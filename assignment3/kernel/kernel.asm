
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	18010113          	addi	sp,sp,384 # 8000a180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	fee70713          	addi	a4,a4,-18 # 8000a040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	a8c78793          	addi	a5,a5,-1396 # 80006af0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcf7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	0d4080e7          	jalr	212(ra) # 800021f2 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00012517          	auipc	a0,0x12
    80000180:	00450513          	addi	a0,a0,4 # 80012180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00012497          	auipc	s1,0x12
    80000190:	ff448493          	addi	s1,s1,-12 # 80012180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00012917          	auipc	s2,0x12
    80000198:	08490913          	addi	s2,s2,132 # 80012218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	822080e7          	jalr	-2014(ra) # 800019d4 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e34080e7          	jalr	-460(ra) # 80001ff6 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	f9e080e7          	jalr	-98(ra) # 8000219c <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00012517          	auipc	a0,0x12
    80000216:	f6e50513          	addi	a0,a0,-146 # 80012180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00012517          	auipc	a0,0x12
    8000022c:	f5850513          	addi	a0,a0,-168 # 80012180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00012717          	auipc	a4,0x12
    80000262:	faf72d23          	sw	a5,-70(a4) # 80012218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00012517          	auipc	a0,0x12
    800002bc:	ec850513          	addi	a0,a0,-312 # 80012180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	f6a080e7          	jalr	-150(ra) # 80002248 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00012517          	auipc	a0,0x12
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80012180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00012717          	auipc	a4,0x12
    8000030e:	e7670713          	addi	a4,a4,-394 # 80012180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00012797          	auipc	a5,0x12
    80000338:	e4c78793          	addi	a5,a5,-436 # 80012180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00012797          	auipc	a5,0x12
    80000366:	eb67a783          	lw	a5,-330(a5) # 80012218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00012717          	auipc	a4,0x12
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80012180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00012497          	auipc	s1,0x12
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80012180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00012717          	auipc	a4,0x12
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80012180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00012717          	auipc	a4,0x12
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80012220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00012797          	auipc	a5,0x12
    80000402:	d8278793          	addi	a5,a5,-638 # 80012180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00012797          	auipc	a5,0x12
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001221c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00012517          	auipc	a0,0x12
    8000042e:	dee50513          	addi	a0,a0,-530 # 80012218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	c28080e7          	jalr	-984(ra) # 8000205a <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00009597          	auipc	a1,0x9
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80009010 <etext+0x10>
    8000044c:	00012517          	auipc	a0,0x12
    80000450:	d3450513          	addi	a0,a0,-716 # 80012180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	0002a797          	auipc	a5,0x2a
    80000468:	2b478793          	addi	a5,a5,692 # 8002a718 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00009617          	auipc	a2,0x9
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80009040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00012797          	auipc	a5,0x12
    8000053a:	d007a523          	sw	zero,-758(a5) # 80012240 <pr+0x18>
  printf("panic: ");
    8000053e:	00009517          	auipc	a0,0x9
    80000542:	ada50513          	addi	a0,a0,-1318 # 80009018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00009517          	auipc	a0,0x9
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800090c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	0000a717          	auipc	a4,0xa
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 8000a000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00012d97          	auipc	s11,0x12
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80012240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00009b17          	auipc	s6,0x9
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80009040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00012517          	auipc	a0,0x12
    800005e8:	c4450513          	addi	a0,a0,-956 # 80012228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00009517          	auipc	a0,0x9
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80009028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00009497          	auipc	s1,0x9
    800006f4:	93048493          	addi	s1,s1,-1744 # 80009020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00012517          	auipc	a0,0x12
    80000746:	ae650513          	addi	a0,a0,-1306 # 80012228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00012497          	auipc	s1,0x12
    80000762:	aca48493          	addi	s1,s1,-1334 # 80012228 <pr>
    80000766:	00009597          	auipc	a1,0x9
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80009038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00009597          	auipc	a1,0x9
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80009058 <digits+0x18>
    800007be:	00012517          	auipc	a0,0x12
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80012248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	0000a797          	auipc	a5,0xa
    800007ee:	8167a783          	lw	a5,-2026(a5) # 8000a000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00009797          	auipc	a5,0x9
    80000826:	7e67b783          	ld	a5,2022(a5) # 8000a008 <uart_tx_r>
    8000082a:	00009717          	auipc	a4,0x9
    8000082e:	7e673703          	ld	a4,2022(a4) # 8000a010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00012a17          	auipc	s4,0x12
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80012248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00009497          	auipc	s1,0x9
    80000858:	7b448493          	addi	s1,s1,1972 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00009997          	auipc	s3,0x9
    80000860:	7b498993          	addi	s3,s3,1972 # 8000a010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00001097          	auipc	ra,0x1
    80000882:	7dc080e7          	jalr	2012(ra) # 8000205a <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00012517          	auipc	a0,0x12
    800008be:	98e50513          	addi	a0,a0,-1650 # 80012248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00009797          	auipc	a5,0x9
    800008ce:	7367a783          	lw	a5,1846(a5) # 8000a000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00009717          	auipc	a4,0x9
    800008da:	73a73703          	ld	a4,1850(a4) # 8000a010 <uart_tx_w>
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	72a7b783          	ld	a5,1834(a5) # 8000a008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00012997          	auipc	s3,0x12
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80012248 <uart_tx_lock>
    800008f6:	00009497          	auipc	s1,0x9
    800008fa:	71248493          	addi	s1,s1,1810 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00009917          	auipc	s2,0x9
    80000902:	71290913          	addi	s2,s2,1810 # 8000a010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	6ec080e7          	jalr	1772(ra) # 80001ff6 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00012497          	auipc	s1,0x12
    80000924:	92848493          	addi	s1,s1,-1752 # 80012248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00009797          	auipc	a5,0x9
    80000938:	6ce7be23          	sd	a4,1756(a5) # 8000a010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00012497          	auipc	s1,0x12
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80012248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	0002e797          	auipc	a5,0x2e
    800009ee:	61678793          	addi	a5,a5,1558 # 8002f000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00012917          	auipc	s2,0x12
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80012280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00008517          	auipc	a0,0x8
    80000a40:	62450513          	addi	a0,a0,1572 # 80009060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00008597          	auipc	a1,0x8
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80009068 <digits+0x28>
    80000aa6:	00011517          	auipc	a0,0x11
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80012280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	0002e517          	auipc	a0,0x2e
    80000abe:	54650513          	addi	a0,a0,1350 # 8002f000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00011497          	auipc	s1,0x11
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80012280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	78c50513          	addi	a0,a0,1932 # 80012280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00011517          	auipc	a0,0x11
    80000b24:	76050513          	addi	a0,a0,1888 # 80012280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e5c080e7          	jalr	-420(ra) # 800019b8 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	e2a080e7          	jalr	-470(ra) # 800019b8 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e1e080e7          	jalr	-482(ra) # 800019b8 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	e06080e7          	jalr	-506(ra) # 800019b8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	dc6080e7          	jalr	-570(ra) # 800019b8 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00008517          	auipc	a0,0x8
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80009070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d9a080e7          	jalr	-614(ra) # 800019b8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00008517          	auipc	a0,0x8
    80000c5a:	42250513          	addi	a0,a0,1058 # 80009078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00008517          	auipc	a0,0x8
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80009090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00008517          	auipc	a0,0x8
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80009098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	b34080e7          	jalr	-1228(ra) # 800019a8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00009717          	auipc	a4,0x9
    80000e80:	19c70713          	addi	a4,a4,412 # 8000a018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	b18080e7          	jalr	-1256(ra) # 800019a8 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00008517          	auipc	a0,0x8
    80000e9e:	21e50513          	addi	a0,a0,542 # 800090b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	0e2080e7          	jalr	226(ra) # 80002f94 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	c76080e7          	jalr	-906(ra) # 80006b30 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	f82080e7          	jalr	-126(ra) # 80001e44 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00008517          	auipc	a0,0x8
    80000ede:	1ee50513          	addi	a0,a0,494 # 800090c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00008517          	auipc	a0,0x8
    80000eee:	1b650513          	addi	a0,a0,438 # 800090a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00008517          	auipc	a0,0x8
    80000efe:	1ce50513          	addi	a0,a0,462 # 800090c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	320080e7          	jalr	800(ra) # 80001232 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	9d6080e7          	jalr	-1578(ra) # 800018f8 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	042080e7          	jalr	66(ra) # 80002f6c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	062080e7          	jalr	98(ra) # 80002f94 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	be0080e7          	jalr	-1056(ra) # 80006b1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	bee080e7          	jalr	-1042(ra) # 80006b30 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	7c2080e7          	jalr	1986(ra) # 8000370c <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	e54080e7          	jalr	-428(ra) # 80003da6 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	114080e7          	jalr	276(ra) # 8000506e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	cf0080e7          	jalr	-784(ra) # 80006c52 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d42080e7          	jalr	-702(ra) # 80001cac <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00009717          	auipc	a4,0x9
    80000f7c:	0af72023          	sw	a5,160(a4) # 8000a018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00009797          	auipc	a5,0x9
    80000f8c:	0987b783          	ld	a5,152(a5) # 8000a020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00008517          	auipc	a0,0x8
    80000fd0:	10450513          	addi	a0,a0,260 # 800090d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	e062                	sd	s8,0(sp)
    800010a4:	0880                	addi	s0,sp,80
    800010a6:	8b2a                	mv	s6,a0
    800010a8:	8a3a                	mv	s4,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010aa:	777d                	lui	a4,0xfffff
    800010ac:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b0:	167d                	addi	a2,a2,-1
    800010b2:	00b609b3          	add	s3,a2,a1
    800010b6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ba:	893e                	mv	s2,a5
    800010bc:	40f68ab3          	sub	s5,a3,a5
      panic("remap");

    *pte = PA2PTE(pa) | perm;
    // ADDED Q1
    // PTE_V == 1 only when the page is located in the ram
    if(!(perm & PTE_PG)){
    800010c0:	200a7b93          	andi	s7,s4,512
      *pte = *pte | PTE_V;
    } 
    if(a == last)
      break;
    a += PGSIZE;
    800010c4:	6c05                	lui	s8,0x1
    800010c6:	a839                	j	800010e4 <mappages+0x56>
      panic("remap");
    800010c8:	00008517          	auipc	a0,0x8
    800010cc:	01050513          	addi	a0,a0,16 # 800090d8 <digits+0x98>
    800010d0:	fffff097          	auipc	ra,0xfffff
    800010d4:	45a080e7          	jalr	1114(ra) # 8000052a <panic>
      *pte = *pte | PTE_V;
    800010d8:	0014e493          	ori	s1,s1,1
    800010dc:	e104                	sd	s1,0(a0)
    if(a == last)
    800010de:	05390563          	beq	s2,s3,80001128 <mappages+0x9a>
    a += PGSIZE;
    800010e2:	9962                	add	s2,s2,s8
  for(;;){
    800010e4:	012a84b3          	add	s1,s5,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010e8:	4605                	li	a2,1
    800010ea:	85ca                	mv	a1,s2
    800010ec:	855a                	mv	a0,s6
    800010ee:	00000097          	auipc	ra,0x0
    800010f2:	eb8080e7          	jalr	-328(ra) # 80000fa6 <walk>
    800010f6:	cd01                	beqz	a0,8000110e <mappages+0x80>
    if(*pte & PTE_V)
    800010f8:	611c                	ld	a5,0(a0)
    800010fa:	8b85                	andi	a5,a5,1
    800010fc:	f7f1                	bnez	a5,800010c8 <mappages+0x3a>
    *pte = PA2PTE(pa) | perm;
    800010fe:	80b1                	srli	s1,s1,0xc
    80001100:	04aa                	slli	s1,s1,0xa
    80001102:	0144e4b3          	or	s1,s1,s4
    if(!(perm & PTE_PG)){
    80001106:	fc0b89e3          	beqz	s7,800010d8 <mappages+0x4a>
    *pte = PA2PTE(pa) | perm;
    8000110a:	e104                	sd	s1,0(a0)
    8000110c:	bfc9                	j	800010de <mappages+0x50>
      return -1;
    8000110e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001110:	60a6                	ld	ra,72(sp)
    80001112:	6406                	ld	s0,64(sp)
    80001114:	74e2                	ld	s1,56(sp)
    80001116:	7942                	ld	s2,48(sp)
    80001118:	79a2                	ld	s3,40(sp)
    8000111a:	7a02                	ld	s4,32(sp)
    8000111c:	6ae2                	ld	s5,24(sp)
    8000111e:	6b42                	ld	s6,16(sp)
    80001120:	6ba2                	ld	s7,8(sp)
    80001122:	6c02                	ld	s8,0(sp)
    80001124:	6161                	addi	sp,sp,80
    80001126:	8082                	ret
  return 0;
    80001128:	4501                	li	a0,0
    8000112a:	b7dd                	j	80001110 <mappages+0x82>

000000008000112c <kvmmap>:
{
    8000112c:	1141                	addi	sp,sp,-16
    8000112e:	e406                	sd	ra,8(sp)
    80001130:	e022                	sd	s0,0(sp)
    80001132:	0800                	addi	s0,sp,16
    80001134:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001136:	86b2                	mv	a3,a2
    80001138:	863e                	mv	a2,a5
    8000113a:	00000097          	auipc	ra,0x0
    8000113e:	f54080e7          	jalr	-172(ra) # 8000108e <mappages>
    80001142:	e509                	bnez	a0,8000114c <kvmmap+0x20>
}
    80001144:	60a2                	ld	ra,8(sp)
    80001146:	6402                	ld	s0,0(sp)
    80001148:	0141                	addi	sp,sp,16
    8000114a:	8082                	ret
    panic("kvmmap");
    8000114c:	00008517          	auipc	a0,0x8
    80001150:	f9450513          	addi	a0,a0,-108 # 800090e0 <digits+0xa0>
    80001154:	fffff097          	auipc	ra,0xfffff
    80001158:	3d6080e7          	jalr	982(ra) # 8000052a <panic>

000000008000115c <kvmmake>:
{
    8000115c:	1101                	addi	sp,sp,-32
    8000115e:	ec06                	sd	ra,24(sp)
    80001160:	e822                	sd	s0,16(sp)
    80001162:	e426                	sd	s1,8(sp)
    80001164:	e04a                	sd	s2,0(sp)
    80001166:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	96a080e7          	jalr	-1686(ra) # 80000ad2 <kalloc>
    80001170:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001172:	6605                	lui	a2,0x1
    80001174:	4581                	li	a1,0
    80001176:	00000097          	auipc	ra,0x0
    8000117a:	b48080e7          	jalr	-1208(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000117e:	4719                	li	a4,6
    80001180:	6685                	lui	a3,0x1
    80001182:	10000637          	lui	a2,0x10000
    80001186:	100005b7          	lui	a1,0x10000
    8000118a:	8526                	mv	a0,s1
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	fa0080e7          	jalr	-96(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001194:	4719                	li	a4,6
    80001196:	6685                	lui	a3,0x1
    80001198:	10001637          	lui	a2,0x10001
    8000119c:	100015b7          	lui	a1,0x10001
    800011a0:	8526                	mv	a0,s1
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	f8a080e7          	jalr	-118(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	004006b7          	lui	a3,0x400
    800011b0:	0c000637          	lui	a2,0xc000
    800011b4:	0c0005b7          	lui	a1,0xc000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	f72080e7          	jalr	-142(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011c2:	00008917          	auipc	s2,0x8
    800011c6:	e3e90913          	addi	s2,s2,-450 # 80009000 <etext>
    800011ca:	4729                	li	a4,10
    800011cc:	80008697          	auipc	a3,0x80008
    800011d0:	e3468693          	addi	a3,a3,-460 # 9000 <_entry-0x7fff7000>
    800011d4:	4605                	li	a2,1
    800011d6:	067e                	slli	a2,a2,0x1f
    800011d8:	85b2                	mv	a1,a2
    800011da:	8526                	mv	a0,s1
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	f50080e7          	jalr	-176(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011e4:	4719                	li	a4,6
    800011e6:	46c5                	li	a3,17
    800011e8:	06ee                	slli	a3,a3,0x1b
    800011ea:	412686b3          	sub	a3,a3,s2
    800011ee:	864a                	mv	a2,s2
    800011f0:	85ca                	mv	a1,s2
    800011f2:	8526                	mv	a0,s1
    800011f4:	00000097          	auipc	ra,0x0
    800011f8:	f38080e7          	jalr	-200(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011fc:	4729                	li	a4,10
    800011fe:	6685                	lui	a3,0x1
    80001200:	00007617          	auipc	a2,0x7
    80001204:	e0060613          	addi	a2,a2,-512 # 80008000 <_trampoline>
    80001208:	040005b7          	lui	a1,0x4000
    8000120c:	15fd                	addi	a1,a1,-1
    8000120e:	05b2                	slli	a1,a1,0xc
    80001210:	8526                	mv	a0,s1
    80001212:	00000097          	auipc	ra,0x0
    80001216:	f1a080e7          	jalr	-230(ra) # 8000112c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000121a:	8526                	mv	a0,s1
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	646080e7          	jalr	1606(ra) # 80001862 <proc_mapstacks>
}
    80001224:	8526                	mv	a0,s1
    80001226:	60e2                	ld	ra,24(sp)
    80001228:	6442                	ld	s0,16(sp)
    8000122a:	64a2                	ld	s1,8(sp)
    8000122c:	6902                	ld	s2,0(sp)
    8000122e:	6105                	addi	sp,sp,32
    80001230:	8082                	ret

0000000080001232 <kvminit>:
{
    80001232:	1141                	addi	sp,sp,-16
    80001234:	e406                	sd	ra,8(sp)
    80001236:	e022                	sd	s0,0(sp)
    80001238:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	f22080e7          	jalr	-222(ra) # 8000115c <kvmmake>
    80001242:	00009797          	auipc	a5,0x9
    80001246:	dca7bf23          	sd	a0,-546(a5) # 8000a020 <kernel_pagetable>
}
    8000124a:	60a2                	ld	ra,8(sp)
    8000124c:	6402                	ld	s0,0(sp)
    8000124e:	0141                	addi	sp,sp,16
    80001250:	8082                	ret

0000000080001252 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001252:	715d                	addi	sp,sp,-80
    80001254:	e486                	sd	ra,72(sp)
    80001256:	e0a2                	sd	s0,64(sp)
    80001258:	fc26                	sd	s1,56(sp)
    8000125a:	f84a                	sd	s2,48(sp)
    8000125c:	f44e                	sd	s3,40(sp)
    8000125e:	f052                	sd	s4,32(sp)
    80001260:	ec56                	sd	s5,24(sp)
    80001262:	e85a                	sd	s6,16(sp)
    80001264:	e45e                	sd	s7,8(sp)
    80001266:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001268:	03459793          	slli	a5,a1,0x34
    8000126c:	e795                	bnez	a5,80001298 <uvmunmap+0x46>
    8000126e:	8a2a                	mv	s4,a0
    80001270:	892e                	mv	s2,a1
    80001272:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001274:	0632                	slli	a2,a2,0xc
    80001276:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0 ) // ADDED Q1
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000127a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	6b05                	lui	s6,0x1
    8000127e:	0735e963          	bltu	a1,s3,800012f0 <uvmunmap+0x9e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001282:	60a6                	ld	ra,72(sp)
    80001284:	6406                	ld	s0,64(sp)
    80001286:	74e2                	ld	s1,56(sp)
    80001288:	7942                	ld	s2,48(sp)
    8000128a:	79a2                	ld	s3,40(sp)
    8000128c:	7a02                	ld	s4,32(sp)
    8000128e:	6ae2                	ld	s5,24(sp)
    80001290:	6b42                	ld	s6,16(sp)
    80001292:	6ba2                	ld	s7,8(sp)
    80001294:	6161                	addi	sp,sp,80
    80001296:	8082                	ret
    panic("uvmunmap: not aligned");
    80001298:	00008517          	auipc	a0,0x8
    8000129c:	e5050513          	addi	a0,a0,-432 # 800090e8 <digits+0xa8>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012a8:	00008517          	auipc	a0,0x8
    800012ac:	e5850513          	addi	a0,a0,-424 # 80009100 <digits+0xc0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012b8:	00008517          	auipc	a0,0x8
    800012bc:	e5850513          	addi	a0,a0,-424 # 80009110 <digits+0xd0>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012c8:	00008517          	auipc	a0,0x8
    800012cc:	e6050513          	addi	a0,a0,-416 # 80009128 <digits+0xe8>
    800012d0:	fffff097          	auipc	ra,0xfffff
    800012d4:	25a080e7          	jalr	602(ra) # 8000052a <panic>
      uint64 pa = PTE2PA(*pte);
    800012d8:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012da:	00c79513          	slli	a0,a5,0xc
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	6f8080e7          	jalr	1784(ra) # 800009d6 <kfree>
    *pte = 0;
    800012e6:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ea:	995a                	add	s2,s2,s6
    800012ec:	f9397be3          	bgeu	s2,s3,80001282 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f0:	4601                	li	a2,0
    800012f2:	85ca                	mv	a1,s2
    800012f4:	8552                	mv	a0,s4
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	cb0080e7          	jalr	-848(ra) # 80000fa6 <walk>
    800012fe:	84aa                	mv	s1,a0
    80001300:	d545                	beqz	a0,800012a8 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0 ) // ADDED Q1
    80001302:	611c                	ld	a5,0(a0)
    80001304:	2017f713          	andi	a4,a5,513
    80001308:	db45                	beqz	a4,800012b8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130a:	3ff7f713          	andi	a4,a5,1023
    8000130e:	fb770de3          	beq	a4,s7,800012c8 <uvmunmap+0x76>
    if(do_free && ((*pte & PTE_PG) == 0)){ // ADDED Q1
    80001312:	fc0a8ae3          	beqz	s5,800012e6 <uvmunmap+0x94>
    80001316:	2007f713          	andi	a4,a5,512
    8000131a:	f771                	bnez	a4,800012e6 <uvmunmap+0x94>
    8000131c:	bf75                	j	800012d8 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7aa080e7          	jalr	1962(ra) # 80000ad2 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	986080e7          	jalr	-1658(ra) # 80000cbe <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	76a080e7          	jalr	1898(ra) # 80000ad2 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	948080e7          	jalr	-1720(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d06080e7          	jalr	-762(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	984080e7          	jalr	-1660(ra) # 80000d1a <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00008517          	auipc	a0,0x8
    800013b2:	d9250513          	addi	a0,a0,-622 # 80009140 <digits+0x100>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	174080e7          	jalr	372(ra) # 8000052a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	7179                	addi	sp,sp,-48
    800013c0:	f406                	sd	ra,40(sp)
    800013c2:	f022                	sd	s0,32(sp)
    800013c4:	ec26                	sd	s1,24(sp)
    800013c6:	e84a                	sd	s2,16(sp)
    800013c8:	e44e                	sd	s3,8(sp)
    800013ca:	e052                	sd	s4,0(sp)
    800013cc:	1800                	addi	s0,sp,48
    800013ce:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    return oldsz;
    800013d0:	892e                	mv	s2,a1
  if(newsz >= oldsz)
    800013d2:	00b67d63          	bgeu	a2,a1,800013ec <uvmdealloc+0x2e>
    800013d6:	8932                	mv	s2,a2
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d8:	6785                	lui	a5,0x1
    800013da:	17fd                	addi	a5,a5,-1
    800013dc:	00f605b3          	add	a1,a2,a5
    800013e0:	767d                	lui	a2,0xfffff
    800013e2:	8df1                	and	a1,a1,a2
    800013e4:	97a6                	add	a5,a5,s1
    800013e6:	8ff1                	and	a5,a5,a2
    800013e8:	00f5eb63          	bltu	a1,a5,800013fe <uvmdealloc+0x40>
      remove_page_from_ram(a);
    }
  }

  return newsz;
}
    800013ec:	854a                	mv	a0,s2
    800013ee:	70a2                	ld	ra,40(sp)
    800013f0:	7402                	ld	s0,32(sp)
    800013f2:	64e2                	ld	s1,24(sp)
    800013f4:	6942                	ld	s2,16(sp)
    800013f6:	69a2                	ld	s3,8(sp)
    800013f8:	6a02                	ld	s4,0(sp)
    800013fa:	6145                	addi	sp,sp,48
    800013fc:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fe:	8f8d                	sub	a5,a5,a1
    80001400:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001402:	4685                	li	a3,1
    80001404:	0007861b          	sext.w	a2,a5
    80001408:	00000097          	auipc	ra,0x0
    8000140c:	e4a080e7          	jalr	-438(ra) # 80001252 <uvmunmap>
    for (int a = PGROUNDDOWN(oldsz); a > PGROUNDDOWN(newsz); a -= PGSIZE) {
    80001410:	77fd                	lui	a5,0xfffff
    80001412:	8cfd                	and	s1,s1,a5
    80001414:	2481                	sext.w	s1,s1
    80001416:	79fd                	lui	s3,0xfffff
    80001418:	013979b3          	and	s3,s2,s3
    8000141c:	fc99f8e3          	bgeu	s3,s1,800013ec <uvmdealloc+0x2e>
    80001420:	7a7d                	lui	s4,0xfffff
      remove_page_from_ram(a);
    80001422:	8526                	mv	a0,s1
    80001424:	00001097          	auipc	ra,0x1
    80001428:	72c080e7          	jalr	1836(ra) # 80002b50 <remove_page_from_ram>
    for (int a = PGROUNDDOWN(oldsz); a > PGROUNDDOWN(newsz); a -= PGSIZE) {
    8000142c:	94d2                	add	s1,s1,s4
    8000142e:	fe99eae3          	bltu	s3,s1,80001422 <uvmdealloc+0x64>
    80001432:	bf6d                	j	800013ec <uvmdealloc+0x2e>

0000000080001434 <uvmalloc>:
  if(newsz < oldsz)
    80001434:	0ab66663          	bltu	a2,a1,800014e0 <uvmalloc+0xac>
{
    80001438:	7139                	addi	sp,sp,-64
    8000143a:	fc06                	sd	ra,56(sp)
    8000143c:	f822                	sd	s0,48(sp)
    8000143e:	f426                	sd	s1,40(sp)
    80001440:	f04a                	sd	s2,32(sp)
    80001442:	ec4e                	sd	s3,24(sp)
    80001444:	e852                	sd	s4,16(sp)
    80001446:	e456                	sd	s5,8(sp)
    80001448:	0080                	addi	s0,sp,64
    8000144a:	8aaa                	mv	s5,a0
    8000144c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144e:	6985                	lui	s3,0x1
    80001450:	19fd                	addi	s3,s3,-1
    80001452:	95ce                	add	a1,a1,s3
    80001454:	79fd                	lui	s3,0xfffff
    80001456:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145a:	08c9f563          	bgeu	s3,a2,800014e4 <uvmalloc+0xb0>
    8000145e:	894e                	mv	s2,s3
    mem = kalloc();
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	672080e7          	jalr	1650(ra) # 80000ad2 <kalloc>
    80001468:	84aa                	mv	s1,a0
    if(mem == 0){
    8000146a:	cd05                	beqz	a0,800014a2 <uvmalloc+0x6e>
    memset(mem, 0, PGSIZE);
    8000146c:	6605                	lui	a2,0x1
    8000146e:	4581                	li	a1,0
    80001470:	00000097          	auipc	ra,0x0
    80001474:	84e080e7          	jalr	-1970(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001478:	4779                	li	a4,30
    8000147a:	86a6                	mv	a3,s1
    8000147c:	6605                	lui	a2,0x1
    8000147e:	85ca                	mv	a1,s2
    80001480:	8556                	mv	a0,s5
    80001482:	00000097          	auipc	ra,0x0
    80001486:	c0c080e7          	jalr	-1012(ra) # 8000108e <mappages>
    8000148a:	ed0d                	bnez	a0,800014c4 <uvmalloc+0x90>
    insert_page_to_ram(a);
    8000148c:	854a                	mv	a0,s2
    8000148e:	00002097          	auipc	ra,0x2
    80001492:	88e080e7          	jalr	-1906(ra) # 80002d1c <insert_page_to_ram>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001496:	6785                	lui	a5,0x1
    80001498:	993e                	add	s2,s2,a5
    8000149a:	fd4963e3          	bltu	s2,s4,80001460 <uvmalloc+0x2c>
  return newsz;
    8000149e:	8552                	mv	a0,s4
    800014a0:	a809                	j	800014b2 <uvmalloc+0x7e>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f16080e7          	jalr	-234(ra) # 800013be <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
}
    800014b2:	70e2                	ld	ra,56(sp)
    800014b4:	7442                	ld	s0,48(sp)
    800014b6:	74a2                	ld	s1,40(sp)
    800014b8:	7902                	ld	s2,32(sp)
    800014ba:	69e2                	ld	s3,24(sp)
    800014bc:	6a42                	ld	s4,16(sp)
    800014be:	6aa2                	ld	s5,8(sp)
    800014c0:	6121                	addi	sp,sp,64
    800014c2:	8082                	ret
      kfree(mem);
    800014c4:	8526                	mv	a0,s1
    800014c6:	fffff097          	auipc	ra,0xfffff
    800014ca:	510080e7          	jalr	1296(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ce:	864e                	mv	a2,s3
    800014d0:	85ca                	mv	a1,s2
    800014d2:	8556                	mv	a0,s5
    800014d4:	00000097          	auipc	ra,0x0
    800014d8:	eea080e7          	jalr	-278(ra) # 800013be <uvmdealloc>
      return 0;
    800014dc:	4501                	li	a0,0
    800014de:	bfd1                	j	800014b2 <uvmalloc+0x7e>
    return oldsz;
    800014e0:	852e                	mv	a0,a1
}
    800014e2:	8082                	ret
  return newsz;
    800014e4:	8532                	mv	a0,a2
    800014e6:	b7f1                	j	800014b2 <uvmalloc+0x7e>

00000000800014e8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014e8:	7179                	addi	sp,sp,-48
    800014ea:	f406                	sd	ra,40(sp)
    800014ec:	f022                	sd	s0,32(sp)
    800014ee:	ec26                	sd	s1,24(sp)
    800014f0:	e84a                	sd	s2,16(sp)
    800014f2:	e44e                	sd	s3,8(sp)
    800014f4:	e052                	sd	s4,0(sp)
    800014f6:	1800                	addi	s0,sp,48
    800014f8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014fa:	84aa                	mv	s1,a0
    800014fc:	6905                	lui	s2,0x1
    800014fe:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	4985                	li	s3,1
    80001502:	a821                	j	8000151a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001504:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001506:	0532                	slli	a0,a0,0xc
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	fe0080e7          	jalr	-32(ra) # 800014e8 <freewalk>
      pagetable[i] = 0;
    80001510:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001514:	04a1                	addi	s1,s1,8
    80001516:	03248163          	beq	s1,s2,80001538 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000151a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151c:	00f57793          	andi	a5,a0,15
    80001520:	ff3782e3          	beq	a5,s3,80001504 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001524:	8905                	andi	a0,a0,1
    80001526:	d57d                	beqz	a0,80001514 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001528:	00008517          	auipc	a0,0x8
    8000152c:	c3850513          	addi	a0,a0,-968 # 80009160 <digits+0x120>
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	ffa080e7          	jalr	-6(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    80001538:	8552                	mv	a0,s4
    8000153a:	fffff097          	auipc	ra,0xfffff
    8000153e:	49c080e7          	jalr	1180(ra) # 800009d6 <kfree>
}
    80001542:	70a2                	ld	ra,40(sp)
    80001544:	7402                	ld	s0,32(sp)
    80001546:	64e2                	ld	s1,24(sp)
    80001548:	6942                	ld	s2,16(sp)
    8000154a:	69a2                	ld	s3,8(sp)
    8000154c:	6a02                	ld	s4,0(sp)
    8000154e:	6145                	addi	sp,sp,48
    80001550:	8082                	ret

0000000080001552 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001552:	1101                	addi	sp,sp,-32
    80001554:	ec06                	sd	ra,24(sp)
    80001556:	e822                	sd	s0,16(sp)
    80001558:	e426                	sd	s1,8(sp)
    8000155a:	1000                	addi	s0,sp,32
    8000155c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000155e:	e999                	bnez	a1,80001574 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001560:	8526                	mv	a0,s1
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f86080e7          	jalr	-122(ra) # 800014e8 <freewalk>
}
    8000156a:	60e2                	ld	ra,24(sp)
    8000156c:	6442                	ld	s0,16(sp)
    8000156e:	64a2                	ld	s1,8(sp)
    80001570:	6105                	addi	sp,sp,32
    80001572:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001574:	6605                	lui	a2,0x1
    80001576:	167d                	addi	a2,a2,-1
    80001578:	962e                	add	a2,a2,a1
    8000157a:	4685                	li	a3,1
    8000157c:	8231                	srli	a2,a2,0xc
    8000157e:	4581                	li	a1,0
    80001580:	00000097          	auipc	ra,0x0
    80001584:	cd2080e7          	jalr	-814(ra) # 80001252 <uvmunmap>
    80001588:	bfe1                	j	80001560 <uvmfree+0xe>

000000008000158a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem =0;

  for(i = 0; i < sz; i += PGSIZE){
    8000158a:	ca71                	beqz	a2,8000165e <uvmcopy+0xd4>
{
    8000158c:	715d                	addi	sp,sp,-80
    8000158e:	e486                	sd	ra,72(sp)
    80001590:	e0a2                	sd	s0,64(sp)
    80001592:	fc26                	sd	s1,56(sp)
    80001594:	f84a                	sd	s2,48(sp)
    80001596:	f44e                	sd	s3,40(sp)
    80001598:	f052                	sd	s4,32(sp)
    8000159a:	ec56                	sd	s5,24(sp)
    8000159c:	e85a                	sd	s6,16(sp)
    8000159e:	e45e                	sd	s7,8(sp)
    800015a0:	0880                	addi	s0,sp,80
    800015a2:	8b2a                	mv	s6,a0
    800015a4:	8aae                	mv	s5,a1
    800015a6:	8a32                	mv	s4,a2
  char *mem =0;
    800015a8:	4981                	li	s3,0
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	4901                	li	s2,0
    800015ac:	a83d                	j	800015ea <uvmcopy+0x60>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015ae:	00008517          	auipc	a0,0x8
    800015b2:	bc250513          	addi	a0,a0,-1086 # 80009170 <digits+0x130>
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	f74080e7          	jalr	-140(ra) # 8000052a <panic>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
      panic("uvmcopy: page not present");
    800015be:	00008517          	auipc	a0,0x8
    800015c2:	bd250513          	addi	a0,a0,-1070 # 80009190 <digits+0x150>
    800015c6:	fffff097          	auipc	ra,0xfffff
    800015ca:	f64080e7          	jalr	-156(ra) # 8000052a <panic>
    if ((flags & PTE_PG) == 0) {
      if((mem = kalloc()) == 0)
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
    }
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ce:	875e                	mv	a4,s7
    800015d0:	86ce                	mv	a3,s3
    800015d2:	6605                	lui	a2,0x1
    800015d4:	85ca                	mv	a1,s2
    800015d6:	8556                	mv	a0,s5
    800015d8:	00000097          	auipc	ra,0x0
    800015dc:	ab6080e7          	jalr	-1354(ra) # 8000108e <mappages>
    800015e0:	e529                	bnez	a0,8000162a <uvmcopy+0xa0>
  for(i = 0; i < sz; i += PGSIZE){
    800015e2:	6785                	lui	a5,0x1
    800015e4:	993e                	add	s2,s2,a5
    800015e6:	07497163          	bgeu	s2,s4,80001648 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    800015ea:	4601                	li	a2,0
    800015ec:	85ca                	mv	a1,s2
    800015ee:	855a                	mv	a0,s6
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	9b6080e7          	jalr	-1610(ra) # 80000fa6 <walk>
    800015f8:	d95d                	beqz	a0,800015ae <uvmcopy+0x24>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
    800015fa:	6104                	ld	s1,0(a0)
    800015fc:	2014f793          	andi	a5,s1,513
    80001600:	dfdd                	beqz	a5,800015be <uvmcopy+0x34>
    flags = PTE_FLAGS(*pte);
    80001602:	3ff4fb93          	andi	s7,s1,1023
    if ((flags & PTE_PG) == 0) {
    80001606:	2004f793          	andi	a5,s1,512
    8000160a:	f3f1                	bnez	a5,800015ce <uvmcopy+0x44>
      if((mem = kalloc()) == 0)
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	4c6080e7          	jalr	1222(ra) # 80000ad2 <kalloc>
    80001614:	89aa                	mv	s3,a0
    80001616:	cd19                	beqz	a0,80001634 <uvmcopy+0xaa>
    pa = PTE2PA(*pte);
    80001618:	00a4d593          	srli	a1,s1,0xa
      memmove(mem, (char*)pa, PGSIZE);
    8000161c:	6605                	lui	a2,0x1
    8000161e:	05b2                	slli	a1,a1,0xc
    80001620:	fffff097          	auipc	ra,0xfffff
    80001624:	6fa080e7          	jalr	1786(ra) # 80000d1a <memmove>
    80001628:	b75d                	j	800015ce <uvmcopy+0x44>
      kfree(mem);
    8000162a:	854e                	mv	a0,s3
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	3aa080e7          	jalr	938(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001634:	4685                	li	a3,1
    80001636:	00c95613          	srli	a2,s2,0xc
    8000163a:	4581                	li	a1,0
    8000163c:	8556                	mv	a0,s5
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	c14080e7          	jalr	-1004(ra) # 80001252 <uvmunmap>
  return -1;
    80001646:	557d                	li	a0,-1
}
    80001648:	60a6                	ld	ra,72(sp)
    8000164a:	6406                	ld	s0,64(sp)
    8000164c:	74e2                	ld	s1,56(sp)
    8000164e:	7942                	ld	s2,48(sp)
    80001650:	79a2                	ld	s3,40(sp)
    80001652:	7a02                	ld	s4,32(sp)
    80001654:	6ae2                	ld	s5,24(sp)
    80001656:	6b42                	ld	s6,16(sp)
    80001658:	6ba2                	ld	s7,8(sp)
    8000165a:	6161                	addi	sp,sp,80
    8000165c:	8082                	ret
  return 0;
    8000165e:	4501                	li	a0,0
}
    80001660:	8082                	ret

0000000080001662 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001662:	1141                	addi	sp,sp,-16
    80001664:	e406                	sd	ra,8(sp)
    80001666:	e022                	sd	s0,0(sp)
    80001668:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000166a:	4601                	li	a2,0
    8000166c:	00000097          	auipc	ra,0x0
    80001670:	93a080e7          	jalr	-1734(ra) # 80000fa6 <walk>
  if(pte == 0)
    80001674:	c901                	beqz	a0,80001684 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001676:	611c                	ld	a5,0(a0)
    80001678:	9bbd                	andi	a5,a5,-17
    8000167a:	e11c                	sd	a5,0(a0)
}
    8000167c:	60a2                	ld	ra,8(sp)
    8000167e:	6402                	ld	s0,0(sp)
    80001680:	0141                	addi	sp,sp,16
    80001682:	8082                	ret
    panic("uvmclear");
    80001684:	00008517          	auipc	a0,0x8
    80001688:	b2c50513          	addi	a0,a0,-1236 # 800091b0 <digits+0x170>
    8000168c:	fffff097          	auipc	ra,0xfffff
    80001690:	e9e080e7          	jalr	-354(ra) # 8000052a <panic>

0000000080001694 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001694:	c6bd                	beqz	a3,80001702 <copyout+0x6e>
{
    80001696:	715d                	addi	sp,sp,-80
    80001698:	e486                	sd	ra,72(sp)
    8000169a:	e0a2                	sd	s0,64(sp)
    8000169c:	fc26                	sd	s1,56(sp)
    8000169e:	f84a                	sd	s2,48(sp)
    800016a0:	f44e                	sd	s3,40(sp)
    800016a2:	f052                	sd	s4,32(sp)
    800016a4:	ec56                	sd	s5,24(sp)
    800016a6:	e85a                	sd	s6,16(sp)
    800016a8:	e45e                	sd	s7,8(sp)
    800016aa:	e062                	sd	s8,0(sp)
    800016ac:	0880                	addi	s0,sp,80
    800016ae:	8b2a                	mv	s6,a0
    800016b0:	8c2e                	mv	s8,a1
    800016b2:	8a32                	mv	s4,a2
    800016b4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016b6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016b8:	6a85                	lui	s5,0x1
    800016ba:	a015                	j	800016de <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016bc:	9562                	add	a0,a0,s8
    800016be:	0004861b          	sext.w	a2,s1
    800016c2:	85d2                	mv	a1,s4
    800016c4:	41250533          	sub	a0,a0,s2
    800016c8:	fffff097          	auipc	ra,0xfffff
    800016cc:	652080e7          	jalr	1618(ra) # 80000d1a <memmove>

    len -= n;
    800016d0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016d4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016d6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016da:	02098263          	beqz	s3,800016fe <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016de:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016e2:	85ca                	mv	a1,s2
    800016e4:	855a                	mv	a0,s6
    800016e6:	00000097          	auipc	ra,0x0
    800016ea:	966080e7          	jalr	-1690(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800016ee:	cd01                	beqz	a0,80001706 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016f0:	418904b3          	sub	s1,s2,s8
    800016f4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016f6:	fc99f3e3          	bgeu	s3,s1,800016bc <copyout+0x28>
    800016fa:	84ce                	mv	s1,s3
    800016fc:	b7c1                	j	800016bc <copyout+0x28>
  }
  return 0;
    800016fe:	4501                	li	a0,0
    80001700:	a021                	j	80001708 <copyout+0x74>
    80001702:	4501                	li	a0,0
}
    80001704:	8082                	ret
      return -1;
    80001706:	557d                	li	a0,-1
}
    80001708:	60a6                	ld	ra,72(sp)
    8000170a:	6406                	ld	s0,64(sp)
    8000170c:	74e2                	ld	s1,56(sp)
    8000170e:	7942                	ld	s2,48(sp)
    80001710:	79a2                	ld	s3,40(sp)
    80001712:	7a02                	ld	s4,32(sp)
    80001714:	6ae2                	ld	s5,24(sp)
    80001716:	6b42                	ld	s6,16(sp)
    80001718:	6ba2                	ld	s7,8(sp)
    8000171a:	6c02                	ld	s8,0(sp)
    8000171c:	6161                	addi	sp,sp,80
    8000171e:	8082                	ret

0000000080001720 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001720:	caa5                	beqz	a3,80001790 <copyin+0x70>
{
    80001722:	715d                	addi	sp,sp,-80
    80001724:	e486                	sd	ra,72(sp)
    80001726:	e0a2                	sd	s0,64(sp)
    80001728:	fc26                	sd	s1,56(sp)
    8000172a:	f84a                	sd	s2,48(sp)
    8000172c:	f44e                	sd	s3,40(sp)
    8000172e:	f052                	sd	s4,32(sp)
    80001730:	ec56                	sd	s5,24(sp)
    80001732:	e85a                	sd	s6,16(sp)
    80001734:	e45e                	sd	s7,8(sp)
    80001736:	e062                	sd	s8,0(sp)
    80001738:	0880                	addi	s0,sp,80
    8000173a:	8b2a                	mv	s6,a0
    8000173c:	8a2e                	mv	s4,a1
    8000173e:	8c32                	mv	s8,a2
    80001740:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001742:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001744:	6a85                	lui	s5,0x1
    80001746:	a01d                	j	8000176c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001748:	018505b3          	add	a1,a0,s8
    8000174c:	0004861b          	sext.w	a2,s1
    80001750:	412585b3          	sub	a1,a1,s2
    80001754:	8552                	mv	a0,s4
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	5c4080e7          	jalr	1476(ra) # 80000d1a <memmove>

    len -= n;
    8000175e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001762:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001764:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001768:	02098263          	beqz	s3,8000178c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000176c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001770:	85ca                	mv	a1,s2
    80001772:	855a                	mv	a0,s6
    80001774:	00000097          	auipc	ra,0x0
    80001778:	8d8080e7          	jalr	-1832(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    8000177c:	cd01                	beqz	a0,80001794 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000177e:	418904b3          	sub	s1,s2,s8
    80001782:	94d6                	add	s1,s1,s5
    if(n > len)
    80001784:	fc99f2e3          	bgeu	s3,s1,80001748 <copyin+0x28>
    80001788:	84ce                	mv	s1,s3
    8000178a:	bf7d                	j	80001748 <copyin+0x28>
  }
  return 0;
    8000178c:	4501                	li	a0,0
    8000178e:	a021                	j	80001796 <copyin+0x76>
    80001790:	4501                	li	a0,0
}
    80001792:	8082                	ret
      return -1;
    80001794:	557d                	li	a0,-1
}
    80001796:	60a6                	ld	ra,72(sp)
    80001798:	6406                	ld	s0,64(sp)
    8000179a:	74e2                	ld	s1,56(sp)
    8000179c:	7942                	ld	s2,48(sp)
    8000179e:	79a2                	ld	s3,40(sp)
    800017a0:	7a02                	ld	s4,32(sp)
    800017a2:	6ae2                	ld	s5,24(sp)
    800017a4:	6b42                	ld	s6,16(sp)
    800017a6:	6ba2                	ld	s7,8(sp)
    800017a8:	6c02                	ld	s8,0(sp)
    800017aa:	6161                	addi	sp,sp,80
    800017ac:	8082                	ret

00000000800017ae <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ae:	c6c5                	beqz	a3,80001856 <copyinstr+0xa8>
{
    800017b0:	715d                	addi	sp,sp,-80
    800017b2:	e486                	sd	ra,72(sp)
    800017b4:	e0a2                	sd	s0,64(sp)
    800017b6:	fc26                	sd	s1,56(sp)
    800017b8:	f84a                	sd	s2,48(sp)
    800017ba:	f44e                	sd	s3,40(sp)
    800017bc:	f052                	sd	s4,32(sp)
    800017be:	ec56                	sd	s5,24(sp)
    800017c0:	e85a                	sd	s6,16(sp)
    800017c2:	e45e                	sd	s7,8(sp)
    800017c4:	0880                	addi	s0,sp,80
    800017c6:	8a2a                	mv	s4,a0
    800017c8:	8b2e                	mv	s6,a1
    800017ca:	8bb2                	mv	s7,a2
    800017cc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ce:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d0:	6985                	lui	s3,0x1
    800017d2:	a035                	j	800017fe <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017d8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017da:	0017b793          	seqz	a5,a5
    800017de:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6161                	addi	sp,sp,80
    800017f6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017f8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017fc:	c8a9                	beqz	s1,8000184e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017fe:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001802:	85ca                	mv	a1,s2
    80001804:	8552                	mv	a0,s4
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	846080e7          	jalr	-1978(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    8000180e:	c131                	beqz	a0,80001852 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001810:	41790833          	sub	a6,s2,s7
    80001814:	984e                	add	a6,a6,s3
    if(n > max)
    80001816:	0104f363          	bgeu	s1,a6,8000181c <copyinstr+0x6e>
    8000181a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000181c:	955e                	add	a0,a0,s7
    8000181e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001822:	fc080be3          	beqz	a6,800017f8 <copyinstr+0x4a>
    80001826:	985a                	add	a6,a6,s6
    80001828:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000182a:	41650633          	sub	a2,a0,s6
    8000182e:	14fd                	addi	s1,s1,-1
    80001830:	9b26                	add	s6,s6,s1
    80001832:	00f60733          	add	a4,a2,a5
    80001836:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd0000>
    8000183a:	df49                	beqz	a4,800017d4 <copyinstr+0x26>
        *dst = *p;
    8000183c:	00e78023          	sb	a4,0(a5)
      --max;
    80001840:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001844:	0785                	addi	a5,a5,1
    while(n > 0){
    80001846:	ff0796e3          	bne	a5,a6,80001832 <copyinstr+0x84>
      dst++;
    8000184a:	8b42                	mv	s6,a6
    8000184c:	b775                	j	800017f8 <copyinstr+0x4a>
    8000184e:	4781                	li	a5,0
    80001850:	b769                	j	800017da <copyinstr+0x2c>
      return -1;
    80001852:	557d                	li	a0,-1
    80001854:	b779                	j	800017e2 <copyinstr+0x34>
  int got_null = 0;
    80001856:	4781                	li	a5,0
  if(got_null){
    80001858:	0017b793          	seqz	a5,a5
    8000185c:	40f00533          	neg	a0,a5
}
    80001860:	8082                	ret

0000000080001862 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001862:	7139                	addi	sp,sp,-64
    80001864:	fc06                	sd	ra,56(sp)
    80001866:	f822                	sd	s0,48(sp)
    80001868:	f426                	sd	s1,40(sp)
    8000186a:	f04a                	sd	s2,32(sp)
    8000186c:	ec4e                	sd	s3,24(sp)
    8000186e:	e852                	sd	s4,16(sp)
    80001870:	e456                	sd	s5,8(sp)
    80001872:	e05a                	sd	s6,0(sp)
    80001874:	0080                	addi	s0,sp,64
    80001876:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001878:	00011497          	auipc	s1,0x11
    8000187c:	e5848493          	addi	s1,s1,-424 # 800126d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001880:	8b26                	mv	s6,s1
    80001882:	00007a97          	auipc	s5,0x7
    80001886:	77ea8a93          	addi	s5,s5,1918 # 80009000 <etext>
    8000188a:	04000937          	lui	s2,0x4000
    8000188e:	197d                	addi	s2,s2,-1
    80001890:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001892:	0001fa17          	auipc	s4,0x1f
    80001896:	c3ea0a13          	addi	s4,s4,-962 # 800204d0 <tickslock>
    char *pa = kalloc();
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	238080e7          	jalr	568(ra) # 80000ad2 <kalloc>
    800018a2:	862a                	mv	a2,a0
    if(pa == 0)
    800018a4:	c131                	beqz	a0,800018e8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018a6:	416485b3          	sub	a1,s1,s6
    800018aa:	858d                	srai	a1,a1,0x3
    800018ac:	000ab783          	ld	a5,0(s5)
    800018b0:	02f585b3          	mul	a1,a1,a5
    800018b4:	2585                	addiw	a1,a1,1
    800018b6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018ba:	4719                	li	a4,6
    800018bc:	6685                	lui	a3,0x1
    800018be:	40b905b3          	sub	a1,s2,a1
    800018c2:	854e                	mv	a0,s3
    800018c4:	00000097          	auipc	ra,0x0
    800018c8:	868080e7          	jalr	-1944(ra) # 8000112c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018cc:	37848493          	addi	s1,s1,888
    800018d0:	fd4495e3          	bne	s1,s4,8000189a <proc_mapstacks+0x38>
  }
}
    800018d4:	70e2                	ld	ra,56(sp)
    800018d6:	7442                	ld	s0,48(sp)
    800018d8:	74a2                	ld	s1,40(sp)
    800018da:	7902                	ld	s2,32(sp)
    800018dc:	69e2                	ld	s3,24(sp)
    800018de:	6a42                	ld	s4,16(sp)
    800018e0:	6aa2                	ld	s5,8(sp)
    800018e2:	6b02                	ld	s6,0(sp)
    800018e4:	6121                	addi	sp,sp,64
    800018e6:	8082                	ret
      panic("kalloc");
    800018e8:	00008517          	auipc	a0,0x8
    800018ec:	8d850513          	addi	a0,a0,-1832 # 800091c0 <digits+0x180>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	c3a080e7          	jalr	-966(ra) # 8000052a <panic>

00000000800018f8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018f8:	7139                	addi	sp,sp,-64
    800018fa:	fc06                	sd	ra,56(sp)
    800018fc:	f822                	sd	s0,48(sp)
    800018fe:	f426                	sd	s1,40(sp)
    80001900:	f04a                	sd	s2,32(sp)
    80001902:	ec4e                	sd	s3,24(sp)
    80001904:	e852                	sd	s4,16(sp)
    80001906:	e456                	sd	s5,8(sp)
    80001908:	e05a                	sd	s6,0(sp)
    8000190a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000190c:	00008597          	auipc	a1,0x8
    80001910:	8bc58593          	addi	a1,a1,-1860 # 800091c8 <digits+0x188>
    80001914:	00011517          	auipc	a0,0x11
    80001918:	98c50513          	addi	a0,a0,-1652 # 800122a0 <pid_lock>
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	216080e7          	jalr	534(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001924:	00008597          	auipc	a1,0x8
    80001928:	8ac58593          	addi	a1,a1,-1876 # 800091d0 <digits+0x190>
    8000192c:	00011517          	auipc	a0,0x11
    80001930:	98c50513          	addi	a0,a0,-1652 # 800122b8 <wait_lock>
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	1fe080e7          	jalr	510(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193c:	00011497          	auipc	s1,0x11
    80001940:	d9448493          	addi	s1,s1,-620 # 800126d0 <proc>
      initlock(&p->lock, "proc");
    80001944:	00008b17          	auipc	s6,0x8
    80001948:	89cb0b13          	addi	s6,s6,-1892 # 800091e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    8000194c:	8aa6                	mv	s5,s1
    8000194e:	00007a17          	auipc	s4,0x7
    80001952:	6b2a0a13          	addi	s4,s4,1714 # 80009000 <etext>
    80001956:	04000937          	lui	s2,0x4000
    8000195a:	197d                	addi	s2,s2,-1
    8000195c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195e:	0001f997          	auipc	s3,0x1f
    80001962:	b7298993          	addi	s3,s3,-1166 # 800204d0 <tickslock>
      initlock(&p->lock, "proc");
    80001966:	85da                	mv	a1,s6
    80001968:	8526                	mv	a0,s1
    8000196a:	fffff097          	auipc	ra,0xfffff
    8000196e:	1c8080e7          	jalr	456(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001972:	415487b3          	sub	a5,s1,s5
    80001976:	878d                	srai	a5,a5,0x3
    80001978:	000a3703          	ld	a4,0(s4)
    8000197c:	02e787b3          	mul	a5,a5,a4
    80001980:	2785                	addiw	a5,a5,1
    80001982:	00d7979b          	slliw	a5,a5,0xd
    80001986:	40f907b3          	sub	a5,s2,a5
    8000198a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198c:	37848493          	addi	s1,s1,888
    80001990:	fd349be3          	bne	s1,s3,80001966 <procinit+0x6e>
  }
}
    80001994:	70e2                	ld	ra,56(sp)
    80001996:	7442                	ld	s0,48(sp)
    80001998:	74a2                	ld	s1,40(sp)
    8000199a:	7902                	ld	s2,32(sp)
    8000199c:	69e2                	ld	s3,24(sp)
    8000199e:	6a42                	ld	s4,16(sp)
    800019a0:	6aa2                	ld	s5,8(sp)
    800019a2:	6b02                	ld	s6,0(sp)
    800019a4:	6121                	addi	sp,sp,64
    800019a6:	8082                	ret

00000000800019a8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a8:	1141                	addi	sp,sp,-16
    800019aa:	e422                	sd	s0,8(sp)
    800019ac:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019ae:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019b0:	2501                	sext.w	a0,a0
    800019b2:	6422                	ld	s0,8(sp)
    800019b4:	0141                	addi	sp,sp,16
    800019b6:	8082                	ret

00000000800019b8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019b8:	1141                	addi	sp,sp,-16
    800019ba:	e422                	sd	s0,8(sp)
    800019bc:	0800                	addi	s0,sp,16
    800019be:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019c4:	00011517          	auipc	a0,0x11
    800019c8:	90c50513          	addi	a0,a0,-1780 # 800122d0 <cpus>
    800019cc:	953e                	add	a0,a0,a5
    800019ce:	6422                	ld	s0,8(sp)
    800019d0:	0141                	addi	sp,sp,16
    800019d2:	8082                	ret

00000000800019d4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019d4:	1101                	addi	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	1000                	addi	s0,sp,32
  push_off();
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	198080e7          	jalr	408(ra) # 80000b76 <push_off>
    800019e6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e8:	2781                	sext.w	a5,a5
    800019ea:	079e                	slli	a5,a5,0x7
    800019ec:	00011717          	auipc	a4,0x11
    800019f0:	8b470713          	addi	a4,a4,-1868 # 800122a0 <pid_lock>
    800019f4:	97ba                	add	a5,a5,a4
    800019f6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	21e080e7          	jalr	542(ra) # 80000c16 <pop_off>
  return p;
}
    80001a00:	8526                	mv	a0,s1
    80001a02:	60e2                	ld	ra,24(sp)
    80001a04:	6442                	ld	s0,16(sp)
    80001a06:	64a2                	ld	s1,8(sp)
    80001a08:	6105                	addi	sp,sp,32
    80001a0a:	8082                	ret

0000000080001a0c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e406                	sd	ra,8(sp)
    80001a10:	e022                	sd	s0,0(sp)
    80001a12:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a14:	00000097          	auipc	ra,0x0
    80001a18:	fc0080e7          	jalr	-64(ra) # 800019d4 <myproc>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	25a080e7          	jalr	602(ra) # 80000c76 <release>

  if (first) {
    80001a24:	00008797          	auipc	a5,0x8
    80001a28:	0fc7a783          	lw	a5,252(a5) # 80009b20 <first.1>
    80001a2c:	eb89                	bnez	a5,80001a3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2e:	00001097          	auipc	ra,0x1
    80001a32:	57e080e7          	jalr	1406(ra) # 80002fac <usertrapret>
}
    80001a36:	60a2                	ld	ra,8(sp)
    80001a38:	6402                	ld	s0,0(sp)
    80001a3a:	0141                	addi	sp,sp,16
    80001a3c:	8082                	ret
    first = 0;
    80001a3e:	00008797          	auipc	a5,0x8
    80001a42:	0e07a123          	sw	zero,226(a5) # 80009b20 <first.1>
    fsinit(ROOTDEV);
    80001a46:	4505                	li	a0,1
    80001a48:	00002097          	auipc	ra,0x2
    80001a4c:	2de080e7          	jalr	734(ra) # 80003d26 <fsinit>
    80001a50:	bff9                	j	80001a2e <forkret+0x22>

0000000080001a52 <allocpid>:
allocpid() {
    80001a52:	1101                	addi	sp,sp,-32
    80001a54:	ec06                	sd	ra,24(sp)
    80001a56:	e822                	sd	s0,16(sp)
    80001a58:	e426                	sd	s1,8(sp)
    80001a5a:	e04a                	sd	s2,0(sp)
    80001a5c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a5e:	00011917          	auipc	s2,0x11
    80001a62:	84290913          	addi	s2,s2,-1982 # 800122a0 <pid_lock>
    80001a66:	854a                	mv	a0,s2
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	15a080e7          	jalr	346(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a70:	00008797          	auipc	a5,0x8
    80001a74:	0b478793          	addi	a5,a5,180 # 80009b24 <nextpid>
    80001a78:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a7a:	0014871b          	addiw	a4,s1,1
    80001a7e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a80:	854a                	mv	a0,s2
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	1f4080e7          	jalr	500(ra) # 80000c76 <release>
}
    80001a8a:	8526                	mv	a0,s1
    80001a8c:	60e2                	ld	ra,24(sp)
    80001a8e:	6442                	ld	s0,16(sp)
    80001a90:	64a2                	ld	s1,8(sp)
    80001a92:	6902                	ld	s2,0(sp)
    80001a94:	6105                	addi	sp,sp,32
    80001a96:	8082                	ret

0000000080001a98 <proc_pagetable>:
{
    80001a98:	1101                	addi	sp,sp,-32
    80001a9a:	ec06                	sd	ra,24(sp)
    80001a9c:	e822                	sd	s0,16(sp)
    80001a9e:	e426                	sd	s1,8(sp)
    80001aa0:	e04a                	sd	s2,0(sp)
    80001aa2:	1000                	addi	s0,sp,32
    80001aa4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa6:	00000097          	auipc	ra,0x0
    80001aaa:	878080e7          	jalr	-1928(ra) # 8000131e <uvmcreate>
    80001aae:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ab0:	c121                	beqz	a0,80001af0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ab2:	4729                	li	a4,10
    80001ab4:	00006697          	auipc	a3,0x6
    80001ab8:	54c68693          	addi	a3,a3,1356 # 80008000 <_trampoline>
    80001abc:	6605                	lui	a2,0x1
    80001abe:	040005b7          	lui	a1,0x4000
    80001ac2:	15fd                	addi	a1,a1,-1
    80001ac4:	05b2                	slli	a1,a1,0xc
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	5c8080e7          	jalr	1480(ra) # 8000108e <mappages>
    80001ace:	02054863          	bltz	a0,80001afe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ad2:	4719                	li	a4,6
    80001ad4:	05893683          	ld	a3,88(s2)
    80001ad8:	6605                	lui	a2,0x1
    80001ada:	020005b7          	lui	a1,0x2000
    80001ade:	15fd                	addi	a1,a1,-1
    80001ae0:	05b6                	slli	a1,a1,0xd
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	5aa080e7          	jalr	1450(ra) # 8000108e <mappages>
    80001aec:	02054163          	bltz	a0,80001b0e <proc_pagetable+0x76>
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6902                	ld	s2,0(sp)
    80001afa:	6105                	addi	sp,sp,32
    80001afc:	8082                	ret
    uvmfree(pagetable, 0);
    80001afe:	4581                	li	a1,0
    80001b00:	8526                	mv	a0,s1
    80001b02:	00000097          	auipc	ra,0x0
    80001b06:	a50080e7          	jalr	-1456(ra) # 80001552 <uvmfree>
    return 0;
    80001b0a:	4481                	li	s1,0
    80001b0c:	b7d5                	j	80001af0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0e:	4681                	li	a3,0
    80001b10:	4605                	li	a2,1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	736080e7          	jalr	1846(ra) # 80001252 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b24:	4581                	li	a1,0
    80001b26:	8526                	mv	a0,s1
    80001b28:	00000097          	auipc	ra,0x0
    80001b2c:	a2a080e7          	jalr	-1494(ra) # 80001552 <uvmfree>
    return 0;
    80001b30:	4481                	li	s1,0
    80001b32:	bf7d                	j	80001af0 <proc_pagetable+0x58>

0000000080001b34 <proc_freepagetable>:
{
    80001b34:	1101                	addi	sp,sp,-32
    80001b36:	ec06                	sd	ra,24(sp)
    80001b38:	e822                	sd	s0,16(sp)
    80001b3a:	e426                	sd	s1,8(sp)
    80001b3c:	e04a                	sd	s2,0(sp)
    80001b3e:	1000                	addi	s0,sp,32
    80001b40:	84aa                	mv	s1,a0
    80001b42:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b44:	4681                	li	a3,0
    80001b46:	4605                	li	a2,1
    80001b48:	040005b7          	lui	a1,0x4000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b2                	slli	a1,a1,0xc
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	702080e7          	jalr	1794(ra) # 80001252 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b58:	4681                	li	a3,0
    80001b5a:	4605                	li	a2,1
    80001b5c:	020005b7          	lui	a1,0x2000
    80001b60:	15fd                	addi	a1,a1,-1
    80001b62:	05b6                	slli	a1,a1,0xd
    80001b64:	8526                	mv	a0,s1
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	6ec080e7          	jalr	1772(ra) # 80001252 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b6e:	85ca                	mv	a1,s2
    80001b70:	8526                	mv	a0,s1
    80001b72:	00000097          	auipc	ra,0x0
    80001b76:	9e0080e7          	jalr	-1568(ra) # 80001552 <uvmfree>
}
    80001b7a:	60e2                	ld	ra,24(sp)
    80001b7c:	6442                	ld	s0,16(sp)
    80001b7e:	64a2                	ld	s1,8(sp)
    80001b80:	6902                	ld	s2,0(sp)
    80001b82:	6105                	addi	sp,sp,32
    80001b84:	8082                	ret

0000000080001b86 <freeproc>:
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b92:	6d28                	ld	a0,88(a0)
    80001b94:	c509                	beqz	a0,80001b9e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	e40080e7          	jalr	-448(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b9e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ba2:	68a8                	ld	a0,80(s1)
    80001ba4:	c511                	beqz	a0,80001bb0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba6:	64ac                	ld	a1,72(s1)
    80001ba8:	00000097          	auipc	ra,0x0
    80001bac:	f8c080e7          	jalr	-116(ra) # 80001b34 <proc_freepagetable>
  p->pagetable = 0;
    80001bb0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bbc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bc0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bcc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bd0:	0004ac23          	sw	zero,24(s1)
}
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6105                	addi	sp,sp,32
    80001bdc:	8082                	ret

0000000080001bde <allocproc>:
{
    80001bde:	1101                	addi	sp,sp,-32
    80001be0:	ec06                	sd	ra,24(sp)
    80001be2:	e822                	sd	s0,16(sp)
    80001be4:	e426                	sd	s1,8(sp)
    80001be6:	e04a                	sd	s2,0(sp)
    80001be8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	00011497          	auipc	s1,0x11
    80001bee:	ae648493          	addi	s1,s1,-1306 # 800126d0 <proc>
    80001bf2:	0001f917          	auipc	s2,0x1f
    80001bf6:	8de90913          	addi	s2,s2,-1826 # 800204d0 <tickslock>
    acquire(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	fc6080e7          	jalr	-58(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001c04:	4c9c                	lw	a5,24(s1)
    80001c06:	cf81                	beqz	a5,80001c1e <allocproc+0x40>
      release(&p->lock);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	06c080e7          	jalr	108(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c12:	37848493          	addi	s1,s1,888
    80001c16:	ff2492e3          	bne	s1,s2,80001bfa <allocproc+0x1c>
  return 0;
    80001c1a:	4481                	li	s1,0
    80001c1c:	a889                	j	80001c6e <allocproc+0x90>
  p->pid = allocpid();
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	e34080e7          	jalr	-460(ra) # 80001a52 <allocpid>
    80001c26:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c28:	4785                	li	a5,1
    80001c2a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	ea6080e7          	jalr	-346(ra) # 80000ad2 <kalloc>
    80001c34:	892a                	mv	s2,a0
    80001c36:	eca8                	sd	a0,88(s1)
    80001c38:	c131                	beqz	a0,80001c7c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	00000097          	auipc	ra,0x0
    80001c40:	e5c080e7          	jalr	-420(ra) # 80001a98 <proc_pagetable>
    80001c44:	892a                	mv	s2,a0
    80001c46:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c48:	c531                	beqz	a0,80001c94 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c4a:	07000613          	li	a2,112
    80001c4e:	4581                	li	a1,0
    80001c50:	06048513          	addi	a0,s1,96
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	06a080e7          	jalr	106(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c5c:	00000797          	auipc	a5,0x0
    80001c60:	db078793          	addi	a5,a5,-592 # 80001a0c <forkret>
    80001c64:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c66:	60bc                	ld	a5,64(s1)
    80001c68:	6705                	lui	a4,0x1
    80001c6a:	97ba                	add	a5,a5,a4
    80001c6c:	f4bc                	sd	a5,104(s1)
}
    80001c6e:	8526                	mv	a0,s1
    80001c70:	60e2                	ld	ra,24(sp)
    80001c72:	6442                	ld	s0,16(sp)
    80001c74:	64a2                	ld	s1,8(sp)
    80001c76:	6902                	ld	s2,0(sp)
    80001c78:	6105                	addi	sp,sp,32
    80001c7a:	8082                	ret
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	f08080e7          	jalr	-248(ra) # 80001b86 <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	fee080e7          	jalr	-18(ra) # 80000c76 <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	bff1                	j	80001c6e <allocproc+0x90>
    freeproc(p);
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	ef0080e7          	jalr	-272(ra) # 80001b86 <freeproc>
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	fd6080e7          	jalr	-42(ra) # 80000c76 <release>
    return 0;
    80001ca8:	84ca                	mv	s1,s2
    80001caa:	b7d1                	j	80001c6e <allocproc+0x90>

0000000080001cac <userinit>:
{
    80001cac:	1101                	addi	sp,sp,-32
    80001cae:	ec06                	sd	ra,24(sp)
    80001cb0:	e822                	sd	s0,16(sp)
    80001cb2:	e426                	sd	s1,8(sp)
    80001cb4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f28080e7          	jalr	-216(ra) # 80001bde <allocproc>
    80001cbe:	84aa                	mv	s1,a0
  initproc = p;
    80001cc0:	00008797          	auipc	a5,0x8
    80001cc4:	36a7b423          	sd	a0,872(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc8:	03400613          	li	a2,52
    80001ccc:	00008597          	auipc	a1,0x8
    80001cd0:	e6458593          	addi	a1,a1,-412 # 80009b30 <initcode>
    80001cd4:	6928                	ld	a0,80(a0)
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	676080e7          	jalr	1654(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001cde:	6785                	lui	a5,0x1
    80001ce0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce2:	6cb8                	ld	a4,88(s1)
    80001ce4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce8:	6cb8                	ld	a4,88(s1)
    80001cea:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cec:	4641                	li	a2,16
    80001cee:	00007597          	auipc	a1,0x7
    80001cf2:	4fa58593          	addi	a1,a1,1274 # 800091e8 <digits+0x1a8>
    80001cf6:	15848513          	addi	a0,s1,344
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	116080e7          	jalr	278(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001d02:	00007517          	auipc	a0,0x7
    80001d06:	4f650513          	addi	a0,a0,1270 # 800091f8 <digits+0x1b8>
    80001d0a:	00003097          	auipc	ra,0x3
    80001d0e:	a4a080e7          	jalr	-1462(ra) # 80004754 <namei>
    80001d12:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d16:	478d                	li	a5,3
    80001d18:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f5a080e7          	jalr	-166(ra) # 80000c76 <release>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <growproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	c98080e7          	jalr	-872(ra) # 800019d4 <myproc>
    80001d44:	892a                	mv	s2,a0
  sz = p->sz;
    80001d46:	652c                	ld	a1,72(a0)
    80001d48:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d4c:	00904f63          	bgtz	s1,80001d6a <growproc+0x3c>
  } else if(n < 0){
    80001d50:	0204cc63          	bltz	s1,80001d88 <growproc+0x5a>
  p->sz = sz;
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d5c:	4501                	li	a0,0
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6902                	ld	s2,0(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d6a:	9e25                	addw	a2,a2,s1
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	6be080e7          	jalr	1726(ra) # 80001434 <uvmalloc>
    80001d7e:	0005061b          	sext.w	a2,a0
    80001d82:	fa69                	bnez	a2,80001d54 <growproc+0x26>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bfe1                	j	80001d5e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	9e25                	addw	a2,a2,s1
    80001d8a:	1602                	slli	a2,a2,0x20
    80001d8c:	9201                	srli	a2,a2,0x20
    80001d8e:	1582                	slli	a1,a1,0x20
    80001d90:	9181                	srli	a1,a1,0x20
    80001d92:	6928                	ld	a0,80(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	62a080e7          	jalr	1578(ra) # 800013be <uvmdealloc>
    80001d9c:	0005061b          	sext.w	a2,a0
    80001da0:	bf55                	j	80001d54 <growproc+0x26>

0000000080001da2 <copy_swapFile>:
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001da2:	c559                	beqz	a0,80001e30 <copy_swapFile+0x8e>
int copy_swapFile(struct proc *src, struct proc *dst) {
    80001da4:	7139                	addi	sp,sp,-64
    80001da6:	fc06                	sd	ra,56(sp)
    80001da8:	f822                	sd	s0,48(sp)
    80001daa:	f426                	sd	s1,40(sp)
    80001dac:	f04a                	sd	s2,32(sp)
    80001dae:	ec4e                	sd	s3,24(sp)
    80001db0:	e852                	sd	s4,16(sp)
    80001db2:	e456                	sd	s5,8(sp)
    80001db4:	0080                	addi	s0,sp,64
    80001db6:	8a2a                	mv	s4,a0
    80001db8:	8aae                	mv	s5,a1
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001dba:	16853783          	ld	a5,360(a0)
    80001dbe:	cbbd                	beqz	a5,80001e34 <copy_swapFile+0x92>
    80001dc0:	cda5                	beqz	a1,80001e38 <copy_swapFile+0x96>
    80001dc2:	1685b783          	ld	a5,360(a1)
    80001dc6:	cbbd                	beqz	a5,80001e3c <copy_swapFile+0x9a>
  char *buffer = (char *)kalloc();
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	d0a080e7          	jalr	-758(ra) # 80000ad2 <kalloc>
    80001dd0:	89aa                	mv	s3,a0
  for (struct disk_page *disk_pg = src->disk_pages; disk_pg < &src->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001dd2:	270a0493          	addi	s1,s4,624
    80001dd6:	370a0913          	addi	s2,s4,880
    80001dda:	a021                	j	80001de2 <copy_swapFile+0x40>
    80001ddc:	04c1                	addi	s1,s1,16
    80001dde:	02990a63          	beq	s2,s1,80001e12 <copy_swapFile+0x70>
    if(disk_pg->used) {
    80001de2:	44dc                	lw	a5,12(s1)
    80001de4:	dfe5                	beqz	a5,80001ddc <copy_swapFile+0x3a>
      if (readFromSwapFile(src, buffer, disk_pg->offset, PGSIZE) < 0) {
    80001de6:	6685                	lui	a3,0x1
    80001de8:	4490                	lw	a2,8(s1)
    80001dea:	85ce                	mv	a1,s3
    80001dec:	8552                	mv	a0,s4
    80001dee:	00003097          	auipc	ra,0x3
    80001df2:	c8e080e7          	jalr	-882(ra) # 80004a7c <readFromSwapFile>
    80001df6:	04054563          	bltz	a0,80001e40 <copy_swapFile+0x9e>
      if (writeToSwapFile(dst, buffer, disk_pg->offset, PGSIZE) < 0) {
    80001dfa:	6685                	lui	a3,0x1
    80001dfc:	4490                	lw	a2,8(s1)
    80001dfe:	85ce                	mv	a1,s3
    80001e00:	8556                	mv	a0,s5
    80001e02:	00003097          	auipc	ra,0x3
    80001e06:	c56080e7          	jalr	-938(ra) # 80004a58 <writeToSwapFile>
    80001e0a:	fc0559e3          	bgez	a0,80001ddc <copy_swapFile+0x3a>
        return -1;
    80001e0e:	557d                	li	a0,-1
    80001e10:	a039                	j	80001e1e <copy_swapFile+0x7c>
  kfree((void *)buffer);
    80001e12:	854e                	mv	a0,s3
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	bc2080e7          	jalr	-1086(ra) # 800009d6 <kfree>
  return 0;
    80001e1c:	4501                	li	a0,0
}
    80001e1e:	70e2                	ld	ra,56(sp)
    80001e20:	7442                	ld	s0,48(sp)
    80001e22:	74a2                	ld	s1,40(sp)
    80001e24:	7902                	ld	s2,32(sp)
    80001e26:	69e2                	ld	s3,24(sp)
    80001e28:	6a42                	ld	s4,16(sp)
    80001e2a:	6aa2                	ld	s5,8(sp)
    80001e2c:	6121                	addi	sp,sp,64
    80001e2e:	8082                	ret
    return -1;
    80001e30:	557d                	li	a0,-1
}
    80001e32:	8082                	ret
    return -1;
    80001e34:	557d                	li	a0,-1
    80001e36:	b7e5                	j	80001e1e <copy_swapFile+0x7c>
    80001e38:	557d                	li	a0,-1
    80001e3a:	b7d5                	j	80001e1e <copy_swapFile+0x7c>
    80001e3c:	557d                	li	a0,-1
    80001e3e:	b7c5                	j	80001e1e <copy_swapFile+0x7c>
        return -1;
    80001e40:	557d                	li	a0,-1
    80001e42:	bff1                	j	80001e1e <copy_swapFile+0x7c>

0000000080001e44 <scheduler>:
{
    80001e44:	7139                	addi	sp,sp,-64
    80001e46:	fc06                	sd	ra,56(sp)
    80001e48:	f822                	sd	s0,48(sp)
    80001e4a:	f426                	sd	s1,40(sp)
    80001e4c:	f04a                	sd	s2,32(sp)
    80001e4e:	ec4e                	sd	s3,24(sp)
    80001e50:	e852                	sd	s4,16(sp)
    80001e52:	e456                	sd	s5,8(sp)
    80001e54:	e05a                	sd	s6,0(sp)
    80001e56:	0080                	addi	s0,sp,64
    80001e58:	8792                	mv	a5,tp
  int id = r_tp();
    80001e5a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e5c:	00779a93          	slli	s5,a5,0x7
    80001e60:	00010717          	auipc	a4,0x10
    80001e64:	44070713          	addi	a4,a4,1088 # 800122a0 <pid_lock>
    80001e68:	9756                	add	a4,a4,s5
    80001e6a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001e6e:	00010717          	auipc	a4,0x10
    80001e72:	46a70713          	addi	a4,a4,1130 # 800122d8 <cpus+0x8>
    80001e76:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001e78:	498d                	li	s3,3
        p->state = RUNNING;
    80001e7a:	4b11                	li	s6,4
        c->proc = p;
    80001e7c:	079e                	slli	a5,a5,0x7
    80001e7e:	00010a17          	auipc	s4,0x10
    80001e82:	422a0a13          	addi	s4,s4,1058 # 800122a0 <pid_lock>
    80001e86:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e88:	0001e917          	auipc	s2,0x1e
    80001e8c:	64890913          	addi	s2,s2,1608 # 800204d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e98:	10079073          	csrw	sstatus,a5
    80001e9c:	00011497          	auipc	s1,0x11
    80001ea0:	83448493          	addi	s1,s1,-1996 # 800126d0 <proc>
    80001ea4:	a811                	j	80001eb8 <scheduler+0x74>
      release(&p->lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	dce080e7          	jalr	-562(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eb0:	37848493          	addi	s1,s1,888
    80001eb4:	fd248ee3          	beq	s1,s2,80001e90 <scheduler+0x4c>
      acquire(&p->lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	d08080e7          	jalr	-760(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001ec2:	4c9c                	lw	a5,24(s1)
    80001ec4:	ff3791e3          	bne	a5,s3,80001ea6 <scheduler+0x62>
        p->state = RUNNING;
    80001ec8:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001ecc:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001ed0:	06048593          	addi	a1,s1,96
    80001ed4:	8556                	mv	a0,s5
    80001ed6:	00001097          	auipc	ra,0x1
    80001eda:	02c080e7          	jalr	44(ra) # 80002f02 <swtch>
        c->proc = 0;
    80001ede:	020a3823          	sd	zero,48(s4)
    80001ee2:	b7d1                	j	80001ea6 <scheduler+0x62>

0000000080001ee4 <sched>:
{
    80001ee4:	7179                	addi	sp,sp,-48
    80001ee6:	f406                	sd	ra,40(sp)
    80001ee8:	f022                	sd	s0,32(sp)
    80001eea:	ec26                	sd	s1,24(sp)
    80001eec:	e84a                	sd	s2,16(sp)
    80001eee:	e44e                	sd	s3,8(sp)
    80001ef0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ef2:	00000097          	auipc	ra,0x0
    80001ef6:	ae2080e7          	jalr	-1310(ra) # 800019d4 <myproc>
    80001efa:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	c4c080e7          	jalr	-948(ra) # 80000b48 <holding>
    80001f04:	c93d                	beqz	a0,80001f7a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f06:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f08:	2781                	sext.w	a5,a5
    80001f0a:	079e                	slli	a5,a5,0x7
    80001f0c:	00010717          	auipc	a4,0x10
    80001f10:	39470713          	addi	a4,a4,916 # 800122a0 <pid_lock>
    80001f14:	97ba                	add	a5,a5,a4
    80001f16:	0a87a703          	lw	a4,168(a5) # 10a8 <_entry-0x7fffef58>
    80001f1a:	4785                	li	a5,1
    80001f1c:	06f71763          	bne	a4,a5,80001f8a <sched+0xa6>
  if(p->state == RUNNING)
    80001f20:	4c98                	lw	a4,24(s1)
    80001f22:	4791                	li	a5,4
    80001f24:	06f70b63          	beq	a4,a5,80001f9a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f28:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f2c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f2e:	efb5                	bnez	a5,80001faa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f30:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f32:	00010917          	auipc	s2,0x10
    80001f36:	36e90913          	addi	s2,s2,878 # 800122a0 <pid_lock>
    80001f3a:	2781                	sext.w	a5,a5
    80001f3c:	079e                	slli	a5,a5,0x7
    80001f3e:	97ca                	add	a5,a5,s2
    80001f40:	0ac7a983          	lw	s3,172(a5)
    80001f44:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f46:	2781                	sext.w	a5,a5
    80001f48:	079e                	slli	a5,a5,0x7
    80001f4a:	00010597          	auipc	a1,0x10
    80001f4e:	38e58593          	addi	a1,a1,910 # 800122d8 <cpus+0x8>
    80001f52:	95be                	add	a1,a1,a5
    80001f54:	06048513          	addi	a0,s1,96
    80001f58:	00001097          	auipc	ra,0x1
    80001f5c:	faa080e7          	jalr	-86(ra) # 80002f02 <swtch>
    80001f60:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f62:	2781                	sext.w	a5,a5
    80001f64:	079e                	slli	a5,a5,0x7
    80001f66:	97ca                	add	a5,a5,s2
    80001f68:	0b37a623          	sw	s3,172(a5)
}
    80001f6c:	70a2                	ld	ra,40(sp)
    80001f6e:	7402                	ld	s0,32(sp)
    80001f70:	64e2                	ld	s1,24(sp)
    80001f72:	6942                	ld	s2,16(sp)
    80001f74:	69a2                	ld	s3,8(sp)
    80001f76:	6145                	addi	sp,sp,48
    80001f78:	8082                	ret
    panic("sched p->lock");
    80001f7a:	00007517          	auipc	a0,0x7
    80001f7e:	28650513          	addi	a0,a0,646 # 80009200 <digits+0x1c0>
    80001f82:	ffffe097          	auipc	ra,0xffffe
    80001f86:	5a8080e7          	jalr	1448(ra) # 8000052a <panic>
    panic("sched locks");
    80001f8a:	00007517          	auipc	a0,0x7
    80001f8e:	28650513          	addi	a0,a0,646 # 80009210 <digits+0x1d0>
    80001f92:	ffffe097          	auipc	ra,0xffffe
    80001f96:	598080e7          	jalr	1432(ra) # 8000052a <panic>
    panic("sched running");
    80001f9a:	00007517          	auipc	a0,0x7
    80001f9e:	28650513          	addi	a0,a0,646 # 80009220 <digits+0x1e0>
    80001fa2:	ffffe097          	auipc	ra,0xffffe
    80001fa6:	588080e7          	jalr	1416(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001faa:	00007517          	auipc	a0,0x7
    80001fae:	28650513          	addi	a0,a0,646 # 80009230 <digits+0x1f0>
    80001fb2:	ffffe097          	auipc	ra,0xffffe
    80001fb6:	578080e7          	jalr	1400(ra) # 8000052a <panic>

0000000080001fba <yield>:
{
    80001fba:	1101                	addi	sp,sp,-32
    80001fbc:	ec06                	sd	ra,24(sp)
    80001fbe:	e822                	sd	s0,16(sp)
    80001fc0:	e426                	sd	s1,8(sp)
    80001fc2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	a10080e7          	jalr	-1520(ra) # 800019d4 <myproc>
    80001fcc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	bf4080e7          	jalr	-1036(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80001fd6:	478d                	li	a5,3
    80001fd8:	cc9c                	sw	a5,24(s1)
  sched();
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	f0a080e7          	jalr	-246(ra) # 80001ee4 <sched>
  release(&p->lock);
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	c92080e7          	jalr	-878(ra) # 80000c76 <release>
}
    80001fec:	60e2                	ld	ra,24(sp)
    80001fee:	6442                	ld	s0,16(sp)
    80001ff0:	64a2                	ld	s1,8(sp)
    80001ff2:	6105                	addi	sp,sp,32
    80001ff4:	8082                	ret

0000000080001ff6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001ff6:	7179                	addi	sp,sp,-48
    80001ff8:	f406                	sd	ra,40(sp)
    80001ffa:	f022                	sd	s0,32(sp)
    80001ffc:	ec26                	sd	s1,24(sp)
    80001ffe:	e84a                	sd	s2,16(sp)
    80002000:	e44e                	sd	s3,8(sp)
    80002002:	1800                	addi	s0,sp,48
    80002004:	89aa                	mv	s3,a0
    80002006:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	9cc080e7          	jalr	-1588(ra) # 800019d4 <myproc>
    80002010:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	bb0080e7          	jalr	-1104(ra) # 80000bc2 <acquire>
  release(lk);
    8000201a:	854a                	mv	a0,s2
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	c5a080e7          	jalr	-934(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002024:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002028:	4789                	li	a5,2
    8000202a:	cc9c                	sw	a5,24(s1)

  sched();
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	eb8080e7          	jalr	-328(ra) # 80001ee4 <sched>

  // Tidy up.
  p->chan = 0;
    80002034:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c3c080e7          	jalr	-964(ra) # 80000c76 <release>
  acquire(lk);
    80002042:	854a                	mv	a0,s2
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	b7e080e7          	jalr	-1154(ra) # 80000bc2 <acquire>
}
    8000204c:	70a2                	ld	ra,40(sp)
    8000204e:	7402                	ld	s0,32(sp)
    80002050:	64e2                	ld	s1,24(sp)
    80002052:	6942                	ld	s2,16(sp)
    80002054:	69a2                	ld	s3,8(sp)
    80002056:	6145                	addi	sp,sp,48
    80002058:	8082                	ret

000000008000205a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000205a:	7139                	addi	sp,sp,-64
    8000205c:	fc06                	sd	ra,56(sp)
    8000205e:	f822                	sd	s0,48(sp)
    80002060:	f426                	sd	s1,40(sp)
    80002062:	f04a                	sd	s2,32(sp)
    80002064:	ec4e                	sd	s3,24(sp)
    80002066:	e852                	sd	s4,16(sp)
    80002068:	e456                	sd	s5,8(sp)
    8000206a:	0080                	addi	s0,sp,64
    8000206c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000206e:	00010497          	auipc	s1,0x10
    80002072:	66248493          	addi	s1,s1,1634 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002076:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002078:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000207a:	0001e917          	auipc	s2,0x1e
    8000207e:	45690913          	addi	s2,s2,1110 # 800204d0 <tickslock>
    80002082:	a811                	j	80002096 <wakeup+0x3c>
      }
      release(&p->lock);
    80002084:	8526                	mv	a0,s1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	bf0080e7          	jalr	-1040(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000208e:	37848493          	addi	s1,s1,888
    80002092:	03248663          	beq	s1,s2,800020be <wakeup+0x64>
    if(p != myproc()){
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	93e080e7          	jalr	-1730(ra) # 800019d4 <myproc>
    8000209e:	fea488e3          	beq	s1,a0,8000208e <wakeup+0x34>
      acquire(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b1e080e7          	jalr	-1250(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800020ac:	4c9c                	lw	a5,24(s1)
    800020ae:	fd379be3          	bne	a5,s3,80002084 <wakeup+0x2a>
    800020b2:	709c                	ld	a5,32(s1)
    800020b4:	fd4798e3          	bne	a5,s4,80002084 <wakeup+0x2a>
        p->state = RUNNABLE;
    800020b8:	0154ac23          	sw	s5,24(s1)
    800020bc:	b7e1                	j	80002084 <wakeup+0x2a>
    }
  }
}
    800020be:	70e2                	ld	ra,56(sp)
    800020c0:	7442                	ld	s0,48(sp)
    800020c2:	74a2                	ld	s1,40(sp)
    800020c4:	7902                	ld	s2,32(sp)
    800020c6:	69e2                	ld	s3,24(sp)
    800020c8:	6a42                	ld	s4,16(sp)
    800020ca:	6aa2                	ld	s5,8(sp)
    800020cc:	6121                	addi	sp,sp,64
    800020ce:	8082                	ret

00000000800020d0 <reparent>:
{
    800020d0:	7179                	addi	sp,sp,-48
    800020d2:	f406                	sd	ra,40(sp)
    800020d4:	f022                	sd	s0,32(sp)
    800020d6:	ec26                	sd	s1,24(sp)
    800020d8:	e84a                	sd	s2,16(sp)
    800020da:	e44e                	sd	s3,8(sp)
    800020dc:	e052                	sd	s4,0(sp)
    800020de:	1800                	addi	s0,sp,48
    800020e0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020e2:	00010497          	auipc	s1,0x10
    800020e6:	5ee48493          	addi	s1,s1,1518 # 800126d0 <proc>
      pp->parent = initproc;
    800020ea:	00008a17          	auipc	s4,0x8
    800020ee:	f3ea0a13          	addi	s4,s4,-194 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020f2:	0001e997          	auipc	s3,0x1e
    800020f6:	3de98993          	addi	s3,s3,990 # 800204d0 <tickslock>
    800020fa:	a029                	j	80002104 <reparent+0x34>
    800020fc:	37848493          	addi	s1,s1,888
    80002100:	01348d63          	beq	s1,s3,8000211a <reparent+0x4a>
    if(pp->parent == p){
    80002104:	7c9c                	ld	a5,56(s1)
    80002106:	ff279be3          	bne	a5,s2,800020fc <reparent+0x2c>
      pp->parent = initproc;
    8000210a:	000a3503          	ld	a0,0(s4)
    8000210e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002110:	00000097          	auipc	ra,0x0
    80002114:	f4a080e7          	jalr	-182(ra) # 8000205a <wakeup>
    80002118:	b7d5                	j	800020fc <reparent+0x2c>
}
    8000211a:	70a2                	ld	ra,40(sp)
    8000211c:	7402                	ld	s0,32(sp)
    8000211e:	64e2                	ld	s1,24(sp)
    80002120:	6942                	ld	s2,16(sp)
    80002122:	69a2                	ld	s3,8(sp)
    80002124:	6a02                	ld	s4,0(sp)
    80002126:	6145                	addi	sp,sp,48
    80002128:	8082                	ret

000000008000212a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000212a:	7179                	addi	sp,sp,-48
    8000212c:	f406                	sd	ra,40(sp)
    8000212e:	f022                	sd	s0,32(sp)
    80002130:	ec26                	sd	s1,24(sp)
    80002132:	e84a                	sd	s2,16(sp)
    80002134:	e44e                	sd	s3,8(sp)
    80002136:	1800                	addi	s0,sp,48
    80002138:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000213a:	00010497          	auipc	s1,0x10
    8000213e:	59648493          	addi	s1,s1,1430 # 800126d0 <proc>
    80002142:	0001e997          	auipc	s3,0x1e
    80002146:	38e98993          	addi	s3,s3,910 # 800204d0 <tickslock>
    acquire(&p->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	a76080e7          	jalr	-1418(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002154:	589c                	lw	a5,48(s1)
    80002156:	01278d63          	beq	a5,s2,80002170 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	b1a080e7          	jalr	-1254(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002164:	37848493          	addi	s1,s1,888
    80002168:	ff3491e3          	bne	s1,s3,8000214a <kill+0x20>
  }
  return -1;
    8000216c:	557d                	li	a0,-1
    8000216e:	a829                	j	80002188 <kill+0x5e>
      p->killed = 1;
    80002170:	4785                	li	a5,1
    80002172:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002174:	4c98                	lw	a4,24(s1)
    80002176:	4789                	li	a5,2
    80002178:	00f70f63          	beq	a4,a5,80002196 <kill+0x6c>
      release(&p->lock);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	af8080e7          	jalr	-1288(ra) # 80000c76 <release>
      return 0;
    80002186:	4501                	li	a0,0
}
    80002188:	70a2                	ld	ra,40(sp)
    8000218a:	7402                	ld	s0,32(sp)
    8000218c:	64e2                	ld	s1,24(sp)
    8000218e:	6942                	ld	s2,16(sp)
    80002190:	69a2                	ld	s3,8(sp)
    80002192:	6145                	addi	sp,sp,48
    80002194:	8082                	ret
        p->state = RUNNABLE;
    80002196:	478d                	li	a5,3
    80002198:	cc9c                	sw	a5,24(s1)
    8000219a:	b7cd                	j	8000217c <kill+0x52>

000000008000219c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000219c:	7179                	addi	sp,sp,-48
    8000219e:	f406                	sd	ra,40(sp)
    800021a0:	f022                	sd	s0,32(sp)
    800021a2:	ec26                	sd	s1,24(sp)
    800021a4:	e84a                	sd	s2,16(sp)
    800021a6:	e44e                	sd	s3,8(sp)
    800021a8:	e052                	sd	s4,0(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	84aa                	mv	s1,a0
    800021ae:	892e                	mv	s2,a1
    800021b0:	89b2                	mv	s3,a2
    800021b2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800021b4:	00000097          	auipc	ra,0x0
    800021b8:	820080e7          	jalr	-2016(ra) # 800019d4 <myproc>
  if(user_dst){
    800021bc:	c08d                	beqz	s1,800021de <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800021be:	86d2                	mv	a3,s4
    800021c0:	864e                	mv	a2,s3
    800021c2:	85ca                	mv	a1,s2
    800021c4:	6928                	ld	a0,80(a0)
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	4ce080e7          	jalr	1230(ra) # 80001694 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800021ce:	70a2                	ld	ra,40(sp)
    800021d0:	7402                	ld	s0,32(sp)
    800021d2:	64e2                	ld	s1,24(sp)
    800021d4:	6942                	ld	s2,16(sp)
    800021d6:	69a2                	ld	s3,8(sp)
    800021d8:	6a02                	ld	s4,0(sp)
    800021da:	6145                	addi	sp,sp,48
    800021dc:	8082                	ret
    memmove((char *)dst, src, len);
    800021de:	000a061b          	sext.w	a2,s4
    800021e2:	85ce                	mv	a1,s3
    800021e4:	854a                	mv	a0,s2
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	b34080e7          	jalr	-1228(ra) # 80000d1a <memmove>
    return 0;
    800021ee:	8526                	mv	a0,s1
    800021f0:	bff9                	j	800021ce <either_copyout+0x32>

00000000800021f2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800021f2:	7179                	addi	sp,sp,-48
    800021f4:	f406                	sd	ra,40(sp)
    800021f6:	f022                	sd	s0,32(sp)
    800021f8:	ec26                	sd	s1,24(sp)
    800021fa:	e84a                	sd	s2,16(sp)
    800021fc:	e44e                	sd	s3,8(sp)
    800021fe:	e052                	sd	s4,0(sp)
    80002200:	1800                	addi	s0,sp,48
    80002202:	892a                	mv	s2,a0
    80002204:	84ae                	mv	s1,a1
    80002206:	89b2                	mv	s3,a2
    80002208:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	7ca080e7          	jalr	1994(ra) # 800019d4 <myproc>
  if(user_src){
    80002212:	c08d                	beqz	s1,80002234 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002214:	86d2                	mv	a3,s4
    80002216:	864e                	mv	a2,s3
    80002218:	85ca                	mv	a1,s2
    8000221a:	6928                	ld	a0,80(a0)
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	504080e7          	jalr	1284(ra) # 80001720 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002224:	70a2                	ld	ra,40(sp)
    80002226:	7402                	ld	s0,32(sp)
    80002228:	64e2                	ld	s1,24(sp)
    8000222a:	6942                	ld	s2,16(sp)
    8000222c:	69a2                	ld	s3,8(sp)
    8000222e:	6a02                	ld	s4,0(sp)
    80002230:	6145                	addi	sp,sp,48
    80002232:	8082                	ret
    memmove(dst, (char*)src, len);
    80002234:	000a061b          	sext.w	a2,s4
    80002238:	85ce                	mv	a1,s3
    8000223a:	854a                	mv	a0,s2
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	ade080e7          	jalr	-1314(ra) # 80000d1a <memmove>
    return 0;
    80002244:	8526                	mv	a0,s1
    80002246:	bff9                	j	80002224 <either_copyin+0x32>

0000000080002248 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002248:	715d                	addi	sp,sp,-80
    8000224a:	e486                	sd	ra,72(sp)
    8000224c:	e0a2                	sd	s0,64(sp)
    8000224e:	fc26                	sd	s1,56(sp)
    80002250:	f84a                	sd	s2,48(sp)
    80002252:	f44e                	sd	s3,40(sp)
    80002254:	f052                	sd	s4,32(sp)
    80002256:	ec56                	sd	s5,24(sp)
    80002258:	e85a                	sd	s6,16(sp)
    8000225a:	e45e                	sd	s7,8(sp)
    8000225c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000225e:	00007517          	auipc	a0,0x7
    80002262:	e6a50513          	addi	a0,a0,-406 # 800090c8 <digits+0x88>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	30e080e7          	jalr	782(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	00010497          	auipc	s1,0x10
    80002272:	5ba48493          	addi	s1,s1,1466 # 80012828 <proc+0x158>
    80002276:	0001e917          	auipc	s2,0x1e
    8000227a:	3b290913          	addi	s2,s2,946 # 80020628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000227e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002280:	00007997          	auipc	s3,0x7
    80002284:	fc898993          	addi	s3,s3,-56 # 80009248 <digits+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    80002288:	00007a97          	auipc	s5,0x7
    8000228c:	fc8a8a93          	addi	s5,s5,-56 # 80009250 <digits+0x210>
    printf("\n");
    80002290:	00007a17          	auipc	s4,0x7
    80002294:	e38a0a13          	addi	s4,s4,-456 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002298:	00007b97          	auipc	s7,0x7
    8000229c:	2f8b8b93          	addi	s7,s7,760 # 80009590 <states.0>
    800022a0:	a00d                	j	800022c2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800022a2:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    800022a6:	8556                	mv	a0,s5
    800022a8:	ffffe097          	auipc	ra,0xffffe
    800022ac:	2cc080e7          	jalr	716(ra) # 80000574 <printf>
    printf("\n");
    800022b0:	8552                	mv	a0,s4
    800022b2:	ffffe097          	auipc	ra,0xffffe
    800022b6:	2c2080e7          	jalr	706(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ba:	37848493          	addi	s1,s1,888
    800022be:	03248263          	beq	s1,s2,800022e2 <procdump+0x9a>
    if(p->state == UNUSED)
    800022c2:	86a6                	mv	a3,s1
    800022c4:	ec04a783          	lw	a5,-320(s1)
    800022c8:	dbed                	beqz	a5,800022ba <procdump+0x72>
      state = "???";
    800022ca:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022cc:	fcfb6be3          	bltu	s6,a5,800022a2 <procdump+0x5a>
    800022d0:	02079713          	slli	a4,a5,0x20
    800022d4:	01d75793          	srli	a5,a4,0x1d
    800022d8:	97de                	add	a5,a5,s7
    800022da:	6390                	ld	a2,0(a5)
    800022dc:	f279                	bnez	a2,800022a2 <procdump+0x5a>
      state = "???";
    800022de:	864e                	mv	a2,s3
    800022e0:	b7c9                	j	800022a2 <procdump+0x5a>
  }
}
    800022e2:	60a6                	ld	ra,72(sp)
    800022e4:	6406                	ld	s0,64(sp)
    800022e6:	74e2                	ld	s1,56(sp)
    800022e8:	7942                	ld	s2,48(sp)
    800022ea:	79a2                	ld	s3,40(sp)
    800022ec:	7a02                	ld	s4,32(sp)
    800022ee:	6ae2                	ld	s5,24(sp)
    800022f0:	6b42                	ld	s6,16(sp)
    800022f2:	6ba2                	ld	s7,8(sp)
    800022f4:	6161                	addi	sp,sp,80
    800022f6:	8082                	ret

00000000800022f8 <fill_swapFile>:

// ADDED Q1
int fill_swapFile(struct proc *p)
{
    800022f8:	7179                	addi	sp,sp,-48
    800022fa:	f406                	sd	ra,40(sp)
    800022fc:	f022                	sd	s0,32(sp)
    800022fe:	ec26                	sd	s1,24(sp)
    80002300:	e84a                	sd	s2,16(sp)
    80002302:	e44e                	sd	s3,8(sp)
    80002304:	e052                	sd	s4,0(sp)
    80002306:	1800                	addi	s0,sp,48
    80002308:	892a                	mv	s2,a0
  char *page = kalloc();
    8000230a:	ffffe097          	auipc	ra,0xffffe
    8000230e:	7c8080e7          	jalr	1992(ra) # 80000ad2 <kalloc>
    80002312:	89aa                	mv	s3,a0
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80002314:	27090493          	addi	s1,s2,624
    80002318:	37090a13          	addi	s4,s2,880
    if (writeToSwapFile(p, page, disk_pg->offset, PGSIZE) < 0) {
    8000231c:	6685                	lui	a3,0x1
    8000231e:	4490                	lw	a2,8(s1)
    80002320:	85ce                	mv	a1,s3
    80002322:	854a                	mv	a0,s2
    80002324:	00002097          	auipc	ra,0x2
    80002328:	734080e7          	jalr	1844(ra) # 80004a58 <writeToSwapFile>
    8000232c:	02054363          	bltz	a0,80002352 <fill_swapFile+0x5a>
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80002330:	04c1                	addi	s1,s1,16
    80002332:	fe9a15e3          	bne	s4,s1,8000231c <fill_swapFile+0x24>
      return -1;
    }
  }
  kfree(page);
    80002336:	854e                	mv	a0,s3
    80002338:	ffffe097          	auipc	ra,0xffffe
    8000233c:	69e080e7          	jalr	1694(ra) # 800009d6 <kfree>
  return 0;
    80002340:	4501                	li	a0,0
}
    80002342:	70a2                	ld	ra,40(sp)
    80002344:	7402                	ld	s0,32(sp)
    80002346:	64e2                	ld	s1,24(sp)
    80002348:	6942                	ld	s2,16(sp)
    8000234a:	69a2                	ld	s3,8(sp)
    8000234c:	6a02                	ld	s4,0(sp)
    8000234e:	6145                	addi	sp,sp,48
    80002350:	8082                	ret
      return -1;
    80002352:	557d                	li	a0,-1
    80002354:	b7fd                	j	80002342 <fill_swapFile+0x4a>

0000000080002356 <init_metadata>:

// ADDED Q1 - p->lock must not be held because of createSwapFile!
int init_metadata(struct proc *p)
{
    80002356:	1101                	addi	sp,sp,-32
    80002358:	ec06                	sd	ra,24(sp)
    8000235a:	e822                	sd	s0,16(sp)
    8000235c:	e426                	sd	s1,8(sp)
    8000235e:	1000                	addi	s0,sp,32
    80002360:	84aa                	mv	s1,a0
  if (!p->swapFile && createSwapFile(p) < 0) {
    80002362:	16853783          	ld	a5,360(a0)
    80002366:	cbb9                	beqz	a5,800023bc <init_metadata+0x66>
    return -1;
  }
  if (fill_swapFile(p) < 0) {
    80002368:	8526                	mv	a0,s1
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	f8e080e7          	jalr	-114(ra) # 800022f8 <fill_swapFile>
    80002372:	04054d63          	bltz	a0,800023cc <init_metadata+0x76>
    80002376:	17048793          	addi	a5,s1,368
    8000237a:	27048713          	addi	a4,s1,624
    return -1;
  }
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    p->ram_pages[i].va = 0;
    8000237e:	0007b023          	sd	zero,0(a5)
    p->ram_pages[i].age = 0; // ADDED Q2
    80002382:	0007a423          	sw	zero,8(a5)
    p->ram_pages[i].used = 0;
    80002386:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000238a:	07c1                	addi	a5,a5,16
    8000238c:	fee799e3          	bne	a5,a4,8000237e <init_metadata+0x28>
    80002390:	27048793          	addi	a5,s1,624
    80002394:	4701                	li	a4,0
  }
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002396:	6605                	lui	a2,0x1
    80002398:	66c1                	lui	a3,0x10
    p->disk_pages[i].va = 0;
    8000239a:	0007b023          	sd	zero,0(a5)
    p->disk_pages[i].offset = i * PGSIZE;
    8000239e:	c798                	sw	a4,8(a5)
    p->disk_pages[i].used = 0;
    800023a0:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    800023a4:	07c1                	addi	a5,a5,16
    800023a6:	9f31                	addw	a4,a4,a2
    800023a8:	fed719e3          	bne	a4,a3,8000239a <init_metadata+0x44>
  }
  p->scfifo_index = 0; // ADDED Q2
    800023ac:	3604a823          	sw	zero,880(s1)
  return 0;
    800023b0:	4501                	li	a0,0
}
    800023b2:	60e2                	ld	ra,24(sp)
    800023b4:	6442                	ld	s0,16(sp)
    800023b6:	64a2                	ld	s1,8(sp)
    800023b8:	6105                	addi	sp,sp,32
    800023ba:	8082                	ret
  if (!p->swapFile && createSwapFile(p) < 0) {
    800023bc:	00002097          	auipc	ra,0x2
    800023c0:	5ec080e7          	jalr	1516(ra) # 800049a8 <createSwapFile>
    800023c4:	fa0552e3          	bgez	a0,80002368 <init_metadata+0x12>
    return -1;
    800023c8:	557d                	li	a0,-1
    800023ca:	b7e5                	j	800023b2 <init_metadata+0x5c>
    return -1;
    800023cc:	557d                	li	a0,-1
    800023ce:	b7d5                	j	800023b2 <init_metadata+0x5c>

00000000800023d0 <free_metadata>:

// p->lock must not be held because of removeSwapFile!
void free_metadata(struct proc *p)
{
    800023d0:	1101                	addi	sp,sp,-32
    800023d2:	ec06                	sd	ra,24(sp)
    800023d4:	e822                	sd	s0,16(sp)
    800023d6:	e426                	sd	s1,8(sp)
    800023d8:	1000                	addi	s0,sp,32
    800023da:	84aa                	mv	s1,a0
    if (p->swapFile && removeSwapFile(p) < 0) {
    800023dc:	16853783          	ld	a5,360(a0)
    800023e0:	c799                	beqz	a5,800023ee <free_metadata+0x1e>
    800023e2:	00002097          	auipc	ra,0x2
    800023e6:	41e080e7          	jalr	1054(ra) # 80004800 <removeSwapFile>
    800023ea:	04054563          	bltz	a0,80002434 <free_metadata+0x64>
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;
    800023ee:	1604b423          	sd	zero,360(s1)

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800023f2:	17048793          	addi	a5,s1,368
    800023f6:	27048713          	addi	a4,s1,624
      p->ram_pages[i].va = 0;
    800023fa:	0007b023          	sd	zero,0(a5)
      p->ram_pages[i].age = 0; // ADDED Q2
    800023fe:	0007a423          	sw	zero,8(a5)
      p->ram_pages[i].used = 0;
    80002402:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002406:	07c1                	addi	a5,a5,16
    80002408:	fee799e3          	bne	a5,a4,800023fa <free_metadata+0x2a>
    8000240c:	27048793          	addi	a5,s1,624
    80002410:	37048713          	addi	a4,s1,880
    }
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
      p->disk_pages[i].va = 0;
    80002414:	0007b023          	sd	zero,0(a5)
      p->disk_pages[i].offset = 0;
    80002418:	0007a423          	sw	zero,8(a5)
      p->disk_pages[i].used = 0;
    8000241c:	0007a623          	sw	zero,12(a5)
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002420:	07c1                	addi	a5,a5,16
    80002422:	fee799e3          	bne	a5,a4,80002414 <free_metadata+0x44>
    }
    p->scfifo_index = 0; // ADDED Q2
    80002426:	3604a823          	sw	zero,880(s1)
}
    8000242a:	60e2                	ld	ra,24(sp)
    8000242c:	6442                	ld	s0,16(sp)
    8000242e:	64a2                	ld	s1,8(sp)
    80002430:	6105                	addi	sp,sp,32
    80002432:	8082                	ret
      panic("free_metadata: removeSwapFile failed");
    80002434:	00007517          	auipc	a0,0x7
    80002438:	e2c50513          	addi	a0,a0,-468 # 80009260 <digits+0x220>
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	0ee080e7          	jalr	238(ra) # 8000052a <panic>

0000000080002444 <fork>:
{
    80002444:	7139                	addi	sp,sp,-64
    80002446:	fc06                	sd	ra,56(sp)
    80002448:	f822                	sd	s0,48(sp)
    8000244a:	f426                	sd	s1,40(sp)
    8000244c:	f04a                	sd	s2,32(sp)
    8000244e:	ec4e                	sd	s3,24(sp)
    80002450:	e852                	sd	s4,16(sp)
    80002452:	e456                	sd	s5,8(sp)
    80002454:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	57e080e7          	jalr	1406(ra) # 800019d4 <myproc>
    8000245e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	77e080e7          	jalr	1918(ra) # 80001bde <allocproc>
    80002468:	1c050663          	beqz	a0,80002634 <fork+0x1f0>
    8000246c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000246e:	048ab603          	ld	a2,72(s5)
    80002472:	692c                	ld	a1,80(a0)
    80002474:	050ab503          	ld	a0,80(s5)
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	112080e7          	jalr	274(ra) # 8000158a <uvmcopy>
    80002480:	04054863          	bltz	a0,800024d0 <fork+0x8c>
  np->sz = p->sz;
    80002484:	048ab783          	ld	a5,72(s5)
    80002488:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    8000248c:	058ab683          	ld	a3,88(s5)
    80002490:	87b6                	mv	a5,a3
    80002492:	0589b703          	ld	a4,88(s3)
    80002496:	12068693          	addi	a3,a3,288 # 10120 <_entry-0x7ffefee0>
    8000249a:	0007b803          	ld	a6,0(a5)
    8000249e:	6788                	ld	a0,8(a5)
    800024a0:	6b8c                	ld	a1,16(a5)
    800024a2:	6f90                	ld	a2,24(a5)
    800024a4:	01073023          	sd	a6,0(a4)
    800024a8:	e708                	sd	a0,8(a4)
    800024aa:	eb0c                	sd	a1,16(a4)
    800024ac:	ef10                	sd	a2,24(a4)
    800024ae:	02078793          	addi	a5,a5,32
    800024b2:	02070713          	addi	a4,a4,32
    800024b6:	fed792e3          	bne	a5,a3,8000249a <fork+0x56>
  np->trapframe->a0 = 0;
    800024ba:	0589b783          	ld	a5,88(s3)
    800024be:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800024c2:	0d0a8493          	addi	s1,s5,208
    800024c6:	0d098913          	addi	s2,s3,208
    800024ca:	150a8a13          	addi	s4,s5,336
    800024ce:	a00d                	j	800024f0 <fork+0xac>
    freeproc(np);
    800024d0:	854e                	mv	a0,s3
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	6b4080e7          	jalr	1716(ra) # 80001b86 <freeproc>
    release(&np->lock);
    800024da:	854e                	mv	a0,s3
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	79a080e7          	jalr	1946(ra) # 80000c76 <release>
    return -1;
    800024e4:	54fd                	li	s1,-1
    800024e6:	a8f1                	j	800025c2 <fork+0x17e>
  for(i = 0; i < NOFILE; i++)
    800024e8:	04a1                	addi	s1,s1,8
    800024ea:	0921                	addi	s2,s2,8
    800024ec:	01448b63          	beq	s1,s4,80002502 <fork+0xbe>
    if(p->ofile[i])
    800024f0:	6088                	ld	a0,0(s1)
    800024f2:	d97d                	beqz	a0,800024e8 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800024f4:	00003097          	auipc	ra,0x3
    800024f8:	c0c080e7          	jalr	-1012(ra) # 80005100 <filedup>
    800024fc:	00a93023          	sd	a0,0(s2)
    80002500:	b7e5                	j	800024e8 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002502:	150ab503          	ld	a0,336(s5)
    80002506:	00002097          	auipc	ra,0x2
    8000250a:	a5a080e7          	jalr	-1446(ra) # 80003f60 <idup>
    8000250e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002512:	4641                	li	a2,16
    80002514:	158a8593          	addi	a1,s5,344
    80002518:	15898513          	addi	a0,s3,344
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	8f4080e7          	jalr	-1804(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002524:	0309a483          	lw	s1,48(s3)
  if (relevant_metadata_proc(np)) {
    80002528:	fff4871b          	addiw	a4,s1,-1
    8000252c:	4785                	li	a5,1
    8000252e:	0ae7e463          	bltu	a5,a4,800025d6 <fork+0x192>
    }
  }
}

int relevant_metadata_proc(struct proc *p) {
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002532:	030aa783          	lw	a5,48(s5)
  if (relevant_metadata_proc(p)) {
    80002536:	37fd                	addiw	a5,a5,-1
    80002538:	4705                	li	a4,1
    8000253a:	04f77263          	bgeu	a4,a5,8000257e <fork+0x13a>
    if (copy_swapFile(p, np) < 0) {
    8000253e:	85ce                	mv	a1,s3
    80002540:	8556                	mv	a0,s5
    80002542:	00000097          	auipc	ra,0x0
    80002546:	860080e7          	jalr	-1952(ra) # 80001da2 <copy_swapFile>
    8000254a:	0c054463          	bltz	a0,80002612 <fork+0x1ce>
    memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
    8000254e:	10000613          	li	a2,256
    80002552:	170a8593          	addi	a1,s5,368
    80002556:	17098513          	addi	a0,s3,368
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	7c0080e7          	jalr	1984(ra) # 80000d1a <memmove>
    memmove(np->disk_pages, p->disk_pages, sizeof(p->disk_pages));
    80002562:	10000613          	li	a2,256
    80002566:	270a8593          	addi	a1,s5,624
    8000256a:	27098513          	addi	a0,s3,624
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	7ac080e7          	jalr	1964(ra) # 80000d1a <memmove>
    np->scfifo_index = p->scfifo_index; // ADDED Q2
    80002576:	370aa783          	lw	a5,880(s5)
    8000257a:	36f9a823          	sw	a5,880(s3)
  release(&np->lock);
    8000257e:	854e                	mv	a0,s3
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	6f6080e7          	jalr	1782(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80002588:	00010917          	auipc	s2,0x10
    8000258c:	d3090913          	addi	s2,s2,-720 # 800122b8 <wait_lock>
    80002590:	854a                	mv	a0,s2
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	630080e7          	jalr	1584(ra) # 80000bc2 <acquire>
  np->parent = p;
    8000259a:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    8000259e:	854a                	mv	a0,s2
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	6d6080e7          	jalr	1750(ra) # 80000c76 <release>
  acquire(&np->lock);
    800025a8:	854e                	mv	a0,s3
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	618080e7          	jalr	1560(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    800025b2:	478d                	li	a5,3
    800025b4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800025b8:	854e                	mv	a0,s3
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	6bc080e7          	jalr	1724(ra) # 80000c76 <release>
}
    800025c2:	8526                	mv	a0,s1
    800025c4:	70e2                	ld	ra,56(sp)
    800025c6:	7442                	ld	s0,48(sp)
    800025c8:	74a2                	ld	s1,40(sp)
    800025ca:	7902                	ld	s2,32(sp)
    800025cc:	69e2                	ld	s3,24(sp)
    800025ce:	6a42                	ld	s4,16(sp)
    800025d0:	6aa2                	ld	s5,8(sp)
    800025d2:	6121                	addi	sp,sp,64
    800025d4:	8082                	ret
    release(&np->lock);
    800025d6:	854e                	mv	a0,s3
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	69e080e7          	jalr	1694(ra) # 80000c76 <release>
    if (init_metadata(np) < 0) {
    800025e0:	854e                	mv	a0,s3
    800025e2:	00000097          	auipc	ra,0x0
    800025e6:	d74080e7          	jalr	-652(ra) # 80002356 <init_metadata>
    800025ea:	00054863          	bltz	a0,800025fa <fork+0x1b6>
    acquire(&np->lock);
    800025ee:	854e                	mv	a0,s3
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	5d2080e7          	jalr	1490(ra) # 80000bc2 <acquire>
    800025f8:	bf2d                	j	80002532 <fork+0xee>
      freeproc(np);
    800025fa:	854e                	mv	a0,s3
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	58a080e7          	jalr	1418(ra) # 80001b86 <freeproc>
      release(&np->lock);
    80002604:	854e                	mv	a0,s3
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	670080e7          	jalr	1648(ra) # 80000c76 <release>
      return -1;
    8000260e:	54fd                	li	s1,-1
    80002610:	bf4d                	j	800025c2 <fork+0x17e>
      freeproc(np);
    80002612:	854e                	mv	a0,s3
    80002614:	fffff097          	auipc	ra,0xfffff
    80002618:	572080e7          	jalr	1394(ra) # 80001b86 <freeproc>
      release(&np->lock);
    8000261c:	854e                	mv	a0,s3
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	658080e7          	jalr	1624(ra) # 80000c76 <release>
      free_metadata(np);
    80002626:	854e                	mv	a0,s3
    80002628:	00000097          	auipc	ra,0x0
    8000262c:	da8080e7          	jalr	-600(ra) # 800023d0 <free_metadata>
      return -1;
    80002630:	54fd                	li	s1,-1
    80002632:	bf41                	j	800025c2 <fork+0x17e>
    return -1;
    80002634:	54fd                	li	s1,-1
    80002636:	b771                	j	800025c2 <fork+0x17e>

0000000080002638 <exit>:
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	e052                	sd	s4,0(sp)
    80002646:	1800                	addi	s0,sp,48
    80002648:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000264a:	fffff097          	auipc	ra,0xfffff
    8000264e:	38a080e7          	jalr	906(ra) # 800019d4 <myproc>
    80002652:	89aa                	mv	s3,a0
  if(p == initproc)
    80002654:	00008797          	auipc	a5,0x8
    80002658:	9d47b783          	ld	a5,-1580(a5) # 8000a028 <initproc>
    8000265c:	0d050493          	addi	s1,a0,208
    80002660:	15050913          	addi	s2,a0,336
    80002664:	02a79363          	bne	a5,a0,8000268a <exit+0x52>
    panic("init exiting");
    80002668:	00007517          	auipc	a0,0x7
    8000266c:	c2050513          	addi	a0,a0,-992 # 80009288 <digits+0x248>
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	eba080e7          	jalr	-326(ra) # 8000052a <panic>
      fileclose(f);
    80002678:	00003097          	auipc	ra,0x3
    8000267c:	ada080e7          	jalr	-1318(ra) # 80005152 <fileclose>
      p->ofile[fd] = 0;
    80002680:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002684:	04a1                	addi	s1,s1,8
    80002686:	01248563          	beq	s1,s2,80002690 <exit+0x58>
    if(p->ofile[fd]){
    8000268a:	6088                	ld	a0,0(s1)
    8000268c:	f575                	bnez	a0,80002678 <exit+0x40>
    8000268e:	bfdd                	j	80002684 <exit+0x4c>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002690:	0309a783          	lw	a5,48(s3)
  if (relevant_metadata_proc(p)) {
    80002694:	37fd                	addiw	a5,a5,-1
    80002696:	4705                	li	a4,1
    80002698:	08f76163          	bltu	a4,a5,8000271a <exit+0xe2>
  begin_op();
    8000269c:	00002097          	auipc	ra,0x2
    800026a0:	5ea080e7          	jalr	1514(ra) # 80004c86 <begin_op>
  iput(p->cwd);
    800026a4:	1509b503          	ld	a0,336(s3)
    800026a8:	00002097          	auipc	ra,0x2
    800026ac:	ab0080e7          	jalr	-1360(ra) # 80004158 <iput>
  end_op();
    800026b0:	00002097          	auipc	ra,0x2
    800026b4:	656080e7          	jalr	1622(ra) # 80004d06 <end_op>
  p->cwd = 0;
    800026b8:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800026bc:	00010497          	auipc	s1,0x10
    800026c0:	bfc48493          	addi	s1,s1,-1028 # 800122b8 <wait_lock>
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	4fc080e7          	jalr	1276(ra) # 80000bc2 <acquire>
  reparent(p);
    800026ce:	854e                	mv	a0,s3
    800026d0:	00000097          	auipc	ra,0x0
    800026d4:	a00080e7          	jalr	-1536(ra) # 800020d0 <reparent>
  wakeup(p->parent);
    800026d8:	0389b503          	ld	a0,56(s3)
    800026dc:	00000097          	auipc	ra,0x0
    800026e0:	97e080e7          	jalr	-1666(ra) # 8000205a <wakeup>
  acquire(&p->lock);
    800026e4:	854e                	mv	a0,s3
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	4dc080e7          	jalr	1244(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800026ee:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026f2:	4795                	li	a5,5
    800026f4:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800026f8:	8526                	mv	a0,s1
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	57c080e7          	jalr	1404(ra) # 80000c76 <release>
  sched();
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	7e2080e7          	jalr	2018(ra) # 80001ee4 <sched>
  panic("zombie exit");
    8000270a:	00007517          	auipc	a0,0x7
    8000270e:	b8e50513          	addi	a0,a0,-1138 # 80009298 <digits+0x258>
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	e18080e7          	jalr	-488(ra) # 8000052a <panic>
    free_metadata(p);
    8000271a:	854e                	mv	a0,s3
    8000271c:	00000097          	auipc	ra,0x0
    80002720:	cb4080e7          	jalr	-844(ra) # 800023d0 <free_metadata>
    80002724:	bfa5                	j	8000269c <exit+0x64>

0000000080002726 <wait>:
{
    80002726:	715d                	addi	sp,sp,-80
    80002728:	e486                	sd	ra,72(sp)
    8000272a:	e0a2                	sd	s0,64(sp)
    8000272c:	fc26                	sd	s1,56(sp)
    8000272e:	f84a                	sd	s2,48(sp)
    80002730:	f44e                	sd	s3,40(sp)
    80002732:	f052                	sd	s4,32(sp)
    80002734:	ec56                	sd	s5,24(sp)
    80002736:	e85a                	sd	s6,16(sp)
    80002738:	e45e                	sd	s7,8(sp)
    8000273a:	e062                	sd	s8,0(sp)
    8000273c:	0880                	addi	s0,sp,80
    8000273e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	294080e7          	jalr	660(ra) # 800019d4 <myproc>
    80002748:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000274a:	00010517          	auipc	a0,0x10
    8000274e:	b6e50513          	addi	a0,a0,-1170 # 800122b8 <wait_lock>
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	470080e7          	jalr	1136(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000275a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000275c:	4a15                	li	s4,5
        havekids = 1;
    8000275e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002760:	0001e997          	auipc	s3,0x1e
    80002764:	d7098993          	addi	s3,s3,-656 # 800204d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002768:	00010c17          	auipc	s8,0x10
    8000276c:	b50c0c13          	addi	s8,s8,-1200 # 800122b8 <wait_lock>
    havekids = 0;
    80002770:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002772:	00010497          	auipc	s1,0x10
    80002776:	f5e48493          	addi	s1,s1,-162 # 800126d0 <proc>
    8000277a:	a059                	j	80002800 <wait+0xda>
          pid = np->pid;
    8000277c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002780:	000b0e63          	beqz	s6,8000279c <wait+0x76>
    80002784:	4691                	li	a3,4
    80002786:	02c48613          	addi	a2,s1,44
    8000278a:	85da                	mv	a1,s6
    8000278c:	05093503          	ld	a0,80(s2)
    80002790:	fffff097          	auipc	ra,0xfffff
    80002794:	f04080e7          	jalr	-252(ra) # 80001694 <copyout>
    80002798:	02054b63          	bltz	a0,800027ce <wait+0xa8>
          freeproc(np);
    8000279c:	8526                	mv	a0,s1
    8000279e:	fffff097          	auipc	ra,0xfffff
    800027a2:	3e8080e7          	jalr	1000(ra) # 80001b86 <freeproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    800027a6:	03092783          	lw	a5,48(s2)
         if (relevant_metadata_proc(p)) {
    800027aa:	37fd                	addiw	a5,a5,-1
    800027ac:	4705                	li	a4,1
    800027ae:	02f76f63          	bltu	a4,a5,800027ec <wait+0xc6>
          release(&np->lock);
    800027b2:	8526                	mv	a0,s1
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	4c2080e7          	jalr	1218(ra) # 80000c76 <release>
          release(&wait_lock);
    800027bc:	00010517          	auipc	a0,0x10
    800027c0:	afc50513          	addi	a0,a0,-1284 # 800122b8 <wait_lock>
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	4b2080e7          	jalr	1202(ra) # 80000c76 <release>
          return pid;
    800027cc:	a88d                	j	8000283e <wait+0x118>
            release(&np->lock);
    800027ce:	8526                	mv	a0,s1
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	4a6080e7          	jalr	1190(ra) # 80000c76 <release>
            release(&wait_lock);
    800027d8:	00010517          	auipc	a0,0x10
    800027dc:	ae050513          	addi	a0,a0,-1312 # 800122b8 <wait_lock>
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	496080e7          	jalr	1174(ra) # 80000c76 <release>
            return -1;
    800027e8:	59fd                	li	s3,-1
    800027ea:	a891                	j	8000283e <wait+0x118>
           free_metadata(np);
    800027ec:	8526                	mv	a0,s1
    800027ee:	00000097          	auipc	ra,0x0
    800027f2:	be2080e7          	jalr	-1054(ra) # 800023d0 <free_metadata>
    800027f6:	bf75                	j	800027b2 <wait+0x8c>
    for(np = proc; np < &proc[NPROC]; np++){
    800027f8:	37848493          	addi	s1,s1,888
    800027fc:	03348463          	beq	s1,s3,80002824 <wait+0xfe>
      if(np->parent == p){
    80002800:	7c9c                	ld	a5,56(s1)
    80002802:	ff279be3          	bne	a5,s2,800027f8 <wait+0xd2>
        acquire(&np->lock);
    80002806:	8526                	mv	a0,s1
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	3ba080e7          	jalr	954(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002810:	4c9c                	lw	a5,24(s1)
    80002812:	f74785e3          	beq	a5,s4,8000277c <wait+0x56>
        release(&np->lock);
    80002816:	8526                	mv	a0,s1
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	45e080e7          	jalr	1118(ra) # 80000c76 <release>
        havekids = 1;
    80002820:	8756                	mv	a4,s5
    80002822:	bfd9                	j	800027f8 <wait+0xd2>
    if(!havekids || p->killed){
    80002824:	c701                	beqz	a4,8000282c <wait+0x106>
    80002826:	02892783          	lw	a5,40(s2)
    8000282a:	c79d                	beqz	a5,80002858 <wait+0x132>
      release(&wait_lock);
    8000282c:	00010517          	auipc	a0,0x10
    80002830:	a8c50513          	addi	a0,a0,-1396 # 800122b8 <wait_lock>
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	442080e7          	jalr	1090(ra) # 80000c76 <release>
      return -1;
    8000283c:	59fd                	li	s3,-1
}
    8000283e:	854e                	mv	a0,s3
    80002840:	60a6                	ld	ra,72(sp)
    80002842:	6406                	ld	s0,64(sp)
    80002844:	74e2                	ld	s1,56(sp)
    80002846:	7942                	ld	s2,48(sp)
    80002848:	79a2                	ld	s3,40(sp)
    8000284a:	7a02                	ld	s4,32(sp)
    8000284c:	6ae2                	ld	s5,24(sp)
    8000284e:	6b42                	ld	s6,16(sp)
    80002850:	6ba2                	ld	s7,8(sp)
    80002852:	6c02                	ld	s8,0(sp)
    80002854:	6161                	addi	sp,sp,80
    80002856:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002858:	85e2                	mv	a1,s8
    8000285a:	854a                	mv	a0,s2
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	79a080e7          	jalr	1946(ra) # 80001ff6 <sleep>
    havekids = 0;
    80002864:	b731                	j	80002770 <wait+0x4a>

0000000080002866 <get_free_page_in_disk>:
{
    80002866:	1141                	addi	sp,sp,-16
    80002868:	e406                	sd	ra,8(sp)
    8000286a:	e022                	sd	s0,0(sp)
    8000286c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000286e:	fffff097          	auipc	ra,0xfffff
    80002872:	166080e7          	jalr	358(ra) # 800019d4 <myproc>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    80002876:	27050793          	addi	a5,a0,624
  int i = 0;
    8000287a:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    8000287c:	46c1                	li	a3,16
    if (!disk_pg->used) {
    8000287e:	47d8                	lw	a4,12(a5)
    80002880:	c711                	beqz	a4,8000288c <get_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    80002882:	07c1                	addi	a5,a5,16
    80002884:	2505                	addiw	a0,a0,1
    80002886:	fed51ce3          	bne	a0,a3,8000287e <get_free_page_in_disk+0x18>
  return -1;
    8000288a:	557d                	li	a0,-1
}
    8000288c:	60a2                	ld	ra,8(sp)
    8000288e:	6402                	ld	s0,0(sp)
    80002890:	0141                	addi	sp,sp,16
    80002892:	8082                	ret

0000000080002894 <swapout>:
{
    80002894:	7139                	addi	sp,sp,-64
    80002896:	fc06                	sd	ra,56(sp)
    80002898:	f822                	sd	s0,48(sp)
    8000289a:	f426                	sd	s1,40(sp)
    8000289c:	f04a                	sd	s2,32(sp)
    8000289e:	ec4e                	sd	s3,24(sp)
    800028a0:	e852                	sd	s4,16(sp)
    800028a2:	e456                	sd	s5,8(sp)
    800028a4:	0080                	addi	s0,sp,64
    800028a6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	12c080e7          	jalr	300(ra) # 800019d4 <myproc>
  if (ram_pg_index < 0 || ram_pg_index >= MAX_PSYC_PAGES) {
    800028b0:	0004871b          	sext.w	a4,s1
    800028b4:	47bd                	li	a5,15
    800028b6:	0ae7e363          	bltu	a5,a4,8000295c <swapout+0xc8>
    800028ba:	8a2a                	mv	s4,a0
  if (!ram_pg_to_swap->used) {
    800028bc:	0492                	slli	s1,s1,0x4
    800028be:	94aa                	add	s1,s1,a0
    800028c0:	17c4a783          	lw	a5,380(s1)
    800028c4:	c7c5                	beqz	a5,8000296c <swapout+0xd8>
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    800028c6:	4601                	li	a2,0
    800028c8:	1704b583          	ld	a1,368(s1)
    800028cc:	6928                	ld	a0,80(a0)
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	6d8080e7          	jalr	1752(ra) # 80000fa6 <walk>
    800028d6:	89aa                	mv	s3,a0
    800028d8:	c155                	beqz	a0,8000297c <swapout+0xe8>
  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    800028da:	611c                	ld	a5,0(a0)
    800028dc:	2017f793          	andi	a5,a5,513
    800028e0:	4705                	li	a4,1
    800028e2:	0ae79563          	bne	a5,a4,8000298c <swapout+0xf8>
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    800028e6:	00000097          	auipc	ra,0x0
    800028ea:	f80080e7          	jalr	-128(ra) # 80002866 <get_free_page_in_disk>
    800028ee:	0a054763          	bltz	a0,8000299c <swapout+0x108>
  uint64 pa = PTE2PA(*pte);
    800028f2:	0009ba83          	ld	s5,0(s3)
    800028f6:	00aada93          	srli	s5,s5,0xa
    800028fa:	0ab2                	slli	s5,s5,0xc
    800028fc:	00451913          	slli	s2,a0,0x4
    80002900:	9952                	add	s2,s2,s4
  if (writeToSwapFile(p, (char *)pa, disk_pg_to_store->offset, PGSIZE) < 0) {
    80002902:	6685                	lui	a3,0x1
    80002904:	27892603          	lw	a2,632(s2)
    80002908:	85d6                	mv	a1,s5
    8000290a:	8552                	mv	a0,s4
    8000290c:	00002097          	auipc	ra,0x2
    80002910:	14c080e7          	jalr	332(ra) # 80004a58 <writeToSwapFile>
    80002914:	08054c63          	bltz	a0,800029ac <swapout+0x118>
  disk_pg_to_store->used = 1;
    80002918:	4785                	li	a5,1
    8000291a:	26f92e23          	sw	a5,636(s2)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    8000291e:	1704b783          	ld	a5,368(s1)
    80002922:	26f93823          	sd	a5,624(s2)
  kfree((void *)pa);
    80002926:	8556                	mv	a0,s5
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	0ae080e7          	jalr	174(ra) # 800009d6 <kfree>
  ram_pg_to_swap->va = 0;
    80002930:	1604b823          	sd	zero,368(s1)
  ram_pg_to_swap->used = 0;
    80002934:	1604ae23          	sw	zero,380(s1)
  *pte = *pte & ~PTE_V;
    80002938:	0009b783          	ld	a5,0(s3)
    8000293c:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    8000293e:	2007e793          	ori	a5,a5,512
    80002942:	00f9b023          	sd	a5,0(s3)
  asm volatile("sfence.vma zero, zero");
    80002946:	12000073          	sfence.vma
}
    8000294a:	70e2                	ld	ra,56(sp)
    8000294c:	7442                	ld	s0,48(sp)
    8000294e:	74a2                	ld	s1,40(sp)
    80002950:	7902                	ld	s2,32(sp)
    80002952:	69e2                	ld	s3,24(sp)
    80002954:	6a42                	ld	s4,16(sp)
    80002956:	6aa2                	ld	s5,8(sp)
    80002958:	6121                	addi	sp,sp,64
    8000295a:	8082                	ret
    panic("swapout: ram page index out of bounds");
    8000295c:	00007517          	auipc	a0,0x7
    80002960:	94c50513          	addi	a0,a0,-1716 # 800092a8 <digits+0x268>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	bc6080e7          	jalr	-1082(ra) # 8000052a <panic>
    panic("swapout: page unused");
    8000296c:	00007517          	auipc	a0,0x7
    80002970:	96450513          	addi	a0,a0,-1692 # 800092d0 <digits+0x290>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	bb6080e7          	jalr	-1098(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    8000297c:	00007517          	auipc	a0,0x7
    80002980:	96c50513          	addi	a0,a0,-1684 # 800092e8 <digits+0x2a8>
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	ba6080e7          	jalr	-1114(ra) # 8000052a <panic>
    panic("swapout: page is not in ram");
    8000298c:	00007517          	auipc	a0,0x7
    80002990:	97450513          	addi	a0,a0,-1676 # 80009300 <digits+0x2c0>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	b96080e7          	jalr	-1130(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    8000299c:	00007517          	auipc	a0,0x7
    800029a0:	98450513          	addi	a0,a0,-1660 # 80009320 <digits+0x2e0>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	b86080e7          	jalr	-1146(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    800029ac:	00007517          	auipc	a0,0x7
    800029b0:	98c50513          	addi	a0,a0,-1652 # 80009338 <digits+0x2f8>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	b76080e7          	jalr	-1162(ra) # 8000052a <panic>

00000000800029bc <swapin>:
{
    800029bc:	7139                	addi	sp,sp,-64
    800029be:	fc06                	sd	ra,56(sp)
    800029c0:	f822                	sd	s0,48(sp)
    800029c2:	f426                	sd	s1,40(sp)
    800029c4:	f04a                	sd	s2,32(sp)
    800029c6:	ec4e                	sd	s3,24(sp)
    800029c8:	e852                	sd	s4,16(sp)
    800029ca:	e456                	sd	s5,8(sp)
    800029cc:	0080                	addi	s0,sp,64
  if (disk_index < 0 || disk_index >= MAX_DISK_PAGES) {
    800029ce:	47bd                	li	a5,15
    800029d0:	0aa7ed63          	bltu	a5,a0,80002a8a <swapin+0xce>
    800029d4:	89ae                	mv	s3,a1
    800029d6:	892a                	mv	s2,a0
  if (ram_index < 0 || ram_index >= MAX_PSYC_PAGES) {
    800029d8:	0005879b          	sext.w	a5,a1
    800029dc:	473d                	li	a4,15
    800029de:	0af76e63          	bltu	a4,a5,80002a9a <swapin+0xde>
  struct proc *p = myproc();
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	ff2080e7          	jalr	-14(ra) # 800019d4 <myproc>
    800029ea:	8aaa                	mv	s5,a0
  if (!disk_pg->used) {
    800029ec:	0912                	slli	s2,s2,0x4
    800029ee:	992a                	add	s2,s2,a0
    800029f0:	27c92783          	lw	a5,636(s2)
    800029f4:	cbdd                	beqz	a5,80002aaa <swapin+0xee>
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    800029f6:	4601                	li	a2,0
    800029f8:	27093583          	ld	a1,624(s2)
    800029fc:	6928                	ld	a0,80(a0)
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	5a8080e7          	jalr	1448(ra) # 80000fa6 <walk>
    80002a06:	8a2a                	mv	s4,a0
    80002a08:	c94d                	beqz	a0,80002aba <swapin+0xfe>
  if ((*pte & PTE_V) || !(*pte & PTE_PG))
    80002a0a:	611c                	ld	a5,0(a0)
    80002a0c:	2017f793          	andi	a5,a5,513
    80002a10:	20000713          	li	a4,512
    80002a14:	0ae79b63          	bne	a5,a4,80002aca <swapin+0x10e>
  if (ram_pg->used) {
    80002a18:	0992                	slli	s3,s3,0x4
    80002a1a:	99d6                	add	s3,s3,s5
    80002a1c:	17c9a783          	lw	a5,380(s3)
    80002a20:	efcd                	bnez	a5,80002ada <swapin+0x11e>
  if ( (npa = (uint64)kalloc()) == 0 ) {
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	0b0080e7          	jalr	176(ra) # 80000ad2 <kalloc>
    80002a2a:	84aa                	mv	s1,a0
    80002a2c:	cd5d                	beqz	a0,80002aea <swapin+0x12e>
  if (readFromSwapFile(p, (char *)npa, disk_pg->offset, PGSIZE) < 0) {
    80002a2e:	6685                	lui	a3,0x1
    80002a30:	27892603          	lw	a2,632(s2)
    80002a34:	85aa                	mv	a1,a0
    80002a36:	8556                	mv	a0,s5
    80002a38:	00002097          	auipc	ra,0x2
    80002a3c:	044080e7          	jalr	68(ra) # 80004a7c <readFromSwapFile>
    80002a40:	0a054d63          	bltz	a0,80002afa <swapin+0x13e>
  ram_pg->used = 1;
    80002a44:	4785                	li	a5,1
    80002a46:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    80002a4a:	27093783          	ld	a5,624(s2)
    80002a4e:	16f9b823          	sd	a5,368(s3)
    ram_pg->age = 0;
    80002a52:	1609ac23          	sw	zero,376(s3)
  disk_pg->va = 0;
    80002a56:	26093823          	sd	zero,624(s2)
  disk_pg->used = 0;
    80002a5a:	26092e23          	sw	zero,636(s2)
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    80002a5e:	80b1                	srli	s1,s1,0xc
    80002a60:	04aa                	slli	s1,s1,0xa
    80002a62:	000a3783          	ld	a5,0(s4)
    80002a66:	1ff7f793          	andi	a5,a5,511
    80002a6a:	8cdd                	or	s1,s1,a5
    80002a6c:	0014e493          	ori	s1,s1,1
    80002a70:	009a3023          	sd	s1,0(s4)
    80002a74:	12000073          	sfence.vma
}
    80002a78:	70e2                	ld	ra,56(sp)
    80002a7a:	7442                	ld	s0,48(sp)
    80002a7c:	74a2                	ld	s1,40(sp)
    80002a7e:	7902                	ld	s2,32(sp)
    80002a80:	69e2                	ld	s3,24(sp)
    80002a82:	6a42                	ld	s4,16(sp)
    80002a84:	6aa2                	ld	s5,8(sp)
    80002a86:	6121                	addi	sp,sp,64
    80002a88:	8082                	ret
    panic("swapin: disk index out of bounds");
    80002a8a:	00007517          	auipc	a0,0x7
    80002a8e:	8d650513          	addi	a0,a0,-1834 # 80009360 <digits+0x320>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	a98080e7          	jalr	-1384(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    80002a9a:	00007517          	auipc	a0,0x7
    80002a9e:	8ee50513          	addi	a0,a0,-1810 # 80009388 <digits+0x348>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	a88080e7          	jalr	-1400(ra) # 8000052a <panic>
    panic("swapin: page unused");
    80002aaa:	00007517          	auipc	a0,0x7
    80002aae:	8fe50513          	addi	a0,a0,-1794 # 800093a8 <digits+0x368>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a78080e7          	jalr	-1416(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    80002aba:	00007517          	auipc	a0,0x7
    80002abe:	90650513          	addi	a0,a0,-1786 # 800093c0 <digits+0x380>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	a68080e7          	jalr	-1432(ra) # 8000052a <panic>
      panic("swapin: page is not in disk");
    80002aca:	00007517          	auipc	a0,0x7
    80002ace:	90e50513          	addi	a0,a0,-1778 # 800093d8 <digits+0x398>
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	a58080e7          	jalr	-1448(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    80002ada:	00007517          	auipc	a0,0x7
    80002ade:	91e50513          	addi	a0,a0,-1762 # 800093f8 <digits+0x3b8>
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	a48080e7          	jalr	-1464(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    80002aea:	00007517          	auipc	a0,0x7
    80002aee:	92650513          	addi	a0,a0,-1754 # 80009410 <digits+0x3d0>
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	a38080e7          	jalr	-1480(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002afa:	00007517          	auipc	a0,0x7
    80002afe:	93e50513          	addi	a0,a0,-1730 # 80009438 <digits+0x3f8>
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	a28080e7          	jalr	-1496(ra) # 8000052a <panic>

0000000080002b0a <get_unused_ram_index>:
{
    80002b0a:	1141                	addi	sp,sp,-16
    80002b0c:	e422                	sd	s0,8(sp)
    80002b0e:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002b10:	17c50793          	addi	a5,a0,380
    80002b14:	4501                	li	a0,0
    80002b16:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    80002b18:	4398                	lw	a4,0(a5)
    80002b1a:	c711                	beqz	a4,80002b26 <get_unused_ram_index+0x1c>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002b1c:	2505                	addiw	a0,a0,1
    80002b1e:	07c1                	addi	a5,a5,16
    80002b20:	fed51ce3          	bne	a0,a3,80002b18 <get_unused_ram_index+0xe>
  return -1;
    80002b24:	557d                	li	a0,-1
}
    80002b26:	6422                	ld	s0,8(sp)
    80002b28:	0141                	addi	sp,sp,16
    80002b2a:	8082                	ret

0000000080002b2c <get_disk_page_index>:
{
    80002b2c:	1141                	addi	sp,sp,-16
    80002b2e:	e422                	sd	s0,8(sp)
    80002b30:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002b32:	27050793          	addi	a5,a0,624
    80002b36:	4501                	li	a0,0
    80002b38:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    80002b3a:	6398                	ld	a4,0(a5)
    80002b3c:	00b70763          	beq	a4,a1,80002b4a <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002b40:	2505                	addiw	a0,a0,1
    80002b42:	07c1                	addi	a5,a5,16
    80002b44:	fed51be3          	bne	a0,a3,80002b3a <get_disk_page_index+0xe>
  return -1;
    80002b48:	557d                	li	a0,-1
}
    80002b4a:	6422                	ld	s0,8(sp)
    80002b4c:	0141                	addi	sp,sp,16
    80002b4e:	8082                	ret

0000000080002b50 <remove_page_from_ram>:
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	1000                	addi	s0,sp,32
    80002b5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	e78080e7          	jalr	-392(ra) # 800019d4 <myproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002b64:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002b66:	37fd                	addiw	a5,a5,-1
    80002b68:	4705                	li	a4,1
    80002b6a:	02f77863          	bgeu	a4,a5,80002b9a <remove_page_from_ram+0x4a>
    80002b6e:	17050793          	addi	a5,a0,368
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002b72:	4701                	li	a4,0
    80002b74:	4641                	li	a2,16
    80002b76:	a029                	j	80002b80 <remove_page_from_ram+0x30>
    80002b78:	2705                	addiw	a4,a4,1
    80002b7a:	07c1                	addi	a5,a5,16
    80002b7c:	02c70463          	beq	a4,a2,80002ba4 <remove_page_from_ram+0x54>
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
    80002b80:	6394                	ld	a3,0(a5)
    80002b82:	fe969be3          	bne	a3,s1,80002b78 <remove_page_from_ram+0x28>
    80002b86:	47d4                	lw	a3,12(a5)
    80002b88:	dae5                	beqz	a3,80002b78 <remove_page_from_ram+0x28>
      p->ram_pages[i].va = 0;
    80002b8a:	0712                	slli	a4,a4,0x4
    80002b8c:	972a                	add	a4,a4,a0
    80002b8e:	16073823          	sd	zero,368(a4)
      p->ram_pages[i].used = 0;
    80002b92:	16072e23          	sw	zero,380(a4)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002b96:	16072c23          	sw	zero,376(a4)
}
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret
  panic("remove_page_from_ram failed");
    80002ba4:	00007517          	auipc	a0,0x7
    80002ba8:	8b450513          	addi	a0,a0,-1868 # 80009458 <digits+0x418>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	97e080e7          	jalr	-1666(ra) # 8000052a <panic>

0000000080002bb4 <nfua>:
{
    80002bb4:	1141                	addi	sp,sp,-16
    80002bb6:	e406                	sd	ra,8(sp)
    80002bb8:	e022                	sd	s0,0(sp)
    80002bba:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	e18080e7          	jalr	-488(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bc4:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002bc8:	567d                	li	a2,-1
  int min_index = 0;
    80002bca:	4501                	li	a0,0
  int i = 0;
    80002bcc:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bce:	45c1                	li	a1,16
    80002bd0:	a029                	j	80002bda <nfua+0x26>
    80002bd2:	0741                	addi	a4,a4,16
    80002bd4:	2785                	addiw	a5,a5,1
    80002bd6:	00b78863          	beq	a5,a1,80002be6 <nfua+0x32>
    if(ram_pg->age <= min_age){
    80002bda:	4714                	lw	a3,8(a4)
    80002bdc:	fed66be3          	bltu	a2,a3,80002bd2 <nfua+0x1e>
      min_age = ram_pg->age;
    80002be0:	8636                	mv	a2,a3
    if(ram_pg->age <= min_age){
    80002be2:	853e                	mv	a0,a5
    80002be4:	b7fd                	j	80002bd2 <nfua+0x1e>
}
    80002be6:	60a2                	ld	ra,8(sp)
    80002be8:	6402                	ld	s0,0(sp)
    80002bea:	0141                	addi	sp,sp,16
    80002bec:	8082                	ret

0000000080002bee <count_ones>:
{
    80002bee:	1141                	addi	sp,sp,-16
    80002bf0:	e422                	sd	s0,8(sp)
    80002bf2:	0800                	addi	s0,sp,16
  while(num > 0){
    80002bf4:	c105                	beqz	a0,80002c14 <count_ones+0x26>
    80002bf6:	87aa                	mv	a5,a0
  int count = 0;
    80002bf8:	4501                	li	a0,0
  while(num > 0){
    80002bfa:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002bfc:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002c00:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002c02:	0007871b          	sext.w	a4,a5
    80002c06:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002c0a:	fee6e9e3          	bltu	a3,a4,80002bfc <count_ones+0xe>
}
    80002c0e:	6422                	ld	s0,8(sp)
    80002c10:	0141                	addi	sp,sp,16
    80002c12:	8082                	ret
  int count = 0;
    80002c14:	4501                	li	a0,0
    80002c16:	bfe5                	j	80002c0e <count_ones+0x20>

0000000080002c18 <lapa>:
{
    80002c18:	715d                	addi	sp,sp,-80
    80002c1a:	e486                	sd	ra,72(sp)
    80002c1c:	e0a2                	sd	s0,64(sp)
    80002c1e:	fc26                	sd	s1,56(sp)
    80002c20:	f84a                	sd	s2,48(sp)
    80002c22:	f44e                	sd	s3,40(sp)
    80002c24:	f052                	sd	s4,32(sp)
    80002c26:	ec56                	sd	s5,24(sp)
    80002c28:	e85a                	sd	s6,16(sp)
    80002c2a:	e45e                	sd	s7,8(sp)
    80002c2c:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	da6080e7          	jalr	-602(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c36:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002c3a:	5afd                	li	s5,-1
  int min_index = 0;
    80002c3c:	4b81                	li	s7,0
  int i = 0;
    80002c3e:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c40:	4b41                	li	s6,16
    80002c42:	a039                	j	80002c50 <lapa+0x38>
      min_age = ram_pg->age;
    80002c44:	8ad2                	mv	s5,s4
    80002c46:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c48:	09c1                	addi	s3,s3,16
    80002c4a:	2905                	addiw	s2,s2,1
    80002c4c:	03690863          	beq	s2,s6,80002c7c <lapa+0x64>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002c50:	0089aa03          	lw	s4,8(s3)
    80002c54:	8552                	mv	a0,s4
    80002c56:	00000097          	auipc	ra,0x0
    80002c5a:	f98080e7          	jalr	-104(ra) # 80002bee <count_ones>
    80002c5e:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002c60:	8556                	mv	a0,s5
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	f8c080e7          	jalr	-116(ra) # 80002bee <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002c6a:	fca4cde3          	blt	s1,a0,80002c44 <lapa+0x2c>
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c6e:	fca49de3          	bne	s1,a0,80002c48 <lapa+0x30>
    80002c72:	fd5a7be3          	bgeu	s4,s5,80002c48 <lapa+0x30>
      min_age = ram_pg->age;
    80002c76:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c78:	8bca                	mv	s7,s2
    80002c7a:	b7f9                	j	80002c48 <lapa+0x30>
}
    80002c7c:	855e                	mv	a0,s7
    80002c7e:	60a6                	ld	ra,72(sp)
    80002c80:	6406                	ld	s0,64(sp)
    80002c82:	74e2                	ld	s1,56(sp)
    80002c84:	7942                	ld	s2,48(sp)
    80002c86:	79a2                	ld	s3,40(sp)
    80002c88:	7a02                	ld	s4,32(sp)
    80002c8a:	6ae2                	ld	s5,24(sp)
    80002c8c:	6b42                	ld	s6,16(sp)
    80002c8e:	6ba2                	ld	s7,8(sp)
    80002c90:	6161                	addi	sp,sp,80
    80002c92:	8082                	ret

0000000080002c94 <scfifo>:
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	e04a                	sd	s2,0(sp)
    80002c9e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	d34080e7          	jalr	-716(ra) # 800019d4 <myproc>
    80002ca8:	892a                	mv	s2,a0
  int index = p->scfifo_index;
    80002caa:	37052483          	lw	s1,880(a0)
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
    80002cae:	01748793          	addi	a5,s1,23
    80002cb2:	0792                	slli	a5,a5,0x4
    80002cb4:	97ca                	add	a5,a5,s2
    80002cb6:	4601                	li	a2,0
    80002cb8:	638c                	ld	a1,0(a5)
    80002cba:	05093503          	ld	a0,80(s2)
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	2e8080e7          	jalr	744(ra) # 80000fa6 <walk>
    80002cc6:	c10d                	beqz	a0,80002ce8 <scfifo+0x54>
    if(*pte & PTE_A){
    80002cc8:	611c                	ld	a5,0(a0)
    80002cca:	0407f713          	andi	a4,a5,64
    80002cce:	c70d                	beqz	a4,80002cf8 <scfifo+0x64>
      *pte = *pte & ~PTE_A;
    80002cd0:	fbf7f793          	andi	a5,a5,-65
    80002cd4:	e11c                	sd	a5,0(a0)
      index = (index + 1) % MAX_PSYC_PAGES;
    80002cd6:	2485                	addiw	s1,s1,1
    80002cd8:	41f4d79b          	sraiw	a5,s1,0x1f
    80002cdc:	01c7d79b          	srliw	a5,a5,0x1c
    80002ce0:	9cbd                	addw	s1,s1,a5
    80002ce2:	88bd                	andi	s1,s1,15
    80002ce4:	9c9d                	subw	s1,s1,a5
  while(1){
    80002ce6:	b7e1                	j	80002cae <scfifo+0x1a>
      panic("scfifo: walk failed");
    80002ce8:	00006517          	auipc	a0,0x6
    80002cec:	79050513          	addi	a0,a0,1936 # 80009478 <digits+0x438>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	83a080e7          	jalr	-1990(ra) # 8000052a <panic>
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
    80002cf8:	0014879b          	addiw	a5,s1,1
    80002cfc:	41f7d71b          	sraiw	a4,a5,0x1f
    80002d00:	01c7571b          	srliw	a4,a4,0x1c
    80002d04:	9fb9                	addw	a5,a5,a4
    80002d06:	8bbd                	andi	a5,a5,15
    80002d08:	9f99                	subw	a5,a5,a4
    80002d0a:	36f92823          	sw	a5,880(s2)
}
    80002d0e:	8526                	mv	a0,s1
    80002d10:	60e2                	ld	ra,24(sp)
    80002d12:	6442                	ld	s0,16(sp)
    80002d14:	64a2                	ld	s1,8(sp)
    80002d16:	6902                	ld	s2,0(sp)
    80002d18:	6105                	addi	sp,sp,32
    80002d1a:	8082                	ret

0000000080002d1c <insert_page_to_ram>:
{
    80002d1c:	7179                	addi	sp,sp,-48
    80002d1e:	f406                	sd	ra,40(sp)
    80002d20:	f022                	sd	s0,32(sp)
    80002d22:	ec26                	sd	s1,24(sp)
    80002d24:	e84a                	sd	s2,16(sp)
    80002d26:	e44e                	sd	s3,8(sp)
    80002d28:	1800                	addi	s0,sp,48
    80002d2a:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	ca8080e7          	jalr	-856(ra) # 800019d4 <myproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002d34:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002d36:	37fd                	addiw	a5,a5,-1
    80002d38:	4705                	li	a4,1
    80002d3a:	02f77363          	bgeu	a4,a5,80002d60 <insert_page_to_ram+0x44>
    80002d3e:	84aa                	mv	s1,a0
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0)
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	dca080e7          	jalr	-566(ra) # 80002b0a <get_unused_ram_index>
    80002d48:	892a                	mv	s2,a0
    80002d4a:	02054263          	bltz	a0,80002d6e <insert_page_to_ram+0x52>
  ram_pg->va = va;
    80002d4e:	0912                	slli	s2,s2,0x4
    80002d50:	94ca                	add	s1,s1,s2
    80002d52:	1734b823          	sd	s3,368(s1)
  ram_pg->used = 1;
    80002d56:	4785                	li	a5,1
    80002d58:	16f4ae23          	sw	a5,380(s1)
    ram_pg->age = 0;
    80002d5c:	1604ac23          	sw	zero,376(s1)
}
    80002d60:	70a2                	ld	ra,40(sp)
    80002d62:	7402                	ld	s0,32(sp)
    80002d64:	64e2                	ld	s1,24(sp)
    80002d66:	6942                	ld	s2,16(sp)
    80002d68:	69a2                	ld	s3,8(sp)
    80002d6a:	6145                	addi	sp,sp,48
    80002d6c:	8082                	ret
    return scfifo();
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	f26080e7          	jalr	-218(ra) # 80002c94 <scfifo>
    80002d76:	892a                	mv	s2,a0
    swapout(ram_pg_index_to_swap);
    80002d78:	00000097          	auipc	ra,0x0
    80002d7c:	b1c080e7          	jalr	-1252(ra) # 80002894 <swapout>
    unused_ram_pg_index = ram_pg_index_to_swap;
    80002d80:	b7f9                	j	80002d4e <insert_page_to_ram+0x32>

0000000080002d82 <handle_page_fault>:
{
    80002d82:	7179                	addi	sp,sp,-48
    80002d84:	f406                	sd	ra,40(sp)
    80002d86:	f022                	sd	s0,32(sp)
    80002d88:	ec26                	sd	s1,24(sp)
    80002d8a:	e84a                	sd	s2,16(sp)
    80002d8c:	e44e                	sd	s3,8(sp)
    80002d8e:	1800                	addi	s0,sp,48
    80002d90:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	c42080e7          	jalr	-958(ra) # 800019d4 <myproc>
    80002d9a:	892a                	mv	s2,a0
  if (!(pte = walk(p->pagetable, va, 0))) {
    80002d9c:	4601                	li	a2,0
    80002d9e:	85ce                	mv	a1,s3
    80002da0:	6928                	ld	a0,80(a0)
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	204080e7          	jalr	516(ra) # 80000fa6 <walk>
    80002daa:	c531                	beqz	a0,80002df6 <handle_page_fault+0x74>
  if(*pte & PTE_V){
    80002dac:	611c                	ld	a5,0(a0)
    80002dae:	0017f713          	andi	a4,a5,1
    80002db2:	eb31                	bnez	a4,80002e06 <handle_page_fault+0x84>
  if(!(*pte & PTE_PG)) { //TODO why?
    80002db4:	2007f793          	andi	a5,a5,512
    80002db8:	cfb9                	beqz	a5,80002e16 <handle_page_fault+0x94>
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
    80002dba:	854a                	mv	a0,s2
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	d4e080e7          	jalr	-690(ra) # 80002b0a <get_unused_ram_index>
    80002dc4:	84aa                	mv	s1,a0
    80002dc6:	06054063          	bltz	a0,80002e26 <handle_page_fault+0xa4>
  if( (target_idx = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002dca:	75fd                	lui	a1,0xfffff
    80002dcc:	00b9f5b3          	and	a1,s3,a1
    80002dd0:	854a                	mv	a0,s2
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	d5a080e7          	jalr	-678(ra) # 80002b2c <get_disk_page_index>
    80002dda:	06054963          	bltz	a0,80002e4c <handle_page_fault+0xca>
  swapin(target_idx, unused_ram_pg_index);
    80002dde:	85a6                	mv	a1,s1
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	bdc080e7          	jalr	-1060(ra) # 800029bc <swapin>
}
    80002de8:	70a2                	ld	ra,40(sp)
    80002dea:	7402                	ld	s0,32(sp)
    80002dec:	64e2                	ld	s1,24(sp)
    80002dee:	6942                	ld	s2,16(sp)
    80002df0:	69a2                	ld	s3,8(sp)
    80002df2:	6145                	addi	sp,sp,48
    80002df4:	8082                	ret
    panic("handle_page_fault: walk failed");
    80002df6:	00006517          	auipc	a0,0x6
    80002dfa:	69a50513          	addi	a0,a0,1690 # 80009490 <digits+0x450>
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	72c080e7          	jalr	1836(ra) # 8000052a <panic>
    panic("handle_page_fault: invalid pte");
    80002e06:	00006517          	auipc	a0,0x6
    80002e0a:	6aa50513          	addi	a0,a0,1706 # 800094b0 <digits+0x470>
    80002e0e:	ffffd097          	auipc	ra,0xffffd
    80002e12:	71c080e7          	jalr	1820(ra) # 8000052a <panic>
    panic("handle_page_fault: PTE_PG off");
    80002e16:	00006517          	auipc	a0,0x6
    80002e1a:	6ba50513          	addi	a0,a0,1722 # 800094d0 <digits+0x490>
    80002e1e:	ffffd097          	auipc	ra,0xffffd
    80002e22:	70c080e7          	jalr	1804(ra) # 8000052a <panic>
    return scfifo();
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	e6e080e7          	jalr	-402(ra) # 80002c94 <scfifo>
    80002e2e:	84aa                	mv	s1,a0
      swapout(ram_pg_index_to_swap); 
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	a64080e7          	jalr	-1436(ra) # 80002894 <swapout>
      printf("handle_page_fault: replace index %d\n", unused_ram_pg_index); // ADDED Q3
    80002e38:	85a6                	mv	a1,s1
    80002e3a:	00006517          	auipc	a0,0x6
    80002e3e:	6b650513          	addi	a0,a0,1718 # 800094f0 <digits+0x4b0>
    80002e42:	ffffd097          	auipc	ra,0xffffd
    80002e46:	732080e7          	jalr	1842(ra) # 80000574 <printf>
    80002e4a:	b741                	j	80002dca <handle_page_fault+0x48>
    panic("handle_page_fault: get_disk_page_index failed");
    80002e4c:	00006517          	auipc	a0,0x6
    80002e50:	6cc50513          	addi	a0,a0,1740 # 80009518 <digits+0x4d8>
    80002e54:	ffffd097          	auipc	ra,0xffffd
    80002e58:	6d6080e7          	jalr	1750(ra) # 8000052a <panic>

0000000080002e5c <index_page_to_swap>:
{
    80002e5c:	1141                	addi	sp,sp,-16
    80002e5e:	e406                	sd	ra,8(sp)
    80002e60:	e022                	sd	s0,0(sp)
    80002e62:	0800                	addi	s0,sp,16
    return scfifo();
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	e30080e7          	jalr	-464(ra) # 80002c94 <scfifo>
}
    80002e6c:	60a2                	ld	ra,8(sp)
    80002e6e:	6402                	ld	s0,0(sp)
    80002e70:	0141                	addi	sp,sp,16
    80002e72:	8082                	ret

0000000080002e74 <maintain_age>:
void maintain_age(struct proc *p){
    80002e74:	7179                	addi	sp,sp,-48
    80002e76:	f406                	sd	ra,40(sp)
    80002e78:	f022                	sd	s0,32(sp)
    80002e7a:	ec26                	sd	s1,24(sp)
    80002e7c:	e84a                	sd	s2,16(sp)
    80002e7e:	e44e                	sd	s3,8(sp)
    80002e80:	e052                	sd	s4,0(sp)
    80002e82:	1800                	addi	s0,sp,48
    80002e84:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002e86:	17050493          	addi	s1,a0,368
    80002e8a:	27050993          	addi	s3,a0,624
      ram_pg->age = ram_pg->age | (1 << 31);
    80002e8e:	80000a37          	lui	s4,0x80000
    80002e92:	a821                	j	80002eaa <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002e94:	00006517          	auipc	a0,0x6
    80002e98:	6b450513          	addi	a0,a0,1716 # 80009548 <digits+0x508>
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	68e080e7          	jalr	1678(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002ea4:	04c1                	addi	s1,s1,16
    80002ea6:	02998b63          	beq	s3,s1,80002edc <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002eaa:	4601                	li	a2,0
    80002eac:	608c                	ld	a1,0(s1)
    80002eae:	05093503          	ld	a0,80(s2)
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	0f4080e7          	jalr	244(ra) # 80000fa6 <walk>
    80002eba:	dd69                	beqz	a0,80002e94 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002ebc:	449c                	lw	a5,8(s1)
    80002ebe:	0017d79b          	srliw	a5,a5,0x1
    80002ec2:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002ec4:	6118                	ld	a4,0(a0)
    80002ec6:	04077713          	andi	a4,a4,64
    80002eca:	df69                	beqz	a4,80002ea4 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002ecc:	0147e7b3          	or	a5,a5,s4
    80002ed0:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002ed2:	611c                	ld	a5,0(a0)
    80002ed4:	fbf7f793          	andi	a5,a5,-65
    80002ed8:	e11c                	sd	a5,0(a0)
    80002eda:	b7e9                	j	80002ea4 <maintain_age+0x30>
}
    80002edc:	70a2                	ld	ra,40(sp)
    80002ede:	7402                	ld	s0,32(sp)
    80002ee0:	64e2                	ld	s1,24(sp)
    80002ee2:	6942                	ld	s2,16(sp)
    80002ee4:	69a2                	ld	s3,8(sp)
    80002ee6:	6a02                	ld	s4,0(sp)
    80002ee8:	6145                	addi	sp,sp,48
    80002eea:	8082                	ret

0000000080002eec <relevant_metadata_proc>:
int relevant_metadata_proc(struct proc *p) {
    80002eec:	1141                	addi	sp,sp,-16
    80002eee:	e422                	sd	s0,8(sp)
    80002ef0:	0800                	addi	s0,sp,16
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002ef2:	591c                	lw	a5,48(a0)
    80002ef4:	37fd                	addiw	a5,a5,-1
    80002ef6:	4505                	li	a0,1
    80002ef8:	00f53533          	sltu	a0,a0,a5
    80002efc:	6422                	ld	s0,8(sp)
    80002efe:	0141                	addi	sp,sp,16
    80002f00:	8082                	ret

0000000080002f02 <swtch>:
    80002f02:	00153023          	sd	ra,0(a0)
    80002f06:	00253423          	sd	sp,8(a0)
    80002f0a:	e900                	sd	s0,16(a0)
    80002f0c:	ed04                	sd	s1,24(a0)
    80002f0e:	03253023          	sd	s2,32(a0)
    80002f12:	03353423          	sd	s3,40(a0)
    80002f16:	03453823          	sd	s4,48(a0)
    80002f1a:	03553c23          	sd	s5,56(a0)
    80002f1e:	05653023          	sd	s6,64(a0)
    80002f22:	05753423          	sd	s7,72(a0)
    80002f26:	05853823          	sd	s8,80(a0)
    80002f2a:	05953c23          	sd	s9,88(a0)
    80002f2e:	07a53023          	sd	s10,96(a0)
    80002f32:	07b53423          	sd	s11,104(a0)
    80002f36:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80002f3a:	0085b103          	ld	sp,8(a1)
    80002f3e:	6980                	ld	s0,16(a1)
    80002f40:	6d84                	ld	s1,24(a1)
    80002f42:	0205b903          	ld	s2,32(a1)
    80002f46:	0285b983          	ld	s3,40(a1)
    80002f4a:	0305ba03          	ld	s4,48(a1)
    80002f4e:	0385ba83          	ld	s5,56(a1)
    80002f52:	0405bb03          	ld	s6,64(a1)
    80002f56:	0485bb83          	ld	s7,72(a1)
    80002f5a:	0505bc03          	ld	s8,80(a1)
    80002f5e:	0585bc83          	ld	s9,88(a1)
    80002f62:	0605bd03          	ld	s10,96(a1)
    80002f66:	0685bd83          	ld	s11,104(a1)
    80002f6a:	8082                	ret

0000000080002f6c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f6c:	1141                	addi	sp,sp,-16
    80002f6e:	e406                	sd	ra,8(sp)
    80002f70:	e022                	sd	s0,0(sp)
    80002f72:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f74:	00006597          	auipc	a1,0x6
    80002f78:	64c58593          	addi	a1,a1,1612 # 800095c0 <states.0+0x30>
    80002f7c:	0001d517          	auipc	a0,0x1d
    80002f80:	55450513          	addi	a0,a0,1364 # 800204d0 <tickslock>
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	bae080e7          	jalr	-1106(ra) # 80000b32 <initlock>
}
    80002f8c:	60a2                	ld	ra,8(sp)
    80002f8e:	6402                	ld	s0,0(sp)
    80002f90:	0141                	addi	sp,sp,16
    80002f92:	8082                	ret

0000000080002f94 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002f94:	1141                	addi	sp,sp,-16
    80002f96:	e422                	sd	s0,8(sp)
    80002f98:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f9a:	00004797          	auipc	a5,0x4
    80002f9e:	ac678793          	addi	a5,a5,-1338 # 80006a60 <kernelvec>
    80002fa2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002fa6:	6422                	ld	s0,8(sp)
    80002fa8:	0141                	addi	sp,sp,16
    80002faa:	8082                	ret

0000000080002fac <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002fac:	1141                	addi	sp,sp,-16
    80002fae:	e406                	sd	ra,8(sp)
    80002fb0:	e022                	sd	s0,0(sp)
    80002fb2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	a20080e7          	jalr	-1504(ra) # 800019d4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fc0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fc2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002fc6:	00005617          	auipc	a2,0x5
    80002fca:	03a60613          	addi	a2,a2,58 # 80008000 <_trampoline>
    80002fce:	00005697          	auipc	a3,0x5
    80002fd2:	03268693          	addi	a3,a3,50 # 80008000 <_trampoline>
    80002fd6:	8e91                	sub	a3,a3,a2
    80002fd8:	040007b7          	lui	a5,0x4000
    80002fdc:	17fd                	addi	a5,a5,-1
    80002fde:	07b2                	slli	a5,a5,0xc
    80002fe0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fe2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002fe6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002fe8:	180026f3          	csrr	a3,satp
    80002fec:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002fee:	6d38                	ld	a4,88(a0)
    80002ff0:	6134                	ld	a3,64(a0)
    80002ff2:	6585                	lui	a1,0x1
    80002ff4:	96ae                	add	a3,a3,a1
    80002ff6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ff8:	6d38                	ld	a4,88(a0)
    80002ffa:	00000697          	auipc	a3,0x0
    80002ffe:	13868693          	addi	a3,a3,312 # 80003132 <usertrap>
    80003002:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003004:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003006:	8692                	mv	a3,tp
    80003008:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000300a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000300e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003012:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003016:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000301a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000301c:	6f18                	ld	a4,24(a4)
    8000301e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003022:	692c                	ld	a1,80(a0)
    80003024:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003026:	00005717          	auipc	a4,0x5
    8000302a:	06a70713          	addi	a4,a4,106 # 80008090 <userret>
    8000302e:	8f11                	sub	a4,a4,a2
    80003030:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003032:	577d                	li	a4,-1
    80003034:	177e                	slli	a4,a4,0x3f
    80003036:	8dd9                	or	a1,a1,a4
    80003038:	02000537          	lui	a0,0x2000
    8000303c:	157d                	addi	a0,a0,-1
    8000303e:	0536                	slli	a0,a0,0xd
    80003040:	9782                	jalr	a5
}
    80003042:	60a2                	ld	ra,8(sp)
    80003044:	6402                	ld	s0,0(sp)
    80003046:	0141                	addi	sp,sp,16
    80003048:	8082                	ret

000000008000304a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000304a:	1101                	addi	sp,sp,-32
    8000304c:	ec06                	sd	ra,24(sp)
    8000304e:	e822                	sd	s0,16(sp)
    80003050:	e426                	sd	s1,8(sp)
    80003052:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003054:	0001d497          	auipc	s1,0x1d
    80003058:	47c48493          	addi	s1,s1,1148 # 800204d0 <tickslock>
    8000305c:	8526                	mv	a0,s1
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	b64080e7          	jalr	-1180(ra) # 80000bc2 <acquire>
  ticks++;
    80003066:	00007517          	auipc	a0,0x7
    8000306a:	fca50513          	addi	a0,a0,-54 # 8000a030 <ticks>
    8000306e:	411c                	lw	a5,0(a0)
    80003070:	2785                	addiw	a5,a5,1
    80003072:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	fe6080e7          	jalr	-26(ra) # 8000205a <wakeup>
  release(&tickslock);
    8000307c:	8526                	mv	a0,s1
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	bf8080e7          	jalr	-1032(ra) # 80000c76 <release>
}
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	64a2                	ld	s1,8(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret

0000000080003090 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000309a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000309e:	00074d63          	bltz	a4,800030b8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800030a2:	57fd                	li	a5,-1
    800030a4:	17fe                	slli	a5,a5,0x3f
    800030a6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800030a8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800030aa:	06f70363          	beq	a4,a5,80003110 <devintr+0x80>
  }
}
    800030ae:	60e2                	ld	ra,24(sp)
    800030b0:	6442                	ld	s0,16(sp)
    800030b2:	64a2                	ld	s1,8(sp)
    800030b4:	6105                	addi	sp,sp,32
    800030b6:	8082                	ret
     (scause & 0xff) == 9){
    800030b8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800030bc:	46a5                	li	a3,9
    800030be:	fed792e3          	bne	a5,a3,800030a2 <devintr+0x12>
    int irq = plic_claim();
    800030c2:	00004097          	auipc	ra,0x4
    800030c6:	aa6080e7          	jalr	-1370(ra) # 80006b68 <plic_claim>
    800030ca:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800030cc:	47a9                	li	a5,10
    800030ce:	02f50763          	beq	a0,a5,800030fc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800030d2:	4785                	li	a5,1
    800030d4:	02f50963          	beq	a0,a5,80003106 <devintr+0x76>
    return 1;
    800030d8:	4505                	li	a0,1
    } else if(irq){
    800030da:	d8f1                	beqz	s1,800030ae <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800030dc:	85a6                	mv	a1,s1
    800030de:	00006517          	auipc	a0,0x6
    800030e2:	4ea50513          	addi	a0,a0,1258 # 800095c8 <states.0+0x38>
    800030e6:	ffffd097          	auipc	ra,0xffffd
    800030ea:	48e080e7          	jalr	1166(ra) # 80000574 <printf>
      plic_complete(irq);
    800030ee:	8526                	mv	a0,s1
    800030f0:	00004097          	auipc	ra,0x4
    800030f4:	a9c080e7          	jalr	-1380(ra) # 80006b8c <plic_complete>
    return 1;
    800030f8:	4505                	li	a0,1
    800030fa:	bf55                	j	800030ae <devintr+0x1e>
      uartintr();
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	88a080e7          	jalr	-1910(ra) # 80000986 <uartintr>
    80003104:	b7ed                	j	800030ee <devintr+0x5e>
      virtio_disk_intr();
    80003106:	00004097          	auipc	ra,0x4
    8000310a:	f18080e7          	jalr	-232(ra) # 8000701e <virtio_disk_intr>
    8000310e:	b7c5                	j	800030ee <devintr+0x5e>
    if(cpuid() == 0){
    80003110:	fffff097          	auipc	ra,0xfffff
    80003114:	898080e7          	jalr	-1896(ra) # 800019a8 <cpuid>
    80003118:	c901                	beqz	a0,80003128 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000311a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000311e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003120:	14479073          	csrw	sip,a5
    return 2;
    80003124:	4509                	li	a0,2
    80003126:	b761                	j	800030ae <devintr+0x1e>
      clockintr();
    80003128:	00000097          	auipc	ra,0x0
    8000312c:	f22080e7          	jalr	-222(ra) # 8000304a <clockintr>
    80003130:	b7ed                	j	8000311a <devintr+0x8a>

0000000080003132 <usertrap>:
{
    80003132:	1101                	addi	sp,sp,-32
    80003134:	ec06                	sd	ra,24(sp)
    80003136:	e822                	sd	s0,16(sp)
    80003138:	e426                	sd	s1,8(sp)
    8000313a:	e04a                	sd	s2,0(sp)
    8000313c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000313e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003142:	1007f793          	andi	a5,a5,256
    80003146:	e3ad                	bnez	a5,800031a8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003148:	00004797          	auipc	a5,0x4
    8000314c:	91878793          	addi	a5,a5,-1768 # 80006a60 <kernelvec>
    80003150:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003154:	fffff097          	auipc	ra,0xfffff
    80003158:	880080e7          	jalr	-1920(ra) # 800019d4 <myproc>
    8000315c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000315e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003160:	14102773          	csrr	a4,sepc
    80003164:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003166:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000316a:	47a1                	li	a5,8
    8000316c:	04f71c63          	bne	a4,a5,800031c4 <usertrap+0x92>
    if(p->killed)
    80003170:	551c                	lw	a5,40(a0)
    80003172:	e3b9                	bnez	a5,800031b8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003174:	6cb8                	ld	a4,88(s1)
    80003176:	6f1c                	ld	a5,24(a4)
    80003178:	0791                	addi	a5,a5,4
    8000317a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000317c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003180:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003184:	10079073          	csrw	sstatus,a5
    syscall();
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	318080e7          	jalr	792(ra) # 800034a0 <syscall>
  if(p->killed)
    80003190:	549c                	lw	a5,40(s1)
    80003192:	ebc5                	bnez	a5,80003242 <usertrap+0x110>
  usertrapret();
    80003194:	00000097          	auipc	ra,0x0
    80003198:	e18080e7          	jalr	-488(ra) # 80002fac <usertrapret>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6902                	ld	s2,0(sp)
    800031a4:	6105                	addi	sp,sp,32
    800031a6:	8082                	ret
    panic("usertrap: not from user mode");
    800031a8:	00006517          	auipc	a0,0x6
    800031ac:	44050513          	addi	a0,a0,1088 # 800095e8 <states.0+0x58>
    800031b0:	ffffd097          	auipc	ra,0xffffd
    800031b4:	37a080e7          	jalr	890(ra) # 8000052a <panic>
      exit(-1);
    800031b8:	557d                	li	a0,-1
    800031ba:	fffff097          	auipc	ra,0xfffff
    800031be:	47e080e7          	jalr	1150(ra) # 80002638 <exit>
    800031c2:	bf4d                	j	80003174 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	ecc080e7          	jalr	-308(ra) # 80003090 <devintr>
    800031cc:	892a                	mv	s2,a0
    800031ce:	c501                	beqz	a0,800031d6 <usertrap+0xa4>
  if(p->killed)
    800031d0:	549c                	lw	a5,40(s1)
    800031d2:	cfb5                	beqz	a5,8000324e <usertrap+0x11c>
    800031d4:	a885                	j	80003244 <usertrap+0x112>
  } else if (relevant_metadata_proc(p) && 
    800031d6:	8526                	mv	a0,s1
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	d14080e7          	jalr	-748(ra) # 80002eec <relevant_metadata_proc>
    800031e0:	c105                	beqz	a0,80003200 <usertrap+0xce>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031e2:	14202773          	csrr	a4,scause
    800031e6:	47b1                	li	a5,12
    800031e8:	04f70663          	beq	a4,a5,80003234 <usertrap+0x102>
    800031ec:	14202773          	csrr	a4,scause
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    800031f0:	47b5                	li	a5,13
    800031f2:	04f70163          	beq	a4,a5,80003234 <usertrap+0x102>
    800031f6:	14202773          	csrr	a4,scause
    800031fa:	47bd                	li	a5,15
    800031fc:	02f70c63          	beq	a4,a5,80003234 <usertrap+0x102>
    80003200:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003204:	5890                	lw	a2,48(s1)
    80003206:	00006517          	auipc	a0,0x6
    8000320a:	40250513          	addi	a0,a0,1026 # 80009608 <states.0+0x78>
    8000320e:	ffffd097          	auipc	ra,0xffffd
    80003212:	366080e7          	jalr	870(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003216:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000321a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000321e:	00006517          	auipc	a0,0x6
    80003222:	41a50513          	addi	a0,a0,1050 # 80009638 <states.0+0xa8>
    80003226:	ffffd097          	auipc	ra,0xffffd
    8000322a:	34e080e7          	jalr	846(ra) # 80000574 <printf>
    p->killed = 1;
    8000322e:	4785                	li	a5,1
    80003230:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80003232:	a809                	j	80003244 <usertrap+0x112>
    80003234:	14302573          	csrr	a0,stval
      handle_page_fault(va);  
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	b4a080e7          	jalr	-1206(ra) # 80002d82 <handle_page_fault>
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    80003240:	bf81                	j	80003190 <usertrap+0x5e>
  if(p->killed)
    80003242:	4901                	li	s2,0
    exit(-1);
    80003244:	557d                	li	a0,-1
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	3f2080e7          	jalr	1010(ra) # 80002638 <exit>
  if(which_dev == 2)
    8000324e:	4789                	li	a5,2
    80003250:	f4f912e3          	bne	s2,a5,80003194 <usertrap+0x62>
    yield();
    80003254:	fffff097          	auipc	ra,0xfffff
    80003258:	d66080e7          	jalr	-666(ra) # 80001fba <yield>
    8000325c:	bf25                	j	80003194 <usertrap+0x62>

000000008000325e <kerneltrap>:
{
    8000325e:	7179                	addi	sp,sp,-48
    80003260:	f406                	sd	ra,40(sp)
    80003262:	f022                	sd	s0,32(sp)
    80003264:	ec26                	sd	s1,24(sp)
    80003266:	e84a                	sd	s2,16(sp)
    80003268:	e44e                	sd	s3,8(sp)
    8000326a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000326c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003270:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003274:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003278:	1004f793          	andi	a5,s1,256
    8000327c:	cb85                	beqz	a5,800032ac <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000327e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003282:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003284:	ef85                	bnez	a5,800032bc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	e0a080e7          	jalr	-502(ra) # 80003090 <devintr>
    8000328e:	cd1d                	beqz	a0,800032cc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003290:	4789                	li	a5,2
    80003292:	06f50a63          	beq	a0,a5,80003306 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003296:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000329a:	10049073          	csrw	sstatus,s1
}
    8000329e:	70a2                	ld	ra,40(sp)
    800032a0:	7402                	ld	s0,32(sp)
    800032a2:	64e2                	ld	s1,24(sp)
    800032a4:	6942                	ld	s2,16(sp)
    800032a6:	69a2                	ld	s3,8(sp)
    800032a8:	6145                	addi	sp,sp,48
    800032aa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032ac:	00006517          	auipc	a0,0x6
    800032b0:	3ac50513          	addi	a0,a0,940 # 80009658 <states.0+0xc8>
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	276080e7          	jalr	630(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800032bc:	00006517          	auipc	a0,0x6
    800032c0:	3c450513          	addi	a0,a0,964 # 80009680 <states.0+0xf0>
    800032c4:	ffffd097          	auipc	ra,0xffffd
    800032c8:	266080e7          	jalr	614(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800032cc:	85ce                	mv	a1,s3
    800032ce:	00006517          	auipc	a0,0x6
    800032d2:	3d250513          	addi	a0,a0,978 # 800096a0 <states.0+0x110>
    800032d6:	ffffd097          	auipc	ra,0xffffd
    800032da:	29e080e7          	jalr	670(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032de:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032e2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032e6:	00006517          	auipc	a0,0x6
    800032ea:	3ca50513          	addi	a0,a0,970 # 800096b0 <states.0+0x120>
    800032ee:	ffffd097          	auipc	ra,0xffffd
    800032f2:	286080e7          	jalr	646(ra) # 80000574 <printf>
    panic("kerneltrap");
    800032f6:	00006517          	auipc	a0,0x6
    800032fa:	3d250513          	addi	a0,a0,978 # 800096c8 <states.0+0x138>
    800032fe:	ffffd097          	auipc	ra,0xffffd
    80003302:	22c080e7          	jalr	556(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	6ce080e7          	jalr	1742(ra) # 800019d4 <myproc>
    8000330e:	d541                	beqz	a0,80003296 <kerneltrap+0x38>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	6c4080e7          	jalr	1732(ra) # 800019d4 <myproc>
    80003318:	4d18                	lw	a4,24(a0)
    8000331a:	4791                	li	a5,4
    8000331c:	f6f71de3          	bne	a4,a5,80003296 <kerneltrap+0x38>
    yield();
    80003320:	fffff097          	auipc	ra,0xfffff
    80003324:	c9a080e7          	jalr	-870(ra) # 80001fba <yield>
    80003328:	b7bd                	j	80003296 <kerneltrap+0x38>

000000008000332a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000332a:	1101                	addi	sp,sp,-32
    8000332c:	ec06                	sd	ra,24(sp)
    8000332e:	e822                	sd	s0,16(sp)
    80003330:	e426                	sd	s1,8(sp)
    80003332:	1000                	addi	s0,sp,32
    80003334:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	69e080e7          	jalr	1694(ra) # 800019d4 <myproc>
  switch (n) {
    8000333e:	4795                	li	a5,5
    80003340:	0497e163          	bltu	a5,s1,80003382 <argraw+0x58>
    80003344:	048a                	slli	s1,s1,0x2
    80003346:	00006717          	auipc	a4,0x6
    8000334a:	3ba70713          	addi	a4,a4,954 # 80009700 <states.0+0x170>
    8000334e:	94ba                	add	s1,s1,a4
    80003350:	409c                	lw	a5,0(s1)
    80003352:	97ba                	add	a5,a5,a4
    80003354:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003356:	6d3c                	ld	a5,88(a0)
    80003358:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000335a:	60e2                	ld	ra,24(sp)
    8000335c:	6442                	ld	s0,16(sp)
    8000335e:	64a2                	ld	s1,8(sp)
    80003360:	6105                	addi	sp,sp,32
    80003362:	8082                	ret
    return p->trapframe->a1;
    80003364:	6d3c                	ld	a5,88(a0)
    80003366:	7fa8                	ld	a0,120(a5)
    80003368:	bfcd                	j	8000335a <argraw+0x30>
    return p->trapframe->a2;
    8000336a:	6d3c                	ld	a5,88(a0)
    8000336c:	63c8                	ld	a0,128(a5)
    8000336e:	b7f5                	j	8000335a <argraw+0x30>
    return p->trapframe->a3;
    80003370:	6d3c                	ld	a5,88(a0)
    80003372:	67c8                	ld	a0,136(a5)
    80003374:	b7dd                	j	8000335a <argraw+0x30>
    return p->trapframe->a4;
    80003376:	6d3c                	ld	a5,88(a0)
    80003378:	6bc8                	ld	a0,144(a5)
    8000337a:	b7c5                	j	8000335a <argraw+0x30>
    return p->trapframe->a5;
    8000337c:	6d3c                	ld	a5,88(a0)
    8000337e:	6fc8                	ld	a0,152(a5)
    80003380:	bfe9                	j	8000335a <argraw+0x30>
  panic("argraw");
    80003382:	00006517          	auipc	a0,0x6
    80003386:	35650513          	addi	a0,a0,854 # 800096d8 <states.0+0x148>
    8000338a:	ffffd097          	auipc	ra,0xffffd
    8000338e:	1a0080e7          	jalr	416(ra) # 8000052a <panic>

0000000080003392 <fetchaddr>:
{
    80003392:	1101                	addi	sp,sp,-32
    80003394:	ec06                	sd	ra,24(sp)
    80003396:	e822                	sd	s0,16(sp)
    80003398:	e426                	sd	s1,8(sp)
    8000339a:	e04a                	sd	s2,0(sp)
    8000339c:	1000                	addi	s0,sp,32
    8000339e:	84aa                	mv	s1,a0
    800033a0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	632080e7          	jalr	1586(ra) # 800019d4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033aa:	653c                	ld	a5,72(a0)
    800033ac:	02f4f863          	bgeu	s1,a5,800033dc <fetchaddr+0x4a>
    800033b0:	00848713          	addi	a4,s1,8
    800033b4:	02e7e663          	bltu	a5,a4,800033e0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033b8:	46a1                	li	a3,8
    800033ba:	8626                	mv	a2,s1
    800033bc:	85ca                	mv	a1,s2
    800033be:	6928                	ld	a0,80(a0)
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	360080e7          	jalr	864(ra) # 80001720 <copyin>
    800033c8:	00a03533          	snez	a0,a0
    800033cc:	40a00533          	neg	a0,a0
}
    800033d0:	60e2                	ld	ra,24(sp)
    800033d2:	6442                	ld	s0,16(sp)
    800033d4:	64a2                	ld	s1,8(sp)
    800033d6:	6902                	ld	s2,0(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret
    return -1;
    800033dc:	557d                	li	a0,-1
    800033de:	bfcd                	j	800033d0 <fetchaddr+0x3e>
    800033e0:	557d                	li	a0,-1
    800033e2:	b7fd                	j	800033d0 <fetchaddr+0x3e>

00000000800033e4 <fetchstr>:
{
    800033e4:	7179                	addi	sp,sp,-48
    800033e6:	f406                	sd	ra,40(sp)
    800033e8:	f022                	sd	s0,32(sp)
    800033ea:	ec26                	sd	s1,24(sp)
    800033ec:	e84a                	sd	s2,16(sp)
    800033ee:	e44e                	sd	s3,8(sp)
    800033f0:	1800                	addi	s0,sp,48
    800033f2:	892a                	mv	s2,a0
    800033f4:	84ae                	mv	s1,a1
    800033f6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	5dc080e7          	jalr	1500(ra) # 800019d4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003400:	86ce                	mv	a3,s3
    80003402:	864a                	mv	a2,s2
    80003404:	85a6                	mv	a1,s1
    80003406:	6928                	ld	a0,80(a0)
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	3a6080e7          	jalr	934(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003410:	00054763          	bltz	a0,8000341e <fetchstr+0x3a>
  return strlen(buf);
    80003414:	8526                	mv	a0,s1
    80003416:	ffffe097          	auipc	ra,0xffffe
    8000341a:	a2c080e7          	jalr	-1492(ra) # 80000e42 <strlen>
}
    8000341e:	70a2                	ld	ra,40(sp)
    80003420:	7402                	ld	s0,32(sp)
    80003422:	64e2                	ld	s1,24(sp)
    80003424:	6942                	ld	s2,16(sp)
    80003426:	69a2                	ld	s3,8(sp)
    80003428:	6145                	addi	sp,sp,48
    8000342a:	8082                	ret

000000008000342c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000342c:	1101                	addi	sp,sp,-32
    8000342e:	ec06                	sd	ra,24(sp)
    80003430:	e822                	sd	s0,16(sp)
    80003432:	e426                	sd	s1,8(sp)
    80003434:	1000                	addi	s0,sp,32
    80003436:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	ef2080e7          	jalr	-270(ra) # 8000332a <argraw>
    80003440:	c088                	sw	a0,0(s1)
  return 0;
}
    80003442:	4501                	li	a0,0
    80003444:	60e2                	ld	ra,24(sp)
    80003446:	6442                	ld	s0,16(sp)
    80003448:	64a2                	ld	s1,8(sp)
    8000344a:	6105                	addi	sp,sp,32
    8000344c:	8082                	ret

000000008000344e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000344e:	1101                	addi	sp,sp,-32
    80003450:	ec06                	sd	ra,24(sp)
    80003452:	e822                	sd	s0,16(sp)
    80003454:	e426                	sd	s1,8(sp)
    80003456:	1000                	addi	s0,sp,32
    80003458:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	ed0080e7          	jalr	-304(ra) # 8000332a <argraw>
    80003462:	e088                	sd	a0,0(s1)
  return 0;
}
    80003464:	4501                	li	a0,0
    80003466:	60e2                	ld	ra,24(sp)
    80003468:	6442                	ld	s0,16(sp)
    8000346a:	64a2                	ld	s1,8(sp)
    8000346c:	6105                	addi	sp,sp,32
    8000346e:	8082                	ret

0000000080003470 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003470:	1101                	addi	sp,sp,-32
    80003472:	ec06                	sd	ra,24(sp)
    80003474:	e822                	sd	s0,16(sp)
    80003476:	e426                	sd	s1,8(sp)
    80003478:	e04a                	sd	s2,0(sp)
    8000347a:	1000                	addi	s0,sp,32
    8000347c:	84ae                	mv	s1,a1
    8000347e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003480:	00000097          	auipc	ra,0x0
    80003484:	eaa080e7          	jalr	-342(ra) # 8000332a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003488:	864a                	mv	a2,s2
    8000348a:	85a6                	mv	a1,s1
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	f58080e7          	jalr	-168(ra) # 800033e4 <fetchstr>
}
    80003494:	60e2                	ld	ra,24(sp)
    80003496:	6442                	ld	s0,16(sp)
    80003498:	64a2                	ld	s1,8(sp)
    8000349a:	6902                	ld	s2,0(sp)
    8000349c:	6105                	addi	sp,sp,32
    8000349e:	8082                	ret

00000000800034a0 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800034a0:	1101                	addi	sp,sp,-32
    800034a2:	ec06                	sd	ra,24(sp)
    800034a4:	e822                	sd	s0,16(sp)
    800034a6:	e426                	sd	s1,8(sp)
    800034a8:	e04a                	sd	s2,0(sp)
    800034aa:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034ac:	ffffe097          	auipc	ra,0xffffe
    800034b0:	528080e7          	jalr	1320(ra) # 800019d4 <myproc>
    800034b4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034b6:	05853903          	ld	s2,88(a0)
    800034ba:	0a893783          	ld	a5,168(s2)
    800034be:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800034c2:	37fd                	addiw	a5,a5,-1
    800034c4:	4751                	li	a4,20
    800034c6:	00f76f63          	bltu	a4,a5,800034e4 <syscall+0x44>
    800034ca:	00369713          	slli	a4,a3,0x3
    800034ce:	00006797          	auipc	a5,0x6
    800034d2:	24a78793          	addi	a5,a5,586 # 80009718 <syscalls>
    800034d6:	97ba                	add	a5,a5,a4
    800034d8:	639c                	ld	a5,0(a5)
    800034da:	c789                	beqz	a5,800034e4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800034dc:	9782                	jalr	a5
    800034de:	06a93823          	sd	a0,112(s2)
    800034e2:	a839                	j	80003500 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800034e4:	15848613          	addi	a2,s1,344
    800034e8:	588c                	lw	a1,48(s1)
    800034ea:	00006517          	auipc	a0,0x6
    800034ee:	1f650513          	addi	a0,a0,502 # 800096e0 <states.0+0x150>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	082080e7          	jalr	130(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800034fa:	6cbc                	ld	a5,88(s1)
    800034fc:	577d                	li	a4,-1
    800034fe:	fbb8                	sd	a4,112(a5)
  }
}
    80003500:	60e2                	ld	ra,24(sp)
    80003502:	6442                	ld	s0,16(sp)
    80003504:	64a2                	ld	s1,8(sp)
    80003506:	6902                	ld	s2,0(sp)
    80003508:	6105                	addi	sp,sp,32
    8000350a:	8082                	ret

000000008000350c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000350c:	1101                	addi	sp,sp,-32
    8000350e:	ec06                	sd	ra,24(sp)
    80003510:	e822                	sd	s0,16(sp)
    80003512:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003514:	fec40593          	addi	a1,s0,-20
    80003518:	4501                	li	a0,0
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	f12080e7          	jalr	-238(ra) # 8000342c <argint>
    return -1;
    80003522:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003524:	00054963          	bltz	a0,80003536 <sys_exit+0x2a>
  exit(n);
    80003528:	fec42503          	lw	a0,-20(s0)
    8000352c:	fffff097          	auipc	ra,0xfffff
    80003530:	10c080e7          	jalr	268(ra) # 80002638 <exit>
  return 0;  // not reached
    80003534:	4781                	li	a5,0
}
    80003536:	853e                	mv	a0,a5
    80003538:	60e2                	ld	ra,24(sp)
    8000353a:	6442                	ld	s0,16(sp)
    8000353c:	6105                	addi	sp,sp,32
    8000353e:	8082                	ret

0000000080003540 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003540:	1141                	addi	sp,sp,-16
    80003542:	e406                	sd	ra,8(sp)
    80003544:	e022                	sd	s0,0(sp)
    80003546:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003548:	ffffe097          	auipc	ra,0xffffe
    8000354c:	48c080e7          	jalr	1164(ra) # 800019d4 <myproc>
}
    80003550:	5908                	lw	a0,48(a0)
    80003552:	60a2                	ld	ra,8(sp)
    80003554:	6402                	ld	s0,0(sp)
    80003556:	0141                	addi	sp,sp,16
    80003558:	8082                	ret

000000008000355a <sys_fork>:

uint64
sys_fork(void)
{
    8000355a:	1141                	addi	sp,sp,-16
    8000355c:	e406                	sd	ra,8(sp)
    8000355e:	e022                	sd	s0,0(sp)
    80003560:	0800                	addi	s0,sp,16
  return fork();
    80003562:	fffff097          	auipc	ra,0xfffff
    80003566:	ee2080e7          	jalr	-286(ra) # 80002444 <fork>
}
    8000356a:	60a2                	ld	ra,8(sp)
    8000356c:	6402                	ld	s0,0(sp)
    8000356e:	0141                	addi	sp,sp,16
    80003570:	8082                	ret

0000000080003572 <sys_wait>:

uint64
sys_wait(void)
{
    80003572:	1101                	addi	sp,sp,-32
    80003574:	ec06                	sd	ra,24(sp)
    80003576:	e822                	sd	s0,16(sp)
    80003578:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000357a:	fe840593          	addi	a1,s0,-24
    8000357e:	4501                	li	a0,0
    80003580:	00000097          	auipc	ra,0x0
    80003584:	ece080e7          	jalr	-306(ra) # 8000344e <argaddr>
    80003588:	87aa                	mv	a5,a0
    return -1;
    8000358a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000358c:	0007c863          	bltz	a5,8000359c <sys_wait+0x2a>
  return wait(p);
    80003590:	fe843503          	ld	a0,-24(s0)
    80003594:	fffff097          	auipc	ra,0xfffff
    80003598:	192080e7          	jalr	402(ra) # 80002726 <wait>
}
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	6105                	addi	sp,sp,32
    800035a2:	8082                	ret

00000000800035a4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035a4:	7179                	addi	sp,sp,-48
    800035a6:	f406                	sd	ra,40(sp)
    800035a8:	f022                	sd	s0,32(sp)
    800035aa:	ec26                	sd	s1,24(sp)
    800035ac:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800035ae:	fdc40593          	addi	a1,s0,-36
    800035b2:	4501                	li	a0,0
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	e78080e7          	jalr	-392(ra) # 8000342c <argint>
    return -1;
    800035bc:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800035be:	00054f63          	bltz	a0,800035dc <sys_sbrk+0x38>
  addr = myproc()->sz;
    800035c2:	ffffe097          	auipc	ra,0xffffe
    800035c6:	412080e7          	jalr	1042(ra) # 800019d4 <myproc>
    800035ca:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800035cc:	fdc42503          	lw	a0,-36(s0)
    800035d0:	ffffe097          	auipc	ra,0xffffe
    800035d4:	75e080e7          	jalr	1886(ra) # 80001d2e <growproc>
    800035d8:	00054863          	bltz	a0,800035e8 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800035dc:	8526                	mv	a0,s1
    800035de:	70a2                	ld	ra,40(sp)
    800035e0:	7402                	ld	s0,32(sp)
    800035e2:	64e2                	ld	s1,24(sp)
    800035e4:	6145                	addi	sp,sp,48
    800035e6:	8082                	ret
    return -1;
    800035e8:	54fd                	li	s1,-1
    800035ea:	bfcd                	j	800035dc <sys_sbrk+0x38>

00000000800035ec <sys_sleep>:

uint64
sys_sleep(void)
{
    800035ec:	7139                	addi	sp,sp,-64
    800035ee:	fc06                	sd	ra,56(sp)
    800035f0:	f822                	sd	s0,48(sp)
    800035f2:	f426                	sd	s1,40(sp)
    800035f4:	f04a                	sd	s2,32(sp)
    800035f6:	ec4e                	sd	s3,24(sp)
    800035f8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800035fa:	fcc40593          	addi	a1,s0,-52
    800035fe:	4501                	li	a0,0
    80003600:	00000097          	auipc	ra,0x0
    80003604:	e2c080e7          	jalr	-468(ra) # 8000342c <argint>
    return -1;
    80003608:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000360a:	06054563          	bltz	a0,80003674 <sys_sleep+0x88>
  acquire(&tickslock);
    8000360e:	0001d517          	auipc	a0,0x1d
    80003612:	ec250513          	addi	a0,a0,-318 # 800204d0 <tickslock>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	5ac080e7          	jalr	1452(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000361e:	00007917          	auipc	s2,0x7
    80003622:	a1292903          	lw	s2,-1518(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    80003626:	fcc42783          	lw	a5,-52(s0)
    8000362a:	cf85                	beqz	a5,80003662 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000362c:	0001d997          	auipc	s3,0x1d
    80003630:	ea498993          	addi	s3,s3,-348 # 800204d0 <tickslock>
    80003634:	00007497          	auipc	s1,0x7
    80003638:	9fc48493          	addi	s1,s1,-1540 # 8000a030 <ticks>
    if(myproc()->killed){
    8000363c:	ffffe097          	auipc	ra,0xffffe
    80003640:	398080e7          	jalr	920(ra) # 800019d4 <myproc>
    80003644:	551c                	lw	a5,40(a0)
    80003646:	ef9d                	bnez	a5,80003684 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003648:	85ce                	mv	a1,s3
    8000364a:	8526                	mv	a0,s1
    8000364c:	fffff097          	auipc	ra,0xfffff
    80003650:	9aa080e7          	jalr	-1622(ra) # 80001ff6 <sleep>
  while(ticks - ticks0 < n){
    80003654:	409c                	lw	a5,0(s1)
    80003656:	412787bb          	subw	a5,a5,s2
    8000365a:	fcc42703          	lw	a4,-52(s0)
    8000365e:	fce7efe3          	bltu	a5,a4,8000363c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003662:	0001d517          	auipc	a0,0x1d
    80003666:	e6e50513          	addi	a0,a0,-402 # 800204d0 <tickslock>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	60c080e7          	jalr	1548(ra) # 80000c76 <release>
  return 0;
    80003672:	4781                	li	a5,0
}
    80003674:	853e                	mv	a0,a5
    80003676:	70e2                	ld	ra,56(sp)
    80003678:	7442                	ld	s0,48(sp)
    8000367a:	74a2                	ld	s1,40(sp)
    8000367c:	7902                	ld	s2,32(sp)
    8000367e:	69e2                	ld	s3,24(sp)
    80003680:	6121                	addi	sp,sp,64
    80003682:	8082                	ret
      release(&tickslock);
    80003684:	0001d517          	auipc	a0,0x1d
    80003688:	e4c50513          	addi	a0,a0,-436 # 800204d0 <tickslock>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	5ea080e7          	jalr	1514(ra) # 80000c76 <release>
      return -1;
    80003694:	57fd                	li	a5,-1
    80003696:	bff9                	j	80003674 <sys_sleep+0x88>

0000000080003698 <sys_kill>:

uint64
sys_kill(void)
{
    80003698:	1101                	addi	sp,sp,-32
    8000369a:	ec06                	sd	ra,24(sp)
    8000369c:	e822                	sd	s0,16(sp)
    8000369e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800036a0:	fec40593          	addi	a1,s0,-20
    800036a4:	4501                	li	a0,0
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	d86080e7          	jalr	-634(ra) # 8000342c <argint>
    800036ae:	87aa                	mv	a5,a0
    return -1;
    800036b0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800036b2:	0007c863          	bltz	a5,800036c2 <sys_kill+0x2a>
  return kill(pid);
    800036b6:	fec42503          	lw	a0,-20(s0)
    800036ba:	fffff097          	auipc	ra,0xfffff
    800036be:	a70080e7          	jalr	-1424(ra) # 8000212a <kill>
}
    800036c2:	60e2                	ld	ra,24(sp)
    800036c4:	6442                	ld	s0,16(sp)
    800036c6:	6105                	addi	sp,sp,32
    800036c8:	8082                	ret

00000000800036ca <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	e426                	sd	s1,8(sp)
    800036d2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036d4:	0001d517          	auipc	a0,0x1d
    800036d8:	dfc50513          	addi	a0,a0,-516 # 800204d0 <tickslock>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	4e6080e7          	jalr	1254(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800036e4:	00007497          	auipc	s1,0x7
    800036e8:	94c4a483          	lw	s1,-1716(s1) # 8000a030 <ticks>
  release(&tickslock);
    800036ec:	0001d517          	auipc	a0,0x1d
    800036f0:	de450513          	addi	a0,a0,-540 # 800204d0 <tickslock>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	582080e7          	jalr	1410(ra) # 80000c76 <release>
  return xticks;
}
    800036fc:	02049513          	slli	a0,s1,0x20
    80003700:	9101                	srli	a0,a0,0x20
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	64a2                	ld	s1,8(sp)
    80003708:	6105                	addi	sp,sp,32
    8000370a:	8082                	ret

000000008000370c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000370c:	7179                	addi	sp,sp,-48
    8000370e:	f406                	sd	ra,40(sp)
    80003710:	f022                	sd	s0,32(sp)
    80003712:	ec26                	sd	s1,24(sp)
    80003714:	e84a                	sd	s2,16(sp)
    80003716:	e44e                	sd	s3,8(sp)
    80003718:	e052                	sd	s4,0(sp)
    8000371a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000371c:	00006597          	auipc	a1,0x6
    80003720:	0ac58593          	addi	a1,a1,172 # 800097c8 <syscalls+0xb0>
    80003724:	0001d517          	auipc	a0,0x1d
    80003728:	dc450513          	addi	a0,a0,-572 # 800204e8 <bcache>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	406080e7          	jalr	1030(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003734:	00025797          	auipc	a5,0x25
    80003738:	db478793          	addi	a5,a5,-588 # 800284e8 <bcache+0x8000>
    8000373c:	00025717          	auipc	a4,0x25
    80003740:	01470713          	addi	a4,a4,20 # 80028750 <bcache+0x8268>
    80003744:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003748:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000374c:	0001d497          	auipc	s1,0x1d
    80003750:	db448493          	addi	s1,s1,-588 # 80020500 <bcache+0x18>
    b->next = bcache.head.next;
    80003754:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003756:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003758:	00006a17          	auipc	s4,0x6
    8000375c:	078a0a13          	addi	s4,s4,120 # 800097d0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003760:	2b893783          	ld	a5,696(s2)
    80003764:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003766:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000376a:	85d2                	mv	a1,s4
    8000376c:	01048513          	addi	a0,s1,16
    80003770:	00001097          	auipc	ra,0x1
    80003774:	7d4080e7          	jalr	2004(ra) # 80004f44 <initsleeplock>
    bcache.head.next->prev = b;
    80003778:	2b893783          	ld	a5,696(s2)
    8000377c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000377e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003782:	45848493          	addi	s1,s1,1112
    80003786:	fd349de3          	bne	s1,s3,80003760 <binit+0x54>
  }
}
    8000378a:	70a2                	ld	ra,40(sp)
    8000378c:	7402                	ld	s0,32(sp)
    8000378e:	64e2                	ld	s1,24(sp)
    80003790:	6942                	ld	s2,16(sp)
    80003792:	69a2                	ld	s3,8(sp)
    80003794:	6a02                	ld	s4,0(sp)
    80003796:	6145                	addi	sp,sp,48
    80003798:	8082                	ret

000000008000379a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000379a:	7179                	addi	sp,sp,-48
    8000379c:	f406                	sd	ra,40(sp)
    8000379e:	f022                	sd	s0,32(sp)
    800037a0:	ec26                	sd	s1,24(sp)
    800037a2:	e84a                	sd	s2,16(sp)
    800037a4:	e44e                	sd	s3,8(sp)
    800037a6:	1800                	addi	s0,sp,48
    800037a8:	892a                	mv	s2,a0
    800037aa:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800037ac:	0001d517          	auipc	a0,0x1d
    800037b0:	d3c50513          	addi	a0,a0,-708 # 800204e8 <bcache>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	40e080e7          	jalr	1038(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037bc:	00025497          	auipc	s1,0x25
    800037c0:	fe44b483          	ld	s1,-28(s1) # 800287a0 <bcache+0x82b8>
    800037c4:	00025797          	auipc	a5,0x25
    800037c8:	f8c78793          	addi	a5,a5,-116 # 80028750 <bcache+0x8268>
    800037cc:	02f48f63          	beq	s1,a5,8000380a <bread+0x70>
    800037d0:	873e                	mv	a4,a5
    800037d2:	a021                	j	800037da <bread+0x40>
    800037d4:	68a4                	ld	s1,80(s1)
    800037d6:	02e48a63          	beq	s1,a4,8000380a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800037da:	449c                	lw	a5,8(s1)
    800037dc:	ff279ce3          	bne	a5,s2,800037d4 <bread+0x3a>
    800037e0:	44dc                	lw	a5,12(s1)
    800037e2:	ff3799e3          	bne	a5,s3,800037d4 <bread+0x3a>
      b->refcnt++;
    800037e6:	40bc                	lw	a5,64(s1)
    800037e8:	2785                	addiw	a5,a5,1
    800037ea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037ec:	0001d517          	auipc	a0,0x1d
    800037f0:	cfc50513          	addi	a0,a0,-772 # 800204e8 <bcache>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	482080e7          	jalr	1154(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800037fc:	01048513          	addi	a0,s1,16
    80003800:	00001097          	auipc	ra,0x1
    80003804:	77e080e7          	jalr	1918(ra) # 80004f7e <acquiresleep>
      return b;
    80003808:	a8b9                	j	80003866 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000380a:	00025497          	auipc	s1,0x25
    8000380e:	f8e4b483          	ld	s1,-114(s1) # 80028798 <bcache+0x82b0>
    80003812:	00025797          	auipc	a5,0x25
    80003816:	f3e78793          	addi	a5,a5,-194 # 80028750 <bcache+0x8268>
    8000381a:	00f48863          	beq	s1,a5,8000382a <bread+0x90>
    8000381e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003820:	40bc                	lw	a5,64(s1)
    80003822:	cf81                	beqz	a5,8000383a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003824:	64a4                	ld	s1,72(s1)
    80003826:	fee49de3          	bne	s1,a4,80003820 <bread+0x86>
  panic("bget: no buffers");
    8000382a:	00006517          	auipc	a0,0x6
    8000382e:	fae50513          	addi	a0,a0,-82 # 800097d8 <syscalls+0xc0>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	cf8080e7          	jalr	-776(ra) # 8000052a <panic>
      b->dev = dev;
    8000383a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000383e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003842:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003846:	4785                	li	a5,1
    80003848:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000384a:	0001d517          	auipc	a0,0x1d
    8000384e:	c9e50513          	addi	a0,a0,-866 # 800204e8 <bcache>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	424080e7          	jalr	1060(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000385a:	01048513          	addi	a0,s1,16
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	720080e7          	jalr	1824(ra) # 80004f7e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003866:	409c                	lw	a5,0(s1)
    80003868:	cb89                	beqz	a5,8000387a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000386a:	8526                	mv	a0,s1
    8000386c:	70a2                	ld	ra,40(sp)
    8000386e:	7402                	ld	s0,32(sp)
    80003870:	64e2                	ld	s1,24(sp)
    80003872:	6942                	ld	s2,16(sp)
    80003874:	69a2                	ld	s3,8(sp)
    80003876:	6145                	addi	sp,sp,48
    80003878:	8082                	ret
    virtio_disk_rw(b, 0);
    8000387a:	4581                	li	a1,0
    8000387c:	8526                	mv	a0,s1
    8000387e:	00003097          	auipc	ra,0x3
    80003882:	518080e7          	jalr	1304(ra) # 80006d96 <virtio_disk_rw>
    b->valid = 1;
    80003886:	4785                	li	a5,1
    80003888:	c09c                	sw	a5,0(s1)
  return b;
    8000388a:	b7c5                	j	8000386a <bread+0xd0>

000000008000388c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000388c:	1101                	addi	sp,sp,-32
    8000388e:	ec06                	sd	ra,24(sp)
    80003890:	e822                	sd	s0,16(sp)
    80003892:	e426                	sd	s1,8(sp)
    80003894:	1000                	addi	s0,sp,32
    80003896:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003898:	0541                	addi	a0,a0,16
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	77e080e7          	jalr	1918(ra) # 80005018 <holdingsleep>
    800038a2:	cd01                	beqz	a0,800038ba <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800038a4:	4585                	li	a1,1
    800038a6:	8526                	mv	a0,s1
    800038a8:	00003097          	auipc	ra,0x3
    800038ac:	4ee080e7          	jalr	1262(ra) # 80006d96 <virtio_disk_rw>
}
    800038b0:	60e2                	ld	ra,24(sp)
    800038b2:	6442                	ld	s0,16(sp)
    800038b4:	64a2                	ld	s1,8(sp)
    800038b6:	6105                	addi	sp,sp,32
    800038b8:	8082                	ret
    panic("bwrite");
    800038ba:	00006517          	auipc	a0,0x6
    800038be:	f3650513          	addi	a0,a0,-202 # 800097f0 <syscalls+0xd8>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	c68080e7          	jalr	-920(ra) # 8000052a <panic>

00000000800038ca <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038ca:	1101                	addi	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	e426                	sd	s1,8(sp)
    800038d2:	e04a                	sd	s2,0(sp)
    800038d4:	1000                	addi	s0,sp,32
    800038d6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038d8:	01050913          	addi	s2,a0,16
    800038dc:	854a                	mv	a0,s2
    800038de:	00001097          	auipc	ra,0x1
    800038e2:	73a080e7          	jalr	1850(ra) # 80005018 <holdingsleep>
    800038e6:	c92d                	beqz	a0,80003958 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800038e8:	854a                	mv	a0,s2
    800038ea:	00001097          	auipc	ra,0x1
    800038ee:	6ea080e7          	jalr	1770(ra) # 80004fd4 <releasesleep>

  acquire(&bcache.lock);
    800038f2:	0001d517          	auipc	a0,0x1d
    800038f6:	bf650513          	addi	a0,a0,-1034 # 800204e8 <bcache>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	2c8080e7          	jalr	712(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003902:	40bc                	lw	a5,64(s1)
    80003904:	37fd                	addiw	a5,a5,-1
    80003906:	0007871b          	sext.w	a4,a5
    8000390a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000390c:	eb05                	bnez	a4,8000393c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000390e:	68bc                	ld	a5,80(s1)
    80003910:	64b8                	ld	a4,72(s1)
    80003912:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003914:	64bc                	ld	a5,72(s1)
    80003916:	68b8                	ld	a4,80(s1)
    80003918:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000391a:	00025797          	auipc	a5,0x25
    8000391e:	bce78793          	addi	a5,a5,-1074 # 800284e8 <bcache+0x8000>
    80003922:	2b87b703          	ld	a4,696(a5)
    80003926:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003928:	00025717          	auipc	a4,0x25
    8000392c:	e2870713          	addi	a4,a4,-472 # 80028750 <bcache+0x8268>
    80003930:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003932:	2b87b703          	ld	a4,696(a5)
    80003936:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003938:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000393c:	0001d517          	auipc	a0,0x1d
    80003940:	bac50513          	addi	a0,a0,-1108 # 800204e8 <bcache>
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	332080e7          	jalr	818(ra) # 80000c76 <release>
}
    8000394c:	60e2                	ld	ra,24(sp)
    8000394e:	6442                	ld	s0,16(sp)
    80003950:	64a2                	ld	s1,8(sp)
    80003952:	6902                	ld	s2,0(sp)
    80003954:	6105                	addi	sp,sp,32
    80003956:	8082                	ret
    panic("brelse");
    80003958:	00006517          	auipc	a0,0x6
    8000395c:	ea050513          	addi	a0,a0,-352 # 800097f8 <syscalls+0xe0>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	bca080e7          	jalr	-1078(ra) # 8000052a <panic>

0000000080003968 <bpin>:

void
bpin(struct buf *b) {
    80003968:	1101                	addi	sp,sp,-32
    8000396a:	ec06                	sd	ra,24(sp)
    8000396c:	e822                	sd	s0,16(sp)
    8000396e:	e426                	sd	s1,8(sp)
    80003970:	1000                	addi	s0,sp,32
    80003972:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003974:	0001d517          	auipc	a0,0x1d
    80003978:	b7450513          	addi	a0,a0,-1164 # 800204e8 <bcache>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	246080e7          	jalr	582(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003984:	40bc                	lw	a5,64(s1)
    80003986:	2785                	addiw	a5,a5,1
    80003988:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000398a:	0001d517          	auipc	a0,0x1d
    8000398e:	b5e50513          	addi	a0,a0,-1186 # 800204e8 <bcache>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	2e4080e7          	jalr	740(ra) # 80000c76 <release>
}
    8000399a:	60e2                	ld	ra,24(sp)
    8000399c:	6442                	ld	s0,16(sp)
    8000399e:	64a2                	ld	s1,8(sp)
    800039a0:	6105                	addi	sp,sp,32
    800039a2:	8082                	ret

00000000800039a4 <bunpin>:

void
bunpin(struct buf *b) {
    800039a4:	1101                	addi	sp,sp,-32
    800039a6:	ec06                	sd	ra,24(sp)
    800039a8:	e822                	sd	s0,16(sp)
    800039aa:	e426                	sd	s1,8(sp)
    800039ac:	1000                	addi	s0,sp,32
    800039ae:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039b0:	0001d517          	auipc	a0,0x1d
    800039b4:	b3850513          	addi	a0,a0,-1224 # 800204e8 <bcache>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	20a080e7          	jalr	522(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800039c0:	40bc                	lw	a5,64(s1)
    800039c2:	37fd                	addiw	a5,a5,-1
    800039c4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039c6:	0001d517          	auipc	a0,0x1d
    800039ca:	b2250513          	addi	a0,a0,-1246 # 800204e8 <bcache>
    800039ce:	ffffd097          	auipc	ra,0xffffd
    800039d2:	2a8080e7          	jalr	680(ra) # 80000c76 <release>
}
    800039d6:	60e2                	ld	ra,24(sp)
    800039d8:	6442                	ld	s0,16(sp)
    800039da:	64a2                	ld	s1,8(sp)
    800039dc:	6105                	addi	sp,sp,32
    800039de:	8082                	ret

00000000800039e0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800039e0:	1101                	addi	sp,sp,-32
    800039e2:	ec06                	sd	ra,24(sp)
    800039e4:	e822                	sd	s0,16(sp)
    800039e6:	e426                	sd	s1,8(sp)
    800039e8:	e04a                	sd	s2,0(sp)
    800039ea:	1000                	addi	s0,sp,32
    800039ec:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800039ee:	00d5d59b          	srliw	a1,a1,0xd
    800039f2:	00025797          	auipc	a5,0x25
    800039f6:	1d27a783          	lw	a5,466(a5) # 80028bc4 <sb+0x1c>
    800039fa:	9dbd                	addw	a1,a1,a5
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	d9e080e7          	jalr	-610(ra) # 8000379a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a04:	0074f713          	andi	a4,s1,7
    80003a08:	4785                	li	a5,1
    80003a0a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a0e:	14ce                	slli	s1,s1,0x33
    80003a10:	90d9                	srli	s1,s1,0x36
    80003a12:	00950733          	add	a4,a0,s1
    80003a16:	05874703          	lbu	a4,88(a4)
    80003a1a:	00e7f6b3          	and	a3,a5,a4
    80003a1e:	c69d                	beqz	a3,80003a4c <bfree+0x6c>
    80003a20:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a22:	94aa                	add	s1,s1,a0
    80003a24:	fff7c793          	not	a5,a5
    80003a28:	8ff9                	and	a5,a5,a4
    80003a2a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a2e:	00001097          	auipc	ra,0x1
    80003a32:	430080e7          	jalr	1072(ra) # 80004e5e <log_write>
  brelse(bp);
    80003a36:	854a                	mv	a0,s2
    80003a38:	00000097          	auipc	ra,0x0
    80003a3c:	e92080e7          	jalr	-366(ra) # 800038ca <brelse>
}
    80003a40:	60e2                	ld	ra,24(sp)
    80003a42:	6442                	ld	s0,16(sp)
    80003a44:	64a2                	ld	s1,8(sp)
    80003a46:	6902                	ld	s2,0(sp)
    80003a48:	6105                	addi	sp,sp,32
    80003a4a:	8082                	ret
    panic("freeing free block");
    80003a4c:	00006517          	auipc	a0,0x6
    80003a50:	db450513          	addi	a0,a0,-588 # 80009800 <syscalls+0xe8>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	ad6080e7          	jalr	-1322(ra) # 8000052a <panic>

0000000080003a5c <balloc>:
{
    80003a5c:	711d                	addi	sp,sp,-96
    80003a5e:	ec86                	sd	ra,88(sp)
    80003a60:	e8a2                	sd	s0,80(sp)
    80003a62:	e4a6                	sd	s1,72(sp)
    80003a64:	e0ca                	sd	s2,64(sp)
    80003a66:	fc4e                	sd	s3,56(sp)
    80003a68:	f852                	sd	s4,48(sp)
    80003a6a:	f456                	sd	s5,40(sp)
    80003a6c:	f05a                	sd	s6,32(sp)
    80003a6e:	ec5e                	sd	s7,24(sp)
    80003a70:	e862                	sd	s8,16(sp)
    80003a72:	e466                	sd	s9,8(sp)
    80003a74:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a76:	00025797          	auipc	a5,0x25
    80003a7a:	1367a783          	lw	a5,310(a5) # 80028bac <sb+0x4>
    80003a7e:	cbd1                	beqz	a5,80003b12 <balloc+0xb6>
    80003a80:	8baa                	mv	s7,a0
    80003a82:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a84:	00025b17          	auipc	s6,0x25
    80003a88:	124b0b13          	addi	s6,s6,292 # 80028ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a8c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a8e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a90:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a92:	6c89                	lui	s9,0x2
    80003a94:	a831                	j	80003ab0 <balloc+0x54>
    brelse(bp);
    80003a96:	854a                	mv	a0,s2
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	e32080e7          	jalr	-462(ra) # 800038ca <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003aa0:	015c87bb          	addw	a5,s9,s5
    80003aa4:	00078a9b          	sext.w	s5,a5
    80003aa8:	004b2703          	lw	a4,4(s6)
    80003aac:	06eaf363          	bgeu	s5,a4,80003b12 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003ab0:	41fad79b          	sraiw	a5,s5,0x1f
    80003ab4:	0137d79b          	srliw	a5,a5,0x13
    80003ab8:	015787bb          	addw	a5,a5,s5
    80003abc:	40d7d79b          	sraiw	a5,a5,0xd
    80003ac0:	01cb2583          	lw	a1,28(s6)
    80003ac4:	9dbd                	addw	a1,a1,a5
    80003ac6:	855e                	mv	a0,s7
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	cd2080e7          	jalr	-814(ra) # 8000379a <bread>
    80003ad0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ad2:	004b2503          	lw	a0,4(s6)
    80003ad6:	000a849b          	sext.w	s1,s5
    80003ada:	8662                	mv	a2,s8
    80003adc:	faa4fde3          	bgeu	s1,a0,80003a96 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003ae0:	41f6579b          	sraiw	a5,a2,0x1f
    80003ae4:	01d7d69b          	srliw	a3,a5,0x1d
    80003ae8:	00c6873b          	addw	a4,a3,a2
    80003aec:	00777793          	andi	a5,a4,7
    80003af0:	9f95                	subw	a5,a5,a3
    80003af2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003af6:	4037571b          	sraiw	a4,a4,0x3
    80003afa:	00e906b3          	add	a3,s2,a4
    80003afe:	0586c683          	lbu	a3,88(a3)
    80003b02:	00d7f5b3          	and	a1,a5,a3
    80003b06:	cd91                	beqz	a1,80003b22 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b08:	2605                	addiw	a2,a2,1
    80003b0a:	2485                	addiw	s1,s1,1
    80003b0c:	fd4618e3          	bne	a2,s4,80003adc <balloc+0x80>
    80003b10:	b759                	j	80003a96 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003b12:	00006517          	auipc	a0,0x6
    80003b16:	d0650513          	addi	a0,a0,-762 # 80009818 <syscalls+0x100>
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	a10080e7          	jalr	-1520(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b22:	974a                	add	a4,a4,s2
    80003b24:	8fd5                	or	a5,a5,a3
    80003b26:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	332080e7          	jalr	818(ra) # 80004e5e <log_write>
        brelse(bp);
    80003b34:	854a                	mv	a0,s2
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	d94080e7          	jalr	-620(ra) # 800038ca <brelse>
  bp = bread(dev, bno);
    80003b3e:	85a6                	mv	a1,s1
    80003b40:	855e                	mv	a0,s7
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	c58080e7          	jalr	-936(ra) # 8000379a <bread>
    80003b4a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b4c:	40000613          	li	a2,1024
    80003b50:	4581                	li	a1,0
    80003b52:	05850513          	addi	a0,a0,88
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	168080e7          	jalr	360(ra) # 80000cbe <memset>
  log_write(bp);
    80003b5e:	854a                	mv	a0,s2
    80003b60:	00001097          	auipc	ra,0x1
    80003b64:	2fe080e7          	jalr	766(ra) # 80004e5e <log_write>
  brelse(bp);
    80003b68:	854a                	mv	a0,s2
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	d60080e7          	jalr	-672(ra) # 800038ca <brelse>
}
    80003b72:	8526                	mv	a0,s1
    80003b74:	60e6                	ld	ra,88(sp)
    80003b76:	6446                	ld	s0,80(sp)
    80003b78:	64a6                	ld	s1,72(sp)
    80003b7a:	6906                	ld	s2,64(sp)
    80003b7c:	79e2                	ld	s3,56(sp)
    80003b7e:	7a42                	ld	s4,48(sp)
    80003b80:	7aa2                	ld	s5,40(sp)
    80003b82:	7b02                	ld	s6,32(sp)
    80003b84:	6be2                	ld	s7,24(sp)
    80003b86:	6c42                	ld	s8,16(sp)
    80003b88:	6ca2                	ld	s9,8(sp)
    80003b8a:	6125                	addi	sp,sp,96
    80003b8c:	8082                	ret

0000000080003b8e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b8e:	7179                	addi	sp,sp,-48
    80003b90:	f406                	sd	ra,40(sp)
    80003b92:	f022                	sd	s0,32(sp)
    80003b94:	ec26                	sd	s1,24(sp)
    80003b96:	e84a                	sd	s2,16(sp)
    80003b98:	e44e                	sd	s3,8(sp)
    80003b9a:	e052                	sd	s4,0(sp)
    80003b9c:	1800                	addi	s0,sp,48
    80003b9e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ba0:	47ad                	li	a5,11
    80003ba2:	04b7fe63          	bgeu	a5,a1,80003bfe <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003ba6:	ff45849b          	addiw	s1,a1,-12
    80003baa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003bae:	0ff00793          	li	a5,255
    80003bb2:	0ae7e463          	bltu	a5,a4,80003c5a <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003bb6:	08052583          	lw	a1,128(a0)
    80003bba:	c5b5                	beqz	a1,80003c26 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003bbc:	00092503          	lw	a0,0(s2)
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	bda080e7          	jalr	-1062(ra) # 8000379a <bread>
    80003bc8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003bca:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003bce:	02049713          	slli	a4,s1,0x20
    80003bd2:	01e75593          	srli	a1,a4,0x1e
    80003bd6:	00b784b3          	add	s1,a5,a1
    80003bda:	0004a983          	lw	s3,0(s1)
    80003bde:	04098e63          	beqz	s3,80003c3a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003be2:	8552                	mv	a0,s4
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	ce6080e7          	jalr	-794(ra) # 800038ca <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003bec:	854e                	mv	a0,s3
    80003bee:	70a2                	ld	ra,40(sp)
    80003bf0:	7402                	ld	s0,32(sp)
    80003bf2:	64e2                	ld	s1,24(sp)
    80003bf4:	6942                	ld	s2,16(sp)
    80003bf6:	69a2                	ld	s3,8(sp)
    80003bf8:	6a02                	ld	s4,0(sp)
    80003bfa:	6145                	addi	sp,sp,48
    80003bfc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003bfe:	02059793          	slli	a5,a1,0x20
    80003c02:	01e7d593          	srli	a1,a5,0x1e
    80003c06:	00b504b3          	add	s1,a0,a1
    80003c0a:	0504a983          	lw	s3,80(s1)
    80003c0e:	fc099fe3          	bnez	s3,80003bec <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003c12:	4108                	lw	a0,0(a0)
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	e48080e7          	jalr	-440(ra) # 80003a5c <balloc>
    80003c1c:	0005099b          	sext.w	s3,a0
    80003c20:	0534a823          	sw	s3,80(s1)
    80003c24:	b7e1                	j	80003bec <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003c26:	4108                	lw	a0,0(a0)
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	e34080e7          	jalr	-460(ra) # 80003a5c <balloc>
    80003c30:	0005059b          	sext.w	a1,a0
    80003c34:	08b92023          	sw	a1,128(s2)
    80003c38:	b751                	j	80003bbc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c3a:	00092503          	lw	a0,0(s2)
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	e1e080e7          	jalr	-482(ra) # 80003a5c <balloc>
    80003c46:	0005099b          	sext.w	s3,a0
    80003c4a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c4e:	8552                	mv	a0,s4
    80003c50:	00001097          	auipc	ra,0x1
    80003c54:	20e080e7          	jalr	526(ra) # 80004e5e <log_write>
    80003c58:	b769                	j	80003be2 <bmap+0x54>
  panic("bmap: out of range");
    80003c5a:	00006517          	auipc	a0,0x6
    80003c5e:	bd650513          	addi	a0,a0,-1066 # 80009830 <syscalls+0x118>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	8c8080e7          	jalr	-1848(ra) # 8000052a <panic>

0000000080003c6a <iget>:
{
    80003c6a:	7179                	addi	sp,sp,-48
    80003c6c:	f406                	sd	ra,40(sp)
    80003c6e:	f022                	sd	s0,32(sp)
    80003c70:	ec26                	sd	s1,24(sp)
    80003c72:	e84a                	sd	s2,16(sp)
    80003c74:	e44e                	sd	s3,8(sp)
    80003c76:	e052                	sd	s4,0(sp)
    80003c78:	1800                	addi	s0,sp,48
    80003c7a:	89aa                	mv	s3,a0
    80003c7c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c7e:	00025517          	auipc	a0,0x25
    80003c82:	f4a50513          	addi	a0,a0,-182 # 80028bc8 <itable>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	f3c080e7          	jalr	-196(ra) # 80000bc2 <acquire>
  empty = 0;
    80003c8e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c90:	00025497          	auipc	s1,0x25
    80003c94:	f5048493          	addi	s1,s1,-176 # 80028be0 <itable+0x18>
    80003c98:	00027697          	auipc	a3,0x27
    80003c9c:	9d868693          	addi	a3,a3,-1576 # 8002a670 <log>
    80003ca0:	a039                	j	80003cae <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ca2:	02090b63          	beqz	s2,80003cd8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ca6:	08848493          	addi	s1,s1,136
    80003caa:	02d48a63          	beq	s1,a3,80003cde <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003cae:	449c                	lw	a5,8(s1)
    80003cb0:	fef059e3          	blez	a5,80003ca2 <iget+0x38>
    80003cb4:	4098                	lw	a4,0(s1)
    80003cb6:	ff3716e3          	bne	a4,s3,80003ca2 <iget+0x38>
    80003cba:	40d8                	lw	a4,4(s1)
    80003cbc:	ff4713e3          	bne	a4,s4,80003ca2 <iget+0x38>
      ip->ref++;
    80003cc0:	2785                	addiw	a5,a5,1
    80003cc2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003cc4:	00025517          	auipc	a0,0x25
    80003cc8:	f0450513          	addi	a0,a0,-252 # 80028bc8 <itable>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	faa080e7          	jalr	-86(ra) # 80000c76 <release>
      return ip;
    80003cd4:	8926                	mv	s2,s1
    80003cd6:	a03d                	j	80003d04 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cd8:	f7f9                	bnez	a5,80003ca6 <iget+0x3c>
    80003cda:	8926                	mv	s2,s1
    80003cdc:	b7e9                	j	80003ca6 <iget+0x3c>
  if(empty == 0)
    80003cde:	02090c63          	beqz	s2,80003d16 <iget+0xac>
  ip->dev = dev;
    80003ce2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ce6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003cea:	4785                	li	a5,1
    80003cec:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003cf0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003cf4:	00025517          	auipc	a0,0x25
    80003cf8:	ed450513          	addi	a0,a0,-300 # 80028bc8 <itable>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	f7a080e7          	jalr	-134(ra) # 80000c76 <release>
}
    80003d04:	854a                	mv	a0,s2
    80003d06:	70a2                	ld	ra,40(sp)
    80003d08:	7402                	ld	s0,32(sp)
    80003d0a:	64e2                	ld	s1,24(sp)
    80003d0c:	6942                	ld	s2,16(sp)
    80003d0e:	69a2                	ld	s3,8(sp)
    80003d10:	6a02                	ld	s4,0(sp)
    80003d12:	6145                	addi	sp,sp,48
    80003d14:	8082                	ret
    panic("iget: no inodes");
    80003d16:	00006517          	auipc	a0,0x6
    80003d1a:	b3250513          	addi	a0,a0,-1230 # 80009848 <syscalls+0x130>
    80003d1e:	ffffd097          	auipc	ra,0xffffd
    80003d22:	80c080e7          	jalr	-2036(ra) # 8000052a <panic>

0000000080003d26 <fsinit>:
fsinit(int dev) {
    80003d26:	7179                	addi	sp,sp,-48
    80003d28:	f406                	sd	ra,40(sp)
    80003d2a:	f022                	sd	s0,32(sp)
    80003d2c:	ec26                	sd	s1,24(sp)
    80003d2e:	e84a                	sd	s2,16(sp)
    80003d30:	e44e                	sd	s3,8(sp)
    80003d32:	1800                	addi	s0,sp,48
    80003d34:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d36:	4585                	li	a1,1
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	a62080e7          	jalr	-1438(ra) # 8000379a <bread>
    80003d40:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d42:	00025997          	auipc	s3,0x25
    80003d46:	e6698993          	addi	s3,s3,-410 # 80028ba8 <sb>
    80003d4a:	02000613          	li	a2,32
    80003d4e:	05850593          	addi	a1,a0,88
    80003d52:	854e                	mv	a0,s3
    80003d54:	ffffd097          	auipc	ra,0xffffd
    80003d58:	fc6080e7          	jalr	-58(ra) # 80000d1a <memmove>
  brelse(bp);
    80003d5c:	8526                	mv	a0,s1
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	b6c080e7          	jalr	-1172(ra) # 800038ca <brelse>
  if(sb.magic != FSMAGIC)
    80003d66:	0009a703          	lw	a4,0(s3)
    80003d6a:	102037b7          	lui	a5,0x10203
    80003d6e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d72:	02f71263          	bne	a4,a5,80003d96 <fsinit+0x70>
  initlog(dev, &sb);
    80003d76:	00025597          	auipc	a1,0x25
    80003d7a:	e3258593          	addi	a1,a1,-462 # 80028ba8 <sb>
    80003d7e:	854a                	mv	a0,s2
    80003d80:	00001097          	auipc	ra,0x1
    80003d84:	e60080e7          	jalr	-416(ra) # 80004be0 <initlog>
}
    80003d88:	70a2                	ld	ra,40(sp)
    80003d8a:	7402                	ld	s0,32(sp)
    80003d8c:	64e2                	ld	s1,24(sp)
    80003d8e:	6942                	ld	s2,16(sp)
    80003d90:	69a2                	ld	s3,8(sp)
    80003d92:	6145                	addi	sp,sp,48
    80003d94:	8082                	ret
    panic("invalid file system");
    80003d96:	00006517          	auipc	a0,0x6
    80003d9a:	ac250513          	addi	a0,a0,-1342 # 80009858 <syscalls+0x140>
    80003d9e:	ffffc097          	auipc	ra,0xffffc
    80003da2:	78c080e7          	jalr	1932(ra) # 8000052a <panic>

0000000080003da6 <iinit>:
{
    80003da6:	7179                	addi	sp,sp,-48
    80003da8:	f406                	sd	ra,40(sp)
    80003daa:	f022                	sd	s0,32(sp)
    80003dac:	ec26                	sd	s1,24(sp)
    80003dae:	e84a                	sd	s2,16(sp)
    80003db0:	e44e                	sd	s3,8(sp)
    80003db2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003db4:	00006597          	auipc	a1,0x6
    80003db8:	abc58593          	addi	a1,a1,-1348 # 80009870 <syscalls+0x158>
    80003dbc:	00025517          	auipc	a0,0x25
    80003dc0:	e0c50513          	addi	a0,a0,-500 # 80028bc8 <itable>
    80003dc4:	ffffd097          	auipc	ra,0xffffd
    80003dc8:	d6e080e7          	jalr	-658(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003dcc:	00025497          	auipc	s1,0x25
    80003dd0:	e2448493          	addi	s1,s1,-476 # 80028bf0 <itable+0x28>
    80003dd4:	00027997          	auipc	s3,0x27
    80003dd8:	8ac98993          	addi	s3,s3,-1876 # 8002a680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ddc:	00006917          	auipc	s2,0x6
    80003de0:	a9c90913          	addi	s2,s2,-1380 # 80009878 <syscalls+0x160>
    80003de4:	85ca                	mv	a1,s2
    80003de6:	8526                	mv	a0,s1
    80003de8:	00001097          	auipc	ra,0x1
    80003dec:	15c080e7          	jalr	348(ra) # 80004f44 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003df0:	08848493          	addi	s1,s1,136
    80003df4:	ff3498e3          	bne	s1,s3,80003de4 <iinit+0x3e>
}
    80003df8:	70a2                	ld	ra,40(sp)
    80003dfa:	7402                	ld	s0,32(sp)
    80003dfc:	64e2                	ld	s1,24(sp)
    80003dfe:	6942                	ld	s2,16(sp)
    80003e00:	69a2                	ld	s3,8(sp)
    80003e02:	6145                	addi	sp,sp,48
    80003e04:	8082                	ret

0000000080003e06 <ialloc>:
{
    80003e06:	715d                	addi	sp,sp,-80
    80003e08:	e486                	sd	ra,72(sp)
    80003e0a:	e0a2                	sd	s0,64(sp)
    80003e0c:	fc26                	sd	s1,56(sp)
    80003e0e:	f84a                	sd	s2,48(sp)
    80003e10:	f44e                	sd	s3,40(sp)
    80003e12:	f052                	sd	s4,32(sp)
    80003e14:	ec56                	sd	s5,24(sp)
    80003e16:	e85a                	sd	s6,16(sp)
    80003e18:	e45e                	sd	s7,8(sp)
    80003e1a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e1c:	00025717          	auipc	a4,0x25
    80003e20:	d9872703          	lw	a4,-616(a4) # 80028bb4 <sb+0xc>
    80003e24:	4785                	li	a5,1
    80003e26:	04e7fa63          	bgeu	a5,a4,80003e7a <ialloc+0x74>
    80003e2a:	8aaa                	mv	s5,a0
    80003e2c:	8bae                	mv	s7,a1
    80003e2e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e30:	00025a17          	auipc	s4,0x25
    80003e34:	d78a0a13          	addi	s4,s4,-648 # 80028ba8 <sb>
    80003e38:	00048b1b          	sext.w	s6,s1
    80003e3c:	0044d793          	srli	a5,s1,0x4
    80003e40:	018a2583          	lw	a1,24(s4)
    80003e44:	9dbd                	addw	a1,a1,a5
    80003e46:	8556                	mv	a0,s5
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	952080e7          	jalr	-1710(ra) # 8000379a <bread>
    80003e50:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e52:	05850993          	addi	s3,a0,88
    80003e56:	00f4f793          	andi	a5,s1,15
    80003e5a:	079a                	slli	a5,a5,0x6
    80003e5c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e5e:	00099783          	lh	a5,0(s3)
    80003e62:	c785                	beqz	a5,80003e8a <ialloc+0x84>
    brelse(bp);
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	a66080e7          	jalr	-1434(ra) # 800038ca <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e6c:	0485                	addi	s1,s1,1
    80003e6e:	00ca2703          	lw	a4,12(s4)
    80003e72:	0004879b          	sext.w	a5,s1
    80003e76:	fce7e1e3          	bltu	a5,a4,80003e38 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e7a:	00006517          	auipc	a0,0x6
    80003e7e:	a0650513          	addi	a0,a0,-1530 # 80009880 <syscalls+0x168>
    80003e82:	ffffc097          	auipc	ra,0xffffc
    80003e86:	6a8080e7          	jalr	1704(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003e8a:	04000613          	li	a2,64
    80003e8e:	4581                	li	a1,0
    80003e90:	854e                	mv	a0,s3
    80003e92:	ffffd097          	auipc	ra,0xffffd
    80003e96:	e2c080e7          	jalr	-468(ra) # 80000cbe <memset>
      dip->type = type;
    80003e9a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00001097          	auipc	ra,0x1
    80003ea4:	fbe080e7          	jalr	-66(ra) # 80004e5e <log_write>
      brelse(bp);
    80003ea8:	854a                	mv	a0,s2
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	a20080e7          	jalr	-1504(ra) # 800038ca <brelse>
      return iget(dev, inum);
    80003eb2:	85da                	mv	a1,s6
    80003eb4:	8556                	mv	a0,s5
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	db4080e7          	jalr	-588(ra) # 80003c6a <iget>
}
    80003ebe:	60a6                	ld	ra,72(sp)
    80003ec0:	6406                	ld	s0,64(sp)
    80003ec2:	74e2                	ld	s1,56(sp)
    80003ec4:	7942                	ld	s2,48(sp)
    80003ec6:	79a2                	ld	s3,40(sp)
    80003ec8:	7a02                	ld	s4,32(sp)
    80003eca:	6ae2                	ld	s5,24(sp)
    80003ecc:	6b42                	ld	s6,16(sp)
    80003ece:	6ba2                	ld	s7,8(sp)
    80003ed0:	6161                	addi	sp,sp,80
    80003ed2:	8082                	ret

0000000080003ed4 <iupdate>:
{
    80003ed4:	1101                	addi	sp,sp,-32
    80003ed6:	ec06                	sd	ra,24(sp)
    80003ed8:	e822                	sd	s0,16(sp)
    80003eda:	e426                	sd	s1,8(sp)
    80003edc:	e04a                	sd	s2,0(sp)
    80003ede:	1000                	addi	s0,sp,32
    80003ee0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ee2:	415c                	lw	a5,4(a0)
    80003ee4:	0047d79b          	srliw	a5,a5,0x4
    80003ee8:	00025597          	auipc	a1,0x25
    80003eec:	cd85a583          	lw	a1,-808(a1) # 80028bc0 <sb+0x18>
    80003ef0:	9dbd                	addw	a1,a1,a5
    80003ef2:	4108                	lw	a0,0(a0)
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	8a6080e7          	jalr	-1882(ra) # 8000379a <bread>
    80003efc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003efe:	05850793          	addi	a5,a0,88
    80003f02:	40c8                	lw	a0,4(s1)
    80003f04:	893d                	andi	a0,a0,15
    80003f06:	051a                	slli	a0,a0,0x6
    80003f08:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f0a:	04449703          	lh	a4,68(s1)
    80003f0e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f12:	04649703          	lh	a4,70(s1)
    80003f16:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f1a:	04849703          	lh	a4,72(s1)
    80003f1e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f22:	04a49703          	lh	a4,74(s1)
    80003f26:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f2a:	44f8                	lw	a4,76(s1)
    80003f2c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f2e:	03400613          	li	a2,52
    80003f32:	05048593          	addi	a1,s1,80
    80003f36:	0531                	addi	a0,a0,12
    80003f38:	ffffd097          	auipc	ra,0xffffd
    80003f3c:	de2080e7          	jalr	-542(ra) # 80000d1a <memmove>
  log_write(bp);
    80003f40:	854a                	mv	a0,s2
    80003f42:	00001097          	auipc	ra,0x1
    80003f46:	f1c080e7          	jalr	-228(ra) # 80004e5e <log_write>
  brelse(bp);
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	97e080e7          	jalr	-1666(ra) # 800038ca <brelse>
}
    80003f54:	60e2                	ld	ra,24(sp)
    80003f56:	6442                	ld	s0,16(sp)
    80003f58:	64a2                	ld	s1,8(sp)
    80003f5a:	6902                	ld	s2,0(sp)
    80003f5c:	6105                	addi	sp,sp,32
    80003f5e:	8082                	ret

0000000080003f60 <idup>:
{
    80003f60:	1101                	addi	sp,sp,-32
    80003f62:	ec06                	sd	ra,24(sp)
    80003f64:	e822                	sd	s0,16(sp)
    80003f66:	e426                	sd	s1,8(sp)
    80003f68:	1000                	addi	s0,sp,32
    80003f6a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f6c:	00025517          	auipc	a0,0x25
    80003f70:	c5c50513          	addi	a0,a0,-932 # 80028bc8 <itable>
    80003f74:	ffffd097          	auipc	ra,0xffffd
    80003f78:	c4e080e7          	jalr	-946(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003f7c:	449c                	lw	a5,8(s1)
    80003f7e:	2785                	addiw	a5,a5,1
    80003f80:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f82:	00025517          	auipc	a0,0x25
    80003f86:	c4650513          	addi	a0,a0,-954 # 80028bc8 <itable>
    80003f8a:	ffffd097          	auipc	ra,0xffffd
    80003f8e:	cec080e7          	jalr	-788(ra) # 80000c76 <release>
}
    80003f92:	8526                	mv	a0,s1
    80003f94:	60e2                	ld	ra,24(sp)
    80003f96:	6442                	ld	s0,16(sp)
    80003f98:	64a2                	ld	s1,8(sp)
    80003f9a:	6105                	addi	sp,sp,32
    80003f9c:	8082                	ret

0000000080003f9e <ilock>:
{
    80003f9e:	1101                	addi	sp,sp,-32
    80003fa0:	ec06                	sd	ra,24(sp)
    80003fa2:	e822                	sd	s0,16(sp)
    80003fa4:	e426                	sd	s1,8(sp)
    80003fa6:	e04a                	sd	s2,0(sp)
    80003fa8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003faa:	c115                	beqz	a0,80003fce <ilock+0x30>
    80003fac:	84aa                	mv	s1,a0
    80003fae:	451c                	lw	a5,8(a0)
    80003fb0:	00f05f63          	blez	a5,80003fce <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fb4:	0541                	addi	a0,a0,16
    80003fb6:	00001097          	auipc	ra,0x1
    80003fba:	fc8080e7          	jalr	-56(ra) # 80004f7e <acquiresleep>
  if(ip->valid == 0){
    80003fbe:	40bc                	lw	a5,64(s1)
    80003fc0:	cf99                	beqz	a5,80003fde <ilock+0x40>
}
    80003fc2:	60e2                	ld	ra,24(sp)
    80003fc4:	6442                	ld	s0,16(sp)
    80003fc6:	64a2                	ld	s1,8(sp)
    80003fc8:	6902                	ld	s2,0(sp)
    80003fca:	6105                	addi	sp,sp,32
    80003fcc:	8082                	ret
    panic("ilock");
    80003fce:	00006517          	auipc	a0,0x6
    80003fd2:	8ca50513          	addi	a0,a0,-1846 # 80009898 <syscalls+0x180>
    80003fd6:	ffffc097          	auipc	ra,0xffffc
    80003fda:	554080e7          	jalr	1364(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003fde:	40dc                	lw	a5,4(s1)
    80003fe0:	0047d79b          	srliw	a5,a5,0x4
    80003fe4:	00025597          	auipc	a1,0x25
    80003fe8:	bdc5a583          	lw	a1,-1060(a1) # 80028bc0 <sb+0x18>
    80003fec:	9dbd                	addw	a1,a1,a5
    80003fee:	4088                	lw	a0,0(s1)
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	7aa080e7          	jalr	1962(ra) # 8000379a <bread>
    80003ff8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ffa:	05850593          	addi	a1,a0,88
    80003ffe:	40dc                	lw	a5,4(s1)
    80004000:	8bbd                	andi	a5,a5,15
    80004002:	079a                	slli	a5,a5,0x6
    80004004:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004006:	00059783          	lh	a5,0(a1)
    8000400a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000400e:	00259783          	lh	a5,2(a1)
    80004012:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004016:	00459783          	lh	a5,4(a1)
    8000401a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000401e:	00659783          	lh	a5,6(a1)
    80004022:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004026:	459c                	lw	a5,8(a1)
    80004028:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000402a:	03400613          	li	a2,52
    8000402e:	05b1                	addi	a1,a1,12
    80004030:	05048513          	addi	a0,s1,80
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	ce6080e7          	jalr	-794(ra) # 80000d1a <memmove>
    brelse(bp);
    8000403c:	854a                	mv	a0,s2
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	88c080e7          	jalr	-1908(ra) # 800038ca <brelse>
    ip->valid = 1;
    80004046:	4785                	li	a5,1
    80004048:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000404a:	04449783          	lh	a5,68(s1)
    8000404e:	fbb5                	bnez	a5,80003fc2 <ilock+0x24>
      panic("ilock: no type");
    80004050:	00006517          	auipc	a0,0x6
    80004054:	85050513          	addi	a0,a0,-1968 # 800098a0 <syscalls+0x188>
    80004058:	ffffc097          	auipc	ra,0xffffc
    8000405c:	4d2080e7          	jalr	1234(ra) # 8000052a <panic>

0000000080004060 <iunlock>:
{
    80004060:	1101                	addi	sp,sp,-32
    80004062:	ec06                	sd	ra,24(sp)
    80004064:	e822                	sd	s0,16(sp)
    80004066:	e426                	sd	s1,8(sp)
    80004068:	e04a                	sd	s2,0(sp)
    8000406a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000406c:	c905                	beqz	a0,8000409c <iunlock+0x3c>
    8000406e:	84aa                	mv	s1,a0
    80004070:	01050913          	addi	s2,a0,16
    80004074:	854a                	mv	a0,s2
    80004076:	00001097          	auipc	ra,0x1
    8000407a:	fa2080e7          	jalr	-94(ra) # 80005018 <holdingsleep>
    8000407e:	cd19                	beqz	a0,8000409c <iunlock+0x3c>
    80004080:	449c                	lw	a5,8(s1)
    80004082:	00f05d63          	blez	a5,8000409c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004086:	854a                	mv	a0,s2
    80004088:	00001097          	auipc	ra,0x1
    8000408c:	f4c080e7          	jalr	-180(ra) # 80004fd4 <releasesleep>
}
    80004090:	60e2                	ld	ra,24(sp)
    80004092:	6442                	ld	s0,16(sp)
    80004094:	64a2                	ld	s1,8(sp)
    80004096:	6902                	ld	s2,0(sp)
    80004098:	6105                	addi	sp,sp,32
    8000409a:	8082                	ret
    panic("iunlock");
    8000409c:	00006517          	auipc	a0,0x6
    800040a0:	81450513          	addi	a0,a0,-2028 # 800098b0 <syscalls+0x198>
    800040a4:	ffffc097          	auipc	ra,0xffffc
    800040a8:	486080e7          	jalr	1158(ra) # 8000052a <panic>

00000000800040ac <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040ac:	7179                	addi	sp,sp,-48
    800040ae:	f406                	sd	ra,40(sp)
    800040b0:	f022                	sd	s0,32(sp)
    800040b2:	ec26                	sd	s1,24(sp)
    800040b4:	e84a                	sd	s2,16(sp)
    800040b6:	e44e                	sd	s3,8(sp)
    800040b8:	e052                	sd	s4,0(sp)
    800040ba:	1800                	addi	s0,sp,48
    800040bc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040be:	05050493          	addi	s1,a0,80
    800040c2:	08050913          	addi	s2,a0,128
    800040c6:	a021                	j	800040ce <itrunc+0x22>
    800040c8:	0491                	addi	s1,s1,4
    800040ca:	01248d63          	beq	s1,s2,800040e4 <itrunc+0x38>
    if(ip->addrs[i]){
    800040ce:	408c                	lw	a1,0(s1)
    800040d0:	dde5                	beqz	a1,800040c8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040d2:	0009a503          	lw	a0,0(s3)
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	90a080e7          	jalr	-1782(ra) # 800039e0 <bfree>
      ip->addrs[i] = 0;
    800040de:	0004a023          	sw	zero,0(s1)
    800040e2:	b7dd                	j	800040c8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800040e4:	0809a583          	lw	a1,128(s3)
    800040e8:	e185                	bnez	a1,80004108 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800040ea:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800040ee:	854e                	mv	a0,s3
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	de4080e7          	jalr	-540(ra) # 80003ed4 <iupdate>
}
    800040f8:	70a2                	ld	ra,40(sp)
    800040fa:	7402                	ld	s0,32(sp)
    800040fc:	64e2                	ld	s1,24(sp)
    800040fe:	6942                	ld	s2,16(sp)
    80004100:	69a2                	ld	s3,8(sp)
    80004102:	6a02                	ld	s4,0(sp)
    80004104:	6145                	addi	sp,sp,48
    80004106:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004108:	0009a503          	lw	a0,0(s3)
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	68e080e7          	jalr	1678(ra) # 8000379a <bread>
    80004114:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004116:	05850493          	addi	s1,a0,88
    8000411a:	45850913          	addi	s2,a0,1112
    8000411e:	a021                	j	80004126 <itrunc+0x7a>
    80004120:	0491                	addi	s1,s1,4
    80004122:	01248b63          	beq	s1,s2,80004138 <itrunc+0x8c>
      if(a[j])
    80004126:	408c                	lw	a1,0(s1)
    80004128:	dde5                	beqz	a1,80004120 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000412a:	0009a503          	lw	a0,0(s3)
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	8b2080e7          	jalr	-1870(ra) # 800039e0 <bfree>
    80004136:	b7ed                	j	80004120 <itrunc+0x74>
    brelse(bp);
    80004138:	8552                	mv	a0,s4
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	790080e7          	jalr	1936(ra) # 800038ca <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004142:	0809a583          	lw	a1,128(s3)
    80004146:	0009a503          	lw	a0,0(s3)
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	896080e7          	jalr	-1898(ra) # 800039e0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004152:	0809a023          	sw	zero,128(s3)
    80004156:	bf51                	j	800040ea <itrunc+0x3e>

0000000080004158 <iput>:
{
    80004158:	1101                	addi	sp,sp,-32
    8000415a:	ec06                	sd	ra,24(sp)
    8000415c:	e822                	sd	s0,16(sp)
    8000415e:	e426                	sd	s1,8(sp)
    80004160:	e04a                	sd	s2,0(sp)
    80004162:	1000                	addi	s0,sp,32
    80004164:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004166:	00025517          	auipc	a0,0x25
    8000416a:	a6250513          	addi	a0,a0,-1438 # 80028bc8 <itable>
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	a54080e7          	jalr	-1452(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004176:	4498                	lw	a4,8(s1)
    80004178:	4785                	li	a5,1
    8000417a:	02f70363          	beq	a4,a5,800041a0 <iput+0x48>
  ip->ref--;
    8000417e:	449c                	lw	a5,8(s1)
    80004180:	37fd                	addiw	a5,a5,-1
    80004182:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004184:	00025517          	auipc	a0,0x25
    80004188:	a4450513          	addi	a0,a0,-1468 # 80028bc8 <itable>
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	aea080e7          	jalr	-1302(ra) # 80000c76 <release>
}
    80004194:	60e2                	ld	ra,24(sp)
    80004196:	6442                	ld	s0,16(sp)
    80004198:	64a2                	ld	s1,8(sp)
    8000419a:	6902                	ld	s2,0(sp)
    8000419c:	6105                	addi	sp,sp,32
    8000419e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041a0:	40bc                	lw	a5,64(s1)
    800041a2:	dff1                	beqz	a5,8000417e <iput+0x26>
    800041a4:	04a49783          	lh	a5,74(s1)
    800041a8:	fbf9                	bnez	a5,8000417e <iput+0x26>
    acquiresleep(&ip->lock);
    800041aa:	01048913          	addi	s2,s1,16
    800041ae:	854a                	mv	a0,s2
    800041b0:	00001097          	auipc	ra,0x1
    800041b4:	dce080e7          	jalr	-562(ra) # 80004f7e <acquiresleep>
    release(&itable.lock);
    800041b8:	00025517          	auipc	a0,0x25
    800041bc:	a1050513          	addi	a0,a0,-1520 # 80028bc8 <itable>
    800041c0:	ffffd097          	auipc	ra,0xffffd
    800041c4:	ab6080e7          	jalr	-1354(ra) # 80000c76 <release>
    itrunc(ip);
    800041c8:	8526                	mv	a0,s1
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	ee2080e7          	jalr	-286(ra) # 800040ac <itrunc>
    ip->type = 0;
    800041d2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041d6:	8526                	mv	a0,s1
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	cfc080e7          	jalr	-772(ra) # 80003ed4 <iupdate>
    ip->valid = 0;
    800041e0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800041e4:	854a                	mv	a0,s2
    800041e6:	00001097          	auipc	ra,0x1
    800041ea:	dee080e7          	jalr	-530(ra) # 80004fd4 <releasesleep>
    acquire(&itable.lock);
    800041ee:	00025517          	auipc	a0,0x25
    800041f2:	9da50513          	addi	a0,a0,-1574 # 80028bc8 <itable>
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	9cc080e7          	jalr	-1588(ra) # 80000bc2 <acquire>
    800041fe:	b741                	j	8000417e <iput+0x26>

0000000080004200 <iunlockput>:
{
    80004200:	1101                	addi	sp,sp,-32
    80004202:	ec06                	sd	ra,24(sp)
    80004204:	e822                	sd	s0,16(sp)
    80004206:	e426                	sd	s1,8(sp)
    80004208:	1000                	addi	s0,sp,32
    8000420a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	e54080e7          	jalr	-428(ra) # 80004060 <iunlock>
  iput(ip);
    80004214:	8526                	mv	a0,s1
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	f42080e7          	jalr	-190(ra) # 80004158 <iput>
}
    8000421e:	60e2                	ld	ra,24(sp)
    80004220:	6442                	ld	s0,16(sp)
    80004222:	64a2                	ld	s1,8(sp)
    80004224:	6105                	addi	sp,sp,32
    80004226:	8082                	ret

0000000080004228 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004228:	1141                	addi	sp,sp,-16
    8000422a:	e422                	sd	s0,8(sp)
    8000422c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000422e:	411c                	lw	a5,0(a0)
    80004230:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004232:	415c                	lw	a5,4(a0)
    80004234:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004236:	04451783          	lh	a5,68(a0)
    8000423a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000423e:	04a51783          	lh	a5,74(a0)
    80004242:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004246:	04c56783          	lwu	a5,76(a0)
    8000424a:	e99c                	sd	a5,16(a1)
}
    8000424c:	6422                	ld	s0,8(sp)
    8000424e:	0141                	addi	sp,sp,16
    80004250:	8082                	ret

0000000080004252 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004252:	457c                	lw	a5,76(a0)
    80004254:	0ed7e963          	bltu	a5,a3,80004346 <readi+0xf4>
{
    80004258:	7159                	addi	sp,sp,-112
    8000425a:	f486                	sd	ra,104(sp)
    8000425c:	f0a2                	sd	s0,96(sp)
    8000425e:	eca6                	sd	s1,88(sp)
    80004260:	e8ca                	sd	s2,80(sp)
    80004262:	e4ce                	sd	s3,72(sp)
    80004264:	e0d2                	sd	s4,64(sp)
    80004266:	fc56                	sd	s5,56(sp)
    80004268:	f85a                	sd	s6,48(sp)
    8000426a:	f45e                	sd	s7,40(sp)
    8000426c:	f062                	sd	s8,32(sp)
    8000426e:	ec66                	sd	s9,24(sp)
    80004270:	e86a                	sd	s10,16(sp)
    80004272:	e46e                	sd	s11,8(sp)
    80004274:	1880                	addi	s0,sp,112
    80004276:	8baa                	mv	s7,a0
    80004278:	8c2e                	mv	s8,a1
    8000427a:	8ab2                	mv	s5,a2
    8000427c:	84b6                	mv	s1,a3
    8000427e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004280:	9f35                	addw	a4,a4,a3
    return 0;
    80004282:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004284:	0ad76063          	bltu	a4,a3,80004324 <readi+0xd2>
  if(off + n > ip->size)
    80004288:	00e7f463          	bgeu	a5,a4,80004290 <readi+0x3e>
    n = ip->size - off;
    8000428c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004290:	0a0b0963          	beqz	s6,80004342 <readi+0xf0>
    80004294:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004296:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000429a:	5cfd                	li	s9,-1
    8000429c:	a82d                	j	800042d6 <readi+0x84>
    8000429e:	020a1d93          	slli	s11,s4,0x20
    800042a2:	020ddd93          	srli	s11,s11,0x20
    800042a6:	05890793          	addi	a5,s2,88
    800042aa:	86ee                	mv	a3,s11
    800042ac:	963e                	add	a2,a2,a5
    800042ae:	85d6                	mv	a1,s5
    800042b0:	8562                	mv	a0,s8
    800042b2:	ffffe097          	auipc	ra,0xffffe
    800042b6:	eea080e7          	jalr	-278(ra) # 8000219c <either_copyout>
    800042ba:	05950d63          	beq	a0,s9,80004314 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042be:	854a                	mv	a0,s2
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	60a080e7          	jalr	1546(ra) # 800038ca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042c8:	013a09bb          	addw	s3,s4,s3
    800042cc:	009a04bb          	addw	s1,s4,s1
    800042d0:	9aee                	add	s5,s5,s11
    800042d2:	0569f763          	bgeu	s3,s6,80004320 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042d6:	000ba903          	lw	s2,0(s7)
    800042da:	00a4d59b          	srliw	a1,s1,0xa
    800042de:	855e                	mv	a0,s7
    800042e0:	00000097          	auipc	ra,0x0
    800042e4:	8ae080e7          	jalr	-1874(ra) # 80003b8e <bmap>
    800042e8:	0005059b          	sext.w	a1,a0
    800042ec:	854a                	mv	a0,s2
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	4ac080e7          	jalr	1196(ra) # 8000379a <bread>
    800042f6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042f8:	3ff4f613          	andi	a2,s1,1023
    800042fc:	40cd07bb          	subw	a5,s10,a2
    80004300:	413b073b          	subw	a4,s6,s3
    80004304:	8a3e                	mv	s4,a5
    80004306:	2781                	sext.w	a5,a5
    80004308:	0007069b          	sext.w	a3,a4
    8000430c:	f8f6f9e3          	bgeu	a3,a5,8000429e <readi+0x4c>
    80004310:	8a3a                	mv	s4,a4
    80004312:	b771                	j	8000429e <readi+0x4c>
      brelse(bp);
    80004314:	854a                	mv	a0,s2
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	5b4080e7          	jalr	1460(ra) # 800038ca <brelse>
      tot = -1;
    8000431e:	59fd                	li	s3,-1
  }
  return tot;
    80004320:	0009851b          	sext.w	a0,s3
}
    80004324:	70a6                	ld	ra,104(sp)
    80004326:	7406                	ld	s0,96(sp)
    80004328:	64e6                	ld	s1,88(sp)
    8000432a:	6946                	ld	s2,80(sp)
    8000432c:	69a6                	ld	s3,72(sp)
    8000432e:	6a06                	ld	s4,64(sp)
    80004330:	7ae2                	ld	s5,56(sp)
    80004332:	7b42                	ld	s6,48(sp)
    80004334:	7ba2                	ld	s7,40(sp)
    80004336:	7c02                	ld	s8,32(sp)
    80004338:	6ce2                	ld	s9,24(sp)
    8000433a:	6d42                	ld	s10,16(sp)
    8000433c:	6da2                	ld	s11,8(sp)
    8000433e:	6165                	addi	sp,sp,112
    80004340:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004342:	89da                	mv	s3,s6
    80004344:	bff1                	j	80004320 <readi+0xce>
    return 0;
    80004346:	4501                	li	a0,0
}
    80004348:	8082                	ret

000000008000434a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000434a:	457c                	lw	a5,76(a0)
    8000434c:	10d7e863          	bltu	a5,a3,8000445c <writei+0x112>
{
    80004350:	7159                	addi	sp,sp,-112
    80004352:	f486                	sd	ra,104(sp)
    80004354:	f0a2                	sd	s0,96(sp)
    80004356:	eca6                	sd	s1,88(sp)
    80004358:	e8ca                	sd	s2,80(sp)
    8000435a:	e4ce                	sd	s3,72(sp)
    8000435c:	e0d2                	sd	s4,64(sp)
    8000435e:	fc56                	sd	s5,56(sp)
    80004360:	f85a                	sd	s6,48(sp)
    80004362:	f45e                	sd	s7,40(sp)
    80004364:	f062                	sd	s8,32(sp)
    80004366:	ec66                	sd	s9,24(sp)
    80004368:	e86a                	sd	s10,16(sp)
    8000436a:	e46e                	sd	s11,8(sp)
    8000436c:	1880                	addi	s0,sp,112
    8000436e:	8b2a                	mv	s6,a0
    80004370:	8c2e                	mv	s8,a1
    80004372:	8ab2                	mv	s5,a2
    80004374:	8936                	mv	s2,a3
    80004376:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004378:	00e687bb          	addw	a5,a3,a4
    8000437c:	0ed7e263          	bltu	a5,a3,80004460 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004380:	00043737          	lui	a4,0x43
    80004384:	0ef76063          	bltu	a4,a5,80004464 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004388:	0c0b8863          	beqz	s7,80004458 <writei+0x10e>
    8000438c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000438e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004392:	5cfd                	li	s9,-1
    80004394:	a091                	j	800043d8 <writei+0x8e>
    80004396:	02099d93          	slli	s11,s3,0x20
    8000439a:	020ddd93          	srli	s11,s11,0x20
    8000439e:	05848793          	addi	a5,s1,88
    800043a2:	86ee                	mv	a3,s11
    800043a4:	8656                	mv	a2,s5
    800043a6:	85e2                	mv	a1,s8
    800043a8:	953e                	add	a0,a0,a5
    800043aa:	ffffe097          	auipc	ra,0xffffe
    800043ae:	e48080e7          	jalr	-440(ra) # 800021f2 <either_copyin>
    800043b2:	07950263          	beq	a0,s9,80004416 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043b6:	8526                	mv	a0,s1
    800043b8:	00001097          	auipc	ra,0x1
    800043bc:	aa6080e7          	jalr	-1370(ra) # 80004e5e <log_write>
    brelse(bp);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	508080e7          	jalr	1288(ra) # 800038ca <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043ca:	01498a3b          	addw	s4,s3,s4
    800043ce:	0129893b          	addw	s2,s3,s2
    800043d2:	9aee                	add	s5,s5,s11
    800043d4:	057a7663          	bgeu	s4,s7,80004420 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043d8:	000b2483          	lw	s1,0(s6)
    800043dc:	00a9559b          	srliw	a1,s2,0xa
    800043e0:	855a                	mv	a0,s6
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	7ac080e7          	jalr	1964(ra) # 80003b8e <bmap>
    800043ea:	0005059b          	sext.w	a1,a0
    800043ee:	8526                	mv	a0,s1
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	3aa080e7          	jalr	938(ra) # 8000379a <bread>
    800043f8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043fa:	3ff97513          	andi	a0,s2,1023
    800043fe:	40ad07bb          	subw	a5,s10,a0
    80004402:	414b873b          	subw	a4,s7,s4
    80004406:	89be                	mv	s3,a5
    80004408:	2781                	sext.w	a5,a5
    8000440a:	0007069b          	sext.w	a3,a4
    8000440e:	f8f6f4e3          	bgeu	a3,a5,80004396 <writei+0x4c>
    80004412:	89ba                	mv	s3,a4
    80004414:	b749                	j	80004396 <writei+0x4c>
      brelse(bp);
    80004416:	8526                	mv	a0,s1
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	4b2080e7          	jalr	1202(ra) # 800038ca <brelse>
  }

  if(off > ip->size)
    80004420:	04cb2783          	lw	a5,76(s6)
    80004424:	0127f463          	bgeu	a5,s2,8000442c <writei+0xe2>
    ip->size = off;
    80004428:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000442c:	855a                	mv	a0,s6
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	aa6080e7          	jalr	-1370(ra) # 80003ed4 <iupdate>

  return tot;
    80004436:	000a051b          	sext.w	a0,s4
}
    8000443a:	70a6                	ld	ra,104(sp)
    8000443c:	7406                	ld	s0,96(sp)
    8000443e:	64e6                	ld	s1,88(sp)
    80004440:	6946                	ld	s2,80(sp)
    80004442:	69a6                	ld	s3,72(sp)
    80004444:	6a06                	ld	s4,64(sp)
    80004446:	7ae2                	ld	s5,56(sp)
    80004448:	7b42                	ld	s6,48(sp)
    8000444a:	7ba2                	ld	s7,40(sp)
    8000444c:	7c02                	ld	s8,32(sp)
    8000444e:	6ce2                	ld	s9,24(sp)
    80004450:	6d42                	ld	s10,16(sp)
    80004452:	6da2                	ld	s11,8(sp)
    80004454:	6165                	addi	sp,sp,112
    80004456:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004458:	8a5e                	mv	s4,s7
    8000445a:	bfc9                	j	8000442c <writei+0xe2>
    return -1;
    8000445c:	557d                	li	a0,-1
}
    8000445e:	8082                	ret
    return -1;
    80004460:	557d                	li	a0,-1
    80004462:	bfe1                	j	8000443a <writei+0xf0>
    return -1;
    80004464:	557d                	li	a0,-1
    80004466:	bfd1                	j	8000443a <writei+0xf0>

0000000080004468 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004468:	1141                	addi	sp,sp,-16
    8000446a:	e406                	sd	ra,8(sp)
    8000446c:	e022                	sd	s0,0(sp)
    8000446e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004470:	4639                	li	a2,14
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	924080e7          	jalr	-1756(ra) # 80000d96 <strncmp>
}
    8000447a:	60a2                	ld	ra,8(sp)
    8000447c:	6402                	ld	s0,0(sp)
    8000447e:	0141                	addi	sp,sp,16
    80004480:	8082                	ret

0000000080004482 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004482:	7139                	addi	sp,sp,-64
    80004484:	fc06                	sd	ra,56(sp)
    80004486:	f822                	sd	s0,48(sp)
    80004488:	f426                	sd	s1,40(sp)
    8000448a:	f04a                	sd	s2,32(sp)
    8000448c:	ec4e                	sd	s3,24(sp)
    8000448e:	e852                	sd	s4,16(sp)
    80004490:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004492:	04451703          	lh	a4,68(a0)
    80004496:	4785                	li	a5,1
    80004498:	00f71a63          	bne	a4,a5,800044ac <dirlookup+0x2a>
    8000449c:	892a                	mv	s2,a0
    8000449e:	89ae                	mv	s3,a1
    800044a0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044a2:	457c                	lw	a5,76(a0)
    800044a4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044a6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044a8:	e79d                	bnez	a5,800044d6 <dirlookup+0x54>
    800044aa:	a8a5                	j	80004522 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044ac:	00005517          	auipc	a0,0x5
    800044b0:	40c50513          	addi	a0,a0,1036 # 800098b8 <syscalls+0x1a0>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	076080e7          	jalr	118(ra) # 8000052a <panic>
      panic("dirlookup read");
    800044bc:	00005517          	auipc	a0,0x5
    800044c0:	41450513          	addi	a0,a0,1044 # 800098d0 <syscalls+0x1b8>
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	066080e7          	jalr	102(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044cc:	24c1                	addiw	s1,s1,16
    800044ce:	04c92783          	lw	a5,76(s2)
    800044d2:	04f4f763          	bgeu	s1,a5,80004520 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044d6:	4741                	li	a4,16
    800044d8:	86a6                	mv	a3,s1
    800044da:	fc040613          	addi	a2,s0,-64
    800044de:	4581                	li	a1,0
    800044e0:	854a                	mv	a0,s2
    800044e2:	00000097          	auipc	ra,0x0
    800044e6:	d70080e7          	jalr	-656(ra) # 80004252 <readi>
    800044ea:	47c1                	li	a5,16
    800044ec:	fcf518e3          	bne	a0,a5,800044bc <dirlookup+0x3a>
    if(de.inum == 0)
    800044f0:	fc045783          	lhu	a5,-64(s0)
    800044f4:	dfe1                	beqz	a5,800044cc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800044f6:	fc240593          	addi	a1,s0,-62
    800044fa:	854e                	mv	a0,s3
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	f6c080e7          	jalr	-148(ra) # 80004468 <namecmp>
    80004504:	f561                	bnez	a0,800044cc <dirlookup+0x4a>
      if(poff)
    80004506:	000a0463          	beqz	s4,8000450e <dirlookup+0x8c>
        *poff = off;
    8000450a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000450e:	fc045583          	lhu	a1,-64(s0)
    80004512:	00092503          	lw	a0,0(s2)
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	754080e7          	jalr	1876(ra) # 80003c6a <iget>
    8000451e:	a011                	j	80004522 <dirlookup+0xa0>
  return 0;
    80004520:	4501                	li	a0,0
}
    80004522:	70e2                	ld	ra,56(sp)
    80004524:	7442                	ld	s0,48(sp)
    80004526:	74a2                	ld	s1,40(sp)
    80004528:	7902                	ld	s2,32(sp)
    8000452a:	69e2                	ld	s3,24(sp)
    8000452c:	6a42                	ld	s4,16(sp)
    8000452e:	6121                	addi	sp,sp,64
    80004530:	8082                	ret

0000000080004532 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004532:	711d                	addi	sp,sp,-96
    80004534:	ec86                	sd	ra,88(sp)
    80004536:	e8a2                	sd	s0,80(sp)
    80004538:	e4a6                	sd	s1,72(sp)
    8000453a:	e0ca                	sd	s2,64(sp)
    8000453c:	fc4e                	sd	s3,56(sp)
    8000453e:	f852                	sd	s4,48(sp)
    80004540:	f456                	sd	s5,40(sp)
    80004542:	f05a                	sd	s6,32(sp)
    80004544:	ec5e                	sd	s7,24(sp)
    80004546:	e862                	sd	s8,16(sp)
    80004548:	e466                	sd	s9,8(sp)
    8000454a:	1080                	addi	s0,sp,96
    8000454c:	84aa                	mv	s1,a0
    8000454e:	8aae                	mv	s5,a1
    80004550:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004552:	00054703          	lbu	a4,0(a0)
    80004556:	02f00793          	li	a5,47
    8000455a:	02f70363          	beq	a4,a5,80004580 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000455e:	ffffd097          	auipc	ra,0xffffd
    80004562:	476080e7          	jalr	1142(ra) # 800019d4 <myproc>
    80004566:	15053503          	ld	a0,336(a0)
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	9f6080e7          	jalr	-1546(ra) # 80003f60 <idup>
    80004572:	89aa                	mv	s3,a0
  while(*path == '/')
    80004574:	02f00913          	li	s2,47
  len = path - s;
    80004578:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000457a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000457c:	4b85                	li	s7,1
    8000457e:	a865                	j	80004636 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004580:	4585                	li	a1,1
    80004582:	4505                	li	a0,1
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	6e6080e7          	jalr	1766(ra) # 80003c6a <iget>
    8000458c:	89aa                	mv	s3,a0
    8000458e:	b7dd                	j	80004574 <namex+0x42>
      iunlockput(ip);
    80004590:	854e                	mv	a0,s3
    80004592:	00000097          	auipc	ra,0x0
    80004596:	c6e080e7          	jalr	-914(ra) # 80004200 <iunlockput>
      return 0;
    8000459a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000459c:	854e                	mv	a0,s3
    8000459e:	60e6                	ld	ra,88(sp)
    800045a0:	6446                	ld	s0,80(sp)
    800045a2:	64a6                	ld	s1,72(sp)
    800045a4:	6906                	ld	s2,64(sp)
    800045a6:	79e2                	ld	s3,56(sp)
    800045a8:	7a42                	ld	s4,48(sp)
    800045aa:	7aa2                	ld	s5,40(sp)
    800045ac:	7b02                	ld	s6,32(sp)
    800045ae:	6be2                	ld	s7,24(sp)
    800045b0:	6c42                	ld	s8,16(sp)
    800045b2:	6ca2                	ld	s9,8(sp)
    800045b4:	6125                	addi	sp,sp,96
    800045b6:	8082                	ret
      iunlock(ip);
    800045b8:	854e                	mv	a0,s3
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	aa6080e7          	jalr	-1370(ra) # 80004060 <iunlock>
      return ip;
    800045c2:	bfe9                	j	8000459c <namex+0x6a>
      iunlockput(ip);
    800045c4:	854e                	mv	a0,s3
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	c3a080e7          	jalr	-966(ra) # 80004200 <iunlockput>
      return 0;
    800045ce:	89e6                	mv	s3,s9
    800045d0:	b7f1                	j	8000459c <namex+0x6a>
  len = path - s;
    800045d2:	40b48633          	sub	a2,s1,a1
    800045d6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800045da:	099c5463          	bge	s8,s9,80004662 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800045de:	4639                	li	a2,14
    800045e0:	8552                	mv	a0,s4
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	738080e7          	jalr	1848(ra) # 80000d1a <memmove>
  while(*path == '/')
    800045ea:	0004c783          	lbu	a5,0(s1)
    800045ee:	01279763          	bne	a5,s2,800045fc <namex+0xca>
    path++;
    800045f2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045f4:	0004c783          	lbu	a5,0(s1)
    800045f8:	ff278de3          	beq	a5,s2,800045f2 <namex+0xc0>
    ilock(ip);
    800045fc:	854e                	mv	a0,s3
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	9a0080e7          	jalr	-1632(ra) # 80003f9e <ilock>
    if(ip->type != T_DIR){
    80004606:	04499783          	lh	a5,68(s3)
    8000460a:	f97793e3          	bne	a5,s7,80004590 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000460e:	000a8563          	beqz	s5,80004618 <namex+0xe6>
    80004612:	0004c783          	lbu	a5,0(s1)
    80004616:	d3cd                	beqz	a5,800045b8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004618:	865a                	mv	a2,s6
    8000461a:	85d2                	mv	a1,s4
    8000461c:	854e                	mv	a0,s3
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	e64080e7          	jalr	-412(ra) # 80004482 <dirlookup>
    80004626:	8caa                	mv	s9,a0
    80004628:	dd51                	beqz	a0,800045c4 <namex+0x92>
    iunlockput(ip);
    8000462a:	854e                	mv	a0,s3
    8000462c:	00000097          	auipc	ra,0x0
    80004630:	bd4080e7          	jalr	-1068(ra) # 80004200 <iunlockput>
    ip = next;
    80004634:	89e6                	mv	s3,s9
  while(*path == '/')
    80004636:	0004c783          	lbu	a5,0(s1)
    8000463a:	05279763          	bne	a5,s2,80004688 <namex+0x156>
    path++;
    8000463e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004640:	0004c783          	lbu	a5,0(s1)
    80004644:	ff278de3          	beq	a5,s2,8000463e <namex+0x10c>
  if(*path == 0)
    80004648:	c79d                	beqz	a5,80004676 <namex+0x144>
    path++;
    8000464a:	85a6                	mv	a1,s1
  len = path - s;
    8000464c:	8cda                	mv	s9,s6
    8000464e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004650:	01278963          	beq	a5,s2,80004662 <namex+0x130>
    80004654:	dfbd                	beqz	a5,800045d2 <namex+0xa0>
    path++;
    80004656:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004658:	0004c783          	lbu	a5,0(s1)
    8000465c:	ff279ce3          	bne	a5,s2,80004654 <namex+0x122>
    80004660:	bf8d                	j	800045d2 <namex+0xa0>
    memmove(name, s, len);
    80004662:	2601                	sext.w	a2,a2
    80004664:	8552                	mv	a0,s4
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	6b4080e7          	jalr	1716(ra) # 80000d1a <memmove>
    name[len] = 0;
    8000466e:	9cd2                	add	s9,s9,s4
    80004670:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004674:	bf9d                	j	800045ea <namex+0xb8>
  if(nameiparent){
    80004676:	f20a83e3          	beqz	s5,8000459c <namex+0x6a>
    iput(ip);
    8000467a:	854e                	mv	a0,s3
    8000467c:	00000097          	auipc	ra,0x0
    80004680:	adc080e7          	jalr	-1316(ra) # 80004158 <iput>
    return 0;
    80004684:	4981                	li	s3,0
    80004686:	bf19                	j	8000459c <namex+0x6a>
  if(*path == 0)
    80004688:	d7fd                	beqz	a5,80004676 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000468a:	0004c783          	lbu	a5,0(s1)
    8000468e:	85a6                	mv	a1,s1
    80004690:	b7d1                	j	80004654 <namex+0x122>

0000000080004692 <dirlink>:
{
    80004692:	7139                	addi	sp,sp,-64
    80004694:	fc06                	sd	ra,56(sp)
    80004696:	f822                	sd	s0,48(sp)
    80004698:	f426                	sd	s1,40(sp)
    8000469a:	f04a                	sd	s2,32(sp)
    8000469c:	ec4e                	sd	s3,24(sp)
    8000469e:	e852                	sd	s4,16(sp)
    800046a0:	0080                	addi	s0,sp,64
    800046a2:	892a                	mv	s2,a0
    800046a4:	8a2e                	mv	s4,a1
    800046a6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046a8:	4601                	li	a2,0
    800046aa:	00000097          	auipc	ra,0x0
    800046ae:	dd8080e7          	jalr	-552(ra) # 80004482 <dirlookup>
    800046b2:	e93d                	bnez	a0,80004728 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046b4:	04c92483          	lw	s1,76(s2)
    800046b8:	c49d                	beqz	s1,800046e6 <dirlink+0x54>
    800046ba:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046bc:	4741                	li	a4,16
    800046be:	86a6                	mv	a3,s1
    800046c0:	fc040613          	addi	a2,s0,-64
    800046c4:	4581                	li	a1,0
    800046c6:	854a                	mv	a0,s2
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	b8a080e7          	jalr	-1142(ra) # 80004252 <readi>
    800046d0:	47c1                	li	a5,16
    800046d2:	06f51163          	bne	a0,a5,80004734 <dirlink+0xa2>
    if(de.inum == 0)
    800046d6:	fc045783          	lhu	a5,-64(s0)
    800046da:	c791                	beqz	a5,800046e6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046dc:	24c1                	addiw	s1,s1,16
    800046de:	04c92783          	lw	a5,76(s2)
    800046e2:	fcf4ede3          	bltu	s1,a5,800046bc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800046e6:	4639                	li	a2,14
    800046e8:	85d2                	mv	a1,s4
    800046ea:	fc240513          	addi	a0,s0,-62
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	6e4080e7          	jalr	1764(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    800046f6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046fa:	4741                	li	a4,16
    800046fc:	86a6                	mv	a3,s1
    800046fe:	fc040613          	addi	a2,s0,-64
    80004702:	4581                	li	a1,0
    80004704:	854a                	mv	a0,s2
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	c44080e7          	jalr	-956(ra) # 8000434a <writei>
    8000470e:	872a                	mv	a4,a0
    80004710:	47c1                	li	a5,16
  return 0;
    80004712:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004714:	02f71863          	bne	a4,a5,80004744 <dirlink+0xb2>
}
    80004718:	70e2                	ld	ra,56(sp)
    8000471a:	7442                	ld	s0,48(sp)
    8000471c:	74a2                	ld	s1,40(sp)
    8000471e:	7902                	ld	s2,32(sp)
    80004720:	69e2                	ld	s3,24(sp)
    80004722:	6a42                	ld	s4,16(sp)
    80004724:	6121                	addi	sp,sp,64
    80004726:	8082                	ret
    iput(ip);
    80004728:	00000097          	auipc	ra,0x0
    8000472c:	a30080e7          	jalr	-1488(ra) # 80004158 <iput>
    return -1;
    80004730:	557d                	li	a0,-1
    80004732:	b7dd                	j	80004718 <dirlink+0x86>
      panic("dirlink read");
    80004734:	00005517          	auipc	a0,0x5
    80004738:	1ac50513          	addi	a0,a0,428 # 800098e0 <syscalls+0x1c8>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	dee080e7          	jalr	-530(ra) # 8000052a <panic>
    panic("dirlink");
    80004744:	00005517          	auipc	a0,0x5
    80004748:	32450513          	addi	a0,a0,804 # 80009a68 <syscalls+0x350>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	dde080e7          	jalr	-546(ra) # 8000052a <panic>

0000000080004754 <namei>:

struct inode*
namei(char *path)
{
    80004754:	1101                	addi	sp,sp,-32
    80004756:	ec06                	sd	ra,24(sp)
    80004758:	e822                	sd	s0,16(sp)
    8000475a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000475c:	fe040613          	addi	a2,s0,-32
    80004760:	4581                	li	a1,0
    80004762:	00000097          	auipc	ra,0x0
    80004766:	dd0080e7          	jalr	-560(ra) # 80004532 <namex>
}
    8000476a:	60e2                	ld	ra,24(sp)
    8000476c:	6442                	ld	s0,16(sp)
    8000476e:	6105                	addi	sp,sp,32
    80004770:	8082                	ret

0000000080004772 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004772:	1141                	addi	sp,sp,-16
    80004774:	e406                	sd	ra,8(sp)
    80004776:	e022                	sd	s0,0(sp)
    80004778:	0800                	addi	s0,sp,16
    8000477a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000477c:	4585                	li	a1,1
    8000477e:	00000097          	auipc	ra,0x0
    80004782:	db4080e7          	jalr	-588(ra) # 80004532 <namex>
}
    80004786:	60a2                	ld	ra,8(sp)
    80004788:	6402                	ld	s0,0(sp)
    8000478a:	0141                	addi	sp,sp,16
    8000478c:	8082                	ret

000000008000478e <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    8000478e:	1101                	addi	sp,sp,-32
    80004790:	ec22                	sd	s0,24(sp)
    80004792:	1000                	addi	s0,sp,32
    80004794:	872a                	mv	a4,a0
    80004796:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    80004798:	00005797          	auipc	a5,0x5
    8000479c:	15878793          	addi	a5,a5,344 # 800098f0 <syscalls+0x1d8>
    800047a0:	6394                	ld	a3,0(a5)
    800047a2:	fed43023          	sd	a3,-32(s0)
    800047a6:	0087d683          	lhu	a3,8(a5)
    800047aa:	fed41423          	sh	a3,-24(s0)
    800047ae:	00a7c783          	lbu	a5,10(a5)
    800047b2:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800047b6:	87ae                	mv	a5,a1
    if(i<0){
    800047b8:	02074b63          	bltz	a4,800047ee <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800047bc:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800047be:	4629                	li	a2,10
        ++p;
    800047c0:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800047c2:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800047c6:	feed                	bnez	a3,800047c0 <itoa+0x32>
    *p = '\0';
    800047c8:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800047cc:	4629                	li	a2,10
    800047ce:	17fd                	addi	a5,a5,-1
    800047d0:	02c766bb          	remw	a3,a4,a2
    800047d4:	ff040593          	addi	a1,s0,-16
    800047d8:	96ae                	add	a3,a3,a1
    800047da:	ff06c683          	lbu	a3,-16(a3)
    800047de:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800047e2:	02c7473b          	divw	a4,a4,a2
    }while(i);
    800047e6:	f765                	bnez	a4,800047ce <itoa+0x40>
    return b;
}
    800047e8:	6462                	ld	s0,24(sp)
    800047ea:	6105                	addi	sp,sp,32
    800047ec:	8082                	ret
        *p++ = '-';
    800047ee:	00158793          	addi	a5,a1,1
    800047f2:	02d00693          	li	a3,45
    800047f6:	00d58023          	sb	a3,0(a1)
        i *= -1;
    800047fa:	40e0073b          	negw	a4,a4
    800047fe:	bf7d                	j	800047bc <itoa+0x2e>

0000000080004800 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004800:	711d                	addi	sp,sp,-96
    80004802:	ec86                	sd	ra,88(sp)
    80004804:	e8a2                	sd	s0,80(sp)
    80004806:	e4a6                	sd	s1,72(sp)
    80004808:	e0ca                	sd	s2,64(sp)
    8000480a:	1080                	addi	s0,sp,96
    8000480c:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000480e:	4619                	li	a2,6
    80004810:	00005597          	auipc	a1,0x5
    80004814:	0f058593          	addi	a1,a1,240 # 80009900 <syscalls+0x1e8>
    80004818:	fd040513          	addi	a0,s0,-48
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	4fe080e7          	jalr	1278(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004824:	fd640593          	addi	a1,s0,-42
    80004828:	5888                	lw	a0,48(s1)
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	f64080e7          	jalr	-156(ra) # 8000478e <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004832:	1684b503          	ld	a0,360(s1)
    80004836:	16050763          	beqz	a0,800049a4 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000483a:	00001097          	auipc	ra,0x1
    8000483e:	918080e7          	jalr	-1768(ra) # 80005152 <fileclose>

  begin_op();
    80004842:	00000097          	auipc	ra,0x0
    80004846:	444080e7          	jalr	1092(ra) # 80004c86 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000484a:	fb040593          	addi	a1,s0,-80
    8000484e:	fd040513          	addi	a0,s0,-48
    80004852:	00000097          	auipc	ra,0x0
    80004856:	f20080e7          	jalr	-224(ra) # 80004772 <nameiparent>
    8000485a:	892a                	mv	s2,a0
    8000485c:	cd69                	beqz	a0,80004936 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	740080e7          	jalr	1856(ra) # 80003f9e <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004866:	00005597          	auipc	a1,0x5
    8000486a:	0a258593          	addi	a1,a1,162 # 80009908 <syscalls+0x1f0>
    8000486e:	fb040513          	addi	a0,s0,-80
    80004872:	00000097          	auipc	ra,0x0
    80004876:	bf6080e7          	jalr	-1034(ra) # 80004468 <namecmp>
    8000487a:	c57d                	beqz	a0,80004968 <removeSwapFile+0x168>
    8000487c:	00005597          	auipc	a1,0x5
    80004880:	09458593          	addi	a1,a1,148 # 80009910 <syscalls+0x1f8>
    80004884:	fb040513          	addi	a0,s0,-80
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	be0080e7          	jalr	-1056(ra) # 80004468 <namecmp>
    80004890:	cd61                	beqz	a0,80004968 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80004892:	fac40613          	addi	a2,s0,-84
    80004896:	fb040593          	addi	a1,s0,-80
    8000489a:	854a                	mv	a0,s2
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	be6080e7          	jalr	-1050(ra) # 80004482 <dirlookup>
    800048a4:	84aa                	mv	s1,a0
    800048a6:	c169                	beqz	a0,80004968 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	6f6080e7          	jalr	1782(ra) # 80003f9e <ilock>

  if(ip->nlink < 1)
    800048b0:	04a49783          	lh	a5,74(s1)
    800048b4:	08f05763          	blez	a5,80004942 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800048b8:	04449703          	lh	a4,68(s1)
    800048bc:	4785                	li	a5,1
    800048be:	08f70a63          	beq	a4,a5,80004952 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800048c2:	4641                	li	a2,16
    800048c4:	4581                	li	a1,0
    800048c6:	fc040513          	addi	a0,s0,-64
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	3f4080e7          	jalr	1012(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048d2:	4741                	li	a4,16
    800048d4:	fac42683          	lw	a3,-84(s0)
    800048d8:	fc040613          	addi	a2,s0,-64
    800048dc:	4581                	li	a1,0
    800048de:	854a                	mv	a0,s2
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	a6a080e7          	jalr	-1430(ra) # 8000434a <writei>
    800048e8:	47c1                	li	a5,16
    800048ea:	08f51a63          	bne	a0,a5,8000497e <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800048ee:	04449703          	lh	a4,68(s1)
    800048f2:	4785                	li	a5,1
    800048f4:	08f70d63          	beq	a4,a5,8000498e <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800048f8:	854a                	mv	a0,s2
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	906080e7          	jalr	-1786(ra) # 80004200 <iunlockput>

  ip->nlink--;
    80004902:	04a4d783          	lhu	a5,74(s1)
    80004906:	37fd                	addiw	a5,a5,-1
    80004908:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000490c:	8526                	mv	a0,s1
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	5c6080e7          	jalr	1478(ra) # 80003ed4 <iupdate>
  iunlockput(ip);
    80004916:	8526                	mv	a0,s1
    80004918:	00000097          	auipc	ra,0x0
    8000491c:	8e8080e7          	jalr	-1816(ra) # 80004200 <iunlockput>

  end_op();
    80004920:	00000097          	auipc	ra,0x0
    80004924:	3e6080e7          	jalr	998(ra) # 80004d06 <end_op>

  return 0;
    80004928:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    8000492a:	60e6                	ld	ra,88(sp)
    8000492c:	6446                	ld	s0,80(sp)
    8000492e:	64a6                	ld	s1,72(sp)
    80004930:	6906                	ld	s2,64(sp)
    80004932:	6125                	addi	sp,sp,96
    80004934:	8082                	ret
    end_op();
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	3d0080e7          	jalr	976(ra) # 80004d06 <end_op>
    return -1;
    8000493e:	557d                	li	a0,-1
    80004940:	b7ed                	j	8000492a <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004942:	00005517          	auipc	a0,0x5
    80004946:	fd650513          	addi	a0,a0,-42 # 80009918 <syscalls+0x200>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	be0080e7          	jalr	-1056(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004952:	8526                	mv	a0,s1
    80004954:	00002097          	auipc	ra,0x2
    80004958:	866080e7          	jalr	-1946(ra) # 800061ba <isdirempty>
    8000495c:	f13d                	bnez	a0,800048c2 <removeSwapFile+0xc2>
    iunlockput(ip);
    8000495e:	8526                	mv	a0,s1
    80004960:	00000097          	auipc	ra,0x0
    80004964:	8a0080e7          	jalr	-1888(ra) # 80004200 <iunlockput>
    iunlockput(dp);
    80004968:	854a                	mv	a0,s2
    8000496a:	00000097          	auipc	ra,0x0
    8000496e:	896080e7          	jalr	-1898(ra) # 80004200 <iunlockput>
    end_op();
    80004972:	00000097          	auipc	ra,0x0
    80004976:	394080e7          	jalr	916(ra) # 80004d06 <end_op>
    return -1;
    8000497a:	557d                	li	a0,-1
    8000497c:	b77d                	j	8000492a <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000497e:	00005517          	auipc	a0,0x5
    80004982:	fb250513          	addi	a0,a0,-78 # 80009930 <syscalls+0x218>
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	ba4080e7          	jalr	-1116(ra) # 8000052a <panic>
    dp->nlink--;
    8000498e:	04a95783          	lhu	a5,74(s2)
    80004992:	37fd                	addiw	a5,a5,-1
    80004994:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004998:	854a                	mv	a0,s2
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	53a080e7          	jalr	1338(ra) # 80003ed4 <iupdate>
    800049a2:	bf99                	j	800048f8 <removeSwapFile+0xf8>
    return -1;
    800049a4:	557d                	li	a0,-1
    800049a6:	b751                	j	8000492a <removeSwapFile+0x12a>

00000000800049a8 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800049a8:	7179                	addi	sp,sp,-48
    800049aa:	f406                	sd	ra,40(sp)
    800049ac:	f022                	sd	s0,32(sp)
    800049ae:	ec26                	sd	s1,24(sp)
    800049b0:	e84a                	sd	s2,16(sp)
    800049b2:	1800                	addi	s0,sp,48
    800049b4:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800049b6:	4619                	li	a2,6
    800049b8:	00005597          	auipc	a1,0x5
    800049bc:	f4858593          	addi	a1,a1,-184 # 80009900 <syscalls+0x1e8>
    800049c0:	fd040513          	addi	a0,s0,-48
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	356080e7          	jalr	854(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800049cc:	fd640593          	addi	a1,s0,-42
    800049d0:	5888                	lw	a0,48(s1)
    800049d2:	00000097          	auipc	ra,0x0
    800049d6:	dbc080e7          	jalr	-580(ra) # 8000478e <itoa>

  begin_op();
    800049da:	00000097          	auipc	ra,0x0
    800049de:	2ac080e7          	jalr	684(ra) # 80004c86 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    800049e2:	4681                	li	a3,0
    800049e4:	4601                	li	a2,0
    800049e6:	4589                	li	a1,2
    800049e8:	fd040513          	addi	a0,s0,-48
    800049ec:	00002097          	auipc	ra,0x2
    800049f0:	9c2080e7          	jalr	-1598(ra) # 800063ae <create>
    800049f4:	892a                	mv	s2,a0
  iunlock(in);
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	66a080e7          	jalr	1642(ra) # 80004060 <iunlock>
  p->swapFile = filealloc();
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	698080e7          	jalr	1688(ra) # 80005096 <filealloc>
    80004a06:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004a0a:	cd1d                	beqz	a0,80004a48 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    80004a0c:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004a10:	1684b703          	ld	a4,360(s1)
    80004a14:	4789                	li	a5,2
    80004a16:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004a18:	1684b703          	ld	a4,360(s1)
    80004a1c:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004a20:	1684b703          	ld	a4,360(s1)
    80004a24:	4685                	li	a3,1
    80004a26:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004a2a:	1684b703          	ld	a4,360(s1)
    80004a2e:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004a32:	00000097          	auipc	ra,0x0
    80004a36:	2d4080e7          	jalr	724(ra) # 80004d06 <end_op>

    return 0;
}
    80004a3a:	4501                	li	a0,0
    80004a3c:	70a2                	ld	ra,40(sp)
    80004a3e:	7402                	ld	s0,32(sp)
    80004a40:	64e2                	ld	s1,24(sp)
    80004a42:	6942                	ld	s2,16(sp)
    80004a44:	6145                	addi	sp,sp,48
    80004a46:	8082                	ret
    panic("no slot for files on /store");
    80004a48:	00005517          	auipc	a0,0x5
    80004a4c:	ef850513          	addi	a0,a0,-264 # 80009940 <syscalls+0x228>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	ada080e7          	jalr	-1318(ra) # 8000052a <panic>

0000000080004a58 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a58:	1141                	addi	sp,sp,-16
    80004a5a:	e406                	sd	ra,8(sp)
    80004a5c:	e022                	sd	s0,0(sp)
    80004a5e:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a60:	16853783          	ld	a5,360(a0)
    80004a64:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004a66:	8636                	mv	a2,a3
    80004a68:	16853503          	ld	a0,360(a0)
    80004a6c:	00001097          	auipc	ra,0x1
    80004a70:	ad8080e7          	jalr	-1320(ra) # 80005544 <kfilewrite>
}
    80004a74:	60a2                	ld	ra,8(sp)
    80004a76:	6402                	ld	s0,0(sp)
    80004a78:	0141                	addi	sp,sp,16
    80004a7a:	8082                	ret

0000000080004a7c <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a7c:	1141                	addi	sp,sp,-16
    80004a7e:	e406                	sd	ra,8(sp)
    80004a80:	e022                	sd	s0,0(sp)
    80004a82:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a84:	16853783          	ld	a5,360(a0)
    80004a88:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004a8a:	8636                	mv	a2,a3
    80004a8c:	16853503          	ld	a0,360(a0)
    80004a90:	00001097          	auipc	ra,0x1
    80004a94:	9f2080e7          	jalr	-1550(ra) # 80005482 <kfileread>
    80004a98:	60a2                	ld	ra,8(sp)
    80004a9a:	6402                	ld	s0,0(sp)
    80004a9c:	0141                	addi	sp,sp,16
    80004a9e:	8082                	ret

0000000080004aa0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004aa0:	1101                	addi	sp,sp,-32
    80004aa2:	ec06                	sd	ra,24(sp)
    80004aa4:	e822                	sd	s0,16(sp)
    80004aa6:	e426                	sd	s1,8(sp)
    80004aa8:	e04a                	sd	s2,0(sp)
    80004aaa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004aac:	00026917          	auipc	s2,0x26
    80004ab0:	bc490913          	addi	s2,s2,-1084 # 8002a670 <log>
    80004ab4:	01892583          	lw	a1,24(s2)
    80004ab8:	02892503          	lw	a0,40(s2)
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	cde080e7          	jalr	-802(ra) # 8000379a <bread>
    80004ac4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004ac6:	02c92683          	lw	a3,44(s2)
    80004aca:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004acc:	02d05863          	blez	a3,80004afc <write_head+0x5c>
    80004ad0:	00026797          	auipc	a5,0x26
    80004ad4:	bd078793          	addi	a5,a5,-1072 # 8002a6a0 <log+0x30>
    80004ad8:	05c50713          	addi	a4,a0,92
    80004adc:	36fd                	addiw	a3,a3,-1
    80004ade:	02069613          	slli	a2,a3,0x20
    80004ae2:	01e65693          	srli	a3,a2,0x1e
    80004ae6:	00026617          	auipc	a2,0x26
    80004aea:	bbe60613          	addi	a2,a2,-1090 # 8002a6a4 <log+0x34>
    80004aee:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004af0:	4390                	lw	a2,0(a5)
    80004af2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004af4:	0791                	addi	a5,a5,4
    80004af6:	0711                	addi	a4,a4,4
    80004af8:	fed79ce3          	bne	a5,a3,80004af0 <write_head+0x50>
  }
  bwrite(buf);
    80004afc:	8526                	mv	a0,s1
    80004afe:	fffff097          	auipc	ra,0xfffff
    80004b02:	d8e080e7          	jalr	-626(ra) # 8000388c <bwrite>
  brelse(buf);
    80004b06:	8526                	mv	a0,s1
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	dc2080e7          	jalr	-574(ra) # 800038ca <brelse>
}
    80004b10:	60e2                	ld	ra,24(sp)
    80004b12:	6442                	ld	s0,16(sp)
    80004b14:	64a2                	ld	s1,8(sp)
    80004b16:	6902                	ld	s2,0(sp)
    80004b18:	6105                	addi	sp,sp,32
    80004b1a:	8082                	ret

0000000080004b1c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b1c:	00026797          	auipc	a5,0x26
    80004b20:	b807a783          	lw	a5,-1152(a5) # 8002a69c <log+0x2c>
    80004b24:	0af05d63          	blez	a5,80004bde <install_trans+0xc2>
{
    80004b28:	7139                	addi	sp,sp,-64
    80004b2a:	fc06                	sd	ra,56(sp)
    80004b2c:	f822                	sd	s0,48(sp)
    80004b2e:	f426                	sd	s1,40(sp)
    80004b30:	f04a                	sd	s2,32(sp)
    80004b32:	ec4e                	sd	s3,24(sp)
    80004b34:	e852                	sd	s4,16(sp)
    80004b36:	e456                	sd	s5,8(sp)
    80004b38:	e05a                	sd	s6,0(sp)
    80004b3a:	0080                	addi	s0,sp,64
    80004b3c:	8b2a                	mv	s6,a0
    80004b3e:	00026a97          	auipc	s5,0x26
    80004b42:	b62a8a93          	addi	s5,s5,-1182 # 8002a6a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b46:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b48:	00026997          	auipc	s3,0x26
    80004b4c:	b2898993          	addi	s3,s3,-1240 # 8002a670 <log>
    80004b50:	a00d                	j	80004b72 <install_trans+0x56>
    brelse(lbuf);
    80004b52:	854a                	mv	a0,s2
    80004b54:	fffff097          	auipc	ra,0xfffff
    80004b58:	d76080e7          	jalr	-650(ra) # 800038ca <brelse>
    brelse(dbuf);
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	fffff097          	auipc	ra,0xfffff
    80004b62:	d6c080e7          	jalr	-660(ra) # 800038ca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b66:	2a05                	addiw	s4,s4,1
    80004b68:	0a91                	addi	s5,s5,4
    80004b6a:	02c9a783          	lw	a5,44(s3)
    80004b6e:	04fa5e63          	bge	s4,a5,80004bca <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b72:	0189a583          	lw	a1,24(s3)
    80004b76:	014585bb          	addw	a1,a1,s4
    80004b7a:	2585                	addiw	a1,a1,1
    80004b7c:	0289a503          	lw	a0,40(s3)
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	c1a080e7          	jalr	-998(ra) # 8000379a <bread>
    80004b88:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b8a:	000aa583          	lw	a1,0(s5)
    80004b8e:	0289a503          	lw	a0,40(s3)
    80004b92:	fffff097          	auipc	ra,0xfffff
    80004b96:	c08080e7          	jalr	-1016(ra) # 8000379a <bread>
    80004b9a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b9c:	40000613          	li	a2,1024
    80004ba0:	05890593          	addi	a1,s2,88
    80004ba4:	05850513          	addi	a0,a0,88
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	172080e7          	jalr	370(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	fffff097          	auipc	ra,0xfffff
    80004bb6:	cda080e7          	jalr	-806(ra) # 8000388c <bwrite>
    if(recovering == 0)
    80004bba:	f80b1ce3          	bnez	s6,80004b52 <install_trans+0x36>
      bunpin(dbuf);
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	fffff097          	auipc	ra,0xfffff
    80004bc4:	de4080e7          	jalr	-540(ra) # 800039a4 <bunpin>
    80004bc8:	b769                	j	80004b52 <install_trans+0x36>
}
    80004bca:	70e2                	ld	ra,56(sp)
    80004bcc:	7442                	ld	s0,48(sp)
    80004bce:	74a2                	ld	s1,40(sp)
    80004bd0:	7902                	ld	s2,32(sp)
    80004bd2:	69e2                	ld	s3,24(sp)
    80004bd4:	6a42                	ld	s4,16(sp)
    80004bd6:	6aa2                	ld	s5,8(sp)
    80004bd8:	6b02                	ld	s6,0(sp)
    80004bda:	6121                	addi	sp,sp,64
    80004bdc:	8082                	ret
    80004bde:	8082                	ret

0000000080004be0 <initlog>:
{
    80004be0:	7179                	addi	sp,sp,-48
    80004be2:	f406                	sd	ra,40(sp)
    80004be4:	f022                	sd	s0,32(sp)
    80004be6:	ec26                	sd	s1,24(sp)
    80004be8:	e84a                	sd	s2,16(sp)
    80004bea:	e44e                	sd	s3,8(sp)
    80004bec:	1800                	addi	s0,sp,48
    80004bee:	892a                	mv	s2,a0
    80004bf0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004bf2:	00026497          	auipc	s1,0x26
    80004bf6:	a7e48493          	addi	s1,s1,-1410 # 8002a670 <log>
    80004bfa:	00005597          	auipc	a1,0x5
    80004bfe:	d6658593          	addi	a1,a1,-666 # 80009960 <syscalls+0x248>
    80004c02:	8526                	mv	a0,s1
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	f2e080e7          	jalr	-210(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004c0c:	0149a583          	lw	a1,20(s3)
    80004c10:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c12:	0109a783          	lw	a5,16(s3)
    80004c16:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c18:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c1c:	854a                	mv	a0,s2
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	b7c080e7          	jalr	-1156(ra) # 8000379a <bread>
  log.lh.n = lh->n;
    80004c26:	4d34                	lw	a3,88(a0)
    80004c28:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c2a:	02d05663          	blez	a3,80004c56 <initlog+0x76>
    80004c2e:	05c50793          	addi	a5,a0,92
    80004c32:	00026717          	auipc	a4,0x26
    80004c36:	a6e70713          	addi	a4,a4,-1426 # 8002a6a0 <log+0x30>
    80004c3a:	36fd                	addiw	a3,a3,-1
    80004c3c:	02069613          	slli	a2,a3,0x20
    80004c40:	01e65693          	srli	a3,a2,0x1e
    80004c44:	06050613          	addi	a2,a0,96
    80004c48:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004c4a:	4390                	lw	a2,0(a5)
    80004c4c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004c4e:	0791                	addi	a5,a5,4
    80004c50:	0711                	addi	a4,a4,4
    80004c52:	fed79ce3          	bne	a5,a3,80004c4a <initlog+0x6a>
  brelse(buf);
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	c74080e7          	jalr	-908(ra) # 800038ca <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c5e:	4505                	li	a0,1
    80004c60:	00000097          	auipc	ra,0x0
    80004c64:	ebc080e7          	jalr	-324(ra) # 80004b1c <install_trans>
  log.lh.n = 0;
    80004c68:	00026797          	auipc	a5,0x26
    80004c6c:	a207aa23          	sw	zero,-1484(a5) # 8002a69c <log+0x2c>
  write_head(); // clear the log
    80004c70:	00000097          	auipc	ra,0x0
    80004c74:	e30080e7          	jalr	-464(ra) # 80004aa0 <write_head>
}
    80004c78:	70a2                	ld	ra,40(sp)
    80004c7a:	7402                	ld	s0,32(sp)
    80004c7c:	64e2                	ld	s1,24(sp)
    80004c7e:	6942                	ld	s2,16(sp)
    80004c80:	69a2                	ld	s3,8(sp)
    80004c82:	6145                	addi	sp,sp,48
    80004c84:	8082                	ret

0000000080004c86 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c86:	1101                	addi	sp,sp,-32
    80004c88:	ec06                	sd	ra,24(sp)
    80004c8a:	e822                	sd	s0,16(sp)
    80004c8c:	e426                	sd	s1,8(sp)
    80004c8e:	e04a                	sd	s2,0(sp)
    80004c90:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c92:	00026517          	auipc	a0,0x26
    80004c96:	9de50513          	addi	a0,a0,-1570 # 8002a670 <log>
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	f28080e7          	jalr	-216(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004ca2:	00026497          	auipc	s1,0x26
    80004ca6:	9ce48493          	addi	s1,s1,-1586 # 8002a670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004caa:	4979                	li	s2,30
    80004cac:	a039                	j	80004cba <begin_op+0x34>
      sleep(&log, &log.lock);
    80004cae:	85a6                	mv	a1,s1
    80004cb0:	8526                	mv	a0,s1
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	344080e7          	jalr	836(ra) # 80001ff6 <sleep>
    if(log.committing){
    80004cba:	50dc                	lw	a5,36(s1)
    80004cbc:	fbed                	bnez	a5,80004cae <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cbe:	509c                	lw	a5,32(s1)
    80004cc0:	0017871b          	addiw	a4,a5,1
    80004cc4:	0007069b          	sext.w	a3,a4
    80004cc8:	0027179b          	slliw	a5,a4,0x2
    80004ccc:	9fb9                	addw	a5,a5,a4
    80004cce:	0017979b          	slliw	a5,a5,0x1
    80004cd2:	54d8                	lw	a4,44(s1)
    80004cd4:	9fb9                	addw	a5,a5,a4
    80004cd6:	00f95963          	bge	s2,a5,80004ce8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004cda:	85a6                	mv	a1,s1
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	318080e7          	jalr	792(ra) # 80001ff6 <sleep>
    80004ce6:	bfd1                	j	80004cba <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004ce8:	00026517          	auipc	a0,0x26
    80004cec:	98850513          	addi	a0,a0,-1656 # 8002a670 <log>
    80004cf0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	f84080e7          	jalr	-124(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004cfa:	60e2                	ld	ra,24(sp)
    80004cfc:	6442                	ld	s0,16(sp)
    80004cfe:	64a2                	ld	s1,8(sp)
    80004d00:	6902                	ld	s2,0(sp)
    80004d02:	6105                	addi	sp,sp,32
    80004d04:	8082                	ret

0000000080004d06 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d06:	7139                	addi	sp,sp,-64
    80004d08:	fc06                	sd	ra,56(sp)
    80004d0a:	f822                	sd	s0,48(sp)
    80004d0c:	f426                	sd	s1,40(sp)
    80004d0e:	f04a                	sd	s2,32(sp)
    80004d10:	ec4e                	sd	s3,24(sp)
    80004d12:	e852                	sd	s4,16(sp)
    80004d14:	e456                	sd	s5,8(sp)
    80004d16:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d18:	00026497          	auipc	s1,0x26
    80004d1c:	95848493          	addi	s1,s1,-1704 # 8002a670 <log>
    80004d20:	8526                	mv	a0,s1
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	ea0080e7          	jalr	-352(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004d2a:	509c                	lw	a5,32(s1)
    80004d2c:	37fd                	addiw	a5,a5,-1
    80004d2e:	0007891b          	sext.w	s2,a5
    80004d32:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d34:	50dc                	lw	a5,36(s1)
    80004d36:	e7b9                	bnez	a5,80004d84 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d38:	04091e63          	bnez	s2,80004d94 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004d3c:	00026497          	auipc	s1,0x26
    80004d40:	93448493          	addi	s1,s1,-1740 # 8002a670 <log>
    80004d44:	4785                	li	a5,1
    80004d46:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d48:	8526                	mv	a0,s1
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	f2c080e7          	jalr	-212(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d52:	54dc                	lw	a5,44(s1)
    80004d54:	06f04763          	bgtz	a5,80004dc2 <end_op+0xbc>
    acquire(&log.lock);
    80004d58:	00026497          	auipc	s1,0x26
    80004d5c:	91848493          	addi	s1,s1,-1768 # 8002a670 <log>
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	e60080e7          	jalr	-416(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004d6a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d6e:	8526                	mv	a0,s1
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	2ea080e7          	jalr	746(ra) # 8000205a <wakeup>
    release(&log.lock);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	efc080e7          	jalr	-260(ra) # 80000c76 <release>
}
    80004d82:	a03d                	j	80004db0 <end_op+0xaa>
    panic("log.committing");
    80004d84:	00005517          	auipc	a0,0x5
    80004d88:	be450513          	addi	a0,a0,-1052 # 80009968 <syscalls+0x250>
    80004d8c:	ffffb097          	auipc	ra,0xffffb
    80004d90:	79e080e7          	jalr	1950(ra) # 8000052a <panic>
    wakeup(&log);
    80004d94:	00026497          	auipc	s1,0x26
    80004d98:	8dc48493          	addi	s1,s1,-1828 # 8002a670 <log>
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	2bc080e7          	jalr	700(ra) # 8000205a <wakeup>
  release(&log.lock);
    80004da6:	8526                	mv	a0,s1
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	ece080e7          	jalr	-306(ra) # 80000c76 <release>
}
    80004db0:	70e2                	ld	ra,56(sp)
    80004db2:	7442                	ld	s0,48(sp)
    80004db4:	74a2                	ld	s1,40(sp)
    80004db6:	7902                	ld	s2,32(sp)
    80004db8:	69e2                	ld	s3,24(sp)
    80004dba:	6a42                	ld	s4,16(sp)
    80004dbc:	6aa2                	ld	s5,8(sp)
    80004dbe:	6121                	addi	sp,sp,64
    80004dc0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dc2:	00026a97          	auipc	s5,0x26
    80004dc6:	8dea8a93          	addi	s5,s5,-1826 # 8002a6a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dca:	00026a17          	auipc	s4,0x26
    80004dce:	8a6a0a13          	addi	s4,s4,-1882 # 8002a670 <log>
    80004dd2:	018a2583          	lw	a1,24(s4)
    80004dd6:	012585bb          	addw	a1,a1,s2
    80004dda:	2585                	addiw	a1,a1,1
    80004ddc:	028a2503          	lw	a0,40(s4)
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	9ba080e7          	jalr	-1606(ra) # 8000379a <bread>
    80004de8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004dea:	000aa583          	lw	a1,0(s5)
    80004dee:	028a2503          	lw	a0,40(s4)
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	9a8080e7          	jalr	-1624(ra) # 8000379a <bread>
    80004dfa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004dfc:	40000613          	li	a2,1024
    80004e00:	05850593          	addi	a1,a0,88
    80004e04:	05848513          	addi	a0,s1,88
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	f12080e7          	jalr	-238(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004e10:	8526                	mv	a0,s1
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	a7a080e7          	jalr	-1414(ra) # 8000388c <bwrite>
    brelse(from);
    80004e1a:	854e                	mv	a0,s3
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	aae080e7          	jalr	-1362(ra) # 800038ca <brelse>
    brelse(to);
    80004e24:	8526                	mv	a0,s1
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	aa4080e7          	jalr	-1372(ra) # 800038ca <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e2e:	2905                	addiw	s2,s2,1
    80004e30:	0a91                	addi	s5,s5,4
    80004e32:	02ca2783          	lw	a5,44(s4)
    80004e36:	f8f94ee3          	blt	s2,a5,80004dd2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e3a:	00000097          	auipc	ra,0x0
    80004e3e:	c66080e7          	jalr	-922(ra) # 80004aa0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e42:	4501                	li	a0,0
    80004e44:	00000097          	auipc	ra,0x0
    80004e48:	cd8080e7          	jalr	-808(ra) # 80004b1c <install_trans>
    log.lh.n = 0;
    80004e4c:	00026797          	auipc	a5,0x26
    80004e50:	8407a823          	sw	zero,-1968(a5) # 8002a69c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e54:	00000097          	auipc	ra,0x0
    80004e58:	c4c080e7          	jalr	-948(ra) # 80004aa0 <write_head>
    80004e5c:	bdf5                	j	80004d58 <end_op+0x52>

0000000080004e5e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e5e:	1101                	addi	sp,sp,-32
    80004e60:	ec06                	sd	ra,24(sp)
    80004e62:	e822                	sd	s0,16(sp)
    80004e64:	e426                	sd	s1,8(sp)
    80004e66:	e04a                	sd	s2,0(sp)
    80004e68:	1000                	addi	s0,sp,32
    80004e6a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e6c:	00026917          	auipc	s2,0x26
    80004e70:	80490913          	addi	s2,s2,-2044 # 8002a670 <log>
    80004e74:	854a                	mv	a0,s2
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	d4c080e7          	jalr	-692(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e7e:	02c92603          	lw	a2,44(s2)
    80004e82:	47f5                	li	a5,29
    80004e84:	06c7c563          	blt	a5,a2,80004eee <log_write+0x90>
    80004e88:	00026797          	auipc	a5,0x26
    80004e8c:	8047a783          	lw	a5,-2044(a5) # 8002a68c <log+0x1c>
    80004e90:	37fd                	addiw	a5,a5,-1
    80004e92:	04f65e63          	bge	a2,a5,80004eee <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e96:	00025797          	auipc	a5,0x25
    80004e9a:	7fa7a783          	lw	a5,2042(a5) # 8002a690 <log+0x20>
    80004e9e:	06f05063          	blez	a5,80004efe <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ea2:	4781                	li	a5,0
    80004ea4:	06c05563          	blez	a2,80004f0e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004ea8:	44cc                	lw	a1,12(s1)
    80004eaa:	00025717          	auipc	a4,0x25
    80004eae:	7f670713          	addi	a4,a4,2038 # 8002a6a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004eb2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004eb4:	4314                	lw	a3,0(a4)
    80004eb6:	04b68c63          	beq	a3,a1,80004f0e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004eba:	2785                	addiw	a5,a5,1
    80004ebc:	0711                	addi	a4,a4,4
    80004ebe:	fef61be3          	bne	a2,a5,80004eb4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ec2:	0621                	addi	a2,a2,8
    80004ec4:	060a                	slli	a2,a2,0x2
    80004ec6:	00025797          	auipc	a5,0x25
    80004eca:	7aa78793          	addi	a5,a5,1962 # 8002a670 <log>
    80004ece:	963e                	add	a2,a2,a5
    80004ed0:	44dc                	lw	a5,12(s1)
    80004ed2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	a92080e7          	jalr	-1390(ra) # 80003968 <bpin>
    log.lh.n++;
    80004ede:	00025717          	auipc	a4,0x25
    80004ee2:	79270713          	addi	a4,a4,1938 # 8002a670 <log>
    80004ee6:	575c                	lw	a5,44(a4)
    80004ee8:	2785                	addiw	a5,a5,1
    80004eea:	d75c                	sw	a5,44(a4)
    80004eec:	a835                	j	80004f28 <log_write+0xca>
    panic("too big a transaction");
    80004eee:	00005517          	auipc	a0,0x5
    80004ef2:	a8a50513          	addi	a0,a0,-1398 # 80009978 <syscalls+0x260>
    80004ef6:	ffffb097          	auipc	ra,0xffffb
    80004efa:	634080e7          	jalr	1588(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004efe:	00005517          	auipc	a0,0x5
    80004f02:	a9250513          	addi	a0,a0,-1390 # 80009990 <syscalls+0x278>
    80004f06:	ffffb097          	auipc	ra,0xffffb
    80004f0a:	624080e7          	jalr	1572(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004f0e:	00878713          	addi	a4,a5,8
    80004f12:	00271693          	slli	a3,a4,0x2
    80004f16:	00025717          	auipc	a4,0x25
    80004f1a:	75a70713          	addi	a4,a4,1882 # 8002a670 <log>
    80004f1e:	9736                	add	a4,a4,a3
    80004f20:	44d4                	lw	a3,12(s1)
    80004f22:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f24:	faf608e3          	beq	a2,a5,80004ed4 <log_write+0x76>
  }
  release(&log.lock);
    80004f28:	00025517          	auipc	a0,0x25
    80004f2c:	74850513          	addi	a0,a0,1864 # 8002a670 <log>
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	d46080e7          	jalr	-698(ra) # 80000c76 <release>
}
    80004f38:	60e2                	ld	ra,24(sp)
    80004f3a:	6442                	ld	s0,16(sp)
    80004f3c:	64a2                	ld	s1,8(sp)
    80004f3e:	6902                	ld	s2,0(sp)
    80004f40:	6105                	addi	sp,sp,32
    80004f42:	8082                	ret

0000000080004f44 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f44:	1101                	addi	sp,sp,-32
    80004f46:	ec06                	sd	ra,24(sp)
    80004f48:	e822                	sd	s0,16(sp)
    80004f4a:	e426                	sd	s1,8(sp)
    80004f4c:	e04a                	sd	s2,0(sp)
    80004f4e:	1000                	addi	s0,sp,32
    80004f50:	84aa                	mv	s1,a0
    80004f52:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f54:	00005597          	auipc	a1,0x5
    80004f58:	a5c58593          	addi	a1,a1,-1444 # 800099b0 <syscalls+0x298>
    80004f5c:	0521                	addi	a0,a0,8
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	bd4080e7          	jalr	-1068(ra) # 80000b32 <initlock>
  lk->name = name;
    80004f66:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f6a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f6e:	0204a423          	sw	zero,40(s1)
}
    80004f72:	60e2                	ld	ra,24(sp)
    80004f74:	6442                	ld	s0,16(sp)
    80004f76:	64a2                	ld	s1,8(sp)
    80004f78:	6902                	ld	s2,0(sp)
    80004f7a:	6105                	addi	sp,sp,32
    80004f7c:	8082                	ret

0000000080004f7e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f7e:	1101                	addi	sp,sp,-32
    80004f80:	ec06                	sd	ra,24(sp)
    80004f82:	e822                	sd	s0,16(sp)
    80004f84:	e426                	sd	s1,8(sp)
    80004f86:	e04a                	sd	s2,0(sp)
    80004f88:	1000                	addi	s0,sp,32
    80004f8a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f8c:	00850913          	addi	s2,a0,8
    80004f90:	854a                	mv	a0,s2
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	c30080e7          	jalr	-976(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004f9a:	409c                	lw	a5,0(s1)
    80004f9c:	cb89                	beqz	a5,80004fae <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f9e:	85ca                	mv	a1,s2
    80004fa0:	8526                	mv	a0,s1
    80004fa2:	ffffd097          	auipc	ra,0xffffd
    80004fa6:	054080e7          	jalr	84(ra) # 80001ff6 <sleep>
  while (lk->locked) {
    80004faa:	409c                	lw	a5,0(s1)
    80004fac:	fbed                	bnez	a5,80004f9e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fae:	4785                	li	a5,1
    80004fb0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	a22080e7          	jalr	-1502(ra) # 800019d4 <myproc>
    80004fba:	591c                	lw	a5,48(a0)
    80004fbc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fbe:	854a                	mv	a0,s2
    80004fc0:	ffffc097          	auipc	ra,0xffffc
    80004fc4:	cb6080e7          	jalr	-842(ra) # 80000c76 <release>
}
    80004fc8:	60e2                	ld	ra,24(sp)
    80004fca:	6442                	ld	s0,16(sp)
    80004fcc:	64a2                	ld	s1,8(sp)
    80004fce:	6902                	ld	s2,0(sp)
    80004fd0:	6105                	addi	sp,sp,32
    80004fd2:	8082                	ret

0000000080004fd4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004fd4:	1101                	addi	sp,sp,-32
    80004fd6:	ec06                	sd	ra,24(sp)
    80004fd8:	e822                	sd	s0,16(sp)
    80004fda:	e426                	sd	s1,8(sp)
    80004fdc:	e04a                	sd	s2,0(sp)
    80004fde:	1000                	addi	s0,sp,32
    80004fe0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fe2:	00850913          	addi	s2,a0,8
    80004fe6:	854a                	mv	a0,s2
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	bda080e7          	jalr	-1062(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004ff0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ff4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	ffffd097          	auipc	ra,0xffffd
    80004ffe:	060080e7          	jalr	96(ra) # 8000205a <wakeup>
  release(&lk->lk);
    80005002:	854a                	mv	a0,s2
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	c72080e7          	jalr	-910(ra) # 80000c76 <release>
}
    8000500c:	60e2                	ld	ra,24(sp)
    8000500e:	6442                	ld	s0,16(sp)
    80005010:	64a2                	ld	s1,8(sp)
    80005012:	6902                	ld	s2,0(sp)
    80005014:	6105                	addi	sp,sp,32
    80005016:	8082                	ret

0000000080005018 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005018:	7179                	addi	sp,sp,-48
    8000501a:	f406                	sd	ra,40(sp)
    8000501c:	f022                	sd	s0,32(sp)
    8000501e:	ec26                	sd	s1,24(sp)
    80005020:	e84a                	sd	s2,16(sp)
    80005022:	e44e                	sd	s3,8(sp)
    80005024:	1800                	addi	s0,sp,48
    80005026:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005028:	00850913          	addi	s2,a0,8
    8000502c:	854a                	mv	a0,s2
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	b94080e7          	jalr	-1132(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005036:	409c                	lw	a5,0(s1)
    80005038:	ef99                	bnez	a5,80005056 <holdingsleep+0x3e>
    8000503a:	4481                	li	s1,0
  release(&lk->lk);
    8000503c:	854a                	mv	a0,s2
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	c38080e7          	jalr	-968(ra) # 80000c76 <release>
  return r;
}
    80005046:	8526                	mv	a0,s1
    80005048:	70a2                	ld	ra,40(sp)
    8000504a:	7402                	ld	s0,32(sp)
    8000504c:	64e2                	ld	s1,24(sp)
    8000504e:	6942                	ld	s2,16(sp)
    80005050:	69a2                	ld	s3,8(sp)
    80005052:	6145                	addi	sp,sp,48
    80005054:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005056:	0284a983          	lw	s3,40(s1)
    8000505a:	ffffd097          	auipc	ra,0xffffd
    8000505e:	97a080e7          	jalr	-1670(ra) # 800019d4 <myproc>
    80005062:	5904                	lw	s1,48(a0)
    80005064:	413484b3          	sub	s1,s1,s3
    80005068:	0014b493          	seqz	s1,s1
    8000506c:	bfc1                	j	8000503c <holdingsleep+0x24>

000000008000506e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000506e:	1141                	addi	sp,sp,-16
    80005070:	e406                	sd	ra,8(sp)
    80005072:	e022                	sd	s0,0(sp)
    80005074:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005076:	00005597          	auipc	a1,0x5
    8000507a:	94a58593          	addi	a1,a1,-1718 # 800099c0 <syscalls+0x2a8>
    8000507e:	00025517          	auipc	a0,0x25
    80005082:	73a50513          	addi	a0,a0,1850 # 8002a7b8 <ftable>
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	aac080e7          	jalr	-1364(ra) # 80000b32 <initlock>
}
    8000508e:	60a2                	ld	ra,8(sp)
    80005090:	6402                	ld	s0,0(sp)
    80005092:	0141                	addi	sp,sp,16
    80005094:	8082                	ret

0000000080005096 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005096:	1101                	addi	sp,sp,-32
    80005098:	ec06                	sd	ra,24(sp)
    8000509a:	e822                	sd	s0,16(sp)
    8000509c:	e426                	sd	s1,8(sp)
    8000509e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800050a0:	00025517          	auipc	a0,0x25
    800050a4:	71850513          	addi	a0,a0,1816 # 8002a7b8 <ftable>
    800050a8:	ffffc097          	auipc	ra,0xffffc
    800050ac:	b1a080e7          	jalr	-1254(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050b0:	00025497          	auipc	s1,0x25
    800050b4:	72048493          	addi	s1,s1,1824 # 8002a7d0 <ftable+0x18>
    800050b8:	00026717          	auipc	a4,0x26
    800050bc:	6b870713          	addi	a4,a4,1720 # 8002b770 <ftable+0xfb8>
    if(f->ref == 0){
    800050c0:	40dc                	lw	a5,4(s1)
    800050c2:	cf99                	beqz	a5,800050e0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050c4:	02848493          	addi	s1,s1,40
    800050c8:	fee49ce3          	bne	s1,a4,800050c0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050cc:	00025517          	auipc	a0,0x25
    800050d0:	6ec50513          	addi	a0,a0,1772 # 8002a7b8 <ftable>
    800050d4:	ffffc097          	auipc	ra,0xffffc
    800050d8:	ba2080e7          	jalr	-1118(ra) # 80000c76 <release>
  return 0;
    800050dc:	4481                	li	s1,0
    800050de:	a819                	j	800050f4 <filealloc+0x5e>
      f->ref = 1;
    800050e0:	4785                	li	a5,1
    800050e2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050e4:	00025517          	auipc	a0,0x25
    800050e8:	6d450513          	addi	a0,a0,1748 # 8002a7b8 <ftable>
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	b8a080e7          	jalr	-1142(ra) # 80000c76 <release>
}
    800050f4:	8526                	mv	a0,s1
    800050f6:	60e2                	ld	ra,24(sp)
    800050f8:	6442                	ld	s0,16(sp)
    800050fa:	64a2                	ld	s1,8(sp)
    800050fc:	6105                	addi	sp,sp,32
    800050fe:	8082                	ret

0000000080005100 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005100:	1101                	addi	sp,sp,-32
    80005102:	ec06                	sd	ra,24(sp)
    80005104:	e822                	sd	s0,16(sp)
    80005106:	e426                	sd	s1,8(sp)
    80005108:	1000                	addi	s0,sp,32
    8000510a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000510c:	00025517          	auipc	a0,0x25
    80005110:	6ac50513          	addi	a0,a0,1708 # 8002a7b8 <ftable>
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	aae080e7          	jalr	-1362(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000511c:	40dc                	lw	a5,4(s1)
    8000511e:	02f05263          	blez	a5,80005142 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005122:	2785                	addiw	a5,a5,1
    80005124:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005126:	00025517          	auipc	a0,0x25
    8000512a:	69250513          	addi	a0,a0,1682 # 8002a7b8 <ftable>
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	b48080e7          	jalr	-1208(ra) # 80000c76 <release>
  return f;
}
    80005136:	8526                	mv	a0,s1
    80005138:	60e2                	ld	ra,24(sp)
    8000513a:	6442                	ld	s0,16(sp)
    8000513c:	64a2                	ld	s1,8(sp)
    8000513e:	6105                	addi	sp,sp,32
    80005140:	8082                	ret
    panic("filedup");
    80005142:	00005517          	auipc	a0,0x5
    80005146:	88650513          	addi	a0,a0,-1914 # 800099c8 <syscalls+0x2b0>
    8000514a:	ffffb097          	auipc	ra,0xffffb
    8000514e:	3e0080e7          	jalr	992(ra) # 8000052a <panic>

0000000080005152 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005152:	7139                	addi	sp,sp,-64
    80005154:	fc06                	sd	ra,56(sp)
    80005156:	f822                	sd	s0,48(sp)
    80005158:	f426                	sd	s1,40(sp)
    8000515a:	f04a                	sd	s2,32(sp)
    8000515c:	ec4e                	sd	s3,24(sp)
    8000515e:	e852                	sd	s4,16(sp)
    80005160:	e456                	sd	s5,8(sp)
    80005162:	0080                	addi	s0,sp,64
    80005164:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005166:	00025517          	auipc	a0,0x25
    8000516a:	65250513          	addi	a0,a0,1618 # 8002a7b8 <ftable>
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	a54080e7          	jalr	-1452(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005176:	40dc                	lw	a5,4(s1)
    80005178:	06f05163          	blez	a5,800051da <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000517c:	37fd                	addiw	a5,a5,-1
    8000517e:	0007871b          	sext.w	a4,a5
    80005182:	c0dc                	sw	a5,4(s1)
    80005184:	06e04363          	bgtz	a4,800051ea <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005188:	0004a903          	lw	s2,0(s1)
    8000518c:	0094ca83          	lbu	s5,9(s1)
    80005190:	0104ba03          	ld	s4,16(s1)
    80005194:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005198:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000519c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800051a0:	00025517          	auipc	a0,0x25
    800051a4:	61850513          	addi	a0,a0,1560 # 8002a7b8 <ftable>
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	ace080e7          	jalr	-1330(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800051b0:	4785                	li	a5,1
    800051b2:	04f90d63          	beq	s2,a5,8000520c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051b6:	3979                	addiw	s2,s2,-2
    800051b8:	4785                	li	a5,1
    800051ba:	0527e063          	bltu	a5,s2,800051fa <fileclose+0xa8>
    begin_op();
    800051be:	00000097          	auipc	ra,0x0
    800051c2:	ac8080e7          	jalr	-1336(ra) # 80004c86 <begin_op>
    iput(ff.ip);
    800051c6:	854e                	mv	a0,s3
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	f90080e7          	jalr	-112(ra) # 80004158 <iput>
    end_op();
    800051d0:	00000097          	auipc	ra,0x0
    800051d4:	b36080e7          	jalr	-1226(ra) # 80004d06 <end_op>
    800051d8:	a00d                	j	800051fa <fileclose+0xa8>
    panic("fileclose");
    800051da:	00004517          	auipc	a0,0x4
    800051de:	7f650513          	addi	a0,a0,2038 # 800099d0 <syscalls+0x2b8>
    800051e2:	ffffb097          	auipc	ra,0xffffb
    800051e6:	348080e7          	jalr	840(ra) # 8000052a <panic>
    release(&ftable.lock);
    800051ea:	00025517          	auipc	a0,0x25
    800051ee:	5ce50513          	addi	a0,a0,1486 # 8002a7b8 <ftable>
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	a84080e7          	jalr	-1404(ra) # 80000c76 <release>
  }
}
    800051fa:	70e2                	ld	ra,56(sp)
    800051fc:	7442                	ld	s0,48(sp)
    800051fe:	74a2                	ld	s1,40(sp)
    80005200:	7902                	ld	s2,32(sp)
    80005202:	69e2                	ld	s3,24(sp)
    80005204:	6a42                	ld	s4,16(sp)
    80005206:	6aa2                	ld	s5,8(sp)
    80005208:	6121                	addi	sp,sp,64
    8000520a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000520c:	85d6                	mv	a1,s5
    8000520e:	8552                	mv	a0,s4
    80005210:	00000097          	auipc	ra,0x0
    80005214:	542080e7          	jalr	1346(ra) # 80005752 <pipeclose>
    80005218:	b7cd                	j	800051fa <fileclose+0xa8>

000000008000521a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000521a:	715d                	addi	sp,sp,-80
    8000521c:	e486                	sd	ra,72(sp)
    8000521e:	e0a2                	sd	s0,64(sp)
    80005220:	fc26                	sd	s1,56(sp)
    80005222:	f84a                	sd	s2,48(sp)
    80005224:	f44e                	sd	s3,40(sp)
    80005226:	0880                	addi	s0,sp,80
    80005228:	84aa                	mv	s1,a0
    8000522a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000522c:	ffffc097          	auipc	ra,0xffffc
    80005230:	7a8080e7          	jalr	1960(ra) # 800019d4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005234:	409c                	lw	a5,0(s1)
    80005236:	37f9                	addiw	a5,a5,-2
    80005238:	4705                	li	a4,1
    8000523a:	04f76763          	bltu	a4,a5,80005288 <filestat+0x6e>
    8000523e:	892a                	mv	s2,a0
    ilock(f->ip);
    80005240:	6c88                	ld	a0,24(s1)
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	d5c080e7          	jalr	-676(ra) # 80003f9e <ilock>
    stati(f->ip, &st);
    8000524a:	fb840593          	addi	a1,s0,-72
    8000524e:	6c88                	ld	a0,24(s1)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	fd8080e7          	jalr	-40(ra) # 80004228 <stati>
    iunlock(f->ip);
    80005258:	6c88                	ld	a0,24(s1)
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	e06080e7          	jalr	-506(ra) # 80004060 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005262:	46e1                	li	a3,24
    80005264:	fb840613          	addi	a2,s0,-72
    80005268:	85ce                	mv	a1,s3
    8000526a:	05093503          	ld	a0,80(s2)
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	426080e7          	jalr	1062(ra) # 80001694 <copyout>
    80005276:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000527a:	60a6                	ld	ra,72(sp)
    8000527c:	6406                	ld	s0,64(sp)
    8000527e:	74e2                	ld	s1,56(sp)
    80005280:	7942                	ld	s2,48(sp)
    80005282:	79a2                	ld	s3,40(sp)
    80005284:	6161                	addi	sp,sp,80
    80005286:	8082                	ret
  return -1;
    80005288:	557d                	li	a0,-1
    8000528a:	bfc5                	j	8000527a <filestat+0x60>

000000008000528c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000528c:	7179                	addi	sp,sp,-48
    8000528e:	f406                	sd	ra,40(sp)
    80005290:	f022                	sd	s0,32(sp)
    80005292:	ec26                	sd	s1,24(sp)
    80005294:	e84a                	sd	s2,16(sp)
    80005296:	e44e                	sd	s3,8(sp)
    80005298:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000529a:	00854783          	lbu	a5,8(a0)
    8000529e:	c3d5                	beqz	a5,80005342 <fileread+0xb6>
    800052a0:	84aa                	mv	s1,a0
    800052a2:	89ae                	mv	s3,a1
    800052a4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052a6:	411c                	lw	a5,0(a0)
    800052a8:	4705                	li	a4,1
    800052aa:	04e78963          	beq	a5,a4,800052fc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052ae:	470d                	li	a4,3
    800052b0:	04e78d63          	beq	a5,a4,8000530a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052b4:	4709                	li	a4,2
    800052b6:	06e79e63          	bne	a5,a4,80005332 <fileread+0xa6>
    ilock(f->ip);
    800052ba:	6d08                	ld	a0,24(a0)
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	ce2080e7          	jalr	-798(ra) # 80003f9e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052c4:	874a                	mv	a4,s2
    800052c6:	5094                	lw	a3,32(s1)
    800052c8:	864e                	mv	a2,s3
    800052ca:	4585                	li	a1,1
    800052cc:	6c88                	ld	a0,24(s1)
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	f84080e7          	jalr	-124(ra) # 80004252 <readi>
    800052d6:	892a                	mv	s2,a0
    800052d8:	00a05563          	blez	a0,800052e2 <fileread+0x56>
      f->off += r;
    800052dc:	509c                	lw	a5,32(s1)
    800052de:	9fa9                	addw	a5,a5,a0
    800052e0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052e2:	6c88                	ld	a0,24(s1)
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	d7c080e7          	jalr	-644(ra) # 80004060 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052ec:	854a                	mv	a0,s2
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	64e2                	ld	s1,24(sp)
    800052f4:	6942                	ld	s2,16(sp)
    800052f6:	69a2                	ld	s3,8(sp)
    800052f8:	6145                	addi	sp,sp,48
    800052fa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800052fc:	6908                	ld	a0,16(a0)
    800052fe:	00000097          	auipc	ra,0x0
    80005302:	5b6080e7          	jalr	1462(ra) # 800058b4 <piperead>
    80005306:	892a                	mv	s2,a0
    80005308:	b7d5                	j	800052ec <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000530a:	02451783          	lh	a5,36(a0)
    8000530e:	03079693          	slli	a3,a5,0x30
    80005312:	92c1                	srli	a3,a3,0x30
    80005314:	4725                	li	a4,9
    80005316:	02d76863          	bltu	a4,a3,80005346 <fileread+0xba>
    8000531a:	0792                	slli	a5,a5,0x4
    8000531c:	00025717          	auipc	a4,0x25
    80005320:	3fc70713          	addi	a4,a4,1020 # 8002a718 <devsw>
    80005324:	97ba                	add	a5,a5,a4
    80005326:	639c                	ld	a5,0(a5)
    80005328:	c38d                	beqz	a5,8000534a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000532a:	4505                	li	a0,1
    8000532c:	9782                	jalr	a5
    8000532e:	892a                	mv	s2,a0
    80005330:	bf75                	j	800052ec <fileread+0x60>
    panic("fileread");
    80005332:	00004517          	auipc	a0,0x4
    80005336:	6ae50513          	addi	a0,a0,1710 # 800099e0 <syscalls+0x2c8>
    8000533a:	ffffb097          	auipc	ra,0xffffb
    8000533e:	1f0080e7          	jalr	496(ra) # 8000052a <panic>
    return -1;
    80005342:	597d                	li	s2,-1
    80005344:	b765                	j	800052ec <fileread+0x60>
      return -1;
    80005346:	597d                	li	s2,-1
    80005348:	b755                	j	800052ec <fileread+0x60>
    8000534a:	597d                	li	s2,-1
    8000534c:	b745                	j	800052ec <fileread+0x60>

000000008000534e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000534e:	715d                	addi	sp,sp,-80
    80005350:	e486                	sd	ra,72(sp)
    80005352:	e0a2                	sd	s0,64(sp)
    80005354:	fc26                	sd	s1,56(sp)
    80005356:	f84a                	sd	s2,48(sp)
    80005358:	f44e                	sd	s3,40(sp)
    8000535a:	f052                	sd	s4,32(sp)
    8000535c:	ec56                	sd	s5,24(sp)
    8000535e:	e85a                	sd	s6,16(sp)
    80005360:	e45e                	sd	s7,8(sp)
    80005362:	e062                	sd	s8,0(sp)
    80005364:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005366:	00954783          	lbu	a5,9(a0)
    8000536a:	10078663          	beqz	a5,80005476 <filewrite+0x128>
    8000536e:	892a                	mv	s2,a0
    80005370:	8aae                	mv	s5,a1
    80005372:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005374:	411c                	lw	a5,0(a0)
    80005376:	4705                	li	a4,1
    80005378:	02e78263          	beq	a5,a4,8000539c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000537c:	470d                	li	a4,3
    8000537e:	02e78663          	beq	a5,a4,800053aa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005382:	4709                	li	a4,2
    80005384:	0ee79163          	bne	a5,a4,80005466 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005388:	0ac05d63          	blez	a2,80005442 <filewrite+0xf4>
    int i = 0;
    8000538c:	4981                	li	s3,0
    8000538e:	6b05                	lui	s6,0x1
    80005390:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005394:	6b85                	lui	s7,0x1
    80005396:	c00b8b9b          	addiw	s7,s7,-1024
    8000539a:	a861                	j	80005432 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000539c:	6908                	ld	a0,16(a0)
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	424080e7          	jalr	1060(ra) # 800057c2 <pipewrite>
    800053a6:	8a2a                	mv	s4,a0
    800053a8:	a045                	j	80005448 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053aa:	02451783          	lh	a5,36(a0)
    800053ae:	03079693          	slli	a3,a5,0x30
    800053b2:	92c1                	srli	a3,a3,0x30
    800053b4:	4725                	li	a4,9
    800053b6:	0cd76263          	bltu	a4,a3,8000547a <filewrite+0x12c>
    800053ba:	0792                	slli	a5,a5,0x4
    800053bc:	00025717          	auipc	a4,0x25
    800053c0:	35c70713          	addi	a4,a4,860 # 8002a718 <devsw>
    800053c4:	97ba                	add	a5,a5,a4
    800053c6:	679c                	ld	a5,8(a5)
    800053c8:	cbdd                	beqz	a5,8000547e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053ca:	4505                	li	a0,1
    800053cc:	9782                	jalr	a5
    800053ce:	8a2a                	mv	s4,a0
    800053d0:	a8a5                	j	80005448 <filewrite+0xfa>
    800053d2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053d6:	00000097          	auipc	ra,0x0
    800053da:	8b0080e7          	jalr	-1872(ra) # 80004c86 <begin_op>
      ilock(f->ip);
    800053de:	01893503          	ld	a0,24(s2)
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	bbc080e7          	jalr	-1092(ra) # 80003f9e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053ea:	8762                	mv	a4,s8
    800053ec:	02092683          	lw	a3,32(s2)
    800053f0:	01598633          	add	a2,s3,s5
    800053f4:	4585                	li	a1,1
    800053f6:	01893503          	ld	a0,24(s2)
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	f50080e7          	jalr	-176(ra) # 8000434a <writei>
    80005402:	84aa                	mv	s1,a0
    80005404:	00a05763          	blez	a0,80005412 <filewrite+0xc4>
        f->off += r;
    80005408:	02092783          	lw	a5,32(s2)
    8000540c:	9fa9                	addw	a5,a5,a0
    8000540e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005412:	01893503          	ld	a0,24(s2)
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	c4a080e7          	jalr	-950(ra) # 80004060 <iunlock>
      end_op();
    8000541e:	00000097          	auipc	ra,0x0
    80005422:	8e8080e7          	jalr	-1816(ra) # 80004d06 <end_op>

      if(r != n1){
    80005426:	009c1f63          	bne	s8,s1,80005444 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000542a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000542e:	0149db63          	bge	s3,s4,80005444 <filewrite+0xf6>
      int n1 = n - i;
    80005432:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005436:	84be                	mv	s1,a5
    80005438:	2781                	sext.w	a5,a5
    8000543a:	f8fb5ce3          	bge	s6,a5,800053d2 <filewrite+0x84>
    8000543e:	84de                	mv	s1,s7
    80005440:	bf49                	j	800053d2 <filewrite+0x84>
    int i = 0;
    80005442:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005444:	013a1f63          	bne	s4,s3,80005462 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005448:	8552                	mv	a0,s4
    8000544a:	60a6                	ld	ra,72(sp)
    8000544c:	6406                	ld	s0,64(sp)
    8000544e:	74e2                	ld	s1,56(sp)
    80005450:	7942                	ld	s2,48(sp)
    80005452:	79a2                	ld	s3,40(sp)
    80005454:	7a02                	ld	s4,32(sp)
    80005456:	6ae2                	ld	s5,24(sp)
    80005458:	6b42                	ld	s6,16(sp)
    8000545a:	6ba2                	ld	s7,8(sp)
    8000545c:	6c02                	ld	s8,0(sp)
    8000545e:	6161                	addi	sp,sp,80
    80005460:	8082                	ret
    ret = (i == n ? n : -1);
    80005462:	5a7d                	li	s4,-1
    80005464:	b7d5                	j	80005448 <filewrite+0xfa>
    panic("filewrite");
    80005466:	00004517          	auipc	a0,0x4
    8000546a:	58a50513          	addi	a0,a0,1418 # 800099f0 <syscalls+0x2d8>
    8000546e:	ffffb097          	auipc	ra,0xffffb
    80005472:	0bc080e7          	jalr	188(ra) # 8000052a <panic>
    return -1;
    80005476:	5a7d                	li	s4,-1
    80005478:	bfc1                	j	80005448 <filewrite+0xfa>
      return -1;
    8000547a:	5a7d                	li	s4,-1
    8000547c:	b7f1                	j	80005448 <filewrite+0xfa>
    8000547e:	5a7d                	li	s4,-1
    80005480:	b7e1                	j	80005448 <filewrite+0xfa>

0000000080005482 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80005482:	7179                	addi	sp,sp,-48
    80005484:	f406                	sd	ra,40(sp)
    80005486:	f022                	sd	s0,32(sp)
    80005488:	ec26                	sd	s1,24(sp)
    8000548a:	e84a                	sd	s2,16(sp)
    8000548c:	e44e                	sd	s3,8(sp)
    8000548e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005490:	00854783          	lbu	a5,8(a0)
    80005494:	c3d5                	beqz	a5,80005538 <kfileread+0xb6>
    80005496:	84aa                	mv	s1,a0
    80005498:	89ae                	mv	s3,a1
    8000549a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000549c:	411c                	lw	a5,0(a0)
    8000549e:	4705                	li	a4,1
    800054a0:	04e78963          	beq	a5,a4,800054f2 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054a4:	470d                	li	a4,3
    800054a6:	04e78d63          	beq	a5,a4,80005500 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800054aa:	4709                	li	a4,2
    800054ac:	06e79e63          	bne	a5,a4,80005528 <kfileread+0xa6>
    ilock(f->ip);
    800054b0:	6d08                	ld	a0,24(a0)
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	aec080e7          	jalr	-1300(ra) # 80003f9e <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800054ba:	874a                	mv	a4,s2
    800054bc:	5094                	lw	a3,32(s1)
    800054be:	864e                	mv	a2,s3
    800054c0:	4581                	li	a1,0
    800054c2:	6c88                	ld	a0,24(s1)
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	d8e080e7          	jalr	-626(ra) # 80004252 <readi>
    800054cc:	892a                	mv	s2,a0
    800054ce:	00a05563          	blez	a0,800054d8 <kfileread+0x56>
      f->off += r;
    800054d2:	509c                	lw	a5,32(s1)
    800054d4:	9fa9                	addw	a5,a5,a0
    800054d6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800054d8:	6c88                	ld	a0,24(s1)
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	b86080e7          	jalr	-1146(ra) # 80004060 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800054e2:	854a                	mv	a0,s2
    800054e4:	70a2                	ld	ra,40(sp)
    800054e6:	7402                	ld	s0,32(sp)
    800054e8:	64e2                	ld	s1,24(sp)
    800054ea:	6942                	ld	s2,16(sp)
    800054ec:	69a2                	ld	s3,8(sp)
    800054ee:	6145                	addi	sp,sp,48
    800054f0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800054f2:	6908                	ld	a0,16(a0)
    800054f4:	00000097          	auipc	ra,0x0
    800054f8:	3c0080e7          	jalr	960(ra) # 800058b4 <piperead>
    800054fc:	892a                	mv	s2,a0
    800054fe:	b7d5                	j	800054e2 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005500:	02451783          	lh	a5,36(a0)
    80005504:	03079693          	slli	a3,a5,0x30
    80005508:	92c1                	srli	a3,a3,0x30
    8000550a:	4725                	li	a4,9
    8000550c:	02d76863          	bltu	a4,a3,8000553c <kfileread+0xba>
    80005510:	0792                	slli	a5,a5,0x4
    80005512:	00025717          	auipc	a4,0x25
    80005516:	20670713          	addi	a4,a4,518 # 8002a718 <devsw>
    8000551a:	97ba                	add	a5,a5,a4
    8000551c:	639c                	ld	a5,0(a5)
    8000551e:	c38d                	beqz	a5,80005540 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005520:	4505                	li	a0,1
    80005522:	9782                	jalr	a5
    80005524:	892a                	mv	s2,a0
    80005526:	bf75                	j	800054e2 <kfileread+0x60>
    panic("fileread");
    80005528:	00004517          	auipc	a0,0x4
    8000552c:	4b850513          	addi	a0,a0,1208 # 800099e0 <syscalls+0x2c8>
    80005530:	ffffb097          	auipc	ra,0xffffb
    80005534:	ffa080e7          	jalr	-6(ra) # 8000052a <panic>
    return -1;
    80005538:	597d                	li	s2,-1
    8000553a:	b765                	j	800054e2 <kfileread+0x60>
      return -1;
    8000553c:	597d                	li	s2,-1
    8000553e:	b755                	j	800054e2 <kfileread+0x60>
    80005540:	597d                	li	s2,-1
    80005542:	b745                	j	800054e2 <kfileread+0x60>

0000000080005544 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005544:	715d                	addi	sp,sp,-80
    80005546:	e486                	sd	ra,72(sp)
    80005548:	e0a2                	sd	s0,64(sp)
    8000554a:	fc26                	sd	s1,56(sp)
    8000554c:	f84a                	sd	s2,48(sp)
    8000554e:	f44e                	sd	s3,40(sp)
    80005550:	f052                	sd	s4,32(sp)
    80005552:	ec56                	sd	s5,24(sp)
    80005554:	e85a                	sd	s6,16(sp)
    80005556:	e45e                	sd	s7,8(sp)
    80005558:	e062                	sd	s8,0(sp)
    8000555a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000555c:	00954783          	lbu	a5,9(a0)
    80005560:	10078663          	beqz	a5,8000566c <kfilewrite+0x128>
    80005564:	892a                	mv	s2,a0
    80005566:	8aae                	mv	s5,a1
    80005568:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000556a:	411c                	lw	a5,0(a0)
    8000556c:	4705                	li	a4,1
    8000556e:	02e78263          	beq	a5,a4,80005592 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005572:	470d                	li	a4,3
    80005574:	02e78663          	beq	a5,a4,800055a0 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005578:	4709                	li	a4,2
    8000557a:	0ee79163          	bne	a5,a4,8000565c <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000557e:	0ac05d63          	blez	a2,80005638 <kfilewrite+0xf4>
    int i = 0;
    80005582:	4981                	li	s3,0
    80005584:	6b05                	lui	s6,0x1
    80005586:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000558a:	6b85                	lui	s7,0x1
    8000558c:	c00b8b9b          	addiw	s7,s7,-1024
    80005590:	a861                	j	80005628 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005592:	6908                	ld	a0,16(a0)
    80005594:	00000097          	auipc	ra,0x0
    80005598:	22e080e7          	jalr	558(ra) # 800057c2 <pipewrite>
    8000559c:	8a2a                	mv	s4,a0
    8000559e:	a045                	j	8000563e <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800055a0:	02451783          	lh	a5,36(a0)
    800055a4:	03079693          	slli	a3,a5,0x30
    800055a8:	92c1                	srli	a3,a3,0x30
    800055aa:	4725                	li	a4,9
    800055ac:	0cd76263          	bltu	a4,a3,80005670 <kfilewrite+0x12c>
    800055b0:	0792                	slli	a5,a5,0x4
    800055b2:	00025717          	auipc	a4,0x25
    800055b6:	16670713          	addi	a4,a4,358 # 8002a718 <devsw>
    800055ba:	97ba                	add	a5,a5,a4
    800055bc:	679c                	ld	a5,8(a5)
    800055be:	cbdd                	beqz	a5,80005674 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800055c0:	4505                	li	a0,1
    800055c2:	9782                	jalr	a5
    800055c4:	8a2a                	mv	s4,a0
    800055c6:	a8a5                	j	8000563e <kfilewrite+0xfa>
    800055c8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	6ba080e7          	jalr	1722(ra) # 80004c86 <begin_op>
      ilock(f->ip);
    800055d4:	01893503          	ld	a0,24(s2)
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	9c6080e7          	jalr	-1594(ra) # 80003f9e <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800055e0:	8762                	mv	a4,s8
    800055e2:	02092683          	lw	a3,32(s2)
    800055e6:	01598633          	add	a2,s3,s5
    800055ea:	4581                	li	a1,0
    800055ec:	01893503          	ld	a0,24(s2)
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	d5a080e7          	jalr	-678(ra) # 8000434a <writei>
    800055f8:	84aa                	mv	s1,a0
    800055fa:	00a05763          	blez	a0,80005608 <kfilewrite+0xc4>
        f->off += r;
    800055fe:	02092783          	lw	a5,32(s2)
    80005602:	9fa9                	addw	a5,a5,a0
    80005604:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005608:	01893503          	ld	a0,24(s2)
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	a54080e7          	jalr	-1452(ra) # 80004060 <iunlock>
      end_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	6f2080e7          	jalr	1778(ra) # 80004d06 <end_op>

      if(r != n1){
    8000561c:	009c1f63          	bne	s8,s1,8000563a <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005620:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005624:	0149db63          	bge	s3,s4,8000563a <kfilewrite+0xf6>
      int n1 = n - i;
    80005628:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000562c:	84be                	mv	s1,a5
    8000562e:	2781                	sext.w	a5,a5
    80005630:	f8fb5ce3          	bge	s6,a5,800055c8 <kfilewrite+0x84>
    80005634:	84de                	mv	s1,s7
    80005636:	bf49                	j	800055c8 <kfilewrite+0x84>
    int i = 0;
    80005638:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000563a:	013a1f63          	bne	s4,s3,80005658 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    8000563e:	8552                	mv	a0,s4
    80005640:	60a6                	ld	ra,72(sp)
    80005642:	6406                	ld	s0,64(sp)
    80005644:	74e2                	ld	s1,56(sp)
    80005646:	7942                	ld	s2,48(sp)
    80005648:	79a2                	ld	s3,40(sp)
    8000564a:	7a02                	ld	s4,32(sp)
    8000564c:	6ae2                	ld	s5,24(sp)
    8000564e:	6b42                	ld	s6,16(sp)
    80005650:	6ba2                	ld	s7,8(sp)
    80005652:	6c02                	ld	s8,0(sp)
    80005654:	6161                	addi	sp,sp,80
    80005656:	8082                	ret
    ret = (i == n ? n : -1);
    80005658:	5a7d                	li	s4,-1
    8000565a:	b7d5                	j	8000563e <kfilewrite+0xfa>
    panic("filewrite");
    8000565c:	00004517          	auipc	a0,0x4
    80005660:	39450513          	addi	a0,a0,916 # 800099f0 <syscalls+0x2d8>
    80005664:	ffffb097          	auipc	ra,0xffffb
    80005668:	ec6080e7          	jalr	-314(ra) # 8000052a <panic>
    return -1;
    8000566c:	5a7d                	li	s4,-1
    8000566e:	bfc1                	j	8000563e <kfilewrite+0xfa>
      return -1;
    80005670:	5a7d                	li	s4,-1
    80005672:	b7f1                	j	8000563e <kfilewrite+0xfa>
    80005674:	5a7d                	li	s4,-1
    80005676:	b7e1                	j	8000563e <kfilewrite+0xfa>

0000000080005678 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005678:	7179                	addi	sp,sp,-48
    8000567a:	f406                	sd	ra,40(sp)
    8000567c:	f022                	sd	s0,32(sp)
    8000567e:	ec26                	sd	s1,24(sp)
    80005680:	e84a                	sd	s2,16(sp)
    80005682:	e44e                	sd	s3,8(sp)
    80005684:	e052                	sd	s4,0(sp)
    80005686:	1800                	addi	s0,sp,48
    80005688:	84aa                	mv	s1,a0
    8000568a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000568c:	0005b023          	sd	zero,0(a1)
    80005690:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005694:	00000097          	auipc	ra,0x0
    80005698:	a02080e7          	jalr	-1534(ra) # 80005096 <filealloc>
    8000569c:	e088                	sd	a0,0(s1)
    8000569e:	c551                	beqz	a0,8000572a <pipealloc+0xb2>
    800056a0:	00000097          	auipc	ra,0x0
    800056a4:	9f6080e7          	jalr	-1546(ra) # 80005096 <filealloc>
    800056a8:	00aa3023          	sd	a0,0(s4)
    800056ac:	c92d                	beqz	a0,8000571e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800056ae:	ffffb097          	auipc	ra,0xffffb
    800056b2:	424080e7          	jalr	1060(ra) # 80000ad2 <kalloc>
    800056b6:	892a                	mv	s2,a0
    800056b8:	c125                	beqz	a0,80005718 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800056ba:	4985                	li	s3,1
    800056bc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800056c0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800056c4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800056c8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800056cc:	00004597          	auipc	a1,0x4
    800056d0:	33458593          	addi	a1,a1,820 # 80009a00 <syscalls+0x2e8>
    800056d4:	ffffb097          	auipc	ra,0xffffb
    800056d8:	45e080e7          	jalr	1118(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800056dc:	609c                	ld	a5,0(s1)
    800056de:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800056e2:	609c                	ld	a5,0(s1)
    800056e4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800056e8:	609c                	ld	a5,0(s1)
    800056ea:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800056ee:	609c                	ld	a5,0(s1)
    800056f0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800056f4:	000a3783          	ld	a5,0(s4)
    800056f8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800056fc:	000a3783          	ld	a5,0(s4)
    80005700:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005704:	000a3783          	ld	a5,0(s4)
    80005708:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000570c:	000a3783          	ld	a5,0(s4)
    80005710:	0127b823          	sd	s2,16(a5)
  return 0;
    80005714:	4501                	li	a0,0
    80005716:	a025                	j	8000573e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005718:	6088                	ld	a0,0(s1)
    8000571a:	e501                	bnez	a0,80005722 <pipealloc+0xaa>
    8000571c:	a039                	j	8000572a <pipealloc+0xb2>
    8000571e:	6088                	ld	a0,0(s1)
    80005720:	c51d                	beqz	a0,8000574e <pipealloc+0xd6>
    fileclose(*f0);
    80005722:	00000097          	auipc	ra,0x0
    80005726:	a30080e7          	jalr	-1488(ra) # 80005152 <fileclose>
  if(*f1)
    8000572a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000572e:	557d                	li	a0,-1
  if(*f1)
    80005730:	c799                	beqz	a5,8000573e <pipealloc+0xc6>
    fileclose(*f1);
    80005732:	853e                	mv	a0,a5
    80005734:	00000097          	auipc	ra,0x0
    80005738:	a1e080e7          	jalr	-1506(ra) # 80005152 <fileclose>
  return -1;
    8000573c:	557d                	li	a0,-1
}
    8000573e:	70a2                	ld	ra,40(sp)
    80005740:	7402                	ld	s0,32(sp)
    80005742:	64e2                	ld	s1,24(sp)
    80005744:	6942                	ld	s2,16(sp)
    80005746:	69a2                	ld	s3,8(sp)
    80005748:	6a02                	ld	s4,0(sp)
    8000574a:	6145                	addi	sp,sp,48
    8000574c:	8082                	ret
  return -1;
    8000574e:	557d                	li	a0,-1
    80005750:	b7fd                	j	8000573e <pipealloc+0xc6>

0000000080005752 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005752:	1101                	addi	sp,sp,-32
    80005754:	ec06                	sd	ra,24(sp)
    80005756:	e822                	sd	s0,16(sp)
    80005758:	e426                	sd	s1,8(sp)
    8000575a:	e04a                	sd	s2,0(sp)
    8000575c:	1000                	addi	s0,sp,32
    8000575e:	84aa                	mv	s1,a0
    80005760:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005762:	ffffb097          	auipc	ra,0xffffb
    80005766:	460080e7          	jalr	1120(ra) # 80000bc2 <acquire>
  if(writable){
    8000576a:	02090d63          	beqz	s2,800057a4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000576e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005772:	21848513          	addi	a0,s1,536
    80005776:	ffffd097          	auipc	ra,0xffffd
    8000577a:	8e4080e7          	jalr	-1820(ra) # 8000205a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000577e:	2204b783          	ld	a5,544(s1)
    80005782:	eb95                	bnez	a5,800057b6 <pipeclose+0x64>
    release(&pi->lock);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffb097          	auipc	ra,0xffffb
    8000578a:	4f0080e7          	jalr	1264(ra) # 80000c76 <release>
    kfree((char*)pi);
    8000578e:	8526                	mv	a0,s1
    80005790:	ffffb097          	auipc	ra,0xffffb
    80005794:	246080e7          	jalr	582(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005798:	60e2                	ld	ra,24(sp)
    8000579a:	6442                	ld	s0,16(sp)
    8000579c:	64a2                	ld	s1,8(sp)
    8000579e:	6902                	ld	s2,0(sp)
    800057a0:	6105                	addi	sp,sp,32
    800057a2:	8082                	ret
    pi->readopen = 0;
    800057a4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800057a8:	21c48513          	addi	a0,s1,540
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	8ae080e7          	jalr	-1874(ra) # 8000205a <wakeup>
    800057b4:	b7e9                	j	8000577e <pipeclose+0x2c>
    release(&pi->lock);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffb097          	auipc	ra,0xffffb
    800057bc:	4be080e7          	jalr	1214(ra) # 80000c76 <release>
}
    800057c0:	bfe1                	j	80005798 <pipeclose+0x46>

00000000800057c2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800057c2:	711d                	addi	sp,sp,-96
    800057c4:	ec86                	sd	ra,88(sp)
    800057c6:	e8a2                	sd	s0,80(sp)
    800057c8:	e4a6                	sd	s1,72(sp)
    800057ca:	e0ca                	sd	s2,64(sp)
    800057cc:	fc4e                	sd	s3,56(sp)
    800057ce:	f852                	sd	s4,48(sp)
    800057d0:	f456                	sd	s5,40(sp)
    800057d2:	f05a                	sd	s6,32(sp)
    800057d4:	ec5e                	sd	s7,24(sp)
    800057d6:	e862                	sd	s8,16(sp)
    800057d8:	1080                	addi	s0,sp,96
    800057da:	84aa                	mv	s1,a0
    800057dc:	8aae                	mv	s5,a1
    800057de:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800057e0:	ffffc097          	auipc	ra,0xffffc
    800057e4:	1f4080e7          	jalr	500(ra) # 800019d4 <myproc>
    800057e8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800057ea:	8526                	mv	a0,s1
    800057ec:	ffffb097          	auipc	ra,0xffffb
    800057f0:	3d6080e7          	jalr	982(ra) # 80000bc2 <acquire>
  while(i < n){
    800057f4:	0b405363          	blez	s4,8000589a <pipewrite+0xd8>
  int i = 0;
    800057f8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800057fa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800057fc:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005800:	21c48b93          	addi	s7,s1,540
    80005804:	a089                	j	80005846 <pipewrite+0x84>
      release(&pi->lock);
    80005806:	8526                	mv	a0,s1
    80005808:	ffffb097          	auipc	ra,0xffffb
    8000580c:	46e080e7          	jalr	1134(ra) # 80000c76 <release>
      return -1;
    80005810:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005812:	854a                	mv	a0,s2
    80005814:	60e6                	ld	ra,88(sp)
    80005816:	6446                	ld	s0,80(sp)
    80005818:	64a6                	ld	s1,72(sp)
    8000581a:	6906                	ld	s2,64(sp)
    8000581c:	79e2                	ld	s3,56(sp)
    8000581e:	7a42                	ld	s4,48(sp)
    80005820:	7aa2                	ld	s5,40(sp)
    80005822:	7b02                	ld	s6,32(sp)
    80005824:	6be2                	ld	s7,24(sp)
    80005826:	6c42                	ld	s8,16(sp)
    80005828:	6125                	addi	sp,sp,96
    8000582a:	8082                	ret
      wakeup(&pi->nread);
    8000582c:	8562                	mv	a0,s8
    8000582e:	ffffd097          	auipc	ra,0xffffd
    80005832:	82c080e7          	jalr	-2004(ra) # 8000205a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005836:	85a6                	mv	a1,s1
    80005838:	855e                	mv	a0,s7
    8000583a:	ffffc097          	auipc	ra,0xffffc
    8000583e:	7bc080e7          	jalr	1980(ra) # 80001ff6 <sleep>
  while(i < n){
    80005842:	05495d63          	bge	s2,s4,8000589c <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005846:	2204a783          	lw	a5,544(s1)
    8000584a:	dfd5                	beqz	a5,80005806 <pipewrite+0x44>
    8000584c:	0289a783          	lw	a5,40(s3)
    80005850:	fbdd                	bnez	a5,80005806 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005852:	2184a783          	lw	a5,536(s1)
    80005856:	21c4a703          	lw	a4,540(s1)
    8000585a:	2007879b          	addiw	a5,a5,512
    8000585e:	fcf707e3          	beq	a4,a5,8000582c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005862:	4685                	li	a3,1
    80005864:	01590633          	add	a2,s2,s5
    80005868:	faf40593          	addi	a1,s0,-81
    8000586c:	0509b503          	ld	a0,80(s3)
    80005870:	ffffc097          	auipc	ra,0xffffc
    80005874:	eb0080e7          	jalr	-336(ra) # 80001720 <copyin>
    80005878:	03650263          	beq	a0,s6,8000589c <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000587c:	21c4a783          	lw	a5,540(s1)
    80005880:	0017871b          	addiw	a4,a5,1
    80005884:	20e4ae23          	sw	a4,540(s1)
    80005888:	1ff7f793          	andi	a5,a5,511
    8000588c:	97a6                	add	a5,a5,s1
    8000588e:	faf44703          	lbu	a4,-81(s0)
    80005892:	00e78c23          	sb	a4,24(a5)
      i++;
    80005896:	2905                	addiw	s2,s2,1
    80005898:	b76d                	j	80005842 <pipewrite+0x80>
  int i = 0;
    8000589a:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000589c:	21848513          	addi	a0,s1,536
    800058a0:	ffffc097          	auipc	ra,0xffffc
    800058a4:	7ba080e7          	jalr	1978(ra) # 8000205a <wakeup>
  release(&pi->lock);
    800058a8:	8526                	mv	a0,s1
    800058aa:	ffffb097          	auipc	ra,0xffffb
    800058ae:	3cc080e7          	jalr	972(ra) # 80000c76 <release>
  return i;
    800058b2:	b785                	j	80005812 <pipewrite+0x50>

00000000800058b4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800058b4:	715d                	addi	sp,sp,-80
    800058b6:	e486                	sd	ra,72(sp)
    800058b8:	e0a2                	sd	s0,64(sp)
    800058ba:	fc26                	sd	s1,56(sp)
    800058bc:	f84a                	sd	s2,48(sp)
    800058be:	f44e                	sd	s3,40(sp)
    800058c0:	f052                	sd	s4,32(sp)
    800058c2:	ec56                	sd	s5,24(sp)
    800058c4:	e85a                	sd	s6,16(sp)
    800058c6:	0880                	addi	s0,sp,80
    800058c8:	84aa                	mv	s1,a0
    800058ca:	892e                	mv	s2,a1
    800058cc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800058ce:	ffffc097          	auipc	ra,0xffffc
    800058d2:	106080e7          	jalr	262(ra) # 800019d4 <myproc>
    800058d6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffb097          	auipc	ra,0xffffb
    800058de:	2e8080e7          	jalr	744(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058e2:	2184a703          	lw	a4,536(s1)
    800058e6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800058ea:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058ee:	02f71463          	bne	a4,a5,80005916 <piperead+0x62>
    800058f2:	2244a783          	lw	a5,548(s1)
    800058f6:	c385                	beqz	a5,80005916 <piperead+0x62>
    if(pr->killed){
    800058f8:	028a2783          	lw	a5,40(s4)
    800058fc:	ebc1                	bnez	a5,8000598c <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800058fe:	85a6                	mv	a1,s1
    80005900:	854e                	mv	a0,s3
    80005902:	ffffc097          	auipc	ra,0xffffc
    80005906:	6f4080e7          	jalr	1780(ra) # 80001ff6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000590a:	2184a703          	lw	a4,536(s1)
    8000590e:	21c4a783          	lw	a5,540(s1)
    80005912:	fef700e3          	beq	a4,a5,800058f2 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005916:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005918:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000591a:	05505363          	blez	s5,80005960 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000591e:	2184a783          	lw	a5,536(s1)
    80005922:	21c4a703          	lw	a4,540(s1)
    80005926:	02f70d63          	beq	a4,a5,80005960 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000592a:	0017871b          	addiw	a4,a5,1
    8000592e:	20e4ac23          	sw	a4,536(s1)
    80005932:	1ff7f793          	andi	a5,a5,511
    80005936:	97a6                	add	a5,a5,s1
    80005938:	0187c783          	lbu	a5,24(a5)
    8000593c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005940:	4685                	li	a3,1
    80005942:	fbf40613          	addi	a2,s0,-65
    80005946:	85ca                	mv	a1,s2
    80005948:	050a3503          	ld	a0,80(s4)
    8000594c:	ffffc097          	auipc	ra,0xffffc
    80005950:	d48080e7          	jalr	-696(ra) # 80001694 <copyout>
    80005954:	01650663          	beq	a0,s6,80005960 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005958:	2985                	addiw	s3,s3,1
    8000595a:	0905                	addi	s2,s2,1
    8000595c:	fd3a91e3          	bne	s5,s3,8000591e <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005960:	21c48513          	addi	a0,s1,540
    80005964:	ffffc097          	auipc	ra,0xffffc
    80005968:	6f6080e7          	jalr	1782(ra) # 8000205a <wakeup>
  release(&pi->lock);
    8000596c:	8526                	mv	a0,s1
    8000596e:	ffffb097          	auipc	ra,0xffffb
    80005972:	308080e7          	jalr	776(ra) # 80000c76 <release>
  return i;
}
    80005976:	854e                	mv	a0,s3
    80005978:	60a6                	ld	ra,72(sp)
    8000597a:	6406                	ld	s0,64(sp)
    8000597c:	74e2                	ld	s1,56(sp)
    8000597e:	7942                	ld	s2,48(sp)
    80005980:	79a2                	ld	s3,40(sp)
    80005982:	7a02                	ld	s4,32(sp)
    80005984:	6ae2                	ld	s5,24(sp)
    80005986:	6b42                	ld	s6,16(sp)
    80005988:	6161                	addi	sp,sp,80
    8000598a:	8082                	ret
      release(&pi->lock);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffb097          	auipc	ra,0xffffb
    80005992:	2e8080e7          	jalr	744(ra) # 80000c76 <release>
      return -1;
    80005996:	59fd                	li	s3,-1
    80005998:	bff9                	j	80005976 <piperead+0xc2>

000000008000599a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000599a:	bd010113          	addi	sp,sp,-1072
    8000599e:	42113423          	sd	ra,1064(sp)
    800059a2:	42813023          	sd	s0,1056(sp)
    800059a6:	40913c23          	sd	s1,1048(sp)
    800059aa:	41213823          	sd	s2,1040(sp)
    800059ae:	41313423          	sd	s3,1032(sp)
    800059b2:	41413023          	sd	s4,1024(sp)
    800059b6:	3f513c23          	sd	s5,1016(sp)
    800059ba:	3f613823          	sd	s6,1008(sp)
    800059be:	3f713423          	sd	s7,1000(sp)
    800059c2:	3f813023          	sd	s8,992(sp)
    800059c6:	3d913c23          	sd	s9,984(sp)
    800059ca:	3da13823          	sd	s10,976(sp)
    800059ce:	3db13423          	sd	s11,968(sp)
    800059d2:	43010413          	addi	s0,sp,1072
    800059d6:	89aa                	mv	s3,a0
    800059d8:	bea43023          	sd	a0,-1056(s0)
    800059dc:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800059e0:	ffffc097          	auipc	ra,0xffffc
    800059e4:	ff4080e7          	jalr	-12(ra) # 800019d4 <myproc>
    800059e8:	84aa                	mv	s1,a0
    800059ea:	c0a43423          	sd	a0,-1016(s0)
  
  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_DISK_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    800059ee:	17050913          	addi	s2,a0,368
    800059f2:	10000613          	li	a2,256
    800059f6:	85ca                	mv	a1,s2
    800059f8:	d1040513          	addi	a0,s0,-752
    800059fc:	ffffb097          	auipc	ra,0xffffb
    80005a00:	31e080e7          	jalr	798(ra) # 80000d1a <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    80005a04:	27048493          	addi	s1,s1,624
    80005a08:	10000613          	li	a2,256
    80005a0c:	85a6                	mv	a1,s1
    80005a0e:	c1040513          	addi	a0,s0,-1008
    80005a12:	ffffb097          	auipc	ra,0xffffb
    80005a16:	308080e7          	jalr	776(ra) # 80000d1a <memmove>

  begin_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	26c080e7          	jalr	620(ra) # 80004c86 <begin_op>

  if((ip = namei(path)) == 0){
    80005a22:	854e                	mv	a0,s3
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	d30080e7          	jalr	-720(ra) # 80004754 <namei>
    80005a2c:	c569                	beqz	a0,80005af6 <exec+0x15c>
    80005a2e:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	56e080e7          	jalr	1390(ra) # 80003f9e <ilock>

  // ADDED Q1
  if(relevant_metadata_proc(p) && init_metadata(p) < 0) {
    80005a38:	c0843983          	ld	s3,-1016(s0)
    80005a3c:	854e                	mv	a0,s3
    80005a3e:	ffffd097          	auipc	ra,0xffffd
    80005a42:	4ae080e7          	jalr	1198(ra) # 80002eec <relevant_metadata_proc>
    80005a46:	c901                	beqz	a0,80005a56 <exec+0xbc>
    80005a48:	854e                	mv	a0,s3
    80005a4a:	ffffd097          	auipc	ra,0xffffd
    80005a4e:	90c080e7          	jalr	-1780(ra) # 80002356 <init_metadata>
    80005a52:	02054963          	bltz	a0,80005a84 <exec+0xea>
    goto bad;
  } 

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005a56:	04000713          	li	a4,64
    80005a5a:	4681                	li	a3,0
    80005a5c:	e4840613          	addi	a2,s0,-440
    80005a60:	4581                	li	a1,0
    80005a62:	8552                	mv	a0,s4
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	7ee080e7          	jalr	2030(ra) # 80004252 <readi>
    80005a6c:	04000793          	li	a5,64
    80005a70:	00f51a63          	bne	a0,a5,80005a84 <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005a74:	e4842703          	lw	a4,-440(s0)
    80005a78:	464c47b7          	lui	a5,0x464c4
    80005a7c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005a80:	08f70163          	beq	a4,a5,80005b02 <exec+0x168>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005a84:	10000613          	li	a2,256
    80005a88:	d1040593          	addi	a1,s0,-752
    80005a8c:	854a                	mv	a0,s2
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	28c080e7          	jalr	652(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005a96:	10000613          	li	a2,256
    80005a9a:	c1040593          	addi	a1,s0,-1008
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	ffffb097          	auipc	ra,0xffffb
    80005aa4:	27a080e7          	jalr	634(ra) # 80000d1a <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005aa8:	8552                	mv	a0,s4
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	756080e7          	jalr	1878(ra) # 80004200 <iunlockput>
    end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	254080e7          	jalr	596(ra) # 80004d06 <end_op>
  }
  return -1;
    80005aba:	557d                	li	a0,-1
}
    80005abc:	42813083          	ld	ra,1064(sp)
    80005ac0:	42013403          	ld	s0,1056(sp)
    80005ac4:	41813483          	ld	s1,1048(sp)
    80005ac8:	41013903          	ld	s2,1040(sp)
    80005acc:	40813983          	ld	s3,1032(sp)
    80005ad0:	40013a03          	ld	s4,1024(sp)
    80005ad4:	3f813a83          	ld	s5,1016(sp)
    80005ad8:	3f013b03          	ld	s6,1008(sp)
    80005adc:	3e813b83          	ld	s7,1000(sp)
    80005ae0:	3e013c03          	ld	s8,992(sp)
    80005ae4:	3d813c83          	ld	s9,984(sp)
    80005ae8:	3d013d03          	ld	s10,976(sp)
    80005aec:	3c813d83          	ld	s11,968(sp)
    80005af0:	43010113          	addi	sp,sp,1072
    80005af4:	8082                	ret
    end_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	210080e7          	jalr	528(ra) # 80004d06 <end_op>
    return -1;
    80005afe:	557d                	li	a0,-1
    80005b00:	bf75                	j	80005abc <exec+0x122>
  if((pagetable = proc_pagetable(p)) == 0)
    80005b02:	c0843503          	ld	a0,-1016(s0)
    80005b06:	ffffc097          	auipc	ra,0xffffc
    80005b0a:	f92080e7          	jalr	-110(ra) # 80001a98 <proc_pagetable>
    80005b0e:	8b2a                	mv	s6,a0
    80005b10:	d935                	beqz	a0,80005a84 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b12:	e6842783          	lw	a5,-408(s0)
    80005b16:	e8045703          	lhu	a4,-384(s0)
    80005b1a:	c735                	beqz	a4,80005b86 <exec+0x1ec>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b1c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b1e:	c0043023          	sd	zero,-1024(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005b22:	6a85                	lui	s5,0x1
    80005b24:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80005b28:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005b2c:	6d85                	lui	s11,0x1
    80005b2e:	7d7d                	lui	s10,0xfffff
    80005b30:	a4ad                	j	80005d9a <exec+0x400>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005b32:	00004517          	auipc	a0,0x4
    80005b36:	ed650513          	addi	a0,a0,-298 # 80009a08 <syscalls+0x2f0>
    80005b3a:	ffffb097          	auipc	ra,0xffffb
    80005b3e:	9f0080e7          	jalr	-1552(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005b42:	874a                	mv	a4,s2
    80005b44:	009c86bb          	addw	a3,s9,s1
    80005b48:	4581                	li	a1,0
    80005b4a:	8552                	mv	a0,s4
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	706080e7          	jalr	1798(ra) # 80004252 <readi>
    80005b54:	2501                	sext.w	a0,a0
    80005b56:	1aa91c63          	bne	s2,a0,80005d0e <exec+0x374>
  for(i = 0; i < sz; i += PGSIZE){
    80005b5a:	009d84bb          	addw	s1,s11,s1
    80005b5e:	013d09bb          	addw	s3,s10,s3
    80005b62:	2174fc63          	bgeu	s1,s7,80005d7a <exec+0x3e0>
    pa = walkaddr(pagetable, va + i);
    80005b66:	02049593          	slli	a1,s1,0x20
    80005b6a:	9181                	srli	a1,a1,0x20
    80005b6c:	95e2                	add	a1,a1,s8
    80005b6e:	855a                	mv	a0,s6
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	4dc080e7          	jalr	1244(ra) # 8000104c <walkaddr>
    80005b78:	862a                	mv	a2,a0
    if(pa == 0)
    80005b7a:	dd45                	beqz	a0,80005b32 <exec+0x198>
      n = PGSIZE;
    80005b7c:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    80005b7e:	fd59f2e3          	bgeu	s3,s5,80005b42 <exec+0x1a8>
      n = sz - i;
    80005b82:	894e                	mv	s2,s3
    80005b84:	bf7d                	j	80005b42 <exec+0x1a8>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b86:	4481                	li	s1,0
  iunlockput(ip);
    80005b88:	8552                	mv	a0,s4
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	676080e7          	jalr	1654(ra) # 80004200 <iunlockput>
  end_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	174080e7          	jalr	372(ra) # 80004d06 <end_op>
  p = myproc();
    80005b9a:	ffffc097          	auipc	ra,0xffffc
    80005b9e:	e3a080e7          	jalr	-454(ra) # 800019d4 <myproc>
    80005ba2:	c0a43423          	sd	a0,-1016(s0)
  uint64 oldsz = p->sz;
    80005ba6:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005baa:	6785                	lui	a5,0x1
    80005bac:	17fd                	addi	a5,a5,-1
    80005bae:	94be                	add	s1,s1,a5
    80005bb0:	77fd                	lui	a5,0xfffff
    80005bb2:	8fe5                	and	a5,a5,s1
    80005bb4:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005bb8:	6609                	lui	a2,0x2
    80005bba:	963e                	add	a2,a2,a5
    80005bbc:	85be                	mv	a1,a5
    80005bbe:	855a                	mv	a0,s6
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	874080e7          	jalr	-1932(ra) # 80001434 <uvmalloc>
    80005bc8:	8aaa                	mv	s5,a0
  ip = 0;
    80005bca:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005bcc:	14050163          	beqz	a0,80005d0e <exec+0x374>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005bd0:	75f9                	lui	a1,0xffffe
    80005bd2:	95aa                	add	a1,a1,a0
    80005bd4:	855a                	mv	a0,s6
    80005bd6:	ffffc097          	auipc	ra,0xffffc
    80005bda:	a8c080e7          	jalr	-1396(ra) # 80001662 <uvmclear>
  stackbase = sp - PGSIZE;
    80005bde:	7bfd                	lui	s7,0xfffff
    80005be0:	9bd6                	add	s7,s7,s5
  for(argc = 0; argv[argc]; argc++) {
    80005be2:	be843783          	ld	a5,-1048(s0)
    80005be6:	6388                	ld	a0,0(a5)
    80005be8:	c925                	beqz	a0,80005c58 <exec+0x2be>
    80005bea:	e8840993          	addi	s3,s0,-376
    80005bee:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005bf2:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005bf4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005bf6:	ffffb097          	auipc	ra,0xffffb
    80005bfa:	24c080e7          	jalr	588(ra) # 80000e42 <strlen>
    80005bfe:	0015079b          	addiw	a5,a0,1
    80005c02:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005c06:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005c0a:	15796c63          	bltu	s2,s7,80005d62 <exec+0x3c8>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005c0e:	be843d03          	ld	s10,-1048(s0)
    80005c12:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80005c16:	8552                	mv	a0,s4
    80005c18:	ffffb097          	auipc	ra,0xffffb
    80005c1c:	22a080e7          	jalr	554(ra) # 80000e42 <strlen>
    80005c20:	0015069b          	addiw	a3,a0,1
    80005c24:	8652                	mv	a2,s4
    80005c26:	85ca                	mv	a1,s2
    80005c28:	855a                	mv	a0,s6
    80005c2a:	ffffc097          	auipc	ra,0xffffc
    80005c2e:	a6a080e7          	jalr	-1430(ra) # 80001694 <copyout>
    80005c32:	12054c63          	bltz	a0,80005d6a <exec+0x3d0>
    ustack[argc] = sp;
    80005c36:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005c3a:	0485                	addi	s1,s1,1
    80005c3c:	008d0793          	addi	a5,s10,8
    80005c40:	bef43423          	sd	a5,-1048(s0)
    80005c44:	008d3503          	ld	a0,8(s10)
    80005c48:	c911                	beqz	a0,80005c5c <exec+0x2c2>
    if(argc >= MAXARG)
    80005c4a:	09a1                	addi	s3,s3,8
    80005c4c:	fb8995e3          	bne	s3,s8,80005bf6 <exec+0x25c>
  sz = sz1;
    80005c50:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005c54:	4a01                	li	s4,0
    80005c56:	a865                	j	80005d0e <exec+0x374>
  sp = sz;
    80005c58:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005c5a:	4481                	li	s1,0
  ustack[argc] = 0;
    80005c5c:	00349793          	slli	a5,s1,0x3
    80005c60:	f9040713          	addi	a4,s0,-112
    80005c64:	97ba                	add	a5,a5,a4
    80005c66:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005c6a:	00148693          	addi	a3,s1,1
    80005c6e:	068e                	slli	a3,a3,0x3
    80005c70:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c74:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005c78:	01797663          	bgeu	s2,s7,80005c84 <exec+0x2ea>
  sz = sz1;
    80005c7c:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005c80:	4a01                	li	s4,0
    80005c82:	a071                	j	80005d0e <exec+0x374>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c84:	e8840613          	addi	a2,s0,-376
    80005c88:	85ca                	mv	a1,s2
    80005c8a:	855a                	mv	a0,s6
    80005c8c:	ffffc097          	auipc	ra,0xffffc
    80005c90:	a08080e7          	jalr	-1528(ra) # 80001694 <copyout>
    80005c94:	0c054f63          	bltz	a0,80005d72 <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005c98:	c0843783          	ld	a5,-1016(s0)
    80005c9c:	6fbc                	ld	a5,88(a5)
    80005c9e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005ca2:	be043783          	ld	a5,-1056(s0)
    80005ca6:	0007c703          	lbu	a4,0(a5)
    80005caa:	cf11                	beqz	a4,80005cc6 <exec+0x32c>
    80005cac:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005cae:	02f00693          	li	a3,47
    80005cb2:	a039                	j	80005cc0 <exec+0x326>
      last = s+1;
    80005cb4:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005cb8:	0785                	addi	a5,a5,1
    80005cba:	fff7c703          	lbu	a4,-1(a5)
    80005cbe:	c701                	beqz	a4,80005cc6 <exec+0x32c>
    if(*s == '/')
    80005cc0:	fed71ce3          	bne	a4,a3,80005cb8 <exec+0x31e>
    80005cc4:	bfc5                	j	80005cb4 <exec+0x31a>
  safestrcpy(p->name, last, sizeof(p->name));
    80005cc6:	4641                	li	a2,16
    80005cc8:	be043583          	ld	a1,-1056(s0)
    80005ccc:	c0843983          	ld	s3,-1016(s0)
    80005cd0:	15898513          	addi	a0,s3,344
    80005cd4:	ffffb097          	auipc	ra,0xffffb
    80005cd8:	13c080e7          	jalr	316(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005cdc:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005ce0:	0569b823          	sd	s6,80(s3)
  p->sz = sz;
    80005ce4:	0559b423          	sd	s5,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005ce8:	0589b783          	ld	a5,88(s3)
    80005cec:	e6043703          	ld	a4,-416(s0)
    80005cf0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005cf2:	0589b783          	ld	a5,88(s3)
    80005cf6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005cfa:	85e6                	mv	a1,s9
    80005cfc:	ffffc097          	auipc	ra,0xffffc
    80005d00:	e38080e7          	jalr	-456(ra) # 80001b34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005d04:	0004851b          	sext.w	a0,s1
    80005d08:	bb55                	j	80005abc <exec+0x122>
    80005d0a:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005d0e:	10000613          	li	a2,256
    80005d12:	d1040593          	addi	a1,s0,-752
    80005d16:	c0843483          	ld	s1,-1016(s0)
    80005d1a:	17048513          	addi	a0,s1,368
    80005d1e:	ffffb097          	auipc	ra,0xffffb
    80005d22:	ffc080e7          	jalr	-4(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005d26:	10000613          	li	a2,256
    80005d2a:	c1040593          	addi	a1,s0,-1008
    80005d2e:	27048513          	addi	a0,s1,624
    80005d32:	ffffb097          	auipc	ra,0xffffb
    80005d36:	fe8080e7          	jalr	-24(ra) # 80000d1a <memmove>
    proc_freepagetable(pagetable, sz);
    80005d3a:	bf043583          	ld	a1,-1040(s0)
    80005d3e:	855a                	mv	a0,s6
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	df4080e7          	jalr	-524(ra) # 80001b34 <proc_freepagetable>
  if(ip){
    80005d48:	d60a10e3          	bnez	s4,80005aa8 <exec+0x10e>
  return -1;
    80005d4c:	557d                	li	a0,-1
    80005d4e:	b3bd                	j	80005abc <exec+0x122>
    80005d50:	be943823          	sd	s1,-1040(s0)
    80005d54:	bf6d                	j	80005d0e <exec+0x374>
    80005d56:	be943823          	sd	s1,-1040(s0)
    80005d5a:	bf55                	j	80005d0e <exec+0x374>
    80005d5c:	be943823          	sd	s1,-1040(s0)
    80005d60:	b77d                	j	80005d0e <exec+0x374>
  sz = sz1;
    80005d62:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d66:	4a01                	li	s4,0
    80005d68:	b75d                	j	80005d0e <exec+0x374>
  sz = sz1;
    80005d6a:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d6e:	4a01                	li	s4,0
    80005d70:	bf79                	j	80005d0e <exec+0x374>
  sz = sz1;
    80005d72:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d76:	4a01                	li	s4,0
    80005d78:	bf59                	j	80005d0e <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d7a:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d7e:	c0043783          	ld	a5,-1024(s0)
    80005d82:	0017869b          	addiw	a3,a5,1
    80005d86:	c0d43023          	sd	a3,-1024(s0)
    80005d8a:	bf843783          	ld	a5,-1032(s0)
    80005d8e:	0387879b          	addiw	a5,a5,56
    80005d92:	e8045703          	lhu	a4,-384(s0)
    80005d96:	dee6d9e3          	bge	a3,a4,80005b88 <exec+0x1ee>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005d9a:	2781                	sext.w	a5,a5
    80005d9c:	bef43c23          	sd	a5,-1032(s0)
    80005da0:	03800713          	li	a4,56
    80005da4:	86be                	mv	a3,a5
    80005da6:	e1040613          	addi	a2,s0,-496
    80005daa:	4581                	li	a1,0
    80005dac:	8552                	mv	a0,s4
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	4a4080e7          	jalr	1188(ra) # 80004252 <readi>
    80005db6:	03800793          	li	a5,56
    80005dba:	f4f518e3          	bne	a0,a5,80005d0a <exec+0x370>
    if(ph.type != ELF_PROG_LOAD)
    80005dbe:	e1042783          	lw	a5,-496(s0)
    80005dc2:	4705                	li	a4,1
    80005dc4:	fae79de3          	bne	a5,a4,80005d7e <exec+0x3e4>
    if(ph.memsz < ph.filesz)
    80005dc8:	e3843603          	ld	a2,-456(s0)
    80005dcc:	e3043783          	ld	a5,-464(s0)
    80005dd0:	f8f660e3          	bltu	a2,a5,80005d50 <exec+0x3b6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005dd4:	e2043783          	ld	a5,-480(s0)
    80005dd8:	963e                	add	a2,a2,a5
    80005dda:	f6f66ee3          	bltu	a2,a5,80005d56 <exec+0x3bc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005dde:	85a6                	mv	a1,s1
    80005de0:	855a                	mv	a0,s6
    80005de2:	ffffb097          	auipc	ra,0xffffb
    80005de6:	652080e7          	jalr	1618(ra) # 80001434 <uvmalloc>
    80005dea:	bea43823          	sd	a0,-1040(s0)
    80005dee:	d53d                	beqz	a0,80005d5c <exec+0x3c2>
    if(ph.vaddr % PGSIZE != 0)
    80005df0:	e2043c03          	ld	s8,-480(s0)
    80005df4:	bd843783          	ld	a5,-1064(s0)
    80005df8:	00fc77b3          	and	a5,s8,a5
    80005dfc:	fb89                	bnez	a5,80005d0e <exec+0x374>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005dfe:	e1842c83          	lw	s9,-488(s0)
    80005e02:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005e06:	f60b8ae3          	beqz	s7,80005d7a <exec+0x3e0>
    80005e0a:	89de                	mv	s3,s7
    80005e0c:	4481                	li	s1,0
    80005e0e:	bba1                	j	80005b66 <exec+0x1cc>

0000000080005e10 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005e10:	7179                	addi	sp,sp,-48
    80005e12:	f406                	sd	ra,40(sp)
    80005e14:	f022                	sd	s0,32(sp)
    80005e16:	ec26                	sd	s1,24(sp)
    80005e18:	e84a                	sd	s2,16(sp)
    80005e1a:	1800                	addi	s0,sp,48
    80005e1c:	892e                	mv	s2,a1
    80005e1e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005e20:	fdc40593          	addi	a1,s0,-36
    80005e24:	ffffd097          	auipc	ra,0xffffd
    80005e28:	608080e7          	jalr	1544(ra) # 8000342c <argint>
    80005e2c:	04054063          	bltz	a0,80005e6c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005e30:	fdc42703          	lw	a4,-36(s0)
    80005e34:	47bd                	li	a5,15
    80005e36:	02e7ed63          	bltu	a5,a4,80005e70 <argfd+0x60>
    80005e3a:	ffffc097          	auipc	ra,0xffffc
    80005e3e:	b9a080e7          	jalr	-1126(ra) # 800019d4 <myproc>
    80005e42:	fdc42703          	lw	a4,-36(s0)
    80005e46:	01a70793          	addi	a5,a4,26
    80005e4a:	078e                	slli	a5,a5,0x3
    80005e4c:	953e                	add	a0,a0,a5
    80005e4e:	611c                	ld	a5,0(a0)
    80005e50:	c395                	beqz	a5,80005e74 <argfd+0x64>
    return -1;
  if(pfd)
    80005e52:	00090463          	beqz	s2,80005e5a <argfd+0x4a>
    *pfd = fd;
    80005e56:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005e5a:	4501                	li	a0,0
  if(pf)
    80005e5c:	c091                	beqz	s1,80005e60 <argfd+0x50>
    *pf = f;
    80005e5e:	e09c                	sd	a5,0(s1)
}
    80005e60:	70a2                	ld	ra,40(sp)
    80005e62:	7402                	ld	s0,32(sp)
    80005e64:	64e2                	ld	s1,24(sp)
    80005e66:	6942                	ld	s2,16(sp)
    80005e68:	6145                	addi	sp,sp,48
    80005e6a:	8082                	ret
    return -1;
    80005e6c:	557d                	li	a0,-1
    80005e6e:	bfcd                	j	80005e60 <argfd+0x50>
    return -1;
    80005e70:	557d                	li	a0,-1
    80005e72:	b7fd                	j	80005e60 <argfd+0x50>
    80005e74:	557d                	li	a0,-1
    80005e76:	b7ed                	j	80005e60 <argfd+0x50>

0000000080005e78 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005e78:	1101                	addi	sp,sp,-32
    80005e7a:	ec06                	sd	ra,24(sp)
    80005e7c:	e822                	sd	s0,16(sp)
    80005e7e:	e426                	sd	s1,8(sp)
    80005e80:	1000                	addi	s0,sp,32
    80005e82:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005e84:	ffffc097          	auipc	ra,0xffffc
    80005e88:	b50080e7          	jalr	-1200(ra) # 800019d4 <myproc>
    80005e8c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005e8e:	0d050793          	addi	a5,a0,208
    80005e92:	4501                	li	a0,0
    80005e94:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005e96:	6398                	ld	a4,0(a5)
    80005e98:	cb19                	beqz	a4,80005eae <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005e9a:	2505                	addiw	a0,a0,1
    80005e9c:	07a1                	addi	a5,a5,8
    80005e9e:	fed51ce3          	bne	a0,a3,80005e96 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005ea2:	557d                	li	a0,-1
}
    80005ea4:	60e2                	ld	ra,24(sp)
    80005ea6:	6442                	ld	s0,16(sp)
    80005ea8:	64a2                	ld	s1,8(sp)
    80005eaa:	6105                	addi	sp,sp,32
    80005eac:	8082                	ret
      p->ofile[fd] = f;
    80005eae:	01a50793          	addi	a5,a0,26
    80005eb2:	078e                	slli	a5,a5,0x3
    80005eb4:	963e                	add	a2,a2,a5
    80005eb6:	e204                	sd	s1,0(a2)
      return fd;
    80005eb8:	b7f5                	j	80005ea4 <fdalloc+0x2c>

0000000080005eba <sys_dup>:

uint64
sys_dup(void)
{
    80005eba:	7179                	addi	sp,sp,-48
    80005ebc:	f406                	sd	ra,40(sp)
    80005ebe:	f022                	sd	s0,32(sp)
    80005ec0:	ec26                	sd	s1,24(sp)
    80005ec2:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005ec4:	fd840613          	addi	a2,s0,-40
    80005ec8:	4581                	li	a1,0
    80005eca:	4501                	li	a0,0
    80005ecc:	00000097          	auipc	ra,0x0
    80005ed0:	f44080e7          	jalr	-188(ra) # 80005e10 <argfd>
    return -1;
    80005ed4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005ed6:	02054363          	bltz	a0,80005efc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005eda:	fd843503          	ld	a0,-40(s0)
    80005ede:	00000097          	auipc	ra,0x0
    80005ee2:	f9a080e7          	jalr	-102(ra) # 80005e78 <fdalloc>
    80005ee6:	84aa                	mv	s1,a0
    return -1;
    80005ee8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005eea:	00054963          	bltz	a0,80005efc <sys_dup+0x42>
  filedup(f);
    80005eee:	fd843503          	ld	a0,-40(s0)
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	20e080e7          	jalr	526(ra) # 80005100 <filedup>
  return fd;
    80005efa:	87a6                	mv	a5,s1
}
    80005efc:	853e                	mv	a0,a5
    80005efe:	70a2                	ld	ra,40(sp)
    80005f00:	7402                	ld	s0,32(sp)
    80005f02:	64e2                	ld	s1,24(sp)
    80005f04:	6145                	addi	sp,sp,48
    80005f06:	8082                	ret

0000000080005f08 <sys_read>:

uint64
sys_read(void)
{
    80005f08:	7179                	addi	sp,sp,-48
    80005f0a:	f406                	sd	ra,40(sp)
    80005f0c:	f022                	sd	s0,32(sp)
    80005f0e:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f10:	fe840613          	addi	a2,s0,-24
    80005f14:	4581                	li	a1,0
    80005f16:	4501                	li	a0,0
    80005f18:	00000097          	auipc	ra,0x0
    80005f1c:	ef8080e7          	jalr	-264(ra) # 80005e10 <argfd>
    return -1;
    80005f20:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f22:	04054163          	bltz	a0,80005f64 <sys_read+0x5c>
    80005f26:	fe440593          	addi	a1,s0,-28
    80005f2a:	4509                	li	a0,2
    80005f2c:	ffffd097          	auipc	ra,0xffffd
    80005f30:	500080e7          	jalr	1280(ra) # 8000342c <argint>
    return -1;
    80005f34:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f36:	02054763          	bltz	a0,80005f64 <sys_read+0x5c>
    80005f3a:	fd840593          	addi	a1,s0,-40
    80005f3e:	4505                	li	a0,1
    80005f40:	ffffd097          	auipc	ra,0xffffd
    80005f44:	50e080e7          	jalr	1294(ra) # 8000344e <argaddr>
    return -1;
    80005f48:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f4a:	00054d63          	bltz	a0,80005f64 <sys_read+0x5c>
  return fileread(f, p, n);
    80005f4e:	fe442603          	lw	a2,-28(s0)
    80005f52:	fd843583          	ld	a1,-40(s0)
    80005f56:	fe843503          	ld	a0,-24(s0)
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	332080e7          	jalr	818(ra) # 8000528c <fileread>
    80005f62:	87aa                	mv	a5,a0
}
    80005f64:	853e                	mv	a0,a5
    80005f66:	70a2                	ld	ra,40(sp)
    80005f68:	7402                	ld	s0,32(sp)
    80005f6a:	6145                	addi	sp,sp,48
    80005f6c:	8082                	ret

0000000080005f6e <sys_write>:

uint64
sys_write(void)
{
    80005f6e:	7179                	addi	sp,sp,-48
    80005f70:	f406                	sd	ra,40(sp)
    80005f72:	f022                	sd	s0,32(sp)
    80005f74:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f76:	fe840613          	addi	a2,s0,-24
    80005f7a:	4581                	li	a1,0
    80005f7c:	4501                	li	a0,0
    80005f7e:	00000097          	auipc	ra,0x0
    80005f82:	e92080e7          	jalr	-366(ra) # 80005e10 <argfd>
    return -1;
    80005f86:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f88:	04054163          	bltz	a0,80005fca <sys_write+0x5c>
    80005f8c:	fe440593          	addi	a1,s0,-28
    80005f90:	4509                	li	a0,2
    80005f92:	ffffd097          	auipc	ra,0xffffd
    80005f96:	49a080e7          	jalr	1178(ra) # 8000342c <argint>
    return -1;
    80005f9a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f9c:	02054763          	bltz	a0,80005fca <sys_write+0x5c>
    80005fa0:	fd840593          	addi	a1,s0,-40
    80005fa4:	4505                	li	a0,1
    80005fa6:	ffffd097          	auipc	ra,0xffffd
    80005faa:	4a8080e7          	jalr	1192(ra) # 8000344e <argaddr>
    return -1;
    80005fae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fb0:	00054d63          	bltz	a0,80005fca <sys_write+0x5c>

  return filewrite(f, p, n);
    80005fb4:	fe442603          	lw	a2,-28(s0)
    80005fb8:	fd843583          	ld	a1,-40(s0)
    80005fbc:	fe843503          	ld	a0,-24(s0)
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	38e080e7          	jalr	910(ra) # 8000534e <filewrite>
    80005fc8:	87aa                	mv	a5,a0
}
    80005fca:	853e                	mv	a0,a5
    80005fcc:	70a2                	ld	ra,40(sp)
    80005fce:	7402                	ld	s0,32(sp)
    80005fd0:	6145                	addi	sp,sp,48
    80005fd2:	8082                	ret

0000000080005fd4 <sys_close>:

uint64
sys_close(void)
{
    80005fd4:	1101                	addi	sp,sp,-32
    80005fd6:	ec06                	sd	ra,24(sp)
    80005fd8:	e822                	sd	s0,16(sp)
    80005fda:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005fdc:	fe040613          	addi	a2,s0,-32
    80005fe0:	fec40593          	addi	a1,s0,-20
    80005fe4:	4501                	li	a0,0
    80005fe6:	00000097          	auipc	ra,0x0
    80005fea:	e2a080e7          	jalr	-470(ra) # 80005e10 <argfd>
    return -1;
    80005fee:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ff0:	02054463          	bltz	a0,80006018 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005ff4:	ffffc097          	auipc	ra,0xffffc
    80005ff8:	9e0080e7          	jalr	-1568(ra) # 800019d4 <myproc>
    80005ffc:	fec42783          	lw	a5,-20(s0)
    80006000:	07e9                	addi	a5,a5,26
    80006002:	078e                	slli	a5,a5,0x3
    80006004:	97aa                	add	a5,a5,a0
    80006006:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000600a:	fe043503          	ld	a0,-32(s0)
    8000600e:	fffff097          	auipc	ra,0xfffff
    80006012:	144080e7          	jalr	324(ra) # 80005152 <fileclose>
  return 0;
    80006016:	4781                	li	a5,0
}
    80006018:	853e                	mv	a0,a5
    8000601a:	60e2                	ld	ra,24(sp)
    8000601c:	6442                	ld	s0,16(sp)
    8000601e:	6105                	addi	sp,sp,32
    80006020:	8082                	ret

0000000080006022 <sys_fstat>:

uint64
sys_fstat(void)
{
    80006022:	1101                	addi	sp,sp,-32
    80006024:	ec06                	sd	ra,24(sp)
    80006026:	e822                	sd	s0,16(sp)
    80006028:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000602a:	fe840613          	addi	a2,s0,-24
    8000602e:	4581                	li	a1,0
    80006030:	4501                	li	a0,0
    80006032:	00000097          	auipc	ra,0x0
    80006036:	dde080e7          	jalr	-546(ra) # 80005e10 <argfd>
    return -1;
    8000603a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000603c:	02054563          	bltz	a0,80006066 <sys_fstat+0x44>
    80006040:	fe040593          	addi	a1,s0,-32
    80006044:	4505                	li	a0,1
    80006046:	ffffd097          	auipc	ra,0xffffd
    8000604a:	408080e7          	jalr	1032(ra) # 8000344e <argaddr>
    return -1;
    8000604e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006050:	00054b63          	bltz	a0,80006066 <sys_fstat+0x44>
  return filestat(f, st);
    80006054:	fe043583          	ld	a1,-32(s0)
    80006058:	fe843503          	ld	a0,-24(s0)
    8000605c:	fffff097          	auipc	ra,0xfffff
    80006060:	1be080e7          	jalr	446(ra) # 8000521a <filestat>
    80006064:	87aa                	mv	a5,a0
}
    80006066:	853e                	mv	a0,a5
    80006068:	60e2                	ld	ra,24(sp)
    8000606a:	6442                	ld	s0,16(sp)
    8000606c:	6105                	addi	sp,sp,32
    8000606e:	8082                	ret

0000000080006070 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80006070:	7169                	addi	sp,sp,-304
    80006072:	f606                	sd	ra,296(sp)
    80006074:	f222                	sd	s0,288(sp)
    80006076:	ee26                	sd	s1,280(sp)
    80006078:	ea4a                	sd	s2,272(sp)
    8000607a:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000607c:	08000613          	li	a2,128
    80006080:	ed040593          	addi	a1,s0,-304
    80006084:	4501                	li	a0,0
    80006086:	ffffd097          	auipc	ra,0xffffd
    8000608a:	3ea080e7          	jalr	1002(ra) # 80003470 <argstr>
    return -1;
    8000608e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006090:	10054e63          	bltz	a0,800061ac <sys_link+0x13c>
    80006094:	08000613          	li	a2,128
    80006098:	f5040593          	addi	a1,s0,-176
    8000609c:	4505                	li	a0,1
    8000609e:	ffffd097          	auipc	ra,0xffffd
    800060a2:	3d2080e7          	jalr	978(ra) # 80003470 <argstr>
    return -1;
    800060a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060a8:	10054263          	bltz	a0,800061ac <sys_link+0x13c>

  begin_op();
    800060ac:	fffff097          	auipc	ra,0xfffff
    800060b0:	bda080e7          	jalr	-1062(ra) # 80004c86 <begin_op>
  if((ip = namei(old)) == 0){
    800060b4:	ed040513          	addi	a0,s0,-304
    800060b8:	ffffe097          	auipc	ra,0xffffe
    800060bc:	69c080e7          	jalr	1692(ra) # 80004754 <namei>
    800060c0:	84aa                	mv	s1,a0
    800060c2:	c551                	beqz	a0,8000614e <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    800060c4:	ffffe097          	auipc	ra,0xffffe
    800060c8:	eda080e7          	jalr	-294(ra) # 80003f9e <ilock>
  if(ip->type == T_DIR){
    800060cc:	04449703          	lh	a4,68(s1)
    800060d0:	4785                	li	a5,1
    800060d2:	08f70463          	beq	a4,a5,8000615a <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    800060d6:	04a4d783          	lhu	a5,74(s1)
    800060da:	2785                	addiw	a5,a5,1
    800060dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060e0:	8526                	mv	a0,s1
    800060e2:	ffffe097          	auipc	ra,0xffffe
    800060e6:	df2080e7          	jalr	-526(ra) # 80003ed4 <iupdate>
  iunlock(ip);
    800060ea:	8526                	mv	a0,s1
    800060ec:	ffffe097          	auipc	ra,0xffffe
    800060f0:	f74080e7          	jalr	-140(ra) # 80004060 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    800060f4:	fd040593          	addi	a1,s0,-48
    800060f8:	f5040513          	addi	a0,s0,-176
    800060fc:	ffffe097          	auipc	ra,0xffffe
    80006100:	676080e7          	jalr	1654(ra) # 80004772 <nameiparent>
    80006104:	892a                	mv	s2,a0
    80006106:	c935                	beqz	a0,8000617a <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	e96080e7          	jalr	-362(ra) # 80003f9e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006110:	00092703          	lw	a4,0(s2)
    80006114:	409c                	lw	a5,0(s1)
    80006116:	04f71d63          	bne	a4,a5,80006170 <sys_link+0x100>
    8000611a:	40d0                	lw	a2,4(s1)
    8000611c:	fd040593          	addi	a1,s0,-48
    80006120:	854a                	mv	a0,s2
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	570080e7          	jalr	1392(ra) # 80004692 <dirlink>
    8000612a:	04054363          	bltz	a0,80006170 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    8000612e:	854a                	mv	a0,s2
    80006130:	ffffe097          	auipc	ra,0xffffe
    80006134:	0d0080e7          	jalr	208(ra) # 80004200 <iunlockput>
  iput(ip);
    80006138:	8526                	mv	a0,s1
    8000613a:	ffffe097          	auipc	ra,0xffffe
    8000613e:	01e080e7          	jalr	30(ra) # 80004158 <iput>

  end_op();
    80006142:	fffff097          	auipc	ra,0xfffff
    80006146:	bc4080e7          	jalr	-1084(ra) # 80004d06 <end_op>

  return 0;
    8000614a:	4781                	li	a5,0
    8000614c:	a085                	j	800061ac <sys_link+0x13c>
    end_op();
    8000614e:	fffff097          	auipc	ra,0xfffff
    80006152:	bb8080e7          	jalr	-1096(ra) # 80004d06 <end_op>
    return -1;
    80006156:	57fd                	li	a5,-1
    80006158:	a891                	j	800061ac <sys_link+0x13c>
    iunlockput(ip);
    8000615a:	8526                	mv	a0,s1
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	0a4080e7          	jalr	164(ra) # 80004200 <iunlockput>
    end_op();
    80006164:	fffff097          	auipc	ra,0xfffff
    80006168:	ba2080e7          	jalr	-1118(ra) # 80004d06 <end_op>
    return -1;
    8000616c:	57fd                	li	a5,-1
    8000616e:	a83d                	j	800061ac <sys_link+0x13c>
    iunlockput(dp);
    80006170:	854a                	mv	a0,s2
    80006172:	ffffe097          	auipc	ra,0xffffe
    80006176:	08e080e7          	jalr	142(ra) # 80004200 <iunlockput>

bad:
  ilock(ip);
    8000617a:	8526                	mv	a0,s1
    8000617c:	ffffe097          	auipc	ra,0xffffe
    80006180:	e22080e7          	jalr	-478(ra) # 80003f9e <ilock>
  ip->nlink--;
    80006184:	04a4d783          	lhu	a5,74(s1)
    80006188:	37fd                	addiw	a5,a5,-1
    8000618a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000618e:	8526                	mv	a0,s1
    80006190:	ffffe097          	auipc	ra,0xffffe
    80006194:	d44080e7          	jalr	-700(ra) # 80003ed4 <iupdate>
  iunlockput(ip);
    80006198:	8526                	mv	a0,s1
    8000619a:	ffffe097          	auipc	ra,0xffffe
    8000619e:	066080e7          	jalr	102(ra) # 80004200 <iunlockput>
  end_op();
    800061a2:	fffff097          	auipc	ra,0xfffff
    800061a6:	b64080e7          	jalr	-1180(ra) # 80004d06 <end_op>
  return -1;
    800061aa:	57fd                	li	a5,-1
}
    800061ac:	853e                	mv	a0,a5
    800061ae:	70b2                	ld	ra,296(sp)
    800061b0:	7412                	ld	s0,288(sp)
    800061b2:	64f2                	ld	s1,280(sp)
    800061b4:	6952                	ld	s2,272(sp)
    800061b6:	6155                	addi	sp,sp,304
    800061b8:	8082                	ret

00000000800061ba <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061ba:	4578                	lw	a4,76(a0)
    800061bc:	02000793          	li	a5,32
    800061c0:	04e7fa63          	bgeu	a5,a4,80006214 <isdirempty+0x5a>
{
    800061c4:	7179                	addi	sp,sp,-48
    800061c6:	f406                	sd	ra,40(sp)
    800061c8:	f022                	sd	s0,32(sp)
    800061ca:	ec26                	sd	s1,24(sp)
    800061cc:	e84a                	sd	s2,16(sp)
    800061ce:	1800                	addi	s0,sp,48
    800061d0:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061d2:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061d6:	4741                	li	a4,16
    800061d8:	86a6                	mv	a3,s1
    800061da:	fd040613          	addi	a2,s0,-48
    800061de:	4581                	li	a1,0
    800061e0:	854a                	mv	a0,s2
    800061e2:	ffffe097          	auipc	ra,0xffffe
    800061e6:	070080e7          	jalr	112(ra) # 80004252 <readi>
    800061ea:	47c1                	li	a5,16
    800061ec:	00f51c63          	bne	a0,a5,80006204 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    800061f0:	fd045783          	lhu	a5,-48(s0)
    800061f4:	e395                	bnez	a5,80006218 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061f6:	24c1                	addiw	s1,s1,16
    800061f8:	04c92783          	lw	a5,76(s2)
    800061fc:	fcf4ede3          	bltu	s1,a5,800061d6 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80006200:	4505                	li	a0,1
    80006202:	a821                	j	8000621a <isdirempty+0x60>
      panic("isdirempty: readi");
    80006204:	00004517          	auipc	a0,0x4
    80006208:	82450513          	addi	a0,a0,-2012 # 80009a28 <syscalls+0x310>
    8000620c:	ffffa097          	auipc	ra,0xffffa
    80006210:	31e080e7          	jalr	798(ra) # 8000052a <panic>
  return 1;
    80006214:	4505                	li	a0,1
}
    80006216:	8082                	ret
      return 0;
    80006218:	4501                	li	a0,0
}
    8000621a:	70a2                	ld	ra,40(sp)
    8000621c:	7402                	ld	s0,32(sp)
    8000621e:	64e2                	ld	s1,24(sp)
    80006220:	6942                	ld	s2,16(sp)
    80006222:	6145                	addi	sp,sp,48
    80006224:	8082                	ret

0000000080006226 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006226:	7155                	addi	sp,sp,-208
    80006228:	e586                	sd	ra,200(sp)
    8000622a:	e1a2                	sd	s0,192(sp)
    8000622c:	fd26                	sd	s1,184(sp)
    8000622e:	f94a                	sd	s2,176(sp)
    80006230:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006232:	08000613          	li	a2,128
    80006236:	f4040593          	addi	a1,s0,-192
    8000623a:	4501                	li	a0,0
    8000623c:	ffffd097          	auipc	ra,0xffffd
    80006240:	234080e7          	jalr	564(ra) # 80003470 <argstr>
    80006244:	16054363          	bltz	a0,800063aa <sys_unlink+0x184>
    return -1;

  begin_op();
    80006248:	fffff097          	auipc	ra,0xfffff
    8000624c:	a3e080e7          	jalr	-1474(ra) # 80004c86 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006250:	fc040593          	addi	a1,s0,-64
    80006254:	f4040513          	addi	a0,s0,-192
    80006258:	ffffe097          	auipc	ra,0xffffe
    8000625c:	51a080e7          	jalr	1306(ra) # 80004772 <nameiparent>
    80006260:	84aa                	mv	s1,a0
    80006262:	c961                	beqz	a0,80006332 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80006264:	ffffe097          	auipc	ra,0xffffe
    80006268:	d3a080e7          	jalr	-710(ra) # 80003f9e <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000626c:	00003597          	auipc	a1,0x3
    80006270:	69c58593          	addi	a1,a1,1692 # 80009908 <syscalls+0x1f0>
    80006274:	fc040513          	addi	a0,s0,-64
    80006278:	ffffe097          	auipc	ra,0xffffe
    8000627c:	1f0080e7          	jalr	496(ra) # 80004468 <namecmp>
    80006280:	c175                	beqz	a0,80006364 <sys_unlink+0x13e>
    80006282:	00003597          	auipc	a1,0x3
    80006286:	68e58593          	addi	a1,a1,1678 # 80009910 <syscalls+0x1f8>
    8000628a:	fc040513          	addi	a0,s0,-64
    8000628e:	ffffe097          	auipc	ra,0xffffe
    80006292:	1da080e7          	jalr	474(ra) # 80004468 <namecmp>
    80006296:	c579                	beqz	a0,80006364 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80006298:	f3c40613          	addi	a2,s0,-196
    8000629c:	fc040593          	addi	a1,s0,-64
    800062a0:	8526                	mv	a0,s1
    800062a2:	ffffe097          	auipc	ra,0xffffe
    800062a6:	1e0080e7          	jalr	480(ra) # 80004482 <dirlookup>
    800062aa:	892a                	mv	s2,a0
    800062ac:	cd45                	beqz	a0,80006364 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    800062ae:	ffffe097          	auipc	ra,0xffffe
    800062b2:	cf0080e7          	jalr	-784(ra) # 80003f9e <ilock>

  if(ip->nlink < 1)
    800062b6:	04a91783          	lh	a5,74(s2)
    800062ba:	08f05263          	blez	a5,8000633e <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800062be:	04491703          	lh	a4,68(s2)
    800062c2:	4785                	li	a5,1
    800062c4:	08f70563          	beq	a4,a5,8000634e <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800062c8:	4641                	li	a2,16
    800062ca:	4581                	li	a1,0
    800062cc:	fd040513          	addi	a0,s0,-48
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	9ee080e7          	jalr	-1554(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800062d8:	4741                	li	a4,16
    800062da:	f3c42683          	lw	a3,-196(s0)
    800062de:	fd040613          	addi	a2,s0,-48
    800062e2:	4581                	li	a1,0
    800062e4:	8526                	mv	a0,s1
    800062e6:	ffffe097          	auipc	ra,0xffffe
    800062ea:	064080e7          	jalr	100(ra) # 8000434a <writei>
    800062ee:	47c1                	li	a5,16
    800062f0:	08f51a63          	bne	a0,a5,80006384 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800062f4:	04491703          	lh	a4,68(s2)
    800062f8:	4785                	li	a5,1
    800062fa:	08f70d63          	beq	a4,a5,80006394 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800062fe:	8526                	mv	a0,s1
    80006300:	ffffe097          	auipc	ra,0xffffe
    80006304:	f00080e7          	jalr	-256(ra) # 80004200 <iunlockput>

  ip->nlink--;
    80006308:	04a95783          	lhu	a5,74(s2)
    8000630c:	37fd                	addiw	a5,a5,-1
    8000630e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006312:	854a                	mv	a0,s2
    80006314:	ffffe097          	auipc	ra,0xffffe
    80006318:	bc0080e7          	jalr	-1088(ra) # 80003ed4 <iupdate>
  iunlockput(ip);
    8000631c:	854a                	mv	a0,s2
    8000631e:	ffffe097          	auipc	ra,0xffffe
    80006322:	ee2080e7          	jalr	-286(ra) # 80004200 <iunlockput>

  end_op();
    80006326:	fffff097          	auipc	ra,0xfffff
    8000632a:	9e0080e7          	jalr	-1568(ra) # 80004d06 <end_op>

  return 0;
    8000632e:	4501                	li	a0,0
    80006330:	a0a1                	j	80006378 <sys_unlink+0x152>
    end_op();
    80006332:	fffff097          	auipc	ra,0xfffff
    80006336:	9d4080e7          	jalr	-1580(ra) # 80004d06 <end_op>
    return -1;
    8000633a:	557d                	li	a0,-1
    8000633c:	a835                	j	80006378 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    8000633e:	00003517          	auipc	a0,0x3
    80006342:	5da50513          	addi	a0,a0,1498 # 80009918 <syscalls+0x200>
    80006346:	ffffa097          	auipc	ra,0xffffa
    8000634a:	1e4080e7          	jalr	484(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000634e:	854a                	mv	a0,s2
    80006350:	00000097          	auipc	ra,0x0
    80006354:	e6a080e7          	jalr	-406(ra) # 800061ba <isdirempty>
    80006358:	f925                	bnez	a0,800062c8 <sys_unlink+0xa2>
    iunlockput(ip);
    8000635a:	854a                	mv	a0,s2
    8000635c:	ffffe097          	auipc	ra,0xffffe
    80006360:	ea4080e7          	jalr	-348(ra) # 80004200 <iunlockput>

bad:
  iunlockput(dp);
    80006364:	8526                	mv	a0,s1
    80006366:	ffffe097          	auipc	ra,0xffffe
    8000636a:	e9a080e7          	jalr	-358(ra) # 80004200 <iunlockput>
  end_op();
    8000636e:	fffff097          	auipc	ra,0xfffff
    80006372:	998080e7          	jalr	-1640(ra) # 80004d06 <end_op>
  return -1;
    80006376:	557d                	li	a0,-1
}
    80006378:	60ae                	ld	ra,200(sp)
    8000637a:	640e                	ld	s0,192(sp)
    8000637c:	74ea                	ld	s1,184(sp)
    8000637e:	794a                	ld	s2,176(sp)
    80006380:	6169                	addi	sp,sp,208
    80006382:	8082                	ret
    panic("unlink: writei");
    80006384:	00003517          	auipc	a0,0x3
    80006388:	5ac50513          	addi	a0,a0,1452 # 80009930 <syscalls+0x218>
    8000638c:	ffffa097          	auipc	ra,0xffffa
    80006390:	19e080e7          	jalr	414(ra) # 8000052a <panic>
    dp->nlink--;
    80006394:	04a4d783          	lhu	a5,74(s1)
    80006398:	37fd                	addiw	a5,a5,-1
    8000639a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000639e:	8526                	mv	a0,s1
    800063a0:	ffffe097          	auipc	ra,0xffffe
    800063a4:	b34080e7          	jalr	-1228(ra) # 80003ed4 <iupdate>
    800063a8:	bf99                	j	800062fe <sys_unlink+0xd8>
    return -1;
    800063aa:	557d                	li	a0,-1
    800063ac:	b7f1                	j	80006378 <sys_unlink+0x152>

00000000800063ae <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    800063ae:	715d                	addi	sp,sp,-80
    800063b0:	e486                	sd	ra,72(sp)
    800063b2:	e0a2                	sd	s0,64(sp)
    800063b4:	fc26                	sd	s1,56(sp)
    800063b6:	f84a                	sd	s2,48(sp)
    800063b8:	f44e                	sd	s3,40(sp)
    800063ba:	f052                	sd	s4,32(sp)
    800063bc:	ec56                	sd	s5,24(sp)
    800063be:	0880                	addi	s0,sp,80
    800063c0:	89ae                	mv	s3,a1
    800063c2:	8ab2                	mv	s5,a2
    800063c4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800063c6:	fb040593          	addi	a1,s0,-80
    800063ca:	ffffe097          	auipc	ra,0xffffe
    800063ce:	3a8080e7          	jalr	936(ra) # 80004772 <nameiparent>
    800063d2:	892a                	mv	s2,a0
    800063d4:	12050e63          	beqz	a0,80006510 <create+0x162>
    return 0;

  ilock(dp);
    800063d8:	ffffe097          	auipc	ra,0xffffe
    800063dc:	bc6080e7          	jalr	-1082(ra) # 80003f9e <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    800063e0:	4601                	li	a2,0
    800063e2:	fb040593          	addi	a1,s0,-80
    800063e6:	854a                	mv	a0,s2
    800063e8:	ffffe097          	auipc	ra,0xffffe
    800063ec:	09a080e7          	jalr	154(ra) # 80004482 <dirlookup>
    800063f0:	84aa                	mv	s1,a0
    800063f2:	c921                	beqz	a0,80006442 <create+0x94>
    iunlockput(dp);
    800063f4:	854a                	mv	a0,s2
    800063f6:	ffffe097          	auipc	ra,0xffffe
    800063fa:	e0a080e7          	jalr	-502(ra) # 80004200 <iunlockput>
    ilock(ip);
    800063fe:	8526                	mv	a0,s1
    80006400:	ffffe097          	auipc	ra,0xffffe
    80006404:	b9e080e7          	jalr	-1122(ra) # 80003f9e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006408:	2981                	sext.w	s3,s3
    8000640a:	4789                	li	a5,2
    8000640c:	02f99463          	bne	s3,a5,80006434 <create+0x86>
    80006410:	0444d783          	lhu	a5,68(s1)
    80006414:	37f9                	addiw	a5,a5,-2
    80006416:	17c2                	slli	a5,a5,0x30
    80006418:	93c1                	srli	a5,a5,0x30
    8000641a:	4705                	li	a4,1
    8000641c:	00f76c63          	bltu	a4,a5,80006434 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006420:	8526                	mv	a0,s1
    80006422:	60a6                	ld	ra,72(sp)
    80006424:	6406                	ld	s0,64(sp)
    80006426:	74e2                	ld	s1,56(sp)
    80006428:	7942                	ld	s2,48(sp)
    8000642a:	79a2                	ld	s3,40(sp)
    8000642c:	7a02                	ld	s4,32(sp)
    8000642e:	6ae2                	ld	s5,24(sp)
    80006430:	6161                	addi	sp,sp,80
    80006432:	8082                	ret
    iunlockput(ip);
    80006434:	8526                	mv	a0,s1
    80006436:	ffffe097          	auipc	ra,0xffffe
    8000643a:	dca080e7          	jalr	-566(ra) # 80004200 <iunlockput>
    return 0;
    8000643e:	4481                	li	s1,0
    80006440:	b7c5                	j	80006420 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80006442:	85ce                	mv	a1,s3
    80006444:	00092503          	lw	a0,0(s2)
    80006448:	ffffe097          	auipc	ra,0xffffe
    8000644c:	9be080e7          	jalr	-1602(ra) # 80003e06 <ialloc>
    80006450:	84aa                	mv	s1,a0
    80006452:	c521                	beqz	a0,8000649a <create+0xec>
  ilock(ip);
    80006454:	ffffe097          	auipc	ra,0xffffe
    80006458:	b4a080e7          	jalr	-1206(ra) # 80003f9e <ilock>
  ip->major = major;
    8000645c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006460:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006464:	4a05                	li	s4,1
    80006466:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000646a:	8526                	mv	a0,s1
    8000646c:	ffffe097          	auipc	ra,0xffffe
    80006470:	a68080e7          	jalr	-1432(ra) # 80003ed4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006474:	2981                	sext.w	s3,s3
    80006476:	03498a63          	beq	s3,s4,800064aa <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000647a:	40d0                	lw	a2,4(s1)
    8000647c:	fb040593          	addi	a1,s0,-80
    80006480:	854a                	mv	a0,s2
    80006482:	ffffe097          	auipc	ra,0xffffe
    80006486:	210080e7          	jalr	528(ra) # 80004692 <dirlink>
    8000648a:	06054b63          	bltz	a0,80006500 <create+0x152>
  iunlockput(dp);
    8000648e:	854a                	mv	a0,s2
    80006490:	ffffe097          	auipc	ra,0xffffe
    80006494:	d70080e7          	jalr	-656(ra) # 80004200 <iunlockput>
  return ip;
    80006498:	b761                	j	80006420 <create+0x72>
    panic("create: ialloc");
    8000649a:	00003517          	auipc	a0,0x3
    8000649e:	5a650513          	addi	a0,a0,1446 # 80009a40 <syscalls+0x328>
    800064a2:	ffffa097          	auipc	ra,0xffffa
    800064a6:	088080e7          	jalr	136(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800064aa:	04a95783          	lhu	a5,74(s2)
    800064ae:	2785                	addiw	a5,a5,1
    800064b0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800064b4:	854a                	mv	a0,s2
    800064b6:	ffffe097          	auipc	ra,0xffffe
    800064ba:	a1e080e7          	jalr	-1506(ra) # 80003ed4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800064be:	40d0                	lw	a2,4(s1)
    800064c0:	00003597          	auipc	a1,0x3
    800064c4:	44858593          	addi	a1,a1,1096 # 80009908 <syscalls+0x1f0>
    800064c8:	8526                	mv	a0,s1
    800064ca:	ffffe097          	auipc	ra,0xffffe
    800064ce:	1c8080e7          	jalr	456(ra) # 80004692 <dirlink>
    800064d2:	00054f63          	bltz	a0,800064f0 <create+0x142>
    800064d6:	00492603          	lw	a2,4(s2)
    800064da:	00003597          	auipc	a1,0x3
    800064de:	43658593          	addi	a1,a1,1078 # 80009910 <syscalls+0x1f8>
    800064e2:	8526                	mv	a0,s1
    800064e4:	ffffe097          	auipc	ra,0xffffe
    800064e8:	1ae080e7          	jalr	430(ra) # 80004692 <dirlink>
    800064ec:	f80557e3          	bgez	a0,8000647a <create+0xcc>
      panic("create dots");
    800064f0:	00003517          	auipc	a0,0x3
    800064f4:	56050513          	addi	a0,a0,1376 # 80009a50 <syscalls+0x338>
    800064f8:	ffffa097          	auipc	ra,0xffffa
    800064fc:	032080e7          	jalr	50(ra) # 8000052a <panic>
    panic("create: dirlink");
    80006500:	00003517          	auipc	a0,0x3
    80006504:	56050513          	addi	a0,a0,1376 # 80009a60 <syscalls+0x348>
    80006508:	ffffa097          	auipc	ra,0xffffa
    8000650c:	022080e7          	jalr	34(ra) # 8000052a <panic>
    return 0;
    80006510:	84aa                	mv	s1,a0
    80006512:	b739                	j	80006420 <create+0x72>

0000000080006514 <sys_open>:

uint64
sys_open(void)
{
    80006514:	7131                	addi	sp,sp,-192
    80006516:	fd06                	sd	ra,184(sp)
    80006518:	f922                	sd	s0,176(sp)
    8000651a:	f526                	sd	s1,168(sp)
    8000651c:	f14a                	sd	s2,160(sp)
    8000651e:	ed4e                	sd	s3,152(sp)
    80006520:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006522:	08000613          	li	a2,128
    80006526:	f5040593          	addi	a1,s0,-176
    8000652a:	4501                	li	a0,0
    8000652c:	ffffd097          	auipc	ra,0xffffd
    80006530:	f44080e7          	jalr	-188(ra) # 80003470 <argstr>
    return -1;
    80006534:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006536:	0c054163          	bltz	a0,800065f8 <sys_open+0xe4>
    8000653a:	f4c40593          	addi	a1,s0,-180
    8000653e:	4505                	li	a0,1
    80006540:	ffffd097          	auipc	ra,0xffffd
    80006544:	eec080e7          	jalr	-276(ra) # 8000342c <argint>
    80006548:	0a054863          	bltz	a0,800065f8 <sys_open+0xe4>

  begin_op();
    8000654c:	ffffe097          	auipc	ra,0xffffe
    80006550:	73a080e7          	jalr	1850(ra) # 80004c86 <begin_op>

  if(omode & O_CREATE){
    80006554:	f4c42783          	lw	a5,-180(s0)
    80006558:	2007f793          	andi	a5,a5,512
    8000655c:	cbdd                	beqz	a5,80006612 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000655e:	4681                	li	a3,0
    80006560:	4601                	li	a2,0
    80006562:	4589                	li	a1,2
    80006564:	f5040513          	addi	a0,s0,-176
    80006568:	00000097          	auipc	ra,0x0
    8000656c:	e46080e7          	jalr	-442(ra) # 800063ae <create>
    80006570:	892a                	mv	s2,a0
    if(ip == 0){
    80006572:	c959                	beqz	a0,80006608 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006574:	04491703          	lh	a4,68(s2)
    80006578:	478d                	li	a5,3
    8000657a:	00f71763          	bne	a4,a5,80006588 <sys_open+0x74>
    8000657e:	04695703          	lhu	a4,70(s2)
    80006582:	47a5                	li	a5,9
    80006584:	0ce7ec63          	bltu	a5,a4,8000665c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006588:	fffff097          	auipc	ra,0xfffff
    8000658c:	b0e080e7          	jalr	-1266(ra) # 80005096 <filealloc>
    80006590:	89aa                	mv	s3,a0
    80006592:	10050263          	beqz	a0,80006696 <sys_open+0x182>
    80006596:	00000097          	auipc	ra,0x0
    8000659a:	8e2080e7          	jalr	-1822(ra) # 80005e78 <fdalloc>
    8000659e:	84aa                	mv	s1,a0
    800065a0:	0e054663          	bltz	a0,8000668c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800065a4:	04491703          	lh	a4,68(s2)
    800065a8:	478d                	li	a5,3
    800065aa:	0cf70463          	beq	a4,a5,80006672 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800065ae:	4789                	li	a5,2
    800065b0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800065b4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800065b8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800065bc:	f4c42783          	lw	a5,-180(s0)
    800065c0:	0017c713          	xori	a4,a5,1
    800065c4:	8b05                	andi	a4,a4,1
    800065c6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800065ca:	0037f713          	andi	a4,a5,3
    800065ce:	00e03733          	snez	a4,a4
    800065d2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800065d6:	4007f793          	andi	a5,a5,1024
    800065da:	c791                	beqz	a5,800065e6 <sys_open+0xd2>
    800065dc:	04491703          	lh	a4,68(s2)
    800065e0:	4789                	li	a5,2
    800065e2:	08f70f63          	beq	a4,a5,80006680 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800065e6:	854a                	mv	a0,s2
    800065e8:	ffffe097          	auipc	ra,0xffffe
    800065ec:	a78080e7          	jalr	-1416(ra) # 80004060 <iunlock>
  end_op();
    800065f0:	ffffe097          	auipc	ra,0xffffe
    800065f4:	716080e7          	jalr	1814(ra) # 80004d06 <end_op>

  return fd;
}
    800065f8:	8526                	mv	a0,s1
    800065fa:	70ea                	ld	ra,184(sp)
    800065fc:	744a                	ld	s0,176(sp)
    800065fe:	74aa                	ld	s1,168(sp)
    80006600:	790a                	ld	s2,160(sp)
    80006602:	69ea                	ld	s3,152(sp)
    80006604:	6129                	addi	sp,sp,192
    80006606:	8082                	ret
      end_op();
    80006608:	ffffe097          	auipc	ra,0xffffe
    8000660c:	6fe080e7          	jalr	1790(ra) # 80004d06 <end_op>
      return -1;
    80006610:	b7e5                	j	800065f8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006612:	f5040513          	addi	a0,s0,-176
    80006616:	ffffe097          	auipc	ra,0xffffe
    8000661a:	13e080e7          	jalr	318(ra) # 80004754 <namei>
    8000661e:	892a                	mv	s2,a0
    80006620:	c905                	beqz	a0,80006650 <sys_open+0x13c>
    ilock(ip);
    80006622:	ffffe097          	auipc	ra,0xffffe
    80006626:	97c080e7          	jalr	-1668(ra) # 80003f9e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000662a:	04491703          	lh	a4,68(s2)
    8000662e:	4785                	li	a5,1
    80006630:	f4f712e3          	bne	a4,a5,80006574 <sys_open+0x60>
    80006634:	f4c42783          	lw	a5,-180(s0)
    80006638:	dba1                	beqz	a5,80006588 <sys_open+0x74>
      iunlockput(ip);
    8000663a:	854a                	mv	a0,s2
    8000663c:	ffffe097          	auipc	ra,0xffffe
    80006640:	bc4080e7          	jalr	-1084(ra) # 80004200 <iunlockput>
      end_op();
    80006644:	ffffe097          	auipc	ra,0xffffe
    80006648:	6c2080e7          	jalr	1730(ra) # 80004d06 <end_op>
      return -1;
    8000664c:	54fd                	li	s1,-1
    8000664e:	b76d                	j	800065f8 <sys_open+0xe4>
      end_op();
    80006650:	ffffe097          	auipc	ra,0xffffe
    80006654:	6b6080e7          	jalr	1718(ra) # 80004d06 <end_op>
      return -1;
    80006658:	54fd                	li	s1,-1
    8000665a:	bf79                	j	800065f8 <sys_open+0xe4>
    iunlockput(ip);
    8000665c:	854a                	mv	a0,s2
    8000665e:	ffffe097          	auipc	ra,0xffffe
    80006662:	ba2080e7          	jalr	-1118(ra) # 80004200 <iunlockput>
    end_op();
    80006666:	ffffe097          	auipc	ra,0xffffe
    8000666a:	6a0080e7          	jalr	1696(ra) # 80004d06 <end_op>
    return -1;
    8000666e:	54fd                	li	s1,-1
    80006670:	b761                	j	800065f8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006672:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006676:	04691783          	lh	a5,70(s2)
    8000667a:	02f99223          	sh	a5,36(s3)
    8000667e:	bf2d                	j	800065b8 <sys_open+0xa4>
    itrunc(ip);
    80006680:	854a                	mv	a0,s2
    80006682:	ffffe097          	auipc	ra,0xffffe
    80006686:	a2a080e7          	jalr	-1494(ra) # 800040ac <itrunc>
    8000668a:	bfb1                	j	800065e6 <sys_open+0xd2>
      fileclose(f);
    8000668c:	854e                	mv	a0,s3
    8000668e:	fffff097          	auipc	ra,0xfffff
    80006692:	ac4080e7          	jalr	-1340(ra) # 80005152 <fileclose>
    iunlockput(ip);
    80006696:	854a                	mv	a0,s2
    80006698:	ffffe097          	auipc	ra,0xffffe
    8000669c:	b68080e7          	jalr	-1176(ra) # 80004200 <iunlockput>
    end_op();
    800066a0:	ffffe097          	auipc	ra,0xffffe
    800066a4:	666080e7          	jalr	1638(ra) # 80004d06 <end_op>
    return -1;
    800066a8:	54fd                	li	s1,-1
    800066aa:	b7b9                	j	800065f8 <sys_open+0xe4>

00000000800066ac <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800066ac:	7175                	addi	sp,sp,-144
    800066ae:	e506                	sd	ra,136(sp)
    800066b0:	e122                	sd	s0,128(sp)
    800066b2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800066b4:	ffffe097          	auipc	ra,0xffffe
    800066b8:	5d2080e7          	jalr	1490(ra) # 80004c86 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800066bc:	08000613          	li	a2,128
    800066c0:	f7040593          	addi	a1,s0,-144
    800066c4:	4501                	li	a0,0
    800066c6:	ffffd097          	auipc	ra,0xffffd
    800066ca:	daa080e7          	jalr	-598(ra) # 80003470 <argstr>
    800066ce:	02054963          	bltz	a0,80006700 <sys_mkdir+0x54>
    800066d2:	4681                	li	a3,0
    800066d4:	4601                	li	a2,0
    800066d6:	4585                	li	a1,1
    800066d8:	f7040513          	addi	a0,s0,-144
    800066dc:	00000097          	auipc	ra,0x0
    800066e0:	cd2080e7          	jalr	-814(ra) # 800063ae <create>
    800066e4:	cd11                	beqz	a0,80006700 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066e6:	ffffe097          	auipc	ra,0xffffe
    800066ea:	b1a080e7          	jalr	-1254(ra) # 80004200 <iunlockput>
  end_op();
    800066ee:	ffffe097          	auipc	ra,0xffffe
    800066f2:	618080e7          	jalr	1560(ra) # 80004d06 <end_op>
  return 0;
    800066f6:	4501                	li	a0,0
}
    800066f8:	60aa                	ld	ra,136(sp)
    800066fa:	640a                	ld	s0,128(sp)
    800066fc:	6149                	addi	sp,sp,144
    800066fe:	8082                	ret
    end_op();
    80006700:	ffffe097          	auipc	ra,0xffffe
    80006704:	606080e7          	jalr	1542(ra) # 80004d06 <end_op>
    return -1;
    80006708:	557d                	li	a0,-1
    8000670a:	b7fd                	j	800066f8 <sys_mkdir+0x4c>

000000008000670c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000670c:	7135                	addi	sp,sp,-160
    8000670e:	ed06                	sd	ra,152(sp)
    80006710:	e922                	sd	s0,144(sp)
    80006712:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006714:	ffffe097          	auipc	ra,0xffffe
    80006718:	572080e7          	jalr	1394(ra) # 80004c86 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000671c:	08000613          	li	a2,128
    80006720:	f7040593          	addi	a1,s0,-144
    80006724:	4501                	li	a0,0
    80006726:	ffffd097          	auipc	ra,0xffffd
    8000672a:	d4a080e7          	jalr	-694(ra) # 80003470 <argstr>
    8000672e:	04054a63          	bltz	a0,80006782 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006732:	f6c40593          	addi	a1,s0,-148
    80006736:	4505                	li	a0,1
    80006738:	ffffd097          	auipc	ra,0xffffd
    8000673c:	cf4080e7          	jalr	-780(ra) # 8000342c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006740:	04054163          	bltz	a0,80006782 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006744:	f6840593          	addi	a1,s0,-152
    80006748:	4509                	li	a0,2
    8000674a:	ffffd097          	auipc	ra,0xffffd
    8000674e:	ce2080e7          	jalr	-798(ra) # 8000342c <argint>
     argint(1, &major) < 0 ||
    80006752:	02054863          	bltz	a0,80006782 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006756:	f6841683          	lh	a3,-152(s0)
    8000675a:	f6c41603          	lh	a2,-148(s0)
    8000675e:	458d                	li	a1,3
    80006760:	f7040513          	addi	a0,s0,-144
    80006764:	00000097          	auipc	ra,0x0
    80006768:	c4a080e7          	jalr	-950(ra) # 800063ae <create>
     argint(2, &minor) < 0 ||
    8000676c:	c919                	beqz	a0,80006782 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000676e:	ffffe097          	auipc	ra,0xffffe
    80006772:	a92080e7          	jalr	-1390(ra) # 80004200 <iunlockput>
  end_op();
    80006776:	ffffe097          	auipc	ra,0xffffe
    8000677a:	590080e7          	jalr	1424(ra) # 80004d06 <end_op>
  return 0;
    8000677e:	4501                	li	a0,0
    80006780:	a031                	j	8000678c <sys_mknod+0x80>
    end_op();
    80006782:	ffffe097          	auipc	ra,0xffffe
    80006786:	584080e7          	jalr	1412(ra) # 80004d06 <end_op>
    return -1;
    8000678a:	557d                	li	a0,-1
}
    8000678c:	60ea                	ld	ra,152(sp)
    8000678e:	644a                	ld	s0,144(sp)
    80006790:	610d                	addi	sp,sp,160
    80006792:	8082                	ret

0000000080006794 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006794:	7135                	addi	sp,sp,-160
    80006796:	ed06                	sd	ra,152(sp)
    80006798:	e922                	sd	s0,144(sp)
    8000679a:	e526                	sd	s1,136(sp)
    8000679c:	e14a                	sd	s2,128(sp)
    8000679e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800067a0:	ffffb097          	auipc	ra,0xffffb
    800067a4:	234080e7          	jalr	564(ra) # 800019d4 <myproc>
    800067a8:	892a                	mv	s2,a0
  
  begin_op();
    800067aa:	ffffe097          	auipc	ra,0xffffe
    800067ae:	4dc080e7          	jalr	1244(ra) # 80004c86 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800067b2:	08000613          	li	a2,128
    800067b6:	f6040593          	addi	a1,s0,-160
    800067ba:	4501                	li	a0,0
    800067bc:	ffffd097          	auipc	ra,0xffffd
    800067c0:	cb4080e7          	jalr	-844(ra) # 80003470 <argstr>
    800067c4:	04054b63          	bltz	a0,8000681a <sys_chdir+0x86>
    800067c8:	f6040513          	addi	a0,s0,-160
    800067cc:	ffffe097          	auipc	ra,0xffffe
    800067d0:	f88080e7          	jalr	-120(ra) # 80004754 <namei>
    800067d4:	84aa                	mv	s1,a0
    800067d6:	c131                	beqz	a0,8000681a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800067d8:	ffffd097          	auipc	ra,0xffffd
    800067dc:	7c6080e7          	jalr	1990(ra) # 80003f9e <ilock>
  if(ip->type != T_DIR){
    800067e0:	04449703          	lh	a4,68(s1)
    800067e4:	4785                	li	a5,1
    800067e6:	04f71063          	bne	a4,a5,80006826 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800067ea:	8526                	mv	a0,s1
    800067ec:	ffffe097          	auipc	ra,0xffffe
    800067f0:	874080e7          	jalr	-1932(ra) # 80004060 <iunlock>
  iput(p->cwd);
    800067f4:	15093503          	ld	a0,336(s2)
    800067f8:	ffffe097          	auipc	ra,0xffffe
    800067fc:	960080e7          	jalr	-1696(ra) # 80004158 <iput>
  end_op();
    80006800:	ffffe097          	auipc	ra,0xffffe
    80006804:	506080e7          	jalr	1286(ra) # 80004d06 <end_op>
  p->cwd = ip;
    80006808:	14993823          	sd	s1,336(s2)
  return 0;
    8000680c:	4501                	li	a0,0
}
    8000680e:	60ea                	ld	ra,152(sp)
    80006810:	644a                	ld	s0,144(sp)
    80006812:	64aa                	ld	s1,136(sp)
    80006814:	690a                	ld	s2,128(sp)
    80006816:	610d                	addi	sp,sp,160
    80006818:	8082                	ret
    end_op();
    8000681a:	ffffe097          	auipc	ra,0xffffe
    8000681e:	4ec080e7          	jalr	1260(ra) # 80004d06 <end_op>
    return -1;
    80006822:	557d                	li	a0,-1
    80006824:	b7ed                	j	8000680e <sys_chdir+0x7a>
    iunlockput(ip);
    80006826:	8526                	mv	a0,s1
    80006828:	ffffe097          	auipc	ra,0xffffe
    8000682c:	9d8080e7          	jalr	-1576(ra) # 80004200 <iunlockput>
    end_op();
    80006830:	ffffe097          	auipc	ra,0xffffe
    80006834:	4d6080e7          	jalr	1238(ra) # 80004d06 <end_op>
    return -1;
    80006838:	557d                	li	a0,-1
    8000683a:	bfd1                	j	8000680e <sys_chdir+0x7a>

000000008000683c <sys_exec>:

uint64
sys_exec(void)
{
    8000683c:	7145                	addi	sp,sp,-464
    8000683e:	e786                	sd	ra,456(sp)
    80006840:	e3a2                	sd	s0,448(sp)
    80006842:	ff26                	sd	s1,440(sp)
    80006844:	fb4a                	sd	s2,432(sp)
    80006846:	f74e                	sd	s3,424(sp)
    80006848:	f352                	sd	s4,416(sp)
    8000684a:	ef56                	sd	s5,408(sp)
    8000684c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000684e:	08000613          	li	a2,128
    80006852:	f4040593          	addi	a1,s0,-192
    80006856:	4501                	li	a0,0
    80006858:	ffffd097          	auipc	ra,0xffffd
    8000685c:	c18080e7          	jalr	-1000(ra) # 80003470 <argstr>
    return -1;
    80006860:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006862:	0c054a63          	bltz	a0,80006936 <sys_exec+0xfa>
    80006866:	e3840593          	addi	a1,s0,-456
    8000686a:	4505                	li	a0,1
    8000686c:	ffffd097          	auipc	ra,0xffffd
    80006870:	be2080e7          	jalr	-1054(ra) # 8000344e <argaddr>
    80006874:	0c054163          	bltz	a0,80006936 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006878:	10000613          	li	a2,256
    8000687c:	4581                	li	a1,0
    8000687e:	e4040513          	addi	a0,s0,-448
    80006882:	ffffa097          	auipc	ra,0xffffa
    80006886:	43c080e7          	jalr	1084(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000688a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000688e:	89a6                	mv	s3,s1
    80006890:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006892:	02000a13          	li	s4,32
    80006896:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000689a:	00391793          	slli	a5,s2,0x3
    8000689e:	e3040593          	addi	a1,s0,-464
    800068a2:	e3843503          	ld	a0,-456(s0)
    800068a6:	953e                	add	a0,a0,a5
    800068a8:	ffffd097          	auipc	ra,0xffffd
    800068ac:	aea080e7          	jalr	-1302(ra) # 80003392 <fetchaddr>
    800068b0:	02054a63          	bltz	a0,800068e4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800068b4:	e3043783          	ld	a5,-464(s0)
    800068b8:	c3b9                	beqz	a5,800068fe <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800068ba:	ffffa097          	auipc	ra,0xffffa
    800068be:	218080e7          	jalr	536(ra) # 80000ad2 <kalloc>
    800068c2:	85aa                	mv	a1,a0
    800068c4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800068c8:	cd11                	beqz	a0,800068e4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800068ca:	6605                	lui	a2,0x1
    800068cc:	e3043503          	ld	a0,-464(s0)
    800068d0:	ffffd097          	auipc	ra,0xffffd
    800068d4:	b14080e7          	jalr	-1260(ra) # 800033e4 <fetchstr>
    800068d8:	00054663          	bltz	a0,800068e4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800068dc:	0905                	addi	s2,s2,1
    800068de:	09a1                	addi	s3,s3,8
    800068e0:	fb491be3          	bne	s2,s4,80006896 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068e4:	10048913          	addi	s2,s1,256
    800068e8:	6088                	ld	a0,0(s1)
    800068ea:	c529                	beqz	a0,80006934 <sys_exec+0xf8>
    kfree(argv[i]);
    800068ec:	ffffa097          	auipc	ra,0xffffa
    800068f0:	0ea080e7          	jalr	234(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068f4:	04a1                	addi	s1,s1,8
    800068f6:	ff2499e3          	bne	s1,s2,800068e8 <sys_exec+0xac>
  return -1;
    800068fa:	597d                	li	s2,-1
    800068fc:	a82d                	j	80006936 <sys_exec+0xfa>
      argv[i] = 0;
    800068fe:	0a8e                	slli	s5,s5,0x3
    80006900:	fc040793          	addi	a5,s0,-64
    80006904:	9abe                	add	s5,s5,a5
    80006906:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000690a:	e4040593          	addi	a1,s0,-448
    8000690e:	f4040513          	addi	a0,s0,-192
    80006912:	fffff097          	auipc	ra,0xfffff
    80006916:	088080e7          	jalr	136(ra) # 8000599a <exec>
    8000691a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000691c:	10048993          	addi	s3,s1,256
    80006920:	6088                	ld	a0,0(s1)
    80006922:	c911                	beqz	a0,80006936 <sys_exec+0xfa>
    kfree(argv[i]);
    80006924:	ffffa097          	auipc	ra,0xffffa
    80006928:	0b2080e7          	jalr	178(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000692c:	04a1                	addi	s1,s1,8
    8000692e:	ff3499e3          	bne	s1,s3,80006920 <sys_exec+0xe4>
    80006932:	a011                	j	80006936 <sys_exec+0xfa>
  return -1;
    80006934:	597d                	li	s2,-1
}
    80006936:	854a                	mv	a0,s2
    80006938:	60be                	ld	ra,456(sp)
    8000693a:	641e                	ld	s0,448(sp)
    8000693c:	74fa                	ld	s1,440(sp)
    8000693e:	795a                	ld	s2,432(sp)
    80006940:	79ba                	ld	s3,424(sp)
    80006942:	7a1a                	ld	s4,416(sp)
    80006944:	6afa                	ld	s5,408(sp)
    80006946:	6179                	addi	sp,sp,464
    80006948:	8082                	ret

000000008000694a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000694a:	7139                	addi	sp,sp,-64
    8000694c:	fc06                	sd	ra,56(sp)
    8000694e:	f822                	sd	s0,48(sp)
    80006950:	f426                	sd	s1,40(sp)
    80006952:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006954:	ffffb097          	auipc	ra,0xffffb
    80006958:	080080e7          	jalr	128(ra) # 800019d4 <myproc>
    8000695c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000695e:	fd840593          	addi	a1,s0,-40
    80006962:	4501                	li	a0,0
    80006964:	ffffd097          	auipc	ra,0xffffd
    80006968:	aea080e7          	jalr	-1302(ra) # 8000344e <argaddr>
    return -1;
    8000696c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000696e:	0e054063          	bltz	a0,80006a4e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006972:	fc840593          	addi	a1,s0,-56
    80006976:	fd040513          	addi	a0,s0,-48
    8000697a:	fffff097          	auipc	ra,0xfffff
    8000697e:	cfe080e7          	jalr	-770(ra) # 80005678 <pipealloc>
    return -1;
    80006982:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006984:	0c054563          	bltz	a0,80006a4e <sys_pipe+0x104>
  fd0 = -1;
    80006988:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000698c:	fd043503          	ld	a0,-48(s0)
    80006990:	fffff097          	auipc	ra,0xfffff
    80006994:	4e8080e7          	jalr	1256(ra) # 80005e78 <fdalloc>
    80006998:	fca42223          	sw	a0,-60(s0)
    8000699c:	08054c63          	bltz	a0,80006a34 <sys_pipe+0xea>
    800069a0:	fc843503          	ld	a0,-56(s0)
    800069a4:	fffff097          	auipc	ra,0xfffff
    800069a8:	4d4080e7          	jalr	1236(ra) # 80005e78 <fdalloc>
    800069ac:	fca42023          	sw	a0,-64(s0)
    800069b0:	06054863          	bltz	a0,80006a20 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800069b4:	4691                	li	a3,4
    800069b6:	fc440613          	addi	a2,s0,-60
    800069ba:	fd843583          	ld	a1,-40(s0)
    800069be:	68a8                	ld	a0,80(s1)
    800069c0:	ffffb097          	auipc	ra,0xffffb
    800069c4:	cd4080e7          	jalr	-812(ra) # 80001694 <copyout>
    800069c8:	02054063          	bltz	a0,800069e8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800069cc:	4691                	li	a3,4
    800069ce:	fc040613          	addi	a2,s0,-64
    800069d2:	fd843583          	ld	a1,-40(s0)
    800069d6:	0591                	addi	a1,a1,4
    800069d8:	68a8                	ld	a0,80(s1)
    800069da:	ffffb097          	auipc	ra,0xffffb
    800069de:	cba080e7          	jalr	-838(ra) # 80001694 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800069e2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800069e4:	06055563          	bgez	a0,80006a4e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800069e8:	fc442783          	lw	a5,-60(s0)
    800069ec:	07e9                	addi	a5,a5,26
    800069ee:	078e                	slli	a5,a5,0x3
    800069f0:	97a6                	add	a5,a5,s1
    800069f2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800069f6:	fc042503          	lw	a0,-64(s0)
    800069fa:	0569                	addi	a0,a0,26
    800069fc:	050e                	slli	a0,a0,0x3
    800069fe:	9526                	add	a0,a0,s1
    80006a00:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006a04:	fd043503          	ld	a0,-48(s0)
    80006a08:	ffffe097          	auipc	ra,0xffffe
    80006a0c:	74a080e7          	jalr	1866(ra) # 80005152 <fileclose>
    fileclose(wf);
    80006a10:	fc843503          	ld	a0,-56(s0)
    80006a14:	ffffe097          	auipc	ra,0xffffe
    80006a18:	73e080e7          	jalr	1854(ra) # 80005152 <fileclose>
    return -1;
    80006a1c:	57fd                	li	a5,-1
    80006a1e:	a805                	j	80006a4e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006a20:	fc442783          	lw	a5,-60(s0)
    80006a24:	0007c863          	bltz	a5,80006a34 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006a28:	01a78513          	addi	a0,a5,26
    80006a2c:	050e                	slli	a0,a0,0x3
    80006a2e:	9526                	add	a0,a0,s1
    80006a30:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006a34:	fd043503          	ld	a0,-48(s0)
    80006a38:	ffffe097          	auipc	ra,0xffffe
    80006a3c:	71a080e7          	jalr	1818(ra) # 80005152 <fileclose>
    fileclose(wf);
    80006a40:	fc843503          	ld	a0,-56(s0)
    80006a44:	ffffe097          	auipc	ra,0xffffe
    80006a48:	70e080e7          	jalr	1806(ra) # 80005152 <fileclose>
    return -1;
    80006a4c:	57fd                	li	a5,-1
}
    80006a4e:	853e                	mv	a0,a5
    80006a50:	70e2                	ld	ra,56(sp)
    80006a52:	7442                	ld	s0,48(sp)
    80006a54:	74a2                	ld	s1,40(sp)
    80006a56:	6121                	addi	sp,sp,64
    80006a58:	8082                	ret
    80006a5a:	0000                	unimp
    80006a5c:	0000                	unimp
	...

0000000080006a60 <kernelvec>:
    80006a60:	7111                	addi	sp,sp,-256
    80006a62:	e006                	sd	ra,0(sp)
    80006a64:	e40a                	sd	sp,8(sp)
    80006a66:	e80e                	sd	gp,16(sp)
    80006a68:	ec12                	sd	tp,24(sp)
    80006a6a:	f016                	sd	t0,32(sp)
    80006a6c:	f41a                	sd	t1,40(sp)
    80006a6e:	f81e                	sd	t2,48(sp)
    80006a70:	fc22                	sd	s0,56(sp)
    80006a72:	e0a6                	sd	s1,64(sp)
    80006a74:	e4aa                	sd	a0,72(sp)
    80006a76:	e8ae                	sd	a1,80(sp)
    80006a78:	ecb2                	sd	a2,88(sp)
    80006a7a:	f0b6                	sd	a3,96(sp)
    80006a7c:	f4ba                	sd	a4,104(sp)
    80006a7e:	f8be                	sd	a5,112(sp)
    80006a80:	fcc2                	sd	a6,120(sp)
    80006a82:	e146                	sd	a7,128(sp)
    80006a84:	e54a                	sd	s2,136(sp)
    80006a86:	e94e                	sd	s3,144(sp)
    80006a88:	ed52                	sd	s4,152(sp)
    80006a8a:	f156                	sd	s5,160(sp)
    80006a8c:	f55a                	sd	s6,168(sp)
    80006a8e:	f95e                	sd	s7,176(sp)
    80006a90:	fd62                	sd	s8,184(sp)
    80006a92:	e1e6                	sd	s9,192(sp)
    80006a94:	e5ea                	sd	s10,200(sp)
    80006a96:	e9ee                	sd	s11,208(sp)
    80006a98:	edf2                	sd	t3,216(sp)
    80006a9a:	f1f6                	sd	t4,224(sp)
    80006a9c:	f5fa                	sd	t5,232(sp)
    80006a9e:	f9fe                	sd	t6,240(sp)
    80006aa0:	fbefc0ef          	jal	ra,8000325e <kerneltrap>
    80006aa4:	6082                	ld	ra,0(sp)
    80006aa6:	6122                	ld	sp,8(sp)
    80006aa8:	61c2                	ld	gp,16(sp)
    80006aaa:	7282                	ld	t0,32(sp)
    80006aac:	7322                	ld	t1,40(sp)
    80006aae:	73c2                	ld	t2,48(sp)
    80006ab0:	7462                	ld	s0,56(sp)
    80006ab2:	6486                	ld	s1,64(sp)
    80006ab4:	6526                	ld	a0,72(sp)
    80006ab6:	65c6                	ld	a1,80(sp)
    80006ab8:	6666                	ld	a2,88(sp)
    80006aba:	7686                	ld	a3,96(sp)
    80006abc:	7726                	ld	a4,104(sp)
    80006abe:	77c6                	ld	a5,112(sp)
    80006ac0:	7866                	ld	a6,120(sp)
    80006ac2:	688a                	ld	a7,128(sp)
    80006ac4:	692a                	ld	s2,136(sp)
    80006ac6:	69ca                	ld	s3,144(sp)
    80006ac8:	6a6a                	ld	s4,152(sp)
    80006aca:	7a8a                	ld	s5,160(sp)
    80006acc:	7b2a                	ld	s6,168(sp)
    80006ace:	7bca                	ld	s7,176(sp)
    80006ad0:	7c6a                	ld	s8,184(sp)
    80006ad2:	6c8e                	ld	s9,192(sp)
    80006ad4:	6d2e                	ld	s10,200(sp)
    80006ad6:	6dce                	ld	s11,208(sp)
    80006ad8:	6e6e                	ld	t3,216(sp)
    80006ada:	7e8e                	ld	t4,224(sp)
    80006adc:	7f2e                	ld	t5,232(sp)
    80006ade:	7fce                	ld	t6,240(sp)
    80006ae0:	6111                	addi	sp,sp,256
    80006ae2:	10200073          	sret
    80006ae6:	00000013          	nop
    80006aea:	00000013          	nop
    80006aee:	0001                	nop

0000000080006af0 <timervec>:
    80006af0:	34051573          	csrrw	a0,mscratch,a0
    80006af4:	e10c                	sd	a1,0(a0)
    80006af6:	e510                	sd	a2,8(a0)
    80006af8:	e914                	sd	a3,16(a0)
    80006afa:	6d0c                	ld	a1,24(a0)
    80006afc:	7110                	ld	a2,32(a0)
    80006afe:	6194                	ld	a3,0(a1)
    80006b00:	96b2                	add	a3,a3,a2
    80006b02:	e194                	sd	a3,0(a1)
    80006b04:	4589                	li	a1,2
    80006b06:	14459073          	csrw	sip,a1
    80006b0a:	6914                	ld	a3,16(a0)
    80006b0c:	6510                	ld	a2,8(a0)
    80006b0e:	610c                	ld	a1,0(a0)
    80006b10:	34051573          	csrrw	a0,mscratch,a0
    80006b14:	30200073          	mret
	...

0000000080006b1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006b1a:	1141                	addi	sp,sp,-16
    80006b1c:	e422                	sd	s0,8(sp)
    80006b1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006b20:	0c0007b7          	lui	a5,0xc000
    80006b24:	4705                	li	a4,1
    80006b26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006b28:	c3d8                	sw	a4,4(a5)
}
    80006b2a:	6422                	ld	s0,8(sp)
    80006b2c:	0141                	addi	sp,sp,16
    80006b2e:	8082                	ret

0000000080006b30 <plicinithart>:

void
plicinithart(void)
{
    80006b30:	1141                	addi	sp,sp,-16
    80006b32:	e406                	sd	ra,8(sp)
    80006b34:	e022                	sd	s0,0(sp)
    80006b36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b38:	ffffb097          	auipc	ra,0xffffb
    80006b3c:	e70080e7          	jalr	-400(ra) # 800019a8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006b40:	0085171b          	slliw	a4,a0,0x8
    80006b44:	0c0027b7          	lui	a5,0xc002
    80006b48:	97ba                	add	a5,a5,a4
    80006b4a:	40200713          	li	a4,1026
    80006b4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006b52:	00d5151b          	slliw	a0,a0,0xd
    80006b56:	0c2017b7          	lui	a5,0xc201
    80006b5a:	953e                	add	a0,a0,a5
    80006b5c:	00052023          	sw	zero,0(a0)
}
    80006b60:	60a2                	ld	ra,8(sp)
    80006b62:	6402                	ld	s0,0(sp)
    80006b64:	0141                	addi	sp,sp,16
    80006b66:	8082                	ret

0000000080006b68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006b68:	1141                	addi	sp,sp,-16
    80006b6a:	e406                	sd	ra,8(sp)
    80006b6c:	e022                	sd	s0,0(sp)
    80006b6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b70:	ffffb097          	auipc	ra,0xffffb
    80006b74:	e38080e7          	jalr	-456(ra) # 800019a8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006b78:	00d5179b          	slliw	a5,a0,0xd
    80006b7c:	0c201537          	lui	a0,0xc201
    80006b80:	953e                	add	a0,a0,a5
  return irq;
}
    80006b82:	4148                	lw	a0,4(a0)
    80006b84:	60a2                	ld	ra,8(sp)
    80006b86:	6402                	ld	s0,0(sp)
    80006b88:	0141                	addi	sp,sp,16
    80006b8a:	8082                	ret

0000000080006b8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006b8c:	1101                	addi	sp,sp,-32
    80006b8e:	ec06                	sd	ra,24(sp)
    80006b90:	e822                	sd	s0,16(sp)
    80006b92:	e426                	sd	s1,8(sp)
    80006b94:	1000                	addi	s0,sp,32
    80006b96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006b98:	ffffb097          	auipc	ra,0xffffb
    80006b9c:	e10080e7          	jalr	-496(ra) # 800019a8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006ba0:	00d5151b          	slliw	a0,a0,0xd
    80006ba4:	0c2017b7          	lui	a5,0xc201
    80006ba8:	97aa                	add	a5,a5,a0
    80006baa:	c3c4                	sw	s1,4(a5)
}
    80006bac:	60e2                	ld	ra,24(sp)
    80006bae:	6442                	ld	s0,16(sp)
    80006bb0:	64a2                	ld	s1,8(sp)
    80006bb2:	6105                	addi	sp,sp,32
    80006bb4:	8082                	ret

0000000080006bb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006bb6:	1141                	addi	sp,sp,-16
    80006bb8:	e406                	sd	ra,8(sp)
    80006bba:	e022                	sd	s0,0(sp)
    80006bbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006bbe:	479d                	li	a5,7
    80006bc0:	06a7c963          	blt	a5,a0,80006c32 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006bc4:	00025797          	auipc	a5,0x25
    80006bc8:	43c78793          	addi	a5,a5,1084 # 8002c000 <disk>
    80006bcc:	00a78733          	add	a4,a5,a0
    80006bd0:	6789                	lui	a5,0x2
    80006bd2:	97ba                	add	a5,a5,a4
    80006bd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006bd8:	e7ad                	bnez	a5,80006c42 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006bda:	00451793          	slli	a5,a0,0x4
    80006bde:	00027717          	auipc	a4,0x27
    80006be2:	42270713          	addi	a4,a4,1058 # 8002e000 <disk+0x2000>
    80006be6:	6314                	ld	a3,0(a4)
    80006be8:	96be                	add	a3,a3,a5
    80006bea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006bee:	6314                	ld	a3,0(a4)
    80006bf0:	96be                	add	a3,a3,a5
    80006bf2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006bf6:	6314                	ld	a3,0(a4)
    80006bf8:	96be                	add	a3,a3,a5
    80006bfa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006bfe:	6318                	ld	a4,0(a4)
    80006c00:	97ba                	add	a5,a5,a4
    80006c02:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006c06:	00025797          	auipc	a5,0x25
    80006c0a:	3fa78793          	addi	a5,a5,1018 # 8002c000 <disk>
    80006c0e:	97aa                	add	a5,a5,a0
    80006c10:	6509                	lui	a0,0x2
    80006c12:	953e                	add	a0,a0,a5
    80006c14:	4785                	li	a5,1
    80006c16:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006c1a:	00027517          	auipc	a0,0x27
    80006c1e:	3fe50513          	addi	a0,a0,1022 # 8002e018 <disk+0x2018>
    80006c22:	ffffb097          	auipc	ra,0xffffb
    80006c26:	438080e7          	jalr	1080(ra) # 8000205a <wakeup>
}
    80006c2a:	60a2                	ld	ra,8(sp)
    80006c2c:	6402                	ld	s0,0(sp)
    80006c2e:	0141                	addi	sp,sp,16
    80006c30:	8082                	ret
    panic("free_desc 1");
    80006c32:	00003517          	auipc	a0,0x3
    80006c36:	e3e50513          	addi	a0,a0,-450 # 80009a70 <syscalls+0x358>
    80006c3a:	ffffa097          	auipc	ra,0xffffa
    80006c3e:	8f0080e7          	jalr	-1808(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006c42:	00003517          	auipc	a0,0x3
    80006c46:	e3e50513          	addi	a0,a0,-450 # 80009a80 <syscalls+0x368>
    80006c4a:	ffffa097          	auipc	ra,0xffffa
    80006c4e:	8e0080e7          	jalr	-1824(ra) # 8000052a <panic>

0000000080006c52 <virtio_disk_init>:
{
    80006c52:	1101                	addi	sp,sp,-32
    80006c54:	ec06                	sd	ra,24(sp)
    80006c56:	e822                	sd	s0,16(sp)
    80006c58:	e426                	sd	s1,8(sp)
    80006c5a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006c5c:	00003597          	auipc	a1,0x3
    80006c60:	e3458593          	addi	a1,a1,-460 # 80009a90 <syscalls+0x378>
    80006c64:	00027517          	auipc	a0,0x27
    80006c68:	4c450513          	addi	a0,a0,1220 # 8002e128 <disk+0x2128>
    80006c6c:	ffffa097          	auipc	ra,0xffffa
    80006c70:	ec6080e7          	jalr	-314(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c74:	100017b7          	lui	a5,0x10001
    80006c78:	4398                	lw	a4,0(a5)
    80006c7a:	2701                	sext.w	a4,a4
    80006c7c:	747277b7          	lui	a5,0x74727
    80006c80:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006c84:	0ef71163          	bne	a4,a5,80006d66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c88:	100017b7          	lui	a5,0x10001
    80006c8c:	43dc                	lw	a5,4(a5)
    80006c8e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c90:	4705                	li	a4,1
    80006c92:	0ce79a63          	bne	a5,a4,80006d66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c96:	100017b7          	lui	a5,0x10001
    80006c9a:	479c                	lw	a5,8(a5)
    80006c9c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c9e:	4709                	li	a4,2
    80006ca0:	0ce79363          	bne	a5,a4,80006d66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006ca4:	100017b7          	lui	a5,0x10001
    80006ca8:	47d8                	lw	a4,12(a5)
    80006caa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006cac:	554d47b7          	lui	a5,0x554d4
    80006cb0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006cb4:	0af71963          	bne	a4,a5,80006d66 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cb8:	100017b7          	lui	a5,0x10001
    80006cbc:	4705                	li	a4,1
    80006cbe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cc0:	470d                	li	a4,3
    80006cc2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006cc4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006cc6:	c7ffe737          	lui	a4,0xc7ffe
    80006cca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf75f>
    80006cce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006cd0:	2701                	sext.w	a4,a4
    80006cd2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cd4:	472d                	li	a4,11
    80006cd6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cd8:	473d                	li	a4,15
    80006cda:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006cdc:	6705                	lui	a4,0x1
    80006cde:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006ce0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006ce4:	5bdc                	lw	a5,52(a5)
    80006ce6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006ce8:	c7d9                	beqz	a5,80006d76 <virtio_disk_init+0x124>
  if(max < NUM)
    80006cea:	471d                	li	a4,7
    80006cec:	08f77d63          	bgeu	a4,a5,80006d86 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006cf0:	100014b7          	lui	s1,0x10001
    80006cf4:	47a1                	li	a5,8
    80006cf6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006cf8:	6609                	lui	a2,0x2
    80006cfa:	4581                	li	a1,0
    80006cfc:	00025517          	auipc	a0,0x25
    80006d00:	30450513          	addi	a0,a0,772 # 8002c000 <disk>
    80006d04:	ffffa097          	auipc	ra,0xffffa
    80006d08:	fba080e7          	jalr	-70(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006d0c:	00025717          	auipc	a4,0x25
    80006d10:	2f470713          	addi	a4,a4,756 # 8002c000 <disk>
    80006d14:	00c75793          	srli	a5,a4,0xc
    80006d18:	2781                	sext.w	a5,a5
    80006d1a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006d1c:	00027797          	auipc	a5,0x27
    80006d20:	2e478793          	addi	a5,a5,740 # 8002e000 <disk+0x2000>
    80006d24:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006d26:	00025717          	auipc	a4,0x25
    80006d2a:	35a70713          	addi	a4,a4,858 # 8002c080 <disk+0x80>
    80006d2e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006d30:	00026717          	auipc	a4,0x26
    80006d34:	2d070713          	addi	a4,a4,720 # 8002d000 <disk+0x1000>
    80006d38:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006d3a:	4705                	li	a4,1
    80006d3c:	00e78c23          	sb	a4,24(a5)
    80006d40:	00e78ca3          	sb	a4,25(a5)
    80006d44:	00e78d23          	sb	a4,26(a5)
    80006d48:	00e78da3          	sb	a4,27(a5)
    80006d4c:	00e78e23          	sb	a4,28(a5)
    80006d50:	00e78ea3          	sb	a4,29(a5)
    80006d54:	00e78f23          	sb	a4,30(a5)
    80006d58:	00e78fa3          	sb	a4,31(a5)
}
    80006d5c:	60e2                	ld	ra,24(sp)
    80006d5e:	6442                	ld	s0,16(sp)
    80006d60:	64a2                	ld	s1,8(sp)
    80006d62:	6105                	addi	sp,sp,32
    80006d64:	8082                	ret
    panic("could not find virtio disk");
    80006d66:	00003517          	auipc	a0,0x3
    80006d6a:	d3a50513          	addi	a0,a0,-710 # 80009aa0 <syscalls+0x388>
    80006d6e:	ffff9097          	auipc	ra,0xffff9
    80006d72:	7bc080e7          	jalr	1980(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006d76:	00003517          	auipc	a0,0x3
    80006d7a:	d4a50513          	addi	a0,a0,-694 # 80009ac0 <syscalls+0x3a8>
    80006d7e:	ffff9097          	auipc	ra,0xffff9
    80006d82:	7ac080e7          	jalr	1964(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006d86:	00003517          	auipc	a0,0x3
    80006d8a:	d5a50513          	addi	a0,a0,-678 # 80009ae0 <syscalls+0x3c8>
    80006d8e:	ffff9097          	auipc	ra,0xffff9
    80006d92:	79c080e7          	jalr	1948(ra) # 8000052a <panic>

0000000080006d96 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006d96:	7119                	addi	sp,sp,-128
    80006d98:	fc86                	sd	ra,120(sp)
    80006d9a:	f8a2                	sd	s0,112(sp)
    80006d9c:	f4a6                	sd	s1,104(sp)
    80006d9e:	f0ca                	sd	s2,96(sp)
    80006da0:	ecce                	sd	s3,88(sp)
    80006da2:	e8d2                	sd	s4,80(sp)
    80006da4:	e4d6                	sd	s5,72(sp)
    80006da6:	e0da                	sd	s6,64(sp)
    80006da8:	fc5e                	sd	s7,56(sp)
    80006daa:	f862                	sd	s8,48(sp)
    80006dac:	f466                	sd	s9,40(sp)
    80006dae:	f06a                	sd	s10,32(sp)
    80006db0:	ec6e                	sd	s11,24(sp)
    80006db2:	0100                	addi	s0,sp,128
    80006db4:	8aaa                	mv	s5,a0
    80006db6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006db8:	00c52c83          	lw	s9,12(a0)
    80006dbc:	001c9c9b          	slliw	s9,s9,0x1
    80006dc0:	1c82                	slli	s9,s9,0x20
    80006dc2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006dc6:	00027517          	auipc	a0,0x27
    80006dca:	36250513          	addi	a0,a0,866 # 8002e128 <disk+0x2128>
    80006dce:	ffffa097          	auipc	ra,0xffffa
    80006dd2:	df4080e7          	jalr	-524(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006dd6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006dd8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006dda:	00025c17          	auipc	s8,0x25
    80006dde:	226c0c13          	addi	s8,s8,550 # 8002c000 <disk>
    80006de2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006de4:	4b0d                	li	s6,3
    80006de6:	a0ad                	j	80006e50 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006de8:	00fc0733          	add	a4,s8,a5
    80006dec:	975e                	add	a4,a4,s7
    80006dee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006df2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006df4:	0207c563          	bltz	a5,80006e1e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006df8:	2905                	addiw	s2,s2,1
    80006dfa:	0611                	addi	a2,a2,4
    80006dfc:	19690d63          	beq	s2,s6,80006f96 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006e00:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006e02:	00027717          	auipc	a4,0x27
    80006e06:	21670713          	addi	a4,a4,534 # 8002e018 <disk+0x2018>
    80006e0a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006e0c:	00074683          	lbu	a3,0(a4)
    80006e10:	fee1                	bnez	a3,80006de8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006e12:	2785                	addiw	a5,a5,1
    80006e14:	0705                	addi	a4,a4,1
    80006e16:	fe979be3          	bne	a5,s1,80006e0c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006e1a:	57fd                	li	a5,-1
    80006e1c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006e1e:	01205d63          	blez	s2,80006e38 <virtio_disk_rw+0xa2>
    80006e22:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006e24:	000a2503          	lw	a0,0(s4)
    80006e28:	00000097          	auipc	ra,0x0
    80006e2c:	d8e080e7          	jalr	-626(ra) # 80006bb6 <free_desc>
      for(int j = 0; j < i; j++)
    80006e30:	2d85                	addiw	s11,s11,1
    80006e32:	0a11                	addi	s4,s4,4
    80006e34:	ffb918e3          	bne	s2,s11,80006e24 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006e38:	00027597          	auipc	a1,0x27
    80006e3c:	2f058593          	addi	a1,a1,752 # 8002e128 <disk+0x2128>
    80006e40:	00027517          	auipc	a0,0x27
    80006e44:	1d850513          	addi	a0,a0,472 # 8002e018 <disk+0x2018>
    80006e48:	ffffb097          	auipc	ra,0xffffb
    80006e4c:	1ae080e7          	jalr	430(ra) # 80001ff6 <sleep>
  for(int i = 0; i < 3; i++){
    80006e50:	f8040a13          	addi	s4,s0,-128
{
    80006e54:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006e56:	894e                	mv	s2,s3
    80006e58:	b765                	j	80006e00 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006e5a:	00027697          	auipc	a3,0x27
    80006e5e:	1a66b683          	ld	a3,422(a3) # 8002e000 <disk+0x2000>
    80006e62:	96ba                	add	a3,a3,a4
    80006e64:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006e68:	00025817          	auipc	a6,0x25
    80006e6c:	19880813          	addi	a6,a6,408 # 8002c000 <disk>
    80006e70:	00027697          	auipc	a3,0x27
    80006e74:	19068693          	addi	a3,a3,400 # 8002e000 <disk+0x2000>
    80006e78:	6290                	ld	a2,0(a3)
    80006e7a:	963a                	add	a2,a2,a4
    80006e7c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006e80:	0015e593          	ori	a1,a1,1
    80006e84:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006e88:	f8842603          	lw	a2,-120(s0)
    80006e8c:	628c                	ld	a1,0(a3)
    80006e8e:	972e                	add	a4,a4,a1
    80006e90:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006e94:	20050593          	addi	a1,a0,512
    80006e98:	0592                	slli	a1,a1,0x4
    80006e9a:	95c2                	add	a1,a1,a6
    80006e9c:	577d                	li	a4,-1
    80006e9e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006ea2:	00461713          	slli	a4,a2,0x4
    80006ea6:	6290                	ld	a2,0(a3)
    80006ea8:	963a                	add	a2,a2,a4
    80006eaa:	03078793          	addi	a5,a5,48
    80006eae:	97c2                	add	a5,a5,a6
    80006eb0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006eb2:	629c                	ld	a5,0(a3)
    80006eb4:	97ba                	add	a5,a5,a4
    80006eb6:	4605                	li	a2,1
    80006eb8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006eba:	629c                	ld	a5,0(a3)
    80006ebc:	97ba                	add	a5,a5,a4
    80006ebe:	4809                	li	a6,2
    80006ec0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006ec4:	629c                	ld	a5,0(a3)
    80006ec6:	973e                	add	a4,a4,a5
    80006ec8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ecc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006ed0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ed4:	6698                	ld	a4,8(a3)
    80006ed6:	00275783          	lhu	a5,2(a4)
    80006eda:	8b9d                	andi	a5,a5,7
    80006edc:	0786                	slli	a5,a5,0x1
    80006ede:	97ba                	add	a5,a5,a4
    80006ee0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006ee4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006ee8:	6698                	ld	a4,8(a3)
    80006eea:	00275783          	lhu	a5,2(a4)
    80006eee:	2785                	addiw	a5,a5,1
    80006ef0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ef4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ef8:	100017b7          	lui	a5,0x10001
    80006efc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006f00:	004aa783          	lw	a5,4(s5)
    80006f04:	02c79163          	bne	a5,a2,80006f26 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006f08:	00027917          	auipc	s2,0x27
    80006f0c:	22090913          	addi	s2,s2,544 # 8002e128 <disk+0x2128>
  while(b->disk == 1) {
    80006f10:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006f12:	85ca                	mv	a1,s2
    80006f14:	8556                	mv	a0,s5
    80006f16:	ffffb097          	auipc	ra,0xffffb
    80006f1a:	0e0080e7          	jalr	224(ra) # 80001ff6 <sleep>
  while(b->disk == 1) {
    80006f1e:	004aa783          	lw	a5,4(s5)
    80006f22:	fe9788e3          	beq	a5,s1,80006f12 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006f26:	f8042903          	lw	s2,-128(s0)
    80006f2a:	20090793          	addi	a5,s2,512
    80006f2e:	00479713          	slli	a4,a5,0x4
    80006f32:	00025797          	auipc	a5,0x25
    80006f36:	0ce78793          	addi	a5,a5,206 # 8002c000 <disk>
    80006f3a:	97ba                	add	a5,a5,a4
    80006f3c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006f40:	00027997          	auipc	s3,0x27
    80006f44:	0c098993          	addi	s3,s3,192 # 8002e000 <disk+0x2000>
    80006f48:	00491713          	slli	a4,s2,0x4
    80006f4c:	0009b783          	ld	a5,0(s3)
    80006f50:	97ba                	add	a5,a5,a4
    80006f52:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006f56:	854a                	mv	a0,s2
    80006f58:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006f5c:	00000097          	auipc	ra,0x0
    80006f60:	c5a080e7          	jalr	-934(ra) # 80006bb6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006f64:	8885                	andi	s1,s1,1
    80006f66:	f0ed                	bnez	s1,80006f48 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006f68:	00027517          	auipc	a0,0x27
    80006f6c:	1c050513          	addi	a0,a0,448 # 8002e128 <disk+0x2128>
    80006f70:	ffffa097          	auipc	ra,0xffffa
    80006f74:	d06080e7          	jalr	-762(ra) # 80000c76 <release>
}
    80006f78:	70e6                	ld	ra,120(sp)
    80006f7a:	7446                	ld	s0,112(sp)
    80006f7c:	74a6                	ld	s1,104(sp)
    80006f7e:	7906                	ld	s2,96(sp)
    80006f80:	69e6                	ld	s3,88(sp)
    80006f82:	6a46                	ld	s4,80(sp)
    80006f84:	6aa6                	ld	s5,72(sp)
    80006f86:	6b06                	ld	s6,64(sp)
    80006f88:	7be2                	ld	s7,56(sp)
    80006f8a:	7c42                	ld	s8,48(sp)
    80006f8c:	7ca2                	ld	s9,40(sp)
    80006f8e:	7d02                	ld	s10,32(sp)
    80006f90:	6de2                	ld	s11,24(sp)
    80006f92:	6109                	addi	sp,sp,128
    80006f94:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f96:	f8042503          	lw	a0,-128(s0)
    80006f9a:	20050793          	addi	a5,a0,512
    80006f9e:	0792                	slli	a5,a5,0x4
  if(write)
    80006fa0:	00025817          	auipc	a6,0x25
    80006fa4:	06080813          	addi	a6,a6,96 # 8002c000 <disk>
    80006fa8:	00f80733          	add	a4,a6,a5
    80006fac:	01a036b3          	snez	a3,s10
    80006fb0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006fb4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006fb8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fbc:	7679                	lui	a2,0xffffe
    80006fbe:	963e                	add	a2,a2,a5
    80006fc0:	00027697          	auipc	a3,0x27
    80006fc4:	04068693          	addi	a3,a3,64 # 8002e000 <disk+0x2000>
    80006fc8:	6298                	ld	a4,0(a3)
    80006fca:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006fcc:	0a878593          	addi	a1,a5,168
    80006fd0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fd2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006fd4:	6298                	ld	a4,0(a3)
    80006fd6:	9732                	add	a4,a4,a2
    80006fd8:	45c1                	li	a1,16
    80006fda:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006fdc:	6298                	ld	a4,0(a3)
    80006fde:	9732                	add	a4,a4,a2
    80006fe0:	4585                	li	a1,1
    80006fe2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006fe6:	f8442703          	lw	a4,-124(s0)
    80006fea:	628c                	ld	a1,0(a3)
    80006fec:	962e                	add	a2,a2,a1
    80006fee:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcf00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ff2:	0712                	slli	a4,a4,0x4
    80006ff4:	6290                	ld	a2,0(a3)
    80006ff6:	963a                	add	a2,a2,a4
    80006ff8:	058a8593          	addi	a1,s5,88
    80006ffc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006ffe:	6294                	ld	a3,0(a3)
    80007000:	96ba                	add	a3,a3,a4
    80007002:	40000613          	li	a2,1024
    80007006:	c690                	sw	a2,8(a3)
  if(write)
    80007008:	e40d19e3          	bnez	s10,80006e5a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000700c:	00027697          	auipc	a3,0x27
    80007010:	ff46b683          	ld	a3,-12(a3) # 8002e000 <disk+0x2000>
    80007014:	96ba                	add	a3,a3,a4
    80007016:	4609                	li	a2,2
    80007018:	00c69623          	sh	a2,12(a3)
    8000701c:	b5b1                	j	80006e68 <virtio_disk_rw+0xd2>

000000008000701e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000701e:	1101                	addi	sp,sp,-32
    80007020:	ec06                	sd	ra,24(sp)
    80007022:	e822                	sd	s0,16(sp)
    80007024:	e426                	sd	s1,8(sp)
    80007026:	e04a                	sd	s2,0(sp)
    80007028:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000702a:	00027517          	auipc	a0,0x27
    8000702e:	0fe50513          	addi	a0,a0,254 # 8002e128 <disk+0x2128>
    80007032:	ffffa097          	auipc	ra,0xffffa
    80007036:	b90080e7          	jalr	-1136(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000703a:	10001737          	lui	a4,0x10001
    8000703e:	533c                	lw	a5,96(a4)
    80007040:	8b8d                	andi	a5,a5,3
    80007042:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007044:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007048:	00027797          	auipc	a5,0x27
    8000704c:	fb878793          	addi	a5,a5,-72 # 8002e000 <disk+0x2000>
    80007050:	6b94                	ld	a3,16(a5)
    80007052:	0207d703          	lhu	a4,32(a5)
    80007056:	0026d783          	lhu	a5,2(a3)
    8000705a:	06f70163          	beq	a4,a5,800070bc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000705e:	00025917          	auipc	s2,0x25
    80007062:	fa290913          	addi	s2,s2,-94 # 8002c000 <disk>
    80007066:	00027497          	auipc	s1,0x27
    8000706a:	f9a48493          	addi	s1,s1,-102 # 8002e000 <disk+0x2000>
    __sync_synchronize();
    8000706e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007072:	6898                	ld	a4,16(s1)
    80007074:	0204d783          	lhu	a5,32(s1)
    80007078:	8b9d                	andi	a5,a5,7
    8000707a:	078e                	slli	a5,a5,0x3
    8000707c:	97ba                	add	a5,a5,a4
    8000707e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007080:	20078713          	addi	a4,a5,512
    80007084:	0712                	slli	a4,a4,0x4
    80007086:	974a                	add	a4,a4,s2
    80007088:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000708c:	e731                	bnez	a4,800070d8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000708e:	20078793          	addi	a5,a5,512
    80007092:	0792                	slli	a5,a5,0x4
    80007094:	97ca                	add	a5,a5,s2
    80007096:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007098:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000709c:	ffffb097          	auipc	ra,0xffffb
    800070a0:	fbe080e7          	jalr	-66(ra) # 8000205a <wakeup>

    disk.used_idx += 1;
    800070a4:	0204d783          	lhu	a5,32(s1)
    800070a8:	2785                	addiw	a5,a5,1
    800070aa:	17c2                	slli	a5,a5,0x30
    800070ac:	93c1                	srli	a5,a5,0x30
    800070ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800070b2:	6898                	ld	a4,16(s1)
    800070b4:	00275703          	lhu	a4,2(a4)
    800070b8:	faf71be3          	bne	a4,a5,8000706e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800070bc:	00027517          	auipc	a0,0x27
    800070c0:	06c50513          	addi	a0,a0,108 # 8002e128 <disk+0x2128>
    800070c4:	ffffa097          	auipc	ra,0xffffa
    800070c8:	bb2080e7          	jalr	-1102(ra) # 80000c76 <release>
}
    800070cc:	60e2                	ld	ra,24(sp)
    800070ce:	6442                	ld	s0,16(sp)
    800070d0:	64a2                	ld	s1,8(sp)
    800070d2:	6902                	ld	s2,0(sp)
    800070d4:	6105                	addi	sp,sp,32
    800070d6:	8082                	ret
      panic("virtio_disk_intr status");
    800070d8:	00003517          	auipc	a0,0x3
    800070dc:	a2850513          	addi	a0,a0,-1496 # 80009b00 <syscalls+0x3e8>
    800070e0:	ffff9097          	auipc	ra,0xffff9
    800070e4:	44a080e7          	jalr	1098(ra) # 8000052a <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret
	...
