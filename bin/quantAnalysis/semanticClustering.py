#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Mar 13 10:04:05 2019

@author: kuncao
"""


import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import umap
import sklearn.cluster as cluster
from sklearn.cluster import DBSCAN
import spacy



def createWord2Vec(data):
    

        
    
    nlp = spacy.load('en_core_web_md')   
    tokenList = []   
    for phrase in data:
        token = nlp(phrase)
        tokenList.append(token.vector)
        
    return np.asarray(tokenList)
    
    

    
    

    
def useUMAP(tokenList):

    db = DBSCAN(eps=0.3, min_samples=2).fit(np.asarray(tokenList))
    standard_embedding = umap.UMAP(random_state=42).fit_transform(np.asarray(tokenList))
    
    db_umap = DBSCAN(eps=0.3, min_samples=2).fit(np.asarray(standard_embedding))

# =============================================================================
#     plt.scatter(standard_embedding[:, 0], standard_embedding[:, 1], c=db.labels_, s=0.1, cmap='Spectral');
# =============================================================================
    
    return np.asarray(db.labels_), np.asarray(db_umap.labels_)

        

def writeCSV(subj_array, labels, umapLables, labelsSimArray, \
             uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray):
    print("Writing CSV")
        
    outputString = "node,labels,umapLables,dbscanSim,UMAPsim,out_sampleDBSCAN,out_sampleUMAP\n"
    for i in range(len(labels)):
        outputString += str(subj_array[i]) + ","\
        + str(labels[i]) + ","\
        +str(umapLables[i]) + ","\
        + str(labelsSimArray[i]) + ","\
        + str(uMapLabelsSimArray[i])+ ","\
        + str(OutSampleLabelsSimArray[i]) + ","\
        + str(OutSampleUMAPSimArray[i]) + "\n"
        
    
    with open("clusteringLabels.csv", 'w') as filetowrite:
        filetowrite.write(outputString)
        filetowrite.close()
        
        
def generatePairs(labels, umapLabels, data):

    nlp = spacy.load('en_core_web_md')  
    labelsSimArray = []
    uMapLabelsSimArray = []
    OutSampleLabelsSimArray = []
    OutSampleUMAPSimArray = []
    
    labels_sim = 0;
    umapLabels_sim = 0;
    outsample_labels_sim = 0;
    outsample_umap_sim = 0;
    for i in range(len(data)):
        print("Iterating Word " + str(i))
        for j in range(len(data)):
            if i != j:
                
# =============================================================================
#                 print("*************Comparing***********")
#                 print(data[i])
#                 print(data[j])
# =============================================================================

                token1 = nlp(data[i])
                token2 = nlp(data[j])
# =============================================================================
#                 
#                 print(token1.similarity(token2))
# =============================================================================
                if(labels[i] == labels[j]):
                    labels_sim += token1.similarity(token2)
                
                if(umapLabels[i] == umapLabels[j]):
                    umapLabels_sim += token1.similarity(token2)
                    
                if(labels [i] != labels[j]):
                    outsample_labels_sim += token1.similarity(token2)
                    
                if(umapLabels[i] != umapLabels[j]):
                    outsample_umap_sim += token1.similarity(token2)
            
            if j == len(data)-1:
                
                labelsSimArray.append(float(labels_sim/(list(labels).count(labels[i])-1)))
                uMapLabelsSimArray.append(float(umapLabels_sim/(list(umapLabels).count(umapLabels[i])-1)))
                
                
                if len(labels)-list(labels).count(labels[i]) == 0:
                    OutSampleLabelsSimArray.append(1)
                else:
                    OutSampleLabelsSimArray.append(float(outsample_labels_sim/(len(labels)-1-list(labels).count(labels[i]))))
                                
                if len(umapLabels)-list(umapLabels).count(umapLabels[i]) == 0:
                    OutSampleUMAPSimArray.append(1)
                else:
                    OutSampleUMAPSimArray.append(float(outsample_umap_sim/(len(umapLabels)-1-list(umapLabels).count(umapLabels[i]))))
                
                labels_sim = 0;
                umapLabels_sim = 0;
                outsample_labels_sim = 0;
                outsample_umap_sim = 0;
        
    
    return labelsSimArray, uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray
                
                    
                
    
                

if __name__ == "__main__":
    data = pd.read_csv("../sovExtraction/svoOutput/svo.csv")
    subj_array = list(data["subject"])   
    obj_array = list(data["object"])
    tokenList = createWord2Vec(obj_array)
    labels,umapLabels = useUMAP(tokenList)
    labelsSimArray, uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray = \
        generatePairs(labels, umapLabels, obj_array)
    
    
    writeCSV(obj_array, labels, umapLabels, labelsSimArray, uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray )
