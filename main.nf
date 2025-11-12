process LS {

input: 
path input_path

output:
path("output.txt")

script:
"""
ls -l $input_path > output.txt
"""
}

workflow{

Channel.fromPath("https://pub-349bcb8decb44bf7acbddf90b270a061.r2.dev/HCC1395-SRA/25.0/data/wgts/fastq/HCC1395__tumour_wgs__WGS_IL_T_1__SRR7890856__subsampled__split_1.1.fastq.gz") | LS

}
