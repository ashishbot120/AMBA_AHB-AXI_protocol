class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)

    virtual ahb_if.MONITOR vif;
    uvm_analysis_port #(ahb_transaction) ap;

    function new(string name = "ahb_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if.MONITOR)::get(this, "", "vif", vif))
            `uvm_fatal("AHB_MON", "Virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.HRESETn == 1'b1);

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.HSEL   == 1'b1 &&
                vif.mon_cb.HREADY == 1'b1 &&
                (vif.mon_cb.HTRANS == 2'b10 ||
                 vif.mon_cb.HTRANS == 2'b11)) begin

                ahb_transaction tr;
                tr       = ahb_transaction::type_id::create("tr");
                tr.addr  = vif.mon_cb.HADDR;
                tr.write = vif.mon_cb.HWRITE;
                tr.size  = vif.mon_cb.HSIZE;
                tr.burst = vif.mon_cb.HBURST;
                tr.resp  = 2'b00;
                tr.rdata = 32'b0;
                tr.data  = 32'b0;

                if (tr.write)
                    capture_write(tr);
                else
                    capture_read(tr);
            end
        end
    endtask

    task capture_write(ahb_transaction tr);
        // Data phase — HWDATA valid one cycle after address
        @(vif.mon_cb);
        tr.data = vif.mon_cb.HWDATA;

        // Wait for bridge to go busy then complete
        while (vif.mon_cb.HREADY == 1'b1)
            @(vif.mon_cb);

        while (vif.mon_cb.HREADY == 1'b0) begin
            if (vif.mon_cb.HRESP == 2'b01)
                tr.resp = 2'b01;
            @(vif.mon_cb);
        end

        if (vif.mon_cb.HRESP == 2'b01)
            tr.resp = 2'b01;

        `uvm_info("AHB_MON",
            $sformatf("Captured: addr=0x%0h data=0x%0h write=%0b resp=%0b",
                tr.addr, tr.data, tr.write, tr.resp),
            UVM_MEDIUM)
        ap.write(tr);
    endtask

    task capture_read(ahb_transaction tr);
    // Move into data phase
    @(vif.mon_cb);

    // Extra clock to let bridge pull HREADY LOW
    @(vif.mon_cb);

    // Wait for HREADY LOW then HIGH
    while (vif.mon_cb.HREADY == 1'b0) begin
        if (vif.mon_cb.HRESP == 2'b01)
            tr.resp = 2'b01;
        @(vif.mon_cb);
    end

    // HREADY HIGH — sample HRDATA now
    if (vif.mon_cb.HRESP == 2'b01)
        tr.resp = 2'b01;

    tr.rdata = vif.mon_cb.HRDATA;

    `uvm_info("AHB_MON",
        $sformatf("Captured: addr=0x%0h rdata=0x%0h write=%0b resp=%0b",
            tr.addr, tr.rdata, tr.write, tr.resp),
        UVM_MEDIUM)
    ap.write(tr);
endtask

endclass