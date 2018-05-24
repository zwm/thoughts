// Author: Wbird
// Time  : 201804051207
module ul_srch_900k (
    input      [ 1:0] scs,
    input      [11:0] re_index,
    output reg [ 7:0] seg_900k,
    output reg [ 7:0] mod_900k
);

// scs30, seg128
wire [14:0] div_mod30_A;
wire [10:0] div_mod30_D;
wire [ 4:0] div_mod30_M;
assign div_mod30_A = {3'd0, re_index};
ul_div_mod30 u_div_mod30 (
  .A        ( div_mod30_A       ),
  .D        ( div_mod30_D       ),
  .M        ( div_mod30_M       )
);
wire [7:0] scs30_900k_seg;
wire [4:0] scs30_900k_mod;
assign scs30_900k_seg = div_mod30_D[7:0];
assign scs30_900k_mod = div_mod30_M;

// scs15, seg64
wire [11:0] div_mod60_A;
wire [ 6:0] div_mod60_D;
wire [ 5:0] div_mod60_M;
assign div_mod60_A = re_index;
ul_div_mod60 u_div_mod60 (
  .A        ( div_mod60_A       ),
  .D        ( div_mod60_D       ),
  .M        ( div_mod60_M       )
);
wire [6:0] scs15_900k_seg;
wire [5:0] scs15_900k_mod;
assign scs15_900k_seg = div_mod60_D[6:0];
assign scs15_900k_mod = div_mod60_M;

// scs5, seg16
reg [4:0] scs5_900k_seg;
reg [7:0] scs5_900k_mod;
always @(*) begin
    case (re_index[11:8])
        4'd0:
            if (re_index[7:0] < 180) begin
                scs5_900k_seg = 0;
                scs5_900k_mod = re_index[7:0] + 0;
            end
            else begin
                scs5_900k_seg = 1;
                scs5_900k_mod = re_index[7:0] - 180;
            end
        4'd1:
            if (re_index[7:0] < 104) begin
                scs5_900k_seg = 1;
                scs5_900k_mod = re_index[7:0] + 76;
            end
            else begin
                scs5_900k_seg = 2;
                scs5_900k_mod = re_index[7:0] - 104;
            end
        4'd2:
            if (re_index[7:0] < 28) begin
                scs5_900k_seg = 2;
                scs5_900k_mod = re_index[7:0] + 152;
            end
            else begin
                scs5_900k_seg = 3;
                scs5_900k_mod = re_index[7:0] - 28;
            end
        4'd3:
            if (re_index[7:0] < 132) begin
                scs5_900k_seg = 4;
                scs5_900k_mod = re_index[7:0] + 48;
            end
            else begin
                scs5_900k_seg = 5;
                scs5_900k_mod = re_index[7:0] - 132;
            end
        4'd4:
            if (re_index[7:0] < 56) begin
                scs5_900k_seg = 5;
                scs5_900k_mod = re_index[7:0] + 124;
            end
            else begin
                scs5_900k_seg = 6;
                scs5_900k_mod = re_index[7:0] - 56;
            end
        4'd5:
            if (re_index[7:0] < 160) begin
                scs5_900k_seg = 7;
                scs5_900k_mod = re_index[7:0] + 20;
            end
            else begin
                scs5_900k_seg = 8;
                scs5_900k_mod = re_index[7:0] - 160;
            end
        4'd6:
            if (re_index[7:0] < 84) begin
                scs5_900k_seg = 8;
                scs5_900k_mod = re_index[7:0] + 96;
            end
            else begin
                scs5_900k_seg = 9;
                scs5_900k_mod = re_index[7:0] - 84;
            end
        4'd7:
            if (re_index[7:0] < 8) begin
                scs5_900k_seg = 9;
                scs5_900k_mod = re_index[7:0] + 172;
            end
            else begin
                scs5_900k_seg = 10;
                scs5_900k_mod = re_index[7:0] - 8;
            end
        4'd8:
            if (re_index[7:0] < 112) begin
                scs5_900k_seg = 11;
                scs5_900k_mod = re_index[7:0] + 68;
            end
            else begin
                scs5_900k_seg = 12;
                scs5_900k_mod = re_index[7:0] - 112;
            end
        4'd9:
            if (re_index[7:0] < 36) begin
                scs5_900k_seg = 12;
                scs5_900k_mod = re_index[7:0] + 144;
            end
            else begin
                scs5_900k_seg = 13;
                scs5_900k_mod = re_index[7:0] - 36;
            end
        4'd10:
            if (re_index[7:0] < 140) begin
                scs5_900k_seg = 14;
                scs5_900k_mod = re_index[7:0] + 40;
            end
            else begin
                scs5_900k_seg = 15;
                scs5_900k_mod = re_index[7:0] - 140;
            end
        4'd11:
            if (re_index[7:0] < 64) begin
                scs5_900k_seg = 15;
                scs5_900k_mod = re_index[7:0] + 116;
            end
            else begin
                scs5_900k_seg = 16;
                scs5_900k_mod = re_index[7:0] - 64;
            end
        4'd12:
            if (re_index[7:0] < 168) begin
                scs5_900k_seg = 17;
                scs5_900k_mod = re_index[7:0] + 12;
            end
            else begin
                scs5_900k_seg = 18;
                scs5_900k_mod = re_index[7:0] - 168;
            end
        4'd13:
            if (re_index[7:0] < 92) begin
                scs5_900k_seg = 18;
                scs5_900k_mod = re_index[7:0] + 88;
            end
            else begin
                scs5_900k_seg = 19;
                scs5_900k_mod = re_index[7:0] - 92;
            end
        4'd14:
            if (re_index[7:0] < 16) begin
                scs5_900k_seg = 19;
                scs5_900k_mod = re_index[7:0] + 164;
            end
            else begin
                scs5_900k_seg = 20;
                scs5_900k_mod = re_index[7:0] - 16;
            end
        4'd15:
            if (re_index[7:0] < 120) begin
                scs5_900k_seg = 21;
                scs5_900k_mod = re_index[7:0] + 60;
            end
            else begin
                scs5_900k_seg = 22;
                scs5_900k_mod = re_index[7:0] - 120;
            end
    endcase
end

// output
always @(*) begin
    case (scs)
        2'd0: begin
            seg_900k = 0;
            mod_900k = 0;
        end
        2'd1: begin
            seg_900k = {3'd0, scs5_900k_seg};
            mod_900k = scs5_900k_mod;
        end
        2'd2: begin
            seg_900k = {1'd0, scs15_900k_seg};
            mod_900k = {2'd0, scs15_900k_mod};
        end
        2'd3: begin
            seg_900k = scs30_900k_seg;
            mod_900k = {3'd0, scs30_900k_mod};
        end
    endcase
end

endmodule
