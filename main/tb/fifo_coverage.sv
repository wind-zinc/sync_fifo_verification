`ifndef FIFO_COVERAGE_SV
`define FIFO_COVERAGE_SV

class fifo_coverage extends uvm_subscriber #(fifo_transaction);

    `uvm_component_utils(fifo_coverage)

    // ============================================================
    // Request type observed before current posedge.
    //
    // Bit order:
    //   {wr_en, rd_en}
    // ============================================================

    typedef enum bit [1:0] {
        REQ_IDLE       = 2'b00,
        REQ_READ_ONLY  = 2'b01,
        REQ_WRITE_ONLY = 2'b10,
        REQ_READ_WRITE = 2'b11
    } request_kind_e;


    // ============================================================
    // Operation really accepted by FIFO at current posedge.
    //
    // Bit order:
    //   {wr_fire, rd_fire}
    // ============================================================

    typedef enum bit [1:0] {
        ACC_NONE       = 2'b00,
        ACC_READ_ONLY  = 2'b01,
        ACC_WRITE_ONLY = 2'b10,
        ACC_READ_WRITE = 2'b11
    } accept_kind_e;


    // ============================================================
    // Mutually exclusive pre-operation occupancy categories.
    //
    // Current FIFO depth is 10, so all five categories are usable.
    //
    // For very small depths such as DEPTH=1 or DEPTH=2, some
    // semantic categories naturally overlap. The priority here is:
    //
    //   EMPTY -> FULL -> ONE -> ALMOST_FULL -> MIDDLE
    // ============================================================

    typedef enum bit [2:0] {
        OCC_EMPTY       = 3'd0,
        OCC_ONE         = 3'd1,
        OCC_MIDDLE      = 3'd2,
        OCC_ALMOST_FULL = 3'd3,
        OCC_FULL        = 3'd4
    } occupancy_kind_e;


    // ============================================================
    // Internal reference state for coverage only.
    //
    // This is not a second scoreboard. It only tracks:
    //
    //   1. Current occupancy category
    //   2. Write-address wrap event
    //   3. Read-address wrap event
    // ============================================================

    int unsigned model_occupancy;
    int unsigned model_wr_addr;
    int unsigned model_rd_addr;


    // ============================================================
    // Variables sampled by covergroup.
    // ============================================================

    request_kind_e   cov_request_kind;
    accept_kind_e    cov_accept_kind;
    occupancy_kind_e cov_pre_occupancy_kind;

    bit cov_empty_read_req;
    bit cov_full_write_req;
    bit cov_empty_write_req;
    bit cov_full_read_req;

    bit cov_rw_at_empty;
    bit cov_rw_at_middle;
    bit cov_rw_at_full;
    bit cov_rw_both_accepted;

    bit cov_empty_to_nonempty;
    bit cov_one_to_empty;
    bit cov_almost_full_to_full;
    bit cov_full_to_nonfull;

    bit cov_wr_wrap;
    bit cov_rd_wrap;


    // ============================================================
    // Useful report counters.
    // ============================================================

    int unsigned sampled_cycle_count;
    int unsigned reset_sample_count;

    int unsigned empty_read_req_count;
    int unsigned full_write_req_count;
    int unsigned empty_write_req_count;
    int unsigned full_read_req_count;

    int unsigned rw_empty_count;
    int unsigned rw_middle_count;
    int unsigned rw_full_count;
    int unsigned rw_both_accepted_count;

    int unsigned empty_to_nonempty_count;
    int unsigned one_to_empty_count;
    int unsigned almost_full_to_full_count;
    int unsigned full_to_nonfull_count;

    int unsigned wr_wrap_count;
    int unsigned rd_wrap_count;


    // ============================================================
    // Functional coverage definition.
    // ============================================================

    covergroup fifo_cg;

        option.per_instance = 1;
        option.name         = "fifo_functional_coverage";

        cp_request_kind : coverpoint cov_request_kind {
            bins idle       = {REQ_IDLE};
            bins read_only  = {REQ_READ_ONLY};
            bins write_only = {REQ_WRITE_ONLY};
            bins read_write = {REQ_READ_WRITE};
        }

        cp_accept_kind : coverpoint cov_accept_kind {
            bins none        = {ACC_NONE};
            bins read_only   = {ACC_READ_ONLY};
            bins write_only  = {ACC_WRITE_ONLY};
            bins read_write  = {ACC_READ_WRITE};
        }

        cp_pre_occupancy_kind : coverpoint cov_pre_occupancy_kind {
            bins empty       = {OCC_EMPTY};
            bins one         = {OCC_ONE};
            bins middle      = {OCC_MIDDLE};
            bins almost_full = {OCC_ALMOST_FULL};
            bins full        = {OCC_FULL};
        }

        // Request operation crossed with FIFO state before posedge.
        x_request_by_occupancy : cross cp_request_kind,
                                       cp_pre_occupancy_kind;

        // Boundary request coverage.
        cp_empty_read_req : coverpoint cov_empty_read_req {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_full_write_req : coverpoint cov_full_write_req {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_empty_write_req : coverpoint cov_empty_write_req {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_full_read_req : coverpoint cov_full_read_req {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        // Simultaneous read/write request under three boundary states.
        cp_rw_at_empty : coverpoint cov_rw_at_empty {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_rw_at_middle : coverpoint cov_rw_at_middle {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_rw_at_full : coverpoint cov_rw_at_full {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_rw_both_accepted : coverpoint cov_rw_both_accepted {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        // Important occupancy boundary transitions.
        cp_empty_to_nonempty : coverpoint cov_empty_to_nonempty {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_one_to_empty : coverpoint cov_one_to_empty {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_almost_full_to_full : coverpoint cov_almost_full_to_full {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_full_to_nonfull : coverpoint cov_full_to_nonfull {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        // Logical write/read address wrap coverage.
        cp_wr_wrap : coverpoint cov_wr_wrap {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

        cp_rd_wrap : coverpoint cov_rd_wrap {
            bins hit = {1'b1};
            ignore_bins not_hit = {1'b0};
        }

    endgroup


    function new(
        string        name   = "fifo_coverage",
        uvm_component parent = null
    );
        super.new(name, parent);

        fifo_cg = new();
    endfunction


    // ============================================================
    // Component initialization.
    // ============================================================

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (FIFO_DEPTH < 1) begin
            `uvm_fatal(
                "BAD_DEPTH",
                "FIFO_DEPTH must be greater than or equal to 1"
            )
        end

        model_occupancy = 0;
        model_wr_addr   = 0;
        model_rd_addr   = 0;

        sampled_cycle_count = 0;
        reset_sample_count  = 0;

        empty_read_req_count  = 0;
        full_write_req_count  = 0;
        empty_write_req_count = 0;
        full_read_req_count   = 0;

        rw_empty_count         = 0;
        rw_middle_count        = 0;
        rw_full_count          = 0;
        rw_both_accepted_count = 0;

        empty_to_nonempty_count  = 0;
        one_to_empty_count        = 0;
        almost_full_to_full_count = 0;
        full_to_nonfull_count     = 0;

        wr_wrap_count = 0;
        rd_wrap_count = 0;
    endfunction


    // ============================================================
    // Convert raw request bits into request-kind enum.
    // ============================================================

    function request_kind_e get_request_kind(
        bit wr_en,
        bit rd_en
    );

        case ({wr_en, rd_en})
            2'b00:  return REQ_IDLE;
            2'b01:  return REQ_READ_ONLY;
            2'b10:  return REQ_WRITE_ONLY;
            default:return REQ_READ_WRITE;
        endcase

    endfunction


    // ============================================================
    // Convert accepted-operation bits into accepted-kind enum.
    // ============================================================

    function accept_kind_e get_accept_kind(
        bit wr_fire,
        bit rd_fire
    );

        case ({wr_fire, rd_fire})
            2'b00:  return ACC_NONE;
            2'b01:  return ACC_READ_ONLY;
            2'b10:  return ACC_WRITE_ONLY;
            default:return ACC_READ_WRITE;
        endcase

    endfunction


    // ============================================================
    // Convert numeric occupancy into a coverage category.
    // ============================================================

    function occupancy_kind_e get_occupancy_kind(
        int unsigned occupancy
    );

        if (occupancy == 0) begin
            return OCC_EMPTY;
        end
        else if (occupancy == FIFO_DEPTH) begin
            return OCC_FULL;
        end
        else if (occupancy == 1) begin
            return OCC_ONE;
        end
        else if (occupancy == (FIFO_DEPTH - 1)) begin
            return OCC_ALMOST_FULL;
        end
        else begin
            return OCC_MIDDLE;
        end

    endfunction


    // ============================================================
    // Receive one transaction from monitor.
    //
    // uvm_subscriber already owns analysis_export. Therefore env
    // only needs:
    //
    //   agent.monitor.ap.connect(coverage.analysis_export);
    // ============================================================

    function void write(fifo_transaction tr);

        int unsigned pre_occupancy;
        int unsigned post_occupancy;


        // ========================================================
        // Reset handling.
        // --------------------------------------------------------
        // Reset clears the internal coverage model but is not
        // sampled into normal operation coverage.
        // ========================================================

        if ((tr.rst_n !== 1'b1) || (tr.post_rst_n !== 1'b1)) begin
            model_occupancy = 0;
            model_wr_addr   = 0;
            model_rd_addr   = 0;

            reset_sample_count++;

            return;
        end


        // ========================================================
        // Capture state before current transaction.
        // ========================================================

        pre_occupancy = model_occupancy;

        cov_request_kind       = get_request_kind(tr.wr_en, tr.rd_en);
        cov_accept_kind        = get_accept_kind(tr.wr_fire, tr.rd_fire);
        cov_pre_occupancy_kind = get_occupancy_kind(pre_occupancy);


        // ========================================================
        // Boundary request flags.
        // ========================================================

        cov_empty_read_req  = (pre_occupancy == 0)          && tr.rd_en;
        cov_full_write_req  = (pre_occupancy == FIFO_DEPTH) && tr.wr_en;
        cov_empty_write_req = (pre_occupancy == 0)          && tr.wr_en;
        cov_full_read_req   = (pre_occupancy == FIFO_DEPTH) && tr.rd_en;


        // ========================================================
        // Simultaneous request flags.
        // ========================================================

        cov_rw_at_empty  = tr.wr_en && tr.rd_en &&
                           (pre_occupancy == 0);

        cov_rw_at_middle = tr.wr_en && tr.rd_en &&
                           (pre_occupancy > 0) &&
                           (pre_occupancy < FIFO_DEPTH);

        cov_rw_at_full   = tr.wr_en && tr.rd_en &&
                           (pre_occupancy == FIFO_DEPTH);

        cov_rw_both_accepted = tr.wr_fire && tr.rd_fire;


        // ========================================================
        // Update occupancy using accepted operations only.
        // ========================================================

        post_occupancy = pre_occupancy;

        if (tr.rd_fire && (post_occupancy > 0)) begin
            post_occupancy--;
        end

        if (tr.wr_fire && (post_occupancy < FIFO_DEPTH)) begin
            post_occupancy++;
        end

        model_occupancy = post_occupancy;


        // ========================================================
        // Boundary transition flags.
        // ========================================================

        cov_empty_to_nonempty  = (pre_occupancy == 0) &&
                                 (post_occupancy > 0);

        cov_one_to_empty       = (pre_occupancy == 1) &&
                                 (post_occupancy == 0);

        cov_almost_full_to_full = (pre_occupancy == (FIFO_DEPTH - 1)) &&
                                  (post_occupancy == FIFO_DEPTH);

        cov_full_to_nonfull     = (pre_occupancy == FIFO_DEPTH) &&
                                  (post_occupancy < FIFO_DEPTH);


        // ========================================================
        // Detect logical address wrap before address update.
        // ========================================================

        cov_wr_wrap = tr.wr_fire &&
                      (model_wr_addr == (FIFO_DEPTH - 1));

        cov_rd_wrap = tr.rd_fire &&
                      (model_rd_addr == (FIFO_DEPTH - 1));


        // ========================================================
        // Update logical write/read addresses.
        // ========================================================

        if (tr.wr_fire) begin
            if (model_wr_addr == (FIFO_DEPTH - 1)) begin
                model_wr_addr = 0;
            end
            else begin
                model_wr_addr++;
            end
        end

        if (tr.rd_fire) begin
            if (model_rd_addr == (FIFO_DEPTH - 1)) begin
                model_rd_addr = 0;
            end
            else begin
                model_rd_addr++;
            end
        end


        // ========================================================
        // Update report counters.
        // ========================================================

        sampled_cycle_count++;

        if (cov_empty_read_req) begin
            empty_read_req_count++;
        end

        if (cov_full_write_req) begin
            full_write_req_count++;
        end

        if (cov_empty_write_req) begin
            empty_write_req_count++;
        end

        if (cov_full_read_req) begin
            full_read_req_count++;
        end

        if (cov_rw_at_empty) begin
            rw_empty_count++;
        end

        if (cov_rw_at_middle) begin
            rw_middle_count++;
        end

        if (cov_rw_at_full) begin
            rw_full_count++;
        end

        if (cov_rw_both_accepted) begin
            rw_both_accepted_count++;
        end

        if (cov_empty_to_nonempty) begin
            empty_to_nonempty_count++;
        end

        if (cov_one_to_empty) begin
            one_to_empty_count++;
        end

        if (cov_almost_full_to_full) begin
            almost_full_to_full_count++;
        end

        if (cov_full_to_nonfull) begin
            full_to_nonfull_count++;
        end

        if (cov_wr_wrap) begin
            wr_wrap_count++;
        end

        if (cov_rd_wrap) begin
            rd_wrap_count++;
        end


        // ========================================================
        // Sample all coverpoints once for this clock cycle.
        // ========================================================

        fifo_cg.sample();

    endfunction


    // ============================================================
    // Final functional coverage report.
    // ============================================================

    function void report_phase(uvm_phase phase);

        `uvm_info(
            "COV_REPORT",
            $sformatf(
                "============================================================\nFIFO Functional Coverage Summary\n------------------------------------------------------------\nNon-reset samples          : %0d\nReset samples              : %0d\nFunctional coverage        : %0.2f%%\nEmpty + read request       : %0d\nFull + write request       : %0d\nEmpty + write request      : %0d\nFull + read request        : %0d\nRW request at empty        : %0d\nRW request in middle       : %0d\nRW request at full         : %0d\nRW both accepted           : %0d\nEmpty to non-empty         : %0d\nOne item to empty          : %0d\nAlmost-full to full        : %0d\nFull to non-full           : %0d\nWrite-address wraps        : %0d\nRead-address wraps         : %0d\n============================================================",
                sampled_cycle_count,
                reset_sample_count,
                fifo_cg.get_inst_coverage(),
                empty_read_req_count,
                full_write_req_count,
                empty_write_req_count,
                full_read_req_count,
                rw_empty_count,
                rw_middle_count,
                rw_full_count,
                rw_both_accepted_count,
                empty_to_nonempty_count,
                one_to_empty_count,
                almost_full_to_full_count,
                full_to_nonfull_count,
                wr_wrap_count,
                rd_wrap_count
            ),
            UVM_LOW
        )

    endfunction

endclass

`endif
