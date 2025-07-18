#!/usr/bin/env nextflow

workflow {
    // if(params.optionalFile) {
    //     results = RunWithBothFiles(file(params.requiredFile), file(params.optionalFile))
    // } else { 
    //     results = RunWithoutOptionalFile(file(params.requiredFile))
    // }

    // optional = params.optionalFile ? file(params.optionalFile) : []
    // results = RunWithBothFiles(file(params.requiredFile), optional)


    // optional = Channel.fromPath(params.optionalFile).ifEmpty([])
    // optional = params.optionalFile ? file(params.optionalFile) : []

    results = RunWithBothFiles(file(params.requiredFile), params.optionalFile)


    results.view()
}


process RunWithBothFiles {
    input:
    path(required)
    path(secondary)

    output:
    path("*.txt")

    script:
    "echo 'I found files ${required} and ${secondary}' > results.txt"
}


process RunWithoutOptionalFile {
    input:
    path(required)

    output:
    path("*.txt")

    script:
    "echo 'I found one file: ${required}' > results.txt"
}


