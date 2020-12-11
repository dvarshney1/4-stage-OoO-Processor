import rv32i_types::*;

module main_cache (
    input clk,
    input rst,

    /* Physical memory signals */
    input logic pmem_resp,
    input logic [63:0] pmem_rdata,
    output logic [31:0] pmem_address,
    output logic [63:0] pmem_wdata,
    output logic pmem_read,
    output logic pmem_write,

    /* I_cache - CPU memory signals */
    input logic mem_i_read,
    input logic [31:0] mem_i_address,
    output logic mem_i_resp,
    output logic [31:0] mem_i_rdata_cpu,

    /* D_cache - CPU memory signals */
    input logic mem_d_read,
    input logic mem_d_write,
    input logic [3:0] mem_d_byte_enable_cpu,
    input logic [31:0] mem_d_address,
    input logic [31:0] mem_d_wdata_cpu,
    output logic mem_d_resp,
    output logic [31:0] mem_d_rdata_cpu
);

/* All signals specific to the main_cache module go over here */
/* I_cache */
logic pmem_i_read;
logic pmem_i_write;
logic pmem_i_resp;
logic [255:0] pmem_i_rdata;
logic [31:0] pmem_i_address;
logic [255:0] pmem_i_wdata;
//
//assign pmem_i_write = 1'b0;
//assign pmem_i_wdata = 255'b0;

/*Unused CPU signals*/
logic mem_i_write;
logic [3:0] mem_i_byte_enable_cpu;
logic [31:0] mem_i_wdata_cpu;

assign mem_i_write = 1'b0;
assign mem_i_byte_enable_cpu = 4'hf;
assign mem_i_wdata_cpu = 32'b0;
    
/* D_cache */
logic [255:0] pmem_d_rdata;
logic pmem_d_resp;
logic pmem_d_read;
logic pmem_d_write;
logic [255:0] pmem_d_wdata;
logic [31:0] pmem_d_address;

/*arbiter*/
logic arbiter_read;
logic arbiter_write;
logic [255:0] arbiter_wdata_256;
logic [31:0] arbiter_address;
logic [255:0] arbiter_rdata_256;
logic arbiter_resp;


cache i_cache(
    /* Physical memory signals connections */
    .*,
    .pmem_resp(pmem_i_resp),
    .pmem_rdata(pmem_i_rdata),
    .pmem_address(pmem_i_address),
    .pmem_wdata(pmem_i_wdata),
    .pmem_read(pmem_i_read),
    .pmem_write(pmem_i_write),

    /* CPU memory signals connections */
    .mem_read(mem_i_read),
    .mem_write(mem_i_write),
    .mem_byte_enable_cpu(mem_i_byte_enable_cpu),
    .mem_address(mem_i_address),
    .mem_wdata_cpu(mem_i_wdata_cpu),
    .mem_resp(mem_i_resp),
    .mem_rdata_cpu(mem_i_rdata_cpu)
);

cache d_cache(
    /* Physical memory signals connections */
    .*,
    .pmem_resp(pmem_d_resp),
    .pmem_rdata(pmem_d_rdata),
    .pmem_address(pmem_d_address),
    .pmem_wdata(pmem_d_wdata),
    .pmem_read(pmem_d_read),
    .pmem_write(pmem_d_write),

    /* CPU memory signals connections */
    .mem_read(mem_d_read),
    .mem_write(mem_d_write),
    .mem_byte_enable_cpu(mem_d_byte_enable_cpu),
    .mem_address(mem_d_address),
    .mem_wdata_cpu(mem_d_wdata_cpu),
    .mem_resp(mem_d_resp),
    .mem_rdata_cpu(mem_d_rdata_cpu)
);

arbiter arbiter(
    .*
);

cacheline_adaptor cacheline_adaptor(
    .*,

    // Port to LLC (Lowest Level Cache)
    .line_i(arbiter_wdata_256),
    .line_o(arbiter_rdata_256),
    .address_i(arbiter_address),
    .read_i(arbiter_read),
    .write_i(arbiter_write),
    .resp_o(arbiter_resp),

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
    
);

endmodule : main_cache