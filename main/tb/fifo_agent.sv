`ifndef FIFO_AGENT_SV
`define FIFO_AGENT_SV

class fifo_agent extends uvm_agent;

    `uvm_component_utils(fifo_agent)

    // ============================================================
    // Old version:
    //
    // fifo_sequencer sequencer;
    // fifo_driver    driver;
    //
    // New version:
    //   Add monitor.
    // ============================================================

    fifo_sequencer sequencer;
    fifo_driver    driver;
    fifo_monitor   monitor;


    function new(
        string        name   = "fifo_agent",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ============================================================
    // build_phase
    // ============================================================

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Old version:
        //
        // sequencer = fifo_sequencer::type_id::create("sequencer", this);
        // driver    = fifo_driver   ::type_id::create("driver",    this);

        sequencer = fifo_sequencer::type_id::create("sequencer", this);
        driver    = fifo_driver   ::type_id::create("driver",    this);
        monitor   = fifo_monitor  ::type_id::create("monitor",   this);
    endfunction


    // ============================================================
    // connect_phase
    // ============================================================

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass

`endif
