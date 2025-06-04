#!/bin/bash

# Script to reproduce FIFO race condition similar to STAR issue
# This demonstrates the problem where directories are deleted while processes
# still have open file descriptors to FIFOs within those directories

set -e

echo "=== Reproducing FIFO Race Condition ==="

# Configuration
NUM_CPUS=${1:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}
echo "Will stress $NUM_CPUS CPUs during the test"

# Function to start CPU stress processes
start_cpu_stress() {
    echo "Starting CPU stress on $NUM_CPUS CPUs..."

    stress --cpu $NUM_CPUS &
    
    # # Method 1: Using 'yes' (most portable)
    # for i in $(seq 1 $NUM_CPUS); do
    #     yes > /dev/null &
    #     CPU_PIDS+=($!)
    #     echo "  Started CPU stress process $i (PID: ${CPU_PIDS[-1]})"
    # done
    
    # # Alternative method 2: Using bash arithmetic loops (uncomment if 'yes' not available)
    # for i in $(seq 1 $NUM_CPUS); do
    #     (while true; do ((n=1+1)); done) &
    #     CPU_PIDS+=($!)
    # done
    
    # Alternative method 3: Using dd (uncomment if others don't work)
    # for i in $(seq 1 $NUM_CPUS); do
    #     dd if=/dev/zero of=/dev/null bs=1M count=999999999 2>/dev/null &
    #     CPU_PIDS+=($!)
    # done
}

# Function to stop CPU stress processes
stop_cpu_stress() {
    echo "Stopping CPU stress processes..."
    for pid in "${CPU_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "  Killing CPU stress process $pid"
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done
    # Give them a moment to die gracefully
    sleep 1
    # Force kill any remaining
    for pid in "${CPU_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done
}

# Array to store CPU stress process PIDs
CPU_PIDS=()

# Start CPU stress BEFORE creating FIFOs
start_cpu_stress

# Create temporary directory (like STAR's _STARtmp)
TMPDIR="./test_STARtmp"
mkdir -p "$TMPDIR"

# Create FIFOs (like STAR's tmp.fifo.read1 and tmp.fifo.header)
FIFO1="$TMPDIR/tmp.fifo.read1"
FIFO2="$TMPDIR/tmp.fifo.header"

mkfifo "$FIFO1"
mkfifo "$FIFO2"

echo "Created FIFOs: $FIFO1, $FIFO2"

# Start background processes that use the FIFOs (like samtools view)
echo "Starting background processes..."

# Process 1: Simulate "samtools view input.bam > tmp.fifo.read1"
(
    echo "Writer process 1 starting..."
    for i in {1..1000}; do
        echo "READ_DATA_LINE_$i" 
        sleep 0.1
    done
) > "$FIFO1" &
WRITER1_PID=$!

# Process 2: Simulate header reading process
(
    echo "Writer process 2 starting..."
    for i in {1..1000}; do
        echo "@HEADER_LINE_$i"
        sleep 0.1  
    done
) > "$FIFO2" &
WRITER2_PID=$!

# Start reader processes
(
    echo "Reader process 1 starting..."
    while read line; do
        echo "Read1: $line" > /dev/null
    done < "$FIFO1"
) &
READER1_PID=$!

(
    echo "Reader process 2 starting..."
    while read line; do  
        echo "Read2: $line" > /dev/null
    done < "$FIFO2"
) &
READER2_PID=$!

echo "Background processes started:"
echo "  Writer 1 PID: $WRITER1_PID"
echo "  Writer 2 PID: $WRITER2_PID" 
echo "  Reader 1 PID: $READER1_PID"
echo "  Reader 2 PID: $READER2_PID"

# Let them run for a moment
sleep 2

echo ""
echo "=== BEFORE DELETION ==="
echo "Directory contents:"
ls -la "$TMPDIR/"

echo ""
echo "Open file descriptors to our FIFOs:"
lsof +D "$TMPDIR" 2>/dev/null || echo "lsof not available"

echo ""
echo "CPU usage should be high right now..."
if command -v top >/dev/null; then
    echo "Current CPU usage (top output for 2 seconds):"
    timeout 2 top -l 1 2>/dev/null | head -10 || echo "Could not get CPU stats"
fi

# THE RACE CONDITION: Delete directory while processes are running
# (This is what STAR was doing wrong)
echo ""
echo "=== DELETING DIRECTORY WHILE PROCESSES RUNNING ==="
rm -rf "$TMPDIR"
echo "Directory deleted!"

# Show the race condition in action
sleep 1

echo ""
echo "=== AFTER DELETION ==="
echo "Processes still running with open FDs to deleted files:"
echo "Looking for processes with deleted files..."

# Check if any of our processes still exist and have deleted file descriptors
for pid in $WRITER1_PID $WRITER2_PID $READER1_PID $READER2_PID; do
    if kill -0 "$pid" 2>/dev/null; then
        echo "Process $pid still running"
        if command -v lsof >/dev/null; then
            lsof -p "$pid" 2>/dev/null | grep deleted || true
        fi
    fi
done

echo ""
echo "=== CLEANUP ==="
echo "Killing processes (like STAR should have done BEFORE deleting files)..."

# Clean up FIFO processes
for pid in $WRITER1_PID $WRITER2_PID $READER1_PID $READER2_PID; do
    if kill -0 "$pid" 2>/dev/null; then
        echo "Killing process $pid"
        kill -TERM "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi
done

# Clean up CPU stress processes
stop_cpu_stress

echo ""
echo "=== DEMONSTRATION COMPLETE ==="
echo "This showed the same race condition that STAR had:"
echo "1. Created directory with FIFOs"
echo "2. Started processes using the FIFOs" 
echo "3. Deleted directory while processes still running"
echo "4. Processes held open file descriptors to deleted files"
echo "5. All while stressing $NUM_CPUS CPUs to simulate heavy load"
echo ""
echo "The fix is to kill/wait for processes BEFORE deleting files!" 
echo ""
echo "Usage: $0 [num_cpus]"
echo "  num_cpus: Number of CPUs to stress (default: auto-detect)" 