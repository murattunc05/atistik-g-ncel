"""
FAZ 7 — ML EĞİTİM VERİSİ TOPLAYICI (v2)
==========================================
Strateji:
  1. TJK KosuSorgulama → koşu listesi + at isimleri + linkler
  2. Her at için /api/horse-details → geçmis koşuları
  3. O koşudaki bitiş pozisyonunu geçmişten çek (label)
  4. Algoritmamızın feature hesaplayıcısını direkt import et
     → scraping yerine yerel hesap (çok daha hızlı)

Çıktı: training_data.csv
  horse_name, race_id, race_type, field_size, finish_pos, is_winner,
  <14 feature>

Kullanım:
  pip install xgboost scikit-learn
  python build_training_dataset.py --months 3
  python build_training_dataset.py --months 1 --max 30 --output test.csv
"""

import requests
import time
import csv
import re
import sys
import json
import argparse
import urllib.parse
from datetime import datetime, timedelta
from pathlib import Path
from bs4 import BeautifulSoup

# ── Config ─────────────────────────────────────────────────────────
BACKEND_URL  = "https://atistik-backend.onrender.com"
TJK_BASE     = "https://www.tjk.org"
OUTPUT_CSV   = "training_data.csv"
DELAY        = 0.8

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept-Language": "tr-TR,tr;q=0.9",
    "Referer": TJK_BASE,
}

FEATURE_COLS = [
    "degree_avg", "degree_trend", "degree_stability",
    "form_trend", "track_suit", "distance_suit",
    "training_fitness", "training_degree_score",
    "weight_impact", "jockey_score", "bounce_score",
    "pace_score", "pedigree", "hp_score",
    "agf_score", "trainer_score",
]

ALL_COLS = [
    "horse_name", "race_id", "date", "city",
    "race_type", "distance", "track_type",
    "field_size", "finish_pos", "is_winner",
] + FEATURE_COLS


# ══════════════════════════════════════════════════════════════════
# ADIM 1: KosuSorgulama → koşu listesi
# ══════════════════════════════════════════════════════════════════

def get_past_races(months: int, city_id: str = "-1") -> list[dict]:
    end   = datetime.now()
    start = end - timedelta(days=30 * months)
    params = {
        "QueryParameter_Tarih_Start": start.strftime("%d.%m.%Y"),
        "QueryParameter_Tarih_End":   end.strftime("%d.%m.%Y"),
        "QueryParameter_SehirId":     city_id,
    }
    url = f"{TJK_BASE}/TR/YarisSever/Query/Page/KosuSorgulama"
    print(f"[COLLECT] {params['QueryParameter_Tarih_Start']} → {params['QueryParameter_Tarih_End']}")
    try:
        resp = requests.get(url, params=params, headers=HEADERS, timeout=20)
        soup = BeautifulSoup(resp.text, "html.parser")
        tbody = soup.find("tbody", id="tbody0") or soup.find("tbody")
        if not tbody:
            print("[WARN] Tablo bulunamadı"); return []

        races = []
        for row in tbody.find_all("tr"):
            if "hidable" in row.get("class", []): continue
            cells = row.find_all("td")
            if len(cells) < 6: continue
            try:
                links = [(a.text.strip(), a.get("href", "")) for a in row.find_all("a", href=True)]
                race_id = None
                for _, href in links:
                    m = re.search(r"#(\d{5,})", href)
                    if m: race_id = m.group(1); break
                if not race_id: continue

                # Detay link — at listesi için
                detail_href = links[0][1] if links else ""
                date_txt   = cells[0].text.strip()
                city_txt   = cells[1].text.strip()
                race_no    = cells[2].text.strip()
                race_type  = cells[4].text.strip() if len(cells) > 4 else ""
                distance   = re.sub(r"[^\d]", "", cells[6].text.strip()) if len(cells) > 6 else ""
                track      = cells[7].text.strip() if len(cells) > 7 else ""

                races.append({
                    "race_id":      race_id,
                    "date":         date_txt,
                    "city":         city_txt,
                    "race_no":      race_no,
                    "race_type":    race_type,
                    "distance":     distance,
                    "track":        track,
                    "detail_href":  detail_href,
                })
            except Exception:
                continue

        print(f"[COLLECT] {len(races)} koşu bulundu")
        return races

    except Exception as e:
        print(f"[ERROR] {e}"); return []


# ══════════════════════════════════════════════════════════════════
# ADIM 2: Koşu program sayfasından at listesi + linklerini çek
# ══════════════════════════════════════════════════════════════════

def get_race_horses(race_id: str, date: str, city_id: str = "34") -> list[dict]:
    """
    TJK GunlukYarisProgrami sayfasından at listesini çeker.
    URL: /TR/YarisSever/Info/Page/GunlukYarisProgrami?QueryParameter_RaceId=XXXXX
    """
    url = f"{TJK_BASE}/TR/YarisSever/Info/Page/GunlukYarisProgrami"
    params = {"QueryParameter_RaceId": race_id}
    try:
        resp = requests.get(url, params=params, headers=HEADERS, timeout=15)
        if resp.status_code != 200: return []

        soup = BeautifulSoup(resp.text, "html.parser")

        # At linklerini bul: /TR/YarisSever/Info/Page/AtBilgileri?...
        at_links = soup.find_all("a", href=re.compile(r"AtBilgileri"))
        if not at_links:
            return []

        horses = []
        seen = set()
        for a in at_links:
            horse_name = a.text.strip()
            href = a.get("href", "")
            if not horse_name or horse_name in seen: continue
            seen.add(horse_name)
            horses.append({
                "name":        horse_name,
                "detail_link": href,
            })

        return horses
    except Exception as e:
        print(f"[ERROR] get_race_horses({race_id}): {e}")
        return []


# ══════════════════════════════════════════════════════════════════
# ADIM 3: Backend /api/horse-details ile geçmişi al
# ══════════════════════════════════════════════════════════════════

def get_horse_history(detail_link: str) -> list[dict]:
    """Backend'deki /api/horse-details endpoint'ini çağırır."""
    try:
        resp = requests.post(
            f"{BACKEND_URL}/api/horse-details",
            json={"detailLink": detail_link},
            timeout=30,
        )
        if resp.status_code != 200: return []
        data = resp.json()
        return data.get("races", [])
    except Exception as e:
        return []


# ══════════════════════════════════════════════════════════════════
# ADIM 4: Koşu ID'sine göre geçmişten bitiş pozisyonunu bul
# ══════════════════════════════════════════════════════════════════

def find_finish_in_history(races: list[dict], race_id: str, race_date: str) -> int | None:
    """
    At geçmişinden race_id veya tarih ile eşleşen koşunun bitiş pozisyonunu bul.
    """
    for r in races:
        # Koşu geçmişinde race_id veya tarih eşleşmesi
        hist_date = r.get("date", "")
        hist_id   = str(r.get("raceId", ""))
        if hist_id == str(race_id):
            rank = r.get("rank", "")
            if str(rank).isdigit(): return int(rank)
        # Tarih eşleştirmesi (yedek)
        if race_date and hist_date:
            # "24.04.2026" formatına normalize et
            if race_date[:10] in hist_date or hist_date in race_date:
                rank = r.get("rank", "")
                if str(rank).isdigit(): return int(rank)
    return None


# ══════════════════════════════════════════════════════════════════
# ADIM 5: Feature hesapla — Backend analyze-race endpoint
# ══════════════════════════════════════════════════════════════════

def compute_features(horse_name: str, race_info: dict) -> dict | None:
    """Backend analyze-race endpoint'ini tek bir at için çağır."""
    try:
        payload = {
            "horses": [{
                "name":       horse_name,
                "no":         "1",
                "detailLink": "",
            }],
            "targetDistance": race_info.get("distance", ""),
            "targetTrack":    race_info.get("track", ""),
            "raceType":       race_info.get("race_type", ""),
        }
        resp = requests.post(
            f"{BACKEND_URL}/api/analyze-race",
            json=payload,
            timeout=60,
        )
        if resp.status_code != 200: return None
        data = resp.json()
        results = data.get("results", [])
        if not results: return None
        return results[0].get("metrics", {})
    except Exception:
        return None


# ══════════════════════════════════════════════════════════════════
# ANA AKIŞ
# ══════════════════════════════════════════════════════════════════

def process_race(race_info: dict, writer: csv.DictWriter, all_horses_done: set) -> int:
    race_id   = race_info["race_id"]
    race_date = race_info["date"]

    time.sleep(DELAY)

    # At listesini çek
    horses = get_race_horses(race_id, race_date)
    if not horses:
        print(f"  [SKIP] {race_id} - at listesi yok")
        return 0

    field_size = len(horses)
    rows = 0

    for horse in horses:
        horse_name = horse["name"]
        if horse_name in all_horses_done:
            continue

        # Geçmiş yarış verilerini al
        hist_races = get_horse_history(horse["detail_link"])
        if not hist_races:
            continue

        # Bu koşunu geçmişinde bul → bitiş pozisyonu
        finish = find_finish_in_history(hist_races, race_id, race_date)
        if finish is None:
            continue

        # Feature'ları hesapla
        metrics = compute_features(horse_name, race_info)
        if not metrics:
            continue

        row = {
            "horse_name": horse_name,
            "race_id":    race_id,
            "date":       race_date,
            "city":       race_info.get("city", ""),
            "race_type":  race_info.get("race_type", ""),
            "distance":   race_info.get("distance", ""),
            "track_type": race_info.get("track", ""),
            "field_size": field_size,
            "finish_pos": finish,
            "is_winner":  1 if finish == 1 else 0,
        }
        for feat in FEATURE_COLS:
            row[feat] = metrics.get(feat, 50.0)

        writer.writerow(row)
        rows += 1
        time.sleep(0.3)

    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--months", type=int, default=3)
    parser.add_argument("--city",   type=str, default="-1")
    parser.add_argument("--max",    type=int, default=300)
    parser.add_argument("--output", type=str, default=OUTPUT_CSV)
    args = parser.parse_args()

    print("=" * 60)
    print(f"FAZ 7 — Eğitim Veri Toplayıcı v2 | Son {args.months} ay")
    print("=" * 60)

    races = get_past_races(args.months, args.city)[:args.max]
    print(f"\n{len(races)} koşu işlenecek → {args.output}\n")

    total = 0
    done_horses: set = set()

    with open(args.output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=ALL_COLS)
        writer.writeheader()

        for i, race_info in enumerate(races, 1):
            print(f"[{i}/{len(races)}] {race_info['date']} {race_info['city']} - {race_info['race_type']}", end=" → ")
            try:
                n = process_race(race_info, writer, done_horses)
                total += n
                print(f"{n} satır")
                f.flush()
            except Exception as e:
                print(f"HATA: {e}")

    print(f"\n{'='*60}\nTOPLAM: {total} satır → {args.output}\n{'='*60}")


if __name__ == "__main__":
    main()
