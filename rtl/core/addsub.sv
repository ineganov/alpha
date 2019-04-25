`include "defines.vh"

module addsub (   input             clk,
                  input             reset,
                  input             enable,

                  input       [2:0] addsub_op,
                  input       [1:0] addsub_scale,
                  input       [2:0] addsub_cmp_op,
    
                  input      [63:0] op_a,
                  input      [63:0] op_b,

                  output reg        rvalid,
                  output reg [63:0] result,
                  output reg        ovflow );

logic [63:0] result_l, sum_64, sum_32, op_a_l;
logic [64:0] op_b_l;
logic [71:0] cmp_bge;
logic  [7:0] cmp_bge_result, cmp_result;
logic        add_ovf_en, add_op32, add_subtract, ovflow64, ovflow32, cout, 
             cmp_enable, cmp_eq, cmp_lt, cmp_lt_u, ovflow_l;

assign {add_ovf_en, add_op32, add_subtract} = addsub_op;

// Scale and negate operands according to opcode
assign op_a_l = op_a << addsub_scale;
assign op_b_l = add_subtract ? (~{1'b0, op_b} + add_subtract) : {1'b0, op_b};

// 64 bit sum with carry out
assign {cout, sum_64} = {1'b0, op_a_l} + op_b_l;

// 32 bit sum is sign-extened to 64
assign sum_32 = {{32{sum_64[31]}}, sum_64[31:0]};


assign ovflow32 = add_ovf_en &  add_op32 & (( op_a[31] &  op_b_l[31] & ~sum_64[31]) |
                                            (~op_a[31] & ~op_b_l[31] &  sum_64[31]) );

assign ovflow64 = add_ovf_en & ~add_op32 & (( op_a[63] &  op_b_l[63] & ~sum_64[63]) |
                                            (~op_a[63] & ~op_b_l[63] &  sum_64[63]) );


genvar byte_num;
generate
   for (byte_num = 0; byte_num < 8; byte_num++) 
   begin : gen_cmp_bge
      assign cmp_bge[byte_num*9+:9] = {1'b0, op_a[byte_num*8+:8]} + {1'b0, ~op_b[byte_num*8+:8]} + 1'b1;
      assign cmp_bge_result[byte_num] = cmp_bge[byte_num*9+8];
   end
endgenerate


// Comparison modes:
// 000 - Comparison disabled
// 001 - EQ
// 010 - LE
// 011 - LT
// 100 - CMPBGE
// 110 - ULE
// 111 - ULT

// Equality comparison done in parallel with addition
assign cmp_eq = ~|(op_a ^ op_b);

// Signed Less Than comparison
assign cmp_lt = sum_64[63];

// Unsigned Less Than comparison
assign cmp_lt_u = cout;

assign cmp_enable = | addsub_cmp_op;

assign cmp_result = ( {8{addsub_cmp_op == `ALU_CMP_BGE}} &          cmp_bge_result     ) |
                    ( {8{addsub_cmp_op == `ALU_CMP_EQ }} & {7'd0, (cmp_eq           )} ) |
                    ( {8{addsub_cmp_op == `ALU_CMP_LE }} & {7'd0, (cmp_eq | cmp_lt  )} ) |
                    ( {8{addsub_cmp_op == `ALU_CMP_LT }} & {7'd0, (         cmp_lt  )} ) |
                    ( {8{addsub_cmp_op == `ALU_CMP_ULE}} & {7'd0, (cmp_eq | cmp_lt_u)} ) |
                    ( {8{addsub_cmp_op == `ALU_CMP_ULT}} & {7'd0, (         cmp_lt_u)} ) ;


assign result_l = cmp_enable ? {56'd0, cmp_result} : 
                    add_op32 ?              sum_32 : 
                                            sum_64 ;

assign ovflow_l = ~cmp_enable & (ovflow32 | ovflow64);


always@(posedge clk)
   if(reset)
      {ovflow, result} <= '0;
   else if (enable)
      {ovflow, result} <= {ovflow_l, result_l};

always@(posedge clk)
   if(reset)
      rvalid <= 1'b0;
   else if (enable)
      rvalid <= 1'b1;
   else if(rvalid)
      rvalid <= 1'b0;


endmodule
