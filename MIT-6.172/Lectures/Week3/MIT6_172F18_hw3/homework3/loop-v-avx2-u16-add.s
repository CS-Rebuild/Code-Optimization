	.text
	.file	"loop.c"
	.section	.rodata.cst32,"aM",@progbits,32
	.p2align	5               # -- Begin function main
.LCPI0_0:
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.short	3                       # 0x3
	.section	.rodata.cst8,"aM",@progbits,8
	.p2align	3
.LCPI0_1:
	.quad	4472406533629990549     # double 1.0000000000000001E-9
	.text
	.globl	main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$40, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	8(%rsi), %rdi
	xorl	%esi, %esi
	movl	$10, %edx
	callq	strtol
	movq	%rax, %r14
	movl	%r14d, %eax
	addq	%rax, %rax
	addq	$15, %rax
	movabsq	$17179869168, %rcx      # imm = 0x3FFFFFFF0
	andq	%rax, %rcx
	movq	%rsp, %r13
	subq	%rcx, %r13
	movq	%r13, %rsp
	movq	%rsp, %rbx
	subq	%rcx, %rbx
	movq	%rbx, %rsp
	movq	%rsp, %r15
	subq	%rcx, %r15
	movq	%r15, %rsp
	movl	$0, -52(%rbp)
	testl	%r14d, %r14d
	jle	.LBB0_8
# %bb.1:
	movl	%r14d, %r12d
	leaq	(%r12,%r12), %rdx
	movq	%rdx, -48(%rbp)         # 8-byte Spill
	xorl	%esi, %esi
	movq	%r13, %rdi
	callq	memset
	xorl	%esi, %esi
	movq	%r15, %rdi
	movq	-48(%rbp), %rdx         # 8-byte Reload
	callq	memset
	cmpq	$16, %r12
	jae	.LBB0_3
# %bb.2:
	xorl	%esi, %esi
	jmp	.LBB0_6
.LBB0_3:
	movl	%r14d, %eax
	andl	$15, %eax
	movq	%r12, %rsi
	subq	%rax, %rsi
	vmovdqa	.LCPI0_0(%rip), %ymm0   # ymm0 = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3]
	movq	%rsi, %rcx
	movq	%rbx, %rdx
	.p2align	4, 0x90
.LBB0_4:                                # =>This Inner Loop Header: Depth=1
	vmovdqu	%ymm0, (%rdx)
	addq	$32, %rdx
	addq	$-16, %rcx
	jne	.LBB0_4
# %bb.5:
	testq	%rax, %rax
	je	.LBB0_8
.LBB0_6:
	leaq	(%rbx,%rsi,2), %rax
	subq	%rsi, %r12
	.p2align	4, 0x90
.LBB0_7:                                # =>This Inner Loop Header: Depth=1
	movw	$3, (%rax)
	addq	$2, %rax
	addq	$-1, %r12
	jne	.LBB0_7
.LBB0_8:
	leaq	-72(%rbp), %rsi
	movl	$1, %edi
	vzeroupper
	callq	clock_gettime
	movq	-72(%rbp), %r12
	movq	-64(%rbp), %rax
	movq	%rax, -48(%rbp)         # 8-byte Spill
	testl	%r14d, %r14d
	jle	.LBB0_17
# %bb.9:
	movl	%r14d, %eax
	movl	%r14d, %edx
	andl	$15, %edx
	movq	%rax, %rcx
	subq	%rdx, %rcx
	xorl	%edx, %edx
	.p2align	4, 0x90
.LBB0_10:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_13 Depth 2
                                        #     Child Loop BB0_15 Depth 2
	cmpq	$16, %rax
	jae	.LBB0_12
# %bb.11:                               #   in Loop: Header=BB0_10 Depth=1
	xorl	%esi, %esi
	jmp	.LBB0_15
	.p2align	4, 0x90
.LBB0_12:                               #   in Loop: Header=BB0_10 Depth=1
	movl	%r14d, %r8d
	andl	$15, %r8d
	movq	%rax, %rsi
	subq	%r8, %rsi
	xorl	%edi, %edi
	.p2align	4, 0x90
.LBB0_13:                               #   Parent Loop BB0_10 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu	(%rbx,%rdi,2), %ymm0
	vpaddw	(%r13,%rdi,2), %ymm0, %ymm0
	vmovdqu	%ymm0, (%r15,%rdi,2)
	addq	$16, %rdi
	cmpq	%rdi, %rcx
	jne	.LBB0_13
# %bb.14:                               #   in Loop: Header=BB0_10 Depth=1
	testq	%r8, %r8
	je	.LBB0_16
	.p2align	4, 0x90
.LBB0_15:                               #   Parent Loop BB0_10 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzwl	(%rbx,%rsi,2), %edi
	addw	(%r13,%rsi,2), %di
	movw	%di, (%r15,%rsi,2)
	addq	$1, %rsi
	cmpq	%rsi, %rax
	jne	.LBB0_15
.LBB0_16:                               #   in Loop: Header=BB0_10 Depth=1
	addl	$1, %edx
	cmpl	$100000, %edx           # imm = 0x186A0
	jne	.LBB0_10
.LBB0_17:
	leaq	-72(%rbp), %rsi
	movl	$1, %edi
	vzeroupper
	callq	clock_gettime
	movq	-72(%rbp), %rbx
	movq	-64(%rbp), %r13
	leaq	-52(%rbp), %rdi
	callq	rand_r
	cltd
	idivl	%r14d
	subq	%r12, %rbx
	vcvtsi2sdq	%rbx, %xmm1, %xmm0
	movslq	%edx, %rax
	subq	-48(%rbp), %r13         # 8-byte Folded Reload
	vcvtsi2sdq	%r13, %xmm1, %xmm1
	movzwl	(%r15,%rax,2), %ebx
	vmulsd	.LCPI0_1(%rip), %xmm1, %xmm1
	vaddsd	%xmm0, %xmm1, %xmm0
	movl	$.L.str, %edi
	movl	$100000, %edx           # imm = 0x186A0
	movl	$.L.str.1, %ecx
	movl	$.L.str.2, %r8d
	movb	$1, %al
	movl	%r14d, %esi
	callq	printf
	movl	%ebx, %eax
	leaq	-40(%rbp), %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.type	.L.str,@object          # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"Elapsed execution time: %f sec; N: %d, I: %d, __OP__: %s, __TYPE__: %s\n"
	.size	.L.str, 72

	.type	.L.str.1,@object        # @.str.1
.L.str.1:
	.asciz	"+"
	.size	.L.str.1, 2

	.type	.L.str.2,@object        # @.str.2
.L.str.2:
	.asciz	"uint16_t"
	.size	.L.str.2, 9


	.ident	"clang version 6.0.0-1ubuntu2 (tags/RELEASE_600/final)"
	.section	".note.GNU-stack","",@progbits
