	.text
	.attribute	4, 16
	.attribute	5, "rv64i2p0_m2p0_a2p0_f2p0_d2p0"
	.option	nopic
	.file	"syscalls.c"
	.globl	printbuf                        # -- Begin function printbuf
	.p2align	2
	.type	printbuf,@function
printbuf:                               # @printbuf
# %bb.0:                                # %entry
	blez	a1, .LBB0_4
# %bb.1:                                # %while.cond.preheader.preheader
	li	a2, 0
	slli	a1, a1, 32
	srli	a1, a1, 32
	lui	a3, 518149
	slli	a3, a3, 6
.LBB0_2:                                # %while.cond
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a3)
	andi	a4, a4, 32
	beqz	a4, .LBB0_2
# %bb.3:                                # %while.end
                                        #   in Loop: Header=BB0_2 Depth=1
	add	a4, a0, a2
	lb	a5, 0(a4)
	sb	a5, 0(a3)
	lbu	a4, 0(a4)
	addi	a4, a4, -10
	snez	a4, a4
	addi	a2, a2, 1
	sltu	a5, a2, a1
	and	a4, a4, a5
	bnez	a4, .LBB0_2
.LBB0_4:                                # %cleanup
	ret
.Lfunc_end0:
	.size	printbuf, .Lfunc_end0-printbuf
                                        # -- End function
	.globl	pass                            # -- Begin function pass
	.p2align	2
	.type	pass,@function
pass:                                   # @pass
# %bb.0:                                # %entry
	addi	sp, sp, -16
	li	a0, 129
	slli	a0, a0, 32
	ld	a0, 0(a0)
	sd	a0, 8(sp)
.LBB1_1:                                # %while.cond
                                        # =>This Inner Loop Header: Depth=1
	j	.LBB1_1
.Lfunc_end1:
	.size	pass, .Lfunc_end1-pass
                                        # -- End function
	.globl	fail                            # -- Begin function fail
	.p2align	2
	.type	fail,@function
fail:                                   # @fail
# %bb.0:                                # %entry
	addi	sp, sp, -16
	li	a0, 65
	slli	a0, a0, 33
	ld	a0, 0(a0)
	sd	a0, 8(sp)
.LBB2_1:                                # %while.cond
                                        # =>This Inner Loop Header: Depth=1
	j	.LBB2_1
.Lfunc_end2:
	.size	fail, .Lfunc_end2-fail
                                        # -- End function
	.globl	setStats                        # -- Begin function setStats
	.p2align	2
	.type	setStats,@function
setStats:                               # @setStats
# %bb.0:                                # %entry
	#APP
	csrr	a2, mcycle
	#NO_APP
.LBB3_3:                                # %entry
                                        # Label of block must be emitted
	auipc	a1, %pcrel_hi(counters.1)
	addi	a1, a1, %pcrel_lo(.LBB3_3)
	beqz	a0, .LBB3_2
# %bb.1:                                # %if.end
.LBB3_4:                                # %if.end
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(counters.0)
	addi	a0, a0, %pcrel_lo(.LBB3_4)
	sw	a2, 0(a0)
	#APP
	csrr	a0, minstret
	#NO_APP
	sw	a0, 0(a1)
	ret
.LBB3_2:                                # %if.then16
.LBB3_5:                                # %if.then16
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(counters.0)
	addi	a0, a0, %pcrel_lo(.LBB3_5)
	lw	a3, 0(a0)
	subw	a2, a2, a3
.LBB3_6:                                # %if.then16
                                        # Label of block must be emitted
	auipc	a3, %pcrel_hi(counter_names.0)
	addi	a3, a3, %pcrel_lo(.LBB3_6)
.LBB3_7:                                # %if.then16
                                        # Label of block must be emitted
	auipc	a4, %pcrel_hi(.L.str)
	addi	a4, a4, %pcrel_lo(.LBB3_7)
	sd	a4, 0(a3)
	sw	a2, 0(a0)
	#APP
	csrr	a0, minstret
	#NO_APP
	lw	a2, 0(a1)
	subw	a0, a0, a2
.LBB3_8:                                # %if.then16
                                        # Label of block must be emitted
	auipc	a2, %pcrel_hi(counter_names.1)
	addi	a2, a2, %pcrel_lo(.LBB3_8)
.LBB3_9:                                # %if.then16
                                        # Label of block must be emitted
	auipc	a3, %pcrel_hi(.L.str.1)
	addi	a3, a3, %pcrel_lo(.LBB3_9)
	sd	a3, 0(a2)
	sw	a0, 0(a1)
	ret
.Lfunc_end3:
	.size	setStats, .Lfunc_end3-setStats
                                        # -- End function
	.globl	tohost_exit                     # -- Begin function tohost_exit
	.p2align	2
	.type	tohost_exit,@function
tohost_exit:                            # @tohost_exit
# %bb.0:                                # %entry
	addi	sp, sp, -16
	sd	ra, 8(sp)                       # 8-byte Folded Spill
	bnez	a0, .LBB4_2
# %bb.1:                                # %if.else
.LBB4_3:                                # %if.else
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(.L.str.3)
	addi	a0, a0, %pcrel_lo(.LBB4_3)
	li	a1, 0
	call	printf
	call	pass
.LBB4_2:                                # %if.then
	mv	a1, a0
.LBB4_4:                                # %if.then
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(.L.str.2)
	addi	a0, a0, %pcrel_lo(.LBB4_4)
	call	printf
	call	fail
.Lfunc_end4:
	.size	tohost_exit, .Lfunc_end4-tohost_exit
                                        # -- End function
	.globl	printf                          # -- Begin function printf
	.p2align	2
	.type	printf,@function
printf:                                 # @printf
# %bb.0:                                # %entry
	addi	sp, sp, -80
	sd	ra, 8(sp)                       # 8-byte Folded Spill
	mv	t0, a0
	sd	a7, 72(sp)
	sd	a6, 64(sp)
	sd	a5, 56(sp)
	sd	a4, 48(sp)
	sd	a3, 40(sp)
	sd	a2, 32(sp)
	sd	a1, 24(sp)
	addi	a0, sp, 24
	sd	a0, 0(sp)
.LBB5_1:                                # %entry
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(putchar)
	addi	a0, a0, %pcrel_lo(.LBB5_1)
	addi	a3, sp, 24
	li	a1, 0
	mv	a2, t0
	call	vprintfmt
	li	a0, 0
	ld	ra, 8(sp)                       # 8-byte Folded Reload
	addi	sp, sp, 80
	ret
.Lfunc_end5:
	.size	printf, .Lfunc_end5-printf
                                        # -- End function
	.weak	handle_trap                     # -- Begin function handle_trap
	.p2align	2
	.type	handle_trap,@function
handle_trap:                            # @handle_trap
# %bb.0:                                # %entry
	li	a0, 1337
	call	tohost_exit
.Lfunc_end6:
	.size	handle_trap, .Lfunc_end6-handle_trap
                                        # -- End function
	.globl	exit                            # -- Begin function exit
	.p2align	2
	.type	exit,@function
exit:                                   # @exit
# %bb.0:                                # %entry
	call	tohost_exit
.Lfunc_end7:
	.size	exit, .Lfunc_end7-exit
                                        # -- End function
	.globl	abort                           # -- Begin function abort
	.p2align	2
	.type	abort,@function
abort:                                  # @abort
# %bb.0:                                # %entry
	li	a0, 134
	call	exit
.Lfunc_end8:
	.size	abort, .Lfunc_end8-abort
                                        # -- End function
	.globl	printstr                        # -- Begin function printstr
	.p2align	2
	.type	printstr,@function
printstr:                               # @printstr
# %bb.0:                                # %entry
	li	a1, 0
.LBB9_1:                                # %while.cond.i
                                        # =>This Inner Loop Header: Depth=1
	add	a2, a0, a1
	lbu	a2, 0(a2)
	addi	a1, a1, 1
	bnez	a2, .LBB9_1
# %bb.2:                                # %strlen.exit
	addiw	a2, a1, -1
	blez	a2, .LBB9_6
# %bb.3:                                # %while.cond.preheader.preheader.i
	li	a2, 0
	addi	a1, a1, -1
	slli	a1, a1, 32
	srli	a1, a1, 32
	lui	a3, 518149
	slli	a3, a3, 6
.LBB9_4:                                # %while.cond.i3
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a3)
	andi	a4, a4, 32
	beqz	a4, .LBB9_4
# %bb.5:                                # %while.end.i
                                        #   in Loop: Header=BB9_4 Depth=1
	add	a4, a0, a2
	lb	a5, 0(a4)
	sb	a5, 0(a3)
	lbu	a4, 0(a4)
	addi	a4, a4, -10
	snez	a4, a4
	addi	a2, a2, 1
	sltu	a5, a2, a1
	and	a4, a4, a5
	bnez	a4, .LBB9_4
.LBB9_6:                                # %printbuf.exit
	ret
.Lfunc_end9:
	.size	printstr, .Lfunc_end9-printstr
                                        # -- End function
	.globl	strlen                          # -- Begin function strlen
	.p2align	2
	.type	strlen,@function
strlen:                                 # @strlen
# %bb.0:                                # %entry
	li	a1, 0
.LBB10_1:                               # %while.cond
                                        # =>This Inner Loop Header: Depth=1
	add	a2, a0, a1
	lbu	a2, 0(a2)
	addi	a1, a1, 1
	bnez	a2, .LBB10_1
# %bb.2:                                # %while.end
	addi	a0, a1, -1
	ret
.Lfunc_end10:
	.size	strlen, .Lfunc_end10-strlen
                                        # -- End function
	.weak	main                            # -- Begin function main
	.p2align	2
	.type	main,@function
main:                                   # @main
# %bb.0:                                # %while.cond.preheader.preheader.i.i
	li	a0, 0
	lui	a1, 518149
	slli	a1, a1, 6
.LBB11_4:                               # %while.cond.preheader.preheader.i.i
                                        # Label of block must be emitted
	auipc	a2, %pcrel_hi(.L.str.4)
	addi	a2, a2, %pcrel_lo(.LBB11_4)
	li	a3, 23
.LBB11_1:                               # %while.cond.i3.i
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a1)
	andi	a4, a4, 32
	beqz	a4, .LBB11_1
# %bb.2:                                # %while.end.i.i
                                        #   in Loop: Header=BB11_1 Depth=1
	add	a4, a0, a2
	lb	a4, 0(a4)
	addi	a0, a0, 1
	sb	a4, 0(a1)
	bne	a0, a3, .LBB11_1
# %bb.3:                                # %printstr.exit
	li	a0, -1
	ret
.Lfunc_end11:
	.size	main, .Lfunc_end11-main
                                        # -- End function
	.globl	_init                           # -- Begin function _init
	.p2align	2
	.type	_init,@function
_init:                                  # @_init
# %bb.0:                                # %entry
	addi	sp, sp, -128
	sd	ra, 120(sp)                     # 8-byte Folded Spill
	sd	s0, 112(sp)                     # 8-byte Folded Spill
	sd	s1, 104(sp)                     # 8-byte Folded Spill
	sd	s2, 96(sp)                      # 8-byte Folded Spill
	sd	s3, 88(sp)                      # 8-byte Folded Spill
	sd	s4, 80(sp)                      # 8-byte Folded Spill
	addi	s0, sp, 128
	andi	sp, sp, -64
	mv	s1, a1
	mv	s4, a0
	sb	a0, 78(sp)
	sb	a1, 79(sp)
	addi	a0, sp, 78
	sd	a0, 64(sp)
	li	a0, 2
	addi	a1, sp, 64
	call	main
.LBB12_16:                              # %entry
                                        # Label of block must be emitted
	auipc	a1, %pcrel_hi(_init.finish_sync0)
	addi	a1, a1, %pcrel_lo(.LBB12_16)
	li	a2, 1
	#APP
	amoadd.w	zero, a2, (a1)
	#NO_APP
	mv	s2, a0
.LBB12_1:                               # %while.cond
                                        # =>This Inner Loop Header: Depth=1
	lw	a0, 0(a1)
	bne	a0, s1, .LBB12_1
# %bb.2:                                # %while.cond5.preheader
.LBB12_17:                              # %while.cond5.preheader
                                        # Label of block must be emitted
	auipc	s1, %pcrel_hi(_init.finish_sync1)
	addi	s1, s1, %pcrel_lo(.LBB12_17)
.LBB12_3:                               # %while.cond5
                                        # =>This Inner Loop Header: Depth=1
	lw	a0, 0(s1)
	bne	a0, s4, .LBB12_3
# %bb.4:                                # %while.end9
.LBB12_18:                              # %while.end9
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(counters.0)
	addi	a0, a0, %pcrel_lo(.LBB12_18)
	lwu	a0, 0(a0)
	li	s3, 0
	beqz	a0, .LBB12_6
# %bb.5:                                # %if.then
.LBB12_19:                              # %if.then
                                        # Label of block must be emitted
	auipc	a1, %pcrel_hi(counter_names.0)
	addi	a1, a1, %pcrel_lo(.LBB12_19)
	ld	a3, 0(a1)
	sext.w	a4, a0
.LBB12_20:                              # %if.then
                                        # Label of block must be emitted
	auipc	a1, %pcrel_hi(.L.str.5)
	addi	a1, a1, %pcrel_lo(.LBB12_20)
	mv	a0, sp
	mv	a2, s4
	call	sprintf
	mv	s3, a0
.LBB12_6:                               # %for.inc
.LBB12_21:                              # %for.inc
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(counters.1)
	addi	a0, a0, %pcrel_lo(.LBB12_21)
	lwu	a1, 0(a0)
	beqz	a1, .LBB12_8
# %bb.7:                                # %if.then.1
.LBB12_22:                              # %if.then.1
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(counter_names.1)
	addi	a0, a0, %pcrel_lo(.LBB12_22)
	ld	a3, 0(a0)
	mv	a0, sp
	add	a0, a0, s3
	sext.w	a4, a1
.LBB12_23:                              # %if.then.1
                                        # Label of block must be emitted
	auipc	a1, %pcrel_hi(.L.str.5)
	addi	a1, a1, %pcrel_lo(.LBB12_23)
	mv	a2, s4
	call	sprintf
	add	s3, s3, a0
.LBB12_8:                               # %for.inc.1
	beqz	s3, .LBB12_15
# %bb.9:                                # %while.cond.i.i.preheader
	li	a0, 0
	mv	a1, sp
.LBB12_10:                              # %while.cond.i.i
                                        # =>This Inner Loop Header: Depth=1
	add	a2, a1, a0
	lbu	a2, 0(a2)
	addi	a0, a0, 1
	bnez	a2, .LBB12_10
# %bb.11:                               # %strlen.exit.i
	addiw	a1, a0, -1
	blez	a1, .LBB12_15
# %bb.12:                               # %while.cond.preheader.preheader.i.i
	li	a1, 0
	addi	a0, a0, -1
	slli	a0, a0, 32
	srli	a0, a0, 32
	lui	a2, 518149
	slli	a2, a2, 6
	mv	a6, sp
.LBB12_13:                              # %while.cond.i3.i
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a2)
	andi	a4, a4, 32
	beqz	a4, .LBB12_13
# %bb.14:                               # %while.end.i.i
                                        #   in Loop: Header=BB12_13 Depth=1
	add	a4, a6, a1
	lbu	a4, 0(a4)
	addi	a5, a4, -10
	snez	a5, a5
	addi	a1, a1, 1
	sltu	a3, a1, a0
	and	a3, a5, a3
	sb	a4, 0(a2)
	bnez	a3, .LBB12_13
.LBB12_15:                              # %if.end23
	li	a0, 1
	#APP
	amoadd.w	zero, a0, (s1)
	#NO_APP
	mv	a0, s2
	call	exit
.Lfunc_end12:
	.size	_init, .Lfunc_end12-_init
                                        # -- End function
	.globl	sprintf                         # -- Begin function sprintf
	.p2align	2
	.type	sprintf,@function
sprintf:                                # @sprintf
# %bb.0:                                # %entry
	addi	sp, sp, -400
	sd	s0, 344(sp)                     # 8-byte Folded Spill
	sd	s1, 336(sp)                     # 8-byte Folded Spill
	sd	s2, 328(sp)                     # 8-byte Folded Spill
	sd	s3, 320(sp)                     # 8-byte Folded Spill
	sd	s4, 312(sp)                     # 8-byte Folded Spill
	sd	s5, 304(sp)                     # 8-byte Folded Spill
	sd	s6, 296(sp)                     # 8-byte Folded Spill
	sd	s7, 288(sp)                     # 8-byte Folded Spill
	sd	s8, 280(sp)                     # 8-byte Folded Spill
	sd	s9, 272(sp)                     # 8-byte Folded Spill
	sd	s10, 264(sp)                    # 8-byte Folded Spill
	sd	a7, 392(sp)
	sd	a6, 384(sp)
	sd	a5, 376(sp)
	sd	a4, 368(sp)
	sd	a3, 360(sp)
	sd	a2, 352(sp)
	addi	t1, sp, 352
	sd	t1, 0(sp)
	neg	a7, a0
	addi	a6, sp, 12
	li	s8, 37
	li	t0, 85
.LBB13_60:                              # %entry
                                        # Label of block must be emitted
	auipc	t4, %pcrel_hi(.LJTI13_0)
	addi	t4, t4, %pcrel_lo(.LBB13_60)
	li	s6, 10
	li	s9, 246
	li	t2, 2
	li	t3, 45
	addi	t5, sp, 8
	li	t6, 9
	li	s5, 1
	li	s2, 48
	li	s3, 120
	li	s4, 32
.LBB13_1:                               # %while.cond.i
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB13_2 Depth 2
                                        #     Child Loop BB13_5 Depth 2
                                        #       Child Loop BB13_8 Depth 3
                                        #     Child Loop BB13_30 Depth 2
                                        #     Child Loop BB13_34 Depth 2
                                        #     Child Loop BB13_39 Depth 2
                                        #     Child Loop BB13_56 Depth 2
                                        #     Child Loop BB13_48 Depth 2
                                        #     Child Loop BB13_50 Depth 2
                                        #     Child Loop BB13_53 Depth 2
	add	a2, a7, a0
	addi	a3, a1, 1
	lbu	a1, -1(a3)
	beqz	a1, .LBB13_59
.LBB13_2:                               # %while.cond1.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	beq	a1, s8, .LBB13_4
# %bb.3:                                # %if.end.i
                                        #   in Loop: Header=BB13_2 Depth=2
	sb	a1, 0(a0)
	addi	a0, a0, 1
	addi	a2, a2, 1
	addi	a3, a3, 1
	lbu	a1, -1(a3)
	bnez	a1, .LBB13_2
	j	.LBB13_59
.LBB13_4:                               # %while.end.i
                                        #   in Loop: Header=BB13_1 Depth=1
	li	s7, 0
	li	s10, 32
	li	s1, -1
	li	a2, -1
	mv	a1, a3
.LBB13_5:                               # %reswitch.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB13_8 Depth 3
	mv	a4, a1
	lbu	a5, 0(a1)
	addi	a1, a5, -35
	bltu	t0, a1, .LBB13_16
# %bb.6:                                # %reswitch.i
                                        #   in Loop: Header=BB13_5 Depth=2
	slli	a1, a1, 3
	add	a1, a1, t4
	ld	s0, 0(a1)
	addi	a1, a4, 1
	jr	s0
.LBB13_7:                               # %for.cond.i.loopexit
                                        #   in Loop: Header=BB13_5 Depth=2
	li	s1, 0
.LBB13_8:                               # %for.cond.i
                                        #   Parent Loop BB13_1 Depth=1
                                        #     Parent Loop BB13_5 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	andi	a1, a5, 255
	lbu	a5, 1(a4)
	addi	a4, a4, 1
	mulw	s0, s1, s6
	addw	a1, a1, s0
	addi	s0, a5, -58
	andi	s0, s0, 255
	addiw	s1, a1, -48
	bgeu	s0, s9, .LBB13_8
# %bb.9:                                #   in Loop: Header=BB13_5 Depth=2
	mv	a1, a4
	sext.w	a4, a2
	bgez	a4, .LBB13_5
.LBB13_10:                              #   in Loop: Header=BB13_5 Depth=2
	mv	a2, s1
	li	s1, -1
	j	.LBB13_5
.LBB13_11:                              # %reswitch.outer186.i.loopexit
                                        #   in Loop: Header=BB13_5 Depth=2
	mv	s10, a5
	j	.LBB13_5
.LBB13_12:                              # %sw.bb19.i
                                        #   in Loop: Header=BB13_5 Depth=2
	lwu	s1, 0(t1)
	addi	t1, t1, 8
	sext.w	a4, a2
	bgez	a4, .LBB13_5
	j	.LBB13_10
.LBB13_13:                              # %sw.bb20.i
                                        #   in Loop: Header=BB13_5 Depth=2
	sext.w	a4, a2
	bgtz	a4, .LBB13_5
# %bb.14:                               # %sw.bb20.i
                                        #   in Loop: Header=BB13_5 Depth=2
	li	a2, 0
	j	.LBB13_5
.LBB13_15:                              # %sw.bb30.i
                                        #   in Loop: Header=BB13_5 Depth=2
	addiw	s7, s7, 1
	j	.LBB13_5
.LBB13_16:                              # %sw.default.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sb	s8, 0(a0)
	addi	a0, a0, 1
	mv	a1, a3
	j	.LBB13_1
.LBB13_17:                              # %sw.bb92.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sb	s8, 0(a0)
	addi	a0, a0, 1
	j	.LBB13_1
.LBB13_18:                              # %sw.bb31.i
                                        #   in Loop: Header=BB13_1 Depth=1
	lb	a2, 0(t1)
	addi	t1, t1, 8
	sb	a2, 0(a0)
	addi	a0, a0, 1
	j	.LBB13_1
.LBB13_19:                              # %sw.bb79.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sext.w	a3, s7
	bge	a3, t2, .LBB13_21
# %bb.20:                               # %if.else.i.i
                                        #   in Loop: Header=BB13_1 Depth=1
	beqz	a3, .LBB13_58
.LBB13_21:                              # %if.then1.i.i
                                        #   in Loop: Header=BB13_1 Depth=1
	ld	s1, 0(t1)
	li	a3, 10
	bgez	s1, .LBB13_46
.LBB13_22:                              # %if.then83.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sb	t3, 0(a0)
	addi	a0, a0, 1
	neg	s1, s1
	j	.LBB13_46
.LBB13_23:                              # %unsigned_number.i.loopexit432
                                        #   in Loop: Header=BB13_1 Depth=1
	li	a3, 8
	sext.w	a4, s7
	blt	a4, t2, .LBB13_44
	j	.LBB13_45
.LBB13_24:                              # %if.else.i168.thread.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sb	s2, 0(a0)
	sb	s3, 1(a0)
	addi	a0, a0, 2
	li	a3, 16
	ld	s1, 0(t1)
	j	.LBB13_46
.LBB13_25:                              # %sw.bb34.i
                                        #   in Loop: Header=BB13_1 Depth=1
	ld	a3, 0(t1)
	bnez	a3, .LBB13_27
# %bb.26:                               #   in Loop: Header=BB13_1 Depth=1
.LBB13_61:                              #   in Loop: Header=BB13_1 Depth=1
                                        # Label of block must be emitted
	auipc	a3, %pcrel_hi(.L.str.7)
	addi	a3, a3, %pcrel_lo(.LBB13_61)
.LBB13_27:                              # %sw.bb34.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sext.w	a4, a2
	sgtz	a4, a4
	andi	a5, s10, 255
	addi	a5, a5, -45
	snez	a5, a5
	and	a4, a4, a5
	beqz	a4, .LBB13_36
# %bb.28:                               # %if.then46.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sext.w	a5, s1
	mv	a4, a3
	beqz	a5, .LBB13_33
# %bb.29:                               # %land.rhs.preheader.i.i
                                        #   in Loop: Header=BB13_1 Depth=1
	add	s7, a3, a5
	mv	a4, a3
.LBB13_30:                              # %land.rhs.i.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	lbu	s0, 0(a4)
	beqz	s0, .LBB13_33
# %bb.31:                               # %while.body.i.i
                                        #   in Loop: Header=BB13_30 Depth=2
	addi	a5, a5, -1
	addi	a4, a4, 1
	bnez	a5, .LBB13_30
# %bb.32:                               #   in Loop: Header=BB13_1 Depth=1
	mv	a4, s7
.LBB13_33:                              # %strnlen.exit.i
                                        #   in Loop: Header=BB13_1 Depth=1
	subw	a4, a3, a4
	addw	a2, a2, a4
	blez	a2, .LBB13_36
.LBB13_34:                              # %for.body.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	sb	s10, 0(a0)
	sext.w	a4, a2
	addiw	a2, a2, -1
	addi	a0, a0, 1
	bltu	s5, a4, .LBB13_34
# %bb.35:                               #   in Loop: Header=BB13_1 Depth=1
	li	a2, 0
.LBB13_36:                              # %if.end57.i
                                        #   in Loop: Header=BB13_1 Depth=1
	lbu	a5, 0(a3)
	beqz	a5, .LBB13_55
# %bb.37:                               # %land.rhs.i.preheader
                                        #   in Loop: Header=BB13_1 Depth=1
	addi	a3, a3, 1
	j	.LBB13_39
.LBB13_38:                              # %for.body67.i
                                        #   in Loop: Header=BB13_39 Depth=2
	sb	a5, 0(a0)
	lbu	a5, 0(a3)
	addi	a0, a0, 1
	addiw	a2, a2, -1
	addi	a3, a3, 1
	beqz	a5, .LBB13_55
.LBB13_39:                              # %land.rhs.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	sext.w	a4, s1
	bltz	a4, .LBB13_38
# %bb.40:                               # %lor.rhs.i
                                        #   in Loop: Header=BB13_39 Depth=2
	beqz	a4, .LBB13_55
# %bb.41:                               #   in Loop: Header=BB13_39 Depth=2
	addiw	s1, s1, -1
	j	.LBB13_38
.LBB13_42:                              # %unsigned_number.i.loopexit
                                        #   in Loop: Header=BB13_1 Depth=1
	li	a3, 10
	sext.w	a4, s7
	bge	a4, t2, .LBB13_45
	j	.LBB13_44
.LBB13_43:                              # %unsigned_number.i.loopexit619
                                        #   in Loop: Header=BB13_1 Depth=1
	li	a3, 16
	sext.w	a4, s7
	bge	a4, t2, .LBB13_45
.LBB13_44:                              # %if.else.i168.i
                                        #   in Loop: Header=BB13_1 Depth=1
	beqz	a4, .LBB13_57
.LBB13_45:                              # %if.then.i164.i
                                        #   in Loop: Header=BB13_1 Depth=1
	ld	s1, 0(t1)
.LBB13_46:                              # %signed_number.i
                                        #   in Loop: Header=BB13_1 Depth=1
	remu	a4, s1, a3
	sw	a4, 8(sp)
	li	a5, 1
	bltu	s1, a3, .LBB13_49
# %bb.47:                               # %if.end.i.i.preheader
                                        #   in Loop: Header=BB13_1 Depth=1
	li	a5, 1
	mv	a4, a6
.LBB13_48:                              # %if.end.i.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	divu	s1, s1, a3
	remu	s0, s1, a3
	addi	a5, a5, 1
	sw	s0, 0(a4)
	addi	a4, a4, 4
	bgeu	s1, a3, .LBB13_48
.LBB13_49:                              # %while.cond5.preheader.i.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sext.w	a4, a2
	sext.w	a3, a5
	bge	a3, a4, .LBB13_51
.LBB13_50:                              # %while.body8.i.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	addiw	a2, a2, -1
	sb	s10, 0(a0)
	addi	a0, a0, 1
	blt	a3, a2, .LBB13_50
.LBB13_51:                              # %while.cond10.preheader.i.i
                                        #   in Loop: Header=BB13_1 Depth=1
	addi	t1, t1, 8
	slli	a2, a5, 32
	srli	a2, a2, 32
	j	.LBB13_53
.LBB13_52:                              # %while.body14.i.i
                                        #   in Loop: Header=BB13_53 Depth=2
	addw	a3, a4, a3
	sb	a3, 0(a0)
	addi	a0, a0, 1
	sext.w	a3, a2
	addi	a2, a2, -1
	bge	s5, a3, .LBB13_1
.LBB13_53:                              # %while.body14.i.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	addiw	a5, a5, -1
	slli	a3, a5, 32
	srli	a3, a3, 30
	add	a3, t5, a3
	lw	a3, 0(a3)
	li	a4, 87
	bltu	t6, a3, .LBB13_52
# %bb.54:                               # %while.body14.i.i
                                        #   in Loop: Header=BB13_53 Depth=2
	li	a4, 48
	j	.LBB13_52
.LBB13_55:                              # %for.end71.i
                                        #   in Loop: Header=BB13_1 Depth=1
	sext.w	a3, a2
	addi	t1, t1, 8
	blez	a3, .LBB13_1
.LBB13_56:                              # %for.body75.i
                                        #   Parent Loop BB13_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	sb	s4, 0(a0)
	sext.w	a3, a2
	addiw	a2, a2, -1
	addi	a0, a0, 1
	bltu	s5, a3, .LBB13_56
	j	.LBB13_1
.LBB13_57:                              # %if.else4.i171.i
                                        #   in Loop: Header=BB13_1 Depth=1
	lwu	s1, 0(t1)
	j	.LBB13_46
.LBB13_58:                              # %if.else4.i.i
                                        #   in Loop: Header=BB13_1 Depth=1
	lw	s1, 0(t1)
	li	a3, 10
	bgez	s1, .LBB13_46
	j	.LBB13_22
.LBB13_59:                              # %vprintfmt.exit
	sext.w	a1, a2
	sb	zero, 0(a0)
	mv	a0, a1
	ld	s0, 344(sp)                     # 8-byte Folded Reload
	ld	s1, 336(sp)                     # 8-byte Folded Reload
	ld	s2, 328(sp)                     # 8-byte Folded Reload
	ld	s3, 320(sp)                     # 8-byte Folded Reload
	ld	s4, 312(sp)                     # 8-byte Folded Reload
	ld	s5, 304(sp)                     # 8-byte Folded Reload
	ld	s6, 296(sp)                     # 8-byte Folded Reload
	ld	s7, 288(sp)                     # 8-byte Folded Reload
	ld	s8, 280(sp)                     # 8-byte Folded Reload
	ld	s9, 272(sp)                     # 8-byte Folded Reload
	ld	s10, 264(sp)                    # 8-byte Folded Reload
	addi	sp, sp, 400
	ret
.Lfunc_end13:
	.size	sprintf, .Lfunc_end13-sprintf
	.section	.rodata,"a",@progbits
	.p2align	3
.LJTI13_0:
	.quad	.LBB13_5
	.quad	.LBB13_16
	.quad	.LBB13_17
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_12
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_11
	.quad	.LBB13_13
	.quad	.LBB13_16
	.quad	.LBB13_11
	.quad	.LBB13_7
	.quad	.LBB13_7
	.quad	.LBB13_7
	.quad	.LBB13_7
	.quad	.LBB13_7
	.quad	.LBB13_7
	.quad	.LBB13_7
	.quad	.LBB13_7
	.quad	.LBB13_7
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_18
	.quad	.LBB13_19
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_15
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_23
	.quad	.LBB13_24
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_25
	.quad	.LBB13_16
	.quad	.LBB13_42
	.quad	.LBB13_16
	.quad	.LBB13_16
	.quad	.LBB13_43
                                        # -- End function
	.text
	.globl	putchar                         # -- Begin function putchar
	.p2align	2
	.type	putchar,@function
putchar:                                # @putchar
# %bb.0:                                # %entry
	lui	a1, %tprel_hi(putchar.buflen)
	add	a3, a1, tp, %tprel_add(putchar.buflen)
	lw	a2, %tprel_lo(putchar.buflen)(a3)
	addiw	a1, a2, 1
	addi	a4, a1, -64
	seqz	a4, a4
	sw	a1, %tprel_lo(putchar.buflen)(a3)
	addi	a3, a0, -10
	seqz	a3, a3
	or	a3, a3, a4
	lui	a4, %tprel_hi(putchar.buf)
	add	a4, a4, tp, %tprel_add(putchar.buf)
	addi	a4, a4, %tprel_lo(putchar.buf)
	add	a4, a4, a2
	sb	a0, 0(a4)
	beqz	a3, .LBB14_6
# %bb.1:                                # %if.then
	bltz	a2, .LBB14_5
# %bb.2:                                # %while.cond.preheader.preheader.i
	li	a0, 0
	slli	a1, a1, 32
	srli	a1, a1, 32
	lui	a2, 518149
	slli	a2, a2, 6
	lui	a3, %tprel_hi(putchar.buf)
	add	a3, a3, tp, %tprel_add(putchar.buf)
	addi	a3, a3, %tprel_lo(putchar.buf)
.LBB14_3:                               # %while.cond.i
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a2)
	andi	a4, a4, 32
	beqz	a4, .LBB14_3
# %bb.4:                                # %while.end.i
                                        #   in Loop: Header=BB14_3 Depth=1
	add	a4, a3, a0
	lb	a5, 0(a4)
	sb	a5, 0(a2)
	lbu	a4, 0(a4)
	addi	a4, a4, -10
	snez	a4, a4
	addi	a0, a0, 1
	sltu	a5, a0, a1
	and	a4, a4, a5
	bnez	a4, .LBB14_3
.LBB14_5:                               # %printbuf.exit
	lui	a0, %tprel_hi(putchar.buflen)
	add	a0, a0, tp, %tprel_add(putchar.buflen)
	addi	a0, a0, %tprel_lo(putchar.buflen)
	sw	zero, 0(a0)
.LBB14_6:                               # %if.end
	li	a0, 0
	ret
.Lfunc_end14:
	.size	putchar, .Lfunc_end14-putchar
                                        # -- End function
	.globl	printhex                        # -- Begin function printhex
	.p2align	2
	.type	printhex,@function
printhex:                               # @printhex
# %bb.0:                                # %entry
	andi	a3, a0, 15
	li	a1, 48
	li	a2, 10
	li	a4, 48
	bltu	a3, a2, .LBB15_2
# %bb.1:                                # %entry
	li	a4, 87
.LBB15_2:                               # %entry
	addi	sp, sp, -32
	addw	a3, a4, a3
	sb	a3, 30(sp)
	srli	a3, a0, 4
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_4
# %bb.3:                                # %entry
	li	a4, 87
.LBB15_4:                               # %entry
	addw	a3, a4, a3
	sb	a3, 29(sp)
	srli	a3, a0, 8
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_6
# %bb.5:                                # %entry
	li	a4, 87
.LBB15_6:                               # %entry
	addw	a3, a4, a3
	sb	a3, 28(sp)
	srli	a3, a0, 12
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_8
# %bb.7:                                # %entry
	li	a4, 87
.LBB15_8:                               # %entry
	addw	a3, a4, a3
	sb	a3, 27(sp)
	srli	a3, a0, 16
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_10
# %bb.9:                                # %entry
	li	a4, 87
.LBB15_10:                              # %entry
	addw	a3, a4, a3
	sb	a3, 26(sp)
	srli	a3, a0, 20
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_12
# %bb.11:                               # %entry
	li	a4, 87
.LBB15_12:                              # %entry
	addw	a3, a4, a3
	sb	a3, 25(sp)
	srli	a3, a0, 24
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_14
# %bb.13:                               # %entry
	li	a4, 87
.LBB15_14:                              # %entry
	addw	a3, a4, a3
	sb	a3, 24(sp)
	srliw	a3, a0, 28
	li	a4, 48
	bltu	a3, a2, .LBB15_16
# %bb.15:                               # %entry
	li	a4, 87
.LBB15_16:                              # %entry
	addw	a3, a4, a3
	sb	a3, 23(sp)
	srli	a3, a0, 32
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_18
# %bb.17:                               # %entry
	li	a4, 87
.LBB15_18:                              # %entry
	addw	a3, a4, a3
	sb	a3, 22(sp)
	srli	a3, a0, 36
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_20
# %bb.19:                               # %entry
	li	a4, 87
.LBB15_20:                              # %entry
	addw	a3, a4, a3
	sb	a3, 21(sp)
	srli	a3, a0, 40
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_22
# %bb.21:                               # %entry
	li	a4, 87
.LBB15_22:                              # %entry
	addw	a3, a4, a3
	sb	a3, 20(sp)
	srli	a3, a0, 44
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_24
# %bb.23:                               # %entry
	li	a4, 87
.LBB15_24:                              # %entry
	addw	a3, a4, a3
	sb	a3, 19(sp)
	srli	a3, a0, 48
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_26
# %bb.25:                               # %entry
	li	a4, 87
.LBB15_26:                              # %entry
	addw	a3, a4, a3
	sb	a3, 18(sp)
	srli	a3, a0, 52
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_28
# %bb.27:                               # %entry
	li	a4, 87
.LBB15_28:                              # %entry
	addw	a3, a4, a3
	sb	a3, 17(sp)
	srli	a3, a0, 56
	andi	a3, a3, 15
	li	a4, 48
	bltu	a3, a2, .LBB15_30
# %bb.29:                               # %entry
	li	a4, 87
.LBB15_30:                              # %entry
	addw	a2, a4, a3
	sb	a2, 16(sp)
	srli	a2, a0, 61
	li	a3, 5
	srli	a0, a0, 60
	bltu	a2, a3, .LBB15_32
# %bb.31:                               # %entry
	li	a1, 87
.LBB15_32:                              # %entry
	add	a0, a1, a0
	sb	a0, 15(sp)
	sb	zero, 31(sp)
	addi	a1, sp, 15
	beqz	a0, .LBB15_34
.LBB15_33:                              # %while.cond.i.i.while.cond.i.i_crit_edge
                                        # =>This Inner Loop Header: Depth=1
	lbu	a0, 1(a1)
	addi	a1, a1, 1
	bnez	a0, .LBB15_33
.LBB15_34:                              # %strlen.exit.i
	addi	a6, sp, 15
	subw	a2, a1, a6
	blez	a2, .LBB15_38
# %bb.35:                               # %while.cond.preheader.preheader.i.i
	li	a2, 0
	sub	a1, a1, a6
	slli	a1, a1, 32
	srli	a1, a1, 32
	lui	a3, 518149
	slli	a3, a3, 6
.LBB15_36:                              # %while.cond.i3.i
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a3)
	andi	a4, a4, 32
	beqz	a4, .LBB15_36
# %bb.37:                               # %while.end.i.i
                                        #   in Loop: Header=BB15_36 Depth=1
	add	a4, a6, a2
	lbu	a4, 0(a4)
	addi	a5, a4, -10
	snez	a5, a5
	addi	a2, a2, 1
	sltu	a0, a2, a1
	and	a0, a5, a0
	sb	a4, 0(a3)
	bnez	a0, .LBB15_36
.LBB15_38:                              # %printstr.exit
	addi	sp, sp, 32
	ret
.Lfunc_end15:
	.size	printhex, .Lfunc_end15-printhex
                                        # -- End function
	.p2align	2                               # -- Begin function vprintfmt
	.type	vprintfmt,@function
vprintfmt:                              # @vprintfmt
# %bb.0:                                # %entry
	addi	sp, sp, -384
	sd	ra, 376(sp)                     # 8-byte Folded Spill
	sd	s0, 368(sp)                     # 8-byte Folded Spill
	sd	s1, 360(sp)                     # 8-byte Folded Spill
	sd	s2, 352(sp)                     # 8-byte Folded Spill
	sd	s3, 344(sp)                     # 8-byte Folded Spill
	sd	s4, 336(sp)                     # 8-byte Folded Spill
	sd	s5, 328(sp)                     # 8-byte Folded Spill
	sd	s6, 320(sp)                     # 8-byte Folded Spill
	sd	s7, 312(sp)                     # 8-byte Folded Spill
	sd	s8, 304(sp)                     # 8-byte Folded Spill
	sd	s9, 296(sp)                     # 8-byte Folded Spill
	sd	s10, 288(sp)                    # 8-byte Folded Spill
	sd	s11, 280(sp)                    # 8-byte Folded Spill
	sd	a3, 16(sp)                      # 8-byte Folded Spill
	mv	s3, a2
	mv	s5, a1
	mv	s8, a0
	li	s7, 37
	li	s1, 85
.LBB16_63:                              # %entry
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(.LJTI16_0)
	addi	a0, a0, %pcrel_lo(.LBB16_63)
	sd	a0, 8(sp)                       # 8-byte Folded Spill
	li	s10, 10
	li	s11, 246
	li	s2, 1
.LBB16_1:                               # %while.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB16_2 Depth 2
                                        #     Child Loop BB16_5 Depth 2
                                        #       Child Loop BB16_8 Depth 3
                                        #     Child Loop BB16_30 Depth 2
                                        #     Child Loop BB16_34 Depth 2
                                        #     Child Loop BB16_39 Depth 2
                                        #     Child Loop BB16_59 Depth 2
                                        #     Child Loop BB16_49 Depth 2
                                        #     Child Loop BB16_52 Depth 2
                                        #     Child Loop BB16_55 Depth 2
	addi	s0, s3, 1
	lbu	a0, -1(s0)
	beq	a0, s7, .LBB16_4
.LBB16_2:                               # %while.cond1
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	beqz	a0, .LBB16_62
# %bb.3:                                # %if.end
                                        #   in Loop: Header=BB16_2 Depth=2
	mv	a1, s5
	jalr	s8
	addi	s0, s0, 1
	lbu	a0, -1(s0)
	bne	a0, s7, .LBB16_2
.LBB16_4:                               # %while.end
                                        #   in Loop: Header=BB16_1 Depth=1
	li	a0, 0
	li	s4, 32
	li	s9, -1
	li	s6, -1
	mv	s3, s0
	ld	a5, 8(sp)                       # 8-byte Folded Reload
.LBB16_5:                               # %reswitch
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB16_8 Depth 3
	lbu	a1, 0(s3)
	addi	a3, a1, -35
	bltu	s1, a3, .LBB16_16
# %bb.6:                                # %reswitch
                                        #   in Loop: Header=BB16_5 Depth=2
	mv	a2, s3
	slli	a3, a3, 3
	add	a3, a3, a5
	ld	a3, 0(a3)
	addi	s3, s3, 1
	jr	a3
.LBB16_7:                               # %for.cond.loopexit
                                        #   in Loop: Header=BB16_5 Depth=2
	li	s9, 0
.LBB16_8:                               # %for.cond
                                        #   Parent Loop BB16_1 Depth=1
                                        #     Parent Loop BB16_5 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	andi	a3, a1, 255
	lbu	a1, 1(a2)
	addi	a2, a2, 1
	mulw	a4, s9, s10
	addw	a3, a3, a4
	addi	a4, a1, -58
	andi	a4, a4, 255
	addiw	s9, a3, -48
	bgeu	a4, s11, .LBB16_8
# %bb.9:                                #   in Loop: Header=BB16_5 Depth=2
	mv	s3, a2
	sext.w	a1, s6
	bgez	a1, .LBB16_5
.LBB16_10:                              #   in Loop: Header=BB16_5 Depth=2
	mv	s6, s9
	li	s9, -1
	j	.LBB16_5
.LBB16_11:                              # %reswitch.outer186.loopexit
                                        #   in Loop: Header=BB16_5 Depth=2
	mv	s4, a1
	j	.LBB16_5
.LBB16_12:                              # %sw.bb19
                                        #   in Loop: Header=BB16_5 Depth=2
	ld	a1, 16(sp)                      # 8-byte Folded Reload
	lwu	s9, 0(a1)
	addi	a1, a1, 8
	sd	a1, 16(sp)                      # 8-byte Folded Spill
	sext.w	a1, s6
	bgez	a1, .LBB16_5
	j	.LBB16_10
.LBB16_13:                              # %sw.bb20
                                        #   in Loop: Header=BB16_5 Depth=2
	sext.w	a1, s6
	bgtz	a1, .LBB16_5
# %bb.14:                               # %sw.bb20
                                        #   in Loop: Header=BB16_5 Depth=2
	li	s6, 0
	j	.LBB16_5
.LBB16_15:                              # %sw.bb30
                                        #   in Loop: Header=BB16_5 Depth=2
	addiw	a0, a0, 1
	j	.LBB16_5
.LBB16_16:                              # %sw.default
                                        #   in Loop: Header=BB16_1 Depth=1
	li	a0, 37
	mv	a1, s5
	jalr	s8
	mv	s3, s0
	j	.LBB16_1
.LBB16_17:                              # %sw.bb92
                                        #   in Loop: Header=BB16_1 Depth=1
	li	a0, 37
	mv	a1, s5
	jalr	s8
	j	.LBB16_1
.LBB16_18:                              # %sw.bb31
                                        #   in Loop: Header=BB16_1 Depth=1
	ld	a1, 16(sp)                      # 8-byte Folded Reload
	lw	a0, 0(a1)
	addi	s0, a1, 8
	mv	a1, s5
	jalr	s8
	sd	s0, 16(sp)                      # 8-byte Folded Spill
	j	.LBB16_1
.LBB16_19:                              # %sw.bb79
                                        #   in Loop: Header=BB16_1 Depth=1
	sext.w	a0, a0
	li	a1, 2
	bge	a0, a1, .LBB16_21
# %bb.20:                               # %if.else.i
                                        #   in Loop: Header=BB16_1 Depth=1
	beqz	a0, .LBB16_61
.LBB16_21:                              # %if.then.i
                                        #   in Loop: Header=BB16_1 Depth=1
	ld	a0, 16(sp)                      # 8-byte Folded Reload
	ld	s0, 0(a0)
	li	s9, 10
	bgez	s0, .LBB16_47
.LBB16_22:                              # %if.then83
                                        #   in Loop: Header=BB16_1 Depth=1
	li	a0, 45
	mv	a1, s5
	jalr	s8
	neg	s0, s0
	j	.LBB16_47
.LBB16_23:                              # %unsigned_number.loopexit594
                                        #   in Loop: Header=BB16_1 Depth=1
	li	s9, 8
	j	.LBB16_44
.LBB16_24:                              # %if.else.i168.thread
                                        #   in Loop: Header=BB16_1 Depth=1
	li	a0, 48
	mv	a1, s5
	jalr	s8
	li	a0, 120
	mv	a1, s5
	jalr	s8
	li	s9, 16
	j	.LBB16_46
.LBB16_25:                              # %sw.bb34
                                        #   in Loop: Header=BB16_1 Depth=1
	ld	a0, 16(sp)                      # 8-byte Folded Reload
	ld	s0, 0(a0)
	bnez	s0, .LBB16_27
# %bb.26:                               #   in Loop: Header=BB16_1 Depth=1
.LBB16_64:                              #   in Loop: Header=BB16_1 Depth=1
                                        # Label of block must be emitted
	auipc	s0, %pcrel_hi(.L.str.7)
	addi	s0, s0, %pcrel_lo(.LBB16_64)
.LBB16_27:                              # %sw.bb34
                                        #   in Loop: Header=BB16_1 Depth=1
	sext.w	a0, s6
	sgtz	a0, a0
	andi	s4, s4, 255
	addi	a1, s4, -45
	snez	a1, a1
	and	a0, a0, a1
	beqz	a0, .LBB16_36
# %bb.28:                               # %if.then46
                                        #   in Loop: Header=BB16_1 Depth=1
	sext.w	a1, s9
	mv	a0, s0
	beqz	a1, .LBB16_33
# %bb.29:                               # %land.rhs.preheader.i
                                        #   in Loop: Header=BB16_1 Depth=1
	add	a2, s0, a1
	mv	a0, s0
.LBB16_30:                              # %land.rhs.i
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	lbu	a3, 0(a0)
	beqz	a3, .LBB16_33
# %bb.31:                               # %while.body.i
                                        #   in Loop: Header=BB16_30 Depth=2
	addi	a1, a1, -1
	addi	a0, a0, 1
	bnez	a1, .LBB16_30
# %bb.32:                               #   in Loop: Header=BB16_1 Depth=1
	mv	a0, a2
.LBB16_33:                              # %strnlen.exit
                                        #   in Loop: Header=BB16_1 Depth=1
	subw	a0, s0, a0
	addw	s6, s6, a0
	blez	s6, .LBB16_36
.LBB16_34:                              # %for.body
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	mv	a0, s4
	mv	a1, s5
	jalr	s8
	sext.w	a0, s6
	addiw	s6, s6, -1
	bltu	s2, a0, .LBB16_34
# %bb.35:                               #   in Loop: Header=BB16_1 Depth=1
	li	s6, 0
.LBB16_36:                              # %if.end57
                                        #   in Loop: Header=BB16_1 Depth=1
	lbu	a0, 0(s0)
	beqz	a0, .LBB16_58
# %bb.37:                               # %land.rhs.preheader
                                        #   in Loop: Header=BB16_1 Depth=1
	addi	s0, s0, 1
	j	.LBB16_39
.LBB16_38:                              # %for.body67
                                        #   in Loop: Header=BB16_39 Depth=2
	andi	a0, a0, 255
	mv	a1, s5
	jalr	s8
	lbu	a0, 0(s0)
	addiw	s6, s6, -1
	addi	s0, s0, 1
	beqz	a0, .LBB16_58
.LBB16_39:                              # %land.rhs
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	sext.w	a1, s9
	bltz	a1, .LBB16_38
# %bb.40:                               # %lor.rhs
                                        #   in Loop: Header=BB16_39 Depth=2
	beqz	a1, .LBB16_58
# %bb.41:                               #   in Loop: Header=BB16_39 Depth=2
	addiw	s9, s9, -1
	j	.LBB16_38
.LBB16_42:                              # %unsigned_number.loopexit
                                        #   in Loop: Header=BB16_1 Depth=1
	li	s9, 10
	j	.LBB16_44
.LBB16_43:                              # %unsigned_number.loopexit779
                                        #   in Loop: Header=BB16_1 Depth=1
	li	s9, 16
.LBB16_44:                              # %unsigned_number
                                        #   in Loop: Header=BB16_1 Depth=1
	sext.w	a0, a0
	li	a1, 2
	bge	a0, a1, .LBB16_46
# %bb.45:                               # %if.else.i168
                                        #   in Loop: Header=BB16_1 Depth=1
	beqz	a0, .LBB16_60
.LBB16_46:                              # %if.then.i164
                                        #   in Loop: Header=BB16_1 Depth=1
	ld	a0, 16(sp)                      # 8-byte Folded Reload
	ld	s0, 0(a0)
.LBB16_47:                              # %signed_number
                                        #   in Loop: Header=BB16_1 Depth=1
	remu	a0, s0, s9
	sw	a0, 24(sp)
	li	s1, 1
	bltu	s0, s9, .LBB16_50
# %bb.48:                               # %if.end.i.preheader
                                        #   in Loop: Header=BB16_1 Depth=1
	li	s1, 1
	addi	a0, sp, 28
.LBB16_49:                              # %if.end.i
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	divu	s0, s0, s9
	remu	a1, s0, s9
	addi	s1, s1, 1
	sw	a1, 0(a0)
	addi	a0, a0, 4
	bgeu	s0, s9, .LBB16_49
.LBB16_50:                              # %while.cond5.preheader.i
                                        #   in Loop: Header=BB16_1 Depth=1
	sext.w	a0, s6
	sext.w	s0, s1
	bge	s0, a0, .LBB16_53
# %bb.51:                               #   in Loop: Header=BB16_1 Depth=1
	andi	s4, s4, 255
.LBB16_52:                              # %while.body8.i
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	addiw	s6, s6, -1
	mv	a0, s4
	mv	a1, s5
	jalr	s8
	blt	s0, s6, .LBB16_52
.LBB16_53:                              # %while.cond10.preheader.i
                                        #   in Loop: Header=BB16_1 Depth=1
	ld	a0, 16(sp)                      # 8-byte Folded Reload
	addi	a0, a0, 8
	sd	a0, 16(sp)                      # 8-byte Folded Spill
	slli	a0, s1, 32
	srli	s0, a0, 32
	addi	s4, sp, 24
	li	s6, 9
	j	.LBB16_55
.LBB16_54:                              # %while.body14.i
                                        #   in Loop: Header=BB16_55 Depth=2
	addw	a0, a1, a0
	mv	a1, s5
	jalr	s8
	sext.w	a0, s0
	addi	s0, s0, -1
	bge	s2, a0, .LBB16_57
.LBB16_55:                              # %while.body14.i
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	addiw	s1, s1, -1
	slli	a0, s1, 32
	srli	a0, a0, 30
	add	a0, s4, a0
	lw	a0, 0(a0)
	li	a1, 87
	bltu	s6, a0, .LBB16_54
# %bb.56:                               # %while.body14.i
                                        #   in Loop: Header=BB16_55 Depth=2
	li	a1, 48
	j	.LBB16_54
.LBB16_57:                              # %printnum.exit
                                        #   in Loop: Header=BB16_1 Depth=1
	li	s1, 85
	j	.LBB16_1
.LBB16_58:                              # %for.end71
                                        #   in Loop: Header=BB16_1 Depth=1
	sext.w	a0, s6
	ld	a1, 16(sp)                      # 8-byte Folded Reload
	addi	a1, a1, 8
	sd	a1, 16(sp)                      # 8-byte Folded Spill
	blez	a0, .LBB16_1
.LBB16_59:                              # %for.body75
                                        #   Parent Loop BB16_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	li	a0, 32
	mv	a1, s5
	jalr	s8
	sext.w	a0, s6
	addiw	s6, s6, -1
	bltu	s2, a0, .LBB16_59
	j	.LBB16_1
.LBB16_60:                              # %if.else4.i171
                                        #   in Loop: Header=BB16_1 Depth=1
	ld	a0, 16(sp)                      # 8-byte Folded Reload
	lwu	s0, 0(a0)
	j	.LBB16_47
.LBB16_61:                              # %if.else4.i
                                        #   in Loop: Header=BB16_1 Depth=1
	ld	a0, 16(sp)                      # 8-byte Folded Reload
	lw	s0, 0(a0)
	li	s9, 10
	bgez	s0, .LBB16_47
	j	.LBB16_22
.LBB16_62:                              # %if.then
	ld	ra, 376(sp)                     # 8-byte Folded Reload
	ld	s0, 368(sp)                     # 8-byte Folded Reload
	ld	s1, 360(sp)                     # 8-byte Folded Reload
	ld	s2, 352(sp)                     # 8-byte Folded Reload
	ld	s3, 344(sp)                     # 8-byte Folded Reload
	ld	s4, 336(sp)                     # 8-byte Folded Reload
	ld	s5, 328(sp)                     # 8-byte Folded Reload
	ld	s6, 320(sp)                     # 8-byte Folded Reload
	ld	s7, 312(sp)                     # 8-byte Folded Reload
	ld	s8, 304(sp)                     # 8-byte Folded Reload
	ld	s9, 296(sp)                     # 8-byte Folded Reload
	ld	s10, 288(sp)                    # 8-byte Folded Reload
	ld	s11, 280(sp)                    # 8-byte Folded Reload
	addi	sp, sp, 384
	ret
.Lfunc_end16:
	.size	vprintfmt, .Lfunc_end16-vprintfmt
	.section	.rodata,"a",@progbits
	.p2align	3
.LJTI16_0:
	.quad	.LBB16_5
	.quad	.LBB16_16
	.quad	.LBB16_17
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_12
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_11
	.quad	.LBB16_13
	.quad	.LBB16_16
	.quad	.LBB16_11
	.quad	.LBB16_7
	.quad	.LBB16_7
	.quad	.LBB16_7
	.quad	.LBB16_7
	.quad	.LBB16_7
	.quad	.LBB16_7
	.quad	.LBB16_7
	.quad	.LBB16_7
	.quad	.LBB16_7
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_18
	.quad	.LBB16_19
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_15
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_23
	.quad	.LBB16_24
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_25
	.quad	.LBB16_16
	.quad	.LBB16_42
	.quad	.LBB16_16
	.quad	.LBB16_16
	.quad	.LBB16_43
                                        # -- End function
	.text
	.globl	sprintf_putch                   # -- Begin function sprintf_putch
	.p2align	2
	.type	sprintf_putch,@function
sprintf_putch:                          # @sprintf_putch
# %bb.0:                                # %entry
	ld	a2, 0(a1)
	sb	a0, 0(a2)
	ld	a0, 0(a1)
	addi	a0, a0, 1
	sd	a0, 0(a1)
	ret
.Lfunc_end17:
	.size	sprintf_putch, .Lfunc_end17-sprintf_putch
                                        # -- End function
	.section	.sdata,"aw",@progbits
	.p2align	3                               # -- Begin function print_float
.LCPI18_0:
	.quad	0x408f400000000000              # double 1000
	.text
	.globl	print_float
	.p2align	2
	.type	print_float,@function
print_float:                            # @print_float
# %bb.0:                                # %entry
	fmv.d.x	ft0, a0
	fcvt.w.d	a1, ft0, rtz
.LBB18_1:                               # %entry
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(.LCPI18_0)
	addi	a0, a0, %pcrel_lo(.LBB18_1)
	fld	ft1, 0(a0)
	li	a0, 1000
	mulw	a0, a1, a0
	fcvt.d.w	ft2, a0
	fmsub.d	ft0, ft0, ft1, ft2
	fcvt.s.d	ft0, ft0
	fcvt.w.s	a2, ft0, rtz
.LBB18_2:                               # %entry
                                        # Label of block must be emitted
	auipc	a0, %pcrel_hi(.L.str.6)
	addi	a0, a0, %pcrel_lo(.LBB18_2)
	tail	printf
.Lfunc_end18:
	.size	print_float, .Lfunc_end18-print_float
                                        # -- End function
	.globl	memcpy                          # -- Begin function memcpy
	.p2align	2
	.type	memcpy,@function
memcpy:                                 # @memcpy
# %bb.0:                                # %entry
	or	a3, a1, a0
	or	a3, a3, a2
	andi	a4, a3, 3
	add	a3, a0, a2
	beqz	a4, .LBB19_4
# %bb.1:                                # %while.cond8.preheader
	bgeu	a0, a3, .LBB19_7
# %bb.2:
	mv	a3, a0
.LBB19_3:                               # %while.body12
                                        # =>This Inner Loop Header: Depth=1
	lb	a4, 0(a1)
	addi	a1, a1, 1
	addi	a5, a3, 1
	addi	a2, a2, -1
	sb	a4, 0(a3)
	mv	a3, a5
	bnez	a2, .LBB19_3
	j	.LBB19_7
.LBB19_4:                               # %if.then
	bgeu	a0, a3, .LBB19_7
# %bb.5:                                # %while.body.preheader
	mv	a2, a0
.LBB19_6:                               # %while.body
                                        # =>This Inner Loop Header: Depth=1
	lw	a4, 0(a1)
	addi	a1, a1, 4
	addi	a5, a2, 4
	sw	a4, 0(a2)
	mv	a2, a5
	bltu	a5, a3, .LBB19_6
.LBB19_7:                               # %if.end
	ret
.Lfunc_end19:
	.size	memcpy, .Lfunc_end19-memcpy
                                        # -- End function
	.globl	memset                          # -- Begin function memset
	.p2align	2
	.type	memset,@function
memset:                                 # @memset
# %bb.0:                                # %entry
	or	a3, a0, a2
	andi	a3, a3, 3
	beqz	a3, .LBB20_4
# %bb.1:                                # %while.cond12.preheader
	add	a3, a0, a2
	bgeu	a0, a3, .LBB20_7
# %bb.2:
	mv	a3, a0
.LBB20_3:                               # %while.body16
                                        # =>This Inner Loop Header: Depth=1
	addi	a4, a3, 1
	addi	a2, a2, -1
	sb	a1, 0(a3)
	mv	a3, a4
	bnez	a2, .LBB20_3
	j	.LBB20_7
.LBB20_4:                               # %if.then
	add	a2, a0, a2
	bgeu	a0, a2, .LBB20_7
# %bb.5:                                # %while.body.preheader
	andi	a1, a1, 255
	lui	a3, 4112
	addiw	a3, a3, 257
	mulw	a1, a1, a3
	mv	a3, a0
.LBB20_6:                               # %while.body
                                        # =>This Inner Loop Header: Depth=1
	addi	a4, a3, 4
	sw	a1, 0(a3)
	mv	a3, a4
	bltu	a4, a2, .LBB20_6
.LBB20_7:                               # %if.end
	ret
.Lfunc_end20:
	.size	memset, .Lfunc_end20-memset
                                        # -- End function
	.globl	strnlen                         # -- Begin function strnlen
	.p2align	2
	.type	strnlen,@function
strnlen:                                # @strnlen
# %bb.0:                                # %entry
	mv	a2, a0
	beqz	a1, .LBB21_5
# %bb.1:                                # %land.rhs.preheader
	add	a3, a0, a1
	mv	a2, a0
.LBB21_2:                               # %land.rhs
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 0(a2)
	beqz	a4, .LBB21_5
# %bb.3:                                # %while.body
                                        #   in Loop: Header=BB21_2 Depth=1
	addi	a1, a1, -1
	addi	a2, a2, 1
	bnez	a1, .LBB21_2
# %bb.4:
	mv	a2, a3
.LBB21_5:                               # %while.end
	sub	a0, a2, a0
	ret
.Lfunc_end21:
	.size	strnlen, .Lfunc_end21-strnlen
                                        # -- End function
	.globl	strcmp                          # -- Begin function strcmp
	.p2align	2
	.type	strcmp,@function
strcmp:                                 # @strcmp
# %bb.0:                                # %entry
.LBB22_1:                               # %do.body
                                        # =>This Inner Loop Header: Depth=1
	lbu	a2, 0(a0)
	lbu	a3, 0(a1)
	addi	a0, a0, 1
	addi	a1, a1, 1
	snez	a4, a2
	xor	a5, a2, a3
	seqz	a5, a5
	and	a4, a4, a5
	bnez	a4, .LBB22_1
# %bb.2:                                # %do.end
	sub	a0, a2, a3
	ret
.Lfunc_end22:
	.size	strcmp, .Lfunc_end22-strcmp
                                        # -- End function
	.globl	strcpy                          # -- Begin function strcpy
	.p2align	2
	.type	strcpy,@function
strcpy:                                 # @strcpy
# %bb.0:                                # %entry
	li	a2, 0
.LBB23_1:                               # %while.cond
                                        # =>This Inner Loop Header: Depth=1
	add	a3, a1, a2
	lbu	a3, 0(a3)
	add	a4, a0, a2
	sb	a3, 0(a4)
	addi	a2, a2, 1
	bnez	a3, .LBB23_1
# %bb.2:                                # %while.end
	ret
.Lfunc_end23:
	.size	strcpy, .Lfunc_end23-strcpy
                                        # -- End function
	.globl	atol                            # -- Begin function atol
	.p2align	2
	.type	atol,@function
atol:                                   # @atol
# %bb.0:                                # %entry
	addi	a2, a0, 1
	li	a0, 32
	lbu	a1, -1(a2)
	bne	a1, a0, .LBB24_2
.LBB24_1:                               # %while.body
                                        # =>This Inner Loop Header: Depth=1
	addi	a2, a2, 1
	lbu	a1, -1(a2)
	beq	a1, a0, .LBB24_1
.LBB24_2:                               # %while.cond
	li	a0, 43
	beq	a1, a0, .LBB24_4
# %bb.3:                                # %while.cond
	li	a0, 45
	bne	a1, a0, .LBB24_5
.LBB24_4:                               # %if.then
	addi	a0, a1, -45
	lbu	a1, 0(a2)
	seqz	a3, a0
	li	a0, 0
	bnez	a1, .LBB24_6
	j	.LBB24_8
.LBB24_5:                               # %if.end.loopexit
	li	a3, 0
	addi	a2, a2, -1
	li	a0, 0
	beqz	a1, .LBB24_8
.LBB24_6:                               # %while.body13.preheader
	addi	a2, a2, 1
	li	a4, 10
.LBB24_7:                               # %while.body13
                                        # =>This Inner Loop Header: Depth=1
	andi	a5, a1, 255
	lbu	a1, 0(a2)
	mul	a0, a0, a4
	add	a0, a0, a5
	addi	a0, a0, -48
	addi	a2, a2, 1
	bnez	a1, .LBB24_7
.LBB24_8:                               # %while.end17
	beqz	a3, .LBB24_10
# %bb.9:                                # %while.end17
	neg	a0, a0
.LBB24_10:                              # %while.end17
	ret
.Lfunc_end24:
	.size	atol, .Lfunc_end24-atol
                                        # -- End function
	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"mcycle"
	.size	.L.str, 7

	.type	.L.str.1,@object                # @.str.1
.L.str.1:
	.asciz	"minstret"
	.size	.L.str.1, 9

	.type	.L.str.2,@object                # @.str.2
.L.str.2:
	.asciz	"\r\n test fail! \r\n"
	.size	.L.str.2, 17

	.type	.L.str.3,@object                # @.str.3
.L.str.3:
	.asciz	"\r\n test pass! \r\n\n"
	.size	.L.str.3, 18

	.type	.L.str.4,@object                # @.str.4
.L.str.4:
	.asciz	"Implement main(), foo!\n"
	.size	.L.str.4, 24

	.type	_init.finish_sync0,@object      # @_init.finish_sync0
	.section	.sbss,"aw",@nobits
	.p2align	2
_init.finish_sync0:
	.word	0                               # 0x0
	.size	_init.finish_sync0, 4

	.type	_init.finish_sync1,@object      # @_init.finish_sync1
	.p2align	2
_init.finish_sync1:
	.word	0                               # 0x0
	.size	_init.finish_sync1, 4

	.type	.L.str.5,@object                # @.str.5
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.5:
	.asciz	"core %d: %s = %d\n"
	.size	.L.str.5, 18

	.type	putchar.buf,@object             # @putchar.buf
	.section	.tbss,"awT",@nobits
	.p2align	6
putchar.buf:
	.zero	64
	.size	putchar.buf, 64

	.type	putchar.buflen,@object          # @putchar.buflen
	.p2align	2
putchar.buflen:
	.word	0                               # 0x0
	.size	putchar.buflen, 4

	.type	.L.str.6,@object                # @.str.6
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.6:
	.asciz	"%u.%u"
	.size	.L.str.6, 6

	.type	.L.str.7,@object                # @.str.7
.L.str.7:
	.asciz	"(null)"
	.size	.L.str.7, 7

	.type	counters.0,@object              # @counters.0
	.section	.sbss,"aw",@nobits
	.p2align	2
counters.0:
	.word	0                               # 0x0
	.size	counters.0, 4

	.type	counters.1,@object              # @counters.1
	.p2align	2
counters.1:
	.word	0                               # 0x0
	.size	counters.1, 4

	.type	counter_names.0,@object         # @counter_names.0
	.p2align	3
counter_names.0:
	.quad	0
	.size	counter_names.0, 8

	.type	counter_names.1,@object         # @counter_names.1
	.p2align	3
counter_names.1:
	.quad	0
	.size	counter_names.1, 8

	.ident	"clang version 14.0.0 (git@repo.hca.bsc.es:EPI/System-Software/llvm-mono.git d033e20a5814218dc061fc28894b2df8c0f36d4d)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym putchar
	.addrsig_sym _init.finish_sync0
	.addrsig_sym _init.finish_sync1
