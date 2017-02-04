#!/usr/bin/env bash
LOG=/tmp/mrboomRegression.log
rm -f $LOG 2> /dev/null
LOCKFILE=./test.lock

printError() {
    echo -e `date` "\033[1;31m$1\033[0m" | tee -a $LOG
}
printOk() {
    echo -e `date` "\033[1;32m$1\033[0m" | tee -a $LOG
}

makeHex() {
    for a in `ls tests/*.mem`
    do
    hexdump $a > $a.hex
    done
}

checkChange() {
    git status | grep /tests
    if [ $? -eq 1 ]
    then
    if [ -f $LOCKFILE ]
    then
    rm -f $LOCKFILE
    printError "test $1 failed: coredump?"
    else
    printOk "test success $1"
    fi
    else
    printError "test $1 failed: different result"
    exit
    fi
}
compile() {
#make clean
make test TESTS=1 -j 4
}

#runTest() {
#  echo "running test $1" | tee -a $LOG
#make clean
#make test TESTS=$1 DEBUG=1 -j 4
#  echo "make: $?" 2>&1 | tee -a $LOG
#if [ $? -eq 0 ]
#then
#  touch $LOCKFILE
#  ./mrboom.out 10 0 | tee -a $LOG
#   makeHex
#
#    checkChange $1
#else
#  printError "test $1 failed: build failed"
#fi
#
#}

rm -f $LOG 2> /dev/null
echo "log: $LOG"

#OPTIONS_O2="-fthread-jumps -falign-functions  -falign-jumps -falign-loops  -falign-labels -fcaller-saves -fcrossjumping -fcse-follow-jumps  -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize -fdevirtualize-speculatively -fexpensive-optimizations -fgcse  -fgcse-lm  -fhoist-adjacent-loads -finline-small-functions -findirect-inlining -fipa-cp -fipa-cp-alignment -fipa-bit-cp   -fipa-sra   -fipa-icf -fisolate-erroneous-paths-dereference -flra-remat -foptimize-sibling-calls -foptimize-strlen -fpartial-inlining -fpeephole2 -freorder-blocks-algorithm=stc -freorder-blocks-and-partition -freorder-functions -frerun-cse-after-loop  -fsched-interblock  -fsched-spec -fschedule-insns  -fschedule-insns2   -fstore-merging -fstrict-aliasing -fstrict-overflow -ftree-builtin-call-dce ftree-switch-conversion -ftree-tail-merge -fcode-hoisting -ftree-pre -ftree-vrp -fipa-ra"
#OPTIONS_O3="-finline-functions -funswitch-loops -fpredictive-commoning -fgcse-after-reload -ftree-loop-vectorize -ftree-loop-distribute-patterns -fsplit-paths -ftree-slp-vectorize -fvect-cost-model -ftree-partial-pre -fpeel-loops -fipa-cp-clone"
#for a in "1"
#$OPTIONS_O2 $OPTIONS_O3
#do
#    runTest $a
#done
#make clean

compile
MAX=25
for i in $(seq 0 $MAX);
do
echo $i
NB=`expr $MAX - $i`
echo running test $NB $i
./mrboom.out $NB $i | tee -a $LOG
makeHex
checkChange "$NB $i"
done


