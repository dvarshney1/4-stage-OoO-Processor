module arbiter (
  input clk,
  input rst,
  //I-Cache Port
  input logic pmem_i_read,
  input  logic [31:0] pmem_i_address,
  output logic [255:0] pmem_i_rdata,
  output logic pmem_i_resp,

  //D-Cache Port
  input logic pmem_d_read,
  input logic pmem_d_write,
  input logic [255:0] pmem_d_wdata,
  input logic [31:0] pmem_d_address,
  output logic[255:0]pmem_d_rdata,
  output logic pmem_d_resp,

  //Cacheline-Adapter Port
  output logic arbiter_read,
  output logic arbiter_write,
  output logic [255:0] arbiter_wdata_256,
  output logic [31:0] arbiter_address,
  input logic [255:0] arbiter_rdata_256,
  input logic arbiter_resp
  );

  logic mux_, next_mux;

  always_comb begin
    next_mux = mux_;
    if(~arbiter_read && ~arbiter_write)begin
      if(pmem_d_read || pmem_d_write)
        next_mux = 1;
      else
        next_mux = 0;
    end
  end


  assign pmem_i_resp = ~mux_ ? arbiter_resp : 1'b0;
  assign pmem_d_resp = ~mux_ ?  1'b0 : arbiter_resp;
  assign arbiter_read = ~mux_ ? pmem_i_read : pmem_d_read;
  assign arbiter_write = ~mux_ ? 1'b0 : pmem_d_write;
  assign arbiter_wdata_256 = ~mux_ ? '0 : pmem_d_wdata;
  assign arbiter_address = ~mux_ ? pmem_i_address : pmem_d_address;

  // always_comb begin
    
  //   pmem_i_resp = '0;
  //   pmem_d_resp = '0;
  //   arbiter_read = '0;
  //   arbiter_write = '0;
  //   arbiter_wdata_256 = '0;
  //   arbiter_address = '0;

  //   unique case (mux_)
  //     0: begin
  //        pmem_i_resp = arbiter_resp;
  //        pmem_d_resp = 0;
  //        arbiter_read = pmem_i_read;
  //        arbiter_write = pmem_i_write;
  //        arbiter_wdata_256 = pmem_i_wdata;
  //        arbiter_address = pmem_i_address;
  //     end
  //     1: begin
  //        pmem_i_resp = 0;
  //        pmem_d_resp = arbiter_resp;
  //        arbiter_read = pmem_d_read;
  //        arbiter_write = pmem_d_write;
  //        arbiter_wdata_256 = pmem_d_wdata;
  //        arbiter_address = pmem_d_address;
  //     end
  //   endcase
  // end

  assign pmem_i_rdata = arbiter_rdata_256;
  assign pmem_d_rdata = arbiter_rdata_256;

  always_ff @ (posedge clk) begin
    if (rst)
      mux_ <= 0;
    else
      mux_ <= next_mux;
  end
endmodule : arbiter