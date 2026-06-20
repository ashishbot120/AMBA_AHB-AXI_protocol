interface ahb_if (input logic HCLK, input logic HRESETn);

    logic        HSEL;
    logic [31:0] HADDR;
    logic [1:0]  HTRANS;
    logic        HWRITE;
    logic [2:0]  HSIZE;
    logic [2:0]  HBURST;
    logic [31:0] HWDATA;
    logic [31:0] HRDATA;
    logic        HREADY;
    logic [1:0]  HRESP;

    // Driver clocking block — controls timing of driven signals
    clocking drv_cb @(posedge HCLK);
        output HSEL, HADDR, HTRANS, HWRITE, HSIZE, HBURST, HWDATA;
        input  HRDATA, HREADY, HRESP;
    endclocking

    // Monitor clocking block — passive sampling only
    clocking mon_cb @(posedge HCLK);
        input HSEL, HADDR, HTRANS, HWRITE, HSIZE, HBURST,
              HWDATA, HRDATA, HREADY, HRESP;
    endclocking

    modport DRIVER (clocking drv_cb, input HCLK, HRESETn);
    modport MONITOR (clocking mon_cb, input HCLK, HRESETn);

endinterface