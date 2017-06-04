`include "defines.vh"

module cpr (   input                   clk,
               input                   reset,
               input                   enable,

               // MFPR/MTPR
               input                   cpr_op,
               input   [`CPR_IDX_BITS] cpr_idx,
               input            [63:0] cpr_wdata,

               // Exceptions
               input                   e_enter,
               input                   e_exit,
               input            [63:0] n_epc,
               input            [31:0] n_inst,
               input [`CPR_CAUSE_BITS] n_cause,

               // Counters
               input                   instn_grad_gr, // Instruction graduated

               output logic            rvalid,
               output logic   [63:0]   result );


// 0: CPR_STATUS  CPU Status
// 1: CPR_EPC     Exceptional instn address
// 2: CPR_CAUSE   Exception Cause
// 3: CPR_INST    Exception Instn
// 4: CPR_IMASK   Interrupt mask
// 5: CPR_IPND    Interrupt pending
// 6: CPR_ICNT    CPR Graduated instn count
// 7: CPR_CC      CPR Cycle count

//wire cpr_rd_e0 = enable & (cpr_op == `CPR_MF);
wire cpr_wr_e0 = enable & (cpr_op == `CPR_MT);




// Exceptions & Status

logic                   cpr_emode_xx;
logic            [63:0] cpr_epc_xx;
logic            [31:0] cpr_inst_xx;
logic [`CPR_CAUSE_BITS] cpr_cause_xx;

wire                    cpr_idx_stts   = (cpr_idx == `CPR_STATUS ); 
wire                    cpr_idx_epc    = (cpr_idx == `CPR_EPC    ); 
wire                    cpr_idx_cause  = (cpr_idx == `CPR_CAUSE  ); 
wire                    cpr_idx_inst   = (cpr_idx == `CPR_INST   ); 

always_ff@(posedge clk)
   if(reset)
   begin
      cpr_epc_xx   <= '0;
      cpr_inst_xx  <= '0;
      cpr_cause_xx <= '0;
   end
   else if(e_enter)
   begin
      cpr_epc_xx   <= n_epc;
      cpr_inst_xx  <= n_inst;
      cpr_cause_xx <= n_cause;
   end

always_ff@(posedge clk)
   if(reset | e_enter)
      cpr_emode_xx <= 1'b1;
   else if(e_exit)
      cpr_emode_xx <= 1'b0;


// Instruction counter

logic [63:0] cpr_icount_xx;
wire         cpr_idx_icount = (cpr_idx == `CPR_ICOUNT);

always_ff@(posedge clk)
   if(reset | (cpr_idx_icount & cpr_wr_e0))
      cpr_icount_xx <= '0;
   else if (instn_grad_gr)
      cpr_icount_xx <= cpr_icount_xx + 1'b1;


// Cycle counter

logic [63:0] cpr_cc_xx;
wire         cpr_idx_cc = (cpr_idx == `CPR_CC);

always_ff@(posedge clk)
   if(reset | (cpr_idx_cc & cpr_wr_e0))
      cpr_cc_xx <= '0;
   else
      cpr_cc_xx <= cpr_cc_xx + 1'b1;



// Data readout
wire  [63:0] stts_rd_xx  = {63'd0, cpr_emode_xx};
wire  [63:0] cause_rd_xx = {{`CPR_CAUSE_PAD{1'b0}}, cpr_cause_xx};
wire  [63:0] inst_rd_xx  = {32'd0, cpr_inst_xx};

wire [63:0] readdata_e0 = ({64{cpr_idx_stts  }} & stts_rd_xx   ) |
                          ({64{cpr_idx_epc   }} & cpr_epc_xx   ) |
                          ({64{cpr_idx_cause }} & cause_rd_xx  ) |
                          ({64{cpr_idx_inst  }} & inst_rd_xx   ) |
                          ({64{cpr_idx_cc    }} & cpr_cc_xx    ) |
                          ({64{cpr_idx_icount}} & cpr_icount_xx) ;

always_ff@(posedge clk)
   if(enable)
      result <= readdata_e0;

always_ff@(posedge clk)
   if(reset)
      rvalid <= 1'b0;
   else if (enable)
      rvalid <= 1'b1;
   else if(rvalid)
      rvalid <= 1'b0;

endmodule
