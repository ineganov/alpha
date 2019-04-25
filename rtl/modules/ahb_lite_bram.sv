module ahb_lite_bram
#(
   parameter HADDR_WIDTH = 17,
             HDATA_WIDTH = 64,
             MADDR_WIDTH = HADDR_WIDTH - $clog2(HDATA_WIDTH / 8)
)(
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
   output                   HREADYOUT
);
   // bram wires
   wire [MADDR_WIDTH-1:0] wa;
   wire                   we;
   wire [HDATA_WIDTH-1:0] wd;
   wire [MADDR_WIDTH-1:0] ra;
   wire                   re;
   wire [HDATA_WIDTH-1:0] rd;

   ahb_lite_sdp   #(
      .HADDR_WIDTH ( HADDR_WIDTH ),
      .HDATA_WIDTH ( HDATA_WIDTH ),
      .MADDR_WIDTH ( MADDR_WIDTH ) 
   ) ahb_lite_sdp  (
      .HCLK        ( HCLK        ),
      .HRESETn     ( HRESETn     ),
      .HADDR       ( HADDR       ),
      .HTRANS      ( HTRANS      ),
      .HSIZE       ( HSIZE       ),
      .HWRITE      ( HWRITE      ),
      .HWDATA      ( HWDATA      ),
      .HRDATA      ( HRDATA      ),
      .HREADY      ( HREADY      ),
      .HRESP       ( HRESP       ),
      .HSEL        ( HSEL        ),
      .HREADYOUT   ( HREADYOUT   ),
      .wa          ( wa          ),
      .we          ( we          ),
      .wd          ( wd          ),
      .ra          ( ra          ),
      .re          ( re          ),
      .rd          ( rd          ) 
   );

   sdp_bram #(
      .ADDR_WIDTH ( MADDR_WIDTH ),
      .DATA_WIDTH ( HDATA_WIDTH ) 
   ) sdp_bram (
      .clk        ( HCLK        ),
      .wa         ( wa          ),
      .we         ( we          ),
      .wd         ( wd          ),
      .ra         ( ra          ),
      .re         ( re          ),
      .rd         ( rd          ) 
   );

endmodule
