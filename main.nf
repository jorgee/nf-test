nextflow.enable.dsl=2

process Dummy {
    debug true

    script:
    "echo 'Process labels: ${task.resourceLabels}'"
}

workflow {
    log.info "Params: ${params}"
    Dummy()
}
