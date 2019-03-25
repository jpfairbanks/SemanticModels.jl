#
#
# Load models and predict - then rep as t-SNE
#
#

from keras.models import Model, load_model
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from keras.utils import to_categorical
from matplotlib import colors as mcolors
from matplotlib import pyplot as plt
from sklearn.manifold import TSNE

import numpy as np
import pandas as pd

max_len = 500

with open("all_funcs.csv", "r") as f: 
    funcs = f.read()

funcs = funcs.split(".jl\n")
funcs = funcs[:-1] # remove trailing empty item
funcs = pd.DataFrame([x.rsplit("\t",1) for x in funcs])
funcs.columns = ['code','source']
funcs = funcs[funcs.code.apply(lambda x: len(x)<=max_len)]

funcs["top_folder"] = funcs.source.apply(lambda x: x[:x.index("/")])
funcs['top2'] = funcs.source.apply(lambda x: '_'.join(x.split("/")[:2]))

enc = load_model("encoder.h5")

def chars_to_indices(data, tok=None, max_len=None):
    if max_len is None:
        max_len = max(data.apply(lambda x: len(x)))+1
    else:
    	max_len = max_len+1

    if tok is None:
        tok = Tokenizer(num_words=None, 
                        filters="", 
                        lower=False, 
                        split='', 
                        char_level=True)

    data = data.values
    tok.fit_on_texts(data)
    sequences = tok.texts_to_sequences(data)
    sequences = pad_sequences(sequences, maxlen=max_len, padding='post')
    sequences = np.array(sequences, dtype='int16')

    return sequences, tok

seqs, tok = chars_to_indices(funcs.iloc[:,0], None, max_len)
N = len(np.unique(seqs))

chunk_size = 1000

encoded_reps = pd.DataFrame()

for i in range(0,seqs.shape[0], chunk_size):
	chunk = seqs[i:i+chunk_size,:]
	one_hot_mat = to_categorical(chunk, N, dtype='int16')
	result = enc.predict(one_hot_mat)
	encoded_reps = pd.concat([encoded_reps, pd.DataFrame(result)])
	print(i)

#
# Visualize tests. Here we limit our test to the "base" top-level folder, 
# and label our cases by their second-level folder/file. We further limit 
# our test cases to those labels with at least 100 examples for better 
# visualization. 
# 

X = encoded_reps.reset_index(drop=True)
X_test = X[funcs.reset_index(drop=True).top_folder=="base"]
Y = funcs.top2.reset_index(drop=True)
Y_test = Y[funcs.reset_index(drop=True).top_folder=="base"]
top_cats = list(Y_test.value_counts()[Y_test.value_counts()>=100].index)

X_test = X_test[Y_test.apply(lambda x: x in top_cats)]
Y_test = Y_test[Y_test.apply(lambda x: x in top_cats)]

tsne = TSNE(n_components=2, random_state=0, metric='cosine', verbose=1, init='pca')

X_2d = tsne.fit_transform(X_test)

sources = Y_test.drop_duplicates()

colors = dict(mcolors.BASE_COLORS, **mcolors.CSS4_COLORS)
by_hsv = sorted((tuple(mcolors.rgb_to_hsv(mcolors.to_rgba(color)[:3])), name)
                for name, color in colors.items())
sorted_names = [name for hsv, name in by_hsv]

NUM_COLORS = len(sources)
my_cols = [sorted_names[i] for i in range(0,len(sorted_names), math.floor(len(sorted_names)/NUM_COLORS))]

plt.figure(figsize=(6, 5))
for i, s in enumerate(sources):
    plt.scatter(X_2d[Y_test == s, 0], X_2d[Y_test == s, 1], c=my_cols[i], label=s)
plt.legend()
plt.show()



















