# Build as materialsproject/jupyterhub-singleuser
# Run with the DockerSpawner in JupyterHub

FROM jupyterhub/singleuser

MAINTAINER Shreyas Cholia <scholia@lbl.gov>

EXPOSE 8888
EXPOSE 5000
EXPOSE 5001
EXPOSE 5002

USER root

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.2 main" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
RUN apt-get update
RUN apt-get install -y cmake  pkg-config libpcre3 libpcre3-dev swig libxml2 libxml2-dev zlib1g zlib1g-dev
RUN apt-get install -y mongodb-org nodejs npm
RUN npm install -g apidoc
RUN mkdir -p /data/db && chown jovyan /data/db

ADD POTCARs /POTCARs
COPY install_openbabel.sh /tmp/install_openbabel.sh
RUN /tmp/install_openbabel.sh

RUN apt-get install -y dvipng
RUN bash -c 'echo -e "Fe2O3-rox\nFe2O3-rox" | passwd'

USER jovyan
WORKDIR /tmp

RUN pip3 install pymongo palettable prettyplotlib
RUN pip3 install pymatgen
RUN pip3 install fireworks
RUN pip3 install custodian
RUN pip3 install pymatgen-db==0.6.1
RUN pip3 install flamyngo==0.4.3

RUN bash -c 'source activate python2 && pip install pymongo palettable prettyplotlib'
RUN bash -c 'source activate python2 && pip install pymatgen'
RUN bash -c 'source activate python2 && pip install fireworks'
RUN bash -c 'source activate python2 && pip install custodian'
RUN bash -c 'source activate python2 && pip install -e git+https://github.com/hackingmaterials/MatMethods.git@v0.21#egg=matmethods'
RUN bash -c 'source activate python2 && pip install pymatgen-db==0.6.1'
RUN bash -c 'source activate python2 && pip install flamyngo==0.4.3'




## Add pythonpath to conda env
RUN mkdir -p /opt/conda/envs/python2/etc/conda/activate.d;  mkdir -p /opt/conda/envs/python2/etc/conda/deactivate.d; \
    echo '#!/bin/sh' > /opt/conda/envs/python2/etc/conda/activate.d/env_vars.sh; \
    echo 'export PYTHONPATH=/usr/local/lib' >> /opt/conda/envs/python2/etc/conda/activate.d/env_vars.sh; \
    echo '#!/bin/sh' > /opt/conda/envs/python2/etc/conda/deactivate.d/env_vars.sh; \
    echo 'unset PYTHONPATH' >> /opt/conda/envs/python2/etc/conda/deactivate.d/env_vars.sh

RUN echo 'export VASP_PSP_DIR=/POTCARs/' >> /home/jovyan/.bashrc
RUN echo 'source activate python2' >> /home/jovyan/.bashrc

COPY kernel.json /usr/local/share/jupyter/kernels/python2/kernel.json

WORKDIR /home/jovyan/work
COPY README.txt /home/jovyan/work/README.txt
# smoke test that it's importable at least
RUN sh /srv/singleuser/singleuser.sh -h
CMD ["sh", "/srv/singleuser/singleuser.sh"]

