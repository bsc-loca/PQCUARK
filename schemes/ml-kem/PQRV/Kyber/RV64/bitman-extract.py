import re
import sys

# Definir los conjuntos de instrucciones para cada extensión
ZBA_INSTRUCTIONS = ['add.uw', 'sh1add', 'sh1add.uw', 'sh2add', 'sh2add.uw', 'sh3add', 'sh3add.uw', 'slli.uw']
ZBB_INSTRUCTIONS = ['andn', 'orn', 'xnor', 'clz', 'clzw', 'ctz', 'ctzw', 'cpop', 'cpopw', 'max', 'maxu', 'min', 'minu', 
                    'sext.b', 'sext.h', 'zext.h', 'sext.w', 'zext.w', 'rol', 'rolw', 'ror', 'rori', 'rorw', 'roriw']
ZBC_INSTRUCTIONS = ['clmul', 'clmulh', 'clmulr']
ZBS_INSTRUCTIONS = ['bclr', 'bclri', 'bext', 'bexti', 'binv', 'binvi', 'bset', 'bseti']

# Función para clasificar instrucciones por extensión
def classify_instruction(instruction):
    if instruction in ZBA_INSTRUCTIONS:
        return "Zba"
    elif instruction in ZBB_INSTRUCTIONS:
        return "Zbb"
    elif instruction in ZBC_INSTRUCTIONS:
        return "Zbc"
    elif instruction in ZBS_INSTRUCTIONS:
        return "Zbs"
    else:
        return None

# Función para leer un archivo objdump y extraer las instrucciones
def extract_bitmanip_instructions_from_file(file_path):
    # Expresión regular para capturar direcciones e instrucciones
    instruction_pattern = re.compile(r'([0-9a-f]+):\s+([0-9a-f]+)\s+(\w+\.\w+|\w+)')

    # Almacenar las instrucciones clasificadas
    instructions = {
        "Zba": [],
        "Zbb": [],
        "Zbc": [],
        "Zbs": []
    }

    # Leer el archivo línea por línea
    with open(file_path, 'r') as file:
        for line in file:
            # Buscar coincidencias de dirección, opcode e instrucción
            match = instruction_pattern.search(line)
            if match:
                address = match.group(1)
                opcode = match.group(2)
                instruction = match.group(3)
                
                # Clasificar la instrucción
                classification = classify_instruction(instruction)
                if classification:
                    instructions[classification].append(f"{address}:\t{opcode}\t{instruction}")
    
    return instructions

# Comprobar si se ha proporcionado el nombre del archivo
if len(sys.argv) != 2:
    print("Uso: python script.py <ruta_al_fichero_objdump>")
    sys.exit(1)

# Obtener la ruta del archivo desde el argumento
file_path = sys.argv[1]

# Extraer y clasificar instrucciones
result = extract_bitmanip_instructions_from_file(file_path)

# Mostrar resultados en el formato solicitado
for extension, instrs in result.items():
    if instrs:
        print(f"Instrucciones {extension} encontradas:")
        for instr in instrs:
            print(instr)
        print()
