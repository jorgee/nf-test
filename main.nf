#!/usr/bin/env nextflow

params.ttl=1
process Dummy_failed {
    debug true
    pod ttlSecondsAfterFinished: params.ttl

    input:
	val(i)
    path:
	path(*.txt)
    script:
    "echo 'Hello fail $i!'; sleep 10; exit 3"
}

process Dummy_success {
    debug true
    pod ttlSecondsAfterFinished: params.ttl

    input:
        val(i)
    script:
    "echo 'Hello success $i!'"
}

workflow {
    Dummy_success(Channel.from(0..200))
    Dummy_failed(Channel.from(0..2))
}
