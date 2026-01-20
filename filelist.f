./includes/pqcuark-common/pipe_queue.sv
./rtl/pqcuark-ntt/rtl/add_sub_32bit.sv
./rtl/pqcuark-ntt/rtl/barrett_reduction/barrett_reduce.sv
./rtl/pqcuark-ntt/rtl/barrett_reduction/bfu_barrett.sv
./rtl/pqcuark-ntt/rtl/mont_reduction/montgomery_dilithium.sv
./rtl/pqcuark-ntt/rtl/mont_reduction/montgomery_kyber.sv
./rtl/pqcuark-ntt/rtl/mont_reduction/bfu_modred.sv
./rtl/pqcuark-ntt/rtl/multiplier/multiplier.sv
./rtl/pqcuark-ntt/rtl/multiplier/bfu_multiplier.sv
./rtl/pqcuark-ntt/rtl/twiddle_factor_rom/zetas_rom.sv
./rtl/pqcuark-ntt/rtl/bfu_top.sv

+incdir+./rtl/pqcuark-keccak/includes
./rtl/pqcuark-keccak/includes/keccak_globals.sv
./rtl/pqcuark-keccak/rtl/keccak_round_constants_gen.sv
./rtl/pqcuark-keccak/rtl/keccak_round_constants_gen_simplified.sv
./rtl/pqcuark-keccak/rtl/keccak_round.sv
./rtl/pqcuark-keccak/rtl/keccak_buffer.sv
./rtl/pqcuark-keccak/rtl/keccak.sv

./interfaces/iface_pqcuark_sargantana_bfu.sv
./interfaces/iface_pqcuark_sargantana_keccak.sv