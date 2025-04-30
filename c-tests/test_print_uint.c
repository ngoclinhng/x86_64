#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "test_utils.h"

extern void print_uint(uint64_t n);

static const struct {
  uint64_t input;
  const char *expected;
} test_cases[] = {
  {0, "0"},
  {123, "123"}
};

static uint64_t current_number;
static void print_current_number(void) {
  print_uint(current_number);
}

static void test_print_uint(uint64_t input, const char *expected) {
  current_number = input;
  char *output = capture_stdout(print_current_number);

  if (strcmp(output, expected) != 0) {
    printf("FAIL: print_uint(%lu)\n", input);
    printf("  Expected: '%s'\n", expected);
    printf("  Got:      '%s'\n", output);
  } else {
    printf("PASS: print_uint(%lu) -> %s\n", input, output);
  }

  free(output);
}

int main(void) {
  const size_t num_test_cases = sizeof(test_cases);
  printf("Num_test_cases: %lu\n", num_test_cases);
  return 0;
}

