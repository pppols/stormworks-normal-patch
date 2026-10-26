# corrected normal calculation patch
# intercepts the broken transformation application for non orthonormal matrices and trampolines it here

.intel_syntax noprefix
.text
.global normal_fix

normal_fix:

  # memory layout begins with,

  # RCX, pointer to source vertex, a 28 byte stride structure:
  # +0x00: x position (float)
  # +0x04: y position (float)
  # +0x08: z position (float)
  # +0x0C: i didnt check lmao
  # +0x10: normal x (float)
  # +0x14: normal y (float)
  # +0x18: normal z (float)

  # RBP, pointer to the 4x4 float model transformation matrix, a contiguous 64 byte structure

  # RBX, pointer to the destination vertex, the same 28 byte stride structure



  # preserve status flag register
  pushfq

  # reserve 144 bytes of stack space and preserve original xmm registers
  sub rsp, 0x90
  movdqu xmmword ptr [rsp+0x40], xmm0
  movdqu xmmword ptr [rsp+0x50], xmm1
  movdqu xmmword ptr [rsp+0x60], xmm2
  movdqu xmmword ptr [rsp+0x70], xmm3

  # the stack layout used will be:
  # +0x00 to +0x23: cofactor terms
  # +0x30: determinant sign
  # +0x34 to +0x3F: unnormalized normal components
  # +0x40 to +0x4F: xmm0
  # +0x50 to +0x5F: xmm1
  # +0x60 to +0x6F: xmm2
  # +0x70 to +0x7F: xmm3

  # the correctly transformed output will be stored with x, y, z in xmm4, xmm6, xmm5 respectively (note the order!)
  # these are moved to the destination RBX vertex structure outside of this trampoline



  # the upper left 3x3 submatrix of interest:
  # a, b, c   [rbp + 0], [rbp + 4], [rbp + 8]
  # d, e, f   [rbp + 16], [rbp + 20], [rbp + 24]
  # g, h, i   [rbp + 32], [rbp + 36], [rbp + 40]

  # calculating the resulting 3x3 cofactor matrix:
  # C00, C01, C02   [rsp + 0], [rsp + 4], [rsp + 8]
  # C10, C11, C12   [rsp + 12], [rsp + 16], [rsp + 20]
  # C20, C21, C22   [rsp + 24], [rsp + 28], [rsp + 32]

  # first cofactor 
  # C00 = e*i - f*h
  movss xmm0, dword ptr [rbp+20] # e
  mulss xmm0, dword ptr [rbp+40] # e*i
  movss xmm1, dword ptr [rbp+24] # f
  mulss xmm1, dword ptr [rbp+36] # f*h
  subss xmm0, xmm1 # e*i - f*h
  movss dword ptr [rsp+0], xmm0 # store C00

  # second cofactor
  # C01 = f*g - d*i
  movss xmm0, dword ptr [rbp+24] # f
  mulss xmm0, dword ptr [rbp+32] # f*g
  movss xmm1, dword ptr [rbp+16] # d
  mulss xmm1, dword ptr [rbp+40] # d*i
  subss xmm0, xmm1 # f*g - d*i
  movss dword ptr [rsp+4], xmm0 # store C01

  # third cofactor
  # C02 = d*h - e*g
  movss xmm0, dword ptr [rbp+16] # d
  mulss xmm0, dword ptr [rbp+36] # d*h
  movss xmm1, dword ptr [rbp+20] # e
  mulss xmm1, dword ptr [rbp+32] # e*g
  subss xmm0, xmm1 # d*h - e*g
  movss dword ptr [rsp+8], xmm0 # store C02

  # fourth cofactor
  # C10 = c*h - b*i
  movss xmm0, dword ptr [rbp+8] # c
  mulss xmm0, dword ptr [rbp+36] # c*h
  movss xmm1, dword ptr [rbp+4] # b
  mulss xmm1, dword ptr [rbp+40] # b*i
  subss xmm0, xmm1 # c*h - b*i
  movss dword ptr [rsp+12], xmm0 # store C10

  # fifth cofactor
  # C11 = a*i - c*g
  movss xmm0, dword ptr [rbp+0] # a
  mulss xmm0, dword ptr [rbp+40] # a*i
  movss xmm1, dword ptr [rbp+8] # c
  mulss xmm1, dword ptr [rbp+32] # c*g
  subss xmm0, xmm1 # a*i - c*g
  movss dword ptr [rsp+16], xmm0 # store C11

  # sixth cofactor
  # C12 = b*g - a*h
  movss xmm0, dword ptr [rbp+4] # b
  mulss xmm0, dword ptr [rbp+32] # b*g
  movss xmm1, dword ptr [rbp+0] # a
  mulss xmm1, dword ptr [rbp+36] # a*h
  subss xmm0, xmm1 # b*g - a*h
  movss dword ptr [rsp+20], xmm0 # store C12

  # seventh cofactor
  # C20 = b*f - c*e
  movss xmm0, dword ptr [rbp+4] # b
  mulss xmm0, dword ptr [rbp+24] # b*f
  movss xmm1, dword ptr [rbp+8] # c
  mulss xmm1, dword ptr [rbp+20] # c*e
  subss xmm0, xmm1 # b*f - c*e
  movss dword ptr [rsp+24], xmm0 # store C20

  # eighth cofactor
  # C21 = c*d - a*f
  movss xmm0, dword ptr [rbp+8] # c
  mulss xmm0, dword ptr [rbp+16] # c*d
  movss xmm1, dword ptr [rbp+0] # a
  mulss xmm1, dword ptr [rbp+24] # a*f
  subss xmm0, xmm1 # c*d - a*f
  movss dword ptr [rsp+28], xmm0 # store C21

  # ninth cofactor
  # C22 = a*e - b*d
  movss xmm0, dword ptr [rbp+0] # a
  mulss xmm0, dword ptr [rbp+20] # a*e
  movss xmm1, dword ptr [rbp+4] # b
  mulss xmm1, dword ptr [rbp+16] # b*d
  subss xmm0, xmm1 # a*e - b*d
  movss dword ptr [rsp+32], xmm0 # store C22



  # calculating determinant
  # det(M) = a*C00 + b*C01 + c*C02
  movss xmm2, dword ptr [rbp+0] # a
  mulss xmm2, dword ptr [rsp+0] # a*C00

  movss xmm0, dword ptr [rbp+4] # b
  mulss xmm0, dword ptr [rsp+4] # b*C01
  addss xmm2, xmm0 # a*C00 + b*C01

  movss xmm0, dword ptr [rbp+8] # c
  mulss xmm0, dword ptr [rsp+8] # c*C02
  addss xmm2, xmm0 # det(M)



  # get and store sign of the determinant
  xorps xmm3, xmm3 # zero the register
  ucomiss xmm2, xmm3 # compare det(M) with zero
  jae normal_sign_positive # jump if positive

  mov dword ptr [rsp+0x30], 0xBF800000 # -1.0 float
  jmp normal_sign_done

normal_sign_positive:
  mov dword ptr [rsp+0x30], 0x3F800000 # +1.0 float

normal_sign_done:



  # correctly transforming the normal

  # the normal is stored in the source vertex structure,
  # nx = [rcx + 0x10]
  # ny = [rcx + 0x14]
  # nz = [rcx + 0x18]

  # calculating the unnormalized x component
  # ux = C00*nx + C10*ny + C20*nz
  movss xmm0, dword ptr [rsp+0] # C00
  mulss xmm0, dword ptr [rcx+0x10] # C00*nx

  movss xmm1, dword ptr [rsp+12] # C10
  mulss xmm1, dword ptr [rcx+0x14] # C10*ny
  addss xmm0, xmm1 # C00*nx + C10*ny

  movss xmm1, dword ptr [rsp+24] # C20
  mulss xmm1, dword ptr [rcx+0x18] # C20*nz
  addss xmm0, xmm1 # C00*nx + C10*ny + C20*nz

  movss dword ptr [rsp+52], xmm0 # storing unnormalized ux

  # calculating the unnormalized y component
  # uy = C01*nx + C11*ny + C21*nz
  movss xmm0, dword ptr [rsp+4] # C01
  mulss xmm0, dword ptr [rcx+0x10] # C01*nx

  movss xmm1, dword ptr [rsp+16] # C11
  mulss xmm1, dword ptr [rcx+0x14] # C11*ny
  addss xmm0, xmm1 # C01*nx + C11*ny

  movss xmm1, dword ptr [rsp+28] # C21
  mulss xmm1, dword ptr [rcx+0x18] # C21*nz
  addss xmm0, xmm1 # C01*nx + C11*ny + C21*nz

  movss dword ptr [rsp+56], xmm0 # storing unnormalized uy

  # calculating the unnormalized z component
  # uz = C02*nx + C12*ny + C22*nz
  movss xmm0, dword ptr [rsp+8] # C02
  mulss xmm0, dword ptr [rcx+0x10] # C02*nx

  movss xmm1, dword ptr [rsp+20] # C12
  mulss xmm1, dword ptr [rcx+0x14] # C12*ny
  addss xmm0, xmm1 # C02*nx + C12*ny

  movss xmm1, dword ptr [rsp+32] # C22
  mulss xmm1, dword ptr [rcx+0x18] # C22*nz
  addss xmm0, xmm1 # C02*nx + C12*ny + C22*nz

  movss dword ptr [rsp+60], xmm0 # storing the unnormalized uz



  # normalizing the result
  # in degenerate cases, give a zero normal

  # magnitude^2 = ux^2 + uy^2 + uz^2
  movss xmm0, dword ptr [rsp+0x34] # ux
  mulss xmm0, xmm0 # ux^2

  movss xmm1, dword ptr [rsp+0x38] # uy
  mulss xmm1, xmm1 # uy^2
  addss xmm0, xmm1 # ux^2 + uy^2

  movss xmm1, dword ptr [rsp+0x3C] # uz
  mulss xmm1, xmm1 # uz^2
  addss xmm0, xmm1 # magnitude^2


  # check for degenerate case
  xorps xmm1, xmm1 # zero the register
  ucomiss xmm0, xmm1 # compare squared l2 norm with zero
  jbe zero_normal # enter edge case if zero or less


  # calculate normalization coefficient
  # reciprocal of the magnitude, inversely signed when mirrored
  sqrtss xmm0, xmm0 # get standard l2 norm from the square

  movss xmm1, dword ptr [rsp+0x30] # determinant sign
  divss xmm1, xmm0 # sign(det) / magnitude

  # multiply with normalization coefficient
  # moving to necessary output registers at the same time
  movss xmm4, dword ptr [rsp+52] # ux
  mulss xmm4, xmm1 # corrected normal x component

  movss xmm6, dword ptr [rsp+56] # uy
  mulss xmm6, xmm1 # corrected normal y component

  movss xmm5, dword ptr [rsp+60] # uz
  mulss xmm5, xmm1 # corrected normal z component

  jmp normal_done


  # degenerate case, give a zero normal
zero_normal:
  xorps xmm4, xmm4
  xorps xmm6, xmm6
  xorps xmm5, xmm5

normal_done:



  # returning to original register states
  # leaving transformed normal in xmm4, xmm6, xmm5
  # restoring xmm0, xmm1, xmm2, xmm3, stack pointer, and flag register
  movdqu xmm0, xmmword ptr [rsp+0x40]
  movdqu xmm1, xmmword ptr [rsp+0x50]
  movdqu xmm2, xmmword ptr [rsp+0x60]
  movdqu xmm3, xmmword ptr [rsp+0x70]

  add rsp, 0x90 # release stack space
  popfq # restore flag register



  # this is a placeholder relative jump
  # the patcher script replaces the placeholder with the necessary alternative when patching
  # keep this here, and keep it unique
normal_return_placeholder:
  .byte 0xE9
  .long 0x12345678
