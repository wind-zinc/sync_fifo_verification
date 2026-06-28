`ifndef FIFO_SEQUENCER_SV
`define FIFO_SEQUENCER_SV

class fifo_sequencer extends uvm_sequencer #(fifo_transaction);

    `uvm_component_utils(fifo_sequencer)

    function new(string name = "fifo_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif