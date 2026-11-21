`timescale 1ns/10ps
// ============================================================================
// instructmem.sv  --  Phase 0 instruction ROM (SIMULATION ONLY)
//
// 32 entries x 16 bits, indexed directly by the 5-bit PC (no x4, no byte addr).
// Combinational read. Contents are loaded from MEM_FILE with $readmemb.
//
// NOTE: `initial` + $readmemb is NOT synthesizable for the ASIC. In the host-
// interface phase this becomes a writable register file with a write port
// (clk, we, waddr, wdata) driven by the RP2350 through the SPI host interface.
//
// Locations not listed in MEM_FILE stay X in simulation on purpose, so that
// running off the end of a program shows up immediately as X on the pins.
// ============================================================================
module instructmem #(
    parameter int DEPTH    = 32,
    parameter int AW       = 5,
    parameter int IW       = 16,
    parameter     MEM_FILE = "program.mem"
) (
    input  logic [AW-1:0] addr,
    output logic [IW-1:0] instr
);
    logic [IW-1:0] mem [DEPTH];

    initial begin
        $readmemb(MEM_FILE, mem);
        $display("instructmem: loaded %s", MEM_FILE);
    end

    assign instr = mem[addr];
endmodule
