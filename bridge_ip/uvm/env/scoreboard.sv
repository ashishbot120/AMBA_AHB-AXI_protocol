`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_axi)

class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_ahb #(ahb_transaction, scoreboard) ahb_imp;
    uvm_analysis_imp_axi #(axi_transaction, scoreboard) axi_imp;

    ahb_transaction ahb_q[$];
    axi_transaction axi_q[$];

    int pass_count;
    int fail_count;

    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        ahb_imp = new("ahb_imp", this);
        axi_imp = new("axi_imp", this);
    endfunction

    function void write_ahb(ahb_transaction tr);
        ahb_q.push_back(tr);
        try_match();
    endfunction

    function void write_axi(axi_transaction tr);
        axi_q.push_back(tr);
        try_match();
    endfunction

    function void try_match();
        ahb_transaction a;
        axi_transaction x;
        bit error_expected;
        bit match;

        if (ahb_q.size() == 0 || axi_q.size() == 0)
            return;

        a = ahb_q.pop_front();
        x = axi_q.pop_front();
        match = 1;

        if (a.write != x.write) begin
            `uvm_error("SCB", $sformatf(
                "Write/Read type mismatch: AHB write=%0b AXI write=%0b",
                a.write, x.write))
            match = 0;
        end

        if (a.addr !== x.addr) begin
            `uvm_error("SCB", $sformatf(
                "Address mismatch: AHB=0x%0h AXI=0x%0h", a.addr, x.addr))
            match = 0;
        end

        if (a.write) begin
            if (a.data !== x.data) begin
                `uvm_error("SCB", $sformatf(
                    "Write data mismatch: AHB=0x%0h AXI=0x%0h", a.data, x.data))
                match = 0;
            end
        end
        else begin
            if (a.rdata !== x.data) begin
                `uvm_error("SCB", $sformatf(
                    "Read data mismatch: AHB got=0x%0h AXI sent=0x%0h",
                    a.rdata, x.data))
                match = 0;
            end
        end

        error_expected = (x.resp != 2'b00);
        if (error_expected && a.resp != 2'b01) begin
            `uvm_error("SCB", $sformatf(
                "Expected HRESP=ERROR but got HRESP=%0b", a.resp))
            match = 0;
        end
        if (!error_expected && a.resp != 2'b00) begin
            `uvm_error("SCB", $sformatf(
                "Expected HRESP=OKAY but got HRESP=%0b", a.resp))
            match = 0;
        end

        if (match) begin
            pass_count++;
            `uvm_info("SCB", $sformatf("MATCH: %s", a.convert2string()), UVM_MEDIUM)
        end
        else
            fail_count++;
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf(
            "Scoreboard summary: %0d PASS, %0d FAIL", pass_count, fail_count),
            UVM_LOW)
    endfunction

endclass