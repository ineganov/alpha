`include "defines.vh"

module instn_decode (  input      [31:0] instn,

                       // Functional Unit
                       output reg  [`FUNIT_BITS] funit,

                       // Instn operands
                       output reg  [4:0] reg_a,
                       output reg  [4:0] reg_b,
                       output reg  [4:0] reg_dst,
                       output reg [20:0] literal,
                       output reg        no_rf_upd,
                       output reg        use_ltrl_8,
                       output reg        use_ltrl_16,
                       output reg        use_ltrl_20,


                       // ADD/SUBTRACT controls
                       output reg  [2:0] addsub_op,
                       output reg  [1:0] addsub_scale,
                       output reg  [2:0] addsub_cmp_op,

                       // LOGICAL controls
                       output reg  [2:0] log_op,
                       output reg  [2:0] log_cmp_op,
                       output reg        log_cond_upd, // Conditional RF update for CMOV

                       // Control Transfers
                       output reg  [1:0] ctu_op,

                       // SHIFT&MASK controls
                       output reg  [3:0] shmsk_op,
                       output reg  [1:0] op_size,

                       // Multiply/populate
                       output reg  [2:0] mpu_op,

                       // LOADSTORE controls
                       output reg  [2:0] lsu_op,
                       output reg        op_llsc,


                       // CPU Registers controls
                       output reg        cpr_op,

                       // Exception signals
                       output reg        e_reserved,
                       output reg        e_halt,    
                       output reg        e_callpal, 
                       output reg        hw_ret     );


enum int unsigned {  
I_ADDL   , I_ADDLV  , I_ADDQ   , I_ADDQV  , I_SUBL   , I_SUBLV  , I_SUBQ   , I_SUBQV  , 
I_S4ADDL , I_S4ADDQ , I_S4SUBL , I_S4SUBQ , I_S8ADDL , I_S8ADDQ , I_S8SUBL , I_S8SUBQ , 
I_CMPBGE , I_CMPEQ  , I_CMPLE  , I_CMPLT  , I_CMPULE , I_CMPULT , I_MULL   , I_MULLV  , 
I_MULQ   , I_MULQV  , I_UMULH  , I_AND    , I_EQV    , I_ORNOT  , I_XOR    , I_BIC    ,
I_BIS    , I_CMOVEQ , I_CMOVGE , I_CMOVGT , I_CMOVLBC, I_CMOVLBS, I_CMOVLE , I_CMOVLT ,
I_CMOVNE , I_SLL    , I_SRA    , I_SRL    , I_EXTBL  , I_EXTLH  , I_EXTLL  , I_EXTQH  , 
I_EXTQL  , I_EXTWH  , I_EXTWL  , I_INSBL  , I_INSLH  , I_INSLL  , I_INSQH  , I_INSQL  ,
I_INSWH  , I_INSWL  , I_MSKBL  , I_MSKLH  , I_MSKLL  , I_MSKQH  , I_MSKQL  , I_MSKWH  ,
I_MSKWL  , I_ZAP    , I_ZAPNOT , I_BEQ    , I_BGE    , I_BGT    , I_BLBC   , I_BLBS   , 
I_BLE    , I_BLT    , I_BNE    , I_BR     , I_BSR    , I_JMP    , I_LDA    , I_LDAH   ,
I_LDL    , I_LDL_L  , I_LDQ    , I_LDQ_L  , I_LDQ_U  , I_STL    , I_STL_C  , I_STQ    ,
I_STQ_C  , I_STQ_U  , I_LDBU   , I_LDWU   , I_STB    , I_STW    , I_SEXTB  , I_SEXTW  , 
I_CTLZ   , I_CTPOP  , I_CTTZ   , I_CALL_PAL,I_HALT   , I_HW_MFPR, I_HW_MTPR, I_HW_RET ,  I_RESERVED } decoded_instn;

logic [31:26] opcode;
logic [25:21] op_ra;
logic [20:16] op_rb;
logic [ 4:0 ] op_rc;
logic [11:5 ] opr_func;
logic [20:13] opr_literal;
logic  [20:0] br_disp;
logic  [15:0] mem_disp;


// Memory instn format
// logic [31:26] mem_opcode;
// logic [25:21] mem_ra;
// logic [20:16] mem_rb;
// assign {mem_opcode, mem_ra, mem_rb, mem_disp} = instn;

// Branch instn format
// logic [31:26] br_opcode;
// logic [25:21] br_ra;
// assign {br_opcode, br_ra, br_disp} = instn;

// Operate instn format
// logic [31:26] opr_opcode;
// logic [25:21] opr_ra;
// logic [20:16] opr_rb;
// logic [15:12] opr_unused;
// logic [11:5 ] opr_func;
// logic [ 4:0 ] opr_rc;
// logic [20:13] opr_literal;
// assign {opr_opcode, opr_ra, opr_rb, opr_unused, opr_func, opr_rc} = instn;

// Palcode instn format
// logic [31:26] pal_opcode;
// logic [25:0 ] pal_op;
// assign {pal_opcode, pal_op} = instn;

assign opcode      = instn[31:26];
assign op_ra       = instn[25:21];
assign op_rb       = instn[20:16];
assign op_rc       = instn[ 4:0 ];
assign opr_func    = instn[11:5 ];
assign opr_literal = instn[20:13];
assign br_disp     = instn[20:0 ];
assign mem_disp    = instn[15:0 ];

assign literal = br_disp;

always_comb
begin
   // Defaul values:

   // Functional unit:
   funit = `FUNIT_NONE;

   // Addsub
   addsub_op = '0;
   addsub_scale = '0;
   addsub_cmp_op = '0;

   // Logical
   log_op = `LOG_NONE;
   log_cmp_op = `LOG_CMP_EQ;
   log_cond_upd = 1'b0;

   // Shift and mask
   shmsk_op = `SHM_SEXT;
   op_size = `OP_SZ_QWRD;

   // Load/Store
   lsu_op  = `LSU_NOP;
   op_size = `OP_SZ_QWRD;
   op_llsc = 1'b0;

   // Control
   ctu_op = `CTU_NONE;

   // Multiply/populate
   mpu_op = `MPU_NONE;

   // CPU Registers
   cpr_op = `CPR_MF;

   // Operands
   reg_a = op_ra;
   reg_b = op_rb;
   reg_dst = op_rc;
   no_rf_upd = 1'b0;
   use_ltrl_8  = 1'b0;
   use_ltrl_16 = 1'b0;
   use_ltrl_20 = 1'b0;

   // Exceptions
   e_reserved = 1'b0;
   e_halt     = 1'b0;
   e_callpal  = 1'b0;
   hw_ret     = 1'b0;

   case(opcode)
      6'h10: begin
                case(opr_func)
                7'h00: begin // Add longword                                
                       decoded_instn = I_ADDL  ;
                       addsub_op = `ALU_ADD_32;
                       funit = `FUNIT_ALU;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h40: begin // Add longword with ovflow                    
                       decoded_instn = I_ADDLV;
                       addsub_op = `ALU_ADD_32 | `ALU_ADD_OVFLOW;
                       funit = `FUNIT_ALU;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h20: begin // Add quadword                                
                       decoded_instn = I_ADDQ  ;
                       addsub_op = `ALU_ADD_64;
                       funit = `FUNIT_ALU;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h60: begin // Add quadword with ovflow                    
                       decoded_instn = I_ADDQV;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_OVFLOW;
                       funit = `FUNIT_ALU;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h09: begin // Subtract longword                           
                       decoded_instn = I_SUBL  ;
                       addsub_op = `ALU_ADD_32 | `ALU_ADD_SUB;
                       funit = `FUNIT_ALU;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h49: begin // Subtract longword with ovflow               
                       decoded_instn = I_SUBLV;
                       addsub_op = `ALU_ADD_32 | `ALU_ADD_SUB | `ALU_ADD_OVFLOW;
                       funit = `FUNIT_ALU;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h29: begin // Subtract quadword                           
                       decoded_instn = I_SUBQ  ;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB;
                       funit = `FUNIT_ALU;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h69: begin // Subtract quadword with ovflow               
                       decoded_instn = I_SUBQV;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB | `ALU_ADD_OVFLOW;
                       funit = `FUNIT_ALU;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h02: begin // Scaled add longword by 4                    
                       decoded_instn = I_S4ADDL;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_32;
                       addsub_scale = 2'd2;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h22: begin // Scaled add quadword by 4                    
                       decoded_instn = I_S4ADDQ;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64;
                       addsub_scale = 2'd2;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h0B: begin // Scaled subtract longword by 4               
                       decoded_instn = I_S4SUBL;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_32 | `ALU_ADD_SUB;                       
                       addsub_scale = 2'd2;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h2B: begin // Scaled subtract quadword by 4               
                       decoded_instn = I_S4SUBQ;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB;                       
                       addsub_scale = 2'd2;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h12: begin // Scaled add longword by 8                    
                       decoded_instn = I_S8ADDL;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_32;
                       addsub_scale = 2'd3;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h32: begin // Scaled add quadword by 8                    
                       decoded_instn = I_S8ADDQ;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64;                       
                       addsub_scale = 2'd3;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h1B: begin // Scaled subtract longword by 8               
                       decoded_instn = I_S8SUBL;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_32 | `ALU_ADD_SUB;                       
                       addsub_scale = 2'd3;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h3B: begin // Scaled subtract quadword by 8               
                       decoded_instn = I_S8SUBQ;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB;                       
                       addsub_scale = 2'd3;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h0F: begin // Compare byte                                
                       funit = `FUNIT_ALU;
                       decoded_instn = I_CMPBGE;
                       addsub_cmp_op = `ALU_CMP_BGE;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h2D: begin // Compare signed quadword equal               
                       decoded_instn = I_CMPEQ ;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB;                       
                       addsub_cmp_op = `ALU_CMP_EQ;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h6D: begin // Compare signed quadword less than or equal  
                       decoded_instn = I_CMPLE ;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB;                       
                       addsub_cmp_op = `ALU_CMP_LE;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h4D: begin // Compare signed quadword less than           
                       decoded_instn = I_CMPLT ;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB;                       
                       addsub_cmp_op = `ALU_CMP_LT;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h3D: begin // Compare unsigned quadword less than or equal
                       decoded_instn = I_CMPULE;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB;               
                       addsub_cmp_op = `ALU_CMP_ULE;
                       use_ltrl_8  = instn[12];
                       end
                
                7'h1D: begin // Compare unsigned quadword less than         
                       decoded_instn = I_CMPULT;
                       funit = `FUNIT_ALU;
                       addsub_op = `ALU_ADD_64 | `ALU_ADD_SUB;                       
                       addsub_cmp_op = `ALU_CMP_ULT;
                       use_ltrl_8  = instn[12];
                       end

                default: begin
                         decoded_instn = I_RESERVED ;
                         e_reserved = 1'b1;
                         end
                endcase // ALU ADD instns2
             end

      6'h11: begin // Logic instn group
               case(opr_func)
               7'h00: begin // Logical product
                      decoded_instn = I_AND;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_AND;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h48: begin // Logical equivalence (XORNOT)
                      decoded_instn = I_EQV;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_EQV;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h28: begin // Logical sum with complement 
                      decoded_instn = I_ORNOT;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_ORNOT;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h40: begin // Logical difference   
                      decoded_instn = I_XOR;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_XOR;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h08: begin // Bit clear (ANDNOT)
                      decoded_instn = I_BIC;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_BIC;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h20: begin // Logical sum (OR)  
                      decoded_instn = I_BIS;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_BIS;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h24: begin // CMOVE if = zero 
                      decoded_instn = I_CMOVEQ ;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_CMOV;
                      log_cmp_op = `LOG_CMP_EQ;
                      log_cond_upd = 1'b1;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h46: begin // CMOVE if >= zero 
                      decoded_instn = I_CMOVGE ;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_CMOV;
                      log_cmp_op = `LOG_CMP_GE;
                      log_cond_upd = 1'b1;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h66: begin // CMOVE if > zero
                      decoded_instn = I_CMOVGT ;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_CMOV;
                      log_cmp_op = `LOG_CMP_GT;
                      log_cond_upd = 1'b1;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h16: begin // CMOVE if low bit clear
                      decoded_instn = I_CMOVLBC;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_CMOV;
                      log_cmp_op = `LOG_CMP_LBC;
                      log_cond_upd = 1'b1;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h14: begin // CMOVE if low bit set
                      decoded_instn = I_CMOVLBS;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_CMOV;
                      log_cmp_op = `LOG_CMP_LBS;
                      log_cond_upd = 1'b1;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h64: begin // CMOVE if <= zero
                      decoded_instn = I_CMOVLE ;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_CMOV;
                      log_cmp_op = `LOG_CMP_LE;
                      log_cond_upd = 1'b1;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h44: begin // CMOVE if < zero
                      decoded_instn = I_CMOVLT ;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_CMOV;
                      log_cmp_op = `LOG_CMP_LT;
                      log_cond_upd = 1'b1;
                      use_ltrl_8  = instn[12];
                      end
                       
               7'h26: begin // CMOVE if !zero 
                      decoded_instn = I_CMOVNE ;
                      funit = `FUNIT_LOG;
                      log_op = `LOG_CMOV;
                      log_cmp_op = `LOG_CMP_NE;
                      log_cond_upd = 1'b1;
                      use_ltrl_8  = instn[12];
                      end
        
               default: begin
                        decoded_instn = I_RESERVED ;
                        e_reserved = 1'b1;
                        end

               endcase
             end

      6'h12: begin // Shifts, Inserts, Masks
                case(opr_func)
                7'h39: begin  // Shift left logical     
                       decoded_instn = I_SLL   ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_SLL;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h3C: begin  // Shift right arithmetic 
                       decoded_instn = I_SRA   ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_SRA;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h34: begin  // Shift right logical    
                       decoded_instn = I_SRL   ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_SRL;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h06: begin  // Extract byte low       
                       decoded_instn = I_EXTBL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_EXT_L;
                       op_size = `OP_SZ_BYTE;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h6A: begin  // Extract longword high  
                       decoded_instn = I_EXTLH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_EXT_H;
                       op_size = `OP_SZ_LWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h26: begin  // Extract longword low   
                       decoded_instn = I_EXTLL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_EXT_L;
                       op_size = `OP_SZ_LWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h7A: begin  // Extract quadword high  
                       decoded_instn = I_EXTQH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_EXT_H;
                       op_size = `OP_SZ_QWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h36: begin  // Extract quadword low   
                       decoded_instn = I_EXTQL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_EXT_L;
                       op_size = `OP_SZ_QWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h5A: begin  // Extract word high      
                       decoded_instn = I_EXTWH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_EXT_H;
                       op_size = `OP_SZ_WORD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h16: begin  // Extract word low       
                       decoded_instn = I_EXTWL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_EXT_L;
                       op_size = `OP_SZ_WORD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h0B: begin  // Insert byte low        
                       decoded_instn = I_INSBL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_INS_L;
                       op_size = `OP_SZ_BYTE;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h67: begin  // Insert longword high   
                       decoded_instn = I_INSLH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_INS_H;
                       op_size = `OP_SZ_LWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h2B: begin  // Insert longword low    
                       decoded_instn = I_INSLL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_INS_L;
                       op_size = `OP_SZ_LWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h77: begin  // Insert quadword high   
                       decoded_instn = I_INSQH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_INS_H;
                       op_size = `OP_SZ_QWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h3B: begin  // Insert quadword low    
                       decoded_instn = I_INSQL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_INS_L;
                       op_size = `OP_SZ_QWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h57: begin  // Insert word high       
                       decoded_instn = I_INSWH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_INS_H;
                       op_size = `OP_SZ_WORD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h1B: begin  // Insert word low        
                       decoded_instn = I_INSWL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_INS_L;
                       op_size = `OP_SZ_WORD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h02: begin  // Mask byte low          
                       decoded_instn = I_MSKBL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_MSK_L;
                       op_size = `OP_SZ_BYTE;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h62: begin  // Mask longword high     
                       decoded_instn = I_MSKLH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_MSK_H;
                       op_size = `OP_SZ_LWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h22: begin  // Mask longword low      
                       decoded_instn = I_MSKLL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_MSK_L;
                       op_size = `OP_SZ_LWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h72: begin  // Mask quadword high     
                       decoded_instn = I_MSKQH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_MSK_H;
                       op_size = `OP_SZ_QWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h32: begin  // Mask quadword low      
                       decoded_instn = I_MSKQL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_MSK_L;
                       op_size = `OP_SZ_QWRD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h52: begin  // Mask word high         
                       decoded_instn = I_MSKWH ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_MSK_H;
                       op_size = `OP_SZ_WORD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h12: begin  // Mask word low          
                       decoded_instn = I_MSKWL ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_MSK_L;
                       op_size = `OP_SZ_WORD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h30: begin  // Zero bytes             
                       decoded_instn = I_ZAP   ;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_ZAP;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h31: begin  // Zero bytes not         
                       decoded_instn = I_ZAPNOT;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_ZAPNOT;
                       use_ltrl_8  = instn[12];
                       end
                        
                default: begin
                         decoded_instn = I_RESERVED ;
                         e_reserved = 1'b1;
                         end
                endcase
             end

      6'h13: begin // Multiply group
                case(opr_func)
                7'h00: begin // Multiply longword
                       decoded_instn = I_MULL;
                       funit = `FUNIT_MPU;
                       mpu_op = `MPU_MUL;
                       op_size = `OP_SZ_LWRD;
                       use_ltrl_8  = instn[12];
                       end
             
                7'h40: begin // Multiply longword with ovflow
                       decoded_instn = I_MULLV;
                       funit = `FUNIT_MPU;
                       mpu_op = `MPU_MULV;
                       op_size = `OP_SZ_LWRD;
                       use_ltrl_8  = instn[12];
                       end
             
                7'h20: begin // Multiply quadword
                       decoded_instn = I_MULQ;
                       funit = `FUNIT_MPU;
                       mpu_op = `MPU_MUL;
                       use_ltrl_8  = instn[12];
                       end
             
                7'h60: begin // Multiply quadword with ovflow
                       decoded_instn = I_MULQV;
                       funit = `FUNIT_MPU;
                       mpu_op = `MPU_MULV;
                       use_ltrl_8  = instn[12];
                       end
             
                7'h30: begin // Unsigned multiply quadword high
                       decoded_instn = I_UMULH;
                       funit = `FUNIT_MPU;
                       mpu_op = `MPU_MULH;
                       use_ltrl_8  = instn[12];
                       end
             
                default: begin
                         decoded_instn = I_RESERVED ;
                         e_reserved = 1'b1;
                         end
                endcase
             end

      6'h1C: begin // Sign-extend and CIX
                case(opr_func)
                7'h00: begin // Sign extend byte   
                       decoded_instn = I_SEXTB;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_SEXT;
                       op_size = `OP_SZ_BYTE;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h01: begin // Sign extend word   
                       decoded_instn = I_SEXTW;
                       funit = `FUNIT_SHM;
                       shmsk_op = `SHM_SEXT;
                       op_size = `OP_SZ_WORD;
                       use_ltrl_8  = instn[12];
                       end
                       
                7'h32: begin // Count leading zero 
                       decoded_instn = I_CTLZ ;
                       funit = `FUNIT_MPU;
                       mpu_op = `MPU_CTLZ;
                       end
                       
                7'h30: begin // Count population   
                       decoded_instn = I_CTPOP;
                       funit = `FUNIT_MPU;
                       mpu_op = `MPU_CTPP;
                       end
                       
                7'h33: begin // Count trailing zero
                       decoded_instn = I_CTTZ ;
                       funit = `FUNIT_MPU;
                       mpu_op = `MPU_CTTZ;
                       end
                       
                default: begin
                         decoded_instn = I_RESERVED ;
                         e_reserved = 1'b1;
                         end
                endcase
             end


      // Branches and jumps
      6'h39: begin // Branch if = zero                  
             decoded_instn = I_BEQ     ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_C;
             log_cmp_op = `LOG_CMP_EQ;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_20 = 1'b1;
             end
             
      6'h3E: begin // Branch if >= zero                 
             decoded_instn = I_BGE     ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_C;
             log_cmp_op = `LOG_CMP_GE;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_20 = 1'b1;
             end
             
      6'h3F: begin // Branch if > zero                  
             decoded_instn = I_BGT     ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_C;
             log_cmp_op = `LOG_CMP_GT;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_20 = 1'b1;
             end
             
      6'h38: begin // Branch if low bit clear           
             decoded_instn = I_BLBC    ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_C;
             log_cmp_op = `LOG_CMP_LBC;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_20 = 1'b1;
             end
             
      6'h3C: begin // Branch if low bit set             
             decoded_instn = I_BLBS    ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_C;
             log_cmp_op = `LOG_CMP_LBS;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_20 = 1'b1;
             end
             
      6'h3B: begin // Branch if <= zero                 
             decoded_instn = I_BLE     ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_C;
             log_cmp_op = `LOG_CMP_LE;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_20 = 1'b1;
             end
             
      6'h3A: begin // Branch if < zero                  
             decoded_instn = I_BLT     ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_C;
             log_cmp_op = `LOG_CMP_LT;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_20 = 1'b1;
             end
             
      6'h3D: begin // Branch if ! zero                  
             decoded_instn = I_BNE     ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_C;
             log_cmp_op = `LOG_CMP_NE;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_20 = 1'b1;
             end
             
      6'h30: begin // Unconditional branch              
             decoded_instn = I_BR      ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_U;
             reg_dst = op_ra;
             use_ltrl_20 = 1'b1;
             end
             
      6'h34: begin // Branch to subroutine              
             decoded_instn = I_BSR     ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_PCR_U;
             reg_dst = op_ra;
             use_ltrl_20 = 1'b1;
             end
             
      6'h1A: begin // Jump, JSR, RET, JST_CRE           
             decoded_instn = I_JMP     ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_ABS;
             reg_dst = op_ra;
             use_ltrl_20 = 1'b1;
             end
             
      6'h00: begin // Trap to PALcode or HALT
             if(instn[25:0] == 26'd0)
               begin
                  decoded_instn = I_HALT;
                  e_halt = 1'b1;
                  no_rf_upd = 1'b1;
               end
             else 
               begin
                  decoded_instn = I_CALL_PAL;
                  reg_dst = op_ra;
                  e_callpal = 1'b1;
               end
             end
      
      6'h19: begin // Move from CPU register
             decoded_instn = I_HW_MFPR;
             funit = `FUNIT_CPR;
             reg_dst = op_ra;
             cpr_op = `CPR_MF;
             use_ltrl_16 = 1'b1;
             end

      6'h1D: begin // Move to CPU register
             decoded_instn = I_HW_MTPR;
             funit = `FUNIT_CPR;
             cpr_op = `CPR_MT;          
             no_rf_upd = 1'b1;
             use_ltrl_16 = 1'b1;
             end

      6'h1E: begin // Return from exception
             decoded_instn = I_HW_RET  ;
             funit = `FUNIT_CTU;
             ctu_op = `CTU_ABS;
             hw_ret = 1'b1;
             no_rf_upd = 1'b1;
             end


      // LSU instns       
      6'h08: begin // Load address                      
             decoded_instn = I_LDA     ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LDA;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h09: begin // Load address high                 
             decoded_instn = I_LDAH    ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LDAH;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h28: begin // Load sign-extended longword       
             decoded_instn = I_LDL     ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LD;
             op_size = `OP_SZ_LWRD;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h2A: begin // Load sign-extended longword locked
             decoded_instn = I_LDL_L   ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LD;
             op_size = `OP_SZ_LWRD;
             op_llsc = 1'b1;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h29: begin // Load quadword                     
             decoded_instn = I_LDQ     ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LD;
             op_size = `OP_SZ_QWRD;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h2B: begin // Load quadword locked              
             decoded_instn = I_LDQ_L   ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LD;
             op_size = `OP_SZ_QWRD;
             op_llsc = 1'b1;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h0B: begin // Load unaligned quadword           
             decoded_instn = I_LDQ_U   ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LD_U;
             op_size = `OP_SZ_QWRD;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h2C: begin // Store longword                    
             decoded_instn = I_STL     ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_ST;
             op_size = `OP_SZ_LWRD;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_16 = 1'b1;
             end
             
      6'h2E: begin // Store longword conditional        
             decoded_instn = I_STL_C   ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_ST;
             op_size = `OP_SZ_LWRD;
             op_llsc = 1'b1;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h2D: begin // Store quadword                    
             decoded_instn = I_STQ     ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_ST;
             op_size = `OP_SZ_QWRD;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_16 = 1'b1;
             end
             
      6'h2F: begin // Store quadword conditional        
             decoded_instn = I_STQ_C   ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_ST;
             op_size = `OP_SZ_QWRD;
             op_llsc = 1'b1;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h0F: begin // Store unaligned quadword          
             decoded_instn = I_STQ_U   ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_ST_U;
             op_size = `OP_SZ_QWRD;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_16 = 1'b1;
             end
             
      // LSU BWX       
      6'h0A: begin // Load zero-extended byte           
             decoded_instn = I_LDBU    ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LD_U;
             op_size = `OP_SZ_BYTE;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h0C: begin // Load zero-extended word           
             decoded_instn = I_LDWU    ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_LD_U;
             op_size = `OP_SZ_WORD;
             reg_dst = op_ra;
             use_ltrl_16 = 1'b1;
             end
             
      6'h0E: begin // Store byte                        
             decoded_instn = I_STB     ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_ST;
             op_size = `OP_SZ_BYTE;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_16 = 1'b1;
             end
             
      6'h0D: begin // Store word                        
             decoded_instn = I_STW     ;
             funit = `FUNIT_LSU;
             lsu_op  = `LSU_ST;
             op_size = `OP_SZ_WORD;
             reg_dst = op_ra;
             no_rf_upd = 1'b1;
             use_ltrl_16 = 1'b1;
             end
              

      default: begin
               decoded_instn = I_RESERVED ;
               e_reserved = 1'b1;
               end
   endcase
end


endmodule
