#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 20 09:39:59 2019

@author: kuncao
"""
import re
import sys
import logging
logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)
logging.getLogger().setLevel(logging.INFO)


def extract(text):
    text = removeIntro(text)

    text = removeEquations(text)
    text = removeFigures(text)
    text = removeStarHeaders(text)
    text = removeNumerics(text)
    
    text = re.split("### References", text)

       
    split_array = re.split(" |\n", text[0])

    


    capitalied_var_array = capitalizeVariables(split_array)      
    processedText = arrayToSentence(capitalied_var_array)
    
    
            
    
    logging.info(processedText)

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

def removeFigures(text):
    removedEquationText = re.sub('\`\`\`((.|\n)*)\`\`\`', '', text)
    return removedEquationText
    
def capitalizeVariables(split_array):

    variable_pattern1 = re.compile("\$\\\(.+)+\$")
    variable_pattern2 = re.compile("\$(.+)+\$")
    caps = False
    for i in range (len(split_array)):
        split_array[i] = split_array[i].strip()
        
        
        if variable_pattern1.match(split_array[i]) is not None\
        or variable_pattern2.match(split_array[i]) is not None:
            caps = True
            
        cleaned_text = re.sub('\W', '', split_array[i])
        if len(cleaned_text.strip()) == 0:
            split_array[i] = cleaned_text
        

        if caps == True:
            split_array[i] = cleaned_text.capitalize()
            caps = False
    
    return split_array

def arrayToSentence(word_array):
    returnString = ""
    for word in word_array:
        if word != "":
            returnString += re.sub("[$\\\]", '', str(word)) + " "
    
    return returnString.strip()
        
    
       

if __name__ == "__main__":
    
    inputFilePath = ""
    
    if len(sys.argv) < 3:
        logging.warn("<source file path> <output file path>")
    
    if len(sys.argv) > 3:
        logging.fatal("Too many argument inputs")
    if len(sys.argv) == 3:
        inputFilePath = sys.argv[1]
        outputFilePath = sys.argv[2]
    
    input_file_string = open(inputFilePath).read()

    proccessedText = extract(input_file_string)
    
    with open(outputFilePath, 'w') as filetowrite:
        filetowrite.write(proccessedText)
        filetowrite.close()
        
    logging.info(outputFilePath + " file created")


    

