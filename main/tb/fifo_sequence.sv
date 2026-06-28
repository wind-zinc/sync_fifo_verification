`ifndef FIFO_SEQUENCE_SV
`define FIFO_SEQUENCE_SV

class fifo_random_sequence extends uvm_sequence #(fifo_transaction);

    `uvm_object_utils(fifo_random_sequence)

    function new(string name = "fifo_random_sequence");
        super.new(name);
    endfunction

    task body();

        fifo_transaction req;

        repeat (300) begin

            req = fifo_transaction::type_id::create("req");

            start_item(req);

            if (!req.randomize()) begin
                `uvm_fatal("RAND_FAIL", "fifo_transaction randomize failed")
            end

            finish_item(req);

        end

    endtask

endclass

`endif