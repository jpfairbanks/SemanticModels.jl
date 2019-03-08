#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar  8 10:30:31 2019

@author: kuncao
"""

import os
import sys
import logging
import spacy

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

SVO_OUTPUT_PATH = os.path.join("svoOutput", "svo.csv")
SIMILARITY_OUTPUT_FILE = os.path.join("svoOutput", "sim_file.csv")
    
    
def createPairsSet(nodeList):
    
    #Use Spacy Model
    nlp = spacy.load('en_core_web_md')
    tokens = []
    

    #Create Tokens
    for vertex in nodeList:
        token = nlp(vertex)
        tokens.append(token)
        
    #Initialize Similarity Matrix    
    sim_matrix = np.zeros((len(tokens), len(tokens)))
    
    for i in range(len(tokens)):
        for j in range(len(tokens)):
           #If comparing the same vertex, ignore and set relation to 0
           if (i == j):
               sim_matrix[i,j] = 0
           else:
               sim_matrix[i,j] = tokens[i].similarity(tokens[j])
               
          
    #Create Histogram
    data = sim_matrix.flatten()
    bin_num = 50
    plt.hist(data, bin_num)
    plt.show()

    threshold = .85
    pairsSet = set()


    #Create a pairs tuple of indices that satisfy threshold
    for i in range(len(tokens)):
        for j in range(len(tokens)):
            #Ignore if the reflective index is already contained
            if sim_matrix[i,j] > threshold and (j,i) not in pairsSet and sim_matrix[i,j] != 1:
                pairsSet.add((i,j))
                
    return pairsSet, sim_matrix
                
def buildOutputFile(subjectPairs, objectPairs, subjSimMatrix, objSimMatrix, csv):
    file_string = ""
    for index1, index2 in subjectPairs:
        file_string += (str(csv["subject"][index1]) + "," + str(csv["subject"][index2]) + "," +  str(subjSimMatrix[index1, index2]) +  "\n")

    for index1, index2 in objectPairs:
        file_string += (str(csv["object"][index1]) + "," + str(csv["object"][index2]) + "," +  str(objSimMatrix[index1, index2]) +  "\n")
    
    with open(SIMILARITY_OUTPUT_FILE, 'w') as filetowrite:
        filetowrite.write(file_string)
        filetowrite.close()
            

    
    
    
if __name__ == "__main__":
    #Read in CSV of svo 
    csv = pd.read_csv(SVO_OUTPUT_PATH)
    subjectPairs, subjSimMatrix = createPairsSet(list(csv["subject"]))
    objectPairs, objSimMatrix = createPairsSet(list(csv["object"]))
    
    buildOutputFile(subjectPairs, objectPairs, subjSimMatrix, objSimMatrix, csv)
    
    
    


    



