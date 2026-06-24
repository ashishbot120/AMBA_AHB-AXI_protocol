class bridge_base_test extends uvm_test;
    `uvm_component_utils(bridge_base_test)

    bridge_env env;

    function new(string name = "bridge_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = bridge_env::type_id::create("env", this);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        // Set error injection before simulation starts
        env.axi_agt.write_responder.error_on_txn = 2;
    endfunction

    task run_phase(uvm_phase phase);
        ahb_basic_seq ahb_seq;
        uvm_objection obj;

        obj = phase.get_objection();
        obj.set_drain_time(this, 300ns);
        phase.raise_objection(this);

        // Small delay for responders to initialise
        #50;

        // Drive all 3 test scenarios
        ahb_seq = ahb_basic_seq::type_id::create("ahb_seq");
        ahb_seq.start(env.ahb_agt.sequencer);

        // Wait for all 3 AXI transactions to complete
        #500;

        phase.drop_objection(this);
    endtask

endclass