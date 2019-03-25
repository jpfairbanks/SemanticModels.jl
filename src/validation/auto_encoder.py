
from keras.callbacks import EarlyStopping
from keras.layers import Input, LSTM, RepeatVector, Activation, CuDNNLSTM
from keras.models import Model
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from keras.utils import to_categorical
from sklearn.model_selection import train_test_split

import numpy as np
import pandas as pd

#
# one-hot encode text
#

with open("all_funcs.csv", "r") as f: 
    funcs = f.read()

funcs = funcs.split(".jl\n")
funcs = funcs[:-1] # remove trailing empty item
fdf = pd.DataFrame([x.rsplit("\t",1) for x in funcs], columns=["code", "path"])
fdf

fdf = fdf[fdf.code.apply(lambda x: len(x)<=500)]

def chars_to_indices(data, tok=None, max_len=None):
    if max_len is None:
        max_len = max(data.apply(lambda x: len(x)))+1

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

def get_cl_embedding_layer(tok, input_shape):
    vocab_size = len(tok.word_index)

    embedding_weights = []
    embedding_weights.append(np.zeros(vocab_size))

    for _, i in tok.word_index.items():
        o_i = np.zeros(vocab_size)
        o_i[i - 1] = 1
        embedding_weights.append(o_i)

    embedding_weights = np.array(embedding_weights)
    # embedding_layer = Embedding(vocab_size + 1,
    #                             vocab_size,
    #                             input_length=input_shape,
    #                             weights=[embedding_weights])

    return embedding_layer


def ae_models(maxlen, latent_dim, N, use_gpu=False):

    inputs = Input((latent_dim,maxlen,N))

    if use_gpu:
        encoded = CuDNNLSTM(latent_dim)(inputs)
    else:
        encoded = LSTM(latent_dim)(inputs)

    decoded = RepeatVector(maxlen)(encoded)

    if use_gpu:
        decoded = CuDNNLSTM(N, return_sequences=True)(decoded)
    else:
        decoded = LSTM(N, return_sequences=True)(decoded)

    sequence_autoencoder = Model(inputs=inputs, outputs=decoded)
    encoder = Model(inputs, encoded)
    #decoder = Model(encoded, decoded)

    return sequence_autoencoder, encoder #, decoder


# funcs = pd.read_csv("/u1/all_funcs.csv").iloc[:,0]
funcs = fdf
seqs, tok = chars_to_indices(funcs.iloc[:,0])
N = len(np.unique(seqs))

max_len = seqs.shape[1]

X_train, X_test = train_test_split(seqs, test_size=1/4)
X_train = to_categorical(X_train, N, dtype='int16')
X_test = to_categorical(X_test, N, dtype='int16')
X_test

autoencoder, enc = ae_models(max_len, 64, N, use_gpu=False)
autoencoder.compile(loss='mse',
                    optimizer='adam',
                    metrics=['accuracy'])

early_stop = EarlyStopping(monitor='val_acc',
                          min_delta=0.0001,
                          patience=10,
                          verbose=1,
                          mode='auto',
                          restore_best_weights=True)

autoencoder.fit(X_train,
                X_train,
                epochs = 100,
                batch_size = 32,
                validation_data=(X_test, X_test),
                callbacks=[early_stop],
                shuffle=True)


