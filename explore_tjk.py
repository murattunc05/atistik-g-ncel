import requests
from bs4 import BeautifulSoup
import re

# 1. Önce bugünün programından bir at linki bulalım
program_url = 'https://www.tjk.org/TR/YarisSever/Info/Page/GunlukYarisProgrami'
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
}

try:
    # Günlük programı çek
    response = requests.get(program_url, headers=headers, timeout=15)
    print(f"Program Status: {response.status_code}")
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # At detay linklerini bul (AtKosuBil ile başlayan)
    links = soup.find_all('a', href=re.compile(r'AtKosuBil'))
    print(f"Bulunan at linkleri: {len(links)}")
    
    if links:
        # İlk linki al
        first_link = links[0]
        href = first_link.get('href', '')
        horse_name = first_link.text.strip()
        
        print(f"\nİlk at: {horse_name}")
        print(f"Link: {href}")
        
        # Tam URL oluştur
        if href.startswith('/'):
            detail_url = f"https://www.tjk.org{href}"
        else:
            detail_url = href
        
        print(f"\nDetay URL: {detail_url}")
        
        # Detay sayfasını çek
        detail_response = requests.get(detail_url, headers=headers, timeout=15)
        print(f"Detay Status: {detail_response.status_code}")
        
        if detail_response.status_code == 200:
            detail_soup = BeautifulSoup(detail_response.text, 'html.parser')
            
            # Yarış geçmişi tablosunu bul
            table = detail_soup.find('table', {'id': 'excelTable'})
            if not table:
                table = detail_soup.find('table', class_=re.compile(r'table'))
            
            if table:
                print("\n=== YARIŞ GEÇMİŞİ TABLOSU BULUNDU ===")
                
                # Başlıklar
                thead = table.find('thead')
                if thead:
                    ths = thead.find_all('th')
                    print("\nSütunlar:")
                    for i, th in enumerate(ths):
                        print(f"  {i}: {th.text.strip()}")
                
                # Veriler
                tbody = table.find('tbody')
                if tbody:
                    rows = tbody.find_all('tr')
                    print(f"\nToplam {len(rows)} yarış kaydı")
                    
                    for row_idx, row in enumerate(rows[:3]):
                        cells = row.find_all('td')
                        print(f"\n--- Yarış {row_idx + 1} ---")
                        for i, cell in enumerate(cells):
                            text = cell.text.strip().replace('\n', ' ')[:40]
                            if text:
                                print(f"  {i}: {text}")
            else:
                print("\nTablo bulunamadı. Sayfa yapısını inceleyelim...")
                tables = detail_soup.find_all('table')
                print(f"Toplam {len(tables)} tablo var")
                
                # İlk 3000 karakter
                text = detail_soup.get_text()
                print(f"\nSayfa metni (ilk 3000):\n{text[:3000]}")
    else:
        print("Hiç at linki bulunamadı!")
        print("\nSayfadaki tüm linkler:")
        all_links = soup.find_all('a')[:20]
        for link in all_links:
            print(f"  {link.get('href', '')[:50]} -> {link.text.strip()[:30]}")

except Exception as e:
    print(f"Hata: {e}")
    import traceback
    traceback.print_exc()
