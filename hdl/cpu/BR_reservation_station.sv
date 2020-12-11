import rv32i_types::*;

module BR_reservation_station #(parameter rob_size = 16, 
                                parameter rob_index_bits = 4, 
                                parameter rs_size = 16, 
                                parameter rs_index_bits = 4,
                                parameter alu_rs_size = 8,
                                parameter alu_rs_index_bits = 3,
                                parameter ls_rs_size = 8,
                                parameter ls_rs_index_bits = 3
                                )
(
    input clk,
    input rst,
    input logic [31:0] opA_br_dec, opB_br_dec, PC_next_reg_dec, imm_br_dec,
    input logic v1_br_dec, v2_br_dec, v3_br_dec,
    input branch_funct3_t cmpop_dec,
    input logic [rob_size-1:0] done_rob,
    input logic [31:0] data_rob[rob_size-1:0],
    input logic load_brrs_dec,
    input logic [31:0] PC_dec,
    input logic [31:0] PC_iq_head,
    input logic iq_empty,
    output logic [31:0] pc_brrs,
    output logic flush,
    output logic brrs_full,
    output logic halt,
    output logic [31:0] pc_curr_brrs
);

typedef struct packed {
    logic [31:0]    rs1_robidx;
    logic           v1;
    logic [31:0]    rs2_robidx;
    logic           v2;
    logic [31:0]    PC_next_reg;
    logic           v3;
    logic [31:0]    imm;
    logic [31:0]    PC;
    branch_funct3_t cmpop;
} BR_RS;
BR_RS br_rs, br_rs_next;

branch_funct3_t cmpop;
rv32i_word in_A,in_B;
logic br_en, brrs_full_next;
 
cmp CMP(
		 .cmpop,
		 .in_A,
		 .in_B,
		 .br_en
);


assign cmpop = br_rs.cmpop;
assign in_A = br_rs.rs1_robidx;
assign in_B = br_rs.rs2_robidx;

assign flush = (PC_iq_head != pc_brrs || iq_empty) && brrs_full && br_rs.v1 && br_rs.v2 && br_rs.v3;
assign pc_brrs = br_en ? br_rs.PC_next_reg + br_rs.imm : br_rs.PC + 4;
assign pc_curr_brrs = br_rs.PC;

//update
always_comb begin
    br_rs_next = br_rs;
    brrs_full_next = brrs_full;
    if (~brrs_full && load_brrs_dec) begin
        br_rs_next = {opA_br_dec,v1_br_dec,opB_br_dec,v2_br_dec,PC_next_reg_dec,v3_br_dec,imm_br_dec,PC_dec,cmpop_dec};
        brrs_full_next = 1;
    end
    else if(brrs_full) begin
        if(~br_rs.v1 && done_rob[br_rs.rs1_robidx[rob_index_bits-1:0]])begin
            br_rs_next.v1 = 1;
            br_rs_next.rs1_robidx = data_rob[br_rs.rs1_robidx[rob_index_bits-1:0]];
        end
        if(~br_rs.v2 && done_rob[br_rs.rs2_robidx[rob_index_bits-1:0]])begin
            br_rs_next.v2 = 1;
            br_rs_next.rs2_robidx = data_rob[br_rs.rs2_robidx[rob_index_bits-1:0]];
        end
        if(~br_rs.v3 && done_rob[br_rs.PC_next_reg[rob_index_bits-1:0]])begin
            br_rs_next.v3 = 1;
            br_rs_next.PC_next_reg = data_rob[br_rs.PC_next_reg[rob_index_bits-1:0]];
        end
        if (br_rs.v1 && br_rs.v2 && br_rs.v3)  
            brrs_full_next = 0;
    end
end


always_ff @(posedge clk) 
begin
    if (rst) begin
        br_rs <= '0;
        brrs_full <= '0;
        halt <= 0;
    end
    else begin
        br_rs <= br_rs_next;
        brrs_full <= brrs_full_next;
        if(flush && (pc_brrs == br_rs.PC))begin 
            $display("Halt = 1 Initiated");
            halt <= 1;
        end
    end
end

endmodule : BR_reservation_station