`ifndef BRIDGE_PKG_SV
`define BRIDGE_PKG_SV

`include "uvm_macros.svh"

package bridge_pkg;
    import uvm_pkg::*;

    // seq_items
    `include "seq_items/ahb_transaction.sv"
    `include "seq_items/axi_transaction.sv"

    // agents
    `include "agents/ahb_driver.sv"
    `include "agents/ahb_monitor.sv"
    `include "agents/ahb_sequencer.sv"
    `include "agents/ahb_agent.sv"
    `include "agents/axi_monitor.sv"
    `include "agents/axi_write_responder.sv"
    `include "agents/axi_read_responder.sv"
    `include "agents/axi_agent.sv"

    // env
    `include "env/scoreboard.sv"
    `include "env/bridge_env.sv"

    // sequences
    `include "seq/ahb_basic_seq.sv"

    // test
    `include "test/bridge_base_test.sv"

endpackage

`endif