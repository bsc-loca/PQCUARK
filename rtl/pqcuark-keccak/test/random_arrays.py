import random

# Generate the list of arrays
num_tests = 2000
array_list = []
round_constant = []
for i in range(num_tests):  # Generate 100 arrays
    array = [[random.getrandbits(64) for _ in range(5)] for _ in range(5)]  # 5x5 array of 64-bit random integers
    array_list.append(array)
    round_constant.append(random.getrandbits(64))
print(len(round_constant))


# Write the list of arrays to a file
try:
    with open("arrays.txt", "w") as f:  # Use 'with' for automatic file handling
        f.write(str(array_list))  # Write the string representation of the list
    print("File 'arrays.txt' created successfully!")
    with open("round_constants.txt", "w") as f:  # Use 'with' for automatic file handling
        f.write(str(round_constant))  # Write the string representation of the list
except Exception as e:
    print(f"An error occurred while writing to the file: {e}")