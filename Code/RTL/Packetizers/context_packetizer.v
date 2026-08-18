`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// context_packetizer.v
//
// DIFI Signal Context Packetizer - Packet Class 0x0001
// Information Class 0x0000 (Basic Data Plane)
//
// Generates a fixed 27-word DIFI Signal Context Packet per Table 4-15
// of the DIFI Standard V1.2.1.
//
// The packet is emitted:
//   1. Once after reset (initial context announcement)
//   2. Periodically at a configurable interval (up to 20 packets/sec)
//   3. On an external trigger pulse (ctx_trigger)
//
// All context field values are set via parameters for the academic
// proof-of-concept. For dynamic configuration, replace the localparams
// with AXI-Lite register inputs later.
//
// AXI-Stream Master output (32-bit) connects to the arbiter.
//////////////////////////////////////////////////////////////////////////////

module context_packetizer #(
    // ── Signal Description Parameters ──────────────────────────────
    // These describe YOUR signal chain. Adjust to match your DDS/system.
    parameter integer SAMPLE_RATE_HZ     = 1_000_000,  // 100 MHz sample rate
    parameter integer BANDWIDTH_HZ       = 50_000_000,   // 50 MHz usable BW
    parameter integer IF_REF_FREQ_HZ     = 0,            // 0 = zero-IF
    parameter integer RF_REF_FREQ_HZ     = 1_000_000_000,// 1 GHz RF center
    parameter integer IF_BAND_OFFSET_HZ  = 0,            // No offset
    parameter integer BITS_PER_SAMPLE    = 16,           // 16-bit I, 16-bit Q
    
    // ── Reference Point ────────────────────────────────────────────
    // 100 (0x0064) = IF converter interface (default for IFC systems)
    //  75 (0x004B) = RF converter interface
    //  25 (0x0019) = Antenna feed
    //  15 (0x000F) = Air interface (ESA)
    parameter [31:0] REFERENCE_POINT     = 32'h0000_0064,
    
    // ── Levels (VITA 49.2 format: 16-bit signed, units of 1/128 dBm) ──
    parameter [15:0] SCALING_LEVEL       = 16'h0000,     // 0 dBFS (not used in Rx)
    parameter [15:0] REFERENCE_LEVEL     = 16'h0000,     // 0 dBm at ref point
    parameter [15:0] GAIN_1              = 16'h0000,     // Reserved per DIFI
    parameter [15:0] GAIN_2              = 16'h0000,     // Reserved per DIFI
    
    // ── Timing ─────────────────────────────────────────────────────
    parameter [63:0] TIMESTAMP_ADJ       = 64'h0,        // femtoseconds
    parameter [31:0] TS_CALIB_TIME       = 32'h0,        // last calibration
    
    // ── State & Event (Word 25) ────────────────────────────────────
    // Bit 19 = calibrated time indicator, Bit 17 = valid freq reference
    parameter [31:0] STATE_EVENT_IND     = 32'h0000_0000,
    
    // ── Stream Configuration ───────────────────────────────────────
    parameter [31:0] FIXED_STREAM_ID     = 32'h0000_0001,
    
    // ── Emission Timing ────────────────────────────────────────────
    // Interval in clock cycles between periodic context packets.
    // At 156.25 MHz: 156_250_000 / 10 = 15_625_000 for 10 packets/sec
    parameter integer EMIT_INTERVAL      = 15_625_000
)(
    input  wire        clk,             // 156.25 MHz MAC clock
    input  wire        rst_n,
    
    // Timestamp inputs (shared with data packetizer, from system time)
    input  wire [31:0] stream_id,
    input  wire [31:0] ts_seconds,
    input  wire [63:0] ts_picoseconds,
    
    // External trigger: pulse high for 1 cycle to force context emission
    input  wire        ctx_trigger,
    
    // AXI-Stream Master output
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready
);

    // ================================================================
    // VITA 49.2 Frequency Format Helper
    // 64-bit two's complement, radix point right of bit 20 in word 2.
    // DIFI requires integer Hz only, so: {freq_hz[43:0], 20'b0} 
    // Split into two 32-bit words:
    //   Word Hi = freq_hz[43:12]  (or freq_hz >> 12 if positive)
    //   Word Lo = freq_hz[11:0] << 20
    // For simplicity with positive frequencies up to ~4 THz:
    // ================================================================
    
    // Pre-compute the 64-bit VITA frequency representations
    // frequency_64 = freq_hz << 20, then split into [63:32] and [31:0]
    localparam [63:0] BW_64       = BANDWIDTH_HZ      * 64'd1_048_576; // << 20
    localparam [63:0] IF_REF_64   = IF_REF_FREQ_HZ    * 64'd1_048_576;
    localparam [63:0] RF_REF_64   = RF_REF_FREQ_HZ    * 64'd1_048_576;
    localparam [63:0] IF_OFFSET_64= IF_BAND_OFFSET_HZ * 64'd1_048_576;
    localparam [63:0] SRATE_64    = SAMPLE_RATE_HZ     * 64'd1_048_576;

    // ── Data Packet Payload Format (Words 26 & 27) ─────────────────
    // Per Figure 10 of DIFI Standard:
    // Word 26: {1'b1,     // Packing Method = Link Efficient
    //           2'b01,    // Real/Complex = Complex Cartesian
    //           5'b00000, // Data Item Format = Signed Fixed Point
    //           1'b0,     // Sample Component Repeat = No
    //           3'b000,   // Event Tag Size = 0
    //           3'b000,   // Channel Tag Size = 0
    //           4'b0000,  // Data Item Fraction Size = 0
    //           6'bXXXXXX,// Item Packing Field Size = bits-1
    //           6'bXXXXXX}// Data Item Size = bits-1
    localparam [5:0] DEPTH_M1 = BITS_PER_SAMPLE - 1;
    localparam [31:0] PAYLOAD_FMT_WORD26 = {
        1'b1,          // [31]    Packing Method: Link Efficient
        2'b01,         // [30:29] Real/Complex: Complex Cartesian
        5'b00000,      // [28:24] Data Item Format: Signed Fixed Point
        1'b0,          // [23]    Sample Component Repeat: No
        3'b000,        // [22:20] Event Tag Size: 0
        3'b000,        // [19:17] Channel Tag Size: 0
        4'b0000,       // [16:13] Data Item Fraction Size: 0
        1'b0,          // [12]    MSB of Item Packing Field (6-bit field)
        DEPTH_M1[4:0], // [11:7]  Item Packing Field Size (bits-1)
        DEPTH_M1       // [6:1,0] Data Item Size (bits-1) -- NOTE: 6 bits [5:0]
    };
    // Word 27: Repeat Count (16b) = 0, Vector Size (16b) = 0
    localparam [31:0] PAYLOAD_FMT_WORD27 = 32'h0000_0000;

    // ── CIF 0 Values ───────────────────────────────────────────────
    // From Figure 9: For Packet Classes 0x0001 and 0x0003
    // Bit 31 = Context Field Change Indicator (1=change, 0=no change)
    // Fixed pattern for remaining bits: X_BB98000
    // With change:    0xFBB98000
    // Without change: 0x7BB98000
    localparam [31:0] CIF0_CHANGED    = 32'hFBB9_8000;
    localparam [31:0] CIF0_NO_CHANGE  = 32'h7BB9_8000;

    // ================================================================
    // State Machine
    // ================================================================
    localparam IDLE    = 2'd0;
    localparam EMIT    = 2'd1;
    
    reg [1:0]  state;
    reg [4:0]  word_cnt;       // 0..26 (27 words)
    reg [3:0]  seq_num;        // Modulo 16 sequence counter
    reg [31:0] emit_timer;     // Periodic emission counter
    reg        first_after_rst;// Flag: first packet after reset
    
    // Latched timestamps at the moment we begin emitting
    reg [31:0] lat_ts_sec;
    reg [63:0] lat_ts_pico;
    reg [31:0] lat_stream_id;

    // ================================================================
    // Periodic Timer & Trigger Logic
    // ================================================================
    wire emit_request = first_after_rst || ctx_trigger || (emit_timer == 0);

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
                        // Latch current timestamp at start of emission
                        lat_ts_sec    <= ts_seconds;
                        lat_ts_pico   <= ts_picoseconds;
                        lat_stream_id <= stream_id;
                    end
                end

                EMIT: begin
                    if (m_axis_tready && m_axis_tvalid) begin
                        if (word_cnt == 5'd26) begin
                            // Last word sent
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
                
                // TLAST on the final word (word 26), gated by handshake
                if (word_cnt == 5'd26)
                    m_axis_tlast = 1'b1;

                case (word_cnt)
                    // ── PROLOGUE (Words 0-6) ────────────────────────
                    
                    // Word 0: Packet Header
                    // [31:28] Packet Type = 0x4 (Context with Stream ID)
                    // [27]    Class ID = 1
                    // [26:25] Reserved = 00
                    // [24]    TSM = 1 (Coarse timing for Info Class 0x0000)
                    // [23:22] TSI = 01 (UTC)
                    // [21:20] TSF = 10 (Real Time, picoseconds)
                    // [19:16] SeqNum
                    // [15:0]  Packet Size = 27
                    5'd0: m_axis_tdata = {4'h4, 1'b1, 2'b00, 1'b1,
                                          2'b01, 2'b10,
                                          seq_num, 16'd27};

                    // Word 1: Stream ID
                    5'd1: m_axis_tdata = lat_stream_id;

                    // Word 2: Class ID word 1
                    // [31:27] Pad Bit Count = 0 (no data payload)
                    // [26:24] Reserved = 000
                    // [23:0]  OUI = 0x6A621E (DIFI Consortium)
                    5'd2: m_axis_tdata = {5'b00000, 3'b000, 24'h6A621E};

                    // Word 3: Class ID word 2
                    // [31:16] Information Class = 0x0000
                    // [15:0]  Packet Class = 0x0001
                    5'd3: m_axis_tdata = {16'h0000, 16'h0001};

                    // Word 4: Integer Seconds Timestamp
                    5'd4: m_axis_tdata = lat_ts_sec;

                    // Words 5-6: Fractional Seconds Timestamp (picoseconds)
                    5'd5: m_axis_tdata = lat_ts_pico[63:32];
                    5'd6: m_axis_tdata = lat_ts_pico[31:0];

                    // ── CONTEXT FIELDS (Words 7-26) ─────────────────
                    
                    // Word 7: CIF 0 - Context Indicator Field
                    // First emission after reset = changed, subsequent = no change
                    // For simplicity, always mark as changed (0xFBB98000)
                    5'd7: m_axis_tdata = CIF0_CHANGED;

                    // Word 8: Reference Point
                    5'd8: m_axis_tdata = REFERENCE_POINT;

                    // Words 9-10: Bandwidth (64-bit VITA freq format)
                    5'd9:  m_axis_tdata = BW_64[63:32];
                    5'd10: m_axis_tdata = BW_64[31:0];

                    // Words 11-12: IF Reference Frequency
                    5'd11: m_axis_tdata = IF_REF_64[63:32];
                    5'd12: m_axis_tdata = IF_REF_64[31:0];

                    // Words 13-14: RF Reference Frequency
                    5'd13: m_axis_tdata = RF_REF_64[63:32];
                    5'd14: m_axis_tdata = RF_REF_64[31:0];

                    // Words 15-16: IF Band Offset
                    5'd15: m_axis_tdata = IF_OFFSET_64[63:32];
                    5'd16: m_axis_tdata = IF_OFFSET_64[31:0];

                    // Word 17: Scaling (upper 16) + Reference Level (lower 16)
                    5'd17: m_axis_tdata = {SCALING_LEVEL, REFERENCE_LEVEL};

                    // Word 18: Gain 2 (upper 16) + Gain 1 (lower 16)
                    // Reserved per DIFI - set to 0x0000 at source
                    5'd18: m_axis_tdata = {GAIN_2, GAIN_1};

                    // Words 19-20: Sample Rate (64-bit VITA freq format)
                    5'd19: m_axis_tdata = SRATE_64[63:32];
                    5'd20: m_axis_tdata = SRATE_64[31:0];

                    // Words 21-22: Timestamp Adjustment (64-bit, femtoseconds)
                    5'd21: m_axis_tdata = TIMESTAMP_ADJ[63:32];
                    5'd22: m_axis_tdata = TIMESTAMP_ADJ[31:0];

                    // Word 23: Timestamp Calibration Time
                    5'd23: m_axis_tdata = TS_CALIB_TIME;

                    // Word 24: State and Event Indicators
                    5'd24: m_axis_tdata = STATE_EVENT_IND;

                    // Words 25-26: Data Packet Payload Format
                    5'd25: m_axis_tdata = PAYLOAD_FMT_WORD26;
                    5'd26: m_axis_tdata = PAYLOAD_FMT_WORD27;

                    default: m_axis_tdata = 32'h0000_0000;
                endcase
            end
        endcase
    end

endmodule
