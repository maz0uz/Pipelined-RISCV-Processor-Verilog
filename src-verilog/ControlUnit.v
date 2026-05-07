`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ControlUnit
// Description:
//   Main RV32I control decoder.
//
// Notes:
//   - Decodes using instruction[6:2], matching the opcode constants in defines.v.
//   - ECALL, EBREAK, FENCE, FENCE.TSO, and PAUSE are treated as halt instructions
//     for this project by asserting endProgram and disabling all architectural writes.
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ControlUnit(
    input  [6:0] instruction,
    output reg       Branch,
    output reg       MemRead,
    output reg       MemtoReg,
    output reg [1:0] ALUOp,
    output reg       MemWrite,
    output reg       ALUSrc,
    output reg       RegWrite,
    output reg [1:0] PCSel,
    output reg       AUIPCSel,
    output reg       endProgram,
    output reg [1:0] writeData_Sel
);

    // instruction[6:2] for the RV32I MISC-MEM opcode: FENCE/FENCE.TSO/PAUSE.
    localparam [4:0] OPCODE_MISC_MEM = 5'b00_011;

    always @(*) begin
        // Safe defaults: NOP-like behavior, PC continues normally.
        Branch        = 1'b0;
        MemRead       = 1'b0;
        MemtoReg      = 1'b0;
        ALUOp         = 2'b00;
        MemWrite      = 1'b0;
        ALUSrc        = 1'b0;
        RegWrite      = 1'b0;
        PCSel         = 2'b00;
        AUIPCSel      = 1'b0;
        endProgram    = 1'b0;
        writeData_Sel = 2'b10;  // default ALU/memory WB path

        case (instruction[6:2])
            `OPCODE_Arith_R: begin
                // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                ALUOp         = 2'b10;
                ALUSrc        = 1'b0;
                RegWrite      = 1'b1;
                writeData_Sel = 2'b10;
            end

            `OPCODE_Arith_I: begin
                // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
                ALUOp         = 2'b11;
                ALUSrc        = 1'b1;
                RegWrite      = 1'b1;
                writeData_Sel = 2'b10;
            end

            `OPCODE_Load: begin
                // LB, LH, LW, LBU, LHU
                MemRead       = 1'b1;
                MemtoReg      = 1'b1;
                ALUOp         = 2'b00;  // address = rs1 + imm
                ALUSrc        = 1'b1;
                RegWrite      = 1'b1;
                writeData_Sel = 2'b10;
            end

            `OPCODE_Store: begin
                // SB, SH, SW
                MemWrite      = 1'b1;
                ALUOp         = 2'b00;  // address = rs1 + imm
                ALUSrc        = 1'b1;
                RegWrite      = 1'b0;
            end

            `OPCODE_Branch: begin
                // BEQ, BNE, BLT, BGE, BLTU, BGEU
                Branch        = 1'b1;
                ALUOp         = 2'b01;  // subtract/compare path
                ALUSrc        = 1'b0;
                RegWrite      = 1'b0;
                PCSel         = 2'b01;  // PC + branch immediate
            end

            `OPCODE_JALR: begin
                // JALR: rd = PC+4, PC = rs1 + imm. Masking bit 0 is handled in datapath.
                Branch        = 1'b1;
                ALUOp         = 2'b00;
                ALUSrc        = 1'b1;
                RegWrite      = 1'b1;
                PCSel         = 2'b10;  // ALU result target
                writeData_Sel = 2'b00;  // PC + 4
            end

            `OPCODE_JAL: begin
                // JAL: rd = PC+4, PC = PC + imm
                Branch        = 1'b1;
                ALUOp         = 2'b00;
                ALUSrc        = 1'b0;
                RegWrite      = 1'b1;
                PCSel         = 2'b01;  // PC + jump immediate
                writeData_Sel = 2'b00;  // PC + 4
            end

            `OPCODE_AUIPC: begin
                // AUIPC: rd = PC + upper immediate
                RegWrite      = 1'b1;
                AUIPCSel      = 1'b1;
                writeData_Sel = 2'b01;  // PC + imm path
            end

            `OPCODE_LUI: begin
                // LUI: rd = upper immediate
                RegWrite      = 1'b1;
                AUIPCSel      = 1'b0;
                writeData_Sel = 2'b11;  // immediate path
            end

            `OPCODE_SYSTEM: begin
                // ECALL/EBREAK are halting instructions in this project.
                endProgram    = 1'b1;
                RegWrite      = 1'b0;
                MemRead       = 1'b0;
                MemWrite      = 1'b0;
                Branch        = 1'b0;
            end

            OPCODE_MISC_MEM: begin
                // FENCE, FENCE.TSO, and PAUSE are halting instructions in this project.
                endProgram    = 1'b1;
                RegWrite      = 1'b0;
                MemRead       = 1'b0;
                MemWrite      = 1'b0;
                Branch        = 1'b0;
            end

            default: begin
                // Illegal/unsupported opcode: no architectural side effects.
                // Do not halt here so that unused all-zero memory behaves like NOP bubbles.
            end
        endcase
    end

endmodule
