// 22bit mod 11bit
module ul_div_sync #(
    parameter DIVIDEND_WIDTH        = 10,
    parameter DIVISOR_WIDTH         = 8) (
    input                           clk,
    input                           rst_n,
    input                           start,
    output  reg                     busy,
    output  reg                     done,
    input   [DIVIDEND_WIDTH-1:0]    dividend,
    input   [DIVISOR_WIDTH-1:0]     divisor,
    output  [DIVIDEND_WIDTH-1:0]    quotient,
    output  [DIVISOR_WIDTH-1:0]     remainder
);

// Internal Signals
reg [7:0] div_cnt;      // ??? bit width???
reg [DIVIDEND_WIDTH-1:0] div_shift;
reg [DIVIDEND_WIDTH-1:0] div_quo;
reg [DIVISOR_WIDTH-1:0] div_rem;

wire [DIVISOR_WIDTH:0] div_pad;
assign div_pad = {div_rem[DIVISOR_WIDTH-1:0], div_shift[DIVIDEND_WIDTH-1]};
wire [DIVISOR_WIDTH:0] div_sub;
assign div_sub = div_pad - {1'd0, divisor};

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
            if (div_cnt == DIVIDEND_WIDTH-1) begin
                busy <= 0;
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
        if (busy == 1 && div_cnt == DIVIDEND_WIDTH-1) begin
            done <= 1;
        end
        else begin
            done <= 0;
        end
    end
end
// divide
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        div_cnt <= 0;
        div_quo <= 0;
        div_rem <= 0;
        div_shift <= 0;
    end
    else begin
        if (start) begin
            div_cnt <= 0;
            div_quo <= 0;
            div_rem <= 0;
            div_shift <= dividend;
        end
        else if (busy) begin
            // cnt
            div_cnt <= div_cnt + 1;
            // div
            if ($unsigned(div_pad) > $unsigned(divisor)) begin
                div_rem <= div_sub[DIVISOR_WIDTH-1:0];
                div_quo <= {div_quo[DIVIDEND_WIDTH-2:0], 1'd1};
            end
            else begin
                div_rem <= div_pad[DIVISOR_WIDTH-1:0];
                div_quo <= {div_quo[DIVIDEND_WIDTH-2:0], 1'd0};
            end
            // shift
            div_shift <= {div_shift[DIVIDEND_WIDTH-2:0], 1'd0};
        end
    end
end

// output
assign quotient = div_quo;
assign remainder = div_rem;

endmodule
