// ul pipelined cordic
module ul_cordic_pipeline (
    input                   clk,
    input                   rst_n,
    input                   cordic_en,
    input                   ang_en,
    input       [14:0]      ang_val,        // R15S13
    output                  amp_en,
    output      [11:0]      amp_i,          // C12S9
    output      [11:0]      amp_q,
    output      [13:0]      inner_en
);
// Internal Signals
//reg                     ang_en;            // angle pre-process
reg                     ang_en_d1;         // cordic step 0
// debug related signals
reg                     ang_en_d2;    // cordic step 0
reg     [13:0]          p_cdc_0;    // PHI R14U13
reg     [25:0]          i_cdc_0;    // I
reg     [25:0]          q_cdc_0;    // Q
reg                     ang_en_d3;    // cordic step 1
reg     [13:0]          p_cdc_1;    // PHI R14U13
reg     [25:0]          i_cdc_1;    // I
reg     [25:0]          q_cdc_1;    // Q
wire    [25:0]          t1_1;
wire    [25:0]          t2_1;
reg                     ang_en_d4;    // cordic step 2
reg     [13:0]          p_cdc_2;    // PHI R14U13
reg     [25:0]          i_cdc_2;    // I
reg     [25:0]          q_cdc_2;    // Q
wire    [25:0]          t1_2;
wire    [25:0]          t2_2;
reg                     ang_en_d5;    // cordic step 3
reg     [13:0]          p_cdc_3;    // PHI R14U13
reg     [25:0]          i_cdc_3;    // I
reg     [25:0]          q_cdc_3;    // Q
wire    [25:0]          t1_3;
wire    [25:0]          t2_3;
reg                     ang_en_d6;    // cordic step 4
reg     [13:0]          p_cdc_4;    // PHI R14U13
reg     [25:0]          i_cdc_4;    // I
reg     [25:0]          q_cdc_4;    // Q
wire    [25:0]          t1_4;
wire    [25:0]          t2_4;
reg                     ang_en_d7;    // cordic step 5
reg     [13:0]          p_cdc_5;    // PHI R14U13
reg     [25:0]          i_cdc_5;    // I
reg     [25:0]          q_cdc_5;    // Q
wire    [25:0]          t1_5;
wire    [25:0]          t2_5;
reg                     ang_en_d8;    // cordic step 6
reg     [13:0]          p_cdc_6;    // PHI R14U13
reg     [25:0]          i_cdc_6;    // I
reg     [25:0]          q_cdc_6;    // Q
wire    [25:0]          t1_6;
wire    [25:0]          t2_6;
reg                     ang_en_d9;    // cordic step 7
reg     [13:0]          p_cdc_7;    // PHI R14U13
reg     [25:0]          i_cdc_7;    // I
reg     [25:0]          q_cdc_7;    // Q
wire    [25:0]          t1_7;
wire    [25:0]          t2_7;
reg                     ang_en_d10;    // cordic step 8
reg     [13:0]          p_cdc_8;    // PHI R14U13
reg     [25:0]          i_cdc_8;    // I
reg     [25:0]          q_cdc_8;    // Q
wire    [25:0]          t1_8;
wire    [25:0]          t2_8;
reg                     ang_en_d11;    // cordic step 9
reg     [13:0]          p_cdc_9;    // PHI R14U13
reg     [25:0]          i_cdc_9;    // I
reg     [25:0]          q_cdc_9;    // Q
wire    [25:0]          t1_9;
wire    [25:0]          t2_9;
// end
reg                     ang_en_d12;        // amplitude post-process 1 : (i,q)*flag
reg                     ang_en_d13;        // output
wire    [25:0]          i_cdc_ini;  // INIT I R26S23
wire    [25:0]          q_cdc_ini;  // INIT Q R26S23
wire    [13:0]          p_adj_0;    // ADJ PHI R14U13
wire    [25:0]          i_adj_0;    // ADJ I
wire    [25:0]          q_adj_0;    // ADJ Q
wire    [13:0]          p_adj_1;    // ADJ PHI R14U13
wire    [25:0]          i_adj_1;    // ADJ I
wire    [25:0]          q_adj_1;    // ADJ Q
wire    [13:0]          p_adj_2;    // ADJ PHI R14U13
wire    [25:0]          i_adj_2;    // ADJ I
wire    [25:0]          q_adj_2;    // ADJ Q
wire    [13:0]          p_adj_3;    // ADJ PHI R14U13
wire    [25:0]          i_adj_3;    // ADJ I
wire    [25:0]          q_adj_3;    // ADJ Q
wire    [13:0]          p_adj_4;    // ADJ PHI R14U13
wire    [25:0]          i_adj_4;    // ADJ I
wire    [25:0]          q_adj_4;    // ADJ Q
wire    [13:0]          p_adj_5;    // ADJ PHI R14U13
wire    [25:0]          i_adj_5;    // ADJ I
wire    [25:0]          q_adj_5;    // ADJ Q
wire    [13:0]          p_adj_6;    // ADJ PHI R14U13
wire    [25:0]          i_adj_6;    // ADJ I
wire    [25:0]          q_adj_6;    // ADJ Q
wire    [13:0]          p_adj_7;    // ADJ PHI R14U13
wire    [25:0]          i_adj_7;    // ADJ I
wire    [25:0]          q_adj_7;    // ADJ Q
wire    [13:0]          p_adj_8;    // ADJ PHI R14U13
wire    [25:0]          i_adj_8;    // ADJ I
wire    [25:0]          q_adj_8;    // ADJ Q
wire    [13:0]          p_adj_9;    // ADJ PHI R14U13
wire    [25:0]          i_adj_9;    // ADJ I
wire    [25:0]          q_adj_9;    // ADJ Q
reg     [ 1:0]          flag_0;
reg     [ 1:0]          flag_1;
reg     [ 1:0]          flag_2;
reg     [ 1:0]          flag_3;
reg     [ 1:0]          flag_4;
reg     [ 1:0]          flag_5;
reg     [ 1:0]          flag_6;
reg     [ 1:0]          flag_7;
reg     [ 1:0]          flag_8;
reg     [ 1:0]          flag_9;
reg     [ 1:0]          flag_10;
wire [11:0] ki;             // R12U12
assign ki = 12'd2487;
reg     [7:0]               cnt;                // debug only
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cnt <= 0;
    end
    else begin
        if (ang_en_d2) begin
            cnt <= cnt + 1;
        end
        else begin
            cnt <= 0;
        end
    end
end
// control signals
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ang_en_d1 <= 0;
        ang_en_d2 <= 0;
        ang_en_d3 <= 0;
        ang_en_d4 <= 0;
        ang_en_d5 <= 0;
        ang_en_d6 <= 0;
        ang_en_d7 <= 0;
        ang_en_d8 <= 0;
        ang_en_d9 <= 0;
        ang_en_d10 <= 0;
        ang_en_d11 <= 0;
        ang_en_d12 <= 0;
        ang_en_d13 <= 0;
    end
    else begin
        if (cordic_en) begin
            ang_en_d1 <= ang_en;
            ang_en_d2 <= ang_en_d1;
            ang_en_d3 <= ang_en_d2;
            ang_en_d4 <= ang_en_d3;
            ang_en_d5 <= ang_en_d4;
            ang_en_d6 <= ang_en_d5;
            ang_en_d7 <= ang_en_d6;
            ang_en_d8 <= ang_en_d7;
            ang_en_d9 <= ang_en_d8;
            ang_en_d10 <= ang_en_d9;
            ang_en_d11 <= ang_en_d10;
            ang_en_d12 <= ang_en_d11;
            ang_en_d13 <= ang_en_d12;
        end
    end
end
// stage 0 : pre-process of cordic
reg     [ 1:0]          flag;           // 00: 1    01: -1      10: j       11: -j
reg     [13:0]          ang_rnd;        // R14S13
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        flag <= 0;
        ang_rnd <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en) begin
                // if ang >= 1/2, ang = ang - 1/2, [4096, 16383], ang = ang - 4096
                if (($unsigned(ang_val[14:0] >= 15'd4096)) && ($unsigned(ang_val[14:0] <= 15'd16383))) begin
                    ang_rnd <= ang_val[13:0] - 14'd4096;
                    flag <= 2'b10;
                end
                // else if ang < -1/2, ang = ang + 1/2, [16384, 28672], ang = ang + 4096
                else if (($unsigned(ang_val[14:0] >= 15'd16384)) && ($unsigned(ang_val[14:0] <= 15'd28672))) begin
                    ang_rnd <= ang_val[13:0] + 14'd4096;
                    flag <= 2'b11;
                end
                else begin
                    ang_rnd <= ang_val[13:0];
                    flag <= 2'b00;
                end
            end
        end
    end
end
// Name Alias
wire [13:0] phi_rnd; // R14S13
assign phi_rnd = ang_rnd;
// stage 1 : cordic stage 0
assign i_cdc_ini = 26'h0800000;     // 1
assign q_cdc_ini = 26'h0000000;     // 0
assign p_adj_0 = (phi_rnd[13] == 1 || phi_rnd[12:0] == 0) ? (-14'd2048) : 14'd2048;
assign i_adj_0 = (phi_rnd[13] == 1 || phi_rnd[12:0] == 0) ? (-q_cdc_ini) : q_cdc_ini;
assign q_adj_0 = (phi_rnd[13] == 1 || phi_rnd[12:0] == 0) ? (-i_cdc_ini) : i_cdc_ini;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_0 <= 0;
        q_cdc_0 <= 0;
        p_cdc_0 <= 0;
        flag_0 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d1) begin
                flag_0 <= flag;
                p_cdc_0 <= phi_rnd - p_adj_0;
                i_cdc_0 <= i_cdc_ini - i_adj_0;
                q_cdc_0 <= q_cdc_ini + q_adj_0;
            end
        end
    end
end
// stage 2 : cordic stage 1
assign p_adj_1 = (p_cdc_0[13] == 1 || p_cdc_0[12:0] == 0) ? (-14'd1209) : 14'd1209;
assign i_adj_1 = (p_cdc_0[13] == 1 || p_cdc_0[12:0] == 0) ? (-q_cdc_0) : q_cdc_0;
assign q_adj_1 = (p_cdc_0[13] == 1 || p_cdc_0[12:0] == 0) ? (-i_cdc_0) : i_cdc_0;
assign t1_1 = {{1{i_adj_1[25]}}, i_adj_1[25:1]};
assign t2_1 = {{1{q_adj_1[25]}}, q_adj_1[25:1]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_1 <= 0;
        q_cdc_1 <= 0;
        p_cdc_1 <= 0;
        flag_1 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d2) begin
                flag_1 <= flag_0;
                p_cdc_1 <= p_cdc_0 - p_adj_1;
                i_cdc_1 <= i_cdc_0 - t1_1;
                q_cdc_1 <= q_cdc_0 + t2_1;
            end
        end
    end
end
// stage 3 : cordic stage 2
assign p_adj_2 = (p_cdc_1[13] == 1 || p_cdc_1[12:0] == 0) ? (-14'd639) : 14'd639;
assign i_adj_2 = (p_cdc_1[13] == 1 || p_cdc_1[12:0] == 0) ? (-q_cdc_1) : q_cdc_1;
assign q_adj_2 = (p_cdc_1[13] == 1 || p_cdc_1[12:0] == 0) ? (-i_cdc_1) : i_cdc_1;
assign t1_2 = {{2{i_adj_2[25]}}, i_adj_2[25:2]};
assign t2_2 = {{2{q_adj_2[25]}}, q_adj_2[25:2]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_2 <= 0;
        q_cdc_2 <= 0;
        p_cdc_2 <= 0;
        flag_2 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d3) begin
                flag_2 <= flag_1;
                p_cdc_2 <= p_cdc_1 - p_adj_2;
                i_cdc_2 <= i_cdc_1 - t1_2;
                q_cdc_2 <= q_cdc_1 + t2_2;
            end
        end
    end
end
// stage 4 : cordic stage 3
assign p_adj_3 = (p_cdc_2[13] == 1 || p_cdc_2[12:0] == 0) ? (-14'd324) : 14'd324;
assign i_adj_3 = (p_cdc_2[13] == 1 || p_cdc_2[12:0] == 0) ? (-q_cdc_2) : q_cdc_2;
assign q_adj_3 = (p_cdc_2[13] == 1 || p_cdc_2[12:0] == 0) ? (-i_cdc_2) : i_cdc_2;
assign t1_3 = {{3{i_adj_3[25]}}, i_adj_3[25:3]};
assign t2_3 = {{3{q_adj_3[25]}}, q_adj_3[25:3]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_3 <= 0;
        q_cdc_3 <= 0;
        p_cdc_3 <= 0;
        flag_3 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d4) begin
                flag_3 <= flag_2;
                p_cdc_3 <= p_cdc_2 - p_adj_3;
                i_cdc_3 <= i_cdc_2 - t1_3;
                q_cdc_3 <= q_cdc_2 + t2_3;
            end
        end
    end
end
// stage 5 : cordic stage 4
assign p_adj_4 = (p_cdc_3[13] == 1 || p_cdc_3[12:0] == 0) ? (-14'd163) : 14'd163;
assign i_adj_4 = (p_cdc_3[13] == 1 || p_cdc_3[12:0] == 0) ? (-q_cdc_3) : q_cdc_3;
assign q_adj_4 = (p_cdc_3[13] == 1 || p_cdc_3[12:0] == 0) ? (-i_cdc_3) : i_cdc_3;
assign t1_4 = {{4{i_adj_4[25]}}, i_adj_4[25:4]};
assign t2_4 = {{4{q_adj_4[25]}}, q_adj_4[25:4]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_4 <= 0;
        q_cdc_4 <= 0;
        p_cdc_4 <= 0;
        flag_4 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d5) begin
                flag_4 <= flag_3;
                p_cdc_4 <= p_cdc_3 - p_adj_4;
                i_cdc_4 <= i_cdc_3 - t1_4;
                q_cdc_4 <= q_cdc_3 + t2_4;
            end
        end
    end
end
// stage 6 : cordic stage 5
assign p_adj_5 = (p_cdc_4[13] == 1 || p_cdc_4[12:0] == 0) ? (-14'd81) : 14'd81;
assign i_adj_5 = (p_cdc_4[13] == 1 || p_cdc_4[12:0] == 0) ? (-q_cdc_4) : q_cdc_4;
assign q_adj_5 = (p_cdc_4[13] == 1 || p_cdc_4[12:0] == 0) ? (-i_cdc_4) : i_cdc_4;
assign t1_5 = {{5{i_adj_5[25]}}, i_adj_5[25:5]};
assign t2_5 = {{5{q_adj_5[25]}}, q_adj_5[25:5]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_5 <= 0;
        q_cdc_5 <= 0;
        p_cdc_5 <= 0;
        flag_5 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d6) begin
                flag_5 <= flag_4;
                p_cdc_5 <= p_cdc_4 - p_adj_5;
                i_cdc_5 <= i_cdc_4 - t1_5;
                q_cdc_5 <= q_cdc_4 + t2_5;
            end
        end
    end
end
// stage 7 : cordic stage 6
assign p_adj_6 = (p_cdc_5[13] == 1 || p_cdc_5[12:0] == 0) ? (-14'd41) : 14'd41;
assign i_adj_6 = (p_cdc_5[13] == 1 || p_cdc_5[12:0] == 0) ? (-q_cdc_5) : q_cdc_5;
assign q_adj_6 = (p_cdc_5[13] == 1 || p_cdc_5[12:0] == 0) ? (-i_cdc_5) : i_cdc_5;
assign t1_6 = {{6{i_adj_6[25]}}, i_adj_6[25:6]};
assign t2_6 = {{6{q_adj_6[25]}}, q_adj_6[25:6]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_6 <= 0;
        q_cdc_6 <= 0;
        p_cdc_6 <= 0;
        flag_6 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d7) begin
                flag_6 <= flag_5;
                p_cdc_6 <= p_cdc_5 - p_adj_6;
                i_cdc_6 <= i_cdc_5 - t1_6;
                q_cdc_6 <= q_cdc_5 + t2_6;
            end
        end
    end
end
// stage 8 : cordic stage 7
assign p_adj_7 = (p_cdc_6[13] == 1 || p_cdc_6[12:0] == 0) ? (-14'd20) : 14'd20;
assign i_adj_7 = (p_cdc_6[13] == 1 || p_cdc_6[12:0] == 0) ? (-q_cdc_6) : q_cdc_6;
assign q_adj_7 = (p_cdc_6[13] == 1 || p_cdc_6[12:0] == 0) ? (-i_cdc_6) : i_cdc_6;
assign t1_7 = {{7{i_adj_7[25]}}, i_adj_7[25:7]};
assign t2_7 = {{7{q_adj_7[25]}}, q_adj_7[25:7]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_7 <= 0;
        q_cdc_7 <= 0;
        p_cdc_7 <= 0;
        flag_7 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d8) begin
                flag_7 <= flag_6;
                p_cdc_7 <= p_cdc_6 - p_adj_7;
                i_cdc_7 <= i_cdc_6 - t1_7;
                q_cdc_7 <= q_cdc_6 + t2_7;
            end
        end
    end
end
// stage 9 : cordic stage 8
assign p_adj_8 = (p_cdc_7[13] == 1 || p_cdc_7[12:0] == 0) ? (-14'd10) : 14'd10;
assign i_adj_8 = (p_cdc_7[13] == 1 || p_cdc_7[12:0] == 0) ? (-q_cdc_7) : q_cdc_7;
assign q_adj_8 = (p_cdc_7[13] == 1 || p_cdc_7[12:0] == 0) ? (-i_cdc_7) : i_cdc_7;
assign t1_8 = {{8{i_adj_8[25]}}, i_adj_8[25:8]};
assign t2_8 = {{8{q_adj_8[25]}}, q_adj_8[25:8]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_8 <= 0;
        q_cdc_8 <= 0;
        p_cdc_8 <= 0;
        flag_8 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d9) begin
                flag_8 <= flag_7;
                p_cdc_8 <= p_cdc_7 - p_adj_8;
                i_cdc_8 <= i_cdc_7 - t1_8;
                q_cdc_8 <= q_cdc_7 + t2_8;
            end
        end
    end
end
// stage 10 : cordic stage 9
assign p_adj_9 = (p_cdc_8[13] == 1 || p_cdc_8[12:0] == 0) ? (-14'd5) : 14'd5;
assign i_adj_9 = (p_cdc_8[13] == 1 || p_cdc_8[12:0] == 0) ? (-q_cdc_8) : q_cdc_8;
assign q_adj_9 = (p_cdc_8[13] == 1 || p_cdc_8[12:0] == 0) ? (-i_cdc_8) : i_cdc_8;
assign t1_9 = {{9{i_adj_9[25]}}, i_adj_9[25:9]};
assign t2_9 = {{9{q_adj_9[25]}}, q_adj_9[25:9]};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_cdc_9 <= 0;
        q_cdc_9 <= 0;
        p_cdc_9 <= 0;
        flag_9 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d10) begin
                flag_9 <= flag_8;
                p_cdc_9 <= p_cdc_8 - p_adj_9;
                i_cdc_9 <= i_cdc_8 - t1_9;
                q_cdc_9 <= q_cdc_8 + t2_9;
            end
        end
    end
end
// stage 11 : (i, q) * ki
wire    [38:0]          i_mul_ki;   // C26S23*R13U12 = R39S35
wire    [38:0]          q_mul_ki;
reg     [11:0]          i_ki;       // C12S9
reg     [11:0]          q_ki;
assign i_mul_ki = $signed(i_cdc_9) * $signed({1'd0, ki});
assign q_mul_ki = $signed(q_cdc_9) * $signed({1'd0, ki});
//wire [12:0] i_round;    // R13S9
//wire [12:0] q_round;
//assign i_round = i_mul_ki[25] ? (i_mul_ki[38] ? (i_mul_ki[38:26] - 1) : (i_mul_ki[38:26] + 1)) : i_mul_ki[38:26];
//assign q_round = q_mul_ki[25] ? (q_mul_ki[38] ? (q_mul_ki[38:26] - 1) : (q_mul_ki[38:26] + 1)) : q_mul_ki[38:26];
wire [12:0] i_floor;    // R13S9
wire [12:0] q_floor;
assign i_floor = i_mul_ki[38:26];
assign q_floor = q_mul_ki[38:26];
wire [11:0] i_sat;      // R12S9
wire [11:0] q_sat;
assign i_sat = (i_floor[12] == 0 && i_floor[11:0] > 12'h7ff) ? 12'h7ff : ((i_floor[12] == 1 && i_floor[11:0] < 12'h800) ? 12'h800 : i_floor[11:0]);
assign q_sat = (q_floor[12] == 0 && q_floor[11:0] > 12'h7ff) ? 12'h7ff : ((q_floor[12] == 1 && q_floor[11:0] < 12'h800) ? 12'h800 : q_floor[11:0]);
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i_ki <= 0;
        q_ki <= 0;
        flag_10 <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d11) begin   // Truncate Method: signed floor
                flag_10 <= flag_9;
                i_ki <= i_sat;
                q_ki <= q_sat;
            end
        end
    end
end
// stage 12 : (i, q) * flag
reg     [11:0]          i;
reg     [11:0]          q;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        i <= 0;
        q <= 0;
    end
    else begin
        if (cordic_en) begin
            if (ang_en_d12) begin
                case (flag_10)
                    2'b00 : begin       // 1
                        i <= +i_ki;
                        q <= +q_ki;
                    end
                    2'b01 : begin       // -1
                        i <= -i_ki;
                        q <= -q_ki;
                    end
                    2'b10 : begin       // j
                        i <= -q_ki;     // i = -q
                        q <= +i_ki;     // q = i
                    end
                    2'b11 : begin       // -j
                        i <= +q_ki;     // i = q
                        q <= -i_ki;     // q = -i
                    end
                endcase
            end
        end
    end
end
// output
assign amp_en = ang_en_d13;
assign amp_i  = i;
assign amp_q  = q;
assign inner_en[13] = ang_en_d13;
assign inner_en[12] = ang_en_d12;
assign inner_en[11] = ang_en_d11;
assign inner_en[10] = ang_en_d10;
assign inner_en[9] = ang_en_d9;
assign inner_en[8] = ang_en_d8;
assign inner_en[7] = ang_en_d7;
assign inner_en[6] = ang_en_d6;
assign inner_en[5] = ang_en_d5;
assign inner_en[4] = ang_en_d4;
assign inner_en[3] = ang_en_d3;
assign inner_en[2] = ang_en_d2;
assign inner_en[1] = ang_en_d1;
assign inner_en[0] = ang_en;

endmodule
