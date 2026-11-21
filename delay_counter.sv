`timescale 1ns/10ps
// ============================================================================
// delay_counter.sv  --  per-instruction delay counter
//
// Behaviour (one clock per row):
//   load = 1               -> dcnt <= delay_in   (new instruction just executed)
//   load = 0, dcnt != 0    -> dcnt <= dcnt - 1   (still waiting)
//   load = 0, dcnt == 0    -> dcnt holds at 0    (idle; must NOT wrap to 31)
//
// dcnt_zero = 1 when the count is 0, i.e. the next instruction may execute.
// In the engine, load is tied to exec = run & dcnt_zero.
// An instruction with delay N therefore occupies 1 + N cycles.
// ============================================================================
module delay_counter #(
    parameter int W = 5                 // width of the delay field
) (
    input  logic         clk,
    input  logic         rst,           // synchronous, active high
    input  logic         load,          // = exec
    input  logic [W-1:0] delay_in,      // = instr[12:8]
    output logic         dcnt_zero
);
    logic [W-1:0] dcnt;
    logic [W-1:0] dcnt_next;
    logic         en;

    assign dcnt_zero = (dcnt == '0);                      // NOR of all bits
    assign en        = load | ~dcnt_zero;                 // update when loading or counting
    assign dcnt_next = load ? delay_in : (dcnt - 1'b1);   // 2:1 mux, sel = load

    always_ff @(posedge clk) begin
        if (rst)
            dcnt <= '0;
        else if (en)
            dcnt <= dcnt_next;
    end
endmodule
