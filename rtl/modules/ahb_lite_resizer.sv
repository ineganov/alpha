
// AHB-Lite bus resizer
//  AMBA 3 AHB-Lite Protocol, section 6.2

module ahb_lite_resizer #(
    parameter  HADDR_WIDTH = 32, // AHB address width
               HDATA_WIDTH = 8,  // AHB bus data width
               DDATA_WIDHT = 8   // AHB device data width
)(
    // common signals
    input                        HCLK,
    // bus side
    input      [HADDR_WIDTH-1:0] s_HADDR,
    input      [HDATA_WIDTH-1:0] s_HWDATA,
    output reg [HDATA_WIDTH-1:0] s_HRDATA,
    input                        s_HREADY,
    // device side
    output reg [DDATA_WIDHT-1:0] m_HWDATA,
    input      [DDATA_WIDHT-1:0] m_HRDATA 
);
    localparam WIDE2NARROW = HDATA_WIDTH > DDATA_WIDHT;
    localparam WIDTH_RATIO = WIDE2NARROW ? HADDR_WIDTH / DDATA_WIDHT : DDATA_WIDHT / HADDR_WIDTH,
               ADDR_L      = WIDE2NARROW ? $clog2(DDATA_WIDHT / 8)   : $clog2(HADDR_WIDTH / 8),
               ADDR_H      = $clog2(WIDTH_RATIO);

    reg [ADDR_H:ADDR_L] sel;
    always_ff @(posedge HCLK)
        if(s_HREADY)
            sel <= s_HADDR [ADDR_H:ADDR_L];

    always_comb begin
        s_HRDATA = '0;
        m_HWDATA = '0;
        
        for(int i=0; i<WIDTH_RATIO; i++) begin

            // wide bus & narrow slave
            if(WIDE2NARROW) begin 
                s_HRDATA [DDATA_WIDHT*i +: DDATA_WIDHT] = m_HRDATA;
                if(sel == i)
                    m_HWDATA = s_HWDATA [DDATA_WIDHT*i +: DDATA_WIDHT];
            end

            // narrow bus & wide slave
            else begin
                m_HWDATA [HADDR_WIDTH*i +: HADDR_WIDTH] = s_HWDATA;
                if(sel == i)
                    s_HRDATA = m_HRDATA [HADDR_WIDTH*i +: HADDR_WIDTH];
            end
        end
    end

endmodule
