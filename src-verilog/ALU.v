`timescale 1ns / 1ps

`include "defines.v"

module ALU #(parameter n = 32)(
    input      [n-1:0] A,
    input      [n-1:0] B,
    input      [3:0]   sel,
    output reg [n-1:0] aluOut,
    output reg         Z,
    output reg         C,
    output reg         V,
    output reg         S
);
wire [n-1:0] outputRCA;
wire [n-1:0] B_temp;
wire [n-1:0] shift_out;
reg  [1:0]   shiftSel;
wire         cout;
wire [4:0]   shift_amt;
assign shift_amt = B[4:0];
always @(*) begin
    case (sel)
        `ALU_SRL: shiftSel = 2'b01;
        `ALU_SRA: shiftSel = 2'b10;
        `ALU_SLL: shiftSel = 2'b00;
        default:  shiftSel = 2'b00;
    endcase
end
assign B_temp = (sel == `ALU_ADD) ? B : (~B + {{(n-1){1'b0}}, 1'b1});
RCA #n rca(.A(A), .B(B_temp), .sum(outputRCA), .cout(cout));

nbit_shiftleft #32 shift1(.A(A), .shift_amt(shift_amt), .shiftSel(shiftSel), .shiftResult(shift_out));

always @(*) begin
    case (sel)
        `ALU_ADD:  aluOut = outputRCA;
        `ALU_SUB:  aluOut = outputRCA;
        `ALU_AND:  aluOut = A & B;
        `ALU_OR:   aluOut = A | B;
        `ALU_XOR:  aluOut = A ^ B;
        `ALU_SRL:  aluOut = shift_out;
        `ALU_SRA:  aluOut = shift_out;
        `ALU_SLL:  aluOut = shift_out;
        `ALU_SLT:  aluOut = ($signed(A) < $signed(B)) ? {{(n-1){1'b0}}, 1'b1} : {n{1'b0}};
        `ALU_SLTU: aluOut = (A < B) ? {{(n-1){1'b0}}, 1'b1} : {n{1'b0}};
        default:   aluOut = {n{1'b0}};
    endcase
end
always @(*) begin
    Z = (aluOut == {n{1'b0}});
    C = cout;
    V = (A[n-1] & B_temp[n-1] & ~aluOut[n-1]) | (~A[n-1] & ~B_temp[n-1] & aluOut[n-1]);
    S = aluOut[n-1];
end
endmodule
