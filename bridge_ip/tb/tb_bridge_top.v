`timescale 1ns/1ps

module tb_bridge_top;

// -------------------------------------------------------
// Clock and reset
// -------------------------------------------------------
reg HCLK;
reg HRESETn;

initial HCLK = 0;
always #5 HCLK = ~HCLK;   // 100MHz clock, 10ns period

// -------------------------------------------------------
// AHB signals
// -------------------------------------------------------
reg         HSEL;
reg  [31:0] HADDR;
reg  [1:0]  HTRANS;
reg         HWRITE;
reg  [2:0]  HSIZE;
reg  [2:0]  HBURST;
reg  [31:0] HWDATA;
wire [31:0] HRDATA;
wire        HREADY;
wire [1:0]  HRESP;

// -------------------------------------------------------
// AXI4-Lite signals
// -------------------------------------------------------
wire [31:0] AWADDR;
wire [2:0]  AWPROT;
wire        AWVALID;
reg         AWREADY;
wire [31:0] WDATA;
wire [3:0]  WSTRB;
wire        WVALID;
reg         WREADY;
reg  [1:0]  BRESP;
reg         BVALID;
wire        BREADY;
wire [31:0] ARADDR;
wire [2:0]  ARPROT;
wire        ARVALID;
reg         ARREADY;
reg  [31:0] RDATA;
reg  [1:0]  RRESP;
reg         RVALID;
wire        RREADY;

// -------------------------------------------------------
// DUT instantiation
// -------------------------------------------------------
bridge_top dut (
    .HCLK    (HCLK),
    .HRESETn (HRESETn),
    .HSEL    (HSEL),
    .HADDR   (HADDR),
    .HTRANS  (HTRANS),
    .HWRITE  (HWRITE),
    .HSIZE   (HSIZE),
    .HBURST  (HBURST),
    .HWDATA  (HWDATA),
    .HRDATA  (HRDATA),
    .HREADY  (HREADY),
    .HRESP   (HRESP),
    .AWADDR  (AWADDR),
    .AWPROT  (AWPROT),
    .AWVALID (AWVALID),
    .AWREADY (AWREADY),
    .WDATA   (WDATA),
    .WSTRB   (WSTRB),
    .WVALID  (WVALID),
    .WREADY  (WREADY),
    .BRESP   (BRESP),
    .BVALID  (BVALID),
    .BREADY  (BREADY),
    .ARADDR  (ARADDR),
    .ARPROT  (ARPROT),
    .ARVALID (ARVALID),
    .ARREADY (ARREADY),
    .RDATA   (RDATA),
    .RRESP   (RRESP),
    .RVALID  (RVALID),
    .RREADY  (RREADY)
);

// -------------------------------------------------------
// Task — apply reset
// -------------------------------------------------------
task apply_reset;
    begin
        HRESETn <= 1'b0;
        HSEL    <= 1'b0;
        HTRANS  <= 2'b00;
        HWRITE  <= 1'b0;
        HSIZE   <= 3'b010;
        HBURST  <= 3'b000;
        HADDR   <= 32'b0;
        HWDATA  <= 32'b0;
        AWREADY <= 1'b0;
        WREADY  <= 1'b0;
        BVALID  <= 1'b0;
        BRESP   <= 2'b00;
        ARREADY <= 1'b0;
        RVALID  <= 1'b0;
        RDATA   <= 32'b0;
        RRESP   <= 2'b00;
        repeat(4) @(posedge HCLK);
        HRESETn <= 1'b1;
        @(posedge HCLK);
    end
endtask

// -------------------------------------------------------
// Task — AHB address phase
// -------------------------------------------------------
task ahb_addr_phase;
    input [31:0] addr;
    input        write;
    begin
        HSEL   <= 1'b1;
        HADDR  <= addr;
        HTRANS <= 2'b10;    // NONSEQ
        HWRITE <= write;
        HSIZE  <= 3'b010;   // word
        HBURST <= 3'b000;   // SINGLE
        @(posedge HCLK);
    end
endtask

// -------------------------------------------------------
// Task — AHB data phase
// -------------------------------------------------------
task ahb_data_phase;
    input [31:0] wdata;
    begin
        HWDATA <= wdata;
        HTRANS <= 2'b00;   // IDLE — no new transfer
        HSEL   <= 1'b0;
        // wait until bridge releases HREADY
        wait(HREADY == 1'b1);
        @(posedge HCLK);
    end
endtask

// -------------------------------------------------------
// Task — AXI write slave (simple responder)
// -------------------------------------------------------
task axi_write_slave;
    input [1:0] resp;
    begin
        // Accept AW channel
        @(posedge HCLK);
        wait(AWVALID);
        AWREADY <= 1'b1;
        @(posedge HCLK);
        AWREADY <= 1'b0;

        // Accept W channel
        wait(WVALID);
        WREADY <= 1'b1;
        @(posedge HCLK);
        WREADY <= 1'b0;

        // Send write response
        wait(BREADY);
        BVALID <= 1'b1;
        BRESP  <= resp;
        @(posedge HCLK);
        BVALID <= 1'b0;
    end
endtask

// -------------------------------------------------------
// Task — AXI read slave (simple responder)
// -------------------------------------------------------
task axi_read_slave;
    input [31:0] rdata;
    input [1:0]  resp;
    begin
        wait(ARVALID);
        ARREADY <= 1'b1;
        @(posedge HCLK);
        ARREADY <= 1'b0;

        // Send read data
        wait(RREADY);
        RVALID <= 1'b1;
        RDATA  <= rdata;
        RRESP  <= resp;
        @(posedge HCLK);
        RVALID <= 1'b0;
    end
endtask

// -------------------------------------------------------
// Checker tasks
// -------------------------------------------------------
task check;
    input [255:0] test_name;
    input         pass;
    begin
        if (pass)
            $display("PASS: %s", test_name);
        else
            $display("FAIL: %s", test_name);
    end
endtask

// -------------------------------------------------------
// Waveform dump
// -------------------------------------------------------
initial begin
    $dumpfile("bridge.vcd");
    $dumpvars(0, tb_bridge_top);
end

// -------------------------------------------------------
// Main test sequence
// -------------------------------------------------------
initial begin
    apply_reset;
    $display("--- Reset done ---");

    // -------------------------------------------------
    // TEST 1 — Single AHB write
    // -------------------------------------------------
    $display("--- Test 1: AHB write 0xDEADBEEF to 0x1000 ---");
    fork
        begin
            ahb_addr_phase(32'h1000, 1'b1);
            ahb_data_phase(32'hDEADBEEF);
        end
        begin
            axi_write_slave(2'b00);
        end
    join

    // Wait for pipeline to settle
    wait(HREADY == 1'b1);
    @(posedge HCLK);
    check("Write: AWADDR correct", AWADDR == 32'h1000);
    check("Write: WDATA correct",  WDATA  == 32'hDEADBEEF);
    check("Write: WSTRB correct",  WSTRB  == 4'b1111);
    check("Write: HRESP is OKAY",  HRESP  == 2'b00);

    repeat(2) @(posedge HCLK);

    // -------------------------------------------------
    // TEST 2 — Single AHB read
    // -------------------------------------------------
    $display("--- Test 2: AHB read from 0x2000 ---");
    fork
        begin
            ahb_addr_phase(32'h2000, 1'b0);
            ahb_data_phase(32'h0);
        end
        begin
            axi_read_slave(32'hCAFEBABE, 2'b00);
        end
    join

    // Wait for HRDATA to propagate through all 3 pipeline stages
    wait(HREADY == 1'b1);
    @(posedge HCLK);
    @(posedge HCLK);
    @(posedge HCLK);
    @(posedge HCLK);
    check("Read: ARADDR correct",  ARADDR == 32'h2000);
    check("Read: HRDATA correct",  HRDATA == 32'hCAFEBABE);
    check("Read: HRESP is OKAY",   HRESP  == 2'b00);

    repeat(2) @(posedge HCLK);

    // -------------------------------------------------
    // TEST 3 — AXI SLVERR maps to AHB ERROR
    // -------------------------------------------------
    $display("--- Test 3: AXI SLVERR -> AHB ERROR ---");
    fork
        begin
            ahb_addr_phase(32'h3000, 1'b1);
            ahb_data_phase(32'hBADC0DE);
        end
        begin
            axi_write_slave(2'b10);   // SLVERR
        end
    join

    // Wait for 2-cycle ERROR sequence to appear
    wait(HRESP == 2'b01);
    @(posedge HCLK);
    check("Error: HRESP is ERROR", HRESP == 2'b01);

    $display("--- All tests complete ---");
    #50;
    $finish;
end
endmodule