include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

workflow {
    validateParameters()
    log.info paramsSummaryLog(workflow)

    log.info "Params: $params"
}
