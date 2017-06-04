`include "defines.vh"

module shift_and_mask ( input               clk,
                        input               reset,
                        input               enable,
       
                        input        [63:0] op_a,
                        input        [63:0] op_b,
       
                        input         [3:0] shmsk_op,
                        input         [1:0] op_size,

                        output logic        rvalid,
                        output logic [63:0] result );


// SEXT       4'd0
// SHM_SRL    4'd1
// SHM_SRA    4'd2
// SHM_SLL    4'd3
// EXT_L      4'd4
// EXT_H      4'd5
// INS_L      4'd6
// INS_H      4'd7
// MSK_L      4'd8
// MSK_H      4'd9
// SHM_ZAP    4'd10   
// SHM_ZAPNOT 4'd11

logic [63:0] result_l;
logic [63:0] op_shifted;
logic [63:0] op_sext;
logic [15:0] byte_mask, byte_mask_shifted;
logic  [2:0] mask_shamt;

logic  [5:0] op_a_shamt;
logic        op_a_rshft;

logic [63:0] sext_mask;
logic [63:0] zap_n_expanded;
logic  [7:0] zap_n_mask;

assign byte_mask = (op_size == `OP_SZ_BYTE) ? 16'b0000_0000_0000_0001 :
                   (op_size == `OP_SZ_WORD) ? 16'b0000_0000_0000_0011 :
                   (op_size == `OP_SZ_LWRD) ? 16'b0000_0000_0000_1111 :
                 /*(op_size == `OP_SZ_QWRD)*/ 16'b0000_0000_1111_1111 ;

// opb[2:0] for INS and MSK, zero for others
assign mask_shamt = (  (shmsk_op == `SHM_INS_L) |
                       (shmsk_op == `SHM_INS_H) |
                       (shmsk_op == `SHM_MSK_L) |
                       (shmsk_op == `SHM_MSK_H) ) ? op_b[2:0] : 3'b000;

assign byte_mask_shifted = byte_mask << mask_shamt;

logic [3:0] op_b_minus;
assign op_b_minus = 4'd8 - op_b[2:0];

always_comb
   case(shmsk_op)
   `SHM_SRL   ,
   `SHM_SRA   : {op_a_rshft, op_a_shamt} = {1'b1, op_b[5:0]};
   `SHM_SLL   : {op_a_rshft, op_a_shamt} = {1'b0, op_b[5:0]};
   `SHM_EXT_L : {op_a_rshft, op_a_shamt} = {1'b1, op_b[2:0], 3'd0};  
   `SHM_EXT_H : {op_a_rshft, op_a_shamt} = {1'b0, op_b_minus[2:0], 3'd0};
   `SHM_INS_L : {op_a_rshft, op_a_shamt} = {1'b0, op_b[2:0], 3'd0};       
   `SHM_INS_H : {op_a_rshft, op_a_shamt} = {1'b1, op_b_minus[2:0], 3'd0};     
    default   : {op_a_rshft, op_a_shamt} = 7'd0; // (`MSK_L, `MSK_H, `SHM_ZAP, `SHM_ZAPNOT, SEXT)
   endcase

always_comb
   case(shmsk_op)
   `SHM_EXT_L , 
   `SHM_EXT_H ,
   `SHM_SEXT  ,
   `SHM_INS_L : zap_n_mask =  byte_mask_shifted[7:0];
   `SHM_MSK_L : zap_n_mask = ~byte_mask_shifted[7:0];
   `SHM_MSK_H : zap_n_mask = ~byte_mask_shifted[15:8];
   `SHM_INS_H : zap_n_mask =  byte_mask_shifted[15:8];
   `SHM_ZAP   : zap_n_mask = ~op_b[7:0];
   `SHM_ZAPNOT: zap_n_mask =  op_b[7:0];
    default   : zap_n_mask = 8'hFF; // SRL, SRA, SLL
   endcase


always_comb
   if((shmsk_op == `SHM_SRA ) & (op_a[63]))
      sext_mask = 64'hFFFF_FFFF_FFFF_FFFF << (6'd63 - op_b[5:0]);
   else if ((shmsk_op == `SHM_SEXT) & (op_size == `OP_SZ_BYTE))
      sext_mask = { {56{op_b[7]}},  8'd0};
   else if ((shmsk_op == `SHM_SEXT) & (op_size == `OP_SZ_WORD))
      sext_mask = { {48{op_b[15]}},  16'd0};
   else
      sext_mask = 64'd0;


assign zap_n_expanded = { {8{zap_n_mask[7]}},
                          {8{zap_n_mask[6]}},
                          {8{zap_n_mask[5]}},
                          {8{zap_n_mask[4]}},
                          {8{zap_n_mask[3]}},
                          {8{zap_n_mask[2]}},
                          {8{zap_n_mask[1]}},
                          {8{zap_n_mask[0]}} };

assign op_shifted = op_a_rshft ? op_a >> op_a_shamt :
                                 op_a << op_a_shamt ;

// op_a must be zero/r31 for sext
assign op_sext = {64{(shmsk_op == `SHM_SEXT)}} & op_b & zap_n_expanded;

assign result_l = (op_shifted & zap_n_expanded) | op_sext | sext_mask;

always@(posedge clk)
   if(reset)        result <= '0;
   else if (enable) result <= result_l;

always@(posedge clk)
   if(reset)
      rvalid <= 1'b0;
   else if (enable)
      rvalid <= 1'b1;
   else if(rvalid)
      rvalid <= 1'b0;

endmodule
