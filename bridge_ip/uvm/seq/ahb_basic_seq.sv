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
        tr.addr  = 32'h1000;
        tr.data  = 32'hDEADBEEF;
        tr.write = 1'b1;
        tr.size  = 3'b010;
        tr.burst = 3'b000;
        finish_item(tr);

        // Test 2 — single read
        tr = ahb_transaction::type_id::create("tr");
        start_item(tr);
        tr.addr  = 32'h2000;
        tr.data  = 32'h0;
        tr.write = 1'b0;
        tr.size  = 3'b010;
        tr.burst = 3'b000;
        finish_item(tr);

        // Test 3 — write expected to receive SLVERR
        tr = ahb_transaction::type_id::create("tr");
        start_item(tr);
        tr.addr  = 32'h3000;
        tr.data  = 32'hBADC0DE;
        tr.write = 1'b1;
        tr.size  = 3'b010;
        tr.burst = 3'b000;
        finish_item(tr);

    endtask

endclass