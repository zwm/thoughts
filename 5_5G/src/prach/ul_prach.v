// 20180416
// Wbird
module ul_prach (
    // sys
    input               clk,
    input               rst_n,
    input               start,
    output              busy,
    output              done,
    // input
    input               zc_sel,
    input       [ 9:0]  u,
    input       [ 9:0]  u_inv,
    input       [ 9:0]  v,
    input               ju,
    // frequency domain compensation
    input               freq_comp_en,
    input       [ 1:0]  scs,                // 00:1.25K, 01:5K, 10:15K, 11:30K, used for frequency domain compensation
    input       [11:0]  sc_offset,
    // ifft shift
    input               ifft_shift_en,
    input       [11:0]  ifft_shift_len,
    input       [ 2:0]  ifft_size_sel,
    // RAM
    output              beta_ram_rd,
    output      [ 7:0]  beta_ram_raddr,
    input       [11:0]  beta_ram_rdata,     // R12U12
    output              ifft_ram_wr,
    output      [11:0]  ifft_ram_waddr,
    output      [23:0]  ifft_ram_wdata      // C12S9
);

// FSM
parameter IDLE          = 4'd0;
parameter INI_X_MUL     = 4'd1;
parameter INI_X_MOD     = 4'd2;
parameter INI_Y_MUL     = 4'd3;
parameter INI_Y_MOD     = 4'd4;
parameter INI_GAMMA     = 4'd5;
parameter INI_BETA0_MUL = 4'd6;
parameter INI_BETA0_MOD = 4'd7;
parameter INI_BETA0_SUB = 4'd8;
parameter INI_ALPHA0    = 4'd9;
parameter PIPELINE      = 4'd10;
parameter FINISH        = 4'd11;
// Reg
reg     [ 3:0]          cur_st;
reg     [ 3:0]          next_st;
wire    [ 9:0]          n_zc;
wire    [ 7:0]          n_zc_inv;       // R8U15
wire    [ 9:0]          n_zc_m1;
reg     [19:0]          x_mul;
reg     [20:0]          y_mul;
reg     [18:0]          beta0_mul;
reg     [10:0]          a_0;
reg     [10:0]          x;
reg     [10:0]          y;
reg     [10:0]          b_0;
reg     [ 8:0]          gamma;
wire    [ 9:0]          gamma_p1;
reg     [ 9:0]          mul_i0;
reg     [10:0]          mul_i1;
wire    [20:0]          mul_q;
reg                     mod_start;
wire                    mod_busy;
wire                    mod_done;
reg     [21:0]          mod_i;
wire    [10:0]          mod_d;
wire    [10:0]          mod_q;
wire                    pip_en;
reg     [31:0]          pip_en_dly;
wire    [31:0]          pip_stg_en;
reg     [10:0]          xmul2_mod;
wire    [12:0]          xmul2_sub;
reg                     beta_en;
reg     [11:0]          beta_addr;
reg     [11:0]          beta_i;
reg     [11:0]          beta_q;
wire                    ifft_data_wr;
wire    [11:0]          ifft_data_waddr;
wire    [23:0]          ifft_data_wdata;
reg                     ifft_eras_wr;
reg     [11:0]          ifft_eras_waddr;
wire    [23:0]          ifft_eras_wdata;
reg                     pip_finish;
reg                     ifft_eras_finish;
wire                    pip_done;

//---------------------------------------------------------------------------
// Args
//---------------------------------------------------------------------------
// ZC Length
assign n_zc = zc_sel ? 10'd139 : 10'd839;
assign n_zc_inv = zc_sel ? 8'd236 : 8'd39;
assign n_zc_m1 = n_zc - 1;
assign gamma_p1 = {1'b0, gamma} + 10'd1;
// RE MAP: IFFT Shift
reg [11:0] ifft_size_m1;
always @(*) begin
    case (ifft_size_sel)
        3'd0: ifft_size_m1 = 12'd4095;
        3'd1: ifft_size_m1 = 12'd2047;
        3'd2: ifft_size_m1 = 12'd1023;
        3'd3: ifft_size_m1 = 12'd511;
        3'd4: ifft_size_m1 = 12'd255;
        default : ifft_size_m1 = 12'd4095;
    endcase
end
wire [11:0] data_len;
wire [11:0] data_ifft_start;
assign data_len = {2'd0, n_zc};
assign data_ifft_start = ifft_shift_en ? (ifft_size_m1 - ifft_shift_len + 1) : 12'd0;
wire shift_over;
assign shift_over = (ifft_shift_len > data_len) ? 1'd1 : 1'd0;
wire [11:0] ifft_eras_start;
wire [11:0] ifft_eras_end;
assign ifft_eras_start = ifft_shift_en ? (shift_over ? (data_ifft_start+data_len) : (data_len-ifft_shift_len)) : data_len;
assign ifft_eras_end   = ifft_shift_en ? (data_ifft_start-1) : ifft_size_m1;

// pip_finish
reg beta_en_d1;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        beta_en_d1 <= 0;
    end
    else begin
        beta_en_d1 <= beta_en;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_finish <= 0;
    end
    else begin
        if (start) begin
            pip_finish <= 0;
        end
        else if ((beta_en == 0) && (beta_en_d1 == 1)) begin
            pip_finish <= 1;
        end
    end
end
assign pip_done = pip_finish & ifft_eras_finish;
assign busy = (cur_st == IDLE) ? 1'd0 : 1'd1;
assign done = (cur_st == FINISH) ? 1'd1 : 1'd0;

//---------------------------------------------------------------------------
// FSM
//---------------------------------------------------------------------------
// state machine: syn
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cur_st <= IDLE;
    end
    else begin
        cur_st <= next_st;
    end
end
// state machine: comb
always @(*) begin
    case (cur_st)
        IDLE:
            if (start)
                next_st = INI_X_MUL;
            else
                next_st = cur_st;
        INI_X_MUL:
            next_st = INI_X_MOD;
        INI_X_MOD:
            if (mod_done)
                next_st = INI_Y_MUL;
            else
                next_st = cur_st;
        INI_Y_MUL:
            next_st = INI_Y_MOD;
        INI_Y_MOD:
            if (mod_done)
                next_st = INI_GAMMA;
            else
                next_st = cur_st;
        INI_GAMMA:
            next_st = INI_BETA0_MUL;
        INI_BETA0_MUL:
            next_st = INI_BETA0_MOD;
        INI_BETA0_MOD:
            if (mod_done)
                next_st = INI_BETA0_SUB;
            else
                next_st = cur_st;
        INI_BETA0_SUB:
            next_st = INI_ALPHA0;
        INI_ALPHA0:
            next_st = PIPELINE;
        PIPELINE:
            if (pip_done)
                next_st = FINISH;
            else
                next_st = cur_st;
        FINISH:
            next_st = IDLE;
        default:
            next_st = IDLE;
    endcase
end
//---------------------------------------------------------------------------
// Initialization
//---------------------------------------------------------------------------
//------------------------------
// Shared Multiplier 
//------------------------------
// input
always @(*) begin
    case (cur_st)
        INI_X_MUL: begin        // u_inv*u_inv
            mul_i0 = u_inv;
            mul_i1 = {1'b0, u_inv};
        end
        INI_Y_MUL: begin        // u_inv*(2v+1)
            mul_i0 = u_inv;
            mul_i1 = {v, 1'b1};
        end
        INI_BETA0_MUL: begin    // gamma*(gamma+1)
            mul_i0 = {1'b0, gamma};
            mul_i1 = {1'b0, gamma_p1};
        end
        default: begin
            mul_i0 = 10'd0;
            mul_i1 = 11'd0;
        end
    endcase
end
// inst: 10bit * 11bit = 21bit
assign mul_q = mul_i0 * mul_i1;
// output reg
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        x_mul <= 0;
        y_mul <= 0;
        beta0_mul <= 0;
    end
    else begin
        if (cur_st == INI_X_MUL) begin
            x_mul <= mul_q[19:0];
        end
        if (cur_st == INI_Y_MUL) begin
            y_mul <= mul_q[20:0];
        end
        if (cur_st == INI_BETA0_MUL) begin
            beta0_mul <= mul_q[18:0];
        end
    end
end
//------------------------------
// Shared Mod
//------------------------------
// start
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        mod_start <= 0;
    end
    else begin
        if ((cur_st == INI_X_MUL && next_st == INI_X_MOD) ||
            (cur_st == INI_Y_MUL && next_st == INI_Y_MOD) ||
            (cur_st == INI_BETA0_MUL && next_st == INI_BETA0_MOD)) begin
            mod_start <= 1;
        end
        else begin
            mod_start <= 0;
        end
    end
end
// dividend
always @(*) begin
    case (cur_st)
        INI_X_MOD : mod_i = {2'd0, x_mul};
        INI_Y_MOD : mod_i = {1'd0, y_mul};
        INI_BETA0_MOD : mod_i = {3'd0, beta0_mul};
        default : mod_i = 0;
    endcase
end
// divisor, 2*Nzc
assign mod_d = {n_zc, 1'd0};
ul_div_sync #(
    .DIVIDEND_WIDTH ( 22                        ),
    .DIVISOR_WIDTH  ( 11                        ))
u_div_sync (
    .clk            ( clk                       ),
    .rst_n          ( rst_n                     ),
    .start          ( mod_start                 ),
    .busy           ( mod_busy                  ),
    .done           ( mod_done                  ),
    .dividend       ( mod_i                     ),
    .divisor        ( mod_d                     ),
    .quotient       (                           ),
    .remainder      ( mod_q                     )
);
// output reg
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        x <= 0;
        y <= 0;
        b_0 <= 0;
    end
    else begin
        if (cur_st == INI_X_MOD && mod_done == 1) begin
            x <= mod_q;
        end
        if (cur_st == INI_Y_MOD && mod_done == 1) begin
            y <= mod_q;
        end
        if (cur_st == INI_BETA0_MOD && mod_done == 1) begin
            b_0 <= mod_q;
        end
        else if (cur_st == INI_BETA0_SUB) begin
            b_0 <= {n_zc, 1'd0} - b_0;
        end
    end
end
// other regs
assign xmul2_sub = {1'b0, x, 1'b0} - {1'b0, 1'b0, mod_d};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        gamma <= 0;
        a_0 <= 0;
        xmul2_mod <= 0;
    end
    else begin
        if (cur_st == INI_GAMMA) begin
            gamma <= n_zc_m1[9:1];
        end
        if (cur_st == INI_ALPHA0) begin
            a_0 <= {n_zc, 1'd0} - x;
        end
        if (cur_st == INI_ALPHA0) begin
            if (xmul2_sub[12]) begin
                xmul2_mod <= {x[9:0], 1'b0};
            end
            else begin
                xmul2_mod <= xmul2_sub[10:0];
            end
        end
    end
end
//---------------------------------------------------------------------------
// Main Pipeline
//---------------------------------------------------------------------------
// stage 0 : a_k = (ak + x*2) mod Nzc
// en
reg pip_0_en;
reg [9:0] pip_0_cnt;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_0_en <= 0;
        pip_0_cnt <= 0;
    end
    else begin
        // cnt
        if (cur_st == INI_ALPHA0 && next_st == PIPELINE) begin
            pip_0_cnt <= 0;
        end
        else if (cur_st == PIPELINE) begin
            if (pip_0_cnt != n_zc) begin
                pip_0_cnt <= pip_0_cnt + 1;
            end
        end
        // en
        if (cur_st == PIPELINE) begin
            if (pip_0_cnt == 0) begin
                pip_0_en <= 1;
            end
            else if (pip_0_cnt == n_zc) begin
                pip_0_en <= 0;
            end
        end
        else begin
            pip_0_en <= 0;
        end
    end
end
// a_k = (ak + x*2) mod 2Nzc
reg [10:0] a_k;
wire [11:0] a_k_add;
wire [11:0] a_k_sub;
assign a_k_add = {1'd0, a_k} + {1'd0, xmul2_mod};
assign a_k_sub = a_k_add - {1'd0, mod_d};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        a_k <= 0;
    end
    else begin
        if (cur_st == PIPELINE) begin
            if (pip_0_cnt == 0) begin
                a_k <= a_0;
            end
            else begin
                if ($unsigned(a_k_add) < $unsigned(mod_d)) begin
                    a_k <= a_k_add[10:0];
                end
                else begin
                    a_k <= a_k_sub[10:0];
                end
            end
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 1 : (a_k + y) mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_1_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_1_en <= 0;
    end
    else begin
        if (pip_0_en) begin
            pip_1_en <= 1;
        end
        else begin
            pip_1_en <= 0;
        end
    end
end
// stage 1 : (a_k + y) mod Nzc
reg     [10:0]          aky_mod;
wire    [11:0]          aky_add;
wire    [12:0]          aky_sub;
assign aky_add = {1'd0, a_k} + {1'd0, y};
assign aky_sub = {1'd0, aky_add} - {1'd0, 1'd0, mod_d};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        aky_mod <= 0;
    end
    else begin
        if (pip_0_en) begin
            if (aky_sub[12]) begin
                aky_mod <= aky_add[10:0];
            end
            else begin
                aky_mod <= aky_sub[10:0];
            end
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 2 : (b_k + aky) mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_2_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_2_en <= 0;
    end
    else begin
        if (pip_1_en) begin
            pip_2_en <= 1;
        end
        else begin
            pip_2_en <= 0;
        end
    end
end
// (b_k + aky) mod Nzc
reg     [10:0]          b_k;
wire    [11:0]          b_k_add;
wire    [12:0]          b_k_sub;
assign b_k_add = {1'd0, b_k} + {1'd0, aky_mod};
assign b_k_sub = {1'd0, b_k_add} - {1'd0, 1'd0, mod_d};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        b_k <= 0;
    end
    else begin
        if (pip_1_en) begin
            if (pip_2_en) begin
                if (b_k_sub[12]) begin
                    b_k <= b_k_add[10:0];
                end
                else begin
                    b_k <= b_k_sub[10:0];
                end
            end
            else begin
                b_k <= b_0;
            end
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 3 : t_k = u*b_k
//---------------------------------------------------------------------------
// en
reg pip_3_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_3_en <= 0;
    end
    else begin
        if (pip_2_en) begin
            pip_3_en <= 1;
        end
        else begin
            pip_3_en <= 0;
        end
    end
end
// t_k = u*b_k
reg     [20:0]          t_k;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k <= 0;
    end
    else begin
        if (pip_2_en) begin
            t_k <= u*b_k;
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 4 : t_k_mod0 = t_k[20:19] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_4_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_4_en <= 0;
    end
    else begin
        if (pip_3_en) begin
            pip_4_en <= 1;
        end
        else begin
            pip_4_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod0_init = 11'd0;
wire [1:0] mod0_i = t_k[20:19];
wire [10:0] mod0_r = mod_d;
wire [10:0] mod0_q;
reg [18:0] t_k_d0;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod0 (
    .init           ( mod0_init     ),
    .dividend       ( mod0_i        ),
    .divider        ( mod0_r        ),
    .remainder      ( mod0_q        )
);
// reg
reg [10:0] t_k_mod0;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod0 <= 0;
        t_k_d0 <= 0;
    end
    else begin
        if (pip_3_en) begin
            t_k_mod0 <= mod0_q;
            t_k_d0 <= t_k[18:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 5 : t_k_mod0 = t_k[18:17] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_5_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_5_en <= 0;
    end
    else begin
        if (pip_4_en) begin
            pip_5_en <= 1;
        end
        else begin
            pip_5_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod1_init = t_k_mod0;
wire [1:0] mod1_i = t_k_d0[18:17];
wire [10:0] mod1_r = mod_d;
wire [10:0] mod1_q;
reg [16:0] t_k_d1;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod1 (
    .init           ( mod1_init     ),
    .dividend       ( mod1_i        ),
    .divider        ( mod1_r        ),
    .remainder      ( mod1_q        )
);
// reg
reg [10:0] t_k_mod1;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod1 <= 0;
        t_k_d1 <= 0;
    end
    else begin
        if (pip_4_en) begin
            t_k_mod1 <= mod1_q;
            t_k_d1 <= t_k_d0[16:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 6 : t_k_mod0 = t_k[16:15] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_6_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_6_en <= 0;
    end
    else begin
        if (pip_5_en) begin
            pip_6_en <= 1;
        end
        else begin
            pip_6_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod2_init = t_k_mod1;
wire [1:0] mod2_i = t_k_d1[16:15];
wire [10:0] mod2_r = mod_d;
wire [10:0] mod2_q;
reg [14:0] t_k_d2;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod2 (
    .init           ( mod2_init     ),
    .dividend       ( mod2_i        ),
    .divider        ( mod2_r        ),
    .remainder      ( mod2_q        )
);
// reg
reg [10:0] t_k_mod2;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod2 <= 0;
        t_k_d2 <= 0;
    end
    else begin
        if (pip_5_en) begin
            t_k_mod2 <= mod2_q;
            t_k_d2 <= t_k_d1[14:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 7 : t_k_mod0 = t_k[14:13] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_7_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_7_en <= 0;
    end
    else begin
        if (pip_6_en) begin
            pip_7_en <= 1;
        end
        else begin
            pip_7_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod3_init = t_k_mod2;
wire [1:0] mod3_i = t_k_d2[14:13];
wire [10:0] mod3_r = mod_d;
wire [10:0] mod3_q;
reg [12:0] t_k_d3;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod3 (
    .init           ( mod3_init     ),
    .dividend       ( mod3_i        ),
    .divider        ( mod3_r        ),
    .remainder      ( mod3_q        )
);
// reg
reg [10:0] t_k_mod3;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod3 <= 0;
        t_k_d3 <= 0;
    end
    else begin
        if (pip_6_en) begin
            t_k_mod3 <= mod3_q;
            t_k_d3 <= t_k_d2[12:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 8 : t_k_mod0 = t_k[12:11] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_8_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_8_en <= 0;
    end
    else begin
        if (pip_7_en) begin
            pip_8_en <= 1;
        end
        else begin
            pip_8_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod4_init = t_k_mod3;
wire [1:0] mod4_i = t_k_d3[12:11];
wire [10:0] mod4_r = mod_d;
wire [10:0] mod4_q;
reg [10:0] t_k_d4;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod4 (
    .init           ( mod4_init     ),
    .dividend       ( mod4_i        ),
    .divider        ( mod4_r        ),
    .remainder      ( mod4_q        )
);
// reg
reg [10:0] t_k_mod4;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod4 <= 0;
        t_k_d4 <= 0;
    end
    else begin
        if (pip_7_en) begin
            t_k_mod4 <= mod4_q;
            t_k_d4 <= t_k_d3[10:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 9 : t_k_mod0 = t_k[10:9] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_9_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_9_en <= 0;
    end
    else begin
        if (pip_8_en) begin
            pip_9_en <= 1;
        end
        else begin
            pip_9_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod5_init = t_k_mod4;
wire [1:0] mod5_i = t_k_d4[10:9];
wire [10:0] mod5_r = mod_d;
wire [10:0] mod5_q;
reg [8:0] t_k_d5;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod5 (
    .init           ( mod5_init     ),
    .dividend       ( mod5_i        ),
    .divider        ( mod5_r        ),
    .remainder      ( mod5_q        )
);
// reg
reg [10:0] t_k_mod5;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod5 <= 0;
        t_k_d5 <= 0;
    end
    else begin
        if (pip_8_en) begin
            t_k_mod5 <= mod5_q;
            t_k_d5 <= t_k_d4[8:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 10 : t_k_mod0 = t_k[8:7] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_10_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_10_en <= 0;
    end
    else begin
        if (pip_9_en) begin
            pip_10_en <= 1;
        end
        else begin
            pip_10_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod6_init = t_k_mod5;
wire [1:0] mod6_i = t_k_d5[8:7];
wire [10:0] mod6_r = mod_d;
wire [10:0] mod6_q;
reg [6:0] t_k_d6;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod6 (
    .init           ( mod6_init     ),
    .dividend       ( mod6_i        ),
    .divider        ( mod6_r        ),
    .remainder      ( mod6_q        )
);
// reg
reg [10:0] t_k_mod6;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod6 <= 0;
        t_k_d6 <= 0;
    end
    else begin
        if (pip_9_en) begin
            t_k_mod6 <= mod6_q;
            t_k_d6 <= t_k_d5[6:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 11 : t_k_mod0 = t_k[6:5] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_11_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_11_en <= 0;
    end
    else begin
        if (pip_10_en) begin
            pip_11_en <= 1;
        end
        else begin
            pip_11_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod7_init = t_k_mod6;
wire [1:0] mod7_i = t_k_d6[6:5];
wire [10:0] mod7_r = mod_d;
wire [10:0] mod7_q;
reg [4:0] t_k_d7;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod7 (
    .init           ( mod7_init     ),
    .dividend       ( mod7_i        ),
    .divider        ( mod7_r        ),
    .remainder      ( mod7_q        )
);
// reg
reg [10:0] t_k_mod7;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod7 <= 0;
        t_k_d7 <= 0;
    end
    else begin
        if (pip_10_en) begin
            t_k_mod7 <= mod7_q;
            t_k_d7 <= t_k_d6[4:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 12 : t_k_mod0 = t_k[4:3] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_12_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_12_en <= 0;
    end
    else begin
        if (pip_11_en) begin
            pip_12_en <= 1;
        end
        else begin
            pip_12_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod8_init = t_k_mod7;
wire [1:0] mod8_i = t_k_d7[4:3];
wire [10:0] mod8_r = mod_d;
wire [10:0] mod8_q;
reg [2:0] t_k_d8;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod8 (
    .init           ( mod8_init     ),
    .dividend       ( mod8_i        ),
    .divider        ( mod8_r        ),
    .remainder      ( mod8_q        )
);
// reg
reg [10:0] t_k_mod8;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod8 <= 0;
        t_k_d8 <= 0;
    end
    else begin
        if (pip_11_en) begin
            t_k_mod8 <= mod8_q;
            t_k_d8 <= t_k_d7[2:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 13 : t_k_mod0 = t_k[2:1] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_13_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_13_en <= 0;
    end
    else begin
        if (pip_12_en) begin
            pip_13_en <= 1;
        end
        else begin
            pip_13_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod9_init = t_k_mod8;
wire [1:0] mod9_i = t_k_d8[2:1];
wire [10:0] mod9_r = mod_d;
wire [10:0] mod9_q;
reg [0:0] t_k_d9;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod9 (
    .init           ( mod9_init     ),
    .dividend       ( mod9_i        ),
    .divider        ( mod9_r        ),
    .remainder      ( mod9_q        )
);
// reg
reg [10:0] t_k_mod9;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod9 <= 0;
        t_k_d9 <= 0;
    end
    else begin
        if (pip_12_en) begin
            t_k_mod9 <= mod9_q;
            t_k_d9 <= t_k_d8[0:0];
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 14 : t_k_mod0 = t_k[0:0] mod 2Nzc
//---------------------------------------------------------------------------
// en
reg pip_14_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_14_en <= 0;
    end
    else begin
        if (pip_13_en) begin
            pip_14_en <= 1;
        end
        else begin
            pip_14_en <= 0;
        end
    end
end
// mod inst
wire [10:0] mod10_init = {1'd0, t_k_mod9[10:1]};
wire [1:0] mod10_i = {t_k_mod9[0], t_k_d9[0:0]};
wire [10:0] mod10_r = mod_d;
wire [10:0] mod10_q;
ul_mod_2stage #(
    .DIVISOR_WIDTH  ( 11            ))
u_mod10 (
    .init           ( mod10_init    ),
    .dividend       ( mod10_i       ),
    .divider        ( mod10_r       ),
    .remainder      ( mod10_q       )
);
// reg
reg [10:0] t_k_mod10;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t_k_mod10 <= 0;
    end
    else begin
        if (pip_13_en) begin
            t_k_mod10 <= mod10_q;
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 15 : t = t_k if t_k<Nzc else (t_k-2Nzc)
//---------------------------------------------------------------------------
// en
reg pip_15_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_15_en <= 0;
    end
    else begin
        if (pip_14_en) begin
            pip_15_en <= 1;
        end
        else begin
            pip_15_en <= 0;
        end
    end
end
// t = t_k if t_k<Nzc else (t_k-2Nzc)
reg     [10:0]          t;
wire    [11:0]          tk_sub_nzc;
wire    [11:0]          tk_sub_2nzc;
assign tk_sub_nzc  = {1'd0, t_k_mod10} - {1'd0, 1'd0, n_zc};
assign tk_sub_2nzc = {1'd0, t_k_mod10} - {1'd0, n_zc, 1'd0};
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        t <= 0;
    end
    else begin
        if (pip_14_en) begin
            if (tk_sub_nzc[11]) begin
                t <= t_k_mod10;
            end
            else begin
                t <= tk_sub_2nzc[10:0];
            end
        end
    end
end
//---------------------------------------------------------------------------
// pipeline 16 : phi = t*(1/Nzc)   R11S0*R8U15=R12S10
//---------------------------------------------------------------------------
// en
reg pip_16_en;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pip_16_en <= 0;
    end
    else begin
        if (pip_15_en) begin
            pip_16_en <= 1;
        end
        else begin
            pip_16_en <= 0;
        end
    end
end
// phi = t*(1/Nzc)   R11S0*R8U15=R12S10
reg     [11:0]          phi;
wire    [19:0]          t_mul_nzcinv;
assign t_mul_nzcinv = $signed(t) * $signed({1'd0, n_zc_inv});   // $signed()*$unsigned() will not work!!!
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        phi <= 0;
    end
    else begin
        if (pip_15_en) begin    // Truncate Method: signed floor, ??? to be modify!!!
            if ((t_mul_nzcinv[19] == 1'b1)) begin
                if (t_mul_nzcinv[18:17] == 2'b11) begin
                    phi <= t_mul_nzcinv[16:5];
//                    if (t_mul_nzcinv[4:0] == 5'd0) begin
//                        phi <= t_mul_nzcinv[16:5];
//                    end
//                    else begin
//                        phi <= t_mul_nzcinv[16:5] + 1;
//                    end
                end
                else begin
                    phi <= 12'h800;
                end
            end
            else begin
                if (t_mul_nzcinv[18:17] == 2'b00) begin
                    phi <= t_mul_nzcinv[16:5];
                end
                else begin
                    phi <= 12'h7ff;
                end
            end
        end
    end
end
// pipelined cordic
wire                        cordic_ang_en;
wire            [14:0]      cordic_ang_val; // R15S13
wire                        cordic_amp_en;
wire            [11:0]      cordic_amp_i;   // C12S9
wire            [11:0]      cordic_amp_q;
wire            [13:0]      cordic_inner_en;
assign cordic_ang_en = pip_16_en;
assign cordic_ang_val = {phi, 3'd0};   // R12S10 -> R15S13
ul_cordic_pipeline u_cordic (
    .clk                    ( clk                   ),
    .rst_n                  ( rst_n                 ),
    .cordic_en              ( 1'd1                  ),
    .ang_en                 ( cordic_ang_en         ),
    .ang_val                ( cordic_ang_val        ),
    .amp_en                 ( cordic_amp_en         ),
    .amp_i                  ( cordic_amp_i          ),
    .amp_q                  ( cordic_amp_q          ),
    .inner_en               ( cordic_inner_en       )
);
// (i, q) = (i, q)*Ju
reg                         ju_en;
reg             [11:0]      ju_i;
reg             [11:0]      ju_q;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ju_en <= 0;
        ju_i  <= 0;
        ju_q  <= 0;
    end
    else begin
        if (cordic_amp_en) begin
            ju_en <= 1;
            if (ju) begin   // ju=1, i=q, q=-i
                ju_i <= +cordic_amp_q;
                ju_q <= -cordic_amp_i;
            end
            else begin      // ju=0, i=-q, q=i
                ju_i <= -cordic_amp_q;
                ju_q <= +cordic_amp_i;
            end
        end
        else begin
            ju_en <= 0;
        end
    end
end
//---------------------------------------------------------------------------
// Frequency Domain Compensation
//---------------------------------------------------------------------------
wire sc_en = freq_comp_en & cordic_inner_en[12];
wire        coef_en;
wire [11:0] coef_val;       // R12U12
wire [ 1:0] sc_gap = 2'd0;  // PRACH only
// (i, q) = (i, q)*Beta_n
ul_comp_coef u_comp_coef(
    .clk                ( clk                   ),
    .rst_n              ( rst_n                 ),
    .work_en            ( 1'd1                  ),
    .init               ( start                 ),
    .sc_en              ( sc_en                 ),
    .sc_offset          ( sc_offset             ),
    .sc_gap             ( sc_gap                ),
    .scs                ( scs                   ),
    .coef_ram_rd        ( beta_ram_rd           ),
    .coef_ram_raddr     ( beta_ram_raddr        ),
    .coef_ram_rdata     ( beta_ram_rdata        ),
    .coef_en            ( coef_en               ),
    .coef_val           ( coef_val              )
);
// (i, q) = (i, q)*Ju
wire [24:0] ju_mul_beta_i = $signed(ju_i) * $signed({1'd0, coef_val});  // R12S9*R13U12=R25S21
wire [24:0] ju_mul_beta_q = $signed(ju_q) * $signed({1'd0, coef_val});
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        beta_en <= 0;
        beta_addr <= 0;
        beta_i  <= 0;
        beta_q  <= 0;
    end
    else begin
        // en
        if (ju_en) begin
            beta_en <= 1;
        end
        else begin
            beta_en <= 0;
        end
        // addr
        if (ju_en) begin
            if (~beta_en) begin
                beta_addr <= data_ifft_start;
            end
            else begin
                if (beta_addr == ifft_size_m1) begin
                    beta_addr <= 0;
                end
                else begin
                    beta_addr <= beta_addr + 1;
                end
            end
        end
        // data
        if (ju_en) begin    // Truncate Method: signed round!!!
            if (freq_comp_en) begin
                // i
                if (ju_mul_beta_i[24] == 0) begin
                    if (ju_mul_beta_i[23:12] >= 12'h7ff) begin
                        beta_i <= 12'h7ff;
                    end
                    else if (ju_mul_beta_i[11]) begin
                        beta_i <= ju_mul_beta_i[23:12] + 1;
                    end
                    else begin
                        beta_i <= ju_mul_beta_i[23:12];
                    end
                end
                else begin
                    if (ju_mul_beta_i[23:12] <= 12'h800) begin
                        beta_i <= 12'h800;
                    end
                    else if ((ju_mul_beta_i[11] == 0) || (ju_mul_beta_i[11:0] == 12'h800)) begin
                        beta_i <= ju_mul_beta_i[23:12];
                    end
                    else begin
                        beta_i <= ju_mul_beta_i[23:12] + 1;
                    end
                end
                // q
                if (ju_mul_beta_q[24] == 0) begin
                    if (ju_mul_beta_q[23:12] >= 12'h7ff) begin
                        beta_q <= 12'h7ff;
                    end
                    else if (ju_mul_beta_q[11]) begin
                        beta_q <= ju_mul_beta_q[23:12] + 1;
                    end
                    else begin
                        beta_q <= ju_mul_beta_q[23:12];
                    end
                end
                else begin
                    if (ju_mul_beta_q[23:12] <= 12'h800) begin
                        beta_q <= 12'h800;
                    end
                    else if ((ju_mul_beta_q[11] == 0) || (ju_mul_beta_q[11:0] == 12'h800)) begin
                        beta_q <= ju_mul_beta_q[23:12];
                    end
                    else begin
                        beta_q <= ju_mul_beta_q[23:12] + 1;
                    end
                end
            end
            else begin
                beta_i <= ju_i;
                beta_q <= ju_q;
            end
        end
    end
end
assign ifft_data_wr    = beta_en;
assign ifft_data_waddr = beta_addr;
assign ifft_data_wdata = {beta_i, beta_q};
// ifft erase
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ifft_eras_finish <= 0;
    end
    else begin
        if (start) begin
            ifft_eras_finish <= 0;
        end
        else if ((ifft_eras_wr == 1) && (ifft_data_wr == 0) && (ifft_eras_waddr == ifft_eras_end)) begin
            ifft_eras_finish <= 1;
        end
    end
end
// eras
assign ifft_eras_wdata = 0;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ifft_eras_wr <= 0;
        ifft_eras_waddr <= 0;
    end
    else begin
        // wr
        if (start) begin
            ifft_eras_wr <= 1;
        end
        else if ((ifft_eras_wr == 1) && (ifft_data_wr == 0) && (ifft_eras_waddr == ifft_eras_end)) begin
            ifft_eras_wr <= 0;
        end
        // addr
        if (start) begin
            ifft_eras_waddr <= ifft_eras_start;
        end
        else if ((ifft_eras_wr == 1) && (ifft_data_wr == 0)) begin
            if (ifft_eras_waddr == ifft_size_m1) begin
                ifft_eras_waddr <= 0;
            end
            else begin
                ifft_eras_waddr <= ifft_eras_waddr + 1;
            end
        end
    end
end
// output
assign ifft_ram_wr    = ifft_data_wr | ifft_eras_wr;
assign ifft_ram_waddr = ifft_data_wr ? ifft_data_waddr : ifft_eras_waddr;
assign ifft_ram_wdata = ifft_data_wr ? ifft_data_wdata : ifft_eras_wdata;

endmodule

