#!/bin/bash

#
# OpenSceneGraph installation script for Ubuntu
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

readPrompt "Should I download OpenSceneGraph-Data to /usr/local/share? " "n"
DATA=$result
if [ $DATA == "y" ]; then
  if [ -d /usr/local/share/OpenSceneGraph/OpenSceneGraph-Data ]; then
    readPrompt "/usr/local/share/OpenSceneGraph/OpenSceneGraph-Data folder already exists, should I overwrite it? " "n"
    DATA=$result
  fi
fi

VERSION="n"
readPrompt "Do you want to install OpenSceneGraph 3.0.0?" "y"
if [ $result == "y" ]; then
  VERSION="3.0.0";
else
  readPrompt "Installing a 2.X.X version of OpenSceneGraph. By default OpenSceneGraph-2.8.3 is installed, do you want to install OpenSceneGraph-2.9.6 instead? " "n"
  if [ $result == "n" ]; then
    VERSION="2.8.3";
  else
    VERSION="2.9.6";
  fi
fi

DELETE_OSG_FOLDER="n"
if [ -d OpenSceneGraph-$VERSION ]; then
  readPrompt "OpenSceneGraph-$VERSION folder already exists, should I overwrite it? " "n"
  DELETE_OSG_FOLDER=$result
fi

eval "echo \"Updating apt database (may ask for your password)\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo apt-get update 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Installing dependencies...\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo apt-get -y install cmake cmake-curses-gui libopenal-dev libopenal1 libcurl4-openssl-dev libpoppler-dev libpoppler-glib-dev librsvg2-dev libgtkglext1 libgtkglext1-dev libgtkglextmm-x11-1.2-0 libgtkglextmm-x11-1.2-dev libwxgtk2.8-dev libopenthreads-dev libtiff4-dev libinventor0 inventor-dev libgif-dev libgif4 libjasper-dev libjasper1 libopenexr-dev libopenexr6 libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev libswscale-dev gstreamer0.10-ffmpeg libxine-dev libquicktime-dev winff dvdrip libavbin-dev libavbin0 libavifile-0.7c2 ffmpeg-dbg libavcodec-dev libavfilter-dev libxine1-ffmpeg moc-ffmpeg-plugin ffmpeg-dbg gstreamer0.10-fluendo-mp3 gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly libavbin-dev libavbin0 libavfilter-dev libavifile-0.7c2 libbabl-0.0-0 libcdaudio1 libmpeg2-4 libmpcdec6 libmp3lame0 libxine1 libxine1-console libxine1-ffmpeg libxine1-misc-plugins libxine1-x moc-ffmpeg-plugin moc mjpegtools ogmtools xine-ui libquicktime-dev winff dvdrip libavbin-dev libavbin0 libavifile-0.7c2 ffmpeg-dbg ffmpeg-dbg ffmpeg libavcodec-dev libavfilter-dev libxine1-ffmpeg moc-ffmpeg-plugin 2>&1 | tee $LOG_FILE $VERBOSE"

if [ $UBUNTU_VERSION == "10.04" -o $UBUNTU_VERSION == "10.10" -o $UBUNTU_VERSION == "11.04" ];then
  eval "sudo apt-get -y install libavdevice52 libavcodec52 libavformat52 libavutil50 libswscale0 libquicktime1 2>&1 | tee $LOG_FILE $VERBOSE"
elif [ $UBUNTU_VERSION == "11.10" -o $UBUNTU_VERSION == "12.04" ];then
  eval "sudo apt-get -y install libavdevice53 libavcodec53 libavformat53 libavutil51 libswscale2 libquicktime2 2>&1 | tee $LOG_FILE $VERBOSE"
fi

if [ $DELETE_OSG_FOLDER == "y" ]; then
  rm -Rf OpenSceneGraph-$VERSION >> /dev/null 2>> /dev/null
fi

if [ ! -e OpenSceneGraph-$VERSION ]; then
  if [ $VERSION == "2.8.3" ]; then
    eval "wget http://www.openscenegraph.org/downloads/stable_releases/OpenSceneGraph-2.8.3/source/OpenSceneGraph-2.8.3.zip 2>&1 | tee $LOG_FILE $VERBOSE"
    eval "unzip OpenSceneGraph-2.8.3.zip 2>&1 | tee $LOG_FILE $VERBOSE"
  elif [ $VERSION == "2.9.6" ]; then
    eval "sudo apt-get install -y subversion 2>&1 | tee $LOG_FILE $VERBOSE"
    eval "svn checkout http://www.openscenegraph.org/svn/osg/OpenSceneGraph/tags/OpenSceneGraph-2.9.6 OpenSceneGraph-2.9.6 2>&1 | tee $LOG_FILE $VERBOSE"
  elif [ $VERSION == "3.0.0" ]; then
    eval "sudo apt-get install -y subversion 2>&1 | tee $LOG_FILE $VERBOSE"
    eval "svn checkout http://www.openscenegraph.org/svn/osg/OpenSceneGraph/tags/OpenSceneGraph-3.0.0 OpenSceneGraph-3.0.0 2>&1 | tee $LOG_FILE $VERBOSE"
  fi
fi

cd OpenSceneGraph-$VERSION
if [ $UBUNTU_VERSION == "11.10" -o $UBUNTU_VERSION == "12.04" ];then
  eval "patch -N -p1 -i ../Patches/OpenSceneGraph/OpenSceneGraph-$VERSION-$UBUNTU_VERSION.patch 2>&1 | tee $LOG_FILE $VERBOSE"
#elif [ $UBUNTU_VERSION == "10.04" -o $UBUNTU_VERSION == "10.10" -o $UBUNTU_VERSION == "11.04" ];then
  #eval "patch -N -p1 -i ../Patches/OpenSceneGraph/OpenSceneGraph-$VERSION-$UBUNTU_VERSION.patch 2>&1 | tee $LOG_FILE $VERBOSE"
fi
if [ ! -e build ]; then mkdir build; fi
cd build
eval "cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-D__STDC_CONSTANT_MACROS 2>&1 | tee $LOG_FILE $VERBOSE"
eval "echo \"Compiling OpenSceneGraph... (this may take LONG)\" 2>&1 | tee $LOG_FILE"
eval "make $CPU_COUNT 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo make install 2>&1 | tee $LOG_FILE $VERBOSE"

OSG_BASHRC=`cat ~/.bashrc | grep osgPlugins`
if [ "$OSG_BASHRC" == "" ]; then
  echo "" >> ~/.bashrc
  echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/local/lib/osgPlugins-$VERSION" >> ~/.bashrc
fi

if [ $DATA == "y" ]; then
  rm -rf /usr/local/share/OpenSceneGraph/OpenSceneGraph-Data >> /dev/null 2>> /dev/null
  eval "sudo svn checkout http://www.openscenegraph.org/svn/osg/OpenSceneGraph-Data/tags/OpenSceneGraph-Data-2.8.0/ /usr/local/share/OpenSceneGraph/OpenSceneGraph-Data 2>&1 | tee $LOG_FILE $VERBOSE"
  OSG_DATA_BASHRC=`cat ~/.bashrc | grep OpenSceneGraph-Data`
  if [ "$OSG_DATA_BASHRC" == "" ]; then
    echo "" >> ~/.bashrc
    echo "export OSG_FILE_PATH=/usr/local/share/OpenSceneGraph/OpenSceneGraph-Data" >> ~/.bashrc
  fi
fi

eval "sudo ldconfig /etc/ld.so.conf 2>&1 | tee $LOG_FILE $VERBOSE"

eval "echo \"Installation complete.\" 2>&1 | tee $LOG_FILE"

exit
