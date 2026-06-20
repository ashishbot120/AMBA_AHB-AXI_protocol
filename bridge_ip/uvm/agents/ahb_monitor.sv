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
        ahb_transaction tr;

        wait (vif.HRESETn == 1'b1);

        forever begin
            // Wait for a valid address phase
            @(vif.mon_cb);
            if (vif.mon_cb.HSEL &&
                (vif.mon_cb.HTRANS == 2'b10 || vif.mon_cb.HTRANS == 2'b11) &&
                vif.mon_cb.HREADY) begin

                tr = ahb_transaction::type_id::create("tr");
                tr.addr  = vif.mon_cb.HADDR;
                tr.write = vif.mon_cb.HWRITE;
                tr.size  = vif.mon_cb.HSIZE;
                tr.burst = vif.mon_cb.HBURST;

                // Data phase is the next cycle
                @(vif.mon_cb);
                tr.data = vif.mon_cb.HWDATA;

                // Wait until the transfer actually completes (HREADY high)
                wait (vif.mon_cb.HREADY == 1'b1);
                @(vif.mon_cb);

                tr.rdata = vif.mon_cb.HRDATA;
                tr.resp  = vif.mon_cb.HRESP;

                `uvm_info("AHB_MON",
                    $sformatf("Captured: %s", tr.convert2string()),
                    UVM_MEDIUM)

                ap.write(tr);   // broadcast to scoreboard + coverage
            end
        end
    endtask

endclass