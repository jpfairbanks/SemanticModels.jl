

import pandas as pd
from random import shuffle

import spacy



def createPairs(data):
    pairs_set= set()
    
    subj_array = list(data["subject"])
    totalPairs = []
    
    for i in range(len(subj_array)):
        for j in range(len(subj_array)):
            if(i != j and subj_array[i] != subj_array[j] and (subj_array[i],subj_array[j]) not in pairs_set) \
                and (subj_array[j],subj_array[i]) not in pairs_set:     
                pairs_set.add((subj_array[i],subj_array[j]))
                totalPairs.append((subj_array[i],subj_array[j]))
                
    
    obj_array = list(data["object"])
    
    for i in range(len(obj_array)):
        for j in range(len(obj_array)):
            if(i != j and obj_array[i] != obj_array[j] and (obj_array[i],obj_array[j]) not in pairs_set) \
                and (obj_array[j],obj_array[i]) not in pairs_set:     
                pairs_set.add((obj_array[i],obj_array[j]))
                totalPairs.append((obj_array[i],obj_array[j]))
    
    writeCSV(totalPairs)
    
    
def writeCSV(pairs):
    
    nlp = spacy.load('en_core_web_md')
    

    outputString = ""
    
    shuffle(pairs)
    for phrase1, phrase2 in pairs:
        
        token1 = nlp(phrase1)
        token2 = nlp(phrase2)
        outputString += phrase1.strip() + "," + phrase2.strip() + "," + str(token1.similarity(token2)) + "\n"
        
    
    
    
    with open("vertexPairs.csv", 'w') as filetowrite:
        filetowrite.write(outputString)
        filetowrite.close()
                

if __name__ == "__main__":
    data = pd.read_csv("../sovExtraction/svoOutput/svo.csv")
    
    createPairs(data)
