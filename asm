#!/usr/bin/python
"""
 *****************************************************************************
   FILE:        sasm

   AUTHOR:      Grace Woolson

   ASSIGNMENT:  SIC/XE Assembler

   DATE:        5/3/2019

 *****************************************************************************
"""

import sys       #gives access to command line
import re        #regex


symbol_table = {}
offset = ""
optable = {
  "add" : "0x18",
  "addf" : "0x58",
  "addr" : "0x90",
  "and" : "0x40",
  "clear" : "0xB4",
  "comp" : "0x28",
  "compf" : "0x88",
  "compr" : "0xA0",
  "div" : "0x24",
  "divf" : "0x64",
  "divr" : "0x9C",
  "fix" : "0xC4",
  "float" : "0xC0",
  "hio" : "0xF4",
  "j" : "0x3C",
  "jeq" : "0x30",
  "jgt" : "0x34",
  "jlt" : "0x38",
  "jsub" : "0x48",
  "lda" : "0x00",
  "ldb" : "0x68",
  "ldch" : "0x50",
  "ldf" : "0x70",
  "ldl" : "0x08",
  "lds" : "0x6C",
  "ldt" : "0x74",
  "ldx" : "0x04",
  "lps" : "0xD0",
  "mul" : "0x20",
  "mulf" : "0x60",
  "mulr" : "0x98",
  "norm" : "0xC8",
  "or" : "0x44",
  "rd" : "0xD8",
  "rmo" : "0xAC",
  "rsub" : "0x4C",
  "shiftl" : "0xA4",
  "shiftr" : "0xA8",
  "sio" : "0xF0",
  "ssk" : "0xEC",
  "sta" : "0x0C",
  "stb" : "0x78",
  "stch" : "0x54",
  "stf" : "0x80",
  "sti" : "0xD4",
  "stl" : "0x14",
  "sts" : "0x7C",
  "stsw" : "0xE8",
  "stt" : "0x84",
  "stx" : "0x10",
  "sub" : "0x1C",
  "subf" : "0x5C",
  "subr" : "0x94",
  "svc" : "0xB0",
  "td" : "0xE0",
  "tio" : "0xF8",
  "tix" : "0x2C",
  "tixr" : "0xB8",
  "wd" : "0xDC"
  }

def first_pass():
    global offset

    if len(sys.argv) < 2:
      print("Usage: sasm <file.asm> <file.obj>")
      exit(1)

    # print("SIC/XE Assembler Version 1.6")

    filename = sys.argv[1]
    infile = open(filename, "r")

    #reads the first line with characters
    (caseline, line) = read_file(infile)
    first_line = line.split()

    error_catch(line)

    #sets the offset
    has_start = start_test(first_line)
    has_label = label_test(first_line[0])


    #UPDATE THIS PART ************************************
    if not has_start:
      next_line = first_line
      #print(next_line)

      next_first_word = next_line[0]

      #maybe? update this
      #(label, connected) = label_test(next_first_word)

      #if resb or resw, adjust offset accordingly
      #if byte, adjust accordingly
      #if not, if end add 1 to offset
      #if not, add 3 to offset

      if has_label:
        opcode = next_line[1]
      else:
        opcode = next_line[0]

      if opcode == 'resb':
        resb_loc = next_line.index('resb')
        bvalue = int(next_line[resb_loc + 1])
        offset = hex_add(offset, bvalue)

      elif opcode == 'resw':
        resw_loc = next_line.index('resw')
        wvalue = 3 * int(next_line[resw_loc + 1])
        offset = hex_add(offset, wvalue)

      elif opcode == 'byte':
        byte_loc = next_line.index('byte')
        byte_value = next_line[byte_loc + 1]
        #print(next_line)
        #print(byte_value)

        bytes_length = len(byte_value) - 3

        if (byte_value[0] == 'C') or (byte_value[0] == 'c'):
          #need to check for ERROR if user forgot to put quotes
          #minus 3 because of C and quotes
          if byte_value[-1] == "\'":
            closed = True
          else:
            bytes_length += 1
            closed = False

          #print(bytes_length)
          offset = hex_add(offset, bytes_length)
          index = byte_loc + 1

          while not closed:
            index += 1
            byte_value = next_line[index]
            #need to check for ERROR if user forgot to put quotes
            #minus 3 because of C and quotes
            #need to account for if a person inputs many spaces
            if byte_value[-1] == "\'":
              closed = True
              byte_value = next_line[index]
              bytes_length = len(byte_value)
              #print(bytes_length)
              offset = hex_add(offset, bytes_length)
            else:
              byte_value = next_line[index]
              bytes_length = len(byte_value) + 1
              #print(bytes_length)
              offset = hex_add(offset, bytes_length)
              closed = False


        elif (byte_value[0] == 'X') or (byte_value[0] == 'x'):
          #print(bytes_length)
          if bytes_length % 2 == 0:
            offset = hex_add(offset, int(bytes_length / 2))
          else:
            offset = hex_add(offset, int((bytes_length + 1) / 2))

        else:
          offset = hex_add(offset, 1)

      elif opcode == 'word':
        offset = hex_add(offset, 3)

      elif opcode[0] == '+':
        offset = hex_add(offset, 4)

      #special 5 and type 2 6
      elif opcode in ['svc', 'clear', 'tixr', 'shiftl', 'shiftr', 'addr', 'compr', 'divr', 'mulr', 'rmo', 'subr']:
        offset = hex_add(offset, 2)

      elif opcode in ['fix', 'float', 'hio', 'norm', 'sio', 'tio']:
          offset = hex_add(offset, 1)

      elif (opcode != "base") and (opcode != "nobase"):
        offset = hex_add(offset, 3)


    end = False

    while not end:
      (o_line, n_line) = read_file(infile)
      next_line = n_line.split()

      if 'end' in next_line:
        end = True

      next_first_word = next_line[0]

      has_label = label_test(next_first_word)

      if has_label:
        opcode = next_line[1]
      else:
        opcode = next_line[0]


      #if resb or resw, adjust offset accordingly
      #if byte, adjust accordingly
      #if not, if end add 1 to offset
      #if not, add 3 to offset
      if not end:

        error_catch(n_line)

        if opcode == 'resb':
          resb_loc = next_line.index('resb')
          bvalue = int(next_line[resb_loc + 1])
          offset = hex_add(offset, bvalue)

        elif opcode == 'resw':
          resw_loc = next_line.index('resw')
          wvalue = 3 * int(next_line[resw_loc + 1])
          offset = hex_add(offset, wvalue)

        elif opcode == 'byte':
          byte_loc = next_line.index('byte')
          byte_value = next_line[byte_loc + 1]
          #print(next_line)
          #print(byte_value)

          bytes_length = len(byte_value) - 3

          if (byte_value[0] == 'C') or (byte_value[0] == 'c'):
          	#need to check for ERROR if user forgot to put quotes
          	#minus 3 because of C and quotes
            if byte_value[-1] == "\'":
              closed = True
            else:
              bytes_length += 1
              closed = False

            #print(bytes_length)
            offset = hex_add(offset, bytes_length)
            index = byte_loc + 1

            while not closed:
              index += 1
              byte_value = next_line[index]
              #need to check for ERROR if user forgot to put quotes
              #minus 3 because of C and quotes
              #need to account for if a person inputs many spaces
              if byte_value[-1] == "\'":
                closed = True
                byte_value = next_line[index]
                bytes_length = len(byte_value)
                #print(bytes_length)
                offset = hex_add(offset, bytes_length)
              else:
                byte_value = next_line[index]
                bytes_length = len(byte_value) + 1
                #print(bytes_length)
                offset = hex_add(offset, bytes_length)
                closed = False


          elif (byte_value[0] == 'X') or (byte_value[0] == 'x'):
            #print(bytes_length)
            if bytes_length % 2 == 0:
              offset = hex_add(offset, int(bytes_length / 2))
            else:
              offset = hex_add(offset, int((bytes_length + 1) / 2))

          else:
            offset = hex_add(offset, 1)

        elif opcode == 'word':
          offset = hex_add(offset, 3)

        elif opcode[0] == '+':
          offset = hex_add(offset, 4)

        #special 5 and type 2 6
        elif opcode in ['svc', 'clear', 'tixr', 'shiftl', 'shiftr', 'addr', 'compr', 'divr', 'mulr', 'rmo', 'subr']:
          offset = hex_add(offset, 2)

        elif opcode in ['fix', 'float', 'hio', 'norm', 'sio', 'tio']:
          offset = hex_add(offset, 1)

        elif (opcode != "base") and (opcode != "nobase"):
          offset = hex_add(offset, 3)



    #print_symbol_table()

    infile.close()

    return


def error_catch(line):
  no_spaces = line.split()

  operand = no_spaces[-1]

  if operand[0] == '#':
    if ',' in operand:
      print("Cannot have immediate and indexed operand")
      exit(1)


  #weird overflow
  on_col = 0

  match_operand = ""
  i = 0

  for char in line:
    #comment_chars = re.match(r'\s|\t')
    #print(on_col)
    on_col += 1

    if char == operand[i]:
      match_operand += char
      i += 1
      if i == len(operand):
        i = 0
    else:
      match_operand = ""
      i = 0

    if on_col == 40:
      if (i != 0) and (i < len(operand)):
        print("Operand overflows into comments!")
        exit(1)

  return

def start_test(start_line):

  if 'start' in start_line:
    start_pos = start_line.index('start')
    str_offset = start_line[start_pos + 1]

    global offset
    offset = int(str_offset)

    hex_str = "0x" + str_offset
    #print(hex_str)
    hex_number = hex_str[2:]
    #print(hex_number)

    if len(hex_number) > 5:
      print("Starting offset value too great")
      exit(1)

    return True

  #if no start directive, set starting offset to 0
  else:
    offset = 0
    return False



def read_file(infile):

    more_instructions = False

    while not more_instructions:
      line = infile.readline()

      if line == "":
        print("Error: No end statement")
        exit(1)

      is_comment = comment_test(line)
      if not is_comment:
        more_instructions = True

    line = detabify(line)
    cased_line = line.lower()

    return (line[:40], cased_line[:40])

def comment_test(line):
    on_col = 0

    comment = False
    more_instructions = False

    for char in line:
      valid_chars = re.match(r'^[A-Za-z0-9]', char)
      #comment_chars = re.match(r'\s|\t')

      if char == ".":
        comment = True

      #elif (char != " ") and (char != ".") and (comment != True) and (char != "\t"):
      elif valid_chars:
        if on_col >= 40:
          comment = True
        else:
          more_instructions = True

      if char == '\t':
        filled = on_col % 8
        remainder = 8 - filled

        on_col = on_col + remainder

      else:
        on_col += 1

      if more_instructions == True:
        return False
      if comment == True:
        return True

    return True


def label_test(word):

    tries_to_label = re.match(r'^.*:', word)
    is_a_label = re.match(r'^\s*[A-Za-z][A-Za-z0-9]*:', word)

    if tries_to_label and (not is_a_label):
      print("invalid label")
      exit(1)

    # r = treat as raw string
    # ^ = start at beginning of string
    # \s = any whitespace character
    global symbol_table
    global offset

    if is_a_label:

      #make sure word only includes the label
      end_loc = word.index(":")
      word = word[:end_loc + 1]


      #also check if symbol has already been used
      word_length = len(word)
      label = word[:word_length - 1]

      if label.upper() in symbol_table.keys():
          print("Redefinition of symbol, %s" % label.upper())
          exit(1)
      else:
          global offset

          symbol_table[label.upper()] = three_bytes(offset)

      return True

    return False

def three_bytes(offset):
    offset = str(offset)
    existing = len(offset)
    remainder = 6 - existing

    for i in range(0, remainder):
      offset = '0' + offset

    return offset


def hex_add(number, to_add):
    #adds number in hex then returns sum

    string_number = str(number)
    hex_number = "0x" + string_number
    hex_add = hex(to_add)

    my_sum = int(hex_number, 0) + int(hex_add, 0)
    #print(my_sum)
    hex_sum = hex(my_sum).upper()
    final_offset = hex_sum[2:]

    return final_offset


def print_symbol_table():
  #need to adjust to print in alphabetical order
    global symbol_table

    print("Symbols:")

    all_keys = sorted(symbol_table)
    for key in all_keys:
      #print('  %s: ' % key, end='')
      print(symbol_table[key])



def detabify(line):

    result_string = ""

    i = 0
    for char in line:
        if char == '\t':
            filled = i % 8
            remainder = 8 - filled
            spaces = " " * remainder
            result_string = result_string + spaces
            i = i + remainder
        else:
            result_string = result_string + char
            i += 1

    return result_string

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------


def second_pass():
    global optable
    global offset

    format_1 = ["fix", "float", "hio", "norm", "sio", "tio"]
    format_2 = ["addr", "clear", "compr", "divr", "mulr", "rmo", "shiftl", "shiftr", "subr", "svc", "tixr"]

    in_file = sys.argv[1]
    out_file = sys.argv[2]

    infile = open(in_file, 'r')
    outfile = open(out_file, 'wb')

    object_code = ""

    (ogline, line) = read_file(infile)
    words_line = line.split()

    (has_start, hcode) = write_header(line, outfile)
    object_code += hcode

    start_offset = offset

    if has_start:
      (ogline, line) = read_file(infile)
      words_line = line.split()


    t_size = 0
    text_record = ""
    based_addressing = False
    reserving = False
    end = False

    #print(three_bytes(offset))

    #initiate first text record
    #TAAAAAASS
    text_record += "T"
    text_record += three_bytes(offset)
    #leave a blank space for the size

    while not end:
      has_label = label_test_2(line)
      opcode = get_opcode(line)

      #special cases:
      if opcode == "rsub":
        if has_label:
          if len(words_line) > 2:
            print("extra characters")
            exit(1)
        else:
          if len(words_line) > 1:
            print("extra characters")
            exit(1)

        text_record += sic_instruction(opcode, "0")
        offset = hex_add(offset, 3)
        t_size += 3
        pass

      elif opcode in format_1:
        text_record += format1(opcode)
        offset = hex_add(offset, 1)
        t_size += 1

      elif opcode in format_2:
        (r1, r2) = f2_operands(line)

        text_record += format2(opcode, r1, r2)
        offset = hex_add(offset, 2)
        t_size += 2

      elif opcode == "byte":
        (b_value, size) = byte_value(ogline, line)
        text_record += b_value
        t_size += size

      else:

        #operand is a 
        operand = find_operand(line)

        if (operand[0] == "#") or (operand[0] == "@"):
          comp_operand = operand[1:]
        else:
          comp_operand = operand

        if opcode == "word":
          text_record += word_value(operand)
          t_size += 3

        elif opcode == "resb":
          reserving = True

          if t_size > 0:
            record_size = "%02x" % t_size

            first = text_record[:7]
            rest = text_record[7:]

            text_record = first + record_size + rest

            object_code += text_record 

            t_size = 0
          text_record = reserve_byte(operand)



        elif opcode == "resw":

          reserving = True

          if t_size > 0:
            record_size = "%02x" % t_size

            first = text_record[:7]
            rest = text_record[7:]

            text_record = first + record_size + rest
            object_code += text_record 

            t_size = 0
          text_record = reserve_word(operand)


        elif opcode == "base":
          based_addressing = True
          if has_label:
            base = hex(int(words_line[2]))[2:]
          else:
            base = hex(int(words_line[1]))[2:]

        elif opcode == "nobase":
          based_addressing = False


        elif opcode[0] == "+":
        #extended
          text_record += format4(opcode, operand)
          offset = hex_add(offset, 4)
          t_size += 4


        elif opcode not in optable:
          print("Invalid operation: %s" % opcode)
          exit(1)

        #this only works if the operand is not an int
        elif (comp_operand <= "007fff") and not (operand[0] in ['#', '@']) :
        #SIC
          #print(line)
          text_record += sic_instruction(opcode, operand)
          offset = hex_add(offset, 3)
          t_size += 3
          
        elif based_addressing == True:
          #based
          text_record += based_instruction(opcode, operand, base)
          offset = hex_add(offset, 3)
          t_size += 3

        elif comp_operand <= "000FFF":
        #direct
          text_record += direct_instruction(opcode, operand)
          offset = hex_add(offset, 3)
          t_size += 3

        else:
        #pc-relative
          offset = hex_add(offset, 3)
          text_record += pc_instruction(opcode, operand)
          t_size += 3


      #CHECK FOR 65 BYTE LIMIT
      if t_size >= 65:
        if t_size == 65:
          record_size = "%02x" % t_size

          first = text_record[:7]
          rest = text_record[7:]

          text_record = first + record_size + rest
          object_code += text_record 

          t_size = 0
          text_record = "T" + three_bytes(offset)

        else:
          #T + 6 for address plus 130 for text
          sized_text_record = text_record[:135]
          new_text_record = text_record[135:]
          record_size = "%02x" % 64

          first = sized_text_record[:7]
          rest = sized_text_record[7:]

          text_record = first + record_size + rest
          object_code += text_record 

          t_size = int(len(new_text_record) / 2)
          t_offset = hex_sub(offset, hex(t_size)[2:])
          text_record = "T" + three_bytes(t_offset) + new_text_record

      (ogline, line) = read_file(infile)
      words_line = line.split()
      if "end" in words_line:
        end = True
        if len(words_line) > 1:
          entry_label = words_line[1]
          entry_loc = symbol_table[entry_label.upper()]
        else:
          entry_loc = three_bytes(start_offset)
          #print(entry_loc)

        if not reserving:
          record_size = "%02x" % t_size
          first = text_record[:7]
          rest = text_record[7:]

          text_record = first + record_size + rest

          object_code += text_record 

      elif (not ("resb" in words_line)) and (not ("resw" in words_line)):
        reserving = False


      #end = True
      #object_code += text_record


    object_code = object_code + "E" + entry_loc

    to_machine_code(object_code, outfile)




def to_machine_code(object_code, outfile):
    hex_list = []

    i = 0
    while i < len(object_code):
      if i <= 6:
        hex_let = hex(ord(object_code[i]))
        hex_list.append(hex_let)
        i += 1

      else:
        if (object_code[i] == "T") or (object_code[i] == "E"):
          hex_let = hex(ord(object_code[i]))
          hex_list.append(hex_let)
          i += 1
        else:
          hex_val = "0x" + object_code[i] + object_code[i + 1]
          hex_list.append(hex_val)
          i += 2



    ascii_values = []
    for elem in hex_list:
      #print(elem)
      #a temporary fix to a stupid problem (adds an extra byte for some reason)
      char = chr(int(elem, 0))
      #print(char)
      outfile.write(char)


#byte
def byte_value(line, lowerline):
    global offset
    #print line

    object_code = ""

    next_line = line.split()

    byte_loc = next_line.index('byte')
    byte_value = next_line[byte_loc + 1]
    #print(next_line)
    #print(byte_value)

    bytes_length = len(byte_value) - 3

    if (byte_value[0] == 'C') or (byte_value[0] == 'c'):
      #need to check for ERROR if user forgot to put quotes
      #minus 3 because of C and quotes
      if byte_value[-1] == "\'":
        closed = True
        object_code += byte_value[2:-1]
      else:
        bytes_length += 1
        closed = False
        object_code += byte_value[2:]

      #print(bytes_length)
      offset = hex_add(offset, bytes_length)
      index = byte_loc + 1

      while not closed:
        index += 1
        byte_value = next_line[index]
        #need to check for ERROR if user forgot to put quotes
        #minus 3 because of C and quotes
        #need to account for if a person inputs many spaces
        if byte_value[-1] == "\'":
          closed = True
          object_code += byte_value[2:-1]
          byte_value = next_line[index]
          bytes_length = len(byte_value)
          #print(bytes_length)
          offset = hex_add(offset, bytes_length)
        else:
          byte_value = next_line[index]
          object_code += byte_value[2:]
          bytes_length = len(byte_value) + 1
          #print(bytes_length)
          offset = hex_add(offset, bytes_length)
          closed = False

      #PLEASE TEST THIS WOOLSON
      hex_object_code = ""
      for char in object_code:
        hexed = hex(ord(char))[2:]
        hex_object_code += hexed

      object_code = hex_object_code


    elif (byte_value[0] == 'X') or (byte_value[0] == 'x'):
      next_line = (line.lower()).split()

      byte_loc = next_line.index('byte')
      byte_value = next_line[byte_loc + 1]

      #print(bytes_length)
      value = byte_value[2:-1]
      if bytes_length % 2 == 0:
        object_code += value
        offset = hex_add(offset, int(bytes_length / 2))
        bytes_length = int(bytes_length / 2)
      else:
        object_code = object_code + "0" + byte_value[2:-1]
        offset = hex_add(offset, int((bytes_length + 1) / 2))
        bytes_length = int((bytes_length + 1) / 2)

    else:
      value = hex(int(byte_value))[2:]
      object_code += value
      offset = hex_add(offset, 1)
      bytes_length = 1

    return (object_code, bytes_length)

  
#word
def word_value(operand):
#should probably check if word is too large
    global offset
  
    """
    if operand > FFFFFF raise error
    """

    if type(operand) == int:
      object_code = "%06x" % operand
    else:
      object_code = "%06x" % int("0x" + operand, 0)

    return object_code


#resb
def reserve_byte(total_bytes):
  global offset

  offset = hex_add(offset, int(total_bytes))

  object_code = "T" + three_bytes(offset)

  return object_code

#resw
def reserve_word(words):
  global offset

  offset = hex_add(offset, int(words) * 3)

  object_code = "T" + three_bytes(offset)

  return object_code


#format4
def format4(mneumonic, operand):
    global offset

    mneumonic = mneumonic[1:]

    opcode = "{0:08b}".format(int(optable[mneumonic], 0))[:6]

    #n i x b p e
    if operand[0] == "@":
      n = "1"
      operand = operand[1:]
    else:
      n = "0"

    if operand[0] == '#':
      i = "1"
      operand = operand[1:]
    else:
      i = "0"

    if (n == "0") and (i == "0"):
      n = "1"
      i = "1"

    if operand[-1] == "x":
      x = "1"
      operand = operand[:-3]
    else:
      x = "0"

    b = "0"
    p = "0"
    e = "1"

    if type(operand) == int:
      address = "{0:020b}".format(operand)
    else:
      address = "{0:020b}".format(int("0x" + operand, 0))   

    object_code = opcode + n + i + x + b + p + e + address

    object_code = bin_to_hex(object_code)

    return object_code

#XE Instruction
def based_instruction(mneumonic, operand, base):
    global offset

    opcode = "{0:08b}".format(int(optable[mneumonic], 0))[:6]

    #n i x b p e
    if operand[0] == "@":
      n = "1"
      operand = operand[1:]
    else:
      n = "0"

    if operand[0] == '#':
      i = "1"
      operand = operand[1:]
    else:
      i = "0"

    if (n == "0") and (i == "0"):
      n = "1"
      i = "1"

    if operand[-1] == "x":
      x = "1"
      operand = operand[:-3]
    else:
      x = "0"

    b = "1"
    p = "0"

    e = "0"

    if type(operand) != int:
      operand = int("0x" + operand, 0)

    int_base = int("0x" + base, 0)
    int_address = operand - int_base

    address = "{0:012b}".format(int_address)    

    object_code = opcode + n + i + x + b + p + e + address

    object_code = bin_to_hex(object_code)

    return object_code





def pc_instruction(mneumonic, operand):
    global offset

    opcode = "{0:08b}".format(int(optable[mneumonic], 0))[:6]

    #n i x b p e
    if operand[0] == "@":
      n = "1"
      operand = operand[1:]
    else:
      n = "0"

    if operand[0] == '#':
      i = "1"
      operand = operand[1:]
    else:
      i = "0"

    if (n == "0") and (i == "0"):
      n = "1"
      i = "1"

    if operand[-1] == "x":
      x = "1"
      operand = operand[:-3]
    else:
      x = "0"

    b = "0"
    p = "1"

    e = "0"

    if type(operand) != int:
      operand = int("0x" + operand, 0)

    int_offset = int("0x" + offset, 0)
    int_address = operand - int_offset

    if (int_address < -2048) or (int_address > 2047):
      print("need to use extended")
      exit(1)

    address = "{0:012b}".format(int_address)    

    object_code = opcode + n + i + x + b + p + e + address

    object_code = bin_to_hex(object_code)

    return object_code





def direct_instruction(mneumonic, operand):

    opcode = "{0:08b}".format(int(optable[mneumonic], 0))[:6]

    #n i x b p e
    if operand[0] == "@":
      n = "1"
      operand = operand[1:]
    else:
      n = "0"

    if operand[0] == '#':
      i = "1"
      operand = operand[1:]
    else:
      i = "0"

    if (n == "0") and (i == "0"):
      n = "1"
      i = "1"

    if operand[-1] == "x":
      x = "1"
      operand = operand[:-3]
    else:
      x = "0"

    b = "0"
    p = "0"

    e = "0"

    if type(operand) == int:
      address = "{0:012b}".format(operand)
    else:
      address = "{0:012b}".format(int("0x" + operand, 0))
    

    object_code = opcode + n + i + x + b + p + e + address

    object_code = bin_to_hex(object_code)

    return object_code




def sic_instruction(mneumonic, operand):
    global optable
    global symbol_table

    #print(mneumonic, operand)

    #bin(int(hex)) -> '0b' + binary string
    opcode = "{0:08b}".format(int(optable[mneumonic], 0))

    #if x is set*************************************
    #remove from tail of string, change address
    if operand[-1] == "x":
      indexed = True
      operand = operand[:-3]
    else:
      indexed = False

    if indexed:
      x = "1"
    else:
      x = "0"

    if type(operand) == int:
      address = "{0:015b}".format(operand)
    else:
      address = "{0:015b}".format(int("0x" + operand, 0))

    object_code = opcode + x + address
    #print(object_code)

    object_code = bin_to_hex(object_code)

    return object_code




def format1(mneumonic):
    opcode = "{0:08b}".format(int(optable[mneumonic], 0))
    object_code = bin_to_hex(opcode)

    return object_code



def format2(mneumonic, r1, r2):

    registers = ["a", "x", "l", "b", "s", "t", "f", "", "pc", "sw"]

    opcode = "{0:08b}".format(int(optable[mneumonic], 0))


    #shiftl, shiftr (r2 = r2-1)
    if (mneumonic == "shiftr") or (mneumonic == "shiftl"):
      r1_code = "wow"
      r2_code = "wow"
      for i in range(0, 7):
        if r1 == registers[i]:
          r1_code = '{0:04b}'.format(i)

      if r1_code == "wow": 
        r1 = int(r1)
        if r1 > 16:
          print("Argument too large: %s" % r1)
          exit(1)
        else:
          r1_code = '{0:04b}'.format(r1)

      r2 = int(r2)
      if r2 > 16:
        print("Argument too large: %s" % r2)
        exit(1)
      else:
        r2_code = '{0:04b}'.format(r2 - 1)

    else:
      r1_code = "wow"
      r2_code = "wow"
      for i in range(0, 10):
        if r1 == registers[i]:
          r1_code = '{0:04b}'.format(i)
        if r2 == registers[i]:
          r2_code = '{0:04b}'.format(i)

      if r1_code == "wow": 
        r1 = int(r1)
        if r1 > 15:
          print("Argument too large: %s" % r1)
          exit(1)
        else:
          r1_code = '{0:04b}'.format(r1)


      if r2_code == "wow":
        r2 = int(r2)
        if r2 > 15:
          print("Argument too large: %s" % r2)
          exit(1)
        else:
          r2_code = '{0:04b}'.format(r2)

    object_code = opcode + r1_code + r2_code

    object_code = bin_to_hex(object_code)

    return object_code


def bin_to_hex(string):

  current_hex = ""
  output = ""
  for i in range(0, len(string), 4):
    current_hex += string[i]
    current_hex += string[i + 1]
    current_hex += string[i + 2]
    current_hex += string[i + 3]

    hexdig = hex(int("0b" + current_hex, 0))[2:]
    output += hexdig

    current_hex = ""

  return output


def find_operand(line):
  #finds the operand and if it is a label it returns the hex value
    global symbol_table

    sline = line.split()
    has_label = label_test_2(sline[0])

    if has_label and (sline[0][-1] == ":"):
      operand = sline[2]
      if len(sline) > 3:
        if (sline[3] != "x") or (len(sline) > 4):
          print("too many arguments")
          exit(1)
    else:
      operand = sline[1]
      if len(sline) > 2:
        if (sline[2] != "x") or (len(sline) > 3):
          print("too many arguments")
          exit(1)

    if operand[-1] == ",":
      operand = operand[:-1]
      if operand.upper() in symbol_table:
        operand = symbol_table[operand.upper()] + ", x"
      else:
        operand = hex(int(operand))[2:] + ", x"


    elif operand[0] == "#":
      operand = operand[1:]
      if operand.upper() in symbol_table:
        operand = "#" + symbol_table[operand.upper()]
      else:
        operand = "#" + hex(int(operand))[2:]

    elif operand[0] == "@":
      operand = operand[1:]
      if operand.upper() in symbol_table:
        operand = "@" + symbol_table[operand.upper()]
      else:
        operand = "@" + hex(int(operand))[2:]

    else:
      if operand.upper() in symbol_table:
        operand = symbol_table[operand.upper()]
      else:
        if int(operand) < 0:
          operand = twos_compliment(int(operand))
        else:
          operand = hex(int(operand))[2:]

    return operand


def twos_compliment(number):

  bin_num = '{0:024b}'.format(abs(number))

  twos_comp = "0b"
  for bit in bin_num:
    if bit == "0":
      twos_comp += "1"
    else:
      twos_comp += "0"

  temp_num = int(twos_comp, 0)
  temp_num += 1

  return hex(temp_num)[2:]


def f2_operands(line):
  #finds the operand and if it is a label it returns the hex value
    sline = line.split()
    has_label = label_test_2(sline[0])

    #clear, svc, tixr
    opcode = get_opcode(line)

    if has_label and (sline[0][-1] == ":"):
      if opcode in ["clear", "svc", "tixr"]:
        r1 = sline[2]
        r2 = 0
      else:
        r1 = sline[2][:-1]
        r2 = sline[3]
    else:
      if opcode in ["clear", "svc", "tixr"]:
        r1 = sline[1]
        r2 = 0
      else:
        r1 = sline[1][:-1]
        r2 = sline[2]

    if opcode == "svc":
      r1 = int(r1) 

    return (r1, r2)


def get_opcode(line):

    sline = line.split()

    has_label = label_test_2(sline[0])
    if not has_label:
      opcode = sline[0]

    else:
      if sline[0][-1] == ":":
        opcode = sline[1]
      else:
        opcode = ""
        after_label = False
        for char in sline[0]:
          if after_label:
            opcode += char
          else:
            if char == ":":
              after_label = True


    return opcode


#header

def write_header(line, outfile):
    has_start = False

    header = "H"

    first_line = line.split()

    has_label = label_test_2(line)
    #H NNNNNN AAA LLL
    if "start" in first_line:
      has_start = True
      if has_label:
        starting_address = first_line[2]
      else:
        starting_address = first_line[1]
    #if no start:
    else:
      starting_address = "000000"

    for i in range(0, 6):
        if has_label:
          header += first_line[0][i]
        else:
          header += " "

    #hexed = text_to_hex(header)
    #outfile.write(hexed)

    sized_address = three_bytes(starting_address)

    """
    spaced_address = ""
    for i in range(0, 6):
      spaced_address = spaced_address + sized_address[i]
      if i == 1:
        spaced_address += " "
    spaced_address += " "

    outfile.write(spaced_address)
    """


    #offset is still set to end of first pass
    global offset
    filesize = hex_sub(offset, starting_address)

    sized_filesize = three_bytes(filesize)

    """
    spaced_size = ""
    for i in range(0, 6):
      spaced_size = spaced_size + sized_filesize[i]
      if i == 3:
        spaced_size += " "

    outfile.write(spaced_size)
    """

    object_code = header + sized_address + sized_filesize

    #has_start is determined aboe
    start_test(first_line)

    return (has_start, object_code)


def hex_sub(val1, val2):
    hex_format1 = "0x" + val1
    hex_format2 = "0x" + val2 
    
    ival1 = int(hex_format1, 0)
    ival2 = int(hex_format2, 0)

    result = ival1 - ival2

    hex_result = hex(result)

    return hex_result[2:] 



def text_to_hex(string):

  hex_string = ""

  for i in range(0, len(string)):
    ascii_val = ord(string[i])
    hex_val = ascii_to_hex(ascii_val)
    hex_string += hex_val

    if i % 2 != 0:
      hex_string = hex_string + " "


  return hex_string


def ascii_to_hex(number):

  return hex(number)[2:]


def label_test_2(word):

    is_a_label = re.match(r'^\s*[A-Za-z][A-Za-z0-9]*:', word)
    # r = treat as raw string
    # ^ = start at beginning of string
    # \s = any whitespace character
    global symbol_table
    global offset

    if is_a_label:
      return True

    return False
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

def main():
    #takes filename off command line

    first_pass()
    second_pass()

if __name__ == "__main__":
  main()
