#!/bin/bash

for dir in *shovill

do
    cd $dir/   
    quast.py -o /path/to/shovill/quastOut/$dir contigs.fa
    cd ..
done
