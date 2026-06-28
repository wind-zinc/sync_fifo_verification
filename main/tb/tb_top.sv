`timescale 1ns/1ps
`include "fifo_cfg.svh"

module tb_top;

    import uvm_pkg::*;
    import fifo_pkg::*;
    `include "uvm_macros.svh"

    parameter int DATA_WIDTH = `FIFO_CFG_DATA_WIDTH;
    parameter int DEPTH      = `FIFO_CFG_DEPTH;

    logic clk;

    fifo_if #(.DATA_WIDTH(DATA_WIDTH)) vif (.clk(clk));

    sync_fifo_any_depth #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (DEPTH)
    ) dut (
        .clk   (clk),
        .rst_n (vif.rst_n),
        .wr_en (vif.wr_en),
        .din   (vif.din),
        .full  (vif.full),
        .rd_en (vif.rd_en),
        .dout  (vif.dout),
        .empty (vif.empty)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        vif.rst_n = 1'b0;
        vif.wr_en = 1'b0;
        vif.rd_en = 1'b0;
        vif.din   = '0;
    end

    initial begin
        if (!$test$plusargs("NO_FSDB")) begin
            $fsdbDumpfile("sync_fifo_uvm.fsdb");
            $fsdbDumpvars(0, tb_top);
        end
    end

    initial begin
        uvm_config_db#(virtual fifo_if#(DATA_WIDTH))::set(null, "uvm_test_top.env.agent.*", "vif", vif);
        run_test();
    end

    // Old version: these two assertions were always active in tb_top.
    // New version: full bound SVA owns the checks when enabled; keep
    // basic assertions active during baseline non-SVA regression.
`ifndef FIFO_ENABLE_SVA

    assert property (@(posedge clk) disable iff (!vif.rst_n) !(vif.full && vif.empty))
    else $error("FIFO protocol error: full and empty are both high");

    assert property (@(posedge clk) !vif.rst_n |=> vif.empty && !vif.full)
    else $error("FIFO reset error: after reset, empty should be high and full should be low");

`endif

endmodule
