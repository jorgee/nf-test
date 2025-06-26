nextflow.enable.dsl=2

workflow {
    log.info "Params:"
    params.each {
        log.info "${it.key}: ${it.value}"
    }

    Channel.of(params.var_i)
    | Example
}   


process Example {
    input: val(i)
    output: path("*.txt")
    script: "echo 'found: ${i} (${i.getClass()})' > out.txt"
}