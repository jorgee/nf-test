nextflow.enable.dsl=2

process Dummy {
    debug true

    script:
    "fifo_race.sh"
}

workflow {
    Dummy()
}
