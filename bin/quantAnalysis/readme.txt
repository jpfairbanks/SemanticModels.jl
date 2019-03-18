semanticClustering.py:
-injests the svo.csv script which is in subject, verb, object format
-creates a csv of clusters from the subject and objects using just DBScan
and a combination of DBScan and UMap
-The insample similarity and outsample similarity between clusters are also computed


predictVariableClusters.py
-injests the JuliaVariableData that are extracted along with the csv that is produced by
semanticClustering.py.
-2 experiments are run one to generate the labels:
1. using Kmeans 
2. comparing similarity between clusters
