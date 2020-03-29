/**
 * Copyright (c) 2012 MIT License by 6.172 Staff
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 **/


#include "./util.h"

// Function prototypes
static void merge_f(data_t* A, int p, int q, int r);
static void copy_f(data_t* source, data_t* dest, int n);
static void sort_f_helper(data_t* A, int p, int r);
extern void isort(data_t* begin, data_t* end);
static data_t *g_left = 0;

void sort_f(data_t* A, int p, int r) {
  mem_alloc(&g_left, (r - p + 1) / 2);
  if (g_left == NULL) {
    mem_free(&g_left);
    return;
  }  
  sort_f_helper(A, p, r);
  mem_free(&g_left);
}

// A basic merge sort routine that sorts the subarray A[p..r]
static inline __attribute__((always_inline)) void sort_f_helper(data_t* A, int p, int r) {
  assert(A);
  if (p < r) {
    if (r - p < 100) {
      isort(A + p, A + r);
    } else {
      int q = (p + r) / 2;
      sort_f_helper(A, p, q);
      sort_f_helper(A, q + 1, r);
      merge_f(A, p, q, r);
    }
  }
}

// A merge routine. Merges the sub-arrays A [p..q] and A [q + 1..r].
// Uses two arrays 'left' and 'right' in the merge operation.
static inline __attribute__((always_inline)) void merge_f(data_t* A, int p, int q, int r) {
  assert(A);
  assert(p <= q);
  assert((q + 1) <= r);
  int n1 = q - p + 1;
  
  data_t* left = g_left;

  copy_f((A + p), left, n1);

  data_t *t_left = A + p;
  data_t *t_left_end = A + q;
  data_t *t_right = A + q + 1;
  data_t *t_right_end = A + r;

  int k = p;
  for (; k <= r && t_left <= t_left_end && t_right <= t_right_end; k++) {
    if (*t_left <= *t_right) {
      *(A+k) = *t_left++;
    } else {
      *(A+k) = *t_right++;
    }
  }

  if (t_left <= t_left_end) {
    for (; k <= r; k++) {
      *(A+k) = *t_left++;
    }
  }

  if (t_right <= t_right_end) {
    for (; k <= r; k++) {
      *(A+k) = *t_right++;
    }
  }
}

static inline __attribute__((always_inline)) void copy_f(data_t* source, data_t* dest, int n) {
  assert(dest);
  assert(source);

  for (int i = 0 ; i < n ; i++) {
    *dest++ = *source++;
  }
}
