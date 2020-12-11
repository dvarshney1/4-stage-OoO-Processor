module regfile  #(parameter rob_index_bits = 4)
(
    input clk,
    input rst,
    input [31:0] regdata_wb,
    input [31:0] regdata_dec,
    input [4:0] regidx_wb,
    input [4:0] regidx_dec,
    input load_reg_wb, 
    input load_reg_dec,
    input [4:0] rs1_dec, rs2_dec,
    input logic [rob_index_bits-1:0] rob_head, 
    output logic [31:0] rs1_out, rs2_out,
    output logic rs1_v, rs2_v
);

//logic [31:0] data [32] /* synthesis ramstyle = "logic" */ = '{default:'0};
logic [31:0] data [32];
logic [rob_index_bits-1:0] robidx[32]; 
logic [31:0] v;


always_ff @(posedge clk)
begin
    if (rst)
    begin
        for (int i=0; i<32; i=i+1) begin
            data[i] <= '0;
            robidx[i] <= '0;
            v[i] <= 1;
        end
    end
    else 
    begin
        if (load_reg_dec && regidx_dec) begin
            robidx[regidx_dec] <= regdata_dec;
            v[regidx_dec] <= 0;
        end
        if (load_reg_wb && regidx_wb) begin
            data[regidx_wb] <= regdata_wb;
            if(~(regidx_dec == regidx_wb && load_reg_dec && regidx_dec) && robidx[regidx_wb] == rob_head)
                v[regidx_wb] <= 1;
        end
    end
end

always_comb
begin
    rs1_out = v[rs1_dec] ? data[rs1_dec] : robidx[rs1_dec];
    rs2_out = v[rs2_dec] ? data[rs2_dec] : robidx[rs2_dec];
    rs1_v = v[rs1_dec];
    rs2_v = v[rs2_dec];
end

endmodule : regfile
