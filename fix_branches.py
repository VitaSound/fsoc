#!/usr/bin/env python3
"""Fix zbranch targets in z80 firmware.hex"""

import sys

def fix_branches(hex_file, output_file):
    with open(hex_file) as f:
        lines = [line.strip() for line in f]
    
    # Convert to byte array for easier manipulation
    bytes_data = bytearray(int(line, 16) for line in lines)
    
    # Find all CALL zbranch (CD D3 00) instructions
    # zbranch is at kernel address 0x00D3
    zbranch_calls = []
    for i in range(len(bytes_data) - 2):
        if bytes_data[i] == 0xCD and bytes_data[i+1] == 0xD3 and bytes_data[i+2] == 0x00:
            call_addr = i
            target_addr = i + 3  # target is at next 2 bytes after CALL (3 bytes)
            print(f"Found CALL zbranch at 0x{call_addr:X}, target at 0x{target_addr:X}")
    
    # Find all JP (C3) instructions
    jp_instructions = []
    for i in range(len(bytes_data) - 2):
        if bytes_data[i] == 0xC3:
            jp_addr = i
            target_addr = i + 1  # offset at next 2 bytes
            print(f"Found JP at 0x{jp_addr:X}, offset at 0x{target_addr:X}")
    
    print("Analysis complete. Manual patching needed.")
    return

if __name__ == '__main__':
    fix_branches(sys.argv[1], sys.argv[1] + '.fixed')
