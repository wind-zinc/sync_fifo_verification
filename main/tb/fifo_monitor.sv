`ifndef FIFO_MONITOR_SV
`define FIFO_MONITOR_SV

class fifo_monitor extends uvm_monitor;

    `uvm_component_utils(fifo_monitor)

    // ============================================================
    // Virtual interface
    // ============================================================

    virtual fifo_if #(FIFO_DATA_WIDTH) vif;


    // ============================================================
    // Analysis port
    // ------------------------------------------------------------
    // Monitor writes observed transaction to this port.
    //
    // Later:
    //
    // monitor.ap
    //      |
    //      +----> scoreboard.analysis_imp
    // ============================================================

    uvm_analysis_port #(fifo_transaction) ap;


    function new(
        string        name   = "fifo_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ============================================================
    // build_phase
    // ============================================================

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fifo_if#(FIFO_DATA_WIDTH))::get(
            this,
            "",
            "vif",
            vif
        )) begin
            `uvm_fatal(
                "NOVIF",
                "virtual interface must be set for fifo_monitor"
            )
        end

        ap = new("ap", this);
    endfunction


    // ============================================================
    // Sample pre-posedge state
    // ------------------------------------------------------------
    // mon_pre_cb uses:
    //
    //   clocking mon_pre_cb @(posedge clk);
    //       default input #1step;
    //   endclocking
    //
    // Therefore these values represent the state just before
    // current posedge.
    // ============================================================

    task sample_pre_state(fifo_transaction tr);

        tr.rst_n     = vif.mon_pre_cb.rst_n;

        tr.wr_en     = vif.mon_pre_cb.wr_en;
        tr.rd_en     = vif.mon_pre_cb.rd_en;
        tr.din       = vif.mon_pre_cb.din;

        tr.pre_full  = vif.mon_pre_cb.full;
        tr.pre_empty = vif.mon_pre_cb.empty;


        // DUT behavior:
        //
        // wr_fire = wr_en && !full;
        // rd_fire = rd_en && !empty;
        //
        // full/empty here must be pre-posedge values.
        tr.wr_fire = (tr.rst_n     === 1'b1) &&
                     (tr.wr_en     === 1'b1) &&
                     (tr.pre_full  === 1'b0);

        tr.rd_fire = (tr.rst_n      === 1'b1) &&
                     (tr.rd_en      === 1'b1) &&
                     (tr.pre_empty  === 1'b0);

    endtask


    // ============================================================
    // Sample post-posedge state
    // ------------------------------------------------------------
    // mon_post_cb samples just before following negedge.
    //
    // By this time:
    //   1. DUT has already processed the previous posedge.
    //   2. dout/full/empty have become stable.
    //   3. Driver has not yet changed next transaction inputs.
    // ============================================================

    task sample_post_state(fifo_transaction tr);

        tr.post_rst_n = vif.mon_post_cb.rst_n;

        tr.dout       = vif.mon_post_cb.dout;
        tr.post_full  = vif.mon_post_cb.full;
        tr.post_empty = vif.mon_post_cb.empty;

    endtask


    // ============================================================
    // run_phase
    // ============================================================

    task run_phase(uvm_phase phase);

        fifo_transaction tr;

        forever begin

            // Capture current operation before DUT processes it.
            @(vif.mon_pre_cb);

            tr = fifo_transaction::type_id::create("tr");

            sample_pre_state(tr);

            // Capture result of the same posedge operation.
            @(vif.mon_post_cb);

            sample_post_state(tr);

            // Send observed transaction to scoreboard.
            ap.write(tr);

            `uvm_info(
                "MON",
                $sformatf(
                    "Observed: rst_n=%0b wr_en=%0b rd_en=%0b din=0x%0h pre_full=%0b pre_empty=%0b wr_fire=%0b rd_fire=%0b dout=0x%0h post_full=%0b post_empty=%0b",
                    tr.rst_n,
                    tr.wr_en,
                    tr.rd_en,
                    tr.din,
                    tr.pre_full,
                    tr.pre_empty,
                    tr.wr_fire,
                    tr.rd_fire,
                    tr.dout,
                    tr.post_full,
                    tr.post_empty
                ),
                UVM_HIGH
            )

        end

    endtask

endclass

`endif
