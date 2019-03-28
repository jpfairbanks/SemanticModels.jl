
from keras import regularizers
from keras.callbacks import EarlyStopping
from keras.layers import Input, GRU, RepeatVector, Activation, CuDNNGRU
from keras.layers import Dense, BatchNormalization, Embedding
from keras.models import Model
from keras.optimizers import Adam
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences

from keras.utils import to_categorical
from sklearn.model_selection import train_test_split

import numpy as np
import pandas as pd

latent_dim = 64
max_len = 500

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

def chars_to_indices(data, tok=None, max_len=None):
    if max_len is None:
        max_len = max(data.apply(lambda x: len(x)))

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

def ae_models(maxlen, latent_dim, N, use_gpu=False):
    inputs = Input((maxlen,), name='Encoder_Inputs')
    encoded = Embedding(N, latent_dim, name='Char_Embedding', mask_zero=False)(inputs)
    encoded = BatchNormalization(name='BatchNorm_Encoder')(encoded)

    if use_gpu:
        _, state_h = CuDNNGRU(latent_dim, return_state=True)(encoded)
    else:
        _, state_h = GRU(latent_dim, return_state=True)(encoded)

    enc = Model(inputs=inputs, outputs=state_h, name='Encoder_Model')
    enc_out = enc(inputs)

    dec_inputs = Input(shape=(None,), name='Decoder_Inputs')
    decoded = Embedding(N, latent_dim, name='Decoder_Embedding', mask_zero=False)(dec_inputs)
    decoded = BatchNormalization(name='BatchNorm_Decoder_1')(decoded)

    if use_gpu:
        dec_out, _ = CuDNNGRU(latent_dim, return_state=True, return_sequences=True)(decoded, initial_state=enc_out)
    else:
        dec_out, _ = GRU(latent_dim, return_state=True, return_sequences=True)(decoded, initial_state=enc_out)

    dec_out = BatchNormalization(name='BatchNorm_Decoder_2')(dec_out)
    dec_out = Dense(N, activation='softmax', name='Final_Out')(dec_out)

    sequence_autoencoder = Model(inputs=[inputs, dec_inputs], outputs=dec_out)

    return sequence_autoencoder, enc

seqs, tok = chars_to_indices(funcs.iloc[:,0])
N = len(np.unique(seqs))

decoder_inputs = seqs[:,  :-1]
Y = seqs[:, 1:  ]

# 
# When improvements in training initially level out, reduce the learning rate
# to 0.0001 and re-compile the model. 
# 

autoencoder, enc = ae_models(max_len, 64, N, use_gpu=True)

opt = Adam(lr=0.001, amsgrad=True)

autoencoder.compile(loss='sparse_categorical_crossentropy',
                    optimizer=opt,
                    metrics=['accuracy'])

early_stop = EarlyStopping(monitor='val_acc',
                          min_delta=0.0001,
                          patience=10,
                          verbose=1,
                          mode='auto',
                          restore_best_weights=True)

autoencoder.fit([seqs, decoder_inputs],
                np.expand_dims(Y, -1),
                epochs = 100,
                batch_size = 32,
                validation_split=0.12,
                callbacks=[early_stop],
                shuffle=True)

autoencoder.save("autoencoder.h5")
enc.save("encoder.h5")

np.savetxt("seqs.csv", seqs, delimiter=",")
encoded_reps = pd.DataFrame(enc.predict(seqs))
encoded_reps.to_csv("encoded_reps.csv", index=False)
