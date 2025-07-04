nextflow.enable.dsl=2

process Dummy {
    debug true

    script:
    "echo 'Hello world!'"
}

workflow {
    log.info "Hello ${params.name}"
    // Dummy()
}
