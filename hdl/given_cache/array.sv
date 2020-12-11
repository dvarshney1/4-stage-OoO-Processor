
module array #(              
                parameter width = 1,
                parameter cache_size = 16,
                parameter cache_index = 4, //log2 cache_size
                parameter tag_size = 23  //32-5-cache_index
                )
(
  input clk,
  input logic load,
  input logic [cache_index-1:0] rindex,
  input logic [cache_index-1:0] windex,
  input logic [width-1:0] datain,
  output logic [width-1:0] dataout
);

//logic [width-1:0] data [2:0];
logic [width-1:0] data [cache_size] = '{default: '0};

// initial begin
//   for (int i=0; i<cache_size; i=i+1)
//     data[i] = '0;
// end

always_comb begin
  dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk)
begin
    if(load)
        data[windex] <= datain;
end

endmodule : array
