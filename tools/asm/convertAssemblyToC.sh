#!/bin/bash

mrboomPath=~/dev/mrboom-libretro
asm2c=~/dev/asm2c

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

cp -rf $asm2c .
docker build -t docker-build . --progress=plain
id=$(docker create docker-build)
echo "Id:$id"
docker cp $id:/root/src/mrboom/mrboom.h ../../mrboom.h
docker cp $id:/root/src/mrboom/mrboom.c /tmp/mrboom.c
rm -rf asm2c 
cat <<EOF > ../../mrboom.c
//         _________   _________     _________   _________   _________   _________
//      ___\______ /___\____   /_____\____   /___\_____  /___\_____  /___\______ /___
//      \_   |   |   _     |_____/\_   ____    _     |/    _     |/    _   |   |   _/
//       |___|___|___|_____|  sns  |___________|___________|___________|___|___|___|
//      ==[mr.boom]=====================================================[est. 1997]==
//
EOF

cat /tmp/mrboom.c >> ../../mrboom.c

docker rm -v $id

patchMrboom