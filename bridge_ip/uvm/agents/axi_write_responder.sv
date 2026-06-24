class axi_write_responder extends uvm_component;
    `uvm_component_utils(axi_write_responder)

    virtual axi_if.SLAVE vif;

    // Set this from the test to inject errors
    // -1 = never error, N = error on Nth write
    int error_on_txn = -1;
    int txn_count    = 0;

    function new(string name = "axi_write_responder", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if.SLAVE)::get(this, "", "vif", vif))
            `uvm_fatal("AXI_WR_RESP", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        vif.slv_cb.AWREADY <= 1'b0;
        vif.slv_cb.WREADY  <= 1'b0;
        vif.slv_cb.BVALID  <= 1'b0;
        vif.slv_cb.BRESP   <= 2'b00;

        wait (vif.ARESETn == 1'b1);
        @(vif.slv_cb);

        forever begin
            logic [1:0] resp;
            txn_count++;
            resp = (txn_count == error_on_txn) ? 2'b10 : 2'b00;

            // Accept AW
            wait (vif.slv_cb.AWVALID);
            vif.slv_cb.AWREADY <= 1'b1;
            @(vif.slv_cb);
            vif.slv_cb.AWREADY <= 1'b0;

            // Accept W
            wait (vif.slv_cb.WVALID);
            vif.slv_cb.WREADY <= 1'b1;
            @(vif.slv_cb);
            vif.slv_cb.WREADY <= 1'b0;

            // Send response
            wait (vif.slv_cb.BREADY);
            vif.slv_cb.BVALID <= 1'b1;
            vif.slv_cb.BRESP  <= resp;
            @(vif.slv_cb);
            vif.slv_cb.BVALID <= 1'b0;
            @(vif.slv_cb);
        end
    endtask

endclass