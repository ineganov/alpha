
module sdp_bram
#(
    parameter ADDR_WIDTH = 6,
              DATA_WIDTH = 1
)(
    input                       clk,
    input      [ADDR_WIDTH-1:0] wa,
    input                       we,
    input      [DATA_WIDTH-1:0] wd,
    input      [ADDR_WIDTH-1:0] ra,
    input                       re,
    output     [DATA_WIDTH-1:0] rd
);
    localparam RAM_SIZE  = 2**(ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] ram [RAM_SIZE - 1:0];
    reg [DATA_WIDTH-1:0] rdata;
    assign rd = rdata;

    always @(posedge clk)
        if (we) ram[wa] <= wd;

    always @(posedge clk)
        if (re) rdata <= ram [ra];

    `ifdef MEM64
    initial
        $readmemh(`MEM64, ram);
    `endif

endmodule
