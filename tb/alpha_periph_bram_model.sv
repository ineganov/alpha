`include "defines.vh"

module alpha_periph_bram_model
(
   input                       clk,
   input                       reset,

   input      [     `PKT_BITS] cpu_req_pkt_xx,
   output                      cpu_req_ack_xx,
   output reg [     `PKT_BITS] cpu_resp_pkt_xx
);
   wire [     `PKT_ADDR] bus_addr;
   wire                  bus_valid;
   wire [     `PKT_DATA] bus_wdata;
   wire [     `PKT_SIZE] bus_wsize;
   wire                  bus_write;
   wire [     `PKT_DATA] bus_rdata;
   wire                  bus_ready;

   alpha_miu alpha_miu (
      .clk              ( clk             ),
      .reset            ( reset           ),
      .cpu_req_pkt_xx   ( cpu_req_pkt_xx  ),
      .cpu_req_ack_xx   ( cpu_req_ack_xx  ),
      .cpu_resp_pkt_xx  ( cpu_resp_pkt_xx ),
      .bus_addr         ( bus_addr        ),
      .bus_valid        ( bus_valid       ),
      .bus_wdata        ( bus_wdata       ),
      .bus_wsize        ( bus_wsize       ),
      .bus_write        ( bus_write       ),
      .bus_rdata        ( bus_rdata       ),
      .bus_ready        ( bus_ready       ) 
   );

   miu_bram_model miu_bram_model (
      .clk              ( clk             ),
      .rst              ( reset           ),
      .bus_addr         ( bus_addr        ),
      .bus_valid        ( bus_valid       ),
      .bus_wdata        ( bus_wdata       ),
      .bus_wsize        ( bus_wsize       ),
      .bus_write        ( bus_write       ),
      .bus_rdata        ( bus_rdata       ),
      .bus_ready        ( bus_ready       ) 
   );

endmodule

module miu_bram_model
#(
   parameter ADDR_WIDTH = 17
)(
   input                       clk,
   input                       rst,
   input      [     `PKT_ADDR] bus_addr,
   input                       bus_valid,
   input      [     `PKT_DATA] bus_wdata,
   input      [     `PKT_SIZE] bus_wsize,
   input                       bus_write,
   output reg [     `PKT_DATA] bus_rdata,
   output                      bus_ready
);
   logic [7:0] ram[0:2**ADDR_WIDTH-1];

   string init_path;
   initial begin
      if(!$value$plusargs("MEM8=%s", init_path))
         init_path = "soft/main.hex";

      $readmemh(init_path, ram);
   end

   wire                  act_rd = bus_valid & ~bus_write;
   wire                  act_wr = bus_valid &  bus_write;
   wire [ADDR_WIDTH-1:3] addr_h = bus_addr >> 3;
   wire [           2:0] addr_l = bus_addr & 3'b111;

   always_ff@(posedge clk)
      if(act_rd)
         bus_rdata <= { ram[ { addr_h, 3'd7 } ],
                        ram[ { addr_h, 3'd6 } ],
                        ram[ { addr_h, 3'd5 } ],
                        ram[ { addr_h, 3'd4 } ],
                        ram[ { addr_h, 3'd3 } ],
                        ram[ { addr_h, 3'd2 } ],
                        ram[ { addr_h, 3'd1 } ],
                        ram[ { addr_h, 3'd0 } ] };

   reg [7:0] wmask;
   always_comb
       case(bus_wsize)
           `OP_SZ_BYTE: wmask = 8'b0000_0001 << addr_l;
           `OP_SZ_WORD: wmask = 8'b0000_0011 << addr_l;
           `OP_SZ_LWRD: wmask = 8'b0000_1111 << addr_l;
           default:     wmask = 8'b1111_1111;
       endcase

   always_ff@(posedge clk)
      if(act_wr) begin
         if (wmask[7]) ram[ { addr_h, 3'd7} ] <= bus_wdata [8*7+:8];
         if (wmask[6]) ram[ { addr_h, 3'd6} ] <= bus_wdata [8*6+:8];
         if (wmask[5]) ram[ { addr_h, 3'd5} ] <= bus_wdata [8*5+:8];
         if (wmask[4]) ram[ { addr_h, 3'd4} ] <= bus_wdata [8*4+:8];
         if (wmask[3]) ram[ { addr_h, 3'd3} ] <= bus_wdata [8*3+:8];
         if (wmask[2]) ram[ { addr_h, 3'd2} ] <= bus_wdata [8*2+:8];
         if (wmask[1]) ram[ { addr_h, 3'd1} ] <= bus_wdata [8*1+:8];
         if (wmask[0]) ram[ { addr_h, 3'd0} ] <= bus_wdata [8*0+:8];
      end

   assign bus_ready = 1'b1;

endmodule
