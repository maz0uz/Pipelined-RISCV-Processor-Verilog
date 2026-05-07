RV32I Directed Assembly and Unified Memory Test Package

Each numbered .s file is the human-readable assembly test.
Each numbered *_unified_mem.v file is the matching byte-addressable unified memory preloaded with that test program.

How to use:
1. Pick a test number, for example 08.
2. Read 08_*.s to see the expected behavior.
3. Copy 08_unified_mem.v into your Vivado project as unified_mem.v, or replace the current unified memory file with it.
4. Run simulation or synthesize/program FPGA with the same CPU top.
5. Check the expected registers/memory/PC behavior listed in the comments and in test_index.txt.

Note:
- These memory files define module unified_memory, matching the interface used by the current riscv.v.
- All programs end with a halt instruction except the tests that specifically validate a halt instruction.
- Data regions are placed away from the instruction region, typically at 0x300.
