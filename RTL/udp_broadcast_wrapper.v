`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// udp_broadcast_wrapper.v
//
// Wraps DIFI packets in Ethernet + IPv4 + UDP headers using broadcast
// addressing. Designed for the Xilinx 10G/25G Ethernet Subsystem.
//
// AXI-Stream BYTE ORDERING:
//   Per Xilinx PG210, the 10G/25G MAC uses LITTLE-ENDIAN byte placement.
//   Byte 0 of the Ethernet frame (first on wire) → tdata[7:0]
//   Byte 7                                       → tdata[63:56]
//   tkeep is LSB-justified - for 2 valid bytes, tkeep = 8'h03.
//
// Frame layout (network byte order on the wire):
//
//   Offset  Field                     Size
//   ------  ------------------------  -----
//      0    Eth Dst MAC               6
//      6    Eth Src MAC               6
//     12    EtherType                 2     0x0800
//     14    IP Version/IHL            1     0x45
//     15    IP DSCP/ECN               1     0x00
//     16    IP Total Length           2     20 + 8 + DIFI_BYTES
//     18    IP Identification         2     0x0000
//     20    IP Flags/Frag Offset      2     0x4000
//     22    IP TTL                    1     0x40
//     23    IP Protocol               1     0x11 (UDP)
//     24    IP Header Checksum        2     computed
//     26    IP Source Address         4
//     30    IP Destination Address    4
//     34    UDP Source Port           2
//     36    UDP Destination Port      2
//     38    UDP Length                2     8 + DIFI_BYTES
//     40    UDP Checksum              2     0x0000
//     42    DIFI Payload              N
//
// 64-bit alignment:
//   42 header bytes = 5 full 64-bit words + 2 leftover bytes.
//   Word 5 (the 6th output word) carries: 2 header bytes (UDP checksum)
//   in tdata[15:0] + 6 bytes of the first DIFI word in tdata[63:16].
//   From there each output word is { fifo[47:0], holdover[15:0] }.
//
// END-OF-PACKET HANDLING (corrected per Gemini's bug report):
//   When the final FIFO word arrives with V valid bytes:
//     - If V ≤ 6: all remaining bytes (V + 2 holdover) fit in THIS output
//       word. Assert tlast and a partial tkeep, then go to IDLE.
//     - If V ≥ 7: emit a full word now, then go to S_SEND_LAST to emit
//       the remaining (V - 6) bytes from the holdover.
//
//////////////////////////////////////////////////////////////////////////////

module udp_broadcast_wrapper #(
    parameter [47:0] SRC_MAC          = 48'h02_00_00_00_00_01,
    parameter [47:0] DST_MAC          = 48'hFF_FF_FF_FF_FF_FF,
    parameter [31:0] SRC_IP           = {8'd192, 8'd168, 8'd1, 8'd10},
    parameter [31:0] DST_IP           = {8'd255, 8'd255, 8'd255, 8'd255},
    parameter [15:0] SRC_PORT         = 16'd4991,
    parameter [15:0] DST_PORT         = 16'd4991,
    parameter integer FIFO_DEPTH      = 256,
    parameter        SWAP_INPUT_BYTES = 1'b1
)(
    input  wire        clk,
    input  wire        rst_n,

    // ── Slave: from Width Converter ────────────────────────────────
    input  wire [63:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    input  wire [7:0]  s_axis_tkeep,
    output reg         s_axis_tready,

    // ── Master: to 10G/25G Ethernet Subsystem ──────────────────────
    output reg  [63:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    output reg  [7:0]  m_axis_tkeep,
    input  wire        m_axis_tready
);

    // ================================================================
    // Optional input byte-swap
    // ================================================================
    wire [63:0] in_data_le;
    wire [7:0]  in_keep_le;

    // ----------------------------------------------------------------
    // FIX (2026-05): SWAP_INPUT_BYTES used to reverse the entire 64-bit
    // word as one unit. That was wrong: the upstream width converter
    // packs DIFI 32-bit words pairwise (word N at tdata[31:0],
    // word N+1 at tdata[63:32]). A full 64-bit reversal swaps the
    // POSITION of the two 32-bit words in addition to reversing bytes,
    // which corrupts the order of DIFI words on the wire.
    //
    // Correct behavior: reverse bytes WITHIN each 32-bit half
    // independently, leaving the two halves in their original
    // [31:0] / [63:32] positions.
    // ----------------------------------------------------------------
    generate
        if (SWAP_INPUT_BYTES) begin : g_swap
            // Per-32-bit-half byte reversal
            assign in_data_le[31:0]  = {s_axis_tdata[ 7: 0], s_axis_tdata[15: 8],
                                        s_axis_tdata[23:16], s_axis_tdata[31:24]};
            assign in_data_le[63:32] = {s_axis_tdata[39:32], s_axis_tdata[47:40],
                                        s_axis_tdata[55:48], s_axis_tdata[63:56]};
            assign in_keep_le[3:0]   = {s_axis_tkeep[0], s_axis_tkeep[1],
                                        s_axis_tkeep[2], s_axis_tkeep[3]};
            assign in_keep_le[7:4]   = {s_axis_tkeep[4], s_axis_tkeep[5],
                                        s_axis_tkeep[6], s_axis_tkeep[7]};
        end else begin : g_passthru
            assign in_data_le = s_axis_tdata;
            assign in_keep_le = s_axis_tkeep;
        end
    endgenerate

    // ================================================================
    // Pack 8 bytes into a tdata word with byte 0 on tdata[7:0]
    // ================================================================
    function [63:0] pack8;
        input [7:0] b0, b1, b2, b3, b4, b5, b6, b7;
        begin
            pack8 = {b7, b6, b5, b4, b3, b2, b1, b0};
        end
    endfunction

    // Generate LSB-justified tkeep mask for N valid bytes (1..8)
    function [7:0] keep_mask;
        input [3:0] n_bytes;
        begin
            case (n_bytes)
                4'd1: keep_mask = 8'h01;
                4'd2: keep_mask = 8'h03;
                4'd3: keep_mask = 8'h07;
                4'd4: keep_mask = 8'h0F;
                4'd5: keep_mask = 8'h1F;
                4'd6: keep_mask = 8'h3F;
                4'd7: keep_mask = 8'h7F;
                4'd8: keep_mask = 8'hFF;
                default: keep_mask = 8'h00;
            endcase
        end
    endfunction

    function [3:0] count_keep_bytes;
        input [7:0] kp;
        begin
            count_keep_bytes = kp[0] + kp[1] + kp[2] + kp[3]
                             + kp[4] + kp[5] + kp[6] + kp[7];
        end
    endfunction

    // ================================================================
    // Packet FIFO
    // ================================================================
    localparam integer ADDR_W = $clog2(FIFO_DEPTH);

    reg [63:0] fifo_data [0:FIFO_DEPTH-1];
    reg [7:0]  fifo_keep [0:FIFO_DEPTH-1];
    reg        fifo_last [0:FIFO_DEPTH-1];

    reg [ADDR_W-1:0] fifo_wr_ptr;
    reg [ADDR_W-1:0] fifo_rd_ptr;
    reg [ADDR_W:0]   fifo_count;
    wire fifo_empty = (fifo_count == 0);

    // ================================================================
    // FSM
    // ================================================================
    localparam [2:0] S_IDLE      = 3'd0;
    localparam [2:0] S_RECEIVE   = 3'd1;
    localparam [2:0] S_COMPUTE   = 3'd2;
    localparam [2:0] S_SEND_HDR  = 3'd3;
    localparam [2:0] S_SEND_BODY = 3'd4;
    localparam [2:0] S_SEND_LAST = 3'd5;

    reg [2:0]  state;
    reg [15:0] difi_byte_count;
    reg [15:0] ip_total_len;
    reg [15:0] udp_len;
    reg [15:0] ip_checksum;
    reg [3:0]  hdr_word_cnt;
    reg [15:0] holdover_data;     // 2 bytes leftover from prior FIFO word
    reg [3:0]  last_remaining;    // bytes still to send in S_SEND_LAST

    // ================================================================
    // IP checksum (one's complement sum, header treated with cksum=0)
    // ================================================================
    function [15:0] compute_ip_checksum;
        input [15:0] tot_len;
        reg [31:0] sum;
        begin
            sum = 32'h0000_4500
                + tot_len
                + 32'h0000_0000
                + 32'h0000_4000
                + 32'h0000_4011
                + 32'h0000_0000
                + SRC_IP[31:16]
                + SRC_IP[15:0]
                + DST_IP[31:16]
                + DST_IP[15:0];
            sum = (sum & 32'hFFFF) + (sum >> 16);
            sum = (sum & 32'hFFFF) + (sum >> 16);
            compute_ip_checksum = ~sum[15:0];
        end
    endfunction

    // ================================================================
    // Pre-built header words (combinatorial)
    // ================================================================
    wire [63:0] hdr_w0 = pack8(
        DST_MAC[47:40], DST_MAC[39:32], DST_MAC[31:24], DST_MAC[23:16],
        DST_MAC[15: 8], DST_MAC[ 7: 0],
        SRC_MAC[47:40], SRC_MAC[39:32]
    );
    wire [63:0] hdr_w1 = pack8(
        SRC_MAC[31:24], SRC_MAC[23:16], SRC_MAC[15:8], SRC_MAC[7:0],
        8'h08, 8'h00,
        8'h45, 8'h00
    );
    wire [63:0] hdr_w2 = pack8(
        ip_total_len[15:8], ip_total_len[7:0],
        8'h00, 8'h00,
        8'h40, 8'h00,
        8'h40, 8'h11
    );
    wire [63:0] hdr_w3 = pack8(
        ip_checksum[15:8], ip_checksum[7:0],
        SRC_IP[31:24], SRC_IP[23:16], SRC_IP[15:8], SRC_IP[7:0],
        DST_IP[31:24], DST_IP[23:16]
    );
    wire [63:0] hdr_w4 = pack8(
        DST_IP[15:8], DST_IP[7:0],
        SRC_PORT[15:8], SRC_PORT[7:0],
        DST_PORT[15:8], DST_PORT[7:0],
        udp_len[15:8],  udp_len[7:0]
    );
    // Word 5: 2 bytes UDP checksum (=0) on tdata[15:0],
    //         then 6 bytes from fifo[0] bytes [47:0] on tdata[63:16].
    wire [63:0] hdr_w5 = {fifo_data[fifo_rd_ptr][47:0], 16'h0000};

    // ================================================================
    // End-of-packet helpers
    //
    // When we read the LAST fifo word, it has V valid bytes.
    // We've already shifted out 2 bytes from EVERY prior fifo word as
    // holdover into the next output cycle. So when this last word arrives:
    //
    //   This output cycle carries:
    //     - holdover[15:0]                       (2 bytes, low byte first)
    //     - up to 6 bytes from this fifo word    (bytes [47:0])
    //
    //   If V ≤ 6: all V valid bytes fit in this cycle.
    //             Total output bytes = V + 2.
    //             Set tlast=1, tkeep = mask(V+2), GO TO IDLE.
    //
    //   If V ≥ 7: we emit a full 8-byte word now (tkeep=FF), and the
    //             remaining (V - 6) bytes (which are in fifo[63:48] for
    //             V=7,8) become the holdover for S_SEND_LAST.
    //             remaining = V - 6 (in {1, 2}).
    //
    // (V cannot be > 8.)
    // ================================================================
    wire [3:0] last_valid_bytes = count_keep_bytes(fifo_keep[fifo_rd_ptr]);
    wire       last_fits_now    = (last_valid_bytes <= 4'd6);

    // ================================================================
    // Main FSM
    // ================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= S_IDLE;
            fifo_wr_ptr     <= 0;
            fifo_rd_ptr     <= 0;
            fifo_count      <= 0;
            difi_byte_count <= 0;
            ip_total_len    <= 0;
            udp_len         <= 0;
            ip_checksum     <= 0;
            hdr_word_cnt    <= 0;
            holdover_data   <= 0;
            last_remaining  <= 0;
            s_axis_tready   <= 0;
            m_axis_tdata    <= 0;
            m_axis_tvalid   <= 0;
            m_axis_tlast    <= 0;
            m_axis_tkeep    <= 0;
        end else begin
            // Defaults
            m_axis_tvalid <= 0;
            m_axis_tlast  <= 0;
            m_axis_tkeep  <= 8'hFF;

            case (state)
                // ────────────────────────────────────────────────────
                S_IDLE: begin
                    s_axis_tready   <= 1;
                    fifo_wr_ptr     <= 0;
                    fifo_rd_ptr     <= 0;
                    fifo_count      <= 0;
                    difi_byte_count <= 0;
                    holdover_data   <= 0;

                    if (s_axis_tvalid && s_axis_tready) begin
                        fifo_data[0] <= in_data_le;
                        fifo_keep[0] <= in_keep_le;
                        fifo_last[0] <= s_axis_tlast;
                        fifo_wr_ptr  <= 1;
                        fifo_count   <= 1;
                        difi_byte_count <= count_keep_bytes(in_keep_le);

                        if (s_axis_tlast) begin
                            s_axis_tready <= 0;
                            state         <= S_COMPUTE;
                        end else begin
                            state <= S_RECEIVE;
                        end
                    end
                end

                // ────────────────────────────────────────────────────
                S_RECEIVE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        fifo_data[fifo_wr_ptr] <= in_data_le;
                        fifo_keep[fifo_wr_ptr] <= in_keep_le;
                        fifo_last[fifo_wr_ptr] <= s_axis_tlast;
                        fifo_wr_ptr            <= fifo_wr_ptr + 1;
                        fifo_count             <= fifo_count + 1;
                        difi_byte_count        <= difi_byte_count
                                                  + count_keep_bytes(in_keep_le);

                        if (s_axis_tlast) begin
                            s_axis_tready <= 0;
                            state         <= S_COMPUTE;
                        end
                    end
                end

                // ────────────────────────────────────────────────────
                S_COMPUTE: begin
                    ip_total_len <= 16'd28 + difi_byte_count;
                    udp_len      <= 16'd8  + difi_byte_count;
                    ip_checksum  <= compute_ip_checksum(16'd28 + difi_byte_count);
                    hdr_word_cnt <= 0;
                    state        <= S_SEND_HDR;
                end

                // ────────────────────────────────────────────────────
                S_SEND_HDR: begin
                    m_axis_tvalid <= 1;
                    m_axis_tkeep  <= 8'hFF;

                    case (hdr_word_cnt)
                        4'd0: m_axis_tdata <= hdr_w0;
                        4'd1: m_axis_tdata <= hdr_w1;
                        4'd2: m_axis_tdata <= hdr_w2;
                        4'd3: m_axis_tdata <= hdr_w3;
                        4'd4: m_axis_tdata <= hdr_w4;
                        4'd5: m_axis_tdata <= hdr_w5;
                        default: m_axis_tdata <= 64'h0;
                    endcase

                    if (m_axis_tready) begin
                        if (hdr_word_cnt == 4'd5) begin
                            // We just consumed bytes [47:0] of fifo[0].
                            // Save bytes [63:48] as holdover.
                            holdover_data <= fifo_data[fifo_rd_ptr][63:48];
                            fifo_rd_ptr   <= fifo_rd_ptr + 1;
                            fifo_count    <= fifo_count - 1;

                            // Was that first word also the last? Edge case:
                            // very small DIFI packet that fits in 1 fifo word.
                            // (Won't happen for our 11/27/350-word DIFI packets,
                            // since even the smallest is 44 bytes = 5.5 fifo words.)
                            if (fifo_last[fifo_rd_ptr]) begin
                                // V = count of valid bytes in this fifo word.
                                // After shifting, bytes [63:48] are holdover.
                                // If keep < 8'h3F, those holdover bytes are
                                // garbage/invalid. Need to handle, but for
                                // our DIFI packets this path is unreachable.
                                state <= S_SEND_LAST;
                                last_remaining <= 4'd0;
                            end else begin
                                state <= S_SEND_BODY;
                            end
                        end else begin
                            hdr_word_cnt <= hdr_word_cnt + 1;
                        end
                    end
                end

                // ────────────────────────────────────────────────────
                S_SEND_BODY: begin
                    if (!fifo_empty) begin
                        m_axis_tvalid <= 1;
                        // Always-form output word: 2 holdover bytes (low) +
                        // 6 bytes from current fifo word (high).
                        m_axis_tdata  <= {fifo_data[fifo_rd_ptr][47:0],
                                          holdover_data};

                        if (fifo_last[fifo_rd_ptr]) begin
                            // ── Final FIFO word ─────────────────────
                            if (last_fits_now) begin
                                // V ≤ 6: everything fits in this cycle.
                                // Total valid bytes this cycle = V + 2.
                                m_axis_tkeep <= keep_mask(last_valid_bytes
                                                          + 4'd2);
                                m_axis_tlast <= 1;

                                if (m_axis_tready) begin
                                    fifo_rd_ptr <= fifo_rd_ptr + 1;
                                    fifo_count  <= fifo_count - 1;
                                    state       <= S_IDLE;
                                end
                            end else begin
                                // V ≥ 7: full output now, leftover next cycle.
                                m_axis_tkeep <= 8'hFF;

                                if (m_axis_tready) begin
                                    holdover_data  <= fifo_data[fifo_rd_ptr][63:48];
                                    last_remaining <= last_valid_bytes - 4'd6;
                                    fifo_rd_ptr    <= fifo_rd_ptr + 1;
                                    fifo_count     <= fifo_count - 1;
                                    state          <= S_SEND_LAST;
                                end
                            end
                        end else begin
                            // ── Normal middle word: full 8-byte transfer ─
                            m_axis_tkeep <= 8'hFF;

                            if (m_axis_tready) begin
                                holdover_data <= fifo_data[fifo_rd_ptr][63:48];
                                fifo_rd_ptr   <= fifo_rd_ptr + 1;
                                fifo_count    <= fifo_count - 1;
                            end
                        end
                    end
                end

                // ────────────────────────────────────────────────────
                S_SEND_LAST: begin
                    // Emit the remaining (last_remaining) bytes from the
                    // holdover. last_remaining is 1 or 2 for V=7 or V=8.
                    m_axis_tvalid <= 1;
                    m_axis_tlast  <= 1;
                    m_axis_tdata  <= {48'h0, holdover_data};
                    m_axis_tkeep  <= keep_mask(last_remaining);

                    if (m_axis_tready) begin
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
