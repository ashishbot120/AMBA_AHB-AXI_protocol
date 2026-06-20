interface axi_if (input logic ACLK, input logic ARESETn);

    logic [31:0] AWADDR;
    logic [2:0]  AWPROT;
    logic        AWVALID;
    logic        AWREADY;

    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WREADY;

    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    logic [31:0] ARADDR;
    logic [2:0]  ARPROT;
    logic        ARVALID;
    logic        ARREADY;

    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RREADY;

    // Slave-side clocking block — drives READY/response signals,
    // samples the master-driven address/data signals.
    // Will be used by the AXI slave responder we write next.
    clocking slv_cb @(posedge ACLK);
        input  AWADDR, AWPROT, AWVALID, WDATA, WSTRB, WVALID,
               ARADDR, ARPROT, ARVALID, BREADY, RREADY;
        output AWREADY, WREADY, BRESP, BVALID, RDATA, RRESP, RVALID;
    endclocking

    // Monitor clocking block — fully passive
    clocking mon_cb @(posedge ACLK);
        input AWADDR, AWPROT, AWVALID, AWREADY,
              WDATA, WSTRB, WVALID, WREADY,
              BRESP, BVALID, BREADY,
              ARADDR, ARPROT, ARVALID, ARREADY,
              RDATA, RRESP, RVALID, RREADY;
    endclocking

    modport SLAVE   (clocking slv_cb, input ACLK, ARESETn);
    modport MONITOR (clocking mon_cb, input ACLK, ARESETn);

endinterface