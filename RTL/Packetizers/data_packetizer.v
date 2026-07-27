`timescale 1ns / 1ps

module data_packetizer #(
    parameter integer SAMPLES_PER_PACKET = 343, // כמות דגימות (N)
    parameter [31:0]  FIXED_SID = 32'h00000001  // Stream ID ברירת מחדל
)(
    input  wire        clk,           // מחובר ל-tx_clk_out_0 של ה-MAC
    input  wire        rst_n,
    
    // נתוני זמן וזיהוי (יכולים להגיע מרגיסטרים או כניסות קבועות)
    input  wire [31:0] stream_id,     
    input  wire [31:0] ts_seconds,    // Integer Seconds (Word 5)
    input  wire [63:0] ts_picoseconds, // Fractional Seconds (Words 6 & 7)

    // ממשק Slave (קריאת דגימות IQ מה-Async FIFO)
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output reg         s_axis_tready,
    
    // ממשק Master (שידור לכיוון ה-MAC)
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready
);

    // הגדרת מצבים
    localparam IDLE    = 2'd0;
    localparam HEADER  = 2'd1;
    localparam PAYLOAD = 2'd2;

    reg [1:0]  state;
    reg [2:0]  word_cnt;      // מונה את 7 מילות ה-Header
    reg [15:0] sample_cnt;    // מונה את N דגימות ה-Payload
    reg [3:0]  seq_num;       // Modulo 16 sequence counter

    // חישוב גודל פקטה כולל
    wire [15:0] total_packet_size = SAMPLES_PER_PACKET + 16'd7;

    // --------------------------------------------------------
    // בלוק סינכרוני: ניהול המצבים והמונים (Sequential)
    // --------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            word_cnt   <= 0;
            sample_cnt <= 0;
            seq_num    <= 0;
        end else begin
            case (state)
                IDLE: begin
                    word_cnt   <= 0;
                    sample_cnt <= 0;
                    if (s_axis_tvalid) state <= HEADER;
                end

                HEADER: begin
                    if (m_axis_tready) begin
                        if (word_cnt == 3'd6) begin
                            state <= PAYLOAD;
                            word_cnt <= 0;
                        end else begin
                            word_cnt <= word_cnt + 1;
                        end
                    end
                end

                PAYLOAD: begin
                    if (s_axis_tvalid && m_axis_tready) begin
                        if (sample_cnt == SAMPLES_PER_PACKET - 1) begin
                            state <= IDLE;
                            seq_num <= seq_num + 1;
                            sample_cnt <= 0;
                        end else begin
                            sample_cnt <= sample_cnt + 1;
                        end
                    end
                end
            endcase
        end
    end

    // --------------------------------------------------------
    // בלוק קומבינטורי: ניתוב האותות ללא שיהוי (Combinatorial)
    // --------------------------------------------------------
    always @(*) begin
        // ערכי ברירת מחדל כדי למנוע יצירת Latches
        m_axis_tvalid = 0;
        m_axis_tlast  = 0;
        m_axis_tdata  = 32'h0000_0000;
        s_axis_tready = 0;

        case (state)
            IDLE: begin
                // אין פעילות, ערכי ברירת המחדל נשמרים
            end

            HEADER: begin
                m_axis_tvalid = 1; // האות מורם מיד ללא המתנה ל-TREADY (לפי תקן AXI)
                case (word_cnt)
                    3'd0: m_axis_tdata = {4'h1, 1'b1, 3'b000, 2'b01, 2'b10, seq_num, total_packet_size};
                    3'd1: m_axis_tdata = stream_id;
                    3'd2: m_axis_tdata = {5'b00000, 3'b000, 24'h6A621E};
                    3'd3: m_axis_tdata = 32'h0000_0000;
                    3'd4: m_axis_tdata = ts_seconds;
                    3'd5: m_axis_tdata = ts_picoseconds[63:32];
                    3'd6: m_axis_tdata = ts_picoseconds[31:0];
                    default: m_axis_tdata = 32'h0000_0000;
                endcase
            end

            PAYLOAD: begin
                // ניתוב ישיר שמונע איבוד נתונים או שיהוי (Zero Latency)
                m_axis_tvalid = s_axis_tvalid;
                m_axis_tdata  = s_axis_tdata;
                s_axis_tready = m_axis_tready;
                
                // FIX: ה-TLAST מורם רק כאשר יש העברה תקינה (handshake שלם)
                // כדי למנוע מצב שבו TLAST מורם ללא TVALID && TREADY
                if ((sample_cnt == SAMPLES_PER_PACKET - 1) && s_axis_tvalid && m_axis_tready) begin
                    m_axis_tlast = 1;
                end
            end
        endcase
    end

endmodule
