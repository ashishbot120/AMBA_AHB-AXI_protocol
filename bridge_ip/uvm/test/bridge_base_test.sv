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

    task run_phase(uvm_phase phase);
        ahb_basic_seq    ahb_seq;
        axi_response_seq wr_resp_seq;
        axi_response_seq rd_resp_seq;

        phase.raise_objection(this);

        // Background AXI responders must be alive before AHB stimulus starts
        wr_resp_seq = axi_response_seq::type_id::create("wr_resp_seq");
        wr_resp_seq.error_on_txn = 2;   // SLVERR on 2nd write — recreates Test 3
        fork
            wr_resp_seq.start(env.axi_agt.write_seqr);
        join_none

        rd_resp_seq = axi_response_seq::type_id::create("rd_resp_seq");
        fork
            rd_resp_seq.start(env.axi_agt.read_seqr);
        join_none

        #10;  // let responders settle before driving stimulus

        // Drive the actual directed test scenarios
        ahb_seq = ahb_basic_seq::type_id::create("ahb_seq");
        ahb_seq.start(env.ahb_agt.sequencer);

        #100; // allow final response to fully propagate before ending

        phase.drop_objection(this);
    endtask

endclass