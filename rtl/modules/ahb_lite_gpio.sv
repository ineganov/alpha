
module ahb_lite_gpio
#(
   parameter HADDR_WIDTH = 17,
             HDATA_WIDTH = 64,
             GPIO_WIDTH  = 8
)(
   input                       HCLK,
   input                       HRESETn,
   input     [HADDR_WIDTH-1:0] HADDR,
   input     [            1:0] HTRANS,
   input     [            2:0] HSIZE,
   input                       HWRITE,
   input     [HDATA_WIDTH-1:0] HWDATA,
   output    [HDATA_WIDTH-1:0] HRDATA,
   input                       HREADY,
   output                      HRESP,
   input                       HSEL,
   output                      HREADYOUT,

   // gpio
   input      [GPIO_WIDTH-1:0] gpio_i,
   output reg [GPIO_WIDTH-1:0] gpio_o
);
   // gpio side wires
   wire                   wa;
   wire                   we;
   wire [ GPIO_WIDTH-1:0] wd;
   wire                   ra;
   wire                   re;
   wire [ GPIO_WIDTH-1:0] rd;

   wire [HDATA_WIDTH-1:0] bus_wd;
   wire [HDATA_WIDTH-1:0] bus_rd;

   assign wd     = bus_wd [ GPIO_WIDTH-1:0];
   assign bus_rd = {{ HDATA_WIDTH - GPIO_WIDTH {1'b0} }, rd };

   ahb_lite_sdp   #(
      .HADDR_WIDTH ( HADDR_WIDTH ),
      .HDATA_WIDTH ( HDATA_WIDTH ),
      .MADDR_WIDTH ( 1           ) 
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
      .wd          ( bus_wd      ),
      .ra          ( ra          ),
      .re          ( re          ),
      .rd          ( bus_rd      ) 
   );

   sdp_gpio #(
      .GPIO_WIDTH ( GPIO_WIDTH  ) 
   ) sdp_gpio (
      .clk        ( HCLK        ),
      .rst_n      ( HRESETn     ),
      .wa         ( wa          ),
      .we         ( we          ),
      .wd         ( wd          ),
      .ra         ( ra          ),
      .re         ( re          ),
      .rd         ( rd          ),
      .gpio_i     ( gpio_i      ),
      .gpio_o     ( gpio_o      ) 
   );

endmodule
