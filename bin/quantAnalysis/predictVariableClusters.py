#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 18 10:27:02 2019

@author: kuncao
"""

import unicodedata
from sklearn.cluster import KMeans
import spacy
import numpy as np
import pandas as pd
import umap



def createWord2Vec(data):
    
    
    nlp = spacy.load('en_core_web_md')   
    tokenList = []   
    for phrase in data:
        token = nlp(phrase)
        tokenList.append(token.vector)
        
    return np.asarray(tokenList)

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


def useKmeans(trainTokenList, K_size, variableTokenList):
    umapModel = umap.UMAP(random_state=42).fit(np.asarray(trainTokenList))
    trainEmbedding = umapModel.transform(trainTokenList)
    predictEmbedding = umapModel.transform(variableTokenList)
    
    
    kmeans = KMeans(n_clusters=K_size, random_state = 0).fit(trainEmbedding)
    
    
    return kmeans.labels_, kmeans.predict(predictEmbedding)
    
def writeCSV(variable_array, predictedLabels, fileName):
    print("generating CSV " + fileName)
    outputString = "variable,cluster\n"
    for i in range(len(variable_array)):
        outputString += str(variable_array[i].replace(",", " ")) + "," + str(predictedLabels[i]) + "\n"
    
    with open(fileName, 'w') as filetowrite:
        filetowrite.write(outputString)
        filetowrite.close()



    

def groupNodesByCluster(umapData):
    maxNoClusters = max(list(umapData["umapLabels"]))
    clusteredNodes = []
    
    for i in range(maxNoClusters):
        temp_bin = []
        for j in range(len(list(umapData["umapLabels"]))):
            if list(umapData["umapLabels"])[j] == i:
                temp_bin.append(list(umapData["node"])[j])
        clusteredNodes.append(temp_bin)
    
    return clusteredNodes

def getSimilarityLabels(clusteredNodes, variable_array):
    labels = []
    nlp = spacy.load('en_core_web_md')  
    
    for variable in variable_array:
        variableToken = nlp(variable)
        highest_average = -9000
        label = 0
        
        for clusterNo in range(len(clusteredNodes)):
            average = 0
            for node in clusteredNodes[clusterNo]:
                nodeToken = nlp(node)
                average += variableToken.similarity(nodeToken)
            average /= len(clusteredNodes[clusterNo])
            if average > highest_average:
                highest_average = average
                label = clusterNo
        
        labels.append(label)
    
    return labels
                
def runKMeansExp():
    variableData = pd.read_csv("data/JuliaVariableData.csv")
    umapData = pd.read_csv("data/clusteringLabels.csv")
    umapData = umapData[umapData.umapLabels != -1]

    kmeansTrainData = list(umapData["node"])
    variable_array = list(variableData["variable"])
    variable_array = cleanVariables(variable_array)
    
    variableTokenList = createWord2Vec(variable_array)
    trainTokenList = createWord2Vec(kmeansTrainData)
    K_size = max(list(umapData["umapLabels"]))

    
    trainLabels, predictedLabels = useKmeans(trainTokenList, K_size, variableTokenList)
    writeCSV(kmeansTrainData, trainLabels, "data/KmeansCluster.csv")
    writeCSV(variable_array, predictedLabels, "data/KmeansPredicted.csv")
    
                
        

def runUMapSimilarityExp():
    variableData = pd.read_csv("data/JuliaVariableData.csv")
    umapData = pd.read_csv("data/clusteringLabels.csv")
    umapData = umapData[umapData.umapLabels != -1]
    variable_array = list(variableData["variable"])
    variable_array = cleanVariables(variable_array)
    
    clusteredNodes = groupNodesByCluster(umapData)
    labels = getSimilarityLabels(clusteredNodes, variable_array)
    
    writeCSV(variable_array, labels, "data/simPredictedUmapClusters.csv")
    
    
    
if __name__ == "__main__":
    runKMeansExp()
# =============================================================================
#     runUMapSimilarityExp()
# =============================================================================

