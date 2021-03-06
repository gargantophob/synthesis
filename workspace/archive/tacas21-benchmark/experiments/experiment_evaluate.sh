#!/bin/bash

# experiment counters
export experiment_current=0
export experiment_total=73

# setting this value to >1 will enable concurrent evaluation of experiments
export threads=$(nproc)

## helper functions ############################################################

# wait until the number of child processes is at most the number of available cores
function experiments_wait() {
    local cores=$1
    children=$(pgrep -c -P$$)

    while [ ${cores} -le ${children} ]; do
        wait -n 1
        children=$(pgrep -c -P$$)
    done
}

# ryn dynasty on a given model/property via a selected method (onebyone, cegis, cegar, hybrid)
function dynasty() {
    experiments_wait ${threads}

    local experiment_set=$1

    local benchmark=$2
    local project="--project ../tacas21-benchmark/${benchmark}"

    local property=$3
    local tag=${property}
    property="--properties ${property}.properties"
    
    local optimality=$4
    if [ -n "${optimality}" ]; then
        tag=${optimality}
        optimality="--optimality ${optimality}.optimal"
    fi

    local method=$5
    local ce_quality=$6
    if [ "${ce_quality}" == "hybrid" ]; then
        tag=${tag}_ce_hybrid
        ce_quality="--ce-quality"
    elif [ "${ce_quality}" == "maxsat" ]; then
        tag=${tag}_ce_maxsat
        ce_quality="--ce-quality --ce-maxsat"
    fi

    local timeout=$7
    local logfile="../experiments/logs/${experiment_set}/${benchmark}_${tag}_${method}.txt"
    
    ((experiment_current+=1))
    echo "experiment ${experiment_current}/${experiment_total}: ${benchmark} (${tag}), method: ${method}"
    timeout ${timeout} python dynasty.py ${project} ${property} ${optimality} ${method} ${ce_quality} > ${logfile} || echo "TO" >> ${logfile} &
}

## experiment section ##########################################################

# create folders for log files
mkdir -p logs logs/performance logs/ce logs/herman2

# navigate to dynasty
cd ../dynasty

## experiments with small models (Table 2)

# evaluate cegis/cegar/hybrid on a basic benchmark
# for method in cegis cegar hybrid; do
for method in onebyone cegis cegar hybrid; do
    echo "-- evaluating basic benchmark (${method})"
    for benchmark in grid maze dpm pole herman; do
        for property in easy hard; do
            dynasty performance "${benchmark}" "${property}" "" "${method}" "" "${TIMEOUT_SMALL_MODELS}"
        done
    done
done

# evaluate CE quality on the same benchmark
for ce_quality in hybrid maxsat; do
    echo "-- evaluating CE quality (${ce_quality})"
    for benchmark in grid maze dpm pole herman; do
        for property in easy hard; do
            dynasty ce "${benchmark}" "${property}" "" "${method}" "${ce_quality}" "${TIMEOUT_SMALL_MODELS}"
        done
    done
done

## experiments with herman-2 (Table 3)

# evaluate herman-2 (smaller,larger) using only cegar and hybrid
echo "-- evaluating herman-2 (smaller)"
for method in cegar hybrid; do
    dynasty herman2 herman2_smaller "feasibility" "" "${method}" "" "${TIMEOUT_SMALL_MODELS}"
    dynasty herman2 herman2_smaller "multiple" "" "${method}" "" "${TIMEOUT_SMALL_MODELS}"
    dynasty herman2 herman2_smaller "none" "0" "${method}" "" "${TIMEOUT_SMALL_MODELS}"
done
echo "-- evaluating herman-2 (larger)"
for method in cegar hybrid; do
    dynasty herman2 herman2_larger "feasibility" "" "${method}" "" "${TIMEOUT_LARGE_MODELS}"
    dynasty herman2 herman2_larger "none" "0" "${method}" "" "${TIMEOUT_LARGE_MODELS}"
    dynasty herman2 herman2_larger "none" "5" "${method}" "" "${TIMEOUT_LARGE_MODELS}"
done
# estimate 1-by-1 enumeration on optimality (0%)
dynasty herman2 herman2_larger "none" "0" "onebyone" "" "${TIMEOUT_LARGE_MODELS}"

# wait for the remaining experiments to finish
wait
echo "-- all experiments finished"

# navigate back to root folder
cd -

# done
