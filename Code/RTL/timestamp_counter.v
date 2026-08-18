`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// time_counter.v
//
// DIFI-compliant timestamp generator.
//
// Produces two outputs per the DIFI Standard V1.2.1, Section 4.1:
//
//   ts_seconds      [31:0]  - Integer Seconds Timestamp
//                             Increments once per second.
//                             Reset value defines the epoch reference.
//
//   ts_picoseconds  [63:0]  - Fractional Seconds Timestamp (Real Time)
//                             Number of picoseconds since the most recent
//                             increment of ts_seconds.
//                             Resets to zero every time ts_seconds increments.
//                             Maximum value: 999,999,999,999 (just under 10^12)
module timestamp_counter #(
    // Clock period in picoseconds.
    // 156.25 MHz → 1/156.25e6 s = 6.4 ns = 6400 ps
    // 100.00 MHz → 10 ns = 10000 ps
    // 200.00 MHz → 5 ns  = 5000 ps
    parameter integer CLK_PERIOD_PS  = 6400,
 
    // Initial value for the seconds counter (lets you set an epoch offset).
    // For testing, leave at 0. For real systems, load from PS or PTP.
    parameter [31:0] INITIAL_SECONDS = 32'h0
)(
    input  wire        clk,
    input  wire        rst_n,
 
    // Optional synchronous load (for setting time from PS / PTP).
    // Pulse load_en for one cycle with the new values on load_seconds.
    // Picoseconds counter is reset to 0 on load.
    input  wire        load_en,
    input  wire [31:0] load_seconds,
 
    // DIFI timestamp outputs
    output reg  [31:0] ts_seconds,
    output reg  [63:0] ts_picoseconds
);
 
    // One second = 10^12 picoseconds
    localparam [63:0] PICOSECONDS_PER_SEC = 64'd1_000_000_000_000;
 
    // Sum of current picoseconds + one clock period
    wire [63:0] next_picos = ts_picoseconds + CLK_PERIOD_PS;
 
    // Has the picoseconds counter reached or exceeded 1 second?
    wire second_rollover = (next_picos >= PICOSECONDS_PER_SEC);
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ts_seconds     <= INITIAL_SECONDS;
            ts_picoseconds <= 64'd0;
        end else if (load_en) begin
            // Synchronous load from external source (PS / PTP)
            ts_seconds     <= load_seconds;
            ts_picoseconds <= 64'd0;
        end else if (second_rollover) begin
            // Picoseconds counter wraps; seconds increments.
            // The wrapped value handles the case where one clock period
            // straddles the second boundary.
            ts_seconds     <= ts_seconds + 32'd1;
            ts_picoseconds <= next_picos - PICOSECONDS_PER_SEC;
        end else begin
            // Normal increment by one clock period
            ts_picoseconds <= next_picos;
        end
    end
 
endmodule
