`timescale 1ns / 1ps


module reg_file #(parameter n=32)(
    input clk, 
    input rst,
    input [4:0] readAddr1, 
    input [4:0] readAddr2, 
    input [4:0] writeAddr, 
    input wr_en, 
    input [n-1:0] writeData, 
    output [n-1:0] readData1, 
    output [n-1:0]readData2
    );
    
    reg [n-1:0] regfile [31:0];
    
    integer i;
    always@(posedge clk or posedge rst) begin
    
        if(rst)
            for(i = 0; i < n; i = i+1)
                regfile[i] <= {n{1'b0}};
        else begin
            if(wr_en && (writeAddr != 5'b0))
               regfile[writeAddr] <= writeData;
             
        end
    end
    
    assign readData1 = regfile[readAddr1];
    assign readData2 = regfile[readAddr2];
endmodule
