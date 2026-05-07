`timescale 1ns / 1ps


module nbit_4x1mux #(parameter n = 32)(input [n-1:0] A ,input [n-1:0] B , input [n-1:0] C,input [n-1:0] D,input [1:0] sel,output [n-1:0] out);
    wire [n-1:0] mux1Out, mux2Out;
    genvar i;

        nbit2x1mux #(n) mux1 (.A(A), .B(B), .sel(sel[0]), .D(mux1Out));
        nbit2x1mux #(n) mux2 (.A(C), .B(D), .sel(sel[0]), .D(mux2Out));
        nbit2x1mux #(n) mux3 (.A(mux1Out), .B(mux2Out), .sel(sel[1]), .D(out));
endmodule

