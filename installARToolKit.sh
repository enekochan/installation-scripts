#!/bin/bash

function readPrompt() {
  while true; do
    read -e -p "$1"": " -i "$2" result
    case $result in
      [Yy]* ) break;;
      [Nn]* ) break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

#rm install.log >> /dev/null 2>> /dev/null

UBUNTU_VERSION=`cat /etc/lsb-release | grep RELEASE | awk -F= '{print $2}'`
eval "echo \"Detected Ubuntu "$UBUNTU_VERSION" system...\" 2>&1 | tee install.log"

CPU_COUNT=`cat /proc/cpuinfo | grep processor | wc -l`
if [ $CPU_COUNT != "1" ]; then
  CPU_COUNT="-j "$CPU_COUNT
else
  CPU_COUNT=""
fi

#readPrompt "Downlad ARToolKit from the SVN repository? " "n"
#ARTOOLKITSVN=$result
readPrompt "Do you want to see verbose installation progress? " "n"
VERBOSE=$result
if [ $VERBOSE == "n" ]; then VERBOSE=" > /dev/null"; else VERBOSE=""; fi

if [ -d ARToolKit ]; then
  readPrompt "ARToolKit folder already exists, should I overwrite it? " "n"
  DELETE_ARTOOLKIT_FOLDER=$result
fi

readPrompt "Add V4L2 support to ARToolKit? " "y"
V4L2_SUPPORT=$result
readPrompt "Add OpenKinect (libfreenect) support to ARToolKit? " "y"
OPENKINECT_SUPPORT=$result

eval "echo \"Updating apt database (may ask for your password)\" 2>&1 | tee install.log $VERBOSE"
eval "sudo apt-get update 2>&1 | tee install.log $VERBOSE"

eval "echo \"Installing dependencies...\" 2>&1 | tee install.log $VERBOSE"
if [ $UBUNTU_VERSION == "10.04" -o $UBUNTU_VERSION == "10.10" -o $UBUNTU_VERSION == "11.04" -o $UBUNTU_VERSION == "11.10" -o $UBUNTU_VERSION == "12.04" ];then
  eval "sudo apt-get -y install freeglut3-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libxi-dev libxmu-headers libxmu-dev libjpeg62-dev libglib2.0-dev libgtk2.0-dev 2>&1 | tee install.log $VERBOSE"
#elif [ $UBUNTU_VERSION == "XX.XX" ];then
#  echo "XX.XX"
fi

if [ $DELETE_ARTOOLKIT_FOLDER == "y" ]; then
  rm -Rf ARToolKit >> /dev/null 2>> /dev/null
fi

if [ ! -e ARToolKit ]; then
  eval "wget \"http://sourceforge.net/projects/artoolkit/files/artoolkit/2.72.1/ARToolKit-2.72.1.tgz/download\" -O ARToolKit-2.72.1.tgz 2>&1 | tee install.log $VERBOSE"
  eval "tar xzvpf ARToolKit-2.72.1.tgz 2>&1 | tee install.log $VERBOSE"
## Download from the SVN repository
#  eval "sudo apt-get install -y subversion 2>&1 | tee install.log $VERBOSE"
#  eval "svn co https://artoolkit.svn.sourceforge.net/svnroot/artoolkit/trunk ARToolKit 2>&1 | tee install.log $VERBOSE"
#  eval "mv -f ./ARToolKit/artoolkit/* ./ARToolKit 2>&1 | tee install.log $VERBOSE"
#  eval "rm -fR ./ARToolKit/artoolkit 2>&1 | tee install.log $VERBOSE"
###################################################################################
fi

cd ARToolKit

if [ $V4L2_SUPPORT == "y" -a $OPENKINECT_SUPPORT == "y" ]; then
  if [ $UBUNTU_VERSION == "11.04" -o $UBUNTU_VERSION == "11.10" -o $UBUNTU_VERSION == "12.04" ];then
    eval "patch -N -p1 -i ../Patches/ARToolKit/v4l2-Freenect-GST_LIBS.patch 2>&1 | tee install.log $VERBOSE"
  else
    eval "patch -N -p1 -i ../Patches/ARToolKit/v4l2-Freenect.patch 2>&1 | tee install.log $VERBOSE"
  fi
elif [ $V4L2_SUPPORT == "y" ]; then
  if [ $UBUNTU_VERSION == "11.04" -o $UBUNTU_VERSION == "11.10" -o $UBUNTU_VERSION == "12.04" ];then
    eval "patch -N -p1 -i ../Patches/ARToolKit/artk-v4l2-2.72.1.20120613-GST_LIBS.patch 2>&1 | tee install.log $VERBOSE"
  else
    eval "patch -N -p1 -i ../Patches/ARToolKit/artk-v4l2-2.72.1.20120613.patch 2>&1 | tee install.log $VERBOSE"
  fi
elif [ $OPENKINECT_SUPPORT == "y" ]; then
  if [ $UBUNTU_VERSION == "11.04" -o $UBUNTU_VERSION == "11.10" -o $UBUNTU_VERSION == "12.04" ];then
    eval "patch -N -p1 -i ../Patches/ARToolKit/Freenect-GST_LIBS.patch 2>&1 | tee install.log $VERBOSE"
  else
    eval "patch -N -p1 -i ../Patches/ARToolKit/Freenect.patch 2>&1 | tee install.log $VERBOSE"
  fi
else
  if [ $UBUNTU_VERSION == "11.04" -o $UBUNTU_VERSION == "11.10" -o $UBUNTU_VERSION == "12.04" ];then
    eval "patch -N -p1 -i ../Patches/ARToolKit/GST_LIBS.patch 2>&1 | tee install.log $VERBOSE"
  #else
  #  
  fi
fi

echo "Now you will be asked 3 questions to configure ARToolKit."
echo "First: You have to choose the input driver for ARToolKit (probably you should choose \"GStreamer Media Framework\")."
echo "Second: If you want debug simbols answer \"y\" to the next question."
echo "Third: "

./Configure

# This patch is common to all (fixes a problem with osgART)
eval "patch -N -p1 -i ../Patches/ARToolKit/VideoGStreamer.patch 2>&1 | tee install.log $VERBOSE"

echo "Compiling ARToolKit..."
eval "echo \"Compiling ARToolKit...\" 2>&1 | tee install.log"
eval "make $CPU_COUNT 2>&1 | tee install.log $VERBOSE"
echo "Copying libraries and include files to your system..."
eval "sudo cp -R ./include/AR /usr/local/include/ 2>&1 | tee install.log $VERBOSE"
eval "sudo cp ./lib/*.a /usr/local/lib/ 2>&1 | tee install.log $VERBOSE"

rm AR.pc >> /dev/null 2>> /dev/null
touch AR.pc
echo "prefix=/usr/local" >> AR.pc
echo "exec_prefix=\${prefix}" >> AR.pc
echo "libdir=\${exec_prefix}/lib" >> AR.pc
echo "includedir=\${exec_prefix}/include" >> AR.pc
echo "" >> AR.pc
echo "Name: AR" >> AR.pc
echo "Description: ARToolKit libs and includes" >> AR.pc
echo "Version: 2.72.1" >> AR.pc
echo "Libs: -L\${libdir} -lARgsub -lARgsub_lite -lARgsubUtil -lARMulti -lARvideo -lAR" >> AR.pc
echo "Cflags: -I\${includedir}/AR" >> AR.pc

if [ -d "/usr/lib/pkgconfig/" ]; then
  eval "sudo mv AR.pc /usr/lib/pkgconfig/ 2>&1 | tee install.log $VERBOSE"
else
  if [ -d "/usr/lib/pkg-config/" ]; then
    eval "sudo mv AR.pc /usr/lib/pkg-config/ 2>&1 | tee install.log $VERBOSE"
  else
    eval "echo \"Couldn't find path for pkgconfig folder. Continuing anyway...\" 2>&1 | tee install.log"
  fi
fi

if [ -c /dev/video* ]; then
  ARTOOLKIT_BASHRC=`cat ~/.bashrc | grep ARTOOLKIT_CONFIG`
  if [ "$ARTOOLKIT_BASHRC" != "" ]; then
    eval "echo \"ARTOOLKIT_CONFIG variable is already defined in ~/.bashrc\" 2>&1 | tee install.log"
    eval "echo \"Please verify that it is pointing to one of those devices:\" 2>&1 | tee install.log"
    eval "echo \"\" 2>&1 | tee install.log"
    eval "ls -l /dev/video* | awk '{print $9}' 2>&1 | tee install.log"
  else
    CAMERA=""
    eval "echo \"Webcams installed in the system:\" 2>&1 | tee install.log"
    eval "echo \"\" 2>&1 | tee install.log"
    eval "ls -l /dev/video* | awk '{print $9}' 2>&1 | tee install.log"
    eval "echo \"\" 2>&1 | tee install.log"
    while [ $CAMERA -ne $CAMERA 2> /dev/null ] # Is it numeric?
    do
      read -p "Select a camera. For /dev/video0 write 0 and press enter: " CAMERA
      if [ ! -c /dev/video$CAMERA ]; then
        eval "echo \"/dev/video\"$CAMARA\" does not exist. 2>&1 | tee install.log"
        CAMERA=""
      fi
    done
    eval "echo \"\" >> ~/.bashrc 2>&1 | tee install.log"
    echo "export ARTOOLKIT_CONFIG=\"v4l2src device=/dev/video$CAMERA use-fixed-fps=false ! ffmpegcolorspace ! capsfilter caps=video/x-raw-rgb,bpp=24 ! identity name=artoolkit ! fakesink\"" >> ~/.bashrc
  fi
else
  eval "echo \"Couldn't find any webcam connected to the system. You'll have to configure ARTOOLKIT_CONFIG yourself.\" 2>&1 | tee install.log"
fi

eval "sudo ldconfig /etc/ld.so.conf 2>&1 | tee install.log $VERBOSE"

eval "echo \"Installation complete.\" 2>&1 | tee install.log"

exit
