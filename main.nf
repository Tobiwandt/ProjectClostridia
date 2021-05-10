#! /usr/bin/env nextflow


/* Verarbeitung der Reads in meiner Doktorarbeit
    fastP zum trimmen der adapter
    fastQC zur Qualitätskontrolle -> multiQC zur Darstellung
    shovill zur Assembly
    quast für die Metrics

*/


params.reads = "$baseDir/*R{1,2}*.fastq.gz"
params.outMultiqc = "MultiQCresults"

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
    tuple val(pair_id), path('*.fastq.gz') into trimmed_reads_ch, trimmed_reads_ch2

    script:
    """
    fastp -i ${reads[0]} -I ${reads[1]} -o trimmed_${reads[0]} -O trimmed_${reads[1]}
    """

}

// creating fastQC reports
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

// collecting the fastQC reports into one multiQC report
process multiqc {

    publishDir params.outMultiqc, mode:'copy'
       
    input:
    path '*' from fastqc_ch.collect()
    
    output:
    path 'multiqc_report.html'
     
    script:
    """
    multiqc . 
    """
} 

// assembling the trimmed reads
process runShovill {
     
    input:
    tuple val(pair_id), path(trimmed_reads) from trimmed_reads_ch2

    output:
    tuple val(pair_id), path('*') into assembled_reads_ch

    script:
    """
    mkdir assembled
    shovill --outdir $baseDir/assembled --namefmt ${trimmed_reads} --R1 ${trimmed_reads[0]} --R2 ${trimmed_reads[1]}
    """

}