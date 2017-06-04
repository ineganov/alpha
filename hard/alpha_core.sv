`include "defines.vh"

module alpha_core (  input             clk,
                     input             reset,

                     output  [`PKT_BITS] mem_req_pkt_xx,
                     input               mem_req_ack_xx,
                     input   [`PKT_BITS] mem_resp_pkt_xx );


// IGU signals
logic               redir_vld_xx;
logic        [63:0] redir_addr_xx;
logic               i_issue_id, no_rf_upd_id;
logic               rf_wen_gr;
logic         [4:0] rf_waddr_gr;
logic        [63:0] rf_wdata_gr; 
logic [`FUNIT_BITS] instn_funit_id, funit_en_e0;
logic               use_ltrl_8_id, use_ltrl_16_id, use_ltrl_20_id, use_ltrl_e0; 
logic        [20:0] literal_id;

// IFU signals
logic           instn_vld_id;
logic    [31:0] instn_opcode_id;
logic    [63:0] instn_pc_id;


// BIU signals
logic [`PKT_BITS] ifu_req_pkt_xx;
logic [`PKT_BITS] lsu_req_pkt_xx;
logic             lsu_req_ack_xx;
logic [`PKT_BITS] biu_resp_pkt_xx;



// Regfile signals
logic   [4:0]  rd_addr_a_id;
logic   [4:0]  rd_addr_b_id;
logic   [4:0]  reg_dst_id;
logic  [63:0]  rd_data_a_e0;
logic  [63:0]  rd_data_b_e0;


// ADDSUB signals
logic  [2:0] addsub_op_id, addsub_op_e0;
logic  [1:0] addsub_scale_id, addsub_scale_e0;
logic  [2:0] addsub_cmp_op_id, addsub_cmp_op_e0;
logic        adds_rvalid_e1;
logic [63:0] adds_result_e1;
logic        adds_ovflow_e1;


// LOGICAL signals
logic  [2:0] log_op_id, log_op_e0; 
logic  [2:0] log_cmp_op_id, log_cmp_op_e0; 
logic        log_cond_upd_id; 
logic        log_rvalid_e1;
logic        cmp_result_e1;
logic [63:0] log_result_e1;


// SHIFT&MASK signals
logic  [3:0] shmsk_op_id, shmsk_op_e0;
logic  [1:0] op_size_id, op_size_e0;
logic        shm_rvalid_e1;
logic [63:0] shm_result_e1;


// LOADSTORE controls
logic  [2:0] lsu_op_id, lsu_op_e0;
logic        op_llsc_id, op_llsc_e0;
logic        lsu_busy_xx;
logic        lsu_valid_e1;
logic        lsu_replay_e1;
logic [63:0] lsu_result_e1;

logic [20:0] lit_op_b_id, lit_op_b_e0;
logic [63:0] op_a_final_e0;
logic [63:0] op_b_final_e0;

// MPU Signals
logic  [2:0] mpu_op_id, mpu_op_e0;
logic        mpu_busy_xx;
logic        mpu_rvalid_e2;
logic        mpu_ovflow_e2;
logic [63:0] mpu_result_e2;


// CTU Signals
logic        en_ctu_e0;
logic        br_pr_taken_id, br_pr_taken_e0;
logic  [1:0] ctu_op_id, ctu_op_e0;
logic [63:0] pc_plus_4_e0;
logic        ctu_rvalid_e1;
logic        ctu_force_rdr_e1;
logic [63:0] ctu_result_e1;
logic [63:0] ctu_next_pc_e1;



// CPR Signals
logic        e_enter_gr, e_exit_gr, instn_grad_gr, squash_result_gr;
logic        cpr_op_id, cpr_op_e0;    
logic        cpr_rvalid_e1;
logic [63:0] cpr_result_e1;

// Exception Signals
logic                   e_reserved_id;
logic                   e_halt_id;
logic                   e_callpal_id; 
logic                   hw_ret_id;
logic            [63:0] n_epc_gr;
logic            [31:0] n_inst_gr;
logic [`CPR_CAUSE_BITS] n_cause_gr;


ifu                     ifu(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                                   
                              .redir_vld         ( redir_vld_xx                   ),
                              .redir_addr        ( redir_addr_xx                  ),
                                   
                              .ifu_req_pkt_xx    ( ifu_req_pkt_xx                 ),
                              .biu_resp_pkt_xx   ( biu_resp_pkt_xx                ),
                                   
                              .instn_accepted_id ( i_issue_id                     ),
                              .instn_vld_id      ( instn_vld_id                   ),
                              .instn_pr_taken_id ( br_pr_taken_id                 ),
                              .instn_opcode_id   ( instn_opcode_id                ), 
                              .instn_pc_id       ( instn_pc_id                    ) );




instn_decode        idecode(  .instn             ( instn_opcode_id                ),
                          
                              .funit             ( instn_funit_id                 ),
                          
                              .reg_a             ( rd_addr_a_id                   ),
                              .reg_b             ( rd_addr_b_id                   ),
                              .reg_dst           ( reg_dst_id                     ),
                              .literal           ( literal_id                     ),
                              .no_rf_upd         ( no_rf_upd_id                   ),
                              .use_ltrl_8        ( use_ltrl_8_id                  ),
                              .use_ltrl_16       ( use_ltrl_16_id                 ),
                              .use_ltrl_20       ( use_ltrl_20_id                 ),
                          
                              .addsub_op         ( addsub_op_id                   ),
                              .addsub_scale      ( addsub_scale_id                ),
                              .addsub_cmp_op     ( addsub_cmp_op_id               ),
                          
                              .log_op            ( log_op_id                      ),
                              .log_cmp_op        ( log_cmp_op_id                  ),
                              .log_cond_upd      ( log_cond_upd_id                ),
                          
                              .ctu_op            ( ctu_op_id                      ),
                          
                              .shmsk_op          ( shmsk_op_id                    ),
                              .op_size           ( op_size_id                     ),
                          
                              .mpu_op            ( mpu_op_id                      ),
                          
                              .lsu_op            ( lsu_op_id                      ),
                              .op_llsc           ( op_llsc_id                     ),
                          
                              .cpr_op            ( cpr_op_id                      ),
                              .e_reserved        ( e_reserved_id                  ),
                              .e_halt            ( e_halt_id                      ),    
                              .e_callpal         ( e_callpal_id                   ), 
                              .hw_ret            ( hw_ret_id                      ) );
    
                
issuegrad               igu(  .clk               ( clk                            ),
                              .reset             ( reset                          ), 
         
                              // Decode interf   ace
                              .instn_vld_id      ( instn_vld_id                   ),
                              .instn_pc_id       ( instn_pc_id                    ),
                              .instn_funit_id    ( instn_funit_id                 ),
                              .reg_dst_id        ( reg_dst_id                     ),
                              .no_rf_upd_id      ( no_rf_upd_id                   ),
                              .log_cond_upd_id   ( log_cond_upd_id                ),
                              .instn_opcode_id   ( instn_opcode_id                ),
                              .i_issue_id        ( i_issue_id                     ),
         
                              // Functional unit outputs                
                              .adds_rvalid_e1    ( adds_rvalid_e1                 ),
                              .adds_ovflow_e1    ( adds_ovflow_e1                 ),
                              .adds_result_e1    ( adds_result_e1                 ),
                            
                              .log_rvalid_e1     ( log_rvalid_e1                  ),
                              .cmp_result_e1     ( cmp_result_e1                  ),
                              .log_result_e1     ( log_result_e1                  ),
                            
                              .shm_rvalid_e1     ( shm_rvalid_e1                  ),
                              .shm_result_e1     ( shm_result_e1                  ),
                            
                              .lsu_busy_xx       ( lsu_busy_xx                    ),
                              .lsu_valid_e1      ( lsu_valid_e1                   ),
                              .lsu_replay_e1     ( lsu_replay_e1                  ),
                              .lsu_result_e1     ( lsu_result_e1                  ),
                            
                              .ctu_rvalid_e1     ( ctu_rvalid_e1                  ),
                              .ctu_result_e1     ( ctu_result_e1                  ),
                              .ctu_force_rdr_e1  ( ctu_force_rdr_e1               ),
                              .ctu_next_pc_e1    ( ctu_next_pc_e1                 ),
                            
                              .mpu_busy_xx       ( mpu_busy_xx                    ),
                              .mpu_rvalid_e2     ( mpu_rvalid_e2                  ),
                              .mpu_ovflow_e2     ( mpu_ovflow_e2                  ),
                              .mpu_result_e2     ( mpu_result_e2                  ),

                              .cpr_rvalid_e1     ( cpr_rvalid_e1                  ),   
                              .cpr_result_e1     ( cpr_result_e1                  ),   
         
                              // Fetch direction outputs
                              .redir_vld_xx      ( redir_vld_xx                   ),
                              .redir_addr_xx     ( redir_addr_xx                  ),
         
                              // Funit enables
                              .funit_en_e0       ( funit_en_e0                    ),

                              // Exception inputs
                              .e_reserved_id     ( e_reserved_id                  ),
                              .e_halt_id         ( e_halt_id                      ),    
                              .e_callpal_id      ( e_callpal_id                   ), 
                              .hw_ret_id         ( hw_ret_id                      ),
     
                              // Graduation outputs
                              .rf_wen_gr         ( rf_wen_gr                      ),
                              .rf_waddr_gr       ( rf_waddr_gr                    ),
                              .rf_wdata_gr       ( rf_wdata_gr                    ),
                              .instn_grad_gr     ( instn_grad_gr                  ),
                              .squash_result_gr  ( squash_result_gr               ),

                              .e_enter_gr        ( e_enter_gr                     ),
                              .e_exit_gr         ( e_exit_gr                      ),
                              .n_epc_gr          ( n_epc_gr                       ),
                              .n_inst_gr         ( n_inst_gr                      ),
                              .n_cause_gr        ( n_cause_gr                     ));


     
ctu                     ctu(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                              .enable            ( funit_en_e0[`CTU_EN]           ),
            
                              .ctu_op            ( ctu_op_e0                      ),
                              .log_cmp_op        ( log_cmp_op_e0                  ),
            
                              .op_a              ( rd_data_a_e0                   ),
                              .op_b              ( rd_data_b_e0                   ),
                              .pc_plus_4         ( pc_plus_4_e0                   ),
                              .literal           ( lit_op_b_e0                    ),
                              .pr_taken          ( br_pr_taken_e0                 ),
            
                              .rvalid            ( ctu_rvalid_e1                  ),
                              .result            ( ctu_result_e1                  ),
                              .force_rdr         ( ctu_force_rdr_e1               ),
                              .next_pc           ( ctu_next_pc_e1                 ));

regfile             regfile(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                              .rd_addr_a         ( rd_addr_a_id                   ),
                              .rd_addr_b         ( rd_addr_b_id                   ),
                              .wr_addr           ( rf_waddr_gr                    ),
                              .wr_data           ( rf_wdata_gr                    ),
                              .wr_en             ( rf_wen_gr                      ),
                              .rd_data_a         ( rd_data_a_e0                   ),
                              .rd_data_b         ( rd_data_b_e0                   ));



addsub               addsub(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                              .enable            ( funit_en_e0[`ALU_EN]           ),
                  
                              .addsub_op         ( addsub_op_e0                   ),
                              .addsub_scale      ( addsub_scale_e0                ),   
                              .addsub_cmp_op     ( addsub_cmp_op_e0               ),    
                                
                              .op_a              ( op_a_final_e0                  ),
                              .op_b              ( op_b_final_e0                  ),
                                                  
                              .rvalid            ( adds_rvalid_e1                 ),
                              .result            ( adds_result_e1                 ),
                              .ovflow            ( adds_ovflow_e1                 ));


logical             logical(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                              .enable            ( funit_en_e0[`LOG_EN]           ),
             
                              .op_a              ( op_a_final_e0                  ),
                              .op_b              ( op_b_final_e0                  ),
                              
                              .log_op            ( log_op_e0                      ),
                              .log_cmp_op        ( log_cmp_op_e0                  ),
                              
                              .rvalid            ( log_rvalid_e1                  ),
                              .cmp_result        ( cmp_result_e1                  ),
                              .result            ( log_result_e1                  ));


shift_and_mask       shmask(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                              .enable            ( funit_en_e0[`SHM_EN]           ),
                                 
                              .op_a              ( op_a_final_e0                  ),
                              .op_b              ( op_b_final_e0                  ),
                                 
                              .shmsk_op          ( shmsk_op_e0                    ),
                              .op_size           ( op_size_e0                     ),
                                 
                              .rvalid            ( shm_rvalid_e1                  ),
                              .result            ( shm_result_e1                  ));



mpu                     mpu(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                              .enable            ( funit_en_e0[`MPU_EN]           ),
                              .op_a              ( op_a_final_e0                  ),
                              .op_b              ( op_b_final_e0                  ),
                              .op_size           ( op_size_e0                     ),
                              .mpu_op            ( mpu_op_e0                      ),
                              .mpu_busy          ( mpu_busy_xx                    ),
                              .rvalid            ( mpu_rvalid_e2                  ),
                              .ovflow            ( mpu_ovflow_e2                  ),
                              .result            ( mpu_result_e2                  ));




loadstore               lsu(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                              .enable            ( funit_en_e0[`LSU_EN]           ),
                    
                              .op_a              ( op_a_final_e0                  ),
                              .op_base           ( rd_data_b_e0                   ),
                              .op_offset         ( lit_op_b_e0[15:0]              ),
                       
                              .lsu_op            ( lsu_op_e0                      ),   
                              .op_size           ( op_size_e0                     ),    
                              .op_llsc           ( op_llsc_e0                     ),
                       
                              .lsu_busy          ( lsu_busy_xx                    ),     
                              .rvalid            ( lsu_valid_e1                   ),
                              .replay            ( lsu_replay_e1                  ),  
                              .result            ( lsu_result_e1                  ),
                              .squash_result_gr  ( squash_result_gr               ),

                              .kill_ll           ( e_exit_gr                      ),

                       
                              .lsu_req_pkt_xx    ( lsu_req_pkt_xx                 ),
                              .biu_resp_pkt_xx   ( biu_resp_pkt_xx                ),
                              .lsu_req_ack_xx    ( lsu_req_ack_xx                 ));      


biu                     biu(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                     
                              .ifu_req_pkt_xx    ( ifu_req_pkt_xx                 ),
                              .lsu_req_pkt_xx    ( lsu_req_pkt_xx                 ),
                              .lsu_req_ack_xx    ( lsu_req_ack_xx                 ),
                              .biu_resp_pkt_xx   ( biu_resp_pkt_xx                ),
                     
                              .mem_req_pkt_xx    ( mem_req_pkt_xx                 ),
                              .mem_req_ack_xx    ( mem_req_ack_xx                 ),
                              .mem_resp_pkt_xx   ( mem_resp_pkt_xx                ));



cpr                     cpr(  .clk               ( clk                            ),
                              .reset             ( reset                          ),
                              .enable            ( funit_en_e0[`CPR_EN]           ),
                                        
                              .cpr_op            ( cpr_op_e0                      ),
                              .cpr_idx           ( lit_op_b_e0[`CPR_IDX_BITS]     ),
                              .cpr_wdata         ( op_b_final_e0                  ),
                                        
                              .e_enter           ( e_enter_gr                     ),
                              .e_exit            ( e_exit_gr                      ),
                              .n_epc             ( n_epc_gr                       ),
                              .n_inst            ( n_inst_gr                      ),
                              .n_cause           ( n_cause_gr                     ),
                              .instn_grad_gr     ( instn_grad_gr                  ),
             
                              .rvalid            ( cpr_rvalid_e1                  ),
                              .result            ( cpr_result_e1                  ));



always_ff@(posedge clk)
   if(i_issue_id)
   begin
     addsub_op_e0     <= addsub_op_id;
     addsub_scale_e0  <= addsub_scale_id;
     addsub_cmp_op_e0 <= addsub_cmp_op_id;

     log_op_e0        <= log_op_id; 
     log_cmp_op_e0    <= log_cmp_op_id; 
     
     shmsk_op_e0      <= shmsk_op_id;
     op_size_e0       <= op_size_id;
     
     lsu_op_e0        <= lsu_op_id;
     op_size_e0       <= op_size_id;
     op_llsc_e0       <= op_llsc_id;

     ctu_op_e0        <= ctu_op_id;
     pc_plus_4_e0     <= instn_pc_id + 3'd4;

     mpu_op_e0        <= mpu_op_id;

     lit_op_b_e0      <= lit_op_b_id;
     use_ltrl_e0      <= use_ltrl_8_id; // Substitute op_b only with 8-bit literals

     cpr_op_e0        <= cpr_op_id;

     br_pr_taken_e0   <= br_pr_taken_id;
   end

assign lit_op_b_id = ({21{use_ltrl_20_id}} &         literal_id        ) |
                     ({21{use_ltrl_16_id}} &  {5'd0, literal_id[15:0] }) |
                     ({21{use_ltrl_8_id }} & {13'd0, literal_id[20:13]}) ;


assign op_a_final_e0 = rd_data_a_e0;  
assign op_b_final_e0 = use_ltrl_e0 ? {{56{1'b0}}, lit_op_b_e0[7:0]} : rd_data_b_e0;

endmodule
