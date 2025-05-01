#!/usr/bin/python3
import subprocess
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

    # Link with stdlib.o
    if not STDLIB.exists():
        subprocess.run([ASM, "-f", "elf64", str(SRC_DIR / "stdlib.asm"), "-o",
                        str(STDLIB)], check=True)
        subprocess.run([LD, str(test_obj), str(STDLIB), "-o", str(test_exe)],
                       check=True)    

    # Run with optional stdin
    result = subprocess.run(
        [f"./{str(test_exe)}"],
        input=test_case.stdin,
        capture_output=True,
        text=True
    )

    return result.stdout, result.returncode

def run_tests(test_configs: Dict[str, list[TestCase]]):
    """Run all tests with their custom checkers."""
    for test_name, cases in test_configs.items():
        print(f"\nTesting {test_name}:")
        
        for i, test_case in enumerate(cases, 1):
            output, exitcode = compile_and_run(test_name, test_case)
            if test_case.checker(output, exitcode):
                print(f"  Case {i}: PASS")
            else:
                print(f"  Case {i}: FAIL (output={output}, exitcode={exitcode})")
                exit(1)

    print("\nAll tests passed!")

if __name__ == "__main__":
    test_configs = {
        # --- print_uint ---
        "print_uint_test": [
            TestCase(
                defines={"TEST_VALUE": "12345"},
                checker=lambda o, c: o == "12345" and c == 0
            )
        ]
    }

    run_tests(test_configs)
    

                    
