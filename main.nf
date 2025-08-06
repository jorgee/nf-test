#!/usr/bin/env nextflow

process Dummy {
    debug true

    script:
    "echo 'Hello world!'"
}

workflow {
    log.info "Found params: ${params}"
    log.info "Found a secrets: ${secrets} (${secrets.getClass()})"
    log.info "Found a secrets.one: ${secrets.one}"
}
