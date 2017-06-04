`include "defines.vh"

module testbench;

logic             clk   = 0;
logic             reset = 1;

logic [`PKT_BITS] mem_req_pkt_xx;
logic             mem_req_ack_xx;
logic [`PKT_BITS] mem_resp_pkt_xx;

logic      [63:0] wdata, rdata;
logic       [7:0] ram[0:2**17-1];

logic [`PKT_BITS] pkt_t0, pkt_t1, pkt_t1_r, pkt_t2;

string init_path;
string cmp_log;

integer fd;
bit log_present = 1'b0;

always #10ns clk = ~clk;

initial
begin
   if(!$value$plusargs("MEM=%s", init_path))
      init_path = "soft/main.hex";

   $readmemh(init_path, ram);

   if($value$plusargs("LOG=%s", cmp_log))
   begin
      fd = $fopen(cmp_log);
      log_present = 1'b1;
   end
   else log_present = 1'b0;

   if($test$plusargs("dump"))
   begin
      $dumpfile("dump.vcd");
      $dumpon; // This looks unsupported by Modelsim Starter Edition
   end

   #50ns @(posedge clk) reset = 0;
end



always_ff@(posedge clk)
   if(uut.igu.e_callpal_e1)
   begin
      if(log_present)            $fclose(fd);
      if($test$plusargs("dump")) $dumpoff;
      $finish;
   end

always_ff@(posedge clk)
begin
   if(log_present & uut.igu.instn_grad_gr & uut.igu.rf_wen_gr)
      $fdisplay(fd, "%08x_%08x: %08x_%08x --> %02d", uut.igu.instn_pc_e1[63:32], 
                                                     uut.igu.instn_pc_e1[31:0 ],
                                                     uut.igu.rf_wdata_gr[63:32],
                                                     uut.igu.rf_wdata_gr[31:0 ],
                                                     uut.igu.rf_waddr_gr);

   // Emulate gem5 CMOVE behavior (failed CMOV writes the register to itself)
   if(   log_present 
      &  uut.igu.instn_grad_gr 
      &  uut.igu.log_cond_upd_e1
      & ~uut.igu.cmp_result_e1 )
      $fdisplay(fd, "%08x_%08x: %08x_%08x --> %02d", uut.igu.instn_pc_e1[63:32], 
                                                     uut.igu.instn_pc_e1[31:0 ],
                                                     uut.regfile.rf[uut.igu.rf_waddr_gr][63:32],
                                                     uut.regfile.rf[uut.igu.rf_waddr_gr][31:0 ],
                                                     uut.igu.rf_waddr_gr);

end


alpha_core uut( .clk              ( clk             ),
                .reset            ( reset           ),
                .mem_req_pkt_xx   ( mem_req_pkt_xx  ),
                .mem_req_ack_xx   ( mem_req_ack_xx  ),
                .mem_resp_pkt_xx  ( mem_resp_pkt_xx ) );


always_ff@(posedge clk)
   if(reset) pkt_t1_r <= '0;
   else      pkt_t1_r <= pkt_t0;

always_ff@(posedge clk)
   if(reset) pkt_t2 <= '0;
   else      pkt_t2 <= pkt_t1;


always_comb
   if(mem_req_pkt_xx[`PKT_VLD] & ~pkt_t1_r[`PKT_VLD])
   begin
      if(mem_req_pkt_xx[`PKT_SIZE] == `REQ_SZ_LINE)
      begin
         pkt_t0 = mem_req_pkt_xx;
         pkt_t1 = mem_req_pkt_xx;

         pkt_t0[`PKT_LAST] = 1'b1;
         pkt_t1[`PKT_LAST] = 1'b0;

         pkt_t0[`PKT_ADDR] = (mem_req_pkt_xx[`PKT_ADDR] & 32'hffff_fff0) | 4'b1000;
         pkt_t1[`PKT_ADDR] = (mem_req_pkt_xx[`PKT_ADDR] & 32'hffff_fff0);
      end
      else // mem_resp_pkt_xx[`PKT_SIZE] != `REQ_SZ_LINE
      begin
         pkt_t0 = {`PKT_P_SIZE{1'b0}};
         pkt_t1 = mem_req_pkt_xx;
      end
   end
   else if(pkt_t1_r[`PKT_VLD]) 
   begin
      pkt_t0 = {`PKT_P_SIZE{1'b0}};
      pkt_t1 = pkt_t1_r;
   end
   else
   begin
      pkt_t0 = {`PKT_P_SIZE{1'b0}};
      pkt_t1 = {`PKT_P_SIZE{1'b0}};
   end

always_comb
   begin
   mem_resp_pkt_xx = pkt_t2;
   mem_resp_pkt_xx[`PKT_VLD]  = pkt_t2[`PKT_VLD];// & (pkt_t2[`PKT_TYPE] != `PKT_TYPE_STORE);
   mem_resp_pkt_xx[`PKT_DATA] = rdata;
   end

assign mem_req_ack_xx = mem_req_pkt_xx[`PKT_VLD] & ~pkt_t1_r[`PKT_VLD];


wire [31:0] addr_t1 = pkt_t1[`PKT_ADDR];

wire write_t1 = pkt_t1[`PKT_VLD] & (pkt_t1[`PKT_TYPE] == `PKT_TYPE_STORE);

wire read_t2  = pkt_t2[`PKT_VLD] & ((pkt_t2[`PKT_TYPE] == `PKT_TYPE_FETCH) |
                                    (pkt_t2[`PKT_TYPE] == `PKT_TYPE_LOAD )); 

assign rdata =   {64{read_t2}} & { ram[pkt_t2[`PKT_ADDR] | 3'd7],
                                   ram[pkt_t2[`PKT_ADDR] | 3'd6],
                                   ram[pkt_t2[`PKT_ADDR] | 3'd5],
                                   ram[pkt_t2[`PKT_ADDR] | 3'd4],
                                   ram[pkt_t2[`PKT_ADDR] | 3'd3],
                                   ram[pkt_t2[`PKT_ADDR] | 3'd2],
                                   ram[pkt_t2[`PKT_ADDR] | 3'd1],
                                   ram[pkt_t2[`PKT_ADDR] | 3'd0] };

assign wdata = pkt_t1[`PKT_DATA] << (addr_t1[2:0] * 8);



logic [7:0] base_be, mem_be;

always_comb
   case(pkt_t1[`PKT_SIZE])
      `OP_SZ_BYTE: base_be = 8'b0000_0001;
      `OP_SZ_WORD: base_be = 8'b0000_0011;
      `OP_SZ_LWRD: base_be = 8'b0000_1111;
      default:     base_be = 8'b1111_1111;
   endcase

assign mem_be = base_be << addr_t1[2:0];


always_ff@(posedge clk)
   if(write_t1)
   begin
      if (mem_be[7]) ram[{addr_t1[16:3], 3'd7}] <= wdata[8*7+:8];
      if (mem_be[6]) ram[{addr_t1[16:3], 3'd6}] <= wdata[8*6+:8];
      if (mem_be[5]) ram[{addr_t1[16:3], 3'd5}] <= wdata[8*5+:8];
      if (mem_be[4]) ram[{addr_t1[16:3], 3'd4}] <= wdata[8*4+:8];
      if (mem_be[3]) ram[{addr_t1[16:3], 3'd3}] <= wdata[8*3+:8];
      if (mem_be[2]) ram[{addr_t1[16:3], 3'd2}] <= wdata[8*2+:8];
      if (mem_be[1]) ram[{addr_t1[16:3], 3'd1}] <= wdata[8*1+:8];
      if (mem_be[0]) ram[{addr_t1[16:3], 3'd0}] <= wdata[8*0+:8];
   end



endmodule
