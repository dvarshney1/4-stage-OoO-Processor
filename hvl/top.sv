module mp4_tb;

// Change frequency for accurate timing
`define FREQUENCY_MHZ 100.0
`define FREQUENCY (`FREQUENCY_MHZ * 1000000)
`define PERIOD_NS (1000000000/`FREQUENCY)
`define PERIOD_CLK (`PERIOD_NS / 2)

`timescale 1ns/1ps
// `timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;
bit check_equal;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = dut.cpu.regfile.load_reg_wb; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = dut.cpu.fetch.halt && dut.cpu.ALU_reservation_station.alurs_empty && dut.cpu.LDST_reservation_station.lsrs_empty && dut.cpu.reorder_buffer.rob_empty;   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:*/
assign rvfi.inst = dut.cpu.decoder.instruction_iq_head;
assign rvfi.trap = dut.cpu.decoder.trap;

// (dut.dut.cpu.regfile.data[18] == 32'd) &&
//         (dut.dut.cpu.regfile.data[19] == 32'd) &&
//         (dut.dut.cpu.regfile.data[20] == 32'd) &&
//         (dut.dut.cpu.regfile.data[21] == 32'd) &&
//         (dut.dut.cpu.regfile.data[22] == 32'd) &&
//         (dut.dut.cpu.regfile.data[23] == 32'd) &&
//         (dut.dut.cpu.regfile.data[24] == 32'd) &&
//         (dut.dut.cpu.regfile.data[25] == 32'd) &&
//         (dut.dut.cpu.regfile.data[26] == 32'd) &&
//         (dut.dut.cpu.regfile.data[27] == 32'd) &&
//         (dut.dut.cpu.regfile.data[28] == 32'd) &&
//         (dut.dut.cpu.regfile.data[29] == 32'd) &&
//         (dut.dut.cpu.regfile.data[30] == 32'd) &&
//         (dut.dut.cpu.regfile.data[31] == 32'd)

always_ff @(posedge itf.clk) begin
    if ((dut.cpu.regfile.data[0] == 32'd0) &&
        (dut.cpu.regfile.data[1] == 32'd4936) &&
        (dut.cpu.regfile.data[2] == 32'd20) &&
        (dut.cpu.regfile.data[3] == 32'd149674) &&
        (dut.cpu.regfile.data[4] == 32'd16740476) &&
        (dut.cpu.regfile.data[5] == 32'd3171472) &&
        (dut.cpu.regfile.data[6] == 32'd0) &&
        (dut.cpu.regfile.data[7] == 32'd0) &&
        (dut.cpu.regfile.data[8] == 32'd0) &&
        (dut.cpu.regfile.data[9] == 32'd0) &&
        (dut.cpu.regfile.data[10] == 32'd2660) &&
        (dut.cpu.regfile.data[11] == 32'd0) &&
        (dut.cpu.regfile.data[12] == 32'd0) &&
        (dut.cpu.regfile.data[13] == 32'd0) &&
        (dut.cpu.regfile.data[14] == 32'd0) &&
        (dut.cpu.regfile.data[15] == 32'd3540) &&
        (dut.cpu.regfile.data[16] == 32'd1636) &&
        (dut.cpu.regfile.data[17] == 32'd1688)
        ) begin
            check_equal = 1'b1;
            $display($time);
        end
end

/*Regfile:*/
// assign rvfi.rs1_addr = dut.cpu.regfile.rs1_dec;
// assign rvfi.rs2_addr = dut.cpu.regfile.rs2_dec;
// assign rvfi.rs1_rdata = dut.cpu.regfile.data[rvfi.rs1_addr];
// assign rvfi.rs2_rdata = dut.cpu.regfile.data[rvfi.rs2_addr];
// assign rvfi.load_regfile = dut.cpu.regfile.load_reg_wb;
assign rvfi.rd_addr = dut.cpu.regfile.regidx_wb;
assign rvfi.rd_wdata = dut.cpu.regfile.regdata_wb;

/*PC:*/
// assign rvfi.pc_rdata = 
// assign rvfi.pc_wdata =

/*Memory:*/
// assign rvfi.mem_addr  = dut.pmem_address;
// assign rvfi.mem_rmask = dut.inst_read ? 4'hf : dut.mem_d_byte_enable;
// assign rvfi.mem_wmask = dut.data_write ? dut.mem_d_byte_enable : 4'h0;
// assign rvfi.mem_rdata = dut.pmem_rdata;
// assign rvfi.mem_wdata = dut.pmem_wdata;

/* Please refer to rvfi_itf.sv for more information. */


/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk            (itf.clk),
    .rst            (itf.rst),
    .pmem_rdata     (itf.mem_rdata),
    .pmem_wdata     (itf.mem_wdata),
    .pmem_address   (itf.mem_addr),
    .pmem_read      (itf.mem_read),
    .pmem_write     (itf.mem_write),
    .pmem_resp      (itf.mem_resp)
);

    assign itf.inst_read = dut.inst_read;
    assign itf.inst_addr = dut.inst_addr;
    assign itf.data_read = dut.data_read;
    assign itf.data_write = dut.data_write;
    assign itf.data_addr = dut.data_addr;
    assign itf.data_wdata = dut.data_wdata;
    assign itf.data_mbe = dut.data_mbe;

    assign itf.inst_rdata = dut.inst_rdata ;
    assign itf.inst_resp = dut.inst_resp ;
    assign itf.data_rdata = dut.data_rdata ;
    assign itf.data_resp = dut.data_resp;

    // assign dut.inst_rdata  = itf.inst_rdata;
    // assign dut.inst_resp  = itf.inst_resp;
    // assign dut.data_rdata  = itf.data_rdata;
    // assign dut.data_resp = itf.data_resp;

/***************************** End Instantiation *****************************/

endmodule
