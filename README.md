# DMA Controller (AHB/APB Compliant)

![GitHub repo size](https://img.shields.io/github/repo-size/swatils-web/DMA-AHB-Controller)
![GitHub last commit](https://img.shields.io/github/last-commit/swatils-web/DMA-AHB-Controller)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

## 📖 Overview
This repository contains a **4‑Channel, 32‑bit DMA Controller IP Core** implemented in **Verilog HDL**.  
The design is **compliant with AMBA AHB/APB protocols**, enabling efficient data transfers between memory and peripherals without CPU intervention.

Key highlights:
- Multi‑channel DMA (4 independent channels).
- 32‑bit data path.
- Protocol compliance with AMBA AHB/APB.
- RTL + testbench included for simulation and verification.

---

## 📂 Directory Structure
- `src/` : RTL source files  
  - `ahb_master.v`  
  - `apb_slave.v`  
  - `arbiter.v`  
  - `dma_top.v`  
- `tb/`  : Testbench files  
  - `dma_tb.v`  
- `.gitignore` : Git ignore rules  
- `README.md` : Project documentation  

---

## 🛠 Simulation (Vivado)
1. Launch **Vivado**.  
2. Add all files from `src/` and `tb/`.  
3. Set **`dma_top`** as the design top.  
4. Set **`dma_tb`** as the simulation top.  
5. Run **Behavioral Simulation**.  
6. Observe DMA transfer waveforms and verify protocol handshakes.

---

## 📊 Block Diagram
*(<img width="940" height="471" alt="image" src="https://github.com/user-attachments/assets/f5bd45ee-81d7-42f9-af9a-6c266a77d162" />
)*

---

## 📜 License
This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing
Contributions are welcome!  
- Fork the repo  
- Create a feature branch  
- Submit a pull request  

---

## 📌 Citation
If you use this project in academic work or research, please cite:  
