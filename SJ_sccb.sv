`timescale 1ns / 1ps



module top_SCCB (
    input  logic clk,
    input  logic reset,
    inout  wire  sda,
    output logic scl
);

    logic [15:0] romData;
    logic [ 7:0] rom_addr;

    OV7670_config_rom U_SCCB_ROM (
        .clk (clk),
        .addr(rom_addr),
        .dout(romData)
    );

    SCCB U_SCCB (
        .clk     (clk),
        .reset   (reset),
        .reg_addr(romData[15:8]),
        .data    (romData[7:0]),
        .rom_addr(rom_addr),
        .sda     (sda),
        .scl     (scl)
    );

    /*
    assign sda = (sda_dir) ? sda_out : 1'bz;

    always @(*) begin
        if (!sda_dir) begin
            in_data <= sda;
        end
    end
*/
endmodule


module SCCB (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] reg_addr,
    input  logic [7:0] data,
    output logic [7:0] rom_addr,
    inout  wire        sda,
    output logic       scl
);

    typedef enum logic [3:0] {
        IDLE,
        START,
        SEND_IP_ADDR,
        SEND_IP_ACK,
        SEND_ADDR,
        SEND_ADDR_ACK,
        SEND_DATA,
        SEND_DATA_ACK,
        STOP,
        FINISHED
    } state_t;



    state_t state, state_next;
    logic o_clk;
    logic scl_en_reg, scl_en_next;
    logic [3:0] i_reg, i_next;
    logic [7:0] ip_addr_reg, ip_addr_next;
    logic [7:0] reg_addr_reg, reg_addr_next;
    logic [7:0] data_reg, data_next;
    logic [7:0] rom_addr_reg, rom_addr_next;
    logic a_reg, a_next;

    logic [6:0] counter_next, counter_reg;
    logic sda_out_reg, sda_out_next, sda_dir_reg, sda_dir_next;
    logic tick;
    logic [9:0] p_counter;
    logic [6:0] stop_counter_reg, stop_counter_next;
    logic [7:0] new_counter_reg, new_counter_next;
    logic scl_en;

    assign scl = scl_en_reg ? o_clk : 1;
    assign sda = (sda_dir_reg) ? sda_out_reg : 1'bz;
    assign rom_addr = rom_addr_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            p_counter        <= 0;
            tick             <= 0;
            o_clk            <= 1'b0;
            counter_reg      <= 0;
            stop_counter_reg <= 0;
            new_counter_reg  <= 0;
            a_reg            <= 0;
            scl_en_reg       <= 0;
            sda_out_reg      <= 0;
            sda_dir_reg      <= 0;
        end else begin
            a_reg            <= a_next;
            scl_en_reg       <= scl_en_next;
            counter_reg      <= counter_next;
            stop_counter_reg <= stop_counter_next;
            new_counter_reg  <= new_counter_next;
            sda_out_reg      <= sda_out_next;
            sda_dir_reg      <= sda_dir_next;
            if (p_counter <= 500 - 1) begin
                tick  <= 0;
                o_clk <= 1'b0;
                if (a_reg) begin
                    p_counter <= 0;
                end else begin
                    p_counter <= p_counter + 1;
                end
                if (p_counter == 250 - 1) begin
                    tick <= 1;
                end
            end else if (p_counter <= 1000 - 1) begin
                tick  <= 0;
                o_clk <= 1'b1;
                if (a_reg) begin
                    p_counter <= 0;
                end else begin
                    p_counter <= p_counter + 1;
                end
                if (p_counter == 1000 - 1) begin
                    p_counter <= 0;
                end
            end
        end
    end

    always_ff @(posedge tick, posedge reset) begin
        if (reset) begin
            ip_addr_reg  <= 8'b0;
            reg_addr_reg <= 8'b0;
            data_reg     <= 8'b0;
            state        <= IDLE;
            i_reg        <= 0;
            rom_addr_reg <= 0;
        end else begin
            ip_addr_reg  <= ip_addr_next;
            reg_addr_reg <= reg_addr_next;
            data_reg     <= data_next;
            state        <= state_next;
            i_reg        <= i_next;
            rom_addr_reg <= rom_addr_next;
        end
    end

    always_comb begin
        ip_addr_next      = ip_addr_reg;
        reg_addr_next     = reg_addr_reg;
        data_next         = data_reg;
        state_next        = state;
        rom_addr_next     = rom_addr_reg;
        counter_next      = counter_reg;
        stop_counter_next = stop_counter_reg;
        new_counter_next  = new_counter_reg;
        a_next            = a_reg;
        i_next            = i_reg;
        scl_en_next       = scl_en_reg;
        sda_out_next      = sda_out_reg;
        sda_dir_next      = sda_dir_reg;
        case (state)
            IDLE: begin
                sda_out_next = 1'b1;
                sda_dir_next = 1'b1;
                i_next       = 0;
                scl_en       = 0;
                a_next       = 0;
                state_next   = START;
            end
            START: begin
                ip_addr_next      = 8'h42;
                reg_addr_next     = reg_addr;
                data_next         = data;
                state_next        = SEND_IP_ADDR;
                stop_counter_next = 0;
                new_counter_next  = 0;
                sda_dir_next      = 1'b1;
                sda_out_next      = 1'b0;
                if (scl) begin
                    counter_next = counter_reg + 1;
                    if (counter_reg == 99) begin
                        a_next = 1;
                    end
                    if (counter_reg == 101) begin
                        scl_en_next = 1;
                    end else begin
                    end
                end else begin
                    counter_next = 0;
                    a_next = 0;
                end
            end
            SEND_IP_ADDR: begin
                sda_dir_next = 1'b1;
                sda_out_next = ip_addr_reg[7];
                ip_addr_next = {ip_addr_reg[6:0], 1'b0};
                i_next       = i_reg + 1;
                if (i_reg == 7) begin
                    state_next = SEND_IP_ACK;
                    i_next = 0;
                    rom_addr_next = rom_addr_reg + 1;
                end
            end
            SEND_IP_ACK: begin
                sda_dir_next = 1'b0;
                state_next   = SEND_ADDR;
            end
            SEND_ADDR: begin
                sda_dir_next  = 1'b1;
                sda_out_next  = reg_addr_reg[7];
                reg_addr_next = {reg_addr_reg[6:0], 1'b0};
                i_next        = i_reg + 1;
                if (i_reg == 7) begin
                    state_next = SEND_ADDR_ACK;
                    i_next = 0;
                end
            end
            SEND_ADDR_ACK: begin
                sda_dir_next = 1'b0;
                state_next   = SEND_DATA;
            end
            SEND_DATA: begin
                sda_dir_next    = 1'b1;
                sda_out_next   = data_reg[7];
                data_next = {data_reg[6:0], 1'b0};
                i_next    = i_reg + 1;
                if (i_reg == 7) begin
                    state_next = SEND_DATA_ACK;
                    i_next = 0;
                end
            end
            SEND_DATA_ACK: begin
                sda_dir_next = 1'b0;
                state_next   = STOP;
            end
            STOP: begin
                sda_out_next = (stop_counter_reg == 100) ? 1 : 0;
                sda_dir_next = 1'b1;
                if (scl) begin
                    if (stop_counter_reg == 100) begin
                        scl_en_next = 0;
                    end else begin
                        stop_counter_next = stop_counter_reg + 1;
                    end
                end
                if (rom_addr == 78) begin
                    state_next = FINISHED;
                end else begin
                    state_next = START;
                end
            end
            FINISHED: begin
                sda_out_next = 1'b1;
                sda_dir_next = 1'b1;
            end
        endcase
    end
endmodule


module OV7670_config_rom (
    input logic clk,
    input logic [7:0] addr,
    output logic [15:0] dout
);

    //FFFF is end of rom, FFF0 is delay
    always @(posedge clk) begin
        case (addr)
            8'h00: dout <= 16'h1280; // COM7   Reset
            8'h01: dout <= 16'h1280; // COM7   Reset
            8'h02: dout <= 16'h1200; // COM7   Size & RGB output
            8'h03: dout <= 16'h1100; // CLKRC  Prescaler - Fin/(1+1)
            8'h04: dout <= 16'h0C00; // COM3   Enable scaling, all others off
            8'h05: dout <= 16'h3E00; // COM14  PCLK scaling off
            8'h06: dout <= 16'h8C00; // RGB444 Set RGB format
            8'h07: dout <= 16'h0400; // COM1   No CCIR601
            8'h08: dout <= 16'h4010; // COM15  Full 0-255 output, RGB 565
            8'h09: dout <= 16'h3A04; // TSLB   UV ordering, do not auto-reset window
            8'h0A: dout <= 16'h1438; // COM9   AGC Ceiling
            8'h0B: dout <= 16'h4FB3; // MTX1   Color conversion matrix
            8'h0C: dout <= 16'h50B3; // MTX2   Color conversion matrix
            8'h0D: dout <= 16'h5100; // MTX3   Color conversion matrix
            8'h0E: dout <= 16'h523D; // MTX4   Color conversion matrix
            8'h0F: dout <= 16'h53A7; // MTX5   Color conversion matrix
            8'h10: dout <= 16'h54E4; // MTX6   Color conversion matrix
            8'h11: dout <= 16'h589E; // MTXS   Matrix sign and auto contrast
            8'h12: dout <= 16'h3DC0; // COM13  Gamma and UV Auto adjust
            8'h13: dout <= 16'h1100; // CLKRC  Prescaler
            8'h14: dout <= 16'h1711; // HSTART HREF start
            8'h15: dout <= 16'h1861; // HSTOP  HREF stop
            8'h16: dout <= 16'h32A4; // HREF   Edge offset
            8'h17: dout <= 16'h1903; // VSTART VSYNC start
            8'h18: dout <= 16'h1A7B; // VSTOP  VSYNC stop
            8'h19: dout <= 16'h030A; // VREF   VSYNC low bits
            8'h1A: dout <= 16'h0E61; // COM5   Miscellaneous
            8'h1B: dout <= 16'h0F4B; // COM6   Miscellaneous
            8'h1C: dout <= 16'h1602;
            8'h1D: dout <= 16'h1E37; // MVFP   Flip and mirror image
            8'h1E: dout <= 16'h2102;
            8'h1F: dout <= 16'h2291;
            8'h20: dout <= 16'h2907;
            8'h21: dout <= 16'h330B;
            8'h22: dout <= 16'h350B;
            8'h23: dout <= 16'h371D;
            8'h24: dout <= 16'h3871;
            8'h25: dout <= 16'h392A;
            8'h26: dout <= 16'h3C78; // COM12
            8'h27: dout <= 16'h4D40;
            8'h28: dout <= 16'h4E20;
            8'h29: dout <= 16'h6900; // GFIX
            8'h2A: dout <= 16'h6B4A;
            8'h2B: dout <= 16'h7410;
            8'h2C: dout <= 16'h8D4F;
            8'h2D: dout <= 16'h8E00;
            8'h2E: dout <= 16'h8F00;
            8'h2F: dout <= 16'h9000;
            8'h30: dout <= 16'h9100;
            8'h31: dout <= 16'h9600;
            8'h32: dout <= 16'h9A00;
            8'h33: dout <= 16'hB084;
            8'h34: dout <= 16'hB10C;
            8'h35: dout <= 16'hB20E;
            8'h36: dout <= 16'hB382;
            8'h37: dout <= 16'hB80A;
            default: dout <= 16'hFFFF; // End marker
        endcase
    end
endmodule