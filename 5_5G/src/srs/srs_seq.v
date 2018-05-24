// 201804131035
// Wbird
module srs_seq (
    // sys
    input               clk,
    input               rst_n,
    input               start,
    output reg          busy,
    output              done,
    // input
    input       [ 1:0]  ifft_size_sel,
    input       [ 4:0]  n_slot,
    input       [ 1:0]  symb_num,       // 00: 1        01: 2               10: -       11: 4
    input       [ 3:0]  start_symb,     // 0~13
    input       [ 1:0]  symb_index,     // 00: 0        01: 1               10: 2       11: 3
    input       [ 1:0]  hop_mode,
    input       [30:0]  c_init,
    input               ktc,
    input       [10:0]  n_zc,
    input       [10:0]  m_sc,
    input       [14:0]  a,
    input       [13:0]  b,
    input       [ 1:0]  scs,
    input       [ 3:0]  alpha_p,
    input       [11:0]  re_start,
    // RAM beta_n
    output              coef0_ram_rd,
    output      [ 7:0]  coef0_ram_raddr,
    input       [15:0]  coef0_ram_rdata,        // R16U16
    output              coef1_ram_rd,
    output      [ 7:0]  coef1_ram_raddr,
    input       [15:0]  coef1_ram_rdata,
    // IFFT
    output              ifft_ram_wr,
    output      [11:0]  ifft_ram_waddr,
    output      [23:0]  ifft_ram_wdata
);

//---------------------------------------------------------------------------
// Args
//---------------------------------------------------------------------------


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


// ki
wire [11:0] ki;
assign ki = 12'd123;  // ????



//---------------------------------------------------------------------------
// Angle
//---------------------------------------------------------------------------
wire ang_start;
wire phi_en;
wire [11:0] phi_val;
assign ang_start = start;
angle_pipeline u_angle (
    .clk                ( clk                   ),
    .rst_n              ( rst_n                 ),
    .start              ( ang_start             ),
    .alpha_p            ( alpha_p               ),      // alpha 0
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
    .phi_en             ( phi_en                ),
    .phi_val            ( phi_val               )
);
//---------------------------------------------------------------------------
// Cordic
//---------------------------------------------------------------------------
wire ang_en;
wire [11:0] ang_val;
assign ang_en = phi_en;
assign ang_val = phi_val;
wire amp_en;
wire [11:0] amp_i;
wire [11:0] amp_q;
cordic_pipeline u_cordic (
    .clk                ( clk                   ),
    .rst_n              ( rst_n                 ),
    .cordic_en          ( 1'd1                  ),
    .ki                 ( ki                    ),
    .ang_en             ( ang_en                ),
    .ang_val            ( ang_val               ),
    .amp_en             ( amp_en                ),
    .amp_i              ( amp_i                 ),
    .amp_q              ( amp_q                 )
);
//---------------------------------------------------------------------------
// RE Index Management
//---------------------------------------------------------------------------
reg [11:0] ifft_size;
always @(*) begin
    case (ifft_size_sel)
        2'd0: ifft_size = 4096;
        2'd1: ifft_size = 2048;
        2'd2: ifft_size = 1024;
        2'd3: ifft_size =  512;
    endcase
end
wire [10:0] re_ini;
assign re_ini = ktc ? {1'd0, re_start[11:2]} : {re_start[11:1]};
wire [11:0] total_size;
assign total_size = {1'd0, re_ini} + {1'd0, m_sc};
wire [11:0] size_half;
assign size_half = {1'd0, total_size[11:1]} + {11'd0, total_size[0]};
reg [11:0] re_index;
wire [11:0] ifft_sub_ini;
assign ifft_sub_ini = ifft_size - size_half + re_ini;
wire [11:0] ini_sub_ifft;
assign ini_sub_ifft = re_ini - size_half;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        re_index <= 0;
    end
    else begin
        if (start) begin
            if ($unsigned(re_ini) < $unsigned(size_half)) begin
                if (ktc) begin
                    re_index <= {ifft_sub_ini[9:0], re_start[1:0]};
                end
                else begin
                    re_index <= {ifft_sub_ini[10:0], re_start[0]};
                end
            end
            else begin
                if (ktc) begin
                    re_index <= {ini_sub_ifft[9:0], re_start[1:0]};
                end
                else begin
                    re_index <= {ini_sub_ifft[10:0], re_start[0]};
                end
            end
        end
        else begin
            if (fcc_re_en) begin
                if (ktc) begin
                    if ((re_index+4) > ifft_size) begin
                        re_index <= re_index + 4 - ifft_size;
                    end
                    else begin
                        re_index <= re_index + 4;
                    end
                end
                else begin
                    if ((re_index+2) > ifft_size) begin
                        re_index <= re_index + 2 - ifft_size;
                    end
                    else begin
                        re_index <= re_index + 2;
                    end
                end
            end
        end
    end
end
//---------------------------------------------------------------------------
// Frequency Domain Compensation
//---------------------------------------------------------------------------
wire fcc_re_en;
wire [11:0] fcc_re_index;
wire fcc_coef_en;
wire [11:0] fcc_coef_addr;
wire [7:0] fcc_coef_val;
wire cordic_en_dn;        // ??? !!!
assign fcc_re_en = cordic_en_dn;        // ??? !!!
assign fcc_re_index = re_index;
freq_comp_coef u_freq_comp_coef (
    .clk                ( clk                   ),
    .rst_n              ( rst_n                 ),
    .work_en            ( 1'd1                  ),
    .scs                ( scs                   ),
    .re_en              ( fcc_re_en             ),
    .re_index           ( fcc_re_index          ),
    .coef0_ram_rd       ( coef0_ram_rd          ),
    .coef0_ram_raddr    ( coef0_ram_raddr       ),
    .coef0_ram_rdata    ( coef0_ram_rdata       ),
    .coef1_ram_rd       ( coef1_ram_rd          ),
    .coef1_ram_raddr    ( coef1_ram_raddr       ),
    .coef1_ram_rdata    ( coef1_ram_rdata       ),
    .coef_en            ( fcc_coef_en           ),
    .coef_addr          ( fcc_coef_addr         ),
    .coef_val           ( fcc_coef_val          )
);
//---------------------------------------------------------------------------
// COEF
//---------------------------------------------------------------------------
wire [27:0] i_mul_coef;
wire [27:0] 1_mul_coef;
assign i_mul_coef = $signed(amp_i) * $unsigned(fcc_coef_val);
assign q_mul_coef = $signed(amp_q) * $unsigned(fcc_coef_val);
reg iq_en;
reg [11:0] iq_addr;
reg [11:0] i;
reg [11:0] q;
// output
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        iq_en <= 0;
        iq_addr <= 0;
        i <= 0;
        q <= 0;
    end
    else begin
        if (start) begin
            iq_en <= 0;
            iq_addr <= 0;
            i <= 0;
            q <= 0;
        end
        else begin
            if (amp_en) begin
                iq_en <= 1;
                iq_addr <= fcc_coef_addr;
                i <= i_mul_coef[27:16];
                q <= q_mul_coef[27:16];
            end
            else begin
                iq_en <= 0;
            end
        end
    end
end
//---------------------------------------------------------------------------
// IFFT
//---------------------------------------------------------------------------
assign ifft_ram_wr = iq_en;
assign ifft_ram_waddr = iq_addr;
assign ifft_ram_wdata = {i, q};

endmodule
