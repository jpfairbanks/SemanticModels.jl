#
#
# Load models and predict - then rep as t-SNE
#
#

from matplotlib import colors as mcolors
from matplotlib import pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from sklearn.metrics import silhouette_score, silhouette_samples
from sklearn.metrics import adjusted_rand_score, adjusted_mutual_info_score, calinski_harabaz_score
import sklearn.cluster as cluster
from umap import UMAP

import numpy as np
import pandas as pd

encoded_reps = pd.read_csv("encoded_reps.csv")

with open("all_funcs.csv", "r") as f: 
    funcs = f.read()

funcs = funcs.split(".jl\n")
funcs = funcs[:-1] # remove trailing empty item
funcs = pd.DataFrame([x.rsplit("\t",1) for x in funcs])
funcs.columns = ['code','source']
funcs = funcs[funcs.code.apply(lambda x: len(x)<=500)]
funcs.reset_index(drop=True, inplace=True)

funcs.source = funcs.source.apply(lambda x: x[x.index("julia/")+6:])
funcs["top_folder"] = funcs.source.apply(lambda x: x[:x.index("/")])
funcs['top2'] = funcs.source.apply(lambda x: '_'.join(x.split("/")[:2]))

#
# Visualize tests. Here we limit our test to the "base" top-level folder, 
# and label our cases by their second-level folder/file. We further limit 
# our test cases to those labels with at least 100 examples for better 
# visualization. 
# 

X_test = encoded_reps[funcs.top_folder=="base"]
Y_test = funcs.top2[funcs.top_folder=="base"]
code_test = funcs.code[funcs.top_folder=="base"]
top_cats = list(Y_test.value_counts()[Y_test.value_counts()>=100].index)

X_test = X_test[Y_test.apply(lambda x: x in top_cats)]
code_test = code_test[Y_test.apply(lambda x: x in top_cats)]
Y_test = Y_test[Y_test.apply(lambda x: x in top_cats)]

reducer = UMAP(random_state=42, metric='cosine', n_neighbors=30, n_components=2)
embedding = reducer.fit_transform(X_test)

reducer_3d = UMAP(random_state=42, metric='cosine', n_neighbors=30, n_components=3)
embedding_3d = reducer_3d.fit_transform(X_test)

sils = silhouette_samples(X_test, Y_test, metric='cosine')
clusts = pd.concat([X_test.reset_index(drop=True), Y_test.reset_index(drop=True), pd.Series(sils)], axis=1, ignore_index=True)
centroids = clusts.groupby(64).agg('mean').sort_values(65)

src = list(centroids.index)

colors = dict(mcolors.BASE_COLORS, **mcolors.CSS4_COLORS)
by_hsv = sorted((tuple(mcolors.rgb_to_hsv(mcolors.to_rgba(color)[:3])), name)
                for name, color in colors.items())
sorted_names = [name for hsv, name in by_hsv]

NUM_COLORS = len(src)
my_cols = [sorted_names[i] for i in range(0,len(sorted_names), int(np.floor(len(sorted_names)/NUM_COLORS)))]



fig, ax = plt.subplots(figsize=(12, 10))
for i, s in enumerate(src):
    ax.scatter(embedding[Y_test==s, 0], 
                embedding[Y_test==s, 1], 
                c=my_cols[i], 
                linewidths=0.1,
                edgecolors='k',
                label=s)
plt.setp(ax, xticks=[], yticks=[]) 
plt.title("Julia source code data embedded into two dimensions by UMAP", fontsize=18) 
plt.legend(loc="upper left", bbox_to_anchor=(1,1))
plt.subplots_adjust(right=0.75)
plt.show()

#
# 3d Plot
# 

fig, ax = plt.subplots(figsize=(12, 10))
ax2 = fig.add_subplot(111, projection="3d")
for i, s in enumerate(src):
    ax2.scatter(embedding_3d[Y_test==s, 0], 
                embedding_3d[Y_test==s, 1], 
                embedding_3d[Y_test==s, 2], 
                c=my_cols[i], 
                linewidths=0.1,
                edgecolors='k',
                label=s)
plt.setp(ax2, xticks=[], yticks=[]) 
plt.title("Julia source code data embedded into two dimensions by UMAP", fontsize=18) 
plt.legend(loc="upper left", bbox_to_anchor=(1,1))
plt.subplots_adjust(right=0.75)
plt.show()

for i in range(2, 50):
    k_clusts = cluster.KMeans(n_clusters=i).fit_predict(embedding)
    print("{} clusts, score: {}".format(i, calinski_harabaz_score(embedding, k_clusts)))

# We see a sligth elbow in the graph at 45 clusters, about what we would expect visually
kmeans_labels = cluster.KMeans(n_clusters=45).fit_predict(embedding)
k_cols = [sorted_names[i] for i in range(0,len(sorted_names), int(np.floor(len(sorted_names)/45)))]

fig, ax = plt.subplots(figsize=(12, 10))
for i, s in enumerate(np.unique(kmeans_labels)):
    ax.scatter(embedding[kmeans_labels==s, 0], 
                embedding[kmeans_labels==s, 1], 
                c=k_cols[i], 
                linewidths=0.1,
                edgecolors='k',
                label=s)
    ax.annotate(s, 
                np.mean(embedding[kmeans_labels==s,:], axis=0),
                horizontalalignment='center',
                verticalalignment='center',
                size=12, weight='bold',
                color='k') 
plt.setp(ax, xticks=[], yticks=[]) 
plt.title("Julia source code data embedded into two dimensions by UMAP", fontsize=18) 
plt.legend(loc="upper left", bbox_to_anchor=(1,1), ncol=2)
plt.subplots_adjust(right=0.75)
plt.show()


for val in np.unique(kmeans_labels):
    print("Cluster {}:".format(val))
    [print(x) for x in code_test[kmeans_labels==val].sample(5)]

silhouette_score(X_test, Y_test, metric='cosine')
sils = silhouette_samples(X_test, Y_test, metric='cosine')
sils2 = silhouette_samples(embedding, Y_test, metric='cosine')
clusts = pd.concat([X_test.reset_index(drop=True), Y_test.reset_index(drop=True), pd.Series(sils)], axis=1, ignore_index=True)
clusts2 = pd.concat([X_test.reset_index(drop=True), Y_test.reset_index(drop=True), pd.Series(sils2)], axis=1, ignore_index=True)
centroids = clusts.groupby(64).agg('mean').sort_values(65)
centroids2 = clusts2.groupby(64).agg('mean').sort_values(65)


for i, group in enumerate(src):
    plt.plot(clusts2[65][clusts2[64]==group].sort_values(ascending=False).reset_index(drop=True), c=my_cols[i], label=group)

plt.title("Plot of Silhouette Scores for Cases in Test Groups")
plt.legend(loc="upper left", bbox_to_anchor=(1,1))
plt.subplots_adjust(right=0.7)
plt.show()
