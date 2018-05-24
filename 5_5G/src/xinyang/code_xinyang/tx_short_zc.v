////////////////////////////////////////
// project name : 5G-NR
// module name  : tx_short_zc
// file name    : 
// autor        :
// version      :
////////////////////////////////////////

module tx_short_zc(
    //system clk and reset
    sys_clk               ,
    rst_n                 ,
                                                    
    //configure signal    
    u                     ,
    start_n               ,
    alpha                 ,
    m_zc                  ,
    
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
input    [5 -1:0]             start_n          ;
input    [5 -1:0]             alpha            ;                                        
input    [5 -1:0]             m_zc             ;    

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
else if((start == 1'b1) && (m_zc < 30))begin
    zc_work_en                <= 'h1;
end 
else if(zc_work_end == 1'b1)begin
    zc_work_en                <= 'h0;
end 

//
reg     [5 -1:0]              zc_cnt; 
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
if(zc_cnt >= m_zc-1)begin
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

reg     [5 -1:0]              zc_cnt_1d; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    zc_cnt_1d                 <= 'h0;
end  
else if(zc_work_en == 1'b1)begin
    zc_cnt_1d                 <= zc_cnt;
end  
                                                                                                                            
//-------------------------------------------------------------------------------------   
//--------------                  fine(n) = mod(fine(n)+8,8)             --------------   
//-------------------------------------------------------------------------------------   
wire    [3 -1:0]              fine; 
tx_zc_table u_zc_table(
        //system clk and reset
        .sys_clk              (sys_clk          ),
        .rst_n                (rst_n            ),
                                  
        //input signal     
        .work_en              (zc_work_en       ),
        .u                    (u                ),
        .n                    (zc_cnt           ),
        .m_zc                 (m_zc             ),
                                                
        //out signal                            
        .fine                 (fine             )
        );


//beta(n+1) = beta(n) + 2*alpha  = 2*n*alpha
reg     [10-1:0]              beta; 
reg     [10-1:0]              beta_wrap;
always@(posedge sys_clk)
if(start == 1'b1)begin
    beta                      <= 'h0; //beta(0) = 0
end  
else if(zc_work_en_1d == 1'b1)begin
    beta                      <= $signed(beta_wrap) + $unsigned({alpha,1'b0});
end 

//wrapper round

//always@(*)
if(beta < 12)begin
    beta_wrap                 = beta;
end
else begin
    beta_wrap                 = 24 - beta;
end

//theta(n) = 3*fine(n) + beta(n)
wire    [11-1:0]              theta_sum = beta + fine; 

//wrapper round
reg     [10-1:0]              theta_wrap;
//always@(*)
if(theta < 12)begin
    theta_wrap                = theta;
end
else begin
    theta_wrap                = 24 - theta;
end

wire    [5 -1:0]              theta = theta_wrap[4:0]; //R5S0

//theta(n)/12
wire    [5 -1:0]              theta_shift = theta; //R5U2

wire    [11-1:0]              scale_1_div_3_data = 683; //R11U11

wire    [16-1:0]              theta_scale = $signed(theta_shift) * $unsigned(scale_1_div_3_data);

wire    [16-1:0]              theta_scale_sat;
tx_fix_floor #(16,13,12,10) u_theta_scale(
         .x                   (theta_scale      ),
                                                
         .y                   (theta_scale_sat  )
         );      


wire    [12-1:0]              theta_out; //R12S10
always@(posedge sys_clk)
if(zc_work_en_1d == 1'b1)begin
    theta_out                 <= theta_scale_sat;
end  

//  
reg                           theta_out_valid;
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    theta_out_valid           <= 'h0;
end  
else if((zc_work_en_1d == 1'b1) && (zc_cnt_1d >= start_n))begin
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
