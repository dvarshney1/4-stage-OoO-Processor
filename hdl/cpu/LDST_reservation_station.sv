import rv32i_types::*;

module LDST_reservation_station #(
                            parameter rs_index_bits = 4,
                            parameter alu_rs_size = 8,
                            parameter ls_rs_size = 8,
                            parameter ls_rs_index_bits = 3,
                            parameter rob_size = 16,
                            parameter rob_index_bits = 4
                            )
(
    input clk,
    input rst,

    input logic [31:0] opA_dec, opB_dec, imm_dec,
    input logic v1_dec, v2_dec,
    input mem_ops memop_dec,
    input logic [rob_size-1:0] done_rob,
    input logic [31:0] data_rob[rob_size-1:0],
    input logic load_lsrs_dec,
    output logic [rs_index_bits-1:0] widx_lsrs,
    output logic lsrs_really_full,
    output logic [ls_rs_size-1:0] done_lsrs,
    output logic [31:0] data_lsrs[ls_rs_size-1:0],

    //mem-port (Memory Signals to D-Cache)
    input logic mem_d_resp,
    input logic [31:0] mem_d_rdata,
    output logic mem_d_read,
    output logic mem_d_write,
    output logic [31:0] mem_d_wdata,
    output logic [3:0] mem_d_byte_enable,
    output logic [31:0] mem_d_address //(least 2-bit are zero-padded)

);



typedef struct packed {
    logic [31:0]    rs1_robidx;
    logic           v1;
    logic [31:0]    imm;
    logic [31:0]    rs2_robidx;
    logic           v2;
    mem_ops         memop;
} LDST_RS;

LDST_RS ls_rs[ls_rs_size-1:0], ls_rs_next[ls_rs_size-1:0];


logic [31:0] mem_address_u; //no-zero padded address
logic is_store;
mem_ops memop;
logic [31:0] mem_mux_out;
logic [31:0] mem_wdata_in;

logic [ls_rs_index_bits-1:0] lsrs_tail, lsrs_head, lsrs_tail_next, lsrs_head_next;
logic lsrs_empty, lsrs_full, lsrs_flag;

logic lsrs_load_full;

always_ff @ (posedge clk)begin
    if (rst)
        lsrs_load_full <= 0;
    else if(lsrs_full && load_lsrs_dec)
        lsrs_load_full <= 1;
    else if (lsrs_load_full == 1 && ~lsrs_full)
        lsrs_load_full <= 0;
end

mem_mux mem     (
                .memop,
                .mem_address_u,
                .mem_d_rdata,
                .mem_wdata_in,
                .is_store,
                .mem_d_byte_enable,
                .mem_mux_out
                );


assign memop = ls_rs[lsrs_head].memop;
assign mem_address_u = ls_rs[lsrs_head].rs1_robidx + ls_rs[lsrs_head].imm; //if does not work, use a MUX
assign mem_wdata_in = ls_rs[lsrs_head].rs2_robidx;
// assign mem_d_read = ls_rs[lsrs_head].v1 && ~is_store && ~lsrs_empty;
// assign mem_d_write = ls_rs[lsrs_head].v1 && ls_rs[lsrs_head].v2 && is_store && ~lsrs_empty;
assign mem_d_wdata = mem_mux_out;
assign mem_d_address = {mem_address_u[31:2],2'b0};

assign lsrs_full = (lsrs_tail == lsrs_head-3'd1) && ~mem_d_resp;
assign lsrs_empty = (lsrs_tail == lsrs_head);
assign lsrs_really_full = (lsrs_tail == lsrs_head-3'd1) && lsrs_flag;

assign lsrs_tail_next = (load_lsrs_dec || lsrs_load_full) && ~lsrs_full ? lsrs_tail + 3'd1 : lsrs_tail;
assign lsrs_head_next = mem_d_resp && ~lsrs_empty ? lsrs_head + 3'd1 : lsrs_head;
assign widx_lsrs = lsrs_tail + {1'b0,3'(alu_rs_size)};


enum int unsigned {init, read, write} state, next_state;

always_comb begin
    next_state = state;
    unique case (state)
        init: begin
            mem_d_read = 0;
            mem_d_write = 0;
            if(ls_rs[lsrs_head].v1 && ~is_store && ~lsrs_empty)
                next_state = read;
            else if(ls_rs[lsrs_head].v1 && ls_rs[lsrs_head].v2 && is_store && ~lsrs_empty)
                next_state = write;
        end
        read: begin
            mem_d_read = 1;
			mem_d_write = 0;
            if(mem_d_resp) begin
                next_state = init;
                // lsrs_head_next = lsrs_head + 3'd1;
            end
        end
        write: begin
			mem_d_read = 0;
            mem_d_write = 1;
            if(mem_d_resp) begin
                next_state = init;
                // lsrs_head_next = lsrs_head + 3'd1;
            end
        end
        default: ;
    endcase
end

always_ff @(posedge clk) begin
    if (rst)
        state <= init;
    else
        state <= next_state;
end



//brodcast
always_comb begin
    for (int j=0; j<ls_rs_size; j=j+1) begin
        data_lsrs[j] = mem_mux_out;
        done_lsrs[j] = (j == lsrs_head) ? mem_d_resp : 1'd0;
    end
end

//update
always_comb begin
    for (int j=0; j<ls_rs_size; j=j+1) begin
        ls_rs_next[j] = ls_rs[j];
        if (j == lsrs_tail && load_lsrs_dec && ~lsrs_really_full)
            ls_rs_next[j] = {opA_dec,v1_dec,imm_dec,opB_dec,v2_dec,memop_dec};
        else begin
            if(~ls_rs[j].v1 && done_rob[ls_rs[j].rs1_robidx[rob_index_bits-1:0]])begin
                ls_rs_next[j].v1 = 1;
                ls_rs_next[j].rs1_robidx = data_rob[ls_rs[j].rs1_robidx[rob_index_bits-1:0]];
            end
            if(~ls_rs[j].v2 && done_rob[ls_rs[j].rs2_robidx[rob_index_bits-1:0]])begin
                ls_rs_next[j].v2 = 1;
                ls_rs_next[j].rs2_robidx = data_rob[ls_rs[j].rs2_robidx[rob_index_bits-1:0]];
            end
        end
    end
end


always_ff @(posedge clk) 
begin
    if (rst)begin
        lsrs_head <= '0;
        lsrs_tail <= '0;
        lsrs_flag <= '0;
        for (int j=0; j<ls_rs_size; j=j+1) 
            ls_rs[j] <= '0;
    end
    else begin
        lsrs_tail <= lsrs_tail_next;
        lsrs_head <= lsrs_head_next;
        if (~lsrs_flag && load_lsrs_dec && lsrs_full)
            lsrs_flag <= 1;
        else if(lsrs_flag && ~lsrs_full)
            lsrs_flag <= 0;
        // lsrs_flag <= lsrs_full && load_lsrs_dec;
        for (int j=0; j<ls_rs_size; j=j+1) 
            ls_rs[j] <= ls_rs_next[j];
    end
end


endmodule : LDST_reservation_station