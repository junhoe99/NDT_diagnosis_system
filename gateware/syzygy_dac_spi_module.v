`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2023 03:37:41 PM
// Design Name: 
// Module Name: syzygy_dac_spi_module
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


module syzygy_dac_spi_module(
		input	wire		reset,
		input 	wire		okClk,
		input 	wire		dac_spi_start,
		input 	wire [15:0]	dac_spi_full,
		output 	reg        	dac_reset_pinmd,
		output 	reg        	dac_sclk,        	// SPI Clock
		output 	reg        	dac_sdio,        	// SPI Data I/O
		output 	reg        	dac_cs_n        	// SPI Chip Select
);
	
// SPI module
reg  [31:0] divide_counter;
reg         clk_en;
reg  [5:0]  spi_pos;
reg			spi_done;

// Divide down the ~125MHz input clock to ~1MHz to work with the SPI interface
always @(posedge okClk) begin
	clk_en <= 1'b0;
	if (reset) begin
		divide_counter <= 32'h00;
	end else begin
		divide_counter <= divide_counter + 1'd1;
		if (divide_counter == 32'd125) begin
			divide_counter <= 32'h00;
			clk_en         <= 1'b1;
		end
	end
end

// Handle the SPI transfer

always @(posedge okClk) begin
	if (reset == 1'b1) begin
		dac_sclk     		<= 1'b1;
		dac_cs_n     		<= 1'b1;
		dac_reset_pinmd    	<= 1'b1;

		spi_done     		<= 1'b1;

		dac_sdio  			<= 1'b0;
		spi_pos      		<= 6'h0;
	end else begin
		dac_reset_pinmd    	<= 1'b0;
		// start an SPI transfer
		if (dac_spi_start && spi_done) begin
			spi_pos        <= 5'h10;
			dac_sclk       <= 1'b1;
			dac_cs_n       <= 1'b0;
			spi_done       <= 1'b0;
		end
			
		if (clk_en) begin
			dac_sclk       <= ~dac_sclk;
			
			if (dac_sclk) begin
				if (spi_pos > 6'h0) begin
					spi_pos		<= spi_pos - 1'b1;
					spi_done	<= 1'b0;
				end else begin
					dac_cs_n	<= 1'b1;
					spi_done	<= 1'b1;
					dac_sclk	<= 1'b1;
				end
				dac_sdio  <= dac_spi_full[spi_pos - 1];
			end
		end
	end
end	
	
	
	
	
	
	
endmodule
