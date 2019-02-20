#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 20 09:39:59 2019

@author: kuncao
"""
import re

def extract(text):
    text = removeEquations(text)
    split_array = text.split(" ")
      
    capitalied_var_array = capitalizeVariables(split_array)
       
    processedText = arrayToSentence(capitalied_var_array)
    
    return processedText

def removeEquations(text):
    removedEquationText = re.sub('\${2}(.+)\${2}', '', text)
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
    temp_String = "Hello World"
