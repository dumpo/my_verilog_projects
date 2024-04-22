import uvm_pkg::*;
`include "uvm_macros.svh"
`include "interface.sv"    ;
`include "uvm_classes.sv"  ;

module testbench ();

  initial begin
          `uvm_info("testbench","hello uvm!",UVM_NONE)
  end
 
endmodule