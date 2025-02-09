### Personal Blog Link : https://blog.naver.com/daniel8608/223731291386


# 🚀 Stereo Depth Estimation

## 📌 Project Overview

### Objective
- Implement Stereo Depth estimation using two cameras in hardware
- Display depth output on a monitor via VGA

### Technologies & Equipment Used
- **Languages**: Verilog, SystemVerilog
- **Hardware**: Xilinx Basys3 Board, OV7670 (x2), VGA to HDMI
- **Software**: Vivado 2020.2, VSCode, Vim

### Responsibilities
- Designed SAD, SSD & Census Algorithms
- Developed VGA & OV7670 IP
- Conducted SCCB Interface UVM Verification

## 📂 Implementation Steps

1. Implement pixel-wise SAD & SSD algorithms
   - Compare Combinational & Sequential Logic approaches
2. Implement window-based SAD & SSD algorithms
3. Implement window-based Census algorithm
4. Integrate all algorithms with a switch for selection

## 🖥️ VGA Specifications
- **Resolution**: 640 x 480
- **Color Depth**: RGB565
- **Signal Type**: RGB with horizontal & vertical sync signals
- **Retrace Time Considerations** (output set to 800 x 525)
  - *Front Porch*: Preparation time for next line
  - *Sync*: Synchronization signal
  - *Back Porch*: Stabilization time after sync

## 📷 OV7670 Camera Module
- **Resolution**: 640 x 480, 30fps
- **Interface**: SCCB for register control
- **UVM Verification**
  - Utilized prior I2C UVM experience for efficient verification
  - Passed all 10,000 test cycles with 100% coverage

## 📉 Resolution & Memory Considerations
- Due to BRAM & LUT limitations on Basys3 Board, resolution reduced to **QQVGA (160x120)**
- VGA output processing optimized to execute real-time pixel processing
  - **Implemented combinational logic to process 160 pixels in a single clock cycle**

## 🔢 Algorithm Implementation

### Pixel-wise SAD & SSD Algorithm
- Strongly affected by light variations with significant noise
- Improved version includes color coding: red for close, blue for far objects

### Combinational vs Sequential Logic
- Sequential Logic approach compared (data loss prevented further analysis)

### Window-based SAD & SSD Algorithm
- Implemented with **3x3 window size**
- **Discarded lower 3 bits of Gray value to reduce noise**
- Expanded line buffer from 160x1 to 160x3
- Increased propagation delay caused **negative slack** → adjusted to process one pixel per clock cycle

### Window-based Census Algorithm
- **Improved detail detection compared to SAD** (e.g., clothing wrinkles are clearly visible)
- More sensitive to noise, capturing even subtle variations

## 🎥 Final Results
- Tested in real-world environments, capturing moving vehicles
- Depth output color-coded dynamically (red = close, blue = far)
- **Attempted 5x5 window implementation but exceeded LUT limits (103–150%)**
  
- ![오토바이](https://github.com/user-attachments/assets/33c19e99-194c-45e0-bc8b-1639dccac828)

- ![차](https://github.com/user-attachments/assets/7b55d98e-d114-4138-8127-99118f157e87)


## 🌍 Potential Applications
- Widely used in **automotive, industrial automation, agriculture, and medical fields**
- Similar to **Apple iPhone's spatial photo/video capture technology**
- Can be utilized for preserving memories in a **3D immersive format**

---

## 🔧 Future Improvements
- Optimize LUT usage for potential 5x5 window implementation
- Apply additional noise reduction techniques
- Enhance parallel processing to improve real-time performance

**Reference**: Unlike software-based implementations, there are very few hardware (Verilog) references for Stereo Depth estimation. This project explores a unique approach.

