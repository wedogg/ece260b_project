// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

`timescale 1ns/1ps

module fullchip_tb;

parameter total_cycle = 8;   // how many streamed Q vectors will be processed
parameter bw = 8;            // Q & K vector bit precision
parameter bw_psum = 2*bw+4;  // partial sum bit precision
parameter pr = 16;           // how many products added in each dot product 
parameter col = 8;           // how many dot product units are equipped

integer qk_file ; // file handler
integer qk_scan_file ; // file handler


integer  captured_data;
integer  weight [col*pr-1:0];
`define NULL 0




integer  K[col-1:0][pr-1:0];
integer  Q[total_cycle-1:0][pr-1:0];
integer  result[total_cycle-1:0][col-1:0];
integer  sum[total_cycle-1:0];
integer  summation[total_cycle-1:0];//
integer  division[total_cycle-1:0][col-1:0];//

integer i,j,k,t,p,q,s,u, m;





reg reset = 1;
reg clk = 0;
reg [pr*bw-1:0] mem_in; 
reg start = 0;



reg [bw_psum-1:0] temp5b;
reg [bw_psum+3:0] temp_sum;
reg [bw_psum*col-1:0] temp16b;
reg [bw_psum+3:0] temp6h;
reg [bw_psum-1:0] temp5h;//
reg [bw_psum*col-1:0] temp40h;//


fullchip #(.bw(bw)) fullchip_inst (
	.clk(clk),
	.reset(reset),
	.start(start),
	.mem_in(mem_in)
);


initial begin 

  $dumpfile("fullchip_tb.vcd");
  $dumpvars(0,fullchip_tb);



///// Q data txt reading /////

$display("##### Q data txt reading #####");


  qk_file = $fopen("qdata.txt", "r");

  //// To get rid of first 3 lines in data file ////
  qk_scan_file = $fscanf(qk_file, "%s\n", captured_data);
  qk_scan_file = $fscanf(qk_file, "%s\n", captured_data);
  qk_scan_file = $fscanf(qk_file, "%s\n", captured_data);
  qk_scan_file = $fscanf(qk_file, "%s\n", captured_data);


  for (q=0; q<total_cycle; q=q+1) begin
    for (j=0; j<pr; j=j+1) begin
          qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
          Q[q][j] = captured_data;
          //$display("%d\n", K[q][j]);
    end
  end
/////////////////////////////////




  for (q=0; q<2; q=q+1) begin
    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   
  end




///// K data txt reading /////

$display("##### K data txt reading #####");

  for (q=0; q<10; q=q+1) begin
    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   
  end

  qk_file = $fopen("kdata.txt", "r");

  //// To get rid of first 4 lines in data file ////
  qk_scan_file = $fscanf(qk_file, "%s\n", captured_data);
  qk_scan_file = $fscanf(qk_file, "%s\n", captured_data);
  qk_scan_file = $fscanf(qk_file, "%s\n", captured_data);
  qk_scan_file = $fscanf(qk_file, "%s\n", captured_data);




  for (q=0; q<col; q=q+1) begin
    for (j=0; j<pr; j=j+1) begin
          qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
          K[q][j] = captured_data;
          //$display("##### %d\n", K[q][j]);
    end
  end
/////////////////////////////////








/////////////// Estimated result printing /////////////////


$display("##### Estimated multiplication result #####");

  for (t=0; t<total_cycle; t=t+1) begin
     for (q=0; q<col; q=q+1) begin
       result[t][q] = 0;
     end
  end

  for (t=0; t<total_cycle; t=t+1) begin
     for (q=0; q<col; q=q+1) begin
         for (k=0; k<pr; k=k+1) begin
            result[t][q] = result[t][q] + Q[t][k] * K[q][k];
         end

         temp5b = result[t][q];
         temp16b = {temp16b[139:0], temp5b};
     end

     //$display("%d %d %d %d %d %d %d %d", result[t][0], result[t][1], result[t][2], result[t][3], result[t][4], result[t][5], result[t][6], result[t][7]);
     $display("prd @cycle%2d: %40h", t, temp16b);
  end
 
  for (t=0; t<total_cycle; t=t+1) begin
    summation[t] = 0;
  end    
  for (t=0; t<total_cycle; t=t+1) begin
    for (q=0; q<col; q=q+1) begin
      if (result[t][q] >= 0) begin
        summation[t] = summation[t] + result[t][q];//
      end
      else begin
	summation[t] = summation[t] - result[t][q];//
      end
    end
    
    temp6h = summation[t]; 
    $display("prd @cycle%2d: %6h", t, temp6h);
  end

  for (t=0; t<total_cycle; t=t+1) begin
    for (q=0; q<col; q=q+1) begin
      division[t][q] = result[t][q] * 128 / (summation[t]);

      temp5h = division[t][q];
      temp40h = {temp40h[139:0], temp5h};
    end

    $display("prd @cycle%2d: %40h", t, temp40h);
  end

//////////////////////////////////////////////
  #0.5 clk = 1'b0;
  reset = 0;
  #0.5 clk = 1'b1;
  #0.5 clk = 1'b0;
  #0.5 clk = 1'b1;

  #0.5 clk = 1'b0;
  start = 1;
  #0.5 clk = 1'b1;

  for (q=0; q<total_cycle; q=q+1) begin

    #0.5 clk = 1'b0;  
    mem_in[1*bw-1:0*bw] = Q[q][0];
    mem_in[2*bw-1:1*bw] = Q[q][1];
    mem_in[3*bw-1:2*bw] = Q[q][2];
    mem_in[4*bw-1:3*bw] = Q[q][3];
    mem_in[5*bw-1:4*bw] = Q[q][4];
    mem_in[6*bw-1:5*bw] = Q[q][5];
    mem_in[7*bw-1:6*bw] = Q[q][6];
    mem_in[8*bw-1:7*bw] = Q[q][7];
    mem_in[9*bw-1:8*bw] = Q[q][8];
    mem_in[10*bw-1:9*bw] = Q[q][9];
    mem_in[11*bw-1:10*bw] = Q[q][10];
    mem_in[12*bw-1:11*bw] = Q[q][11];
    mem_in[13*bw-1:12*bw] = Q[q][12];
    mem_in[14*bw-1:13*bw] = Q[q][13];
    mem_in[15*bw-1:14*bw] = Q[q][14];
    mem_in[16*bw-1:15*bw] = Q[q][15];

    #0.5 clk = 1'b1;  

  end


  #0.5 clk = 1'b0;  
  #0.5 clk = 1'b1;  
///////////////////////////////////////////





///// Kmem writing  /////


  for (q=0; q<col; q=q+1) begin

    #0.5 clk = 1'b0;  
    mem_in[1*bw-1:0*bw] = K[q][0];
    mem_in[2*bw-1:1*bw] = K[q][1];
    mem_in[3*bw-1:2*bw] = K[q][2];
    mem_in[4*bw-1:3*bw] = K[q][3];
    mem_in[5*bw-1:4*bw] = K[q][4];
    mem_in[6*bw-1:5*bw] = K[q][5];
    mem_in[7*bw-1:6*bw] = K[q][6];
    mem_in[8*bw-1:7*bw] = K[q][7];
    mem_in[9*bw-1:8*bw] = K[q][8];
    mem_in[10*bw-1:9*bw] = K[q][9];
    mem_in[11*bw-1:10*bw] = K[q][10];
    mem_in[12*bw-1:11*bw] = K[q][11];
    mem_in[13*bw-1:12*bw] = K[q][12];
    mem_in[14*bw-1:13*bw] = K[q][13];
    mem_in[15*bw-1:14*bw] = K[q][14];
    mem_in[16*bw-1:15*bw] = K[q][15];

    #0.5 clk = 1'b1;  

  end

  #0.5 clk = 1'b0;  
  #0.5 clk = 1'b1;  
///////////////////////////////////////////


  for (q=0; q<111; q=q+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;
  end


#10 $finish;

end
endmodule

