nextflow.enable.dsl=2

process Dummy {
    cpus 4
    debug true

    input: val(i)

    script:
    "fifo_race.sh ${task.cpus}"
}

workflow {
    Channel.of(1..4)
    | Dummy
}
