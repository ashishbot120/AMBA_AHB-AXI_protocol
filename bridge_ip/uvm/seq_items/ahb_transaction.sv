// ahb_transaction.sv
`include "uvm_macros.svh"
import uvm_pkg::*;
class ahb_transaction extends uvm_sequence_item;
    `uvm_object_utils(ahb_transaction)

    // Transaction fields
    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic        write;   // 1=write, 0=read
    rand logic [2:0]  size;
    rand logic [2:0]  burst;
         logic [31:0] rdata;   // read data back (not randomised)
         logic [1:0]  resp;    // HRESP back (not randomised)

    // Constraints
    constraint valid_size  { size  inside {3'b000, 3'b001, 3'b010}; }
    constraint valid_burst { burst inside {3'b000, 3'b011, 3'b101}; }
// WITH THIS (plain ASCII ->):
    constraint addr_align  {
        (size == 3'b010) -> (addr[1:0] == 2'b00);
        (size == 3'b001) -> (addr[0]   == 1'b0);
    }

    function new(string name = "ahb_transaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("addr=0x%h data=0x%h write=%0b resp=%0b",
                          addr, data, write, resp);
    endfunction

endclass