#!/bin/bash

#
# libfreenect installation script for Ubuntu
#
# Author: enekochan
# URL: http://tech.enekochan.com
# Source: http://openkinect.org/wiki/Getting_Started#Ubuntu_Manual_Install
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

#UBUNTU_VERSION=`cat /etc/lsb-release | grep RELEASE | awk -F= '{print $2}'`
#eval "echo \"Detected Ubuntu "$UBUNTU_VERSION" system...\" 2>&1 | tee $LOG_FILE"

CPU_COUNT=`cat /proc/cpuinfo | grep processor | wc -l`
if [ $CPU_COUNT != "1" ]; then
  CPU_COUNT="-j "$CPU_COUNT
else
  CPU_COUNT=""
fi

readPrompt "Do you want to see verbose installation progress? " "n"
VERBOSE=$result
if [ $VERBOSE == "n" ]; then VERBOSE=" > /dev/null"; else VERBOSE=""; fi

DELETE_FREENECT_FOLDER="n"
if [ -d libfreenect ]; then
  readPrompt "libfreenect folder already exists, should I overwrite it? " "n"
  DELETE_FREENECT_FOLDER=$result
fi

eval "echo \"Updating apt database (may ask for your password)\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo apt-get update 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Installing dependencies...\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo apt-get -y install git libusb-1.0-0-dev cmake pkg-config build-essential libxmu-dev freeglut3-dev 2>&1 | tee $LOG_FILE $VERBOSE"
#If you are using an old version of Ubuntu install libglut3-dev instead of freeglut3-dev

if [ $DELETE_FREENECT_FOLDER == "y" ]; then
  rm -Rf libfreenect >> /dev/null 2>> /dev/null
fi

if [ ! -e libfreenect ]; then
  eval "git clone git://github.com/OpenKinect/libfreenect.git 2>&1 | tee $LOG_FILE $VERBOSE"
fi
cd libfreenect
if [ ! -e build ]; then mkdir build; fi
cd build
eval "cmake .. 2>&1 | tee $LOG_FILE $VERBOSE"
eval "echo \"Compiling libfreenect...\" 2>&1 | tee $LOG_FILE"
eval "make $CPU_COUNT 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo make install 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo ldconfig /usr/local/lib64/ 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo ldconfig /etc/ld.so.conf 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo adduser $USER video 2>&1 | tee $LOG_FILE $VERBOSE"
touch 51-kinect.rules
echo "# ATTR{product}==\"Xbox NUI Motor\"" >> 51-kinect.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"045e\", ATTR{idProduct}==\"02b0\", MODE=\"0666\"" >> 51-kinect.rules
echo "# ATTR{product}==\"Xbox NUI Audio\"" >> 51-kinect.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"045e\", ATTR{idProduct}==\"02ad\", MODE=\"0666\"" >> 51-kinect.rules
echo "# ATTR{product}==\"Xbox NUI Camera\"" >> 51-kinect.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"045e\", ATTR{idProduct}==\"02ae\", MODE=\"0666\"" >> 51-kinect.rules
sudo mv 51-kinect.rules /etc/udev/rules.d/

eval "sudo ldconfig /etc/ld.so.conf 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Installation complete.\" 2>&1 | tee $LOG_FILE"

# To test the installation plug the Kinect to the USB port and execute:
# /usr/local/bin/glview
