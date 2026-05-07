`timescale 1ns / 1ps


module RCA#(parameter n = 32)(input [n-1:0] A,input [n-1:0] B, output [n-1:0] sum, output cout);

wire [n-1:0] couts;


FA adder1(.A(A[0]), .B(B[0]), .cin(1'b0), .cout(couts[0]), .sum(sum[0]));

genvar i;
generate 
for(i=1; i<n; i=i+1)
    begin
        FA adder(.A(A[i]), .B(B[i]), .cin(couts[i-1]), .cout(couts[i]), .sum(sum[i]));
    end
endgenerate 

assign cout=couts[n-1];
    
    

endmodule
