/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Testbench for the UNFFT64_core - FFT 64 processor          ////
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
// FUNCTION:a set of 4 sine waves is inputted to the FFT processor,
//          the results are compared with the expected waves,
//          the square root mean error is calculated (without a root)
// FILES:   USFFT64_2B_TB.v - this file, contains
//	      USFFT64_2B.v - unit under test
//          sin_tst_rom.v - rom with the test waveform, generating by 
//          sinerom64_gen.pl   
//  PROPERTIES: 1) the calculated error after ca. 4us modeling 
//		is outputted to the console	 as the note:
//   	      rms error is           1 lsb
//		2)if the error is 0,1,2 then the test is OK
//		3) the customer can exchange the test selecting the 
//		different frequencies and generating the wave ROM by
//          the script  sinerom64_gen.pl   		 	
//		4) the proper operation can be checked by investigation
//          of the core output waveforms
/////////////////////////////////////////////////////////////////////
`include "FFT64_CONFIG.inc"	 

`timescale 1ns / 1ps

module Wave_ROM64 ( ADDR ,DATA_RE, DATA_IM, DATA_REF); 
    	output [15:0] DATA_REF ;
		output [15:0] DATA_RE ;
		output [15:0] DATA_IM ;
    	input [5:0]    ADDR ;     
    	reg [15:0] sine[0:63];    
    	initial	  begin    
  sine[0]=16'h0000;  sine[1]=16'h0C8B;  sine[2]=16'h18F8;  sine[3]=16'h2527;
  sine[4]=16'h30FB;  sine[5]=16'h3C56;  sine[6]=16'h471C;  sine[7]=16'h5133;
  sine[8]=16'h5A82;  sine[9]=16'h62F1;  sine[10]=16'h6A6D;  sine[11]=16'h70E2;
  sine[12]=16'h7641;  sine[13]=16'h7A7C;  sine[14]=16'h7D8A;  sine[15]=16'h7F62;
  sine[16]=16'h7FFF;  sine[17]=16'h7F62;  sine[18]=16'h7D8A;  sine[19]=16'h7A7C;
  sine[20]=16'h7641;  sine[21]=16'h70E2;  sine[22]=16'h6A6D;  sine[23]=16'h62F1;
  sine[24]=16'h5A82;  sine[25]=16'h5133;  sine[26]=16'h471C;  sine[27]=16'h3C56;
  sine[28]=16'h30FB;  sine[29]=16'h2527;  sine[30]=16'h18F8;  sine[31]=16'h0C8B;
  sine[32]=16'h0000;  sine[33]=16'hF375;  sine[34]=16'hE708;  sine[35]=16'hDAD9;
  sine[36]=16'hCF05;  sine[37]=16'hC3AA;  sine[38]=16'hB8E4;  sine[39]=16'hAECD;
  sine[40]=16'hA57E;  sine[41]=16'h9D0F;  sine[42]=16'h9593;  sine[43]=16'h8F1E;
  sine[44]=16'h89BF;  sine[45]=16'h8584;  sine[46]=16'h8276;  sine[47]=16'h809E;
  sine[48]=16'h8001;  sine[49]=16'h809E;  sine[50]=16'h8276;  sine[51]=16'h8584;
  sine[52]=16'h89BF;  sine[53]=16'h8F1E;  sine[54]=16'h9593;  sine[55]=16'h9D0F;
  sine[56]=16'hA57E;  sine[57]=16'hAECD;  sine[58]=16'hB8E4;  sine[59]=16'hC3AA;
  sine[60]=16'hCF05;  sine[61]=16'hDAD9;  sine[62]=16'hE708;  sine[63]=16'hF375;
end 

	assign DATA_REF=sine[ADDR];
	assign DATA_RE=sine[ADDR];
	assign DATA_IM=16'h0;
		
endmodule 

module USFFT64_2B_tb;
	//Parameters declaration: 
	//defparam UUT.nb = 12;
	`USFFT64paramnb	
	
	//Internal signals declarations:
	reg CLK;
	reg RST;
	reg ED;
	reg START;
	reg [3:0]SHIFT;
	wire [nb-1:0]DR;
	wire [nb-1:0]DI;
	wire RDY;
	wire OVF1;
	wire OVF2;
	wire [5:0]ADDR;
	wire signed [nb+2:0]DOR;
	wire signed [nb+2:0]DOI;		 
	
	initial 
		begin
			CLK = 1'b0;
			forever #5 CLK = ~CLK;
		end
	initial 
		begin	
			SHIFT = 4'b0000;
			ED = 1'b1;
			RST = 1'b0;
			START = 1'b0;
			#13 RST =1'b1;
			#43 RST =1'b0;
			#53 START =1'b1;
			#12 START =1'b0;
		end	  
	
	reg [5:0] ct64;
	always @(posedge CLK or posedge START) begin
			if (START) ct64 = 6'b000000;
			else ct64 = ct64 + 'd1;
		end
	
	wire [15:0] DATA_RE,DATA_IM,DATA_0;	
	Wave_ROM64 UG( .ADDR(ct64) ,
		.DATA_RE(DATA_RE), .DATA_IM(DATA_IM), .DATA_REF(DATA_0) );// 
	
	assign DR=DATA_RE[15:15-nb+1];
	assign DI=DATA_IM[15:15-nb+1];
	
	// Unit Under Test 
	USFFT64_2B UUT (
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
		
		wire [5:0] addrr;		  
	`ifdef USFFT64paramifft
		assign addrr= (64-ADDR);  //the result order if IFFT 
	`else  
		assign addrr= ADDR;
	`endif
	

		wire signed [15:0] DATA_R0,DATA_I0,DATA_REF;	
	Wave_ROM64 UR( .ADDR(addrr) ,
		.DATA_RE(DATA_R0), .DATA_IM(DATA_I0), .DATA_REF(DATA_REF) );// 
	
	wire signed [18:15-nb+1] DREF=2*DATA_REF[15:15-nb+1];
	
	integer sqra; 
	integer ctres; 
	reg f;				  
	initial f=0;
	always@(posedge CLK) begin 
		if (f) 
			ctres=ctres+1;
			if (RST || RDY)  begin
				if (RDY) f=1;
				sqra=0;
				ctres=0; end
			else if (ctres<64) begin
					#2 sqra = sqra +(DREF-DOR)*(DREF-DOR);
				#2 sqra = sqra +(DOI)*(DOI); end		 
			else if (ctres==64)  
				$display("rms error is ", (sqra/128), " lsb");
		end

	
endmodule
