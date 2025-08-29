#!/usr/bin/env nextflow

process UseLock {
    debug true
    script: "use_lock.py"
}

workflow {
    UseLock()
}
