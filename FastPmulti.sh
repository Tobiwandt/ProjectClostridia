#!/bin/bash

for f1 in *R1*.gz

do
    f2=${f1/R1/R2}
    fastp -i $f1 -I $f2 -o "trimmed-$f1" -O "trimmed-$f2"
done