// 201804071109
// Wbird
module angle_pipeline (
    // sys
    input               clk,
    input               rst_n,
    input               start,
    // input
    input       [ 4:0]  n_slot,
    input       [ 1:0]  symb_num,       // 00: 1        01: 2               10: -       11: 4
    input       [ 3:0]  start_symb,     // 0~13
    input       [ 1:0]  symb_index,     // 00: 0        01: 1               10: 2       11: 3
    input       [ 1:0]  hop_mode,
    input       [30:0]  c_init,
    input       [ 3:0]  alpha_p,
    input       [10:0]  n_zc,
    input       [10:0]  m_sc,
    input               ktc,
    input       [14:0]  a,
    input       [13:0]  b,

    output              phi_en,
    output      [11:0]  phi_val     // R12S10
);

//---------------------------------------------------------------------------
// Engine Select
//---------------------------------------------------------------------------
wire zc_sel;
assign zc_sel = (m_sc < 36) ? 1'd0 : 1'd1;

//---------------------------------------------------------------------------
// ZC Angle Generate
//---------------------------------------------------------------------------
// hop
wire hop_start;
wire hop_busy;
wire hop_done;
wire [4:0] u;
wire v;
assign hop_start = zc_sel & start;
hop u_hop (
    .clk                ( clk               ),
    .rst_n              ( rst_n             ),
    .start              ( hop_start         ),
    .busy               ( hop_busy          ),
    .done               ( hop_done          ),
    .hop_mode           ( hop_mode          ),
    .n_slot             ( n_slot            ),
    .symb_num           ( symb_num          ),
    .start_symb         ( start_symb        ),
    .symb_index         ( symb_index        ),
    .c_init             ( c_init            ),
    .u                  ( u                 ),
    .v                  ( v                 )
);
// zc angle
wire zc_start;
wire zc_busy;
wire zc_done;
wire zc_phi_en;
wire [11:0] zc_phi_val;
assign zc_start = hop_done;
zc_ang_pipeline u_zc_ang (
    .clk                ( clk               ),
    .rst_n              ( rst_n             ),
    .start              ( zc_start          ),
    .busy               ( zc_busy           ),
    .done               ( zc_done           ),
    .alpha_p            ( alpha_p           ),
    .n_zc               ( n_zc              ),
    .m_sc               ( m_sc              ),
    .u                  ( u                 ),
    .v                  ( v                 ),
    .ktc                ( ktc               ),
    .a                  ( a                 ),
    .b                  ( b                 ),
    .phi_en             ( zc_phi_en         ),
    .phi_val            ( zc_phi_val        )
);

//---------------------------------------------------------------------------
// CG Angle Generate
//---------------------------------------------------------------------------
wire cg_start;
wire cg_busy;
wire cg_done;
wire cg_phi_en;
wire [11:0] cg_phi_val;
cg_ang_pipeline u_cg_ang (
    .clk                ( clk               ),
    .rst_n              ( rst_n             ),
    .start              ( cg_start          ),
    .busy               ( cg_busy           ),
    .done               ( cg_done           ),
    .alpha_p            ( alpha_p           ),
    .m_sc               ( m_sc              ),
    .u                  ( u                 ),
    .ktc                ( ktc               ),
    .phi_en             ( cg_phi_en         ),
    .phi_val            ( cg_phi_val        )
);


//---------------------------------------------------------------------------
// Angle Output
//---------------------------------------------------------------------------
assign phi_en  = zc_sel ? zc_phi_en  : cg_phi_en;
assign phi_val = zc_sel ? zc_phi_val : cg_phi_val;

endmodule
