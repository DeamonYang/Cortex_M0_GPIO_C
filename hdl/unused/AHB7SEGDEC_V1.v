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


module AHB7SEGDEC(
	//AHBLITE INTERFACE
		//Slave Select Signals
			input wire HSEL,
		//Global Signal
			input wire HCLK,
			input wire HRESETn,
		//Address, Control & Write Data
			input wire HREADY,
			input wire [31:0] HADDR,
			input wire [1:0] HTRANS,
			input wire HWRITE,
			input wire [2:0] HSIZE,
			
			input wire [31:0] HWDATA,
		// Transfer Response & Read Data
			output wire HREADYOUT,
			output wire [31:0] HRDATA,
	
	//7segment displa
			output reg [6:0] seg,
			output [7:0] an,
			output dp
  );

//Address Phase Sampling Registers
  reg rHSEL;
  reg [31:0] rHADDR;
  reg [1:0] rHTRANS;
  reg rHWRITE;
  reg [2:0] rHSIZE;


//Address Phase Sampling
  always @(posedge HCLK or negedge HRESETn)
  begin
	 if(!HRESETn)
	 begin
		rHSEL	<= 1'b0;
		rHADDR	<= 32'h0;
		rHTRANS	<= 2'b00;
		rHWRITE	<= 1'b0;
		rHSIZE	<= 3'b000;
	 end
    else 
    begin
      if(HREADY)
        begin
          rHSEL  <= HSEL;
		  rHADDR <= HADDR;
		  rHTRANS<= HTRANS;
		  rHWRITE<= HWRITE;
		  rHSIZE <= HSIZE;
         end
     end
  end

//Data Phase data transfer

  reg [31:0]	DATA;
  always @(posedge HCLK or negedge HRESETn)
  begin
    if(!HRESETn)
      DATA <= 32'h12345678;
    else 
      begin
       if(rHSEL & rHWRITE & rHTRANS[1])
           DATA <= HWDATA[31:0];
       end
  end

//Transfer Response
  assign HREADYOUT = 1'b1; //Single cycle Write & Read. Zero Wait state operations

//Read Data  
  assign HRDATA = DATA;

  reg [15:0] counter;
  reg [7:0] ring = 8'b00000001;
  
  wire [3:0] code;
  wire [6:0] seg_out;
  reg scan_clk;
  assign an =ring;
  assign dp = 1'b1;
  
  always @(posedge HCLK or negedge HRESETn)
  begin
	if(!HRESETn)
	 begin
		counter <= 16'h0000;
		scan_clk<=1'b0;
     end
	else
	 begin
		if(counter==16'h7000)
		   begin
		    scan_clk<=~scan_clk;
		    counter<=16'h0000;
		   end 
		else
		  counter <= counter + 1'b1;
     end 
  end

  always @(posedge scan_clk or negedge HRESETn)
  begin
	if(!HRESETn)
		ring <= 8'b00000001;
	else
		ring <= {ring[6:0],ring[7]};
  end

  assign code =
	(ring == 8'b00000001) ? DATA[3:0] :
	(ring == 8'b00000010) ? DATA[7:4] :
	(ring == 8'b00000100) ? DATA[11:8] :
	(ring == 8'b00001000) ? DATA[15:12] :
	(ring == 8'b00010000) ? DATA[19:16]:
	(ring == 8'b00100000) ? DATA[23:20]:
	(ring == 8'b01000000) ? DATA [27:24]:
	(ring == 8'b10000000) ? DATA [31:28]:
    8'b1111110;
		
always @(*)
case (code)  //a-b-c-d-e-f-g
  4'b0000  :  seg=7'b00000001;  //0
  4'b0001  :  seg=7'b1001111;   //1
  4'b0010  :  seg=7'b0010010;   //2
  4'b0011  :  seg=7'b0000110;   //3
  4'b0100  :  seg=7'b1001100;   //4
  4'b0101  :  seg=7'b0100100;   //5
  4'b0110  :  seg=7'b0100000;   //6
  4'b0111  :  seg=7'b0001111;   //7
  4'b1000  :  seg=7'b0000000;   //8
  4'b1001  :  seg=7'b0000100;   //9
  4'b1010  :  seg=7'b0001000;   //A
  4'b1011  :  seg=7'b1100000;   //B
  4'b1100  :  seg=7'b0110001;   //C
  4'b1101  :  seg=7'b1000010;   //D
  4'b1110  :  seg=7'b0110000;   //E
  4'b1111  :  seg=7'b0111000;   //F
  default  :  seg=7'b1111111;   //no display
 endcase
endmodule
