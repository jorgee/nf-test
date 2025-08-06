#!/usr/bin/env nextflow

process Dummy {
    secret "one"
    debug true

    script:
    "echo \"Found secret: \${one}\""
}

workflow {
    Dummy()
    log.info "Found params: ${params}"
    log.info "Found a secrets: ${secrets} (${secrets.getClass()})"
    log.info "Found a secrets.one: ${secrets.one}"
}
