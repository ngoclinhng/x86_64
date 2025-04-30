#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "test_utils.h"

char *capture_stdout(void (*func)(void)) {
  int pipefd[2];
  pipe(pipefd);

  // Backup stdout
  int stdout_backup = dup(STDOUT_FILENO);

  // Redirect stdout to pipe
  dup2(pipefd[1], STDOUT_FILENO);
  close(pipefd[1]);

  // Call the function (output goes to pipe)
  func();
  fflush(stdout);

  // Restore stdout
  dup2(stdout_backup, STDOUT_FILENO);
  close(stdout_backup);

  size_t buf_size = 0;
  size_t total_read = 0;
  char *buffer = NULL;
  char temp[1024]; // Temporary chunk buffer

  while(1) {
    ssize_t bytes_read = read(pipefd[0], temp, sizeof(temp));
    if (bytes_read <= 0) break;

    // Resize buffer and append new data
    buffer = realloc(buffer, total_read + bytes_read + 1);
    memcpy(buffer + total_read, temp, bytes_read);
    total_read += bytes_read;
  }

  close(pipefd[0]);

  if (buffer) {
    buffer[total_read] = '\0'; // Null-terminator
  } else {
    buffer = strdup(""); // Fallback to empty output
  }

  return buffer;  
}
