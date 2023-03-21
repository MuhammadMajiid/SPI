`timescale 1ns/1ps
module mstr_tb;

// parameters
parameter BUS = 4,
          TICKS_PER_HALF = 2;
// Signals
logic       clk;
logic       arst_n;
logic [1:0] mode;
//    (MOSI) signals
logic [BUS-1:0] tx_byte;
logic           tx_vld;
//    (MISO) signals
logic [BUS-1:0] rx_byte;
logic           rx_vld;
//    SPI Interface
logic miso;
logic mosi;
logic sclk;

// DUT
mstr_spi #(4,2) dut (.*);

//  dumping
initial
begin
    $dumpfile("PisoTest.vcd");
    $dumpvars;
end

//  Monitoring the outputs and the inputs
initial begin
    $monitor($time, "   The Outputs:  MOSI = %b  Recieved Byte = %b Recieved Flag = %b  The Inputs:   Data to transmit = %b  Mode = %d  Transmit Flag = %b  MISO = %b",
    mosi, rx_byte, rx_vld, tx_byte, mode, tx_vld, miso);
end

// clock generator  50MHz
initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
end

// Resetting the system
initial begin
    arst_n = 1'b1;
    @(negedge clk)
    arst_n = 1'b0;
    @(posedge clk)
    arst_n = 1'b1;
end

// Transmitting serially
initial begin
    // frame to transmit = 1010;
    mode    = 2'd0;
    tx_byte = 4'hA;
    tx_vld  = 1'b1;
    miso    = 1'b0;

    #370;
    mode    = 2'd1;
    tx_byte = 4'b1101;
    tx_vld  = 1'b1;
    miso    = 1'b1;
end

// Recieving serially
always @(negedge sclk) begin
    // frame to recieve = 1010;
    miso = ~miso;
end
endmodule