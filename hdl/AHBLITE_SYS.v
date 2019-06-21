//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT (�LICENCE?) IS A LEGAL AGREEMENT BETWEEN      //
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


module AHBLITE_SYS(
	//CLOCKS & RESET
	input		wire				clk,
	input		wire				rst_n, 
	
	input		wire				rx,
	output		wire				tx,
	
	input		wire	[3:1]		key,
	//TO BOARD LEDs
	output    	wire	[3:0]    	led
	
//	input		wire				btn,
//	output      wire   [6:0]       seg,
//	output      wire   [7:0]       an,
//	output      wire               dp,
   
	
//	output      wire               hs,
//	output      wire               vs,
//	output      wire  [11:0]       rgb
);
 
//AHB-LITE SIGNALS 
//Gloal Signals
wire 				HCLK	=	clk		;
wire 				HRESETn	=	rst_n	;
wire	[15:0]		PORTOUT;
wire	[15:0]		PORTIN;
//led output port

assign				led		=	PORTOUT[3:0];
assign				PORTIN	=	{12'b0,key,1'b1};

//Address, Control & Write Data Signals
wire [31:0]		    HADDR;
wire [31:0]		    HWDATA;
wire 				HWRITE;
wire [1:0] 		    HTRANS;
wire [2:0] 		    HBURST;
wire 				HMASTLOCK;
wire [3:0] 		    HPROT;
wire [2:0] 		    HSIZE;
//Transfer Response & Read Data Signals
wire [31:0] 	    HRDATA;
wire 				HRESP;
wire 				HREADY;


//SELECT SIGNALS
wire [3:0] 		    MUX_SEL;

// HSEL SIGNALS
wire				HSEL_MEM;
wire				HSEL_LED;
wire				HSEL_GPIO;
wire				HSEL_UART;

//SLAVE READ DATA
wire [31:0]			HRDATA_MEM;
wire [31:0]			HRDATA_LED;
wire [31:0]			HRDATA_GPIO;
wire [31:0]			HRDATA_UART;

//SLAVE HREADYOUT
wire				HREADYOUT_MEM;
wire				HREADYOUT_LED;
wire				HREADYOUT_GPIO;
wire				HREADYOUT_UART;

//CM0-DS Sideband signals
wire 				LOCKUP;
wire 				TXEV;
wire 				SLEEPING;
wire [15:0]		    IRQ;

wire               Int;
wire               Int_timer;
wire               Int_uart;

wire               LOCK;
//SYSTEM GENERATES NO ERROR RESPONSE
assign 			HRESP = 1'b0;

//CM0-DS INTERRUPT SIGNALS  
assign 			IRQ = {13'b0000_0000_0000_0,Int_uart,Int_timer,Int};
//assign 			LED[7] = LOCKUP;

 
CORTEXM0DS u_cortexm0ds (
	//Global Signals
	.HCLK        	(	HCLK				),
	.HRESETn     	(	HRESETn				),
	//Address, Control & Write Data	
	.HADDR       	(	HADDR[31:0]			),
	.HBURST      	(	HBURST[2:0]			),
	.HMASTLOCK   	(	HMASTLOCK			),
	.HPROT       	(	HPROT[3:0]			),
	.HSIZE			(	HSIZE[2:0]			),
	.HTRANS			(	HTRANS[1:0]			),
	.HWDATA      	(	HWDATA[31:0]		),
	.HWRITE      	(	HWRITE				),
	//Transfer Response & Read Data	
	.HRDATA			(	HRDATA[31:0]		),			
	.HREADY			(	HREADY				),					
	.HRESP       	(	HRESP				),					

	//CM0 Sideband Signals
	.NMI         	(	1'b0				),
	.IRQ         	(	IRQ[15:0]			),
	.TXEV        	(						),
	.RXEV        	(	1'b0				),
	.LOCKUP			(	LOCKUP				),
	.SYSRESETREQ 	(						),
	.SLEEPING    	(						)
);

//Address Decoder 

AHBDCD uAHBDCD (
	.HADDR			(	HADDR[31:0]			),
	 
	.HSEL_S0		(	HSEL_MEM			),
	.HSEL_S1		(	HSEL_LED			),
	.HSEL_S2		(	HSEL_GPIO			),
	.HSEL_S3		(						),
	.HSEL_S4		(	HSEL_UART			),
	.HSEL_S5		(						),
	.HSEL_S6		(						),
	.HSEL_S7		(						),
	.HSEL_S8		(						),
	.HSEL_S9		(						),
	.HSEL_NOMAP		(	HSEL_NOMAP			),
			
	.MUX_SEL		(	MUX_SEL[3:0]		)
);

//Slave to Master Mulitplexor

AHBMUX uAHBMUX 
(
	.HCLK			(	HCLK				),
	.HRESETn		(	HRESETn				),
	.MUX_SEL		(	MUX_SEL[3:0]		),
	 
	.HRDATA_S0		(	HRDATA_MEM			),
	.HRDATA_S1		(	HRDATA_LED			),
	.HRDATA_S2		(	HRDATA_GPIO			),
	.HRDATA_S3		(						),
	.HRDATA_S4		(	HRDATA_UART			),
	.HRDATA_S5		(						),
	.HRDATA_S6		(						),
	.HRDATA_S7		(						),
	.HRDATA_S8		(						),
	.HRDATA_S9		(						),
	.HRDATA_NOMAP	(	32'hDEADBEEF		),
	 
	.HREADYOUT_S0	(	HREADYOUT_MEM		),
	.HREADYOUT_S1	(	HREADYOUT_LED		),
	.HREADYOUT_S2	(	HREADYOUT_GPIO		),
	.HREADYOUT_S3	(	1'b1				),
	.HREADYOUT_S4	(	HREADYOUT_UART		),
	.HREADYOUT_S5	(	1'b1				),
	.HREADYOUT_S6	(	1'b1				),
	.HREADYOUT_S7	(	1'b1				),
	.HREADYOUT_S8	(	1'b1				),
	.HREADYOUT_S9	(	1'b1				),
	.HREADYOUT_NOMAP(	1'b1				),
    
	.HRDATA			(	HRDATA[31:0]		),
	.HREADY			(	HREADY				)
);

// AHBLite Peripherals

//AHBLite Slave 
AHB2MEM uAHB2MEM 
(
	//AHBLITE Signals
	.HSEL			(	HSEL_MEM			),
	.HCLK			(	HCLK				), 
	.HRESETn		(	HRESETn				), 
	.HREADY			(	HREADY				),     
	.HADDR			(	HADDR				),
	.HTRANS			(	HTRANS[1:0]			), 
	.HWRITE			(	HWRITE				),
	.HSIZE			(	HSIZE				),
	.HWDATA			(	HWDATA[31:0]		), 
		
	.HRDATA			(	HRDATA_MEM			), 
	.HREADYOUT		(	HREADYOUT_MEM		)
	//Sideband Signals
	
);
/********************************************************************
//AHBLite Slave 
AHB2LED uAHB2LED 
(
	//AHBLITE Signals
	.HSEL			(	HSEL_LED			),
	.HCLK			(	HCLK				), 
	.HRESETn		(	HRESETn				), 
	.HREADY			(	HREADY				),     
	.HADDR			(	HADDR				),
	.HTRANS			(	HTRANS[1:0]			), 
	.HWRITE			(	HWRITE				),
	.HSIZE			(	HSIZE				),
	.HWDATA			(	HWDATA[31:0]		), 
		
	.HRDATA			(	HRDATA_LED			), 
	.HREADYOUT		(	HREADYOUT_LED		),
	//Sideband Signals
	.LED			(						)
);

********************************************************************/

//AHBLite Slave GPIO
cmsdk_ahb_gpio ucmsdk_ahb_gpio
(// AHB Inputs
	.HCLK			(	HCLK				),      // system bus clock
	.HRESETn		(	HRESETn				),   	// system bus reset
	.FCLK			(	HCLK				),      // system bus clock
	.HSEL			(	HSEL_GPIO			),      // AHB peripheral select
	.HREADY			(	HREADY				),    	// AHB ready input
	.HTRANS			(	HTRANS[1:0]			),    	// AHB transfer type
	.HSIZE			(	HSIZE				),     	// AHB hsize
	.HWRITE			(	HWRITE				),    	// AHB hwrite
	.HADDR			(	HADDR				),     	// AHB address bus
	.HWDATA			(	HWDATA[31:0]		),    	// AHB write data bus

	.ECOREVNUM		(						),  // Engineering-change-order revision bits

	.PORTIN			(	PORTIN				),     // GPIO Interface input

	.HREADYOUT		(	HREADYOUT_GPIO		), // AHB ready output to S->M mux
	.HRESP			(						),     // AHB response
	.HRDATA			(	HRDATA_GPIO			),

	.PORTOUT		(	PORTOUT				),    // GPIO output
	.PORTEN			(						),     // GPIO output enable
	.PORTFUNC		(						),   // Alternate function control

	.GPIOINT		(						),    // Interrupt output for each pin
	.COMBINT		(						)		 // Combined interrupt
	
);  

	
//AHBLite Slave UART
AHBUART Inst_AHBUART(
      .HCLK			(	HCLK				),
      .HRESETn		(	HRESETn				),
      .HADDR		(	HADDR				),
      .HTRANS		(	HTRANS				),
      .HWDATA		(	HWDATA				),
      .HWRITE		(	HWRITE				),
      .HREADY		(	HREADY				),
      .HREADYOUT	(	HREADYOUT_UART		),
      .HRDATA		(	HRDATA_UART			),
      .HSEL			(	HSEL_UART			),
      .RsRx			(	rx					), 
      .RsTx			(	tx					), 
      .uart_irq		(	Int_uart			)
  );
  

  
endmodule
