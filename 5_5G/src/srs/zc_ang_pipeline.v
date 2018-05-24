// 201804071109
// Wbird
module zc_ang_pipeline (
    // sys
    input               clk,
    input               rst_n,
    input               start,
    output reg          busy,
    output              done,
    // input
    input       [ 3:0]  alpha_p,
    input       [10:0]  n_zc,
    input       [10:0]  m_sc,
    input       [ 4:0]  u,
    input               v,
    input               ktc,
    input       [14:0]  a,
    input       [13:0]  b,

    output              phi_en,
    output      [11:0]  phi_val     // R12S10
);

//---------------------------------------------------------------------------
// Args
//---------------------------------------------------------------------------
// ZC Length

//---------------------------------------------------------------------------
// BUSY & DONE
//---------------------------------------------------------------------------
// busy
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        busy <= 0;
    end
    else begin
        if (~busy) begin
            if (start) begin
                busy <= 1;
            end
        end
        else begin
            if (done) begin
                busy <= 0;
            end
        end
    end
end
// done
reg phi_en_d1;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        phi_en_d1 <= 0;
    end
    else begin
        phi_en_d1 <= phi_en;
    end
end
assign done = (~phi_en) & phi_en_d1;
//---------------------------------------------------------------------------
// steps after start
//---------------------------------------------------------------------------
reg ini_step1;
reg ini_step2;
reg ini_step3;
reg ini_step4;
reg ini_step5;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ini_step1 <= 0;
        ini_step2 <= 0;
        ini_step3 <= 0;
        ini_step4 <= 0;
        ini_step5 <= 0;
    end
    else begin
        ini_step1 <= start & (~busy);
        ini_step2 <= ini_step1;
        ini_step3 <= ini_step2;
        ini_step4 <= ini_step3;
        ini_step5 <= ini_step4;
    end
end
//---------------------------------------------------------------------------
// q
//---------------------------------------------------------------------------
// step0: zc_mul_u_a1 = n_zc*(u+1)
// step1: q_bar_mul2 = (zc_mul_u_a1<<1)/31
// step2: q=part1+part2, part1=(q_bar_mul2+1)>>1, part2=v*((-1)**q_bar_mul2), 
// step0
wire [15:0] zc_mul_u_a1_w;
reg  [15:0] zc_mul_u_a1;
wire [4:0] u_a1;
assign u_a1 = u + 1;
assign zc_mul_u_a1_w = n_zc * u_a1;     // R5U0*R11U0=R16U0
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        zc_mul_u_a1 <= 0;
    end
    else begin
        if (start) begin
            zc_mul_u_a1 <= zc_mul_u_a1_w;
        end
    end
end
// step1
wire [16:0] zc_mul_u_a1_mul2;
wire [16:0] one_div_thirty_one; // R17U21
wire [33:0] mul_17b_17b;        // R17U0*R17U21
reg  [12:0] q_bar_mul2;
assign zc_mul_u_a1_mul2 = {zc_mul_u_a1, 1'd0};
assign one_div_thirty_one = (ktc == 0 && m_sc == 12'd144) ? 17'd67651 : 17'd67650;
assign mul_17b_17b = zc_mul_u_a1_mul2*one_div_thirty_one;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        q_bar_mul2 <= 0;
    end
    else begin
        if (ini_step1) begin
            q_bar_mul2 <= mul_17b_17b[33:21];
        end
    end
end
// step2
wire [13:0] q_bar_mul2_a1;
wire [13:0] v_mul_neg1;
wire [13:0] part1_add_part2;
reg [10:0] q;
assign q_bar_mul2_a1 = {1'd0, q_bar_mul2} + 1;
assign v_mul_neg1 = v ? (q_bar_mul2[0] ? (-1) : (+1)) : 0;
assign part1_add_part2 = {1'd0, q_bar_mul2_a1[13:1]} + v_mul_neg1;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        q <= 0;
    end
    else begin
        if (ini_step2) begin
            q <= part1_add_part2[10:0];     // mismatch!!! how to round??? !!!
        end
    end
end
//---------------------------------------------------------------------------
// omega
//---------------------------------------------------------------------------
// step 0: omega = N_CS_RS_MAX * N_RS_ZC    R4U0*R11U0 = R15U0
wire [3:0] srs_cs_max;
assign srs_cs_max = ktc ? 4'd12 : 4'd8;
reg [14:0] omega;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        omega <= 0;
    end
    else begin
        if (start) begin
            omega = srs_cs_max * n_zc;
        end
    end
end
wire [15:0] omega2;
assign omega2 = {omega, 1'd0};
//---------------------------------------------------------------------------
// 2Q
//---------------------------------------------------------------------------
// step 3: Q = q*N_CS_RS_MAX, max (N_RS_ZC+1)*N_CS_RS_MAX < 2*N_RS_ZC*N_CS_RS_MAX
// step 4: Q = mod(Q, 2omega), if Q > 2omega, Q=Q-2omega, else Q=Q
//          20180409, q_max=N_RS_ZC+1, Q = (N_RS_ZC+1)*N_CS_RS_MAX
//          < (N_RS_ZC+N_RS_ZC)*N_CS_RS_MAX, no need to do mod() operation
// step 5: 2Q = mod(2Q, 2omega), if 2Q > 2omega, 2Q=2Q-2omega, else 2Q=2Q
reg [15:0] ini_Q2;
wire [15:0] ini_Q_sub_omega2;
assign ini_Q_sub_omega2 = ini_Q2 - omega2;
wire [16:0] ini_Q2_sub_omega2;
assign ini_Q2_sub_omega2 = {ini_Q2, 1'd0} - {1'd0, omega2};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ini_Q2 <= 0;
    end
    else begin
        if (ini_step3) begin
            ini_Q2[15] <= 0;
            ini_Q2[14:0] <= srs_cs_max * q;
        end
        else if (ini_step4) begin // acturally no need!!
            if (($unsigned(ini_Q2) > $unsigned(omega2)) || ($unsigned(ini_Q2) == $unsigned(omega2))) begin
                ini_Q2 <= ini_Q_sub_omega2[14:0];
            end
        end
        else if (ini_step5) begin
            if (($unsigned({ini_Q2, 1'd0}) > $unsigned(omega2)) || ($unsigned({ini_Q2, 1'd0}) == $unsigned(omega2))) begin
                ini_Q2 <= ini_Q2_sub_omega[15:0];
            end
            else begin
                ini_Q2 <= {ini_Q2[14:0], 1'd0};
            end
        end
    end
end
//---------------------------------------------------------------------------
// 2Q_bar
//---------------------------------------------------------------------------
// step 0: Q_bar = alpha_p * N_RS_ZC    R4U0*R11U0 = R15U0
// step 1: Q_bar = mod(Q_bar, omega2)
// step 2: Q2_bar = mod(Q2_bar, omega2)
reg [15:0] ini_Q2_bar;
wire [15:0] ini_Q_bar_sub_omega2;
assign ini_Q_bar_sub_omega2 = ini_Q2_bar - omega2;
wire [16:0] ini_Q2_bar_sub_omega2;
assign ini_Q2_bar_sub_omega2 = {ini_Q2_bar, 1'd0} - {1'd0, omega2};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ini_Q2_bar <= 0;
    end
    else begin
        if (start) begin
            ini_Q2_bar[15] = 0;
            ini_Q2_bar[14:0] = alpha_p * n_zc;
        end
        else if (ini_step1) begin
            if (($unsigned(ini_Q2_bar) > $unsigned(omega2)) || ($unsigned(ini_Q2_bar) == $unsigned(omega2))) begin
                ini_Q2_bar <= ini_Q_bar_sub_omega2;
            end
        end
        else if (ini_step2) begin
            if (($unsigned({ini_Q2_bar, 1'd0}) > $unsigned(omega2)) || ($unsigned({ini_Q2_bar, 1'd0}) == $unsigned(omega2))) begin
                ini_Q2_bar <= ini_Q2_bar_sub_omega2[15:0];
            end
            else begin
                ini_Q2_bar <= {ini_Q2_bar[14:0], 1'd0};
            end
        end
    end
end
//---------------------------------------------------------------------------
// Pipeline 0
//---------------------------------------------------------------------------
// 2Q*(m+1)
reg pip_0_en;
reg [10:0] n;   // 0~M_RS_SC-1
reg [10:0] m;   // mod(n, N_RS_ZC)
// pip_0_en
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_0_en <= 0;
    end
    else begin
        if (~pip_0_en) begin
            if (ini_step5) begin
                pip_0_en <= 1;
            end
        end
        else begin
            if (n == (m_sc-1)) begin
                pip_0_en <= 0;
            end
        end
    end
end
// n, m
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        n <= 0;
        m <= 0;
    end
    else begin
        if (ini_step5) begin
            n <= 0;
            m <= 0;
        end
        else if (pip_0_en) begin
            n <= n + 1;
            if (m == (n_zc-1)) begin
                m <= 0;
            end
            else begin
                m <= m + 1;
            end
        end
    end
end
// Q2_m
reg [15:0] Q2_m;
wire [16:0] Q2_m_plus_Q2;
wire [16:0] Q2_m_plus_Q2_sub_omega2;
assign Q2_m_plus_Q2 = {1'd0, Q2_m} + {1'd0, ini_Q2};
assign Q2_m_plus_Q2_sub_omega = Q2_m_plus_Q2 - {1'd0, omega2};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        Q2_m <= 0;
    end
    else begin
        if (ini_step5) begin
            Q2_m <= ini_Q2;
        end
        else if (pip_0_en) begin
            if (m == (n_zc-1)) begin
                Q2_m <= ini_Q2;
            end
            else begin
                if (($unsigned(Q2_m_plus_Q2) > $unsigned(omega2)) || ($unsigned(Q2_m_plus_Q2) == $unsigned(omega2))) begin
                    Q2_m <= Q2_m_plus_Q2_sub_omega2[15:0];
                end
                else begin
                    Q2_m <= Q2_m_plus_Q2[15:0];
                end
            end
        end
    end
end
// b_m = mod(b_m+2Q*m, omega2)
reg [15:0] b_m;
wire [16:0] bm_plus_Q2;
assign bm_plus_Q2 = {1'd0, b_m} + {1'd0, Q2_m};
wire [16:0] bm_plus_Q2_sub_omega2;
assign bm_plus_Q2_sub_omega2 = bm_plus_Q2 - {1'd0, omega2};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        b_m <= 0;
    end
    else begin
        if (ini_step5) begin
            b_m <= 0;
        end
        else begin
            if (m == (n_zc-1)) begin
                b_m <= 0;
            end
            else begin
                if (($unsigned(bm_plus_Q2) > $unsigned(omega2)) || ($unsigned(bm_plus_Q2) == $unsigned(omega2))) begin
                    b_m <= bm_plus_Q2_sub_omega2[15:0];
                end
                else begin
                    b_m <= bm_plus_Q2[15:0];
                end
            end
        end
    end
end
// b_n = mod(b_n+2Q_bar, omega2)
reg [15:0] b_n;
wire [16:0] bn_plus_Q2_bar;
assign bn_plus_Q2_bar = {1'd0, b_m} + {1'd0, ini_Q2_bar};
wire [16:0] bn_plus_Q2_bar_sub_omega2;
assign bn_plus_Q2_bar_sub_omega2 = bn_plus_Q2_bar - {1'd0, omega2};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        b_n <= 0;
    end
    else begin
        if (ini_step5) begin
            b_n <= 0;
        end
        else begin
            if (($unsigned(bn_plus_Q2_bar) > $unsigned(omega2)) || ($unsigned(bn_plus_Q2_bar) == $unsigned(omega2))) begin
                b_n <= bn_plus_Q2_bar_sub_omega2[15:0];
            end
            else begin
                b_n <= bn_plus_Q2_bar[15:0];
            end
        end
    end
end
//---------------------------------------------------------------------------
// Pipeline 1
//---------------------------------------------------------------------------
// theta = mod(bn-bm, 2omega)
reg pip_1_en;
reg [15:0] theta;
wire [16:0] bn_sub_bm;
assign bn_sub_bm = {1'd0, b_n} - {1'd0, b_m};
wire [16:0] bn_sub_bm_plus_omega2;
assign bn_sub_bm_plus_omega2 = bn_sub_bm + {1'd0, omega2};
// en
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_1_en <= 0;
    end
    else begin
        pip_1_en <= pip_0_en;
    end
end
// theta
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        theta <= 0;
    end
    else begin
        if (pip_0_en) begin
            if (bn_sub_bm[16]) begin
                theta <= bn_sub_bm_plus_omega2[15:0];
            end
            else begin
                theta <= bn_sub_bm[15:0];
            end
        end
    end
end
//---------------------------------------------------------------------------
// Pipeline 2
//---------------------------------------------------------------------------
// t = theta if theta < omega else (theta - 2omega)
reg pip_2_en;
reg [15:0] t;
wire [15:0] theta_sub_omega2;
assign theta_sub_omega2 = theta - omega2;
// en
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_2_en <= 0;
    end
    else begin
        pip_2_en <= pip_1_en;
    end
end
// t
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t <= 0;
    end
    else begin
        if (pip_1_en) begin
            if ($unsigned(theta) < $unsigned(omega)) begin
                t <= theta;
            end
            else begin
                t <= theta_sub_omega2;
            end
        end
    end
end
//---------------------------------------------------------------------------
// Pipeline 3
//---------------------------------------------------------------------------
// phi = T/omega
reg pip_3_en;
reg [11:0] phi;
wire [13:0] mul_i0;
wire [15:0] mul_i1;
wire [29:0] mul_q;
assign mul_i0 = k_tc ? t[15:2] : {t[15], t[15:3]};
assign mul_i1 = k_tc ? {2'd0, b} : {a, 1'd0};
assign mul_q = $signed(mul_i0) * $unsigned(mul_i1);
// en
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_3_en <= 0;
    end
    else begin
        pip_3_en <= pip_2_en;
    end
end
// phi
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        phi <= 0;
    end
    else begin
        if (pip_2_en) begin
            phi <= mul_q[21:10];
        end
    end
end

// output
assign phi_en = pip_3_en;
assign phi_val = phi;

endmodule
