# Build as materialsproject/jupyterhub-singleuser
# Run with the DockerSpawner in JupyterHub

FROM jupyterhub/singleuser@sha256:c39fcdc1913308667c5a53250d1ce7669c0c45099b3544a3f4fbe78721427adb

MAINTAINER Patrick Huck <phuck@lbl.gov>

EXPOSE 8888
EXPOSE 5000
EXPOSE 5001
EXPOSE 5002

USER root

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.2 main" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
RUN apt-get update
RUN apt-get install -y cmake  pkg-config libpcre3 libpcre3-dev swig libxml2 libxml2-dev zlib1g zlib1g-dev
RUN apt-get install -y apt-utils
RUN apt-get install -y mongodb-org curl supervisor
RUN apt-get install -y ssh telnet postfix tree silversearcher-ag vim
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && apt-get update && apt-get install -y nodejs && npm install npm@latest -g
RUN npm install -g git+https://github.com/tschaume/apidoc.git#csrf
RUN npm install -g bower
RUN cp /usr/share/postfix/main.cf.debian /etc/postfix/main.cf
RUN echo 'mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128' >> /etc/postfix/main.cf
RUN echo 'mydestination = localhost' >> /etc/postfix/main.cf
RUN mkdir -p /data/db && chown jovyan /data/db
RUN mkdir -p /var/log/supervisor

ADD POTCARs /POTCARs
COPY install_openbabel.sh /tmp/install_openbabel.sh
RUN /tmp/install_openbabel.sh

RUN apt-get install -y dvipng
#RUN bash -c 'echo -e "Fe2O3-rox\nFe2O3-rox" | passwd'

RUN ln -s /usr/bin/nodejs /usr/local/bin/node
RUN bash -c 'npm cache clean --force'

RUN chown -R jovyan:users /home/jovyan/.config
RUN chown -R jovyan /home/jovyan/.npm

USER jovyan
WORKDIR /tmp

RUN pip3 install --upgrade pip
RUN pip3 install Django==1.8.5
RUN pip3 install pymongo palettable prettyplotlib
RUN pip3 install pymatgen
RUN pip3 install fireworks
RUN pip3 install custodian
RUN pip3 install atomate
RUN pip3 install pymatgen-db==0.6.1
RUN pip3 install flamyngo==0.4.3
RUN conda clean -a -y

RUN bash -c 'source activate python2 && pip install --upgrade pip setuptools'
RUN bash -c 'source activate python2 && pip install --upgrade nbformat'
RUN bash -c 'source activate python2 && pip install -e git+https://github.com/jupyter/notebook.git#egg=notebook'
#RUN bash -c 'source activate python2 && conda install -c conda-forge ipywidgets'
#RUN bash -c 'source activate python2 && pip install -U ipykernel==4.5.1 nbformat notebook ipywidgets'
RUN bash -c 'source activate python2 && pip install Django==1.8.5'
RUN bash -c 'source activate python2 && pip install pymongo palettable prettyplotlib'
RUN bash -c 'source activate python2 && pip install pymatgen'
RUN bash -c 'source activate python2 && pip install fireworks'
RUN bash -c 'source activate python2 && pip install custodian'
RUN bash -c 'source activate python2 && pip install atomate'
#RUN bash -c 'source activate python2 && pip install -e git+https://github.com/jupyter-widgets/ipywidgets.git#egg=ipywidgets'
#RUN bash -c 'source activate python2 && cd /tmp/src/ipywidgets && ./dev-install.sh --sys-prefix'
#RUN bash -c 'source activate python2 && jupyter nbextension enable --py widgetsnbextension --sys-prefix'

RUN bash -c 'source activate python2 && pip install ase xarray igor xrdtools xrayutilities pympler'

WORKDIR /home/jovyan/work
RUN git clone https://github.com/materialsproject/workshop-2017
RUN cd workshop-2017 && git remote set-url --push origin git@github.com:materialsproject/workshop-2017.git
RUN git clone https://github.com/materialsproject/MPContribs.git
WORKDIR /home/jovyan/work/MPContribs
RUN git remote set-url --push origin git@github.com:materialsproject/MPContribs.git
RUN cp db.sqlite3.init db.sqlite3
RUN git submodule init mpcontribs/users && git submodule update mpcontribs/users
RUN cd mpcontribs/users && git remote set-url --push origin git@github.com:materialsproject/MPContribsUsers.git
RUN git submodule init webtzite && git submodule update webtzite
RUN cd webtzite && git remote set-url --push origin git@github.com:materialsproject/webtzite.git
RUN git submodule init docker/jupyterhub && git submodule update docker/jupyterhub
RUN cd /home/jovyan/work/MPContribs/mpcontribs/users && git checkout master
RUN cd /home/jovyan/work/MPContribs/webtzite && git checkout master
RUN bash -c 'source activate python2 && pip install -e .'
RUN bash -c 'cd /home/jovyan/work/MPContribs/docker/jupyterhub && pip3 install -e .'
RUN cd /home/jovyan/work/MPContribs/webtzite && bower install
RUN ln -s /home/jovyan/work/MPContribs/notebooks/profile/custom /home/jovyan/.jupyter/custom

WORKDIR /tmp
RUN bash -c 'source activate python2 && pip install pymatgen-db==0.6.1'
RUN bash -c 'source activate python2 && pip install flamyngo==0.4.3'
RUN bash -c 'source activate python2 && pip install gitpython'
RUN bash -c 'source activate python2 && conda install pyqt=4.11'
RUN bash -c 'source activate python2 && pip install -e git+https://github.com/gabrielelanaro/chemview.git#egg=chemview'
RUN bash -c 'source activate python2 && jupyter nbextension install --sys-prefix --py --symlink chemview && jupyter nbextension enable --sys-prefix --py chemview'
RUN bash -c 'source activate python2 && conda clean -a -y'

RUN pip3 install --upgrade nbformat
RUN pip3 install git+https://github.com/gabrielelanaro/chemview.git#egg=chemview
RUN jupyter nbextension enable widgetsnbextension --user --py
RUN jupyter nbextension install --user --py --symlink chemview
RUN jupyter nbextension enable --user --py  chemview

## Add pythonpath to conda env
RUN mkdir -p /opt/conda/envs/python2/etc/conda/activate.d;  mkdir -p /opt/conda/envs/python2/etc/conda/deactivate.d; \
    echo '#!/bin/sh' > /opt/conda/envs/python2/etc/conda/activate.d/env_vars.sh; \
    echo 'export PYTHONPATH=/usr/local/lib' >> /opt/conda/envs/python2/etc/conda/activate.d/env_vars.sh; \
    echo '#!/bin/sh' > /opt/conda/envs/python2/etc/conda/deactivate.d/env_vars.sh; \
    echo 'unset PYTHONPATH' >> /opt/conda/envs/python2/etc/conda/deactivate.d/env_vars.sh

RUN echo 'source activate python2' >> /home/jovyan/.bashrc
RUN echo 'export EDITOR=vim' >> /home/jovyan/.bashrc
RUN echo 'alias l="ls -ltrh"' >> /home/jovyan/.bashrc
RUN pmg config --add PMG_VASP_PSP_DIR /POTCARs/

RUN git clone https://github.com/amix/vimrc.git /home/jovyan/.vim_runtime
RUN sh /home/jovyan/.vim_runtime/install_basic_vimrc.sh
COPY alphsubs.txt /home/jovyan/.alphsubs.txt
RUN cat /home/jovyan/.alphsubs.txt >> /home/jovyan/.vimrc

RUN mkdir /home/jovyan/.ssh && chown jovyan /home/jovyan/.ssh && chmod 700 /home/jovyan/.ssh
RUN git config --global alias.lg 'log --decorate --oneline --graph --all'
RUN git config --global push.default simple
RUN touch /data/db/mongod.log
COPY kernel.json /usr/local/share/jupyter/kernels/python2/kernel.json

WORKDIR /home/jovyan/work
COPY README.txt /home/jovyan/work/README.txt
user root
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
