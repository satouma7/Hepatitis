# Plot_PCA/sSNE/MDS/UMAP_all
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import umap.umap_ as umap
import matplotlib.cm as cm
import matplotlib.colors as mcolors
from matplotlib.lines import Line2D
from pathlib import Path
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.manifold import TSNE, MDS

def alpha_for_id(sid):
    if sid in high_acc: return high     # 濃い
    if sid in low_acc:  return low    # 薄い
    return medium                   # ふつう

def scatter_by_slide(ax, X2, title):
    # 速度と凡例のため、スライド単位でまとめて描画
    for sid in uniq_ids:
        sel = (ids == sid)
        if not np.any(sel): 
            continue
        # 点ごとの色（ラベルでわずかに色味を変える）
        base_color = id2color[sid]
        cols = np.tile(base_color, (sel.sum(), 1))
        ax.scatter(X2[sel,0], X2[sel,1],
                   c=cols,
                   s=6,
                   alpha=alpha_for_id(sid),
                   linewidths=0)
    ax.set_title(title)
    ax.set_xlabel(title.split()[0] + "1")
    ax.set_ylabel(title.split()[0] + "2")

DF = pd.read_parquet("GAPlayer_merged.parquet")
OUT_DIR = Path("dr_all_out"); OUT_DIR.mkdir(exist_ok=True)

feat_cols = [c for c in DF.columns if c.startswith("f")]
X = DF[feat_cols].values
labels = DF["Label"].values           # 'AIH' / 'DILI'
ids = DF["orig_id"].values.astype(int)

# スライドごとに色を割り当て（同一IDは同じ色）
uniq_ids = np.unique(ids)
aih_ids  = [sid for sid in uniq_ids if sid < 2000]
dili_ids = [sid for sid in uniq_ids if sid >= 2000]
cmap = plt.cm.jet
aih_colors = cmap(np.linspace(0.0, 0.4, len(aih_ids)))
dili_colors = cmap(np.linspace(0.6, 1.0, len(dili_ids)))
id2color = {}
for sid, c in zip(aih_ids, aih_colors):
    id2color[sid] = c
for sid, c in zip(dili_ids, dili_colors):
    id2color[sid] = c

# 高精度/低精度でアルファ（濃淡）を変える
high=1
medium=0
low=0
high_acc = {1047, 1063, 2141, 2171, 1026, 2136}
low_acc  = {1097, 1015, 2137, 2114, 2118, 1002}

# 2D に圧縮
X_pca = PCA(n_components=2, random_state=0).fit_transform(X)
# perp = max(5, min(30, X.shape[0] // 3))
# X_tsne = TSNE(n_components=2, learning_rate="auto", init="pca", perplexity=perp, random_state=0).fit_transform(X)
# X_mds = MDS(n_components=2, random_state=0, n_init=4, max_iter=300).fit_transform(X)
X_umap = umap.UMAP(n_neighbors=15, min_dist=0.1, metric="cosine", random_state=0).fit_transform(X)

# ---- plot ---
fig, axes = plt.subplots(1, 2, figsize=(14, 6), constrained_layout=True)
scatter_by_slide(axes[0], X_pca, "PCA (all patches)")
# scatter_by_slide(axes[1], X_tsne, "t-SNE (all patches)")
# scatter_by_slide(axes[2], X_mds, "MDS (all patches)")
scatter_by_slide(axes[1], X_umap, "UMAP (all patches)")

#カラーバー
sorted_ids  = np.array(sorted(uniq_ids))
base_colors = np.array([id2color[sid] for sid in sorted_ids])[:, :3]  # RGBA→RGB
cmap = mcolors.ListedColormap(base_colors)
norm = mcolors.BoundaryNorm(np.arange(len(sorted_ids) + 1), cmap.N)
sm = cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array([])
cbar = fig.colorbar(sm, ax=axes, fraction=0.03, pad=0.02)
cbar.set_label("Slide ID (base color)")

max_ticks = 12  # 見やすさ用
step = max(1, len(sorted_ids) // max_ticks)
tick_pos = np.arange(0, len(sorted_ids), step)
cbar.set_ticks(tick_pos)
cbar.set_ticklabels(sorted_ids[tick_pos])

# 簡易凡例（high/low の濃淡見本）
legend_elems = [
    Line2D([0],[0], marker='o', color='w', label='high-acc slides', markerfacecolor='k', markersize=8, alpha=high),
    Line2D([0],[0], marker='o', color='w', label='normal slides',   markerfacecolor='k', markersize=8, alpha=medium),
    Line2D([0],[0], marker='o', color='w', label='low-acc slides',  markerfacecolor='k', markersize=8, alpha=low),
]
axes[1].legend(handles=legend_elems, loc="lower right", frameon=False)

plt.savefig(OUT_DIR / "all_patches_by_slide_high.png", dpi=180)
plt.show()