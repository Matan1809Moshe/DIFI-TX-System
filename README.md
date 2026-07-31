# DIFI-TX-System
**Hardware-Software co-design of a VITA 49.2 / DIFI compliant Transmit (TX) system on Zynq UltraScale+ MPSoC**

<p align="center">
  <img src="https://github.com/user-attachments/assets/7dea17a6-9ae5-45d5-a50a-2e6364eca95b" alt="Zynq UltraScale+_Logo" width="150">
  &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/293f2d76-f036-45d1-af16-df0e450071f5" alt="SystemVerilog_logo" width="150">
  &nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/772c26f8-e691-4229-9b25-75eba6462247" alt="DIFI_logo" width="110">
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/fd20ac97-91b3-467b-b187-27039ead6434" alt="TAU_logo" width="400">
</p>

> **Note:** The current scope of this repository focuses strictly on the **Transmit (TX) data path**

## Overview
This repository contains the design, implementation, and documentation for a high-performance **Digital IF (DIFI) Transmit (TX) System**, developed as part of an engineering graduation project at Tel Aviv University. The system is fully compliant with the strict **VITA 49.2 / DIFI standard**.

The primary objective is to develop a robust hardware-software co-design architecture capable of encapsulating digitized analog signals (IQ format samples) into standard IP network packets. This facilitates the transition of satellite ground stations from traditional analog RF infrastructure to digital, Ethernet-based networks, effectively mitigating the industry problem of "vendor lock-in."

<p align="center">
  <img src="https://github.com/user-attachments/assets/f0a4382d-2c07-4bd7-90d9-27ea4dfc9428" alt="Overall_hardware-software_co-design_architecture" width="700">
</p>

---

## Getting Started

## 1. System Architecture & Hardware-Software Co-Design

The system is deployed on a **Xilinx Zynq UltraScale+ MPSoC** platform (utilizing the iW-RainboW-G30M development board) and is divided into the Processing System (PS) and Programmable Logic (PL).

### Hardware Data Path (PL)
```
                  +---------------------------+
                  |  Zynq UltraScale+ MPSoC   |
                  +---------------------------+
                    |                       |
            100 MHz |                       | 156 MHz (MAC)
                    v                       v 
              +-----------+            +-------------------+
              |    DDS    |            | Timestamp Counter |
              |  Compiler |            +-------------------+
              +-----------+           /           |         \
                    |                /            |          \
                    v               v             v           v
              +-----------+     +-------+     +-------+   +-------+
              |   ASYNC   |     | Data  |     |Context|   |Version|
              |   FIFO    | --> |Packet.|     |Packet.|   |Packet.|
              +-----------+     +-------+     +-------+   +-------+
                    ^              |              |           |
                    |              v              v           v
                    |        +----------+     +--------------------+
             156 MHz (MAC)   |   Sync   |     |       Stream       |
             ------------>   |   FIFO   | --> |       Arbiter      |
                             +----------+     +--------------------+
                                                        | 32-bit
                                                        v
                                             +-----------------------+
                                             |  Bus Width Converter  |
                                             |     (32-to-64 bit)    |
                                             +-----------------------+
                                                        | 64-bit
                                                        v
                                             +-----------------------+
                                             | UDP Broadcast Wrapper |
                                             +-----------------------+
                                                        | 64-bit
                                                        v
                                             +-----------------------+
                                             |  Ethernet Subsystem   |
                                             |   (10G/25G MAC+PCS)   |
                                             +-----------------------+
                                                        | SFP+ (10G)
                                                        v
                                             +-----------------------+
                                             |      Receiver PC      |
                                             +-----------------------+
```
---
* **Digital Signal Generation (DDS):** Xilinx IP configured to generate a complex I/Q sine and cosine outputs with programmable phase increment. In this project it is set to output a 100 kHz tone from the 100 MHz clock. A custom dds_rate_ctrl module gates the DDS clock enable to enforce an adjustable target sample rate.

* **Clock Domain Crossing (CDC) & Async FIFO:** An IP configured as an asynchronous FIFO. It bridges the 100 MHz PS clock (where the DDS runs) to the needed 156.25 MHz Ethernet MAC clock. Direct crossing between clock domains would cause metastability. The async FIFO uses synchronization internally to transfer data safely at streaming throughput.

* **Data Packetizer:** An RTL Verilog module. Buffers 343 I/Q samples per packet, constructs the 7-word DIFI Data Packet header (Class 0x0000) with stream ID, sequence number, and a timestamp sampled from the Timestamp Counter, and outputs a complete 350-word DIFI packet on AXI-Stream.

* **Context Packetizer:** An RTL Verilog module. Emits a 27-word DIFI Signal Context packet (Class 0x0001) at a configurable periodic rate, carrying signal metadata sample rate, RF center frequency, bandwidth, and reference level. That allows the receiver to interpret the I/Q samples.

* **Version Packetizer:** An RTL Verilog module. Emits an 11-word DIFI Version Context packet (Class 0x0004) at a configurable (less frequent) rate, carrying the DIFI specification version and firmware build identity. This allows a receiver joining the stream to identify the transmitter.

* **Sync FIFO:** An IP configured as a single-clock (synchronous) FIFO. It provides buffering between the Data Packetizer output and the Stream Arbiter, absorbing short bursts of backpressure and avoiding stalls in the upstream pipeline.

* **Priority Arbiter:** An RTL Verilog module. Merges the three concurrent packet streams (Data, Context, Version) onto a single 32-bit AXI-Stream bus with fixed priority: Version > Context > Data. Priority arbitration ensures that the low-rate metadata packets are never starved by the continuous Data stream.

* **Bus Width Converter:** Data Width Converter IP, configured 32-bit to 64-bit. The Xilinx 10G/25G Ethernet Subsystem requires a 64-bit AXI-Stream input to sustain 10 Gbit/s line rate at 156.25 MHz (156.25 MHz × 64 bits ≈ 10 Gbit/s). The upstream pipeline runs at 32 bits to match the DIFI word size, so a width conversion is needed.

* **UDP Broadcast Wrapper:** An RTL module. Prepends a 42-byte Ethernet/IPv4/UDP header to each DIFI packet, computes the IPv4 header checksum combinationally in hardware, and handles the misalignment between the 42-byte header and the 64-bit datapath using a packing mechanism that keeps every output word fully populated.

* **10G/25G Ethernet Subsystem (MAC + PCS):** Xilinx 10G/25G Ethernet Subsystem IP. Implements the Ethernet Media Access Control (MAC) layer and the Physical Coding Sublayer (PCS), converting the AXI-Stream frames from the UDP Broadcast Wrapper into 10 Gbit/s serial data. Its output drives GTH gigabit transceivers, which are connected to the board's SFP+ cage for optical transmission to the Receiver PC.

---

## 2. Processing System (PS) & Software Control

The Processing System (PS) runs an embedded PetaLinux OS, managing the network stack, system initialization, and high-level configuration of transmission parameters from user space via memory-mapped AXI4-Lite registers.

### AXI4-Lite Control & Status Register Map
The PL custom IP registers are mapped into the PS memory space starting at base address `0xB0000000`:

| Offset | Register Name | Description | Access |
| :--- | :--- | :--- | :--- |
| `0x00` | `TX_CTRL_REG` | Global core enable / soft reset | R/W |
| `0x04` | `STREAM_CFG_REG` | Packet size, payload length configuration | R/W |
| `0x08` | `DEST_IP_REG` | Target host IPv4 destination address | R/W |
| `0x0C` | `PORT_CFG_REG` | UDP source and destination port mapping | R/W |
| `0x20` | `DDS_FREQ_REG` | DDS tuning word / output frequency select | R/W |
| `0x24` | `STATUS_REG` | FIFO fill levels, TX active state indicators | RO |

---

## 3. Build & Implementation Guide
### Step 1: Block Design Generation
1. Open Vivado targeting the Zynq UltraScale+ MPSoC device and create a Block Design (BD).
2. Create a new Block Design (`BD`).
3. Instantiate the Zynq MPSoC processing block, run *Block Automation* to configure DDR memory and
   default AXI interconnects.
4. Add the custom DIFI TX IP blocks (DDS, FIFO, Packetizer, UDP Wrapper) to the canvas.

### Step 2: Constraint Assignment (`.xdc`)
Ensure physical constraints for the 10G SFP+ interface transceiver pins, differential reference clocks, and board-level IO standards are correctly defined in your master constraints file:

#### Example constraint snippet for high-speed serial transceiver reference clock
**Tcl**
set_property PACKAGE_PIN F9 [get_ports {gt_refclk_10g_n}]
set_property PACKAGE_PIN F10 [get_ports {gt_refclk_10g_p}]

### Step 3: Synthesis and Bitstream Export
* Generate the HDL wrapper for the block design.

* Launch Synthesis and Implementation.

* Upon successful place-and-route closure, click Generate Bitstream.

* Export the hardware description (.xsa) including the bitstream to PetaLinux.

### step 4: PetaLinux Build (OS Generation)
Create and build the PetaLinux project using the exported .xsa:

**Bash**
petalinux-create -t project -s <path_to_bsp> --name difi_mpsoc_system
cd difi_mpsoc_system
petalinux-config --get-hw-description=<path_to_export_hardware>
# Map memory regions in system-user.dtsi, then compile:
petalinux-build

---

## 4. Execution & Verification
### Step 1: SD Card Boot Preparation
1. BOOT Partition (FAT32): Stores primary bootloader files, device tree, and kernel binary. Populate
   with:

* BOOT.BIN (packaged FSBL, PMU firmware, ATF, U-Boot, and the bitstream).
* image.ub (combined Linux kernel, device tree, and initramfs).
* boot.scr (U-Boot boot script).

2. RootFS Partition (EXT4): Extract the root file system archive for user-space operations:

**Bash**
sudo tar -xaf rootfs.tar.gz -C /media/user/ROOTFS_PARTITION/

### Step 2: Board Bring-Up & Register Initialization

**Bash**
#A. Soft reset and enable DIFI TX core
devmem 0xB0000000 32 0x00000001

#B. Configure packet transfer parameters (e.g., payload size)
devmem 0xB0000004 32 0x00000400

#C. Set destination UDP port and IP register mappings
devmem 0xB000000C 32 0xC0A8010A    # Target IP: 192.168.1.10
devmem 0xB0000010 32 0x70A070A0    # Port configuration

#D. Verify system readiness via status register readback
devmem 0xB0000024 32

### Step 3: Network Capture & Verification

**1. Live Network Capture - Wireshark:** Connect the 10G SFP+ cable to a host PC (e.g., 192.168.1.10). Apply a UDP port display filter in Wireshark (udp.port == 8888) to observe incoming VITA 49.2 packets streaming at line rate with zero packet drops.

**2. Baseband Reconstruction GNU Radio:** Feed the captured raw packet stream into a custom GNU Radio flowgraph to demap headers, extract 16-bit IQ samples, and visually verify the reconstructed baseband tones via QT GUI sinks.

---

## Authors & Contributors

* **Students:** Matan Moshe and Daniel Burstein
* **Project Supervisor:** Baruch Kagan (CTO, Ayecka Communication Systems LTD)
* **Institution:** Tel Aviv University | Faculty of Engineering | Project ID: 3324
