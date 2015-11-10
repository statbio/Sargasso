#!/usr/bin/env python

# This script reads the read mapping BAM files & parallelises its filtering

# Parameters:
# 1 - Block directory filepath
# 2 - Output directory
# 3 - No. Threads
# 4 - Species 1
# 5 - Species 2

import sys
import subprocess
import os
from os import listdir
from os.path import isfile, join


# Check whether output dir exists
def check_dir(dir):
    if not os.path.isdir(dir):
        print "Filepath Parameter does not exist"
    quit()


# Check how many instances of a process are running at the present time
def check_processes(processes, max):
    busy = 0
    i = 0
    threshold = max
    while True:
        if i < len(processes):
            if processes[i].poll() is None:
                busy = busy + 1
            elif processes[i].poll() == 0:
                del processes[i]
                i = i - 1
            if busy >= threshold:
                return False
            i = i + 1
        else:
            break
    return True


# turn file list into dictionary; d[species1file] = species2file
def dictionary_files(files, sp1, sp2):
    file_dict = {}
    files = sorted(files)
    for file in files:
        sections = file.split("_")
        if sections[1] == sp1:
            sections[1] = sp2
            file_dict[file] = sections[0] + "_" + sections[1] + \
                "_" + sections[2] + "_" + sections[3]
    return file_dict


# Cycles through previously indexed chunks of read data & assigns it to the
# filter subprocess script Chunks; for the time being I'm considering each
# chunk to be 10 read pairs organised as a list of dictionaries
def run_processes(params):
    chunk_dir = params[0]
    out_dir = params[1]
    species1 = params[3]
    species2 = params[4]

    # keep track of all processes
    all_processes = []
    process_no = -1

    # get block files
    block_files = [f for f in listdir(chunk_dir) if isfile(join(chunk_dir, f))]

    # remove species 2 block files
    file_pairs = dictionary_files(block_files, species1, species2)

    # cycle through chunks
    for file1 in file_pairs.keys():
        process_no = process_no + 1
        # create input paths
        sp1in = chunk_dir + "/" + file1
        sp2in = chunk_dir + "/" + file_pairs[file1]
        # create output paths
        sp1out = out_dir + "/" + species1 + "-block_" + \
            str(process_no) + "-filtered"
        sp2out = out_dir + "/" + species2 + "-block_" + \
            str(process_no) + "-filtered"
        commands = ["filter_sample_reads",
                    species1, sp1in, os.path.abspath(sp1out),
                    species2, sp2in, os.path.abspath(sp2out)]
        proc = subprocess.Popen(commands)
        all_processes.append(proc)

    # check all processes finished
    free = check_processes(all_processes, 1)
    while not free:
        print "Waiting for Threads"
        all_processes[0].wait()
        free = check_processes(all_processes, 1)

    print "Filtering Complete"

    # NEED TO CONCATENATE THE OUTPUT FILES


def validate_params(params):
    # check output dir exists & create if not
    #check_dir(params[1])
    #check_dir(params[2])
    #if not params[3].isnumeric():
    #   print "Number of threads specified is not a number"
    #   quit()
    #if !os.path.isfile(params[2]):
    #   print "The filepath for the first BAM file points to a non-existant file"
    #   return False
    #if !os.path.isfile(params[3]):
        #        print "The filepath for the second BAM file points to a non-existant file"
        #        return False
    return True


def filter_control(args):
    if validate_params(args):
        run_processes(args)
