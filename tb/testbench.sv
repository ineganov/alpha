`include "defines.vh"

module testbench;

   logic             clk   = 0;
   logic             reset = 1;

   string cmp_log;

   integer fd;
   bit log_present = 1'b0;

   always #10ns clk = ~clk;

   int cycle; initial cycle = 0;
   always @ (posedge clk) begin
      cycle = cycle + 1;
      if (cycle > 1500)
      begin
         cycle = 0;
         $display ("Iteration Timeout");
         $stop;
      end
   end

   initial
   begin
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

   // a small bug workaround function
   // over Modelsim fdisplay default behavior
   // default:       2 -> ' 2'
   // this function: 2 -> '02'
   function string rfaddr2str(logic [4:0] addr);
      string out;
      out.itoa(addr);
      if(out.len()<2) out = { "0", out };
      return out;
   endfunction

   always_ff@(posedge clk)
   begin
      if(log_present & uut.igu.instn_grad_gr & uut.igu.rf_wen_gr)
         $fdisplay(fd, "%08x_%08x: %08x_%08x --> %02d", uut.igu.instn_pc_e1[63:32], 
                                                      uut.igu.instn_pc_e1[31:0 ],
                                                      uut.igu.rf_wdata_gr[63:32],
                                                      uut.igu.rf_wdata_gr[31:0 ],
                                                      rfaddr2str(uut.igu.rf_waddr_gr));

      // Emulate gem5 CMOVE behavior (failed CMOV writes the register to itself)
      if(   log_present 
         &  uut.igu.instn_grad_gr 
         &  uut.igu.log_cond_upd_e1
         & ~uut.igu.cmp_result_e1 )
         $fdisplay(fd, "%08x_%08x: %08x_%08x --> %02d", uut.igu.instn_pc_e1[63:32], 
                                                      uut.igu.instn_pc_e1[31:0 ],
                                                      uut.regfile.rf[uut.igu.rf_waddr_gr][63:32],
                                                      uut.regfile.rf[uut.igu.rf_waddr_gr][31:0 ],
                                                      rfaddr2str(uut.igu.rf_waddr_gr));

   end

   `define TB_MODE_ORIG
   // `define TB_MODE_MIU_MODEL
   // `define TB_MODE_COMPARE
   // `define TB_MODE_AHB

   logic [`PKT_BITS] mem_req_pkt_xx;
   logic             mem_req_ack_xx;
   logic [`PKT_BITS] mem_resp_pkt_xx;

   alpha_core uut ( 
      .clk              ( clk             ),
      .reset            ( reset           ),
      .mem_req_pkt_xx   ( mem_req_pkt_xx  ),
      .mem_req_ack_xx   ( mem_req_ack_xx  ),
      .mem_resp_pkt_xx  ( mem_resp_pkt_xx ) 
   );

   `ifdef TB_MODE_ORIG
      alpha_periph_bram_orig periph ( 
         .clk              ( clk             ),
         .reset            ( reset           ),
         .mem_req_pkt_xx   ( mem_req_pkt_xx  ),
         .mem_req_ack_xx   ( mem_req_ack_xx  ),
         .mem_resp_pkt_xx  ( mem_resp_pkt_xx ) 
      );
      
   `elsif TB_MODE_MIU_MODEL
      alpha_periph_bram_model periph ( 
         .clk              ( clk             ),
         .reset            ( reset           ),
         .cpu_req_pkt_xx   ( mem_req_pkt_xx  ),
         .cpu_req_ack_xx   ( mem_req_ack_xx  ),
         .cpu_resp_pkt_xx  ( mem_resp_pkt_xx ) 
      );

   `elsif TB_MODE_COMPARE
      wire             cpu_req_ack_xx;
      wire [`PKT_BITS] cpu_resp_pkt_xx;
      
      alpha_periph_bram_orig periph_orig ( 
         .clk              ( clk             ),
         .reset            ( reset           ),
         .mem_req_pkt_xx   ( mem_req_pkt_xx  ),
         .mem_req_ack_xx   ( mem_req_ack_xx  ),
         .mem_resp_pkt_xx  ( mem_resp_pkt_xx ) 
      );

      alpha_periph_bram_model periph_miu ( 
         .clk              ( clk             ),
         .reset            ( reset           ),
         .cpu_req_pkt_xx   ( mem_req_pkt_xx  ),
         .cpu_req_ack_xx   ( cpu_req_ack_xx  ),
         .cpu_resp_pkt_xx  ( cpu_resp_pkt_xx ) 
      );

      always @(posedge clk) assert(cpu_req_ack_xx === mem_req_ack_xx)
      else $error(" miu VS cpu: req_ack_xx problem!? \n cpu:%h\n mem:%h\n", cpu_req_ack_xx, mem_req_ack_xx );

      always @(posedge clk) assert(cpu_resp_pkt_xx === mem_resp_pkt_xx)
      else $error(" miu VS cpu: resp_pkt_xx problem!? \n cpu:%h\n mem:%h\n", cpu_resp_pkt_xx, mem_resp_pkt_xx );

   `else // TB_MODE_AHB
      localparam CONF_GPIO_WIDTH = 64;
      localparam CONF_BRAM_WIDTH = 14;
      wire [CONF_GPIO_WIDTH-1:0] periph_gpio_o;
      wire [CONF_GPIO_WIDTH-1:0] periph_gpio_i = ~periph_gpio_o;

      alpha_periph_ahb_lite #(
         .GPIO_WIDTH       ( CONF_GPIO_WIDTH ),
         .BRAM_WIDTH       ( CONF_BRAM_WIDTH ) 
      ) periph_ahb ( 
         .clk              ( clk             ),
         .reset            ( reset           ),
         .cpu_req_pkt_xx   ( mem_req_pkt_xx  ),
         .cpu_req_ack_xx   ( mem_req_ack_xx  ),
         .cpu_resp_pkt_xx  ( mem_resp_pkt_xx ),
         .periph_gpio_i    ( periph_gpio_i   ),
         .periph_gpio_o    ( periph_gpio_o   ) 
      );
   `endif

endmodule
