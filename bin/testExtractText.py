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
        assert(returnString == "There are no birth of natural death processes in this model Parameters are Beta rate of infection Delta rate at which symptoms")
    except AssertionError:
        print("Variable Capitalization Test Failed")
    else:
        print("Variable Capitalization Test Passed")
        

    
def testEquationRemoval(inputString):
    returnString = extract(inputString)
    
    try:
        assert(returnString == "in an open population with no additional mortality associated with infection such that the population size remains constant and R is not modelled explicitly")
    except AssertionError:
        print("Equation Removal Test Failed")
    else:
        print("Equation Removal Test Passed")

if __name__ == "__main__":
    
    capitalizeVariableTest = r"There are no birth of natural death processes in this model. Parameters are: $\beta$: rate of infection $\delta$: rate at which symptoms"
    testVariableCapitalization(capitalizeVariableTest)
    
    
    equationRemovalTest = r"in an open population, with no additional mortality associated with infection (such that the population size remains constant and $R$ is not modelled explicitly).$$ \frac{dS(t)}{dt} = \mu-\beta S(t) I(t) - \mu S(t)\ \frac{dE(t)}{dt} = \beta S(t) I(t)- (\sigma + \mu) E(t)\ \frac{dI(t)}{dt} = \sigma E(t)- (\gamma + \mu) I(t)\ \frac{dR(t)}{dt} = \gamma I(t) = \mu R $$"
    testEquationRemoval(equationRemovalTest)