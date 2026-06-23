`include "uvm_macros.svh"
import uvm_pkg::*;

module tb_top_uvm;

    logic HCLK;
    logic HRESETn;

    initial HCLK = 0;
    always #5 HCLK = ~HCLK;

    initial begin
        HRESETn = 0;
        repeat(4) @(posedge HCLK);
        HRESETn = 1;
    end

    ahb_if ahb_intf (.HCLK(HCLK), .HRESETn(HRESETn));
    axi_if axi_intf (.ACLK(HCLK), .ARESETn(HRESETn));

    bridge_top dut (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .HSEL(ahb_intf.HSEL), .HADDR(ahb_intf.HADDR),
        .HTRANS(ahb_intf.HTRANS), .HWRITE(ahb_intf.HWRITE),
        .HSIZE(ahb_intf.HSIZE), .HBURST(ahb_intf.HBURST),
        .HWDATA(ahb_intf.HWDATA), .HRDATA(ahb_intf.HRDATA),
        .HREADY(ahb_intf.HREADY), .HRESP(ahb_intf.HRESP),
        .AWADDR(axi_intf.AWADDR), .AWPROT(axi_intf.AWPROT),
        .AWVALID(axi_intf.AWVALID), .AWREADY(axi_intf.AWREADY),
        .WDATA(axi_intf.WDATA), .WSTRB(axi_intf.WSTRB),
        .WVALID(axi_intf.WVALID), .WREADY(axi_intf.WREADY),
        .BRESP(axi_intf.BRESP), .BVALID(axi_intf.BVALID),
        .BREADY(axi_intf.BREADY), .ARADDR(axi_intf.ARADDR),
        .ARPROT(axi_intf.ARPROT), .ARVALID(axi_intf.ARVALID),
        .ARREADY(axi_intf.ARREADY), .RDATA(axi_intf.RDATA),
        .RRESP(axi_intf.RRESP), .RVALID(axi_intf.RVALID),
        .RREADY(axi_intf.RREADY)
    );

    initial begin
        uvm_config_db#(virtual ahb_if.DRIVER)::set(null, "*", "vif", ahb_intf);
        uvm_config_db#(virtual ahb_if.MONITOR)::set(null, "*", "vif", ahb_intf);
        uvm_config_db#(virtual axi_if.SLAVE)::set(null, "*", "vif", axi_intf);
        uvm_config_db#(virtual axi_if.MONITOR)::set(null, "*", "vif", axi_intf);

        run_test("bridge_base_test");
    end

    initial begin
        $dumpfile("bridge_uvm.vcd");
        $dumpvars(0, tb_top_uvm);
    end

endmodule