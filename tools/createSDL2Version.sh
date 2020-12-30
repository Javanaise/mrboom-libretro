#!/bin/bash
set -x
COPYFILE_DISABLE=1; export COPYFILE_DISABLE

if [ "$#" -ne 1 ]; then
    echo "version missing"
    exit
fi
VERSION=$1
echo version $VERSION
rm -rf ../mrboom_libretro.dylib
rm -rf ../mrboom
cd ..
make clean
DEST=/tmp/mrboom.$$

VERSION_VIRGULES=${VERSION//./,}

cat > Assets/mrboom.rc <<EOF 
id ICON "./mrboom.ico"
1 VERSIONINFO
FILEVERSION     $VERSION_VIRGULES,0,0
PRODUCTVERSION  $VERSION_VIRGULES,0,0
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "080904E4"
    BEGIN
      VALUE "CompanyName", "Remdy Software"
      VALUE "FileDescription", "MrBoom"
      VALUE "FileVersion", "$VERSION"
      VALUE "InternalName", "mrboom"
      VALUE "LegalCopyright", "Remdy Software"
      VALUE "OriginalFilename", "MrBoom.exe"
      VALUE "ProductName", "MrBoom"
      VALUE "ProductVersion", "$VERSION"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x809, 1252
  END
END
EOF

mkdir $DEST
mkdir $DEST/MrBoom-src-$VERSION
cp -rf * $DEST/MrBoom-src-$VERSION/
rm -rf $DEST/MrBoom-src-$VERSION/sdl $DEST/MrBoom-src-$VERSION/tools $DEST/MrBoom-src-$VERSION/libretro $DEST/MrBoom-src-$VERSION/*.yml $DEST/MrBoom-src-$VERSION/link.T
cd $DEST
rm ~/Downloads/MrBoom-src-$VERSION.tar*
tar cf ~/Downloads/MrBoom-src-$VERSION.tar *
gzip -9 ~/Downloads/MrBoom-src-$VERSION.tar
rm -rf DEST