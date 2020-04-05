# Homework 3: Vectorization 

在本作业和复习课中，您将尝试英特尔向量扩展。您**将学习如何对代码进行向量化**，向量化成功时进行配置，向量化似乎有效但没有加速时进行调试。

向量化是一种通用的优化技术，在某些情况下可以为您带来数量级的性能提升。这也是一个微妙的操作。
- 一方面，向量化是自动的：当`clang`被告知要进行积极的优化时，它会**自动尝试**将程序中的每个循环向量化。
- 另一方面，循环结构的微小变化会导致`clang`放弃而根本不向量化。

此外，这些小的更改可能允许代码向量化，但不会产生预期的加速。我们将讨论如何识别这些情况，以便您可以从向量单元中获得最大的收益。

# 1. Getting Started

# 2. Vectorization in clang

考虑在两个数组`A`和`B`之间执行元素相加的循环，将结果存储在数组`C`中。此循环是**数据并行**的，**因为在任何迭代 $i_1$ 期间的操作都独立于在任何迭代 $i_2$ 期间的操作，其中 $i_{1} \neq i_{2}$**。

简而言之，应该允许编译器**按任意顺序安排每个迭代**【Case 1】，或者**将多个迭代打包到一个时钟周期中**【Case 2】。
- 第一个选项将在下一个家庭作业中讨论。
- 第二种情况是向量化，也称为“单指令，多数据”或SIMD。

向量化是一个微妙的操作：
- 对循环结构的微小更改可能会导致`clang`放弃而根本不向量化，
- 或者对代码进行向量化，但不会产生预期的加速。 

有时，未向量化的代码可能比向量化代码快。在我们理解这种脆弱性之前，我们必须了解如何解释`clang`在对代码进行向量化时实际上在做什么；在第3节中，您将看到向量化代码的实际性能影响。

## 2.1  Example 1 
### Code
```c
// Copyright (c) 2015 MIT License by 6.172 Staff

#include <stdint.h>
#include <stdlib.h>
#include <math.h>

#define SIZE (1L << 16)

void test(uint8_t * a,  uint8_t * b) {
  uint64_t i;

  for (i = 0; i < SIZE; i++) {
    a[i] += b[i];
  }
}
```
编译为SSE指令，默认方式
```
$ make clean; make ASSEMBLE=1 VECTORIZE=1 example1.o 
```

### Build
```bash
dongkesi@DESKTOP-CL29DN1:/mnt/d/workspace/study/Code-Optimization/MIT-6.172/Lectures/Week3/MIT6_172F18_hw3/recitation3$ make ASSEMBLE=1 VECTORIZE=1 example1.o
# 您应该看到以下输出，通知您循环已向量化。尽管clang确实告诉了您这一点，但是您应该始终查看汇
# 编，以查看它是如何被向量化的，因为它不能保证最佳地使用向量寄存器。
clang -Wall -g -std=gnu99 -O3 -Rpass=loop-vectorize -Rpass-missed=loop-vectorize  -S  -c example1.c
example1.c:12:3: remark: vectorized loop (vectorization width: 16, interleaved count: 2) [-Rpass=loop-vectorize]
  for (i = 0; i < SIZE; i++) {
  ^
```
### example1.s

```s
$ cat example1.s 
        .text
        .file   "example1.c"
        .globl  test                    # -- Begin function test
        .p2align        4, 0x90
        .type   test,@function
test:                                   # @test
.Lfunc_begin0:
        .file   1 "example1.c"
        .loc    1 9 0                   # example1.c:9:0
        .cfi_startproc
# %bb.0:
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:i <- 0
        .loc    1 12 3 prologue_end     # example1.c:12:3
        leaq    65536(%rsi), %rax
        cmpq    %rdi, %rax
        jbe     .LBB0_2
# %bb.1:
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        leaq    65536(%rdi), %rax
        cmpq    %rsi, %rax
        jbe     .LBB0_2
# %bb.4:
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 0 3 is_stmt 0         # example1.c:0:3
        movq    $-65536, %rax           # imm = 0xFFFF0000
        .p2align        4, 0x90
.LBB0_5:                                # =>This Inner Loop Header: Depth=1
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
.Ltmp0:
        .loc    1 13 13 is_stmt 1       # example1.c:13:13
        movzbl  65536(%rsi,%rax), %ecx
        .loc    1 13 10 is_stmt 0       # example1.c:13:10
        addb    %cl, 65536(%rdi,%rax)
        .loc    1 13 13                 # example1.c:13:13
        movzbl  65537(%rsi,%rax), %ecx
        .loc    1 13 10                 # example1.c:13:10
        addb    %cl, 65537(%rdi,%rax)
        .loc    1 13 13                 # example1.c:13:13
        movzbl  65538(%rsi,%rax), %ecx
        .loc    1 13 10                 # example1.c:13:10
        addb    %cl, 65538(%rdi,%rax)
        .loc    1 13 13                 # example1.c:13:13
        movzbl  65539(%rsi,%rax), %ecx
        .loc    1 13 10                 # example1.c:13:10
        addb    %cl, 65539(%rdi,%rax)
.Ltmp1:
        .loc    1 12 17 is_stmt 1       # example1.c:12:17
        addq    $4, %rax
.Ltmp2:
        .loc    1 12 3 is_stmt 0        # example1.c:12:3
        jne     .LBB0_5
        jmp     .LBB0_6
.LBB0_2:
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 0 3                   # example1.c:0:3
        movq    $-65536, %rax           # imm = 0xFFFF0000
        .p2align        4, 0x90
.LBB0_3:                                # =>This Inner Loop Header: Depth=1
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
.Ltmp3:
        .loc    1 13 13 is_stmt 1       # example1.c:13:13
        movdqu  65536(%rsi,%rax), %xmm0
        movdqu  65552(%rsi,%rax), %xmm1
        .loc    1 13 10 is_stmt 0       # example1.c:13:10
        movdqu  65536(%rdi,%rax), %xmm2
        paddb   %xmm0, %xmm2
        movdqu  65552(%rdi,%rax), %xmm0
        movdqu  65568(%rdi,%rax), %xmm3
        movdqu  65584(%rdi,%rax), %xmm4
        movdqu  %xmm2, 65536(%rdi,%rax)
        paddb   %xmm1, %xmm0
        movdqu  %xmm0, 65552(%rdi,%rax)
        .loc    1 13 13                 # example1.c:13:13
        movdqu  65568(%rsi,%rax), %xmm0
        .loc    1 13 10                 # example1.c:13:10
        paddb   %xmm3, %xmm0
        .loc    1 13 13                 # example1.c:13:13
        movdqu  65584(%rsi,%rax), %xmm1
        .loc    1 13 10                 # example1.c:13:10
        movdqu  %xmm0, 65568(%rdi,%rax)
        paddb   %xmm4, %xmm1
        movdqu  %xmm1, 65584(%rdi,%rax)
.Ltmp4:
        .loc    1 12 26 is_stmt 1       # example1.c:12:26
        addq    $64, %rax
        jne     .LBB0_3
```

![](../Images/w3-2.png)

### Write-up 1: 
- 看上面的汇编代码。编译器已将代码翻译为将起始索引设置为$-2^{16}$，并为每次内存访问添加该代码。为什么不将开始索引设置为`0`并使用小的正偏移？
> 可以用加法来代替`cmp`操作，也方便计数。另外应为C代码中SIZE为常数，所以汇编时使用了该数值；如果该数值比较小，编译器不生成循环，而会执行循环展开，通过很多次寄存器操作完成加法操作，并且从0开始正偏移。

---

此代码首先检查数组`A`和数组`B`之间**是否存在部分重叠**。
- 如果存在重叠，则执行简单的非向量化代码。
- 如果没有重叠，则转到`.LBB0_2`，并执行向量化版本。

上面的充其量只能称为部分向量化。问题是编译器受我们所说的数组的约束。**如果我们告诉它更多，那么也许它可以做更多的优化**。最明显的是**通知编译器不可能有重叠**。这是在标准C中通过使用指针的`restrict`限定符来完成的。

```c
void test(uint8_t * restrict a,  uint8_t * restrict b) {
  uint64_t i;

  for (i = 0; i < SIZE; i++) {
    a[i] += b[i];
  }
}
```
下面是添加`restrict`限定符后生成的汇编代码，可以看到，只有向量化版本
```s
        .text
        .file   "example1.c"
        .globl  test                    # -- Begin function test
        .p2align        4, 0x90
        .type   test,@function
test:                                   # @test
.Lfunc_begin0:
        .file   1 "example1.c"
        .loc    1 9 0                   # example1.c:9:0
        .cfi_startproc
# %bb.0:
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:b <- %rsi
        movq    $-65536, %rax           # imm = 0xFFFF0000
.Ltmp0:
        #DEBUG_VALUE: test:i <- 0
        .p2align        4, 0x90
.LBB0_1:                                # =>This Inner Loop Header: Depth=1
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 13 13 prologue_end    # example1.c:13:13
        movdqu  65536(%rsi,%rax), %xmm0
        .loc    1 13 10 is_stmt 0       # example1.c:13:10
        movdqu  65536(%rdi,%rax), %xmm1
        paddb   %xmm0, %xmm1
        movdqu  65552(%rdi,%rax), %xmm0
        movdqu  65568(%rdi,%rax), %xmm2
        movdqu  65584(%rdi,%rax), %xmm3
        movdqu  %xmm1, 65536(%rdi,%rax)
        .loc    1 13 13                 # example1.c:13:13
        movdqu  65552(%rsi,%rax), %xmm1
        .loc    1 13 10                 # example1.c:13:10
        paddb   %xmm1, %xmm0
        movdqu  %xmm0, 65552(%rdi,%rax)
        .loc    1 13 13                 # example1.c:13:13
        movdqu  65568(%rsi,%rax), %xmm0
        .loc    1 13 10                 # example1.c:13:10
        paddb   %xmm2, %xmm0
        .loc    1 13 13                 # example1.c:13:13
        movdqu  65584(%rsi,%rax), %xmm1
        .loc    1 13 10                 # example1.c:13:10
        movdqu  %xmm0, 65568(%rdi,%rax)
        paddb   %xmm3, %xmm1
        movdqu  %xmm1, 65584(%rdi,%rax)
.Ltmp1:
        .loc    1 12 26 is_stmt 1       # example1.c:12:26
        addq    $64, %rax
        jne     .LBB0_1
.Ltmp2:
# %bb.2:
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 15 1                  # example1.c:15:1
        retq
```

生成的代码更好，但它**假设数据不是16字节对齐的**（movdqu是未对齐的move）。这也意味着上面的循环不能假定两个数组都对齐。如果clang是智能的，它可以测试数组要么都是对齐的，要么都是未对齐的，并且有一个快速的内部循环。但是，它目前没有这样做。

因此，为了获得我们期望的性能，我们**需要告诉clang数组是对齐的**。有几种方法可以做到这一点。
- 首先是构造一个（不可移植的）对齐类型，并在**函数接口**中使用它。
- 第二种方法是在函数本身中添加一个或两个**内部函数(intrinsic)**。

第二个选项更容易在较旧的代码基上实现，因为调用要向量化的函数的其他函数不必修改。其intrinsic为此被称为`__builtin_assume_aligned`：

```c
void test(uint8_t * restrict a,  uint8_t * restrict b) {
  uint64_t i;

  a = __builtin_assume_aligned(a, 16);
  b = __builtin_assume_aligned(b, 16);

  for (i = 0; i < SIZE; i++) {
    a[i] += b[i];
  }
}
```

在添加了指令之后``__builtin_assume_aligned``，您应该会看到类似于以下输出:

```s
        .text
        .file   "example1.c"
        .globl  test                    # -- Begin function test
        .p2align        4, 0x90
        .type   test,@function
test:                                   # @test
.Lfunc_begin0:
        .file   1 "example1.c"
        .loc    1 9 0                   # example1.c:9:0
        .cfi_startproc
# %bb.0:
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:b <- %rsi
        movq    $-65536, %rax           # imm = 0xFFFF0000
.Ltmp0:
        #DEBUG_VALUE: test:i <- 0
        .p2align        4, 0x90
.LBB0_1:                                # =>This Inner Loop Header: Depth=1
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 16 10 prologue_end    # example1.c:16:10
        movdqa  65536(%rdi,%rax), %xmm0
        movdqa  65552(%rdi,%rax), %xmm1
        movdqa  65568(%rdi,%rax), %xmm2
        movdqa  65584(%rdi,%rax), %xmm3
        paddb   65536(%rsi,%rax), %xmm0
        paddb   65552(%rsi,%rax), %xmm1
        movdqa  %xmm0, 65536(%rdi,%rax)
        movdqa  %xmm1, 65552(%rdi,%rax)
        paddb   65568(%rsi,%rax), %xmm2
        paddb   65584(%rsi,%rax), %xmm3
        movdqa  %xmm2, 65568(%rdi,%rax)
        movdqa  %xmm3, 65584(%rdi,%rax)
.Ltmp1:
        .loc    1 15 26                 # example1.c:15:26
        addq    $64, %rax
        jne     .LBB0_1
.Ltmp2:
# %bb.2:
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 18 1                  # example1.c:18:1
        retq
```

现在，最终，我们得到了我们正在寻找的漂亮的紧向量化代码（movdqa是对齐移动），因为clang使用打包的SSE指令一次添加16个字节。它还**设法一次加载和存储两个**，而它上次没有这样做。现在的问题是，我们已经了解需要告诉编译器什么，在自动向量化失败之前，循环可以复杂多少。

接下来，我们尝试使用以下命令打开AVX2指令：

```
$ make clean; make ASSEMBLE=1 VECTORIZE=1 AVX2=1 example1.o 
```
生成的代码如下

```as
        .text
        .file   "example1.c"
        .globl  test                    # -- Begin function test
        .p2align        4, 0x90
        .type   test,@function
test:                                   # @test
.Lfunc_begin0:
        .file   1 "example1.c"
        .loc    1 9 0                   # example1.c:9:0
        .cfi_startproc
# %bb.0:
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:b <- %rsi
        movq    $-65536, %rax           # imm = 0xFFFF0000
.Ltmp0:
        #DEBUG_VALUE: test:i <- 0
        .p2align        4, 0x90
.LBB0_1:                                # =>This Inner Loop Header: Depth=1
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 16 10 prologue_end    # example1.c:16:10
        vmovdqu 65536(%rdi,%rax), %ymm0
        vmovdqu 65568(%rdi,%rax), %ymm1
        vmovdqu 65600(%rdi,%rax), %ymm2
        vmovdqu 65632(%rdi,%rax), %ymm3
        vpaddb  65536(%rsi,%rax), %ymm0, %ymm0
        vpaddb  65568(%rsi,%rax), %ymm1, %ymm1
        vpaddb  65600(%rsi,%rax), %ymm2, %ymm2
        vmovdqu %ymm0, 65536(%rdi,%rax)
        vmovdqu %ymm1, 65568(%rdi,%rax)
        vmovdqu %ymm2, 65600(%rdi,%rax)
        vpaddb  65632(%rsi,%rax), %ymm3, %ymm0
        vmovdqu %ymm0, 65632(%rdi,%rax)
.Ltmp1:
        .loc    1 15 26                 # example1.c:15:26
        addq    $128, %rax
        jne     .LBB0_1
.Ltmp2:
# %bb.2:
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 18 1                  # example1.c:18:1
        vzeroupper
        retq
.Ltmp3:
```
### Write-up 2: 
使用AVX2寄存器时，此代码**仍不对齐**。修复代码以确保它使用**对齐移动**以获得最佳性能。

代码中依然使用如下的指令，表示没有对齐
```
vmovdqu 65536(%rdi,%rax), %ymm0
```
AVX2是256-bit，按照SSE 128bit推断，应该使用32字节对齐，所以应使用`__builtin_assume_aligned`内置函数告诉clang数组是32字节对齐。

```c
void test(uint8_t * restrict a,  uint8_t * restrict b) {
  uint64_t i;

  a = __builtin_assume_aligned(a, 32);
  b = __builtin_assume_aligned(b, 32);
  
  for (i = 0; i < SIZE; i++) {
    a[i] += b[i];
  }
}
```
查看生成的代码，发现`vmovdqu`->`vmovdqa`
```as
        .text
        .file   "example1.c"
        .globl  test                    # -- Begin function test
        .p2align        4, 0x90
        .type   test,@function
test:                                   # @test
.Lfunc_begin0:
        .file   1 "example1.c"
        .loc    1 9 0                   # example1.c:9:0
        .cfi_startproc
# %bb.0:
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:b <- %rsi
        movq    $-65536, %rax           # imm = 0xFFFF0000
.Ltmp0:
        #DEBUG_VALUE: test:i <- 0
        .p2align        4, 0x90
.LBB0_1:                                # =>This Inner Loop Header: Depth=1
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 16 10 prologue_end    # example1.c:16:10
        vmovdqa 65536(%rdi,%rax), %ymm0
        vmovdqa 65568(%rdi,%rax), %ymm1
        vmovdqa 65600(%rdi,%rax), %ymm2
        vmovdqa 65632(%rdi,%rax), %ymm3
        vpaddb  65536(%rsi,%rax), %ymm0, %ymm0
        vpaddb  65568(%rsi,%rax), %ymm1, %ymm1
        vpaddb  65600(%rsi,%rax), %ymm2, %ymm2
        vmovdqa %ymm0, 65536(%rdi,%rax)
        vmovdqa %ymm1, 65568(%rdi,%rax)
        vmovdqa %ymm2, 65600(%rdi,%rax)
        vpaddb  65632(%rsi,%rax), %ymm3, %ymm0
        vmovdqa %ymm0, 65632(%rdi,%rax)
.Ltmp1:
        .loc    1 15 26                 # example1.c:15:26
        addq    $128, %rax
        jne     .LBB0_1
.Ltmp2:
# %bb.2:
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 18 1                  # example1.c:18:1
        vzeroupper
        retq
```

## 2.2  Example 2 

### Base Code

```c
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

#define SIZE (1L << 16)

void test(uint8_t * restrict a, uint8_t * restrict b) {
  uint64_t i;

  uint8_t * x = __builtin_assume_aligned(a, 16);
  uint8_t * y = __builtin_assume_aligned(b, 16);

  for (i = 0; i < SIZE; i++) {
    /* max() */
    if (y[i] > x[i]) x[i] = y[i];
  }
}
```
编译
```bash
$ make clean; make ASSEMBLE=1 VECTORIZE=1 example2.o 
```
请注意，程序集没有很好地向量化量化。现在，将函数更改为如下所示：
```c
void test(uint8_t * restrict a, uint8_t * restrict b) {
  uint64_t i;

  a = __builtin_assume_aligned(a, 16);
  b = __builtin_assume_aligned(b, 16);

  for (i = 0; i < SIZE; i++) {
    /* max() */
    a[i] = (b[i] > a[i]) ? b[i] : a[i];
  }
}
```
现在，您实际上看到了带有`movdqa`和`pmaxub`指令的向量化程序集。
```as
        .text
        .file   "example2.c"
        .globl  test                    # -- Begin function test
        .p2align        4, 0x90
        .type   test,@function
test:                                   # @test
.Lfunc_begin0:
        .file   1 "example2.c"
        .loc    1 9 0                   # example2.c:9:0
        .cfi_startproc
# %bb.0:
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:b <- %rsi
        movq    $-65536, %rax           # imm = 0xFFFF0000
.Ltmp0:
        #DEBUG_VALUE: test:i <- 0
        .p2align        4, 0x90
.LBB0_1:                                # =>This Inner Loop Header: Depth=1
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 17 13 prologue_end    # example2.c:17:13
        movdqa  65536(%rsi,%rax), %xmm0
        movdqa  65552(%rsi,%rax), %xmm1
        .loc    1 17 12 is_stmt 0       # example2.c:17:12
        pmaxub  65536(%rdi,%rax), %xmm0
        pmaxub  65552(%rdi,%rax), %xmm1
        .loc    1 17 10                 # example2.c:17:10
        movdqa  %xmm0, 65536(%rdi,%rax)
        movdqa  %xmm1, 65552(%rdi,%rax)
        .loc    1 17 13                 # example2.c:17:13
        movdqa  65568(%rsi,%rax), %xmm0
        movdqa  65584(%rsi,%rax), %xmm1
        .loc    1 17 12                 # example2.c:17:12
        pmaxub  65568(%rdi,%rax), %xmm0
        pmaxub  65584(%rdi,%rax), %xmm1
        .loc    1 17 10                 # example2.c:17:10
        movdqa  %xmm0, 65568(%rdi,%rax)
        movdqa  %xmm1, 65584(%rdi,%rax)
.Ltmp1:
        .loc    1 15 26 is_stmt 1       # example2.c:15:26
        addq    $64, %rax
        jne     .LBB0_1
.Ltmp2:
# %bb.2:
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:a <- %rdi
        .loc    1 19 1                  # example2.c:19:1
        retq
```
### Write-up 3: 

为编译器生成截然不同的程序集提供理论依据。

> 看到的主要不同是由`if`语句变成了三元条件表达式，该表达式帮助编译很好的理解代码是找最大值的意思。`pmaxub`这条向量指令正好对应该操作。
> - https://www.felixcloutier.com/x86/pmaxub:pmaxuw

## 2.3 Example 3 
### Base Code

```c
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

#define SIZE (1L << 16)

void test(uint8_t * restrict a, uint8_t * restrict b) {
  uint64_t i;

  for (i = 0; i < SIZE; i++) {
    a[i] = b[i + 1];
  }
}
```
此代码汇编后，并没有生成向量指令，而是直接调用了memcpy
```as
# %bb.0:
        .loc    1 12 3 prologue_end     # example3.c:12:3
        pushq   %rax
        .cfi_def_cfa_offset 16
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:a <- %rdi
        #DEBUG_VALUE: test:b <- %rsi
        #DEBUG_VALUE: test:b <- %rsi
.Ltmp0:
        #DEBUG_VALUE: test:i <- 0
        addq    $1, %rsi
.Ltmp1:
        .loc    1 13 10                 # example3.c:13:10
        movl    $65536, %edx            # imm = 0x10000
        #DEBUG_VALUE: test:a <- %rdi
        callq   memcpy
.Ltmp2:
        .loc    1 15 1                  # example3.c:15:1
        popq    %rax
        retq
```
### Write-up 4: 

Inspect the assembly and determine why the assembly does not include instructions with vector registers. Do you think it would be faster if it did vectorize? Explain. 

代码中直接调用了库中的`memcpy`，因为为了高效实现内存拷贝，需要考虑很多因素，块拷贝，对齐操作，重叠等因素，memcpy内部针对这些情况做了不同的应对，从而使代码更加复杂，当然为了高效也一定使用了向量拷贝。针对我们的代码，如果是完美的循环，没有这些不良因素，无疑向量操作快，但同时memcpy在这种情况下也会使用向量，所以两者应该是等价的。

## 2.4  Example 4 
### Base Code

```c
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define SIZE (1L << 16)

double test(double * restrict a) {
  size_t i;

  double *x = __builtin_assume_aligned(a, 16);

  double y = 0;

  for (i = 0; i < SIZE; i++) {
    y += x[i];
  }
  return y;
}

int main() {
  double a[SIZE];
  for (int i = 0; i < SIZE; i++) {
    a[i] = 1.0/(i*1.0+1.0);
  }
  double sum = test(a);
  printf("The decimal floating point sum result is: %f\n", sum);
  printf("The raw floating point sum result is: %a\n", sum);
}
```
### Build

```bash
$ make clean; make ASSEMBLE=1 VECTORIZE=1 example4.o 
```

![](../Images/w3-4.png)

> 都是在同一个`xmm0`上累加，只是8字节double的累加操作，用到的是非向量指令`addsd`。

![](../Images/w3-3.png)


注意，这实际上**并没有向量化**，因为`xmm`寄存器是在8字节块上操作的。这里的问题是，`clang`不允许重新排序我们提供的操作。尽管**加法**运算与实数相关联，但它们与浮点数无关。（例如，考虑带符号的零会发生什么）

此外，我们需要告诉`clang`，重新排序操作对我们来说是可以的。为此，我们需要添加另一个编译标志，`-ffast-math`。将`-ffast-math`标志添加到`Makefile`中，然后再次编译程序。

![](../Images/w3-5.png)

> 使用了向量指令`addpd`

### Write-up 5: 
检查汇编并验证它实际上是否正确向量化。当您运行以下命令并带有或不带有`-ffast-math`标志时，您还注意到了什么？
```
$ clang -O3 example4.c -o example4; ./example4
``` 
具体来说，为什么你会看到输出的不同。
> 结果都一样

```bash
$ clang -O3 -ffast-math example4.c -o example4; ./example4The decimal floating point sum result is: 11.667578
The raw floating point sum result is: 0x1.755cccec10aa3p+3
$ clang -O3  example4.c -o example4; ./example4
The decimal floating point sum result is: 11.667578
The raw floating point sum result is: 0x1.755cccec10aa5p+3
```
# 3  Performance Impacts of Vectorization 

我们现在将熟悉哪些代码进行/不进行向量化，并讨论如何从向量化中提高速度。

## Base Code

```c
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "./fasttime.h"

// N is small enough so that 3 arrays of size N fit into the AWS machine
// level 1 caches (which are 32 KB each, as seen by running `lscpu`)
#define N          1024

// Run for multiple experiments to reduce measurement error on gettime().
#define I          100000

// Which operations are vectorizable?
// Guarding it with #ifndef allows passing -D"__OP__=$value" on the
// command line
#ifndef __OP__
#define __OP__     +
#endif
#ifndef __TYPE__
#define __TYPE__   uint32_t
#endif

// Define a way of automatically converting __OP__ and __TYPE__ into string literals
#define stringify(V) _stringify(V)
#define _stringify(V) #V

int main(int argc, char *argv[]) {
    __TYPE__ A[N];
    __TYPE__ B[N];
    __TYPE__ C[N];
    __TYPE__ total = 0;

    int i, j;
    unsigned int seed = 0;

    // Touch each element in each array before we start the timed part
    // of execution.  This operation brings all arrays into the level 1
    // cache and gives us a 'cleaner' view of speedup from vectorization.
    for (j = 0; j < N; j++) {
        A[j] = 0;  // 0 was chosen arbitrarily
        B[j] = 0;
        C[j] = 0;
    }

    fasttime_t time1 = gettime();

    for (i = 0; i < I; i++) {
        for (j = 0; j < N; j++) {
            C[j] = A[j] __OP__ B[j];
        }
    }

    fasttime_t time2 = gettime();

    // Forces the compiler to not prune away any loop operations
    total += C[rand_r(&seed) % N];

    double elapsedf = tdiff(time1, time2);
    // C concatenates adjacent string literals.  We take advantage of
    // this and include a print-out of __OP__ and __TYPE__
    printf("Elapsed execution time: %f sec; N: %d, I: %d,"
           " __OP__: %s, __TYPE__: %s\n",
           elapsedf, N, I, stringify(__OP__), stringify(__TYPE__));

    return total;
}
```

## 3.1  The Many Facets of a Data Parallel Loop 

在`loop.c`中，我们编写了一个循环，在两个数组`A`和`B`之间执行元素级的操作（默认情况下为加法），并将结果存储在数组`C`中。如果检查代码，您将看到我们的循环没有任何有用的工作（即`A`和`B`没有填充任何初始值）。我们只是用这个循环来演示概念。此外，我们在`I`上添加了一个外循环，其目的是消除`gettime()`中的测量错误。

让我们看看向量化的速度有多快。
- 运行`make`并运行`awsrun ./loop`。记录经过的执行时间。
- 然后运行`make VECTORIZE=1`并再次运行`awsrun ./loop`。记录向量化的执行时间。
- 标志`-mavx2`告诉`clang`使用带有更大向量寄存器的高级向量扩展。运行`make VECTORIZE=1 AVX2=1`并再次运行`awsrun ./loop`。

请注意，您必须使用awsrun机器进行此操作；否则可能会收到非法指令（core dumped）之类的消息。通过在`cat/proc/cpuinfo`输出的`flags`部分中查找`AVX2`，可以检查计算机是否支持`AVX2`指令。记录向量化的执行时间。

```bash
# 会显示8个processor，分别属于4个core
$ cat /proc/cpuinfo 
processor       : 0
vendor_id       : GenuineIntel
cpu family      : 6
model           : 142
model name      : Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
stepping        : 10
microcode       : 0xffffffff
cpu MHz         : 2001.000
cache size      : 256 KB
physical id     : 0
siblings        : 8
core id         : 0
cpu cores       : 4
apicid          : 0
initial apicid  : 0
fpu             : yes
fpu_exception   : yes
cpuid level     : 6
wp              : yes
flags           : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave osxsave avx f16c rdrand lahf_lm abm 3dnowprefetch fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt ibrs ibpb stibp ssbd
bogomips        : 4002.00
clflush size    : 64
cache_alignment : 64
address sizes   : 36 bits physical, 48 bits virtual
power management:

processor       : 1
...
// 一共4个core，8个processor
# 另一种查看CPU信息的方式
$ lscpu 
Architecture:        x86_64
CPU op-mode(s):      32-bit, 64-bit
Byte Order:          Little Endian
CPU(s):              8
On-line CPU(s) list: 0-7
Thread(s) per core:  2
Core(s) per socket:  4
Socket(s):           1
Vendor ID:           GenuineIntel
CPU family:          6
Model:               142
Model name:          Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
Stepping:            10
CPU MHz:             2001.000
CPU max MHz:         2001.0000
BogoMIPS:            4002.00
Virtualization:      VT-x
Hypervisor vendor:   Windows Subsystem for Linux
Virtualization type: container
Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 fma cx16 xtpr pdcm pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave osxsave avx f16c rdrand lahf_lm abm 3dnowprefetch fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid mpx rdseed adx smap clflushopt intel_pt ibrs ibpb stibp ssbd
```

```bash
# Test 1
$ make
clang -Wall -std=gnu99 -g -O3 -DNDEBUG -fno-vectorize  -c loop.c
clang -o loop loop.o -lrt
$ ./loop
Elapsed execution time: 0.042948 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t

# Test 2
$ make VECTORIZE=1
clang -Wall -std=gnu99 -g -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -c loop.c
loop.c:70:9: remark: vectorized loop (vectorization width: 4, interleaved
      count: 2) [-Rpass=loop-vectorize]
        for (j = 0; j < N; j++) {
        ^
clang -o loop loop.o -lrt
$ ./loop
Elapsed execution time: 0.011106 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t

# Test 3
$ make VECTORIZE=1 AVX2=1
clang -Wall -std=gnu99 -g -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math -mavx2  -c loop.c
loop.c:70:9: remark: vectorized loop (vectorization width: 8, interleaved
      count: 4) [-Rpass=loop-vectorize]
        for (j = 0; j < N; j++) {
        ^
clang -o loop loop.o -lrt
$ ./loop
Elapsed execution time: 0.006277 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
```

#### Write-up 6: 

向量化代码比非向量化代码的速度有多快？

> 默认向量化代码比非向量化快大约4倍，AVX2向量化比非向量化快大约7倍

使用`-mavx2`有什么额外的加速效果？您可能希望运行此实验几次，并取经过时间的中位数；您可以报告最接近100%的答案（例如，2×，3×，等等）。

> 理论8x，实际大约7x

关于`awsrun`机器上默认向量寄存器的位宽度，您能推断出什么？

> 在个人电脑上运行，默认向量快了4倍，数据类型是`uint32`，所以默认寄存器位宽度为4x32=128-bits

AVX2向量寄存器的位宽是多少？

> AVX2在默认向量上增速2倍，所以是2x128=256-bits

【示：除了加速和向量化报告外，最相关的信息是每个数组的数据类型是`uint32`。】

### 3.1.1  Flags to enable and debug vectorization 

默认情况下，向量化是启用的，但可以使用`-fvectorize`标志显式打开。

启用向量化时，
- `-Rpass=loop-vectorize` flag标识**成功向量化**的循环，-
- `-Rpass-missed=loop-vectorize` flag标识**失败向量化**的循环并指示是否指定了向量化（请参见Makefile）。
- 此外，还可以添加`-Rpass-analysis=loop-vectorize`来**标识导致向量化失败的语句**。

### 3.1.2  Debugging through assembly code inspection 

查看代码如何向量化的另一种方法是**查看编译器的程序集输出**。运行`$ make ASSEMBLE=1 VECTORIZE=1` 

这将产生`loop.s`，其中包含人类可读的x86程序集，如来自Recitation 2的`perf annotate-f`。注意编译可能会“失败”，因为这个flag告诉clang不要产生loop.o。

#### Write-up 7: 

设置/未设置向量化flag时，比较loop.s的内容。

> Vector vs No-Vector with unroll
  
![](../Images/w3-6.png)

> Vector vs No-Vector with no-unroll

![](../Images/w3-7.png)

- 哪个指令（复制文本到这）负责向量加法操作？

```as
  paddd	12320(%rsp,%rax), %xmm0
```

- 当您另外传递`AVX2=1`时，哪个指令（复制文本到这）负责向量加法操作？
```as
vpaddd  12320(%rsp,%rax), %ymm0, %ymm0
```

> Vector with no-unroll vs Vector with no-unroll and AVX2

![](../Images/w3-8.png)

您可以在LMOD上查找x86说明手册。查找MMX和SSE2指令，它们是向量运算。为了使程序集代码更具可读性，最好通过移动`Makefile`中的`-g`和`-gdwarf-3` CFLAGS从`release builds`中删除调试符号。在研究程序集代码时，最好使用`-fno-unroll-loops` flag关闭循环展开。

### 3.1.3 Flavors of vector arithmetic 

正如在讲座中所讨论的，向量单元直接在硬件中构建。为了支持更灵活的向量运算（如向量减法或乘法），必须为每个运算添加额外的硬件。

#### Write-up 8: 

使用`__OP__`宏在数据并行循环中实验不同的运算符。对于某些操作，您将得到零的除法错误，因为我们将数组`B`初始化为零-修复这个问题以任何你喜欢的方式。**是否有任何版本的循环不能使用`VECTORIZE=1 AVX2=1`向量化**？研究`<<`的汇编代码，仅使用`VECTORIZE=1`，并解释它与`AVX2`版本的区别。

> `%`与`/`不会向量化

结果可能会让你大吃一惊。例如，比较`*`和`<<`(shift)的结果。问题是，除非传递`-mavx2`，否则按变量(B[j])移位不是受支持的向量指令。将`B[j]`更改为常量值应允许代码再次可向量化。

![](../Images/w3-9.png)

- Test 1: 使用`make ASSEMBLE=1 VECTORIZE=1 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='$value'"`编译
  > 注意这里的`$value`代表某个操作符，必须使用单引号，否则在测试`<`, `<<`之类的操作时会导致编译错误
  - https://www.programiz.com/c-programming/c-operators
  - https://docs.oracle.com/cd/E36784_01/html/E36859/gntbd.html#scrolltoc
  
    ![](../Images/w3-10.png)

    ![](../Images/w3-11.png)

  - `__OP__` -> `+`
    ```as
    // vmovdqu: Move Unaligned Packed Integer Values
    vmovdqu	8224(%rsp,%rcx), %ymm0
    // vpaddd: Add Packed Integers
    vpaddd	12320(%rsp,%rcx), %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `-`
    ```as
    vmovdqu	12320(%rsp,%rcx), %ymm0
    // vpsubd: Packed Integer Subtract
    vpsubd	8224(%rsp,%rcx), %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `*`
    ```as
    // vmovdqu: Move Unaligned Packed Integer Values
    vmovdqu	8224(%rsp,%rcx), %ymm0
    // vpmulld: Multiply Packed Integers and Store Low Result
    vpmulld	12320(%rsp,%rcx), %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `&`
    ```as
    // vmovups: Move Unaligned Packed Single-Precision Floating-Point Values
    vmovups	8224(%rsp,%rcx), %ymm0
    // vandps: Bitwise Logical AND of Packed Single-Precision Floating-Point Values
    vandps	12320(%rsp,%rcx), %ymm0, %ymm0
    vmovups	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `|`
    ```as
    // vmovups: Move Unaligned Packed Single-Precision Floating-Point Values
    vmovups	8224(%rsp,%rcx), %ymm0
    // vorps: Bitwise Logical OR of Single-Precision Floating-Point Values
    vorps	12320(%rsp,%rcx), %ymm0, %ymm0
    vmovups	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `^`
    ```as
    // vmovups: Move Unaligned Packed Single-Precision Floating-Point
    vmovups	8224(%rsp,%rcx), %ymm0
    // Bitwise Logical XOR for Single-Precision Floating-Point Values
    vxorps	12320(%rsp,%rcx), %ymm0, %ymm0
    vmovups	%ymm0, 4128(%rsp,%rcx)
    ``` 
  - `__OP__` -> `&&`
    ```as
    // vpcmpeqd: Compare Packed Integers for Equality
    vpcmpeqd	12320(%rsp,%rdx,4), %ymm0, %ymm3
    // vpxor: Exclusive Or
    vpxor	%ymm1, %ymm3, %ymm4
    // vpmaskmovd: Conditional SIMD Integer Packed Loads and Stores
    vpmaskmovd	(%rsi), %ymm4, %ymm4
    vpcmpeqd	%ymm0, %ymm4, %ymm4
    vpxor	%ymm1, %ymm4, %ymm4
    // vpandn: Logical AND NOT
    vpandn	%ymm4, %ymm3, %ymm3
    // vpand: Logical AND
    vpand	%ymm2, %ymm3, %ymm3
    // vmovdqu: Move Unaligned Packed Integer Values
    vmovdqu	%ymm3, 4128(%rsp,%rdx,4)
    addq	$32, %rsi
    addq	$8, %rdx
    ```    
  - `__OP__` -> `||`
    ```as
    vmovdqu	12320(%rsp,%rdx,4), %ymm2
    vpcmpeqd	%ymm0, %ymm2, %ymm3
    vpmaskmovd	(%rsi), %ymm3, %ymm3
    vpor	%ymm2, %ymm3, %ymm2
    vpcmpeqd	%ymm0, %ymm2, %ymm2
    vpandn	%ymm1, %ymm2, %ymm2
    vmovdqu	%ymm2, 4128(%rsp,%rdx,4)
    addq	$32, %rsi
    addq	$8, %rdx
    ```       
  - `__OP__` -> `<<`
    ```as
    vmovdqu	12320(%rsp,%rcx), %ymm0
    // vpsllvd: Variable Bit Shift Left Logical
    vpsllvd	8224(%rsp,%rcx), %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `>>`
    ```as
    vmovdqu	12320(%rsp,%rcx), %ymm0
    // vpsrlvd: Variable Bit Shift Right Logical
    vpsrlvd	8224(%rsp,%rcx), %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `>`
    ```as
    vpxor	8224(%rsp,%rcx), %ymm0, %ymm1
    vpxor	12320(%rsp,%rcx), %ymm0, %ymm2
    // vpcmpgtd: Compare Packed Integers for Greater Than
    vpcmpgtd	%ymm1, %ymm2, %ymm1
    // vpsrld: Shift Double Quadword Right Logical
    vpsrld	$31, %ymm1, %ymm1
    vmovdqu	%ymm1, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `>=`
    ```as
    vmovdqu	12320(%rsp,%rcx), %ymm0
    // vpmaxud: Maximum of Packed Unsigned Integers
    vpmaxud	8224(%rsp,%rcx), %ymm0, %ymm1
    vpcmpeqd	%ymm1, %ymm0, %ymm0
    vpsrld	$31, %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `<`
    ```as
    vpxor	12320(%rsp,%rcx), %ymm0, %ymm1
    vpxor	8224(%rsp,%rcx), %ymm0, %ymm2
    vpcmpgtd	%ymm1, %ymm2, %ymm1
    vpsrld	$31, %ymm1, %ymm1
    vmovdqu	%ymm1, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `<=`
    ```as
    vmovdqu	12320(%rsp,%rcx), %ymm0
    vpminud	8224(%rsp,%rcx), %ymm0, %ymm1
    vpcmpeqd	%ymm1, %ymm0, %ymm0
    vpsrld	$31, %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rcx)
    ```
  - `__OP__` -> `==`
    ```as
    vmovdqu	12320(%rsp,%rcx), %ymm0
    vpcmpeqd	8224(%rsp,%rcx), %ymm0, %ymm0
    vpsrld	$31, %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rcx)
    ```            
  - `__OP__` -> `!=`
    ```as
    vmovdqu	12320(%rsp,%rcx), %ymm1
    vpcmpeqd	8224(%rsp,%rcx), %ymm1, %ymm1
    vpandn	%ymm0, %ymm1, %ymm1
    vmovdqu	%ymm1, 4128(%rsp,%rcx)
    ```                              
  - 编译成功但是没有生成向量的操作符`%`, `/`
  - `__OP__` -> `%`
    ```as
    .LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                            # =>  This Inner Loop Header: Depth=2
    vmovdqu	12320(%rsp,%rdi), %ymm0
    vextracti128	$1, %ymm0, %xmm2
    vpextrd	$1, %xmm2, %eax
    vmovdqu	8224(%rsp,%rdi), %ymm1
    vextracti128	$1, %ymm1, %xmm3
    vpextrd	$1, %xmm3, %ecx
    xorl	%edx, %edx
    divl	%ecx
    movl	%edx, %ecx
    vmovd	%xmm2, %eax
    vmovd	%xmm3, %ebx
    xorl	%edx, %edx
    divl	%ebx
    vmovd	%edx, %xmm4
    vpinsrd	$1, %ecx, %xmm4, %xmm4
    vpextrd	$2, %xmm2, %eax
    vpextrd	$2, %xmm3, %ecx
    xorl	%edx, %edx
    divl	%ecx
    vpinsrd	$2, %edx, %xmm4, %xmm4
    vpextrd	$3, %xmm2, %eax
    vpextrd	$3, %xmm3, %ecx
    xorl	%edx, %edx
    divl	%ecx
    vpinsrd	$3, %edx, %xmm4, %xmm2
    vpextrd	$1, %xmm0, %eax
    vpextrd	$1, %xmm1, %ecx
    xorl	%edx, %edx
    divl	%ecx
    movl	%edx, %ecx
    vmovd	%xmm0, %eax
    vmovd	%xmm1, %ebx
    xorl	%edx, %edx
    divl	%ebx
    vmovd	%edx, %xmm3
    vpinsrd	$1, %ecx, %xmm3, %xmm3
    vpextrd	$2, %xmm0, %eax
    vpextrd	$2, %xmm1, %ecx
    xorl	%edx, %edx
    divl	%ecx
    vpinsrd	$2, %edx, %xmm3, %xmm3
    vpextrd	$3, %xmm0, %eax
    vpextrd	$3, %xmm1, %ecx
    xorl	%edx, %edx
    divl	%ecx
    vpinsrd	$3, %edx, %xmm3, %xmm0
    vinserti128	$1, %xmm2, %ymm0, %ymm0
    vmovdqu	%ymm0, 4128(%rsp,%rdi)
    addq	$32, %rdi
    jne	.LBB0_4
    ```
  - `__OP__` -> `/`
    ```as
    .LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                            # =>  This Inner Loop Header: Depth=2
      movl	12320(%rsp,%rsi), %eax
      xorl	%edx, %edx
      divl	8224(%rsp,%rsi)
      movl	%eax, 4128(%rsp,%rsi)
      addq	$4, %rsi
      jne	.LBB0_4    
    ```
- Test 2: 使用编译 `make ASSEMBLE=1 VECTORIZE=1 EXTRA_CFLAGS+=-D"__OP__='$value'"`
  - `__OP__` -> `<<`
    > 对比AVX2使能的版本，代码复杂了很多
    ```as
    movdqa	12320(%rsp,%rcx), %xmm1
    movdqa	8224(%rsp,%rcx), %xmm2
    pslld	$23, %xmm2
    paddd	%xmm0, %xmm2
    cvttps2dq	%xmm2, %xmm2
    pshufd	$245, %xmm2, %xmm3      # xmm3 = xmm2[1,1,3,3]
    pmuludq	%xmm1, %xmm2
    pshufd	$232, %xmm2, %xmm2      # xmm2 = xmm2[0,2,2,3]
    pshufd	$245, %xmm1, %xmm1      # xmm1 = xmm1[1,1,3,3]
    pmuludq	%xmm3, %xmm1
    pshufd	$232, %xmm1, %xmm1      # xmm1 = xmm1[0,2,2,3]
    punpckldq	%xmm1, %xmm2    # xmm2 = xmm2[0],xmm1[0],xmm2[1],xmm1[1]
    movdqa	%xmm2, 4128(%rsp,%rcx)
    addq	$16, %rcx
    ```
    - 如果把B[j]换位常量，与对应AVX2使能的版本类似行为
      ```as
      movdqa	8224(%rsp,%rax), %xmm0
      pslld	$3, %xmm0
      movdqa	%xmm0, 4128(%rsp,%rax)
      ```
  - `__OP__` -> `*`
    ```as
    movdqa	12320(%rsp,%rcx), %xmm0
    movdqa	8224(%rsp,%rcx), %xmm1
    pshufd	$245, %xmm1, %xmm2      # xmm2 = xmm1[1,1,3,3]
    pmuludq	%xmm0, %xmm1
    pshufd	$232, %xmm1, %xmm1      # xmm1 = xmm1[0,2,2,3]
    pshufd	$245, %xmm0, %xmm0      # xmm0 = xmm0[1,1,3,3]
    pmuludq	%xmm2, %xmm0
    pshufd	$232, %xmm0, %xmm0      # xmm0 = xmm0[0,2,2,3]
    punpckldq	%xmm0, %xmm1    # xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1]
    movdqa	%xmm1, 4128(%rsp,%rcx)
    addq	$16, %rcx
    ```

    - 把B[j]换为常量，并没有AVX2对应的类似行为
      ```as
      movdqa	8224(%rsp,%rax), %xmm1
      pshufd	$245, %xmm1, %xmm2      # xmm2 = xmm1[1,1,3,3]
      pmuludq	%xmm0, %xmm1
      pshufd	$232, %xmm1, %xmm1      # xmm1 = xmm1[0,2,2,3]
      pmuludq	%xmm0, %xmm2
      pshufd	$232, %xmm2, %xmm2      # xmm2 = xmm2[0,2,2,3]
      punpckldq	%xmm2, %xmm1    # xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
      movdqa	%xmm1, 4128(%rsp,%rax)
      ```
### 3.1.4  Packing smaller words into vectors 

在未来的项目中将使用的一大类优化是优化应用程序的**数据类型宽度**。假设数组`A`、`B`和`C`的数据类型是`uint32_t`（由`__TYPE__`宏给出）。更改每个数组的数据类型有两个方面的影响：
1. 内存需求。每个元素的数据类型越小，每个数组的内存占用就越小。
2. 向量打包。较小的数据类型允许将更多的元素打包到单个向量寄存器中。
  
让我们来试验一下向量打包的思想：

#### Write-up 9:

当您将`__TYPE__`更改为`uint64_t`、`uint32_t`、`uint16_t`和`uint8_t`时，向量化代码与未向量化代码的加速比；AVX2向量化代码与未向量化代码的加速比是多少？对于每个实验，将`__OP__`设置为`+`且不更改`N`。

编译指令
```bash
$ make ASSEMBLE=1 VECTORIZE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='$type'"
```
- 非向量化代码执行时间
  ```bash
  $ make VECTORIZE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -D__OP__='+' -D__TYPE__='uint64_t' -c loop.c
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.060191 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint64_t
  $ make VECTORIZE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.057364 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
  $ make VECTORIZE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint16_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -D__OP__='+' -D__TYPE__='uint16_t' -c loop.c
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.057048 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint16_t
  $ make VECTORIZE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint8_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -D__OP__='+' -D__TYPE__='uint8_t' -c loop.c
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.042535 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint8_t
  ```
- 默认向量化代码执行时间
  ```bash
  $ make VECTORIZE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -D__OP__='+' -D__TYPE__='uint64_t' -c loop.c
  loop.c:61:5: remark: vectorized loop (vectorization width: 2, interleaved count: 1) [-Rpass=loop-vectorize]
      for (j = 0; j < N; j++) {
      ^
  loop.c:70:9: remark: vectorized loop (vectorization width: 2, interleaved count: 1) [-Rpass=loop-vectorize]
          for (j = 0; j < N; j++) {
          ^
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.029708 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint64_t
  $ make VECTORIZE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c
  loop.c:61:5: remark: vectorized loop (vectorization width: 4, interleaved count: 1) [-Rpass=loop-vectorize]
      for (j = 0; j < N; j++) {
      ^
  loop.c:70:9: remark: vectorized loop (vectorization width: 4, interleaved count: 1) [-Rpass=loop-vectorize]
          for (j = 0; j < N; j++) {
          ^
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.014512 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
  $ make VECTORIZE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint16_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -D__OP__='+' -D__TYPE__='uint16_t' -c loop.c
  loop.c:61:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1) [-Rpass=loop-vectorize]
      for (j = 0; j < N; j++) {
      ^
  loop.c:70:9: remark: vectorized loop (vectorization width: 8, interleaved count: 1) [-Rpass=loop-vectorize]
          for (j = 0; j < N; j++) {
          ^
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.007220 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint16_t
  $ make VECTORIZE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint8_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -D__OP__='+' -D__TYPE__='uint8_t' -c loop.c
  loop.c:70:9: remark: vectorized loop (vectorization width: 16, interleaved count: 1) [-Rpass=loop-vectorize]
          for (j = 0; j < N; j++) {
          ^
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.003657 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint8_t
  ```
- AVX2向量化代码执行时间
  ```bash
  $ make VECTORIZE=1 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='+' -D__TYPE__='uint64_t' -c loop.c
  loop.c:61:5: remark: vectorized loop (vectorization width: 4, interleaved count: 1) [-Rpass=loop-vectorize]
      for (j = 0; j < N; j++) {
      ^
  loop.c:70:9: remark: vectorized loop (vectorization width: 4, interleaved count: 1) [-Rpass=loop-vectorize]
          for (j = 0; j < N; j++) {
          ^
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.014537 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint64_t
  $ make VECTORIZE=1 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c
  loop.c:61:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1) [-Rpass=loop-vectorize]
      for (j = 0; j < N; j++) {
      ^
  loop.c:70:9: remark: vectorized loop (vectorization width: 8, interleaved count: 1) [-Rpass=loop-vectorize]
          for (j = 0; j < N; j++) {
          ^
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.007501 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
  $ make VECTORIZE=1 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint16_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='+' -D__TYPE__='uint16_t' -c loop.c
  loop.c:61:5: remark: vectorized loop (vectorization width: 16, interleaved count: 1) [-Rpass=loop-vectorize]
      for (j = 0; j < N; j++) {
      ^
  loop.c:70:9: remark: vectorized loop (vectorization width: 16, interleaved count: 1) [-Rpass=loop-vectorize]
          for (j = 0; j < N; j++) {
          ^
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.003380 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint16_t
  $ make VECTORIZE=1 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint8_t'"; ./loop
  clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='+' -D__TYPE__='uint8_t' -c loop.c
  loop.c:70:9: remark: vectorized loop (vectorization width: 32, interleaved count: 1) [-Rpass=loop-vectorize]
          for (j = 0; j < N; j++) {
          ^
  clang -o loop loop.o -lrt
  # Elapsed execution time: 0.001792 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint8_t
  ```
- 综合对比
  
  |      | uint64_t | uint32_t | uint16_t | uint8_t |
  |:---:|:---:|:---:|:---:|:---:|
  |Non-Vectorization | 0.060191 | 0.057364 | 0.057048 | 0.042535 |
  | Non-V-Width/Speedup | 1 | 1 | 1 | 1|
  |Default(SSE)-Vectorization| 0.029708 | 0.014512 | 0.007220 |  0.003657 |
  |SSE_V-Width/Speedup | 2 | 4 | 8 | 16 | 
  |AVX2-Vectorization | 0.014537 | 0.007501 | 0.003380 | 0.001792 |
  |AVX2-V-Width/Speedup | 4 | 8 | 16 | 32 |

> 从上表可以分析出，当执行SIMD指令时，寄存器中同时load的操作数越多，计算越快。

一般来说，**加速应该随着数据类型大小的减小而增加**。这是相对于未向量化的代码的一个基本优势，对于固定的`N`，在`N`个元素数组上执行元素操作所需的指令数量**通常**与数据类型宽度无关。

> 我们之所以说“通常”是因为根据处理器的体系结构，具有大数据类型（例如64位和128位）的数组以不同的方式进行处理。例如，可以使用`gcc`和`__int128`类型使用128位数据类型。但是由于awsrun机器中的`ALU`只有64位宽，**编译器会将每个128位操作转换成几个64位操作**。

### 3.1.5  To vectorize or not to vectorize 

向量化的性能潜力也会受到希望执行的操作的影响。在向量化的操作（第3.1.3节）中，乘法（*）每次操作占用的时钟周期最多。

#### Write-up 10:

您已经确定`uint64_t`对向量化代码的性能改善最小（第3.1.4节）。

- 使用`uint64_t`数组测试向量乘法（即，`__OP__`是`*`）。AVX2向量代码相对于非向量代码的加速（也使用了`uint64_t`和`*`）会发生什么情况？
> 加速并不像`+`一样，随着数据宽度下降成倍的增长；AVX2 uint64_t的`*`只能达到2倍的加速而不是`+`的4倍
- 如果将数据类型宽度设置为较小的值（例如`uint8_t`），会怎么样？
> 当使用AVX2 uint8_t时`*`只能达到4倍的加速，SSE也是4倍加速
**SSE: Unvectorize VS Vectorize uint64_t**

```bash
$ make VECTORIZE=0 AVX2=0 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'"; ./loop
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -D__OP__='*' -D__TYPE__='uint64_t' -c loop.c
clang -o loop loop.o -lrt
# Elapsed execution time: 0.057632 sec; N: 1024, I: 100000, __OP__: *, __TYPE__: uint64_t
$ make VECTORIZE=1 AVX2=0 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'"; ./loop
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -D__OP__='*' -D__TYPE__='uint64_t' -c loop.c
loop.c:61:5: remark: vectorized loop (vectorization width: 2, interleaved count: 1) [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:70:9: remark: the cost-model indicates that vectorization is not beneficial [-Rpass-missed=loop-vectorize]
        for (j = 0; j < N; j++) {
        ^
loop.c:70:9: remark: the cost-model indicates that interleaving is not beneficial and is explicitly disabled or interleave count is set to 1
      [-Rpass-missed=loop-vectorize]
clang -o loop loop.o -lrt
# Elapsed execution time: 0.056620 sec; N: 1024, I: 100000, __OP__: *, __TYPE__: uint64_t
```
**SSE: Unvectorize VS Vectorize uint8_t**
```bash
$ make VECTORIZE=0 AVX2=0 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint8_t'"; ./loop
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -D__OP__='*' -D__TYPE__='uint8_t' -c loop.c
clang -o loop loop.o -lrt
# Elapsed execution time: 0.042256 sec; N: 1024, I: 100000, __OP__: *, __TYPE__: uint8_t
$ make VECTORIZE=1 AVX2=0 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint8_t'"; ./loop
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -D__OP__='*' -D__TYPE__='uint8_t' -c loop.c
loop.c:70:9: remark: vectorized loop (vectorization width: 8, interleaved count: 1) [-Rpass=loop-vectorize]
        for (j = 0; j < N; j++) {
        ^
clang -o loop loop.o -lrt
# Elapsed execution time: 0.010906 sec; N: 1024, I: 100000, __OP__: *, __TYPE__: uint8_t
```
**AVX2: Unvectorize VS Vectorize uint64_t**
```bash
$ make VECTORIZE=0 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'"; ./loop
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -mavx2 -D__OP__='*' -D__TYPE__='uint64_t' -c loop.c
clang -o loop loop.o -lrt
# Elapsed execution time: 0.056882 sec; N: 1024, I: 100000, __OP__: *, __TYPE__: uint64_t
$ make VECTORIZE=1 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'"; ./loop
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='*' -D__TYPE__='uint64_t' -c loop.c
loop.c:61:5: remark: vectorized loop (vectorization width: 4, interleaved count: 1) [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:70:9: remark: vectorized loop (vectorization width: 4, interleaved count: 1) [-Rpass=loop-vectorize]
        for (j = 0; j < N; j++) {
        ^
clang -o loop loop.o -lrt
# Elapsed execution time: 0.026245 sec; N: 1024, I: 100000, __OP__: *, __TYPE__: uint64_t
```

**AVX2: Unvectorize VS Vectorize uint8_t**

```bash
$ make VECTORIZE=0 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint8_t'"; ./loop
make: Nothing to be done for 'all'.
# Elapsed execution time: 0.042760 sec; N: 1024, I: 100000, __OP__: *, __TYPE__: uint8_t
$ make VECTORIZE=1 AVX2=1 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint8_t'"; ./loop
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='*' -D__TYPE__='uint8_t' -c loop.c  
loop.c:70:9: remark: vectorized loop (vectorization width: 32, interleaved count: 1) [-Rpass=loop-vectorize]
        for (j = 0; j < N; j++) {
        ^
clang -o loop loop.o -lrt
# Elapsed execution time: 0.013057 sec; N: 1024, I: 100000, __OP__: *, __TYPE__: uint8_t
```
**综合对比**

|  MUL   | uint64_t | uint8_t |
|:---:|:---:|:---:|
|Non-Vectorization | 0.057632 | 0.042256 |
| Non-V-Width/Speedup | 1 | 1 |
|Default(SSE)-Vectorization| 0.056620 | 0.010906 |
|SSE_V-Width/Speedup | 2 / 1 | 8 / 4 |
|AVX2-Vectorization | 0.026245 | 0.013057 |
|AVX2-V-Width/Speedup | 4 / 2 | 32 / 4 |

#### Write-up 11: 

对使用`uint64_t`的AVX2向量化乘法代码打开`aws-perf-report`工具（如您在Recitation 2中所做的）。请记住首先使用`awsrun perf record`工具收集性能报告

![](../Images/w3-12.png)

```bash
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=0 EXTRA_CFLAGS+=-D"__OP__='*'" EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'";
```
- 向量乘用的时间最多吗？
  > time: vpaddq > vpmulu

  ![](../Images/w3-13.png)

- 如果不是的话，时间会去哪里呢？

  > 从上图可以看到 50% 以上的时间被用在了vmovdq/vpaddq/add三种指令上

- 现在将`__OP__`改回`+`，重新运行实验并再次检查`aws-perf-report`。AVX2向量加法指令所花费的时间百分比与AVX2向量乘法指令所花费的时间百分比如何比较？

  ![](../Images/w3-14.png)

  ```bash
  $ make VECTORIZE=1 AVX2=1 ASSEMBLE=0 EXTRA_CFLAGS+=-D"__OP__='+'" \
   EXTRA_CFLAGS+=-D"__TYPE__='uint64_t'";
  ```

当你把`*`改为`+`时，你会看到时间会发生巨大的变化。这部分是由于数据类型宽度（`uint64_t`）和`*`操作本身造成的。特别地，awsrun机器向量单元只支持`32×32`位乘法，**更宽的数据类型是由更小的操作合成的**。如果您尝试使用较小的（uint16_t及以下）数据类型，应该会看到*和+的程序集代码看起来更相似

![](../Images/w3-15.png)

## 3.2  Vector Patterns 
我们现在将探讨一些常见的向量代码模式。我们还推荐 https://llvm.org/docs/Vectorizers.html 作为优化项目时的参考指南。

### 3.2.1  Loops with Runtime Bounds 

到目前为止，我们的数据并行循环对于编译器来说非常简单，因为`N`是预先知道的，并且是2的幂。当循环边界不能提前知道，怎么办呢？

#### Write-up 12: 

去掉`#define N 1024`宏，重新定义`N`为：`int N=atoi(argv[1])`（在`main()`的开头）。（通过命令行设置`N`可确保编译器不会对其进行任何假设。）重新运行（使用`N`的各种选择）并比较`AVX2`向量化、non-AVX2向量化和非向量化代码。加速比相对于`N=1024`的情况有显著的变化吗？为什么？

> 加速比没有显著变化；因为最后还是生成了向量代码，而其他做终止处理处理的代码并没有起太多作用

提示：如果您在应用此更改时查看`loop.s`，您将看到编译器添加终止情况代码来处理最终循环迭代（即，与向量寄存器宽度不一致的迭代）。亲自测试：当您将`__TYPE__`设置为**较小的数据类型时**，您应该看到编译器发出的**与终止相关的程序集代码量会增加**。

| +/1024 |uint64_t| uint32_t | uint16_t | uint8_t |
|:---:|:---:|:---:|:---:|:---:|
|Non-Vec| 0.044662 | 0.045466 | 0.047897 | 0.060357 |
|Default-Vec| 0.032639 | 0.011601 | 0.006575 | 0.002864 |
|AVX2-Vec| 0.015655 | 0.008516 | 0.003858 | 0.001856 |

| +/1777 |uint64_t| uint32_t | uint16_t | uint8_t |
|:---:|:---:|:---:|:---:|:---:|
|Non-Vec| 0.088873 | 0.078087 | 0.078314 | 0.113379 |
|Default-Vec| 0.067034 | 0.022698 | 0.011031 | 0.005668 |
|AVX2-Vec| 0.055892 | 0.015004 | 0.007652 | 0.003953 | 

### 3.2.2  Striding 

循环中的另一个简化特性是它的步幅（或步长）等于1。步幅对应于我们在数组中的步幅有多大；例如，`j++`、`j+=2`等。awsrun机器向量单元有一些硬件支持来加速不同的步幅。

例如，
```c
for (j = 0; j < N; j += 2)  { 
  C[j] = A[j] + B[j]; 
}
```
#### Write-up 13:

将`__TYPE__`设置为`uint32_t`，将`__OP__`设置为`+`，并将内部循环更改为“跨步”。`clang`是否将代码向量化？
> 没有向量化
```bash
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c
loop.c:62:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:71:9: remark: the cost-model indicates that vectorization is not beneficial 
# 这里编译器提示没有生成vectorize代码
      [-Rpass-missed=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
# 这里给出了原因: cost-model表明交错并行是不有益的，并被显式禁用，或这可以将交错计数设置为1
loop.c:71:9: remark: the cost-model indicates that interleaving is not beneficial  
      and is explicitly disabled or interleave count is set to 1
      [-Rpass-missed=loop-vectorize]
clang -o loop loop.o -lrt
# 执行时间，对应non-strip向量执行时间0.007501
Elapsed execution time: 0.031005 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
```
> 生成的代码如下
```as
.LBB0_3:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_4 Depth 2
        xorl    %ecx, %ecx
        .p2align        4, 0x90
.LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                        # =>  This Inner Loop Header: Depth=2      
        movl    4128(%rsp,%rcx,4), %edx
        addl    8224(%rsp,%rcx,4), %edx
        movl    %edx, 32(%rsp,%rcx,4)
        addq    $2, %rcx
        cmpq    $1024, %rcx             # imm = 0x400
        jb      .LBB0_4
# %bb.5:                                #   in Loop: Header=BB0_3 Depth=1
        addl    $1, %eax
        cmpl    $100000, %eax           # imm = 0x186A0
        jne     .LBB0_3
```
为什么它会选择不对代码进行向量化？
> 从编译器来说，它认为向量化不值得。那么如果强制向量化呢？

`clang`提供一个`#pragma clang loop`指令，可用于控制循环的优化，包括向量化。以下网页介绍了这些情况：

http://clang.llvm.org/docs/LanguageExtensions.html#extensions-for-loop-hint-optimizations

#### Write-up 14: 

使用上面clang语言扩展网页中描述的`#vectorize` pragma使clang向量化跨步循环。对于非AVX2和AVX2向量化，非向量化代码的加速比是多少？
> 修改代码

```c
    for (i = 0; i < I; i++) {
        #pragma clang loop vectorize(enable)
        for (j = 0; j < N; j+=2) {
            C[j] = A[j] __OP__ B[j];
        }
    }
```
> 当使用AVX2编译时，编译器提示已经向量化
```bash
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c
loop.c:62:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:72:9: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
clang -o loop loop.o -lrt
# 执行时间相对最初增加了一倍，但是还是与非跨步向量化代码差一倍时间
Elapsed execution time: 0.014584 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
```
> 编译为non-AVX2
```bash
$ make VECTORIZE=1 AVX2=0 ASSEMBLE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c    
loop.c:62:5: remark: vectorized loop (vectorization width: 4, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:72:9: remark: vectorized loop (vectorization width: 4, interleaved count: 1)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
clang -o loop loop.o -lrt
# 执行时间与上面AVX2版本相同
Elapsed execution time: 0.014834 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
```
如果将`vectorize_width`更改为`2`，会发生什么情况？
> 修改代码
```c
    for (i = 0; i < I; i++) {
        #pragma clang loop vectorize(enable)
        #pragma clang loop vectorize_width(2)
        for (j = 0; j < N; j+=2) {
            C[j] = A[j] __OP__ B[j];
        }
    }
```
> 编译AVX2版本
```bash
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c
loop.c:62:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:73:9: remark: vectorized loop (vectorization width: 2, interleaved count: 1)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
clang -o loop loop.o -lrt
# 执行时间，没太多变化
Elapsed execution time: 0.015546 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
```
> 编译non-AVX2版本
```bash
$ make VECTORIZE=1 AVX2=0 ASSEMBLE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c    
loop.c:62:5: remark: vectorized loop (vectorization width: 4, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:73:9: remark: vectorized loop (vectorization width: 2, interleaved count: 1)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
clang -o loop loop.o -lrt
# 执行时间，没太多变化
Elapsed execution time: 0.015454 sec; N: 1024, I: 100000, __OP__: +, __TYPE__: uint32_t
```

使用`clang loop pragmas并报告您找到的最好的（对循环进行向量化）配置。你在非向量代码上得到了加速吗？
> 当编译为非向量化代码时，速度提升了，说明该伪指令，为编译器做出提示，即使没有向量化的参数也会向量化
```bash
$ make VECTORIZE=0 AVX2=1 ASSEMBLE=0 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c
clang -o loop loop.o -lrt
```
> 对比代码发现，两者生成了相同的循环计算代码

```bash
$ make VECTORIZE=0 AVX2=1 ASSEMBLE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -fno-vectorize -S -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c loop.c
$ mv loop.s loop-w14-non-v.s
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -S -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c 
loop.c
loop.c:62:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:73:9: remark: vectorized loop (vectorization width: 2, interleaved count: 1)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
$ mv loop.s loop-w14-v-avx2.s
```
![](../Images/w3-16.png)

> 试验最好的搭配，不管如何搭配，只要成功向量化了，最后执行时间总是大约`0.014347`，并不能达到non-stride向量化的速度（大约是现在的一倍）

再次，检查程序集代码以查看striding是如何向量化的，这是很有见地的。

> 以下这三种配置，最后执行时间都差不多`0.014347`

> Config1: 向量化代码
```c
    for (i = 0; i < I; i++) {
        #pragma clang loop vectorize(enable)
        // #pragma clang loop vectorize_width(2)
        #pragma clang loop interleave(enable)
        // #pragma clang loop interleave_count(1)
        for (j = 0; j < N; j+=2) {
            C[j] = A[j] __OP__ B[j];
        }
    }
```
```bash
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -S -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c 
loop.c
loop.c:62:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:75:9: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
```
```as
.LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu	8160(%rsp,%rcx,8), %ymm0
	vpaddd	12256(%rsp,%rcx,8), %ymm0, %ymm0
	vmovd	%xmm0, 4064(%rsp,%rcx,8)
	vpextrd	$2, %xmm0, 4072(%rsp,%rcx,8)
	vextracti128	$1, %ymm0, %xmm0
	vmovd	%xmm0, 4080(%rsp,%rcx,8)
	vpextrd	$2, %xmm0, 4088(%rsp,%rcx,8)
	vmovdqu	8192(%rsp,%rcx,8), %ymm0
	vpaddd	12288(%rsp,%rcx,8), %ymm0, %ymm0
	vmovd	%xmm0, 4096(%rsp,%rcx,8)
	vpextrd	$2, %xmm0, 4104(%rsp,%rcx,8)
	vextracti128	$1, %ymm0, %xmm0
	vmovd	%xmm0, 4112(%rsp,%rcx,8)
	vpextrd	$2, %xmm0, 4120(%rsp,%rcx,8)
	addq	$8, %rcx
	jne	.LBB0_4
```
> Config 2
```c
    for (i = 0; i < I; i++) {
        #pragma clang loop vectorize(enable)
        #pragma clang loop vectorize_width(2)
        #pragma clang loop interleave(enable)
        // #pragma clang loop interleave_count(1)
        for (j = 0; j < N; j+=2) {
            C[j] = A[j] __OP__ B[j];
        }
    }
```

```bash
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -S -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c 
loop.c
loop.c:62:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:75:9: remark: vectorized loop (vectorization width: 2, interleaved count: 1)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
```

```as
.LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqa	8208(%rsp,%rcx,8), %xmm0
	vpaddd	12304(%rsp,%rcx,8), %xmm0, %xmm0
	vmovd	%xmm0, 4112(%rsp,%rcx,8)
	vpextrd	$2, %xmm0, 4120(%rsp,%rcx,8)
	addq	$2, %rcx
	jne	.LBB0_4
```
> Config 3
```c
    for (i = 0; i < I; i++) {
        #pragma clang loop vectorize(enable)
        #pragma clang loop vectorize_width(2)
        #pragma clang loop interleave(enable)
        #pragma clang loop interleave_count(2)
        for (j = 0; j < N; j+=2) {
            C[j] = A[j] __OP__ B[j];
        }
    }
```

```bash
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -S -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c 
loop.c
loop.c:62:5: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
    for (j = 0; j < N; j++) {
    ^
loop.c:75:9: remark: vectorized loop (vectorization width: 2, interleaved count: 2)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j+=2) {
        ^
```
```as
.LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqa	8192(%rsp,%rcx,8), %xmm0
	vpaddd	12288(%rsp,%rcx,8), %xmm0, %xmm0
	vmovd	%xmm0, 4096(%rsp,%rcx,8)
	vmovdqa	8208(%rsp,%rcx,8), %xmm1
	vpextrd	$2, %xmm0, 4104(%rsp,%rcx,8)
	vpaddd	12304(%rsp,%rcx,8), %xmm1, %xmm0
	vmovd	%xmm0, 4112(%rsp,%rcx,8)
	vpextrd	$2, %xmm0, 4120(%rsp,%rcx,8)
	addq	$4, %rcx
	jne	.LBB0_4
```
#### Clang: Extensions for loop hint optimizations
- http://clang.llvm.org/docs/LanguageExtensions.html#%20extensions-for-loop-hint-optimizations
  
`#pragma clang loop`指令用于指定用于优化后续`for`、`while`、`do while`或基于c++11范围的`for`循环的提示。该指令提供了vectorization, interleaving, predication, unrolling and distribution的选项。循环提示可以在任何循环之前指定，如果应用优化不安全，则忽略该提示。

有控制转换的循环提示（例如向量化、循环展开）和设置转换选项的循环提示（例如`vectorize_width`、`unroll_count`）。Pragmas setting transformation选项表示转换已启用，就好像它是通过相应的转换pragma启用的（例如`vectorize(enable)`）。如果转换被禁用（例如`vectorize(disable)`），则优先于表示该转换的转换选项pragmas。

##### Vectorization, Interleaving

向量化循环使用向量指令**并行执行原始循环的多次迭代**。目标处理器的指令集确定可用的向量指令及其向量宽度。这限制了可以向量化的循环类型。向量器会自动确定循环是否安全，是否有利于向量化。向量指令**代价模型**用于选择向量宽度。

交错多循环迭代允许现代处理器使用高级硬件功能（如多个执行单元和无序执行）进一步提高指令级并行性（ILP）。向量器使用一个成本模型，该模型依赖于寄存器压力和生成的代码大小来选择交织计数。

向量化通过`vectorize(enable)`启用，交织通过`interleave(enable)`启用。这在使用`-Os`编译以手动启用向量化或交错时非常有用。
```c
#pragma clang loop vectorize(enable)
#pragma clang loop interleave(enable)
for(...) {
  ...
}
```
向量宽度由`vectorize_width(_value_)`指定，交织计数由`interleave_count(_value_)`指定，其中`_value_u`是正整数。这对于指定应用程序支持的目标体系结构集的最佳宽度/计数非常有用。
```c
#pragma clang loop vectorize_width(2)
#pragma clang loop interleave_count(2)
for(...) {
  ...
}
```
指定宽度/计数为1将禁用优化，并等效于向量化`vectorize(disable)` 或 `interleave(disable)`。

### 3.2.3  Strip Mining 

一个非常常见的操作是将数组中的元素（以某种方式）组合成一个值。例如，人们可能希望求和数组中的元素。将数据并行内环替换为这样的reduction：

```c
427  for (j = 0; j < N; j++)  { 
428   total += A[j]; 
429  } 
```
为了确保clang对内部循环而不是外部循环进行向量化，请注释掉外部循环。

#### Write-up 15:

这段代码向量化，但它如何向量化？打开ASSEMBLE=1，查看程序集转储，并解释编译器正在做什么。

正如在讲座中所讨论的，只有当组合操作（＋）是关联的时，这种归约才会向量化。

![](../Images/w3-17.png)

> 编译代码
```bash
$ make VECTORIZE=1 AVX2=1 ASSEMBLE=1 EXTRA_CFLAGS+=-D"__OP__='+'" EXTRA_CFLAGS+=-D"__TYPE__='uint32_t'";
clang -Wall -std=gnu99 -fno-unroll-loops -O3 -DNDEBUG -Rpass=loop-vectorize -Rpass-missed=loop-vectorize -ffast-math  -S -mavx2 -D__OP__='+' -D__TYPE__='uint32_t' -c 
loop.c
loop.c:78:9: remark: vectorized loop (vectorization width: 8, interleaved count: 1)      [-Rpass=loop-vectorize]
        for (j = 0; j < N; j++) {
        ^
```
> reduction代码实现方式
```as
.LBB0_1:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
	vmovd	%ebx, %xmm0
	movq	$-4096, %rcx            # imm = 0xF000
	.p2align	4, 0x90
.LBB0_2:                                #   Parent Loop BB0_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpaddd	8224(%rsp,%rcx), %ymm0, %ymm0 # total+=A[j]
	addq	$32, %rcx
	jne	.LBB0_2
# %bb.3:                                #   in Loop: Header=BB0_1 Depth=1
	# 如果对齐到8的话，上面最后生成最后8个total值，相当于分块算了8个total，
	# 最后需要把它们合并起来，即求8个total的和，才是最后结果
  
	# Extract 128 bits of integer data from ymm2 and store results in xmm1/m128.
	# https://software.intel.com/sites/landingpage/IntrinsicsGuide/#text=vextracti128&expand=97,2457
	# 即从ymm0[255:128] -> xmm1[127:0]
	vextracti128	$1, %ymm0, %xmm1  
	vpaddd	%ymm1, %ymm0, %ymm0
	# Shuffle Packed Doublewords
	vpshufd	$78, %xmm0, %xmm1       # xmm1 = xmm0[2,3,0,1]
	vpaddd	%ymm1, %ymm0, %ymm0
	# Packed Horizontal Add and Saturate
	vphaddd	%ymm0, %ymm0, %ymm0
	vmovd	%xmm0, %ebx
	addl	$1, %eax
	cmpl	$100000, %eax           # imm = 0x186A0
	jne	.LBB0_1
```