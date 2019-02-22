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
    split_array = re.split(" |\n", text)

    for element in split_array:
        if element.strip() == "":
            split_array.remove(element)
            
      
    capitalied_var_array = capitalizeVariables(split_array)
    
    for element in split_array:
        if element.strip() == "":
            split_array.remove(element)
       
    processedText = arrayToSentence(capitalied_var_array)
    

    return processedText

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
        returnString += str(word) + " "
    
    return returnString.strip()
        
    
       

if __name__ == "__main__":
    
    inputFilePath = ""
    
    if len(sys.argv) == 1:
        print("No input File Path Detected")
    
    if len(sys.argv) > 2:
        print("Too many argument inputs")
        
    if len(sys.argv) == 2:
        inputFilePath = sys.argv[1]
    
    print(inputFilePath)
    
    input_file_string = open(inputFilePath).read()
    print(input_file_string)
    print("****************")
    proccessedText = extract(input_file_string)
    print(proccessedText)

    

