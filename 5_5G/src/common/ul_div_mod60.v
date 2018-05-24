// Wbird
// 20180413
module ul_div_mod60 (
    input   [11:0]  A,
    output  [ 6:0]  D,
    output  [ 5:0]  M
);

//---------------------------------------------------------------------------
// A is a 12b unsigned number
// AB=A[11:6], AA=A[5:0]
// A=60AB+(4*AB+AA)
// E = 4AB+AA
// EC=E[8:6], ED=E[5:0]
// E=60*EC+4*EC+ED
// G=4*EC+ED
// if G>=60,      G/60=1, G%60=G-60
// else           G/60=0, G%60=G
//---------------------------------------------------------------------------
wire [5:0] AA;
wire [5:0] AB;
wire [8:0] E;
wire [2:0] EC;
wire [5:0] ED;
wire [6:0] G;
wire       GD60;
wire [5:0] GM60;

wire [6:0] AD60a;
wire [6:0] AD60;
wire [5:0] AM60;

assign AA = A[5:0];
assign AB = A[11:6];
assign E = {1'd0, AB, 2'd0} + {3'd0, AA};
assign EC = E[8:6];
assign ED = E[5:0];
assign G = {2'd0, EC, 2'd0} + {1'd0, ED};
assign GD60 = ((G[6] == 1) || (G[5:2] == 4'b1111)) ? 1'd1 : 1'd0;
assign GM60 = ((G[6] == 1) || (G[5:2] == 4'b1111)) ? (G[5:0]-60) : G[5:0];
assign AD60a = {1'd0, AB} + {4'd0, EC} + {6'd0, GD60};
assign AD60 = AD60a;
assign AM60 = GM60;

// output
assign D = AD60;
assign M = AM60;

endmodule
