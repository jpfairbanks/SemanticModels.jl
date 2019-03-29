import pandas as pd
import numpy as np
import umap
import sklearn.cluster as cluster
from sklearn.cluster import KMeans
from sklearn.cluster import DBSCAN
import spacy
import unicodedata
import matplotlib.pyplot as plt
import logging
logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)
logging.getLogger().setLevel(logging.INFO)

JULIA_VARIABLE_CSV_PATH = "ExperimentData/JuliaVariableData.csv"
CLUSTER_LABEL_CSV_PATH = "clusteringLabels.csv"
KMEANS_CLUSTER_LABEL_CSV_PATH = "ExperimentData/KmeansCluster.csv"
KMEANS_CLUSTER_TRUTH_CSV_PATH = "ExperimentData/KmeanClusterTruths.csv"
KMEANS_PREDICTED_CSV_PATH = "ExperimentData/KmeansPredicted.csv"
PREDICTED_UMAP_CSV_PATH = "ExperimentData/simPredictedUmapClusters.csv"





def createWord2Vec(data):


    nlp = spacy.load('en_core_web_md')
    tokenList = []
    for phrase in data:
        token = nlp(phrase)
        tokenList.append(token.vector)

    return np.asarray(tokenList)







def useUMAP(tokenList):

    db = DBSCAN(eps=0.3, min_samples=2).fit(np.asarray(tokenList))

    umapModel = umap.UMAP(random_state=42).fit(np.asarray(tokenList))

    standardEmbedding = umapModel.transform(tokenList)

    db_umap = DBSCAN(eps=0.3, min_samples=2).fit(standardEmbedding)

    return np.asarray(db.labels_), np.asarray(db_umap.labels_)






def writeUMAP_DBSCAN_CSV(subj_array, labels, umapLabels, labelsSimArray, \
             uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray):
    logging.info("Writing CSV")

    outputString = "node,labels,umapLabels,dbscanSim,UMAPsim,out_sampleDBSCAN,out_sampleUMAP\n"
    for i in range(len(labels)):
        outputString += str(subj_array[i]) + ","\
        + str(labels[i]) + ","\
        +str(umapLabels[i]) + ","\
        + str(labelsSimArray[i]) + ","\
        + str(uMapLabelsSimArray[i])+ ","\
        + str(OutSampleLabelsSimArray[i]) + ","\
        + str(OutSampleUMAPSimArray[i]) + "\n"


    with open(CLUSTER_LABEL_CSV_PATH, 'w') as filetowrite:
        filetowrite.write(outputString)
        filetowrite.close()




def generatePairs(labels, umapLabels, data):

    nlp = spacy.load('en_core_web_md')
    labelsSimArray = []
    uMapLabelsSimArray = []
    OutSampleLabelsSimArray = []
    OutSampleUMAPSimArray = []

    labels_sim = 0;
    umapLabels_sim = 0;
    outsample_labels_sim = 0;
    outsample_umap_sim = 0;
    for i in range(len(data)):
        logging.info("Iterating Word " + str(i))
        for j in range(len(data)):
            if i != j:

                token1 = nlp(data[i])
                token2 = nlp(data[j])
                if(labels[i] == labels[j]):
                    labels_sim += token1.similarity(token2)

                if(umapLabels[i] == umapLabels[j]):
                    umapLabels_sim += token1.similarity(token2)

                if(labels [i] != labels[j]):
                    outsample_labels_sim += token1.similarity(token2)

                if(umapLabels[i] != umapLabels[j]):
                    outsample_umap_sim += token1.similarity(token2)

            if j == len(data)-1:

                labelsSimArray.append(float(labels_sim/(list(labels).count(labels[i])-1)))
                uMapLabelsSimArray.append(float(umapLabels_sim/(list(umapLabels).count(umapLabels[i])-1)))


                if len(labels)-list(labels).count(labels[i]) == 0:
                    OutSampleLabelsSimArray.append(1)
                else:
                    OutSampleLabelsSimArray.append(float(outsample_labels_sim/(len(labels)-1-list(labels).count(labels[i]))))

                if len(umapLabels)-list(umapLabels).count(umapLabels[i]) == 0:
                    OutSampleUMAPSimArray.append(1)
                else:
                    OutSampleUMAPSimArray.append(float(outsample_umap_sim/(len(umapLabels)-1-list(umapLabels).count(umapLabels[i]))))

                labels_sim = 0;
                umapLabels_sim = 0;
                outsample_labels_sim = 0;
                outsample_umap_sim = 0;


    return labelsSimArray, uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray



def createCluster(svoFile):
    SVOdata = pd.read_csv(svoFile)

    subj_array = list(SVOdata["subject"])
    obj_array = list(SVOdata["object"])
    totalNodes = subj_array + obj_array



    tokenList = createWord2Vec(totalNodes)


    #Use UMAP Clustering
    labels,umapLabels = useUMAP(tokenList)


    #Retrieves Labels for Similarity
    labelsSimArray, uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray = \
        generatePairs(labels, umapLabels, totalNodes)

    #Writes CSV for UMAP vs DBScan Labels
    writeUMAP_DBSCAN_CSV(totalNodes, labels, umapLabels, labelsSimArray, \
             uMapLabelsSimArray, OutSampleLabelsSimArray, OutSampleUMAPSimArray )



def cleanVariables(variableArray):
    for i in range(len(variableArray)):

        variableArray[i] = str(variableArray[i]).replace(",", " ")
        variableArray[i] = str(variableArray[i]).replace("_", " ")
        variableArray[i] = containsGreek(variableArray[i])



    return variableArray


def containsGreek(inputString):
    greekLetters = []
    for s in inputString:
        name = unicodedata.name(chr(ord(s)))
        if "GREEK" in name:
            greekLetters.append(s)


    for letter in greekLetters:
        name = unicodedata.name(chr(ord(letter))).split(" ")[3]
        name = name.lower().capitalize()
        inputString = inputString.replace(letter, str(name) + str(" "))

    return inputString


def useKmeans(trainTokenList, K_size, variableTokenList):
    print(type(trainTokenList), type(K_size), type(variableTokenList))
    umapModel = umap.UMAP(random_state=42).fit(np.asarray(trainTokenList))
    trainEmbedding = umapModel.transform(trainTokenList)
    predictEmbedding = umapModel.transform(variableTokenList)


    kmeans = KMeans(n_clusters=K_size, random_state = 0).fit(trainEmbedding)


    return kmeans.labels_, kmeans.predict(predictEmbedding)

def writeCSV(variable_array, predictedLabels, fileName):
    logging.info("generating CSV " + fileName)
    outputString = "variable,cluster\n"
    for i in range(len(variable_array)):
        outputString += str(variable_array[i].replace(",", " ")) + "," + str(predictedLabels[i]) + "\n"

    with open(fileName, 'w') as filetowrite:
        filetowrite.write(outputString)
        filetowrite.close()





def groupNodesByCluster(umapData):
    maxNoClusters = max(list(umapData["umapLabels"]))
    clusteredNodes = []

    for i in range(maxNoClusters + 1):
        temp_bin = []
        for j in range(len(list(umapData["umapLabels"]))):
            if list(umapData["umapLabels"])[j] == i:
                temp_bin.append(list(umapData["node"])[j])
        clusteredNodes.append(temp_bin)

    return clusteredNodes

def groupNodesByKMeansCluster(kMeansData):
    maxNoClusters = max(list(kMeansData["cluster"]))
    clusteredNodes = []

    for i in range(maxNoClusters + 1):
        temp_bin = []
        for j in range(len(list(kMeansData["cluster"]))):
            if list(kMeansData["cluster"])[j] == i:
                temp_bin.append(list(kMeansData["variable"])[j])
        clusteredNodes.append(temp_bin)

    return clusteredNodes


def getSimilarityLabels(clusteredNodes, variable_array):
    labels = []
    nlp = spacy.load('en_core_web_md')

    count = 0
    for variable in variable_array:
        logging.info("Comparing Variable No: " + str(count))
        count += 1
        variableToken = nlp(variable)
        highest_average = -9000
        label = 0

        for clusterNo in range(len(clusteredNodes)):
            average = 0
            for node in clusteredNodes[clusterNo]:
                nodeToken = nlp(node)
                average += variableToken.similarity(nodeToken)
            average /= len(clusteredNodes[clusterNo])
            if average > highest_average:
                highest_average = average
                label = clusterNo

        labels.append(label)

    return labels


def calculateKMeansAccuracy():
    labeledData = pd.read_csv(JULIA_VARIABLE_CSV_PATH)
    predictedData = pd.read_csv(KMEANS_PREDICTED_CSV_PATH)

    labeled = list(labeledData["KMeansLabels"])
    predicted = list(predictedData["cluster"])

    count = 0
    for i in range(len(predicted)):
        if labeled[i] == predicted[i]:
            count += 1

    logging.info("KMeans Accuracy is : " + str(float(count/len(predicted))))


def calculateSimAccuracy():
    labeledData = pd.read_csv(JULIA_VARIABLE_CSV_PATH)
    predictedData = pd.read_csv(PREDICTED_UMAP_CSV_PATH)

    labeled = list(labeledData["DBSCANLabels"])
    predicted = list(predictedData["cluster"])

    count = 0
    for i in range(len(predicted)):
        if labeled[i] == predicted[i]:
            count += 1

    logging.info("Similar Cluster Assignment Accuracy is : " + str(float(count/len(predicted))))


def runKMeansExp():
    variableData = pd.read_csv(JULIA_VARIABLE_CSV_PATH)
    umapData = pd.read_csv(CLUSTER_LABEL_CSV_PATH)
    umapData = umapData[umapData.umapLabels != -1]

    kmeansTrainData = list(umapData["node"])
    variable_array = list(variableData["variable"])
    variable_array = cleanVariables(variable_array)

    variableTokenList = createWord2Vec(variable_array)
    trainTokenList = createWord2Vec(kmeansTrainData)
    print(len(trainTokenList))
    K_size = max(list(umapData["umapLabels"]))


    trainLabels, predictedLabels = useKmeans(trainTokenList, K_size, variableTokenList)
    writeCSV(kmeansTrainData, trainLabels, KMEANS_CLUSTER_LABEL_CSV_PATH)
    writeCSV(variable_array, predictedLabels, KMEANS_PREDICTED_CSV_PATH)

    calculateKMeansAccuracy()




def runUMapSimilarityExp():
    variableData = pd.read_csv(JULIA_VARIABLE_CSV_PATH)
    umapData = pd.read_csv(CLUSTER_LABEL_CSV_PATH)
    umapData = umapData[umapData.umapLabels != -1]
    variable_array = list(variableData["variable"])
    variable_array = cleanVariables(variable_array)

    clusteredNodes = groupNodesByCluster(umapData)
    labels = getSimilarityLabels(clusteredNodes, variable_array)

    writeCSV(variable_array, labels, PREDICTED_UMAP_CSV_PATH)

    calculateSimAccuracy()

def getAverageSimilarity(variable_array, clusteredNodes, predictedLabels):
    nlp = spacy.load('en_core_web_md')
    averageSimArray = []

    for i in range(len(variable_array)):
        averageSim = 0
        for word in clusteredNodes[predictedLabels[i]]:
            token1 = nlp(word)
            token2 = nlp(variable_array[i])
            averageSim += token1.similarity(token2)
        averageSimArray.append(float(averageSim/ len(clusteredNodes[predictedLabels[i]])))

    return averageSimArray




def runCombinationExp():
    variableData = pd.read_csv(JULIA_VARIABLE_CSV_PATH)
    umapData = pd.read_csv(CLUSTER_LABEL_CSV_PATH)
    umapData = umapData[umapData.umapLabels != -1]

    kmeansTrainData = list(umapData["node"])
    variable_array = list(variableData["variable"])
    variable_array = cleanVariables(variable_array)

    variableTokenList = createWord2Vec(variable_array)
    trainTokenList = createWord2Vec(kmeansTrainData)
    K_size = max(list(umapData["umapLabels"]))


    trainLabels, predictedLabels = useKmeans(trainTokenList, K_size, variableTokenList)
    writeCSV(kmeansTrainData, trainLabels, KMEANS_CLUSTER_LABEL_CSV_PATH)


    clusteredNodes = groupNodesByKMeansCluster(pd.read_csv(KMEANS_CLUSTER_LABEL_CSV_PATH))
    averageSimArray = getAverageSimilarity(variable_array, clusteredNodes, predictedLabels)

    writeCSV(variable_array, predictedLabels, KMEANS_PREDICTED_CSV_PATH)


    graphCombinationExp(averageSimArray)

    return averageSimArray

def graphCombinationExp(averageSimArray):

    labeledData = pd.read_csv(JULIA_VARIABLE_CSV_PATH)
    predictedData = pd.read_csv(KMEANS_CLUSTER_TRUTH_CSV_PATH)


    labeled = list(labeledData["KMeansLabels"])
    predicted = list(predictedData["cluster"])

    thresholdArray = []
    accuracy = []
    numberOfAssignments = []

    threshold = .01
    while threshold < .95:

        assignmentCount = 0
        denominatorCount = 0
        for i in range(len(predicted)):
            if averageSimArray[i] > threshold:
                denominatorCount += 1

            if labeled[i] == predicted[i] and averageSimArray[i] > threshold:
                assignmentCount += 1

        if denominatorCount != 0:
            accuracy.append(float(assignmentCount/denominatorCount))
        else:
            accuracy.append(1.0)
        numberOfAssignments.append(float(assignmentCount/len(predicted)))
        thresholdArray.append(threshold)
        threshold += .02
    numberOfAssignments = np.divide(np.asarray(numberOfAssignments), numberOfAssignments[0])
    plt.figure(0)
    plt.title("Accuracy vs Normalized True Assignments")
    plt.plot(thresholdArray, accuracy, color="blue", label="Accuracy")
    plt.plot(thresholdArray, numberOfAssignments, color="orange", label="Normalized True Assigns" )
    plt.legend(loc="upper right")
    plt.xticks(np.arange(0, 1, step=0.1))
    plt.xlabel("Similarity Threshold")
    plt.ylabel("Normalized Values")
    idx = np.argwhere(np.diff(np.sign(numberOfAssignments - accuracy))).flatten()
    plt.plot(thresholdArray[int(idx)], numberOfAssignments[int(idx)], 'ro')
    logging.info("Intersection Threshold is: " + str(thresholdArray[int(idx)]))
