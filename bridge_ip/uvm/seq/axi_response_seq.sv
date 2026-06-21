class axi_response_seq extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_response_seq)

    // Which request number (1-based, per channel) should get SLVERR.
    // -1 means never inject an error.
    int error_on_txn = -1;
    int txn_count = 0;

    function new(string name = "axi_response_seq");
        super.new(name);
    endfunction

    task body();
        forever begin
            axi_transaction tr;
            txn_count++;

            tr = axi_transaction::type_id::create("tr");
            start_item(tr);

            tr.data = 32'hCAFEBABE;        // only used by read_responder
            tr.resp = (txn_count == error_on_txn) ? 2'b10 : 2'b00;

            finish_item(tr);
        end
    endtask

endclass