`include "defines.vh"

module dcache  (  input                 clk,
                  input                 reset,

                  input                 read_e0,
                  input      [`VA_BITS] read_addr_e0,

                  input                 inv_en_e1,
                  input           [9:4] inv_index_e1,

                  input                 write_xx,
                  input      [`VA_BITS] write_addr_xx,
                  input          [63:0] write_data_xx,
                  input           [7:0] write_be_xx,

                  output reg [`VA_BITS] dc_addr_e1,
                  output reg     [63:0] dc_data_e1,
                  output                dc_miss_e1,
                  output                dc_hit_e1 );

// Sizes are in bytes
// localparam DC_SIZE = 1024;
// localparam DC_WORD_SIZE = 8;
// localparam DC_LINE_SIZE = 16;

// addr[2:0] qw offset (8 bytes)
// addr[3]   qw sel in line
// addr[3:0] offset in line  (16 bytes)
// addr[9:4] idx (6 bits, 64 indices)
// addr[31:10] tag (22 bits)


logic read_e1, hit_e1;

logic  [21:0] output_tag_e1;
logic         output_vld_e1;

logic  [63:0] dc_tag_vld;

wire    [9:4] tag_addr  = write_xx ? write_addr_xx[9:4] : read_addr_e0[9:4];
wire    [9:3] data_addr = write_xx ? write_addr_xx[9:3] : read_addr_e0[9:3];

always_ff@(posedge clk)
   if(reset) read_e1 <= 1'b0;
   else      read_e1 <= read_e0;

wire idx_inv_bypass_e0 = (read_addr_e0[9:4] == inv_index_e1) & read_e0 & inv_en_e1;

always_ff@(posedge clk)
   if(reset) output_vld_e1 <= 1'b0;
   else      output_vld_e1 <= dc_tag_vld[read_addr_e0[9:4]] & ~idx_inv_bypass_e0;


sp_ram #( .WIDTH(22), .DEPTH(64) ) tram ( .clk   ( clk                  ),
                                          .addr  ( tag_addr             ),
                                          .we    ( write_xx             ),
                                          .wdata ( write_addr_xx[31:10] ),
                                          .rdata ( output_tag_e1        ) );

sp_ram #( .WIDTH(64), .DEPTH(128)) dram ( .clk   ( clk                  ),
                                          .addr  ( data_addr            ),
                                          .we    ( write_xx             ),
                                          .wdata ( write_data_xx        ),
                                          .rdata ( dc_data_e1           ) );

always_ff@(posedge clk)
   if(read_e0)
      dc_addr_e1 <= read_addr_e0;

genvar line_num;
generate
   for (line_num = 0; line_num < 64; line_num++) 
   begin : gen_line_vld

      always_ff@(posedge clk)
         if(reset | (inv_en_e1 & (inv_index_e1 == line_num)))
            dc_tag_vld[line_num] <= 1'b0;
         else if (write_xx & (write_addr_xx[9:4] == line_num))
            dc_tag_vld[line_num] <= 1'b1;
   end
endgenerate


assign hit_e1 = output_vld_e1 & (output_tag_e1 == dc_addr_e1[31:10]);
assign dc_miss_e1 = read_e1 & ~hit_e1;
assign  dc_hit_e1 = read_e1 &  hit_e1;

endmodule
