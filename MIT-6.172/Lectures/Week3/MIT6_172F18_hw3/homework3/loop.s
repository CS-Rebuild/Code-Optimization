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
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%r12
	.cfi_def_cfa_offset 32
	pushq	%rbx
	.cfi_def_cfa_offset 40
	subq	$8232, %rsp             # imm = 0x2028
	.cfi_def_cfa_offset 8272
	.cfi_offset %rbx, -40
	.cfi_offset %r12, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	movl	$0, 12(%rsp)
	leaq	4128(%rsp), %rdi
	xorl	%ebx, %ebx
	xorl	%esi, %esi
	movl	$4096, %edx             # imm = 0x1000
	callq	memset
	leaq	32(%rsp), %rdi
	xorl	%esi, %esi
	movl	$4096, %edx             # imm = 0x1000
	callq	memset
	leaq	16(%rsp), %rsi
	movl	$1, %edi
	callq	clock_gettime
	movq	16(%rsp), %r15
	movq	24(%rsp), %r14
	xorl	%eax, %eax
	.p2align	4, 0x90
.LBB0_1:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
	vmovd	%ebx, %xmm0
	movq	$-4096, %rcx            # imm = 0xF000
	.p2align	4, 0x90
.LBB0_2:                                #   Parent Loop BB0_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpaddd	8224(%rsp,%rcx), %ymm0, %ymm0
	addq	$32, %rcx
	jne	.LBB0_2
# %bb.3:                                #   in Loop: Header=BB0_1 Depth=1
	vextracti128	$1, %ymm0, %xmm1
	vpaddd	%ymm1, %ymm0, %ymm0
	vpshufd	$78, %xmm0, %xmm1       # xmm1 = xmm0[2,3,0,1]
	vpaddd	%ymm1, %ymm0, %ymm0
	vphaddd	%ymm0, %ymm0, %ymm0
	vmovd	%xmm0, %ebx
	addl	$1, %eax
	cmpl	$100000, %eax           # imm = 0x186A0
	jne	.LBB0_1
# %bb.4:
	leaq	16(%rsp), %rsi
	movl	$1, %edi
	vzeroupper
	callq	clock_gettime
	movq	16(%rsp), %r12
	subq	%r15, %r12
	movq	24(%rsp), %r15
	subq	%r14, %r15
	leaq	12(%rsp), %rdi
	callq	rand_r
	movl	%eax, %ecx
	sarl	$31, %ecx
	shrl	$22, %ecx
	addl	%eax, %ecx
	andl	$-1024, %ecx            # imm = 0xFC00
	subl	%ecx, %eax
	cltq
	addl	32(%rsp,%rax,4), %ebx
	vcvtsi2sdq	%r12, %xmm2, %xmm0
	vcvtsi2sdq	%r15, %xmm2, %xmm1
	vmulsd	.LCPI0_0(%rip), %xmm1, %xmm1
	vaddsd	%xmm0, %xmm1, %xmm0
	movl	$.L.str, %edi
	movl	$1024, %esi             # imm = 0x400
	movl	$100000, %edx           # imm = 0x186A0
	movl	$.L.str.1, %ecx
	movl	$.L.str.2, %r8d
	movb	$1, %al
	callq	printf
	movl	%ebx, %eax
	addq	$8232, %rsp             # imm = 0x2028
	popq	%rbx
	popq	%r12
	popq	%r14
	popq	%r15
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
	.asciz	"uint32_t"
	.size	.L.str.2, 9


	.ident	"clang version 6.0.0-1ubuntu2 (tags/RELEASE_600/final)"
	.section	".note.GNU-stack","",@progbits
