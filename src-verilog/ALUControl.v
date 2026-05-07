`timescale 1ns / 1ps

`include "defines.v"

module ALUControlUnit(
    input  [31:0] instruction,
    input  [1:0]  ALUOp,
    output reg [3:0] ALUSel
);

    wire [2:0] funct3;
    wire       funct7_bit5;

    assign funct3     = instruction[`IR_funct3];
    assign funct7_bit5 = instruction[30];

    always @(*) begin
        ALUSel = `ALU_ADD;
        case (ALUOp)
            2'b00: begin
                ALUSel = `ALU_ADD;
            end
            2'b01: begin
                ALUSel = `ALU_SUB;
            end
            2'b10: begin
                case (funct3)
                    `F3_ADD:  ALUSel = funct7_bit5 ? `ALU_SUB  : `ALU_ADD;
                    `F3_SLL:  ALUSel = `ALU_SLL;
                    `F3_SLT:  ALUSel = `ALU_SLT;
                    `F3_SLTU: ALUSel = `ALU_SLTU;
                    `F3_XOR:  ALUSel = `ALU_XOR;
                    `F3_SRL:  ALUSel = funct7_bit5 ? `ALU_SRA  : `ALU_SRL;
                    `F3_OR:   ALUSel = `ALU_OR;
                    `F3_AND:  ALUSel = `ALU_AND;
                    default:  ALUSel = `ALU_ADD;
                endcase
            end
            2'b11: begin
                case (funct3)
                    `F3_ADD:  ALUSel = `ALU_ADD;
                    `F3_SLL:  ALUSel = `ALU_SLL;
                    `F3_SLT:  ALUSel = `ALU_SLT;
                    `F3_SLTU: ALUSel = `ALU_SLTU;
                    `F3_XOR:  ALUSel = `ALU_XOR;
                    `F3_SRL:  ALUSel = funct7_bit5 ? `ALU_SRA  : `ALU_SRL;
                    `F3_OR:   ALUSel = `ALU_OR;
                    `F3_AND:  ALUSel = `ALU_AND;
                    default:  ALUSel = `ALU_ADD;
                endcase
            end

            default: begin
                ALUSel = `ALU_ADD;
            end
        endcase
    end

endmodule
