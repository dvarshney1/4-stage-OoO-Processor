module fetch (
    input clk,
    input rst,
    //BR_RS port
    input logic [31:0] pc_brrs,
    input logic flush,
    output logic flush_iq_fetch,
    input logic halt,
    input logic [31:0] pc_curr_brrs,

    //IQ port
    output logic [31:0] PC,
    output logic load_iq_fetch,
    input logic iq_really_full, //iq is full dont send more stuff
    
    // I-Cache port
    input logic mem_i_resp,
    output logic [31:0] mem_i_address,
    output logic mem_i_read
);

logic flush_reg;
logic [31:0] PC_next_predict;

assign mem_i_address = {PC[31:2],2'b0};
// assign mem_i_read = ~iq_really_full && ~halt;
assign load_iq_fetch = ~iq_really_full && mem_i_resp && ~halt;
assign flush_iq_fetch = flush || flush_reg || halt;

enum int unsigned {read1, read2} state, next_state;

always_comb begin
    next_state = state;
    unique case (state)
        read1: begin
            mem_i_read = 0;
            if(~iq_really_full && ~halt)
                next_state = read2;
        end
        read2: begin
            mem_i_read = 1;
            if(mem_i_resp)
                next_state = read1;
        end
        default: ;
    endcase
end

always_ff @(posedge clk) begin
    if (rst)
        state <= read1;
    else
        state <= next_state;
end

always_ff @(posedge clk)
begin
    if (rst)
        flush_reg <= 0;
    else if (flush && mem_i_read)
        flush_reg <= 1;
    else if(flush_reg && mem_i_resp) 
        flush_reg <= 0;
    //no need of else (for stalling), by default wil remain same
end


always_ff @(posedge clk)
begin
    if (rst) 
        PC <= 32'h00000060;
    else if ((flush && ~mem_i_read) || (flush_reg && mem_i_resp))
        PC <= pc_brrs;
    else if(mem_i_resp && ~iq_really_full && ~halt) 
        PC <= PC_next_predict;
end
// assign PC_next_predict = PC+4;
Branch_Predictor bp(
    .*
);

endmodule : fetch