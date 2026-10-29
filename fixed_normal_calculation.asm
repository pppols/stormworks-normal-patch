# corrected normal calculation
# intercepts the broken transformations for non orthonormal matrices and trampolines them here

.intel_syntax noprefix
.text
.global normal_hook_a1
.global normal_hook_a2
.global normal_hook_b1
.global normal_hook_b2
.global normal_hook_face
.global normal_hook_virtual
.global normal_calculation


# adapter stack layout:
# +0x00: xmm0
# +0x10: xmm1
# +0x20: xmm2
# +0x30: xmm3
# +0x40: r8

normal_hook_a1:
  # hook entry signature
  .long 0x111111E8 # little endian

  # preserve necessary registers
  sub rsp, 0x48 # allocate 72 bytes on stack

  movdqu [rsp+0x00], xmm0
  movdqu [rsp+0x10], xmm1
  movdqu [rsp+0x20], xmm2
  movdqu [rsp+0x30], xmm3
  mov [rsp+0x40], r8

  pushfq

  # input calculation arguments
  movss xmm0, dword ptr [rcx+0x10]
  movss xmm1, dword ptr [rcx+0x14]
  movss xmm2, dword ptr [rcx+0x18]
  lea r8, [rbp+0x40]

  # calculation
  call normal_calculation

  # move calculation results
  movss xmm15, xmm0
  movss xmm14, xmm1
  movss xmm13, xmm2

  # restore registers
  popfq

  movdqu xmm0, [rsp+0x00]
  movdqu xmm1, [rsp+0x10]
  movdqu xmm2, [rsp+0x20]
  movdqu xmm3, [rsp+0x30]
  mov r8, [rsp+0x40]

  add rsp, 0x48 # free stack allocation

  xor r9d, r9d # trampoline skips this instruction

  # hook return signature and placeholder
  .byte 0xE9
  .long 0x11111111

normal_hook_a2:
  # hook entry signature
  .long 0x222222E8 # little endian

  # preserve necessary registers
  sub rsp, 0x48 # allocate 72 bytes on stack

  movdqu [rsp+0x00], xmm0
  movdqu [rsp+0x10], xmm1
  movdqu [rsp+0x20], xmm2
  movdqu [rsp+0x30], xmm3
  mov [rsp+0x40], r8

  pushfq

  # input calculation arguments
  movss xmm0, dword ptr [rcx+0x10]
  movss xmm1, dword ptr [rcx+0x14]
  movss xmm2, dword ptr [rcx+0x18]
  mov r8, rbp

  # calculation
  call normal_calculation

  # move calculation results
  movss xmm15, xmm0
  movss xmm14, xmm1
  movss xmm13, xmm2

  # restore registers
  popfq

  movdqu xmm0, [rsp+0x00]
  movdqu xmm1, [rsp+0x10]
  movdqu xmm2, [rsp+0x20]
  movdqu xmm3, [rsp+0x30]
  mov r8, [rsp+0x40]

  add rsp, 0x48 # free stack allocation

  # hook return signature and placeholder
  .byte 0xE9
  .long 0x22222222

normal_hook_b1:
  # hook entry signature
  .long 0x333333E8 # little endian

  # preserve necessary registers
  sub rsp, 0x48 # allocate 72 bytes on stack

  movdqu [rsp+0x00], xmm0
  movdqu [rsp+0x10], xmm1
  movdqu [rsp+0x20], xmm2
  movdqu [rsp+0x30], xmm3
  mov [rsp+0x40], r8

  pushfq

  # input calculation arguments
  movss xmm0, dword ptr [rcx+0x10]
  movss xmm1, dword ptr [rcx+0x14]
  movss xmm2, dword ptr [rcx+0x18]
  lea r8, [rbp+0x40]

  # calculation
  call normal_calculation

  # move calculation results
  movss xmm4, xmm0
  movss xmm6, xmm1
  movss xmm5, xmm2

  # restore registers
  popfq

  movdqu xmm0, [rsp+0x00]
  movdqu xmm1, [rsp+0x10]
  movdqu xmm2, [rsp+0x20]
  movdqu xmm3, [rsp+0x30]
  mov r8, [rsp+0x40]

  add rsp, 0x48 # free stack allocation

  movss xmm7, dword ptr [rip+constant] # replacing the original constant lookup off RIP, moving the constant to the assembly here instead
  xor r9d, r9d # trampoline skips these instructions

  # hook return signature and placeholder
  .byte 0xE9
  .long 0x33333333

normal_hook_b2:
  # hook entry signature
  .long 0x444444E8 # little endian

  # preserve necessary registers
  sub rsp, 0x48 # allocate 72 bytes on stack

  movdqu [rsp+0x00], xmm0
  movdqu [rsp+0x10], xmm1
  movdqu [rsp+0x20], xmm2
  movdqu [rsp+0x30], xmm3
  mov [rsp+0x40], r8

  pushfq

  # input calculation arguments
  movss xmm0, dword ptr [rcx+0x10]
  movss xmm1, dword ptr [rcx+0x14]
  movss xmm2, dword ptr [rcx+0x18]
  mov r8, rbp

  # calculation
  call normal_calculation

  # move calculation results
  movss xmm4, xmm0
  movss xmm6, xmm1
  movss xmm5, xmm2

  # restore registers
  popfq

  movdqu xmm0, [rsp+0x00]
  movdqu xmm1, [rsp+0x10]
  movdqu xmm2, [rsp+0x20]
  movdqu xmm3, [rsp+0x30]
  mov r8, [rsp+0x40]

  add rsp, 0x48 # free stack allocation

  # hook return signature and placeholder
  .byte 0xE9
  .long 0x44444444

normal_hook_face:
  # hook entry signature
  .long 0x555555E8 # little endian

  # preserve necessary registers
  sub rsp, 0x48 # allocate 72 bytes on stack

  movdqu [rsp+0x00], xmm0
  movdqu [rsp+0x10], xmm1
  movdqu [rsp+0x20], xmm2
  movdqu [rsp+0x30], xmm3
  mov [rsp+0x40], r8

  pushfq

  # input calculation arguments
  movss xmm0, xmm2
  movss xmm1, xmm3
  movss xmm2, xmm4
  mov r8, rbp

  # calculation
  call normal_calculation

  # move calculation results
  movss xmm10, xmm0
  movss xmm9, xmm1
  movss xmm8, xmm2

  # restore registers
  popfq

  movdqu xmm0, [rsp+0x00]
  movdqu xmm1, [rsp+0x10]
  movdqu xmm2, [rsp+0x20]
  movdqu xmm3, [rsp+0x30]
  mov r8, [rsp+0x40]

  add rsp, 0x48 # free stack allocation

  # hook return signature and placeholder
  .byte 0xE9
  .long 0x55555555

normal_hook_virtual:
  # hook entry signature
  .long 0x666666E8 # little endian

  # preserve necessary registers
  sub rsp, 0x48 # allocate 72 bytes on stack

  movdqu [rsp+0x00], xmm0
  movdqu [rsp+0x10], xmm1
  movdqu [rsp+0x20], xmm2
  movdqu [rsp+0x30], xmm3
  mov [rsp+0x40], r8

  pushfq

  # input calculation arguments
  movss xmm0, dword ptr [rcx+r9+0x10] # object oriented
  movss xmm1, dword ptr [rcx+r9+0x14]
  movss xmm2, dword ptr [rcx+r9+0x18]
  mov r8, r11

  # calculation
  call normal_calculation

  # write calculation results
  movss dword ptr [r10+0x10], xmm0
  movss dword ptr [r10+0x14], xmm1
  movss dword ptr [r10+0x18], xmm2

  # restore registers
  popfq

  movdqu xmm0, [rsp+0x00]
  movdqu xmm1, [rsp+0x10]
  movdqu xmm2, [rsp+0x20]
  movdqu xmm3, [rsp+0x30]
  mov r8, [rsp+0x40]

  add rsp, 0x48 # free stack allocation

  # hook return signature and placeholder
  .byte 0xE9
  .long 0x66666666


normal_calculation:
  # function arguments register layout:
  # xmm0: input / output normal x
  # xmm1: input / output normal y
  # xmm2: input / output normal z
  # r8: transformation matrix address

  # function stack layout:
  # +0x00 to +0x0B: input normal components
  # +0x0C to +0x17: unnormalized normal components
  # +0x18 to +0x3B: cofactor matrix
  # +0x3C to +0x3F: determinant sign

  # allocate stack space
  sub rsp, 0x40

  # store normal floats
  movss dword ptr [rsp+0x00], xmm0
  movss dword ptr [rsp+0x04], xmm1
  movss dword ptr [rsp+0x08], xmm2



  # the upper left 3x3 submatrix of interest:
  # a, b, c   [r8 + 0x00], [r8 + 0x04], [r8 + 0x08]
  # d, e, f   [r8 + 0x10], [r8 + 0x14], [r8 + 0x18]
  # g, h, i   [r8 + 0x20], [r8 + 0x24], [r8 + 0x28]

  # calculating the resulting 3x3 cofactor matrix:
  # C00, C01, C02   [rsp + 0x18], [rsp + 0x1C], [rsp + 0x20]
  # C10, C11, C12   [rsp + 0x24], [rsp + 0x28], [rsp + 0x2C]
  # C20, C21, C22   [rsp + 0x30], [rsp + 0x34], [rsp + 0x38]

  # first cofactor 
  # C00 = e*i - f*h
  movss xmm0, dword ptr [r8+0x14] # e
  mulss xmm0, dword ptr [r8+0x28] # e*i
  movss xmm1, dword ptr [r8+0x18] # f
  mulss xmm1, dword ptr [r8+0x24] # f*h
  subss xmm0, xmm1 # e*i - f*h
  movss dword ptr [rsp+0x18], xmm0 # store C00

  # second cofactor
  # C01 = f*g - d*i
  movss xmm0, dword ptr [r8+0x18] # f
  mulss xmm0, dword ptr [r8+0x20] # f*g
  movss xmm1, dword ptr [r8+0x10] # d
  mulss xmm1, dword ptr [r8+0x28] # d*i
  subss xmm0, xmm1 # f*g - d*i
  movss dword ptr [rsp+0x1C], xmm0 # store C01

  # third cofactor
  # C02 = d*h - e*g
  movss xmm0, dword ptr [r8+0x10] # d
  mulss xmm0, dword ptr [r8+0x24] # d*h
  movss xmm1, dword ptr [r8+0x14] # e
  mulss xmm1, dword ptr [r8+0x20] # e*g
  subss xmm0, xmm1 # d*h - e*g
  movss dword ptr [rsp+0x20], xmm0 # store C02

  # fourth cofactor
  # C10 = c*h - b*i
  movss xmm0, dword ptr [r8+0x08] # c
  mulss xmm0, dword ptr [r8+0x24] # c*h
  movss xmm1, dword ptr [r8+0x04] # b
  mulss xmm1, dword ptr [r8+0x28] # b*i
  subss xmm0, xmm1 # c*h - b*i
  movss dword ptr [rsp+0x24], xmm0 # store C10

  # fifth cofactor
  # C11 = a*i - c*g
  movss xmm0, dword ptr [r8+0x00] # a
  mulss xmm0, dword ptr [r8+0x28] # a*i
  movss xmm1, dword ptr [r8+0x08] # c
  mulss xmm1, dword ptr [r8+0x20] # c*g
  subss xmm0, xmm1 # a*i - c*g
  movss dword ptr [rsp+0x28], xmm0 # store C11

  # sixth cofactor
  # C12 = b*g - a*h
  movss xmm0, dword ptr [r8+0x04] # b
  mulss xmm0, dword ptr [r8+0x20] # b*g
  movss xmm1, dword ptr [r8+0x00] # a
  mulss xmm1, dword ptr [r8+0x24] # a*h
  subss xmm0, xmm1 # b*g - a*h
  movss dword ptr [rsp+0x2C], xmm0 # store C12

  # seventh cofactor
  # C20 = b*f - c*e
  movss xmm0, dword ptr [r8+0x04] # b
  mulss xmm0, dword ptr [r8+0x18] # b*f
  movss xmm1, dword ptr [r8+0x08] # c
  mulss xmm1, dword ptr [r8+0x14] # c*e
  subss xmm0, xmm1 # b*f - c*e
  movss dword ptr [rsp+0x30], xmm0 # store C20

  # eighth cofactor
  # C21 = c*d - a*f
  movss xmm0, dword ptr [r8+0x08] # c
  mulss xmm0, dword ptr [r8+0x10] # c*d
  movss xmm1, dword ptr [r8+0x00] # a
  mulss xmm1, dword ptr [r8+0x18] # a*f
  subss xmm0, xmm1 # c*d - a*f
  movss dword ptr [rsp+0x34], xmm0 # store C21

  # ninth cofactor
  # C22 = a*e - b*d
  movss xmm0, dword ptr [r8+0x00] # a
  mulss xmm0, dword ptr [r8+0x14] # a*e
  movss xmm1, dword ptr [r8+0x04] # b
  mulss xmm1, dword ptr [r8+0x10] # b*d
  subss xmm0, xmm1 # a*e - b*d
  movss dword ptr [rsp+0x38], xmm0 # store C22



  # calculating determinant
  # det(M) = a*C00 + b*C01 + c*C02
  movss xmm2, dword ptr [r8+0x00] # a
  mulss xmm2, dword ptr [rsp+0x18] # a*C00

  movss xmm1, dword ptr [r8+0x04] # b
  mulss xmm1, dword ptr [rsp+0x1C] # b*C01
  addss xmm2, xmm1 # a*C00 + b*C01

  movss xmm1, dword ptr [r8+0x08] # c
  mulss xmm1, dword ptr [rsp+0x20] # c*C02
  addss xmm2, xmm1 # det(M)



  # get and store sign of the determinant
  xorps xmm3, xmm3 # zero the register
  ucomiss xmm2, xmm3 # compare det(M) with zero
  jae normal_sign_positive # jump if positive

  mov dword ptr [rsp+0x3C], 0xBF800000 # -1.0f
  jmp normal_sign_done

normal_sign_positive:
  mov dword ptr [rsp+0x3C], 0x3F800000 # +1.0f

normal_sign_done:



  # correctly transforming the normal

  # the normal is now stored in the stack,
  # nx = [rsp + 0x00]
  # ny = [rsp + 0x04]
  # nz = [rsp + 0x08]

  # calculating the unnormalized x component
  # ux = C00*nx + C10*ny + C20*nz
  movss xmm0, dword ptr [rsp+0x18] # C00
  mulss xmm0, dword ptr [rsp+0x00] # C00*nx

  movss xmm1, dword ptr [rsp+0x24] # C10
  mulss xmm1, dword ptr [rsp+0x04] # C10*ny
  addss xmm0, xmm1 # C00*nx + C10*ny

  movss xmm1, dword ptr [rsp+0x30] # C20
  mulss xmm1, dword ptr [rsp+0x08] # C20*nz
  addss xmm0, xmm1 # C00*nx + C10*ny + C20*nz

  movss dword ptr [rsp+0x0C], xmm0 # storing unnormalized ux

  # calculating the unnormalized y component
  # uy = C01*nx + C11*ny + C21*nz
  movss xmm0, dword ptr [rsp+0x1C] # C01
  mulss xmm0, dword ptr [rsp+0x00] # C01*nx

  movss xmm1, dword ptr [rsp+0x28] # C11
  mulss xmm1, dword ptr [rsp+0x04] # C11*ny
  addss xmm0, xmm1 # C01*nx + C11*ny

  movss xmm1, dword ptr [rsp+0x34] # C21
  mulss xmm1, dword ptr [rsp+0x08] # C21*nz
  addss xmm0, xmm1 # C01*nx + C11*ny + C21*nz

  movss dword ptr [rsp+0x10], xmm0 # storing unnormalized uy

  # calculating the unnormalized z component
  # uz = C02*nx + C12*ny + C22*nz
  movss xmm0, dword ptr [rsp+0x20] # C02
  mulss xmm0, dword ptr [rsp+0x00] # C02*nx

  movss xmm1, dword ptr [rsp+0x2C] # C12
  mulss xmm1, dword ptr [rsp+0x04] # C12*ny
  addss xmm0, xmm1 # C02*nx + C12*ny

  movss xmm1, dword ptr [rsp+0x38] # C22
  mulss xmm1, dword ptr [rsp+0x08] # C22*nz
  addss xmm0, xmm1 # C02*nx + C12*ny + C22*nz

  movss dword ptr [rsp+0x14], xmm0 # storing the unnormalized uz



  # normalizing the result
  # in degenerate cases, give a zero normal

  # magnitude^2 = ux^2 + uy^2 + uz^2
  movss xmm0, dword ptr [rsp+0x0C] # ux
  mulss xmm0, xmm0 # ux^2

  movss xmm1, dword ptr [rsp+0x10] # uy
  mulss xmm1, xmm1 # uy^2
  addss xmm0, xmm1 # ux^2 + uy^2

  movss xmm1, dword ptr [rsp+0x14] # uz
  mulss xmm1, xmm1 # uz^2
  addss xmm0, xmm1 # magnitude^2


  # check for degenerate case
  xorps xmm1, xmm1 # zero the register
  ucomiss xmm0, xmm1 # compare squared l2 norm with zero
  jbe zero_normal # enter edge case if zero or less


  # calculate normalization coefficient
  # reciprocal of the magnitude, inversely signed when mirrored
  sqrtss xmm0, xmm0 # get standard l2 norm from the square

  movss xmm3, dword ptr [rsp+0x3C] # determinant sign
  divss xmm3, xmm0 # sign(det) / magnitude

  # multiply with normalization coefficient
  # moving to necessary output registers at the same time
  movss xmm0, dword ptr [rsp+0x0C] # ux
  mulss xmm0, xmm3 # corrected normal x component

  movss xmm1, dword ptr [rsp+0x10] # uy
  mulss xmm1, xmm3 # corrected normal y component

  movss xmm2, dword ptr [rsp+0x14] # uz
  mulss xmm2, xmm3 # corrected normal z component

  jmp normal_done


  # degenerate case, give a zero normal
zero_normal:
  xorps xmm0, xmm0
  xorps xmm1, xmm1
  xorps xmm2, xmm2

normal_done:



  # release stack space
  add rsp, 0x40



  # return to adapter
  ret


# constant lookup
constant:
  .long 0x3E800000 # +0.25f
