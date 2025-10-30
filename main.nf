#!/usr/bin/env nextflow

process Dummy {
    debug true

    script:
    "echo 'Hello world!'"
}

workflow {
    log,info "Found params: ${params}"
}
