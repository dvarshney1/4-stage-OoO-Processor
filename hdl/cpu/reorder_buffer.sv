module reorder_buffer #(parameter rob_size = 16, parameter rob_index_bits = 4, parameter rs_size = 16, parameter rs_index_bits = 4)
(
    input clk,
    input rst,
    input logic load_rob_dec,
    input logic [4:0] regidx_dec, //sent by decoder
    input logic [31:0] rsidx_rs, //sent by decoder (Reservation Station index)
    input logic  [rs_size-1:0] done_rs, //comes from the reservation station indication all bits that have updated
    input logic  [31:0] data_rs [rs_size-1:0], 
    output logic load_reg_wb, load_reg_dec,// output to load the WB. 
    output logic [4:0] regidx_wb, //will specify which register that will be updated in regfile. 
    output logic [31:0] regdata_wb, regdata_dec, // the new data we want to load our register with
    output logic [rob_size-1:0] done_rob,
    output logic [31:0] data_rob[rob_size-1:0],
    output logic rob_really_full,
    output logic [rob_index_bits-1:0] rob_head
);

typedef struct packed {
    logic [4:0]    Regidx;
    logic          v;
    logic [31:0]   Data_RSidx;
} ROB;

ROB rob[rob_size-1:0], rob_next[rob_size-1:0];

logic [rob_index_bits-1:0] rob_tail, rob_tail_next, rob_head_next;
logic rob_empty, rob_full, rob_flag;
logic rob_load_full;
logic [31:0] rob_total, rob_total_next;
logic [31:0] rob_full_count, rob_full_count_next;

assign rob_full = (rob_tail == rob_head-4'd1) && ~rob[rob_head].v;
assign rob_empty = (rob_tail == rob_head);
assign rob_really_full = (rob_tail == rob_head-4'd1) && rob_flag;

assign rob_tail_next = (load_rob_dec || rob_load_full) && ~rob_full ? rob_tail + 4'd1 : rob_tail;
assign rob_head_next = rob[rob_head].v && ~rob_empty ? rob_head + 4'd1 : rob_head ;

assign rob_total_next = load_rob_dec ? rob_total + 1 : rob_total;
assign rob_full_count_next = (rob_tail == rob_head-4'd1) ? rob_full_count + 1 : rob_full_count;

always_ff @ (posedge clk)begin
    if (rst)
        rob_load_full <= 0;
    else if(rob_full && load_rob_dec)
        rob_load_full <= 1;
    else if (rob_load_full == 1 && ~rob_full)
        rob_load_full <= 0;
end



//decoder stage
//regidx_dec directly set by decoder
assign regdata_dec = {'0,rob_tail};
assign load_reg_dec = load_rob_dec;

//write-back stage
assign regidx_wb = rob[rob_head].Regidx;
assign regdata_wb = rob[rob_head].Data_RSidx;
assign load_reg_wb = rob[rob_head].v && ~rob_empty;


//brodcast
always_comb begin
    for (int i=0; i<rob_size; i=i+1) begin
        done_rob[i] = rob[i].v;
        data_rob[i] = rob[i].Data_RSidx;
    end
end


//ROB update
always_comb begin
    for (int i=0; i<rob_size; i=i+1) begin
        rob_next[i] = rob[i];
        if ( i == rob_tail && load_rob_dec && ~rob_really_full)
            rob_next[i] = {regidx_dec, 1'b0, rsidx_rs};
        else if(~rob[i].v && done_rs[rob[i].Data_RSidx[rs_index_bits-1:0]])
            rob_next[i] = {rob[i].Regidx, 1'b1, data_rs[rob[i].Data_RSidx[rs_index_bits-1:0]]};
    end
end



always_ff @(posedge clk) 
begin
    if (rst)begin
        rob_head <= '0;
        rob_tail <= '0;
        rob_flag <= '0;
        rob_total <= '0;
        rob_full_count <= '0;
        for (int i=0; i<rob_size; i=i+1) 
            rob[i] <= '0;
    end
    else begin
        rob_tail <= rob_tail_next;
        rob_head <= rob_head_next;
        rob_total <= rob_total_next;
        rob_full_count <= rob_full_count_next;
        // rob_flag <= rob_full && load_rob_dec;
        if (~rob_flag && load_rob_dec && rob_full)
            rob_flag <= 1;
        else if(rob_flag && ~rob_full)
            rob_flag <= 0;
        for (int i=0; i<rob_size; i=i+1) 
            rob[i] <= rob_next[i];
    end
end


endmodule : reorder_buffer