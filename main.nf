nextflow.enable.dsl=2

workflow {
    log.info "Params:"
    params.each {
        log.info "${it.key}: ${it.value}"
    }
}
