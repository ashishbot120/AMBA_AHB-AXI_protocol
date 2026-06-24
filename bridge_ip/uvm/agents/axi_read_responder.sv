class axi_read_responder extends uvm_component;
    `uvm_component_utils(axi_read_responder)

    virtual axi_if.SLAVE vif;

    function new(string name = "axi_read_responder", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if.SLAVE)::get(this, "", "vif", vif))
            `uvm_fatal("AXI_RD_RESP", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        vif.slv_cb.ARREADY <= 1'b0;
        vif.slv_cb.RVALID  <= 1'b0;
        vif.slv_cb.RDATA   <= 32'hCAFEBABE;
        vif.slv_cb.RRESP   <= 2'b00;

        wait (vif.ARESETn == 1'b1);
        @(vif.slv_cb);

        forever begin
            // Accept AR
            wait (vif.slv_cb.ARVALID);
            vif.slv_cb.ARREADY <= 1'b1;
            @(vif.slv_cb);
            vif.slv_cb.ARREADY <= 1'b0;

            // Send read data
            wait (vif.slv_cb.RREADY);
            vif.slv_cb.RVALID <= 1'b1;
            vif.slv_cb.RDATA  <= 32'hCAFEBABE;
            vif.slv_cb.RRESP  <= 2'b00;
            @(vif.slv_cb);
            vif.slv_cb.RVALID <= 1'b0;
            @(vif.slv_cb);
        end
    endtask

endclass