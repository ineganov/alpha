module regfile(   input           clk,
                  input           reset,
                  input    [4:0]  rd_addr_a,
                  input    [4:0]  rd_addr_b,
                  input    [4:0]  wr_addr,
                  input   [63:0]  wr_data,
                  input           wr_en,
                  output  [63:0]  rd_data_a,
                  output  [63:0]  rd_data_b  );


logic [63:0] rf[31:0];
logic [63:0] reg_read_a, reg_read_b, wr_data_byp;
logic  [4:0] rd_addr_a_l, rd_addr_b_l;
logic        rd_a_zero, rd_a_byp, rd_a_byp_l;
logic        rd_b_zero, rd_b_byp, rd_b_byp_l;

always_ff@(posedge clk)
begin
   reg_read_a <= rf[rd_addr_a];
   reg_read_b <= rf[rd_addr_b];
   if(wr_en)
      rf[wr_addr] <= wr_data;
   end

always_ff@(posedge clk)
   begin
      rd_addr_a_l <= rd_addr_a;
      rd_addr_b_l <= rd_addr_b;
      rd_a_zero   <= (rd_addr_a == 5'd31);
      rd_b_zero   <= (rd_addr_b == 5'd31);
      rd_a_byp    <= (wr_en & (rd_addr_a == wr_addr));
      rd_b_byp    <= (wr_en & (rd_addr_b == wr_addr));
      wr_data_byp <= wr_data;
   end

assign rd_a_byp_l = wr_en & (rd_addr_a_l == wr_addr);
assign rd_b_byp_l = wr_en & (rd_addr_b_l == wr_addr);

assign rd_data_a = rd_a_zero  ?          '0 :
                   rd_a_byp_l ?     wr_data :
                   rd_a_byp   ? wr_data_byp :
                                 reg_read_a ;

assign rd_data_b = rd_b_zero  ?          '0 :
                   rd_b_byp_l ?     wr_data : 
                   rd_b_byp   ? wr_data_byp :
                                 reg_read_b ;



endmodule
