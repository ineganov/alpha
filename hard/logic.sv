`include "defines.vh"

module logical (  input               clk,
                  input               reset,
                  input               enable,

                  input        [63:0] op_a,
                  input        [63:0] op_b,

                  input         [2:0] log_op,
                  input         [2:0] log_cmp_op,

                  output logic        rvalid,
                  output logic        cmp_result,
                  output logic [63:0] result );

logic [63:0] result_l;
logic        is_zero, is_lt_zero, cmp_result_l;


assign result_l = ({64{(log_op == `LOG_NONE )}} &  ( op_a         )) |
                  ({64{(log_op == `LOG_CMOV )}} &  ( op_b         )) |
                  ({64{(log_op == `LOG_AND  )}} &  ( op_a &  op_b )) |
                  ({64{(log_op == `LOG_EQV  )}} & ~( op_a ^  op_b )) |
                  ({64{(log_op == `LOG_ORNOT)}} &  ( op_a | ~op_b )) |
                  ({64{(log_op == `LOG_XOR  )}} &  ( op_a ^  op_b )) |
                  ({64{(log_op == `LOG_BIC  )}} &  ( op_a & ~op_b )) |
                  ({64{(log_op == `LOG_BIS  )}} &  ( op_a |  op_b )) ;


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

always@(posedge clk)
   if(reset)
      {cmp_result, result} <= '0;
   else if (enable)
      {cmp_result, result} <= {cmp_result_l, result_l};

always@(posedge clk)
   if(reset)
      rvalid <= 1'b0;
   else if (enable)
      rvalid <= 1'b1;
   else if(rvalid)
      rvalid <= 1'b0;


endmodule