#!/usr/bin/env nextflow

params.ttl=1
process Dummy_failed {
    debug true
    pod ttlSecondsAfterFinished: params.ttl

    input:
	val(i)
    script:
    "echo 'Hello fail $i!'; sleep 10; exit 3"
}

process Dummy_success {
    debug true
    pod ttlSecondsAfterFinished: params.ttl

    input:
        val(i)
    script:
    "echo 'Hello fail $i!'"
}

workflow {
    Dummy_success(Channel.from(0..50))
    Dummy_failed(Channel.from(0..50))
}
