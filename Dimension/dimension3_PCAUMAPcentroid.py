# Plot_PCA/sSNE/MDS/UMAP_centroid

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import umap.umap_ as umap
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE, MDS

# ---- load ----
C = pd.read_parquet("centroids.parquet")
feat_cols = [c for c in C.columns if c.startswith("f")]
X = C[feat_cols].values
y = C["Label"].values  # 'AIH' / 'DILI'

# カラー（AIH=青, DILI=オレンジ）
colors = np.where(y == "AIH", "tab:blue", "tab:orange")

# ---- PCA ----
pca = PCA(n_components=2, random_state=0)
X_pca = pca.fit_transform(X)

# ---- t-SNE ----
# サンプルが少ないときは perplexity を小さめに
perp = max(5, min(30, X.shape[0] // 3))
X_tsne = TSNE(n_components=2, learning_rate="auto", init="pca", perplexity=perp, random_state=0).fit_transform(X)

# ---- MDS ----
X_mds = MDS(n_components=2, random_state=0, n_init=4, max_iter=300).fit_transform(X)

# ---- UMAP ----
X_umap = umap.UMAP(n_neighbors=10, min_dist=0.1, metric="cosine", random_state=0).fit_transform(X)

# ---- plot ----
panels = [("PCA", X_pca), ("t-SNE", X_tsne), ("MDS", X_mds), ("UMAP", X_umap)]

n = len(panels)
rows, cols = 2, 2
fig, axes = plt.subplots(rows, cols, figsize=(12, 10))
axes = axes.ravel()

# 高精度 / 低精度スライドID
high_acc = {1047, 1063, 2141, 2171, 1026, 2136}
low_acc  = {1097, 1015, 2137, 2114, 2118, 1002}

for ax, (name, X2) in zip(axes, panels):
    ax.scatter(X2[:, 0], X2[:, 1], c=colors, s=40, alpha=0.9, edgecolors="none")
    for i, oid in enumerate(C["orig_id"].values):
        if oid in high_acc:
            ax.text(X2[i, 0], X2[i, 1], str(oid), fontsize=9, ha="left", va="center", color="red")
        # elif oid in low_acc:
        #     ax.text(X2[i, 0], X2[i, 1], str(oid), fontsize=9, ha="left", va="center", color="blue") 
        # else:
        #     ax.text(X2[i, 0], X2[i, 1], str(oid), fontsize=8, ha="left", va="center")
    ax.set_title(f"{name} (centroids)")
    ax.set_xlabel(name + "1")
    ax.set_ylabel(name + "2")

# 凡例（ラベル1個だけで十分）
from matplotlib.lines import Line2D
legend_elems = [
    Line2D([0], [0], marker='o', color='w', label='AIH',
           markerfacecolor='tab:blue', markersize=8),
    Line2D([0], [0], marker='o', color='w', label='DILI',
           markerfacecolor='tab:orange', markersize=8),
]
fig.legend(handles=legend_elems, loc="upper right")

plt.tight_layout()
plt.savefig("centroids_DR_4panels.png", dpi=200)
print(f"-> centroids_DR_4panels.png を保存しました")