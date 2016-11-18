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
RUN apt-get install -y mongodb-org nodejs npm curl
RUN apt-get install -y ssh telnet postfix tree silversearcher-ag vim
RUN npm install -g git+https://github.com/tschaume/apidoc.git#csrf
RUN npm install -g bower
RUN cp /usr/share/postfix/main.cf.debian /etc/postfix/main.cf
RUN echo 'mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128' >> /etc/postfix/main.cf
RUN echo 'mydestination = localhost' >> /etc/postfix/main.cf
RUN mkdir -p /data/db && chown jovyan /data/db

ADD POTCARs /POTCARs
COPY install_openbabel.sh /tmp/install_openbabel.sh
RUN /tmp/install_openbabel.sh

RUN apt-get install -y dvipng
RUN bash -c 'echo -e "Fe2O3-rox\nFe2O3-rox" | passwd'

RUN ln -s /usr/bin/nodejs /usr/local/bin/node

USER jovyan
WORKDIR /tmp

RUN pip3 install Django==1.8.5
RUN pip3 install pymongo palettable prettyplotlib
RUN pip3 install pymatgen
RUN pip3 install fireworks
RUN pip3 install custodian
RUN pip3 install -e git+https://github.com/hackingmaterials/MatMethods.git@v0.21#egg=matmethods
RUN pip3 install pymatgen-db==0.6.1
RUN pip3 install flamyngo==0.4.3
RUN conda clean -a -y

RUN bash -c 'source activate python2 && pip install Django==1.8.5'
RUN bash -c 'source activate python2 && pip install pymongo palettable prettyplotlib'
RUN bash -c 'source activate python2 && pip install pymatgen'
RUN bash -c 'source activate python2 && pip install fireworks'
RUN bash -c 'source activate python2 && pip install custodian'
RUN bash -c 'source activate python2 && pip install -e git+https://github.com/hackingmaterials/MatMethods.git@v0.21#egg=matmethods'
WORKDIR /home/jovyan/work
RUN bash -c 'source activate python2 && pip install -e git+https://github.com/materialsproject/MPContribs.git@mp-jupyterhub#egg=mpcontribs --src /home/jovyan/work'
RUN cd /home/jovyan/work/mpcontribs && git checkout -b mp-jupyterhub origin/mp-jupyterhub
RUN cp /home/jovyan/work/mpcontribs/db.sqlite3.init /home/jovyan/work/mpcontribs/db.sqlite3
RUN cd /home/jovyan/work/mpcontribs && git remote set-url --push origin git@github.com:materialsproject/MPContribs.git
RUN cd /home/jovyan/work/mpcontribs/webtzite && bower install
WORKDIR /tmp
RUN bash -c 'source activate python2 && pip install pymatgen-db==0.6.1'
RUN bash -c 'source activate python2 && pip install flamyngo==0.4.3'
RUN bash -c 'source activate python2 && conda clean -a -y'

## Add pythonpath to conda env
RUN mkdir -p /opt/conda/envs/python2/etc/conda/activate.d;  mkdir -p /opt/conda/envs/python2/etc/conda/deactivate.d; \
    echo '#!/bin/sh' > /opt/conda/envs/python2/etc/conda/activate.d/env_vars.sh; \
    echo 'export PYTHONPATH=/usr/local/lib' >> /opt/conda/envs/python2/etc/conda/activate.d/env_vars.sh; \
    echo '#!/bin/sh' > /opt/conda/envs/python2/etc/conda/deactivate.d/env_vars.sh; \
    echo 'unset PYTHONPATH' >> /opt/conda/envs/python2/etc/conda/deactivate.d/env_vars.sh

RUN echo 'export VASP_PSP_DIR=/POTCARs/' >> /home/jovyan/.bashrc
RUN echo 'source activate python2' >> /home/jovyan/.bashrc
RUN echo 'export EDITOR=vim' >> /home/jovyan/.bashrc

RUN git clone https://github.com/amix/vimrc.git /home/jovyan/.vim_runtime
RUN sh /home/jovyan/.vim_runtime/install_basic_vimrc.sh

RUN mkdir /home/jovyan/.ssh && chown jovyan /home/jovyan/.ssh && chmod 700 /home/jovyan/.ssh
RUN ssh-keygen -f /home/jovyan/.ssh/id_rsa -t rsa -N '' -b 4096
RUN eval `ssh-agent -s` && ssh-add /home/jovyan/.ssh/id_rsa
RUN git config --global push.default simple
RUN touch /data/db/mongod.log

COPY kernel.json /usr/local/share/jupyter/kernels/python2/kernel.json

WORKDIR /home/jovyan/work
COPY README.txt /home/jovyan/work/README.txt
RUN ln -s /home/jovyan/work/mpcontribs/notebooks/profile/custom /home/jovyan/.jupyter/custom
# smoke test that it's importable at least
COPY singleuser_wrapper.sh /tmp/singleuser_wrapper.sh
CMD ["bash", "-c", "/tmp/singleuser_wrapper.sh"]
