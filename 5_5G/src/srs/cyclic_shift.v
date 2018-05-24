module cyclic_shift (
    // input
    input               ktc,
    input       [ 1:0]  ap_num,     // 00: 1    01: 2     11:4
    input       [ 3:0]  srs_cs,
    // output
    output      [ 3:0]  a0,
    output      [ 3:0]  a1,
    output      [ 3:0]  a2,
    output      [ 3:0]  a3
);

wire [3:0] srs_cs_max;
assign srs_cs_max = ktc ? 4'd12 : 4'd8;

// a0
assign a0 = ($unsigned(srs_cs) < $unsigned(srs_cs_max)) ? srs_cs : (srs_cs - srs_cs_max);

// a1
wire [4:0] a1_plus0;
wire [4:0] a1_plus1;
wire [4:0] a1_mod0;
wire [4:0] a1_mod1;
assign a1_plus0 = srs_cs + {1'd0, srs_cs_max[3:1]};
assign a1_plus1 = srs_cs + {2'd0, srs_cs_max[3:2]};
assign a1_mod0 = ($unsigned(a1_plus0) < $unsigned(srs_cs_max)) ? a1_plus0 : (a1_plus0 - {1'd0, srs_cs_max});
assign a1_mod1 = ($unsigned(a1_plus1) < $unsigned(srs_cs_max)) ? a1_plus1 : (a1_plus1 - {1'd0, srs_cs_max});
assign a1 = (ap_num==2'd1) ? a1_mod0[3:0] : a1_mod1[3:0];

// a2
wire [4:0] a2_plus;
wire [4:0] a2_mod;
assign a2_plus = srs_cs + {1'd0, srs_cs_max[3:1]};
assign a2_mod = ($unsigned(a2_plus) < $unsigned(srs_cs_max)) ? a2_plus : (a2_plus - {1'd0, srs_cs_max});
assign a2 = (ap_num==2'd3) ? a2_mod[3:0] : 4'd0;

// a3
wire [4:0] a3_plus;
wire [4:0] a3_mod;
assign a3_plus = srs_cs + {1'd0, srs_cs_max[3:1]} + {2'd0, srs_cs_max[3:2]};
assign a3_mod = ($unsigned(a3_plus) < $unsigned(srs_cs_max)) ? a3_plus : (a3_plus - {1'd0, srs_cs_max});
assign a3 = (ap_num==2'd3) ? a3_mod[3:0] : 4'd0;

endmodule
