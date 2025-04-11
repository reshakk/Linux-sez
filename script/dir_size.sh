#!/bin/bash

echo "==================================" >> dir_size.txt
echo "Dirs size `date +"%Y-%m-%d_%H-%M"`" >> dir_size.txt
echo "==================================" >> dir_size.txt
du -hs * | sort -hr | head -10 >> dir_size.txt
