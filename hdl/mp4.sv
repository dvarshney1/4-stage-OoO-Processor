import rv32i_types::*;

module mp4(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

logic inst_read;
logic [31:0] inst_addr;
logic data_read;
logic data_write;
logic [3:0] data_mbe; //wmask
logic [31:0] data_addr;
logic [31:0] data_wdata;
logic inst_resp;
logic [31:0] inst_rdata;
logic data_resp;
logic [31:0] data_rdata;

/* CPU Signals */
// Memory Signals to I-Cache
logic mem_i_resp;
logic [31:0] mem_i_rdata;
logic mem_i_read;
logic [31:0] mem_i_address;
// Memory Signals to D-Cache
logic mem_d_resp;
logic [31:0] mem_d_rdata;
logic mem_d_read;
logic mem_d_write;
logic [31:0] mem_d_wdata;
logic [3:0] mem_d_byte_enable;
logic [31:0] mem_d_address; //(least 2-bit are zero-padded)


assign inst_read = mem_i_read;
assign inst_addr = mem_i_address;
assign data_read = mem_d_read;
assign data_write = mem_d_write;
assign data_mbe = mem_d_byte_enable; //wmask
assign data_addr = mem_d_address;
assign data_wdata = mem_d_wdata;

assign inst_resp = mem_i_resp;
assign inst_rdata = mem_i_rdata;
assign data_resp = mem_d_resp;
assign data_rdata = mem_d_rdata;

// assign mem_i_resp = inst_resp;
// assign mem_i_rdata = inst_rdata;
// assign mem_d_resp = data_resp;
// assign mem_d_rdata = data_rdata;

cpu cpu(
    .*
);

// CP3 Introducing Main Cache
main_cache main_cache(
             .*,
             .mem_i_rdata_cpu(mem_i_rdata),
             .mem_d_byte_enable_cpu(mem_d_byte_enable),
             .mem_d_rdata_cpu(mem_d_rdata),
             .mem_d_wdata_cpu(mem_d_wdata)
);

// // Port to LLC (Lowest Level Cache)
// logic [255:0] line_i;
// logic [255:0] line_o;
// logic [31:0] address_i;
// logic read_i;
// logic write_i;
// logic resp_o;

// assign address_i = mem_address;

// // Port to memory
// logic [63:0] burst_i;
// logic [63:0] burst_o;
// logic [31:0] address_o;
// logic read_o;
// logic write_o;
// logic resp_i;

// assign burst_i = pmem_rdata;
// assign pmem_wdata = burst_o;
// assign pmem_read = read_o;
// assign pmem_write = write_o;
// assign resp_i = pmem_resp;

// main_cache main_cache(
//              .*,
//              .pmem_wdata(line_i),
//              .pmem_rdata(line_o),
//              .pmem_read(read_i),
//              .pmem_write(write_i),
//              .pmem_resp(resp_o)
// );

// cacheline_adaptor cacheline_adaptor(.*);

endmodule : mp4
