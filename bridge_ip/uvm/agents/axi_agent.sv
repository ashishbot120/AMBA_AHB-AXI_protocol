class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    axi_monitor          monitor;
    axi_write_responder  write_responder;
    axi_read_responder   read_responder;

    function new(string name = "axi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = axi_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            write_responder = axi_write_responder::type_id::create("write_responder", this);
            read_responder  = axi_read_responder::type_id::create("read_responder", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        // No sequencer connections needed
    endfunction

endclass