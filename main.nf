#!/usr/bin/env nextflow

process Dummy {
    debug true

    script:
    "echo 'Hello world!'"
}

workflow {
    log.info "Found params: ${params}"
    log.info "Found a secret.one: ${secrets.one}"
}
