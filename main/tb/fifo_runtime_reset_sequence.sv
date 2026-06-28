`ifndef FIFO_RUNTIME_RESET_SEQUENCE_SV
`define FIFO_RUNTIME_RESET_SEQUENCE_SV

class fifo_runtime_reset_sequence extends uvm_sequence #(fifo_transaction);

    `uvm_object_utils(fifo_runtime_reset_sequence)

    function new(string name = "fifo_runtime_reset_sequence");
        super.new(name);
    endfunction

    task send_normal(
        bit                          wr_en_value,
        bit                          rd_en_value,
        logic [FIFO_DATA_WIDTH-1:0]  data_value
    );
        fifo_transaction req;
        req = fifo_transaction::type_id::create("normal_req");
        start_item(req);
        req.op           = FIFO_OP_NORMAL;
        req.reset_cycles = 0;
        req.wr_en        = wr_en_value;
        req.rd_en        = rd_en_value;
        req.din          = data_value;
        finish_item(req);
    endtask

    task send_reset(int unsigned reset_length);
        fifo_transaction req;
        req = fifo_transaction::type_id::create("reset_req");
        start_item(req);
        req.op           = FIFO_OP_RESET;
        req.reset_cycles = reset_length;
        req.wr_en        = 1'b0;
        req.rd_en        = 1'b0;
        req.din          = '0;
        finish_item(req);
    endtask

    task body();
        int unsigned pre_reset_write_count;
        int unsigned post_reset_write_count;
        int unsigned i;

        pre_reset_write_count  = (FIFO_DEPTH < 4) ? FIFO_DEPTH : 4;
        post_reset_write_count = (FIFO_DEPTH < 3) ? FIFO_DEPTH : 3;

        // Pre-reset traffic.
        for (i = 0; i < pre_reset_write_count; i++) begin
            send_normal(1'b1, 1'b0, 8'hA0 + i);
        end

        if (pre_reset_write_count > 1) begin
            send_normal(1'b0, 1'b1, '0);
        end

        // Exercise active traffic immediately before reset.
        send_normal(1'b1, 1'b1, 8'h5A);

        // Runtime reset during active test execution.
        send_reset(3);

        // Post-reset empty read, then a fresh write/read sequence.
        send_normal(1'b0, 1'b1, '0);

        for (i = 0; i < post_reset_write_count; i++) begin
            send_normal(1'b1, 1'b0, 8'h30 + i);
        end

        for (i = 0; i < post_reset_write_count; i++) begin
            send_normal(1'b0, 1'b1, '0);
        end
    endtask

endclass

`endif
