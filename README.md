# DIFI-TX-System
Hardware-Software co-design of a VITA 49.2 / DIFI compliant Transmit (TX) system on Zynq UltraScale+ MPSoC

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

The system is deployed on a **Xilinx Zynq UltraScale+ MPSoC** platform (utilizing the iW-RainboW-G30M development board) and is divided into two main domains:

1. **Processing System (PS):** 
   - Runs an embedded Linux operating system (PetaLinux).
   - Manages the network stack, system initialization, and high-level configuration of transmission         parameters via memory-mapped **AXI4-Lite** registers.

2. **Programmable Logic (PL - Hardware Data Path):** 
* **DDS Compiler:** Generates synthetic digital baseband quadrature (IQ) samples at a 100 MHz clock
  domain.

* **Asynchronous FIFO:** Manages Clock Domain Crossing (CDC) from the 100 MHz DDS domain to the 156.25
  MHz high-speed network streaming domain.

* **Packetizers:** Dedicated logic blocks constructing VITA 49.2 / DIFI compliant headers across three
  parallel pipelines: Data Packets, Context Packets, and Version Packets, synchronized via a central
  Timestamp Counter.

* **Sync Data FIFO & Stream Arbiter:** Buffers and multiplexes data streams and periodic metadata
  packets based on priority schemes.

* **Bus Width Converter:** Translates the internal data stream width (e.g., 32-bit to 64-bit) to match
  the MAC layer specifications.

* **UDP Broadcast Wrapper:** Appends standard network encapsulation headers (UDP/IP/MAC) to the packet
  payloads.

* **Ethernet Subsystem:** Transmits the data stream at line rate via a 10G SFP+ physical interface to
  the Receiver PC.
  
```
       +---------------------------+
       |  Zynq UltraScale+ MPSoC   |
       +---------------------------+
         |                       |
 100 MHz |                       | 156 MHz (MAC)
         v                       v צ
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
         |       +-----------+     +-----------------------+
  156 MHz (MAC)  | Sync Data |     |         Stream        |
  ------------>  |   FIFO    | --> |         Arbiter       |
                 +-----------+     +-----------------------+
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

## 2. Detailed Subsystem Breakdown (Programmable Logic)

### A. Digital Signal Generation (DDS Compiler)
* **Function:** Generates synthetic digital baseband quadrature (IQ) samples.
* **Configuration:** Configured to output 16-bit signed I and Q data streams at a sampling clock of      **100 MHz**.
* **Interface:** Employs an AXI-Stream Master interface transmitting continuous sample pairs to the downstream FIFO.

### B. Clock Domain Crossing (CDC) & Asynchronous FIFO
* **Function:** Bridges the asynchronous clock boundary between the internal sample generation domain (100 MHz) and the high-speed Ethernet streaming domain (156.25 MHz for 10GbE).
* **Implementation:** Built using Xilinx FIFO Generator IP configured in independent clock block RAM mode with built-in almost-full/empty threshold flags to prevent data overflow/underflow.

### C. VITA 49.2 / DIFI Packetizer Engine
Converts raw IQ sample streams into structured VITA 49.2 compliant packets. The pipeline constructs three distinct packet types:
1. **Signal Data Packets:** Encapsulates payloads consisting of interleaved 16-bit IQ samples alongside a precise 64-bit timestamp (integer seconds and fractional seconds).
2. **Signal Context Packets:** Periodically transmits metadata parameters including RF frequency, sample rate, bandwidth, gain control settings, and stream identifiers.
3. **Version Context Packets:** Conveys firmware version descriptors and DIFI specification release compliance identifiers.

### D. Stream Arbiter & UDP/IP Wrapper
* **Stream Arbiter:** Multiplexes data packets and periodic context packets based on priority schemes, arbitrating access to the network transmission channel.
* **UDP/IP Wrapper:** Appends standard Ethernet MAC headers, IPv4 headers, and UDP transport layer headers (destination/source ports) to the packet payloads, outputting a wide AXI-Stream data bus ready for MAC insertion.

---

## 3. Processing System (PS) & Software Control

The Processing System runs an embedded **PetaLinux** distribution. System parameters and IP core configurations are managed dynamically from user space using memory-mapped register access.

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

## 4. Step-by-Step Implementation Guide (Vivado Flow)

### Step 1: Block Design Generation
1. Launch **Vivado** and open the target project targeting the Zynq UltraScale+ MPSoC device.
2. Create a new Block Design (`BD`).
3. Instantiate the **Zynq UltraScale+ MPSoC** processing block and run *Block Automation* to configure DDR memory and default AXI interconnects.
4. Add the custom DIFI TX IP blocks (DDS, FIFO, Packetizer, UDP Wrapper) to the canvas.

### Step 2: Constraint Assignment (`.xdc`)
Ensure physical constraints for the 10G SFP+ interface transceiver pins, differential reference clocks, and board-level IO standards are correctly defined in your master constraints file:
tcl

#### Example constraint snippet for high-speed serial transceiver reference clock
set_property PACKAGE_PIN AB6 [get_names {gt_refclk_10g_p}]
set_property PACKAGE_PIN AB5 [get_names {gt_refclk_10g_n}]

### Step 3: Synthesis and Bitstream Export
Generate the HDL wrapper for the block design.

Launch Synthesis and Implementation.

Upon successful place-and-route closure, click Generate Bitstream.

Export the hardware description (.xsa) including the bitstream to PetaLinux.

---

## 5. Step-by-Step Execution & Verification
Step 1: Board Booting & Register Initialization
Power on the iW-RainboW-G30M evaluation board and establish a serial terminal connection (PuTTY / minicom) to the PetaLinux prompt. Use devmem to initialize and unlock the hardware pipeline:

Bash
# A. Soft reset and enable DIFI TX core
devmem 0xB0000000 32 0x00000001

# B. Configure packet transfer parameters (e.g., payload size)
devmem 0xB0000004 32 0x00000400

# C. Set destination UDP port and IP register mappings
devmem 0xB000000C 32 0xC0A8010A    # Target IP: 192.168.1.10
devmem 0xB0000010 32 0x70A070A0    # Port configuration

# D. Verify system readiness via status register readback
devmem 0xB0000024 32

### Step 2: Live Network Capture (Wireshark)
Connect the 10G SFP+ optical/direct attach cable from the board to a host workstation equipped with a 10G network interface card.

Configure the host interface IP to match the subnet (e.g., 192.168.1.10).

Launch Wireshark, select the capture interface, and apply a display filter matching your configured UDP port (e.g., udp.port == 8888).

Observe incoming VITA 49.2 packets streaming continuously at line rate with zero packet drops.

### Step 3: Baseband Reconstruction (GNU Radio)
Feed the captured raw packet stream into a custom GNU Radio flowgraph.

Demaps the VITA 49 frame headers, extracts the 16-bit IQ samples, and feeds them into a QT GUI Time Sink and Frequency Sink to visually verify the reconstructed baseband tones.

## 6. Authors & Contributors

Students: Matan Moshe and Daniel Burstein

Project Supervisor: Baruch Kagan (CTO, Ayecka Communication Systems LTD)

Institution: Tel Aviv University | Faculty of Engineering (Project ID: 3324)
Supervisor: Baruch Kagan (CTO, Ayecka Communication Systems LTD)

Institution: Tel Aviv University, Iby and Aladar Fleischman Faculty of Engineering
