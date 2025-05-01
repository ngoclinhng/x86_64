#!/usr/bin/python3
import subprocess
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import Callable, Optional, Dict, Any

# Config
ASM = "nasm"
LD = "ld"
SRC_DIR = Path("../")
STDLIB = SRC_DIR / "stdlib.o"
TEST_DIR = Path(".")

@dataclass
class TestCase:
    # -D flags for NASM (e.g., {"TEST_VALUE": "123"}
    defines: Dict[str, Any]

    # Input to pipe to stdin
    stdin: Optional[str] = None 

    # For exit code tests
    expected_exitcode: int = 0

    checker: Callable = lambda output, returncode: output.strip() == "0"

def compile_stdlib(force: bool = False) -> bool:
    "Recompile stdlib.asm if needed or forced."
    stdlib_src = SRC_DIR / "stdlib.asm"

    if not STDLIB.exists() or force or \
       (stdlib_src.stat().st_mtime > STDLIB.stat().st_mtime):
        print("Compiling stdlib...")
        subprocess.run([ASM, "-f", "elf64", str(stdlib_src), "-o",
                        str(STDLIB)], check=True)
        return True

    return False

def clean_build_artifacts(test_name: str):
    "Remove .o and binary files for a test."
    test_obj = TEST_DIR / f"{test_name}.o"
    test_exe = TEST_DIR / test_name
    test_obj.unlink(missing_ok=True)
    test_exe.unlink(missing_ok=True)    
    

def compile_and_run(test_name: str, test_case: TestCase) -> tuple[str, int]:
    """Assemble, link, and run a test. Returns (output, exitcode)."""
    test_asm = TEST_DIR / f"{test_name}.asm"
    test_obj = TEST_DIR / f"{test_name}.o"
    test_exe = TEST_DIR / test_name

    # Assemble with -D flags
    cmd = [ASM, "-f", "elf64", str(test_asm), "-o", str(test_obj)]
    for k, v in test_case.defines.items():        
        cmd.extend(["-D", f"{k}={v}"])        

    subprocess.run(cmd, check=True)

    # Link with stdlib
    subprocess.run([LD, str(test_obj), str(STDLIB), "-o", str(test_exe)],
                   check=True)


    # Run with optional stdin
    result = subprocess.run(
        [f"./{str(test_exe)}"],
        input=test_case.stdin,
        capture_output=True,
        text=True,
        cwd=str(TEST_DIR)
    )

    return result.stdout, result.returncode

def run_tests(test_configs: Dict[str, list[TestCase]], cleanup: bool = True,
              force_stdlib: bool = False):
    """Run all tests with optional cleanup and stdlib recompilation."""
    compile_stdlib(force_stdlib)
    
    for test_name, cases in test_configs.items():
        print(f"\nTesting {test_name}:")
        
        for i, test_case in enumerate(cases, 1):
            output, exitcode = compile_and_run(test_name, test_case)
            if test_case.checker(output, exitcode):
                print(f"  Case {i}: PASS")
            else:
                print(f"  Case {i}: FAIL (output={output}, exitcode={exitcode})")
                exit(1)

        if cleanup:
            clean_build_artifacts(test_name)

    print("\nAll tests passed!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NASM Test Runner")

    parser.add_argument(
        "--no-cleanup",
        dest="cleanup",
        action="store_false",
        default=True,
        help="Skip removal of build artifacts"
    )
    
    parser.add_argument(
        "--rebuild-stdlib",
        action="store_true",
        default=False,
        help="Force recompile stdlib"
    )
    
    args = parser.parse_args()
    
    test_configs = {
        # --- print_uint ---
        "print_uint_test": [
            TestCase(
                defines={"TEST_VALUE": "12345"},
                checker=lambda o, c: o == "12345" and c == 0
            )
        ]
    }

    run_tests(test_configs, cleanup=args.cleanup,
              force_stdlib=args.rebuild_stdlib)
    

                    
