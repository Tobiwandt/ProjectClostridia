#!/bin/bash

for f1 in *R1*.gz

do
    f2=${f1/R1/R2}
    out={$f1}_shovill
    shovill --outdir $out --R1 $f1 --R2 $f2
done
