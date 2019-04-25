
module sdp_gpio
#(
   parameter GPIO_WIDTH = 1
)(
   input                       clk,
   input                       rst_n,

   // mem access port
   input                       wa,
   input                       we,
   input      [GPIO_WIDTH-1:0] wd,
   input                       ra,
   input                       re,
   output reg [GPIO_WIDTH-1:0] rd,

   // gpio
   input      [GPIO_WIDTH-1:0] gpio_i,
   output reg [GPIO_WIDTH-1:0] gpio_o
);
   localparam  ADDR_RD = 1'b0,
               ADDR_WR = 1'b1;

   // gpio output write
   always_ff @(posedge clk or negedge rst_n)
      if(~rst_n)
         gpio_o <= '0;
      else if(we && wa == ADDR_WR)
         gpio_o <= wd;

   // gpio input debouncer
   reg [GPIO_WIDTH-1:0] dpio_i0, dpio_i1;
   always_ff @(posedge clk or negedge rst_n)
      if(~rst_n)
         { dpio_i1, dpio_i0 } <= '0;
      else
         { dpio_i1, dpio_i0 } <= { dpio_i0, gpio_i };

   // gpio read
   always_ff @(posedge clk or negedge rst_n)
      if(~rst_n)
         rd <= '0;
      else if(re) begin
         case (ra)
            ADDR_RD : rd <= dpio_i1;
            ADDR_WR : rd <= gpio_o;
         endcase
      end

endmodule
