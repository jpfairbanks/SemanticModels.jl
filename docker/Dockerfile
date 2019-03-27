FROM julia:1.0.3-stretch

# Sets up jupyterlab
RUN apt-get update; \
    apt-get install -y python3 python3-pip python3-dev build-essential git

RUN pip3 install jupyter -U && pip3 install jupyterlab jupytext --upgrade

RUN jupyter lab --generate-config && echo 'c.NotebookApp.contents_manager_class = "jupytext.TextFileContentsManager"' >> /root/.jupyter/jupyter_notebook_config.py

## Connects Julia to jupyterlab
RUN julia -e 'ENV["JUPYTER"]="jupyter"; using Pkg; Pkg.add("IJulia")'

## Add SemanticModels.jl to Julia
RUN julia --project -e 'using Pkg; Pkg.develop("SemanticModels");'

RUN julia --project -e 'using Pkg; \
          Pkg.add(["LsqFit", "Polynomials", "Plots", "Test"]); \
          pkg"precompile";'

## Expose port 8888
EXPOSE 8888

WORKDIR /root/.julia/dev/SemanticModels

## Create an entrypoint to jupyterlab
ENTRYPOINT ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
