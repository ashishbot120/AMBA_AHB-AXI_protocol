module ahb_slave (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        HSEL,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [2:0]  HBURST,
    input  wire [31:0] HWDATA,
    output reg  [31:0] HRDATA,
    output reg         HREADY,
    output reg  [1:0]  HRESP,
    output reg  [31:0] ahb_addr,
    output reg         ahb_write,
    output reg  [2:0]  ahb_size,
    output reg  [2:0]  ahb_burst,
    output reg  [31:0] ahb_wdata,
    output reg         ahb_valid,
    input  wire [31:0] fsm_rdata,
    input  wire        fsm_ready,
    input  wire        fsm_error
);

localparam IDLE   = 2'b00;
localparam BUSY   = 2'b01;
localparam NONSEQ = 2'b10;
localparam SEQ    = 2'b11;
localparam OKAY   = 2'b00;
localparam ERROR  = 2'b01;

reg error_second_cycle;
reg busy;

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
        ahb_valid <= 1'b0;
    end
end

// -------------------------------------------------------
// Write data — combinational, valid in data phase
// -------------------------------------------------------
always @(*) begin
    ahb_wdata = HWDATA;
end

// -------------------------------------------------------
// Busy flag — stays HIGH until fsm_ready
// -------------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
        busy <= 1'b0;
    else if (ahb_valid)
        busy <= 1'b1;
    else if (fsm_ready)
        busy <= 1'b0;
end

// -------------------------------------------------------
// HREADY
// -------------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
        HREADY <= 1'b1;
    else if (busy && !fsm_ready)
        HREADY <= 1'b0;
    else if (fsm_ready)
        HREADY <= 1'b1;
    else
        HREADY <= 1'b1;
end

// -------------------------------------------------------
// HRDATA — registered, fsm_rdata is now combinational
// so this captures valid data one cycle after S_COMPLETE
// which is exactly when fsm_ready fires (S_ERROR/S_IDLE)
// -------------------------------------------------------
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
        HRDATA <= 32'b0;
    else if (fsm_ready && !ahb_write)
        HRDATA <= fsm_rdata;
end

// -------------------------------------------------------
// HRESP — 2-cycle ERROR (fsm_error and fsm_ready now
// arrive on separate cycles from FSM S_COMPLETE/S_ERROR)
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
        HRESP              <= OKAY;
    end
end

endmodule