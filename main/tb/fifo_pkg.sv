`ifndef FIFO_PKG_SV
`define FIFO_PKG_SV

`include "fifo_cfg.svh"

package fifo_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int FIFO_DATA_WIDTH = `FIFO_CFG_DATA_WIDTH;
    parameter int FIFO_DEPTH      = `FIFO_CFG_DEPTH;

    `include "fifo_transaction.sv"
    `include "fifo_sequence.sv"

    // Old version:
    // `include "fifo_sequence.sv"
    // `include "fifo_sequencer.sv"
    // New version: runtime reset sequence is added before tests.
    `include "fifo_runtime_reset_sequence.sv"

    `include "fifo_sequencer.sv"
    `include "fifo_driver.sv"
    `include "fifo_monitor.sv"
    `include "fifo_scoreboard.sv"
    `include "fifo_coverage.sv"
    `include "fifo_agent.sv"
    `include "fifo_env.sv"
    `include "fifo_base_test.sv"

    // New directed test.
    `include "fifo_runtime_reset_test.sv"

endpackage

`endif
