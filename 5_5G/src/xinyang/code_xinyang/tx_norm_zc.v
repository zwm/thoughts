////////////////////////////////////////
// project name : 5G-NR
// module name  : tx_norm_zc
// file name    : 
// autor        :
// version      :
////////////////////////////////////////

module tx_norm_zc(
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
    
    //out signal    
    busy                  ,
    theta_out_end         ,  
    theta_out_valid       ,
    theta_out        
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
input    [15-1:0]             zc_Q             ; //mod(12q,2*12*Nzc) R15U0
input    [16-1:0]             zc_P             ; //mod(2*a*Nzc,2*12*Nzc) R16U0    

//control signal  
input                         start            ;                                                            
                                                                                          
//out signal            
output                        busy             ;
output                        theta_out_end    ;
output                        theta_out_valid  ;                                                                        
output   [12-1:0]             theta_out        ; //R12S10        


//-------------------------------------------------------------------------------------   
//--------------                        control                          --------------   
//------------------------------------------------------------------------------------- 
reg                           zc_work_end; 
reg                           zc_work_en; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    zc_work_en                <= 'h0;
end    
else if((start == 1'b1) && (zc_N_zc >= 30))begin
    zc_work_en                <= 'h1;
end 
else if(zc_work_end == 1'b1)begin
    zc_work_en                <= 'h0;
end 

//
reg     [12-1:0]              zc_cnt; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    zc_cnt                    <= 'h0;
end    
else if(start == 1'b1)begin
    zc_cnt                    <= 0;
end  
else if(zc_work_en == 1'b1)begin
    zc_cnt                    <= zc_cnt + 1'b1;
end 

//
//always@(*) 
if(zc_cnt >= zc_len-1)begin
    zc_work_end               = 1'b1;
end
else begin
    zc_work_end               = 1'b0;
end    

reg                           zc_work_en_1d;
reg                           zc_work_en_2d;
reg                           zc_work_en_3d;
reg                           zc_work_en_4d;
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    zc_work_en_1d             <= 1'b0;  
    zc_work_en_2d             <= 1'b0;
    zc_work_en_3d             <= 1'b0;
    zc_work_en_4d             <= 1'b0;
end 
else begin
    zc_work_en_1d             <= zc_work_en;  
    zc_work_en_2d             <= zc_work_en_1d;
    zc_work_en_3d             <= zc_work_en_2d;
    zc_work_en_4d             <= zc_work_en_3d;
end 

reg     [12-1:0]              zc_cnt_1d; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    zc_cnt_1d                 <= 'h0;
end  
else if(zc_work_en == 1'b1)begin
    zc_cnt_1d                 <= zc_cnt;
end  

reg     [12-1:0]              zc_cnt_2d; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    zc_cnt_2d                 <= 'h0;
end  
else if(zc_work_en_2d == 1'b1)begin
    zc_cnt_2d                 <= zc_cnt_1d;
end  
                                                                                                                            
//-------------------------------------------------------------------------------------   
//--------------                  fine(n) = mod(fine(n)+8,8)             --------------   
//-------------------------------------------------------------------------------------   
//n
wire    [12-1:0]              n = zc_cnt; 

//m = mod(n,Nzc)
reg     [12-1:0]              m_temp; 
//always(*)
if({7'h0,n} >= {zc_N_zc,7'h0})begin
    m_temp                    = {7'h0,n} - {7'h0,n};
end
else if({6'h0,n} >= {zc_N_zc,6'h0})begin
    m_temp                    = {6'h0,n} - {6'h0,n};
end                                          
else if({5'h0,n} >= {zc_N_zc,5'h0})begin     
    m_temp                    = {5'h0,n} - {5'h0,n};
end                                          
else if({4'h0,n} >= {zc_N_zc,4'h0})begin     
    m_temp                    = {7'h0,n} - {4'h0,n};
end                                          
else if({3'h0,n} >= {zc_N_zc,3'h0})begin     
    m_temp                    = {3'h0,n} - {3'h0,n};
end                                          
else if({2'h0,n} >= {zc_N_zc,2'h0})begin     
    m_temp                    = {2'h0,n} - {2'h0,n};
end                                          
else if({1'h0,n} >= {zc_N_zc,1'h0})begin     
    m_temp                    = {1'h0,n} - {1'h0,n};
end  
else begin
    m_temp                    = n;
end  

wire    [12-1:0]              m = m_temp[11:0]; 

//T = 2*12*Nzc
wire    [17-1:0]              T = {zc_N_zc,4'b0} + {zc_N_zc,3'b0};

//beta(n+1) = mod(beta(n) + P,2*12*Nzc)
wire    [17-1:0]              beta_tmp = beta + zc_P;
wire    [17-1:0]              beta_tmp_wrap = beta_tmp - zc_N_zc;
reg     [16-1:0]              beta;  //R16U0
always@(posedge sys_clk)
if(start == 1'b1)begin
    beta                      <= 'h0;
end 
else if(zc_work_en == 1'b1)begin 
    if(beta_tmp_wrap[16] == 1'b1)begin
        beta                  <= beta_tmp[15:0];
    end
    else begin
        beta                  <= beta_tmp_wrap[15:0];
    end 
end 

//yita(m+1) = mod(yita(m) + 2(m+1)*12q,2*12*Nzc)
wire    [12-1:0]              m_add_1_mul_2 = {m,1'b1} + 12'd2; //2(m+1) R12U0 

wire    [27-1:0]              q_scale = zc_Q*m_add_1_mul_2; //R15U0 * R12U0 

wire    [16-1:0]              delt_yita = q_scale[27-1:11];

wire    [17-1:0]              yita_tmp = yita + delt_yita;
wire    [17-1:0]              yita_tmp_wrap = yita_tmp - zc_N_zc;
reg     [16-1:0]              yita;  //R16U0
always@(posedge sys_clk)
if(start == 1'b1)begin
    yita                      <= 'h0;
end 
else if(zc_work_en == 1'b1)begin 
    if(yita_tmp_wrap[16] == 1'b1)begin
        yita                  <= yita_tmp[15:0];
    end
    else begin
        yita                  <= yita_tmp_wrap[15:0];
    end 
end 

//theta(n) = mod(beta(n)-yita(m),2*12*Nzc)
wire    [17-1:0]              theta = beta - yita;  //R17S0

reg     [16-1:0]              theta_mod; //R16U0
//always@(*)
if(theta >= T)begin
    theta_mod                 = theta - T;
end                           
else begin                    
    theta_mod                 = theta;
end

//
wire    [16-1:0]              theta_wrap_TH = {zc_N_zc,2'b0} + {zc_N_zc,3'b0}; //12*Nzc      
wire    [17-1:0]              yita_tmp_wrap = T - theta_mod;
wire    [16-1:0]              theta_wrap; //R16S0
always@(posedge sys_clk)
if(start == 1'b1)begin
    theta_wrap                <= 'h0;
end 
else if(zc_work_en_1d == 1'b1)begin 
    if(theta_mod >= theta_wrap_TH)begin
        theta_wrap            <= yita_tmp_wrap[15:0];
    end 
    else begin
        theta_wrap            <= theta_mod;
    end 
end

//theta(n)/12
wire    [16-1:0]              theta_shift = theta; //R16S2

wire    [11-1:0]              scale_1_div_3_data = 683; //R11U11

wire    [27-1:0]              theta_scale = $signed(theta_shift) * $unsigned(scale_1_div_3_data);

wire    [16-1:0]              theta_scale_sat;
tx_fix_floor #(27,13,12,10) u_theta_scale(
         .x                   (theta_scale      ),
                                                
         .y                   (theta_scale_sat  )
         );           

wire    [12-1:0]              theta_out; //R12S10
always@(posedge sys_clk)
if(zc_work_en_2d == 1'b1)begin
    theta_out                 <= theta_scale_sat;
end    

reg                           theta_out_valid;
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    theta_out_valid           <= 'h0;
end  
else if((zc_work_en_2d == 1'b1) && (zc_cnt_2d >= zc_start_index))begin
    theta_out_valid           <= zc_cnt;
end 
else begin
    theta_out_valid           <= 'h0;
end  

wire                          theta_out_end = ~zc_work_en_2d & zc_work_en_3d;     

//always@(*)
if(start | zc_work_en | zc_work_en_1d | zc_work_en_2d | theta_out_end)begin
    busy                      = 1'b1;
end
else begin
    busy                      = 1'b0;
end

endmodule
