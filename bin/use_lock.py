#!/usr/bin/env python3

import os
import sys
import time
import signal
import fcntl

# Global variable to hold the file handle
locked_file = None

def signal_handler(signum, frame):
    print(f"Received signal {signum}, shutting down...")
    if locked_file:
        try:
            fcntl.flock(locked_file, fcntl.LOCK_UN)
            locked_file.close()
            print("File lock released")
        except:
            pass
    sys.exit(0)

def main():
    global locked_file
    
    # Set up signal handler for graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Create output directory if it doesn't exist
    output_dir = "output_dir"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Create and hold an exclusive file lock
    log_file = os.path.join(output_dir, "isoquant.log")
    
    print(f"Creating and locking file: {log_file}")
    
    try:
        # Open file for writing
        locked_file = open(log_file, 'w')
        
        # Acquire exclusive lock (blocking)
        fcntl.flock(locked_file, fcntl.LOCK_EX)
        
        print("EXCLUSIVE FILE LOCK ACQUIRED AND HELD")
        print("This file lock will be held for 24 hours or until interrupted")
        print("CRIU should detect this lock and fail the dump")
        print("You can interrupt with Ctrl+C or send SIGTERM")
        
        # Write initial content
        locked_file.write("Starting simulation of IsoQuant file locking behavior\n")
        locked_file.write("This file is locked with fcntl.LOCK_EX\n")
        locked_file.flush()
        
        start_time = time.time()
        counter = 0
        
        # Hold the lock for 24 hours, periodically writing
        while time.time() - start_time < 86400:  # 24 hours
            counter += 1
            
            # Write to locked file periodically (every 10 seconds)
            if counter % 100 == 0:  # Every 10 seconds at 0.1s intervals
                elapsed = time.time() - start_time
                locked_file.write(f"Lock still held at iteration {counter}, elapsed: {elapsed:.1f}s\n")
                locked_file.flush()  # Ensure write while lock is held
                print(f"Lock held for {elapsed:.1f}s (iteration {counter})")
            
            time.sleep(0.1)  # Check every 0.1 seconds
            
    except KeyboardInterrupt:
        print("Interrupted by user")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Clean up - release lock
        if locked_file:
            try:
                locked_file.write("Process ending, releasing file lock\n")
                locked_file.flush()
                fcntl.flock(locked_file, fcntl.LOCK_UN)
                locked_file.close()
                print("File lock released and file closed")
            except Exception as e:
                print(f"Error during cleanup: {e}")
    
    print("Process complete")

if __name__ == "__main__":
    main()