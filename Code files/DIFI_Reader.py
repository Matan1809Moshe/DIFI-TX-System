"""
Embedded Python Blocks:

Each time this file is saved, GRC will instantiate the first class it finds
to get ports and parameters of your block. The arguments to __init__  will
be the parameters. All of them are required to have default values!
"""

import numpy as np
from gnuradio import gr
import os

class difi_bin_reader(gr.sync_block):
    """
    Custom GNU Radio source block for reading and parsing DIFI/VITA 49
    binary files. It features robust frame alignment via sync-word detection,
    sequence number drop tracking, and automatic Big-Endian to Little-Endian
    conversion for the I/Q samples.
    """

    def __init__(self, filename=''):
        gr.sync_block.__init__(
            self,
            name='DIFI Reader',
            in_sig=None,
            out_sig=[np.int16]  # Output of 16-bit integers (to be fed into IShortToComplex)
        )
        self.filename = filename
        
        # Open file only if filename is provided (prevents GRC crashing during UI loading)
        self.f = open(self.filename, 'rb') if self.filename else None
        self.buffer = bytearray()
        
        # Sync signature: Word 1 (Stream ID) + Word 2 (Class ID Word 1)
        # 8 strictly constant bytes allowing realignment even if the file contains noise
        self.sync_word = b'\x00\x00\x00\x01\x00\x6a\x62\x1e'
        
        self.expected_seq = -1
        self.dropped_packets = 0
        
        # Packet dimensions (excluding network headers, pure DIFI VITA-49)
        self.difi_pkt_len = 1400  # 28 Bytes Header + 1372 Bytes IQ Payload
        self.samples_per_pkt = 1372 // 2  # 686 int16 samples (343 I, 343 Q)

    def work(self, input_items, output_items):
        # Protection: if file wasn't opened, do nothing
        if not self.f:
            return 0
            
        out = output_items[0]
        out_len = len(out)
        out_idx = 0

        # Loop until output buffer is full or file is EOF
        while out_idx < out_len:
            # 1. Load data from file into the internal buffer if it runs low
            if len(self.buffer) < self.difi_pkt_len * 10:
                chunk = self.f.read(self.difi_pkt_len * 10)
                if not chunk and len(self.buffer) < self.difi_pkt_len:
                    break  # EOF reached and not enough data for a full packet
                self.buffer.extend(chunk)

            # Wait if buffer is still smaller than a single packet length
            if len(self.buffer) < self.difi_pkt_len:
                break 

            # 2. Find the sync word
            sync_idx = self.buffer.find(self.sync_word)

            if sync_idx == -1:
                # Sync word not found. Discard buffer except the very end to prevent splitting the sync word
                del self.buffer[:-len(self.sync_word)]
                continue

            # In VITA 49, Word 0 (Header) comes 4 bytes before Word 1 (Stream ID).
            # So the packet actually starts 4 bytes before our sync_word.
            packet_start_idx = sync_idx - 4
            
            if packet_start_idx < 0:
                # Missing header bytes, delete corrupt partial data and keep searching
                del self.buffer[:sync_idx + 1]
                continue
            
            if packet_start_idx + self.difi_pkt_len > len(self.buffer):
                # We have the start, but not the full packet yet. Wait for next iteration.
                break

            # 3. Check if we have enough space in the GNU Radio output buffer
            if out_idx + self.samples_per_pkt > out_len:
                # Not enough space for this packet in current cycle. 
                # Return what we processed so far, GNU Radio will call work() again.
                break 

            # 4. Extract the valid packet
            packet = self.buffer[packet_start_idx : packet_start_idx + self.difi_pkt_len]
            del self.buffer[:packet_start_idx + self.difi_pkt_len] # Remove packet from internal buffer

            # 5. Parse Header and Track Sequence Numbers
            header_word0 = int.from_bytes(packet[0:4], byteorder='big')
            seq_num = header_word0 & 0x0F  # Sequence number is the lower 4 bits (modulo 16)

            if self.expected_seq != -1 and seq_num != self.expected_seq:
                self.dropped_packets += 1
                print(f"[DIFI Reader] Warning: Packet drop detected! Expected seq {self.expected_seq}, got {seq_num}. Total drops: {self.dropped_packets}")
            
            self.expected_seq = (seq_num + 1) % 16

            # 6. Extract Payload and Convert Big-Endian to Little-Endian
            payload = packet[28:] # Skip 28 bytes of DIFI header
            
            # np.frombuffer reads the bytes directly. '>i2' indicates Big-Endian 16-bit integers.
            # Numpy automatically converts them to the native Little-Endian format for the host CPU.
            samples = np.frombuffer(payload, dtype='>i2')

            # 7. Write to output buffer
            out[out_idx : out_idx + self.samples_per_pkt] = samples
            out_idx += self.samples_per_pkt

        return out_idx

    def stop(self):
        """
        Called automatically when the flowgraph finishes running.
        Provides a final summary of stream integrity.
        """
        if self.dropped_packets == 0:
            print("[DIFI Reader] Summary: Zero Packet Loss goal achieve!")
        else:
            print(f"[DIFI Reader] Summary: Execution finished with a total of {self.dropped_packets} dropped packets.")
            
        # Safely close the file descriptor
        if self.f:
            self.f.close()
            
        return True
