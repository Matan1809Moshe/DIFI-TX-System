# DIFI-TX-System
Hardware-Software co-design of a VITA 49.2 / DIFI compliant Transmit (TX) system on Zynq UltraScale+ MPSoC

![Platform](https://img.shields.io/badge/Platform-Xilinx%20Zynq%20UltraScale%2B-blue)
![Standard](https://img.shields.io/badge/Standard-VITA%2049.2%20%7C%20DIFI-orange)
![Institution](https://img.shields.io/badge/Institution-Tel%20Aviv%20University-green)

> **Note:** The current scope of this repository focuses strictly on the **Transmit (TX) data path**

## Overview
This repository contains the design, implementation, and documentation for a high-performance **Digital IF (DIFI) Transmit (TX) System**, developed as part of an engineering graduation project at Tel Aviv University. The system is fully compliant with the strict **VITA 49.2 / DIFI standard**.

The primary objective is to develop a robust hardware-software co-design architecture capable of encapsulating digitized analog signals (IQ format samples) into standard IP network packets. This facilitates the transition of satellite ground stations from traditional analog RF infrastructure to digital, Ethernet-based networks, effectively mitigating the industry problem of "vendor lock-in."

---

## System Architecture & Signal Flow
The system is deployed on a **Xilinx Zynq UltraScale+ MPSoC** platform (utilizing the iW-RainboW-G30M development board) and is divided into two main domains:

1. **Processing System (PS):** 
   - Runs an embedded Linux operating system (PetaLinux).
   - Manages the network stack, system initialization, and high-level configuration of transmission parameters via memory-mapped **AXI4-Lite** registers.

2. **Programmable Logic (PL - Hardware Data Path):** 
   - **DDS Compiler:** Generates synthetic digital baseband IQ samples at 100 MHz.
   - **Asynchronous FIFO:** Manages Clock Domain Crossing (CDC) between the 100 MHz sample clock and the 156 MHz network streaming clock.
   - **Packetizers:** Dedicated logic blocks constructing VITA 49.2 / DIFI compliant headers (Data, Context, and Version packets) with precise timestamping.
   - **Stream Arbiter & UDP Wrapper:** Multiplexes concurrent streams, converts bus widths, and encapsulates packets within standard UDP/IP wrappers.
   - **Ethernet Subsystem:** Transmits the data stream at line rate via a 10G SFP+ physical interface.

---

## Getting Started

### 1. Hardware Initialization & Register Unlocking
After booting the PetaLinux environment on the Zynq MPSoC board, use the `devmem` utility to unlock the AXI4-Lite control registers for the IP cores:

```bash
# Unlock key control register offsets
devmem 0xB0000000 32 0x00000001
devmem 0xB0000004 32 0x00000001
devmem 0xB000000C 32 0x00000001
devmem 0xB0000020 32 0x00000001

# Verify successful unlocking via status registers
devmem 0xB0000708 32
devmem 0xB0000024 32
2. Traffic Capture & Validation
Connect the SFP+ port to a Host PC equipped with a 10G NIC.

Use Wireshark to monitor the target UDP port and verify VITA 49.2 / DIFI packet compliance.

Use GNU Radio to decode the payload, extract the interleaved IQ samples, and reconstruct the baseband sine waves.

Project Verification
The system has been thoroughly validated using:

Integrated Logic Analyzer (ILA): On-chip real-time verification ensuring clean clock-domain crossings and correct AXI-Stream handshakes.

Network Analysis: Proven zero packet loss under sustained high-throughput line-rate transmission.

Authors & Acknowledgments
Students: Matan Moshe & Daniel Burstein

Supervisor: Baruch Kagan (CTO, Ayecka Communication Systems LTD)

Institution: Tel Aviv University, Iby and Aladar Fleischman Faculty of Engineering
