# femtoRV32 — Pipelined RV32I RISC-V Processor

Milestone 3 final implementation for **CSCE 3301: Computer Architecture**.

This project implements a pipelined RV32I RISC-V processor in Verilog. The CPU supports the required RV32I base integer instruction set, uses a unified single-ported instruction/data memory, and includes hazard handling, forwarding, branch flushing, and Nexys A7 debug outputs.

> Team: Mohamed Azouz, Amonios Beshara

---

## Project Overview

`femtoRV32` is a three-stage pipelined RV32I processor. The design uses a single unified byte-addressable memory for both instruction fetches and data loads/stores.

Because the memory is single-ported, the processor uses an every-other-cycle issue schedule with two internal phases, `C0` and `C1`, to avoid instruction/data memory structural hazards.

The processor intentionally treats the following instructions as program-halting instructions, according to the project requirements:

- `ECALL`
- `EBREAK`
- `FENCE`
- `FENCE.TSO`
- `PAUSE`

---

## Pipeline Design

The CPU uses a three-stage pipeline with `C0/C1` phase timing.

| Stage   | C0 Phase                           | C1 Phase               |
| ------- | ---------------------------------- | ---------------------- |
| Stage 0 | Instruction Fetch                  | Decode / Register Read |
| Stage 1 | Execute / ALU / Address Generation | Memory Read / Write    |
| Stage 2 | Register Writeback                 | Unused                 |

### Pipeline Registers

The processor includes the following pipeline registers:

- `IF/ID`
- `ID/EX`
- `EX/MEM`
- `MEM/WB`

---

## Implemented Features

- RV32I base integer instruction support
- Three-stage pipelined datapath
- Single-ported unified instruction/data memory
- Byte-addressable load/store behavior
- Every-other-cycle instruction issuing
- EX-stage forwarding for ALU operands
- Store-data forwarding
- Load-use hazard detection and stalling
- Branch and jump flushing
- Halt handling for `ECALL`, `EBREAK`, `FENCE`, `FENCE.TSO`, and `PAUSE`
- Nexys A7 debug outputs using LEDs and seven-segment display

---

## Bonus Features

### Bonus 1: ID-Stage Branch Resolution

Branch and jump target logic was moved from the EX stage to the ID stage to reduce branch penalty.

This includes:

- ID-stage `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, and `BGEU` comparison
- ID-stage branch target calculation
- ID-stage `JAL` target calculation
- ID-stage `JALR` target calculation with bit 0 cleared
- ID-stage forwarding into the branch comparator
- Extra stalling for branch-load hazards

### Bonus 2: Random Test Program Generator

A C++ random test generator is included to create additional stress tests for the processor.

The generator produces:

- `program.hex`
- `data.hex`
- `trace.txt`

It can generate valid RV32I instruction sequences, including:

- Arithmetic instructions
- Logic instructions
- Shift instructions
- Load and store instructions
- Branch instructions
- Upper-immediate instructions
- Halt/fence-related instructions

---

## Main Verilog Modules

| File            | Description                                                                                                                                                                            |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `riscv.v`       | Top-level CPU module containing the pipelined datapath, phase controller, hazard detection, branch handling, unified memory interface, forwarding connections, and board debug outputs |
| `unified_mem.v` | Single-port byte-addressable unified memory for instruction fetches and data load/store operations                                                                                     |
| `ControlUnit.v` | RV32I opcode decoder that generates control signals and detects halt instructions                                                                                                      |
| `ALUControl.v`  | Decodes `ALUOp`, `funct3`, and `funct7` bits into ALU operation selects                                                                                                                |
| `ALU.v`         | Performs arithmetic, logic, shift, and comparison operations                                                                                                                           |
| `ImmGen.v`      | Generates I-type, S-type, B-type, U-type, and J-type immediates                                                                                                                        |
| `reg_file.v`    | 32-register RV32I register file                                                                                                                                                        |
| `ForwardUnit.v` | Forwarding select logic for EX-stage ALU inputs                                                                                                                                        |
| `n-bit_reg.v`   | Parameterized register used for the PC and pipeline registers                                                                                                                          |
| `mux2x1.v`      | 2-to-1 multiplexer                                                                                                                                                                     |
| `nbit2x1mux.v`  | Parameterized n-bit 2-to-1 multiplexer                                                                                                                                                 |
| `nbit_4x1mux.v` | Parameterized n-bit 4-to-1 multiplexer                                                                                                                                                 |
| `RCA.v`         | Ripple-carry adder                                                                                                                                                                     |
| `FA.v`          | Full-adder module                                                                                                                                                                      |

---

## Repository Structure

```text
Project1_MS3/
├── Verilog/
│   ├── riscv.v
│   ├── unified_mem.v
│   ├── ControlUnit.v
│   ├── ALUControl.v
│   ├── ALU.v
│   ├── ImmGen.v
│   ├── reg_file.v
│   ├── ForwardUnit.v
│   ├── n-bit_reg.v
│   ├── mux2x1.v
│   ├── nbit2x1mux.v
│   ├── nbit_4x1mux.v
│   ├── nbit_shiftleft1.v
│   ├── RCA.v
│   ├── FA.v
│   ├── FlipFlop.v
│   └── defines.v
│
├── test/
│   ├── program.hex
│   └── data.hex
│
├── Test Generator/
│   └── testGen.cpp
│
├── report/
│   └── MS3_Final_Report.pdf
│
├── journal/
│   ├── Mohamed_Azouz_journal.txt
│   └── Amonios_Beshara_journal.txt
│
└── README.md
```

---

## Running the Random Test Generator

The random test generator is written in C++.

From the `Test Generator/` directory, compile it with:

```bash
g++ testGen.cpp -o testGen
```

Run it with the default instruction count:

```bash
./testGen
```

Run it with a custom instruction count:

```bash
./testGen 100
```

The generator outputs:

| File          | Description                                 |
| ------------- | ------------------------------------------- |
| `program.hex` | Byte-wise instruction memory initialization |
| `data.hex`    | Byte-wise data memory initialization        |
| `trace.txt`   | Human-readable instruction trace            |

---

## Known Passing Tests

The following tests were observed passing during simulation.

### JAL / JALR Test

Expected observed values:

```text
x1 = 0x00000004
x2 = 0x00000018
x3 = 0x0000001c
x5 = 0x00000000
x6 = 0x00000000
```

This confirms:

- `JAL` link writeback
- `JALR` target masking
- Correct jump target behavior

### Hazard Test

Expected observed values:

```text
x1        = 0x0000000a
x2        = 0x00000014
x3        = 0x0000001e
mem[0xa0] = 0x00000055
x5        = 0x00000055
x6        = 0x000000aa
x8        = 0x00000000
x9        = 0x0000007b
```

This confirms:

- ALU-to-ALU forwarding
- Store-data forwarding
- Load-use stalling
- Branch-related hazard handling

---

## Design Assumptions

- Instruction memory and data memory share the same unified memory array.
- Program and data regions must not overlap.
- Directed tests are used for guaranteed instruction coverage.
- The random test generator is used for additional stress testing, not as the only verification method.
- Halt instructions stop PC updates and end program execution.
- The `C0/C1` phase schedule avoids structural conflicts caused by the single-ported unified memory.
