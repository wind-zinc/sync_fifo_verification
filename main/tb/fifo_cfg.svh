`ifndef FIFO_CFG_SVH
`define FIFO_CFG_SVH

// ============================================================
// FIFO elaboration-time configuration.
//
// Default values are used when VCS is invoked without:
//
//   +define+FIFO_CFG_DATA_WIDTH=<value>
//   +define+FIFO_CFG_DEPTH=<value>
//
// The regression script overrides these two macros for every
// parameter configuration.
// ============================================================

`ifndef FIFO_CFG_DATA_WIDTH
    `define FIFO_CFG_DATA_WIDTH 8
`endif

`ifndef FIFO_CFG_DEPTH
    `define FIFO_CFG_DEPTH 10
`endif

`endif
