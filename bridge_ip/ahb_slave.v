module ahb_slave (
    // Global signals
    input  wire        HCLK,
    input  wire        HRESETn,

    // AHB input signals
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [2:0]  HBURST,
    input  wire [31:0] HWDATA,

    // AHB output signals
    output reg  [31:0] HRDATA,
    output reg         HREADY,
    output reg  [1:0]  HRESP,

    // Internal interface to bridge_fsm
    output reg  [31:0] ahb_addr,
    output reg         ahb_write,
    output reg  [2:0]  ahb_size,
    output reg  [2:0]  ahb_burst,
    output reg  [31:0] ahb_wdata,
    output reg         ahb_valid,   // pulse: valid AHB transfer detected

    // Inputs from bridge_fsm
    input  wire [31:0] fsm_rdata,   // read data coming back from AXI
    input  wire        fsm_ready,   // bridge done, ok to complete transfer
    input  wire        fsm_error    // AXI returned error response
);

// HTRANS encoding
localparam IDLE   = 2'b00;
localparam BUSY   = 2'b01;
localparam NONSEQ = 2'b10;
localparam SEQ    = 2'b11;

// HRESP encoding
localparam OKAY  = 2'b00;
localparam ERROR = 2'b01;

reg error_second_cycle;

// -------------------------------------------------------
// Address phase register
// -------------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        ahb_addr  <= 32'b0;
        ahb_write <= 1'b0;
        ahb_size  <= 3'b0;
        ahb_burst <= 3'b0;
        ahb_valid <= 1'b0;
    end
    else if (HREADY) begin
    if (HSEL && (HTRANS == NONSEQ || HTRANS == SEQ)) begin
        ahb_addr  <= HADDR;
        ahb_write <= HWRITE;
        ahb_size  <= HSIZE;
        ahb_burst <= HBURST;
        ahb_valid <= 1'b1;
    end
    else begin
        ahb_valid <= 1'b0;
    end
end
else if (fsm_ready) begin
    ahb_valid <= 1'b0;   // NEW — clear immediately once this beat is consumed
end
end

// -------------------------------------------------------
// Write data — combinational, valid in data phase
// -------------------------------------------------------
always @(*) begin
    ahb_wdata = HWDATA;
end

// -------------------------------------------------------
// FIX 1 — HREADY now coordinates with the error 2-cycle rule
// FIX 2 — added explicit default else, no more stuck-low risk
// -------------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
        HREADY <= 1'b1;
    else if (fsm_error && !error_second_cycle)
        HREADY <= 1'b0;                       // force wait state, error cycle 1
    else if (error_second_cycle)
        HREADY <= 1'b1;                       // release on error cycle 2
    else if (ahb_valid && !fsm_ready)
        HREADY <= 1'b0;                       // normal stall, bridge still busy
    else if (fsm_ready)
        HREADY <= 1'b1;                       // normal completion
    else
        HREADY <= 1'b1;                       // safe default — never stuck low
end

// -------------------------------------------------------
// HRDATA — return AXI read data to AHB master
// -------------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
        HRDATA <= 32'b0;
    else if (fsm_ready && !ahb_write)
        HRDATA <= fsm_rdata;
end

// -------------------------------------------------------
// HRESP — 2-cycle ERROR response per AHB spec
// -------------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        HRESP              <= OKAY;
        error_second_cycle <= 1'b0;
    end
    else if (fsm_error && !error_second_cycle) begin
        HRESP              <= ERROR;
        error_second_cycle <= 1'b1;
    end
    else if (error_second_cycle) begin
        HRESP              <= ERROR;
        error_second_cycle <= 1'b0;
    end
    else begin
        HRESP <= OKAY;
    end
end

endmodule