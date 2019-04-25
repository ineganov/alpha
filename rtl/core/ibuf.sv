`include "defines.vh"

module ibuf (  input                 clk,
               input                 reset,

               input                 clear,

               output                can_accept_1,
               output                can_accept_2,

               input                 push_a,
               input      [`VA_BITS] instn_pc_a_if,
               input          [31:0] instn_opcode_a_if,
               input                 instn_pr_taken_a_if,

               input                 push_b,
               input      [`VA_BITS] instn_pc_b_if,
               input          [31:0] instn_opcode_b_if,
               input                 instn_pr_taken_b_if,

               input                 instn_accepted_id,
               output                instn_vld_id,
               output reg            instn_pr_taken_id,
               output reg     [31:0] instn_opcode_id,
               output reg [`VA_BITS] instn_pc_id );

localparam N_ENTRIES = 4;
localparam N_SQ = $clog2(N_ENTRIES);

localparam W = `VA_SIZE + 32 + 1; // PC + Opcode + Prediction

logic  [W-1:0]  ent_data[0:N_ENTRIES-1];
logic  [N_SQ:0] wr_ptr, rd_ptr;
wire   [N_SQ:0] wr_ptr_p = wr_ptr + 1'b1;

always_ff@(posedge clk)
   if(reset | clear) wr_ptr <= '0;
   else              wr_ptr <= wr_ptr + push_a + push_b;

always_ff@(posedge clk)
   if(reset | clear)
      rd_ptr <= '0;
   else if(instn_accepted_id)
      rd_ptr <= rd_ptr + 1'b1;

always_ff@(posedge clk)
   if(push_a & push_b)
   begin
      ent_data[wr_ptr[N_SQ-1:0]]   <= {instn_pr_taken_a_if, instn_pc_a_if, instn_opcode_a_if};
      ent_data[wr_ptr_p[N_SQ-1:0]] <= {instn_pr_taken_b_if, instn_pc_b_if, instn_opcode_b_if};
   end
   else if(push_a)
   begin
      ent_data[wr_ptr[N_SQ-1:0]]   <= {instn_pr_taken_a_if, instn_pc_a_if, instn_opcode_a_if};
      ent_data[wr_ptr_p[N_SQ-1:0]] <= ent_data[wr_ptr_p[N_SQ-1:0]];
   end
   else if(push_b)
   begin
      ent_data[wr_ptr[N_SQ-1:0]]   <= {instn_pr_taken_b_if, instn_pc_b_if, instn_opcode_b_if};
      ent_data[wr_ptr_p[N_SQ-1:0]] <= ent_data[wr_ptr_p[N_SQ-1:0]];
   end


wire        full = (rd_ptr[N_SQ] ^ wr_ptr[N_SQ]) & (rd_ptr[N_SQ-1:0] == wr_ptr[N_SQ-1:0]);
wire almost_full = (rd_ptr[N_SQ] ^ wr_ptr_p[N_SQ]) & (rd_ptr[N_SQ-1:0] == wr_ptr_p[N_SQ-1:0]);

assign can_accept_1 = ~full ;
assign can_accept_2 = ~(full | almost_full);

assign instn_vld_id = (rd_ptr != wr_ptr) & ~clear;
assign {instn_pr_taken_id, instn_pc_id, instn_opcode_id} = ent_data[rd_ptr[N_SQ-1:0]];

endmodule
