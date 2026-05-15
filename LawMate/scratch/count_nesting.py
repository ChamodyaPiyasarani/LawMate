
import sys

def count_nesting(filename, limit_line):
    nesting = 0
    with open(filename, 'r') as f:
        for i, line in enumerate(f, 1):
            if i > limit_line:
                break
            # Remove strings and comments to avoid false matches
            # (Simplified for this task)
            line = line.split('//')[0]
            for char in line:
                if char == '{':
                    nesting += 1
                elif char == '}':
                    nesting -= 1
            print(f"{i}: {nesting} | {line.strip()}")

if __name__ == "__main__":
    count_nesting(sys.argv[1], int(sys.argv[2]))
