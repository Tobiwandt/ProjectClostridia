#! /usr/bin/env nextflow

/* Abgleichung von Proteinen in den Assemblies
    Prodigal zur Annotation und Protein-Translation
    mmseqs2 zum Suchen 

    NEEDED: assemblies Ordner in dem die assemblies.fasta sind
            proteins Ordner in dem die Proteine sind, nach denen man suchen will
            (oder halt in params. hier drunter ändern)

*/


params.assemblies = "$baseDir/assemblies/**.fasta"
params.proteins = "$baseDir/proteins/*.fasta"


Channel
    .fromPath( params.assemblies )
    .ifEmpty { error "Cannot find any reads matching: ${params.assemblies}" }
    .set { assemblies_ch } 


// annotating the assemblies
process prodigal {

    publishDir "$baseDir/prodigal", mode: 'copy'

    input:
    path(assembly) from assemblies_ch

    output:
    file('prot_*.fa*') into prot_translations_ch

    script:
    """
    prodigal -i ${assembly} -o out_${assembly} -a prot_transl_${assembly}
    """

}

process createProteinDB {

    input:
    
    output:
    path('prot*') into prot_db_ch
    
    script:
    """
    mmseqs createdb ${params.proteins} protDB
    """
    
}


process createDB {

    publishDir "$baseDir/DB", mode: 'copy'

    input:
    file(transla) from prot_translations_ch    

    output:
    path('*transl*') into transla_db_ch

    script:
    """
    mmseqs createdb ${transla} ${transla}DB
    """
    
}


process mmseqs2 {

    publishDir "$baseDir/mmseqs2", mode: 'copy'

    input:
    file(transla_db) from transla_db_ch
    path(prot_db) from prot_db_ch

    output:
    path('*') into search_ch

    script:
    """    
    mmseqs search ${prot_db[0]} ${transla_db[0]} ${transla_db[0]}resultDB tmp
    mmseqs convertalis ${prot_db[0]} ${transla_db[0]} ${transla_db[0]}resultDB ${transla_db[0]}resultDB.m8
    """

}