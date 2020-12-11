module cacheline_adaptor
(
    input clk,
    input rst,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

enum logic [3:0]{RS,WS,R1,R2,R3,R4,W1,W2,W3,W4,RF,WF} StateR, StateW, NextStateR, NextStateW;
logic [255:0] Line, NextLine;

always_ff @ ( posedge clk) begin
  if (rst) begin
    StateR <= RS;
    StateW <= WS;
    Line <= 256'b0;
  end
  else begin
    StateR <= NextStateR;
    StateW <= NextStateW;
    Line <= NextLine;
  end
end

always_comb begin
  NextStateR = StateR;
  NextStateW = StateW;
  NextLine = Line;
  burst_o = 64'b0;
  resp_o = 0;
  read_o = 0;
  write_o = 0;

  unique case (StateR)
    RS: begin
        if(read_i)  NextStateR = R1;
        end
    R1: begin
        read_o = 1;
        if(resp_i) begin
          NextStateR = R2;
          NextLine[63:0] = burst_i;
        end
    end
    R2: begin
        read_o = 1;
        if(resp_i) begin
          NextStateR = R3;
          NextLine[127:64] = burst_i;
        end
    end
    R3:begin
      read_o = 1;
      if(resp_i) begin
        NextStateR = R4;
        NextLine[191:128] = burst_i;
      end
    end
    R4: begin
        read_o =1;
        if(resp_i) begin
          NextStateR = RF;
          NextLine[255:192] = burst_i;
        end
      end
    RF: begin
        resp_o = 1;
        NextStateR = RS;
        end
    default: ;
  endcase

  unique case (StateW)
    WS: begin
        if(write_i) NextStateW = W1;
        end
    W1: begin
        write_o = 1;
        if(resp_i) begin
          NextStateW = W2;
          burst_o = line_i[63:0];
        end
    end
    W2: begin
        write_o = 1;
        if(resp_i) begin
          NextStateW = W3;
          burst_o = line_i[127:64];
        end
    end
    W3:begin
      write_o = 1;
      if(resp_i) begin
        NextStateW = W4;
        burst_o = line_i[191:128];
      end
    end
    W4: begin
        write_o = 1;
        if(resp_i) begin
          NextStateW = WF;
          burst_o = line_i[255:192];
        end
    end
    WF: begin
      NextStateW = WS;
      resp_o = 1;
    end
    default: ;
  endcase
end

assign address_o = address_i;
assign line_o = Line;

endmodule : cacheline_adaptor
