`ifndef FIFO_RUNTIME_RESET_TEST_SV
`define FIFO_RUNTIME_RESET_TEST_SV

class fifo_runtime_reset_test extends fifo_base_test;

    `uvm_component_utils(fifo_runtime_reset_test)

    function new(string name = "fifo_runtime_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // fifo_base_test builds env. Do not call super.run_phase(),
    // because this test replaces the random sequence with a directed
    // reset-during-traffic sequence.
    task run_phase(uvm_phase phase);
        fifo_runtime_reset_sequence seq;

        phase.raise_objection(this);
        seq = fifo_runtime_reset_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #100ns;
        phase.drop_objection(this);
    endtask

endclass

`endif
