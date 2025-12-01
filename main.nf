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

Channel.fromPath("s3://ncbi-blast-databases/2025-09-16-01-05-02/tsa_nt.02.nhi") | LS

}
