`include "defines.vh"

module alpha_periph_bram_orig
(
   input                       clk,
   input                       reset,

   input      [     `PKT_BITS] mem_req_pkt_xx,
   output                      mem_req_ack_xx,
   output reg [     `PKT_BITS] mem_resp_pkt_xx
);
   string init_path;

   initial
   begin
      if(!$value$plusargs("MEM8=%s", init_path))
         init_path = "soft/main.hex";

      $readmemh(init_path, ram);
   end

   logic       [7:0] ram[0:2**17-1];
   logic      [63:0] wdata, rdata;
   logic [`PKT_BITS] pkt_t0, pkt_t1, pkt_t1_r, pkt_t2;

   always_ff@(posedge clk)
      if(reset) pkt_t1_r <= '0;
      else      pkt_t1_r <= pkt_t0;

   always_ff@(posedge clk)
      if(reset) pkt_t2 <= '0;
      else      pkt_t2 <= pkt_t1;


   always_comb
      if(mem_req_pkt_xx[`PKT_VLD] & ~pkt_t1_r[`PKT_VLD])
      begin
         if(mem_req_pkt_xx[`PKT_SIZE] == `REQ_SZ_LINE)
         begin
            pkt_t0 = mem_req_pkt_xx;
            pkt_t1 = mem_req_pkt_xx;

            pkt_t0[`PKT_LAST] = 1'b1;
            pkt_t1[`PKT_LAST] = 1'b0;

            pkt_t0[`PKT_ADDR] = (mem_req_pkt_xx[`PKT_ADDR] & 32'hffff_fff0) | 4'b1000;
            pkt_t1[`PKT_ADDR] = (mem_req_pkt_xx[`PKT_ADDR] & 32'hffff_fff0);
         end
         else // mem_resp_pkt_xx[`PKT_SIZE] != `REQ_SZ_LINE
         begin
            pkt_t0 = {`PKT_P_SIZE{1'b0}};
            pkt_t1 = mem_req_pkt_xx;
         end
      end
      else if(pkt_t1_r[`PKT_VLD]) 
      begin
         pkt_t0 = {`PKT_P_SIZE{1'b0}};
         pkt_t1 = pkt_t1_r;
      end
      else
      begin
         pkt_t0 = {`PKT_P_SIZE{1'b0}};
         pkt_t1 = {`PKT_P_SIZE{1'b0}};
      end

   always_comb
      begin
      mem_resp_pkt_xx = pkt_t2;
      mem_resp_pkt_xx[`PKT_VLD]  = pkt_t2[`PKT_VLD];// & (pkt_t2[`PKT_TYPE] != `PKT_TYPE_STORE);
      mem_resp_pkt_xx[`PKT_DATA] = rdata;
      end

   assign mem_req_ack_xx = mem_req_pkt_xx[`PKT_VLD] & ~pkt_t1_r[`PKT_VLD];


   wire [31:0] addr_t1 = pkt_t1[`PKT_ADDR];

   wire write_t1 = pkt_t1[`PKT_VLD] & (pkt_t1[`PKT_TYPE] == `PKT_TYPE_STORE);

   wire read_t2  = pkt_t2[`PKT_VLD] & ((pkt_t2[`PKT_TYPE] == `PKT_TYPE_FETCH) |
                                       (pkt_t2[`PKT_TYPE] == `PKT_TYPE_LOAD )); 

   // ZSL: OR on ADDR !? - is it a bug??
   assign rdata =   {64{read_t2}} & { ram[pkt_t2[`PKT_ADDR] | 3'd7], 
                                    ram[pkt_t2[`PKT_ADDR] | 3'd6],
                                    ram[pkt_t2[`PKT_ADDR] | 3'd5],
                                    ram[pkt_t2[`PKT_ADDR] | 3'd4],
                                    ram[pkt_t2[`PKT_ADDR] | 3'd3],
                                    ram[pkt_t2[`PKT_ADDR] | 3'd2],
                                    ram[pkt_t2[`PKT_ADDR] | 3'd1],
                                    ram[pkt_t2[`PKT_ADDR] | 3'd0] };

   // ZSL: WDATA shift - is it nessesary?
   assign wdata = pkt_t1[`PKT_DATA] << (addr_t1[2:0] * 8);



   logic [7:0] base_be, mem_be;

   always_comb
      case(pkt_t1[`PKT_SIZE])
         `OP_SZ_BYTE: base_be = 8'b0000_0001;
         `OP_SZ_WORD: base_be = 8'b0000_0011;
         `OP_SZ_LWRD: base_be = 8'b0000_1111;
         default:     base_be = 8'b1111_1111;
      endcase

   assign mem_be = base_be << addr_t1[2:0];


   always_ff@(posedge clk)
      if(write_t1)
      begin
         if (mem_be[7]) ram[{addr_t1[16:3], 3'd7}] <= wdata[8*7+:8];
         if (mem_be[6]) ram[{addr_t1[16:3], 3'd6}] <= wdata[8*6+:8];
         if (mem_be[5]) ram[{addr_t1[16:3], 3'd5}] <= wdata[8*5+:8];
         if (mem_be[4]) ram[{addr_t1[16:3], 3'd4}] <= wdata[8*4+:8];
         if (mem_be[3]) ram[{addr_t1[16:3], 3'd3}] <= wdata[8*3+:8];
         if (mem_be[2]) ram[{addr_t1[16:3], 3'd2}] <= wdata[8*2+:8];
         if (mem_be[1]) ram[{addr_t1[16:3], 3'd1}] <= wdata[8*1+:8];
         if (mem_be[0]) ram[{addr_t1[16:3], 3'd0}] <= wdata[8*0+:8];
      end



endmodule
