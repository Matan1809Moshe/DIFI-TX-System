`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// tb_udp_broadcast_wrapper.v
//
// Testbench for udp_broadcast_wrapper.v
//
// What this testbench does:
//   1. Builds a known 44-byte DIFI version packet by hand.
//   2. Feeds it into the wrapper as 64-bit AXI-Stream words in TWO
//      possible input formats:
//        - BE-on-tdata (Verilog-natural, what data_packetizer.v produces)
//        - LE-on-tdata (pre-swapped by some hypothetical upstream logic)
//   3. Captures the output AXI-Stream byte by byte (using tkeep).
//   4. Compares to a hand-computed 86-byte expected Ethernet frame.
//   5. Runs FOUR scenarios (input format x SWAP_INPUT_BYTES) and prints
//      a clear PASS/FAIL report.
//
// Run in Vivado XSim:
//   1. Add Sources -> Add or create simulation sources
//   2. Add tb_udp_broadcast_wrapper.v as a SIMULATION source
//   3. Set tb_udp_broadcast_wrapper as the simulation top
//   4. Run Simulation -> Run Behavioral Simulation
//   5. Read the TCL console for PASS/FAIL output
//////////////////////////////////////////////////////////////////////////////

module tb_udp_broadcast_wrapper;

    // ── Clock & Reset ──────────────────────────────────────────────
    reg clk = 0;
    reg rst_n = 0;
    always #3.2 clk = ~clk;  // 156.25 MHz (period = 6.4 ns)

    // ── Shared DUT inputs (driven by stimulus) ─────────────────────
    reg  [63:0] s_axis_tdata;
    reg         s_axis_tvalid;
    reg         s_axis_tlast;
    reg  [7:0]  s_axis_tkeep;
    wire        s_axis_tready;

    // ── Shared DUT outputs (captured) ──────────────────────────────
    wire [63:0] m_axis_tdata;
    wire        m_axis_tvalid;
    wire        m_axis_tlast;
    wire [7:0]  m_axis_tkeep;
    reg         m_axis_tready;

    // ════════════════════════════════════════════════════════════════
    // Four DUT instances, one per (input format, SWAP) combination.
    // We mux which one is active via `active_dut`.
    // ════════════════════════════════════════════════════════════════
    reg [1:0] active_dut;

    wire [63:0] m_data_a, m_data_b, m_data_c, m_data_d;
    wire        m_valid_a, m_valid_b, m_valid_c, m_valid_d;
    wire        m_last_a,  m_last_b,  m_last_c,  m_last_d;
    wire [7:0]  m_keep_a,  m_keep_b,  m_keep_c,  m_keep_d;
    wire        s_ready_a, s_ready_b, s_ready_c, s_ready_d;

    wire valid_a = s_axis_tvalid && (active_dut == 2'd0);
    wire valid_b = s_axis_tvalid && (active_dut == 2'd1);
    wire valid_c = s_axis_tvalid && (active_dut == 2'd2);
    wire valid_d = s_axis_tvalid && (active_dut == 2'd3);

    wire ready_a = m_axis_tready && (active_dut == 2'd0);
    wire ready_b = m_axis_tready && (active_dut == 2'd1);
    wire ready_c = m_axis_tready && (active_dut == 2'd2);
    wire ready_d = m_axis_tready && (active_dut == 2'd3);

    assign m_axis_tdata  = (active_dut == 2'd0) ? m_data_a :
                           (active_dut == 2'd1) ? m_data_b :
                           (active_dut == 2'd2) ? m_data_c : m_data_d;
    assign m_axis_tvalid = (active_dut == 2'd0) ? m_valid_a :
                           (active_dut == 2'd1) ? m_valid_b :
                           (active_dut == 2'd2) ? m_valid_c : m_valid_d;
    assign m_axis_tlast  = (active_dut == 2'd0) ? m_last_a  :
                           (active_dut == 2'd1) ? m_last_b  :
                           (active_dut == 2'd2) ? m_last_c  : m_last_d;
    assign m_axis_tkeep  = (active_dut == 2'd0) ? m_keep_a  :
                           (active_dut == 2'd1) ? m_keep_b  :
                           (active_dut == 2'd2) ? m_keep_c  : m_keep_d;
    assign s_axis_tready = (active_dut == 2'd0) ? s_ready_a :
                           (active_dut == 2'd1) ? s_ready_b :
                           (active_dut == 2'd2) ? s_ready_c : s_ready_d;

    udp_broadcast_wrapper #(.SWAP_INPUT_BYTES(1'b0)) dut_a (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(valid_a), .s_axis_tlast(s_axis_tlast),
        .s_axis_tkeep(s_axis_tkeep), .s_axis_tready(s_ready_a),
        .m_axis_tdata(m_data_a), .m_axis_tvalid(m_valid_a),
        .m_axis_tlast(m_last_a), .m_axis_tkeep(m_keep_a),
        .m_axis_tready(ready_a)
    );
    udp_broadcast_wrapper #(.SWAP_INPUT_BYTES(1'b1)) dut_b (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(valid_b), .s_axis_tlast(s_axis_tlast),
        .s_axis_tkeep(s_axis_tkeep), .s_axis_tready(s_ready_b),
        .m_axis_tdata(m_data_b), .m_axis_tvalid(m_valid_b),
        .m_axis_tlast(m_last_b), .m_axis_tkeep(m_keep_b),
        .m_axis_tready(ready_b)
    );
    udp_broadcast_wrapper #(.SWAP_INPUT_BYTES(1'b0)) dut_c (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(valid_c), .s_axis_tlast(s_axis_tlast),
        .s_axis_tkeep(s_axis_tkeep), .s_axis_tready(s_ready_c),
        .m_axis_tdata(m_data_c), .m_axis_tvalid(m_valid_c),
        .m_axis_tlast(m_last_c), .m_axis_tkeep(m_keep_c),
        .m_axis_tready(ready_c)
    );
    udp_broadcast_wrapper #(.SWAP_INPUT_BYTES(1'b1)) dut_d (
        .clk(clk), .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(valid_d), .s_axis_tlast(s_axis_tlast),
        .s_axis_tkeep(s_axis_tkeep), .s_axis_tready(s_ready_d),
        .m_axis_tdata(m_data_d), .m_axis_tvalid(m_valid_d),
        .m_axis_tlast(m_last_d), .m_axis_tkeep(m_keep_d),
        .m_axis_tready(ready_d)
    );

    // ════════════════════════════════════════════════════════════════
    // Stimulus storage
    // ════════════════════════════════════════════════════════════════
    reg [63:0] input_be_data [0:5];
    reg [7:0]  input_be_keep [0:5];
    reg        input_be_last [0:5];

    reg [63:0] input_le_data [0:5];
    reg [7:0]  input_le_keep [0:5];
    reg        input_le_last [0:5];

    reg [7:0]  expected_frame [0:85];

    reg [7:0]  captured_frame [0:127];
    integer    captured_count;

    initial begin
        // BE-on-tdata: each 32-bit DIFI word is placed with its MSB at
        // the high byte of the 32-bit half.  Word N at tdata[31:0],
        // word N+1 at tdata[63:32].
        input_be_data[0] = 64'h00000001_4900000B; input_be_keep[0] = 8'hFF; input_be_last[0] = 0;
        input_be_data[1] = 64'h00010004_006A621E; input_be_keep[1] = 8'hFF; input_be_last[1] = 0;
        input_be_data[2] = 64'h00000000_00000064; input_be_keep[2] = 8'hFF; input_be_last[2] = 0;
        input_be_data[3] = 64'h80000002_0BEBC200; input_be_keep[3] = 8'hFF; input_be_last[3] = 0;
        input_be_data[4] = 64'h00000004_0000000C; input_be_keep[4] = 8'hFF; input_be_last[4] = 0;
        input_be_data[5] = 64'h00000000_328C8400; input_be_keep[5] = 8'h0F; input_be_last[5] = 1;

        // LE-on-tdata: each 32-bit DIFI word has its bytes reversed
        // before being placed into its 32-bit half.
        input_le_data[0] = 64'h01000000_0B000049; input_le_keep[0] = 8'hFF; input_le_last[0] = 0;
        input_le_data[1] = 64'h04000100_1E626A00; input_le_keep[1] = 8'hFF; input_le_last[1] = 0;
        input_le_data[2] = 64'h00000000_64000000; input_le_keep[2] = 8'hFF; input_le_last[2] = 0;
        input_le_data[3] = 64'h02000080_00C2EB0B; input_le_keep[3] = 8'hFF; input_le_last[3] = 0;
        input_le_data[4] = 64'h04000000_0C000000; input_le_keep[4] = 8'hFF; input_le_last[4] = 0;
        input_le_data[5] = 64'h00000000_00848C32; input_le_keep[5] = 8'h0F; input_le_last[5] = 1;

        // Expected 86-byte Ethernet frame (wire order)
        expected_frame[ 0]=8'hFF; expected_frame[ 1]=8'hFF; expected_frame[ 2]=8'hFF; expected_frame[ 3]=8'hFF;
        expected_frame[ 4]=8'hFF; expected_frame[ 5]=8'hFF;
        expected_frame[ 6]=8'h02; expected_frame[ 7]=8'h00; expected_frame[ 8]=8'h00; expected_frame[ 9]=8'h00;
        expected_frame[10]=8'h00; expected_frame[11]=8'h01;
        expected_frame[12]=8'h08; expected_frame[13]=8'h00;
        expected_frame[14]=8'h45; expected_frame[15]=8'h00;
        expected_frame[16]=8'h00; expected_frame[17]=8'h48;
        expected_frame[18]=8'h00; expected_frame[19]=8'h00;
        expected_frame[20]=8'h40; expected_frame[21]=8'h00;
        expected_frame[22]=8'h40; expected_frame[23]=8'h11;
        expected_frame[24]=8'h78; expected_frame[25]=8'hF3;
        expected_frame[26]=8'hC0; expected_frame[27]=8'hA8; expected_frame[28]=8'h01; expected_frame[29]=8'h0A;
        expected_frame[30]=8'hFF; expected_frame[31]=8'hFF; expected_frame[32]=8'hFF; expected_frame[33]=8'hFF;
        expected_frame[34]=8'h13; expected_frame[35]=8'h7F;
        expected_frame[36]=8'h13; expected_frame[37]=8'h7F;
        expected_frame[38]=8'h00; expected_frame[39]=8'h34;
        expected_frame[40]=8'h00; expected_frame[41]=8'h00;
        expected_frame[42]=8'h49; expected_frame[43]=8'h00; expected_frame[44]=8'h00; expected_frame[45]=8'h0B;
        expected_frame[46]=8'h00; expected_frame[47]=8'h00; expected_frame[48]=8'h00; expected_frame[49]=8'h01;
        expected_frame[50]=8'h00; expected_frame[51]=8'h6A; expected_frame[52]=8'h62; expected_frame[53]=8'h1E;
        expected_frame[54]=8'h00; expected_frame[55]=8'h01; expected_frame[56]=8'h00; expected_frame[57]=8'h04;
        expected_frame[58]=8'h00; expected_frame[59]=8'h00; expected_frame[60]=8'h00; expected_frame[61]=8'h64;
        expected_frame[62]=8'h00; expected_frame[63]=8'h00; expected_frame[64]=8'h00; expected_frame[65]=8'h00;
        expected_frame[66]=8'h0B; expected_frame[67]=8'hEB; expected_frame[68]=8'hC2; expected_frame[69]=8'h00;
        expected_frame[70]=8'h80; expected_frame[71]=8'h00; expected_frame[72]=8'h00; expected_frame[73]=8'h02;
        expected_frame[74]=8'h00; expected_frame[75]=8'h00; expected_frame[76]=8'h00; expected_frame[77]=8'h0C;
        expected_frame[78]=8'h00; expected_frame[79]=8'h00; expected_frame[80]=8'h00; expected_frame[81]=8'h04;
        expected_frame[82]=8'h32; expected_frame[83]=8'h8C; expected_frame[84]=8'h84; expected_frame[85]=8'h00;
    end

    // ════════════════════════════════════════════════════════════════
    // AXI-Stream master driver. Holds each word until handshake.
    // ════════════════════════════════════════════════════════════════
    integer drive_i;
    task drive_input;
        input use_le;
        begin
            drive_i = 0;
            @(negedge clk);
            if (use_le) begin
                s_axis_tdata = input_le_data[0];
                s_axis_tkeep = input_le_keep[0];
                s_axis_tlast = input_le_last[0];
            end else begin
                s_axis_tdata = input_be_data[0];
                s_axis_tkeep = input_be_keep[0];
                s_axis_tlast = input_be_last[0];
            end
            s_axis_tvalid = 1;
            while (drive_i < 6) begin
                @(posedge clk);
                if (s_axis_tvalid && s_axis_tready) begin
                    drive_i = drive_i + 1;
                    @(negedge clk);
                    if (drive_i < 6) begin
                        if (use_le) begin
                            s_axis_tdata = input_le_data[drive_i];
                            s_axis_tkeep = input_le_keep[drive_i];
                            s_axis_tlast = input_le_last[drive_i];
                        end else begin
                            s_axis_tdata = input_be_data[drive_i];
                            s_axis_tkeep = input_be_keep[drive_i];
                            s_axis_tlast = input_be_last[drive_i];
                        end
                        s_axis_tvalid = 1;
                    end else begin
                        s_axis_tvalid = 0;
                        s_axis_tlast  = 0;
                        s_axis_tkeep  = 8'h00;
                    end
                end
            end
        end
    endtask

    // ════════════════════════════════════════════════════════════════
    // Capture: collect output bytes per tkeep until tlast
    // ════════════════════════════════════════════════════════════════
    integer cap_j;
    task capture_output;
        begin
            captured_count = 0;
            m_axis_tready = 1;
            while (1) begin
                @(posedge clk);
                if (m_axis_tvalid && m_axis_tready) begin
                    for (cap_j = 0; cap_j < 8; cap_j = cap_j + 1) begin
                        if (m_axis_tkeep[cap_j]) begin
                            captured_frame[captured_count] = m_axis_tdata[cap_j*8 +: 8];
                            captured_count = captured_count + 1;
                        end
                    end
                    if (m_axis_tlast) begin
                        m_axis_tready = 0;
                        disable capture_output;
                    end
                end
            end
        end
    endtask

    // ════════════════════════════════════════════════════════════════
    // Compare
    // ════════════════════════════════════════════════════════════════
    integer mismatch_count;
    integer first_mismatch;
    integer cmp_k;
    task compare_output;
        output result_pass;
        begin
            mismatch_count = 0;
            first_mismatch = -1;
            if (captured_count != 86) begin
                $display("    [compare] Captured %0d bytes, expected 86", captured_count);
                first_mismatch = 0;
                mismatch_count = (captured_count > 86) ? captured_count - 86 : 86 - captured_count;
            end
            for (cmp_k = 0; cmp_k < 86 && cmp_k < captured_count; cmp_k = cmp_k + 1) begin
                if (captured_frame[cmp_k] !== expected_frame[cmp_k]) begin
                    if (mismatch_count < 6) begin
                        $display("    [compare] byte[%0d]: got 0x%02X expected 0x%02X",
                                 cmp_k, captured_frame[cmp_k], expected_frame[cmp_k]);
                    end
                    if (first_mismatch < 0) first_mismatch = cmp_k;
                    mismatch_count = mismatch_count + 1;
                end
            end
            if (mismatch_count == 0) begin
                $display("    [compare] All 86 bytes match.");
                result_pass = 1;
            end else begin
                $display("    [compare] %0d mismatches (first at byte %0d)",
                         mismatch_count, first_mismatch);
                result_pass = 0;
            end
        end
    endtask

    // ════════════════════════════════════════════════════════════════
    // Scenario runner
    // ════════════════════════════════════════════════════════════════
    task run_scenario;
        input [1:0]   dut_idx;
        input [255:0] name;
        input         use_le_input;
        output        result;
        begin
            $display("");
            $display("--------------------------------------------------------------");
            $display(" SCENARIO %0d: %0s", dut_idx, name);
            $display("--------------------------------------------------------------");
            rst_n = 0;
            active_dut = dut_idx;
            s_axis_tvalid = 0;
            s_axis_tdata  = 64'h0;
            s_axis_tkeep  = 8'h00;
            s_axis_tlast  = 0;
            m_axis_tready = 0;
            repeat (5) @(posedge clk);
            rst_n = 1;
            repeat (3) @(posedge clk);

            fork
                drive_input(use_le_input);
                capture_output();
            join

            compare_output(result);
            $display("    Result: %s", result ? "PASS" : "FAIL");
            repeat (10) @(posedge clk);
        end
    endtask

    // ════════════════════════════════════════════════════════════════
    // Main
    // ════════════════════════════════════════════════════════════════
    reg pass_a, pass_b, pass_c, pass_d;
    initial begin
        $dumpfile("tb_udp.vcd");
        $dumpvars(0, tb_udp_broadcast_wrapper);

        $display("==============================================================");
        $display(" UDP BROADCAST WRAPPER TESTBENCH");
        $display(" Testing all 4 combinations of input format x SWAP_INPUT_BYTES");
        $display("==============================================================");

        repeat (10) @(posedge clk);

        run_scenario(2'd0, "BE-on-tdata input, SWAP_INPUT_BYTES=0", 1'b0, pass_a);
        run_scenario(2'd1, "BE-on-tdata input, SWAP_INPUT_BYTES=1", 1'b0, pass_b);
        run_scenario(2'd2, "LE-on-tdata input, SWAP_INPUT_BYTES=0", 1'b1, pass_c);
        run_scenario(2'd3, "LE-on-tdata input, SWAP_INPUT_BYTES=1", 1'b1, pass_d);

        $display("");
        $display("==============================================================");
        $display(" FINAL REPORT");
        $display("==============================================================");
        $display("  Scenario A (BE input, SWAP=0): %s", pass_a ? "PASS" : "FAIL");
        $display("  Scenario B (BE input, SWAP=1): %s", pass_b ? "PASS" : "FAIL");
        $display("  Scenario C (LE input, SWAP=0): %s", pass_c ? "PASS" : "FAIL");
        $display("  Scenario D (LE input, SWAP=1): %s", pass_d ? "PASS" : "FAIL");
        $display("");
        $display("--------------------------------------------------------------");
        $display(" INTERPRETATION");
        $display("--------------------------------------------------------------");
        if (pass_b && pass_c && !pass_a && !pass_d) begin
            $display("  Wrapper logic is CORRECT.");
            $display("");
            $display("  Your packetizers write tdata in the Verilog-natural way:");
            $display("  e.g. tdata <= 32'h4900_000B puts byte 0x49 at tdata[31:24].");
            $display("  This is BE-on-tdata.");
            $display("");
            $display("  ==> SET SWAP_INPUT_BYTES = 1 in your block design. <==");
        end else if (pass_a && pass_d && !pass_b && !pass_c) begin
            $display("  Swap logic appears INVERTED relative to expectations.");
        end else if (pass_a || pass_b || pass_c || pass_d) begin
            $display("  Mixed results - the wrapper has a bug somewhere.");
            $display("  Check waveforms (tb_udp.vcd).");
        end else begin
            $display("  ALL FOUR SCENARIOS FAILED.");
            $display("");
            $display("  The original SWAP_INPUT_BYTES code reverses the entire");
            $display("  64-bit word, which scrambles the order of the two 32-bit");
            $display("  DIFI words. The fix is to reverse bytes WITHIN each");
            $display("  32-bit half independently.");
            $display("");
            $display("  See udp_broadcast_wrapper_fixed.v for the corrected version.");
            $display("  Re-run this testbench against the fixed wrapper, and you");
            $display("  should get PASS for scenarios B and C.");
        end
        $display("==============================================================");
        $finish;
    end

    initial begin
        #500000;
        $display("ERROR: Testbench timed out after 500 us");
        $finish;
    end

endmodule
