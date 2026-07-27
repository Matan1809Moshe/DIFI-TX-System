`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// stream_arbiter.v
//
// Fixed-Priority AXI-Stream Arbiter for DIFI Packet Streams
//
// Merges three 32-bit AXI-Stream sources into a single output:
//   Priority 0 (highest): Version Context  (S_AXIS_VER)
//   Priority 1:           Signal Context   (S_AXIS_CTX)
//   Priority 2 (lowest):  Data             (S_AXIS_DATA)
//
// Behavior:
//   - Selects highest-priority source with TVALID at packet boundaries.
//   - Holds grant until TLAST transfers (never interrupts mid-packet).
//   - Non-selected sources see TREADY = 0 and stall.
//
// Vivado Integration:
//   Uses X_INTERFACE_INFO / X_INTERFACE_PARAMETER attributes so that
//   Vivado Block Design auto-infers AXI-Stream bus interfaces, clock,
//   and active-low reset. Just add as an RTL module source and drag
//   into the block design.
//////////////////////////////////////////////////////////////////////////////

module stream_arbiter #(
    parameter integer DATA_WIDTH = 32
)(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS_VER:S_AXIS_CTX:S_AXIS_DATA:M_AXIS, ASSOCIATED_RESET aresetn" *)
    input  wire aclk,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  wire aresetn,

    // ── Slave: Version Context (highest priority) ──────────────────
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_VER TDATA" *)
    input  wire [DATA_WIDTH-1:0] s_axis_ver_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_VER TVALID" *)
    input  wire                  s_axis_ver_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_VER TLAST" *)
    input  wire                  s_axis_ver_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_VER TREADY" *)
    output wire                  s_axis_ver_tready,

    // ── Slave: Signal Context ──────────────────────────────────────
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_CTX TDATA" *)
    input  wire [DATA_WIDTH-1:0] s_axis_ctx_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_CTX TVALID" *)
    input  wire                  s_axis_ctx_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_CTX TLAST" *)
    input  wire                  s_axis_ctx_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_CTX TREADY" *)
    output wire                  s_axis_ctx_tready,

    // ── Slave: Data (lowest priority) ──────────────────────────────
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_DATA TDATA" *)
    input  wire [DATA_WIDTH-1:0] s_axis_data_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_DATA TVALID" *)
    input  wire                  s_axis_data_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_DATA TLAST" *)
    input  wire                  s_axis_data_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_DATA TREADY" *)
    output wire                  s_axis_data_tready,

    // ── Master: to Width Converter / MAC ───────────────────────────
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output reg                   m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
    output reg                   m_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
    input  wire                  m_axis_tready
);

    // ================================================================
    // Grant Encoding
    // ================================================================
    localparam [1:0] GRANT_NONE    = 2'd0;
    localparam [1:0] GRANT_VERSION = 2'd1;
    localparam [1:0] GRANT_CONTEXT = 2'd2;
    localparam [1:0] GRANT_DATA    = 2'd3;

    reg [1:0] grant;
    reg       locked;

    // ================================================================
    // Transfer detection
    // ================================================================
    wire transfer    = m_axis_tvalid && m_axis_tready;
    wire packet_done = transfer && m_axis_tlast;

    // ================================================================
    // Arbitration Logic (Sequential)
    // ================================================================
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            grant  <= GRANT_NONE;
            locked <= 1'b0;
        end else begin
            if (locked) begin
                if (packet_done) begin
                    locked <= 1'b0;
                    grant  <= GRANT_NONE;
                end
            end else begin
                if (s_axis_ver_tvalid) begin
                    grant  <= GRANT_VERSION;
                    locked <= 1'b1;
                end else if (s_axis_ctx_tvalid) begin
                    grant  <= GRANT_CONTEXT;
                    locked <= 1'b1;
                end else if (s_axis_data_tvalid) begin
                    grant  <= GRANT_DATA;
                    locked <= 1'b1;
                end else begin
                    grant  <= GRANT_NONE;
                    locked <= 1'b0;
                end
            end
        end
    end

    // ================================================================
    // Output MUX (Combinatorial)
    // ================================================================
    always @(*) begin
        case (grant)
            GRANT_VERSION: begin
                m_axis_tdata  = s_axis_ver_tdata;
                m_axis_tvalid = s_axis_ver_tvalid;
                m_axis_tlast  = s_axis_ver_tlast;
            end
            GRANT_CONTEXT: begin
                m_axis_tdata  = s_axis_ctx_tdata;
                m_axis_tvalid = s_axis_ctx_tvalid;
                m_axis_tlast  = s_axis_ctx_tlast;
            end
            GRANT_DATA: begin
                m_axis_tdata  = s_axis_data_tdata;
                m_axis_tvalid = s_axis_data_tvalid;
                m_axis_tlast  = s_axis_data_tlast;
            end
            default: begin
                m_axis_tdata  = {DATA_WIDTH{1'b0}};
                m_axis_tvalid = 1'b0;
                m_axis_tlast  = 1'b0;
            end
        endcase
    end

    // ================================================================
    // Ready Routing
    // ================================================================
    assign s_axis_ver_tready  = (grant == GRANT_VERSION) ? m_axis_tready : 1'b0;
    assign s_axis_ctx_tready  = (grant == GRANT_CONTEXT) ? m_axis_tready : 1'b0;
    assign s_axis_data_tready = (grant == GRANT_DATA)    ? m_axis_tready : 1'b0;

endmodule