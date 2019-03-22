#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Mar 21 23:01:25 2019

@author: kuncao
"""
import pandas as pd
import numpy as np
import logging
logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)
logging.getLogger().setLevel(logging.INFO)


def groupNodesByCluster(umapData):
    maxNoClusters = max(list(umapData["umapLabels"]))
    clusteredNodes = []
    clusteredRatios = []
    
    for i in range(maxNoClusters + 1):
        temp_bin = []
        ratio_bin = []
        for j in range(len(list(umapData["umapLabels"]))):
            if list(umapData["umapLabels"])[j] == i:
                temp_bin.append(list(umapData["node"])[j])
                ratio_bin.append(list(umapData["UMAPsim"])[j])
        clusteredNodes.append(temp_bin)
        clusteredRatios.append(ratio_bin)
        
    
    return clusteredNodes, clusteredRatios

def determineMerge(clusteredRatios, threshold):
    indexList = []
    index = 0
    for numList in clusteredRatios:
        if np.average(np.asarray(numList)) >= threshold:
            indexList.append(index)
        
        index += 1
    
    return indexList

def determineCenterNode(indices, clusteredNodes, clusteredRatios):
    centerNodes = []
    for index in indices:
        highestRatio = -100
        nodeTemp = ""
        for i in range(len(clusteredNodes[index])):

            if clusteredRatios[index][i] > highestRatio:
                highestRatio = clusteredRatios[index][i]
                nodeTemp = clusteredNodes[index][i]
        
        centerNodes.append(nodeTemp)
    
    return centerNodes
        
        
        
def createNodeMap(centerNodes, clusteredNodes, indices):
    assignmentMap = dict()    
    for i in range(len(indices)):

        for word in clusteredNodes[indices[i]]:
            assignmentMap[word] = centerNodes[i]
    
    return assignmentMap

def mergeNodes(assignmentMap):
    svoData = pd.read_csv("svo.csv")
    
    for index, values in svoData.iterrows():
        if values["subject"] in assignmentMap:
            svoData.at[index,'subject'] = assignmentMap[values["subject"]]
        elif values["object"] in assignmentMap:
            svoData.at[index,'object'] = assignmentMap[values["object"]]
    
    return svoData
    
def addVariableEdges(newSvoDataFrame, averageSimArray, threshold, assignmentMap, allCenterNodes):
    kMeansPredictedData = pd.read_csv("ExperimentData/KMeansPredicted.csv")
    variables = list(kMeansPredictedData["variable"])
    clusters = list(kMeansPredictedData["cluster"])
    
    count = newSvoDataFrame.shape[0] + 1
    for i in range(len(variables)):
        if averageSimArray[i] > threshold:
            newSvoDataFrame.loc[count] = [variables[i], "implements", allCenterNodes[clusters[i]]]
            count += 1   
    newSvoDataFrame.to_csv("mergedSVO.csv")
    logging.info("mergedSVO.csv Created")
            
            
        
    
    
def createFinalGraph(ClusterThreshold, VariableThreshold, averageSimArray):
    data = pd.read_csv("clusteringLabels.csv")

    
    clusteredNodes, clusteredRatios = groupNodesByCluster(data)
    indices = determineMerge(clusteredRatios, ClusterThreshold)
    centerNodes = determineCenterNode(indices, clusteredNodes, clusteredRatios)
    assignmentMap = createNodeMap(centerNodes, clusteredNodes, indices)
    newSvoDataFrame = mergeNodes(assignmentMap)
    
    indices = list(range(0, max(list(data["umapLabels"]))+1))
    allCenterNodes = determineCenterNode(indices, clusteredNodes, clusteredRatios)
    addVariableEdges(newSvoDataFrame, averageSimArray, VariableThreshold, assignmentMap, allCenterNodes)

    