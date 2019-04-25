/* UART16550 controller for MIPSfpga+ system AHB-Lite bus
 * Copyright(c) 2017-2019 Stanislav Zhelnio
 * https://github.com/zhelnio/ahb_lite_uart16550
 * 
 * based on https://github.com/freecores/uart16550 
 *          https://github.com/olofk/uart16550
 *
 * these projects source code is placed in 'uart16550' folder
 */

`include "ahb_lite.vh"

module ahb_lite_uart16550
#(
   parameter HADDR_WIDTH = 32
)(
    //AHB-Lite side
    input                        HCLK,
    input                        HRESETn,
    input      [HADDR_WIDTH-1:0] HADDR,
    input      [            1:0] HTRANS,
    input      [            2:0] HSIZE,     // ignored, byte only access
    input                        HWRITE,
    input      [            7:0] HWDATA,
    output reg [            7:0] HRDATA,
    input                        HREADY,
    output                       HRESP,
    input                        HSEL,
    output                       HREADYOUT,

    //UART side
    input                        uart_SRX,   // UART serial input signal
    output                       uart_STX,   // UART serial output signal
    output                       uart_INT    // UART interrupt

    //Modem side
    `ifdef UART16550_MODEM_IO
    output                       uart_RTS,   // UART MODEM Request To Send
    input                        uart_CTS,   // UART MODEM Clear To Send
    output                       uart_DTR,   // UART MODEM Data Terminal Ready
    input                        uart_DSR,   // UART MODEM Data Set Ready
    input                        uart_RI,    // UART MODEM Ring Indicator
    input                        uart_DCD,   // UART MODEM Data Carrier Detect
    output                       uart_BAUD,  // UART baudrate output
    `endif
);
    // modem side wires
    wire [3:0] modem_inputs;
    wire       modem_rts;
    wire       modem_dtr;
    wire       modem_baud;

    `ifdef UART16550_MODEM_IO
        assign modem_inputs = { uart_CTS, uart_DSR, uart_RI, uart_DCD }
        assign uart_RTS  = modem_rts;
        assign uart_DTR  = modem_dtr;
        assign uart_BAUD = modem_baud
    `else
        assign modem_inputs = 4'b0;
    `endif

    // bus adapter side wires
    wire [2:0] a;
    wire       en;
    wire [7:0] wd;
    wire       we;
    reg  [7:0] rd;
    wire [7:0] rd_nx;

    always_ff @(posedge HCLK)
        rd <= rd_nx;

    ahb_lite_sp     #(
        .HADDR_WIDTH ( HADDR_WIDTH ),
        .HDATA_WIDTH ( 8           ),
        .BADDR_WIDTH ( 0           ),
        .MADDR_WIDTH ( 3           ) 
    ) ahb_lite_sp    (
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
        .a           ( a           ),
        .en          ( en          ),
        .wd          ( wd          ),
        .we          ( we          ),
        .rd          ( rd          ) 
    );

    // uart core
    uart_regs uart_core (
        .clk            (  HCLK         ),
        .wb_rst_i       ( ~HRESETn      ),
        .wb_addr_i      (  a            ),
        .wb_dat_i       (  wd           ),
        .wb_dat_o       (  rd_nx        ),
        .wb_we_i        (  we           ),
        .wb_re_i        (  re           ),
        .stx_pad_o      (  uart_STX     ),
        .srx_pad_i      (  uart_SRX     ),
        .modem_inputs   (  modem_inputs ),
        .rts_pad_o      (  modem_rts    ),
        .dtr_pad_o      (  modem_dtr    ),
        .int_o          (  uart_INT     ),
        .baud_o         (  modem_baud   )
    );

endmodule

module ahb_lite_sp
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
    input  [            2:0] HSIZE,     // ignored
    input                    HWRITE,
    input  [HDATA_WIDTH-1:0] HWDATA,
    output [HDATA_WIDTH-1:0] HRDATA,
    input                    HREADY,
    output                   HRESP,
    input                    HSEL,
    output                   HREADYOUT,
    // bram side
    output     [MADDR_WIDTH-1:0] a,
    output                       en,
    output reg [HDATA_WIDTH-1:0] wd,
    output reg                   we,
    input      [HDATA_WIDTH-1:0] rd 
);
    wire act = HTRANS != `HTRANS_IDLE && HSEL && HREADY;

    always_ff @(posedge HCLK or negedge HRESETn)
        if(HRESETn) we <= 1'b0;
        else        we <= act & HWRITE;

    reg [MADDR_WIDTH-1:0] wa;
    always_ff @(posedge HCLK)
        if(act) wa <= HADDR [BADDR_WIDTH +: MADDR_WIDTH];

    wire                  re = act & ~we;
    reg [MADDR_WIDTH-1:0] ra = HADDR [BADDR_WIDTH +: MADDR_WIDTH];

    assign a  = we ? wa: ra;
    assign en = we | re;
    assign wd = HWDATA;

    assign HRDATA    = rd;
    assign HREADYOUT = ~we;
    assign HRESP     = 1'b0;

endmodule
