# Categories for Science

Dan Spivak wrote a wonderful book on category theory for scientists based on his lectures at MIT
http://math.mit.edu/~dspivak/CT4S.pdf.

> Data gathering is ubiquitous in science. Giant databases are currently being mined for unknown
> patterns, but in fact there are many (many) known patterns that simply have not been catalogued.
> Consider the well-known case of medical records. A patient’s medical history is often known by
> various individual doctor-offices but quite inadequately shared between them. Sharing medical
> records often means faxing a hand-written note or a filled-in house-created form between offices.
>
> Similarly, in science there exists substantial expertise making brilliant connections between
> concepts, but it is being conveyed in silos of English prose known as journal articles. Every
> scientific journal article has a methods section, but it is almost impossible to read a methods
> section and subsequently repeat the experiment—the English language is inadequate to precisely and
> concisely convey what is being done


This is the point of our project, to mine the code and docs for the information necessary to repeat
and *expand* scientific knowledge. Reproducible research is focused on getting the code/data to be
shared and runnable with VMs/Docker etc are doing the first step. Can I repeat your analysis? We
want to push that to expanding.

Ontology logs are a diagrammatic approach to formalizing scientific methodologies. They can be used
to precisely specify what a scientist is talking about. Spivak, D.I., Kent, R.E. (2012) “Ologs: A
Categorical Framework for Knowledge Representation.” PLoS ONE 7(1): e24274.
doi:10.1371/journal.pone.0024274.

An olog is composed of types (the boxes) and aspects (the edges). The labels on the edges is the
name of the aspect. An aspect is valid if it is a function (1-many relation). 

![Birthday olog](img/olog_birthday.png)


We can represent an SIR model as an olog as shown below.

![SIR olog](img/olog_sir.png)

Another category theory representation without the human readable names used in an olog shows a simpler representation.

![SIR Category](img/category_sir.png)