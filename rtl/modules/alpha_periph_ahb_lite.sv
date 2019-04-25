
`include "defines.vh"

module alpha_periph_ahb_lite
#(
   parameter GPIO_WIDTH = 8,
             BRAM_WIDTH = 14
)(
   input                       clk,
   input                       reset,
   input      [     `PKT_BITS] cpu_req_pkt_xx,
   output                      cpu_req_ack_xx,
   output reg [     `PKT_BITS] cpu_resp_pkt_xx,

   // peripheral
   input      [GPIO_WIDTH-1:0] periph_gpio_i,
   output     [GPIO_WIDTH-1:0] periph_gpio_o 
);
   wire periph_uart_rx;
   wire periph_uart_tx;

   localparam HDATA_WIDTH = 64,
              HADDR_WIDTH = 32;
   localparam HPORT_COUNT = 3;

   // cpu memory interface
   wire [     `PKT_ADDR] bus_addr;
   wire                  bus_valid;
   wire [     `PKT_DATA] bus_wdata;
   wire [     `PKT_SIZE] bus_wsize;
   wire                  bus_write;
   wire [     `PKT_DATA] bus_rdata;
   wire                  bus_ready;

   // global bus wires
   wire                   HCLK;
   wire                   HRESETn;

   // cpu side
   wire [HADDR_WIDTH-1:0] cpu_HADDR;
   wire [            1:0] cpu_HTRANS;
   wire [            2:0] cpu_HSIZE;
   wire                   cpu_HWRITE;
   wire [HDATA_WIDTH-1:0] cpu_HWDATA;
   wire [HDATA_WIDTH-1:0] cpu_HRDATA;
   wire                   cpu_HREADY;
   wire                   cpu_HRESP;

   // peripheral side
   wire [HPORT_COUNT-1:0][HADDR_WIDTH-1:0] HADDR;
   wire [HPORT_COUNT-1:0][            1:0] HTRANS;
   wire [HPORT_COUNT-1:0][            2:0] HSIZE;
   wire [HPORT_COUNT-1:0]                  HWRITE;
   wire [HPORT_COUNT-1:0][HDATA_WIDTH-1:0] HWDATA;
   wire [HPORT_COUNT-1:0][HDATA_WIDTH-1:0] HRDATA;
   wire [HPORT_COUNT-1:0]                  HREADY;
   wire [HPORT_COUNT-1:0]                  HRESP;
   wire [HPORT_COUNT-1:0]                  HSEL;
   wire [HPORT_COUNT-1:0]                  HREADYOUT;

   // addr decoder side
   wire                  [HADDR_WIDTH-1:0] decoder_HADDR;
   wire [HPORT_COUNT-1:0]                  decoder_HSEL;

   // uart bus has another width
   localparam UART_WIDTH = 8;
   wire [UART_WIDTH-1:0] uart_HWDATA;
   wire [UART_WIDTH-1:0] uart_HRDATA;

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

   miu_ahb_master #(
      .HADDR_WIDTH ( HADDR_WIDTH ),
      .HDATA_WIDTH ( HDATA_WIDTH )
   ) miu_ahb_master(
      .clk         ( clk        ),
      .reset       ( reset      ),
      .bus_addr    ( bus_addr   ),
      .bus_valid   ( bus_valid  ),
      .bus_wdata   ( bus_wdata  ),
      .bus_wsize   ( bus_wsize  ),
      .bus_write   ( bus_write  ),
      .bus_rdata   ( bus_rdata  ),
      .bus_ready   ( bus_ready  ),
      .HCLK        ( HCLK       ),
      .HRESETn     ( HRESETn    ),
      .HADDR       ( cpu_HADDR  ),
      .HTRANS      ( cpu_HTRANS ),
      .HSIZE       ( cpu_HSIZE  ),
      .HWRITE      ( cpu_HWRITE ),
      .HWDATA      ( cpu_HWDATA ),
      .HRDATA      ( cpu_HRDATA ),
      .HREADY      ( cpu_HREADY ),
      .HRESP       ( cpu_HRESP  ) 
   );

   ahb_lite_1xN #(
      .HDATA_WIDTH ( HDATA_WIDTH   ),
      .HADDR_WIDTH ( HADDR_WIDTH   ),
      .HPORT_COUNT ( HPORT_COUNT   ) 
   ) ahb_lite_1xN (
      .HCLK        ( HCLK          ),
      .HRESETn     ( HRESETn       ),
      .s_HADDR     ( cpu_HADDR     ),
      .s_HTRANS    ( cpu_HTRANS    ),
      .s_HSIZE     ( cpu_HSIZE     ),
      .s_HWRITE    ( cpu_HWRITE    ),
      .s_HWDATA    ( cpu_HWDATA    ),
      .s_HRDATA    ( cpu_HRDATA    ),
      .s_HREADY    ( cpu_HREADY    ),
      .s_HRESP     ( cpu_HRESP     ),
      .m_HADDR     ( HADDR         ),
      .m_HTRANS    ( HTRANS        ),
      .m_HSIZE     ( HSIZE         ),
      .m_HWRITE    ( HWRITE        ),
      .m_HWDATA    ( HWDATA        ),
      .m_HRDATA    ( HRDATA        ),
      .m_HREADY    ( HREADY        ),
      .m_HRESP     ( HRESP         ),
      .m_HSEL      ( HSEL          ),
      .m_HREADYOUT ( HREADYOUT     ),
      .d_HADDR     ( decoder_HADDR ),
      .d_HSEL      ( decoder_HSEL  ) 
   );

   ahb_decoder #(
      .HADDR_WIDTH ( HADDR_WIDTH   ),
      .HPORT_COUNT ( HPORT_COUNT   ) 
   ) ahb_decoder (
      .d_HADDR     ( decoder_HADDR ),
      .d_HSEL      ( decoder_HSEL  ) 
   );

   ahb_lite_bram #(
      .HADDR_WIDTH ( HADDR_WIDTH   ),
      .HDATA_WIDTH ( HDATA_WIDTH   ),
      .MADDR_WIDTH ( BRAM_WIDTH    )
   ) ahb_lite_bram (
      .HCLK        ( HCLK          ),
      .HRESETn     ( HRESETn       ),
      .HADDR       ( HADDR     [0] ),
      .HTRANS      ( HTRANS    [0] ),
      .HSIZE       ( HSIZE     [0] ),
      .HWRITE      ( HWRITE    [0] ),
      .HWDATA      ( HWDATA    [0] ),
      .HRDATA      ( HRDATA    [0] ),
      .HREADY      ( HREADY    [0] ),
      .HRESP       ( HRESP     [0] ),
      .HSEL        ( HSEL      [0] ),
      .HREADYOUT   ( HREADYOUT [0] ) 
   );

   ahb_lite_gpio #(
      .HADDR_WIDTH ( HADDR_WIDTH   ),
      .HDATA_WIDTH ( HDATA_WIDTH   ),
      .GPIO_WIDTH  ( GPIO_WIDTH    ) 
   ) ahb_lite_gpio (
      .HCLK        ( HCLK          ),
      .HRESETn     ( HRESETn       ),
      .HADDR       ( HADDR     [1] ),
      .HTRANS      ( HTRANS    [1] ),
      .HSIZE       ( HSIZE     [1] ),
      .HWRITE      ( HWRITE    [1] ),
      .HWDATA      ( HWDATA    [1] ),
      .HRDATA      ( HRDATA    [1] ),
      .HREADY      ( HREADY    [1] ),
      .HRESP       ( HRESP     [1] ),
      .HSEL        ( HSEL      [1] ),
      .HREADYOUT   ( HREADYOUT [1] ),
      .gpio_i      ( periph_gpio_i ),
      .gpio_o      ( periph_gpio_o ) 
   );

   ahb_lite_resizer #( 
      .HADDR_WIDTH ( HADDR_WIDTH ),
      .HDATA_WIDTH ( HDATA_WIDTH ),
      .DDATA_WIDHT ( UART_WIDTH  )
   ) uart_resizer  (
      .HCLK        ( HCLK        ),
      .s_HADDR     ( HADDR   [2] ),
      .s_HWDATA    ( HWDATA  [2] ),
      .s_HRDATA    ( HRDATA  [2] ),
      .s_HREADY    ( HREADY  [2] ),
      .m_HWDATA    ( uart_HWDATA ),
      .m_HRDATA    ( uart_HRDATA ) 
   );

   ahb_lite_uart16550 #(
      .HADDR_WIDTH ( HADDR_WIDTH    )
   ) uart16550     (
      .HCLK        ( HCLK           ),
      .HRESETn     ( HRESETn        ),
      .HADDR       ( HADDR     [2]  ),
      .HTRANS      ( HTRANS    [2]  ),
      .HSIZE       ( HSIZE     [2]  ),
      .HWRITE      ( HWRITE    [2]  ),
      .HWDATA      ( uart_HWDATA    ),
      .HRDATA      ( uart_HRDATA    ),
      .HREADY      ( HREADY    [2]  ),
      .HRESP       ( HRESP     [2]  ),
      .HSEL        ( HSEL      [2]  ),
      .HREADYOUT   ( HREADYOUT [2]  ),
      .uart_SRX    ( periph_uart_rx ),
      .uart_STX    ( periph_uart_tx ),
      .uart_INT    (                ) 
   );

endmodule

module ahb_decoder
#(
   parameter HADDR_WIDTH = 17,
             HPORT_COUNT = 2
)(
   input  [HADDR_WIDTH-1:0] d_HADDR,
   output [HPORT_COUNT-1:0] d_HSEL
);
   assign d_HSEL[0] = d_HADDR[31   ] == 0;
   assign d_HSEL[1] = d_HADDR[31:12] == 20'h80001;
   assign d_HSEL[2] = d_HADDR[31:12] == 20'h80002;

endmodule
