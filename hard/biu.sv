`include "defines.vh"

module biu (   input                 clk,
               input                 reset, 

               input     [`PKT_BITS] ifu_req_pkt_xx,
               input     [`PKT_BITS] lsu_req_pkt_xx,
               output                lsu_req_ack_xx,
               output    [`PKT_BITS] biu_resp_pkt_xx,

               output    [`PKT_BITS] mem_req_pkt_xx,
               input                 mem_req_ack_xx,
               input     [`PKT_BITS] mem_resp_pkt_xx );

logic [`PKT_PLOAD_BITS] ifu_pkt_xx, lsu_pkt_xx;
logic                   ifu_pkt_vld, lsu_pkt_vld;
logic                   lsu_pri, ifu_pri, ifu_pending_xx;


wire lsu_mem_ack = lsu_pri & mem_req_ack_xx;
wire ifu_mem_ack = ifu_pri & mem_req_ack_xx;

wire lsu_b2b_upd = lsu_pkt_vld & lsu_mem_ack;

always@(posedge clk)
   if(ifu_req_pkt_xx[`PKT_VLD])
      ifu_pkt_xx <= ifu_req_pkt_xx[`PKT_PLOAD_BITS];

always@(posedge clk)
   if(lsu_req_pkt_xx[`PKT_VLD] & (~lsu_pkt_vld | lsu_b2b_upd ))
      lsu_pkt_xx <= lsu_req_pkt_xx[`PKT_PLOAD_BITS];


always@(posedge clk)
   if(reset | (~ifu_req_pkt_xx[`PKT_VLD] & ifu_mem_ack ) )
      ifu_pkt_vld <= 1'b0;
   else if(ifu_req_pkt_xx[`PKT_VLD])
      ifu_pkt_vld <= 1'b1;

always@(posedge clk)
   if(reset | (~lsu_req_pkt_xx[`PKT_VLD] & lsu_mem_ack ) )
      lsu_pkt_vld <= 1'b0;
   else if(lsu_req_pkt_xx[`PKT_VLD])
      lsu_pkt_vld <= 1'b1;


assign lsu_pri = lsu_pkt_vld &  ~ifu_pending_xx;
assign ifu_pri = ifu_pkt_vld & (~lsu_pkt_vld | ifu_pending_xx);

always@(posedge clk)
   if(reset | (ifu_pending_xx & mem_req_ack_xx))
      ifu_pending_xx <= 1'b0;
   else if(ifu_pkt_vld & ~lsu_pkt_vld & ~mem_req_ack_xx)
      ifu_pending_xx <= 1'b1;


assign mem_req_pkt_xx[`PKT_VLD]        = lsu_pkt_vld | ifu_pkt_vld;
assign mem_req_pkt_xx[`PKT_PLOAD_BITS] = ({`PKT_PLOAD_SIZE{ifu_pri}} & ifu_pkt_xx ) |
                                         ({`PKT_PLOAD_SIZE{lsu_pri}} & lsu_pkt_xx ) ;


assign lsu_req_ack_xx = lsu_req_pkt_xx[`PKT_VLD] & (~lsu_pkt_vld | lsu_b2b_upd);
assign biu_resp_pkt_xx = mem_resp_pkt_xx;


`ifdef MODEL_TECH

string req_sz_str, req_type_str, resp_sz_str, resp_type_str;

always_comb
   case(mem_req_pkt_xx[`PKT_TYPE])
      `PKT_TYPE_LOAD : req_type_str = " LOAD";
      `PKT_TYPE_STORE: req_type_str = "STORE";
      `PKT_TYPE_FETCH: req_type_str = "FETCH";
      default:         req_type_str = "UNKNW";
   endcase

always_comb
   case(mem_req_pkt_xx[`PKT_SIZE])
      `REQ_SZ_BYTE: req_sz_str = "BYTE";
      `REQ_SZ_WORD: req_sz_str = "WORD";
      `REQ_SZ_LWRD: req_sz_str = "LWRD";
      `REQ_SZ_QWRD: req_sz_str = "QWRD";
      default:      req_sz_str = "LINE";
   endcase

always_comb
   case(mem_resp_pkt_xx[`PKT_TYPE])
      `PKT_TYPE_LOAD : resp_type_str = " LOAD";
      `PKT_TYPE_STORE: resp_type_str = "STORE";
      `PKT_TYPE_FETCH: resp_type_str = "FETCH";
      default:         resp_type_str = "UNKNW";
   endcase

always_comb
   case(mem_resp_pkt_xx[`PKT_SIZE])
      `REQ_SZ_BYTE: resp_sz_str = "BYTE";
      `REQ_SZ_WORD: resp_sz_str = "WORD";
      `REQ_SZ_LWRD: resp_sz_str = "LWRD";
      `REQ_SZ_QWRD: resp_sz_str = "QWRD";
      default:      resp_sz_str = "LINE";
   endcase

always_ff@ (posedge clk)
   begin
      if(mem_req_pkt_xx[`PKT_VLD] & mem_req_ack_xx)
         $display("[%8tps] REQ  <%5s> %4s @%08x %08x_%08x", $time, 
                                                       req_type_str, 
                                                       req_sz_str, 
                                                       mem_req_pkt_xx[`PKT_ADDR], 
                                                       mem_req_pkt_xx[63:32],
                                                       mem_req_pkt_xx[31:0]);

      if(mem_resp_pkt_xx[`PKT_VLD])
         $display("[%8tps] RESP <%5s> %4s @%08x %08x_%08x", $time, 
                                                       resp_type_str, 
                                                       resp_sz_str, 
                                                       mem_resp_pkt_xx[`PKT_ADDR], 
                                                       mem_resp_pkt_xx[63:32],
                                                       mem_resp_pkt_xx[31:0]);

   end

`endif


endmodule
