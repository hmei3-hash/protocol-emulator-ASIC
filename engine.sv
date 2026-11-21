`timescale 1ns/10ps
// ============================================================================
// engine.sv  --  Phase 0 protocol engine (single engine, ROM program)
//
// Ports match the Phase 0 architecture drawing:
//   inputs : clk, rst, run
//   output : pins_out[4:0]   (Q of the pin output register, "ODR")
//
// Timing model:
//   exec = run & dcnt_zero   -- "this cycle really executes the current instr"
//   On an exec cycle ALL effects of the instruction happen together at the
//   next clock edge: pins / X written, PC updated, delay counter loaded.
//   The following `delay` cycles are idle (exec = 0, PC held).
//   => every instruction takes exactly 1 + delay cycles.
//
// Registers (all synchronous reset, active-high rst):
//   PC        5 bit   reset 0
//   X         5 bit   reset 0
//   dcnt      5 bit   reset 0    (inside delay_counter)
//   pins_out  5 bit   reset PINS_RESET (bit 0 = UART TX idles high)
// ============================================================================
module engine #(
    parameter int             AW          = 5,
    parameter logic [AW-1:0]  WRAP_TOP    = 5'd31,      // phase 0: constant
    parameter logic [AW-1:0]  WRAP_BOTTOM = 5'd0,       // phase 0: constant
    parameter logic [4:0]     PINS_RESET  = 5'b00001,   // UART TX (bit 0) idle = 1
    parameter                 MEM_FILE    = "program.mem"
) (
    input  logic       clk,
    input  logic       rst,       // synchronous, active high (TT rst_n is inverted in the top wrapper)
    input  logic       run,       // start / stop the engine
    output logic [4:0] pins_out
);
    // ------------------------------------------------------------------
    // Fetch
    // ------------------------------------------------------------------
    logic [AW-1:0] pc;
    logic [15:0]   instr;

    instructmem #(.DEPTH(1 << AW), .AW(AW), .IW(16), .MEM_FILE(MEM_FILE)) u_imem (
        .addr  (pc),
        .instr (instr)
    );

    // Instruction fields
    logic [2:0] opcode;
    logic [4:0] delay;
    logic [2:0] sub;
    logic [4:0] imm;              // SET immediate / JMP target address

    assign opcode = instr[15:13];
    assign delay  = instr[12:8];
    assign sub    = instr[7:5];
    assign imm    = instr[4:0];

    // ------------------------------------------------------------------
    // Decode
    // ------------------------------------------------------------------
    logic pin_we, x_we, x_src, is_jmp;

    control u_ctrl (
        .opcode (opcode),
        .sub    (sub),
        .pin_we (pin_we),
        .x_we   (x_we),
        .x_src  (x_src),
        .is_jmp (is_jmp)
    );

    // ------------------------------------------------------------------
    // Delay counter, exec, stall
    // ------------------------------------------------------------------
    logic dcnt_zero, exec, stall;

    delay_counter #(.W(5)) u_dly (
        .clk       (clk),
        .rst       (rst),
        .load      (exec),
        .delay_in  (delay),
        .dcnt_zero (dcnt_zero)
    );

    assign exec  = run & dcnt_zero;
    assign stall = ~exec;

    // ------------------------------------------------------------------
    // X register
    //   D  = x_src ? X-1 : imm
    //   EN = x_we & exec
    // ------------------------------------------------------------------
    logic [4:0] x, x_next;
    logic       x_nz;

    assign x_next = x_src ? (x - 5'd1) : imm;
    assign x_nz   = |x;                          // 5-input OR: X != 0

    always_ff @(posedge clk) begin
        if (rst)
            x <= '0;
        else if (x_we & exec)
            x <= x_next;
    end

    // ------------------------------------------------------------------
    // Jump decision
    //   cond_ok mux: sel = instr[5] (= sub[0])
    //     0 -> 1      (always)
    //     1 -> X != 0 (X--)   uses X BEFORE the decrement
    // ------------------------------------------------------------------
    logic cond_ok, jump_taken;

    assign cond_ok    = sub[0] ? x_nz : 1'b1;
    assign jump_taken = is_jmp & cond_ok;

    // ------------------------------------------------------------------
    // Next PC: 4:1 mux, PC register always enabled
    //   sel = 00 : PC + 1
    //         01 : jump target (imm)
    //         10 : WRAP_BOTTOM
    //         11 : PC (hold, when stalled)
    //   sel1 = stall | (~jump_taken & at_top)
    //   sel0 = stall | jump_taken
    // ------------------------------------------------------------------
    logic          at_top;
    logic [1:0]    pc_sel;
    logic [AW-1:0] pc_plus1, next_pc;

    assign at_top   = (pc == WRAP_TOP);
    assign pc_plus1 = pc + 1'b1;
    assign pc_sel   = { stall | (~jump_taken & at_top),
                        stall |   jump_taken };

    always_comb begin
        case (pc_sel)
            2'b00:   next_pc = pc_plus1;
            2'b01:   next_pc = imm[AW-1:0];
            2'b10:   next_pc = WRAP_BOTTOM;
            default: next_pc = pc;               // 2'b11: hold
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst)
            pc <= '0;
        else
            pc <= next_pc;
    end

    // ------------------------------------------------------------------
    // Pin output register (ODR)
    //   D  = imm,  EN = pin_we & exec,  Q = pins_out
    // ------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            pins_out <= PINS_RESET;
        else if (pin_we & exec)
            pins_out <= imm;
    end
endmodule
