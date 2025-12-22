# 全サンプルを用いてPCA/UMAP計算、可視化
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import cm
from matplotlib.colors import Normalize
from matplotlib.lines import Line2D
from pathlib import Path
from sklearn.decomposition import PCA
from adjustText import adjust_text
import umap
import matplotlib.patheffects as pe

def alpha_for_id(sid:int)->float:
    if sid in high_acc: return 0.9
    if sid in low_acc:  return 0.15
    return 0.35

def scatter_by_slide(ax, X2, id_vec, lab_vec, title,id2color):
    for sid in np.unique(id_vec):
        sel = (id_vec == sid)
        cols = np.vstack([id2color[sid] for _ in range(sel.sum())])
        ax.scatter(X2[sel,0], X2[sel,1],c=cols, s=6, alpha=alpha_for_id(sid),linewidths=0)
    ax.set_title(title); ax.set_xlabel(title.split()[0]+"1"); ax.set_ylabel(title.split()[0]+"2")

def overlay_centroids(ax, Xc, idc, labc,id2color):
    texts = []
    for (x, y, sid, lab) in zip(Xc[:,0], Xc[:,1], idc, labc):
        ax.scatter([x],[y], s=50, c=[id2color[sid]], edgecolors="k", linewidths=0.7, zorder=5)
        texts.append(ax.text(x+0.2, y+0.2, str(sid),fontsize=7, weight="bold", 
        color="k", path_effects=[pe.withStroke(linewidth=2, foreground="w")], zorder=6))
    adjust_text(texts, arrowprops=dict(arrowstyle="-", color='gray'))

# 高精度/低精度の定義
high_acc = {1047, 1063, 2141, 2171, 1026, 2136, 1075, 2158, 1016, 2131, 2197}
low_acc  = {1097, 1015, 2137, 2114, 2118, 1002}

# ---- 入力 ----
DF = pd.read_parquet("GAPlayer_merged.parquet")   # 全パッチ (1024次元＋メタ)
C  = pd.read_parquet("centroids.parquet")         # スライド重心（同じ1024次元）

#DFのうちfで始まる列(GAP層ベクトルのデータ)のみを抽出
feat_cols = [c for c in DF.columns if c.startswith("f")]
Xall = DF[feat_cols].values #全ベクトルデータ
id_all   = DF["orig_id"].astype(int).values #サンプルID
lab_all= DF["Label"].values  # 'AIH' / 'DILI'

CX   = C[feat_cols].values #重心ベクトルデータ
Cid_all  = C["orig_id"].astype(int).values #重心ID
Clab_all = C["Label"].values #重心ラベル

# ---- 次元圧縮器を “全パッチ” で学習（座標系の基準を固定）----
Xpca = PCA(n_components=2, random_state=0).fit(Xall)
Xumap  = umap.UMAP(n_neighbors=15, min_dist=0.1, metric="cosine", random_state=0).fit(Xall)
Xpca_all = Xpca.transform(Xall)#PCAの結果を2次元配列化
Xumap_all = Xumap.transform(Xall)#UMAPの結果を2次元配列化

# ---- 可視化対象：high-acc スライドのみ ----
all_high = np.isin(id_all, list(high_acc))
Xall_high  = Xall[all_high]
id_high  = id_all[all_high]
lab_high = lab_all[all_high]

Xpca_high = Xpca.transform(Xall_high)#PCAの結果を2次元配列化(highのみ)
Xumap_high = Xumap.transform(Xall_high)#UMAPの結果を2次元配列化(highのみ)

Cpca_all = Xpca.transform(CX)#PCAの結果を2次元配列化(重心のみ)
Cumap_all = Xumap.transform(CX)#UMAPの結果を2次元配列化(重心のみ)

# high-acc の centroid だけ抜き出す
cent_high = np.isin(Cid_all, list(high_acc))
Cpca_high = Cpca_all[cent_high]
Cumap_high = Cumap_all[cent_high]
Cid_high = Cid_all[cent_high]
Clab_high = Clab_all[cent_high]

# ---- カラー: jet の前半(青系)=AIH, 後半(赤系)=DILI を均等割り当て ----
cmap = cm.get_cmap("jet")
uniq_id = np.unique(id_all)
aih_id  = sorted([sid for sid in uniq_id if sid < 2000])
dili_id = sorted([sid for sid in uniq_id if sid >= 2000])
aih_pos  = np.linspace(0.00, 0.38, len(aih_id))   # 青～シアン
dili_pos = np.linspace(0.62, 1.00, len(dili_id))  # 黄～赤
id2color = {}
for sid, pos in zip(aih_id, aih_pos):   id2color[sid]  = cmap(pos)
for sid, pos in zip(dili_id, dili_pos): id2color[sid]  = cmap(pos)

# ---- 図を作成（PCA/UMAP 並置）----
fig, axes = plt.subplots(1, 2, figsize=(14, 6), constrained_layout=True)

# PCA+UMAP パネル（全パッチ + centroid）
scatter_by_slide(axes[0], Xpca_all, id_all, lab_all, "PCA (all patches)",id2color)
overlay_centroids(axes[0], Cpca_all, Cid_all, Clab_all,id2color)
scatter_by_slide(axes[1], Xumap_all, id_all, lab_all, "UMAP (all patches)",id2color)
overlay_centroids(axes[1], Cumap_all, Cid_all, Clab_all,id2color)

# 濃淡の凡例
legend_elems = [
    Line2D([0],[0], marker='o', color='w', label='high-acc slide patches', markerfacecolor='k', markersize=8, alpha=0.9),
    Line2D([0],[0], marker='o', color='w', label='med-acc slide patches',   markerfacecolor='k', markersize=8, alpha=0.35),
    Line2D([0],[0], marker='o', color='w', label='low-acc slide patches',  markerfacecolor='k', markersize=8, alpha=0.15),
    Line2D([0],[0], marker='o', color='k', label='centroid (mean per slide)', markerfacecolor='w', markersize=8),
]
axes[1].legend(handles=legend_elems, loc="lower left", frameon=False)

# スライドIDのカラーバー（色=ID の凡例）
bounds = [1000, 1999, 2000, 2999]  # AIH帯, DILI帯
norm = Normalize(vmin=1000, vmax=2999)
sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm); sm.set_array([])
cbar = fig.colorbar(sm, ax=axes.ravel().tolist(), boundaries=bounds, ticks=[1500, 2500])
cbar.set_ticklabels(["AIH IDs<2000", "DILI IDs>2000"])
cbar.set_label("Slide ID")

#出力
out = Path("dr_all_out"); out.mkdir(exist_ok=True)
plt.savefig(out/"all_overlay_centroids.png", dpi=200)    
plt.show()