///////////////////////////////////////////////////////////////////////
//  AUTHOR: Mohamed Maged Elkholy.
//  INFO.: Undergraduate ECE student, Alexandria university, Egypt.
//  AUTHOR'S EMAIL: majiidd17@icloud.com
//  FILE NAME: mstr_spi.v
//  TYPE: module.
//  DATE: 2/3/2023
//  KEYWORDS: SPI, Master, Serial Communication.
//  PURPOSE: RTL modelling for the SPI Master Protocol.
//  NOTE: - TICKS_PER_HALF MUST BE >= 2, 
//          clk must be at least 2x faster than sclk
//        - If the SPI peripheral requires a chip-select, 
//          this must be done at a higher level.
//        - mode, can be 0, 1, 2, or 3. check the table below:
//              Can be configured in one of 4 modes:
//              Mode |    Clock Polarity (CPOL)  | Clock Phase (CPHA)
//               0   |             0             |        0
//               1   |             0             |        1
//               2   |             1             |        0
//               3   |             1             |        1
///////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module mstr_spi
#(
    parameter BUS = 4,
              TICKS_PER_HALF = 2
)(
//    System
   input              clk,
   input  logic       arst_n,
   input  logic [1:0] mode,

//    (MOSI) signals
   input  logic [BUS-1:0] tx_byte,
   input  logic           tx_vld,
   
//    (MISO) signals
   output logic [BUS-1:0] rx_byte,
   output logic           rx_vld,
   
//    SPI Interface
   input  logic miso,
   output logic mosi,
   output logic sclk
);

// Internals
localparam CNT_SZ = $clog2(TICKS_PER_HALF*2)-1;
logic [CNT_SZ:0] tick_crnt, tick_nxt;
logic [$clog2(BUS)-1:0] frame_r, frame_nxt; 
logic [BUS-1:0] tx_byte_nxt, tx_byte_r;
logic [BUS-1:0] rx_byte_nxt, rx_byte_r;
logic cpol, cpha;
logic spi_clk_mid, spi_clk_fin;
logic tx_bit;

// FSM states
typedef enum logic [1:0] {IDLE, CPHA_DL, LOW, HIGH} state_t;
state_t state_crnt;
state_t state_nxt;

// setup
assign cpha     = mode[0];
assign cpol     = mode[1];
assign rx_vld   = (state_crnt == IDLE);

always_ff @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
      state_crnt  <= IDLE;
      tick_crnt   <= 0;
      frame_r     <= 0;
      tx_byte_r   <= 0;
      rx_byte_r   <= 0;
    end
    else begin
      state_crnt <= state_nxt;
      tick_crnt  <= tick_nxt;
      frame_r    <= frame_nxt;
      tx_byte_r  <= tx_byte_nxt;
      rx_byte_r  <= rx_byte_nxt;
    end
end

// Serial System FSM
always_comb begin
   // default values
   state_nxt   = state_crnt;
   tick_nxt    = tick_crnt;
   frame_nxt   = frame_r;
   tx_byte_nxt = tx_byte_r;
   rx_byte_nxt = rx_byte_r;
   tx_bit      = 1'b0;
   
   case (state_crnt)
      IDLE: begin
         if (tx_vld) begin
            tx_byte_nxt = tx_byte;
            tick_nxt    = 0;
            frame_nxt   = 0;
            if (cpha) state_nxt = CPHA_DL;
            else      state_nxt = LOW;
         end
      end

      CPHA_DL: begin
         if (tick_crnt == (TICKS_PER_HALF - 1)) begin
            state_nxt  = LOW;
            tick_nxt   = 0;
         end
         else tick_nxt = tick_crnt + 1'b1;
      end

      LOW: begin
         if (tick_crnt == (TICKS_PER_HALF - 1)) begin
            state_nxt      = HIGH;
            tick_nxt       = 0;
            tx_bit         = tx_byte_r[BUS-1];
            tx_byte_nxt    = tx_byte_r << 1;
            rx_byte_nxt[0] = miso;
         end
         else tick_nxt     = tick_crnt + 1'b1;
      end

      HIGH: begin
         if (tick_crnt == (TICKS_PER_HALF - 1)) begin
            if (frame_nxt == (BUS -1)) state_nxt = IDLE;
            else begin
               state_nxt   = LOW;
               tick_nxt    = 0;
               rx_byte_nxt = rx_byte_r << 1;
               frame_nxt   = frame_r + 1'b1;
            end
         end
         else   tick_nxt = tick_crnt + 1'b1;
      end
   endcase
end

// sclk generation
assign spi_clk_mid = ((state_nxt == HIGH) && !cpha) || ((state_nxt == LOW) && cpha);
assign spi_clk_fin = cpol ? !spi_clk_mid : spi_clk_mid;

// SPI
assign sclk    = spi_clk_fin;
assign mosi    = tx_bit;
assign rx_byte = rx_vld ? rx_byte_r : 0;

endmodule