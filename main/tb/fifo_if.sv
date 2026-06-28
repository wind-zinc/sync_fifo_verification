`ifndef FIFO_IF_SV
`define FIFO_IF_SV

`timescale 1ns/1ps

interface fifo_if #(
    parameter int DATA_WIDTH = 8
)(
    input logic clk
);

    logic                  rst_n;
    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] din;

    logic [DATA_WIDTH-1:0] dout;
    logic                  full;
    logic                  empty;

    clocking drv_cb @(negedge clk);
        default input #1step output #1step;

        output rst_n;
        output wr_en;
        output rd_en;
        output din;

        input  dout;
        input  full;
        input  empty;
    endclocking

    clocking mon_pre_cb @(posedge clk);
        default input #1step;

        input rst_n;
        input wr_en;
        input rd_en;
        input din;
        input dout;
        input full;
        input empty;
    endclocking

    clocking mon_post_cb @(negedge clk);
        default input #1step;

        input rst_n;
        input wr_en;
        input rd_en;
        input din;
        input dout;
        input full;
        input empty;
    endclocking

    modport DUT (
        input  clk,
        input  rst_n,
        input  wr_en,
        input  rd_en,
        input  din,
        output dout,
        output full,
        output empty
    );

    modport DRIVER (
        input clk,
        clocking drv_cb
    );

    modport MONITOR (
        input clk,
        clocking mon_pre_cb,
        clocking mon_post_cb
    );

endinterface

`endif