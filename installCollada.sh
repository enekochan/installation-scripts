#!/bin/bash

#
# Collada-DOM installation script for Ubuntu
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

DELETE_COLLADA_FOLDER="n"
if [ -d collada-dom ]; then
  readPrompt "collada-dom folder already exists, should I overwrite it? " "n"
  DELETE_COLLADA_FOLDER=$result
fi

eval "echo \"Updating apt database (may ask for your password)\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo apt-get update 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Installing dependencies...\" 2>&1 | tee $LOG_FILE $VERBOSE"
if [ $UBUNTU_VERSION == "10.04" ];then
  eval "sudo apt-get -y install libboost1.40-dev libpcre++-dev nvidia-cg-toolkit libboost-filesystem1.40-dev libglut3-dev 2>&1 | tee $LOG_FILE $VERBOSE"
elif [ $UBUNTU_VERSION == "10.10" -o $UBUNTU_VERSION == "11.04" ];then
  eval "sudo apt-get -y install libboost1.42-dev libpcre++-dev nvidia-cg-toolkit libboost-filesystem1.42-dev libglut3-dev 2>&1 | tee $LOG_FILE $VERBOSE"
elif [ $UBUNTU_VERSION == "11.10" -o $UBUNTU_VERSION == "12.04" ];then
  eval "sudo apt-get -y install libboost1.46-dev libpcre++-dev nvidia-cg-toolkit libboost-filesystem1.46-dev freeglut3-dev 2>&1 | tee $LOG_FILE $VERBOSE"
fi

if [ $DELETE_COLLADA_FOLDER == "y" ]; then
  rm -Rf collada-dom >> /dev/null 2>> /dev/null
fi

if [ ! -e collada-dom ]; then
  eval "sudo apt-get install -y subversion 2>&1 | tee $LOG_FILE $VERBOSE"
  #
  # NOTE: Trunk version fails to compile rt and fx although they are not necessary
  #
  # Version on 2011/03/12
  eval "svn co -r {20110312} https://collada-dom.svn.sourceforge.net/svnroot/collada-dom/trunk collada-dom 2>&1 | tee $LOG_FILE $VERBOSE"
  # Latest official release DOM 2.2
  #eval "svn co https://collada-dom.svn.sourceforge.net/svnroot/collada-dom/tags/2.2 collada-dom 2>&1 | tee $LOG_FILE $VERBOSE"
  # Trunk (does not work with OpenSceneGraph osgdb_dae plugin)
  #eval "svn co https://collada-dom.svn.sourceforge.net/svnroot/collada-dom/trunk collada-dom 2>&1 | tee $LOG_FILE $VERBOSE"
fi

cd collada-dom
eval "echo \"Compiling Collada DOM...\" 2>&1 | tee $LOG_FILE"
eval "make $CPU_COUNT os=linux project=minizip -C dom 2>&1 | tee $LOG_FILE $VERBOSE"
eval "make $CPU_COUNT os=linux project=dom -C dom 2>&1 | tee $LOG_FILE $VERBOSE"
#eval "make $CPU_COUNT os=linux project=rt -C rt 2>&1 | tee $LOG_FILE $VERBOSE"
#eval "make $CPU_COUNT os=linux project=fx -C fx 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo cp dom/build/linux-1.4/libminizip.* /usr/local/lib/ 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo cp dom/build/linux-1.4/libcollada14dom.* /usr/local/lib/ 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo cp -R dom/include /usr/local/include/colladadom 2>&1 | tee $LOG_FILE $VERBOSE"
#eval "sudo cp rt/build/linux-1.4/libcollada14rt.* /usr/local/lib/ 2>&1 | tee $LOG_FILE $VERBOSE"
#eval "sudo cp fx/build/linux-1.4/libcollada14fx.* /usr/local/lib/ 2>&1 | tee $LOG_FILE $VERBOSE"

eval "sudo ldconfig /etc/ld.so.conf 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Installation complete.\" 2>&1 | tee $LOG_FILE"

exit
