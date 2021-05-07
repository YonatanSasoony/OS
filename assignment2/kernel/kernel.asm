
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
    80000068:	ccc78793          	addi	a5,a5,-820 # 80006d30 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffba7ff>
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
    8000011e:	00003097          	auipc	ra,0x3
    80000122:	8f2080e7          	jalr	-1806(ra) # 80002a10 <either_copyin>
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
    800001b6:	8a4080e7          	jalr	-1884(ra) # 80001a56 <myproc>
    800001ba:	4d5c                	lw	a5,28(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	4f2080e7          	jalr	1266(ra) # 800026b4 <sleep>
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
    80000202:	7ba080e7          	jalr	1978(ra) # 800029b8 <either_copyout>
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
    800002e2:	78a080e7          	jalr	1930(ra) # 80002a68 <procdump>
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
    80000436:	40c080e7          	jalr	1036(ra) # 8000283e <wakeup>
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
    80000464:	00040797          	auipc	a5,0x40
    80000468:	8e478793          	addi	a5,a5,-1820 # 8003fd48 <devsw>
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
    8000055c:	b7850513          	addi	a0,a0,-1160 # 800090d0 <digits+0x90>
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
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	fc0080e7          	jalr	-64(ra) # 8000283e <wakeup>
    
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
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	daa080e7          	jalr	-598(ra) # 800026b4 <sleep>
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
    800009ea:	00043797          	auipc	a5,0x43
    800009ee:	61678793          	addi	a5,a5,1558 # 80044000 <end>
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
    80000aba:	00043517          	auipc	a0,0x43
    80000abe:	54650513          	addi	a0,a0,1350 # 80044000 <end>
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
    80000b60:	ede080e7          	jalr	-290(ra) # 80001a3a <mycpu>
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
    80000b92:	eac080e7          	jalr	-340(ra) # 80001a3a <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	ea0080e7          	jalr	-352(ra) # 80001a3a <mycpu>
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
    80000bb6:	e88080e7          	jalr	-376(ra) # 80001a3a <mycpu>
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
    80000bf6:	e48080e7          	jalr	-440(ra) # 80001a3a <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire\n");
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
    80000c22:	e1c080e7          	jalr	-484(ra) # 80001a3a <mycpu>
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
    80000c5a:	42a50513          	addi	a0,a0,1066 # 80009080 <digits+0x40>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00008517          	auipc	a0,0x8
    80000c6a:	43250513          	addi	a0,a0,1074 # 80009098 <digits+0x58>
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
    80000cb2:	3f250513          	addi	a0,a0,1010 # 800090a0 <digits+0x60>
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
    80000e78:	bb6080e7          	jalr	-1098(ra) # 80001a2a <cpuid>
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
    80000e94:	b9a080e7          	jalr	-1126(ra) # 80001a2a <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00008517          	auipc	a0,0x8
    80000e9e:	22650513          	addi	a0,a0,550 # 800090c0 <digits+0x80>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	5f4080e7          	jalr	1524(ra) # 800034a6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	eb6080e7          	jalr	-330(ra) # 80006d70 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	4aa080e7          	jalr	1194(ra) # 8000236c <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00008517          	auipc	a0,0x8
    80000ede:	1f650513          	addi	a0,a0,502 # 800090d0 <digits+0x90>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00008517          	auipc	a0,0x8
    80000eee:	1be50513          	addi	a0,a0,446 # 800090a8 <digits+0x68>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00008517          	auipc	a0,0x8
    80000efe:	1d650513          	addi	a0,a0,470 # 800090d0 <digits+0x90>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	a18080e7          	jalr	-1512(ra) # 8000193a <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	554080e7          	jalr	1364(ra) # 8000347e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	574080e7          	jalr	1396(ra) # 800034a6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	e20080e7          	jalr	-480(ra) # 80006d5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	e2e080e7          	jalr	-466(ra) # 80006d70 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00003097          	auipc	ra,0x3
    80000f4e:	f60080e7          	jalr	-160(ra) # 80003eaa <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	5f2080e7          	jalr	1522(ra) # 80004544 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	5a0080e7          	jalr	1440(ra) # 800054fa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	f30080e7          	jalr	-208(ra) # 80006e92 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	fd2080e7          	jalr	-46(ra) # 80001f3c <userinit>
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
    80000fd0:	10c50513          	addi	a0,a0,268 # 800090d8 <digits+0x98>
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
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00008517          	auipc	a0,0x8
    800010f4:	ff050513          	addi	a0,a0,-16 # 800090e0 <digits+0xa0>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00008517          	auipc	a0,0x8
    80001140:	fac50513          	addi	a0,a0,-84 # 800090e8 <digits+0xa8>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00008917          	auipc	s2,0x8
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80009000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80008697          	auipc	a3,0x80008
    800011c0:	e4468693          	addi	a3,a3,-444 # 9000 <_entry-0x7fff7000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00007617          	auipc	a2,0x7
    800011f4:	e1060613          	addi	a2,a2,-496 # 80008000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	640080e7          	jalr	1600(ra) # 8000184c <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00009797          	auipc	a5,0x9
    80001236:	dea7b723          	sd	a0,-530(a5) # 8000a020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6b05                	lui	s6,0x1
    8000126e:	0735e263          	bltu	a1,s3,800012d2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00008517          	auipc	a0,0x8
    8000128c:	e6850513          	addi	a0,a0,-408 # 800090f0 <digits+0xb0>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00008517          	auipc	a0,0x8
    8000129c:	e7050513          	addi	a0,a0,-400 # 80009108 <digits+0xc8>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00008517          	auipc	a0,0x8
    800012ac:	e7050513          	addi	a0,a0,-400 # 80009118 <digits+0xd8>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00008517          	auipc	a0,0x8
    800012bc:	e7850513          	addi	a0,a0,-392 # 80009130 <digits+0xf0>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    *pte = 0;
    800012c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	995a                	add	s2,s2,s6
    800012ce:	fb3972e3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d2:	4601                	li	a2,0
    800012d4:	85ca                	mv	a1,s2
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	cce080e7          	jalr	-818(ra) # 80000fa6 <walk>
    800012e0:	84aa                	mv	s1,a0
    800012e2:	d95d                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012e4:	6108                	ld	a0,0(a0)
    800012e6:	00157793          	andi	a5,a0,1
    800012ea:	dfdd                	beqz	a5,800012a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	3ff57793          	andi	a5,a0,1023
    800012f0:	fd7784e3          	beq	a5,s7,800012b8 <uvmunmap+0x76>
    if(do_free){
    800012f4:	fc0a8ae3          	beqz	s5,800012c8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	6da080e7          	jalr	1754(ra) # 800009d6 <kfree>
    80001304:	b7d1                	j	800012c8 <uvmunmap+0x86>

0000000080001306 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	7c2080e7          	jalr	1986(ra) # 80000ad2 <kalloc>
    80001318:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000131a:	c519                	beqz	a0,80001328 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	99e080e7          	jalr	-1634(ra) # 80000cbe <memset>
  return pagetable;
}
    80001328:	8526                	mv	a0,s1
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001334:	7179                	addi	sp,sp,-48
    80001336:	f406                	sd	ra,40(sp)
    80001338:	f022                	sd	s0,32(sp)
    8000133a:	ec26                	sd	s1,24(sp)
    8000133c:	e84a                	sd	s2,16(sp)
    8000133e:	e44e                	sd	s3,8(sp)
    80001340:	e052                	sd	s4,0(sp)
    80001342:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001344:	6785                	lui	a5,0x1
    80001346:	04f67863          	bgeu	a2,a5,80001396 <uvminit+0x62>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	89ae                	mv	s3,a1
    8000134e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	782080e7          	jalr	1922(ra) # 80000ad2 <kalloc>
    80001358:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	960080e7          	jalr	-1696(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001366:	4779                	li	a4,30
    80001368:	86ca                	mv	a3,s2
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	8552                	mv	a0,s4
    80001370:	00000097          	auipc	ra,0x0
    80001374:	d1e080e7          	jalr	-738(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001378:	8626                	mv	a2,s1
    8000137a:	85ce                	mv	a1,s3
    8000137c:	854a                	mv	a0,s2
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	99c080e7          	jalr	-1636(ra) # 80000d1a <memmove>
}
    80001386:	70a2                	ld	ra,40(sp)
    80001388:	7402                	ld	s0,32(sp)
    8000138a:	64e2                	ld	s1,24(sp)
    8000138c:	6942                	ld	s2,16(sp)
    8000138e:	69a2                	ld	s3,8(sp)
    80001390:	6a02                	ld	s4,0(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret
    panic("inituvm: more than a page");
    80001396:	00008517          	auipc	a0,0x8
    8000139a:	db250513          	addi	a0,a0,-590 # 80009148 <digits+0x108>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800013a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a6:	1101                	addi	sp,sp,-32
    800013a8:	ec06                	sd	ra,24(sp)
    800013aa:	e822                	sd	s0,16(sp)
    800013ac:	e426                	sd	s1,8(sp)
    800013ae:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013b2:	00b67d63          	bgeu	a2,a1,800013cc <uvmdealloc+0x26>
    800013b6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b8:	6785                	lui	a5,0x1
    800013ba:	17fd                	addi	a5,a5,-1
    800013bc:	00f60733          	add	a4,a2,a5
    800013c0:	767d                	lui	a2,0xfffff
    800013c2:	8f71                	and	a4,a4,a2
    800013c4:	97ae                	add	a5,a5,a1
    800013c6:	8ff1                	and	a5,a5,a2
    800013c8:	00f76863          	bltu	a4,a5,800013d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d8:	8f99                	sub	a5,a5,a4
    800013da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013dc:	4685                	li	a3,1
    800013de:	0007861b          	sext.w	a2,a5
    800013e2:	85ba                	mv	a1,a4
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	e5e080e7          	jalr	-418(ra) # 80001242 <uvmunmap>
    800013ec:	b7c5                	j	800013cc <uvmdealloc+0x26>

00000000800013ee <uvmalloc>:
  if(newsz < oldsz)
    800013ee:	0ab66163          	bltu	a2,a1,80001490 <uvmalloc+0xa2>
{
    800013f2:	7139                	addi	sp,sp,-64
    800013f4:	fc06                	sd	ra,56(sp)
    800013f6:	f822                	sd	s0,48(sp)
    800013f8:	f426                	sd	s1,40(sp)
    800013fa:	f04a                	sd	s2,32(sp)
    800013fc:	ec4e                	sd	s3,24(sp)
    800013fe:	e852                	sd	s4,16(sp)
    80001400:	e456                	sd	s5,8(sp)
    80001402:	0080                	addi	s0,sp,64
    80001404:	8aaa                	mv	s5,a0
    80001406:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001408:	6985                	lui	s3,0x1
    8000140a:	19fd                	addi	s3,s3,-1
    8000140c:	95ce                	add	a1,a1,s3
    8000140e:	79fd                	lui	s3,0xfffff
    80001410:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001414:	08c9f063          	bgeu	s3,a2,80001494 <uvmalloc+0xa6>
    80001418:	894e                	mv	s2,s3
    mem = kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	6b8080e7          	jalr	1720(ra) # 80000ad2 <kalloc>
    80001422:	84aa                	mv	s1,a0
    if(mem == 0){
    80001424:	c51d                	beqz	a0,80001452 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001426:	6605                	lui	a2,0x1
    80001428:	4581                	li	a1,0
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	894080e7          	jalr	-1900(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001432:	4779                	li	a4,30
    80001434:	86a6                	mv	a3,s1
    80001436:	6605                	lui	a2,0x1
    80001438:	85ca                	mv	a1,s2
    8000143a:	8556                	mv	a0,s5
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	c52080e7          	jalr	-942(ra) # 8000108e <mappages>
    80001444:	e905                	bnez	a0,80001474 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001446:	6785                	lui	a5,0x1
    80001448:	993e                	add	s2,s2,a5
    8000144a:	fd4968e3          	bltu	s2,s4,8000141a <uvmalloc+0x2c>
  return newsz;
    8000144e:	8552                	mv	a0,s4
    80001450:	a809                	j	80001462 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001452:	864e                	mv	a2,s3
    80001454:	85ca                	mv	a1,s2
    80001456:	8556                	mv	a0,s5
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f4e080e7          	jalr	-178(ra) # 800013a6 <uvmdealloc>
      return 0;
    80001460:	4501                	li	a0,0
}
    80001462:	70e2                	ld	ra,56(sp)
    80001464:	7442                	ld	s0,48(sp)
    80001466:	74a2                	ld	s1,40(sp)
    80001468:	7902                	ld	s2,32(sp)
    8000146a:	69e2                	ld	s3,24(sp)
    8000146c:	6a42                	ld	s4,16(sp)
    8000146e:	6aa2                	ld	s5,8(sp)
    80001470:	6121                	addi	sp,sp,64
    80001472:	8082                	ret
      kfree(mem);
    80001474:	8526                	mv	a0,s1
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	560080e7          	jalr	1376(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000147e:	864e                	mv	a2,s3
    80001480:	85ca                	mv	a1,s2
    80001482:	8556                	mv	a0,s5
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f22080e7          	jalr	-222(ra) # 800013a6 <uvmdealloc>
      return 0;
    8000148c:	4501                	li	a0,0
    8000148e:	bfd1                	j	80001462 <uvmalloc+0x74>
    return oldsz;
    80001490:	852e                	mv	a0,a1
}
    80001492:	8082                	ret
  return newsz;
    80001494:	8532                	mv	a0,a2
    80001496:	b7f1                	j	80001462 <uvmalloc+0x74>

0000000080001498 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
    800014a8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014aa:	84aa                	mv	s1,a0
    800014ac:	6905                	lui	s2,0x1
    800014ae:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014b0:	4985                	li	s3,1
    800014b2:	a821                	j	800014ca <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b6:	0532                	slli	a0,a0,0xc
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	fe0080e7          	jalr	-32(ra) # 80001498 <freewalk>
      pagetable[i] = 0;
    800014c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014c4:	04a1                	addi	s1,s1,8
    800014c6:	03248163          	beq	s1,s2,800014e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014cc:	00f57793          	andi	a5,a0,15
    800014d0:	ff3782e3          	beq	a5,s3,800014b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014d4:	8905                	andi	a0,a0,1
    800014d6:	d57d                	beqz	a0,800014c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014d8:	00008517          	auipc	a0,0x8
    800014dc:	c9050513          	addi	a0,a0,-880 # 80009168 <digits+0x128>
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014e8:	8552                	mv	a0,s4
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	4ec080e7          	jalr	1260(ra) # 800009d6 <kfree>
}
    800014f2:	70a2                	ld	ra,40(sp)
    800014f4:	7402                	ld	s0,32(sp)
    800014f6:	64e2                	ld	s1,24(sp)
    800014f8:	6942                	ld	s2,16(sp)
    800014fa:	69a2                	ld	s3,8(sp)
    800014fc:	6a02                	ld	s4,0(sp)
    800014fe:	6145                	addi	sp,sp,48
    80001500:	8082                	ret

0000000080001502 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001502:	1101                	addi	sp,sp,-32
    80001504:	ec06                	sd	ra,24(sp)
    80001506:	e822                	sd	s0,16(sp)
    80001508:	e426                	sd	s1,8(sp)
    8000150a:	1000                	addi	s0,sp,32
    8000150c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000150e:	e999                	bnez	a1,80001524 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001510:	8526                	mv	a0,s1
    80001512:	00000097          	auipc	ra,0x0
    80001516:	f86080e7          	jalr	-122(ra) # 80001498 <freewalk>
}
    8000151a:	60e2                	ld	ra,24(sp)
    8000151c:	6442                	ld	s0,16(sp)
    8000151e:	64a2                	ld	s1,8(sp)
    80001520:	6105                	addi	sp,sp,32
    80001522:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001524:	6605                	lui	a2,0x1
    80001526:	167d                	addi	a2,a2,-1
    80001528:	962e                	add	a2,a2,a1
    8000152a:	4685                	li	a3,1
    8000152c:	8231                	srli	a2,a2,0xc
    8000152e:	4581                	li	a1,0
    80001530:	00000097          	auipc	ra,0x0
    80001534:	d12080e7          	jalr	-750(ra) # 80001242 <uvmunmap>
    80001538:	bfe1                	j	80001510 <uvmfree+0xe>

000000008000153a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000153a:	c679                	beqz	a2,80001608 <uvmcopy+0xce>
{
    8000153c:	715d                	addi	sp,sp,-80
    8000153e:	e486                	sd	ra,72(sp)
    80001540:	e0a2                	sd	s0,64(sp)
    80001542:	fc26                	sd	s1,56(sp)
    80001544:	f84a                	sd	s2,48(sp)
    80001546:	f44e                	sd	s3,40(sp)
    80001548:	f052                	sd	s4,32(sp)
    8000154a:	ec56                	sd	s5,24(sp)
    8000154c:	e85a                	sd	s6,16(sp)
    8000154e:	e45e                	sd	s7,8(sp)
    80001550:	0880                	addi	s0,sp,80
    80001552:	8b2a                	mv	s6,a0
    80001554:	8aae                	mv	s5,a1
    80001556:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001558:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000155a:	4601                	li	a2,0
    8000155c:	85ce                	mv	a1,s3
    8000155e:	855a                	mv	a0,s6
    80001560:	00000097          	auipc	ra,0x0
    80001564:	a46080e7          	jalr	-1466(ra) # 80000fa6 <walk>
    80001568:	c531                	beqz	a0,800015b4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000156a:	6118                	ld	a4,0(a0)
    8000156c:	00177793          	andi	a5,a4,1
    80001570:	cbb1                	beqz	a5,800015c4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001572:	00a75593          	srli	a1,a4,0xa
    80001576:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000157a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	554080e7          	jalr	1364(ra) # 80000ad2 <kalloc>
    80001586:	892a                	mv	s2,a0
    80001588:	c939                	beqz	a0,800015de <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	85de                	mv	a1,s7
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	78c080e7          	jalr	1932(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001596:	8726                	mv	a4,s1
    80001598:	86ca                	mv	a3,s2
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85ce                	mv	a1,s3
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	aee080e7          	jalr	-1298(ra) # 8000108e <mappages>
    800015a8:	e515                	bnez	a0,800015d4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	6785                	lui	a5,0x1
    800015ac:	99be                	add	s3,s3,a5
    800015ae:	fb49e6e3          	bltu	s3,s4,8000155a <uvmcopy+0x20>
    800015b2:	a081                	j	800015f2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015b4:	00008517          	auipc	a0,0x8
    800015b8:	bc450513          	addi	a0,a0,-1084 # 80009178 <digits+0x138>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015c4:	00008517          	auipc	a0,0x8
    800015c8:	bd450513          	addi	a0,a0,-1068 # 80009198 <digits+0x158>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
      kfree(mem);
    800015d4:	854a                	mv	a0,s2
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	400080e7          	jalr	1024(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015de:	4685                	li	a3,1
    800015e0:	00c9d613          	srli	a2,s3,0xc
    800015e4:	4581                	li	a1,0
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	c5a080e7          	jalr	-934(ra) # 80001242 <uvmunmap>
  return -1;
    800015f0:	557d                	li	a0,-1
}
    800015f2:	60a6                	ld	ra,72(sp)
    800015f4:	6406                	ld	s0,64(sp)
    800015f6:	74e2                	ld	s1,56(sp)
    800015f8:	7942                	ld	s2,48(sp)
    800015fa:	79a2                	ld	s3,40(sp)
    800015fc:	7a02                	ld	s4,32(sp)
    800015fe:	6ae2                	ld	s5,24(sp)
    80001600:	6b42                	ld	s6,16(sp)
    80001602:	6ba2                	ld	s7,8(sp)
    80001604:	6161                	addi	sp,sp,80
    80001606:	8082                	ret
  return 0;
    80001608:	4501                	li	a0,0
}
    8000160a:	8082                	ret

000000008000160c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160c:	1141                	addi	sp,sp,-16
    8000160e:	e406                	sd	ra,8(sp)
    80001610:	e022                	sd	s0,0(sp)
    80001612:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001614:	4601                	li	a2,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	990080e7          	jalr	-1648(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000161e:	c901                	beqz	a0,8000162e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001620:	611c                	ld	a5,0(a0)
    80001622:	9bbd                	andi	a5,a5,-17
    80001624:	e11c                	sd	a5,0(a0)
}
    80001626:	60a2                	ld	ra,8(sp)
    80001628:	6402                	ld	s0,0(sp)
    8000162a:	0141                	addi	sp,sp,16
    8000162c:	8082                	ret
    panic("uvmclear");
    8000162e:	00008517          	auipc	a0,0x8
    80001632:	b8a50513          	addi	a0,a0,-1142 # 800091b8 <digits+0x178>
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	ef4080e7          	jalr	-268(ra) # 8000052a <panic>

000000008000163e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163e:	c6bd                	beqz	a3,800016ac <copyout+0x6e>
{
    80001640:	715d                	addi	sp,sp,-80
    80001642:	e486                	sd	ra,72(sp)
    80001644:	e0a2                	sd	s0,64(sp)
    80001646:	fc26                	sd	s1,56(sp)
    80001648:	f84a                	sd	s2,48(sp)
    8000164a:	f44e                	sd	s3,40(sp)
    8000164c:	f052                	sd	s4,32(sp)
    8000164e:	ec56                	sd	s5,24(sp)
    80001650:	e85a                	sd	s6,16(sp)
    80001652:	e45e                	sd	s7,8(sp)
    80001654:	e062                	sd	s8,0(sp)
    80001656:	0880                	addi	s0,sp,80
    80001658:	8b2a                	mv	s6,a0
    8000165a:	8c2e                	mv	s8,a1
    8000165c:	8a32                	mv	s4,a2
    8000165e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001660:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001662:	6a85                	lui	s5,0x1
    80001664:	a015                	j	80001688 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001666:	9562                	add	a0,a0,s8
    80001668:	0004861b          	sext.w	a2,s1
    8000166c:	85d2                	mv	a1,s4
    8000166e:	41250533          	sub	a0,a0,s2
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	6a8080e7          	jalr	1704(ra) # 80000d1a <memmove>

    len -= n;
    8000167a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001680:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001684:	02098263          	beqz	s3,800016a8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001688:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168c:	85ca                	mv	a1,s2
    8000168e:	855a                	mv	a0,s6
    80001690:	00000097          	auipc	ra,0x0
    80001694:	9bc080e7          	jalr	-1604(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001698:	cd01                	beqz	a0,800016b0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000169a:	418904b3          	sub	s1,s2,s8
    8000169e:	94d6                	add	s1,s1,s5
    if(n > len)
    800016a0:	fc99f3e3          	bgeu	s3,s1,80001666 <copyout+0x28>
    800016a4:	84ce                	mv	s1,s3
    800016a6:	b7c1                	j	80001666 <copyout+0x28>
  }
  return 0;
    800016a8:	4501                	li	a0,0
    800016aa:	a021                	j	800016b2 <copyout+0x74>
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret
      return -1;
    800016b0:	557d                	li	a0,-1
}
    800016b2:	60a6                	ld	ra,72(sp)
    800016b4:	6406                	ld	s0,64(sp)
    800016b6:	74e2                	ld	s1,56(sp)
    800016b8:	7942                	ld	s2,48(sp)
    800016ba:	79a2                	ld	s3,40(sp)
    800016bc:	7a02                	ld	s4,32(sp)
    800016be:	6ae2                	ld	s5,24(sp)
    800016c0:	6b42                	ld	s6,16(sp)
    800016c2:	6ba2                	ld	s7,8(sp)
    800016c4:	6c02                	ld	s8,0(sp)
    800016c6:	6161                	addi	sp,sp,80
    800016c8:	8082                	ret

00000000800016ca <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	caa5                	beqz	a3,8000173a <copyin+0x70>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8a2e                	mv	s4,a1
    800016e8:	8c32                	mv	s8,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a01d                	j	80001716 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f2:	018505b3          	add	a1,a0,s8
    800016f6:	0004861b          	sext.w	a2,s1
    800016fa:	412585b3          	sub	a1,a1,s2
    800016fe:	8552                	mv	a0,s4
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	61a080e7          	jalr	1562(ra) # 80000d1a <memmove>

    len -= n;
    80001708:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000170c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001712:	02098263          	beqz	s3,80001736 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001716:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000171a:	85ca                	mv	a1,s2
    8000171c:	855a                	mv	a0,s6
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	92e080e7          	jalr	-1746(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001726:	cd01                	beqz	a0,8000173e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001728:	418904b3          	sub	s1,s2,s8
    8000172c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172e:	fc99f2e3          	bgeu	s3,s1,800016f2 <copyin+0x28>
    80001732:	84ce                	mv	s1,s3
    80001734:	bf7d                	j	800016f2 <copyin+0x28>
  }
  return 0;
    80001736:	4501                	li	a0,0
    80001738:	a021                	j	80001740 <copyin+0x76>
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret
      return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	60a6                	ld	ra,72(sp)
    80001742:	6406                	ld	s0,64(sp)
    80001744:	74e2                	ld	s1,56(sp)
    80001746:	7942                	ld	s2,48(sp)
    80001748:	79a2                	ld	s3,40(sp)
    8000174a:	7a02                	ld	s4,32(sp)
    8000174c:	6ae2                	ld	s5,24(sp)
    8000174e:	6b42                	ld	s6,16(sp)
    80001750:	6ba2                	ld	s7,8(sp)
    80001752:	6c02                	ld	s8,0(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret

0000000080001758 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001758:	c6c5                	beqz	a3,80001800 <copyinstr+0xa8>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8a2a                	mv	s4,a0
    80001772:	8b2e                	mv	s6,a1
    80001774:	8bb2                	mv	s7,a2
    80001776:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6985                	lui	s3,0x1
    8000177c:	a035                	j	800017a8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001782:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001784:	0017b793          	seqz	a5,a5
    80001788:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6161                	addi	sp,sp,80
    800017a0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017a2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a6:	c8a9                	beqz	s1,800017f8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	8552                	mv	a0,s4
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	89c080e7          	jalr	-1892(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017b8:	c131                	beqz	a0,800017fc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ba:	41790833          	sub	a6,s2,s7
    800017be:	984e                	add	a6,a6,s3
    if(n > max)
    800017c0:	0104f363          	bgeu	s1,a6,800017c6 <copyinstr+0x6e>
    800017c4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c6:	955e                	add	a0,a0,s7
    800017c8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017cc:	fc080be3          	beqz	a6,800017a2 <copyinstr+0x4a>
    800017d0:	985a                	add	a6,a6,s6
    800017d2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d4:	41650633          	sub	a2,a0,s6
    800017d8:	14fd                	addi	s1,s1,-1
    800017da:	9b26                	add	s6,s6,s1
    800017dc:	00f60733          	add	a4,a2,a5
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbb000>
    800017e4:	df49                	beqz	a4,8000177e <copyinstr+0x26>
        *dst = *p;
    800017e6:	00e78023          	sb	a4,0(a5)
      --max;
    800017ea:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ee:	0785                	addi	a5,a5,1
    while(n > 0){
    800017f0:	ff0796e3          	bne	a5,a6,800017dc <copyinstr+0x84>
      dst++;
    800017f4:	8b42                	mv	s6,a6
    800017f6:	b775                	j	800017a2 <copyinstr+0x4a>
    800017f8:	4781                	li	a5,0
    800017fa:	b769                	j	80001784 <copyinstr+0x2c>
      return -1;
    800017fc:	557d                	li	a0,-1
    800017fe:	b779                	j	8000178c <copyinstr+0x34>
  int got_null = 0;
    80001800:	4781                	li	a5,0
  if(got_null){
    80001802:	0017b793          	seqz	a5,a5
    80001806:	40f00533          	neg	a0,a5
}
    8000180a:	8082                	ret

000000008000180c <freethread>:
}

// ADDED Q3
static void
freethread(struct thread *t)
{
    8000180c:	1101                	addi	sp,sp,-32
    8000180e:	ec06                	sd	ra,24(sp)
    80001810:	e822                	sd	s0,16(sp)
    80001812:	e426                	sd	s1,8(sp)
    80001814:	1000                	addi	s0,sp,32
    80001816:	84aa                	mv	s1,a0
    if (t->kstack)
    80001818:	6128                	ld	a0,64(a0)
    8000181a:	e505                	bnez	a0,80001842 <freethread+0x36>
      kfree((void *)t->kstack);
    t->kstack = 0;
    8000181c:	0404b023          	sd	zero,64(s1)
    t->trapframe = 0;
    80001820:	0404b423          	sd	zero,72(s1)
    t->tid = 0;
    80001824:	0204a823          	sw	zero,48(s1)
    t->proc = 0;
    80001828:	0204bc23          	sd	zero,56(s1)
    t->chan = 0;
    8000182c:	0204b023          	sd	zero,32(s1)
    t->terminated = 0;
    80001830:	0204a423          	sw	zero,40(s1)
    t->state = UNUSED_T;
    80001834:	0004ac23          	sw	zero,24(s1)
}
    80001838:	60e2                	ld	ra,24(sp)
    8000183a:	6442                	ld	s0,16(sp)
    8000183c:	64a2                	ld	s1,8(sp)
    8000183e:	6105                	addi	sp,sp,32
    80001840:	8082                	ret
      kfree((void *)t->kstack);
    80001842:	fffff097          	auipc	ra,0xfffff
    80001846:	194080e7          	jalr	404(ra) # 800009d6 <kfree>
    8000184a:	bfc9                	j	8000181c <freethread+0x10>

000000008000184c <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000184c:	715d                	addi	sp,sp,-80
    8000184e:	e486                	sd	ra,72(sp)
    80001850:	e0a2                	sd	s0,64(sp)
    80001852:	fc26                	sd	s1,56(sp)
    80001854:	f84a                	sd	s2,48(sp)
    80001856:	f44e                	sd	s3,40(sp)
    80001858:	f052                	sd	s4,32(sp)
    8000185a:	ec56                	sd	s5,24(sp)
    8000185c:	e85a                	sd	s6,16(sp)
    8000185e:	e45e                	sd	s7,8(sp)
    80001860:	e062                	sd	s8,0(sp)
    80001862:	0880                	addi	s0,sp,80
    80001864:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00012497          	auipc	s1,0x12
    8000186a:	29a48493          	addi	s1,s1,666 # 80013b00 <proc>
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8c26                	mv	s8,s1
    80001870:	00007b97          	auipc	s7,0x7
    80001874:	790b8b93          	addi	s7,s7,1936 # 80009000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001880:	6a05                	lui	s4,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001882:	880a0b13          	addi	s6,s4,-1920 # 880 <_entry-0x7ffff780>
    80001886:	00034a97          	auipc	s5,0x34
    8000188a:	27aa8a93          	addi	s5,s5,634 # 80035b00 <tickslock>
    char *pa = kalloc();
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	244080e7          	jalr	580(ra) # 80000ad2 <kalloc>
    80001896:	862a                	mv	a2,a0
    if(pa == 0)
    80001898:	c139                	beqz	a0,800018de <proc_mapstacks+0x92>
    uint64 va = KSTACK((int) (p - proc));
    8000189a:	418485b3          	sub	a1,s1,s8
    8000189e:	859d                	srai	a1,a1,0x7
    800018a0:	000bb783          	ld	a5,0(s7)
    800018a4:	02f585b3          	mul	a1,a1,a5
    800018a8:	2585                	addiw	a1,a1,1
    800018aa:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018ae:	4719                	li	a4,6
    800018b0:	86d2                	mv	a3,s4
    800018b2:	40b905b3          	sub	a1,s2,a1
    800018b6:	854e                	mv	a0,s3
    800018b8:	00000097          	auipc	ra,0x0
    800018bc:	864080e7          	jalr	-1948(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c0:	94da                	add	s1,s1,s6
    800018c2:	fd5496e3          	bne	s1,s5,8000188e <proc_mapstacks+0x42>
}
    800018c6:	60a6                	ld	ra,72(sp)
    800018c8:	6406                	ld	s0,64(sp)
    800018ca:	74e2                	ld	s1,56(sp)
    800018cc:	7942                	ld	s2,48(sp)
    800018ce:	79a2                	ld	s3,40(sp)
    800018d0:	7a02                	ld	s4,32(sp)
    800018d2:	6ae2                	ld	s5,24(sp)
    800018d4:	6b42                	ld	s6,16(sp)
    800018d6:	6ba2                	ld	s7,8(sp)
    800018d8:	6c02                	ld	s8,0(sp)
    800018da:	6161                	addi	sp,sp,80
    800018dc:	8082                	ret
      panic("kalloc");
    800018de:	00008517          	auipc	a0,0x8
    800018e2:	8ea50513          	addi	a0,a0,-1814 # 800091c8 <digits+0x188>
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	c44080e7          	jalr	-956(ra) # 8000052a <panic>

00000000800018ee <init_bsems>:
{
    800018ee:	7179                	addi	sp,sp,-48
    800018f0:	f406                	sd	ra,40(sp)
    800018f2:	f022                	sd	s0,32(sp)
    800018f4:	ec26                	sd	s1,24(sp)
    800018f6:	e84a                	sd	s2,16(sp)
    800018f8:	e44e                	sd	s3,8(sp)
    800018fa:	1800                	addi	s0,sp,48
  for(struct bsem* bs = bsems; bs < &bsems[MAX_BSEM]; bs++){
    800018fc:	00011497          	auipc	s1,0x11
    80001900:	e1448493          	addi	s1,s1,-492 # 80012710 <bsems+0x10>
    80001904:	00012997          	auipc	s3,0x12
    80001908:	20c98993          	addi	s3,s3,524 # 80013b10 <proc+0x10>
    initlock(&bs->mutex, "bsem_mutex");
    8000190c:	00008917          	auipc	s2,0x8
    80001910:	8c490913          	addi	s2,s2,-1852 # 800091d0 <digits+0x190>
    bs->active = 0;
    80001914:	fe04a823          	sw	zero,-16(s1)
    initlock(&bs->mutex, "bsem_mutex");
    80001918:	85ca                	mv	a1,s2
    8000191a:	8526                	mv	a0,s1
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	216080e7          	jalr	534(ra) # 80000b32 <initlock>
  for(struct bsem* bs = bsems; bs < &bsems[MAX_BSEM]; bs++){
    80001924:	02848493          	addi	s1,s1,40
    80001928:	ff3496e3          	bne	s1,s3,80001914 <init_bsems+0x26>
}
    8000192c:	70a2                	ld	ra,40(sp)
    8000192e:	7402                	ld	s0,32(sp)
    80001930:	64e2                	ld	s1,24(sp)
    80001932:	6942                	ld	s2,16(sp)
    80001934:	69a2                	ld	s3,8(sp)
    80001936:	6145                	addi	sp,sp,48
    80001938:	8082                	ret

000000008000193a <procinit>:
{
    8000193a:	715d                	addi	sp,sp,-80
    8000193c:	e486                	sd	ra,72(sp)
    8000193e:	e0a2                	sd	s0,64(sp)
    80001940:	fc26                	sd	s1,56(sp)
    80001942:	f84a                	sd	s2,48(sp)
    80001944:	f44e                	sd	s3,40(sp)
    80001946:	f052                	sd	s4,32(sp)
    80001948:	ec56                	sd	s5,24(sp)
    8000194a:	e85a                	sd	s6,16(sp)
    8000194c:	e45e                	sd	s7,8(sp)
    8000194e:	0880                	addi	s0,sp,80
  init_bsems();
    80001950:	00000097          	auipc	ra,0x0
    80001954:	f9e080e7          	jalr	-98(ra) # 800018ee <init_bsems>
  initlock(&pid_lock, "nextpid");
    80001958:	00008597          	auipc	a1,0x8
    8000195c:	88858593          	addi	a1,a1,-1912 # 800091e0 <digits+0x1a0>
    80001960:	00011517          	auipc	a0,0x11
    80001964:	94050513          	addi	a0,a0,-1728 # 800122a0 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	1ca080e7          	jalr	458(ra) # 80000b32 <initlock>
  initlock(&tid_lock, "nexttid"); // ADDED Q3
    80001970:	00008597          	auipc	a1,0x8
    80001974:	87858593          	addi	a1,a1,-1928 # 800091e8 <digits+0x1a8>
    80001978:	00011517          	auipc	a0,0x11
    8000197c:	94050513          	addi	a0,a0,-1728 # 800122b8 <tid_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	1b2080e7          	jalr	434(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001988:	00008597          	auipc	a1,0x8
    8000198c:	86858593          	addi	a1,a1,-1944 # 800091f0 <digits+0x1b0>
    80001990:	00011517          	auipc	a0,0x11
    80001994:	94050513          	addi	a0,a0,-1728 # 800122d0 <wait_lock>
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	19a080e7          	jalr	410(ra) # 80000b32 <initlock>
  initlock(&join_lock, "join_lock"); // ADDED Q3
    800019a0:	00008597          	auipc	a1,0x8
    800019a4:	86058593          	addi	a1,a1,-1952 # 80009200 <digits+0x1c0>
    800019a8:	00011517          	auipc	a0,0x11
    800019ac:	94050513          	addi	a0,a0,-1728 # 800122e8 <join_lock>
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	182080e7          	jalr	386(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b8:	00013917          	auipc	s2,0x13
    800019bc:	9c090913          	addi	s2,s2,-1600 # 80014378 <proc+0x878>
    800019c0:	00035b97          	auipc	s7,0x35
    800019c4:	9b8b8b93          	addi	s7,s7,-1608 # 80036378 <bcache+0x860>
    initlock(&p->lock, "proc");
    800019c8:	7afd                	lui	s5,0xfffff
    800019ca:	788a8a93          	addi	s5,s5,1928 # fffffffffffff788 <end+0xffffffff7ffbb788>
    800019ce:	00008b17          	auipc	s6,0x8
    800019d2:	842b0b13          	addi	s6,s6,-1982 # 80009210 <digits+0x1d0>
      initlock(&t->lock, "thread");
    800019d6:	00008997          	auipc	s3,0x8
    800019da:	84298993          	addi	s3,s3,-1982 # 80009218 <digits+0x1d8>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019de:	6a05                	lui	s4,0x1
    800019e0:	880a0a13          	addi	s4,s4,-1920 # 880 <_entry-0x7ffff780>
    800019e4:	a021                	j	800019ec <procinit+0xb2>
    800019e6:	9952                	add	s2,s2,s4
    800019e8:	03790663          	beq	s2,s7,80001a14 <procinit+0xda>
    initlock(&p->lock, "proc");
    800019ec:	85da                	mv	a1,s6
    800019ee:	01590533          	add	a0,s2,s5
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	140080e7          	jalr	320(ra) # 80000b32 <initlock>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800019fa:	a0090493          	addi	s1,s2,-1536
      initlock(&t->lock, "thread");
    800019fe:	85ce                	mv	a1,s3
    80001a00:	8526                	mv	a0,s1
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	130080e7          	jalr	304(ra) # 80000b32 <initlock>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001a0a:	0c048493          	addi	s1,s1,192
    80001a0e:	ff2498e3          	bne	s1,s2,800019fe <procinit+0xc4>
    80001a12:	bfd1                	j	800019e6 <procinit+0xac>
}
    80001a14:	60a6                	ld	ra,72(sp)
    80001a16:	6406                	ld	s0,64(sp)
    80001a18:	74e2                	ld	s1,56(sp)
    80001a1a:	7942                	ld	s2,48(sp)
    80001a1c:	79a2                	ld	s3,40(sp)
    80001a1e:	7a02                	ld	s4,32(sp)
    80001a20:	6ae2                	ld	s5,24(sp)
    80001a22:	6b42                	ld	s6,16(sp)
    80001a24:	6ba2                	ld	s7,8(sp)
    80001a26:	6161                	addi	sp,sp,80
    80001a28:	8082                	ret

0000000080001a2a <cpuid>:
{
    80001a2a:	1141                	addi	sp,sp,-16
    80001a2c:	e422                	sd	s0,8(sp)
    80001a2e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a30:	8512                	mv	a0,tp
}
    80001a32:	2501                	sext.w	a0,a0
    80001a34:	6422                	ld	s0,8(sp)
    80001a36:	0141                	addi	sp,sp,16
    80001a38:	8082                	ret

0000000080001a3a <mycpu>:
mycpu(void) {
    80001a3a:	1141                	addi	sp,sp,-16
    80001a3c:	e422                	sd	s0,8(sp)
    80001a3e:	0800                	addi	s0,sp,16
    80001a40:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a42:	2781                	sext.w	a5,a5
    80001a44:	079e                	slli	a5,a5,0x7
}
    80001a46:	00011517          	auipc	a0,0x11
    80001a4a:	8ba50513          	addi	a0,a0,-1862 # 80012300 <cpus>
    80001a4e:	953e                	add	a0,a0,a5
    80001a50:	6422                	ld	s0,8(sp)
    80001a52:	0141                	addi	sp,sp,16
    80001a54:	8082                	ret

0000000080001a56 <myproc>:
myproc(void) {
    80001a56:	1101                	addi	sp,sp,-32
    80001a58:	ec06                	sd	ra,24(sp)
    80001a5a:	e822                	sd	s0,16(sp)
    80001a5c:	e426                	sd	s1,8(sp)
    80001a5e:	1000                	addi	s0,sp,32
  push_off();
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	116080e7          	jalr	278(ra) # 80000b76 <push_off>
    80001a68:	8792                	mv	a5,tp
  struct proc *p = c->thread->proc; //ADDED Q3
    80001a6a:	2781                	sext.w	a5,a5
    80001a6c:	079e                	slli	a5,a5,0x7
    80001a6e:	00011717          	auipc	a4,0x11
    80001a72:	83270713          	addi	a4,a4,-1998 # 800122a0 <pid_lock>
    80001a76:	97ba                	add	a5,a5,a4
    80001a78:	73bc                	ld	a5,96(a5)
    80001a7a:	7f84                	ld	s1,56(a5)
  pop_off();
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	19a080e7          	jalr	410(ra) # 80000c16 <pop_off>
}
    80001a84:	8526                	mv	a0,s1
    80001a86:	60e2                	ld	ra,24(sp)
    80001a88:	6442                	ld	s0,16(sp)
    80001a8a:	64a2                	ld	s1,8(sp)
    80001a8c:	6105                	addi	sp,sp,32
    80001a8e:	8082                	ret

0000000080001a90 <mythread>:
mythread(void) {
    80001a90:	1101                	addi	sp,sp,-32
    80001a92:	ec06                	sd	ra,24(sp)
    80001a94:	e822                	sd	s0,16(sp)
    80001a96:	e426                	sd	s1,8(sp)
    80001a98:	1000                	addi	s0,sp,32
  push_off();
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	0dc080e7          	jalr	220(ra) # 80000b76 <push_off>
    80001aa2:	8792                	mv	a5,tp
  struct thread *t = c->thread;
    80001aa4:	2781                	sext.w	a5,a5
    80001aa6:	079e                	slli	a5,a5,0x7
    80001aa8:	00010717          	auipc	a4,0x10
    80001aac:	7f870713          	addi	a4,a4,2040 # 800122a0 <pid_lock>
    80001ab0:	97ba                	add	a5,a5,a4
    80001ab2:	73a4                	ld	s1,96(a5)
  pop_off();
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	162080e7          	jalr	354(ra) # 80000c16 <pop_off>
}
    80001abc:	8526                	mv	a0,s1
    80001abe:	60e2                	ld	ra,24(sp)
    80001ac0:	6442                	ld	s0,16(sp)
    80001ac2:	64a2                	ld	s1,8(sp)
    80001ac4:	6105                	addi	sp,sp,32
    80001ac6:	8082                	ret

0000000080001ac8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ac8:	1141                	addi	sp,sp,-16
    80001aca:	e406                	sd	ra,8(sp)
    80001acc:	e022                	sd	s0,0(sp)
    80001ace:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding t->lock from scheduler.
  release(&mythread()->lock); // ADDED Q3
    80001ad0:	00000097          	auipc	ra,0x0
    80001ad4:	fc0080e7          	jalr	-64(ra) # 80001a90 <mythread>
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	19e080e7          	jalr	414(ra) # 80000c76 <release>

  if (first) {
    80001ae0:	00008797          	auipc	a5,0x8
    80001ae4:	d807a783          	lw	a5,-640(a5) # 80009860 <first.1>
    80001ae8:	eb89                	bnez	a5,80001afa <forkret+0x32>
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }
  usertrapret();
    80001aea:	00002097          	auipc	ra,0x2
    80001aee:	9d4080e7          	jalr	-1580(ra) # 800034be <usertrapret>
}
    80001af2:	60a2                	ld	ra,8(sp)
    80001af4:	6402                	ld	s0,0(sp)
    80001af6:	0141                	addi	sp,sp,16
    80001af8:	8082                	ret
    first = 0;
    80001afa:	00008797          	auipc	a5,0x8
    80001afe:	d607a323          	sw	zero,-666(a5) # 80009860 <first.1>
    fsinit(ROOTDEV);
    80001b02:	4505                	li	a0,1
    80001b04:	00003097          	auipc	ra,0x3
    80001b08:	9c0080e7          	jalr	-1600(ra) # 800044c4 <fsinit>
    80001b0c:	bff9                	j	80001aea <forkret+0x22>

0000000080001b0e <allocpid>:
allocpid() {
    80001b0e:	1101                	addi	sp,sp,-32
    80001b10:	ec06                	sd	ra,24(sp)
    80001b12:	e822                	sd	s0,16(sp)
    80001b14:	e426                	sd	s1,8(sp)
    80001b16:	e04a                	sd	s2,0(sp)
    80001b18:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b1a:	00010917          	auipc	s2,0x10
    80001b1e:	78690913          	addi	s2,s2,1926 # 800122a0 <pid_lock>
    80001b22:	854a                	mv	a0,s2
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	09e080e7          	jalr	158(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001b2c:	00008797          	auipc	a5,0x8
    80001b30:	d3c78793          	addi	a5,a5,-708 # 80009868 <nextpid>
    80001b34:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b36:	0014871b          	addiw	a4,s1,1
    80001b3a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b3c:	854a                	mv	a0,s2
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	138080e7          	jalr	312(ra) # 80000c76 <release>
}
    80001b46:	8526                	mv	a0,s1
    80001b48:	60e2                	ld	ra,24(sp)
    80001b4a:	6442                	ld	s0,16(sp)
    80001b4c:	64a2                	ld	s1,8(sp)
    80001b4e:	6902                	ld	s2,0(sp)
    80001b50:	6105                	addi	sp,sp,32
    80001b52:	8082                	ret

0000000080001b54 <alloctid>:
alloctid() {
    80001b54:	1101                	addi	sp,sp,-32
    80001b56:	ec06                	sd	ra,24(sp)
    80001b58:	e822                	sd	s0,16(sp)
    80001b5a:	e426                	sd	s1,8(sp)
    80001b5c:	e04a                	sd	s2,0(sp)
    80001b5e:	1000                	addi	s0,sp,32
  acquire(&tid_lock);
    80001b60:	00010917          	auipc	s2,0x10
    80001b64:	75890913          	addi	s2,s2,1880 # 800122b8 <tid_lock>
    80001b68:	854a                	mv	a0,s2
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	058080e7          	jalr	88(ra) # 80000bc2 <acquire>
  tid = nexttid;
    80001b72:	00008797          	auipc	a5,0x8
    80001b76:	cf278793          	addi	a5,a5,-782 # 80009864 <nexttid>
    80001b7a:	4384                	lw	s1,0(a5)
  nexttid = nexttid + 1;
    80001b7c:	0014871b          	addiw	a4,s1,1
    80001b80:	c398                	sw	a4,0(a5)
  release(&tid_lock);
    80001b82:	854a                	mv	a0,s2
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	0f2080e7          	jalr	242(ra) # 80000c76 <release>
}
    80001b8c:	8526                	mv	a0,s1
    80001b8e:	60e2                	ld	ra,24(sp)
    80001b90:	6442                	ld	s0,16(sp)
    80001b92:	64a2                	ld	s1,8(sp)
    80001b94:	6902                	ld	s2,0(sp)
    80001b96:	6105                	addi	sp,sp,32
    80001b98:	8082                	ret

0000000080001b9a <allocthread>:
{
    80001b9a:	7179                	addi	sp,sp,-48
    80001b9c:	f406                	sd	ra,40(sp)
    80001b9e:	f022                	sd	s0,32(sp)
    80001ba0:	ec26                	sd	s1,24(sp)
    80001ba2:	e84a                	sd	s2,16(sp)
    80001ba4:	e44e                	sd	s3,8(sp)
    80001ba6:	e052                	sd	s4,0(sp)
    80001ba8:	1800                	addi	s0,sp,48
    80001baa:	8a2a                	mv	s4,a0
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001bac:	27850493          	addi	s1,a0,632
    int t_index = 0;
    80001bb0:	4901                	li	s2,0
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001bb2:	49a1                	li	s3,8
    80001bb4:	a88d                	j	80001c26 <allocthread+0x8c>
  t->tid = alloctid();
    80001bb6:	00000097          	auipc	ra,0x0
    80001bba:	f9e080e7          	jalr	-98(ra) # 80001b54 <alloctid>
    80001bbe:	d888                	sw	a0,48(s1)
  t->index = t_index;
    80001bc0:	0324aa23          	sw	s2,52(s1)
  t->state = USED_T;
    80001bc4:	4785                	li	a5,1
    80001bc6:	cc9c                	sw	a5,24(s1)
  t->trapframe = &p->trapframes[t_index];
    80001bc8:	6705                	lui	a4,0x1
    80001bca:	9752                	add	a4,a4,s4
    80001bcc:	00391793          	slli	a5,s2,0x3
    80001bd0:	993e                	add	s2,s2,a5
    80001bd2:	0916                	slli	s2,s2,0x5
    80001bd4:	87873783          	ld	a5,-1928(a4) # 878 <_entry-0x7ffff788>
    80001bd8:	993e                	add	s2,s2,a5
    80001bda:	0524b423          	sd	s2,72(s1)
  t->terminated = 0;
    80001bde:	0204a423          	sw	zero,40(s1)
  t->proc = p;
    80001be2:	0344bc23          	sd	s4,56(s1)
  memset(&t->context, 0, sizeof(t->context));
    80001be6:	07000613          	li	a2,112
    80001bea:	4581                	li	a1,0
    80001bec:	05048513          	addi	a0,s1,80
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	0ce080e7          	jalr	206(ra) # 80000cbe <memset>
  t->context.ra = (uint64)forkret;
    80001bf8:	00000797          	auipc	a5,0x0
    80001bfc:	ed078793          	addi	a5,a5,-304 # 80001ac8 <forkret>
    80001c00:	e8bc                	sd	a5,80(s1)
  if((t->kstack = (uint64)kalloc()) == 0) {
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	ed0080e7          	jalr	-304(ra) # 80000ad2 <kalloc>
    80001c0a:	892a                	mv	s2,a0
    80001c0c:	e0a8                	sd	a0,64(s1)
    80001c0e:	c929                	beqz	a0,80001c60 <allocthread+0xc6>
  t->context.sp = t->kstack + PGSIZE;
    80001c10:	6785                	lui	a5,0x1
    80001c12:	00f50933          	add	s2,a0,a5
    80001c16:	0524bc23          	sd	s2,88(s1)
  return t;
    80001c1a:	a815                	j	80001c4e <allocthread+0xb4>
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001c1c:	0c048493          	addi	s1,s1,192
    80001c20:	2905                	addiw	s2,s2,1
    80001c22:	03390563          	beq	s2,s3,80001c4c <allocthread+0xb2>
      if (t != mythread()) {
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	e6a080e7          	jalr	-406(ra) # 80001a90 <mythread>
    80001c2e:	fea487e3          	beq	s1,a0,80001c1c <allocthread+0x82>
        acquire(&t->lock);
    80001c32:	8526                	mv	a0,s1
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	f8e080e7          	jalr	-114(ra) # 80000bc2 <acquire>
        if (t->state == UNUSED_T) {
    80001c3c:	4c9c                	lw	a5,24(s1)
    80001c3e:	dfa5                	beqz	a5,80001bb6 <allocthread+0x1c>
        release(&t->lock);
    80001c40:	8526                	mv	a0,s1
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	034080e7          	jalr	52(ra) # 80000c76 <release>
    80001c4a:	bfc9                	j	80001c1c <allocthread+0x82>
    return 0;
    80001c4c:	4481                	li	s1,0
}
    80001c4e:	8526                	mv	a0,s1
    80001c50:	70a2                	ld	ra,40(sp)
    80001c52:	7402                	ld	s0,32(sp)
    80001c54:	64e2                	ld	s1,24(sp)
    80001c56:	6942                	ld	s2,16(sp)
    80001c58:	69a2                	ld	s3,8(sp)
    80001c5a:	6a02                	ld	s4,0(sp)
    80001c5c:	6145                	addi	sp,sp,48
    80001c5e:	8082                	ret
      freethread(t);
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	baa080e7          	jalr	-1110(ra) # 8000180c <freethread>
      release(&t->lock);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	00a080e7          	jalr	10(ra) # 80000c76 <release>
      return 0;
    80001c74:	84ca                	mv	s1,s2
    80001c76:	bfe1                	j	80001c4e <allocthread+0xb4>

0000000080001c78 <proc_pagetable>:
{
    80001c78:	1101                	addi	sp,sp,-32
    80001c7a:	ec06                	sd	ra,24(sp)
    80001c7c:	e822                	sd	s0,16(sp)
    80001c7e:	e426                	sd	s1,8(sp)
    80001c80:	e04a                	sd	s2,0(sp)
    80001c82:	1000                	addi	s0,sp,32
    80001c84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	680080e7          	jalr	1664(ra) # 80001306 <uvmcreate>
    80001c8e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c90:	c131                	beqz	a0,80001cd4 <proc_pagetable+0x5c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c92:	4729                	li	a4,10
    80001c94:	00006697          	auipc	a3,0x6
    80001c98:	36c68693          	addi	a3,a3,876 # 80008000 <_trampoline>
    80001c9c:	6605                	lui	a2,0x1
    80001c9e:	040005b7          	lui	a1,0x4000
    80001ca2:	15fd                	addi	a1,a1,-1
    80001ca4:	05b2                	slli	a1,a1,0xc
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	3e8080e7          	jalr	1000(ra) # 8000108e <mappages>
    80001cae:	02054a63          	bltz	a0,80001ce2 <proc_pagetable+0x6a>
              (uint64)(p->trapframes), PTE_R | PTE_W) < 0){
    80001cb2:	6505                	lui	a0,0x1
    80001cb4:	954a                	add	a0,a0,s2
  if(mappages(pagetable, TRAPFRAME(0), PGSIZE,
    80001cb6:	4719                	li	a4,6
    80001cb8:	87853683          	ld	a3,-1928(a0) # 878 <_entry-0x7ffff788>
    80001cbc:	6605                	lui	a2,0x1
    80001cbe:	020005b7          	lui	a1,0x2000
    80001cc2:	15fd                	addi	a1,a1,-1
    80001cc4:	05b6                	slli	a1,a1,0xd
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	3c6080e7          	jalr	966(ra) # 8000108e <mappages>
    80001cd0:	02054163          	bltz	a0,80001cf2 <proc_pagetable+0x7a>
}
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	60e2                	ld	ra,24(sp)
    80001cd8:	6442                	ld	s0,16(sp)
    80001cda:	64a2                	ld	s1,8(sp)
    80001cdc:	6902                	ld	s2,0(sp)
    80001cde:	6105                	addi	sp,sp,32
    80001ce0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ce2:	4581                	li	a1,0
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	81c080e7          	jalr	-2020(ra) # 80001502 <uvmfree>
    return 0;
    80001cee:	4481                	li	s1,0
    80001cf0:	b7d5                	j	80001cd4 <proc_pagetable+0x5c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf2:	4681                	li	a3,0
    80001cf4:	4605                	li	a2,1
    80001cf6:	040005b7          	lui	a1,0x4000
    80001cfa:	15fd                	addi	a1,a1,-1
    80001cfc:	05b2                	slli	a1,a1,0xc
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	542080e7          	jalr	1346(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d08:	4581                	li	a1,0
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	7f6080e7          	jalr	2038(ra) # 80001502 <uvmfree>
    return 0;
    80001d14:	4481                	li	s1,0
    80001d16:	bf7d                	j	80001cd4 <proc_pagetable+0x5c>

0000000080001d18 <proc_freepagetable>:
{
    80001d18:	1101                	addi	sp,sp,-32
    80001d1a:	ec06                	sd	ra,24(sp)
    80001d1c:	e822                	sd	s0,16(sp)
    80001d1e:	e426                	sd	s1,8(sp)
    80001d20:	e04a                	sd	s2,0(sp)
    80001d22:	1000                	addi	s0,sp,32
    80001d24:	84aa                	mv	s1,a0
    80001d26:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d28:	4681                	li	a3,0
    80001d2a:	4605                	li	a2,1
    80001d2c:	040005b7          	lui	a1,0x4000
    80001d30:	15fd                	addi	a1,a1,-1
    80001d32:	05b2                	slli	a1,a1,0xc
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	50e080e7          	jalr	1294(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME(0), 1, 0);
    80001d3c:	4681                	li	a3,0
    80001d3e:	4605                	li	a2,1
    80001d40:	020005b7          	lui	a1,0x2000
    80001d44:	15fd                	addi	a1,a1,-1
    80001d46:	05b6                	slli	a1,a1,0xd
    80001d48:	8526                	mv	a0,s1
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	4f8080e7          	jalr	1272(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d52:	85ca                	mv	a1,s2
    80001d54:	8526                	mv	a0,s1
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	7ac080e7          	jalr	1964(ra) # 80001502 <uvmfree>
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6902                	ld	s2,0(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret

0000000080001d6a <freeproc>:
{
    80001d6a:	1101                	addi	sp,sp,-32
    80001d6c:	ec06                	sd	ra,24(sp)
    80001d6e:	e822                	sd	s0,16(sp)
    80001d70:	e426                	sd	s1,8(sp)
    80001d72:	e04a                	sd	s2,0(sp)
    80001d74:	1000                	addi	s0,sp,32
    80001d76:	892a                	mv	s2,a0
  if(p->trapframes)
    80001d78:	6785                	lui	a5,0x1
    80001d7a:	97aa                	add	a5,a5,a0
    80001d7c:	8787b503          	ld	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001d80:	c509                	beqz	a0,80001d8a <freeproc+0x20>
    kfree((void*)p->trapframes);
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	c54080e7          	jalr	-940(ra) # 800009d6 <kfree>
  p->trapframes = 0;
    80001d8a:	6785                	lui	a5,0x1
    80001d8c:	97ca                	add	a5,a5,s2
    80001d8e:	8607bc23          	sd	zero,-1928(a5) # 878 <_entry-0x7ffff788>
  if(p->trapframe_backup)
    80001d92:	1b893503          	ld	a0,440(s2)
    80001d96:	c509                	beqz	a0,80001da0 <freeproc+0x36>
    kfree((void*)p->trapframe_backup);
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	c3e080e7          	jalr	-962(ra) # 800009d6 <kfree>
  p->trapframe_backup = 0;
    80001da0:	1a093c23          	sd	zero,440(s2)
  if(p->pagetable)
    80001da4:	1d893503          	ld	a0,472(s2)
    80001da8:	c519                	beqz	a0,80001db6 <freeproc+0x4c>
    proc_freepagetable(p->pagetable, p->sz);
    80001daa:	1d093583          	ld	a1,464(s2)
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	f6a080e7          	jalr	-150(ra) # 80001d18 <proc_freepagetable>
  p->pagetable = 0;
    80001db6:	1c093c23          	sd	zero,472(s2)
  p->sz = 0;
    80001dba:	1c093823          	sd	zero,464(s2)
  p->pid = 0;
    80001dbe:	02092223          	sw	zero,36(s2)
  p->parent = 0;
    80001dc2:	1c093423          	sd	zero,456(s2)
  p->name[0] = 0;
    80001dc6:	26090423          	sb	zero,616(s2)
  p->killed = 0;
    80001dca:	00092e23          	sw	zero,28(s2)
  p->stopped = 0;
    80001dce:	1c092023          	sw	zero,448(s2)
  p->xstate = 0;
    80001dd2:	02092023          	sw	zero,32(s2)
  p->state = UNUSED;
    80001dd6:	00092c23          	sw	zero,24(s2)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001dda:	27890493          	addi	s1,s2,632
    80001dde:	6505                	lui	a0,0x1
    80001de0:	87850513          	addi	a0,a0,-1928 # 878 <_entry-0x7ffff788>
    80001de4:	992a                	add	s2,s2,a0
    freethread(t);
    80001de6:	8526                	mv	a0,s1
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	a24080e7          	jalr	-1500(ra) # 8000180c <freethread>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001df0:	0c048493          	addi	s1,s1,192
    80001df4:	fe9919e3          	bne	s2,s1,80001de6 <freeproc+0x7c>
}
    80001df8:	60e2                	ld	ra,24(sp)
    80001dfa:	6442                	ld	s0,16(sp)
    80001dfc:	64a2                	ld	s1,8(sp)
    80001dfe:	6902                	ld	s2,0(sp)
    80001e00:	6105                	addi	sp,sp,32
    80001e02:	8082                	ret

0000000080001e04 <allocproc>:
{
    80001e04:	7179                	addi	sp,sp,-48
    80001e06:	f406                	sd	ra,40(sp)
    80001e08:	f022                	sd	s0,32(sp)
    80001e0a:	ec26                	sd	s1,24(sp)
    80001e0c:	e84a                	sd	s2,16(sp)
    80001e0e:	e44e                	sd	s3,8(sp)
    80001e10:	e052                	sd	s4,0(sp)
    80001e12:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e14:	00012497          	auipc	s1,0x12
    80001e18:	cec48493          	addi	s1,s1,-788 # 80013b00 <proc>
    80001e1c:	6985                	lui	s3,0x1
    80001e1e:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80001e22:	00034a17          	auipc	s4,0x34
    80001e26:	cdea0a13          	addi	s4,s4,-802 # 80035b00 <tickslock>
    acquire(&p->lock);
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	d96080e7          	jalr	-618(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001e34:	4c9c                	lw	a5,24(s1)
    80001e36:	cb99                	beqz	a5,80001e4c <allocproc+0x48>
      release(&p->lock);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e3c080e7          	jalr	-452(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e42:	94ce                	add	s1,s1,s3
    80001e44:	ff4493e3          	bne	s1,s4,80001e2a <allocproc+0x26>
  return 0;
    80001e48:	4481                	li	s1,0
    80001e4a:	a89d                	j	80001ec0 <allocproc+0xbc>
  p->pid = allocpid();
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	cc2080e7          	jalr	-830(ra) # 80001b0e <allocpid>
    80001e54:	d0c8                	sw	a0,36(s1)
  p->state = USED;
    80001e56:	4785                	li	a5,1
    80001e58:	cc9c                	sw	a5,24(s1)
  p->pending_signals = 0;
    80001e5a:	0204a423          	sw	zero,40(s1)
  p->signal_mask = 0;
    80001e5e:	0204a623          	sw	zero,44(s1)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001e62:	03848793          	addi	a5,s1,56
    80001e66:	13848713          	addi	a4,s1,312
    p->signal_handlers[signum] = SIG_DFL;
    80001e6a:	0007b023          	sd	zero,0(a5)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001e6e:	07a1                	addi	a5,a5,8
    80001e70:	fee79de3          	bne	a5,a4,80001e6a <allocproc+0x66>
  if((p->trapframes = (struct trapframe *)kalloc()) == 0){
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	c5e080e7          	jalr	-930(ra) # 80000ad2 <kalloc>
    80001e7c:	892a                	mv	s2,a0
    80001e7e:	6785                	lui	a5,0x1
    80001e80:	97a6                	add	a5,a5,s1
    80001e82:	86a7bc23          	sd	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001e86:	c531                	beqz	a0,80001ed2 <allocproc+0xce>
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	c4a080e7          	jalr	-950(ra) # 80000ad2 <kalloc>
    80001e90:	892a                	mv	s2,a0
    80001e92:	1aa4bc23          	sd	a0,440(s1)
    80001e96:	c931                	beqz	a0,80001eea <allocproc+0xe6>
  p->pagetable = proc_pagetable(p);
    80001e98:	8526                	mv	a0,s1
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	dde080e7          	jalr	-546(ra) # 80001c78 <proc_pagetable>
    80001ea2:	892a                	mv	s2,a0
    80001ea4:	1ca4bc23          	sd	a0,472(s1)
  if(p->pagetable == 0){
    80001ea8:	cd29                	beqz	a0,80001f02 <allocproc+0xfe>
  if ((t = allocthread(p)) == 0) {
    80001eaa:	8526                	mv	a0,s1
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	cee080e7          	jalr	-786(ra) # 80001b9a <allocthread>
    80001eb4:	892a                	mv	s2,a0
    80001eb6:	c135                	beqz	a0,80001f1a <allocproc+0x116>
  release(&t->lock);
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	dbe080e7          	jalr	-578(ra) # 80000c76 <release>
}
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	70a2                	ld	ra,40(sp)
    80001ec4:	7402                	ld	s0,32(sp)
    80001ec6:	64e2                	ld	s1,24(sp)
    80001ec8:	6942                	ld	s2,16(sp)
    80001eca:	69a2                	ld	s3,8(sp)
    80001ecc:	6a02                	ld	s4,0(sp)
    80001ece:	6145                	addi	sp,sp,48
    80001ed0:	8082                	ret
    freeproc(p);
    80001ed2:	8526                	mv	a0,s1
    80001ed4:	00000097          	auipc	ra,0x0
    80001ed8:	e96080e7          	jalr	-362(ra) # 80001d6a <freeproc>
    release(&p->lock);
    80001edc:	8526                	mv	a0,s1
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	d98080e7          	jalr	-616(ra) # 80000c76 <release>
    return 0;
    80001ee6:	84ca                	mv	s1,s2
    80001ee8:	bfe1                	j	80001ec0 <allocproc+0xbc>
    freeproc(p);
    80001eea:	8526                	mv	a0,s1
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	e7e080e7          	jalr	-386(ra) # 80001d6a <freeproc>
    release(&p->lock);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	d80080e7          	jalr	-640(ra) # 80000c76 <release>
    return 0;
    80001efe:	84ca                	mv	s1,s2
    80001f00:	b7c1                	j	80001ec0 <allocproc+0xbc>
    freeproc(p);
    80001f02:	8526                	mv	a0,s1
    80001f04:	00000097          	auipc	ra,0x0
    80001f08:	e66080e7          	jalr	-410(ra) # 80001d6a <freeproc>
    release(&p->lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	d68080e7          	jalr	-664(ra) # 80000c76 <release>
    return 0;
    80001f16:	84ca                	mv	s1,s2
    80001f18:	b765                	j	80001ec0 <allocproc+0xbc>
    release(&t->lock);
    80001f1a:	4501                	li	a0,0
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	d5a080e7          	jalr	-678(ra) # 80000c76 <release>
    release(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	d50080e7          	jalr	-688(ra) # 80000c76 <release>
    freeproc(p);
    80001f2e:	8526                	mv	a0,s1
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	e3a080e7          	jalr	-454(ra) # 80001d6a <freeproc>
    return 0;
    80001f38:	84ca                	mv	s1,s2
    80001f3a:	b759                	j	80001ec0 <allocproc+0xbc>

0000000080001f3c <userinit>:
{
    80001f3c:	1101                	addi	sp,sp,-32
    80001f3e:	ec06                	sd	ra,24(sp)
    80001f40:	e822                	sd	s0,16(sp)
    80001f42:	e426                	sd	s1,8(sp)
    80001f44:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	ebe080e7          	jalr	-322(ra) # 80001e04 <allocproc>
    80001f4e:	84aa                	mv	s1,a0
  initproc = p;
    80001f50:	00008797          	auipc	a5,0x8
    80001f54:	0ca7bc23          	sd	a0,216(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f58:	03400613          	li	a2,52
    80001f5c:	00008597          	auipc	a1,0x8
    80001f60:	91458593          	addi	a1,a1,-1772 # 80009870 <initcode>
    80001f64:	1d853503          	ld	a0,472(a0)
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	3cc080e7          	jalr	972(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001f70:	6785                	lui	a5,0x1
    80001f72:	1cf4b823          	sd	a5,464(s1)
  p->trapframes->epc = 0;      // user program counter
    80001f76:	00f48733          	add	a4,s1,a5
    80001f7a:	87873683          	ld	a3,-1928(a4)
    80001f7e:	0006bc23          	sd	zero,24(a3)
  p->trapframes->sp = PGSIZE;  // user stack pointer
    80001f82:	87873703          	ld	a4,-1928(a4)
    80001f86:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f88:	4641                	li	a2,16
    80001f8a:	00007597          	auipc	a1,0x7
    80001f8e:	29658593          	addi	a1,a1,662 # 80009220 <digits+0x1e0>
    80001f92:	26848513          	addi	a0,s1,616
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	e7a080e7          	jalr	-390(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001f9e:	00007517          	auipc	a0,0x7
    80001fa2:	29250513          	addi	a0,a0,658 # 80009230 <digits+0x1f0>
    80001fa6:	00003097          	auipc	ra,0x3
    80001faa:	f4c080e7          	jalr	-180(ra) # 80004ef2 <namei>
    80001fae:	26a4b023          	sd	a0,608(s1)
  p->threads[0].state = RUNNABLE;
    80001fb2:	478d                	li	a5,3
    80001fb4:	28f4a823          	sw	a5,656(s1)
  release(&p->lock);
    80001fb8:	8526                	mv	a0,s1
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	cbc080e7          	jalr	-836(ra) # 80000c76 <release>
}
    80001fc2:	60e2                	ld	ra,24(sp)
    80001fc4:	6442                	ld	s0,16(sp)
    80001fc6:	64a2                	ld	s1,8(sp)
    80001fc8:	6105                	addi	sp,sp,32
    80001fca:	8082                	ret

0000000080001fcc <growproc>:
{
    80001fcc:	1101                	addi	sp,sp,-32
    80001fce:	ec06                	sd	ra,24(sp)
    80001fd0:	e822                	sd	s0,16(sp)
    80001fd2:	e426                	sd	s1,8(sp)
    80001fd4:	e04a                	sd	s2,0(sp)
    80001fd6:	1000                	addi	s0,sp,32
    80001fd8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	a7c080e7          	jalr	-1412(ra) # 80001a56 <myproc>
    80001fe2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	bde080e7          	jalr	-1058(ra) # 80000bc2 <acquire>
  sz = p->sz;
    80001fec:	1d04b583          	ld	a1,464(s1)
    80001ff0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ff4:	03204463          	bgtz	s2,8000201c <growproc+0x50>
  } else if(n < 0){
    80001ff8:	04094863          	bltz	s2,80002048 <growproc+0x7c>
  p->sz = sz;
    80001ffc:	1602                	slli	a2,a2,0x20
    80001ffe:	9201                	srli	a2,a2,0x20
    80002000:	1cc4b823          	sd	a2,464(s1)
  release(&p->lock);
    80002004:	8526                	mv	a0,s1
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	c70080e7          	jalr	-912(ra) # 80000c76 <release>
  return 0;
    8000200e:	4501                	li	a0,0
}
    80002010:	60e2                	ld	ra,24(sp)
    80002012:	6442                	ld	s0,16(sp)
    80002014:	64a2                	ld	s1,8(sp)
    80002016:	6902                	ld	s2,0(sp)
    80002018:	6105                	addi	sp,sp,32
    8000201a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000201c:	00c9063b          	addw	a2,s2,a2
    80002020:	1602                	slli	a2,a2,0x20
    80002022:	9201                	srli	a2,a2,0x20
    80002024:	1582                	slli	a1,a1,0x20
    80002026:	9181                	srli	a1,a1,0x20
    80002028:	1d84b503          	ld	a0,472(s1)
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	3c2080e7          	jalr	962(ra) # 800013ee <uvmalloc>
    80002034:	0005061b          	sext.w	a2,a0
    80002038:	f271                	bnez	a2,80001ffc <growproc+0x30>
      release(&p->lock);
    8000203a:	8526                	mv	a0,s1
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	c3a080e7          	jalr	-966(ra) # 80000c76 <release>
      return -1;
    80002044:	557d                	li	a0,-1
    80002046:	b7e9                	j	80002010 <growproc+0x44>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002048:	00c9063b          	addw	a2,s2,a2
    8000204c:	1602                	slli	a2,a2,0x20
    8000204e:	9201                	srli	a2,a2,0x20
    80002050:	1582                	slli	a1,a1,0x20
    80002052:	9181                	srli	a1,a1,0x20
    80002054:	1d84b503          	ld	a0,472(s1)
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	34e080e7          	jalr	846(ra) # 800013a6 <uvmdealloc>
    80002060:	0005061b          	sext.w	a2,a0
    80002064:	bf61                	j	80001ffc <growproc+0x30>

0000000080002066 <fork>:
{
    80002066:	7139                	addi	sp,sp,-64
    80002068:	fc06                	sd	ra,56(sp)
    8000206a:	f822                	sd	s0,48(sp)
    8000206c:	f426                	sd	s1,40(sp)
    8000206e:	f04a                	sd	s2,32(sp)
    80002070:	ec4e                	sd	s3,24(sp)
    80002072:	e852                	sd	s4,16(sp)
    80002074:	e456                	sd	s5,8(sp)
    80002076:	0080                	addi	s0,sp,64
  struct thread *t = mythread();
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	a18080e7          	jalr	-1512(ra) # 80001a90 <mythread>
    80002080:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002082:	00000097          	auipc	ra,0x0
    80002086:	9d4080e7          	jalr	-1580(ra) # 80001a56 <myproc>
    8000208a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0) {
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	d78080e7          	jalr	-648(ra) # 80001e04 <allocproc>
    80002094:	14050a63          	beqz	a0,800021e8 <fork+0x182>
    80002098:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000209a:	1d093603          	ld	a2,464(s2)
    8000209e:	1d853583          	ld	a1,472(a0)
    800020a2:	1d893503          	ld	a0,472(s2)
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	494080e7          	jalr	1172(ra) # 8000153a <uvmcopy>
    800020ae:	04054763          	bltz	a0,800020fc <fork+0x96>
  np->sz = p->sz;
    800020b2:	1d093783          	ld	a5,464(s2)
    800020b6:	1cfa3823          	sd	a5,464(s4)
  *(nt->trapframe) = *(t->trapframe); 
    800020ba:	64b4                	ld	a3,72(s1)
    800020bc:	87b6                	mv	a5,a3
    800020be:	2c0a3703          	ld	a4,704(s4)
    800020c2:	12068693          	addi	a3,a3,288
    800020c6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800020ca:	6788                	ld	a0,8(a5)
    800020cc:	6b8c                	ld	a1,16(a5)
    800020ce:	6f90                	ld	a2,24(a5)
    800020d0:	01073023          	sd	a6,0(a4)
    800020d4:	e708                	sd	a0,8(a4)
    800020d6:	eb0c                	sd	a1,16(a4)
    800020d8:	ef10                	sd	a2,24(a4)
    800020da:	02078793          	addi	a5,a5,32
    800020de:	02070713          	addi	a4,a4,32
    800020e2:	fed792e3          	bne	a5,a3,800020c6 <fork+0x60>
  nt->trapframe->a0 = 0;
    800020e6:	2c0a3783          	ld	a5,704(s4)
    800020ea:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800020ee:	1e090493          	addi	s1,s2,480
    800020f2:	1e0a0993          	addi	s3,s4,480
    800020f6:	26090a93          	addi	s5,s2,608
    800020fa:	a00d                	j	8000211c <fork+0xb6>
    freeproc(np);
    800020fc:	8552                	mv	a0,s4
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	c6c080e7          	jalr	-916(ra) # 80001d6a <freeproc>
    release(&np->lock);
    80002106:	8552                	mv	a0,s4
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b6e080e7          	jalr	-1170(ra) # 80000c76 <release>
    return -1;
    80002110:	59fd                	li	s3,-1
    80002112:	a0c9                	j	800021d4 <fork+0x16e>
  for(i = 0; i < NOFILE; i++)
    80002114:	04a1                	addi	s1,s1,8
    80002116:	09a1                	addi	s3,s3,8
    80002118:	01548b63          	beq	s1,s5,8000212e <fork+0xc8>
    if(p->ofile[i])
    8000211c:	6088                	ld	a0,0(s1)
    8000211e:	d97d                	beqz	a0,80002114 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    80002120:	00003097          	auipc	ra,0x3
    80002124:	46c080e7          	jalr	1132(ra) # 8000558c <filedup>
    80002128:	00a9b023          	sd	a0,0(s3)
    8000212c:	b7e5                	j	80002114 <fork+0xae>
  np->cwd = idup(p->cwd);
    8000212e:	26093503          	ld	a0,608(s2)
    80002132:	00002097          	auipc	ra,0x2
    80002136:	5cc080e7          	jalr	1484(ra) # 800046fe <idup>
    8000213a:	26aa3023          	sd	a0,608(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000213e:	4641                	li	a2,16
    80002140:	26890593          	addi	a1,s2,616
    80002144:	268a0513          	addi	a0,s4,616
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	cc8080e7          	jalr	-824(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002150:	024a2983          	lw	s3,36(s4)
  release(&np->lock);
    80002154:	8552                	mv	a0,s4
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b20080e7          	jalr	-1248(ra) # 80000c76 <release>
  acquire(&wait_lock);
    8000215e:	00010497          	auipc	s1,0x10
    80002162:	17248493          	addi	s1,s1,370 # 800122d0 <wait_lock>
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	a5a080e7          	jalr	-1446(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002170:	1d2a3423          	sd	s2,456(s4)
  release(&wait_lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b00080e7          	jalr	-1280(ra) # 80000c76 <release>
  acquire(&np->lock);
    8000217e:	8552                	mv	a0,s4
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	a42080e7          	jalr	-1470(ra) # 80000bc2 <acquire>
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
    80002188:	02c92783          	lw	a5,44(s2)
    8000218c:	02fa2623          	sw	a5,44(s4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80002190:	03890793          	addi	a5,s2,56
    80002194:	038a0713          	addi	a4,s4,56
    80002198:	13890613          	addi	a2,s2,312
    np->signal_handlers[i] = p->signal_handlers[i];    
    8000219c:	6394                	ld	a3,0(a5)
    8000219e:	e314                	sd	a3,0(a4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    800021a0:	07a1                	addi	a5,a5,8
    800021a2:	0721                	addi	a4,a4,8
    800021a4:	fec79ce3          	bne	a5,a2,8000219c <fork+0x136>
  np->pending_signals = 0; // ADDED Q2.1.2
    800021a8:	020a2423          	sw	zero,40(s4)
  release(&np->lock);
    800021ac:	8552                	mv	a0,s4
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	ac8080e7          	jalr	-1336(ra) # 80000c76 <release>
  acquire(&nt->lock);
    800021b6:	278a0493          	addi	s1,s4,632
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a06080e7          	jalr	-1530(ra) # 80000bc2 <acquire>
  nt->state = RUNNABLE;
    800021c4:	478d                	li	a5,3
    800021c6:	28fa2823          	sw	a5,656(s4)
  release(&nt->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	aaa080e7          	jalr	-1366(ra) # 80000c76 <release>
}
    800021d4:	854e                	mv	a0,s3
    800021d6:	70e2                	ld	ra,56(sp)
    800021d8:	7442                	ld	s0,48(sp)
    800021da:	74a2                	ld	s1,40(sp)
    800021dc:	7902                	ld	s2,32(sp)
    800021de:	69e2                	ld	s3,24(sp)
    800021e0:	6a42                	ld	s4,16(sp)
    800021e2:	6aa2                	ld	s5,8(sp)
    800021e4:	6121                	addi	sp,sp,64
    800021e6:	8082                	ret
    return -1;
    800021e8:	59fd                	li	s3,-1
    800021ea:	b7ed                	j	800021d4 <fork+0x16e>

00000000800021ec <kill_handler>:
{
    800021ec:	1141                	addi	sp,sp,-16
    800021ee:	e406                	sd	ra,8(sp)
    800021f0:	e022                	sd	s0,0(sp)
    800021f2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	862080e7          	jalr	-1950(ra) # 80001a56 <myproc>
  p->killed = 1; 
    800021fc:	4785                	li	a5,1
    800021fe:	cd5c                	sw	a5,28(a0)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002200:	27850793          	addi	a5,a0,632
    80002204:	6705                	lui	a4,0x1
    80002206:	87870713          	addi	a4,a4,-1928 # 878 <_entry-0x7ffff788>
    8000220a:	953a                	add	a0,a0,a4
    if (t->state == SLEEPING) {
    8000220c:	4689                	li	a3,2
      t->state = RUNNABLE;
    8000220e:	460d                	li	a2,3
    80002210:	a029                	j	8000221a <kill_handler+0x2e>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002212:	0c078793          	addi	a5,a5,192
    80002216:	00f50763          	beq	a0,a5,80002224 <kill_handler+0x38>
    if (t->state == SLEEPING) {
    8000221a:	4f98                	lw	a4,24(a5)
    8000221c:	fed71be3          	bne	a4,a3,80002212 <kill_handler+0x26>
      t->state = RUNNABLE;
    80002220:	cf90                	sw	a2,24(a5)
    80002222:	bfc5                	j	80002212 <kill_handler+0x26>
}
    80002224:	60a2                	ld	ra,8(sp)
    80002226:	6402                	ld	s0,0(sp)
    80002228:	0141                	addi	sp,sp,16
    8000222a:	8082                	ret

000000008000222c <received_continue>:
{
    8000222c:	1101                	addi	sp,sp,-32
    8000222e:	ec06                	sd	ra,24(sp)
    80002230:	e822                	sd	s0,16(sp)
    80002232:	e426                	sd	s1,8(sp)
    80002234:	e04a                	sd	s2,0(sp)
    80002236:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002238:	00000097          	auipc	ra,0x0
    8000223c:	81e080e7          	jalr	-2018(ra) # 80001a56 <myproc>
    80002240:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	980080e7          	jalr	-1664(ra) # 80000bc2 <acquire>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    8000224a:	02c92683          	lw	a3,44(s2)
    8000224e:	fff6c693          	not	a3,a3
    80002252:	02892783          	lw	a5,40(s2)
    80002256:	8efd                	and	a3,a3,a5
    80002258:	2681                	sext.w	a3,a3
    for (int signum = 0; signum < SIG_NUM; signum++) {
    8000225a:	03890713          	addi	a4,s2,56
    8000225e:	4781                	li	a5,0
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002260:	454d                	li	a0,19
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80002262:	02000613          	li	a2,32
    80002266:	a801                	j	80002276 <received_continue+0x4a>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002268:	630c                	ld	a1,0(a4)
    8000226a:	00a58f63          	beq	a1,a0,80002288 <received_continue+0x5c>
    for (int signum = 0; signum < SIG_NUM; signum++) {
    8000226e:	2785                	addiw	a5,a5,1
    80002270:	0721                	addi	a4,a4,8
    80002272:	02c78163          	beq	a5,a2,80002294 <received_continue+0x68>
      if( (pending_and_not_blocked & (1 << signum)) &&
    80002276:	40f6d4bb          	sraw	s1,a3,a5
    8000227a:	8885                	andi	s1,s1,1
    8000227c:	d8ed                	beqz	s1,8000226e <received_continue+0x42>
    8000227e:	0d093583          	ld	a1,208(s2)
    80002282:	f1fd                	bnez	a1,80002268 <received_continue+0x3c>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002284:	fea792e3          	bne	a5,a0,80002268 <received_continue+0x3c>
            release(&p->lock);
    80002288:	854a                	mv	a0,s2
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	9ec080e7          	jalr	-1556(ra) # 80000c76 <release>
            return 1;
    80002292:	a039                	j	800022a0 <received_continue+0x74>
    release(&p->lock);
    80002294:	854a                	mv	a0,s2
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	9e0080e7          	jalr	-1568(ra) # 80000c76 <release>
    return 0;
    8000229e:	4481                	li	s1,0
}
    800022a0:	8526                	mv	a0,s1
    800022a2:	60e2                	ld	ra,24(sp)
    800022a4:	6442                	ld	s0,16(sp)
    800022a6:	64a2                	ld	s1,8(sp)
    800022a8:	6902                	ld	s2,0(sp)
    800022aa:	6105                	addi	sp,sp,32
    800022ac:	8082                	ret

00000000800022ae <continue_handler>:
{
    800022ae:	1141                	addi	sp,sp,-16
    800022b0:	e406                	sd	ra,8(sp)
    800022b2:	e022                	sd	s0,0(sp)
    800022b4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	7a0080e7          	jalr	1952(ra) # 80001a56 <myproc>
  p->stopped = 0;
    800022be:	1c052023          	sw	zero,448(a0)
}
    800022c2:	60a2                	ld	ra,8(sp)
    800022c4:	6402                	ld	s0,0(sp)
    800022c6:	0141                	addi	sp,sp,16
    800022c8:	8082                	ret

00000000800022ca <handle_user_signals>:
handle_user_signals(int signum) {
    800022ca:	7179                	addi	sp,sp,-48
    800022cc:	f406                	sd	ra,40(sp)
    800022ce:	f022                	sd	s0,32(sp)
    800022d0:	ec26                	sd	s1,24(sp)
    800022d2:	e84a                	sd	s2,16(sp)
    800022d4:	e44e                	sd	s3,8(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	892a                	mv	s2,a0
  struct thread *t = mythread();
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	7b6080e7          	jalr	1974(ra) # 80001a90 <mythread>
    800022e2:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	772080e7          	jalr	1906(ra) # 80001a56 <myproc>
    800022ec:	84aa                	mv	s1,a0
  p->signal_mask_backup = p->signal_mask;
    800022ee:	555c                	lw	a5,44(a0)
    800022f0:	d91c                	sw	a5,48(a0)
  p->signal_mask = p->signal_handlers_masks[signum];  
    800022f2:	04c90793          	addi	a5,s2,76
    800022f6:	078a                	slli	a5,a5,0x2
    800022f8:	97aa                	add	a5,a5,a0
    800022fa:	479c                	lw	a5,8(a5)
    800022fc:	d55c                	sw	a5,44(a0)
  memmove(p->trapframe_backup, t->trapframe, sizeof(struct trapframe));
    800022fe:	12000613          	li	a2,288
    80002302:	0489b583          	ld	a1,72(s3)
    80002306:	1b853503          	ld	a0,440(a0)
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	a10080e7          	jalr	-1520(ra) # 80000d1a <memmove>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    80002312:	0489b703          	ld	a4,72(s3)
  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
    80002316:	00006617          	auipc	a2,0x6
    8000231a:	dfc60613          	addi	a2,a2,-516 # 80008112 <start_inject_sigret>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    8000231e:	00006697          	auipc	a3,0x6
    80002322:	dfa68693          	addi	a3,a3,-518 # 80008118 <end_inject_sigret>
    80002326:	9e91                	subw	a3,a3,a2
    80002328:	7b1c                	ld	a5,48(a4)
    8000232a:	8f95                	sub	a5,a5,a3
    8000232c:	fb1c                	sd	a5,48(a4)
  copyout(p->pagetable, (uint64) (t->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);
    8000232e:	0489b783          	ld	a5,72(s3)
    80002332:	7b8c                	ld	a1,48(a5)
    80002334:	1d84b503          	ld	a0,472(s1)
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	306080e7          	jalr	774(ra) # 8000163e <copyout>
  t->trapframe->a0 = signum;
    80002340:	0489b783          	ld	a5,72(s3)
    80002344:	0727b823          	sd	s2,112(a5)
  t->trapframe->epc = (uint64)p->signal_handlers[signum];
    80002348:	0489b783          	ld	a5,72(s3)
    8000234c:	0919                	addi	s2,s2,6
    8000234e:	090e                	slli	s2,s2,0x3
    80002350:	94ca                	add	s1,s1,s2
    80002352:	6498                	ld	a4,8(s1)
    80002354:	ef98                	sd	a4,24(a5)
  t->trapframe->ra = t->trapframe->sp;
    80002356:	0489b783          	ld	a5,72(s3)
    8000235a:	7b98                	ld	a4,48(a5)
    8000235c:	f798                	sd	a4,40(a5)
}
    8000235e:	70a2                	ld	ra,40(sp)
    80002360:	7402                	ld	s0,32(sp)
    80002362:	64e2                	ld	s1,24(sp)
    80002364:	6942                	ld	s2,16(sp)
    80002366:	69a2                	ld	s3,8(sp)
    80002368:	6145                	addi	sp,sp,48
    8000236a:	8082                	ret

000000008000236c <scheduler>:
{
    8000236c:	715d                	addi	sp,sp,-80
    8000236e:	e486                	sd	ra,72(sp)
    80002370:	e0a2                	sd	s0,64(sp)
    80002372:	fc26                	sd	s1,56(sp)
    80002374:	f84a                	sd	s2,48(sp)
    80002376:	f44e                	sd	s3,40(sp)
    80002378:	f052                	sd	s4,32(sp)
    8000237a:	ec56                	sd	s5,24(sp)
    8000237c:	e85a                	sd	s6,16(sp)
    8000237e:	e45e                	sd	s7,8(sp)
    80002380:	e062                	sd	s8,0(sp)
    80002382:	0880                	addi	s0,sp,80
    80002384:	8792                	mv	a5,tp
  int id = r_tp();
    80002386:	2781                	sext.w	a5,a5
  c->thread = 0;
    80002388:	00779a93          	slli	s5,a5,0x7
    8000238c:	00010717          	auipc	a4,0x10
    80002390:	f1470713          	addi	a4,a4,-236 # 800122a0 <pid_lock>
    80002394:	9756                	add	a4,a4,s5
    80002396:	06073023          	sd	zero,96(a4)
          swtch(&c->context, &t->context);
    8000239a:	00010717          	auipc	a4,0x10
    8000239e:	f6e70713          	addi	a4,a4,-146 # 80012308 <cpus+0x8>
    800023a2:	9aba                	add	s5,s5,a4
    800023a4:	00034c17          	auipc	s8,0x34
    800023a8:	fd4c0c13          	addi	s8,s8,-44 # 80036378 <bcache+0x860>
          t->state = RUNNING;
    800023ac:	4b11                	li	s6,4
          c->thread = t;
    800023ae:	079e                	slli	a5,a5,0x7
    800023b0:	00010a17          	auipc	s4,0x10
    800023b4:	ef0a0a13          	addi	s4,s4,-272 # 800122a0 <pid_lock>
    800023b8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800023ba:	6b85                	lui	s7,0x1
    800023bc:	880b8b93          	addi	s7,s7,-1920 # 880 <_entry-0x7ffff780>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023c0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023c4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023c8:	10079073          	csrw	sstatus,a5
    800023cc:	00012917          	auipc	s2,0x12
    800023d0:	fac90913          	addi	s2,s2,-84 # 80014378 <proc+0x878>
        if(t->state == RUNNABLE) {
    800023d4:	498d                	li	s3,3
    800023d6:	a099                	j	8000241c <scheduler+0xb0>
        release(&t->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	89c080e7          	jalr	-1892(ra) # 80000c76 <release>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800023e2:	0c048493          	addi	s1,s1,192
    800023e6:	03248863          	beq	s1,s2,80002416 <scheduler+0xaa>
        acquire(&t->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	7d6080e7          	jalr	2006(ra) # 80000bc2 <acquire>
        if(t->state == RUNNABLE) {
    800023f4:	4c9c                	lw	a5,24(s1)
    800023f6:	ff3791e3          	bne	a5,s3,800023d8 <scheduler+0x6c>
          t->state = RUNNING;
    800023fa:	0164ac23          	sw	s6,24(s1)
          c->thread = t;
    800023fe:	069a3023          	sd	s1,96(s4)
          swtch(&c->context, &t->context);
    80002402:	05048593          	addi	a1,s1,80
    80002406:	8556                	mv	a0,s5
    80002408:	00001097          	auipc	ra,0x1
    8000240c:	00c080e7          	jalr	12(ra) # 80003414 <swtch>
          c->thread = 0;
    80002410:	060a3023          	sd	zero,96(s4)
    80002414:	b7d1                	j	800023d8 <scheduler+0x6c>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002416:	995e                	add	s2,s2,s7
    80002418:	fb8904e3          	beq	s2,s8,800023c0 <scheduler+0x54>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000241c:	a0090493          	addi	s1,s2,-1536
    80002420:	b7e9                	j	800023ea <scheduler+0x7e>

0000000080002422 <sched>:
{
    80002422:	7179                	addi	sp,sp,-48
    80002424:	f406                	sd	ra,40(sp)
    80002426:	f022                	sd	s0,32(sp)
    80002428:	ec26                	sd	s1,24(sp)
    8000242a:	e84a                	sd	s2,16(sp)
    8000242c:	e44e                	sd	s3,8(sp)
    8000242e:	1800                	addi	s0,sp,48
  struct thread *t = mythread();
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	660080e7          	jalr	1632(ra) # 80001a90 <mythread>
    80002438:	84aa                	mv	s1,a0
  if(!holding(&t->lock))
    8000243a:	ffffe097          	auipc	ra,0xffffe
    8000243e:	70e080e7          	jalr	1806(ra) # 80000b48 <holding>
    80002442:	c93d                	beqz	a0,800024b8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002444:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002446:	2781                	sext.w	a5,a5
    80002448:	079e                	slli	a5,a5,0x7
    8000244a:	00010717          	auipc	a4,0x10
    8000244e:	e5670713          	addi	a4,a4,-426 # 800122a0 <pid_lock>
    80002452:	97ba                	add	a5,a5,a4
    80002454:	0d87a703          	lw	a4,216(a5)
    80002458:	4785                	li	a5,1
    8000245a:	06f71763          	bne	a4,a5,800024c8 <sched+0xa6>
  if(t->state == RUNNING)
    8000245e:	4c98                	lw	a4,24(s1)
    80002460:	4791                	li	a5,4
    80002462:	06f70b63          	beq	a4,a5,800024d8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002466:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000246a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000246c:	efb5                	bnez	a5,800024e8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000246e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002470:	00010917          	auipc	s2,0x10
    80002474:	e3090913          	addi	s2,s2,-464 # 800122a0 <pid_lock>
    80002478:	2781                	sext.w	a5,a5
    8000247a:	079e                	slli	a5,a5,0x7
    8000247c:	97ca                	add	a5,a5,s2
    8000247e:	0dc7a983          	lw	s3,220(a5)
    80002482:	8792                	mv	a5,tp
  swtch(&t->context, &mycpu()->context);
    80002484:	2781                	sext.w	a5,a5
    80002486:	079e                	slli	a5,a5,0x7
    80002488:	00010597          	auipc	a1,0x10
    8000248c:	e8058593          	addi	a1,a1,-384 # 80012308 <cpus+0x8>
    80002490:	95be                	add	a1,a1,a5
    80002492:	05048513          	addi	a0,s1,80
    80002496:	00001097          	auipc	ra,0x1
    8000249a:	f7e080e7          	jalr	-130(ra) # 80003414 <swtch>
    8000249e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800024a0:	2781                	sext.w	a5,a5
    800024a2:	079e                	slli	a5,a5,0x7
    800024a4:	97ca                	add	a5,a5,s2
    800024a6:	0d37ae23          	sw	s3,220(a5)
}
    800024aa:	70a2                	ld	ra,40(sp)
    800024ac:	7402                	ld	s0,32(sp)
    800024ae:	64e2                	ld	s1,24(sp)
    800024b0:	6942                	ld	s2,16(sp)
    800024b2:	69a2                	ld	s3,8(sp)
    800024b4:	6145                	addi	sp,sp,48
    800024b6:	8082                	ret
    panic("sched t->lock");
    800024b8:	00007517          	auipc	a0,0x7
    800024bc:	d8050513          	addi	a0,a0,-640 # 80009238 <digits+0x1f8>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	06a080e7          	jalr	106(ra) # 8000052a <panic>
    panic("sched locks\n");
    800024c8:	00007517          	auipc	a0,0x7
    800024cc:	d8050513          	addi	a0,a0,-640 # 80009248 <digits+0x208>
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	05a080e7          	jalr	90(ra) # 8000052a <panic>
    panic("sched running");
    800024d8:	00007517          	auipc	a0,0x7
    800024dc:	d8050513          	addi	a0,a0,-640 # 80009258 <digits+0x218>
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    panic("sched interruptible");
    800024e8:	00007517          	auipc	a0,0x7
    800024ec:	d8050513          	addi	a0,a0,-640 # 80009268 <digits+0x228>
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	03a080e7          	jalr	58(ra) # 8000052a <panic>

00000000800024f8 <yield>:
{
    800024f8:	1101                	addi	sp,sp,-32
    800024fa:	ec06                	sd	ra,24(sp)
    800024fc:	e822                	sd	s0,16(sp)
    800024fe:	e426                	sd	s1,8(sp)
    80002500:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	58e080e7          	jalr	1422(ra) # 80001a90 <mythread>
    8000250a:	84aa                	mv	s1,a0
  acquire(&t->lock);
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	6b6080e7          	jalr	1718(ra) # 80000bc2 <acquire>
  t->state = RUNNABLE;
    80002514:	478d                	li	a5,3
    80002516:	cc9c                	sw	a5,24(s1)
  sched();
    80002518:	00000097          	auipc	ra,0x0
    8000251c:	f0a080e7          	jalr	-246(ra) # 80002422 <sched>
  release(&t->lock);
    80002520:	8526                	mv	a0,s1
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	754080e7          	jalr	1876(ra) # 80000c76 <release>
}
    8000252a:	60e2                	ld	ra,24(sp)
    8000252c:	6442                	ld	s0,16(sp)
    8000252e:	64a2                	ld	s1,8(sp)
    80002530:	6105                	addi	sp,sp,32
    80002532:	8082                	ret

0000000080002534 <stop_handler>:
{
    80002534:	1101                	addi	sp,sp,-32
    80002536:	ec06                	sd	ra,24(sp)
    80002538:	e822                	sd	s0,16(sp)
    8000253a:	e426                	sd	s1,8(sp)
    8000253c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	518080e7          	jalr	1304(ra) # 80001a56 <myproc>
    80002546:	84aa                	mv	s1,a0
  p->stopped = 1;
    80002548:	4785                	li	a5,1
    8000254a:	1cf52023          	sw	a5,448(a0)
  release(&p->lock);
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	728080e7          	jalr	1832(ra) # 80000c76 <release>
  while (p->stopped && !received_continue())
    80002556:	1c04a783          	lw	a5,448(s1)
    8000255a:	cf89                	beqz	a5,80002574 <stop_handler+0x40>
    8000255c:	00000097          	auipc	ra,0x0
    80002560:	cd0080e7          	jalr	-816(ra) # 8000222c <received_continue>
    80002564:	e901                	bnez	a0,80002574 <stop_handler+0x40>
      yield();
    80002566:	00000097          	auipc	ra,0x0
    8000256a:	f92080e7          	jalr	-110(ra) # 800024f8 <yield>
  while (p->stopped && !received_continue())
    8000256e:	1c04a783          	lw	a5,448(s1)
    80002572:	f7ed                	bnez	a5,8000255c <stop_handler+0x28>
  acquire(&p->lock);
    80002574:	8526                	mv	a0,s1
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	64c080e7          	jalr	1612(ra) # 80000bc2 <acquire>
}
    8000257e:	60e2                	ld	ra,24(sp)
    80002580:	6442                	ld	s0,16(sp)
    80002582:	64a2                	ld	s1,8(sp)
    80002584:	6105                	addi	sp,sp,32
    80002586:	8082                	ret

0000000080002588 <handle_signals>:
{
    80002588:	711d                	addi	sp,sp,-96
    8000258a:	ec86                	sd	ra,88(sp)
    8000258c:	e8a2                	sd	s0,80(sp)
    8000258e:	e4a6                	sd	s1,72(sp)
    80002590:	e0ca                	sd	s2,64(sp)
    80002592:	fc4e                	sd	s3,56(sp)
    80002594:	f852                	sd	s4,48(sp)
    80002596:	f456                	sd	s5,40(sp)
    80002598:	f05a                	sd	s6,32(sp)
    8000259a:	ec5e                	sd	s7,24(sp)
    8000259c:	e862                	sd	s8,16(sp)
    8000259e:	e466                	sd	s9,8(sp)
    800025a0:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    800025a2:	fffff097          	auipc	ra,0xfffff
    800025a6:	4b4080e7          	jalr	1204(ra) # 80001a56 <myproc>
    800025aa:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	616080e7          	jalr	1558(ra) # 80000bc2 <acquire>
  for(int signum = 0; signum < SIG_NUM; signum++){
    800025b4:	03890993          	addi	s3,s2,56
    800025b8:	4481                	li	s1,0
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025ba:	4b05                	li	s6,1
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800025bc:	4ac5                	li	s5,17
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800025be:	4bcd                	li	s7,19
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    800025c0:	4c25                	li	s8,9
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    800025c2:	4c85                	li	s9,1
  for(int signum = 0; signum < SIG_NUM; signum++){
    800025c4:	02000a13          	li	s4,32
    800025c8:	a0a1                	j	80002610 <handle_signals+0x88>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800025ca:	03548263          	beq	s1,s5,800025ee <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800025ce:	09748b63          	beq	s1,s7,80002664 <handle_signals+0xdc>
        kill_handler();
    800025d2:	00000097          	auipc	ra,0x0
    800025d6:	c1a080e7          	jalr	-998(ra) # 800021ec <kill_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025da:	009b17bb          	sllw	a5,s6,s1
    800025de:	fff7c793          	not	a5,a5
    800025e2:	02892703          	lw	a4,40(s2)
    800025e6:	8ff9                	and	a5,a5,a4
    800025e8:	02f92423          	sw	a5,40(s2)
    800025ec:	a831                	j	80002608 <handle_signals+0x80>
        stop_handler();
    800025ee:	00000097          	auipc	ra,0x0
    800025f2:	f46080e7          	jalr	-186(ra) # 80002534 <stop_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025f6:	009b17bb          	sllw	a5,s6,s1
    800025fa:	fff7c793          	not	a5,a5
    800025fe:	02892703          	lw	a4,40(s2)
    80002602:	8ff9                	and	a5,a5,a4
    80002604:	02f92423          	sw	a5,40(s2)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80002608:	2485                	addiw	s1,s1,1
    8000260a:	09a1                	addi	s3,s3,8
    8000260c:	09448263          	beq	s1,s4,80002690 <handle_signals+0x108>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    80002610:	02892703          	lw	a4,40(s2)
    80002614:	02c92783          	lw	a5,44(s2)
    80002618:	fff7c793          	not	a5,a5
    8000261c:	8ff9                	and	a5,a5,a4
    if(pending_and_not_blocked & (1 << signum)){
    8000261e:	4097d7bb          	sraw	a5,a5,s1
    80002622:	8b85                	andi	a5,a5,1
    80002624:	d3f5                	beqz	a5,80002608 <handle_signals+0x80>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    80002626:	0009b783          	ld	a5,0(s3)
    8000262a:	d3c5                	beqz	a5,800025ca <handle_signals+0x42>
    8000262c:	fd5781e3          	beq	a5,s5,800025ee <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    80002630:	03778a63          	beq	a5,s7,80002664 <handle_signals+0xdc>
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    80002634:	f9878fe3          	beq	a5,s8,800025d2 <handle_signals+0x4a>
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    80002638:	05978463          	beq	a5,s9,80002680 <handle_signals+0xf8>
      } else if (p->handling_user_level_signal == 0){
    8000263c:	1c492783          	lw	a5,452(s2)
    80002640:	f7e1                	bnez	a5,80002608 <handle_signals+0x80>
        p->handling_user_level_signal = 1;
    80002642:	1d992223          	sw	s9,452(s2)
        handle_user_signals(signum);
    80002646:	8526                	mv	a0,s1
    80002648:	00000097          	auipc	ra,0x0
    8000264c:	c82080e7          	jalr	-894(ra) # 800022ca <handle_user_signals>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002650:	009b17bb          	sllw	a5,s6,s1
    80002654:	fff7c793          	not	a5,a5
    80002658:	02892703          	lw	a4,40(s2)
    8000265c:	8ff9                	and	a5,a5,a4
    8000265e:	02f92423          	sw	a5,40(s2)
    80002662:	b75d                	j	80002608 <handle_signals+0x80>
        continue_handler();
    80002664:	00000097          	auipc	ra,0x0
    80002668:	c4a080e7          	jalr	-950(ra) # 800022ae <continue_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000266c:	009b17bb          	sllw	a5,s6,s1
    80002670:	fff7c793          	not	a5,a5
    80002674:	02892703          	lw	a4,40(s2)
    80002678:	8ff9                	and	a5,a5,a4
    8000267a:	02f92423          	sw	a5,40(s2)
    8000267e:	b769                	j	80002608 <handle_signals+0x80>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002680:	009b17bb          	sllw	a5,s6,s1
    80002684:	fff7c793          	not	a5,a5
    80002688:	8f7d                	and	a4,a4,a5
    8000268a:	02e92423          	sw	a4,40(s2)
    8000268e:	bfad                	j	80002608 <handle_signals+0x80>
  release(&p->lock);
    80002690:	854a                	mv	a0,s2
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	5e4080e7          	jalr	1508(ra) # 80000c76 <release>
}
    8000269a:	60e6                	ld	ra,88(sp)
    8000269c:	6446                	ld	s0,80(sp)
    8000269e:	64a6                	ld	s1,72(sp)
    800026a0:	6906                	ld	s2,64(sp)
    800026a2:	79e2                	ld	s3,56(sp)
    800026a4:	7a42                	ld	s4,48(sp)
    800026a6:	7aa2                	ld	s5,40(sp)
    800026a8:	7b02                	ld	s6,32(sp)
    800026aa:	6be2                	ld	s7,24(sp)
    800026ac:	6c42                	ld	s8,16(sp)
    800026ae:	6ca2                	ld	s9,8(sp)
    800026b0:	6125                	addi	sp,sp,96
    800026b2:	8082                	ret

00000000800026b4 <sleep>:
// ADDED Q3
// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800026b4:	7179                	addi	sp,sp,-48
    800026b6:	f406                	sd	ra,40(sp)
    800026b8:	f022                	sd	s0,32(sp)
    800026ba:	ec26                	sd	s1,24(sp)
    800026bc:	e84a                	sd	s2,16(sp)
    800026be:	e44e                	sd	s3,8(sp)
    800026c0:	1800                	addi	s0,sp,48
    800026c2:	89aa                	mv	s3,a0
    800026c4:	892e                	mv	s2,a1
  struct thread *t = mythread();
    800026c6:	fffff097          	auipc	ra,0xfffff
    800026ca:	3ca080e7          	jalr	970(ra) # 80001a90 <mythread>
    800026ce:	84aa                	mv	s1,a0
  // Once we hold t->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks t->lock),
  // so it's okay to release lk.

  acquire(&t->lock);  //DOC: sleeplock1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	4f2080e7          	jalr	1266(ra) # 80000bc2 <acquire>
  release(lk);
    800026d8:	854a                	mv	a0,s2
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	59c080e7          	jalr	1436(ra) # 80000c76 <release>

  // Go to sleep.
  t->chan = chan;
    800026e2:	0334b023          	sd	s3,32(s1)
  t->state = SLEEPING;
    800026e6:	4789                	li	a5,2
    800026e8:	cc9c                	sw	a5,24(s1)

  sched();
    800026ea:	00000097          	auipc	ra,0x0
    800026ee:	d38080e7          	jalr	-712(ra) # 80002422 <sched>

  // Tidy up.
  t->chan = 0;
    800026f2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&t->lock);
    800026f6:	8526                	mv	a0,s1
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	57e080e7          	jalr	1406(ra) # 80000c76 <release>
  acquire(lk);
    80002700:	854a                	mv	a0,s2
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	4c0080e7          	jalr	1216(ra) # 80000bc2 <acquire>
}
    8000270a:	70a2                	ld	ra,40(sp)
    8000270c:	7402                	ld	s0,32(sp)
    8000270e:	64e2                	ld	s1,24(sp)
    80002710:	6942                	ld	s2,16(sp)
    80002712:	69a2                	ld	s3,8(sp)
    80002714:	6145                	addi	sp,sp,48
    80002716:	8082                	ret

0000000080002718 <wait>:
{
    80002718:	715d                	addi	sp,sp,-80
    8000271a:	e486                	sd	ra,72(sp)
    8000271c:	e0a2                	sd	s0,64(sp)
    8000271e:	fc26                	sd	s1,56(sp)
    80002720:	f84a                	sd	s2,48(sp)
    80002722:	f44e                	sd	s3,40(sp)
    80002724:	f052                	sd	s4,32(sp)
    80002726:	ec56                	sd	s5,24(sp)
    80002728:	e85a                	sd	s6,16(sp)
    8000272a:	e45e                	sd	s7,8(sp)
    8000272c:	0880                	addi	s0,sp,80
    8000272e:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002730:	fffff097          	auipc	ra,0xfffff
    80002734:	326080e7          	jalr	806(ra) # 80001a56 <myproc>
    80002738:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000273a:	00010517          	auipc	a0,0x10
    8000273e:	b9650513          	addi	a0,a0,-1130 # 800122d0 <wait_lock>
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	480080e7          	jalr	1152(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000274a:	4a89                	li	s5,2
        havekids = 1;
    8000274c:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000274e:	6985                	lui	s3,0x1
    80002750:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80002754:	00033a17          	auipc	s4,0x33
    80002758:	3aca0a13          	addi	s4,s4,940 # 80035b00 <tickslock>
    havekids = 0;
    8000275c:	4701                	li	a4,0
    for(np = proc; np < &proc[NPROC]; np++){
    8000275e:	00011497          	auipc	s1,0x11
    80002762:	3a248493          	addi	s1,s1,930 # 80013b00 <proc>
    80002766:	a0b5                	j	800027d2 <wait+0xba>
          pid = np->pid;
    80002768:	0244a983          	lw	s3,36(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000276c:	000b8e63          	beqz	s7,80002788 <wait+0x70>
    80002770:	4691                	li	a3,4
    80002772:	02048613          	addi	a2,s1,32
    80002776:	85de                	mv	a1,s7
    80002778:	1d893503          	ld	a0,472(s2)
    8000277c:	fffff097          	auipc	ra,0xfffff
    80002780:	ec2080e7          	jalr	-318(ra) # 8000163e <copyout>
    80002784:	02054563          	bltz	a0,800027ae <wait+0x96>
          freeproc(np);
    80002788:	8526                	mv	a0,s1
    8000278a:	fffff097          	auipc	ra,0xfffff
    8000278e:	5e0080e7          	jalr	1504(ra) # 80001d6a <freeproc>
          release(&np->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	4e2080e7          	jalr	1250(ra) # 80000c76 <release>
          release(&wait_lock);
    8000279c:	00010517          	auipc	a0,0x10
    800027a0:	b3450513          	addi	a0,a0,-1228 # 800122d0 <wait_lock>
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4d2080e7          	jalr	1234(ra) # 80000c76 <release>
          return pid;
    800027ac:	a09d                	j	80002812 <wait+0xfa>
            release(&np->lock);
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	4c6080e7          	jalr	1222(ra) # 80000c76 <release>
            release(&wait_lock);
    800027b8:	00010517          	auipc	a0,0x10
    800027bc:	b1850513          	addi	a0,a0,-1256 # 800122d0 <wait_lock>
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	4b6080e7          	jalr	1206(ra) # 80000c76 <release>
            return -1;
    800027c8:	59fd                	li	s3,-1
    800027ca:	a0a1                	j	80002812 <wait+0xfa>
    for(np = proc; np < &proc[NPROC]; np++){
    800027cc:	94ce                	add	s1,s1,s3
    800027ce:	03448563          	beq	s1,s4,800027f8 <wait+0xe0>
      if(np->parent == p){
    800027d2:	1c84b783          	ld	a5,456(s1)
    800027d6:	ff279be3          	bne	a5,s2,800027cc <wait+0xb4>
        acquire(&np->lock);
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	3e6080e7          	jalr	998(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800027e4:	4c9c                	lw	a5,24(s1)
    800027e6:	f95781e3          	beq	a5,s5,80002768 <wait+0x50>
        release(&np->lock);
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	48a080e7          	jalr	1162(ra) # 80000c76 <release>
        havekids = 1;
    800027f4:	875a                	mv	a4,s6
    800027f6:	bfd9                	j	800027cc <wait+0xb4>
    if(!havekids || p->killed){
    800027f8:	c701                	beqz	a4,80002800 <wait+0xe8>
    800027fa:	01c92783          	lw	a5,28(s2)
    800027fe:	c795                	beqz	a5,8000282a <wait+0x112>
      release(&wait_lock);
    80002800:	00010517          	auipc	a0,0x10
    80002804:	ad050513          	addi	a0,a0,-1328 # 800122d0 <wait_lock>
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	46e080e7          	jalr	1134(ra) # 80000c76 <release>
      return -1;
    80002810:	59fd                	li	s3,-1
}
    80002812:	854e                	mv	a0,s3
    80002814:	60a6                	ld	ra,72(sp)
    80002816:	6406                	ld	s0,64(sp)
    80002818:	74e2                	ld	s1,56(sp)
    8000281a:	7942                	ld	s2,48(sp)
    8000281c:	79a2                	ld	s3,40(sp)
    8000281e:	7a02                	ld	s4,32(sp)
    80002820:	6ae2                	ld	s5,24(sp)
    80002822:	6b42                	ld	s6,16(sp)
    80002824:	6ba2                	ld	s7,8(sp)
    80002826:	6161                	addi	sp,sp,80
    80002828:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000282a:	00010597          	auipc	a1,0x10
    8000282e:	aa658593          	addi	a1,a1,-1370 # 800122d0 <wait_lock>
    80002832:	854a                	mv	a0,s2
    80002834:	00000097          	auipc	ra,0x0
    80002838:	e80080e7          	jalr	-384(ra) # 800026b4 <sleep>
    havekids = 0;
    8000283c:	b705                	j	8000275c <wait+0x44>

000000008000283e <wakeup>:
// Wake up all threads sleeping on chan.
// Must be called without any t->lock.
// ADDED Q3
void
wakeup(void *chan)
{
    8000283e:	715d                	addi	sp,sp,-80
    80002840:	e486                	sd	ra,72(sp)
    80002842:	e0a2                	sd	s0,64(sp)
    80002844:	fc26                	sd	s1,56(sp)
    80002846:	f84a                	sd	s2,48(sp)
    80002848:	f44e                	sd	s3,40(sp)
    8000284a:	f052                	sd	s4,32(sp)
    8000284c:	ec56                	sd	s5,24(sp)
    8000284e:	e85a                	sd	s6,16(sp)
    80002850:	e45e                	sd	s7,8(sp)
    80002852:	0880                	addi	s0,sp,80
    80002854:	8a2a                	mv	s4,a0
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    80002856:	00012917          	auipc	s2,0x12
    8000285a:	b2290913          	addi	s2,s2,-1246 # 80014378 <proc+0x878>
    8000285e:	00034b17          	auipc	s6,0x34
    80002862:	b1ab0b13          	addi	s6,s6,-1254 # 80036378 <bcache+0x860>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
      if(t != mythread()){
        acquire(&t->lock);
        if (t->state == SLEEPING && t->chan == chan) {
    80002866:	4989                	li	s3,2
          t->state = RUNNABLE;
    80002868:	4b8d                	li	s7,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000286a:	6a85                	lui	s5,0x1
    8000286c:	880a8a93          	addi	s5,s5,-1920 # 880 <_entry-0x7ffff780>
    80002870:	a089                	j	800028b2 <wakeup+0x74>
        }
        release(&t->lock);
    80002872:	8526                	mv	a0,s1
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	402080e7          	jalr	1026(ra) # 80000c76 <release>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000287c:	0c048493          	addi	s1,s1,192
    80002880:	03248663          	beq	s1,s2,800028ac <wakeup+0x6e>
      if(t != mythread()){
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	20c080e7          	jalr	524(ra) # 80001a90 <mythread>
    8000288c:	fea488e3          	beq	s1,a0,8000287c <wakeup+0x3e>
        acquire(&t->lock);
    80002890:	8526                	mv	a0,s1
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	330080e7          	jalr	816(ra) # 80000bc2 <acquire>
        if (t->state == SLEEPING && t->chan == chan) {
    8000289a:	4c9c                	lw	a5,24(s1)
    8000289c:	fd379be3          	bne	a5,s3,80002872 <wakeup+0x34>
    800028a0:	709c                	ld	a5,32(s1)
    800028a2:	fd4798e3          	bne	a5,s4,80002872 <wakeup+0x34>
          t->state = RUNNABLE;
    800028a6:	0174ac23          	sw	s7,24(s1)
    800028aa:	b7e1                	j	80002872 <wakeup+0x34>
  for(p = proc; p < &proc[NPROC]; p++) {
    800028ac:	9956                	add	s2,s2,s5
    800028ae:	01690563          	beq	s2,s6,800028b8 <wakeup+0x7a>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800028b2:	a0090493          	addi	s1,s2,-1536
    800028b6:	b7f9                	j	80002884 <wakeup+0x46>
      }
    }
  }
}
    800028b8:	60a6                	ld	ra,72(sp)
    800028ba:	6406                	ld	s0,64(sp)
    800028bc:	74e2                	ld	s1,56(sp)
    800028be:	7942                	ld	s2,48(sp)
    800028c0:	79a2                	ld	s3,40(sp)
    800028c2:	7a02                	ld	s4,32(sp)
    800028c4:	6ae2                	ld	s5,24(sp)
    800028c6:	6b42                	ld	s6,16(sp)
    800028c8:	6ba2                	ld	s7,8(sp)
    800028ca:	6161                	addi	sp,sp,80
    800028cc:	8082                	ret

00000000800028ce <reparent>:
{
    800028ce:	7139                	addi	sp,sp,-64
    800028d0:	fc06                	sd	ra,56(sp)
    800028d2:	f822                	sd	s0,48(sp)
    800028d4:	f426                	sd	s1,40(sp)
    800028d6:	f04a                	sd	s2,32(sp)
    800028d8:	ec4e                	sd	s3,24(sp)
    800028da:	e852                	sd	s4,16(sp)
    800028dc:	e456                	sd	s5,8(sp)
    800028de:	0080                	addi	s0,sp,64
    800028e0:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028e2:	00011497          	auipc	s1,0x11
    800028e6:	21e48493          	addi	s1,s1,542 # 80013b00 <proc>
      pp->parent = initproc;
    800028ea:	00007a97          	auipc	s5,0x7
    800028ee:	73ea8a93          	addi	s5,s5,1854 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028f2:	6905                	lui	s2,0x1
    800028f4:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    800028f8:	00033a17          	auipc	s4,0x33
    800028fc:	208a0a13          	addi	s4,s4,520 # 80035b00 <tickslock>
    80002900:	a021                	j	80002908 <reparent+0x3a>
    80002902:	94ca                	add	s1,s1,s2
    80002904:	01448f63          	beq	s1,s4,80002922 <reparent+0x54>
    if(pp->parent == p){
    80002908:	1c84b783          	ld	a5,456(s1)
    8000290c:	ff379be3          	bne	a5,s3,80002902 <reparent+0x34>
      pp->parent = initproc;
    80002910:	000ab503          	ld	a0,0(s5)
    80002914:	1ca4b423          	sd	a0,456(s1)
      wakeup(initproc);
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	f26080e7          	jalr	-218(ra) # 8000283e <wakeup>
    80002920:	b7cd                	j	80002902 <reparent+0x34>
}
    80002922:	70e2                	ld	ra,56(sp)
    80002924:	7442                	ld	s0,48(sp)
    80002926:	74a2                	ld	s1,40(sp)
    80002928:	7902                	ld	s2,32(sp)
    8000292a:	69e2                	ld	s3,24(sp)
    8000292c:	6a42                	ld	s4,16(sp)
    8000292e:	6aa2                	ld	s5,8(sp)
    80002930:	6121                	addi	sp,sp,64
    80002932:	8082                	ret

0000000080002934 <kill>:
// ADDED Q2.2.1
int
kill(int pid, int signum)
{
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    80002934:	47fd                	li	a5,31
    80002936:	06b7ef63          	bltu	a5,a1,800029b4 <kill+0x80>
{
    8000293a:	7139                	addi	sp,sp,-64
    8000293c:	fc06                	sd	ra,56(sp)
    8000293e:	f822                	sd	s0,48(sp)
    80002940:	f426                	sd	s1,40(sp)
    80002942:	f04a                	sd	s2,32(sp)
    80002944:	ec4e                	sd	s3,24(sp)
    80002946:	e852                	sd	s4,16(sp)
    80002948:	e456                	sd	s5,8(sp)
    8000294a:	0080                	addi	s0,sp,64
    8000294c:	892a                	mv	s2,a0
    8000294e:	8aae                	mv	s5,a1
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002950:	00011497          	auipc	s1,0x11
    80002954:	1b048493          	addi	s1,s1,432 # 80013b00 <proc>
    80002958:	6985                	lui	s3,0x1
    8000295a:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    8000295e:	00033a17          	auipc	s4,0x33
    80002962:	1a2a0a13          	addi	s4,s4,418 # 80035b00 <tickslock>
    acquire(&p->lock);
    80002966:	8526                	mv	a0,s1
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	25a080e7          	jalr	602(ra) # 80000bc2 <acquire>
    if(p->pid == pid) {
    80002970:	50dc                	lw	a5,36(s1)
    80002972:	01278c63          	beq	a5,s2,8000298a <kill+0x56>
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002976:	8526                	mv	a0,s1
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	2fe080e7          	jalr	766(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002980:	94ce                	add	s1,s1,s3
    80002982:	ff4492e3          	bne	s1,s4,80002966 <kill+0x32>
  }
  // no such pid
  return -1;
    80002986:	557d                	li	a0,-1
    80002988:	a829                	j	800029a2 <kill+0x6e>
      p->pending_signals = p->pending_signals | (1 << signum);
    8000298a:	4785                	li	a5,1
    8000298c:	0157973b          	sllw	a4,a5,s5
    80002990:	549c                	lw	a5,40(s1)
    80002992:	8fd9                	or	a5,a5,a4
    80002994:	d49c                	sw	a5,40(s1)
      release(&p->lock);
    80002996:	8526                	mv	a0,s1
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	2de080e7          	jalr	734(ra) # 80000c76 <release>
      return 0;
    800029a0:	4501                	li	a0,0
}
    800029a2:	70e2                	ld	ra,56(sp)
    800029a4:	7442                	ld	s0,48(sp)
    800029a6:	74a2                	ld	s1,40(sp)
    800029a8:	7902                	ld	s2,32(sp)
    800029aa:	69e2                	ld	s3,24(sp)
    800029ac:	6a42                	ld	s4,16(sp)
    800029ae:	6aa2                	ld	s5,8(sp)
    800029b0:	6121                	addi	sp,sp,64
    800029b2:	8082                	ret
    return -1;
    800029b4:	557d                	li	a0,-1
}
    800029b6:	8082                	ret

00000000800029b8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029b8:	7179                	addi	sp,sp,-48
    800029ba:	f406                	sd	ra,40(sp)
    800029bc:	f022                	sd	s0,32(sp)
    800029be:	ec26                	sd	s1,24(sp)
    800029c0:	e84a                	sd	s2,16(sp)
    800029c2:	e44e                	sd	s3,8(sp)
    800029c4:	e052                	sd	s4,0(sp)
    800029c6:	1800                	addi	s0,sp,48
    800029c8:	84aa                	mv	s1,a0
    800029ca:	892e                	mv	s2,a1
    800029cc:	89b2                	mv	s3,a2
    800029ce:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	086080e7          	jalr	134(ra) # 80001a56 <myproc>
  if(user_dst){
    800029d8:	c095                	beqz	s1,800029fc <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    800029da:	86d2                	mv	a3,s4
    800029dc:	864e                	mv	a2,s3
    800029de:	85ca                	mv	a1,s2
    800029e0:	1d853503          	ld	a0,472(a0)
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	c5a080e7          	jalr	-934(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029ec:	70a2                	ld	ra,40(sp)
    800029ee:	7402                	ld	s0,32(sp)
    800029f0:	64e2                	ld	s1,24(sp)
    800029f2:	6942                	ld	s2,16(sp)
    800029f4:	69a2                	ld	s3,8(sp)
    800029f6:	6a02                	ld	s4,0(sp)
    800029f8:	6145                	addi	sp,sp,48
    800029fa:	8082                	ret
    memmove((char *)dst, src, len);
    800029fc:	000a061b          	sext.w	a2,s4
    80002a00:	85ce                	mv	a1,s3
    80002a02:	854a                	mv	a0,s2
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	316080e7          	jalr	790(ra) # 80000d1a <memmove>
    return 0;
    80002a0c:	8526                	mv	a0,s1
    80002a0e:	bff9                	j	800029ec <either_copyout+0x34>

0000000080002a10 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a10:	7179                	addi	sp,sp,-48
    80002a12:	f406                	sd	ra,40(sp)
    80002a14:	f022                	sd	s0,32(sp)
    80002a16:	ec26                	sd	s1,24(sp)
    80002a18:	e84a                	sd	s2,16(sp)
    80002a1a:	e44e                	sd	s3,8(sp)
    80002a1c:	e052                	sd	s4,0(sp)
    80002a1e:	1800                	addi	s0,sp,48
    80002a20:	892a                	mv	s2,a0
    80002a22:	84ae                	mv	s1,a1
    80002a24:	89b2                	mv	s3,a2
    80002a26:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	02e080e7          	jalr	46(ra) # 80001a56 <myproc>
  if(user_src){
    80002a30:	c095                	beqz	s1,80002a54 <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    80002a32:	86d2                	mv	a3,s4
    80002a34:	864e                	mv	a2,s3
    80002a36:	85ca                	mv	a1,s2
    80002a38:	1d853503          	ld	a0,472(a0)
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	c8e080e7          	jalr	-882(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a44:	70a2                	ld	ra,40(sp)
    80002a46:	7402                	ld	s0,32(sp)
    80002a48:	64e2                	ld	s1,24(sp)
    80002a4a:	6942                	ld	s2,16(sp)
    80002a4c:	69a2                	ld	s3,8(sp)
    80002a4e:	6a02                	ld	s4,0(sp)
    80002a50:	6145                	addi	sp,sp,48
    80002a52:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a54:	000a061b          	sext.w	a2,s4
    80002a58:	85ce                	mv	a1,s3
    80002a5a:	854a                	mv	a0,s2
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	2be080e7          	jalr	702(ra) # 80000d1a <memmove>
    return 0;
    80002a64:	8526                	mv	a0,s1
    80002a66:	bff9                	j	80002a44 <either_copyin+0x34>

0000000080002a68 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a68:	715d                	addi	sp,sp,-80
    80002a6a:	e486                	sd	ra,72(sp)
    80002a6c:	e0a2                	sd	s0,64(sp)
    80002a6e:	fc26                	sd	s1,56(sp)
    80002a70:	f84a                	sd	s2,48(sp)
    80002a72:	f44e                	sd	s3,40(sp)
    80002a74:	f052                	sd	s4,32(sp)
    80002a76:	ec56                	sd	s5,24(sp)
    80002a78:	e85a                	sd	s6,16(sp)
    80002a7a:	e45e                	sd	s7,8(sp)
    80002a7c:	e062                	sd	s8,0(sp)
    80002a7e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	65050513          	addi	a0,a0,1616 # 800090d0 <digits+0x90>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	aec080e7          	jalr	-1300(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a90:	00011497          	auipc	s1,0x11
    80002a94:	2d848493          	addi	s1,s1,728 # 80013d68 <proc+0x268>
    80002a98:	00033997          	auipc	s3,0x33
    80002a9c:	2d098993          	addi	s3,s3,720 # 80035d68 <bcache+0x250>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aa0:	4b89                	li	s7,2
      state = states[p->state];
    else
      state = "???";
    80002aa2:	00006a17          	auipc	s4,0x6
    80002aa6:	7dea0a13          	addi	s4,s4,2014 # 80009280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002aaa:	00006b17          	auipc	s6,0x6
    80002aae:	7deb0b13          	addi	s6,s6,2014 # 80009288 <digits+0x248>
    printf("\n");
    80002ab2:	00006a97          	auipc	s5,0x6
    80002ab6:	61ea8a93          	addi	s5,s5,1566 # 800090d0 <digits+0x90>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aba:	00007c17          	auipc	s8,0x7
    80002abe:	80ec0c13          	addi	s8,s8,-2034 # 800092c8 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ac2:	6905                	lui	s2,0x1
    80002ac4:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    80002ac8:	a005                	j	80002ae8 <procdump+0x80>
    printf("%d %s %s", p->pid, state, p->name);
    80002aca:	dbc6a583          	lw	a1,-580(a3)
    80002ace:	855a                	mv	a0,s6
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	aa4080e7          	jalr	-1372(ra) # 80000574 <printf>
    printf("\n");
    80002ad8:	8556                	mv	a0,s5
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	a9a080e7          	jalr	-1382(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ae2:	94ca                	add	s1,s1,s2
    80002ae4:	03348263          	beq	s1,s3,80002b08 <procdump+0xa0>
    if(p->state == UNUSED)
    80002ae8:	86a6                	mv	a3,s1
    80002aea:	db04a783          	lw	a5,-592(s1)
    80002aee:	dbf5                	beqz	a5,80002ae2 <procdump+0x7a>
      state = "???";
    80002af0:	8652                	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002af2:	fcfbece3          	bltu	s7,a5,80002aca <procdump+0x62>
    80002af6:	02079713          	slli	a4,a5,0x20
    80002afa:	01d75793          	srli	a5,a4,0x1d
    80002afe:	97e2                	add	a5,a5,s8
    80002b00:	6390                	ld	a2,0(a5)
    80002b02:	f661                	bnez	a2,80002aca <procdump+0x62>
      state = "???";
    80002b04:	8652                	mv	a2,s4
    80002b06:	b7d1                	j	80002aca <procdump+0x62>
  }
}
    80002b08:	60a6                	ld	ra,72(sp)
    80002b0a:	6406                	ld	s0,64(sp)
    80002b0c:	74e2                	ld	s1,56(sp)
    80002b0e:	7942                	ld	s2,48(sp)
    80002b10:	79a2                	ld	s3,40(sp)
    80002b12:	7a02                	ld	s4,32(sp)
    80002b14:	6ae2                	ld	s5,24(sp)
    80002b16:	6b42                	ld	s6,16(sp)
    80002b18:	6ba2                	ld	s7,8(sp)
    80002b1a:	6c02                	ld	s8,0(sp)
    80002b1c:	6161                	addi	sp,sp,80
    80002b1e:	8082                	ret

0000000080002b20 <sigprocmask>:

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
    80002b20:	7179                	addi	sp,sp,-48
    80002b22:	f406                	sd	ra,40(sp)
    80002b24:	f022                	sd	s0,32(sp)
    80002b26:	ec26                	sd	s1,24(sp)
    80002b28:	e84a                	sd	s2,16(sp)
    80002b2a:	e44e                	sd	s3,8(sp)
    80002b2c:	1800                	addi	s0,sp,48
    80002b2e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	f26080e7          	jalr	-218(ra) # 80001a56 <myproc>
    80002b38:	84aa                	mv	s1,a0
  uint old_mask = p->signal_mask;
    80002b3a:	02c52983          	lw	s3,44(a0)
  acquire(&p->lock);
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	084080e7          	jalr	132(ra) # 80000bc2 <acquire>

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    80002b46:	000207b7          	lui	a5,0x20
    80002b4a:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    80002b4e:	00f977b3          	and	a5,s2,a5
    80002b52:	e385                	bnez	a5,80002b72 <sigprocmask+0x52>
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
    80002b54:	0324a623          	sw	s2,44(s1)
  release(&p->lock);
    80002b58:	8526                	mv	a0,s1
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	11c080e7          	jalr	284(ra) # 80000c76 <release>
  return old_mask;
}
    80002b62:	854e                	mv	a0,s3
    80002b64:	70a2                	ld	ra,40(sp)
    80002b66:	7402                	ld	s0,32(sp)
    80002b68:	64e2                	ld	s1,24(sp)
    80002b6a:	6942                	ld	s2,16(sp)
    80002b6c:	69a2                	ld	s3,8(sp)
    80002b6e:	6145                	addi	sp,sp,48
    80002b70:	8082                	ret
    release(&p->lock);
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	102080e7          	jalr	258(ra) # 80000c76 <release>
    return -1;
    80002b7c:	59fd                	li	s3,-1
    80002b7e:	b7d5                	j	80002b62 <sigprocmask+0x42>

0000000080002b80 <sigaction>:

// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
    80002b80:	715d                	addi	sp,sp,-80
    80002b82:	e486                	sd	ra,72(sp)
    80002b84:	e0a2                	sd	s0,64(sp)
    80002b86:	fc26                	sd	s1,56(sp)
    80002b88:	f84a                	sd	s2,48(sp)
    80002b8a:	f44e                	sd	s3,40(sp)
    80002b8c:	f052                	sd	s4,32(sp)
    80002b8e:	0880                	addi	s0,sp,80
    80002b90:	84aa                	mv	s1,a0
    80002b92:	89ae                	mv	s3,a1
    80002b94:	8a32                	mv	s4,a2
  struct proc *p = myproc();
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	ec0080e7          	jalr	-320(ra) # 80001a56 <myproc>
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;

  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    80002b9e:	0004879b          	sext.w	a5,s1
    80002ba2:	477d                	li	a4,31
    80002ba4:	0cf76763          	bltu	a4,a5,80002c72 <sigaction+0xf2>
    80002ba8:	892a                	mv	s2,a0
    80002baa:	37dd                	addiw	a5,a5,-9
    80002bac:	9bdd                	andi	a5,a5,-9
    80002bae:	2781                	sext.w	a5,a5
    80002bb0:	c3f9                	beqz	a5,80002c76 <sigaction+0xf6>
    return -1;
  }

  acquire(&p->lock);
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	010080e7          	jalr	16(ra) # 80000bc2 <acquire>

  if(act && copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    80002bba:	0c098063          	beqz	s3,80002c7a <sigaction+0xfa>
    80002bbe:	46c1                	li	a3,16
    80002bc0:	864e                	mv	a2,s3
    80002bc2:	fc040593          	addi	a1,s0,-64
    80002bc6:	1d893503          	ld	a0,472(s2)
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	b00080e7          	jalr	-1280(ra) # 800016ca <copyin>
    80002bd2:	08054263          	bltz	a0,80002c56 <sigaction+0xd6>
    release(&p->lock);
    return -1;
  }
  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((kernel_act.sigmask & (1 << SIGKILL)) != 0) || ((kernel_act.sigmask & (1 << SIGSTOP)) != 0)) ) {
    80002bd6:	fc843783          	ld	a5,-56(s0)
    80002bda:	00020737          	lui	a4,0x20
    80002bde:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    80002be2:	8ff9                	and	a5,a5,a4
    80002be4:	e3c1                	bnez	a5,80002c64 <sigaction+0xe4>
    return -1;
  }

  

  if (oldact) {
    80002be6:	020a0c63          	beqz	s4,80002c1e <sigaction+0x9e>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002bea:	00648793          	addi	a5,s1,6
    80002bee:	078e                	slli	a5,a5,0x3
    80002bf0:	97ca                	add	a5,a5,s2
    80002bf2:	679c                	ld	a5,8(a5)
    80002bf4:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002bf8:	04c48793          	addi	a5,s1,76
    80002bfc:	078a                	slli	a5,a5,0x2
    80002bfe:	97ca                	add	a5,a5,s2
    80002c00:	479c                	lw	a5,8(a5)
    80002c02:	faf42c23          	sw	a5,-72(s0)

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002c06:	46c1                	li	a3,16
    80002c08:	fb040613          	addi	a2,s0,-80
    80002c0c:	85d2                	mv	a1,s4
    80002c0e:	1d893503          	ld	a0,472(s2)
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	a2c080e7          	jalr	-1492(ra) # 8000163e <copyout>
    80002c1a:	08054c63          	bltz	a0,80002cb2 <sigaction+0x132>
      return -1;
    }
  }

  if (act) {
    p->signal_handlers[signum] = kernel_act.sa_handler;
    80002c1e:	00648793          	addi	a5,s1,6
    80002c22:	078e                	slli	a5,a5,0x3
    80002c24:	97ca                	add	a5,a5,s2
    80002c26:	fc043703          	ld	a4,-64(s0)
    80002c2a:	e798                	sd	a4,8(a5)
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
    80002c2c:	04c48493          	addi	s1,s1,76
    80002c30:	048a                	slli	s1,s1,0x2
    80002c32:	94ca                	add	s1,s1,s2
    80002c34:	fc842783          	lw	a5,-56(s0)
    80002c38:	c49c                	sw	a5,8(s1)
  }

  release(&p->lock);
    80002c3a:	854a                	mv	a0,s2
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	03a080e7          	jalr	58(ra) # 80000c76 <release>
  return 0;
    80002c44:	4501                	li	a0,0
}
    80002c46:	60a6                	ld	ra,72(sp)
    80002c48:	6406                	ld	s0,64(sp)
    80002c4a:	74e2                	ld	s1,56(sp)
    80002c4c:	7942                	ld	s2,48(sp)
    80002c4e:	79a2                	ld	s3,40(sp)
    80002c50:	7a02                	ld	s4,32(sp)
    80002c52:	6161                	addi	sp,sp,80
    80002c54:	8082                	ret
    release(&p->lock);
    80002c56:	854a                	mv	a0,s2
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	01e080e7          	jalr	30(ra) # 80000c76 <release>
    return -1;
    80002c60:	557d                	li	a0,-1
    80002c62:	b7d5                	j	80002c46 <sigaction+0xc6>
    release(&p->lock);
    80002c64:	854a                	mv	a0,s2
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	010080e7          	jalr	16(ra) # 80000c76 <release>
    return -1;
    80002c6e:	557d                	li	a0,-1
    80002c70:	bfd9                	j	80002c46 <sigaction+0xc6>
    return -1;
    80002c72:	557d                	li	a0,-1
    80002c74:	bfc9                	j	80002c46 <sigaction+0xc6>
    80002c76:	557d                	li	a0,-1
    80002c78:	b7f9                	j	80002c46 <sigaction+0xc6>
  if (oldact) {
    80002c7a:	fc0a00e3          	beqz	s4,80002c3a <sigaction+0xba>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002c7e:	00648793          	addi	a5,s1,6
    80002c82:	078e                	slli	a5,a5,0x3
    80002c84:	97ca                	add	a5,a5,s2
    80002c86:	679c                	ld	a5,8(a5)
    80002c88:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002c8c:	04c48493          	addi	s1,s1,76
    80002c90:	048a                	slli	s1,s1,0x2
    80002c92:	94ca                	add	s1,s1,s2
    80002c94:	449c                	lw	a5,8(s1)
    80002c96:	faf42c23          	sw	a5,-72(s0)
    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002c9a:	46c1                	li	a3,16
    80002c9c:	fb040613          	addi	a2,s0,-80
    80002ca0:	85d2                	mv	a1,s4
    80002ca2:	1d893503          	ld	a0,472(s2)
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	998080e7          	jalr	-1640(ra) # 8000163e <copyout>
    80002cae:	f80556e3          	bgez	a0,80002c3a <sigaction+0xba>
      release(&p->lock);
    80002cb2:	854a                	mv	a0,s2
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	fc2080e7          	jalr	-62(ra) # 80000c76 <release>
      return -1;
    80002cbc:	557d                	li	a0,-1
    80002cbe:	b761                	j	80002c46 <sigaction+0xc6>

0000000080002cc0 <sigret>:

// ADDED Q2.1.5
// ADDED Q3
void
sigret(void)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	e04a                	sd	s2,0(sp)
    80002cca:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	dc4080e7          	jalr	-572(ra) # 80001a90 <mythread>
    80002cd4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	d80080e7          	jalr	-640(ra) # 80001a56 <myproc>
    80002cde:	84aa                	mv	s1,a0

  acquire(&p->lock);
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	ee2080e7          	jalr	-286(ra) # 80000bc2 <acquire>
  acquire(&t->lock);
    80002ce8:	854a                	mv	a0,s2
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	ed8080e7          	jalr	-296(ra) # 80000bc2 <acquire>
  memmove(t->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    80002cf2:	12000613          	li	a2,288
    80002cf6:	1b84b583          	ld	a1,440(s1)
    80002cfa:	04893503          	ld	a0,72(s2)
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	01c080e7          	jalr	28(ra) # 80000d1a <memmove>
  p->signal_mask = p->signal_mask_backup;
    80002d06:	589c                	lw	a5,48(s1)
    80002d08:	d4dc                	sw	a5,44(s1)
  p->handling_user_level_signal = 0;
    80002d0a:	1c04a223          	sw	zero,452(s1)
  release(&t->lock);
    80002d0e:	854a                	mv	a0,s2
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	f66080e7          	jalr	-154(ra) # 80000c76 <release>
  release(&p->lock);
    80002d18:	8526                	mv	a0,s1
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	f5c080e7          	jalr	-164(ra) # 80000c76 <release>
}
    80002d22:	60e2                	ld	ra,24(sp)
    80002d24:	6442                	ld	s0,16(sp)
    80002d26:	64a2                	ld	s1,8(sp)
    80002d28:	6902                	ld	s2,0(sp)
    80002d2a:	6105                	addi	sp,sp,32
    80002d2c:	8082                	ret

0000000080002d2e <kthread_create>:

int
kthread_create(void (*start_func)(), void* stack)
{ 
    80002d2e:	7179                	addi	sp,sp,-48
    80002d30:	f406                	sd	ra,40(sp)
    80002d32:	f022                	sd	s0,32(sp)
    80002d34:	ec26                	sd	s1,24(sp)
    80002d36:	e84a                	sd	s2,16(sp)
    80002d38:	e44e                	sd	s3,8(sp)
    80002d3a:	e052                	sd	s4,0(sp)
    80002d3c:	1800                	addi	s0,sp,48
    80002d3e:	89aa                	mv	s3,a0
    80002d40:	892e                	mv	s2,a1
    struct thread* t = mythread();
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	d4e080e7          	jalr	-690(ra) # 80001a90 <mythread>
    80002d4a:	8a2a                	mv	s4,a0
    struct thread* nt;

    if((nt = allocthread(myproc())) == 0) {
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	d0a080e7          	jalr	-758(ra) # 80001a56 <myproc>
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	e46080e7          	jalr	-442(ra) # 80001b9a <allocthread>
    80002d5c:	c135                	beqz	a0,80002dc0 <kthread_create+0x92>
    80002d5e:	84aa                	mv	s1,a0
        return -1;
    }
    *nt->trapframe = *t->trapframe;
    80002d60:	048a3683          	ld	a3,72(s4)
    80002d64:	87b6                	mv	a5,a3
    80002d66:	6538                	ld	a4,72(a0)
    80002d68:	12068693          	addi	a3,a3,288
    80002d6c:	0007b803          	ld	a6,0(a5)
    80002d70:	6788                	ld	a0,8(a5)
    80002d72:	6b8c                	ld	a1,16(a5)
    80002d74:	6f90                	ld	a2,24(a5)
    80002d76:	01073023          	sd	a6,0(a4)
    80002d7a:	e708                	sd	a0,8(a4)
    80002d7c:	eb0c                	sd	a1,16(a4)
    80002d7e:	ef10                	sd	a2,24(a4)
    80002d80:	02078793          	addi	a5,a5,32
    80002d84:	02070713          	addi	a4,a4,32
    80002d88:	fed792e3          	bne	a5,a3,80002d6c <kthread_create+0x3e>
    nt->trapframe->epc = (uint64)start_func;
    80002d8c:	64bc                	ld	a5,72(s1)
    80002d8e:	0137bc23          	sd	s3,24(a5)
    // It's stack pointer will be the "malloced" stack plus "STACK_SIZE" minus 16.
    nt->trapframe->sp = (uint64)(stack + MAX_STACK_SIZE) - 16; 
    80002d92:	64bc                	ld	a5,72(s1)
    80002d94:	6585                	lui	a1,0x1
    80002d96:	f9058593          	addi	a1,a1,-112 # f90 <_entry-0x7ffff070>
    80002d9a:	992e                	add	s2,s2,a1
    80002d9c:	0327b823          	sd	s2,48(a5)
    nt->state = RUNNABLE;
    80002da0:	478d                	li	a5,3
    80002da2:	cc9c                	sw	a5,24(s1)

    release(&nt->lock);
    80002da4:	8526                	mv	a0,s1
    80002da6:	ffffe097          	auipc	ra,0xffffe
    80002daa:	ed0080e7          	jalr	-304(ra) # 80000c76 <release>
    return nt->tid;
    80002dae:	5888                	lw	a0,48(s1)
}
    80002db0:	70a2                	ld	ra,40(sp)
    80002db2:	7402                	ld	s0,32(sp)
    80002db4:	64e2                	ld	s1,24(sp)
    80002db6:	6942                	ld	s2,16(sp)
    80002db8:	69a2                	ld	s3,8(sp)
    80002dba:	6a02                	ld	s4,0(sp)
    80002dbc:	6145                	addi	sp,sp,48
    80002dbe:	8082                	ret
        return -1;
    80002dc0:	557d                	li	a0,-1
    80002dc2:	b7fd                	j	80002db0 <kthread_create+0x82>

0000000080002dc4 <exit_single_thread>:

void
exit_single_thread(int status) { // exit single thread when there are other threads in the process
    80002dc4:	7179                	addi	sp,sp,-48
    80002dc6:	f406                	sd	ra,40(sp)
    80002dc8:	f022                	sd	s0,32(sp)
    80002dca:	ec26                	sd	s1,24(sp)
    80002dcc:	e84a                	sd	s2,16(sp)
    80002dce:	e44e                	sd	s3,8(sp)
    80002dd0:	1800                	addi	s0,sp,48
    80002dd2:	892a                	mv	s2,a0
  struct thread *t = mythread();
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	cbc080e7          	jalr	-836(ra) # 80001a90 <mythread>
    80002ddc:	84aa                	mv	s1,a0
  acquire(&join_lock);
    80002dde:	0000f997          	auipc	s3,0xf
    80002de2:	50a98993          	addi	s3,s3,1290 # 800122e8 <join_lock>
    80002de6:	854e                	mv	a0,s3
    80002de8:	ffffe097          	auipc	ra,0xffffe
    80002dec:	dda080e7          	jalr	-550(ra) # 80000bc2 <acquire>
  wakeup(t);
    80002df0:	8526                	mv	a0,s1
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	a4c080e7          	jalr	-1460(ra) # 8000283e <wakeup>

  acquire(&t->lock);
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	dc6080e7          	jalr	-570(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80002e04:	0324a623          	sw	s2,44(s1)
  t->state = ZOMBIE_T;
    80002e08:	4795                	li	a5,5
    80002e0a:	cc9c                	sw	a5,24(s1)
  release(&join_lock);
    80002e0c:	854e                	mv	a0,s3
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	e68080e7          	jalr	-408(ra) # 80000c76 <release>
  // Jump into the scheduler, never to return.
  sched();
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	60c080e7          	jalr	1548(ra) # 80002422 <sched>
  panic("zombie exit");
    80002e1e:	00006517          	auipc	a0,0x6
    80002e22:	47a50513          	addi	a0,a0,1146 # 80009298 <digits+0x258>
    80002e26:	ffffd097          	auipc	ra,0xffffd
    80002e2a:	704080e7          	jalr	1796(ra) # 8000052a <panic>

0000000080002e2e <kthread_join>:
  exit_single_thread(status);
}

int
kthread_join(int thread_id, int *status)
{
    80002e2e:	7139                	addi	sp,sp,-64
    80002e30:	fc06                	sd	ra,56(sp)
    80002e32:	f822                	sd	s0,48(sp)
    80002e34:	f426                	sd	s1,40(sp)
    80002e36:	f04a                	sd	s2,32(sp)
    80002e38:	ec4e                	sd	s3,24(sp)
    80002e3a:	e852                	sd	s4,16(sp)
    80002e3c:	e456                	sd	s5,8(sp)
    80002e3e:	e05a                	sd	s6,0(sp)
    80002e40:	0080                	addi	s0,sp,64
    80002e42:	89aa                	mv	s3,a0
    80002e44:	8aae                	mv	s5,a1
  struct thread *jt  = 0;
  struct proc *p = myproc();  
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	c10080e7          	jalr	-1008(ra) # 80001a56 <myproc>
    80002e4e:	8a2a                	mv	s4,a0

  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002e50:	27850493          	addi	s1,a0,632
    80002e54:	6905                	lui	s2,0x1
    80002e56:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    80002e5a:	992a                	add	s2,s2,a0
    80002e5c:	a811                	j	80002e70 <kthread_join+0x42>
    if (temp_t != mythread() && thread_id == temp_t->tid) {
      jt = temp_t;
      release(&temp_t->lock);
      goto found;
    }
    release(&temp_t->lock);
    80002e5e:	8526                	mv	a0,s1
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	e16080e7          	jalr	-490(ra) # 80000c76 <release>
  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002e68:	0c048493          	addi	s1,s1,192
    80002e6c:	09248e63          	beq	s1,s2,80002f08 <kthread_join+0xda>
    acquire(&temp_t->lock);
    80002e70:	8526                	mv	a0,s1
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	d50080e7          	jalr	-688(ra) # 80000bc2 <acquire>
    if (temp_t != mythread() && thread_id == temp_t->tid) {
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	c16080e7          	jalr	-1002(ra) # 80001a90 <mythread>
    80002e82:	fca48ee3          	beq	s1,a0,80002e5e <kthread_join+0x30>
    80002e86:	589c                	lw	a5,48(s1)
    80002e88:	fd379be3          	bne	a5,s3,80002e5e <kthread_join+0x30>
      release(&temp_t->lock);
    80002e8c:	8526                	mv	a0,s1
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	de8080e7          	jalr	-536(ra) # 80000c76 <release>

  //not found
  return -1;

  found:
  acquire(&join_lock);
    80002e96:	0000f517          	auipc	a0,0xf
    80002e9a:	45250513          	addi	a0,a0,1106 # 800122e8 <join_lock>
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	d24080e7          	jalr	-732(ra) # 80000bc2 <acquire>
  while (jt->state != ZOMBIE_T && jt->state != UNUSED_T && jt->tid == thread_id) {
    80002ea6:	4c9c                	lw	a5,24(s1)
    80002ea8:	4715                	li	a4,5
    sleep(jt, &join_lock);
    80002eaa:	0000fb17          	auipc	s6,0xf
    80002eae:	43eb0b13          	addi	s6,s6,1086 # 800122e8 <join_lock>
  while (jt->state != ZOMBIE_T && jt->state != UNUSED_T && jt->tid == thread_id) {
    80002eb2:	4915                	li	s2,5
    80002eb4:	00e78f63          	beq	a5,a4,80002ed2 <kthread_join+0xa4>
    80002eb8:	cf89                	beqz	a5,80002ed2 <kthread_join+0xa4>
    80002eba:	589c                	lw	a5,48(s1)
    80002ebc:	01379b63          	bne	a5,s3,80002ed2 <kthread_join+0xa4>
    sleep(jt, &join_lock);
    80002ec0:	85da                	mv	a1,s6
    80002ec2:	8526                	mv	a0,s1
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	7f0080e7          	jalr	2032(ra) # 800026b4 <sleep>
  while (jt->state != ZOMBIE_T && jt->state != UNUSED_T && jt->tid == thread_id) {
    80002ecc:	4c9c                	lw	a5,24(s1)
    80002ece:	ff2795e3          	bne	a5,s2,80002eb8 <kthread_join+0x8a>
  }

  release(&join_lock);
    80002ed2:	0000f517          	auipc	a0,0xf
    80002ed6:	41650513          	addi	a0,a0,1046 # 800122e8 <join_lock>
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	d9c080e7          	jalr	-612(ra) # 80000c76 <release>
  acquire(&jt->lock);
    80002ee2:	8526                	mv	a0,s1
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	cde080e7          	jalr	-802(ra) # 80000bc2 <acquire>
  if (jt->state == ZOMBIE_T && jt->tid == thread_id) {
    80002eec:	4c98                	lw	a4,24(s1)
    80002eee:	4795                	li	a5,5
    80002ef0:	00f71563          	bne	a4,a5,80002efa <kthread_join+0xcc>
    80002ef4:	589c                	lw	a5,48(s1)
    80002ef6:	03378463          	beq	a5,s3,80002f1e <kthread_join+0xf0>
      return -1;
    }
    freethread(jt);
  } 

  release(&jt->lock);
    80002efa:	8526                	mv	a0,s1
    80002efc:	ffffe097          	auipc	ra,0xffffe
    80002f00:	d7a080e7          	jalr	-646(ra) # 80000c76 <release>
  return 0;
    80002f04:	4501                	li	a0,0
    80002f06:	a011                	j	80002f0a <kthread_join+0xdc>
  return -1;
    80002f08:	557d                	li	a0,-1
}
    80002f0a:	70e2                	ld	ra,56(sp)
    80002f0c:	7442                	ld	s0,48(sp)
    80002f0e:	74a2                	ld	s1,40(sp)
    80002f10:	7902                	ld	s2,32(sp)
    80002f12:	69e2                	ld	s3,24(sp)
    80002f14:	6a42                	ld	s4,16(sp)
    80002f16:	6aa2                	ld	s5,8(sp)
    80002f18:	6b02                	ld	s6,0(sp)
    80002f1a:	6121                	addi	sp,sp,64
    80002f1c:	8082                	ret
    if (status != 0 && copyout(p->pagetable, (uint64)status, (char *)&jt->xstate, sizeof(jt->xstate)) < 0) {
    80002f1e:	000a8e63          	beqz	s5,80002f3a <kthread_join+0x10c>
    80002f22:	4691                	li	a3,4
    80002f24:	02c48613          	addi	a2,s1,44
    80002f28:	85d6                	mv	a1,s5
    80002f2a:	1d8a3503          	ld	a0,472(s4)
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	710080e7          	jalr	1808(ra) # 8000163e <copyout>
    80002f36:	00054863          	bltz	a0,80002f46 <kthread_join+0x118>
    freethread(jt);
    80002f3a:	8526                	mv	a0,s1
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	8d0080e7          	jalr	-1840(ra) # 8000180c <freethread>
    80002f44:	bf5d                	j	80002efa <kthread_join+0xcc>
      release(&jt->lock);
    80002f46:	8526                	mv	a0,s1
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	d2e080e7          	jalr	-722(ra) # 80000c76 <release>
      return -1;
    80002f50:	557d                	li	a0,-1
    80002f52:	bf65                	j	80002f0a <kthread_join+0xdc>

0000000080002f54 <exit>:
{
    80002f54:	715d                	addi	sp,sp,-80
    80002f56:	e486                	sd	ra,72(sp)
    80002f58:	e0a2                	sd	s0,64(sp)
    80002f5a:	fc26                	sd	s1,56(sp)
    80002f5c:	f84a                	sd	s2,48(sp)
    80002f5e:	f44e                	sd	s3,40(sp)
    80002f60:	f052                	sd	s4,32(sp)
    80002f62:	ec56                	sd	s5,24(sp)
    80002f64:	e85a                	sd	s6,16(sp)
    80002f66:	e45e                	sd	s7,8(sp)
    80002f68:	e062                	sd	s8,0(sp)
    80002f6a:	0880                	addi	s0,sp,80
    80002f6c:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	ae8080e7          	jalr	-1304(ra) # 80001a56 <myproc>
    80002f76:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f78:	00007797          	auipc	a5,0x7
    80002f7c:	0b07b783          	ld	a5,176(a5) # 8000a028 <initproc>
    80002f80:	1e050493          	addi	s1,a0,480
    80002f84:	26050913          	addi	s2,a0,608
    80002f88:	02a79363          	bne	a5,a0,80002fae <exit+0x5a>
    panic("init exiting");
    80002f8c:	00006517          	auipc	a0,0x6
    80002f90:	31c50513          	addi	a0,a0,796 # 800092a8 <digits+0x268>
    80002f94:	ffffd097          	auipc	ra,0xffffd
    80002f98:	596080e7          	jalr	1430(ra) # 8000052a <panic>
      fileclose(f);
    80002f9c:	00002097          	auipc	ra,0x2
    80002fa0:	642080e7          	jalr	1602(ra) # 800055de <fileclose>
      p->ofile[fd] = 0;
    80002fa4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002fa8:	04a1                	addi	s1,s1,8
    80002faa:	01248563          	beq	s1,s2,80002fb4 <exit+0x60>
    if(p->ofile[fd]){
    80002fae:	6088                	ld	a0,0(s1)
    80002fb0:	f575                	bnez	a0,80002f9c <exit+0x48>
    80002fb2:	bfdd                	j	80002fa8 <exit+0x54>
  begin_op();
    80002fb4:	00002097          	auipc	ra,0x2
    80002fb8:	15e080e7          	jalr	350(ra) # 80005112 <begin_op>
  iput(p->cwd);
    80002fbc:	2609b503          	ld	a0,608(s3)
    80002fc0:	00002097          	auipc	ra,0x2
    80002fc4:	936080e7          	jalr	-1738(ra) # 800048f6 <iput>
  end_op();
    80002fc8:	00002097          	auipc	ra,0x2
    80002fcc:	1ca080e7          	jalr	458(ra) # 80005192 <end_op>
  p->cwd = 0;
    80002fd0:	2609b023          	sd	zero,608(s3)
  acquire(&wait_lock);
    80002fd4:	0000f517          	auipc	a0,0xf
    80002fd8:	2fc50513          	addi	a0,a0,764 # 800122d0 <wait_lock>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	be6080e7          	jalr	-1050(ra) # 80000bc2 <acquire>
  reparent(p);
    80002fe4:	854e                	mv	a0,s3
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	8e8080e7          	jalr	-1816(ra) # 800028ce <reparent>
  wakeup(p->parent);
    80002fee:	1c89b503          	ld	a0,456(s3)
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	84c080e7          	jalr	-1972(ra) # 8000283e <wakeup>
  acquire(&p->lock);
    80002ffa:	854e                	mv	a0,s3
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	bc6080e7          	jalr	-1082(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80003004:	0359a023          	sw	s5,32(s3)
  p->state = ZOMBIE;
    80003008:	4789                	li	a5,2
    8000300a:	00f9ac23          	sw	a5,24(s3)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000300e:	27898493          	addi	s1,s3,632
    80003012:	6a05                	lui	s4,0x1
    80003014:	878a0a13          	addi	s4,s4,-1928 # 878 <_entry-0x7ffff788>
    80003018:	9a4e                	add	s4,s4,s3
      t->terminated = 1;
    8000301a:	4b85                	li	s7,1
      if (t->state == SLEEPING) {
    8000301c:	4b09                	li	s6,2
          t->state = RUNNABLE;
    8000301e:	4c0d                	li	s8,3
    80003020:	a005                	j	80003040 <exit+0xec>
      release(&t->lock);
    80003022:	8526                	mv	a0,s1
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	c52080e7          	jalr	-942(ra) # 80000c76 <release>
      kthread_join(t->tid, 0);
    8000302c:	4581                	li	a1,0
    8000302e:	5888                	lw	a0,48(s1)
    80003030:	00000097          	auipc	ra,0x0
    80003034:	dfe080e7          	jalr	-514(ra) # 80002e2e <kthread_join>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80003038:	0c048493          	addi	s1,s1,192
    8000303c:	029a0863          	beq	s4,s1,8000306c <exit+0x118>
    if (t->tid != mythread()->tid) {
    80003040:	0304a903          	lw	s2,48(s1)
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	a4c080e7          	jalr	-1460(ra) # 80001a90 <mythread>
    8000304c:	591c                	lw	a5,48(a0)
    8000304e:	ff2785e3          	beq	a5,s2,80003038 <exit+0xe4>
      acquire(&t->lock);
    80003052:	8526                	mv	a0,s1
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	b6e080e7          	jalr	-1170(ra) # 80000bc2 <acquire>
      t->terminated = 1;
    8000305c:	0374a423          	sw	s7,40(s1)
      if (t->state == SLEEPING) {
    80003060:	4c9c                	lw	a5,24(s1)
    80003062:	fd6790e3          	bne	a5,s6,80003022 <exit+0xce>
          t->state = RUNNABLE;
    80003066:	0184ac23          	sw	s8,24(s1)
    8000306a:	bf65                	j	80003022 <exit+0xce>
  release(&p->lock);
    8000306c:	854e                	mv	a0,s3
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	c08080e7          	jalr	-1016(ra) # 80000c76 <release>
  struct thread *t = mythread();
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	a1a080e7          	jalr	-1510(ra) # 80001a90 <mythread>
    8000307e:	84aa                	mv	s1,a0
  acquire(&t->lock);
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	b42080e7          	jalr	-1214(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80003088:	0354a623          	sw	s5,44(s1)
  t->state = ZOMBIE_T;
    8000308c:	4795                	li	a5,5
    8000308e:	cc9c                	sw	a5,24(s1)
  release(&wait_lock);
    80003090:	0000f517          	auipc	a0,0xf
    80003094:	24050513          	addi	a0,a0,576 # 800122d0 <wait_lock>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	bde080e7          	jalr	-1058(ra) # 80000c76 <release>
  sched();
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	382080e7          	jalr	898(ra) # 80002422 <sched>
  panic("zombie exit");
    800030a8:	00006517          	auipc	a0,0x6
    800030ac:	1f050513          	addi	a0,a0,496 # 80009298 <digits+0x258>
    800030b0:	ffffd097          	auipc	ra,0xffffd
    800030b4:	47a080e7          	jalr	1146(ra) # 8000052a <panic>

00000000800030b8 <kthread_exit>:
{
    800030b8:	7139                	addi	sp,sp,-64
    800030ba:	fc06                	sd	ra,56(sp)
    800030bc:	f822                	sd	s0,48(sp)
    800030be:	f426                	sd	s1,40(sp)
    800030c0:	f04a                	sd	s2,32(sp)
    800030c2:	ec4e                	sd	s3,24(sp)
    800030c4:	e852                	sd	s4,16(sp)
    800030c6:	e456                	sd	s5,8(sp)
    800030c8:	0080                	addi	s0,sp,64
    800030ca:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    800030cc:	fffff097          	auipc	ra,0xfffff
    800030d0:	98a080e7          	jalr	-1654(ra) # 80001a56 <myproc>
    800030d4:	8a2a                	mv	s4,a0
  acquire(&p->lock);
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	aec080e7          	jalr	-1300(ra) # 80000bc2 <acquire>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800030de:	278a0493          	addi	s1,s4,632
    800030e2:	6905                	lui	s2,0x1
    800030e4:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    800030e8:	9952                	add	s2,s2,s4
  int used_threads = 0;
    800030ea:	4981                	li	s3,0
    800030ec:	a811                	j	80003100 <kthread_exit+0x48>
    release(&t->lock);
    800030ee:	8526                	mv	a0,s1
    800030f0:	ffffe097          	auipc	ra,0xffffe
    800030f4:	b86080e7          	jalr	-1146(ra) # 80000c76 <release>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800030f8:	0c048493          	addi	s1,s1,192
    800030fc:	00990b63          	beq	s2,s1,80003112 <kthread_exit+0x5a>
    acquire(&t->lock);
    80003100:	8526                	mv	a0,s1
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	ac0080e7          	jalr	-1344(ra) # 80000bc2 <acquire>
    if (t->state != UNUSED_T) {
    8000310a:	4c9c                	lw	a5,24(s1)
    8000310c:	d3ed                	beqz	a5,800030ee <kthread_exit+0x36>
      used_threads++;
    8000310e:	2985                	addiw	s3,s3,1
    80003110:	bff9                	j	800030ee <kthread_exit+0x36>
  release(&p->lock);
    80003112:	8552                	mv	a0,s4
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	b62080e7          	jalr	-1182(ra) # 80000c76 <release>
  if (used_threads <= 1) {
    8000311c:	4785                	li	a5,1
    8000311e:	0137d763          	bge	a5,s3,8000312c <kthread_exit+0x74>
  exit_single_thread(status);
    80003122:	8556                	mv	a0,s5
    80003124:	00000097          	auipc	ra,0x0
    80003128:	ca0080e7          	jalr	-864(ra) # 80002dc4 <exit_single_thread>
    exit(status);
    8000312c:	8556                	mv	a0,s5
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	e26080e7          	jalr	-474(ra) # 80002f54 <exit>

0000000080003136 <wakeup_single_thread>:


// ADDED Q4.1
void
wakeup_single_thread(void *chan)
{
    80003136:	7139                	addi	sp,sp,-64
    80003138:	fc06                	sd	ra,56(sp)
    8000313a:	f822                	sd	s0,48(sp)
    8000313c:	f426                	sd	s1,40(sp)
    8000313e:	f04a                	sd	s2,32(sp)
    80003140:	ec4e                	sd	s3,24(sp)
    80003142:	e852                	sd	s4,16(sp)
    80003144:	e456                	sd	s5,8(sp)
    80003146:	e05a                	sd	s6,0(sp)
    80003148:	0080                	addi	s0,sp,64
    8000314a:	8a2a                	mv	s4,a0
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    8000314c:	00011917          	auipc	s2,0x11
    80003150:	22c90913          	addi	s2,s2,556 # 80014378 <proc+0x878>
    80003154:	00033b17          	auipc	s6,0x33
    80003158:	224b0b13          	addi	s6,s6,548 # 80036378 <bcache+0x860>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
      if(t != mythread()){
        acquire(&t->lock);
        if (t->state == SLEEPING && t->chan == chan) {
    8000315c:	4989                	li	s3,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000315e:	6a85                	lui	s5,0x1
    80003160:	880a8a93          	addi	s5,s5,-1920 # 880 <_entry-0x7ffff780>
    80003164:	a8b9                	j	800031c2 <wakeup_single_thread+0x8c>
          t->state = RUNNABLE;
          release(&t->lock);
          return;
        }
        release(&t->lock);
    80003166:	8526                	mv	a0,s1
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	b0e080e7          	jalr	-1266(ra) # 80000c76 <release>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80003170:	0c048493          	addi	s1,s1,192
    80003174:	05248463          	beq	s1,s2,800031bc <wakeup_single_thread+0x86>
      if(t != mythread()){
    80003178:	fffff097          	auipc	ra,0xfffff
    8000317c:	918080e7          	jalr	-1768(ra) # 80001a90 <mythread>
    80003180:	fea488e3          	beq	s1,a0,80003170 <wakeup_single_thread+0x3a>
        acquire(&t->lock);
    80003184:	8526                	mv	a0,s1
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	a3c080e7          	jalr	-1476(ra) # 80000bc2 <acquire>
        if (t->state == SLEEPING && t->chan == chan) {
    8000318e:	4c9c                	lw	a5,24(s1)
    80003190:	fd379be3          	bne	a5,s3,80003166 <wakeup_single_thread+0x30>
    80003194:	709c                	ld	a5,32(s1)
    80003196:	fd4798e3          	bne	a5,s4,80003166 <wakeup_single_thread+0x30>
          t->state = RUNNABLE;
    8000319a:	478d                	li	a5,3
    8000319c:	cc9c                	sw	a5,24(s1)
          release(&t->lock);
    8000319e:	8526                	mv	a0,s1
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	ad6080e7          	jalr	-1322(ra) # 80000c76 <release>
      }
    }
  }
}
    800031a8:	70e2                	ld	ra,56(sp)
    800031aa:	7442                	ld	s0,48(sp)
    800031ac:	74a2                	ld	s1,40(sp)
    800031ae:	7902                	ld	s2,32(sp)
    800031b0:	69e2                	ld	s3,24(sp)
    800031b2:	6a42                	ld	s4,16(sp)
    800031b4:	6aa2                	ld	s5,8(sp)
    800031b6:	6b02                	ld	s6,0(sp)
    800031b8:	6121                	addi	sp,sp,64
    800031ba:	8082                	ret
  for(p = proc; p < &proc[NPROC]; p++) {
    800031bc:	9956                	add	s2,s2,s5
    800031be:	ff6905e3          	beq	s2,s6,800031a8 <wakeup_single_thread+0x72>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800031c2:	a0090493          	addi	s1,s2,-1536
    800031c6:	bf4d                	j	80003178 <wakeup_single_thread+0x42>

00000000800031c8 <bsem_alloc>:

int
bsem_alloc(void)
{
    800031c8:	7179                	addi	sp,sp,-48
    800031ca:	f406                	sd	ra,40(sp)
    800031cc:	f022                	sd	s0,32(sp)
    800031ce:	ec26                	sd	s1,24(sp)
    800031d0:	e84a                	sd	s2,16(sp)
    800031d2:	e44e                	sd	s3,8(sp)
    800031d4:	e052                	sd	s4,0(sp)
    800031d6:	1800                	addi	s0,sp,48
  int descriptor = 0;
  for(struct bsem* bs = bsems; bs < &bsems[MAX_BSEM]; bs++, descriptor++){
    800031d8:	0000f497          	auipc	s1,0xf
    800031dc:	52848493          	addi	s1,s1,1320 # 80012700 <bsems>
  int descriptor = 0;
    800031e0:	4981                	li	s3,0
  for(struct bsem* bs = bsems; bs < &bsems[MAX_BSEM]; bs++, descriptor++){
    800031e2:	08000a13          	li	s4,128
    acquire(&bs->mutex);
    800031e6:	01048913          	addi	s2,s1,16
    800031ea:	854a                	mv	a0,s2
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	9d6080e7          	jalr	-1578(ra) # 80000bc2 <acquire>
    if(bs->active){
    800031f4:	409c                	lw	a5,0(s1)
    800031f6:	e785                	bnez	a5,8000321e <bsem_alloc+0x56>
      release(&bs->mutex);
      continue;
    } 
    bs->active = 1;
    800031f8:	4785                	li	a5,1
    800031fa:	c09c                	sw	a5,0(s1)
    bs->permits = 1;
    800031fc:	c49c                	sw	a5,8(s1)
    bs->blocked = 0;
    800031fe:	0004a223          	sw	zero,4(s1)
    release(&bs->mutex);
    80003202:	854a                	mv	a0,s2
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	a72080e7          	jalr	-1422(ra) # 80000c76 <release>
    return descriptor;
  }
  return -1;
}
    8000320c:	854e                	mv	a0,s3
    8000320e:	70a2                	ld	ra,40(sp)
    80003210:	7402                	ld	s0,32(sp)
    80003212:	64e2                	ld	s1,24(sp)
    80003214:	6942                	ld	s2,16(sp)
    80003216:	69a2                	ld	s3,8(sp)
    80003218:	6a02                	ld	s4,0(sp)
    8000321a:	6145                	addi	sp,sp,48
    8000321c:	8082                	ret
      release(&bs->mutex);
    8000321e:	854a                	mv	a0,s2
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	a56080e7          	jalr	-1450(ra) # 80000c76 <release>
  for(struct bsem* bs = bsems; bs < &bsems[MAX_BSEM]; bs++, descriptor++){
    80003228:	02848493          	addi	s1,s1,40
    8000322c:	2985                	addiw	s3,s3,1
    8000322e:	fb499ce3          	bne	s3,s4,800031e6 <bsem_alloc+0x1e>
  return -1;
    80003232:	59fd                	li	s3,-1
    80003234:	bfe1                	j	8000320c <bsem_alloc+0x44>

0000000080003236 <bsem_free>:

void
bsem_free(int descriptor)
{
  if (descriptor < 0 || descriptor >= MAX_BSEM) {
    80003236:	07f00793          	li	a5,127
    8000323a:	00a7f363          	bgeu	a5,a0,80003240 <bsem_free+0xa>
    8000323e:	8082                	ret
{
    80003240:	7179                	addi	sp,sp,-48
    80003242:	f406                	sd	ra,40(sp)
    80003244:	f022                	sd	s0,32(sp)
    80003246:	ec26                	sd	s1,24(sp)
    80003248:	e84a                	sd	s2,16(sp)
    8000324a:	e44e                	sd	s3,8(sp)
    8000324c:	e052                	sd	s4,0(sp)
    8000324e:	1800                	addi	s0,sp,48
    80003250:	89aa                	mv	s3,a0
    return;
  }
  struct bsem *bs = &bsems[descriptor]; 
  acquire(&bs->mutex);
    80003252:	00251913          	slli	s2,a0,0x2
    80003256:	00a904b3          	add	s1,s2,a0
    8000325a:	048e                	slli	s1,s1,0x3
    8000325c:	04c1                	addi	s1,s1,16
    8000325e:	0000fa17          	auipc	s4,0xf
    80003262:	4a2a0a13          	addi	s4,s4,1186 # 80012700 <bsems>
    80003266:	94d2                	add	s1,s1,s4
    80003268:	8526                	mv	a0,s1
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	958080e7          	jalr	-1704(ra) # 80000bc2 <acquire>
  bs->active = 0;
    80003272:	994e                	add	s2,s2,s3
    80003274:	090e                	slli	s2,s2,0x3
    80003276:	9952                	add	s2,s2,s4
    80003278:	00092023          	sw	zero,0(s2)
  release(&bs->mutex);
    8000327c:	8526                	mv	a0,s1
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	9f8080e7          	jalr	-1544(ra) # 80000c76 <release>
}
    80003286:	70a2                	ld	ra,40(sp)
    80003288:	7402                	ld	s0,32(sp)
    8000328a:	64e2                	ld	s1,24(sp)
    8000328c:	6942                	ld	s2,16(sp)
    8000328e:	69a2                	ld	s3,8(sp)
    80003290:	6a02                	ld	s4,0(sp)
    80003292:	6145                	addi	sp,sp,48
    80003294:	8082                	ret

0000000080003296 <bsem_down>:
// Else
//    S--
void
bsem_down(int descriptor)
{
  if (descriptor < 0 || descriptor >= MAX_BSEM) {
    80003296:	07f00793          	li	a5,127
    8000329a:	00a7f363          	bgeu	a5,a0,800032a0 <bsem_down+0xa>
    8000329e:	8082                	ret
{
    800032a0:	7179                	addi	sp,sp,-48
    800032a2:	f406                	sd	ra,40(sp)
    800032a4:	f022                	sd	s0,32(sp)
    800032a6:	ec26                	sd	s1,24(sp)
    800032a8:	e84a                	sd	s2,16(sp)
    800032aa:	e44e                	sd	s3,8(sp)
    800032ac:	e052                	sd	s4,0(sp)
    800032ae:	1800                	addi	s0,sp,48
    800032b0:	84aa                	mv	s1,a0
    return;
  }
  struct bsem *bs = &bsems[descriptor];
  
  acquire(&bs->mutex);
    800032b2:	00251913          	slli	s2,a0,0x2
    800032b6:	992a                	add	s2,s2,a0
    800032b8:	090e                	slli	s2,s2,0x3
    800032ba:	01090a13          	addi	s4,s2,16
    800032be:	0000f997          	auipc	s3,0xf
    800032c2:	44298993          	addi	s3,s3,1090 # 80012700 <bsems>
    800032c6:	9a4e                	add	s4,s4,s3
    800032c8:	8552                	mv	a0,s4
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	8f8080e7          	jalr	-1800(ra) # 80000bc2 <acquire>

  if (!bs->active){
    800032d2:	99ca                	add	s3,s3,s2
    800032d4:	0009a783          	lw	a5,0(s3)
    800032d8:	c7a9                	beqz	a5,80003322 <bsem_down+0x8c>
    release(&bs->mutex);
    return;
  }

  if (bs->permits <= 0) {
    800032da:	00249793          	slli	a5,s1,0x2
    800032de:	97a6                	add	a5,a5,s1
    800032e0:	078e                	slli	a5,a5,0x3
    800032e2:	0000f717          	auipc	a4,0xf
    800032e6:	41e70713          	addi	a4,a4,1054 # 80012700 <bsems>
    800032ea:	97ba                	add	a5,a5,a4
    800032ec:	4798                	lw	a4,8(a5)
    800032ee:	04e05063          	blez	a4,8000332e <bsem_down+0x98>
    bs->blocked++;
    sleep(bs, &bs->mutex);
  }
  else{
    bs->permits--;
    800032f2:	00249793          	slli	a5,s1,0x2
    800032f6:	94be                	add	s1,s1,a5
    800032f8:	048e                	slli	s1,s1,0x3
    800032fa:	0000f797          	auipc	a5,0xf
    800032fe:	40678793          	addi	a5,a5,1030 # 80012700 <bsems>
    80003302:	94be                	add	s1,s1,a5
    80003304:	377d                	addiw	a4,a4,-1
    80003306:	c498                	sw	a4,8(s1)
  }

  release(&bs->mutex);
    80003308:	8552                	mv	a0,s4
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	96c080e7          	jalr	-1684(ra) # 80000c76 <release>
}
    80003312:	70a2                	ld	ra,40(sp)
    80003314:	7402                	ld	s0,32(sp)
    80003316:	64e2                	ld	s1,24(sp)
    80003318:	6942                	ld	s2,16(sp)
    8000331a:	69a2                	ld	s3,8(sp)
    8000331c:	6a02                	ld	s4,0(sp)
    8000331e:	6145                	addi	sp,sp,48
    80003320:	8082                	ret
    release(&bs->mutex);
    80003322:	8552                	mv	a0,s4
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	952080e7          	jalr	-1710(ra) # 80000c76 <release>
    return;
    8000332c:	b7dd                	j	80003312 <bsem_down+0x7c>
    bs->blocked++;
    8000332e:	0000f517          	auipc	a0,0xf
    80003332:	3d250513          	addi	a0,a0,978 # 80012700 <bsems>
    80003336:	00249793          	slli	a5,s1,0x2
    8000333a:	00978733          	add	a4,a5,s1
    8000333e:	070e                	slli	a4,a4,0x3
    80003340:	972a                	add	a4,a4,a0
    80003342:	435c                	lw	a5,4(a4)
    80003344:	2785                	addiw	a5,a5,1
    80003346:	c35c                	sw	a5,4(a4)
    sleep(bs, &bs->mutex);
    80003348:	85d2                	mv	a1,s4
    8000334a:	954a                	add	a0,a0,s2
    8000334c:	fffff097          	auipc	ra,0xfffff
    80003350:	368080e7          	jalr	872(ra) # 800026b4 <sleep>
    80003354:	bf55                	j	80003308 <bsem_down+0x72>

0000000080003356 <bsem_up>:
// Else 
//    S++
void
bsem_up(int descriptor)
{
  if (descriptor < 0 || descriptor >= MAX_BSEM) {
    80003356:	07f00793          	li	a5,127
    8000335a:	00a7f363          	bgeu	a5,a0,80003360 <bsem_up+0xa>
    8000335e:	8082                	ret
{
    80003360:	7179                	addi	sp,sp,-48
    80003362:	f406                	sd	ra,40(sp)
    80003364:	f022                	sd	s0,32(sp)
    80003366:	ec26                	sd	s1,24(sp)
    80003368:	e84a                	sd	s2,16(sp)
    8000336a:	e44e                	sd	s3,8(sp)
    8000336c:	e052                	sd	s4,0(sp)
    8000336e:	1800                	addi	s0,sp,48
    80003370:	84aa                	mv	s1,a0
    return;
  }
  struct bsem *bs = &bsems[descriptor];

  acquire(&bs->mutex);
    80003372:	00251913          	slli	s2,a0,0x2
    80003376:	992a                	add	s2,s2,a0
    80003378:	090e                	slli	s2,s2,0x3
    8000337a:	01090a13          	addi	s4,s2,16
    8000337e:	0000f997          	auipc	s3,0xf
    80003382:	38298993          	addi	s3,s3,898 # 80012700 <bsems>
    80003386:	9a4e                	add	s4,s4,s3
    80003388:	8552                	mv	a0,s4
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	838080e7          	jalr	-1992(ra) # 80000bc2 <acquire>

  if (!bs->active){
    80003392:	99ca                	add	s3,s3,s2
    80003394:	0009a783          	lw	a5,0(s3)
    80003398:	c7b9                	beqz	a5,800033e6 <bsem_up+0x90>
    release(&bs->mutex);
    return;
  }
  
  if(bs->blocked > 0){
    8000339a:	00249793          	slli	a5,s1,0x2
    8000339e:	97a6                	add	a5,a5,s1
    800033a0:	078e                	slli	a5,a5,0x3
    800033a2:	0000f717          	auipc	a4,0xf
    800033a6:	35e70713          	addi	a4,a4,862 # 80012700 <bsems>
    800033aa:	97ba                	add	a5,a5,a4
    800033ac:	43d8                	lw	a4,4(a5)
    800033ae:	04e04263          	bgtz	a4,800033f2 <bsem_up+0x9c>
    bs->blocked--;
    wakeup_single_thread(bs);
  }
  else{
    bs->permits++;
    800033b2:	0000f697          	auipc	a3,0xf
    800033b6:	34e68693          	addi	a3,a3,846 # 80012700 <bsems>
    800033ba:	00249793          	slli	a5,s1,0x2
    800033be:	00978733          	add	a4,a5,s1
    800033c2:	070e                	slli	a4,a4,0x3
    800033c4:	9736                	add	a4,a4,a3
    800033c6:	471c                	lw	a5,8(a4)
    800033c8:	2785                	addiw	a5,a5,1
    800033ca:	c71c                	sw	a5,8(a4)
  }

  release(&bs->mutex);
    800033cc:	8552                	mv	a0,s4
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	8a8080e7          	jalr	-1880(ra) # 80000c76 <release>
}
    800033d6:	70a2                	ld	ra,40(sp)
    800033d8:	7402                	ld	s0,32(sp)
    800033da:	64e2                	ld	s1,24(sp)
    800033dc:	6942                	ld	s2,16(sp)
    800033de:	69a2                	ld	s3,8(sp)
    800033e0:	6a02                	ld	s4,0(sp)
    800033e2:	6145                	addi	sp,sp,48
    800033e4:	8082                	ret
    release(&bs->mutex);
    800033e6:	8552                	mv	a0,s4
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	88e080e7          	jalr	-1906(ra) # 80000c76 <release>
    return;
    800033f0:	b7dd                	j	800033d6 <bsem_up+0x80>
    bs->blocked--;
    800033f2:	0000f517          	auipc	a0,0xf
    800033f6:	30e50513          	addi	a0,a0,782 # 80012700 <bsems>
    800033fa:	00249793          	slli	a5,s1,0x2
    800033fe:	94be                	add	s1,s1,a5
    80003400:	048e                	slli	s1,s1,0x3
    80003402:	94aa                	add	s1,s1,a0
    80003404:	377d                	addiw	a4,a4,-1
    80003406:	c0d8                	sw	a4,4(s1)
    wakeup_single_thread(bs);
    80003408:	954a                	add	a0,a0,s2
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	d2c080e7          	jalr	-724(ra) # 80003136 <wakeup_single_thread>
    80003412:	bf6d                	j	800033cc <bsem_up+0x76>

0000000080003414 <swtch>:
    80003414:	00153023          	sd	ra,0(a0)
    80003418:	00253423          	sd	sp,8(a0)
    8000341c:	e900                	sd	s0,16(a0)
    8000341e:	ed04                	sd	s1,24(a0)
    80003420:	03253023          	sd	s2,32(a0)
    80003424:	03353423          	sd	s3,40(a0)
    80003428:	03453823          	sd	s4,48(a0)
    8000342c:	03553c23          	sd	s5,56(a0)
    80003430:	05653023          	sd	s6,64(a0)
    80003434:	05753423          	sd	s7,72(a0)
    80003438:	05853823          	sd	s8,80(a0)
    8000343c:	05953c23          	sd	s9,88(a0)
    80003440:	07a53023          	sd	s10,96(a0)
    80003444:	07b53423          	sd	s11,104(a0)
    80003448:	0005b083          	ld	ra,0(a1)
    8000344c:	0085b103          	ld	sp,8(a1)
    80003450:	6980                	ld	s0,16(a1)
    80003452:	6d84                	ld	s1,24(a1)
    80003454:	0205b903          	ld	s2,32(a1)
    80003458:	0285b983          	ld	s3,40(a1)
    8000345c:	0305ba03          	ld	s4,48(a1)
    80003460:	0385ba83          	ld	s5,56(a1)
    80003464:	0405bb03          	ld	s6,64(a1)
    80003468:	0485bb83          	ld	s7,72(a1)
    8000346c:	0505bc03          	ld	s8,80(a1)
    80003470:	0585bc83          	ld	s9,88(a1)
    80003474:	0605bd03          	ld	s10,96(a1)
    80003478:	0685bd83          	ld	s11,104(a1)
    8000347c:	8082                	ret

000000008000347e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000347e:	1141                	addi	sp,sp,-16
    80003480:	e406                	sd	ra,8(sp)
    80003482:	e022                	sd	s0,0(sp)
    80003484:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003486:	00006597          	auipc	a1,0x6
    8000348a:	e5a58593          	addi	a1,a1,-422 # 800092e0 <states.0+0x18>
    8000348e:	00032517          	auipc	a0,0x32
    80003492:	67250513          	addi	a0,a0,1650 # 80035b00 <tickslock>
    80003496:	ffffd097          	auipc	ra,0xffffd
    8000349a:	69c080e7          	jalr	1692(ra) # 80000b32 <initlock>
}
    8000349e:	60a2                	ld	ra,8(sp)
    800034a0:	6402                	ld	s0,0(sp)
    800034a2:	0141                	addi	sp,sp,16
    800034a4:	8082                	ret

00000000800034a6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800034a6:	1141                	addi	sp,sp,-16
    800034a8:	e422                	sd	s0,8(sp)
    800034aa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800034ac:	00003797          	auipc	a5,0x3
    800034b0:	7f478793          	addi	a5,a5,2036 # 80006ca0 <kernelvec>
    800034b4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800034b8:	6422                	ld	s0,8(sp)
    800034ba:	0141                	addi	sp,sp,16
    800034bc:	8082                	ret

00000000800034be <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800034be:	1101                	addi	sp,sp,-32
    800034c0:	ec06                	sd	ra,24(sp)
    800034c2:	e822                	sd	s0,16(sp)
    800034c4:	e426                	sd	s1,8(sp)
    800034c6:	e04a                	sd	s2,0(sp)
    800034c8:	1000                	addi	s0,sp,32
  struct thread *t = mythread(); // ADDED Q3
    800034ca:	ffffe097          	auipc	ra,0xffffe
    800034ce:	5c6080e7          	jalr	1478(ra) # 80001a90 <mythread>
    800034d2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800034d4:	ffffe097          	auipc	ra,0xffffe
    800034d8:	582080e7          	jalr	1410(ra) # 80001a56 <myproc>
    800034dc:	892a                	mv	s2,a0

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  handle_signals(); // ADDED Q2.4 
    800034de:	fffff097          	auipc	ra,0xfffff
    800034e2:	0aa080e7          	jalr	170(ra) # 80002588 <handle_signals>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800034ea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034ec:	10079073          	csrw	sstatus,a5

  intr_off();
  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800034f0:	00005617          	auipc	a2,0x5
    800034f4:	b1060613          	addi	a2,a2,-1264 # 80008000 <_trampoline>
    800034f8:	00005697          	auipc	a3,0x5
    800034fc:	b0868693          	addi	a3,a3,-1272 # 80008000 <_trampoline>
    80003500:	8e91                	sub	a3,a3,a2
    80003502:	040007b7          	lui	a5,0x4000
    80003506:	17fd                	addi	a5,a5,-1
    80003508:	07b2                	slli	a5,a5,0xc
    8000350a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000350c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  t->trapframe->kernel_satp = r_satp();         // kernel page table
    80003510:	64b8                	ld	a4,72(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003512:	180026f3          	csrr	a3,satp
    80003516:	e314                	sd	a3,0(a4)
  t->trapframe->kernel_sp = t->kstack + PGSIZE; // thread's kernel stack
    80003518:	64b8                	ld	a4,72(s1)
    8000351a:	60b4                	ld	a3,64(s1)
    8000351c:	6585                	lui	a1,0x1
    8000351e:	96ae                	add	a3,a3,a1
    80003520:	e714                	sd	a3,8(a4)
  t->trapframe->kernel_trap = (uint64)usertrap;
    80003522:	64b8                	ld	a4,72(s1)
    80003524:	00000697          	auipc	a3,0x0
    80003528:	14a68693          	addi	a3,a3,330 # 8000366e <usertrap>
    8000352c:	eb14                	sd	a3,16(a4)
  t->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000352e:	64b8                	ld	a4,72(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003530:	8692                	mv	a3,tp
    80003532:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003534:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003538:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000353c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003540:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(t->trapframe->epc);
    80003544:	64b8                	ld	a4,72(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003546:	6f18                	ld	a4,24(a4)
    80003548:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000354c:	1d893583          	ld	a1,472(s2)
    80003550:	81b1                	srli	a1,a1,0xc
  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    80003552:	58d8                	lw	a4,52(s1)
    80003554:	00371513          	slli	a0,a4,0x3
    80003558:	953a                	add	a0,a0,a4
    8000355a:	0516                	slli	a0,a0,0x5
    8000355c:	020006b7          	lui	a3,0x2000
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003560:	00005717          	auipc	a4,0x5
    80003564:	b3070713          	addi	a4,a4,-1232 # 80008090 <userret>
    80003568:	8f11                	sub	a4,a4,a2
    8000356a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    8000356c:	577d                	li	a4,-1
    8000356e:	177e                	slli	a4,a4,0x3f
    80003570:	8dd9                	or	a1,a1,a4
    80003572:	16fd                	addi	a3,a3,-1
    80003574:	06b6                	slli	a3,a3,0xd
    80003576:	9536                	add	a0,a0,a3
    80003578:	9782                	jalr	a5
}
    8000357a:	60e2                	ld	ra,24(sp)
    8000357c:	6442                	ld	s0,16(sp)
    8000357e:	64a2                	ld	s1,8(sp)
    80003580:	6902                	ld	s2,0(sp)
    80003582:	6105                	addi	sp,sp,32
    80003584:	8082                	ret

0000000080003586 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003586:	1101                	addi	sp,sp,-32
    80003588:	ec06                	sd	ra,24(sp)
    8000358a:	e822                	sd	s0,16(sp)
    8000358c:	e426                	sd	s1,8(sp)
    8000358e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003590:	00032497          	auipc	s1,0x32
    80003594:	57048493          	addi	s1,s1,1392 # 80035b00 <tickslock>
    80003598:	8526                	mv	a0,s1
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	628080e7          	jalr	1576(ra) # 80000bc2 <acquire>
  ticks++;
    800035a2:	00007517          	auipc	a0,0x7
    800035a6:	a8e50513          	addi	a0,a0,-1394 # 8000a030 <ticks>
    800035aa:	411c                	lw	a5,0(a0)
    800035ac:	2785                	addiw	a5,a5,1
    800035ae:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800035b0:	fffff097          	auipc	ra,0xfffff
    800035b4:	28e080e7          	jalr	654(ra) # 8000283e <wakeup>
  release(&tickslock);
    800035b8:	8526                	mv	a0,s1
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	6bc080e7          	jalr	1724(ra) # 80000c76 <release>
}
    800035c2:	60e2                	ld	ra,24(sp)
    800035c4:	6442                	ld	s0,16(sp)
    800035c6:	64a2                	ld	s1,8(sp)
    800035c8:	6105                	addi	sp,sp,32
    800035ca:	8082                	ret

00000000800035cc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800035cc:	1101                	addi	sp,sp,-32
    800035ce:	ec06                	sd	ra,24(sp)
    800035d0:	e822                	sd	s0,16(sp)
    800035d2:	e426                	sd	s1,8(sp)
    800035d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035d6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800035da:	00074d63          	bltz	a4,800035f4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800035de:	57fd                	li	a5,-1
    800035e0:	17fe                	slli	a5,a5,0x3f
    800035e2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800035e4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800035e6:	06f70363          	beq	a4,a5,8000364c <devintr+0x80>
  }
}
    800035ea:	60e2                	ld	ra,24(sp)
    800035ec:	6442                	ld	s0,16(sp)
    800035ee:	64a2                	ld	s1,8(sp)
    800035f0:	6105                	addi	sp,sp,32
    800035f2:	8082                	ret
     (scause & 0xff) == 9){
    800035f4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800035f8:	46a5                	li	a3,9
    800035fa:	fed792e3          	bne	a5,a3,800035de <devintr+0x12>
    int irq = plic_claim();
    800035fe:	00003097          	auipc	ra,0x3
    80003602:	7aa080e7          	jalr	1962(ra) # 80006da8 <plic_claim>
    80003606:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003608:	47a9                	li	a5,10
    8000360a:	02f50763          	beq	a0,a5,80003638 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000360e:	4785                	li	a5,1
    80003610:	02f50963          	beq	a0,a5,80003642 <devintr+0x76>
    return 1;
    80003614:	4505                	li	a0,1
    } else if(irq){
    80003616:	d8f1                	beqz	s1,800035ea <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003618:	85a6                	mv	a1,s1
    8000361a:	00006517          	auipc	a0,0x6
    8000361e:	cce50513          	addi	a0,a0,-818 # 800092e8 <states.0+0x20>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	f52080e7          	jalr	-174(ra) # 80000574 <printf>
      plic_complete(irq);
    8000362a:	8526                	mv	a0,s1
    8000362c:	00003097          	auipc	ra,0x3
    80003630:	7a0080e7          	jalr	1952(ra) # 80006dcc <plic_complete>
    return 1;
    80003634:	4505                	li	a0,1
    80003636:	bf55                	j	800035ea <devintr+0x1e>
      uartintr();
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	34e080e7          	jalr	846(ra) # 80000986 <uartintr>
    80003640:	b7ed                	j	8000362a <devintr+0x5e>
      virtio_disk_intr();
    80003642:	00004097          	auipc	ra,0x4
    80003646:	c1c080e7          	jalr	-996(ra) # 8000725e <virtio_disk_intr>
    8000364a:	b7c5                	j	8000362a <devintr+0x5e>
    if(cpuid() == 0){
    8000364c:	ffffe097          	auipc	ra,0xffffe
    80003650:	3de080e7          	jalr	990(ra) # 80001a2a <cpuid>
    80003654:	c901                	beqz	a0,80003664 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003656:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000365a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000365c:	14479073          	csrw	sip,a5
    return 2;
    80003660:	4509                	li	a0,2
    80003662:	b761                	j	800035ea <devintr+0x1e>
      clockintr();
    80003664:	00000097          	auipc	ra,0x0
    80003668:	f22080e7          	jalr	-222(ra) # 80003586 <clockintr>
    8000366c:	b7ed                	j	80003656 <devintr+0x8a>

000000008000366e <usertrap>:
{
    8000366e:	7179                	addi	sp,sp,-48
    80003670:	f406                	sd	ra,40(sp)
    80003672:	f022                	sd	s0,32(sp)
    80003674:	ec26                	sd	s1,24(sp)
    80003676:	e84a                	sd	s2,16(sp)
    80003678:	e44e                	sd	s3,8(sp)
    8000367a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000367c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003680:	1007f793          	andi	a5,a5,256
    80003684:	e3c9                	bnez	a5,80003706 <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003686:	00003797          	auipc	a5,0x3
    8000368a:	61a78793          	addi	a5,a5,1562 # 80006ca0 <kernelvec>
    8000368e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003692:	ffffe097          	auipc	ra,0xffffe
    80003696:	3c4080e7          	jalr	964(ra) # 80001a56 <myproc>
    8000369a:	892a                	mv	s2,a0
  struct thread *t = mythread(); // ADDED Q3
    8000369c:	ffffe097          	auipc	ra,0xffffe
    800036a0:	3f4080e7          	jalr	1012(ra) # 80001a90 <mythread>
    800036a4:	84aa                	mv	s1,a0
  t->trapframe->epc = r_sepc();
    800036a6:	653c                	ld	a5,72(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800036a8:	14102773          	csrr	a4,sepc
    800036ac:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800036ae:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800036b2:	47a1                	li	a5,8
    800036b4:	06f71d63          	bne	a4,a5,8000372e <usertrap+0xc0>
    if(p->killed)
    800036b8:	01c92783          	lw	a5,28(s2)
    800036bc:	efa9                	bnez	a5,80003716 <usertrap+0xa8>
    if (t->terminated) {
    800036be:	549c                	lw	a5,40(s1)
    800036c0:	e3ad                	bnez	a5,80003722 <usertrap+0xb4>
    t->trapframe->epc += 4;
    800036c2:	64b8                	ld	a4,72(s1)
    800036c4:	6f1c                	ld	a5,24(a4)
    800036c6:	0791                	addi	a5,a5,4
    800036c8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800036ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800036ce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800036d2:	10079073          	csrw	sstatus,a5
    syscall();
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	302080e7          	jalr	770(ra) # 800039d8 <syscall>
  int which_dev = 0;
    800036de:	4981                	li	s3,0
  if(p->killed)
    800036e0:	01c92783          	lw	a5,28(s2)
    800036e4:	e7d1                	bnez	a5,80003770 <usertrap+0x102>
  if (t->terminated) {
    800036e6:	549c                	lw	a5,40(s1)
    800036e8:	ebd1                	bnez	a5,8000377c <usertrap+0x10e>
  if(which_dev == 2)
    800036ea:	4789                	li	a5,2
    800036ec:	08f98e63          	beq	s3,a5,80003788 <usertrap+0x11a>
  usertrapret();
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	dce080e7          	jalr	-562(ra) # 800034be <usertrapret>
}
    800036f8:	70a2                	ld	ra,40(sp)
    800036fa:	7402                	ld	s0,32(sp)
    800036fc:	64e2                	ld	s1,24(sp)
    800036fe:	6942                	ld	s2,16(sp)
    80003700:	69a2                	ld	s3,8(sp)
    80003702:	6145                	addi	sp,sp,48
    80003704:	8082                	ret
    panic("usertrap: not from user mode");
    80003706:	00006517          	auipc	a0,0x6
    8000370a:	c0250513          	addi	a0,a0,-1022 # 80009308 <states.0+0x40>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	e1c080e7          	jalr	-484(ra) # 8000052a <panic>
      exit(-1);
    80003716:	557d                	li	a0,-1
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	83c080e7          	jalr	-1988(ra) # 80002f54 <exit>
    80003720:	bf79                	j	800036be <usertrap+0x50>
      kthread_exit(-1);
    80003722:	557d                	li	a0,-1
    80003724:	00000097          	auipc	ra,0x0
    80003728:	994080e7          	jalr	-1644(ra) # 800030b8 <kthread_exit>
    8000372c:	bf59                	j	800036c2 <usertrap+0x54>
  } else if((which_dev = devintr()) != 0){
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	e9e080e7          	jalr	-354(ra) # 800035cc <devintr>
    80003736:	89aa                	mv	s3,a0
    80003738:	f545                	bnez	a0,800036e0 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000373a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000373e:	02492603          	lw	a2,36(s2)
    80003742:	00006517          	auipc	a0,0x6
    80003746:	be650513          	addi	a0,a0,-1050 # 80009328 <states.0+0x60>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	e2a080e7          	jalr	-470(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003752:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003756:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000375a:	00006517          	auipc	a0,0x6
    8000375e:	bfe50513          	addi	a0,a0,-1026 # 80009358 <states.0+0x90>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	e12080e7          	jalr	-494(ra) # 80000574 <printf>
    p->killed = 1;
    8000376a:	4785                	li	a5,1
    8000376c:	00f92e23          	sw	a5,28(s2)
    exit(-1);
    80003770:	557d                	li	a0,-1
    80003772:	fffff097          	auipc	ra,0xfffff
    80003776:	7e2080e7          	jalr	2018(ra) # 80002f54 <exit>
    8000377a:	b7b5                	j	800036e6 <usertrap+0x78>
    kthread_exit(-1);
    8000377c:	557d                	li	a0,-1
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	93a080e7          	jalr	-1734(ra) # 800030b8 <kthread_exit>
    80003786:	b795                	j	800036ea <usertrap+0x7c>
    yield();
    80003788:	fffff097          	auipc	ra,0xfffff
    8000378c:	d70080e7          	jalr	-656(ra) # 800024f8 <yield>
    80003790:	b785                	j	800036f0 <usertrap+0x82>

0000000080003792 <kerneltrap>:
{
    80003792:	7179                	addi	sp,sp,-48
    80003794:	f406                	sd	ra,40(sp)
    80003796:	f022                	sd	s0,32(sp)
    80003798:	ec26                	sd	s1,24(sp)
    8000379a:	e84a                	sd	s2,16(sp)
    8000379c:	e44e                	sd	s3,8(sp)
    8000379e:	e052                	sd	s4,0(sp)
    800037a0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800037a2:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800037a6:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800037aa:	14202a73          	csrr	s4,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800037ae:	10097793          	andi	a5,s2,256
    800037b2:	cf95                	beqz	a5,800037ee <kerneltrap+0x5c>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800037b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800037b8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800037ba:	e3b1                	bnez	a5,800037fe <kerneltrap+0x6c>
  if((which_dev = devintr()) == 0){
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	e10080e7          	jalr	-496(ra) # 800035cc <devintr>
    800037c4:	84aa                	mv	s1,a0
    800037c6:	c521                	beqz	a0,8000380e <kerneltrap+0x7c>
  struct thread *t = mythread();
    800037c8:	ffffe097          	auipc	ra,0xffffe
    800037cc:	2c8080e7          	jalr	712(ra) # 80001a90 <mythread>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    800037d0:	4789                	li	a5,2
    800037d2:	06f48b63          	beq	s1,a5,80003848 <kerneltrap+0xb6>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800037d6:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800037da:	10091073          	csrw	sstatus,s2
}
    800037de:	70a2                	ld	ra,40(sp)
    800037e0:	7402                	ld	s0,32(sp)
    800037e2:	64e2                	ld	s1,24(sp)
    800037e4:	6942                	ld	s2,16(sp)
    800037e6:	69a2                	ld	s3,8(sp)
    800037e8:	6a02                	ld	s4,0(sp)
    800037ea:	6145                	addi	sp,sp,48
    800037ec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800037ee:	00006517          	auipc	a0,0x6
    800037f2:	b8a50513          	addi	a0,a0,-1142 # 80009378 <states.0+0xb0>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	d34080e7          	jalr	-716(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800037fe:	00006517          	auipc	a0,0x6
    80003802:	ba250513          	addi	a0,a0,-1118 # 800093a0 <states.0+0xd8>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	d24080e7          	jalr	-732(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000380e:	85d2                	mv	a1,s4
    80003810:	00006517          	auipc	a0,0x6
    80003814:	bb050513          	addi	a0,a0,-1104 # 800093c0 <states.0+0xf8>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	d5c080e7          	jalr	-676(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003820:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003824:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003828:	00006517          	auipc	a0,0x6
    8000382c:	ba850513          	addi	a0,a0,-1112 # 800093d0 <states.0+0x108>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	d44080e7          	jalr	-700(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003838:	00006517          	auipc	a0,0x6
    8000383c:	bb050513          	addi	a0,a0,-1104 # 800093e8 <states.0+0x120>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	cea080e7          	jalr	-790(ra) # 8000052a <panic>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    80003848:	d559                	beqz	a0,800037d6 <kerneltrap+0x44>
    8000384a:	4d18                	lw	a4,24(a0)
    8000384c:	4791                	li	a5,4
    8000384e:	f8f714e3          	bne	a4,a5,800037d6 <kerneltrap+0x44>
    yield();
    80003852:	fffff097          	auipc	ra,0xfffff
    80003856:	ca6080e7          	jalr	-858(ra) # 800024f8 <yield>
    8000385a:	bfb5                	j	800037d6 <kerneltrap+0x44>

000000008000385c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000385c:	1101                	addi	sp,sp,-32
    8000385e:	ec06                	sd	ra,24(sp)
    80003860:	e822                	sd	s0,16(sp)
    80003862:	e426                	sd	s1,8(sp)
    80003864:	1000                	addi	s0,sp,32
    80003866:	84aa                	mv	s1,a0
  struct thread *t = mythread();
    80003868:	ffffe097          	auipc	ra,0xffffe
    8000386c:	228080e7          	jalr	552(ra) # 80001a90 <mythread>
  switch (n) {
    80003870:	4795                	li	a5,5
    80003872:	0497e163          	bltu	a5,s1,800038b4 <argraw+0x58>
    80003876:	048a                	slli	s1,s1,0x2
    80003878:	00006717          	auipc	a4,0x6
    8000387c:	ba870713          	addi	a4,a4,-1112 # 80009420 <states.0+0x158>
    80003880:	94ba                	add	s1,s1,a4
    80003882:	409c                	lw	a5,0(s1)
    80003884:	97ba                	add	a5,a5,a4
    80003886:	8782                	jr	a5
  case 0:
    return t->trapframe->a0;
    80003888:	653c                	ld	a5,72(a0)
    8000388a:	7ba8                	ld	a0,112(a5)
  case 5:
    return t->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000388c:	60e2                	ld	ra,24(sp)
    8000388e:	6442                	ld	s0,16(sp)
    80003890:	64a2                	ld	s1,8(sp)
    80003892:	6105                	addi	sp,sp,32
    80003894:	8082                	ret
    return t->trapframe->a1;
    80003896:	653c                	ld	a5,72(a0)
    80003898:	7fa8                	ld	a0,120(a5)
    8000389a:	bfcd                	j	8000388c <argraw+0x30>
    return t->trapframe->a2;
    8000389c:	653c                	ld	a5,72(a0)
    8000389e:	63c8                	ld	a0,128(a5)
    800038a0:	b7f5                	j	8000388c <argraw+0x30>
    return t->trapframe->a3;
    800038a2:	653c                	ld	a5,72(a0)
    800038a4:	67c8                	ld	a0,136(a5)
    800038a6:	b7dd                	j	8000388c <argraw+0x30>
    return t->trapframe->a4;
    800038a8:	653c                	ld	a5,72(a0)
    800038aa:	6bc8                	ld	a0,144(a5)
    800038ac:	b7c5                	j	8000388c <argraw+0x30>
    return t->trapframe->a5;
    800038ae:	653c                	ld	a5,72(a0)
    800038b0:	6fc8                	ld	a0,152(a5)
    800038b2:	bfe9                	j	8000388c <argraw+0x30>
  panic("argraw");
    800038b4:	00006517          	auipc	a0,0x6
    800038b8:	b4450513          	addi	a0,a0,-1212 # 800093f8 <states.0+0x130>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	c6e080e7          	jalr	-914(ra) # 8000052a <panic>

00000000800038c4 <fetchaddr>:
{
    800038c4:	1101                	addi	sp,sp,-32
    800038c6:	ec06                	sd	ra,24(sp)
    800038c8:	e822                	sd	s0,16(sp)
    800038ca:	e426                	sd	s1,8(sp)
    800038cc:	e04a                	sd	s2,0(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
    800038d2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800038d4:	ffffe097          	auipc	ra,0xffffe
    800038d8:	182080e7          	jalr	386(ra) # 80001a56 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800038dc:	1d053783          	ld	a5,464(a0)
    800038e0:	02f4f963          	bgeu	s1,a5,80003912 <fetchaddr+0x4e>
    800038e4:	00848713          	addi	a4,s1,8
    800038e8:	02e7e763          	bltu	a5,a4,80003916 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800038ec:	46a1                	li	a3,8
    800038ee:	8626                	mv	a2,s1
    800038f0:	85ca                	mv	a1,s2
    800038f2:	1d853503          	ld	a0,472(a0)
    800038f6:	ffffe097          	auipc	ra,0xffffe
    800038fa:	dd4080e7          	jalr	-556(ra) # 800016ca <copyin>
    800038fe:	00a03533          	snez	a0,a0
    80003902:	40a00533          	neg	a0,a0
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	64a2                	ld	s1,8(sp)
    8000390c:	6902                	ld	s2,0(sp)
    8000390e:	6105                	addi	sp,sp,32
    80003910:	8082                	ret
    return -1;
    80003912:	557d                	li	a0,-1
    80003914:	bfcd                	j	80003906 <fetchaddr+0x42>
    80003916:	557d                	li	a0,-1
    80003918:	b7fd                	j	80003906 <fetchaddr+0x42>

000000008000391a <fetchstr>:
{
    8000391a:	7179                	addi	sp,sp,-48
    8000391c:	f406                	sd	ra,40(sp)
    8000391e:	f022                	sd	s0,32(sp)
    80003920:	ec26                	sd	s1,24(sp)
    80003922:	e84a                	sd	s2,16(sp)
    80003924:	e44e                	sd	s3,8(sp)
    80003926:	1800                	addi	s0,sp,48
    80003928:	892a                	mv	s2,a0
    8000392a:	84ae                	mv	s1,a1
    8000392c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000392e:	ffffe097          	auipc	ra,0xffffe
    80003932:	128080e7          	jalr	296(ra) # 80001a56 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003936:	86ce                	mv	a3,s3
    80003938:	864a                	mv	a2,s2
    8000393a:	85a6                	mv	a1,s1
    8000393c:	1d853503          	ld	a0,472(a0)
    80003940:	ffffe097          	auipc	ra,0xffffe
    80003944:	e18080e7          	jalr	-488(ra) # 80001758 <copyinstr>
  if(err < 0)
    80003948:	00054763          	bltz	a0,80003956 <fetchstr+0x3c>
  return strlen(buf);
    8000394c:	8526                	mv	a0,s1
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	4f4080e7          	jalr	1268(ra) # 80000e42 <strlen>
}
    80003956:	70a2                	ld	ra,40(sp)
    80003958:	7402                	ld	s0,32(sp)
    8000395a:	64e2                	ld	s1,24(sp)
    8000395c:	6942                	ld	s2,16(sp)
    8000395e:	69a2                	ld	s3,8(sp)
    80003960:	6145                	addi	sp,sp,48
    80003962:	8082                	ret

0000000080003964 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003964:	1101                	addi	sp,sp,-32
    80003966:	ec06                	sd	ra,24(sp)
    80003968:	e822                	sd	s0,16(sp)
    8000396a:	e426                	sd	s1,8(sp)
    8000396c:	1000                	addi	s0,sp,32
    8000396e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003970:	00000097          	auipc	ra,0x0
    80003974:	eec080e7          	jalr	-276(ra) # 8000385c <argraw>
    80003978:	c088                	sw	a0,0(s1)
  return 0;
}
    8000397a:	4501                	li	a0,0
    8000397c:	60e2                	ld	ra,24(sp)
    8000397e:	6442                	ld	s0,16(sp)
    80003980:	64a2                	ld	s1,8(sp)
    80003982:	6105                	addi	sp,sp,32
    80003984:	8082                	ret

0000000080003986 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	1000                	addi	s0,sp,32
    80003990:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003992:	00000097          	auipc	ra,0x0
    80003996:	eca080e7          	jalr	-310(ra) # 8000385c <argraw>
    8000399a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000399c:	4501                	li	a0,0
    8000399e:	60e2                	ld	ra,24(sp)
    800039a0:	6442                	ld	s0,16(sp)
    800039a2:	64a2                	ld	s1,8(sp)
    800039a4:	6105                	addi	sp,sp,32
    800039a6:	8082                	ret

00000000800039a8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800039a8:	1101                	addi	sp,sp,-32
    800039aa:	ec06                	sd	ra,24(sp)
    800039ac:	e822                	sd	s0,16(sp)
    800039ae:	e426                	sd	s1,8(sp)
    800039b0:	e04a                	sd	s2,0(sp)
    800039b2:	1000                	addi	s0,sp,32
    800039b4:	84ae                	mv	s1,a1
    800039b6:	8932                	mv	s2,a2
  *ip = argraw(n);
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	ea4080e7          	jalr	-348(ra) # 8000385c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800039c0:	864a                	mv	a2,s2
    800039c2:	85a6                	mv	a1,s1
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	f56080e7          	jalr	-170(ra) # 8000391a <fetchstr>
}
    800039cc:	60e2                	ld	ra,24(sp)
    800039ce:	6442                	ld	s0,16(sp)
    800039d0:	64a2                	ld	s1,8(sp)
    800039d2:	6902                	ld	s2,0(sp)
    800039d4:	6105                	addi	sp,sp,32
    800039d6:	8082                	ret

00000000800039d8 <syscall>:

};

void
syscall(void)
{
    800039d8:	1101                	addi	sp,sp,-32
    800039da:	ec06                	sd	ra,24(sp)
    800039dc:	e822                	sd	s0,16(sp)
    800039de:	e426                	sd	s1,8(sp)
    800039e0:	e04a                	sd	s2,0(sp)
    800039e2:	1000                	addi	s0,sp,32
  int num;
  struct thread *t = mythread();
    800039e4:	ffffe097          	auipc	ra,0xffffe
    800039e8:	0ac080e7          	jalr	172(ra) # 80001a90 <mythread>
    800039ec:	84aa                	mv	s1,a0

  num = t->trapframe->a7;
    800039ee:	04853903          	ld	s2,72(a0)
    800039f2:	0a893783          	ld	a5,168(s2)
    800039f6:	0007861b          	sext.w	a2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800039fa:	37fd                	addiw	a5,a5,-1
    800039fc:	477d                	li	a4,31
    800039fe:	00f76f63          	bltu	a4,a5,80003a1c <syscall+0x44>
    80003a02:	00361713          	slli	a4,a2,0x3
    80003a06:	00006797          	auipc	a5,0x6
    80003a0a:	a3278793          	addi	a5,a5,-1486 # 80009438 <syscalls>
    80003a0e:	97ba                	add	a5,a5,a4
    80003a10:	639c                	ld	a5,0(a5)
    80003a12:	c789                	beqz	a5,80003a1c <syscall+0x44>
    t->trapframe->a0 = syscalls[num]();
    80003a14:	9782                	jalr	a5
    80003a16:	06a93823          	sd	a0,112(s2)
    80003a1a:	a829                	j	80003a34 <syscall+0x5c>
  } else {
    printf("thread %d: unknown sys call %d\n",
    80003a1c:	588c                	lw	a1,48(s1)
    80003a1e:	00006517          	auipc	a0,0x6
    80003a22:	9e250513          	addi	a0,a0,-1566 # 80009400 <states.0+0x138>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	b4e080e7          	jalr	-1202(ra) # 80000574 <printf>
            t->tid, num);
    t->trapframe->a0 = -1;
    80003a2e:	64bc                	ld	a5,72(s1)
    80003a30:	577d                	li	a4,-1
    80003a32:	fbb8                	sd	a4,112(a5)
  }
}
    80003a34:	60e2                	ld	ra,24(sp)
    80003a36:	6442                	ld	s0,16(sp)
    80003a38:	64a2                	ld	s1,8(sp)
    80003a3a:	6902                	ld	s2,0(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret

0000000080003a40 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003a48:	fec40593          	addi	a1,s0,-20
    80003a4c:	4501                	li	a0,0
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	f16080e7          	jalr	-234(ra) # 80003964 <argint>
    return -1;
    80003a56:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003a58:	00054963          	bltz	a0,80003a6a <sys_exit+0x2a>
  exit(n);
    80003a5c:	fec42503          	lw	a0,-20(s0)
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	4f4080e7          	jalr	1268(ra) # 80002f54 <exit>
  return 0;  // not reached
    80003a68:	4781                	li	a5,0
}
    80003a6a:	853e                	mv	a0,a5
    80003a6c:	60e2                	ld	ra,24(sp)
    80003a6e:	6442                	ld	s0,16(sp)
    80003a70:	6105                	addi	sp,sp,32
    80003a72:	8082                	ret

0000000080003a74 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003a74:	1141                	addi	sp,sp,-16
    80003a76:	e406                	sd	ra,8(sp)
    80003a78:	e022                	sd	s0,0(sp)
    80003a7a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003a7c:	ffffe097          	auipc	ra,0xffffe
    80003a80:	fda080e7          	jalr	-38(ra) # 80001a56 <myproc>
}
    80003a84:	5148                	lw	a0,36(a0)
    80003a86:	60a2                	ld	ra,8(sp)
    80003a88:	6402                	ld	s0,0(sp)
    80003a8a:	0141                	addi	sp,sp,16
    80003a8c:	8082                	ret

0000000080003a8e <sys_fork>:

uint64
sys_fork(void)
{
    80003a8e:	1141                	addi	sp,sp,-16
    80003a90:	e406                	sd	ra,8(sp)
    80003a92:	e022                	sd	s0,0(sp)
    80003a94:	0800                	addi	s0,sp,16
  return fork();
    80003a96:	ffffe097          	auipc	ra,0xffffe
    80003a9a:	5d0080e7          	jalr	1488(ra) # 80002066 <fork>
}
    80003a9e:	60a2                	ld	ra,8(sp)
    80003aa0:	6402                	ld	s0,0(sp)
    80003aa2:	0141                	addi	sp,sp,16
    80003aa4:	8082                	ret

0000000080003aa6 <sys_wait>:

uint64
sys_wait(void)
{
    80003aa6:	1101                	addi	sp,sp,-32
    80003aa8:	ec06                	sd	ra,24(sp)
    80003aaa:	e822                	sd	s0,16(sp)
    80003aac:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003aae:	fe840593          	addi	a1,s0,-24
    80003ab2:	4501                	li	a0,0
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	ed2080e7          	jalr	-302(ra) # 80003986 <argaddr>
    80003abc:	87aa                	mv	a5,a0
    return -1;
    80003abe:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003ac0:	0007c863          	bltz	a5,80003ad0 <sys_wait+0x2a>
  return wait(p);
    80003ac4:	fe843503          	ld	a0,-24(s0)
    80003ac8:	fffff097          	auipc	ra,0xfffff
    80003acc:	c50080e7          	jalr	-944(ra) # 80002718 <wait>
}
    80003ad0:	60e2                	ld	ra,24(sp)
    80003ad2:	6442                	ld	s0,16(sp)
    80003ad4:	6105                	addi	sp,sp,32
    80003ad6:	8082                	ret

0000000080003ad8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003ad8:	7179                	addi	sp,sp,-48
    80003ada:	f406                	sd	ra,40(sp)
    80003adc:	f022                	sd	s0,32(sp)
    80003ade:	ec26                	sd	s1,24(sp)
    80003ae0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003ae2:	fdc40593          	addi	a1,s0,-36
    80003ae6:	4501                	li	a0,0
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	e7c080e7          	jalr	-388(ra) # 80003964 <argint>
    return -1;
    80003af0:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003af2:	02054063          	bltz	a0,80003b12 <sys_sbrk+0x3a>
  addr = myproc()->sz;
    80003af6:	ffffe097          	auipc	ra,0xffffe
    80003afa:	f60080e7          	jalr	-160(ra) # 80001a56 <myproc>
    80003afe:	1d052483          	lw	s1,464(a0)
  if(growproc(n) < 0)
    80003b02:	fdc42503          	lw	a0,-36(s0)
    80003b06:	ffffe097          	auipc	ra,0xffffe
    80003b0a:	4c6080e7          	jalr	1222(ra) # 80001fcc <growproc>
    80003b0e:	00054863          	bltz	a0,80003b1e <sys_sbrk+0x46>
    return -1;
  return addr;
}
    80003b12:	8526                	mv	a0,s1
    80003b14:	70a2                	ld	ra,40(sp)
    80003b16:	7402                	ld	s0,32(sp)
    80003b18:	64e2                	ld	s1,24(sp)
    80003b1a:	6145                	addi	sp,sp,48
    80003b1c:	8082                	ret
    return -1;
    80003b1e:	54fd                	li	s1,-1
    80003b20:	bfcd                	j	80003b12 <sys_sbrk+0x3a>

0000000080003b22 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003b22:	7139                	addi	sp,sp,-64
    80003b24:	fc06                	sd	ra,56(sp)
    80003b26:	f822                	sd	s0,48(sp)
    80003b28:	f426                	sd	s1,40(sp)
    80003b2a:	f04a                	sd	s2,32(sp)
    80003b2c:	ec4e                	sd	s3,24(sp)
    80003b2e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003b30:	fcc40593          	addi	a1,s0,-52
    80003b34:	4501                	li	a0,0
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	e2e080e7          	jalr	-466(ra) # 80003964 <argint>
    return -1;
    80003b3e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003b40:	06054563          	bltz	a0,80003baa <sys_sleep+0x88>
  acquire(&tickslock);
    80003b44:	00032517          	auipc	a0,0x32
    80003b48:	fbc50513          	addi	a0,a0,-68 # 80035b00 <tickslock>
    80003b4c:	ffffd097          	auipc	ra,0xffffd
    80003b50:	076080e7          	jalr	118(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003b54:	00006917          	auipc	s2,0x6
    80003b58:	4dc92903          	lw	s2,1244(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    80003b5c:	fcc42783          	lw	a5,-52(s0)
    80003b60:	cf85                	beqz	a5,80003b98 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003b62:	00032997          	auipc	s3,0x32
    80003b66:	f9e98993          	addi	s3,s3,-98 # 80035b00 <tickslock>
    80003b6a:	00006497          	auipc	s1,0x6
    80003b6e:	4c648493          	addi	s1,s1,1222 # 8000a030 <ticks>
    if(myproc()->killed){
    80003b72:	ffffe097          	auipc	ra,0xffffe
    80003b76:	ee4080e7          	jalr	-284(ra) # 80001a56 <myproc>
    80003b7a:	4d5c                	lw	a5,28(a0)
    80003b7c:	ef9d                	bnez	a5,80003bba <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003b7e:	85ce                	mv	a1,s3
    80003b80:	8526                	mv	a0,s1
    80003b82:	fffff097          	auipc	ra,0xfffff
    80003b86:	b32080e7          	jalr	-1230(ra) # 800026b4 <sleep>
  while(ticks - ticks0 < n){
    80003b8a:	409c                	lw	a5,0(s1)
    80003b8c:	412787bb          	subw	a5,a5,s2
    80003b90:	fcc42703          	lw	a4,-52(s0)
    80003b94:	fce7efe3          	bltu	a5,a4,80003b72 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003b98:	00032517          	auipc	a0,0x32
    80003b9c:	f6850513          	addi	a0,a0,-152 # 80035b00 <tickslock>
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	0d6080e7          	jalr	214(ra) # 80000c76 <release>
  return 0;
    80003ba8:	4781                	li	a5,0
}
    80003baa:	853e                	mv	a0,a5
    80003bac:	70e2                	ld	ra,56(sp)
    80003bae:	7442                	ld	s0,48(sp)
    80003bb0:	74a2                	ld	s1,40(sp)
    80003bb2:	7902                	ld	s2,32(sp)
    80003bb4:	69e2                	ld	s3,24(sp)
    80003bb6:	6121                	addi	sp,sp,64
    80003bb8:	8082                	ret
      release(&tickslock);
    80003bba:	00032517          	auipc	a0,0x32
    80003bbe:	f4650513          	addi	a0,a0,-186 # 80035b00 <tickslock>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	0b4080e7          	jalr	180(ra) # 80000c76 <release>
      return -1;
    80003bca:	57fd                	li	a5,-1
    80003bcc:	bff9                	j	80003baa <sys_sleep+0x88>

0000000080003bce <sys_kill>:

// ADDED Q2.2.1
uint64
sys_kill(void)
{
    80003bce:	1101                	addi	sp,sp,-32
    80003bd0:	ec06                	sd	ra,24(sp)
    80003bd2:	e822                	sd	s0,16(sp)
    80003bd4:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    80003bd6:	fec40593          	addi	a1,s0,-20
    80003bda:	4501                	li	a0,0
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	d88080e7          	jalr	-632(ra) # 80003964 <argint>
    return -1;
    80003be4:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80003be6:	02054563          	bltz	a0,80003c10 <sys_kill+0x42>

  if(argint(1, &signum) < 0)
    80003bea:	fe840593          	addi	a1,s0,-24
    80003bee:	4505                	li	a0,1
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	d74080e7          	jalr	-652(ra) # 80003964 <argint>
    return -1;
    80003bf8:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    80003bfa:	00054b63          	bltz	a0,80003c10 <sys_kill+0x42>

  return kill(pid, signum);
    80003bfe:	fe842583          	lw	a1,-24(s0)
    80003c02:	fec42503          	lw	a0,-20(s0)
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	d2e080e7          	jalr	-722(ra) # 80002934 <kill>
    80003c0e:	87aa                	mv	a5,a0
}
    80003c10:	853e                	mv	a0,a5
    80003c12:	60e2                	ld	ra,24(sp)
    80003c14:	6442                	ld	s0,16(sp)
    80003c16:	6105                	addi	sp,sp,32
    80003c18:	8082                	ret

0000000080003c1a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003c1a:	1101                	addi	sp,sp,-32
    80003c1c:	ec06                	sd	ra,24(sp)
    80003c1e:	e822                	sd	s0,16(sp)
    80003c20:	e426                	sd	s1,8(sp)
    80003c22:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003c24:	00032517          	auipc	a0,0x32
    80003c28:	edc50513          	addi	a0,a0,-292 # 80035b00 <tickslock>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	f96080e7          	jalr	-106(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003c34:	00006497          	auipc	s1,0x6
    80003c38:	3fc4a483          	lw	s1,1020(s1) # 8000a030 <ticks>
  release(&tickslock);
    80003c3c:	00032517          	auipc	a0,0x32
    80003c40:	ec450513          	addi	a0,a0,-316 # 80035b00 <tickslock>
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	032080e7          	jalr	50(ra) # 80000c76 <release>
  return xticks;
}
    80003c4c:	02049513          	slli	a0,s1,0x20
    80003c50:	9101                	srli	a0,a0,0x20
    80003c52:	60e2                	ld	ra,24(sp)
    80003c54:	6442                	ld	s0,16(sp)
    80003c56:	64a2                	ld	s1,8(sp)
    80003c58:	6105                	addi	sp,sp,32
    80003c5a:	8082                	ret

0000000080003c5c <sys_sigprocmask>:

// ADDED Q2.1.3
uint64
sys_sigprocmask(void)
{
    80003c5c:	1101                	addi	sp,sp,-32
    80003c5e:	ec06                	sd	ra,24(sp)
    80003c60:	e822                	sd	s0,16(sp)
    80003c62:	1000                	addi	s0,sp,32
  uint sigmask;

  if(argint(0, (int *)&sigmask) < 0) 
    80003c64:	fec40593          	addi	a1,s0,-20
    80003c68:	4501                	li	a0,0
    80003c6a:	00000097          	auipc	ra,0x0
    80003c6e:	cfa080e7          	jalr	-774(ra) # 80003964 <argint>
    80003c72:	87aa                	mv	a5,a0
    return -1;
    80003c74:	557d                	li	a0,-1
  if(argint(0, (int *)&sigmask) < 0) 
    80003c76:	0007ca63          	bltz	a5,80003c8a <sys_sigprocmask+0x2e>

  return sigprocmask(sigmask);
    80003c7a:	fec42503          	lw	a0,-20(s0)
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	ea2080e7          	jalr	-350(ra) # 80002b20 <sigprocmask>
    80003c86:	1502                	slli	a0,a0,0x20
    80003c88:	9101                	srli	a0,a0,0x20
}
    80003c8a:	60e2                	ld	ra,24(sp)
    80003c8c:	6442                	ld	s0,16(sp)
    80003c8e:	6105                	addi	sp,sp,32
    80003c90:	8082                	ret

0000000080003c92 <sys_sigaction>:

// ADDED Q2.1.4
uint64
sys_sigaction(void)
{
    80003c92:	7179                	addi	sp,sp,-48
    80003c94:	f406                	sd	ra,40(sp)
    80003c96:	f022                	sd	s0,32(sp)
    80003c98:	1800                	addi	s0,sp,48
  int signum;
  struct sigaction *act;
  struct sigaction *oldact;

  if(argint(0, &signum) < 0)
    80003c9a:	fec40593          	addi	a1,s0,-20
    80003c9e:	4501                	li	a0,0
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	cc4080e7          	jalr	-828(ra) # 80003964 <argint>
    return -1;
    80003ca8:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    80003caa:	04054163          	bltz	a0,80003cec <sys_sigaction+0x5a>

  if(argaddr(1, (uint64 *)&act) < 0)
    80003cae:	fe040593          	addi	a1,s0,-32
    80003cb2:	4505                	li	a0,1
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	cd2080e7          	jalr	-814(ra) # 80003986 <argaddr>
    return -1;
    80003cbc:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&act) < 0)
    80003cbe:	02054763          	bltz	a0,80003cec <sys_sigaction+0x5a>

  if(argaddr(2, (uint64 *)&oldact) < 0)
    80003cc2:	fd840593          	addi	a1,s0,-40
    80003cc6:	4509                	li	a0,2
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	cbe080e7          	jalr	-834(ra) # 80003986 <argaddr>
    return -1;
    80003cd0:	57fd                	li	a5,-1
  if(argaddr(2, (uint64 *)&oldact) < 0)
    80003cd2:	00054d63          	bltz	a0,80003cec <sys_sigaction+0x5a>

  return sigaction(signum, act, oldact);
    80003cd6:	fd843603          	ld	a2,-40(s0)
    80003cda:	fe043583          	ld	a1,-32(s0)
    80003cde:	fec42503          	lw	a0,-20(s0)
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	e9e080e7          	jalr	-354(ra) # 80002b80 <sigaction>
    80003cea:	87aa                	mv	a5,a0
}
    80003cec:	853e                	mv	a0,a5
    80003cee:	70a2                	ld	ra,40(sp)
    80003cf0:	7402                	ld	s0,32(sp)
    80003cf2:	6145                	addi	sp,sp,48
    80003cf4:	8082                	ret

0000000080003cf6 <sys_sigret>:

// ADDED Q2.1.5
uint64
sys_sigret(void)
{
    80003cf6:	1141                	addi	sp,sp,-16
    80003cf8:	e406                	sd	ra,8(sp)
    80003cfa:	e022                	sd	s0,0(sp)
    80003cfc:	0800                	addi	s0,sp,16
  sigret();
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	fc2080e7          	jalr	-62(ra) # 80002cc0 <sigret>
  return 0;
}
    80003d06:	4501                	li	a0,0
    80003d08:	60a2                	ld	ra,8(sp)
    80003d0a:	6402                	ld	s0,0(sp)
    80003d0c:	0141                	addi	sp,sp,16
    80003d0e:	8082                	ret

0000000080003d10 <sys_kthread_create>:

// ADDED Q3.2
uint64
sys_kthread_create(void)
{
    80003d10:	1101                	addi	sp,sp,-32
    80003d12:	ec06                	sd	ra,24(sp)
    80003d14:	e822                	sd	s0,16(sp)
    80003d16:	1000                	addi	s0,sp,32
  uint64 start_func;
  uint64 stack;

  if(argaddr(0, &start_func) < 0)
    80003d18:	fe840593          	addi	a1,s0,-24
    80003d1c:	4501                	li	a0,0
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	c68080e7          	jalr	-920(ra) # 80003986 <argaddr>
    return -1;
    80003d26:	57fd                	li	a5,-1
  if(argaddr(0, &start_func) < 0)
    80003d28:	02054563          	bltz	a0,80003d52 <sys_kthread_create+0x42>

  if(argaddr(1, &stack) < 0)
    80003d2c:	fe040593          	addi	a1,s0,-32
    80003d30:	4505                	li	a0,1
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	c54080e7          	jalr	-940(ra) # 80003986 <argaddr>
    return -1;
    80003d3a:	57fd                	li	a5,-1
  if(argaddr(1, &stack) < 0)
    80003d3c:	00054b63          	bltz	a0,80003d52 <sys_kthread_create+0x42>

  return kthread_create((void (*)())start_func, (void *)stack);
    80003d40:	fe043583          	ld	a1,-32(s0)
    80003d44:	fe843503          	ld	a0,-24(s0)
    80003d48:	fffff097          	auipc	ra,0xfffff
    80003d4c:	fe6080e7          	jalr	-26(ra) # 80002d2e <kthread_create>
    80003d50:	87aa                	mv	a5,a0
}
    80003d52:	853e                	mv	a0,a5
    80003d54:	60e2                	ld	ra,24(sp)
    80003d56:	6442                	ld	s0,16(sp)
    80003d58:	6105                	addi	sp,sp,32
    80003d5a:	8082                	ret

0000000080003d5c <sys_kthread_id>:

uint64
sys_kthread_id(void)
{
    80003d5c:	1141                	addi	sp,sp,-16
    80003d5e:	e406                	sd	ra,8(sp)
    80003d60:	e022                	sd	s0,0(sp)
    80003d62:	0800                	addi	s0,sp,16
  return mythread()->tid;
    80003d64:	ffffe097          	auipc	ra,0xffffe
    80003d68:	d2c080e7          	jalr	-724(ra) # 80001a90 <mythread>
}
    80003d6c:	5908                	lw	a0,48(a0)
    80003d6e:	60a2                	ld	ra,8(sp)
    80003d70:	6402                	ld	s0,0(sp)
    80003d72:	0141                	addi	sp,sp,16
    80003d74:	8082                	ret

0000000080003d76 <sys_kthread_exit>:

uint64
sys_kthread_exit(void)
{
    80003d76:	1101                	addi	sp,sp,-32
    80003d78:	ec06                	sd	ra,24(sp)
    80003d7a:	e822                	sd	s0,16(sp)
    80003d7c:	1000                	addi	s0,sp,32
  int status;

  if(argint(0, &status) < 0)
    80003d7e:	fec40593          	addi	a1,s0,-20
    80003d82:	4501                	li	a0,0
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	be0080e7          	jalr	-1056(ra) # 80003964 <argint>
    return -1;
    80003d8c:	57fd                	li	a5,-1
  if(argint(0, &status) < 0)
    80003d8e:	00054963          	bltz	a0,80003da0 <sys_kthread_exit+0x2a>

  kthread_exit(status);
    80003d92:	fec42503          	lw	a0,-20(s0)
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	322080e7          	jalr	802(ra) # 800030b8 <kthread_exit>
  return 0;
    80003d9e:	4781                	li	a5,0
}
    80003da0:	853e                	mv	a0,a5
    80003da2:	60e2                	ld	ra,24(sp)
    80003da4:	6442                	ld	s0,16(sp)
    80003da6:	6105                	addi	sp,sp,32
    80003da8:	8082                	ret

0000000080003daa <sys_kthread_join>:

uint64
sys_kthread_join(void)
{
    80003daa:	1101                	addi	sp,sp,-32
    80003dac:	ec06                	sd	ra,24(sp)
    80003dae:	e822                	sd	s0,16(sp)
    80003db0:	1000                	addi	s0,sp,32
  int thread_id;
  int *status;

  if(argint(0, &thread_id) < 0)
    80003db2:	fec40593          	addi	a1,s0,-20
    80003db6:	4501                	li	a0,0
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	bac080e7          	jalr	-1108(ra) # 80003964 <argint>
    return -1;
    80003dc0:	57fd                	li	a5,-1
  if(argint(0, &thread_id) < 0)
    80003dc2:	02054563          	bltz	a0,80003dec <sys_kthread_join+0x42>

  if(argaddr(1, (uint64 *)&status) < 0)
    80003dc6:	fe040593          	addi	a1,s0,-32
    80003dca:	4505                	li	a0,1
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	bba080e7          	jalr	-1094(ra) # 80003986 <argaddr>
    return -1;
    80003dd4:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&status) < 0)
    80003dd6:	00054b63          	bltz	a0,80003dec <sys_kthread_join+0x42>

  return kthread_join(thread_id, status);
    80003dda:	fe043583          	ld	a1,-32(s0)
    80003dde:	fec42503          	lw	a0,-20(s0)
    80003de2:	fffff097          	auipc	ra,0xfffff
    80003de6:	04c080e7          	jalr	76(ra) # 80002e2e <kthread_join>
    80003dea:	87aa                	mv	a5,a0
}
    80003dec:	853e                	mv	a0,a5
    80003dee:	60e2                	ld	ra,24(sp)
    80003df0:	6442                	ld	s0,16(sp)
    80003df2:	6105                	addi	sp,sp,32
    80003df4:	8082                	ret

0000000080003df6 <sys_bsem_alloc>:

uint64
sys_bsem_alloc(void)
{
    80003df6:	1141                	addi	sp,sp,-16
    80003df8:	e406                	sd	ra,8(sp)
    80003dfa:	e022                	sd	s0,0(sp)
    80003dfc:	0800                	addi	s0,sp,16
  return bsem_alloc();
    80003dfe:	fffff097          	auipc	ra,0xfffff
    80003e02:	3ca080e7          	jalr	970(ra) # 800031c8 <bsem_alloc>
}
    80003e06:	60a2                	ld	ra,8(sp)
    80003e08:	6402                	ld	s0,0(sp)
    80003e0a:	0141                	addi	sp,sp,16
    80003e0c:	8082                	ret

0000000080003e0e <sys_bsem_free>:

uint64
sys_bsem_free(void)
{
    80003e0e:	1101                	addi	sp,sp,-32
    80003e10:	ec06                	sd	ra,24(sp)
    80003e12:	e822                	sd	s0,16(sp)
    80003e14:	1000                	addi	s0,sp,32
  int descriptor;

  if(argint(0, &descriptor) < 0)
    80003e16:	fec40593          	addi	a1,s0,-20
    80003e1a:	4501                	li	a0,0
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	b48080e7          	jalr	-1208(ra) # 80003964 <argint>
    return -1;
    80003e24:	57fd                	li	a5,-1
  if(argint(0, &descriptor) < 0)
    80003e26:	00054963          	bltz	a0,80003e38 <sys_bsem_free+0x2a>
  
  bsem_free(descriptor);
    80003e2a:	fec42503          	lw	a0,-20(s0)
    80003e2e:	fffff097          	auipc	ra,0xfffff
    80003e32:	408080e7          	jalr	1032(ra) # 80003236 <bsem_free>
  return 0;
    80003e36:	4781                	li	a5,0
}
    80003e38:	853e                	mv	a0,a5
    80003e3a:	60e2                	ld	ra,24(sp)
    80003e3c:	6442                	ld	s0,16(sp)
    80003e3e:	6105                	addi	sp,sp,32
    80003e40:	8082                	ret

0000000080003e42 <sys_bsem_down>:

uint64
sys_bsem_down(void)
{
    80003e42:	1101                	addi	sp,sp,-32
    80003e44:	ec06                	sd	ra,24(sp)
    80003e46:	e822                	sd	s0,16(sp)
    80003e48:	1000                	addi	s0,sp,32
  int descriptor;

  if(argint(0, &descriptor) < 0)
    80003e4a:	fec40593          	addi	a1,s0,-20
    80003e4e:	4501                	li	a0,0
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	b14080e7          	jalr	-1260(ra) # 80003964 <argint>
    return -1;
    80003e58:	57fd                	li	a5,-1
  if(argint(0, &descriptor) < 0)
    80003e5a:	00054963          	bltz	a0,80003e6c <sys_bsem_down+0x2a>
  
  bsem_down(descriptor);
    80003e5e:	fec42503          	lw	a0,-20(s0)
    80003e62:	fffff097          	auipc	ra,0xfffff
    80003e66:	434080e7          	jalr	1076(ra) # 80003296 <bsem_down>
  return 0;
    80003e6a:	4781                	li	a5,0
}
    80003e6c:	853e                	mv	a0,a5
    80003e6e:	60e2                	ld	ra,24(sp)
    80003e70:	6442                	ld	s0,16(sp)
    80003e72:	6105                	addi	sp,sp,32
    80003e74:	8082                	ret

0000000080003e76 <sys_bsem_up>:

uint64
sys_bsem_up(void)
{
    80003e76:	1101                	addi	sp,sp,-32
    80003e78:	ec06                	sd	ra,24(sp)
    80003e7a:	e822                	sd	s0,16(sp)
    80003e7c:	1000                	addi	s0,sp,32
  int descriptor;

  if(argint(0, &descriptor) < 0)
    80003e7e:	fec40593          	addi	a1,s0,-20
    80003e82:	4501                	li	a0,0
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	ae0080e7          	jalr	-1312(ra) # 80003964 <argint>
    return -1;
    80003e8c:	57fd                	li	a5,-1
  if(argint(0, &descriptor) < 0)
    80003e8e:	00054963          	bltz	a0,80003ea0 <sys_bsem_up+0x2a>
  
  bsem_up(descriptor);
    80003e92:	fec42503          	lw	a0,-20(s0)
    80003e96:	fffff097          	auipc	ra,0xfffff
    80003e9a:	4c0080e7          	jalr	1216(ra) # 80003356 <bsem_up>
  return 0; 
    80003e9e:	4781                	li	a5,0
}
    80003ea0:	853e                	mv	a0,a5
    80003ea2:	60e2                	ld	ra,24(sp)
    80003ea4:	6442                	ld	s0,16(sp)
    80003ea6:	6105                	addi	sp,sp,32
    80003ea8:	8082                	ret

0000000080003eaa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003eaa:	7179                	addi	sp,sp,-48
    80003eac:	f406                	sd	ra,40(sp)
    80003eae:	f022                	sd	s0,32(sp)
    80003eb0:	ec26                	sd	s1,24(sp)
    80003eb2:	e84a                	sd	s2,16(sp)
    80003eb4:	e44e                	sd	s3,8(sp)
    80003eb6:	e052                	sd	s4,0(sp)
    80003eb8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003eba:	00005597          	auipc	a1,0x5
    80003ebe:	68658593          	addi	a1,a1,1670 # 80009540 <syscalls+0x108>
    80003ec2:	00032517          	auipc	a0,0x32
    80003ec6:	c5650513          	addi	a0,a0,-938 # 80035b18 <bcache>
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	c68080e7          	jalr	-920(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003ed2:	0003a797          	auipc	a5,0x3a
    80003ed6:	c4678793          	addi	a5,a5,-954 # 8003db18 <bcache+0x8000>
    80003eda:	0003a717          	auipc	a4,0x3a
    80003ede:	ea670713          	addi	a4,a4,-346 # 8003dd80 <bcache+0x8268>
    80003ee2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003ee6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003eea:	00032497          	auipc	s1,0x32
    80003eee:	c4648493          	addi	s1,s1,-954 # 80035b30 <bcache+0x18>
    b->next = bcache.head.next;
    80003ef2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003ef4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003ef6:	00005a17          	auipc	s4,0x5
    80003efa:	652a0a13          	addi	s4,s4,1618 # 80009548 <syscalls+0x110>
    b->next = bcache.head.next;
    80003efe:	2b893783          	ld	a5,696(s2)
    80003f02:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003f04:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003f08:	85d2                	mv	a1,s4
    80003f0a:	01048513          	addi	a0,s1,16
    80003f0e:	00001097          	auipc	ra,0x1
    80003f12:	4c2080e7          	jalr	1218(ra) # 800053d0 <initsleeplock>
    bcache.head.next->prev = b;
    80003f16:	2b893783          	ld	a5,696(s2)
    80003f1a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003f1c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003f20:	45848493          	addi	s1,s1,1112
    80003f24:	fd349de3          	bne	s1,s3,80003efe <binit+0x54>
  }
}
    80003f28:	70a2                	ld	ra,40(sp)
    80003f2a:	7402                	ld	s0,32(sp)
    80003f2c:	64e2                	ld	s1,24(sp)
    80003f2e:	6942                	ld	s2,16(sp)
    80003f30:	69a2                	ld	s3,8(sp)
    80003f32:	6a02                	ld	s4,0(sp)
    80003f34:	6145                	addi	sp,sp,48
    80003f36:	8082                	ret

0000000080003f38 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003f38:	7179                	addi	sp,sp,-48
    80003f3a:	f406                	sd	ra,40(sp)
    80003f3c:	f022                	sd	s0,32(sp)
    80003f3e:	ec26                	sd	s1,24(sp)
    80003f40:	e84a                	sd	s2,16(sp)
    80003f42:	e44e                	sd	s3,8(sp)
    80003f44:	1800                	addi	s0,sp,48
    80003f46:	892a                	mv	s2,a0
    80003f48:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003f4a:	00032517          	auipc	a0,0x32
    80003f4e:	bce50513          	addi	a0,a0,-1074 # 80035b18 <bcache>
    80003f52:	ffffd097          	auipc	ra,0xffffd
    80003f56:	c70080e7          	jalr	-912(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003f5a:	0003a497          	auipc	s1,0x3a
    80003f5e:	e764b483          	ld	s1,-394(s1) # 8003ddd0 <bcache+0x82b8>
    80003f62:	0003a797          	auipc	a5,0x3a
    80003f66:	e1e78793          	addi	a5,a5,-482 # 8003dd80 <bcache+0x8268>
    80003f6a:	02f48f63          	beq	s1,a5,80003fa8 <bread+0x70>
    80003f6e:	873e                	mv	a4,a5
    80003f70:	a021                	j	80003f78 <bread+0x40>
    80003f72:	68a4                	ld	s1,80(s1)
    80003f74:	02e48a63          	beq	s1,a4,80003fa8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003f78:	449c                	lw	a5,8(s1)
    80003f7a:	ff279ce3          	bne	a5,s2,80003f72 <bread+0x3a>
    80003f7e:	44dc                	lw	a5,12(s1)
    80003f80:	ff3799e3          	bne	a5,s3,80003f72 <bread+0x3a>
      b->refcnt++;
    80003f84:	40bc                	lw	a5,64(s1)
    80003f86:	2785                	addiw	a5,a5,1
    80003f88:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003f8a:	00032517          	auipc	a0,0x32
    80003f8e:	b8e50513          	addi	a0,a0,-1138 # 80035b18 <bcache>
    80003f92:	ffffd097          	auipc	ra,0xffffd
    80003f96:	ce4080e7          	jalr	-796(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003f9a:	01048513          	addi	a0,s1,16
    80003f9e:	00001097          	auipc	ra,0x1
    80003fa2:	46c080e7          	jalr	1132(ra) # 8000540a <acquiresleep>
      return b;
    80003fa6:	a8b9                	j	80004004 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003fa8:	0003a497          	auipc	s1,0x3a
    80003fac:	e204b483          	ld	s1,-480(s1) # 8003ddc8 <bcache+0x82b0>
    80003fb0:	0003a797          	auipc	a5,0x3a
    80003fb4:	dd078793          	addi	a5,a5,-560 # 8003dd80 <bcache+0x8268>
    80003fb8:	00f48863          	beq	s1,a5,80003fc8 <bread+0x90>
    80003fbc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003fbe:	40bc                	lw	a5,64(s1)
    80003fc0:	cf81                	beqz	a5,80003fd8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003fc2:	64a4                	ld	s1,72(s1)
    80003fc4:	fee49de3          	bne	s1,a4,80003fbe <bread+0x86>
  panic("bget: no buffers");
    80003fc8:	00005517          	auipc	a0,0x5
    80003fcc:	58850513          	addi	a0,a0,1416 # 80009550 <syscalls+0x118>
    80003fd0:	ffffc097          	auipc	ra,0xffffc
    80003fd4:	55a080e7          	jalr	1370(ra) # 8000052a <panic>
      b->dev = dev;
    80003fd8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003fdc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003fe0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003fe4:	4785                	li	a5,1
    80003fe6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003fe8:	00032517          	auipc	a0,0x32
    80003fec:	b3050513          	addi	a0,a0,-1232 # 80035b18 <bcache>
    80003ff0:	ffffd097          	auipc	ra,0xffffd
    80003ff4:	c86080e7          	jalr	-890(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003ff8:	01048513          	addi	a0,s1,16
    80003ffc:	00001097          	auipc	ra,0x1
    80004000:	40e080e7          	jalr	1038(ra) # 8000540a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80004004:	409c                	lw	a5,0(s1)
    80004006:	cb89                	beqz	a5,80004018 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80004008:	8526                	mv	a0,s1
    8000400a:	70a2                	ld	ra,40(sp)
    8000400c:	7402                	ld	s0,32(sp)
    8000400e:	64e2                	ld	s1,24(sp)
    80004010:	6942                	ld	s2,16(sp)
    80004012:	69a2                	ld	s3,8(sp)
    80004014:	6145                	addi	sp,sp,48
    80004016:	8082                	ret
    virtio_disk_rw(b, 0);
    80004018:	4581                	li	a1,0
    8000401a:	8526                	mv	a0,s1
    8000401c:	00003097          	auipc	ra,0x3
    80004020:	fba080e7          	jalr	-70(ra) # 80006fd6 <virtio_disk_rw>
    b->valid = 1;
    80004024:	4785                	li	a5,1
    80004026:	c09c                	sw	a5,0(s1)
  return b;
    80004028:	b7c5                	j	80004008 <bread+0xd0>

000000008000402a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000402a:	1101                	addi	sp,sp,-32
    8000402c:	ec06                	sd	ra,24(sp)
    8000402e:	e822                	sd	s0,16(sp)
    80004030:	e426                	sd	s1,8(sp)
    80004032:	1000                	addi	s0,sp,32
    80004034:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004036:	0541                	addi	a0,a0,16
    80004038:	00001097          	auipc	ra,0x1
    8000403c:	46c080e7          	jalr	1132(ra) # 800054a4 <holdingsleep>
    80004040:	cd01                	beqz	a0,80004058 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80004042:	4585                	li	a1,1
    80004044:	8526                	mv	a0,s1
    80004046:	00003097          	auipc	ra,0x3
    8000404a:	f90080e7          	jalr	-112(ra) # 80006fd6 <virtio_disk_rw>
}
    8000404e:	60e2                	ld	ra,24(sp)
    80004050:	6442                	ld	s0,16(sp)
    80004052:	64a2                	ld	s1,8(sp)
    80004054:	6105                	addi	sp,sp,32
    80004056:	8082                	ret
    panic("bwrite");
    80004058:	00005517          	auipc	a0,0x5
    8000405c:	51050513          	addi	a0,a0,1296 # 80009568 <syscalls+0x130>
    80004060:	ffffc097          	auipc	ra,0xffffc
    80004064:	4ca080e7          	jalr	1226(ra) # 8000052a <panic>

0000000080004068 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80004068:	1101                	addi	sp,sp,-32
    8000406a:	ec06                	sd	ra,24(sp)
    8000406c:	e822                	sd	s0,16(sp)
    8000406e:	e426                	sd	s1,8(sp)
    80004070:	e04a                	sd	s2,0(sp)
    80004072:	1000                	addi	s0,sp,32
    80004074:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004076:	01050913          	addi	s2,a0,16
    8000407a:	854a                	mv	a0,s2
    8000407c:	00001097          	auipc	ra,0x1
    80004080:	428080e7          	jalr	1064(ra) # 800054a4 <holdingsleep>
    80004084:	c92d                	beqz	a0,800040f6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80004086:	854a                	mv	a0,s2
    80004088:	00001097          	auipc	ra,0x1
    8000408c:	3d8080e7          	jalr	984(ra) # 80005460 <releasesleep>

  acquire(&bcache.lock);
    80004090:	00032517          	auipc	a0,0x32
    80004094:	a8850513          	addi	a0,a0,-1400 # 80035b18 <bcache>
    80004098:	ffffd097          	auipc	ra,0xffffd
    8000409c:	b2a080e7          	jalr	-1238(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800040a0:	40bc                	lw	a5,64(s1)
    800040a2:	37fd                	addiw	a5,a5,-1
    800040a4:	0007871b          	sext.w	a4,a5
    800040a8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800040aa:	eb05                	bnez	a4,800040da <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800040ac:	68bc                	ld	a5,80(s1)
    800040ae:	64b8                	ld	a4,72(s1)
    800040b0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800040b2:	64bc                	ld	a5,72(s1)
    800040b4:	68b8                	ld	a4,80(s1)
    800040b6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800040b8:	0003a797          	auipc	a5,0x3a
    800040bc:	a6078793          	addi	a5,a5,-1440 # 8003db18 <bcache+0x8000>
    800040c0:	2b87b703          	ld	a4,696(a5)
    800040c4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800040c6:	0003a717          	auipc	a4,0x3a
    800040ca:	cba70713          	addi	a4,a4,-838 # 8003dd80 <bcache+0x8268>
    800040ce:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800040d0:	2b87b703          	ld	a4,696(a5)
    800040d4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800040d6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800040da:	00032517          	auipc	a0,0x32
    800040de:	a3e50513          	addi	a0,a0,-1474 # 80035b18 <bcache>
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	b94080e7          	jalr	-1132(ra) # 80000c76 <release>
}
    800040ea:	60e2                	ld	ra,24(sp)
    800040ec:	6442                	ld	s0,16(sp)
    800040ee:	64a2                	ld	s1,8(sp)
    800040f0:	6902                	ld	s2,0(sp)
    800040f2:	6105                	addi	sp,sp,32
    800040f4:	8082                	ret
    panic("brelse");
    800040f6:	00005517          	auipc	a0,0x5
    800040fa:	47a50513          	addi	a0,a0,1146 # 80009570 <syscalls+0x138>
    800040fe:	ffffc097          	auipc	ra,0xffffc
    80004102:	42c080e7          	jalr	1068(ra) # 8000052a <panic>

0000000080004106 <bpin>:

void
bpin(struct buf *b) {
    80004106:	1101                	addi	sp,sp,-32
    80004108:	ec06                	sd	ra,24(sp)
    8000410a:	e822                	sd	s0,16(sp)
    8000410c:	e426                	sd	s1,8(sp)
    8000410e:	1000                	addi	s0,sp,32
    80004110:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80004112:	00032517          	auipc	a0,0x32
    80004116:	a0650513          	addi	a0,a0,-1530 # 80035b18 <bcache>
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	aa8080e7          	jalr	-1368(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80004122:	40bc                	lw	a5,64(s1)
    80004124:	2785                	addiw	a5,a5,1
    80004126:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004128:	00032517          	auipc	a0,0x32
    8000412c:	9f050513          	addi	a0,a0,-1552 # 80035b18 <bcache>
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	b46080e7          	jalr	-1210(ra) # 80000c76 <release>
}
    80004138:	60e2                	ld	ra,24(sp)
    8000413a:	6442                	ld	s0,16(sp)
    8000413c:	64a2                	ld	s1,8(sp)
    8000413e:	6105                	addi	sp,sp,32
    80004140:	8082                	ret

0000000080004142 <bunpin>:

void
bunpin(struct buf *b) {
    80004142:	1101                	addi	sp,sp,-32
    80004144:	ec06                	sd	ra,24(sp)
    80004146:	e822                	sd	s0,16(sp)
    80004148:	e426                	sd	s1,8(sp)
    8000414a:	1000                	addi	s0,sp,32
    8000414c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000414e:	00032517          	auipc	a0,0x32
    80004152:	9ca50513          	addi	a0,a0,-1590 # 80035b18 <bcache>
    80004156:	ffffd097          	auipc	ra,0xffffd
    8000415a:	a6c080e7          	jalr	-1428(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000415e:	40bc                	lw	a5,64(s1)
    80004160:	37fd                	addiw	a5,a5,-1
    80004162:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004164:	00032517          	auipc	a0,0x32
    80004168:	9b450513          	addi	a0,a0,-1612 # 80035b18 <bcache>
    8000416c:	ffffd097          	auipc	ra,0xffffd
    80004170:	b0a080e7          	jalr	-1270(ra) # 80000c76 <release>
}
    80004174:	60e2                	ld	ra,24(sp)
    80004176:	6442                	ld	s0,16(sp)
    80004178:	64a2                	ld	s1,8(sp)
    8000417a:	6105                	addi	sp,sp,32
    8000417c:	8082                	ret

000000008000417e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000417e:	1101                	addi	sp,sp,-32
    80004180:	ec06                	sd	ra,24(sp)
    80004182:	e822                	sd	s0,16(sp)
    80004184:	e426                	sd	s1,8(sp)
    80004186:	e04a                	sd	s2,0(sp)
    80004188:	1000                	addi	s0,sp,32
    8000418a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000418c:	00d5d59b          	srliw	a1,a1,0xd
    80004190:	0003a797          	auipc	a5,0x3a
    80004194:	0647a783          	lw	a5,100(a5) # 8003e1f4 <sb+0x1c>
    80004198:	9dbd                	addw	a1,a1,a5
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	d9e080e7          	jalr	-610(ra) # 80003f38 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800041a2:	0074f713          	andi	a4,s1,7
    800041a6:	4785                	li	a5,1
    800041a8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800041ac:	14ce                	slli	s1,s1,0x33
    800041ae:	90d9                	srli	s1,s1,0x36
    800041b0:	00950733          	add	a4,a0,s1
    800041b4:	05874703          	lbu	a4,88(a4)
    800041b8:	00e7f6b3          	and	a3,a5,a4
    800041bc:	c69d                	beqz	a3,800041ea <bfree+0x6c>
    800041be:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800041c0:	94aa                	add	s1,s1,a0
    800041c2:	fff7c793          	not	a5,a5
    800041c6:	8ff9                	and	a5,a5,a4
    800041c8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800041cc:	00001097          	auipc	ra,0x1
    800041d0:	11e080e7          	jalr	286(ra) # 800052ea <log_write>
  brelse(bp);
    800041d4:	854a                	mv	a0,s2
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	e92080e7          	jalr	-366(ra) # 80004068 <brelse>
}
    800041de:	60e2                	ld	ra,24(sp)
    800041e0:	6442                	ld	s0,16(sp)
    800041e2:	64a2                	ld	s1,8(sp)
    800041e4:	6902                	ld	s2,0(sp)
    800041e6:	6105                	addi	sp,sp,32
    800041e8:	8082                	ret
    panic("freeing free block");
    800041ea:	00005517          	auipc	a0,0x5
    800041ee:	38e50513          	addi	a0,a0,910 # 80009578 <syscalls+0x140>
    800041f2:	ffffc097          	auipc	ra,0xffffc
    800041f6:	338080e7          	jalr	824(ra) # 8000052a <panic>

00000000800041fa <balloc>:
{
    800041fa:	711d                	addi	sp,sp,-96
    800041fc:	ec86                	sd	ra,88(sp)
    800041fe:	e8a2                	sd	s0,80(sp)
    80004200:	e4a6                	sd	s1,72(sp)
    80004202:	e0ca                	sd	s2,64(sp)
    80004204:	fc4e                	sd	s3,56(sp)
    80004206:	f852                	sd	s4,48(sp)
    80004208:	f456                	sd	s5,40(sp)
    8000420a:	f05a                	sd	s6,32(sp)
    8000420c:	ec5e                	sd	s7,24(sp)
    8000420e:	e862                	sd	s8,16(sp)
    80004210:	e466                	sd	s9,8(sp)
    80004212:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80004214:	0003a797          	auipc	a5,0x3a
    80004218:	fc87a783          	lw	a5,-56(a5) # 8003e1dc <sb+0x4>
    8000421c:	cbd1                	beqz	a5,800042b0 <balloc+0xb6>
    8000421e:	8baa                	mv	s7,a0
    80004220:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80004222:	0003ab17          	auipc	s6,0x3a
    80004226:	fb6b0b13          	addi	s6,s6,-74 # 8003e1d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000422a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000422c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000422e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80004230:	6c89                	lui	s9,0x2
    80004232:	a831                	j	8000424e <balloc+0x54>
    brelse(bp);
    80004234:	854a                	mv	a0,s2
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	e32080e7          	jalr	-462(ra) # 80004068 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000423e:	015c87bb          	addw	a5,s9,s5
    80004242:	00078a9b          	sext.w	s5,a5
    80004246:	004b2703          	lw	a4,4(s6)
    8000424a:	06eaf363          	bgeu	s5,a4,800042b0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000424e:	41fad79b          	sraiw	a5,s5,0x1f
    80004252:	0137d79b          	srliw	a5,a5,0x13
    80004256:	015787bb          	addw	a5,a5,s5
    8000425a:	40d7d79b          	sraiw	a5,a5,0xd
    8000425e:	01cb2583          	lw	a1,28(s6)
    80004262:	9dbd                	addw	a1,a1,a5
    80004264:	855e                	mv	a0,s7
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	cd2080e7          	jalr	-814(ra) # 80003f38 <bread>
    8000426e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004270:	004b2503          	lw	a0,4(s6)
    80004274:	000a849b          	sext.w	s1,s5
    80004278:	8662                	mv	a2,s8
    8000427a:	faa4fde3          	bgeu	s1,a0,80004234 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000427e:	41f6579b          	sraiw	a5,a2,0x1f
    80004282:	01d7d69b          	srliw	a3,a5,0x1d
    80004286:	00c6873b          	addw	a4,a3,a2
    8000428a:	00777793          	andi	a5,a4,7
    8000428e:	9f95                	subw	a5,a5,a3
    80004290:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004294:	4037571b          	sraiw	a4,a4,0x3
    80004298:	00e906b3          	add	a3,s2,a4
    8000429c:	0586c683          	lbu	a3,88(a3) # 2000058 <_entry-0x7dffffa8>
    800042a0:	00d7f5b3          	and	a1,a5,a3
    800042a4:	cd91                	beqz	a1,800042c0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800042a6:	2605                	addiw	a2,a2,1
    800042a8:	2485                	addiw	s1,s1,1
    800042aa:	fd4618e3          	bne	a2,s4,8000427a <balloc+0x80>
    800042ae:	b759                	j	80004234 <balloc+0x3a>
  panic("balloc: out of blocks");
    800042b0:	00005517          	auipc	a0,0x5
    800042b4:	2e050513          	addi	a0,a0,736 # 80009590 <syscalls+0x158>
    800042b8:	ffffc097          	auipc	ra,0xffffc
    800042bc:	272080e7          	jalr	626(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800042c0:	974a                	add	a4,a4,s2
    800042c2:	8fd5                	or	a5,a5,a3
    800042c4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800042c8:	854a                	mv	a0,s2
    800042ca:	00001097          	auipc	ra,0x1
    800042ce:	020080e7          	jalr	32(ra) # 800052ea <log_write>
        brelse(bp);
    800042d2:	854a                	mv	a0,s2
    800042d4:	00000097          	auipc	ra,0x0
    800042d8:	d94080e7          	jalr	-620(ra) # 80004068 <brelse>
  bp = bread(dev, bno);
    800042dc:	85a6                	mv	a1,s1
    800042de:	855e                	mv	a0,s7
    800042e0:	00000097          	auipc	ra,0x0
    800042e4:	c58080e7          	jalr	-936(ra) # 80003f38 <bread>
    800042e8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800042ea:	40000613          	li	a2,1024
    800042ee:	4581                	li	a1,0
    800042f0:	05850513          	addi	a0,a0,88
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	9ca080e7          	jalr	-1590(ra) # 80000cbe <memset>
  log_write(bp);
    800042fc:	854a                	mv	a0,s2
    800042fe:	00001097          	auipc	ra,0x1
    80004302:	fec080e7          	jalr	-20(ra) # 800052ea <log_write>
  brelse(bp);
    80004306:	854a                	mv	a0,s2
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	d60080e7          	jalr	-672(ra) # 80004068 <brelse>
}
    80004310:	8526                	mv	a0,s1
    80004312:	60e6                	ld	ra,88(sp)
    80004314:	6446                	ld	s0,80(sp)
    80004316:	64a6                	ld	s1,72(sp)
    80004318:	6906                	ld	s2,64(sp)
    8000431a:	79e2                	ld	s3,56(sp)
    8000431c:	7a42                	ld	s4,48(sp)
    8000431e:	7aa2                	ld	s5,40(sp)
    80004320:	7b02                	ld	s6,32(sp)
    80004322:	6be2                	ld	s7,24(sp)
    80004324:	6c42                	ld	s8,16(sp)
    80004326:	6ca2                	ld	s9,8(sp)
    80004328:	6125                	addi	sp,sp,96
    8000432a:	8082                	ret

000000008000432c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000432c:	7179                	addi	sp,sp,-48
    8000432e:	f406                	sd	ra,40(sp)
    80004330:	f022                	sd	s0,32(sp)
    80004332:	ec26                	sd	s1,24(sp)
    80004334:	e84a                	sd	s2,16(sp)
    80004336:	e44e                	sd	s3,8(sp)
    80004338:	e052                	sd	s4,0(sp)
    8000433a:	1800                	addi	s0,sp,48
    8000433c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000433e:	47ad                	li	a5,11
    80004340:	04b7fe63          	bgeu	a5,a1,8000439c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80004344:	ff45849b          	addiw	s1,a1,-12
    80004348:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000434c:	0ff00793          	li	a5,255
    80004350:	0ae7e463          	bltu	a5,a4,800043f8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80004354:	08052583          	lw	a1,128(a0)
    80004358:	c5b5                	beqz	a1,800043c4 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000435a:	00092503          	lw	a0,0(s2)
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	bda080e7          	jalr	-1062(ra) # 80003f38 <bread>
    80004366:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004368:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000436c:	02049713          	slli	a4,s1,0x20
    80004370:	01e75593          	srli	a1,a4,0x1e
    80004374:	00b784b3          	add	s1,a5,a1
    80004378:	0004a983          	lw	s3,0(s1)
    8000437c:	04098e63          	beqz	s3,800043d8 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80004380:	8552                	mv	a0,s4
    80004382:	00000097          	auipc	ra,0x0
    80004386:	ce6080e7          	jalr	-794(ra) # 80004068 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000438a:	854e                	mv	a0,s3
    8000438c:	70a2                	ld	ra,40(sp)
    8000438e:	7402                	ld	s0,32(sp)
    80004390:	64e2                	ld	s1,24(sp)
    80004392:	6942                	ld	s2,16(sp)
    80004394:	69a2                	ld	s3,8(sp)
    80004396:	6a02                	ld	s4,0(sp)
    80004398:	6145                	addi	sp,sp,48
    8000439a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000439c:	02059793          	slli	a5,a1,0x20
    800043a0:	01e7d593          	srli	a1,a5,0x1e
    800043a4:	00b504b3          	add	s1,a0,a1
    800043a8:	0504a983          	lw	s3,80(s1)
    800043ac:	fc099fe3          	bnez	s3,8000438a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800043b0:	4108                	lw	a0,0(a0)
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	e48080e7          	jalr	-440(ra) # 800041fa <balloc>
    800043ba:	0005099b          	sext.w	s3,a0
    800043be:	0534a823          	sw	s3,80(s1)
    800043c2:	b7e1                	j	8000438a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800043c4:	4108                	lw	a0,0(a0)
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	e34080e7          	jalr	-460(ra) # 800041fa <balloc>
    800043ce:	0005059b          	sext.w	a1,a0
    800043d2:	08b92023          	sw	a1,128(s2)
    800043d6:	b751                	j	8000435a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800043d8:	00092503          	lw	a0,0(s2)
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	e1e080e7          	jalr	-482(ra) # 800041fa <balloc>
    800043e4:	0005099b          	sext.w	s3,a0
    800043e8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800043ec:	8552                	mv	a0,s4
    800043ee:	00001097          	auipc	ra,0x1
    800043f2:	efc080e7          	jalr	-260(ra) # 800052ea <log_write>
    800043f6:	b769                	j	80004380 <bmap+0x54>
  panic("bmap: out of range");
    800043f8:	00005517          	auipc	a0,0x5
    800043fc:	1b050513          	addi	a0,a0,432 # 800095a8 <syscalls+0x170>
    80004400:	ffffc097          	auipc	ra,0xffffc
    80004404:	12a080e7          	jalr	298(ra) # 8000052a <panic>

0000000080004408 <iget>:
{
    80004408:	7179                	addi	sp,sp,-48
    8000440a:	f406                	sd	ra,40(sp)
    8000440c:	f022                	sd	s0,32(sp)
    8000440e:	ec26                	sd	s1,24(sp)
    80004410:	e84a                	sd	s2,16(sp)
    80004412:	e44e                	sd	s3,8(sp)
    80004414:	e052                	sd	s4,0(sp)
    80004416:	1800                	addi	s0,sp,48
    80004418:	89aa                	mv	s3,a0
    8000441a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000441c:	0003a517          	auipc	a0,0x3a
    80004420:	ddc50513          	addi	a0,a0,-548 # 8003e1f8 <itable>
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	79e080e7          	jalr	1950(ra) # 80000bc2 <acquire>
  empty = 0;
    8000442c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000442e:	0003a497          	auipc	s1,0x3a
    80004432:	de248493          	addi	s1,s1,-542 # 8003e210 <itable+0x18>
    80004436:	0003c697          	auipc	a3,0x3c
    8000443a:	86a68693          	addi	a3,a3,-1942 # 8003fca0 <log>
    8000443e:	a039                	j	8000444c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004440:	02090b63          	beqz	s2,80004476 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004444:	08848493          	addi	s1,s1,136
    80004448:	02d48a63          	beq	s1,a3,8000447c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000444c:	449c                	lw	a5,8(s1)
    8000444e:	fef059e3          	blez	a5,80004440 <iget+0x38>
    80004452:	4098                	lw	a4,0(s1)
    80004454:	ff3716e3          	bne	a4,s3,80004440 <iget+0x38>
    80004458:	40d8                	lw	a4,4(s1)
    8000445a:	ff4713e3          	bne	a4,s4,80004440 <iget+0x38>
      ip->ref++;
    8000445e:	2785                	addiw	a5,a5,1
    80004460:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004462:	0003a517          	auipc	a0,0x3a
    80004466:	d9650513          	addi	a0,a0,-618 # 8003e1f8 <itable>
    8000446a:	ffffd097          	auipc	ra,0xffffd
    8000446e:	80c080e7          	jalr	-2036(ra) # 80000c76 <release>
      return ip;
    80004472:	8926                	mv	s2,s1
    80004474:	a03d                	j	800044a2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004476:	f7f9                	bnez	a5,80004444 <iget+0x3c>
    80004478:	8926                	mv	s2,s1
    8000447a:	b7e9                	j	80004444 <iget+0x3c>
  if(empty == 0)
    8000447c:	02090c63          	beqz	s2,800044b4 <iget+0xac>
  ip->dev = dev;
    80004480:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004484:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004488:	4785                	li	a5,1
    8000448a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000448e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004492:	0003a517          	auipc	a0,0x3a
    80004496:	d6650513          	addi	a0,a0,-666 # 8003e1f8 <itable>
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	7dc080e7          	jalr	2012(ra) # 80000c76 <release>
}
    800044a2:	854a                	mv	a0,s2
    800044a4:	70a2                	ld	ra,40(sp)
    800044a6:	7402                	ld	s0,32(sp)
    800044a8:	64e2                	ld	s1,24(sp)
    800044aa:	6942                	ld	s2,16(sp)
    800044ac:	69a2                	ld	s3,8(sp)
    800044ae:	6a02                	ld	s4,0(sp)
    800044b0:	6145                	addi	sp,sp,48
    800044b2:	8082                	ret
    panic("iget: no inodes");
    800044b4:	00005517          	auipc	a0,0x5
    800044b8:	10c50513          	addi	a0,a0,268 # 800095c0 <syscalls+0x188>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	06e080e7          	jalr	110(ra) # 8000052a <panic>

00000000800044c4 <fsinit>:
fsinit(int dev) {
    800044c4:	7179                	addi	sp,sp,-48
    800044c6:	f406                	sd	ra,40(sp)
    800044c8:	f022                	sd	s0,32(sp)
    800044ca:	ec26                	sd	s1,24(sp)
    800044cc:	e84a                	sd	s2,16(sp)
    800044ce:	e44e                	sd	s3,8(sp)
    800044d0:	1800                	addi	s0,sp,48
    800044d2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800044d4:	4585                	li	a1,1
    800044d6:	00000097          	auipc	ra,0x0
    800044da:	a62080e7          	jalr	-1438(ra) # 80003f38 <bread>
    800044de:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800044e0:	0003a997          	auipc	s3,0x3a
    800044e4:	cf898993          	addi	s3,s3,-776 # 8003e1d8 <sb>
    800044e8:	02000613          	li	a2,32
    800044ec:	05850593          	addi	a1,a0,88
    800044f0:	854e                	mv	a0,s3
    800044f2:	ffffd097          	auipc	ra,0xffffd
    800044f6:	828080e7          	jalr	-2008(ra) # 80000d1a <memmove>
  brelse(bp);
    800044fa:	8526                	mv	a0,s1
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	b6c080e7          	jalr	-1172(ra) # 80004068 <brelse>
  if(sb.magic != FSMAGIC)
    80004504:	0009a703          	lw	a4,0(s3)
    80004508:	102037b7          	lui	a5,0x10203
    8000450c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004510:	02f71263          	bne	a4,a5,80004534 <fsinit+0x70>
  initlog(dev, &sb);
    80004514:	0003a597          	auipc	a1,0x3a
    80004518:	cc458593          	addi	a1,a1,-828 # 8003e1d8 <sb>
    8000451c:	854a                	mv	a0,s2
    8000451e:	00001097          	auipc	ra,0x1
    80004522:	b4e080e7          	jalr	-1202(ra) # 8000506c <initlog>
}
    80004526:	70a2                	ld	ra,40(sp)
    80004528:	7402                	ld	s0,32(sp)
    8000452a:	64e2                	ld	s1,24(sp)
    8000452c:	6942                	ld	s2,16(sp)
    8000452e:	69a2                	ld	s3,8(sp)
    80004530:	6145                	addi	sp,sp,48
    80004532:	8082                	ret
    panic("invalid file system");
    80004534:	00005517          	auipc	a0,0x5
    80004538:	09c50513          	addi	a0,a0,156 # 800095d0 <syscalls+0x198>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	fee080e7          	jalr	-18(ra) # 8000052a <panic>

0000000080004544 <iinit>:
{
    80004544:	7179                	addi	sp,sp,-48
    80004546:	f406                	sd	ra,40(sp)
    80004548:	f022                	sd	s0,32(sp)
    8000454a:	ec26                	sd	s1,24(sp)
    8000454c:	e84a                	sd	s2,16(sp)
    8000454e:	e44e                	sd	s3,8(sp)
    80004550:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004552:	00005597          	auipc	a1,0x5
    80004556:	09658593          	addi	a1,a1,150 # 800095e8 <syscalls+0x1b0>
    8000455a:	0003a517          	auipc	a0,0x3a
    8000455e:	c9e50513          	addi	a0,a0,-866 # 8003e1f8 <itable>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	5d0080e7          	jalr	1488(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000456a:	0003a497          	auipc	s1,0x3a
    8000456e:	cb648493          	addi	s1,s1,-842 # 8003e220 <itable+0x28>
    80004572:	0003b997          	auipc	s3,0x3b
    80004576:	73e98993          	addi	s3,s3,1854 # 8003fcb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000457a:	00005917          	auipc	s2,0x5
    8000457e:	07690913          	addi	s2,s2,118 # 800095f0 <syscalls+0x1b8>
    80004582:	85ca                	mv	a1,s2
    80004584:	8526                	mv	a0,s1
    80004586:	00001097          	auipc	ra,0x1
    8000458a:	e4a080e7          	jalr	-438(ra) # 800053d0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000458e:	08848493          	addi	s1,s1,136
    80004592:	ff3498e3          	bne	s1,s3,80004582 <iinit+0x3e>
}
    80004596:	70a2                	ld	ra,40(sp)
    80004598:	7402                	ld	s0,32(sp)
    8000459a:	64e2                	ld	s1,24(sp)
    8000459c:	6942                	ld	s2,16(sp)
    8000459e:	69a2                	ld	s3,8(sp)
    800045a0:	6145                	addi	sp,sp,48
    800045a2:	8082                	ret

00000000800045a4 <ialloc>:
{
    800045a4:	715d                	addi	sp,sp,-80
    800045a6:	e486                	sd	ra,72(sp)
    800045a8:	e0a2                	sd	s0,64(sp)
    800045aa:	fc26                	sd	s1,56(sp)
    800045ac:	f84a                	sd	s2,48(sp)
    800045ae:	f44e                	sd	s3,40(sp)
    800045b0:	f052                	sd	s4,32(sp)
    800045b2:	ec56                	sd	s5,24(sp)
    800045b4:	e85a                	sd	s6,16(sp)
    800045b6:	e45e                	sd	s7,8(sp)
    800045b8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800045ba:	0003a717          	auipc	a4,0x3a
    800045be:	c2a72703          	lw	a4,-982(a4) # 8003e1e4 <sb+0xc>
    800045c2:	4785                	li	a5,1
    800045c4:	04e7fa63          	bgeu	a5,a4,80004618 <ialloc+0x74>
    800045c8:	8aaa                	mv	s5,a0
    800045ca:	8bae                	mv	s7,a1
    800045cc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800045ce:	0003aa17          	auipc	s4,0x3a
    800045d2:	c0aa0a13          	addi	s4,s4,-1014 # 8003e1d8 <sb>
    800045d6:	00048b1b          	sext.w	s6,s1
    800045da:	0044d793          	srli	a5,s1,0x4
    800045de:	018a2583          	lw	a1,24(s4)
    800045e2:	9dbd                	addw	a1,a1,a5
    800045e4:	8556                	mv	a0,s5
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	952080e7          	jalr	-1710(ra) # 80003f38 <bread>
    800045ee:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800045f0:	05850993          	addi	s3,a0,88
    800045f4:	00f4f793          	andi	a5,s1,15
    800045f8:	079a                	slli	a5,a5,0x6
    800045fa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800045fc:	00099783          	lh	a5,0(s3)
    80004600:	c785                	beqz	a5,80004628 <ialloc+0x84>
    brelse(bp);
    80004602:	00000097          	auipc	ra,0x0
    80004606:	a66080e7          	jalr	-1434(ra) # 80004068 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000460a:	0485                	addi	s1,s1,1
    8000460c:	00ca2703          	lw	a4,12(s4)
    80004610:	0004879b          	sext.w	a5,s1
    80004614:	fce7e1e3          	bltu	a5,a4,800045d6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80004618:	00005517          	auipc	a0,0x5
    8000461c:	fe050513          	addi	a0,a0,-32 # 800095f8 <syscalls+0x1c0>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	f0a080e7          	jalr	-246(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80004628:	04000613          	li	a2,64
    8000462c:	4581                	li	a1,0
    8000462e:	854e                	mv	a0,s3
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	68e080e7          	jalr	1678(ra) # 80000cbe <memset>
      dip->type = type;
    80004638:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000463c:	854a                	mv	a0,s2
    8000463e:	00001097          	auipc	ra,0x1
    80004642:	cac080e7          	jalr	-852(ra) # 800052ea <log_write>
      brelse(bp);
    80004646:	854a                	mv	a0,s2
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	a20080e7          	jalr	-1504(ra) # 80004068 <brelse>
      return iget(dev, inum);
    80004650:	85da                	mv	a1,s6
    80004652:	8556                	mv	a0,s5
    80004654:	00000097          	auipc	ra,0x0
    80004658:	db4080e7          	jalr	-588(ra) # 80004408 <iget>
}
    8000465c:	60a6                	ld	ra,72(sp)
    8000465e:	6406                	ld	s0,64(sp)
    80004660:	74e2                	ld	s1,56(sp)
    80004662:	7942                	ld	s2,48(sp)
    80004664:	79a2                	ld	s3,40(sp)
    80004666:	7a02                	ld	s4,32(sp)
    80004668:	6ae2                	ld	s5,24(sp)
    8000466a:	6b42                	ld	s6,16(sp)
    8000466c:	6ba2                	ld	s7,8(sp)
    8000466e:	6161                	addi	sp,sp,80
    80004670:	8082                	ret

0000000080004672 <iupdate>:
{
    80004672:	1101                	addi	sp,sp,-32
    80004674:	ec06                	sd	ra,24(sp)
    80004676:	e822                	sd	s0,16(sp)
    80004678:	e426                	sd	s1,8(sp)
    8000467a:	e04a                	sd	s2,0(sp)
    8000467c:	1000                	addi	s0,sp,32
    8000467e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004680:	415c                	lw	a5,4(a0)
    80004682:	0047d79b          	srliw	a5,a5,0x4
    80004686:	0003a597          	auipc	a1,0x3a
    8000468a:	b6a5a583          	lw	a1,-1174(a1) # 8003e1f0 <sb+0x18>
    8000468e:	9dbd                	addw	a1,a1,a5
    80004690:	4108                	lw	a0,0(a0)
    80004692:	00000097          	auipc	ra,0x0
    80004696:	8a6080e7          	jalr	-1882(ra) # 80003f38 <bread>
    8000469a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000469c:	05850793          	addi	a5,a0,88
    800046a0:	40c8                	lw	a0,4(s1)
    800046a2:	893d                	andi	a0,a0,15
    800046a4:	051a                	slli	a0,a0,0x6
    800046a6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800046a8:	04449703          	lh	a4,68(s1)
    800046ac:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800046b0:	04649703          	lh	a4,70(s1)
    800046b4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800046b8:	04849703          	lh	a4,72(s1)
    800046bc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800046c0:	04a49703          	lh	a4,74(s1)
    800046c4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800046c8:	44f8                	lw	a4,76(s1)
    800046ca:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800046cc:	03400613          	li	a2,52
    800046d0:	05048593          	addi	a1,s1,80
    800046d4:	0531                	addi	a0,a0,12
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	644080e7          	jalr	1604(ra) # 80000d1a <memmove>
  log_write(bp);
    800046de:	854a                	mv	a0,s2
    800046e0:	00001097          	auipc	ra,0x1
    800046e4:	c0a080e7          	jalr	-1014(ra) # 800052ea <log_write>
  brelse(bp);
    800046e8:	854a                	mv	a0,s2
    800046ea:	00000097          	auipc	ra,0x0
    800046ee:	97e080e7          	jalr	-1666(ra) # 80004068 <brelse>
}
    800046f2:	60e2                	ld	ra,24(sp)
    800046f4:	6442                	ld	s0,16(sp)
    800046f6:	64a2                	ld	s1,8(sp)
    800046f8:	6902                	ld	s2,0(sp)
    800046fa:	6105                	addi	sp,sp,32
    800046fc:	8082                	ret

00000000800046fe <idup>:
{
    800046fe:	1101                	addi	sp,sp,-32
    80004700:	ec06                	sd	ra,24(sp)
    80004702:	e822                	sd	s0,16(sp)
    80004704:	e426                	sd	s1,8(sp)
    80004706:	1000                	addi	s0,sp,32
    80004708:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000470a:	0003a517          	auipc	a0,0x3a
    8000470e:	aee50513          	addi	a0,a0,-1298 # 8003e1f8 <itable>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	4b0080e7          	jalr	1200(ra) # 80000bc2 <acquire>
  ip->ref++;
    8000471a:	449c                	lw	a5,8(s1)
    8000471c:	2785                	addiw	a5,a5,1
    8000471e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004720:	0003a517          	auipc	a0,0x3a
    80004724:	ad850513          	addi	a0,a0,-1320 # 8003e1f8 <itable>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	54e080e7          	jalr	1358(ra) # 80000c76 <release>
}
    80004730:	8526                	mv	a0,s1
    80004732:	60e2                	ld	ra,24(sp)
    80004734:	6442                	ld	s0,16(sp)
    80004736:	64a2                	ld	s1,8(sp)
    80004738:	6105                	addi	sp,sp,32
    8000473a:	8082                	ret

000000008000473c <ilock>:
{
    8000473c:	1101                	addi	sp,sp,-32
    8000473e:	ec06                	sd	ra,24(sp)
    80004740:	e822                	sd	s0,16(sp)
    80004742:	e426                	sd	s1,8(sp)
    80004744:	e04a                	sd	s2,0(sp)
    80004746:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004748:	c115                	beqz	a0,8000476c <ilock+0x30>
    8000474a:	84aa                	mv	s1,a0
    8000474c:	451c                	lw	a5,8(a0)
    8000474e:	00f05f63          	blez	a5,8000476c <ilock+0x30>
  acquiresleep(&ip->lock);
    80004752:	0541                	addi	a0,a0,16
    80004754:	00001097          	auipc	ra,0x1
    80004758:	cb6080e7          	jalr	-842(ra) # 8000540a <acquiresleep>
  if(ip->valid == 0){
    8000475c:	40bc                	lw	a5,64(s1)
    8000475e:	cf99                	beqz	a5,8000477c <ilock+0x40>
}
    80004760:	60e2                	ld	ra,24(sp)
    80004762:	6442                	ld	s0,16(sp)
    80004764:	64a2                	ld	s1,8(sp)
    80004766:	6902                	ld	s2,0(sp)
    80004768:	6105                	addi	sp,sp,32
    8000476a:	8082                	ret
    panic("ilock");
    8000476c:	00005517          	auipc	a0,0x5
    80004770:	ea450513          	addi	a0,a0,-348 # 80009610 <syscalls+0x1d8>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	db6080e7          	jalr	-586(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000477c:	40dc                	lw	a5,4(s1)
    8000477e:	0047d79b          	srliw	a5,a5,0x4
    80004782:	0003a597          	auipc	a1,0x3a
    80004786:	a6e5a583          	lw	a1,-1426(a1) # 8003e1f0 <sb+0x18>
    8000478a:	9dbd                	addw	a1,a1,a5
    8000478c:	4088                	lw	a0,0(s1)
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	7aa080e7          	jalr	1962(ra) # 80003f38 <bread>
    80004796:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004798:	05850593          	addi	a1,a0,88
    8000479c:	40dc                	lw	a5,4(s1)
    8000479e:	8bbd                	andi	a5,a5,15
    800047a0:	079a                	slli	a5,a5,0x6
    800047a2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800047a4:	00059783          	lh	a5,0(a1)
    800047a8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800047ac:	00259783          	lh	a5,2(a1)
    800047b0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800047b4:	00459783          	lh	a5,4(a1)
    800047b8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800047bc:	00659783          	lh	a5,6(a1)
    800047c0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800047c4:	459c                	lw	a5,8(a1)
    800047c6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800047c8:	03400613          	li	a2,52
    800047cc:	05b1                	addi	a1,a1,12
    800047ce:	05048513          	addi	a0,s1,80
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	548080e7          	jalr	1352(ra) # 80000d1a <memmove>
    brelse(bp);
    800047da:	854a                	mv	a0,s2
    800047dc:	00000097          	auipc	ra,0x0
    800047e0:	88c080e7          	jalr	-1908(ra) # 80004068 <brelse>
    ip->valid = 1;
    800047e4:	4785                	li	a5,1
    800047e6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800047e8:	04449783          	lh	a5,68(s1)
    800047ec:	fbb5                	bnez	a5,80004760 <ilock+0x24>
      panic("ilock: no type");
    800047ee:	00005517          	auipc	a0,0x5
    800047f2:	e2a50513          	addi	a0,a0,-470 # 80009618 <syscalls+0x1e0>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	d34080e7          	jalr	-716(ra) # 8000052a <panic>

00000000800047fe <iunlock>:
{
    800047fe:	1101                	addi	sp,sp,-32
    80004800:	ec06                	sd	ra,24(sp)
    80004802:	e822                	sd	s0,16(sp)
    80004804:	e426                	sd	s1,8(sp)
    80004806:	e04a                	sd	s2,0(sp)
    80004808:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000480a:	c905                	beqz	a0,8000483a <iunlock+0x3c>
    8000480c:	84aa                	mv	s1,a0
    8000480e:	01050913          	addi	s2,a0,16
    80004812:	854a                	mv	a0,s2
    80004814:	00001097          	auipc	ra,0x1
    80004818:	c90080e7          	jalr	-880(ra) # 800054a4 <holdingsleep>
    8000481c:	cd19                	beqz	a0,8000483a <iunlock+0x3c>
    8000481e:	449c                	lw	a5,8(s1)
    80004820:	00f05d63          	blez	a5,8000483a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004824:	854a                	mv	a0,s2
    80004826:	00001097          	auipc	ra,0x1
    8000482a:	c3a080e7          	jalr	-966(ra) # 80005460 <releasesleep>
}
    8000482e:	60e2                	ld	ra,24(sp)
    80004830:	6442                	ld	s0,16(sp)
    80004832:	64a2                	ld	s1,8(sp)
    80004834:	6902                	ld	s2,0(sp)
    80004836:	6105                	addi	sp,sp,32
    80004838:	8082                	ret
    panic("iunlock");
    8000483a:	00005517          	auipc	a0,0x5
    8000483e:	dee50513          	addi	a0,a0,-530 # 80009628 <syscalls+0x1f0>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	ce8080e7          	jalr	-792(ra) # 8000052a <panic>

000000008000484a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000484a:	7179                	addi	sp,sp,-48
    8000484c:	f406                	sd	ra,40(sp)
    8000484e:	f022                	sd	s0,32(sp)
    80004850:	ec26                	sd	s1,24(sp)
    80004852:	e84a                	sd	s2,16(sp)
    80004854:	e44e                	sd	s3,8(sp)
    80004856:	e052                	sd	s4,0(sp)
    80004858:	1800                	addi	s0,sp,48
    8000485a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000485c:	05050493          	addi	s1,a0,80
    80004860:	08050913          	addi	s2,a0,128
    80004864:	a021                	j	8000486c <itrunc+0x22>
    80004866:	0491                	addi	s1,s1,4
    80004868:	01248d63          	beq	s1,s2,80004882 <itrunc+0x38>
    if(ip->addrs[i]){
    8000486c:	408c                	lw	a1,0(s1)
    8000486e:	dde5                	beqz	a1,80004866 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004870:	0009a503          	lw	a0,0(s3)
    80004874:	00000097          	auipc	ra,0x0
    80004878:	90a080e7          	jalr	-1782(ra) # 8000417e <bfree>
      ip->addrs[i] = 0;
    8000487c:	0004a023          	sw	zero,0(s1)
    80004880:	b7dd                	j	80004866 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004882:	0809a583          	lw	a1,128(s3)
    80004886:	e185                	bnez	a1,800048a6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004888:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000488c:	854e                	mv	a0,s3
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	de4080e7          	jalr	-540(ra) # 80004672 <iupdate>
}
    80004896:	70a2                	ld	ra,40(sp)
    80004898:	7402                	ld	s0,32(sp)
    8000489a:	64e2                	ld	s1,24(sp)
    8000489c:	6942                	ld	s2,16(sp)
    8000489e:	69a2                	ld	s3,8(sp)
    800048a0:	6a02                	ld	s4,0(sp)
    800048a2:	6145                	addi	sp,sp,48
    800048a4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800048a6:	0009a503          	lw	a0,0(s3)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	68e080e7          	jalr	1678(ra) # 80003f38 <bread>
    800048b2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800048b4:	05850493          	addi	s1,a0,88
    800048b8:	45850913          	addi	s2,a0,1112
    800048bc:	a021                	j	800048c4 <itrunc+0x7a>
    800048be:	0491                	addi	s1,s1,4
    800048c0:	01248b63          	beq	s1,s2,800048d6 <itrunc+0x8c>
      if(a[j])
    800048c4:	408c                	lw	a1,0(s1)
    800048c6:	dde5                	beqz	a1,800048be <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800048c8:	0009a503          	lw	a0,0(s3)
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	8b2080e7          	jalr	-1870(ra) # 8000417e <bfree>
    800048d4:	b7ed                	j	800048be <itrunc+0x74>
    brelse(bp);
    800048d6:	8552                	mv	a0,s4
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	790080e7          	jalr	1936(ra) # 80004068 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800048e0:	0809a583          	lw	a1,128(s3)
    800048e4:	0009a503          	lw	a0,0(s3)
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	896080e7          	jalr	-1898(ra) # 8000417e <bfree>
    ip->addrs[NDIRECT] = 0;
    800048f0:	0809a023          	sw	zero,128(s3)
    800048f4:	bf51                	j	80004888 <itrunc+0x3e>

00000000800048f6 <iput>:
{
    800048f6:	1101                	addi	sp,sp,-32
    800048f8:	ec06                	sd	ra,24(sp)
    800048fa:	e822                	sd	s0,16(sp)
    800048fc:	e426                	sd	s1,8(sp)
    800048fe:	e04a                	sd	s2,0(sp)
    80004900:	1000                	addi	s0,sp,32
    80004902:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004904:	0003a517          	auipc	a0,0x3a
    80004908:	8f450513          	addi	a0,a0,-1804 # 8003e1f8 <itable>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	2b6080e7          	jalr	694(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004914:	4498                	lw	a4,8(s1)
    80004916:	4785                	li	a5,1
    80004918:	02f70363          	beq	a4,a5,8000493e <iput+0x48>
  ip->ref--;
    8000491c:	449c                	lw	a5,8(s1)
    8000491e:	37fd                	addiw	a5,a5,-1
    80004920:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004922:	0003a517          	auipc	a0,0x3a
    80004926:	8d650513          	addi	a0,a0,-1834 # 8003e1f8 <itable>
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	34c080e7          	jalr	844(ra) # 80000c76 <release>
}
    80004932:	60e2                	ld	ra,24(sp)
    80004934:	6442                	ld	s0,16(sp)
    80004936:	64a2                	ld	s1,8(sp)
    80004938:	6902                	ld	s2,0(sp)
    8000493a:	6105                	addi	sp,sp,32
    8000493c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000493e:	40bc                	lw	a5,64(s1)
    80004940:	dff1                	beqz	a5,8000491c <iput+0x26>
    80004942:	04a49783          	lh	a5,74(s1)
    80004946:	fbf9                	bnez	a5,8000491c <iput+0x26>
    acquiresleep(&ip->lock);
    80004948:	01048913          	addi	s2,s1,16
    8000494c:	854a                	mv	a0,s2
    8000494e:	00001097          	auipc	ra,0x1
    80004952:	abc080e7          	jalr	-1348(ra) # 8000540a <acquiresleep>
    release(&itable.lock);
    80004956:	0003a517          	auipc	a0,0x3a
    8000495a:	8a250513          	addi	a0,a0,-1886 # 8003e1f8 <itable>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	318080e7          	jalr	792(ra) # 80000c76 <release>
    itrunc(ip);
    80004966:	8526                	mv	a0,s1
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	ee2080e7          	jalr	-286(ra) # 8000484a <itrunc>
    ip->type = 0;
    80004970:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004974:	8526                	mv	a0,s1
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	cfc080e7          	jalr	-772(ra) # 80004672 <iupdate>
    ip->valid = 0;
    8000497e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004982:	854a                	mv	a0,s2
    80004984:	00001097          	auipc	ra,0x1
    80004988:	adc080e7          	jalr	-1316(ra) # 80005460 <releasesleep>
    acquire(&itable.lock);
    8000498c:	0003a517          	auipc	a0,0x3a
    80004990:	86c50513          	addi	a0,a0,-1940 # 8003e1f8 <itable>
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	22e080e7          	jalr	558(ra) # 80000bc2 <acquire>
    8000499c:	b741                	j	8000491c <iput+0x26>

000000008000499e <iunlockput>:
{
    8000499e:	1101                	addi	sp,sp,-32
    800049a0:	ec06                	sd	ra,24(sp)
    800049a2:	e822                	sd	s0,16(sp)
    800049a4:	e426                	sd	s1,8(sp)
    800049a6:	1000                	addi	s0,sp,32
    800049a8:	84aa                	mv	s1,a0
  iunlock(ip);
    800049aa:	00000097          	auipc	ra,0x0
    800049ae:	e54080e7          	jalr	-428(ra) # 800047fe <iunlock>
  iput(ip);
    800049b2:	8526                	mv	a0,s1
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	f42080e7          	jalr	-190(ra) # 800048f6 <iput>
}
    800049bc:	60e2                	ld	ra,24(sp)
    800049be:	6442                	ld	s0,16(sp)
    800049c0:	64a2                	ld	s1,8(sp)
    800049c2:	6105                	addi	sp,sp,32
    800049c4:	8082                	ret

00000000800049c6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800049c6:	1141                	addi	sp,sp,-16
    800049c8:	e422                	sd	s0,8(sp)
    800049ca:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800049cc:	411c                	lw	a5,0(a0)
    800049ce:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800049d0:	415c                	lw	a5,4(a0)
    800049d2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800049d4:	04451783          	lh	a5,68(a0)
    800049d8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800049dc:	04a51783          	lh	a5,74(a0)
    800049e0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800049e4:	04c56783          	lwu	a5,76(a0)
    800049e8:	e99c                	sd	a5,16(a1)
}
    800049ea:	6422                	ld	s0,8(sp)
    800049ec:	0141                	addi	sp,sp,16
    800049ee:	8082                	ret

00000000800049f0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800049f0:	457c                	lw	a5,76(a0)
    800049f2:	0ed7e963          	bltu	a5,a3,80004ae4 <readi+0xf4>
{
    800049f6:	7159                	addi	sp,sp,-112
    800049f8:	f486                	sd	ra,104(sp)
    800049fa:	f0a2                	sd	s0,96(sp)
    800049fc:	eca6                	sd	s1,88(sp)
    800049fe:	e8ca                	sd	s2,80(sp)
    80004a00:	e4ce                	sd	s3,72(sp)
    80004a02:	e0d2                	sd	s4,64(sp)
    80004a04:	fc56                	sd	s5,56(sp)
    80004a06:	f85a                	sd	s6,48(sp)
    80004a08:	f45e                	sd	s7,40(sp)
    80004a0a:	f062                	sd	s8,32(sp)
    80004a0c:	ec66                	sd	s9,24(sp)
    80004a0e:	e86a                	sd	s10,16(sp)
    80004a10:	e46e                	sd	s11,8(sp)
    80004a12:	1880                	addi	s0,sp,112
    80004a14:	8baa                	mv	s7,a0
    80004a16:	8c2e                	mv	s8,a1
    80004a18:	8ab2                	mv	s5,a2
    80004a1a:	84b6                	mv	s1,a3
    80004a1c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004a1e:	9f35                	addw	a4,a4,a3
    return 0;
    80004a20:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004a22:	0ad76063          	bltu	a4,a3,80004ac2 <readi+0xd2>
  if(off + n > ip->size)
    80004a26:	00e7f463          	bgeu	a5,a4,80004a2e <readi+0x3e>
    n = ip->size - off;
    80004a2a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004a2e:	0a0b0963          	beqz	s6,80004ae0 <readi+0xf0>
    80004a32:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004a34:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004a38:	5cfd                	li	s9,-1
    80004a3a:	a82d                	j	80004a74 <readi+0x84>
    80004a3c:	020a1d93          	slli	s11,s4,0x20
    80004a40:	020ddd93          	srli	s11,s11,0x20
    80004a44:	05890793          	addi	a5,s2,88
    80004a48:	86ee                	mv	a3,s11
    80004a4a:	963e                	add	a2,a2,a5
    80004a4c:	85d6                	mv	a1,s5
    80004a4e:	8562                	mv	a0,s8
    80004a50:	ffffe097          	auipc	ra,0xffffe
    80004a54:	f68080e7          	jalr	-152(ra) # 800029b8 <either_copyout>
    80004a58:	05950d63          	beq	a0,s9,80004ab2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004a5c:	854a                	mv	a0,s2
    80004a5e:	fffff097          	auipc	ra,0xfffff
    80004a62:	60a080e7          	jalr	1546(ra) # 80004068 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004a66:	013a09bb          	addw	s3,s4,s3
    80004a6a:	009a04bb          	addw	s1,s4,s1
    80004a6e:	9aee                	add	s5,s5,s11
    80004a70:	0569f763          	bgeu	s3,s6,80004abe <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004a74:	000ba903          	lw	s2,0(s7)
    80004a78:	00a4d59b          	srliw	a1,s1,0xa
    80004a7c:	855e                	mv	a0,s7
    80004a7e:	00000097          	auipc	ra,0x0
    80004a82:	8ae080e7          	jalr	-1874(ra) # 8000432c <bmap>
    80004a86:	0005059b          	sext.w	a1,a0
    80004a8a:	854a                	mv	a0,s2
    80004a8c:	fffff097          	auipc	ra,0xfffff
    80004a90:	4ac080e7          	jalr	1196(ra) # 80003f38 <bread>
    80004a94:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004a96:	3ff4f613          	andi	a2,s1,1023
    80004a9a:	40cd07bb          	subw	a5,s10,a2
    80004a9e:	413b073b          	subw	a4,s6,s3
    80004aa2:	8a3e                	mv	s4,a5
    80004aa4:	2781                	sext.w	a5,a5
    80004aa6:	0007069b          	sext.w	a3,a4
    80004aaa:	f8f6f9e3          	bgeu	a3,a5,80004a3c <readi+0x4c>
    80004aae:	8a3a                	mv	s4,a4
    80004ab0:	b771                	j	80004a3c <readi+0x4c>
      brelse(bp);
    80004ab2:	854a                	mv	a0,s2
    80004ab4:	fffff097          	auipc	ra,0xfffff
    80004ab8:	5b4080e7          	jalr	1460(ra) # 80004068 <brelse>
      tot = -1;
    80004abc:	59fd                	li	s3,-1
  }
  return tot;
    80004abe:	0009851b          	sext.w	a0,s3
}
    80004ac2:	70a6                	ld	ra,104(sp)
    80004ac4:	7406                	ld	s0,96(sp)
    80004ac6:	64e6                	ld	s1,88(sp)
    80004ac8:	6946                	ld	s2,80(sp)
    80004aca:	69a6                	ld	s3,72(sp)
    80004acc:	6a06                	ld	s4,64(sp)
    80004ace:	7ae2                	ld	s5,56(sp)
    80004ad0:	7b42                	ld	s6,48(sp)
    80004ad2:	7ba2                	ld	s7,40(sp)
    80004ad4:	7c02                	ld	s8,32(sp)
    80004ad6:	6ce2                	ld	s9,24(sp)
    80004ad8:	6d42                	ld	s10,16(sp)
    80004ada:	6da2                	ld	s11,8(sp)
    80004adc:	6165                	addi	sp,sp,112
    80004ade:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004ae0:	89da                	mv	s3,s6
    80004ae2:	bff1                	j	80004abe <readi+0xce>
    return 0;
    80004ae4:	4501                	li	a0,0
}
    80004ae6:	8082                	ret

0000000080004ae8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004ae8:	457c                	lw	a5,76(a0)
    80004aea:	10d7e863          	bltu	a5,a3,80004bfa <writei+0x112>
{
    80004aee:	7159                	addi	sp,sp,-112
    80004af0:	f486                	sd	ra,104(sp)
    80004af2:	f0a2                	sd	s0,96(sp)
    80004af4:	eca6                	sd	s1,88(sp)
    80004af6:	e8ca                	sd	s2,80(sp)
    80004af8:	e4ce                	sd	s3,72(sp)
    80004afa:	e0d2                	sd	s4,64(sp)
    80004afc:	fc56                	sd	s5,56(sp)
    80004afe:	f85a                	sd	s6,48(sp)
    80004b00:	f45e                	sd	s7,40(sp)
    80004b02:	f062                	sd	s8,32(sp)
    80004b04:	ec66                	sd	s9,24(sp)
    80004b06:	e86a                	sd	s10,16(sp)
    80004b08:	e46e                	sd	s11,8(sp)
    80004b0a:	1880                	addi	s0,sp,112
    80004b0c:	8b2a                	mv	s6,a0
    80004b0e:	8c2e                	mv	s8,a1
    80004b10:	8ab2                	mv	s5,a2
    80004b12:	8936                	mv	s2,a3
    80004b14:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004b16:	00e687bb          	addw	a5,a3,a4
    80004b1a:	0ed7e263          	bltu	a5,a3,80004bfe <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004b1e:	00043737          	lui	a4,0x43
    80004b22:	0ef76063          	bltu	a4,a5,80004c02 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004b26:	0c0b8863          	beqz	s7,80004bf6 <writei+0x10e>
    80004b2a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004b2c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004b30:	5cfd                	li	s9,-1
    80004b32:	a091                	j	80004b76 <writei+0x8e>
    80004b34:	02099d93          	slli	s11,s3,0x20
    80004b38:	020ddd93          	srli	s11,s11,0x20
    80004b3c:	05848793          	addi	a5,s1,88
    80004b40:	86ee                	mv	a3,s11
    80004b42:	8656                	mv	a2,s5
    80004b44:	85e2                	mv	a1,s8
    80004b46:	953e                	add	a0,a0,a5
    80004b48:	ffffe097          	auipc	ra,0xffffe
    80004b4c:	ec8080e7          	jalr	-312(ra) # 80002a10 <either_copyin>
    80004b50:	07950263          	beq	a0,s9,80004bb4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004b54:	8526                	mv	a0,s1
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	794080e7          	jalr	1940(ra) # 800052ea <log_write>
    brelse(bp);
    80004b5e:	8526                	mv	a0,s1
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	508080e7          	jalr	1288(ra) # 80004068 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004b68:	01498a3b          	addw	s4,s3,s4
    80004b6c:	0129893b          	addw	s2,s3,s2
    80004b70:	9aee                	add	s5,s5,s11
    80004b72:	057a7663          	bgeu	s4,s7,80004bbe <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004b76:	000b2483          	lw	s1,0(s6)
    80004b7a:	00a9559b          	srliw	a1,s2,0xa
    80004b7e:	855a                	mv	a0,s6
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	7ac080e7          	jalr	1964(ra) # 8000432c <bmap>
    80004b88:	0005059b          	sext.w	a1,a0
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	3aa080e7          	jalr	938(ra) # 80003f38 <bread>
    80004b96:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004b98:	3ff97513          	andi	a0,s2,1023
    80004b9c:	40ad07bb          	subw	a5,s10,a0
    80004ba0:	414b873b          	subw	a4,s7,s4
    80004ba4:	89be                	mv	s3,a5
    80004ba6:	2781                	sext.w	a5,a5
    80004ba8:	0007069b          	sext.w	a3,a4
    80004bac:	f8f6f4e3          	bgeu	a3,a5,80004b34 <writei+0x4c>
    80004bb0:	89ba                	mv	s3,a4
    80004bb2:	b749                	j	80004b34 <writei+0x4c>
      brelse(bp);
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	fffff097          	auipc	ra,0xfffff
    80004bba:	4b2080e7          	jalr	1202(ra) # 80004068 <brelse>
  }

  if(off > ip->size)
    80004bbe:	04cb2783          	lw	a5,76(s6)
    80004bc2:	0127f463          	bgeu	a5,s2,80004bca <writei+0xe2>
    ip->size = off;
    80004bc6:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004bca:	855a                	mv	a0,s6
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	aa6080e7          	jalr	-1370(ra) # 80004672 <iupdate>

  return tot;
    80004bd4:	000a051b          	sext.w	a0,s4
}
    80004bd8:	70a6                	ld	ra,104(sp)
    80004bda:	7406                	ld	s0,96(sp)
    80004bdc:	64e6                	ld	s1,88(sp)
    80004bde:	6946                	ld	s2,80(sp)
    80004be0:	69a6                	ld	s3,72(sp)
    80004be2:	6a06                	ld	s4,64(sp)
    80004be4:	7ae2                	ld	s5,56(sp)
    80004be6:	7b42                	ld	s6,48(sp)
    80004be8:	7ba2                	ld	s7,40(sp)
    80004bea:	7c02                	ld	s8,32(sp)
    80004bec:	6ce2                	ld	s9,24(sp)
    80004bee:	6d42                	ld	s10,16(sp)
    80004bf0:	6da2                	ld	s11,8(sp)
    80004bf2:	6165                	addi	sp,sp,112
    80004bf4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004bf6:	8a5e                	mv	s4,s7
    80004bf8:	bfc9                	j	80004bca <writei+0xe2>
    return -1;
    80004bfa:	557d                	li	a0,-1
}
    80004bfc:	8082                	ret
    return -1;
    80004bfe:	557d                	li	a0,-1
    80004c00:	bfe1                	j	80004bd8 <writei+0xf0>
    return -1;
    80004c02:	557d                	li	a0,-1
    80004c04:	bfd1                	j	80004bd8 <writei+0xf0>

0000000080004c06 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004c06:	1141                	addi	sp,sp,-16
    80004c08:	e406                	sd	ra,8(sp)
    80004c0a:	e022                	sd	s0,0(sp)
    80004c0c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004c0e:	4639                	li	a2,14
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	186080e7          	jalr	390(ra) # 80000d96 <strncmp>
}
    80004c18:	60a2                	ld	ra,8(sp)
    80004c1a:	6402                	ld	s0,0(sp)
    80004c1c:	0141                	addi	sp,sp,16
    80004c1e:	8082                	ret

0000000080004c20 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004c20:	7139                	addi	sp,sp,-64
    80004c22:	fc06                	sd	ra,56(sp)
    80004c24:	f822                	sd	s0,48(sp)
    80004c26:	f426                	sd	s1,40(sp)
    80004c28:	f04a                	sd	s2,32(sp)
    80004c2a:	ec4e                	sd	s3,24(sp)
    80004c2c:	e852                	sd	s4,16(sp)
    80004c2e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004c30:	04451703          	lh	a4,68(a0)
    80004c34:	4785                	li	a5,1
    80004c36:	00f71a63          	bne	a4,a5,80004c4a <dirlookup+0x2a>
    80004c3a:	892a                	mv	s2,a0
    80004c3c:	89ae                	mv	s3,a1
    80004c3e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c40:	457c                	lw	a5,76(a0)
    80004c42:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004c44:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c46:	e79d                	bnez	a5,80004c74 <dirlookup+0x54>
    80004c48:	a8a5                	j	80004cc0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004c4a:	00005517          	auipc	a0,0x5
    80004c4e:	9e650513          	addi	a0,a0,-1562 # 80009630 <syscalls+0x1f8>
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	8d8080e7          	jalr	-1832(ra) # 8000052a <panic>
      panic("dirlookup read");
    80004c5a:	00005517          	auipc	a0,0x5
    80004c5e:	9ee50513          	addi	a0,a0,-1554 # 80009648 <syscalls+0x210>
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	8c8080e7          	jalr	-1848(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c6a:	24c1                	addiw	s1,s1,16
    80004c6c:	04c92783          	lw	a5,76(s2)
    80004c70:	04f4f763          	bgeu	s1,a5,80004cbe <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c74:	4741                	li	a4,16
    80004c76:	86a6                	mv	a3,s1
    80004c78:	fc040613          	addi	a2,s0,-64
    80004c7c:	4581                	li	a1,0
    80004c7e:	854a                	mv	a0,s2
    80004c80:	00000097          	auipc	ra,0x0
    80004c84:	d70080e7          	jalr	-656(ra) # 800049f0 <readi>
    80004c88:	47c1                	li	a5,16
    80004c8a:	fcf518e3          	bne	a0,a5,80004c5a <dirlookup+0x3a>
    if(de.inum == 0)
    80004c8e:	fc045783          	lhu	a5,-64(s0)
    80004c92:	dfe1                	beqz	a5,80004c6a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004c94:	fc240593          	addi	a1,s0,-62
    80004c98:	854e                	mv	a0,s3
    80004c9a:	00000097          	auipc	ra,0x0
    80004c9e:	f6c080e7          	jalr	-148(ra) # 80004c06 <namecmp>
    80004ca2:	f561                	bnez	a0,80004c6a <dirlookup+0x4a>
      if(poff)
    80004ca4:	000a0463          	beqz	s4,80004cac <dirlookup+0x8c>
        *poff = off;
    80004ca8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004cac:	fc045583          	lhu	a1,-64(s0)
    80004cb0:	00092503          	lw	a0,0(s2)
    80004cb4:	fffff097          	auipc	ra,0xfffff
    80004cb8:	754080e7          	jalr	1876(ra) # 80004408 <iget>
    80004cbc:	a011                	j	80004cc0 <dirlookup+0xa0>
  return 0;
    80004cbe:	4501                	li	a0,0
}
    80004cc0:	70e2                	ld	ra,56(sp)
    80004cc2:	7442                	ld	s0,48(sp)
    80004cc4:	74a2                	ld	s1,40(sp)
    80004cc6:	7902                	ld	s2,32(sp)
    80004cc8:	69e2                	ld	s3,24(sp)
    80004cca:	6a42                	ld	s4,16(sp)
    80004ccc:	6121                	addi	sp,sp,64
    80004cce:	8082                	ret

0000000080004cd0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004cd0:	711d                	addi	sp,sp,-96
    80004cd2:	ec86                	sd	ra,88(sp)
    80004cd4:	e8a2                	sd	s0,80(sp)
    80004cd6:	e4a6                	sd	s1,72(sp)
    80004cd8:	e0ca                	sd	s2,64(sp)
    80004cda:	fc4e                	sd	s3,56(sp)
    80004cdc:	f852                	sd	s4,48(sp)
    80004cde:	f456                	sd	s5,40(sp)
    80004ce0:	f05a                	sd	s6,32(sp)
    80004ce2:	ec5e                	sd	s7,24(sp)
    80004ce4:	e862                	sd	s8,16(sp)
    80004ce6:	e466                	sd	s9,8(sp)
    80004ce8:	1080                	addi	s0,sp,96
    80004cea:	84aa                	mv	s1,a0
    80004cec:	8aae                	mv	s5,a1
    80004cee:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004cf0:	00054703          	lbu	a4,0(a0)
    80004cf4:	02f00793          	li	a5,47
    80004cf8:	02f70363          	beq	a4,a5,80004d1e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	d5a080e7          	jalr	-678(ra) # 80001a56 <myproc>
    80004d04:	26053503          	ld	a0,608(a0)
    80004d08:	00000097          	auipc	ra,0x0
    80004d0c:	9f6080e7          	jalr	-1546(ra) # 800046fe <idup>
    80004d10:	89aa                	mv	s3,a0
  while(*path == '/')
    80004d12:	02f00913          	li	s2,47
  len = path - s;
    80004d16:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004d18:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004d1a:	4b85                	li	s7,1
    80004d1c:	a865                	j	80004dd4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004d1e:	4585                	li	a1,1
    80004d20:	4505                	li	a0,1
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	6e6080e7          	jalr	1766(ra) # 80004408 <iget>
    80004d2a:	89aa                	mv	s3,a0
    80004d2c:	b7dd                	j	80004d12 <namex+0x42>
      iunlockput(ip);
    80004d2e:	854e                	mv	a0,s3
    80004d30:	00000097          	auipc	ra,0x0
    80004d34:	c6e080e7          	jalr	-914(ra) # 8000499e <iunlockput>
      return 0;
    80004d38:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004d3a:	854e                	mv	a0,s3
    80004d3c:	60e6                	ld	ra,88(sp)
    80004d3e:	6446                	ld	s0,80(sp)
    80004d40:	64a6                	ld	s1,72(sp)
    80004d42:	6906                	ld	s2,64(sp)
    80004d44:	79e2                	ld	s3,56(sp)
    80004d46:	7a42                	ld	s4,48(sp)
    80004d48:	7aa2                	ld	s5,40(sp)
    80004d4a:	7b02                	ld	s6,32(sp)
    80004d4c:	6be2                	ld	s7,24(sp)
    80004d4e:	6c42                	ld	s8,16(sp)
    80004d50:	6ca2                	ld	s9,8(sp)
    80004d52:	6125                	addi	sp,sp,96
    80004d54:	8082                	ret
      iunlock(ip);
    80004d56:	854e                	mv	a0,s3
    80004d58:	00000097          	auipc	ra,0x0
    80004d5c:	aa6080e7          	jalr	-1370(ra) # 800047fe <iunlock>
      return ip;
    80004d60:	bfe9                	j	80004d3a <namex+0x6a>
      iunlockput(ip);
    80004d62:	854e                	mv	a0,s3
    80004d64:	00000097          	auipc	ra,0x0
    80004d68:	c3a080e7          	jalr	-966(ra) # 8000499e <iunlockput>
      return 0;
    80004d6c:	89e6                	mv	s3,s9
    80004d6e:	b7f1                	j	80004d3a <namex+0x6a>
  len = path - s;
    80004d70:	40b48633          	sub	a2,s1,a1
    80004d74:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004d78:	099c5463          	bge	s8,s9,80004e00 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004d7c:	4639                	li	a2,14
    80004d7e:	8552                	mv	a0,s4
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	f9a080e7          	jalr	-102(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004d88:	0004c783          	lbu	a5,0(s1)
    80004d8c:	01279763          	bne	a5,s2,80004d9a <namex+0xca>
    path++;
    80004d90:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004d92:	0004c783          	lbu	a5,0(s1)
    80004d96:	ff278de3          	beq	a5,s2,80004d90 <namex+0xc0>
    ilock(ip);
    80004d9a:	854e                	mv	a0,s3
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	9a0080e7          	jalr	-1632(ra) # 8000473c <ilock>
    if(ip->type != T_DIR){
    80004da4:	04499783          	lh	a5,68(s3)
    80004da8:	f97793e3          	bne	a5,s7,80004d2e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004dac:	000a8563          	beqz	s5,80004db6 <namex+0xe6>
    80004db0:	0004c783          	lbu	a5,0(s1)
    80004db4:	d3cd                	beqz	a5,80004d56 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004db6:	865a                	mv	a2,s6
    80004db8:	85d2                	mv	a1,s4
    80004dba:	854e                	mv	a0,s3
    80004dbc:	00000097          	auipc	ra,0x0
    80004dc0:	e64080e7          	jalr	-412(ra) # 80004c20 <dirlookup>
    80004dc4:	8caa                	mv	s9,a0
    80004dc6:	dd51                	beqz	a0,80004d62 <namex+0x92>
    iunlockput(ip);
    80004dc8:	854e                	mv	a0,s3
    80004dca:	00000097          	auipc	ra,0x0
    80004dce:	bd4080e7          	jalr	-1068(ra) # 8000499e <iunlockput>
    ip = next;
    80004dd2:	89e6                	mv	s3,s9
  while(*path == '/')
    80004dd4:	0004c783          	lbu	a5,0(s1)
    80004dd8:	05279763          	bne	a5,s2,80004e26 <namex+0x156>
    path++;
    80004ddc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004dde:	0004c783          	lbu	a5,0(s1)
    80004de2:	ff278de3          	beq	a5,s2,80004ddc <namex+0x10c>
  if(*path == 0)
    80004de6:	c79d                	beqz	a5,80004e14 <namex+0x144>
    path++;
    80004de8:	85a6                	mv	a1,s1
  len = path - s;
    80004dea:	8cda                	mv	s9,s6
    80004dec:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004dee:	01278963          	beq	a5,s2,80004e00 <namex+0x130>
    80004df2:	dfbd                	beqz	a5,80004d70 <namex+0xa0>
    path++;
    80004df4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004df6:	0004c783          	lbu	a5,0(s1)
    80004dfa:	ff279ce3          	bne	a5,s2,80004df2 <namex+0x122>
    80004dfe:	bf8d                	j	80004d70 <namex+0xa0>
    memmove(name, s, len);
    80004e00:	2601                	sext.w	a2,a2
    80004e02:	8552                	mv	a0,s4
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	f16080e7          	jalr	-234(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004e0c:	9cd2                	add	s9,s9,s4
    80004e0e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004e12:	bf9d                	j	80004d88 <namex+0xb8>
  if(nameiparent){
    80004e14:	f20a83e3          	beqz	s5,80004d3a <namex+0x6a>
    iput(ip);
    80004e18:	854e                	mv	a0,s3
    80004e1a:	00000097          	auipc	ra,0x0
    80004e1e:	adc080e7          	jalr	-1316(ra) # 800048f6 <iput>
    return 0;
    80004e22:	4981                	li	s3,0
    80004e24:	bf19                	j	80004d3a <namex+0x6a>
  if(*path == 0)
    80004e26:	d7fd                	beqz	a5,80004e14 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004e28:	0004c783          	lbu	a5,0(s1)
    80004e2c:	85a6                	mv	a1,s1
    80004e2e:	b7d1                	j	80004df2 <namex+0x122>

0000000080004e30 <dirlink>:
{
    80004e30:	7139                	addi	sp,sp,-64
    80004e32:	fc06                	sd	ra,56(sp)
    80004e34:	f822                	sd	s0,48(sp)
    80004e36:	f426                	sd	s1,40(sp)
    80004e38:	f04a                	sd	s2,32(sp)
    80004e3a:	ec4e                	sd	s3,24(sp)
    80004e3c:	e852                	sd	s4,16(sp)
    80004e3e:	0080                	addi	s0,sp,64
    80004e40:	892a                	mv	s2,a0
    80004e42:	8a2e                	mv	s4,a1
    80004e44:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004e46:	4601                	li	a2,0
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	dd8080e7          	jalr	-552(ra) # 80004c20 <dirlookup>
    80004e50:	e93d                	bnez	a0,80004ec6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004e52:	04c92483          	lw	s1,76(s2)
    80004e56:	c49d                	beqz	s1,80004e84 <dirlink+0x54>
    80004e58:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004e5a:	4741                	li	a4,16
    80004e5c:	86a6                	mv	a3,s1
    80004e5e:	fc040613          	addi	a2,s0,-64
    80004e62:	4581                	li	a1,0
    80004e64:	854a                	mv	a0,s2
    80004e66:	00000097          	auipc	ra,0x0
    80004e6a:	b8a080e7          	jalr	-1142(ra) # 800049f0 <readi>
    80004e6e:	47c1                	li	a5,16
    80004e70:	06f51163          	bne	a0,a5,80004ed2 <dirlink+0xa2>
    if(de.inum == 0)
    80004e74:	fc045783          	lhu	a5,-64(s0)
    80004e78:	c791                	beqz	a5,80004e84 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004e7a:	24c1                	addiw	s1,s1,16
    80004e7c:	04c92783          	lw	a5,76(s2)
    80004e80:	fcf4ede3          	bltu	s1,a5,80004e5a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004e84:	4639                	li	a2,14
    80004e86:	85d2                	mv	a1,s4
    80004e88:	fc240513          	addi	a0,s0,-62
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	f46080e7          	jalr	-186(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004e94:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004e98:	4741                	li	a4,16
    80004e9a:	86a6                	mv	a3,s1
    80004e9c:	fc040613          	addi	a2,s0,-64
    80004ea0:	4581                	li	a1,0
    80004ea2:	854a                	mv	a0,s2
    80004ea4:	00000097          	auipc	ra,0x0
    80004ea8:	c44080e7          	jalr	-956(ra) # 80004ae8 <writei>
    80004eac:	872a                	mv	a4,a0
    80004eae:	47c1                	li	a5,16
  return 0;
    80004eb0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004eb2:	02f71863          	bne	a4,a5,80004ee2 <dirlink+0xb2>
}
    80004eb6:	70e2                	ld	ra,56(sp)
    80004eb8:	7442                	ld	s0,48(sp)
    80004eba:	74a2                	ld	s1,40(sp)
    80004ebc:	7902                	ld	s2,32(sp)
    80004ebe:	69e2                	ld	s3,24(sp)
    80004ec0:	6a42                	ld	s4,16(sp)
    80004ec2:	6121                	addi	sp,sp,64
    80004ec4:	8082                	ret
    iput(ip);
    80004ec6:	00000097          	auipc	ra,0x0
    80004eca:	a30080e7          	jalr	-1488(ra) # 800048f6 <iput>
    return -1;
    80004ece:	557d                	li	a0,-1
    80004ed0:	b7dd                	j	80004eb6 <dirlink+0x86>
      panic("dirlink read");
    80004ed2:	00004517          	auipc	a0,0x4
    80004ed6:	78650513          	addi	a0,a0,1926 # 80009658 <syscalls+0x220>
    80004eda:	ffffb097          	auipc	ra,0xffffb
    80004ede:	650080e7          	jalr	1616(ra) # 8000052a <panic>
    panic("dirlink");
    80004ee2:	00005517          	auipc	a0,0x5
    80004ee6:	88650513          	addi	a0,a0,-1914 # 80009768 <syscalls+0x330>
    80004eea:	ffffb097          	auipc	ra,0xffffb
    80004eee:	640080e7          	jalr	1600(ra) # 8000052a <panic>

0000000080004ef2 <namei>:

struct inode*
namei(char *path)
{
    80004ef2:	1101                	addi	sp,sp,-32
    80004ef4:	ec06                	sd	ra,24(sp)
    80004ef6:	e822                	sd	s0,16(sp)
    80004ef8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004efa:	fe040613          	addi	a2,s0,-32
    80004efe:	4581                	li	a1,0
    80004f00:	00000097          	auipc	ra,0x0
    80004f04:	dd0080e7          	jalr	-560(ra) # 80004cd0 <namex>
}
    80004f08:	60e2                	ld	ra,24(sp)
    80004f0a:	6442                	ld	s0,16(sp)
    80004f0c:	6105                	addi	sp,sp,32
    80004f0e:	8082                	ret

0000000080004f10 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004f10:	1141                	addi	sp,sp,-16
    80004f12:	e406                	sd	ra,8(sp)
    80004f14:	e022                	sd	s0,0(sp)
    80004f16:	0800                	addi	s0,sp,16
    80004f18:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004f1a:	4585                	li	a1,1
    80004f1c:	00000097          	auipc	ra,0x0
    80004f20:	db4080e7          	jalr	-588(ra) # 80004cd0 <namex>
}
    80004f24:	60a2                	ld	ra,8(sp)
    80004f26:	6402                	ld	s0,0(sp)
    80004f28:	0141                	addi	sp,sp,16
    80004f2a:	8082                	ret

0000000080004f2c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004f2c:	1101                	addi	sp,sp,-32
    80004f2e:	ec06                	sd	ra,24(sp)
    80004f30:	e822                	sd	s0,16(sp)
    80004f32:	e426                	sd	s1,8(sp)
    80004f34:	e04a                	sd	s2,0(sp)
    80004f36:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004f38:	0003b917          	auipc	s2,0x3b
    80004f3c:	d6890913          	addi	s2,s2,-664 # 8003fca0 <log>
    80004f40:	01892583          	lw	a1,24(s2)
    80004f44:	02892503          	lw	a0,40(s2)
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	ff0080e7          	jalr	-16(ra) # 80003f38 <bread>
    80004f50:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004f52:	02c92683          	lw	a3,44(s2)
    80004f56:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004f58:	02d05863          	blez	a3,80004f88 <write_head+0x5c>
    80004f5c:	0003b797          	auipc	a5,0x3b
    80004f60:	d7478793          	addi	a5,a5,-652 # 8003fcd0 <log+0x30>
    80004f64:	05c50713          	addi	a4,a0,92
    80004f68:	36fd                	addiw	a3,a3,-1
    80004f6a:	02069613          	slli	a2,a3,0x20
    80004f6e:	01e65693          	srli	a3,a2,0x1e
    80004f72:	0003b617          	auipc	a2,0x3b
    80004f76:	d6260613          	addi	a2,a2,-670 # 8003fcd4 <log+0x34>
    80004f7a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004f7c:	4390                	lw	a2,0(a5)
    80004f7e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004f80:	0791                	addi	a5,a5,4
    80004f82:	0711                	addi	a4,a4,4
    80004f84:	fed79ce3          	bne	a5,a3,80004f7c <write_head+0x50>
  }
  bwrite(buf);
    80004f88:	8526                	mv	a0,s1
    80004f8a:	fffff097          	auipc	ra,0xfffff
    80004f8e:	0a0080e7          	jalr	160(ra) # 8000402a <bwrite>
  brelse(buf);
    80004f92:	8526                	mv	a0,s1
    80004f94:	fffff097          	auipc	ra,0xfffff
    80004f98:	0d4080e7          	jalr	212(ra) # 80004068 <brelse>
}
    80004f9c:	60e2                	ld	ra,24(sp)
    80004f9e:	6442                	ld	s0,16(sp)
    80004fa0:	64a2                	ld	s1,8(sp)
    80004fa2:	6902                	ld	s2,0(sp)
    80004fa4:	6105                	addi	sp,sp,32
    80004fa6:	8082                	ret

0000000080004fa8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004fa8:	0003b797          	auipc	a5,0x3b
    80004fac:	d247a783          	lw	a5,-732(a5) # 8003fccc <log+0x2c>
    80004fb0:	0af05d63          	blez	a5,8000506a <install_trans+0xc2>
{
    80004fb4:	7139                	addi	sp,sp,-64
    80004fb6:	fc06                	sd	ra,56(sp)
    80004fb8:	f822                	sd	s0,48(sp)
    80004fba:	f426                	sd	s1,40(sp)
    80004fbc:	f04a                	sd	s2,32(sp)
    80004fbe:	ec4e                	sd	s3,24(sp)
    80004fc0:	e852                	sd	s4,16(sp)
    80004fc2:	e456                	sd	s5,8(sp)
    80004fc4:	e05a                	sd	s6,0(sp)
    80004fc6:	0080                	addi	s0,sp,64
    80004fc8:	8b2a                	mv	s6,a0
    80004fca:	0003ba97          	auipc	s5,0x3b
    80004fce:	d06a8a93          	addi	s5,s5,-762 # 8003fcd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004fd2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004fd4:	0003b997          	auipc	s3,0x3b
    80004fd8:	ccc98993          	addi	s3,s3,-820 # 8003fca0 <log>
    80004fdc:	a00d                	j	80004ffe <install_trans+0x56>
    brelse(lbuf);
    80004fde:	854a                	mv	a0,s2
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	088080e7          	jalr	136(ra) # 80004068 <brelse>
    brelse(dbuf);
    80004fe8:	8526                	mv	a0,s1
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	07e080e7          	jalr	126(ra) # 80004068 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ff2:	2a05                	addiw	s4,s4,1
    80004ff4:	0a91                	addi	s5,s5,4
    80004ff6:	02c9a783          	lw	a5,44(s3)
    80004ffa:	04fa5e63          	bge	s4,a5,80005056 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004ffe:	0189a583          	lw	a1,24(s3)
    80005002:	014585bb          	addw	a1,a1,s4
    80005006:	2585                	addiw	a1,a1,1
    80005008:	0289a503          	lw	a0,40(s3)
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	f2c080e7          	jalr	-212(ra) # 80003f38 <bread>
    80005014:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80005016:	000aa583          	lw	a1,0(s5)
    8000501a:	0289a503          	lw	a0,40(s3)
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	f1a080e7          	jalr	-230(ra) # 80003f38 <bread>
    80005026:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80005028:	40000613          	li	a2,1024
    8000502c:	05890593          	addi	a1,s2,88
    80005030:	05850513          	addi	a0,a0,88
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	ce6080e7          	jalr	-794(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000503c:	8526                	mv	a0,s1
    8000503e:	fffff097          	auipc	ra,0xfffff
    80005042:	fec080e7          	jalr	-20(ra) # 8000402a <bwrite>
    if(recovering == 0)
    80005046:	f80b1ce3          	bnez	s6,80004fde <install_trans+0x36>
      bunpin(dbuf);
    8000504a:	8526                	mv	a0,s1
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	0f6080e7          	jalr	246(ra) # 80004142 <bunpin>
    80005054:	b769                	j	80004fde <install_trans+0x36>
}
    80005056:	70e2                	ld	ra,56(sp)
    80005058:	7442                	ld	s0,48(sp)
    8000505a:	74a2                	ld	s1,40(sp)
    8000505c:	7902                	ld	s2,32(sp)
    8000505e:	69e2                	ld	s3,24(sp)
    80005060:	6a42                	ld	s4,16(sp)
    80005062:	6aa2                	ld	s5,8(sp)
    80005064:	6b02                	ld	s6,0(sp)
    80005066:	6121                	addi	sp,sp,64
    80005068:	8082                	ret
    8000506a:	8082                	ret

000000008000506c <initlog>:
{
    8000506c:	7179                	addi	sp,sp,-48
    8000506e:	f406                	sd	ra,40(sp)
    80005070:	f022                	sd	s0,32(sp)
    80005072:	ec26                	sd	s1,24(sp)
    80005074:	e84a                	sd	s2,16(sp)
    80005076:	e44e                	sd	s3,8(sp)
    80005078:	1800                	addi	s0,sp,48
    8000507a:	892a                	mv	s2,a0
    8000507c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000507e:	0003b497          	auipc	s1,0x3b
    80005082:	c2248493          	addi	s1,s1,-990 # 8003fca0 <log>
    80005086:	00004597          	auipc	a1,0x4
    8000508a:	5e258593          	addi	a1,a1,1506 # 80009668 <syscalls+0x230>
    8000508e:	8526                	mv	a0,s1
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	aa2080e7          	jalr	-1374(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80005098:	0149a583          	lw	a1,20(s3)
    8000509c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000509e:	0109a783          	lw	a5,16(s3)
    800050a2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800050a4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800050a8:	854a                	mv	a0,s2
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	e8e080e7          	jalr	-370(ra) # 80003f38 <bread>
  log.lh.n = lh->n;
    800050b2:	4d34                	lw	a3,88(a0)
    800050b4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800050b6:	02d05663          	blez	a3,800050e2 <initlog+0x76>
    800050ba:	05c50793          	addi	a5,a0,92
    800050be:	0003b717          	auipc	a4,0x3b
    800050c2:	c1270713          	addi	a4,a4,-1006 # 8003fcd0 <log+0x30>
    800050c6:	36fd                	addiw	a3,a3,-1
    800050c8:	02069613          	slli	a2,a3,0x20
    800050cc:	01e65693          	srli	a3,a2,0x1e
    800050d0:	06050613          	addi	a2,a0,96
    800050d4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800050d6:	4390                	lw	a2,0(a5)
    800050d8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800050da:	0791                	addi	a5,a5,4
    800050dc:	0711                	addi	a4,a4,4
    800050de:	fed79ce3          	bne	a5,a3,800050d6 <initlog+0x6a>
  brelse(buf);
    800050e2:	fffff097          	auipc	ra,0xfffff
    800050e6:	f86080e7          	jalr	-122(ra) # 80004068 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800050ea:	4505                	li	a0,1
    800050ec:	00000097          	auipc	ra,0x0
    800050f0:	ebc080e7          	jalr	-324(ra) # 80004fa8 <install_trans>
  log.lh.n = 0;
    800050f4:	0003b797          	auipc	a5,0x3b
    800050f8:	bc07ac23          	sw	zero,-1064(a5) # 8003fccc <log+0x2c>
  write_head(); // clear the log
    800050fc:	00000097          	auipc	ra,0x0
    80005100:	e30080e7          	jalr	-464(ra) # 80004f2c <write_head>
}
    80005104:	70a2                	ld	ra,40(sp)
    80005106:	7402                	ld	s0,32(sp)
    80005108:	64e2                	ld	s1,24(sp)
    8000510a:	6942                	ld	s2,16(sp)
    8000510c:	69a2                	ld	s3,8(sp)
    8000510e:	6145                	addi	sp,sp,48
    80005110:	8082                	ret

0000000080005112 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80005112:	1101                	addi	sp,sp,-32
    80005114:	ec06                	sd	ra,24(sp)
    80005116:	e822                	sd	s0,16(sp)
    80005118:	e426                	sd	s1,8(sp)
    8000511a:	e04a                	sd	s2,0(sp)
    8000511c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000511e:	0003b517          	auipc	a0,0x3b
    80005122:	b8250513          	addi	a0,a0,-1150 # 8003fca0 <log>
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	a9c080e7          	jalr	-1380(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    8000512e:	0003b497          	auipc	s1,0x3b
    80005132:	b7248493          	addi	s1,s1,-1166 # 8003fca0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005136:	4979                	li	s2,30
    80005138:	a039                	j	80005146 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000513a:	85a6                	mv	a1,s1
    8000513c:	8526                	mv	a0,s1
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	576080e7          	jalr	1398(ra) # 800026b4 <sleep>
    if(log.committing){
    80005146:	50dc                	lw	a5,36(s1)
    80005148:	fbed                	bnez	a5,8000513a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000514a:	509c                	lw	a5,32(s1)
    8000514c:	0017871b          	addiw	a4,a5,1
    80005150:	0007069b          	sext.w	a3,a4
    80005154:	0027179b          	slliw	a5,a4,0x2
    80005158:	9fb9                	addw	a5,a5,a4
    8000515a:	0017979b          	slliw	a5,a5,0x1
    8000515e:	54d8                	lw	a4,44(s1)
    80005160:	9fb9                	addw	a5,a5,a4
    80005162:	00f95963          	bge	s2,a5,80005174 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80005166:	85a6                	mv	a1,s1
    80005168:	8526                	mv	a0,s1
    8000516a:	ffffd097          	auipc	ra,0xffffd
    8000516e:	54a080e7          	jalr	1354(ra) # 800026b4 <sleep>
    80005172:	bfd1                	j	80005146 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80005174:	0003b517          	auipc	a0,0x3b
    80005178:	b2c50513          	addi	a0,a0,-1236 # 8003fca0 <log>
    8000517c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000517e:	ffffc097          	auipc	ra,0xffffc
    80005182:	af8080e7          	jalr	-1288(ra) # 80000c76 <release>
      break;
    }
  }
}
    80005186:	60e2                	ld	ra,24(sp)
    80005188:	6442                	ld	s0,16(sp)
    8000518a:	64a2                	ld	s1,8(sp)
    8000518c:	6902                	ld	s2,0(sp)
    8000518e:	6105                	addi	sp,sp,32
    80005190:	8082                	ret

0000000080005192 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005192:	7139                	addi	sp,sp,-64
    80005194:	fc06                	sd	ra,56(sp)
    80005196:	f822                	sd	s0,48(sp)
    80005198:	f426                	sd	s1,40(sp)
    8000519a:	f04a                	sd	s2,32(sp)
    8000519c:	ec4e                	sd	s3,24(sp)
    8000519e:	e852                	sd	s4,16(sp)
    800051a0:	e456                	sd	s5,8(sp)
    800051a2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800051a4:	0003b497          	auipc	s1,0x3b
    800051a8:	afc48493          	addi	s1,s1,-1284 # 8003fca0 <log>
    800051ac:	8526                	mv	a0,s1
    800051ae:	ffffc097          	auipc	ra,0xffffc
    800051b2:	a14080e7          	jalr	-1516(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800051b6:	509c                	lw	a5,32(s1)
    800051b8:	37fd                	addiw	a5,a5,-1
    800051ba:	0007891b          	sext.w	s2,a5
    800051be:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800051c0:	50dc                	lw	a5,36(s1)
    800051c2:	e7b9                	bnez	a5,80005210 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800051c4:	04091e63          	bnez	s2,80005220 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800051c8:	0003b497          	auipc	s1,0x3b
    800051cc:	ad848493          	addi	s1,s1,-1320 # 8003fca0 <log>
    800051d0:	4785                	li	a5,1
    800051d2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800051d4:	8526                	mv	a0,s1
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	aa0080e7          	jalr	-1376(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800051de:	54dc                	lw	a5,44(s1)
    800051e0:	06f04763          	bgtz	a5,8000524e <end_op+0xbc>
    acquire(&log.lock);
    800051e4:	0003b497          	auipc	s1,0x3b
    800051e8:	abc48493          	addi	s1,s1,-1348 # 8003fca0 <log>
    800051ec:	8526                	mv	a0,s1
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	9d4080e7          	jalr	-1580(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800051f6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800051fa:	8526                	mv	a0,s1
    800051fc:	ffffd097          	auipc	ra,0xffffd
    80005200:	642080e7          	jalr	1602(ra) # 8000283e <wakeup>
    release(&log.lock);
    80005204:	8526                	mv	a0,s1
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	a70080e7          	jalr	-1424(ra) # 80000c76 <release>
}
    8000520e:	a03d                	j	8000523c <end_op+0xaa>
    panic("log.committing");
    80005210:	00004517          	auipc	a0,0x4
    80005214:	46050513          	addi	a0,a0,1120 # 80009670 <syscalls+0x238>
    80005218:	ffffb097          	auipc	ra,0xffffb
    8000521c:	312080e7          	jalr	786(ra) # 8000052a <panic>
    wakeup(&log);
    80005220:	0003b497          	auipc	s1,0x3b
    80005224:	a8048493          	addi	s1,s1,-1408 # 8003fca0 <log>
    80005228:	8526                	mv	a0,s1
    8000522a:	ffffd097          	auipc	ra,0xffffd
    8000522e:	614080e7          	jalr	1556(ra) # 8000283e <wakeup>
  release(&log.lock);
    80005232:	8526                	mv	a0,s1
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	a42080e7          	jalr	-1470(ra) # 80000c76 <release>
}
    8000523c:	70e2                	ld	ra,56(sp)
    8000523e:	7442                	ld	s0,48(sp)
    80005240:	74a2                	ld	s1,40(sp)
    80005242:	7902                	ld	s2,32(sp)
    80005244:	69e2                	ld	s3,24(sp)
    80005246:	6a42                	ld	s4,16(sp)
    80005248:	6aa2                	ld	s5,8(sp)
    8000524a:	6121                	addi	sp,sp,64
    8000524c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000524e:	0003ba97          	auipc	s5,0x3b
    80005252:	a82a8a93          	addi	s5,s5,-1406 # 8003fcd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80005256:	0003ba17          	auipc	s4,0x3b
    8000525a:	a4aa0a13          	addi	s4,s4,-1462 # 8003fca0 <log>
    8000525e:	018a2583          	lw	a1,24(s4)
    80005262:	012585bb          	addw	a1,a1,s2
    80005266:	2585                	addiw	a1,a1,1
    80005268:	028a2503          	lw	a0,40(s4)
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	ccc080e7          	jalr	-820(ra) # 80003f38 <bread>
    80005274:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80005276:	000aa583          	lw	a1,0(s5)
    8000527a:	028a2503          	lw	a0,40(s4)
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	cba080e7          	jalr	-838(ra) # 80003f38 <bread>
    80005286:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005288:	40000613          	li	a2,1024
    8000528c:	05850593          	addi	a1,a0,88
    80005290:	05848513          	addi	a0,s1,88
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	a86080e7          	jalr	-1402(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000529c:	8526                	mv	a0,s1
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	d8c080e7          	jalr	-628(ra) # 8000402a <bwrite>
    brelse(from);
    800052a6:	854e                	mv	a0,s3
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	dc0080e7          	jalr	-576(ra) # 80004068 <brelse>
    brelse(to);
    800052b0:	8526                	mv	a0,s1
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	db6080e7          	jalr	-586(ra) # 80004068 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800052ba:	2905                	addiw	s2,s2,1
    800052bc:	0a91                	addi	s5,s5,4
    800052be:	02ca2783          	lw	a5,44(s4)
    800052c2:	f8f94ee3          	blt	s2,a5,8000525e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800052c6:	00000097          	auipc	ra,0x0
    800052ca:	c66080e7          	jalr	-922(ra) # 80004f2c <write_head>
    install_trans(0); // Now install writes to home locations
    800052ce:	4501                	li	a0,0
    800052d0:	00000097          	auipc	ra,0x0
    800052d4:	cd8080e7          	jalr	-808(ra) # 80004fa8 <install_trans>
    log.lh.n = 0;
    800052d8:	0003b797          	auipc	a5,0x3b
    800052dc:	9e07aa23          	sw	zero,-1548(a5) # 8003fccc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800052e0:	00000097          	auipc	ra,0x0
    800052e4:	c4c080e7          	jalr	-948(ra) # 80004f2c <write_head>
    800052e8:	bdf5                	j	800051e4 <end_op+0x52>

00000000800052ea <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800052ea:	1101                	addi	sp,sp,-32
    800052ec:	ec06                	sd	ra,24(sp)
    800052ee:	e822                	sd	s0,16(sp)
    800052f0:	e426                	sd	s1,8(sp)
    800052f2:	e04a                	sd	s2,0(sp)
    800052f4:	1000                	addi	s0,sp,32
    800052f6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800052f8:	0003b917          	auipc	s2,0x3b
    800052fc:	9a890913          	addi	s2,s2,-1624 # 8003fca0 <log>
    80005300:	854a                	mv	a0,s2
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	8c0080e7          	jalr	-1856(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000530a:	02c92603          	lw	a2,44(s2)
    8000530e:	47f5                	li	a5,29
    80005310:	06c7c563          	blt	a5,a2,8000537a <log_write+0x90>
    80005314:	0003b797          	auipc	a5,0x3b
    80005318:	9a87a783          	lw	a5,-1624(a5) # 8003fcbc <log+0x1c>
    8000531c:	37fd                	addiw	a5,a5,-1
    8000531e:	04f65e63          	bge	a2,a5,8000537a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005322:	0003b797          	auipc	a5,0x3b
    80005326:	99e7a783          	lw	a5,-1634(a5) # 8003fcc0 <log+0x20>
    8000532a:	06f05063          	blez	a5,8000538a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000532e:	4781                	li	a5,0
    80005330:	06c05563          	blez	a2,8000539a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80005334:	44cc                	lw	a1,12(s1)
    80005336:	0003b717          	auipc	a4,0x3b
    8000533a:	99a70713          	addi	a4,a4,-1638 # 8003fcd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000533e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80005340:	4314                	lw	a3,0(a4)
    80005342:	04b68c63          	beq	a3,a1,8000539a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80005346:	2785                	addiw	a5,a5,1
    80005348:	0711                	addi	a4,a4,4
    8000534a:	fef61be3          	bne	a2,a5,80005340 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000534e:	0621                	addi	a2,a2,8
    80005350:	060a                	slli	a2,a2,0x2
    80005352:	0003b797          	auipc	a5,0x3b
    80005356:	94e78793          	addi	a5,a5,-1714 # 8003fca0 <log>
    8000535a:	963e                	add	a2,a2,a5
    8000535c:	44dc                	lw	a5,12(s1)
    8000535e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005360:	8526                	mv	a0,s1
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	da4080e7          	jalr	-604(ra) # 80004106 <bpin>
    log.lh.n++;
    8000536a:	0003b717          	auipc	a4,0x3b
    8000536e:	93670713          	addi	a4,a4,-1738 # 8003fca0 <log>
    80005372:	575c                	lw	a5,44(a4)
    80005374:	2785                	addiw	a5,a5,1
    80005376:	d75c                	sw	a5,44(a4)
    80005378:	a835                	j	800053b4 <log_write+0xca>
    panic("too big a transaction");
    8000537a:	00004517          	auipc	a0,0x4
    8000537e:	30650513          	addi	a0,a0,774 # 80009680 <syscalls+0x248>
    80005382:	ffffb097          	auipc	ra,0xffffb
    80005386:	1a8080e7          	jalr	424(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000538a:	00004517          	auipc	a0,0x4
    8000538e:	30e50513          	addi	a0,a0,782 # 80009698 <syscalls+0x260>
    80005392:	ffffb097          	auipc	ra,0xffffb
    80005396:	198080e7          	jalr	408(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000539a:	00878713          	addi	a4,a5,8
    8000539e:	00271693          	slli	a3,a4,0x2
    800053a2:	0003b717          	auipc	a4,0x3b
    800053a6:	8fe70713          	addi	a4,a4,-1794 # 8003fca0 <log>
    800053aa:	9736                	add	a4,a4,a3
    800053ac:	44d4                	lw	a3,12(s1)
    800053ae:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800053b0:	faf608e3          	beq	a2,a5,80005360 <log_write+0x76>
  }
  release(&log.lock);
    800053b4:	0003b517          	auipc	a0,0x3b
    800053b8:	8ec50513          	addi	a0,a0,-1812 # 8003fca0 <log>
    800053bc:	ffffc097          	auipc	ra,0xffffc
    800053c0:	8ba080e7          	jalr	-1862(ra) # 80000c76 <release>
}
    800053c4:	60e2                	ld	ra,24(sp)
    800053c6:	6442                	ld	s0,16(sp)
    800053c8:	64a2                	ld	s1,8(sp)
    800053ca:	6902                	ld	s2,0(sp)
    800053cc:	6105                	addi	sp,sp,32
    800053ce:	8082                	ret

00000000800053d0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800053d0:	1101                	addi	sp,sp,-32
    800053d2:	ec06                	sd	ra,24(sp)
    800053d4:	e822                	sd	s0,16(sp)
    800053d6:	e426                	sd	s1,8(sp)
    800053d8:	e04a                	sd	s2,0(sp)
    800053da:	1000                	addi	s0,sp,32
    800053dc:	84aa                	mv	s1,a0
    800053de:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800053e0:	00004597          	auipc	a1,0x4
    800053e4:	2d858593          	addi	a1,a1,728 # 800096b8 <syscalls+0x280>
    800053e8:	0521                	addi	a0,a0,8
    800053ea:	ffffb097          	auipc	ra,0xffffb
    800053ee:	748080e7          	jalr	1864(ra) # 80000b32 <initlock>
  lk->name = name;
    800053f2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800053f6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800053fa:	0204a423          	sw	zero,40(s1)
}
    800053fe:	60e2                	ld	ra,24(sp)
    80005400:	6442                	ld	s0,16(sp)
    80005402:	64a2                	ld	s1,8(sp)
    80005404:	6902                	ld	s2,0(sp)
    80005406:	6105                	addi	sp,sp,32
    80005408:	8082                	ret

000000008000540a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000540a:	1101                	addi	sp,sp,-32
    8000540c:	ec06                	sd	ra,24(sp)
    8000540e:	e822                	sd	s0,16(sp)
    80005410:	e426                	sd	s1,8(sp)
    80005412:	e04a                	sd	s2,0(sp)
    80005414:	1000                	addi	s0,sp,32
    80005416:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005418:	00850913          	addi	s2,a0,8
    8000541c:	854a                	mv	a0,s2
    8000541e:	ffffb097          	auipc	ra,0xffffb
    80005422:	7a4080e7          	jalr	1956(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80005426:	409c                	lw	a5,0(s1)
    80005428:	cb89                	beqz	a5,8000543a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000542a:	85ca                	mv	a1,s2
    8000542c:	8526                	mv	a0,s1
    8000542e:	ffffd097          	auipc	ra,0xffffd
    80005432:	286080e7          	jalr	646(ra) # 800026b4 <sleep>
  while (lk->locked) {
    80005436:	409c                	lw	a5,0(s1)
    80005438:	fbed                	bnez	a5,8000542a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000543a:	4785                	li	a5,1
    8000543c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000543e:	ffffc097          	auipc	ra,0xffffc
    80005442:	618080e7          	jalr	1560(ra) # 80001a56 <myproc>
    80005446:	515c                	lw	a5,36(a0)
    80005448:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000544a:	854a                	mv	a0,s2
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	82a080e7          	jalr	-2006(ra) # 80000c76 <release>
}
    80005454:	60e2                	ld	ra,24(sp)
    80005456:	6442                	ld	s0,16(sp)
    80005458:	64a2                	ld	s1,8(sp)
    8000545a:	6902                	ld	s2,0(sp)
    8000545c:	6105                	addi	sp,sp,32
    8000545e:	8082                	ret

0000000080005460 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005460:	1101                	addi	sp,sp,-32
    80005462:	ec06                	sd	ra,24(sp)
    80005464:	e822                	sd	s0,16(sp)
    80005466:	e426                	sd	s1,8(sp)
    80005468:	e04a                	sd	s2,0(sp)
    8000546a:	1000                	addi	s0,sp,32
    8000546c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000546e:	00850913          	addi	s2,a0,8
    80005472:	854a                	mv	a0,s2
    80005474:	ffffb097          	auipc	ra,0xffffb
    80005478:	74e080e7          	jalr	1870(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000547c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005480:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005484:	8526                	mv	a0,s1
    80005486:	ffffd097          	auipc	ra,0xffffd
    8000548a:	3b8080e7          	jalr	952(ra) # 8000283e <wakeup>
  release(&lk->lk);
    8000548e:	854a                	mv	a0,s2
    80005490:	ffffb097          	auipc	ra,0xffffb
    80005494:	7e6080e7          	jalr	2022(ra) # 80000c76 <release>
}
    80005498:	60e2                	ld	ra,24(sp)
    8000549a:	6442                	ld	s0,16(sp)
    8000549c:	64a2                	ld	s1,8(sp)
    8000549e:	6902                	ld	s2,0(sp)
    800054a0:	6105                	addi	sp,sp,32
    800054a2:	8082                	ret

00000000800054a4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800054a4:	7179                	addi	sp,sp,-48
    800054a6:	f406                	sd	ra,40(sp)
    800054a8:	f022                	sd	s0,32(sp)
    800054aa:	ec26                	sd	s1,24(sp)
    800054ac:	e84a                	sd	s2,16(sp)
    800054ae:	e44e                	sd	s3,8(sp)
    800054b0:	1800                	addi	s0,sp,48
    800054b2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800054b4:	00850913          	addi	s2,a0,8
    800054b8:	854a                	mv	a0,s2
    800054ba:	ffffb097          	auipc	ra,0xffffb
    800054be:	708080e7          	jalr	1800(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800054c2:	409c                	lw	a5,0(s1)
    800054c4:	ef99                	bnez	a5,800054e2 <holdingsleep+0x3e>
    800054c6:	4481                	li	s1,0
  release(&lk->lk);
    800054c8:	854a                	mv	a0,s2
    800054ca:	ffffb097          	auipc	ra,0xffffb
    800054ce:	7ac080e7          	jalr	1964(ra) # 80000c76 <release>
  return r;
}
    800054d2:	8526                	mv	a0,s1
    800054d4:	70a2                	ld	ra,40(sp)
    800054d6:	7402                	ld	s0,32(sp)
    800054d8:	64e2                	ld	s1,24(sp)
    800054da:	6942                	ld	s2,16(sp)
    800054dc:	69a2                	ld	s3,8(sp)
    800054de:	6145                	addi	sp,sp,48
    800054e0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800054e2:	0284a983          	lw	s3,40(s1)
    800054e6:	ffffc097          	auipc	ra,0xffffc
    800054ea:	570080e7          	jalr	1392(ra) # 80001a56 <myproc>
    800054ee:	5144                	lw	s1,36(a0)
    800054f0:	413484b3          	sub	s1,s1,s3
    800054f4:	0014b493          	seqz	s1,s1
    800054f8:	bfc1                	j	800054c8 <holdingsleep+0x24>

00000000800054fa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800054fa:	1141                	addi	sp,sp,-16
    800054fc:	e406                	sd	ra,8(sp)
    800054fe:	e022                	sd	s0,0(sp)
    80005500:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005502:	00004597          	auipc	a1,0x4
    80005506:	1c658593          	addi	a1,a1,454 # 800096c8 <syscalls+0x290>
    8000550a:	0003b517          	auipc	a0,0x3b
    8000550e:	8de50513          	addi	a0,a0,-1826 # 8003fde8 <ftable>
    80005512:	ffffb097          	auipc	ra,0xffffb
    80005516:	620080e7          	jalr	1568(ra) # 80000b32 <initlock>
}
    8000551a:	60a2                	ld	ra,8(sp)
    8000551c:	6402                	ld	s0,0(sp)
    8000551e:	0141                	addi	sp,sp,16
    80005520:	8082                	ret

0000000080005522 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005522:	1101                	addi	sp,sp,-32
    80005524:	ec06                	sd	ra,24(sp)
    80005526:	e822                	sd	s0,16(sp)
    80005528:	e426                	sd	s1,8(sp)
    8000552a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000552c:	0003b517          	auipc	a0,0x3b
    80005530:	8bc50513          	addi	a0,a0,-1860 # 8003fde8 <ftable>
    80005534:	ffffb097          	auipc	ra,0xffffb
    80005538:	68e080e7          	jalr	1678(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000553c:	0003b497          	auipc	s1,0x3b
    80005540:	8c448493          	addi	s1,s1,-1852 # 8003fe00 <ftable+0x18>
    80005544:	0003c717          	auipc	a4,0x3c
    80005548:	85c70713          	addi	a4,a4,-1956 # 80040da0 <ftable+0xfb8>
    if(f->ref == 0){
    8000554c:	40dc                	lw	a5,4(s1)
    8000554e:	cf99                	beqz	a5,8000556c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005550:	02848493          	addi	s1,s1,40
    80005554:	fee49ce3          	bne	s1,a4,8000554c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005558:	0003b517          	auipc	a0,0x3b
    8000555c:	89050513          	addi	a0,a0,-1904 # 8003fde8 <ftable>
    80005560:	ffffb097          	auipc	ra,0xffffb
    80005564:	716080e7          	jalr	1814(ra) # 80000c76 <release>
  return 0;
    80005568:	4481                	li	s1,0
    8000556a:	a819                	j	80005580 <filealloc+0x5e>
      f->ref = 1;
    8000556c:	4785                	li	a5,1
    8000556e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005570:	0003b517          	auipc	a0,0x3b
    80005574:	87850513          	addi	a0,a0,-1928 # 8003fde8 <ftable>
    80005578:	ffffb097          	auipc	ra,0xffffb
    8000557c:	6fe080e7          	jalr	1790(ra) # 80000c76 <release>
}
    80005580:	8526                	mv	a0,s1
    80005582:	60e2                	ld	ra,24(sp)
    80005584:	6442                	ld	s0,16(sp)
    80005586:	64a2                	ld	s1,8(sp)
    80005588:	6105                	addi	sp,sp,32
    8000558a:	8082                	ret

000000008000558c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000558c:	1101                	addi	sp,sp,-32
    8000558e:	ec06                	sd	ra,24(sp)
    80005590:	e822                	sd	s0,16(sp)
    80005592:	e426                	sd	s1,8(sp)
    80005594:	1000                	addi	s0,sp,32
    80005596:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005598:	0003b517          	auipc	a0,0x3b
    8000559c:	85050513          	addi	a0,a0,-1968 # 8003fde8 <ftable>
    800055a0:	ffffb097          	auipc	ra,0xffffb
    800055a4:	622080e7          	jalr	1570(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800055a8:	40dc                	lw	a5,4(s1)
    800055aa:	02f05263          	blez	a5,800055ce <filedup+0x42>
    panic("filedup");
  f->ref++;
    800055ae:	2785                	addiw	a5,a5,1
    800055b0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800055b2:	0003b517          	auipc	a0,0x3b
    800055b6:	83650513          	addi	a0,a0,-1994 # 8003fde8 <ftable>
    800055ba:	ffffb097          	auipc	ra,0xffffb
    800055be:	6bc080e7          	jalr	1724(ra) # 80000c76 <release>
  return f;
}
    800055c2:	8526                	mv	a0,s1
    800055c4:	60e2                	ld	ra,24(sp)
    800055c6:	6442                	ld	s0,16(sp)
    800055c8:	64a2                	ld	s1,8(sp)
    800055ca:	6105                	addi	sp,sp,32
    800055cc:	8082                	ret
    panic("filedup");
    800055ce:	00004517          	auipc	a0,0x4
    800055d2:	10250513          	addi	a0,a0,258 # 800096d0 <syscalls+0x298>
    800055d6:	ffffb097          	auipc	ra,0xffffb
    800055da:	f54080e7          	jalr	-172(ra) # 8000052a <panic>

00000000800055de <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800055de:	7139                	addi	sp,sp,-64
    800055e0:	fc06                	sd	ra,56(sp)
    800055e2:	f822                	sd	s0,48(sp)
    800055e4:	f426                	sd	s1,40(sp)
    800055e6:	f04a                	sd	s2,32(sp)
    800055e8:	ec4e                	sd	s3,24(sp)
    800055ea:	e852                	sd	s4,16(sp)
    800055ec:	e456                	sd	s5,8(sp)
    800055ee:	0080                	addi	s0,sp,64
    800055f0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800055f2:	0003a517          	auipc	a0,0x3a
    800055f6:	7f650513          	addi	a0,a0,2038 # 8003fde8 <ftable>
    800055fa:	ffffb097          	auipc	ra,0xffffb
    800055fe:	5c8080e7          	jalr	1480(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005602:	40dc                	lw	a5,4(s1)
    80005604:	06f05163          	blez	a5,80005666 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005608:	37fd                	addiw	a5,a5,-1
    8000560a:	0007871b          	sext.w	a4,a5
    8000560e:	c0dc                	sw	a5,4(s1)
    80005610:	06e04363          	bgtz	a4,80005676 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005614:	0004a903          	lw	s2,0(s1)
    80005618:	0094ca83          	lbu	s5,9(s1)
    8000561c:	0104ba03          	ld	s4,16(s1)
    80005620:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005624:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005628:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000562c:	0003a517          	auipc	a0,0x3a
    80005630:	7bc50513          	addi	a0,a0,1980 # 8003fde8 <ftable>
    80005634:	ffffb097          	auipc	ra,0xffffb
    80005638:	642080e7          	jalr	1602(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    8000563c:	4785                	li	a5,1
    8000563e:	04f90d63          	beq	s2,a5,80005698 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005642:	3979                	addiw	s2,s2,-2
    80005644:	4785                	li	a5,1
    80005646:	0527e063          	bltu	a5,s2,80005686 <fileclose+0xa8>
    begin_op();
    8000564a:	00000097          	auipc	ra,0x0
    8000564e:	ac8080e7          	jalr	-1336(ra) # 80005112 <begin_op>
    iput(ff.ip);
    80005652:	854e                	mv	a0,s3
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	2a2080e7          	jalr	674(ra) # 800048f6 <iput>
    end_op();
    8000565c:	00000097          	auipc	ra,0x0
    80005660:	b36080e7          	jalr	-1226(ra) # 80005192 <end_op>
    80005664:	a00d                	j	80005686 <fileclose+0xa8>
    panic("fileclose");
    80005666:	00004517          	auipc	a0,0x4
    8000566a:	07250513          	addi	a0,a0,114 # 800096d8 <syscalls+0x2a0>
    8000566e:	ffffb097          	auipc	ra,0xffffb
    80005672:	ebc080e7          	jalr	-324(ra) # 8000052a <panic>
    release(&ftable.lock);
    80005676:	0003a517          	auipc	a0,0x3a
    8000567a:	77250513          	addi	a0,a0,1906 # 8003fde8 <ftable>
    8000567e:	ffffb097          	auipc	ra,0xffffb
    80005682:	5f8080e7          	jalr	1528(ra) # 80000c76 <release>
  }
}
    80005686:	70e2                	ld	ra,56(sp)
    80005688:	7442                	ld	s0,48(sp)
    8000568a:	74a2                	ld	s1,40(sp)
    8000568c:	7902                	ld	s2,32(sp)
    8000568e:	69e2                	ld	s3,24(sp)
    80005690:	6a42                	ld	s4,16(sp)
    80005692:	6aa2                	ld	s5,8(sp)
    80005694:	6121                	addi	sp,sp,64
    80005696:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005698:	85d6                	mv	a1,s5
    8000569a:	8552                	mv	a0,s4
    8000569c:	00000097          	auipc	ra,0x0
    800056a0:	34c080e7          	jalr	844(ra) # 800059e8 <pipeclose>
    800056a4:	b7cd                	j	80005686 <fileclose+0xa8>

00000000800056a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800056a6:	715d                	addi	sp,sp,-80
    800056a8:	e486                	sd	ra,72(sp)
    800056aa:	e0a2                	sd	s0,64(sp)
    800056ac:	fc26                	sd	s1,56(sp)
    800056ae:	f84a                	sd	s2,48(sp)
    800056b0:	f44e                	sd	s3,40(sp)
    800056b2:	0880                	addi	s0,sp,80
    800056b4:	84aa                	mv	s1,a0
    800056b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800056b8:	ffffc097          	auipc	ra,0xffffc
    800056bc:	39e080e7          	jalr	926(ra) # 80001a56 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800056c0:	409c                	lw	a5,0(s1)
    800056c2:	37f9                	addiw	a5,a5,-2
    800056c4:	4705                	li	a4,1
    800056c6:	04f76763          	bltu	a4,a5,80005714 <filestat+0x6e>
    800056ca:	892a                	mv	s2,a0
    ilock(f->ip);
    800056cc:	6c88                	ld	a0,24(s1)
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	06e080e7          	jalr	110(ra) # 8000473c <ilock>
    stati(f->ip, &st);
    800056d6:	fb840593          	addi	a1,s0,-72
    800056da:	6c88                	ld	a0,24(s1)
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	2ea080e7          	jalr	746(ra) # 800049c6 <stati>
    iunlock(f->ip);
    800056e4:	6c88                	ld	a0,24(s1)
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	118080e7          	jalr	280(ra) # 800047fe <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800056ee:	46e1                	li	a3,24
    800056f0:	fb840613          	addi	a2,s0,-72
    800056f4:	85ce                	mv	a1,s3
    800056f6:	1d893503          	ld	a0,472(s2)
    800056fa:	ffffc097          	auipc	ra,0xffffc
    800056fe:	f44080e7          	jalr	-188(ra) # 8000163e <copyout>
    80005702:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005706:	60a6                	ld	ra,72(sp)
    80005708:	6406                	ld	s0,64(sp)
    8000570a:	74e2                	ld	s1,56(sp)
    8000570c:	7942                	ld	s2,48(sp)
    8000570e:	79a2                	ld	s3,40(sp)
    80005710:	6161                	addi	sp,sp,80
    80005712:	8082                	ret
  return -1;
    80005714:	557d                	li	a0,-1
    80005716:	bfc5                	j	80005706 <filestat+0x60>

0000000080005718 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005718:	7179                	addi	sp,sp,-48
    8000571a:	f406                	sd	ra,40(sp)
    8000571c:	f022                	sd	s0,32(sp)
    8000571e:	ec26                	sd	s1,24(sp)
    80005720:	e84a                	sd	s2,16(sp)
    80005722:	e44e                	sd	s3,8(sp)
    80005724:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005726:	00854783          	lbu	a5,8(a0)
    8000572a:	c3d5                	beqz	a5,800057ce <fileread+0xb6>
    8000572c:	84aa                	mv	s1,a0
    8000572e:	89ae                	mv	s3,a1
    80005730:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005732:	411c                	lw	a5,0(a0)
    80005734:	4705                	li	a4,1
    80005736:	04e78963          	beq	a5,a4,80005788 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000573a:	470d                	li	a4,3
    8000573c:	04e78d63          	beq	a5,a4,80005796 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005740:	4709                	li	a4,2
    80005742:	06e79e63          	bne	a5,a4,800057be <fileread+0xa6>
    ilock(f->ip);
    80005746:	6d08                	ld	a0,24(a0)
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	ff4080e7          	jalr	-12(ra) # 8000473c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005750:	874a                	mv	a4,s2
    80005752:	5094                	lw	a3,32(s1)
    80005754:	864e                	mv	a2,s3
    80005756:	4585                	li	a1,1
    80005758:	6c88                	ld	a0,24(s1)
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	296080e7          	jalr	662(ra) # 800049f0 <readi>
    80005762:	892a                	mv	s2,a0
    80005764:	00a05563          	blez	a0,8000576e <fileread+0x56>
      f->off += r;
    80005768:	509c                	lw	a5,32(s1)
    8000576a:	9fa9                	addw	a5,a5,a0
    8000576c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000576e:	6c88                	ld	a0,24(s1)
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	08e080e7          	jalr	142(ra) # 800047fe <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005778:	854a                	mv	a0,s2
    8000577a:	70a2                	ld	ra,40(sp)
    8000577c:	7402                	ld	s0,32(sp)
    8000577e:	64e2                	ld	s1,24(sp)
    80005780:	6942                	ld	s2,16(sp)
    80005782:	69a2                	ld	s3,8(sp)
    80005784:	6145                	addi	sp,sp,48
    80005786:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005788:	6908                	ld	a0,16(a0)
    8000578a:	00000097          	auipc	ra,0x0
    8000578e:	3c0080e7          	jalr	960(ra) # 80005b4a <piperead>
    80005792:	892a                	mv	s2,a0
    80005794:	b7d5                	j	80005778 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005796:	02451783          	lh	a5,36(a0)
    8000579a:	03079693          	slli	a3,a5,0x30
    8000579e:	92c1                	srli	a3,a3,0x30
    800057a0:	4725                	li	a4,9
    800057a2:	02d76863          	bltu	a4,a3,800057d2 <fileread+0xba>
    800057a6:	0792                	slli	a5,a5,0x4
    800057a8:	0003a717          	auipc	a4,0x3a
    800057ac:	5a070713          	addi	a4,a4,1440 # 8003fd48 <devsw>
    800057b0:	97ba                	add	a5,a5,a4
    800057b2:	639c                	ld	a5,0(a5)
    800057b4:	c38d                	beqz	a5,800057d6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800057b6:	4505                	li	a0,1
    800057b8:	9782                	jalr	a5
    800057ba:	892a                	mv	s2,a0
    800057bc:	bf75                	j	80005778 <fileread+0x60>
    panic("fileread");
    800057be:	00004517          	auipc	a0,0x4
    800057c2:	f2a50513          	addi	a0,a0,-214 # 800096e8 <syscalls+0x2b0>
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	d64080e7          	jalr	-668(ra) # 8000052a <panic>
    return -1;
    800057ce:	597d                	li	s2,-1
    800057d0:	b765                	j	80005778 <fileread+0x60>
      return -1;
    800057d2:	597d                	li	s2,-1
    800057d4:	b755                	j	80005778 <fileread+0x60>
    800057d6:	597d                	li	s2,-1
    800057d8:	b745                	j	80005778 <fileread+0x60>

00000000800057da <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800057da:	715d                	addi	sp,sp,-80
    800057dc:	e486                	sd	ra,72(sp)
    800057de:	e0a2                	sd	s0,64(sp)
    800057e0:	fc26                	sd	s1,56(sp)
    800057e2:	f84a                	sd	s2,48(sp)
    800057e4:	f44e                	sd	s3,40(sp)
    800057e6:	f052                	sd	s4,32(sp)
    800057e8:	ec56                	sd	s5,24(sp)
    800057ea:	e85a                	sd	s6,16(sp)
    800057ec:	e45e                	sd	s7,8(sp)
    800057ee:	e062                	sd	s8,0(sp)
    800057f0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800057f2:	00954783          	lbu	a5,9(a0)
    800057f6:	10078663          	beqz	a5,80005902 <filewrite+0x128>
    800057fa:	892a                	mv	s2,a0
    800057fc:	8aae                	mv	s5,a1
    800057fe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005800:	411c                	lw	a5,0(a0)
    80005802:	4705                	li	a4,1
    80005804:	02e78263          	beq	a5,a4,80005828 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005808:	470d                	li	a4,3
    8000580a:	02e78663          	beq	a5,a4,80005836 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000580e:	4709                	li	a4,2
    80005810:	0ee79163          	bne	a5,a4,800058f2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005814:	0ac05d63          	blez	a2,800058ce <filewrite+0xf4>
    int i = 0;
    80005818:	4981                	li	s3,0
    8000581a:	6b05                	lui	s6,0x1
    8000581c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005820:	6b85                	lui	s7,0x1
    80005822:	c00b8b9b          	addiw	s7,s7,-1024
    80005826:	a861                	j	800058be <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005828:	6908                	ld	a0,16(a0)
    8000582a:	00000097          	auipc	ra,0x0
    8000582e:	22e080e7          	jalr	558(ra) # 80005a58 <pipewrite>
    80005832:	8a2a                	mv	s4,a0
    80005834:	a045                	j	800058d4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005836:	02451783          	lh	a5,36(a0)
    8000583a:	03079693          	slli	a3,a5,0x30
    8000583e:	92c1                	srli	a3,a3,0x30
    80005840:	4725                	li	a4,9
    80005842:	0cd76263          	bltu	a4,a3,80005906 <filewrite+0x12c>
    80005846:	0792                	slli	a5,a5,0x4
    80005848:	0003a717          	auipc	a4,0x3a
    8000584c:	50070713          	addi	a4,a4,1280 # 8003fd48 <devsw>
    80005850:	97ba                	add	a5,a5,a4
    80005852:	679c                	ld	a5,8(a5)
    80005854:	cbdd                	beqz	a5,8000590a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005856:	4505                	li	a0,1
    80005858:	9782                	jalr	a5
    8000585a:	8a2a                	mv	s4,a0
    8000585c:	a8a5                	j	800058d4 <filewrite+0xfa>
    8000585e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005862:	00000097          	auipc	ra,0x0
    80005866:	8b0080e7          	jalr	-1872(ra) # 80005112 <begin_op>
      ilock(f->ip);
    8000586a:	01893503          	ld	a0,24(s2)
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	ece080e7          	jalr	-306(ra) # 8000473c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005876:	8762                	mv	a4,s8
    80005878:	02092683          	lw	a3,32(s2)
    8000587c:	01598633          	add	a2,s3,s5
    80005880:	4585                	li	a1,1
    80005882:	01893503          	ld	a0,24(s2)
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	262080e7          	jalr	610(ra) # 80004ae8 <writei>
    8000588e:	84aa                	mv	s1,a0
    80005890:	00a05763          	blez	a0,8000589e <filewrite+0xc4>
        f->off += r;
    80005894:	02092783          	lw	a5,32(s2)
    80005898:	9fa9                	addw	a5,a5,a0
    8000589a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000589e:	01893503          	ld	a0,24(s2)
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	f5c080e7          	jalr	-164(ra) # 800047fe <iunlock>
      end_op();
    800058aa:	00000097          	auipc	ra,0x0
    800058ae:	8e8080e7          	jalr	-1816(ra) # 80005192 <end_op>

      if(r != n1){
    800058b2:	009c1f63          	bne	s8,s1,800058d0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800058b6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800058ba:	0149db63          	bge	s3,s4,800058d0 <filewrite+0xf6>
      int n1 = n - i;
    800058be:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800058c2:	84be                	mv	s1,a5
    800058c4:	2781                	sext.w	a5,a5
    800058c6:	f8fb5ce3          	bge	s6,a5,8000585e <filewrite+0x84>
    800058ca:	84de                	mv	s1,s7
    800058cc:	bf49                	j	8000585e <filewrite+0x84>
    int i = 0;
    800058ce:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800058d0:	013a1f63          	bne	s4,s3,800058ee <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800058d4:	8552                	mv	a0,s4
    800058d6:	60a6                	ld	ra,72(sp)
    800058d8:	6406                	ld	s0,64(sp)
    800058da:	74e2                	ld	s1,56(sp)
    800058dc:	7942                	ld	s2,48(sp)
    800058de:	79a2                	ld	s3,40(sp)
    800058e0:	7a02                	ld	s4,32(sp)
    800058e2:	6ae2                	ld	s5,24(sp)
    800058e4:	6b42                	ld	s6,16(sp)
    800058e6:	6ba2                	ld	s7,8(sp)
    800058e8:	6c02                	ld	s8,0(sp)
    800058ea:	6161                	addi	sp,sp,80
    800058ec:	8082                	ret
    ret = (i == n ? n : -1);
    800058ee:	5a7d                	li	s4,-1
    800058f0:	b7d5                	j	800058d4 <filewrite+0xfa>
    panic("filewrite");
    800058f2:	00004517          	auipc	a0,0x4
    800058f6:	e0650513          	addi	a0,a0,-506 # 800096f8 <syscalls+0x2c0>
    800058fa:	ffffb097          	auipc	ra,0xffffb
    800058fe:	c30080e7          	jalr	-976(ra) # 8000052a <panic>
    return -1;
    80005902:	5a7d                	li	s4,-1
    80005904:	bfc1                	j	800058d4 <filewrite+0xfa>
      return -1;
    80005906:	5a7d                	li	s4,-1
    80005908:	b7f1                	j	800058d4 <filewrite+0xfa>
    8000590a:	5a7d                	li	s4,-1
    8000590c:	b7e1                	j	800058d4 <filewrite+0xfa>

000000008000590e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000590e:	7179                	addi	sp,sp,-48
    80005910:	f406                	sd	ra,40(sp)
    80005912:	f022                	sd	s0,32(sp)
    80005914:	ec26                	sd	s1,24(sp)
    80005916:	e84a                	sd	s2,16(sp)
    80005918:	e44e                	sd	s3,8(sp)
    8000591a:	e052                	sd	s4,0(sp)
    8000591c:	1800                	addi	s0,sp,48
    8000591e:	84aa                	mv	s1,a0
    80005920:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005922:	0005b023          	sd	zero,0(a1)
    80005926:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000592a:	00000097          	auipc	ra,0x0
    8000592e:	bf8080e7          	jalr	-1032(ra) # 80005522 <filealloc>
    80005932:	e088                	sd	a0,0(s1)
    80005934:	c551                	beqz	a0,800059c0 <pipealloc+0xb2>
    80005936:	00000097          	auipc	ra,0x0
    8000593a:	bec080e7          	jalr	-1044(ra) # 80005522 <filealloc>
    8000593e:	00aa3023          	sd	a0,0(s4)
    80005942:	c92d                	beqz	a0,800059b4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005944:	ffffb097          	auipc	ra,0xffffb
    80005948:	18e080e7          	jalr	398(ra) # 80000ad2 <kalloc>
    8000594c:	892a                	mv	s2,a0
    8000594e:	c125                	beqz	a0,800059ae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005950:	4985                	li	s3,1
    80005952:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005956:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000595a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000595e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005962:	00004597          	auipc	a1,0x4
    80005966:	da658593          	addi	a1,a1,-602 # 80009708 <syscalls+0x2d0>
    8000596a:	ffffb097          	auipc	ra,0xffffb
    8000596e:	1c8080e7          	jalr	456(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80005972:	609c                	ld	a5,0(s1)
    80005974:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005978:	609c                	ld	a5,0(s1)
    8000597a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000597e:	609c                	ld	a5,0(s1)
    80005980:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005984:	609c                	ld	a5,0(s1)
    80005986:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000598a:	000a3783          	ld	a5,0(s4)
    8000598e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005992:	000a3783          	ld	a5,0(s4)
    80005996:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000599a:	000a3783          	ld	a5,0(s4)
    8000599e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800059a2:	000a3783          	ld	a5,0(s4)
    800059a6:	0127b823          	sd	s2,16(a5)
  return 0;
    800059aa:	4501                	li	a0,0
    800059ac:	a025                	j	800059d4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800059ae:	6088                	ld	a0,0(s1)
    800059b0:	e501                	bnez	a0,800059b8 <pipealloc+0xaa>
    800059b2:	a039                	j	800059c0 <pipealloc+0xb2>
    800059b4:	6088                	ld	a0,0(s1)
    800059b6:	c51d                	beqz	a0,800059e4 <pipealloc+0xd6>
    fileclose(*f0);
    800059b8:	00000097          	auipc	ra,0x0
    800059bc:	c26080e7          	jalr	-986(ra) # 800055de <fileclose>
  if(*f1)
    800059c0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800059c4:	557d                	li	a0,-1
  if(*f1)
    800059c6:	c799                	beqz	a5,800059d4 <pipealloc+0xc6>
    fileclose(*f1);
    800059c8:	853e                	mv	a0,a5
    800059ca:	00000097          	auipc	ra,0x0
    800059ce:	c14080e7          	jalr	-1004(ra) # 800055de <fileclose>
  return -1;
    800059d2:	557d                	li	a0,-1
}
    800059d4:	70a2                	ld	ra,40(sp)
    800059d6:	7402                	ld	s0,32(sp)
    800059d8:	64e2                	ld	s1,24(sp)
    800059da:	6942                	ld	s2,16(sp)
    800059dc:	69a2                	ld	s3,8(sp)
    800059de:	6a02                	ld	s4,0(sp)
    800059e0:	6145                	addi	sp,sp,48
    800059e2:	8082                	ret
  return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	b7fd                	j	800059d4 <pipealloc+0xc6>

00000000800059e8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800059e8:	1101                	addi	sp,sp,-32
    800059ea:	ec06                	sd	ra,24(sp)
    800059ec:	e822                	sd	s0,16(sp)
    800059ee:	e426                	sd	s1,8(sp)
    800059f0:	e04a                	sd	s2,0(sp)
    800059f2:	1000                	addi	s0,sp,32
    800059f4:	84aa                	mv	s1,a0
    800059f6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800059f8:	ffffb097          	auipc	ra,0xffffb
    800059fc:	1ca080e7          	jalr	458(ra) # 80000bc2 <acquire>
  if(writable){
    80005a00:	02090d63          	beqz	s2,80005a3a <pipeclose+0x52>
    pi->writeopen = 0;
    80005a04:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005a08:	21848513          	addi	a0,s1,536
    80005a0c:	ffffd097          	auipc	ra,0xffffd
    80005a10:	e32080e7          	jalr	-462(ra) # 8000283e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005a14:	2204b783          	ld	a5,544(s1)
    80005a18:	eb95                	bnez	a5,80005a4c <pipeclose+0x64>
    release(&pi->lock);
    80005a1a:	8526                	mv	a0,s1
    80005a1c:	ffffb097          	auipc	ra,0xffffb
    80005a20:	25a080e7          	jalr	602(ra) # 80000c76 <release>
    kfree((char*)pi);
    80005a24:	8526                	mv	a0,s1
    80005a26:	ffffb097          	auipc	ra,0xffffb
    80005a2a:	fb0080e7          	jalr	-80(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005a2e:	60e2                	ld	ra,24(sp)
    80005a30:	6442                	ld	s0,16(sp)
    80005a32:	64a2                	ld	s1,8(sp)
    80005a34:	6902                	ld	s2,0(sp)
    80005a36:	6105                	addi	sp,sp,32
    80005a38:	8082                	ret
    pi->readopen = 0;
    80005a3a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005a3e:	21c48513          	addi	a0,s1,540
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	dfc080e7          	jalr	-516(ra) # 8000283e <wakeup>
    80005a4a:	b7e9                	j	80005a14 <pipeclose+0x2c>
    release(&pi->lock);
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffb097          	auipc	ra,0xffffb
    80005a52:	228080e7          	jalr	552(ra) # 80000c76 <release>
}
    80005a56:	bfe1                	j	80005a2e <pipeclose+0x46>

0000000080005a58 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005a58:	711d                	addi	sp,sp,-96
    80005a5a:	ec86                	sd	ra,88(sp)
    80005a5c:	e8a2                	sd	s0,80(sp)
    80005a5e:	e4a6                	sd	s1,72(sp)
    80005a60:	e0ca                	sd	s2,64(sp)
    80005a62:	fc4e                	sd	s3,56(sp)
    80005a64:	f852                	sd	s4,48(sp)
    80005a66:	f456                	sd	s5,40(sp)
    80005a68:	f05a                	sd	s6,32(sp)
    80005a6a:	ec5e                	sd	s7,24(sp)
    80005a6c:	e862                	sd	s8,16(sp)
    80005a6e:	1080                	addi	s0,sp,96
    80005a70:	84aa                	mv	s1,a0
    80005a72:	8aae                	mv	s5,a1
    80005a74:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005a76:	ffffc097          	auipc	ra,0xffffc
    80005a7a:	fe0080e7          	jalr	-32(ra) # 80001a56 <myproc>
    80005a7e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffb097          	auipc	ra,0xffffb
    80005a86:	140080e7          	jalr	320(ra) # 80000bc2 <acquire>
  while(i < n){
    80005a8a:	0b405363          	blez	s4,80005b30 <pipewrite+0xd8>
  int i = 0;
    80005a8e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005a90:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005a92:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005a96:	21c48b93          	addi	s7,s1,540
    80005a9a:	a089                	j	80005adc <pipewrite+0x84>
      release(&pi->lock);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffb097          	auipc	ra,0xffffb
    80005aa2:	1d8080e7          	jalr	472(ra) # 80000c76 <release>
      return -1;
    80005aa6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	60e6                	ld	ra,88(sp)
    80005aac:	6446                	ld	s0,80(sp)
    80005aae:	64a6                	ld	s1,72(sp)
    80005ab0:	6906                	ld	s2,64(sp)
    80005ab2:	79e2                	ld	s3,56(sp)
    80005ab4:	7a42                	ld	s4,48(sp)
    80005ab6:	7aa2                	ld	s5,40(sp)
    80005ab8:	7b02                	ld	s6,32(sp)
    80005aba:	6be2                	ld	s7,24(sp)
    80005abc:	6c42                	ld	s8,16(sp)
    80005abe:	6125                	addi	sp,sp,96
    80005ac0:	8082                	ret
      wakeup(&pi->nread);
    80005ac2:	8562                	mv	a0,s8
    80005ac4:	ffffd097          	auipc	ra,0xffffd
    80005ac8:	d7a080e7          	jalr	-646(ra) # 8000283e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005acc:	85a6                	mv	a1,s1
    80005ace:	855e                	mv	a0,s7
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	be4080e7          	jalr	-1052(ra) # 800026b4 <sleep>
  while(i < n){
    80005ad8:	05495d63          	bge	s2,s4,80005b32 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005adc:	2204a783          	lw	a5,544(s1)
    80005ae0:	dfd5                	beqz	a5,80005a9c <pipewrite+0x44>
    80005ae2:	01c9a783          	lw	a5,28(s3)
    80005ae6:	fbdd                	bnez	a5,80005a9c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005ae8:	2184a783          	lw	a5,536(s1)
    80005aec:	21c4a703          	lw	a4,540(s1)
    80005af0:	2007879b          	addiw	a5,a5,512
    80005af4:	fcf707e3          	beq	a4,a5,80005ac2 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005af8:	4685                	li	a3,1
    80005afa:	01590633          	add	a2,s2,s5
    80005afe:	faf40593          	addi	a1,s0,-81
    80005b02:	1d89b503          	ld	a0,472(s3)
    80005b06:	ffffc097          	auipc	ra,0xffffc
    80005b0a:	bc4080e7          	jalr	-1084(ra) # 800016ca <copyin>
    80005b0e:	03650263          	beq	a0,s6,80005b32 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005b12:	21c4a783          	lw	a5,540(s1)
    80005b16:	0017871b          	addiw	a4,a5,1
    80005b1a:	20e4ae23          	sw	a4,540(s1)
    80005b1e:	1ff7f793          	andi	a5,a5,511
    80005b22:	97a6                	add	a5,a5,s1
    80005b24:	faf44703          	lbu	a4,-81(s0)
    80005b28:	00e78c23          	sb	a4,24(a5)
      i++;
    80005b2c:	2905                	addiw	s2,s2,1
    80005b2e:	b76d                	j	80005ad8 <pipewrite+0x80>
  int i = 0;
    80005b30:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005b32:	21848513          	addi	a0,s1,536
    80005b36:	ffffd097          	auipc	ra,0xffffd
    80005b3a:	d08080e7          	jalr	-760(ra) # 8000283e <wakeup>
  release(&pi->lock);
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffb097          	auipc	ra,0xffffb
    80005b44:	136080e7          	jalr	310(ra) # 80000c76 <release>
  return i;
    80005b48:	b785                	j	80005aa8 <pipewrite+0x50>

0000000080005b4a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005b4a:	715d                	addi	sp,sp,-80
    80005b4c:	e486                	sd	ra,72(sp)
    80005b4e:	e0a2                	sd	s0,64(sp)
    80005b50:	fc26                	sd	s1,56(sp)
    80005b52:	f84a                	sd	s2,48(sp)
    80005b54:	f44e                	sd	s3,40(sp)
    80005b56:	f052                	sd	s4,32(sp)
    80005b58:	ec56                	sd	s5,24(sp)
    80005b5a:	e85a                	sd	s6,16(sp)
    80005b5c:	0880                	addi	s0,sp,80
    80005b5e:	84aa                	mv	s1,a0
    80005b60:	892e                	mv	s2,a1
    80005b62:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005b64:	ffffc097          	auipc	ra,0xffffc
    80005b68:	ef2080e7          	jalr	-270(ra) # 80001a56 <myproc>
    80005b6c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005b6e:	8526                	mv	a0,s1
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	052080e7          	jalr	82(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005b78:	2184a703          	lw	a4,536(s1)
    80005b7c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005b80:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005b84:	02f71463          	bne	a4,a5,80005bac <piperead+0x62>
    80005b88:	2244a783          	lw	a5,548(s1)
    80005b8c:	c385                	beqz	a5,80005bac <piperead+0x62>
    if(pr->killed){
    80005b8e:	01ca2783          	lw	a5,28(s4)
    80005b92:	ebc1                	bnez	a5,80005c22 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005b94:	85a6                	mv	a1,s1
    80005b96:	854e                	mv	a0,s3
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	b1c080e7          	jalr	-1252(ra) # 800026b4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005ba0:	2184a703          	lw	a4,536(s1)
    80005ba4:	21c4a783          	lw	a5,540(s1)
    80005ba8:	fef700e3          	beq	a4,a5,80005b88 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005bac:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005bae:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005bb0:	05505363          	blez	s5,80005bf6 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005bb4:	2184a783          	lw	a5,536(s1)
    80005bb8:	21c4a703          	lw	a4,540(s1)
    80005bbc:	02f70d63          	beq	a4,a5,80005bf6 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005bc0:	0017871b          	addiw	a4,a5,1
    80005bc4:	20e4ac23          	sw	a4,536(s1)
    80005bc8:	1ff7f793          	andi	a5,a5,511
    80005bcc:	97a6                	add	a5,a5,s1
    80005bce:	0187c783          	lbu	a5,24(a5)
    80005bd2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005bd6:	4685                	li	a3,1
    80005bd8:	fbf40613          	addi	a2,s0,-65
    80005bdc:	85ca                	mv	a1,s2
    80005bde:	1d8a3503          	ld	a0,472(s4)
    80005be2:	ffffc097          	auipc	ra,0xffffc
    80005be6:	a5c080e7          	jalr	-1444(ra) # 8000163e <copyout>
    80005bea:	01650663          	beq	a0,s6,80005bf6 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005bee:	2985                	addiw	s3,s3,1
    80005bf0:	0905                	addi	s2,s2,1
    80005bf2:	fd3a91e3          	bne	s5,s3,80005bb4 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005bf6:	21c48513          	addi	a0,s1,540
    80005bfa:	ffffd097          	auipc	ra,0xffffd
    80005bfe:	c44080e7          	jalr	-956(ra) # 8000283e <wakeup>
  release(&pi->lock);
    80005c02:	8526                	mv	a0,s1
    80005c04:	ffffb097          	auipc	ra,0xffffb
    80005c08:	072080e7          	jalr	114(ra) # 80000c76 <release>
  return i;
}
    80005c0c:	854e                	mv	a0,s3
    80005c0e:	60a6                	ld	ra,72(sp)
    80005c10:	6406                	ld	s0,64(sp)
    80005c12:	74e2                	ld	s1,56(sp)
    80005c14:	7942                	ld	s2,48(sp)
    80005c16:	79a2                	ld	s3,40(sp)
    80005c18:	7a02                	ld	s4,32(sp)
    80005c1a:	6ae2                	ld	s5,24(sp)
    80005c1c:	6b42                	ld	s6,16(sp)
    80005c1e:	6161                	addi	sp,sp,80
    80005c20:	8082                	ret
      release(&pi->lock);
    80005c22:	8526                	mv	a0,s1
    80005c24:	ffffb097          	auipc	ra,0xffffb
    80005c28:	052080e7          	jalr	82(ra) # 80000c76 <release>
      return -1;
    80005c2c:	59fd                	li	s3,-1
    80005c2e:	bff9                	j	80005c0c <piperead+0xc2>

0000000080005c30 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005c30:	dd010113          	addi	sp,sp,-560
    80005c34:	22113423          	sd	ra,552(sp)
    80005c38:	22813023          	sd	s0,544(sp)
    80005c3c:	20913c23          	sd	s1,536(sp)
    80005c40:	21213823          	sd	s2,528(sp)
    80005c44:	21313423          	sd	s3,520(sp)
    80005c48:	21413023          	sd	s4,512(sp)
    80005c4c:	ffd6                	sd	s5,504(sp)
    80005c4e:	fbda                	sd	s6,496(sp)
    80005c50:	f7de                	sd	s7,488(sp)
    80005c52:	f3e2                	sd	s8,480(sp)
    80005c54:	efe6                	sd	s9,472(sp)
    80005c56:	ebea                	sd	s10,464(sp)
    80005c58:	e7ee                	sd	s11,456(sp)
    80005c5a:	1c00                	addi	s0,sp,560
    80005c5c:	dea43823          	sd	a0,-528(s0)
    80005c60:	deb43023          	sd	a1,-544(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005c64:	ffffc097          	auipc	ra,0xffffc
    80005c68:	df2080e7          	jalr	-526(ra) # 80001a56 <myproc>
    80005c6c:	89aa                	mv	s3,a0
  struct thread *t = mythread();
    80005c6e:	ffffc097          	auipc	ra,0xffffc
    80005c72:	e22080e7          	jalr	-478(ra) # 80001a90 <mythread>
    80005c76:	e0a43423          	sd	a0,-504(s0)

  // ADDED Q3
  for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    80005c7a:	27898493          	addi	s1,s3,632
    80005c7e:	6905                	lui	s2,0x1
    80005c80:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    80005c84:	994e                	add	s2,s2,s3
    if(t_temp->tid != t->tid){
      acquire(&t_temp->lock);
      t_temp->terminated = 1;
    80005c86:	4a85                	li	s5,1
      if(t_temp->state == SLEEPING){
    80005c88:	4a09                	li	s4,2
        t_temp->state = RUNNABLE;
    80005c8a:	4b0d                	li	s6,3
    80005c8c:	a015                	j	80005cb0 <exec+0x80>
    80005c8e:	0164ac23          	sw	s6,24(s1)
      }
      release(&t_temp->lock);
    80005c92:	8526                	mv	a0,s1
    80005c94:	ffffb097          	auipc	ra,0xffffb
    80005c98:	fe2080e7          	jalr	-30(ra) # 80000c76 <release>
      kthread_join(t_temp->tid, 0);
    80005c9c:	4581                	li	a1,0
    80005c9e:	5888                	lw	a0,48(s1)
    80005ca0:	ffffd097          	auipc	ra,0xffffd
    80005ca4:	18e080e7          	jalr	398(ra) # 80002e2e <kthread_join>
  for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    80005ca8:	0c048493          	addi	s1,s1,192
    80005cac:	03248363          	beq	s1,s2,80005cd2 <exec+0xa2>
    if(t_temp->tid != t->tid){
    80005cb0:	5898                	lw	a4,48(s1)
    80005cb2:	e0843783          	ld	a5,-504(s0)
    80005cb6:	5b9c                	lw	a5,48(a5)
    80005cb8:	fef708e3          	beq	a4,a5,80005ca8 <exec+0x78>
      acquire(&t_temp->lock);
    80005cbc:	8526                	mv	a0,s1
    80005cbe:	ffffb097          	auipc	ra,0xffffb
    80005cc2:	f04080e7          	jalr	-252(ra) # 80000bc2 <acquire>
      t_temp->terminated = 1;
    80005cc6:	0354a423          	sw	s5,40(s1)
      if(t_temp->state == SLEEPING){
    80005cca:	4c9c                	lw	a5,24(s1)
    80005ccc:	fd4793e3          	bne	a5,s4,80005c92 <exec+0x62>
    80005cd0:	bf7d                	j	80005c8e <exec+0x5e>
    }
  }

  begin_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	440080e7          	jalr	1088(ra) # 80005112 <begin_op>

  if((ip = namei(path)) == 0){
    80005cda:	df043503          	ld	a0,-528(s0)
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	214080e7          	jalr	532(ra) # 80004ef2 <namei>
    80005ce6:	8aaa                	mv	s5,a0
    80005ce8:	cd25                	beqz	a0,80005d60 <exec+0x130>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	a52080e7          	jalr	-1454(ra) # 8000473c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005cf2:	04000713          	li	a4,64
    80005cf6:	4681                	li	a3,0
    80005cf8:	e4840613          	addi	a2,s0,-440
    80005cfc:	4581                	li	a1,0
    80005cfe:	8556                	mv	a0,s5
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	cf0080e7          	jalr	-784(ra) # 800049f0 <readi>
    80005d08:	04000793          	li	a5,64
    80005d0c:	00f51a63          	bne	a0,a5,80005d20 <exec+0xf0>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005d10:	e4842703          	lw	a4,-440(s0)
    80005d14:	464c47b7          	lui	a5,0x464c4
    80005d18:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005d1c:	04f70863          	beq	a4,a5,80005d6c <exec+0x13c>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005d20:	8556                	mv	a0,s5
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	c7c080e7          	jalr	-900(ra) # 8000499e <iunlockput>
    end_op();
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	468080e7          	jalr	1128(ra) # 80005192 <end_op>
  }
  return -1;
    80005d32:	557d                	li	a0,-1
}
    80005d34:	22813083          	ld	ra,552(sp)
    80005d38:	22013403          	ld	s0,544(sp)
    80005d3c:	21813483          	ld	s1,536(sp)
    80005d40:	21013903          	ld	s2,528(sp)
    80005d44:	20813983          	ld	s3,520(sp)
    80005d48:	20013a03          	ld	s4,512(sp)
    80005d4c:	7afe                	ld	s5,504(sp)
    80005d4e:	7b5e                	ld	s6,496(sp)
    80005d50:	7bbe                	ld	s7,488(sp)
    80005d52:	7c1e                	ld	s8,480(sp)
    80005d54:	6cfe                	ld	s9,472(sp)
    80005d56:	6d5e                	ld	s10,464(sp)
    80005d58:	6dbe                	ld	s11,456(sp)
    80005d5a:	23010113          	addi	sp,sp,560
    80005d5e:	8082                	ret
    end_op();
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	432080e7          	jalr	1074(ra) # 80005192 <end_op>
    return -1;
    80005d68:	557d                	li	a0,-1
    80005d6a:	b7e9                	j	80005d34 <exec+0x104>
  if((pagetable = proc_pagetable(p)) == 0)
    80005d6c:	854e                	mv	a0,s3
    80005d6e:	ffffc097          	auipc	ra,0xffffc
    80005d72:	f0a080e7          	jalr	-246(ra) # 80001c78 <proc_pagetable>
    80005d76:	8b2a                	mv	s6,a0
    80005d78:	d545                	beqz	a0,80005d20 <exec+0xf0>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d7a:	e6842783          	lw	a5,-408(s0)
    80005d7e:	e8045703          	lhu	a4,-384(s0)
    80005d82:	c735                	beqz	a4,80005dee <exec+0x1be>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005d84:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d86:	e0043023          	sd	zero,-512(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005d8a:	6a05                	lui	s4,0x1
    80005d8c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005d90:	dce43c23          	sd	a4,-552(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005d94:	6d85                	lui	s11,0x1
    80005d96:	7d7d                	lui	s10,0xfffff
    80005d98:	a485                	j	80005ff8 <exec+0x3c8>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005d9a:	00004517          	auipc	a0,0x4
    80005d9e:	97650513          	addi	a0,a0,-1674 # 80009710 <syscalls+0x2d8>
    80005da2:	ffffa097          	auipc	ra,0xffffa
    80005da6:	788080e7          	jalr	1928(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005daa:	874a                	mv	a4,s2
    80005dac:	009c86bb          	addw	a3,s9,s1
    80005db0:	4581                	li	a1,0
    80005db2:	8556                	mv	a0,s5
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	c3c080e7          	jalr	-964(ra) # 800049f0 <readi>
    80005dbc:	2501                	sext.w	a0,a0
    80005dbe:	1ca91d63          	bne	s2,a0,80005f98 <exec+0x368>
  for(i = 0; i < sz; i += PGSIZE){
    80005dc2:	009d84bb          	addw	s1,s11,s1
    80005dc6:	013d09bb          	addw	s3,s10,s3
    80005dca:	2174f763          	bgeu	s1,s7,80005fd8 <exec+0x3a8>
    pa = walkaddr(pagetable, va + i);
    80005dce:	02049593          	slli	a1,s1,0x20
    80005dd2:	9181                	srli	a1,a1,0x20
    80005dd4:	95e2                	add	a1,a1,s8
    80005dd6:	855a                	mv	a0,s6
    80005dd8:	ffffb097          	auipc	ra,0xffffb
    80005ddc:	274080e7          	jalr	628(ra) # 8000104c <walkaddr>
    80005de0:	862a                	mv	a2,a0
    if(pa == 0)
    80005de2:	dd45                	beqz	a0,80005d9a <exec+0x16a>
      n = PGSIZE;
    80005de4:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005de6:	fd49f2e3          	bgeu	s3,s4,80005daa <exec+0x17a>
      n = sz - i;
    80005dea:	894e                	mv	s2,s3
    80005dec:	bf7d                	j	80005daa <exec+0x17a>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005dee:	4481                	li	s1,0
  iunlockput(ip);
    80005df0:	8556                	mv	a0,s5
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	bac080e7          	jalr	-1108(ra) # 8000499e <iunlockput>
  end_op();
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	398080e7          	jalr	920(ra) # 80005192 <end_op>
  p = myproc();
    80005e02:	ffffc097          	auipc	ra,0xffffc
    80005e06:	c54080e7          	jalr	-940(ra) # 80001a56 <myproc>
    80005e0a:	8a2a                	mv	s4,a0
  uint64 oldsz = p->sz;
    80005e0c:	1d053d03          	ld	s10,464(a0)
  sz = PGROUNDUP(sz);
    80005e10:	6785                	lui	a5,0x1
    80005e12:	17fd                	addi	a5,a5,-1
    80005e14:	94be                	add	s1,s1,a5
    80005e16:	77fd                	lui	a5,0xfffff
    80005e18:	8fe5                	and	a5,a5,s1
    80005e1a:	def43423          	sd	a5,-536(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005e1e:	6609                	lui	a2,0x2
    80005e20:	963e                	add	a2,a2,a5
    80005e22:	85be                	mv	a1,a5
    80005e24:	855a                	mv	a0,s6
    80005e26:	ffffb097          	auipc	ra,0xffffb
    80005e2a:	5c8080e7          	jalr	1480(ra) # 800013ee <uvmalloc>
    80005e2e:	8caa                	mv	s9,a0
  ip = 0;
    80005e30:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005e32:	16050363          	beqz	a0,80005f98 <exec+0x368>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005e36:	75f9                	lui	a1,0xffffe
    80005e38:	95aa                	add	a1,a1,a0
    80005e3a:	855a                	mv	a0,s6
    80005e3c:	ffffb097          	auipc	ra,0xffffb
    80005e40:	7d0080e7          	jalr	2000(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80005e44:	7bfd                	lui	s7,0xfffff
    80005e46:	9be6                	add	s7,s7,s9
  for(argc = 0; argv[argc]; argc++) {
    80005e48:	de043783          	ld	a5,-544(s0)
    80005e4c:	6388                	ld	a0,0(a5)
    80005e4e:	c925                	beqz	a0,80005ebe <exec+0x28e>
    80005e50:	e8840993          	addi	s3,s0,-376
    80005e54:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005e58:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005e5a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005e5c:	ffffb097          	auipc	ra,0xffffb
    80005e60:	fe6080e7          	jalr	-26(ra) # 80000e42 <strlen>
    80005e64:	0015079b          	addiw	a5,a0,1
    80005e68:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005e6c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005e70:	15796863          	bltu	s2,s7,80005fc0 <exec+0x390>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005e74:	de043d83          	ld	s11,-544(s0)
    80005e78:	000dba83          	ld	s5,0(s11) # 1000 <_entry-0x7ffff000>
    80005e7c:	8556                	mv	a0,s5
    80005e7e:	ffffb097          	auipc	ra,0xffffb
    80005e82:	fc4080e7          	jalr	-60(ra) # 80000e42 <strlen>
    80005e86:	0015069b          	addiw	a3,a0,1
    80005e8a:	8656                	mv	a2,s5
    80005e8c:	85ca                	mv	a1,s2
    80005e8e:	855a                	mv	a0,s6
    80005e90:	ffffb097          	auipc	ra,0xffffb
    80005e94:	7ae080e7          	jalr	1966(ra) # 8000163e <copyout>
    80005e98:	12054863          	bltz	a0,80005fc8 <exec+0x398>
    ustack[argc] = sp;
    80005e9c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005ea0:	0485                	addi	s1,s1,1
    80005ea2:	008d8793          	addi	a5,s11,8
    80005ea6:	def43023          	sd	a5,-544(s0)
    80005eaa:	008db503          	ld	a0,8(s11)
    80005eae:	c911                	beqz	a0,80005ec2 <exec+0x292>
    if(argc >= MAXARG)
    80005eb0:	09a1                	addi	s3,s3,8
    80005eb2:	fb3c15e3          	bne	s8,s3,80005e5c <exec+0x22c>
  sz = sz1;
    80005eb6:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005eba:	4a81                	li	s5,0
    80005ebc:	a8f1                	j	80005f98 <exec+0x368>
  sp = sz;
    80005ebe:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005ec0:	4481                	li	s1,0
  ustack[argc] = 0;
    80005ec2:	00349793          	slli	a5,s1,0x3
    80005ec6:	f9040713          	addi	a4,s0,-112
    80005eca:	97ba                	add	a5,a5,a4
    80005ecc:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffbaef8>
  sp -= (argc+1) * sizeof(uint64);
    80005ed0:	00148693          	addi	a3,s1,1
    80005ed4:	068e                	slli	a3,a3,0x3
    80005ed6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005eda:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005ede:	01797663          	bgeu	s2,s7,80005eea <exec+0x2ba>
  sz = sz1;
    80005ee2:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005ee6:	4a81                	li	s5,0
    80005ee8:	a845                	j	80005f98 <exec+0x368>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005eea:	e8840613          	addi	a2,s0,-376
    80005eee:	85ca                	mv	a1,s2
    80005ef0:	855a                	mv	a0,s6
    80005ef2:	ffffb097          	auipc	ra,0xffffb
    80005ef6:	74c080e7          	jalr	1868(ra) # 8000163e <copyout>
    80005efa:	0c054b63          	bltz	a0,80005fd0 <exec+0x3a0>
  t->trapframe->a1 = sp;
    80005efe:	e0843783          	ld	a5,-504(s0)
    80005f02:	67bc                	ld	a5,72(a5)
    80005f04:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005f08:	df043783          	ld	a5,-528(s0)
    80005f0c:	0007c703          	lbu	a4,0(a5)
    80005f10:	cf11                	beqz	a4,80005f2c <exec+0x2fc>
    80005f12:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005f14:	02f00693          	li	a3,47
    80005f18:	a039                	j	80005f26 <exec+0x2f6>
      last = s+1;
    80005f1a:	def43823          	sd	a5,-528(s0)
  for(last=s=path; *s; s++)
    80005f1e:	0785                	addi	a5,a5,1
    80005f20:	fff7c703          	lbu	a4,-1(a5)
    80005f24:	c701                	beqz	a4,80005f2c <exec+0x2fc>
    if(*s == '/')
    80005f26:	fed71ce3          	bne	a4,a3,80005f1e <exec+0x2ee>
    80005f2a:	bfc5                	j	80005f1a <exec+0x2ea>
  safestrcpy(p->name, last, sizeof(p->name));
    80005f2c:	4641                	li	a2,16
    80005f2e:	df043583          	ld	a1,-528(s0)
    80005f32:	268a0513          	addi	a0,s4,616
    80005f36:	ffffb097          	auipc	ra,0xffffb
    80005f3a:	eda080e7          	jalr	-294(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005f3e:	1d8a3503          	ld	a0,472(s4)
  p->pagetable = pagetable;
    80005f42:	1d6a3c23          	sd	s6,472(s4)
  p->sz = sz;
    80005f46:	1d9a3823          	sd	s9,464(s4)
  t->trapframe->epc = elf.entry;  // initial program counter = main
    80005f4a:	e0843683          	ld	a3,-504(s0)
    80005f4e:	66bc                	ld	a5,72(a3)
    80005f50:	e6043703          	ld	a4,-416(s0)
    80005f54:	ef98                	sd	a4,24(a5)
  t->trapframe->sp = sp; // initial stack pointer
    80005f56:	66bc                	ld	a5,72(a3)
    80005f58:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005f5c:	85ea                	mv	a1,s10
    80005f5e:	ffffc097          	auipc	ra,0xffffc
    80005f62:	dba080e7          	jalr	-582(ra) # 80001d18 <proc_freepagetable>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005f66:	138a0793          	addi	a5,s4,312
    80005f6a:	038a0a13          	addi	s4,s4,56
    80005f6e:	863e                	mv	a2,a5
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005f70:	4685                	li	a3,1
    80005f72:	a029                	j	80005f7c <exec+0x34c>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005f74:	0791                	addi	a5,a5,4
    80005f76:	0a21                	addi	s4,s4,8
    80005f78:	00ca0b63          	beq	s4,a2,80005f8e <exec+0x35e>
    p->signal_handlers_masks[signum] = 0;
    80005f7c:	0007a023          	sw	zero,0(a5)
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005f80:	000a3703          	ld	a4,0(s4)
    80005f84:	fed708e3          	beq	a4,a3,80005f74 <exec+0x344>
      p->signal_handlers[signum] = SIG_DFL;
    80005f88:	000a3023          	sd	zero,0(s4)
    80005f8c:	b7e5                	j	80005f74 <exec+0x344>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005f8e:	0004851b          	sext.w	a0,s1
    80005f92:	b34d                	j	80005d34 <exec+0x104>
    80005f94:	de943423          	sd	s1,-536(s0)
    proc_freepagetable(pagetable, sz);
    80005f98:	de843583          	ld	a1,-536(s0)
    80005f9c:	855a                	mv	a0,s6
    80005f9e:	ffffc097          	auipc	ra,0xffffc
    80005fa2:	d7a080e7          	jalr	-646(ra) # 80001d18 <proc_freepagetable>
  if(ip){
    80005fa6:	d60a9de3          	bnez	s5,80005d20 <exec+0xf0>
  return -1;
    80005faa:	557d                	li	a0,-1
    80005fac:	b361                	j	80005d34 <exec+0x104>
    80005fae:	de943423          	sd	s1,-536(s0)
    80005fb2:	b7dd                	j	80005f98 <exec+0x368>
    80005fb4:	de943423          	sd	s1,-536(s0)
    80005fb8:	b7c5                	j	80005f98 <exec+0x368>
    80005fba:	de943423          	sd	s1,-536(s0)
    80005fbe:	bfe9                	j	80005f98 <exec+0x368>
  sz = sz1;
    80005fc0:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005fc4:	4a81                	li	s5,0
    80005fc6:	bfc9                	j	80005f98 <exec+0x368>
  sz = sz1;
    80005fc8:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005fcc:	4a81                	li	s5,0
    80005fce:	b7e9                	j	80005f98 <exec+0x368>
  sz = sz1;
    80005fd0:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005fd4:	4a81                	li	s5,0
    80005fd6:	b7c9                	j	80005f98 <exec+0x368>
    sz = sz1;
    80005fd8:	de843483          	ld	s1,-536(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005fdc:	e0043783          	ld	a5,-512(s0)
    80005fe0:	0017869b          	addiw	a3,a5,1
    80005fe4:	e0d43023          	sd	a3,-512(s0)
    80005fe8:	df843783          	ld	a5,-520(s0)
    80005fec:	0387879b          	addiw	a5,a5,56
    80005ff0:	e8045703          	lhu	a4,-384(s0)
    80005ff4:	dee6dee3          	bge	a3,a4,80005df0 <exec+0x1c0>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005ff8:	2781                	sext.w	a5,a5
    80005ffa:	def43c23          	sd	a5,-520(s0)
    80005ffe:	03800713          	li	a4,56
    80006002:	86be                	mv	a3,a5
    80006004:	e1040613          	addi	a2,s0,-496
    80006008:	4581                	li	a1,0
    8000600a:	8556                	mv	a0,s5
    8000600c:	fffff097          	auipc	ra,0xfffff
    80006010:	9e4080e7          	jalr	-1564(ra) # 800049f0 <readi>
    80006014:	03800793          	li	a5,56
    80006018:	f6f51ee3          	bne	a0,a5,80005f94 <exec+0x364>
    if(ph.type != ELF_PROG_LOAD)
    8000601c:	e1042783          	lw	a5,-496(s0)
    80006020:	4705                	li	a4,1
    80006022:	fae79de3          	bne	a5,a4,80005fdc <exec+0x3ac>
    if(ph.memsz < ph.filesz)
    80006026:	e3843603          	ld	a2,-456(s0)
    8000602a:	e3043783          	ld	a5,-464(s0)
    8000602e:	f8f660e3          	bltu	a2,a5,80005fae <exec+0x37e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80006032:	e2043783          	ld	a5,-480(s0)
    80006036:	963e                	add	a2,a2,a5
    80006038:	f6f66ee3          	bltu	a2,a5,80005fb4 <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000603c:	85a6                	mv	a1,s1
    8000603e:	855a                	mv	a0,s6
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	3ae080e7          	jalr	942(ra) # 800013ee <uvmalloc>
    80006048:	dea43423          	sd	a0,-536(s0)
    8000604c:	d53d                	beqz	a0,80005fba <exec+0x38a>
    if(ph.vaddr % PGSIZE != 0)
    8000604e:	e2043c03          	ld	s8,-480(s0)
    80006052:	dd843783          	ld	a5,-552(s0)
    80006056:	00fc77b3          	and	a5,s8,a5
    8000605a:	ff9d                	bnez	a5,80005f98 <exec+0x368>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000605c:	e1842c83          	lw	s9,-488(s0)
    80006060:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80006064:	f60b8ae3          	beqz	s7,80005fd8 <exec+0x3a8>
    80006068:	89de                	mv	s3,s7
    8000606a:	4481                	li	s1,0
    8000606c:	b38d                	j	80005dce <exec+0x19e>

000000008000606e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000606e:	7179                	addi	sp,sp,-48
    80006070:	f406                	sd	ra,40(sp)
    80006072:	f022                	sd	s0,32(sp)
    80006074:	ec26                	sd	s1,24(sp)
    80006076:	e84a                	sd	s2,16(sp)
    80006078:	1800                	addi	s0,sp,48
    8000607a:	892e                	mv	s2,a1
    8000607c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000607e:	fdc40593          	addi	a1,s0,-36
    80006082:	ffffe097          	auipc	ra,0xffffe
    80006086:	8e2080e7          	jalr	-1822(ra) # 80003964 <argint>
    8000608a:	04054063          	bltz	a0,800060ca <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000608e:	fdc42703          	lw	a4,-36(s0)
    80006092:	47bd                	li	a5,15
    80006094:	02e7ed63          	bltu	a5,a4,800060ce <argfd+0x60>
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	9be080e7          	jalr	-1602(ra) # 80001a56 <myproc>
    800060a0:	fdc42703          	lw	a4,-36(s0)
    800060a4:	03c70793          	addi	a5,a4,60
    800060a8:	078e                	slli	a5,a5,0x3
    800060aa:	953e                	add	a0,a0,a5
    800060ac:	611c                	ld	a5,0(a0)
    800060ae:	c395                	beqz	a5,800060d2 <argfd+0x64>
    return -1;
  if(pfd)
    800060b0:	00090463          	beqz	s2,800060b8 <argfd+0x4a>
    *pfd = fd;
    800060b4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800060b8:	4501                	li	a0,0
  if(pf)
    800060ba:	c091                	beqz	s1,800060be <argfd+0x50>
    *pf = f;
    800060bc:	e09c                	sd	a5,0(s1)
}
    800060be:	70a2                	ld	ra,40(sp)
    800060c0:	7402                	ld	s0,32(sp)
    800060c2:	64e2                	ld	s1,24(sp)
    800060c4:	6942                	ld	s2,16(sp)
    800060c6:	6145                	addi	sp,sp,48
    800060c8:	8082                	ret
    return -1;
    800060ca:	557d                	li	a0,-1
    800060cc:	bfcd                	j	800060be <argfd+0x50>
    return -1;
    800060ce:	557d                	li	a0,-1
    800060d0:	b7fd                	j	800060be <argfd+0x50>
    800060d2:	557d                	li	a0,-1
    800060d4:	b7ed                	j	800060be <argfd+0x50>

00000000800060d6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800060d6:	1101                	addi	sp,sp,-32
    800060d8:	ec06                	sd	ra,24(sp)
    800060da:	e822                	sd	s0,16(sp)
    800060dc:	e426                	sd	s1,8(sp)
    800060de:	1000                	addi	s0,sp,32
    800060e0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800060e2:	ffffc097          	auipc	ra,0xffffc
    800060e6:	974080e7          	jalr	-1676(ra) # 80001a56 <myproc>
    800060ea:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800060ec:	1e050793          	addi	a5,a0,480
    800060f0:	4501                	li	a0,0
    800060f2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800060f4:	6398                	ld	a4,0(a5)
    800060f6:	cb19                	beqz	a4,8000610c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800060f8:	2505                	addiw	a0,a0,1
    800060fa:	07a1                	addi	a5,a5,8
    800060fc:	fed51ce3          	bne	a0,a3,800060f4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80006100:	557d                	li	a0,-1
}
    80006102:	60e2                	ld	ra,24(sp)
    80006104:	6442                	ld	s0,16(sp)
    80006106:	64a2                	ld	s1,8(sp)
    80006108:	6105                	addi	sp,sp,32
    8000610a:	8082                	ret
      p->ofile[fd] = f;
    8000610c:	03c50793          	addi	a5,a0,60
    80006110:	078e                	slli	a5,a5,0x3
    80006112:	963e                	add	a2,a2,a5
    80006114:	e204                	sd	s1,0(a2)
      return fd;
    80006116:	b7f5                	j	80006102 <fdalloc+0x2c>

0000000080006118 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80006118:	715d                	addi	sp,sp,-80
    8000611a:	e486                	sd	ra,72(sp)
    8000611c:	e0a2                	sd	s0,64(sp)
    8000611e:	fc26                	sd	s1,56(sp)
    80006120:	f84a                	sd	s2,48(sp)
    80006122:	f44e                	sd	s3,40(sp)
    80006124:	f052                	sd	s4,32(sp)
    80006126:	ec56                	sd	s5,24(sp)
    80006128:	0880                	addi	s0,sp,80
    8000612a:	89ae                	mv	s3,a1
    8000612c:	8ab2                	mv	s5,a2
    8000612e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006130:	fb040593          	addi	a1,s0,-80
    80006134:	fffff097          	auipc	ra,0xfffff
    80006138:	ddc080e7          	jalr	-548(ra) # 80004f10 <nameiparent>
    8000613c:	892a                	mv	s2,a0
    8000613e:	12050e63          	beqz	a0,8000627a <create+0x162>
    return 0;

  ilock(dp);
    80006142:	ffffe097          	auipc	ra,0xffffe
    80006146:	5fa080e7          	jalr	1530(ra) # 8000473c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000614a:	4601                	li	a2,0
    8000614c:	fb040593          	addi	a1,s0,-80
    80006150:	854a                	mv	a0,s2
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	ace080e7          	jalr	-1330(ra) # 80004c20 <dirlookup>
    8000615a:	84aa                	mv	s1,a0
    8000615c:	c921                	beqz	a0,800061ac <create+0x94>
    iunlockput(dp);
    8000615e:	854a                	mv	a0,s2
    80006160:	fffff097          	auipc	ra,0xfffff
    80006164:	83e080e7          	jalr	-1986(ra) # 8000499e <iunlockput>
    ilock(ip);
    80006168:	8526                	mv	a0,s1
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	5d2080e7          	jalr	1490(ra) # 8000473c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006172:	2981                	sext.w	s3,s3
    80006174:	4789                	li	a5,2
    80006176:	02f99463          	bne	s3,a5,8000619e <create+0x86>
    8000617a:	0444d783          	lhu	a5,68(s1)
    8000617e:	37f9                	addiw	a5,a5,-2
    80006180:	17c2                	slli	a5,a5,0x30
    80006182:	93c1                	srli	a5,a5,0x30
    80006184:	4705                	li	a4,1
    80006186:	00f76c63          	bltu	a4,a5,8000619e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000618a:	8526                	mv	a0,s1
    8000618c:	60a6                	ld	ra,72(sp)
    8000618e:	6406                	ld	s0,64(sp)
    80006190:	74e2                	ld	s1,56(sp)
    80006192:	7942                	ld	s2,48(sp)
    80006194:	79a2                	ld	s3,40(sp)
    80006196:	7a02                	ld	s4,32(sp)
    80006198:	6ae2                	ld	s5,24(sp)
    8000619a:	6161                	addi	sp,sp,80
    8000619c:	8082                	ret
    iunlockput(ip);
    8000619e:	8526                	mv	a0,s1
    800061a0:	ffffe097          	auipc	ra,0xffffe
    800061a4:	7fe080e7          	jalr	2046(ra) # 8000499e <iunlockput>
    return 0;
    800061a8:	4481                	li	s1,0
    800061aa:	b7c5                	j	8000618a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800061ac:	85ce                	mv	a1,s3
    800061ae:	00092503          	lw	a0,0(s2)
    800061b2:	ffffe097          	auipc	ra,0xffffe
    800061b6:	3f2080e7          	jalr	1010(ra) # 800045a4 <ialloc>
    800061ba:	84aa                	mv	s1,a0
    800061bc:	c521                	beqz	a0,80006204 <create+0xec>
  ilock(ip);
    800061be:	ffffe097          	auipc	ra,0xffffe
    800061c2:	57e080e7          	jalr	1406(ra) # 8000473c <ilock>
  ip->major = major;
    800061c6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800061ca:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800061ce:	4a05                	li	s4,1
    800061d0:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800061d4:	8526                	mv	a0,s1
    800061d6:	ffffe097          	auipc	ra,0xffffe
    800061da:	49c080e7          	jalr	1180(ra) # 80004672 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800061de:	2981                	sext.w	s3,s3
    800061e0:	03498a63          	beq	s3,s4,80006214 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800061e4:	40d0                	lw	a2,4(s1)
    800061e6:	fb040593          	addi	a1,s0,-80
    800061ea:	854a                	mv	a0,s2
    800061ec:	fffff097          	auipc	ra,0xfffff
    800061f0:	c44080e7          	jalr	-956(ra) # 80004e30 <dirlink>
    800061f4:	06054b63          	bltz	a0,8000626a <create+0x152>
  iunlockput(dp);
    800061f8:	854a                	mv	a0,s2
    800061fa:	ffffe097          	auipc	ra,0xffffe
    800061fe:	7a4080e7          	jalr	1956(ra) # 8000499e <iunlockput>
  return ip;
    80006202:	b761                	j	8000618a <create+0x72>
    panic("create: ialloc");
    80006204:	00003517          	auipc	a0,0x3
    80006208:	52c50513          	addi	a0,a0,1324 # 80009730 <syscalls+0x2f8>
    8000620c:	ffffa097          	auipc	ra,0xffffa
    80006210:	31e080e7          	jalr	798(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80006214:	04a95783          	lhu	a5,74(s2)
    80006218:	2785                	addiw	a5,a5,1
    8000621a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000621e:	854a                	mv	a0,s2
    80006220:	ffffe097          	auipc	ra,0xffffe
    80006224:	452080e7          	jalr	1106(ra) # 80004672 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006228:	40d0                	lw	a2,4(s1)
    8000622a:	00003597          	auipc	a1,0x3
    8000622e:	51658593          	addi	a1,a1,1302 # 80009740 <syscalls+0x308>
    80006232:	8526                	mv	a0,s1
    80006234:	fffff097          	auipc	ra,0xfffff
    80006238:	bfc080e7          	jalr	-1028(ra) # 80004e30 <dirlink>
    8000623c:	00054f63          	bltz	a0,8000625a <create+0x142>
    80006240:	00492603          	lw	a2,4(s2)
    80006244:	00003597          	auipc	a1,0x3
    80006248:	50458593          	addi	a1,a1,1284 # 80009748 <syscalls+0x310>
    8000624c:	8526                	mv	a0,s1
    8000624e:	fffff097          	auipc	ra,0xfffff
    80006252:	be2080e7          	jalr	-1054(ra) # 80004e30 <dirlink>
    80006256:	f80557e3          	bgez	a0,800061e4 <create+0xcc>
      panic("create dots");
    8000625a:	00003517          	auipc	a0,0x3
    8000625e:	4f650513          	addi	a0,a0,1270 # 80009750 <syscalls+0x318>
    80006262:	ffffa097          	auipc	ra,0xffffa
    80006266:	2c8080e7          	jalr	712(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000626a:	00003517          	auipc	a0,0x3
    8000626e:	4f650513          	addi	a0,a0,1270 # 80009760 <syscalls+0x328>
    80006272:	ffffa097          	auipc	ra,0xffffa
    80006276:	2b8080e7          	jalr	696(ra) # 8000052a <panic>
    return 0;
    8000627a:	84aa                	mv	s1,a0
    8000627c:	b739                	j	8000618a <create+0x72>

000000008000627e <sys_dup>:
{
    8000627e:	7179                	addi	sp,sp,-48
    80006280:	f406                	sd	ra,40(sp)
    80006282:	f022                	sd	s0,32(sp)
    80006284:	ec26                	sd	s1,24(sp)
    80006286:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80006288:	fd840613          	addi	a2,s0,-40
    8000628c:	4581                	li	a1,0
    8000628e:	4501                	li	a0,0
    80006290:	00000097          	auipc	ra,0x0
    80006294:	dde080e7          	jalr	-546(ra) # 8000606e <argfd>
    return -1;
    80006298:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000629a:	02054363          	bltz	a0,800062c0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000629e:	fd843503          	ld	a0,-40(s0)
    800062a2:	00000097          	auipc	ra,0x0
    800062a6:	e34080e7          	jalr	-460(ra) # 800060d6 <fdalloc>
    800062aa:	84aa                	mv	s1,a0
    return -1;
    800062ac:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800062ae:	00054963          	bltz	a0,800062c0 <sys_dup+0x42>
  filedup(f);
    800062b2:	fd843503          	ld	a0,-40(s0)
    800062b6:	fffff097          	auipc	ra,0xfffff
    800062ba:	2d6080e7          	jalr	726(ra) # 8000558c <filedup>
  return fd;
    800062be:	87a6                	mv	a5,s1
}
    800062c0:	853e                	mv	a0,a5
    800062c2:	70a2                	ld	ra,40(sp)
    800062c4:	7402                	ld	s0,32(sp)
    800062c6:	64e2                	ld	s1,24(sp)
    800062c8:	6145                	addi	sp,sp,48
    800062ca:	8082                	ret

00000000800062cc <sys_read>:
{
    800062cc:	7179                	addi	sp,sp,-48
    800062ce:	f406                	sd	ra,40(sp)
    800062d0:	f022                	sd	s0,32(sp)
    800062d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800062d4:	fe840613          	addi	a2,s0,-24
    800062d8:	4581                	li	a1,0
    800062da:	4501                	li	a0,0
    800062dc:	00000097          	auipc	ra,0x0
    800062e0:	d92080e7          	jalr	-622(ra) # 8000606e <argfd>
    return -1;
    800062e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800062e6:	04054163          	bltz	a0,80006328 <sys_read+0x5c>
    800062ea:	fe440593          	addi	a1,s0,-28
    800062ee:	4509                	li	a0,2
    800062f0:	ffffd097          	auipc	ra,0xffffd
    800062f4:	674080e7          	jalr	1652(ra) # 80003964 <argint>
    return -1;
    800062f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800062fa:	02054763          	bltz	a0,80006328 <sys_read+0x5c>
    800062fe:	fd840593          	addi	a1,s0,-40
    80006302:	4505                	li	a0,1
    80006304:	ffffd097          	auipc	ra,0xffffd
    80006308:	682080e7          	jalr	1666(ra) # 80003986 <argaddr>
    return -1;
    8000630c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000630e:	00054d63          	bltz	a0,80006328 <sys_read+0x5c>
  return fileread(f, p, n);
    80006312:	fe442603          	lw	a2,-28(s0)
    80006316:	fd843583          	ld	a1,-40(s0)
    8000631a:	fe843503          	ld	a0,-24(s0)
    8000631e:	fffff097          	auipc	ra,0xfffff
    80006322:	3fa080e7          	jalr	1018(ra) # 80005718 <fileread>
    80006326:	87aa                	mv	a5,a0
}
    80006328:	853e                	mv	a0,a5
    8000632a:	70a2                	ld	ra,40(sp)
    8000632c:	7402                	ld	s0,32(sp)
    8000632e:	6145                	addi	sp,sp,48
    80006330:	8082                	ret

0000000080006332 <sys_write>:
{
    80006332:	7179                	addi	sp,sp,-48
    80006334:	f406                	sd	ra,40(sp)
    80006336:	f022                	sd	s0,32(sp)
    80006338:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000633a:	fe840613          	addi	a2,s0,-24
    8000633e:	4581                	li	a1,0
    80006340:	4501                	li	a0,0
    80006342:	00000097          	auipc	ra,0x0
    80006346:	d2c080e7          	jalr	-724(ra) # 8000606e <argfd>
    return -1;
    8000634a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000634c:	04054163          	bltz	a0,8000638e <sys_write+0x5c>
    80006350:	fe440593          	addi	a1,s0,-28
    80006354:	4509                	li	a0,2
    80006356:	ffffd097          	auipc	ra,0xffffd
    8000635a:	60e080e7          	jalr	1550(ra) # 80003964 <argint>
    return -1;
    8000635e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006360:	02054763          	bltz	a0,8000638e <sys_write+0x5c>
    80006364:	fd840593          	addi	a1,s0,-40
    80006368:	4505                	li	a0,1
    8000636a:	ffffd097          	auipc	ra,0xffffd
    8000636e:	61c080e7          	jalr	1564(ra) # 80003986 <argaddr>
    return -1;
    80006372:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006374:	00054d63          	bltz	a0,8000638e <sys_write+0x5c>
  return filewrite(f, p, n);
    80006378:	fe442603          	lw	a2,-28(s0)
    8000637c:	fd843583          	ld	a1,-40(s0)
    80006380:	fe843503          	ld	a0,-24(s0)
    80006384:	fffff097          	auipc	ra,0xfffff
    80006388:	456080e7          	jalr	1110(ra) # 800057da <filewrite>
    8000638c:	87aa                	mv	a5,a0
}
    8000638e:	853e                	mv	a0,a5
    80006390:	70a2                	ld	ra,40(sp)
    80006392:	7402                	ld	s0,32(sp)
    80006394:	6145                	addi	sp,sp,48
    80006396:	8082                	ret

0000000080006398 <sys_close>:
{
    80006398:	1101                	addi	sp,sp,-32
    8000639a:	ec06                	sd	ra,24(sp)
    8000639c:	e822                	sd	s0,16(sp)
    8000639e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800063a0:	fe040613          	addi	a2,s0,-32
    800063a4:	fec40593          	addi	a1,s0,-20
    800063a8:	4501                	li	a0,0
    800063aa:	00000097          	auipc	ra,0x0
    800063ae:	cc4080e7          	jalr	-828(ra) # 8000606e <argfd>
    return -1;
    800063b2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800063b4:	02054563          	bltz	a0,800063de <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    800063b8:	ffffb097          	auipc	ra,0xffffb
    800063bc:	69e080e7          	jalr	1694(ra) # 80001a56 <myproc>
    800063c0:	fec42783          	lw	a5,-20(s0)
    800063c4:	03c78793          	addi	a5,a5,60
    800063c8:	078e                	slli	a5,a5,0x3
    800063ca:	97aa                	add	a5,a5,a0
    800063cc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800063d0:	fe043503          	ld	a0,-32(s0)
    800063d4:	fffff097          	auipc	ra,0xfffff
    800063d8:	20a080e7          	jalr	522(ra) # 800055de <fileclose>
  return 0;
    800063dc:	4781                	li	a5,0
}
    800063de:	853e                	mv	a0,a5
    800063e0:	60e2                	ld	ra,24(sp)
    800063e2:	6442                	ld	s0,16(sp)
    800063e4:	6105                	addi	sp,sp,32
    800063e6:	8082                	ret

00000000800063e8 <sys_fstat>:
{
    800063e8:	1101                	addi	sp,sp,-32
    800063ea:	ec06                	sd	ra,24(sp)
    800063ec:	e822                	sd	s0,16(sp)
    800063ee:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800063f0:	fe840613          	addi	a2,s0,-24
    800063f4:	4581                	li	a1,0
    800063f6:	4501                	li	a0,0
    800063f8:	00000097          	auipc	ra,0x0
    800063fc:	c76080e7          	jalr	-906(ra) # 8000606e <argfd>
    return -1;
    80006400:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006402:	02054563          	bltz	a0,8000642c <sys_fstat+0x44>
    80006406:	fe040593          	addi	a1,s0,-32
    8000640a:	4505                	li	a0,1
    8000640c:	ffffd097          	auipc	ra,0xffffd
    80006410:	57a080e7          	jalr	1402(ra) # 80003986 <argaddr>
    return -1;
    80006414:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006416:	00054b63          	bltz	a0,8000642c <sys_fstat+0x44>
  return filestat(f, st);
    8000641a:	fe043583          	ld	a1,-32(s0)
    8000641e:	fe843503          	ld	a0,-24(s0)
    80006422:	fffff097          	auipc	ra,0xfffff
    80006426:	284080e7          	jalr	644(ra) # 800056a6 <filestat>
    8000642a:	87aa                	mv	a5,a0
}
    8000642c:	853e                	mv	a0,a5
    8000642e:	60e2                	ld	ra,24(sp)
    80006430:	6442                	ld	s0,16(sp)
    80006432:	6105                	addi	sp,sp,32
    80006434:	8082                	ret

0000000080006436 <sys_link>:
{
    80006436:	7169                	addi	sp,sp,-304
    80006438:	f606                	sd	ra,296(sp)
    8000643a:	f222                	sd	s0,288(sp)
    8000643c:	ee26                	sd	s1,280(sp)
    8000643e:	ea4a                	sd	s2,272(sp)
    80006440:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006442:	08000613          	li	a2,128
    80006446:	ed040593          	addi	a1,s0,-304
    8000644a:	4501                	li	a0,0
    8000644c:	ffffd097          	auipc	ra,0xffffd
    80006450:	55c080e7          	jalr	1372(ra) # 800039a8 <argstr>
    return -1;
    80006454:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006456:	10054e63          	bltz	a0,80006572 <sys_link+0x13c>
    8000645a:	08000613          	li	a2,128
    8000645e:	f5040593          	addi	a1,s0,-176
    80006462:	4505                	li	a0,1
    80006464:	ffffd097          	auipc	ra,0xffffd
    80006468:	544080e7          	jalr	1348(ra) # 800039a8 <argstr>
    return -1;
    8000646c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000646e:	10054263          	bltz	a0,80006572 <sys_link+0x13c>
  begin_op();
    80006472:	fffff097          	auipc	ra,0xfffff
    80006476:	ca0080e7          	jalr	-864(ra) # 80005112 <begin_op>
  if((ip = namei(old)) == 0){
    8000647a:	ed040513          	addi	a0,s0,-304
    8000647e:	fffff097          	auipc	ra,0xfffff
    80006482:	a74080e7          	jalr	-1420(ra) # 80004ef2 <namei>
    80006486:	84aa                	mv	s1,a0
    80006488:	c551                	beqz	a0,80006514 <sys_link+0xde>
  ilock(ip);
    8000648a:	ffffe097          	auipc	ra,0xffffe
    8000648e:	2b2080e7          	jalr	690(ra) # 8000473c <ilock>
  if(ip->type == T_DIR){
    80006492:	04449703          	lh	a4,68(s1)
    80006496:	4785                	li	a5,1
    80006498:	08f70463          	beq	a4,a5,80006520 <sys_link+0xea>
  ip->nlink++;
    8000649c:	04a4d783          	lhu	a5,74(s1)
    800064a0:	2785                	addiw	a5,a5,1
    800064a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800064a6:	8526                	mv	a0,s1
    800064a8:	ffffe097          	auipc	ra,0xffffe
    800064ac:	1ca080e7          	jalr	458(ra) # 80004672 <iupdate>
  iunlock(ip);
    800064b0:	8526                	mv	a0,s1
    800064b2:	ffffe097          	auipc	ra,0xffffe
    800064b6:	34c080e7          	jalr	844(ra) # 800047fe <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800064ba:	fd040593          	addi	a1,s0,-48
    800064be:	f5040513          	addi	a0,s0,-176
    800064c2:	fffff097          	auipc	ra,0xfffff
    800064c6:	a4e080e7          	jalr	-1458(ra) # 80004f10 <nameiparent>
    800064ca:	892a                	mv	s2,a0
    800064cc:	c935                	beqz	a0,80006540 <sys_link+0x10a>
  ilock(dp);
    800064ce:	ffffe097          	auipc	ra,0xffffe
    800064d2:	26e080e7          	jalr	622(ra) # 8000473c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800064d6:	00092703          	lw	a4,0(s2)
    800064da:	409c                	lw	a5,0(s1)
    800064dc:	04f71d63          	bne	a4,a5,80006536 <sys_link+0x100>
    800064e0:	40d0                	lw	a2,4(s1)
    800064e2:	fd040593          	addi	a1,s0,-48
    800064e6:	854a                	mv	a0,s2
    800064e8:	fffff097          	auipc	ra,0xfffff
    800064ec:	948080e7          	jalr	-1720(ra) # 80004e30 <dirlink>
    800064f0:	04054363          	bltz	a0,80006536 <sys_link+0x100>
  iunlockput(dp);
    800064f4:	854a                	mv	a0,s2
    800064f6:	ffffe097          	auipc	ra,0xffffe
    800064fa:	4a8080e7          	jalr	1192(ra) # 8000499e <iunlockput>
  iput(ip);
    800064fe:	8526                	mv	a0,s1
    80006500:	ffffe097          	auipc	ra,0xffffe
    80006504:	3f6080e7          	jalr	1014(ra) # 800048f6 <iput>
  end_op();
    80006508:	fffff097          	auipc	ra,0xfffff
    8000650c:	c8a080e7          	jalr	-886(ra) # 80005192 <end_op>
  return 0;
    80006510:	4781                	li	a5,0
    80006512:	a085                	j	80006572 <sys_link+0x13c>
    end_op();
    80006514:	fffff097          	auipc	ra,0xfffff
    80006518:	c7e080e7          	jalr	-898(ra) # 80005192 <end_op>
    return -1;
    8000651c:	57fd                	li	a5,-1
    8000651e:	a891                	j	80006572 <sys_link+0x13c>
    iunlockput(ip);
    80006520:	8526                	mv	a0,s1
    80006522:	ffffe097          	auipc	ra,0xffffe
    80006526:	47c080e7          	jalr	1148(ra) # 8000499e <iunlockput>
    end_op();
    8000652a:	fffff097          	auipc	ra,0xfffff
    8000652e:	c68080e7          	jalr	-920(ra) # 80005192 <end_op>
    return -1;
    80006532:	57fd                	li	a5,-1
    80006534:	a83d                	j	80006572 <sys_link+0x13c>
    iunlockput(dp);
    80006536:	854a                	mv	a0,s2
    80006538:	ffffe097          	auipc	ra,0xffffe
    8000653c:	466080e7          	jalr	1126(ra) # 8000499e <iunlockput>
  ilock(ip);
    80006540:	8526                	mv	a0,s1
    80006542:	ffffe097          	auipc	ra,0xffffe
    80006546:	1fa080e7          	jalr	506(ra) # 8000473c <ilock>
  ip->nlink--;
    8000654a:	04a4d783          	lhu	a5,74(s1)
    8000654e:	37fd                	addiw	a5,a5,-1
    80006550:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006554:	8526                	mv	a0,s1
    80006556:	ffffe097          	auipc	ra,0xffffe
    8000655a:	11c080e7          	jalr	284(ra) # 80004672 <iupdate>
  iunlockput(ip);
    8000655e:	8526                	mv	a0,s1
    80006560:	ffffe097          	auipc	ra,0xffffe
    80006564:	43e080e7          	jalr	1086(ra) # 8000499e <iunlockput>
  end_op();
    80006568:	fffff097          	auipc	ra,0xfffff
    8000656c:	c2a080e7          	jalr	-982(ra) # 80005192 <end_op>
  return -1;
    80006570:	57fd                	li	a5,-1
}
    80006572:	853e                	mv	a0,a5
    80006574:	70b2                	ld	ra,296(sp)
    80006576:	7412                	ld	s0,288(sp)
    80006578:	64f2                	ld	s1,280(sp)
    8000657a:	6952                	ld	s2,272(sp)
    8000657c:	6155                	addi	sp,sp,304
    8000657e:	8082                	ret

0000000080006580 <sys_unlink>:
{
    80006580:	7151                	addi	sp,sp,-240
    80006582:	f586                	sd	ra,232(sp)
    80006584:	f1a2                	sd	s0,224(sp)
    80006586:	eda6                	sd	s1,216(sp)
    80006588:	e9ca                	sd	s2,208(sp)
    8000658a:	e5ce                	sd	s3,200(sp)
    8000658c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000658e:	08000613          	li	a2,128
    80006592:	f3040593          	addi	a1,s0,-208
    80006596:	4501                	li	a0,0
    80006598:	ffffd097          	auipc	ra,0xffffd
    8000659c:	410080e7          	jalr	1040(ra) # 800039a8 <argstr>
    800065a0:	18054163          	bltz	a0,80006722 <sys_unlink+0x1a2>
  begin_op();
    800065a4:	fffff097          	auipc	ra,0xfffff
    800065a8:	b6e080e7          	jalr	-1170(ra) # 80005112 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800065ac:	fb040593          	addi	a1,s0,-80
    800065b0:	f3040513          	addi	a0,s0,-208
    800065b4:	fffff097          	auipc	ra,0xfffff
    800065b8:	95c080e7          	jalr	-1700(ra) # 80004f10 <nameiparent>
    800065bc:	84aa                	mv	s1,a0
    800065be:	c979                	beqz	a0,80006694 <sys_unlink+0x114>
  ilock(dp);
    800065c0:	ffffe097          	auipc	ra,0xffffe
    800065c4:	17c080e7          	jalr	380(ra) # 8000473c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800065c8:	00003597          	auipc	a1,0x3
    800065cc:	17858593          	addi	a1,a1,376 # 80009740 <syscalls+0x308>
    800065d0:	fb040513          	addi	a0,s0,-80
    800065d4:	ffffe097          	auipc	ra,0xffffe
    800065d8:	632080e7          	jalr	1586(ra) # 80004c06 <namecmp>
    800065dc:	14050a63          	beqz	a0,80006730 <sys_unlink+0x1b0>
    800065e0:	00003597          	auipc	a1,0x3
    800065e4:	16858593          	addi	a1,a1,360 # 80009748 <syscalls+0x310>
    800065e8:	fb040513          	addi	a0,s0,-80
    800065ec:	ffffe097          	auipc	ra,0xffffe
    800065f0:	61a080e7          	jalr	1562(ra) # 80004c06 <namecmp>
    800065f4:	12050e63          	beqz	a0,80006730 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800065f8:	f2c40613          	addi	a2,s0,-212
    800065fc:	fb040593          	addi	a1,s0,-80
    80006600:	8526                	mv	a0,s1
    80006602:	ffffe097          	auipc	ra,0xffffe
    80006606:	61e080e7          	jalr	1566(ra) # 80004c20 <dirlookup>
    8000660a:	892a                	mv	s2,a0
    8000660c:	12050263          	beqz	a0,80006730 <sys_unlink+0x1b0>
  ilock(ip);
    80006610:	ffffe097          	auipc	ra,0xffffe
    80006614:	12c080e7          	jalr	300(ra) # 8000473c <ilock>
  if(ip->nlink < 1)
    80006618:	04a91783          	lh	a5,74(s2)
    8000661c:	08f05263          	blez	a5,800066a0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006620:	04491703          	lh	a4,68(s2)
    80006624:	4785                	li	a5,1
    80006626:	08f70563          	beq	a4,a5,800066b0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000662a:	4641                	li	a2,16
    8000662c:	4581                	li	a1,0
    8000662e:	fc040513          	addi	a0,s0,-64
    80006632:	ffffa097          	auipc	ra,0xffffa
    80006636:	68c080e7          	jalr	1676(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000663a:	4741                	li	a4,16
    8000663c:	f2c42683          	lw	a3,-212(s0)
    80006640:	fc040613          	addi	a2,s0,-64
    80006644:	4581                	li	a1,0
    80006646:	8526                	mv	a0,s1
    80006648:	ffffe097          	auipc	ra,0xffffe
    8000664c:	4a0080e7          	jalr	1184(ra) # 80004ae8 <writei>
    80006650:	47c1                	li	a5,16
    80006652:	0af51563          	bne	a0,a5,800066fc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006656:	04491703          	lh	a4,68(s2)
    8000665a:	4785                	li	a5,1
    8000665c:	0af70863          	beq	a4,a5,8000670c <sys_unlink+0x18c>
  iunlockput(dp);
    80006660:	8526                	mv	a0,s1
    80006662:	ffffe097          	auipc	ra,0xffffe
    80006666:	33c080e7          	jalr	828(ra) # 8000499e <iunlockput>
  ip->nlink--;
    8000666a:	04a95783          	lhu	a5,74(s2)
    8000666e:	37fd                	addiw	a5,a5,-1
    80006670:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006674:	854a                	mv	a0,s2
    80006676:	ffffe097          	auipc	ra,0xffffe
    8000667a:	ffc080e7          	jalr	-4(ra) # 80004672 <iupdate>
  iunlockput(ip);
    8000667e:	854a                	mv	a0,s2
    80006680:	ffffe097          	auipc	ra,0xffffe
    80006684:	31e080e7          	jalr	798(ra) # 8000499e <iunlockput>
  end_op();
    80006688:	fffff097          	auipc	ra,0xfffff
    8000668c:	b0a080e7          	jalr	-1270(ra) # 80005192 <end_op>
  return 0;
    80006690:	4501                	li	a0,0
    80006692:	a84d                	j	80006744 <sys_unlink+0x1c4>
    end_op();
    80006694:	fffff097          	auipc	ra,0xfffff
    80006698:	afe080e7          	jalr	-1282(ra) # 80005192 <end_op>
    return -1;
    8000669c:	557d                	li	a0,-1
    8000669e:	a05d                	j	80006744 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800066a0:	00003517          	auipc	a0,0x3
    800066a4:	0d050513          	addi	a0,a0,208 # 80009770 <syscalls+0x338>
    800066a8:	ffffa097          	auipc	ra,0xffffa
    800066ac:	e82080e7          	jalr	-382(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800066b0:	04c92703          	lw	a4,76(s2)
    800066b4:	02000793          	li	a5,32
    800066b8:	f6e7f9e3          	bgeu	a5,a4,8000662a <sys_unlink+0xaa>
    800066bc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800066c0:	4741                	li	a4,16
    800066c2:	86ce                	mv	a3,s3
    800066c4:	f1840613          	addi	a2,s0,-232
    800066c8:	4581                	li	a1,0
    800066ca:	854a                	mv	a0,s2
    800066cc:	ffffe097          	auipc	ra,0xffffe
    800066d0:	324080e7          	jalr	804(ra) # 800049f0 <readi>
    800066d4:	47c1                	li	a5,16
    800066d6:	00f51b63          	bne	a0,a5,800066ec <sys_unlink+0x16c>
    if(de.inum != 0)
    800066da:	f1845783          	lhu	a5,-232(s0)
    800066de:	e7a1                	bnez	a5,80006726 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800066e0:	29c1                	addiw	s3,s3,16
    800066e2:	04c92783          	lw	a5,76(s2)
    800066e6:	fcf9ede3          	bltu	s3,a5,800066c0 <sys_unlink+0x140>
    800066ea:	b781                	j	8000662a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800066ec:	00003517          	auipc	a0,0x3
    800066f0:	09c50513          	addi	a0,a0,156 # 80009788 <syscalls+0x350>
    800066f4:	ffffa097          	auipc	ra,0xffffa
    800066f8:	e36080e7          	jalr	-458(ra) # 8000052a <panic>
    panic("unlink: writei");
    800066fc:	00003517          	auipc	a0,0x3
    80006700:	0a450513          	addi	a0,a0,164 # 800097a0 <syscalls+0x368>
    80006704:	ffffa097          	auipc	ra,0xffffa
    80006708:	e26080e7          	jalr	-474(ra) # 8000052a <panic>
    dp->nlink--;
    8000670c:	04a4d783          	lhu	a5,74(s1)
    80006710:	37fd                	addiw	a5,a5,-1
    80006712:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006716:	8526                	mv	a0,s1
    80006718:	ffffe097          	auipc	ra,0xffffe
    8000671c:	f5a080e7          	jalr	-166(ra) # 80004672 <iupdate>
    80006720:	b781                	j	80006660 <sys_unlink+0xe0>
    return -1;
    80006722:	557d                	li	a0,-1
    80006724:	a005                	j	80006744 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006726:	854a                	mv	a0,s2
    80006728:	ffffe097          	auipc	ra,0xffffe
    8000672c:	276080e7          	jalr	630(ra) # 8000499e <iunlockput>
  iunlockput(dp);
    80006730:	8526                	mv	a0,s1
    80006732:	ffffe097          	auipc	ra,0xffffe
    80006736:	26c080e7          	jalr	620(ra) # 8000499e <iunlockput>
  end_op();
    8000673a:	fffff097          	auipc	ra,0xfffff
    8000673e:	a58080e7          	jalr	-1448(ra) # 80005192 <end_op>
  return -1;
    80006742:	557d                	li	a0,-1
}
    80006744:	70ae                	ld	ra,232(sp)
    80006746:	740e                	ld	s0,224(sp)
    80006748:	64ee                	ld	s1,216(sp)
    8000674a:	694e                	ld	s2,208(sp)
    8000674c:	69ae                	ld	s3,200(sp)
    8000674e:	616d                	addi	sp,sp,240
    80006750:	8082                	ret

0000000080006752 <sys_open>:

uint64
sys_open(void)
{
    80006752:	7131                	addi	sp,sp,-192
    80006754:	fd06                	sd	ra,184(sp)
    80006756:	f922                	sd	s0,176(sp)
    80006758:	f526                	sd	s1,168(sp)
    8000675a:	f14a                	sd	s2,160(sp)
    8000675c:	ed4e                	sd	s3,152(sp)
    8000675e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006760:	08000613          	li	a2,128
    80006764:	f5040593          	addi	a1,s0,-176
    80006768:	4501                	li	a0,0
    8000676a:	ffffd097          	auipc	ra,0xffffd
    8000676e:	23e080e7          	jalr	574(ra) # 800039a8 <argstr>
    return -1;
    80006772:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006774:	0c054163          	bltz	a0,80006836 <sys_open+0xe4>
    80006778:	f4c40593          	addi	a1,s0,-180
    8000677c:	4505                	li	a0,1
    8000677e:	ffffd097          	auipc	ra,0xffffd
    80006782:	1e6080e7          	jalr	486(ra) # 80003964 <argint>
    80006786:	0a054863          	bltz	a0,80006836 <sys_open+0xe4>

  begin_op();
    8000678a:	fffff097          	auipc	ra,0xfffff
    8000678e:	988080e7          	jalr	-1656(ra) # 80005112 <begin_op>

  if(omode & O_CREATE){
    80006792:	f4c42783          	lw	a5,-180(s0)
    80006796:	2007f793          	andi	a5,a5,512
    8000679a:	cbdd                	beqz	a5,80006850 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000679c:	4681                	li	a3,0
    8000679e:	4601                	li	a2,0
    800067a0:	4589                	li	a1,2
    800067a2:	f5040513          	addi	a0,s0,-176
    800067a6:	00000097          	auipc	ra,0x0
    800067aa:	972080e7          	jalr	-1678(ra) # 80006118 <create>
    800067ae:	892a                	mv	s2,a0
    if(ip == 0){
    800067b0:	c959                	beqz	a0,80006846 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800067b2:	04491703          	lh	a4,68(s2)
    800067b6:	478d                	li	a5,3
    800067b8:	00f71763          	bne	a4,a5,800067c6 <sys_open+0x74>
    800067bc:	04695703          	lhu	a4,70(s2)
    800067c0:	47a5                	li	a5,9
    800067c2:	0ce7ec63          	bltu	a5,a4,8000689a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800067c6:	fffff097          	auipc	ra,0xfffff
    800067ca:	d5c080e7          	jalr	-676(ra) # 80005522 <filealloc>
    800067ce:	89aa                	mv	s3,a0
    800067d0:	10050263          	beqz	a0,800068d4 <sys_open+0x182>
    800067d4:	00000097          	auipc	ra,0x0
    800067d8:	902080e7          	jalr	-1790(ra) # 800060d6 <fdalloc>
    800067dc:	84aa                	mv	s1,a0
    800067de:	0e054663          	bltz	a0,800068ca <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800067e2:	04491703          	lh	a4,68(s2)
    800067e6:	478d                	li	a5,3
    800067e8:	0cf70463          	beq	a4,a5,800068b0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800067ec:	4789                	li	a5,2
    800067ee:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800067f2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800067f6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800067fa:	f4c42783          	lw	a5,-180(s0)
    800067fe:	0017c713          	xori	a4,a5,1
    80006802:	8b05                	andi	a4,a4,1
    80006804:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006808:	0037f713          	andi	a4,a5,3
    8000680c:	00e03733          	snez	a4,a4
    80006810:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006814:	4007f793          	andi	a5,a5,1024
    80006818:	c791                	beqz	a5,80006824 <sys_open+0xd2>
    8000681a:	04491703          	lh	a4,68(s2)
    8000681e:	4789                	li	a5,2
    80006820:	08f70f63          	beq	a4,a5,800068be <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006824:	854a                	mv	a0,s2
    80006826:	ffffe097          	auipc	ra,0xffffe
    8000682a:	fd8080e7          	jalr	-40(ra) # 800047fe <iunlock>
  end_op();
    8000682e:	fffff097          	auipc	ra,0xfffff
    80006832:	964080e7          	jalr	-1692(ra) # 80005192 <end_op>

  return fd;
}
    80006836:	8526                	mv	a0,s1
    80006838:	70ea                	ld	ra,184(sp)
    8000683a:	744a                	ld	s0,176(sp)
    8000683c:	74aa                	ld	s1,168(sp)
    8000683e:	790a                	ld	s2,160(sp)
    80006840:	69ea                	ld	s3,152(sp)
    80006842:	6129                	addi	sp,sp,192
    80006844:	8082                	ret
      end_op();
    80006846:	fffff097          	auipc	ra,0xfffff
    8000684a:	94c080e7          	jalr	-1716(ra) # 80005192 <end_op>
      return -1;
    8000684e:	b7e5                	j	80006836 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006850:	f5040513          	addi	a0,s0,-176
    80006854:	ffffe097          	auipc	ra,0xffffe
    80006858:	69e080e7          	jalr	1694(ra) # 80004ef2 <namei>
    8000685c:	892a                	mv	s2,a0
    8000685e:	c905                	beqz	a0,8000688e <sys_open+0x13c>
    ilock(ip);
    80006860:	ffffe097          	auipc	ra,0xffffe
    80006864:	edc080e7          	jalr	-292(ra) # 8000473c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006868:	04491703          	lh	a4,68(s2)
    8000686c:	4785                	li	a5,1
    8000686e:	f4f712e3          	bne	a4,a5,800067b2 <sys_open+0x60>
    80006872:	f4c42783          	lw	a5,-180(s0)
    80006876:	dba1                	beqz	a5,800067c6 <sys_open+0x74>
      iunlockput(ip);
    80006878:	854a                	mv	a0,s2
    8000687a:	ffffe097          	auipc	ra,0xffffe
    8000687e:	124080e7          	jalr	292(ra) # 8000499e <iunlockput>
      end_op();
    80006882:	fffff097          	auipc	ra,0xfffff
    80006886:	910080e7          	jalr	-1776(ra) # 80005192 <end_op>
      return -1;
    8000688a:	54fd                	li	s1,-1
    8000688c:	b76d                	j	80006836 <sys_open+0xe4>
      end_op();
    8000688e:	fffff097          	auipc	ra,0xfffff
    80006892:	904080e7          	jalr	-1788(ra) # 80005192 <end_op>
      return -1;
    80006896:	54fd                	li	s1,-1
    80006898:	bf79                	j	80006836 <sys_open+0xe4>
    iunlockput(ip);
    8000689a:	854a                	mv	a0,s2
    8000689c:	ffffe097          	auipc	ra,0xffffe
    800068a0:	102080e7          	jalr	258(ra) # 8000499e <iunlockput>
    end_op();
    800068a4:	fffff097          	auipc	ra,0xfffff
    800068a8:	8ee080e7          	jalr	-1810(ra) # 80005192 <end_op>
    return -1;
    800068ac:	54fd                	li	s1,-1
    800068ae:	b761                	j	80006836 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800068b0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800068b4:	04691783          	lh	a5,70(s2)
    800068b8:	02f99223          	sh	a5,36(s3)
    800068bc:	bf2d                	j	800067f6 <sys_open+0xa4>
    itrunc(ip);
    800068be:	854a                	mv	a0,s2
    800068c0:	ffffe097          	auipc	ra,0xffffe
    800068c4:	f8a080e7          	jalr	-118(ra) # 8000484a <itrunc>
    800068c8:	bfb1                	j	80006824 <sys_open+0xd2>
      fileclose(f);
    800068ca:	854e                	mv	a0,s3
    800068cc:	fffff097          	auipc	ra,0xfffff
    800068d0:	d12080e7          	jalr	-750(ra) # 800055de <fileclose>
    iunlockput(ip);
    800068d4:	854a                	mv	a0,s2
    800068d6:	ffffe097          	auipc	ra,0xffffe
    800068da:	0c8080e7          	jalr	200(ra) # 8000499e <iunlockput>
    end_op();
    800068de:	fffff097          	auipc	ra,0xfffff
    800068e2:	8b4080e7          	jalr	-1868(ra) # 80005192 <end_op>
    return -1;
    800068e6:	54fd                	li	s1,-1
    800068e8:	b7b9                	j	80006836 <sys_open+0xe4>

00000000800068ea <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800068ea:	7175                	addi	sp,sp,-144
    800068ec:	e506                	sd	ra,136(sp)
    800068ee:	e122                	sd	s0,128(sp)
    800068f0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800068f2:	fffff097          	auipc	ra,0xfffff
    800068f6:	820080e7          	jalr	-2016(ra) # 80005112 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800068fa:	08000613          	li	a2,128
    800068fe:	f7040593          	addi	a1,s0,-144
    80006902:	4501                	li	a0,0
    80006904:	ffffd097          	auipc	ra,0xffffd
    80006908:	0a4080e7          	jalr	164(ra) # 800039a8 <argstr>
    8000690c:	02054963          	bltz	a0,8000693e <sys_mkdir+0x54>
    80006910:	4681                	li	a3,0
    80006912:	4601                	li	a2,0
    80006914:	4585                	li	a1,1
    80006916:	f7040513          	addi	a0,s0,-144
    8000691a:	fffff097          	auipc	ra,0xfffff
    8000691e:	7fe080e7          	jalr	2046(ra) # 80006118 <create>
    80006922:	cd11                	beqz	a0,8000693e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006924:	ffffe097          	auipc	ra,0xffffe
    80006928:	07a080e7          	jalr	122(ra) # 8000499e <iunlockput>
  end_op();
    8000692c:	fffff097          	auipc	ra,0xfffff
    80006930:	866080e7          	jalr	-1946(ra) # 80005192 <end_op>
  return 0;
    80006934:	4501                	li	a0,0
}
    80006936:	60aa                	ld	ra,136(sp)
    80006938:	640a                	ld	s0,128(sp)
    8000693a:	6149                	addi	sp,sp,144
    8000693c:	8082                	ret
    end_op();
    8000693e:	fffff097          	auipc	ra,0xfffff
    80006942:	854080e7          	jalr	-1964(ra) # 80005192 <end_op>
    return -1;
    80006946:	557d                	li	a0,-1
    80006948:	b7fd                	j	80006936 <sys_mkdir+0x4c>

000000008000694a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000694a:	7135                	addi	sp,sp,-160
    8000694c:	ed06                	sd	ra,152(sp)
    8000694e:	e922                	sd	s0,144(sp)
    80006950:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006952:	ffffe097          	auipc	ra,0xffffe
    80006956:	7c0080e7          	jalr	1984(ra) # 80005112 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000695a:	08000613          	li	a2,128
    8000695e:	f7040593          	addi	a1,s0,-144
    80006962:	4501                	li	a0,0
    80006964:	ffffd097          	auipc	ra,0xffffd
    80006968:	044080e7          	jalr	68(ra) # 800039a8 <argstr>
    8000696c:	04054a63          	bltz	a0,800069c0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006970:	f6c40593          	addi	a1,s0,-148
    80006974:	4505                	li	a0,1
    80006976:	ffffd097          	auipc	ra,0xffffd
    8000697a:	fee080e7          	jalr	-18(ra) # 80003964 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000697e:	04054163          	bltz	a0,800069c0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006982:	f6840593          	addi	a1,s0,-152
    80006986:	4509                	li	a0,2
    80006988:	ffffd097          	auipc	ra,0xffffd
    8000698c:	fdc080e7          	jalr	-36(ra) # 80003964 <argint>
     argint(1, &major) < 0 ||
    80006990:	02054863          	bltz	a0,800069c0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006994:	f6841683          	lh	a3,-152(s0)
    80006998:	f6c41603          	lh	a2,-148(s0)
    8000699c:	458d                	li	a1,3
    8000699e:	f7040513          	addi	a0,s0,-144
    800069a2:	fffff097          	auipc	ra,0xfffff
    800069a6:	776080e7          	jalr	1910(ra) # 80006118 <create>
     argint(2, &minor) < 0 ||
    800069aa:	c919                	beqz	a0,800069c0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800069ac:	ffffe097          	auipc	ra,0xffffe
    800069b0:	ff2080e7          	jalr	-14(ra) # 8000499e <iunlockput>
  end_op();
    800069b4:	ffffe097          	auipc	ra,0xffffe
    800069b8:	7de080e7          	jalr	2014(ra) # 80005192 <end_op>
  return 0;
    800069bc:	4501                	li	a0,0
    800069be:	a031                	j	800069ca <sys_mknod+0x80>
    end_op();
    800069c0:	ffffe097          	auipc	ra,0xffffe
    800069c4:	7d2080e7          	jalr	2002(ra) # 80005192 <end_op>
    return -1;
    800069c8:	557d                	li	a0,-1
}
    800069ca:	60ea                	ld	ra,152(sp)
    800069cc:	644a                	ld	s0,144(sp)
    800069ce:	610d                	addi	sp,sp,160
    800069d0:	8082                	ret

00000000800069d2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800069d2:	7135                	addi	sp,sp,-160
    800069d4:	ed06                	sd	ra,152(sp)
    800069d6:	e922                	sd	s0,144(sp)
    800069d8:	e526                	sd	s1,136(sp)
    800069da:	e14a                	sd	s2,128(sp)
    800069dc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800069de:	ffffb097          	auipc	ra,0xffffb
    800069e2:	078080e7          	jalr	120(ra) # 80001a56 <myproc>
    800069e6:	892a                	mv	s2,a0
  
  begin_op();
    800069e8:	ffffe097          	auipc	ra,0xffffe
    800069ec:	72a080e7          	jalr	1834(ra) # 80005112 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800069f0:	08000613          	li	a2,128
    800069f4:	f6040593          	addi	a1,s0,-160
    800069f8:	4501                	li	a0,0
    800069fa:	ffffd097          	auipc	ra,0xffffd
    800069fe:	fae080e7          	jalr	-82(ra) # 800039a8 <argstr>
    80006a02:	04054b63          	bltz	a0,80006a58 <sys_chdir+0x86>
    80006a06:	f6040513          	addi	a0,s0,-160
    80006a0a:	ffffe097          	auipc	ra,0xffffe
    80006a0e:	4e8080e7          	jalr	1256(ra) # 80004ef2 <namei>
    80006a12:	84aa                	mv	s1,a0
    80006a14:	c131                	beqz	a0,80006a58 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006a16:	ffffe097          	auipc	ra,0xffffe
    80006a1a:	d26080e7          	jalr	-730(ra) # 8000473c <ilock>
  if(ip->type != T_DIR){
    80006a1e:	04449703          	lh	a4,68(s1)
    80006a22:	4785                	li	a5,1
    80006a24:	04f71063          	bne	a4,a5,80006a64 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006a28:	8526                	mv	a0,s1
    80006a2a:	ffffe097          	auipc	ra,0xffffe
    80006a2e:	dd4080e7          	jalr	-556(ra) # 800047fe <iunlock>
  iput(p->cwd);
    80006a32:	26093503          	ld	a0,608(s2)
    80006a36:	ffffe097          	auipc	ra,0xffffe
    80006a3a:	ec0080e7          	jalr	-320(ra) # 800048f6 <iput>
  end_op();
    80006a3e:	ffffe097          	auipc	ra,0xffffe
    80006a42:	754080e7          	jalr	1876(ra) # 80005192 <end_op>
  p->cwd = ip;
    80006a46:	26993023          	sd	s1,608(s2)
  return 0;
    80006a4a:	4501                	li	a0,0
}
    80006a4c:	60ea                	ld	ra,152(sp)
    80006a4e:	644a                	ld	s0,144(sp)
    80006a50:	64aa                	ld	s1,136(sp)
    80006a52:	690a                	ld	s2,128(sp)
    80006a54:	610d                	addi	sp,sp,160
    80006a56:	8082                	ret
    end_op();
    80006a58:	ffffe097          	auipc	ra,0xffffe
    80006a5c:	73a080e7          	jalr	1850(ra) # 80005192 <end_op>
    return -1;
    80006a60:	557d                	li	a0,-1
    80006a62:	b7ed                	j	80006a4c <sys_chdir+0x7a>
    iunlockput(ip);
    80006a64:	8526                	mv	a0,s1
    80006a66:	ffffe097          	auipc	ra,0xffffe
    80006a6a:	f38080e7          	jalr	-200(ra) # 8000499e <iunlockput>
    end_op();
    80006a6e:	ffffe097          	auipc	ra,0xffffe
    80006a72:	724080e7          	jalr	1828(ra) # 80005192 <end_op>
    return -1;
    80006a76:	557d                	li	a0,-1
    80006a78:	bfd1                	j	80006a4c <sys_chdir+0x7a>

0000000080006a7a <sys_exec>:

uint64
sys_exec(void)
{
    80006a7a:	7145                	addi	sp,sp,-464
    80006a7c:	e786                	sd	ra,456(sp)
    80006a7e:	e3a2                	sd	s0,448(sp)
    80006a80:	ff26                	sd	s1,440(sp)
    80006a82:	fb4a                	sd	s2,432(sp)
    80006a84:	f74e                	sd	s3,424(sp)
    80006a86:	f352                	sd	s4,416(sp)
    80006a88:	ef56                	sd	s5,408(sp)
    80006a8a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006a8c:	08000613          	li	a2,128
    80006a90:	f4040593          	addi	a1,s0,-192
    80006a94:	4501                	li	a0,0
    80006a96:	ffffd097          	auipc	ra,0xffffd
    80006a9a:	f12080e7          	jalr	-238(ra) # 800039a8 <argstr>
    return -1;
    80006a9e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006aa0:	0c054a63          	bltz	a0,80006b74 <sys_exec+0xfa>
    80006aa4:	e3840593          	addi	a1,s0,-456
    80006aa8:	4505                	li	a0,1
    80006aaa:	ffffd097          	auipc	ra,0xffffd
    80006aae:	edc080e7          	jalr	-292(ra) # 80003986 <argaddr>
    80006ab2:	0c054163          	bltz	a0,80006b74 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006ab6:	10000613          	li	a2,256
    80006aba:	4581                	li	a1,0
    80006abc:	e4040513          	addi	a0,s0,-448
    80006ac0:	ffffa097          	auipc	ra,0xffffa
    80006ac4:	1fe080e7          	jalr	510(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006ac8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006acc:	89a6                	mv	s3,s1
    80006ace:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006ad0:	02000a13          	li	s4,32
    80006ad4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006ad8:	00391793          	slli	a5,s2,0x3
    80006adc:	e3040593          	addi	a1,s0,-464
    80006ae0:	e3843503          	ld	a0,-456(s0)
    80006ae4:	953e                	add	a0,a0,a5
    80006ae6:	ffffd097          	auipc	ra,0xffffd
    80006aea:	dde080e7          	jalr	-546(ra) # 800038c4 <fetchaddr>
    80006aee:	02054a63          	bltz	a0,80006b22 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006af2:	e3043783          	ld	a5,-464(s0)
    80006af6:	c3b9                	beqz	a5,80006b3c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006af8:	ffffa097          	auipc	ra,0xffffa
    80006afc:	fda080e7          	jalr	-38(ra) # 80000ad2 <kalloc>
    80006b00:	85aa                	mv	a1,a0
    80006b02:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006b06:	cd11                	beqz	a0,80006b22 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006b08:	6605                	lui	a2,0x1
    80006b0a:	e3043503          	ld	a0,-464(s0)
    80006b0e:	ffffd097          	auipc	ra,0xffffd
    80006b12:	e0c080e7          	jalr	-500(ra) # 8000391a <fetchstr>
    80006b16:	00054663          	bltz	a0,80006b22 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006b1a:	0905                	addi	s2,s2,1
    80006b1c:	09a1                	addi	s3,s3,8
    80006b1e:	fb491be3          	bne	s2,s4,80006ad4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b22:	10048913          	addi	s2,s1,256
    80006b26:	6088                	ld	a0,0(s1)
    80006b28:	c529                	beqz	a0,80006b72 <sys_exec+0xf8>
    kfree(argv[i]);
    80006b2a:	ffffa097          	auipc	ra,0xffffa
    80006b2e:	eac080e7          	jalr	-340(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b32:	04a1                	addi	s1,s1,8
    80006b34:	ff2499e3          	bne	s1,s2,80006b26 <sys_exec+0xac>
  return -1;
    80006b38:	597d                	li	s2,-1
    80006b3a:	a82d                	j	80006b74 <sys_exec+0xfa>
      argv[i] = 0;
    80006b3c:	0a8e                	slli	s5,s5,0x3
    80006b3e:	fc040793          	addi	a5,s0,-64
    80006b42:	9abe                	add	s5,s5,a5
    80006b44:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006b48:	e4040593          	addi	a1,s0,-448
    80006b4c:	f4040513          	addi	a0,s0,-192
    80006b50:	fffff097          	auipc	ra,0xfffff
    80006b54:	0e0080e7          	jalr	224(ra) # 80005c30 <exec>
    80006b58:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b5a:	10048993          	addi	s3,s1,256
    80006b5e:	6088                	ld	a0,0(s1)
    80006b60:	c911                	beqz	a0,80006b74 <sys_exec+0xfa>
    kfree(argv[i]);
    80006b62:	ffffa097          	auipc	ra,0xffffa
    80006b66:	e74080e7          	jalr	-396(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b6a:	04a1                	addi	s1,s1,8
    80006b6c:	ff3499e3          	bne	s1,s3,80006b5e <sys_exec+0xe4>
    80006b70:	a011                	j	80006b74 <sys_exec+0xfa>
  return -1;
    80006b72:	597d                	li	s2,-1
}
    80006b74:	854a                	mv	a0,s2
    80006b76:	60be                	ld	ra,456(sp)
    80006b78:	641e                	ld	s0,448(sp)
    80006b7a:	74fa                	ld	s1,440(sp)
    80006b7c:	795a                	ld	s2,432(sp)
    80006b7e:	79ba                	ld	s3,424(sp)
    80006b80:	7a1a                	ld	s4,416(sp)
    80006b82:	6afa                	ld	s5,408(sp)
    80006b84:	6179                	addi	sp,sp,464
    80006b86:	8082                	ret

0000000080006b88 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006b88:	7139                	addi	sp,sp,-64
    80006b8a:	fc06                	sd	ra,56(sp)
    80006b8c:	f822                	sd	s0,48(sp)
    80006b8e:	f426                	sd	s1,40(sp)
    80006b90:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006b92:	ffffb097          	auipc	ra,0xffffb
    80006b96:	ec4080e7          	jalr	-316(ra) # 80001a56 <myproc>
    80006b9a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006b9c:	fd840593          	addi	a1,s0,-40
    80006ba0:	4501                	li	a0,0
    80006ba2:	ffffd097          	auipc	ra,0xffffd
    80006ba6:	de4080e7          	jalr	-540(ra) # 80003986 <argaddr>
    return -1;
    80006baa:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006bac:	0e054463          	bltz	a0,80006c94 <sys_pipe+0x10c>
  if(pipealloc(&rf, &wf) < 0)
    80006bb0:	fc840593          	addi	a1,s0,-56
    80006bb4:	fd040513          	addi	a0,s0,-48
    80006bb8:	fffff097          	auipc	ra,0xfffff
    80006bbc:	d56080e7          	jalr	-682(ra) # 8000590e <pipealloc>
    return -1;
    80006bc0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006bc2:	0c054963          	bltz	a0,80006c94 <sys_pipe+0x10c>
  fd0 = -1;
    80006bc6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006bca:	fd043503          	ld	a0,-48(s0)
    80006bce:	fffff097          	auipc	ra,0xfffff
    80006bd2:	508080e7          	jalr	1288(ra) # 800060d6 <fdalloc>
    80006bd6:	fca42223          	sw	a0,-60(s0)
    80006bda:	0a054063          	bltz	a0,80006c7a <sys_pipe+0xf2>
    80006bde:	fc843503          	ld	a0,-56(s0)
    80006be2:	fffff097          	auipc	ra,0xfffff
    80006be6:	4f4080e7          	jalr	1268(ra) # 800060d6 <fdalloc>
    80006bea:	fca42023          	sw	a0,-64(s0)
    80006bee:	06054c63          	bltz	a0,80006c66 <sys_pipe+0xde>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006bf2:	4691                	li	a3,4
    80006bf4:	fc440613          	addi	a2,s0,-60
    80006bf8:	fd843583          	ld	a1,-40(s0)
    80006bfc:	1d84b503          	ld	a0,472(s1)
    80006c00:	ffffb097          	auipc	ra,0xffffb
    80006c04:	a3e080e7          	jalr	-1474(ra) # 8000163e <copyout>
    80006c08:	02054163          	bltz	a0,80006c2a <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006c0c:	4691                	li	a3,4
    80006c0e:	fc040613          	addi	a2,s0,-64
    80006c12:	fd843583          	ld	a1,-40(s0)
    80006c16:	0591                	addi	a1,a1,4
    80006c18:	1d84b503          	ld	a0,472(s1)
    80006c1c:	ffffb097          	auipc	ra,0xffffb
    80006c20:	a22080e7          	jalr	-1502(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006c24:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006c26:	06055763          	bgez	a0,80006c94 <sys_pipe+0x10c>
    p->ofile[fd0] = 0;
    80006c2a:	fc442783          	lw	a5,-60(s0)
    80006c2e:	03c78793          	addi	a5,a5,60
    80006c32:	078e                	slli	a5,a5,0x3
    80006c34:	97a6                	add	a5,a5,s1
    80006c36:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006c3a:	fc042503          	lw	a0,-64(s0)
    80006c3e:	03c50513          	addi	a0,a0,60
    80006c42:	050e                	slli	a0,a0,0x3
    80006c44:	9526                	add	a0,a0,s1
    80006c46:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006c4a:	fd043503          	ld	a0,-48(s0)
    80006c4e:	fffff097          	auipc	ra,0xfffff
    80006c52:	990080e7          	jalr	-1648(ra) # 800055de <fileclose>
    fileclose(wf);
    80006c56:	fc843503          	ld	a0,-56(s0)
    80006c5a:	fffff097          	auipc	ra,0xfffff
    80006c5e:	984080e7          	jalr	-1660(ra) # 800055de <fileclose>
    return -1;
    80006c62:	57fd                	li	a5,-1
    80006c64:	a805                	j	80006c94 <sys_pipe+0x10c>
    if(fd0 >= 0)
    80006c66:	fc442783          	lw	a5,-60(s0)
    80006c6a:	0007c863          	bltz	a5,80006c7a <sys_pipe+0xf2>
      p->ofile[fd0] = 0;
    80006c6e:	03c78513          	addi	a0,a5,60
    80006c72:	050e                	slli	a0,a0,0x3
    80006c74:	9526                	add	a0,a0,s1
    80006c76:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006c7a:	fd043503          	ld	a0,-48(s0)
    80006c7e:	fffff097          	auipc	ra,0xfffff
    80006c82:	960080e7          	jalr	-1696(ra) # 800055de <fileclose>
    fileclose(wf);
    80006c86:	fc843503          	ld	a0,-56(s0)
    80006c8a:	fffff097          	auipc	ra,0xfffff
    80006c8e:	954080e7          	jalr	-1708(ra) # 800055de <fileclose>
    return -1;
    80006c92:	57fd                	li	a5,-1
}
    80006c94:	853e                	mv	a0,a5
    80006c96:	70e2                	ld	ra,56(sp)
    80006c98:	7442                	ld	s0,48(sp)
    80006c9a:	74a2                	ld	s1,40(sp)
    80006c9c:	6121                	addi	sp,sp,64
    80006c9e:	8082                	ret

0000000080006ca0 <kernelvec>:
    80006ca0:	7111                	addi	sp,sp,-256
    80006ca2:	e006                	sd	ra,0(sp)
    80006ca4:	e40a                	sd	sp,8(sp)
    80006ca6:	e80e                	sd	gp,16(sp)
    80006ca8:	ec12                	sd	tp,24(sp)
    80006caa:	f016                	sd	t0,32(sp)
    80006cac:	f41a                	sd	t1,40(sp)
    80006cae:	f81e                	sd	t2,48(sp)
    80006cb0:	fc22                	sd	s0,56(sp)
    80006cb2:	e0a6                	sd	s1,64(sp)
    80006cb4:	e4aa                	sd	a0,72(sp)
    80006cb6:	e8ae                	sd	a1,80(sp)
    80006cb8:	ecb2                	sd	a2,88(sp)
    80006cba:	f0b6                	sd	a3,96(sp)
    80006cbc:	f4ba                	sd	a4,104(sp)
    80006cbe:	f8be                	sd	a5,112(sp)
    80006cc0:	fcc2                	sd	a6,120(sp)
    80006cc2:	e146                	sd	a7,128(sp)
    80006cc4:	e54a                	sd	s2,136(sp)
    80006cc6:	e94e                	sd	s3,144(sp)
    80006cc8:	ed52                	sd	s4,152(sp)
    80006cca:	f156                	sd	s5,160(sp)
    80006ccc:	f55a                	sd	s6,168(sp)
    80006cce:	f95e                	sd	s7,176(sp)
    80006cd0:	fd62                	sd	s8,184(sp)
    80006cd2:	e1e6                	sd	s9,192(sp)
    80006cd4:	e5ea                	sd	s10,200(sp)
    80006cd6:	e9ee                	sd	s11,208(sp)
    80006cd8:	edf2                	sd	t3,216(sp)
    80006cda:	f1f6                	sd	t4,224(sp)
    80006cdc:	f5fa                	sd	t5,232(sp)
    80006cde:	f9fe                	sd	t6,240(sp)
    80006ce0:	ab3fc0ef          	jal	ra,80003792 <kerneltrap>
    80006ce4:	6082                	ld	ra,0(sp)
    80006ce6:	6122                	ld	sp,8(sp)
    80006ce8:	61c2                	ld	gp,16(sp)
    80006cea:	7282                	ld	t0,32(sp)
    80006cec:	7322                	ld	t1,40(sp)
    80006cee:	73c2                	ld	t2,48(sp)
    80006cf0:	7462                	ld	s0,56(sp)
    80006cf2:	6486                	ld	s1,64(sp)
    80006cf4:	6526                	ld	a0,72(sp)
    80006cf6:	65c6                	ld	a1,80(sp)
    80006cf8:	6666                	ld	a2,88(sp)
    80006cfa:	7686                	ld	a3,96(sp)
    80006cfc:	7726                	ld	a4,104(sp)
    80006cfe:	77c6                	ld	a5,112(sp)
    80006d00:	7866                	ld	a6,120(sp)
    80006d02:	688a                	ld	a7,128(sp)
    80006d04:	692a                	ld	s2,136(sp)
    80006d06:	69ca                	ld	s3,144(sp)
    80006d08:	6a6a                	ld	s4,152(sp)
    80006d0a:	7a8a                	ld	s5,160(sp)
    80006d0c:	7b2a                	ld	s6,168(sp)
    80006d0e:	7bca                	ld	s7,176(sp)
    80006d10:	7c6a                	ld	s8,184(sp)
    80006d12:	6c8e                	ld	s9,192(sp)
    80006d14:	6d2e                	ld	s10,200(sp)
    80006d16:	6dce                	ld	s11,208(sp)
    80006d18:	6e6e                	ld	t3,216(sp)
    80006d1a:	7e8e                	ld	t4,224(sp)
    80006d1c:	7f2e                	ld	t5,232(sp)
    80006d1e:	7fce                	ld	t6,240(sp)
    80006d20:	6111                	addi	sp,sp,256
    80006d22:	10200073          	sret
    80006d26:	00000013          	nop
    80006d2a:	00000013          	nop
    80006d2e:	0001                	nop

0000000080006d30 <timervec>:
    80006d30:	34051573          	csrrw	a0,mscratch,a0
    80006d34:	e10c                	sd	a1,0(a0)
    80006d36:	e510                	sd	a2,8(a0)
    80006d38:	e914                	sd	a3,16(a0)
    80006d3a:	6d0c                	ld	a1,24(a0)
    80006d3c:	7110                	ld	a2,32(a0)
    80006d3e:	6194                	ld	a3,0(a1)
    80006d40:	96b2                	add	a3,a3,a2
    80006d42:	e194                	sd	a3,0(a1)
    80006d44:	4589                	li	a1,2
    80006d46:	14459073          	csrw	sip,a1
    80006d4a:	6914                	ld	a3,16(a0)
    80006d4c:	6510                	ld	a2,8(a0)
    80006d4e:	610c                	ld	a1,0(a0)
    80006d50:	34051573          	csrrw	a0,mscratch,a0
    80006d54:	30200073          	mret
	...

0000000080006d5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006d5a:	1141                	addi	sp,sp,-16
    80006d5c:	e422                	sd	s0,8(sp)
    80006d5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006d60:	0c0007b7          	lui	a5,0xc000
    80006d64:	4705                	li	a4,1
    80006d66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006d68:	c3d8                	sw	a4,4(a5)
}
    80006d6a:	6422                	ld	s0,8(sp)
    80006d6c:	0141                	addi	sp,sp,16
    80006d6e:	8082                	ret

0000000080006d70 <plicinithart>:

void
plicinithart(void)
{
    80006d70:	1141                	addi	sp,sp,-16
    80006d72:	e406                	sd	ra,8(sp)
    80006d74:	e022                	sd	s0,0(sp)
    80006d76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006d78:	ffffb097          	auipc	ra,0xffffb
    80006d7c:	cb2080e7          	jalr	-846(ra) # 80001a2a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006d80:	0085171b          	slliw	a4,a0,0x8
    80006d84:	0c0027b7          	lui	a5,0xc002
    80006d88:	97ba                	add	a5,a5,a4
    80006d8a:	40200713          	li	a4,1026
    80006d8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006d92:	00d5151b          	slliw	a0,a0,0xd
    80006d96:	0c2017b7          	lui	a5,0xc201
    80006d9a:	953e                	add	a0,a0,a5
    80006d9c:	00052023          	sw	zero,0(a0)
}
    80006da0:	60a2                	ld	ra,8(sp)
    80006da2:	6402                	ld	s0,0(sp)
    80006da4:	0141                	addi	sp,sp,16
    80006da6:	8082                	ret

0000000080006da8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006da8:	1141                	addi	sp,sp,-16
    80006daa:	e406                	sd	ra,8(sp)
    80006dac:	e022                	sd	s0,0(sp)
    80006dae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006db0:	ffffb097          	auipc	ra,0xffffb
    80006db4:	c7a080e7          	jalr	-902(ra) # 80001a2a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006db8:	00d5179b          	slliw	a5,a0,0xd
    80006dbc:	0c201537          	lui	a0,0xc201
    80006dc0:	953e                	add	a0,a0,a5
  return irq;
}
    80006dc2:	4148                	lw	a0,4(a0)
    80006dc4:	60a2                	ld	ra,8(sp)
    80006dc6:	6402                	ld	s0,0(sp)
    80006dc8:	0141                	addi	sp,sp,16
    80006dca:	8082                	ret

0000000080006dcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006dcc:	1101                	addi	sp,sp,-32
    80006dce:	ec06                	sd	ra,24(sp)
    80006dd0:	e822                	sd	s0,16(sp)
    80006dd2:	e426                	sd	s1,8(sp)
    80006dd4:	1000                	addi	s0,sp,32
    80006dd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006dd8:	ffffb097          	auipc	ra,0xffffb
    80006ddc:	c52080e7          	jalr	-942(ra) # 80001a2a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006de0:	00d5151b          	slliw	a0,a0,0xd
    80006de4:	0c2017b7          	lui	a5,0xc201
    80006de8:	97aa                	add	a5,a5,a0
    80006dea:	c3c4                	sw	s1,4(a5)
}
    80006dec:	60e2                	ld	ra,24(sp)
    80006dee:	6442                	ld	s0,16(sp)
    80006df0:	64a2                	ld	s1,8(sp)
    80006df2:	6105                	addi	sp,sp,32
    80006df4:	8082                	ret

0000000080006df6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006df6:	1141                	addi	sp,sp,-16
    80006df8:	e406                	sd	ra,8(sp)
    80006dfa:	e022                	sd	s0,0(sp)
    80006dfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006dfe:	479d                	li	a5,7
    80006e00:	06a7c963          	blt	a5,a0,80006e72 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006e04:	0003a797          	auipc	a5,0x3a
    80006e08:	1fc78793          	addi	a5,a5,508 # 80041000 <disk>
    80006e0c:	00a78733          	add	a4,a5,a0
    80006e10:	6789                	lui	a5,0x2
    80006e12:	97ba                	add	a5,a5,a4
    80006e14:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006e18:	e7ad                	bnez	a5,80006e82 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006e1a:	00451793          	slli	a5,a0,0x4
    80006e1e:	0003c717          	auipc	a4,0x3c
    80006e22:	1e270713          	addi	a4,a4,482 # 80043000 <disk+0x2000>
    80006e26:	6314                	ld	a3,0(a4)
    80006e28:	96be                	add	a3,a3,a5
    80006e2a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006e2e:	6314                	ld	a3,0(a4)
    80006e30:	96be                	add	a3,a3,a5
    80006e32:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006e36:	6314                	ld	a3,0(a4)
    80006e38:	96be                	add	a3,a3,a5
    80006e3a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006e3e:	6318                	ld	a4,0(a4)
    80006e40:	97ba                	add	a5,a5,a4
    80006e42:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006e46:	0003a797          	auipc	a5,0x3a
    80006e4a:	1ba78793          	addi	a5,a5,442 # 80041000 <disk>
    80006e4e:	97aa                	add	a5,a5,a0
    80006e50:	6509                	lui	a0,0x2
    80006e52:	953e                	add	a0,a0,a5
    80006e54:	4785                	li	a5,1
    80006e56:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006e5a:	0003c517          	auipc	a0,0x3c
    80006e5e:	1be50513          	addi	a0,a0,446 # 80043018 <disk+0x2018>
    80006e62:	ffffc097          	auipc	ra,0xffffc
    80006e66:	9dc080e7          	jalr	-1572(ra) # 8000283e <wakeup>
}
    80006e6a:	60a2                	ld	ra,8(sp)
    80006e6c:	6402                	ld	s0,0(sp)
    80006e6e:	0141                	addi	sp,sp,16
    80006e70:	8082                	ret
    panic("free_desc 1");
    80006e72:	00003517          	auipc	a0,0x3
    80006e76:	93e50513          	addi	a0,a0,-1730 # 800097b0 <syscalls+0x378>
    80006e7a:	ffff9097          	auipc	ra,0xffff9
    80006e7e:	6b0080e7          	jalr	1712(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006e82:	00003517          	auipc	a0,0x3
    80006e86:	93e50513          	addi	a0,a0,-1730 # 800097c0 <syscalls+0x388>
    80006e8a:	ffff9097          	auipc	ra,0xffff9
    80006e8e:	6a0080e7          	jalr	1696(ra) # 8000052a <panic>

0000000080006e92 <virtio_disk_init>:
{
    80006e92:	1101                	addi	sp,sp,-32
    80006e94:	ec06                	sd	ra,24(sp)
    80006e96:	e822                	sd	s0,16(sp)
    80006e98:	e426                	sd	s1,8(sp)
    80006e9a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006e9c:	00003597          	auipc	a1,0x3
    80006ea0:	93458593          	addi	a1,a1,-1740 # 800097d0 <syscalls+0x398>
    80006ea4:	0003c517          	auipc	a0,0x3c
    80006ea8:	28450513          	addi	a0,a0,644 # 80043128 <disk+0x2128>
    80006eac:	ffffa097          	auipc	ra,0xffffa
    80006eb0:	c86080e7          	jalr	-890(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006eb4:	100017b7          	lui	a5,0x10001
    80006eb8:	4398                	lw	a4,0(a5)
    80006eba:	2701                	sext.w	a4,a4
    80006ebc:	747277b7          	lui	a5,0x74727
    80006ec0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006ec4:	0ef71163          	bne	a4,a5,80006fa6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006ec8:	100017b7          	lui	a5,0x10001
    80006ecc:	43dc                	lw	a5,4(a5)
    80006ece:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006ed0:	4705                	li	a4,1
    80006ed2:	0ce79a63          	bne	a5,a4,80006fa6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006ed6:	100017b7          	lui	a5,0x10001
    80006eda:	479c                	lw	a5,8(a5)
    80006edc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006ede:	4709                	li	a4,2
    80006ee0:	0ce79363          	bne	a5,a4,80006fa6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006ee4:	100017b7          	lui	a5,0x10001
    80006ee8:	47d8                	lw	a4,12(a5)
    80006eea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006eec:	554d47b7          	lui	a5,0x554d4
    80006ef0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006ef4:	0af71963          	bne	a4,a5,80006fa6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ef8:	100017b7          	lui	a5,0x10001
    80006efc:	4705                	li	a4,1
    80006efe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006f00:	470d                	li	a4,3
    80006f02:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006f04:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006f06:	c7ffe737          	lui	a4,0xc7ffe
    80006f0a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fba75f>
    80006f0e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006f10:	2701                	sext.w	a4,a4
    80006f12:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006f14:	472d                	li	a4,11
    80006f16:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006f18:	473d                	li	a4,15
    80006f1a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006f1c:	6705                	lui	a4,0x1
    80006f1e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006f20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006f24:	5bdc                	lw	a5,52(a5)
    80006f26:	2781                	sext.w	a5,a5
  if(max == 0)
    80006f28:	c7d9                	beqz	a5,80006fb6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006f2a:	471d                	li	a4,7
    80006f2c:	08f77d63          	bgeu	a4,a5,80006fc6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006f30:	100014b7          	lui	s1,0x10001
    80006f34:	47a1                	li	a5,8
    80006f36:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006f38:	6609                	lui	a2,0x2
    80006f3a:	4581                	li	a1,0
    80006f3c:	0003a517          	auipc	a0,0x3a
    80006f40:	0c450513          	addi	a0,a0,196 # 80041000 <disk>
    80006f44:	ffffa097          	auipc	ra,0xffffa
    80006f48:	d7a080e7          	jalr	-646(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006f4c:	0003a717          	auipc	a4,0x3a
    80006f50:	0b470713          	addi	a4,a4,180 # 80041000 <disk>
    80006f54:	00c75793          	srli	a5,a4,0xc
    80006f58:	2781                	sext.w	a5,a5
    80006f5a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006f5c:	0003c797          	auipc	a5,0x3c
    80006f60:	0a478793          	addi	a5,a5,164 # 80043000 <disk+0x2000>
    80006f64:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006f66:	0003a717          	auipc	a4,0x3a
    80006f6a:	11a70713          	addi	a4,a4,282 # 80041080 <disk+0x80>
    80006f6e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006f70:	0003b717          	auipc	a4,0x3b
    80006f74:	09070713          	addi	a4,a4,144 # 80042000 <disk+0x1000>
    80006f78:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006f7a:	4705                	li	a4,1
    80006f7c:	00e78c23          	sb	a4,24(a5)
    80006f80:	00e78ca3          	sb	a4,25(a5)
    80006f84:	00e78d23          	sb	a4,26(a5)
    80006f88:	00e78da3          	sb	a4,27(a5)
    80006f8c:	00e78e23          	sb	a4,28(a5)
    80006f90:	00e78ea3          	sb	a4,29(a5)
    80006f94:	00e78f23          	sb	a4,30(a5)
    80006f98:	00e78fa3          	sb	a4,31(a5)
}
    80006f9c:	60e2                	ld	ra,24(sp)
    80006f9e:	6442                	ld	s0,16(sp)
    80006fa0:	64a2                	ld	s1,8(sp)
    80006fa2:	6105                	addi	sp,sp,32
    80006fa4:	8082                	ret
    panic("could not find virtio disk");
    80006fa6:	00003517          	auipc	a0,0x3
    80006faa:	83a50513          	addi	a0,a0,-1990 # 800097e0 <syscalls+0x3a8>
    80006fae:	ffff9097          	auipc	ra,0xffff9
    80006fb2:	57c080e7          	jalr	1404(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006fb6:	00003517          	auipc	a0,0x3
    80006fba:	84a50513          	addi	a0,a0,-1974 # 80009800 <syscalls+0x3c8>
    80006fbe:	ffff9097          	auipc	ra,0xffff9
    80006fc2:	56c080e7          	jalr	1388(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006fc6:	00003517          	auipc	a0,0x3
    80006fca:	85a50513          	addi	a0,a0,-1958 # 80009820 <syscalls+0x3e8>
    80006fce:	ffff9097          	auipc	ra,0xffff9
    80006fd2:	55c080e7          	jalr	1372(ra) # 8000052a <panic>

0000000080006fd6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006fd6:	7119                	addi	sp,sp,-128
    80006fd8:	fc86                	sd	ra,120(sp)
    80006fda:	f8a2                	sd	s0,112(sp)
    80006fdc:	f4a6                	sd	s1,104(sp)
    80006fde:	f0ca                	sd	s2,96(sp)
    80006fe0:	ecce                	sd	s3,88(sp)
    80006fe2:	e8d2                	sd	s4,80(sp)
    80006fe4:	e4d6                	sd	s5,72(sp)
    80006fe6:	e0da                	sd	s6,64(sp)
    80006fe8:	fc5e                	sd	s7,56(sp)
    80006fea:	f862                	sd	s8,48(sp)
    80006fec:	f466                	sd	s9,40(sp)
    80006fee:	f06a                	sd	s10,32(sp)
    80006ff0:	ec6e                	sd	s11,24(sp)
    80006ff2:	0100                	addi	s0,sp,128
    80006ff4:	8aaa                	mv	s5,a0
    80006ff6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006ff8:	00c52c83          	lw	s9,12(a0)
    80006ffc:	001c9c9b          	slliw	s9,s9,0x1
    80007000:	1c82                	slli	s9,s9,0x20
    80007002:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007006:	0003c517          	auipc	a0,0x3c
    8000700a:	12250513          	addi	a0,a0,290 # 80043128 <disk+0x2128>
    8000700e:	ffffa097          	auipc	ra,0xffffa
    80007012:	bb4080e7          	jalr	-1100(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80007016:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007018:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000701a:	0003ac17          	auipc	s8,0x3a
    8000701e:	fe6c0c13          	addi	s8,s8,-26 # 80041000 <disk>
    80007022:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80007024:	4b0d                	li	s6,3
    80007026:	a0ad                	j	80007090 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80007028:	00fc0733          	add	a4,s8,a5
    8000702c:	975e                	add	a4,a4,s7
    8000702e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80007032:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80007034:	0207c563          	bltz	a5,8000705e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80007038:	2905                	addiw	s2,s2,1
    8000703a:	0611                	addi	a2,a2,4
    8000703c:	19690d63          	beq	s2,s6,800071d6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80007040:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80007042:	0003c717          	auipc	a4,0x3c
    80007046:	fd670713          	addi	a4,a4,-42 # 80043018 <disk+0x2018>
    8000704a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000704c:	00074683          	lbu	a3,0(a4)
    80007050:	fee1                	bnez	a3,80007028 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80007052:	2785                	addiw	a5,a5,1
    80007054:	0705                	addi	a4,a4,1
    80007056:	fe979be3          	bne	a5,s1,8000704c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000705a:	57fd                	li	a5,-1
    8000705c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000705e:	01205d63          	blez	s2,80007078 <virtio_disk_rw+0xa2>
    80007062:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80007064:	000a2503          	lw	a0,0(s4)
    80007068:	00000097          	auipc	ra,0x0
    8000706c:	d8e080e7          	jalr	-626(ra) # 80006df6 <free_desc>
      for(int j = 0; j < i; j++)
    80007070:	2d85                	addiw	s11,s11,1
    80007072:	0a11                	addi	s4,s4,4
    80007074:	ffb918e3          	bne	s2,s11,80007064 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80007078:	0003c597          	auipc	a1,0x3c
    8000707c:	0b058593          	addi	a1,a1,176 # 80043128 <disk+0x2128>
    80007080:	0003c517          	auipc	a0,0x3c
    80007084:	f9850513          	addi	a0,a0,-104 # 80043018 <disk+0x2018>
    80007088:	ffffb097          	auipc	ra,0xffffb
    8000708c:	62c080e7          	jalr	1580(ra) # 800026b4 <sleep>
  for(int i = 0; i < 3; i++){
    80007090:	f8040a13          	addi	s4,s0,-128
{
    80007094:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80007096:	894e                	mv	s2,s3
    80007098:	b765                	j	80007040 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000709a:	0003c697          	auipc	a3,0x3c
    8000709e:	f666b683          	ld	a3,-154(a3) # 80043000 <disk+0x2000>
    800070a2:	96ba                	add	a3,a3,a4
    800070a4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800070a8:	0003a817          	auipc	a6,0x3a
    800070ac:	f5880813          	addi	a6,a6,-168 # 80041000 <disk>
    800070b0:	0003c697          	auipc	a3,0x3c
    800070b4:	f5068693          	addi	a3,a3,-176 # 80043000 <disk+0x2000>
    800070b8:	6290                	ld	a2,0(a3)
    800070ba:	963a                	add	a2,a2,a4
    800070bc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800070c0:	0015e593          	ori	a1,a1,1
    800070c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800070c8:	f8842603          	lw	a2,-120(s0)
    800070cc:	628c                	ld	a1,0(a3)
    800070ce:	972e                	add	a4,a4,a1
    800070d0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800070d4:	20050593          	addi	a1,a0,512
    800070d8:	0592                	slli	a1,a1,0x4
    800070da:	95c2                	add	a1,a1,a6
    800070dc:	577d                	li	a4,-1
    800070de:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800070e2:	00461713          	slli	a4,a2,0x4
    800070e6:	6290                	ld	a2,0(a3)
    800070e8:	963a                	add	a2,a2,a4
    800070ea:	03078793          	addi	a5,a5,48
    800070ee:	97c2                	add	a5,a5,a6
    800070f0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800070f2:	629c                	ld	a5,0(a3)
    800070f4:	97ba                	add	a5,a5,a4
    800070f6:	4605                	li	a2,1
    800070f8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800070fa:	629c                	ld	a5,0(a3)
    800070fc:	97ba                	add	a5,a5,a4
    800070fe:	4809                	li	a6,2
    80007100:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80007104:	629c                	ld	a5,0(a3)
    80007106:	973e                	add	a4,a4,a5
    80007108:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000710c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80007110:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80007114:	6698                	ld	a4,8(a3)
    80007116:	00275783          	lhu	a5,2(a4)
    8000711a:	8b9d                	andi	a5,a5,7
    8000711c:	0786                	slli	a5,a5,0x1
    8000711e:	97ba                	add	a5,a5,a4
    80007120:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80007124:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80007128:	6698                	ld	a4,8(a3)
    8000712a:	00275783          	lhu	a5,2(a4)
    8000712e:	2785                	addiw	a5,a5,1
    80007130:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80007134:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80007138:	100017b7          	lui	a5,0x10001
    8000713c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80007140:	004aa783          	lw	a5,4(s5)
    80007144:	02c79163          	bne	a5,a2,80007166 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80007148:	0003c917          	auipc	s2,0x3c
    8000714c:	fe090913          	addi	s2,s2,-32 # 80043128 <disk+0x2128>
  while(b->disk == 1) {
    80007150:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80007152:	85ca                	mv	a1,s2
    80007154:	8556                	mv	a0,s5
    80007156:	ffffb097          	auipc	ra,0xffffb
    8000715a:	55e080e7          	jalr	1374(ra) # 800026b4 <sleep>
  while(b->disk == 1) {
    8000715e:	004aa783          	lw	a5,4(s5)
    80007162:	fe9788e3          	beq	a5,s1,80007152 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80007166:	f8042903          	lw	s2,-128(s0)
    8000716a:	20090793          	addi	a5,s2,512
    8000716e:	00479713          	slli	a4,a5,0x4
    80007172:	0003a797          	auipc	a5,0x3a
    80007176:	e8e78793          	addi	a5,a5,-370 # 80041000 <disk>
    8000717a:	97ba                	add	a5,a5,a4
    8000717c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80007180:	0003c997          	auipc	s3,0x3c
    80007184:	e8098993          	addi	s3,s3,-384 # 80043000 <disk+0x2000>
    80007188:	00491713          	slli	a4,s2,0x4
    8000718c:	0009b783          	ld	a5,0(s3)
    80007190:	97ba                	add	a5,a5,a4
    80007192:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80007196:	854a                	mv	a0,s2
    80007198:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000719c:	00000097          	auipc	ra,0x0
    800071a0:	c5a080e7          	jalr	-934(ra) # 80006df6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800071a4:	8885                	andi	s1,s1,1
    800071a6:	f0ed                	bnez	s1,80007188 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800071a8:	0003c517          	auipc	a0,0x3c
    800071ac:	f8050513          	addi	a0,a0,-128 # 80043128 <disk+0x2128>
    800071b0:	ffffa097          	auipc	ra,0xffffa
    800071b4:	ac6080e7          	jalr	-1338(ra) # 80000c76 <release>
}
    800071b8:	70e6                	ld	ra,120(sp)
    800071ba:	7446                	ld	s0,112(sp)
    800071bc:	74a6                	ld	s1,104(sp)
    800071be:	7906                	ld	s2,96(sp)
    800071c0:	69e6                	ld	s3,88(sp)
    800071c2:	6a46                	ld	s4,80(sp)
    800071c4:	6aa6                	ld	s5,72(sp)
    800071c6:	6b06                	ld	s6,64(sp)
    800071c8:	7be2                	ld	s7,56(sp)
    800071ca:	7c42                	ld	s8,48(sp)
    800071cc:	7ca2                	ld	s9,40(sp)
    800071ce:	7d02                	ld	s10,32(sp)
    800071d0:	6de2                	ld	s11,24(sp)
    800071d2:	6109                	addi	sp,sp,128
    800071d4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800071d6:	f8042503          	lw	a0,-128(s0)
    800071da:	20050793          	addi	a5,a0,512
    800071de:	0792                	slli	a5,a5,0x4
  if(write)
    800071e0:	0003a817          	auipc	a6,0x3a
    800071e4:	e2080813          	addi	a6,a6,-480 # 80041000 <disk>
    800071e8:	00f80733          	add	a4,a6,a5
    800071ec:	01a036b3          	snez	a3,s10
    800071f0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800071f4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800071f8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800071fc:	7679                	lui	a2,0xffffe
    800071fe:	963e                	add	a2,a2,a5
    80007200:	0003c697          	auipc	a3,0x3c
    80007204:	e0068693          	addi	a3,a3,-512 # 80043000 <disk+0x2000>
    80007208:	6298                	ld	a4,0(a3)
    8000720a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000720c:	0a878593          	addi	a1,a5,168
    80007210:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80007212:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80007214:	6298                	ld	a4,0(a3)
    80007216:	9732                	add	a4,a4,a2
    80007218:	45c1                	li	a1,16
    8000721a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000721c:	6298                	ld	a4,0(a3)
    8000721e:	9732                	add	a4,a4,a2
    80007220:	4585                	li	a1,1
    80007222:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80007226:	f8442703          	lw	a4,-124(s0)
    8000722a:	628c                	ld	a1,0(a3)
    8000722c:	962e                	add	a2,a2,a1
    8000722e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffba00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80007232:	0712                	slli	a4,a4,0x4
    80007234:	6290                	ld	a2,0(a3)
    80007236:	963a                	add	a2,a2,a4
    80007238:	058a8593          	addi	a1,s5,88
    8000723c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000723e:	6294                	ld	a3,0(a3)
    80007240:	96ba                	add	a3,a3,a4
    80007242:	40000613          	li	a2,1024
    80007246:	c690                	sw	a2,8(a3)
  if(write)
    80007248:	e40d19e3          	bnez	s10,8000709a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000724c:	0003c697          	auipc	a3,0x3c
    80007250:	db46b683          	ld	a3,-588(a3) # 80043000 <disk+0x2000>
    80007254:	96ba                	add	a3,a3,a4
    80007256:	4609                	li	a2,2
    80007258:	00c69623          	sh	a2,12(a3)
    8000725c:	b5b1                	j	800070a8 <virtio_disk_rw+0xd2>

000000008000725e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000725e:	1101                	addi	sp,sp,-32
    80007260:	ec06                	sd	ra,24(sp)
    80007262:	e822                	sd	s0,16(sp)
    80007264:	e426                	sd	s1,8(sp)
    80007266:	e04a                	sd	s2,0(sp)
    80007268:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000726a:	0003c517          	auipc	a0,0x3c
    8000726e:	ebe50513          	addi	a0,a0,-322 # 80043128 <disk+0x2128>
    80007272:	ffffa097          	auipc	ra,0xffffa
    80007276:	950080e7          	jalr	-1712(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000727a:	10001737          	lui	a4,0x10001
    8000727e:	533c                	lw	a5,96(a4)
    80007280:	8b8d                	andi	a5,a5,3
    80007282:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007284:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007288:	0003c797          	auipc	a5,0x3c
    8000728c:	d7878793          	addi	a5,a5,-648 # 80043000 <disk+0x2000>
    80007290:	6b94                	ld	a3,16(a5)
    80007292:	0207d703          	lhu	a4,32(a5)
    80007296:	0026d783          	lhu	a5,2(a3)
    8000729a:	06f70163          	beq	a4,a5,800072fc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000729e:	0003a917          	auipc	s2,0x3a
    800072a2:	d6290913          	addi	s2,s2,-670 # 80041000 <disk>
    800072a6:	0003c497          	auipc	s1,0x3c
    800072aa:	d5a48493          	addi	s1,s1,-678 # 80043000 <disk+0x2000>
    __sync_synchronize();
    800072ae:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800072b2:	6898                	ld	a4,16(s1)
    800072b4:	0204d783          	lhu	a5,32(s1)
    800072b8:	8b9d                	andi	a5,a5,7
    800072ba:	078e                	slli	a5,a5,0x3
    800072bc:	97ba                	add	a5,a5,a4
    800072be:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800072c0:	20078713          	addi	a4,a5,512
    800072c4:	0712                	slli	a4,a4,0x4
    800072c6:	974a                	add	a4,a4,s2
    800072c8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800072cc:	e731                	bnez	a4,80007318 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800072ce:	20078793          	addi	a5,a5,512
    800072d2:	0792                	slli	a5,a5,0x4
    800072d4:	97ca                	add	a5,a5,s2
    800072d6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800072d8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800072dc:	ffffb097          	auipc	ra,0xffffb
    800072e0:	562080e7          	jalr	1378(ra) # 8000283e <wakeup>

    disk.used_idx += 1;
    800072e4:	0204d783          	lhu	a5,32(s1)
    800072e8:	2785                	addiw	a5,a5,1
    800072ea:	17c2                	slli	a5,a5,0x30
    800072ec:	93c1                	srli	a5,a5,0x30
    800072ee:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800072f2:	6898                	ld	a4,16(s1)
    800072f4:	00275703          	lhu	a4,2(a4)
    800072f8:	faf71be3          	bne	a4,a5,800072ae <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800072fc:	0003c517          	auipc	a0,0x3c
    80007300:	e2c50513          	addi	a0,a0,-468 # 80043128 <disk+0x2128>
    80007304:	ffffa097          	auipc	ra,0xffffa
    80007308:	972080e7          	jalr	-1678(ra) # 80000c76 <release>
}
    8000730c:	60e2                	ld	ra,24(sp)
    8000730e:	6442                	ld	s0,16(sp)
    80007310:	64a2                	ld	s1,8(sp)
    80007312:	6902                	ld	s2,0(sp)
    80007314:	6105                	addi	sp,sp,32
    80007316:	8082                	ret
      panic("virtio_disk_intr status");
    80007318:	00002517          	auipc	a0,0x2
    8000731c:	52850513          	addi	a0,a0,1320 # 80009840 <syscalls+0x408>
    80007320:	ffff9097          	auipc	ra,0xffff9
    80007324:	20a080e7          	jalr	522(ra) # 8000052a <panic>
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

0000000080008112 <start_inject_sigret>:
    80008112:	48e1                	li	a7,24
    80008114:	00000073          	ecall

0000000080008118 <end_inject_sigret>:
	...
