module bridge_fsm (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire [31:0] ahb_addr,
    input  wire        ahb_write,
    input  wire [2:0]  ahb_size,
    input  wire [2:0]  ahb_burst,
    input  wire [31:0] ahb_wdata,
    input  wire        ahb_valid,
    output reg  [31:0] fsm_rdata,
    output reg         fsm_ready,
    output reg         fsm_error,
    output reg  [31:0] axi_addr,
    output reg  [31:0] axi_wdata,
    output reg  [3:0]  axi_wstrb,
    output reg         axi_write,
    output reg         axi_start,
    input  wire [31:0] axi_rdata,
    input  wire [1:0]  axi_resp,
    input  wire        axi_done
);

localparam S_IDLE     = 3'd0;
localparam S_ISSUE    = 3'd1;
localparam S_WAIT     = 3'd2;
localparam S_COMPLETE = 3'd3;
localparam S_ERROR    = 3'd4;

reg [2:0]  state;
reg [31:0] addr_reg, wdata_reg, rdata_reg;
reg        write_reg;
reg [3:0]  wstrb_reg;
reg [1:0]  resp_reg;

function [3:0] calc_wstrb;
    input [31:0] addr;
    input [2:0]  size;
    begin
        case (size)
            3'b000: begin
                case (addr[1:0])
                    2'b00: calc_wstrb = 4'b0001;
                    2'b01: calc_wstrb = 4'b0010;
                    2'b10: calc_wstrb = 4'b0100;
                    2'b11: calc_wstrb = 4'b1000;
                endcase
            end
            3'b001: begin
                case (addr[1])
                    1'b0: calc_wstrb = 4'b0011;
                    1'b1: calc_wstrb = 4'b1100;
                endcase
            end
            default: calc_wstrb = 4'b1111;
        endcase
    end
endfunction

always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        state     <= S_IDLE;
        fsm_ready <= 1'b0;
        fsm_error <= 1'b0;
        fsm_rdata <= 32'b0;
        axi_start <= 1'b0;
        axi_addr  <= 32'b0;
        axi_wdata <= 32'b0;
        axi_wstrb <= 4'b0;
        axi_write <= 1'b0;
        rdata_reg <= 32'b0;
        resp_reg  <= 2'b0;
        addr_reg  <= 32'b0;
        wdata_reg <= 32'b0;
        write_reg <= 1'b0;
        wstrb_reg <= 4'b0;
    end
    else begin
        axi_start <= 1'b0;
        fsm_ready <= 1'b0;
        fsm_error <= 1'b0;

        case (state)
            S_IDLE: begin
                if (ahb_valid) begin
                    addr_reg  <= ahb_addr;
                    wdata_reg <= ahb_wdata;
                    write_reg <= ahb_write;
                    wstrb_reg <= calc_wstrb(ahb_addr, ahb_size);
                    state     <= S_ISSUE;
                end
            end

            S_ISSUE: begin
                axi_addr  <= addr_reg;
                axi_wdata <= wdata_reg;
                axi_wstrb <= wstrb_reg;
                axi_write <= write_reg;
                axi_start <= 1'b1;
                state     <= S_WAIT;
            end

            S_WAIT: begin
                if (axi_done) begin
                    rdata_reg <= axi_rdata;
                    resp_reg  <= axi_resp;
                    state     <= S_COMPLETE;
                end
            end

            S_COMPLETE: begin
                fsm_rdata <= rdata_reg;
                if (resp_reg != 2'b00) begin
                    fsm_error <= 1'b1;
                    state     <= S_ERROR;
                end
                else begin
                    fsm_ready <= 1'b1;
                    state     <= S_IDLE;
                end
            end

            S_ERROR: begin
                fsm_ready <= 1'b1;
                state     <= S_IDLE;
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule