# -------------------------------------------------------
# run.do — AHB-AXI Bridge UVM simulation script
# Run from: bridge_ip\uvm_sim\
# -------------------------------------------------------

# Clean previous work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# -------------------------------------------------------
# Compile RTL (plain Verilog)
# -------------------------------------------------------
vlog -reportprogress 300 -work work ../rtl/ahb_slave.v
vlog -reportprogress 300 -work work ../rtl/bridge_fsm.v
vlog -reportprogress 300 -work work ../rtl/axi_master.v
vlog -reportprogress 300 -work work ../rtl/bridge_top.v

# -------------------------------------------------------
# Compile UVM package + testbench
# -------------------------------------------------------
vlog -reportprogress 300 -work work -sv -L uvm_lib \
    +incdir+../uvm \
    +incdir+../uvm/interfaces \
    +incdir+../uvm/seq_items \
    +incdir+../uvm/agents \
    +incdir+../uvm/env \
    +incdir+../uvm/seq \
    +incdir+../uvm/test \
    +incdir+C:/altera_lite/25.1std/questa_fse/verilog_src/uvm-1.1d/src \
    ../uvm/interfaces/ahb_if.sv \
    ../uvm/interfaces/axi_if.sv \
    ../uvm/bridge_pkg.sv \
    ../uvm/tb_top_uvm.sv

# -------------------------------------------------------
# Simulate
# -------------------------------------------------------
vsim -c work.tb_top_uvm \
     -L uvm_lib \
     -sv_lib "C:/altera_lite/25.1std/questa_fse/uvm-1.1d/win64/uvm_dpi" \
     +UVM_TESTNAME=bridge_base_test \
     +UVM_VERBOSITY=UVM_MEDIUM \
     -do "run -all"