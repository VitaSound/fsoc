#!/usr/bin/env python3
"""Fix zbranch targets in z80 firmware.hex"""

import sys

def patch_firmware(hex_file):
    with open(hex_file) as f:
        lines = [line.strip() for line in f]
    bytes_data = bytearray(int(line, 16) for line in lines)
    
    # Find the CALL zbranch instruction (CD <zbranch_addr> 00)
    # zbranch is at kernel address 0x00D3 (211) or 0x20D3 depending on build
    zbranch_calls = []
    for i in range(len(bytes_data) - 2):
        if bytes_data[i] == 0xCD and bytes_data[i+2] == 0x00:
            addr = bytes_data[i+2] * 256 + bytes_data[i+1]
            # Check if this is a zbranch call (zbranch is at 0x00D3 or 0x20D3)
            if addr == 0x00D3 or addr == 0x20D3:
                print(f"Found CALL zbranch at 0x{i:X} (target 0x{addr:04X})")
                # Target is at i+3 (after the 3-byte CALL)
                target_low = bytes_data[i+3]
                target_high = bytes_data[i+4]
                target = target_high * 256 + target_low
                print(f"  Current target: 0x{target:04X} (bytes {target_low:02X} {target_high:02X})")
                return i, bytes_data
    
    print("No CALL zbranch found!")
    return None, None

def find_else_body_start(bytes_data, zbranch_call_addr):
    """Find the else body start address by looking for the JP after the if-body"""
    # The if-body ends with a JR NZ that jumps back to the loop
    # Then there's a JP that jumps over the else body
    # The else body starts at the target of that JP
    
    # Search for JR NZ (0x20) with negative offset (loop back)
    for i in range(zbranch_call_addr + 3, len(bytes_data) - 1):
        if bytes_data[i] == 0x20:  # JR NZ
            offset = bytes_data[i+1]
            if offset >= 128:  # negative offset
                print(f"Found JR NZ at 0x{i:X} with offset {offset-256}")
                # The if-body ends here, next is the JP over else body
                # Look for JP after this
                for j in range(i + 2, len(bytes_data) - 2):
                    if bytes_data[j] == 0xC3:  # JP
                        addr = bytes_data[j+2] * 256 + bytes_data[j+1]
                        print(f"Found JP at 0x{j:X} jumping to 0x{addr:04X}")
                        return addr
    return None

if __name__ == '__main__':
    hex_file = sys.argv[1]
    zbranch_addr, bytes_data = patch_firmware(hex_file)
    if zbranch_addr is not None:
        else_start = find_else_body_start(bytes_data, zbranch_addr)
        if else_start:
            print(f"Else body starts at 0x{else_start:04X}")
            # Fix the zbranch target
            target_low = else_start & 0xFF
            target_high = (else_start >> 8) & 0xFF
            target_addr = zbranch_addr + 3  # target bytes after CALL
            print(f"Patching zbranch target at 0x{zbranch_addr+3:X} from 0x{bytes_data[target_addr]:02X}{bytes_data[target_addr+1]:02X} to {target_low:02X}{target_high:02X}")
            bytes_data[target_addr] = target_low
            bytes_data[target_addr + 1] = target_high
            
            # Write back
            with open(hex_file, 'w') as f:
                for b in bytes_data:
                    f.write(f"{b:02X}\n")
            print("Patched!")
        else:
            print("Could not find else body start")
    else:
        print("No zbranch found to patch")
