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

import unicodedata



def createWord2Vec(data):
    
    
    nlp = spacy.load('en_core_web_md')   
    tokenList = []   
    for phrase in data:
        token = nlp(phrase)
        tokenList.append(token.vector)
        
    return np.asarray(tokenList)
    
    

    
    

    
def useUMAP(tokenList, variableTokenList):

    db = DBSCAN(eps=0.3, min_samples=2).fit(np.asarray(tokenList))
    
    umapModel = umap.UMAP(random_state=42).fit(np.asarray(tokenList))
    
    standardEmbedding = umapModel.transform(tokenList)
    variableEmbeddings = umapModel.transform(np.asarray(variableTokenList))
    


    
    db_umap = DBSCAN(eps=0.3, min_samples=2).fit(standardEmbedding)
    print(db_umap.labels_)
    predictedVariables = db_umap.fit_predict(variableEmbeddings)
    
    
    return np.asarray(db.labels_), np.asarray(db_umap.labels_), predictedVariables

def writePredictedCSV(variable_array, predictedLabels):
    print("generating CSV")
    outputString = "variable,predictedCluster\n"
    for i in range(len(variable_array)):
        outputString += str(variable_array[i]) + "," + str(predictedLabels[i]) + "\n"
    
    with open("variableNamePredictedCluster.csv", 'w') as filetowrite:
        filetowrite.write(outputString)
        filetowrite.close()
        
        
    

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

                token1 = nlp(data[i])
                token2 = nlp(data[j])
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
                
                    
def cleanVariables(variableArray):
    for i in range(len(variableArray)):

        variableArray[i] = variableArray[i].replace(",", " ")
        variableArray[i] = variableArray[i].replace("_", " ")
        variableArray[i] = containsGreek(variableArray[i])
        


    return variableArray

    
def containsGreek(inputString):
    greekLetters = []
    for s in inputString:
        name = unicodedata.name(chr(ord(s)))
        if "GREEK" in name:
            greekLetters.append(s)
    
    
    for letter in greekLetters:
        name = unicodedata.name(chr(ord(letter))).split(" ")[3]
        inputString = inputString.replace(letter, str(name) + str(" "))
    
    return inputString
        

            

if __name__ == "__main__":
    SVOdata = pd.read_csv("../sovExtraction/svoOutput/svo.csv")
    variableData = pd.read_csv("JuliaVariableData.csv")
    
    variable_array = list(variableData["variable"])
    subj_array = list(SVOdata["subject"])   
    obj_array = list(SVOdata["object"])
    
    variable_array = cleanVariables(variable_array)
# =============================================================================
#     print(variable_array)
# =============================================================================

    tokenList = createWord2Vec(obj_array)
    variableTokenList = createWord2Vec(variable_array)
    
    #Use UMAP Clustering
    labels,umapLabels, predictedVariables = useUMAP(tokenList, variableTokenList)
# =============================================================================
#     print(predictedVariables)
#     
#     print(obj_array)
#     print(umapLabels)
# =============================================================================
# =============================================================================
#     print(predictedLabels)
#     print(variable_array)
# =============================================================================
# =============================================================================
#     labelsSimArray, uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray = \
#         generatePairs(labels, umapLabels, obj_array)
# =============================================================================
        
    #Write Predicted Variable Names
    writePredictedCSV(variable_array, predictedVariables)
    

        
    
    
    
    
# =============================================================================
#     writeCSV(obj_array, labels, umapLabels, labelsSimArray, \
#              uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray )
# =============================================================================
        
        
