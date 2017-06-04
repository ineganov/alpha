`include "defines.vh"

module loadstore (input                 clk,
                  input                 reset,
                  input                 enable,

                  input          [63:0] op_a,
                  input          [63:0] op_base,
                  input          [15:0] op_offset,

                  input           [2:0] lsu_op,
                  input           [1:0] op_size,
                  input                 op_llsc,

                  // Result group
                  output                lsu_busy,
                  output                rvalid,
                  output                replay,
                  output         [63:0] result, 
                  input                 squash_result_gr,

                  // LLBit
                  input                 kill_ll,

                  // BIU interface
                  output    [`PKT_BITS] lsu_req_pkt_xx,
                  input                 lsu_req_ack_xx,
                  input     [`PKT_BITS] biu_resp_pkt_xx  );


// VA calculation: can be separated in idx/full VA/LDAH VA if not fast enough
logic     [63:0] full_offset_e0;
logic     [63:0] va_e0, va_e1;

logic            inst_vld_e1;

logic            read_e0;
logic [`VA_BITS] read_addr_e0;

logic            write_dc_e1;
logic            write_dc_pnd_xx;

logic            write_xx;
logic [`VA_BITS] write_addr_xx;
logic     [63:0] write_data_xx;
logic      [7:0] write_be_xx;

logic [`VA_BITS] dc_addr_e1;
logic     [63:0] dc_data_e1, data_shifted_e1, data_zext_e1, data_sext_e1, sc_result_e1;
logic            dc_miss_e1, dc_hit_e1;

logic     [63:0] wdata_e1;
logic     [63:0] uc_data_xx;

logic      [1:0] op_size_e1;
logic            inst_ld_e1, inst_st_e1, inst_lda_e1, sext_e1;

logic            miss_pnd_xx, uc_pnd_xx, uc_replay_xx, biu_ack, biu_last;
logic            req_uc_miss_e1, req_ld_miss_e1, req_st_e1;

logic            op_ll_e1, op_sc_e1, llbit_xx, sc_pass_e1, sc_fail_e1;

wire inst_ld_e0   = (lsu_op == `LSU_LD ) | (lsu_op  == `LSU_LD_U);
wire inst_st_e0   = (lsu_op == `LSU_ST ) | (lsu_op  == `LSU_ST_U);
wire inst_lda_e0  = (lsu_op == `LSU_LDA) | (lsu_op  == `LSU_LDAH);

always_ff@(posedge clk)
   if(reset)
      inst_vld_e1 <= 1'b0;
   else
      inst_vld_e1 <= enable;

always_ff@(posedge clk)
   if(enable & ~replay)
   begin
      op_size_e1   <= op_size;
      inst_ld_e1   <= inst_ld_e0;
      inst_st_e1   <= inst_st_e0;
      inst_lda_e1  <= inst_lda_e0;
      sext_e1      <= (lsu_op == `LSU_LD ) & (op_size == `OP_SZ_LWRD);
      va_e1        <= va_e0;
      wdata_e1     <= op_a;
      op_ll_e1     <= op_llsc & (lsu_op == `LSU_LD);
      op_sc_e1     <= op_llsc & (lsu_op == `LSU_ST);
   end

// ---------------------------------Write data path------------------------------------


//  logic             stb_hit_e1;
//  logic             stb_fail_e1;
//  logic      [63:0] stb_data_e1;
//  
//  
//  logic             rtr_st_vld_xx;
//  logic       [7:0] rtr_st_be_xx;
//  logic      [63:0] rtr_st_data_xx;
//  logic  [`VA_BITS] rtr_st_addr_xx;
//  logic             rtr_st_ack_xx;
//  
//  
//  storebuf storebuf (  .clk            ( clk                  ),
//                       .reset          ( reset                ),
//  
//                       .store_e0       ( inst_st_e0 & ~replay ),
//                       .load_e0        ( inst_ld_e0 & ~replay ),
//                       .op_size_e0     ( op_size              ),
//                       .va_e0,         ( va_e0,               ),
//                       .store_data_e0  ( op_a                 ),
//  
//                       .dealloc_e1     ( dealloc_e1           ),
//                       .stb_hit_e1     ( stb_hit_e1           ),
//                       .stb_fail_e1    ( stb_fail_e1          ),
//                       .stb_data_e1    ( stb_data_e1          ),
//  
//                       .rtr_st_vld_xx  ( rtr_st_vld_xx        ),
//                       .rtr_st_be_xx   ( rtr_st_be_xx         ),
//                       .rtr_st_data_xx ( rtr_st_data_xx       ),
//                       .rtr_st_addr_xx ( rtr_st_addr_xx       ),
//                       .rtr_st_ack_xx  ( rtr_st_ack_xx        ));
//  


// ---------------------------------VA calculation------------------------------------

// LDQ_U and STQ_U are unlaigned instead of unsigned!
wire  allow_ua_e0 = ((lsu_op == `LSU_LD_U) & (op_size == `OP_SZ_QWRD) & ~op_llsc) | 
                    ((lsu_op == `LSU_ST_U) & (op_size == `OP_SZ_QWRD) & ~op_llsc) ;

assign full_offset_e0 = (lsu_op == `LSU_LDAH) ? { {32{op_offset[15]}}, op_offset, 16'd0} :
                                                { {48{op_offset[15]}}, op_offset } ;

assign va_e0 = (op_base + full_offset_e0) & ~{61'd0, {3{allow_ua_e0}}};

// --------------------------------D$ & control---------------------------------------
assign biu_ack  = biu_resp_pkt_xx[`PKT_VLD] & ((biu_resp_pkt_xx[`PKT_TYPE] == `PKT_TYPE_LOAD)  | 
                                               (biu_resp_pkt_xx[`PKT_TYPE] == `PKT_TYPE_STORE));

// BIU Last is only used for cached load misses 
assign biu_last = biu_ack & biu_resp_pkt_xx[`PKT_LAST] & (biu_resp_pkt_xx[`PKT_TYPE] == `PKT_TYPE_LOAD);


assign read_e0 = enable & (inst_ld_e0 | inst_st_e0) & ~replay;
assign read_addr_e0 = va_e0[`PA_BITS];

// assign write_xx      = miss_pnd_xx ?  biu_ack                    : 1'b0 ;      
// assign write_addr_xx = miss_pnd_xx ?  biu_resp_pkt_xx[`PKT_ADDR] : rtr_st_addr_xx;
// assign write_data_xx = miss_pnd_xx ?  biu_resp_pkt_xx[`PKT_DATA] : rtr_st_data_xx;
// assign write_be_xx   = miss_pnd_xx ?  8'hFF                      : rtr_st_be_xx; 

assign write_xx      = biu_ack & miss_pnd_xx     ;
assign write_addr_xx = biu_resp_pkt_xx[`PKT_ADDR];
assign write_data_xx = biu_resp_pkt_xx[`PKT_DATA];
assign write_be_xx   = 8'hFF                     ;

wire       inv_en_e1    = dc_hit_e1 & inst_st_e1 & inst_vld_e1 & ~squash_result_gr;
wire [9:4] inv_index_e1 = va_e1[9:4];

 dcache  dcache(  .clk           ( clk             ),
                  .reset         ( reset           ),  
                  .read_e0       ( read_e0         ),    
                  .read_addr_e0  ( read_addr_e0    ),
                  .inv_en_e1     ( inv_en_e1       ),
                  .inv_index_e1  ( inv_index_e1    ),        
                  .write_xx      ( write_xx        ),     
                  .write_addr_xx ( write_addr_xx   ),          
                  .write_data_xx ( write_data_xx   ),
                  .write_be_xx   ( write_be_xx     ),          
                  .dc_addr_e1    ( dc_addr_e1      ),       
                  .dc_data_e1    ( dc_data_e1      ),       
                  .dc_miss_e1    ( dc_miss_e1      ),       
                  .dc_hit_e1     ( dc_hit_e1       ) );      

// --------------------------------------- LLBit --------------------------------------------------

wire set_ll = inst_vld_e1 & dc_hit_e1 & op_ll_e1 & ~squash_result_gr;
wire clr_ll = inst_vld_e1 & inst_st_e1 & ~squash_result_gr & ~replay;

always_ff@(posedge clk)
   if(reset | clr_ll | kill_ll)
      llbit_xx <= 1'b0;
   else if(set_ll)
      llbit_xx <= 1'b1;

assign sc_pass_e1 = inst_vld_e1 & op_sc_e1 & dc_hit_e1 & llbit_xx;
assign sc_fail_e1 = inst_vld_e1 & op_sc_e1 & (dc_miss_e1 | ~llbit_xx);

// -------------------------------- Bus request logic ---------------------------------------------

assign req_ld_miss_e1 = inst_vld_e1 & inst_ld_e1 & dc_miss_e1 & ~squash_result_gr;
assign req_uc_miss_e1 = inst_vld_e1 & (inst_ld_e1 | inst_st_e1) & va_e1[63] & ~uc_replay_xx & ~squash_result_gr; //FIXME: this should be based on PA
assign req_st_e1      = inst_vld_e1 & inst_st_e1 & ~squash_result_gr & ~sc_fail_e1 & ~uc_replay_xx;

assign lsu_req_pkt_xx[`PKT_VLD ] = req_ld_miss_e1 | req_uc_miss_e1 | req_st_e1;
assign lsu_req_pkt_xx[`PKT_SIZE] = (req_st_e1 | req_uc_miss_e1) ? op_size_e1 : `REQ_SZ_LINE;
assign lsu_req_pkt_xx[`PKT_LAST] = 1'b1;
assign lsu_req_pkt_xx[`PKT_TYPE] = inst_st_e1 ? `PKT_TYPE_STORE : `PKT_TYPE_LOAD;
assign lsu_req_pkt_xx[`PKT_ADDR] = {va_e1[31:3], {3{req_st_e1 | req_uc_miss_e1}} & va_e1[2:0]}; // FIXME: hardcoded PA_BITS
assign lsu_req_pkt_xx[`PKT_DATA] = wdata_e1;


always_ff@(posedge clk)
   if(reset | (miss_pnd_xx & biu_last))
      miss_pnd_xx <= 1'b0;
   else if(~miss_pnd_xx & req_ld_miss_e1 & lsu_req_ack_xx)
      miss_pnd_xx <= 1'b1;

always_ff@(posedge clk)
   if(reset | (uc_pnd_xx & biu_ack)) // FIXME: cached store out, uc store starts, cached store in
      uc_pnd_xx <= 1'b0;
   else if(~uc_pnd_xx & req_uc_miss_e1 & lsu_req_ack_xx)
      uc_pnd_xx <= 1'b1;

always_ff@(posedge clk)
   if(uc_pnd_xx & biu_ack)
      uc_data_xx <= biu_resp_pkt_xx[`PKT_DATA];

always_ff@(posedge clk)
   if(reset | (uc_replay_xx & inst_vld_e1))
      uc_replay_xx <= 1'b0;
   else if (uc_pnd_xx & biu_ack)
      uc_replay_xx <= 1'b1;

// ---------------------------------Output data align/zext/sext------------------------------------
assign data_shifted_e1 = uc_replay_xx ? (uc_data_xx >> {va_e1[2:0], 3'd0}) :
                                        (dc_data_e1 >> {va_e1[2:0], 3'd0}) ;

assign data_zext_e1    = (         {64{(op_size_e1 == `OP_SZ_QWRD)}}  |
                           {32'd0, {32{(op_size_e1 == `OP_SZ_LWRD)}}} |
                           {48'd0, {16{(op_size_e1 == `OP_SZ_WORD)}}} |
                           {56'd0,  {8{(op_size_e1 == `OP_SZ_BYTE)}}} ) & data_shifted_e1;

assign data_sext_e1 = {{32{sext_e1 & data_shifted_e1[31]}}, 32'd0} | data_zext_e1;

assign sc_result_e1 = {63'd0, sc_pass_e1};

assign result   = inst_lda_e1 ? va_e1        :
                     op_sc_e1 ? sc_result_e1 :
                                data_sext_e1 ;

assign rvalid   = inst_vld_e1 & ( inst_ld_e1 | inst_lda_e1 | inst_st_e1 );
assign replay   = req_ld_miss_e1 | req_uc_miss_e1 | (req_st_e1 & ~lsu_req_ack_xx);
assign lsu_busy = uc_pnd_xx | (miss_pnd_xx & ~biu_last);

endmodule
