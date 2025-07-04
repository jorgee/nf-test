nextflow.enable.dsl=2

workflow {
    log.info "Hello ${params.name} from ${params.location}"
}
