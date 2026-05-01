import sys 

# disctionay mapping instruction names to the 4 bit opcode 

OPCODE_MAP = {
    "LOADI":"0",
    "ADD":"1",
    "SUB":"2",
    "MOV":"3",
    "READ":"4",
    "WRITE":"5",
    "JUMP":"6",
    "JNZ" : "7",
    "MUL" : "8",
    "HALT": "E"
}

def assemble (input_file):
    output_hex = []

    last_write  = None

    second_last_write= None

    with open(input_file, 'r') as f:
        for line in f:
            # cleaing the line from commensts
            line  =  line.split("//")[0].strip()

            if not line: continue

            parts = line.replace(',','').split()
            instr = parts[0].upper()

            # 2 building the hex code.
            hex_val = ""
            current_reads=[]
            reg_dest = None

            if instr in OPCODE_MAP:
                opcode = OPCODE_MAP[instr]

                if instr ==  "HALT":
                    # to ensure all the contents are flushed 
                    output_hex.append("0000")
                    output_hex.append("0000")
                    hex_val = "E000"
                
                elif instr == "LOADI":
                    #LOADI R1, value
                    reg_dest =int(parts[1].replace("R",""))
                    imm = int(parts[2])


                    binary_instr = (int(opcode, 16) << 12) | (reg_dest << 9) | imm
                    hex_val = f"{binary_instr:04X}"

                    # hex_val  = f"{opcode}{reg}{imm:02X}" ## ***** Could be a problem here in opcode generation int he immediate values 

                elif instr in ["ADD", "SUB","MUL"]:
                    # ADD/SUB R1, R2

                    reg_dest = int(parts[1].replace("R",""))
                    reg_src = int(parts[2].replace("R",""))

                    # Making a binary instr
                    binary_instr = (int(opcode,16) <<12) | (reg_dest << 9) | (reg_src << 6)
                    hex_val = f"{binary_instr:04X}"

                    current_reads = [reg_dest, reg_src]



                elif instr == "JUMP":
                    addr = int(parts[1])
                    hex_val = f"{opcode}{addr:03X}"
        

                elif instr == "MOV":
                    reg_dest = int(parts[1].replace("R",""))
                    reg_src = int(parts[2].replace("R",""))

                    binary_instr = (int(opcode,16) <<12) | (reg_dest << 9) | (reg_src << 6 )

                    hex_val = f"{binary_instr:04X}"

                    current_reads = [reg_src]


                elif instr == "READ":
                    reg_dest = int(parts[1].replace("R",""))
                    addr = int(parts[2])

                    binary_instr = (int(opcode,16) <<12) | (reg_dest << 9) | addr
                    hex_val = f"{binary_instr:04X}"

                    current_reads = [reg_dest]



                elif instr == "WRITE":

                    reg_src = int(parts[1].replace("R",""))
                    addr = int(parts[2])
                    binary_instr = (int(opcode,16) <<12) | (reg_src << 9) | addr

                    hex_val = f"{binary_instr:04X}"

                    current_reads = [reg_src]


                elif instr == "JNZ":
                    addr = int(parts[1])
                    binary_instr = (int(opcode,16) <<12) | addr
                    hex_val = f"{binary_instr:04X}"


                # Check if we need to insert NOPs (Bubbles)
            
            
          
            
            # Check 1-instruction-ago hazard
            if last_write is not None and last_write in current_reads:
                output_hex.append("0000") # Insert NOP
                output_hex.append("0000") # Insert NOP
                # After 2 NOPs, the previous writes are cleared
                last_write = None
                second_last_write = None

            
            # Check 2-instructions-ago hazard
            elif second_last_write is not None and second_last_write in current_reads:
                output_hex.append("0000") # Insert NOP
                second_last_write = None

       
            
            output_hex.append(hex_val)
            if instr == "JNZ":
             output_hex.append("0000")
             output_hex.append("0000")

           

# Update the pipeline "memory" for the NEXT instruction
            second_last_write = last_write
            last_write = reg_dest
        

    
    with open("program.txt", "w") as f:
        for h in output_hex:
            f.write(h + "\n")

    print("Successfully assembled")


if __name__ == "__main__":
        assemble("code.asm")