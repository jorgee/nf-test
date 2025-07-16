#!/usr/bin/env nextflow

process Dummy {
    debug true

    script:
    "echo 'Hello world!'"
}

workflow {
    Dummy()
}
