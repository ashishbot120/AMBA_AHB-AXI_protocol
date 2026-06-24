
class ahb_driver extends uvm_driver #(ahb_transaction);
    `uvm_component_utils(ahb_driver)

    virtual ahb_if.DRIVER vif;

    function new(string name = "ahb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if.DRIVER)::get(this, "", "vif", vif))
            `uvm_fatal("AHB_DRV", "Virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // Reset state at start
        vif.drv_cb.HSEL    <= 1'b0;
        vif.drv_cb.HTRANS  <= 2'b00;
        vif.drv_cb.HADDR   <= 32'b0;
        vif.drv_cb.HWRITE  <= 1'b0;
        vif.drv_cb.HSIZE   <= 3'b010;
        vif.drv_cb.HBURST  <= 3'b000;
        vif.drv_cb.HWDATA  <= 32'b0;

        wait (vif.HRESETn == 1'b1);

        forever begin
            ahb_transaction tr;
            seq_item_port.get_next_item(tr);
            drive_transfer(tr);
            seq_item_port.item_done();
        end
    endtask

task drive_transfer(ahb_transaction tr);
    // --- Address phase ---
    @(vif.drv_cb);
    vif.drv_cb.HSEL   <= 1'b1;
    vif.drv_cb.HADDR  <= tr.addr;
    vif.drv_cb.HTRANS <= 2'b10;
    vif.drv_cb.HWRITE <= tr.write;
    vif.drv_cb.HSIZE  <= tr.size;
    vif.drv_cb.HBURST <= tr.burst;

    // --- Move to data phase (1 clock after address) ---
    @(vif.drv_cb);
    vif.drv_cb.HWDATA <= tr.data;
    vif.drv_cb.HTRANS <= 2'b00;
    vif.drv_cb.HSEL   <= 1'b0;

    // --- Wait 1 extra clock for bridge to react and pull HREADY LOW ---
    @(vif.drv_cb);

    // --- Now wait for HREADY LOW (bridge busy) ---
    while (vif.drv_cb.HREADY == 1'b1)
        @(vif.drv_cb);

    // --- Wait for HREADY HIGH (bridge done) ---
    while (vif.drv_cb.HREADY == 1'b0)
        @(vif.drv_cb);

    // --- Capture response ---
    tr.rdata = vif.drv_cb.HRDATA;
    tr.resp  = vif.drv_cb.HRESP;
endtask

endclass