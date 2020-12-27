#!/bin/bash

asm2c=~/dev/asm2c
asm2cBIN=${asm2c}/.build/debug/asm2c
resourcePath=${asm2c}/Resources
exitOnError=1
swiftBin=/usr/bin/swift
mrboomPath=~/dev/mrboom-libretro

printError() {
    echo -e "\033[1;31m$1\033[0m"
    if [ $exitOnError == 1 ]
    then
        exit
    fi
}
printOk() {
    echo -e "\033[1;32m$1\033[0m"
}

createSwiftScript() {
    if [[ -x "$swiftBin" ]]
    then
    $swiftBin build
    else
    echo "File '$swiftBin' is not executable or found"
    fi
}

patchMrboom() {
    file=${mrboomPath}/mrboom.c
    file2=${mrboomPath}/mrboom_data.c
    head -10 $file > $file2
    cat $file | grep "define " | grep -v INITVAR >> $file2
    tmpFile=/tmp/mrboom.c
    cp -f $file $tmpFile
    rm -f $file
    while IFS= read -r line; 
    do 
        if [ "Memory m = {" == "$line" ]
        then
            file=$file2
        fi
        echo "$line" >> $file; 
    done < $tmpFile
}


runSwiftScript() {
    filename=$(basename "$1")
    extension="${filename##*.}"
    filename="${filename%.*}"
    mkdir $filename 2> /dev/null

    if [[ -x $asm2cBIN ]]
    then
        echo running $asm2cBIN `pwd`/$1
        if [ $2 == "silent" ]
        then
            $asm2cBIN `pwd`/$1 $resourcePath > /tmp/test.$$
        else
            $asm2cBIN `pwd`/$1 $resourcePath
        fi
        if [ $? -ne 0 ]
        then
            cat /tmp/test.$$ 2> /dev/null
            rm -f /tmp/test.$$ 2> /dev/null
            printError "Error running $asm2cBIN `pwd`/$1"
        fi
        rm -f /tmp/test.$$
    else
        echo "$asm2cBIN not found"
    fi
}

checkFileExists() {
     if [ ! -e "$1" ]
     then
        printError "file $1 doesnt exist"
     fi
}

cd src 

createSwiftScript

runSwiftScript mrboom.asm nosilent

mv -f mrboom/mrboom.c /tmp/mrboom.c

cat <<EOF > mrboom/mrboom.c
//         _________   _________     _________   _________   _________   _________
//      ___\______ /___\____   /_____\____   /___\_____  /___\_____  /___\______ /___
//      \_   |   |   _     |_____/\_   ____    _     |/    _     |/    _   |   |   _/
//       |___|___|___|_____|  sns  |___________|___________|___________|___|___|___|
//      ==[mr.boom]=====================================================[est. 1997]==
//
EOF

cat /tmp/mrboom.c >> mrboom/mrboom.c
rm mrboom/mrboom.nomacro

patchMrboom

