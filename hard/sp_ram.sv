module sp_ram #(  parameter WIDTH = 32,
                  parameter DEPTH = 128            )
               (  input                      clk,
                  input  [$clog2(DEPTH)-1:0] addr,
               // input                      re,  // No read strobe: quartus likes we-only RAMs better
                  input                      we,
                  input          [WIDTH-1:0] wdata,
                  output logic   [WIDTH-1:0] rdata );

logic [WIDTH-1:0] ram[0:DEPTH-1];

always_ff@(posedge clk)
   if(we) ram[addr] <= wdata;

always_ff@(posedge clk)
   rdata <= ram[addr];

endmodule
