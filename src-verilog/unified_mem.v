`timescale 1ns / 1ps

module unified_memory #(
    parameter MEM_BYTES    = 4096,
    parameter ADDR_WIDTH   = 12,
    parameter PROGRAM_FILE = "C:/Users/mohamedazouz/Downloads/program.hex",
    parameter DATA_FILE    = "C:/Users/mohamedazouz/Downloads/data.hex",
    parameter DATA_OFFSET  = 2048
)(
    input clk,
    input mem_en,
    input mem_write,
    input [2:0] funct3,
    input [ADDR_WIDTH-1:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata
);
    initial begin
        for (i = 0; i < MEM_BYTES; i = i + 1)
            mem[i] = 8'b0;
        if (PROGRAM_FILE != "") begin
            $display("Loading program file: %s", PROGRAM_FILE);
            $readmemh(PROGRAM_FILE, mem, 0);
        end
        if (DATA_FILE != "") begin
            $display("Loading data file: %s at offset %0d", DATA_FILE, DATA_OFFSET);
            $readmemh(DATA_FILE, mem, DATA_OFFSET);
        end
    end
    reg [7:0] mem [0:MEM_BYTES-1];
    integer i;
    initial begin
        for (i = 0; i < MEM_BYTES; i = i + 1)
            mem[i] = 8'b0;
        if (PROGRAM_FILE != "")
            $readmemh(PROGRAM_FILE, mem, 0);
        if (DATA_FILE != "")
            $readmemh(DATA_FILE, mem, DATA_OFFSET);
    end
    always @(*) begin
        rdata = 32'b0;
        if (mem_en && !mem_write) begin
            case (funct3)
                3'b000: rdata = {{24{mem[addr][7]}}, mem[addr]};
                3'b001: rdata = {{16{mem[addr + 1][7]}}, mem[addr + 1], mem[addr]};
                3'b010: rdata = {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};
                3'b100: rdata = {24'b0, mem[addr]};
                3'b101: rdata = {16'b0, mem[addr + 1], mem[addr]};
                default: rdata = 32'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (mem_en && mem_write) begin
            case (funct3)
                3'b000: begin
                    mem[addr] <= wdata[7:0];
                end
                3'b001: begin
                    mem[addr]     <= wdata[7:0];
                    mem[addr + 1] <= wdata[15:8];
                end

                3'b010: begin
                    mem[addr]     <= wdata[7:0];
                    mem[addr + 1] <= wdata[15:8];
                    mem[addr + 2] <= wdata[23:16];
                    mem[addr + 3] <= wdata[31:24];
                end
            endcase
        end
    end

endmodule