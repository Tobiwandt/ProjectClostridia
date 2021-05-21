#! /usr/bin/env nextflow


/* Verarbeitung der Reads in meiner Doktorarbeit
    fastP zum trimmen der adapter
    fastQC zur Qualitätskontrolle -> multiQC zur Darstellung
    shovill zur Assembly
    quast für die Metrics

    NEEDED: nextflow.config mit params.pathToConda mit path zu conda env mit BUSCO+MultiQC

*/


params.reads = "$baseDir/*R{1,2}*.fastq.gz"
params.outMultiqc = "MultiQCresults"
params.outShovill = "assembled"
params.outQuast = "QuastOut"
params.reference_genome = "E88.fa"
params.outBUSCO = "BUSCOout"

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { read_pairs_ch } 

// trimming the adapters of the reads
process fastp {

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

// assembling the trimmed reads
process shovill {

    publishDir params.outShovill, mode:'copy'
        
    input:
    tuple val(pair_id), path(trimmed_reads) from trimmed_reads_ch2

    output:
    tuple val(pair_id), path('*/*.fa') into assembled_reads_ch, assembled_reads_ch2
    

    script:
    """
    shovill --outdir assembled_$pair_id --R1 ${trimmed_reads[0]} --R2 ${trimmed_reads[1]}
    cd assembled_$pair_id
    mv contigs.fa ${pair_id}.fa
    """

}

// getting the quast metrics of the assemblies
process quast {

    publishDir params.outQuast, mode:'copy'

    input:
    tuple val(pair_id), path(assemblies) from assembled_reads_ch

    output:
    path "*" into quast_metrics_ch


    script:
    """
    quast.py -o quast_${pair_id}_logs *.fa -r $baseDir/$params.reference_genome
    """
}

// getting the BUSCO metrics of the assemblies
process BUSCO {
    conda params.pathToConda

    publishDir params.outBUSCO, mode:'copy'

    input:
    tuple val(pair_id), path(assemblies) from assembled_reads_ch2

    output:
    file "**/*${pair_id}*.txt" into busco_metrics_ch


    script:
    """
    busco -m genome -i *.fa -o busco_${pair_id}_logs -l clostridiales_odb10
    """
}

// collecting the fastQC reports and quast reports into one multiQC report
process multiqc {
    conda params.pathToConda

    publishDir params.outMultiqc, mode:'copy'
       
    input:
    path '*' from fastqc_ch.collect()
    path '*' from quast_metrics_ch.collect()
    path '*' from busco_metrics_ch.collect()
    
    output:
    file "multiqc_report.html" into multiqc_report
    file "multiqc_data"

     
    script:
    """
    multiqc .
    """
} 
