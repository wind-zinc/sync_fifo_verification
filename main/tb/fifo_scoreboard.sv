`ifndef FIFO_SCOREBOARD_SV
`define FIFO_SCOREBOARD_SV

class fifo_scoreboard extends uvm_component;

    `uvm_component_utils(fifo_scoreboard)

    // ============================================================
    // Analysis implementation port
    // ------------------------------------------------------------
    // This port receives transactions from fifo_monitor.
    // ============================================================

    uvm_analysis_imp #(fifo_transaction, fifo_scoreboard) analysis_imp;


    // ============================================================
    // Reference FIFO model
    // ------------------------------------------------------------
    // This queue is intentionally simple.
    //
    // It does not duplicate DUT pointer/count/address logic.
    // It only models FIFO behavior:
    //
    // write -> push_back
    // read  -> pop_front
    // ============================================================

    logic [FIFO_DATA_WIDTH-1:0] model_queue[$];


    // ============================================================
    // Statistics
    // ============================================================

    int unsigned write_count;
    int unsigned read_count;
    int unsigned compare_count;
    int unsigned error_count;
    int unsigned reset_count;

    bit          in_reset;


    function new(
        string        name   = "fifo_scoreboard",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ============================================================
    // build_phase
    // ============================================================

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        analysis_imp = new("analysis_imp", this);

        write_count   = 0;
        read_count    = 0;
        compare_count = 0;
        error_count   = 0;
        reset_count   = 0;
        in_reset      = 1'b0;
    endfunction


    // ============================================================
    // Check full/empty status after current transaction
    // ============================================================

    function void check_post_status(fifo_transaction tr);

        bit expected_empty;
        bit expected_full;

        expected_empty = (model_queue.size() == 0);
        expected_full  = (model_queue.size() == FIFO_DEPTH);

        if (tr.post_empty !== expected_empty) begin
            error_count++;

            `uvm_error(
                "SB_EMPTY",
                $sformatf(
                    "empty mismatch: expected=%0b actual=%0b model_size=%0d",
                    expected_empty,
                    tr.post_empty,
                    model_queue.size()
                )
            )
        end

        if (tr.post_full !== expected_full) begin
            error_count++;

            `uvm_error(
                "SB_FULL",
                $sformatf(
                    "full mismatch: expected=%0b actual=%0b model_size=%0d",
                    expected_full,
                    tr.post_full,
                    model_queue.size()
                )
            )
        end

    endfunction


    // ============================================================
    // write
    // ------------------------------------------------------------
    // This function is called automatically whenever monitor runs:
    //
    //   ap.write(tr);
    //
    // No explicit task call is needed in scoreboard.
    // ============================================================

    function void write(fifo_transaction tr);

        logic [FIFO_DATA_WIDTH-1:0] expected_data;


        // ========================================================
        // Reset handling
        // --------------------------------------------------------
        // Reset clears DUT storage, pointers and used_cnt.
        // Therefore reference queue must also be cleared.
        // ========================================================

        if ((tr.rst_n === 1'b0) || (tr.post_rst_n === 1'b0)) begin

            if (!in_reset) begin
                reset_count++;

                `uvm_info(
                    "SB",
                    "Reset observed: reference FIFO queue cleared",
                    UVM_LOW
                )
            end

            in_reset = 1'b1;

            model_queue.delete();

            // Reset-state check.
            if ((tr.post_empty !== 1'b1) || (tr.post_full !== 1'b0)) begin
                error_count++;

                `uvm_error(
                    "SB_RESET",
                    $sformatf(
                        "Reset status mismatch: expected empty=1 full=0, actual empty=%0b full=%0b",
                        tr.post_empty,
                        tr.post_full
                    )
                )
            end

            return;
        end


        // Reset has just been released.
        if (in_reset) begin
            `uvm_info(
                "SB",
                "Reset release observed",
                UVM_LOW
            )
        end

        in_reset = 1'b0;


        // ========================================================
        // Read handling
        // --------------------------------------------------------
        // Read must happen before write in reference-model update.
        //
        // For simultaneous read/write in normal non-empty/non-full
        // state:
        //
        //   pop old FIFO head
        //   push new write data to FIFO tail
        //
        // This matches FIFO behavior.
        // ========================================================

        if (tr.rd_fire) begin

            read_count++;

            if (model_queue.size() == 0) begin
                error_count++;

                `uvm_error(
                    "SB_RD_EMPTY",
                    "DUT accepted a read, but reference FIFO is empty"
                )
            end
            else begin
                expected_data = model_queue.pop_front();

                compare_count++;

                if (tr.dout !== expected_data) begin
                    error_count++;

                    `uvm_error(
                        "SB_DATA",
                        $sformatf(
                            "Read data mismatch: expected=0x%0h actual=0x%0h",
                            expected_data,
                            tr.dout
                        )
                    )
                end
                else begin
                    `uvm_info(
                        "SB",
                        $sformatf(
                            "Read data matched: 0x%0h",
                            tr.dout
                        ),
                        UVM_HIGH
                    )
                end
            end

        end


        // ========================================================
        // Write handling
        // ========================================================

        if (tr.wr_fire) begin
            model_queue.push_back(tr.din);

            write_count++;
        end


        // ========================================================
        // Post-operation full/empty check
        // ========================================================

        check_post_status(tr);


        `uvm_info(
            "SB",
            $sformatf(
                "Model update: wr_fire=%0b rd_fire=%0b queue_size=%0d",
                tr.wr_fire,
                tr.rd_fire,
                model_queue.size()
            ),
            UVM_HIGH
        )

    endfunction


    // ============================================================
    // report_phase
    // ------------------------------------------------------------
    // Print summary after test finishes.
    // ============================================================

    function void report_phase(uvm_phase phase);

        `uvm_info(
            "SB_REPORT",
            $sformatf(
                "\n ============================================================\n FIFO Scoreboard Summary\n ------------------------------------------------------------\n Reset count       : %0d\n Accepted writes   : %0d\n Accepted reads    : %0d\n Data comparisons  : %0d\n Scoreboard errors : %0d\n Pending queue data: %0d\n ============================================================",
                reset_count,
                write_count,
                read_count,
                compare_count,
                error_count,
                model_queue.size()
            ),
            UVM_LOW
        )

    endfunction

endclass

`endif
