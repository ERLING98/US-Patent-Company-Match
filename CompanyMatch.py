# 导入需要的库
import time

import numpy as np
import pandas as pd
import torch
from sentence_transformers.util import pytorch_cos_sim as cos_sim
from sentence_transformers import SentenceTransformer as SBert

# define model
model = SBert('paraphrase-MiniLM-L6-v2', device='cuda')

data_1 = pd.read_csv('patent_trade_dataset.csv')
data_2 = pd.read_csv('PERMNO_dt.csv')
data_1['ee_name'] = data_1['ee_name'].apply(str)
data_1['or_name'] = data_1['or_name'].apply(str)

ee_name = data_1['ee_name']
or_name = data_1['or_name']
nm = data_2['SecurityNm']
no = data_2['PERMNO']
ti = data_2['Ticker']
na = data_2['NAICS']

# Compute word embedding
print("start embedding")
embeddings1 = model.encode(ee_name, device='cuda')
print('finish ee_name embedding')

embeddings2 = model.encode(or_name, device='cuda')
print('finish or_name embedding')

embeddings3 = model.encode(nm, device='cuda', convert_to_tensor=True)
embeddings3 = embeddings3.to('cuda')
print('finish nm embedding')


result_ee = []
result_or = []

print('start cos-sim')
one_loop_rows = 10000
sim_thresholds = .85

print('will do {} loops'.format(len(embeddings1) // one_loop_rows + 1))

# aovid RAM outrage
for i in range(0, len(embeddings1), one_loop_rows):
    print('start epoch {}'.format(i // one_loop_rows + 1))
    start = time.time()

    emb1 = embeddings1[i:i + one_loop_rows]
    # use tensor to transfer to GPU
    emb1 = torch.tensor(emb1).to('cuda')

    cosine_scores = cos_sim(emb1, embeddings3).cpu()

    for j in cosine_scores:
        k = np.array(j)
        index = k.argmax()
        if k[index] > sim_thresholds:
            result_ee.append(index)
        else:
            result_ee.append(-1)

    emb2 = embeddings2[i:i + one_loop_rows]
    # use tensor to transfer to GPU
    emb2 = torch.tensor(emb2).to('cuda')
    cosine_scores = cos_sim(emb2, embeddings3).cpu()

    for j in cosine_scores:
        k = np.array(j)
        index = k.argmax()
        if k[index] > sim_thresholds:
            result_or.append(index)
        else:
            result_or.append(-1)
    end = time.time()
    print('finish epoch {} cost: {:.3f}s'.format(i // one_loop_rows + 1, end - start))

print('finish cos-sim')

print('start save files')


ee_snm = []
ee_no = []
ee_ticker = []
ee_nas = []


for i in result_ee:

    if i != -1:
        ee_snm.append(nm[i])
        ee_no.append(no[i])
        ee_ticker.append(ti[i])
        ee_nas.append(na[i])

    else:
        ee_snm.append(None)
        ee_no.append(None)
        ee_ticker.append(None)
        ee_nas.append(None)


data_1['ee_SecurityNm'] = ee_snm
data_1['ee_PERMNO'] = ee_no
data_1['ee_Ticker'] = ee_ticker
data_1['ee_NAICS'] = ee_nas

or_snm = []
or_no = []
or_ticker = []
or_nas = []

for i in result_or:
    if i != -1:
        or_snm.append(nm[i])
        or_no.append(no[i])
        or_ticker.append(ti[i])
        or_nas.append(na[i])
    else:
        or_snm.append(None)
        or_no.append(None)
        or_ticker.append(None)
        or_nas.append(None)

data_1['or_SecurityNm'] = or_snm
data_1['or_PERMNO'] = or_no
data_1['or_Ticker'] = or_ticker
data_1['or_NAICS'] = or_nas


data_1.to_csv('data_test.csv', index=False)
