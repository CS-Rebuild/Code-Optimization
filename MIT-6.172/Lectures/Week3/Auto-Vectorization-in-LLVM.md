# Auto-Vectorization in LLVM

LLVM有两个向量器：循环向量器（对循环进行操作）和SLP向量器。这些向量器关注不同的优化机会，并使用不同的技术。SLP向量器将代码中的**多个标量合并为向量**，而循环向量器则**将循环中的指令加宽**，以在多个连续迭代中操作。

默认情况下，循环向量器和SLP向量器都已启用。

## The Loop Vectorizer
### Usage

默认情况下，Loop Vectorizer是启用的，但是可以使用命令行标志通过clang禁用它：
```bash
$ clang ... -fno-vectorize  file.c
```
#### Command line flags

循环向量化器使用**成本模型**来确定最佳**向量化因子和展开因子**。但是，向量化器的用户可以强制向量化器使用特定值。  `clang`和`opt`都支持以下标志。

用户可以使用命令行标志`-force-vector-width`来控制向量化SIMD宽度。
```bash
$ clang  -mllvm -force-vector-width=8 ...
$ opt -loop-vectorize -force-vector-width=8 ...
```
用户可以使用命令行标志`-force-vector-interleave`来控制`unroll`因子
```bash
$ clang  -mllvm -force-vector-interleave=2 ...
$ opt -loop-vectorize -force-vector-interleave=2 ...
```

#### Pragma loop hint directives

`#pragma clang loop`指令允许为后续`for`，`while`，`do-while`或c++ 11基于范围的`for`循环指定循环向量化提示。该指令允许启用或禁用向量化和交织。向量宽度以及交织计数也可以手动指定。下面的示例显式启用向量化和交织：

```c
#pragma clang loop vectorize(enable) interleave(enable)
while(...) {
  ...
}
```

以下示例通过指定向量宽度和交织计数**隐式启用**向量化和交织：
```c
#pragma clang loop vectorize_width(2) interleave_count(2)
for(...) {
  ...
}
```
有关详细信息，请参见[Clang语言扩展](https://clang.llvm.org/docs/LanguageExtensions.html#extensions-for-loop-hint-optimizations)。

### Diagnostics

许多循环不能被向量化，包括具有复杂控制流，不可向量化类型和不可向量化调用的循环。循环向量化器生成优化说明，可以使用命令行选项查询优化说明，以识别和诊断被循环向量化器跳过的循环。

使用以下命令启用优化说明：
- `-Rpass = loop-vectorize`标识已成功向量化的循环。
- `-Rpass-missed = loop-vectorize`标识失败向量化的循环，并指示是否指定了向量化。
- `-Rpass-analysis = loop-vectorize`标识导致向量化失败的语句。如果另外提供了`-fsave-optimization-record`，则可能列出向量化失败的多种原因（此行为将来可能会更改）。

考虑以下循环：
```c
#pragma clang loop vectorize(enable)
for (int i = 0; i < Length; i++) {
  switch(A[i]) {
  case 0: A[i] = i*2; break;
  case 1: A[i] = i;   break;
  default: A[i] = 0;
  }
}
```
命令行`-Rpass-missed=loop-vectorize`打印注释：
```
no_switch.cpp:4:5: remark: loop not vectorized: vectorization is explicitly enabled [-Rpass-missed=loop-vectorize]
```
并且命令行`-Rpass-analysis=loop-vectorize`指示无法对switch语句进行向量化。
```
no_switch.cpp:4:5: remark: loop not vectorized: loop contains a switch statement [-Rpass-analysis=loop-vectorize]
  switch(A[i]) {
  ^
```
为确保生成行号和列号，请包含命令行选项`-gline-tables-only`和`-gcolumn-info`。有关详细信息，请参见[Clang用户手册](https://clang.llvm.org/docs/UsersManual.html#options-to-emit-optimization-reports)。

### Features
LLVM循环向量化器具有许多功能，可对复杂的循环进行向量化处理。
#### Loops with unknown trip count

循环向量器**支持循环计数未知的循环**。在下面的循环中，迭代的开始点和结束点是未知的，并且Loop Vectorizer具有一种机制，可以对不以零开始的循环进行向量化。在此示例中，`n`可能不是向量宽度的倍数，并且向量化程序必须执行最后几次迭代作为标量代码。保留循环的标量副本会增加代码大小。

```c
void bar(float *A, float* B, float K, int start, int end) {
  for (int i = start; i < end; ++i)
    A[i] *= B[i] + K;
}
```
#### Runtime Checks of Pointers

在下面的示例中，如果指针**A和B指向连续的地址**【注：A,B地址相连】，则对代码进行向量化是**非法的**，因为A的某些元素在从数组B读取之前将被写入。

一些程序员使用`restrict`关键字来通知编译器指针是不相交的，但是在我们的示例中，Loop Vectorizer无法知道指针A和B是唯一的。循环向量化器通过放置在**运行时检查数组A和B是否指向不连续的内存位置的代码来处理此循环**。如果数组A和B**重叠**，则执行循环的**标量版本**。

```c
void bar(float *A, float* B, float K, int n) {
  for (int i = 0; i < n; ++i)
    A[i] *= B[i] + K;
}
```
#### Reductions

在此示例中，循环的连续迭代使用`sum`变量。通常，这会阻止向量化，但是向量化器可以检测到`sum`是归约变量。变量`sum`成为**整数的向量**，并且在循环结束时，**将数组的元素相加在一起以创建正确的结果**。我们支持许多不同的归约运算，例如加法，乘法，XOR，AND和OR。

```c
int foo(int *A, int *B, int n) {
  unsigned sum = 0;
  for (int i = 0; i < n; ++i)
    sum += A[i] + 5;
  return sum;
}
```

当使用`-ffast-math`时，我们支持浮点数归约操作。

#### Inductions

在此示例中，归纳(Inductions)变量`i`的值保存到数组中。循环向量化器知道向量化归纳变量。

```c
void bar(float *A, float* B, float K, int n) {
  for (int i = 0; i < n; ++i)
    A[i] = i;
}
```
#### If Conversion

循环向量化器能够`flatten`代码中的`IF`语句并生成单个指令流。循环向量化器**支持最内部循环中的任何控制流**。最内层的循环可能包含`IFs`，`ELSEs`甚至`GOTO`的复杂嵌套。

```c
int foo(int *A, int *B, int n) {
  unsigned sum = 0;
  for (int i = 0; i < n; ++i)
    if (A[i] > B[i])
      sum += A[i] + 5;
  return sum;
}
```
#### Pointer Induction Variables

本示例使用标准C++库的“accumulate”函数。此循环使用C++迭代器，它们是指针，而不是整数索引。循环向量化器检测**指针归纳变量并可以向量化此循环**。此功能很重要，因为许多C++程序都使用迭代器。

```c
int baz(int *A, int n) {
  return std::accumulate(A, A + n, 0);
}
```
#### Reverse Iterators
循环向量化器可以向量化向后计数的循环。

```c
int foo(int *A, int *B, int n) {
  for (int i = n; i > 0; --i)
    A[i] +=1;
}
```
#### Scatter / Gather
循环向量化器可以对代码进行向量化处理，这些代码成为分散/聚集内存的一系列标量指令。
```c
int foo(int * A, int * B, int n) {
  for (intptr_t i = 0; i < n; ++i)
      A[i] += B[i * 4];
}
```

在许多情况下，成本模型将通知LLVM这是无益的，并且LLVM仅在强制使用`-mllvm -force-vector-width=#`时才会向量化此类代码。

#### Vectorization of Mixed Types

循环向量化器可以**对混合类型的程序进行向量化**。Vectorizer成本模型可以估算类型转换的成本，并确定向量化是否有利可图。

```c
int foo(int *A, char *B, int n, int k) {
  for (int i = 0; i < n; ++i)
    A[i] += 4 * B[i];
}
```
#### Global Structures Alias Analysis

对全局结构的访问也可以进行向量化，并使用**别名分析**来确保访问没有别名。也可以在对结构成员的指针访问上添加运行时检查。

支持许多变体，但是有些依赖未定义行为的变体（与其他编译器一样）仍未进行向量化处理。

```c
struct { int A[100], K, B[100]; } Foo;

int foo() {
  for (int i = 0; i < 100; ++i)
    Foo.A[i] = Foo.B[i] + 100;
}
```
#### Vectorization of function calls

Loop Vectorizer可以**向量化内在数学函数**。有关这些功能的列表，请参见下表。

column0 | column1 | column2
------- | ------- | -------
pow | exp | exp2
sin | cos | sqrt
log | log2 | log10
fabs | floor | ceil
fma | trunc | nearbyint
 |   | fmuladd

请注意，如果库调用了诸如`errno`之类的外部状态，则优化器可能无法向量化与这些内在函数相对应的数学库函数。为了更好地优化C/C++数学库函数，请使用`-fno-math-errno`。

循环向量化器了解目标上的特殊指令，并将对包含映射到指令的函数调用的循环进行向量化。例如，如果有SSE4.1 `roundps`指令可用，则以下循环将在Intel x86上进行向量化处理。
```c
void foo(float *f) {
  for (int i = 0; i != 1024; ++i)
    f[i] = floorf(f[i]);
}
```
#### Partial unrolling during vectorization

现代处理器具有**多个执行单元**，只有包含高度并行性的程序才能充分利用机器的整个宽度。循环向量化器通过执行循环的**部分展开来提高指令级并行度（ILP）**。

在下面的示例中，整个数组都累积到变量`sum`中。这是低效率的，因为处理器只能使用一个执行端口。通过展开代码，Loop Vectorizer允许同时使用两个或多个执行端口。

```c
int foo(int *A, int *B, int n) {
  unsigned sum = 0;
  for (int i = 0; i < n; ++i)
      sum += A[i];
  return sum;
}
```

Loop Vectorizer使用成本模型来决定何时展开循环是有利可图的。展开循环的决定取决于寄存器压力和生成的代码大小。

### Performance

本节以简单的基准显示`Clang`的执行时间：[`gcc-loops`](https://github.com/llvm/llvm-test-suite/tree/master/SingleSource/UnitTests/Vectorizer)。该基准是Dorit Nuzman在GCC自动向量化[页面](http://gcc.gnu.org/projects/tree-ssa/vectorization.html)上收集的一系列循环。

下表比较了在Sandybridge iMac上运行的在`-O3`处进行和不进行循环向量化的`GCC-4.7`，`ICC-13`和`Clang-SVN`（针对“ corei7-avx”进行了调整）。Y轴以毫秒为单位显示时间。越低越好。 最后一列显示了所有内核的几何平均值。

![](../Images/gcc-loops.png)

与Linpack-pc具有相同的配置。结果单位是`Mflops`，越高越好。

![](../Images/linpack-pc.png)

### Ongoing Development Directions

[向量化计划](https://llvm.org/docs/Proposals/VectorizationPlan.html)

对LLVM的Loop Vectorizer的过程进行建模并升级基础架构。
## The SLP Vectorizer
### Details
SLP向量化（也称为超字级并行性）的目标是**将类似的独立指令组合成向量指令**。存储器访问，算术运算，比较运算，PHI节点都可以使用此技术向量化。

例如，以下函数对其输入（a1，b1）和（a2，b2）执行非常相似的操作。基本块向量化器可以将它们组合成向量运算。
```c
void foo(int a1, int a2, int b1, int b2, int *A) {
  A[0] = a1*(a1 + b1);
  A[1] = a2*(a2 + b2);
  A[2] = a1*(a1 + b1);
  A[3] = a2*(a2 + b2);
}
```
SLP向量化器在基本块中自下而上地处理代码，以寻找要合并的标量。
### Usage

SLP Vectorizer默认情况下处于启用状态，但可以使用命令行标志通过clang禁用它：

```bash
$ clang -fno-slp-vectorize file.c
```