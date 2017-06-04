

// Functional unit defines (onehot)
`define FUNIT_BITS    6:0

`define FUNIT_NONE    7'b0000000
`define FUNIT_ALU     7'b0000001
`define FUNIT_LOG     7'b0000010
`define FUNIT_SHM     7'b0000100
`define FUNIT_LSU     7'b0001000
`define FUNIT_CTU     7'b0010000
`define FUNIT_MPU     7'b0100000
`define FUNIT_CPR     7'b1000000
`define ALU_EN        0
`define LOG_EN        1
`define SHM_EN        2
`define LSU_EN        3
`define CTU_EN        4
`define MPU_EN        5
`define CPR_EN        6


// ADD/SUBTRACT modes

`define ALU_ADD_OVFLOW 3'b100
`define ALU_ADD_32     3'b010
`define ALU_ADD_64     3'b000
`define ALU_ADD_SUB    3'b001


// ADD/SUBTRACT comparison modes
`define ALU_CMP_NONE  3'b000
`define ALU_CMP_EQ    3'b001
`define ALU_CMP_LE    3'b010
`define ALU_CMP_LT    3'b011
`define ALU_CMP_BGE   3'b100
`define ALU_CMP_ULE   3'b110
`define ALU_CMP_ULT   3'b111


// LOGICAL modes
`define LOG_NONE  3'd0
`define LOG_AND   3'd1
`define LOG_EQV   3'd2
`define LOG_ORNOT 3'd3
`define LOG_XOR   3'd4
`define LOG_BIC   3'd5
`define LOG_BIS   3'd6
`define LOG_CMOV  3'd7


// LOGICAL comparison modes
`define LOG_CMP_EQ  3'd0 
`define LOG_CMP_GE  3'd1 
`define LOG_CMP_GT  3'd2 
`define LOG_CMP_LBC 3'd3 
`define LOG_CMP_LBS 3'd4 
`define LOG_CMP_LE  3'd5 
`define LOG_CMP_LT  3'd6 
`define LOG_CMP_NE  3'd7 


// SHIFT/MASK modes
`define SHM_SEXT   4'd0
`define SHM_SRL    4'd1
`define SHM_SRA    4'd2
`define SHM_SLL    4'd3
`define SHM_EXT_L  4'd4
`define SHM_EXT_H  4'd5
`define SHM_INS_L  4'd6
`define SHM_INS_H  4'd7
`define SHM_MSK_L  4'd8
`define SHM_MSK_H  4'd9
`define SHM_ZAP    4'd10   
`define SHM_ZAPNOT 4'd11

// Multiply/populate unit
`define MPU_NONE 3'd0
`define MPU_MUL  3'd1
`define MPU_MULV 3'd2
`define MPU_MULH 3'd3
`define MPU_CTLZ 3'd4
`define MPU_CTTZ 3'd5
`define MPU_CTPP 3'd6


// Op size
`define OP_SZ_QWRD 2'd3
`define OP_SZ_LWRD 2'd2
`define OP_SZ_WORD 2'd1
`define OP_SZ_BYTE 2'd0


// LSU operations
`define LSU_NOP   3'd0
`define LSU_LDA   3'd1
`define LSU_LDAH  3'd2
`define LSU_LD    3'd3
`define LSU_LD_U  3'd4
`define LSU_ST    3'd5
`define LSU_ST_U  3'd6

// CTU operations
`define CTU_NONE  2'd0
`define CTU_PCR_C 2'd1
`define CTU_PCR_U 2'd2
`define CTU_ABS   2'd3

`define CPR_MF    1'd0
`define CPR_MT    1'd1

`define CPR_IDX_W    3
`define CPR_IDX_BITS `CPR_IDX_W-1:0

`define CPR_STATUS  `CPR_IDX_W'd0 //   CPU Status
`define CPR_EPC     `CPR_IDX_W'd1 //   Exceptional instn address
`define CPR_CAUSE   `CPR_IDX_W'd2 //   Exception Cause
`define CPR_INST    `CPR_IDX_W'd3 //   Exception Instn
`define CPR_IMASK   `CPR_IDX_W'd4 //   Interrupt mask
`define CPR_IPND    `CPR_IDX_W'd5 //   Interrupt pending
`define CPR_ICOUNT  `CPR_IDX_W'd6 //   Graduated instn count     
`define CPR_CC      `CPR_IDX_W'd7 //   MPR Cycle count


`define CPR_CAUSE_NUM  3
`define CPR_CAUSE_BITS `CPR_CAUSE_NUM-1:0
`define CPR_CAUSE_PAD  64-`CPR_CAUSE_NUM


`define VA_SIZE 32
`define VA_BITS      `VA_SIZE-1:0
`define VA_TOP_SIZE  64-`VA_SIZE
`define VA_TOP_BITS  63:`VA_SIZE

`define PA_SIZE `VA_SIZE
`define PA_BITS  `PA_SIZE-1:0

//Bus request size
`define REQ_SZ_BYTE 3'd0
`define REQ_SZ_WORD 3'd1
`define REQ_SZ_LWRD 3'd2
`define REQ_SZ_QWRD 3'd3
`define REQ_SZ_LINE 3'd4





// Request/Response packet
//  1 -- Valid
//  3 -- Size: {Line, QW, LW, W, B}
//  1 -- Last beat in multi-beat txn
//  3 -- Type: {FETCH, LOAD, STORE, RESP_ERR, MMU_req? IO?} 
// 32 -- Addr
// 64 -- Writedata (dontcare for loads)


`define PKT_P_SIZE 64+32+3+1+3+1
`define PKT_BITS   `PKT_P_SIZE-1:0

`define PKT_VLD  103
`define PKT_SIZE 102:100
`define PKT_LAST 99
`define PKT_TYPE 98:96
`define PKT_ADDR 95:64
`define PKT_DATA 63:0

`define PKT_PLOAD_SIZE `PKT_P_SIZE-1
`define PKT_PLOAD_BITS `PKT_PLOAD_SIZE-1:0

`define PKT_TYPE_LOAD  3'b001
`define PKT_TYPE_STORE 3'b010
`define PKT_TYPE_FETCH 3'b100



`define CPU_RESET_ADDR 64'h0
`define CPU_EXC_ADDR   64'h0

















