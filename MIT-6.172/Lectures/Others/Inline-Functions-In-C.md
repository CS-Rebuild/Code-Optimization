# Inline Functions In C
- https://www.greenend.org.uk/rjk/tech/inline.html
  
## Introduction

GNU C（和其他一些编译器）早在标准C引入内联函数之前（在1999年标准中）就有了内联函数； 本页总结了它们使用的规则，并对如何实际使用内联函数提出了一些建议。

内联函数的目的是向编译器暗示，有必要付出一些额外的努力来比其他方法更快地调用函数-通常通过将函数的代码替换为其调用程序。**除了消除对调用和返回序列的需求外，它还可以使编译器在两个函数的主体之间执行某些优化**。

有时，即使是内联函数，编译器也有必要为该函数发出目标代码的独立副本-例如，如果有必要获取该**函数的地址**，或者在某些特定上下文中不能内联，或者（也许）在优化已关闭的情况下。  （当然，如果您使用的是无法理解内联的编译器，则将需要目标代码的独立副本，以便所有调用实际上都可以正常工作。） 

定义内联函数的方法有很多种。任何给定类型的定义都可能肯定会发出独立的目标代码，绝对不会发出独立的目标代码，或者仅在已知需要时才发出独立的目标代码。有时，这可能导致目标代码重复，这是一个潜在问题，原因如下：
- 浪费空间。
- 它可能导致指向显然相同函数的指针之间的比较不相等。
- 这可能会降低指令缓存的效率。（尽管内联也可以通过其他方式做到这一点。）

如果您遇到任何上述问题，那么您将希望使用避免重复的策略。 这些将在下面讨论。

## C99 inline rules

内联规范是C99标准（ISO/IEC 9899：1999）第6.7.4节。不幸的是，这不是免费提供的。存在以下可能性：
- 一个函数，其中**所有声明（包括定义）都提到`inline`而不是`extern`**。同一翻译单元中必须有一个定义。该标准将此称为`inline definition`。没有发出独立的目标代码，因此不能从另一个翻译单元调用此定义。
  
  您可以在另一个翻译单元中有一个单独的（非内联）定义，编译器可以选择该定义或内联定义二者之一。
  
  此类函数可能不包含可修改的静态变量，并且可能不会引用静态变量或在声明它们的源文件中其他位置引用的函数。
  
  在此示例中，**所有声明和定义都使用`inline`而不使用`extern`**：

  ```c
  // a declaration mentioning inline
  inline int max(int a, int b);

  // a definition mentioning inline
  inline int max(int a, int b) {
    return a > b ? a : b;
  }
  ```

  **该函数将无法从其他文件中调用；如果另一个文件具有可以代替的定义**。
   
  在这一点上，标准含糊。它说内联定义不禁止在其他地方使用外部定义，但是它提供了外部定义的替代方法。不幸的是，这并不能真正弄清楚这个外部定义是否必须存在。
  
  在实践中，除非您要对编译器进行极限测试，否则编译器将存在：如果您希望将内联函数完全保留给一个翻译单元私用，则**可以使其成为static inline**。

- 一个函数，其中至少一个声明提到`inline`，但是其中一些声明没有提到`inline`或确实提到了`extern`。在同一翻译单元中必须有一个定义。发出独立的目标代码（就像正常函数一样），并且可以从程序中的其他翻译单元调用它。
  
  上面关于静态的相同约束也适用于此。
  
  在此示例中，所有声明和定义都使用`inline`，但其中一个添加了`extern`： 

  ```c
  // a declaration mentioning extern and inline
  extern inline int max(int a, int b);

  // a definition mentioning inline
  inline int max(int a, int b) {
    return a > b ? a : b;
  }
  ```

  在此示例中，其中一个声明未提及`inline`：

  ```c
  // a declaration not mentioning inline
  int max(int a, int b);

  // a definition mentioning inline
  inline int max(int a, int b) {
    return a > b ? a : b;
  }
  ```
  在任一示例中，**该函数都可以从其他文件中调用**。

- 函数定义的`static inline`。如果需要，可以发出局部定义。您**可以在程序中以不同的翻译单位使用多个定义**，并且仍然可以使用。**只需内联即可将程序缩减为可移植程序**（同样，所有其他条件都相同）。
  
  这可能主要对您可能会使用宏的小函数很有用。 如果该函数并不总是内联的，则您将获得目标代码的重复副本，并且存在上述问题。
  
  一个明智的方法是将`static line`函数放在头文件中，如果要**广泛使用的话**；或者仅将静态内联函数放在使用它们的源文件中（如果仅从一个文件使用过）。
  
  在此示例中，该函数是`static inline`定义的：

  ```c
  // a definition using static inline
  static inline int max(int a, int b) {
    return a > b ? a : b;
  }
  ```

前两种可能性自然并存。您可以在各处编写内联代码，然后在一个地方进行外部调用以请求独立的定义，或者在几乎所有地方编写内联代码，但只进行一次省略即可获得独立定义。

main不允许是内联函数。

（如果您认为我误解了这些规则，请告诉我！）（C++更为严格：在任何地方都可以内联的函数必须在任何地方都可以内联，并且在使用它的所有翻译单元中必须定义相同。）

## GNU C inline rules

GNU C规则在GNU C手册中进行了描述，该手册随编译器一起提供。如果您点击了例如来自 http://gcc.gnu.org。 存在以下可能性：
- 单独使用内联定义的函数。始终发出独立的目标代码。您只能在整个程序中编写一个这样的定义。 如果要将它从其他翻译单元使用到定义它的单元，请**在头文件中放置一个声明**；但不会在那些翻译单元中内联。
  
  这种用法用途有限：如果您**只想在一个翻译单元中使用该函数**，则下面的`static inline`更为合理；如果不是，则可能需要某种形式，以允许将函数嵌入多个翻译单元中。
  
  但是，这样做的好处是，通过定义`inline`关键字，程序**可以简化为具有相同含义的可移植程序**（前提是不使用其他不可移植的结构）。

- 用`extern inline`定义的函数。永远不会发出独立的目标代码。您可以有多个这样的定义，并且程序仍然可以运行。但是，您也应该在某处添加非内联定义，以防该函数未在任何地方内联。
  
  这提供了合理的语义（可以避免函数目标代码的重复副本），但是使用起来有些不便。
  
  一种使用此方法的方法是将定义放在头文件中，并用`#if`包围，当使用GNU C时，或者在包含发出的定义的文件中包含头（无论是 不使用GNU C）。 在后一种情况下，省略了`extern`（例如，将`EXTERN`和＃`define-ing`为`extern`或什么都不写）。 对于非GNU编译器，`#else`分支将仅包含函数的声明。
  
- 用`static inline`定义的函数。如果需要，可以发出独立的目标代码。您可以在程序中以不同的翻译单位使用多个定义，并且仍然可以使用。 这与C99规则相同。

从4.3版开始，GNU C支持上述C99内联规则，并默认使用`-std=c99`或`-std=gnu99`选项。可以使用`-gnu89-inline`选项或通过`gnu_inline`函数属性在新的编译器中请求旧规则。

如果C99规则有效，则GCC将定义`__GNUC_STDC_INLINE__`宏。从GCC 4.1.3开始，如果仅使用GCC规则，它将定义`__GNUC_GNU_INLINE__`，但是较早的编译器使用这些规则而不定义任何宏。 您可以使用如下片段来规范化情况：

```c
#if defined __GNUC__ && !defined __GNUC_STDC_INLINE__ && !defined __GNUC_GNU_INLINE__
# define __GNUC_GNU_INLINE__ 1
#endif
```

## Strategies for using inline functions

这些规则建议了几种可能的模型，它们以或多或少的可移植方式使用内联函数。
- 一个简单的可移植方式。使用`static inline`（在公共头文件中或仅在一个文件中）。如果编译器需要发出一个定义（例如获取其地址，或者因为它不希望内联某些调用），则会浪费一些空间; 如果以两个转换单位表示函数的地址，则结果将不会相等。

  例如，在头文件中： 

  ```c
  static inline int max(int a, int b) {
    return a > b ? a : b;
  }
  ```

  您可以通过`-Dinline=""`支持旧版编译器（即没有内联的任何东西），尽管如果编译器未优化未使用的函数，这可能会浪费空间。

- 一个GNU C 方式。在公共头文件中使用`extern inline`，并在`.c`文件中的某个位置提供定义，也许使用宏来确保在每种情况下都使用相同的代码。 例如，在头文件中：
  
  ```c
  #ifndef INLINE
  # define INLINE extern inline
  #endif
  INLINE int max(int a, int b) {
    return a > b ? a : b;
  }
  ```
  ...并在一个源文件中：

  ```c
  #define INLINE
  #include "header.h"
  ```

  除非您不介意浪费空间并为同一函数使用多个地址，否则支持旧版编译器很麻烦。您需要将定义限制为单个转换单元（`INLINE`定义为空字符串），并在头文件中添加一些外部声明。

- C99 方式。在公共头文件中使用`inline`，并通过`extern`声明在`.c`文件中的某个位置提供定义。例如，在头文件中：
  ```c
  inline int max(int a, int b) {
    return a > b ? a : b;
  }
  ```
  ...并在一个源文件中：

  ```c
  #include "header.h"
  extern int max(int a, int b);
  ```

  为了支持旧式编译器，您必须交换整个内容，以使声明在公共头文件中可见，并且定义限于单个翻译单元，而内联定义除外。

- 复杂的可移植方式。使用宏为GNU C选择`extern inline`，为C99选择`inline`，或者为定义都不选择。例如，在头文件中：

  ```c
  #ifndef INLINE
  # if __GNUC__ && !__GNUC_STDC_INLINE__
  #  define INLINE extern inline
  # else
  #  define INLINE inline
  # endif
  #endif
  INLINE int max(int a, int b) {
    return a > b ? a : b;
  }
  ```
  ...并在一个源文件中：
  ```c
  #define INLINE
  #include "header.h"
  ```

  支持旧版编译器的问题与GNU C方式相同。