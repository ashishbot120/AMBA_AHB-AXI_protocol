`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_axi)

class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_ahb #(ahb_transaction, scoreboard) ahb_imp;
    uvm_analysis_imp_axi #(axi_transaction, scoreboard) axi_imp;

    // Separate queues for reads and writes
    ahb_transaction ahb_wr_q[$];   // AHB write transactions
    ahb_transaction ahb_rd_q[$];   // AHB read transactions
    axi_transaction axi_wr_q[$];   // AXI write transactions
    axi_transaction axi_rd_q[$];   // AXI read transactions

    int pass_count;
    int fail_count;

    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        ahb_imp = new("ahb_imp", this);
        axi_imp = new("axi_imp", this);
        pass_count = 0;
        fail_count = 0;
    endfunction

    function void write_ahb(ahb_transaction tr);
        if (tr.write)
            ahb_wr_q.push_back(tr);
        else
            ahb_rd_q.push_back(tr);
        try_match();
    endfunction

    function void write_axi(axi_transaction tr);
        if (tr.write)
            axi_wr_q.push_back(tr);
        else
            axi_rd_q.push_back(tr);
        try_match();
    endfunction

    function void try_match();
        // Try to match a write pair
        if (ahb_wr_q.size() > 0 && axi_wr_q.size() > 0)
            match_write(ahb_wr_q.pop_front(), axi_wr_q.pop_front());

        // Try to match a read pair
        if (ahb_rd_q.size() > 0 && axi_rd_q.size() > 0)
            match_read(ahb_rd_q.pop_front(), axi_rd_q.pop_front());
    endfunction

    function void match_write(ahb_transaction a, axi_transaction x);
        bit match = 1;

        if (a.addr !== x.addr) begin
            `uvm_error("SCB", $sformatf(
                "WRITE Addr mismatch: AHB=0x%0h AXI=0x%0h", a.addr, x.addr))
            match = 0;
        end

        if (a.data !== x.data) begin
            `uvm_error("SCB", $sformatf(
                "WRITE Data mismatch: AHB=0x%0h AXI=0x%0h", a.data, x.data))
            match = 0;
        end

        // Check error response mapping
        if (x.resp != 2'b00 && a.resp !== 2'b01) begin
            `uvm_error("SCB", $sformatf(
                "WRITE Expected HRESP=ERROR but got HRESP=%0b", a.resp))
            match = 0;
        end
        if (x.resp == 2'b00 && a.resp !== 2'b00) begin
            `uvm_error("SCB", $sformatf(
                "WRITE Expected HRESP=OKAY but got HRESP=%0b", a.resp))
            match = 0;
        end

        if (match) begin
            pass_count++;
            `uvm_info("SCB", $sformatf(
                "WRITE MATCH: addr=0x%0h data=0x%0h resp=%0b",
                a.addr, a.data, a.resp), UVM_MEDIUM)
        end
        else
            fail_count++;
    endfunction

    function void match_read(ahb_transaction a, axi_transaction x);
        bit match = 1;

        if (a.addr !== x.addr) begin
            `uvm_error("SCB", $sformatf(
                "READ Addr mismatch: AHB=0x%0h AXI=0x%0h", a.addr, x.addr))
            match = 0;
        end

        if (a.rdata !== x.data) begin
            `uvm_error("SCB", $sformatf(
                "READ Data mismatch: AHB got=0x%0h AXI sent=0x%0h",
                a.rdata, x.data))
            match = 0;
        end

        if (x.resp != 2'b00 && a.resp !== 2'b01) begin
            `uvm_error("SCB", $sformatf(
                "READ Expected HRESP=ERROR but got HRESP=%0b", a.resp))
            match = 0;
        end
        if (x.resp == 2'b00 && a.resp !== 2'b00) begin
            `uvm_error("SCB", $sformatf(
                "READ Expected HRESP=OKAY but got HRESP=%0b", a.resp))
            match = 0;
        end

        if (match) begin
            pass_count++;
            `uvm_info("SCB", $sformatf(
                "READ MATCH: addr=0x%0h rdata=0x%0h resp=%0b",
                a.addr, a.rdata, a.resp), UVM_MEDIUM)
        end
        else
            fail_count++;
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf(
            "Scoreboard summary: %0d PASS, %0d FAIL",
            pass_count, fail_count), UVM_LOW)

        if (ahb_wr_q.size() > 0)
            `uvm_warning("SCB", $sformatf(
                "%0d unmatched AHB WRITE transactions remaining", ahb_wr_q.size()))
        if (ahb_rd_q.size() > 0)
            `uvm_warning("SCB", $sformatf(
                "%0d unmatched AHB READ transactions remaining", ahb_rd_q.size()))
        if (axi_wr_q.size() > 0)
            `uvm_warning("SCB", $sformatf(
                "%0d unmatched AXI WRITE transactions remaining", axi_wr_q.size()))
        if (axi_rd_q.size() > 0)
            `uvm_warning("SCB", $sformatf(
                "%0d unmatched AXI READ transactions remaining", axi_rd_q.size()))
    endfunction

endclass