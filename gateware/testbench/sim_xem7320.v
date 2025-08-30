`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2023 02:07:23 PM
// Design Name: 
// Module Name: sim_xem7320_system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`default_nettype none

module sim_xem7320;

   wire [4:0] okUH;
   wire [2:0] okHU;
   wire [31:0] okUHU;
   wire okAA;
   wire [7:0] led;


    reg sys_clkp;
    reg sys_clkn;
    reg [1:0] adc_out_1p;
    reg [1:0] adc_out_1n;
    reg [1:0] adc_out_2p;
    reg [1:0] adc_out_2n;
    reg adc_dco_p;
    reg adc_dco_n;
    reg adc_fr_p;
    reg adc_fr_n;
    wire adc_encode_p;
    wire adc_encode_n;
    wire adc_sdo;
    wire adc_sdi;
    wire adc_cs_n;
    wire adc_sck;
    wire OEN;
   wire REN;
   wire SEL0;
   wire NEG0;
   wire POS0;
   wire MODE;
   wire PWS;
   wire dac_clk;
   wire [7:0] m_dbg_signal;

   xem7320_adc uut (
      // Connect input and output ports of the DUT (xem7320_adc)
      .okUH(okUH),
      .okHU(okHU),
      .okUHU(okUHU),
      .okAA(okAA),
      .sys_clkp(sys_clkp),
      .sys_clkn(sys_clkn),
      .adc_out_1p(adc_out_1p),
      .adc_out_1n(adc_out_1n),
      .adc_out_2p(adc_out_2p),
      .adc_out_2n(adc_out_2n),
      .adc_dco_p(adc_dco_p),
      .adc_dco_n(adc_dco_n),
      .adc_fr_p(adc_fr_p),
      .adc_fr_n(adc_fr_n),
      .adc_encode_p(adc_encode_p),
      .adc_encode_n(adc_encode_n),
      .adc_sdo(adc_sdo),
      .adc_sdi(adc_sdi),
      .adc_cs_n(adc_cs_n),
      .led(led),
      .adc_sck(adc_sck),
      .OEN(OEN),
      .REN(REN),
      .SEL0(SEL0),
      .NEG0(NEG0),
      .POS0(POS0),
      .MODE(MODE),
      .PWS(PWS)
   
      //.m_dbg_signal(m_dbg_signal)
     );
     
   //------------------------------------------------------------------------
   // Begin okHostInterface simulation user configurable global data
   //------------------------------------------------------------------------
   parameter BlockDelayStates = 5; // REQUIRED: # of clocks between blocks of pipe data
   parameter ReadyCheckDelay = 5; // REQUIRED: # of clocks before block transfer before
                                     // host interface checks for ready (0-255)
   parameter PostReadyDelay = 5; // REQUIRED: # of clocks after ready is asserted and
                                     // check that the block transfer begins (0-255)
   parameter pipeInSize = 128; // REQUIRED: byte (must be even) length of default
                                     // PipeIn; Integer 0-2^32
   parameter pipeOutSize = 16; // REQUIRED: byte (must be even) length of default
                                     // PipeOut; Integer 0-2^32
   parameter registerSetSize = 32; // Size of array for register set commands.

   parameter Tsys_clk = 5; // 100Mhz
   //-------------------------------------------------------------------------

    // Pipes
   integer k;
   reg [7:0] pipeIn [0:(pipeInSize-1)];
   initial for (k=0; k<pipeInSize; k=k+1) pipeIn[k] = 8'h00;

   reg [7:0] pipeOut [0:(pipeOutSize-1)];
   initial for (k=0; k<pipeOutSize; k=k+1) pipeOut[k] = 8'h00;

   // Registers
   reg [31:0] u32Address [0:(registerSetSize-1)];
   reg [31:0] u32Data [0:(registerSetSize-1)];
   reg [31:0] u32Count;
   
   //------------------------------------------------------------------------
   // Available User Task and Function Calls:
   // FrontPanelReset; // Always start routine with FrontPanelReset;
   // SetWireInValue(ep, val, mask);
   // UpdateWireIns;
   // UpdateWireOuts;
   // GetWireOutValue(ep);
   // ActivateTriggerIn(ep, bit); // bit is an integer 0-15
   // UpdateTriggerOuts;
   // IsTriggered(ep, mask); // Returns a 1 or 0
   // WriteToPipeIn(ep, length); // passes pipeIn array data
   // ReadFromPipeOut(ep, length); // passes data to pipeOut array
   // WriteToBlockPipeIn(ep, blockSize, length); // pass pipeIn array data; blockSize and length are integers
   // ReadFromBlockPipeOut(ep, blockSize, length); // pass data to pipeOut array; blockSize and length are integers
   // WriteRegister(address, data);
   // ReadRegister(address, data);
   // WriteRegisterSet; // writes all values in u32Data to the addresses in u32Address
   // ReadRegisterSet; // reads all values in the addresses in u32Address to the array u32Data
   //
   // *Pipes operate by passing arrays of data back and forth to the user's
   // design. If you need multiple arrays, you can create a new procedure
   // above and connect it to a differnet array. More information is
   // available in Opal Kelly documentation and online support tutorial.
   //------------------------------------------------------------------------
   
   wire [31:0] NO_MASK = 32'hffff_ffff;
   
   // LFSR/Counter modes
   wire [15:0] MODE_LFSR = 2'b00; // Will set 0th bit
   wire [15:0] MODE_COUNTER = 2'b01; // Will set 1st bit

   // Off/Continuous/Piped modes for LFSR/Counter
   wire [15:0] MODE_OFF = 2'b10; // Will set 2nd bit
   wire [15:0] MODE_CONTINUOUS = 2'b11; // Will set 3rd bit
   wire [15:0] MODE_PIPED = 3'b100; // Will set 4th bit

   // Variables
   integer i, j;
   reg [31:0] ep01value;
   reg [31:0] ep20value;
   reg [31:0] ep03data; //pulser ON
   reg [31:0] ep04data;
   reg [31:0] ep05data;
   reg [31:0] ep40trig;
   
   reg [31:0] mode;
   reg [7 :0] ReadPipe [0:(pipeOutSize-1)];
   reg [31:0] RegOutData [0:(registerSetSize-1)];
   reg [31:0] RegInData [0:(registerSetSize-1)];
   reg [31:0] RegAddresses [0:(registerSetSize-1)];
   integer rand_error;
   reg trig_error = 1'b0;
   reg [31:0] errorSim = 32'h0000_0000;

   initial for (k=0; k<pipeOutSize; k=k+1) ReadPipe[k] = 8'h00;
   initial for (k=0; k<registerSetSize; k=k+1) begin
      RegOutData[k] = 32'h0000_0000;
      RegInData[k] = 32'h0000_0000;
      RegAddresses[k] = 32'h0000_0000;
   end

   // sys_clkp, sys_clkn 200 MHz clock generation
   initial begin 
      sys_clkp = 0;
      sys_clkn = 1;
      forever #2.5 begin
           // Toggle the positive and negative phases of the clock every 5 time units
           sys_clkp = ~sys_clkp;
           sys_clkn = ~sys_clkn;
      end
   end
   
   // DCO generation
   parameter tSER = 3.125; // 40 Mhz (25ns) -> 8 periods (Two Lanes, 16-bit Serialization)
   parameter tPD = 2*tSER+1.1; // tPD - Propagation Delay : 1.1n + 2tSER 
   parameter tFrame = 0.5*tSER;
   reg adc_dco_p_tmp;
   reg adc_dco_n_tmp;
   
   
   always @(posedge adc_encode_p or negedge adc_encode_p) begin
   
      #tPD;
      adc_fr_p = adc_encode_p;
      adc_fr_n = adc_encode_n;
   
   end
   
   always @(posedge adc_fr_p or negedge adc_fr_p) begin
   
      adc_dco_p_tmp = 1'b1;
      adc_dco_n_tmp = 1'b0;
      
      #tSER;
      adc_dco_p_tmp = ~adc_dco_p_tmp;
      adc_dco_n_tmp = ~adc_dco_n_tmp;
      
      #tSER;
      adc_dco_p_tmp = ~adc_dco_p_tmp;
      adc_dco_n_tmp = ~adc_dco_n_tmp;
      
      #tSER;
      adc_dco_p_tmp = ~adc_dco_p_tmp;
      adc_dco_n_tmp = ~adc_dco_n_tmp;
      
   end
   
   
   always @(posedge adc_dco_p_tmp or negedge adc_dco_p_tmp) begin
   
      #tFrame;
      adc_dco_p = adc_dco_p_tmp;
      adc_dco_n = adc_dco_n_tmp;
   
   end

   // Sine wave
   reg [11:0] sine_lut [0:1023];
   integer file_handle;
   initial begin
      file_handle = $fopen("sine_file.txt", "w");
      for (i = 0; i < 1024; i = i + 1) begin
         sine_lut[i] = $signed(511.5 * $sin(2 * i * 4 * 3.14159265359 / 1024));         
         $fwrite(file_handle, "Data[%0d]: %b\n", i, sine_lut[i]);
      end
      $fclose(file_handle);
   end
   
   integer d_cnt = 7;
   integer i_cnt = 1023;
   
   always @(posedge adc_dco_p_tmp or negedge adc_dco_p_tmp) begin

      if (led[6] == 1'b0) begin
         d_cnt = 7;
         i_cnt = 1023;
      end
      else begin
         d_cnt <= d_cnt + 1;
         if (d_cnt == 7) begin
            d_cnt <= 0;
            i_cnt <= i_cnt + 1;
         end
         if (i_cnt == 1023) begin
            i_cnt <= 0;
         end
      end
   end
   
   always @* begin
      case(d_cnt)
         0: begin
            adc_out_1p[0] = sine_lut[i_cnt][11];
            adc_out_1p[1] = sine_lut[i_cnt][10];
         end
         
         1: begin
            adc_out_1p[0] = sine_lut[i_cnt][9];
            adc_out_1p[1] = sine_lut[i_cnt][8];
         end
         
         2: begin
            adc_out_1p[0] = sine_lut[i_cnt][7];
            adc_out_1p[1] = sine_lut[i_cnt][6];
         end
         
         3: begin
            adc_out_1p[0] = sine_lut[i_cnt][5];
            adc_out_1p[1] = sine_lut[i_cnt][4];
         end
         
         4: begin
            adc_out_1p[0] = sine_lut[i_cnt][3];
            adc_out_1p[1] = sine_lut[i_cnt][2];
         end
         
         5: begin
            adc_out_1p[0] = sine_lut[i_cnt][1];
            adc_out_1p[1] = sine_lut[i_cnt][0];
         end
         
         6 : begin
            adc_out_1p[0] = 1'b0;
            adc_out_1p[1] = 1'b0;
         end
         
         7 : begin
            adc_out_1p[0] = 1'b0;
            adc_out_1p[1] = 1'b0;
         end
      
      endcase
      
      adc_out_1n = ~adc_out_1p;
   end
   
   initial begin
      FrontPanelReset;
      
      // Init Sys
      // Reset
      SetWireInValue(8'h00, 32'h0000_0001, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h00, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
      // Wait for ADC setup
      #1000
      // Rx sample number update
      SetWireInValue(8'h05, 32'd2, NO_MASK);
      UpdateWireIns;
      #1000
      SetWireInValue(8'h06, 32'd13, NO_MASK);
      UpdateWireIns;
   
      SetWireInValue(8'h01, 32'd2044, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h03, 32'h0000_0001, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h04, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h03, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
//      SetWireInValue(8'h08, 32'h0000_0001, NO_MASK);
//      UpdateWireIns;
      SetWireInValue(8'h07, 32'h0000_0001, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h08, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
      #2000
      SetWireInValue(8'h08, 32'h0000_0001, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h07, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
      #2000
      SetWireInValue(8'h07, 32'h0000_0001, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h08, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
      
      
      
      
  
      // Wait for ADC setup
      #2000
      
      // Init Tx
      // Reset
      // SetWireInValue(8'h00, 32'h0000_0001, NO_MASK);
      // UpdateWireIns;
      // SetWireInValue(8'h00, 32'h0000_0000, NO_MASK);
      // UpdateWireIns;
      // SPI setting
      // SetWireInValue(8'h02, 32'h0000_0580, NO_MASK);
      // UpdateWireIns;
      // ActivateTriggerIn(8'h40, 1);
      // #10000
      // SetWireInValue(8'h02, 32'h0000_0880, NO_MASK);
      // UpdateWireIns;
      // ActivateTriggerIn(8'h40, 1);
      // #1000
      // SetWireInValue(8'h02, 32'h0000_04A0, NO_MASK);
      // UpdateWireIns;
      // ActivateTriggerIn(8'h40, 1);
      // #1000
      // SetWireInValue(8'h02, 32'h0000_07A0, NO_MASK);
      // UpdateWireIns;
      // ActivateTriggerIn(8'h40, 1);
      // #1000
      
      // Acquire Data
      //ActivateTriggerIn(8'h40, 0);
      SetWireInValue(8'h02, 32'h0000_0001, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h02, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
   
      #10000
      SetWireInValue(8'h02, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
   
      // Wait for ADC operating
      #10000
      
      file_handle = $fopen("sine_read_file1.txt", "w");
      for (i = 0; i <= 2044; i = i + 4) begin
         ReadFromPipeOut(8'hA0, 32'h0000_0010); // passes data to pipeOut array - 4 sample ReadFromBlockPipeOut
         @(negedge hi_clk);
         $fwrite(file_handle, "Data[%0d]: %b\n", i, {pipeOut[0],pipeOut[1]});
         @(negedge hi_clk);
         $fwrite(file_handle, "Data[%0d]: %b\n", i+1, {pipeOut[4],pipeOut[5]});
         @(negedge hi_clk);
         $fwrite(file_handle, "Data[%0d]: %b\n", i+2, {pipeOut[8],pipeOut[9]});
         @(negedge hi_clk);
         $fwrite(file_handle, "Data[%0d]: %b\n", i+3, {pipeOut[12],pipeOut[13]});
      end
      $fclose(file_handle);
      #60000
      
      // Acquire Data (again)
      //ActivateTriggerIn(8'h40, 0);
      SetWireInValue(8'h02, 32'h0000_0001, NO_MASK);
      UpdateWireIns;
      SetWireInValue(8'h02, 32'h0000_0000, NO_MASK);
      UpdateWireIns;
      // Wait for ADC operating
      #10000
      
      file_handle = $fopen("sine_read_file2.txt", "w");
      for (i = 0; i <= 2044; i = i + 4) begin
         ReadFromPipeOut(8'hA0, 32'h0000_0010); // passes data to pipeOut array - 4 sample ReadFromBlockPipeOut
         @(negedge hi_clk);
         $fwrite(file_handle, "Data[%0d]: %b\n", i, {pipeOut[0],pipeOut[1]});
         @(negedge hi_clk);
         $fwrite(file_handle, "Data[%0d]: %b\n", i+1, {pipeOut[4],pipeOut[5]});
         @(negedge hi_clk);
         $fwrite(file_handle, "Data[%0d]: %b\n", i+2, {pipeOut[8],pipeOut[9]});
         @(negedge hi_clk);
         $fwrite(file_handle, "Data[%0d]: %b\n", i+3, {pipeOut[12],pipeOut[13]});
      end
      $fclose(file_handle);
   end
   
   //always @(negedge hi_clk) begin
   //
   // if 
   //
   //end
   
   `include "C:/Project/13_dac_adc_triggered_read_JH/gateware/oksim/okHostCalls.vh"
   
endmodule
`default_nettype wire
