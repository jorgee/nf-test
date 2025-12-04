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

Channel.fromPath("s3://ngi-igenomes/igenomes/Mus_musculus/UCSC/mm10/Sequence/Bowtie2Index/") | LS

}
