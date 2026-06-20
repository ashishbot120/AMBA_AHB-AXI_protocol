class axi_read_responder extends uvm_driver #(axi_transaction);
    `uvm_component_utils(axi_read_responder)

    virtual axi_if.SLAVE vif;

    function new(string name = "axi_read_responder", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if.SLAVE)::get(this, "", "vif", vif))
            `uvm_fatal("AXI_RD_RESP", "Virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        vif.slv_cb.ARREADY <= 1'b0;
        vif.slv_cb.RVALID  <= 1'b0;
        vif.slv_cb.RDATA   <= 32'b0;
        vif.slv_cb.RRESP   <= 2'b00;

        wait (vif.ARESETn == 1'b1);

        forever begin
            axi_transaction tr;

            @(vif.slv_cb);
            wait (vif.slv_cb.ARVALID);

            // Ask the sequence what read data + response to send back
            seq_item_port.get_next_item(tr);

            vif.slv_cb.ARREADY <= 1'b1;
            @(vif.slv_cb);
            vif.slv_cb.ARREADY <= 1'b0;

            wait (vif.slv_cb.RREADY);
            vif.slv_cb.RVALID <= 1'b1;
            vif.slv_cb.RDATA  <= tr.data;
            vif.slv_cb.RRESP  <= tr.resp;
            @(vif.slv_cb);
            vif.slv_cb.RVALID <= 1'b0;

            seq_item_port.item_done();
        end
    endtask

endclass