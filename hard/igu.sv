`include "defines.vh"

module issuegrad (   input                    clk,
                     input                    reset, 
     
                     // Decode interface
                     input                    instn_vld_id,
                     input             [63:0] instn_pc_id,
                     input      [`FUNIT_BITS] instn_funit_id,
                     input              [4:0] reg_dst_id,
                     input                    no_rf_upd_id,
                     input                    log_cond_upd_id,
                     input             [31:0] instn_opcode_id,
                     output                   i_issue_id,
     
                     // Functional unit outputs
                     input                    adds_rvalid_e1,
                     input                    adds_ovflow_e1,
                     input             [63:0] adds_result_e1,
     
                     input                    log_rvalid_e1,
                     input                    cmp_result_e1,
                     input             [63:0] log_result_e1,
     
                     input                    shm_rvalid_e1,
                     input             [63:0] shm_result_e1,
     
                     input                    lsu_busy_xx,
                     input                    lsu_valid_e1,
                     input                    lsu_replay_e1,
                     input             [63:0] lsu_result_e1,
     
                     input                    ctu_rvalid_e1,
                     input             [63:0] ctu_result_e1,
                     input                    ctu_force_rdr_e1,
                     input             [63:0] ctu_next_pc_e1,
     
                     input                    mpu_busy_xx,
                     input                    mpu_rvalid_e2,
                     input                    mpu_ovflow_e2,
                     input             [63:0] mpu_result_e2,
     
                     input                    cpr_rvalid_e1,
                     input           [63:0]   cpr_result_e1,

                     // Fetch direction outputs
                     output                   redir_vld_xx,
                     output            [63:0] redir_addr_xx,

                     // Funit enables
                     output logic [`FUNIT_BITS] funit_en_e0,

                     // Exception inputs
                     input                    e_reserved_id,
                     input                    e_halt_id,
                     input                    e_callpal_id,
                     input                    hw_ret_id,

                     // Graduation outputs
                     output                   rf_wen_gr,
                     output             [4:0] rf_waddr_gr,
                     output            [63:0] rf_wdata_gr,
                     output logic             instn_grad_gr,
                     output logic             squash_result_gr,

                     // Exceptions
                     output                   e_enter_gr,
                     output                   e_exit_gr,
                     output            [63:0] n_epc_gr,
                     output            [31:0] n_inst_gr,
                     output [`CPR_CAUSE_BITS] n_cause_gr );


logic        post_reset, reset_r;
logic        instn_cmplt_gr;
logic        cpu_halt_xx;

logic        i_valid_e0, i_valid_e1;
logic [63:0] instn_pc_e0, instn_pc_e1;
logic [31:0] instn_opcode_e0, instn_opcode_e1;
logic        no_rf_upd_e0, no_rf_upd_e1, log_cond_upd_e0, log_cond_upd_e1;
logic        e_reserved_e0, e_halt_e0, e_callpal_e0, hw_ret_e0;
logic        e_reserved_e1, e_halt_e1, e_callpal_e1, hw_ret_e1;
logic  [4:0] reg_dst_e0, reg_dst_e1;
logic [63:0] next_pc_xx;

wire         exc_cmplt_e1  = i_valid_e1 & ( e_reserved_e1 | e_halt_e1 | e_callpal_e1 );
wire         eret_cmplt_e1 = i_valid_e1 &   hw_ret_e1;


assign instn_cmplt_gr  = adds_rvalid_e1 | log_rvalid_e1 | shm_rvalid_e1 | 
                         lsu_valid_e1   | ctu_rvalid_e1 | mpu_rvalid_e2 |
                         cpr_rvalid_e1  ;


assign i_issue_id = instn_vld_id 
                    & ~(lsu_busy_xx & instn_funit_id[`LSU_EN])
                    & ~mpu_busy_xx
                    & ~cpu_halt_xx;

always_ff@(posedge clk)
   if(reset | redir_vld_xx) i_valid_e0 <= 1'b0;
   else                     i_valid_e0 <= i_issue_id;

always_ff@(posedge clk)
   if(reset | redir_vld_xx) i_valid_e1 <= 1'b0;
   else                     i_valid_e1 <= i_valid_e0;


// ID/E0 reg
always_ff@(posedge clk)
   if(i_issue_id) 
   begin
      reg_dst_e0      <= reg_dst_id;
      no_rf_upd_e0    <= no_rf_upd_id;
      log_cond_upd_e0 <= log_cond_upd_id;
      instn_pc_e0     <= instn_pc_id;
      instn_opcode_e0 <= instn_opcode_id;
      e_reserved_e0   <= e_reserved_id;
      e_halt_e0       <= e_halt_id;
      e_callpal_e0    <= e_callpal_id;
      hw_ret_e0       <= hw_ret_id;
   end

// E0/E1 reg
always_ff@(posedge clk)
   if(i_valid_e0 & ~redir_vld_xx) 
   begin
      reg_dst_e1      <= reg_dst_e0;
      no_rf_upd_e1    <= no_rf_upd_e0;
      log_cond_upd_e1 <= log_cond_upd_e0;
      instn_pc_e1     <= instn_pc_e0;
      instn_opcode_e1 <= instn_opcode_e0;
      e_reserved_e1   <= e_reserved_e0;
      e_halt_e1       <= e_halt_e0;
      e_callpal_e1    <= e_callpal_e0;
      hw_ret_e1       <= hw_ret_e0;
   end



always_ff@(posedge clk)
   if (reset) 
      cpu_halt_xx <= 1'b0;
   else if (e_halt_e1 & i_valid_e1)
      cpu_halt_xx <= 1'b1;

// Squash result if redirect happens at e0 (let it run to completion 1-N cycles, then ignore result)
always_ff@(posedge clk)
   if(reset)
      squash_result_gr <= 1'b0;
   else if(i_valid_e0 & redir_vld_xx)
      squash_result_gr <= 1'b1;
   else if(instn_cmplt_gr)
      squash_result_gr <= 1'b0;



// RF write
assign rf_wen_gr   = instn_grad_gr & ~no_rf_upd_e1 & (~log_cond_upd_e1 | cmp_result_e1) & (reg_dst_e1 != 5'd31);
assign rf_waddr_gr = reg_dst_e1;
assign rf_wdata_gr = ({64{ adds_rvalid_e1  }} & adds_result_e1 ) |
                     ({64{ log_rvalid_e1   }} &  log_result_e1 ) |
                     ({64{ shm_rvalid_e1   }} &  shm_result_e1 ) |
                     ({64{ lsu_valid_e1    }} &  lsu_result_e1 ) |
                     ({64{ ctu_rvalid_e1   }} &  ctu_result_e1 ) |
                     ({64{ mpu_rvalid_e2   }} &  mpu_result_e2 ) |
                     ({64{ cpr_rvalid_e1   }} &  cpr_result_e1 ) ;

// Funit dispatch
always_ff@(posedge clk)
   if(reset | ~i_issue_id | redir_vld_xx)
      funit_en_e0 <= `FUNIT_NONE;
   else if(i_issue_id)
      funit_en_e0 <= instn_funit_id;


// Fetch direction logic
always@(posedge clk)
   if(reset | post_reset)
      reset_r <= reset;

assign post_reset = reset_r & ~reset;



assign redir_vld_xx  = post_reset | (i_valid_e1 & (lsu_replay_e1 | ctu_force_rdr_e1) & ~((e_halt_e1 & i_valid_e1) | cpu_halt_xx)) ;
assign redir_addr_xx = lsu_replay_e1 ? instn_pc_e1 : next_pc_xx;

always_comb
   if(post_reset)
      next_pc_xx = `CPU_RESET_ADDR;
   else if(exc_cmplt_e1)
      next_pc_xx = `CPU_EXC_ADDR;
   else
      next_pc_xx = ctu_next_pc_e1;


// FIXME: only works for fully interlocked processor
assign n_epc_gr   = instn_pc_id;
assign n_inst_gr  = instn_opcode_id;
assign n_cause_gr = {e_halt_e1, e_reserved_e1, e_callpal_e1};

assign e_enter_gr = exc_cmplt_e1;
assign e_exit_gr  = eret_cmplt_e1;

assign instn_grad_gr = instn_cmplt_gr & ~squash_result_gr & ~lsu_replay_e1;

`ifdef MODEL_TECH

instn_decode nonsynth_idecode(   .instn         ( instn_opcode_e1 ),
                                 .funit         (                 ),
                                 .reg_a         (                 ),
                                 .reg_b         (                 ),
                                 .reg_dst       (                 ),
                                 .literal       (                 ),
                                 .no_rf_upd     (                 ),
                                 .use_ltrl_8    (                 ),
                                 .use_ltrl_16   (                 ),
                                 .use_ltrl_20   (                 ),
                                 .addsub_op     (                 ),
                                 .addsub_scale  (                 ),
                                 .addsub_cmp_op (                 ),
                                 .log_op        (                 ),
                                 .log_cmp_op    (                 ),
                                 .log_cond_upd  (                 ),
                                 .ctu_op        (                 ),
                                 .shmsk_op      (                 ),
                                 .op_size       (                 ),
                                 .mpu_op        (                 ),
                                 .lsu_op        (                 ),
                                 .op_llsc       (                 ),
                                 .cpr_op        (                 ), 
                                 .e_reserved    (                 ), 
                                 .e_halt        (                 ), 
                                 .e_callpal     (                 ), 
                                 .hw_ret        (                 ) );


//-----------simulation-only----------------
function string get_rname(input [4:0] idx);
begin
   case(idx)
   5'd00: get_rname = "$v0";
   5'd01: get_rname = "$t0";
   5'd02: get_rname = "$t1";
   5'd03: get_rname = "$t2";
   5'd04: get_rname = "$t3";
   5'd05: get_rname = "$t4";
   5'd06: get_rname = "$t5";
   5'd07: get_rname = "$t6";
   5'd08: get_rname = "$t7";
   5'd09: get_rname = "$s0";
   5'd10: get_rname = "$s1";
   5'd11: get_rname = "$s2";
   5'd12: get_rname = "$s3";
   5'd13: get_rname = "$s4";
   5'd14: get_rname = "$s5";
   5'd15: get_rname = "$fp";
   5'd16: get_rname = "$a0";
   5'd17: get_rname = "$a1";
   5'd18: get_rname = "$a2";
   5'd19: get_rname = "$a3";
   5'd20: get_rname = "$a4";
   5'd21: get_rname = "$a5";
   5'd22: get_rname = "$t8";
   5'd23: get_rname = "$t9";
   5'd24: get_rname = "$t10";
   5'd25: get_rname = "$t11";
   5'd26: get_rname = "$ra";
   5'd27: get_rname = "$t12";
   5'd28: get_rname = "$at";
   5'd29: get_rname = "$gp";
   5'd30: get_rname = "$sp";
   5'd31: get_rname = "$zero";
   endcase
end
endfunction

always_ff@ (posedge clk)
   begin
      if     (exc_cmplt_e1 )
         $display("[%8tps] %08x_%08x: <%8s> ----EXCEPTION----", $time,
                                                                instn_pc_e1[63:32], 
                                                                instn_pc_e1[31:0],
                                                                nonsynth_idecode.decoded_instn.name());
      else if(eret_cmplt_e1 )
         $display("[%8tps] %08x_%08x: <%8s> ------ERET-------", $time,
                                                                instn_pc_e1[63:32], 
                                                                instn_pc_e1[31:0],
                                                                nonsynth_idecode.decoded_instn.name());
      else if(instn_grad_gr & ~rf_wen_gr)
         $display("[%8tps] %08x_%08x: <%8s> --------_--------", $time,
                                                                instn_pc_e1[63:32], 
                                                                instn_pc_e1[31:0],
                                                                nonsynth_idecode.decoded_instn.name());
      else if(instn_grad_gr & rf_wen_gr)
         $display("[%8tps] %08x_%08x: <%8s> %08x_%08x --> %s (r%02d)", $time,
                                                                       instn_pc_e1[63:32], 
                                                                       instn_pc_e1[31:0],
                                                                       nonsynth_idecode.decoded_instn.name(),
                                                                       rf_wdata_gr[63:32],
                                                                       rf_wdata_gr[31:0],
                                                                       get_rname(rf_waddr_gr),
                                                                       rf_waddr_gr);

   end

`endif

endmodule
