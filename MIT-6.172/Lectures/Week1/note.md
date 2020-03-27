# Calendar

WEEK | LECTURES | RECITATIONS | KEY DATES
-----|----------|-------------|----------
1 | L1: Intro and Matrix Multiplication | R1: Basic Tools | HW1: Basic Tools, C Primer assigned

# Homework 1: Getting Started
# 4. C Primer 
## Preprocessing 
```c
// Copyright (c) 2012 MIT License by 6.172 Staff

// All occurences of ONE will be replaced by 1.
#define ONE 1

// Macros can also behave similar to inline functions.
// Note that parentheses around arguments are required to preserve order of
// operations. Otherwise, you can introduce bugs when substitution happens

#define MIN(a, b) ((a) < (b) ? (a) : (b))

int c = ONE, d = ONE + 5;
int e = MIN(c, d);

#ifndef NDEBUG
// This code will be compiled only when
// the macro NDEBUG is not defined.
// Recall that if clang is passed -DNDEBUG on the command line,
// then NDEBUG will be defined.
  if (something) {}
#endif
```
#### Exercise: Direct clang to preprocess preprocess.c. 
- e1
```bash
/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer$ clang -E preprocess.c 
# 1 "preprocess.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 349 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "preprocess.c" 2
# 12 "preprocess.c"
int c = 1, d = 1 + 5;
int e = ((c) < (d) ? (c) : (d));






  if (something) {}
```
- e2
```bash
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer$ clang -E -DNDEBUG preprocess.c                                                                           
# 1 "preprocess.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 349 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "preprocess.c" 2
# 12 "preprocess.c"
int c = 1, d = 1 + 5;
int e = ((c) < (d) ? (c) : (d));
```

## Data types and their sizes 

- https://en.cppreference.com/w/c/types/integer

- 对于**一次性变量或将在精度限制下保持良好状态的变量，请使用常规int**。 设置这些值的精度是为了在具有不同字长的计算机上最大化性能。如果使用位级操作，**最好使用无符号数据类型**，例如uint64_t（无符号64位int）。否则，通常最好使用非显式变量，例如常规int。此外，如果您知道要使用的架构，通常最好使用显式数据类型编写代码

#### Exercise: Edit sizes.c to print the sizes of each of the following types:  int, short, long, char, float,  double,  unsigned int,  long long,  uint8_t,  uint16_t,  uint32_t,  uint64_t,  uint_fast8_t, uint_fast16_t, uintmax_t, intmax_t, __int128, int[] and student. Note that __int128 is a clang 

```diff
diff --git a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/sizes.c b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/sizes.c
index c98aba5..40c8e61 100644
--- a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/sizes.c
+++ b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/sizes.c
@@ -4,11 +4,32 @@
 #include <stdlib.h>
 #include <stdint.h>

+#define PRINT_SIZE(type)  \
+do {                      \
+  printf("size of %s : %zu bytes \n", #type, sizeof(type));  \
+} while(0)
+
 int main() {
   // Please print the sizes of the following types:
   // int, short, long, char, float, double, unsigned int, long long
   // uint8_t, uint16_t, uint32_t, and uint64_t, uint_fast8_t,
   // uint_fast16_t, uintmax_t, intmax_t, __int128, and student
+  PRINT_SIZE(short);
+  PRINT_SIZE(long);
+  PRINT_SIZE(char);
+  PRINT_SIZE(float);
+  PRINT_SIZE(double);
+  PRINT_SIZE(unsigned int);
+  PRINT_SIZE(long long);
+  PRINT_SIZE(uint8_t);
+  PRINT_SIZE(uint16_t);
+  PRINT_SIZE(uint32_t);
+  PRINT_SIZE(uint64_t);
+  PRINT_SIZE(uint_fast8_t);
+  PRINT_SIZE(uint_fast16_t);
+  PRINT_SIZE(uintmax_t);
+  PRINT_SIZE(intmax_t);
+  PRINT_SIZE(__int128);

   // Here's how to show the size of one type. See if you can define a macro
   // to avoid copy pasting this code.
```
- output
```
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer$ ./sizes
size of short : 2 bytes 
size of long : 8 bytes 
size of char : 1 bytes
size of float : 4 bytes
size of double : 8 bytes
size of unsigned int : 4 bytes
size of long long : 8 bytes
size of uint8_t : 1 bytes
size of uint16_t : 2 bytes
size of uint32_t : 4 bytes
size of uint64_t : 8 bytes
size of uint_fast8_t : 1 bytes
size of uint_fast16_t : 8 bytes
size of uintmax_t : 8 bytes
size of intmax_t : 8 bytes
size of __int128 : 16 bytes
size of int : 4 bytes
size of student : 8 bytes
```

## Pointers 

```c
// Copyright (c) 2012 MIT License by 6.172 Staff

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char * argv[]) {  // What is the type of argv?
  int i = 5;
  // The & operator here gets the address of i and stores it into pi
  int * pi = &i;
  // The * operator here dereferences pi and stores the value -- 5 --
  // into j.
  int j = *pi;

  char c[] = "6.172";
  char * pc = c;  // Valid assignment: c acts like a pointer to c[0] here.
  char d = *pc;
  printf("char d = %c\n", d);  // What does this print? #char d = 6#

  // compound types are read right to left in C.
  // pcp is a pointer to a pointer to a char, meaning that
  // pcp stores the address of a char pointer.
  char ** pcp;
  pcp = argv;  // Why is this assignment valid? #argv[]->char*; argv->char **#

  const char * pcc = c;  // pcc is a pointer to char constant
  char const * pcc2 = c;  // What is the type of pcc2? #char const == const char#

  // For each of the following, why is the assignment:
  *pcc = '7';  // invalid? #Y#
  pcc = *pcp;  // valid? #Y#
  pcc = argv[0];  // valid? #Y#

  char * const cp = c;  // cp is a const pointer to char
  // For each of the following, why is the assignment:
  cp = *pcp;  // invalid? #Y#
  cp = *argv;  // invalid? #Y#
  *cp = '!';  // valid? #Y#

  const char * const cpc = c;  // cpc is a const pointer to char const
  // For each of the following, why is the assignment:
  cpc = *pcp;  // invalid? #Y#
  cpc = argv[0];  // invalid? #Y#
  *cpc = '@';  // invalid? #Y#

  return 0;
}
```

#### Exercise: Compile pointer.c using the following command: 

- Write-up 2: Answer the questions in the comments in pointer.c. For example, why are some of the statements valid and some are not? 

```bash
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer$ make pointer
clang -Wall -O1 -DNDEBUG  -c pointer.c
pointer.c:30:8: error: read-only variable is not assignable
  *pcc = '7';  // invalid? #Y#
  ~~~~ ^
pointer.c:36:6: error: cannot assign to variable 'cp' with const-qualified type 'char *const'
  cp = *pcp;  // invalid? #Y#
  ~~ ^
pointer.c:34:16: note: variable 'cp' declared const here
  char * const cp = c;  // cp is a const pointer to char
  ~~~~~~~~~~~~~^~~~~~
pointer.c:37:6: error: cannot assign to variable 'cp' with const-qualified type 'char *const'
  cp = *argv;  // invalid? #Y#
  ~~ ^
pointer.c:34:16: note: variable 'cp' declared const here
  char * const cp = c;  // cp is a const pointer to char
  ~~~~~~~~~~~~~^~~~~~
pointer.c:42:7: error: cannot assign to variable 'cpc' with const-qualified type 'const char *const'
  cpc = *pcp;  // invalid? #Y#
  ~~~ ^
pointer.c:40:22: note: variable 'cpc' declared const here
  const char * const cpc = c;  // cpc is a const pointer to char const
  ~~~~~~~~~~~~~~~~~~~^~~~~~~
pointer.c:43:7: error: cannot assign to variable 'cpc' with const-qualified type 'const char *const'
  cpc = argv[0];  // invalid? #Y#
  ~~~ ^
pointer.c:40:22: note: variable 'cpc' declared const here
  const char * const cpc = c;  // cpc is a const pointer to char const
  ~~~~~~~~~~~~~~~~~~~^~~~~~~
pointer.c:44:8: error: read-only variable is not assignable
  *cpc = '@';  // invalid? #Y#
  ~~~~ ^
6 errors generated.
Makefile:20: recipe for target 'pointer.o' failed
make: *** [pointer.o] Error 1
```
- Write-up 3: For each of the types in the sizes.c exercise above, print the size of a pointer to that type. Recall that obtaining the address of an array or struct requires the &operator. Provide the output of your program (which should include the sizes of both the actual type and a pointer to it) in the writeup. 

```diff
diff --git a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/sizes.c b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/sizes.c
index 40c8e61..eb520f7 100644
--- a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/sizes.c
+++ b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/sizes.c
@@ -6,7 +6,7 @@

 #define PRINT_SIZE(type)  \
 do {                      \
-  printf("size of %s : %zu bytes \n", #type, sizeof(type));  \
+  printf("size of %s : %zu bytes, size of %s : %zu bytes\n", #type, sizeof(type), #type" *", sizeof(type *));  \
 } while(0)

 int main() {
@@ -55,10 +55,16 @@ int main() {


   // Array declaration. Use your macro to print the size of this.
-  int x[5];
+  typedef int x[5];
+  int y[5];

   // You can just use your macro here instead: PRINT_SIZE("student", you);
-  printf("size of %s : %zu bytes \n", "student", sizeof(you));
+  printf("size of %s : %zu bytes, size of %s : %zu bytes\n",
+        "student", sizeof(you), "&student", sizeof(&you));
+  printf("size of %s : %zu bytes, size of %s : %zu bytes\n",
+        "y[5]", sizeof(y), "&y", sizeof(&y));
+  PRINT_SIZE(student);
+  PRINT_SIZE(x);
 
   return 0;
 }
```
- output
```
size of short : 2 bytes, size of short * : 8 bytes
size of long : 8 bytes, size of long * : 8 bytes
size of char : 1 bytes, size of char * : 8 bytes
size of float : 4 bytes, size of float * : 8 bytes
size of double : 8 bytes, size of double * : 8 bytes
size of unsigned int : 4 bytes, size of unsigned int * : 8 bytes
size of long long : 8 bytes, size of long long * : 8 bytes
size of uint8_t : 1 bytes, size of uint8_t * : 8 bytes
size of uint16_t : 2 bytes, size of uint16_t * : 8 bytes
size of uint32_t : 4 bytes, size of uint32_t * : 8 bytes
size of uint64_t : 8 bytes, size of uint64_t * : 8 bytes
size of uint_fast8_t : 1 bytes, size of uint_fast8_t * : 8 bytes
size of uint_fast16_t : 8 bytes, size of uint_fast16_t * : 8 bytes
size of uintmax_t : 8 bytes, size of uintmax_t * : 8 bytes
size of intmax_t : 8 bytes, size of intmax_t * : 8 bytes
size of __int128 : 16 bytes, size of __int128 * : 8 bytes
size of int : 4 bytes
size of student : 8 bytes, size of &student : 8 bytes
size of y[5] : 20 bytes, size of &y : 8 bytes
size of student : 8 bytes, size of student * : 8 bytes
size of x : 20 bytes, size of x * : 8 bytes
```

## Argument passing 

```c
// Copyright (c) 2012 MIT License by 6.172 Staff

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

void swap(int i, int j) {
  int temp = i;
  i = j;
  j = temp;
}

int main() {
  int k = 1;
  int m = 2;
  swap(k, m);
  // What does this print?
  printf("k = %d, m = %d\n", k, m);

  return 0;
}
```

- Write-up 4: File swap.c contains the code to swap two integers. Rewrite the swap() function **using pointers** and make appropriate changes in main() function so that the values are swapped with a call to swap(). Compile the code with make swap and run the program with ./swap. Provide your edited code in the writeup. Verify that the results of both sizes.c and swap.c are correct by using the python script verifier.py. 

```diff
diff --git a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/swap.c b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/swap.c
index 9a15116..40c8e6f 100644
--- a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/swap.c
+++ b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/c-primer/swap.c
@@ -4,16 +4,16 @@
 #include <stdlib.h>
 #include <stdint.h>

-void swap(int i, int j) {
-  int temp = i;
-  i = j;
-  j = temp;
+void swap(int *i, int *j) {
+  int temp = *i;
+  *i = *j;
+  *j = temp;
 }

 int main() {
   int k = 1;
   int m = 2;
-  swap(k, m);
+  swap(&k, &m);
   // What does this print?
   printf("k = %d, m = %d\n", k, m);
```

# 5. Basic tools 

```bash
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ make
clang -O1 -DNDEBUG -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c testbed.c -o testbed.o
clang -O1 -DNDEBUG -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c matrix_multiply.c -o matrix_multiply.o
clang -o matrix_multiply testbed.o matrix_multiply.o -lrt -flto -fuse-ld=gold
```

```diff
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ git diff Makefile
diff --git a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/Makefile b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/Makefile
index 94bdde1..9c30122 100644
--- a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/Makefile
+++ b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/Makefile
@@ -31,7 +31,7 @@ CFLAGS_DEBUG := -g -DDEBUG -O0
 # In the release version, we ask for many optimizations; -O3 sets the
 # optimization level to three.  -DNDEBUG defines the NDEBUG macro,
 # which disables assertion checks.
-CFLAGS_RELEASE := -O1 -DNDEBUG
+CFLAGS_RELEASE := -O3 -DNDEBUG

 # These flags are used to invoke Clang's address sanitizer.
 CFLAGS_ASAN := -O1 -g -fsanitize=address
```

- **Write-up 5**: Now, what do you see when you type make clean; make? 
 
```bash
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ make clean
rm -f testbed.o matrix_multiply.o matrix_multiply .buildmode \
        testbed.gcda matrix_multiply.gcda \
        testbed.gcno matrix_multiply.gcno \
        testbed.c.gcov matrix_multiply.c.gcov fasttime.h.gcov
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ make
clang -O3 -DNDEBUG -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c testbed.c -o testbed.o
clang -O3 -DNDEBUG -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c matrix_multiply.c -o matrix_multiply.o
clang -o matrix_multiply testbed.o matrix_multiply.o -lrt -flto -fuse-ld=gold
```

- Debug

```gdb
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ gdb --args ./matrix_multiply
GNU gdb (Ubuntu 8.1-0ubuntu3.2) 8.1.0.20180409-git
Copyright (C) 2018 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from ./matrix_multiply...(no debugging symbols found)...done.
(gdb) run
Starting program: /mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
Setup
Running matrix_multiply_run()...

Program received signal SIGSEGV, Segmentation fault.
0x00000000004011a4 in matrix_multiply_run ()
(gdb) bt
#0  0x00000000004011a4 in matrix_multiply_run ()
#1  0x0000000000400f6e in main ()
(gdb) q
A debugging session is active.

        Inferior 1 [process 23078] will be killed.

Quit anyway? (y or n) y
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ make DEBUG=1
clang -g -DDEBUG -O0 -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c testbed.c -o testbed.o
clang -g -DDEBUG -O0 -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c matrix_multiply.c -o matrix_multiply.o
clang -o matrix_multiply testbed.o matrix_multiply.o -lrt -flto -fuse-ld=gold
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ gdb --args ./matrix_multiply
GNU gdb (Ubuntu 8.1-0ubuntu3.2) 8.1.0.20180409-git
Copyright (C) 2018 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from ./matrix_multiply...done.
(gdb) r
Starting program: /mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
Setup
Running matrix_multiply_run()...

Program received signal SIGSEGV, Segmentation fault.
0x00000000004011ef in matrix_multiply_run (A=0x404320, B=0x404280, C=0x404420) at matrix_multiply.c:90
90              C->values[i][j] += A->values[i][k] * B->values[k][j];
(gdb) p A->values[i][k]
$1 = 7
(gdb) p B->values[k][j]
Cannot access memory at address 0x0
(gdb) p B->values[k]
$2 = (int *) 0x0
(gdb) p k
$3 = 4
(gdb)
```

## AddressSanitizer 

AddressSanitizer是一个使用编译器工具和运行时库的快速的内存错误检查器。它可以检测各种错误（包括内存泄漏）。

- Memory leak check

  ```bash
  dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ make ASAN=1
  clang -O1 -g -fsanitize=address -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c testbed.c -o testbed.o
  clang -O1 -g -fsanitize=address -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c matrix_multiply.c -o matrix_multiply.o
  clang -o matrix_multiply testbed.o matrix_multiply.o -lrt -flto -fuse-ld=gold -fsanitize=address
  ```
- Write-up 6: What output do you see from AddressSanitizer regarding the memory bug? Paste it into your writeup here. 
  ```bash
  dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ ./matrix_multiply
  Setup
  Running matrix_multiply_run()...
  Elapsed execution time: 0.000002 sec

  =================================================================
  ==23199==ERROR: LeakSanitizer: detected memory leaks

  Direct leak of 48 byte(s) in 3 object(s) allocated from:
      #0 0x4db0a0  (/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply+0x4db0a0)
      #1 0x5142b9  (/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply+0x5142b9)
      #2 0x7faa01621b96  (/lib/x86_64-linux-gnu/libc.so.6+0x21b96)

  Indirect leak of 192 byte(s) in 12 object(s) allocated from:
      #0 0x4db0a0  (/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply+0x4db0a0)
      #1 0x514337  (/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply+0x514337)

  Indirect leak of 96 byte(s) in 3 object(s) allocated from:
      #0 0x4db0a0  (/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply+0x4db0a0)
      #1 0x514300  (/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply+0x514300)
      #2 0x7faa01621b96  (/lib/x86_64-linux-gnu/libc.so.6+0x21b96)

  SUMMARY: AddressSanitizer: 336 byte(s) leaked in 18 allocation(s).
  ```
## Valgrind 

Valgrind是另一个检查内存泄漏的工具。如果您要检查程序但无法对其进行检测，则Valgrind是检测内存错误的不错选择。

```
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ valgrind ./matrix_multiply -p
==23228== Memcheck, a memory error detector
==23228== Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
==23228== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==23228== Command: ./matrix_multiply -p
==23228==
==23228== error calling PR_SET_PTRACER, vgdb might block
Setup
Matrix A:
------------
    3      7      8      1  
    7      9      8      3
    1      2      6      7
    9      8      1      9
------------
Matrix B:
------------
    1      3      0      1
    5      5      7      8
    0      1      9      8
    9      3      1      7
------------
Running matrix_multiply_run()...
---- RESULTS ----
Result:
------------
==23228== Conditional jump or move depends on uninitialised value(s)
==23228==    at 0x50A08DA: vfprintf (vfprintf.c:1642)
==23228==    by 0x50A8F25: printf (printf.c:33)
==23228==    by 0x401167: print_matrix (matrix_multiply.c:68)
==23228==    by 0x400E4F: main (testbed.c:140)
==23228==
==23228== Use of uninitialised value of size 8
==23228==    at 0x509C86B: _itoa_word (_itoa.c:179)
==23228==    by 0x509FF0D: vfprintf (vfprintf.c:1642)
==23228==    by 0x50A8F25: printf (printf.c:33)
==23228==    by 0x401167: print_matrix (matrix_multiply.c:68)
==23228==    by 0x400E4F: main (testbed.c:140)
==23228==
==23228== Conditional jump or move depends on uninitialised value(s)
==23228==    at 0x509C875: _itoa_word (_itoa.c:179)
==23228==    by 0x509FF0D: vfprintf (vfprintf.c:1642)
==23228==    by 0x50A8F25: printf (printf.c:33)
==23228==    by 0x401167: print_matrix (matrix_multiply.c:68)
==23228==    by 0x400E4F: main (testbed.c:140)
==23228==
==23228== Conditional jump or move depends on uninitialised value(s)
==23228==    at 0x50A0014: vfprintf (vfprintf.c:1642)
==23228==    by 0x50A8F25: printf (printf.c:33)
==23228==    by 0x401167: print_matrix (matrix_multiply.c:68)
==23228==    by 0x400E4F: main (testbed.c:140)
==23228==
==23228== Conditional jump or move depends on uninitialised value(s)
==23228==    at 0x50A0B4C: vfprintf (vfprintf.c:1642)
==23228==    by 0x50A8F25: printf (printf.c:33)
==23228==    by 0x401167: print_matrix (matrix_multiply.c:68)
==23228==    by 0x400E4F: main (testbed.c:140)
==23228==
   47     55    122    130
   79     83    138    164
   74     40     75    114
  130     95     74    144
------------
---- END RESULTS ----
Elapsed execution time: 0.001296 sec
==23228== 
==23228== HEAP SUMMARY:
==23228==     in use at exit: 336 bytes in 18 blocks
==23228==   total heap usage: 39 allocs, 21 frees, 4,752 bytes allocated
==23228==
==23228== LEAK SUMMARY:
==23228==    definitely lost: 48 bytes in 3 blocks
==23228==    indirectly lost: 288 bytes in 15 blocks
==23228==      possibly lost: 0 bytes in 0 blocks
==23228==    still reachable: 0 bytes in 0 blocks
==23228==         suppressed: 0 bytes in 0 blocks
==23228== Rerun with --leak-check=full to see details of leaked memory
==23228==
==23228== For counts of detected and suppressed errors, rerun with: -v
==23228== Use --track-origins=yes to see where uninitialised values come from
==23228== ERROR SUMMARY: 126 errors from 5 contexts (suppressed: 0 from 0)
```

您需要-p开关`$ valgrind ./matrix_multiply -p`，因为Valgrind仅检测影响输出的内存错误。 您还应该使用“调试”版本来获得良好的结果。 此命令应打印出多行。 重要的是
```bash
==23228== Conditional jump or move depends on uninitialised value(s)
==23228==    at 0x50A08DA: vfprintf (vfprintf.c:1642)
==23228==    by 0x50A8F25: printf (printf.c:33)
==23228==    by 0x401167: print_matrix (matrix_multiply.c:68)
# 栈回溯显示BUG出现在这里
==23228==    by 0x400E4F: main (testbed.c:140)
```
#### Exercise: Fix matrix_multiply.c to initialize values in matrices before using them. Keep in mind that the matrices are stored in structs. Rebuild your program, and verify that it outputs a correct answer. Again, commit and push your changes to the Git repository. 

- Write-up 7: After you ﬁx your program, run ./matrix_multiply -p. Paste the program output showing that the matrix multiplication is working correctly. 

```diff
diff --git a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/Makefile b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/Makefile
index 94bdde1..9c30122 100644
--- a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/Makefile
+++ b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/Makefile
@@ -31,7 +31,7 @@ CFLAGS_DEBUG := -g -DDEBUG -O0
 # In the release version, we ask for many optimizations; -O3 sets the
 # optimization level to three.  -DNDEBUG defines the NDEBUG macro,
 # which disables assertion checks.
-CFLAGS_RELEASE := -O1 -DNDEBUG
+CFLAGS_RELEASE := -O3 -DNDEBUG

 # These flags are used to invoke Clang's address sanitizer.
 CFLAGS_ASAN := -O1 -g -fsanitize=address
diff --git a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply.c b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply.c
index c650d17..3b7eb28 100644
--- a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply.c
+++ b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/matrix_multiply.c
@@ -21,7 +21,7 @@
  **/

 #include "./matrix_multiply.h"
-
+#include "./tbassert.h"
 #include <stdio.h>
 #include <stdlib.h>
 #include <unistd.h>
@@ -75,14 +75,14 @@ void print_matrix(const matrix* m) {

 // Multiply matrix A*B, store result in C.
 int matrix_multiply_run(const matrix* A, const matrix* B, matrix* C) {
-  /*
+
   tbassert(A->cols == B->rows,
            "A->cols = %d, B->rows = %d\n", A->cols, B->rows);
   tbassert(A->rows == C->rows,
            "A->rows = %d, C->rows = %d\n", A->rows, C->rows);
   tbassert(B->cols == C->cols,
            "B->cols = %d, C->cols = %d\n", B->cols, C->cols);
-  */
+

   for (int i = 0; i < A->rows; i++) {
     for (int j = 0; j < B->cols; j++) {
diff --git a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/testbed.c b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/testbed.c
index 556172e..46697a8 100644
--- a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/testbed.c
+++ b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/testbed.c
@@ -92,7 +92,7 @@ int main(int argc, char** argv) {
 
   fprintf(stderr, "Setup\n");

-  A = make_matrix(kMatrixSize, kMatrixSize+1);
+  A = make_matrix(kMatrixSize, kMatrixSize);
   B = make_matrix(kMatrixSize, kMatrixSize);
   C = make_matrix(kMatrixSize, kMatrixSize);

@@ -107,6 +107,11 @@ int main(int argc, char** argv) {
         B->values[i][j] = 0;
       }
     }
+    for (int i = 0; i < C->rows; i++) {
+      for (int j = 0; j < C->cols; j++) {
+        C->values[i][j] = 0;
+      }
+    }
   } else {
     for (int i = 0; i < A->rows; i++) {
       for (int j = 0; j < A->cols; j++) {
@@ -118,6 +123,11 @@ int main(int argc, char** argv) {
         B->values[i][j] = rand_r(&randomSeed) % 10;
       }
     }
+    for (int i = 0; i < C->rows; i++) {
+      for (int j = 0; j < C->cols; j++) {
+        C->values[i][j] = 0;
+      }
+    }
   }

   if (should_print) {
```
- output
```
Setup
Matrix A: 
------------
    3      7      8      1
    7      9      8      3
    1      2      6      7
    9      8      1      9
------------
Matrix B:
------------
    1      3      0      1
    5      5      7      8
    0      1      9      8
    9      3      1      7
------------
Running matrix_multiply_run()...
---- RESULTS ----
Result:
------------
   47     55    122    130
   79     83    138    164
   74     40     75    114
  130     95     74    144
------------
---- END RESULTS ----
Elapsed execution time: 0.000002 sec
```
## Memory management 

```bash
Elapsed execution time: 0.001218 sec
==23304== 
==23304== HEAP SUMMARY:
==23304==     in use at exit: 336 bytes in 18 blocks
==23304==   total heap usage: 39 allocs, 21 frees, 4,752 bytes allocated
==23304==
==23304== LEAK SUMMARY:
# 这两行说明了有内存泄漏
==23304==    definitely lost: 48 bytes in 3 blocks
==23304==    indirectly lost: 288 bytes in 15 blocks
==23304==      possibly lost: 0 bytes in 0 blocks
==23304==    still reachable: 0 bytes in 0 blocks
==23304==         suppressed: 0 bytes in 0 blocks
==23304== Rerun with --leak-check=full to see details of leaked memory
==23304==
==23304== For counts of detected and suppressed errors, rerun with: -v
==23304== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

- 内存检测
```
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ valgrind --leak-check=full ./matrix_multiply -p
==23305== Memcheck, a memory error detector
==23305== Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
==23305== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
==23305== Command: ./matrix_multiply -p
==23305==
==23305== error calling PR_SET_PTRACER, vgdb might block
Setup
Matrix A: 
------------
    3      7      8      1  
    7      9      8      3
    1      2      6      7
    9      8      1      9
------------
Matrix B:
------------
    1      3      0      1  
    5      5      7      8
    0      1      9      8
    9      3      1      7
------------
Running matrix_multiply_run()...
---- RESULTS ----
Result:
------------
   47     55    122    130
   79     83    138    164
   74     40     75    114
  130     95     74    144
------------
---- END RESULTS ----
Elapsed execution time: 0.001171 sec
==23305== 
==23305== HEAP SUMMARY:
==23305==     in use at exit: 336 bytes in 18 blocks
==23305==   total heap usage: 39 allocs, 21 frees, 4,752 bytes allocated
==23305==
==23305== 112 (16 direct, 96 indirect) bytes in 1 blocks are definitely lost in loss record 7 of 9
==23305==    at 0x4C2FB0F: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==23305==    by 0x40110C: make_matrix (matrix_multiply.c:39)
==23305==    by 0x400AF6: main (testbed.c:95)
==23305==
==23305== 112 (16 direct, 96 indirect) bytes in 1 blocks are definitely lost in loss record 8 of 9
==23305==    at 0x4C2FB0F: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==23305==    by 0x40110C: make_matrix (matrix_multiply.c:39)
==23305==    by 0x400B08: main (testbed.c:96)
==23305==
==23305== 112 (16 direct, 96 indirect) bytes in 1 blocks are definitely lost in loss record 9 of 9
==23305==    at 0x4C2FB0F: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==23305==    by 0x40110C: make_matrix (matrix_multiply.c:39)
==23305==    by 0x400B1A: main (testbed.c:97)
==23305==
==23305== LEAK SUMMARY:
==23305==    definitely lost: 48 bytes in 3 blocks
==23305==    indirectly lost: 288 bytes in 15 blocks
==23305==      possibly lost: 0 bytes in 0 blocks
==23305==    still reachable: 0 bytes in 0 blocks
==23305==         suppressed: 0 bytes in 0 blocks
==23305==
==23305== For counts of detected and suppressed errors, rerun with: -v
==23305== ERROR SUMMARY: 3 errors from 3 contexts (suppressed: 0 from 0)
```
#### Exercise: Fix testbed.c by freeing these matrices after use with the function free_matrix. Re-build  your  program,  and  verify  that  Valgrind  doesn’t  complain  about anything.  Commit  and push your changes to the Git repository. 

```diff
diff --git a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/testbed.c b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/testbed.c
index 46697a8..23ec46b 100644
--- a/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/testbed.c
+++ b/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply/testbed.c
@@ -160,5 +160,9 @@ int main(int argc, char** argv) {
     printf("Elapsed execution time: %f sec\n", elapsed);
   }

+  free_matrix(A);
+  free_matrix(B);
+  free_matrix(C);
+
   return 0;
 }
```

- **Write-up 8**: Paste the output from Valgrind showing that there is no error in your program. 
  ```
  dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ valgrind --leak-check=full ./matrix_multiply -p
  ==23318== Memcheck, a memory error detector
  ==23318== Copyright (C) 2002-2017, and GNU GPL'd, by Julian Seward et al.
  ==23318== Using Valgrind-3.13.0 and LibVEX; rerun with -h for copyright info
  ==23318== Command: ./matrix_multiply -p
  ==23318==
  ==23318== error calling PR_SET_PTRACER, vgdb might block
  Setup
  Matrix A:
  ------------
      3      7      8      1  
      7      9      8      3
      1      2      6      7
      9      8      1      9
  ------------
  Matrix B:
  ------------
      1      3      0      1
      5      5      7      8
      0      1      9      8
      9      3      1      7
  ------------
  Running matrix_multiply_run()...
  ---- RESULTS ----
  Result:
  ------------
    47     55    122    130
    79     83    138    164
    74     40     75    114
    130     95     74    144
  ------------
  ---- END RESULTS ----
  Elapsed execution time: 0.001113 sec
  ==23318== 
  ==23318== HEAP SUMMARY:
  ==23318==     in use at exit: 0 bytes in 0 blocks
  ==23318==   total heap usage: 39 allocs, 39 frees, 4,752 bytes allocated
  ==23318==
  ==23318== All heap blocks were freed -- no leaks are possible
  ==23318==
  ==23318== For counts of detected and suppressed errors, rerun with: -v
  ==23318== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
  ```
## Checking code coverage 

测试中未执行的代码中可能存在错误。当有人在测试您的代码（例如教授或TA）时发现您从未行使过的代码行崩溃时，您可能会感到惊讶。此外，经常执行的行是优化的理想选择。`Gcov`工具为您的程序提供了逐行执行计数。

#### Exercise: To use `Gcov`, modify your Makeﬁle and add the ﬂags `-fprofile-arcs` and `-ftest-coverage` to the CFLAGS and LDFLAGS variables. You will have to rebuild from scratch using make clean followed by make DEBUG=1.  Try running your code normally with ./matrix_multiply -p.  Note that a number of new .gcda and .gcno ﬁles were created during your execution. 

## Performance enhancements 

#### Exercise: Increase the size of all matrices to 1000 × 1000. 

#### Exercise: First, you should run the program as is to get a performance measurement. Next, swap the j and k loops,  so that the inner loop strides sequentially through the rows of the C and B matrices.  Rerun the program, and verify that you have produced a speedup.  Commit and push your changes to the Git repository. 
- output (i, j, k)
```
Setup
Running matrix_multiply_run()...
Elapsed execution time: 1.373060 sec
```
- output (i, k, j)
```
Setup
Running matrix_multiply_run()...
Elapsed execution time: 0.747866 sec
```
## Compiler optimizations 

- Write-up 10: Report the execution time of your programs compiled in debug mode with -O0 and in non-debug mode with -O3. 
- output(i, k, j) -O3
  ```
  dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ make
  clang -O3 -DNDEBUG -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c matrix_multiply.c -o matrix_multiply.o
  clang -o matrix_multiply testbed.o matrix_multiply.o -lrt -flto -fuse-ld=gold
  dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ ./matrix_multiply
  Setup
  Running matrix_multiply_run()...
  Elapsed execution time: 0.747866 sec
  ```
- output(i, k, j) -O0
  ```
  dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ make DEBUG=1
  clang -g -DDEBUG -O0 -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c testbed.c -o testbed.o
  clang -g -DDEBUG -O0 -Wall -std=c99 -D_POSIX_C_SOURCE=200809L -c matrix_multiply.c -o matrix_multiply.o
  clang -o matrix_multiply testbed.o matrix_multiply.o -lrt -flto -fuse-ld=gold
  dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/CodeOptimize/MIT-6.172/Lectures/lec1/MIT6_172F18_hw1/matrix-multiply$ ./matrix_multiply
  Setup
  Running matrix_multiply_run()...
  Elapsed execution time: 3.451351 sec
  ```