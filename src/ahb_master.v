`timescale 1ns / 1ps

//module ahb_master #(
//  parameter CH = 4, AW = 32, DW = 32
//)(
//  input  wire        HCLK, HRESETn,

//  output reg  [AW-1:0] HADDR,
//  output reg  [1:0]    HTRANS,
//  output reg  [2:0]    HBURST, HSIZE,
//  output reg           HWRITE,
//  output wire [DW-1:0] HWDATA,  // wire for combinational drive

//  input  wire [DW-1:0] HRDATA,
//  input  wire          HREADY, HRESP,

//  output reg           HBUSREQ,
//  input  wire          HGRANT,

//  input  wire [CH-1:0] grant,

//  input  wire [AW-1:0] sar0, sar1, sar2, sar3,
//  input  wire [AW-1:0] dar0, dar1, dar2, dar3,
//  input  wire [15:0]   ctr0, ctr1, ctr2, ctr3,

//  output reg [CH-1:0] dma_ack,
//  output reg [CH-1:0] irq,
//  output reg          done
//);

//  localparam IDLE    = 3'd0,
//             RD_ADDR = 3'd1,
//             RD_DATA = 3'd2,
//             WR_ADDR = 3'd3,
//             WR_DATA = 3'd4,
//             DONE    = 3'd5;

//  reg [2:0]    state;
//  reg [AW-1:0] s_ptr, d_ptr;
//  reg [15:0]   count;
//  reg [DW-1:0] buffer;

//  // Combinational HWDATA: always shows buffer during write states
//  assign HWDATA = buffer;

//  always @(posedge HCLK or negedge HRESETn) begin
//    if (!HRESETn) begin
//      state   <= IDLE;
//      HADDR   <= 0;
//      HTRANS  <= 2'b00;
//      HWRITE  <= 0;
//      HBUSREQ <= 0;
//      dma_ack <= 0;
//      irq     <= 0;
//      done    <= 0;
//      HSIZE   <= 3'b010;
//      HBURST  <= 3'b000;
//      s_ptr   <= 0;
//      d_ptr   <= 0;
//      count   <= 0;
//      buffer  <= 0;
//    end else begin
//      case (state)

//        IDLE: begin
//          irq     <= 0;
//          done    <= 0;
//          dma_ack <= 0;
//          HTRANS  <= 2'b00;
//          HWRITE  <= 0;

//          if (|grant && HGRANT) begin
//            case (grant)
//              4'b0001: begin s_ptr<=sar0; d_ptr<=dar0; count<=ctr0; end
//              4'b0010: begin s_ptr<=sar1; d_ptr<=dar1; count<=ctr1; end
//              4'b0100: begin s_ptr<=sar2; d_ptr<=dar2; count<=ctr2; end
//              4'b1000: begin s_ptr<=sar3; d_ptr<=dar3; count<=ctr3; end
//            endcase
//            HBUSREQ <= 1;
//            dma_ack <= grant;
//            state   <= RD_ADDR;
//          end
//        end

//        RD_ADDR: begin
//          HADDR  <= s_ptr;
//          HWRITE <= 0;
//          HTRANS <= 2'b10;   // NONSEQ read
//          state  <= RD_DATA;
//        end

//        RD_DATA: begin
//          HTRANS <= 2'b00;
//          HWRITE <= 0;
//          if (HREADY) begin
//            // KEY FIX: Latch HRDATA directly into buffer.
//            // HRDATA is combinationally driven by TB from HADDR,
//            // so it is already stable and correct here.
//            buffer <= HRDATA;
//            s_ptr  <= s_ptr + 4;
//            state  <= WR_ADDR;
//          end
//        end

//        WR_ADDR: begin
//          HADDR  <= d_ptr;
//          HWRITE <= 1;
//          HTRANS <= 2'b10;   // NONSEQ write
//          // buffer already holds correct data
//          // HWDATA = buffer combinationally, so it is valid NOW
//          state  <= WR_DATA;
//        end

//        WR_DATA: begin
//          HTRANS <= 2'b00;
//          if (HREADY) begin
//            d_ptr <= d_ptr + 4;
//            if (count == 16'd1) begin
//              state <= DONE;
//            end else begin
//              count <= count - 1;
//              state <= RD_ADDR;
//            end
//          end
//        end

//        DONE: begin
//          HTRANS  <= 2'b00;
//          HWRITE  <= 0;
//          HBUSREQ <= 0;
//          irq     <= dma_ack;
//          dma_ack <= 0;
//          done    <= 1;
//          state   <= IDLE;
//        end

//        default: state <= IDLE;
//      endcase
//    end
//  end
//endmodule

`timescale 1ns / 1ps

module ahb_master #(
  parameter CH = 4, AW = 32, DW = 32
)(
  input  wire        HCLK, HRESETn,

  output reg  [AW-1:0] HADDR,
  output reg  [1:0]    HTRANS,
  output reg  [2:0]    HBURST, HSIZE,
  output reg           HWRITE,
  output wire [DW-1:0] HWDATA,

  input  wire [DW-1:0] HRDATA,
  input  wire          HREADY, HRESP,

  output reg           HBUSREQ,
  input  wire          HGRANT,

  input  wire [CH-1:0] grant,

  input  wire [AW-1:0] sar0, sar1, sar2, sar3,
  input  wire [AW-1:0] dar0, dar1, dar2, dar3,
  input  wire [15:0]   ctr0, ctr1, ctr2, ctr3,

  output reg [CH-1:0] dma_ack,
  output reg [CH-1:0] irq,
  output reg          done
);

  localparam IDLE    = 3'd0,
             RD_ADDR = 3'd1,
             RD_DATA = 3'd2,
             WR_ADDR = 3'd3,
             WR_DATA = 3'd4,
             DONE    = 3'd5;

  reg [2:0]    state;
  reg [AW-1:0] s_ptr, d_ptr;
  reg [15:0]   count, total_count;
  reg [DW-1:0] buffer;

  assign HWDATA = buffer;

  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      state   <= IDLE;
      HADDR   <= 0;
      HTRANS  <= 2'b00;
      HWRITE  <= 0;
      HBUSREQ <= 0;
      dma_ack <= 0;
      irq     <= 0;
      done    <= 0;
      HSIZE   <= 3'b010; // 32-bit
      HBURST  <= 3'b000;
      s_ptr   <= 0;
      d_ptr   <= 0;
      count   <= 0;
      total_count <= 0;
      buffer  <= 0;
    end else begin
      case (state)

        // =========================
        //IDLE
        // =========================
        IDLE: begin
          irq     <= 0;
          done    <= 0;
          dma_ack <= 0;
          HTRANS  <= 2'b00;
          HWRITE  <= 0;

          if (|grant && HGRANT) begin
            case (grant)
              4'b0001: begin s_ptr<=sar0; d_ptr<=dar0; count<=ctr0; total_count<=ctr0; end
              4'b0010: begin s_ptr<=sar1; d_ptr<=dar1; count<=ctr1; total_count<=ctr1; end
              4'b0100: begin s_ptr<=sar2; d_ptr<=dar2; count<=ctr2; total_count<=ctr2; end
              4'b1000: begin s_ptr<=sar3; d_ptr<=dar3; count<=ctr3; total_count<=ctr3; end
            endcase
            HBUSREQ <= 1;
            HBURST  <= 3'b001; // INCR burst ✅
            dma_ack <= grant;
            state   <= RD_ADDR;
          end
        end

        // =========================
        //READ ADDRESS
        // =========================
        RD_ADDR: begin
          HADDR  <= s_ptr;
          HWRITE <= 0;
          HTRANS <= (count == total_count) ? 2'b10 : 2'b11; // NONSEQ → SEQ ✅
          state  <= RD_DATA;
        end

        // =========================
        //READ DATA
        // =========================
        RD_DATA: begin
          if (HREADY) begin
            buffer <= HRDATA;
            s_ptr  <= s_ptr + 4;
            state  <= WR_ADDR;
          end
        end

        // =========================
        //WRITE ADDRESS
        // =========================
        WR_ADDR: begin
          HADDR  <= d_ptr;
          HWRITE <= 1;
          HTRANS <= (count == total_count) ? 2'b10 : 2'b11; // NONSEQ → SEQ ✅
          state  <= WR_DATA;
        end

        // =========================
        //WRITE DATA
        // =========================
        WR_DATA: begin
          if (HREADY) begin
            d_ptr <= d_ptr + 4;

            if (count == 16'd1) begin
              state <= DONE;
            end else begin
              count <= count - 1;
              state <= RD_ADDR;
            end
          end
        end

        // =========================
        
        // =========================
        DONE: begin
          HTRANS  <= 2'b00;
          HWRITE  <= 0;
          HBUSREQ <= 0;
          irq     <= dma_ack;
          dma_ack <= 0;
          done    <= 1;
          state   <= IDLE;
        end

        default: state <= IDLE;

      endcase
    end
  end

endmodule


