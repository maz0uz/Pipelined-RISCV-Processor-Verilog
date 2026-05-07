`timescale 1ns / 1ps
`include "defines.v"

module riscv(
    input clk,
    input rst
);
    reg phase;
    wire c0 = ~phase;
    wire c1 =  phase;

    wire halted_decode;
    reg  halted;
    wire stop_fetch;
    wire load_use_hazard;
    wire id_branch_load_hazard;
    wire id_stall_hazard;
    reg  stall_fetch_next;
    wire if_id_uses_rs2;
    wire if_id_uses_rs1;
    wire if_id_is_branch;
    wire if_id_is_jal;
    wire if_id_is_jalr;

    assign stop_fetch = halted;

    always @(posedge clk or posedge rst) begin
        if (rst)
            phase <= 1'b0;
        else
            phase <= ~phase;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            halted <= 1'b0;
        else if (c1 && halted_decode)
            halted <= 1'b1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            stall_fetch_next <= 1'b0;
        else if (c1)
            stall_fetch_next <= id_stall_hazard;
        else if (c0)
            stall_fetch_next <= 1'b0;
    end
    wire Branch;
    wire MemRead;
    wire MemtoReg;
    wire [1:0] ALUOp;
    wire MemWrite;
    wire ALUSrc;
    wire RegWrite;
    wire [1:0] PCSel;
    wire AUIPCSel;
    wire [1:0] writeData_Sel;
    wire [31:0] writeData;
    wire [31:0] writeBackMuxOut;
    wire [31:0] readData_1;
    wire [31:0] readData_2;

    reg  [31:0] PC_in;
    wire [31:0] PC_Out;
    wire [31:0] PC_inc;

    wire [31:0] immOut;
    wire [31:0] ALUmux_out;
    wire [3:0]  ALUSel;
    wire [31:0] ALUres;
    wire [31:0] memOut;
    wire [31:0] branchAdder_out;
    wire [31:0] id_branch_target;
    wire [31:0] id_jalr_sum;
    wire [31:0] id_jalr_target;
    wire [31:0] id_rs1_value;
    wire [31:0] id_rs2_value;
    wire [31:0] ex_mem_forward_value;
    wire        ex_mem_forward_valid;
    wire        mem_wb_forward_valid;
    wire Z, V, C, S;
    reg branchRes;

    wire [31:0] IF_ID_PC;
    wire [31:0] IF_ID_Instr;
    wire [31:0] IF_ID_PCadd4;

    wire [31:0] ID_EX_PC;
    wire [31:0] ID_EX_readData_1;
    wire [31:0] ID_EX_readData_2;
    wire [31:0] ID_EX_immediate;
    wire [31:0] ID_EX_PCadd4;
    wire [7:0]  ID_EX_ctrl;
    wire [3:0]  ID_EX_func;
    wire [4:0]  ID_EX_rs1;
    wire [4:0]  ID_EX_rs2;
    wire [4:0]  ID_EX_rd;
    wire [4:0]  ID_EX_opcode;
    wire [1:0]  ID_EX_PCsel;
    wire [1:0]  ID_EX_writeSel;

    wire [31:0] EX_MEM_branchAdd;
    wire [31:0] EX_MEM_ALUOut;
    wire [31:0] EX_MEM_readData_2;
    wire [31:0] EX_MEM_immediate;
    wire [31:0] EX_MEM_PCadd4;
    wire [4:0]  EX_MEM_ctrl;
    wire [4:0]  EX_MEM_rd;
    wire [4:0]  EX_MEM_opcode;
    wire        EX_MEM_Z;
    wire        EX_MEM_V;
    wire        EX_MEM_C;
    wire        EX_MEM_S;
    wire [2:0]  EX_MEM_funct3;
    wire [1:0]  EX_MEM_writeSel;

    wire [31:0] MEM_WB_memOut;
    wire [31:0] MEM_WB_ALUOut;
    wire [31:0] MEM_WB_PCadd4;
    wire [31:0] MEM_WB_branchAdd;
    wire [31:0] MEM_WB_immediate;
    wire [1:0]  MEM_WB_ctrl;
    wire [1:0]  MEM_WB_writeSel;
    wire [4:0]  MEM_WB_rd;

    wire [1:0] forwardA;
    wire [1:0] forwardB;
    wire [31:0] forwardMuxA_out;
    wire [31:0] forwardMuxB_out;

    wire [7:0] ctrlFlushMuxOut;
    wire [4:0] flush_EX_MEM;
    wire [31:0] IF_ID_instr_in;

    nbit_reg #(.n(32)) PC (.clk(clk), .load(c0 & ~stop_fetch & ~stall_fetch_next), .rst(rst), .D(PC_in), .Q(PC_Out));

    RCA pcplus4(.A(PC_Out), .B(32'd4), .sum(PC_inc));

    assign IF_ID_instr_in = (branchRes | rst) ? 32'd0 : memOut;

    nbit_reg #(.n(96)) IF_ID(.clk(clk), .load(c0 & ~stop_fetch & ~stall_fetch_next), .rst(rst), .D({PC_inc, PC_Out, IF_ID_instr_in}), .Q({IF_ID_PCadd4, IF_ID_PC, IF_ID_Instr}));

    ControlUnit controlunit(.instruction(IF_ID_Instr[6:0]), .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg), .ALUOp(ALUOp), .MemWrite(MemWrite), .ALUSrc(ALUSrc), .RegWrite(RegWrite), .PCSel(PCSel), .AUIPCSel(AUIPCSel), .endProgram(halted_decode), .writeData_Sel(writeData_Sel));

    assign if_id_is_branch = (IF_ID_Instr[6:2] == `OPCODE_Branch);
    assign if_id_is_jal    = (IF_ID_Instr[6:2] == `OPCODE_JAL);
    assign if_id_is_jalr   = (IF_ID_Instr[6:2] == `OPCODE_JALR);

    assign if_id_uses_rs1 = (IF_ID_Instr[6:2] == `OPCODE_Arith_R) ||
                            (IF_ID_Instr[6:2] == `OPCODE_Arith_I) ||
                            (IF_ID_Instr[6:2] == `OPCODE_Load)    ||
                            (IF_ID_Instr[6:2] == `OPCODE_Store)   ||
                            (IF_ID_Instr[6:2] == `OPCODE_Branch)  ||
                            (IF_ID_Instr[6:2] == `OPCODE_JALR);

    assign if_id_uses_rs2 = (IF_ID_Instr[6:2] == `OPCODE_Arith_R) ||
                            (IF_ID_Instr[6:2] == `OPCODE_Branch)  ||
                            (IF_ID_Instr[6:2] == `OPCODE_Store);

    assign load_use_hazard = ID_EX_ctrl[5] && (ID_EX_rd != 5'd0) && ((if_id_uses_rs1 && (ID_EX_rd == IF_ID_Instr[19:15])) || (if_id_uses_rs2 && (ID_EX_rd == IF_ID_Instr[24:20])));

    assign id_branch_load_hazard = (if_id_is_branch || if_id_is_jalr) && EX_MEM_ctrl[2] && (EX_MEM_rd != 5'd0) && ((EX_MEM_rd == IF_ID_Instr[19:15]) || (if_id_is_branch && (EX_MEM_rd == IF_ID_Instr[24:20])));
    
    assign id_stall_hazard = load_use_hazard | id_branch_load_hazard;

    reg_file registers(.clk(clk), .rst(rst), .wr_en(c0 & MEM_WB_ctrl[0]), .readAddr1(IF_ID_Instr[19:15]), .readAddr2(IF_ID_Instr[24:20]), .writeAddr(MEM_WB_rd), .writeData(writeData), .readData1(readData_1), .readData2(readData_2));

    rv32_ImmGen immediateGenerator(.IR(IF_ID_Instr), .Imm(immOut));

    assign ex_mem_forward_valid = EX_MEM_ctrl[3] && (EX_MEM_rd != 5'd0) && ~EX_MEM_ctrl[2];
    assign mem_wb_forward_valid = MEM_WB_ctrl[0] && (MEM_WB_rd != 5'd0);

    assign ex_mem_forward_value = (EX_MEM_writeSel == 2'b00) ? EX_MEM_PCadd4 : (EX_MEM_writeSel == 2'b01) ? EX_MEM_branchAdd : (EX_MEM_writeSel == 2'b11) ? EX_MEM_immediate : EX_MEM_ALUOut;

    assign id_rs1_value = (ex_mem_forward_valid && (EX_MEM_rd == IF_ID_Instr[19:15])) ? ex_mem_forward_value : (mem_wb_forward_valid && (MEM_WB_rd == IF_ID_Instr[19:15])) ? writeData : readData_1;

    assign id_rs2_value = (ex_mem_forward_valid && (EX_MEM_rd == IF_ID_Instr[24:20])) ? ex_mem_forward_value : (mem_wb_forward_valid && (MEM_WB_rd == IF_ID_Instr[24:20])) ? writeData : readData_2;

    assign id_branch_target = IF_ID_PC + immOut;
    assign id_jalr_sum      = id_rs1_value + immOut;
    assign id_jalr_target   = {id_jalr_sum[31:1], 1'b0};

    nbit2x1mux #(.n(8)) ctrlFlushMux(.A({MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp, ALUSrc}), .B(8'b0), .sel(id_stall_hazard), .D(ctrlFlushMuxOut));

    nbit_reg #(.n(226)) ID_EX (.clk(clk), .load(c1), .rst(rst),
        .D({IF_ID_Instr[6:2], PCSel, writeData_Sel, IF_ID_PCadd4, ctrlFlushMuxOut, IF_ID_PC, readData_1, readData_2, immOut, IF_ID_Instr[30], IF_ID_Instr[14:12], IF_ID_Instr[19:15], IF_ID_Instr[24:20], IF_ID_Instr[11:7]}),
        .Q({ID_EX_opcode, ID_EX_PCsel, ID_EX_writeSel, ID_EX_PCadd4, ID_EX_ctrl, ID_EX_PC, ID_EX_readData_1, ID_EX_readData_2, ID_EX_immediate, ID_EX_func, ID_EX_rs1, ID_EX_rs2, ID_EX_rd}));

    nbit_4x1mux #(.n(32)) ALUmuxA(.A(ID_EX_readData_1), .B(writeData), .C(EX_MEM_ALUOut), .D(32'b0), .sel(forwardA), .out(forwardMuxA_out));

    nbit_4x1mux #(.n(32)) ALUmuxB(.A(ID_EX_readData_2), .B(writeData), .C(EX_MEM_ALUOut), .D(32'b0), .sel(forwardB), .out(forwardMuxB_out));

    RCA branchAdder(.A(ID_EX_PC), .B(ID_EX_immediate), .sum(branchAdder_out));

    nbit2x1mux #(.n(32)) aluin(.A(forwardMuxB_out), .B(ID_EX_immediate), .sel(ID_EX_ctrl[0]), .D(ALUmux_out));

    ALUControlUnit ALUCU(.instruction({1'b0, ID_EX_func[3], 15'b0, ID_EX_func[2:0], 12'b0}), .ALUOp(ID_EX_ctrl[2:1]), .ALUSel(ALUSel));

    ALU alu(.A(forwardMuxA_out), .B(ALUmux_out), .sel(ALUSel), .aluOut(ALUres), .Z(Z), .C(C), .V(V), .S(S));

    assign flush_EX_MEM = ID_EX_ctrl[7:3];
    
    always @(*) begin
        branchRes = 1'b0;
        if (!id_stall_hazard) begin
            if (if_id_is_jal || if_id_is_jalr) begin
                branchRes = 1'b1;
            end else if (if_id_is_branch && Branch) begin
                case (IF_ID_Instr[14:12])
                    `BR_BEQ:  branchRes = (id_rs1_value == id_rs2_value);
                    `BR_BNE:  branchRes = (id_rs1_value != id_rs2_value);
                    `BR_BLT:  branchRes = ($signed(id_rs1_value) <  $signed(id_rs2_value));
                    `BR_BGE:  branchRes = ($signed(id_rs1_value) >= $signed(id_rs2_value));
                    `BR_BLTU: branchRes = (id_rs1_value <  id_rs2_value);
                    `BR_BGEU: branchRes = (id_rs1_value >= id_rs2_value);
                    default:  branchRes = 1'b0;
                endcase
            end
        end
    end

    always @(*) begin
        if (branchRes && if_id_is_jalr)
            PC_in = id_jalr_target;
        else if (branchRes && (if_id_is_branch || if_id_is_jal))
            PC_in = id_branch_target;
        else
            PC_in = PC_inc;
    end

    nbit_reg #(.n(184)) EX_MEM(.clk(clk), .load(c0), .rst(rst),
        .D({ID_EX_writeSel, ID_EX_opcode, ID_EX_func[2:0], V, C, S, ID_EX_immediate, ID_EX_PCadd4, flush_EX_MEM, branchAdder_out, Z, ALUres, forwardMuxB_out, ID_EX_rd}),
        .Q({EX_MEM_writeSel, EX_MEM_opcode, EX_MEM_funct3, EX_MEM_V, EX_MEM_C, EX_MEM_S, EX_MEM_immediate, EX_MEM_PCadd4, EX_MEM_ctrl, EX_MEM_branchAdd, EX_MEM_Z, EX_MEM_ALUOut, EX_MEM_readData_2, EX_MEM_rd}));

    wire mem_en_single;
    wire mem_write_single;
    wire [2:0] mem_funct3_single;
    wire [11:0] mem_addr_single;
    wire [31:0] mem_wdata_single;

    assign mem_en_single     = c0 ? (~stop_fetch & ~stall_fetch_next) : (EX_MEM_ctrl[2] | EX_MEM_ctrl[1]);
    assign mem_write_single  = c1 & EX_MEM_ctrl[1];
    assign mem_funct3_single = c0 ? 3'b010 : EX_MEM_funct3;
    assign mem_addr_single   = c0 ? PC_Out[11:0] : EX_MEM_ALUOut[11:0];
    assign mem_wdata_single  = EX_MEM_readData_2;

    unified_memory mem(.clk(clk), .mem_en(mem_en_single), .mem_write(mem_write_single), .funct3(mem_funct3_single), .addr(mem_addr_single), .wdata(mem_wdata_single), .rdata(memOut));

    nbit_reg #(.n(169)) MEM_WB ( .clk(clk), .load(c1), .rst(rst),
        .D({EX_MEM_writeSel, EX_MEM_immediate, EX_MEM_branchAdd, EX_MEM_PCadd4, EX_MEM_ctrl[4:3], memOut, EX_MEM_ALUOut, EX_MEM_rd}),
        .Q({MEM_WB_writeSel, MEM_WB_immediate, MEM_WB_branchAdd, MEM_WB_PCadd4, MEM_WB_ctrl, MEM_WB_memOut, MEM_WB_ALUOut, MEM_WB_rd}));

    nbit2x1mux #(.n(32)) writebackmux(.A(MEM_WB_ALUOut), .B(MEM_WB_memOut), .sel(MEM_WB_ctrl[1]), .D(writeBackMuxOut));

    nbit_4x1mux #(.n(32)) writeDataMUX(.A(MEM_WB_PCadd4), .B(MEM_WB_branchAdd), .C(writeBackMuxOut), .D(MEM_WB_immediate), .sel(MEM_WB_writeSel), .out(writeData));

    ForwardingUnit FU( .ID_EX_RegisterRs1(ID_EX_rs1), .ID_EX_RegisterRs2(ID_EX_rs2), .EX_MEM_RegisterRd(EX_MEM_rd), .MEM_WB_RegisterRd(MEM_WB_rd), .EX_MEM_RegWrite(EX_MEM_ctrl[3]), .MEM_WB_RegWrite(MEM_WB_ctrl[0]), .forwardA(forwardA), .forwardB(forwardB));
endmodule

