`ifndef FIFO_ENV_SV
`define FIFO_ENV_SV

class fifo_env extends uvm_env;

    `uvm_component_utils(fifo_env)

    // ============================================================
    // Environment components.
    // ============================================================

    fifo_agent      agent;
    fifo_scoreboard scoreboard;

    // Old version:
    //
    // fifo_agent      agent;
    // fifo_scoreboard scoreboard;
    //
    // New component:
    fifo_coverage    coverage;


    function new(
        string        name   = "fifo_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ============================================================
    // build_phase
    // ============================================================

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent      = fifo_agent     ::type_id::create("agent",      this);
        scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);

        // New version:
        coverage   = fifo_coverage  ::type_id::create("coverage",   this);
    endfunction


    // ============================================================
    // connect_phase
    //
    // Monitor broadcasts every observed transaction to:
    //
    //   1. scoreboard : checks FIFO data correctness
    //   2. coverage   : collects functional coverage
    // ============================================================

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agent.monitor.ap.connect(scoreboard.analysis_imp);

        // New connection:
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction

endclass

`endif
