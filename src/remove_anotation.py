import os
import re

def remove_annotations(file_path):
    # read the file
    with open(file_path, 'r') as f:
        data = f.read()

    data = re.sub(r"//.*?$", "", data, flags=re.MULTILINE)  # remove single-line comments
    data = re.sub(r"/\*.*?\*/", "", data, flags=re.DOTALL)  # remove multi-line comments
    data = re.sub(r"\n\s*\n", "\n", data)  # remove empty lines
    data = data.strip()  # remove leading/trailing whitespace

    return data

if __name__ == '__main__':

    for filename in os.listdir("../data/CVE"):
        if not filename.endswith(".sol"):
            continue
        filepath = os.path.join("../data/CVE", filename)
        content = remove_annotations(filepath)
        new_filepath = os.path.join("../data/CVE_clean", filename)

        with open(new_filepath, 'w') as f:
            f.write(content)
