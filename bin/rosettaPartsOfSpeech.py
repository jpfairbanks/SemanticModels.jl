#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Feb 25 10:12:44 2019

@author: kuncao
"""



import argparse
import json
import os
import sys

from rosette.api import API, DocumentParameters, RosetteException


def run(key, alt_url, filepath):
    """ Run the example """
    # Create an API instance
    api = API(user_key=key, service_url=alt_url)

    # Set selected API options.
    # For more information on the functionality of these
    # and other available options, see Rosette Features & Functions
    # https://developer.rosette.com/features-and-functions#morphological-analysis-introduction

    # api.set_option('modelType','perceptron') # Valid for Chinese and Japanese only

    morphology_parts_of_speech_data = open(inputFilePath).read()
    #morphology_parts_of_speech_data = "Kermack and McKendrick, proposed, The susceptibleinfectedrecovered SIR model in a closed population, as a special case of a more general model, ''"
    #morphology_parts_of_speech_data = "The susceptibleinfectedrecovered SIR model in a closed population, forms, '', '', ''"
    #morphology_parts_of_speech_data = "I and infected individuals, recover, '', at a percapita rate, ''"

    params = DocumentParameters()
    params["content"] = morphology_parts_of_speech_data
    try:
        return api.morphology(params, api.morphology_output['PARTS_OF_SPEECH'])
    except RosetteException as exception:
        print(exception)


PARSER = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,
                                 description='Calls the ' +
                                 os.path.splitext(os.path.basename(__file__))[0] + ' endpoint')
PARSER.add_argument('-k', '--key', help='Rosette API Key', required=True)
PARSER.add_argument('-u', '--url', help="Alternative API URL",
                    default='https://api.rosette.com/rest/v1/')

if __name__ == '__main__':
    inputFilePath = sys.argv[1]
    RESULT = run("5e6d3db318804b1c730aed6a4bf43d38", 'https://api.rosette.com/rest/v1/', inputFilePath)
    print(RESULT)
    # print(json.dumps(RESULT, indent=2, ensure_ascii=False, sort_keys=True).encode("utf8"))
