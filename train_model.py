"""
FAZ 7 — XGBoost MODEL EĞİTİCİ
================================
build_training_dataset.py ile üretilen training_data.csv'yi kullanarak
XGBoost ranking modeli eğitir ve kaydeder.

Çıktılar:
  model_xgb.json       → eğitilmiş model
  feature_importance.png (opsiyonel)

Kullanım:
  python train_model.py
  python train_model.py --csv training_data.csv
  python train_model.py --eval      → sadece backtesting raporu
"""

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

try:
    import xgboost as xgb
except ImportError:
    print("[ERROR] xgboost kurulu değil. Çalıştır: pip install xgboost")
    sys.exit(1)

from sklearn.model_selection import GroupShuffleSplit
from sklearn.metrics import ndcg_score

# ── Config ─────────────────────────────────────────────────────────
FEATURE_COLS = [
    "degree_avg", "degree_trend", "degree_stability",
    "form_trend", "track_suit", "distance_suit",
    "training_fitness", "training_degree_score",
    "weight_impact", "jockey_score", "bounce_score",
    "pace_score", "pedigree", "hp_score",
    "agf_score", "trainer_score",
    # meta-features
    "field_size",
]

TARGET_COL    = "finish_pos"      # label: bitiş pozisyonu (1 = iyi)
GROUP_COL     = "race_id"        # her koşu = bir grup
OUTPUT_MODEL  = "model_xgb.json"
OUTPUT_SCALER = "feature_stats.json"


# ══════════════════════════════════════════════════════════════════
# BÖLÜM 1: VERİ HAZIRLIĞI
# ══════════════════════════════════════════════════════════════════

def load_and_clean(csv_path: str) -> pd.DataFrame:
    df = pd.read_csv(csv_path)
    print(f"[DATA] {len(df)} satır, {df['race_id'].nunique()} koşu yüklendi")

    # Tamamlanmamış satırları at
    df = df.dropna(subset=[TARGET_COL] + FEATURE_COLS[:5])
    df[TARGET_COL] = pd.to_numeric(df[TARGET_COL], errors="coerce")
    df = df.dropna(subset=[TARGET_COL])
    df[TARGET_COL] = df[TARGET_COL].astype(int)

    # Sadece en az 3 atlı koşuları al
    race_counts = df.groupby(GROUP_COL).size()
    valid_races = race_counts[race_counts >= 3].index
    df = df[df[GROUP_COL].isin(valid_races)]

    # Eksik feature'ları 50 ile doldur (nötr)
    for col in FEATURE_COLS:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce").fillna(50.0)
        else:
            df[col] = 50.0

    print(f"[DATA] Temizleme sonrası: {len(df)} satır, {df[GROUP_COL].nunique()} koşu")
    return df


def add_meta_features(df: pd.DataFrame) -> pd.DataFrame:
    """Ek türetilmiş özellikler ekle."""
    # Koşu içi normalize (her at kendi koşusundaki rakiplerine göre)
    for col in ["degree_avg", "form_trend", "track_suit"]:
        if col in df.columns:
            group_mean = df.groupby(GROUP_COL)[col].transform("mean")
            group_std  = df.groupby(GROUP_COL)[col].transform("std").replace(0, 1)
            df[f"{col}_zscore"] = (df[col] - group_mean) / group_std

    return df


# ══════════════════════════════════════════════════════════════════
# BÖLÜM 2: MODEL EĞİTİMİ
# ══════════════════════════════════════════════════════════════════

def train(df: pd.DataFrame) -> xgb.XGBRanker:
    """XGBoost LambdaMART ranker eğit."""

    # Feature listesi (z-score eklenmiş sütunlar dahil)
    feature_cols = [c for c in FEATURE_COLS if c in df.columns]
    feature_cols += [c for c in df.columns if c.endswith("_zscore")]

    # Label: düşük finish_pos = iyi → ters çevir (max is best için)
    # XGBRanker pair-wise => label = relevance score (yüksek = daha iyi)
    df["relevance"] = df.groupby(GROUP_COL)[TARGET_COL].transform(
        lambda x: (x.max() + 1 - x).astype(float)
    )

    # Train / validation split (race bazlı — veri sızıntısı olmadan)
    race_ids = df[GROUP_COL].values
    gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    train_idx, val_idx = next(gss.split(df, groups=race_ids))

    df_train = df.iloc[train_idx].sort_values(GROUP_COL)
    df_val   = df.iloc[val_idx].sort_values(GROUP_COL)

    X_train = df_train[feature_cols].values
    y_train = df_train["relevance"].values
    q_train = df_train.groupby(GROUP_COL).size().values

    X_val   = df_val[feature_cols].values
    y_val   = df_val["relevance"].values
    q_val   = df_val.groupby(GROUP_COL).size().values

    model = xgb.XGBRanker(
        objective       = "rank:pairwise",
        learning_rate   = 0.05,
        n_estimators    = 400,
        max_depth       = 5,
        subsample       = 0.8,
        colsample_bytree= 0.8,
        reg_alpha       = 0.1,
        reg_lambda      = 1.0,
        tree_method     = "hist",
        random_state    = 42,
        verbosity       = 1,
    )

    model.fit(
        X_train, y_train,
        group           = q_train,
        eval_set        = [(X_val, y_val)],
        eval_group      = [q_val],
        verbose         = 50,
    )

    # Validation metriği
    val_score = evaluate(model, df_val, feature_cols)
    print(f"\n[EVAL] Validation Winner Hit-Rate: %{val_score:.1f}")

    return model, feature_cols


# ══════════════════════════════════════════════════════════════════
# BÖLÜM 3: DEĞERLENDİRME
# ══════════════════════════════════════════════════════════════════

def evaluate(model, df_eval: pd.DataFrame, feature_cols: list) -> float:
    """
    Her koşuda 1. tahmin edilen atın gerçekten 1. olma oranı (top-1 hit rate).
    Sektör ortalaması: %20-25. Hedefimiz: %30+
    """
    correct = 0
    total   = 0

    for race_id, group in df_eval.groupby(GROUP_COL):
        if len(group) < 2:
            continue
        X = group[feature_cols].values
        scores = model.predict(X)
        pred_winner_idx = int(np.argmax(scores))
        actual_winner_finish = group.iloc[pred_winner_idx][TARGET_COL]
        if actual_winner_finish == 1:
            correct += 1
        total += 1

    return (correct / total * 100) if total > 0 else 0.0


def evaluate_top3(model, df_eval: pd.DataFrame, feature_cols: list) -> float:
    """Top-3 hit rate: algoritmamızın top-3'ünde gerçek 1. var mı."""
    correct = 0
    total   = 0

    for race_id, group in df_eval.groupby(GROUP_COL):
        if len(group) < 3:
            continue
        X = group[feature_cols].values
        scores = model.predict(X)
        top3_idx = np.argsort(scores)[::-1][:3]
        top3_finishes = group.iloc[top3_idx][TARGET_COL].values
        if 1 in top3_finishes:
            correct += 1
        total += 1

    return (correct / total * 100) if total > 0 else 0.0


# ══════════════════════════════════════════════════════════════════
# BÖLÜM 4: KAYDET
# ══════════════════════════════════════════════════════════════════

def save_model(model, feature_cols: list, df: pd.DataFrame):
    model.save_model(OUTPUT_MODEL)
    print(f"[SAVE] Model kaydedildi → {OUTPUT_MODEL}")

    # Feature istatistiklerini kaydet (blend sırasında normalize için)
    stats = {}
    for col in feature_cols:
        if col in df.columns:
            stats[col] = {
                "mean": float(df[col].mean()),
                "std":  float(df[col].std()),
            }
    with open(OUTPUT_SCALER, "w", encoding="utf-8") as f:
        json.dump({"feature_cols": feature_cols, "stats": stats}, f, indent=2, ensure_ascii=False)
    print(f"[SAVE] Feature istatistikleri → {OUTPUT_SCALER}")


def print_feature_importance(model, feature_cols: list):
    importance = model.feature_importances_
    pairs = sorted(zip(feature_cols, importance), key=lambda x: -x[1])
    print("\n[FEATURE IMPORTANCE]")
    for name, score in pairs[:10]:
        bar = "█" * int(score * 200)
        print(f"  {name:<30} {score:.4f}  {bar}")


# ══════════════════════════════════════════════════════════════════
# ANA AKIŞ
# ══════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="XGBoost At Yarışı Ranker Eğitici")
    parser.add_argument("--csv",  type=str, default="training_data.csv", help="Eğitim verisi CSV")
    parser.add_argument("--eval", action="store_true", help="Sadece değerlendirme (model zaten eğitilmiş)")
    args = parser.parse_args()

    csv_path = Path(args.csv)
    if not csv_path.exists():
        print(f"[ERROR] {csv_path} bulunamadı. Önce build_training_dataset.py çalıştırın.")
        sys.exit(1)

    print("=" * 60)
    print("FAZ 7 — XGBoost Model Eğitimi")
    print(f"  Veri: {args.csv}")
    print("=" * 60)

    # 1. Veri yükle
    df = load_and_clean(args.csv)
    df = add_meta_features(df)

    if args.eval:
        model = xgb.XGBRanker()
        model.load_model(OUTPUT_MODEL)
        with open(OUTPUT_SCALER, encoding="utf-8") as f:
            saved = json.load(f)
        feature_cols = saved["feature_cols"]
        hit_rate  = evaluate(model, df, feature_cols)
        top3_rate = evaluate_top3(model, df, feature_cols)
        print(f"\n[RESULT] Top-1 Hit Rate: %{hit_rate:.1f}")
        print(f"[RESULT] Top-3 Hit Rate: %{top3_rate:.1f}")
        return

    # 2. Eğit
    model, feature_cols = train(df)

    # 3. Kaydet
    save_model(model, feature_cols, df)

    # 4. Feature importance göster
    print_feature_importance(model, feature_cols)

    # 5. Tam dataset üzerinde değerlendirme
    hit_rate  = evaluate(model, df, feature_cols)
    top3_rate = evaluate_top3(model, df, feature_cols)

    print(f"\n{'='*60}")
    print(f"[SONUÇ] Top-1 Winner Hit Rate : %{hit_rate:.1f}")
    print(f"[SONUÇ] Top-3 Hit Rate        : %{top3_rate:.1f}")
    print(f"[SONUÇ] Sektör ortalaması     : %20-25")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
