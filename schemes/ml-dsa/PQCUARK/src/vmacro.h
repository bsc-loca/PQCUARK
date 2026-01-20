#define VZEXT_VF4_U32M4_NO_GROUPING(dest_ptr, src, vl)                \
do {                                                                  \
    size_t vl1 = (vl) / 4;                                            \
                                                                      \
    vuint32m1_t temp_src0_m1 = __riscv_vreinterpret_v_u8m1_u32m1(src);             \
    vuint32m1_t temp_src1_m1 = __riscv_vslide1down_vx_u32m1(temp_src0_m1, 0, vl1); \
    vuint32m1_t temp_src2_m1 = __riscv_vslide1down_vx_u32m1(temp_src1_m1, 0, vl1); \
    vuint32m1_t temp_src3_m1 = __riscv_vslide1down_vx_u32m1(temp_src2_m1, 0, vl1); \
                                                                      \
    vuint8mf4_t temp_src0_mf4 = __riscv_vlmul_trunc_v_u8m1_u8mf4(__riscv_vreinterpret_v_u32m1_u8m1(temp_src0_m1)); \
    vuint8mf4_t temp_src1_mf4 = __riscv_vlmul_trunc_v_u8m1_u8mf4(__riscv_vreinterpret_v_u32m1_u8m1(temp_src1_m1)); \
    vuint8mf4_t temp_src2_mf4 = __riscv_vlmul_trunc_v_u8m1_u8mf4(__riscv_vreinterpret_v_u32m1_u8m1(temp_src2_m1)); \
    vuint8mf4_t temp_src3_mf4 = __riscv_vlmul_trunc_v_u8m1_u8mf4(__riscv_vreinterpret_v_u32m1_u8m1(temp_src3_m1)); \
    vuint32m1_t part0, part1, part2, part3;                           \
                                                                      \
    part0 = __riscv_vzext_vf4_u32m1(temp_src0_mf4, vl1);              \
    __riscv_vse32_v_u32m1((dest_ptr), part0, vl1);                    \
                                                                      \
    part1 = __riscv_vzext_vf4_u32m1(temp_src1_mf4, vl1);              \
    __riscv_vse32_v_u32m1((dest_ptr) + vl1, part1, vl1);              \
                                                                      \
    part2 = __riscv_vzext_vf4_u32m1(temp_src2_mf4, vl1);              \
    __riscv_vse32_v_u32m1((dest_ptr) + 2 * vl1, part2, vl1);          \
                                                                      \
    part3 = __riscv_vzext_vf4_u32m1(temp_src3_mf4, vl1);              \
    __riscv_vse32_v_u32m1((dest_ptr) + 3 * vl1, part3, vl1);          \
} while (0)


#define VMSLTU_VX_U32M4_B8_NO_GROUPING(result_ptr, src, scalar, vl)        \
do {                                                                       \
    size_t vl1 = (vl) / 4;                                                 \
    vuint32m1_t temp_src0 = __riscv_vle32_v_u32m1((src), vl1);             \
    vuint32m1_t temp_src1 = __riscv_vle32_v_u32m1((src) + vl1, vl1);       \
    vuint32m1_t temp_src2 = __riscv_vle32_v_u32m1((src) + 2 * vl1, vl1);   \
    vuint32m1_t temp_src3 = __riscv_vle32_v_u32m1((src) + 3 * vl1, vl1);   \
    vbool32_t mask_part0, mask_part1, mask_part2, mask_part3;              \
                                                                           \
    mask_part0 = __riscv_vmsltu_vx_u32m1_b32(temp_src0, scalar, vl1);      \
    __riscv_vsm_v_b32((result_ptr), mask_part0, vl1);                      \
                                                                           \
    mask_part1 = __riscv_vmsltu_vx_u32m1_b32(temp_src1, scalar, vl1);      \
    __riscv_vsm_v_b32((result_ptr) + 1, mask_part1, vl1);                \
                                                                           \
    mask_part2 = __riscv_vmsltu_vx_u32m1_b32(temp_src2, scalar, vl1);      \
    __riscv_vsm_v_b32((result_ptr) + 2, mask_part2, vl1);            \
                                                                           \
    mask_part3 = __riscv_vmsltu_vx_u32m1_b32(temp_src3, scalar, vl1);      \
    __riscv_vsm_v_b32((result_ptr) + 3, mask_part3, vl1);            \
} while (0)

#define VMUL_VX_U32M4_NO_GROUPING(result_ptr, src, scalar, vl)        \
do {                                                                       \
    size_t vl1 = (vl) / 4;                                                 \
    vuint32m1_t temp_src0 = __riscv_vle32_v_u32m1((src), vl1);             \
    vuint32m1_t temp_src1 = __riscv_vle32_v_u32m1((src) + vl1, vl1);       \
    vuint32m1_t temp_src2 = __riscv_vle32_v_u32m1((src) + 2 * vl1, vl1);   \
    vuint32m1_t temp_src3 = __riscv_vle32_v_u32m1((src) + 3 * vl1, vl1);   \
    vuint32m1_t part0, part1, part2, part3;              \
                                                                           \
    part0 = __riscv_vmul_vx_u32m1(temp_src0, scalar, vl1);      \
    __riscv_vse32_v_u32m1((result_ptr), part0, vl1);                      \
                                                                           \
    part1 = __riscv_vmul_vx_u32m1(temp_src1, scalar, vl1);      \
    __riscv_vse32_v_u32m1((result_ptr) + vl1, part1, vl1);                \
                                                                           \
    part2 = __riscv_vmul_vx_u32m1(temp_src2, scalar, vl1);      \
    __riscv_vse32_v_u32m1((result_ptr) + 2 * vl1, part2, vl1);            \
                                                                           \
    part3 = __riscv_vmul_vx_u32m1(temp_src3, scalar, vl1);      \
    __riscv_vse32_v_u32m1((result_ptr) + 3 * vl1, part3, vl1);            \
} while (0)

#define VSRL_VX_U32M4_NO_GROUPING(result_ptr, src, scalar, vl)        \
do {                                                                       \
    size_t vl1 = (vl) / 4;                                                 \
    vuint32m1_t temp_src0 = __riscv_vle32_v_u32m1((src), vl1);             \
    vuint32m1_t temp_src1 = __riscv_vle32_v_u32m1((src) + vl1, vl1);       \
    vuint32m1_t temp_src2 = __riscv_vle32_v_u32m1((src) + 2 * vl1, vl1);   \
    vuint32m1_t temp_src3 = __riscv_vle32_v_u32m1((src) + 3 * vl1, vl1);   \
    vuint32m1_t part0, part1, part2, part3;              \
                                                                           \
    part0 = __riscv_vsrl_vx_u32m1(temp_src0, scalar, vl1);      \
    __riscv_vse32_v_u32m1((result_ptr), part0, vl1);                      \
                                                                           \
    part1 = __riscv_vsrl_vx_u32m1(temp_src1, scalar, vl1);      \
    __riscv_vse32_v_u32m1((result_ptr) + vl1, part1, vl1);                \
                                                                           \
    part2 = __riscv_vsrl_vx_u32m1(temp_src2, scalar, vl1);      \
    __riscv_vse32_v_u32m1((result_ptr) + 2 * vl1, part2, vl1);            \
                                                                           \
    part3 = __riscv_vsrl_vx_u32m1(temp_src3, scalar, vl1);      \
    __riscv_vse32_v_u32m1((result_ptr) + 3 * vl1, part3, vl1);            \
} while (0)

#define VSUB_VV_U32M4_NO_GROUPING(result_ptr, src2, src1, vl)             \
do {                                                                      \
    size_t vl1 = (vl) / 4;                                                \
    vuint32m1_t temp_src1_0 = __riscv_vle32_v_u32m1((src1), vl1);         \
    vuint32m1_t temp_src1_1 = __riscv_vle32_v_u32m1((src1) + vl1, vl1);   \
    vuint32m1_t temp_src1_2 = __riscv_vle32_v_u32m1((src1) + 2 * vl1, vl1); \
    vuint32m1_t temp_src1_3 = __riscv_vle32_v_u32m1((src1) + 3 * vl1, vl1); \
                                                                          \
    vuint32m1_t temp_src2_0 = __riscv_vle32_v_u32m1((src2), vl1);         \
    vuint32m1_t temp_src2_1 = __riscv_vle32_v_u32m1((src2) + vl1, vl1);   \
    vuint32m1_t temp_src2_2 = __riscv_vle32_v_u32m1((src2) + 2 * vl1, vl1); \
    vuint32m1_t temp_src2_3 = __riscv_vle32_v_u32m1((src2) + 3 * vl1, vl1); \
                                                                          \
    vuint32m1_t part0, part1, part2, part3;                               \
                                                                          \
    part0 = __riscv_vsub_vv_u32m1(temp_src2_0, temp_src1_0, vl1);         \
    __riscv_vse32_v_u32m1((result_ptr), part0, vl1);                      \
                                                                          \
    part1 = __riscv_vsub_vv_u32m1(temp_src2_1, temp_src1_1, vl1);         \
    __riscv_vse32_v_u32m1((result_ptr) + vl1, part1, vl1);                \
                                                                          \
    part2 = __riscv_vsub_vv_u32m1(temp_src2_2, temp_src1_2, vl1);         \
    __riscv_vse32_v_u32m1((result_ptr) + 2 * vl1, part2, vl1);            \
                                                                          \
    part3 = __riscv_vsub_vv_u32m1(temp_src2_3, temp_src1_3, vl1);         \
    __riscv_vse32_v_u32m1((result_ptr) + 3 * vl1, part3, vl1);            \
} while (0)

#define VRSUB_VX_U32M4_NO_GROUPING(result_ptr, src, scalar, vl)            \
do {                                                                       \
    size_t vl1 = (vl) / 4;                                                 \
    vuint32m1_t temp_src0 = __riscv_vle32_v_u32m1((src), vl1);             \
    vuint32m1_t temp_src1 = __riscv_vle32_v_u32m1((src) + vl1, vl1);       \
    vuint32m1_t temp_src2 = __riscv_vle32_v_u32m1((src) + 2 * vl1, vl1);   \
    vuint32m1_t temp_src3 = __riscv_vle32_v_u32m1((src) + 3 * vl1, vl1);   \
                                                                           \
    vuint32m1_t part0, part1, part2, part3;                                \
                                                                           \
    part0 = __riscv_vrsub_vx_u32m1(temp_src0, scalar, vl1);                \
    __riscv_vse32_v_u32m1((result_ptr), part0, vl1);                       \
                                                                           \
    part1 = __riscv_vrsub_vx_u32m1(temp_src1, scalar, vl1);                \
    __riscv_vse32_v_u32m1((result_ptr) + vl1, part1, vl1);                 \
                                                                           \
    part2 = __riscv_vrsub_vx_u32m1(temp_src2, scalar, vl1);                \
    __riscv_vse32_v_u32m1((result_ptr) + 2 * vl1, part2, vl1);             \
                                                                           \
    part3 = __riscv_vrsub_vx_u32m1(temp_src3, scalar, vl1);                \
    __riscv_vse32_v_u32m1((result_ptr) + 3 * vl1, part3, vl1);             \
} while (0)

#define VCOMPRESS_VM_U32M4_NO_GROUPING(result_ptr, src, mask, vl)            \
do {                                                                         \
    size_t vl1 = (vl) / 4;                                                   \
    vuint32m1_t temp_src0 = __riscv_vle32_v_u32m1((src), vl1);               \
    vuint32m1_t temp_src1 = __riscv_vle32_v_u32m1((src) + vl1, vl1);         \
    vuint32m1_t temp_src2 = __riscv_vle32_v_u32m1((src) + 2 * vl1, vl1);     \
    vuint32m1_t temp_src3 = __riscv_vle32_v_u32m1((src) + 3 * vl1, vl1);     \
                                                                             \
    vbool32_t temp_mask0 = __riscv_vlm_v_b32(mask, vl1);                     \
    vbool32_t temp_mask1 = __riscv_vlm_v_b32(mask + vl1, vl1);               \
    vbool32_t temp_mask2 = __riscv_vlm_v_b32(mask + 2 * vl1, vl1);           \
    vbool32_t temp_mask3 = __riscv_vlm_v_b32(mask + 3 * vl1, vl1);           \
                                                                             \
    vuint32m1_t part0, part1, part2, part3;                                  \
                                                                             \
    part0 = __riscv_vcompress_vm_u32m1_tu(temp_src0, temp_src0, temp_mask0, vl1);          \
    __riscv_vse32_v_u32m1((result_ptr), part0, vl1);                         \
                                                                             \
    part1 = __riscv_vcompress_vm_u32m1_tu(temp_src1, temp_src1, temp_mask1, vl1);          \
    __riscv_vse32_v_u32m1((result_ptr) + vl1, part1, vl1);                   \
                                                                             \
    part2 = __riscv_vcompress_vm_u32m1_tu(temp_src2, temp_src2, temp_mask2, vl1);          \
    __riscv_vse32_v_u32m1((result_ptr) + 2 * vl1, part2, vl1);               \
                                                                             \
    part3 = __riscv_vcompress_vm_u32m1_tu(temp_src3, temp_src3, temp_mask3, vl1);          \
    __riscv_vse32_v_u32m1((result_ptr) + 3 * vl1, part3, vl1);               \
} while (0)

#define VSE32_V_U32M4_NO_GROUPING(base_ptr, src, vl)                   \
do {                                                                   \
    size_t vl1 = (vl) / 4;                                             \
    vuint32m1_t temp_src0 = __riscv_vle32_v_u32m1((src), vl1);         \
    vuint32m1_t temp_src1 = __riscv_vle32_v_u32m1((src) + vl1, vl1);   \
    vuint32m1_t temp_src2 = __riscv_vle32_v_u32m1((src) + 2 * vl1, vl1); \
    vuint32m1_t temp_src3 = __riscv_vle32_v_u32m1((src) + 3 * vl1, vl1); \
                                                                       \
    __riscv_vse32_v_u32m1((base_ptr), temp_src0, vl1);                 \
    __riscv_vse32_v_u32m1((base_ptr) + vl1, temp_src1, vl1);           \
    __riscv_vse32_v_u32m1((base_ptr) + 2 * vl1, temp_src2, vl1);       \
    __riscv_vse32_v_u32m1((base_ptr) + 3 * vl1, temp_src3, vl1);       \
} while (0)
