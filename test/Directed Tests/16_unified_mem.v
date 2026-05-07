`timescale 1ns / 1ps
// Unified single-port byte-addressable memory for directed test 16
// Replace your unified_mem.v with this file when running test 16.

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
        mem[2] = 8'h10;
        mem[3] = 8'h00;
        mem[4] = 8'h0f;
        mem[5] = 8'h00;
        mem[6] = 8'hf0;
        mem[7] = 8'h0f;
        mem[8] = 8'h13;
        mem[9] = 8'h01;
        mem[10] = 8'h30;
        mem[11] = 8'h06;
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
