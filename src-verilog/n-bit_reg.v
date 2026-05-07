`timescale 1ns / 1ps


module nbit_reg #(parameter n = 32)(
    input clk,
    input load,
    input rst,
    input [n-1:0] D,
    output [n-1:0] Q
    );


    wire [n-1:0] c;
        
    genvar i;
    generate
    for (i=0; i<n; i = i+1) begin
        DFlipFlop ff (.clk(clk), .D(c[i]), .Q(Q[i]), .rst(rst));
        mux2x1 mux (.A(Q[i]), .B(D[i]), .sel(load), .D(c[i]));
    end
    endgenerate
endmodule
