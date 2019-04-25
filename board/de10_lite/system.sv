
`include "defines.vh"

module system
(
    input           ADC_CLK_10,
    input           MAX10_CLK1_50,
    input           MAX10_CLK2_50,

    input   [ 1:0]  KEY,
    input   [ 9:0]  SW,
    output  [ 7:0]  HEX0,
    output  [ 7:0]  HEX1,
    output  [ 7:0]  HEX2,
    output  [ 7:0]  HEX3,
    output  [ 7:0]  HEX4,
    output  [ 7:0]  HEX5,
    output  [ 9:0]  LEDR,

    `ifdef UNUSED
        output  [12:0]  DRAM_ADDR,
        output  [ 1:0]  DRAM_BA,
        output          DRAM_CAS_N,
        output          DRAM_CKE,
        output          DRAM_CLK,
        output          DRAM_CS_N,
        inout   [15:0]  DRAM_DQ,
        output          DRAM_LDQM,
        output          DRAM_RAS_N,
        output          DRAM_UDQM,
        output          DRAM_WE_N,
        output  [ 3:0]  VGA_B,
        output  [ 3:0]  VGA_G,
        output          VGA_HS,
        output  [ 3:0]  VGA_R,
        output          VGA_VS,
        output          GSENSOR_CS_N,
        input   [ 2:1]  GSENSOR_INT,
        output          GSENSOR_SCLK,
        inout           GSENSOR_SDI,
        inout           GSENSOR_SDO,
        inout   [15:0]  ARDUINO_IO,
        inout           ARDUINO_RESET_N,
    `endif

    inout   [35:0]  GPIO
);
    localparam CONF_GPIO_WIDTH = 64;
    localparam CONF_BRAM_WIDTH = 14;
    localparam CONF_7SEG_COUNT = 6;

    wire clk = MAX10_CLK1_50;
    wire reset;

    debouncer rst_debouncer (clk, ~KEY[0], reset);

    wire [CONF_GPIO_WIDTH-1:0] periph_gpio_o;
    wire [CONF_GPIO_WIDTH-1:0] periph_gpio_i = ~periph_gpio_o;

    logic [`PKT_BITS] mem_req_pkt_xx;
    logic             mem_req_ack_xx;
    logic [`PKT_BITS] mem_resp_pkt_xx;

    assign LEDR = periph_gpio_o[9:0];

    alpha_core uut ( 
        .clk              ( clk             ),
        .reset            ( reset           ),
        .mem_req_pkt_xx   ( mem_req_pkt_xx  ),
        .mem_req_ack_xx   ( mem_req_ack_xx  ),
        .mem_resp_pkt_xx  ( mem_resp_pkt_xx ) 
    );

    alpha_periph_ahb_lite #(
        .GPIO_WIDTH       ( CONF_GPIO_WIDTH ),
        .BRAM_WIDTH       ( CONF_BRAM_WIDTH )
    ) periph_ahb ( 
        .clk              ( clk             ),
        .reset            ( reset           ),
        .cpu_req_pkt_xx   ( mem_req_pkt_xx  ),
        .cpu_req_ack_xx   ( mem_req_ack_xx  ),
        .cpu_resp_pkt_xx  ( mem_resp_pkt_xx ),
        .periph_gpio_i    ( periph_gpio_i   ),
        .periph_gpio_o    ( periph_gpio_o   ) 
    );

    seg7_display #(
        .DIGITS ( CONF_7SEG_COUNT )
    ) seg7_display (
        .data   ( periph_gpio_o [32 +: 4*CONF_7SEG_COUNT] ),
        .seg    ( { HEX5, HEX4, HEX3, HEX2, HEX1, HEX0  } )
    );

endmodule

module debouncer
(
    input      clk,
    input      in,
    output reg out
);
    reg buffer;
    always_ff @(posedge clk)
        { out, buffer } <= { buffer, in };

endmodule
