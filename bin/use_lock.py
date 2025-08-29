#!/usr/bin/env python3

import logging
import os
import sys
import time
import signal
import fcntl

def signal_handler(signum, frame):
    print(f"Received signal {signum}, shutting down...")
    sys.exit(0)

def main():
    # Set up signal handler for graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Create output directory if it doesn't exist
    output_dir = "output_dir"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Set up logging to simulate IsoQuant's behavior
    log_file = os.path.join(output_dir, "isoquant.log")
    
    # Create file handler - this creates the file lock
    print(f"Creating log file with lock: {log_file}")
    fh = logging.FileHandler(log_file)
    fh.setLevel(logging.INFO)
    
    # Set up logger
    logger = logging.getLogger('TestLogger')
    logger.setLevel(logging.INFO)
    logger.addHandler(fh)
    
    # Write initial message
    logger.info("Starting simulation of IsoQuant file locking behavior")
    logger.info("This process will hold a file lock on the log file")
    
    print("Log file created and locked. Process will continuously write to log...")
    print("Writing every 0.1 seconds to maximize lock collision probability")
    print("You can interrupt with Ctrl+C or send SIGTERM")
    
    counter = 0
    start_time = time.time()
    
    try:
        # Run for 24 hours, writing continuously to increase lock collision
        while time.time() - start_time < 86400:  # 24 hours
            counter += 1
            # Write frequently to keep file lock active
            logger.info(f"Active logging iteration {counter}, elapsed: {time.time() - start_time:.1f}s")
            
            # Small sleep to avoid excessive CPU usage but maintain frequent writes
            time.sleep(0.1)  # 10 writes per second
            
    except KeyboardInterrupt:
        print("Interrupted by user")
    
    logger.info("Process ending, file lock will be released")
    print("Process complete")

if __name__ == "__main__":
    main()