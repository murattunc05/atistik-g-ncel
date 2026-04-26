import requests
import re

url = "https://www.tjk.org/TR/YarisSever/Info/Sehir/GunlukYarisProgrami?SehirId=1&QueryParameter_Tarih=22/11/2025&SehirAdi=Adana&Era=today"
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "X-Requested-With": "XMLHttpRequest"
}

try:
    response = requests.get(url, headers=headers)
    content = response.text
    
    print(f"Status Code: {response.status_code}")
    
    # Find occurrences of "İkramiye" or "Ikramiye"
    matches = [m for m in re.finditer(r'(İkramiye|Ikramiye)', content, re.IGNORECASE)]
    
    if not matches:
        print("No 'Ikramiye' found.")
    else:
        print(f"Found {len(matches)} 'Ikramiye' matches.")
        for i, m in enumerate(matches[:5]): # Print first 5
            start = m.start()
            end = min(len(content), m.end() + 500) # Print 500 chars after
            print(f"Match {i}: {m.group(0)}")
            print(f"Context: {content[start:end]}")
            print("-" * 50)

except Exception as e:
    print(f"Error: {e}")
