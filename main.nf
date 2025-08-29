#!/usr/bin/env nextflow

process UseLock {
    script: "use_lock.py"
}

workflow {
    UseLock()
}
