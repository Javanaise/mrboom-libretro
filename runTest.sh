#!/usr/bin/env bash
LOG=/tmp/test.log

printError() {
    echo -e "\033[1;31m$1\033[0m"
    echo $1 >> $LOG
}
printOk() {
    echo -e "\033[1;32m$1\033[0m"
    echo $1 >> $LOG
}

runTest() {
  set -x
  echo "run test $a"
  make clean
  make test TESTS=$1 DEBUG=1 -j 4
  echo "make: $?"
if [ $? -eq 0 ]
then
  ./mrboom.out
  git status | grep /tests
  if [ $? -eq 1 ]
  then
    printOk "test success $1"
  else
    printError "test $1 failed: different result"
    #git checkout -- tests
  fi
else
  printError "test $1 failed: build failed"
fi

}
rm -f $LOG 2> /dev/null
OPTIONS_O2="-fthread-jumps -falign-functions  -falign-jumps -falign-loops  -falign-labels -fcaller-saves -fcrossjumping -fcse-follow-jumps  -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize -fdevirtualize-speculatively -fexpensive-optimizations -fgcse  -fgcse-lm  -fhoist-adjacent-loads -finline-small-functions -findirect-inlining -fipa-cp -fipa-cp-alignment -fipa-bit-cp   -fipa-sra   -fipa-icf -fisolate-erroneous-paths-dereference -flra-remat -foptimize-sibling-calls -foptimize-strlen -fpartial-inlining -fpeephole2 -freorder-blocks-algorithm=stc -freorder-blocks-and-partition -freorder-functions -frerun-cse-after-loop  -fsched-interblock  -fsched-spec -fschedule-insns  -fschedule-insns2   -fstore-merging -fstrict-aliasing -fstrict-overflow -ftree-builtin-call-dce ftree-switch-conversion -ftree-tail-merge -fcode-hoisting -ftree-pre -ftree-vrp -fipa-ra"
OPTIONS_O3="-finline-functions -funswitch-loops -fpredictive-commoning -fgcse-after-reload -ftree-loop-vectorize -ftree-loop-distribute-patterns -fsplit-paths -ftree-slp-vectorize -fvect-cost-model -ftree-partial-pre -fpeel-loops -fipa-cp-clone"
for a in "1" $OPTIONS_O2 $OPTIONS_O3
do
  runTest $a
done
