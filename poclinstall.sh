#!/bin/bash

# Script to install POCL (Portable OpenCL) on the Rocket Cluster at the University of Tartu
# Partly follows https://github.com/maedoc/pocl-build/blob/master/CMakeLists.txt

module purge
module load gcc-5.2.0 
module load python-2.7.6
#module load intel_parallel_studio_xe_2015 
module unload gcc-4.8.1
module load m4-1.4.17

cd $HOME

export POCL=pocl
mkdir $POCL
cd $POCL

# Get PKGconfig
# Use this to get correct libraries
wget https://pkg-config.freedesktop.org/releases/pkg-config-0.29.1.tar.gz
tar xvf pkg-config-0.29.1.tar.gz
cd pkg-config-0.29.1
./configure --prefix=$HOME/$POCL/pkgconfiginstall --with-internal-glib
make
make install
export PATH=$HOME/$POCL/pkgconfiginstall/bin:$PATH
cd $HOME
cd $POCL

# Get Libtool
wget ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz
tar xvf libtool-2.4.6.tar.gz
cd libtool-2.4.6
./configure --prefix=$HOME/$POCL/libtoolinstall
make
make install
export PATH=$HOME/$POCL/libtoolinstall/bin:$PATH
export LD_LIBRARY_PATH=$HOME/$POCL/libtoolinstall/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/storage/software/gcc-5.2.0/lib64/pkgconfig/:$PKG_CONFIG_PATH
cd $HOME
cd $POCL

# Get newer version of CMAKE
#
wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz
tar xvf cmake-3.6.2.tar.gz
mkdir buildcmake
cd buildcmake
../cmake-3.6.2/bootstrap --prefix=$HOME/$POCL/cmakeinstall
make 
make install
cd $HOME
cd $POCL

# Get llvm and clang which is required for POCL
# This follows http://clang.llvm.org/get_started.html

# Get llvm
#svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm
#svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_390/final/ llvm
wget llvm.org/releases/3.8.0/llvm-3.8.0.src.tar.xz
tar -xvf llvm-3.8.0.src.tar.xz
mv llvm-3.8.0.src llvm
# checkout clang
cd llvm
cd tools
#svn co http://llvm.org/svn/llvm-project/cfe/trunk clang
#svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_390/final/ clang
wget llvm.org/releases/3.8.0/cfe-3.8.0.src.tar.xz
tar -xvf cfe-3.8.0.src.tar.xz
mv cfe-3.8.0.src clang
cd $HOME
cd $POCL

# Check out extra Clang tools: (optional)

cd llvm
cd tools
cd clang
cd tools
#svn co http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra
#svn co http://llvm.org/svn/llvm-project/clang-tools-extra/tags/RELEASE_390/final extra
wget llvm.org/releases/3.8.0/clang-tools-extra-3.8.0.src.tar.xz
tar -xvf clang-tools-extra-3.8.0.src.tar.xz
mv clang-tools-extra-3.8.0.src extra
cd $HOME
cd $POCL

# Check out Compiler-RT (optional):

cd llvm
cd projects
#svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt
#svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_390/final compiler-rt
wget llvm.org/releases/3.8.0/compiler-rt-3.8.0.src.tar.xz
tar -xvf compiler-rt-3.8.0.src.tar.xz
mv compiler-rt-3.8.0.src compiler-rt
cd $HOME 
cd $POCL

# Build LLVM and Clang, (in-tree build is not supported):

mkdir clangbuild 
cd clangbuild
$HOME/$POCL/cmakeinstall/bin/cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
-DLLVM_ENABLE_EH:BOOLS=ON -DLLVM_ENABLE_RTTI:BOOL=ON \
-DLLVM_ENABLE_ASSERTIONS:BOOL=ON -DCLANG_TOOL_LIBCLANG_BUILD:BOOL=ON \
-DLIBCLANG_BUILD_STATIC:BOOL=ON \
-DCMAKE_INSTALL_PREFIX=${HOME}/${POCL}/clanginstall ../llvm/ 
make REQUIRES_RTTI=1
make install

cd $HOME
cd $POCL
wget https://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.4.tar.gz
tar -xvf hwloc-1.11.4.tar.gz
cd hwloc-1.11.4
./configure --prefix=$HOME/$POCL/hwlocinstall \
 CC=$HOME/$POCL/clanginstall/bin/clang CXX=$HOME/$POCL/clanginstall/bin/clang++
make
make install
export PATH=$HOME/$POCL/hwlocinstall/bin:$PATH
export LD_LIBRARY_PATH=$HOME/$POCL/hwlocinstall/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$HOME/$POCL/hwlocinstall/lib/pkgconfig:$PKG_CONFIG_PATH

cd $HOME
cd $POCL
wget portablecl.org/downloads/pocl-0.13.tar.gz
tar -xvf pocl-0.13.tar.gz
mkdir poclbuild
cd poclbuild
$HOME/$POCL/cmakeinstall/bin/cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
-DCMAKE_C_COMPILER=gcc \
-DCMAKE_CXX_COMPILER=g++ -DCMAKE_INSTALL_PREFIX=${HOME}/${POCL}/poclinstall \
-DPOCL_INSTALL_ICD_VENDORDIR=${HOME}/etc/OpenCL/vendors \ -DLLVM_CONFIG=${HOME}/${POCL}/clanginstall/bin/llvm-config \
-DWITH_LLVM_CONFIG=${HOME}/${POCL}/clanginstall/bin/llvm-config \
-DLTDL_H=${HOME}/${POCL}/libtoolinstall/include/ltdl.h \
-DLTDL_LIB=${HOME}/${POCL}/libtoolinstall/lib/libltdl.a \
../pocl-0.13/
make   
make install
export PATH=$HOME/$POCL/poclinstall/bin:$PATH
export LD_LIBRARY_PATH=$HOME/$POCL/poclinstall/lib64:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$HOME/$POCL/poclinstall/lib64/pkgconfig:$PKG_CONFIG_PATH
