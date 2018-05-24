// 201804110931
// Wbird
module srs (
    // sys
    input               clk,
    input               rst_n,
    input               start,
    output reg          busy,
    output              done,
    // input
    input       [ 4:0]  n_slot,
    input       [ 1:0]  ifft_size_sel,
    input       [ 1:0]  symb_num,       // 00: 1        01: 2               10: -       11: 4
    input       [ 3:0]  start_symb,     // 0~13
    input       [ 1:0]  symb_index,     // 00: 0        01: 1               10: 2       11: 3
    input       [ 1:0]  hop_mode,
    input       [30:0]  c_init,
    input               ktc,
    input       [ 1:0]  ap_num,
    input       [ 3:0]  srs_cs,
    input       [10:0]  n_zc,
    input       [10:0]  m_sc,
    input       [14:0]  a,
    input       [13:0]  b,
    input       [ 1:0]  scs,
    input       [11:0]  ant0_re_start,
    input       [11:0]  ant1_re_start,
    // RAM beta_n
    output              coef0_ram_rd,
    output      [ 7:0]  coef0_ram_raddr,
    input       [15:0]  coef0_ram_rdata,
    output              coef1_ram_rd,
    output      [ 7:0]  coef1_ram_raddr,
    input       [15:0]  coef1_ram_rdata,
    output              coef2_ram_rd,
    output      [ 7:0]  coef2_ram_raddr,
    input       [15:0]  coef2_ram_rdata,
    output              coef3_ram_rd,
    output      [ 7:0]  coef3_ram_raddr,
    input       [15:0]  coef3_ram_rdata,
    // IFFT
    output              ant0_ifft_ram_wr,
    output      [11:0]  ant0_ifft_ram_waddr,
    output      [23:0]  ant0_ifft_ram_wdata,
    output              ant1_ifft_ram_wr,
    output      [11:0]  ant1_ifft_ram_waddr,
    output      [23:0]  ant1_ifft_ram_wdata,
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
assign done = ant0_seq_done;
//---------------------------------------------------------------------------
// Ant0/1 : Cyclic Shift
//---------------------------------------------------------------------------
// inst
wire [3:0] a0_w;
wire [3:0] a1_w;
wire [3:0] a2_w;
wire [3:0] a3_w;
cyclic_shift u_cs (
    .ktc        ( ktc           ),
    .ap_num     ( ap_num        ),
    .srs_cs     ( srs_cs        ),
    .a0         ( a0_w          ),
    .a1         ( a1_w          ),
    .a2         ( a2_w          ),
    .a3         ( a3_w          )
);
// reg
reg [3:0] a0;
reg [3:0] a1;
reg [3:0] a2;
reg [3:0] a3;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        a0 <= 0;
        a1 <= 0;
        a2 <= 0;
        a3 <= 0;
    end
    else begin
        if (start) begin
            a0 <= a0_w;
            a1 <= a1_w;
            a2 <= a2_w;
            a3 <= a3_w;
        end
    end
end
//---------------------------------------------------------------------------
// Ant0/1: Trigger
//---------------------------------------------------------------------------
reg ant0_start;
reg ant1_start;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ant0_start <= 0;
        ant1_start <= 0;
    end
    else begin
        if (start) begin
            if (ap_num == 2'd0) begin
                ant0_start <= 1;
                ant1_start <= 0;
            end
            else if (ap_num == 2'd1) begin
                ant0_start <= 1;
                ant1_start <= 1;
            end
            else begin
                ant0_start <= 0;
                ant1_start <= 0;
            end
        end
        else begin
            ant0_start <= 0;
            ant1_start <= 0;
        end
    end
end
//---------------------------------------------------------------------------
// Ant0 Sequence Generate
//---------------------------------------------------------------------------
wire ant0_seq_start;
wire ant0_seq_busy;
wire ant0_seq_done;
srs_seq u_ant0_seq (
    .clk                ( clk                   ),
    .rst_n              ( rst_n                 ),
    .start              ( ant0_seq_start        ),
    .busy               ( ant0_seq_busy         ),
    .done               ( ant0_seq_done         ),
    .ifft_size_sel      ( ifft_size_sel         ),
    .n_slot             ( n_slot                ),
    .symb_num           ( symb_num              ),
    .start_symb         ( start_symb            ),
    .symb_index         ( symb_index            ),
    .hop_mode           ( hop_mode              ),
    .c_init             ( c_init                ),
    .ktc                ( ktc                   ),
    .n_zc               ( n_zc                  ),
    .m_sc               ( m_sc                  ),
    .a                  ( a                     ),
    .b                  ( b                     ),
    .scs                ( scs                   ),
    .alpha_p            ( a0                    ),
    .re_start           ( ant0_re_start         ),
    .coef0_ram_rd       ( coef0_ram_rd          ),
    .coef0_ram_raddr    ( coef0_ram_raddr       ),
    .coef0_ram_rdata    ( coef0_ram_rdata       ),
    .coef1_ram_rd       ( coef1_ram_rd          ),
    .coef1_ram_raddr    ( coef1_ram_raddr       ),
    .coef1_ram_rdata    ( coef1_ram_rdata       ),
    .ifft_ram_wr        ( ant0_ifft_ram_wr      ),
    .ifft_ram_waddr     ( ant0_ifft_ram_waddr   ),
    .ifft_ram_wdata     ( ant0_ifft_ram_wdata   )
);
//---------------------------------------------------------------------------
// Ant1 Sequence Generate
//---------------------------------------------------------------------------
wire ant1_seq_start;
wire ant1_seq_busy;
wire ant1_seq_done;
srs_seq u_ant1_seq (
    .clk                ( clk                   ),
    .rst_n              ( rst_n                 ),
    .start              ( ant1_seq_start        ),
    .busy               ( ant1_seq_busy         ),
    .done               ( ant1_seq_done         ),
    .ifft_size_sel      ( ifft_size_sel         ),
    .n_slot             ( n_slot                ),
    .symb_num           ( symb_num              ),
    .start_symb         ( start_symb            ),
    .symb_index         ( symb_index            ),
    .hop_mode           ( hop_mode              ),
    .c_init             ( c_init                ),
    .ktc                ( ktc                   ),
    .n_zc               ( n_zc                  ),
    .m_sc               ( m_sc                  ),
    .a                  ( a                     ),
    .b                  ( b                     ),
    .scs                ( scs                   ),
    .alpha_p            ( a1                    ),
    .re_start           ( ant1_re_start         ),
    .coef0_ram_rd       ( coef2_ram_rd          ),
    .coef0_ram_raddr    ( coef2_ram_raddr       ),
    .coef0_ram_rdata    ( coef2_ram_rdata       ),
    .coef1_ram_rd       ( coef3_ram_rd          ),
    .coef1_ram_raddr    ( coef3_ram_raddr       ),
    .coef1_ram_rdata    ( coef3_ram_rdata       ),
    .ifft_ram_wr        ( ant1_ifft_ram_wr      ),
    .ifft_ram_waddr     ( ant1_ifft_ram_waddr   ),
    .ifft_ram_wdata     ( ant1_ifft_ram_wdata   )
);

endmodule
