`ifndef FIFO_TRANSACTION_SV
`define FIFO_TRANSACTION_SV

// Runtime-reset extension: normal random traffic stays FIFO_OP_NORMAL.
typedef enum bit [1:0] {
    FIFO_OP_NORMAL = 2'b00,
    FIFO_OP_IDLE   = 2'b01,
    FIFO_OP_RESET  = 2'b10
} fifo_op_e;

class fifo_transaction extends uvm_sequence_item;

    rand bit                       wr_en;
    rand bit                       rd_en;
    rand bit [FIFO_DATA_WIDTH-1:0] din;

    // Old version:
    //   The transaction only contained wr_en, rd_en, and din.
    // New version:
    //   op/reset_cycles allow a directed sequence to request reset
    //   through the ordinary sequencer-driver path.
    fifo_op_e                      op;
    int unsigned                   reset_cycles;

    logic                         rst_n;
    logic                         post_rst_n;
    logic [FIFO_DATA_WIDTH-1:0]   dout;
    logic                         pre_full;
    logic                         pre_empty;
    logic                         post_full;
    logic                         post_empty;
    bit                           wr_fire;
    bit                           rd_fire;

    `uvm_object_utils_begin(fifo_transaction)
        `uvm_field_int(wr_en,        UVM_ALL_ON)
        `uvm_field_int(rd_en,        UVM_ALL_ON)
        `uvm_field_int(din,          UVM_ALL_ON)
        `uvm_field_enum(fifo_op_e, op, UVM_ALL_ON)
        `uvm_field_int(reset_cycles, UVM_ALL_ON)
        `uvm_field_int(rst_n,        UVM_ALL_ON)
        `uvm_field_int(post_rst_n,   UVM_ALL_ON)
        `uvm_field_int(dout,         UVM_ALL_ON)
        `uvm_field_int(pre_full,     UVM_ALL_ON)
        `uvm_field_int(pre_empty,    UVM_ALL_ON)
        `uvm_field_int(post_full,    UVM_ALL_ON)
        `uvm_field_int(post_empty,   UVM_ALL_ON)
        `uvm_field_int(wr_fire,      UVM_ALL_ON)
        `uvm_field_int(rd_fire,      UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "fifo_transaction");
        super.new(name);
        op           = FIFO_OP_NORMAL;
        reset_cycles = 3;
    endfunction

endclass

`endif
