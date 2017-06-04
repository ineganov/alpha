`include "defines.vh"

module icache  (  input                 clk,
                  input                 reset,

                  input                 fetch_ff,
                  input      [`VA_BITS] fetch_addr_ff,

                  input                 write_ff,
                  input      [`VA_BITS] write_addr_ff,
                  input          [63:0] write_data_ff,

                  output reg [`VA_BITS] ic_addr_if,
                  output         [63:0] ic_data_if,
                  output                ic_miss_if,
                  output                ic_hit_if );

// Sizes are in bytes
// localparam IC_SIZE = 1024;
// localparam IC_WORD_SIZE = 8;
// localparam IC_LINE_SIZE = 16;

// addr[1:0] offset in instn (4 bytes)
// addr[2]   instn sel in ic word
// addr[3:0] offset in line  (16 bytes)
// addr[9:4] idx (6 bits, 64 indices)
// addr[31:10] tag (22 bits)


logic fetch_if, hit_if;

logic  [63:0] output_data_if;
logic  [21:0] output_tag_if;
logic         output_vld_if;

logic  [63:0] ic_tag_vld;

wire    [9:4] tag_addr  = write_ff ? write_addr_ff[9:4] : fetch_addr_ff[9:4];
wire    [9:3] data_addr = write_ff ? write_addr_ff[9:3] : fetch_addr_ff[9:3];

always_ff@(posedge clk)
   if(reset) fetch_if <= 1'b0;
   else      fetch_if <= fetch_ff;

always_ff@(posedge clk)
   if(reset) output_vld_if <= 1'b0;
   else      output_vld_if <= ic_tag_vld[fetch_addr_ff[9:4]];


sp_ram #( .WIDTH(22), .DEPTH(64) ) tram ( .clk   ( clk                  ),
                                          .addr  ( tag_addr             ),
                                          .we    ( write_ff             ),
                                          .wdata ( write_addr_ff[31:10] ),
                                          .rdata ( output_tag_if        ) );

sp_ram #( .WIDTH(64), .DEPTH(128)) dram ( .clk   ( clk                  ),
                                          .addr  ( data_addr            ),
                                          .we    ( write_ff             ),
                                          .wdata ( write_data_ff        ),
                                          .rdata ( output_data_if       ) );



always_ff@(posedge clk)
   if(fetch_ff)
      ic_addr_if <= fetch_addr_ff;

genvar line_num;
generate
   for (line_num = 0; line_num < 64; line_num++) 
   begin : gen_line_vld

      always_ff@(posedge clk)
         if(reset)
            ic_tag_vld[line_num] <= 1'b0;
         else if (write_ff & (write_addr_ff[9:4] == line_num))
            ic_tag_vld[line_num] <= 1'b1;
   end
endgenerate


assign hit_if = output_vld_if & (output_tag_if == ic_addr_if[31:10]);
assign ic_miss_if = fetch_if & ~hit_if;
assign  ic_hit_if = fetch_if &  hit_if;
assign ic_data_if = output_data_if;

endmodule
