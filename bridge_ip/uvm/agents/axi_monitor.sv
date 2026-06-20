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
        // Write and read channels are independent — track both concurrently
        fork
            monitor_write();
            monitor_read();
        join
    endtask

    task monitor_write();
        axi_transaction tr;
        logic [31:0] aw_addr;
        logic [31:0] w_data;
        logic [3:0]  w_strb;
        bit aw_seen, w_seen;

        forever begin
            aw_seen = 0;
            w_seen  = 0;

            // AW and W can complete in either order — catch both independently
            while (!(aw_seen && w_seen)) begin
                @(vif.mon_cb);
                if (vif.mon_cb.AWVALID && vif.mon_cb.AWREADY && !aw_seen) begin
                    aw_addr = vif.mon_cb.AWADDR;
                    aw_seen = 1;
                end
                if (vif.mon_cb.WVALID && vif.mon_cb.WREADY && !w_seen) begin
                    w_data = vif.mon_cb.WDATA;
                    w_strb = vif.mon_cb.WSTRB;
                    w_seen = 1;
                end
            end

            // Now wait for the write response
            while (!(vif.mon_cb.BVALID && vif.mon_cb.BREADY))
                @(vif.mon_cb);

            tr = axi_transaction::type_id::create("tr");
            tr.addr  = aw_addr;
            tr.data  = w_data;
            tr.wstrb = w_strb;
            tr.write = 1'b1;
            tr.resp  = vif.mon_cb.BRESP;

            `uvm_info("AXI_MON",
                $sformatf("Write captured: %s", tr.convert2string()), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

    task monitor_read();
        axi_transaction tr;
        logic [31:0] ar_addr;

        forever begin
            do @(vif.mon_cb);
            while (!(vif.mon_cb.ARVALID && vif.mon_cb.ARREADY));
            ar_addr = vif.mon_cb.ARADDR;

            do @(vif.mon_cb);
            while (!(vif.mon_cb.RVALID && vif.mon_cb.RREADY));

            tr = axi_transaction::type_id::create("tr");
            tr.addr  = ar_addr;
            tr.data  = vif.mon_cb.RDATA;
            tr.write = 1'b0;
            tr.resp  = vif.mon_cb.RRESP;

            `uvm_info("AXI_MON",
                $sformatf("Read captured: %s", tr.convert2string()), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

endclass