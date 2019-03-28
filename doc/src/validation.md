# Model Validation with Dynamic Analysis

### Looking Forward

We pursued a novel approach to model validation based on LSTM models of program traces, this was supposed to use the Cassette based traces to build probabilistic models of program failure. This did not work because of the long term dependencies between information in the trace and the failure condition that would happen much later. While we see no impediment to successful modeling of program failure based on traces, we are attempting a prerequisite task of building an [autoencoder](notebooks/autoencoding_julia.ipynb) of Julia code snippets that will enable learning latent space embeddings of programs. These latent space embeddings will assist with future model augmentation, synthesis, and validation tasks because we will be able to solve clustering, classification, and nearest neighbor search in this latent space that captures the meaning of julia program snippets.

We also believe that the existing work on model augmentation in particular the metaprogramming on models necessary to implement the typegraph functionality will enable faster development of novel validation techniques.

Validation of scientific models is a type of program verification, but is complicated by the fact that there are no global explicit rules about what defines a valid scientific models. In a local sense many disciplines of science have developed rules for valid computations. For example unit checking and dimensional analysis and conservation of physical laws. Dimensional analysis provides rules for arithmetic of unitful numbers. The rules of dimensional analysis are "you can add numbers if the units match, when you multiply/divide, the powers of the units add/subtract." Many physical computations obey conservation rules that provide a form of program verification. Based on a law of physics such as "The total mass of the system is constant," one can build a program checker that instruments a program with the ability to audit the fact that `sum(mass, system[t]) == sum(mass, system[t0])`, these kinds of checks may be expressed in codes.

We can use Cassette.jl to implement a context for validating these computations. The main difficulty is converting the human language expressed rule into a mathematical test for correctness. A data driven method is outlined below.

## DeepValidate
There are an intractable number of permutations of valid deep learning model architectures, each providing different levels of performance (both in terms of efficiency and accuracy of output) on different datasets. One current predicament in the field is an inability to rigorously define an optimal architecture starting from the types of inputs and outputs; preferred solutions are instead chosen based on empirical processes of trial and error. In light of this, it has become common to start deep learning model efforts from architectures established by previous research, especially ones which have been adopted by a significant portion of the deep learning community, for similar tasks, and then tweak and modify hyper parameters as necessary. We adopt this typical approach, beginning with a standard architecture and leaving open the possibility of optimizing the architecture as training progresses. 

Given that our deep learning task in this instance is relatively straightforward and supportive of the overall thrust of this project rather than central to it, we adopt a common and well tested <a href='http://www.bioinf.jku.at/publications/older/2604.pdf'>long short-term memory</a> (LSTM) recurrent neural network (RNN) architecture for our variable-length sequence classification task. LSTM models have a rich history of success in complex natural language processing tasks, specifically where <a href='https://towardsdatascience.com/how-to-create-data-products-that-are-magical-using-sequence-to-sequence-models-703f86a231f8'>comprehension</a> and classification of computer programming code is concernd, and they remain the most popular and <a href='https://www.microsoft.com/en-us/research/wp-content/uploads/2016/04/Intent.pdf'>effective</a> approach to these tasks. Our base model will use binary cross entropy as its cost function given our task is one of binary classification, and an Adam optimizer for training optimization. Introduced in 2014, the <a href='https://arxiv.org/abs/1412.6980'>Adam</a> optimization algorithm generally remains the most robust and efficient back propagation optimization method in deep learning. Input traces are first tokenized as indices representing specific functions, variables, and types in vocabularies compiled from our modeling corpus, while values are passed as is. These sequences are fed in to a LSTM layer which reads each token/value in sequence and calculates activations on them, while also passing values ahead in the chain subject to functions which either pass, strengthen or “forget” the memory value. 

As mentioned, this LSTM RNN model is written using Julia’s Flux.jl package, with a similar architecture to the standard language classification model:

```julia
scanner = Chain(Dense(length(alphabet), seq_len, σ), LSTM(seq_len, seq_len))
encoder = Dense(seq_len, 2)

function model(x)
  state = scanner.([x])[end]
  Flux.reset!(scanner)
  softmax(encoder(state))
end

loss(tup) = crossentropy(mod(tup[1]), tup[2])
accuracy(tup) = mean(argmax(m(tup[1])) .== argmax(tup[2]))

testacc() = mean(accuracy(t) for t in test)
testloss() = mean(loss(t) for t in test)

opt = ADAM(0.01)
ps = params(mod)
evalcb = () -> @show testloss(), testacc()

Flux.train!(loss, ps, train, opt, cb = throttle(evalcb, 10))
```

In the above example, outputs of the LSTM layer are subject to 50% dropout as a regularization measure to avoid over-fitting, and then fed to a densely connected neural network layer for computation of non-linear feature functions. Outputs of this dense layer are normalized for each batch of training data as another regularization measure to constrict extreme weights. This sequence of dropout-dense-normalization layers is repeated once more to add depth to the non-linear features learned by the model. Finally, a softmax activation function is calculated on the outputs and a binary classification is completed on each case in our dataset. 


To train this DeepValidate model, we execute the following steps:

1. Collect a sample of known “good” inputs matched with their corresponding “good” outputs, and a sample of known “bad” inputs matched with their corresponding “bad” outputs.
    + “Good” here is defined as: given these input(s), the model output(s)/prediction(s) correspond to expected or observed
empirical reality, within an acceptable error tolerance.
    + Edge cases to note but not heavily consider at this point:
        1. For “good” input to “bad” output, we can just corrupt the “good” inputs at various points along the computation.
        1. If assumption that code is correct and does not contain bugs holds, then it is ok to assume we will not observe “bad” input to “good” output. 
1. Run the simulation to collect a sample of known good outputs.
1. Instrument the code to log all SSA assignments from the function calls
1. Train an RNN on the sequence of [(func, var, val)...] where the labels are “good input vs bad input”
    + By definition, any SSA “sentence” generated by a known “good” input is assumed to be “good”; thus, these labels essentially propagate down. 
1. Partial evaluations of the RNN model and output can point to “where things went wrong." Specifically, layer-wise relevance propagation can be employed to identify the most powerful factors in input sequences, as well as their valence (good input, bad input) for case by case error analysis in deep learning models. This approach was effectively extended to LSTM RNN models by Arras et al. (http://www.aclweb.org/anthology/W17-5221) in 2017. 

In step 1: for an analytically tractable model, we can generate an arbitrarily large collection of known good and bad inputs.

### Required Data Format

We need to build a Tensorflow.jl or Flux.jl RNN model that will work on sequences `[(func, var, val, type)]` and produce labels of good/bad

1. Traces will be communicated 1 trace per file
1. Each line is a tuple module.func, var,val,type with quotes as necessary for CSV storage. 
1. The files will be organized into folders program/{good,bad}/tracenumber.txt
1. Traces will be variable length.

### Datasets for empirical validation

Observed empirical reality is represented in selected real world epidemiological datasets covering multiple collection efforts in different environments. These datasets have been identified as promising candidates for demonstrating how modeling choices can affect the quality of models and how ranges of variables can change when one moves between environments or contexts with the same types of data. 

To ensure a broad selection of types of epidemiological model options during examination of this data, we will combine key disease case data with various environmental data sources covering weather, demography, healthcare infrastructure, and travel patterns wherever possible. These datasets will be of varying levels of geographic and temporal granularity, but always at least monthly in order to model seasonal variations in infected populations. 

The validation datasets cover three main disease topics:
1.	**Influenza cases in the United States**: The Centers for Disease Control and Prevention (CDC) maintains publicly available data containing weekly influenza activity levels per state (https://gis.cdc.gov/grasp/fluview/fluportaldashboard.html). This weekly data is provided for all states from the 2010-2011 to 2018-2019 flu seasons, comprising over 23,000 rows with columns indicating percentage of influenza-like-illnesses, raw case count, number of providers and total numbers of patients for each state in each week of each year. A sample of the data is presented below for reference This data will be supplemented by monthly influenza vaccine reports provided by the CDC (https://www.cdc.gov/flu/fluvaxview/coverage-1718estimates.htm) for different age ranges (6 months – 4 years of age, 5-12 years of age, 13-17 years of age, 18-49 years of age, and 50 – 64 years of age). In addition, data is split by different demographic groups (Caucasian, African American and Hispanic). This data is downloaded directly into .csv dataset from the above cited webpage. For application to our weekly datasets, weekly values can be interpolated based on the monthly aggregates. 

<center>

|REGION|YEAR|WEEK|%UNWEIGHTED ILI|ILITOTAL|NUM. OF PROVIDERS|TOTAL PATIENTS|
|------|----|----|---------------|--------|-----------------|-------------|
|Alabama|2010|40|2.13477|249|35|11664|
|Alaska|2010|40|0.875146|15|7|1714|
|Arizona|2010|40|0.674721|172|49|25492|

</center>

2.	**Zika virus cases in the Americas**: This data catalogues 108,000 reported cases of Zika, along with their report date and country/city (for geo-spatial location). This dataset is provided by the publicly available Zika Data Repository (https://github.com/cdcepi/zika) hosted on Github. One dozen countries throughout the Americas are included, as well as two separate Caribbean U.S. territories (Puerto Rico and U.S. Virgin Islands). A sample of the data is presented below for reference:

<center>

|report_date|location|data_field|value|
|---|---|---|---|
|6/2/18|Mexico-Guanajuato|weekly_zika_confirmed|3|
|6/2/18|Mexico-Guerrero|weekly_zika_confirmed|0|
|6/2/18|Mexico-Hidalgo|weekly_zika_confirmed|5|
|6/2/18|Mexico-Jalisco|weekly_zika_confirmed|21|

</center>

3.	**Dengue fever cases in select countries around the world**: The Pan-American Health Organization reports weekly dengue fever case levels in 53 countries throughout the Americas and at sub-national geographic units in Brazil, covering years 2014-2019. This data is available at http://www.paho.org/data/index.php/en/mnu-topics/indicadores-dengue-en/dengue-nacional-en/252-dengue-pais-ano-en.html and a sample of the data is presented below for reference:

<center>

|Geo|Type|Year|Confirmed|Deaths|Week|Incidence Rate|Population X 1000|Severe Dengue|Total Cases|
|---|---|---|---|---|---|---|---|---|---|
|Curaçao||2018|0|0|52|0|162|0|0|
|Honduras|DEN 1,2,3|2018|Null|3|52|84.34|9,417|1,172|7,942|
|Argentina|DEN 1|2018|1,175|0|52|4.09|44,689|0|1,829|
|Aruba|DEN|2018|75|Null|52|70.75|106|Null|75|
|Mexico|DEN 1,2,3,4|2018|12,706|45|52|60.13|130,759|858|78,621|

</center>

Our supplementary environmental datasets will be variably sourced depending on the target geographies, but will include:
1.	**Weather**: Historical weather data aggregated to the target geography and unit of time. This data is pulled directly from the Global Historical Climate Network (GHCN), an integrated database of climate summaries from land surface stations across the globe that have been subjected to a common suite of quality assurance reviews, and updated hourly. This database is maintained by the National Oceanic and Atmospheric Agency (NOAA) at https://www.ncdc.noaa.gov/data-access/land-based-station-data/land-based-datasets/global-historical-climatology-network-ghcn. A variety of weather and climate indicators are available, but for completeness of coverage and relevance, we will target high/low/mean temperatures and total precipitation data for each geography and time period. 
2.	**Demography**: Demographic information such as total population, population density, population share by age, gender, education level, by target geography. For the United States, American Community Survey data is conveniently from the IPUMS repositories (https://usa.ipums.org/usa/) and also includes highly relevant additional variables such as health insurance coverage. Basic demographic data is available for international geographies as well through national statistics office websites (such as the Department of Statistics for Singapore at https://www.singstat.gov.sg/) or international governmental organizations (such as the World Bank for Bangladesh at http://microdata.worldbank.org/index.php/catalog/2562/sampling). These may be less current and frequently updated, especially in less developed countries, but should still serve as reasonable approximations for our purposes. Some variables such as health coverage or access to healthcare may be more sparsely available internationally.
 - Similarly, for the United States influenza data, we will include reports and estimates of flu vaccination rates (sourced from CDC https://www.cdc.gov/flu/fluvaxview/coverage-1718estimates.htm). Rates over time within years can be interpolated from CDC estimates.
 - As one potential outcome variable in flu modeling, we leverage recent research on costs of seasonal influenza outbreaks by different population breaks (https://www.ncbi.nlm.nih.gov/pubmed/29801998). 
3.	**Mobility**: Airline Network News and Analysis (ANNA) provides monthly passenger traffic numbers from hundreds of major airports around the world (over 300 in Europe, over 250 in the Americas, and over 50 in the rest of the world) updated weekly and dating back to 2014 (https://www.anna.aero/databases/). These will be aggregated by geographic unit and time period to model external population flows as an additional disease vector. For application to weekly datasets, weekly numbers can be interpolated based on the monthly aggregates. 
4.	**Online indicators**: Online activity proxies such as Google Trends data on disease relevant searches. This type of data has been shown to be useful in modeling and predicting disease outbreaks in recent years, and may be of interest for our own models. These data are no longer actively updated or maintained, but historical data covering most of the time periods and geographies of interest are available at https://www.google.org/flutrends/about/ 
    a.	Similarly, keyword searches on Twitter for ‘Dengue/aegypti’ and or ‘Influenza/Flu’ can be used to supplement our datasets. These will be GPS tagged and stored by Twitter for each returned tweet. If GPS is not provided we use the location the user reported to twitter during their user registration. This data provides spatially localized social messaging that can be mapped to the Dengue Fever and Influenza/Flu case datasets provided above, by assigning each GPS tagged tweet to its most likely state (Influenza/Flu) or country (Dengue). These would then be aggregated to the time level (weekly, monthly or yearly) for comparison to the Flu and Dengue Fever databases.
