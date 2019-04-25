`include "ahb_lite.vh"

// Attention:
// - module is designed to work with sync block ram with no delay (RD is acceptable on clock edge)
// - write request is processed as read-modify-write to apply write mask
// - WD is bypassed to RD when read request followed the write one on the same address

module ahb_lite_sdp
#(
   parameter HADDR_WIDTH = 17,                       // AHB addr width
             HDATA_WIDTH = 32,                       // AHB data width
   parameter BADDR_WIDTH = $clog2(HDATA_WIDTH / 8),  // byte addr in word
             MADDR_WIDTH = HADDR_WIDTH - BADDR_WIDTH // SDP addr width
)(
   // AHB-Lite side
   input                    HCLK,
   input                    HRESETn,
   input  [HADDR_WIDTH-1:0] HADDR,
   input  [            1:0] HTRANS,
   input  [            2:0] HSIZE,
   input                    HWRITE,
   input  [HDATA_WIDTH-1:0] HWDATA,
   output [HDATA_WIDTH-1:0] HRDATA,
   input                    HREADY,
   output                   HRESP,
   input                    HSEL,
   output                   HREADYOUT,
   // bram side
   output reg [MADDR_WIDTH-1:0] wa,
   output reg                   we,
   output reg [HDATA_WIDTH-1:0] wd,
   output     [MADDR_WIDTH-1:0] ra,
   output                       re,
   input      [HDATA_WIDTH-1:0] rd 
);
   wire request = HTRANS != `HTRANS_IDLE && HSEL && HREADY;

   // write port
   always_ff@(posedge HCLK)
      if(~HRESETn) we <= 1'b0;
      else         we <= request & HWRITE;

   always_ff@(posedge HCLK)
      if(request)  wa <= HADDR [BADDR_WIDTH +: MADDR_WIDTH];

   // write is implemented as read-modify-write to apply the mask 
   localparam BMASK_WIDTH = HDATA_WIDTH / 8;
   reg [BMASK_WIDTH-1:0] wmask;

   always_ff@(posedge HCLK)
      if(request)
         case(HSIZE) // write mask
            `HSIZE_1 : wmask <= 8'b00000001 << HADDR[BADDR_WIDTH-1:0];
            `HSIZE_2 : wmask <= 8'b00000011 << HADDR[BADDR_WIDTH-1:0];
            `HSIZE_4 : wmask <= 8'b00001111 << HADDR[BADDR_WIDTH-1:0];
            `HSIZE_8 : wmask <= 8'b11111111;
             default : wmask <= 8'b00000000;
         endcase

   always_comb begin
      for(int i = 0; i<BMASK_WIDTH; i++)
         wd [8*i+:8] = wmask[i] ? HWDATA[8*i+:8] : HRDATA[8*i+:8];
   end

   // read port
   //  write data bypass
   reg [HDATA_WIDTH-1:0] wd_bp;
   reg                   wd_bp_en;
   always_ff@(posedge HCLK) begin
      wd_bp    <= wd;
      wd_bp_en <= ra == wa && we;
   end

   assign ra = HADDR [BADDR_WIDTH +: MADDR_WIDTH];
   assign re = request;
   assign HRDATA = wd_bp_en ? wd_bp : rd;

   // other
   assign HREADYOUT = 1;
   assign HRESP     = 0;

endmodule
