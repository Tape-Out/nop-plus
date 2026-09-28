# 冒烟程序：开缓存后跑加法循环、乘除、字节写读，结果写到非缓存的 0xbffffff0。
# LA32R 没有 beqz/bnez，一律与 $zero 比
# 写 1 为过，写 2 起为第几项不过；测试台盯的就是这个地址。

	.macro	li32 rd, v
	lu12i.w	\rd, ((((\v) >> 12) & 0xfffff) ^ 0x80000) - 0x80000
	ori	\rd, \rd, (\v) & 0xfff
	.endm

	.macro	expect rd, v, code
	li32	$t8, \v
	addi.w	$a7, $zero, \code
	bne	\rd, $t8, fail
	.endm

	.text
	.globl	_start
_start:
	# DMW0 把 0x0-0x1fffffff 映成一致可缓存，DMW1 把 0xa0000000-0xbfffffff 映成强序非缓存
	li32	$t0, 0x00000011
	csrwr	$t0, 0x180
	li32	$t0, 0xaa000001
	csrwr	$t0, 0x181
	# CRMD：PG=1，此后取指与访存都走 DMW，也就走缓存
	li32	$t0, 0x000000b0
	csrwr	$t0, 0x0

	addi.w	$t1, $zero, 100
	or	$t2, $zero, $zero
1:	add.w	$t2, $t2, $t1
	addi.w	$t1, $t1, -1
	bne	$t1, $zero, 1b
	expect	$t2, 5050, 2

	li32	$t0, 0x12345678
	mul.w	$t3, $t0, $t2
	expect	$t3, 0x1c71bb30, 3
	mulh.wu	$t3, $t0, $t2
	expect	$t3, 0x167, 4
	addi.w	$t4, $zero, -3
	addi.w	$t5, $zero, 7
	mul.w	$t3, $t4, $t5
	expect	$t3, 0xffffffeb, 5
	div.w	$t3, $t2, $t5
	expect	$t3, 721, 6
	mod.w	$t3, $t2, $t5
	expect	$t3, 3, 7

	li32	$a0, 0x1c008000
	st.w	$t0, $a0, 0
	addi.w	$t3, $zero, 0xab
	st.b	$t3, $a0, 1
	ld.w	$t3, $a0, 0
	expect	$t3, 0x1234ab78, 8

	# 跨四行写 64 个字再读回求和，读的时候行已在缓存里
	or	$t1, $zero, $zero
	addi.w	$t6, $a0, 64
2:	st.w	$t1, $t6, 0
	addi.w	$t6, $t6, 4
	addi.w	$t1, $t1, 1
	addi.w	$t3, $zero, 64
	bne	$t1, $t3, 2b
	or	$t2, $zero, $zero
	addi.w	$t6, $a0, 64
3:	ld.w	$t3, $t6, 0
	add.w	$t2, $t2, $t3
	addi.w	$t6, $t6, 4
	addi.w	$t1, $t1, -1
	bne	$t1, $zero, 3b
	expect	$t2, 2016, 9

	addi.w	$a7, $zero, 1
fail:
	li32	$a1, 0xbffffff0
	st.w	$a7, $a1, 0
4:	b	4b
