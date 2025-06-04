nextflow.enable.dsl=2

process Dummy {
    cpus 1
    debug true

    input: val(i)

    script:
    "fifo_race.sh 8"
}

workflow {
    Channel.of(1..20)
    | Dummy
}
