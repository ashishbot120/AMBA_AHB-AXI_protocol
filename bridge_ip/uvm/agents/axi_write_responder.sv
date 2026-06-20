class axi_write_responder extends uvm_driver #(axi_transaction);
    `uvm_component_utils(axi_write_responder)

    virtual axi_if.SLAVE vif;

    function new(string name = "axi_write_responder", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if.SLAVE)::get(this, "", "vif", vif))
            `uvm_fatal("AXI_WR_RESP", "Virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        vif.slv_cb.AWREADY <= 1'b0;
        vif.slv_cb.WREADY  <= 1'b0;
        vif.slv_cb.BVALID  <= 1'b0;
        vif.slv_cb.BRESP   <= 2'b00;

        wait (vif.ARESETn == 1'b1);

        forever begin
            axi_transaction tr;

            // Wait for a write address to appear
            @(vif.slv_cb);
            wait (vif.slv_cb.AWVALID);

            // Ask the sequence what response to send for this write
            seq_item_port.get_next_item(tr);

            // Accept AW
            vif.slv_cb.AWREADY <= 1'b1;
            @(vif.slv_cb);
            vif.slv_cb.AWREADY <= 1'b0;

            // Accept W
            wait (vif.slv_cb.WVALID);
            vif.slv_cb.WREADY <= 1'b1;
            @(vif.slv_cb);
            vif.slv_cb.WREADY <= 1'b0;

            // Drive write response
            wait (vif.slv_cb.BREADY);
            vif.slv_cb.BVALID <= 1'b1;
            vif.slv_cb.BRESP  <= tr.resp;
            @(vif.slv_cb);
            vif.slv_cb.BVALID <= 1'b0;

            seq_item_port.item_done();
        end
    endtask

endclass