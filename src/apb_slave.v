`timescale 1ns / 1ps

module apb_slave #(
  parameter CH=4,
  parameter AW=32,
  parameter DW=32
)(
  input  wire        PCLK, PRESETn,
  input  wire [11:0] PADDR,
  input  wire        PSEL, PENABLE, PWRITE,
  input  wire [DW-1:0] PWDATA,
  output reg  [DW-1:0] PRDATA,

  output reg [AW-1:0] sar0, sar1, sar2, sar3,
  output reg [AW-1:0] dar0, dar1, dar2, dar3,
  output reg [15:0]   ctr0, ctr1, ctr2, ctr3
);

  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      sar0 <= 0; dar0 <= 0; ctr0 <= 0;
      sar1 <= 0; dar1 <= 0; ctr1 <= 0;
      sar2 <= 0; dar2 <= 0; ctr2 <= 0;
      sar3 <= 0; dar3 <= 0; ctr3 <= 0;
      PRDATA <= 0;
    end else if (PSEL && PENABLE) begin
      if (PWRITE) begin
        case (PADDR[5:0])
          6'h00: sar0 <= PWDATA;
          6'h04: dar0 <= PWDATA;
          6'h08: ctr0 <= PWDATA[15:0];
          6'h10: sar1 <= PWDATA;
          6'h14: dar1 <= PWDATA;
          6'h18: ctr1 <= PWDATA[15:0];
          6'h20: sar2 <= PWDATA;
          6'h24: dar2 <= PWDATA;
          6'h28: ctr2 <= PWDATA[15:0];
          6'h30: sar3 <= PWDATA;
          6'h34: dar3 <= PWDATA;
          6'h38: ctr3 <= PWDATA[15:0];
        endcase
      end else begin
        case (PADDR[5:0])
          6'h00: PRDATA <= sar0;
          6'h04: PRDATA <= dar0;
          6'h08: PRDATA <= {16'h0, ctr0};
          6'h10: PRDATA <= sar1;
          6'h14: PRDATA <= dar1;
          6'h18: PRDATA <= {16'h0, ctr1};
          6'h20: PRDATA <= sar2;
          6'h24: PRDATA <= dar2;
          6'h28: PRDATA <= {16'h0, ctr2};
          6'h30: PRDATA <= sar3;
          6'h34: PRDATA <= dar3;
          6'h38: PRDATA <= {16'h0, ctr3};
          default: PRDATA <= 32'h0;
        endcase
      end
    end
  end
endmodule