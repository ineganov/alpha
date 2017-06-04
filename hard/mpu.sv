`include "defines.vh"

`define ALPHA_NAIVE_CTPOP

module mpu (   input               clk,
               input               reset,
               input               enable,

               input        [63:0] op_a,
               input        [63:0] op_b,

               input         [1:0] op_size,
               input         [2:0] mpu_op,

               output logic        mpu_busy,

               output logic        rvalid,
               output logic        ovflow,
               output logic [63:0] result );


logic [127:0] wide_mult_e2, nrw_mult_e2;
logic  [95:0] part_sum_e2;
logic  [63:0] m_al_bl_e1, m_ah_bh_e1, m_ah_bl_e1, m_al_bh_e1, 
              m_al_bl_e2, m_ah_bh_e2, m_ah_bl_e2, m_al_bh_e2;
logic  [63:0] op_a_e1, op_b_e1, mul_rslt_e2, mulh_rslt_e2, result_e2;

logic       [6:0] ctpop_final_e2, ctz_final_e2;
logic   [5*4-1:0] ctpop_rslt_e1, ctpop_rslt_e2;
logic   [5*4-1:0] ctz_rslt_e1, ctz_rslt_e2;

logic   [1:0] op_size_e1, op_size_e2;
logic   [2:0] mpu_op_e1, mpu_op_e2;
logic         en_e1, en_e2, pipe_adv;

// Register E0->E1 for E0 bypass is too late
always_ff@(posedge clk)
  if(enable)
  begin
    op_a_e1    <= op_a;
    op_b_e1    <= op_b;
    op_size_e1 <= op_size;
    mpu_op_e1  <= mpu_op;
  end

// Generate partial multiplications at E1
assign m_ah_bl_e1 = op_a_e1[63:32] * op_b_e1[31:0 ];
assign m_ah_bh_e1 = op_a_e1[63:32] * op_b_e1[63:32];
assign m_al_bl_e1 = op_a_e1[31:0 ] * op_b_e1[31:0 ];
assign m_al_bh_e1 = op_a_e1[31:0 ] * op_b_e1[63:32];

always_ff@(posedge clk)
   if(en_e1)
   begin
      m_al_bl_e2 <= m_al_bl_e1;
      m_ah_bh_e2 <= m_ah_bh_e1;
      m_ah_bl_e2 <= m_ah_bl_e1;
      m_al_bh_e2 <= m_al_bh_e1;
      op_size_e2 <= op_size_e1;
      mpu_op_e2  <= mpu_op_e1;
   end

// Generate full/final products at E2
assign nrw_mult_e2  = m_al_bl_e2;
assign part_sum_e2  = {m_ah_bh_e2, m_al_bl_e2[63:32]} + m_ah_bl_e2 + m_al_bh_e2 ;
assign wide_mult_e2 = {part_sum_e2, m_al_bl_e2[31:0]};

// Generate MULH (128-bit high) result
assign mulh_rslt_e2 = wide_mult_e2[127:64];

assign mul_rslt_e2  = ({64{op_size_e2 == `OP_SZ_QWRD}} &                        wide_mult_e2[63:0] ) |
                      ({64{op_size_e2 == `OP_SZ_LWRD}} & {{32{nrw_mult_e2[31]}}, nrw_mult_e2[31:0]}) ;

// Select the appropriate result
assign result_e2 = ({64{((mpu_op_e2 == `MPU_MUL) | (mpu_op_e2 == `MPU_MULV))}} & mul_rslt_e2) |
                   ({64{ (mpu_op_e2 == `MPU_MULH) }} &           mulh_rslt_e2 ) |
                   ({64{ (mpu_op_e2 == `MPU_CTLZ) }} & {57'd0,   ctz_final_e2}) |
                   ({64{ (mpu_op_e2 == `MPU_CTTZ) }} & {57'd0,   ctz_final_e2}) |
                   ({64{ (mpu_op_e2 == `MPU_CTPP) }} & {57'd0, ctpop_final_e2}) ;


// Result is E3
always_ff@(posedge clk)
   if(reset)       result <= '0;
   else if (en_e2) result <= result_e2;


// Busy signal to the issue unit
assign mpu_busy = enable | en_e1 | en_e2;

// Pipeline gating
assign pipe_adv = enable | en_e1 | en_e2 | rvalid;

always_ff@(posedge clk)
  if(reset)
  begin
    en_e1  <= 1'b0;
    en_e2  <= 1'b0;
    rvalid <= 1'b0;
  end
  else if (pipe_adv)
  begin
    en_e1  <= enable;
    en_e2  <= en_e1;
    rvalid <= en_e2;
  end



logic [63:0] op_br_e1, op_ctz_e1;

vec_reverse #(.W(64)) vec_reverse (.in(op_b_e1), .result(op_br_e1));

assign op_ctz_e1 = (mpu_op_e1 == `MPU_CTTZ) ? op_br_e1 : op_b_e1;


genvar word_num;
generate
   for (word_num = 0; word_num < 4; word_num++) 
   begin : gen_bit_counts

   `ifdef ALPHA_NAIVE_CTPOP
      mpu_count_pop #(.W(16)) mpu_count_pop ( .in(   op_b_e1[word_num*16+:16] ), .result( ctpop_rslt_e1[word_num*5+:5] ));
      mpu_count_lz  #(.W(16)) mpu_count_lz  ( .in( op_ctz_e1[word_num*16+:16] ), .result(   ctz_rslt_e1[word_num*5+:5] ));
   `else
      mpu_count_pop_16 mpu_count_pop   ( .in(   op_b_e1[word_num*16+:16] ), .result( ctpop_rslt_e1[word_num*5+:5] ));
      mpu_count_lz_16  mpu_count_lz_16 ( .in( op_ctz_e1[word_num*16+:16] ), .result(   ctz_rslt_e1[word_num*5+:5] ));
   `endif

   always_ff@(posedge clk)
   if(en_e1)
   begin
      ctpop_rslt_e2[word_num*5+:5] <= ctpop_rslt_e1[word_num*5+:5];
      ctz_rslt_e2  [word_num*5+:5] <= ctz_rslt_e1  [word_num*5+:5];
   end

   end
endgenerate


// Carry bits for 16/64 bit pipelining: 5*(i+1)-1 = [4], [9], [14], [19]
assign ctz_final_e2  = ~ctz_rslt_e2[19] ? {2'd0,   ctz_rslt_e2[3*5 +:5 ]} :
                       ~ctz_rslt_e2[14] ?  7'd16 + ctz_rslt_e2[2*5 +:5 ]  :
                       ~ctz_rslt_e2[9]  ?  7'd32 + ctz_rslt_e2[1*5 +:5 ]  :
                                           7'd48 + ctz_rslt_e2[0*5 +:5 ]  ;


assign ctpop_final_e2 = ctpop_rslt_e2[0 * 5 +: 5] +
                        ctpop_rslt_e2[1 * 5 +: 5] +
                        ctpop_rslt_e2[2 * 5 +: 5] +
                        ctpop_rslt_e2[3 * 5 +: 5] ;


//FIXME:
assign ovflow = 1'b0;

endmodule
//=====================================================================================//
module vec_reverse #( parameter W = 64)
                    ( input  [W-1:0] in,
                      output [W-1:0] result );

genvar bit_num;
generate
   for (bit_num = 0; bit_num < W; bit_num++) 
   begin : gen_bit_counts
      assign result[W - bit_num - 1] = in[bit_num];
   end
endgenerate

endmodule

`ifdef ALPHA_NAIVE_CTPOP
//=====================================================================================//
module mpu_count_pop #( parameter W = 16)
                      ( input              [W-1:0] in, 
                        output logic [$clog2(W):0] result );

always_comb
   begin
   result = '0;

   for(int i = 0; i < W; i++)
      result = result + in[i];
   
   end

endmodule
//=====================================================================================//
module mpu_count_lz #( parameter W = 16)
                     ( input              [W-1:0] in, 
                       output logic [$clog2(W):0] result );

logic done;

always_comb
begin
   result = '0;
   done = '0;

   for(int i = W-1; i >= 0; i--)
   if(~in[i] & ~done)
      result = result + 1'b1;
   else
      done = 1'b1;
end

endmodule
//=====================================================================================//
// module mpu_count_tz #( parameter W = 16)
//                      ( input              [W-1:0] in, 
//                        output logic [$clog2(W):0] result );
// 
// logic done;
// 
// always_comb
// begin
//    result = '0;
//    done = '0;
// 
//    for(int i = 0; i < W; i++)
//    if(~in[i] & ~done)
//       result = result + 1'b1;
//    else
//       done = 1'b1;
// end
// 
// endmodule
//=====================================================================================//
`else

module mpu_count_lz_16 (input [15:0] in,
                        output [4:0] result );

logic [11:0] s;

genvar q_num;
generate
   for (q_num = 0; q_num < 4; q_num++) 
   begin : gen_nibbles
      always_comb
         case(in[q_num*4+:4])

            4'b0000: s[q_num*3+:3] = 3'd4;
            
            4'b0001: s[q_num*3+:3] = 3'd3;

            4'b0010,
            4'b0011: s[q_num*3+:3] = 3'd2;

            4'b0100,
            4'b0101,
            4'b0110,
            4'b0111: s[q_num*3+:3] = 3'd1;

            default: s[q_num*3+:3] = 3'd0;
         endcase
   end
endgenerate

// 4, 4, 4, x => 12 + x
// 4, 4, y, x =>  8 + y
// 4, z, y, x =>  4 + z
// t, z, y, x =>  0 + t
// [2], [5], [8], [11]

assign result = ~s[11] ? {1'b0, s[3*3+:3]} :
                 ~s[8] ? 5'd4 + s[2*3+:3]  :
                 ~s[5] ? 5'd8 + s[1*3+:3]  :
                        5'd12 + s[0*3+:3]  ;

endmodule

//=====================================================================================//

module mpu_count_pop_16 (input [15:0] in,
                         output [4:0] result );

logic [11:0] s;

genvar q_num;
generate
   for (q_num = 0; q_num < 4; q_num++) 
   begin : gen_nibbles
      always_comb
         case(in[q_num*4+:4])
            4'b0000: s[q_num*3+:3] = 3'd0;
      
            4'b0001,
            4'b0010,
            4'b0100,
            4'b1000: s[q_num*3+:3] = 3'd1;
      
            4'b0011,
            4'b0101,
            4'b1001,
            4'b0110,
            4'b1010,
            4'b1100: s[q_num*3+:3] = 3'd2;
      
            4'b1110,
            4'b1101,
            4'b1011,
            4'b0111: s[q_num*3+:3] = 3'd3;
      
            4'b1111: s[q_num*3+:3] = 3'd4;
      
            default: s[q_num*3+:3] = 3'd4;
         endcase
   end
endgenerate

assign result = s[3*3+:3] + 
                s[2*3+:3] +
                s[1*3+:3] +
                s[0*3+:3] ;

endmodule
`endif

//=====================================================================================//
