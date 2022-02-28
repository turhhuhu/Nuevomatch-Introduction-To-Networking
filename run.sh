#!/bin/bash
path=/home/comp211/Desktop/Networking/nuevomatch
dataset_base_dir=${path}/rulesets

tool_classifier=${path}/bin/tool_classifier.exe
nuevomatch_exe=${path}/bin/nuevomatch.py
tool_trace_generator=${path}/bin/tool_trace_generator.exe
tool_locality=${path}/bin/tool_locality.exe
number_of_packets=700000

function generate_traces_and_skew {
    $tool_trace_generator -f ${dataset_base_dir}/${1}/rules -n $number_of_packets -o ${path}/traces/trace_${1}.txt
    $tool_locality --trace-file ${path}/traces/trace_${1}.txt --output-trace ${path}/traces/trace_skewed_${1}.txt --zipf --alpha 0.99
}

function generate_nuveomatch {
    $nuevomatch_exe -f ${dataset_base_dir}/${1}/rules -o ${path}/models/${1}/nuevomatch_${1}_classifier.data --min-size 64 --max-error 64
}

function generate_tuplemerge {
    $tool_classifier -m tuplemerge -c -in ${dataset_base_dir}/${1}/rules -out ${path}/models/${1}/tuplemerge_${1}_classifier.data 
}

function generate_cutsplit {
    $tool_classifier -m cutsplit -c -in ${dataset_base_dir}/${1}/rules -out ${path}/models/${1}/cutsplit_${1}_classifier.data 
}

function execute_nuveomatch {
    $tool_classifier -m nuevomatch -l -in ${path}/models/${1}/nuevomatch_${1}_classifier.data --trace ${path}/traces/trace_skewed_${1}.txt --parallel 1 --trace-silent --max-subsets 1 --remainder-type $2 --force-remainder-build -v 3 |& tee ${path}/results/${1}/nuevomatch_${1}_w_${2}_res.txt
}

function execute_tuplemerge {
    $tool_classifier -m tuplemerge -l -in ${path}/models/${1}/tuplemerge_${1}_classifier.data --trace ${path}/traces/trace_skewed_${1}.txt --trace-silent -v 3 |& tee ${path}/results/${1}/tuplemerge_${1}_res.txt
}

function execute_cutsplit {
    $tool_classifier -m cutsplit -l -in ${path}/models/${1}/cutsplit_${1}_classifier.data --trace ${path}/traces/trace_skewed_${1}.txt --trace-silent -v 3 |& tee ${path}/results/${1}/cutsplit_${1}_res.txt
}


function execute_script {
    counter=0
    feature_name=$1
    num_of_features=$2
    num_of_rules=$3
    while [ $counter -lt $num_of_features ]; do
        counter=`expr $counter + 1`
        curr_feature=${feature_name}${counter}_seed_${num_of_rules}k
        generate_nuveomatch $curr_feature
        generate_traces_and_skew $curr_feature
        generate_cutsplit $curr_feature
        generate_tuplemerge $curr_feature
        execute_nuveomatch $curr_feature cutsplit
        execute_nuveomatch $curr_feature tuplemerge
        execute_tuplemerge $curr_feature
        execute_cutsplit $curr_feature
    done
}

#execute_script acl 5 500
# execute_script fw 5 500
# execute_script ipc 2 500
# execute_script acl 5 500
# execute_script fw 5 500
execute_script ipc 2 500



