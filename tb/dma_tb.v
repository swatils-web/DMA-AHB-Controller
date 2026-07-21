`timescale 1ns / 1ps

module dma_tb;

    parameter AW = 32;
    parameter DW = 32;
    parameter CH = 4;

    // Clock & Reset
    reg HCLK = 0;
    reg HRESETn = 0;

    // APB
    reg  [11:0] PADDR;
    reg         PSEL, PENABLE, PWRITE;
    reg  [DW-1:0] PWDATA;
    wire [DW-1:0] PRDATA;

    // DMA
    reg  [CH-1:0] dma_req;
    wire [CH-1:0] dma_ack;
    wire [CH-1:0] irq;

    // AHB
    wire [AW-1:0] HADDR;
    wire [1:0]    HTRANS;
    wire [2:0]    HBURST, HSIZE;
    wire          HWRITE;
    wire [DW-1:0] HWDATA;
    reg  [DW-1:0] HRDATA;
    reg           HREADY = 1;
    reg           HRESP  = 0;
    wire          HBUSREQ;
    reg           HGRANT = 1;

    // Memory array
    reg [DW-1:0] mem [0:1023];

    // Pipeline registers for write channel
    reg [AW-1:0] addr_pipe;
    reg          write_pipe;
    reg [1:0]    trans_pipe;

    // Clock generation
    always #5 HCLK = ~HCLK;

    // DUT
    dma_top #(.CH(CH), .AW(AW), .DW(DW)) U_DUT (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .HADDR(HADDR), .HTRANS(HTRANS), .HBURST(HBURST), .HSIZE(HSIZE),
        .HWRITE(HWRITE), .HWDATA(HWDATA), .HRDATA(HRDATA),
        .HREADY(HREADY), .HRESP(HRESP),
        .HBUSREQ(HBUSREQ), .HGRANT(HGRANT),
        .PADDR(PADDR), .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE),
        .PWDATA(PWDATA), .PRDATA(PRDATA),
        .dma_req(dma_req), .dma_ack(dma_ack), .irq(irq)
    );

    // =========================================================
    // READ DATA PATH
    // KEY FIX: Drive HRDATA directly and combinationally from
    // HADDR. No registered intermediate.
    // This ensures the master always gets correct data in RD_DATA.
    // =========================================================
    always @(*) begin
        if (!HWRITE && (HTRANS == 2'b10 || HTRANS == 2'b11))
            HRDATA = mem[HADDR[11:2]];
        else
            HRDATA = 32'h0;
    end

    // =========================================================
    // WRITE DATA PATH
    // Pipeline: Capture address/control in address phase,
    // then write mem in data phase using pipelined signals.
    // =========================================================
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_pipe  <= 0;
            write_pipe <= 0;
            trans_pipe <= 0;
        end else if (HREADY) begin
            // Data phase: use previously captured address/control
            if (write_pipe && (trans_pipe == 2'b10 || trans_pipe == 2'b11)) begin
                mem[addr_pipe[11:2]] <= HWDATA;
                $display("TB_WRITE: Addr=%h Data=%h Time=%0t",
                          addr_pipe, HWDATA, $time);
            end

            // Capture current address phase for next cycle
            addr_pipe  <= HADDR;
            write_pipe <= HWRITE;
            trans_pipe <= HTRANS;
        end
    end

    // =========================================================
    // STIMULUS
    // =========================================================
    integer i;

    initial begin
        HRESETn = 0;
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;
        dma_req = 0;

        // Clear all memory
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'h0;

        // Initialize source: addresses 0x400 to 0x43C
        // (mem[256] to mem[271])
        for (i = 0; i < 16; i = i + 1) begin
            mem[256 + i] = 32'hA000_0000 + i;
            $display("TB_INIT: mem[%0d] = %h", 256+i, mem[256+i]);
        end

        // Reset sequence
        #50 HRESETn = 1;
        repeat(5) @(posedge HCLK);

        // Configure DMA Channel 0 via APB
        apb_write(12'h000, 32'h0000_0400); // SAR0 = 0x400
        apb_write(12'h004, 32'h0000_0800); // DAR0 = 0x800
        apb_write(12'h008, 32'h0000_0010); // CTR0 = 16 words

        // Assert DMA request
        @(posedge HCLK);
        dma_req = 4'b0001;
        $display("TB_INFO: DMA request asserted at time %0t", $time);

        fork
            begin
                // Wait for IRQ
                wait(irq[0] === 1'b1);
                $display("TB_INFO: IRQ received at time %0t", $time);
                dma_req = 4'b0000;

                // Small settling delay
                repeat(5) @(posedge HCLK);

                // Verify destination memory
                $display("--- VERIFICATION ---");
                for (i = 0; i < 16; i = i + 1) begin
                    $display("mem[%0d] Addr=%h Got=%h Expected=%h %s",
                        512+i,
                        32'h800 + i*4,
                        mem[512+i],
                        32'hA000_0000 + i,
                        (mem[512+i] === (32'hA000_0000+i)) ? "PASS" : "FAIL"
                    );
                    if (mem[512+i] !== (32'hA000_0000 + i)) begin
                        $display("FAIL at index %0d", i);
                        $finish;
                    end
                end

                $display("ALL PASS: DMA transfer verified successfully!");
                #50 $finish;
            end

            begin
                #20000;
                $display("TIMEOUT ERROR at time %0t", $time);
                $finish;
            end
        join
    end

    // APB Write Task
    task apb_write(input [11:0] addr, input [31:0] data);
        begin
            @(posedge HCLK);
            PSEL   = 1;
            PADDR  = addr;
            PWRITE = 1;
            PWDATA = data;
            @(posedge HCLK);
            PENABLE = 1;
            @(posedge HCLK);
            PSEL    = 0;
            PENABLE = 0;
            PWRITE  = 0;
        end
    endtask

endmodule