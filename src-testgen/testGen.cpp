#include <iostream>
#include <vector>
#include <fstream>
#include <map>
#include <string>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <iomanip>
#include <algorithm>
#include <sstream>

using namespace std;

constexpr uint32_t DATA_BASE = 2048; // 2048
constexpr uint32_t DATA_WORDS = 512; // 2048 bytes of data

vector<string> R_TYPE = {
    "add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and"};

vector<string> I_ALU = {
    "addi", "slti", "sltiu", "xori", "ori", "andi"};

vector<string> I_SHIFT = {
    "slli", "srli", "srai"};

vector<string> U_TYPE = {
    "lui", "auipc"};

vector<string> B_TYPE = {
    "beq", "bne", "blt", "bge", "bltu", "bgeu"};

vector<string> I_LOAD = {
    "lb", "lh", "lw", "lbu", "lhu"};

vector<string> S_TYPE = {
    "sb", "sh", "sw"};

vector<string> J_TYPE = {
    "jal"};

vector<string> SYSTEM_TYPE = {
    "ecall", "ebreak"};

vector<string> FENCE_TYPE = {
    "fence", "fence.tso", "pause"};

map<string, uint8_t> opcodeMap = {
    // Loads
    {"lb", 0b0000011},
    {"lh", 0b0000011},
    {"lw", 0b0000011},
    {"lbu", 0b0000011},
    {"lhu", 0b0000011},
    // I-type ALU
    {"addi", 0b0010011},
    {"slli", 0b0010011},
    {"slti", 0b0010011},
    {"sltiu", 0b0010011},
    {"xori", 0b0010011},
    {"srli", 0b0010011},
    {"srai", 0b0010011},
    {"ori", 0b0010011},
    {"andi", 0b0010011},
    // Stores
    {"sb", 0b0100011},
    {"sh", 0b0100011},
    {"sw", 0b0100011},
    // R-type
    {"add", 0b0110011},
    {"sub", 0b0110011},
    {"sll", 0b0110011},
    {"slt", 0b0110011},
    {"sltu", 0b0110011},
    {"xor", 0b0110011},
    {"srl", 0b0110011},
    {"sra", 0b0110011},
    {"or", 0b0110011},
    {"and", 0b0110011},
    // Branches
    {"beq", 0b1100011},
    {"bne", 0b1100011},
    {"blt", 0b1100011},
    {"bge", 0b1100011},
    {"bltu", 0b1100011},
    {"bgeu", 0b1100011},
    // Jumps
    {"jalr", 0b1100111},
    {"jal", 0b1101111},
    // U-type
    {"lui", 0b0110111},
    {"auipc", 0b0010111},
    // System
    {"ecall", 0b1110011},
    {"ebreak", 0b1110011},
    // FENCE
    {"fence", 0b0001111},
    {"fence.tso", 0b0001111},
    {"pause", 0b0001111}};

map<string, uint8_t> funct3Map = {
    // R-type
    {"add", 0b000},
    {"sub", 0b000},
    {"sll", 0b001},
    {"slt", 0b010},
    {"sltu", 0b011},
    {"xor", 0b100},
    {"srl", 0b101},
    {"sra", 0b101},
    {"or", 0b110},
    {"and", 0b111},
    // I-type ALU
    {"addi", 0b000},
    {"slli", 0b001},
    {"slti", 0b010},
    {"sltiu", 0b011},
    {"xori", 0b100},
    {"srli", 0b101},
    {"srai", 0b101},
    {"ori", 0b110},
    {"andi", 0b111},
    // Loads
    {"lb", 0b000},
    {"lh", 0b001},
    {"lw", 0b010},
    {"lbu", 0b100},
    {"lhu", 0b101},
    // Stores
    {"sb", 0b000},
    {"sh", 0b001},
    {"sw", 0b010},
    // Branches
    {"beq", 0b000},
    {"bne", 0b001},
    {"blt", 0b100},
    {"bge", 0b101},
    {"bltu", 0b110},
    {"bgeu", 0b111},
    // JALR and system
    {"jalr", 0b000},
    {"ecall", 0b000},
    {"ebreak", 0b000},
    // FENCE
    {"fence", 0b000},
    {"fence.tso", 0b000},
    {"pause", 0b000}};

map<string, uint8_t> funct7Map = {
    {"add", 0b0000000},
    {"sub", 0b0100000},
    {"sll", 0b0000000},
    {"slt", 0b0000000},
    {"sltu", 0b0000000},
    {"xor", 0b0000000},
    {"srl", 0b0000000},
    {"sra", 0b0100000},
    {"or", 0b0000000},
    {"and", 0b0000000},
    {"slli", 0b0000000},
    {"srli", 0b0000000},
    {"srai", 0b0100000}};

struct RegState
{
    bool known;
    uint32_t value;
};

uint32_t rand32()
{
    return (static_cast<uint32_t>(rand()) << 16) ^
           static_cast<uint32_t>(rand());
}

int32_t signExtend12(uint32_t imm)
{
    imm &= 0xFFF;

    if (imm & 0x800)
        return static_cast<int32_t>(imm | 0xFFFFF000);

    return static_cast<int32_t>(imm);
}

uint8_t randomWritableRegister()
{
    return static_cast<uint8_t>(1 + rand() % 31); // x1 to x31
}

uint8_t randomKnownRegister(const array<RegState, 32> &regs)
{
    vector<uint8_t> known;

    for (uint8_t i = 0; i < 32; i++)
    {
        if (regs[i].known)
        {
            known.push_back(i);
        }
    }

    if (known.empty())
    {
        return 0;
    }

    return known[rand() % known.size()];
}

void setRegister(array<RegState, 32> &regs, uint8_t rd, uint32_t value)
{
    if (rd == 0)
    {
        regs[0] = {true, 0};
        return;
    }

    regs[rd] = {true, value};
}

uint32_t executeR(const string &instr, uint32_t rs1, uint32_t rs2)
{
    uint32_t shift_amt = rs2 & 0x1F;
    if (instr == "add")
        return rs1 + rs2;
    else if (instr == "sub")
        return rs1 - rs2;
    else if (instr == "sll")
        return rs1 << shift_amt;
    else if (instr == "slt")
        return static_cast<int32_t>(rs1) < static_cast<int32_t>(rs2) ? 1 : 0;
    else if (instr == "sltu")
        return rs1 < rs2 ? 1 : 0;
    else if (instr == "xor")
        return rs1 ^ rs2;
    else if (instr == "srl")
        return rs1 >> shift_amt;
    else if (instr == "sra")
        return static_cast<uint32_t>(static_cast<int32_t>(rs1) >> shift_amt);
    else if (instr == "or")
        return rs1 | rs2;
    else if (instr == "and")
        return rs1 & rs2;
    return 0;
}
uint32_t executeI(const string &instr, uint32_t rs1, int32_t imm)
{
    if (instr == "addi")
        return rs1 + static_cast<uint32_t>(imm);

    else if (instr == "slti")
        return static_cast<int32_t>(rs1) < imm ? 1 : 0;

    else if (instr == "sltiu")
        return rs1 < static_cast<uint32_t>(imm) ? 1 : 0;

    else if (instr == "xori")
        return rs1 ^ static_cast<uint32_t>(imm);

    else if (instr == "ori")
        return rs1 | static_cast<uint32_t>(imm);

    else if (instr == "andi")
        return rs1 & static_cast<uint32_t>(imm);

    else if (instr == "slli")
    {
        uint32_t shift_amt = imm & 0x1F;
        return rs1 << shift_amt;
    }
    else if (instr == "srli")
    {
        uint32_t shift_amt = imm & 0x1F;
        return rs1 >> shift_amt;
    }
    else if (instr == "srai")
    {
        uint32_t shift_amt = imm & 0x1F;
        return static_cast<uint32_t>(static_cast<int32_t>(rs1) >> shift_amt);
    }
    return 0;
}
uint32_t executeU(const string &instr, uint32_t imm20, uint32_t pc)
{
    uint32_t imm = imm20 << 12;

    if (instr == "lui")
        return imm;

    else if (instr == "auipc")
        return pc + imm;

    return 0;
}

uint32_t encodeR(uint8_t funct7, uint8_t rs2, uint8_t rs1, uint8_t funct3, uint8_t rd, uint8_t opcode)
{
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x07) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F);
}
uint32_t encodeI(int32_t imm, uint8_t rs1, uint8_t funct3, uint8_t rd, uint8_t opcode)
{
    uint32_t uimm = static_cast<uint32_t>(imm) & 0xFFF;
    return (uimm << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x07) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F);
}
uint32_t encodeShiftI(const string &instr, uint8_t shamt, uint8_t rs1, uint8_t rd)
{
    uint32_t imm = ((funct7Map.at(instr) & 0x7F) << 5) | (shamt & 0x1F);
    return encodeI(static_cast<int32_t>(imm), rs1, funct3Map.at(instr), rd, opcodeMap.at(instr));
}
uint32_t encodeS(int32_t imm, uint8_t rs2, uint8_t rs1, uint8_t funct3, uint8_t opcode)
{
    uint32_t uimm = static_cast<uint32_t>(imm) & 0xFFF;
    uint32_t imm11_5 = (uimm >> 5) & 0x7F;
    uint32_t imm4_0 = uimm & 0x1F;
    return (imm11_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x07) << 12) | (imm4_0 << 7) | (opcode & 0x7F);
}
uint32_t encodeB(int32_t imm, uint8_t rs2, uint8_t rs1, uint8_t funct3, uint8_t opcode)
{
    uint32_t uimm = static_cast<uint32_t>(imm);
    uint32_t imm12 = (uimm >> 12) & 0x1;
    uint32_t imm10_5 = (uimm >> 5) & 0x3F;
    uint32_t imm4_1 = (uimm >> 1) & 0xF;
    uint32_t imm11 = (uimm >> 11) & 0x1;
    return (imm12 << 31) | (imm10_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x07) << 12) | (imm4_1 << 8) | (imm11 << 7) | (opcode & 0x7F);
}
uint32_t encodeJ(int32_t imm, uint8_t rd, uint8_t opcode)
{
    uint32_t uimm = static_cast<uint32_t>(imm);

    uint32_t imm20 = (uimm >> 20) & 0x1;
    uint32_t imm10_1 = (uimm >> 1) & 0x3FF;
    uint32_t imm11 = (uimm >> 11) & 0x1;
    uint32_t imm19_12 = (uimm >> 12) & 0xFF;
    return (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | (imm19_12 << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F);
}
uint32_t encodeU(uint32_t imm20, uint8_t rd, uint8_t opcode)
{
    return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F);
}
uint32_t encodeSystem(uint32_t imm12)
{
    return ((imm12 & 0xFFF) << 20) | (0 << 15) | (0b000 << 12) | (0 << 7) | 0b1110011;
}

uint32_t encodeFence(uint8_t fm, uint8_t pred, uint8_t succ)
{
    uint32_t imm = ((fm & 0xF) << 8) | ((pred & 0xF) << 4) | (succ & 0xF);
    return (imm << 20) | (0 << 15) | (0b000 << 12) | (0 << 7) | 0b0001111;
}

uint32_t encodeFenceByName(const string &instr)
{
    if (instr == "fence")
    {
        return encodeFence(0b0000, 0b1111, 0b1111);
    }
    if (instr == "fence.tso")
    {
        return encodeFence(0b1000, 0b0011, 0b0011);
    }
    if (instr == "pause")
    {
        return encodeFence(0b0000, 0b0001, 0b0000);
    }
    return 0;
}

void writeProgramHex(const string &filename, const vector<uint32_t> &program)
{
    ofstream out(filename);
    if (!out)
    {
        cerr << "Could not open " << filename << " for writing.\n";
        return;
    }
    for (uint32_t word : program)
    {
        out << hex << setw(2) << setfill('0') << ((word >> 0) & 0xFF) << "\n";
        out << hex << setw(2) << setfill('0') << ((word >> 8) & 0xFF) << "\n";
        out << hex << setw(2) << setfill('0') << ((word >> 16) & 0xFF) << "\n";
        out << hex << setw(2) << setfill('0') << ((word >> 24) & 0xFF) << "\n";
    }
}
void writeDataHex(const string &filename, const map<uint32_t, uint32_t> &data)
{
    ofstream out(filename);
    if (!out)
    {
        cerr << "Could not open " << filename << " for writing.\n";
        return;
    }

    for (uint32_t i = 0; i < DATA_WORDS; i++)
    {
        uint32_t addr = DATA_BASE + i * 4;
        uint32_t value = 0;
        auto it = data.find(addr);
        if (it != data.end())
        {
            value = it->second;
        }
        out << hex << setw(2) << setfill('0') << ((value >> 0) & 0xFF) << "\n";
        out << hex << setw(2) << setfill('0') << ((value >> 8) & 0xFF) << "\n";
        out << hex << setw(2) << setfill('0') << ((value >> 16) & 0xFF) << "\n";
        out << hex << setw(2) << setfill('0') << ((value >> 24) & 0xFF) << "\n";
    }
}

uint32_t wordAddress(uint32_t addr)
{
    return addr & ~0x3u;
}
uint8_t byteOffset(uint32_t addr)
{
    return addr & 0x3u;
}
uint32_t signExtend8(uint32_t value)
{
    value &= 0xFF;
    if (value & 0x80)
        return value | 0xFFFFFF00;
    return value;
}
uint32_t signExtend16(uint32_t value)
{
    value &= 0xFFFF;
    if (value & 0x8000)
        return value | 0xFFFF0000;
    return value;
}
uint32_t loadMemory(const map<uint32_t, uint32_t> &data, uint32_t addr, const string &instr)
{
    uint32_t base = wordAddress(addr);
    uint32_t off = byteOffset(addr);

    auto it = data.find(base);
    uint32_t word = 0;

    if (it != data.end())
        word = it->second;
    if (instr == "lb")
    {
        uint32_t byteVal = (word >> (8 * off)) & 0xFF;
        return signExtend8(byteVal);
    }
    if (instr == "lbu")
    {
        return (word >> (8 * off)) & 0xFF;
    }
    if (instr == "lh")
    {
        uint32_t halfVal = (word >> (8 * off)) & 0xFFFF;
        return signExtend16(halfVal);
    }
    if (instr == "lhu")
    {
        return (word >> (8 * off)) & 0xFFFF;
    }
    if (instr == "lw")
    {
        return word;
    }
    return 0;
}
void storeMemory(map<uint32_t, uint32_t> &data, uint32_t addr, uint32_t value, const string &instr)
{
    uint32_t base = wordAddress(addr);
    uint32_t off = byteOffset(addr);

    uint32_t &word = data[base];

    if (instr == "sb")
    {
        uint32_t shift = 8 * off;
        word &= ~(0xFFu << shift);
        word |= ((value & 0xFFu) << shift);
    }
    else if (instr == "sh")
    {
        uint32_t shift = 8 * off;
        word &= ~(0xFFFFu << shift);
        word |= ((value & 0xFFFFu) << shift);
    }
    else if (instr == "sw")
    {
        word = value;
    }
}

void writeTrace(const string &filename, const vector<string> &trace)
{
    ofstream out(filename);
    if (!out)
    {
        cerr << "Could not open " << filename << " for writing.\n";
        return;
    }
    for (const string &line : trace)
    {
        out << line << "\n";
    }
}

string hex32(uint32_t value)
{
    stringstream ss;
    ss << "0x" << hex << setw(8) << setfill('0') << value;
    return ss.str();
}

void generateProgram(int length, vector<uint32_t> &program, map<uint32_t, uint32_t> &data, vector<string> &trace)
{
    array<RegState, 32> regs;
    for (int i = 0; i < 32; i++)
    {
        regs[i] = {false, 0};
    }
    regs[0] = {true, 0};
    program.clear();
    data.clear();
    trace.clear();
    program.reserve(length + 16);

    // Fill data memory with random values
    for (uint32_t i = 0; i < DATA_WORDS; i++)
    {
        uint32_t addr = DATA_BASE + i * 4;
        data[addr] = rand32();
    }
    writeDataHex("data.hex", data);

    { // Makes x10 the base of the data memory
        uint32_t pc = program.size() * 4;
        uint32_t imm20 = DATA_BASE >> 12;
        uint32_t instrWord = encodeU(imm20, 10, opcodeMap.at("lui"));

        program.push_back(instrWord);
        setRegister(regs, 10, DATA_BASE);
        trace.push_back(hex32(pc) + ": " + hex32(instrWord) +
                        "    lui x10, 0x" + to_string(imm20));
    }

    for (int i = 0; i < 5; i++)
    { // Initialize some registers with random values using addi
        uint32_t pc = program.size() * 4;

        uint8_t rd = randomWritableRegister();
        int32_t imm = signExtend12(rand() & 0xFFF);
        uint32_t instrWord = encodeI(imm, 0, funct3Map.at("addi"), rd, opcodeMap.at("addi"));
        program.push_back(instrWord);
        setRegister(regs, rd, static_cast<uint32_t>(imm));
        trace.push_back(hex32(pc) + ": " + hex32(instrWord) + "    addi x" + to_string(rd) + ", x0, " + to_string(imm));
    }

    // Generate random instructions
    for (int i = 0; i < length; i++)
    {
        uint32_t pc = program.size() * 4;

        uint8_t rd = randomWritableRegister();
        uint8_t rs1 = randomKnownRegister(regs);
        uint8_t rs2 = randomKnownRegister(regs);

        string instr;
        int type = rand() % 6;
        switch (type)
        {
        case 0:
        {
            instr = R_TYPE[rand() % R_TYPE.size()];
            uint32_t instrWord = encodeR(funct7Map.at(instr), rs2, rs1, funct3Map.at(instr), rd, opcodeMap.at(instr));
            program.push_back(instrWord);
            uint32_t result = executeR(instr, regs[rs1].value, regs[rs2].value);
            setRegister(regs, rd, result);
            trace.push_back(hex32(pc) + ": " + hex32(instrWord) + "    " + instr + " x" + to_string(rd) + ", x" + to_string(rs1) + ", x" + to_string(rs2));
            break;
        }
        case 1:
        {
            instr = I_ALU[rand() % I_ALU.size()];
            int32_t imm = signExtend12(rand() & 0xFFF);
            uint32_t instrWord = encodeI(imm, rs1, funct3Map.at(instr), rd, opcodeMap.at(instr));
            program.push_back(instrWord);
            uint32_t result = executeI(instr, regs[rs1].value, imm);
            setRegister(regs, rd, result);
            trace.push_back(hex32(pc) + ": " + hex32(instrWord) + "    " + instr + " x" + to_string(rd) + ", x" + to_string(rs1) + ", " + to_string(imm));
            break;
        }
        case 2:
        {
            instr = I_SHIFT[rand() % I_SHIFT.size()];
            uint8_t shift_amt = rand() % 32;
            uint32_t instrWord = encodeShiftI(instr, shift_amt, rs1, rd);
            program.push_back(instrWord);
            uint32_t result = executeI(instr, regs[rs1].value, shift_amt);
            setRegister(regs, rd, result);
            trace.push_back(hex32(pc) + ": " + hex32(instrWord) + "    " + instr + " x" + to_string(rd) + ", x" + to_string(rs1) + ", " + to_string(shift_amt));
            break;
        }
        case 3:
        {
            instr = U_TYPE[rand() % U_TYPE.size()];
            uint32_t imm20 = rand32() & 0xFFFFF;
            uint32_t instrWord = encodeU(imm20, rd, opcodeMap.at(instr));
            program.push_back(instrWord);
            uint32_t result = executeU(instr, imm20, pc);
            setRegister(regs, rd, result);
            trace.push_back(hex32(pc) + ": " + hex32(instrWord) + "    " + instr + " x" + to_string(rd) + ", 0x" + to_string(imm20));
            break;
        }
        case 4:
        {
            bool doLoad = rand() % 2;
            if (doLoad)
            {
                instr = I_LOAD[rand() % I_LOAD.size()];
                uint32_t offset;
                if (instr == "lw")
                    offset = (rand() % DATA_WORDS) * 4;
                else if (instr == "lh" || instr == "lhu")
                    offset = (rand() % (DATA_WORDS * 2)) * 2;
                else
                    offset = rand() % (DATA_WORDS * 4);
                uint32_t addr = DATA_BASE + offset;
                uint32_t instrWord = encodeI(static_cast<int32_t>(offset), 10, funct3Map.at(instr), rd, opcodeMap.at(instr));

                program.push_back(instrWord);

                uint32_t loadedValue = loadMemory(data, addr, instr);
                setRegister(regs, rd, loadedValue);

                trace.push_back(hex32(pc) + ": " + hex32(instrWord) + "    " + instr + " x" + to_string(rd) + ", " + to_string(offset) + "(x10)");
            }
            else
            {
                instr = S_TYPE[rand() % S_TYPE.size()];

                uint32_t offset;

                if (instr == "sw")
                    offset = (rand() % DATA_WORDS) * 4;
                else if (instr == "sh")
                    offset = (rand() % (DATA_WORDS * 2)) * 2;
                else
                    offset = rand() % (DATA_WORDS * 4);

                uint32_t addr = DATA_BASE + offset;

                uint32_t instrWord = encodeS(
                    static_cast<int32_t>(offset),
                    rs2,
                    10,
                    funct3Map.at(instr),
                    opcodeMap.at(instr));

                program.push_back(instrWord);

                storeMemory(data, addr, regs[rs2].value, instr);

                trace.push_back(hex32(pc) + ": " + hex32(instrWord) +
                                "    " + instr +
                                " x" + to_string(rs2) +
                                ", " + to_string(offset) + "(x10)");
            }

            break;
        }
        case 5:
        {
            instr = B_TYPE[rand() % B_TYPE.size()];
            int32_t offset = 4; // Only use offset = 4 to ensure the branch target is valid

            uint32_t instrWord = encodeB(offset, rs2, rs1, funct3Map.at(instr), opcodeMap.at(instr));
            program.push_back(instrWord);
            trace.push_back(hex32(pc) + ": " + hex32(instrWord) + "    " + instr + " x" + to_string(rs1) + ", x" + to_string(rs2) + ", " + to_string(offset));
            break;
        }
        }
        regs[0] = {true, 0};
    }
    {
        uint32_t pc = program.size() * 4;
        uint32_t instrWord = encodeJ(0, 0, opcodeMap.at("jal"));
        program.push_back(instrWord);
        trace.push_back(hex32(pc) + ": " + hex32(instrWord) + "    jal x0, 0");
    }
}
int main(int argc, char *argv[])
{
    int length = 50;
    if (argc >= 2)
    {
        length = atoi(argv[1]);
    }
    srand(time(nullptr));
    vector<uint32_t> program;
    map<uint32_t, uint32_t> data;
    vector<string> trace;
    generateProgram(length, program, data, trace);
    writeProgramHex("program.hex", program);
    writeTrace("trace.txt", trace);
    cout << "Generated RV32I test program.\n";
    cout << "Instruction count requested: " << length << "\n";
    cout << "Actual instruction words: " << program.size() << "\n";
    cout << "Data words: " << DATA_WORDS << "\n";
    cout << "Wrote program.hex\n";
    cout << "Wrote data.hex\n";
    cout << "Wrote trace.txt\n";
    return 0;
}
