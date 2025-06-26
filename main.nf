include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

workflow {
    validateParameters()
    log.info "Hello, ${params.name}!"
}