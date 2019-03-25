#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 20 09:50:39 2019

@author: kuncao
"""

from extractText import extract



def testVariableCapitalization(inputString):
    
    returnString = extract(inputString)
    
    try:
        assert(returnString == "There are no birth of natural death processes in this model. Parameters are: Beta rate of infection Delta rate at which symptoms")
    except AssertionError:
        print("Variable Capitalization Test Failed")
    else:
        print("Variable Capitalization Test Passed")

def testEmptyVariable(inputString):
    returnString = extract(inputString)
    try:
        assert(returnString == "")
    except AssertionError:
        print("Empty Variable String Failed")
    else:
        print("Empty Variable String Passed")
        
def removeStarHeaders(inputString):
    returnString = extract(inputString)
    try:
        assert(returnString == "Bob")
    except AssertionError:
        print("Star Headers removal Failed")
    else:
        print("Star Headers removal Passed")
        

def removeTitleHeaders(inputString):
    returnString = extract(inputString)
    try:
        assert(returnString == "Leftover")
    except AssertionError:
        print("Title Headers removal Failed")
    else:
        print("Title Headers removal Passed")
    
    

    
def testEquationRemoval(inputString):
    returnString = extract(inputString)
    
    try:
        assert(returnString == "in an open population, with no additional mortality associated with infection (such that the population size remains constant and R is not modelled explicitly).")
    except AssertionError:
        print("Equation Removal Test Failed")
    else:
        print("Equation Removal Test Passed")

if __name__ == "__main__": 
    
    capitalizeVariableTest = r"There are no birth of natural death processes in this model. Parameters are: $\beta$: rate of infection $\delta$: rate at which symptoms"
    testVariableCapitalization(capitalizeVariableTest)
    
    capitalizationVariableTest = r"$\$"
    testEmptyVariable(capitalizationVariableTest)
    
    starHeaderTest = r"*Author* Bob"
    removeStarHeaders(starHeaderTest) 
    
    equationRemovalTest = r"in an open population, with no additional mortality associated with infection (such that the population size remains constant and $R$ is not modelled explicitly).$$ \frac{dS(t)}{dt} = \mu-\beta S(t) I(t) - \mu S(t)\ \frac{dE(t)}{dt} = \beta S(t) I(t)- (\sigma + \mu) E(t)\ \frac{dI(t)}{dt} = \sigma E(t)- (\gamma + \mu) I(t)\ \frac{dR(t)}{dt} = \gamma I(t) = \mu R $$"
    testEquationRemoval(equationRemovalTest)
    
# =============================================================================
#     
#     titleHeaderTest = "--- \n title: 'SIS model ' \npermalink: 'chapters/sis/intro' \npreviouschapter:--- Leftover"
#     removeTitleHeaders(titleHeaderTest)
# =============================================================================
    
    