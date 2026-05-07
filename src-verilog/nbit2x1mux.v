`timescale 1ns / 1ps


module nbit2x1mux #(parameter n=32)(
    input [n-1:0] A,
    input [n-1:0] B,
    input sel,
    output [n-1:0] D
    );
    
    genvar i;
    generate
    for (i=0; i<n; i=i+1)
        mux2x1 mux(.A(A[i]),.B(B[i]), .D(D[i]), .sel(sel));
    endgenerate
    
endmodule

