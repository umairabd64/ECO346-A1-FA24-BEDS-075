"""04_scatter_python.py -- Question 5: band table and scatter figure in Python.
Run from the repository root:  python scripts/04_scatter_python.py
Needs pandas, numpy, matplotlib."""
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter, FixedLocator, NullLocator

person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv")[["hhid", "hhweight", "prov_code", "urban_rural"]]
d = person.merge(hh, on="hhid", how="left")

# variant 3 = Sindh (3), urban (2); earners aged 15-64 with earnings > 0
e = d[(d.prov_code == 3) & (d.urban_rural == 2) &
      (d.age >= 15) & (d.age <= 64) & (d.earn_annual > 0)].copy()

# five-year bands [15,20), [20,25), ... -- right=False matches the R script
edges = list(range(15, 70, 5))
labels = [f"{a}-{a + 4}" for a in range(15, 65, 5)]
e["band"] = pd.cut(e.age, bins=edges, right=False, labels=labels)

def band_stats(g):
    return pd.Series({"n": len(g),
                      "mean_earn": (g.hhweight * g.earn_annual).sum() / g.hhweight.sum()})

bands = e.groupby("band", observed=True).apply(band_stats).reset_index()
bands["n"] = bands["n"].astype(int)
# nearest whole rupee (half rounded up, like the assignment's "nearest rupee")
bands["mean_earn"] = np.floor(bands["mean_earn"] + 0.5).astype(int)
bands["mid"] = [a + 2 for a in range(15, 65, 5)]
bands["thin"] = bands["n"] < 30

os.makedirs("figures", exist_ok=True)
bands[["band", "n", "mean_earn"]].to_csv("figures/band_table_python.csv", index=False)

# check against the R table, rupee by rupee
if os.path.exists("figures/band_table_R.csv"):
    r = pd.read_csv("figures/band_table_R.csv")
    same = (r["band"].astype(str).tolist() == bands["band"].astype(str).tolist()
            and (r["n"].values == bands["n"].values).all()
            and (r["mean_earn"].values == bands["mean_earn"].values).all())
    print("Band tables identical to R:", same)

# figure -------------------------------------------------------------
rng = np.random.default_rng(346)
x = e.age.values + rng.uniform(-0.4, 0.4, len(e))      # matplotlib has no jitter: add it by hand
fig, ax = plt.subplots(figsize=(9, 5.8))
ax.scatter(x, e.earn_annual, s=8, alpha=0.18, color="0.35", linewidths=0)
ax.plot(bands.mid, bands.mean_earn, color="#B22222", lw=2)
for _, row in bands.iterrows():                          # hollow markers for thin bands
    ax.scatter(row.mid, row.mean_earn, s=70, color="#B22222",
               facecolors="none" if row.thin else "#B22222", linewidths=1.6, zorder=3)

top = bands.loc[bands.mean_earn.idxmax()]
ax.annotate(f"Highest band mean: ages {top.band}\nRs {top.mean_earn:,}",
            xy=(top.mid - 0.7, top.mean_earn * 1.12), xytext=(top.mid - 6, top.mean_earn * 3),
            ha="right", color="#B22222", arrowprops=dict(arrowstyle="->", color="#B22222"))

ax.set_yscale("log")
ax.set_ylim(1e4, 1e7)
ax.set_xlim(14.5, 64.5)
ax.set_xticks(range(15, 65, 10))
ax.yaxis.set_major_locator(FixedLocator([1e4, 1e5, 1e6, 1e7]))
ax.yaxis.set_minor_locator(NullLocator())
ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"Rs {int(v):,}"))
ax.set_xlabel("Age (years)")
ax.set_ylabel("Annual earnings (rupees, log scale)")
ax.set_title(f"In urban Sindh, average earnings climb with age and peak at ages {top.band}",
             loc="left", fontweight="bold", fontsize=12)
for s in ("top", "right", "left", "bottom"):
    ax.spines[s].set_visible(False)
ax.grid(color="0.92")
n_out = int(((e.earn_annual < 1e4) | (e.earn_annual > 1e7)).sum())
fig.text(0.01, 0.01,
         f"Source: PSLM 2019-20 person and household files. Sample: {len(e):,} earners aged 15-64 "
         f"in urban Sindh with earnings > 0.\n{n_out} earners outside the Rs 10,000-10,000,000 axis "
         "are not shown. Grey dots: individual earners (jittered, semi-transparent).\n"
         "Red markers: weighted mean (hhweight) of each five-year band at its midpoint. "
         "Hollow markers: bands with fewer than 30 unweighted observations.",
         fontsize=7.5, color="0.3", va="bottom", ha="left")
fig.subplots_adjust(left=0.14, right=0.97, top=0.93, bottom=0.17)
plt.savefig("figures/scatter_python.svg")
print(bands[["band", "n", "mean_earn"]].to_string(index=False))
