#!/bin/sh
choco install 7zip.install

for file in *.7z
do
  7z e "$file"
done
