params.input='s3://ncbi-blast-databases/2025-09-16-01-05-02/'
include { validateParameters } from 'plugin/nf-schema'
process LS {

input: 
path input_path

output:
path("output.txt")

script:
"""
echo listing $input_path
ls -l $input_path > output.txt
"""
}

workflow{
validateParameters()
Channel.fromPath(params.input) | LS

}
