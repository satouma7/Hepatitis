# スライドごとの代表ベクトルを作る
import pandas as pd
import numpy as np

DF = pd.read_parquet("GAPlayer_merged.parquet")  # さっき出力したやつ
feat_cols = [c for c in DF.columns if c.startswith("f")]

# ラベルは多数決（tie は最初の出現でOK）
def majority_label(s: pd.Series) -> str:
    return s.value_counts().index[0]

centroids = (
    DF.groupby("orig_id")
      .agg({**{c:"mean" for c in feat_cols}, "Label": majority_label, "Path":"first"})
      .reset_index()
)

centroids.to_parquet("centroids.parquet", index=False)
centroids.to_csv("centroids.csv", index=False)
print(centroids.shape, "-> centroids.{parquet,csv} を出力しました")
print(centroids.head(3)[["orig_id","Label"] + feat_cols[:5]])