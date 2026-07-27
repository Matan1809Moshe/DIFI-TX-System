`timescale 1ns / 1ps

module dds_rate_ctrl #(
    parameter integer DIVISOR = 100
)(
    input  wire clk,
    input  wire rst_n,
    output reg  aclken_out
);

    reg [31:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter    <= 0;
            aclken_out <= 0;
        end else begin
            if (counter == DIVISOR - 1) begin
                counter    <= 0;
                aclken_out <= 1'b1;
            end else begin
                counter    <= counter + 1;
                aclken_out <= 1'b0;
            end
        end
    end
endmodule