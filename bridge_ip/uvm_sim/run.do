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
vlog -work work ../rtl/ahb_slave.v
vlog -work work ../rtl/bridge_fsm.v
vlog -work work ../rtl/axi_master.v
vlog -work work ../rtl/bridge_top.v

# -------------------------------------------------------
# Compile UVM testbench (SystemVerilog)
# -------------------------------------------------------
vlog -work work -sv -L uvm_lib \
    +incdir+../uvm/interfaces \
    +incdir+../uvm/seq_items \
    +incdir+../uvm/agents \
    +incdir+../uvm/env \
    +incdir+../uvm/seq \
    +incdir+../uvm/test \
    ../uvm/interfaces/ahb_if.sv \
    ../uvm/interfaces/axi_if.sv \
    ../uvm/seq_items/ahb_transaction.sv \
    ../uvm/seq_items/axi_transaction.sv \
    ../uvm/agents/ahb_driver.sv \
    ../uvm/agents/ahb_monitor.sv \
    ../uvm/agents/ahb_sequencer.sv \
    ../uvm/agents/ahb_agent.sv \
    ../uvm/agents/axi_monitor.sv \
    ../uvm/agents/axi_write_responder.sv \
    ../uvm/agents/axi_read_responder.sv \
    ../uvm/agents/axi_agent.sv \
    ../uvm/env/scoreboard.sv \
    ../uvm/env/bridge_env.sv \
    ../uvm/seq/ahb_basic_seq.sv \
    ../uvm/seq/axi_response_seq.sv \
    ../uvm/test/bridge_base_test.sv \
    ../uvm/tb_top_uvm.sv

# -------------------------------------------------------
# Simulate
# -------------------------------------------------------
vsim -c work.tb_top_uvm \
     -L uvm_lib \
     +UVM_TESTNAME=bridge_base_test \
     +UVM_VERBOSITY=UVM_MEDIUM \
     -do "run -all; quit -f"