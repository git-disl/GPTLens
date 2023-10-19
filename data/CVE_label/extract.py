import re
import json

with open("raw_data.txt", "r") as f:
    data = f.read()

pattern = r'cvename\.cgi\?name=(CVE-\d{4}-\d+).*?<td valign="top">(.*?)\n\n</td>'
# match = re.search(pattern, data, re.DOTALL)
matches = re.findall(pattern, data, re.DOTALL)

CVE2description = {}

for match in matches:

    cve_id, description = match
    print("CVE ID:", cve_id)
    print("Description:", description.strip())
    print("-----------------------")
    CVE2description.update({cve_id: description.strip()})

print("pause")

with open("./CVE2description.json", "w") as f:
    json.dump(CVE2description, f, indent=4)


