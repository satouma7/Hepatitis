# GAPlayerとlabelsを結合して、orig_idを付与する
import re
import pandas as pd
from pathlib import Path

# ---- 入力ファイル ----
GAPlayer_path = "GAPlayer.csv"   # 1024行 × 35555列（想定）
labels_path   = "labels.csv"     # 列: Path, Label（見出しあり）

# ---- 1) ラベル読み込み & 元画像ID抽出 ----
lab = pd.read_csv(labels_path)   # columns: ["Path","Label"]pip
assert {"Path","Label"}.issubset(lab.columns), "labels.csv に Path, Label 列が必要です"

# パスから元画像ID（SmallSize_XXXX_… の XXXX）を抽出
def extract_orig_id(p: str) -> int:
    m = re.search(r"SmallSize_(\d+)_", Path(p).name)
    if not m:
        raise ValueError(f"元画像IDを抽出できません: {p}")
    return int(m.group(1))

lab["orig_id"] = lab["Path"].apply(extract_orig_id)

# ---- 2) GAPlayer（特徴量）読み込み ----
# 形状: 1024行 × N列（N=35555想定） → 転置して N行 × 1024列に
G = pd.read_csv(GAPlayer_path, header=None)  # 行=feature, 列=sample
G = G.T
# 次元に名前をつける
G.columns = [f"f{i}" for i in range(G.shape[1])]

# ---- 3) 行数（サンプル数）対応チェック ----
if len(G) != len(lab):
    raise ValueError(f"サンプル数不一致: GAPlayer={len(G)} vs labels={len(lab)}")

# ここで重要：labels.csv の行順と GAPlayer.csv の列順が同一前提。
#（通常は前処理で同じ順に保存しているはず）
# 念のため Path のハッシュ等が別にある場合はそれで照合するが、
# 今回は順序一致を前提にそのまま結合する。

# ---- 4) 結合（サンプル × 1024次元 + 付帯情報）----
X = pd.concat([lab[["Path","orig_id","Label"]].reset_index(drop=True),
               G.reset_index(drop=True)], axis=1)

# ---- 5) 保存（後工程が速い Parquet も併せて）----
#parquetは列指向のバイナリ形式でpandas用　高速
X.to_parquet("GAPlayer_merged.parquet", index=False)
X.to_csv("GAPlayer_merged.csv", index=False)

print(X.shape, "-> GAPlayer_merged.{csv,parquet} を出力しました")
print(X.head())