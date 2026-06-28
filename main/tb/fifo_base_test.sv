`ifndef FIFO_BASE_TEST_SV
`define FIFO_BASE_TEST_SV

class fifo_base_test extends uvm_test;

    `uvm_component_utils(fifo_base_test)

    fifo_env env;

    function new(string name = "fifo_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);

        fifo_random_sequence seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "fifo_base_test started", UVM_LOW)

        seq = fifo_random_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        // Give the last driven transaction some time to propagate.
        #100ns;

        `uvm_info("TEST", "fifo_base_test finished", UVM_LOW)

        phase.drop_objection(this);

    endtask

endclass

`endif