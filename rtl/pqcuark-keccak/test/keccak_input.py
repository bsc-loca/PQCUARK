with open("../test/test_vectors/keccak_in_custom.txt", "r") as f, open("../test/test_vectors/keccak_in_vector.txt", 'w') as file2:
    input_message = ''
    j = 0
    
    for line in f:
        line_strip = line.strip()
        #print(line_strip)
        #print(j)
        if line_strip == "-":
            # Write the final input message to the output file
            j+=1
            #print(f"Input message = {input_message}\n")
            file2.write(input_message + "\n")
            input_message = ''  # Reset the input message
        elif line_strip != "1200" and line_strip != ".":
            # Process the line in pairs and reverse each pair
            new_line = ''
            for i in range(0, len(line_strip), 2):
                # Extract a pair of characters
                pair = line_strip[i:i+2]
                # Reverse the pair and add it to new_line
                new_line += pair[::-1]
            if (j == 923):
                print(new_line)
            # Add the processed line to the input message
            input_message += new_line[::-1]