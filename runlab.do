# ModelSim script for the Phase 0 engine.
# Run from this folder so $readmemb can find program.mem.
# engine_tb.sv is YOUR testbench -- write it in this folder, then `do runlab.do`.

vlib work

vlog -sv "./control.sv"
vlog -sv "./delay_counter.sv"
vlog -sv "./instructmem.sv"
vlog -sv "./engine.sv"
vlog -sv "./engine_tb.sv"

vsim -voptargs="+acc" -t 1ps -lib work engine_tb

add wave -noupdate /engine_tb/dut/clk
add wave -noupdate /engine_tb/dut/rst
add wave -noupdate /engine_tb/dut/run
add wave -noupdate -radix unsigned /engine_tb/dut/pc
add wave -noupdate -radix binary   /engine_tb/dut/instr
add wave -noupdate /engine_tb/dut/exec
add wave -noupdate -radix unsigned /engine_tb/dut/u_dly/dcnt
add wave -noupdate -radix unsigned /engine_tb/dut/x
add wave -noupdate /engine_tb/dut/jump_taken
add wave -noupdate -radix binary   /engine_tb/dut/pins_out

view wave
run -all
