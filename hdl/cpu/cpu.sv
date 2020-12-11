import rv32i_types::*;

module cpu #(parameter rob_size = 16, 
            parameter rob_index_bits = 4, 
            parameter rs_size = 16, 
            parameter rs_index_bits = 4,
            parameter alu_rs_size = 8,
            parameter alu_rs_index_bits = 3,
            parameter ls_rs_size = 8,
            parameter ls_rs_index_bits = 3,
            parameter iq_size = 16,
            parameter iq_index_bit = 4
            )(
    input clk,
    input rst,

    // Memory Signals to I-Cache
    input logic mem_i_resp,
    input logic [31:0] mem_i_rdata,
    output logic mem_i_read,
    output logic [31:0] mem_i_address,
    
    // Memory Signals to D-Cache
    input logic mem_d_resp,
    input logic [31:0] mem_d_rdata,
    output logic mem_d_read,
    output logic mem_d_write,
    output logic [31:0] mem_d_wdata,
    output logic [3:0] mem_d_byte_enable,
    output logic [31:0] mem_d_address //(least 2-bit are zero-padded)

);

// FETCH
logic [31:0] pc_brrs;
logic flush;
logic flush_iq_fetch;
logic [31:0] PC;
logic load_iq_fetch;
logic iq_really_full;
logic iq_empty;

// INSTRUCTION QUEUE
logic full_dec; //ROB or RS is full
logic load_dec_iq;//iq is not empty; entry at head is ready to be dcoded
logic [31:0] instruction_iq_head; //iq entry at head
logic [31:0] PC_iq_head;

// DECODE
logic [31:0] opA_dec, opB_dec, opA_br_dec, opB_br_dec;
logic v1_dec, v2_dec, v1_br_dec, v2_br_dec, v3_br_dec;
logic [31:0] PC_next_reg_dec;

alu_ops aluop_dec;
logic load_alurs_dec;
logic [alu_rs_index_bits-1:0] widx_alurs;
logic alurs_full;

logic [31:0] imm_br_dec;
branch_funct3_t cmpop_dec;
logic load_brrs_dec;
logic brrs_full;

logic load_rob_dec;
logic [31:0] rsidx_rs; //sent by decoder (Reservation Station index) -> assign
logic rob_really_full;

// LS_RS
logic [31:0] imm_dec; //opA_dec and opB_dec same as above
mem_ops memop_dec;
logic load_lsrs_dec;
logic [rs_index_bits-1:0] widx_lsrs;
logic lsrs_really_full;

logic [4:0] regidx_dec;
logic [4:0] rs1_dec, rs2_dec;
logic [31:0] rs1_out, rs2_out;
logic rs1_v, rs2_v;

// BR_RS
logic [rob_size-1:0] done_rob;
logic [31:0] data_rob[rob_size-1:0];
logic halt;
logic [31:0] PC_dec;
logic [31:0] pc_curr_brrs;

// ROB
logic [4:0] regidx_wb; //will specify which register that will be updated in regfile. 
logic load_reg_wb, load_reg_dec;
logic [31:0] regdata_wb, regdata_dec;// the new data we want to load our register with
logic [rob_index_bits-1:0] rob_head;

// ALU RS
logic [31:0] data_alurs [alu_rs_size-1:0];
logic [alu_rs_size-1:0] done_alurs; //end of this cycle result is available if done_alurs[i] = 1
logic [ls_rs_size-1:0] done_lsrs;
logic [31:0] data_lsrs[ls_rs_size-1:0];

// COMPLETE RS
logic  [rs_size-1:0] done_rs; //comes from the reservation station indication all bits that have updated
logic  [31:0] data_rs [rs_size-1:0];

assign done_rs[alu_rs_size-1:0] = done_alurs;
assign data_rs[alu_rs_size-1:0] = data_alurs;
assign done_rs[alu_rs_size + ls_rs_size-1:alu_rs_size] = done_lsrs;
assign data_rs[alu_rs_size + ls_rs_size-1:alu_rs_size] = data_lsrs;

fetch fetch (
    .*
);

instruction_queue #(.iq_size(iq_size), .iq_index_bit(iq_index_bit)) instruction_queue (
    .*
);

decoder #(.rob_size(rob_size), 
          .rob_index_bits(rob_index_bits), 
          .rs_size(rs_size), 
          .rs_index_bits(rs_index_bits),
          .alu_rs_size(alu_rs_size),
          .alu_rs_index_bits(alu_rs_index_bits),
          .ls_rs_size(ls_rs_size),
          .ls_rs_index_bits(ls_rs_index_bits)
) decoder 
(
    .*
);

BR_reservation_station #(.rob_size(rob_size), 
                         .rob_index_bits(rob_index_bits), 
                         .rs_size(rs_size), 
                         .rs_index_bits(rs_index_bits),
                         .alu_rs_size(alu_rs_size),
                         .alu_rs_index_bits(alu_rs_index_bits),
                         .ls_rs_size(ls_rs_size),
                         .ls_rs_index_bits(ls_rs_index_bits)
) BR_reservation_station
(
    .*
);

ALU_reservation_station #(.alu_rs_size(alu_rs_size),
                          .alu_rs_index_bits(alu_rs_index_bits),
                          .rob_size(rob_size),
                          .rob_index_bits(rob_index_bits)
) ALU_reservation_station
(
    .*
);


LDST_reservation_station #( .rs_index_bits(rs_index_bits),
                            .alu_rs_size(alu_rs_size),
                            .ls_rs_size(ls_rs_size),
                            .ls_rs_index_bits(ls_rs_index_bits),
                            .rob_size(rob_size),
                            .rob_index_bits(rob_index_bits)
) LDST_reservation_station
(
    .*
);

reorder_buffer #(.rob_size(rob_size), 
                 .rob_index_bits(rob_index_bits), 
                 .rs_size(rs_size), 
                 .rs_index_bits(rs_index_bits)
) reorder_buffer
(
    .*
);

regfile  #(.rob_index_bits(rob_index_bits)) regfile
(
    .*
);

endmodule : cpu

