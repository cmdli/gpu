Very basic multicore processor in verilog

Instruction spec:

    0000 iiii iiii tttt     mov i rt - regs[rt] = i
    0001 aaaa bbbb tttt     add ra rb rt - regs[rt] = regs[ra] + regs[rb]
    0010 jjjj jjjj jjjj     jmp j - pc = j
    0011 xxxx xxxx xxxx     halt - halts
    0100 iiii iiii tttt     ld mi rt - regs[rt] = mem[mi]
    0101 aaaa bbbb tttt     ldr ra rb rt - regs[rt] = mem[regs[ra]+regs[rb]]
    0110 aaaa bbbb dddd     jeq ra rb d - if regs[ra]==regs[rb] pc += d
    0111 aaaa bbbb dddd     jlt ra rb d - if regs[ra]<regs[rb] pc += d
    1000 aaaa bbbb dddd     jgt ra rb d - if regs[ra]>regs[rb] pc += d
    1001 xxxx xxxx xxxx     nop - takes one cycle to do nothing
    1010 jjjj jjjj jjjj     sync j - adds the core group to sync group j
    1011 aaaa ssss ssss     spawn a s - enables core a and sets the pc to s
    1100 aaaa ssss ssss     st ra ms - mem[ms] = regs[ra]
