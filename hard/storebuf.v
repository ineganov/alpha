`include "defines.vh"

module storebuf  (   input                 clk,
                     input                 reset,

                     // Input side
                     input                 store_e0,
                     input                 load_e0,
                     input           [1:0] op_size_e0,
                     input      [`VA_BITS] va_e0,     
                     input          [63:0] store_data_e0,

                     // Bypass side
                     output                stb_fail_e1, // Also set on overflow

                     // D$/Request side
                     output                rtr_st_vld_xx,
                     output          [7:0] rtr_st_be_xx,
                     output         [63:0] rtr_st_data_xx,
                     input      [`VA_BITS] rtr_st_addr_xx,     
                     input                 rtr_st_ack_xx );

logic  [7:0] be_e0, bitmask_e0, be_base_e0;
logic [63:0] writedata_e0;

// St data array: parameterize&replicate eventually?
logic            sbe_vld;
logic      [7:0] sbe_be;
logic     [63:0] sbe_data;
logic [`VA_BITS] sbe_addr;

logic            alloc;

always_comb
   case(op_size)
      `OP_SZ_BYTE: bitmask_e0 = 64'h0000_000f;
      `OP_SZ_WORD: bitmask_e0 = 64'h0000_00ff;
      `OP_SZ_LWRD: bitmask_e0 = 64'h0000_ffff;
      default:     bitmask_e0 = 64'hffff_ffff;
   endcase

always_comb
   case(op_size)
      `OP_SZ_BYTE: be_base_e0 = 8'b0000_0001;
      `OP_SZ_WORD: be_base_e0 = 8'b0000_0011;
      `OP_SZ_LWRD: be_base_e0 = 8'b0000_1111;
      default:     be_base_e0 = 8'b1111_1111;
   endcase

assign be_e0 = be_base_e0 << va_e0[2:0];
assign writedata_e0 = (store_data_e0 & bitmask_e0) << {va_e0[2:0], 3'd0};

assign alloc = store_e0 & (~sbe_vld | rtr_st_ack_xx);

always_ff@(posedge clk)
   if(reset | rtr_st_ack_xx )
      sbe_vld <= 1'b0;
   else if(alloc)
      sbe_vld <= 1'b1;

always_ff@(posedge clk)
   if(alloc)
   begin
      sbe_be   <= be_e0;
      sbe_data <= writedata_e0;
      sbe_addr <= va_e0;
   end

assign rtr_st_vld_xx  = sbe_vld;
assign rtr_st_be_xx   = sbe_be;
assign rtr_st_data_xx = sbe_data;
assign rtr_st_addr_xx = sbe_addr;

endmodule
