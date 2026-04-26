import requests
from bs4 import BeautifulSoup

# TJK Günlük Program - At bilgilerini kontrol et
url = 'https://www.tjk.org/TR/YarisSever/Info/Sehir/GunlukYarisProgrami'
params = {
    'SehirId': '1',  # İstanbul
    'QueryParameter_Tarih': '05/12/2025',
    'Era': 'today'
}
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'X-Requested-With': 'XMLHttpRequest',
    'Referer': 'https://www.tjk.org/'
}

try:
    response = requests.get(url, params=params, headers=headers, timeout=15)
    print(f"Status: {response.status_code}")
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # At tablosu bul
    tables = soup.find_all('table')
    print(f"\nToplam {len(tables)} tablo bulundu")
    
    for i, table in enumerate(tables[:2]):  # İlk 2 tablo
        print(f"\n=== TABLO {i+1} ===")
        
        # Başlıkları bul
        headers_row = table.find('tr')
        if headers_row:
            ths = headers_row.find_all(['th', 'td'])
            for j, th in enumerate(ths[:15]):
                class_name = th.get('class', [''])[0] if th.get('class') else ''
                text = th.text.strip()[:30]
                print(f"  {j}: [{class_name}] {text}")
        
        # İlk veri satırı
        rows = table.find_all('tr')
        if len(rows) > 1:
            first_data = rows[1]
            cells = first_data.find_all('td')
            print(f"\n  Veri satırı ({len(cells)} hücre):")
            for j, cell in enumerate(cells[:15]):
                class_name = cell.get('class', [''])[0] if cell.get('class') else ''
                text = cell.text.strip()[:40].replace('\n', ' ')
                print(f"    {j}: [{class_name}] {text}")

except Exception as e:
    print(f"Hata: {e}")
    import traceback
    traceback.print_exc()
