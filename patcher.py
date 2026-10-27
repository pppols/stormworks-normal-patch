from tkinter import Tk, filedialog, messagebox
from pathlib import Path
import struct
import hashlib



def read_u16(data, offset):
    return struct.unpack_from("<H", data, offset)[0]

def read_u32(data, offset):
    return struct.unpack_from("<I", data, offset)[0]

def write_u16(data, offset, value):
    struct.pack_into("<H", data, offset, value)

def write_u32(data, offset, value):
    struct.pack_into("<I", data, offset, value)

def allign(value, allignment):
    return (value + allignment - 1) // allignment * allignment

def offset_to_rva(offset, section_headers):

    for header in section_headers:

        section_start = header["raw_offset"]
        section_end = section_start + header["raw_size"]

        if section_start <= offset < section_end:
            return header["rva"] + (offset - section_start)

    raise ValueError("could not find rva from offset")

def relative_jump(source_rva, destination_rva):
    displacement = destination_rva - source_rva - 5
    return b"\xE9" + struct.pack("<i", displacement)

def get_checksum(data, optional_offset):

    checksum_offset = optional_offset + 64
    checksum = 0
    length = len(data)

    for offset in range(0, length, 2):

        # exclude four byte checksum itself
        if checksum_offset <= offset < checksum_offset + 4:
            word = 0

        elif offset + 1 < length:
            word = data[offset] | (data[offset + 1] << 8)

        else:
            word = data[offset]

        checksum += word
        checksum = (checksum & 0xFFFF) + (checksum >> 16)

    checksum = (checksum & 0xFFFF) + (checksum >> 16)
    checksum = (checksum + length) & 0xFFFFFFFF

    return checksum

def save_to_file(data, path):
    path.write_bytes(data)

def scan_for_signiature(data, signiature, search_start=0, search_length=None):

    offset = search_start
    search_end = (len(data)  if search_length is None  else search_start + search_length)
    match_length = len(signiature)
    matches = []
    
    while True:
        
        index = data.find(signiature, offset, search_end)

        if index == -1:
            break

        matches.append(index)
        offset = index + match_length

    return matches


def load_payload(payload_path):

    payload = bytearray(payload_path.read_bytes())


    # confirm hash
    hash = hashlib.sha256(payload).hexdigest()

    if hash != EXPECTED_PAYLOAD_HASH:

        messagebox.showerror(
            "Error!",
            "The patch payload is malformed or corrupted!\nThis likely indicates that a mistake has been made in distributing or downloading the build\nPlease check for updates to this patcher!"
        )

        raise SystemExit


    return payload

def load_exe(exe_path):

    data = bytearray(exe_path.read_bytes())


    # confirm hash
    hash = hashlib.sha256(data).hexdigest()

    if hash != EXPECTED_EXE_HASH:

        confirmed = messagebox.askokcancel(
            "Warning!",
            "This executable is malformed, or has been modified from the expected version!\nThis may indicate that the game has since been updated\nGame updates may result in a failed patch!\nContinue anyways?",
            icon="warning"
        )

        if not confirmed:
            raise SystemExit


    return data

def get_headers(data):

    # verify signiatures
    if data[0:2] != b"MZ":
        raise ValueError("invalid dos signiature")


    pe_offset = read_u32(data, 0x3C)

    if data[pe_offset:pe_offset + 4] != b"PE\x00\x00":
        raise ValueError("invalid pe signiature")


    coff_offset = pe_offset + 4
    optional_offset = coff_offset + 20

    section_count = read_u16(data, coff_offset + 2)
    optional_size = read_u16(data, coff_offset + 16)

    if read_u16(data, optional_offset) != 0x020B:
        raise ValueError("missing executable header")


    section_offset = optional_offset + optional_size


    return (coff_offset, optional_offset, section_offset, section_count)

def get_section_headers(data, section_offset, section_count):

    section_headers = []

    for i in range(section_count):

        offset = section_offset + 40*i

        name = data[offset:offset+8]
        name = name.split(b"\x00", 1)[0].decode("ascii")

        header = {
            "name": name,
            "header_offset": offset,
            "virtual_size": read_u32(data, offset+8),
            "rva": read_u32(data, offset+12),
            "raw_size": read_u32(data, offset+16),
            "raw_offset": read_u32(data, offset+20),
            "flags": read_u32(data, offset+36)
        }

        section_headers.append(header)

    return section_headers

def get_allignments(data, optional_offset):

    section_allignment = read_u32(data, optional_offset + 32)
    file_allignment = read_u32(data, optional_offset + 36)

    return (section_allignment, file_allignment)

def get_patch_section_details(data, optional_offset, section_offset, section_count, section_headers):

    # get and verify patch section header
    patch_header_offset = section_offset + 40*section_count

    first_raw_offset = min(
        header["raw_offset"]
        for header in section_headers
        if header["raw_offset"] > 0 and header["raw_size"] > 0
    )

    size_of_headers = read_u32(data, optional_offset + 60)

    if patch_header_offset + 40 > first_raw_offset:
        raise ValueError("not enough space before section data, i hope this fucking never happens for all future time in the universe to come ever")

    if patch_header_offset + 40 > size_of_headers:
        raise ValueError("not enough pe header space")

    if data[patch_header_offset:patch_header_offset+40] != bytes(40):
        raise ValueError("new header region not empty")


    # get patch section
    section_allignment = read_u32(data, optional_offset + 32)
    file_allignment = read_u32(data, optional_offset + 36)
        
    highest = max(
        header["rva"] + max(header["virtual_size"], header["raw_size"])
        for header in section_headers
    )
    
    patch_rva = allign(highest, section_allignment)
    patch_raw_offset = allign(len(data), file_allignment)
    
    
    return (patch_header_offset, patch_rva, patch_raw_offset)

def insert_patch_section_header(data, header_offset, section_rva, section_raw_offset, section_size, file_allignment):

    section_raw_size = allign(section_size, file_allignment)

    struct.pack_into("<8sIIIIIIHHI", data, header_offset,
        b".patch",
        section_size,
        section_rva,
        section_raw_size,
        section_raw_offset,
        0,
        0,
        0,
        0,
        0x60000020 # flags (readable, executable, contains code)
    )

def insert_patch_section(data, payload, raw_offset, file_allignment):

    raw_size = allign(len(payload), file_allignment)

    if len(data) > raw_offset:
        raise ValueError("patch section overlaps existing exe data")

    # extend and patch file
    data.extend(b"\x00" * (raw_offset - len(data)))

    data.extend(payload)

    data.extend(b"\x00" * (raw_size - len(payload)))

def get_trampoline_instructions(section_headers, hook_entry_offset, hook_return_offset, payload_return_offset, patch_rva):

    # entry jump
    hook_entry_rva = offset_to_rva(hook_entry_offset, section_headers)
    hook_jump = relative_jump(hook_entry_rva, patch_rva)

    # return jump
    hook_return_rva = offset_to_rva(hook_return_offset, section_headers)
    return_jump = relative_jump(patch_rva + payload_return_offset, hook_return_rva)

    return (hook_jump, return_jump)

def insert_trampoline(data, payload, hook_offset, return_offset, hook_jump, return_jump):

    data[hook_offset:hook_offset + 5] = hook_jump
    payload[return_offset:return_offset + 5] = return_jump

def update_headers(data, payload, coff_offset, optional_offset, section_count, section_allignment, file_allignment, patch_rva):

    # upate section count
    write_u16(data, coff_offset + 2, section_count + 1)

    # update image size
    new_image_size = allign(patch_rva + len(payload), section_allignment)
    write_u32(data, optional_offset + 56, new_image_size)

    # update code size
    raw_size = allign(len(payload), file_allignment)
    previous_size = read_u32(data, optional_offset + 4)
    write_u32(data, optional_offset + 4, previous_size + raw_size)

    # update checksum
    checksum = get_checksum(data, optional_offset)
    write_u32(data, optional_offset + 64, checksum)

EXPECTED_EXE_HASH = "f9206d85c82f4d02fd0ac391781d19c5c68394a9ffc48accca0e1f5966db8699"
EXPECTED_PAYLOAD_HASH = "0abdcea5c39702fbdff1b84bc2c21d7c71bcf49b68c0086513fb89ef5d330507"
HOOK_ENTRY_SIGNIATURE = bytes.fromhex("F3 0F 10 61 14   F3 0F 10 51 10   F3 0F 10 59 18   0F 28 EC   F3 0F 59 6D 18")
HOOK_RETURN_SIGNIATURE = bytes.fromhex("F3 0F 11 63 10   F3 0F 11 73 14   F3 0F 11 6B 18")
PAYLOAD_RETURN_SIGNIATURE = bytes.fromhex("E9 78 56 34 12")
PATCH_PAYLOAD_PATH = (Path(__file__).resolve().parent / "fixed_normal_calculation.bin")



# main
root = Tk()
root.withdraw()

try:
    # prompt for executable path
    exe_path = filedialog.askopenfilename(
        title = "Select Stormworks Executable (prefer 64 bit)", 
        filetypes = [
            ("Windows Executables", "*.exe"), 
            ("All Files", "*.*")
        ]
    )

    if not exe_path:
        raise SystemExit

    backup_path = Path(exe_path + ".bak")
    exe_path = Path(exe_path)


    # minor safeguard
    if not "stormworks" in exe_path.name:
        messagebox.showerror(
            "Invalid file", 
            "Please select a valid stormworks executable"
        )
        raise SystemExit


    # confirm patch
    confirmed = messagebox.askokcancel(
        "Normal Calculation Patch",
        f"Target executable:\n{exe_path}\n\nA backup of the original will be created\nContinue?"
    )

    if not confirmed:
        raise SystemExit


    # load patch payload
    payload = load_payload(PATCH_PAYLOAD_PATH)

    # load executable
    data = load_exe(exe_path)

    # get headers and details
    coff_offset, optional_offset, section_offset, section_count = get_headers(data)
    section_allignment, file_allignment = get_allignments(data, optional_offset)
    section_headers = get_section_headers(data, section_offset, section_count)

    # check for existing patch region
    if any(header["name"] == ".patch" for header in section_headers):
        messagebox.showwarning(
            "Warning!",
            "The patch has already been applied to this executable!"
        )
        raise SystemExit

    # get patch details
    patch_header_offset, patch_rva, patch_raw_offset = get_patch_section_details(data, optional_offset, section_offset, section_count, section_headers)

    # scan for exe signiatures
    matches = scan_for_signiature(data, HOOK_ENTRY_SIGNIATURE)
    
    if len(matches) != 1:
        messagebox.showerror(
            "Error!",
            f"An unexpected number ({len(matches)}) of hook entry signiatures were found!\nThis likely indicates this patcher is out of date\nPlease check for any updates!"
        )
        raise SystemExit
    
    hook_entry_offset = matches[0]
    matches = scan_for_signiature(data, HOOK_RETURN_SIGNIATURE, hook_entry_offset, 0x200) # expecting a 0x66 delta

    if len(matches) != 1:
        messagebox.showerror(
            "Error!",
            f"An unexpected number ({len(matches)}) of hook return signiatures were found!\nThis likely indicates this patcher is out of date\nPlease check for any updates!"
        )
        raise SystemExit

    hook_return_offset = matches[0]

    # scan for payload signiature
    matches = scan_for_signiature(payload, PAYLOAD_RETURN_SIGNIATURE)

    if len(matches) != 1:
        messagebox.showerror(
            "Error!",
            f"An unexpected number ({len(matches)}) of patch return signiatures were found!\nThis likely indicates this patcher is out of date\nPlease check for any updates!"
        )
        raise SystemExit

    payload_return_offset = matches[0]

    # backup executable
    if backup_path.exists():
    
        response = messagebox.askyesnocancel(
            "Backup Already Exists",
            "A backup already exists at the attempted location!\nOverwrite it?"
        )
    
        if response is True:
            save_to_file(data, backup_path)
    
        if response is None:
            raise SystemExit
    
    else:
        save_to_file(data, backup_path)

    # insert trampoline
    hook_jump, return_jump = get_trampoline_instructions(section_headers, hook_entry_offset, hook_return_offset, payload_return_offset, patch_rva)
    insert_trampoline(data, payload, hook_entry_offset, payload_return_offset, hook_jump, return_jump)

    # insert patch
    insert_patch_section_header(data, patch_header_offset, patch_rva, patch_raw_offset, len(payload), file_allignment)
    insert_patch_section(data, payload, patch_raw_offset, file_allignment)

    # update headers
    update_headers(data, payload, coff_offset, optional_offset, section_count, section_allignment, file_allignment, patch_rva)

    # update executable
    save_to_file(data, exe_path)


    # patch complete
    messagebox.showinfo(
        "Patch Successful!",
        f"Patched executable at:\n{exe_path}\n\nBackup available at:\n{backup_path}",
    )

except (ValueError, OSError, struct.error) as error:
    messagebox.showerror(
        "Patching failed!",
        str(error)
    )

finally:
    root.destroy()