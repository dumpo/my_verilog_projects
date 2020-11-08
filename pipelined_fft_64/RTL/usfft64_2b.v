/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Top level  of the  high speed FFT  core                    ////
////                                                             ////
////  Authors: Anatoliy Sergienko, Volodya Lepeha                ////
////  Company: Unicore Systems http://unicore.co.ua              ////
////                                                             ////
////  Downloaded from: http://www.opencores.org                  ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2006-2010 Unicore Systems LTD                 ////
//// www.unicore.co.ua                                           ////
//// o.uzenkov@unicore.co.ua                                     ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
//// THIS SOFTWARE IS PROVIDED "AS IS"                           ////
//// AND ANY EXPRESSED OR IMPLIED WARRANTIES,                    ////
//// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED                  ////
//// WARRANTIES OF MERCHANTABILITY, NONINFRINGEMENT              ////
//// AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.        ////
//// IN NO EVENT SHALL THE UNICORE SYSTEMS OR ITS                ////
//// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,            ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL            ////
//// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT         ////
//// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,               ////
//// DATA, OR PROFITS; OR BUSINESS INTERRUPTION)                 ////
//// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,              ////
//// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT              ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING                 ////
//// IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,                 ////
//// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.          ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
// Design_Version       : 1.0
// File name            : 
// File Revision        : 
// Last modification    : Sun Sep 30 20:11:56 2007
/////////////////////////////////////////////////////////////////////
// FUNCTION: Structural model of the high speed 64-complex point FFT 
// PROPERTIES: 
//1.Fully pipelined, 1 complex data in, 1 complex result out each 
//clock cycle
//2. Input data, output data, coefficient widths are adjustable  
//in range 8..16
//3. Normalization stages trigger the data overflow and shift 
//data right to prevent the overflow 	  
//4. Core can contain 2 or 3 data buffers. In the configuration of 
//2 buffers the results are in the shuffled order but provided with 
//the proper address.
//5. The core operation can be slowed down by the control 
//of the ED input
//6. The reset RST is synchronous
/////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
`include "FFT64_CONFIG.inc"	 

module USFFT64_2B ( CLK ,RST ,ED ,START ,SHIFT ,DR ,DI ,RDY ,OVF1 ,OVF2 ,ADDR ,DOR ,DOI );
	`USFFT64paramnb		  	 		//nb is the data bit width

	output RDY ;   			// in the next cycle after RDY=1 the 0-th result is present 
	wire RDY ;
	output OVF1 ;			// 1 signals that an overflow occured in the 1-st stage 
	wire OVF1 ;
	output OVF2 ;			// 1 signals that an overflow occured in the 2-nd stage 
	wire OVF2 ;
	output [5:0] ADDR ;	//result data address/number
	wire [5:0] ADDR ;
	output [nb+2:0] DOR ;//Real part of the output data, 
	wire [nb+2:0] DOR ;	 // the bit width is nb+3, can be decreased when instantiating the core 
	output [nb+2:0] DOI ;//Imaginary part of the output data
	wire [nb+2:0] DOI ;
	
	input CLK ;        			//Clock signal is less than 320 MHz for the Xilinx Virtex5 FPGA        
	wire CLK ;
	input RST ;				//Reset signal, is the synchronous one with respect to CLK
	wire RST ;
	input ED ;					//=1 enables the operation (eneabling CLK)
	wire ED ;
	input START ;  			// its falling edge starts the transform or the serie of transforms  
	wire START ;			 	// and resets the overflow detectors
	input [3:0] SHIFT ;		// bits 1,0 -shift left code in the 1-st stage
	wire [3:0] SHIFT ;	   	// bits 3,2 -shift left code in the 2-nd stage
	input [nb-1:0] DR ;		// Real part of the input data,  0-th data goes just after 
	wire [nb-1:0] DR ;	    // the START signal or after 63-th data of the previous transform
	input [nb-1:0] DI ;		//Imaginary part of the input data
	wire [nb-1:0] DI ;
	
	wire [nb-1:0] dr1,di1;
	wire [nb+1:0] dr3,di3,dr4,di4, dr5,di5 ;
	wire [nb+2:0] dr2,di2;
	wire [nb+4:0] dr6,di6; 	
	wire [nb+2:0] dr7,di7,dr8,di8;   
	wire rdy1,rdy2,rdy3,rdy4,rdy5,rdy6,rdy7,rdy8;			 
	reg [5:0] addri ;
												    // input buffer =8-bit inversion ordering
	BUFRAM64C1 #(nb) U_BUF1(.CLK(CLK), .RST(RST), .ED(ED),	.START(START),
	.DR(DR),	.DI(DI),			.RDY(rdy1),	.DOR(dr1), .DOI(di1));	   
	
	//1-st stage of FFT
	FFT8 #(nb) U_FFT1(.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy1),.DIR(dr1),.DII(di1),
		.RDY(rdy2),	.DOR(dr2),.	DOI(di2));	
	
	wire	[1:0] shiftl=	 SHIFT[1:0]; 
	CNORM #(nb) U_NORM1( .CLK(CLK),	.ED(ED),  //1-st normalization unit
		.START(rdy2),	// overflow detector reset
		.DR(dr2),	.DI(di2),
		.SHIFT(shiftl), //shift left bit number
		.OVF(OVF1),
		.RDY(rdy3),
		.DOR(dr3),.DOI(di3));	
		
	// rotator to the angles proportional to PI/32
	ROTATOR64 U_MPU (.CLK(CLK),.RST(RST),.ED(ED),
		.START(rdy3),. DR(dr3),.DI(di3),
		.RDY(rdy4), .DOR(dr4),	.DOI(di4));
	
	BUFRAM64C1 #(nb+2) U_BUF2(.CLK(CLK),.RST(RST),.ED(ED),	// intermediate buffer =8-bit inversion ordering
		.START(rdy4),. DR(dr4),.DI(di4),
		.RDY(rdy5), .DOR(dr5),	.DOI(di5));	 
	
	//2-nd stage of FFT
	FFT8 #(nb+2) U_FFT2(.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy5),. DIR(dr5),.DII(di5),
		.RDY(rdy6), .DOR(dr6),	.DOI(di6));
	
	wire	[1:0] shifth=	 SHIFT[3:2]; 
	//2-nd normalization unit
	CNORM #(nb+2) U_NORM2 ( .CLK(CLK),	.ED(ED),
		.START(rdy6),	// overflow detector reset
		.DR(dr6),	.DI(di6),
		.SHIFT(shifth), //shift left bit number
		.OVF(OVF2),
		.RDY(rdy7),
		.DOR(dr7),	.DOI(di7));


		BUFRAM64C1  #(nb+3) 	Ubuf3(.CLK(CLK),.RST(RST),.ED(ED),	// intermediate buffer =8-bit inversion ordering
		.START(rdy7),. DR(dr7),.DI(di7),
		.RDY(rdy8), .DOR(dr8),	.DOI(di8));	 	

	

	
	`ifdef USFFT64parambuffers3  	 	// 3-data buffer configuratiion 		   
	always @(posedge CLK)	begin	//POINTER to the result samples
			if (RST)
				addri<=6'b000000;
			else if (rdy8==1 )  
				addri<=6'b000000;
			else if (ED)
				addri<=addri+1; 
		end
	
		assign ADDR=  addri ;
	assign	DOR=dr8;
	assign	DOI=di8;
	assign	RDY=rdy8;	

	`else
	 	always @(posedge CLK)	begin	//POINTER to the result samples
			if (RST)
				addri<=6'b000000;
			else if (rdy7) 
				addri<=6'b000000;
			else if (ED)
				addri<=addri+1; 
		end	  
	assign ADDR=  {addri[2:0] , addri[5:3]} ;
	assign	DOR= dr7;
	assign	DOI= di7;
	assign	RDY= rdy7;	
	`endif	
endmodule
