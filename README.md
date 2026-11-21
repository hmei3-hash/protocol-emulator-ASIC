# protocol-emulator-ASIC

A reprogrammable protocol emulator chip for Jane Street's [protocol emulator ASIC competition](https://blog.janestreet.com/), targeting IHP 130nm via Tiny Tapeout.

Small, cycle-exact I/O engines (PIO-style) run tiny programs to bit-bang protocols like UART, SPI and I2C, so new protocols need new software, not new silicon.

**Status:** Phase 0 — single engine with `SET`, `JMP` (incl. `X--` loops) and per-instruction delay; sends UART bytes in simulation.

## Files
- `engine.sv` — top level (PC, X, delay, pin register)
- `control.sv` — instruction decoder
- `delay_counter.sv` — per-instruction delay
- `instructmem.sv` — 32 x 16-bit program ROM (sim only)
- `program.mem` — test program: UART 0x55
