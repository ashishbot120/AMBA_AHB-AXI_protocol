class axi_transaction extends uvm_sequence_item;
    `uvm_object_utils(axi_transaction)

    logic [31:0] addr;
    logic [31:0] data;
    logic [3:0]  wstrb;
    logic        write;
    logic [1:0]  resp;

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("addr=0x%0h data=0x%0h wstrb=%0b write=%0b resp=%0b",
                          addr, data, wstrb, write, resp);
    endfunction

endclass