params.tasks=65

process LS {

input:
val id
path input_path

output:
path("output*.txt")

script:
"""
echo listing ${input_path}
echo $PWD
ls -l ${input_path} > output_${id}.txt
"""
}

workflow{
   LS(Channel.of(1..params.tasks), file("s3://ngi-igenomes/igenomes/Mus_musculus/UCSC/mm10/Sequence/Bowtie2Index/"))
}
