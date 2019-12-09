#!/usr/bin/env bash
LOG=/tmp/mrboom.log
rm -f $LOG 2> /dev/null
LOCKFILE=./test.lock

printError() {
    echo -e `date` "\033[1;31m$1\033[0m" | tee -a $LOG
}
printOk() {
    echo -e `date` "\033[1;32m$1\033[0m" | tee -a $LOG
}

makeHex() {
    for a in `ls tests/statetests/*.mem`
    do
    hexdump -v -C $a > $a.hex
    done
}

checkChange() {
    if [ `hostname` == "franck-mac-book-air.local" ]
    then
        cd ../..
    fi
    git status | grep tests/
    RESULT=$?

    if [ `hostname` == "franck-mac-book-air.local" ]
    then
        cd -
    fi

    if [ $RESULT -eq 1 ]
    then
        if [ -f $LOCKFILE ]
        then
            rm -f $LOCKFILE
            printError "test $1 failed: coredump?"
        else
            printOk "test success $1"
        fi
    else
        makeHex
        printError "test $1 failed: different result"
        exit
    fi
}

createAnimatedGif() {
  which convert
  if [ $? -ne 0 ]
  then
    echo "missing imagemagick"
    exit 
  fi
  which gifsicle
  if [ $? -ne 0 ]
  then
    echo "missing gifsicle"
    exit 
  fi
  ./mrboomTest.out screenshots 10000 0 5 $1
  convert -flop -rotate 180 tests/screenshots/*.bmp tests/screenshots/mrboom.gif
  gifsicle tests/screenshots/mrboom.gif -O3 --colors 256 > tests/screenshots/mrboom-$1.gif
  rm -f tests/screenshots/*.raw
  rm -f tests/screenshots/*.mem
  rm -f tests/screenshots/*.bmp
  rm -f tests/screenshots/mrboom.gif
}
compile() {
rm -f ./$1.out
make clean
make $* -j 4
if [ -x ./$1.out ]
then
    printOk "Compiled!"
else
    printError "Failed to compile"
    exit
fi
}

rm -f $LOG 2> /dev/null
echo "log: $LOG"

if [ $# -eq 0 ]
  then
    echo "No arguments supplied, run:"
    echo "$0 unittests"
    echo "$0 statetests"
    echo "$0 screenshots"
    echo "$0 ai"
    echo "$0 fps"
    exit
fi
case "$1" in
"unittests")
mkdir tests/$1
compile mrboomTest UNITTESTS=1
./mrboomTest.out
    ;;
"statetests")
mkdir tests/$1
compile mrboomTest STATETESTS=1
MAX=25
NB_FRAME_PER_WINDOW=1000
for i in $(seq 0 $MAX);
do
echo $i
NB=`expr $MAX - $i`
echo running test $NB $i
./mrboomTest.out statetests $NB $i $NB_FRAME_PER_WINDOW
checkChange "$NB $i"
done
makeHex
    ;;
"screenshots")
compile mrboomTest SCREENSHOTS=1
mkdir tests/$1
createAnimatedGif 0
createAnimatedGif 1
createAnimatedGif 2
createAnimatedGif 3
createAnimatedGif 4
createAnimatedGif 5
createAnimatedGif 6
createAnimatedGif 7
    ;;
"fps")
compile mrboomTest FPS=1
./mrboomTest.out statetests  1 0 10000
;;

"ai")
compile mrboom DEBUG=1 LIBSDL2=1
mkdir tests/$1
rm -rf tests/$1/victories.log
   for i in `seq 0 1000`;
        do
                ./mrboom.out -z -a 2 -f 0 -t 0 -l $i -4 -1 -3 $i
                echo $? >> tests/$1/victories.log
        done    
    ;;
*)
    echo "wrong argument"
    ;;
esac
