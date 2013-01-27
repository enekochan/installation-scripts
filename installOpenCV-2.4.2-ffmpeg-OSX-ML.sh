#!/bin/bash

#
# OpenCV 2.4.2 installation script for Mac OS X 10.8 with ffmpeg support
#
# Author: enekochan
# URL: http://tech.enekochan.com
#

function readPrompt() {
  while true; do
    read -e -p "$1 (default $2)"": " result
    case $result in
      Y|y ) result="y"; break;;
      N|n ) result="n"; break;;
      "" ) result=`echo $2 | awk '{print substr($0,0,1)}'`; break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

#Create the path for the log file and quote it
#so paths are correct for command line programs
LOG_FILE="\""`pwd`"/install.log\""

#rm $LOG_FILE >> /dev/null 2>> /dev/null

MAC_VERSION=`sw_vers -productVersion`
eval "echo \"Detected Mac OS X "$MAC_VERSION" system...\" 2>&1 | tee $LOG_FILE"

CPU_COUNT=`/usr/sbin/system_profiler SPHardwareDataType | grep "Total Number of Cores" | awk '{print $5}'`
if [ $CPU_COUNT != "1" ]; then
  CPU_COUNT="-j "$CPU_COUNT
else
  CPU_COUNT=""
fi

readPrompt "Do you want to see verbose installation progress? " "n"
VERBOSE=$result
if [ $VERBOSE == "n" ]; then VERBOSE=" > /dev/null"; else VERBOSE=""; fi


DELETE_OPENCV_FOLDER="n"
if [ -d OpenCV-2.4.2 ]; then
  readPrompt "OpenCV-2.4.2 folder already exists, should I overwrite it? " "n"
  DELETE_OPENCV_FOLDER=$result
fi

if [ ! -d ffmpeg ]; then
  mkdir ffmpeg
fi
cd ffmpeg

DELETE_LAME_FOLDER="n"
if [ -d lame-3.99.5 ]; then
  readPrompt "lame-3.99.5 folder already exists, should I overwrite it? " "n"
  DELETE_LAME_FOLDER=$result
fi

DELETE_FAAC_FOLDER="n"
if [ -d faac-1.28 ]; then
  readPrompt "faac-1.28 folder already exists, should I overwrite it? " "n"
  DELETE_FAAC_FOLDER=$result
fi

DELETE_FAAD_FOLDER="n"
if [ -d faad2-2.7 ]; then
  readPrompt "faad2-2.7 folder already exists, should I overwrite it? " "n"
  DELETE_FAAD_FOLDER=$result
fi

DELETE_FFMPEG_FOLDER="n"
if [ -d ffmpeg-0.11.1 ]; then
  readPrompt "ffmpeg-0.11.1 folder already exists, should I overwrite it? " "n"
  DELETE_FFMPEG_FOLDER=$result
fi


eval "echo \"Installing lame-3.99.5...\" 2>&1 | tee $LOG_FILE $VERBOSE"
if [ $DELETE_LAME_FOLDER == "y" ]; then
  rm -Rf lame-3.99.5 >> /dev/null 2>> /dev/null
fi
if [ ! -e lame-3.99.5 ]; then
  if [ ! -e lame-3.99.5.tar.gz ]; then
    eval "curl -L -o lame-3.99.5.tar.gz http://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download 2>&1 | tee $LOG_FILE $VERBOSE"
  fi
  eval "tar xzvf lame-3.99.5.tar.gz 2>&1 | tee $LOG_FILE $VERBOSE"
fi
cd lame-3.99.5
eval "./configure --disable-dependency-tracking CFLAGS=\"-arch i386 -arch x86_64\" LDFLAGS=\"-arch i386 -arch x86_64\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "make $CPU_COUNT 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo make install 2>&1 | tee $LOG_FILE $VERBOSE"
cd ..


eval "echo \"Installing faac-1.28...\" 2>&1 | tee $LOG_FILE $VERBOSE"
if [ $DELETE_FAAC_FOLDER == "y" ]; then
  rm -Rf faac-1.28 >> /dev/null 2>> /dev/null
fi
if [ ! -e faac-1.28 ]; then
  if [ ! -e faac-1.28.tar.gz ]; then
    eval "curl -L -o faac-1.28.tar.gz http://sourceforge.net/projects/faac/files/faac-src/faac-1.28/faac-1.28.tar.gz/download
tar xzvf faac-1.28.tar.gz 2>&1 | tee $LOG_FILE $VERBOSE"
  fi
  eval "tar xzvf faac-1.28.tar.gz 2>&1 | tee $LOG_FILE $VERBOSE"
fi
cd faac-1.28
eval "./configure --disable-dependency-tracking CFLAGS=\"-arch x86_64\" LDFLAGS=\"-arch x86_64\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "make $CPU_COUNT 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo make install 2>&1 | tee $LOG_FILE $VERBOSE"
cd ..


eval "echo \"Installing faad2-2.7...\" 2>&1 | tee $LOG_FILE $VERBOSE"
if [ $DELETE_FAAD_FOLDER == "y" ]; then
  rm -Rf faad2-2.7 >> /dev/null 2>> /dev/null
fi
if [ ! -e faad2-2.7 ]; then
  if [ ! -e faad2-2.7.tar.gz ]; then
    eval "curl -L -o faad2-2.7.tar.gz http://sourceforge.net/projects/faac/files/faad2-src/faad2-2.7/faad2-2.7.tar.gz/download 2>&1 | tee $LOG_FILE $VERBOSE"
  fi
  eval "tar xzvf faad2-2.7.tar.gz 2>&1 | tee $LOG_FILE $VERBOSE"
fi
cd faad2-2.7
eval "./configure --disable-dependency-tracking CFLAGS=\"-arch i386 -arch x86_64\" LDFLAGS=\"-arch i386 -arch x86_64\" 2>&1 | tee $LOG_FILE $VERBOSE"
eval "make $CPU_COUNT 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo make install 2>&1 | tee $LOG_FILE $VERBOSE"
cd ..


eval "echo \"Installing ffmpeg-0.11.1...\" 2>&1 | tee $LOG_FILE $VERBOSE"
if [ $DELETE_FFMPEG_FOLDER == "y" ]; then
  rm -Rf ffmpeg-0.11.1 >> /dev/null 2>> /dev/null
fi
if [ ! -e ffmpeg-0.11.1 ]; then
  if [ ! -e ffmpeg-0.11.1.tar.gz ]; then
    eval "curl -O http://ffmpeg.org/releases/ffmpeg-0.11.1.tar.gz 2>&1 | tee $LOG_FILE $VERBOSE"
  fi
  eval "tar xzvf ffmpeg-0.11.1.tar.gz 2>&1 | tee $LOG_FILE $VERBOSE"
fi
cd ffmpeg-0.11.1
eval "./configure --enable-libmp3lame --enable-libfaac --enable-nonfree --enable-shared --enable-pic --disable-mmx --arch=x86_64 2>&1 | tee $LOG_FILE $VERBOSE"
eval "make $CPU_COUNT 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo make install 2>&1 | tee $LOG_FILE $VERBOSE"
cd ..

cd ..

eval "echo \"Installing OpenCV-2.4.2...\" 2>&1 | tee $LOG_FILE $VERBOSE"
if [ $DELETE_OPENCV_FOLDER == "y" ]; then
  rm -Rf OpenCV-2.4.2 >> /dev/null 2>> /dev/null
fi
if [ ! -e OpenCV-2.4.2 ]; then
  if [ ! -e OpenCV-2.4.2.tar.bz2 ]; then
    eval "curl -L -o OpenCV-2.4.2.tar.bz2 http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/2.4.2/OpenCV-2.4.2.tar.bz2/download 2>&1 | tee $LOG_FILE $VERBOSE"
  fi
  eval "tar xzvf OpenCV-2.4.2.tar.bz2 2>&1 | tee $LOG_FILE $VERBOSE"
fi
cd OpenCV-2.4.2
eval "patch -N -p0 -i `pwd`/../Patches/OpenCV/OpenCV-2.4.2-ffmpeg-OSX-ML.patch 2>&1 | tee $LOG_FILE $VERBOSE"
if [ ! -e build ]; then mkdir build; fi
cd build
eval "cmake .. 2>&1 | tee $LOG_FILE $VERBOSE"
eval "make $CPU_COUNT 2>&1 | tee $LOG_FILE $VERBOSE"
eval "sudo make install 2>&1 | tee $LOG_FILE $VERBOSE"
cd ..


eval "echo \"Installation complete.\" 2>&1 | tee $LOG_FILE"

exit
