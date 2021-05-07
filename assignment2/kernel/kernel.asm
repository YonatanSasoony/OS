
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
    80000068:	a5c78793          	addi	a5,a5,-1444 # 80006ac0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffbb7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de278793          	addi	a5,a5,-542 # 80000e90 <main>
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
    80000122:	916080e7          	jalr	-1770(ra) # 80002a34 <either_copyin>
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
    800001b6:	880080e7          	jalr	-1920(ra) # 80001a32 <myproc>
    800001ba:	4d5c                	lw	a5,28(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	516080e7          	jalr	1302(ra) # 800026d8 <sleep>
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
    80000202:	7de080e7          	jalr	2014(ra) # 800029dc <either_copyout>
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
    8000021e:	a6e080e7          	jalr	-1426(ra) # 80000c88 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00012517          	auipc	a0,0x12
    8000022c:	f5850513          	addi	a0,a0,-168 # 80012180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a58080e7          	jalr	-1448(ra) # 80000c88 <release>
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
    800002e2:	7ae080e7          	jalr	1966(ra) # 80002a8c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00012517          	auipc	a0,0x12
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80012180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	99a080e7          	jalr	-1638(ra) # 80000c88 <release>
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
    80000436:	430080e7          	jalr	1072(ra) # 80002862 <wakeup>
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
    80000464:	0003e797          	auipc	a5,0x3e
    80000468:	4e478793          	addi	a5,a5,1252 # 8003e948 <devsw>
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
    8000055c:	cf850513          	addi	a0,a0,-776 # 80009250 <digits+0x210>
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
    8000074e:	53e080e7          	jalr	1342(ra) # 80000c88 <release>
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
    80000814:	418080e7          	jalr	1048(ra) # 80000c28 <pop_off>
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
    80000882:	fe4080e7          	jalr	-28(ra) # 80002862 <wakeup>
    
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
    8000090e:	dce080e7          	jalr	-562(ra) # 800026d8 <sleep>
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
    8000094a:	342080e7          	jalr	834(ra) # 80000c88 <release>
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
    800009c8:	2c4080e7          	jalr	708(ra) # 80000c88 <release>
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
    800009ea:	00042797          	auipc	a5,0x42
    800009ee:	61678793          	addi	a5,a5,1558 # 80043000 <end>
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
    80000a06:	2e0080e7          	jalr	736(ra) # 80000ce2 <memset>

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
    80000a2c:	260080e7          	jalr	608(ra) # 80000c88 <release>
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
    80000aba:	00042517          	auipc	a0,0x42
    80000abe:	54650513          	addi	a0,a0,1350 # 80043000 <end>
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
    80000b02:	18a080e7          	jalr	394(ra) # 80000c88 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1d6080e7          	jalr	470(ra) # 80000ce2 <memset>
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
    80000b2c:	160080e7          	jalr	352(ra) # 80000c88 <release>
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
    80000b60:	eba080e7          	jalr	-326(ra) # 80001a16 <mycpu>
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
    80000b92:	e88080e7          	jalr	-376(ra) # 80001a16 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e7c080e7          	jalr	-388(ra) # 80001a16 <mycpu>
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
    80000bb6:	e64080e7          	jalr	-412(ra) # 80001a16 <mycpu>
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
  if(holding(lk)) {
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk)) {
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
    80000bf6:	e24080e7          	jalr	-476(ra) # 80001a16 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    printf("PANIC-%s\n",lk->name); //REMOVE
    80000c06:	648c                	ld	a1,8(s1)
    80000c08:	00008517          	auipc	a0,0x8
    80000c0c:	46850513          	addi	a0,a0,1128 # 80009070 <digits+0x30>
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	964080e7          	jalr	-1692(ra) # 80000574 <printf>
    panic("acquire\n");
    80000c18:	00008517          	auipc	a0,0x8
    80000c1c:	46850513          	addi	a0,a0,1128 # 80009080 <digits+0x40>
    80000c20:	00000097          	auipc	ra,0x0
    80000c24:	90a080e7          	jalr	-1782(ra) # 8000052a <panic>

0000000080000c28 <pop_off>:

void
pop_off(void)
{
    80000c28:	1141                	addi	sp,sp,-16
    80000c2a:	e406                	sd	ra,8(sp)
    80000c2c:	e022                	sd	s0,0(sp)
    80000c2e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c30:	00001097          	auipc	ra,0x1
    80000c34:	de6080e7          	jalr	-538(ra) # 80001a16 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c38:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3e:	e78d                	bnez	a5,80000c68 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c40:	5d3c                	lw	a5,120(a0)
    80000c42:	02f05b63          	blez	a5,80000c78 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c46:	37fd                	addiw	a5,a5,-1
    80000c48:	0007871b          	sext.w	a4,a5
    80000c4c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4e:	eb09                	bnez	a4,80000c60 <pop_off+0x38>
    80000c50:	5d7c                	lw	a5,124(a0)
    80000c52:	c799                	beqz	a5,80000c60 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c60:	60a2                	ld	ra,8(sp)
    80000c62:	6402                	ld	s0,0(sp)
    80000c64:	0141                	addi	sp,sp,16
    80000c66:	8082                	ret
    panic("pop_off - interruptible");
    80000c68:	00008517          	auipc	a0,0x8
    80000c6c:	42850513          	addi	a0,a0,1064 # 80009090 <digits+0x50>
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	8ba080e7          	jalr	-1862(ra) # 8000052a <panic>
    panic("pop_off");
    80000c78:	00008517          	auipc	a0,0x8
    80000c7c:	43050513          	addi	a0,a0,1072 # 800090a8 <digits+0x68>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8aa080e7          	jalr	-1878(ra) # 8000052a <panic>

0000000080000c88 <release>:
{
    80000c88:	1101                	addi	sp,sp,-32
    80000c8a:	ec06                	sd	ra,24(sp)
    80000c8c:	e822                	sd	s0,16(sp)
    80000c8e:	e426                	sd	s1,8(sp)
    80000c90:	1000                	addi	s0,sp,32
    80000c92:	84aa                	mv	s1,a0
  if(!holding(lk)) {
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	eb4080e7          	jalr	-332(ra) # 80000b48 <holding>
    80000c9c:	c115                	beqz	a0,80000cc0 <release+0x38>
  lk->cpu = 0;
    80000c9e:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca6:	0f50000f          	fence	iorw,ow
    80000caa:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cae:	00000097          	auipc	ra,0x0
    80000cb2:	f7a080e7          	jalr	-134(ra) # 80000c28 <pop_off>
}
    80000cb6:	60e2                	ld	ra,24(sp)
    80000cb8:	6442                	ld	s0,16(sp)
    80000cba:	64a2                	ld	s1,8(sp)
    80000cbc:	6105                	addi	sp,sp,32
    80000cbe:	8082                	ret
    printf("PANIC-%s\n",lk->name); // REMOVE
    80000cc0:	648c                	ld	a1,8(s1)
    80000cc2:	00008517          	auipc	a0,0x8
    80000cc6:	3ae50513          	addi	a0,a0,942 # 80009070 <digits+0x30>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	8aa080e7          	jalr	-1878(ra) # 80000574 <printf>
    panic("release");
    80000cd2:	00008517          	auipc	a0,0x8
    80000cd6:	3de50513          	addi	a0,a0,990 # 800090b0 <digits+0x70>
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	850080e7          	jalr	-1968(ra) # 8000052a <panic>

0000000080000ce2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce2:	1141                	addi	sp,sp,-16
    80000ce4:	e422                	sd	s0,8(sp)
    80000ce6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce8:	ca19                	beqz	a2,80000cfe <memset+0x1c>
    80000cea:	87aa                	mv	a5,a0
    80000cec:	1602                	slli	a2,a2,0x20
    80000cee:	9201                	srli	a2,a2,0x20
    80000cf0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cf4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cf8:	0785                	addi	a5,a5,1
    80000cfa:	fee79de3          	bne	a5,a4,80000cf4 <memset+0x12>
  }
  return dst;
}
    80000cfe:	6422                	ld	s0,8(sp)
    80000d00:	0141                	addi	sp,sp,16
    80000d02:	8082                	ret

0000000080000d04 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d04:	1141                	addi	sp,sp,-16
    80000d06:	e422                	sd	s0,8(sp)
    80000d08:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0a:	ca05                	beqz	a2,80000d3a <memcmp+0x36>
    80000d0c:	fff6069b          	addiw	a3,a2,-1
    80000d10:	1682                	slli	a3,a3,0x20
    80000d12:	9281                	srli	a3,a3,0x20
    80000d14:	0685                	addi	a3,a3,1
    80000d16:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d18:	00054783          	lbu	a5,0(a0)
    80000d1c:	0005c703          	lbu	a4,0(a1)
    80000d20:	00e79863          	bne	a5,a4,80000d30 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d24:	0505                	addi	a0,a0,1
    80000d26:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d28:	fed518e3          	bne	a0,a3,80000d18 <memcmp+0x14>
  }

  return 0;
    80000d2c:	4501                	li	a0,0
    80000d2e:	a019                	j	80000d34 <memcmp+0x30>
      return *s1 - *s2;
    80000d30:	40e7853b          	subw	a0,a5,a4
}
    80000d34:	6422                	ld	s0,8(sp)
    80000d36:	0141                	addi	sp,sp,16
    80000d38:	8082                	ret
  return 0;
    80000d3a:	4501                	li	a0,0
    80000d3c:	bfe5                	j	80000d34 <memcmp+0x30>

0000000080000d3e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d3e:	1141                	addi	sp,sp,-16
    80000d40:	e422                	sd	s0,8(sp)
    80000d42:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d44:	02a5e563          	bltu	a1,a0,80000d6e <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d48:	fff6069b          	addiw	a3,a2,-1
    80000d4c:	ce11                	beqz	a2,80000d68 <memmove+0x2a>
    80000d4e:	1682                	slli	a3,a3,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	0685                	addi	a3,a3,1
    80000d54:	96ae                	add	a3,a3,a1
    80000d56:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d58:	0585                	addi	a1,a1,1
    80000d5a:	0785                	addi	a5,a5,1
    80000d5c:	fff5c703          	lbu	a4,-1(a1)
    80000d60:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d64:	fed59ae3          	bne	a1,a3,80000d58 <memmove+0x1a>

  return dst;
}
    80000d68:	6422                	ld	s0,8(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret
  if(s < d && s + n > d){
    80000d6e:	02061713          	slli	a4,a2,0x20
    80000d72:	9301                	srli	a4,a4,0x20
    80000d74:	00e587b3          	add	a5,a1,a4
    80000d78:	fcf578e3          	bgeu	a0,a5,80000d48 <memmove+0xa>
    d += n;
    80000d7c:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d7e:	fff6069b          	addiw	a3,a2,-1
    80000d82:	d27d                	beqz	a2,80000d68 <memmove+0x2a>
    80000d84:	02069613          	slli	a2,a3,0x20
    80000d88:	9201                	srli	a2,a2,0x20
    80000d8a:	fff64613          	not	a2,a2
    80000d8e:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d90:	17fd                	addi	a5,a5,-1
    80000d92:	177d                	addi	a4,a4,-1
    80000d94:	0007c683          	lbu	a3,0(a5)
    80000d98:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d9c:	fef61ae3          	bne	a2,a5,80000d90 <memmove+0x52>
    80000da0:	b7e1                	j	80000d68 <memmove+0x2a>

0000000080000da2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e406                	sd	ra,8(sp)
    80000da6:	e022                	sd	s0,0(sp)
    80000da8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000daa:	00000097          	auipc	ra,0x0
    80000dae:	f94080e7          	jalr	-108(ra) # 80000d3e <memmove>
}
    80000db2:	60a2                	ld	ra,8(sp)
    80000db4:	6402                	ld	s0,0(sp)
    80000db6:	0141                	addi	sp,sp,16
    80000db8:	8082                	ret

0000000080000dba <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e422                	sd	s0,8(sp)
    80000dbe:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc0:	ce11                	beqz	a2,80000ddc <strncmp+0x22>
    80000dc2:	00054783          	lbu	a5,0(a0)
    80000dc6:	cf89                	beqz	a5,80000de0 <strncmp+0x26>
    80000dc8:	0005c703          	lbu	a4,0(a1)
    80000dcc:	00f71a63          	bne	a4,a5,80000de0 <strncmp+0x26>
    n--, p++, q++;
    80000dd0:	367d                	addiw	a2,a2,-1
    80000dd2:	0505                	addi	a0,a0,1
    80000dd4:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd6:	f675                	bnez	a2,80000dc2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd8:	4501                	li	a0,0
    80000dda:	a809                	j	80000dec <strncmp+0x32>
    80000ddc:	4501                	li	a0,0
    80000dde:	a039                	j	80000dec <strncmp+0x32>
  if(n == 0)
    80000de0:	ca09                	beqz	a2,80000df2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de2:	00054503          	lbu	a0,0(a0)
    80000de6:	0005c783          	lbu	a5,0(a1)
    80000dea:	9d1d                	subw	a0,a0,a5
}
    80000dec:	6422                	ld	s0,8(sp)
    80000dee:	0141                	addi	sp,sp,16
    80000df0:	8082                	ret
    return 0;
    80000df2:	4501                	li	a0,0
    80000df4:	bfe5                	j	80000dec <strncmp+0x32>

0000000080000df6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e422                	sd	s0,8(sp)
    80000dfa:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfc:	872a                	mv	a4,a0
    80000dfe:	8832                	mv	a6,a2
    80000e00:	367d                	addiw	a2,a2,-1
    80000e02:	01005963          	blez	a6,80000e14 <strncpy+0x1e>
    80000e06:	0705                	addi	a4,a4,1
    80000e08:	0005c783          	lbu	a5,0(a1)
    80000e0c:	fef70fa3          	sb	a5,-1(a4)
    80000e10:	0585                	addi	a1,a1,1
    80000e12:	f7f5                	bnez	a5,80000dfe <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e14:	86ba                	mv	a3,a4
    80000e16:	00c05c63          	blez	a2,80000e2e <strncpy+0x38>
    *s++ = 0;
    80000e1a:	0685                	addi	a3,a3,1
    80000e1c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e20:	fff6c793          	not	a5,a3
    80000e24:	9fb9                	addw	a5,a5,a4
    80000e26:	010787bb          	addw	a5,a5,a6
    80000e2a:	fef048e3          	bgtz	a5,80000e1a <strncpy+0x24>
  return os;
}
    80000e2e:	6422                	ld	s0,8(sp)
    80000e30:	0141                	addi	sp,sp,16
    80000e32:	8082                	ret

0000000080000e34 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e34:	1141                	addi	sp,sp,-16
    80000e36:	e422                	sd	s0,8(sp)
    80000e38:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3a:	02c05363          	blez	a2,80000e60 <safestrcpy+0x2c>
    80000e3e:	fff6069b          	addiw	a3,a2,-1
    80000e42:	1682                	slli	a3,a3,0x20
    80000e44:	9281                	srli	a3,a3,0x20
    80000e46:	96ae                	add	a3,a3,a1
    80000e48:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4a:	00d58963          	beq	a1,a3,80000e5c <safestrcpy+0x28>
    80000e4e:	0585                	addi	a1,a1,1
    80000e50:	0785                	addi	a5,a5,1
    80000e52:	fff5c703          	lbu	a4,-1(a1)
    80000e56:	fee78fa3          	sb	a4,-1(a5)
    80000e5a:	fb65                	bnez	a4,80000e4a <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e60:	6422                	ld	s0,8(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret

0000000080000e66 <strlen>:

int
strlen(const char *s)
{
    80000e66:	1141                	addi	sp,sp,-16
    80000e68:	e422                	sd	s0,8(sp)
    80000e6a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6c:	00054783          	lbu	a5,0(a0)
    80000e70:	cf91                	beqz	a5,80000e8c <strlen+0x26>
    80000e72:	0505                	addi	a0,a0,1
    80000e74:	87aa                	mv	a5,a0
    80000e76:	4685                	li	a3,1
    80000e78:	9e89                	subw	a3,a3,a0
    80000e7a:	00f6853b          	addw	a0,a3,a5
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff7c703          	lbu	a4,-1(a5)
    80000e84:	fb7d                	bnez	a4,80000e7a <strlen+0x14>
    ;
  return n;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8c:	4501                	li	a0,0
    80000e8e:	bfe5                	j	80000e86 <strlen+0x20>

0000000080000e90 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e90:	1141                	addi	sp,sp,-16
    80000e92:	e406                	sd	ra,8(sp)
    80000e94:	e022                	sd	s0,0(sp)
    80000e96:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e98:	00001097          	auipc	ra,0x1
    80000e9c:	b6e080e7          	jalr	-1170(ra) # 80001a06 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea0:	00009717          	auipc	a4,0x9
    80000ea4:	17870713          	addi	a4,a4,376 # 8000a018 <started>
  if(cpuid() == 0){
    80000ea8:	c139                	beqz	a0,80000eee <main+0x5e>
    while(started == 0)
    80000eaa:	431c                	lw	a5,0(a4)
    80000eac:	2781                	sext.w	a5,a5
    80000eae:	dff5                	beqz	a5,80000eaa <main+0x1a>
      ;
    __sync_synchronize();
    80000eb0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb4:	00001097          	auipc	ra,0x1
    80000eb8:	b52080e7          	jalr	-1198(ra) # 80001a06 <cpuid>
    80000ebc:	85aa                	mv	a1,a0
    80000ebe:	00008517          	auipc	a0,0x8
    80000ec2:	21250513          	addi	a0,a0,530 # 800090d0 <digits+0x90>
    80000ec6:	fffff097          	auipc	ra,0xfffff
    80000eca:	6ae080e7          	jalr	1710(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000ece:	00000097          	auipc	ra,0x0
    80000ed2:	0d8080e7          	jalr	216(ra) # 80000fa6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed6:	00002097          	auipc	ra,0x2
    80000eda:	354080e7          	jalr	852(ra) # 8000322a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00006097          	auipc	ra,0x6
    80000ee2:	c22080e7          	jalr	-990(ra) # 80006b00 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	462080e7          	jalr	1122(ra) # 80002348 <scheduler>
    consoleinit();
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	54e080e7          	jalr	1358(ra) # 8000043c <consoleinit>
    printfinit();
    80000ef6:	00000097          	auipc	ra,0x0
    80000efa:	85e080e7          	jalr	-1954(ra) # 80000754 <printfinit>
    printf("\n");
    80000efe:	00008517          	auipc	a0,0x8
    80000f02:	35250513          	addi	a0,a0,850 # 80009250 <digits+0x210>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	66e080e7          	jalr	1646(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000f0e:	00008517          	auipc	a0,0x8
    80000f12:	1aa50513          	addi	a0,a0,426 # 800090b8 <digits+0x78>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	65e080e7          	jalr	1630(ra) # 80000574 <printf>
    printf("\n");
    80000f1e:	00008517          	auipc	a0,0x8
    80000f22:	33250513          	addi	a0,a0,818 # 80009250 <digits+0x210>
    80000f26:	fffff097          	auipc	ra,0xfffff
    80000f2a:	64e080e7          	jalr	1614(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f2e:	00000097          	auipc	ra,0x0
    80000f32:	b68080e7          	jalr	-1176(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	310080e7          	jalr	784(ra) # 80001246 <kvminit>
    kvminithart();   // turn on paging
    80000f3e:	00000097          	auipc	ra,0x0
    80000f42:	068080e7          	jalr	104(ra) # 80000fa6 <kvminithart>
    procinit();      // process table
    80000f46:	00001097          	auipc	ra,0x1
    80000f4a:	9d8080e7          	jalr	-1576(ra) # 8000191e <procinit>
    trapinit();      // trap vectors
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	2b4080e7          	jalr	692(ra) # 80003202 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	2d4080e7          	jalr	724(ra) # 8000322a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00006097          	auipc	ra,0x6
    80000f62:	b8c080e7          	jalr	-1140(ra) # 80006aea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00006097          	auipc	ra,0x6
    80000f6a:	b9a080e7          	jalr	-1126(ra) # 80006b00 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00003097          	auipc	ra,0x3
    80000f72:	cc0080e7          	jalr	-832(ra) # 80003c2e <binit>
    iinit();         // inode cache
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	352080e7          	jalr	850(ra) # 800042c8 <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	300080e7          	jalr	768(ra) # 8000527e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00006097          	auipc	ra,0x6
    80000f8a:	c9c080e7          	jalr	-868(ra) # 80006c22 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	f8a080e7          	jalr	-118(ra) # 80001f18 <userinit>
    __sync_synchronize();
    80000f96:	0ff0000f          	fence
    started = 1;
    80000f9a:	4785                	li	a5,1
    80000f9c:	00009717          	auipc	a4,0x9
    80000fa0:	06f72e23          	sw	a5,124(a4) # 8000a018 <started>
    80000fa4:	b789                	j	80000ee6 <main+0x56>

0000000080000fa6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa6:	1141                	addi	sp,sp,-16
    80000fa8:	e422                	sd	s0,8(sp)
    80000faa:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fac:	00009797          	auipc	a5,0x9
    80000fb0:	0747b783          	ld	a5,116(a5) # 8000a020 <kernel_pagetable>
    80000fb4:	83b1                	srli	a5,a5,0xc
    80000fb6:	577d                	li	a4,-1
    80000fb8:	177e                	slli	a4,a4,0x3f
    80000fba:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fbc:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc0:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc4:	6422                	ld	s0,8(sp)
    80000fc6:	0141                	addi	sp,sp,16
    80000fc8:	8082                	ret

0000000080000fca <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fca:	7139                	addi	sp,sp,-64
    80000fcc:	fc06                	sd	ra,56(sp)
    80000fce:	f822                	sd	s0,48(sp)
    80000fd0:	f426                	sd	s1,40(sp)
    80000fd2:	f04a                	sd	s2,32(sp)
    80000fd4:	ec4e                	sd	s3,24(sp)
    80000fd6:	e852                	sd	s4,16(sp)
    80000fd8:	e456                	sd	s5,8(sp)
    80000fda:	e05a                	sd	s6,0(sp)
    80000fdc:	0080                	addi	s0,sp,64
    80000fde:	84aa                	mv	s1,a0
    80000fe0:	89ae                	mv	s3,a1
    80000fe2:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe4:	57fd                	li	a5,-1
    80000fe6:	83e9                	srli	a5,a5,0x1a
    80000fe8:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fea:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fec:	04b7f263          	bgeu	a5,a1,80001030 <walk+0x66>
    panic("walk");
    80000ff0:	00008517          	auipc	a0,0x8
    80000ff4:	0f850513          	addi	a0,a0,248 # 800090e8 <digits+0xa8>
    80000ff8:	fffff097          	auipc	ra,0xfffff
    80000ffc:	532080e7          	jalr	1330(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001000:	060a8663          	beqz	s5,8000106c <walk+0xa2>
    80001004:	00000097          	auipc	ra,0x0
    80001008:	ace080e7          	jalr	-1330(ra) # 80000ad2 <kalloc>
    8000100c:	84aa                	mv	s1,a0
    8000100e:	c529                	beqz	a0,80001058 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001010:	6605                	lui	a2,0x1
    80001012:	4581                	li	a1,0
    80001014:	00000097          	auipc	ra,0x0
    80001018:	cce080e7          	jalr	-818(ra) # 80000ce2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101c:	00c4d793          	srli	a5,s1,0xc
    80001020:	07aa                	slli	a5,a5,0xa
    80001022:	0017e793          	ori	a5,a5,1
    80001026:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000102a:	3a5d                	addiw	s4,s4,-9
    8000102c:	036a0063          	beq	s4,s6,8000104c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001030:	0149d933          	srl	s2,s3,s4
    80001034:	1ff97913          	andi	s2,s2,511
    80001038:	090e                	slli	s2,s2,0x3
    8000103a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103c:	00093483          	ld	s1,0(s2)
    80001040:	0014f793          	andi	a5,s1,1
    80001044:	dfd5                	beqz	a5,80001000 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001046:	80a9                	srli	s1,s1,0xa
    80001048:	04b2                	slli	s1,s1,0xc
    8000104a:	b7c5                	j	8000102a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104c:	00c9d513          	srli	a0,s3,0xc
    80001050:	1ff57513          	andi	a0,a0,511
    80001054:	050e                	slli	a0,a0,0x3
    80001056:	9526                	add	a0,a0,s1
}
    80001058:	70e2                	ld	ra,56(sp)
    8000105a:	7442                	ld	s0,48(sp)
    8000105c:	74a2                	ld	s1,40(sp)
    8000105e:	7902                	ld	s2,32(sp)
    80001060:	69e2                	ld	s3,24(sp)
    80001062:	6a42                	ld	s4,16(sp)
    80001064:	6aa2                	ld	s5,8(sp)
    80001066:	6b02                	ld	s6,0(sp)
    80001068:	6121                	addi	sp,sp,64
    8000106a:	8082                	ret
        return 0;
    8000106c:	4501                	li	a0,0
    8000106e:	b7ed                	j	80001058 <walk+0x8e>

0000000080001070 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001070:	57fd                	li	a5,-1
    80001072:	83e9                	srli	a5,a5,0x1a
    80001074:	00b7f463          	bgeu	a5,a1,8000107c <walkaddr+0xc>
    return 0;
    80001078:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000107a:	8082                	ret
{
    8000107c:	1141                	addi	sp,sp,-16
    8000107e:	e406                	sd	ra,8(sp)
    80001080:	e022                	sd	s0,0(sp)
    80001082:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001084:	4601                	li	a2,0
    80001086:	00000097          	auipc	ra,0x0
    8000108a:	f44080e7          	jalr	-188(ra) # 80000fca <walk>
  if(pte == 0)
    8000108e:	c105                	beqz	a0,800010ae <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001090:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001092:	0117f693          	andi	a3,a5,17
    80001096:	4745                	li	a4,17
    return 0;
    80001098:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000109a:	00e68663          	beq	a3,a4,800010a6 <walkaddr+0x36>
}
    8000109e:	60a2                	ld	ra,8(sp)
    800010a0:	6402                	ld	s0,0(sp)
    800010a2:	0141                	addi	sp,sp,16
    800010a4:	8082                	ret
  pa = PTE2PA(*pte);
    800010a6:	00a7d513          	srli	a0,a5,0xa
    800010aa:	0532                	slli	a0,a0,0xc
  return pa;
    800010ac:	bfcd                	j	8000109e <walkaddr+0x2e>
    return 0;
    800010ae:	4501                	li	a0,0
    800010b0:	b7fd                	j	8000109e <walkaddr+0x2e>

00000000800010b2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b2:	715d                	addi	sp,sp,-80
    800010b4:	e486                	sd	ra,72(sp)
    800010b6:	e0a2                	sd	s0,64(sp)
    800010b8:	fc26                	sd	s1,56(sp)
    800010ba:	f84a                	sd	s2,48(sp)
    800010bc:	f44e                	sd	s3,40(sp)
    800010be:	f052                	sd	s4,32(sp)
    800010c0:	ec56                	sd	s5,24(sp)
    800010c2:	e85a                	sd	s6,16(sp)
    800010c4:	e45e                	sd	s7,8(sp)
    800010c6:	0880                	addi	s0,sp,80
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010cc:	777d                	lui	a4,0xfffff
    800010ce:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	167d                	addi	a2,a2,-1
    800010d4:	00b609b3          	add	s3,a2,a1
    800010d8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010dc:	893e                	mv	s2,a5
    800010de:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010e8:	4605                	li	a2,1
    800010ea:	85ca                	mv	a1,s2
    800010ec:	8556                	mv	a0,s5
    800010ee:	00000097          	auipc	ra,0x0
    800010f2:	edc080e7          	jalr	-292(ra) # 80000fca <walk>
    800010f6:	c51d                	beqz	a0,80001124 <mappages+0x72>
    if(*pte & PTE_V)
    800010f8:	611c                	ld	a5,0(a0)
    800010fa:	8b85                	andi	a5,a5,1
    800010fc:	ef81                	bnez	a5,80001114 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010fe:	80b1                	srli	s1,s1,0xc
    80001100:	04aa                	slli	s1,s1,0xa
    80001102:	0164e4b3          	or	s1,s1,s6
    80001106:	0014e493          	ori	s1,s1,1
    8000110a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000110c:	03390863          	beq	s2,s3,8000113c <mappages+0x8a>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001112:	bfc9                	j	800010e4 <mappages+0x32>
      panic("remap");
    80001114:	00008517          	auipc	a0,0x8
    80001118:	fdc50513          	addi	a0,a0,-36 # 800090f0 <digits+0xb0>
    8000111c:	fffff097          	auipc	ra,0xfffff
    80001120:	40e080e7          	jalr	1038(ra) # 8000052a <panic>
      return -1;
    80001124:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001126:	60a6                	ld	ra,72(sp)
    80001128:	6406                	ld	s0,64(sp)
    8000112a:	74e2                	ld	s1,56(sp)
    8000112c:	7942                	ld	s2,48(sp)
    8000112e:	79a2                	ld	s3,40(sp)
    80001130:	7a02                	ld	s4,32(sp)
    80001132:	6ae2                	ld	s5,24(sp)
    80001134:	6b42                	ld	s6,16(sp)
    80001136:	6ba2                	ld	s7,8(sp)
    80001138:	6161                	addi	sp,sp,80
    8000113a:	8082                	ret
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	b7e5                	j	80001126 <mappages+0x74>

0000000080001140 <kvmmap>:
{
    80001140:	1141                	addi	sp,sp,-16
    80001142:	e406                	sd	ra,8(sp)
    80001144:	e022                	sd	s0,0(sp)
    80001146:	0800                	addi	s0,sp,16
    80001148:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000114a:	86b2                	mv	a3,a2
    8000114c:	863e                	mv	a2,a5
    8000114e:	00000097          	auipc	ra,0x0
    80001152:	f64080e7          	jalr	-156(ra) # 800010b2 <mappages>
    80001156:	e509                	bnez	a0,80001160 <kvmmap+0x20>
}
    80001158:	60a2                	ld	ra,8(sp)
    8000115a:	6402                	ld	s0,0(sp)
    8000115c:	0141                	addi	sp,sp,16
    8000115e:	8082                	ret
    panic("kvmmap");
    80001160:	00008517          	auipc	a0,0x8
    80001164:	f9850513          	addi	a0,a0,-104 # 800090f8 <digits+0xb8>
    80001168:	fffff097          	auipc	ra,0xfffff
    8000116c:	3c2080e7          	jalr	962(ra) # 8000052a <panic>

0000000080001170 <kvmmake>:
{
    80001170:	1101                	addi	sp,sp,-32
    80001172:	ec06                	sd	ra,24(sp)
    80001174:	e822                	sd	s0,16(sp)
    80001176:	e426                	sd	s1,8(sp)
    80001178:	e04a                	sd	s2,0(sp)
    8000117a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	956080e7          	jalr	-1706(ra) # 80000ad2 <kalloc>
    80001184:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001186:	6605                	lui	a2,0x1
    80001188:	4581                	li	a1,0
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	b58080e7          	jalr	-1192(ra) # 80000ce2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001192:	4719                	li	a4,6
    80001194:	6685                	lui	a3,0x1
    80001196:	10000637          	lui	a2,0x10000
    8000119a:	100005b7          	lui	a1,0x10000
    8000119e:	8526                	mv	a0,s1
    800011a0:	00000097          	auipc	ra,0x0
    800011a4:	fa0080e7          	jalr	-96(ra) # 80001140 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a8:	4719                	li	a4,6
    800011aa:	6685                	lui	a3,0x1
    800011ac:	10001637          	lui	a2,0x10001
    800011b0:	100015b7          	lui	a1,0x10001
    800011b4:	8526                	mv	a0,s1
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	f8a080e7          	jalr	-118(ra) # 80001140 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011be:	4719                	li	a4,6
    800011c0:	004006b7          	lui	a3,0x400
    800011c4:	0c000637          	lui	a2,0xc000
    800011c8:	0c0005b7          	lui	a1,0xc000
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f72080e7          	jalr	-142(ra) # 80001140 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d6:	00008917          	auipc	s2,0x8
    800011da:	e2a90913          	addi	s2,s2,-470 # 80009000 <etext>
    800011de:	4729                	li	a4,10
    800011e0:	80008697          	auipc	a3,0x80008
    800011e4:	e2068693          	addi	a3,a3,-480 # 9000 <_entry-0x7fff7000>
    800011e8:	4605                	li	a2,1
    800011ea:	067e                	slli	a2,a2,0x1f
    800011ec:	85b2                	mv	a1,a2
    800011ee:	8526                	mv	a0,s1
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	f50080e7          	jalr	-176(ra) # 80001140 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f8:	4719                	li	a4,6
    800011fa:	46c5                	li	a3,17
    800011fc:	06ee                	slli	a3,a3,0x1b
    800011fe:	412686b3          	sub	a3,a3,s2
    80001202:	864a                	mv	a2,s2
    80001204:	85ca                	mv	a1,s2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f38080e7          	jalr	-200(ra) # 80001140 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001210:	4729                	li	a4,10
    80001212:	6685                	lui	a3,0x1
    80001214:	00007617          	auipc	a2,0x7
    80001218:	dec60613          	addi	a2,a2,-532 # 80008000 <_trampoline>
    8000121c:	040005b7          	lui	a1,0x4000
    80001220:	15fd                	addi	a1,a1,-1
    80001222:	05b2                	slli	a1,a1,0xc
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f1a080e7          	jalr	-230(ra) # 80001140 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122e:	8526                	mv	a0,s1
    80001230:	00000097          	auipc	ra,0x0
    80001234:	640080e7          	jalr	1600(ra) # 80001870 <proc_mapstacks>
}
    80001238:	8526                	mv	a0,s1
    8000123a:	60e2                	ld	ra,24(sp)
    8000123c:	6442                	ld	s0,16(sp)
    8000123e:	64a2                	ld	s1,8(sp)
    80001240:	6902                	ld	s2,0(sp)
    80001242:	6105                	addi	sp,sp,32
    80001244:	8082                	ret

0000000080001246 <kvminit>:
{
    80001246:	1141                	addi	sp,sp,-16
    80001248:	e406                	sd	ra,8(sp)
    8000124a:	e022                	sd	s0,0(sp)
    8000124c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	f22080e7          	jalr	-222(ra) # 80001170 <kvmmake>
    80001256:	00009797          	auipc	a5,0x9
    8000125a:	dca7b523          	sd	a0,-566(a5) # 8000a020 <kernel_pagetable>
}
    8000125e:	60a2                	ld	ra,8(sp)
    80001260:	6402                	ld	s0,0(sp)
    80001262:	0141                	addi	sp,sp,16
    80001264:	8082                	ret

0000000080001266 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001266:	715d                	addi	sp,sp,-80
    80001268:	e486                	sd	ra,72(sp)
    8000126a:	e0a2                	sd	s0,64(sp)
    8000126c:	fc26                	sd	s1,56(sp)
    8000126e:	f84a                	sd	s2,48(sp)
    80001270:	f44e                	sd	s3,40(sp)
    80001272:	f052                	sd	s4,32(sp)
    80001274:	ec56                	sd	s5,24(sp)
    80001276:	e85a                	sd	s6,16(sp)
    80001278:	e45e                	sd	s7,8(sp)
    8000127a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127c:	03459793          	slli	a5,a1,0x34
    80001280:	e795                	bnez	a5,800012ac <uvmunmap+0x46>
    80001282:	8a2a                	mv	s4,a0
    80001284:	892e                	mv	s2,a1
    80001286:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001288:	0632                	slli	a2,a2,0xc
    8000128a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001290:	6b05                	lui	s6,0x1
    80001292:	0735e263          	bltu	a1,s3,800012f6 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001296:	60a6                	ld	ra,72(sp)
    80001298:	6406                	ld	s0,64(sp)
    8000129a:	74e2                	ld	s1,56(sp)
    8000129c:	7942                	ld	s2,48(sp)
    8000129e:	79a2                	ld	s3,40(sp)
    800012a0:	7a02                	ld	s4,32(sp)
    800012a2:	6ae2                	ld	s5,24(sp)
    800012a4:	6b42                	ld	s6,16(sp)
    800012a6:	6ba2                	ld	s7,8(sp)
    800012a8:	6161                	addi	sp,sp,80
    800012aa:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ac:	00008517          	auipc	a0,0x8
    800012b0:	e5450513          	addi	a0,a0,-428 # 80009100 <digits+0xc0>
    800012b4:	fffff097          	auipc	ra,0xfffff
    800012b8:	276080e7          	jalr	630(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012bc:	00008517          	auipc	a0,0x8
    800012c0:	e5c50513          	addi	a0,a0,-420 # 80009118 <digits+0xd8>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	266080e7          	jalr	614(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012cc:	00008517          	auipc	a0,0x8
    800012d0:	e5c50513          	addi	a0,a0,-420 # 80009128 <digits+0xe8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	256080e7          	jalr	598(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012dc:	00008517          	auipc	a0,0x8
    800012e0:	e6450513          	addi	a0,a0,-412 # 80009140 <digits+0x100>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	246080e7          	jalr	582(ra) # 8000052a <panic>
    *pte = 0;
    800012ec:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f0:	995a                	add	s2,s2,s6
    800012f2:	fb3972e3          	bgeu	s2,s3,80001296 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f6:	4601                	li	a2,0
    800012f8:	85ca                	mv	a1,s2
    800012fa:	8552                	mv	a0,s4
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	cce080e7          	jalr	-818(ra) # 80000fca <walk>
    80001304:	84aa                	mv	s1,a0
    80001306:	d95d                	beqz	a0,800012bc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001308:	6108                	ld	a0,0(a0)
    8000130a:	00157793          	andi	a5,a0,1
    8000130e:	dfdd                	beqz	a5,800012cc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001310:	3ff57793          	andi	a5,a0,1023
    80001314:	fd7784e3          	beq	a5,s7,800012dc <uvmunmap+0x76>
    if(do_free){
    80001318:	fc0a8ae3          	beqz	s5,800012ec <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131e:	0532                	slli	a0,a0,0xc
    80001320:	fffff097          	auipc	ra,0xfffff
    80001324:	6b6080e7          	jalr	1718(ra) # 800009d6 <kfree>
    80001328:	b7d1                	j	800012ec <uvmunmap+0x86>

000000008000132a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000132a:	1101                	addi	sp,sp,-32
    8000132c:	ec06                	sd	ra,24(sp)
    8000132e:	e822                	sd	s0,16(sp)
    80001330:	e426                	sd	s1,8(sp)
    80001332:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	79e080e7          	jalr	1950(ra) # 80000ad2 <kalloc>
    8000133c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133e:	c519                	beqz	a0,8000134c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001340:	6605                	lui	a2,0x1
    80001342:	4581                	li	a1,0
    80001344:	00000097          	auipc	ra,0x0
    80001348:	99e080e7          	jalr	-1634(ra) # 80000ce2 <memset>
  return pagetable;
}
    8000134c:	8526                	mv	a0,s1
    8000134e:	60e2                	ld	ra,24(sp)
    80001350:	6442                	ld	s0,16(sp)
    80001352:	64a2                	ld	s1,8(sp)
    80001354:	6105                	addi	sp,sp,32
    80001356:	8082                	ret

0000000080001358 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001358:	7179                	addi	sp,sp,-48
    8000135a:	f406                	sd	ra,40(sp)
    8000135c:	f022                	sd	s0,32(sp)
    8000135e:	ec26                	sd	s1,24(sp)
    80001360:	e84a                	sd	s2,16(sp)
    80001362:	e44e                	sd	s3,8(sp)
    80001364:	e052                	sd	s4,0(sp)
    80001366:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001368:	6785                	lui	a5,0x1
    8000136a:	04f67863          	bgeu	a2,a5,800013ba <uvminit+0x62>
    8000136e:	8a2a                	mv	s4,a0
    80001370:	89ae                	mv	s3,a1
    80001372:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001374:	fffff097          	auipc	ra,0xfffff
    80001378:	75e080e7          	jalr	1886(ra) # 80000ad2 <kalloc>
    8000137c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137e:	6605                	lui	a2,0x1
    80001380:	4581                	li	a1,0
    80001382:	00000097          	auipc	ra,0x0
    80001386:	960080e7          	jalr	-1696(ra) # 80000ce2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000138a:	4779                	li	a4,30
    8000138c:	86ca                	mv	a3,s2
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	8552                	mv	a0,s4
    80001394:	00000097          	auipc	ra,0x0
    80001398:	d1e080e7          	jalr	-738(ra) # 800010b2 <mappages>
  memmove(mem, src, sz);
    8000139c:	8626                	mv	a2,s1
    8000139e:	85ce                	mv	a1,s3
    800013a0:	854a                	mv	a0,s2
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	99c080e7          	jalr	-1636(ra) # 80000d3e <memmove>
}
    800013aa:	70a2                	ld	ra,40(sp)
    800013ac:	7402                	ld	s0,32(sp)
    800013ae:	64e2                	ld	s1,24(sp)
    800013b0:	6942                	ld	s2,16(sp)
    800013b2:	69a2                	ld	s3,8(sp)
    800013b4:	6a02                	ld	s4,0(sp)
    800013b6:	6145                	addi	sp,sp,48
    800013b8:	8082                	ret
    panic("inituvm: more than a page");
    800013ba:	00008517          	auipc	a0,0x8
    800013be:	d9e50513          	addi	a0,a0,-610 # 80009158 <digits+0x118>
    800013c2:	fffff097          	auipc	ra,0xfffff
    800013c6:	168080e7          	jalr	360(ra) # 8000052a <panic>

00000000800013ca <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ca:	1101                	addi	sp,sp,-32
    800013cc:	ec06                	sd	ra,24(sp)
    800013ce:	e822                	sd	s0,16(sp)
    800013d0:	e426                	sd	s1,8(sp)
    800013d2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d6:	00b67d63          	bgeu	a2,a1,800013f0 <uvmdealloc+0x26>
    800013da:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013dc:	6785                	lui	a5,0x1
    800013de:	17fd                	addi	a5,a5,-1
    800013e0:	00f60733          	add	a4,a2,a5
    800013e4:	767d                	lui	a2,0xfffff
    800013e6:	8f71                	and	a4,a4,a2
    800013e8:	97ae                	add	a5,a5,a1
    800013ea:	8ff1                	and	a5,a5,a2
    800013ec:	00f76863          	bltu	a4,a5,800013fc <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013f0:	8526                	mv	a0,s1
    800013f2:	60e2                	ld	ra,24(sp)
    800013f4:	6442                	ld	s0,16(sp)
    800013f6:	64a2                	ld	s1,8(sp)
    800013f8:	6105                	addi	sp,sp,32
    800013fa:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fc:	8f99                	sub	a5,a5,a4
    800013fe:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001400:	4685                	li	a3,1
    80001402:	0007861b          	sext.w	a2,a5
    80001406:	85ba                	mv	a1,a4
    80001408:	00000097          	auipc	ra,0x0
    8000140c:	e5e080e7          	jalr	-418(ra) # 80001266 <uvmunmap>
    80001410:	b7c5                	j	800013f0 <uvmdealloc+0x26>

0000000080001412 <uvmalloc>:
  if(newsz < oldsz)
    80001412:	0ab66163          	bltu	a2,a1,800014b4 <uvmalloc+0xa2>
{
    80001416:	7139                	addi	sp,sp,-64
    80001418:	fc06                	sd	ra,56(sp)
    8000141a:	f822                	sd	s0,48(sp)
    8000141c:	f426                	sd	s1,40(sp)
    8000141e:	f04a                	sd	s2,32(sp)
    80001420:	ec4e                	sd	s3,24(sp)
    80001422:	e852                	sd	s4,16(sp)
    80001424:	e456                	sd	s5,8(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f063          	bgeu	s3,a2,800014b8 <uvmalloc+0xa6>
    8000143c:	894e                	mv	s2,s3
    mem = kalloc();
    8000143e:	fffff097          	auipc	ra,0xfffff
    80001442:	694080e7          	jalr	1684(ra) # 80000ad2 <kalloc>
    80001446:	84aa                	mv	s1,a0
    if(mem == 0){
    80001448:	c51d                	beqz	a0,80001476 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000144a:	6605                	lui	a2,0x1
    8000144c:	4581                	li	a1,0
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	894080e7          	jalr	-1900(ra) # 80000ce2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001456:	4779                	li	a4,30
    80001458:	86a6                	mv	a3,s1
    8000145a:	6605                	lui	a2,0x1
    8000145c:	85ca                	mv	a1,s2
    8000145e:	8556                	mv	a0,s5
    80001460:	00000097          	auipc	ra,0x0
    80001464:	c52080e7          	jalr	-942(ra) # 800010b2 <mappages>
    80001468:	e905                	bnez	a0,80001498 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146a:	6785                	lui	a5,0x1
    8000146c:	993e                	add	s2,s2,a5
    8000146e:	fd4968e3          	bltu	s2,s4,8000143e <uvmalloc+0x2c>
  return newsz;
    80001472:	8552                	mv	a0,s4
    80001474:	a809                	j	80001486 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001476:	864e                	mv	a2,s3
    80001478:	85ca                	mv	a1,s2
    8000147a:	8556                	mv	a0,s5
    8000147c:	00000097          	auipc	ra,0x0
    80001480:	f4e080e7          	jalr	-178(ra) # 800013ca <uvmdealloc>
      return 0;
    80001484:	4501                	li	a0,0
}
    80001486:	70e2                	ld	ra,56(sp)
    80001488:	7442                	ld	s0,48(sp)
    8000148a:	74a2                	ld	s1,40(sp)
    8000148c:	7902                	ld	s2,32(sp)
    8000148e:	69e2                	ld	s3,24(sp)
    80001490:	6a42                	ld	s4,16(sp)
    80001492:	6aa2                	ld	s5,8(sp)
    80001494:	6121                	addi	sp,sp,64
    80001496:	8082                	ret
      kfree(mem);
    80001498:	8526                	mv	a0,s1
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	53c080e7          	jalr	1340(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f22080e7          	jalr	-222(ra) # 800013ca <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	bfd1                	j	80001486 <uvmalloc+0x74>
    return oldsz;
    800014b4:	852e                	mv	a0,a1
}
    800014b6:	8082                	ret
  return newsz;
    800014b8:	8532                	mv	a0,a2
    800014ba:	b7f1                	j	80001486 <uvmalloc+0x74>

00000000800014bc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014bc:	7179                	addi	sp,sp,-48
    800014be:	f406                	sd	ra,40(sp)
    800014c0:	f022                	sd	s0,32(sp)
    800014c2:	ec26                	sd	s1,24(sp)
    800014c4:	e84a                	sd	s2,16(sp)
    800014c6:	e44e                	sd	s3,8(sp)
    800014c8:	e052                	sd	s4,0(sp)
    800014ca:	1800                	addi	s0,sp,48
    800014cc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ce:	84aa                	mv	s1,a0
    800014d0:	6905                	lui	s2,0x1
    800014d2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	4985                	li	s3,1
    800014d6:	a821                	j	800014ee <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014da:	0532                	slli	a0,a0,0xc
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	fe0080e7          	jalr	-32(ra) # 800014bc <freewalk>
      pagetable[i] = 0;
    800014e4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014e8:	04a1                	addi	s1,s1,8
    800014ea:	03248163          	beq	s1,s2,8000150c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014ee:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f0:	00f57793          	andi	a5,a0,15
    800014f4:	ff3782e3          	beq	a5,s3,800014d8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014f8:	8905                	andi	a0,a0,1
    800014fa:	d57d                	beqz	a0,800014e8 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014fc:	00008517          	auipc	a0,0x8
    80001500:	c7c50513          	addi	a0,a0,-900 # 80009178 <digits+0x138>
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	026080e7          	jalr	38(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    8000150c:	8552                	mv	a0,s4
    8000150e:	fffff097          	auipc	ra,0xfffff
    80001512:	4c8080e7          	jalr	1224(ra) # 800009d6 <kfree>
}
    80001516:	70a2                	ld	ra,40(sp)
    80001518:	7402                	ld	s0,32(sp)
    8000151a:	64e2                	ld	s1,24(sp)
    8000151c:	6942                	ld	s2,16(sp)
    8000151e:	69a2                	ld	s3,8(sp)
    80001520:	6a02                	ld	s4,0(sp)
    80001522:	6145                	addi	sp,sp,48
    80001524:	8082                	ret

0000000080001526 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001526:	1101                	addi	sp,sp,-32
    80001528:	ec06                	sd	ra,24(sp)
    8000152a:	e822                	sd	s0,16(sp)
    8000152c:	e426                	sd	s1,8(sp)
    8000152e:	1000                	addi	s0,sp,32
    80001530:	84aa                	mv	s1,a0
  if(sz > 0)
    80001532:	e999                	bnez	a1,80001548 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001534:	8526                	mv	a0,s1
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f86080e7          	jalr	-122(ra) # 800014bc <freewalk>
}
    8000153e:	60e2                	ld	ra,24(sp)
    80001540:	6442                	ld	s0,16(sp)
    80001542:	64a2                	ld	s1,8(sp)
    80001544:	6105                	addi	sp,sp,32
    80001546:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001548:	6605                	lui	a2,0x1
    8000154a:	167d                	addi	a2,a2,-1
    8000154c:	962e                	add	a2,a2,a1
    8000154e:	4685                	li	a3,1
    80001550:	8231                	srli	a2,a2,0xc
    80001552:	4581                	li	a1,0
    80001554:	00000097          	auipc	ra,0x0
    80001558:	d12080e7          	jalr	-750(ra) # 80001266 <uvmunmap>
    8000155c:	bfe1                	j	80001534 <uvmfree+0xe>

000000008000155e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000155e:	c679                	beqz	a2,8000162c <uvmcopy+0xce>
{
    80001560:	715d                	addi	sp,sp,-80
    80001562:	e486                	sd	ra,72(sp)
    80001564:	e0a2                	sd	s0,64(sp)
    80001566:	fc26                	sd	s1,56(sp)
    80001568:	f84a                	sd	s2,48(sp)
    8000156a:	f44e                	sd	s3,40(sp)
    8000156c:	f052                	sd	s4,32(sp)
    8000156e:	ec56                	sd	s5,24(sp)
    80001570:	e85a                	sd	s6,16(sp)
    80001572:	e45e                	sd	s7,8(sp)
    80001574:	0880                	addi	s0,sp,80
    80001576:	8b2a                	mv	s6,a0
    80001578:	8aae                	mv	s5,a1
    8000157a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000157c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000157e:	4601                	li	a2,0
    80001580:	85ce                	mv	a1,s3
    80001582:	855a                	mv	a0,s6
    80001584:	00000097          	auipc	ra,0x0
    80001588:	a46080e7          	jalr	-1466(ra) # 80000fca <walk>
    8000158c:	c531                	beqz	a0,800015d8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000158e:	6118                	ld	a4,0(a0)
    80001590:	00177793          	andi	a5,a4,1
    80001594:	cbb1                	beqz	a5,800015e8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001596:	00a75593          	srli	a1,a4,0xa
    8000159a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000159e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	530080e7          	jalr	1328(ra) # 80000ad2 <kalloc>
    800015aa:	892a                	mv	s2,a0
    800015ac:	c939                	beqz	a0,80001602 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	85de                	mv	a1,s7
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	78c080e7          	jalr	1932(ra) # 80000d3e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ba:	8726                	mv	a4,s1
    800015bc:	86ca                	mv	a3,s2
    800015be:	6605                	lui	a2,0x1
    800015c0:	85ce                	mv	a1,s3
    800015c2:	8556                	mv	a0,s5
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	aee080e7          	jalr	-1298(ra) # 800010b2 <mappages>
    800015cc:	e515                	bnez	a0,800015f8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015ce:	6785                	lui	a5,0x1
    800015d0:	99be                	add	s3,s3,a5
    800015d2:	fb49e6e3          	bltu	s3,s4,8000157e <uvmcopy+0x20>
    800015d6:	a081                	j	80001616 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d8:	00008517          	auipc	a0,0x8
    800015dc:	bb050513          	addi	a0,a0,-1104 # 80009188 <digits+0x148>
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	f4a080e7          	jalr	-182(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015e8:	00008517          	auipc	a0,0x8
    800015ec:	bc050513          	addi	a0,a0,-1088 # 800091a8 <digits+0x168>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f3a080e7          	jalr	-198(ra) # 8000052a <panic>
      kfree(mem);
    800015f8:	854a                	mv	a0,s2
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	3dc080e7          	jalr	988(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001602:	4685                	li	a3,1
    80001604:	00c9d613          	srli	a2,s3,0xc
    80001608:	4581                	li	a1,0
    8000160a:	8556                	mv	a0,s5
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	c5a080e7          	jalr	-934(ra) # 80001266 <uvmunmap>
  return -1;
    80001614:	557d                	li	a0,-1
}
    80001616:	60a6                	ld	ra,72(sp)
    80001618:	6406                	ld	s0,64(sp)
    8000161a:	74e2                	ld	s1,56(sp)
    8000161c:	7942                	ld	s2,48(sp)
    8000161e:	79a2                	ld	s3,40(sp)
    80001620:	7a02                	ld	s4,32(sp)
    80001622:	6ae2                	ld	s5,24(sp)
    80001624:	6b42                	ld	s6,16(sp)
    80001626:	6ba2                	ld	s7,8(sp)
    80001628:	6161                	addi	sp,sp,80
    8000162a:	8082                	ret
  return 0;
    8000162c:	4501                	li	a0,0
}
    8000162e:	8082                	ret

0000000080001630 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001630:	1141                	addi	sp,sp,-16
    80001632:	e406                	sd	ra,8(sp)
    80001634:	e022                	sd	s0,0(sp)
    80001636:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001638:	4601                	li	a2,0
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	990080e7          	jalr	-1648(ra) # 80000fca <walk>
  if(pte == 0)
    80001642:	c901                	beqz	a0,80001652 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001644:	611c                	ld	a5,0(a0)
    80001646:	9bbd                	andi	a5,a5,-17
    80001648:	e11c                	sd	a5,0(a0)
}
    8000164a:	60a2                	ld	ra,8(sp)
    8000164c:	6402                	ld	s0,0(sp)
    8000164e:	0141                	addi	sp,sp,16
    80001650:	8082                	ret
    panic("uvmclear");
    80001652:	00008517          	auipc	a0,0x8
    80001656:	b7650513          	addi	a0,a0,-1162 # 800091c8 <digits+0x188>
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	ed0080e7          	jalr	-304(ra) # 8000052a <panic>

0000000080001662 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001662:	c6bd                	beqz	a3,800016d0 <copyout+0x6e>
{
    80001664:	715d                	addi	sp,sp,-80
    80001666:	e486                	sd	ra,72(sp)
    80001668:	e0a2                	sd	s0,64(sp)
    8000166a:	fc26                	sd	s1,56(sp)
    8000166c:	f84a                	sd	s2,48(sp)
    8000166e:	f44e                	sd	s3,40(sp)
    80001670:	f052                	sd	s4,32(sp)
    80001672:	ec56                	sd	s5,24(sp)
    80001674:	e85a                	sd	s6,16(sp)
    80001676:	e45e                	sd	s7,8(sp)
    80001678:	e062                	sd	s8,0(sp)
    8000167a:	0880                	addi	s0,sp,80
    8000167c:	8b2a                	mv	s6,a0
    8000167e:	8c2e                	mv	s8,a1
    80001680:	8a32                	mv	s4,a2
    80001682:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001684:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001686:	6a85                	lui	s5,0x1
    80001688:	a015                	j	800016ac <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168a:	9562                	add	a0,a0,s8
    8000168c:	0004861b          	sext.w	a2,s1
    80001690:	85d2                	mv	a1,s4
    80001692:	41250533          	sub	a0,a0,s2
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	6a8080e7          	jalr	1704(ra) # 80000d3e <memmove>

    len -= n;
    8000169e:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a8:	02098263          	beqz	s3,800016cc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ac:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b0:	85ca                	mv	a1,s2
    800016b2:	855a                	mv	a0,s6
    800016b4:	00000097          	auipc	ra,0x0
    800016b8:	9bc080e7          	jalr	-1604(ra) # 80001070 <walkaddr>
    if(pa0 == 0)
    800016bc:	cd01                	beqz	a0,800016d4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016be:	418904b3          	sub	s1,s2,s8
    800016c2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016c4:	fc99f3e3          	bgeu	s3,s1,8000168a <copyout+0x28>
    800016c8:	84ce                	mv	s1,s3
    800016ca:	b7c1                	j	8000168a <copyout+0x28>
  }
  return 0;
    800016cc:	4501                	li	a0,0
    800016ce:	a021                	j	800016d6 <copyout+0x74>
    800016d0:	4501                	li	a0,0
}
    800016d2:	8082                	ret
      return -1;
    800016d4:	557d                	li	a0,-1
}
    800016d6:	60a6                	ld	ra,72(sp)
    800016d8:	6406                	ld	s0,64(sp)
    800016da:	74e2                	ld	s1,56(sp)
    800016dc:	7942                	ld	s2,48(sp)
    800016de:	79a2                	ld	s3,40(sp)
    800016e0:	7a02                	ld	s4,32(sp)
    800016e2:	6ae2                	ld	s5,24(sp)
    800016e4:	6b42                	ld	s6,16(sp)
    800016e6:	6ba2                	ld	s7,8(sp)
    800016e8:	6c02                	ld	s8,0(sp)
    800016ea:	6161                	addi	sp,sp,80
    800016ec:	8082                	ret

00000000800016ee <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ee:	caa5                	beqz	a3,8000175e <copyin+0x70>
{
    800016f0:	715d                	addi	sp,sp,-80
    800016f2:	e486                	sd	ra,72(sp)
    800016f4:	e0a2                	sd	s0,64(sp)
    800016f6:	fc26                	sd	s1,56(sp)
    800016f8:	f84a                	sd	s2,48(sp)
    800016fa:	f44e                	sd	s3,40(sp)
    800016fc:	f052                	sd	s4,32(sp)
    800016fe:	ec56                	sd	s5,24(sp)
    80001700:	e85a                	sd	s6,16(sp)
    80001702:	e45e                	sd	s7,8(sp)
    80001704:	e062                	sd	s8,0(sp)
    80001706:	0880                	addi	s0,sp,80
    80001708:	8b2a                	mv	s6,a0
    8000170a:	8a2e                	mv	s4,a1
    8000170c:	8c32                	mv	s8,a2
    8000170e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001710:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001712:	6a85                	lui	s5,0x1
    80001714:	a01d                	j	8000173a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001716:	018505b3          	add	a1,a0,s8
    8000171a:	0004861b          	sext.w	a2,s1
    8000171e:	412585b3          	sub	a1,a1,s2
    80001722:	8552                	mv	a0,s4
    80001724:	fffff097          	auipc	ra,0xfffff
    80001728:	61a080e7          	jalr	1562(ra) # 80000d3e <memmove>

    len -= n;
    8000172c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001730:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001732:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001736:	02098263          	beqz	s3,8000175a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000173e:	85ca                	mv	a1,s2
    80001740:	855a                	mv	a0,s6
    80001742:	00000097          	auipc	ra,0x0
    80001746:	92e080e7          	jalr	-1746(ra) # 80001070 <walkaddr>
    if(pa0 == 0)
    8000174a:	cd01                	beqz	a0,80001762 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000174c:	418904b3          	sub	s1,s2,s8
    80001750:	94d6                	add	s1,s1,s5
    if(n > len)
    80001752:	fc99f2e3          	bgeu	s3,s1,80001716 <copyin+0x28>
    80001756:	84ce                	mv	s1,s3
    80001758:	bf7d                	j	80001716 <copyin+0x28>
  }
  return 0;
    8000175a:	4501                	li	a0,0
    8000175c:	a021                	j	80001764 <copyin+0x76>
    8000175e:	4501                	li	a0,0
}
    80001760:	8082                	ret
      return -1;
    80001762:	557d                	li	a0,-1
}
    80001764:	60a6                	ld	ra,72(sp)
    80001766:	6406                	ld	s0,64(sp)
    80001768:	74e2                	ld	s1,56(sp)
    8000176a:	7942                	ld	s2,48(sp)
    8000176c:	79a2                	ld	s3,40(sp)
    8000176e:	7a02                	ld	s4,32(sp)
    80001770:	6ae2                	ld	s5,24(sp)
    80001772:	6b42                	ld	s6,16(sp)
    80001774:	6ba2                	ld	s7,8(sp)
    80001776:	6c02                	ld	s8,0(sp)
    80001778:	6161                	addi	sp,sp,80
    8000177a:	8082                	ret

000000008000177c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000177c:	c6c5                	beqz	a3,80001824 <copyinstr+0xa8>
{
    8000177e:	715d                	addi	sp,sp,-80
    80001780:	e486                	sd	ra,72(sp)
    80001782:	e0a2                	sd	s0,64(sp)
    80001784:	fc26                	sd	s1,56(sp)
    80001786:	f84a                	sd	s2,48(sp)
    80001788:	f44e                	sd	s3,40(sp)
    8000178a:	f052                	sd	s4,32(sp)
    8000178c:	ec56                	sd	s5,24(sp)
    8000178e:	e85a                	sd	s6,16(sp)
    80001790:	e45e                	sd	s7,8(sp)
    80001792:	0880                	addi	s0,sp,80
    80001794:	8a2a                	mv	s4,a0
    80001796:	8b2e                	mv	s6,a1
    80001798:	8bb2                	mv	s7,a2
    8000179a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000179c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000179e:	6985                	lui	s3,0x1
    800017a0:	a035                	j	800017cc <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017a6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a8:	0017b793          	seqz	a5,a5
    800017ac:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b0:	60a6                	ld	ra,72(sp)
    800017b2:	6406                	ld	s0,64(sp)
    800017b4:	74e2                	ld	s1,56(sp)
    800017b6:	7942                	ld	s2,48(sp)
    800017b8:	79a2                	ld	s3,40(sp)
    800017ba:	7a02                	ld	s4,32(sp)
    800017bc:	6ae2                	ld	s5,24(sp)
    800017be:	6b42                	ld	s6,16(sp)
    800017c0:	6ba2                	ld	s7,8(sp)
    800017c2:	6161                	addi	sp,sp,80
    800017c4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ca:	c8a9                	beqz	s1,8000181c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017cc:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d0:	85ca                	mv	a1,s2
    800017d2:	8552                	mv	a0,s4
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	89c080e7          	jalr	-1892(ra) # 80001070 <walkaddr>
    if(pa0 == 0)
    800017dc:	c131                	beqz	a0,80001820 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017de:	41790833          	sub	a6,s2,s7
    800017e2:	984e                	add	a6,a6,s3
    if(n > max)
    800017e4:	0104f363          	bgeu	s1,a6,800017ea <copyinstr+0x6e>
    800017e8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ea:	955e                	add	a0,a0,s7
    800017ec:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f0:	fc080be3          	beqz	a6,800017c6 <copyinstr+0x4a>
    800017f4:	985a                	add	a6,a6,s6
    800017f6:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017f8:	41650633          	sub	a2,a0,s6
    800017fc:	14fd                	addi	s1,s1,-1
    800017fe:	9b26                	add	s6,s6,s1
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbc000>
    80001808:	df49                	beqz	a4,800017a2 <copyinstr+0x26>
        *dst = *p;
    8000180a:	00e78023          	sb	a4,0(a5)
      --max;
    8000180e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001812:	0785                	addi	a5,a5,1
    while(n > 0){
    80001814:	ff0796e3          	bne	a5,a6,80001800 <copyinstr+0x84>
      dst++;
    80001818:	8b42                	mv	s6,a6
    8000181a:	b775                	j	800017c6 <copyinstr+0x4a>
    8000181c:	4781                	li	a5,0
    8000181e:	b769                	j	800017a8 <copyinstr+0x2c>
      return -1;
    80001820:	557d                	li	a0,-1
    80001822:	b779                	j	800017b0 <copyinstr+0x34>
  int got_null = 0;
    80001824:	4781                	li	a5,0
  if(got_null){
    80001826:	0017b793          	seqz	a5,a5
    8000182a:	40f00533          	neg	a0,a5
}
    8000182e:	8082                	ret

0000000080001830 <freethread>:
}

// ADDED Q3
static void
freethread(struct thread *t)
{
    80001830:	1101                	addi	sp,sp,-32
    80001832:	ec06                	sd	ra,24(sp)
    80001834:	e822                	sd	s0,16(sp)
    80001836:	e426                	sd	s1,8(sp)
    80001838:	1000                	addi	s0,sp,32
    8000183a:	84aa                	mv	s1,a0
    if (t->kstack)
    8000183c:	6128                	ld	a0,64(a0)
    8000183e:	e505                	bnez	a0,80001866 <freethread+0x36>
      kfree((void *)t->kstack);
    t->kstack = 0;
    80001840:	0404b023          	sd	zero,64(s1)
    t->trapframe = 0;
    80001844:	0404b423          	sd	zero,72(s1)
    t->tid = 0;
    80001848:	0204a823          	sw	zero,48(s1)
    t->proc = 0;
    8000184c:	0204bc23          	sd	zero,56(s1)
    t->chan = 0;
    80001850:	0204b023          	sd	zero,32(s1)
    t->terminated = 0;
    80001854:	0204a423          	sw	zero,40(s1)
    t->state = UNUSED_T;
    80001858:	0004ac23          	sw	zero,24(s1)
}
    8000185c:	60e2                	ld	ra,24(sp)
    8000185e:	6442                	ld	s0,16(sp)
    80001860:	64a2                	ld	s1,8(sp)
    80001862:	6105                	addi	sp,sp,32
    80001864:	8082                	ret
      kfree((void *)t->kstack);
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	170080e7          	jalr	368(ra) # 800009d6 <kfree>
    8000186e:	bfc9                	j	80001840 <freethread+0x10>

0000000080001870 <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    80001870:	715d                	addi	sp,sp,-80
    80001872:	e486                	sd	ra,72(sp)
    80001874:	e0a2                	sd	s0,64(sp)
    80001876:	fc26                	sd	s1,56(sp)
    80001878:	f84a                	sd	s2,48(sp)
    8000187a:	f44e                	sd	s3,40(sp)
    8000187c:	f052                	sd	s4,32(sp)
    8000187e:	ec56                	sd	s5,24(sp)
    80001880:	e85a                	sd	s6,16(sp)
    80001882:	e45e                	sd	s7,8(sp)
    80001884:	e062                	sd	s8,0(sp)
    80001886:	0880                	addi	s0,sp,80
    80001888:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188a:	00011497          	auipc	s1,0x11
    8000188e:	e7648493          	addi	s1,s1,-394 # 80012700 <proc>
    uint64 va = KSTACK((int) (p - proc));
    80001892:	8c26                	mv	s8,s1
    80001894:	00007b97          	auipc	s7,0x7
    80001898:	76cb8b93          	addi	s7,s7,1900 # 80009000 <etext>
    8000189c:	04000937          	lui	s2,0x4000
    800018a0:	197d                	addi	s2,s2,-1
    800018a2:	0932                	slli	s2,s2,0xc
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a4:	6a05                	lui	s4,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a6:	880a0b13          	addi	s6,s4,-1920 # 880 <_entry-0x7ffff780>
    800018aa:	00033a97          	auipc	s5,0x33
    800018ae:	e56a8a93          	addi	s5,s5,-426 # 80034700 <tickslock>
    char *pa = kalloc();
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	220080e7          	jalr	544(ra) # 80000ad2 <kalloc>
    800018ba:	862a                	mv	a2,a0
    if(pa == 0)
    800018bc:	c139                	beqz	a0,80001902 <proc_mapstacks+0x92>
    uint64 va = KSTACK((int) (p - proc));
    800018be:	418485b3          	sub	a1,s1,s8
    800018c2:	859d                	srai	a1,a1,0x7
    800018c4:	000bb783          	ld	a5,0(s7)
    800018c8:	02f585b3          	mul	a1,a1,a5
    800018cc:	2585                	addiw	a1,a1,1
    800018ce:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018d2:	4719                	li	a4,6
    800018d4:	86d2                	mv	a3,s4
    800018d6:	40b905b3          	sub	a1,s2,a1
    800018da:	854e                	mv	a0,s3
    800018dc:	00000097          	auipc	ra,0x0
    800018e0:	864080e7          	jalr	-1948(ra) # 80001140 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018e4:	94da                	add	s1,s1,s6
    800018e6:	fd5496e3          	bne	s1,s5,800018b2 <proc_mapstacks+0x42>
}
    800018ea:	60a6                	ld	ra,72(sp)
    800018ec:	6406                	ld	s0,64(sp)
    800018ee:	74e2                	ld	s1,56(sp)
    800018f0:	7942                	ld	s2,48(sp)
    800018f2:	79a2                	ld	s3,40(sp)
    800018f4:	7a02                	ld	s4,32(sp)
    800018f6:	6ae2                	ld	s5,24(sp)
    800018f8:	6b42                	ld	s6,16(sp)
    800018fa:	6ba2                	ld	s7,8(sp)
    800018fc:	6c02                	ld	s8,0(sp)
    800018fe:	6161                	addi	sp,sp,80
    80001900:	8082                	ret
      panic("kalloc");
    80001902:	00008517          	auipc	a0,0x8
    80001906:	8d650513          	addi	a0,a0,-1834 # 800091d8 <digits+0x198>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	c20080e7          	jalr	-992(ra) # 8000052a <panic>

0000000080001912 <init_bsems>:
{
    80001912:	1141                	addi	sp,sp,-16
    80001914:	e422                	sd	s0,8(sp)
    80001916:	0800                	addi	s0,sp,16
}
    80001918:	6422                	ld	s0,8(sp)
    8000191a:	0141                	addi	sp,sp,16
    8000191c:	8082                	ret

000000008000191e <procinit>:
{
    8000191e:	715d                	addi	sp,sp,-80
    80001920:	e486                	sd	ra,72(sp)
    80001922:	e0a2                	sd	s0,64(sp)
    80001924:	fc26                	sd	s1,56(sp)
    80001926:	f84a                	sd	s2,48(sp)
    80001928:	f44e                	sd	s3,40(sp)
    8000192a:	f052                	sd	s4,32(sp)
    8000192c:	ec56                	sd	s5,24(sp)
    8000192e:	e85a                	sd	s6,16(sp)
    80001930:	e45e                	sd	s7,8(sp)
    80001932:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001934:	00008597          	auipc	a1,0x8
    80001938:	8ac58593          	addi	a1,a1,-1876 # 800091e0 <digits+0x1a0>
    8000193c:	00011517          	auipc	a0,0x11
    80001940:	96450513          	addi	a0,a0,-1692 # 800122a0 <pid_lock>
    80001944:	fffff097          	auipc	ra,0xfffff
    80001948:	1ee080e7          	jalr	494(ra) # 80000b32 <initlock>
  initlock(&tid_lock, "nexttid"); // ADDED Q3
    8000194c:	00008597          	auipc	a1,0x8
    80001950:	89c58593          	addi	a1,a1,-1892 # 800091e8 <digits+0x1a8>
    80001954:	00011517          	auipc	a0,0x11
    80001958:	96450513          	addi	a0,a0,-1692 # 800122b8 <tid_lock>
    8000195c:	fffff097          	auipc	ra,0xfffff
    80001960:	1d6080e7          	jalr	470(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001964:	00008597          	auipc	a1,0x8
    80001968:	88c58593          	addi	a1,a1,-1908 # 800091f0 <digits+0x1b0>
    8000196c:	00011517          	auipc	a0,0x11
    80001970:	96450513          	addi	a0,a0,-1692 # 800122d0 <wait_lock>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	1be080e7          	jalr	446(ra) # 80000b32 <initlock>
  initlock(&join_lock, "join_lock"); // ADDED Q3
    8000197c:	00008597          	auipc	a1,0x8
    80001980:	88458593          	addi	a1,a1,-1916 # 80009200 <digits+0x1c0>
    80001984:	00011517          	auipc	a0,0x11
    80001988:	96450513          	addi	a0,a0,-1692 # 800122e8 <join_lock>
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	1a6080e7          	jalr	422(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001994:	00011917          	auipc	s2,0x11
    80001998:	5e490913          	addi	s2,s2,1508 # 80012f78 <proc+0x878>
    8000199c:	00033b97          	auipc	s7,0x33
    800019a0:	5dcb8b93          	addi	s7,s7,1500 # 80034f78 <bcache+0x860>
    initlock(&p->lock, "proc");
    800019a4:	7afd                	lui	s5,0xfffff
    800019a6:	788a8a93          	addi	s5,s5,1928 # fffffffffffff788 <end+0xffffffff7ffbc788>
    800019aa:	00008b17          	auipc	s6,0x8
    800019ae:	866b0b13          	addi	s6,s6,-1946 # 80009210 <digits+0x1d0>
      initlock(&t->lock, "thread");
    800019b2:	00008997          	auipc	s3,0x8
    800019b6:	86698993          	addi	s3,s3,-1946 # 80009218 <digits+0x1d8>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ba:	6a05                	lui	s4,0x1
    800019bc:	880a0a13          	addi	s4,s4,-1920 # 880 <_entry-0x7ffff780>
    800019c0:	a021                	j	800019c8 <procinit+0xaa>
    800019c2:	9952                	add	s2,s2,s4
    800019c4:	03790663          	beq	s2,s7,800019f0 <procinit+0xd2>
    initlock(&p->lock, "proc");
    800019c8:	85da                	mv	a1,s6
    800019ca:	01590533          	add	a0,s2,s5
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	164080e7          	jalr	356(ra) # 80000b32 <initlock>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800019d6:	a0090493          	addi	s1,s2,-1536
      initlock(&t->lock, "thread");
    800019da:	85ce                	mv	a1,s3
    800019dc:	8526                	mv	a0,s1
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	154080e7          	jalr	340(ra) # 80000b32 <initlock>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800019e6:	0c048493          	addi	s1,s1,192
    800019ea:	ff2498e3          	bne	s1,s2,800019da <procinit+0xbc>
    800019ee:	bfd1                	j	800019c2 <procinit+0xa4>
}
    800019f0:	60a6                	ld	ra,72(sp)
    800019f2:	6406                	ld	s0,64(sp)
    800019f4:	74e2                	ld	s1,56(sp)
    800019f6:	7942                	ld	s2,48(sp)
    800019f8:	79a2                	ld	s3,40(sp)
    800019fa:	7a02                	ld	s4,32(sp)
    800019fc:	6ae2                	ld	s5,24(sp)
    800019fe:	6b42                	ld	s6,16(sp)
    80001a00:	6ba2                	ld	s7,8(sp)
    80001a02:	6161                	addi	sp,sp,80
    80001a04:	8082                	ret

0000000080001a06 <cpuid>:
{
    80001a06:	1141                	addi	sp,sp,-16
    80001a08:	e422                	sd	s0,8(sp)
    80001a0a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a0c:	8512                	mv	a0,tp
}
    80001a0e:	2501                	sext.w	a0,a0
    80001a10:	6422                	ld	s0,8(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret

0000000080001a16 <mycpu>:
mycpu(void) {
    80001a16:	1141                	addi	sp,sp,-16
    80001a18:	e422                	sd	s0,8(sp)
    80001a1a:	0800                	addi	s0,sp,16
    80001a1c:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a1e:	2781                	sext.w	a5,a5
    80001a20:	079e                	slli	a5,a5,0x7
}
    80001a22:	00011517          	auipc	a0,0x11
    80001a26:	8de50513          	addi	a0,a0,-1826 # 80012300 <cpus>
    80001a2a:	953e                	add	a0,a0,a5
    80001a2c:	6422                	ld	s0,8(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret

0000000080001a32 <myproc>:
myproc(void) {
    80001a32:	1101                	addi	sp,sp,-32
    80001a34:	ec06                	sd	ra,24(sp)
    80001a36:	e822                	sd	s0,16(sp)
    80001a38:	e426                	sd	s1,8(sp)
    80001a3a:	1000                	addi	s0,sp,32
  push_off();
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	13a080e7          	jalr	314(ra) # 80000b76 <push_off>
    80001a44:	8792                	mv	a5,tp
  struct proc *p = c->thread->proc; //ADDED Q3
    80001a46:	2781                	sext.w	a5,a5
    80001a48:	079e                	slli	a5,a5,0x7
    80001a4a:	00011717          	auipc	a4,0x11
    80001a4e:	85670713          	addi	a4,a4,-1962 # 800122a0 <pid_lock>
    80001a52:	97ba                	add	a5,a5,a4
    80001a54:	73bc                	ld	a5,96(a5)
    80001a56:	7f84                	ld	s1,56(a5)
  pop_off();
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	1d0080e7          	jalr	464(ra) # 80000c28 <pop_off>
}
    80001a60:	8526                	mv	a0,s1
    80001a62:	60e2                	ld	ra,24(sp)
    80001a64:	6442                	ld	s0,16(sp)
    80001a66:	64a2                	ld	s1,8(sp)
    80001a68:	6105                	addi	sp,sp,32
    80001a6a:	8082                	ret

0000000080001a6c <mythread>:
mythread(void) {
    80001a6c:	1101                	addi	sp,sp,-32
    80001a6e:	ec06                	sd	ra,24(sp)
    80001a70:	e822                	sd	s0,16(sp)
    80001a72:	e426                	sd	s1,8(sp)
    80001a74:	1000                	addi	s0,sp,32
  push_off();
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	100080e7          	jalr	256(ra) # 80000b76 <push_off>
    80001a7e:	8792                	mv	a5,tp
  struct thread *t = c->thread;
    80001a80:	2781                	sext.w	a5,a5
    80001a82:	079e                	slli	a5,a5,0x7
    80001a84:	00011717          	auipc	a4,0x11
    80001a88:	81c70713          	addi	a4,a4,-2020 # 800122a0 <pid_lock>
    80001a8c:	97ba                	add	a5,a5,a4
    80001a8e:	73a4                	ld	s1,96(a5)
  pop_off();
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	198080e7          	jalr	408(ra) # 80000c28 <pop_off>
}
    80001a98:	8526                	mv	a0,s1
    80001a9a:	60e2                	ld	ra,24(sp)
    80001a9c:	6442                	ld	s0,16(sp)
    80001a9e:	64a2                	ld	s1,8(sp)
    80001aa0:	6105                	addi	sp,sp,32
    80001aa2:	8082                	ret

0000000080001aa4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001aa4:	1141                	addi	sp,sp,-16
    80001aa6:	e406                	sd	ra,8(sp)
    80001aa8:	e022                	sd	s0,0(sp)
    80001aaa:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding t->lock from scheduler.
  release(&mythread()->lock); // ADDED Q3
    80001aac:	00000097          	auipc	ra,0x0
    80001ab0:	fc0080e7          	jalr	-64(ra) # 80001a6c <mythread>
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	1d4080e7          	jalr	468(ra) # 80000c88 <release>

  if (first) {
    80001abc:	00008797          	auipc	a5,0x8
    80001ac0:	dc47a783          	lw	a5,-572(a5) # 80009880 <first.1>
    80001ac4:	eb89                	bnez	a5,80001ad6 <forkret+0x32>
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }
  usertrapret();
    80001ac6:	00001097          	auipc	ra,0x1
    80001aca:	77c080e7          	jalr	1916(ra) # 80003242 <usertrapret>
}
    80001ace:	60a2                	ld	ra,8(sp)
    80001ad0:	6402                	ld	s0,0(sp)
    80001ad2:	0141                	addi	sp,sp,16
    80001ad4:	8082                	ret
    first = 0;
    80001ad6:	00008797          	auipc	a5,0x8
    80001ada:	da07a523          	sw	zero,-598(a5) # 80009880 <first.1>
    fsinit(ROOTDEV);
    80001ade:	4505                	li	a0,1
    80001ae0:	00002097          	auipc	ra,0x2
    80001ae4:	768080e7          	jalr	1896(ra) # 80004248 <fsinit>
    80001ae8:	bff9                	j	80001ac6 <forkret+0x22>

0000000080001aea <allocpid>:
allocpid() {
    80001aea:	1101                	addi	sp,sp,-32
    80001aec:	ec06                	sd	ra,24(sp)
    80001aee:	e822                	sd	s0,16(sp)
    80001af0:	e426                	sd	s1,8(sp)
    80001af2:	e04a                	sd	s2,0(sp)
    80001af4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001af6:	00010917          	auipc	s2,0x10
    80001afa:	7aa90913          	addi	s2,s2,1962 # 800122a0 <pid_lock>
    80001afe:	854a                	mv	a0,s2
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	0c2080e7          	jalr	194(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001b08:	00008797          	auipc	a5,0x8
    80001b0c:	d8078793          	addi	a5,a5,-640 # 80009888 <nextpid>
    80001b10:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b12:	0014871b          	addiw	a4,s1,1
    80001b16:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b18:	854a                	mv	a0,s2
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	16e080e7          	jalr	366(ra) # 80000c88 <release>
}
    80001b22:	8526                	mv	a0,s1
    80001b24:	60e2                	ld	ra,24(sp)
    80001b26:	6442                	ld	s0,16(sp)
    80001b28:	64a2                	ld	s1,8(sp)
    80001b2a:	6902                	ld	s2,0(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <alloctid>:
alloctid() {
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	e04a                	sd	s2,0(sp)
    80001b3a:	1000                	addi	s0,sp,32
  acquire(&tid_lock);
    80001b3c:	00010917          	auipc	s2,0x10
    80001b40:	77c90913          	addi	s2,s2,1916 # 800122b8 <tid_lock>
    80001b44:	854a                	mv	a0,s2
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	07c080e7          	jalr	124(ra) # 80000bc2 <acquire>
  tid = nexttid;
    80001b4e:	00008797          	auipc	a5,0x8
    80001b52:	d3678793          	addi	a5,a5,-714 # 80009884 <nexttid>
    80001b56:	4384                	lw	s1,0(a5)
  nexttid = nexttid + 1;
    80001b58:	0014871b          	addiw	a4,s1,1
    80001b5c:	c398                	sw	a4,0(a5)
  release(&tid_lock);
    80001b5e:	854a                	mv	a0,s2
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	128080e7          	jalr	296(ra) # 80000c88 <release>
}
    80001b68:	8526                	mv	a0,s1
    80001b6a:	60e2                	ld	ra,24(sp)
    80001b6c:	6442                	ld	s0,16(sp)
    80001b6e:	64a2                	ld	s1,8(sp)
    80001b70:	6902                	ld	s2,0(sp)
    80001b72:	6105                	addi	sp,sp,32
    80001b74:	8082                	ret

0000000080001b76 <allocthread>:
{
    80001b76:	7179                	addi	sp,sp,-48
    80001b78:	f406                	sd	ra,40(sp)
    80001b7a:	f022                	sd	s0,32(sp)
    80001b7c:	ec26                	sd	s1,24(sp)
    80001b7e:	e84a                	sd	s2,16(sp)
    80001b80:	e44e                	sd	s3,8(sp)
    80001b82:	e052                	sd	s4,0(sp)
    80001b84:	1800                	addi	s0,sp,48
    80001b86:	8a2a                	mv	s4,a0
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001b88:	27850493          	addi	s1,a0,632
    int t_index = 0;
    80001b8c:	4901                	li	s2,0
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001b8e:	49a1                	li	s3,8
    80001b90:	a88d                	j	80001c02 <allocthread+0x8c>
  t->tid = alloctid();
    80001b92:	00000097          	auipc	ra,0x0
    80001b96:	f9e080e7          	jalr	-98(ra) # 80001b30 <alloctid>
    80001b9a:	d888                	sw	a0,48(s1)
  t->index = t_index;
    80001b9c:	0324aa23          	sw	s2,52(s1)
  t->state = USED_T;
    80001ba0:	4785                	li	a5,1
    80001ba2:	cc9c                	sw	a5,24(s1)
  t->trapframe = &p->trapframes[t_index];
    80001ba4:	6705                	lui	a4,0x1
    80001ba6:	9752                	add	a4,a4,s4
    80001ba8:	00391793          	slli	a5,s2,0x3
    80001bac:	993e                	add	s2,s2,a5
    80001bae:	0916                	slli	s2,s2,0x5
    80001bb0:	87873783          	ld	a5,-1928(a4) # 878 <_entry-0x7ffff788>
    80001bb4:	993e                	add	s2,s2,a5
    80001bb6:	0524b423          	sd	s2,72(s1)
  t->terminated = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  t->proc = p;
    80001bbe:	0344bc23          	sd	s4,56(s1)
  memset(&t->context, 0, sizeof(t->context));
    80001bc2:	07000613          	li	a2,112
    80001bc6:	4581                	li	a1,0
    80001bc8:	05048513          	addi	a0,s1,80
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	116080e7          	jalr	278(ra) # 80000ce2 <memset>
  t->context.ra = (uint64)forkret;
    80001bd4:	00000797          	auipc	a5,0x0
    80001bd8:	ed078793          	addi	a5,a5,-304 # 80001aa4 <forkret>
    80001bdc:	e8bc                	sd	a5,80(s1)
  if((t->kstack = (uint64)kalloc()) == 0) {
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	ef4080e7          	jalr	-268(ra) # 80000ad2 <kalloc>
    80001be6:	892a                	mv	s2,a0
    80001be8:	e0a8                	sd	a0,64(s1)
    80001bea:	c929                	beqz	a0,80001c3c <allocthread+0xc6>
  t->context.sp = t->kstack + PGSIZE;
    80001bec:	6785                	lui	a5,0x1
    80001bee:	00f50933          	add	s2,a0,a5
    80001bf2:	0524bc23          	sd	s2,88(s1)
  return t;
    80001bf6:	a815                	j	80001c2a <allocthread+0xb4>
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001bf8:	0c048493          	addi	s1,s1,192
    80001bfc:	2905                	addiw	s2,s2,1
    80001bfe:	03390563          	beq	s2,s3,80001c28 <allocthread+0xb2>
      if (t != mythread()) {
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	e6a080e7          	jalr	-406(ra) # 80001a6c <mythread>
    80001c0a:	fea487e3          	beq	s1,a0,80001bf8 <allocthread+0x82>
        acquire(&t->lock);
    80001c0e:	8526                	mv	a0,s1
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	fb2080e7          	jalr	-78(ra) # 80000bc2 <acquire>
        if (t->state == UNUSED_T) {
    80001c18:	4c9c                	lw	a5,24(s1)
    80001c1a:	dfa5                	beqz	a5,80001b92 <allocthread+0x1c>
        release(&t->lock);
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	06a080e7          	jalr	106(ra) # 80000c88 <release>
    80001c26:	bfc9                	j	80001bf8 <allocthread+0x82>
    return 0;
    80001c28:	4481                	li	s1,0
}
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	70a2                	ld	ra,40(sp)
    80001c2e:	7402                	ld	s0,32(sp)
    80001c30:	64e2                	ld	s1,24(sp)
    80001c32:	6942                	ld	s2,16(sp)
    80001c34:	69a2                	ld	s3,8(sp)
    80001c36:	6a02                	ld	s4,0(sp)
    80001c38:	6145                	addi	sp,sp,48
    80001c3a:	8082                	ret
      freethread(t);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	bf2080e7          	jalr	-1038(ra) # 80001830 <freethread>
      release(&t->lock);
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	040080e7          	jalr	64(ra) # 80000c88 <release>
      return 0;
    80001c50:	84ca                	mv	s1,s2
    80001c52:	bfe1                	j	80001c2a <allocthread+0xb4>

0000000080001c54 <proc_pagetable>:
{
    80001c54:	1101                	addi	sp,sp,-32
    80001c56:	ec06                	sd	ra,24(sp)
    80001c58:	e822                	sd	s0,16(sp)
    80001c5a:	e426                	sd	s1,8(sp)
    80001c5c:	e04a                	sd	s2,0(sp)
    80001c5e:	1000                	addi	s0,sp,32
    80001c60:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	6c8080e7          	jalr	1736(ra) # 8000132a <uvmcreate>
    80001c6a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c6c:	c131                	beqz	a0,80001cb0 <proc_pagetable+0x5c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c6e:	4729                	li	a4,10
    80001c70:	00006697          	auipc	a3,0x6
    80001c74:	39068693          	addi	a3,a3,912 # 80008000 <_trampoline>
    80001c78:	6605                	lui	a2,0x1
    80001c7a:	040005b7          	lui	a1,0x4000
    80001c7e:	15fd                	addi	a1,a1,-1
    80001c80:	05b2                	slli	a1,a1,0xc
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	430080e7          	jalr	1072(ra) # 800010b2 <mappages>
    80001c8a:	02054a63          	bltz	a0,80001cbe <proc_pagetable+0x6a>
              (uint64)(p->trapframes), PTE_R | PTE_W) < 0){
    80001c8e:	6505                	lui	a0,0x1
    80001c90:	954a                	add	a0,a0,s2
  if(mappages(pagetable, TRAPFRAME(0), PGSIZE,
    80001c92:	4719                	li	a4,6
    80001c94:	87853683          	ld	a3,-1928(a0) # 878 <_entry-0x7ffff788>
    80001c98:	6605                	lui	a2,0x1
    80001c9a:	020005b7          	lui	a1,0x2000
    80001c9e:	15fd                	addi	a1,a1,-1
    80001ca0:	05b6                	slli	a1,a1,0xd
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	40e080e7          	jalr	1038(ra) # 800010b2 <mappages>
    80001cac:	02054163          	bltz	a0,80001cce <proc_pagetable+0x7a>
}
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	60e2                	ld	ra,24(sp)
    80001cb4:	6442                	ld	s0,16(sp)
    80001cb6:	64a2                	ld	s1,8(sp)
    80001cb8:	6902                	ld	s2,0(sp)
    80001cba:	6105                	addi	sp,sp,32
    80001cbc:	8082                	ret
    uvmfree(pagetable, 0);
    80001cbe:	4581                	li	a1,0
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	864080e7          	jalr	-1948(ra) # 80001526 <uvmfree>
    return 0;
    80001cca:	4481                	li	s1,0
    80001ccc:	b7d5                	j	80001cb0 <proc_pagetable+0x5c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cce:	4681                	li	a3,0
    80001cd0:	4605                	li	a2,1
    80001cd2:	040005b7          	lui	a1,0x4000
    80001cd6:	15fd                	addi	a1,a1,-1
    80001cd8:	05b2                	slli	a1,a1,0xc
    80001cda:	8526                	mv	a0,s1
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	58a080e7          	jalr	1418(ra) # 80001266 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ce4:	4581                	li	a1,0
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	00000097          	auipc	ra,0x0
    80001cec:	83e080e7          	jalr	-1986(ra) # 80001526 <uvmfree>
    return 0;
    80001cf0:	4481                	li	s1,0
    80001cf2:	bf7d                	j	80001cb0 <proc_pagetable+0x5c>

0000000080001cf4 <proc_freepagetable>:
{
    80001cf4:	1101                	addi	sp,sp,-32
    80001cf6:	ec06                	sd	ra,24(sp)
    80001cf8:	e822                	sd	s0,16(sp)
    80001cfa:	e426                	sd	s1,8(sp)
    80001cfc:	e04a                	sd	s2,0(sp)
    80001cfe:	1000                	addi	s0,sp,32
    80001d00:	84aa                	mv	s1,a0
    80001d02:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d04:	4681                	li	a3,0
    80001d06:	4605                	li	a2,1
    80001d08:	040005b7          	lui	a1,0x4000
    80001d0c:	15fd                	addi	a1,a1,-1
    80001d0e:	05b2                	slli	a1,a1,0xc
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	556080e7          	jalr	1366(ra) # 80001266 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME(0), 1, 0);
    80001d18:	4681                	li	a3,0
    80001d1a:	4605                	li	a2,1
    80001d1c:	020005b7          	lui	a1,0x2000
    80001d20:	15fd                	addi	a1,a1,-1
    80001d22:	05b6                	slli	a1,a1,0xd
    80001d24:	8526                	mv	a0,s1
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	540080e7          	jalr	1344(ra) # 80001266 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d2e:	85ca                	mv	a1,s2
    80001d30:	8526                	mv	a0,s1
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	7f4080e7          	jalr	2036(ra) # 80001526 <uvmfree>
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret

0000000080001d46 <freeproc>:
{
    80001d46:	1101                	addi	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	e04a                	sd	s2,0(sp)
    80001d50:	1000                	addi	s0,sp,32
    80001d52:	892a                	mv	s2,a0
  if(p->trapframes)
    80001d54:	6785                	lui	a5,0x1
    80001d56:	97aa                	add	a5,a5,a0
    80001d58:	8787b503          	ld	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001d5c:	c509                	beqz	a0,80001d66 <freeproc+0x20>
    kfree((void*)p->trapframes);
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	c78080e7          	jalr	-904(ra) # 800009d6 <kfree>
  p->trapframes = 0;
    80001d66:	6785                	lui	a5,0x1
    80001d68:	97ca                	add	a5,a5,s2
    80001d6a:	8607bc23          	sd	zero,-1928(a5) # 878 <_entry-0x7ffff788>
  if(p->trapframe_backup)
    80001d6e:	1b893503          	ld	a0,440(s2)
    80001d72:	c509                	beqz	a0,80001d7c <freeproc+0x36>
    kfree((void*)p->trapframe_backup);
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	c62080e7          	jalr	-926(ra) # 800009d6 <kfree>
  p->trapframe_backup = 0;
    80001d7c:	1a093c23          	sd	zero,440(s2)
  if(p->pagetable)
    80001d80:	1d893503          	ld	a0,472(s2)
    80001d84:	c519                	beqz	a0,80001d92 <freeproc+0x4c>
    proc_freepagetable(p->pagetable, p->sz);
    80001d86:	1d093583          	ld	a1,464(s2)
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	f6a080e7          	jalr	-150(ra) # 80001cf4 <proc_freepagetable>
  p->pagetable = 0;
    80001d92:	1c093c23          	sd	zero,472(s2)
  p->sz = 0;
    80001d96:	1c093823          	sd	zero,464(s2)
  p->pid = 0;
    80001d9a:	02092223          	sw	zero,36(s2)
  p->parent = 0;
    80001d9e:	1c093423          	sd	zero,456(s2)
  p->name[0] = 0;
    80001da2:	26090423          	sb	zero,616(s2)
  p->killed = 0;
    80001da6:	00092e23          	sw	zero,28(s2)
  p->stopped = 0;
    80001daa:	1c092023          	sw	zero,448(s2)
  p->xstate = 0;
    80001dae:	02092023          	sw	zero,32(s2)
  p->state = UNUSED;
    80001db2:	00092c23          	sw	zero,24(s2)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001db6:	27890493          	addi	s1,s2,632
    80001dba:	6505                	lui	a0,0x1
    80001dbc:	87850513          	addi	a0,a0,-1928 # 878 <_entry-0x7ffff788>
    80001dc0:	992a                	add	s2,s2,a0
    freethread(t);
    80001dc2:	8526                	mv	a0,s1
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	a6c080e7          	jalr	-1428(ra) # 80001830 <freethread>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001dcc:	0c048493          	addi	s1,s1,192
    80001dd0:	fe9919e3          	bne	s2,s1,80001dc2 <freeproc+0x7c>
}
    80001dd4:	60e2                	ld	ra,24(sp)
    80001dd6:	6442                	ld	s0,16(sp)
    80001dd8:	64a2                	ld	s1,8(sp)
    80001dda:	6902                	ld	s2,0(sp)
    80001ddc:	6105                	addi	sp,sp,32
    80001dde:	8082                	ret

0000000080001de0 <allocproc>:
{
    80001de0:	7179                	addi	sp,sp,-48
    80001de2:	f406                	sd	ra,40(sp)
    80001de4:	f022                	sd	s0,32(sp)
    80001de6:	ec26                	sd	s1,24(sp)
    80001de8:	e84a                	sd	s2,16(sp)
    80001dea:	e44e                	sd	s3,8(sp)
    80001dec:	e052                	sd	s4,0(sp)
    80001dee:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001df0:	00011497          	auipc	s1,0x11
    80001df4:	91048493          	addi	s1,s1,-1776 # 80012700 <proc>
    80001df8:	6985                	lui	s3,0x1
    80001dfa:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80001dfe:	00033a17          	auipc	s4,0x33
    80001e02:	902a0a13          	addi	s4,s4,-1790 # 80034700 <tickslock>
    acquire(&p->lock);
    80001e06:	8526                	mv	a0,s1
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	dba080e7          	jalr	-582(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001e10:	4c9c                	lw	a5,24(s1)
    80001e12:	cb99                	beqz	a5,80001e28 <allocproc+0x48>
      release(&p->lock);
    80001e14:	8526                	mv	a0,s1
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	e72080e7          	jalr	-398(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e1e:	94ce                	add	s1,s1,s3
    80001e20:	ff4493e3          	bne	s1,s4,80001e06 <allocproc+0x26>
  return 0;
    80001e24:	4481                	li	s1,0
    80001e26:	a89d                	j	80001e9c <allocproc+0xbc>
  p->pid = allocpid();
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	cc2080e7          	jalr	-830(ra) # 80001aea <allocpid>
    80001e30:	d0c8                	sw	a0,36(s1)
  p->state = USED;
    80001e32:	4785                	li	a5,1
    80001e34:	cc9c                	sw	a5,24(s1)
  p->pending_signals = 0;
    80001e36:	0204a423          	sw	zero,40(s1)
  p->signal_mask = 0;
    80001e3a:	0204a623          	sw	zero,44(s1)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001e3e:	03848793          	addi	a5,s1,56
    80001e42:	13848713          	addi	a4,s1,312
    p->signal_handlers[signum] = SIG_DFL;
    80001e46:	0007b023          	sd	zero,0(a5)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001e4a:	07a1                	addi	a5,a5,8
    80001e4c:	fee79de3          	bne	a5,a4,80001e46 <allocproc+0x66>
  if((p->trapframes = (struct trapframe *)kalloc()) == 0){
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	c82080e7          	jalr	-894(ra) # 80000ad2 <kalloc>
    80001e58:	892a                	mv	s2,a0
    80001e5a:	6785                	lui	a5,0x1
    80001e5c:	97a6                	add	a5,a5,s1
    80001e5e:	86a7bc23          	sd	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001e62:	c531                	beqz	a0,80001eae <allocproc+0xce>
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	c6e080e7          	jalr	-914(ra) # 80000ad2 <kalloc>
    80001e6c:	892a                	mv	s2,a0
    80001e6e:	1aa4bc23          	sd	a0,440(s1)
    80001e72:	c931                	beqz	a0,80001ec6 <allocproc+0xe6>
  p->pagetable = proc_pagetable(p);
    80001e74:	8526                	mv	a0,s1
    80001e76:	00000097          	auipc	ra,0x0
    80001e7a:	dde080e7          	jalr	-546(ra) # 80001c54 <proc_pagetable>
    80001e7e:	892a                	mv	s2,a0
    80001e80:	1ca4bc23          	sd	a0,472(s1)
  if(p->pagetable == 0){
    80001e84:	cd29                	beqz	a0,80001ede <allocproc+0xfe>
  if ((t = allocthread(p)) == 0) {
    80001e86:	8526                	mv	a0,s1
    80001e88:	00000097          	auipc	ra,0x0
    80001e8c:	cee080e7          	jalr	-786(ra) # 80001b76 <allocthread>
    80001e90:	892a                	mv	s2,a0
    80001e92:	c135                	beqz	a0,80001ef6 <allocproc+0x116>
  release(&t->lock);
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	df4080e7          	jalr	-524(ra) # 80000c88 <release>
}
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	70a2                	ld	ra,40(sp)
    80001ea0:	7402                	ld	s0,32(sp)
    80001ea2:	64e2                	ld	s1,24(sp)
    80001ea4:	6942                	ld	s2,16(sp)
    80001ea6:	69a2                	ld	s3,8(sp)
    80001ea8:	6a02                	ld	s4,0(sp)
    80001eaa:	6145                	addi	sp,sp,48
    80001eac:	8082                	ret
    freeproc(p);
    80001eae:	8526                	mv	a0,s1
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	e96080e7          	jalr	-362(ra) # 80001d46 <freeproc>
    release(&p->lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	dce080e7          	jalr	-562(ra) # 80000c88 <release>
    return 0;
    80001ec2:	84ca                	mv	s1,s2
    80001ec4:	bfe1                	j	80001e9c <allocproc+0xbc>
    freeproc(p);
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	e7e080e7          	jalr	-386(ra) # 80001d46 <freeproc>
    release(&p->lock);
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	db6080e7          	jalr	-586(ra) # 80000c88 <release>
    return 0;
    80001eda:	84ca                	mv	s1,s2
    80001edc:	b7c1                	j	80001e9c <allocproc+0xbc>
    freeproc(p);
    80001ede:	8526                	mv	a0,s1
    80001ee0:	00000097          	auipc	ra,0x0
    80001ee4:	e66080e7          	jalr	-410(ra) # 80001d46 <freeproc>
    release(&p->lock);
    80001ee8:	8526                	mv	a0,s1
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	d9e080e7          	jalr	-610(ra) # 80000c88 <release>
    return 0;
    80001ef2:	84ca                	mv	s1,s2
    80001ef4:	b765                	j	80001e9c <allocproc+0xbc>
    release(&t->lock);
    80001ef6:	4501                	li	a0,0
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	d90080e7          	jalr	-624(ra) # 80000c88 <release>
    release(&p->lock);
    80001f00:	8526                	mv	a0,s1
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	d86080e7          	jalr	-634(ra) # 80000c88 <release>
    freeproc(p);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	00000097          	auipc	ra,0x0
    80001f10:	e3a080e7          	jalr	-454(ra) # 80001d46 <freeproc>
    return 0;
    80001f14:	84ca                	mv	s1,s2
    80001f16:	b759                	j	80001e9c <allocproc+0xbc>

0000000080001f18 <userinit>:
{
    80001f18:	1101                	addi	sp,sp,-32
    80001f1a:	ec06                	sd	ra,24(sp)
    80001f1c:	e822                	sd	s0,16(sp)
    80001f1e:	e426                	sd	s1,8(sp)
    80001f20:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f22:	00000097          	auipc	ra,0x0
    80001f26:	ebe080e7          	jalr	-322(ra) # 80001de0 <allocproc>
    80001f2a:	84aa                	mv	s1,a0
  initproc = p;
    80001f2c:	00008797          	auipc	a5,0x8
    80001f30:	0ea7be23          	sd	a0,252(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f34:	03400613          	li	a2,52
    80001f38:	00008597          	auipc	a1,0x8
    80001f3c:	95858593          	addi	a1,a1,-1704 # 80009890 <initcode>
    80001f40:	1d853503          	ld	a0,472(a0)
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	414080e7          	jalr	1044(ra) # 80001358 <uvminit>
  p->sz = PGSIZE;
    80001f4c:	6785                	lui	a5,0x1
    80001f4e:	1cf4b823          	sd	a5,464(s1)
  p->trapframes->epc = 0;      // user program counter
    80001f52:	00f48733          	add	a4,s1,a5
    80001f56:	87873683          	ld	a3,-1928(a4)
    80001f5a:	0006bc23          	sd	zero,24(a3)
  p->trapframes->sp = PGSIZE;  // user stack pointer
    80001f5e:	87873703          	ld	a4,-1928(a4)
    80001f62:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f64:	4641                	li	a2,16
    80001f66:	00007597          	auipc	a1,0x7
    80001f6a:	2ba58593          	addi	a1,a1,698 # 80009220 <digits+0x1e0>
    80001f6e:	26848513          	addi	a0,s1,616
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	ec2080e7          	jalr	-318(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001f7a:	00007517          	auipc	a0,0x7
    80001f7e:	2b650513          	addi	a0,a0,694 # 80009230 <digits+0x1f0>
    80001f82:	00003097          	auipc	ra,0x3
    80001f86:	cf4080e7          	jalr	-780(ra) # 80004c76 <namei>
    80001f8a:	26a4b023          	sd	a0,608(s1)
  p->threads[0].state = RUNNABLE;
    80001f8e:	478d                	li	a5,3
    80001f90:	28f4a823          	sw	a5,656(s1)
  release(&p->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	cf2080e7          	jalr	-782(ra) # 80000c88 <release>
}
    80001f9e:	60e2                	ld	ra,24(sp)
    80001fa0:	6442                	ld	s0,16(sp)
    80001fa2:	64a2                	ld	s1,8(sp)
    80001fa4:	6105                	addi	sp,sp,32
    80001fa6:	8082                	ret

0000000080001fa8 <growproc>:
{
    80001fa8:	1101                	addi	sp,sp,-32
    80001faa:	ec06                	sd	ra,24(sp)
    80001fac:	e822                	sd	s0,16(sp)
    80001fae:	e426                	sd	s1,8(sp)
    80001fb0:	e04a                	sd	s2,0(sp)
    80001fb2:	1000                	addi	s0,sp,32
    80001fb4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	a7c080e7          	jalr	-1412(ra) # 80001a32 <myproc>
    80001fbe:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	c02080e7          	jalr	-1022(ra) # 80000bc2 <acquire>
  sz = p->sz;
    80001fc8:	1d04b583          	ld	a1,464(s1)
    80001fcc:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001fd0:	03204463          	bgtz	s2,80001ff8 <growproc+0x50>
  } else if(n < 0){
    80001fd4:	04094863          	bltz	s2,80002024 <growproc+0x7c>
  p->sz = sz;
    80001fd8:	1602                	slli	a2,a2,0x20
    80001fda:	9201                	srli	a2,a2,0x20
    80001fdc:	1cc4b823          	sd	a2,464(s1)
  release(&p->lock);
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	ca6080e7          	jalr	-858(ra) # 80000c88 <release>
  return 0;
    80001fea:	4501                	li	a0,0
}
    80001fec:	60e2                	ld	ra,24(sp)
    80001fee:	6442                	ld	s0,16(sp)
    80001ff0:	64a2                	ld	s1,8(sp)
    80001ff2:	6902                	ld	s2,0(sp)
    80001ff4:	6105                	addi	sp,sp,32
    80001ff6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ff8:	00c9063b          	addw	a2,s2,a2
    80001ffc:	1602                	slli	a2,a2,0x20
    80001ffe:	9201                	srli	a2,a2,0x20
    80002000:	1582                	slli	a1,a1,0x20
    80002002:	9181                	srli	a1,a1,0x20
    80002004:	1d84b503          	ld	a0,472(s1)
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	40a080e7          	jalr	1034(ra) # 80001412 <uvmalloc>
    80002010:	0005061b          	sext.w	a2,a0
    80002014:	f271                	bnez	a2,80001fd8 <growproc+0x30>
      release(&p->lock);
    80002016:	8526                	mv	a0,s1
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	c70080e7          	jalr	-912(ra) # 80000c88 <release>
      return -1;
    80002020:	557d                	li	a0,-1
    80002022:	b7e9                	j	80001fec <growproc+0x44>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002024:	00c9063b          	addw	a2,s2,a2
    80002028:	1602                	slli	a2,a2,0x20
    8000202a:	9201                	srli	a2,a2,0x20
    8000202c:	1582                	slli	a1,a1,0x20
    8000202e:	9181                	srli	a1,a1,0x20
    80002030:	1d84b503          	ld	a0,472(s1)
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	396080e7          	jalr	918(ra) # 800013ca <uvmdealloc>
    8000203c:	0005061b          	sext.w	a2,a0
    80002040:	bf61                	j	80001fd8 <growproc+0x30>

0000000080002042 <fork>:
{
    80002042:	7139                	addi	sp,sp,-64
    80002044:	fc06                	sd	ra,56(sp)
    80002046:	f822                	sd	s0,48(sp)
    80002048:	f426                	sd	s1,40(sp)
    8000204a:	f04a                	sd	s2,32(sp)
    8000204c:	ec4e                	sd	s3,24(sp)
    8000204e:	e852                	sd	s4,16(sp)
    80002050:	e456                	sd	s5,8(sp)
    80002052:	0080                	addi	s0,sp,64
  struct thread *t = mythread();
    80002054:	00000097          	auipc	ra,0x0
    80002058:	a18080e7          	jalr	-1512(ra) # 80001a6c <mythread>
    8000205c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	9d4080e7          	jalr	-1580(ra) # 80001a32 <myproc>
    80002066:	892a                	mv	s2,a0
  if((np = allocproc()) == 0) {
    80002068:	00000097          	auipc	ra,0x0
    8000206c:	d78080e7          	jalr	-648(ra) # 80001de0 <allocproc>
    80002070:	14050a63          	beqz	a0,800021c4 <fork+0x182>
    80002074:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002076:	1d093603          	ld	a2,464(s2)
    8000207a:	1d853583          	ld	a1,472(a0)
    8000207e:	1d893503          	ld	a0,472(s2)
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	4dc080e7          	jalr	1244(ra) # 8000155e <uvmcopy>
    8000208a:	04054763          	bltz	a0,800020d8 <fork+0x96>
  np->sz = p->sz;
    8000208e:	1d093783          	ld	a5,464(s2)
    80002092:	1cfa3823          	sd	a5,464(s4)
  *(nt->trapframe) = *(t->trapframe); 
    80002096:	64b4                	ld	a3,72(s1)
    80002098:	87b6                	mv	a5,a3
    8000209a:	2c0a3703          	ld	a4,704(s4)
    8000209e:	12068693          	addi	a3,a3,288
    800020a2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800020a6:	6788                	ld	a0,8(a5)
    800020a8:	6b8c                	ld	a1,16(a5)
    800020aa:	6f90                	ld	a2,24(a5)
    800020ac:	01073023          	sd	a6,0(a4)
    800020b0:	e708                	sd	a0,8(a4)
    800020b2:	eb0c                	sd	a1,16(a4)
    800020b4:	ef10                	sd	a2,24(a4)
    800020b6:	02078793          	addi	a5,a5,32
    800020ba:	02070713          	addi	a4,a4,32
    800020be:	fed792e3          	bne	a5,a3,800020a2 <fork+0x60>
  nt->trapframe->a0 = 0;
    800020c2:	2c0a3783          	ld	a5,704(s4)
    800020c6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800020ca:	1e090493          	addi	s1,s2,480
    800020ce:	1e0a0993          	addi	s3,s4,480
    800020d2:	26090a93          	addi	s5,s2,608
    800020d6:	a00d                	j	800020f8 <fork+0xb6>
    freeproc(np);
    800020d8:	8552                	mv	a0,s4
    800020da:	00000097          	auipc	ra,0x0
    800020de:	c6c080e7          	jalr	-916(ra) # 80001d46 <freeproc>
    release(&np->lock);
    800020e2:	8552                	mv	a0,s4
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba4080e7          	jalr	-1116(ra) # 80000c88 <release>
    return -1;
    800020ec:	59fd                	li	s3,-1
    800020ee:	a0c9                	j	800021b0 <fork+0x16e>
  for(i = 0; i < NOFILE; i++)
    800020f0:	04a1                	addi	s1,s1,8
    800020f2:	09a1                	addi	s3,s3,8
    800020f4:	01548b63          	beq	s1,s5,8000210a <fork+0xc8>
    if(p->ofile[i])
    800020f8:	6088                	ld	a0,0(s1)
    800020fa:	d97d                	beqz	a0,800020f0 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    800020fc:	00003097          	auipc	ra,0x3
    80002100:	214080e7          	jalr	532(ra) # 80005310 <filedup>
    80002104:	00a9b023          	sd	a0,0(s3)
    80002108:	b7e5                	j	800020f0 <fork+0xae>
  np->cwd = idup(p->cwd);
    8000210a:	26093503          	ld	a0,608(s2)
    8000210e:	00002097          	auipc	ra,0x2
    80002112:	374080e7          	jalr	884(ra) # 80004482 <idup>
    80002116:	26aa3023          	sd	a0,608(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000211a:	4641                	li	a2,16
    8000211c:	26890593          	addi	a1,s2,616
    80002120:	268a0513          	addi	a0,s4,616
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	d10080e7          	jalr	-752(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    8000212c:	024a2983          	lw	s3,36(s4)
  release(&np->lock);
    80002130:	8552                	mv	a0,s4
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	b56080e7          	jalr	-1194(ra) # 80000c88 <release>
  acquire(&wait_lock);
    8000213a:	00010497          	auipc	s1,0x10
    8000213e:	19648493          	addi	s1,s1,406 # 800122d0 <wait_lock>
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	a7e080e7          	jalr	-1410(ra) # 80000bc2 <acquire>
  np->parent = p;
    8000214c:	1d2a3423          	sd	s2,456(s4)
  release(&wait_lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b36080e7          	jalr	-1226(ra) # 80000c88 <release>
  acquire(&np->lock);
    8000215a:	8552                	mv	a0,s4
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	a66080e7          	jalr	-1434(ra) # 80000bc2 <acquire>
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
    80002164:	02c92783          	lw	a5,44(s2)
    80002168:	02fa2623          	sw	a5,44(s4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    8000216c:	03890793          	addi	a5,s2,56
    80002170:	038a0713          	addi	a4,s4,56
    80002174:	13890613          	addi	a2,s2,312
    np->signal_handlers[i] = p->signal_handlers[i];    
    80002178:	6394                	ld	a3,0(a5)
    8000217a:	e314                	sd	a3,0(a4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    8000217c:	07a1                	addi	a5,a5,8
    8000217e:	0721                	addi	a4,a4,8
    80002180:	fec79ce3          	bne	a5,a2,80002178 <fork+0x136>
  np->pending_signals = 0; // ADDED Q2.1.2
    80002184:	020a2423          	sw	zero,40(s4)
  release(&np->lock);
    80002188:	8552                	mv	a0,s4
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	afe080e7          	jalr	-1282(ra) # 80000c88 <release>
  acquire(&nt->lock);
    80002192:	278a0493          	addi	s1,s4,632
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	a2a080e7          	jalr	-1494(ra) # 80000bc2 <acquire>
  nt->state = RUNNABLE;
    800021a0:	478d                	li	a5,3
    800021a2:	28fa2823          	sw	a5,656(s4)
  release(&nt->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	ae0080e7          	jalr	-1312(ra) # 80000c88 <release>
}
    800021b0:	854e                	mv	a0,s3
    800021b2:	70e2                	ld	ra,56(sp)
    800021b4:	7442                	ld	s0,48(sp)
    800021b6:	74a2                	ld	s1,40(sp)
    800021b8:	7902                	ld	s2,32(sp)
    800021ba:	69e2                	ld	s3,24(sp)
    800021bc:	6a42                	ld	s4,16(sp)
    800021be:	6aa2                	ld	s5,8(sp)
    800021c0:	6121                	addi	sp,sp,64
    800021c2:	8082                	ret
    return -1;
    800021c4:	59fd                	li	s3,-1
    800021c6:	b7ed                	j	800021b0 <fork+0x16e>

00000000800021c8 <kill_handler>:
{
    800021c8:	1141                	addi	sp,sp,-16
    800021ca:	e406                	sd	ra,8(sp)
    800021cc:	e022                	sd	s0,0(sp)
    800021ce:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800021d0:	00000097          	auipc	ra,0x0
    800021d4:	862080e7          	jalr	-1950(ra) # 80001a32 <myproc>
  p->killed = 1; 
    800021d8:	4785                	li	a5,1
    800021da:	cd5c                	sw	a5,28(a0)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800021dc:	27850793          	addi	a5,a0,632
    800021e0:	6705                	lui	a4,0x1
    800021e2:	87870713          	addi	a4,a4,-1928 # 878 <_entry-0x7ffff788>
    800021e6:	953a                	add	a0,a0,a4
    if (t->state == SLEEPING) {
    800021e8:	4689                	li	a3,2
      t->state = RUNNABLE;
    800021ea:	460d                	li	a2,3
    800021ec:	a029                	j	800021f6 <kill_handler+0x2e>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800021ee:	0c078793          	addi	a5,a5,192
    800021f2:	00f50763          	beq	a0,a5,80002200 <kill_handler+0x38>
    if (t->state == SLEEPING) {
    800021f6:	4f98                	lw	a4,24(a5)
    800021f8:	fed71be3          	bne	a4,a3,800021ee <kill_handler+0x26>
      t->state = RUNNABLE;
    800021fc:	cf90                	sw	a2,24(a5)
    800021fe:	bfc5                	j	800021ee <kill_handler+0x26>
}
    80002200:	60a2                	ld	ra,8(sp)
    80002202:	6402                	ld	s0,0(sp)
    80002204:	0141                	addi	sp,sp,16
    80002206:	8082                	ret

0000000080002208 <received_continue>:
{
    80002208:	1101                	addi	sp,sp,-32
    8000220a:	ec06                	sd	ra,24(sp)
    8000220c:	e822                	sd	s0,16(sp)
    8000220e:	e426                	sd	s1,8(sp)
    80002210:	e04a                	sd	s2,0(sp)
    80002212:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002214:	00000097          	auipc	ra,0x0
    80002218:	81e080e7          	jalr	-2018(ra) # 80001a32 <myproc>
    8000221c:	892a                	mv	s2,a0
    acquire(&p->lock);
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9a4080e7          	jalr	-1628(ra) # 80000bc2 <acquire>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    80002226:	02c92683          	lw	a3,44(s2)
    8000222a:	fff6c693          	not	a3,a3
    8000222e:	02892783          	lw	a5,40(s2)
    80002232:	8efd                	and	a3,a3,a5
    80002234:	2681                	sext.w	a3,a3
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80002236:	03890713          	addi	a4,s2,56
    8000223a:	4781                	li	a5,0
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    8000223c:	454d                	li	a0,19
    for (int signum = 0; signum < SIG_NUM; signum++) {
    8000223e:	02000613          	li	a2,32
    80002242:	a801                	j	80002252 <received_continue+0x4a>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002244:	630c                	ld	a1,0(a4)
    80002246:	00a58f63          	beq	a1,a0,80002264 <received_continue+0x5c>
    for (int signum = 0; signum < SIG_NUM; signum++) {
    8000224a:	2785                	addiw	a5,a5,1
    8000224c:	0721                	addi	a4,a4,8
    8000224e:	02c78163          	beq	a5,a2,80002270 <received_continue+0x68>
      if( (pending_and_not_blocked & (1 << signum)) &&
    80002252:	40f6d4bb          	sraw	s1,a3,a5
    80002256:	8885                	andi	s1,s1,1
    80002258:	d8ed                	beqz	s1,8000224a <received_continue+0x42>
    8000225a:	0d093583          	ld	a1,208(s2)
    8000225e:	f1fd                	bnez	a1,80002244 <received_continue+0x3c>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002260:	fea792e3          	bne	a5,a0,80002244 <received_continue+0x3c>
            release(&p->lock);
    80002264:	854a                	mv	a0,s2
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a22080e7          	jalr	-1502(ra) # 80000c88 <release>
            return 1;
    8000226e:	a039                	j	8000227c <received_continue+0x74>
    release(&p->lock);
    80002270:	854a                	mv	a0,s2
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a16080e7          	jalr	-1514(ra) # 80000c88 <release>
    return 0;
    8000227a:	4481                	li	s1,0
}
    8000227c:	8526                	mv	a0,s1
    8000227e:	60e2                	ld	ra,24(sp)
    80002280:	6442                	ld	s0,16(sp)
    80002282:	64a2                	ld	s1,8(sp)
    80002284:	6902                	ld	s2,0(sp)
    80002286:	6105                	addi	sp,sp,32
    80002288:	8082                	ret

000000008000228a <continue_handler>:
{
    8000228a:	1141                	addi	sp,sp,-16
    8000228c:	e406                	sd	ra,8(sp)
    8000228e:	e022                	sd	s0,0(sp)
    80002290:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	7a0080e7          	jalr	1952(ra) # 80001a32 <myproc>
  p->stopped = 0;
    8000229a:	1c052023          	sw	zero,448(a0)
}
    8000229e:	60a2                	ld	ra,8(sp)
    800022a0:	6402                	ld	s0,0(sp)
    800022a2:	0141                	addi	sp,sp,16
    800022a4:	8082                	ret

00000000800022a6 <handle_user_signals>:
handle_user_signals(int signum) {
    800022a6:	7179                	addi	sp,sp,-48
    800022a8:	f406                	sd	ra,40(sp)
    800022aa:	f022                	sd	s0,32(sp)
    800022ac:	ec26                	sd	s1,24(sp)
    800022ae:	e84a                	sd	s2,16(sp)
    800022b0:	e44e                	sd	s3,8(sp)
    800022b2:	1800                	addi	s0,sp,48
    800022b4:	892a                	mv	s2,a0
  struct thread *t = mythread();
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	7b6080e7          	jalr	1974(ra) # 80001a6c <mythread>
    800022be:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	772080e7          	jalr	1906(ra) # 80001a32 <myproc>
    800022c8:	84aa                	mv	s1,a0
  p->signal_mask_backup = p->signal_mask;
    800022ca:	555c                	lw	a5,44(a0)
    800022cc:	d91c                	sw	a5,48(a0)
  p->signal_mask = p->signal_handlers_masks[signum];  
    800022ce:	04c90793          	addi	a5,s2,76
    800022d2:	078a                	slli	a5,a5,0x2
    800022d4:	97aa                	add	a5,a5,a0
    800022d6:	479c                	lw	a5,8(a5)
    800022d8:	d55c                	sw	a5,44(a0)
  memmove(p->trapframe_backup, t->trapframe, sizeof(struct trapframe));
    800022da:	12000613          	li	a2,288
    800022de:	0489b583          	ld	a1,72(s3)
    800022e2:	1b853503          	ld	a0,440(a0)
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	a58080e7          	jalr	-1448(ra) # 80000d3e <memmove>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    800022ee:	0489b703          	ld	a4,72(s3)
  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
    800022f2:	00006617          	auipc	a2,0x6
    800022f6:	e2060613          	addi	a2,a2,-480 # 80008112 <start_inject_sigret>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    800022fa:	00006697          	auipc	a3,0x6
    800022fe:	e1e68693          	addi	a3,a3,-482 # 80008118 <end_inject_sigret>
    80002302:	9e91                	subw	a3,a3,a2
    80002304:	7b1c                	ld	a5,48(a4)
    80002306:	8f95                	sub	a5,a5,a3
    80002308:	fb1c                	sd	a5,48(a4)
  copyout(p->pagetable, (uint64) (t->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);
    8000230a:	0489b783          	ld	a5,72(s3)
    8000230e:	7b8c                	ld	a1,48(a5)
    80002310:	1d84b503          	ld	a0,472(s1)
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	34e080e7          	jalr	846(ra) # 80001662 <copyout>
  t->trapframe->a0 = signum;
    8000231c:	0489b783          	ld	a5,72(s3)
    80002320:	0727b823          	sd	s2,112(a5)
  t->trapframe->epc = (uint64)p->signal_handlers[signum];
    80002324:	0489b783          	ld	a5,72(s3)
    80002328:	0919                	addi	s2,s2,6
    8000232a:	090e                	slli	s2,s2,0x3
    8000232c:	94ca                	add	s1,s1,s2
    8000232e:	6498                	ld	a4,8(s1)
    80002330:	ef98                	sd	a4,24(a5)
  t->trapframe->ra = t->trapframe->sp;
    80002332:	0489b783          	ld	a5,72(s3)
    80002336:	7b98                	ld	a4,48(a5)
    80002338:	f798                	sd	a4,40(a5)
}
    8000233a:	70a2                	ld	ra,40(sp)
    8000233c:	7402                	ld	s0,32(sp)
    8000233e:	64e2                	ld	s1,24(sp)
    80002340:	6942                	ld	s2,16(sp)
    80002342:	69a2                	ld	s3,8(sp)
    80002344:	6145                	addi	sp,sp,48
    80002346:	8082                	ret

0000000080002348 <scheduler>:
{
    80002348:	715d                	addi	sp,sp,-80
    8000234a:	e486                	sd	ra,72(sp)
    8000234c:	e0a2                	sd	s0,64(sp)
    8000234e:	fc26                	sd	s1,56(sp)
    80002350:	f84a                	sd	s2,48(sp)
    80002352:	f44e                	sd	s3,40(sp)
    80002354:	f052                	sd	s4,32(sp)
    80002356:	ec56                	sd	s5,24(sp)
    80002358:	e85a                	sd	s6,16(sp)
    8000235a:	e45e                	sd	s7,8(sp)
    8000235c:	e062                	sd	s8,0(sp)
    8000235e:	0880                	addi	s0,sp,80
    80002360:	8792                	mv	a5,tp
  int id = r_tp();
    80002362:	2781                	sext.w	a5,a5
  c->thread = 0;
    80002364:	00779a93          	slli	s5,a5,0x7
    80002368:	00010717          	auipc	a4,0x10
    8000236c:	f3870713          	addi	a4,a4,-200 # 800122a0 <pid_lock>
    80002370:	9756                	add	a4,a4,s5
    80002372:	06073023          	sd	zero,96(a4)
          swtch(&c->context, &t->context);
    80002376:	00010717          	auipc	a4,0x10
    8000237a:	f9270713          	addi	a4,a4,-110 # 80012308 <cpus+0x8>
    8000237e:	9aba                	add	s5,s5,a4
    80002380:	00033c17          	auipc	s8,0x33
    80002384:	bf8c0c13          	addi	s8,s8,-1032 # 80034f78 <bcache+0x860>
          t->state = RUNNING;
    80002388:	4b11                	li	s6,4
          c->thread = t;
    8000238a:	079e                	slli	a5,a5,0x7
    8000238c:	00010a17          	auipc	s4,0x10
    80002390:	f14a0a13          	addi	s4,s4,-236 # 800122a0 <pid_lock>
    80002394:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002396:	6b85                	lui	s7,0x1
    80002398:	880b8b93          	addi	s7,s7,-1920 # 880 <_entry-0x7ffff780>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000239c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023a0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023a4:	10079073          	csrw	sstatus,a5
    800023a8:	00011917          	auipc	s2,0x11
    800023ac:	bd090913          	addi	s2,s2,-1072 # 80012f78 <proc+0x878>
        if(t->state == RUNNABLE) {
    800023b0:	498d                	li	s3,3
    800023b2:	a099                	j	800023f8 <scheduler+0xb0>
        release(&t->lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	8d2080e7          	jalr	-1838(ra) # 80000c88 <release>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800023be:	0c048493          	addi	s1,s1,192
    800023c2:	03248863          	beq	s1,s2,800023f2 <scheduler+0xaa>
        acquire(&t->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	ffffe097          	auipc	ra,0xffffe
    800023cc:	7fa080e7          	jalr	2042(ra) # 80000bc2 <acquire>
        if(t->state == RUNNABLE) {
    800023d0:	4c9c                	lw	a5,24(s1)
    800023d2:	ff3791e3          	bne	a5,s3,800023b4 <scheduler+0x6c>
          t->state = RUNNING;
    800023d6:	0164ac23          	sw	s6,24(s1)
          c->thread = t;
    800023da:	069a3023          	sd	s1,96(s4)
          swtch(&c->context, &t->context);
    800023de:	05048593          	addi	a1,s1,80
    800023e2:	8556                	mv	a0,s5
    800023e4:	00001097          	auipc	ra,0x1
    800023e8:	db4080e7          	jalr	-588(ra) # 80003198 <swtch>
          c->thread = 0;
    800023ec:	060a3023          	sd	zero,96(s4)
    800023f0:	b7d1                	j	800023b4 <scheduler+0x6c>
    for(p = proc; p < &proc[NPROC]; p++) {
    800023f2:	995e                	add	s2,s2,s7
    800023f4:	fb8904e3          	beq	s2,s8,8000239c <scheduler+0x54>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800023f8:	a0090493          	addi	s1,s2,-1536
    800023fc:	b7e9                	j	800023c6 <scheduler+0x7e>

00000000800023fe <sched>:
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	1800                	addi	s0,sp,48
  struct thread *t = mythread();
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	660080e7          	jalr	1632(ra) # 80001a6c <mythread>
    80002414:	84aa                	mv	s1,a0
  if(!holding(&t->lock))
    80002416:	ffffe097          	auipc	ra,0xffffe
    8000241a:	732080e7          	jalr	1842(ra) # 80000b48 <holding>
    8000241e:	c93d                	beqz	a0,80002494 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002420:	8792                	mv	a5,tp
  if(mycpu()->noff != 1) {
    80002422:	2781                	sext.w	a5,a5
    80002424:	079e                	slli	a5,a5,0x7
    80002426:	00010717          	auipc	a4,0x10
    8000242a:	e7a70713          	addi	a4,a4,-390 # 800122a0 <pid_lock>
    8000242e:	97ba                	add	a5,a5,a4
    80002430:	0d87a703          	lw	a4,216(a5)
    80002434:	4785                	li	a5,1
    80002436:	06f71763          	bne	a4,a5,800024a4 <sched+0xa6>
  if(t->state == RUNNING)
    8000243a:	4c98                	lw	a4,24(s1)
    8000243c:	4791                	li	a5,4
    8000243e:	0af70f63          	beq	a4,a5,800024fc <sched+0xfe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002442:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002446:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002448:	e3f1                	bnez	a5,8000250c <sched+0x10e>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000244a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000244c:	00010917          	auipc	s2,0x10
    80002450:	e5490913          	addi	s2,s2,-428 # 800122a0 <pid_lock>
    80002454:	2781                	sext.w	a5,a5
    80002456:	079e                	slli	a5,a5,0x7
    80002458:	97ca                	add	a5,a5,s2
    8000245a:	0dc7a983          	lw	s3,220(a5)
    8000245e:	8792                	mv	a5,tp
  swtch(&t->context, &mycpu()->context);
    80002460:	2781                	sext.w	a5,a5
    80002462:	079e                	slli	a5,a5,0x7
    80002464:	00010597          	auipc	a1,0x10
    80002468:	ea458593          	addi	a1,a1,-348 # 80012308 <cpus+0x8>
    8000246c:	95be                	add	a1,a1,a5
    8000246e:	05048513          	addi	a0,s1,80
    80002472:	00001097          	auipc	ra,0x1
    80002476:	d26080e7          	jalr	-730(ra) # 80003198 <swtch>
    8000247a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000247c:	2781                	sext.w	a5,a5
    8000247e:	079e                	slli	a5,a5,0x7
    80002480:	97ca                	add	a5,a5,s2
    80002482:	0d37ae23          	sw	s3,220(a5)
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6145                	addi	sp,sp,48
    80002492:	8082                	ret
    panic("sched t->lock");
    80002494:	00007517          	auipc	a0,0x7
    80002498:	da450513          	addi	a0,a0,-604 # 80009238 <digits+0x1f8>
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	08e080e7          	jalr	142(ra) # 8000052a <panic>
    800024a4:	8792                	mv	a5,tp
    printf("noff: %d\n", mycpu()->noff); // REMOVE
    800024a6:	2781                	sext.w	a5,a5
    800024a8:	079e                	slli	a5,a5,0x7
    800024aa:	00010717          	auipc	a4,0x10
    800024ae:	df670713          	addi	a4,a4,-522 # 800122a0 <pid_lock>
    800024b2:	97ba                	add	a5,a5,a4
    800024b4:	0d87a583          	lw	a1,216(a5)
    800024b8:	00007517          	auipc	a0,0x7
    800024bc:	d9050513          	addi	a0,a0,-624 # 80009248 <digits+0x208>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	0b4080e7          	jalr	180(ra) # 80000574 <printf>
    if (holding(&myproc()->lock))
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	56a080e7          	jalr	1386(ra) # 80001a32 <myproc>
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	678080e7          	jalr	1656(ra) # 80000b48 <holding>
    800024d8:	e909                	bnez	a0,800024ea <sched+0xec>
    panic("sched locks\n");
    800024da:	00007517          	auipc	a0,0x7
    800024de:	d9650513          	addi	a0,a0,-618 # 80009270 <digits+0x230>
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	048080e7          	jalr	72(ra) # 8000052a <panic>
      printf("holding proc lock\n"); //REMOVE
    800024ea:	00007517          	auipc	a0,0x7
    800024ee:	d6e50513          	addi	a0,a0,-658 # 80009258 <digits+0x218>
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	082080e7          	jalr	130(ra) # 80000574 <printf>
    800024fa:	b7c5                	j	800024da <sched+0xdc>
    panic("sched running");
    800024fc:	00007517          	auipc	a0,0x7
    80002500:	d8450513          	addi	a0,a0,-636 # 80009280 <digits+0x240>
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	026080e7          	jalr	38(ra) # 8000052a <panic>
    panic("sched interruptible");
    8000250c:	00007517          	auipc	a0,0x7
    80002510:	d8450513          	addi	a0,a0,-636 # 80009290 <digits+0x250>
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	016080e7          	jalr	22(ra) # 8000052a <panic>

000000008000251c <yield>:
{
    8000251c:	1101                	addi	sp,sp,-32
    8000251e:	ec06                	sd	ra,24(sp)
    80002520:	e822                	sd	s0,16(sp)
    80002522:	e426                	sd	s1,8(sp)
    80002524:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	546080e7          	jalr	1350(ra) # 80001a6c <mythread>
    8000252e:	84aa                	mv	s1,a0
  acquire(&t->lock);
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	692080e7          	jalr	1682(ra) # 80000bc2 <acquire>
  t->state = RUNNABLE;
    80002538:	478d                	li	a5,3
    8000253a:	cc9c                	sw	a5,24(s1)
  sched();
    8000253c:	00000097          	auipc	ra,0x0
    80002540:	ec2080e7          	jalr	-318(ra) # 800023fe <sched>
  release(&t->lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	742080e7          	jalr	1858(ra) # 80000c88 <release>
}
    8000254e:	60e2                	ld	ra,24(sp)
    80002550:	6442                	ld	s0,16(sp)
    80002552:	64a2                	ld	s1,8(sp)
    80002554:	6105                	addi	sp,sp,32
    80002556:	8082                	ret

0000000080002558 <stop_handler>:
{
    80002558:	1101                	addi	sp,sp,-32
    8000255a:	ec06                	sd	ra,24(sp)
    8000255c:	e822                	sd	s0,16(sp)
    8000255e:	e426                	sd	s1,8(sp)
    80002560:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	4d0080e7          	jalr	1232(ra) # 80001a32 <myproc>
    8000256a:	84aa                	mv	s1,a0
  p->stopped = 1;
    8000256c:	4785                	li	a5,1
    8000256e:	1cf52023          	sw	a5,448(a0)
  release(&p->lock);
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	716080e7          	jalr	1814(ra) # 80000c88 <release>
  while (p->stopped && !received_continue())
    8000257a:	1c04a783          	lw	a5,448(s1)
    8000257e:	cf89                	beqz	a5,80002598 <stop_handler+0x40>
    80002580:	00000097          	auipc	ra,0x0
    80002584:	c88080e7          	jalr	-888(ra) # 80002208 <received_continue>
    80002588:	e901                	bnez	a0,80002598 <stop_handler+0x40>
      yield();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	f92080e7          	jalr	-110(ra) # 8000251c <yield>
  while (p->stopped && !received_continue())
    80002592:	1c04a783          	lw	a5,448(s1)
    80002596:	f7ed                	bnez	a5,80002580 <stop_handler+0x28>
  acquire(&p->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	628080e7          	jalr	1576(ra) # 80000bc2 <acquire>
}
    800025a2:	60e2                	ld	ra,24(sp)
    800025a4:	6442                	ld	s0,16(sp)
    800025a6:	64a2                	ld	s1,8(sp)
    800025a8:	6105                	addi	sp,sp,32
    800025aa:	8082                	ret

00000000800025ac <handle_signals>:
{
    800025ac:	711d                	addi	sp,sp,-96
    800025ae:	ec86                	sd	ra,88(sp)
    800025b0:	e8a2                	sd	s0,80(sp)
    800025b2:	e4a6                	sd	s1,72(sp)
    800025b4:	e0ca                	sd	s2,64(sp)
    800025b6:	fc4e                	sd	s3,56(sp)
    800025b8:	f852                	sd	s4,48(sp)
    800025ba:	f456                	sd	s5,40(sp)
    800025bc:	f05a                	sd	s6,32(sp)
    800025be:	ec5e                	sd	s7,24(sp)
    800025c0:	e862                	sd	s8,16(sp)
    800025c2:	e466                	sd	s9,8(sp)
    800025c4:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    800025c6:	fffff097          	auipc	ra,0xfffff
    800025ca:	46c080e7          	jalr	1132(ra) # 80001a32 <myproc>
    800025ce:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	5f2080e7          	jalr	1522(ra) # 80000bc2 <acquire>
  for(int signum = 0; signum < SIG_NUM; signum++){
    800025d8:	03890993          	addi	s3,s2,56
    800025dc:	4481                	li	s1,0
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025de:	4b05                	li	s6,1
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800025e0:	4ac5                	li	s5,17
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800025e2:	4bcd                	li	s7,19
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    800025e4:	4c25                	li	s8,9
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    800025e6:	4c85                	li	s9,1
  for(int signum = 0; signum < SIG_NUM; signum++){
    800025e8:	02000a13          	li	s4,32
    800025ec:	a0a1                	j	80002634 <handle_signals+0x88>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800025ee:	03548263          	beq	s1,s5,80002612 <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800025f2:	09748b63          	beq	s1,s7,80002688 <handle_signals+0xdc>
        kill_handler();
    800025f6:	00000097          	auipc	ra,0x0
    800025fa:	bd2080e7          	jalr	-1070(ra) # 800021c8 <kill_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025fe:	009b17bb          	sllw	a5,s6,s1
    80002602:	fff7c793          	not	a5,a5
    80002606:	02892703          	lw	a4,40(s2)
    8000260a:	8ff9                	and	a5,a5,a4
    8000260c:	02f92423          	sw	a5,40(s2)
    80002610:	a831                	j	8000262c <handle_signals+0x80>
        stop_handler();
    80002612:	00000097          	auipc	ra,0x0
    80002616:	f46080e7          	jalr	-186(ra) # 80002558 <stop_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000261a:	009b17bb          	sllw	a5,s6,s1
    8000261e:	fff7c793          	not	a5,a5
    80002622:	02892703          	lw	a4,40(s2)
    80002626:	8ff9                	and	a5,a5,a4
    80002628:	02f92423          	sw	a5,40(s2)
  for(int signum = 0; signum < SIG_NUM; signum++){
    8000262c:	2485                	addiw	s1,s1,1
    8000262e:	09a1                	addi	s3,s3,8
    80002630:	09448263          	beq	s1,s4,800026b4 <handle_signals+0x108>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    80002634:	02892703          	lw	a4,40(s2)
    80002638:	02c92783          	lw	a5,44(s2)
    8000263c:	fff7c793          	not	a5,a5
    80002640:	8ff9                	and	a5,a5,a4
    if(pending_and_not_blocked & (1 << signum)){
    80002642:	4097d7bb          	sraw	a5,a5,s1
    80002646:	8b85                	andi	a5,a5,1
    80002648:	d3f5                	beqz	a5,8000262c <handle_signals+0x80>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    8000264a:	0009b783          	ld	a5,0(s3)
    8000264e:	d3c5                	beqz	a5,800025ee <handle_signals+0x42>
    80002650:	fd5781e3          	beq	a5,s5,80002612 <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    80002654:	03778a63          	beq	a5,s7,80002688 <handle_signals+0xdc>
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    80002658:	f9878fe3          	beq	a5,s8,800025f6 <handle_signals+0x4a>
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    8000265c:	05978463          	beq	a5,s9,800026a4 <handle_signals+0xf8>
      } else if (p->handling_user_level_signal == 0){
    80002660:	1c492783          	lw	a5,452(s2)
    80002664:	f7e1                	bnez	a5,8000262c <handle_signals+0x80>
        p->handling_user_level_signal = 1;
    80002666:	1d992223          	sw	s9,452(s2)
        handle_user_signals(signum);
    8000266a:	8526                	mv	a0,s1
    8000266c:	00000097          	auipc	ra,0x0
    80002670:	c3a080e7          	jalr	-966(ra) # 800022a6 <handle_user_signals>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002674:	009b17bb          	sllw	a5,s6,s1
    80002678:	fff7c793          	not	a5,a5
    8000267c:	02892703          	lw	a4,40(s2)
    80002680:	8ff9                	and	a5,a5,a4
    80002682:	02f92423          	sw	a5,40(s2)
    80002686:	b75d                	j	8000262c <handle_signals+0x80>
        continue_handler();
    80002688:	00000097          	auipc	ra,0x0
    8000268c:	c02080e7          	jalr	-1022(ra) # 8000228a <continue_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002690:	009b17bb          	sllw	a5,s6,s1
    80002694:	fff7c793          	not	a5,a5
    80002698:	02892703          	lw	a4,40(s2)
    8000269c:	8ff9                	and	a5,a5,a4
    8000269e:	02f92423          	sw	a5,40(s2)
    800026a2:	b769                	j	8000262c <handle_signals+0x80>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800026a4:	009b17bb          	sllw	a5,s6,s1
    800026a8:	fff7c793          	not	a5,a5
    800026ac:	8f7d                	and	a4,a4,a5
    800026ae:	02e92423          	sw	a4,40(s2)
    800026b2:	bfad                	j	8000262c <handle_signals+0x80>
  release(&p->lock);
    800026b4:	854a                	mv	a0,s2
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	5d2080e7          	jalr	1490(ra) # 80000c88 <release>
}
    800026be:	60e6                	ld	ra,88(sp)
    800026c0:	6446                	ld	s0,80(sp)
    800026c2:	64a6                	ld	s1,72(sp)
    800026c4:	6906                	ld	s2,64(sp)
    800026c6:	79e2                	ld	s3,56(sp)
    800026c8:	7a42                	ld	s4,48(sp)
    800026ca:	7aa2                	ld	s5,40(sp)
    800026cc:	7b02                	ld	s6,32(sp)
    800026ce:	6be2                	ld	s7,24(sp)
    800026d0:	6c42                	ld	s8,16(sp)
    800026d2:	6ca2                	ld	s9,8(sp)
    800026d4:	6125                	addi	sp,sp,96
    800026d6:	8082                	ret

00000000800026d8 <sleep>:
// ADDED Q3
// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800026d8:	7179                	addi	sp,sp,-48
    800026da:	f406                	sd	ra,40(sp)
    800026dc:	f022                	sd	s0,32(sp)
    800026de:	ec26                	sd	s1,24(sp)
    800026e0:	e84a                	sd	s2,16(sp)
    800026e2:	e44e                	sd	s3,8(sp)
    800026e4:	1800                	addi	s0,sp,48
    800026e6:	89aa                	mv	s3,a0
    800026e8:	892e                	mv	s2,a1
  struct thread *t = mythread();
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	382080e7          	jalr	898(ra) # 80001a6c <mythread>
    800026f2:	84aa                	mv	s1,a0
  // Once we hold t->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks t->lock),
  // so it's okay to release lk.

  acquire(&t->lock);  //DOC: sleeplock1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4ce080e7          	jalr	1230(ra) # 80000bc2 <acquire>
  release(lk);
    800026fc:	854a                	mv	a0,s2
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	58a080e7          	jalr	1418(ra) # 80000c88 <release>

  // Go to sleep.
  t->chan = chan;
    80002706:	0334b023          	sd	s3,32(s1)
  t->state = SLEEPING;
    8000270a:	4789                	li	a5,2
    8000270c:	cc9c                	sw	a5,24(s1)

  sched();
    8000270e:	00000097          	auipc	ra,0x0
    80002712:	cf0080e7          	jalr	-784(ra) # 800023fe <sched>

  // Tidy up.
  t->chan = 0;
    80002716:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&t->lock);
    8000271a:	8526                	mv	a0,s1
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	56c080e7          	jalr	1388(ra) # 80000c88 <release>
  acquire(lk);
    80002724:	854a                	mv	a0,s2
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	49c080e7          	jalr	1180(ra) # 80000bc2 <acquire>
}
    8000272e:	70a2                	ld	ra,40(sp)
    80002730:	7402                	ld	s0,32(sp)
    80002732:	64e2                	ld	s1,24(sp)
    80002734:	6942                	ld	s2,16(sp)
    80002736:	69a2                	ld	s3,8(sp)
    80002738:	6145                	addi	sp,sp,48
    8000273a:	8082                	ret

000000008000273c <wait>:
{
    8000273c:	715d                	addi	sp,sp,-80
    8000273e:	e486                	sd	ra,72(sp)
    80002740:	e0a2                	sd	s0,64(sp)
    80002742:	fc26                	sd	s1,56(sp)
    80002744:	f84a                	sd	s2,48(sp)
    80002746:	f44e                	sd	s3,40(sp)
    80002748:	f052                	sd	s4,32(sp)
    8000274a:	ec56                	sd	s5,24(sp)
    8000274c:	e85a                	sd	s6,16(sp)
    8000274e:	e45e                	sd	s7,8(sp)
    80002750:	0880                	addi	s0,sp,80
    80002752:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	2de080e7          	jalr	734(ra) # 80001a32 <myproc>
    8000275c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000275e:	00010517          	auipc	a0,0x10
    80002762:	b7250513          	addi	a0,a0,-1166 # 800122d0 <wait_lock>
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	45c080e7          	jalr	1116(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000276e:	4a89                	li	s5,2
        havekids = 1;
    80002770:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002772:	6985                	lui	s3,0x1
    80002774:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80002778:	00032a17          	auipc	s4,0x32
    8000277c:	f88a0a13          	addi	s4,s4,-120 # 80034700 <tickslock>
    havekids = 0;
    80002780:	4701                	li	a4,0
    for(np = proc; np < &proc[NPROC]; np++){
    80002782:	00010497          	auipc	s1,0x10
    80002786:	f7e48493          	addi	s1,s1,-130 # 80012700 <proc>
    8000278a:	a0b5                	j	800027f6 <wait+0xba>
          pid = np->pid;
    8000278c:	0244a983          	lw	s3,36(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002790:	000b8e63          	beqz	s7,800027ac <wait+0x70>
    80002794:	4691                	li	a3,4
    80002796:	02048613          	addi	a2,s1,32
    8000279a:	85de                	mv	a1,s7
    8000279c:	1d893503          	ld	a0,472(s2)
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	ec2080e7          	jalr	-318(ra) # 80001662 <copyout>
    800027a8:	02054563          	bltz	a0,800027d2 <wait+0x96>
          freeproc(np);
    800027ac:	8526                	mv	a0,s1
    800027ae:	fffff097          	auipc	ra,0xfffff
    800027b2:	598080e7          	jalr	1432(ra) # 80001d46 <freeproc>
          release(&np->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	4d0080e7          	jalr	1232(ra) # 80000c88 <release>
          release(&wait_lock);
    800027c0:	00010517          	auipc	a0,0x10
    800027c4:	b1050513          	addi	a0,a0,-1264 # 800122d0 <wait_lock>
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	4c0080e7          	jalr	1216(ra) # 80000c88 <release>
          return pid;
    800027d0:	a09d                	j	80002836 <wait+0xfa>
            release(&np->lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	4b4080e7          	jalr	1204(ra) # 80000c88 <release>
            release(&wait_lock);
    800027dc:	00010517          	auipc	a0,0x10
    800027e0:	af450513          	addi	a0,a0,-1292 # 800122d0 <wait_lock>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	4a4080e7          	jalr	1188(ra) # 80000c88 <release>
            return -1;
    800027ec:	59fd                	li	s3,-1
    800027ee:	a0a1                	j	80002836 <wait+0xfa>
    for(np = proc; np < &proc[NPROC]; np++){
    800027f0:	94ce                	add	s1,s1,s3
    800027f2:	03448563          	beq	s1,s4,8000281c <wait+0xe0>
      if(np->parent == p){
    800027f6:	1c84b783          	ld	a5,456(s1)
    800027fa:	ff279be3          	bne	a5,s2,800027f0 <wait+0xb4>
        acquire(&np->lock);
    800027fe:	8526                	mv	a0,s1
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	3c2080e7          	jalr	962(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002808:	4c9c                	lw	a5,24(s1)
    8000280a:	f95781e3          	beq	a5,s5,8000278c <wait+0x50>
        release(&np->lock);
    8000280e:	8526                	mv	a0,s1
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	478080e7          	jalr	1144(ra) # 80000c88 <release>
        havekids = 1;
    80002818:	875a                	mv	a4,s6
    8000281a:	bfd9                	j	800027f0 <wait+0xb4>
    if(!havekids || p->killed){
    8000281c:	c701                	beqz	a4,80002824 <wait+0xe8>
    8000281e:	01c92783          	lw	a5,28(s2)
    80002822:	c795                	beqz	a5,8000284e <wait+0x112>
      release(&wait_lock);
    80002824:	00010517          	auipc	a0,0x10
    80002828:	aac50513          	addi	a0,a0,-1364 # 800122d0 <wait_lock>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	45c080e7          	jalr	1116(ra) # 80000c88 <release>
      return -1;
    80002834:	59fd                	li	s3,-1
}
    80002836:	854e                	mv	a0,s3
    80002838:	60a6                	ld	ra,72(sp)
    8000283a:	6406                	ld	s0,64(sp)
    8000283c:	74e2                	ld	s1,56(sp)
    8000283e:	7942                	ld	s2,48(sp)
    80002840:	79a2                	ld	s3,40(sp)
    80002842:	7a02                	ld	s4,32(sp)
    80002844:	6ae2                	ld	s5,24(sp)
    80002846:	6b42                	ld	s6,16(sp)
    80002848:	6ba2                	ld	s7,8(sp)
    8000284a:	6161                	addi	sp,sp,80
    8000284c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000284e:	00010597          	auipc	a1,0x10
    80002852:	a8258593          	addi	a1,a1,-1406 # 800122d0 <wait_lock>
    80002856:	854a                	mv	a0,s2
    80002858:	00000097          	auipc	ra,0x0
    8000285c:	e80080e7          	jalr	-384(ra) # 800026d8 <sleep>
    havekids = 0;
    80002860:	b705                	j	80002780 <wait+0x44>

0000000080002862 <wakeup>:
// Wake up all threads sleeping on chan.
// Must be called without any t->lock.
// ADDED Q3
void
wakeup(void *chan)
{
    80002862:	715d                	addi	sp,sp,-80
    80002864:	e486                	sd	ra,72(sp)
    80002866:	e0a2                	sd	s0,64(sp)
    80002868:	fc26                	sd	s1,56(sp)
    8000286a:	f84a                	sd	s2,48(sp)
    8000286c:	f44e                	sd	s3,40(sp)
    8000286e:	f052                	sd	s4,32(sp)
    80002870:	ec56                	sd	s5,24(sp)
    80002872:	e85a                	sd	s6,16(sp)
    80002874:	e45e                	sd	s7,8(sp)
    80002876:	0880                	addi	s0,sp,80
    80002878:	8a2a                	mv	s4,a0
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    8000287a:	00010917          	auipc	s2,0x10
    8000287e:	6fe90913          	addi	s2,s2,1790 # 80012f78 <proc+0x878>
    80002882:	00032b17          	auipc	s6,0x32
    80002886:	6f6b0b13          	addi	s6,s6,1782 # 80034f78 <bcache+0x860>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
      if(t != mythread()){
        acquire(&t->lock);
        if (t->state == SLEEPING && t->chan == chan) {
    8000288a:	4989                	li	s3,2
          t->state = RUNNABLE;
    8000288c:	4b8d                	li	s7,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000288e:	6a85                	lui	s5,0x1
    80002890:	880a8a93          	addi	s5,s5,-1920 # 880 <_entry-0x7ffff780>
    80002894:	a089                	j	800028d6 <wakeup+0x74>
        }
        release(&t->lock);
    80002896:	8526                	mv	a0,s1
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	3f0080e7          	jalr	1008(ra) # 80000c88 <release>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800028a0:	0c048493          	addi	s1,s1,192
    800028a4:	03248663          	beq	s1,s2,800028d0 <wakeup+0x6e>
      if(t != mythread()){
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	1c4080e7          	jalr	452(ra) # 80001a6c <mythread>
    800028b0:	fea488e3          	beq	s1,a0,800028a0 <wakeup+0x3e>
        acquire(&t->lock);
    800028b4:	8526                	mv	a0,s1
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	30c080e7          	jalr	780(ra) # 80000bc2 <acquire>
        if (t->state == SLEEPING && t->chan == chan) {
    800028be:	4c9c                	lw	a5,24(s1)
    800028c0:	fd379be3          	bne	a5,s3,80002896 <wakeup+0x34>
    800028c4:	709c                	ld	a5,32(s1)
    800028c6:	fd4798e3          	bne	a5,s4,80002896 <wakeup+0x34>
          t->state = RUNNABLE;
    800028ca:	0174ac23          	sw	s7,24(s1)
    800028ce:	b7e1                	j	80002896 <wakeup+0x34>
  for(p = proc; p < &proc[NPROC]; p++) {
    800028d0:	9956                	add	s2,s2,s5
    800028d2:	01690563          	beq	s2,s6,800028dc <wakeup+0x7a>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800028d6:	a0090493          	addi	s1,s2,-1536
    800028da:	b7f9                	j	800028a8 <wakeup+0x46>
      }
    }
  }
}
    800028dc:	60a6                	ld	ra,72(sp)
    800028de:	6406                	ld	s0,64(sp)
    800028e0:	74e2                	ld	s1,56(sp)
    800028e2:	7942                	ld	s2,48(sp)
    800028e4:	79a2                	ld	s3,40(sp)
    800028e6:	7a02                	ld	s4,32(sp)
    800028e8:	6ae2                	ld	s5,24(sp)
    800028ea:	6b42                	ld	s6,16(sp)
    800028ec:	6ba2                	ld	s7,8(sp)
    800028ee:	6161                	addi	sp,sp,80
    800028f0:	8082                	ret

00000000800028f2 <reparent>:
{
    800028f2:	7139                	addi	sp,sp,-64
    800028f4:	fc06                	sd	ra,56(sp)
    800028f6:	f822                	sd	s0,48(sp)
    800028f8:	f426                	sd	s1,40(sp)
    800028fa:	f04a                	sd	s2,32(sp)
    800028fc:	ec4e                	sd	s3,24(sp)
    800028fe:	e852                	sd	s4,16(sp)
    80002900:	e456                	sd	s5,8(sp)
    80002902:	0080                	addi	s0,sp,64
    80002904:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002906:	00010497          	auipc	s1,0x10
    8000290a:	dfa48493          	addi	s1,s1,-518 # 80012700 <proc>
      pp->parent = initproc;
    8000290e:	00007a97          	auipc	s5,0x7
    80002912:	71aa8a93          	addi	s5,s5,1818 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002916:	6905                	lui	s2,0x1
    80002918:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    8000291c:	00032a17          	auipc	s4,0x32
    80002920:	de4a0a13          	addi	s4,s4,-540 # 80034700 <tickslock>
    80002924:	a021                	j	8000292c <reparent+0x3a>
    80002926:	94ca                	add	s1,s1,s2
    80002928:	01448f63          	beq	s1,s4,80002946 <reparent+0x54>
    if(pp->parent == p){
    8000292c:	1c84b783          	ld	a5,456(s1)
    80002930:	ff379be3          	bne	a5,s3,80002926 <reparent+0x34>
      pp->parent = initproc;
    80002934:	000ab503          	ld	a0,0(s5)
    80002938:	1ca4b423          	sd	a0,456(s1)
      wakeup(initproc);
    8000293c:	00000097          	auipc	ra,0x0
    80002940:	f26080e7          	jalr	-218(ra) # 80002862 <wakeup>
    80002944:	b7cd                	j	80002926 <reparent+0x34>
}
    80002946:	70e2                	ld	ra,56(sp)
    80002948:	7442                	ld	s0,48(sp)
    8000294a:	74a2                	ld	s1,40(sp)
    8000294c:	7902                	ld	s2,32(sp)
    8000294e:	69e2                	ld	s3,24(sp)
    80002950:	6a42                	ld	s4,16(sp)
    80002952:	6aa2                	ld	s5,8(sp)
    80002954:	6121                	addi	sp,sp,64
    80002956:	8082                	ret

0000000080002958 <kill>:
// ADDED Q2.2.1
int
kill(int pid, int signum)
{
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    80002958:	47fd                	li	a5,31
    8000295a:	06b7ef63          	bltu	a5,a1,800029d8 <kill+0x80>
{
    8000295e:	7139                	addi	sp,sp,-64
    80002960:	fc06                	sd	ra,56(sp)
    80002962:	f822                	sd	s0,48(sp)
    80002964:	f426                	sd	s1,40(sp)
    80002966:	f04a                	sd	s2,32(sp)
    80002968:	ec4e                	sd	s3,24(sp)
    8000296a:	e852                	sd	s4,16(sp)
    8000296c:	e456                	sd	s5,8(sp)
    8000296e:	0080                	addi	s0,sp,64
    80002970:	892a                	mv	s2,a0
    80002972:	8aae                	mv	s5,a1
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002974:	00010497          	auipc	s1,0x10
    80002978:	d8c48493          	addi	s1,s1,-628 # 80012700 <proc>
    8000297c:	6985                	lui	s3,0x1
    8000297e:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80002982:	00032a17          	auipc	s4,0x32
    80002986:	d7ea0a13          	addi	s4,s4,-642 # 80034700 <tickslock>
    acquire(&p->lock);
    8000298a:	8526                	mv	a0,s1
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	236080e7          	jalr	566(ra) # 80000bc2 <acquire>
    if(p->pid == pid) {
    80002994:	50dc                	lw	a5,36(s1)
    80002996:	01278c63          	beq	a5,s2,800029ae <kill+0x56>
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000299a:	8526                	mv	a0,s1
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	2ec080e7          	jalr	748(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800029a4:	94ce                	add	s1,s1,s3
    800029a6:	ff4492e3          	bne	s1,s4,8000298a <kill+0x32>
  }
  // no such pid
  return -1;
    800029aa:	557d                	li	a0,-1
    800029ac:	a829                	j	800029c6 <kill+0x6e>
      p->pending_signals = p->pending_signals | (1 << signum);
    800029ae:	4785                	li	a5,1
    800029b0:	0157973b          	sllw	a4,a5,s5
    800029b4:	549c                	lw	a5,40(s1)
    800029b6:	8fd9                	or	a5,a5,a4
    800029b8:	d49c                	sw	a5,40(s1)
      release(&p->lock);
    800029ba:	8526                	mv	a0,s1
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	2cc080e7          	jalr	716(ra) # 80000c88 <release>
      return 0;
    800029c4:	4501                	li	a0,0
}
    800029c6:	70e2                	ld	ra,56(sp)
    800029c8:	7442                	ld	s0,48(sp)
    800029ca:	74a2                	ld	s1,40(sp)
    800029cc:	7902                	ld	s2,32(sp)
    800029ce:	69e2                	ld	s3,24(sp)
    800029d0:	6a42                	ld	s4,16(sp)
    800029d2:	6aa2                	ld	s5,8(sp)
    800029d4:	6121                	addi	sp,sp,64
    800029d6:	8082                	ret
    return -1;
    800029d8:	557d                	li	a0,-1
}
    800029da:	8082                	ret

00000000800029dc <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029dc:	7179                	addi	sp,sp,-48
    800029de:	f406                	sd	ra,40(sp)
    800029e0:	f022                	sd	s0,32(sp)
    800029e2:	ec26                	sd	s1,24(sp)
    800029e4:	e84a                	sd	s2,16(sp)
    800029e6:	e44e                	sd	s3,8(sp)
    800029e8:	e052                	sd	s4,0(sp)
    800029ea:	1800                	addi	s0,sp,48
    800029ec:	84aa                	mv	s1,a0
    800029ee:	892e                	mv	s2,a1
    800029f0:	89b2                	mv	s3,a2
    800029f2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	03e080e7          	jalr	62(ra) # 80001a32 <myproc>
  if(user_dst){
    800029fc:	c095                	beqz	s1,80002a20 <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    800029fe:	86d2                	mv	a3,s4
    80002a00:	864e                	mv	a2,s3
    80002a02:	85ca                	mv	a1,s2
    80002a04:	1d853503          	ld	a0,472(a0)
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	c5a080e7          	jalr	-934(ra) # 80001662 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a10:	70a2                	ld	ra,40(sp)
    80002a12:	7402                	ld	s0,32(sp)
    80002a14:	64e2                	ld	s1,24(sp)
    80002a16:	6942                	ld	s2,16(sp)
    80002a18:	69a2                	ld	s3,8(sp)
    80002a1a:	6a02                	ld	s4,0(sp)
    80002a1c:	6145                	addi	sp,sp,48
    80002a1e:	8082                	ret
    memmove((char *)dst, src, len);
    80002a20:	000a061b          	sext.w	a2,s4
    80002a24:	85ce                	mv	a1,s3
    80002a26:	854a                	mv	a0,s2
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	316080e7          	jalr	790(ra) # 80000d3e <memmove>
    return 0;
    80002a30:	8526                	mv	a0,s1
    80002a32:	bff9                	j	80002a10 <either_copyout+0x34>

0000000080002a34 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a34:	7179                	addi	sp,sp,-48
    80002a36:	f406                	sd	ra,40(sp)
    80002a38:	f022                	sd	s0,32(sp)
    80002a3a:	ec26                	sd	s1,24(sp)
    80002a3c:	e84a                	sd	s2,16(sp)
    80002a3e:	e44e                	sd	s3,8(sp)
    80002a40:	e052                	sd	s4,0(sp)
    80002a42:	1800                	addi	s0,sp,48
    80002a44:	892a                	mv	s2,a0
    80002a46:	84ae                	mv	s1,a1
    80002a48:	89b2                	mv	s3,a2
    80002a4a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	fe6080e7          	jalr	-26(ra) # 80001a32 <myproc>
  if(user_src){
    80002a54:	c095                	beqz	s1,80002a78 <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    80002a56:	86d2                	mv	a3,s4
    80002a58:	864e                	mv	a2,s3
    80002a5a:	85ca                	mv	a1,s2
    80002a5c:	1d853503          	ld	a0,472(a0)
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	c8e080e7          	jalr	-882(ra) # 800016ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a68:	70a2                	ld	ra,40(sp)
    80002a6a:	7402                	ld	s0,32(sp)
    80002a6c:	64e2                	ld	s1,24(sp)
    80002a6e:	6942                	ld	s2,16(sp)
    80002a70:	69a2                	ld	s3,8(sp)
    80002a72:	6a02                	ld	s4,0(sp)
    80002a74:	6145                	addi	sp,sp,48
    80002a76:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a78:	000a061b          	sext.w	a2,s4
    80002a7c:	85ce                	mv	a1,s3
    80002a7e:	854a                	mv	a0,s2
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	2be080e7          	jalr	702(ra) # 80000d3e <memmove>
    return 0;
    80002a88:	8526                	mv	a0,s1
    80002a8a:	bff9                	j	80002a68 <either_copyin+0x34>

0000000080002a8c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a8c:	715d                	addi	sp,sp,-80
    80002a8e:	e486                	sd	ra,72(sp)
    80002a90:	e0a2                	sd	s0,64(sp)
    80002a92:	fc26                	sd	s1,56(sp)
    80002a94:	f84a                	sd	s2,48(sp)
    80002a96:	f44e                	sd	s3,40(sp)
    80002a98:	f052                	sd	s4,32(sp)
    80002a9a:	ec56                	sd	s5,24(sp)
    80002a9c:	e85a                	sd	s6,16(sp)
    80002a9e:	e45e                	sd	s7,8(sp)
    80002aa0:	e062                	sd	s8,0(sp)
    80002aa2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	7ac50513          	addi	a0,a0,1964 # 80009250 <digits+0x210>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	ac8080e7          	jalr	-1336(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ab4:	00010497          	auipc	s1,0x10
    80002ab8:	eb448493          	addi	s1,s1,-332 # 80012968 <proc+0x268>
    80002abc:	00032997          	auipc	s3,0x32
    80002ac0:	eac98993          	addi	s3,s3,-340 # 80034968 <bcache+0x250>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ac4:	4b89                	li	s7,2
      state = states[p->state];
    else
      state = "???";
    80002ac6:	00006a17          	auipc	s4,0x6
    80002aca:	7e2a0a13          	addi	s4,s4,2018 # 800092a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002ace:	00006b17          	auipc	s6,0x6
    80002ad2:	7e2b0b13          	addi	s6,s6,2018 # 800092b0 <digits+0x270>
    printf("\n");
    80002ad6:	00006a97          	auipc	s5,0x6
    80002ada:	77aa8a93          	addi	s5,s5,1914 # 80009250 <digits+0x210>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ade:	00007c17          	auipc	s8,0x7
    80002ae2:	812c0c13          	addi	s8,s8,-2030 # 800092f0 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ae6:	6905                	lui	s2,0x1
    80002ae8:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    80002aec:	a005                	j	80002b0c <procdump+0x80>
    printf("%d %s %s", p->pid, state, p->name);
    80002aee:	dbc6a583          	lw	a1,-580(a3)
    80002af2:	855a                	mv	a0,s6
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a80080e7          	jalr	-1408(ra) # 80000574 <printf>
    printf("\n");
    80002afc:	8556                	mv	a0,s5
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a76080e7          	jalr	-1418(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b06:	94ca                	add	s1,s1,s2
    80002b08:	03348263          	beq	s1,s3,80002b2c <procdump+0xa0>
    if(p->state == UNUSED)
    80002b0c:	86a6                	mv	a3,s1
    80002b0e:	db04a783          	lw	a5,-592(s1)
    80002b12:	dbf5                	beqz	a5,80002b06 <procdump+0x7a>
      state = "???";
    80002b14:	8652                	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b16:	fcfbece3          	bltu	s7,a5,80002aee <procdump+0x62>
    80002b1a:	02079713          	slli	a4,a5,0x20
    80002b1e:	01d75793          	srli	a5,a4,0x1d
    80002b22:	97e2                	add	a5,a5,s8
    80002b24:	6390                	ld	a2,0(a5)
    80002b26:	f661                	bnez	a2,80002aee <procdump+0x62>
      state = "???";
    80002b28:	8652                	mv	a2,s4
    80002b2a:	b7d1                	j	80002aee <procdump+0x62>
  }
}
    80002b2c:	60a6                	ld	ra,72(sp)
    80002b2e:	6406                	ld	s0,64(sp)
    80002b30:	74e2                	ld	s1,56(sp)
    80002b32:	7942                	ld	s2,48(sp)
    80002b34:	79a2                	ld	s3,40(sp)
    80002b36:	7a02                	ld	s4,32(sp)
    80002b38:	6ae2                	ld	s5,24(sp)
    80002b3a:	6b42                	ld	s6,16(sp)
    80002b3c:	6ba2                	ld	s7,8(sp)
    80002b3e:	6c02                	ld	s8,0(sp)
    80002b40:	6161                	addi	sp,sp,80
    80002b42:	8082                	ret

0000000080002b44 <sigprocmask>:

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
    80002b44:	7179                	addi	sp,sp,-48
    80002b46:	f406                	sd	ra,40(sp)
    80002b48:	f022                	sd	s0,32(sp)
    80002b4a:	ec26                	sd	s1,24(sp)
    80002b4c:	e84a                	sd	s2,16(sp)
    80002b4e:	e44e                	sd	s3,8(sp)
    80002b50:	1800                	addi	s0,sp,48
    80002b52:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	ede080e7          	jalr	-290(ra) # 80001a32 <myproc>
    80002b5c:	84aa                	mv	s1,a0
  uint old_mask = p->signal_mask;
    80002b5e:	02c52983          	lw	s3,44(a0)
  acquire(&p->lock);
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	060080e7          	jalr	96(ra) # 80000bc2 <acquire>

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    80002b6a:	000207b7          	lui	a5,0x20
    80002b6e:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    80002b72:	00f977b3          	and	a5,s2,a5
    80002b76:	e385                	bnez	a5,80002b96 <sigprocmask+0x52>
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
    80002b78:	0324a623          	sw	s2,44(s1)
  release(&p->lock);
    80002b7c:	8526                	mv	a0,s1
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	10a080e7          	jalr	266(ra) # 80000c88 <release>
  return old_mask;
}
    80002b86:	854e                	mv	a0,s3
    80002b88:	70a2                	ld	ra,40(sp)
    80002b8a:	7402                	ld	s0,32(sp)
    80002b8c:	64e2                	ld	s1,24(sp)
    80002b8e:	6942                	ld	s2,16(sp)
    80002b90:	69a2                	ld	s3,8(sp)
    80002b92:	6145                	addi	sp,sp,48
    80002b94:	8082                	ret
    release(&p->lock);
    80002b96:	8526                	mv	a0,s1
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	0f0080e7          	jalr	240(ra) # 80000c88 <release>
    return -1;
    80002ba0:	59fd                	li	s3,-1
    80002ba2:	b7d5                	j	80002b86 <sigprocmask+0x42>

0000000080002ba4 <sigaction>:

// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
    80002ba4:	715d                	addi	sp,sp,-80
    80002ba6:	e486                	sd	ra,72(sp)
    80002ba8:	e0a2                	sd	s0,64(sp)
    80002baa:	fc26                	sd	s1,56(sp)
    80002bac:	f84a                	sd	s2,48(sp)
    80002bae:	f44e                	sd	s3,40(sp)
    80002bb0:	f052                	sd	s4,32(sp)
    80002bb2:	0880                	addi	s0,sp,80
    80002bb4:	84aa                	mv	s1,a0
    80002bb6:	89ae                	mv	s3,a1
    80002bb8:	8a32                	mv	s4,a2
  struct proc *p = myproc();
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	e78080e7          	jalr	-392(ra) # 80001a32 <myproc>
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;

  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    80002bc2:	0004879b          	sext.w	a5,s1
    80002bc6:	477d                	li	a4,31
    80002bc8:	0cf76763          	bltu	a4,a5,80002c96 <sigaction+0xf2>
    80002bcc:	892a                	mv	s2,a0
    80002bce:	37dd                	addiw	a5,a5,-9
    80002bd0:	9bdd                	andi	a5,a5,-9
    80002bd2:	2781                	sext.w	a5,a5
    80002bd4:	c3f9                	beqz	a5,80002c9a <sigaction+0xf6>
    return -1;
  }

  acquire(&p->lock);
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	fec080e7          	jalr	-20(ra) # 80000bc2 <acquire>

  if(act && copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    80002bde:	0c098063          	beqz	s3,80002c9e <sigaction+0xfa>
    80002be2:	46c1                	li	a3,16
    80002be4:	864e                	mv	a2,s3
    80002be6:	fc040593          	addi	a1,s0,-64
    80002bea:	1d893503          	ld	a0,472(s2)
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	b00080e7          	jalr	-1280(ra) # 800016ee <copyin>
    80002bf6:	08054263          	bltz	a0,80002c7a <sigaction+0xd6>
    release(&p->lock);
    return -1;
  }
  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((kernel_act.sigmask & (1 << SIGKILL)) != 0) || ((kernel_act.sigmask & (1 << SIGSTOP)) != 0)) ) {
    80002bfa:	fc843783          	ld	a5,-56(s0)
    80002bfe:	00020737          	lui	a4,0x20
    80002c02:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    80002c06:	8ff9                	and	a5,a5,a4
    80002c08:	e3c1                	bnez	a5,80002c88 <sigaction+0xe4>
    return -1;
  }

  

  if (oldact) {
    80002c0a:	020a0c63          	beqz	s4,80002c42 <sigaction+0x9e>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002c0e:	00648793          	addi	a5,s1,6
    80002c12:	078e                	slli	a5,a5,0x3
    80002c14:	97ca                	add	a5,a5,s2
    80002c16:	679c                	ld	a5,8(a5)
    80002c18:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002c1c:	04c48793          	addi	a5,s1,76
    80002c20:	078a                	slli	a5,a5,0x2
    80002c22:	97ca                	add	a5,a5,s2
    80002c24:	479c                	lw	a5,8(a5)
    80002c26:	faf42c23          	sw	a5,-72(s0)

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002c2a:	46c1                	li	a3,16
    80002c2c:	fb040613          	addi	a2,s0,-80
    80002c30:	85d2                	mv	a1,s4
    80002c32:	1d893503          	ld	a0,472(s2)
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	a2c080e7          	jalr	-1492(ra) # 80001662 <copyout>
    80002c3e:	08054c63          	bltz	a0,80002cd6 <sigaction+0x132>
      return -1;
    }
  }

  if (act) {
    p->signal_handlers[signum] = kernel_act.sa_handler;
    80002c42:	00648793          	addi	a5,s1,6
    80002c46:	078e                	slli	a5,a5,0x3
    80002c48:	97ca                	add	a5,a5,s2
    80002c4a:	fc043703          	ld	a4,-64(s0)
    80002c4e:	e798                	sd	a4,8(a5)
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
    80002c50:	04c48493          	addi	s1,s1,76
    80002c54:	048a                	slli	s1,s1,0x2
    80002c56:	94ca                	add	s1,s1,s2
    80002c58:	fc842783          	lw	a5,-56(s0)
    80002c5c:	c49c                	sw	a5,8(s1)
  }

  release(&p->lock);
    80002c5e:	854a                	mv	a0,s2
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	028080e7          	jalr	40(ra) # 80000c88 <release>
  return 0;
    80002c68:	4501                	li	a0,0
}
    80002c6a:	60a6                	ld	ra,72(sp)
    80002c6c:	6406                	ld	s0,64(sp)
    80002c6e:	74e2                	ld	s1,56(sp)
    80002c70:	7942                	ld	s2,48(sp)
    80002c72:	79a2                	ld	s3,40(sp)
    80002c74:	7a02                	ld	s4,32(sp)
    80002c76:	6161                	addi	sp,sp,80
    80002c78:	8082                	ret
    release(&p->lock);
    80002c7a:	854a                	mv	a0,s2
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	00c080e7          	jalr	12(ra) # 80000c88 <release>
    return -1;
    80002c84:	557d                	li	a0,-1
    80002c86:	b7d5                	j	80002c6a <sigaction+0xc6>
    release(&p->lock);
    80002c88:	854a                	mv	a0,s2
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	ffe080e7          	jalr	-2(ra) # 80000c88 <release>
    return -1;
    80002c92:	557d                	li	a0,-1
    80002c94:	bfd9                	j	80002c6a <sigaction+0xc6>
    return -1;
    80002c96:	557d                	li	a0,-1
    80002c98:	bfc9                	j	80002c6a <sigaction+0xc6>
    80002c9a:	557d                	li	a0,-1
    80002c9c:	b7f9                	j	80002c6a <sigaction+0xc6>
  if (oldact) {
    80002c9e:	fc0a00e3          	beqz	s4,80002c5e <sigaction+0xba>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002ca2:	00648793          	addi	a5,s1,6
    80002ca6:	078e                	slli	a5,a5,0x3
    80002ca8:	97ca                	add	a5,a5,s2
    80002caa:	679c                	ld	a5,8(a5)
    80002cac:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002cb0:	04c48493          	addi	s1,s1,76
    80002cb4:	048a                	slli	s1,s1,0x2
    80002cb6:	94ca                	add	s1,s1,s2
    80002cb8:	449c                	lw	a5,8(s1)
    80002cba:	faf42c23          	sw	a5,-72(s0)
    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002cbe:	46c1                	li	a3,16
    80002cc0:	fb040613          	addi	a2,s0,-80
    80002cc4:	85d2                	mv	a1,s4
    80002cc6:	1d893503          	ld	a0,472(s2)
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	998080e7          	jalr	-1640(ra) # 80001662 <copyout>
    80002cd2:	f80556e3          	bgez	a0,80002c5e <sigaction+0xba>
      release(&p->lock);
    80002cd6:	854a                	mv	a0,s2
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	fb0080e7          	jalr	-80(ra) # 80000c88 <release>
      return -1;
    80002ce0:	557d                	li	a0,-1
    80002ce2:	b761                	j	80002c6a <sigaction+0xc6>

0000000080002ce4 <sigret>:

// ADDED Q2.1.5
// ADDED Q3
void
sigret(void)
{
    80002ce4:	1101                	addi	sp,sp,-32
    80002ce6:	ec06                	sd	ra,24(sp)
    80002ce8:	e822                	sd	s0,16(sp)
    80002cea:	e426                	sd	s1,8(sp)
    80002cec:	e04a                	sd	s2,0(sp)
    80002cee:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	d7c080e7          	jalr	-644(ra) # 80001a6c <mythread>
    80002cf8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	d38080e7          	jalr	-712(ra) # 80001a32 <myproc>
    80002d02:	84aa                	mv	s1,a0

  acquire(&p->lock);
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	ebe080e7          	jalr	-322(ra) # 80000bc2 <acquire>
  acquire(&t->lock);
    80002d0c:	854a                	mv	a0,s2
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	eb4080e7          	jalr	-332(ra) # 80000bc2 <acquire>
  memmove(t->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    80002d16:	12000613          	li	a2,288
    80002d1a:	1b84b583          	ld	a1,440(s1)
    80002d1e:	04893503          	ld	a0,72(s2)
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	01c080e7          	jalr	28(ra) # 80000d3e <memmove>
  p->signal_mask = p->signal_mask_backup;
    80002d2a:	589c                	lw	a5,48(s1)
    80002d2c:	d4dc                	sw	a5,44(s1)
  p->handling_user_level_signal = 0;
    80002d2e:	1c04a223          	sw	zero,452(s1)
  release(&t->lock);
    80002d32:	854a                	mv	a0,s2
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	f54080e7          	jalr	-172(ra) # 80000c88 <release>
  release(&p->lock);
    80002d3c:	8526                	mv	a0,s1
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	f4a080e7          	jalr	-182(ra) # 80000c88 <release>
}
    80002d46:	60e2                	ld	ra,24(sp)
    80002d48:	6442                	ld	s0,16(sp)
    80002d4a:	64a2                	ld	s1,8(sp)
    80002d4c:	6902                	ld	s2,0(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret

0000000080002d52 <kthread_create>:

int
//kthread_create(void (*start_func)(), void* stack)
kthread_create(uint64 start_func, uint64 stack) // REMOVE?
{ 
    80002d52:	7179                	addi	sp,sp,-48
    80002d54:	f406                	sd	ra,40(sp)
    80002d56:	f022                	sd	s0,32(sp)
    80002d58:	ec26                	sd	s1,24(sp)
    80002d5a:	e84a                	sd	s2,16(sp)
    80002d5c:	e44e                	sd	s3,8(sp)
    80002d5e:	e052                	sd	s4,0(sp)
    80002d60:	1800                	addi	s0,sp,48
    80002d62:	89aa                	mv	s3,a0
    80002d64:	892e                	mv	s2,a1
    struct thread* t = mythread();
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	d06080e7          	jalr	-762(ra) # 80001a6c <mythread>
    80002d6e:	8a2a                	mv	s4,a0
    struct thread* nt;

    if((nt = allocthread(myproc())) == 0) {
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	cc2080e7          	jalr	-830(ra) # 80001a32 <myproc>
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	dfe080e7          	jalr	-514(ra) # 80001b76 <allocthread>
    80002d80:	c135                	beqz	a0,80002de4 <kthread_create+0x92>
    80002d82:	84aa                	mv	s1,a0
        return -1;
    }
    *nt->trapframe = *t->trapframe;
    80002d84:	048a3683          	ld	a3,72(s4)
    80002d88:	87b6                	mv	a5,a3
    80002d8a:	6538                	ld	a4,72(a0)
    80002d8c:	12068693          	addi	a3,a3,288
    80002d90:	0007b803          	ld	a6,0(a5)
    80002d94:	6788                	ld	a0,8(a5)
    80002d96:	6b8c                	ld	a1,16(a5)
    80002d98:	6f90                	ld	a2,24(a5)
    80002d9a:	01073023          	sd	a6,0(a4)
    80002d9e:	e708                	sd	a0,8(a4)
    80002da0:	eb0c                	sd	a1,16(a4)
    80002da2:	ef10                	sd	a2,24(a4)
    80002da4:	02078793          	addi	a5,a5,32
    80002da8:	02070713          	addi	a4,a4,32
    80002dac:	fed792e3          	bne	a5,a3,80002d90 <kthread_create+0x3e>
    nt->trapframe->epc = (uint64)start_func;
    80002db0:	64bc                	ld	a5,72(s1)
    80002db2:	0137bc23          	sd	s3,24(a5)
    nt->trapframe->sp = (uint64)(stack + MAX_STACK_SIZE) - 16; // TODO: - 16? ..  
    80002db6:	64bc                	ld	a5,72(s1)
    80002db8:	6585                	lui	a1,0x1
    80002dba:	f9058593          	addi	a1,a1,-112 # f90 <_entry-0x7ffff070>
    80002dbe:	992e                	add	s2,s2,a1
    80002dc0:	0327b823          	sd	s2,48(a5)
    // It's stack pointer will be the "malloced" stack plus "STACK_SIZE" minus 16.
    nt->state = RUNNABLE;
    80002dc4:	478d                	li	a5,3
    80002dc6:	cc9c                	sw	a5,24(s1)

    release(&nt->lock);
    80002dc8:	8526                	mv	a0,s1
    80002dca:	ffffe097          	auipc	ra,0xffffe
    80002dce:	ebe080e7          	jalr	-322(ra) # 80000c88 <release>
    return nt->tid;
    80002dd2:	5888                	lw	a0,48(s1)
}
    80002dd4:	70a2                	ld	ra,40(sp)
    80002dd6:	7402                	ld	s0,32(sp)
    80002dd8:	64e2                	ld	s1,24(sp)
    80002dda:	6942                	ld	s2,16(sp)
    80002ddc:	69a2                	ld	s3,8(sp)
    80002dde:	6a02                	ld	s4,0(sp)
    80002de0:	6145                	addi	sp,sp,48
    80002de2:	8082                	ret
        return -1;
    80002de4:	557d                	li	a0,-1
    80002de6:	b7fd                	j	80002dd4 <kthread_create+0x82>

0000000080002de8 <exit_single_thread>:

void
exit_single_thread(int status) { // exit single thread when there are other threads in the process
    80002de8:	7179                	addi	sp,sp,-48
    80002dea:	f406                	sd	ra,40(sp)
    80002dec:	f022                	sd	s0,32(sp)
    80002dee:	ec26                	sd	s1,24(sp)
    80002df0:	e84a                	sd	s2,16(sp)
    80002df2:	e44e                	sd	s3,8(sp)
    80002df4:	1800                	addi	s0,sp,48
    80002df6:	892a                	mv	s2,a0
  struct thread *t = mythread();
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	c74080e7          	jalr	-908(ra) # 80001a6c <mythread>
    80002e00:	84aa                	mv	s1,a0
  acquire(&join_lock);
    80002e02:	0000f997          	auipc	s3,0xf
    80002e06:	4e698993          	addi	s3,s3,1254 # 800122e8 <join_lock>
    80002e0a:	854e                	mv	a0,s3
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	db6080e7          	jalr	-586(ra) # 80000bc2 <acquire>
  wakeup(t);
    80002e14:	8526                	mv	a0,s1
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	a4c080e7          	jalr	-1460(ra) # 80002862 <wakeup>

  acquire(&t->lock);
    80002e1e:	8526                	mv	a0,s1
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	da2080e7          	jalr	-606(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80002e28:	0324a623          	sw	s2,44(s1)
  t->state = ZOMBIE_T;
    80002e2c:	4795                	li	a5,5
    80002e2e:	cc9c                	sw	a5,24(s1)
  release(&join_lock);
    80002e30:	854e                	mv	a0,s3
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	e56080e7          	jalr	-426(ra) # 80000c88 <release>
  // Jump into the scheduler, never to return.
  sched();
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	5c4080e7          	jalr	1476(ra) # 800023fe <sched>
  panic("zombie exit");
    80002e42:	00006517          	auipc	a0,0x6
    80002e46:	47e50513          	addi	a0,a0,1150 # 800092c0 <digits+0x280>
    80002e4a:	ffffd097          	auipc	ra,0xffffd
    80002e4e:	6e0080e7          	jalr	1760(ra) # 8000052a <panic>

0000000080002e52 <kthread_join>:
  exit_single_thread(status);
}

int
kthread_join(int thread_id, int *status)
{
    80002e52:	7139                	addi	sp,sp,-64
    80002e54:	fc06                	sd	ra,56(sp)
    80002e56:	f822                	sd	s0,48(sp)
    80002e58:	f426                	sd	s1,40(sp)
    80002e5a:	f04a                	sd	s2,32(sp)
    80002e5c:	ec4e                	sd	s3,24(sp)
    80002e5e:	e852                	sd	s4,16(sp)
    80002e60:	e456                	sd	s5,8(sp)
    80002e62:	e05a                	sd	s6,0(sp)
    80002e64:	0080                	addi	s0,sp,64
    80002e66:	89aa                	mv	s3,a0
    80002e68:	8aae                	mv	s5,a1
  struct thread *jt  = 0;
  struct proc *p = myproc();  
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	bc8080e7          	jalr	-1080(ra) # 80001a32 <myproc>
    80002e72:	8a2a                	mv	s4,a0

  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002e74:	27850493          	addi	s1,a0,632
    80002e78:	6905                	lui	s2,0x1
    80002e7a:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    80002e7e:	992a                	add	s2,s2,a0
    80002e80:	a811                	j	80002e94 <kthread_join+0x42>
    if (temp_t != mythread() && thread_id == temp_t->tid) {
      jt = temp_t;
      release(&temp_t->lock);
      goto found;
    }
    release(&temp_t->lock);
    80002e82:	8526                	mv	a0,s1
    80002e84:	ffffe097          	auipc	ra,0xffffe
    80002e88:	e04080e7          	jalr	-508(ra) # 80000c88 <release>
  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002e8c:	0c048493          	addi	s1,s1,192
    80002e90:	09248e63          	beq	s1,s2,80002f2c <kthread_join+0xda>
    acquire(&temp_t->lock);
    80002e94:	8526                	mv	a0,s1
    80002e96:	ffffe097          	auipc	ra,0xffffe
    80002e9a:	d2c080e7          	jalr	-724(ra) # 80000bc2 <acquire>
    if (temp_t != mythread() && thread_id == temp_t->tid) {
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	bce080e7          	jalr	-1074(ra) # 80001a6c <mythread>
    80002ea6:	fca48ee3          	beq	s1,a0,80002e82 <kthread_join+0x30>
    80002eaa:	589c                	lw	a5,48(s1)
    80002eac:	fd379be3          	bne	a5,s3,80002e82 <kthread_join+0x30>
      release(&temp_t->lock);
    80002eb0:	8526                	mv	a0,s1
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	dd6080e7          	jalr	-554(ra) # 80000c88 <release>

  //not found
  return -1;

  found:
  acquire(&join_lock);
    80002eba:	0000f517          	auipc	a0,0xf
    80002ebe:	42e50513          	addi	a0,a0,1070 # 800122e8 <join_lock>
    80002ec2:	ffffe097          	auipc	ra,0xffffe
    80002ec6:	d00080e7          	jalr	-768(ra) # 80000bc2 <acquire>
  while (jt->state != ZOMBIE_T && jt->state != UNUSED_T && jt->tid == thread_id) {
    80002eca:	4c9c                	lw	a5,24(s1)
    80002ecc:	4715                	li	a4,5
    sleep(jt, &join_lock);
    80002ece:	0000fb17          	auipc	s6,0xf
    80002ed2:	41ab0b13          	addi	s6,s6,1050 # 800122e8 <join_lock>
  while (jt->state != ZOMBIE_T && jt->state != UNUSED_T && jt->tid == thread_id) {
    80002ed6:	4915                	li	s2,5
    80002ed8:	00e78f63          	beq	a5,a4,80002ef6 <kthread_join+0xa4>
    80002edc:	cf89                	beqz	a5,80002ef6 <kthread_join+0xa4>
    80002ede:	589c                	lw	a5,48(s1)
    80002ee0:	01379b63          	bne	a5,s3,80002ef6 <kthread_join+0xa4>
    sleep(jt, &join_lock);
    80002ee4:	85da                	mv	a1,s6
    80002ee6:	8526                	mv	a0,s1
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	7f0080e7          	jalr	2032(ra) # 800026d8 <sleep>
  while (jt->state != ZOMBIE_T && jt->state != UNUSED_T && jt->tid == thread_id) {
    80002ef0:	4c9c                	lw	a5,24(s1)
    80002ef2:	ff2795e3          	bne	a5,s2,80002edc <kthread_join+0x8a>
  }

  release(&join_lock);
    80002ef6:	0000f517          	auipc	a0,0xf
    80002efa:	3f250513          	addi	a0,a0,1010 # 800122e8 <join_lock>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	d8a080e7          	jalr	-630(ra) # 80000c88 <release>
  acquire(&jt->lock);
    80002f06:	8526                	mv	a0,s1
    80002f08:	ffffe097          	auipc	ra,0xffffe
    80002f0c:	cba080e7          	jalr	-838(ra) # 80000bc2 <acquire>
  if (jt->state == ZOMBIE_T && jt->tid == thread_id) {
    80002f10:	4c98                	lw	a4,24(s1)
    80002f12:	4795                	li	a5,5
    80002f14:	00f71563          	bne	a4,a5,80002f1e <kthread_join+0xcc>
    80002f18:	589c                	lw	a5,48(s1)
    80002f1a:	03378463          	beq	a5,s3,80002f42 <kthread_join+0xf0>
      return -1;
    }
    freethread(jt);
  } 

  release(&jt->lock);
    80002f1e:	8526                	mv	a0,s1
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	d68080e7          	jalr	-664(ra) # 80000c88 <release>
  return 0;
    80002f28:	4501                	li	a0,0
    80002f2a:	a011                	j	80002f2e <kthread_join+0xdc>
  return -1;
    80002f2c:	557d                	li	a0,-1
}
    80002f2e:	70e2                	ld	ra,56(sp)
    80002f30:	7442                	ld	s0,48(sp)
    80002f32:	74a2                	ld	s1,40(sp)
    80002f34:	7902                	ld	s2,32(sp)
    80002f36:	69e2                	ld	s3,24(sp)
    80002f38:	6a42                	ld	s4,16(sp)
    80002f3a:	6aa2                	ld	s5,8(sp)
    80002f3c:	6b02                	ld	s6,0(sp)
    80002f3e:	6121                	addi	sp,sp,64
    80002f40:	8082                	ret
    if (status != 0 && copyout(p->pagetable, (uint64)status, (char *)&jt->xstate, sizeof(jt->xstate)) < 0) {
    80002f42:	000a8e63          	beqz	s5,80002f5e <kthread_join+0x10c>
    80002f46:	4691                	li	a3,4
    80002f48:	02c48613          	addi	a2,s1,44
    80002f4c:	85d6                	mv	a1,s5
    80002f4e:	1d8a3503          	ld	a0,472(s4)
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	710080e7          	jalr	1808(ra) # 80001662 <copyout>
    80002f5a:	00054863          	bltz	a0,80002f6a <kthread_join+0x118>
    freethread(jt);
    80002f5e:	8526                	mv	a0,s1
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	8d0080e7          	jalr	-1840(ra) # 80001830 <freethread>
    80002f68:	bf5d                	j	80002f1e <kthread_join+0xcc>
      release(&jt->lock);
    80002f6a:	8526                	mv	a0,s1
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	d1c080e7          	jalr	-740(ra) # 80000c88 <release>
      return -1;
    80002f74:	557d                	li	a0,-1
    80002f76:	bf65                	j	80002f2e <kthread_join+0xdc>

0000000080002f78 <exit>:
{
    80002f78:	715d                	addi	sp,sp,-80
    80002f7a:	e486                	sd	ra,72(sp)
    80002f7c:	e0a2                	sd	s0,64(sp)
    80002f7e:	fc26                	sd	s1,56(sp)
    80002f80:	f84a                	sd	s2,48(sp)
    80002f82:	f44e                	sd	s3,40(sp)
    80002f84:	f052                	sd	s4,32(sp)
    80002f86:	ec56                	sd	s5,24(sp)
    80002f88:	e85a                	sd	s6,16(sp)
    80002f8a:	e45e                	sd	s7,8(sp)
    80002f8c:	e062                	sd	s8,0(sp)
    80002f8e:	0880                	addi	s0,sp,80
    80002f90:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	aa0080e7          	jalr	-1376(ra) # 80001a32 <myproc>
    80002f9a:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f9c:	00007797          	auipc	a5,0x7
    80002fa0:	08c7b783          	ld	a5,140(a5) # 8000a028 <initproc>
    80002fa4:	1e050493          	addi	s1,a0,480
    80002fa8:	26050913          	addi	s2,a0,608
    80002fac:	02a79363          	bne	a5,a0,80002fd2 <exit+0x5a>
    panic("init exiting");
    80002fb0:	00006517          	auipc	a0,0x6
    80002fb4:	32050513          	addi	a0,a0,800 # 800092d0 <digits+0x290>
    80002fb8:	ffffd097          	auipc	ra,0xffffd
    80002fbc:	572080e7          	jalr	1394(ra) # 8000052a <panic>
      fileclose(f);
    80002fc0:	00002097          	auipc	ra,0x2
    80002fc4:	3a2080e7          	jalr	930(ra) # 80005362 <fileclose>
      p->ofile[fd] = 0;
    80002fc8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002fcc:	04a1                	addi	s1,s1,8
    80002fce:	01248563          	beq	s1,s2,80002fd8 <exit+0x60>
    if(p->ofile[fd]){
    80002fd2:	6088                	ld	a0,0(s1)
    80002fd4:	f575                	bnez	a0,80002fc0 <exit+0x48>
    80002fd6:	bfdd                	j	80002fcc <exit+0x54>
  begin_op();
    80002fd8:	00002097          	auipc	ra,0x2
    80002fdc:	ebe080e7          	jalr	-322(ra) # 80004e96 <begin_op>
  iput(p->cwd);
    80002fe0:	2609b503          	ld	a0,608(s3)
    80002fe4:	00001097          	auipc	ra,0x1
    80002fe8:	696080e7          	jalr	1686(ra) # 8000467a <iput>
  end_op();
    80002fec:	00002097          	auipc	ra,0x2
    80002ff0:	f2a080e7          	jalr	-214(ra) # 80004f16 <end_op>
  p->cwd = 0;
    80002ff4:	2609b023          	sd	zero,608(s3)
  acquire(&wait_lock);
    80002ff8:	0000f517          	auipc	a0,0xf
    80002ffc:	2d850513          	addi	a0,a0,728 # 800122d0 <wait_lock>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	bc2080e7          	jalr	-1086(ra) # 80000bc2 <acquire>
  reparent(p);
    80003008:	854e                	mv	a0,s3
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	8e8080e7          	jalr	-1816(ra) # 800028f2 <reparent>
  wakeup(p->parent);
    80003012:	1c89b503          	ld	a0,456(s3)
    80003016:	00000097          	auipc	ra,0x0
    8000301a:	84c080e7          	jalr	-1972(ra) # 80002862 <wakeup>
  acquire(&p->lock);
    8000301e:	854e                	mv	a0,s3
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	ba2080e7          	jalr	-1118(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80003028:	0359a023          	sw	s5,32(s3)
  p->state = ZOMBIE;
    8000302c:	4789                	li	a5,2
    8000302e:	00f9ac23          	sw	a5,24(s3)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80003032:	27898493          	addi	s1,s3,632
    80003036:	6a05                	lui	s4,0x1
    80003038:	878a0a13          	addi	s4,s4,-1928 # 878 <_entry-0x7ffff788>
    8000303c:	9a4e                	add	s4,s4,s3
      t->terminated = 1;
    8000303e:	4b85                	li	s7,1
      if (t->state == SLEEPING) {
    80003040:	4b09                	li	s6,2
          t->state = RUNNABLE;
    80003042:	4c0d                	li	s8,3
    80003044:	a005                	j	80003064 <exit+0xec>
      release(&t->lock);
    80003046:	8526                	mv	a0,s1
    80003048:	ffffe097          	auipc	ra,0xffffe
    8000304c:	c40080e7          	jalr	-960(ra) # 80000c88 <release>
      kthread_join(t->tid, 0);
    80003050:	4581                	li	a1,0
    80003052:	5888                	lw	a0,48(s1)
    80003054:	00000097          	auipc	ra,0x0
    80003058:	dfe080e7          	jalr	-514(ra) # 80002e52 <kthread_join>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000305c:	0c048493          	addi	s1,s1,192
    80003060:	029a0863          	beq	s4,s1,80003090 <exit+0x118>
    if (t->tid != mythread()->tid) {
    80003064:	0304a903          	lw	s2,48(s1)
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	a04080e7          	jalr	-1532(ra) # 80001a6c <mythread>
    80003070:	591c                	lw	a5,48(a0)
    80003072:	ff2785e3          	beq	a5,s2,8000305c <exit+0xe4>
      acquire(&t->lock);
    80003076:	8526                	mv	a0,s1
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	b4a080e7          	jalr	-1206(ra) # 80000bc2 <acquire>
      t->terminated = 1;
    80003080:	0374a423          	sw	s7,40(s1)
      if (t->state == SLEEPING) {
    80003084:	4c9c                	lw	a5,24(s1)
    80003086:	fd6790e3          	bne	a5,s6,80003046 <exit+0xce>
          t->state = RUNNABLE;
    8000308a:	0184ac23          	sw	s8,24(s1)
    8000308e:	bf65                	j	80003046 <exit+0xce>
  release(&p->lock);
    80003090:	854e                	mv	a0,s3
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	bf6080e7          	jalr	-1034(ra) # 80000c88 <release>
  struct thread *t = mythread();
    8000309a:	fffff097          	auipc	ra,0xfffff
    8000309e:	9d2080e7          	jalr	-1582(ra) # 80001a6c <mythread>
    800030a2:	84aa                	mv	s1,a0
  acquire(&t->lock);
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	b1e080e7          	jalr	-1250(ra) # 80000bc2 <acquire>
  t->xstate = status;
    800030ac:	0354a623          	sw	s5,44(s1)
  t->state = ZOMBIE_T;
    800030b0:	4795                	li	a5,5
    800030b2:	cc9c                	sw	a5,24(s1)
  release(&wait_lock);
    800030b4:	0000f517          	auipc	a0,0xf
    800030b8:	21c50513          	addi	a0,a0,540 # 800122d0 <wait_lock>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	bcc080e7          	jalr	-1076(ra) # 80000c88 <release>
  sched();
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	33a080e7          	jalr	826(ra) # 800023fe <sched>
  panic("zombie exit");
    800030cc:	00006517          	auipc	a0,0x6
    800030d0:	1f450513          	addi	a0,a0,500 # 800092c0 <digits+0x280>
    800030d4:	ffffd097          	auipc	ra,0xffffd
    800030d8:	456080e7          	jalr	1110(ra) # 8000052a <panic>

00000000800030dc <kthread_exit>:
{
    800030dc:	7139                	addi	sp,sp,-64
    800030de:	fc06                	sd	ra,56(sp)
    800030e0:	f822                	sd	s0,48(sp)
    800030e2:	f426                	sd	s1,40(sp)
    800030e4:	f04a                	sd	s2,32(sp)
    800030e6:	ec4e                	sd	s3,24(sp)
    800030e8:	e852                	sd	s4,16(sp)
    800030ea:	e456                	sd	s5,8(sp)
    800030ec:	0080                	addi	s0,sp,64
    800030ee:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    800030f0:	fffff097          	auipc	ra,0xfffff
    800030f4:	942080e7          	jalr	-1726(ra) # 80001a32 <myproc>
    800030f8:	8a2a                	mv	s4,a0
  acquire(&p->lock);
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	ac8080e7          	jalr	-1336(ra) # 80000bc2 <acquire>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80003102:	278a0493          	addi	s1,s4,632
    80003106:	6905                	lui	s2,0x1
    80003108:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    8000310c:	9952                	add	s2,s2,s4
  int used_threads = 0;
    8000310e:	4981                	li	s3,0
    80003110:	a811                	j	80003124 <kthread_exit+0x48>
    release(&t->lock);
    80003112:	8526                	mv	a0,s1
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	b74080e7          	jalr	-1164(ra) # 80000c88 <release>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000311c:	0c048493          	addi	s1,s1,192
    80003120:	00990b63          	beq	s2,s1,80003136 <kthread_exit+0x5a>
    acquire(&t->lock);
    80003124:	8526                	mv	a0,s1
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	a9c080e7          	jalr	-1380(ra) # 80000bc2 <acquire>
    if (t->state != UNUSED_T) {
    8000312e:	4c9c                	lw	a5,24(s1)
    80003130:	d3ed                	beqz	a5,80003112 <kthread_exit+0x36>
      used_threads++;
    80003132:	2985                	addiw	s3,s3,1
    80003134:	bff9                	j	80003112 <kthread_exit+0x36>
  release(&p->lock);
    80003136:	8552                	mv	a0,s4
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	b50080e7          	jalr	-1200(ra) # 80000c88 <release>
  if (used_threads <= 1) {
    80003140:	4785                	li	a5,1
    80003142:	0137d763          	bge	a5,s3,80003150 <kthread_exit+0x74>
  exit_single_thread(status);
    80003146:	8556                	mv	a0,s5
    80003148:	00000097          	auipc	ra,0x0
    8000314c:	ca0080e7          	jalr	-864(ra) # 80002de8 <exit_single_thread>
    exit(status);
    80003150:	8556                	mv	a0,s5
    80003152:	00000097          	auipc	ra,0x0
    80003156:	e26080e7          	jalr	-474(ra) # 80002f78 <exit>

000000008000315a <wakeupSingleThread>:


// ADDED Q4.1
void
wakeupSingleThread(void *chan)
{
    8000315a:	1141                	addi	sp,sp,-16
    8000315c:	e422                	sd	s0,8(sp)
    8000315e:	0800                	addi	s0,sp,16
  //       }
  //       release(&t->lock);
  //     }
  //   }
  // }
}
    80003160:	6422                	ld	s0,8(sp)
    80003162:	0141                	addi	sp,sp,16
    80003164:	8082                	ret

0000000080003166 <bsem_alloc>:

int
bsem_alloc(void)
{
    80003166:	1141                	addi	sp,sp,-16
    80003168:	e422                	sd	s0,8(sp)
    8000316a:	0800                	addi	s0,sp,16
  //     release(&bs->mutex);
  //     return descriptor;
  //   }
  // }
  return -1;
}
    8000316c:	557d                	li	a0,-1
    8000316e:	6422                	ld	s0,8(sp)
    80003170:	0141                	addi	sp,sp,16
    80003172:	8082                	ret

0000000080003174 <bsem_free>:

void
bsem_free(int descriptor)
{
    80003174:	1141                	addi	sp,sp,-16
    80003176:	e422                	sd	s0,8(sp)
    80003178:	0800                	addi	s0,sp,16
  //   return;
  // }
  // // TODO: acquire(&bs->lock);
  // bsems[descriptor].active = 0;
  // // TODO: release(&bs->lock);
}
    8000317a:	6422                	ld	s0,8(sp)
    8000317c:	0141                	addi	sp,sp,16
    8000317e:	8082                	ret

0000000080003180 <bsem_down>:
//    the process is blocked. It will resume execution only after it is woken-up
// Else
//    S--
void
bsem_down(int descriptor)
{
    80003180:	1141                	addi	sp,sp,-16
    80003182:	e422                	sd	s0,8(sp)
    80003184:	0800                	addi	s0,sp,16
  // else{
  //   bs->permits--;
  // }

  // release(&bs->mutex);
}
    80003186:	6422                	ld	s0,8(sp)
    80003188:	0141                	addi	sp,sp,16
    8000318a:	8082                	ret

000000008000318c <bsem_up>:
//    wake-up one of them
// Else 
//    S++
void
bsem_up(int descriptor)
{
    8000318c:	1141                	addi	sp,sp,-16
    8000318e:	e422                	sd	s0,8(sp)
    80003190:	0800                	addi	s0,sp,16
  // else{
  //   bs->permits++;
  // }

  // release(&bs->mutex);
}
    80003192:	6422                	ld	s0,8(sp)
    80003194:	0141                	addi	sp,sp,16
    80003196:	8082                	ret

0000000080003198 <swtch>:
    80003198:	00153023          	sd	ra,0(a0)
    8000319c:	00253423          	sd	sp,8(a0)
    800031a0:	e900                	sd	s0,16(a0)
    800031a2:	ed04                	sd	s1,24(a0)
    800031a4:	03253023          	sd	s2,32(a0)
    800031a8:	03353423          	sd	s3,40(a0)
    800031ac:	03453823          	sd	s4,48(a0)
    800031b0:	03553c23          	sd	s5,56(a0)
    800031b4:	05653023          	sd	s6,64(a0)
    800031b8:	05753423          	sd	s7,72(a0)
    800031bc:	05853823          	sd	s8,80(a0)
    800031c0:	05953c23          	sd	s9,88(a0)
    800031c4:	07a53023          	sd	s10,96(a0)
    800031c8:	07b53423          	sd	s11,104(a0)
    800031cc:	0005b083          	ld	ra,0(a1)
    800031d0:	0085b103          	ld	sp,8(a1)
    800031d4:	6980                	ld	s0,16(a1)
    800031d6:	6d84                	ld	s1,24(a1)
    800031d8:	0205b903          	ld	s2,32(a1)
    800031dc:	0285b983          	ld	s3,40(a1)
    800031e0:	0305ba03          	ld	s4,48(a1)
    800031e4:	0385ba83          	ld	s5,56(a1)
    800031e8:	0405bb03          	ld	s6,64(a1)
    800031ec:	0485bb83          	ld	s7,72(a1)
    800031f0:	0505bc03          	ld	s8,80(a1)
    800031f4:	0585bc83          	ld	s9,88(a1)
    800031f8:	0605bd03          	ld	s10,96(a1)
    800031fc:	0685bd83          	ld	s11,104(a1)
    80003200:	8082                	ret

0000000080003202 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003202:	1141                	addi	sp,sp,-16
    80003204:	e406                	sd	ra,8(sp)
    80003206:	e022                	sd	s0,0(sp)
    80003208:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000320a:	00006597          	auipc	a1,0x6
    8000320e:	0fe58593          	addi	a1,a1,254 # 80009308 <states.0+0x18>
    80003212:	00031517          	auipc	a0,0x31
    80003216:	4ee50513          	addi	a0,a0,1262 # 80034700 <tickslock>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	918080e7          	jalr	-1768(ra) # 80000b32 <initlock>
}
    80003222:	60a2                	ld	ra,8(sp)
    80003224:	6402                	ld	s0,0(sp)
    80003226:	0141                	addi	sp,sp,16
    80003228:	8082                	ret

000000008000322a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000322a:	1141                	addi	sp,sp,-16
    8000322c:	e422                	sd	s0,8(sp)
    8000322e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003230:	00004797          	auipc	a5,0x4
    80003234:	80078793          	addi	a5,a5,-2048 # 80006a30 <kernelvec>
    80003238:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000323c:	6422                	ld	s0,8(sp)
    8000323e:	0141                	addi	sp,sp,16
    80003240:	8082                	ret

0000000080003242 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003242:	1101                	addi	sp,sp,-32
    80003244:	ec06                	sd	ra,24(sp)
    80003246:	e822                	sd	s0,16(sp)
    80003248:	e426                	sd	s1,8(sp)
    8000324a:	e04a                	sd	s2,0(sp)
    8000324c:	1000                	addi	s0,sp,32
  struct thread *t = mythread(); // ADDED Q3
    8000324e:	fffff097          	auipc	ra,0xfffff
    80003252:	81e080e7          	jalr	-2018(ra) # 80001a6c <mythread>
    80003256:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	7da080e7          	jalr	2010(ra) # 80001a32 <myproc>
    80003260:	892a                	mv	s2,a0

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  handle_signals(); // ADDED Q2.4 
    80003262:	fffff097          	auipc	ra,0xfffff
    80003266:	34a080e7          	jalr	842(ra) # 800025ac <handle_signals>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000326a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000326e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003270:	10079073          	csrw	sstatus,a5

  intr_off();
  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003274:	00005617          	auipc	a2,0x5
    80003278:	d8c60613          	addi	a2,a2,-628 # 80008000 <_trampoline>
    8000327c:	00005697          	auipc	a3,0x5
    80003280:	d8468693          	addi	a3,a3,-636 # 80008000 <_trampoline>
    80003284:	8e91                	sub	a3,a3,a2
    80003286:	040007b7          	lui	a5,0x4000
    8000328a:	17fd                	addi	a5,a5,-1
    8000328c:	07b2                	slli	a5,a5,0xc
    8000328e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003290:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  t->trapframe->kernel_satp = r_satp();         // kernel page table
    80003294:	64b8                	ld	a4,72(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003296:	180026f3          	csrr	a3,satp
    8000329a:	e314                	sd	a3,0(a4)
  t->trapframe->kernel_sp = t->kstack + PGSIZE; // thread's kernel stack
    8000329c:	64b8                	ld	a4,72(s1)
    8000329e:	60b4                	ld	a3,64(s1)
    800032a0:	6585                	lui	a1,0x1
    800032a2:	96ae                	add	a3,a3,a1
    800032a4:	e714                	sd	a3,8(a4)
  t->trapframe->kernel_trap = (uint64)usertrap;
    800032a6:	64b8                	ld	a4,72(s1)
    800032a8:	00000697          	auipc	a3,0x0
    800032ac:	14a68693          	addi	a3,a3,330 # 800033f2 <usertrap>
    800032b0:	eb14                	sd	a3,16(a4)
  t->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800032b2:	64b8                	ld	a4,72(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    800032b4:	8692                	mv	a3,tp
    800032b6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032b8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800032bc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800032c0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032c4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(t->trapframe->epc);
    800032c8:	64b8                	ld	a4,72(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032ca:	6f18                	ld	a4,24(a4)
    800032cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800032d0:	1d893583          	ld	a1,472(s2)
    800032d4:	81b1                	srli	a1,a1,0xc
  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    800032d6:	58d8                	lw	a4,52(s1)
    800032d8:	00371513          	slli	a0,a4,0x3
    800032dc:	953a                	add	a0,a0,a4
    800032de:	0516                	slli	a0,a0,0x5
    800032e0:	020006b7          	lui	a3,0x2000
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800032e4:	00005717          	auipc	a4,0x5
    800032e8:	dac70713          	addi	a4,a4,-596 # 80008090 <userret>
    800032ec:	8f11                	sub	a4,a4,a2
    800032ee:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    800032f0:	577d                	li	a4,-1
    800032f2:	177e                	slli	a4,a4,0x3f
    800032f4:	8dd9                	or	a1,a1,a4
    800032f6:	16fd                	addi	a3,a3,-1
    800032f8:	06b6                	slli	a3,a3,0xd
    800032fa:	9536                	add	a0,a0,a3
    800032fc:	9782                	jalr	a5
}
    800032fe:	60e2                	ld	ra,24(sp)
    80003300:	6442                	ld	s0,16(sp)
    80003302:	64a2                	ld	s1,8(sp)
    80003304:	6902                	ld	s2,0(sp)
    80003306:	6105                	addi	sp,sp,32
    80003308:	8082                	ret

000000008000330a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000330a:	1101                	addi	sp,sp,-32
    8000330c:	ec06                	sd	ra,24(sp)
    8000330e:	e822                	sd	s0,16(sp)
    80003310:	e426                	sd	s1,8(sp)
    80003312:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003314:	00031497          	auipc	s1,0x31
    80003318:	3ec48493          	addi	s1,s1,1004 # 80034700 <tickslock>
    8000331c:	8526                	mv	a0,s1
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	8a4080e7          	jalr	-1884(ra) # 80000bc2 <acquire>
  ticks++;
    80003326:	00007517          	auipc	a0,0x7
    8000332a:	d0a50513          	addi	a0,a0,-758 # 8000a030 <ticks>
    8000332e:	411c                	lw	a5,0(a0)
    80003330:	2785                	addiw	a5,a5,1
    80003332:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003334:	fffff097          	auipc	ra,0xfffff
    80003338:	52e080e7          	jalr	1326(ra) # 80002862 <wakeup>
  release(&tickslock);
    8000333c:	8526                	mv	a0,s1
    8000333e:	ffffe097          	auipc	ra,0xffffe
    80003342:	94a080e7          	jalr	-1718(ra) # 80000c88 <release>
}
    80003346:	60e2                	ld	ra,24(sp)
    80003348:	6442                	ld	s0,16(sp)
    8000334a:	64a2                	ld	s1,8(sp)
    8000334c:	6105                	addi	sp,sp,32
    8000334e:	8082                	ret

0000000080003350 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003350:	1101                	addi	sp,sp,-32
    80003352:	ec06                	sd	ra,24(sp)
    80003354:	e822                	sd	s0,16(sp)
    80003356:	e426                	sd	s1,8(sp)
    80003358:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000335a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000335e:	00074d63          	bltz	a4,80003378 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003362:	57fd                	li	a5,-1
    80003364:	17fe                	slli	a5,a5,0x3f
    80003366:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003368:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000336a:	06f70363          	beq	a4,a5,800033d0 <devintr+0x80>
  }
}
    8000336e:	60e2                	ld	ra,24(sp)
    80003370:	6442                	ld	s0,16(sp)
    80003372:	64a2                	ld	s1,8(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret
     (scause & 0xff) == 9){
    80003378:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000337c:	46a5                	li	a3,9
    8000337e:	fed792e3          	bne	a5,a3,80003362 <devintr+0x12>
    int irq = plic_claim();
    80003382:	00003097          	auipc	ra,0x3
    80003386:	7b6080e7          	jalr	1974(ra) # 80006b38 <plic_claim>
    8000338a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000338c:	47a9                	li	a5,10
    8000338e:	02f50763          	beq	a0,a5,800033bc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003392:	4785                	li	a5,1
    80003394:	02f50963          	beq	a0,a5,800033c6 <devintr+0x76>
    return 1;
    80003398:	4505                	li	a0,1
    } else if(irq){
    8000339a:	d8f1                	beqz	s1,8000336e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000339c:	85a6                	mv	a1,s1
    8000339e:	00006517          	auipc	a0,0x6
    800033a2:	f7250513          	addi	a0,a0,-142 # 80009310 <states.0+0x20>
    800033a6:	ffffd097          	auipc	ra,0xffffd
    800033aa:	1ce080e7          	jalr	462(ra) # 80000574 <printf>
      plic_complete(irq);
    800033ae:	8526                	mv	a0,s1
    800033b0:	00003097          	auipc	ra,0x3
    800033b4:	7ac080e7          	jalr	1964(ra) # 80006b5c <plic_complete>
    return 1;
    800033b8:	4505                	li	a0,1
    800033ba:	bf55                	j	8000336e <devintr+0x1e>
      uartintr();
    800033bc:	ffffd097          	auipc	ra,0xffffd
    800033c0:	5ca080e7          	jalr	1482(ra) # 80000986 <uartintr>
    800033c4:	b7ed                	j	800033ae <devintr+0x5e>
      virtio_disk_intr();
    800033c6:	00004097          	auipc	ra,0x4
    800033ca:	c28080e7          	jalr	-984(ra) # 80006fee <virtio_disk_intr>
    800033ce:	b7c5                	j	800033ae <devintr+0x5e>
    if(cpuid() == 0){
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	636080e7          	jalr	1590(ra) # 80001a06 <cpuid>
    800033d8:	c901                	beqz	a0,800033e8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800033da:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800033de:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800033e0:	14479073          	csrw	sip,a5
    return 2;
    800033e4:	4509                	li	a0,2
    800033e6:	b761                	j	8000336e <devintr+0x1e>
      clockintr();
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	f22080e7          	jalr	-222(ra) # 8000330a <clockintr>
    800033f0:	b7ed                	j	800033da <devintr+0x8a>

00000000800033f2 <usertrap>:
{
    800033f2:	7179                	addi	sp,sp,-48
    800033f4:	f406                	sd	ra,40(sp)
    800033f6:	f022                	sd	s0,32(sp)
    800033f8:	ec26                	sd	s1,24(sp)
    800033fa:	e84a                	sd	s2,16(sp)
    800033fc:	e44e                	sd	s3,8(sp)
    800033fe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003400:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003404:	1007f793          	andi	a5,a5,256
    80003408:	e3c9                	bnez	a5,8000348a <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000340a:	00003797          	auipc	a5,0x3
    8000340e:	62678793          	addi	a5,a5,1574 # 80006a30 <kernelvec>
    80003412:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003416:	ffffe097          	auipc	ra,0xffffe
    8000341a:	61c080e7          	jalr	1564(ra) # 80001a32 <myproc>
    8000341e:	892a                	mv	s2,a0
  struct thread *t = mythread(); // ADDED Q3
    80003420:	ffffe097          	auipc	ra,0xffffe
    80003424:	64c080e7          	jalr	1612(ra) # 80001a6c <mythread>
    80003428:	84aa                	mv	s1,a0
  t->trapframe->epc = r_sepc();
    8000342a:	653c                	ld	a5,72(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000342c:	14102773          	csrr	a4,sepc
    80003430:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003432:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003436:	47a1                	li	a5,8
    80003438:	06f71d63          	bne	a4,a5,800034b2 <usertrap+0xc0>
    if(p->killed)
    8000343c:	01c92783          	lw	a5,28(s2)
    80003440:	efa9                	bnez	a5,8000349a <usertrap+0xa8>
    if (t->terminated) {
    80003442:	549c                	lw	a5,40(s1)
    80003444:	e3ad                	bnez	a5,800034a6 <usertrap+0xb4>
    t->trapframe->epc += 4;
    80003446:	64b8                	ld	a4,72(s1)
    80003448:	6f1c                	ld	a5,24(a4)
    8000344a:	0791                	addi	a5,a5,4
    8000344c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000344e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003452:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003456:	10079073          	csrw	sstatus,a5
    syscall();
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	302080e7          	jalr	770(ra) # 8000375c <syscall>
  int which_dev = 0;
    80003462:	4981                	li	s3,0
  if(p->killed)
    80003464:	01c92783          	lw	a5,28(s2)
    80003468:	e7d1                	bnez	a5,800034f4 <usertrap+0x102>
  if (t->terminated) {
    8000346a:	549c                	lw	a5,40(s1)
    8000346c:	ebd1                	bnez	a5,80003500 <usertrap+0x10e>
  if(which_dev == 2)
    8000346e:	4789                	li	a5,2
    80003470:	08f98e63          	beq	s3,a5,8000350c <usertrap+0x11a>
  usertrapret();
    80003474:	00000097          	auipc	ra,0x0
    80003478:	dce080e7          	jalr	-562(ra) # 80003242 <usertrapret>
}
    8000347c:	70a2                	ld	ra,40(sp)
    8000347e:	7402                	ld	s0,32(sp)
    80003480:	64e2                	ld	s1,24(sp)
    80003482:	6942                	ld	s2,16(sp)
    80003484:	69a2                	ld	s3,8(sp)
    80003486:	6145                	addi	sp,sp,48
    80003488:	8082                	ret
    panic("usertrap: not from user mode");
    8000348a:	00006517          	auipc	a0,0x6
    8000348e:	ea650513          	addi	a0,a0,-346 # 80009330 <states.0+0x40>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	098080e7          	jalr	152(ra) # 8000052a <panic>
      exit(-1);
    8000349a:	557d                	li	a0,-1
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	adc080e7          	jalr	-1316(ra) # 80002f78 <exit>
    800034a4:	bf79                	j	80003442 <usertrap+0x50>
      kthread_exit(-1);
    800034a6:	557d                	li	a0,-1
    800034a8:	00000097          	auipc	ra,0x0
    800034ac:	c34080e7          	jalr	-972(ra) # 800030dc <kthread_exit>
    800034b0:	bf59                	j	80003446 <usertrap+0x54>
  } else if((which_dev = devintr()) != 0){
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	e9e080e7          	jalr	-354(ra) # 80003350 <devintr>
    800034ba:	89aa                	mv	s3,a0
    800034bc:	f545                	bnez	a0,80003464 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034be:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800034c2:	02492603          	lw	a2,36(s2)
    800034c6:	00006517          	auipc	a0,0x6
    800034ca:	e8a50513          	addi	a0,a0,-374 # 80009350 <states.0+0x60>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	0a6080e7          	jalr	166(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034d6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800034da:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800034de:	00006517          	auipc	a0,0x6
    800034e2:	ea250513          	addi	a0,a0,-350 # 80009380 <states.0+0x90>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	08e080e7          	jalr	142(ra) # 80000574 <printf>
    p->killed = 1;
    800034ee:	4785                	li	a5,1
    800034f0:	00f92e23          	sw	a5,28(s2)
    exit(-1);
    800034f4:	557d                	li	a0,-1
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	a82080e7          	jalr	-1406(ra) # 80002f78 <exit>
    800034fe:	b7b5                	j	8000346a <usertrap+0x78>
    kthread_exit(-1);
    80003500:	557d                	li	a0,-1
    80003502:	00000097          	auipc	ra,0x0
    80003506:	bda080e7          	jalr	-1062(ra) # 800030dc <kthread_exit>
    8000350a:	b795                	j	8000346e <usertrap+0x7c>
    yield();
    8000350c:	fffff097          	auipc	ra,0xfffff
    80003510:	010080e7          	jalr	16(ra) # 8000251c <yield>
    80003514:	b785                	j	80003474 <usertrap+0x82>

0000000080003516 <kerneltrap>:
{
    80003516:	7179                	addi	sp,sp,-48
    80003518:	f406                	sd	ra,40(sp)
    8000351a:	f022                	sd	s0,32(sp)
    8000351c:	ec26                	sd	s1,24(sp)
    8000351e:	e84a                	sd	s2,16(sp)
    80003520:	e44e                	sd	s3,8(sp)
    80003522:	e052                	sd	s4,0(sp)
    80003524:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003526:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000352a:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000352e:	14202a73          	csrr	s4,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003532:	10097793          	andi	a5,s2,256
    80003536:	cf95                	beqz	a5,80003572 <kerneltrap+0x5c>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003538:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000353c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000353e:	e3b1                	bnez	a5,80003582 <kerneltrap+0x6c>
  if((which_dev = devintr()) == 0){
    80003540:	00000097          	auipc	ra,0x0
    80003544:	e10080e7          	jalr	-496(ra) # 80003350 <devintr>
    80003548:	84aa                	mv	s1,a0
    8000354a:	c521                	beqz	a0,80003592 <kerneltrap+0x7c>
  struct thread *t = mythread();
    8000354c:	ffffe097          	auipc	ra,0xffffe
    80003550:	520080e7          	jalr	1312(ra) # 80001a6c <mythread>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    80003554:	4789                	li	a5,2
    80003556:	06f48b63          	beq	s1,a5,800035cc <kerneltrap+0xb6>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000355a:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000355e:	10091073          	csrw	sstatus,s2
}
    80003562:	70a2                	ld	ra,40(sp)
    80003564:	7402                	ld	s0,32(sp)
    80003566:	64e2                	ld	s1,24(sp)
    80003568:	6942                	ld	s2,16(sp)
    8000356a:	69a2                	ld	s3,8(sp)
    8000356c:	6a02                	ld	s4,0(sp)
    8000356e:	6145                	addi	sp,sp,48
    80003570:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003572:	00006517          	auipc	a0,0x6
    80003576:	e2e50513          	addi	a0,a0,-466 # 800093a0 <states.0+0xb0>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	fb0080e7          	jalr	-80(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80003582:	00006517          	auipc	a0,0x6
    80003586:	e4650513          	addi	a0,a0,-442 # 800093c8 <states.0+0xd8>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	fa0080e7          	jalr	-96(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80003592:	85d2                	mv	a1,s4
    80003594:	00006517          	auipc	a0,0x6
    80003598:	e5450513          	addi	a0,a0,-428 # 800093e8 <states.0+0xf8>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	fd8080e7          	jalr	-40(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035a4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800035a8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800035ac:	00006517          	auipc	a0,0x6
    800035b0:	e4c50513          	addi	a0,a0,-436 # 800093f8 <states.0+0x108>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	fc0080e7          	jalr	-64(ra) # 80000574 <printf>
    panic("kerneltrap");
    800035bc:	00006517          	auipc	a0,0x6
    800035c0:	e5450513          	addi	a0,a0,-428 # 80009410 <states.0+0x120>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	f66080e7          	jalr	-154(ra) # 8000052a <panic>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    800035cc:	d559                	beqz	a0,8000355a <kerneltrap+0x44>
    800035ce:	4d18                	lw	a4,24(a0)
    800035d0:	4791                	li	a5,4
    800035d2:	f8f714e3          	bne	a4,a5,8000355a <kerneltrap+0x44>
    yield();
    800035d6:	fffff097          	auipc	ra,0xfffff
    800035da:	f46080e7          	jalr	-186(ra) # 8000251c <yield>
    800035de:	bfb5                	j	8000355a <kerneltrap+0x44>

00000000800035e0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	1000                	addi	s0,sp,32
    800035ea:	84aa                	mv	s1,a0
  struct thread *t = mythread();
    800035ec:	ffffe097          	auipc	ra,0xffffe
    800035f0:	480080e7          	jalr	1152(ra) # 80001a6c <mythread>
  switch (n) {
    800035f4:	4795                	li	a5,5
    800035f6:	0497e163          	bltu	a5,s1,80003638 <argraw+0x58>
    800035fa:	048a                	slli	s1,s1,0x2
    800035fc:	00006717          	auipc	a4,0x6
    80003600:	e4c70713          	addi	a4,a4,-436 # 80009448 <states.0+0x158>
    80003604:	94ba                	add	s1,s1,a4
    80003606:	409c                	lw	a5,0(s1)
    80003608:	97ba                	add	a5,a5,a4
    8000360a:	8782                	jr	a5
  case 0:
    return t->trapframe->a0;
    8000360c:	653c                	ld	a5,72(a0)
    8000360e:	7ba8                	ld	a0,112(a5)
  case 5:
    return t->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003610:	60e2                	ld	ra,24(sp)
    80003612:	6442                	ld	s0,16(sp)
    80003614:	64a2                	ld	s1,8(sp)
    80003616:	6105                	addi	sp,sp,32
    80003618:	8082                	ret
    return t->trapframe->a1;
    8000361a:	653c                	ld	a5,72(a0)
    8000361c:	7fa8                	ld	a0,120(a5)
    8000361e:	bfcd                	j	80003610 <argraw+0x30>
    return t->trapframe->a2;
    80003620:	653c                	ld	a5,72(a0)
    80003622:	63c8                	ld	a0,128(a5)
    80003624:	b7f5                	j	80003610 <argraw+0x30>
    return t->trapframe->a3;
    80003626:	653c                	ld	a5,72(a0)
    80003628:	67c8                	ld	a0,136(a5)
    8000362a:	b7dd                	j	80003610 <argraw+0x30>
    return t->trapframe->a4;
    8000362c:	653c                	ld	a5,72(a0)
    8000362e:	6bc8                	ld	a0,144(a5)
    80003630:	b7c5                	j	80003610 <argraw+0x30>
    return t->trapframe->a5;
    80003632:	653c                	ld	a5,72(a0)
    80003634:	6fc8                	ld	a0,152(a5)
    80003636:	bfe9                	j	80003610 <argraw+0x30>
  panic("argraw");
    80003638:	00006517          	auipc	a0,0x6
    8000363c:	de850513          	addi	a0,a0,-536 # 80009420 <states.0+0x130>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	eea080e7          	jalr	-278(ra) # 8000052a <panic>

0000000080003648 <fetchaddr>:
{
    80003648:	1101                	addi	sp,sp,-32
    8000364a:	ec06                	sd	ra,24(sp)
    8000364c:	e822                	sd	s0,16(sp)
    8000364e:	e426                	sd	s1,8(sp)
    80003650:	e04a                	sd	s2,0(sp)
    80003652:	1000                	addi	s0,sp,32
    80003654:	84aa                	mv	s1,a0
    80003656:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003658:	ffffe097          	auipc	ra,0xffffe
    8000365c:	3da080e7          	jalr	986(ra) # 80001a32 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003660:	1d053783          	ld	a5,464(a0)
    80003664:	02f4f963          	bgeu	s1,a5,80003696 <fetchaddr+0x4e>
    80003668:	00848713          	addi	a4,s1,8
    8000366c:	02e7e763          	bltu	a5,a4,8000369a <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003670:	46a1                	li	a3,8
    80003672:	8626                	mv	a2,s1
    80003674:	85ca                	mv	a1,s2
    80003676:	1d853503          	ld	a0,472(a0)
    8000367a:	ffffe097          	auipc	ra,0xffffe
    8000367e:	074080e7          	jalr	116(ra) # 800016ee <copyin>
    80003682:	00a03533          	snez	a0,a0
    80003686:	40a00533          	neg	a0,a0
}
    8000368a:	60e2                	ld	ra,24(sp)
    8000368c:	6442                	ld	s0,16(sp)
    8000368e:	64a2                	ld	s1,8(sp)
    80003690:	6902                	ld	s2,0(sp)
    80003692:	6105                	addi	sp,sp,32
    80003694:	8082                	ret
    return -1;
    80003696:	557d                	li	a0,-1
    80003698:	bfcd                	j	8000368a <fetchaddr+0x42>
    8000369a:	557d                	li	a0,-1
    8000369c:	b7fd                	j	8000368a <fetchaddr+0x42>

000000008000369e <fetchstr>:
{
    8000369e:	7179                	addi	sp,sp,-48
    800036a0:	f406                	sd	ra,40(sp)
    800036a2:	f022                	sd	s0,32(sp)
    800036a4:	ec26                	sd	s1,24(sp)
    800036a6:	e84a                	sd	s2,16(sp)
    800036a8:	e44e                	sd	s3,8(sp)
    800036aa:	1800                	addi	s0,sp,48
    800036ac:	892a                	mv	s2,a0
    800036ae:	84ae                	mv	s1,a1
    800036b0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800036b2:	ffffe097          	auipc	ra,0xffffe
    800036b6:	380080e7          	jalr	896(ra) # 80001a32 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800036ba:	86ce                	mv	a3,s3
    800036bc:	864a                	mv	a2,s2
    800036be:	85a6                	mv	a1,s1
    800036c0:	1d853503          	ld	a0,472(a0)
    800036c4:	ffffe097          	auipc	ra,0xffffe
    800036c8:	0b8080e7          	jalr	184(ra) # 8000177c <copyinstr>
  if(err < 0)
    800036cc:	00054763          	bltz	a0,800036da <fetchstr+0x3c>
  return strlen(buf);
    800036d0:	8526                	mv	a0,s1
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	794080e7          	jalr	1940(ra) # 80000e66 <strlen>
}
    800036da:	70a2                	ld	ra,40(sp)
    800036dc:	7402                	ld	s0,32(sp)
    800036de:	64e2                	ld	s1,24(sp)
    800036e0:	6942                	ld	s2,16(sp)
    800036e2:	69a2                	ld	s3,8(sp)
    800036e4:	6145                	addi	sp,sp,48
    800036e6:	8082                	ret

00000000800036e8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800036e8:	1101                	addi	sp,sp,-32
    800036ea:	ec06                	sd	ra,24(sp)
    800036ec:	e822                	sd	s0,16(sp)
    800036ee:	e426                	sd	s1,8(sp)
    800036f0:	1000                	addi	s0,sp,32
    800036f2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	eec080e7          	jalr	-276(ra) # 800035e0 <argraw>
    800036fc:	c088                	sw	a0,0(s1)
  return 0;
}
    800036fe:	4501                	li	a0,0
    80003700:	60e2                	ld	ra,24(sp)
    80003702:	6442                	ld	s0,16(sp)
    80003704:	64a2                	ld	s1,8(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret

000000008000370a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	1000                	addi	s0,sp,32
    80003714:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	eca080e7          	jalr	-310(ra) # 800035e0 <argraw>
    8000371e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003720:	4501                	li	a0,0
    80003722:	60e2                	ld	ra,24(sp)
    80003724:	6442                	ld	s0,16(sp)
    80003726:	64a2                	ld	s1,8(sp)
    80003728:	6105                	addi	sp,sp,32
    8000372a:	8082                	ret

000000008000372c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000372c:	1101                	addi	sp,sp,-32
    8000372e:	ec06                	sd	ra,24(sp)
    80003730:	e822                	sd	s0,16(sp)
    80003732:	e426                	sd	s1,8(sp)
    80003734:	e04a                	sd	s2,0(sp)
    80003736:	1000                	addi	s0,sp,32
    80003738:	84ae                	mv	s1,a1
    8000373a:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	ea4080e7          	jalr	-348(ra) # 800035e0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003744:	864a                	mv	a2,s2
    80003746:	85a6                	mv	a1,s1
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	f56080e7          	jalr	-170(ra) # 8000369e <fetchstr>
}
    80003750:	60e2                	ld	ra,24(sp)
    80003752:	6442                	ld	s0,16(sp)
    80003754:	64a2                	ld	s1,8(sp)
    80003756:	6902                	ld	s2,0(sp)
    80003758:	6105                	addi	sp,sp,32
    8000375a:	8082                	ret

000000008000375c <syscall>:

};

void
syscall(void)
{
    8000375c:	1101                	addi	sp,sp,-32
    8000375e:	ec06                	sd	ra,24(sp)
    80003760:	e822                	sd	s0,16(sp)
    80003762:	e426                	sd	s1,8(sp)
    80003764:	e04a                	sd	s2,0(sp)
    80003766:	1000                	addi	s0,sp,32
  int num;
  struct thread *t = mythread();
    80003768:	ffffe097          	auipc	ra,0xffffe
    8000376c:	304080e7          	jalr	772(ra) # 80001a6c <mythread>
    80003770:	84aa                	mv	s1,a0

  num = t->trapframe->a7;
    80003772:	04853903          	ld	s2,72(a0)
    80003776:	0a893783          	ld	a5,168(s2)
    8000377a:	0007861b          	sext.w	a2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000377e:	37fd                	addiw	a5,a5,-1
    80003780:	477d                	li	a4,31
    80003782:	00f76f63          	bltu	a4,a5,800037a0 <syscall+0x44>
    80003786:	00361713          	slli	a4,a2,0x3
    8000378a:	00006797          	auipc	a5,0x6
    8000378e:	cd678793          	addi	a5,a5,-810 # 80009460 <syscalls>
    80003792:	97ba                	add	a5,a5,a4
    80003794:	639c                	ld	a5,0(a5)
    80003796:	c789                	beqz	a5,800037a0 <syscall+0x44>
    t->trapframe->a0 = syscalls[num]();
    80003798:	9782                	jalr	a5
    8000379a:	06a93823          	sd	a0,112(s2)
    8000379e:	a829                	j	800037b8 <syscall+0x5c>
  } else {
    printf("thread %d: unknown sys call %d\n",
    800037a0:	588c                	lw	a1,48(s1)
    800037a2:	00006517          	auipc	a0,0x6
    800037a6:	c8650513          	addi	a0,a0,-890 # 80009428 <states.0+0x138>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	dca080e7          	jalr	-566(ra) # 80000574 <printf>
            t->tid, num);
    t->trapframe->a0 = -1;
    800037b2:	64bc                	ld	a5,72(s1)
    800037b4:	577d                	li	a4,-1
    800037b6:	fbb8                	sd	a4,112(a5)
  }
}
    800037b8:	60e2                	ld	ra,24(sp)
    800037ba:	6442                	ld	s0,16(sp)
    800037bc:	64a2                	ld	s1,8(sp)
    800037be:	6902                	ld	s2,0(sp)
    800037c0:	6105                	addi	sp,sp,32
    800037c2:	8082                	ret

00000000800037c4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800037c4:	1101                	addi	sp,sp,-32
    800037c6:	ec06                	sd	ra,24(sp)
    800037c8:	e822                	sd	s0,16(sp)
    800037ca:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800037cc:	fec40593          	addi	a1,s0,-20
    800037d0:	4501                	li	a0,0
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	f16080e7          	jalr	-234(ra) # 800036e8 <argint>
    return -1;
    800037da:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800037dc:	00054963          	bltz	a0,800037ee <sys_exit+0x2a>
  exit(n);
    800037e0:	fec42503          	lw	a0,-20(s0)
    800037e4:	fffff097          	auipc	ra,0xfffff
    800037e8:	794080e7          	jalr	1940(ra) # 80002f78 <exit>
  return 0;  // not reached
    800037ec:	4781                	li	a5,0
}
    800037ee:	853e                	mv	a0,a5
    800037f0:	60e2                	ld	ra,24(sp)
    800037f2:	6442                	ld	s0,16(sp)
    800037f4:	6105                	addi	sp,sp,32
    800037f6:	8082                	ret

00000000800037f8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800037f8:	1141                	addi	sp,sp,-16
    800037fa:	e406                	sd	ra,8(sp)
    800037fc:	e022                	sd	s0,0(sp)
    800037fe:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003800:	ffffe097          	auipc	ra,0xffffe
    80003804:	232080e7          	jalr	562(ra) # 80001a32 <myproc>
}
    80003808:	5148                	lw	a0,36(a0)
    8000380a:	60a2                	ld	ra,8(sp)
    8000380c:	6402                	ld	s0,0(sp)
    8000380e:	0141                	addi	sp,sp,16
    80003810:	8082                	ret

0000000080003812 <sys_fork>:

uint64
sys_fork(void)
{
    80003812:	1141                	addi	sp,sp,-16
    80003814:	e406                	sd	ra,8(sp)
    80003816:	e022                	sd	s0,0(sp)
    80003818:	0800                	addi	s0,sp,16
  return fork();
    8000381a:	fffff097          	auipc	ra,0xfffff
    8000381e:	828080e7          	jalr	-2008(ra) # 80002042 <fork>
}
    80003822:	60a2                	ld	ra,8(sp)
    80003824:	6402                	ld	s0,0(sp)
    80003826:	0141                	addi	sp,sp,16
    80003828:	8082                	ret

000000008000382a <sys_wait>:

uint64
sys_wait(void)
{
    8000382a:	1101                	addi	sp,sp,-32
    8000382c:	ec06                	sd	ra,24(sp)
    8000382e:	e822                	sd	s0,16(sp)
    80003830:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003832:	fe840593          	addi	a1,s0,-24
    80003836:	4501                	li	a0,0
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	ed2080e7          	jalr	-302(ra) # 8000370a <argaddr>
    80003840:	87aa                	mv	a5,a0
    return -1;
    80003842:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003844:	0007c863          	bltz	a5,80003854 <sys_wait+0x2a>
  return wait(p);
    80003848:	fe843503          	ld	a0,-24(s0)
    8000384c:	fffff097          	auipc	ra,0xfffff
    80003850:	ef0080e7          	jalr	-272(ra) # 8000273c <wait>
}
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	6105                	addi	sp,sp,32
    8000385a:	8082                	ret

000000008000385c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000385c:	7179                	addi	sp,sp,-48
    8000385e:	f406                	sd	ra,40(sp)
    80003860:	f022                	sd	s0,32(sp)
    80003862:	ec26                	sd	s1,24(sp)
    80003864:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003866:	fdc40593          	addi	a1,s0,-36
    8000386a:	4501                	li	a0,0
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	e7c080e7          	jalr	-388(ra) # 800036e8 <argint>
    return -1;
    80003874:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003876:	02054063          	bltz	a0,80003896 <sys_sbrk+0x3a>
  addr = myproc()->sz;
    8000387a:	ffffe097          	auipc	ra,0xffffe
    8000387e:	1b8080e7          	jalr	440(ra) # 80001a32 <myproc>
    80003882:	1d052483          	lw	s1,464(a0)
  if(growproc(n) < 0)
    80003886:	fdc42503          	lw	a0,-36(s0)
    8000388a:	ffffe097          	auipc	ra,0xffffe
    8000388e:	71e080e7          	jalr	1822(ra) # 80001fa8 <growproc>
    80003892:	00054863          	bltz	a0,800038a2 <sys_sbrk+0x46>
    return -1;
  return addr;
}
    80003896:	8526                	mv	a0,s1
    80003898:	70a2                	ld	ra,40(sp)
    8000389a:	7402                	ld	s0,32(sp)
    8000389c:	64e2                	ld	s1,24(sp)
    8000389e:	6145                	addi	sp,sp,48
    800038a0:	8082                	ret
    return -1;
    800038a2:	54fd                	li	s1,-1
    800038a4:	bfcd                	j	80003896 <sys_sbrk+0x3a>

00000000800038a6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800038a6:	7139                	addi	sp,sp,-64
    800038a8:	fc06                	sd	ra,56(sp)
    800038aa:	f822                	sd	s0,48(sp)
    800038ac:	f426                	sd	s1,40(sp)
    800038ae:	f04a                	sd	s2,32(sp)
    800038b0:	ec4e                	sd	s3,24(sp)
    800038b2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800038b4:	fcc40593          	addi	a1,s0,-52
    800038b8:	4501                	li	a0,0
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	e2e080e7          	jalr	-466(ra) # 800036e8 <argint>
    return -1;
    800038c2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800038c4:	06054563          	bltz	a0,8000392e <sys_sleep+0x88>
  acquire(&tickslock);
    800038c8:	00031517          	auipc	a0,0x31
    800038cc:	e3850513          	addi	a0,a0,-456 # 80034700 <tickslock>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	2f2080e7          	jalr	754(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    800038d8:	00006917          	auipc	s2,0x6
    800038dc:	75892903          	lw	s2,1880(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    800038e0:	fcc42783          	lw	a5,-52(s0)
    800038e4:	cf85                	beqz	a5,8000391c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800038e6:	00031997          	auipc	s3,0x31
    800038ea:	e1a98993          	addi	s3,s3,-486 # 80034700 <tickslock>
    800038ee:	00006497          	auipc	s1,0x6
    800038f2:	74248493          	addi	s1,s1,1858 # 8000a030 <ticks>
    if(myproc()->killed){
    800038f6:	ffffe097          	auipc	ra,0xffffe
    800038fa:	13c080e7          	jalr	316(ra) # 80001a32 <myproc>
    800038fe:	4d5c                	lw	a5,28(a0)
    80003900:	ef9d                	bnez	a5,8000393e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003902:	85ce                	mv	a1,s3
    80003904:	8526                	mv	a0,s1
    80003906:	fffff097          	auipc	ra,0xfffff
    8000390a:	dd2080e7          	jalr	-558(ra) # 800026d8 <sleep>
  while(ticks - ticks0 < n){
    8000390e:	409c                	lw	a5,0(s1)
    80003910:	412787bb          	subw	a5,a5,s2
    80003914:	fcc42703          	lw	a4,-52(s0)
    80003918:	fce7efe3          	bltu	a5,a4,800038f6 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000391c:	00031517          	auipc	a0,0x31
    80003920:	de450513          	addi	a0,a0,-540 # 80034700 <tickslock>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	364080e7          	jalr	868(ra) # 80000c88 <release>
  return 0;
    8000392c:	4781                	li	a5,0
}
    8000392e:	853e                	mv	a0,a5
    80003930:	70e2                	ld	ra,56(sp)
    80003932:	7442                	ld	s0,48(sp)
    80003934:	74a2                	ld	s1,40(sp)
    80003936:	7902                	ld	s2,32(sp)
    80003938:	69e2                	ld	s3,24(sp)
    8000393a:	6121                	addi	sp,sp,64
    8000393c:	8082                	ret
      release(&tickslock);
    8000393e:	00031517          	auipc	a0,0x31
    80003942:	dc250513          	addi	a0,a0,-574 # 80034700 <tickslock>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	342080e7          	jalr	834(ra) # 80000c88 <release>
      return -1;
    8000394e:	57fd                	li	a5,-1
    80003950:	bff9                	j	8000392e <sys_sleep+0x88>

0000000080003952 <sys_kill>:

// ADDED Q2.2.1
uint64
sys_kill(void)
{
    80003952:	1101                	addi	sp,sp,-32
    80003954:	ec06                	sd	ra,24(sp)
    80003956:	e822                	sd	s0,16(sp)
    80003958:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    8000395a:	fec40593          	addi	a1,s0,-20
    8000395e:	4501                	li	a0,0
    80003960:	00000097          	auipc	ra,0x0
    80003964:	d88080e7          	jalr	-632(ra) # 800036e8 <argint>
    return -1;
    80003968:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    8000396a:	02054563          	bltz	a0,80003994 <sys_kill+0x42>

  if(argint(1, &signum) < 0)
    8000396e:	fe840593          	addi	a1,s0,-24
    80003972:	4505                	li	a0,1
    80003974:	00000097          	auipc	ra,0x0
    80003978:	d74080e7          	jalr	-652(ra) # 800036e8 <argint>
    return -1;
    8000397c:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    8000397e:	00054b63          	bltz	a0,80003994 <sys_kill+0x42>

  return kill(pid, signum);
    80003982:	fe842583          	lw	a1,-24(s0)
    80003986:	fec42503          	lw	a0,-20(s0)
    8000398a:	fffff097          	auipc	ra,0xfffff
    8000398e:	fce080e7          	jalr	-50(ra) # 80002958 <kill>
    80003992:	87aa                	mv	a5,a0
}
    80003994:	853e                	mv	a0,a5
    80003996:	60e2                	ld	ra,24(sp)
    80003998:	6442                	ld	s0,16(sp)
    8000399a:	6105                	addi	sp,sp,32
    8000399c:	8082                	ret

000000008000399e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000399e:	1101                	addi	sp,sp,-32
    800039a0:	ec06                	sd	ra,24(sp)
    800039a2:	e822                	sd	s0,16(sp)
    800039a4:	e426                	sd	s1,8(sp)
    800039a6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800039a8:	00031517          	auipc	a0,0x31
    800039ac:	d5850513          	addi	a0,a0,-680 # 80034700 <tickslock>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	212080e7          	jalr	530(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800039b8:	00006497          	auipc	s1,0x6
    800039bc:	6784a483          	lw	s1,1656(s1) # 8000a030 <ticks>
  release(&tickslock);
    800039c0:	00031517          	auipc	a0,0x31
    800039c4:	d4050513          	addi	a0,a0,-704 # 80034700 <tickslock>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	2c0080e7          	jalr	704(ra) # 80000c88 <release>
  return xticks;
}
    800039d0:	02049513          	slli	a0,s1,0x20
    800039d4:	9101                	srli	a0,a0,0x20
    800039d6:	60e2                	ld	ra,24(sp)
    800039d8:	6442                	ld	s0,16(sp)
    800039da:	64a2                	ld	s1,8(sp)
    800039dc:	6105                	addi	sp,sp,32
    800039de:	8082                	ret

00000000800039e0 <sys_sigprocmask>:

// ADDED Q2.1.3
uint64
sys_sigprocmask(void)
{
    800039e0:	1101                	addi	sp,sp,-32
    800039e2:	ec06                	sd	ra,24(sp)
    800039e4:	e822                	sd	s0,16(sp)
    800039e6:	1000                	addi	s0,sp,32
  uint sigmask;

  if(argint(0, (int *)&sigmask) < 0) 
    800039e8:	fec40593          	addi	a1,s0,-20
    800039ec:	4501                	li	a0,0
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	cfa080e7          	jalr	-774(ra) # 800036e8 <argint>
    800039f6:	87aa                	mv	a5,a0
    return -1;
    800039f8:	557d                	li	a0,-1
  if(argint(0, (int *)&sigmask) < 0) 
    800039fa:	0007ca63          	bltz	a5,80003a0e <sys_sigprocmask+0x2e>

  return sigprocmask(sigmask);
    800039fe:	fec42503          	lw	a0,-20(s0)
    80003a02:	fffff097          	auipc	ra,0xfffff
    80003a06:	142080e7          	jalr	322(ra) # 80002b44 <sigprocmask>
    80003a0a:	1502                	slli	a0,a0,0x20
    80003a0c:	9101                	srli	a0,a0,0x20
}
    80003a0e:	60e2                	ld	ra,24(sp)
    80003a10:	6442                	ld	s0,16(sp)
    80003a12:	6105                	addi	sp,sp,32
    80003a14:	8082                	ret

0000000080003a16 <sys_sigaction>:

// ADDED Q2.1.4
uint64
sys_sigaction(void)
{
    80003a16:	7179                	addi	sp,sp,-48
    80003a18:	f406                	sd	ra,40(sp)
    80003a1a:	f022                	sd	s0,32(sp)
    80003a1c:	1800                	addi	s0,sp,48
  int signum;
  struct sigaction *act;
  struct sigaction *oldact;

  if(argint(0, &signum) < 0)
    80003a1e:	fec40593          	addi	a1,s0,-20
    80003a22:	4501                	li	a0,0
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	cc4080e7          	jalr	-828(ra) # 800036e8 <argint>
    return -1;
    80003a2c:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    80003a2e:	04054163          	bltz	a0,80003a70 <sys_sigaction+0x5a>

  if(argaddr(1, (uint64 *)&act) < 0)
    80003a32:	fe040593          	addi	a1,s0,-32
    80003a36:	4505                	li	a0,1
    80003a38:	00000097          	auipc	ra,0x0
    80003a3c:	cd2080e7          	jalr	-814(ra) # 8000370a <argaddr>
    return -1;
    80003a40:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&act) < 0)
    80003a42:	02054763          	bltz	a0,80003a70 <sys_sigaction+0x5a>

  if(argaddr(2, (uint64 *)&oldact) < 0)
    80003a46:	fd840593          	addi	a1,s0,-40
    80003a4a:	4509                	li	a0,2
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	cbe080e7          	jalr	-834(ra) # 8000370a <argaddr>
    return -1;
    80003a54:	57fd                	li	a5,-1
  if(argaddr(2, (uint64 *)&oldact) < 0)
    80003a56:	00054d63          	bltz	a0,80003a70 <sys_sigaction+0x5a>

  return sigaction(signum, act, oldact);
    80003a5a:	fd843603          	ld	a2,-40(s0)
    80003a5e:	fe043583          	ld	a1,-32(s0)
    80003a62:	fec42503          	lw	a0,-20(s0)
    80003a66:	fffff097          	auipc	ra,0xfffff
    80003a6a:	13e080e7          	jalr	318(ra) # 80002ba4 <sigaction>
    80003a6e:	87aa                	mv	a5,a0
}
    80003a70:	853e                	mv	a0,a5
    80003a72:	70a2                	ld	ra,40(sp)
    80003a74:	7402                	ld	s0,32(sp)
    80003a76:	6145                	addi	sp,sp,48
    80003a78:	8082                	ret

0000000080003a7a <sys_sigret>:

// ADDED Q2.1.5
uint64
sys_sigret(void)
{
    80003a7a:	1141                	addi	sp,sp,-16
    80003a7c:	e406                	sd	ra,8(sp)
    80003a7e:	e022                	sd	s0,0(sp)
    80003a80:	0800                	addi	s0,sp,16
  sigret();
    80003a82:	fffff097          	auipc	ra,0xfffff
    80003a86:	262080e7          	jalr	610(ra) # 80002ce4 <sigret>
  return 0;
}
    80003a8a:	4501                	li	a0,0
    80003a8c:	60a2                	ld	ra,8(sp)
    80003a8e:	6402                	ld	s0,0(sp)
    80003a90:	0141                	addi	sp,sp,16
    80003a92:	8082                	ret

0000000080003a94 <sys_kthread_create>:

// ADDED Q3.2
uint64
sys_kthread_create(void)
{
    80003a94:	1101                	addi	sp,sp,-32
    80003a96:	ec06                	sd	ra,24(sp)
    80003a98:	e822                	sd	s0,16(sp)
    80003a9a:	1000                	addi	s0,sp,32
  uint64 start_func;
  uint64 stack;

  if(argaddr(0, &start_func) < 0)
    80003a9c:	fe840593          	addi	a1,s0,-24
    80003aa0:	4501                	li	a0,0
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	c68080e7          	jalr	-920(ra) # 8000370a <argaddr>
    return -1;
    80003aaa:	57fd                	li	a5,-1
  if(argaddr(0, &start_func) < 0)
    80003aac:	02054563          	bltz	a0,80003ad6 <sys_kthread_create+0x42>

  if(argaddr(1, &stack) < 0)
    80003ab0:	fe040593          	addi	a1,s0,-32
    80003ab4:	4505                	li	a0,1
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	c54080e7          	jalr	-940(ra) # 8000370a <argaddr>
    return -1;
    80003abe:	57fd                	li	a5,-1
  if(argaddr(1, &stack) < 0)
    80003ac0:	00054b63          	bltz	a0,80003ad6 <sys_kthread_create+0x42>

  return kthread_create(start_func, stack);
    80003ac4:	fe043583          	ld	a1,-32(s0)
    80003ac8:	fe843503          	ld	a0,-24(s0)
    80003acc:	fffff097          	auipc	ra,0xfffff
    80003ad0:	286080e7          	jalr	646(ra) # 80002d52 <kthread_create>
    80003ad4:	87aa                	mv	a5,a0
}
    80003ad6:	853e                	mv	a0,a5
    80003ad8:	60e2                	ld	ra,24(sp)
    80003ada:	6442                	ld	s0,16(sp)
    80003adc:	6105                	addi	sp,sp,32
    80003ade:	8082                	ret

0000000080003ae0 <sys_kthread_id>:

uint64
sys_kthread_id(void)
{
    80003ae0:	1141                	addi	sp,sp,-16
    80003ae2:	e406                	sd	ra,8(sp)
    80003ae4:	e022                	sd	s0,0(sp)
    80003ae6:	0800                	addi	s0,sp,16
  return mythread()->tid;
    80003ae8:	ffffe097          	auipc	ra,0xffffe
    80003aec:	f84080e7          	jalr	-124(ra) # 80001a6c <mythread>
}
    80003af0:	5908                	lw	a0,48(a0)
    80003af2:	60a2                	ld	ra,8(sp)
    80003af4:	6402                	ld	s0,0(sp)
    80003af6:	0141                	addi	sp,sp,16
    80003af8:	8082                	ret

0000000080003afa <sys_kthread_exit>:

uint64
sys_kthread_exit(void)
{
    80003afa:	1101                	addi	sp,sp,-32
    80003afc:	ec06                	sd	ra,24(sp)
    80003afe:	e822                	sd	s0,16(sp)
    80003b00:	1000                	addi	s0,sp,32
  int status;

  if(argint(0, &status) < 0)
    80003b02:	fec40593          	addi	a1,s0,-20
    80003b06:	4501                	li	a0,0
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	be0080e7          	jalr	-1056(ra) # 800036e8 <argint>
    return -1;
    80003b10:	57fd                	li	a5,-1
  if(argint(0, &status) < 0)
    80003b12:	00054963          	bltz	a0,80003b24 <sys_kthread_exit+0x2a>

  kthread_exit(status);
    80003b16:	fec42503          	lw	a0,-20(s0)
    80003b1a:	fffff097          	auipc	ra,0xfffff
    80003b1e:	5c2080e7          	jalr	1474(ra) # 800030dc <kthread_exit>
  return 0;
    80003b22:	4781                	li	a5,0
}
    80003b24:	853e                	mv	a0,a5
    80003b26:	60e2                	ld	ra,24(sp)
    80003b28:	6442                	ld	s0,16(sp)
    80003b2a:	6105                	addi	sp,sp,32
    80003b2c:	8082                	ret

0000000080003b2e <sys_kthread_join>:

uint64
sys_kthread_join(void)
{
    80003b2e:	1101                	addi	sp,sp,-32
    80003b30:	ec06                	sd	ra,24(sp)
    80003b32:	e822                	sd	s0,16(sp)
    80003b34:	1000                	addi	s0,sp,32
  int thread_id;
  int *status;

  if(argint(0, &thread_id) < 0)
    80003b36:	fec40593          	addi	a1,s0,-20
    80003b3a:	4501                	li	a0,0
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	bac080e7          	jalr	-1108(ra) # 800036e8 <argint>
    return -1;
    80003b44:	57fd                	li	a5,-1
  if(argint(0, &thread_id) < 0)
    80003b46:	02054563          	bltz	a0,80003b70 <sys_kthread_join+0x42>

  if(argaddr(1, (uint64 *)&status) < 0)
    80003b4a:	fe040593          	addi	a1,s0,-32
    80003b4e:	4505                	li	a0,1
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	bba080e7          	jalr	-1094(ra) # 8000370a <argaddr>
    return -1;
    80003b58:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&status) < 0)
    80003b5a:	00054b63          	bltz	a0,80003b70 <sys_kthread_join+0x42>

  return kthread_join(thread_id, status);
    80003b5e:	fe043583          	ld	a1,-32(s0)
    80003b62:	fec42503          	lw	a0,-20(s0)
    80003b66:	fffff097          	auipc	ra,0xfffff
    80003b6a:	2ec080e7          	jalr	748(ra) # 80002e52 <kthread_join>
    80003b6e:	87aa                	mv	a5,a0
}
    80003b70:	853e                	mv	a0,a5
    80003b72:	60e2                	ld	ra,24(sp)
    80003b74:	6442                	ld	s0,16(sp)
    80003b76:	6105                	addi	sp,sp,32
    80003b78:	8082                	ret

0000000080003b7a <sys_bsem_alloc>:

uint64
sys_bsem_alloc(void)
{
    80003b7a:	1141                	addi	sp,sp,-16
    80003b7c:	e406                	sd	ra,8(sp)
    80003b7e:	e022                	sd	s0,0(sp)
    80003b80:	0800                	addi	s0,sp,16
  return bsem_alloc();
    80003b82:	fffff097          	auipc	ra,0xfffff
    80003b86:	5e4080e7          	jalr	1508(ra) # 80003166 <bsem_alloc>
}
    80003b8a:	60a2                	ld	ra,8(sp)
    80003b8c:	6402                	ld	s0,0(sp)
    80003b8e:	0141                	addi	sp,sp,16
    80003b90:	8082                	ret

0000000080003b92 <sys_bsem_free>:

uint64
sys_bsem_free(void)
{
    80003b92:	1101                	addi	sp,sp,-32
    80003b94:	ec06                	sd	ra,24(sp)
    80003b96:	e822                	sd	s0,16(sp)
    80003b98:	1000                	addi	s0,sp,32
  int descriptor;

  if(argint(0, &descriptor) < 0)
    80003b9a:	fec40593          	addi	a1,s0,-20
    80003b9e:	4501                	li	a0,0
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	b48080e7          	jalr	-1208(ra) # 800036e8 <argint>
    return -1;
    80003ba8:	57fd                	li	a5,-1
  if(argint(0, &descriptor) < 0)
    80003baa:	00054963          	bltz	a0,80003bbc <sys_bsem_free+0x2a>
  
  bsem_free(descriptor);
    80003bae:	fec42503          	lw	a0,-20(s0)
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	5c2080e7          	jalr	1474(ra) # 80003174 <bsem_free>
  return 0;
    80003bba:	4781                	li	a5,0
}
    80003bbc:	853e                	mv	a0,a5
    80003bbe:	60e2                	ld	ra,24(sp)
    80003bc0:	6442                	ld	s0,16(sp)
    80003bc2:	6105                	addi	sp,sp,32
    80003bc4:	8082                	ret

0000000080003bc6 <sys_bsem_down>:

uint64
sys_bsem_down(void)
{
    80003bc6:	1101                	addi	sp,sp,-32
    80003bc8:	ec06                	sd	ra,24(sp)
    80003bca:	e822                	sd	s0,16(sp)
    80003bcc:	1000                	addi	s0,sp,32
  int descriptor;

  if(argint(0, &descriptor) < 0)
    80003bce:	fec40593          	addi	a1,s0,-20
    80003bd2:	4501                	li	a0,0
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	b14080e7          	jalr	-1260(ra) # 800036e8 <argint>
    return -1;
    80003bdc:	57fd                	li	a5,-1
  if(argint(0, &descriptor) < 0)
    80003bde:	00054963          	bltz	a0,80003bf0 <sys_bsem_down+0x2a>
  
  bsem_down(descriptor);
    80003be2:	fec42503          	lw	a0,-20(s0)
    80003be6:	fffff097          	auipc	ra,0xfffff
    80003bea:	59a080e7          	jalr	1434(ra) # 80003180 <bsem_down>
  return 0;
    80003bee:	4781                	li	a5,0
}
    80003bf0:	853e                	mv	a0,a5
    80003bf2:	60e2                	ld	ra,24(sp)
    80003bf4:	6442                	ld	s0,16(sp)
    80003bf6:	6105                	addi	sp,sp,32
    80003bf8:	8082                	ret

0000000080003bfa <sys_bsem_up>:

uint64
sys_bsem_up(void)
{
    80003bfa:	1101                	addi	sp,sp,-32
    80003bfc:	ec06                	sd	ra,24(sp)
    80003bfe:	e822                	sd	s0,16(sp)
    80003c00:	1000                	addi	s0,sp,32
  int descriptor;

  if(argint(0, &descriptor) < 0)
    80003c02:	fec40593          	addi	a1,s0,-20
    80003c06:	4501                	li	a0,0
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	ae0080e7          	jalr	-1312(ra) # 800036e8 <argint>
    return -1;
    80003c10:	57fd                	li	a5,-1
  if(argint(0, &descriptor) < 0)
    80003c12:	00054963          	bltz	a0,80003c24 <sys_bsem_up+0x2a>
  
  bsem_up(descriptor);
    80003c16:	fec42503          	lw	a0,-20(s0)
    80003c1a:	fffff097          	auipc	ra,0xfffff
    80003c1e:	572080e7          	jalr	1394(ra) # 8000318c <bsem_up>
  return 0; 
    80003c22:	4781                	li	a5,0
}
    80003c24:	853e                	mv	a0,a5
    80003c26:	60e2                	ld	ra,24(sp)
    80003c28:	6442                	ld	s0,16(sp)
    80003c2a:	6105                	addi	sp,sp,32
    80003c2c:	8082                	ret

0000000080003c2e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003c2e:	7179                	addi	sp,sp,-48
    80003c30:	f406                	sd	ra,40(sp)
    80003c32:	f022                	sd	s0,32(sp)
    80003c34:	ec26                	sd	s1,24(sp)
    80003c36:	e84a                	sd	s2,16(sp)
    80003c38:	e44e                	sd	s3,8(sp)
    80003c3a:	e052                	sd	s4,0(sp)
    80003c3c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003c3e:	00006597          	auipc	a1,0x6
    80003c42:	92a58593          	addi	a1,a1,-1750 # 80009568 <syscalls+0x108>
    80003c46:	00031517          	auipc	a0,0x31
    80003c4a:	ad250513          	addi	a0,a0,-1326 # 80034718 <bcache>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	ee4080e7          	jalr	-284(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003c56:	00039797          	auipc	a5,0x39
    80003c5a:	ac278793          	addi	a5,a5,-1342 # 8003c718 <bcache+0x8000>
    80003c5e:	00039717          	auipc	a4,0x39
    80003c62:	d2270713          	addi	a4,a4,-734 # 8003c980 <bcache+0x8268>
    80003c66:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003c6a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003c6e:	00031497          	auipc	s1,0x31
    80003c72:	ac248493          	addi	s1,s1,-1342 # 80034730 <bcache+0x18>
    b->next = bcache.head.next;
    80003c76:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003c78:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003c7a:	00006a17          	auipc	s4,0x6
    80003c7e:	8f6a0a13          	addi	s4,s4,-1802 # 80009570 <syscalls+0x110>
    b->next = bcache.head.next;
    80003c82:	2b893783          	ld	a5,696(s2)
    80003c86:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003c88:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003c8c:	85d2                	mv	a1,s4
    80003c8e:	01048513          	addi	a0,s1,16
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	4c2080e7          	jalr	1218(ra) # 80005154 <initsleeplock>
    bcache.head.next->prev = b;
    80003c9a:	2b893783          	ld	a5,696(s2)
    80003c9e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003ca0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ca4:	45848493          	addi	s1,s1,1112
    80003ca8:	fd349de3          	bne	s1,s3,80003c82 <binit+0x54>
  }
}
    80003cac:	70a2                	ld	ra,40(sp)
    80003cae:	7402                	ld	s0,32(sp)
    80003cb0:	64e2                	ld	s1,24(sp)
    80003cb2:	6942                	ld	s2,16(sp)
    80003cb4:	69a2                	ld	s3,8(sp)
    80003cb6:	6a02                	ld	s4,0(sp)
    80003cb8:	6145                	addi	sp,sp,48
    80003cba:	8082                	ret

0000000080003cbc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003cbc:	7179                	addi	sp,sp,-48
    80003cbe:	f406                	sd	ra,40(sp)
    80003cc0:	f022                	sd	s0,32(sp)
    80003cc2:	ec26                	sd	s1,24(sp)
    80003cc4:	e84a                	sd	s2,16(sp)
    80003cc6:	e44e                	sd	s3,8(sp)
    80003cc8:	1800                	addi	s0,sp,48
    80003cca:	892a                	mv	s2,a0
    80003ccc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003cce:	00031517          	auipc	a0,0x31
    80003cd2:	a4a50513          	addi	a0,a0,-1462 # 80034718 <bcache>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	eec080e7          	jalr	-276(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003cde:	00039497          	auipc	s1,0x39
    80003ce2:	cf24b483          	ld	s1,-782(s1) # 8003c9d0 <bcache+0x82b8>
    80003ce6:	00039797          	auipc	a5,0x39
    80003cea:	c9a78793          	addi	a5,a5,-870 # 8003c980 <bcache+0x8268>
    80003cee:	02f48f63          	beq	s1,a5,80003d2c <bread+0x70>
    80003cf2:	873e                	mv	a4,a5
    80003cf4:	a021                	j	80003cfc <bread+0x40>
    80003cf6:	68a4                	ld	s1,80(s1)
    80003cf8:	02e48a63          	beq	s1,a4,80003d2c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003cfc:	449c                	lw	a5,8(s1)
    80003cfe:	ff279ce3          	bne	a5,s2,80003cf6 <bread+0x3a>
    80003d02:	44dc                	lw	a5,12(s1)
    80003d04:	ff3799e3          	bne	a5,s3,80003cf6 <bread+0x3a>
      b->refcnt++;
    80003d08:	40bc                	lw	a5,64(s1)
    80003d0a:	2785                	addiw	a5,a5,1
    80003d0c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003d0e:	00031517          	auipc	a0,0x31
    80003d12:	a0a50513          	addi	a0,a0,-1526 # 80034718 <bcache>
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	f72080e7          	jalr	-142(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003d1e:	01048513          	addi	a0,s1,16
    80003d22:	00001097          	auipc	ra,0x1
    80003d26:	46c080e7          	jalr	1132(ra) # 8000518e <acquiresleep>
      return b;
    80003d2a:	a8b9                	j	80003d88 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003d2c:	00039497          	auipc	s1,0x39
    80003d30:	c9c4b483          	ld	s1,-868(s1) # 8003c9c8 <bcache+0x82b0>
    80003d34:	00039797          	auipc	a5,0x39
    80003d38:	c4c78793          	addi	a5,a5,-948 # 8003c980 <bcache+0x8268>
    80003d3c:	00f48863          	beq	s1,a5,80003d4c <bread+0x90>
    80003d40:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003d42:	40bc                	lw	a5,64(s1)
    80003d44:	cf81                	beqz	a5,80003d5c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003d46:	64a4                	ld	s1,72(s1)
    80003d48:	fee49de3          	bne	s1,a4,80003d42 <bread+0x86>
  panic("bget: no buffers");
    80003d4c:	00006517          	auipc	a0,0x6
    80003d50:	82c50513          	addi	a0,a0,-2004 # 80009578 <syscalls+0x118>
    80003d54:	ffffc097          	auipc	ra,0xffffc
    80003d58:	7d6080e7          	jalr	2006(ra) # 8000052a <panic>
      b->dev = dev;
    80003d5c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003d60:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003d64:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003d68:	4785                	li	a5,1
    80003d6a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003d6c:	00031517          	auipc	a0,0x31
    80003d70:	9ac50513          	addi	a0,a0,-1620 # 80034718 <bcache>
    80003d74:	ffffd097          	auipc	ra,0xffffd
    80003d78:	f14080e7          	jalr	-236(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003d7c:	01048513          	addi	a0,s1,16
    80003d80:	00001097          	auipc	ra,0x1
    80003d84:	40e080e7          	jalr	1038(ra) # 8000518e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003d88:	409c                	lw	a5,0(s1)
    80003d8a:	cb89                	beqz	a5,80003d9c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003d8c:	8526                	mv	a0,s1
    80003d8e:	70a2                	ld	ra,40(sp)
    80003d90:	7402                	ld	s0,32(sp)
    80003d92:	64e2                	ld	s1,24(sp)
    80003d94:	6942                	ld	s2,16(sp)
    80003d96:	69a2                	ld	s3,8(sp)
    80003d98:	6145                	addi	sp,sp,48
    80003d9a:	8082                	ret
    virtio_disk_rw(b, 0);
    80003d9c:	4581                	li	a1,0
    80003d9e:	8526                	mv	a0,s1
    80003da0:	00003097          	auipc	ra,0x3
    80003da4:	fc6080e7          	jalr	-58(ra) # 80006d66 <virtio_disk_rw>
    b->valid = 1;
    80003da8:	4785                	li	a5,1
    80003daa:	c09c                	sw	a5,0(s1)
  return b;
    80003dac:	b7c5                	j	80003d8c <bread+0xd0>

0000000080003dae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003dae:	1101                	addi	sp,sp,-32
    80003db0:	ec06                	sd	ra,24(sp)
    80003db2:	e822                	sd	s0,16(sp)
    80003db4:	e426                	sd	s1,8(sp)
    80003db6:	1000                	addi	s0,sp,32
    80003db8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003dba:	0541                	addi	a0,a0,16
    80003dbc:	00001097          	auipc	ra,0x1
    80003dc0:	46c080e7          	jalr	1132(ra) # 80005228 <holdingsleep>
    80003dc4:	cd01                	beqz	a0,80003ddc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003dc6:	4585                	li	a1,1
    80003dc8:	8526                	mv	a0,s1
    80003dca:	00003097          	auipc	ra,0x3
    80003dce:	f9c080e7          	jalr	-100(ra) # 80006d66 <virtio_disk_rw>
}
    80003dd2:	60e2                	ld	ra,24(sp)
    80003dd4:	6442                	ld	s0,16(sp)
    80003dd6:	64a2                	ld	s1,8(sp)
    80003dd8:	6105                	addi	sp,sp,32
    80003dda:	8082                	ret
    panic("bwrite");
    80003ddc:	00005517          	auipc	a0,0x5
    80003de0:	7b450513          	addi	a0,a0,1972 # 80009590 <syscalls+0x130>
    80003de4:	ffffc097          	auipc	ra,0xffffc
    80003de8:	746080e7          	jalr	1862(ra) # 8000052a <panic>

0000000080003dec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003dec:	1101                	addi	sp,sp,-32
    80003dee:	ec06                	sd	ra,24(sp)
    80003df0:	e822                	sd	s0,16(sp)
    80003df2:	e426                	sd	s1,8(sp)
    80003df4:	e04a                	sd	s2,0(sp)
    80003df6:	1000                	addi	s0,sp,32
    80003df8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003dfa:	01050913          	addi	s2,a0,16
    80003dfe:	854a                	mv	a0,s2
    80003e00:	00001097          	auipc	ra,0x1
    80003e04:	428080e7          	jalr	1064(ra) # 80005228 <holdingsleep>
    80003e08:	c92d                	beqz	a0,80003e7a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003e0a:	854a                	mv	a0,s2
    80003e0c:	00001097          	auipc	ra,0x1
    80003e10:	3d8080e7          	jalr	984(ra) # 800051e4 <releasesleep>

  acquire(&bcache.lock);
    80003e14:	00031517          	auipc	a0,0x31
    80003e18:	90450513          	addi	a0,a0,-1788 # 80034718 <bcache>
    80003e1c:	ffffd097          	auipc	ra,0xffffd
    80003e20:	da6080e7          	jalr	-602(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003e24:	40bc                	lw	a5,64(s1)
    80003e26:	37fd                	addiw	a5,a5,-1
    80003e28:	0007871b          	sext.w	a4,a5
    80003e2c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003e2e:	eb05                	bnez	a4,80003e5e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003e30:	68bc                	ld	a5,80(s1)
    80003e32:	64b8                	ld	a4,72(s1)
    80003e34:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003e36:	64bc                	ld	a5,72(s1)
    80003e38:	68b8                	ld	a4,80(s1)
    80003e3a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003e3c:	00039797          	auipc	a5,0x39
    80003e40:	8dc78793          	addi	a5,a5,-1828 # 8003c718 <bcache+0x8000>
    80003e44:	2b87b703          	ld	a4,696(a5)
    80003e48:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003e4a:	00039717          	auipc	a4,0x39
    80003e4e:	b3670713          	addi	a4,a4,-1226 # 8003c980 <bcache+0x8268>
    80003e52:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003e54:	2b87b703          	ld	a4,696(a5)
    80003e58:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003e5a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003e5e:	00031517          	auipc	a0,0x31
    80003e62:	8ba50513          	addi	a0,a0,-1862 # 80034718 <bcache>
    80003e66:	ffffd097          	auipc	ra,0xffffd
    80003e6a:	e22080e7          	jalr	-478(ra) # 80000c88 <release>
}
    80003e6e:	60e2                	ld	ra,24(sp)
    80003e70:	6442                	ld	s0,16(sp)
    80003e72:	64a2                	ld	s1,8(sp)
    80003e74:	6902                	ld	s2,0(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret
    panic("brelse");
    80003e7a:	00005517          	auipc	a0,0x5
    80003e7e:	71e50513          	addi	a0,a0,1822 # 80009598 <syscalls+0x138>
    80003e82:	ffffc097          	auipc	ra,0xffffc
    80003e86:	6a8080e7          	jalr	1704(ra) # 8000052a <panic>

0000000080003e8a <bpin>:

void
bpin(struct buf *b) {
    80003e8a:	1101                	addi	sp,sp,-32
    80003e8c:	ec06                	sd	ra,24(sp)
    80003e8e:	e822                	sd	s0,16(sp)
    80003e90:	e426                	sd	s1,8(sp)
    80003e92:	1000                	addi	s0,sp,32
    80003e94:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003e96:	00031517          	auipc	a0,0x31
    80003e9a:	88250513          	addi	a0,a0,-1918 # 80034718 <bcache>
    80003e9e:	ffffd097          	auipc	ra,0xffffd
    80003ea2:	d24080e7          	jalr	-732(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003ea6:	40bc                	lw	a5,64(s1)
    80003ea8:	2785                	addiw	a5,a5,1
    80003eaa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003eac:	00031517          	auipc	a0,0x31
    80003eb0:	86c50513          	addi	a0,a0,-1940 # 80034718 <bcache>
    80003eb4:	ffffd097          	auipc	ra,0xffffd
    80003eb8:	dd4080e7          	jalr	-556(ra) # 80000c88 <release>
}
    80003ebc:	60e2                	ld	ra,24(sp)
    80003ebe:	6442                	ld	s0,16(sp)
    80003ec0:	64a2                	ld	s1,8(sp)
    80003ec2:	6105                	addi	sp,sp,32
    80003ec4:	8082                	ret

0000000080003ec6 <bunpin>:

void
bunpin(struct buf *b) {
    80003ec6:	1101                	addi	sp,sp,-32
    80003ec8:	ec06                	sd	ra,24(sp)
    80003eca:	e822                	sd	s0,16(sp)
    80003ecc:	e426                	sd	s1,8(sp)
    80003ece:	1000                	addi	s0,sp,32
    80003ed0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003ed2:	00031517          	auipc	a0,0x31
    80003ed6:	84650513          	addi	a0,a0,-1978 # 80034718 <bcache>
    80003eda:	ffffd097          	auipc	ra,0xffffd
    80003ede:	ce8080e7          	jalr	-792(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003ee2:	40bc                	lw	a5,64(s1)
    80003ee4:	37fd                	addiw	a5,a5,-1
    80003ee6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ee8:	00031517          	auipc	a0,0x31
    80003eec:	83050513          	addi	a0,a0,-2000 # 80034718 <bcache>
    80003ef0:	ffffd097          	auipc	ra,0xffffd
    80003ef4:	d98080e7          	jalr	-616(ra) # 80000c88 <release>
}
    80003ef8:	60e2                	ld	ra,24(sp)
    80003efa:	6442                	ld	s0,16(sp)
    80003efc:	64a2                	ld	s1,8(sp)
    80003efe:	6105                	addi	sp,sp,32
    80003f00:	8082                	ret

0000000080003f02 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003f02:	1101                	addi	sp,sp,-32
    80003f04:	ec06                	sd	ra,24(sp)
    80003f06:	e822                	sd	s0,16(sp)
    80003f08:	e426                	sd	s1,8(sp)
    80003f0a:	e04a                	sd	s2,0(sp)
    80003f0c:	1000                	addi	s0,sp,32
    80003f0e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003f10:	00d5d59b          	srliw	a1,a1,0xd
    80003f14:	00039797          	auipc	a5,0x39
    80003f18:	ee07a783          	lw	a5,-288(a5) # 8003cdf4 <sb+0x1c>
    80003f1c:	9dbd                	addw	a1,a1,a5
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	d9e080e7          	jalr	-610(ra) # 80003cbc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003f26:	0074f713          	andi	a4,s1,7
    80003f2a:	4785                	li	a5,1
    80003f2c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003f30:	14ce                	slli	s1,s1,0x33
    80003f32:	90d9                	srli	s1,s1,0x36
    80003f34:	00950733          	add	a4,a0,s1
    80003f38:	05874703          	lbu	a4,88(a4)
    80003f3c:	00e7f6b3          	and	a3,a5,a4
    80003f40:	c69d                	beqz	a3,80003f6e <bfree+0x6c>
    80003f42:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003f44:	94aa                	add	s1,s1,a0
    80003f46:	fff7c793          	not	a5,a5
    80003f4a:	8ff9                	and	a5,a5,a4
    80003f4c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003f50:	00001097          	auipc	ra,0x1
    80003f54:	11e080e7          	jalr	286(ra) # 8000506e <log_write>
  brelse(bp);
    80003f58:	854a                	mv	a0,s2
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	e92080e7          	jalr	-366(ra) # 80003dec <brelse>
}
    80003f62:	60e2                	ld	ra,24(sp)
    80003f64:	6442                	ld	s0,16(sp)
    80003f66:	64a2                	ld	s1,8(sp)
    80003f68:	6902                	ld	s2,0(sp)
    80003f6a:	6105                	addi	sp,sp,32
    80003f6c:	8082                	ret
    panic("freeing free block");
    80003f6e:	00005517          	auipc	a0,0x5
    80003f72:	63250513          	addi	a0,a0,1586 # 800095a0 <syscalls+0x140>
    80003f76:	ffffc097          	auipc	ra,0xffffc
    80003f7a:	5b4080e7          	jalr	1460(ra) # 8000052a <panic>

0000000080003f7e <balloc>:
{
    80003f7e:	711d                	addi	sp,sp,-96
    80003f80:	ec86                	sd	ra,88(sp)
    80003f82:	e8a2                	sd	s0,80(sp)
    80003f84:	e4a6                	sd	s1,72(sp)
    80003f86:	e0ca                	sd	s2,64(sp)
    80003f88:	fc4e                	sd	s3,56(sp)
    80003f8a:	f852                	sd	s4,48(sp)
    80003f8c:	f456                	sd	s5,40(sp)
    80003f8e:	f05a                	sd	s6,32(sp)
    80003f90:	ec5e                	sd	s7,24(sp)
    80003f92:	e862                	sd	s8,16(sp)
    80003f94:	e466                	sd	s9,8(sp)
    80003f96:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003f98:	00039797          	auipc	a5,0x39
    80003f9c:	e447a783          	lw	a5,-444(a5) # 8003cddc <sb+0x4>
    80003fa0:	cbd1                	beqz	a5,80004034 <balloc+0xb6>
    80003fa2:	8baa                	mv	s7,a0
    80003fa4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003fa6:	00039b17          	auipc	s6,0x39
    80003faa:	e32b0b13          	addi	s6,s6,-462 # 8003cdd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003fae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003fb0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003fb2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003fb4:	6c89                	lui	s9,0x2
    80003fb6:	a831                	j	80003fd2 <balloc+0x54>
    brelse(bp);
    80003fb8:	854a                	mv	a0,s2
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	e32080e7          	jalr	-462(ra) # 80003dec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003fc2:	015c87bb          	addw	a5,s9,s5
    80003fc6:	00078a9b          	sext.w	s5,a5
    80003fca:	004b2703          	lw	a4,4(s6)
    80003fce:	06eaf363          	bgeu	s5,a4,80004034 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003fd2:	41fad79b          	sraiw	a5,s5,0x1f
    80003fd6:	0137d79b          	srliw	a5,a5,0x13
    80003fda:	015787bb          	addw	a5,a5,s5
    80003fde:	40d7d79b          	sraiw	a5,a5,0xd
    80003fe2:	01cb2583          	lw	a1,28(s6)
    80003fe6:	9dbd                	addw	a1,a1,a5
    80003fe8:	855e                	mv	a0,s7
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	cd2080e7          	jalr	-814(ra) # 80003cbc <bread>
    80003ff2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ff4:	004b2503          	lw	a0,4(s6)
    80003ff8:	000a849b          	sext.w	s1,s5
    80003ffc:	8662                	mv	a2,s8
    80003ffe:	faa4fde3          	bgeu	s1,a0,80003fb8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80004002:	41f6579b          	sraiw	a5,a2,0x1f
    80004006:	01d7d69b          	srliw	a3,a5,0x1d
    8000400a:	00c6873b          	addw	a4,a3,a2
    8000400e:	00777793          	andi	a5,a4,7
    80004012:	9f95                	subw	a5,a5,a3
    80004014:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004018:	4037571b          	sraiw	a4,a4,0x3
    8000401c:	00e906b3          	add	a3,s2,a4
    80004020:	0586c683          	lbu	a3,88(a3) # 2000058 <_entry-0x7dffffa8>
    80004024:	00d7f5b3          	and	a1,a5,a3
    80004028:	cd91                	beqz	a1,80004044 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000402a:	2605                	addiw	a2,a2,1
    8000402c:	2485                	addiw	s1,s1,1
    8000402e:	fd4618e3          	bne	a2,s4,80003ffe <balloc+0x80>
    80004032:	b759                	j	80003fb8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80004034:	00005517          	auipc	a0,0x5
    80004038:	58450513          	addi	a0,a0,1412 # 800095b8 <syscalls+0x158>
    8000403c:	ffffc097          	auipc	ra,0xffffc
    80004040:	4ee080e7          	jalr	1262(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80004044:	974a                	add	a4,a4,s2
    80004046:	8fd5                	or	a5,a5,a3
    80004048:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000404c:	854a                	mv	a0,s2
    8000404e:	00001097          	auipc	ra,0x1
    80004052:	020080e7          	jalr	32(ra) # 8000506e <log_write>
        brelse(bp);
    80004056:	854a                	mv	a0,s2
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	d94080e7          	jalr	-620(ra) # 80003dec <brelse>
  bp = bread(dev, bno);
    80004060:	85a6                	mv	a1,s1
    80004062:	855e                	mv	a0,s7
    80004064:	00000097          	auipc	ra,0x0
    80004068:	c58080e7          	jalr	-936(ra) # 80003cbc <bread>
    8000406c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000406e:	40000613          	li	a2,1024
    80004072:	4581                	li	a1,0
    80004074:	05850513          	addi	a0,a0,88
    80004078:	ffffd097          	auipc	ra,0xffffd
    8000407c:	c6a080e7          	jalr	-918(ra) # 80000ce2 <memset>
  log_write(bp);
    80004080:	854a                	mv	a0,s2
    80004082:	00001097          	auipc	ra,0x1
    80004086:	fec080e7          	jalr	-20(ra) # 8000506e <log_write>
  brelse(bp);
    8000408a:	854a                	mv	a0,s2
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	d60080e7          	jalr	-672(ra) # 80003dec <brelse>
}
    80004094:	8526                	mv	a0,s1
    80004096:	60e6                	ld	ra,88(sp)
    80004098:	6446                	ld	s0,80(sp)
    8000409a:	64a6                	ld	s1,72(sp)
    8000409c:	6906                	ld	s2,64(sp)
    8000409e:	79e2                	ld	s3,56(sp)
    800040a0:	7a42                	ld	s4,48(sp)
    800040a2:	7aa2                	ld	s5,40(sp)
    800040a4:	7b02                	ld	s6,32(sp)
    800040a6:	6be2                	ld	s7,24(sp)
    800040a8:	6c42                	ld	s8,16(sp)
    800040aa:	6ca2                	ld	s9,8(sp)
    800040ac:	6125                	addi	sp,sp,96
    800040ae:	8082                	ret

00000000800040b0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800040b0:	7179                	addi	sp,sp,-48
    800040b2:	f406                	sd	ra,40(sp)
    800040b4:	f022                	sd	s0,32(sp)
    800040b6:	ec26                	sd	s1,24(sp)
    800040b8:	e84a                	sd	s2,16(sp)
    800040ba:	e44e                	sd	s3,8(sp)
    800040bc:	e052                	sd	s4,0(sp)
    800040be:	1800                	addi	s0,sp,48
    800040c0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800040c2:	47ad                	li	a5,11
    800040c4:	04b7fe63          	bgeu	a5,a1,80004120 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800040c8:	ff45849b          	addiw	s1,a1,-12
    800040cc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800040d0:	0ff00793          	li	a5,255
    800040d4:	0ae7e463          	bltu	a5,a4,8000417c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800040d8:	08052583          	lw	a1,128(a0)
    800040dc:	c5b5                	beqz	a1,80004148 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800040de:	00092503          	lw	a0,0(s2)
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	bda080e7          	jalr	-1062(ra) # 80003cbc <bread>
    800040ea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800040ec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800040f0:	02049713          	slli	a4,s1,0x20
    800040f4:	01e75593          	srli	a1,a4,0x1e
    800040f8:	00b784b3          	add	s1,a5,a1
    800040fc:	0004a983          	lw	s3,0(s1)
    80004100:	04098e63          	beqz	s3,8000415c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80004104:	8552                	mv	a0,s4
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	ce6080e7          	jalr	-794(ra) # 80003dec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000410e:	854e                	mv	a0,s3
    80004110:	70a2                	ld	ra,40(sp)
    80004112:	7402                	ld	s0,32(sp)
    80004114:	64e2                	ld	s1,24(sp)
    80004116:	6942                	ld	s2,16(sp)
    80004118:	69a2                	ld	s3,8(sp)
    8000411a:	6a02                	ld	s4,0(sp)
    8000411c:	6145                	addi	sp,sp,48
    8000411e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80004120:	02059793          	slli	a5,a1,0x20
    80004124:	01e7d593          	srli	a1,a5,0x1e
    80004128:	00b504b3          	add	s1,a0,a1
    8000412c:	0504a983          	lw	s3,80(s1)
    80004130:	fc099fe3          	bnez	s3,8000410e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80004134:	4108                	lw	a0,0(a0)
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	e48080e7          	jalr	-440(ra) # 80003f7e <balloc>
    8000413e:	0005099b          	sext.w	s3,a0
    80004142:	0534a823          	sw	s3,80(s1)
    80004146:	b7e1                	j	8000410e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80004148:	4108                	lw	a0,0(a0)
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	e34080e7          	jalr	-460(ra) # 80003f7e <balloc>
    80004152:	0005059b          	sext.w	a1,a0
    80004156:	08b92023          	sw	a1,128(s2)
    8000415a:	b751                	j	800040de <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000415c:	00092503          	lw	a0,0(s2)
    80004160:	00000097          	auipc	ra,0x0
    80004164:	e1e080e7          	jalr	-482(ra) # 80003f7e <balloc>
    80004168:	0005099b          	sext.w	s3,a0
    8000416c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80004170:	8552                	mv	a0,s4
    80004172:	00001097          	auipc	ra,0x1
    80004176:	efc080e7          	jalr	-260(ra) # 8000506e <log_write>
    8000417a:	b769                	j	80004104 <bmap+0x54>
  panic("bmap: out of range");
    8000417c:	00005517          	auipc	a0,0x5
    80004180:	45450513          	addi	a0,a0,1108 # 800095d0 <syscalls+0x170>
    80004184:	ffffc097          	auipc	ra,0xffffc
    80004188:	3a6080e7          	jalr	934(ra) # 8000052a <panic>

000000008000418c <iget>:
{
    8000418c:	7179                	addi	sp,sp,-48
    8000418e:	f406                	sd	ra,40(sp)
    80004190:	f022                	sd	s0,32(sp)
    80004192:	ec26                	sd	s1,24(sp)
    80004194:	e84a                	sd	s2,16(sp)
    80004196:	e44e                	sd	s3,8(sp)
    80004198:	e052                	sd	s4,0(sp)
    8000419a:	1800                	addi	s0,sp,48
    8000419c:	89aa                	mv	s3,a0
    8000419e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800041a0:	00039517          	auipc	a0,0x39
    800041a4:	c5850513          	addi	a0,a0,-936 # 8003cdf8 <itable>
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	a1a080e7          	jalr	-1510(ra) # 80000bc2 <acquire>
  empty = 0;
    800041b0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800041b2:	00039497          	auipc	s1,0x39
    800041b6:	c5e48493          	addi	s1,s1,-930 # 8003ce10 <itable+0x18>
    800041ba:	0003a697          	auipc	a3,0x3a
    800041be:	6e668693          	addi	a3,a3,1766 # 8003e8a0 <log>
    800041c2:	a039                	j	800041d0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800041c4:	02090b63          	beqz	s2,800041fa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800041c8:	08848493          	addi	s1,s1,136
    800041cc:	02d48a63          	beq	s1,a3,80004200 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800041d0:	449c                	lw	a5,8(s1)
    800041d2:	fef059e3          	blez	a5,800041c4 <iget+0x38>
    800041d6:	4098                	lw	a4,0(s1)
    800041d8:	ff3716e3          	bne	a4,s3,800041c4 <iget+0x38>
    800041dc:	40d8                	lw	a4,4(s1)
    800041de:	ff4713e3          	bne	a4,s4,800041c4 <iget+0x38>
      ip->ref++;
    800041e2:	2785                	addiw	a5,a5,1
    800041e4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800041e6:	00039517          	auipc	a0,0x39
    800041ea:	c1250513          	addi	a0,a0,-1006 # 8003cdf8 <itable>
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	a9a080e7          	jalr	-1382(ra) # 80000c88 <release>
      return ip;
    800041f6:	8926                	mv	s2,s1
    800041f8:	a03d                	j	80004226 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800041fa:	f7f9                	bnez	a5,800041c8 <iget+0x3c>
    800041fc:	8926                	mv	s2,s1
    800041fe:	b7e9                	j	800041c8 <iget+0x3c>
  if(empty == 0)
    80004200:	02090c63          	beqz	s2,80004238 <iget+0xac>
  ip->dev = dev;
    80004204:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004208:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000420c:	4785                	li	a5,1
    8000420e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004212:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004216:	00039517          	auipc	a0,0x39
    8000421a:	be250513          	addi	a0,a0,-1054 # 8003cdf8 <itable>
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	a6a080e7          	jalr	-1430(ra) # 80000c88 <release>
}
    80004226:	854a                	mv	a0,s2
    80004228:	70a2                	ld	ra,40(sp)
    8000422a:	7402                	ld	s0,32(sp)
    8000422c:	64e2                	ld	s1,24(sp)
    8000422e:	6942                	ld	s2,16(sp)
    80004230:	69a2                	ld	s3,8(sp)
    80004232:	6a02                	ld	s4,0(sp)
    80004234:	6145                	addi	sp,sp,48
    80004236:	8082                	ret
    panic("iget: no inodes");
    80004238:	00005517          	auipc	a0,0x5
    8000423c:	3b050513          	addi	a0,a0,944 # 800095e8 <syscalls+0x188>
    80004240:	ffffc097          	auipc	ra,0xffffc
    80004244:	2ea080e7          	jalr	746(ra) # 8000052a <panic>

0000000080004248 <fsinit>:
fsinit(int dev) {
    80004248:	7179                	addi	sp,sp,-48
    8000424a:	f406                	sd	ra,40(sp)
    8000424c:	f022                	sd	s0,32(sp)
    8000424e:	ec26                	sd	s1,24(sp)
    80004250:	e84a                	sd	s2,16(sp)
    80004252:	e44e                	sd	s3,8(sp)
    80004254:	1800                	addi	s0,sp,48
    80004256:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004258:	4585                	li	a1,1
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	a62080e7          	jalr	-1438(ra) # 80003cbc <bread>
    80004262:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004264:	00039997          	auipc	s3,0x39
    80004268:	b7498993          	addi	s3,s3,-1164 # 8003cdd8 <sb>
    8000426c:	02000613          	li	a2,32
    80004270:	05850593          	addi	a1,a0,88
    80004274:	854e                	mv	a0,s3
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	ac8080e7          	jalr	-1336(ra) # 80000d3e <memmove>
  brelse(bp);
    8000427e:	8526                	mv	a0,s1
    80004280:	00000097          	auipc	ra,0x0
    80004284:	b6c080e7          	jalr	-1172(ra) # 80003dec <brelse>
  if(sb.magic != FSMAGIC)
    80004288:	0009a703          	lw	a4,0(s3)
    8000428c:	102037b7          	lui	a5,0x10203
    80004290:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004294:	02f71263          	bne	a4,a5,800042b8 <fsinit+0x70>
  initlog(dev, &sb);
    80004298:	00039597          	auipc	a1,0x39
    8000429c:	b4058593          	addi	a1,a1,-1216 # 8003cdd8 <sb>
    800042a0:	854a                	mv	a0,s2
    800042a2:	00001097          	auipc	ra,0x1
    800042a6:	b4e080e7          	jalr	-1202(ra) # 80004df0 <initlog>
}
    800042aa:	70a2                	ld	ra,40(sp)
    800042ac:	7402                	ld	s0,32(sp)
    800042ae:	64e2                	ld	s1,24(sp)
    800042b0:	6942                	ld	s2,16(sp)
    800042b2:	69a2                	ld	s3,8(sp)
    800042b4:	6145                	addi	sp,sp,48
    800042b6:	8082                	ret
    panic("invalid file system");
    800042b8:	00005517          	auipc	a0,0x5
    800042bc:	34050513          	addi	a0,a0,832 # 800095f8 <syscalls+0x198>
    800042c0:	ffffc097          	auipc	ra,0xffffc
    800042c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>

00000000800042c8 <iinit>:
{
    800042c8:	7179                	addi	sp,sp,-48
    800042ca:	f406                	sd	ra,40(sp)
    800042cc:	f022                	sd	s0,32(sp)
    800042ce:	ec26                	sd	s1,24(sp)
    800042d0:	e84a                	sd	s2,16(sp)
    800042d2:	e44e                	sd	s3,8(sp)
    800042d4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800042d6:	00005597          	auipc	a1,0x5
    800042da:	33a58593          	addi	a1,a1,826 # 80009610 <syscalls+0x1b0>
    800042de:	00039517          	auipc	a0,0x39
    800042e2:	b1a50513          	addi	a0,a0,-1254 # 8003cdf8 <itable>
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	84c080e7          	jalr	-1972(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800042ee:	00039497          	auipc	s1,0x39
    800042f2:	b3248493          	addi	s1,s1,-1230 # 8003ce20 <itable+0x28>
    800042f6:	0003a997          	auipc	s3,0x3a
    800042fa:	5ba98993          	addi	s3,s3,1466 # 8003e8b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800042fe:	00005917          	auipc	s2,0x5
    80004302:	31a90913          	addi	s2,s2,794 # 80009618 <syscalls+0x1b8>
    80004306:	85ca                	mv	a1,s2
    80004308:	8526                	mv	a0,s1
    8000430a:	00001097          	auipc	ra,0x1
    8000430e:	e4a080e7          	jalr	-438(ra) # 80005154 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004312:	08848493          	addi	s1,s1,136
    80004316:	ff3498e3          	bne	s1,s3,80004306 <iinit+0x3e>
}
    8000431a:	70a2                	ld	ra,40(sp)
    8000431c:	7402                	ld	s0,32(sp)
    8000431e:	64e2                	ld	s1,24(sp)
    80004320:	6942                	ld	s2,16(sp)
    80004322:	69a2                	ld	s3,8(sp)
    80004324:	6145                	addi	sp,sp,48
    80004326:	8082                	ret

0000000080004328 <ialloc>:
{
    80004328:	715d                	addi	sp,sp,-80
    8000432a:	e486                	sd	ra,72(sp)
    8000432c:	e0a2                	sd	s0,64(sp)
    8000432e:	fc26                	sd	s1,56(sp)
    80004330:	f84a                	sd	s2,48(sp)
    80004332:	f44e                	sd	s3,40(sp)
    80004334:	f052                	sd	s4,32(sp)
    80004336:	ec56                	sd	s5,24(sp)
    80004338:	e85a                	sd	s6,16(sp)
    8000433a:	e45e                	sd	s7,8(sp)
    8000433c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000433e:	00039717          	auipc	a4,0x39
    80004342:	aa672703          	lw	a4,-1370(a4) # 8003cde4 <sb+0xc>
    80004346:	4785                	li	a5,1
    80004348:	04e7fa63          	bgeu	a5,a4,8000439c <ialloc+0x74>
    8000434c:	8aaa                	mv	s5,a0
    8000434e:	8bae                	mv	s7,a1
    80004350:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004352:	00039a17          	auipc	s4,0x39
    80004356:	a86a0a13          	addi	s4,s4,-1402 # 8003cdd8 <sb>
    8000435a:	00048b1b          	sext.w	s6,s1
    8000435e:	0044d793          	srli	a5,s1,0x4
    80004362:	018a2583          	lw	a1,24(s4)
    80004366:	9dbd                	addw	a1,a1,a5
    80004368:	8556                	mv	a0,s5
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	952080e7          	jalr	-1710(ra) # 80003cbc <bread>
    80004372:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004374:	05850993          	addi	s3,a0,88
    80004378:	00f4f793          	andi	a5,s1,15
    8000437c:	079a                	slli	a5,a5,0x6
    8000437e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004380:	00099783          	lh	a5,0(s3)
    80004384:	c785                	beqz	a5,800043ac <ialloc+0x84>
    brelse(bp);
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	a66080e7          	jalr	-1434(ra) # 80003dec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000438e:	0485                	addi	s1,s1,1
    80004390:	00ca2703          	lw	a4,12(s4)
    80004394:	0004879b          	sext.w	a5,s1
    80004398:	fce7e1e3          	bltu	a5,a4,8000435a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000439c:	00005517          	auipc	a0,0x5
    800043a0:	28450513          	addi	a0,a0,644 # 80009620 <syscalls+0x1c0>
    800043a4:	ffffc097          	auipc	ra,0xffffc
    800043a8:	186080e7          	jalr	390(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800043ac:	04000613          	li	a2,64
    800043b0:	4581                	li	a1,0
    800043b2:	854e                	mv	a0,s3
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	92e080e7          	jalr	-1746(ra) # 80000ce2 <memset>
      dip->type = type;
    800043bc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800043c0:	854a                	mv	a0,s2
    800043c2:	00001097          	auipc	ra,0x1
    800043c6:	cac080e7          	jalr	-852(ra) # 8000506e <log_write>
      brelse(bp);
    800043ca:	854a                	mv	a0,s2
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	a20080e7          	jalr	-1504(ra) # 80003dec <brelse>
      return iget(dev, inum);
    800043d4:	85da                	mv	a1,s6
    800043d6:	8556                	mv	a0,s5
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	db4080e7          	jalr	-588(ra) # 8000418c <iget>
}
    800043e0:	60a6                	ld	ra,72(sp)
    800043e2:	6406                	ld	s0,64(sp)
    800043e4:	74e2                	ld	s1,56(sp)
    800043e6:	7942                	ld	s2,48(sp)
    800043e8:	79a2                	ld	s3,40(sp)
    800043ea:	7a02                	ld	s4,32(sp)
    800043ec:	6ae2                	ld	s5,24(sp)
    800043ee:	6b42                	ld	s6,16(sp)
    800043f0:	6ba2                	ld	s7,8(sp)
    800043f2:	6161                	addi	sp,sp,80
    800043f4:	8082                	ret

00000000800043f6 <iupdate>:
{
    800043f6:	1101                	addi	sp,sp,-32
    800043f8:	ec06                	sd	ra,24(sp)
    800043fa:	e822                	sd	s0,16(sp)
    800043fc:	e426                	sd	s1,8(sp)
    800043fe:	e04a                	sd	s2,0(sp)
    80004400:	1000                	addi	s0,sp,32
    80004402:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004404:	415c                	lw	a5,4(a0)
    80004406:	0047d79b          	srliw	a5,a5,0x4
    8000440a:	00039597          	auipc	a1,0x39
    8000440e:	9e65a583          	lw	a1,-1562(a1) # 8003cdf0 <sb+0x18>
    80004412:	9dbd                	addw	a1,a1,a5
    80004414:	4108                	lw	a0,0(a0)
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	8a6080e7          	jalr	-1882(ra) # 80003cbc <bread>
    8000441e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004420:	05850793          	addi	a5,a0,88
    80004424:	40c8                	lw	a0,4(s1)
    80004426:	893d                	andi	a0,a0,15
    80004428:	051a                	slli	a0,a0,0x6
    8000442a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000442c:	04449703          	lh	a4,68(s1)
    80004430:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004434:	04649703          	lh	a4,70(s1)
    80004438:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000443c:	04849703          	lh	a4,72(s1)
    80004440:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004444:	04a49703          	lh	a4,74(s1)
    80004448:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000444c:	44f8                	lw	a4,76(s1)
    8000444e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004450:	03400613          	li	a2,52
    80004454:	05048593          	addi	a1,s1,80
    80004458:	0531                	addi	a0,a0,12
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	8e4080e7          	jalr	-1820(ra) # 80000d3e <memmove>
  log_write(bp);
    80004462:	854a                	mv	a0,s2
    80004464:	00001097          	auipc	ra,0x1
    80004468:	c0a080e7          	jalr	-1014(ra) # 8000506e <log_write>
  brelse(bp);
    8000446c:	854a                	mv	a0,s2
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	97e080e7          	jalr	-1666(ra) # 80003dec <brelse>
}
    80004476:	60e2                	ld	ra,24(sp)
    80004478:	6442                	ld	s0,16(sp)
    8000447a:	64a2                	ld	s1,8(sp)
    8000447c:	6902                	ld	s2,0(sp)
    8000447e:	6105                	addi	sp,sp,32
    80004480:	8082                	ret

0000000080004482 <idup>:
{
    80004482:	1101                	addi	sp,sp,-32
    80004484:	ec06                	sd	ra,24(sp)
    80004486:	e822                	sd	s0,16(sp)
    80004488:	e426                	sd	s1,8(sp)
    8000448a:	1000                	addi	s0,sp,32
    8000448c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000448e:	00039517          	auipc	a0,0x39
    80004492:	96a50513          	addi	a0,a0,-1686 # 8003cdf8 <itable>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	72c080e7          	jalr	1836(ra) # 80000bc2 <acquire>
  ip->ref++;
    8000449e:	449c                	lw	a5,8(s1)
    800044a0:	2785                	addiw	a5,a5,1
    800044a2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044a4:	00039517          	auipc	a0,0x39
    800044a8:	95450513          	addi	a0,a0,-1708 # 8003cdf8 <itable>
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	7dc080e7          	jalr	2012(ra) # 80000c88 <release>
}
    800044b4:	8526                	mv	a0,s1
    800044b6:	60e2                	ld	ra,24(sp)
    800044b8:	6442                	ld	s0,16(sp)
    800044ba:	64a2                	ld	s1,8(sp)
    800044bc:	6105                	addi	sp,sp,32
    800044be:	8082                	ret

00000000800044c0 <ilock>:
{
    800044c0:	1101                	addi	sp,sp,-32
    800044c2:	ec06                	sd	ra,24(sp)
    800044c4:	e822                	sd	s0,16(sp)
    800044c6:	e426                	sd	s1,8(sp)
    800044c8:	e04a                	sd	s2,0(sp)
    800044ca:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800044cc:	c115                	beqz	a0,800044f0 <ilock+0x30>
    800044ce:	84aa                	mv	s1,a0
    800044d0:	451c                	lw	a5,8(a0)
    800044d2:	00f05f63          	blez	a5,800044f0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800044d6:	0541                	addi	a0,a0,16
    800044d8:	00001097          	auipc	ra,0x1
    800044dc:	cb6080e7          	jalr	-842(ra) # 8000518e <acquiresleep>
  if(ip->valid == 0){
    800044e0:	40bc                	lw	a5,64(s1)
    800044e2:	cf99                	beqz	a5,80004500 <ilock+0x40>
}
    800044e4:	60e2                	ld	ra,24(sp)
    800044e6:	6442                	ld	s0,16(sp)
    800044e8:	64a2                	ld	s1,8(sp)
    800044ea:	6902                	ld	s2,0(sp)
    800044ec:	6105                	addi	sp,sp,32
    800044ee:	8082                	ret
    panic("ilock");
    800044f0:	00005517          	auipc	a0,0x5
    800044f4:	14850513          	addi	a0,a0,328 # 80009638 <syscalls+0x1d8>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	032080e7          	jalr	50(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004500:	40dc                	lw	a5,4(s1)
    80004502:	0047d79b          	srliw	a5,a5,0x4
    80004506:	00039597          	auipc	a1,0x39
    8000450a:	8ea5a583          	lw	a1,-1814(a1) # 8003cdf0 <sb+0x18>
    8000450e:	9dbd                	addw	a1,a1,a5
    80004510:	4088                	lw	a0,0(s1)
    80004512:	fffff097          	auipc	ra,0xfffff
    80004516:	7aa080e7          	jalr	1962(ra) # 80003cbc <bread>
    8000451a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000451c:	05850593          	addi	a1,a0,88
    80004520:	40dc                	lw	a5,4(s1)
    80004522:	8bbd                	andi	a5,a5,15
    80004524:	079a                	slli	a5,a5,0x6
    80004526:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004528:	00059783          	lh	a5,0(a1)
    8000452c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004530:	00259783          	lh	a5,2(a1)
    80004534:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004538:	00459783          	lh	a5,4(a1)
    8000453c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004540:	00659783          	lh	a5,6(a1)
    80004544:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004548:	459c                	lw	a5,8(a1)
    8000454a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000454c:	03400613          	li	a2,52
    80004550:	05b1                	addi	a1,a1,12
    80004552:	05048513          	addi	a0,s1,80
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	7e8080e7          	jalr	2024(ra) # 80000d3e <memmove>
    brelse(bp);
    8000455e:	854a                	mv	a0,s2
    80004560:	00000097          	auipc	ra,0x0
    80004564:	88c080e7          	jalr	-1908(ra) # 80003dec <brelse>
    ip->valid = 1;
    80004568:	4785                	li	a5,1
    8000456a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000456c:	04449783          	lh	a5,68(s1)
    80004570:	fbb5                	bnez	a5,800044e4 <ilock+0x24>
      panic("ilock: no type");
    80004572:	00005517          	auipc	a0,0x5
    80004576:	0ce50513          	addi	a0,a0,206 # 80009640 <syscalls+0x1e0>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	fb0080e7          	jalr	-80(ra) # 8000052a <panic>

0000000080004582 <iunlock>:
{
    80004582:	1101                	addi	sp,sp,-32
    80004584:	ec06                	sd	ra,24(sp)
    80004586:	e822                	sd	s0,16(sp)
    80004588:	e426                	sd	s1,8(sp)
    8000458a:	e04a                	sd	s2,0(sp)
    8000458c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000458e:	c905                	beqz	a0,800045be <iunlock+0x3c>
    80004590:	84aa                	mv	s1,a0
    80004592:	01050913          	addi	s2,a0,16
    80004596:	854a                	mv	a0,s2
    80004598:	00001097          	auipc	ra,0x1
    8000459c:	c90080e7          	jalr	-880(ra) # 80005228 <holdingsleep>
    800045a0:	cd19                	beqz	a0,800045be <iunlock+0x3c>
    800045a2:	449c                	lw	a5,8(s1)
    800045a4:	00f05d63          	blez	a5,800045be <iunlock+0x3c>
  releasesleep(&ip->lock);
    800045a8:	854a                	mv	a0,s2
    800045aa:	00001097          	auipc	ra,0x1
    800045ae:	c3a080e7          	jalr	-966(ra) # 800051e4 <releasesleep>
}
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	64a2                	ld	s1,8(sp)
    800045b8:	6902                	ld	s2,0(sp)
    800045ba:	6105                	addi	sp,sp,32
    800045bc:	8082                	ret
    panic("iunlock");
    800045be:	00005517          	auipc	a0,0x5
    800045c2:	09250513          	addi	a0,a0,146 # 80009650 <syscalls+0x1f0>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	f64080e7          	jalr	-156(ra) # 8000052a <panic>

00000000800045ce <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800045ce:	7179                	addi	sp,sp,-48
    800045d0:	f406                	sd	ra,40(sp)
    800045d2:	f022                	sd	s0,32(sp)
    800045d4:	ec26                	sd	s1,24(sp)
    800045d6:	e84a                	sd	s2,16(sp)
    800045d8:	e44e                	sd	s3,8(sp)
    800045da:	e052                	sd	s4,0(sp)
    800045dc:	1800                	addi	s0,sp,48
    800045de:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800045e0:	05050493          	addi	s1,a0,80
    800045e4:	08050913          	addi	s2,a0,128
    800045e8:	a021                	j	800045f0 <itrunc+0x22>
    800045ea:	0491                	addi	s1,s1,4
    800045ec:	01248d63          	beq	s1,s2,80004606 <itrunc+0x38>
    if(ip->addrs[i]){
    800045f0:	408c                	lw	a1,0(s1)
    800045f2:	dde5                	beqz	a1,800045ea <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800045f4:	0009a503          	lw	a0,0(s3)
    800045f8:	00000097          	auipc	ra,0x0
    800045fc:	90a080e7          	jalr	-1782(ra) # 80003f02 <bfree>
      ip->addrs[i] = 0;
    80004600:	0004a023          	sw	zero,0(s1)
    80004604:	b7dd                	j	800045ea <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004606:	0809a583          	lw	a1,128(s3)
    8000460a:	e185                	bnez	a1,8000462a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000460c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004610:	854e                	mv	a0,s3
    80004612:	00000097          	auipc	ra,0x0
    80004616:	de4080e7          	jalr	-540(ra) # 800043f6 <iupdate>
}
    8000461a:	70a2                	ld	ra,40(sp)
    8000461c:	7402                	ld	s0,32(sp)
    8000461e:	64e2                	ld	s1,24(sp)
    80004620:	6942                	ld	s2,16(sp)
    80004622:	69a2                	ld	s3,8(sp)
    80004624:	6a02                	ld	s4,0(sp)
    80004626:	6145                	addi	sp,sp,48
    80004628:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000462a:	0009a503          	lw	a0,0(s3)
    8000462e:	fffff097          	auipc	ra,0xfffff
    80004632:	68e080e7          	jalr	1678(ra) # 80003cbc <bread>
    80004636:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004638:	05850493          	addi	s1,a0,88
    8000463c:	45850913          	addi	s2,a0,1112
    80004640:	a021                	j	80004648 <itrunc+0x7a>
    80004642:	0491                	addi	s1,s1,4
    80004644:	01248b63          	beq	s1,s2,8000465a <itrunc+0x8c>
      if(a[j])
    80004648:	408c                	lw	a1,0(s1)
    8000464a:	dde5                	beqz	a1,80004642 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000464c:	0009a503          	lw	a0,0(s3)
    80004650:	00000097          	auipc	ra,0x0
    80004654:	8b2080e7          	jalr	-1870(ra) # 80003f02 <bfree>
    80004658:	b7ed                	j	80004642 <itrunc+0x74>
    brelse(bp);
    8000465a:	8552                	mv	a0,s4
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	790080e7          	jalr	1936(ra) # 80003dec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004664:	0809a583          	lw	a1,128(s3)
    80004668:	0009a503          	lw	a0,0(s3)
    8000466c:	00000097          	auipc	ra,0x0
    80004670:	896080e7          	jalr	-1898(ra) # 80003f02 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004674:	0809a023          	sw	zero,128(s3)
    80004678:	bf51                	j	8000460c <itrunc+0x3e>

000000008000467a <iput>:
{
    8000467a:	1101                	addi	sp,sp,-32
    8000467c:	ec06                	sd	ra,24(sp)
    8000467e:	e822                	sd	s0,16(sp)
    80004680:	e426                	sd	s1,8(sp)
    80004682:	e04a                	sd	s2,0(sp)
    80004684:	1000                	addi	s0,sp,32
    80004686:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004688:	00038517          	auipc	a0,0x38
    8000468c:	77050513          	addi	a0,a0,1904 # 8003cdf8 <itable>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	532080e7          	jalr	1330(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004698:	4498                	lw	a4,8(s1)
    8000469a:	4785                	li	a5,1
    8000469c:	02f70363          	beq	a4,a5,800046c2 <iput+0x48>
  ip->ref--;
    800046a0:	449c                	lw	a5,8(s1)
    800046a2:	37fd                	addiw	a5,a5,-1
    800046a4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800046a6:	00038517          	auipc	a0,0x38
    800046aa:	75250513          	addi	a0,a0,1874 # 8003cdf8 <itable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	5da080e7          	jalr	1498(ra) # 80000c88 <release>
}
    800046b6:	60e2                	ld	ra,24(sp)
    800046b8:	6442                	ld	s0,16(sp)
    800046ba:	64a2                	ld	s1,8(sp)
    800046bc:	6902                	ld	s2,0(sp)
    800046be:	6105                	addi	sp,sp,32
    800046c0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800046c2:	40bc                	lw	a5,64(s1)
    800046c4:	dff1                	beqz	a5,800046a0 <iput+0x26>
    800046c6:	04a49783          	lh	a5,74(s1)
    800046ca:	fbf9                	bnez	a5,800046a0 <iput+0x26>
    acquiresleep(&ip->lock);
    800046cc:	01048913          	addi	s2,s1,16
    800046d0:	854a                	mv	a0,s2
    800046d2:	00001097          	auipc	ra,0x1
    800046d6:	abc080e7          	jalr	-1348(ra) # 8000518e <acquiresleep>
    release(&itable.lock);
    800046da:	00038517          	auipc	a0,0x38
    800046de:	71e50513          	addi	a0,a0,1822 # 8003cdf8 <itable>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	5a6080e7          	jalr	1446(ra) # 80000c88 <release>
    itrunc(ip);
    800046ea:	8526                	mv	a0,s1
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	ee2080e7          	jalr	-286(ra) # 800045ce <itrunc>
    ip->type = 0;
    800046f4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800046f8:	8526                	mv	a0,s1
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	cfc080e7          	jalr	-772(ra) # 800043f6 <iupdate>
    ip->valid = 0;
    80004702:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004706:	854a                	mv	a0,s2
    80004708:	00001097          	auipc	ra,0x1
    8000470c:	adc080e7          	jalr	-1316(ra) # 800051e4 <releasesleep>
    acquire(&itable.lock);
    80004710:	00038517          	auipc	a0,0x38
    80004714:	6e850513          	addi	a0,a0,1768 # 8003cdf8 <itable>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	4aa080e7          	jalr	1194(ra) # 80000bc2 <acquire>
    80004720:	b741                	j	800046a0 <iput+0x26>

0000000080004722 <iunlockput>:
{
    80004722:	1101                	addi	sp,sp,-32
    80004724:	ec06                	sd	ra,24(sp)
    80004726:	e822                	sd	s0,16(sp)
    80004728:	e426                	sd	s1,8(sp)
    8000472a:	1000                	addi	s0,sp,32
    8000472c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	e54080e7          	jalr	-428(ra) # 80004582 <iunlock>
  iput(ip);
    80004736:	8526                	mv	a0,s1
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	f42080e7          	jalr	-190(ra) # 8000467a <iput>
}
    80004740:	60e2                	ld	ra,24(sp)
    80004742:	6442                	ld	s0,16(sp)
    80004744:	64a2                	ld	s1,8(sp)
    80004746:	6105                	addi	sp,sp,32
    80004748:	8082                	ret

000000008000474a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000474a:	1141                	addi	sp,sp,-16
    8000474c:	e422                	sd	s0,8(sp)
    8000474e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004750:	411c                	lw	a5,0(a0)
    80004752:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004754:	415c                	lw	a5,4(a0)
    80004756:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004758:	04451783          	lh	a5,68(a0)
    8000475c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004760:	04a51783          	lh	a5,74(a0)
    80004764:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004768:	04c56783          	lwu	a5,76(a0)
    8000476c:	e99c                	sd	a5,16(a1)
}
    8000476e:	6422                	ld	s0,8(sp)
    80004770:	0141                	addi	sp,sp,16
    80004772:	8082                	ret

0000000080004774 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004774:	457c                	lw	a5,76(a0)
    80004776:	0ed7e963          	bltu	a5,a3,80004868 <readi+0xf4>
{
    8000477a:	7159                	addi	sp,sp,-112
    8000477c:	f486                	sd	ra,104(sp)
    8000477e:	f0a2                	sd	s0,96(sp)
    80004780:	eca6                	sd	s1,88(sp)
    80004782:	e8ca                	sd	s2,80(sp)
    80004784:	e4ce                	sd	s3,72(sp)
    80004786:	e0d2                	sd	s4,64(sp)
    80004788:	fc56                	sd	s5,56(sp)
    8000478a:	f85a                	sd	s6,48(sp)
    8000478c:	f45e                	sd	s7,40(sp)
    8000478e:	f062                	sd	s8,32(sp)
    80004790:	ec66                	sd	s9,24(sp)
    80004792:	e86a                	sd	s10,16(sp)
    80004794:	e46e                	sd	s11,8(sp)
    80004796:	1880                	addi	s0,sp,112
    80004798:	8baa                	mv	s7,a0
    8000479a:	8c2e                	mv	s8,a1
    8000479c:	8ab2                	mv	s5,a2
    8000479e:	84b6                	mv	s1,a3
    800047a0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800047a2:	9f35                	addw	a4,a4,a3
    return 0;
    800047a4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800047a6:	0ad76063          	bltu	a4,a3,80004846 <readi+0xd2>
  if(off + n > ip->size)
    800047aa:	00e7f463          	bgeu	a5,a4,800047b2 <readi+0x3e>
    n = ip->size - off;
    800047ae:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800047b2:	0a0b0963          	beqz	s6,80004864 <readi+0xf0>
    800047b6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800047b8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800047bc:	5cfd                	li	s9,-1
    800047be:	a82d                	j	800047f8 <readi+0x84>
    800047c0:	020a1d93          	slli	s11,s4,0x20
    800047c4:	020ddd93          	srli	s11,s11,0x20
    800047c8:	05890793          	addi	a5,s2,88
    800047cc:	86ee                	mv	a3,s11
    800047ce:	963e                	add	a2,a2,a5
    800047d0:	85d6                	mv	a1,s5
    800047d2:	8562                	mv	a0,s8
    800047d4:	ffffe097          	auipc	ra,0xffffe
    800047d8:	208080e7          	jalr	520(ra) # 800029dc <either_copyout>
    800047dc:	05950d63          	beq	a0,s9,80004836 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800047e0:	854a                	mv	a0,s2
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	60a080e7          	jalr	1546(ra) # 80003dec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800047ea:	013a09bb          	addw	s3,s4,s3
    800047ee:	009a04bb          	addw	s1,s4,s1
    800047f2:	9aee                	add	s5,s5,s11
    800047f4:	0569f763          	bgeu	s3,s6,80004842 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800047f8:	000ba903          	lw	s2,0(s7)
    800047fc:	00a4d59b          	srliw	a1,s1,0xa
    80004800:	855e                	mv	a0,s7
    80004802:	00000097          	auipc	ra,0x0
    80004806:	8ae080e7          	jalr	-1874(ra) # 800040b0 <bmap>
    8000480a:	0005059b          	sext.w	a1,a0
    8000480e:	854a                	mv	a0,s2
    80004810:	fffff097          	auipc	ra,0xfffff
    80004814:	4ac080e7          	jalr	1196(ra) # 80003cbc <bread>
    80004818:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000481a:	3ff4f613          	andi	a2,s1,1023
    8000481e:	40cd07bb          	subw	a5,s10,a2
    80004822:	413b073b          	subw	a4,s6,s3
    80004826:	8a3e                	mv	s4,a5
    80004828:	2781                	sext.w	a5,a5
    8000482a:	0007069b          	sext.w	a3,a4
    8000482e:	f8f6f9e3          	bgeu	a3,a5,800047c0 <readi+0x4c>
    80004832:	8a3a                	mv	s4,a4
    80004834:	b771                	j	800047c0 <readi+0x4c>
      brelse(bp);
    80004836:	854a                	mv	a0,s2
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	5b4080e7          	jalr	1460(ra) # 80003dec <brelse>
      tot = -1;
    80004840:	59fd                	li	s3,-1
  }
  return tot;
    80004842:	0009851b          	sext.w	a0,s3
}
    80004846:	70a6                	ld	ra,104(sp)
    80004848:	7406                	ld	s0,96(sp)
    8000484a:	64e6                	ld	s1,88(sp)
    8000484c:	6946                	ld	s2,80(sp)
    8000484e:	69a6                	ld	s3,72(sp)
    80004850:	6a06                	ld	s4,64(sp)
    80004852:	7ae2                	ld	s5,56(sp)
    80004854:	7b42                	ld	s6,48(sp)
    80004856:	7ba2                	ld	s7,40(sp)
    80004858:	7c02                	ld	s8,32(sp)
    8000485a:	6ce2                	ld	s9,24(sp)
    8000485c:	6d42                	ld	s10,16(sp)
    8000485e:	6da2                	ld	s11,8(sp)
    80004860:	6165                	addi	sp,sp,112
    80004862:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004864:	89da                	mv	s3,s6
    80004866:	bff1                	j	80004842 <readi+0xce>
    return 0;
    80004868:	4501                	li	a0,0
}
    8000486a:	8082                	ret

000000008000486c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000486c:	457c                	lw	a5,76(a0)
    8000486e:	10d7e863          	bltu	a5,a3,8000497e <writei+0x112>
{
    80004872:	7159                	addi	sp,sp,-112
    80004874:	f486                	sd	ra,104(sp)
    80004876:	f0a2                	sd	s0,96(sp)
    80004878:	eca6                	sd	s1,88(sp)
    8000487a:	e8ca                	sd	s2,80(sp)
    8000487c:	e4ce                	sd	s3,72(sp)
    8000487e:	e0d2                	sd	s4,64(sp)
    80004880:	fc56                	sd	s5,56(sp)
    80004882:	f85a                	sd	s6,48(sp)
    80004884:	f45e                	sd	s7,40(sp)
    80004886:	f062                	sd	s8,32(sp)
    80004888:	ec66                	sd	s9,24(sp)
    8000488a:	e86a                	sd	s10,16(sp)
    8000488c:	e46e                	sd	s11,8(sp)
    8000488e:	1880                	addi	s0,sp,112
    80004890:	8b2a                	mv	s6,a0
    80004892:	8c2e                	mv	s8,a1
    80004894:	8ab2                	mv	s5,a2
    80004896:	8936                	mv	s2,a3
    80004898:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000489a:	00e687bb          	addw	a5,a3,a4
    8000489e:	0ed7e263          	bltu	a5,a3,80004982 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800048a2:	00043737          	lui	a4,0x43
    800048a6:	0ef76063          	bltu	a4,a5,80004986 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800048aa:	0c0b8863          	beqz	s7,8000497a <writei+0x10e>
    800048ae:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800048b0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800048b4:	5cfd                	li	s9,-1
    800048b6:	a091                	j	800048fa <writei+0x8e>
    800048b8:	02099d93          	slli	s11,s3,0x20
    800048bc:	020ddd93          	srli	s11,s11,0x20
    800048c0:	05848793          	addi	a5,s1,88
    800048c4:	86ee                	mv	a3,s11
    800048c6:	8656                	mv	a2,s5
    800048c8:	85e2                	mv	a1,s8
    800048ca:	953e                	add	a0,a0,a5
    800048cc:	ffffe097          	auipc	ra,0xffffe
    800048d0:	168080e7          	jalr	360(ra) # 80002a34 <either_copyin>
    800048d4:	07950263          	beq	a0,s9,80004938 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800048d8:	8526                	mv	a0,s1
    800048da:	00000097          	auipc	ra,0x0
    800048de:	794080e7          	jalr	1940(ra) # 8000506e <log_write>
    brelse(bp);
    800048e2:	8526                	mv	a0,s1
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	508080e7          	jalr	1288(ra) # 80003dec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800048ec:	01498a3b          	addw	s4,s3,s4
    800048f0:	0129893b          	addw	s2,s3,s2
    800048f4:	9aee                	add	s5,s5,s11
    800048f6:	057a7663          	bgeu	s4,s7,80004942 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800048fa:	000b2483          	lw	s1,0(s6)
    800048fe:	00a9559b          	srliw	a1,s2,0xa
    80004902:	855a                	mv	a0,s6
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	7ac080e7          	jalr	1964(ra) # 800040b0 <bmap>
    8000490c:	0005059b          	sext.w	a1,a0
    80004910:	8526                	mv	a0,s1
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	3aa080e7          	jalr	938(ra) # 80003cbc <bread>
    8000491a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000491c:	3ff97513          	andi	a0,s2,1023
    80004920:	40ad07bb          	subw	a5,s10,a0
    80004924:	414b873b          	subw	a4,s7,s4
    80004928:	89be                	mv	s3,a5
    8000492a:	2781                	sext.w	a5,a5
    8000492c:	0007069b          	sext.w	a3,a4
    80004930:	f8f6f4e3          	bgeu	a3,a5,800048b8 <writei+0x4c>
    80004934:	89ba                	mv	s3,a4
    80004936:	b749                	j	800048b8 <writei+0x4c>
      brelse(bp);
    80004938:	8526                	mv	a0,s1
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	4b2080e7          	jalr	1202(ra) # 80003dec <brelse>
  }

  if(off > ip->size)
    80004942:	04cb2783          	lw	a5,76(s6)
    80004946:	0127f463          	bgeu	a5,s2,8000494e <writei+0xe2>
    ip->size = off;
    8000494a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000494e:	855a                	mv	a0,s6
    80004950:	00000097          	auipc	ra,0x0
    80004954:	aa6080e7          	jalr	-1370(ra) # 800043f6 <iupdate>

  return tot;
    80004958:	000a051b          	sext.w	a0,s4
}
    8000495c:	70a6                	ld	ra,104(sp)
    8000495e:	7406                	ld	s0,96(sp)
    80004960:	64e6                	ld	s1,88(sp)
    80004962:	6946                	ld	s2,80(sp)
    80004964:	69a6                	ld	s3,72(sp)
    80004966:	6a06                	ld	s4,64(sp)
    80004968:	7ae2                	ld	s5,56(sp)
    8000496a:	7b42                	ld	s6,48(sp)
    8000496c:	7ba2                	ld	s7,40(sp)
    8000496e:	7c02                	ld	s8,32(sp)
    80004970:	6ce2                	ld	s9,24(sp)
    80004972:	6d42                	ld	s10,16(sp)
    80004974:	6da2                	ld	s11,8(sp)
    80004976:	6165                	addi	sp,sp,112
    80004978:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000497a:	8a5e                	mv	s4,s7
    8000497c:	bfc9                	j	8000494e <writei+0xe2>
    return -1;
    8000497e:	557d                	li	a0,-1
}
    80004980:	8082                	ret
    return -1;
    80004982:	557d                	li	a0,-1
    80004984:	bfe1                	j	8000495c <writei+0xf0>
    return -1;
    80004986:	557d                	li	a0,-1
    80004988:	bfd1                	j	8000495c <writei+0xf0>

000000008000498a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000498a:	1141                	addi	sp,sp,-16
    8000498c:	e406                	sd	ra,8(sp)
    8000498e:	e022                	sd	s0,0(sp)
    80004990:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004992:	4639                	li	a2,14
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	426080e7          	jalr	1062(ra) # 80000dba <strncmp>
}
    8000499c:	60a2                	ld	ra,8(sp)
    8000499e:	6402                	ld	s0,0(sp)
    800049a0:	0141                	addi	sp,sp,16
    800049a2:	8082                	ret

00000000800049a4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800049a4:	7139                	addi	sp,sp,-64
    800049a6:	fc06                	sd	ra,56(sp)
    800049a8:	f822                	sd	s0,48(sp)
    800049aa:	f426                	sd	s1,40(sp)
    800049ac:	f04a                	sd	s2,32(sp)
    800049ae:	ec4e                	sd	s3,24(sp)
    800049b0:	e852                	sd	s4,16(sp)
    800049b2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800049b4:	04451703          	lh	a4,68(a0)
    800049b8:	4785                	li	a5,1
    800049ba:	00f71a63          	bne	a4,a5,800049ce <dirlookup+0x2a>
    800049be:	892a                	mv	s2,a0
    800049c0:	89ae                	mv	s3,a1
    800049c2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800049c4:	457c                	lw	a5,76(a0)
    800049c6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800049c8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049ca:	e79d                	bnez	a5,800049f8 <dirlookup+0x54>
    800049cc:	a8a5                	j	80004a44 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800049ce:	00005517          	auipc	a0,0x5
    800049d2:	c8a50513          	addi	a0,a0,-886 # 80009658 <syscalls+0x1f8>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	b54080e7          	jalr	-1196(ra) # 8000052a <panic>
      panic("dirlookup read");
    800049de:	00005517          	auipc	a0,0x5
    800049e2:	c9250513          	addi	a0,a0,-878 # 80009670 <syscalls+0x210>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	b44080e7          	jalr	-1212(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049ee:	24c1                	addiw	s1,s1,16
    800049f0:	04c92783          	lw	a5,76(s2)
    800049f4:	04f4f763          	bgeu	s1,a5,80004a42 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049f8:	4741                	li	a4,16
    800049fa:	86a6                	mv	a3,s1
    800049fc:	fc040613          	addi	a2,s0,-64
    80004a00:	4581                	li	a1,0
    80004a02:	854a                	mv	a0,s2
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	d70080e7          	jalr	-656(ra) # 80004774 <readi>
    80004a0c:	47c1                	li	a5,16
    80004a0e:	fcf518e3          	bne	a0,a5,800049de <dirlookup+0x3a>
    if(de.inum == 0)
    80004a12:	fc045783          	lhu	a5,-64(s0)
    80004a16:	dfe1                	beqz	a5,800049ee <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004a18:	fc240593          	addi	a1,s0,-62
    80004a1c:	854e                	mv	a0,s3
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	f6c080e7          	jalr	-148(ra) # 8000498a <namecmp>
    80004a26:	f561                	bnez	a0,800049ee <dirlookup+0x4a>
      if(poff)
    80004a28:	000a0463          	beqz	s4,80004a30 <dirlookup+0x8c>
        *poff = off;
    80004a2c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004a30:	fc045583          	lhu	a1,-64(s0)
    80004a34:	00092503          	lw	a0,0(s2)
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	754080e7          	jalr	1876(ra) # 8000418c <iget>
    80004a40:	a011                	j	80004a44 <dirlookup+0xa0>
  return 0;
    80004a42:	4501                	li	a0,0
}
    80004a44:	70e2                	ld	ra,56(sp)
    80004a46:	7442                	ld	s0,48(sp)
    80004a48:	74a2                	ld	s1,40(sp)
    80004a4a:	7902                	ld	s2,32(sp)
    80004a4c:	69e2                	ld	s3,24(sp)
    80004a4e:	6a42                	ld	s4,16(sp)
    80004a50:	6121                	addi	sp,sp,64
    80004a52:	8082                	ret

0000000080004a54 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004a54:	711d                	addi	sp,sp,-96
    80004a56:	ec86                	sd	ra,88(sp)
    80004a58:	e8a2                	sd	s0,80(sp)
    80004a5a:	e4a6                	sd	s1,72(sp)
    80004a5c:	e0ca                	sd	s2,64(sp)
    80004a5e:	fc4e                	sd	s3,56(sp)
    80004a60:	f852                	sd	s4,48(sp)
    80004a62:	f456                	sd	s5,40(sp)
    80004a64:	f05a                	sd	s6,32(sp)
    80004a66:	ec5e                	sd	s7,24(sp)
    80004a68:	e862                	sd	s8,16(sp)
    80004a6a:	e466                	sd	s9,8(sp)
    80004a6c:	1080                	addi	s0,sp,96
    80004a6e:	84aa                	mv	s1,a0
    80004a70:	8aae                	mv	s5,a1
    80004a72:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004a74:	00054703          	lbu	a4,0(a0)
    80004a78:	02f00793          	li	a5,47
    80004a7c:	02f70363          	beq	a4,a5,80004aa2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004a80:	ffffd097          	auipc	ra,0xffffd
    80004a84:	fb2080e7          	jalr	-78(ra) # 80001a32 <myproc>
    80004a88:	26053503          	ld	a0,608(a0)
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	9f6080e7          	jalr	-1546(ra) # 80004482 <idup>
    80004a94:	89aa                	mv	s3,a0
  while(*path == '/')
    80004a96:	02f00913          	li	s2,47
  len = path - s;
    80004a9a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004a9c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004a9e:	4b85                	li	s7,1
    80004aa0:	a865                	j	80004b58 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004aa2:	4585                	li	a1,1
    80004aa4:	4505                	li	a0,1
    80004aa6:	fffff097          	auipc	ra,0xfffff
    80004aaa:	6e6080e7          	jalr	1766(ra) # 8000418c <iget>
    80004aae:	89aa                	mv	s3,a0
    80004ab0:	b7dd                	j	80004a96 <namex+0x42>
      iunlockput(ip);
    80004ab2:	854e                	mv	a0,s3
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	c6e080e7          	jalr	-914(ra) # 80004722 <iunlockput>
      return 0;
    80004abc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004abe:	854e                	mv	a0,s3
    80004ac0:	60e6                	ld	ra,88(sp)
    80004ac2:	6446                	ld	s0,80(sp)
    80004ac4:	64a6                	ld	s1,72(sp)
    80004ac6:	6906                	ld	s2,64(sp)
    80004ac8:	79e2                	ld	s3,56(sp)
    80004aca:	7a42                	ld	s4,48(sp)
    80004acc:	7aa2                	ld	s5,40(sp)
    80004ace:	7b02                	ld	s6,32(sp)
    80004ad0:	6be2                	ld	s7,24(sp)
    80004ad2:	6c42                	ld	s8,16(sp)
    80004ad4:	6ca2                	ld	s9,8(sp)
    80004ad6:	6125                	addi	sp,sp,96
    80004ad8:	8082                	ret
      iunlock(ip);
    80004ada:	854e                	mv	a0,s3
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	aa6080e7          	jalr	-1370(ra) # 80004582 <iunlock>
      return ip;
    80004ae4:	bfe9                	j	80004abe <namex+0x6a>
      iunlockput(ip);
    80004ae6:	854e                	mv	a0,s3
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	c3a080e7          	jalr	-966(ra) # 80004722 <iunlockput>
      return 0;
    80004af0:	89e6                	mv	s3,s9
    80004af2:	b7f1                	j	80004abe <namex+0x6a>
  len = path - s;
    80004af4:	40b48633          	sub	a2,s1,a1
    80004af8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004afc:	099c5463          	bge	s8,s9,80004b84 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004b00:	4639                	li	a2,14
    80004b02:	8552                	mv	a0,s4
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	23a080e7          	jalr	570(ra) # 80000d3e <memmove>
  while(*path == '/')
    80004b0c:	0004c783          	lbu	a5,0(s1)
    80004b10:	01279763          	bne	a5,s2,80004b1e <namex+0xca>
    path++;
    80004b14:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004b16:	0004c783          	lbu	a5,0(s1)
    80004b1a:	ff278de3          	beq	a5,s2,80004b14 <namex+0xc0>
    ilock(ip);
    80004b1e:	854e                	mv	a0,s3
    80004b20:	00000097          	auipc	ra,0x0
    80004b24:	9a0080e7          	jalr	-1632(ra) # 800044c0 <ilock>
    if(ip->type != T_DIR){
    80004b28:	04499783          	lh	a5,68(s3)
    80004b2c:	f97793e3          	bne	a5,s7,80004ab2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004b30:	000a8563          	beqz	s5,80004b3a <namex+0xe6>
    80004b34:	0004c783          	lbu	a5,0(s1)
    80004b38:	d3cd                	beqz	a5,80004ada <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004b3a:	865a                	mv	a2,s6
    80004b3c:	85d2                	mv	a1,s4
    80004b3e:	854e                	mv	a0,s3
    80004b40:	00000097          	auipc	ra,0x0
    80004b44:	e64080e7          	jalr	-412(ra) # 800049a4 <dirlookup>
    80004b48:	8caa                	mv	s9,a0
    80004b4a:	dd51                	beqz	a0,80004ae6 <namex+0x92>
    iunlockput(ip);
    80004b4c:	854e                	mv	a0,s3
    80004b4e:	00000097          	auipc	ra,0x0
    80004b52:	bd4080e7          	jalr	-1068(ra) # 80004722 <iunlockput>
    ip = next;
    80004b56:	89e6                	mv	s3,s9
  while(*path == '/')
    80004b58:	0004c783          	lbu	a5,0(s1)
    80004b5c:	05279763          	bne	a5,s2,80004baa <namex+0x156>
    path++;
    80004b60:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004b62:	0004c783          	lbu	a5,0(s1)
    80004b66:	ff278de3          	beq	a5,s2,80004b60 <namex+0x10c>
  if(*path == 0)
    80004b6a:	c79d                	beqz	a5,80004b98 <namex+0x144>
    path++;
    80004b6c:	85a6                	mv	a1,s1
  len = path - s;
    80004b6e:	8cda                	mv	s9,s6
    80004b70:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004b72:	01278963          	beq	a5,s2,80004b84 <namex+0x130>
    80004b76:	dfbd                	beqz	a5,80004af4 <namex+0xa0>
    path++;
    80004b78:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004b7a:	0004c783          	lbu	a5,0(s1)
    80004b7e:	ff279ce3          	bne	a5,s2,80004b76 <namex+0x122>
    80004b82:	bf8d                	j	80004af4 <namex+0xa0>
    memmove(name, s, len);
    80004b84:	2601                	sext.w	a2,a2
    80004b86:	8552                	mv	a0,s4
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	1b6080e7          	jalr	438(ra) # 80000d3e <memmove>
    name[len] = 0;
    80004b90:	9cd2                	add	s9,s9,s4
    80004b92:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004b96:	bf9d                	j	80004b0c <namex+0xb8>
  if(nameiparent){
    80004b98:	f20a83e3          	beqz	s5,80004abe <namex+0x6a>
    iput(ip);
    80004b9c:	854e                	mv	a0,s3
    80004b9e:	00000097          	auipc	ra,0x0
    80004ba2:	adc080e7          	jalr	-1316(ra) # 8000467a <iput>
    return 0;
    80004ba6:	4981                	li	s3,0
    80004ba8:	bf19                	j	80004abe <namex+0x6a>
  if(*path == 0)
    80004baa:	d7fd                	beqz	a5,80004b98 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004bac:	0004c783          	lbu	a5,0(s1)
    80004bb0:	85a6                	mv	a1,s1
    80004bb2:	b7d1                	j	80004b76 <namex+0x122>

0000000080004bb4 <dirlink>:
{
    80004bb4:	7139                	addi	sp,sp,-64
    80004bb6:	fc06                	sd	ra,56(sp)
    80004bb8:	f822                	sd	s0,48(sp)
    80004bba:	f426                	sd	s1,40(sp)
    80004bbc:	f04a                	sd	s2,32(sp)
    80004bbe:	ec4e                	sd	s3,24(sp)
    80004bc0:	e852                	sd	s4,16(sp)
    80004bc2:	0080                	addi	s0,sp,64
    80004bc4:	892a                	mv	s2,a0
    80004bc6:	8a2e                	mv	s4,a1
    80004bc8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004bca:	4601                	li	a2,0
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	dd8080e7          	jalr	-552(ra) # 800049a4 <dirlookup>
    80004bd4:	e93d                	bnez	a0,80004c4a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004bd6:	04c92483          	lw	s1,76(s2)
    80004bda:	c49d                	beqz	s1,80004c08 <dirlink+0x54>
    80004bdc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004bde:	4741                	li	a4,16
    80004be0:	86a6                	mv	a3,s1
    80004be2:	fc040613          	addi	a2,s0,-64
    80004be6:	4581                	li	a1,0
    80004be8:	854a                	mv	a0,s2
    80004bea:	00000097          	auipc	ra,0x0
    80004bee:	b8a080e7          	jalr	-1142(ra) # 80004774 <readi>
    80004bf2:	47c1                	li	a5,16
    80004bf4:	06f51163          	bne	a0,a5,80004c56 <dirlink+0xa2>
    if(de.inum == 0)
    80004bf8:	fc045783          	lhu	a5,-64(s0)
    80004bfc:	c791                	beqz	a5,80004c08 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004bfe:	24c1                	addiw	s1,s1,16
    80004c00:	04c92783          	lw	a5,76(s2)
    80004c04:	fcf4ede3          	bltu	s1,a5,80004bde <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004c08:	4639                	li	a2,14
    80004c0a:	85d2                	mv	a1,s4
    80004c0c:	fc240513          	addi	a0,s0,-62
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	1e6080e7          	jalr	486(ra) # 80000df6 <strncpy>
  de.inum = inum;
    80004c18:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c1c:	4741                	li	a4,16
    80004c1e:	86a6                	mv	a3,s1
    80004c20:	fc040613          	addi	a2,s0,-64
    80004c24:	4581                	li	a1,0
    80004c26:	854a                	mv	a0,s2
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	c44080e7          	jalr	-956(ra) # 8000486c <writei>
    80004c30:	872a                	mv	a4,a0
    80004c32:	47c1                	li	a5,16
  return 0;
    80004c34:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c36:	02f71863          	bne	a4,a5,80004c66 <dirlink+0xb2>
}
    80004c3a:	70e2                	ld	ra,56(sp)
    80004c3c:	7442                	ld	s0,48(sp)
    80004c3e:	74a2                	ld	s1,40(sp)
    80004c40:	7902                	ld	s2,32(sp)
    80004c42:	69e2                	ld	s3,24(sp)
    80004c44:	6a42                	ld	s4,16(sp)
    80004c46:	6121                	addi	sp,sp,64
    80004c48:	8082                	ret
    iput(ip);
    80004c4a:	00000097          	auipc	ra,0x0
    80004c4e:	a30080e7          	jalr	-1488(ra) # 8000467a <iput>
    return -1;
    80004c52:	557d                	li	a0,-1
    80004c54:	b7dd                	j	80004c3a <dirlink+0x86>
      panic("dirlink read");
    80004c56:	00005517          	auipc	a0,0x5
    80004c5a:	a2a50513          	addi	a0,a0,-1494 # 80009680 <syscalls+0x220>
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("dirlink");
    80004c66:	00005517          	auipc	a0,0x5
    80004c6a:	b2a50513          	addi	a0,a0,-1238 # 80009790 <syscalls+0x330>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080004c76 <namei>:

struct inode*
namei(char *path)
{
    80004c76:	1101                	addi	sp,sp,-32
    80004c78:	ec06                	sd	ra,24(sp)
    80004c7a:	e822                	sd	s0,16(sp)
    80004c7c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004c7e:	fe040613          	addi	a2,s0,-32
    80004c82:	4581                	li	a1,0
    80004c84:	00000097          	auipc	ra,0x0
    80004c88:	dd0080e7          	jalr	-560(ra) # 80004a54 <namex>
}
    80004c8c:	60e2                	ld	ra,24(sp)
    80004c8e:	6442                	ld	s0,16(sp)
    80004c90:	6105                	addi	sp,sp,32
    80004c92:	8082                	ret

0000000080004c94 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004c94:	1141                	addi	sp,sp,-16
    80004c96:	e406                	sd	ra,8(sp)
    80004c98:	e022                	sd	s0,0(sp)
    80004c9a:	0800                	addi	s0,sp,16
    80004c9c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004c9e:	4585                	li	a1,1
    80004ca0:	00000097          	auipc	ra,0x0
    80004ca4:	db4080e7          	jalr	-588(ra) # 80004a54 <namex>
}
    80004ca8:	60a2                	ld	ra,8(sp)
    80004caa:	6402                	ld	s0,0(sp)
    80004cac:	0141                	addi	sp,sp,16
    80004cae:	8082                	ret

0000000080004cb0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004cb0:	1101                	addi	sp,sp,-32
    80004cb2:	ec06                	sd	ra,24(sp)
    80004cb4:	e822                	sd	s0,16(sp)
    80004cb6:	e426                	sd	s1,8(sp)
    80004cb8:	e04a                	sd	s2,0(sp)
    80004cba:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004cbc:	0003a917          	auipc	s2,0x3a
    80004cc0:	be490913          	addi	s2,s2,-1052 # 8003e8a0 <log>
    80004cc4:	01892583          	lw	a1,24(s2)
    80004cc8:	02892503          	lw	a0,40(s2)
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	ff0080e7          	jalr	-16(ra) # 80003cbc <bread>
    80004cd4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004cd6:	02c92683          	lw	a3,44(s2)
    80004cda:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004cdc:	02d05863          	blez	a3,80004d0c <write_head+0x5c>
    80004ce0:	0003a797          	auipc	a5,0x3a
    80004ce4:	bf078793          	addi	a5,a5,-1040 # 8003e8d0 <log+0x30>
    80004ce8:	05c50713          	addi	a4,a0,92
    80004cec:	36fd                	addiw	a3,a3,-1
    80004cee:	02069613          	slli	a2,a3,0x20
    80004cf2:	01e65693          	srli	a3,a2,0x1e
    80004cf6:	0003a617          	auipc	a2,0x3a
    80004cfa:	bde60613          	addi	a2,a2,-1058 # 8003e8d4 <log+0x34>
    80004cfe:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004d00:	4390                	lw	a2,0(a5)
    80004d02:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004d04:	0791                	addi	a5,a5,4
    80004d06:	0711                	addi	a4,a4,4
    80004d08:	fed79ce3          	bne	a5,a3,80004d00 <write_head+0x50>
  }
  bwrite(buf);
    80004d0c:	8526                	mv	a0,s1
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	0a0080e7          	jalr	160(ra) # 80003dae <bwrite>
  brelse(buf);
    80004d16:	8526                	mv	a0,s1
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	0d4080e7          	jalr	212(ra) # 80003dec <brelse>
}
    80004d20:	60e2                	ld	ra,24(sp)
    80004d22:	6442                	ld	s0,16(sp)
    80004d24:	64a2                	ld	s1,8(sp)
    80004d26:	6902                	ld	s2,0(sp)
    80004d28:	6105                	addi	sp,sp,32
    80004d2a:	8082                	ret

0000000080004d2c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d2c:	0003a797          	auipc	a5,0x3a
    80004d30:	ba07a783          	lw	a5,-1120(a5) # 8003e8cc <log+0x2c>
    80004d34:	0af05d63          	blez	a5,80004dee <install_trans+0xc2>
{
    80004d38:	7139                	addi	sp,sp,-64
    80004d3a:	fc06                	sd	ra,56(sp)
    80004d3c:	f822                	sd	s0,48(sp)
    80004d3e:	f426                	sd	s1,40(sp)
    80004d40:	f04a                	sd	s2,32(sp)
    80004d42:	ec4e                	sd	s3,24(sp)
    80004d44:	e852                	sd	s4,16(sp)
    80004d46:	e456                	sd	s5,8(sp)
    80004d48:	e05a                	sd	s6,0(sp)
    80004d4a:	0080                	addi	s0,sp,64
    80004d4c:	8b2a                	mv	s6,a0
    80004d4e:	0003aa97          	auipc	s5,0x3a
    80004d52:	b82a8a93          	addi	s5,s5,-1150 # 8003e8d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d56:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004d58:	0003a997          	auipc	s3,0x3a
    80004d5c:	b4898993          	addi	s3,s3,-1208 # 8003e8a0 <log>
    80004d60:	a00d                	j	80004d82 <install_trans+0x56>
    brelse(lbuf);
    80004d62:	854a                	mv	a0,s2
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	088080e7          	jalr	136(ra) # 80003dec <brelse>
    brelse(dbuf);
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	07e080e7          	jalr	126(ra) # 80003dec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d76:	2a05                	addiw	s4,s4,1
    80004d78:	0a91                	addi	s5,s5,4
    80004d7a:	02c9a783          	lw	a5,44(s3)
    80004d7e:	04fa5e63          	bge	s4,a5,80004dda <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004d82:	0189a583          	lw	a1,24(s3)
    80004d86:	014585bb          	addw	a1,a1,s4
    80004d8a:	2585                	addiw	a1,a1,1
    80004d8c:	0289a503          	lw	a0,40(s3)
    80004d90:	fffff097          	auipc	ra,0xfffff
    80004d94:	f2c080e7          	jalr	-212(ra) # 80003cbc <bread>
    80004d98:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004d9a:	000aa583          	lw	a1,0(s5)
    80004d9e:	0289a503          	lw	a0,40(s3)
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	f1a080e7          	jalr	-230(ra) # 80003cbc <bread>
    80004daa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004dac:	40000613          	li	a2,1024
    80004db0:	05890593          	addi	a1,s2,88
    80004db4:	05850513          	addi	a0,a0,88
    80004db8:	ffffc097          	auipc	ra,0xffffc
    80004dbc:	f86080e7          	jalr	-122(ra) # 80000d3e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	fffff097          	auipc	ra,0xfffff
    80004dc6:	fec080e7          	jalr	-20(ra) # 80003dae <bwrite>
    if(recovering == 0)
    80004dca:	f80b1ce3          	bnez	s6,80004d62 <install_trans+0x36>
      bunpin(dbuf);
    80004dce:	8526                	mv	a0,s1
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	0f6080e7          	jalr	246(ra) # 80003ec6 <bunpin>
    80004dd8:	b769                	j	80004d62 <install_trans+0x36>
}
    80004dda:	70e2                	ld	ra,56(sp)
    80004ddc:	7442                	ld	s0,48(sp)
    80004dde:	74a2                	ld	s1,40(sp)
    80004de0:	7902                	ld	s2,32(sp)
    80004de2:	69e2                	ld	s3,24(sp)
    80004de4:	6a42                	ld	s4,16(sp)
    80004de6:	6aa2                	ld	s5,8(sp)
    80004de8:	6b02                	ld	s6,0(sp)
    80004dea:	6121                	addi	sp,sp,64
    80004dec:	8082                	ret
    80004dee:	8082                	ret

0000000080004df0 <initlog>:
{
    80004df0:	7179                	addi	sp,sp,-48
    80004df2:	f406                	sd	ra,40(sp)
    80004df4:	f022                	sd	s0,32(sp)
    80004df6:	ec26                	sd	s1,24(sp)
    80004df8:	e84a                	sd	s2,16(sp)
    80004dfa:	e44e                	sd	s3,8(sp)
    80004dfc:	1800                	addi	s0,sp,48
    80004dfe:	892a                	mv	s2,a0
    80004e00:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004e02:	0003a497          	auipc	s1,0x3a
    80004e06:	a9e48493          	addi	s1,s1,-1378 # 8003e8a0 <log>
    80004e0a:	00005597          	auipc	a1,0x5
    80004e0e:	88658593          	addi	a1,a1,-1914 # 80009690 <syscalls+0x230>
    80004e12:	8526                	mv	a0,s1
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	d1e080e7          	jalr	-738(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004e1c:	0149a583          	lw	a1,20(s3)
    80004e20:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004e22:	0109a783          	lw	a5,16(s3)
    80004e26:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004e28:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004e2c:	854a                	mv	a0,s2
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	e8e080e7          	jalr	-370(ra) # 80003cbc <bread>
  log.lh.n = lh->n;
    80004e36:	4d34                	lw	a3,88(a0)
    80004e38:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004e3a:	02d05663          	blez	a3,80004e66 <initlog+0x76>
    80004e3e:	05c50793          	addi	a5,a0,92
    80004e42:	0003a717          	auipc	a4,0x3a
    80004e46:	a8e70713          	addi	a4,a4,-1394 # 8003e8d0 <log+0x30>
    80004e4a:	36fd                	addiw	a3,a3,-1
    80004e4c:	02069613          	slli	a2,a3,0x20
    80004e50:	01e65693          	srli	a3,a2,0x1e
    80004e54:	06050613          	addi	a2,a0,96
    80004e58:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004e5a:	4390                	lw	a2,0(a5)
    80004e5c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004e5e:	0791                	addi	a5,a5,4
    80004e60:	0711                	addi	a4,a4,4
    80004e62:	fed79ce3          	bne	a5,a3,80004e5a <initlog+0x6a>
  brelse(buf);
    80004e66:	fffff097          	auipc	ra,0xfffff
    80004e6a:	f86080e7          	jalr	-122(ra) # 80003dec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004e6e:	4505                	li	a0,1
    80004e70:	00000097          	auipc	ra,0x0
    80004e74:	ebc080e7          	jalr	-324(ra) # 80004d2c <install_trans>
  log.lh.n = 0;
    80004e78:	0003a797          	auipc	a5,0x3a
    80004e7c:	a407aa23          	sw	zero,-1452(a5) # 8003e8cc <log+0x2c>
  write_head(); // clear the log
    80004e80:	00000097          	auipc	ra,0x0
    80004e84:	e30080e7          	jalr	-464(ra) # 80004cb0 <write_head>
}
    80004e88:	70a2                	ld	ra,40(sp)
    80004e8a:	7402                	ld	s0,32(sp)
    80004e8c:	64e2                	ld	s1,24(sp)
    80004e8e:	6942                	ld	s2,16(sp)
    80004e90:	69a2                	ld	s3,8(sp)
    80004e92:	6145                	addi	sp,sp,48
    80004e94:	8082                	ret

0000000080004e96 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004e96:	1101                	addi	sp,sp,-32
    80004e98:	ec06                	sd	ra,24(sp)
    80004e9a:	e822                	sd	s0,16(sp)
    80004e9c:	e426                	sd	s1,8(sp)
    80004e9e:	e04a                	sd	s2,0(sp)
    80004ea0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ea2:	0003a517          	auipc	a0,0x3a
    80004ea6:	9fe50513          	addi	a0,a0,-1538 # 8003e8a0 <log>
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	d18080e7          	jalr	-744(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004eb2:	0003a497          	auipc	s1,0x3a
    80004eb6:	9ee48493          	addi	s1,s1,-1554 # 8003e8a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004eba:	4979                	li	s2,30
    80004ebc:	a039                	j	80004eca <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ebe:	85a6                	mv	a1,s1
    80004ec0:	8526                	mv	a0,s1
    80004ec2:	ffffe097          	auipc	ra,0xffffe
    80004ec6:	816080e7          	jalr	-2026(ra) # 800026d8 <sleep>
    if(log.committing){
    80004eca:	50dc                	lw	a5,36(s1)
    80004ecc:	fbed                	bnez	a5,80004ebe <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ece:	509c                	lw	a5,32(s1)
    80004ed0:	0017871b          	addiw	a4,a5,1
    80004ed4:	0007069b          	sext.w	a3,a4
    80004ed8:	0027179b          	slliw	a5,a4,0x2
    80004edc:	9fb9                	addw	a5,a5,a4
    80004ede:	0017979b          	slliw	a5,a5,0x1
    80004ee2:	54d8                	lw	a4,44(s1)
    80004ee4:	9fb9                	addw	a5,a5,a4
    80004ee6:	00f95963          	bge	s2,a5,80004ef8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004eea:	85a6                	mv	a1,s1
    80004eec:	8526                	mv	a0,s1
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	7ea080e7          	jalr	2026(ra) # 800026d8 <sleep>
    80004ef6:	bfd1                	j	80004eca <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004ef8:	0003a517          	auipc	a0,0x3a
    80004efc:	9a850513          	addi	a0,a0,-1624 # 8003e8a0 <log>
    80004f00:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	d86080e7          	jalr	-634(ra) # 80000c88 <release>
      break;
    }
  }
}
    80004f0a:	60e2                	ld	ra,24(sp)
    80004f0c:	6442                	ld	s0,16(sp)
    80004f0e:	64a2                	ld	s1,8(sp)
    80004f10:	6902                	ld	s2,0(sp)
    80004f12:	6105                	addi	sp,sp,32
    80004f14:	8082                	ret

0000000080004f16 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004f16:	7139                	addi	sp,sp,-64
    80004f18:	fc06                	sd	ra,56(sp)
    80004f1a:	f822                	sd	s0,48(sp)
    80004f1c:	f426                	sd	s1,40(sp)
    80004f1e:	f04a                	sd	s2,32(sp)
    80004f20:	ec4e                	sd	s3,24(sp)
    80004f22:	e852                	sd	s4,16(sp)
    80004f24:	e456                	sd	s5,8(sp)
    80004f26:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004f28:	0003a497          	auipc	s1,0x3a
    80004f2c:	97848493          	addi	s1,s1,-1672 # 8003e8a0 <log>
    80004f30:	8526                	mv	a0,s1
    80004f32:	ffffc097          	auipc	ra,0xffffc
    80004f36:	c90080e7          	jalr	-880(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004f3a:	509c                	lw	a5,32(s1)
    80004f3c:	37fd                	addiw	a5,a5,-1
    80004f3e:	0007891b          	sext.w	s2,a5
    80004f42:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004f44:	50dc                	lw	a5,36(s1)
    80004f46:	e7b9                	bnez	a5,80004f94 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004f48:	04091e63          	bnez	s2,80004fa4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004f4c:	0003a497          	auipc	s1,0x3a
    80004f50:	95448493          	addi	s1,s1,-1708 # 8003e8a0 <log>
    80004f54:	4785                	li	a5,1
    80004f56:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004f58:	8526                	mv	a0,s1
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	d2e080e7          	jalr	-722(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004f62:	54dc                	lw	a5,44(s1)
    80004f64:	06f04763          	bgtz	a5,80004fd2 <end_op+0xbc>
    acquire(&log.lock);
    80004f68:	0003a497          	auipc	s1,0x3a
    80004f6c:	93848493          	addi	s1,s1,-1736 # 8003e8a0 <log>
    80004f70:	8526                	mv	a0,s1
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	c50080e7          	jalr	-944(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004f7a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004f7e:	8526                	mv	a0,s1
    80004f80:	ffffe097          	auipc	ra,0xffffe
    80004f84:	8e2080e7          	jalr	-1822(ra) # 80002862 <wakeup>
    release(&log.lock);
    80004f88:	8526                	mv	a0,s1
    80004f8a:	ffffc097          	auipc	ra,0xffffc
    80004f8e:	cfe080e7          	jalr	-770(ra) # 80000c88 <release>
}
    80004f92:	a03d                	j	80004fc0 <end_op+0xaa>
    panic("log.committing");
    80004f94:	00004517          	auipc	a0,0x4
    80004f98:	70450513          	addi	a0,a0,1796 # 80009698 <syscalls+0x238>
    80004f9c:	ffffb097          	auipc	ra,0xffffb
    80004fa0:	58e080e7          	jalr	1422(ra) # 8000052a <panic>
    wakeup(&log);
    80004fa4:	0003a497          	auipc	s1,0x3a
    80004fa8:	8fc48493          	addi	s1,s1,-1796 # 8003e8a0 <log>
    80004fac:	8526                	mv	a0,s1
    80004fae:	ffffe097          	auipc	ra,0xffffe
    80004fb2:	8b4080e7          	jalr	-1868(ra) # 80002862 <wakeup>
  release(&log.lock);
    80004fb6:	8526                	mv	a0,s1
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	cd0080e7          	jalr	-816(ra) # 80000c88 <release>
}
    80004fc0:	70e2                	ld	ra,56(sp)
    80004fc2:	7442                	ld	s0,48(sp)
    80004fc4:	74a2                	ld	s1,40(sp)
    80004fc6:	7902                	ld	s2,32(sp)
    80004fc8:	69e2                	ld	s3,24(sp)
    80004fca:	6a42                	ld	s4,16(sp)
    80004fcc:	6aa2                	ld	s5,8(sp)
    80004fce:	6121                	addi	sp,sp,64
    80004fd0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004fd2:	0003aa97          	auipc	s5,0x3a
    80004fd6:	8fea8a93          	addi	s5,s5,-1794 # 8003e8d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004fda:	0003aa17          	auipc	s4,0x3a
    80004fde:	8c6a0a13          	addi	s4,s4,-1850 # 8003e8a0 <log>
    80004fe2:	018a2583          	lw	a1,24(s4)
    80004fe6:	012585bb          	addw	a1,a1,s2
    80004fea:	2585                	addiw	a1,a1,1
    80004fec:	028a2503          	lw	a0,40(s4)
    80004ff0:	fffff097          	auipc	ra,0xfffff
    80004ff4:	ccc080e7          	jalr	-820(ra) # 80003cbc <bread>
    80004ff8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004ffa:	000aa583          	lw	a1,0(s5)
    80004ffe:	028a2503          	lw	a0,40(s4)
    80005002:	fffff097          	auipc	ra,0xfffff
    80005006:	cba080e7          	jalr	-838(ra) # 80003cbc <bread>
    8000500a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000500c:	40000613          	li	a2,1024
    80005010:	05850593          	addi	a1,a0,88
    80005014:	05848513          	addi	a0,s1,88
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	d26080e7          	jalr	-730(ra) # 80000d3e <memmove>
    bwrite(to);  // write the log
    80005020:	8526                	mv	a0,s1
    80005022:	fffff097          	auipc	ra,0xfffff
    80005026:	d8c080e7          	jalr	-628(ra) # 80003dae <bwrite>
    brelse(from);
    8000502a:	854e                	mv	a0,s3
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	dc0080e7          	jalr	-576(ra) # 80003dec <brelse>
    brelse(to);
    80005034:	8526                	mv	a0,s1
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	db6080e7          	jalr	-586(ra) # 80003dec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000503e:	2905                	addiw	s2,s2,1
    80005040:	0a91                	addi	s5,s5,4
    80005042:	02ca2783          	lw	a5,44(s4)
    80005046:	f8f94ee3          	blt	s2,a5,80004fe2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000504a:	00000097          	auipc	ra,0x0
    8000504e:	c66080e7          	jalr	-922(ra) # 80004cb0 <write_head>
    install_trans(0); // Now install writes to home locations
    80005052:	4501                	li	a0,0
    80005054:	00000097          	auipc	ra,0x0
    80005058:	cd8080e7          	jalr	-808(ra) # 80004d2c <install_trans>
    log.lh.n = 0;
    8000505c:	0003a797          	auipc	a5,0x3a
    80005060:	8607a823          	sw	zero,-1936(a5) # 8003e8cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80005064:	00000097          	auipc	ra,0x0
    80005068:	c4c080e7          	jalr	-948(ra) # 80004cb0 <write_head>
    8000506c:	bdf5                	j	80004f68 <end_op+0x52>

000000008000506e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000506e:	1101                	addi	sp,sp,-32
    80005070:	ec06                	sd	ra,24(sp)
    80005072:	e822                	sd	s0,16(sp)
    80005074:	e426                	sd	s1,8(sp)
    80005076:	e04a                	sd	s2,0(sp)
    80005078:	1000                	addi	s0,sp,32
    8000507a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000507c:	0003a917          	auipc	s2,0x3a
    80005080:	82490913          	addi	s2,s2,-2012 # 8003e8a0 <log>
    80005084:	854a                	mv	a0,s2
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	b3c080e7          	jalr	-1220(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000508e:	02c92603          	lw	a2,44(s2)
    80005092:	47f5                	li	a5,29
    80005094:	06c7c563          	blt	a5,a2,800050fe <log_write+0x90>
    80005098:	0003a797          	auipc	a5,0x3a
    8000509c:	8247a783          	lw	a5,-2012(a5) # 8003e8bc <log+0x1c>
    800050a0:	37fd                	addiw	a5,a5,-1
    800050a2:	04f65e63          	bge	a2,a5,800050fe <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800050a6:	0003a797          	auipc	a5,0x3a
    800050aa:	81a7a783          	lw	a5,-2022(a5) # 8003e8c0 <log+0x20>
    800050ae:	06f05063          	blez	a5,8000510e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800050b2:	4781                	li	a5,0
    800050b4:	06c05563          	blez	a2,8000511e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800050b8:	44cc                	lw	a1,12(s1)
    800050ba:	0003a717          	auipc	a4,0x3a
    800050be:	81670713          	addi	a4,a4,-2026 # 8003e8d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800050c2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800050c4:	4314                	lw	a3,0(a4)
    800050c6:	04b68c63          	beq	a3,a1,8000511e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800050ca:	2785                	addiw	a5,a5,1
    800050cc:	0711                	addi	a4,a4,4
    800050ce:	fef61be3          	bne	a2,a5,800050c4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800050d2:	0621                	addi	a2,a2,8
    800050d4:	060a                	slli	a2,a2,0x2
    800050d6:	00039797          	auipc	a5,0x39
    800050da:	7ca78793          	addi	a5,a5,1994 # 8003e8a0 <log>
    800050de:	963e                	add	a2,a2,a5
    800050e0:	44dc                	lw	a5,12(s1)
    800050e2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800050e4:	8526                	mv	a0,s1
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	da4080e7          	jalr	-604(ra) # 80003e8a <bpin>
    log.lh.n++;
    800050ee:	00039717          	auipc	a4,0x39
    800050f2:	7b270713          	addi	a4,a4,1970 # 8003e8a0 <log>
    800050f6:	575c                	lw	a5,44(a4)
    800050f8:	2785                	addiw	a5,a5,1
    800050fa:	d75c                	sw	a5,44(a4)
    800050fc:	a835                	j	80005138 <log_write+0xca>
    panic("too big a transaction");
    800050fe:	00004517          	auipc	a0,0x4
    80005102:	5aa50513          	addi	a0,a0,1450 # 800096a8 <syscalls+0x248>
    80005106:	ffffb097          	auipc	ra,0xffffb
    8000510a:	424080e7          	jalr	1060(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000510e:	00004517          	auipc	a0,0x4
    80005112:	5b250513          	addi	a0,a0,1458 # 800096c0 <syscalls+0x260>
    80005116:	ffffb097          	auipc	ra,0xffffb
    8000511a:	414080e7          	jalr	1044(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000511e:	00878713          	addi	a4,a5,8
    80005122:	00271693          	slli	a3,a4,0x2
    80005126:	00039717          	auipc	a4,0x39
    8000512a:	77a70713          	addi	a4,a4,1914 # 8003e8a0 <log>
    8000512e:	9736                	add	a4,a4,a3
    80005130:	44d4                	lw	a3,12(s1)
    80005132:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005134:	faf608e3          	beq	a2,a5,800050e4 <log_write+0x76>
  }
  release(&log.lock);
    80005138:	00039517          	auipc	a0,0x39
    8000513c:	76850513          	addi	a0,a0,1896 # 8003e8a0 <log>
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	b48080e7          	jalr	-1208(ra) # 80000c88 <release>
}
    80005148:	60e2                	ld	ra,24(sp)
    8000514a:	6442                	ld	s0,16(sp)
    8000514c:	64a2                	ld	s1,8(sp)
    8000514e:	6902                	ld	s2,0(sp)
    80005150:	6105                	addi	sp,sp,32
    80005152:	8082                	ret

0000000080005154 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005154:	1101                	addi	sp,sp,-32
    80005156:	ec06                	sd	ra,24(sp)
    80005158:	e822                	sd	s0,16(sp)
    8000515a:	e426                	sd	s1,8(sp)
    8000515c:	e04a                	sd	s2,0(sp)
    8000515e:	1000                	addi	s0,sp,32
    80005160:	84aa                	mv	s1,a0
    80005162:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005164:	00004597          	auipc	a1,0x4
    80005168:	57c58593          	addi	a1,a1,1404 # 800096e0 <syscalls+0x280>
    8000516c:	0521                	addi	a0,a0,8
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	9c4080e7          	jalr	-1596(ra) # 80000b32 <initlock>
  lk->name = name;
    80005176:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000517a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000517e:	0204a423          	sw	zero,40(s1)
}
    80005182:	60e2                	ld	ra,24(sp)
    80005184:	6442                	ld	s0,16(sp)
    80005186:	64a2                	ld	s1,8(sp)
    80005188:	6902                	ld	s2,0(sp)
    8000518a:	6105                	addi	sp,sp,32
    8000518c:	8082                	ret

000000008000518e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000518e:	1101                	addi	sp,sp,-32
    80005190:	ec06                	sd	ra,24(sp)
    80005192:	e822                	sd	s0,16(sp)
    80005194:	e426                	sd	s1,8(sp)
    80005196:	e04a                	sd	s2,0(sp)
    80005198:	1000                	addi	s0,sp,32
    8000519a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000519c:	00850913          	addi	s2,a0,8
    800051a0:	854a                	mv	a0,s2
    800051a2:	ffffc097          	auipc	ra,0xffffc
    800051a6:	a20080e7          	jalr	-1504(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800051aa:	409c                	lw	a5,0(s1)
    800051ac:	cb89                	beqz	a5,800051be <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800051ae:	85ca                	mv	a1,s2
    800051b0:	8526                	mv	a0,s1
    800051b2:	ffffd097          	auipc	ra,0xffffd
    800051b6:	526080e7          	jalr	1318(ra) # 800026d8 <sleep>
  while (lk->locked) {
    800051ba:	409c                	lw	a5,0(s1)
    800051bc:	fbed                	bnez	a5,800051ae <acquiresleep+0x20>
  }
  lk->locked = 1;
    800051be:	4785                	li	a5,1
    800051c0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800051c2:	ffffd097          	auipc	ra,0xffffd
    800051c6:	870080e7          	jalr	-1936(ra) # 80001a32 <myproc>
    800051ca:	515c                	lw	a5,36(a0)
    800051cc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800051ce:	854a                	mv	a0,s2
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	ab8080e7          	jalr	-1352(ra) # 80000c88 <release>
}
    800051d8:	60e2                	ld	ra,24(sp)
    800051da:	6442                	ld	s0,16(sp)
    800051dc:	64a2                	ld	s1,8(sp)
    800051de:	6902                	ld	s2,0(sp)
    800051e0:	6105                	addi	sp,sp,32
    800051e2:	8082                	ret

00000000800051e4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800051e4:	1101                	addi	sp,sp,-32
    800051e6:	ec06                	sd	ra,24(sp)
    800051e8:	e822                	sd	s0,16(sp)
    800051ea:	e426                	sd	s1,8(sp)
    800051ec:	e04a                	sd	s2,0(sp)
    800051ee:	1000                	addi	s0,sp,32
    800051f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800051f2:	00850913          	addi	s2,a0,8
    800051f6:	854a                	mv	a0,s2
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	9ca080e7          	jalr	-1590(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80005200:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005204:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005208:	8526                	mv	a0,s1
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	658080e7          	jalr	1624(ra) # 80002862 <wakeup>
  release(&lk->lk);
    80005212:	854a                	mv	a0,s2
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	a74080e7          	jalr	-1420(ra) # 80000c88 <release>
}
    8000521c:	60e2                	ld	ra,24(sp)
    8000521e:	6442                	ld	s0,16(sp)
    80005220:	64a2                	ld	s1,8(sp)
    80005222:	6902                	ld	s2,0(sp)
    80005224:	6105                	addi	sp,sp,32
    80005226:	8082                	ret

0000000080005228 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005228:	7179                	addi	sp,sp,-48
    8000522a:	f406                	sd	ra,40(sp)
    8000522c:	f022                	sd	s0,32(sp)
    8000522e:	ec26                	sd	s1,24(sp)
    80005230:	e84a                	sd	s2,16(sp)
    80005232:	e44e                	sd	s3,8(sp)
    80005234:	1800                	addi	s0,sp,48
    80005236:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005238:	00850913          	addi	s2,a0,8
    8000523c:	854a                	mv	a0,s2
    8000523e:	ffffc097          	auipc	ra,0xffffc
    80005242:	984080e7          	jalr	-1660(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005246:	409c                	lw	a5,0(s1)
    80005248:	ef99                	bnez	a5,80005266 <holdingsleep+0x3e>
    8000524a:	4481                	li	s1,0
  release(&lk->lk);
    8000524c:	854a                	mv	a0,s2
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	a3a080e7          	jalr	-1478(ra) # 80000c88 <release>
  return r;
}
    80005256:	8526                	mv	a0,s1
    80005258:	70a2                	ld	ra,40(sp)
    8000525a:	7402                	ld	s0,32(sp)
    8000525c:	64e2                	ld	s1,24(sp)
    8000525e:	6942                	ld	s2,16(sp)
    80005260:	69a2                	ld	s3,8(sp)
    80005262:	6145                	addi	sp,sp,48
    80005264:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005266:	0284a983          	lw	s3,40(s1)
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	7c8080e7          	jalr	1992(ra) # 80001a32 <myproc>
    80005272:	5144                	lw	s1,36(a0)
    80005274:	413484b3          	sub	s1,s1,s3
    80005278:	0014b493          	seqz	s1,s1
    8000527c:	bfc1                	j	8000524c <holdingsleep+0x24>

000000008000527e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000527e:	1141                	addi	sp,sp,-16
    80005280:	e406                	sd	ra,8(sp)
    80005282:	e022                	sd	s0,0(sp)
    80005284:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005286:	00004597          	auipc	a1,0x4
    8000528a:	46a58593          	addi	a1,a1,1130 # 800096f0 <syscalls+0x290>
    8000528e:	00039517          	auipc	a0,0x39
    80005292:	75a50513          	addi	a0,a0,1882 # 8003e9e8 <ftable>
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	89c080e7          	jalr	-1892(ra) # 80000b32 <initlock>
}
    8000529e:	60a2                	ld	ra,8(sp)
    800052a0:	6402                	ld	s0,0(sp)
    800052a2:	0141                	addi	sp,sp,16
    800052a4:	8082                	ret

00000000800052a6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800052a6:	1101                	addi	sp,sp,-32
    800052a8:	ec06                	sd	ra,24(sp)
    800052aa:	e822                	sd	s0,16(sp)
    800052ac:	e426                	sd	s1,8(sp)
    800052ae:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800052b0:	00039517          	auipc	a0,0x39
    800052b4:	73850513          	addi	a0,a0,1848 # 8003e9e8 <ftable>
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	90a080e7          	jalr	-1782(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800052c0:	00039497          	auipc	s1,0x39
    800052c4:	74048493          	addi	s1,s1,1856 # 8003ea00 <ftable+0x18>
    800052c8:	0003a717          	auipc	a4,0x3a
    800052cc:	6d870713          	addi	a4,a4,1752 # 8003f9a0 <ftable+0xfb8>
    if(f->ref == 0){
    800052d0:	40dc                	lw	a5,4(s1)
    800052d2:	cf99                	beqz	a5,800052f0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800052d4:	02848493          	addi	s1,s1,40
    800052d8:	fee49ce3          	bne	s1,a4,800052d0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800052dc:	00039517          	auipc	a0,0x39
    800052e0:	70c50513          	addi	a0,a0,1804 # 8003e9e8 <ftable>
    800052e4:	ffffc097          	auipc	ra,0xffffc
    800052e8:	9a4080e7          	jalr	-1628(ra) # 80000c88 <release>
  return 0;
    800052ec:	4481                	li	s1,0
    800052ee:	a819                	j	80005304 <filealloc+0x5e>
      f->ref = 1;
    800052f0:	4785                	li	a5,1
    800052f2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800052f4:	00039517          	auipc	a0,0x39
    800052f8:	6f450513          	addi	a0,a0,1780 # 8003e9e8 <ftable>
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	98c080e7          	jalr	-1652(ra) # 80000c88 <release>
}
    80005304:	8526                	mv	a0,s1
    80005306:	60e2                	ld	ra,24(sp)
    80005308:	6442                	ld	s0,16(sp)
    8000530a:	64a2                	ld	s1,8(sp)
    8000530c:	6105                	addi	sp,sp,32
    8000530e:	8082                	ret

0000000080005310 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005310:	1101                	addi	sp,sp,-32
    80005312:	ec06                	sd	ra,24(sp)
    80005314:	e822                	sd	s0,16(sp)
    80005316:	e426                	sd	s1,8(sp)
    80005318:	1000                	addi	s0,sp,32
    8000531a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000531c:	00039517          	auipc	a0,0x39
    80005320:	6cc50513          	addi	a0,a0,1740 # 8003e9e8 <ftable>
    80005324:	ffffc097          	auipc	ra,0xffffc
    80005328:	89e080e7          	jalr	-1890(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000532c:	40dc                	lw	a5,4(s1)
    8000532e:	02f05263          	blez	a5,80005352 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005332:	2785                	addiw	a5,a5,1
    80005334:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005336:	00039517          	auipc	a0,0x39
    8000533a:	6b250513          	addi	a0,a0,1714 # 8003e9e8 <ftable>
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	94a080e7          	jalr	-1718(ra) # 80000c88 <release>
  return f;
}
    80005346:	8526                	mv	a0,s1
    80005348:	60e2                	ld	ra,24(sp)
    8000534a:	6442                	ld	s0,16(sp)
    8000534c:	64a2                	ld	s1,8(sp)
    8000534e:	6105                	addi	sp,sp,32
    80005350:	8082                	ret
    panic("filedup");
    80005352:	00004517          	auipc	a0,0x4
    80005356:	3a650513          	addi	a0,a0,934 # 800096f8 <syscalls+0x298>
    8000535a:	ffffb097          	auipc	ra,0xffffb
    8000535e:	1d0080e7          	jalr	464(ra) # 8000052a <panic>

0000000080005362 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005362:	7139                	addi	sp,sp,-64
    80005364:	fc06                	sd	ra,56(sp)
    80005366:	f822                	sd	s0,48(sp)
    80005368:	f426                	sd	s1,40(sp)
    8000536a:	f04a                	sd	s2,32(sp)
    8000536c:	ec4e                	sd	s3,24(sp)
    8000536e:	e852                	sd	s4,16(sp)
    80005370:	e456                	sd	s5,8(sp)
    80005372:	0080                	addi	s0,sp,64
    80005374:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005376:	00039517          	auipc	a0,0x39
    8000537a:	67250513          	addi	a0,a0,1650 # 8003e9e8 <ftable>
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	844080e7          	jalr	-1980(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005386:	40dc                	lw	a5,4(s1)
    80005388:	06f05163          	blez	a5,800053ea <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000538c:	37fd                	addiw	a5,a5,-1
    8000538e:	0007871b          	sext.w	a4,a5
    80005392:	c0dc                	sw	a5,4(s1)
    80005394:	06e04363          	bgtz	a4,800053fa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005398:	0004a903          	lw	s2,0(s1)
    8000539c:	0094ca83          	lbu	s5,9(s1)
    800053a0:	0104ba03          	ld	s4,16(s1)
    800053a4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800053a8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800053ac:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800053b0:	00039517          	auipc	a0,0x39
    800053b4:	63850513          	addi	a0,a0,1592 # 8003e9e8 <ftable>
    800053b8:	ffffc097          	auipc	ra,0xffffc
    800053bc:	8d0080e7          	jalr	-1840(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    800053c0:	4785                	li	a5,1
    800053c2:	04f90d63          	beq	s2,a5,8000541c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800053c6:	3979                	addiw	s2,s2,-2
    800053c8:	4785                	li	a5,1
    800053ca:	0527e063          	bltu	a5,s2,8000540a <fileclose+0xa8>
    begin_op();
    800053ce:	00000097          	auipc	ra,0x0
    800053d2:	ac8080e7          	jalr	-1336(ra) # 80004e96 <begin_op>
    iput(ff.ip);
    800053d6:	854e                	mv	a0,s3
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	2a2080e7          	jalr	674(ra) # 8000467a <iput>
    end_op();
    800053e0:	00000097          	auipc	ra,0x0
    800053e4:	b36080e7          	jalr	-1226(ra) # 80004f16 <end_op>
    800053e8:	a00d                	j	8000540a <fileclose+0xa8>
    panic("fileclose");
    800053ea:	00004517          	auipc	a0,0x4
    800053ee:	31650513          	addi	a0,a0,790 # 80009700 <syscalls+0x2a0>
    800053f2:	ffffb097          	auipc	ra,0xffffb
    800053f6:	138080e7          	jalr	312(ra) # 8000052a <panic>
    release(&ftable.lock);
    800053fa:	00039517          	auipc	a0,0x39
    800053fe:	5ee50513          	addi	a0,a0,1518 # 8003e9e8 <ftable>
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	886080e7          	jalr	-1914(ra) # 80000c88 <release>
  }
}
    8000540a:	70e2                	ld	ra,56(sp)
    8000540c:	7442                	ld	s0,48(sp)
    8000540e:	74a2                	ld	s1,40(sp)
    80005410:	7902                	ld	s2,32(sp)
    80005412:	69e2                	ld	s3,24(sp)
    80005414:	6a42                	ld	s4,16(sp)
    80005416:	6aa2                	ld	s5,8(sp)
    80005418:	6121                	addi	sp,sp,64
    8000541a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000541c:	85d6                	mv	a1,s5
    8000541e:	8552                	mv	a0,s4
    80005420:	00000097          	auipc	ra,0x0
    80005424:	34c080e7          	jalr	844(ra) # 8000576c <pipeclose>
    80005428:	b7cd                	j	8000540a <fileclose+0xa8>

000000008000542a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000542a:	715d                	addi	sp,sp,-80
    8000542c:	e486                	sd	ra,72(sp)
    8000542e:	e0a2                	sd	s0,64(sp)
    80005430:	fc26                	sd	s1,56(sp)
    80005432:	f84a                	sd	s2,48(sp)
    80005434:	f44e                	sd	s3,40(sp)
    80005436:	0880                	addi	s0,sp,80
    80005438:	84aa                	mv	s1,a0
    8000543a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	5f6080e7          	jalr	1526(ra) # 80001a32 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005444:	409c                	lw	a5,0(s1)
    80005446:	37f9                	addiw	a5,a5,-2
    80005448:	4705                	li	a4,1
    8000544a:	04f76763          	bltu	a4,a5,80005498 <filestat+0x6e>
    8000544e:	892a                	mv	s2,a0
    ilock(f->ip);
    80005450:	6c88                	ld	a0,24(s1)
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	06e080e7          	jalr	110(ra) # 800044c0 <ilock>
    stati(f->ip, &st);
    8000545a:	fb840593          	addi	a1,s0,-72
    8000545e:	6c88                	ld	a0,24(s1)
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	2ea080e7          	jalr	746(ra) # 8000474a <stati>
    iunlock(f->ip);
    80005468:	6c88                	ld	a0,24(s1)
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	118080e7          	jalr	280(ra) # 80004582 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005472:	46e1                	li	a3,24
    80005474:	fb840613          	addi	a2,s0,-72
    80005478:	85ce                	mv	a1,s3
    8000547a:	1d893503          	ld	a0,472(s2)
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	1e4080e7          	jalr	484(ra) # 80001662 <copyout>
    80005486:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000548a:	60a6                	ld	ra,72(sp)
    8000548c:	6406                	ld	s0,64(sp)
    8000548e:	74e2                	ld	s1,56(sp)
    80005490:	7942                	ld	s2,48(sp)
    80005492:	79a2                	ld	s3,40(sp)
    80005494:	6161                	addi	sp,sp,80
    80005496:	8082                	ret
  return -1;
    80005498:	557d                	li	a0,-1
    8000549a:	bfc5                	j	8000548a <filestat+0x60>

000000008000549c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000549c:	7179                	addi	sp,sp,-48
    8000549e:	f406                	sd	ra,40(sp)
    800054a0:	f022                	sd	s0,32(sp)
    800054a2:	ec26                	sd	s1,24(sp)
    800054a4:	e84a                	sd	s2,16(sp)
    800054a6:	e44e                	sd	s3,8(sp)
    800054a8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800054aa:	00854783          	lbu	a5,8(a0)
    800054ae:	c3d5                	beqz	a5,80005552 <fileread+0xb6>
    800054b0:	84aa                	mv	s1,a0
    800054b2:	89ae                	mv	s3,a1
    800054b4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800054b6:	411c                	lw	a5,0(a0)
    800054b8:	4705                	li	a4,1
    800054ba:	04e78963          	beq	a5,a4,8000550c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054be:	470d                	li	a4,3
    800054c0:	04e78d63          	beq	a5,a4,8000551a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800054c4:	4709                	li	a4,2
    800054c6:	06e79e63          	bne	a5,a4,80005542 <fileread+0xa6>
    ilock(f->ip);
    800054ca:	6d08                	ld	a0,24(a0)
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	ff4080e7          	jalr	-12(ra) # 800044c0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800054d4:	874a                	mv	a4,s2
    800054d6:	5094                	lw	a3,32(s1)
    800054d8:	864e                	mv	a2,s3
    800054da:	4585                	li	a1,1
    800054dc:	6c88                	ld	a0,24(s1)
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	296080e7          	jalr	662(ra) # 80004774 <readi>
    800054e6:	892a                	mv	s2,a0
    800054e8:	00a05563          	blez	a0,800054f2 <fileread+0x56>
      f->off += r;
    800054ec:	509c                	lw	a5,32(s1)
    800054ee:	9fa9                	addw	a5,a5,a0
    800054f0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800054f2:	6c88                	ld	a0,24(s1)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	08e080e7          	jalr	142(ra) # 80004582 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800054fc:	854a                	mv	a0,s2
    800054fe:	70a2                	ld	ra,40(sp)
    80005500:	7402                	ld	s0,32(sp)
    80005502:	64e2                	ld	s1,24(sp)
    80005504:	6942                	ld	s2,16(sp)
    80005506:	69a2                	ld	s3,8(sp)
    80005508:	6145                	addi	sp,sp,48
    8000550a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000550c:	6908                	ld	a0,16(a0)
    8000550e:	00000097          	auipc	ra,0x0
    80005512:	3c0080e7          	jalr	960(ra) # 800058ce <piperead>
    80005516:	892a                	mv	s2,a0
    80005518:	b7d5                	j	800054fc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000551a:	02451783          	lh	a5,36(a0)
    8000551e:	03079693          	slli	a3,a5,0x30
    80005522:	92c1                	srli	a3,a3,0x30
    80005524:	4725                	li	a4,9
    80005526:	02d76863          	bltu	a4,a3,80005556 <fileread+0xba>
    8000552a:	0792                	slli	a5,a5,0x4
    8000552c:	00039717          	auipc	a4,0x39
    80005530:	41c70713          	addi	a4,a4,1052 # 8003e948 <devsw>
    80005534:	97ba                	add	a5,a5,a4
    80005536:	639c                	ld	a5,0(a5)
    80005538:	c38d                	beqz	a5,8000555a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000553a:	4505                	li	a0,1
    8000553c:	9782                	jalr	a5
    8000553e:	892a                	mv	s2,a0
    80005540:	bf75                	j	800054fc <fileread+0x60>
    panic("fileread");
    80005542:	00004517          	auipc	a0,0x4
    80005546:	1ce50513          	addi	a0,a0,462 # 80009710 <syscalls+0x2b0>
    8000554a:	ffffb097          	auipc	ra,0xffffb
    8000554e:	fe0080e7          	jalr	-32(ra) # 8000052a <panic>
    return -1;
    80005552:	597d                	li	s2,-1
    80005554:	b765                	j	800054fc <fileread+0x60>
      return -1;
    80005556:	597d                	li	s2,-1
    80005558:	b755                	j	800054fc <fileread+0x60>
    8000555a:	597d                	li	s2,-1
    8000555c:	b745                	j	800054fc <fileread+0x60>

000000008000555e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000555e:	715d                	addi	sp,sp,-80
    80005560:	e486                	sd	ra,72(sp)
    80005562:	e0a2                	sd	s0,64(sp)
    80005564:	fc26                	sd	s1,56(sp)
    80005566:	f84a                	sd	s2,48(sp)
    80005568:	f44e                	sd	s3,40(sp)
    8000556a:	f052                	sd	s4,32(sp)
    8000556c:	ec56                	sd	s5,24(sp)
    8000556e:	e85a                	sd	s6,16(sp)
    80005570:	e45e                	sd	s7,8(sp)
    80005572:	e062                	sd	s8,0(sp)
    80005574:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005576:	00954783          	lbu	a5,9(a0)
    8000557a:	10078663          	beqz	a5,80005686 <filewrite+0x128>
    8000557e:	892a                	mv	s2,a0
    80005580:	8aae                	mv	s5,a1
    80005582:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005584:	411c                	lw	a5,0(a0)
    80005586:	4705                	li	a4,1
    80005588:	02e78263          	beq	a5,a4,800055ac <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000558c:	470d                	li	a4,3
    8000558e:	02e78663          	beq	a5,a4,800055ba <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005592:	4709                	li	a4,2
    80005594:	0ee79163          	bne	a5,a4,80005676 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005598:	0ac05d63          	blez	a2,80005652 <filewrite+0xf4>
    int i = 0;
    8000559c:	4981                	li	s3,0
    8000559e:	6b05                	lui	s6,0x1
    800055a0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800055a4:	6b85                	lui	s7,0x1
    800055a6:	c00b8b9b          	addiw	s7,s7,-1024
    800055aa:	a861                	j	80005642 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800055ac:	6908                	ld	a0,16(a0)
    800055ae:	00000097          	auipc	ra,0x0
    800055b2:	22e080e7          	jalr	558(ra) # 800057dc <pipewrite>
    800055b6:	8a2a                	mv	s4,a0
    800055b8:	a045                	j	80005658 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800055ba:	02451783          	lh	a5,36(a0)
    800055be:	03079693          	slli	a3,a5,0x30
    800055c2:	92c1                	srli	a3,a3,0x30
    800055c4:	4725                	li	a4,9
    800055c6:	0cd76263          	bltu	a4,a3,8000568a <filewrite+0x12c>
    800055ca:	0792                	slli	a5,a5,0x4
    800055cc:	00039717          	auipc	a4,0x39
    800055d0:	37c70713          	addi	a4,a4,892 # 8003e948 <devsw>
    800055d4:	97ba                	add	a5,a5,a4
    800055d6:	679c                	ld	a5,8(a5)
    800055d8:	cbdd                	beqz	a5,8000568e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800055da:	4505                	li	a0,1
    800055dc:	9782                	jalr	a5
    800055de:	8a2a                	mv	s4,a0
    800055e0:	a8a5                	j	80005658 <filewrite+0xfa>
    800055e2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800055e6:	00000097          	auipc	ra,0x0
    800055ea:	8b0080e7          	jalr	-1872(ra) # 80004e96 <begin_op>
      ilock(f->ip);
    800055ee:	01893503          	ld	a0,24(s2)
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	ece080e7          	jalr	-306(ra) # 800044c0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800055fa:	8762                	mv	a4,s8
    800055fc:	02092683          	lw	a3,32(s2)
    80005600:	01598633          	add	a2,s3,s5
    80005604:	4585                	li	a1,1
    80005606:	01893503          	ld	a0,24(s2)
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	262080e7          	jalr	610(ra) # 8000486c <writei>
    80005612:	84aa                	mv	s1,a0
    80005614:	00a05763          	blez	a0,80005622 <filewrite+0xc4>
        f->off += r;
    80005618:	02092783          	lw	a5,32(s2)
    8000561c:	9fa9                	addw	a5,a5,a0
    8000561e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005622:	01893503          	ld	a0,24(s2)
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	f5c080e7          	jalr	-164(ra) # 80004582 <iunlock>
      end_op();
    8000562e:	00000097          	auipc	ra,0x0
    80005632:	8e8080e7          	jalr	-1816(ra) # 80004f16 <end_op>

      if(r != n1){
    80005636:	009c1f63          	bne	s8,s1,80005654 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000563a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000563e:	0149db63          	bge	s3,s4,80005654 <filewrite+0xf6>
      int n1 = n - i;
    80005642:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005646:	84be                	mv	s1,a5
    80005648:	2781                	sext.w	a5,a5
    8000564a:	f8fb5ce3          	bge	s6,a5,800055e2 <filewrite+0x84>
    8000564e:	84de                	mv	s1,s7
    80005650:	bf49                	j	800055e2 <filewrite+0x84>
    int i = 0;
    80005652:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005654:	013a1f63          	bne	s4,s3,80005672 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005658:	8552                	mv	a0,s4
    8000565a:	60a6                	ld	ra,72(sp)
    8000565c:	6406                	ld	s0,64(sp)
    8000565e:	74e2                	ld	s1,56(sp)
    80005660:	7942                	ld	s2,48(sp)
    80005662:	79a2                	ld	s3,40(sp)
    80005664:	7a02                	ld	s4,32(sp)
    80005666:	6ae2                	ld	s5,24(sp)
    80005668:	6b42                	ld	s6,16(sp)
    8000566a:	6ba2                	ld	s7,8(sp)
    8000566c:	6c02                	ld	s8,0(sp)
    8000566e:	6161                	addi	sp,sp,80
    80005670:	8082                	ret
    ret = (i == n ? n : -1);
    80005672:	5a7d                	li	s4,-1
    80005674:	b7d5                	j	80005658 <filewrite+0xfa>
    panic("filewrite");
    80005676:	00004517          	auipc	a0,0x4
    8000567a:	0aa50513          	addi	a0,a0,170 # 80009720 <syscalls+0x2c0>
    8000567e:	ffffb097          	auipc	ra,0xffffb
    80005682:	eac080e7          	jalr	-340(ra) # 8000052a <panic>
    return -1;
    80005686:	5a7d                	li	s4,-1
    80005688:	bfc1                	j	80005658 <filewrite+0xfa>
      return -1;
    8000568a:	5a7d                	li	s4,-1
    8000568c:	b7f1                	j	80005658 <filewrite+0xfa>
    8000568e:	5a7d                	li	s4,-1
    80005690:	b7e1                	j	80005658 <filewrite+0xfa>

0000000080005692 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005692:	7179                	addi	sp,sp,-48
    80005694:	f406                	sd	ra,40(sp)
    80005696:	f022                	sd	s0,32(sp)
    80005698:	ec26                	sd	s1,24(sp)
    8000569a:	e84a                	sd	s2,16(sp)
    8000569c:	e44e                	sd	s3,8(sp)
    8000569e:	e052                	sd	s4,0(sp)
    800056a0:	1800                	addi	s0,sp,48
    800056a2:	84aa                	mv	s1,a0
    800056a4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800056a6:	0005b023          	sd	zero,0(a1)
    800056aa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800056ae:	00000097          	auipc	ra,0x0
    800056b2:	bf8080e7          	jalr	-1032(ra) # 800052a6 <filealloc>
    800056b6:	e088                	sd	a0,0(s1)
    800056b8:	c551                	beqz	a0,80005744 <pipealloc+0xb2>
    800056ba:	00000097          	auipc	ra,0x0
    800056be:	bec080e7          	jalr	-1044(ra) # 800052a6 <filealloc>
    800056c2:	00aa3023          	sd	a0,0(s4)
    800056c6:	c92d                	beqz	a0,80005738 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800056c8:	ffffb097          	auipc	ra,0xffffb
    800056cc:	40a080e7          	jalr	1034(ra) # 80000ad2 <kalloc>
    800056d0:	892a                	mv	s2,a0
    800056d2:	c125                	beqz	a0,80005732 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800056d4:	4985                	li	s3,1
    800056d6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800056da:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800056de:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800056e2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800056e6:	00004597          	auipc	a1,0x4
    800056ea:	04a58593          	addi	a1,a1,74 # 80009730 <syscalls+0x2d0>
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	444080e7          	jalr	1092(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800056f6:	609c                	ld	a5,0(s1)
    800056f8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800056fc:	609c                	ld	a5,0(s1)
    800056fe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005702:	609c                	ld	a5,0(s1)
    80005704:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005708:	609c                	ld	a5,0(s1)
    8000570a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000570e:	000a3783          	ld	a5,0(s4)
    80005712:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005716:	000a3783          	ld	a5,0(s4)
    8000571a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000571e:	000a3783          	ld	a5,0(s4)
    80005722:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005726:	000a3783          	ld	a5,0(s4)
    8000572a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000572e:	4501                	li	a0,0
    80005730:	a025                	j	80005758 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005732:	6088                	ld	a0,0(s1)
    80005734:	e501                	bnez	a0,8000573c <pipealloc+0xaa>
    80005736:	a039                	j	80005744 <pipealloc+0xb2>
    80005738:	6088                	ld	a0,0(s1)
    8000573a:	c51d                	beqz	a0,80005768 <pipealloc+0xd6>
    fileclose(*f0);
    8000573c:	00000097          	auipc	ra,0x0
    80005740:	c26080e7          	jalr	-986(ra) # 80005362 <fileclose>
  if(*f1)
    80005744:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005748:	557d                	li	a0,-1
  if(*f1)
    8000574a:	c799                	beqz	a5,80005758 <pipealloc+0xc6>
    fileclose(*f1);
    8000574c:	853e                	mv	a0,a5
    8000574e:	00000097          	auipc	ra,0x0
    80005752:	c14080e7          	jalr	-1004(ra) # 80005362 <fileclose>
  return -1;
    80005756:	557d                	li	a0,-1
}
    80005758:	70a2                	ld	ra,40(sp)
    8000575a:	7402                	ld	s0,32(sp)
    8000575c:	64e2                	ld	s1,24(sp)
    8000575e:	6942                	ld	s2,16(sp)
    80005760:	69a2                	ld	s3,8(sp)
    80005762:	6a02                	ld	s4,0(sp)
    80005764:	6145                	addi	sp,sp,48
    80005766:	8082                	ret
  return -1;
    80005768:	557d                	li	a0,-1
    8000576a:	b7fd                	j	80005758 <pipealloc+0xc6>

000000008000576c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000576c:	1101                	addi	sp,sp,-32
    8000576e:	ec06                	sd	ra,24(sp)
    80005770:	e822                	sd	s0,16(sp)
    80005772:	e426                	sd	s1,8(sp)
    80005774:	e04a                	sd	s2,0(sp)
    80005776:	1000                	addi	s0,sp,32
    80005778:	84aa                	mv	s1,a0
    8000577a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000577c:	ffffb097          	auipc	ra,0xffffb
    80005780:	446080e7          	jalr	1094(ra) # 80000bc2 <acquire>
  if(writable){
    80005784:	02090d63          	beqz	s2,800057be <pipeclose+0x52>
    pi->writeopen = 0;
    80005788:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000578c:	21848513          	addi	a0,s1,536
    80005790:	ffffd097          	auipc	ra,0xffffd
    80005794:	0d2080e7          	jalr	210(ra) # 80002862 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005798:	2204b783          	ld	a5,544(s1)
    8000579c:	eb95                	bnez	a5,800057d0 <pipeclose+0x64>
    release(&pi->lock);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffb097          	auipc	ra,0xffffb
    800057a4:	4e8080e7          	jalr	1256(ra) # 80000c88 <release>
    kfree((char*)pi);
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffb097          	auipc	ra,0xffffb
    800057ae:	22c080e7          	jalr	556(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800057b2:	60e2                	ld	ra,24(sp)
    800057b4:	6442                	ld	s0,16(sp)
    800057b6:	64a2                	ld	s1,8(sp)
    800057b8:	6902                	ld	s2,0(sp)
    800057ba:	6105                	addi	sp,sp,32
    800057bc:	8082                	ret
    pi->readopen = 0;
    800057be:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800057c2:	21c48513          	addi	a0,s1,540
    800057c6:	ffffd097          	auipc	ra,0xffffd
    800057ca:	09c080e7          	jalr	156(ra) # 80002862 <wakeup>
    800057ce:	b7e9                	j	80005798 <pipeclose+0x2c>
    release(&pi->lock);
    800057d0:	8526                	mv	a0,s1
    800057d2:	ffffb097          	auipc	ra,0xffffb
    800057d6:	4b6080e7          	jalr	1206(ra) # 80000c88 <release>
}
    800057da:	bfe1                	j	800057b2 <pipeclose+0x46>

00000000800057dc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800057dc:	711d                	addi	sp,sp,-96
    800057de:	ec86                	sd	ra,88(sp)
    800057e0:	e8a2                	sd	s0,80(sp)
    800057e2:	e4a6                	sd	s1,72(sp)
    800057e4:	e0ca                	sd	s2,64(sp)
    800057e6:	fc4e                	sd	s3,56(sp)
    800057e8:	f852                	sd	s4,48(sp)
    800057ea:	f456                	sd	s5,40(sp)
    800057ec:	f05a                	sd	s6,32(sp)
    800057ee:	ec5e                	sd	s7,24(sp)
    800057f0:	e862                	sd	s8,16(sp)
    800057f2:	1080                	addi	s0,sp,96
    800057f4:	84aa                	mv	s1,a0
    800057f6:	8aae                	mv	s5,a1
    800057f8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800057fa:	ffffc097          	auipc	ra,0xffffc
    800057fe:	238080e7          	jalr	568(ra) # 80001a32 <myproc>
    80005802:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005804:	8526                	mv	a0,s1
    80005806:	ffffb097          	auipc	ra,0xffffb
    8000580a:	3bc080e7          	jalr	956(ra) # 80000bc2 <acquire>
  while(i < n){
    8000580e:	0b405363          	blez	s4,800058b4 <pipewrite+0xd8>
  int i = 0;
    80005812:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005814:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005816:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000581a:	21c48b93          	addi	s7,s1,540
    8000581e:	a089                	j	80005860 <pipewrite+0x84>
      release(&pi->lock);
    80005820:	8526                	mv	a0,s1
    80005822:	ffffb097          	auipc	ra,0xffffb
    80005826:	466080e7          	jalr	1126(ra) # 80000c88 <release>
      return -1;
    8000582a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000582c:	854a                	mv	a0,s2
    8000582e:	60e6                	ld	ra,88(sp)
    80005830:	6446                	ld	s0,80(sp)
    80005832:	64a6                	ld	s1,72(sp)
    80005834:	6906                	ld	s2,64(sp)
    80005836:	79e2                	ld	s3,56(sp)
    80005838:	7a42                	ld	s4,48(sp)
    8000583a:	7aa2                	ld	s5,40(sp)
    8000583c:	7b02                	ld	s6,32(sp)
    8000583e:	6be2                	ld	s7,24(sp)
    80005840:	6c42                	ld	s8,16(sp)
    80005842:	6125                	addi	sp,sp,96
    80005844:	8082                	ret
      wakeup(&pi->nread);
    80005846:	8562                	mv	a0,s8
    80005848:	ffffd097          	auipc	ra,0xffffd
    8000584c:	01a080e7          	jalr	26(ra) # 80002862 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005850:	85a6                	mv	a1,s1
    80005852:	855e                	mv	a0,s7
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	e84080e7          	jalr	-380(ra) # 800026d8 <sleep>
  while(i < n){
    8000585c:	05495d63          	bge	s2,s4,800058b6 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005860:	2204a783          	lw	a5,544(s1)
    80005864:	dfd5                	beqz	a5,80005820 <pipewrite+0x44>
    80005866:	01c9a783          	lw	a5,28(s3)
    8000586a:	fbdd                	bnez	a5,80005820 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000586c:	2184a783          	lw	a5,536(s1)
    80005870:	21c4a703          	lw	a4,540(s1)
    80005874:	2007879b          	addiw	a5,a5,512
    80005878:	fcf707e3          	beq	a4,a5,80005846 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000587c:	4685                	li	a3,1
    8000587e:	01590633          	add	a2,s2,s5
    80005882:	faf40593          	addi	a1,s0,-81
    80005886:	1d89b503          	ld	a0,472(s3)
    8000588a:	ffffc097          	auipc	ra,0xffffc
    8000588e:	e64080e7          	jalr	-412(ra) # 800016ee <copyin>
    80005892:	03650263          	beq	a0,s6,800058b6 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005896:	21c4a783          	lw	a5,540(s1)
    8000589a:	0017871b          	addiw	a4,a5,1
    8000589e:	20e4ae23          	sw	a4,540(s1)
    800058a2:	1ff7f793          	andi	a5,a5,511
    800058a6:	97a6                	add	a5,a5,s1
    800058a8:	faf44703          	lbu	a4,-81(s0)
    800058ac:	00e78c23          	sb	a4,24(a5)
      i++;
    800058b0:	2905                	addiw	s2,s2,1
    800058b2:	b76d                	j	8000585c <pipewrite+0x80>
  int i = 0;
    800058b4:	4901                	li	s2,0
  wakeup(&pi->nread);
    800058b6:	21848513          	addi	a0,s1,536
    800058ba:	ffffd097          	auipc	ra,0xffffd
    800058be:	fa8080e7          	jalr	-88(ra) # 80002862 <wakeup>
  release(&pi->lock);
    800058c2:	8526                	mv	a0,s1
    800058c4:	ffffb097          	auipc	ra,0xffffb
    800058c8:	3c4080e7          	jalr	964(ra) # 80000c88 <release>
  return i;
    800058cc:	b785                	j	8000582c <pipewrite+0x50>

00000000800058ce <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800058ce:	715d                	addi	sp,sp,-80
    800058d0:	e486                	sd	ra,72(sp)
    800058d2:	e0a2                	sd	s0,64(sp)
    800058d4:	fc26                	sd	s1,56(sp)
    800058d6:	f84a                	sd	s2,48(sp)
    800058d8:	f44e                	sd	s3,40(sp)
    800058da:	f052                	sd	s4,32(sp)
    800058dc:	ec56                	sd	s5,24(sp)
    800058de:	e85a                	sd	s6,16(sp)
    800058e0:	0880                	addi	s0,sp,80
    800058e2:	84aa                	mv	s1,a0
    800058e4:	892e                	mv	s2,a1
    800058e6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800058e8:	ffffc097          	auipc	ra,0xffffc
    800058ec:	14a080e7          	jalr	330(ra) # 80001a32 <myproc>
    800058f0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffb097          	auipc	ra,0xffffb
    800058f8:	2ce080e7          	jalr	718(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058fc:	2184a703          	lw	a4,536(s1)
    80005900:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005904:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005908:	02f71463          	bne	a4,a5,80005930 <piperead+0x62>
    8000590c:	2244a783          	lw	a5,548(s1)
    80005910:	c385                	beqz	a5,80005930 <piperead+0x62>
    if(pr->killed){
    80005912:	01ca2783          	lw	a5,28(s4)
    80005916:	ebc1                	bnez	a5,800059a6 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005918:	85a6                	mv	a1,s1
    8000591a:	854e                	mv	a0,s3
    8000591c:	ffffd097          	auipc	ra,0xffffd
    80005920:	dbc080e7          	jalr	-580(ra) # 800026d8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005924:	2184a703          	lw	a4,536(s1)
    80005928:	21c4a783          	lw	a5,540(s1)
    8000592c:	fef700e3          	beq	a4,a5,8000590c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005930:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005932:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005934:	05505363          	blez	s5,8000597a <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005938:	2184a783          	lw	a5,536(s1)
    8000593c:	21c4a703          	lw	a4,540(s1)
    80005940:	02f70d63          	beq	a4,a5,8000597a <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005944:	0017871b          	addiw	a4,a5,1
    80005948:	20e4ac23          	sw	a4,536(s1)
    8000594c:	1ff7f793          	andi	a5,a5,511
    80005950:	97a6                	add	a5,a5,s1
    80005952:	0187c783          	lbu	a5,24(a5)
    80005956:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000595a:	4685                	li	a3,1
    8000595c:	fbf40613          	addi	a2,s0,-65
    80005960:	85ca                	mv	a1,s2
    80005962:	1d8a3503          	ld	a0,472(s4)
    80005966:	ffffc097          	auipc	ra,0xffffc
    8000596a:	cfc080e7          	jalr	-772(ra) # 80001662 <copyout>
    8000596e:	01650663          	beq	a0,s6,8000597a <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005972:	2985                	addiw	s3,s3,1
    80005974:	0905                	addi	s2,s2,1
    80005976:	fd3a91e3          	bne	s5,s3,80005938 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000597a:	21c48513          	addi	a0,s1,540
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	ee4080e7          	jalr	-284(ra) # 80002862 <wakeup>
  release(&pi->lock);
    80005986:	8526                	mv	a0,s1
    80005988:	ffffb097          	auipc	ra,0xffffb
    8000598c:	300080e7          	jalr	768(ra) # 80000c88 <release>
  return i;
}
    80005990:	854e                	mv	a0,s3
    80005992:	60a6                	ld	ra,72(sp)
    80005994:	6406                	ld	s0,64(sp)
    80005996:	74e2                	ld	s1,56(sp)
    80005998:	7942                	ld	s2,48(sp)
    8000599a:	79a2                	ld	s3,40(sp)
    8000599c:	7a02                	ld	s4,32(sp)
    8000599e:	6ae2                	ld	s5,24(sp)
    800059a0:	6b42                	ld	s6,16(sp)
    800059a2:	6161                	addi	sp,sp,80
    800059a4:	8082                	ret
      release(&pi->lock);
    800059a6:	8526                	mv	a0,s1
    800059a8:	ffffb097          	auipc	ra,0xffffb
    800059ac:	2e0080e7          	jalr	736(ra) # 80000c88 <release>
      return -1;
    800059b0:	59fd                	li	s3,-1
    800059b2:	bff9                	j	80005990 <piperead+0xc2>

00000000800059b4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800059b4:	dd010113          	addi	sp,sp,-560
    800059b8:	22113423          	sd	ra,552(sp)
    800059bc:	22813023          	sd	s0,544(sp)
    800059c0:	20913c23          	sd	s1,536(sp)
    800059c4:	21213823          	sd	s2,528(sp)
    800059c8:	21313423          	sd	s3,520(sp)
    800059cc:	21413023          	sd	s4,512(sp)
    800059d0:	ffd6                	sd	s5,504(sp)
    800059d2:	fbda                	sd	s6,496(sp)
    800059d4:	f7de                	sd	s7,488(sp)
    800059d6:	f3e2                	sd	s8,480(sp)
    800059d8:	efe6                	sd	s9,472(sp)
    800059da:	ebea                	sd	s10,464(sp)
    800059dc:	e7ee                	sd	s11,456(sp)
    800059de:	1c00                	addi	s0,sp,560
    800059e0:	dea43823          	sd	a0,-528(s0)
    800059e4:	deb43023          	sd	a1,-544(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800059e8:	ffffc097          	auipc	ra,0xffffc
    800059ec:	04a080e7          	jalr	74(ra) # 80001a32 <myproc>
    800059f0:	89aa                	mv	s3,a0
  struct thread *t = mythread();
    800059f2:	ffffc097          	auipc	ra,0xffffc
    800059f6:	07a080e7          	jalr	122(ra) # 80001a6c <mythread>
    800059fa:	e0a43423          	sd	a0,-504(s0)

  // ADDED Q3
  for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    800059fe:	27898493          	addi	s1,s3,632
    80005a02:	6905                	lui	s2,0x1
    80005a04:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    80005a08:	994e                	add	s2,s2,s3
    if(t_temp->tid != t->tid){
      acquire(&t_temp->lock);
      t_temp->terminated = 1;
    80005a0a:	4a85                	li	s5,1
      if(t_temp->state == SLEEPING){
    80005a0c:	4a09                	li	s4,2
        t_temp->state = RUNNABLE;
    80005a0e:	4b0d                	li	s6,3
    80005a10:	a015                	j	80005a34 <exec+0x80>
    80005a12:	0164ac23          	sw	s6,24(s1)
      }
      release(&t_temp->lock);
    80005a16:	8526                	mv	a0,s1
    80005a18:	ffffb097          	auipc	ra,0xffffb
    80005a1c:	270080e7          	jalr	624(ra) # 80000c88 <release>
      kthread_join(t_temp->tid, 0);
    80005a20:	4581                	li	a1,0
    80005a22:	5888                	lw	a0,48(s1)
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	42e080e7          	jalr	1070(ra) # 80002e52 <kthread_join>
  for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    80005a2c:	0c048493          	addi	s1,s1,192
    80005a30:	03248363          	beq	s1,s2,80005a56 <exec+0xa2>
    if(t_temp->tid != t->tid){
    80005a34:	5898                	lw	a4,48(s1)
    80005a36:	e0843783          	ld	a5,-504(s0)
    80005a3a:	5b9c                	lw	a5,48(a5)
    80005a3c:	fef708e3          	beq	a4,a5,80005a2c <exec+0x78>
      acquire(&t_temp->lock);
    80005a40:	8526                	mv	a0,s1
    80005a42:	ffffb097          	auipc	ra,0xffffb
    80005a46:	180080e7          	jalr	384(ra) # 80000bc2 <acquire>
      t_temp->terminated = 1;
    80005a4a:	0354a423          	sw	s5,40(s1)
      if(t_temp->state == SLEEPING){
    80005a4e:	4c9c                	lw	a5,24(s1)
    80005a50:	fd4793e3          	bne	a5,s4,80005a16 <exec+0x62>
    80005a54:	bf7d                	j	80005a12 <exec+0x5e>
    }
  }

  begin_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	440080e7          	jalr	1088(ra) # 80004e96 <begin_op>

  if((ip = namei(path)) == 0){
    80005a5e:	df043503          	ld	a0,-528(s0)
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	214080e7          	jalr	532(ra) # 80004c76 <namei>
    80005a6a:	8aaa                	mv	s5,a0
    80005a6c:	cd25                	beqz	a0,80005ae4 <exec+0x130>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	a52080e7          	jalr	-1454(ra) # 800044c0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005a76:	04000713          	li	a4,64
    80005a7a:	4681                	li	a3,0
    80005a7c:	e4840613          	addi	a2,s0,-440
    80005a80:	4581                	li	a1,0
    80005a82:	8556                	mv	a0,s5
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	cf0080e7          	jalr	-784(ra) # 80004774 <readi>
    80005a8c:	04000793          	li	a5,64
    80005a90:	00f51a63          	bne	a0,a5,80005aa4 <exec+0xf0>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005a94:	e4842703          	lw	a4,-440(s0)
    80005a98:	464c47b7          	lui	a5,0x464c4
    80005a9c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005aa0:	04f70863          	beq	a4,a5,80005af0 <exec+0x13c>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005aa4:	8556                	mv	a0,s5
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	c7c080e7          	jalr	-900(ra) # 80004722 <iunlockput>
    end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	468080e7          	jalr	1128(ra) # 80004f16 <end_op>
  }
  return -1;
    80005ab6:	557d                	li	a0,-1
}
    80005ab8:	22813083          	ld	ra,552(sp)
    80005abc:	22013403          	ld	s0,544(sp)
    80005ac0:	21813483          	ld	s1,536(sp)
    80005ac4:	21013903          	ld	s2,528(sp)
    80005ac8:	20813983          	ld	s3,520(sp)
    80005acc:	20013a03          	ld	s4,512(sp)
    80005ad0:	7afe                	ld	s5,504(sp)
    80005ad2:	7b5e                	ld	s6,496(sp)
    80005ad4:	7bbe                	ld	s7,488(sp)
    80005ad6:	7c1e                	ld	s8,480(sp)
    80005ad8:	6cfe                	ld	s9,472(sp)
    80005ada:	6d5e                	ld	s10,464(sp)
    80005adc:	6dbe                	ld	s11,456(sp)
    80005ade:	23010113          	addi	sp,sp,560
    80005ae2:	8082                	ret
    end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	432080e7          	jalr	1074(ra) # 80004f16 <end_op>
    return -1;
    80005aec:	557d                	li	a0,-1
    80005aee:	b7e9                	j	80005ab8 <exec+0x104>
  if((pagetable = proc_pagetable(p)) == 0)
    80005af0:	854e                	mv	a0,s3
    80005af2:	ffffc097          	auipc	ra,0xffffc
    80005af6:	162080e7          	jalr	354(ra) # 80001c54 <proc_pagetable>
    80005afa:	8b2a                	mv	s6,a0
    80005afc:	d545                	beqz	a0,80005aa4 <exec+0xf0>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005afe:	e6842783          	lw	a5,-408(s0)
    80005b02:	e8045703          	lhu	a4,-384(s0)
    80005b06:	c735                	beqz	a4,80005b72 <exec+0x1be>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b08:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b0a:	e0043023          	sd	zero,-512(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005b0e:	6a05                	lui	s4,0x1
    80005b10:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005b14:	dce43c23          	sd	a4,-552(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005b18:	6d85                	lui	s11,0x1
    80005b1a:	7d7d                	lui	s10,0xfffff
    80005b1c:	a485                	j	80005d7c <exec+0x3c8>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005b1e:	00004517          	auipc	a0,0x4
    80005b22:	c1a50513          	addi	a0,a0,-998 # 80009738 <syscalls+0x2d8>
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	a04080e7          	jalr	-1532(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005b2e:	874a                	mv	a4,s2
    80005b30:	009c86bb          	addw	a3,s9,s1
    80005b34:	4581                	li	a1,0
    80005b36:	8556                	mv	a0,s5
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	c3c080e7          	jalr	-964(ra) # 80004774 <readi>
    80005b40:	2501                	sext.w	a0,a0
    80005b42:	1ca91d63          	bne	s2,a0,80005d1c <exec+0x368>
  for(i = 0; i < sz; i += PGSIZE){
    80005b46:	009d84bb          	addw	s1,s11,s1
    80005b4a:	013d09bb          	addw	s3,s10,s3
    80005b4e:	2174f763          	bgeu	s1,s7,80005d5c <exec+0x3a8>
    pa = walkaddr(pagetable, va + i);
    80005b52:	02049593          	slli	a1,s1,0x20
    80005b56:	9181                	srli	a1,a1,0x20
    80005b58:	95e2                	add	a1,a1,s8
    80005b5a:	855a                	mv	a0,s6
    80005b5c:	ffffb097          	auipc	ra,0xffffb
    80005b60:	514080e7          	jalr	1300(ra) # 80001070 <walkaddr>
    80005b64:	862a                	mv	a2,a0
    if(pa == 0)
    80005b66:	dd45                	beqz	a0,80005b1e <exec+0x16a>
      n = PGSIZE;
    80005b68:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005b6a:	fd49f2e3          	bgeu	s3,s4,80005b2e <exec+0x17a>
      n = sz - i;
    80005b6e:	894e                	mv	s2,s3
    80005b70:	bf7d                	j	80005b2e <exec+0x17a>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b72:	4481                	li	s1,0
  iunlockput(ip);
    80005b74:	8556                	mv	a0,s5
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	bac080e7          	jalr	-1108(ra) # 80004722 <iunlockput>
  end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	398080e7          	jalr	920(ra) # 80004f16 <end_op>
  p = myproc();
    80005b86:	ffffc097          	auipc	ra,0xffffc
    80005b8a:	eac080e7          	jalr	-340(ra) # 80001a32 <myproc>
    80005b8e:	8a2a                	mv	s4,a0
  uint64 oldsz = p->sz;
    80005b90:	1d053d03          	ld	s10,464(a0)
  sz = PGROUNDUP(sz);
    80005b94:	6785                	lui	a5,0x1
    80005b96:	17fd                	addi	a5,a5,-1
    80005b98:	94be                	add	s1,s1,a5
    80005b9a:	77fd                	lui	a5,0xfffff
    80005b9c:	8fe5                	and	a5,a5,s1
    80005b9e:	def43423          	sd	a5,-536(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005ba2:	6609                	lui	a2,0x2
    80005ba4:	963e                	add	a2,a2,a5
    80005ba6:	85be                	mv	a1,a5
    80005ba8:	855a                	mv	a0,s6
    80005baa:	ffffc097          	auipc	ra,0xffffc
    80005bae:	868080e7          	jalr	-1944(ra) # 80001412 <uvmalloc>
    80005bb2:	8caa                	mv	s9,a0
  ip = 0;
    80005bb4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005bb6:	16050363          	beqz	a0,80005d1c <exec+0x368>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005bba:	75f9                	lui	a1,0xffffe
    80005bbc:	95aa                	add	a1,a1,a0
    80005bbe:	855a                	mv	a0,s6
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	a70080e7          	jalr	-1424(ra) # 80001630 <uvmclear>
  stackbase = sp - PGSIZE;
    80005bc8:	7bfd                	lui	s7,0xfffff
    80005bca:	9be6                	add	s7,s7,s9
  for(argc = 0; argv[argc]; argc++) {
    80005bcc:	de043783          	ld	a5,-544(s0)
    80005bd0:	6388                	ld	a0,0(a5)
    80005bd2:	c925                	beqz	a0,80005c42 <exec+0x28e>
    80005bd4:	e8840993          	addi	s3,s0,-376
    80005bd8:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005bdc:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005bde:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005be0:	ffffb097          	auipc	ra,0xffffb
    80005be4:	286080e7          	jalr	646(ra) # 80000e66 <strlen>
    80005be8:	0015079b          	addiw	a5,a0,1
    80005bec:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005bf0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005bf4:	15796863          	bltu	s2,s7,80005d44 <exec+0x390>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005bf8:	de043d83          	ld	s11,-544(s0)
    80005bfc:	000dba83          	ld	s5,0(s11) # 1000 <_entry-0x7ffff000>
    80005c00:	8556                	mv	a0,s5
    80005c02:	ffffb097          	auipc	ra,0xffffb
    80005c06:	264080e7          	jalr	612(ra) # 80000e66 <strlen>
    80005c0a:	0015069b          	addiw	a3,a0,1
    80005c0e:	8656                	mv	a2,s5
    80005c10:	85ca                	mv	a1,s2
    80005c12:	855a                	mv	a0,s6
    80005c14:	ffffc097          	auipc	ra,0xffffc
    80005c18:	a4e080e7          	jalr	-1458(ra) # 80001662 <copyout>
    80005c1c:	12054863          	bltz	a0,80005d4c <exec+0x398>
    ustack[argc] = sp;
    80005c20:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005c24:	0485                	addi	s1,s1,1
    80005c26:	008d8793          	addi	a5,s11,8
    80005c2a:	def43023          	sd	a5,-544(s0)
    80005c2e:	008db503          	ld	a0,8(s11)
    80005c32:	c911                	beqz	a0,80005c46 <exec+0x292>
    if(argc >= MAXARG)
    80005c34:	09a1                	addi	s3,s3,8
    80005c36:	fb3c15e3          	bne	s8,s3,80005be0 <exec+0x22c>
  sz = sz1;
    80005c3a:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005c3e:	4a81                	li	s5,0
    80005c40:	a8f1                	j	80005d1c <exec+0x368>
  sp = sz;
    80005c42:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005c44:	4481                	li	s1,0
  ustack[argc] = 0;
    80005c46:	00349793          	slli	a5,s1,0x3
    80005c4a:	f9040713          	addi	a4,s0,-112
    80005c4e:	97ba                	add	a5,a5,a4
    80005c50:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffbbef8>
  sp -= (argc+1) * sizeof(uint64);
    80005c54:	00148693          	addi	a3,s1,1
    80005c58:	068e                	slli	a3,a3,0x3
    80005c5a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c5e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005c62:	01797663          	bgeu	s2,s7,80005c6e <exec+0x2ba>
  sz = sz1;
    80005c66:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005c6a:	4a81                	li	s5,0
    80005c6c:	a845                	j	80005d1c <exec+0x368>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c6e:	e8840613          	addi	a2,s0,-376
    80005c72:	85ca                	mv	a1,s2
    80005c74:	855a                	mv	a0,s6
    80005c76:	ffffc097          	auipc	ra,0xffffc
    80005c7a:	9ec080e7          	jalr	-1556(ra) # 80001662 <copyout>
    80005c7e:	0c054b63          	bltz	a0,80005d54 <exec+0x3a0>
  t->trapframe->a1 = sp;
    80005c82:	e0843783          	ld	a5,-504(s0)
    80005c86:	67bc                	ld	a5,72(a5)
    80005c88:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c8c:	df043783          	ld	a5,-528(s0)
    80005c90:	0007c703          	lbu	a4,0(a5)
    80005c94:	cf11                	beqz	a4,80005cb0 <exec+0x2fc>
    80005c96:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005c98:	02f00693          	li	a3,47
    80005c9c:	a039                	j	80005caa <exec+0x2f6>
      last = s+1;
    80005c9e:	def43823          	sd	a5,-528(s0)
  for(last=s=path; *s; s++)
    80005ca2:	0785                	addi	a5,a5,1
    80005ca4:	fff7c703          	lbu	a4,-1(a5)
    80005ca8:	c701                	beqz	a4,80005cb0 <exec+0x2fc>
    if(*s == '/')
    80005caa:	fed71ce3          	bne	a4,a3,80005ca2 <exec+0x2ee>
    80005cae:	bfc5                	j	80005c9e <exec+0x2ea>
  safestrcpy(p->name, last, sizeof(p->name));
    80005cb0:	4641                	li	a2,16
    80005cb2:	df043583          	ld	a1,-528(s0)
    80005cb6:	268a0513          	addi	a0,s4,616
    80005cba:	ffffb097          	auipc	ra,0xffffb
    80005cbe:	17a080e7          	jalr	378(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    80005cc2:	1d8a3503          	ld	a0,472(s4)
  p->pagetable = pagetable;
    80005cc6:	1d6a3c23          	sd	s6,472(s4)
  p->sz = sz;
    80005cca:	1d9a3823          	sd	s9,464(s4)
  t->trapframe->epc = elf.entry;  // initial program counter = main
    80005cce:	e0843683          	ld	a3,-504(s0)
    80005cd2:	66bc                	ld	a5,72(a3)
    80005cd4:	e6043703          	ld	a4,-416(s0)
    80005cd8:	ef98                	sd	a4,24(a5)
  t->trapframe->sp = sp; // initial stack pointer
    80005cda:	66bc                	ld	a5,72(a3)
    80005cdc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005ce0:	85ea                	mv	a1,s10
    80005ce2:	ffffc097          	auipc	ra,0xffffc
    80005ce6:	012080e7          	jalr	18(ra) # 80001cf4 <proc_freepagetable>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005cea:	138a0793          	addi	a5,s4,312
    80005cee:	038a0a13          	addi	s4,s4,56
    80005cf2:	863e                	mv	a2,a5
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005cf4:	4685                	li	a3,1
    80005cf6:	a029                	j	80005d00 <exec+0x34c>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005cf8:	0791                	addi	a5,a5,4
    80005cfa:	0a21                	addi	s4,s4,8
    80005cfc:	00ca0b63          	beq	s4,a2,80005d12 <exec+0x35e>
    p->signal_handlers_masks[signum] = 0;
    80005d00:	0007a023          	sw	zero,0(a5)
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005d04:	000a3703          	ld	a4,0(s4)
    80005d08:	fed708e3          	beq	a4,a3,80005cf8 <exec+0x344>
      p->signal_handlers[signum] = SIG_DFL;
    80005d0c:	000a3023          	sd	zero,0(s4)
    80005d10:	b7e5                	j	80005cf8 <exec+0x344>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005d12:	0004851b          	sext.w	a0,s1
    80005d16:	b34d                	j	80005ab8 <exec+0x104>
    80005d18:	de943423          	sd	s1,-536(s0)
    proc_freepagetable(pagetable, sz);
    80005d1c:	de843583          	ld	a1,-536(s0)
    80005d20:	855a                	mv	a0,s6
    80005d22:	ffffc097          	auipc	ra,0xffffc
    80005d26:	fd2080e7          	jalr	-46(ra) # 80001cf4 <proc_freepagetable>
  if(ip){
    80005d2a:	d60a9de3          	bnez	s5,80005aa4 <exec+0xf0>
  return -1;
    80005d2e:	557d                	li	a0,-1
    80005d30:	b361                	j	80005ab8 <exec+0x104>
    80005d32:	de943423          	sd	s1,-536(s0)
    80005d36:	b7dd                	j	80005d1c <exec+0x368>
    80005d38:	de943423          	sd	s1,-536(s0)
    80005d3c:	b7c5                	j	80005d1c <exec+0x368>
    80005d3e:	de943423          	sd	s1,-536(s0)
    80005d42:	bfe9                	j	80005d1c <exec+0x368>
  sz = sz1;
    80005d44:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005d48:	4a81                	li	s5,0
    80005d4a:	bfc9                	j	80005d1c <exec+0x368>
  sz = sz1;
    80005d4c:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005d50:	4a81                	li	s5,0
    80005d52:	b7e9                	j	80005d1c <exec+0x368>
  sz = sz1;
    80005d54:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005d58:	4a81                	li	s5,0
    80005d5a:	b7c9                	j	80005d1c <exec+0x368>
    sz = sz1;
    80005d5c:	de843483          	ld	s1,-536(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d60:	e0043783          	ld	a5,-512(s0)
    80005d64:	0017869b          	addiw	a3,a5,1
    80005d68:	e0d43023          	sd	a3,-512(s0)
    80005d6c:	df843783          	ld	a5,-520(s0)
    80005d70:	0387879b          	addiw	a5,a5,56
    80005d74:	e8045703          	lhu	a4,-384(s0)
    80005d78:	dee6dee3          	bge	a3,a4,80005b74 <exec+0x1c0>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005d7c:	2781                	sext.w	a5,a5
    80005d7e:	def43c23          	sd	a5,-520(s0)
    80005d82:	03800713          	li	a4,56
    80005d86:	86be                	mv	a3,a5
    80005d88:	e1040613          	addi	a2,s0,-496
    80005d8c:	4581                	li	a1,0
    80005d8e:	8556                	mv	a0,s5
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	9e4080e7          	jalr	-1564(ra) # 80004774 <readi>
    80005d98:	03800793          	li	a5,56
    80005d9c:	f6f51ee3          	bne	a0,a5,80005d18 <exec+0x364>
    if(ph.type != ELF_PROG_LOAD)
    80005da0:	e1042783          	lw	a5,-496(s0)
    80005da4:	4705                	li	a4,1
    80005da6:	fae79de3          	bne	a5,a4,80005d60 <exec+0x3ac>
    if(ph.memsz < ph.filesz)
    80005daa:	e3843603          	ld	a2,-456(s0)
    80005dae:	e3043783          	ld	a5,-464(s0)
    80005db2:	f8f660e3          	bltu	a2,a5,80005d32 <exec+0x37e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005db6:	e2043783          	ld	a5,-480(s0)
    80005dba:	963e                	add	a2,a2,a5
    80005dbc:	f6f66ee3          	bltu	a2,a5,80005d38 <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005dc0:	85a6                	mv	a1,s1
    80005dc2:	855a                	mv	a0,s6
    80005dc4:	ffffb097          	auipc	ra,0xffffb
    80005dc8:	64e080e7          	jalr	1614(ra) # 80001412 <uvmalloc>
    80005dcc:	dea43423          	sd	a0,-536(s0)
    80005dd0:	d53d                	beqz	a0,80005d3e <exec+0x38a>
    if(ph.vaddr % PGSIZE != 0)
    80005dd2:	e2043c03          	ld	s8,-480(s0)
    80005dd6:	dd843783          	ld	a5,-552(s0)
    80005dda:	00fc77b3          	and	a5,s8,a5
    80005dde:	ff9d                	bnez	a5,80005d1c <exec+0x368>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005de0:	e1842c83          	lw	s9,-488(s0)
    80005de4:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005de8:	f60b8ae3          	beqz	s7,80005d5c <exec+0x3a8>
    80005dec:	89de                	mv	s3,s7
    80005dee:	4481                	li	s1,0
    80005df0:	b38d                	j	80005b52 <exec+0x19e>

0000000080005df2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005df2:	7179                	addi	sp,sp,-48
    80005df4:	f406                	sd	ra,40(sp)
    80005df6:	f022                	sd	s0,32(sp)
    80005df8:	ec26                	sd	s1,24(sp)
    80005dfa:	e84a                	sd	s2,16(sp)
    80005dfc:	1800                	addi	s0,sp,48
    80005dfe:	892e                	mv	s2,a1
    80005e00:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005e02:	fdc40593          	addi	a1,s0,-36
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	8e2080e7          	jalr	-1822(ra) # 800036e8 <argint>
    80005e0e:	04054063          	bltz	a0,80005e4e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005e12:	fdc42703          	lw	a4,-36(s0)
    80005e16:	47bd                	li	a5,15
    80005e18:	02e7ed63          	bltu	a5,a4,80005e52 <argfd+0x60>
    80005e1c:	ffffc097          	auipc	ra,0xffffc
    80005e20:	c16080e7          	jalr	-1002(ra) # 80001a32 <myproc>
    80005e24:	fdc42703          	lw	a4,-36(s0)
    80005e28:	03c70793          	addi	a5,a4,60
    80005e2c:	078e                	slli	a5,a5,0x3
    80005e2e:	953e                	add	a0,a0,a5
    80005e30:	611c                	ld	a5,0(a0)
    80005e32:	c395                	beqz	a5,80005e56 <argfd+0x64>
    return -1;
  if(pfd)
    80005e34:	00090463          	beqz	s2,80005e3c <argfd+0x4a>
    *pfd = fd;
    80005e38:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005e3c:	4501                	li	a0,0
  if(pf)
    80005e3e:	c091                	beqz	s1,80005e42 <argfd+0x50>
    *pf = f;
    80005e40:	e09c                	sd	a5,0(s1)
}
    80005e42:	70a2                	ld	ra,40(sp)
    80005e44:	7402                	ld	s0,32(sp)
    80005e46:	64e2                	ld	s1,24(sp)
    80005e48:	6942                	ld	s2,16(sp)
    80005e4a:	6145                	addi	sp,sp,48
    80005e4c:	8082                	ret
    return -1;
    80005e4e:	557d                	li	a0,-1
    80005e50:	bfcd                	j	80005e42 <argfd+0x50>
    return -1;
    80005e52:	557d                	li	a0,-1
    80005e54:	b7fd                	j	80005e42 <argfd+0x50>
    80005e56:	557d                	li	a0,-1
    80005e58:	b7ed                	j	80005e42 <argfd+0x50>

0000000080005e5a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005e5a:	1101                	addi	sp,sp,-32
    80005e5c:	ec06                	sd	ra,24(sp)
    80005e5e:	e822                	sd	s0,16(sp)
    80005e60:	e426                	sd	s1,8(sp)
    80005e62:	1000                	addi	s0,sp,32
    80005e64:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005e66:	ffffc097          	auipc	ra,0xffffc
    80005e6a:	bcc080e7          	jalr	-1076(ra) # 80001a32 <myproc>
    80005e6e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005e70:	1e050793          	addi	a5,a0,480
    80005e74:	4501                	li	a0,0
    80005e76:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005e78:	6398                	ld	a4,0(a5)
    80005e7a:	cb19                	beqz	a4,80005e90 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005e7c:	2505                	addiw	a0,a0,1
    80005e7e:	07a1                	addi	a5,a5,8
    80005e80:	fed51ce3          	bne	a0,a3,80005e78 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005e84:	557d                	li	a0,-1
}
    80005e86:	60e2                	ld	ra,24(sp)
    80005e88:	6442                	ld	s0,16(sp)
    80005e8a:	64a2                	ld	s1,8(sp)
    80005e8c:	6105                	addi	sp,sp,32
    80005e8e:	8082                	ret
      p->ofile[fd] = f;
    80005e90:	03c50793          	addi	a5,a0,60
    80005e94:	078e                	slli	a5,a5,0x3
    80005e96:	963e                	add	a2,a2,a5
    80005e98:	e204                	sd	s1,0(a2)
      return fd;
    80005e9a:	b7f5                	j	80005e86 <fdalloc+0x2c>

0000000080005e9c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005e9c:	715d                	addi	sp,sp,-80
    80005e9e:	e486                	sd	ra,72(sp)
    80005ea0:	e0a2                	sd	s0,64(sp)
    80005ea2:	fc26                	sd	s1,56(sp)
    80005ea4:	f84a                	sd	s2,48(sp)
    80005ea6:	f44e                	sd	s3,40(sp)
    80005ea8:	f052                	sd	s4,32(sp)
    80005eaa:	ec56                	sd	s5,24(sp)
    80005eac:	0880                	addi	s0,sp,80
    80005eae:	89ae                	mv	s3,a1
    80005eb0:	8ab2                	mv	s5,a2
    80005eb2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005eb4:	fb040593          	addi	a1,s0,-80
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	ddc080e7          	jalr	-548(ra) # 80004c94 <nameiparent>
    80005ec0:	892a                	mv	s2,a0
    80005ec2:	12050e63          	beqz	a0,80005ffe <create+0x162>
    return 0;

  ilock(dp);
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	5fa080e7          	jalr	1530(ra) # 800044c0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005ece:	4601                	li	a2,0
    80005ed0:	fb040593          	addi	a1,s0,-80
    80005ed4:	854a                	mv	a0,s2
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	ace080e7          	jalr	-1330(ra) # 800049a4 <dirlookup>
    80005ede:	84aa                	mv	s1,a0
    80005ee0:	c921                	beqz	a0,80005f30 <create+0x94>
    iunlockput(dp);
    80005ee2:	854a                	mv	a0,s2
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	83e080e7          	jalr	-1986(ra) # 80004722 <iunlockput>
    ilock(ip);
    80005eec:	8526                	mv	a0,s1
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	5d2080e7          	jalr	1490(ra) # 800044c0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005ef6:	2981                	sext.w	s3,s3
    80005ef8:	4789                	li	a5,2
    80005efa:	02f99463          	bne	s3,a5,80005f22 <create+0x86>
    80005efe:	0444d783          	lhu	a5,68(s1)
    80005f02:	37f9                	addiw	a5,a5,-2
    80005f04:	17c2                	slli	a5,a5,0x30
    80005f06:	93c1                	srli	a5,a5,0x30
    80005f08:	4705                	li	a4,1
    80005f0a:	00f76c63          	bltu	a4,a5,80005f22 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005f0e:	8526                	mv	a0,s1
    80005f10:	60a6                	ld	ra,72(sp)
    80005f12:	6406                	ld	s0,64(sp)
    80005f14:	74e2                	ld	s1,56(sp)
    80005f16:	7942                	ld	s2,48(sp)
    80005f18:	79a2                	ld	s3,40(sp)
    80005f1a:	7a02                	ld	s4,32(sp)
    80005f1c:	6ae2                	ld	s5,24(sp)
    80005f1e:	6161                	addi	sp,sp,80
    80005f20:	8082                	ret
    iunlockput(ip);
    80005f22:	8526                	mv	a0,s1
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	7fe080e7          	jalr	2046(ra) # 80004722 <iunlockput>
    return 0;
    80005f2c:	4481                	li	s1,0
    80005f2e:	b7c5                	j	80005f0e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005f30:	85ce                	mv	a1,s3
    80005f32:	00092503          	lw	a0,0(s2)
    80005f36:	ffffe097          	auipc	ra,0xffffe
    80005f3a:	3f2080e7          	jalr	1010(ra) # 80004328 <ialloc>
    80005f3e:	84aa                	mv	s1,a0
    80005f40:	c521                	beqz	a0,80005f88 <create+0xec>
  ilock(ip);
    80005f42:	ffffe097          	auipc	ra,0xffffe
    80005f46:	57e080e7          	jalr	1406(ra) # 800044c0 <ilock>
  ip->major = major;
    80005f4a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005f4e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005f52:	4a05                	li	s4,1
    80005f54:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005f58:	8526                	mv	a0,s1
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	49c080e7          	jalr	1180(ra) # 800043f6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005f62:	2981                	sext.w	s3,s3
    80005f64:	03498a63          	beq	s3,s4,80005f98 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005f68:	40d0                	lw	a2,4(s1)
    80005f6a:	fb040593          	addi	a1,s0,-80
    80005f6e:	854a                	mv	a0,s2
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	c44080e7          	jalr	-956(ra) # 80004bb4 <dirlink>
    80005f78:	06054b63          	bltz	a0,80005fee <create+0x152>
  iunlockput(dp);
    80005f7c:	854a                	mv	a0,s2
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	7a4080e7          	jalr	1956(ra) # 80004722 <iunlockput>
  return ip;
    80005f86:	b761                	j	80005f0e <create+0x72>
    panic("create: ialloc");
    80005f88:	00003517          	auipc	a0,0x3
    80005f8c:	7d050513          	addi	a0,a0,2000 # 80009758 <syscalls+0x2f8>
    80005f90:	ffffa097          	auipc	ra,0xffffa
    80005f94:	59a080e7          	jalr	1434(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005f98:	04a95783          	lhu	a5,74(s2)
    80005f9c:	2785                	addiw	a5,a5,1
    80005f9e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005fa2:	854a                	mv	a0,s2
    80005fa4:	ffffe097          	auipc	ra,0xffffe
    80005fa8:	452080e7          	jalr	1106(ra) # 800043f6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005fac:	40d0                	lw	a2,4(s1)
    80005fae:	00003597          	auipc	a1,0x3
    80005fb2:	7ba58593          	addi	a1,a1,1978 # 80009768 <syscalls+0x308>
    80005fb6:	8526                	mv	a0,s1
    80005fb8:	fffff097          	auipc	ra,0xfffff
    80005fbc:	bfc080e7          	jalr	-1028(ra) # 80004bb4 <dirlink>
    80005fc0:	00054f63          	bltz	a0,80005fde <create+0x142>
    80005fc4:	00492603          	lw	a2,4(s2)
    80005fc8:	00003597          	auipc	a1,0x3
    80005fcc:	7a858593          	addi	a1,a1,1960 # 80009770 <syscalls+0x310>
    80005fd0:	8526                	mv	a0,s1
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	be2080e7          	jalr	-1054(ra) # 80004bb4 <dirlink>
    80005fda:	f80557e3          	bgez	a0,80005f68 <create+0xcc>
      panic("create dots");
    80005fde:	00003517          	auipc	a0,0x3
    80005fe2:	79a50513          	addi	a0,a0,1946 # 80009778 <syscalls+0x318>
    80005fe6:	ffffa097          	auipc	ra,0xffffa
    80005fea:	544080e7          	jalr	1348(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005fee:	00003517          	auipc	a0,0x3
    80005ff2:	79a50513          	addi	a0,a0,1946 # 80009788 <syscalls+0x328>
    80005ff6:	ffffa097          	auipc	ra,0xffffa
    80005ffa:	534080e7          	jalr	1332(ra) # 8000052a <panic>
    return 0;
    80005ffe:	84aa                	mv	s1,a0
    80006000:	b739                	j	80005f0e <create+0x72>

0000000080006002 <sys_dup>:
{
    80006002:	7179                	addi	sp,sp,-48
    80006004:	f406                	sd	ra,40(sp)
    80006006:	f022                	sd	s0,32(sp)
    80006008:	ec26                	sd	s1,24(sp)
    8000600a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000600c:	fd840613          	addi	a2,s0,-40
    80006010:	4581                	li	a1,0
    80006012:	4501                	li	a0,0
    80006014:	00000097          	auipc	ra,0x0
    80006018:	dde080e7          	jalr	-546(ra) # 80005df2 <argfd>
    return -1;
    8000601c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000601e:	02054363          	bltz	a0,80006044 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80006022:	fd843503          	ld	a0,-40(s0)
    80006026:	00000097          	auipc	ra,0x0
    8000602a:	e34080e7          	jalr	-460(ra) # 80005e5a <fdalloc>
    8000602e:	84aa                	mv	s1,a0
    return -1;
    80006030:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80006032:	00054963          	bltz	a0,80006044 <sys_dup+0x42>
  filedup(f);
    80006036:	fd843503          	ld	a0,-40(s0)
    8000603a:	fffff097          	auipc	ra,0xfffff
    8000603e:	2d6080e7          	jalr	726(ra) # 80005310 <filedup>
  return fd;
    80006042:	87a6                	mv	a5,s1
}
    80006044:	853e                	mv	a0,a5
    80006046:	70a2                	ld	ra,40(sp)
    80006048:	7402                	ld	s0,32(sp)
    8000604a:	64e2                	ld	s1,24(sp)
    8000604c:	6145                	addi	sp,sp,48
    8000604e:	8082                	ret

0000000080006050 <sys_read>:
{
    80006050:	7179                	addi	sp,sp,-48
    80006052:	f406                	sd	ra,40(sp)
    80006054:	f022                	sd	s0,32(sp)
    80006056:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006058:	fe840613          	addi	a2,s0,-24
    8000605c:	4581                	li	a1,0
    8000605e:	4501                	li	a0,0
    80006060:	00000097          	auipc	ra,0x0
    80006064:	d92080e7          	jalr	-622(ra) # 80005df2 <argfd>
    return -1;
    80006068:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000606a:	04054163          	bltz	a0,800060ac <sys_read+0x5c>
    8000606e:	fe440593          	addi	a1,s0,-28
    80006072:	4509                	li	a0,2
    80006074:	ffffd097          	auipc	ra,0xffffd
    80006078:	674080e7          	jalr	1652(ra) # 800036e8 <argint>
    return -1;
    8000607c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000607e:	02054763          	bltz	a0,800060ac <sys_read+0x5c>
    80006082:	fd840593          	addi	a1,s0,-40
    80006086:	4505                	li	a0,1
    80006088:	ffffd097          	auipc	ra,0xffffd
    8000608c:	682080e7          	jalr	1666(ra) # 8000370a <argaddr>
    return -1;
    80006090:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006092:	00054d63          	bltz	a0,800060ac <sys_read+0x5c>
  return fileread(f, p, n);
    80006096:	fe442603          	lw	a2,-28(s0)
    8000609a:	fd843583          	ld	a1,-40(s0)
    8000609e:	fe843503          	ld	a0,-24(s0)
    800060a2:	fffff097          	auipc	ra,0xfffff
    800060a6:	3fa080e7          	jalr	1018(ra) # 8000549c <fileread>
    800060aa:	87aa                	mv	a5,a0
}
    800060ac:	853e                	mv	a0,a5
    800060ae:	70a2                	ld	ra,40(sp)
    800060b0:	7402                	ld	s0,32(sp)
    800060b2:	6145                	addi	sp,sp,48
    800060b4:	8082                	ret

00000000800060b6 <sys_write>:
{
    800060b6:	7179                	addi	sp,sp,-48
    800060b8:	f406                	sd	ra,40(sp)
    800060ba:	f022                	sd	s0,32(sp)
    800060bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800060be:	fe840613          	addi	a2,s0,-24
    800060c2:	4581                	li	a1,0
    800060c4:	4501                	li	a0,0
    800060c6:	00000097          	auipc	ra,0x0
    800060ca:	d2c080e7          	jalr	-724(ra) # 80005df2 <argfd>
    return -1;
    800060ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800060d0:	04054163          	bltz	a0,80006112 <sys_write+0x5c>
    800060d4:	fe440593          	addi	a1,s0,-28
    800060d8:	4509                	li	a0,2
    800060da:	ffffd097          	auipc	ra,0xffffd
    800060de:	60e080e7          	jalr	1550(ra) # 800036e8 <argint>
    return -1;
    800060e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800060e4:	02054763          	bltz	a0,80006112 <sys_write+0x5c>
    800060e8:	fd840593          	addi	a1,s0,-40
    800060ec:	4505                	li	a0,1
    800060ee:	ffffd097          	auipc	ra,0xffffd
    800060f2:	61c080e7          	jalr	1564(ra) # 8000370a <argaddr>
    return -1;
    800060f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800060f8:	00054d63          	bltz	a0,80006112 <sys_write+0x5c>
  return filewrite(f, p, n);
    800060fc:	fe442603          	lw	a2,-28(s0)
    80006100:	fd843583          	ld	a1,-40(s0)
    80006104:	fe843503          	ld	a0,-24(s0)
    80006108:	fffff097          	auipc	ra,0xfffff
    8000610c:	456080e7          	jalr	1110(ra) # 8000555e <filewrite>
    80006110:	87aa                	mv	a5,a0
}
    80006112:	853e                	mv	a0,a5
    80006114:	70a2                	ld	ra,40(sp)
    80006116:	7402                	ld	s0,32(sp)
    80006118:	6145                	addi	sp,sp,48
    8000611a:	8082                	ret

000000008000611c <sys_close>:
{
    8000611c:	1101                	addi	sp,sp,-32
    8000611e:	ec06                	sd	ra,24(sp)
    80006120:	e822                	sd	s0,16(sp)
    80006122:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80006124:	fe040613          	addi	a2,s0,-32
    80006128:	fec40593          	addi	a1,s0,-20
    8000612c:	4501                	li	a0,0
    8000612e:	00000097          	auipc	ra,0x0
    80006132:	cc4080e7          	jalr	-828(ra) # 80005df2 <argfd>
    return -1;
    80006136:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80006138:	02054563          	bltz	a0,80006162 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    8000613c:	ffffc097          	auipc	ra,0xffffc
    80006140:	8f6080e7          	jalr	-1802(ra) # 80001a32 <myproc>
    80006144:	fec42783          	lw	a5,-20(s0)
    80006148:	03c78793          	addi	a5,a5,60
    8000614c:	078e                	slli	a5,a5,0x3
    8000614e:	97aa                	add	a5,a5,a0
    80006150:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80006154:	fe043503          	ld	a0,-32(s0)
    80006158:	fffff097          	auipc	ra,0xfffff
    8000615c:	20a080e7          	jalr	522(ra) # 80005362 <fileclose>
  return 0;
    80006160:	4781                	li	a5,0
}
    80006162:	853e                	mv	a0,a5
    80006164:	60e2                	ld	ra,24(sp)
    80006166:	6442                	ld	s0,16(sp)
    80006168:	6105                	addi	sp,sp,32
    8000616a:	8082                	ret

000000008000616c <sys_fstat>:
{
    8000616c:	1101                	addi	sp,sp,-32
    8000616e:	ec06                	sd	ra,24(sp)
    80006170:	e822                	sd	s0,16(sp)
    80006172:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006174:	fe840613          	addi	a2,s0,-24
    80006178:	4581                	li	a1,0
    8000617a:	4501                	li	a0,0
    8000617c:	00000097          	auipc	ra,0x0
    80006180:	c76080e7          	jalr	-906(ra) # 80005df2 <argfd>
    return -1;
    80006184:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006186:	02054563          	bltz	a0,800061b0 <sys_fstat+0x44>
    8000618a:	fe040593          	addi	a1,s0,-32
    8000618e:	4505                	li	a0,1
    80006190:	ffffd097          	auipc	ra,0xffffd
    80006194:	57a080e7          	jalr	1402(ra) # 8000370a <argaddr>
    return -1;
    80006198:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000619a:	00054b63          	bltz	a0,800061b0 <sys_fstat+0x44>
  return filestat(f, st);
    8000619e:	fe043583          	ld	a1,-32(s0)
    800061a2:	fe843503          	ld	a0,-24(s0)
    800061a6:	fffff097          	auipc	ra,0xfffff
    800061aa:	284080e7          	jalr	644(ra) # 8000542a <filestat>
    800061ae:	87aa                	mv	a5,a0
}
    800061b0:	853e                	mv	a0,a5
    800061b2:	60e2                	ld	ra,24(sp)
    800061b4:	6442                	ld	s0,16(sp)
    800061b6:	6105                	addi	sp,sp,32
    800061b8:	8082                	ret

00000000800061ba <sys_link>:
{
    800061ba:	7169                	addi	sp,sp,-304
    800061bc:	f606                	sd	ra,296(sp)
    800061be:	f222                	sd	s0,288(sp)
    800061c0:	ee26                	sd	s1,280(sp)
    800061c2:	ea4a                	sd	s2,272(sp)
    800061c4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800061c6:	08000613          	li	a2,128
    800061ca:	ed040593          	addi	a1,s0,-304
    800061ce:	4501                	li	a0,0
    800061d0:	ffffd097          	auipc	ra,0xffffd
    800061d4:	55c080e7          	jalr	1372(ra) # 8000372c <argstr>
    return -1;
    800061d8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800061da:	10054e63          	bltz	a0,800062f6 <sys_link+0x13c>
    800061de:	08000613          	li	a2,128
    800061e2:	f5040593          	addi	a1,s0,-176
    800061e6:	4505                	li	a0,1
    800061e8:	ffffd097          	auipc	ra,0xffffd
    800061ec:	544080e7          	jalr	1348(ra) # 8000372c <argstr>
    return -1;
    800061f0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800061f2:	10054263          	bltz	a0,800062f6 <sys_link+0x13c>
  begin_op();
    800061f6:	fffff097          	auipc	ra,0xfffff
    800061fa:	ca0080e7          	jalr	-864(ra) # 80004e96 <begin_op>
  if((ip = namei(old)) == 0){
    800061fe:	ed040513          	addi	a0,s0,-304
    80006202:	fffff097          	auipc	ra,0xfffff
    80006206:	a74080e7          	jalr	-1420(ra) # 80004c76 <namei>
    8000620a:	84aa                	mv	s1,a0
    8000620c:	c551                	beqz	a0,80006298 <sys_link+0xde>
  ilock(ip);
    8000620e:	ffffe097          	auipc	ra,0xffffe
    80006212:	2b2080e7          	jalr	690(ra) # 800044c0 <ilock>
  if(ip->type == T_DIR){
    80006216:	04449703          	lh	a4,68(s1)
    8000621a:	4785                	li	a5,1
    8000621c:	08f70463          	beq	a4,a5,800062a4 <sys_link+0xea>
  ip->nlink++;
    80006220:	04a4d783          	lhu	a5,74(s1)
    80006224:	2785                	addiw	a5,a5,1
    80006226:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000622a:	8526                	mv	a0,s1
    8000622c:	ffffe097          	auipc	ra,0xffffe
    80006230:	1ca080e7          	jalr	458(ra) # 800043f6 <iupdate>
  iunlock(ip);
    80006234:	8526                	mv	a0,s1
    80006236:	ffffe097          	auipc	ra,0xffffe
    8000623a:	34c080e7          	jalr	844(ra) # 80004582 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000623e:	fd040593          	addi	a1,s0,-48
    80006242:	f5040513          	addi	a0,s0,-176
    80006246:	fffff097          	auipc	ra,0xfffff
    8000624a:	a4e080e7          	jalr	-1458(ra) # 80004c94 <nameiparent>
    8000624e:	892a                	mv	s2,a0
    80006250:	c935                	beqz	a0,800062c4 <sys_link+0x10a>
  ilock(dp);
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	26e080e7          	jalr	622(ra) # 800044c0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000625a:	00092703          	lw	a4,0(s2)
    8000625e:	409c                	lw	a5,0(s1)
    80006260:	04f71d63          	bne	a4,a5,800062ba <sys_link+0x100>
    80006264:	40d0                	lw	a2,4(s1)
    80006266:	fd040593          	addi	a1,s0,-48
    8000626a:	854a                	mv	a0,s2
    8000626c:	fffff097          	auipc	ra,0xfffff
    80006270:	948080e7          	jalr	-1720(ra) # 80004bb4 <dirlink>
    80006274:	04054363          	bltz	a0,800062ba <sys_link+0x100>
  iunlockput(dp);
    80006278:	854a                	mv	a0,s2
    8000627a:	ffffe097          	auipc	ra,0xffffe
    8000627e:	4a8080e7          	jalr	1192(ra) # 80004722 <iunlockput>
  iput(ip);
    80006282:	8526                	mv	a0,s1
    80006284:	ffffe097          	auipc	ra,0xffffe
    80006288:	3f6080e7          	jalr	1014(ra) # 8000467a <iput>
  end_op();
    8000628c:	fffff097          	auipc	ra,0xfffff
    80006290:	c8a080e7          	jalr	-886(ra) # 80004f16 <end_op>
  return 0;
    80006294:	4781                	li	a5,0
    80006296:	a085                	j	800062f6 <sys_link+0x13c>
    end_op();
    80006298:	fffff097          	auipc	ra,0xfffff
    8000629c:	c7e080e7          	jalr	-898(ra) # 80004f16 <end_op>
    return -1;
    800062a0:	57fd                	li	a5,-1
    800062a2:	a891                	j	800062f6 <sys_link+0x13c>
    iunlockput(ip);
    800062a4:	8526                	mv	a0,s1
    800062a6:	ffffe097          	auipc	ra,0xffffe
    800062aa:	47c080e7          	jalr	1148(ra) # 80004722 <iunlockput>
    end_op();
    800062ae:	fffff097          	auipc	ra,0xfffff
    800062b2:	c68080e7          	jalr	-920(ra) # 80004f16 <end_op>
    return -1;
    800062b6:	57fd                	li	a5,-1
    800062b8:	a83d                	j	800062f6 <sys_link+0x13c>
    iunlockput(dp);
    800062ba:	854a                	mv	a0,s2
    800062bc:	ffffe097          	auipc	ra,0xffffe
    800062c0:	466080e7          	jalr	1126(ra) # 80004722 <iunlockput>
  ilock(ip);
    800062c4:	8526                	mv	a0,s1
    800062c6:	ffffe097          	auipc	ra,0xffffe
    800062ca:	1fa080e7          	jalr	506(ra) # 800044c0 <ilock>
  ip->nlink--;
    800062ce:	04a4d783          	lhu	a5,74(s1)
    800062d2:	37fd                	addiw	a5,a5,-1
    800062d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800062d8:	8526                	mv	a0,s1
    800062da:	ffffe097          	auipc	ra,0xffffe
    800062de:	11c080e7          	jalr	284(ra) # 800043f6 <iupdate>
  iunlockput(ip);
    800062e2:	8526                	mv	a0,s1
    800062e4:	ffffe097          	auipc	ra,0xffffe
    800062e8:	43e080e7          	jalr	1086(ra) # 80004722 <iunlockput>
  end_op();
    800062ec:	fffff097          	auipc	ra,0xfffff
    800062f0:	c2a080e7          	jalr	-982(ra) # 80004f16 <end_op>
  return -1;
    800062f4:	57fd                	li	a5,-1
}
    800062f6:	853e                	mv	a0,a5
    800062f8:	70b2                	ld	ra,296(sp)
    800062fa:	7412                	ld	s0,288(sp)
    800062fc:	64f2                	ld	s1,280(sp)
    800062fe:	6952                	ld	s2,272(sp)
    80006300:	6155                	addi	sp,sp,304
    80006302:	8082                	ret

0000000080006304 <sys_unlink>:
{
    80006304:	7151                	addi	sp,sp,-240
    80006306:	f586                	sd	ra,232(sp)
    80006308:	f1a2                	sd	s0,224(sp)
    8000630a:	eda6                	sd	s1,216(sp)
    8000630c:	e9ca                	sd	s2,208(sp)
    8000630e:	e5ce                	sd	s3,200(sp)
    80006310:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006312:	08000613          	li	a2,128
    80006316:	f3040593          	addi	a1,s0,-208
    8000631a:	4501                	li	a0,0
    8000631c:	ffffd097          	auipc	ra,0xffffd
    80006320:	410080e7          	jalr	1040(ra) # 8000372c <argstr>
    80006324:	18054163          	bltz	a0,800064a6 <sys_unlink+0x1a2>
  begin_op();
    80006328:	fffff097          	auipc	ra,0xfffff
    8000632c:	b6e080e7          	jalr	-1170(ra) # 80004e96 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006330:	fb040593          	addi	a1,s0,-80
    80006334:	f3040513          	addi	a0,s0,-208
    80006338:	fffff097          	auipc	ra,0xfffff
    8000633c:	95c080e7          	jalr	-1700(ra) # 80004c94 <nameiparent>
    80006340:	84aa                	mv	s1,a0
    80006342:	c979                	beqz	a0,80006418 <sys_unlink+0x114>
  ilock(dp);
    80006344:	ffffe097          	auipc	ra,0xffffe
    80006348:	17c080e7          	jalr	380(ra) # 800044c0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000634c:	00003597          	auipc	a1,0x3
    80006350:	41c58593          	addi	a1,a1,1052 # 80009768 <syscalls+0x308>
    80006354:	fb040513          	addi	a0,s0,-80
    80006358:	ffffe097          	auipc	ra,0xffffe
    8000635c:	632080e7          	jalr	1586(ra) # 8000498a <namecmp>
    80006360:	14050a63          	beqz	a0,800064b4 <sys_unlink+0x1b0>
    80006364:	00003597          	auipc	a1,0x3
    80006368:	40c58593          	addi	a1,a1,1036 # 80009770 <syscalls+0x310>
    8000636c:	fb040513          	addi	a0,s0,-80
    80006370:	ffffe097          	auipc	ra,0xffffe
    80006374:	61a080e7          	jalr	1562(ra) # 8000498a <namecmp>
    80006378:	12050e63          	beqz	a0,800064b4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000637c:	f2c40613          	addi	a2,s0,-212
    80006380:	fb040593          	addi	a1,s0,-80
    80006384:	8526                	mv	a0,s1
    80006386:	ffffe097          	auipc	ra,0xffffe
    8000638a:	61e080e7          	jalr	1566(ra) # 800049a4 <dirlookup>
    8000638e:	892a                	mv	s2,a0
    80006390:	12050263          	beqz	a0,800064b4 <sys_unlink+0x1b0>
  ilock(ip);
    80006394:	ffffe097          	auipc	ra,0xffffe
    80006398:	12c080e7          	jalr	300(ra) # 800044c0 <ilock>
  if(ip->nlink < 1)
    8000639c:	04a91783          	lh	a5,74(s2)
    800063a0:	08f05263          	blez	a5,80006424 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800063a4:	04491703          	lh	a4,68(s2)
    800063a8:	4785                	li	a5,1
    800063aa:	08f70563          	beq	a4,a5,80006434 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800063ae:	4641                	li	a2,16
    800063b0:	4581                	li	a1,0
    800063b2:	fc040513          	addi	a0,s0,-64
    800063b6:	ffffb097          	auipc	ra,0xffffb
    800063ba:	92c080e7          	jalr	-1748(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800063be:	4741                	li	a4,16
    800063c0:	f2c42683          	lw	a3,-212(s0)
    800063c4:	fc040613          	addi	a2,s0,-64
    800063c8:	4581                	li	a1,0
    800063ca:	8526                	mv	a0,s1
    800063cc:	ffffe097          	auipc	ra,0xffffe
    800063d0:	4a0080e7          	jalr	1184(ra) # 8000486c <writei>
    800063d4:	47c1                	li	a5,16
    800063d6:	0af51563          	bne	a0,a5,80006480 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800063da:	04491703          	lh	a4,68(s2)
    800063de:	4785                	li	a5,1
    800063e0:	0af70863          	beq	a4,a5,80006490 <sys_unlink+0x18c>
  iunlockput(dp);
    800063e4:	8526                	mv	a0,s1
    800063e6:	ffffe097          	auipc	ra,0xffffe
    800063ea:	33c080e7          	jalr	828(ra) # 80004722 <iunlockput>
  ip->nlink--;
    800063ee:	04a95783          	lhu	a5,74(s2)
    800063f2:	37fd                	addiw	a5,a5,-1
    800063f4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800063f8:	854a                	mv	a0,s2
    800063fa:	ffffe097          	auipc	ra,0xffffe
    800063fe:	ffc080e7          	jalr	-4(ra) # 800043f6 <iupdate>
  iunlockput(ip);
    80006402:	854a                	mv	a0,s2
    80006404:	ffffe097          	auipc	ra,0xffffe
    80006408:	31e080e7          	jalr	798(ra) # 80004722 <iunlockput>
  end_op();
    8000640c:	fffff097          	auipc	ra,0xfffff
    80006410:	b0a080e7          	jalr	-1270(ra) # 80004f16 <end_op>
  return 0;
    80006414:	4501                	li	a0,0
    80006416:	a84d                	j	800064c8 <sys_unlink+0x1c4>
    end_op();
    80006418:	fffff097          	auipc	ra,0xfffff
    8000641c:	afe080e7          	jalr	-1282(ra) # 80004f16 <end_op>
    return -1;
    80006420:	557d                	li	a0,-1
    80006422:	a05d                	j	800064c8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006424:	00003517          	auipc	a0,0x3
    80006428:	37450513          	addi	a0,a0,884 # 80009798 <syscalls+0x338>
    8000642c:	ffffa097          	auipc	ra,0xffffa
    80006430:	0fe080e7          	jalr	254(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006434:	04c92703          	lw	a4,76(s2)
    80006438:	02000793          	li	a5,32
    8000643c:	f6e7f9e3          	bgeu	a5,a4,800063ae <sys_unlink+0xaa>
    80006440:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006444:	4741                	li	a4,16
    80006446:	86ce                	mv	a3,s3
    80006448:	f1840613          	addi	a2,s0,-232
    8000644c:	4581                	li	a1,0
    8000644e:	854a                	mv	a0,s2
    80006450:	ffffe097          	auipc	ra,0xffffe
    80006454:	324080e7          	jalr	804(ra) # 80004774 <readi>
    80006458:	47c1                	li	a5,16
    8000645a:	00f51b63          	bne	a0,a5,80006470 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000645e:	f1845783          	lhu	a5,-232(s0)
    80006462:	e7a1                	bnez	a5,800064aa <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006464:	29c1                	addiw	s3,s3,16
    80006466:	04c92783          	lw	a5,76(s2)
    8000646a:	fcf9ede3          	bltu	s3,a5,80006444 <sys_unlink+0x140>
    8000646e:	b781                	j	800063ae <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006470:	00003517          	auipc	a0,0x3
    80006474:	34050513          	addi	a0,a0,832 # 800097b0 <syscalls+0x350>
    80006478:	ffffa097          	auipc	ra,0xffffa
    8000647c:	0b2080e7          	jalr	178(ra) # 8000052a <panic>
    panic("unlink: writei");
    80006480:	00003517          	auipc	a0,0x3
    80006484:	34850513          	addi	a0,a0,840 # 800097c8 <syscalls+0x368>
    80006488:	ffffa097          	auipc	ra,0xffffa
    8000648c:	0a2080e7          	jalr	162(ra) # 8000052a <panic>
    dp->nlink--;
    80006490:	04a4d783          	lhu	a5,74(s1)
    80006494:	37fd                	addiw	a5,a5,-1
    80006496:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000649a:	8526                	mv	a0,s1
    8000649c:	ffffe097          	auipc	ra,0xffffe
    800064a0:	f5a080e7          	jalr	-166(ra) # 800043f6 <iupdate>
    800064a4:	b781                	j	800063e4 <sys_unlink+0xe0>
    return -1;
    800064a6:	557d                	li	a0,-1
    800064a8:	a005                	j	800064c8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800064aa:	854a                	mv	a0,s2
    800064ac:	ffffe097          	auipc	ra,0xffffe
    800064b0:	276080e7          	jalr	630(ra) # 80004722 <iunlockput>
  iunlockput(dp);
    800064b4:	8526                	mv	a0,s1
    800064b6:	ffffe097          	auipc	ra,0xffffe
    800064ba:	26c080e7          	jalr	620(ra) # 80004722 <iunlockput>
  end_op();
    800064be:	fffff097          	auipc	ra,0xfffff
    800064c2:	a58080e7          	jalr	-1448(ra) # 80004f16 <end_op>
  return -1;
    800064c6:	557d                	li	a0,-1
}
    800064c8:	70ae                	ld	ra,232(sp)
    800064ca:	740e                	ld	s0,224(sp)
    800064cc:	64ee                	ld	s1,216(sp)
    800064ce:	694e                	ld	s2,208(sp)
    800064d0:	69ae                	ld	s3,200(sp)
    800064d2:	616d                	addi	sp,sp,240
    800064d4:	8082                	ret

00000000800064d6 <sys_open>:

uint64
sys_open(void)
{
    800064d6:	7131                	addi	sp,sp,-192
    800064d8:	fd06                	sd	ra,184(sp)
    800064da:	f922                	sd	s0,176(sp)
    800064dc:	f526                	sd	s1,168(sp)
    800064de:	f14a                	sd	s2,160(sp)
    800064e0:	ed4e                	sd	s3,152(sp)
    800064e2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800064e4:	08000613          	li	a2,128
    800064e8:	f5040593          	addi	a1,s0,-176
    800064ec:	4501                	li	a0,0
    800064ee:	ffffd097          	auipc	ra,0xffffd
    800064f2:	23e080e7          	jalr	574(ra) # 8000372c <argstr>
    return -1;
    800064f6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800064f8:	0c054163          	bltz	a0,800065ba <sys_open+0xe4>
    800064fc:	f4c40593          	addi	a1,s0,-180
    80006500:	4505                	li	a0,1
    80006502:	ffffd097          	auipc	ra,0xffffd
    80006506:	1e6080e7          	jalr	486(ra) # 800036e8 <argint>
    8000650a:	0a054863          	bltz	a0,800065ba <sys_open+0xe4>

  begin_op();
    8000650e:	fffff097          	auipc	ra,0xfffff
    80006512:	988080e7          	jalr	-1656(ra) # 80004e96 <begin_op>

  if(omode & O_CREATE){
    80006516:	f4c42783          	lw	a5,-180(s0)
    8000651a:	2007f793          	andi	a5,a5,512
    8000651e:	cbdd                	beqz	a5,800065d4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006520:	4681                	li	a3,0
    80006522:	4601                	li	a2,0
    80006524:	4589                	li	a1,2
    80006526:	f5040513          	addi	a0,s0,-176
    8000652a:	00000097          	auipc	ra,0x0
    8000652e:	972080e7          	jalr	-1678(ra) # 80005e9c <create>
    80006532:	892a                	mv	s2,a0
    if(ip == 0){
    80006534:	c959                	beqz	a0,800065ca <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006536:	04491703          	lh	a4,68(s2)
    8000653a:	478d                	li	a5,3
    8000653c:	00f71763          	bne	a4,a5,8000654a <sys_open+0x74>
    80006540:	04695703          	lhu	a4,70(s2)
    80006544:	47a5                	li	a5,9
    80006546:	0ce7ec63          	bltu	a5,a4,8000661e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000654a:	fffff097          	auipc	ra,0xfffff
    8000654e:	d5c080e7          	jalr	-676(ra) # 800052a6 <filealloc>
    80006552:	89aa                	mv	s3,a0
    80006554:	10050263          	beqz	a0,80006658 <sys_open+0x182>
    80006558:	00000097          	auipc	ra,0x0
    8000655c:	902080e7          	jalr	-1790(ra) # 80005e5a <fdalloc>
    80006560:	84aa                	mv	s1,a0
    80006562:	0e054663          	bltz	a0,8000664e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006566:	04491703          	lh	a4,68(s2)
    8000656a:	478d                	li	a5,3
    8000656c:	0cf70463          	beq	a4,a5,80006634 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006570:	4789                	li	a5,2
    80006572:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006576:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000657a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000657e:	f4c42783          	lw	a5,-180(s0)
    80006582:	0017c713          	xori	a4,a5,1
    80006586:	8b05                	andi	a4,a4,1
    80006588:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000658c:	0037f713          	andi	a4,a5,3
    80006590:	00e03733          	snez	a4,a4
    80006594:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006598:	4007f793          	andi	a5,a5,1024
    8000659c:	c791                	beqz	a5,800065a8 <sys_open+0xd2>
    8000659e:	04491703          	lh	a4,68(s2)
    800065a2:	4789                	li	a5,2
    800065a4:	08f70f63          	beq	a4,a5,80006642 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800065a8:	854a                	mv	a0,s2
    800065aa:	ffffe097          	auipc	ra,0xffffe
    800065ae:	fd8080e7          	jalr	-40(ra) # 80004582 <iunlock>
  end_op();
    800065b2:	fffff097          	auipc	ra,0xfffff
    800065b6:	964080e7          	jalr	-1692(ra) # 80004f16 <end_op>

  return fd;
}
    800065ba:	8526                	mv	a0,s1
    800065bc:	70ea                	ld	ra,184(sp)
    800065be:	744a                	ld	s0,176(sp)
    800065c0:	74aa                	ld	s1,168(sp)
    800065c2:	790a                	ld	s2,160(sp)
    800065c4:	69ea                	ld	s3,152(sp)
    800065c6:	6129                	addi	sp,sp,192
    800065c8:	8082                	ret
      end_op();
    800065ca:	fffff097          	auipc	ra,0xfffff
    800065ce:	94c080e7          	jalr	-1716(ra) # 80004f16 <end_op>
      return -1;
    800065d2:	b7e5                	j	800065ba <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800065d4:	f5040513          	addi	a0,s0,-176
    800065d8:	ffffe097          	auipc	ra,0xffffe
    800065dc:	69e080e7          	jalr	1694(ra) # 80004c76 <namei>
    800065e0:	892a                	mv	s2,a0
    800065e2:	c905                	beqz	a0,80006612 <sys_open+0x13c>
    ilock(ip);
    800065e4:	ffffe097          	auipc	ra,0xffffe
    800065e8:	edc080e7          	jalr	-292(ra) # 800044c0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800065ec:	04491703          	lh	a4,68(s2)
    800065f0:	4785                	li	a5,1
    800065f2:	f4f712e3          	bne	a4,a5,80006536 <sys_open+0x60>
    800065f6:	f4c42783          	lw	a5,-180(s0)
    800065fa:	dba1                	beqz	a5,8000654a <sys_open+0x74>
      iunlockput(ip);
    800065fc:	854a                	mv	a0,s2
    800065fe:	ffffe097          	auipc	ra,0xffffe
    80006602:	124080e7          	jalr	292(ra) # 80004722 <iunlockput>
      end_op();
    80006606:	fffff097          	auipc	ra,0xfffff
    8000660a:	910080e7          	jalr	-1776(ra) # 80004f16 <end_op>
      return -1;
    8000660e:	54fd                	li	s1,-1
    80006610:	b76d                	j	800065ba <sys_open+0xe4>
      end_op();
    80006612:	fffff097          	auipc	ra,0xfffff
    80006616:	904080e7          	jalr	-1788(ra) # 80004f16 <end_op>
      return -1;
    8000661a:	54fd                	li	s1,-1
    8000661c:	bf79                	j	800065ba <sys_open+0xe4>
    iunlockput(ip);
    8000661e:	854a                	mv	a0,s2
    80006620:	ffffe097          	auipc	ra,0xffffe
    80006624:	102080e7          	jalr	258(ra) # 80004722 <iunlockput>
    end_op();
    80006628:	fffff097          	auipc	ra,0xfffff
    8000662c:	8ee080e7          	jalr	-1810(ra) # 80004f16 <end_op>
    return -1;
    80006630:	54fd                	li	s1,-1
    80006632:	b761                	j	800065ba <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006634:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006638:	04691783          	lh	a5,70(s2)
    8000663c:	02f99223          	sh	a5,36(s3)
    80006640:	bf2d                	j	8000657a <sys_open+0xa4>
    itrunc(ip);
    80006642:	854a                	mv	a0,s2
    80006644:	ffffe097          	auipc	ra,0xffffe
    80006648:	f8a080e7          	jalr	-118(ra) # 800045ce <itrunc>
    8000664c:	bfb1                	j	800065a8 <sys_open+0xd2>
      fileclose(f);
    8000664e:	854e                	mv	a0,s3
    80006650:	fffff097          	auipc	ra,0xfffff
    80006654:	d12080e7          	jalr	-750(ra) # 80005362 <fileclose>
    iunlockput(ip);
    80006658:	854a                	mv	a0,s2
    8000665a:	ffffe097          	auipc	ra,0xffffe
    8000665e:	0c8080e7          	jalr	200(ra) # 80004722 <iunlockput>
    end_op();
    80006662:	fffff097          	auipc	ra,0xfffff
    80006666:	8b4080e7          	jalr	-1868(ra) # 80004f16 <end_op>
    return -1;
    8000666a:	54fd                	li	s1,-1
    8000666c:	b7b9                	j	800065ba <sys_open+0xe4>

000000008000666e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000666e:	7175                	addi	sp,sp,-144
    80006670:	e506                	sd	ra,136(sp)
    80006672:	e122                	sd	s0,128(sp)
    80006674:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006676:	fffff097          	auipc	ra,0xfffff
    8000667a:	820080e7          	jalr	-2016(ra) # 80004e96 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000667e:	08000613          	li	a2,128
    80006682:	f7040593          	addi	a1,s0,-144
    80006686:	4501                	li	a0,0
    80006688:	ffffd097          	auipc	ra,0xffffd
    8000668c:	0a4080e7          	jalr	164(ra) # 8000372c <argstr>
    80006690:	02054963          	bltz	a0,800066c2 <sys_mkdir+0x54>
    80006694:	4681                	li	a3,0
    80006696:	4601                	li	a2,0
    80006698:	4585                	li	a1,1
    8000669a:	f7040513          	addi	a0,s0,-144
    8000669e:	fffff097          	auipc	ra,0xfffff
    800066a2:	7fe080e7          	jalr	2046(ra) # 80005e9c <create>
    800066a6:	cd11                	beqz	a0,800066c2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066a8:	ffffe097          	auipc	ra,0xffffe
    800066ac:	07a080e7          	jalr	122(ra) # 80004722 <iunlockput>
  end_op();
    800066b0:	fffff097          	auipc	ra,0xfffff
    800066b4:	866080e7          	jalr	-1946(ra) # 80004f16 <end_op>
  return 0;
    800066b8:	4501                	li	a0,0
}
    800066ba:	60aa                	ld	ra,136(sp)
    800066bc:	640a                	ld	s0,128(sp)
    800066be:	6149                	addi	sp,sp,144
    800066c0:	8082                	ret
    end_op();
    800066c2:	fffff097          	auipc	ra,0xfffff
    800066c6:	854080e7          	jalr	-1964(ra) # 80004f16 <end_op>
    return -1;
    800066ca:	557d                	li	a0,-1
    800066cc:	b7fd                	j	800066ba <sys_mkdir+0x4c>

00000000800066ce <sys_mknod>:

uint64
sys_mknod(void)
{
    800066ce:	7135                	addi	sp,sp,-160
    800066d0:	ed06                	sd	ra,152(sp)
    800066d2:	e922                	sd	s0,144(sp)
    800066d4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800066d6:	ffffe097          	auipc	ra,0xffffe
    800066da:	7c0080e7          	jalr	1984(ra) # 80004e96 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800066de:	08000613          	li	a2,128
    800066e2:	f7040593          	addi	a1,s0,-144
    800066e6:	4501                	li	a0,0
    800066e8:	ffffd097          	auipc	ra,0xffffd
    800066ec:	044080e7          	jalr	68(ra) # 8000372c <argstr>
    800066f0:	04054a63          	bltz	a0,80006744 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800066f4:	f6c40593          	addi	a1,s0,-148
    800066f8:	4505                	li	a0,1
    800066fa:	ffffd097          	auipc	ra,0xffffd
    800066fe:	fee080e7          	jalr	-18(ra) # 800036e8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006702:	04054163          	bltz	a0,80006744 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006706:	f6840593          	addi	a1,s0,-152
    8000670a:	4509                	li	a0,2
    8000670c:	ffffd097          	auipc	ra,0xffffd
    80006710:	fdc080e7          	jalr	-36(ra) # 800036e8 <argint>
     argint(1, &major) < 0 ||
    80006714:	02054863          	bltz	a0,80006744 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006718:	f6841683          	lh	a3,-152(s0)
    8000671c:	f6c41603          	lh	a2,-148(s0)
    80006720:	458d                	li	a1,3
    80006722:	f7040513          	addi	a0,s0,-144
    80006726:	fffff097          	auipc	ra,0xfffff
    8000672a:	776080e7          	jalr	1910(ra) # 80005e9c <create>
     argint(2, &minor) < 0 ||
    8000672e:	c919                	beqz	a0,80006744 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006730:	ffffe097          	auipc	ra,0xffffe
    80006734:	ff2080e7          	jalr	-14(ra) # 80004722 <iunlockput>
  end_op();
    80006738:	ffffe097          	auipc	ra,0xffffe
    8000673c:	7de080e7          	jalr	2014(ra) # 80004f16 <end_op>
  return 0;
    80006740:	4501                	li	a0,0
    80006742:	a031                	j	8000674e <sys_mknod+0x80>
    end_op();
    80006744:	ffffe097          	auipc	ra,0xffffe
    80006748:	7d2080e7          	jalr	2002(ra) # 80004f16 <end_op>
    return -1;
    8000674c:	557d                	li	a0,-1
}
    8000674e:	60ea                	ld	ra,152(sp)
    80006750:	644a                	ld	s0,144(sp)
    80006752:	610d                	addi	sp,sp,160
    80006754:	8082                	ret

0000000080006756 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006756:	7135                	addi	sp,sp,-160
    80006758:	ed06                	sd	ra,152(sp)
    8000675a:	e922                	sd	s0,144(sp)
    8000675c:	e526                	sd	s1,136(sp)
    8000675e:	e14a                	sd	s2,128(sp)
    80006760:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006762:	ffffb097          	auipc	ra,0xffffb
    80006766:	2d0080e7          	jalr	720(ra) # 80001a32 <myproc>
    8000676a:	892a                	mv	s2,a0
  
  begin_op();
    8000676c:	ffffe097          	auipc	ra,0xffffe
    80006770:	72a080e7          	jalr	1834(ra) # 80004e96 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006774:	08000613          	li	a2,128
    80006778:	f6040593          	addi	a1,s0,-160
    8000677c:	4501                	li	a0,0
    8000677e:	ffffd097          	auipc	ra,0xffffd
    80006782:	fae080e7          	jalr	-82(ra) # 8000372c <argstr>
    80006786:	04054b63          	bltz	a0,800067dc <sys_chdir+0x86>
    8000678a:	f6040513          	addi	a0,s0,-160
    8000678e:	ffffe097          	auipc	ra,0xffffe
    80006792:	4e8080e7          	jalr	1256(ra) # 80004c76 <namei>
    80006796:	84aa                	mv	s1,a0
    80006798:	c131                	beqz	a0,800067dc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000679a:	ffffe097          	auipc	ra,0xffffe
    8000679e:	d26080e7          	jalr	-730(ra) # 800044c0 <ilock>
  if(ip->type != T_DIR){
    800067a2:	04449703          	lh	a4,68(s1)
    800067a6:	4785                	li	a5,1
    800067a8:	04f71063          	bne	a4,a5,800067e8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800067ac:	8526                	mv	a0,s1
    800067ae:	ffffe097          	auipc	ra,0xffffe
    800067b2:	dd4080e7          	jalr	-556(ra) # 80004582 <iunlock>
  iput(p->cwd);
    800067b6:	26093503          	ld	a0,608(s2)
    800067ba:	ffffe097          	auipc	ra,0xffffe
    800067be:	ec0080e7          	jalr	-320(ra) # 8000467a <iput>
  end_op();
    800067c2:	ffffe097          	auipc	ra,0xffffe
    800067c6:	754080e7          	jalr	1876(ra) # 80004f16 <end_op>
  p->cwd = ip;
    800067ca:	26993023          	sd	s1,608(s2)
  return 0;
    800067ce:	4501                	li	a0,0
}
    800067d0:	60ea                	ld	ra,152(sp)
    800067d2:	644a                	ld	s0,144(sp)
    800067d4:	64aa                	ld	s1,136(sp)
    800067d6:	690a                	ld	s2,128(sp)
    800067d8:	610d                	addi	sp,sp,160
    800067da:	8082                	ret
    end_op();
    800067dc:	ffffe097          	auipc	ra,0xffffe
    800067e0:	73a080e7          	jalr	1850(ra) # 80004f16 <end_op>
    return -1;
    800067e4:	557d                	li	a0,-1
    800067e6:	b7ed                	j	800067d0 <sys_chdir+0x7a>
    iunlockput(ip);
    800067e8:	8526                	mv	a0,s1
    800067ea:	ffffe097          	auipc	ra,0xffffe
    800067ee:	f38080e7          	jalr	-200(ra) # 80004722 <iunlockput>
    end_op();
    800067f2:	ffffe097          	auipc	ra,0xffffe
    800067f6:	724080e7          	jalr	1828(ra) # 80004f16 <end_op>
    return -1;
    800067fa:	557d                	li	a0,-1
    800067fc:	bfd1                	j	800067d0 <sys_chdir+0x7a>

00000000800067fe <sys_exec>:

uint64
sys_exec(void)
{
    800067fe:	7145                	addi	sp,sp,-464
    80006800:	e786                	sd	ra,456(sp)
    80006802:	e3a2                	sd	s0,448(sp)
    80006804:	ff26                	sd	s1,440(sp)
    80006806:	fb4a                	sd	s2,432(sp)
    80006808:	f74e                	sd	s3,424(sp)
    8000680a:	f352                	sd	s4,416(sp)
    8000680c:	ef56                	sd	s5,408(sp)
    8000680e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006810:	08000613          	li	a2,128
    80006814:	f4040593          	addi	a1,s0,-192
    80006818:	4501                	li	a0,0
    8000681a:	ffffd097          	auipc	ra,0xffffd
    8000681e:	f12080e7          	jalr	-238(ra) # 8000372c <argstr>
    return -1;
    80006822:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006824:	0c054a63          	bltz	a0,800068f8 <sys_exec+0xfa>
    80006828:	e3840593          	addi	a1,s0,-456
    8000682c:	4505                	li	a0,1
    8000682e:	ffffd097          	auipc	ra,0xffffd
    80006832:	edc080e7          	jalr	-292(ra) # 8000370a <argaddr>
    80006836:	0c054163          	bltz	a0,800068f8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000683a:	10000613          	li	a2,256
    8000683e:	4581                	li	a1,0
    80006840:	e4040513          	addi	a0,s0,-448
    80006844:	ffffa097          	auipc	ra,0xffffa
    80006848:	49e080e7          	jalr	1182(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000684c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006850:	89a6                	mv	s3,s1
    80006852:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006854:	02000a13          	li	s4,32
    80006858:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000685c:	00391793          	slli	a5,s2,0x3
    80006860:	e3040593          	addi	a1,s0,-464
    80006864:	e3843503          	ld	a0,-456(s0)
    80006868:	953e                	add	a0,a0,a5
    8000686a:	ffffd097          	auipc	ra,0xffffd
    8000686e:	dde080e7          	jalr	-546(ra) # 80003648 <fetchaddr>
    80006872:	02054a63          	bltz	a0,800068a6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006876:	e3043783          	ld	a5,-464(s0)
    8000687a:	c3b9                	beqz	a5,800068c0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000687c:	ffffa097          	auipc	ra,0xffffa
    80006880:	256080e7          	jalr	598(ra) # 80000ad2 <kalloc>
    80006884:	85aa                	mv	a1,a0
    80006886:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000688a:	cd11                	beqz	a0,800068a6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000688c:	6605                	lui	a2,0x1
    8000688e:	e3043503          	ld	a0,-464(s0)
    80006892:	ffffd097          	auipc	ra,0xffffd
    80006896:	e0c080e7          	jalr	-500(ra) # 8000369e <fetchstr>
    8000689a:	00054663          	bltz	a0,800068a6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000689e:	0905                	addi	s2,s2,1
    800068a0:	09a1                	addi	s3,s3,8
    800068a2:	fb491be3          	bne	s2,s4,80006858 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068a6:	10048913          	addi	s2,s1,256
    800068aa:	6088                	ld	a0,0(s1)
    800068ac:	c529                	beqz	a0,800068f6 <sys_exec+0xf8>
    kfree(argv[i]);
    800068ae:	ffffa097          	auipc	ra,0xffffa
    800068b2:	128080e7          	jalr	296(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068b6:	04a1                	addi	s1,s1,8
    800068b8:	ff2499e3          	bne	s1,s2,800068aa <sys_exec+0xac>
  return -1;
    800068bc:	597d                	li	s2,-1
    800068be:	a82d                	j	800068f8 <sys_exec+0xfa>
      argv[i] = 0;
    800068c0:	0a8e                	slli	s5,s5,0x3
    800068c2:	fc040793          	addi	a5,s0,-64
    800068c6:	9abe                	add	s5,s5,a5
    800068c8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800068cc:	e4040593          	addi	a1,s0,-448
    800068d0:	f4040513          	addi	a0,s0,-192
    800068d4:	fffff097          	auipc	ra,0xfffff
    800068d8:	0e0080e7          	jalr	224(ra) # 800059b4 <exec>
    800068dc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068de:	10048993          	addi	s3,s1,256
    800068e2:	6088                	ld	a0,0(s1)
    800068e4:	c911                	beqz	a0,800068f8 <sys_exec+0xfa>
    kfree(argv[i]);
    800068e6:	ffffa097          	auipc	ra,0xffffa
    800068ea:	0f0080e7          	jalr	240(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068ee:	04a1                	addi	s1,s1,8
    800068f0:	ff3499e3          	bne	s1,s3,800068e2 <sys_exec+0xe4>
    800068f4:	a011                	j	800068f8 <sys_exec+0xfa>
  return -1;
    800068f6:	597d                	li	s2,-1
}
    800068f8:	854a                	mv	a0,s2
    800068fa:	60be                	ld	ra,456(sp)
    800068fc:	641e                	ld	s0,448(sp)
    800068fe:	74fa                	ld	s1,440(sp)
    80006900:	795a                	ld	s2,432(sp)
    80006902:	79ba                	ld	s3,424(sp)
    80006904:	7a1a                	ld	s4,416(sp)
    80006906:	6afa                	ld	s5,408(sp)
    80006908:	6179                	addi	sp,sp,464
    8000690a:	8082                	ret

000000008000690c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000690c:	7139                	addi	sp,sp,-64
    8000690e:	fc06                	sd	ra,56(sp)
    80006910:	f822                	sd	s0,48(sp)
    80006912:	f426                	sd	s1,40(sp)
    80006914:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006916:	ffffb097          	auipc	ra,0xffffb
    8000691a:	11c080e7          	jalr	284(ra) # 80001a32 <myproc>
    8000691e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006920:	fd840593          	addi	a1,s0,-40
    80006924:	4501                	li	a0,0
    80006926:	ffffd097          	auipc	ra,0xffffd
    8000692a:	de4080e7          	jalr	-540(ra) # 8000370a <argaddr>
    return -1;
    8000692e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006930:	0e054463          	bltz	a0,80006a18 <sys_pipe+0x10c>
  if(pipealloc(&rf, &wf) < 0)
    80006934:	fc840593          	addi	a1,s0,-56
    80006938:	fd040513          	addi	a0,s0,-48
    8000693c:	fffff097          	auipc	ra,0xfffff
    80006940:	d56080e7          	jalr	-682(ra) # 80005692 <pipealloc>
    return -1;
    80006944:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006946:	0c054963          	bltz	a0,80006a18 <sys_pipe+0x10c>
  fd0 = -1;
    8000694a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000694e:	fd043503          	ld	a0,-48(s0)
    80006952:	fffff097          	auipc	ra,0xfffff
    80006956:	508080e7          	jalr	1288(ra) # 80005e5a <fdalloc>
    8000695a:	fca42223          	sw	a0,-60(s0)
    8000695e:	0a054063          	bltz	a0,800069fe <sys_pipe+0xf2>
    80006962:	fc843503          	ld	a0,-56(s0)
    80006966:	fffff097          	auipc	ra,0xfffff
    8000696a:	4f4080e7          	jalr	1268(ra) # 80005e5a <fdalloc>
    8000696e:	fca42023          	sw	a0,-64(s0)
    80006972:	06054c63          	bltz	a0,800069ea <sys_pipe+0xde>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006976:	4691                	li	a3,4
    80006978:	fc440613          	addi	a2,s0,-60
    8000697c:	fd843583          	ld	a1,-40(s0)
    80006980:	1d84b503          	ld	a0,472(s1)
    80006984:	ffffb097          	auipc	ra,0xffffb
    80006988:	cde080e7          	jalr	-802(ra) # 80001662 <copyout>
    8000698c:	02054163          	bltz	a0,800069ae <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006990:	4691                	li	a3,4
    80006992:	fc040613          	addi	a2,s0,-64
    80006996:	fd843583          	ld	a1,-40(s0)
    8000699a:	0591                	addi	a1,a1,4
    8000699c:	1d84b503          	ld	a0,472(s1)
    800069a0:	ffffb097          	auipc	ra,0xffffb
    800069a4:	cc2080e7          	jalr	-830(ra) # 80001662 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800069a8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800069aa:	06055763          	bgez	a0,80006a18 <sys_pipe+0x10c>
    p->ofile[fd0] = 0;
    800069ae:	fc442783          	lw	a5,-60(s0)
    800069b2:	03c78793          	addi	a5,a5,60
    800069b6:	078e                	slli	a5,a5,0x3
    800069b8:	97a6                	add	a5,a5,s1
    800069ba:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800069be:	fc042503          	lw	a0,-64(s0)
    800069c2:	03c50513          	addi	a0,a0,60
    800069c6:	050e                	slli	a0,a0,0x3
    800069c8:	9526                	add	a0,a0,s1
    800069ca:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800069ce:	fd043503          	ld	a0,-48(s0)
    800069d2:	fffff097          	auipc	ra,0xfffff
    800069d6:	990080e7          	jalr	-1648(ra) # 80005362 <fileclose>
    fileclose(wf);
    800069da:	fc843503          	ld	a0,-56(s0)
    800069de:	fffff097          	auipc	ra,0xfffff
    800069e2:	984080e7          	jalr	-1660(ra) # 80005362 <fileclose>
    return -1;
    800069e6:	57fd                	li	a5,-1
    800069e8:	a805                	j	80006a18 <sys_pipe+0x10c>
    if(fd0 >= 0)
    800069ea:	fc442783          	lw	a5,-60(s0)
    800069ee:	0007c863          	bltz	a5,800069fe <sys_pipe+0xf2>
      p->ofile[fd0] = 0;
    800069f2:	03c78513          	addi	a0,a5,60
    800069f6:	050e                	slli	a0,a0,0x3
    800069f8:	9526                	add	a0,a0,s1
    800069fa:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800069fe:	fd043503          	ld	a0,-48(s0)
    80006a02:	fffff097          	auipc	ra,0xfffff
    80006a06:	960080e7          	jalr	-1696(ra) # 80005362 <fileclose>
    fileclose(wf);
    80006a0a:	fc843503          	ld	a0,-56(s0)
    80006a0e:	fffff097          	auipc	ra,0xfffff
    80006a12:	954080e7          	jalr	-1708(ra) # 80005362 <fileclose>
    return -1;
    80006a16:	57fd                	li	a5,-1
}
    80006a18:	853e                	mv	a0,a5
    80006a1a:	70e2                	ld	ra,56(sp)
    80006a1c:	7442                	ld	s0,48(sp)
    80006a1e:	74a2                	ld	s1,40(sp)
    80006a20:	6121                	addi	sp,sp,64
    80006a22:	8082                	ret
	...

0000000080006a30 <kernelvec>:
    80006a30:	7111                	addi	sp,sp,-256
    80006a32:	e006                	sd	ra,0(sp)
    80006a34:	e40a                	sd	sp,8(sp)
    80006a36:	e80e                	sd	gp,16(sp)
    80006a38:	ec12                	sd	tp,24(sp)
    80006a3a:	f016                	sd	t0,32(sp)
    80006a3c:	f41a                	sd	t1,40(sp)
    80006a3e:	f81e                	sd	t2,48(sp)
    80006a40:	fc22                	sd	s0,56(sp)
    80006a42:	e0a6                	sd	s1,64(sp)
    80006a44:	e4aa                	sd	a0,72(sp)
    80006a46:	e8ae                	sd	a1,80(sp)
    80006a48:	ecb2                	sd	a2,88(sp)
    80006a4a:	f0b6                	sd	a3,96(sp)
    80006a4c:	f4ba                	sd	a4,104(sp)
    80006a4e:	f8be                	sd	a5,112(sp)
    80006a50:	fcc2                	sd	a6,120(sp)
    80006a52:	e146                	sd	a7,128(sp)
    80006a54:	e54a                	sd	s2,136(sp)
    80006a56:	e94e                	sd	s3,144(sp)
    80006a58:	ed52                	sd	s4,152(sp)
    80006a5a:	f156                	sd	s5,160(sp)
    80006a5c:	f55a                	sd	s6,168(sp)
    80006a5e:	f95e                	sd	s7,176(sp)
    80006a60:	fd62                	sd	s8,184(sp)
    80006a62:	e1e6                	sd	s9,192(sp)
    80006a64:	e5ea                	sd	s10,200(sp)
    80006a66:	e9ee                	sd	s11,208(sp)
    80006a68:	edf2                	sd	t3,216(sp)
    80006a6a:	f1f6                	sd	t4,224(sp)
    80006a6c:	f5fa                	sd	t5,232(sp)
    80006a6e:	f9fe                	sd	t6,240(sp)
    80006a70:	aa7fc0ef          	jal	ra,80003516 <kerneltrap>
    80006a74:	6082                	ld	ra,0(sp)
    80006a76:	6122                	ld	sp,8(sp)
    80006a78:	61c2                	ld	gp,16(sp)
    80006a7a:	7282                	ld	t0,32(sp)
    80006a7c:	7322                	ld	t1,40(sp)
    80006a7e:	73c2                	ld	t2,48(sp)
    80006a80:	7462                	ld	s0,56(sp)
    80006a82:	6486                	ld	s1,64(sp)
    80006a84:	6526                	ld	a0,72(sp)
    80006a86:	65c6                	ld	a1,80(sp)
    80006a88:	6666                	ld	a2,88(sp)
    80006a8a:	7686                	ld	a3,96(sp)
    80006a8c:	7726                	ld	a4,104(sp)
    80006a8e:	77c6                	ld	a5,112(sp)
    80006a90:	7866                	ld	a6,120(sp)
    80006a92:	688a                	ld	a7,128(sp)
    80006a94:	692a                	ld	s2,136(sp)
    80006a96:	69ca                	ld	s3,144(sp)
    80006a98:	6a6a                	ld	s4,152(sp)
    80006a9a:	7a8a                	ld	s5,160(sp)
    80006a9c:	7b2a                	ld	s6,168(sp)
    80006a9e:	7bca                	ld	s7,176(sp)
    80006aa0:	7c6a                	ld	s8,184(sp)
    80006aa2:	6c8e                	ld	s9,192(sp)
    80006aa4:	6d2e                	ld	s10,200(sp)
    80006aa6:	6dce                	ld	s11,208(sp)
    80006aa8:	6e6e                	ld	t3,216(sp)
    80006aaa:	7e8e                	ld	t4,224(sp)
    80006aac:	7f2e                	ld	t5,232(sp)
    80006aae:	7fce                	ld	t6,240(sp)
    80006ab0:	6111                	addi	sp,sp,256
    80006ab2:	10200073          	sret
    80006ab6:	00000013          	nop
    80006aba:	00000013          	nop
    80006abe:	0001                	nop

0000000080006ac0 <timervec>:
    80006ac0:	34051573          	csrrw	a0,mscratch,a0
    80006ac4:	e10c                	sd	a1,0(a0)
    80006ac6:	e510                	sd	a2,8(a0)
    80006ac8:	e914                	sd	a3,16(a0)
    80006aca:	6d0c                	ld	a1,24(a0)
    80006acc:	7110                	ld	a2,32(a0)
    80006ace:	6194                	ld	a3,0(a1)
    80006ad0:	96b2                	add	a3,a3,a2
    80006ad2:	e194                	sd	a3,0(a1)
    80006ad4:	4589                	li	a1,2
    80006ad6:	14459073          	csrw	sip,a1
    80006ada:	6914                	ld	a3,16(a0)
    80006adc:	6510                	ld	a2,8(a0)
    80006ade:	610c                	ld	a1,0(a0)
    80006ae0:	34051573          	csrrw	a0,mscratch,a0
    80006ae4:	30200073          	mret
	...

0000000080006aea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006aea:	1141                	addi	sp,sp,-16
    80006aec:	e422                	sd	s0,8(sp)
    80006aee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006af0:	0c0007b7          	lui	a5,0xc000
    80006af4:	4705                	li	a4,1
    80006af6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006af8:	c3d8                	sw	a4,4(a5)
}
    80006afa:	6422                	ld	s0,8(sp)
    80006afc:	0141                	addi	sp,sp,16
    80006afe:	8082                	ret

0000000080006b00 <plicinithart>:

void
plicinithart(void)
{
    80006b00:	1141                	addi	sp,sp,-16
    80006b02:	e406                	sd	ra,8(sp)
    80006b04:	e022                	sd	s0,0(sp)
    80006b06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b08:	ffffb097          	auipc	ra,0xffffb
    80006b0c:	efe080e7          	jalr	-258(ra) # 80001a06 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006b10:	0085171b          	slliw	a4,a0,0x8
    80006b14:	0c0027b7          	lui	a5,0xc002
    80006b18:	97ba                	add	a5,a5,a4
    80006b1a:	40200713          	li	a4,1026
    80006b1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006b22:	00d5151b          	slliw	a0,a0,0xd
    80006b26:	0c2017b7          	lui	a5,0xc201
    80006b2a:	953e                	add	a0,a0,a5
    80006b2c:	00052023          	sw	zero,0(a0)
}
    80006b30:	60a2                	ld	ra,8(sp)
    80006b32:	6402                	ld	s0,0(sp)
    80006b34:	0141                	addi	sp,sp,16
    80006b36:	8082                	ret

0000000080006b38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006b38:	1141                	addi	sp,sp,-16
    80006b3a:	e406                	sd	ra,8(sp)
    80006b3c:	e022                	sd	s0,0(sp)
    80006b3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b40:	ffffb097          	auipc	ra,0xffffb
    80006b44:	ec6080e7          	jalr	-314(ra) # 80001a06 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006b48:	00d5179b          	slliw	a5,a0,0xd
    80006b4c:	0c201537          	lui	a0,0xc201
    80006b50:	953e                	add	a0,a0,a5
  return irq;
}
    80006b52:	4148                	lw	a0,4(a0)
    80006b54:	60a2                	ld	ra,8(sp)
    80006b56:	6402                	ld	s0,0(sp)
    80006b58:	0141                	addi	sp,sp,16
    80006b5a:	8082                	ret

0000000080006b5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006b5c:	1101                	addi	sp,sp,-32
    80006b5e:	ec06                	sd	ra,24(sp)
    80006b60:	e822                	sd	s0,16(sp)
    80006b62:	e426                	sd	s1,8(sp)
    80006b64:	1000                	addi	s0,sp,32
    80006b66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006b68:	ffffb097          	auipc	ra,0xffffb
    80006b6c:	e9e080e7          	jalr	-354(ra) # 80001a06 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006b70:	00d5151b          	slliw	a0,a0,0xd
    80006b74:	0c2017b7          	lui	a5,0xc201
    80006b78:	97aa                	add	a5,a5,a0
    80006b7a:	c3c4                	sw	s1,4(a5)
}
    80006b7c:	60e2                	ld	ra,24(sp)
    80006b7e:	6442                	ld	s0,16(sp)
    80006b80:	64a2                	ld	s1,8(sp)
    80006b82:	6105                	addi	sp,sp,32
    80006b84:	8082                	ret

0000000080006b86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006b86:	1141                	addi	sp,sp,-16
    80006b88:	e406                	sd	ra,8(sp)
    80006b8a:	e022                	sd	s0,0(sp)
    80006b8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006b8e:	479d                	li	a5,7
    80006b90:	06a7c963          	blt	a5,a0,80006c02 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006b94:	00039797          	auipc	a5,0x39
    80006b98:	46c78793          	addi	a5,a5,1132 # 80040000 <disk>
    80006b9c:	00a78733          	add	a4,a5,a0
    80006ba0:	6789                	lui	a5,0x2
    80006ba2:	97ba                	add	a5,a5,a4
    80006ba4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006ba8:	e7ad                	bnez	a5,80006c12 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006baa:	00451793          	slli	a5,a0,0x4
    80006bae:	0003b717          	auipc	a4,0x3b
    80006bb2:	45270713          	addi	a4,a4,1106 # 80042000 <disk+0x2000>
    80006bb6:	6314                	ld	a3,0(a4)
    80006bb8:	96be                	add	a3,a3,a5
    80006bba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006bbe:	6314                	ld	a3,0(a4)
    80006bc0:	96be                	add	a3,a3,a5
    80006bc2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006bc6:	6314                	ld	a3,0(a4)
    80006bc8:	96be                	add	a3,a3,a5
    80006bca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006bce:	6318                	ld	a4,0(a4)
    80006bd0:	97ba                	add	a5,a5,a4
    80006bd2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006bd6:	00039797          	auipc	a5,0x39
    80006bda:	42a78793          	addi	a5,a5,1066 # 80040000 <disk>
    80006bde:	97aa                	add	a5,a5,a0
    80006be0:	6509                	lui	a0,0x2
    80006be2:	953e                	add	a0,a0,a5
    80006be4:	4785                	li	a5,1
    80006be6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006bea:	0003b517          	auipc	a0,0x3b
    80006bee:	42e50513          	addi	a0,a0,1070 # 80042018 <disk+0x2018>
    80006bf2:	ffffc097          	auipc	ra,0xffffc
    80006bf6:	c70080e7          	jalr	-912(ra) # 80002862 <wakeup>
}
    80006bfa:	60a2                	ld	ra,8(sp)
    80006bfc:	6402                	ld	s0,0(sp)
    80006bfe:	0141                	addi	sp,sp,16
    80006c00:	8082                	ret
    panic("free_desc 1");
    80006c02:	00003517          	auipc	a0,0x3
    80006c06:	bd650513          	addi	a0,a0,-1066 # 800097d8 <syscalls+0x378>
    80006c0a:	ffffa097          	auipc	ra,0xffffa
    80006c0e:	920080e7          	jalr	-1760(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006c12:	00003517          	auipc	a0,0x3
    80006c16:	bd650513          	addi	a0,a0,-1066 # 800097e8 <syscalls+0x388>
    80006c1a:	ffffa097          	auipc	ra,0xffffa
    80006c1e:	910080e7          	jalr	-1776(ra) # 8000052a <panic>

0000000080006c22 <virtio_disk_init>:
{
    80006c22:	1101                	addi	sp,sp,-32
    80006c24:	ec06                	sd	ra,24(sp)
    80006c26:	e822                	sd	s0,16(sp)
    80006c28:	e426                	sd	s1,8(sp)
    80006c2a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006c2c:	00003597          	auipc	a1,0x3
    80006c30:	bcc58593          	addi	a1,a1,-1076 # 800097f8 <syscalls+0x398>
    80006c34:	0003b517          	auipc	a0,0x3b
    80006c38:	4f450513          	addi	a0,a0,1268 # 80042128 <disk+0x2128>
    80006c3c:	ffffa097          	auipc	ra,0xffffa
    80006c40:	ef6080e7          	jalr	-266(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c44:	100017b7          	lui	a5,0x10001
    80006c48:	4398                	lw	a4,0(a5)
    80006c4a:	2701                	sext.w	a4,a4
    80006c4c:	747277b7          	lui	a5,0x74727
    80006c50:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006c54:	0ef71163          	bne	a4,a5,80006d36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c58:	100017b7          	lui	a5,0x10001
    80006c5c:	43dc                	lw	a5,4(a5)
    80006c5e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c60:	4705                	li	a4,1
    80006c62:	0ce79a63          	bne	a5,a4,80006d36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c66:	100017b7          	lui	a5,0x10001
    80006c6a:	479c                	lw	a5,8(a5)
    80006c6c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c6e:	4709                	li	a4,2
    80006c70:	0ce79363          	bne	a5,a4,80006d36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006c74:	100017b7          	lui	a5,0x10001
    80006c78:	47d8                	lw	a4,12(a5)
    80006c7a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c7c:	554d47b7          	lui	a5,0x554d4
    80006c80:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006c84:	0af71963          	bne	a4,a5,80006d36 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c88:	100017b7          	lui	a5,0x10001
    80006c8c:	4705                	li	a4,1
    80006c8e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c90:	470d                	li	a4,3
    80006c92:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006c94:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006c96:	c7ffe737          	lui	a4,0xc7ffe
    80006c9a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fbb75f>
    80006c9e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006ca0:	2701                	sext.w	a4,a4
    80006ca2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ca4:	472d                	li	a4,11
    80006ca6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ca8:	473d                	li	a4,15
    80006caa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006cac:	6705                	lui	a4,0x1
    80006cae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006cb0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006cb4:	5bdc                	lw	a5,52(a5)
    80006cb6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006cb8:	c7d9                	beqz	a5,80006d46 <virtio_disk_init+0x124>
  if(max < NUM)
    80006cba:	471d                	li	a4,7
    80006cbc:	08f77d63          	bgeu	a4,a5,80006d56 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006cc0:	100014b7          	lui	s1,0x10001
    80006cc4:	47a1                	li	a5,8
    80006cc6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006cc8:	6609                	lui	a2,0x2
    80006cca:	4581                	li	a1,0
    80006ccc:	00039517          	auipc	a0,0x39
    80006cd0:	33450513          	addi	a0,a0,820 # 80040000 <disk>
    80006cd4:	ffffa097          	auipc	ra,0xffffa
    80006cd8:	00e080e7          	jalr	14(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006cdc:	00039717          	auipc	a4,0x39
    80006ce0:	32470713          	addi	a4,a4,804 # 80040000 <disk>
    80006ce4:	00c75793          	srli	a5,a4,0xc
    80006ce8:	2781                	sext.w	a5,a5
    80006cea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006cec:	0003b797          	auipc	a5,0x3b
    80006cf0:	31478793          	addi	a5,a5,788 # 80042000 <disk+0x2000>
    80006cf4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006cf6:	00039717          	auipc	a4,0x39
    80006cfa:	38a70713          	addi	a4,a4,906 # 80040080 <disk+0x80>
    80006cfe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006d00:	0003a717          	auipc	a4,0x3a
    80006d04:	30070713          	addi	a4,a4,768 # 80041000 <disk+0x1000>
    80006d08:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006d0a:	4705                	li	a4,1
    80006d0c:	00e78c23          	sb	a4,24(a5)
    80006d10:	00e78ca3          	sb	a4,25(a5)
    80006d14:	00e78d23          	sb	a4,26(a5)
    80006d18:	00e78da3          	sb	a4,27(a5)
    80006d1c:	00e78e23          	sb	a4,28(a5)
    80006d20:	00e78ea3          	sb	a4,29(a5)
    80006d24:	00e78f23          	sb	a4,30(a5)
    80006d28:	00e78fa3          	sb	a4,31(a5)
}
    80006d2c:	60e2                	ld	ra,24(sp)
    80006d2e:	6442                	ld	s0,16(sp)
    80006d30:	64a2                	ld	s1,8(sp)
    80006d32:	6105                	addi	sp,sp,32
    80006d34:	8082                	ret
    panic("could not find virtio disk");
    80006d36:	00003517          	auipc	a0,0x3
    80006d3a:	ad250513          	addi	a0,a0,-1326 # 80009808 <syscalls+0x3a8>
    80006d3e:	ffff9097          	auipc	ra,0xffff9
    80006d42:	7ec080e7          	jalr	2028(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006d46:	00003517          	auipc	a0,0x3
    80006d4a:	ae250513          	addi	a0,a0,-1310 # 80009828 <syscalls+0x3c8>
    80006d4e:	ffff9097          	auipc	ra,0xffff9
    80006d52:	7dc080e7          	jalr	2012(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006d56:	00003517          	auipc	a0,0x3
    80006d5a:	af250513          	addi	a0,a0,-1294 # 80009848 <syscalls+0x3e8>
    80006d5e:	ffff9097          	auipc	ra,0xffff9
    80006d62:	7cc080e7          	jalr	1996(ra) # 8000052a <panic>

0000000080006d66 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006d66:	7119                	addi	sp,sp,-128
    80006d68:	fc86                	sd	ra,120(sp)
    80006d6a:	f8a2                	sd	s0,112(sp)
    80006d6c:	f4a6                	sd	s1,104(sp)
    80006d6e:	f0ca                	sd	s2,96(sp)
    80006d70:	ecce                	sd	s3,88(sp)
    80006d72:	e8d2                	sd	s4,80(sp)
    80006d74:	e4d6                	sd	s5,72(sp)
    80006d76:	e0da                	sd	s6,64(sp)
    80006d78:	fc5e                	sd	s7,56(sp)
    80006d7a:	f862                	sd	s8,48(sp)
    80006d7c:	f466                	sd	s9,40(sp)
    80006d7e:	f06a                	sd	s10,32(sp)
    80006d80:	ec6e                	sd	s11,24(sp)
    80006d82:	0100                	addi	s0,sp,128
    80006d84:	8aaa                	mv	s5,a0
    80006d86:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006d88:	00c52c83          	lw	s9,12(a0)
    80006d8c:	001c9c9b          	slliw	s9,s9,0x1
    80006d90:	1c82                	slli	s9,s9,0x20
    80006d92:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006d96:	0003b517          	auipc	a0,0x3b
    80006d9a:	39250513          	addi	a0,a0,914 # 80042128 <disk+0x2128>
    80006d9e:	ffffa097          	auipc	ra,0xffffa
    80006da2:	e24080e7          	jalr	-476(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006da6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006da8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006daa:	00039c17          	auipc	s8,0x39
    80006dae:	256c0c13          	addi	s8,s8,598 # 80040000 <disk>
    80006db2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006db4:	4b0d                	li	s6,3
    80006db6:	a0ad                	j	80006e20 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006db8:	00fc0733          	add	a4,s8,a5
    80006dbc:	975e                	add	a4,a4,s7
    80006dbe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006dc2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006dc4:	0207c563          	bltz	a5,80006dee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006dc8:	2905                	addiw	s2,s2,1
    80006dca:	0611                	addi	a2,a2,4
    80006dcc:	19690d63          	beq	s2,s6,80006f66 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006dd0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006dd2:	0003b717          	auipc	a4,0x3b
    80006dd6:	24670713          	addi	a4,a4,582 # 80042018 <disk+0x2018>
    80006dda:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006ddc:	00074683          	lbu	a3,0(a4)
    80006de0:	fee1                	bnez	a3,80006db8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006de2:	2785                	addiw	a5,a5,1
    80006de4:	0705                	addi	a4,a4,1
    80006de6:	fe979be3          	bne	a5,s1,80006ddc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006dea:	57fd                	li	a5,-1
    80006dec:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006dee:	01205d63          	blez	s2,80006e08 <virtio_disk_rw+0xa2>
    80006df2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006df4:	000a2503          	lw	a0,0(s4)
    80006df8:	00000097          	auipc	ra,0x0
    80006dfc:	d8e080e7          	jalr	-626(ra) # 80006b86 <free_desc>
      for(int j = 0; j < i; j++)
    80006e00:	2d85                	addiw	s11,s11,1
    80006e02:	0a11                	addi	s4,s4,4
    80006e04:	ffb918e3          	bne	s2,s11,80006df4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006e08:	0003b597          	auipc	a1,0x3b
    80006e0c:	32058593          	addi	a1,a1,800 # 80042128 <disk+0x2128>
    80006e10:	0003b517          	auipc	a0,0x3b
    80006e14:	20850513          	addi	a0,a0,520 # 80042018 <disk+0x2018>
    80006e18:	ffffc097          	auipc	ra,0xffffc
    80006e1c:	8c0080e7          	jalr	-1856(ra) # 800026d8 <sleep>
  for(int i = 0; i < 3; i++){
    80006e20:	f8040a13          	addi	s4,s0,-128
{
    80006e24:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006e26:	894e                	mv	s2,s3
    80006e28:	b765                	j	80006dd0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006e2a:	0003b697          	auipc	a3,0x3b
    80006e2e:	1d66b683          	ld	a3,470(a3) # 80042000 <disk+0x2000>
    80006e32:	96ba                	add	a3,a3,a4
    80006e34:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006e38:	00039817          	auipc	a6,0x39
    80006e3c:	1c880813          	addi	a6,a6,456 # 80040000 <disk>
    80006e40:	0003b697          	auipc	a3,0x3b
    80006e44:	1c068693          	addi	a3,a3,448 # 80042000 <disk+0x2000>
    80006e48:	6290                	ld	a2,0(a3)
    80006e4a:	963a                	add	a2,a2,a4
    80006e4c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006e50:	0015e593          	ori	a1,a1,1
    80006e54:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006e58:	f8842603          	lw	a2,-120(s0)
    80006e5c:	628c                	ld	a1,0(a3)
    80006e5e:	972e                	add	a4,a4,a1
    80006e60:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006e64:	20050593          	addi	a1,a0,512
    80006e68:	0592                	slli	a1,a1,0x4
    80006e6a:	95c2                	add	a1,a1,a6
    80006e6c:	577d                	li	a4,-1
    80006e6e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006e72:	00461713          	slli	a4,a2,0x4
    80006e76:	6290                	ld	a2,0(a3)
    80006e78:	963a                	add	a2,a2,a4
    80006e7a:	03078793          	addi	a5,a5,48
    80006e7e:	97c2                	add	a5,a5,a6
    80006e80:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006e82:	629c                	ld	a5,0(a3)
    80006e84:	97ba                	add	a5,a5,a4
    80006e86:	4605                	li	a2,1
    80006e88:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006e8a:	629c                	ld	a5,0(a3)
    80006e8c:	97ba                	add	a5,a5,a4
    80006e8e:	4809                	li	a6,2
    80006e90:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006e94:	629c                	ld	a5,0(a3)
    80006e96:	973e                	add	a4,a4,a5
    80006e98:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006e9c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006ea0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ea4:	6698                	ld	a4,8(a3)
    80006ea6:	00275783          	lhu	a5,2(a4)
    80006eaa:	8b9d                	andi	a5,a5,7
    80006eac:	0786                	slli	a5,a5,0x1
    80006eae:	97ba                	add	a5,a5,a4
    80006eb0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006eb4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006eb8:	6698                	ld	a4,8(a3)
    80006eba:	00275783          	lhu	a5,2(a4)
    80006ebe:	2785                	addiw	a5,a5,1
    80006ec0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ec4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ec8:	100017b7          	lui	a5,0x10001
    80006ecc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006ed0:	004aa783          	lw	a5,4(s5)
    80006ed4:	02c79163          	bne	a5,a2,80006ef6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006ed8:	0003b917          	auipc	s2,0x3b
    80006edc:	25090913          	addi	s2,s2,592 # 80042128 <disk+0x2128>
  while(b->disk == 1) {
    80006ee0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006ee2:	85ca                	mv	a1,s2
    80006ee4:	8556                	mv	a0,s5
    80006ee6:	ffffb097          	auipc	ra,0xffffb
    80006eea:	7f2080e7          	jalr	2034(ra) # 800026d8 <sleep>
  while(b->disk == 1) {
    80006eee:	004aa783          	lw	a5,4(s5)
    80006ef2:	fe9788e3          	beq	a5,s1,80006ee2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006ef6:	f8042903          	lw	s2,-128(s0)
    80006efa:	20090793          	addi	a5,s2,512
    80006efe:	00479713          	slli	a4,a5,0x4
    80006f02:	00039797          	auipc	a5,0x39
    80006f06:	0fe78793          	addi	a5,a5,254 # 80040000 <disk>
    80006f0a:	97ba                	add	a5,a5,a4
    80006f0c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006f10:	0003b997          	auipc	s3,0x3b
    80006f14:	0f098993          	addi	s3,s3,240 # 80042000 <disk+0x2000>
    80006f18:	00491713          	slli	a4,s2,0x4
    80006f1c:	0009b783          	ld	a5,0(s3)
    80006f20:	97ba                	add	a5,a5,a4
    80006f22:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006f26:	854a                	mv	a0,s2
    80006f28:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006f2c:	00000097          	auipc	ra,0x0
    80006f30:	c5a080e7          	jalr	-934(ra) # 80006b86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006f34:	8885                	andi	s1,s1,1
    80006f36:	f0ed                	bnez	s1,80006f18 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006f38:	0003b517          	auipc	a0,0x3b
    80006f3c:	1f050513          	addi	a0,a0,496 # 80042128 <disk+0x2128>
    80006f40:	ffffa097          	auipc	ra,0xffffa
    80006f44:	d48080e7          	jalr	-696(ra) # 80000c88 <release>
}
    80006f48:	70e6                	ld	ra,120(sp)
    80006f4a:	7446                	ld	s0,112(sp)
    80006f4c:	74a6                	ld	s1,104(sp)
    80006f4e:	7906                	ld	s2,96(sp)
    80006f50:	69e6                	ld	s3,88(sp)
    80006f52:	6a46                	ld	s4,80(sp)
    80006f54:	6aa6                	ld	s5,72(sp)
    80006f56:	6b06                	ld	s6,64(sp)
    80006f58:	7be2                	ld	s7,56(sp)
    80006f5a:	7c42                	ld	s8,48(sp)
    80006f5c:	7ca2                	ld	s9,40(sp)
    80006f5e:	7d02                	ld	s10,32(sp)
    80006f60:	6de2                	ld	s11,24(sp)
    80006f62:	6109                	addi	sp,sp,128
    80006f64:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f66:	f8042503          	lw	a0,-128(s0)
    80006f6a:	20050793          	addi	a5,a0,512
    80006f6e:	0792                	slli	a5,a5,0x4
  if(write)
    80006f70:	00039817          	auipc	a6,0x39
    80006f74:	09080813          	addi	a6,a6,144 # 80040000 <disk>
    80006f78:	00f80733          	add	a4,a6,a5
    80006f7c:	01a036b3          	snez	a3,s10
    80006f80:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006f84:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006f88:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006f8c:	7679                	lui	a2,0xffffe
    80006f8e:	963e                	add	a2,a2,a5
    80006f90:	0003b697          	auipc	a3,0x3b
    80006f94:	07068693          	addi	a3,a3,112 # 80042000 <disk+0x2000>
    80006f98:	6298                	ld	a4,0(a3)
    80006f9a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f9c:	0a878593          	addi	a1,a5,168
    80006fa0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fa2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006fa4:	6298                	ld	a4,0(a3)
    80006fa6:	9732                	add	a4,a4,a2
    80006fa8:	45c1                	li	a1,16
    80006faa:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006fac:	6298                	ld	a4,0(a3)
    80006fae:	9732                	add	a4,a4,a2
    80006fb0:	4585                	li	a1,1
    80006fb2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006fb6:	f8442703          	lw	a4,-124(s0)
    80006fba:	628c                	ld	a1,0(a3)
    80006fbc:	962e                	add	a2,a2,a1
    80006fbe:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffbb00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006fc2:	0712                	slli	a4,a4,0x4
    80006fc4:	6290                	ld	a2,0(a3)
    80006fc6:	963a                	add	a2,a2,a4
    80006fc8:	058a8593          	addi	a1,s5,88
    80006fcc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006fce:	6294                	ld	a3,0(a3)
    80006fd0:	96ba                	add	a3,a3,a4
    80006fd2:	40000613          	li	a2,1024
    80006fd6:	c690                	sw	a2,8(a3)
  if(write)
    80006fd8:	e40d19e3          	bnez	s10,80006e2a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006fdc:	0003b697          	auipc	a3,0x3b
    80006fe0:	0246b683          	ld	a3,36(a3) # 80042000 <disk+0x2000>
    80006fe4:	96ba                	add	a3,a3,a4
    80006fe6:	4609                	li	a2,2
    80006fe8:	00c69623          	sh	a2,12(a3)
    80006fec:	b5b1                	j	80006e38 <virtio_disk_rw+0xd2>

0000000080006fee <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006fee:	1101                	addi	sp,sp,-32
    80006ff0:	ec06                	sd	ra,24(sp)
    80006ff2:	e822                	sd	s0,16(sp)
    80006ff4:	e426                	sd	s1,8(sp)
    80006ff6:	e04a                	sd	s2,0(sp)
    80006ff8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006ffa:	0003b517          	auipc	a0,0x3b
    80006ffe:	12e50513          	addi	a0,a0,302 # 80042128 <disk+0x2128>
    80007002:	ffffa097          	auipc	ra,0xffffa
    80007006:	bc0080e7          	jalr	-1088(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000700a:	10001737          	lui	a4,0x10001
    8000700e:	533c                	lw	a5,96(a4)
    80007010:	8b8d                	andi	a5,a5,3
    80007012:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007014:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007018:	0003b797          	auipc	a5,0x3b
    8000701c:	fe878793          	addi	a5,a5,-24 # 80042000 <disk+0x2000>
    80007020:	6b94                	ld	a3,16(a5)
    80007022:	0207d703          	lhu	a4,32(a5)
    80007026:	0026d783          	lhu	a5,2(a3)
    8000702a:	06f70163          	beq	a4,a5,8000708c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000702e:	00039917          	auipc	s2,0x39
    80007032:	fd290913          	addi	s2,s2,-46 # 80040000 <disk>
    80007036:	0003b497          	auipc	s1,0x3b
    8000703a:	fca48493          	addi	s1,s1,-54 # 80042000 <disk+0x2000>
    __sync_synchronize();
    8000703e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007042:	6898                	ld	a4,16(s1)
    80007044:	0204d783          	lhu	a5,32(s1)
    80007048:	8b9d                	andi	a5,a5,7
    8000704a:	078e                	slli	a5,a5,0x3
    8000704c:	97ba                	add	a5,a5,a4
    8000704e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007050:	20078713          	addi	a4,a5,512
    80007054:	0712                	slli	a4,a4,0x4
    80007056:	974a                	add	a4,a4,s2
    80007058:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000705c:	e731                	bnez	a4,800070a8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000705e:	20078793          	addi	a5,a5,512
    80007062:	0792                	slli	a5,a5,0x4
    80007064:	97ca                	add	a5,a5,s2
    80007066:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007068:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000706c:	ffffb097          	auipc	ra,0xffffb
    80007070:	7f6080e7          	jalr	2038(ra) # 80002862 <wakeup>

    disk.used_idx += 1;
    80007074:	0204d783          	lhu	a5,32(s1)
    80007078:	2785                	addiw	a5,a5,1
    8000707a:	17c2                	slli	a5,a5,0x30
    8000707c:	93c1                	srli	a5,a5,0x30
    8000707e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007082:	6898                	ld	a4,16(s1)
    80007084:	00275703          	lhu	a4,2(a4)
    80007088:	faf71be3          	bne	a4,a5,8000703e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000708c:	0003b517          	auipc	a0,0x3b
    80007090:	09c50513          	addi	a0,a0,156 # 80042128 <disk+0x2128>
    80007094:	ffffa097          	auipc	ra,0xffffa
    80007098:	bf4080e7          	jalr	-1036(ra) # 80000c88 <release>
}
    8000709c:	60e2                	ld	ra,24(sp)
    8000709e:	6442                	ld	s0,16(sp)
    800070a0:	64a2                	ld	s1,8(sp)
    800070a2:	6902                	ld	s2,0(sp)
    800070a4:	6105                	addi	sp,sp,32
    800070a6:	8082                	ret
      panic("virtio_disk_intr status");
    800070a8:	00002517          	auipc	a0,0x2
    800070ac:	7c050513          	addi	a0,a0,1984 # 80009868 <syscalls+0x408>
    800070b0:	ffff9097          	auipc	ra,0xffff9
    800070b4:	47a080e7          	jalr	1146(ra) # 8000052a <panic>
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
