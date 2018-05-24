// Wbird
// 20180412
module ul_div_mod30 (
    input   [14:0]  A,
    output  [10:0]  D,
    output  [ 4:0]  M
);

//---------------------------------------------------------------------------
// A is a 15b unsigned number
// AC=A[14:10], AB=A[9:5], AA=A[4:0]
// A=34*30AC+30AB+(4*AC+2*AB+AA)
// E = 4*AC*2AB+AA
// ED=E[7:5], EE=E[4:0]
// E=30*ED+2*ED+EE
// G=2*ED+EE
// if G>=60,      G/30=2, G%30=G-60
// else if G>=30, G/30=1, G%30=G-30
// else           G/30=0, G%30=G
//---------------------------------------------------------------------------
wire [4:0] AA;
wire [4:0] AB;
wire [4:0] AC;
wire [7:0] E;
wire [2:0] ED;
wire [4:0] EE;
wire [5:0] G;
wire [1:0] GD30;
wire [4:0] GM30;
wire [6:0] AD30a;
wire [3:0] AD30b;
wire [9:0] AD30c;
wire [10:0] AD30;
wire [4:0] AM30;

assign AA = A[4:0];
assign AB = A[9:5];
assign AC = A[14:10];
assign E = {1'd0, AC, 2'd0} + {2'd0, AB, 1'd0} + {3'd0, AA};
assign ED = E[7:5];
assign EE = E[4:0];
assign G = {2'd0, E[7:5], 1'd0} + {1'd0, EE};
assign GD30 = (G[5:2] == 4'b1111) ? 2'd2 : (((G[5]==1) || (G[4:1]==4'b1111)) ? 2'd1 : 2'd0);
assign GM30 = (G[5:2] == 4'b1111) ? {3'd0, G[1:0]} : (((G[5]==1) || (G[4:1]==4'b1111)) ? (G[4:0]+5'b00010): G[4:0]);
assign AD30a = {1'd0, AC, 1'd0} + {2'd0, AB};
assign AD30b = {1'd0, ED} + {2'd0, GD30};
assign AD30c = {3'd0, AD30a} + {6'd0, AD30b};
assign AD30  = {1'd0, AD30c} + {1'd0, AC, 5'd0};
assign AM30 = GM30;

// output
assign D = AD30;
assign M = AM30;

endmodule
