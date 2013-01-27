#!/bin/bash

#
# osgART 2.0 RC3 installation script for Ubuntu
#
# Author: enekochan
# URL: http://tech.enekochan.com
#

function readPrompt() {
  while true; do
    read -e -p "$1"": " -i "$2" result
    case $result in
      Y|y ) result="y"; break;;
      N|n ) result="n"; break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

#Create the path for the log file and quote it
#so paths are correct for command line programs
LOG_FILE="\""`pwd`"/install.log\""

#rm $LOG_FILE >> /dev/null 2>> /dev/null

UBUNTU_VERSION=`cat /etc/lsb-release | grep RELEASE | awk -F= '{print $2}'`
eval "echo \"Detected Ubuntu "$UBUNTU_VERSION" system...\" 2>&1 | tee $LOG_FILE"

CPU_COUNT=`cat /proc/cpuinfo | grep processor | wc -l`
if [ $CPU_COUNT != "1" ]; then
  CPU_COUNT="-j "$CPU_COUNT
else
  CPU_COUNT=""
fi

readPrompt "Do you want to see verbose installation progress? " "n"
VERBOSE=$result
if [ $VERBOSE == "n" ]; then VERBOSE=" > /dev/null"; else VERBOSE=""; fi

DELETE_OSGART_FOLDER="n"
if [ -d osgART_2.0_RC3 ]; then
  readPrompt "osgART_2.0_RC3 folder already exists, should I overwrite it? " "n"
  DELETE_OSGART_FOLDER=$result
fi

readPrompt "Do you want to use arGetTransMatCont instead of arGetTransMat (for smoother pattern detection)? " "y"
CONT=$result

#readPrompt "Do you want to apply the -fpermissive fix patch? " "y"
#PERMISSIVE_FIX=$result
PERMISSIVE_FIX="y"

#eval "echo \"Updating apt database (may ask for your password)\" 2>&1 | tee $LOG_FILE $VERBOSE"
#eval "sudo apt-get update 2>&1 | tee $LOG_FILE $VERBOSE"

#eval "echo \"Installing dependencies...\" 2>&1 | tee $LOG_FILE $VERBOSE"
#eval "sudo apt-get -y install cmake cmake-curses-gui 2>&1 | tee $LOG_FILE $VERBOSE"

if [ $DELETE_OSGART_FOLDER == "y" ]; then
  rm -Rf osgART_2.0_RC3 >> /dev/null 2>> /dev/null
fi

if [ ! -e osgART_2.0_RC3 ]; then
  eval "wget http://www.osgart.org/images/f/fa/Osgart_2.0_rc3.zip -O Osgart_2.0_rc3.zip 2>&1 | tee $LOG_FILE $VERBOSE"
  eval "unzip Osgart_2.0_rc3.zip 2>&1 | tee $LOG_FILE $VERBOSE"
  rm -Rf __MACOSX >> /dev/null 2>> /dev/null
fi

cd osgART_2.0_RC3
if [ $CONT == "y" ]; then
  eval "patch -N -p1 -i ../Patches/osgART/osgART_Cont.patch 2>&1 | tee $LOG_FILE $VERBOSE"
fi
if [ $PERMISSIVE_FIX == "n" ]; then
  PERMISSIVE_FIX="-DCMAKE_CXX_FLAGS=-fpermissive"
else
  eval "patch -N -p1 -i ../Patches/osgART/osgART_Permissive.patch 2>&1 | tee $LOG_FILE $VERBOSE"
  PERMISSIVE_FIX=""
fi
if [ ! -e build ]; then mkdir build; fi
cd build
eval "cmake .. $PERMISSIVE_FIX -DCMAKE_MODULE_LINKER_FLAGS=-lgstreamer-0.10 -DCMAKE_SHARED_LINKER_FLAGS=-lgstreamer-0.10 2>&1 | tee $LOG_FILE $VERBOSE"
eval "echo \"Compiling osgART...\" 2>&1 | tee $LOG_FILE"
eval "make $CPU_COUNT 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo make install 2>&1 | tee $LOG_FILE $VERBOSE"

eval "sudo ldconfig /etc/ld.so.conf 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Installation complete.\" 2>&1 | tee $LOG_FILE"

exit
