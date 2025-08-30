`default_nettype none

module xem7320_adc(
input  wire [4:0]           okUH,
output wire [3:0]           okHU,
inout  wire [31:0]         okUHU,
inout  wire                 okAA,
// ADC Pins
input  wire               sys_clkp,
input  wire               sys_clkn,
input  wire [1:0]         adc_out_1p, // Channel 1 data
input  wire [1:0]         adc_out_1n,
input  wire [1:0]         adc_out_2p, // Channel 2 data
input  wire [1:0]         adc_out_2n,
input  wire               adc_dco_p,      // ADC Data clock
input  wire               adc_dco_n,
input  wire               adc_fr_p,       // Frame input
input  wire               adc_fr_n,
output wire               adc_encode_p,   // ADC Encode Clock
output wire               adc_encode_n,
input  wire               adc_sdo,
output wire               adc_sdi,
output wire               adc_cs_n,
output wire [7:0]         led,
output wire               adc_sck,
// Pulser Pins
output reg                OEN, REN, MODE, PWS,
output reg                SEL0, NEG0, POS0,
output reg                SEL1, NEG1, POS1,

// BRKOUT Pins
output wire [7:0] m_dbg_signal
);

// Target interface bus:
wire         okClk;
wire [112:0] okHE;
wire [64:0]  okEH;

wire [31:0]  ep00data; // SW reset
wire [31:0]  ep01data; // Rx FIFO sample size
wire [31:0]  ep02data;  //acq_trigger
wire [31:0]  ep03data;  //pulser ON
wire [31:0]  ep04data;  //pulser OFF
wire [31:0]  ep05data;  //burst cnt
wire [31:0]  ep06data;  //frequency
wire [31:0]  ep07data;  // mode selection (0=transmission,1=reflection)
//wire [31:0]  ep08data;  // mode selection (reflection)

wire [31:0]  pipea0_data;
wire         pulser_on;
wire         pulser_off;
wire         reset;
wire         idelay_rdy;
wire         ep_read;
wire         adc_data_clk;
wire         adc_clk;
wire         adc_data_valid;
wire         prog_full;
wire         acq_start;
wire [31:0]  frequency;
wire [7:0]   status_signals;
wire         enc_clk_locked;
wire         locked;
wire         sys_clk_ibuf;
wire         sys_clk_bufg;
wire         rd_rst_busy;
wire         wr_rst_busy;
wire [7:0]   debugpin;
wire [15:0]  adc_data_out1, adc_data_out2;
wire         transmission;
wire         reflection;
reg          wr_en = 1'b0;
reg          tx_en = 1'b0;
reg          tx_done;
reg          tx_start;
reg          rx_rd;
reg          rx_en;
reg          md_en;
reg          rx_done;
reg          fifo_reset;
reg          fifo_busy;

// DAC signals
assign locked       = idelay_rdy & enc_clk_locked;
assign reset        = ep00data[0];
assign acq_start    = ep02data[0];
assign pulser_on    = ep03data[0];
assign pulser_off   = ep04data[0];
//assign transmission = ep07data[0];
//assign reflection   = ep08data[0];
assign frequency    = ep06data[31:0];

assign status_signals = {acq_start, reset, enc_clk_locked, idelay_rdy, adc_data_valid, fifo_busy, locked, prog_full};
function [7:0] xem7320_led;
input [0:7] a;
integer i;
begin
for(i=0; i<8; i=i+1) begin: u
xem7320_led[i] = (a[i]==1'b1) ? (1'b0) : (1'bz);
end
end
endfunction
assign led = xem7320_led(status_signals);

//debug pins
assign m_dbg_signal[7:3]= 5'b00000;
assign m_dbg_signal[0]  = pulse_state[0];
assign m_dbg_signal[1]  = pulse_state[1];
assign m_dbg_signal[2]  = tx_en;

//PULSER PW UP/DW
always @(posedge adc_clk) begin
if (pulser_off == 1'b1) begin
OEN <= 1'b0;
REN <= 1'b0;
end
else if (pulser_on == 1'b1) begin
REN <= 1'b1;
OEN <= 1'b1;
end
end

// Main Controller Design(40MHz)
reg [31:0] rx_sample_counter = 32'd0;
reg [2:0] main_state = 3'b000;
localparam main_idle = 0,
rx_rdy = 1,
tx_init = 2,
tx_pulse_gen = 3,
rx_cnt = 4;

always @ (posedge adc_clk) begin
    case (main_state)
    main_idle: begin
        rx_done  <= 1'b0;
        wr_en   <= 1'b0;
        tx_en   <= 1'b0;
        PWS     <= 1'b0;
        MODE    <= 1'b0;
            if (locked && !prog_full && adc_data_valid && !fifo_busy) begin
            main_state <= rx_rdy;
            end
            else begin
            main_state <= main_idle;
            end
        end
    
    rx_rdy: begin // wait for acquisition start trigger
         wr_en <= 1'b0;
         tx_en <= 1'b0;
         PWS   <= 1'b1;//원래는 1이었는데, acq_start에 맞춰서 high로 뜨게 바꾸고 싶어서 수정.이상 있을 시 다시 1로 수정할 것
         MODE  <= 1'b0;
            if (acq_start) begin
                main_state <= tx_init;
            end
            else begin
                main_state <= rx_rdy;
            end
        end
    
      tx_init: begin
         wr_en <= 1'b0;
         tx_en <= 1'b0;
         PWS   <= 1'b1;
         MODE  <= 1'b0;
         if (OEN==1'b1&& REN==1'b1) begin
            main_state <= tx_pulse_gen;
         end
         else begin
            main_state <= rx_rdy;
         end
        end
    
      tx_pulse_gen: begin
         wr_en <= 1'b0;
         tx_en <= 1'b1;
         PWS   <= 1'b1;
         MODE  <= 1'b0;
         if (tx_done) begin
            rx_sample_counter <= ep01data;
            main_state <= rx_cnt;
            tx_en      <=1'b0;
         end
         else begin
                main_state <= tx_pulse_gen;
            end
        end
    
      rx_cnt: begin
         rx_sample_counter <= rx_sample_counter - 1'b1;
         wr_en <= 1'b1;
         tx_en <= 1'b0;
         PWS   <= 1'b1;
         MODE  <= 1'b0;
         if (rx_sample_counter == 32'd0) begin
                rx_done <= 1'b1;
             //ep20data <=1'b1;  //새로 추가된 부분
                main_state <= main_idle;
            end
    
        end
    endcase
   end

// Transmission and Reflection Mode Control
reg [4:0]  pos_counter;
reg [4:0]  neg_counter;
reg [2:0]  tx_done_counter;
//reg [31:0] sw_counter;
reg [31:0] burst_counter;
reg [3:0]  RTZ_counter;
reg [2:0] pulse_state = 3'b000;
reg selected_mode; // 1'b0: transmission, 1'b1: reflection
reg mode_locked;   // mode가 lock 되었음을 나타내는 플래그

localparam initialize = 3'b000,
pos        = 3'b001,
RTZ        = 3'b010,
neg        = 3'b011,
clamping   = 3'b100,
rx         = 3'b101;

  always @(posedge idelay_ref) begin
    if (reset) begin
        tx_done       <= 1'b0;
        tx_start      <= 1'b0;
        pos_counter   <= 5'b0;
        neg_counter   <= 5'b0;
        burst_counter <= 32'b0000_0000;
        RTZ_counter   <= 4'b0;
        tx_done_counter<=3'b000;
        mode_locked    <=1'b0;
        selected_mode  <=1'b0;
        POS0 <= 1'b0;
        NEG0 <= 1'b0;
        SEL0 <= 1'b0;
        POS1 <= 1'b0;
        NEG1 <= 1'b0;
        SEL1 <= 1'b0;
        end else if(tx_en) begin
            pulse_state <= initialize;
        end else begin
            tx_done  <= tx_done;
            tx_start <= tx_start;
            pos_counter <= pos_counter;
            neg_counter <= neg_counter;
            burst_counter <= burst_counter;
            RTZ_counter <= RTZ_counter;
            tx_done_counter<=tx_done_counter;
            POS0 <= POS0;
            NEG0 <= NEG0;
            SEL0 <= SEL0;
            POS1 <= POS1;
            NEG1 <= NEG1;
            SEL1 <= SEL1;
        end
        case (pulse_state)
            initialize: begin
                tx_done     <= 1'b0;
                pos_counter <= frequency; // 5ns * 5 = 25ns
                neg_counter <= frequency; // 5ns * 5 = 25ns
                RTZ_counter <= 4'b0101;   // 5ns * 5 = 25ns
              tx_done_counter<=3'b000;
                // transmission mode setting
                POS0 <= 1'b0;
                NEG0 <= 1'b0;
                SEL0 <= 1'b0;
                POS1 <= 1'b0;
                NEG1 <= 1'b0;
                SEL1 <= 1'b0;
        
                if (tx_en == 1'b1) begin
                    pulse_state <= pos;
                    burst_counter <= ep05data - 1'b1;
                end else begin
                    pulse_state <= initialize;
                end
            end
        
            pos: begin
                POS0 <= 1'b1;
                NEG0 <= 1'b0;
                if (pos_counter == 5'd0) begin
                    pulse_state <= RTZ;
                    pos_counter <= frequency;
                end else begin
                    pos_counter <= pos_counter - 1'b1;
                    pulse_state <= pos;
                end
            end
        
            RTZ: begin
                POS0 <= 1'b0;
                NEG0 <= 1'b0;
                if (RTZ_counter == 2'b00) begin
                    pulse_state <= neg;
                    RTZ_counter <= 4'b0101;
                end else begin
                    pulse_state <= RTZ;
                    RTZ_counter <= RTZ_counter - 1'b1;
                end
            end
        
            neg: begin
                POS0 <= 1'b0;
                NEG0 <= 1'b1;
                if (neg_counter == 5'd0) begin
                    pulse_state   <= clamping;
                    neg_counter   <= frequency;
                end else begin
                    pulse_state <= neg;
                    neg_counter <= neg_counter - 1'b1;
                end
            end
        
            clamping: begin
                POS0 <= 1'b0;
                NEG0 <= 1'b0;
        
                if (RTZ_counter != 4'd0) begin
                    pulse_state <= clamping;
                    RTZ_counter <= RTZ_counter - 1'b1;
                end else if (burst_counter != 32'b0) begin
                    burst_counter <= burst_counter - 1'b1;
                    pulse_state <= pos;
                 RTZ_counter <= 4'b0101;
                end else begin
                    pulse_state <= rx;
                    burst_counter <= 32'b0000_0000;
                end
            end
        
            rx: begin
              if (tx_done_counter > 3'b100) begin  // Counter for 3 clock cycles
                    tx_done <= 1'b0;
                 //tx_done_counter <= 3'b000;
        
                end else begin
                 tx_done <= 1'b1;
                    tx_done_counter <= tx_done_counter + 1'b1;
                end
        
              // 초기에는 mode_locked가 비활성화되어 있는지 확인합니다.
              if (!mode_locked) begin
              // 첫 번째로 ep07data 값을 확인하여 selected_mode에 저장합니다.
              selected_mode <= ep07data[0];
              mode_locked <= 1'b1;  // 이후부터는 mode가 lock됩니다.
              end
        
                if(selected_mode == 1'b0)begin
                    //tx_done <= 1'b1;
                    POS0 <= 1'b0;
                    NEG0 <= 1'b0;
                    POS1 <= 1'b1;
                    NEG1 <= 1'b1;
                 //transmission <= 1'b0;
                end
              else if (selected_mode == 1'b1) begin
                   // tx_done <= 1'b1;
                    POS0 <= 1'b1;
                    NEG0 <= 1'b1;
                    POS1 <= 1'b0;
                    NEG1 <= 1'b0;
                 //reflection<=1'b0;
                end
                if (rx_done) begin
                    pulse_state <= initialize;
                 mode_locked <= 1'b0;  // 다음번 동작에 대비해 lock 해제
                end
                else begin
                    pulse_state <= rx;
                end
              end
            endcase
        end

/*
always @posedge(adc_clk) begin
case(pulse_state)
rx:begin
tx_done<=1'b1;
end
endcase
end */

// FIFO Reset Logic
reg [7:0] delay_counter = 8'd0;
reg [1:0] state = 2'b00;
localparam idle = 0,
wait_for_lock = 3,
reset_state = 1,
delay_wait = 2;

// Worst case is using ADC-12 project, in which
// okClk (100.8 MHz) is 2.52x faster than adc_clk (40 MHz)
// first wait for MMCM to lock, then the
// reset should be asserted for 21 cycles,
// and then should wait for 152 cycles, for a
// total of 173 cycles the FIFO is resetting.
// See PG057 Figure 3-29 for more information.
always @ (posedge okClk) begin
case (state)
idle: begin
if (reset) begin
fifo_reset <= 1'b1;
state <= wait_for_lock;
fifo_busy <= 1'b1;
end
else begin
fifo_busy <= 1'b0;
fifo_reset <= 1'b0;
end
end

wait_for_lock: begin // wait for MMCM to lock
        if (locked) begin
            delay_counter = 8'd21;
            state <= reset_state;
        end
    end

    reset_state: begin // assert reset for 21 cycles after MMCM is locked
        delay_counter <= delay_counter - 1'b1;
        if (delay_counter == 8'd0) begin
            fifo_reset <= 1'b0;
            delay_counter <= 8'd152;
            state <= delay_wait;
        end
    end

    delay_wait: begin // deassert fifo_busy after 152 cycles
        delay_counter <= delay_counter - 1'b1;
        if (delay_counter == 8'd0) begin
            fifo_busy <= 1'b0;
            state <= idle;
         end
    end
endcase
end

wire idelay_ref;
enc_clk enc_clk_inst (
    .clk_out1(adc_clk),     // output clk_out1
    .clk_out2(idelay_ref),
    .reset(reset),          // input reset
    .locked(enc_clk_locked),// output locked
    .clk_in1_p(sys_clkp),   // input clk_in1
    .clk_in1_n(sys_clkn)    // input clk_in1
);

syzygy_adc_top adc_impl(
    .clk          (adc_clk),
    .idelay_ref   (idelay_ref),
    .reset_async  (reset),
   
    .adc_out_1p   (adc_out_1p),
    .adc_out_1n   (adc_out_1n),
    .adc_out_2p   (adc_out_2p),
    .adc_out_2n   (adc_out_2n),
    .adc_dco_p    (adc_dco_p),
    .adc_dco_n    (adc_dco_n),
    .adc_fr_p     (adc_fr_p),
    .adc_fr_n     (adc_fr_n),
    .adc_encode_p (adc_encode_p),
    .adc_encode_n (adc_encode_n),
    .adc_sdo      (adc_sdo),
    .adc_sdi      (adc_sdi),
    .adc_cs_n     (adc_cs_n),
    .adc_sck      (adc_sck),
   
    .adc_data_clk (adc_data_clk),
    .adc_data_1   (adc_data_out1),
    .adc_data_2   (adc_data_out2),
    .data_valid   (adc_data_valid),
    .idelay_rdy   (idelay_rdy)
);

fifo_generator_0 fifo(
.wr_clk         (adc_data_clk),
.rd_clk         (okClk),
.rst            (fifo_reset),
.din            ({adc_data_out1, adc_data_out2}),
.wr_en          (wr_en & ~fifo_busy),
.rd_en          (ep_read & ~fifo_busy),
.dout           ({pipea0_data[7:0], pipea0_data[15:8], pipea0_data[23:16], pipea0_data[31:24]}),
.full           (),
.wr_rst_busy    (wr_rst_busy),
.rd_rst_busy    (rd_rst_busy),
.empty          (),
.prog_full      (prog_full)
);

//fifo read counter
reg [11:0] fifo_rd_cnt;
always @ (posedge okClk) begin
if (reset | ~ep_read) begin
fifo_rd_cnt <= 12'b000000000000;
end
else begin
fifo_rd_cnt <= fifo_rd_cnt + 1'b1;

end
end

// Instantiate the okHost and connect endpoints.
wire [65*1-1:0]  okEHx;
okHost okHI(
.okUH(okUH),
.okHU(okHU),
.okUHU(okUHU),
.okAA(okAA),
.okClk(okClk),
.okHE(okHE),
.okEH(okEH)
);

okWireOR # (.N(1)) wireOR (okEH, okEHx);

//okTriggerIn trigIn53    (.okHE(okHE), .ep_addr(8'h40), .ep_clk(adc_data_clk), .ep_trigger(ep40trig));
okWireIn wire00         (.okHE(okHE), .ep_addr(8'h00), .ep_dataout(ep00data));
okWireIn wire01         (.okHE(okHE), .ep_addr(8'h01), .ep_dataout(ep01data));
okWireIn wire02         (.okHE(okHE), .ep_addr(8'h02), .ep_dataout(ep02data));
okWireIn wire03         (.okHE(okHE), .ep_addr(8'h03), .ep_dataout(ep03data));
okWireIn wire04         (.okHE(okHE), .ep_addr(8'h04), .ep_dataout(ep04data));
okWireIn wire05         (.okHE(okHE), .ep_addr(8'h05), .ep_dataout(ep05data));
okWireIn wire06         (.okHE(okHE), .ep_addr(8'h06), .ep_dataout(ep06data));
okWireIn wire07         (.okHE(okHE), .ep_addr(8'h07), .ep_dataout(ep07data));
//okWireIn wire08         (.okHE(okHE), .ep_addr(8'h08), .ep_dataout(ep08data));

okPipeOut pipeOuta0     (.okHE(okHE), .okEH(okEHx[ 0*65 +: 65 ]), .ep_addr(8'ha0), .ep_read(ep_read), .ep_datain(pipea0_data));

endmodule
`default_nettype wire`default_nettype none
