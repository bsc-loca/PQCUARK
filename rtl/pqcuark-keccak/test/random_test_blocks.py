import secrets
import random
import math

def generate_hex_word(bit_length):
    # Calculate the number of hex characters needed (4 bits per character)
    hex_chars = math.ceil(bit_length / 4)
    return secrets.token_hex(hex_chars).upper()

def create_keccak_test_file(filename, bit_length=512, num_blocks=1200, max_words_per_block=10):
    with open(filename, 'w') as f:
        f.write(f"{num_blocks}\n")  # Total blocks

        for block in range(num_blocks):
            words_in_block = random.randint(1, max_words_per_block)

            for _ in range(words_in_block):
                f.write(generate_hex_word(bit_length) + "\n")

            if block < num_blocks - 1:
                f.write("-\n")
            else:
                f.write(".\n")

# Example usage: 256-bit lines, 1200 blocks, up to 10 words per block
create_keccak_test_file("keccak_in_custom.txt", bit_length=64, num_blocks=1200, max_words_per_block=5)

print("Done! Generated test blocks with custom bit-length words.")
