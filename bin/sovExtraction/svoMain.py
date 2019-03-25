from subject_verb_object_extract import findSVOs, nlp
import sys
import os
import re
import logging
logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)
logging.getLogger().setLevel(logging.INFO)
CSV_OUTPUT_PATH = os.path.join("svoOutput", "svo.csv")
REGEX_PATTERNS = '[.,/$]'


def tuplesToFile(svo):
    csv_string = ""
    for triplet in svo:
        csv_string += re.sub(REGEX_PATTERNS, '', triplet[0]) + ","\
                    + re.sub(REGEX_PATTERNS, '', triplet[1]) + ","\
                    + re.sub(REGEX_PATTERNS, '', triplet[2]) + "\n"
    logging.debug("writing tuples to {}".format(CSV_OUTPUT_PATH))
    logging.info("writing {} tuples".format(len(svo)))
    with open(CSV_OUTPUT_PATH,'a') as outputFile:
        outputFile.write(csv_string)
    
def extractSVO(dir_path):
    if os.path.isdir(dir_path):
        logging.info("Extracting Files from " + str(dir_path))
        for file in os.listdir(dir_path):
            if file.endswith(".txt"):
                logging.info("Parsing file {}".format(file))
                file_string = open(os.path.join(dir_path,file)).read()
                tokens = nlp(file_string)
                svos = findSVOs(tokens)
                tuplesToFile(svos)
            else:
                logging.info("Skipping file {}".format(file))
                
    else:
        logging.fatal(dir_path + " is not a directory")




if __name__ == "__main__":
    
    inputFilePath = ""
    
    if len(sys.argv) < 2:
        
        logging.fatal("Not enough arguments, input directory path")
    
    if len(sys.argv) > 2:
        CSV_OUTPUT_PATH = sys.argv[2]
        logging.info("using CSV_OUTPUT_PATH: {}".format(CSV_OUTPUT_PATH))
    else:
        logging.info("using default output path {}".format(CSV_OUTPUT_PATH))
    dir_path = sys.argv[1]
    extractSVO(dir_path)

        



    
