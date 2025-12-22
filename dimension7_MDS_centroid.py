import numpy as np, pandas as pd
from pathlib import Path
from sklearn.decomposition import PCA
from sklearn.manifold import MDS
import matplotlib.pyplot as plt

# データ読み込み
C = pd.read_parquet("centroids.parquet")
feat_cols = [c for c in C.columns if c.startswith("f")]
CX   = C[feat_cols].values #重心ベクトルデータ
Cid  = C["orig_id"].astype(int).values #重心ID
Clab = C["Label"].values #重心ラベル

# MDS（metric=TrueのSMACOF）
mds = MDS(n_components=2, dissimilarity="euclidean",
          n_init=1, max_iter=200, random_state=0, verbose=1)
CXmds = mds.fit_transform(CX)

# ざっくり可視化（AIH=青, DILI=橙）
colors = np.where(Clab=="AIH", "tab:blue", "tab:orange")
fig, ax = plt.subplots(figsize=(6,5))
ax.scatter(CXmds[:,0], CXmds[:,1], c=colors, s=40, alpha=0.9, linewidths=0)
for x,y,s in zip(CXmds[:,0], CXmds[:,1], Cid):
    ax.text(x, y, str(s), fontsize=9, weight="bold",
            color="k", ha="center", va="center")
ax.set_title("MDS (centroids)")
ax.set_xlabel("dim1"); ax.set_ylabel("dim2")
plt.tight_layout(); plt.show()