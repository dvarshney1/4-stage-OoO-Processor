import rv32i_types::*;

module mem_mux
(
    input mem_ops memop,
    input [31:0] mem_address_u, //memory address
    input [31:0] mem_d_rdata, //data coming from memory
    input [31:0] mem_wdata_in, //data going to memeory
    output logic is_store,
    output logic [3:0] mem_d_byte_enable,
    output logic [31:0] mem_mux_out
);

always_comb begin
    unique case (memop)
        mem_lb:     begin
                        unique case (mem_address_u[1:0])
                            2'd0: mem_mux_out = {{24{mem_d_rdata[7]}},mem_d_rdata[7:0]};
                            2'd1: mem_mux_out = {{24{mem_d_rdata[15]}},mem_d_rdata[15:8]};
                            2'd2: mem_mux_out = {{24{mem_d_rdata[23]}},mem_d_rdata[23:16]};
                            2'd3: mem_mux_out = {{24{mem_d_rdata[31]}},mem_d_rdata[31:24]};
                            default: ;
                        endcase
                    end
        mem_lbu:    begin
                        unique case (mem_address_u[1:0])
                            2'd0: mem_mux_out = {24'b0,mem_d_rdata[7:0]};
                            2'd1: mem_mux_out = {24'b0,mem_d_rdata[15:8]};
                            2'd2: mem_mux_out = {24'b0,mem_d_rdata[23:16]};
                            2'd3: mem_mux_out = {24'b0,mem_d_rdata[31:24]};
                            default: ;
                        endcase
                    end
        mem_lh:     begin
                        unique case (mem_address_u[1])
                            1'd0: mem_mux_out = {{16{mem_d_rdata[15]}},mem_d_rdata[15:0]};
                            1'd1: mem_mux_out = {{16{mem_d_rdata[31]}},mem_d_rdata[31:16]};
                            default: ;
                        endcase
                    end
        mem_lhu:    begin
                        unique case (mem_address_u[1])
                            1'd0: mem_mux_out = {16'b0,mem_d_rdata[15:0]};
                            1'd1: mem_mux_out = {16'b0,mem_d_rdata[31:16]};
                            default: ;
                        endcase
                    end
        mem_lw:     mem_mux_out = mem_d_rdata;
        mem_sb:     mem_mux_out = mem_wdata_in << {mem_address_u[1:0], 3'b0};
        mem_sh:     mem_mux_out = mem_wdata_in << {mem_address_u[1], 4'b0};
        mem_sw:     mem_mux_out = mem_wdata_in;
        default:;
     endcase
end


always_comb begin
    unique case (memop)
        mem_lw, mem_sw:             mem_d_byte_enable = 4'b1111;
        mem_lh, mem_lhu, mem_sh:    mem_d_byte_enable = 4'b0011 << {mem_address_u[1], 1'b0};
        mem_lb, mem_lbu, mem_sb:    mem_d_byte_enable = 4'b0001 << mem_address_u[1:0];
        default:                    mem_d_byte_enable = 4'b1111;
    endcase
end

assign is_store = (memop == mem_sb) || (memop == mem_sh) || (memop == mem_sw);

endmodule : mem_mux