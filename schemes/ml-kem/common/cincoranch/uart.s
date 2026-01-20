	.text
	.attribute	4, 16
	.attribute	5, "rv64i2p0_m2p0_a2p0_f2p0_d2p0"
	.option	nopic
	.file	"uart.c"
	.globl	write_reg_u8                    # -- Begin function write_reg_u8
	.p2align	2
	.type	write_reg_u8,@function
write_reg_u8:                           # @write_reg_u8
# %bb.0:                                # %entry
	sb	a1, 0(a0)
	ret
.Lfunc_end0:
	.size	write_reg_u8, .Lfunc_end0-write_reg_u8
                                        # -- End function
	.globl	read_reg_u8                     # -- Begin function read_reg_u8
	.p2align	2
	.type	read_reg_u8,@function
read_reg_u8:                            # @read_reg_u8
# %bb.0:                                # %entry
	lbu	a0, 0(a0)
	ret
.Lfunc_end1:
	.size	read_reg_u8, .Lfunc_end1-read_reg_u8
                                        # -- End function
	.globl	is_transmit_empty               # -- Begin function is_transmit_empty
	.p2align	2
	.type	is_transmit_empty,@function
is_transmit_empty:                      # @is_transmit_empty
# %bb.0:                                # %entry
	lui	a0, 518149
	slli	a0, a0, 6
	lbu	a0, 5(a0)
	andi	a0, a0, 32
	ret
.Lfunc_end2:
	.size	is_transmit_empty, .Lfunc_end2-is_transmit_empty
                                        # -- End function
	.globl	write_serial                    # -- Begin function write_serial
	.p2align	2
	.type	write_serial,@function
write_serial:                           # @write_serial
# %bb.0:                                # %entry
	lui	a1, 518149
	slli	a1, a1, 6
.LBB3_1:                                # %while.cond
                                        # =>This Inner Loop Header: Depth=1
	lbu	a2, 5(a1)
	andi	a2, a2, 32
	beqz	a2, .LBB3_1
# %bb.2:                                # %while.end
	lui	a1, 518149
	slli	a1, a1, 6
	sb	a0, 0(a1)
	ret
.Lfunc_end3:
	.size	write_serial, .Lfunc_end3-write_serial
                                        # -- End function
	.globl	init_uart                       # -- Begin function init_uart
	.p2align	2
	.type	init_uart,@function
init_uart:                              # @init_uart
# %bb.0:                                # %entry
	lui	a0, 518149
	slli	a0, a0, 6
	sb	zero, 1(a0)
	li	a1, 128
	sb	a1, 3(a0)
	li	a1, 13
	sb	a1, 0(a0)
	sb	zero, 1(a0)
	li	a1, 3
	sb	a1, 3(a0)
	li	a1, 32
	sb	a1, 4(a0)
	ret
.Lfunc_end4:
	.size	init_uart, .Lfunc_end4-init_uart
                                        # -- End function
	.globl	print_uart                      # -- Begin function print_uart
	.p2align	2
	.type	print_uart,@function
print_uart:                             # @print_uart
# %bb.0:                                # %entry
	lbu	a2, 0(a0)
	beqz	a2, .LBB5_5
# %bb.1:                                # %while.cond.i.preheader.preheader
	li	a1, 0
	lui	a3, 518149
	slli	a3, a3, 6
.LBB5_2:                                # %while.cond.i
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a3)
	andi	a4, a4, 32
	beqz	a4, .LBB5_2
# %bb.3:                                # %write_serial.exit
                                        #   in Loop: Header=BB5_2 Depth=1
	sb	a2, 0(a3)
	lbu	a2, 1(a0)
	addi	a0, a0, 1
	addiw	a1, a1, 1
	bnez	a2, .LBB5_2
# %bb.4:                                # %while.end
	mv	a0, a1
	ret
.LBB5_5:
	li	a0, 0
	ret
.Lfunc_end5:
	.size	print_uart, .Lfunc_end5-print_uart
                                        # -- End function
	.globl	bin_to_hex                      # -- Begin function bin_to_hex
	.p2align	2
	.type	bin_to_hex,@function
bin_to_hex:                             # @bin_to_hex
# %bb.0:                                # %entry
	andi	a2, a0, 15
.LBB6_1:                                # %entry
                                        # Label of block must be emitted
	auipc	a3, %pcrel_hi(bin_to_hex_table)
	addi	a3, a3, %pcrel_lo(.LBB6_1)
	add	a2, a2, a3
	lb	a2, 0(a2)
	sb	a2, 1(a1)
	srli	a0, a0, 4
	add	a0, a0, a3
	lb	a0, 0(a0)
	sb	a0, 0(a1)
	ret
.Lfunc_end6:
	.size	bin_to_hex, .Lfunc_end6-bin_to_hex
                                        # -- End function
	.globl	print_uart_dec                  # -- Begin function print_uart_dec
	.p2align	2
	.type	print_uart_dec,@function
print_uart_dec:                         # @print_uart_dec
# %bb.0:                                # %entry
	li	a7, 0
	li	a3, 9
	lui	a2, 244141
	addiw	a5, a2, -1536
	lui	a2, 838861
	addiw	a2, a2, -819
	slli	t0, a2, 32
.LBB7_7:                                # %entry
                                        # Label of block must be emitted
	auipc	a6, %pcrel_hi(bin_to_hex_table)
	addi	a6, a6, %pcrel_lo(.LBB7_7)
	lui	a2, 518149
	slli	a2, a2, 6
	j	.LBB7_2
.LBB7_1:                                # %if.end
                                        #   in Loop: Header=BB7_2 Depth=1
	mulw	a4, t2, a5
	subw	a0, a0, a4
	slli	a4, a5, 32
	mulhu	a4, a4, t0
	srli	a5, a4, 35
	addiw	a3, a3, -1
	beqz	t1, .LBB7_6
.LBB7_2:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB7_4 Depth 2
	sext.w	t1, a5
	sext.w	a4, a0
	sltu	a4, a4, t1
	xori	t2, a4, 1
	sext.w	a4, a1
	sext.w	t1, a3
	sltu	a4, t1, a4
	or	a4, t2, a4
	divuw	t2, a0, a5
	beqz	a4, .LBB7_1
# %bb.3:                                # %if.then
                                        #   in Loop: Header=BB7_2 Depth=1
	andi	a1, t2, 15
	add	a1, a1, a6
	lbu	a1, 0(a1)
.LBB7_4:                                # %while.cond.i
                                        #   Parent Loop BB7_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	lbu	a4, 5(a2)
	andi	a4, a4, 32
	beqz	a4, .LBB7_4
# %bb.5:                                # %write_serial.exit
                                        #   in Loop: Header=BB7_2 Depth=1
	sb	a1, 0(a2)
	addiw	a7, a7, 1
	mv	a1, a3
	j	.LBB7_1
.LBB7_6:                                # %for.end
	sext.w	a0, a7
	ret
.Lfunc_end7:
	.size	print_uart_dec, .Lfunc_end7-print_uart_dec
                                        # -- End function
	.globl	print_uart_int                  # -- Begin function print_uart_int
	.p2align	2
	.type	print_uart_int,@function
print_uart_int:                         # @print_uart_int
# %bb.0:                                # %entry
	srliw	a1, a0, 24
	andi	a2, a1, 15
.LBB8_17:                               # %entry
                                        # Label of block must be emitted
	auipc	a1, %pcrel_hi(bin_to_hex_table)
	addi	a1, a1, %pcrel_lo(.LBB8_17)
	add	a2, a2, a1
	lbu	a2, 0(a2)
	srliw	a3, a0, 28
	add	a3, a3, a1
	lbu	a3, 0(a3)
	lui	a4, 518149
	slli	a4, a4, 6
.LBB8_1:                                # %while.cond.i
                                        # =>This Inner Loop Header: Depth=1
	lbu	a5, 5(a4)
	andi	a5, a5, 32
	beqz	a5, .LBB8_1
# %bb.2:                                # %write_serial.exit
	lui	a4, 518149
	slli	a4, a4, 6
	sb	a3, 0(a4)
.LBB8_3:                                # %while.cond.i6
                                        # =>This Inner Loop Header: Depth=1
	lbu	a3, 5(a4)
	andi	a3, a3, 32
	beqz	a3, .LBB8_3
# %bb.4:                                # %write_serial.exit7
	lui	a3, 518149
	slli	a3, a3, 6
	sb	a2, 0(a3)
	srliw	a2, a0, 16
	andi	a2, a2, 15
	add	a2, a2, a1
	lbu	a2, 0(a2)
	srliw	a4, a0, 20
	andi	a4, a4, 15
	add	a4, a4, a1
	lbu	a4, 0(a4)
.LBB8_5:                                # %while.cond.i.1
                                        # =>This Inner Loop Header: Depth=1
	lbu	a5, 5(a3)
	andi	a5, a5, 32
	beqz	a5, .LBB8_5
# %bb.6:                                # %write_serial.exit.1
	lui	a3, 518149
	slli	a3, a3, 6
	sb	a4, 0(a3)
.LBB8_7:                                # %while.cond.i6.1
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a3)
	andi	a4, a4, 32
	beqz	a4, .LBB8_7
# %bb.8:                                # %write_serial.exit7.1
	lui	a3, 518149
	slli	a3, a3, 6
	sb	a2, 0(a3)
	srliw	a2, a0, 8
	andi	a2, a2, 15
	add	a2, a2, a1
	lbu	a2, 0(a2)
	srliw	a4, a0, 12
	andi	a4, a4, 15
	add	a4, a4, a1
	lbu	a4, 0(a4)
.LBB8_9:                                # %while.cond.i.2
                                        # =>This Inner Loop Header: Depth=1
	lbu	a5, 5(a3)
	andi	a5, a5, 32
	beqz	a5, .LBB8_9
# %bb.10:                               # %write_serial.exit.2
	lui	a3, 518149
	slli	a3, a3, 6
	sb	a4, 0(a3)
.LBB8_11:                               # %while.cond.i6.2
                                        # =>This Inner Loop Header: Depth=1
	lbu	a4, 5(a3)
	andi	a4, a4, 32
	beqz	a4, .LBB8_11
# %bb.12:                               # %write_serial.exit7.2
	lui	a3, 518149
	slli	a3, a3, 6
	sb	a2, 0(a3)
	andi	a2, a0, 15
	add	a2, a2, a1
	lbu	a2, 0(a2)
	srli	a0, a0, 4
	andi	a0, a0, 15
	add	a0, a0, a1
	lbu	a0, 0(a0)
.LBB8_13:                               # %while.cond.i.3
                                        # =>This Inner Loop Header: Depth=1
	lbu	a1, 5(a3)
	andi	a1, a1, 32
	beqz	a1, .LBB8_13
# %bb.14:                               # %write_serial.exit.3
	lui	a1, 518149
	slli	a1, a1, 6
	sb	a0, 0(a1)
.LBB8_15:                               # %while.cond.i6.3
                                        # =>This Inner Loop Header: Depth=1
	lbu	a0, 5(a1)
	andi	a0, a0, 32
	beqz	a0, .LBB8_15
# %bb.16:                               # %write_serial.exit7.3
	lui	a0, 518149
	slli	a1, a0, 6
	li	a0, 8
	sb	a2, 0(a1)
	ret
.Lfunc_end8:
	.size	print_uart_int, .Lfunc_end8-print_uart_int
                                        # -- End function
	.globl	print_uart_addr                 # -- Begin function print_uart_addr
	.p2align	2
	.type	print_uart_addr,@function
print_uart_addr:                        # @print_uart_addr
# %bb.0:                                # %entry
	li	a4, 7
.LBB9_7:                                # %entry
                                        # Label of block must be emitted
	auipc	a6, %pcrel_hi(bin_to_hex_table)
	addi	a6, a6, %pcrel_lo(.LBB9_7)
	lui	a2, 518149
	slli	a2, a2, 6
.LBB9_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB9_2 Depth 2
                                        #     Child Loop BB9_4 Depth 2
	mv	a3, a4
	slli	a4, a4, 3
	srl	a5, a0, a4
	andi	a4, a5, 15
	add	a4, a4, a6
	lbu	a4, 0(a4)
	srli	a5, a5, 4
	andi	a5, a5, 15
	add	a5, a5, a6
	lbu	a5, 0(a5)
.LBB9_2:                                # %while.cond.i
                                        #   Parent Loop BB9_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	lbu	a1, 5(a2)
	andi	a1, a1, 32
	beqz	a1, .LBB9_2
# %bb.3:                                # %write_serial.exit
                                        #   in Loop: Header=BB9_1 Depth=1
	sb	a5, 0(a2)
.LBB9_4:                                # %while.cond.i6
                                        #   Parent Loop BB9_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	lbu	a1, 5(a2)
	andi	a1, a1, 32
	beqz	a1, .LBB9_4
# %bb.5:                                # %write_serial.exit7
                                        #   in Loop: Header=BB9_1 Depth=1
	sb	a4, 0(a2)
	addi	a4, a3, -1
	bnez	a3, .LBB9_1
# %bb.6:                                # %for.end
	li	a0, 16
	ret
.Lfunc_end9:
	.size	print_uart_addr, .Lfunc_end9-print_uart_addr
                                        # -- End function
	.globl	print_uart_byte                 # -- Begin function print_uart_byte
	.p2align	2
	.type	print_uart_byte,@function
print_uart_byte:                        # @print_uart_byte
# %bb.0:                                # %entry
	andi	a1, a0, 15
.LBB10_5:                               # %entry
                                        # Label of block must be emitted
	auipc	a2, %pcrel_hi(bin_to_hex_table)
	addi	a2, a2, %pcrel_lo(.LBB10_5)
	add	a1, a1, a2
	lbu	a1, 0(a1)
	srli	a0, a0, 4
	add	a0, a0, a2
	lbu	a0, 0(a0)
	lui	a2, 518149
	slli	a2, a2, 6
.LBB10_1:                               # %while.cond.i
                                        # =>This Inner Loop Header: Depth=1
	lbu	a3, 5(a2)
	andi	a3, a3, 32
	beqz	a3, .LBB10_1
# %bb.2:                                # %write_serial.exit
	lui	a2, 518149
	slli	a2, a2, 6
	sb	a0, 0(a2)
.LBB10_3:                               # %while.cond.i3
                                        # =>This Inner Loop Header: Depth=1
	lbu	a0, 5(a2)
	andi	a0, a0, 32
	beqz	a0, .LBB10_3
# %bb.4:                                # %write_serial.exit4
	lui	a0, 518149
	slli	a2, a0, 6
	li	a0, 2
	sb	a1, 0(a2)
	ret
.Lfunc_end10:
	.size	print_uart_byte, .Lfunc_end10-print_uart_byte
                                        # -- End function
	.type	bin_to_hex_table,@object        # @bin_to_hex_table
	.data
	.globl	bin_to_hex_table
bin_to_hex_table:
	.ascii	"0123456789ABCDEF"
	.size	bin_to_hex_table, 16

	.ident	"clang version 14.0.0 (git@repo.hca.bsc.es:EPI/System-Software/llvm-mono.git d033e20a5814218dc061fc28894b2df8c0f36d4d)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
