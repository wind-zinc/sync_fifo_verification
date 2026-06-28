// my original systemverilog testbench without UVM, including random stimulus and 2 assertion.
`timescale 1ns/1ps

module tb_sync_fifo;

    logic       clk;
    logic       rst_n;
    logic       wr_en;
    logic		rd_en;
    logic [7:0] din;
    wire  [7:0] dout;
    wire		full;
    wire		empty;

    // DUT
    sync_fifo_any_depth dut (.*);

    // 10 ns clock period: clk toggles every 5 ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Randomize input on the falling edge to avoid racing with DUT
    // sampling on the rising edge.
    always @(negedge clk) begin
        if (~rst_n) begin
            din <= 8'b0;
            wr_en <= 1'b0;
            rd_en <= 1'b0;
	end
        else begin
            din <= $urandom_range(8'b0, 8'b1111_1111);
            wr_en <= $urandom_range(0,1);
            rd_en <= $urandom_range(0,1);
	end
    end

    initial begin
        din    = 8'b0;
        rst_n  = 1'b0;

        // Initial synchronous reset
        repeat (3) @(posedge clk);
        rst_n <= 1'b1;

        // Run with random input
        repeat (300) @(posedge clk);

        // One reset in the middle of simulation
        rst_n <= 1'b0;
        repeat (3) @(posedge clk);
        rst_n <= 1'b1;

        // Continue running with random input
        repeat (300) @(posedge clk);

        $finish;
    end
	
	assert property (
    @(posedge clk)
    disable iff (!rst_n)
    !(full && empty)
	);

	assert property (
    @(posedge clk)
    !rst_n |=> empty && !full
	);
	
    // FSDB waveform for Verdi
    initial begin
        $fsdbDumpfile("sync_fifo.fsdb");
        $fsdbDumpvars(0, tb_sync_fifo);
    end

endmodule
