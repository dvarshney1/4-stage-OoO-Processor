import rv32i_types::*;
// Change frequency for accurate timing
`define FREQUENCY_MHZ 100.0
`define FREQUENCY (`FREQUENCY_MHZ * 1000000)
`define PERIOD_NS (1000000000/`FREQUENCY)
`define PERIOD_CLK (`PERIOD_NS / 2)

`timescale 1ns/1ps



module decoder #(parameter rob_size = 16, 
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

    /*ALU RS, LDST RS, BR RS*/
    output logic [31:0] opA_dec, opB_dec, opA_br_dec, opB_br_dec,
    output logic v1_dec, v2_dec, v1_br_dec, v2_br_dec, v3_br_dec,
    output logic [31:0] PC_next_reg_dec,
    output logic [31:0] PC_dec,
    
    /*ALU RS*/  
    output alu_ops aluop_dec,
    output logic load_alurs_dec,
    input logic [alu_rs_index_bits-1:0] widx_alurs,
    input logic alurs_full,

    /* BR RS port */
    output logic [31:0] imm_br_dec,
    output branch_funct3_t cmpop_dec,
    output logic load_brrs_dec,
    input logic brrs_full,

    /*ROB*/
    output logic load_rob_dec,
    output logic [31:0] rsidx_rs, //sent by decoder (Reservation Station index) -> assign
    input logic rob_really_full,

    /*LDST RS*/
    output logic [31:0] imm_dec, //opA_dec and opB_dec same as above
    output mem_ops memop_dec,
    output logic load_lsrs_dec,
    input logic [rs_index_bits-1:0] widx_lsrs,
    input logic lsrs_really_full,

    /* Regfile*/
    output [4:0] regidx_dec,
    output [4:0] rs1_dec, rs2_dec,
    input logic [31:0] rs1_out, rs2_out,
    input logic rs1_v, rs2_v,

    //iq port
    input logic [31:0] instruction_iq_head,
    input logic [31:0] PC_iq_head,
    input logic load_dec_iq,
    output logic full_dec // -> assign

);

logic [31:0] data;
logic [2:0] funct3;
logic [6:0] funct7;
rv32i_opcode opcode;
logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] u_imm;
logic [31:0] j_imm;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;
logic trap;

logic current_cycle_has_branch, current_cycle_branch; 
logic [31:0] total_branches;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign data = instruction_iq_head;
assign funct3 = data[14:12];
assign funct7 = data[31:25];
assign opcode = rv32i_opcode'(data[6:0]);
assign i_imm = {{21{data[31]}}, data[30:20]};
assign s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign u_imm = {data[31:12], 12'h000};
assign j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign rs1 = data[19:15];
assign rs2 = data[24:20];
assign rd = data[11:7];


assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign regidx_dec = rd; 
assign rs1_dec = rs1;
assign rs2_dec = rs2;
assign PC_dec = PC_iq_head;

function void set_defaults();
  opA_dec = '0;
  opB_dec = '0;
  opA_br_dec = '0;
  opB_br_dec = '0;
  PC_next_reg_dec = '0;
  imm_dec = '0;
  imm_br_dec = '0;
  v1_dec = '0;
  v2_dec  = '0;
  v1_br_dec = '0;
  v2_br_dec = '0; 
  v3_br_dec = '0;
  aluop_dec = alu_add;
  cmpop_dec = beq;
  load_brrs_dec = '0;
  load_alurs_dec = '0;
  load_rob_dec = '0;
  rsidx_rs = '0; //sent by decoder (Reservation Station index) 
  memop_dec = mem_lw;
  load_lsrs_dec = '0;
  full_dec = '0;
  trap = '0;
  current_cycle_has_branch = '0;
endfunction: set_defaults


// always_ff @(posedge clk) begin
//   if(full_dec) 
//     $display("In decoder", $time, instruction_iq_head);
// end

always_comb begin : decode_instructions
/**Based on opcode, forward relevant stuff to ROB, reservation station (alu_rs, ldst_rs) etc. **/
/** Get back to BR, JAL, JALR later **/
    set_defaults();
    if(load_dec_iq && ~brrs_full) begin
      unique case (opcode)
          /* Require ALU_Reservation_Station */
          op_lui: begin //puts uimm in a reg ; pc<=pc+4  
                      opA_dec =  '0;
                      opB_dec =  u_imm;
                      v1_dec = 1;
                      v2_dec = 1;
                      aluop_dec = alu_add;
                      rsidx_rs = widx_alurs;
                      current_cycle_has_branch = 0;
                      if(~rob_really_full && ~alurs_full) begin
                        load_alurs_dec=1;
                        load_rob_dec=1;
                      end
                      else
                        full_dec = 1;

                      /* TODO: set PC = PC + 4*/

                  end
          op_auipc:   begin  //puts uimm + pc in a reg ; pc<=pc+4
                          opA_dec =  PC_iq_head;
                          opB_dec =  u_imm;
                          v1_dec = 1;
                          v2_dec = 1;
                          aluop_dec = alu_add;
                          rsidx_rs = widx_alurs;
                          current_cycle_has_branch = 0;
                          if(~rob_really_full && ~alurs_full) begin
                            load_alurs_dec=1;
                            load_rob_dec=1;
                          end
                          else
                            full_dec = 1;

                          /* TODO: set PC = PC + 4*/

                      end
          op_imm: begin  //op(reg,imm) ; pc<=pc+4
                      opA_dec =  rs1_out;
                      opB_dec =  i_imm;
                      v1_dec = rs1_v;
                      v2_dec = 1;
                      current_cycle_has_branch = 0;
                      unique case (arith_funct3)
                        add: aluop_dec = alu_add;
                        sll: aluop_dec = alu_sll;
                        slt: aluop_dec = alu_slt;
                        sltu: aluop_dec = alu_sltu;
                        axor:  aluop_dec = alu_xor;
                        sr:begin //check bit30 for logical/arithmetic
                            if(funct7[5])  aluop_dec = alu_sra;
                            else           aluop_dec = alu_srl;
                        end
                        aor:  aluop_dec = alu_or;
                        aand: aluop_dec = alu_and;
                        default: aluop_dec = alu_add;
                      endcase
                      rsidx_rs = widx_alurs;
                      if(~rob_really_full && ~alurs_full) begin
                        load_alurs_dec=1;
                        load_rob_dec=1;
                      end
                      else
                        full_dec = 1;
                      

                      /* TODO: set PC = PC + 4*/

                  end
          op_reg: begin //op(reg,reg) ; pc<=pc+4
                      opA_dec =  rs1_out;
                      opB_dec =  rs2_out;
                      v1_dec = rs1_v;
                      v2_dec = rs2_v;
                      current_cycle_has_branch = 0;
                      unique case (arith_funct3)
                        add: begin
                            if(funct7[5]) aluop_dec = alu_sub;
                            else aluop_dec = alu_add;
                        end
                        sll: aluop_dec = alu_sll;
                        slt: aluop_dec = alu_slt;
                        sltu: aluop_dec = alu_sltu;
                        axor:  aluop_dec = alu_xor;
                        sr:begin //check bit30 for logical/arithmetic
                            if(funct7[5])  aluop_dec = alu_sra;
                            else           aluop_dec = alu_srl;
                        end
                        aor:  aluop_dec = alu_or;
                        aand: aluop_dec = alu_and;
                        default: aluop_dec = alu_add;
                      endcase
                      rsidx_rs = widx_alurs;
                      if(~rob_really_full && ~alurs_full) begin
                        load_alurs_dec=1;
                        load_rob_dec=1;
                      end
                      else
                        full_dec = 1;

                      /* TODO: set PC = PC + 4*/
                      
                  end 

          /* Require LDRS_Reservation_Station */
          op_load:begin//rd <- M[rs1 + i_imm]; pc <= pc+4
              opA_dec =  rs1_out;
              v1_dec = rs1_v;
              imm_dec = i_imm;
              current_cycle_has_branch = 0;
              unique case (load_funct3)
                  lw: memop_dec = mem_lw;
                  lh: memop_dec = mem_lh;
                  lhu: memop_dec = mem_lhu;
                  lb: memop_dec = mem_lb;
                  lbu: memop_dec = mem_lbu;
                  default:;
              endcase
              rsidx_rs = widx_lsrs + alu_rs_size;
              if(~rob_really_full && ~lsrs_really_full) begin
                  load_lsrs_dec=1;
                  load_rob_dec=1;
              end
              else
                  full_dec = 1;

              /* TODO: set PC = PC + 4*/
          end     

          op_store:begin //M[rs1 + s_imm] <- rd; PC <= PC+4 
              opA_dec =  rs1_out;
              opB_dec = rs2_out;
              v1_dec = rs1_v;
              v2_dec = rs2_v;
              imm_dec = s_imm;
              current_cycle_has_branch = 0;
              unique case (store_funct3)
                  sw: memop_dec = mem_sw;
                  sh: memop_dec = mem_sh;
                  sb: memop_dec = mem_sb;
                  default:;
              endcase
              // rsidx_rs = widx_lsrs + alu_rs_size;
              if(~lsrs_really_full) begin
                  load_lsrs_dec=1;
                  // load_rob_dec=1;
              end
              else
                  full_dec = 1;

              /* TODO: set PC = PC + 4*/
          end   
          
          op_jal: begin //reg<= pc+4 ; pc<=pc+j_imm
                  //reg <= pc+4
                  opA_dec =  PC_iq_head;
                  opB_dec =  32'd4;
                  v1_dec = 1;
                  v2_dec = 1;
                  aluop_dec = alu_add;
                  rsidx_rs = widx_alurs;

                  // pc<=pc+j_imm
                  opA_br_dec = 0;
                  opB_br_dec = 0;
                  PC_next_reg_dec = PC_iq_head;
                  imm_br_dec = j_imm;
                  v1_br_dec = 1;
                  v2_br_dec = 1;
                  v3_br_dec = 1;
                  cmpop_dec = beq;

                  current_cycle_has_branch = 1;

                  if(~rob_really_full && ~alurs_full) begin
                    load_alurs_dec=1;
                    load_rob_dec=1;
                    load_brrs_dec = 1;
                  end
                  else
                    full_dec = 1;

                  /* TODO: set PC = PC + j_imm*/

          end 
          op_jalr: begin //reg<= pc+4 ; pc<=reg+i_imm
                  //reg <= pc+4
                  opA_dec =  PC_iq_head;
                  opB_dec =  32'd4;
                  v1_dec = 1;
                  v2_dec = 1;
                  aluop_dec = alu_add;
                  rsidx_rs = widx_alurs;

                  // pc<=reg+i_imm
                  opA_br_dec = 0;
                  opB_br_dec = 0;
                  PC_next_reg_dec = rs1_out;
                  imm_br_dec = i_imm;
                  v1_br_dec = 1;
                  v2_br_dec = 1;
                  v3_br_dec = rs1_v;
                  cmpop_dec = beq;

                  current_cycle_has_branch = 1;

                  if(~rob_really_full && ~alurs_full) begin
                    load_alurs_dec=1;
                    load_rob_dec=1;
                    load_brrs_dec = 1;
                  end
                  else
                    full_dec = 1;

                  /* TODO: set PC = PC + j_imm*/
          end

          op_br: begin  //pc <- pc + (br_en ? b_imm : 4) (br_en = cmp(reg,reg))
                  opA_br_dec = rs1_out;
                  opB_br_dec = rs2_out;
                  PC_next_reg_dec = PC_iq_head;
                  imm_br_dec = b_imm;
                  v1_br_dec = rs1_v;
                  v2_br_dec = rs2_v;
                  v3_br_dec = 1;
                  cmpop_dec = branch_funct3;

                  current_cycle_has_branch = 1;

                  // if(~rob_really_full && ~alurs_full) begin
                    // load_alurs_dec=1;
                    // load_rob_dec=1;
                    load_brrs_dec = 1;
                  // end
                  // else
                    // full_dec = 1;

                  /* TODO: set PC = output of op_br*/
          end
          default: begin 
            current_cycle_has_branch = 0;
            $display("Incorrect Opcode Selected");
            trap = 1;
          end
    endcase
    end
    else if (brrs_full) begin //allows to stall till brnach is resolved (change later)
      full_dec = 1;
    end
end

always_ff @(posedge clk) 
begin
  if (rst) begin
    total_branches <= '0;
    current_cycle_branch <= 0;
  end
  else begin
    // current_cycle_branch <= current_cycle_has_branch;
    if (current_cycle_has_branch)
      total_branches <= total_branches + 1;
  end
end

endmodule : decoder 