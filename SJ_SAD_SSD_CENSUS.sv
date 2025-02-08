`timescale 1ns / 1ps

module SAD_SSD_CENSUS (
    input  logic        clk,
    input  logic        reset,
    input  logic        ssd_sad_select,
    input  logic        census_select,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [10:0] in_L,
    input  logic [10:0] in_R,
    output logic [ 5:0] rData
);

    localparam IDLE = 0, COMP = 1, J_PULSE = 2;

    logic [13:0] mem_L[0:2][0:159];
    logic [13:0] mem_R[0:2][0:159];
    logic [1:0] state_reg, state_next;
    logic read_en_reg, read_en_next;
    logic [3:0] window_cost_census_reg[15:0];
    logic [35:0] window_cost_sad_ssd_reg[15:0];
    logic [5:0] temp_mem[0:160-1];
    logic [7:0] j, j_next;

    // Pipeline registers
    logic [13:0] window_L  [0:2][0:2];
    logic [13:0] window_R  [0:2][0:2];
    logic [ 5:0] depth_reg;
    logic [3:0] index_reg, index_next;

    logic [15:0] is_smaller;
    logic [ 3:0] min_idx;
    assign rData = temp_mem[x_pixel[9:1]];

    ///////////////////////////////////             SAD & SSD               //////////////////////////////////////
    function automatic logic [35:0] window_cost_sad_ssd(
        input logic [13:0] L[0:2][0:2], input logic [13:0] R[0:2][0:2]);

        logic [35:0] cost = 0;

        for (int i = 0; i < 3; i++) begin
            for (int w = 0; w < 3; w++) begin
                if (ssd_sad_select) begin
                    cost += (L[i][w] > R[i][w]) ? (L[i][w] - R[i][w]) * (L[i][w] - R[i][w]) : (R[i][w] - L[i][w]) * (R[i][w] - L[i][w]);
                end else begin
                    cost += (L[i][w] > R[i][w]) ? (L[i][w] - R[i][w]) : (R[i][w] - L[i][w]);
                end
            end
        end


        return cost;
    endfunction
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////


    ///////////////////////////////             SAD & SSD Get Disparity              /////////////////////////////
    function automatic logic [3:0] get_depth_sad_ssd(logic [35:0] costs[16]);
        logic [ 3:0] min_idx = 0;
        logic [35:0] min_cost = costs[0];

        // Find minimum cost index
        for (int i = 1; i < 16; i++) begin
            if (costs[i] < min_cost) begin
                min_cost = costs[i];
                min_idx  = i;
            end
        end

        return min_idx;
    endfunction
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////               Census                //////////////////////////////////////
    function automatic logic [3:0] window_cost_census(
        input logic [13:0] L[0:2][0:2], input logic [13:0] R[0:2][0:2]);

        logic        cost_L               [8:0];
        logic        cost_R               [8:0];
        logic [ 3:0] cost_census = 0;
        logic [15:0] average_pixels_L = 0;
        logic [15:0] average_pixels_R = 0;

        average_pixels_L = (L[0][0] + L[0][1] + L[0][2] + L[1][0] + L[1][1] + L[1][2] + L[2][0] + L[2][1] + L[2][2]) / 9;
        average_pixels_R = (R[0][0] + R[0][1] + R[0][2] + R[1][0] + R[1][1] + R[1][2] + R[2][0] + R[2][1] + R[2][2]) / 9;

        // Census Transform
        for (int i = 0; i < 3; i++) begin
            for (int w = 0; w < 3; w++) begin
                cost_L[w+(i*3)] = (L[i][w] > average_pixels_L) ? 1 : 0;
            end
        end

        for (int i = 0; i < 3; i++) begin
            for (int w = 0; w < 3; w++) begin
                cost_R[w+(i*3)] = (R[i][w] > average_pixels_R) ? 1 : 0;
            end
        end

        // Bitstring Transform & Hamming Distance
        for (int i = 0; i < 9; i++) begin
            if (i != 4) begin
                if (cost_L[i] != cost_R[i]) begin
                    cost_census = cost_census + 1;
                end
            end
        end

        return cost_census;
    endfunction

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////


    /////////////////////////////////             Census Get Disparity              //////////////////////////////
    function automatic logic [3:0] get_depth_census(logic [3:0] costs[16]);
        logic [3:0] min_idx = 0;
        logic [3:0] min_cost = costs[0];

        // Find minimum cost index
        for (int i = 1; i < 16; i++) begin
            if (costs[i] < min_cost) begin
                min_cost = costs[i];
                min_idx  = i;
            end
        end

        return min_idx;
    endfunction

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////


    ///////////////////////////////                    Sequential                    /////////////////////////////
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state_reg   <= 0;
            read_en_reg <= 1;
            j           <= 0;
            depth_reg   <= 0;
            index_reg   <= 0;
            for (int i = 0; i < 16; i++) begin
                window_cost_census_reg[i] <= 4'hF;
            end
            for (int i = 0; i < 160; i++) begin
                temp_mem[i] <= 0;
            end
        end else begin
            state_reg   <= state_next;
            read_en_reg <= read_en_next;
            j           <= j_next;
            index_reg   <= index_next;

            // Load window data
            if (read_en_reg) begin
                mem_L[y_pixel[9:1]%3][x_pixel[9:1]] <= in_L;
                mem_R[y_pixel[9:1]%3][x_pixel[9:1]] <= in_R;
            end

            // Setup window data
            for (int i = 0; i < 3; i++) begin
                for (int k = 0; k < 3; k++) begin
                    window_L[i][k] <= mem_L[i][j+k];
                    window_R[i][k] <= mem_R[i][j+k+index_reg];
                end
            end

            // Calculate costs (16 times)
            if (census_select) begin
                window_cost_census_reg[index_reg] <= window_cost_census(
                    window_L, window_R
                );

                if (index_reg == 15) begin
                    depth_reg <= {
                        get_depth_census(window_cost_census_reg), 2'b11
                    };
                end
            end else begin
                window_cost_sad_ssd_reg[index_reg] <= window_cost_sad_ssd(
                    window_L, window_R
                );

                if (index_reg == 15) begin
                    depth_reg <= {
                        get_depth_sad_ssd(window_cost_sad_ssd_reg), 2'b11
                    };
                end
            end


            // Determine depth

            // Store result
            temp_mem[j] <= depth_reg;
        end
    end
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////


    ///////////////////////////////                    Combinational                 /////////////////////////////
    always_comb begin
        state_next   = state_reg;
        read_en_next = read_en_reg;
        j_next       = j;
        index_next   = index_reg;
        case (state_reg)
            IDLE: begin
                // If last pixel in row (Line buffer is full)
                if (x_pixel[9:1] == 159) begin
                    state_next   = COMP;
                    read_en_next = 0;
                end
            end
            COMP: begin
                // Disparity research range : 16
                if (index_reg == 15) begin
                    state_next = J_PULSE;
                    index_next = 0;
                end else begin
                    index_next = index_reg + 1;
                end
            end
            J_PULSE: begin
                // If All pixels in row are processed
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
endmodule




module SAD_SSD_CENSUS_5x5 (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic [10:0] in_L,
    input  logic [10:0] in_R,
    output logic [ 5:0] rData
);

    localparam IDLE = 0, COMP = 1, J_PULSE = 2;

    logic [10:0] mem_L[0:4][0:159];
    logic [10:0] mem_R[0:4][0:159];
    logic [1:0] state_reg, state_next;
    logic read_en_reg, read_en_next;
    logic [4:0] window_cost[15:0];
    logic [5:0] temp_mem[0:160-1];
    logic [7:0] j, j_next;

    // Pipeline registers
    logic [10:0] window_L  [0:4][0:4];
    logic [10:0] window_R  [0:4][0:4];
    logic [ 5:0] depth_reg;
    logic [3:0] index_reg, index_next;

    logic [3:0] min_idx;
    assign rData = temp_mem[x_pixel[9:1]];

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function automatic logic [4:0] window_cost_census(
        input logic [10:0] L[0:4][0:4], input logic [10:0] R[0:4][0:4]);
        logic        cost_L           [24:0];
        logic        cost_R           [24:0];
        logic [ 4:0] cost_census = 0;
        logic [19:0] average_pixels_L;
        logic [19:0] average_pixels_R;

        average_pixels_L = (
          L[0][0] + L[0][1] + L[0][2] + L[0][3] + L[0][4]
        + L[1][0] + L[1][1] + L[1][2] + L[1][3] + L[1][4] 
        + L[2][0] + L[2][1] + L[2][2] + L[2][3] + L[2][4] 
        + L[3][0] + L[3][1] + L[3][2] + L[3][3] + L[3][4] 
        + L[4][0] + L[4][1] + L[4][2] + L[4][3] + L[4][4]) / 25;

        average_pixels_L = (
          R[0][0] + R[0][1] + R[0][2] + R[0][3] + R[0][4]
        + R[1][0] + R[1][1] + R[1][2] + R[1][3] + R[1][4]
        + R[2][0] + R[2][1] + R[2][2] + R[2][3] + R[2][4]
        + R[3][0] + R[3][1] + R[3][2] + R[3][3] + R[3][4]
        + R[4][0] + R[4][1] + R[4][2] + R[4][3] + R[4][4]) / 25;

        // Census Transform
        for (int i = 0; i < 5; i++) begin
            for (int w = 0; w < 5; w++) begin
                cost_L[w+(i*3)] = (L[i][w] > average_pixels_L) ? 1 : 0;
            end
        end

        for (int i = 0; i < 5; i++) begin
            for (int w = 0; w < 5; w++) begin
                cost_R[w+(i*3)] = (R[i][w] > average_pixels_R) ? 1 : 0;
            end
        end

        // Bitstring Transform & Hamming Distance

        for (int i = 0; i < 25; i++) begin
            if (i != 12) begin
                if (cost_L[i] != cost_R[i]) begin
                    cost_census = cost_census + 1;
                end
            end
        end

        return cost_census;
    endfunction

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function automatic logic [3:0] get_depth(logic [4:0] costs[16]);
        logic [4:0] min_idx = 0;
        logic [4:0] min_cost = costs[0];

        // Find minimum cost index
        for (int i = 1; i < 16; i++) begin
            if (costs[i] < min_cost) begin
                min_cost = costs[i];
                min_idx  = i;
            end
        end

        return min_idx;
    endfunction

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state_reg   <= 0;
            read_en_reg <= 1;
            j           <= 0;
            depth_reg   <= 0;
            index_reg   <= 0;
            for (int i = 0; i < 16; i++) begin
                window_cost[i] <= 4'hF;
            end
            for (int i = 0; i < 160; i++) begin
                temp_mem[i] <= 0;
            end
        end else begin
            state_reg   <= state_next;
            read_en_reg <= read_en_next;
            j           <= j_next;
            index_reg   <= index_next;

            // Pipeline Stage 1: Load window data
            if (read_en_reg) begin
                mem_L[y_pixel[9:1]%5][x_pixel[9:1]] <= in_L;
                mem_R[y_pixel[9:1]%5][x_pixel[9:1]] <= in_R;
            end
            // end


            // Pipeline Stage 2: Setup window data
            for (int i = 0; i < 5; i++) begin
                for (int k = 0; k < 5; k++) begin
                    window_L[i][k] <= mem_L[i][j+k];
                    window_R[i][k] <= mem_R[i][j+k+index_reg];
                end
            end

            // Pipeline Stage 3: Calculate costs (Unrolled loop)
            // Prepare packed array for each disparity value and calculate costs
            window_cost[index_reg] <= window_cost_census(window_L, window_R);


            // Pipeline Stage 4: Determine depth
            if (index_reg == 15) begin
                depth_reg <= {get_depth(window_cost), 2'b11};
            end

            // Pipeline Stage 5: Store result
            temp_mem[j] <= depth_reg;
        end
    end
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always_comb begin
        state_next   = state_reg;
        read_en_next = read_en_reg;
        j_next       = j;
        index_next   = index_reg;
        case (state_reg)
            IDLE: begin
                if (x_pixel[9:1] == 159) begin
                    state_next   = COMP;
                    read_en_next = 0;
                end
            end
            COMP: begin
                if (index_reg == 15) begin
                    state_next = J_PULSE;
                    index_next = 0;
                end else begin
                    index_next = index_reg + 1;
                end
            end
            J_PULSE: begin
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
endmodule
