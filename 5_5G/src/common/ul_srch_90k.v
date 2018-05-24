// Author: Wbird
// Time  : 201804051453
module ul_srch_90k (
    input      [ 1:0] scs,
    input      [ 7:0] re_index,
    output reg [ 3:0] srch_90k_seg,
    output reg [ 4:0] srch_90k_mod
);

// scs30, gap3
reg [3:0] scs30_seg;
reg [7:0] scs30_mod;
always @(*) begin
    if (re_index >= 27) begin
        scs30_seg = 4'd9;
        scs30_mod = re_index - 27;
    end
    else if (re_index >= 24) begin
        scs30_seg = 4'd8;
        scs30_mod = re_index - 24;
    end
    else if (re_index >= 21) begin
        scs30_seg = 4'd7;
        scs30_mod = re_index - 21;
    end
    else if (re_index >= 18) begin
        scs30_seg = 4'd6;
        scs30_mod = re_index - 18;
    end
    else if (re_index >= 15) begin
        scs30_seg = 4'd5;
        scs30_mod = re_index - 15;
    end
    else if (re_index >= 12) begin
        scs30_seg = 4'd4;
        scs30_mod = re_index - 12;
    end
    else if (re_index >= 9) begin
        scs30_seg = 4'd3;
        scs30_mod = re_index - 9;
    end
    else if (re_index >= 6) begin
        scs30_seg = 4'd2;
        scs30_mod = re_index - 6;
    end
    else if (re_index >= 3) begin
        scs30_seg = 4'd1;
        scs30_mod = re_index - 3;
    end
    else begin
        scs30_seg = 4'd0;
        scs30_mod = re_index - 0;
    end
end
// scs15, gap6
reg [3:0] scs15_seg;
reg [7:0] scs15_mod;
always @(*) begin
    if (re_index >= 54) begin
        scs15_seg = 4'd9;
        scs15_mod = re_index - 54;
    end
    else if (re_index >= 48) begin
        scs15_seg = 4'd8;
        scs15_mod = re_index - 48;
    end
    else if (re_index >= 42) begin
        scs15_seg = 4'd7;
        scs15_mod = re_index - 42;
    end
    else if (re_index >= 36) begin
        scs15_seg = 4'd6;
        scs15_mod = re_index - 36;
    end
    else if (re_index >= 30) begin
        scs15_seg = 4'd5;
        scs15_mod = re_index - 30;
    end
    else if (re_index >= 24) begin
        scs15_seg = 4'd4;
        scs15_mod = re_index - 24;
    end
    else if (re_index >= 18) begin
        scs15_seg = 4'd3;
        scs15_mod = re_index - 18;
    end
    else if (re_index >= 12) begin
        scs15_seg = 4'd2;
        scs15_mod = re_index - 12;
    end
    else if (re_index >= 6) begin
        scs15_seg = 4'd1;
        scs15_mod = re_index - 6;
    end
    else begin
        scs15_seg = 4'd0;
        scs15_mod = re_index - 0;
    end
end
// scs5, gap18
reg [3:0] scs5_seg;
reg [7:0] scs5_mod;
always @(*) begin
    if (re_index >= 162) begin
        scs5_seg = 4'd9;
        scs5_mod = re_index - 162;
    end
    else if (re_index >= 144) begin
        scs5_seg = 4'd8;
        scs5_mod = re_index - 144;
    end
    else if (re_index >= 126) begin
        scs5_seg = 4'd7;
        scs5_mod = re_index - 126;
    end
    else if (re_index >= 108) begin
        scs5_seg = 4'd6;
        scs5_mod = re_index - 108;
    end
    else if (re_index >= 90) begin
        scs5_seg = 4'd5;
        scs5_mod = re_index - 90;
    end
    else if (re_index >= 72) begin
        scs5_seg = 4'd4;
        scs5_mod = re_index - 72;
    end
    else if (re_index >= 54) begin
        scs5_seg = 4'd3;
        scs5_mod = re_index - 54;
    end
    else if (re_index >= 36) begin
        scs5_seg = 4'd2;
        scs5_mod = re_index - 36;
    end
    else if (re_index >= 18) begin
        scs5_seg = 4'd1;
        scs5_mod = re_index - 18;
    end
    else begin
        scs5_seg = 4'd0;
        scs5_mod = re_index - 0;
    end
end
// output
always @(*) begin
    case (scs)
        2'd1: begin
            srch_90k_seg = scs5_seg;
            srch_90k_mod = scs5_mod[4:0];
        end
        2'd2: begin
            srch_90k_seg = scs15_seg;
            srch_90k_mod = scs15_mod[4:0];
        end
        2'd3: begin
            srch_90k_seg = scs30_seg;
            srch_90k_mod = scs30_mod[4:0];
        end
        default : begin
            srch_90k_seg = 0;
            srch_90k_mod = 0;
        end
    endcase
end

endmodule
