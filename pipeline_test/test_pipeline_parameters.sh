#!/bin/bash

set -o nounset
set -o errexit
set -o xtrace

source common.sh

MISMATCH_THRESHOLD=$1
MINMATCH_THRESHOLD=$2
MULTIMAP_THRESHOLD=$3
REJECT_MULTIMAPS=$4

MOUSE_FILTERED_HITS_EXPECTED=$5
MOUSE_FILTERED_READS_EXPECTED=$6
MOUSE_REJECTED_HITS_EXPECTED=$7
MOUSE_REJECTED_READS_EXPECTED=$8

RAT_FILTERED_HITS_EXPECTED=$9
RAT_FILTERED_READS_EXPECTED=${10}
RAT_REJECTED_HITS_EXPECTED=${11}
RAT_REJECTED_READS_EXPECTED=${12}

AMBIGUOUS_HITS_EXPECTED=${13}
AMBIGUOUS_READS_EXPECTED=${14}

RUN_STAR=${15}

rm -rf ${RESULTS_DIR}
mkdir -p ${RESULTS_DIR}

echo "sample_reads ${RAW_READS_DIR}/mouse_rat_test_1.fastq.gz ${RAW_READS_DIR}/mouse_rat_test_2.fastq.gz" > ${SAMPLES_FILE}

if [[ "${REJECT_MULTIMAPS}" == "true" ]]; then
    REJECT_MULTIMAPS="--reject-multimaps"
else
    REJECT_MULTIMAPS=""
fi

if [[ ! "${RUN_STAR}" == "yes" ]]; then
    MOUSE_STAR_INDEX=dummy_star_index
    RAT_STAR_INDEX=dummy_star_index
fi

species_separator --reads-base-dir="/" -t ${NUM_THREADS} --mismatch-threshold=${MISMATCH_THRESHOLD} --minmatch-threshold=${MINMATCH_THRESHOLD} --multimap-threshold=${MULTIMAP_THRESHOLD} ${REJECT_MULTIMAPS} ${SAMPLES_FILE} ${SSS_DIR} mouse ${MOUSE_STAR_INDEX} rat ${RAT_STAR_INDEX}

if [[ ! "${RUN_STAR}" == "yes" ]]; then
    mkdir -p ${SSS_DIR}/star_indices/mouse
    mkdir -p ${SSS_DIR}/star_indices/rat
    mkdir -p ${SSS_DIR}/raw_reads
    mkdir -p ${SSS_DIR}/mapped_reads
    mkdir -p ${SSS_SORTED_DIR}
    cp ${PRESORTED_READS_DIR}/*.bam ${SSS_SORTED_DIR}
fi

#(cd ${SSS_DIR}; make >${LOG_FILE} 2>&1) 
(cd ${SSS_DIR}; make V=1) 

MOUSE_INFO_EXPECTED=$(expected_results 1 ${MOUSE_FILTERED_HITS_EXPECTED} ${MOUSE_FILTERED_READS_EXPECTED} ${MOUSE_REJECTED_HITS_EXPECTED} ${MOUSE_REJECTED_READS_EXPECTED} ${AMBIGUOUS_HITS_EXPECTED} ${AMBIGUOUS_READS_EXPECTED})

RAT_INFO_EXPECTED=$(expected_results 2 ${RAT_FILTERED_HITS_EXPECTED} ${RAT_FILTERED_READS_EXPECTED} ${RAT_REJECTED_HITS_EXPECTED} ${RAT_REJECTED_READS_EXPECTED} ${AMBIGUOUS_HITS_EXPECTED} ${AMBIGUOUS_READS_EXPECTED})

test_expected_results 1 "${MOUSE_INFO_EXPECTED}" ${MISMATCH_THRESHOLD} ${MINMATCH_THRESHOLD} ${MULTIMAP_THRESHOLD}
test_expected_results 2 "${RAT_INFO_EXPECTED}" ${MISMATCH_THRESHOLD} ${MINMATCH_THRESHOLD} ${MULTIMAP_THRESHOLD}
