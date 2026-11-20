import urllib.request
import re
import json

opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor())
urllib.request.install_opener(opener)

headers = {"User-Agent": "Mozilla/5.0"}

# Step 1: get main page to acquire cookies and csrf token
req = urllib.request.Request("https://reodesuxz.itch.io/low-poly-sci-fi-lab-robots-pack", headers=headers)
html = opener.open(req).read().decode()
token = re.search(r'name="csrf_token"\s+value="([^"]+)"', html).group(1)
print("CSRF Token:", token)

# Step 2: request download link
post_data = ("csrf_token=" + urllib.parse.quote(token)).encode()
req2 = urllib.request.Request("https://reodesuxz.itch.io/upload/19718123/download", data=post_data, headers=headers)
res = opener.open(req2).read().decode()
print("Download response:", res)

data = json.loads(res)
dl_url = data["url"]

# Step 3: download file
print("Downloading file from:", dl_url)
req3 = urllib.request.Request(dl_url, headers=headers)
file_bytes = opener.open(req3).read()
with open("references/candidates/scifi_lab_pack.zip", "wb") as f:
    f.write(file_bytes)
print(f"Saved {len(file_bytes)} bytes to references/candidates/scifi_lab_pack.zip")
