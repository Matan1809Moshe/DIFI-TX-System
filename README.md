# DIFI-TX-System
Hardware-Software co-design of a VITA 49.2 / DIFI compliant Transmit (TX) system on Zynq UltraScale+ MPSoC

![Platform](https://img.shields.io/badge/Platform-Xilinx%20Zynq%20UltraScale%2B-blue)
![Standard](https://img.shields.io/badge/Standard-VITA%2049.2%20%7C%20DIFI-orange)
![Institution](https://img.shields.io/badge/Institution-Tel%20Aviv%20University-green)

## 📖 Overview

This repository contains the design, implementation, and documentation for a high-performance **Digital IF (DIFI) Transmit (TX) System**. The system is fully compliant with the strict **VITA 49.2 / DIFI standard**. 

The primary objective is to develop a robust hardware architecture capable of encapsulating digitized analog signals (IQ format samples) into standard IP network packets, facilitating the transition of satellite ground stations from traditional analog RF infrastructure to digital, Ethernet-based networks. 

The system is developed and deployed on a **Xilinx Zynq UltraScale+ MPSoC** platform (iW-RainboW-G30M) utilizing a hardware-software
co-design approach. 

> **Note:** The current scope of this repository focuses strictly on the **Transmit (TX) data path**
