`include "defines.vh"

module alpha_miu
(
   input                       clk,
   input                       reset,

   input      [     `PKT_BITS] cpu_req_pkt_xx,
   output                      cpu_req_ack_xx,
   output reg [     `PKT_BITS] cpu_resp_pkt_xx,

   output     [     `PKT_ADDR] bus_addr,
   output                      bus_valid,
   output     [     `PKT_DATA] bus_wdata,
   output     [     `PKT_SIZE] bus_wsize,
   output                      bus_write,
   input      [     `PKT_DATA] bus_rdata,
   input                       bus_ready
);
    logic [`PKT_BITS] pkt_t0, pkt_t1, pkt_t1_r, pkt_t2;

    // ***************************************
    // request logic
    always_ff@(posedge clk)
        if(reset)
            pkt_t1_r <= '0;
        else if(bus_ready)
            pkt_t1_r <= pkt_t0;

    always_comb
        if(cpu_req_pkt_xx[`PKT_VLD] & ~pkt_t1_r[`PKT_VLD]) begin

            if(cpu_req_pkt_xx[`PKT_SIZE] == `REQ_SZ_LINE) begin
                pkt_t0 = cpu_req_pkt_xx;
                pkt_t1 = cpu_req_pkt_xx;

                pkt_t0[`PKT_LAST] = 1'b1;
                pkt_t1[`PKT_LAST] = 1'b0;

                pkt_t0[`PKT_ADDR] = (cpu_req_pkt_xx[`PKT_ADDR] & 32'hffff_fff0) | 4'b1000;
                pkt_t1[`PKT_ADDR] = (cpu_req_pkt_xx[`PKT_ADDR] & 32'hffff_fff0);
            end

            else begin// cpu_req_pkt_xx[`PKT_SIZE] != `REQ_SZ_LINE
                pkt_t0 = {`PKT_P_SIZE{1'b0}};
                pkt_t1 = cpu_req_pkt_xx;
            end
        end

        else if(pkt_t1_r[`PKT_VLD]) begin
            pkt_t0 = {`PKT_P_SIZE{1'b0}};
            pkt_t1 = pkt_t1_r;
        end

        else begin
            pkt_t0 = {`PKT_P_SIZE{1'b0}};
            pkt_t1 = {`PKT_P_SIZE{1'b0}};
        end

    assign cpu_req_ack_xx = cpu_req_pkt_xx[`PKT_VLD] 
                          & ~pkt_t1_r[`PKT_VLD]
                          & bus_ready;

    assign bus_addr  = pkt_t1[`PKT_ADDR];
    assign bus_valid = pkt_t1[`PKT_VLD];

    wire [2:0] wbyte_shift = bus_addr & 3'b111;

    // shift?
    assign bus_wdata = pkt_t1[`PKT_DATA] << (wbyte_shift * 8);
    assign bus_write = pkt_t1[`PKT_VLD] & (pkt_t1[`PKT_TYPE] == `PKT_TYPE_STORE);
    assign bus_wsize = pkt_t1[`PKT_SIZE];

    // ***************************************
    // responce logic
    always_ff@(posedge clk)
        if(reset)
            pkt_t2 <= '0;
        else if(bus_ready)
            pkt_t2 <= pkt_t1;

    wire read_t2  = bus_ready & ((pkt_t2[`PKT_TYPE] == `PKT_TYPE_FETCH) |
                                 (pkt_t2[`PKT_TYPE] == `PKT_TYPE_LOAD )); 
    always_comb begin
        cpu_resp_pkt_xx = pkt_t2;
        cpu_resp_pkt_xx [`PKT_DATA] = read_t2 ? bus_rdata : '0;
        cpu_resp_pkt_xx [`PKT_VLD ] = pkt_t2 [`PKT_VLD ] & bus_ready;
    end

endmodule
