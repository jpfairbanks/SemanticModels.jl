# Information Extraction for Semantic Modeling

To select knowledge elements that should be present in knowledge graphs we conduct information extraction
on various sources files including:

1. Comments within source code files
2. Code phenomena like function names and parameters
3. Research Publications
4. Documentation for Libraries and Frameworks utilized within domain

## Information Extraction
Our working goal for doing information extraction is to identify and extract
 information elements which may, through situating in a knowledge graph 
 make meaning for use in meta-modeling construction and reasoning tasks.

### Rule-based Methodology
We are currently leveraging a rule-based methodology provided by the AUTOMATES team. 
We have started creating rules to extract phenomena like definitions of parameters. 
These same parameters can then be recognized within source code beginning with lexical
matching for mapping human language definitions to specific source code instantiations.

### Model-based Methodology
We are currently in the process of collecting and annotating ground truth data to
use in construct machine learning models to do information extractions based on
information elements of interest that we identify in use case planning for 
meta-modeling related functionalities users will be able to work with.