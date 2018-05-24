module hop (
    // sys
    input               clk,
    input               rst_n,
    input               start,
    output              busy,
    output reg          done,
    // input
    input       [ 4:0]  n_slot,
    input       [ 1:0]  symb_num,       // 00: 1        01: 2               10: -       11: 4
    input       [ 3:0]  start_symb,     // 0~13
    input       [ 1:0]  symb_index,     // 00: 0        01: 1               10: 2       11: 3
    input       [ 1:0]  hop_mode,       // 00: non      01: group hop       10: sequence hop
    input       [30:0]  c_init,
    // output
    output      [ 4:0]  u,
    output              v
);


// FSM
parameter IDLE          = 4'd0;
parameter C_SRCH        = 4'd1;
parameter UV_CALC       = 4'd2;
parameter U_MOD         = 4'd3;

parameter MATRIX1600_0  = 31'd1;    // ??? initial value ??? !!!
parameter MATRIX1600_1  = 31'd1;
parameter MATRIX1600_2  = 31'd1;
parameter MATRIX1600_3  = 31'd1;
parameter MATRIX1600_4  = 31'd1;
parameter MATRIX1600_5  = 31'd1;
parameter MATRIX1600_6  = 31'd1;
parameter MATRIX1600_7  = 31'd1;
parameter MATRIX1600_8  = 31'd1;
parameter MATRIX1600_9  = 31'd1;
parameter MATRIX1600_10 = 31'd1;
parameter MATRIX1600_11 = 31'd1;
parameter MATRIX1600_12 = 31'd1;
parameter MATRIX1600_13 = 31'd1;
parameter MATRIX1600_14 = 31'd1;
parameter MATRIX1600_15 = 31'd1;
parameter MATRIX1600_16 = 31'd1;
parameter MATRIX1600_17 = 31'd1;
parameter MATRIX1600_18 = 31'd1;
parameter MATRIX1600_19 = 31'd1;
parameter MATRIX1600_20 = 31'd1;
parameter MATRIX1600_21 = 31'd1;
parameter MATRIX1600_22 = 31'd1;
parameter MATRIX1600_23 = 31'd1;
parameter MATRIX1600_24 = 31'd1;
parameter MATRIX1600_25 = 31'd1;
parameter MATRIX1600_26 = 31'd1;
parameter MATRIX1600_27 = 31'd1;
parameter MATRIX1600_28 = 31'd1;
parameter MATRIX1600_29 = 31'd1;
parameter MATRIX1600_30 = 31'd1;
// Reg
reg     [ 3:0]          cur_st;
reg     [ 3:0]          next_st;

reg     [30:0]          x1;
reg     [30:0]          x2;
wire    [30:0]          x1_ini;
wire    [30:0]          x2_ini;
wire    [30:0]          c;
wire    [23:0]          x1_next24;
wire    [23:0]          x2_next24;
reg     [10:0]          c_index;

assign c = x1 ^ x2;
assign x1_ini = 31'd123;        // tbd ??? !!!
assign x2_ini[0] = ^(c_init ^ MATRIX1600_0);
assign x2_ini[1] = ^(c_init ^ MATRIX1600_1);
assign x2_ini[2] = ^(c_init ^ MATRIX1600_2);
assign x2_ini[3] = ^(c_init ^ MATRIX1600_3);
assign x2_ini[4] = ^(c_init ^ MATRIX1600_4);
assign x2_ini[5] = ^(c_init ^ MATRIX1600_5);
assign x2_ini[6] = ^(c_init ^ MATRIX1600_6);
assign x2_ini[7] = ^(c_init ^ MATRIX1600_7);
assign x2_ini[8] = ^(c_init ^ MATRIX1600_8);
assign x2_ini[9] = ^(c_init ^ MATRIX1600_9);
assign x2_ini[10] = ^(c_init ^ MATRIX1600_10);
assign x2_ini[11] = ^(c_init ^ MATRIX1600_11);
assign x2_ini[12] = ^(c_init ^ MATRIX1600_12);
assign x2_ini[13] = ^(c_init ^ MATRIX1600_13);
assign x2_ini[14] = ^(c_init ^ MATRIX1600_14);
assign x2_ini[15] = ^(c_init ^ MATRIX1600_15);
assign x2_ini[16] = ^(c_init ^ MATRIX1600_16);
assign x2_ini[17] = ^(c_init ^ MATRIX1600_17);
assign x2_ini[18] = ^(c_init ^ MATRIX1600_18);
assign x2_ini[19] = ^(c_init ^ MATRIX1600_19);
assign x2_ini[20] = ^(c_init ^ MATRIX1600_20);
assign x2_ini[21] = ^(c_init ^ MATRIX1600_21);
assign x2_ini[22] = ^(c_init ^ MATRIX1600_22);
assign x2_ini[23] = ^(c_init ^ MATRIX1600_23);
assign x2_ini[24] = ^(c_init ^ MATRIX1600_24);
assign x2_ini[25] = ^(c_init ^ MATRIX1600_25);
assign x2_ini[26] = ^(c_init ^ MATRIX1600_26);
assign x2_ini[27] = ^(c_init ^ MATRIX1600_27);
assign x2_ini[28] = ^(c_init ^ MATRIX1600_28);
assign x2_ini[29] = ^(c_init ^ MATRIX1600_29);
assign x2_ini[30] = ^(c_init ^ MATRIX1600_30);
// x1_next24
assign x1_next24[0] = x1[3] ^ x1[0];
assign x1_next24[1] = x1[4] ^ x1[1];
assign x1_next24[2] = x1[5] ^ x1[2];
assign x1_next24[3] = x1[6] ^ x1[3];
assign x1_next24[4] = x1[7] ^ x1[4];
assign x1_next24[5] = x1[8] ^ x1[5];
assign x1_next24[6] = x1[9] ^ x1[6];
assign x1_next24[7] = x1[10] ^ x1[7];
assign x1_next24[8] = x1[11] ^ x1[8];
assign x1_next24[9] = x1[12] ^ x1[9];
assign x1_next24[10] = x1[13] ^ x1[10];
assign x1_next24[11] = x1[14] ^ x1[11];
assign x1_next24[12] = x1[15] ^ x1[12];
assign x1_next24[13] = x1[16] ^ x1[13];
assign x1_next24[14] = x1[17] ^ x1[14];
assign x1_next24[15] = x1[18] ^ x1[15];
assign x1_next24[16] = x1[19] ^ x1[16];
assign x1_next24[17] = x1[20] ^ x1[17];
assign x1_next24[18] = x1[21] ^ x1[18];
assign x1_next24[19] = x1[22] ^ x1[19];
assign x1_next24[20] = x1[23] ^ x1[20];
assign x1_next24[21] = x1[24] ^ x1[21];
assign x1_next24[22] = x1[25] ^ x1[22];
assign x1_next24[23] = x1[26] ^ x1[23];
// x2_next24
assign x2_next24[0] = x2[3] ^ x2[0];
assign x2_next24[1] = x2[4] ^ x2[1];
assign x2_next24[2] = x2[5] ^ x2[2];
assign x2_next24[3] = x2[6] ^ x2[3];
assign x2_next24[4] = x2[7] ^ x2[4];
assign x2_next24[5] = x2[8] ^ x2[5];
assign x2_next24[6] = x2[9] ^ x2[6];
assign x2_next24[7] = x2[10] ^ x2[7];
assign x2_next24[8] = x2[11] ^ x2[8];
assign x2_next24[9] = x2[12] ^ x2[9];
assign x2_next24[10] = x2[13] ^ x2[10];
assign x2_next24[11] = x2[14] ^ x2[11];
assign x2_next24[12] = x2[15] ^ x2[12];
assign x2_next24[13] = x2[16] ^ x2[13];
assign x2_next24[14] = x2[17] ^ x2[14];
assign x2_next24[15] = x2[18] ^ x2[15];
assign x2_next24[16] = x2[19] ^ x2[16];
assign x2_next24[17] = x2[20] ^ x2[17];
assign x2_next24[18] = x2[21] ^ x2[18];
assign x2_next24[19] = x2[22] ^ x2[19];
assign x2_next24[20] = x2[23] ^ x2[20];
assign x2_next24[21] = x2[24] ^ x2[21];
assign x2_next24[22] = x2[25] ^ x2[22];
assign x2_next24[23] = x2[26] ^ x2[23];

// n_slot*n_sys_symb
wire            [6:0]   n_slot_symb;
assign n_slot_symb = (n_srs_symb == 2'd0) ? {2'd0, n_slot} : ((n_srs_symb == 2'd1) ? {1'd0, n_slot, 1'd0} : {n_slot, 2'd0});
wire            [7:0]   n_slot_symb_l;
assign n_slot_symb_l = {1'd0, n_slot_symb} + {4'd0, start_symb} + {6'd0, symb_index};
// c_start
wire            [10:0]  c_start;
assign c_start = (hop_mode == 2'd0) ? 11'd0 : ((hop_mode == 2'd1) ? {n_slot_symb_l, 3'd0} : {3'd0, n_slot_symb_l});

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
                next_st = C_SRCH;
            else
                next_st = cur_st;
        C_SRCH:
            if (hop_mode == 2'd0)
                next_st = UV_CALC;
            else
                if (c_index > c_start)
                    next_st = UV_CALC;
                else
                    next_st = C_SRCH;
        UV_CALC:
            next_st = U_MOD;
        U_MOD:
            next_st = IDLE;
    endcase
end
//---------------------------------------------------------------------------
// Initialization
//---------------------------------------------------------------------------
// c_index
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        c_index <= 0;
    end
    else begin
        if (cur_st == IDLE) begin
            if (next_st == C_SRCH) begin
                c_index <= 11'd0;
            end
        end
        else if (cur_st == C_SRCH) begin
            c_index <= c_index + 11'd24;
        end
    end
end
// x1, x2
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        x1 <= 0;
        x2 <= 0;
    end
    else begin
        if (cur_st == C_SRCH) begin
            if (c_index == 0) begin
                x1 <= x1_ini;
                x2 <= x2_ini;
            end
            else begin
                x1 <= {x1_next24, x1[6:0]};
                x2 <= {x2_next24, x2[6:0]};
            end
        end
    end
end
// u_org, v_org
wire [10:0] c_index_sub_c_start;
reg [7:0] u_org;
reg       v_org;
assign c_index_sub_c_start = c_index - c_start;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        u_org <= 0;
        v_org <= 0;
    end
    else begin
        if (cur_st == UV_CALC) begin
            if (hop_mode == 2'd0) begin
                u_org <= 0;
                v_org <= 0;
            end
            else if (hop_mode == 2'd1) begin
                v_org <= 0;
                if (c_index_sub_c_start[4:3] == 2'd0) begin
                    u_org <= 0;
                end
                else if (c_index_sub_c_start[4:3] == 2'd1) begin
                    u_org <= c[23:16];
                end
                else if (c_index_sub_c_start[4:3] == 2'd2) begin
                    u_org <= c[15: 8];
                end
                else if (c_index_sub_c_start[4:3] == 2'd3) begin
                    u_org <= c[ 7: 0];
                end
            end
            else if (hop_mode == 2'd2) begin
                u_org <= 0;
                case (c_index_sub_c_start[4:0])
                    5'd1 : v_org <= c[23];
                    5'd2 : v_org <= c[22];
                    5'd3 : v_org <= c[21];
                    5'd4 : v_org <= c[20];
                    5'd5 : v_org <= c[19];
                    5'd6 : v_org <= c[18];
                    5'd7 : v_org <= c[17];
                    5'd8 : v_org <= c[16];
                    5'd9 : v_org <= c[15];
                    5'd10 : v_org <= c[14];
                    5'd11 : v_org <= c[13];
                    5'd12 : v_org <= c[12];
                    5'd13 : v_org <= c[11];
                    5'd14 : v_org <= c[10];
                    5'd15 : v_org <= c[9];
                    5'd16 : v_org <= c[8];
                    5'd17 : v_org <= c[7];
                    5'd18 : v_org <= c[6];
                    5'd19 : v_org <= c[5];
                    5'd20 : v_org <= c[4];
                    5'd21 : v_org <= c[3];
                    5'd22 : v_org <= c[2];
                    5'd23 : v_org <= c[1];
                    5'd24 : v_org <= c[0];
                    default : v_org <= 1'd0;
                endcase
            end
        end
    end
end
// u_mod
reg [4:0] u_mod30;
wire [2:0] u_a;
wire [4:0] u_b;
wire [5:0] u_c;
wire [5:0] u_c_sub_60;
wire [5:0] u_c_sub_30;
assign u_a = u_org[7:5];
assign u_b = u_org[4:0];
assign u_c = {1'd0, u_b} + {2'd0, u_a, 1'd0};
assign u_c_sub_60 = u_c - 6'd60;
assign u_c_sub_30 = u_c - 6'd30;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        u_mod30 <= 0;
    end
    else begin
        if (cur_st == U_MOD) begin
            if (u_c >= 60) begin
                u_mod30 <= u_c_sub_60[4:0];
            end
            else if (u_c >= 30) begin
                u_mod30 <= u_c_sub_30[4:0];
            end
            else begin
                u_mod30 <= u_c[4:0];
            end
        end
    end
end
// done
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        done <= 0;
    end
    else begin
        if (cur_st == U_MOD) begin
            done <= 1;
        end
        else begin
            done <= 0;
        end
    end
end
assign u = u_mod30;
assign v = v_org;

assign busy = (cur_st == IDLE) ? 1'd0 : 1'd1;

endmodule
