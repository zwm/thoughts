module ul_mod_2stage #(
    parameter   DIVISOR_WIDTH       = 8) (
    input  [DIVISOR_WIDTH-1:0]      init,
    input  [1:0]                    dividend,
    input   [DIVISOR_WIDTH-1:0]     divider,
    output  [DIVISOR_WIDTH-1:0]     remainder
);

// mod stage 0
wire [DIVISOR_WIDTH:0] stg0_i;
assign stg0_i = {init, dividend[1]};
wire [DIVISOR_WIDTH+1:0] stg0_sub;
assign stg0_sub = {1'd0, stg0_i} - {2'd0, divider};
wire [DIVISOR_WIDTH-1:0] stg0_mod;
assign stg0_mod = stg0_sub[DIVISOR_WIDTH+1] ? stg0_i[DIVISOR_WIDTH-1:0] : stg0_sub[DIVISOR_WIDTH-1:0];

// mod stage 1
wire [DIVISOR_WIDTH:0] stg1_i;
assign stg1_i = {stg0_mod, dividend[0]};
wire [DIVISOR_WIDTH+1:0] stg1_sub;
assign stg1_sub = {1'd0, stg1_i} - {2'd0, divider};
wire [DIVISOR_WIDTH-1:0] stg1_mod;
assign stg1_mod = stg1_sub[DIVISOR_WIDTH+1] ? stg1_i[DIVISOR_WIDTH-1:0] : stg1_sub[DIVISOR_WIDTH-1:0];

// output
assign remainder = stg1_mod;

endmodule
