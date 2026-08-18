//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.2 (lin64) Build 4029153 Fri Oct 13 20:13:54 MDT 2023
//Date        : Mon May  4 16:53:44 2026
//Host        : daniel running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (ddr4_act_n,
    ddr4_adr,
    ddr4_ba,
    ddr4_bg,
    ddr4_ck_c,
    ddr4_ck_t,
    ddr4_cke,
    ddr4_cs_n,
    ddr4_dm_n,
    ddr4_dq,
    ddr4_dqs_c,
    ddr4_dqs_t,
    ddr4_odt,
    ddr4_reset_n,
    ddr4_sysclk_clk_n,
    ddr4_sysclk_clk_p,
    diff_clock_rtl_clk_n,
    diff_clock_rtl_clk_p,
    gt_rtl_grx_n,
    gt_rtl_grx_p,
    gt_rtl_gtx_n,
    gt_rtl_gtx_p);
  output ddr4_act_n;
  output [16:0]ddr4_adr;
  output [1:0]ddr4_ba;
  output ddr4_bg;
  output ddr4_ck_c;
  output ddr4_ck_t;
  output ddr4_cke;
  output ddr4_cs_n;
  inout [1:0]ddr4_dm_n;
  inout [15:0]ddr4_dq;
  inout [1:0]ddr4_dqs_c;
  inout [1:0]ddr4_dqs_t;
  output ddr4_odt;
  output ddr4_reset_n;
  input ddr4_sysclk_clk_n;
  input ddr4_sysclk_clk_p;
  input diff_clock_rtl_clk_n;
  input diff_clock_rtl_clk_p;
  input [0:0]gt_rtl_grx_n;
  input [0:0]gt_rtl_grx_p;
  output [0:0]gt_rtl_gtx_n;
  output [0:0]gt_rtl_gtx_p;

  wire ddr4_act_n;
  wire [16:0]ddr4_adr;
  wire [1:0]ddr4_ba;
  wire ddr4_bg;
  wire ddr4_ck_c;
  wire ddr4_ck_t;
  wire ddr4_cke;
  wire ddr4_cs_n;
  wire [1:0]ddr4_dm_n;
  wire [15:0]ddr4_dq;
  wire [1:0]ddr4_dqs_c;
  wire [1:0]ddr4_dqs_t;
  wire ddr4_odt;
  wire ddr4_reset_n;
  wire ddr4_sysclk_clk_n;
  wire ddr4_sysclk_clk_p;
  wire diff_clock_rtl_clk_n;
  wire diff_clock_rtl_clk_p;
  wire [0:0]gt_rtl_grx_n;
  wire [0:0]gt_rtl_grx_p;
  wire [0:0]gt_rtl_gtx_n;
  wire [0:0]gt_rtl_gtx_p;

  design_1 design_1_i
       (.ddr4_act_n(ddr4_act_n),
        .ddr4_adr(ddr4_adr),
        .ddr4_ba(ddr4_ba),
        .ddr4_bg(ddr4_bg),
        .ddr4_ck_c(ddr4_ck_c),
        .ddr4_ck_t(ddr4_ck_t),
        .ddr4_cke(ddr4_cke),
        .ddr4_cs_n(ddr4_cs_n),
        .ddr4_dm_n(ddr4_dm_n),
        .ddr4_dq(ddr4_dq),
        .ddr4_dqs_c(ddr4_dqs_c),
        .ddr4_dqs_t(ddr4_dqs_t),
        .ddr4_odt(ddr4_odt),
        .ddr4_reset_n(ddr4_reset_n),
        .ddr4_sysclk_clk_n(ddr4_sysclk_clk_n),
        .ddr4_sysclk_clk_p(ddr4_sysclk_clk_p),
        .diff_clock_rtl_clk_n(diff_clock_rtl_clk_n),
        .diff_clock_rtl_clk_p(diff_clock_rtl_clk_p),
        .gt_rtl_grx_n(gt_rtl_grx_n),
        .gt_rtl_grx_p(gt_rtl_grx_p),
        .gt_rtl_gtx_n(gt_rtl_gtx_n),
        .gt_rtl_gtx_p(gt_rtl_gtx_p));
endmodule
