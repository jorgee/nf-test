#!/usr/bin/env nextflow

process UseLock {
    script: "use_lock.py"
}

process TestLock {
    debug true
    script: "test-locks.py ."
}

workflow {
    TestLock()
    UseLock()
}
