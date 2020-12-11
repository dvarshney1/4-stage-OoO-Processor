// Change frequency for accurate timing
`define FREQUENCY_MHZ 100.0
`define FREQUENCY (`FREQUENCY_MHZ * 1000000)
`define PERIOD_NS (1000000000/`FREQUENCY)
`define PERIOD_CLK (`PERIOD_NS / 2)

`timescale 1ns/1ps

module instruction_queue #(parameter iq_size = 16, parameter iq_index_bit = 4) (
    input clk,
    input rst,
    input load_iq_fetch, //to load the iq (from MIR) -> load_iq_fetch
    input logic [31:0] mem_i_rdata, //the instruction to load it with
    input logic [31:0] mem_i_address,
    input logic full_dec, //ROB or RS is full
    input logic flush_iq_fetch,
    input logic [31:0] PC,

    output logic iq_empty,
    output logic iq_really_full, //iq is full dont send more stuff
    output logic load_dec_iq, //iq is not empty; entry at head is ready to be dcoded
    output logic [31:0] instruction_iq_head, //iq entry at head
    output logic [31:0] PC_iq_head
);

typedef struct packed {
    logic [31:0] instruction;
    logic [31:0] PC; 
} IQ;

IQ iq[iq_size-1:0];

logic [iq_index_bit-1:0] iq_tail, iq_head, iq_tail_next, iq_head_next;
logic iq_full, iq_flag;
logic iq_load_full;

always_ff @ (posedge clk)begin
    if (rst)
        iq_load_full <= 0;
    else if(iq_full && load_iq_fetch)
        iq_load_full <= 1;
    else if (iq_load_full == 1 && ~iq_full)
        iq_load_full <= 0;
end

assign iq_full = (iq_tail == iq_head-4'd1) && full_dec;
assign iq_empty = (iq_tail == iq_head);
assign iq_really_full = (iq_tail == iq_head-4'd1) && iq_flag;

assign iq_tail_next = (load_iq_fetch || iq_load_full) && ~iq_full ? iq_tail + 4'd1 : iq_tail;
assign iq_head_next = ~full_dec && ~iq_empty ? iq_head + 4'd1 : iq_head ;

assign load_dec_iq = ~iq_empty;
assign instruction_iq_head = iq[iq_head].instruction;
assign PC_iq_head = iq[iq_head].PC;

// always_ff @(posedge clk) begin
//   if(iq_really_full) 
//     $display("In iq", $time, instruction_iq_head);
// end

always_ff @(posedge clk) 
begin
    if (rst || flush_iq_fetch)begin
        iq_head <= '0;
        iq_tail <= '0;
        iq_flag <= '0;
        for (int i=0; i<iq_size; i=i+1) 
            iq[i] <= '0;
    end
    else begin
        iq_head <= iq_head_next;
        iq_tail <= iq_tail_next;
        // iq_flag <= iq_full  && load_iq_fetch;
        if (~iq_flag && load_iq_fetch && iq_full)
            iq_flag <= 1;
        else if(iq_flag && ~iq_full)
            iq_flag <= 0;
        if(~iq_really_full && load_iq_fetch) begin
            iq[iq_tail].instruction <= mem_i_rdata;
            iq[iq_tail].PC <= mem_i_address;
        end
    end
end

endmodule : instruction_queue