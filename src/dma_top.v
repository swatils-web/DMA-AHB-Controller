`timescale 1ns / 1ps

module dma_top #(
  parameter CH = 4,    // number of DMA channels
  parameter AW = 32,   // address width
  parameter DW = 32    // data width
)(
  input  wire        HCLK, HRESETn,

  // AHB Master port
  output wire [AW-1:0] HADDR,
  output wire [1:0]    HTRANS,
  output wire [2:0]    HBURST,
  output wire [2:0]    HSIZE,
  output wire          HWRITE,
  output wire [DW-1:0] HWDATA,
  input  wire [DW-1:0] HRDATA,
  input  wire          HREADY, HRESP,
  output wire          HBUSREQ,
  input  wire          HGRANT,

  // APB Slave port (CPU config)
  input  wire [11:0]   PADDR,
  input  wire          PSEL, PENABLE, PWRITE,
  input  wire [DW-1:0] PWDATA,
  output wire [DW-1:0] PRDATA,

  // DMA request lines from peripherals
  input  wire [CH-1:0] dma_req,
  output wire [CH-1:0] dma_ack,

  // Interrupt output
  output wire [CH-1:0] irq
);

  // Connection signals
  wire [AW-1:0] ch_sar_0, ch_sar_1, ch_sar_2, ch_sar_3;
  wire [AW-1:0] ch_dar_0, ch_dar_1, ch_dar_2, ch_dar_3;
  wire [15:0]   ch_ctr_0, ch_ctr_1, ch_ctr_2, ch_ctr_3;
  wire [CH-1:0] ch_grant;
  wire          done;

  // APB slave instance
  apb_slave #(.CH(CH), .AW(AW), .DW(DW)) U_APB (
    .PCLK(HCLK), .PRESETn(HRESETn),
    .PADDR(PADDR), .PSEL(PSEL), .PENABLE(PENABLE),
    .PWRITE(PWRITE), .PWDATA(PWDATA), .PRDATA(PRDATA),
    .sar0(ch_sar_0), .sar1(ch_sar_1), .sar2(ch_sar_2), .sar3(ch_sar_3),
    .dar0(ch_dar_0), .dar1(ch_dar_1), .dar2(ch_dar_2), .dar3(ch_dar_3),
    .ctr0(ch_ctr_0), .ctr1(ch_ctr_1), .ctr2(ch_ctr_2), .ctr3(ch_ctr_3)
  );

  // Arbiter instance
  arbiter #(.CH(CH)) U_ARB (
    .clk(HCLK),
    .rst_n(HRESETn),
    .req(dma_req),
    .done(done),
    .grant(ch_grant)
  );

  // AHB master instance
  ahb_master #(.CH(CH), .AW(AW), .DW(DW)) U_AHB (
    .HCLK(HCLK), .HRESETn(HRESETn),
    .HADDR(HADDR), .HTRANS(HTRANS), .HBURST(HBURST),
    .HSIZE(HSIZE), .HWRITE(HWRITE),
    .HWDATA(HWDATA), .HRDATA(HRDATA),
    .HREADY(HREADY), .HRESP(HRESP),
    .HBUSREQ(HBUSREQ), .HGRANT(HGRANT),
    .grant(ch_grant),
    .sar0(ch_sar_0), .sar1(ch_sar_1), .sar2(ch_sar_2), .sar3(ch_sar_3),
    .dar0(ch_dar_0), .dar1(ch_dar_1), .dar2(ch_dar_2), .dar3(ch_dar_3),
    .ctr0(ch_ctr_0), .ctr1(ch_ctr_1), .ctr2(ch_ctr_2), .ctr3(ch_ctr_3),
    .dma_ack(dma_ack), .irq(irq),
    .done(done)
  );

endmodule