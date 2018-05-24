// Author: Wbird
// Time  : 201804051531
module ul_comp_coef (
    input             clk,
    input             rst_n,
    input             work_en,
    input             init,
    input             sc_en,
    input      [11:0] sc_offset,
    input      [ 1:0] sc_gap,       // 00: 1    01: 2   10: 3   11: 4
    input      [ 1:0] scs,          // 00:1.25K, 01:5K, 10:15K, 11:30K, used for frequency domain compensation
    output reg        coef_ram_rd,
    output reg [ 7:0] coef_ram_raddr,
    input      [11:0] coef_ram_rdata,       // R12U12, 20180502
    output reg        coef_en,
    output reg [11:0] coef_val
);


//---------------------------------------------------------------------------
// Init Step 1: 
//---------------------------------------------------------------------------
// init_d1
reg                     init_d1;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        init_d1 <= 0;
    end
    else begin
        init_d1 <= init;
    end
end
wire    [7:0]           srch_900k_seg;
wire    [7:0]           srch_900k_mod;
reg     [7:0]           srch_900k_mod_reg;
// srch_900k inst
ul_srch_900k u0_srch_900k (
    .scs                ( scs               ),
    .re_index           ( sc_offset         ),
    .seg_900k           ( srch_900k_seg     ),
    .mod_900k           ( srch_900k_mod     )
);
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        srch_900k_mod_reg <= 0;
    end
    else begin
        if (init) begin
            srch_900k_mod_reg <= srch_900k_mod;
        end
    end
end
//---------------------------------------------------------------------------
// Init Step 2: 
//---------------------------------------------------------------------------
// init_d2
reg                     init_d2;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        init_d2 <= 0;
    end
    else begin
        init_d2 <= init_d1;
    end
end
wire    [3:0]           srch_90k_seg;
wire    [4:0]           srch_90k_mod;       // used by repeat_index
reg     [3:0]           srch_90k_seg_reg;
// srch_90k inst
ul_srch_90k u_srch_90k (
    .scs                ( scs               ),
    .re_index           ( srch_900k_mod_reg ),
    .srch_90k_seg       ( srch_90k_seg      ),
    .srch_90k_mod       ( srch_90k_mod      )
);
//---------------------------------------------------------------------------
// Init Step 2: 
//---------------------------------------------------------------------------
// init_d3
reg                     init_d3;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        init_d3 <= 0;
    end
    else begin
        init_d3 <= init_d2;
    end
end
//---------------------------------------------------------------------------
// Init Step 3: 
//---------------------------------------------------------------------------
// init_d4
reg                     init_d4;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        init_d4 <= 0;
    end
    else begin
        init_d4 <= init_d3;
    end
end
//---------------------------------------------------------------------------
// Intro 900KHz Index
//---------------------------------------------------------------------------
reg     [ 7:0]          seg_len;
reg     [ 7:0]          seg_next;
reg     [ 7:0]          seg_index;
// seg_len
always @(*) begin
    case (scs)
        2'd1 : seg_len = 8'd180;
        2'd2 : seg_len = 8'd60;
        2'd3 : seg_len = 8'd30;
        default : seg_len = 8'd0;
    endcase
end
// seg_next
always @(*) begin
    case (sc_gap)
        2'd0 : seg_next = seg_index + 1;
        2'd1 : seg_next = seg_index + 2;
        2'd2 : seg_next = seg_index + 3;
        default : seg_next = seg_index + 4;
    endcase
end
// seg_index
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        seg_index <= 0;
    end
    else begin
        if (init) begin
            seg_index <= srch_900k_mod;
        end
        else if (sc_en) begin
            if (seg_next >= seg_len) begin  // never cross two segments!!!
                seg_index <= seg_next - seg_len;
            end
            else begin
                seg_index <= seg_next;
            end
        end
    end
end
//---------------------------------------------------------------------------
// Repeat Index
//---------------------------------------------------------------------------
reg     [ 4:0]          rpt_next;       // repeat next
reg     [ 4:0]          rpt_index;      // repeat index
//// rpt_len
//reg     [ 4:0]          rpt_len;        // repeat length
//always @(*) begin
//    case (scs)
//        2'd1 : rpt_len = 5'd18;
//        2'd2 : rpt_len = 5'd6;
//        2'd3 : rpt_len = 5'd3;
//        default : rpt_len = 5'd0;
//    endcase
//end
// rpt_next
always @(*) begin
    case (sc_gap)
        2'd0 : rpt_next = rpt_index + 1;
        2'd1 : rpt_next = rpt_index + 2;
        2'd2 : rpt_next = rpt_index + 3;
        default : rpt_next = rpt_index + 4;
    endcase
end
// rpt_index
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        rpt_index <= 0;
    end
    else begin
        if (init_d1) begin
            rpt_index <= srch_90k_mod;
        end
        else if (sc_en) begin
            case (scs)
                2'd1:
                    if (rpt_next >= 18) begin
                        rpt_index <= rpt_next - 18;
                    end
                    else begin
                        rpt_index <= rpt_next;
                    end
                2'd2:
                    if (rpt_next >= 6) begin
                        rpt_index <= rpt_next - 6;
                    end
                    else begin
                        rpt_index <= rpt_next;
                    end
                2'd3:
                    if (rpt_next >= 6) begin    // may through 2 segments!!!
                        rpt_index <= rpt_next - 6;
                    end
                    else if (rpt_next >= 3) begin
                        rpt_index <= rpt_next - 3;
                    end
                    else begin
                        rpt_index <= rpt_next;
                    end
                default:
                    rpt_index <= rpt_index;
            endcase
//            if (rpt_next >= rpt_len) begin
//                rpt_index <= rpt_next - rpt_len;
//            end
//            else begin
//                rpt_index <= rpt_next;
//            end
        end
    end
end
//---------------------------------------------------------------------------
// RAM Read Operation
//---------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        coef_ram_rd <= 0;
        coef_ram_raddr <= 0;
    end
    else begin
        if (work_en) begin
            if (init) begin
                coef_ram_rd <= 1;
                coef_ram_raddr <= srch_900k_seg;
            end
            else if (init_d1) begin
                coef_ram_rd <= 1;
                coef_ram_raddr <= coef_ram_raddr + 1;
            end
            else if (init_d2) begin
                coef_ram_rd <= 1;
                coef_ram_raddr <= coef_ram_raddr + 1;
            end
            else if (sc_en) begin
                if (seg_next >= seg_len) begin
                    coef_ram_rd <= 1;
//                    coef_ram_raddr <= srch_900k_seg;
                    coef_ram_raddr <= coef_ram_raddr + 1;
                end
                else begin
                    coef_ram_rd <= 0;
                end
            end
            else begin
                coef_ram_rd <= 0;
            end
        end
        else begin
            coef_ram_rd <= 0;
        end
    end
end
// coef_ram_rd_d1
reg coef_ram_rd_d1;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        coef_ram_rd_d1 <= 0;
    end
    else begin
        coef_ram_rd_d1 <= coef_ram_rd;
    end
end
// coef register update
reg     [11:0] coef_start;
reg     [11:0] coef_end;
reg     [11:0] coef_next;
reg     [12:0] coef_diff;
// start
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        coef_start <= 0;
    end
    else begin
        if (work_en) begin
            if (init_d2) begin
                coef_start <= coef_ram_rdata;
            end
            else begin
                if (sc_en) begin
                    if (seg_next >= seg_len) begin
                        coef_start <= coef_end;
                    end
                end
            end
        end
    end
end
// end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        coef_end <= 0;
    end
    else begin
        if (work_en) begin
            if (init_d3) begin
                coef_end <= coef_ram_rdata;
            end
            else begin
                if (sc_en) begin
                    if (seg_next >= seg_len) begin
                        coef_end <= coef_next;
                    end
                end
            end
        end
    end
end
// diff
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        coef_diff <= 0;
    end
    else begin
        if (work_en) begin
            if (init_d3) begin
                coef_diff <= {1'd0, coef_ram_rdata} - {1'd0, coef_start};
            end
            else begin
                if (sc_en) begin
                    if (seg_next >= seg_len) begin
                        coef_diff <= {1'd0, coef_next} - {1'd0, coef_end};
                    end
                end
            end
        end
    end
end
// next
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        coef_next <= 0;
    end
    else begin
        if (work_en) begin
            if (init_d4) begin
                coef_next <= coef_ram_rdata;
            end
            else begin
                if (coef_ram_rd_d1) begin
                    coef_next <= coef_ram_rdata;
                end
            end
        end
    end
end
//---------------------------------------------------------------------------
// n_reg
//---------------------------------------------------------------------------
reg [3:0] n_reg;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        n_reg <= 0;
    end
    else begin
        if (work_en) begin
            if (init_d1) begin
                n_reg <= srch_90k_seg;
            end
            else begin
                if (sc_en) begin
                    case (scs)
                        2'd1:
                            if (rpt_next >= 18) begin
                                if (n_reg == 9) begin
                                    n_reg <= 0;
                                end
                                else begin
                                    n_reg <= n_reg + 1;
                                end
                            end
                        2'd2:
                            if (rpt_next >= 6) begin
                                if (n_reg == 9) begin
                                    n_reg <= 0;
                                end
                                else begin
                                    n_reg <= n_reg + 1;
                                end
                            end
                        2'd3:
                            if (rpt_next >= 6) begin    // may through 2 segments!!!
                                if (n_reg == 8) begin
                                    n_reg <= 0;
                                end
                                else if (n_reg == 9) begin
                                    n_reg <= 1;
                                end
                                else begin
                                    n_reg <= n_reg + 2;
                                end
                            end
                            else if (rpt_next >= 3) begin
                                if (n_reg == 9) begin
                                    n_reg <= 0;
                                end
                                else begin
                                    n_reg <= n_reg + 1;
                                end
                            end
                        default:
                            n_reg <= n_reg;
                    endcase
                end
            end
        end
    end
end
//---------------------------------------------------------------------------
// sc_en_d1 & (10-n)*start+n*end
//---------------------------------------------------------------------------
// sc_en_d1
reg sc_en_d1;
reg [3:0] n_reg_d1;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sc_en_d1 <= 0;
        n_reg_d1 <= 0;
    end
    else begin
        sc_en_d1 <= sc_en;
        n_reg_d1 <= n_reg;
    end
end
//---------------------------------------------------------------------------
//      (a*(10-n)+b*n)/10
//    = a*(1-n/10)+b*n/10
//    = a + (b-a)*n/10
//    n=0,1,2,...9
//    1/10=8'd205 R8U11
//    We need a and (b-a)
//---------------------------------------------------------------------------
// (b-a)*(n*1/10)
reg     [24:0]          numer;      // R13S12*R12U11=R25S23
reg     [11:0]          n_div_10;
reg     [11:0]          coef_start_d1;
always @(*) begin
    case (n_reg)
        4'd1: n_div_10 = 12'd205;
        4'd2: n_div_10 = 12'd410;
        4'd3: n_div_10 = 12'd615;
        4'd4: n_div_10 = 12'd820;
        4'd5: n_div_10 = 12'd1025;
        4'd6: n_div_10 = 12'd1230;
        4'd7: n_div_10 = 12'd1435;
        4'd8: n_div_10 = 12'd1640;
        4'd9: n_div_10 = 12'd1845;
        default: n_div_10 = 12'd0;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        coef_start_d1 <= 0;
    end
    else begin
        if (work_en) begin
            coef_start_d1 <= coef_start;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        numer <= 0;
    end
    else begin
        if (work_en) begin
            if (sc_en) begin
                numer <= $signed(coef_diff) * $signed(n_div_10);
            end
        end
    end
end
//---------------------------------------------------------------------------
// output
//---------------------------------------------------------------------------
// a + (b-a)*(n*1/10)
wire [24:0] a_r25u23 = {2'd0, coef_start_d1, 11'd0};    // R12U12*R12U11 -> R24U23
wire [24:0] a_sub    = a_r25u23 + numer;                // R25U23, must be positive
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        coef_en <= 0;
        coef_val <= 0;
    end
    else begin
        if (work_en) begin
            if (sc_en_d1) begin     // Truncate Method: Unsigned Round
                coef_en <= 1;
//                if (n_reg_d1 == 0) begin        // 20180503, Qu.Jin Confirmed!!!
//                    coef_val <= coef_start;
//                end
//                else begin
                    if (a_sub[10]) begin
                        if (a_sub[23:11] >= 13'h0fff) begin
                            coef_val <= 12'hfff;
                        end
                        else begin
                            coef_val <= a_sub[22:11] + 1;
                        end
                    end
                    else begin
                        coef_val <= a_sub[22:11];
                    end
//                end
            end
            else begin
                coef_en <= 0;
            end
        end
        else begin
            coef_en <= 0;
        end
    end
end

endmodule
