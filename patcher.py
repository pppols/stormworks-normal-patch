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

def scan_for_signature(data, signature, search_start=0, search_length=None):

    offset = search_start
    search_end = (len(data)  if search_length is None  else search_start + search_length)
    match_length = len(signature)
    matches = []
    
    while True:
        
        index = data.find(signature, offset, search_end)

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

    # verify signatures
    if data[0:2] != b"MZ":
        raise ValueError("invalid dos signature")


    pe_offset = read_u32(data, 0x3C)

    if data[pe_offset:pe_offset + 4] != b"PE\x00\x00":
        raise ValueError("invalid pe signature")


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

def scan_for_hook_signatures(data, payload):

    hook_addresses = []

    for hook in HOOKS:

        hook_entry_signature = hook["hook_entry"]
        hook_return_signature = hook["hook_return"]
        payload_entry_signature = hook["payload_entry"]
        payload_return_signature = hook["payload_return"]


        # hook entry
        matches = scan_for_signature(data, hook_entry_signature)

        if len(matches) != 1:
            break

        hook_entry_offset = matches[0]

        # hook return
        matches = scan_for_signature(data, hook_return_signature, hook_entry_offset, 0x200) # expected maximum delta of 0x1A8

        if len(matches) != 1:
            break

        hook_return_offset = matches[0]


        # payload entry
        matches = scan_for_signature(payload, payload_entry_signature)

        if len(matches) != 1:
            break

        payload_entry_offset = matches[0] + len(payload_entry_signature) # instructions begin after the marker 

        # payload return
        matches = scan_for_signature(payload, payload_return_signature, payload_entry_offset, 0x200)

        if len(matches) != 1:
            break

        payload_return_offset = matches[0]


        # insert addresses
        hook_addresses.append({
            "hook_entry": hook_entry_offset,
            "hook_return": hook_return_offset,
            "payload_entry": payload_entry_offset,
            "payload_return": payload_return_offset
        })


    # handle early exit
    if len(hook_addresses) != len(HOOKS):
        messagebox.showerror(
            "Error!",
            "An unexpected number of hooks signatures were found!\nThis likely indicates this patcher is out of date\nPlease check for any updates!"
        )
        raise SystemExit


    return hook_addresses

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

def get_hook_instructions(section_headers, patch_rva, hook_addresses):

    hook_instructions = []

    for hook in hook_addresses:

        hook_entry_offset = hook["hook_entry"]
        hook_return_offset = hook["hook_return"]
        payload_entry_offset = hook["payload_entry"]
        payload_return_offset = hook["payload_return"]

        # entry jump
        hook_entry_rva = offset_to_rva(hook_entry_offset, section_headers)
        payload_entry_rva = patch_rva + payload_entry_offset
        entry_jump = relative_jump(hook_entry_rva, payload_entry_rva)

        # return jump
        hook_return_rva = offset_to_rva(hook_return_offset, section_headers)
        payload_return_rva = patch_rva + payload_return_offset
        return_jump = relative_jump(payload_return_rva, hook_return_rva)

        # insert instructions
        hook_instructions.append({
            "entry_jump": entry_jump,
            "return_jump": return_jump
        })
    
    return hook_instructions

def insert_hooks(data, payload, hook_addresses, hook_instructions):

    hook_count = len(HOOKS)

    for i in range(hook_count):

        hook_address = hook_addresses[i]
        hook_instruction = hook_instructions[i]

        entry_address = hook_address["hook_entry"]
        return_address = hook_address["payload_return"]
        entry_jump = hook_instruction["entry_jump"]
        return_jump = hook_instruction["return_jump"]

        data[entry_address:entry_address + 5] = entry_jump
        payload[return_address:return_address + 5] = return_jump

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

EXPECTED_EXE_HASH = "c38c03ff756b4f42bbc9f11cdbb034977ad0f968e45741c5cf410732f22a338d"
EXPECTED_PAYLOAD_HASH = "a03db562458437a448bd2c6794bdade10c3a35d38a29e99c9ae59b6455303239"
PATCH_PAYLOAD_PATH = (Path(__file__).resolve().parent / "fixed_normal_calculation.bin")

HOOKS = [
    { # a1
        "hook_entry": bytes.fromhex("F3 0F 10 49 14   F3 0F 10 41 10   F3 0F 10 51 18   F3 44 0F 59 E8   F3 44 0F 59 E1"),
        "hook_return": bytes.fromhex("F3 44 0F 11 7E 10   F3 44 0F 11 76 14   F3 44 0F 11 6E 18   48 8B 44 24 28   8B 40 38"),
        "payload_entry": bytes.fromhex("E8 11 11 11"),
        "payload_return": bytes.fromhex("E9 11 11 11 11"),
    },
    { # a2
        "hook_entry": bytes.fromhex("F3 0F 10 59 14   F3 0F 10 51 10   F3 0F 10 61 18   F3 44 0F 10 6D 08   F3 44 0F 59 EA"),
        "hook_return": bytes.fromhex("F3 44 0F 11 7E 10   F3 44 0F 11 76 14   F3 44 0F 11 6E 18   48 8B 44 24 28   8B 40 38"),
        "payload_entry": bytes.fromhex("E8 22 22 22"),
        "payload_return": bytes.fromhex("E9 22 22 22 22"),
    },
    { # b1
        "hook_entry": bytes.fromhex("F3 0F 10 61 14   F3 0F 10 51 10   F3 0F 10 59 18   0F 28 EC   F3 0F 59 6D 58"),
        "hook_return": bytes.fromhex("F3 0F 11 63 10   F3 0F 11 73 14   F3 0F 11 6B 18   48 8B 44 24 28   8B 40 38"),
        "payload_entry": bytes.fromhex("E8 33 33 33"),
        "payload_return": bytes.fromhex("E9 33 33 33 33"),
    },
    { # b2
        "hook_entry": bytes.fromhex("F3 0F 10 61 14   F3 0F 10 51 10   F3 0F 10 59 18   0F 28 EC   F3 0F 59 6D 18"),
        "hook_return": bytes.fromhex("F3 0F 11 63 10   F3 0F 11 73 14   F3 0F 11 6B 18   48 8B 44 24 28   8B 40 38"),
        "payload_entry": bytes.fromhex("E8 44 44 44"),
        "payload_return": bytes.fromhex("E9 44 44 44 44"),
    },
    { # face
        "hook_entry": bytes.fromhex("F3 44 0F 10 45 08   F3 44 0F 59 C2   F3 0F 10 45 18   F3 0F 59 C3   F3 44 0F 58 C0"),
        "hook_return": bytes.fromhex("8B 4F 10   44 8B 47 08   41 8D 72 21   41 3B C8   75 1C"),
        "payload_entry": bytes.fromhex("E8 55 55 55"),
        "payload_return": bytes.fromhex("E9 55 55 55 55"),
    },
    { # virtual
        "hook_entry": bytes.fromhex("F3 42 0F 10 74 09 14   F3 42 0F 10 5C 09 10   0F 28 EE   F3 42 0F 10 64 09 18   0F 28 D6"),
        "hook_return": bytes.fromhex("0F B7 04 7A   48 6B C8 1C   46 0F B6 44 09 0C   41 8D 80 01 FF FF FF   99"),
        "payload_entry": bytes.fromhex("E8 66 66 66"),
        "payload_return": bytes.fromhex("E9 66 66 66 66"),
    }
]



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

    # scan for hook signatures
    hook_addresses = scan_for_hook_signatures(data, payload)

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

    # insert hooks
    hook_instructions = get_hook_instructions(section_headers, patch_rva, hook_addresses)
    insert_hooks(data, payload, hook_addresses, hook_instructions)

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