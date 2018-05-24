// Author: Wbird
// Time  : 201804051453
module srch_90k (
    input      [ 1:0] scs,
    input      [ 7:0] re_index,
    output reg [ 3:0] seg_90k
);

// scs30, gap3
reg [3:0] scs30_90k_seg;
always @(*) begin
    case (re_index[4:2])
        3'd0:
            if (re_index[1:0] < 3)
                scs30_90k_seg = 0;
            else
                scs30_90k_seg = 1;
        3'd1:
            if (re_index[1:0] < 2)
                scs30_90k_seg = 1;
            else
                scs30_90k_seg = 2;
        3'd2:
            if (re_index[1:0] < 1)
                scs30_90k_seg = 2;
            else
                scs30_90k_seg = 3;
        3'd3:
            if (re_index[1:0] < 3)
                scs30_90k_seg = 4;
            else
                scs30_90k_seg = 5;
        3'd4:
            if (re_index[1:0] < 2)
                scs30_90k_seg = 5;
            else
                scs30_90k_seg = 6;
        3'd5:
            if (re_index[1:0] < 1)
                scs30_90k_seg = 6;
            else
                scs30_90k_seg = 7;
        3'd6:
            if (re_index[1:0] < 3)
                scs30_90k_seg = 8;
            else
                scs30_90k_seg = 9;
        3'd7:
            if (re_index[1:0] < 2)
                scs30_90k_seg = 9;
            else
                scs30_90k_seg = 10;
    endcase
end
// scs15, gap6
reg [3:0] scs15_90k_seg;
always @(*) begin
    case (re_index[5:3])
        3'd0:
            if (re_index[2:0] < 6)
                scs15_90k_seg = 0;
            else
                scs15_90k_seg = 1;
        3'd1:
            if (re_index[2:0] < 4)
                scs15_90k_seg = 1;
            else
                scs15_90k_seg = 2;
        3'd2:
            if (re_index[2:0] < 2)
                scs15_90k_seg = 2;
            else
                scs15_90k_seg = 3;
        3'd3:
            if (re_index[2:0] < 6)
                scs15_90k_seg = 4;
            else
                scs15_90k_seg = 5;
        3'd4:
            if (re_index[2:0] < 4)
                scs15_90k_seg = 5;
            else
                scs15_90k_seg = 6;
        3'd5:
            if (re_index[2:0] < 2)
                scs15_90k_seg = 6;
            else
                scs15_90k_seg = 7;
        3'd6:
            if (re_index[2:0] < 6)
                scs15_90k_seg = 8;
            else
                scs15_90k_seg = 9;
        3'd7:
            if (re_index[2:0] < 4)
                scs15_90k_seg = 9;
            else
                scs15_90k_seg = 10;
    endcase
end
// scs5, gap18
reg [3:0] scs5_90k_seg;
always @(*) begin
    case (re_index[7:5])
        3'd0:
            if (re_index[4:0] < 18)
                scs5_90k_seg = 0;
            else
                scs5_90k_seg = 1;
        3'd1:
            if (re_index[4:0] < 4)
                scs5_90k_seg = 1;
            else
                scs5_90k_seg = 2;
        3'd2:
            if (re_index[4:0] < 8)
                scs5_90k_seg = 3;
            else
                scs5_90k_seg = 4;
        3'd3:
            if (re_index[4:0] < 12)
                scs5_90k_seg = 5;
            else
                scs5_90k_seg = 6;
        3'd4:
            if (re_index[4:0] < 16)
                scs5_90k_seg = 7;
            else
                scs5_90k_seg = 8;
        3'd5:
            if (re_index[4:0] < 2)
                scs5_90k_seg = 8;
            else
                scs5_90k_seg = 9;
        3'd6:
            if (re_index[4:0] < 6)
                scs5_90k_seg = 10;
            else
                scs5_90k_seg = 11;
        3'd7:
            if (re_index[4:0] < 10)
                scs5_90k_seg = 12;
            else
                scs5_90k_seg = 13;
    endcase
end

// output
always @(*) begin
    case (scs) begin
        2'd0:
            seg_90k = 0;
        2'd1:
            seg_90k = scs5_90k_seg;
        2'd2:
            seg_90k = scs15_90k_seg;
        2'd3:
            seg_90k = scs30_90k_seg;
    endcase
end

endmodule
