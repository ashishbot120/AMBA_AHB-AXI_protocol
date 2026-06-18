module axi_master (
    input  wire        ACLK,
    input  wire        ARESETn,

    // From bridge_fsm
    input  wire [31:0] axi_addr,
    input  wire [31:0] axi_wdata,
    input  wire [3:0]  axi_wstrb,
    input  wire        axi_write,
    input  wire        axi_start,

    // To bridge_fsm
    output reg  [31:0] axi_rdata,
    output reg  [1:0]  axi_resp,
    output reg         axi_done,

    // AXI4-Lite — Write address channel
    output reg  [31:0] AWADDR,
    output reg  [2:0]  AWPROT,
    output reg         AWVALID,
    input  wire        AWREADY,

    // AXI4-Lite — Write data channel
    output reg  [31:0] WDATA,
    output reg  [3:0]  WSTRB,
    output reg         WVALID,
    input  wire        WREADY,

    // AXI4-Lite — Write response channel
    input  wire [1:0]  BRESP,
    input  wire        BVALID,
    output reg         BREADY,

    // AXI4-Lite — Read address channel
    output reg  [31:0] ARADDR,
    output reg  [2:0]  ARPROT,
    output reg         ARVALID,
    input  wire        ARREADY,

    // AXI4-Lite — Read data channel
    input  wire [31:0] RDATA,
    input  wire [1:0]  RRESP,
    input  wire        RVALID,
    output reg         RREADY
);

localparam S_IDLE         = 3'd0;
localparam S_WR_ADDR_DATA = 3'd1;
localparam S_WR_RESP      = 3'd2;
localparam S_RD_ADDR      = 3'd3;
localparam S_RD_DATA      = 3'd4;

reg [2:0] state;
reg       aw_done, w_done;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        state     <= S_IDLE;
        AWVALID   <= 1'b0;
        WVALID    <= 1'b0;
        BREADY    <= 1'b0;
        ARVALID   <= 1'b0;
        RREADY    <= 1'b0;
        axi_done  <= 1'b0;
        aw_done   <= 1'b0;
        w_done    <= 1'b0;
        AWADDR    <= 32'b0;
        AWPROT    <= 3'b0;
        WDATA     <= 32'b0;
        WSTRB     <= 4'b0;
        ARADDR    <= 32'b0;
        ARPROT    <= 3'b0;
        axi_rdata <= 32'b0;
        axi_resp  <= 2'b00;
    end
    else begin
        axi_done <= 1'b0;   // default — overridden only when a beat finishes

        case (state)

            S_IDLE: begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
                if (axi_start) begin
                    if (axi_write) begin
                        AWADDR  <= axi_addr;
                        AWPROT  <= 3'b000;
                        AWVALID <= 1'b1;
                        WDATA   <= axi_wdata;
                        WSTRB   <= axi_wstrb;
                        WVALID  <= 1'b1;
                        state   <= S_WR_ADDR_DATA;
                    end
                    else begin
                        ARADDR  <= axi_addr;
                        ARPROT  <= 3'b000;
                        ARVALID <= 1'b1;
                        state   <= S_RD_ADDR;
                    end
                end
            end

            S_WR_ADDR_DATA: begin
                // AW and W are independent channels — either can finish first
                if (AWVALID && AWREADY) begin
                    AWVALID <= 1'b0;
                    aw_done <= 1'b1;
                end
                if (WVALID && WREADY) begin
                    WVALID <= 1'b0;
                    w_done <= 1'b1;
                end
                // Move on only once BOTH have completed (this cycle or earlier)
                if ((aw_done || (AWVALID && AWREADY)) &&
                    (w_done  || (WVALID  && WREADY))) begin
                    BREADY <= 1'b1;
                    state  <= S_WR_RESP;
                end
            end

            S_WR_RESP: begin
                if (BVALID && BREADY) begin
                    BREADY   <= 1'b0;
                    axi_resp <= BRESP;
                    axi_done <= 1'b1;
                    state    <= S_IDLE;
                end
            end

            S_RD_ADDR: begin
                if (ARVALID && ARREADY) begin
                    ARVALID <= 1'b0;
                    RREADY  <= 1'b1;
                    state   <= S_RD_DATA;
                end
            end

            S_RD_DATA: begin
                if (RVALID && RREADY) begin
                    RREADY    <= 1'b0;
                    axi_rdata <= RDATA;
                    axi_resp  <= RRESP;
                    axi_done  <= 1'b1;
                    state     <= S_IDLE;
                end
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule