`include "FFT64_CONFIG.inc"	


module pipelined_fft_64(CLK ,RST ,ED ,START ,SHIFT ,DR ,DI ,RDY ,OVF1 ,OVF2 ,ADDR ,DOR ,DOI);

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
	
USFFT64_2B fft (
		.CLK(CLK),
		.RST(RST),
		.ED(ED),
		.START(START),
		.SHIFT(SHIFT),
		.DR(DR),
		.DI(DI),
		.RDY(RDY),
		.OVF1(OVF1),
		.OVF2(OVF2),
		.ADDR(ADDR),
		.DOR(DOR),
		.DOI(DOI));
endmodule
 