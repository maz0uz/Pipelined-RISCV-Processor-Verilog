`timescale 1ns / 1ps


module nbit_shiftleft #(parameter n= 32)(input [n-1:0] A, [4:0] shift_amt, [1:0] shiftSel, output reg [n-1:0] shiftResult);
integer i;
always @(*) begin
shiftResult = A;
    for(i=0; i<shift_amt; i=i+1)begin
        case(shiftSel)
        2'b00: shiftResult = {shiftResult[n-2:0],1'b0}; // SLL
        2'b01: shiftResult = {1'b0,shiftResult[n-1:1]}; // SRL
        2'b10: shiftResult = {A[n-1],shiftResult[n-1:1]}; // SRA
        endcase
    end
end
endmodule 

