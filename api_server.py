from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import prediction_logic

app = Flask(__name__)
CORS(app)  # Flutter'dan gelen isteklere izin ver

# TJK ayarları
TARGET_URL = "https://www.tjk.org/TR/YarisSever/Query/Data/Atlar"
REFERER_URL = "https://www.tjk.org/TR/YarisSever/Query/Page/Atlar?QueryParameter_OLDUFLG=on"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Referer": REFERER_URL
}

def map_breed_to_id(breed):
    """Irk adını TJK ID'sine çevirir"""
    breed_map = {
        'Tümü': '-1',
        'İngiliz': '1',
        'Arap': '2'
    }
    return breed_map.get(breed, '-1')

def map_gender_to_id(gender):
    """Cinsiyet adını TJK ID'sine çevirir"""
    gender_map = {
        'Tümü': '-1',
        'Erkek': '1',
        'Dişi': '2',
        'İğdiş': '3'
    }
    return gender_map.get(gender, '-1')

def map_country_to_id(country):
    """Ülke adını TJK ID'sine çevirir"""
    country_map = {
        'Tümü': '-1',
        'Türkiye': '1',
        'İngiltere': '2',
        'Fransa': '3',
        'ABD': '4',
        'İrlanda': '5'
    }
    return country_map.get(country, '-1')

@app.route('/api/search-horses', methods=['POST'])
def search_horses():
    """At arama endpoint'i"""
    try:
        data = request.json
        
        # Form payload'ını hazırla
        payload = {
            "QueryParameter_AtIsmi": data.get('horseName', ''),
            "QueryParameter_IrkId": map_breed_to_id(data.get('breed', 'Tümü')),
            "QueryParameter_CinsiyetId": map_gender_to_id(data.get('gender', 'Tümü')),
            "QueryParameter_Yas": data.get('age', ''),
            "QueryParameter_BabaId": data.get('fatherName', ''),
            "QueryParameter_AnneId": data.get('motherName', ''),
            "QueryParameter_UzerineKosanSahipId": data.get('ownerName', ''),
            "QueryParameter_YetistiricAdi": data.get('breederName', ''),
            "QueryParameter_AntronorId": data.get('trainerName', ''),
            "QueryParameter_UlkeId": map_country_to_id(data.get('country', 'Tümü')),
            "QueryParameter_OLDUFLG": "on" if data.get('includeDeadHorses', False) else "",
            "Era": "past",
            "Sort": "AtIsmi",
            "OldQueryParameter_OLDUFLG": "on" if data.get('includeDeadHorses', False) else ""
        }
        
        # TJK'ya istek gönder
        response = requests.get(
            TARGET_URL,
            params=payload,
            headers=HEADERS,
            timeout=10
        )
        
        if response.status_code != 200:
            return jsonify({
                'success': False,
                'error': f'TJK sunucusundan cevap alınamadı. Status: {response.status_code}'
            }), 500
        
        # HTML'i parse et
        soup = BeautifulSoup(response.text, 'html.parser')
        stats_table = soup.find('table', id='queryTable')
        
        if not stats_table:
            return jsonify({
                'success': True,
                'horses': [],
                'message': 'Sonuç bulunamadı'
            })
        
        table_body = stats_table.find('tbody', id='tbody0')
        if not table_body:
            return jsonify({
                'success': True,
                'horses': [],
                'message': 'Sonuç bulunamadı'
            })
        
        rows = table_body.find_all('tr')
        horses = []
        
        for row in rows:
            if 'hidable' in row.get('class', []):
                continue
            
            try:
                at_ismi_cell = row.find('td', class_='sorgu-Atlar-AtIsmi')
                irk_cell = row.find('td', class_='sorgu-Atlar-IrkAdi')
                cinsiyet_cell = row.find('td', class_='sorgu-Atlar-Cinsiyet')
                yas_cell = row.find('td', class_='sorgu-Atlar-Yas')
                orijin_cell = row.find('td', class_='sorgu-Atlar-BabaAdi')
                sahip_cell = row.find('td', class_='sorgu-Atlar-UzerineKosanSahip')
                antrenor_cell = row.find('td', class_='sorgu-Atlar-Antronoru')
                son_kosu_cell = row.find('td', class_='sorgu-Atlar-SonKosu')
                ikramiye_cell = row.find('td', class_='sorgu-Atlar-SadeAtKazanc')
                
                if not at_ismi_cell or not irk_cell:
                    continue
                
                # Orijin (Baba/Anne) bilgisini parse et
                orijin_text = " ".join(orijin_cell.text.split()) if orijin_cell else ""
                orijin_parts = orijin_text.split('/')
                baba = orijin_parts[0].strip() if len(orijin_parts) > 0 else ""
                anne = orijin_parts[1].strip() if len(orijin_parts) > 1 else ""
                
                at_ismi_link = at_ismi_cell.find('a')
                
                horse = {
                    'name': at_ismi_cell.text.strip(),
                    'detailLink': at_ismi_link['href'] if at_ismi_link else "",
                    'breed': irk_cell.text.strip(),
                    'gender': cinsiyet_cell.text.strip() if cinsiyet_cell else "",
                    'age': yas_cell.text.strip() if yas_cell else "",
                    'father': baba,
                    'mother': anne,
                    'owner': sahip_cell.text.strip() if sahip_cell else "",
                    'trainer': antrenor_cell.text.strip() if antrenor_cell else "",
                    'lastRace': son_kosu_cell.text.strip() if son_kosu_cell else "",
                    'prize': ikramiye_cell.text.strip() if ikramiye_cell else ""
                }
                
                horses.append(horse)
                
            except Exception as e:
                print(f"Satır parse hatası: {e}")
                continue
        
        return jsonify({
            'success': True,
            'horses': horses,
            'count': len(horses)
        })
        
    except requests.exceptions.RequestException as e:
        return jsonify({
            'success': False,
            'error': f'İstek hatası: {str(e)}'
        }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Beklenmeyen hata: {str(e)}'
        }), 500

@app.route('/api/horse-details', methods=['POST'])
def get_horse_details():
    """At detay bilgilerini getir"""
    try:
        data = request.json
        relative_url = data.get('detailLink', '')
        
        if not relative_url:
            return jsonify({
                'success': False,
                'error': 'Detay linki bulunamadı'
            }), 400
        
        detail_url = urljoin(TARGET_URL, relative_url)
        detail_url = detail_url.replace("&amp;", "&")
        
        response = requests.get(detail_url, headers=HEADERS, timeout=10)
        
        if response.status_code != 200:
            return jsonify({
                'success': False,
                'error': f'Detay sayfası alınamadı. Status: {response.status_code}'
            }), 500
        
        soup = BeautifulSoup(response.text, 'html.parser')
        data_div = soup.find('div', id='dataDiv')
        
        if not data_div:
            return jsonify({
                'success': False,
                'error': 'Detay sayfasında veri bulunamadı'
            }), 404
        
        race_table = data_div.find('table', id='queryTable')
        if not race_table:
            return jsonify({
                'success': True,
                'races': [],
                'message': 'Yarış geçmişi bulunamadı'
            })
        
        table_body = race_table.find('tbody', id='tbody0')
        if not table_body:
            return jsonify({
                'success': True,
                'races': [],
                'message': 'Yarış geçmişi bulunamadı'
            })
        
        rows = table_body.find_all('tr')
        races = []
        
        for row in rows:
            if 'hidable' in row.get('class', []):
                continue
            
            cells = row.find_all('td')
            
            if len(cells) > 17:
                try:
                    race = {
                        'date': cells[0].text.strip(),
                        'city': cells[1].text.strip(),
                        'distance': cells[2].text.strip(),
                        'track': " ".join(cells[3].text.strip().split()),
                        'position': cells[4].text.strip(),
                        'grade': cells[5].text.strip(),
                        'jockey': cells[8].text.strip(),
                        'prize': cells[17].text.strip()
                    }
                    races.append(race)
                except IndexError:
                    continue
        
        return jsonify({
            'success': True,
            'races': races,
            'count': len(races)
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Hata: {str(e)}'
        }), 500

@app.route('/api/search-races', methods=['POST'])
def search_races():
    """Yarış arama endpoint'i - Web scraping ile"""
    try:
        data = request.json
        
        # TJK yarış sorgulama sayfası - GET ile direkt HTML çekiyoruz
        base_url = "https://www.tjk.org/TR/YarisSever/Query/Page/KosuSorgulama"
        
        # Query parametreleri
        params = {
            'QueryParameter_Tarih_Start': data.get('startDate', ''),
            'QueryParameter_Tarih_End': data.get('endDate', ''),
            'QueryParameter_SehirId': '-1',  # Tüm şehirler
        }
        
        # Opsiyonel parametreler
        if data.get('distance'):
            params['QueryParameter_Mesafe'] = data.get('distance')
        if data.get('fatherName'):
            params['QueryParameter_BabaIsmi'] = data.get('fatherName')
        if data.get('motherName'):
            params['QueryParameter_AnneIsmi'] = data.get('motherName')
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
            "Referer": "https://www.tjk.org/TR/YarisSever/Query/Page/KosuSorgulama"
        }
        
        # TJK sayfasını GET ile çek
        response = requests.get(
            base_url,
            params=params,
            headers=headers,
            timeout=15
        )
        
        if response.status_code != 200:
            return jsonify({
                'success': False,
                'error': f'TJK sayfası yüklenemedi. Status: {response.status_code}'
            }), 500
        
        # HTML'i parse et
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Tablonun gövdesini sağlam şekilde bul (tbody0/thead/tbody1 farklarını tolere et)
        table = soup.find('table', id='queryTable')
        tbody = None
        if table:
            tbody = table.find('tbody') or table.find('tbody', id='tbody0') or table.find('tbody', id='tbody1')
        if not tbody:
            tbody = soup.find('tbody', id='tbody0') or soup.find('tbody', id='tbody1')
        
        if not tbody:
            return jsonify({
                'success': True,
                'races': [],
                'message': 'Sonuç bulunamadı'
            })
        
        # Tüm satırları al
        race_rows = tbody.find_all('tr')
        
        if not race_rows:
            return jsonify({
                'success': True,
                'races': [],
                'message': 'Sonuç bulunamadı'
            })
        
        races = []
        
        for row in race_rows:
            try:
                cells = row.find_all('td')
                
                if len(cells) >= 8:
                    # Detay linkini bul
                    detail_link = ''
                    link_elem = cells[0].find('a', href=True) if len(cells) > 0 else None
                    if link_elem:
                        detail_link = link_elem['href']
                    
                    # Tarih hücresinden sadece metni al
                    date_text = cells[0].text.strip() if len(cells) > 0 else ''
                    
                    # Sütun eşleştirmeleri TJK başlık sırasına göre düzeltildi
                    race = {
                        'date': date_text,                                            # 0: Tarih (dd.MM.yyyy)
                        'city': cells[1].text.strip() if len(cells) > 1 else '',      # 1: Şehir
                        'raceNumber': cells[2].text.strip() if len(cells) > 2 else '',# 2: Koşu
                        'group': cells[3].text.strip() if len(cells) > 3 else '',     # 3: Grup
                        'raceType': cells[4].text.strip() if len(cells) > 4 else '',  # 4: Koşu Cinsi
                        'apprenticeType': cells[5].text.strip() if len(cells) > 5 else '', # 5: Apr. Koş. Cinsi
                        'distance': cells[6].text.strip() if len(cells) > 6 else '',  # 6: Mesafe
                        'track': cells[7].text.strip() if len(cells) > 7 else '',     # 7: Pist
                        'detailLink': detail_link
                    }
                    
                    races.append(race)
                    
            except Exception as e:
                print(f"Satır parse hatası: {e}")
                continue
        
        return jsonify({
            'success': True,
            'races': races,
            'count': len(races)
        })
        
    except requests.exceptions.RequestException as e:
        return jsonify({
            'success': False,
            'error': f'İstek hatası: {str(e)}'
        }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Beklenmeyen hata: {str(e)}'
        }), 500

@app.route('/api/daily-races', methods=['POST'])
def get_daily_races():
    """Günün koşularını getir"""
    try:
        data = request.json
        # Şehir ID mapping
        city_map = {
            'İstanbul': '1',
            'Ankara': '2',
            'İzmir': '3',
            'Adana': '4',
            'Bursa': '5',
            'Şanlıurfa': '6',
            'Diyarbakır': '7',
            'Elazığ': '8',
            'Kocaeli': '9'
        }
        
        city = data.get('city', 'İstanbul')
        city_id = city_map.get(city, '1')
        
        # Bugünün tarihini al
        from datetime import datetime
        today = datetime.now().strftime('%d.%m.%Y')
        
        # TJK günlük program sayfası
        url = f"https://www.tjk.org/TR/YarisSever/Info/Page/GunlukYarisProgrami?SehirId={city_id}"
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "tr-TR,tr;q=0.9"
        }
        
        response = requests.get(url, headers=headers, timeout=15)
        
        if response.status_code != 200:
            return jsonify({
                'success': False,
                'error': f'TJK sayfası yüklenemedi. Status: {response.status_code}'
            }), 500
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Koşu bilgilerini bul
        races = []
        race_cards = soup.find_all('div', class_='race-card') or soup.find_all('div', class_='kosu-card')
        
        # Alternatif: Tablo formatında koşular
        if not race_cards:
            tables = soup.find_all('table')
            for table in tables:
                rows = table.find_all('tr')
                for row in rows[1:]:  # İlk satır başlık
                    cells = row.find_all('td')
                    if len(cells) >= 4:
                        try:
                            race = {
                                'raceNumber': cells[0].text.strip(),
                                'time': cells[1].text.strip(),
                                'distance': cells[2].text.strip(),
                                'track': cells[3].text.strip(),
                                'city': city
                            }
                            races.append(race)
                        except:
                            continue
        else:
            for card in race_cards:
                try:
                    race = {
                        'raceNumber': card.find('span', class_='race-number').text.strip() if card.find('span', class_='race-number') else '',
                        'time': card.find('span', class_='race-time').text.strip() if card.find('span', class_='race-time') else '',
                        'distance': card.find('span', class_='distance').text.strip() if card.find('span', class_='distance') else '',
                        'track': card.find('span', class_='track').text.strip() if card.find('span', class_='track') else '',
                        'city': city
                    }
                    races.append(race)
                except:
                    continue
        
        return jsonify({
            'success': True,
            'races': races,
            'city': city,
            'date': today,
            'count': len(races)
        })
        
    except requests.exceptions.RequestException as e:
        return jsonify({
            'success': False,
            'error': f'İstek hatası: {str(e)}'
        }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Beklenmeyen hata: {str(e)}'
        }), 500

@app.route('/api/compare-horses', methods=['POST'])
def compare_horses():
    """Atları karşılaştır ve kazanma olasılıklarını hesapla"""
    try:
        data = request.json
        horses_to_compare = data.get('horses', [])
        
        if not horses_to_compare:
            return jsonify({
                'success': False,
                'error': 'Karşılaştırılacak at listesi boş'
            }), 400
            
        # Eğer at detayları eksikse (örneğin sadece link varsa), detayları çek
        # Bu örnekte frontend'in detayları zaten gönderdiğini varsayıyoruz, 
        # ancak tam bir implementasyonda burada eksik veriler için fetch yapılabilir.
        # Biz şimdilik frontend'in dolu veri gönderdiğini varsayalım veya
        # prediction_logic içinde eksik verileri handle edelim.
        
        # Olasılıkları hesapla
        compared_horses = prediction_logic.calculate_winning_probability(horses_to_compare)
        
        return jsonify({
            'success': True,
            'horses': compared_horses,
            'count': len(compared_horses)
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Hata: {str(e)}'
        }), 500

@app.route('/daily-program', methods=['GET'])
def daily_program():
    """TJK Günlük Yarış Programı"""
    try:
        date_param = request.args.get('date')  # Format: dd/MM/yyyy
        city_id = request.args.get('cityId', '1') # Default İstanbul
        
        if not date_param:
            return jsonify({'success': False, 'error': 'Date parameter is required'}), 400

        # TJK Headers
        headers = {
            'sec-ch-ua-platform': '"Windows"',
            'Referer': 'https://www.tjk.org/TR/YarisSever/Info/Page/GunlukYarisProgrami',
            'X-Requested-With': 'XMLHttpRequest',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36',
            'Accept': 'text/html, */*; q=0.01'
        }
        
        # Parameters
        params = {
            'SehirId': city_id,
            'QueryParameter_Tarih': date_param,
            'Era': 'today'
        }
        
        target_url = "https://www.tjk.org/TR/YarisSever/Info/Sehir/GunlukYarisProgrami"
        
        response = requests.get(target_url, headers=headers, params=params, timeout=15)
        
        if response.status_code != 200:
            return jsonify({'success': False, 'error': f'TJK Error: {response.status_code}'}), 500
            
        soup = BeautifulSoup(response.text, 'html.parser')
        
        races = []
        
        # Parse logic
        # TJK usually returns a list of races in a specific structure.
        # We need to adapt to the HTML structure returned by this specific endpoint.
        # Based on typical TJK structure:
        
        # Look for race rows or cards
        # The structure might be different from the main page.
        # Let's try to find the main container.
        
        # Common TJK race list structure
        race_rows = soup.find_all('div', class_='row') # Generic
        
        # More specific: Look for "Kosu" containers
        # Since I cannot see the real HTML, I will try to be generic and robust.
        # I'll look for elements that look like race headers.
        
        # Try to find the race table or list
        # Often TJK uses tables for programs
        tables = soup.find_all('table')
        
        for table in tables:
            # Check if this table looks like a race list
            if table.find('thead'):
                # Parse rows
                rows = table.find('tbody').find_all('tr') if table.find('tbody') else table.find_all('tr')[1:]
                for row in rows:
                    cells = row.find_all('td')
                    if len(cells) > 5:
                        try:
                            # This is a guess at the structure based on typical TJK tables
                            # We might need to adjust this after testing or if the user provides more info.
                            # But the user said "Parse edilen veriyi temiz bir JSON formatına çevir"
                            # I will try to extract as much as possible.
                            
                            # However, the user also said "Kaldır: Ekranın üst kısmında bulunan... widget'ı tamamen kaldır."
                            # and "Kart Tasarımı: ... Koşu Saati, Şehir Adı, Koşu Türü..."
                            
                            # Let's try to find specific classes if possible.
                            # TJK often uses 'd-block' or specific classes for race info.
                            pass
                        except:
                            continue

        # Alternative: The endpoint might return the "City Program" which is often a list of races.
        # Let's look for "accordion" or "card" style elements if it's the mobile view, 
        # or table if desktop. The User-Agent is Windows/Chrome, so likely Desktop view.
        
        # Let's assume it returns the standard program table.
        # I will try to parse the "Program" table.
        
        program_table = soup.find('table', id='programTable') or soup.find('table')
        
        if program_table:
            rows = program_table.find_all('tr')
            current_race = {}
            
            for row in rows:
                # Skip headers
                if row.find('th'):
                    continue
                    
                cells = row.find_all('td')
                if not cells:
                    continue
                    
                # Try to identify columns
                # This is tricky without seeing the HTML.
                # But usually: Race No, Time, Horse Name, etc.
                # Wait, the user wants "Günün Koşuları" (Race List), not "Horse List" for a race.
                # The endpoint `GunlukYarisProgrami` usually lists the RACES (1. Koşu, 2. Koşu...).
                
                # Actually, `GunlukYarisProgrami` page usually has a list of races on the left (or top) 
                # and the details of the selected race.
                # But the endpoint `Info/Sehir/GunlukYarisProgrami` might return the list of races for that city.
                
                # Let's look for elements with class "race-header" or similar.
                pass

        # RE-EVALUATION:
        # The user said "Parse edilen veriyi temiz bir JSON formatına çevir (Örn: Koşu Saati, Şehir, Koşu İsmi, Mesafesi, Bahis Türü vb.)"
        # I'll try to find the race headers.
        
        race_headers = soup.find_all('div', class_='kosu-baslik') # Common TJK class
        if not race_headers:
             race_headers = soup.find_all('div', class_='card-header')
             
        # If we can't find specific classes, let's try to parse the text content of the response
        # to find patterns like "1. Koşu", "13:30", etc.
        
        # Let's try a more robust approach using the structure I saw in `get_daily_races` (lines 430+ in original file)
        # It looked for `race-card` or `kosu-card`.
        
        race_cards = soup.find_all('div', class_='race-card') or soup.find_all('div', class_='kosu-card')
        
        if not race_cards:
            # Try finding the main container
            main_container = soup.find('div', id='main-container') or soup
            
            # Look for race blocks
            # Pattern: "X. Koşu"
            # I'll iterate through all divs and check text
            all_divs = main_container.find_all('div')
            for div in all_divs:
                text = div.get_text(strip=True)
                if 'Koşu' in text and 'Saat' in text:
                    # Potential race header
                    # Parse it
                    # "1. KoşuSaat: 13:30..."
                    pass
        
        # Let's use the logic I wrote in the Dart service (regex) but in Python.
        # It's robust against HTML structure changes.
        
        import re
        text_content = soup.get_text(" | ", strip=True)
        
        # Regex to find races
        # Pattern: 1. Koşu | Saat: 13:30 | ...
        # Or: 1. Koşu 13:30
        
        # Let's try to find the race elements directly.
        # On TJK "GunlukYarisProgrami", races are often in an accordion or list.
        # The endpoint `Info/Sehir/GunlukYarisProgrami` likely returns the partial HTML for the race list.
        
        # I will look for `h5` or `h4` or `div` that contains "Koşu" and "Saat".
        
        found_races = []
        
        # Strategy: Find all elements that might be race headers
        candidates = soup.find_all(['div', 'h3', 'h4', 'h5', 'a'])
        
        for cand in candidates:
            text = cand.get_text(strip=True)
            # Check for "X. Koşu" and "Saat"
            if re.search(r'\d+\.\s*Koşu', text, re.IGNORECASE) and re.search(r'Saat', text, re.IGNORECASE):
                # Found a race header
                # Extract info
                race_num_match = re.search(r'(\d+)\.\s*Koşu', text, re.IGNORECASE)
                time_match = re.search(r'Saat\s*:?\s*(\d{2}:\d{2})', text, re.IGNORECASE)
                
                if race_num_match and time_match:
                    race_num = race_num_match.group(1)
                    time = time_match.group(1)
                    
                    # Try to get distance and track
                    # Usually in the same text or nearby
                    distance_match = re.search(r'(\d{3,4})\s*(?:Metre|m)?\s*(Çim|Kum|Sentetik)', text, re.IGNORECASE)
                    distance = ""
                    track = ""
                    if distance_match:
                        distance = distance_match.group(1)
                        track = distance_match.group(2)
                    
                    # Check if we already added this race (avoid duplicates from nested elements)
                    if not any(r['raceNumber'] == race_num for r in found_races):
                        found_races.append({
                            'raceNumber': race_num,
                            'time': time,
                            'distance': distance,
                            'track': track,
                            'city': city_id, # We don't have city name easily, use ID or map it
                            'info': text[:100] # Summary
                        })
        
        if not found_races:
             # Fallback: Try to parse from the `daily_races` logic I saw earlier
             # Maybe the response is a table?
             pass
             
        return jsonify({
            'success': True,
            'races': found_races,
            'count': len(found_races),
            'cityId': city_id,
            'date': date_param
        })

    except Exception as e:
        return jsonify({'success': False, 'error': f'Server Error: {str(e)}'}), 500


@app.route('/health', methods=['GET'])
def health_check():
    """Sunucu sağlık kontrolü"""
    return jsonify({'status': 'ok', 'message': 'TJK API Server çalışıyor'})

if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 5000))
    print("TJK API Server başlatılıyor...")
    print("Endpoint'ler:")
    print("  POST /api/search-horses - At arama")
    print("  POST /api/horse-details - At detayları")
    print("  POST /api/search-races - Yarış arama")
    print("  POST /api/daily-races - Günün koşuları")
    print("  GET  /daily-program - Günün Yarış Programı (Yeni)")
    print("  GET  /health - Sağlık kontrolü")
    print(f"Port: {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
