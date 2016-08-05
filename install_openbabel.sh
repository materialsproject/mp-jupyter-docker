#!/bin/bash 

cd /usr/local/src
wget http://bitbucket.org/eigen/eigen/get/3.1.2.tar.gz
wget https://sourceforge.net/projects/openbabel/files/openbabel/2.3.2/openbabel-2.3.2.tar.gz


source activate python2

tar -zxvf openbabel-2.3.2.tar.gz
tar -zxvf 3.1.2.tar.gz


mv eigen-eigen* eigen3
mv openbabel-2.3.2 ob-src


cd ob-src/scripts/python; rm openbabel.py openbabel-python.cpp; cd ../../..

sed -i "s/eigen2_define/eigen_define/g" ob-src/scripts/CMakeLists.txt 

mkdir ob-build
cd ob-build

cmake -DPYTHON_BINDINGS=ON -DRUN_SWIG=ON -DEIGEN3_INCLUDE_DIR=../eigen3 ../ob-src 2>&1 | tee cmake.out

sed -i "s?PYTHON_LIBRARY:FILEPATH=/Library/Frameworks/Python.framework/Versions/2.7/lib/libpython2.7.dylib?PYTHON_LIBRARY:FILEPATH=/opt/conda/envs/python2/lib/libpython2.7.so?g" CMakeCache.txt

make -j2
make install
