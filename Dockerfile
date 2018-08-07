# Build as materialsproject/jupyterhub-singleuser
# Run with the DockerSpawner in JupyterHub

FROM jupyterhub/singleuser@sha256:c39fcdc1913308667c5a53250d1ce7669c0c45099b3544a3f4fbe78721427adb
MAINTAINER Patrick Huck <phuck@lbl.gov>
EXPOSE 8888 5000 5001 5002

USER root
WORKDIR /root

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 04EE7237B7D453EC
RUN echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.2 main" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
RUN echo "deb http://cdn-fastly.deb.debian.org/debian sid main" | tee /etc/apt/sources.list.d/sid.list
RUN echo 'APT::Default-Release "jessie";' | tee /etc/apt/apt.conf.d/default-release
RUN apt-get update -y && apt-get install -t sid -y \
      binutils openmpi-bin openmpi-common openssh-client openssh-server libopenmpi3 libopenmpi-dev \
      gcc g++ gfortran libgcrypt20-dev libncurses5-dev make python \
      cmake pkg-config libpcre3 libpcre3-dev swig libxml2 libxml2-dev zlib1g zlib1g-dev apt-utils \
      mongodb-org curl supervisor ssh telnet tree silversearcher-ag vim dvipng less gzip \
      fonts-liberation libappindicator3-1 libnspr4 libnss3 libxss1

RUN apt-get autoremove -y && apt-get autoclean -y

RUN wget https://github.com/dun/munge/releases/download/munge-0.5.13/munge-0.5.13.tar.xz
RUN mkdir -p /root/local/src && cd /root/local/src && \
      tar axvf /root/munge-0.5.13.tar.xz && cd /root/local/src/munge-0.5.13 && \
      ./configure --prefix=/usr/local && make -j && make install && \
      rm -rf /root/local/src/munge-0.5.13 && rm -f /root/munge-0.5.13.tar.xz
RUN wget https://github.com/SchedMD/slurm/archive/slurm-17-11-8-1.tar.gz
RUN cd /root/local/src && tar axvf /root/slurm-17-11-8-1.tar.gz && cd /root/local/src/slurm-slurm-17-11-8-1 && \
      ./configure --prefix=/usr/local && make -j && make install && \
      rm -rf /root/local/src/slurm-slurm-17-11-8-1 && rm -f /root/slurm-17-11-8-1.tar.gz
RUN useradd munge -m && useradd slurm -m && mkdir /tmp/slurm && chown slurm:slurm -R /tmp/slurm
RUN git clone https://github.com/jamesmcclain/SlurmDocker.git && cd SlurmDocker && cp config/slurm.conf.template /usr/local/etc/

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && apt-get update && apt-get install -y nodejs && npm install npm@latest -g
RUN npm install -g git+https://github.com/tschaume/apidoc.git#csrf bower
RUN mkdir -p /data/db && chown jovyan /data/db && mkdir -p /var/log/supervisor
ADD POTCARs /POTCARs
#COPY install_openbabel.sh /tmp/install_openbabel.sh
#RUN /tmp/install_openbabel.sh
RUN ln -s /usr/bin/nodejs /usr/local/bin/node && bash -c 'npm cache clean --force' && \
      chown -R jovyan:users /home/jovyan/.config && chown -R jovyan /home/jovyan/.npm
RUN wget https://chromedriver.storage.googleapis.com/2.35/chromedriver_linux64.zip && \
      unzip chromedriver_linux64.zip && cp chromedriver /usr/bin
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
      dpkg -i google-chrome-stable_current_amd64.deb && apt-get -f install
RUN apt-get install -y apache2-dev

USER jovyan

WORKDIR /home/jovyan
RUN pip3 install -U Jinja2 && pip3 install -e git+https://github.com/tschaume/fireworks.git#egg=fireworks && \
      cd src/fireworks && git remote set-url --push origin git@github.com:tschaume/fireworks.git
RUN pip3 install -e git+https://github.com/materialsproject/maggma.git#egg=maggma && \
      cd src/maggma && git remote set-url --push origin git@github.com:materialsproject/maggma.git
RUN pip3 install pip==9.0.3 atomate && conda clean -a -y
RUN pip3 install -e git+https://github.com/tschaume/jhub_cas_authenticator.git#egg=jhub_cas_authenticator
RUN bash -c 'source activate python2 && pip install pip==9.0.3 && \
      pip install --upgrade setuptools ipykernel notebook scipy && \
      pip install Django==1.8.5 atomate ase xarray igor xrdtools xrayutilities pympler openpyxl selenium'
COPY example_tasks.tar.gz /home/jovyan/example_tasks.tar.gz
RUN wget https://materialsproject.org/static/tasks_jcap.bson.gz

WORKDIR /home/jovyan/work
RUN git clone https://github.com/materialsproject/workshop-2018 && cd workshop-2018 && \
      git remote set-url --push origin git@github.com:materialsproject/workshop-2018.git
RUN git clone https://github.com/materialsproject/MPContribs.git && cd MPContribs && \
      git remote set-url --push origin git@github.com:materialsproject/MPContribs.git

WORKDIR /home/jovyan/work/MPContribs
RUN cp db.sqlite3.init db.sqlite3 && ln -s /home/jovyan/work/MPContribs/notebooks/profile/custom /home/jovyan/.jupyter/custom
RUN git submodule init mpcontribs/users && git submodule update mpcontribs/users && cd mpcontribs/users && \
      git remote set-url --push origin git@github.com:materialsproject/MPContribsUsers.git && git checkout master
RUN git submodule init webtzite && git submodule update webtzite && cd webtzite && \
      git remote set-url --push origin git@github.com:materialsproject/webtzite.git && git checkout master && bower install
RUN git submodule init docker/jupyterhub && git submodule update docker/jupyterhub && cd docker/jupyterhub && pip3 install -e .
RUN bash -c 'source activate python2 && pip install -e . && export MPCONTRIBS_DEBUG="True" && python manage.py migrate'

## Add pythonpath to conda env
RUN mkdir -p /opt/conda/envs/python2/etc/conda/activate.d;  mkdir -p /opt/conda/envs/python2/etc/conda/deactivate.d; \
    echo '#!/bin/sh' > /opt/conda/envs/python2/etc/conda/activate.d/env_vars.sh; \
    echo 'export PYTHONPATH=/usr/local/lib' >> /opt/conda/envs/python2/etc/conda/activate.d/env_vars.sh; \
    echo '#!/bin/sh' > /opt/conda/envs/python2/etc/conda/deactivate.d/env_vars.sh; \
    echo 'unset PYTHONPATH' >> /opt/conda/envs/python2/etc/conda/deactivate.d/env_vars.sh

RUN echo 'source activate python2' >> /home/jovyan/.bashrc; echo 'export EDITOR=vim' >> /home/jovyan/.bashrc; \
      echo 'alias l="ls -ltrh"' >> /home/jovyan/.bashrc; pmg config --add PMG_VASP_PSP_DIR /POTCARs/
RUN git clone https://github.com/amix/vimrc.git /home/jovyan/.vim_runtime && sh /home/jovyan/.vim_runtime/install_basic_vimrc.sh
COPY alphsubs.txt /home/jovyan/.alphsubs.txt
RUN cat /home/jovyan/.alphsubs.txt >> /home/jovyan/.vimrc && \
      mkdir /home/jovyan/.ssh && chown jovyan /home/jovyan/.ssh && chmod 700 /home/jovyan/.ssh
RUN git config --global alias.lg 'log --decorate --oneline --graph --all' && \
      git config --global push.default simple && touch /data/db/mongod.log
COPY kernel.json /usr/local/share/jupyter/kernels/python2/kernel.json

WORKDIR /home/jovyan/work
COPY README.txt /home/jovyan/work/README.txt
user root
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start_slurm.sh /root/start_slurm.sh
RUN chmod +x /root/start_slurm.sh
CMD ["/usr/bin/supervisord"]
