process LS {

input:
val id
path input_path

output:
path("output*.txt")

script:
"""
echo listing ${input_path]
ls -l ${input_path} > output_${id}.txt
"""
}

workflow{
   LS(Channel.of(1..65), file("s3://ngi-igenomes/igenomes/Mus_musculus/UCSC/mm10/Sequence/Bowtie2Index/"))
}
