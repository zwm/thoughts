// 201804010 2031
// Wbird
module cg_ang_pipeline (
    // sys
    input               clk,
    input               rst_n,
    input               start,
    output reg          busy,
    output              done,
    // input
    input       [ 3:0]  alpha_p,
    input       [ 4:0]  m_sc,
    input       [ 4:0]  u,
    input               ktc,

    output              phi_en,
    output      [11:0]  phi_val     // R12S10
);

//---------------------------------------------------------------------------
// Args
//---------------------------------------------------------------------------
wire [3:0] srs_cs_max;
wire [1:0] srs_cs_max_bar;
wire [4:0] n_rs_cs2;
assign srs_cs_max = ktc ? 4'd12 : 4'd8;
assign srs_cs_max_bar = ktc ? 2'd3 : 2'd2;
assign n_rs_cs2 = {srs_cs_max, 1'd0};

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
// Pipeline 0
//---------------------------------------------------------------------------
// look up table, get phi(n)
reg lut_en;
reg pip_0_en;
reg [4:0] n;   // 0~M_RS_SC-1
// lut_en
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        lut_en <= 0;
    end
    else begin
        if (start) begin
            lut_en <= 1;
        end
        else if (n == (m_sc-1)) begin
            lut_en <= 0;
        end
    end
end
// n
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        n <= 0;
    end
    else begin
        if (start) begin
            n <= 0;
        end
        else if (lut_en) begin
            n <= n + 1;
        end
    end
end
// look up table for phi(n)
wire [2:0] phi_n;
tx_zc_table u_lut_phi_n (
    .sys_clk            ( clk               ),
    .rst_n              ( rst_n             ),
    .work_en            ( lut_en            ),
    .u                  ( u                 ),
    .n                  ( n                 ),
    .m_zc               ( m_sc              ),
    .fine               ( phi_n             )
);
// pip_0_en
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_0_en <= 0;
    end
    else begin
        pip_0_en <= lut_en;
    end
end
//---------------------------------------------------------------------------
// Pipeline 1
//---------------------------------------------------------------------------
// phi(n)*N_RS_CS_MAX
// beta_n = beta_n + 2*alpha_p
// en
reg pip_1_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_1_en <= 0;
    end
    else begin
        pip_1_en <= pip_0_en;
    end
end
// phi(n)*N_RS_CS_MAX
reg [4:0] phi_n_mul;
wire [4:0] phi_n_mul_w;
assign phi_n_mul_w = ktc ? ({1'd0, phi_n, 1'd0} + {2'd0, phi_n}) : {1'd0, phi_n, 1'd0};
wire [4:0] phi_n_mul_w_sub;
assign phi_n_mul_w_sub = phi_n_mul_w - n_rs_cs2;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        phi_n_mul <= 0;
    end
    else begin
        if (pip_0_en) begin
            if ($unsigned(phi_n_mul_w) < $unsigned(n_rs_cs2)) begin
                phi_n_mul <= phi_n_mul_w;
            end
            else begin
                phi_n_mul <= phi_n_mul_w_sub;
            end
        end
    end
end
// beta_n = beta_n + 2*alpha_p
reg [4:0] b_n;
wire [5:0] bn_plus_ap2;
assign bn_plus_ap2 = {1'd0, b_n} + {1'd0, alpha_p, 1'd0};
wire [5:0] bn_plus_ap2_sub;
assign bn_plus_ap2_sub = bn_plus_ap2 - {1'd0, n_rs_cs2};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        b_n <= 0;
    end
    else begin
        if (pip_0_en) begin
            if (~pip_1_en) begin
                b_n <= 0;
            end
            else begin
                if ($unsigned(bn_plus_ap2) < $unsigned(n_rs_cs2)) begin
                    b_n <= bn_plus_ap2[4:0];
                end
                else begin
                    b_n <= bn_plus_ap2_sub[4:0];
                end
            end
        end
    end
end
//---------------------------------------------------------------------------
// Pipeline 2
//---------------------------------------------------------------------------
// b_n + phi(n)*N_RS_CS_MAX
// en
reg pip_2_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_2_en <= 0;
    end
    else begin
        pip_2_en <= pip_1_en;
    end
end
// b_n + phi(n)*N_RS_CS_MAX
reg [4:0] theta;
wire [5:0] bn_plus_phi;
assign bn_plus_phi = {1'd0, b_n} + {1'd0, phi_n_mul};
wire [5:0] bn_plus_phi_sub;
assign bn_plus_phi_sub = bn_plus_phi - {1'd0, n_rs_cs2};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        theta <= 0;
    end
    else begin
        if (pip_1_en) begin
            if ($unsigned(bn_plus_phi) < $unsigned(n_rs_cs2)) begin
                theta <= bn_plus_phi[4:0];
            end
            else begin
                theta <= bn_plus_phi_sub[4:0];
            end
        end
    end
end
//---------------------------------------------------------------------------
// Pipeline 3
//---------------------------------------------------------------------------
// T = theta if theta < N_RS_CS_MAX else theta - 2*N_RS_CS_MAX
// en
reg pip_3_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_3_en <= 0;
    end
    else begin
        pip_3_en <= pip_2_en;
    end
end
// T = theta if theta < N_RS_CS_MAX else theta - 2*N_RS_CS_MAX
reg [4:0] T;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        T <= 0;
    end
    else begin
        if (pip_2_en) begin
            if ($unsigned(theta) < $unsigned(srs_cs_max)) begin
                T <= theta;
            end
            else begin
                T <= theta - n_rs_cs2;
            end
        end
    end
end
//---------------------------------------------------------------------------
// Pipeline 4
//---------------------------------------------------------------------------
// phi = T/N_RS_CS_MAX
// en
reg pip_4_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_4_en <= 0;
    end
    else begin
        pip_4_en <= pip_3_en;
    end
end
// phi = T/N_RS_CS_MAX
reg [11:0] phi;
wire [14:0] t_mul;
assign t_mul = T * 10'd683; // how to cut???? !!!
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        phi <= 0;
    end
    else begin
        if (pip_3_en) begin
            if (ktc) begin
                phi <= t_mul[12:1];
            end
            else begin
                phi <= {T, 7'd0};   // R12S10
            end
        end
    end
end

// output
assign phi_en = pip_4_en;
assign phi_val = phi;

endmodule
