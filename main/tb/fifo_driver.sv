`ifndef FIFO_DRIVER_SV
`define FIFO_DRIVER_SV

class fifo_driver extends uvm_driver #(fifo_transaction);

    `uvm_component_utils(fifo_driver)

    virtual fifo_if #(FIFO_DATA_WIDTH) vif;

    function new(string name = "fifo_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fifo_if#(FIFO_DATA_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for fifo_driver")
        end
    endfunction

    task drive_idle();
        vif.drv_cb.wr_en <= 1'b0;
        vif.drv_cb.rd_en <= 1'b0;
        vif.drv_cb.din   <= '0;
    endtask

    task drive_normal_item(fifo_transaction tr);
        vif.drv_cb.wr_en <= tr.wr_en;
        vif.drv_cb.rd_en <= tr.rd_en;
        vif.drv_cb.din   <= tr.din;
        `uvm_info("DRV", $sformatf("Drive normal item: wr_en=%0b rd_en=%0b din=0x%0h", tr.wr_en, tr.rd_en, tr.din), UVM_HIGH)
    endtask

    // Called at a drv_cb event. Reset is held for at least one cycle.
    task apply_reset(int unsigned requested_cycles);
        int unsigned actual_cycles;
        actual_cycles = (requested_cycles == 0) ? 1 : requested_cycles;

        vif.drv_cb.rst_n <= 1'b0;
        drive_idle();

        repeat (actual_cycles) begin
            @(vif.drv_cb);
            vif.drv_cb.rst_n <= 1'b0;
            drive_idle();
        end

        @(vif.drv_cb);
        vif.drv_cb.rst_n <= 1'b1;
        drive_idle();
    endtask

    task reset_dut();
        `uvm_info("DRV", "Start initial FIFO reset", UVM_LOW)
        @(vif.drv_cb);
        apply_reset(3);
        @(vif.drv_cb);
        `uvm_info("DRV", "Initial FIFO reset finished", UVM_LOW)
    endtask

    task run_phase(uvm_phase phase);
        fifo_transaction req;
        bit item_pending;

        reset_dut();
        item_pending = 1'b0;

        // Old version:
        //   Every request was a one-cycle normal read/write item.
        // New version:
        //   Dispatch NORMAL / IDLE / RESET transactions. A reset
        //   transaction completes only after reset has been released.
        forever begin
            @(vif.drv_cb);

            if (item_pending) begin
                seq_item_port.item_done();
                item_pending = 1'b0;
            end

            req = null;
            seq_item_port.try_next_item(req);

            if (req == null) begin
                drive_idle();
            end
            else begin
                case (req.op)
                    FIFO_OP_NORMAL: begin
                        drive_normal_item(req);
                        item_pending = 1'b1;
                    end

                    FIFO_OP_IDLE: begin
                        drive_idle();
                        item_pending = 1'b1;
                    end

                    FIFO_OP_RESET: begin
                        `uvm_info("DRV", $sformatf("Start runtime reset: cycles=%0d", req.reset_cycles), UVM_LOW)
                        apply_reset(req.reset_cycles);
                        `uvm_info("DRV", "Runtime reset finished", UVM_LOW)
                        seq_item_port.item_done();
                    end

                    default: begin
                        `uvm_error("DRV_BAD_OP", $sformatf("Unsupported FIFO operation value: %0d", req.op))
                        drive_idle();
                        seq_item_port.item_done();
                    end
                endcase
            end
        end
    endtask

endclass

`endif
