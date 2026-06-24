class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    virtual axi_if.MONITOR vif;
    uvm_analysis_port #(axi_transaction) ap;

    function new(string name = "axi_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if.MONITOR)::get(this, "", "vif", vif))
            `uvm_fatal("AXI_MON", "Virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.ARESETn == 1'b1);
        @(vif.mon_cb);

        forever begin
            @(vif.mon_cb);

            // Check write address channel
            if (vif.mon_cb.AWVALID && vif.mon_cb.AWREADY) begin
                fork
                    capture_write(vif.mon_cb.AWADDR);
                join_none
            end

            // Check read address channel
            if (vif.mon_cb.ARVALID && vif.mon_cb.ARREADY) begin
                fork
                    capture_read(vif.mon_cb.ARADDR);
                join_none
            end
        end
    endtask

    task capture_write(logic [31:0] aw_addr);
        axi_transaction tr;
        logic [31:0] w_data;
        logic [3:0]  w_strb;
        logic [1:0]  bresp;

        // Wait for W channel
        do @(vif.mon_cb);
        while (!(vif.mon_cb.WVALID && vif.mon_cb.WREADY));
        w_data = vif.mon_cb.WDATA;
        w_strb = vif.mon_cb.WSTRB;

        // Wait for B channel
        do @(vif.mon_cb);
        while (!(vif.mon_cb.BVALID && vif.mon_cb.BREADY));
        bresp = vif.mon_cb.BRESP;

        tr = axi_transaction::type_id::create("tr");
        tr.addr  = aw_addr;
        tr.data  = w_data;
        tr.wstrb = w_strb;
        tr.write = 1'b1;
        tr.resp  = bresp;

        `uvm_info("AXI_MON",
            $sformatf("Write captured: addr=0x%0h data=0x%0h wstrb=%0b write=%0b resp=%0b",
                tr.addr, tr.data, tr.wstrb, tr.write, tr.resp),
            UVM_MEDIUM)
        ap.write(tr);
    endtask

    task capture_read(logic [31:0] ar_addr);
        axi_transaction tr;

        // Wait for R channel
        do @(vif.mon_cb);
        while (!(vif.mon_cb.RVALID && vif.mon_cb.RREADY));

        tr = axi_transaction::type_id::create("tr");
        tr.addr  = ar_addr;
        tr.data  = vif.mon_cb.RDATA;
        tr.write = 1'b0;
        tr.resp  = vif.mon_cb.RRESP;

        `uvm_info("AXI_MON",
            $sformatf("Read captured: addr=0x%0h data=0x%0h write=%0b resp=%0b",
                tr.addr, tr.data, tr.write, tr.resp),
            UVM_MEDIUM)
        ap.write(tr);
    endtask

endclass