`include "defines.vh"


module ifu (  // Clock
              input                 clk,
              input                 reset, 

              // Redirect iface
              input                 redir_vld,
              input          [63:0] redir_addr,

              // BIU iface
              output    [`PKT_BITS] ifu_req_pkt_xx,
              input     [`PKT_BITS] biu_resp_pkt_xx,

              // Valid instns
              input                 instn_accepted_id,
              output                instn_vld_id,
              output                instn_pr_taken_id,
              output         [31:0] instn_opcode_id,
              output         [63:0] instn_pc_id );


enum int unsigned {ST_WAIT_RDR, ST_FETCH, ST_WBUF, ST_MISS, ST_REFETCH} state, next;


logic            fetch_ff, refetch_ff, pp_redir_vld, redir_fetch_ff;
logic [`VA_BITS] fetch_addr_ff, write_addr_ff, next_fetch_addr_ff, instn_pc_id_l, pp_redir_addr;

logic [`VA_BITS] ic_addr_if;
logic     [63:0] ic_data_if;
logic            ic_miss_if, ic_hit_if;

logic            push_a_if, push_b_if, all_accepted_if, next_fetch_tgt_vld, wait_ibuf_if;
logic            can_accept_1_if, can_accept_2_if;

logic            inst_a_is_br, inst_a_is_jmp, rdy_a_if;
logic            inst_b_is_br, inst_b_is_jmp, rdy_b_if;
logic            fetch_tgt_is_b_if;


wire            biu_ack  = biu_resp_pkt_xx[`PKT_VLD] & (biu_resp_pkt_xx[`PKT_TYPE] == `PKT_TYPE_FETCH);
wire            biu_last = biu_ack & biu_resp_pkt_xx[`PKT_LAST];


wire     [31:0] inst_a_if      = ic_data_if[31:0];
wire [`VA_BITS] inst_a_addr_if = {ic_addr_if[`VA_SIZE-1:3], 3'd0};

wire     [31:0] inst_b_if      = ic_data_if[63:32];
wire [`VA_BITS] inst_b_addr_if = {ic_addr_if[`VA_SIZE-1:3], 3'd4};

wire [`VA_BITS] pc_plus_4   = ic_addr_if + 4'd4;
wire [`VA_BITS] pc_plus_8   = ic_addr_if + 4'd8;
wire [`VA_BITS] pc_br_b_tgt = inst_b_addr_if + 3'd4 + {{`VA_SIZE-23{inst_b_if[20]}}, inst_b_if[20:0], 2'b00};
wire [`VA_BITS] pc_br_a_tgt = inst_a_addr_if + 3'd4 + {{`VA_SIZE-23{inst_a_if[20]}}, inst_a_if[20:0], 2'b00};


always_ff@(posedge clk)
   if(reset | (state == ST_REFETCH))
      pp_redir_vld <= 1'b0;
   else if(redir_vld & (state == ST_MISS))
      pp_redir_vld <= 1'b1;

always_ff@(posedge clk)
   if(redir_vld)
      pp_redir_addr <= redir_addr[`VA_BITS];

always_ff@(posedge clk)
   if(reset) state <= ST_WAIT_RDR;
   else      state <= next;

always_comb
   case(state)
      ST_WAIT_RDR: next = redir_vld ? ST_FETCH : state;

      ST_FETCH:    next =  redir_vld          ? ST_FETCH    :
                           ic_miss_if         ? ST_MISS     :
                          ~all_accepted_if    ? ST_WBUF     :
                          ~next_fetch_tgt_vld ? ST_WAIT_RDR : state ;

      ST_WBUF:     next =  redir_vld          ? ST_FETCH    :
                           all_accepted_if    ? ST_FETCH    : state ;

      ST_MISS:     next =  biu_last           ? ST_REFETCH  : state ; 

      ST_REFETCH:  next = ST_FETCH;
   
      default:     next = ST_WAIT_RDR;
   endcase



assign wait_ibuf_if  = (state == ST_WBUF);
assign refetch_ff    = (state == ST_REFETCH); 
assign fetch_ff      = redir_fetch_ff | next_fetch_tgt_vld | refetch_ff;

assign redir_fetch_ff = redir_vld & ~(state == ST_MISS);

assign fetch_addr_ff = redir_vld  ? redir_addr[`VA_BITS] : // May happen at REFETCH, so first priority
                     pp_redir_vld ? pp_redir_addr        : // May ONLY happen at REFETCH 
                       refetch_ff ? ic_addr_if           : // Normal refetch, no redirect 
               next_fetch_tgt_vld ? next_fetch_addr_ff   : // Advance to next fetch addr
                                    ic_addr_if           ; // Do nothing

assign next_fetch_tgt_vld = (ic_hit_if | wait_ibuf_if) & all_accepted_if &
                            (fetch_tgt_is_b_if ? ~inst_b_is_jmp : ~inst_a_is_jmp); 

always_comb
   if(fetch_tgt_is_b_if) begin
      if(inst_b_is_br)
         next_fetch_addr_ff = pc_br_b_tgt;
      else
         next_fetch_addr_ff = pc_plus_4;
   end
   else begin
      if(inst_a_is_br)
         next_fetch_addr_ff = pc_br_a_tgt;
      else if(inst_b_is_br)
         next_fetch_addr_ff = pc_br_b_tgt;
      else
         next_fetch_addr_ff = pc_plus_8;
   end


icache  icache(   .clk           ( clk                                              ),
                  .reset         ( reset                                            ),

                  .fetch_ff      ( fetch_ff                                         ),     
                  .fetch_addr_ff ( fetch_addr_ff                                    ),

                  .write_ff      ( biu_ack                                          ),     
                  .write_addr_ff ( biu_resp_pkt_xx[`PKT_ADDR]                       ),          
                  .write_data_ff ( biu_resp_pkt_xx[`PKT_DATA]                       ),

                  .ic_addr_if    ( ic_addr_if                                       ),       
                  .ic_data_if    ( ic_data_if                                       ),       
                  .ic_miss_if    ( ic_miss_if                                       ),       
                  .ic_hit_if     ( ic_hit_if                                        ));


assign inst_a_is_br  = is_branch(inst_a_if[31:26]);
assign inst_a_is_jmp = is_jump  (inst_a_if[31:26]);

assign inst_b_is_br  = is_branch(inst_b_if[31:26]);
assign inst_b_is_jmp = is_jump  (inst_b_if[31:26]);

assign fetch_tgt_is_b_if = ic_addr_if[2];

// Don't suppress on redirect: IBUF should discard these instns anyway
assign rdy_a_if = (ic_hit_if | wait_ibuf_if) & ~fetch_tgt_is_b_if;
assign rdy_b_if = (ic_hit_if | wait_ibuf_if) & (fetch_tgt_is_b_if | ~(inst_a_is_br | inst_a_is_jmp));


assign {push_b_if, push_a_if} = (rdy_a_if & rdy_b_if) ? {can_accept_2_if,            can_accept_2_if            } :
                                                        {can_accept_1_if & rdy_b_if, can_accept_1_if & rdy_a_if } ;

assign all_accepted_if = (rdy_a_if & rdy_b_if) ? can_accept_2_if : can_accept_1_if;

ibuf ibuf(  .clk                 ( clk                 ),
            .reset               ( reset               ),
            .clear               ( redir_vld           ),

            .can_accept_1        ( can_accept_1_if     ),
            .can_accept_2        ( can_accept_2_if     ),

            .push_a              ( push_a_if           ),
            .instn_pc_a_if       ( inst_a_addr_if      ),
            .instn_opcode_a_if   ( inst_a_if           ),
            .instn_pr_taken_a_if ( 1'b1                ),

            .push_b              ( push_b_if           ),
            .instn_pc_b_if       ( inst_b_addr_if      ),
            .instn_opcode_b_if   ( inst_b_if           ),
            .instn_pr_taken_b_if ( 1'b1                ),

            .instn_accepted_id   ( instn_accepted_id   ),
            .instn_vld_id        ( instn_vld_id        ),
            .instn_pr_taken_id   ( instn_pr_taken_id   ),
            .instn_opcode_id     ( instn_opcode_id     ),
            .instn_pc_id         ( instn_pc_id_l       ));

assign instn_pc_id = {{`VA_TOP_SIZE{1'b0}}, instn_pc_id_l};

assign ifu_req_pkt_xx[`PKT_VLD ] = ic_miss_if & ~redir_vld; // Don't issue bus requests on simultaneous miss+redirect
assign ifu_req_pkt_xx[`PKT_SIZE] = `REQ_SZ_LINE;
assign ifu_req_pkt_xx[`PKT_LAST] = 1'b1;
assign ifu_req_pkt_xx[`PKT_TYPE] = `PKT_TYPE_FETCH;
assign ifu_req_pkt_xx[`PKT_ADDR] = {ic_addr_if[`PA_SIZE-1:4], 4'd0};
assign ifu_req_pkt_xx[`PKT_DATA] = 64'd0;


function is_branch(input [5:0] opcode);

   is_branch = ( (opcode == 6'h39) |  // Branch if = zero        
                 (opcode == 6'h3E) |  // Branch if >= zero       
                 (opcode == 6'h3F) |  // Branch if > zero        
                 (opcode == 6'h38) |  // Branch if low bit clear 
                 (opcode == 6'h3C) |  // Branch if low bit set   
                 (opcode == 6'h3B) |  // Branch if <= zero       
                 (opcode == 6'h3A) |  // Branch if < zero        
                 (opcode == 6'h3D) |  // Branch if ! zero        
                 (opcode == 6'h30) |  // Unconditional branch    
                 (opcode == 6'h34) ); // Branch to subroutine

endfunction

function is_jump(input [5:0] opcode );

   is_jump = ( (inst_a_if[31:26] == 6'h1A) |  // Jump, JSR, RET, JST_CRE  
               (inst_a_if[31:26] == 6'h00) |  // Trap to PALcode or HALT
               (inst_a_if[31:26] == 6'h1E) ); // Return from exception

endfunction


endmodule
