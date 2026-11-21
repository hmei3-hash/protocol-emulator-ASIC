`timescale 1ns/10ps
// ============================================================================
// control.sv  --  Phase 0 decoder (pure combinational)
//
// Instruction format (16 bit):
//   [15:13] opcode   SET = 3'b000, JMP = 3'b111
//   [12:8]  delay    extra idle cycles after this instruction (0..31)
//   [7:5]   sub      SET: dest  (000 = pins, 001 = X)
//                    JMP: cond  (000 = always, 001 = X-- : jump if X!=0, X <= X-1)
//   [4:0]   data     SET: immediate value
//                    JMP: absolute target address
//
// Any undefined opcode/sub combination decodes to all-zero outputs = NOP
// (nothing written, no jump, PC advances normally).
//
// Matches the Phase 0 control table:
//            set pins  set x  jmp  jmp x--
//   pin_we      1        0     0     0
//   x_we        0        1     0     1
//   x_src       X        0     X     1
//   is_jmp      0        0     1     1
// ============================================================================
module control (
    input  logic [2:0] opcode,   // instr[15:13]
    input  logic [2:0] sub,      // instr[7:5]  (dest for SET, cond for JMP)
    output logic       pin_we,   // write the pin output register (ODR)
    output logic       x_we,     // write X
    output logic       x_src,    // X input select: 0 = immediate, 1 = X - 1
    output logic       is_jmp    // this is a jump instruction
);
    localparam logic [2:0] OP_SET      = 3'b000;
    localparam logic [2:0] OP_JMP      = 3'b111;

    localparam logic [2:0] DEST_PINS   = 3'b000;
    localparam logic [2:0] DEST_X      = 3'b001;

    localparam logic [2:0] COND_ALWAYS = 3'b000;
    localparam logic [2:0] COND_XDEC   = 3'b001;

    always_comb begin
        // Defaults: everything off = NOP. Every path below only turns things on.
        pin_we = 1'b0;
        x_we   = 1'b0;
        x_src  = 1'b0;
        is_jmp = 1'b0;

        case (opcode)
            OP_SET: begin
                case (sub)
                    DEST_PINS: pin_we = 1'b1;
                    DEST_X: begin
                        x_we  = 1'b1;
                        x_src = 1'b0;          // take the immediate
                    end
                    default: ;                 // undefined dest -> NOP
                endcase
            end

            OP_JMP: begin
                case (sub)
                    COND_ALWAYS: is_jmp = 1'b1;
                    COND_XDEC: begin
                        is_jmp = 1'b1;
                        x_we   = 1'b1;         // X is decremented whether or not we jump
                        x_src  = 1'b1;         // take X - 1
                    end
                    default: ;                 // undefined cond -> NOP
                endcase
            end

            default: ;                         // undefined opcode -> NOP
        endcase
    end
endmodule
