FROM julia:1.0.3-stretch

# Sets up jupyterlab
RUN apt-get update; \
    apt-get install -y python3 python3-pip python3-dev build-essential git

RUN pip3 install jupyter -U && pip3 install jupyterlab jupytext --upgrade

RUN jupyter lab --generate-config && echo 'c.NotebookApp.contents_manager_class = "jupytext.TextFileContentsManager"' >> /root/.jupyter/jupyter_notebook_config.py

## Connects Julia to jupyterlab
RUN julia -e 'ENV["JUPYTER"]="jupyter"; using Pkg; Pkg.add("IJulia")'

## Add SemanticModels.jl to Julia
RUN julia --project -e 'using Pkg; pkg"add https://github.com/jpfairbanks/SemanticModels.jl.git";'

## Download SemanticModels.jl folder
RUN git clone https://github.com/jpfairbanks/SemanticModels.jl.git

## Expose port 8888
EXPOSE 8888

## Create an entrypoint to jupyterlab
ENTRYPOINT ["jupyter", "lab", "--notebook-dir=SemanticModels.jl", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
