
`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    axi_monitor                      monitor;
    axi_write_responder               write_responder;
    axi_read_responder                read_responder;
    uvm_sequencer #(axi_transaction)  write_seqr;
    uvm_sequencer #(axi_transaction)  read_seqr;

    function new(string name = "axi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        monitor = axi_monitor::type_id::create("monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin
            write_responder = axi_write_responder::type_id::create("write_responder", this);
            read_responder  = axi_read_responder::type_id::create("read_responder", this);
            write_seqr      = uvm_sequencer#(axi_transaction)::type_id::create("write_seqr", this);
            read_seqr       = uvm_sequencer#(axi_transaction)::type_id::create("read_seqr", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            write_responder.seq_item_port.connect(write_seqr.seq_item_export);
            read_responder.seq_item_port.connect(read_seqr.seq_item_export);
        end
    endfunction

endclass