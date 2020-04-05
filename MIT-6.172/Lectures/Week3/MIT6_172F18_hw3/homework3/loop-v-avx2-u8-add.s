	.text
	.file	"loop.c"
	.section	.rodata.cst8,"aM",@progbits,8
	.p2align	3               # -- Begin function main
.LCPI0_0:
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
	movl	%r14d, %r13d
	leaq	15(%r13), %rax
	movabsq	$8589934576, %rcx       # imm = 0x1FFFFFFF0
	andq	%rax, %rcx
	movq	%rsp, %r12
	subq	%rcx, %r12
	movq	%r12, %rsp
	movq	%rsp, %rbx
	subq	%rcx, %rbx
	movq	%rbx, %rsp
	movq	%rsp, %r15
	subq	%rcx, %r15
	movq	%r15, %rsp
	movl	$0, -44(%rbp)
	testl	%r14d, %r14d
	jle	.LBB0_2
# %bb.1:
	xorl	%esi, %esi
	movq	%r12, %rdi
	movq	%r13, %rdx
	callq	memset
	movl	$3, %esi
	movq	%rbx, %rdi
	movq	%r13, %rdx
	callq	memset
	xorl	%esi, %esi
	movq	%r15, %rdi
	movq	%r13, %rdx
	callq	memset
.LBB0_2:
	leaq	-64(%rbp), %rsi
	movl	$1, %edi
	callq	clock_gettime
	movq	-64(%rbp), %r13
	movq	-56(%rbp), %rax
	movq	%rax, -72(%rbp)         # 8-byte Spill
	testl	%r14d, %r14d
	jle	.LBB0_11
# %bb.3:
	movl	%r14d, %eax
	movl	%r14d, %edx
	andl	$31, %edx
	movq	%rax, %rcx
	subq	%rdx, %rcx
	xorl	%r9d, %r9d
	.p2align	4, 0x90
.LBB0_4:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_7 Depth 2
                                        #     Child Loop BB0_9 Depth 2
	cmpq	$32, %rax
	jae	.LBB0_6
# %bb.5:                                #   in Loop: Header=BB0_4 Depth=1
	xorl	%esi, %esi
	jmp	.LBB0_9
	.p2align	4, 0x90
.LBB0_6:                                #   in Loop: Header=BB0_4 Depth=1
	movl	%r14d, %r8d
	andl	$31, %r8d
	movq	%rax, %rsi
	subq	%r8, %rsi
	xorl	%edi, %edi
	.p2align	4, 0x90
.LBB0_7:                                #   Parent Loop BB0_4 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu	(%rbx,%rdi), %ymm0
	vpaddb	(%r12,%rdi), %ymm0, %ymm0
	vmovdqu	%ymm0, (%r15,%rdi)
	addq	$32, %rdi
	cmpq	%rdi, %rcx
	jne	.LBB0_7
# %bb.8:                                #   in Loop: Header=BB0_4 Depth=1
	testq	%r8, %r8
	je	.LBB0_10
	.p2align	4, 0x90
.LBB0_9:                                #   Parent Loop BB0_4 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	(%rbx,%rsi), %edx
	addb	(%r12,%rsi), %dl
	movb	%dl, (%r15,%rsi)
	addq	$1, %rsi
	cmpq	%rsi, %rax
	jne	.LBB0_9
.LBB0_10:                               #   in Loop: Header=BB0_4 Depth=1
	addl	$1, %r9d
	cmpl	$100000, %r9d           # imm = 0x186A0
	jne	.LBB0_4
.LBB0_11:
	leaq	-64(%rbp), %rsi
	movl	$1, %edi
	vzeroupper
	callq	clock_gettime
	movq	-64(%rbp), %rbx
	movq	-56(%rbp), %r12
	leaq	-44(%rbp), %rdi
	callq	rand_r
	cltd
	idivl	%r14d
	subq	%r13, %rbx
	vcvtsi2sdq	%rbx, %xmm1, %xmm0
	movslq	%edx, %rax
	subq	-72(%rbp), %r12         # 8-byte Folded Reload
	vcvtsi2sdq	%r12, %xmm1, %xmm1
	movzbl	(%r15,%rax), %ebx
	vmulsd	.LCPI0_0(%rip), %xmm1, %xmm1
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
	.asciz	"uint8_t"
	.size	.L.str.2, 8


	.ident	"clang version 6.0.0-1ubuntu2 (tags/RELEASE_600/final)"
	.section	".note.GNU-stack","",@progbits
