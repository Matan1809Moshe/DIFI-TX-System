set_property PACKAGE_PIN F9 [get_ports diff_clock_rtl_clk_n]
set_property PACKAGE_PIN F10 [get_ports diff_clock_rtl_clk_p]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list design_1_i/xxv_ethernet_0/inst/i_core_gtwiz_userclk_tx_inst_0/tx_clk]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {design_1_i/stream_arbiter_0_M_AXIS_TDATA[0]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[1]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[2]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[3]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[4]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[5]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[6]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[7]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[8]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[9]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[10]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[11]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[12]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[13]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[14]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[15]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[16]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[17]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[18]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[19]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[20]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[21]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[22]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[23]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[24]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[25]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[26]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[27]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[28]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[29]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[30]} {design_1_i/stream_arbiter_0_M_AXIS_TDATA[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {design_1_i/sync_data_fifo_M_AXIS_TDATA[0]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[1]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[2]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[3]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[4]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[5]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[6]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[7]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[8]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[9]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[10]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[11]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[12]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[13]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[14]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[15]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[16]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[17]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[18]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[19]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[20]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[21]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[22]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[23]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[24]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[25]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[26]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[27]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[28]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[29]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[30]} {design_1_i/sync_data_fifo_M_AXIS_TDATA[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 64 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[0]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[1]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[2]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[3]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[4]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[5]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[6]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[7]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[8]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[9]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[10]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[11]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[12]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[13]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[14]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[15]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[16]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[17]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[18]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[19]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[20]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[21]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[22]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[23]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[24]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[25]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[26]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[27]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[28]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[29]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[30]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[31]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[32]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[33]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[34]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[35]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[36]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[37]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[38]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[39]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[40]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[41]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[42]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[43]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[44]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[45]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[46]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[47]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[48]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[49]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[50]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[51]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[52]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[53]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[54]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[55]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[56]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[57]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[58]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[59]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[60]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[61]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[62]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TDATA[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {design_1_i/udp_broadcast_wrapper_0_m_axis_TKEEP[0]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TKEEP[1]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TKEEP[2]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TKEEP[3]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TKEEP[4]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TKEEP[5]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TKEEP[6]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TKEEP[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 64 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[0]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[1]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[2]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[3]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[4]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[5]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[6]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[7]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[8]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[9]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[10]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[11]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[12]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[13]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[14]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[15]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[16]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[17]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[18]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[19]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[20]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[21]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[22]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[23]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[24]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[25]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[26]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[27]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[28]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[29]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[30]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[31]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[32]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[33]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[34]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[35]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[36]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[37]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[38]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[39]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[40]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[41]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[42]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[43]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[44]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[45]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[46]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[47]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[48]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[49]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[50]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[51]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[52]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[53]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[54]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[55]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[56]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[57]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[58]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[59]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[60]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[61]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[62]} {design_1_i/udp_broadcast_wrapper_0_m_axis_TDATA[63]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 4 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {design_1_i/axis_dwidth_converter_0_M_AXIS_TKEEP[4]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TKEEP[5]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TKEEP[6]} {design_1_i/axis_dwidth_converter_0_M_AXIS_TKEEP[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list design_1_i/axis_dwidth_converter_0_M_AXIS_TLAST]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list design_1_i/axis_dwidth_converter_0_M_AXIS_TREADY]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list design_1_i/axis_dwidth_converter_0_M_AXIS_TVALID]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list design_1_i/stream_arbiter_0_M_AXIS_TLAST]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list design_1_i/stream_arbiter_0_M_AXIS_TREADY]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list design_1_i/stream_arbiter_0_M_AXIS_TVALID]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list design_1_i/sync_data_fifo_M_AXIS_TLAST]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list design_1_i/sync_data_fifo_M_AXIS_TREADY]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list design_1_i/sync_data_fifo_M_AXIS_TVALID]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list design_1_i/udp_broadcast_wrapper_0_m_axis_TLAST]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list design_1_i/udp_broadcast_wrapper_0_m_axis_TREADY]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list design_1_i/udp_broadcast_wrapper_0_m_axis_TVALID]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
