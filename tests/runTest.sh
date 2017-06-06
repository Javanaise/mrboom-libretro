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
  ./mrboom-test.out screenshots 10000 0 5 $1
  convert -flop -rotate 180 tests/screenshots/*.bmp tests/screenshots/mrboom.gif
  gifsicle tests/screenshots/mrboom.gif -O3 --colors 256 > tests/screenshots/mrboom-$1.gif
  rm -f tests/screenshots/*.raw
  rm -f tests/screenshots/*.mem
  rm -f tests/screenshots/*.bmp
  rm -f tests/screenshots/mrboom.gif
}
compile() {
rm -f ./mrboom-test.out
make clean $1
make testtool $1 -j 4 DEBUG=1
if [ -x ./mrboom-test.out ]
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
    exit
fi
case "$1" in
"unittests")
mkdir tests/$1
compile UNITTESTS=1
./mrboom-test.out
    ;;
"statetests")
mkdir tests/$1
compile STATETESTS=1
MAX=25
NB_FRAME_PER_WINDOW=1000
for i in $(seq 0 $MAX);
do
echo $i
NB=`expr $MAX - $i`
echo running test $NB $i
./mrboom-test.out statetests $NB $i $NB_FRAME_PER_WINDOW
checkChange "$NB $i"
done
makeHex
    ;;
"screenshots")
compile SCREENSHOTS=1
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
*)
    echo "wrong argument"
    ;;
esac