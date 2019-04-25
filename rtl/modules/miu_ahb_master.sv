`include "ahb_lite.vh"
`include "defines.vh"

module miu_ahb_master
#(
   parameter HADDR_WIDTH = 17,   // AHB addr width
             HDATA_WIDTH = 64    // data width
)(
   input                        clk,
   input                        reset,

   // cpu side
   input      [      `PKT_ADDR] bus_addr,
   input                        bus_valid,
   input      [      `PKT_DATA] bus_wdata,
   input      [      `PKT_SIZE] bus_wsize,
   input                        bus_write,
   output     [      `PKT_DATA] bus_rdata,
   output                       bus_ready,

   // AHB-Lite side
   output                       HCLK,
   output                       HRESETn,
   output     [HADDR_WIDTH-1:0] HADDR,
   output     [            1:0] HTRANS,
   output reg [            2:0] HSIZE,
   output                       HWRITE,
   output reg [HDATA_WIDTH-1:0] HWDATA,
   input      [HDATA_WIDTH-1:0] HRDATA,
   input                        HREADY,
   input                        HRESP  //ignored
);
   assign HCLK    = clk;
   assign HRESETn = ~reset;
   assign HWRITE  = bus_valid & bus_write;
   assign HTRANS  = bus_valid ? `HTRANS_NONSEQ : `HTRANS_IDLE;
   assign HADDR   = bus_addr;

   always_ff@(posedge clk)
      if(bus_valid & bus_ready)
         HWDATA <= bus_wdata;

   always_comb
      if(HWRITE)
         casez(bus_wsize)
            `OP_SZ_BYTE: HSIZE = `HSIZE_1;
            `OP_SZ_WORD: HSIZE = `HSIZE_2;
            `OP_SZ_LWRD: HSIZE = `HSIZE_4;
            default    : HSIZE = `HSIZE_8;
         endcase
      else
         HSIZE = `HSIZE_8;

   assign bus_ready = HREADY;
   assign bus_rdata = HRDATA;

endmodule
