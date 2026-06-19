module bridge_top (
    // Global
    input  wire        HCLK,
    input  wire        HRESETn,

    // AHB slave interface
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [2:0]  HBURST,
    input  wire [31:0] HWDATA,
    output wire [31:0] HRDATA,
    output wire        HREADY,
    output wire [1:0]  HRESP,

    // AXI4-Lite master interface
    output wire [31:0] AWADDR,
    output wire [2:0]  AWPROT,
    output wire        AWVALID,
    input  wire        AWREADY,
    output wire [31:0] WDATA,
    output wire [3:0]  WSTRB,
    output wire        WVALID,
    input  wire        WREADY,
    input  wire [1:0]  BRESP,
    input  wire        BVALID,
    output wire        BREADY,
    output wire [31:0] ARADDR,
    output wire [2:0]  ARPROT,
    output wire        ARVALID,
    input  wire        ARREADY,
    input  wire [31:0] RDATA,
    input  wire [1:0]  RRESP,
    input  wire        RVALID,
    output wire        RREADY
);

// -------------------------------------------------------
// Internal wires — ahb_slave <-> bridge_fsm
// -------------------------------------------------------
wire [31:0] ahb_addr;
wire        ahb_write;
wire [2:0]  ahb_size;
wire [2:0]  ahb_burst;
wire [31:0] ahb_wdata;
wire        ahb_valid;
wire [31:0] fsm_rdata;
wire        fsm_ready;
wire        fsm_error;

// -------------------------------------------------------
// Internal wires — bridge_fsm <-> axi_master
// -------------------------------------------------------
wire [31:0] axi_addr;
wire [31:0] axi_wdata;
wire [3:0]  axi_wstrb;
wire        axi_write;
wire        axi_start;
wire [31:0] axi_rdata;
wire [1:0]  axi_resp;
wire        axi_done;

// -------------------------------------------------------
// Sub-module instantiations
// -------------------------------------------------------
ahb_slave u_ahb_slave (
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),
    .HSEL       (HSEL),
    .HADDR      (HADDR),
    .HTRANS     (HTRANS),
    .HWRITE     (HWRITE),
    .HSIZE      (HSIZE),
    .HBURST     (HBURST),
    .HWDATA     (HWDATA),
    .HRDATA     (HRDATA),
    .HREADY     (HREADY),
    .HRESP      (HRESP),
    .ahb_addr   (ahb_addr),
    .ahb_write  (ahb_write),
    .ahb_size   (ahb_size),
    .ahb_burst  (ahb_burst),
    .ahb_wdata  (ahb_wdata),
    .ahb_valid  (ahb_valid),
    .fsm_rdata  (fsm_rdata),
    .fsm_ready  (fsm_ready),
    .fsm_error  (fsm_error)
);

bridge_fsm u_bridge_fsm (
    .HCLK       (HCLK),
    .HRESETn    (HRESETn),
    .ahb_addr   (ahb_addr),
    .ahb_write  (ahb_write),
    .ahb_size   (ahb_size),
    .ahb_burst  (ahb_burst),
    .ahb_wdata  (ahb_wdata),
    .ahb_valid  (ahb_valid),
    .fsm_rdata  (fsm_rdata),
    .fsm_ready  (fsm_ready),
    .fsm_error  (fsm_error),
    .axi_addr   (axi_addr),
    .axi_wdata  (axi_wdata),
    .axi_wstrb  (axi_wstrb),
    .axi_write  (axi_write),
    .axi_start  (axi_start),
    .axi_rdata  (axi_rdata),
    .axi_resp   (axi_resp),
    .axi_done   (axi_done)
);

axi_master u_axi_master (
    .ACLK       (HCLK),
    .ARESETn    (HRESETn),
    .axi_addr   (axi_addr),
    .axi_wdata  (axi_wdata),
    .axi_wstrb  (axi_wstrb),
    .axi_write  (axi_write),
    .axi_start  (axi_start),
    .axi_rdata  (axi_rdata),
    .axi_resp   (axi_resp),
    .axi_done   (axi_done),
    .AWADDR     (AWADDR),
    .AWPROT     (AWPROT),
    .AWVALID    (AWVALID),
    .AWREADY    (AWREADY),
    .WDATA      (WDATA),
    .WSTRB      (WSTRB),
    .WVALID     (WVALID),
    .WREADY     (WREADY),
    .BRESP      (BRESP),
    .BVALID     (BVALID),
    .BREADY     (BREADY),
    .ARADDR     (ARADDR),
    .ARPROT     (ARPROT),
    .ARVALID    (ARVALID),
    .ARREADY    (ARREADY),
    .RDATA      (RDATA),
    .RRESP      (RRESP),
    .RVALID     (RVALID),
    .RREADY     (RREADY)
);

endmodule