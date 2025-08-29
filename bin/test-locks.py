#!/usr/bin/env python3

import os
import sys
import fcntl
import errno
import subprocess
import time
import struct
from pathlib import Path

def test_file_locking(test_dir):
    """
    Test file locking behavior to distinguish between:
    1. Real filesystem lock support (like ext4, xfs)
    2. Unsupported locks (like Fusion returning ENOSYS)
    """
    
    test_file = Path(test_dir) / "lock_test.txt"
    print(f"Testing file locking on: {test_file}")
    print(f"Filesystem type: {get_filesystem_type(test_dir)}")
    print("-" * 50)
    
    # Test 1: Basic lock acquisition
    print("Test 1: Basic flock() call")
    try:
        with open(test_file, 'w') as f:
            f.write("test content\n")
            fcntl.flock(f, fcntl.LOCK_EX)
            print("✓ flock(LOCK_EX) succeeded")
            fcntl.flock(f, fcntl.LOCK_UN)
            print("✓ flock(LOCK_UN) succeeded")
    except OSError as e:
        print(f"✗ flock() failed: {e} (errno: {e.errno})")
        if e.errno == errno.ENOSYS:
            print("  → Filesystem does not implement file locking")
            return "UNSUPPORTED"
    
    # Test 2: Process-level lock conflict detection
    print("\nTest 2: Lock conflict between processes")
    
    try:
        # Fork a child process to test inter-process locking
        pid = os.fork()
        
        if pid == 0:  # Child process
            try:
                with open(test_file, 'w') as f:
                    fcntl.flock(f, fcntl.LOCK_EX)  # Child holds lock
                    print("Child: Acquired exclusive lock")
                    time.sleep(3)  # Hold lock for 3 seconds
                    print("Child: Releasing lock")
            except Exception as e:
                print(f"Child: Lock failed: {e}")
                sys.exit(1)
            sys.exit(0)
        else:  # Parent process
            time.sleep(0.5)  # Let child acquire lock first
            
            # Try to acquire lock from parent (should block or fail)
            start_time = time.time()
            try:
                with open(test_file, 'w') as f:
                    # Use non-blocking lock to test conflict detection
                    fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    elapsed = time.time() - start_time
                    print(f"Parent: Got lock immediately ({elapsed:.2f}s)")
                    print("✗ No lock conflict detected - locks may not be working")
                    os.waitpid(pid, 0)
                    return "FAKE_LOCKS"
            except BlockingIOError:
                elapsed = time.time() - start_time
                print(f"Parent: Lock blocked as expected ({elapsed:.2f}s)")
                print("✓ Lock conflict properly detected")
                os.waitpid(pid, 0)
                return "REAL_LOCKS"
            except OSError as e:
                print(f"Parent: Lock error: {e}")
                os.waitpid(pid, 0)
                if e.errno == errno.ENOSYS:
                    return "UNSUPPORTED"
                return "ERROR"
    
    except OSError as e:
        print(f"Fork failed: {e}")
        return "ERROR"
    
    return "UNKNOWN"

def test_fcntl_locks(test_dir):
    """Test fcntl-based record locking (F_SETLK)"""
    test_file = Path(test_dir) / "fcntl_test.txt"
    print(f"\nTest 3: fcntl() record locking")
    
    try:
        with open(test_file, 'w+') as f:
            f.write("fcntl test content\n")
            f.flush()
            
            # Create a lock structure using struct.pack
            # struct flock: l_type, l_whence, l_start, l_len, l_pid
            lock_data = struct.pack('hhllh', fcntl.F_WRLCK, 0, 0, 10, 0)
            
            # Try F_SETLK (non-blocking)
            fcntl.fcntl(f, fcntl.F_SETLK, lock_data)
            print("✓ fcntl(F_SETLK) succeeded")
            
            # Try F_GETLK to query lock
            test_lock = struct.pack('hhllh', fcntl.F_WRLCK, 0, 0, 5, 0)
            result = fcntl.fcntl(f, fcntl.F_GETLK, test_lock)
            print("✓ fcntl(F_GETLK) succeeded")
            
            return "SUPPORTED"
            
    except OSError as e:
        print(f"✗ fcntl() failed: {e} (errno: {e.errno})")
        if e.errno == errno.ENOSYS:
            print("  → fcntl() locking not implemented")
            return "UNSUPPORTED"
        return "ERROR"
    except Exception as e:
        print(f"✗ fcntl() test failed: {e}")
        # If we can't test fcntl, but flock worked, assume it's supported
        return "PARTIAL"

def get_filesystem_type(path):
    """Get filesystem type for the given path"""
    try:
        result = subprocess.run(['df', '-T', str(path)], 
                              capture_output=True, text=True)
        lines = result.stdout.strip().split('\n')
        if len(lines) >= 2:
            return lines[1].split()[1]
    except:
        pass
    return "unknown"

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 test-locks.py <directory>")
        print("Example: python3 test-locks.py /fusion/s3/bucket/test")
        sys.exit(1)
    
    test_dir = sys.argv[1]
    
    # Create test directory if it doesn't exist
    Path(test_dir).mkdir(parents=True, exist_ok=True)
    
    print("File Locking Support Test")
    print("=" * 50)
    
    # Test flock() behavior
    flock_result = test_file_locking(test_dir)
    
    # Test fcntl() behavior  
    fcntl_result = test_fcntl_locks(test_dir)
    
    print("\n" + "=" * 50)
    print("RESULTS:")
    print(f"flock() support: {flock_result}")
    print(f"fcntl() support: {fcntl_result}")
    
    if flock_result == "UNSUPPORTED" or fcntl_result == "UNSUPPORTED":
        print("\n🚨 FILESYSTEM DOES NOT SUPPORT FILE LOCKING")
        print("   This explains why CRIU fails - locks exist only locally")
        print("   and cannot be serialized/restored across machines.")
    elif flock_result == "FAKE_LOCKS":
        print("\n⚠️  LOCKS APPEAR TO SUCCEED BUT DON'T ACTUALLY WORK")
        print("   This suggests local-only lock simulation that CRIU cannot handle.")
    elif flock_result == "REAL_LOCKS" and fcntl_result in ["SUPPORTED", "PARTIAL"]:
        print("\n✅ FILESYSTEM SUPPORTS REAL FILE LOCKING")
        print("   CRIU should be able to handle locks on this filesystem.")
    else:
        print(f"\n❓ MIXED OR UNCLEAR RESULTS")
        print("   Manual investigation may be needed.")
        print(f"   flock: {flock_result}, fcntl: {fcntl_result}")
    
    # Cleanup
    try:
        (Path(test_dir) / "lock_test.txt").unlink(missing_ok=True)
        (Path(test_dir) / "fcntl_test.txt").unlink(missing_ok=True)
    except:
        pass

if __name__ == "__main__":
    main()