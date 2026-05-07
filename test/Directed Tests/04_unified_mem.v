`timescale 1ns / 1ps
// Unified single-port byte-addressable memory for directed test 04
// Replace your unified_mem.v with this file when running test 04.

module unified_memory #(
    parameter MEM_BYTES  = 2048,
    parameter ADDR_WIDTH = 12
)(
    input clk,
    input mem_en,
    input mem_write,
    input [2:0] funct3,
    input [ADDR_WIDTH-1:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata
);

    reg [7:0] mem [0:MEM_BYTES-1];
    integer i;

    initial begin
        for (i = 0; i < MEM_BYTES; i = i + 1)
            mem[i] = 8'h00;

        mem[0] = 8'h93;
        mem[1] = 8'h00;
        mem[2] = 8'hc0;
        mem[3] = 8'h00;
        mem[4] = 8'h13;
        mem[5] = 8'h01;
        mem[6] = 8'h50;
        mem[7] = 8'h00;
        mem[8] = 8'h93;
        mem[9] = 8'h01;
        mem[10] = 8'h80;
        mem[11] = 8'hff;
        mem[12] = 8'h33;
        mem[13] = 8'h82;
        mem[14] = 8'h20;
        mem[15] = 8'h00;
        mem[16] = 8'hb3;
        mem[17] = 8'h82;
        mem[18] = 8'h20;
        mem[19] = 8'h40;
        mem[20] = 8'h33;
        mem[21] = 8'h93;
        mem[22] = 8'h20;
        mem[23] = 8'h00;
        mem[24] = 8'hb3;
        mem[25] = 8'ha3;
        mem[26] = 8'h21;
        mem[27] = 8'h00;
        mem[28] = 8'h33;
        mem[29] = 8'hb4;
        mem[30] = 8'h21;
        mem[31] = 8'h00;
        mem[32] = 8'hb3;
        mem[33] = 8'hc4;
        mem[34] = 8'h20;
        mem[35] = 8'h00;
        mem[36] = 8'h33;
        mem[37] = 8'hd5;
        mem[38] = 8'h20;
        mem[39] = 8'h00;
        mem[40] = 8'hb3;
        mem[41] = 8'hd5;
        mem[42] = 8'h21;
        mem[43] = 8'h40;
        mem[44] = 8'h33;
        mem[45] = 8'he6;
        mem[46] = 8'h20;
        mem[47] = 8'h00;
        mem[48] = 8'hb3;
        mem[49] = 8'hf6;
        mem[50] = 8'h20;
        mem[51] = 8'h00;
        mem[52] = 8'h73;
        mem[53] = 8'h00;
        mem[54] = 8'h00;
        mem[55] = 8'h00;
    end

    always @(posedge clk) begin
        if (mem_en) begin
            if (mem_write) begin
                case (funct3)
                    3'b000: mem[addr] <= wdata[7:0]; // SB
                    3'b001: begin // SH
                        mem[addr]     <= wdata[7:0];
                        mem[addr + 1] <= wdata[15:8];
                    end
                    3'b010: begin // SW
                        mem[addr]     <= wdata[7:0];
                        mem[addr + 1] <= wdata[15:8];
                        mem[addr + 2] <= wdata[23:16];
                        mem[addr + 3] <= wdata[31:24];
                    end
                    default: begin end
                endcase
            end

            case (funct3)
                3'b000: rdata <= {{24{mem[addr][7]}}, mem[addr]}; // LB
                3'b001: rdata <= {{16{mem[addr + 1][7]}}, mem[addr + 1], mem[addr]}; // LH
                3'b010: rdata <= {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]}; // LW/instruction
                3'b100: rdata <= {24'b0, mem[addr]}; // LBU
                3'b101: rdata <= {16'b0, mem[addr + 1], mem[addr]}; // LHU
                default: rdata <= {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};
            endcase
        end
    end

endmodule
