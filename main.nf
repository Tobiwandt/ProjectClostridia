#! /usr/bin/env nextflow


/* Verarbeitung der Reads in meiner Doktorarbeit
    fastP zum trimmen der adapter
    fastQC zur Qualitätskontrolle -> multiQC zur Darstellung
    shovill zur Assembly
    quast für die Metrik

*/


params.reads = "$baseDir/*R{1,2}*.fastq.gz"
params.outdir = "results"

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { read_pairs_ch } 

// trimming the adapters of the reads
process runFastp {

    publishDir "$baseDir/trimmed", mode: 'copy'

    input:
    tuple val(pair_id), path(reads) from read_pairs_ch

    output:
    tuple val(pair_id), path('*.fastq.gz') into trimmed_reads_ch

    script:
    """
    fastp -i ${reads[0]} -I ${reads[1]} -o trimmed_${reads[0]} -O trimmed_${reads[1]}
    """

}

process fastqc {
    tag "FASTQC on $sample_id"

    input:
    tuple sample_id, path(reads) from trimmed_reads_ch

    output:
    path "fastqc_${sample_id}_logs" into fastqc_ch


    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """  
}  

process multiqc {

    publishDir params.outdir, mode:'copy'
       
    input:
    path '*' from fastqc_ch.collect()
    
    output:
    path 'multiqc_report.html'
     
    script:
    """
    multiqc . 
    """
} 
