#!/bin/bash

#
# OpenNI, Sensor Kinect (avin2) and NITE installation script for Ubuntu
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

if [ ! -d OpenNI ]; then
  mkdir OpenNI
fi

cd OpenNI

#Create the path for the log file and quote it
#so paths are correct for command line programs
LOG_FILE="\""`pwd`"/install.log\""

#rm $LOG_FILE >> /dev/null 2>> /dev/null

#UBUNTU_VERSION=`cat /etc/lsb-release | grep RELEASE | awk -F= '{print $2}'`
#eval "echo \"Detected Ubuntu "$UBUNTU_VERSION" system...\" 2>&1 | tee $LOG_FILE"

ARCH=`uname -m`
eval "echo \"Detected "$ARCH" architecture...\" 2>&1 | tee $LOG_FILE"
if [ $ARCH == "x86_64" ]; then
  ARCH="x64"
else
  ARCH="x86"
fi

readPrompt "Do you want to see verbose installation progress? " "n"
VERBOSE=$result
if [ $VERBOSE == "n" ]; then VERBOSE=" > /dev/null"; else VERBOSE=""; fi

UNLOAD_GSPCA_KINECT_MODULE="n"
BLACKLIST_GSPCA_KINECT_MODULE="n"
if [ `lsmod | grep gspca_kinect`"" != "" ]; then
  echo "The gspca_kinect module is currently loaded (it enables the use of Kinect as a webcam)."
  echo "It should be unloaded before running any OpenNI or NITE program."
  readPrompt "Should I unload it when installation finishes? " "y"
  UNLOAD_GSPCA_KINECT_MODULE=$result
  eval "echo \"If you want to keep it unloaded forever after the next reboot add the entry 'blacklist gspca_kinect' to the file /etc/modprobe.d/blacklist.conf\" 2>&1 | tee $LOG_FILE $VERBOSE"
  readPrompt "Should I blacklist it for the next reboot when installation finishes?" "y"
  BLACKLIST_GSPCA_KINECT_MODULE=$result
fi

DELETE_OPENNI_FOLDER="n"
if [ -d OpenNI* ]; then
  readPrompt "OpenNI folder already exists, should I overwrite it? " "n"
  DELETE_OPENNI_FOLDER=$result
fi
DELETE_SENSOR_FOLDER="n"
if [ -d SensorKinect ]; then
  readPrompt "SensorKinect folder already exists, should I overwrite it? " "n"
  DELETE_SENSOR_FOLDER=$result
fi
DELETE_NITE_FOLDER="n"
if [ -d NITE-Bin* ]; then
  readPrompt "NITE folder already exists, should I overwrite it? " "n"
  DELETE_NITE_FOLDER=$result
fi

COMPILE_OPENNI="y"
#readPrompt "Should I compile OpenNI from source (otherwise a binary version will be downloaded)? " "n"
#COMPILE_OPENNI=$result

eval "echo \"Updating apt database (may ask for your password)\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo apt-get update 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Installing dependencies...\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo apt-get -y install git-core build-essential libusb-1.0-0-dev libtool freeglut3-dev automake autoconf doxygen 2>&1 | tee $LOG_FILE $VERBOSE"

if [ $DELETE_OPENNI_FOLDER == "y" ]; then
  rm -Rf `ls | grep OpenNI` >> /dev/null 2>> /dev/null
fi

if [ $COMPILE_OPENNI == "y" ]; then
  if [ ! -e `ls | grep OpenNI`"" ]; then
    #Stable branch doesn't work with avin2 SensorKinect
    eval "git clone https://github.com/OpenNI/OpenNI.git -b unstable 2>&1 | tee $LOG_FILE $VERBOSE"
    #eval "wget https://github.com/OpenNI/OpenNI/tarball/unstable -O OpenNI.tar.gz 2>&1 | tee $LOG_FILE $VERBOSE"
    #tar xzvpf OpenNI.tar.gz
  fi
  cd `ls | grep OpenNI`/Platform/Linux/CreateRedist
  eval "sudo ./RedistMaker 2>&1 | tee $LOG_FILE $VERBOSE"
  cd ../Redist
  cd `ls | grep OpenNI-Bin`
  eval "sudo ./install.sh 2>&1 | tee $LOG_FILE $VERBOSE"
  cd ../../../../../
else
  #Don't use this
  eval "wget http://www.openni.org/downloads/openni-bin-dev-linux-"$ARCH"-v1.5.2.23.tar.bz2 2>&1 | tee $LOG_FILE $VERBOSE"
  eval "tar jxvpf openni-bin-dev-linux-"$ARCH"-v1.5.2.23.tar.bz2 2>&1 | tee $LOG_FILE $VERBOSE"
  cd `ls | grep OpenNI-Bin`
  eval "sudo ./install.sh 2>&1 | tee $LOG_FILE $VERBOSE"
  cd ..
fi

if [ $DELETE_SENSOR_FOLDER == "y" ]; then
  rm -Rf SensorKinect >> /dev/null 2>> /dev/null
fi
if [ ! -e SensorKinect ]; then
  eval "git clone https://github.com/avin2/SensorKinect.git 2>&1 | tee $LOG_FILE $VERBOSE"
fi

cd SensorKinect/Platform/Linux/CreateRedist
eval "sudo ./RedistMaker 2>&1 | tee $LOG_FILE $VERBOSE"
cd ../Redist/`ls ../Redist | grep Sensor-Bin`
eval "sudo ./install.sh 2>&1 | tee $LOG_FILE $VERBOSE"
cd ../../../../../

if [ $DELETE_NITE_FOLDER == "y" ]; then
  rm -Rf `ls | grep NITE-Bin` >> /dev/null 2>> /dev/null
fi
if [ ! -e `ls | grep NITE-Bin`"" ]; then
  eval "wget http://www.openni.org/downloads/nite-bin-linux-"$ARCH"-v1.5.2.21.tar.bz2 2>&1 | tee $LOG_FILE $VERBOSE"
  eval "tar jxvpf nite-bin-linux-"$ARCH"-v1.5.2.21.tar.bz2 2>&1 | tee $LOG_FILE $VERBOSE"
fi

cd `ls | grep NITE-Bin`
cd Data
#Write the license key in the files
sed 's/insert key here/0KOIk2JeIBYClPWVnMoRKn5cdY4=/g' Sample-Scene.xml > Sample-Scene.xml.new
sed 's/insert key here/0KOIk2JeIBYClPWVnMoRKn5cdY4=/g' Sample-Tracking.xml > Sample-Tracking.xml.new
sed 's/insert key here/0KOIk2JeIBYClPWVnMoRKn5cdY4=/g' Sample-User.xml > Sample-User.xml.new
rm Sample-Scene.xml Sample-Tracking.xml Sample-User.xml
mv Sample-Scene.xml.new Sample-Scene.xml
mv Sample-Tracking.xml.new Sample-Tracking.xml
mv Sample-User.xml.new Sample-User.xml
eval "niLicense PrimeSense 0KOIk2JeIBYClPWVnMoRKn5cdY4= 2>&1 | tee $LOG_FILE $VERBOSE"
cd ..
eval "sudo ./install.sh 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo cp -R Data /usr/etc/primesense 2>&1 | tee $LOG_FILE $VERBOSE"
cd ..

if [ $UNLOAD_GSPCA_KINECT_MODULE == "y" ]; then
  eval "echo \"Unloading gspca_kinect...\" 2>&1 | tee $LOG_FILE $VERBOSE"
  eval "sudo rmmod gspca_kinect 2>&1 | tee $LOG_FILE $VERBOSE"
  if [ `lsmod | grep gspca_kinect`"" != "" ]; then
    readPrompt "gspca_kinect didn't unload, should I force it to unload? " "n"
    if [ $result == "y" ]; then eval "sudo rmmod -f gspca_kinect 2>&1 | tee $LOG_FILE $VERBOSE"; fi
  fi
fi

if [ $BLACKLIST_GSPCA_KINECT_MODULE == "y" ]; then
  eval "echo \"Adding gspca_kinect to the blacklist...\" 2>&1 | tee $LOG_FILE $VERBOSE"
  eval "sudo sh -c 'echo \"\" >> /etc/modprobe.d/blacklist.conf' 2>&1 | tee $LOG_FILE $VERBOSE"
  eval "sudo sh -c 'echo \"# Prevents OpenNI and NITE applications from working properly\" >> /etc/modprobe.d/blacklist.conf' 2>&1 | tee $LOG_FILE $VERBOSE"
  eval "sudo sh -c 'echo \"blacklist gspca_kinect\" >> /etc/modprobe.d/blacklist.conf' 2>&1 | tee $LOG_FILE $VERBOSE"
fi

eval "sudo ldconfig /etc/ld.so.conf 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo ldconfig /usr/local/lib64/ 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Unplug and plug again the Kinect so the new udev rules can take effect.\" 2>&1 | tee $LOG_FILE $VERBOSE"

# To test OpenNI installation execute:
# ./OpenNI/`ls | grep OpenNI`/Platform/Linux/Bin/x86-Release/Sample-NiUserTracker

# To test NITE installation execute:
# ./OpenNI/`ls | grep NITE-Bin`/Samples/Bin/x86-Release/Sample-TrackPad

