//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT (“LICENCE?) IS A LEGAL AGREEMENT BETWEEN      //
//YOU AND ARM LIMITED ("ARM") FOR THE USE OF THE SOFTWARE EXAMPLE ACCOMPANYING  //
//THIS LICENCE. ARM IS ONLY WILLING TO LICENSE THE SOFTWARE EXAMPLE TO YOU ON   //
//CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY INSTALLING OR  //
//OTHERWISE USING OR COPYING THE SOFTWARE EXAMPLE YOU INDICATE THAT YOU AGREE   //
//TO BE BOUND BY ALL OF THE TERMS OF THIS LICENCE. IF YOU DO NOT AGREE TO THE   //
//TERMS OF THIS LICENCE, ARM IS UNWILLING TO LICENSE THE SOFTWARE EXAMPLE TO    //
//YOU AND YOU MAY NOT INSTALL, USE OR COPY THE SOFTWARE EXAMPLE.                //
//                                                                              //
//ARM hereby grants to you, subject to the terms and conditions of this Licence,//
//a non-exclusive, worldwide, non-transferable, copyright licence only to       //
//redistribute and use in source and binary forms, with or without modification,//
//for academic purposes provided the following conditions are met:              //
//a) Redistributions of source code must retain the above copyright notice, this//
//list of conditions and the following disclaimer.                              //
//b) Redistributions in binary form must reproduce the above copyright notice,  //
//this list of conditions and the following disclaimer in the documentation     //
//and/or other materials provided with the distribution.                        //
//                                                                              //
//THIS SOFTWARE EXAMPLE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ARM     //
//EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING     //
//WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR //
//PURPOSE, WITH RESPECT TO THIS SOFTWARE EXAMPLE. IN NO EVENT SHALL ARM BE LIABLE/
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES OF ANY/
//KIND WHATSOEVER WITH RESPECT TO THE SOFTWARE EXAMPLE. ARM SHALL NOT BE LIABLE //
//FOR ANY CLAIMS, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, //
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE    //
//EXAMPLE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE EXAMPLE. FOR THE AVOIDANCE/
// OF DOUBT, NO PATENT LICENSES ARE BEING LICENSED UNDER THIS LICENSE AGREEMENT.//
//////////////////////////////////////////////////////////////////////////////////


module AHBTIMER(
	//Inputs
  input wire HCLK,
  input wire HRESETn,
  input wire [31:0] HADDR,
  input wire [31:0] HWDATA,
  input wire [1:0] HTRANS,
  input wire HWRITE,
  input wire HSEL,
  input wire HREADY,
  
	//Output
  output reg [31:0] HRDATA,
  output wire HREADYOUT,
  output reg timer_irq
);

  parameter st_idle = 1'b0,st_count = 1'b1;
  parameter int_gen=2'b00,int_con=2'b01,int_clr=2'b10;
  reg state;
  reg [1:0] state1;
  reg timer_irq_next;

  //AHB Registers
  reg last_HWRITE;
  reg [31:0] last_HADDR;
  reg last_HSEL;
  reg [1:0] last_HTRANS;

  //internal registers
  reg [3:0] control;
  reg [31:0] load;
  reg clear;
  reg [31:0] value;

  //Prescaled clk signals
  wire clk16;            // HCLK/16
  wire clk256;           // HCLK/256
  (*gated_clock="false"*) reg timerclk;
  
   assign HREADYOUT = 1'b1; //Always ready
  
  //Generate prescaled clk16 ticks
  prescaler Inst_precaler_clk16(
  .inclk(HCLK),
  .outclk(clk16)
  ); 
   //Generate prescaled clk16 ticks
  prescaler Inst_precaler_clk256(
  .inclk(clk16),
  .outclk(clk256)
  ); 
   //Prescale clk based on control[3:2] 1x= 256 ; 01 = 16 ; 00 = 1;
  always @(*)
  begin
       case (control[3:2]) 
         2'b00   : timerclk<=HCLK;
         2'b01   : timerclk<=clk16;
         default : timerclk<=clk256;
       endcase
  end 

  always @(posedge HCLK or negedge HRESETn)
  begin
   if(!HRESETn)
      begin
         last_HSEL   <= 1'b0;
         last_HADDR  <= 32'h0;
         last_HTRANS <= 2'b00;
         last_HWRITE <= 1'b0;
      end
    else
     if(HREADY)
      begin
        last_HWRITE <= HWRITE;
        last_HSEL <= HSEL;
        last_HADDR <= HADDR;
        last_HTRANS <= HTRANS;
      end
  end                        
  //wirte Control register
  always @(posedge HCLK or negedge HRESETn)
  begin
    if(!HRESETn)
      begin
        control <= 4'b0000;
        load<=32'h00000000;
        clear<=1'b0;
      end 
    else
     begin 
        if(last_HWRITE & last_HSEL & last_HTRANS[1])
            if(last_HADDR[3:0] == 4'h8)  //control register address
                control <= HWDATA[3:0];
            else if(last_HADDR[3:0] == 4'h0) //load register address
                load <= HWDATA;   
            else if(last_HADDR[3:0] ==4'hc)  //clear register address
                clear <= HWDATA[0];  
     end  
  end 
  //read status register
  always @(*)
  begin
    case(last_HADDR[3:0]) 
      4'h0    :  HRDATA<=load;
      4'h4    :  HRDATA<=value;
      4'h8    :  HRDATA<=control;
      default :  HRDATA<=32'h00000000;
    endcase
  end
  //State Machine    
  always @(posedge timerclk or negedge HRESETn)
  begin
    if(!HRESETn)
     begin
        timer_irq_next<=1'b0;
        value <= 32'h0000_0000;
        state<=st_idle;
     end 
    else
        case(state)
          st_idle:
            if(control[0])
                begin
                  value<= load;
                  state<= st_count;
                end
          st_count:
            if(control[0])                          //if disabled timer stops
                if(value == 32'h0000_0000)
                  begin
                      timer_irq_next =1'b1;
                      if(control[1] == 0)           //If mode=0 timer is free-running counter
                         value<=value-1;
                      else if(control[1] == 1)      //If mode=1 timer is periodic counter;
                         value<=load;
                  end
                else
                  begin
                      value<= value-1;
                      timer_irq_next<=1'b0;
                  end 
        endcase
  end
  always @(posedge HCLK or negedge HRESETn)
  begin
   if(!HRESETn) 
      begin
        timer_irq<=1'b0;
        state1<=int_gen;
      end
   else
    case (state1)
      int_gen:
        begin
           if(timer_irq_next==1'b1)
             begin
               timer_irq<=1'b1;   
               state1<=int_con;
             end 
           else
              state1<=int_gen;
        end 
       int_con:
               state1<=int_clr;
       int_clr:
        begin
            timer_irq<=1'b0;
            if(timer_irq_next==1'b0)
                 state1<=int_gen;
            else
                 state1<=int_clr;
        end
    endcase
  end
        
endmodule
