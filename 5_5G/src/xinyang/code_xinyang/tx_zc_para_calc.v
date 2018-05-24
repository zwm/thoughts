////////////////////////////////////////
// project name : 5G-NR
// module name  : tx_zc_para_calc
// file name    : 
// autor        :
// version      :
////////////////////////////////////////

module tx_zc_para_calc(
    //system clk and reset
    sys_clk               ,
    rst_n                 ,
    
    //configure signal  
    u                     ,
    v                     ,
    alpha                 ,
    zc_N_zc               ,
    
    //control signal   
    start                 ,
    
    //out signal   
    busy                  ,
    done                  ,
    zc_Q                  , //mod(12q,2*12*Nzc)        
    zc_P                    //mod(2*a*Nzc,2*12*Nzc)    
    );
    
//parameter declear                                                                           
parameter                     DATA_WIDTH       = 12;                                      
                                                                                          
//input and output signal declear                                                         
input                         sys_clk          ;                                          
input                         rst_n            ;                                          
                                                                                          
//configure signal                                                                           
input    [5 -1:0]             u                ; 
input                         v                ;  
input    [5 -1:0]             alpha            ;                                          
input    [11-1:0]             zc_N_zc          ; //R11U0

//control signal  
input                         start            ;                                                            
                                                                                          
//out signal    
output                        busy             ; 
output                        done             ;   
output   [15-1:0]             zc_Q             ; //mod(12q,2*12*Nzc)                                                                  
output   [16-1:0]             zc_P             ; //mod(2*a*Nzc,2*12*Nzc)                                      
                                                                                          
//-------------------------------------------------------------------------------------   
//--------------                        q calation                       --------------   
//-------------------------------------------------------------------------------------  

//Nzc*(u+1)
reg                           mul_u1_Nzc_A_work_en;
//always@(*)
if((start == 1'b1) && (zc_N_zc > 30))begin
    mul_u1_Nzc_A_work_en      = 1'b1;
end
else begin
    mul_u1_Nzc_A_work_en      = 1'b0;
end

wire    [17-1:0]              mul_u1_Nzc_A = $unsigned(u);
wire    [17-1:0]              mul_u1_Nzc_B = $unsigned(zc_N_zc);

wire    [34-1:0]              mul_u1_Nzc_C;

wire    [16-1:0]              u_add_1_mul_Nzc = mul_u1_Nzc_C[16-1:0]; //R16U0

reg                           u_add_1_mul_Nzc_valid; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    u_add_1_mul_Nzc_valid     <= 'h0;
end    
else begin
    u_add_1_mul_Nzc_valid     <= mul_u1_Nzc_A_work_en;
end 


//2Nzc*(u+1)
wire    [17-1:0]              q_scale = {u_add_1_mul_Nzc,1'b0};  //R17U0


///2Nzc*(u+1)/31
wire                          mul_v_scale_work_en = u_add_1_mul_Nzc_valid;
wire    [17-1:0]              mul_v_scale_A = $unsigned(q_scale);  //R17U0   
wire    [17-1:0]              mul_v_scale_B = 17'd67850; //R17U21  

wire    [34-1:0]              mul_v_scale_C; //R34U21   

//floor(2Nzc*(u+1)/31)
wire                          v_scale_mod_2_out = mul_v_scale_C[21];  

reg                           mul_v_scale_out_en; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    mul_v_scale_out_en        <= 'h0;
end    
else begin
    mul_v_scale_out_en        <= mul_v_scale_work_en;
end 

//v*(-1)^floor(2Nzc*(u+1)/31)
reg                           delt_v_flag; 
always@(posedge sys_clk)
if(mul_v_scale_out_en == 1'b1)begin
    delt_v_flag               <= v_scale_mod_2_out; //1 -> -1,0 -> 1
end 

//(2Nzc*(u+1)+31)/62
wire                          mul_u_scale_work_en = mul_v_scale_out_en;
wire    [17-1:0]              mul_u_scale_A = q_scale + 17'd31;  //R17U0   
wire    [17-1:0]              mul_u_scale_B = 17'd33825; //R17U21  

wire    [34-1:0]              mul_u_scale_C; //R34U21  

reg                           mul_u_scale_out_en; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    mul_u_scale_out_en        <= 'h0;
end    
else begin
    mul_u_scale_out_en        <= mul_u_scale_work_en;
end  

//floor((2Nzc*(u+1)+31)/62)                                                
wire    [11-1:0]              floor_u_scale = mul_u_scale_C[32-1:21]; //R11U0  

//q = floor((2Nzc*(u+1)+31)/62) + v*(-1)^floor(2Nzc*(u+1)/31) 
reg     [11-1:0]              q_temp;
//always@(*)
if(delt_v_flag == 1'b1)begin
    q_temp                    = floor_u_scale - 1'b1;
end
else begin
    q_temp                    = floor_u_scale + 1'b1;
end

reg     [11-1:0]              q;
always@(posedge sys_clk)
if(zc_N_zc > 30)begin
    if(mul_u_scale_out_en == 1'b1)begin
        q                     <= q_temp; 
    end
end
else begin
    q                         <= u + 1'b1;
end 

reg                           q_valid; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    q_valid                   <= 'h0;
end    
else if(zc_N_zc > 30)begin
    q_valid                   <= mul_u_scale_out_en;
end  
else begin
    q_valid                   <= start;
end  


//-------------------------------------------------------------------------------------   
//--------------                  mod(12q,2*12*Nzc)                      --------------   
//-------------------------------------------------------------------------------------  
//mod(12q,2*12*Nzc)
wire     [15-1:0]             q_mul_12_out = {q,2'b0} + {q,3'b0};   
wire     [16-1:0]             Nzc_mul_24_out = {zc_N_zc,4'b0} + {zc_N_zc,3'b0}; 
reg      [16-1:0]             mod_q; 
 
//always@(*)
if(Nzc_mul_24_out > {1'b0,q_mul_12_out})begin   
    mod_q                     = Nzc_mul_24_out - {1'b0,q_mul_12_out};
end
else begin
    mod_q                     = {1'b0,q_mul_12_out};
end

reg      [15-1:0]             zc_Q;  
always@(posedge sys_clk)
if(q_valid == 1'b1)begin
    zc_Q                      <= mod_q[15-1:0]; 
end 


//mod(2*a*Nzc,2*12*Nzc)                                                                 
reg     [16-1:0]              zc_P;   

wire                          mul_a_Nzc_work_en = q_valid;
wire    [17-1:0]              mul_a_Nzc_A = $unsigned({alpha,1'b1}); //R5U0   
wire    [17-1:0]              mul_a_Nzc_B = $unsigned(zc_N_zc); //R11U0  

wire    [34-1:0]              mul_a_Nzc_C; //R16U0
wire    [16-1:0]              mul_a_Nzc_out = mul_a_Nzc_C[16-1:0];

reg                           mul_a_Nzc_out_en; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    mul_a_Nzc_out_en          <= 'h0;
end    
else begin
    mul_a_Nzc_out_en          <= mul_a_Nzc_work_en;
end  

reg      [16-1:0]             mod_p; 
 
//always@(*)
if(Nzc_mul_24_out > mul_a_Nzc_out)begin   
    mod_p                     = Nzc_mul_24_out - mul_a_Nzc_out;
end
else begin
    mod_p                     = mul_a_Nzc_out;
end

reg      [16-1:0]             zc_P;  
always@(posedge sys_clk)
if(mul_a_Nzc_out_en == 1'b1)begin
    zc_P                      <= mod_p; 
end 


reg                           done; 
always@(posedge sys_clk or negedge rst_n)
if(~rst_n)begin
    done                      <= 'h0;
end    
else begin
    done                      <= mul_a_Nzc_out_en;
end 

endmodule 
