#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 20 09:39:59 2019

@author: kuncao
"""
import re
import sys



def extract(text):
    text = removeIntro(text)
    text = removeEquations(text)
    text = removeStarHeaders(text)
    text = removeNumerics(text)
       
    split_array = re.split(" |\n", text)

    capitalied_var_array = capitalizeVariables(split_array)      
    processedText = arrayToSentence(capitalied_var_array)
            

    return processedText

def removeNumerics(text):
    removedNumerText = re.sub(r'[0-9]+','',text)
    return removedNumerText

def removeStarHeaders(text):
    removedIntroText = re.sub('\*((.|\n)*)\*', '', text)
    return removedIntroText
    

def removeIntro(text):
    removedIntroText = re.sub('\-\-\-((.|\n)*)\-\-\-', '', text)
    return removedIntroText

def removeEquations(text):
    removedEquationText = re.sub('\$\$((.|\n)*)\$\$', '', text)
    return removedEquationText

    
def capitalizeVariables(split_array):
    pattern = re.compile("\$\\\(.+)+\$")
    caps = False
    for i in range (len(split_array)):
        split_array[i] = split_array[i].strip()
        
        
        if pattern.match(split_array[i]) is not None:
            caps = True
            
        split_array[i] = re.sub('\W', '', split_array[i])
        if caps == True:
            split_array[i] = split_array[i].capitalize()
            caps = False
    
    return split_array

def arrayToSentence(word_array):
    returnString = ""
    for word in word_array:
        if word != "":
            returnString += str(word) + " "
    
    return returnString.strip()
        
    
       

if __name__ == "__main__":
    
    inputFilePath = ""
    
    if len(sys.argv) < 3:
        print("<source file path> <output file path>")
    
    if len(sys.argv) > 3:
        print("Too many argument inputs")
        
    if len(sys.argv) == 3:
        inputFilePath = sys.argv[1]
        outputFilePath = sys.argv[2]
    
    input_file_string = open(inputFilePath).read()

    proccessedText = extract(input_file_string)
    
    with open(outputFilePath, 'w') as filetowrite:
        filetowrite.write(proccessedText)
        filetowrite.close()
        
    print(outputFilePath + " file created")


    

