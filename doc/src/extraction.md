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
 
### Information Extraction Process
1. First we process source files including research papers, source code, and documentation files into
a common format that can be ingested by our information extraction process
2. For source code files, we extract out comment lines and process them as natural language text
3. For source code itself, we perform lexical processing to extract out phenomena like 
function names and parameters
4. We use a lexical-token based matching algorithm to detect potential matches between
phenomena of interest in comments that may map to phenomena from actual code
5. We create an associative array of code extractions to particular comment lines
6. We run Automates rule-based extraction on the comment lines that were associated
with a code extraction
7. If there is a relevant rule match in Automates output to a comment and the rule
contains the lexical token from the associated code match then we create new
knowledge based on the nature of the particular rule that was triggered e.g.
Definition, Concept, parameter setting, etc.
 
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