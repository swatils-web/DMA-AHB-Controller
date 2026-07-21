`timescale 1ns / 1ps

module arbiter #(
  parameter CH = 4
)(
  input  wire          clk,
  input  wire          rst_n,
  input  wire [CH-1:0] req,
  input  wire          done,     // from master
  output reg  [CH-1:0] grant
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= 0;
    end else begin
      if (grant == 0) begin
        if (req[0])      grant <= 4'b0001;
        else if (req[1]) grant <= 4'b0010;
        else if (req[2]) grant <= 4'b0100;
        else if (req[3]) grant <= 4'b1000;
      end 
      else if (done) begin
        grant <= 0;
      end
    end
  end
endmodule