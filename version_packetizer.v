`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// version_packetizer.v
//
// DIFI Version Flow Signal Context Packetizer - Packet Class 0x0004
// Information Class 0x0001 (Version Flow)
//
// Generates a fixed 11-word DIFI Version Context Packet per Table 4-17
// of the DIFI Standard V1.2.1.
//
// This packet conveys:
//   - Which version of the DIFI standard is in use
//   - VITA 49.2 spec version
//   - Firmware build date (Year / Day / Revision)
//   - Precise time-of-day for software synchronization
//
// The packet is emitted:
//   1. Once after reset
//   2. Periodically at a configurable interval (0 to 100 packets/sec)
//   3. On an external trigger pulse (ver_trigger)
//
// Packet structure (11 words):
//   Word  0: Packet Header
//   Word  1: Stream ID
//   Word  2: Class ID word 1 (Pad + OUI)
//   Word  3: Class ID word 2 (Info Class 0x0001 + Packet Class 0x0004)
//   Word  4: Integer Seconds Timestamp
//   Word  5: Fractional Seconds Timestamp [63:32]
//   Word  6: Fractional Seconds Timestamp [31:0]
//   Word  7: CIF 0
//   Word  8: CIF 1
//   Word  9: V49 Spec Version
//   Word 10: Year / Day / Revision / Type / ICD Version
//////////////////////////////////////////////////////////////////////////////

module version_packetizer #(
    // ── Firmware Build Info ────────────────────────────────────────
    // Year: offset from 2000. E.g., 2025 → 25
    parameter [6:0]  BUILD_YEAR     = 7'd25,    // 2025
    // Day: day of year (1 = Jan 1). E.g., April 15 → 105
    parameter [8:0]  BUILD_DAY      = 9'd105,   // April 15
    // Revision: normally 1
    parameter [5:0]  BUILD_REVISION = 6'd1,
    // Type: device type (0x0 = undefined, per DIFI standard)
    parameter [3:0]  DEVICE_TYPE    = 4'h0,
    // ICD Version: 0 = DIFI v1.x (per Table 4-18)
    parameter [5:0]  ICD_VERSION    = 6'd0,

    // ── Stream Configuration ───────────────────────────────────────
    parameter [31:0] FIXED_STREAM_ID = 32'h0000_0001,

    // ── Emission Timing ────────────────────────────────────────────
    // Interval in clock cycles between periodic version packets.
    // At 156.25 MHz: 156_250_000 = once per second
    // Set to 0 to disable periodic emission (trigger/reset only).
    parameter integer EMIT_INTERVAL   = 156_250_000
)(
    input  wire        clk,             // 156.25 MHz MAC clock
    input  wire        rst_n,

    // Timestamp inputs (from system time source)
    input  wire [31:0] stream_id,
    input  wire [31:0] ts_seconds,
    input  wire [63:0] ts_picoseconds,

    // External trigger: pulse high for 1 cycle to force emission
    input  wire        ver_trigger,

    // AXI-Stream Master output
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready
);

    // ================================================================
    // Constant Payload Words
    // ================================================================

    // CIF 0 for Packet Class 0x0004 (from Figure 11):
    //   Bit 31 = Context Change Indicator
    //   Bit 1  = CIF 1 Enable
    //   All other bits = 0
    // With change:    0x80000002
    // Without change: 0x00000002
    localparam [31:0] CIF0_CHANGED   = 32'h8000_0002;
    localparam [31:0] CIF0_NO_CHANGE = 32'h0000_0002;

    // CIF 1 = 0x0000000C
    //   Bit 3 = V49 Spec Version present
    //   Bit 2 = Year/Day/Revision/Type/ICD Version present
    localparam [31:0] CIF1_VALUE     = 32'h0000_000C;

    // V49 Spec Version = 0x00000004 (VITA 49.2)
    localparam [31:0] V49_SPEC_VER   = 32'h0000_0004;

    // Year/Day/Revision/Type/ICD Version word:
    //   [31:25] Year (7 bits) - offset from 2000
    //   [24:16] Day  (9 bits) - day of year
    //   [15:10] Revision (6 bits)
    //   [9:6]   Type (4 bits) - device type
    //   [5:0]   ICD Version (6 bits) - DIFI version code
    localparam [31:0] VERSION_WORD = {
        BUILD_YEAR,       // [31:25]
        BUILD_DAY,        // [24:16]
        BUILD_REVISION,   // [15:10]
        DEVICE_TYPE,      // [9:6]
        ICD_VERSION       // [5:0]
    };

    // ================================================================
    // State Machine
    // ================================================================
    localparam IDLE = 1'b0;
    localparam EMIT = 1'b1;

    reg        state;
    reg [3:0]  word_cnt;       // 0..10 (11 words)
    reg [3:0]  seq_num;        // Modulo 16 sequence counter
    reg [31:0] emit_timer;     // Periodic emission counter
    reg        first_after_rst;

    // Latched timestamps
    reg [31:0] lat_ts_sec;
    reg [63:0] lat_ts_pico;
    reg [31:0] lat_stream_id;

    // ================================================================
    // Periodic Timer & Trigger Logic
    // ================================================================
    wire emit_request = first_after_rst || ver_trigger || (emit_timer == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            emit_timer <= EMIT_INTERVAL - 1;
        end else begin
            if (state == IDLE && emit_request)
                emit_timer <= EMIT_INTERVAL - 1;
            else if (emit_timer != 0)
                emit_timer <= emit_timer - 1;
        end
    end

    // ================================================================
    // Sequential: State and Counters
    // ================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= IDLE;
            word_cnt        <= 0;
            seq_num         <= 0;
            first_after_rst <= 1;
            lat_ts_sec      <= 0;
            lat_ts_pico     <= 0;
            lat_stream_id   <= 0;
        end else begin
            case (state)
                IDLE: begin
                    word_cnt <= 0;
                    if (emit_request) begin
                        state           <= EMIT;
                        first_after_rst <= 0;
                        lat_ts_sec    <= ts_seconds;
                        lat_ts_pico   <= ts_picoseconds;
                        lat_stream_id <= stream_id;
                    end
                end

                EMIT: begin
                    if (m_axis_tready && m_axis_tvalid) begin
                        if (word_cnt == 4'd10) begin
                            state    <= IDLE;
                            word_cnt <= 0;
                            seq_num  <= seq_num + 1;
                        end else begin
                            word_cnt <= word_cnt + 1;
                        end
                    end
                end
            endcase
        end
    end

    // ================================================================
    // Combinatorial: Word Selection & AXI-Stream Outputs
    // ================================================================
    always @(*) begin
        // Defaults
        m_axis_tdata  = 32'h0000_0000;
        m_axis_tvalid = 1'b0;
        m_axis_tlast  = 1'b0;

        case (state)
            IDLE: begin
                // Nothing to output
            end

            EMIT: begin
                m_axis_tvalid = 1'b1;

                // TLAST on the final word (word 10)
                if (word_cnt == 4'd10)
                    m_axis_tlast = 1'b1;

                case (word_cnt)
                    // ── PROLOGUE (Words 0-6) ────────────────────────

                    // Word 0: Packet Header
                    // [31:28] Packet Type = 0x4 (Context with Stream ID)
                    // [27]    Class ID = 1
                    // [26:25] Reserved = 00
                    // [24]    TSM = 1 (Coarse timing for Packet Class 0x0004)
                    // [23:22] TSI = 01 (UTC)
                    // [21:20] TSF = 10 (Real Time, picoseconds)
                    // [19:16] SeqNum
                    // [15:0]  Packet Size = 11
                    4'd0: m_axis_tdata = {4'h4, 1'b1, 2'b00, 1'b1,
                                          2'b01, 2'b10,
                                          seq_num, 16'd11};

                    // Word 1: Stream ID
                    4'd1: m_axis_tdata = lat_stream_id;

                    // Word 2: Class ID word 1
                    // [31:27] Pad Bit Count = 0
                    // [26:24] Reserved = 000
                    // [23:0]  OUI = 0x6A621E
                    4'd2: m_axis_tdata = {5'b00000, 3'b000, 24'h6A621E};

                    // Word 3: Class ID word 2
                    // [31:16] Information Class = 0x0001 (Version Flow)
                    // [15:0]  Packet Class = 0x0004
                    4'd3: m_axis_tdata = {16'h0001, 16'h0004};

                    // Word 4: Integer Seconds Timestamp
                    4'd4: m_axis_tdata = lat_ts_sec;

                    // Words 5-6: Fractional Seconds (picoseconds)
                    4'd5: m_axis_tdata = lat_ts_pico[63:32];
                    4'd6: m_axis_tdata = lat_ts_pico[31:0];

                    // ── CONTEXT PAYLOAD (Words 7-10) ────────────────

                    // Word 7: CIF 0
                    // Always mark as changed for simplicity
                    4'd7: m_axis_tdata = CIF0_CHANGED;

                    // Word 8: CIF 1 = 0x0000000C
                    // Bit 3 = V49 Spec Version present
                    // Bit 2 = Year/Day/Rev/Type/ICD present
                    4'd8: m_axis_tdata = CIF1_VALUE;

                    // Word 9: V49 Spec Version = 0x00000004
                    4'd9: m_axis_tdata = V49_SPEC_VER;

                    // Word 10: Year/Day/Revision/Type/ICD Version
                    4'd10: m_axis_tdata = VERSION_WORD;

                    default: m_axis_tdata = 32'h0000_0000;
                endcase
            end
        endcase
    end

endmodule
