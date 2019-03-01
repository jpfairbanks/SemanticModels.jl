from subject_verb_object_extract import findSVOs, nlp
import sys
import os
import re

CSV_OUTPUT_PATH = os.path.join("svoOutput", "svo.csv")
REGEX_PATTERNS = '[.,/$]'


def tuplesToFile(svo):
    csv_string = ""
    for triplet in svo:
        csv_string += re.sub(REGEX_PATTERNS, '', triplet[0]) + ","\
                    + re.sub(REGEX_PATTERNS, '', triplet[1]) + ","\
                    + re.sub(REGEX_PATTERNS, '', triplet[2]) + "\n"
    
    with open(CSV_OUTPUT_PATH,'a') as outputFile:
        outputFile.write(csv_string)

        
    
    
    
def extractSVO(dir_path):
    if os.path.isdir(dir_path):
        print("Extracting Files from " + str(dir_path))
        for file in os.listdir(dir_path):
            if file.endswith(".txt"):
                file_string = open(os.path.join(dir_path,file)).read()
                tokens = nlp(file_string)
                svos = findSVOs(tokens)
                tuplesToFile(svos)
                
    else:
        print(dir_path + " is not a directory")




if __name__ == "__main__":
    
    inputFilePath = ""
    
    if len(sys.argv) < 2:
        
        print("Not enough arguments, input directory path")
    
    if len(sys.argv) > 2:
        print("Too many argument inputs")
        
    if len(sys.argv) == 2:
        dir_path = sys.argv[1]
        extractSVO(dir_path)

        



    
