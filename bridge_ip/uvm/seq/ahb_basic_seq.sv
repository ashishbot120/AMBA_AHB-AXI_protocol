`include "uvm_macros.svh"
import uvm_pkg::*;
class ahb_basic_seq extends uvm_sequence #(ahb_transaction);
    `uvm_object_utils(ahb_basic_seq)

    function new(string name = "ahb_basic_seq");
        super.new(name);
    endfunction

    task body();
        ahb_transaction tr;

        // Test 1 — single write
        tr = ahb_transaction::type_id::create("tr");
        start_item(tr);
        if (!tr.randomize() with {
            addr  == 32'h1000; data == 32'hDEADBEEF;
            write == 1'b1; size == 3'b010; burst == 3'b000;
        }) `uvm_error("SEQ", "Randomization failed")
        finish_item(tr);

        // Test 2 — single read
        tr = ahb_transaction::type_id::create("tr");
        start_item(tr);
        if (!tr.randomize() with {
            addr == 32'h2000; write == 1'b0;
            size == 3'b010; burst == 3'b000;
        }) `uvm_error("SEQ", "Randomization failed")
        finish_item(tr);

        // Test 3 — write expected to receive SLVERR
        tr = ahb_transaction::type_id::create("tr");
        start_item(tr);
        if (!tr.randomize() with {
            addr == 32'h3000; data == 32'hBADC0DE;
            write == 1'b1; size == 3'b010; burst == 3'b000;
        }) `uvm_error("SEQ", "Randomization failed")
        finish_item(tr);

    endtask

endclass