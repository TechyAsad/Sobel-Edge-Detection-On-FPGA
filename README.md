# Sobel Edge Detection on FPGA

This project implements a **hardware-accelerated Sobel edge detection engine** on FPGA using Verilog HDL. It serves as a practical example for learning **image processing on FPGA** with real-time performance.This module's aim is to act as a preprocessing block for **Neural Network Accelerator for Railway Track Defect Detection**.

## Overview

The Sobel edge detection algorithm computes image gradients using a **3×3 convolution kernel** to highlight edges. This FPGA implementation accelerates the computation by leveraging parallelism and modular RTL design.

- **Gradient Computation:** Calculates horizontal (Gx) and vertical (Gy) gradients.
- **Edge Magnitude:** Computes the final edge intensity using the gradient magnitudes.
- **Real-time Processing:** Optimized for FPGA, providing **5–10× faster edge detection** compared to software implementations.

## Architecture

The design consists of modular RTL blocks:

1. **Line Buffering:** Efficiently stores pixel rows for convolution.
2. **Convolution Module:** Performs 3×3 kernel operations for Gx and Gy.
3. **Gradient Magnitude Computation:** Combines horizontal and vertical gradients to generate edge intensity.

This modularity allows easy reuse and integration into larger FPGA-based image processing pipelines.

## Future aim:

- Preprocessing for **CNN vision pipelines**, reducing input feature complexity by **60–70%**.
- Enabling Real-time edge detection of  **track images in the Roboflow Railway Track Dataset**.
- Educational tool for learning **Verilog-based image processing** on FPGA.
