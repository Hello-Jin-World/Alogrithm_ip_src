`timescale 1ns / 1ps


module top_VGA_CAMERA (
    input  logic       clk,
    input  logic       reset,
    input  logic       gray_sw,
    input  logic       depth2rgb_sw,
    input  logic       ssd_sad_select,
    input  logic       census_select,
    // SCCB interface signals
    output logic       SCL_L,
    inout  wire        SDA_L,
    output logic       SCL_R,
    inout  wire        SDA_R,
    // ov7670 camera input signals
    output logic       ov7670_xclk1,
    input  logic       ov7670_pclk1,
    input  logic       ov7670_href1,
    input  logic       ov7670_v_sync1,
    input  logic [7:0] ov7670_data1,

    output logic       ov7670_xclk2,
    input  logic       ov7670_pclk2,
    input  logic       ov7670_href2,
    input  logic       ov7670_v_sync2,
    input  logic [7:0] ov7670_data2,

    // VGA display output
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    // Internal signals
    logic disp_enable;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic we1, we2;
    logic [14:0] wAddr1, wAddr2;
    logic [15:0] wData1, wData2, buffer1, buffer2, buffer;
    logic qvga_en1, qvga_en2, qvga_en3;
    logic [14:0] qvga_addr1, qvga_addr2, qvga_addr3;
    logic vga_clk;
    logic [5:0] buffer3;

    logic [13:0] gray_rgb_L, gray_rgb_R;
    logic [13:0] gray_L, gray_R;

    // Disparity signal
    logic [15:0] depth_out, depth_rgb;
    // assign vgaRed   = (disp_enable) ? depth_out[15:12] : 0;
    // assign vgaGreen = (disp_enable) ? depth_out[10:7] : 0;
    // assign vgaBlue  = (disp_enable) ? depth_out[4:1] : 0;

    logic [13:0] average_gray;

    assign average_gray = (gray_L + gray_R) / 2;

    clk_wiz_0 U_clk_gene (
        // Clock out ports
        .vga_clk     (vga_clk),       // output vga_clk
        .ov7670_xclk1(ov7670_xclk1),  // output ov7670_xclk1
        .ov7670_xclk2(ov7670_xclk2),  // output ov7670_xclk2
        // Status and control signals
        .reset       (reset),         // input reset
        // Clock in ports
        .clk_in1     (clk)
    );  // input clk_in1

    rbt2gray U_rbt2gray (
        .color_rgb  ({depth_out[15:12], depth_out[10:7], depth_out[4:1]}),
        .gray_sw    (gray_sw),
        .disp_enable(disp_enable),
        .gray_rgb   ({vgaRed, vgaGreen, vgaBlue})
    );

    top_SCCB U_top_SCCB_L (
        .clk  (clk),
        .reset(reset),
        .sda  (SDA_L),
        .scl  (SCL_L)
    );
    top_SCCB U_top_SCCB_R (
        .clk  (clk),
        .reset(reset),
        .sda  (SDA_R),
        .scl  (SCL_R)
    );

    display_sel U_display_sel (
        .Left_Data(buffer1),
        .Right_Data(buffer2),
        .Disparity_Data(depth_rgb),
        .Average_Data({
            average_gray[13:9], average_gray[13:8], average_gray[13:9]
        }),
        .x(x_pixel),
        .y(y_pixel),
        .Out_Data(depth_out)
    );

    ov7670_SetData U_OV7670_SetDataLeft (
        .pclk       (ov7670_pclk1),
        .reset      (reset),
        .href       (ov7670_href1),
        .v_sync     (ov7670_v_sync1),
        .ov7670_data(ov7670_data1),
        .we         (we1),
        .wAddr      (wAddr1),
        .wData      (wData1)
    );

    ov7670_SetData U_OV7670_SetDataRight (
        .pclk       (ov7670_pclk2),
        .reset      (reset),
        .href       (ov7670_href2),
        .v_sync     (ov7670_v_sync2),
        .ov7670_data(ov7670_data2),
        .we         (we2),
        .wAddr      (wAddr2),
        .wData      (wData2)
    );


    frameBuffer U_FrameBufferLeft (
        // write side ov7670
        .wclk (ov7670_pclk1),
        .we   (we1),
        .wAddr(wAddr1),
        .wData(wData1),
        .rclk (vga_clk),
        .oe   (qvga_en1),
        .rAddr(qvga_addr1),
        .rData(buffer1)
    );

    frameBuffer U_FrameBufferRight (
        // write side ov7670
        .wclk (ov7670_pclk2),
        .we   (we2),
        .wAddr(wAddr2),
        .wData(wData2),
        .rclk (vga_clk),
        .oe   (qvga_en2),
        .rAddr(qvga_addr2),
        .rData(buffer2)
    );

    qvga_addr_decoder U_qvga_addr_decoder (
        .x         (x_pixel),
        .y         (y_pixel),
        .qvga_en1  (qvga_en1),
        .qvga_addr1(qvga_addr1),
        .qvga_en2  (qvga_en2),
        .qvga_addr2(qvga_addr2)
    );

    ////////////////////////////        Output VGA Signals            ////////////////////////////////////
    vga_controller U_vga_controller (
        .clk        (vga_clk),
        .reset      (reset),
        .h_sync     (Hsync),
        .v_sync     (Vsync),
        .x_pixel    (x_pixel),
        .y_pixel    (y_pixel),
        .disp_enable(disp_enable)
    );
    /////////////////////////////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////      For GrayScale Input       ////////////////////////////////////////
    rgb2gray U_rgb2gray_L (
        .color_rgb(buffer1),
        // .gray_sw  (crop_sw),
        .gray     (gray_L)
    );
    rgb2gray U_rgb2gray_R (
        .color_rgb(buffer2),
        // .gray_sw  (crop_sw),
        .gray     (gray_R)
    );
    /////////////////////////////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////           Algorithm          ////////////////////////////////////////
    SAD_SSD_CENSUS U_SAD_SSD_CENSUS (
        .clk           (vga_clk),
        .reset         (reset),
        .ssd_sad_select(ssd_sad_select),
        .census_select (census_select),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .in_L          (gray_L[13:3]),
        .in_R          (gray_R[13:3]),
        .rData         (buffer3)
    );
    /////////////////////////////////////////////////////////////////////////////////////////////////////


    ////////////////               Select Gray/Color Depthmap             ///////////////////////////////
    depth2rgb U_depth2rgb (
        .depth       (buffer3),
        .depth2rgb_sw(depth2rgb_sw),
        .rgb         (depth_rgb)
    );
    /////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule


module qvga_addr_decoder (
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    output logic        qvga_en1,
    output logic [14:0] qvga_addr1,
    output logic        qvga_en2,
    output logic [14:0] qvga_addr2
);

    always_comb begin
        if (y < 240) begin
            if (x >= 320) begin
                qvga_addr1 = y[9:1] * 160 + x[9:1];
                qvga_en1   = 1'b1;
                qvga_addr2 = 0;
                qvga_en2   = 1'b0;
            end else begin
                qvga_addr2 = y[9:1] * 160 + x[9:1];
                qvga_en2   = 1'b1;
                qvga_addr1 = 0;
                qvga_en1   = 1'b0;
            end
        end else begin
            if (x < 320) begin
                qvga_addr1 = (y[9:1] - 120) * 160 + x[9:1];
                qvga_en1   = 1'b1;
                qvga_addr2 = (y[9:1] - 120) * 160 + x[9:1];
                qvga_en2   = 1'b1;
            end else begin
                qvga_addr1 = (y[9:1] - 120) * 160 + x[9:1];
                qvga_en1   = 1'b1;
                qvga_addr2 = (y[9:1] - 120) * 160 + x[9:1];
                qvga_en2   = 1'b1;
            end
        end
    end
endmodule



module display_sel (
    input  logic [15:0] Left_Data,
    input  logic [15:0] Right_Data,
    input  logic [15:0] Disparity_Data,  // Added for disparity output
    input  logic [15:0] Average_Data,    // Added for disparity output
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    output logic [15:0] Out_Data
);

    always_comb begin

        if (y < 240) begin
            if (x >= 320) begin
                Out_Data = Left_Data;
            end else begin
                Out_Data = Right_Data;
            end
        end else begin
            if (x < 320) begin
                Out_Data = Disparity_Data;
            end else begin
                Out_Data = Average_Data;
            end
        end
    end
endmodule


module rbt2gray (
    input  logic [11:0] color_rgb,
    input  logic        gray_sw,
    input  logic        disp_enable,
    output logic [11:0] gray_rgb
);

    localparam RW = 8'h4c, GW = 8'h96, BW = 8'h1e;

    logic [11:0] gray;

    assign gray = color_rgb[11:8]*RW + color_rgb[7:4]*GW + color_rgb[3:0]*BW;
    // assign gray = (76*color_rgb[11:8] + 150*color_rgb[7:4] + 30*color_rgb[3:0]) / 256;

    assign gray_rgb = (disp_enable) ? ((gray_sw) ? {gray[11:8], gray[11:8], gray[11:8]} : color_rgb) : 12'd0;
endmodule

module rgb2gray (
    input  logic [15:0] color_rgb,
    output logic [13:0] gray
);

    localparam RW = 8'h47;  // weight for red
    localparam GW = 8'h96;  // weight for green
    localparam BW = 8'h1D;  // weight for blue


    assign gray = color_rgb[15:11]*RW + color_rgb[10:5]*GW + color_rgb[4:0]*BW;

endmodule

module depth2rgb (
    input  logic [ 5:0] depth,
    input  logic        depth2rgb_sw,
    output logic [15:0] rgb
);

    always_comb begin
        if (depth2rgb_sw) begin
            case (depth[5:2])
                4'd0: begin
                    rgb = {
                        4'b0000, 1'b1, 4'b0000, 2'b00, 4'b1111, 1'b1
                    };  // 진한 파란색
                end
                4'd1: begin
                    rgb = {
                        4'b0000, 1'b1, 4'b0011, 2'b00, 4'b1100, 1'b1
                    };  // 중간 파란색
                end
                4'd2: begin
                    rgb = {
                        4'b0000, 1'b1, 4'b0111, 2'b00, 4'b1100, 1'b1
                    };  // 옅은 파란색
                end
                4'd3: begin
                    rgb = {
                        4'b0000, 1'b1, 4'b1100, 2'b00, 4'b1111, 1'b1
                    };  // 청록색
                end
                4'd4: begin
                    rgb = {
                        4'b0000, 1'b1, 4'b1100, 2'b00, 4'b1100, 1'b1
                    };  // 옅은 청록색
                end
                4'd5: begin
                    rgb = {
                        4'b0011, 1'b1, 4'b1100, 2'b00, 4'b0000, 1'b1
                    };  // 연두색
                end
                4'd6: begin
                    rgb = {
                        4'b0000, 1'b1, 4'b1111, 2'b00, 4'b0000, 1'b1
                    };  // 녹색
                end
                4'd7: begin
                    rgb = {
                        4'b1000, 1'b1, 4'b1111, 2'b00, 4'b0000, 1'b1
                    };  // 초록-노랑
                end
                4'd8: begin
                    rgb = {
                        4'b1111, 1'b1, 4'b1111, 2'b00, 4'b0000, 1'b1
                    };  // 노란색
                end
                4'd9: begin
                    rgb = {
                        4'b1111, 1'b1, 4'b1100, 2'b00, 4'b0000, 1'b1
                    };  // 주황-노랑
                end
                4'd10: begin
                    rgb = {
                        4'b1111, 1'b1, 4'b0110, 2'b00, 4'b0000, 1'b1
                    };  // 옅은 주황색
                end
                4'd11: begin
                    rgb = {
                        4'b1111, 1'b1, 4'b0011, 2'b00, 4'b0000, 1'b1
                    };  // 주황색
                end
                4'd12: begin
                    rgb = {
                        4'b1111, 1'b1, 4'b0010, 2'b00, 4'b0000, 1'b1
                    };  // 붉은 주황색
                end
                4'd13: begin
                    rgb = {
                        4'b1111, 1'b1, 4'b0001, 2'b00, 4'b0000, 1'b1
                    };  // 연한 빨강색
                end
                4'd14: begin
                    rgb = {
                        4'b1111, 1'b1, 4'b0000, 2'b00, 4'b1000, 1'b1
                    };  // 중간 빨강색
                end
                4'd15: begin
                    rgb = {
                        4'b1111, 1'b1, 4'b0000, 2'b00, 4'b0000, 1'b1
                    };  // 진한 빨강색
                end
                default: begin
                    rgb = {
                        4'b0000, 1'b1, 4'b0000, 2'b00, 4'b0000, 1'b1
                    };  // 기본값: 검정색
                end
            endcase
        end else begin
            rgb = {
                depth[5:1], depth[5:0], depth[5:1]
            }; 
        end
    end

endmodule


