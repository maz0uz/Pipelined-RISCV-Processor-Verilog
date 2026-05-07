`timescale 1ns / 1ps


module ForwardingUnit(
    input [4:0] ID_EX_RegisterRs1,
    input [4:0] ID_EX_RegisterRs2,
    input [4:0] EX_MEM_RegisterRd,
    input [4:0] MEM_WB_RegisterRd,
    input EX_MEM_RegWrite,
    input MEM_WB_RegWrite,
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

always @(*) begin
    forwardA = 2'b00;
    forwardB = 2'b00;

    if (EX_MEM_RegWrite && (EX_MEM_RegisterRd != 5'b00000) && (EX_MEM_RegisterRd == ID_EX_RegisterRs1))
        forwardA = 2'b10;
    else if (MEM_WB_RegWrite && (MEM_WB_RegisterRd != 5'b00000) && (MEM_WB_RegisterRd == ID_EX_RegisterRs1))
        forwardA = 2'b01;

    if (EX_MEM_RegWrite && (EX_MEM_RegisterRd != 5'b00000) && (EX_MEM_RegisterRd == ID_EX_RegisterRs2))
        forwardB = 2'b10;
    else if (MEM_WB_RegWrite && (MEM_WB_RegisterRd != 5'b00000) && (MEM_WB_RegisterRd == ID_EX_RegisterRs2))
        forwardB = 2'b01;
end

endmodule