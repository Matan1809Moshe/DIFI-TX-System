`timescale 1ns / 1ps

module tb_packetizer();

    // הגדרת אותות כניסה (רגיסטרים כי אנחנו שולטים בהם בטסט)
    reg clk;
    reg rst_n;
    reg [31:0] stream_id;
    reg [31:0] ts_seconds;
    reg [63:0] ts_picoseconds;
    
    // אותות שמגיעים מה-FIFO המדומה
    reg [31:0] s_axis_tdata;
    reg        s_axis_tvalid;
    wire       s_axis_tready; // ה-Packetizer מחזיר לנו
    
    // אותות שהולכים ל-MAC/MUX המדומה
    wire [31:0] m_axis_tdata;
    wire        m_axis_tvalid;
    wire        m_axis_tlast;
    reg         m_axis_tready;

    // חיבור הבלוק שלנו (Unit Under Test)
    data_packetizer #(
        .SAMPLES_PER_PACKET(343)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .stream_id(stream_id),
        .ts_seconds(ts_seconds),
        .ts_picoseconds(ts_picoseconds),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );

    // יצירת שעון: מחזור של 6.4 ננו-שניות מדמה תדר של 156.25MHz (שעון MAC סטנדרטי)
    always #3.2 clk = ~clk;

    integer i;

    initial begin
        // אתחול המערכת
        clk = 0;
        rst_n = 0;
        stream_id = 32'h00000001;
        ts_seconds = 32'h00000010;        // סתם מספר (16 שניות)
        ts_picoseconds = 64'h0000000000001000;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        m_axis_tready = 1; // אנחנו אומרים ל-Packetizer שה-MAC פנוי תמיד

        // המתנה ואיפוס
        #100;
        @(posedge clk);
        rst_n = 1;
        #50;

        // --- התחלת הזרמת נתונים מה-FIFO ---
        // אנחנו מדמים את ה-FIFO מוציא 512 דגימות
        for (i = 0; i < 1029; i = i + 1) begin
            @(posedge clk);
            s_axis_tvalid = 1;
            // נמציא דגימות IQ ממוספרות כדי שיהיה קל לראות בגרף (למשל 1000, 1001, 1002...)
            s_axis_tdata = 32'd1000 + i; 
            
            // אנחנו מחכים שה-Packetizer יגיד "קיבלתי" לפני שנמשיך לדגימה הבאה
            while (!s_axis_tready) begin
                @(posedge clk);
            end
        end

        // סיום הזרמת הנתונים
        @(posedge clk);
        s_axis_tvalid = 0;

        // ממתינים קצת כדי לראות את סוף הפקטה ולסגור את הסימולציה
        #200;
        $finish;
    end

endmodule
