//send iq_head+1 PC to brrs to flush
module Branch_Predictor(
    input clk,
    input rst,
    input logic flush,
    input logic [31:0] pc_brrs,
    input logic [31:0] pc_curr_brrs,
    input logic [31:0] PC,
    output logic [31:0] PC_next_predict
);

typedef struct packed {
    logic [21:0]    tag;
    logic [31:0]    PC_next; 
    logic           v;   
} BTB;

BTB btb[256];

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i=0; i<256; i=i+1) begin
            btb[i] <= '0;
        end
    end
    else if (flush) begin
        btb[pc_curr_brrs[9:2]] <= {pc_curr_brrs[31:10],pc_brrs,1'b1};
    end

end

assign PC_next_predict = btb[PC[9:2]].v && btb[PC[9:2]].tag == PC[31:10] ? btb[PC[9:2]].PC_next : PC + 4;

endmodule