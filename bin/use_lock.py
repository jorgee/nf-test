#!/usr/bin/env python3

import logging
import os
import sys
import time
import signal

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
    
    print("Log file created and locked. Process will wait for 24 hours (86400 seconds)...")
    print("You can interrupt with Ctrl+C or send SIGTERM")
    
    try:
        # Wait for 24 hours (86400 seconds) or until interrupted
        time.sleep(86400)
    except KeyboardInterrupt:
        print("Interrupted by user")
    
    logger.info("Process ending, file lock will be released")
    print("Process complete")

if __name__ == "__main__":
    main()