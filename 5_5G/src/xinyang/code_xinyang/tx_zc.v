////////////////////////////////////////
// project name : 5G-NR
// module name  : tx_zc
// file name    : 
// autor        :
// version      :
////////////////////////////////////////

module tx_zc(
    //system clk and reset
    sys_clk               ,
    rst_n                 ,
    
    //configure signal  
    u                     ,
    v                     ,
    alpha                 ,
    zc_start_index        ,
    zc_len                ,
    zc_N_zc               ,
    zc_Q                  ,
    zc_P                  ,
                                                    
    //control signal   
    start                 ,
    n                     ,
    alpha                 ,
    
    //out signal   
    busy                  ,
    done                  ,
    zc_out_valid          ,
    zc_out_data        
    );
    
//parameter declear                                                                           
parameter                     DATA_WIDTH       = 12;                                      
                                                                                          
//input and output signal declear                                                         
input                         sys_clk          ;                                          
input                         rst_n            ;                                          
                                                                                          
//configure signal                                                                           
input    [5 -1:0]             u                ; 
input    [5 -1:0]             v                ;                                         
input    [5 -1:0]             alpha            ; 
input    [12-1:0]             zc_start_index   ;  
input    [12-1:0]             zc_len           ;
input    [12-1:0]             zc_N_zc          ;
input    [15-1:0]             zc_Q             ; //mod(12q,2*12*Nzc)
input    [16-1:0]             zc_P             ; //mod(2*a*Nzc,2*12*Nzc)    

//control signal  
input                         start            ;                                                            
                                                                                          
//out signal    
output                        busy             ; 
output                        done             ;   
output                        zc_out_valid     ;                                                                        
output   [12*2-1:0]           zc_out_data      ; //C12S9                                        
                                                                                          
//-------------------------------------------------------------------------------------   
//--------------                        Mzc < 30                         --------------   
//-------------------------------------------------------------------------------------  
wire     [5 -1:0]             short_zc_start_n = zc_start_index[4:0];
wire                          short_theta_busy   ;
wire                          short_theta_end    ; 
wire                          short_theta_valid  ; 
wire     [12-1:0]             short_theta        ;   //R12S10 

tx_short_zc u_short_zc(
        //system clk and reset
        .sys_clk              (sys_clk            ),
        .rst_n                (rst_n              ),
                                                  
        //configure signal                        
        .u                    (u                  ),
        .start_n              (short_zc_start_n   ),
        .alpha                (alpha              ),
        .m_zc                 (zc_N_zc            ),
                                                  
        //control signal                          
        .start                (start              ),
                                                  
        //out signal    
        .busy                 (short_theta_busy   ),
        .theta_out_end        (short_theta_end    ),  
        .theta_out_valid      (short_theta_valid  ),
        .theta_out            (short_theta        )
        );
        
//-------------------------------------------------------------------------------------         
//--------------                        Mzc >= 30                        -------------- 
//------------------------------------------------------------------------------------- 
wire                          norm_theta_busy   ;
wire                          norm_theta_end    ; 
wire                          norm_theta_valid  ; 
wire     [12-1:0]             norm_theta        ;   //R12S10 
 
tx_norm_zc u_norm_zc(
        //system clk and reset
        .sys_clk              (sys_clk            ),    
        .rst_n                (rst_n              ),    
                                                        
        //configure signal  
        .u                    (u                  ),
        .v                    (v                  ),
        .alpha                (alpha              ),
        .zc_start_index       (zc_start_index     ),
        .zc_len               (zc_len             ),
        .zc_N_zc              (zc_N_zc            ),
        .zc_Q                 (zc_Q               ),
        .zc_P                 (zc_P               ),
                                                  
        //control signal                          
        .start                (start              ),
                            
        //out signal        
        .busy                 (norm_theta_busy    ),
        .theta_out_end        (norm_theta_end     ),  
        .theta_out_valid      (norm_theta_valid   ),
        .theta_out            (norm_theta         )
        );


//-------------------------------------------------------------------------------------  
//--------------                         cordic                          --------------  
//-------------------------------------------------------------------------------------  
wire                          theta_data_valid = zc_N_zc < 30 ? short_theta_valid : norm_theta_valid;         
wire     [15-1:0]             theta_data       = zc_N_zc < 30 ? {short_theta,3'b0}: norm_theta      ;  //R15S13     
                                                                                              
wire                          cordic_busy      ;          
wire                          cordic_out_valid ;          
wire     [12*2-1:0]           cordic_out       ; //C12S9  

tx_cordic u_cordic(
        //system clk and reset
        .sys_clk              (sys_clk            ),
        .rst_n                (rst_n              ),
                                                        
        //input signal    
        .theta_data_valid     (theta_data_valid   ),
        .theta_data           (theta_data         ),
                                                  
        //out signal                              
        .busy                 (cordic_busy        ),
        .cordic_out_valid     (cordic_out_valid   ),
        .cordic_out           (cordic_out         )
        );
        
wire                          zc_out_valid = cordic_out_valid;
wire     [12*2-1:0]           zc_out_data  = cordic_out      ; 

wire                          busy = short_theta_busy | norm_theta_busy | cordic_busy;

endmodule
