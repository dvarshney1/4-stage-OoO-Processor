import rv32i_types::*;


//TODO: figure out how to get data in the very next cycle (save 1 cycle); see if widx can be a wire and still be used to index
module ALU_reservation_station #(
                            parameter alu_rs_size = 8,
                            parameter alu_rs_index_bits = 3,
                            parameter rob_size = 16,
                            parameter rob_index_bits = 4
                            )
(
    input clk,
    input rst,
    input logic [31:0] opA_dec, opB_dec,
    input logic v1_dec, v2_dec,
    input alu_ops aluop_dec,
    input logic load_alurs_dec,
    input logic [rob_size-1:0] done_rob,
    input logic [31:0] data_rob[rob_size-1:0],
    output logic [alu_rs_index_bits-1:0] widx_alurs,
    output logic [31:0] data_alurs [alu_rs_size-1:0],
    output logic [alu_rs_size-1:0] done_alurs, //end of this cycle result is available if done_alurs[i] = 1
    output logic alurs_full
);

typedef struct packed {
    logic [31:0]    rs1_robidx;
    logic           v1;
    logic [31:0]    rs2_robidx;
    logic           v2;
    alu_ops         aluop;
} ALU_RS;

ALU_RS alu_rs[alu_rs_size-1:0], alu_rs_next[alu_rs_size-1:0];

genvar i;
generate 
        for (i = 0; i < alu_rs_size; i = i + 1) begin : ALU_Instantiation
            alu ALU(
                .aluop(alu_rs[i].aluop),
                .a(alu_rs[i].rs1_robidx), 
                .b(alu_rs[i].rs2_robidx),
                .f(data_alurs[i])
                );
        end 
endgenerate

logic [alu_rs_index_bits-1:0] widx_alurs_next;
logic [alu_rs_size-1: 0] alu_rs_bitmap, alu_rs_bitmap_next;
logic alurs_empty;
logic [31:0] alu_rs_total, alu_rs_total_next;
logic [31:0] alu_rs_full_count, alu_rs_full_count_next;

assign alurs_full = (alu_rs_bitmap == -1);
// assign alurs_full = (alu_rs_bitmap == -1) && (done_alurs == '0); make this work
assign alurs_empty = (alu_rs_bitmap == 0);
assign alu_rs_total_next = load_alurs_dec ? alu_rs_total + 1 : alu_rs_total;
assign alu_rs_full_count_next = (alu_rs_bitmap == -1) ? alu_rs_full_count + 32'd1 : alu_rs_full_count;

always_comb begin : done_alu_operation
    for (int j=0; j<alu_rs_size; j=j+1)
        done_alurs[j] = (alu_rs[j].v1 && alu_rs[j].v2);
end


always_comb begin : get_latest_rs_available
    widx_alurs_next = '0;
    alu_rs_bitmap_next = (alu_rs_bitmap & ~done_alurs);
    for (int j = alu_rs_size-1; j >=0 ; j=j-1) begin
        if(~alu_rs_bitmap[j] || done_alurs[j])begin
            if(j == widx_alurs && load_alurs_dec)
                alu_rs_bitmap_next[j] = 1;
            else
                widx_alurs_next = 3'(j);
        end
    end
end

//update block for alurs -> will be updated by the ROB
always_comb begin : update_alu_rs_station
    for (int j=0; j<alu_rs_size; j=j+1) begin
        alu_rs_next[j] = alu_rs[j];
        if(j==widx_alurs && load_alurs_dec && (~alu_rs_bitmap[j] || done_alurs[j])) begin // do not need for alurs_full as decode should not assert load_alurs_dec when full
            alu_rs_next[j] = {opA_dec,v1_dec,opB_dec,v2_dec,aluop_dec};
        end
        else begin
            if(alu_rs_bitmap[j] && ~alu_rs[j].v1 && done_rob[alu_rs[j].rs1_robidx[rob_index_bits-1:0]]) begin
                alu_rs_next[j].v1 = 1;
                alu_rs_next[j].rs1_robidx = data_rob[alu_rs[j].rs1_robidx[rob_index_bits-1:0]];
            end
            if(alu_rs_bitmap[j] && ~alu_rs[j].v2 && done_rob[alu_rs[j].rs2_robidx[rob_index_bits-1:0]]) begin
                alu_rs_next[j].v2 = 1;
                alu_rs_next[j].rs2_robidx = data_rob[alu_rs[j].rs2_robidx[rob_index_bits-1:0]];
            end
        end
    end
end

always_ff @(posedge clk) begin
    if(rst) begin
        alu_rs_bitmap <= '0;
        widx_alurs <= '0;
        alu_rs_total <= '0;
        alu_rs_full_count <= '0;
        for (int j=0; j<alu_rs_size; j=j+1) begin
            alu_rs[j] <= '0;
        end
    end
    else begin
        alu_rs_bitmap <= alu_rs_bitmap_next;
        widx_alurs <= widx_alurs_next;
        alu_rs_total <= alu_rs_total_next;
        alu_rs_full_count <= alu_rs_full_count_next;
        for (int j=0; j<alu_rs_size; j=j+1) begin
            alu_rs[j] <= alu_rs_next[j];
        end
    end
end

endmodule : ALU_reservation_station
