import pandas as pd, numpy as np
import matplotlib.pyplot as plt
import matplotlib.patheffects as pe
from matplotlib import cm
from matplotlib.colors import Normalize
from pathlib import Path
from sklearn.decomposition import PCA
from sklearn.manifold import MDS

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

# 高精度の定義
high_acc = {1047, 1063, 2141, 2171, 1026, 2136, 1075, 2158, 1016, 2131, 2197}

# ---- 入力 ----
DF = pd.read_parquet("GAPlayer_merged.parquet")   # 全パッチ (1024次元＋メタ)

#DFのうちfで始まる列(GAP層ベクトルのデータ)のみを抽出
feat_cols = [c for c in DF.columns if c.startswith("f")]

DF = DF[DF["orig_id"].astype(int).isin(high_acc)]#high_accのみのパッチ

X_high = DF[feat_cols].values
id_high = DF["orig_id"].astype(int).values
lab_high= DF["Label"].values

#PCA
Xpca = PCA(n_components=10, random_state=0).fit_transform(X_high)

#MDS
mds = MDS(n_components=2, dissimilarity='euclidean', random_state=0, n_jobs=-1)
Xmds = mds.fit_transform(Xpca)  # high-accだけ使うなら

# ---- カラー: jet の前半(青系)=AIH, 後半(赤系)=DILI を均等割り当て ----
cmap = cm.get_cmap("jet")
uniq_id = np.unique(id_high)
aih_id  = sorted([sid for sid in uniq_id if sid < 2000])
dili_id = sorted([sid for sid in uniq_id if sid >= 2000])
aih_pos  = np.linspace(0.00, 0.38, len(aih_id))   # 青～シアン
dili_pos = np.linspace(0.62, 1.00, len(dili_id))  # 黄～赤
id2color = {}
for sid, pos in zip(aih_id, aih_pos):   id2color[sid]  = cmap(pos)
for sid, pos in zip(dili_id, dili_pos): id2color[sid]  = cmap(pos)

# プロット（high-acc パッチ + centroid）
fig, ax = plt.subplots(figsize=(7,6))
scatter_by_slide(ax, Xmds, id_high, lab_high, "MDS (high-acc patches)",id2color)

# スライド番号を重心付近に表示
for sid in high_acc:
    sel = (id_high == sid)
    if np.any(sel):
        cx, cy = Xmds[sel].mean(axis=0)
        ax.text(cx, cy, str(sid), fontsize=9, weight="bold",ha="center", va="center", 
        color="k", path_effects=[pe.withStroke(linewidth=2, foreground="w")])

# スライドIDのカラーバー（色=ID の凡例）
bounds = [1000, 1999, 2000, 2999]  # AIH帯, DILI帯
norm = Normalize(vmin=1000, vmax=2999)
sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm); sm.set_array([])
cbar = fig.colorbar(sm, ax=[ax], boundaries=bounds, ticks=[1500, 2500])
cbar.set_ticklabels(["AIH IDs<2000", "DILI IDs>2000"])
cbar.set_label("Slide ID")

out = Path("dr_all_out"); out.mkdir(exist_ok=True)
plt.savefig(out/"MDS_high.png", dpi=200)
plt.show()