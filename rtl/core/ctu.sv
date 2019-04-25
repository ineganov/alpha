`include "defines.vh"

module ctu (   input               clk,
               input               reset,
               input               enable,

               input         [1:0] ctu_op,
               input         [2:0] log_cmp_op,
               input        [63:0] op_a,
               input        [63:0] op_b,
               input        [63:0] pc_plus_4,
               input        [20:0] literal,
               input               pr_taken,

               output logic        rvalid,
               output logic [63:0] result,

               output logic        force_rdr,
               output logic [63:0] next_pc );

logic        is_zero, is_lt_zero, cmp_result_l, force_rdr_l;
logic        use_next_pc, use_pc_rel, use_abs;
logic [63:0] offset, next_pc_l;

always@(posedge clk)
   if(enable)
      result  <= pc_plus_4; // Return address for branches is the only result of this unit

always@(posedge clk)
   if(reset) next_pc <= '0;
   else      next_pc <= next_pc_l;

always@(posedge clk)
   if(reset) force_rdr <= '0;
   else      force_rdr <= force_rdr_l;

assign offset = { {41{literal[20]}}, literal, 2'b00};


assign use_next_pc = ((ctu_op == `CTU_PCR_C) & ~cmp_result_l) | (ctu_op == `CTU_NONE ); // Branch not taken or regular instn
assign use_pc_rel  = ((ctu_op == `CTU_PCR_C) &  cmp_result_l) | (ctu_op == `CTU_PCR_U); // Branch taken
assign use_abs     =  (ctu_op == `CTU_ABS);

assign next_pc_l = ({64{use_next_pc}} &         pc_plus_4   ) |
                   ({64{use_pc_rel }} & (pc_plus_4 + offset)) |
                   ({64{use_abs    }} &  {op_b[63:2], 2'b00}) ;


assign is_zero = ~|op_a;
assign is_lt_zero = op_a[63];

assign cmp_result_l = (( log_cmp_op == `LOG_CMP_EQ  ) &   is_zero                ) |
                      (( log_cmp_op == `LOG_CMP_GE  ) &  ~is_lt_zero             ) |
                      (( log_cmp_op == `LOG_CMP_GT  ) & (~is_zero & ~is_lt_zero )) |
                      (( log_cmp_op == `LOG_CMP_LBC ) &  ~op_a[0]                ) |
                      (( log_cmp_op == `LOG_CMP_LBS ) &   op_a[0]                ) |
                      (( log_cmp_op == `LOG_CMP_LE  ) & ( is_zero |  is_lt_zero )) |
                      (( log_cmp_op == `LOG_CMP_LT  ) &   is_lt_zero             ) |
                      (( log_cmp_op == `LOG_CMP_NE  ) &  ~is_zero                ) ;

assign force_rdr_l = (ctu_op == `CTU_PCR_U) | (ctu_op == `CTU_ABS) |
                     ((ctu_op == `CTU_PCR_C) & (cmp_result_l ^ pr_taken));

always@(posedge clk)
   if(reset)
      rvalid <= 1'b0;
   else if (enable)
      rvalid <= 1'b1;
   else if(rvalid)
      rvalid <= 1'b0;


endmodule
