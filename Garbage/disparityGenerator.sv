`timescale 1ns / 1ps

module disparity_generator_1x1 (
    input  logic        clk,
    input  logic        reset,
    input  logic        Hsync,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [15:0] in_L,
    input  logic [15:0] in_R,
    output logic [ 5:0] rData
);
    localparam IDLE = 0, COMP = 1;

    logic [5:0] mem_L[0:159];
    logic [5:0] mem_R[0:159];

    logic [1:0] state_reg, state_next;
    logic read_en_reg, read_en_next;
    logic [5:0] temp1, temp2, temp3, temp4, temp5, temp_min;
    logic [5:0] temp_mem[0:160-1];

    // logic [6:0]  min_temp, min_index, i, temp;

    assign rData = temp_mem[x_pixel[9:2]];

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state_reg   <= 0;
            read_en_reg <= 1;
        end else begin
            state_reg   <= state_next;
            read_en_reg <= read_en_next;
            if (read_en_reg == 1'b1) begin
                mem_L[x_pixel[9:2]] <= in_L[15:10];
                mem_R[x_pixel[9:2]] <= in_R[15:10];
            end
        end
    end

    always_comb begin
        state_next   = state_reg;
        read_en_next = read_en_reg;
        case (state_reg)
            IDLE: begin
                if (x_pixel >= 159) begin
                    state_next   = COMP;
                    read_en_next = 0;
                end
            end
            COMP: begin

                // for (int j = 0; j < 160; j++) begin
                //     min_temp = 127;
                //     min_index = 0;

                //     for (i = 0; i < 7; i++) begin
                //         temp = (mem_L[j] > mem_R[j+i]) ? (mem_L[j] - mem_R[j+i]) : (mem_R[j+i] - mem_L[j]);
                //         if (temp < min_temp) begin
                //             min_temp  = temp;
                //             min_index = i;
                //         end
                //     end

                //     case (min_index)
                //         0: temp_mem[j] = 0;
                //         1: temp_mem[j] = 10;
                //         2: temp_mem[j] = 25;
                //         3: temp_mem[j] = 40;
                //         4: temp_mem[j] = 63;
                //         default: temp_mem[j] = 63;
                //     endcase
                // end

                // for (int j = 0; j < 160; j++) begin
                //     temp1 = (mem_L[j] > mem_R[j])   ? (mem_L[j] - mem_R[j])   : (mem_R[j] - mem_L[j]);
                //     temp2 = (mem_L[j] > mem_R[j+1]) ? (mem_L[j] - mem_R[j+1]) : (mem_R[j+1] - mem_L[j]);
                //     temp3 = (mem_L[j] > mem_R[j+2]) ? (mem_L[j] - mem_R[j+2]) : (mem_R[j+2] - mem_L[j]);
                //     temp4 = (mem_L[j] > mem_R[j+3]) ? (mem_L[j] - mem_R[j+3]) : (mem_R[j+3] - mem_L[j]);
                //     temp5 = (mem_L[j] > mem_R[j+4]) ? (mem_L[j] - mem_R[j+4]) : (mem_R[j+4] - mem_L[j]);

                //     temp_min = temp1;

                //     if (temp2 < temp_min) temp_min = temp2;
                //     if (temp3 < temp_min) temp_min = temp3;
                //     if (temp4 < temp_min) temp_min = temp4;
                //     if (temp5 < temp_min) temp_min = temp5;

                //     if (temp_min == temp1) begin
                //         // temp_mem[j] = 630 * 0.1 / 1;
                //         temp_mem[j] = 63;
                //     end else if (temp_min == temp2) begin
                //         // temp_mem[j] = 630 * 0.1 / 2;
                //         temp_mem[j] = 40;
                //     end else if (temp_min == temp3) begin
                //         // temp_mem[j] = 630 * 0.1 / 3;
                //         temp_mem[j] = 25;
                //     end else if (temp_min == temp4) begin
                //         // temp_mem[j] = 630 * 0.1 / 4;
                //         temp_mem[j] = 10;
                //     end else begin
                //         // temp_mem[j] = 630 * 0.1 / 5;
                //         temp_mem[j] = 0;
                //     end
                // end


                for (int j = 0; j < 160; j++) begin
                    temp1 = (mem_L[j] > mem_R[j]) ? (mem_L[j] - mem_R[j]) : (mem_R[j] - mem_L[j]); // Right data' 1st data. 
                    temp2 = (mem_L[j] > mem_R[j+1]) ? (mem_L[j] - mem_R[j+1]) : (mem_R[j+1] - mem_L[j]);       // i
                    temp3 = (mem_L[j] > mem_R[j+2]) ? (mem_L[j] - mem_R[j+2]) : (mem_R[j+2] - mem_L[j]);       // i
                    temp4 = (mem_L[j] > mem_R[j+3]) ? (mem_L[j] - mem_R[j+3]) : (mem_R[j+3] - mem_L[j]);       // i
                    temp5 = (mem_L[j] > mem_R[j+4]) ? (mem_L[j] - mem_R[j+4]) : (mem_R[j+4] - mem_L[j]);       // i

                    if (temp1 < temp2) begin
                        if (temp1 < temp3) begin
                            if (temp1 < temp4) begin
                                if (temp1 < temp5) begin
                                    temp_mem[j] = 0;
                                end else begin
                                    temp_mem[j] = 63;
                                end
                            end else begin
                                if (temp4 < temp5) begin
                                    temp_mem[j] = 40;
                                end else begin
                                    temp_mem[j] = 63;
                                end
                            end
                        end else begin
                            if (temp3 < temp4) begin
                                if (temp3 < temp5) begin
                                    temp_mem[j] = 25;
                                end else begin
                                    temp_mem[j] = 63;
                                end
                            end else begin
                                if (temp4 < temp5) begin
                                    temp_mem[j] = 40;
                                end else begin
                                    temp_mem[j] = 63;
                                end
                            end
                        end
                    end else begin
                        if (temp2 < temp3) begin
                            if (temp2 < temp4) begin
                                if (temp2 < temp5) begin
                                    temp_mem[j] = 10;
                                end else begin
                                    temp_mem[j] = 63;
                                end
                            end else begin
                                if (temp4 < temp5) begin
                                    temp_mem[j] = 40;
                                end else begin
                                    temp_mem[j] = 63;
                                end
                            end
                        end else begin
                            if (temp3 < temp4) begin
                                if (temp3 < temp5) begin
                                    temp_mem[j] = 25;
                                end else begin
                                    temp_mem[j] = 63;
                                end
                            end else begin
                                if (temp4 < temp5) begin
                                    temp_mem[j] = 40;
                                end else begin
                                    temp_mem[j] = 63;
                                end
                            end
                        end
                    end
                end
                state_next   = IDLE;
                read_en_next = 1;
            end
        endcase
    end


endmodule

module disparity_generator_3x3 (
    input  logic        clk,
    input  logic        reset,
    input  logic        Hsync,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [15:0] in_L,
    input  logic [15:0] in_R,
    output logic [ 5:0] addr,
    output logic [ 5:0] rData
);
    localparam IDLE = 0, COMP = 1;

    logic [5:0] mem_L[0:2][0:159];
    logic [5:0] mem_R[0:2][0:159];

    logic state_reg, state_next;
    logic read_en_reg, read_en_next;
    logic [11:0] window[4:0];
    logic [5:0] window1;
    logic [5:0] window2;
    logic [5:0] window3;
    logic [5:0] window4;
    logic [5:0] window5;
    logic [5:0] window6;
    logic [5:0] window7;
    logic [5:0] window8;
    logic [5:0] window9;
    logic [5:0] min_temp;
    logic [5:0] temp_mem[0:160-1];

    logic [7:0] j, j_next;
    logic [7:0] k, k_next;
    logic [5:0] result;

    assign rData = temp_mem[x_pixel[9:2]];

    // assign rData = result;
    assign addr = j;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state_reg   <= 0;
            read_en_reg <= 1;
            j           <= 0;
        end else begin
            state_reg   <= state_next;
            read_en_reg <= read_en_next;
            j           <= j_next;
            if (read_en_reg == 1'b1) begin
                mem_L[y_pixel[9:2]%3][x_pixel[9:2]] <= in_L[15:10];
                mem_R[y_pixel[9:2]%3][x_pixel[9:2]] <= in_R[15:10];
            end
            temp_mem[j] <= result;
        end
    end

    always_comb begin
        state_next   = state_reg;
        read_en_next = read_en_reg;
        j_next       = j;
        case (state_reg)
            IDLE: begin
                if (x_pixel[9:1] >= 159) begin
                    state_next   = COMP;
                    read_en_next = 0;
                end
            end
            COMP: begin
                // i ===== y                j ======= x
                for (int i = 0; i < 5; i++) begin
                    window1 = (mem_L[0][j-1] > mem_R[0][j-1+i]) ? (mem_L[0][j-1] - mem_R[0][j-1+i]) : (mem_R[0][j-1+i] - mem_L[0][j-1]);
                    window2 = (mem_L[0][j]   > mem_R[0][j+i])   ? (mem_L[0][j]   - mem_R[0][j+i])   : (mem_R[0][j+i]   - mem_L[0][j]);
                    window3 = (mem_L[0][j+1] > mem_R[0][j+1+i]) ? (mem_L[0][j+1] - mem_R[0][j+1+i]) : (mem_R[0][j+1+i] - mem_L[0][j+1]);

                    window4 = (mem_L[1][j-1] > mem_R[1][j-1+i]) ? (mem_L[1][j-1] - mem_R[1][j-1+i]) : (mem_R[1][j-1+i] - mem_L[1][j-1]);
                    window5 = (mem_L[1][j]   > mem_R[1][j+i])   ? (mem_L[1][j]   - mem_R[1][j+i])   : (mem_R[1][j+i]   - mem_L[1][j]);
                    window6 = (mem_L[1][j+1] > mem_R[1][j+1+i]) ? (mem_L[1][j+1] - mem_R[1][j+1+i]) : (mem_R[1][j+1+i] - mem_L[1][j+1]);

                    window7 = (mem_L[2][j-1] > mem_R[2][j-1+i]) ? (mem_L[2][j-1] - mem_R[2][j-1+i]) : (mem_R[2][j-1+i] - mem_L[2][j-1]);
                    window8 = (mem_L[2][j]   > mem_R[2][j+i])   ? (mem_L[2][j]   - mem_R[2][j+i])   : (mem_R[2][j+i]   - mem_L[2][j]);
                    window9 = (mem_L[2][j+1] > mem_R[2][j+1+i]) ? (mem_L[2][j+1] - mem_R[2][j+1+i]) : (mem_R[2][j+1+i] - mem_L[2][j+1]);
                    window[i] = window1 + window2 + window3 + window4 + window5 + window6 + window7 + window8 + window9;
                end

                if (window[0] < window[1]) begin
                    if (window[0] < window[2]) begin
                        if (window[0] < window[3]) begin
                            if (window[0] < window[4]) begin
                                result = 63;
                            end else begin
                                result = 0;
                            end
                        end else begin
                            if (window[3] < window[4]) begin
                                result = 14;
                            end else begin
                                result = 0;
                            end
                        end
                    end else begin
                        if (window[2] < window[3]) begin
                            if (window[2] < window[4]) begin
                                result = 43;
                            end else begin
                                result = 0;
                            end
                        end else begin
                            if (window[3] < window[4]) begin
                                result = 14;
                            end else begin
                                result = 0;
                            end
                        end
                    end
                end else begin
                    if (window[1] < window[2]) begin
                        if (window[1] < window[3]) begin
                            if (window[1] < window[4]) begin
                                result = 27;
                            end else begin
                                result = 0;
                            end
                        end else begin
                            if (window[3] < window[4]) begin
                                result = 14;
                            end else begin
                                result = 0;
                            end
                        end
                    end else begin
                        if (window[2] < window[3]) begin
                            if (window[2] < window[4]) begin
                                result = 43;
                            end else begin
                                result = 0;
                            end
                        end else begin
                            if (window[3] < window[4]) begin
                                result = 14;
                            end else begin
                                result = 0;
                            end
                        end
                    end
                end
                if (j == 159) begin
                    j_next       = 0;
                    state_next   = IDLE;
                    read_en_next = 1;
                end else begin
                    j_next     = j + 1;
                    state_next = COMP;
                end
            end
        endcase
    end

    //  COMP: begin
    //             for (int j = 0; j < 160; j++) begin
    //                 temp1 = (mem_L[j] > mem_R[j]) ? (mem_L[j] - mem_R[j]) : (mem_R[j] - mem_L[j]); // Right data' 1st data. 
    //                 temp2 = (mem_L[j] > mem_R[j+1]) ? (mem_L[j] - mem_R[j+1]) : (mem_R[j+1] - mem_L[j]);       // i
    //                 temp3 = (mem_L[j] > mem_R[j+2]) ? (mem_L[j] - mem_R[j+2]) : (mem_R[j+2] - mem_L[j]);       // i
    //                 temp4 = (mem_L[j] > mem_R[j+3]) ? (mem_L[j] - mem_R[j+3]) : (mem_R[j+3] - mem_L[j]);       // i
    //                 temp5 = (mem_L[j] > mem_R[j+4]) ? (mem_L[j] - mem_R[j+4]) : (mem_R[j+4] - mem_L[j]);       // i

    //                 if (temp1 < temp2) begin
    //                     if (temp1 < temp3) begin
    //                         if (temp1 < temp4) begin
    //                             if (temp1 < temp5) begin
    //                                 temp_mem[j] = 0;
    //                             end else begin
    //                                 temp_mem[j] = 63;
    //                             end
    //                         end else begin
    //                             if (temp4 < temp5) begin
    //                                 temp_mem[j] = 40;
    //                             end else begin
    //                                 temp_mem[j] = 63;
    //                             end
    //                         end
    //                     end else begin
    //                         if (temp3 < temp4) begin
    //                             if (temp3 < temp5) begin
    //                                 temp_mem[j] = 25;
    //                             end else begin
    //                                 temp_mem[j] = 63;
    //                             end
    //                         end else begin
    //                             if (temp4 < temp5) begin
    //                                 temp_mem[j] = 40;
    //                             end else begin
    //                                 temp_mem[j] = 63;
    //                             end
    //                         end
    //                     end
    //                 end else begin
    //                     if (temp2 < temp3) begin
    //                         if (temp2 < temp4) begin
    //                             if (temp2 < temp5) begin
    //                                 temp_mem[j] = 10;
    //                             end else begin
    //                                 temp_mem[j] = 63;
    //                             end
    //                         end else begin
    //                             if (temp4 < temp5) begin
    //                                 temp_mem[j] = 40;
    //                             end else begin
    //                                 temp_mem[j] = 63;
    //                             end
    //                         end
    //                     end else begin
    //                         if (temp3 < temp4) begin
    //                             if (temp3 < temp5) begin
    //                                 temp_mem[j] = 25;
    //                             end else begin
    //                                 temp_mem[j] = 63;
    //                             end
    //                         end else begin
    //                             if (temp4 < temp5) begin
    //                                 temp_mem[j] = 40;
    //                             end else begin
    //                                 temp_mem[j] = 63;
    //                             end
    //                         end
    //                     end
    //                 end
    //             end
    //             state_next   = WAIT;
    //             read_en_next = 1;
    //         end

endmodule

// module disparity_generator (
//     input  logic        clk,
//     input  logic        reset,
//     // input  logic        Hsync,
//     // write side
//     input  logic        wclk1,
//     input  logic        we1,
//     input  logic [14:0] wAddr1,
//     input  logic [15:0] wData1,
//     // write side
//     input  logic        wclk2,
//     input  logic        we2,
//     input  logic [14:0] wAddr2,
//     input  logic [15:0] wData2,
//     // read side for VGA
//     input  logic        rclk,
//     input  logic        oe,
//     input  logic [14:0] rAddr,
//     output logic [ 5:0] rData
// );
//     logic [5:0] mem_L[0:160-1];
//     logic [5:0] mem_R[0:160-1];

//     logic [5:0] prv_mem_L[0:160-1];
//     logic [5:0] prv_mem_R[0:160-1];

//     logic state_reg, state_next;
//     logic read_en_reg, read_en_next;
//     logic [5:0] temp1;
//     logic [5:0] temp2;
//     logic [5:0] temp3;
//     logic [5:0] temp4;
//     logic [5:0] temp5;
//     logic [5:0] temp_mem[0:160-1];
//     // logic [6:0] j_reg, j_next;


//     localparam IDLE = 0, STATE0 = 1;

//     always_ff @(posedge rclk) begin
//         if (oe && read_en_reg) begin
//             rData <= temp_mem[rAddr];
//         end else begin
//             rData <= 0;
//         end
//     end

//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             state_reg   <= 0;
//             read_en_reg <= 0;
//             temp1       <= 0;
//             temp2       <= 0;
//             temp3       <= 0;
//             temp4       <= 0;
//             temp5       <= 0;
//             // j_reg       <= 0;
//         end else begin
//             state_reg   <= state_next;
//             read_en_reg <= read_en_next;
//             // j_reg       <= j_next;
//         end
//     end

//     always_ff @(posedge wclk1) begin
//         if (we1) begin
//             mem_L[wAddr1%160] <= wData1[12:7];
//         end
//     end

//     always_ff @(posedge wclk2) begin
//         if (we2) begin
//             mem_R[wAddr2%160] <= wData2[12:7];
//         end
//     end

//     always_comb begin
//         state_next   = state_reg;
//         read_en_next = read_en_reg;
//         // j_next       = j_reg;
//         case (state_reg)
//             IDLE: begin

//                 if (wAddr1 % 159 == 0 && wAddr1 > 0 && wAddr2 % 159 == 0) begin
//                     state_next   = STATE0;
//                     read_en_next = 0;
//                 end
//                 // if (j_reg == 1)
//                 // focal length * baseline / disparity = z() (depth)
//             end
//             STATE0: begin
//                 for (int j = 0; j < 160; j++) begin
//                     temp1 = (mem_L[j] > prv_mem_R[j]) ? (mem_L[j] - mem_R[j]) : (mem_R[j] - mem_L[j]); // Right data' 1st data. 
//                     temp2 = (mem_L[j] > mem_R[j+1]) ? (mem_L[j] - mem_R[j+1]) : (mem_R[j+1] - mem_L[j]);       // i
//                     temp3 = (mem_L[j] > mem_R[j+2]) ? (mem_L[j] - mem_R[j+2]) : (mem_R[j+2] - mem_L[j]);       // i
//                     temp4 = (mem_L[j] > mem_R[j+3]) ? (mem_L[j] - mem_R[j+3]) : (mem_R[j+3] - mem_L[j]);       // i
//                     temp5 = (mem_L[j] > mem_R[j+4]) ? (mem_L[j] - mem_R[j+4]) : (mem_R[j+4] - mem_L[j]);       // i

//                     if (temp1 < temp2) begin
//                         if (temp1 < temp3) begin
//                             if (temp1 < temp4) begin
//                                 if (temp1 < temp5) begin
//                                     temp_mem[j] = 600 * 0.1 / 1;
//                                 end else begin
//                                     temp_mem[j] = 600 * 0.1 / 5;
//                                 end
//                             end else begin
//                                 if (temp4 < temp5) begin
//                                     temp_mem[j] = 600 * 0.1 / 4;
//                                 end else begin
//                                     temp_mem[j] = 600 * 0.1 / 5;
//                                 end
//                             end
//                         end else begin
//                             if (temp3 < temp4) begin
//                                 if (temp3 < temp5) begin
//                                     temp_mem[j] = 600 * 0.1 / 3;
//                                 end else begin
//                                     temp_mem[j] = 600 * 0.1 / 5;
//                                 end
//                             end else begin
//                                 if (temp4 < temp5) begin
//                                     temp_mem[j] = 600 * 0.1 / 4;
//                                 end else begin
//                                     temp_mem[j] = 600 * 0.1 / 5;
//                                 end
//                             end
//                         end
//                     end else begin
//                         if (temp2 < temp3) begin
//                             if (temp2 < temp4) begin
//                                 if (temp2 < temp5) begin
//                                     temp_mem[j] = 600 * 0.1 / 2;
//                                 end else begin
//                                     temp_mem[j] = 600 * 0.1 / 5;
//                                 end
//                             end else begin
//                                 if (temp4 < temp5) begin
//                                     temp_mem[j] = 600 * 0.1 / 4;
//                                 end else begin
//                                     temp_mem[j] = 600 * 0.1 / 5;
//                                 end
//                             end
//                         end else begin
//                             if (temp3 < temp4) begin
//                                 if (temp3 < temp5) begin
//                                     temp_mem[j] = 600 * 0.1 / 3;
//                                 end else begin
//                                     temp_mem[j] = 600 * 0.1 / 5;
//                                 end
//                             end else begin
//                                 if (temp4 < temp5) begin
//                                     temp_mem[j] = 600 * 0.1 / 4;
//                                 end else begin
//                                     temp_mem[j] = 600 * 0.1 / 5;
//                                 end
//                             end
//                         end
//                     end
//                 end
//                 // j_next = j_reg + 1;
//                 // if (!Hsync) begin
//                     state_next   = IDLE;
//                     read_en_next = 1;
//                 // end
//             end
//         endcase
//     end
// endmodule

// module disparity_generator (
//     input  logic        clk,
//     input  logic        reset,
//     input  logic        Hsync,
//     // write side
//     input  logic        wclk1,
//     input  logic        we1,
//     input  logic [14:0] wAddr1,
//     input  logic [15:0] wData1,
//     // write side
//     input  logic        wclk2,
//     input  logic        we2,
//     input  logic [14:0] wAddr2,
//     input  logic [15:0] wData2,
//     // read side for VGA
//     input  logic        rclk,
//     input  logic        oe,
//     input  logic [14:0] rAddr,
//     output logic [ 5:0] rData
// );
//     logic [5:0] mem_L[0:160-1];
//     logic [5:0] mem_R[0:160-1];

//     logic [5:0] prv_mem_L[0:160-1];
//     logic [5:0] prv_mem_R[0:160-1];

//     logic [1:0] state_reg, state_next;
//     // logic read_en_reg, read_en_next;
//     logic [5:0] temp1, temp1_next;
//     logic [5:0] temp2, temp2_next;
//     logic [5:0] temp3, temp3_next;
//     logic [5:0] temp4, temp4_next;
//     logic [5:0] temp5, temp5_next;
//     logic [5:0] result;
//     logic [5:0] temp_mem[0:160*120-1];
//     logic [7:0] j_reg, j_next;
//     logic [6:0] k_reg, k_next;

//     ila_0 U_ila_0 (
//         .clk    (clk),                        // input wire clk
//         .probe0 (wclk1),                      // input wire [0:0]  probe0  
//         .probe1 (wAddr1),                     // input wire [14:0]  probe1 
//         .probe2 (wData1),                     // input wire [15:0]  probe2 
//         .probe3 (wclk2),                      // input wire [0:0]  probe3 
//         .probe4 (wAddr2),                     // input wire [14:0]  probe4 
//         .probe5 (wData2),                     // input wire [15:0]  probe5 
//         .probe6 (rclk),                       // input wire [0:0]  probe6 
//         .probe7 (oe),                         // input wire [0:0]  probe7 
//         .probe8 (rAddr),                      // input wire [14:0]  probe8 
//         .probe9 (rData),                      // input wire [5:0]  probe9 
//         .probe10(mem_L[wAddr1%160]),          // input wire [5:0]  probe10 
//         .probe11(mem_R[wAddr2%160]),          // input wire [5:0]  probe11 
//         .probe12(prv_mem_L[wAddr1%160]),      // input wire [5:0]  probe12 
//         .probe13(prv_mem_R[wAddr2%160]),      // input wire [5:0]  probe13 
//         .probe14(state_reg),                  // input wire [1:0]  probe14 
//         .probe15(read_en_reg),                // input wire [0:0]  probe15
//         .probe16(temp_mem[j_reg+k_reg*160]),  // input wire [5:0]  probe16 
//         .probe17({8'd0, k_reg}),              // input wire [14:0]  probe17 
//         .probe18(j_reg)                       // input wire [7:0]  probe18
//     );


//     localparam IDLE0 = 0, IDLE1 = 1, STATE0 = 2, STATE1 = 3;


//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             state_reg <= 0;
//             temp1     <= 0;
//             temp2     <= 0;
//             temp3     <= 0;
//             temp4     <= 0;
//             temp5     <= 0;
//             result    <= 0;
//             j_reg     <= 0;
//             k_reg     <= 0;
//         end else begin
//             state_reg <= state_next;
//             j_reg     <= j_next;
//             k_reg     <= k_next;
//             temp1     <= temp1_next;
//             temp2     <= temp2_next;
//             temp3     <= temp3_next;
//             temp4     <= temp4_next;
//             temp5     <= temp5_next;
//         end
//     end


//     always_ff @(posedge wclk1) begin
//         if (we1) begin
//             mem_L[wAddr1%160] <= wData1[13:8];
//         end
//     end

//     always_ff @(posedge wclk2) begin
//         if (we2) begin
//             mem_R[wAddr2%160] <= wData2[13:8];
//         end
//     end

//     always_comb begin
//         state_next = state_reg;
//         j_next     = j_reg;
//         k_next     = k_reg;
//         temp1_next = temp1;
//         temp2_next = temp2;
//         temp3_next = temp3;
//         temp4_next = temp4;
//         temp5_next = temp5;
//         case (state_reg)
//             IDLE0: begin
//                 prv_mem_L = mem_L;
//                 prv_mem_R = mem_R;
//                 if (wAddr2 >= 4) begin
//                     state_next = STATE0;
//                 end else begin
//                     state_next = IDLE0;
//                 end
//             end
//             IDLE1: begin
//                 prv_mem_L = mem_L;
//                 prv_mem_R = mem_R;
//                 if (wAddr2 % (j_reg + 4 == 0)) begin
//                     state_next = STATE0;
//                 end else begin
//                     state_next = IDLE1;
//                 end
//                 // read_en_next = 0;
//             end
//             STATE0: begin
//                 temp1_next = (prv_mem_L[j_reg] > prv_mem_R[j_reg]) ? (prv_mem_L[j_reg] - prv_mem_R[j_reg]) : (prv_mem_R[j_reg] - prv_mem_L[j_reg]);             // Right data' 1st data. 
//                 temp2_next = (prv_mem_L[j_reg] > prv_mem_R[j_reg+1]) ? (prv_mem_L[j_reg] - prv_mem_R[j_reg+1]) : (prv_mem_R[j_reg+1] - prv_mem_L[j_reg]);       // i
//                 temp3_next = (prv_mem_L[j_reg] > prv_mem_R[j_reg+2]) ? (prv_mem_L[j_reg] - prv_mem_R[j_reg+2]) : (prv_mem_R[j_reg+2] - prv_mem_L[j_reg]);       // i
//                 temp4_next = (prv_mem_L[j_reg] > prv_mem_R[j_reg+3]) ? (prv_mem_L[j_reg] - prv_mem_R[j_reg+3]) : (prv_mem_R[j_reg+3] - prv_mem_L[j_reg]);       // i
//                 temp5_next = (prv_mem_L[j_reg] > prv_mem_R[j_reg+4]) ? (prv_mem_L[j_reg] - prv_mem_R[j_reg+4]) : (prv_mem_R[j_reg+4] - prv_mem_L[j_reg]);       // i
//                 state_next = STATE1;
//             end
//             STATE1: begin
//                 if (temp1 < temp2) begin
//                     if (temp1 < temp3) begin
//                         if (temp1 < temp4) begin
//                             if (temp1 < temp5) begin
//                                 result = 600 * 0.1 / 1;
//                             end else begin
//                                 result = 600 * 0.1 / 5;
//                             end
//                         end else begin
//                             if (temp4 < temp5) begin
//                                 result = 600 * 0.1 / 4;
//                             end else begin
//                                 result = 600 * 0.1 / 5;
//                             end
//                         end
//                     end else begin
//                         if (temp3 < temp4) begin
//                             if (temp3 < temp5) begin
//                                 result = 600 * 0.1 / 3;
//                             end else begin
//                                 result = 600 * 0.1 / 5;
//                             end
//                         end else begin
//                             if (temp4 < temp5) begin
//                                 result = 600 * 0.1 / 4;
//                             end else begin
//                                 result = 600 * 0.1 / 5;
//                             end
//                         end
//                     end
//                 end else begin
//                     if (temp2 < temp3) begin
//                         if (temp2 < temp4) begin
//                             if (temp2 < temp5) begin
//                                 result = 600 * 0.1 / 2;
//                             end else begin
//                                 result = 600 * 0.1 / 5;
//                             end
//                         end else begin
//                             if (temp4 < temp5) begin
//                                 result = 600 * 0.1 / 4;
//                             end else begin
//                                 result = 600 * 0.1 / 5;
//                             end
//                         end
//                     end else begin
//                         if (temp3 < temp4) begin
//                             if (temp3 < temp5) begin
//                                 result = 600 * 0.1 / 3;
//                             end else begin
//                                 result = 600 * 0.1 / 5;
//                             end
//                         end else begin
//                             if (temp4 < temp5) begin
//                                 result = 600 * 0.1 / 4;
//                             end else begin
//                                 result = 600 * 0.1 / 5;
//                             end
//                         end
//                     end
//                 end

//                 temp_mem[j_reg+k_reg*160] = result;

//                 if (j_reg >= 159) begin
//                     if (!Hsync) begin
//                         temp1_next = 0;
//                         temp2_next = 0;
//                         temp3_next = 0;
//                         temp4_next = 0;
//                         temp5_next = 0;
//                         j_next     = 0;
//                         state_next = IDLE0;
//                         if (k_reg == 119) begin
//                             k_next = 0;
//                         end else begin
//                             k_next = k_reg + 1;
//                         end
//                     end
//                 end else begin
//                     temp1_next = 0;
//                     temp2_next = 0;
//                     temp3_next = 0;
//                     temp4_next = 0;
//                     temp5_next = 0;
//                     j_next     = j_reg + 1;
//                     state_next = IDLE1;
//                 end
//             end
//         endcase
//     end

//     always_ff @(posedge rclk) begin
//         if (oe) begin
//             rData <= temp_mem[rAddr];
//         end else begin
//             rData <= 0;
//         end
//     end
// endmodule

// module disparity_generator (
//     input  logic        clk,
//     input  logic        reset,
//     input  logic        Hsync,
//     // write side
//     input  logic        wclk1,
//     input  logic        we1,
//     input  logic [14:0] wAddr1,
//     input  logic [15:0] wData1,
//     // write side
//     input  logic        wclk2,
//     input  logic        we2,
//     input  logic [14:0] wAddr2,
//     input  logic [15:0] wData2,
//     // read side for VGA
//     input  logic        rclk,
//     input  logic        oe,
//     input  logic [14:0] rAddr,
//     output logic [ 5:0] rData
// );
//     logic [5:0] mem_L[0:160-1];
//     logic [5:0] mem_R[0:160-1];

//     logic [5:0] prv_mem_L[0:160-1];
//     logic [5:0] prv_mem_R[0:160-1];

//     logic state_reg, state_next;
//     logic read_en_reg, read_en_next;
//     logic [5:0] temp1;
//     logic [5:0] temp2;
//     logic [5:0] temp3;
//     logic [5:0] temp4;
//     logic [5:0] temp5;
//     logic [5:0] temp_mem[0:160-1];
//     logic [6:0] j_reg, j_next;

//     ila_0 U_ila_0 (
//         .clk    (clk),                    // input wire clk
//         .probe0 (wclk1),                  // input wire [0:0]  probe0  
//         .probe1 (wAddr1),                 // input wire [14:0]  probe1 
//         .probe2 (wData1),                 // input wire [15:0]  probe2 
//         .probe3 (wclk2),                  // input wire [0:0]  probe3 
//         .probe4 (wAddr2),                 // input wire [14:0]  probe4 
//         .probe5 (wData2),                 // input wire [15:0]  probe5 
//         .probe6 (rclk),                   // input wire [0:0]  probe6 
//         .probe7 (oe),                     // input wire [0:0]  probe7 
//         .probe8 (rAddr),                  // input wire [14:0]  probe8 
//         .probe9 (rData),                  // input wire [5:0]  probe9 
//         .probe10(mem_L[wAddr1%160]),      // input wire [5:0]  probe10 
//         .probe11(mem_R[wAddr2%160]),      // input wire [5:0]  probe11 
//         .probe12(prv_mem_L[wAddr1%160]),  // input wire [5:0]  probe12 
//         .probe13(prv_mem_R[wAddr2%160]),  // input wire [5:0]  probe13 
//         .probe14(state_reg),              // input wire [1:0]  probe14 
//         .probe15(read_en_reg),            // input wire [0:0]  probe15
//         .probe16(temp_mem[rAddr])        // input wire [5:0]  probe16 
//     );

//     localparam IDLE = 0, STATE0 = 1;

//     always_ff @(posedge rclk) begin
//         // if (y - 240 == j_reg) begin
//         if (oe && read_en_reg) begin
//             rData <= temp_mem[rAddr];
//         end else begin
//             rData <= 0;
//         end
//         // end
//     end

//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             state_reg   <= 0;
//             read_en_reg <= 1;
//             temp1       <= 0;
//             temp2       <= 0;
//             temp3       <= 0;
//             temp4       <= 0;
//             temp5       <= 0;
//             j_reg       <= 0;
//             for (int i = 0; i < 160; i++) begin
//                 temp_mem[i]  <= 6'd0;
//                 mem_L[i]     <= 6'd0;
//                 mem_R[i]     <= 6'd0;
//                 prv_mem_L[i] <= 6'd0;
//                 prv_mem_R[i] <= 6'd0;
//             end
//         end else begin
//             state_reg   <= state_next;
//             read_en_reg <= read_en_next;
//             j_reg       <= j_next;
//         end
//     end

//     always_ff @(posedge wclk1) begin
//         if (we1 && read_en_reg) begin
//             mem_L[wAddr1%160] <= wData1[13:8];
//         end
//     end

//     always_ff @(posedge wclk2) begin
//         if (we2 && read_en_reg) begin
//             mem_R[wAddr2%160] <= wData2[13:8];
//         end
//     end

//     always_comb begin
//         state_next   = state_reg;
//         read_en_next = read_en_reg;
//         j_next       = j_reg;
//         case (state_reg)
//             IDLE: begin
//                 prv_mem_L = mem_L;
//                 prv_mem_R = mem_R;
//                 if (wAddr2 % 159 == 0 && wAddr2 > 0) begin
//                     state_next   = STATE0;
//                     read_en_next = 0;
//                 end
//                 // focal length * baseline / disparity = z() (depth)
//             end
//             STATE0: begin
//                 if (!Hsync) begin
//                     state_next   = IDLE;
//                     read_en_next = 1;
//                     if (j_reg == 119) begin
//                         j_next = 0;
//                     end else begin
//                         j_next = j_reg + 1;
//                     end
//                     for (int j = 0; j < 160; j++) begin
//                         temp1 = (prv_mem_L[j] > prv_mem_R[j]) ? (prv_mem_L[j] - prv_mem_R[j]) : (prv_mem_R[j] - prv_mem_L[j]); // Right data' 1st data. 
//                         temp2 = (prv_mem_L[j] > prv_mem_R[j+1]) ? (prv_mem_L[j] - prv_mem_R[j+1]) : (prv_mem_R[j+1] - prv_mem_L[j]);       // i
//                         temp3 = (prv_mem_L[j] > prv_mem_R[j+2]) ? (prv_mem_L[j] - prv_mem_R[j+2]) : (prv_mem_R[j+2] - prv_mem_L[j]);       // i
//                         temp4 = (prv_mem_L[j] > prv_mem_R[j+3]) ? (prv_mem_L[j] - prv_mem_R[j+3]) : (prv_mem_R[j+3] - prv_mem_L[j]);       // i
//                         temp5 = (prv_mem_L[j] > prv_mem_R[j+4]) ? (prv_mem_L[j] - prv_mem_R[j+4]) : (prv_mem_R[j+4] - prv_mem_L[j]);       // i

//                         if (temp1 < temp2) begin
//                             if (temp1 < temp3) begin
//                                 if (temp1 < temp4) begin
//                                     if (temp1 < temp5) begin
//                                         temp_mem[j] = 600 * 0.1 / 1;
//                                     end else begin
//                                         temp_mem[j] = 600 * 0.1 / 5;
//                                     end
//                                 end else begin
//                                     if (temp4 < temp5) begin
//                                         temp_mem[j] = 600 * 0.1 / 4;
//                                     end else begin
//                                         temp_mem[j] = 600 * 0.1 / 5;
//                                     end
//                                 end
//                             end else begin
//                                 if (temp3 < temp4) begin
//                                     if (temp3 < temp5) begin
//                                         temp_mem[j] = 600 * 0.1 / 3;
//                                     end else begin
//                                         temp_mem[j] = 600 * 0.1 / 5;
//                                     end
//                                 end else begin
//                                     if (temp4 < temp5) begin
//                                         temp_mem[j] = 600 * 0.1 / 4;
//                                     end else begin
//                                         temp_mem[j] = 600 * 0.1 / 5;
//                                     end
//                                 end
//                             end
//                         end else begin
//                             if (temp2 < temp3) begin
//                                 if (temp2 < temp4) begin
//                                     if (temp2 < temp5) begin
//                                         temp_mem[j] = 600 * 0.1 / 2;
//                                     end else begin
//                                         temp_mem[j] = 600 * 0.1 / 5;
//                                     end
//                                 end else begin
//                                     if (temp4 < temp5) begin
//                                         temp_mem[j] = 600 * 0.1 / 4;
//                                     end else begin
//                                         temp_mem[j] = 600 * 0.1 / 5;
//                                     end
//                                 end
//                             end else begin
//                                 if (temp3 < temp4) begin
//                                     if (temp3 < temp5) begin
//                                         temp_mem[j] = 600 * 0.1 / 3;
//                                     end else begin
//                                         temp_mem[j] = 600 * 0.1 / 5;
//                                     end
//                                 end else begin
//                                     if (temp4 < temp5) begin
//                                         temp_mem[j] = 600 * 0.1 / 4;
//                                     end else begin
//                                         temp_mem[j] = 600 * 0.1 / 5;
//                                     end
//                                 end
//                             end
//                         end
//                     end
//                 end
//             end
//         endcase
//     end
// endmodule
