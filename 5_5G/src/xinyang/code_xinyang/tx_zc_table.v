////////////////////////////////////////
// project name : 5G-NR
// module name  : tx_zc_table
// file name    : 
// autor        :
// version      :
////////////////////////////////////////

module tx_zc_table(
    //system clk and reset
    sys_clk               ,
    rst_n                 ,
                                                    
    //input signal   
    work_en               ,
    u                     ,
    n                     ,
    m_zc                  ,
    
    //out signal   
    fine          
    );
    
//parameter declear                                                                           
parameter                     DATA_WIDTH       = 3;                                      
                                                                                          
//input and output signal declear                                                         
input                         sys_clk          ;                                          
input                         rst_n            ;                                          
                                                                                          
//input signal        
input                         work_en          ;                                                                
input    [5 -1:0]             u                ; 
input    [5 -1:0]             n                ;                                          
input    [5 -1:0]             m_zc             ;                                                                                 
                                                                                          
//out signal                                                                            
output   [DATA_WIDTH-1:0]     fine             ;                                          
                                                                                          
//-------------------------------------------------------------------------------------   
//--------------                fine = mod(fine(u,n)+8,8)                --------------   
//-------------------------------------------------------------------------------------  
reg      [3*6 -1:0]           fine_zc_6_out;
//always@(*)
case(u)
    0  : fine_zc_6_out        = 'h2F6FD;
    1  : fine_zc_6_out        = 'h2BFDD;
    2  : fine_zc_6_out        = 'h2976D;
    3  : fine_zc_6_out        = 'h2F649;
    4  : fine_zc_6_out        = 'h1FA49;
    5  : fine_zc_6_out        = 'h2DBCD;
    6  : fine_zc_6_out        = 'h2DACD;
    7  : fine_zc_6_out        = 'h39A7D;
    8  : fine_zc_6_out        = 'h2D37D;
    9  : fine_zc_6_out        = 'h2BA6D;
    10 : fine_zc_6_out        = 'h2D2CD;
    11 : fine_zc_6_out        = 'h2937D;
    12 : fine_zc_6_out        = 'h1DEC9;
    13 : fine_zc_6_out        = 'h1F6C9;
    14 : fine_zc_6_out        = 'h3BA49;
    15 : fine_zc_6_out        = 'h2BE49;
    16 : fine_zc_6_out        = 'h3BFFD;
    17 : fine_zc_6_out        = 'h2F3ED;
    18 : fine_zc_6_out        = 'h3D36D;
    19 : fine_zc_6_out        = 'h2FA4D;
    20 : fine_zc_6_out        = 'h2935D;
    21 : fine_zc_6_out        = 'h3DB4D;
    22 : fine_zc_6_out        = 'h19749;
    23 : fine_zc_6_out        = 'h29B49;
    24 : fine_zc_6_out        = 'h1BEC9;
    25 : fine_zc_6_out        = 'h1B349;
    26 : fine_zc_6_out        = 'h3BFC9;
    27 : fine_zc_6_out        = 'h3F7C9;
    28 : fine_zc_6_out        = 'h3D7C9;
    29 : fine_zc_6_out        = 'h3F349;
    default:
    		 fine_zc_6_out        = 'h3F349; 
endcase 


reg      [3*12 -1:0]          fine_zc_12_out;
//always@(*)
case(u)
    0  : fine_zc_12_out       = 'h359FF92F9;
    1  : fine_zc_12_out       = 'h37B7E9FFF;
    2  : fine_zc_12_out       = 'hA49F5DB4D;
    3  : fine_zc_12_out       = 'h75924D65D;
    4  : fine_zc_12_out       = 'hA5FF6FECD;
    5  : fine_zc_12_out       = 'hA6FED9E4F;
    6  : fine_zc_12_out       = 'hBCD75B7ED;
    7  : fine_zc_12_out       = 'hA5BFEB75D;
    8  : fine_zc_12_out       = 'hA7F6EFF7D;
    9  : fine_zc_12_out       = 'hACDF6F6DD;
    10 : fine_zc_12_out       = 'h7CF2DB359;
    11 : fine_zc_12_out       = 'hA79F6DEEF;
    12 : fine_zc_12_out       = 'hBCB3EB2CB;
    13 : fine_zc_12_out       = 'hA5D3EB6ED;
    14 : fine_zc_12_out       = 'h6EF6D9A7D;
    15 : fine_zc_12_out       = 'h67BF6D2ED;
    16 : fine_zc_12_out       = 'hE6FE79ACF;
    17 : fine_zc_12_out       = 'h379E4B3FD;
    18 : fine_zc_12_out       = 'h6EF37DAFD;
    19 : fine_zc_12_out       = 'hA6F6DFAED;
    20 : fine_zc_12_out       = 'hBEFF5BFCD;
    21 : fine_zc_12_out       = 'hAEB77F6CD;
    22 : fine_zc_12_out       = 'hBD977DBFD;
    23 : fine_zc_12_out       = 'h2D977D2FD;
    24 : fine_zc_12_out       = 'hAEB3DD2DD;
    25 : fine_zc_12_out       = 'hBEB6FD77B;
    26 : fine_zc_12_out       = 'hA49F7FEF9;
    27 : fine_zc_12_out       = 'h6D9FD9A5D;
    28 : fine_zc_12_out       = 'hACFEED75D;
    29 : fine_zc_12_out       = 'h3CF35BE5D;
    default:
    		 fine_zc_12_out       = 'h3CF35BE5D; 
endcase 


reg      [3*18 -1:0]          fine_zc_18_out;
//always@(*)
case(u)
    0  : fine_zc_18_out       = 'h1D7CBBEDF59EEB;
    1  : fine_zc_18_out       = 'h3BADF26FE7B26C;
    2  : fine_zc_18_out       = 'h0966BFED26FBDD;
    3  : fine_zc_18_out       = 'h0BE7FA6DA7DFC9;
    4  : fine_zc_18_out       = 'h1FB4F27BACB749;
    5  : fine_zc_18_out       = 'h3FAEDA4BEDBA6C;
    6  : fine_zc_18_out       = 'h3FE49FEBF4BBE0;
    7  : fine_zc_18_out       = 'h193EDBE9769B4D;
    8  : fine_zc_18_out       = 'h1B67DF69BDBBE9;
    9  : fine_zc_18_out       = 'h3BECFADF3FFE5C;
    10 : fine_zc_18_out       = 'h0B2FB6DFA4FE6D;
    11 : fine_zc_18_out       = 'h1FFEBBCDECD6ED;
    12 : fine_zc_18_out       = 'h0FBDDA5B34B6ED;
    13 : fine_zc_18_out       = 'h2DBDB349F4B3DC;
    14 : fine_zc_18_out       = 'h3F24DBEDA5FF4C;
    15 : fine_zc_18_out       = 'h3BF697FFBFB6EC;
    16 : fine_zc_18_out       = 'h0B7FFBCFBDF6FD;
    17 : fine_zc_18_out       = 'h2F7796DFACDF7C;
    18 : fine_zc_18_out       = 'h3DEF9249F5FE5C;
    19 : fine_zc_18_out       = 'h1B25FA7B76D37B;
    20 : fine_zc_18_out       = 'h1BF69BCF7EFADB;
    21 : fine_zc_18_out       = 'h2BACB6ED3ED2FC;
    22 : fine_zc_18_out       = 'h2FFDD7EFAC9A4C;
    23 : fine_zc_18_out       = 'h3FEFD6EFEE9BFC;
    24 : fine_zc_18_out       = 'h1DAFB36B25D36D;
    25 : fine_zc_18_out       = 'h0DEFD2DD66DB49;
    26 : fine_zc_18_out       = 'h1DA49BEDF7D3FB;
    27 : fine_zc_18_out       = 'h19F5DBEDEDD34B;
    28 : fine_zc_18_out       = 'h0D7EB75B26DA6F;
    29 : fine_zc_18_out       = 'h197DBFEFBC9B7D;
    default:
    		 fine_zc_18_out       = 'h197DBFEFBC9B7D; 
endcase 

reg      [3*18 -1:0]          fine_zc_24_out;
//always@(*)
case(u)
    0  : fine_zc_24_out       = 'hB5B35B75FF4DA692EF;
    1  : fine_zc_24_out       = 'hB6B6EFACFBE9ECBEEF;
    2  : fine_zc_24_out       = 'hB49FFDB6FBCD34F65D;
    3  : fine_zc_24_out       = 'hB49F6FFFFAED269EFB;
    4  : fine_zc_24_out       = 'hB7D7EDBEB2796FDEE9;
    5  : fine_zc_24_out       = 'hB6D3FFEE977B26BE7B;
    6  : fine_zc_24_out       = 'hACD3ED2D925BFF97DD;
    7  : fine_zc_24_out       = 'hB6D37DE59BFBA4DA7D;
    8  : fine_zc_24_out       = 'hB49A4DA6DB69A6D34D;
    9  : fine_zc_24_out       = 'hB797DFAFB24BF5BF6B;
    10 : fine_zc_24_out       = 'hB4FE5BAE9AFDE6FFED;
    11 : fine_zc_24_out       = 'hBDD3FDF5F3E9FF96ED;
    12 : fine_zc_24_out       = 'hBFF34D7F93F9F5BE6D;
    13 : fine_zc_24_out       = 'hB6DA79ECFBCBBFF74D;
    14 : fine_zc_24_out       = 'hACBBCB26FF4B2EBF6D;
    15 : fine_zc_24_out       = 'hB4D66F76BA79A4FBC9;
    16 : fine_zc_24_out       = 'hB7FACFB5D6692DF7DD;
    17 : fine_zc_24_out       = 'hB5FF4B26FF7B37F36F;
    18 : fine_zc_24_out       = 'hB6DBCBBD9F6964D34D;
    19 : fine_zc_24_out       = 'hB5DADFEEBF7F2CDEEB;
    20 : fine_zc_24_out       = 'hB79BCB37F659FDFB5F;
    21 : fine_zc_24_out       = 'hAEDBFD77B7CD65FF4D;
    22 : fine_zc_24_out       = 'hB7F25FA5F3DFF69BFD;
    23 : fine_zc_24_out       = 'hADB3D9B6DF7974D74D;
    24 : fine_zc_24_out       = 'hBCBB6FE79ED927FA7D;
    25 : fine_zc_24_out       = 'hB6BA4BEEFBDFBFB3EB;
    26 : fine_zc_24_out       = 'hADDFEFFDDF7BAF9ECD;
    27 : fine_zc_24_out       = 'hB792FD75FAFF7FFBDD;
    28 : fine_zc_24_out       = 'hBCF3DB64F26FA7DBCD;
    29 : fine_zc_24_out       = 'hB7DF6D259BDFFDBFDF;
    default:
    		 fine_zc_24_out       = 'hB7DF6D259BDFFDBFDF; 
endcase  

reg      [3*18 -1:0]          fine_zc_out;    
//always@(*)
if(m_zc == 24)begin
    fine_zc_out               = fine_zc_24_out;
end
else if(m_zc == 16)begin
    fine_zc_out               = {6'b0,fine_zc_18_out};
end
else if(m_zc == 12)begin
    fine_zc_out               = {12'b0,fine_zc_12_out};
end
else begin
    fine_zc_out               = {18'b0,fine_zc_6_out};
end

reg      [3 -1:0]            fine;   
always@(posedge sys_clk)
if(work_en == 1'b1)begin
    case(n)
        0  : fine            <= fine_zc_out[ 1*3: 0*3];
        1  : fine            <= fine_zc_out[ 2*3: 1*3];
        2  : fine            <= fine_zc_out[ 3*3: 2*3];
        3  : fine            <= fine_zc_out[ 4*3: 3*3];
        4  : fine            <= fine_zc_out[ 5*3: 4*3];
        5  : fine            <= fine_zc_out[ 6*3: 5*3];
        6  : fine            <= fine_zc_out[ 7*3: 6*3];
        7  : fine            <= fine_zc_out[ 8*3: 7*3];
        8  : fine            <= fine_zc_out[ 9*3: 8*3];
        9  : fine            <= fine_zc_out[10*3: 9*3];
        10 : fine            <= fine_zc_out[11*3:10*3];
        11 : fine            <= fine_zc_out[12*3:11*3];
        12 : fine            <= fine_zc_out[13*3:12*3];
        13 : fine            <= fine_zc_out[14*3:13*3];
        14 : fine            <= fine_zc_out[15*3:14*3];
        15 : fine            <= fine_zc_out[16*3:15*3];
        16 : fine            <= fine_zc_out[17*3:16*3];
        17 : fine            <= fine_zc_out[18*3:17*3];
        18 : fine            <= fine_zc_out[19*3:18*3];
        19 : fine            <= fine_zc_out[20*3:19*3];
        20 : fine            <= fine_zc_out[21*3:20*3];
        21 : fine            <= fine_zc_out[22*3:21*3];
        22 : fine            <= fine_zc_out[23*3:22*3];
        23 : fine            <= fine_zc_out[24*3:23*3];
        default:            
             fine            <= fine_zc_out[24*3:23*3];   
    endcase 
end
	
endmodule