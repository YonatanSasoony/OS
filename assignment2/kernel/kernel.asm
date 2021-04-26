
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
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
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000064:	00006797          	auipc	a5,0x6
    80000068:	12c78793          	addi	a5,a5,300 # 80006190 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd27ff>
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
    80000122:	676080e7          	jalr	1654(ra) # 80002794 <either_copyin>
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
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
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
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7ce080e7          	jalr	1998(ra) # 80001980 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	1c6080e7          	jalr	454(ra) # 80002388 <sleep>
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
    80000202:	53e080e7          	jalr	1342(ra) # 8000273c <either_copyout>
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
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
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
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
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
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
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
    800002e2:	50e080e7          	jalr	1294(ra) # 800027ec <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
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
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
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
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
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
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
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
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
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
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	0e4080e7          	jalr	228(ra) # 80002516 <wakeup>
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
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00027797          	auipc	a5,0x27
    80000468:	4b478793          	addi	a5,a5,1204 # 80027918 <devsw>
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
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
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
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
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
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
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
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
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
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
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
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
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
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
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
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
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
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
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
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
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
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
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
    80000882:	c98080e7          	jalr	-872(ra) # 80002516 <wakeup>
    
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
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	a7e080e7          	jalr	-1410(ra) # 80002388 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
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
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
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
    800009ea:	0002b797          	auipc	a5,0x2b
    800009ee:	61678793          	addi	a5,a5,1558 # 8002c000 <end>
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
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
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
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
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
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	0002b517          	auipc	a0,0x2b
    80000abe:	54650513          	addi	a0,a0,1350 # 8002c000 <end>
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
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
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
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
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
    80000b60:	e08080e7          	jalr	-504(ra) # 80001964 <mycpu>
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
    80000b92:	dd6080e7          	jalr	-554(ra) # 80001964 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dca080e7          	jalr	-566(ra) # 80001964 <mycpu>
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
    80000bb6:	db2080e7          	jalr	-590(ra) # 80001964 <mycpu>
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
    80000bf6:	d72080e7          	jalr	-654(ra) # 80001964 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
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
    80000c22:	d46080e7          	jalr	-698(ra) # 80001964 <mycpu>
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
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
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
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
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
    80000e78:	ae0080e7          	jalr	-1312(ra) # 80001954 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
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
    80000e94:	ac4080e7          	jalr	-1340(ra) # 80001954 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	c76080e7          	jalr	-906(ra) # 80002b28 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	316080e7          	jalr	790(ra) # 800061d0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	188080e7          	jalr	392(ra) # 8000204a <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
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
    80000f26:	980080e7          	jalr	-1664(ra) # 800018a2 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	bd6080e7          	jalr	-1066(ra) # 80002b00 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	bf6080e7          	jalr	-1034(ra) # 80002b28 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	280080e7          	jalr	640(ra) # 800061ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	28e080e7          	jalr	654(ra) # 800061d0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	422080e7          	jalr	1058(ra) # 8000336c <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	ab4080e7          	jalr	-1356(ra) # 80003a06 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	a62080e7          	jalr	-1438(ra) # 800049bc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	390080e7          	jalr	912(ra) # 800062f2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d26080e7          	jalr	-730(ra) # 80001c90 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
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
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
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
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
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
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
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
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
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
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
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
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	600080e7          	jalr	1536(ra) # 8000180c <proc_mapstacks>
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
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
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
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
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
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	daa50513          	addi	a0,a0,-598 # 80008140 <digits+0x100>
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
    800014d8:	00007517          	auipc	a0,0x7
    800014dc:	c8850513          	addi	a0,a0,-888 # 80008160 <digits+0x120>
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
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	bbc50513          	addi	a0,a0,-1092 # 80008170 <digits+0x130>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	bcc50513          	addi	a0,a0,-1076 # 80008190 <digits+0x150>
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
    8000162e:	00007517          	auipc	a0,0x7
    80001632:	b8250513          	addi	a0,a0,-1150 # 800081b0 <digits+0x170>
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
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd3000>
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

000000008000180c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000180c:	7139                	addi	sp,sp,-64
    8000180e:	fc06                	sd	ra,56(sp)
    80001810:	f822                	sd	s0,48(sp)
    80001812:	f426                	sd	s1,40(sp)
    80001814:	f04a                	sd	s2,32(sp)
    80001816:	ec4e                	sd	s3,24(sp)
    80001818:	e852                	sd	s4,16(sp)
    8000181a:	e456                	sd	s5,8(sp)
    8000181c:	e05a                	sd	s6,0(sp)
    8000181e:	0080                	addi	s0,sp,64
    80001820:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001822:	00010497          	auipc	s1,0x10
    80001826:	eae48493          	addi	s1,s1,-338 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000182a:	8b26                	mv	s6,s1
    8000182c:	00006a97          	auipc	s5,0x6
    80001830:	7d4a8a93          	addi	s5,s5,2004 # 80008000 <etext>
    80001834:	04000937          	lui	s2,0x4000
    80001838:	197d                	addi	s2,s2,-1
    8000183a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183c:	0001ca17          	auipc	s4,0x1c
    80001840:	e94a0a13          	addi	s4,s4,-364 # 8001d6d0 <tickslock>
    char *pa = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	28e080e7          	jalr	654(ra) # 80000ad2 <kalloc>
    8000184c:	862a                	mv	a2,a0
    if(pa == 0)
    8000184e:	c131                	beqz	a0,80001892 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001850:	416485b3          	sub	a1,s1,s6
    80001854:	85a1                	srai	a1,a1,0x8
    80001856:	000ab783          	ld	a5,0(s5)
    8000185a:	02f585b3          	mul	a1,a1,a5
    8000185e:	2585                	addiw	a1,a1,1
    80001860:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001864:	4719                	li	a4,6
    80001866:	6685                	lui	a3,0x1
    80001868:	40b905b3          	sub	a1,s2,a1
    8000186c:	854e                	mv	a0,s3
    8000186e:	00000097          	auipc	ra,0x0
    80001872:	8ae080e7          	jalr	-1874(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	30048493          	addi	s1,s1,768
    8000187a:	fd4495e3          	bne	s1,s4,80001844 <proc_mapstacks+0x38>
  }
}
    8000187e:	70e2                	ld	ra,56(sp)
    80001880:	7442                	ld	s0,48(sp)
    80001882:	74a2                	ld	s1,40(sp)
    80001884:	7902                	ld	s2,32(sp)
    80001886:	69e2                	ld	s3,24(sp)
    80001888:	6a42                	ld	s4,16(sp)
    8000188a:	6aa2                	ld	s5,8(sp)
    8000188c:	6b02                	ld	s6,0(sp)
    8000188e:	6121                	addi	sp,sp,64
    80001890:	8082                	ret
      panic("kalloc");
    80001892:	00007517          	auipc	a0,0x7
    80001896:	92e50513          	addi	a0,a0,-1746 # 800081c0 <digits+0x180>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	c90080e7          	jalr	-880(ra) # 8000052a <panic>

00000000800018a2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018a2:	7139                	addi	sp,sp,-64
    800018a4:	fc06                	sd	ra,56(sp)
    800018a6:	f822                	sd	s0,48(sp)
    800018a8:	f426                	sd	s1,40(sp)
    800018aa:	f04a                	sd	s2,32(sp)
    800018ac:	ec4e                	sd	s3,24(sp)
    800018ae:	e852                	sd	s4,16(sp)
    800018b0:	e456                	sd	s5,8(sp)
    800018b2:	e05a                	sd	s6,0(sp)
    800018b4:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018b6:	00007597          	auipc	a1,0x7
    800018ba:	91258593          	addi	a1,a1,-1774 # 800081c8 <digits+0x188>
    800018be:	00010517          	auipc	a0,0x10
    800018c2:	9e250513          	addi	a0,a0,-1566 # 800112a0 <pid_lock>
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	26c080e7          	jalr	620(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	90258593          	addi	a1,a1,-1790 # 800081d0 <digits+0x190>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9e250513          	addi	a0,a0,-1566 # 800112b8 <wait_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	254080e7          	jalr	596(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018e6:	00010497          	auipc	s1,0x10
    800018ea:	dea48493          	addi	s1,s1,-534 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    800018ee:	00007b17          	auipc	s6,0x7
    800018f2:	8f2b0b13          	addi	s6,s6,-1806 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    800018f6:	8aa6                	mv	s5,s1
    800018f8:	00006a17          	auipc	s4,0x6
    800018fc:	708a0a13          	addi	s4,s4,1800 # 80008000 <etext>
    80001900:	04000937          	lui	s2,0x4000
    80001904:	197d                	addi	s2,s2,-1
    80001906:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001908:	0001c997          	auipc	s3,0x1c
    8000190c:	dc898993          	addi	s3,s3,-568 # 8001d6d0 <tickslock>
      initlock(&p->lock, "proc");
    80001910:	85da                	mv	a1,s6
    80001912:	8526                	mv	a0,s1
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	21e080e7          	jalr	542(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000191c:	415487b3          	sub	a5,s1,s5
    80001920:	87a1                	srai	a5,a5,0x8
    80001922:	000a3703          	ld	a4,0(s4)
    80001926:	02e787b3          	mul	a5,a5,a4
    8000192a:	2785                	addiw	a5,a5,1
    8000192c:	00d7979b          	slliw	a5,a5,0xd
    80001930:	40f907b3          	sub	a5,s2,a5
    80001934:	1cf4bc23          	sd	a5,472(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001938:	30048493          	addi	s1,s1,768
    8000193c:	fd349ae3          	bne	s1,s3,80001910 <procinit+0x6e>
  }
}
    80001940:	70e2                	ld	ra,56(sp)
    80001942:	7442                	ld	s0,48(sp)
    80001944:	74a2                	ld	s1,40(sp)
    80001946:	7902                	ld	s2,32(sp)
    80001948:	69e2                	ld	s3,24(sp)
    8000194a:	6a42                	ld	s4,16(sp)
    8000194c:	6aa2                	ld	s5,8(sp)
    8000194e:	6b02                	ld	s6,0(sp)
    80001950:	6121                	addi	sp,sp,64
    80001952:	8082                	ret

0000000080001954 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001954:	1141                	addi	sp,sp,-16
    80001956:	e422                	sd	s0,8(sp)
    80001958:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000195a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000195c:	2501                	sext.w	a0,a0
    8000195e:	6422                	ld	s0,8(sp)
    80001960:	0141                	addi	sp,sp,16
    80001962:	8082                	ret

0000000080001964 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001964:	1141                	addi	sp,sp,-16
    80001966:	e422                	sd	s0,8(sp)
    80001968:	0800                	addi	s0,sp,16
    8000196a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000196c:	2781                	sext.w	a5,a5
    8000196e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001970:	00010517          	auipc	a0,0x10
    80001974:	96050513          	addi	a0,a0,-1696 # 800112d0 <cpus>
    80001978:	953e                	add	a0,a0,a5
    8000197a:	6422                	ld	s0,8(sp)
    8000197c:	0141                	addi	sp,sp,16
    8000197e:	8082                	ret

0000000080001980 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001980:	1101                	addi	sp,sp,-32
    80001982:	ec06                	sd	ra,24(sp)
    80001984:	e822                	sd	s0,16(sp)
    80001986:	e426                	sd	s1,8(sp)
    80001988:	1000                	addi	s0,sp,32
  push_off();
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	1ec080e7          	jalr	492(ra) # 80000b76 <push_off>
    80001992:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001994:	2781                	sext.w	a5,a5
    80001996:	079e                	slli	a5,a5,0x7
    80001998:	00010717          	auipc	a4,0x10
    8000199c:	90870713          	addi	a4,a4,-1784 # 800112a0 <pid_lock>
    800019a0:	97ba                	add	a5,a5,a4
    800019a2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019a4:	fffff097          	auipc	ra,0xfffff
    800019a8:	272080e7          	jalr	626(ra) # 80000c16 <pop_off>
  return p;
}
    800019ac:	8526                	mv	a0,s1
    800019ae:	60e2                	ld	ra,24(sp)
    800019b0:	6442                	ld	s0,16(sp)
    800019b2:	64a2                	ld	s1,8(sp)
    800019b4:	6105                	addi	sp,sp,32
    800019b6:	8082                	ret

00000000800019b8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019b8:	1141                	addi	sp,sp,-16
    800019ba:	e406                	sd	ra,8(sp)
    800019bc:	e022                	sd	s0,0(sp)
    800019be:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019c0:	00000097          	auipc	ra,0x0
    800019c4:	fc0080e7          	jalr	-64(ra) # 80001980 <myproc>
    800019c8:	fffff097          	auipc	ra,0xfffff
    800019cc:	2ae080e7          	jalr	686(ra) # 80000c76 <release>

  if (first) {
    800019d0:	00007797          	auipc	a5,0x7
    800019d4:	e407a783          	lw	a5,-448(a5) # 80008810 <first.1>
    800019d8:	eb89                	bnez	a5,800019ea <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019da:	00001097          	auipc	ra,0x1
    800019de:	166080e7          	jalr	358(ra) # 80002b40 <usertrapret>
}
    800019e2:	60a2                	ld	ra,8(sp)
    800019e4:	6402                	ld	s0,0(sp)
    800019e6:	0141                	addi	sp,sp,16
    800019e8:	8082                	ret
    first = 0;
    800019ea:	00007797          	auipc	a5,0x7
    800019ee:	e207a323          	sw	zero,-474(a5) # 80008810 <first.1>
    fsinit(ROOTDEV);
    800019f2:	4505                	li	a0,1
    800019f4:	00002097          	auipc	ra,0x2
    800019f8:	f92080e7          	jalr	-110(ra) # 80003986 <fsinit>
    800019fc:	bff9                	j	800019da <forkret+0x22>

00000000800019fe <allocpid>:
allocpid() {
    800019fe:	1101                	addi	sp,sp,-32
    80001a00:	ec06                	sd	ra,24(sp)
    80001a02:	e822                	sd	s0,16(sp)
    80001a04:	e426                	sd	s1,8(sp)
    80001a06:	e04a                	sd	s2,0(sp)
    80001a08:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a0a:	00010917          	auipc	s2,0x10
    80001a0e:	89690913          	addi	s2,s2,-1898 # 800112a0 <pid_lock>
    80001a12:	854a                	mv	a0,s2
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a1c:	00007797          	auipc	a5,0x7
    80001a20:	df878793          	addi	a5,a5,-520 # 80008814 <nextpid>
    80001a24:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a26:	0014871b          	addiw	a4,s1,1
    80001a2a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a2c:	854a                	mv	a0,s2
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	248080e7          	jalr	584(ra) # 80000c76 <release>
}
    80001a36:	8526                	mv	a0,s1
    80001a38:	60e2                	ld	ra,24(sp)
    80001a3a:	6442                	ld	s0,16(sp)
    80001a3c:	64a2                	ld	s1,8(sp)
    80001a3e:	6902                	ld	s2,0(sp)
    80001a40:	6105                	addi	sp,sp,32
    80001a42:	8082                	ret

0000000080001a44 <proc_pagetable>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
    80001a50:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a52:	00000097          	auipc	ra,0x0
    80001a56:	8b4080e7          	jalr	-1868(ra) # 80001306 <uvmcreate>
    80001a5a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a5c:	c121                	beqz	a0,80001a9c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a5e:	4729                	li	a4,10
    80001a60:	00005697          	auipc	a3,0x5
    80001a64:	5a068693          	addi	a3,a3,1440 # 80007000 <_trampoline>
    80001a68:	6605                	lui	a2,0x1
    80001a6a:	040005b7          	lui	a1,0x4000
    80001a6e:	15fd                	addi	a1,a1,-1
    80001a70:	05b2                	slli	a1,a1,0xc
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	61c080e7          	jalr	1564(ra) # 8000108e <mappages>
    80001a7a:	02054863          	bltz	a0,80001aaa <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a7e:	4719                	li	a4,6
    80001a80:	1f093683          	ld	a3,496(s2)
    80001a84:	6605                	lui	a2,0x1
    80001a86:	020005b7          	lui	a1,0x2000
    80001a8a:	15fd                	addi	a1,a1,-1
    80001a8c:	05b6                	slli	a1,a1,0xd
    80001a8e:	8526                	mv	a0,s1
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	5fe080e7          	jalr	1534(ra) # 8000108e <mappages>
    80001a98:	02054163          	bltz	a0,80001aba <proc_pagetable+0x76>
}
    80001a9c:	8526                	mv	a0,s1
    80001a9e:	60e2                	ld	ra,24(sp)
    80001aa0:	6442                	ld	s0,16(sp)
    80001aa2:	64a2                	ld	s1,8(sp)
    80001aa4:	6902                	ld	s2,0(sp)
    80001aa6:	6105                	addi	sp,sp,32
    80001aa8:	8082                	ret
    uvmfree(pagetable, 0);
    80001aaa:	4581                	li	a1,0
    80001aac:	8526                	mv	a0,s1
    80001aae:	00000097          	auipc	ra,0x0
    80001ab2:	a54080e7          	jalr	-1452(ra) # 80001502 <uvmfree>
    return 0;
    80001ab6:	4481                	li	s1,0
    80001ab8:	b7d5                	j	80001a9c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aba:	4681                	li	a3,0
    80001abc:	4605                	li	a2,1
    80001abe:	040005b7          	lui	a1,0x4000
    80001ac2:	15fd                	addi	a1,a1,-1
    80001ac4:	05b2                	slli	a1,a1,0xc
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	77a080e7          	jalr	1914(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ad0:	4581                	li	a1,0
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	a2e080e7          	jalr	-1490(ra) # 80001502 <uvmfree>
    return 0;
    80001adc:	4481                	li	s1,0
    80001ade:	bf7d                	j	80001a9c <proc_pagetable+0x58>

0000000080001ae0 <proc_freepagetable>:
{
    80001ae0:	1101                	addi	sp,sp,-32
    80001ae2:	ec06                	sd	ra,24(sp)
    80001ae4:	e822                	sd	s0,16(sp)
    80001ae6:	e426                	sd	s1,8(sp)
    80001ae8:	e04a                	sd	s2,0(sp)
    80001aea:	1000                	addi	s0,sp,32
    80001aec:	84aa                	mv	s1,a0
    80001aee:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af0:	4681                	li	a3,0
    80001af2:	4605                	li	a2,1
    80001af4:	040005b7          	lui	a1,0x4000
    80001af8:	15fd                	addi	a1,a1,-1
    80001afa:	05b2                	slli	a1,a1,0xc
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	746080e7          	jalr	1862(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b04:	4681                	li	a3,0
    80001b06:	4605                	li	a2,1
    80001b08:	020005b7          	lui	a1,0x2000
    80001b0c:	15fd                	addi	a1,a1,-1
    80001b0e:	05b6                	slli	a1,a1,0xd
    80001b10:	8526                	mv	a0,s1
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	730080e7          	jalr	1840(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b1a:	85ca                	mv	a1,s2
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	00000097          	auipc	ra,0x0
    80001b22:	9e4080e7          	jalr	-1564(ra) # 80001502 <uvmfree>
}
    80001b26:	60e2                	ld	ra,24(sp)
    80001b28:	6442                	ld	s0,16(sp)
    80001b2a:	64a2                	ld	s1,8(sp)
    80001b2c:	6902                	ld	s2,0(sp)
    80001b2e:	6105                	addi	sp,sp,32
    80001b30:	8082                	ret

0000000080001b32 <freeproc>:
{
    80001b32:	1101                	addi	sp,sp,-32
    80001b34:	ec06                	sd	ra,24(sp)
    80001b36:	e822                	sd	s0,16(sp)
    80001b38:	e426                	sd	s1,8(sp)
    80001b3a:	1000                	addi	s0,sp,32
    80001b3c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b3e:	1f053503          	ld	a0,496(a0)
    80001b42:	c509                	beqz	a0,80001b4c <freeproc+0x1a>
    kfree((void*)p->trapframe);
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	e92080e7          	jalr	-366(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b4c:	1e04b823          	sd	zero,496(s1)
  if(p->pagetable)
    80001b50:	1e84b503          	ld	a0,488(s1)
    80001b54:	c519                	beqz	a0,80001b62 <freeproc+0x30>
    proc_freepagetable(p->pagetable, p->sz);
    80001b56:	1e04b583          	ld	a1,480(s1)
    80001b5a:	00000097          	auipc	ra,0x0
    80001b5e:	f86080e7          	jalr	-122(ra) # 80001ae0 <proc_freepagetable>
  p->pagetable = 0;
    80001b62:	1e04b423          	sd	zero,488(s1)
  p->sz = 0;
    80001b66:	1e04b023          	sd	zero,480(s1)
  p->pid = 0;
    80001b6a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b6e:	1c04b823          	sd	zero,464(s1)
  p->name[0] = 0;
    80001b72:	2e048823          	sb	zero,752(s1)
  p->chan = 0;
    80001b76:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b7a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b7e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b82:	0004ac23          	sw	zero,24(s1)
}
    80001b86:	60e2                	ld	ra,24(sp)
    80001b88:	6442                	ld	s0,16(sp)
    80001b8a:	64a2                	ld	s1,8(sp)
    80001b8c:	6105                	addi	sp,sp,32
    80001b8e:	8082                	ret

0000000080001b90 <allocproc>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	e04a                	sd	s2,0(sp)
    80001b9a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b9c:	00010497          	auipc	s1,0x10
    80001ba0:	b3448493          	addi	s1,s1,-1228 # 800116d0 <proc>
    80001ba4:	0001c917          	auipc	s2,0x1c
    80001ba8:	b2c90913          	addi	s2,s2,-1236 # 8001d6d0 <tickslock>
    acquire(&p->lock);
    80001bac:	8526                	mv	a0,s1
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	014080e7          	jalr	20(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bb6:	4c9c                	lw	a5,24(s1)
    80001bb8:	cf81                	beqz	a5,80001bd0 <allocproc+0x40>
      release(&p->lock);
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	0ba080e7          	jalr	186(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc4:	30048493          	addi	s1,s1,768
    80001bc8:	ff2492e3          	bne	s1,s2,80001bac <allocproc+0x1c>
  return 0;
    80001bcc:	4481                	li	s1,0
    80001bce:	a0b5                	j	80001c3a <allocproc+0xaa>
  p->pid = allocpid();
    80001bd0:	00000097          	auipc	ra,0x0
    80001bd4:	e2e080e7          	jalr	-466(ra) # 800019fe <allocpid>
    80001bd8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bda:	4785                	li	a5,1
    80001bdc:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	ef4080e7          	jalr	-268(ra) # 80000ad2 <kalloc>
    80001be6:	892a                	mv	s2,a0
    80001be8:	1ea4b823          	sd	a0,496(s1)
    80001bec:	cd31                	beqz	a0,80001c48 <allocproc+0xb8>
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ee4080e7          	jalr	-284(ra) # 80000ad2 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	1ca4b023          	sd	a0,448(s1)
    80001bfc:	c135                	beqz	a0,80001c60 <allocproc+0xd0>
  p->pagetable = proc_pagetable(p);
    80001bfe:	8526                	mv	a0,s1
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	e44080e7          	jalr	-444(ra) # 80001a44 <proc_pagetable>
    80001c08:	892a                	mv	s2,a0
    80001c0a:	1ea4b423          	sd	a0,488(s1)
  if(p->pagetable == 0){
    80001c0e:	c52d                	beqz	a0,80001c78 <allocproc+0xe8>
  memset(&p->context, 0, sizeof(p->context));
    80001c10:	07000613          	li	a2,112
    80001c14:	4581                	li	a1,0
    80001c16:	1f848513          	addi	a0,s1,504
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	0a4080e7          	jalr	164(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c22:	00000797          	auipc	a5,0x0
    80001c26:	d9678793          	addi	a5,a5,-618 # 800019b8 <forkret>
    80001c2a:	1ef4bc23          	sd	a5,504(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c2e:	1d84b783          	ld	a5,472(s1)
    80001c32:	6705                	lui	a4,0x1
    80001c34:	97ba                	add	a5,a5,a4
    80001c36:	20f4b023          	sd	a5,512(s1)
}
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6902                	ld	s2,0(sp)
    80001c44:	6105                	addi	sp,sp,32
    80001c46:	8082                	ret
    freeproc(p);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	00000097          	auipc	ra,0x0
    80001c4e:	ee8080e7          	jalr	-280(ra) # 80001b32 <freeproc>
    release(&p->lock);
    80001c52:	8526                	mv	a0,s1
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	022080e7          	jalr	34(ra) # 80000c76 <release>
    return 0;
    80001c5c:	84ca                	mv	s1,s2
    80001c5e:	bff1                	j	80001c3a <allocproc+0xaa>
    freeproc(p);
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	ed0080e7          	jalr	-304(ra) # 80001b32 <freeproc>
    release(&p->lock);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	00a080e7          	jalr	10(ra) # 80000c76 <release>
    return 0;
    80001c74:	84ca                	mv	s1,s2
    80001c76:	b7d1                	j	80001c3a <allocproc+0xaa>
    freeproc(p);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	eb8080e7          	jalr	-328(ra) # 80001b32 <freeproc>
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	ff2080e7          	jalr	-14(ra) # 80000c76 <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	b775                	j	80001c3a <allocproc+0xaa>

0000000080001c90 <userinit>:
{
    80001c90:	1101                	addi	sp,sp,-32
    80001c92:	ec06                	sd	ra,24(sp)
    80001c94:	e822                	sd	s0,16(sp)
    80001c96:	e426                	sd	s1,8(sp)
    80001c98:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	ef6080e7          	jalr	-266(ra) # 80001b90 <allocproc>
    80001ca2:	84aa                	mv	s1,a0
  initproc = p;
    80001ca4:	00007797          	auipc	a5,0x7
    80001ca8:	38a7b223          	sd	a0,900(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cac:	03400613          	li	a2,52
    80001cb0:	00007597          	auipc	a1,0x7
    80001cb4:	b7058593          	addi	a1,a1,-1168 # 80008820 <initcode>
    80001cb8:	1e853503          	ld	a0,488(a0)
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	678080e7          	jalr	1656(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001cc4:	6785                	lui	a5,0x1
    80001cc6:	1ef4b023          	sd	a5,480(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cca:	1f04b703          	ld	a4,496(s1)
    80001cce:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd2:	1f04b703          	ld	a4,496(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	50e58593          	addi	a1,a1,1294 # 800081e8 <digits+0x1a8>
    80001ce2:	2f048513          	addi	a0,s1,752
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	12a080e7          	jalr	298(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	50a50513          	addi	a0,a0,1290 # 800081f8 <digits+0x1b8>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	6be080e7          	jalr	1726(ra) # 800043b4 <namei>
    80001cfe:	2ea4b423          	sd	a0,744(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f6e080e7          	jalr	-146(ra) # 80000c76 <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c58080e7          	jalr	-936(ra) # 80001980 <myproc>
    80001d30:	892a                	mv	s2,a0
  sz = p->sz;
    80001d32:	1e053583          	ld	a1,480(a0)
    80001d36:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d3a:	00904f63          	bgtz	s1,80001d58 <growproc+0x3e>
  } else if(n < 0){
    80001d3e:	0204cd63          	bltz	s1,80001d78 <growproc+0x5e>
  p->sz = sz;
    80001d42:	1602                	slli	a2,a2,0x20
    80001d44:	9201                	srli	a2,a2,0x20
    80001d46:	1ec93023          	sd	a2,480(s2)
  return 0;
    80001d4a:	4501                	li	a0,0
}
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6902                	ld	s2,0(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d58:	9e25                	addw	a2,a2,s1
    80001d5a:	1602                	slli	a2,a2,0x20
    80001d5c:	9201                	srli	a2,a2,0x20
    80001d5e:	1582                	slli	a1,a1,0x20
    80001d60:	9181                	srli	a1,a1,0x20
    80001d62:	1e853503          	ld	a0,488(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	688080e7          	jalr	1672(ra) # 800013ee <uvmalloc>
    80001d6e:	0005061b          	sext.w	a2,a0
    80001d72:	fa61                	bnez	a2,80001d42 <growproc+0x28>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bfd9                	j	80001d4c <growproc+0x32>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	9e25                	addw	a2,a2,s1
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	1e853503          	ld	a0,488(a0)
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	620080e7          	jalr	1568(ra) # 800013a6 <uvmdealloc>
    80001d8e:	0005061b          	sext.w	a2,a0
    80001d92:	bf45                	j	80001d42 <growproc+0x28>

0000000080001d94 <fork>:
{
    80001d94:	7139                	addi	sp,sp,-64
    80001d96:	fc06                	sd	ra,56(sp)
    80001d98:	f822                	sd	s0,48(sp)
    80001d9a:	f426                	sd	s1,40(sp)
    80001d9c:	f04a                	sd	s2,32(sp)
    80001d9e:	ec4e                	sd	s3,24(sp)
    80001da0:	e852                	sd	s4,16(sp)
    80001da2:	e456                	sd	s5,8(sp)
    80001da4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	bda080e7          	jalr	-1062(ra) # 80001980 <myproc>
    80001dae:	892a                	mv	s2,a0
  if((np = allocproc()) == 0) {
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	de0080e7          	jalr	-544(ra) # 80001b90 <allocproc>
    80001db8:	12050f63          	beqz	a0,80001ef6 <fork+0x162>
    80001dbc:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dbe:	1e093603          	ld	a2,480(s2)
    80001dc2:	1e853583          	ld	a1,488(a0)
    80001dc6:	1e893503          	ld	a0,488(s2)
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	770080e7          	jalr	1904(ra) # 8000153a <uvmcopy>
    80001dd2:	04054863          	bltz	a0,80001e22 <fork+0x8e>
  np->sz = p->sz;
    80001dd6:	1e093783          	ld	a5,480(s2)
    80001dda:	1efa3023          	sd	a5,480(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dde:	1f093683          	ld	a3,496(s2)
    80001de2:	87b6                	mv	a5,a3
    80001de4:	1f0a3703          	ld	a4,496(s4)
    80001de8:	12068693          	addi	a3,a3,288
    80001dec:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df0:	6788                	ld	a0,8(a5)
    80001df2:	6b8c                	ld	a1,16(a5)
    80001df4:	6f90                	ld	a2,24(a5)
    80001df6:	01073023          	sd	a6,0(a4)
    80001dfa:	e708                	sd	a0,8(a4)
    80001dfc:	eb0c                	sd	a1,16(a4)
    80001dfe:	ef10                	sd	a2,24(a4)
    80001e00:	02078793          	addi	a5,a5,32
    80001e04:	02070713          	addi	a4,a4,32
    80001e08:	fed792e3          	bne	a5,a3,80001dec <fork+0x58>
  np->trapframe->a0 = 0;
    80001e0c:	1f0a3783          	ld	a5,496(s4)
    80001e10:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e14:	26890493          	addi	s1,s2,616
    80001e18:	268a0993          	addi	s3,s4,616
    80001e1c:	2e890a93          	addi	s5,s2,744
    80001e20:	a00d                	j	80001e42 <fork+0xae>
    freeproc(np);
    80001e22:	8552                	mv	a0,s4
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	d0e080e7          	jalr	-754(ra) # 80001b32 <freeproc>
    release(&np->lock);
    80001e2c:	8552                	mv	a0,s4
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	e48080e7          	jalr	-440(ra) # 80000c76 <release>
    return -1;
    80001e36:	59fd                	li	s3,-1
    80001e38:	a06d                	j	80001ee2 <fork+0x14e>
  for(i = 0; i < NOFILE; i++)
    80001e3a:	04a1                	addi	s1,s1,8
    80001e3c:	09a1                	addi	s3,s3,8
    80001e3e:	01548b63          	beq	s1,s5,80001e54 <fork+0xc0>
    if(p->ofile[i])
    80001e42:	6088                	ld	a0,0(s1)
    80001e44:	d97d                	beqz	a0,80001e3a <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e46:	00003097          	auipc	ra,0x3
    80001e4a:	c08080e7          	jalr	-1016(ra) # 80004a4e <filedup>
    80001e4e:	00a9b023          	sd	a0,0(s3)
    80001e52:	b7e5                	j	80001e3a <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e54:	2e893503          	ld	a0,744(s2)
    80001e58:	00002097          	auipc	ra,0x2
    80001e5c:	d68080e7          	jalr	-664(ra) # 80003bc0 <idup>
    80001e60:	2eaa3423          	sd	a0,744(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e64:	4641                	li	a2,16
    80001e66:	2f090593          	addi	a1,s2,752
    80001e6a:	2f0a0513          	addi	a0,s4,752
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	fa2080e7          	jalr	-94(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e76:	030a2983          	lw	s3,48(s4)
  release(&np->lock);
    80001e7a:	8552                	mv	a0,s4
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	dfa080e7          	jalr	-518(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e84:	0000f497          	auipc	s1,0xf
    80001e88:	43448493          	addi	s1,s1,1076 # 800112b8 <wait_lock>
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	d34080e7          	jalr	-716(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e96:	1d2a3823          	sd	s2,464(s4)
  release(&wait_lock);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dda080e7          	jalr	-550(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	d1c080e7          	jalr	-740(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001eae:	478d                	li	a5,3
    80001eb0:	00fa2c23          	sw	a5,24(s4)
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
    80001eb4:	03892783          	lw	a5,56(s2)
    80001eb8:	02fa2c23          	sw	a5,56(s4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80001ebc:	04090793          	addi	a5,s2,64
    80001ec0:	040a0713          	addi	a4,s4,64
    80001ec4:	14090613          	addi	a2,s2,320
    np->signal_handlers[i] = p->signal_handlers[i];    
    80001ec8:	6394                	ld	a3,0(a5)
    80001eca:	e314                	sd	a3,0(a4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80001ecc:	07a1                	addi	a5,a5,8
    80001ece:	0721                	addi	a4,a4,8
    80001ed0:	fec79ce3          	bne	a5,a2,80001ec8 <fork+0x134>
  np->pending_signals = 0; // ADDED Q2.1.2
    80001ed4:	020a2a23          	sw	zero,52(s4)
  release(&np->lock);
    80001ed8:	8552                	mv	a0,s4
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	d9c080e7          	jalr	-612(ra) # 80000c76 <release>
}
    80001ee2:	854e                	mv	a0,s3
    80001ee4:	70e2                	ld	ra,56(sp)
    80001ee6:	7442                	ld	s0,48(sp)
    80001ee8:	74a2                	ld	s1,40(sp)
    80001eea:	7902                	ld	s2,32(sp)
    80001eec:	69e2                	ld	s3,24(sp)
    80001eee:	6a42                	ld	s4,16(sp)
    80001ef0:	6aa2                	ld	s5,8(sp)
    80001ef2:	6121                	addi	sp,sp,64
    80001ef4:	8082                	ret
    return -1;
    80001ef6:	59fd                	li	s3,-1
    80001ef8:	b7ed                	j	80001ee2 <fork+0x14e>

0000000080001efa <kill_handler>:
{
    80001efa:	1141                	addi	sp,sp,-16
    80001efc:	e406                	sd	ra,8(sp)
    80001efe:	e022                	sd	s0,0(sp)
    80001f00:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	a7e080e7          	jalr	-1410(ra) # 80001980 <myproc>
  p->killed = 1; 
    80001f0a:	4785                	li	a5,1
    80001f0c:	d51c                	sw	a5,40(a0)
}
    80001f0e:	60a2                	ld	ra,8(sp)
    80001f10:	6402                	ld	s0,0(sp)
    80001f12:	0141                	addi	sp,sp,16
    80001f14:	8082                	ret

0000000080001f16 <received_continue>:
{
    80001f16:	1101                	addi	sp,sp,-32
    80001f18:	ec06                	sd	ra,24(sp)
    80001f1a:	e822                	sd	s0,16(sp)
    80001f1c:	e426                	sd	s1,8(sp)
    80001f1e:	e04a                	sd	s2,0(sp)
    80001f20:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80001f22:	00000097          	auipc	ra,0x0
    80001f26:	a5e080e7          	jalr	-1442(ra) # 80001980 <myproc>
    80001f2a:	892a                	mv	s2,a0
    acquire(&p->lock);
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	c96080e7          	jalr	-874(ra) # 80000bc2 <acquire>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    80001f34:	03892683          	lw	a3,56(s2)
    80001f38:	fff6c693          	not	a3,a3
    80001f3c:	03492783          	lw	a5,52(s2)
    80001f40:	8efd                	and	a3,a3,a5
    80001f42:	2681                	sext.w	a3,a3
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001f44:	04090713          	addi	a4,s2,64
    80001f48:	4781                	li	a5,0
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001f4a:	454d                	li	a0,19
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001f4c:	02000613          	li	a2,32
    80001f50:	a801                	j	80001f60 <received_continue+0x4a>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001f52:	630c                	ld	a1,0(a4)
    80001f54:	00a58f63          	beq	a1,a0,80001f72 <received_continue+0x5c>
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001f58:	2785                	addiw	a5,a5,1
    80001f5a:	0721                	addi	a4,a4,8
    80001f5c:	02c78163          	beq	a5,a2,80001f7e <received_continue+0x68>
      if( (pending_and_not_blocked & (1 << signum)) &&
    80001f60:	40f6d4bb          	sraw	s1,a3,a5
    80001f64:	8885                	andi	s1,s1,1
    80001f66:	d8ed                	beqz	s1,80001f58 <received_continue+0x42>
    80001f68:	0d893583          	ld	a1,216(s2)
    80001f6c:	f1fd                	bnez	a1,80001f52 <received_continue+0x3c>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001f6e:	fea792e3          	bne	a5,a0,80001f52 <received_continue+0x3c>
            release(&p->lock);
    80001f72:	854a                	mv	a0,s2
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	d02080e7          	jalr	-766(ra) # 80000c76 <release>
            return 1;
    80001f7c:	a039                	j	80001f8a <received_continue+0x74>
    release(&p->lock);
    80001f7e:	854a                	mv	a0,s2
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	cf6080e7          	jalr	-778(ra) # 80000c76 <release>
    return 0;
    80001f88:	4481                	li	s1,0
}
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	60e2                	ld	ra,24(sp)
    80001f8e:	6442                	ld	s0,16(sp)
    80001f90:	64a2                	ld	s1,8(sp)
    80001f92:	6902                	ld	s2,0(sp)
    80001f94:	6105                	addi	sp,sp,32
    80001f96:	8082                	ret

0000000080001f98 <continue_handler>:
{
    80001f98:	1141                	addi	sp,sp,-16
    80001f9a:	e406                	sd	ra,8(sp)
    80001f9c:	e022                	sd	s0,0(sp)
    80001f9e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	9e0080e7          	jalr	-1568(ra) # 80001980 <myproc>
  p->stopped = 0;
    80001fa8:	1c052423          	sw	zero,456(a0)
}
    80001fac:	60a2                	ld	ra,8(sp)
    80001fae:	6402                	ld	s0,0(sp)
    80001fb0:	0141                	addi	sp,sp,16
    80001fb2:	8082                	ret

0000000080001fb4 <handle_user_signals>:
handle_user_signals(int signum) {
    80001fb4:	1101                	addi	sp,sp,-32
    80001fb6:	ec06                	sd	ra,24(sp)
    80001fb8:	e822                	sd	s0,16(sp)
    80001fba:	e426                	sd	s1,8(sp)
    80001fbc:	e04a                	sd	s2,0(sp)
    80001fbe:	1000                	addi	s0,sp,32
    80001fc0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	9be080e7          	jalr	-1602(ra) # 80001980 <myproc>
    80001fca:	84aa                	mv	s1,a0
  p->signal_mask_backup = p->signal_mask;
    80001fcc:	5d1c                	lw	a5,56(a0)
    80001fce:	dd5c                	sw	a5,60(a0)
  p->signal_mask = p->signal_handlers_masks[signum];  
    80001fd0:	05090793          	addi	a5,s2,80
    80001fd4:	078a                	slli	a5,a5,0x2
    80001fd6:	97aa                	add	a5,a5,a0
    80001fd8:	439c                	lw	a5,0(a5)
    80001fda:	dd1c                	sw	a5,56(a0)
  memmove(p->trapframe_backup, p->trapframe, sizeof(struct trapframe));
    80001fdc:	12000613          	li	a2,288
    80001fe0:	1f053583          	ld	a1,496(a0)
    80001fe4:	1c053503          	ld	a0,448(a0)
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	d32080e7          	jalr	-718(ra) # 80000d1a <memmove>
  p->trapframe->sp = p->trapframe->sp - inject_sigret_size;
    80001ff0:	1f04b703          	ld	a4,496(s1)
  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
    80001ff4:	00005617          	auipc	a2,0x5
    80001ff8:	11e60613          	addi	a2,a2,286 # 80007112 <start_inject_sigret>
  p->trapframe->sp = p->trapframe->sp - inject_sigret_size;
    80001ffc:	00005697          	auipc	a3,0x5
    80002000:	11c68693          	addi	a3,a3,284 # 80007118 <end_inject_sigret>
    80002004:	9e91                	subw	a3,a3,a2
    80002006:	7b1c                	ld	a5,48(a4)
    80002008:	8f95                	sub	a5,a5,a3
    8000200a:	fb1c                	sd	a5,48(a4)
  copyout(p->pagetable, (uint64) (p->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);
    8000200c:	1f04b783          	ld	a5,496(s1)
    80002010:	7b8c                	ld	a1,48(a5)
    80002012:	1e84b503          	ld	a0,488(s1)
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	628080e7          	jalr	1576(ra) # 8000163e <copyout>
  p->trapframe->a0 = signum;
    8000201e:	1f04b783          	ld	a5,496(s1)
    80002022:	0727b823          	sd	s2,112(a5)
  p->trapframe->epc = (uint64)p->signal_handlers[signum];
    80002026:	1f04b783          	ld	a5,496(s1)
    8000202a:	0921                	addi	s2,s2,8
    8000202c:	090e                	slli	s2,s2,0x3
    8000202e:	9926                	add	s2,s2,s1
    80002030:	00093703          	ld	a4,0(s2)
    80002034:	ef98                	sd	a4,24(a5)
  p->trapframe->ra = p->trapframe->sp;
    80002036:	1f04b783          	ld	a5,496(s1)
    8000203a:	7b98                	ld	a4,48(a5)
    8000203c:	f798                	sd	a4,40(a5)
}
    8000203e:	60e2                	ld	ra,24(sp)
    80002040:	6442                	ld	s0,16(sp)
    80002042:	64a2                	ld	s1,8(sp)
    80002044:	6902                	ld	s2,0(sp)
    80002046:	6105                	addi	sp,sp,32
    80002048:	8082                	ret

000000008000204a <scheduler>:
{
    8000204a:	7139                	addi	sp,sp,-64
    8000204c:	fc06                	sd	ra,56(sp)
    8000204e:	f822                	sd	s0,48(sp)
    80002050:	f426                	sd	s1,40(sp)
    80002052:	f04a                	sd	s2,32(sp)
    80002054:	ec4e                	sd	s3,24(sp)
    80002056:	e852                	sd	s4,16(sp)
    80002058:	e456                	sd	s5,8(sp)
    8000205a:	e05a                	sd	s6,0(sp)
    8000205c:	0080                	addi	s0,sp,64
    8000205e:	8792                	mv	a5,tp
  int id = r_tp();
    80002060:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002062:	00779a93          	slli	s5,a5,0x7
    80002066:	0000f717          	auipc	a4,0xf
    8000206a:	23a70713          	addi	a4,a4,570 # 800112a0 <pid_lock>
    8000206e:	9756                	add	a4,a4,s5
    80002070:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002074:	0000f717          	auipc	a4,0xf
    80002078:	26470713          	addi	a4,a4,612 # 800112d8 <cpus+0x8>
    8000207c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000207e:	498d                	li	s3,3
        p->state = RUNNING;
    80002080:	4b11                	li	s6,4
        c->proc = p;
    80002082:	079e                	slli	a5,a5,0x7
    80002084:	0000fa17          	auipc	s4,0xf
    80002088:	21ca0a13          	addi	s4,s4,540 # 800112a0 <pid_lock>
    8000208c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000208e:	0001b917          	auipc	s2,0x1b
    80002092:	64290913          	addi	s2,s2,1602 # 8001d6d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002096:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000209a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000209e:	10079073          	csrw	sstatus,a5
    800020a2:	0000f497          	auipc	s1,0xf
    800020a6:	62e48493          	addi	s1,s1,1582 # 800116d0 <proc>
    800020aa:	a811                	j	800020be <scheduler+0x74>
      release(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bc8080e7          	jalr	-1080(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020b6:	30048493          	addi	s1,s1,768
    800020ba:	fd248ee3          	beq	s1,s2,80002096 <scheduler+0x4c>
      acquire(&p->lock);
    800020be:	8526                	mv	a0,s1
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b02080e7          	jalr	-1278(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    800020c8:	4c9c                	lw	a5,24(s1)
    800020ca:	ff3791e3          	bne	a5,s3,800020ac <scheduler+0x62>
        p->state = RUNNING;
    800020ce:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020d2:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020d6:	1f848593          	addi	a1,s1,504
    800020da:	8556                	mv	a0,s5
    800020dc:	00001097          	auipc	ra,0x1
    800020e0:	9ba080e7          	jalr	-1606(ra) # 80002a96 <swtch>
        c->proc = 0;
    800020e4:	020a3823          	sd	zero,48(s4)
    800020e8:	b7d1                	j	800020ac <scheduler+0x62>

00000000800020ea <sched>:
{
    800020ea:	7179                	addi	sp,sp,-48
    800020ec:	f406                	sd	ra,40(sp)
    800020ee:	f022                	sd	s0,32(sp)
    800020f0:	ec26                	sd	s1,24(sp)
    800020f2:	e84a                	sd	s2,16(sp)
    800020f4:	e44e                	sd	s3,8(sp)
    800020f6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	888080e7          	jalr	-1912(ra) # 80001980 <myproc>
    80002100:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	a46080e7          	jalr	-1466(ra) # 80000b48 <holding>
    8000210a:	c93d                	beqz	a0,80002180 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000210c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000210e:	2781                	sext.w	a5,a5
    80002110:	079e                	slli	a5,a5,0x7
    80002112:	0000f717          	auipc	a4,0xf
    80002116:	18e70713          	addi	a4,a4,398 # 800112a0 <pid_lock>
    8000211a:	97ba                	add	a5,a5,a4
    8000211c:	0a87a703          	lw	a4,168(a5)
    80002120:	4785                	li	a5,1
    80002122:	06f71763          	bne	a4,a5,80002190 <sched+0xa6>
  if(p->state == RUNNING)
    80002126:	4c98                	lw	a4,24(s1)
    80002128:	4791                	li	a5,4
    8000212a:	06f70b63          	beq	a4,a5,800021a0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000212e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002132:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002134:	efb5                	bnez	a5,800021b0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002136:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002138:	0000f917          	auipc	s2,0xf
    8000213c:	16890913          	addi	s2,s2,360 # 800112a0 <pid_lock>
    80002140:	2781                	sext.w	a5,a5
    80002142:	079e                	slli	a5,a5,0x7
    80002144:	97ca                	add	a5,a5,s2
    80002146:	0ac7a983          	lw	s3,172(a5)
    8000214a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000214c:	2781                	sext.w	a5,a5
    8000214e:	079e                	slli	a5,a5,0x7
    80002150:	0000f597          	auipc	a1,0xf
    80002154:	18858593          	addi	a1,a1,392 # 800112d8 <cpus+0x8>
    80002158:	95be                	add	a1,a1,a5
    8000215a:	1f848513          	addi	a0,s1,504
    8000215e:	00001097          	auipc	ra,0x1
    80002162:	938080e7          	jalr	-1736(ra) # 80002a96 <swtch>
    80002166:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002168:	2781                	sext.w	a5,a5
    8000216a:	079e                	slli	a5,a5,0x7
    8000216c:	97ca                	add	a5,a5,s2
    8000216e:	0b37a623          	sw	s3,172(a5)
}
    80002172:	70a2                	ld	ra,40(sp)
    80002174:	7402                	ld	s0,32(sp)
    80002176:	64e2                	ld	s1,24(sp)
    80002178:	6942                	ld	s2,16(sp)
    8000217a:	69a2                	ld	s3,8(sp)
    8000217c:	6145                	addi	sp,sp,48
    8000217e:	8082                	ret
    panic("sched p->lock");
    80002180:	00006517          	auipc	a0,0x6
    80002184:	08050513          	addi	a0,a0,128 # 80008200 <digits+0x1c0>
    80002188:	ffffe097          	auipc	ra,0xffffe
    8000218c:	3a2080e7          	jalr	930(ra) # 8000052a <panic>
    panic("sched locks");
    80002190:	00006517          	auipc	a0,0x6
    80002194:	08050513          	addi	a0,a0,128 # 80008210 <digits+0x1d0>
    80002198:	ffffe097          	auipc	ra,0xffffe
    8000219c:	392080e7          	jalr	914(ra) # 8000052a <panic>
    panic("sched running");
    800021a0:	00006517          	auipc	a0,0x6
    800021a4:	08050513          	addi	a0,a0,128 # 80008220 <digits+0x1e0>
    800021a8:	ffffe097          	auipc	ra,0xffffe
    800021ac:	382080e7          	jalr	898(ra) # 8000052a <panic>
    panic("sched interruptible");
    800021b0:	00006517          	auipc	a0,0x6
    800021b4:	08050513          	addi	a0,a0,128 # 80008230 <digits+0x1f0>
    800021b8:	ffffe097          	auipc	ra,0xffffe
    800021bc:	372080e7          	jalr	882(ra) # 8000052a <panic>

00000000800021c0 <yield>:
{
    800021c0:	1101                	addi	sp,sp,-32
    800021c2:	ec06                	sd	ra,24(sp)
    800021c4:	e822                	sd	s0,16(sp)
    800021c6:	e426                	sd	s1,8(sp)
    800021c8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	7b6080e7          	jalr	1974(ra) # 80001980 <myproc>
    800021d2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	9ee080e7          	jalr	-1554(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    800021dc:	478d                	li	a5,3
    800021de:	cc9c                	sw	a5,24(s1)
  sched();
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	f0a080e7          	jalr	-246(ra) # 800020ea <sched>
  release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	a8c080e7          	jalr	-1396(ra) # 80000c76 <release>
}
    800021f2:	60e2                	ld	ra,24(sp)
    800021f4:	6442                	ld	s0,16(sp)
    800021f6:	64a2                	ld	s1,8(sp)
    800021f8:	6105                	addi	sp,sp,32
    800021fa:	8082                	ret

00000000800021fc <stop_handler>:
{
    800021fc:	1101                	addi	sp,sp,-32
    800021fe:	ec06                	sd	ra,24(sp)
    80002200:	e822                	sd	s0,16(sp)
    80002202:	e426                	sd	s1,8(sp)
    80002204:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	77a080e7          	jalr	1914(ra) # 80001980 <myproc>
    8000220e:	84aa                	mv	s1,a0
  p->stopped = 1;
    80002210:	4785                	li	a5,1
    80002212:	1cf52423          	sw	a5,456(a0)
  release(&p->lock);
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	a60080e7          	jalr	-1440(ra) # 80000c76 <release>
  while (p->stopped && !received_continue())
    8000221e:	1c84a783          	lw	a5,456(s1)
    80002222:	cf89                	beqz	a5,8000223c <stop_handler+0x40>
    80002224:	00000097          	auipc	ra,0x0
    80002228:	cf2080e7          	jalr	-782(ra) # 80001f16 <received_continue>
    8000222c:	e901                	bnez	a0,8000223c <stop_handler+0x40>
      yield();
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	f92080e7          	jalr	-110(ra) # 800021c0 <yield>
  while (p->stopped && !received_continue())
    80002236:	1c84a783          	lw	a5,456(s1)
    8000223a:	f7ed                	bnez	a5,80002224 <stop_handler+0x28>
  acquire(&p->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	984080e7          	jalr	-1660(ra) # 80000bc2 <acquire>
}
    80002246:	60e2                	ld	ra,24(sp)
    80002248:	6442                	ld	s0,16(sp)
    8000224a:	64a2                	ld	s1,8(sp)
    8000224c:	6105                	addi	sp,sp,32
    8000224e:	8082                	ret

0000000080002250 <handle_signals>:
{
    80002250:	711d                	addi	sp,sp,-96
    80002252:	ec86                	sd	ra,88(sp)
    80002254:	e8a2                	sd	s0,80(sp)
    80002256:	e4a6                	sd	s1,72(sp)
    80002258:	e0ca                	sd	s2,64(sp)
    8000225a:	fc4e                	sd	s3,56(sp)
    8000225c:	f852                	sd	s4,48(sp)
    8000225e:	f456                	sd	s5,40(sp)
    80002260:	f05a                	sd	s6,32(sp)
    80002262:	ec5e                	sd	s7,24(sp)
    80002264:	e862                	sd	s8,16(sp)
    80002266:	e466                	sd	s9,8(sp)
    80002268:	e06a                	sd	s10,0(sp)
    8000226a:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	714080e7          	jalr	1812(ra) # 80001980 <myproc>
    80002274:	8a2a                	mv	s4,a0
  acquire(&p->lock);
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	94c080e7          	jalr	-1716(ra) # 80000bc2 <acquire>
  int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    8000227e:	038a2983          	lw	s3,56(s4)
    80002282:	fff9c993          	not	s3,s3
    80002286:	034a2783          	lw	a5,52(s4)
    8000228a:	00f9f9b3          	and	s3,s3,a5
    8000228e:	2981                	sext.w	s3,s3
  for(int signum = 0; signum < SIG_NUM; signum++){
    80002290:	040a0913          	addi	s2,s4,64
    80002294:	4481                	li	s1,0
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002296:	4b85                	li	s7,1
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    80002298:	4b45                	li	s6,17
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    8000229a:	4c4d                	li	s8,19
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    8000229c:	4ca5                	li	s9,9
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    8000229e:	4d05                	li	s10,1
  for(int signum = 0; signum < SIG_NUM; signum++){
    800022a0:	02000a93          	li	s5,32
    800022a4:	a0a1                	j	800022ec <handle_signals+0x9c>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800022a6:	03648263          	beq	s1,s6,800022ca <handle_signals+0x7a>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800022aa:	09848463          	beq	s1,s8,80002332 <handle_signals+0xe2>
        kill_handler();
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	c4c080e7          	jalr	-948(ra) # 80001efa <kill_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800022b6:	009b97bb          	sllw	a5,s7,s1
    800022ba:	fff7c793          	not	a5,a5
    800022be:	034a2703          	lw	a4,52(s4)
    800022c2:	8ff9                	and	a5,a5,a4
    800022c4:	02fa2a23          	sw	a5,52(s4)
    800022c8:	a831                	j	800022e4 <handle_signals+0x94>
        stop_handler();
    800022ca:	00000097          	auipc	ra,0x0
    800022ce:	f32080e7          	jalr	-206(ra) # 800021fc <stop_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800022d2:	009b97bb          	sllw	a5,s7,s1
    800022d6:	fff7c793          	not	a5,a5
    800022da:	034a2703          	lw	a4,52(s4)
    800022de:	8ff9                	and	a5,a5,a4
    800022e0:	02fa2a23          	sw	a5,52(s4)
  for(int signum = 0; signum < SIG_NUM; signum++){
    800022e4:	2485                	addiw	s1,s1,1
    800022e6:	0921                	addi	s2,s2,8
    800022e8:	07548d63          	beq	s1,s5,80002362 <handle_signals+0x112>
    if(pending_and_not_blocked & (1 << signum)){
    800022ec:	4099d7bb          	sraw	a5,s3,s1
    800022f0:	8b85                	andi	a5,a5,1
    800022f2:	dbed                	beqz	a5,800022e4 <handle_signals+0x94>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800022f4:	00093783          	ld	a5,0(s2)
    800022f8:	d7dd                	beqz	a5,800022a6 <handle_signals+0x56>
    800022fa:	fd6788e3          	beq	a5,s6,800022ca <handle_signals+0x7a>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800022fe:	03878a63          	beq	a5,s8,80002332 <handle_signals+0xe2>
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    80002302:	fb9786e3          	beq	a5,s9,800022ae <handle_signals+0x5e>
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    80002306:	05a78463          	beq	a5,s10,8000234e <handle_signals+0xfe>
      } else if (p->handling_user_level_signal == 0){
    8000230a:	1cca2783          	lw	a5,460(s4)
    8000230e:	fbf9                	bnez	a5,800022e4 <handle_signals+0x94>
        p->handling_user_level_signal = 1;
    80002310:	1daa2623          	sw	s10,460(s4)
        handle_user_signals(signum);
    80002314:	8526                	mv	a0,s1
    80002316:	00000097          	auipc	ra,0x0
    8000231a:	c9e080e7          	jalr	-866(ra) # 80001fb4 <handle_user_signals>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000231e:	009b97bb          	sllw	a5,s7,s1
    80002322:	fff7c793          	not	a5,a5
    80002326:	034a2703          	lw	a4,52(s4)
    8000232a:	8ff9                	and	a5,a5,a4
    8000232c:	02fa2a23          	sw	a5,52(s4)
    80002330:	bf55                	j	800022e4 <handle_signals+0x94>
        continue_handler();
    80002332:	00000097          	auipc	ra,0x0
    80002336:	c66080e7          	jalr	-922(ra) # 80001f98 <continue_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000233a:	009b97bb          	sllw	a5,s7,s1
    8000233e:	fff7c793          	not	a5,a5
    80002342:	034a2703          	lw	a4,52(s4)
    80002346:	8ff9                	and	a5,a5,a4
    80002348:	02fa2a23          	sw	a5,52(s4)
    8000234c:	bf61                	j	800022e4 <handle_signals+0x94>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000234e:	009b97bb          	sllw	a5,s7,s1
    80002352:	fff7c793          	not	a5,a5
    80002356:	034a2703          	lw	a4,52(s4)
    8000235a:	8ff9                	and	a5,a5,a4
    8000235c:	02fa2a23          	sw	a5,52(s4)
    80002360:	b751                	j	800022e4 <handle_signals+0x94>
  release(&p->lock);
    80002362:	8552                	mv	a0,s4
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	912080e7          	jalr	-1774(ra) # 80000c76 <release>
}
    8000236c:	60e6                	ld	ra,88(sp)
    8000236e:	6446                	ld	s0,80(sp)
    80002370:	64a6                	ld	s1,72(sp)
    80002372:	6906                	ld	s2,64(sp)
    80002374:	79e2                	ld	s3,56(sp)
    80002376:	7a42                	ld	s4,48(sp)
    80002378:	7aa2                	ld	s5,40(sp)
    8000237a:	7b02                	ld	s6,32(sp)
    8000237c:	6be2                	ld	s7,24(sp)
    8000237e:	6c42                	ld	s8,16(sp)
    80002380:	6ca2                	ld	s9,8(sp)
    80002382:	6d02                	ld	s10,0(sp)
    80002384:	6125                	addi	sp,sp,96
    80002386:	8082                	ret

0000000080002388 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002388:	7179                	addi	sp,sp,-48
    8000238a:	f406                	sd	ra,40(sp)
    8000238c:	f022                	sd	s0,32(sp)
    8000238e:	ec26                	sd	s1,24(sp)
    80002390:	e84a                	sd	s2,16(sp)
    80002392:	e44e                	sd	s3,8(sp)
    80002394:	1800                	addi	s0,sp,48
    80002396:	89aa                	mv	s3,a0
    80002398:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	5e6080e7          	jalr	1510(ra) # 80001980 <myproc>
    800023a2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	81e080e7          	jalr	-2018(ra) # 80000bc2 <acquire>
  release(lk);
    800023ac:	854a                	mv	a0,s2
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	8c8080e7          	jalr	-1848(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800023b6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023ba:	4789                	li	a5,2
    800023bc:	cc9c                	sw	a5,24(s1)

  sched();
    800023be:	00000097          	auipc	ra,0x0
    800023c2:	d2c080e7          	jalr	-724(ra) # 800020ea <sched>

  // Tidy up.
  p->chan = 0;
    800023c6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8aa080e7          	jalr	-1878(ra) # 80000c76 <release>
  acquire(lk);
    800023d4:	854a                	mv	a0,s2
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	7ec080e7          	jalr	2028(ra) # 80000bc2 <acquire>
}
    800023de:	70a2                	ld	ra,40(sp)
    800023e0:	7402                	ld	s0,32(sp)
    800023e2:	64e2                	ld	s1,24(sp)
    800023e4:	6942                	ld	s2,16(sp)
    800023e6:	69a2                	ld	s3,8(sp)
    800023e8:	6145                	addi	sp,sp,48
    800023ea:	8082                	ret

00000000800023ec <wait>:
{
    800023ec:	715d                	addi	sp,sp,-80
    800023ee:	e486                	sd	ra,72(sp)
    800023f0:	e0a2                	sd	s0,64(sp)
    800023f2:	fc26                	sd	s1,56(sp)
    800023f4:	f84a                	sd	s2,48(sp)
    800023f6:	f44e                	sd	s3,40(sp)
    800023f8:	f052                	sd	s4,32(sp)
    800023fa:	ec56                	sd	s5,24(sp)
    800023fc:	e85a                	sd	s6,16(sp)
    800023fe:	e45e                	sd	s7,8(sp)
    80002400:	e062                	sd	s8,0(sp)
    80002402:	0880                	addi	s0,sp,80
    80002404:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	57a080e7          	jalr	1402(ra) # 80001980 <myproc>
    8000240e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002410:	0000f517          	auipc	a0,0xf
    80002414:	ea850513          	addi	a0,a0,-344 # 800112b8 <wait_lock>
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7aa080e7          	jalr	1962(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002420:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002422:	4a15                	li	s4,5
        havekids = 1;
    80002424:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002426:	0001b997          	auipc	s3,0x1b
    8000242a:	2aa98993          	addi	s3,s3,682 # 8001d6d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000242e:	0000fc17          	auipc	s8,0xf
    80002432:	e8ac0c13          	addi	s8,s8,-374 # 800112b8 <wait_lock>
    havekids = 0;
    80002436:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002438:	0000f497          	auipc	s1,0xf
    8000243c:	29848493          	addi	s1,s1,664 # 800116d0 <proc>
    80002440:	a0bd                	j	800024ae <wait+0xc2>
          pid = np->pid;
    80002442:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002446:	000b0e63          	beqz	s6,80002462 <wait+0x76>
    8000244a:	4691                	li	a3,4
    8000244c:	02c48613          	addi	a2,s1,44
    80002450:	85da                	mv	a1,s6
    80002452:	1e893503          	ld	a0,488(s2)
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	1e8080e7          	jalr	488(ra) # 8000163e <copyout>
    8000245e:	02054563          	bltz	a0,80002488 <wait+0x9c>
          freeproc(np);
    80002462:	8526                	mv	a0,s1
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	6ce080e7          	jalr	1742(ra) # 80001b32 <freeproc>
          release(&np->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	808080e7          	jalr	-2040(ra) # 80000c76 <release>
          release(&wait_lock);
    80002476:	0000f517          	auipc	a0,0xf
    8000247a:	e4250513          	addi	a0,a0,-446 # 800112b8 <wait_lock>
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	7f8080e7          	jalr	2040(ra) # 80000c76 <release>
          return pid;
    80002486:	a0a5                	j	800024ee <wait+0x102>
            release(&np->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	7ec080e7          	jalr	2028(ra) # 80000c76 <release>
            release(&wait_lock);
    80002492:	0000f517          	auipc	a0,0xf
    80002496:	e2650513          	addi	a0,a0,-474 # 800112b8 <wait_lock>
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	7dc080e7          	jalr	2012(ra) # 80000c76 <release>
            return -1;
    800024a2:	59fd                	li	s3,-1
    800024a4:	a0a9                	j	800024ee <wait+0x102>
    for(np = proc; np < &proc[NPROC]; np++){
    800024a6:	30048493          	addi	s1,s1,768
    800024aa:	03348563          	beq	s1,s3,800024d4 <wait+0xe8>
      if(np->parent == p){
    800024ae:	1d04b783          	ld	a5,464(s1)
    800024b2:	ff279ae3          	bne	a5,s2,800024a6 <wait+0xba>
        acquire(&np->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	70a080e7          	jalr	1802(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800024c0:	4c9c                	lw	a5,24(s1)
    800024c2:	f94780e3          	beq	a5,s4,80002442 <wait+0x56>
        release(&np->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7ae080e7          	jalr	1966(ra) # 80000c76 <release>
        havekids = 1;
    800024d0:	8756                	mv	a4,s5
    800024d2:	bfd1                	j	800024a6 <wait+0xba>
    if(!havekids || p->killed){
    800024d4:	c701                	beqz	a4,800024dc <wait+0xf0>
    800024d6:	02892783          	lw	a5,40(s2)
    800024da:	c79d                	beqz	a5,80002508 <wait+0x11c>
      release(&wait_lock);
    800024dc:	0000f517          	auipc	a0,0xf
    800024e0:	ddc50513          	addi	a0,a0,-548 # 800112b8 <wait_lock>
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	792080e7          	jalr	1938(ra) # 80000c76 <release>
      return -1;
    800024ec:	59fd                	li	s3,-1
}
    800024ee:	854e                	mv	a0,s3
    800024f0:	60a6                	ld	ra,72(sp)
    800024f2:	6406                	ld	s0,64(sp)
    800024f4:	74e2                	ld	s1,56(sp)
    800024f6:	7942                	ld	s2,48(sp)
    800024f8:	79a2                	ld	s3,40(sp)
    800024fa:	7a02                	ld	s4,32(sp)
    800024fc:	6ae2                	ld	s5,24(sp)
    800024fe:	6b42                	ld	s6,16(sp)
    80002500:	6ba2                	ld	s7,8(sp)
    80002502:	6c02                	ld	s8,0(sp)
    80002504:	6161                	addi	sp,sp,80
    80002506:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002508:	85e2                	mv	a1,s8
    8000250a:	854a                	mv	a0,s2
    8000250c:	00000097          	auipc	ra,0x0
    80002510:	e7c080e7          	jalr	-388(ra) # 80002388 <sleep>
    havekids = 0;
    80002514:	b70d                	j	80002436 <wait+0x4a>

0000000080002516 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002516:	7139                	addi	sp,sp,-64
    80002518:	fc06                	sd	ra,56(sp)
    8000251a:	f822                	sd	s0,48(sp)
    8000251c:	f426                	sd	s1,40(sp)
    8000251e:	f04a                	sd	s2,32(sp)
    80002520:	ec4e                	sd	s3,24(sp)
    80002522:	e852                	sd	s4,16(sp)
    80002524:	e456                	sd	s5,8(sp)
    80002526:	0080                	addi	s0,sp,64
    80002528:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000252a:	0000f497          	auipc	s1,0xf
    8000252e:	1a648493          	addi	s1,s1,422 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002532:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002534:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002536:	0001b917          	auipc	s2,0x1b
    8000253a:	19a90913          	addi	s2,s2,410 # 8001d6d0 <tickslock>
    8000253e:	a811                	j	80002552 <wakeup+0x3c>
      }
      release(&p->lock);
    80002540:	8526                	mv	a0,s1
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	734080e7          	jalr	1844(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000254a:	30048493          	addi	s1,s1,768
    8000254e:	03248663          	beq	s1,s2,8000257a <wakeup+0x64>
    if(p != myproc()){
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	42e080e7          	jalr	1070(ra) # 80001980 <myproc>
    8000255a:	fea488e3          	beq	s1,a0,8000254a <wakeup+0x34>
      acquire(&p->lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	662080e7          	jalr	1634(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002568:	4c9c                	lw	a5,24(s1)
    8000256a:	fd379be3          	bne	a5,s3,80002540 <wakeup+0x2a>
    8000256e:	709c                	ld	a5,32(s1)
    80002570:	fd4798e3          	bne	a5,s4,80002540 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002574:	0154ac23          	sw	s5,24(s1)
    80002578:	b7e1                	j	80002540 <wakeup+0x2a>
    }
  }
}
    8000257a:	70e2                	ld	ra,56(sp)
    8000257c:	7442                	ld	s0,48(sp)
    8000257e:	74a2                	ld	s1,40(sp)
    80002580:	7902                	ld	s2,32(sp)
    80002582:	69e2                	ld	s3,24(sp)
    80002584:	6a42                	ld	s4,16(sp)
    80002586:	6aa2                	ld	s5,8(sp)
    80002588:	6121                	addi	sp,sp,64
    8000258a:	8082                	ret

000000008000258c <reparent>:
{
    8000258c:	7179                	addi	sp,sp,-48
    8000258e:	f406                	sd	ra,40(sp)
    80002590:	f022                	sd	s0,32(sp)
    80002592:	ec26                	sd	s1,24(sp)
    80002594:	e84a                	sd	s2,16(sp)
    80002596:	e44e                	sd	s3,8(sp)
    80002598:	e052                	sd	s4,0(sp)
    8000259a:	1800                	addi	s0,sp,48
    8000259c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000259e:	0000f497          	auipc	s1,0xf
    800025a2:	13248493          	addi	s1,s1,306 # 800116d0 <proc>
      pp->parent = initproc;
    800025a6:	00007a17          	auipc	s4,0x7
    800025aa:	a82a0a13          	addi	s4,s4,-1406 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025ae:	0001b997          	auipc	s3,0x1b
    800025b2:	12298993          	addi	s3,s3,290 # 8001d6d0 <tickslock>
    800025b6:	a029                	j	800025c0 <reparent+0x34>
    800025b8:	30048493          	addi	s1,s1,768
    800025bc:	01348f63          	beq	s1,s3,800025da <reparent+0x4e>
    if(pp->parent == p){
    800025c0:	1d04b783          	ld	a5,464(s1)
    800025c4:	ff279ae3          	bne	a5,s2,800025b8 <reparent+0x2c>
      pp->parent = initproc;
    800025c8:	000a3503          	ld	a0,0(s4)
    800025cc:	1ca4b823          	sd	a0,464(s1)
      wakeup(initproc);
    800025d0:	00000097          	auipc	ra,0x0
    800025d4:	f46080e7          	jalr	-186(ra) # 80002516 <wakeup>
    800025d8:	b7c5                	j	800025b8 <reparent+0x2c>
}
    800025da:	70a2                	ld	ra,40(sp)
    800025dc:	7402                	ld	s0,32(sp)
    800025de:	64e2                	ld	s1,24(sp)
    800025e0:	6942                	ld	s2,16(sp)
    800025e2:	69a2                	ld	s3,8(sp)
    800025e4:	6a02                	ld	s4,0(sp)
    800025e6:	6145                	addi	sp,sp,48
    800025e8:	8082                	ret

00000000800025ea <exit>:
{
    800025ea:	7179                	addi	sp,sp,-48
    800025ec:	f406                	sd	ra,40(sp)
    800025ee:	f022                	sd	s0,32(sp)
    800025f0:	ec26                	sd	s1,24(sp)
    800025f2:	e84a                	sd	s2,16(sp)
    800025f4:	e44e                	sd	s3,8(sp)
    800025f6:	e052                	sd	s4,0(sp)
    800025f8:	1800                	addi	s0,sp,48
    800025fa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	384080e7          	jalr	900(ra) # 80001980 <myproc>
    80002604:	89aa                	mv	s3,a0
  if(p == initproc)
    80002606:	00007797          	auipc	a5,0x7
    8000260a:	a227b783          	ld	a5,-1502(a5) # 80009028 <initproc>
    8000260e:	26850493          	addi	s1,a0,616
    80002612:	2e850913          	addi	s2,a0,744
    80002616:	02a79363          	bne	a5,a0,8000263c <exit+0x52>
    panic("init exiting");
    8000261a:	00006517          	auipc	a0,0x6
    8000261e:	c2e50513          	addi	a0,a0,-978 # 80008248 <digits+0x208>
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	f08080e7          	jalr	-248(ra) # 8000052a <panic>
      fileclose(f);
    8000262a:	00002097          	auipc	ra,0x2
    8000262e:	476080e7          	jalr	1142(ra) # 80004aa0 <fileclose>
      p->ofile[fd] = 0;
    80002632:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002636:	04a1                	addi	s1,s1,8
    80002638:	01248563          	beq	s1,s2,80002642 <exit+0x58>
    if(p->ofile[fd]){
    8000263c:	6088                	ld	a0,0(s1)
    8000263e:	f575                	bnez	a0,8000262a <exit+0x40>
    80002640:	bfdd                	j	80002636 <exit+0x4c>
  begin_op();
    80002642:	00002097          	auipc	ra,0x2
    80002646:	f92080e7          	jalr	-110(ra) # 800045d4 <begin_op>
  iput(p->cwd);
    8000264a:	2e89b503          	ld	a0,744(s3)
    8000264e:	00001097          	auipc	ra,0x1
    80002652:	76a080e7          	jalr	1898(ra) # 80003db8 <iput>
  end_op();
    80002656:	00002097          	auipc	ra,0x2
    8000265a:	ffe080e7          	jalr	-2(ra) # 80004654 <end_op>
  p->cwd = 0;
    8000265e:	2e09b423          	sd	zero,744(s3)
  acquire(&wait_lock);
    80002662:	0000f497          	auipc	s1,0xf
    80002666:	c5648493          	addi	s1,s1,-938 # 800112b8 <wait_lock>
    8000266a:	8526                	mv	a0,s1
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	556080e7          	jalr	1366(ra) # 80000bc2 <acquire>
  reparent(p);
    80002674:	854e                	mv	a0,s3
    80002676:	00000097          	auipc	ra,0x0
    8000267a:	f16080e7          	jalr	-234(ra) # 8000258c <reparent>
  wakeup(p->parent);
    8000267e:	1d09b503          	ld	a0,464(s3)
    80002682:	00000097          	auipc	ra,0x0
    80002686:	e94080e7          	jalr	-364(ra) # 80002516 <wakeup>
  acquire(&p->lock);
    8000268a:	854e                	mv	a0,s3
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	536080e7          	jalr	1334(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002694:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002698:	4795                	li	a5,5
    8000269a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000269e:	8526                	mv	a0,s1
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	5d6080e7          	jalr	1494(ra) # 80000c76 <release>
  sched();
    800026a8:	00000097          	auipc	ra,0x0
    800026ac:	a42080e7          	jalr	-1470(ra) # 800020ea <sched>
  panic("zombie exit");
    800026b0:	00006517          	auipc	a0,0x6
    800026b4:	ba850513          	addi	a0,a0,-1112 # 80008258 <digits+0x218>
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	e72080e7          	jalr	-398(ra) # 8000052a <panic>

00000000800026c0 <kill>:
// ADDED Q2.2.1
int
kill(int pid, int signum)
{
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    800026c0:	47fd                	li	a5,31
    800026c2:	06b7eb63          	bltu	a5,a1,80002738 <kill+0x78>
{
    800026c6:	7179                	addi	sp,sp,-48
    800026c8:	f406                	sd	ra,40(sp)
    800026ca:	f022                	sd	s0,32(sp)
    800026cc:	ec26                	sd	s1,24(sp)
    800026ce:	e84a                	sd	s2,16(sp)
    800026d0:	e44e                	sd	s3,8(sp)
    800026d2:	e052                	sd	s4,0(sp)
    800026d4:	1800                	addi	s0,sp,48
    800026d6:	892a                	mv	s2,a0
    800026d8:	8a2e                	mv	s4,a1
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    800026da:	0000f497          	auipc	s1,0xf
    800026de:	ff648493          	addi	s1,s1,-10 # 800116d0 <proc>
    800026e2:	0001b997          	auipc	s3,0x1b
    800026e6:	fee98993          	addi	s3,s3,-18 # 8001d6d0 <tickslock>
    acquire(&p->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	4d6080e7          	jalr	1238(ra) # 80000bc2 <acquire>
    if(p->pid == pid) {
    800026f4:	589c                	lw	a5,48(s1)
    800026f6:	01278d63          	beq	a5,s2,80002710 <kill+0x50>
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026fa:	8526                	mv	a0,s1
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	57a080e7          	jalr	1402(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002704:	30048493          	addi	s1,s1,768
    80002708:	ff3491e3          	bne	s1,s3,800026ea <kill+0x2a>
  }
  // no such pid
  return -1;
    8000270c:	557d                	li	a0,-1
    8000270e:	a829                	j	80002728 <kill+0x68>
      p->pending_signals = p->pending_signals | (1 << signum);
    80002710:	4785                	li	a5,1
    80002712:	0147973b          	sllw	a4,a5,s4
    80002716:	58dc                	lw	a5,52(s1)
    80002718:	8fd9                	or	a5,a5,a4
    8000271a:	d8dc                	sw	a5,52(s1)
      release(&p->lock);
    8000271c:	8526                	mv	a0,s1
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	558080e7          	jalr	1368(ra) # 80000c76 <release>
      return 0;
    80002726:	4501                	li	a0,0
}
    80002728:	70a2                	ld	ra,40(sp)
    8000272a:	7402                	ld	s0,32(sp)
    8000272c:	64e2                	ld	s1,24(sp)
    8000272e:	6942                	ld	s2,16(sp)
    80002730:	69a2                	ld	s3,8(sp)
    80002732:	6a02                	ld	s4,0(sp)
    80002734:	6145                	addi	sp,sp,48
    80002736:	8082                	ret
    return -1;
    80002738:	557d                	li	a0,-1
}
    8000273a:	8082                	ret

000000008000273c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000273c:	7179                	addi	sp,sp,-48
    8000273e:	f406                	sd	ra,40(sp)
    80002740:	f022                	sd	s0,32(sp)
    80002742:	ec26                	sd	s1,24(sp)
    80002744:	e84a                	sd	s2,16(sp)
    80002746:	e44e                	sd	s3,8(sp)
    80002748:	e052                	sd	s4,0(sp)
    8000274a:	1800                	addi	s0,sp,48
    8000274c:	84aa                	mv	s1,a0
    8000274e:	892e                	mv	s2,a1
    80002750:	89b2                	mv	s3,a2
    80002752:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	22c080e7          	jalr	556(ra) # 80001980 <myproc>
  if(user_dst){
    8000275c:	c095                	beqz	s1,80002780 <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    8000275e:	86d2                	mv	a3,s4
    80002760:	864e                	mv	a2,s3
    80002762:	85ca                	mv	a1,s2
    80002764:	1e853503          	ld	a0,488(a0)
    80002768:	fffff097          	auipc	ra,0xfffff
    8000276c:	ed6080e7          	jalr	-298(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002770:	70a2                	ld	ra,40(sp)
    80002772:	7402                	ld	s0,32(sp)
    80002774:	64e2                	ld	s1,24(sp)
    80002776:	6942                	ld	s2,16(sp)
    80002778:	69a2                	ld	s3,8(sp)
    8000277a:	6a02                	ld	s4,0(sp)
    8000277c:	6145                	addi	sp,sp,48
    8000277e:	8082                	ret
    memmove((char *)dst, src, len);
    80002780:	000a061b          	sext.w	a2,s4
    80002784:	85ce                	mv	a1,s3
    80002786:	854a                	mv	a0,s2
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	592080e7          	jalr	1426(ra) # 80000d1a <memmove>
    return 0;
    80002790:	8526                	mv	a0,s1
    80002792:	bff9                	j	80002770 <either_copyout+0x34>

0000000080002794 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002794:	7179                	addi	sp,sp,-48
    80002796:	f406                	sd	ra,40(sp)
    80002798:	f022                	sd	s0,32(sp)
    8000279a:	ec26                	sd	s1,24(sp)
    8000279c:	e84a                	sd	s2,16(sp)
    8000279e:	e44e                	sd	s3,8(sp)
    800027a0:	e052                	sd	s4,0(sp)
    800027a2:	1800                	addi	s0,sp,48
    800027a4:	892a                	mv	s2,a0
    800027a6:	84ae                	mv	s1,a1
    800027a8:	89b2                	mv	s3,a2
    800027aa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	1d4080e7          	jalr	468(ra) # 80001980 <myproc>
  if(user_src){
    800027b4:	c095                	beqz	s1,800027d8 <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    800027b6:	86d2                	mv	a3,s4
    800027b8:	864e                	mv	a2,s3
    800027ba:	85ca                	mv	a1,s2
    800027bc:	1e853503          	ld	a0,488(a0)
    800027c0:	fffff097          	auipc	ra,0xfffff
    800027c4:	f0a080e7          	jalr	-246(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027c8:	70a2                	ld	ra,40(sp)
    800027ca:	7402                	ld	s0,32(sp)
    800027cc:	64e2                	ld	s1,24(sp)
    800027ce:	6942                	ld	s2,16(sp)
    800027d0:	69a2                	ld	s3,8(sp)
    800027d2:	6a02                	ld	s4,0(sp)
    800027d4:	6145                	addi	sp,sp,48
    800027d6:	8082                	ret
    memmove(dst, (char*)src, len);
    800027d8:	000a061b          	sext.w	a2,s4
    800027dc:	85ce                	mv	a1,s3
    800027de:	854a                	mv	a0,s2
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	53a080e7          	jalr	1338(ra) # 80000d1a <memmove>
    return 0;
    800027e8:	8526                	mv	a0,s1
    800027ea:	bff9                	j	800027c8 <either_copyin+0x34>

00000000800027ec <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027ec:	715d                	addi	sp,sp,-80
    800027ee:	e486                	sd	ra,72(sp)
    800027f0:	e0a2                	sd	s0,64(sp)
    800027f2:	fc26                	sd	s1,56(sp)
    800027f4:	f84a                	sd	s2,48(sp)
    800027f6:	f44e                	sd	s3,40(sp)
    800027f8:	f052                	sd	s4,32(sp)
    800027fa:	ec56                	sd	s5,24(sp)
    800027fc:	e85a                	sd	s6,16(sp)
    800027fe:	e45e                	sd	s7,8(sp)
    80002800:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002802:	00006517          	auipc	a0,0x6
    80002806:	8c650513          	addi	a0,a0,-1850 # 800080c8 <digits+0x88>
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	d6a080e7          	jalr	-662(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002812:	0000f497          	auipc	s1,0xf
    80002816:	1ae48493          	addi	s1,s1,430 # 800119c0 <proc+0x2f0>
    8000281a:	0001b917          	auipc	s2,0x1b
    8000281e:	1a690913          	addi	s2,s2,422 # 8001d9c0 <bcache+0x2d8>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002822:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002824:	00006997          	auipc	s3,0x6
    80002828:	a4498993          	addi	s3,s3,-1468 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000282c:	00006a97          	auipc	s5,0x6
    80002830:	a44a8a93          	addi	s5,s5,-1468 # 80008270 <digits+0x230>
    printf("\n");
    80002834:	00006a17          	auipc	s4,0x6
    80002838:	894a0a13          	addi	s4,s4,-1900 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000283c:	00006b97          	auipc	s7,0x6
    80002840:	a6cb8b93          	addi	s7,s7,-1428 # 800082a8 <states.0>
    80002844:	a00d                	j	80002866 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002846:	d406a583          	lw	a1,-704(a3)
    8000284a:	8556                	mv	a0,s5
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	d28080e7          	jalr	-728(ra) # 80000574 <printf>
    printf("\n");
    80002854:	8552                	mv	a0,s4
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	d1e080e7          	jalr	-738(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000285e:	30048493          	addi	s1,s1,768
    80002862:	03248263          	beq	s1,s2,80002886 <procdump+0x9a>
    if(p->state == UNUSED)
    80002866:	86a6                	mv	a3,s1
    80002868:	d284a783          	lw	a5,-728(s1)
    8000286c:	dbed                	beqz	a5,8000285e <procdump+0x72>
      state = "???";
    8000286e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002870:	fcfb6be3          	bltu	s6,a5,80002846 <procdump+0x5a>
    80002874:	02079713          	slli	a4,a5,0x20
    80002878:	01d75793          	srli	a5,a4,0x1d
    8000287c:	97de                	add	a5,a5,s7
    8000287e:	6390                	ld	a2,0(a5)
    80002880:	f279                	bnez	a2,80002846 <procdump+0x5a>
      state = "???";
    80002882:	864e                	mv	a2,s3
    80002884:	b7c9                	j	80002846 <procdump+0x5a>
  }
}
    80002886:	60a6                	ld	ra,72(sp)
    80002888:	6406                	ld	s0,64(sp)
    8000288a:	74e2                	ld	s1,56(sp)
    8000288c:	7942                	ld	s2,48(sp)
    8000288e:	79a2                	ld	s3,40(sp)
    80002890:	7a02                	ld	s4,32(sp)
    80002892:	6ae2                	ld	s5,24(sp)
    80002894:	6b42                	ld	s6,16(sp)
    80002896:	6ba2                	ld	s7,8(sp)
    80002898:	6161                	addi	sp,sp,80
    8000289a:	8082                	ret

000000008000289c <sigprocmask>:

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
    8000289c:	7179                	addi	sp,sp,-48
    8000289e:	f406                	sd	ra,40(sp)
    800028a0:	f022                	sd	s0,32(sp)
    800028a2:	ec26                	sd	s1,24(sp)
    800028a4:	e84a                	sd	s2,16(sp)
    800028a6:	e44e                	sd	s3,8(sp)
    800028a8:	1800                	addi	s0,sp,48
    800028aa:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	0d4080e7          	jalr	212(ra) # 80001980 <myproc>
    800028b4:	84aa                	mv	s1,a0
  uint old_mask = p->signal_mask;
    800028b6:	03852983          	lw	s3,56(a0)
  acquire(&p->lock);
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	308080e7          	jalr	776(ra) # 80000bc2 <acquire>

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    800028c2:	000207b7          	lui	a5,0x20
    800028c6:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    800028ca:	00f977b3          	and	a5,s2,a5
    800028ce:	e385                	bnez	a5,800028ee <sigprocmask+0x52>
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
    800028d0:	0324ac23          	sw	s2,56(s1)
  release(&p->lock);
    800028d4:	8526                	mv	a0,s1
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	3a0080e7          	jalr	928(ra) # 80000c76 <release>
  return old_mask;
}
    800028de:	854e                	mv	a0,s3
    800028e0:	70a2                	ld	ra,40(sp)
    800028e2:	7402                	ld	s0,32(sp)
    800028e4:	64e2                	ld	s1,24(sp)
    800028e6:	6942                	ld	s2,16(sp)
    800028e8:	69a2                	ld	s3,8(sp)
    800028ea:	6145                	addi	sp,sp,48
    800028ec:	8082                	ret
    release(&p->lock);
    800028ee:	8526                	mv	a0,s1
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	386080e7          	jalr	902(ra) # 80000c76 <release>
    return -1;
    800028f8:	59fd                	li	s3,-1
    800028fa:	b7d5                	j	800028de <sigprocmask+0x42>

00000000800028fc <sigaction>:
// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    800028fc:	0005079b          	sext.w	a5,a0
    80002900:	477d                	li	a4,31
    80002902:	0ef76163          	bltu	a4,a5,800029e4 <sigaction+0xe8>
{
    80002906:	711d                	addi	sp,sp,-96
    80002908:	ec86                	sd	ra,88(sp)
    8000290a:	e8a2                	sd	s0,80(sp)
    8000290c:	e4a6                	sd	s1,72(sp)
    8000290e:	e0ca                	sd	s2,64(sp)
    80002910:	fc4e                	sd	s3,56(sp)
    80002912:	f852                	sd	s4,48(sp)
    80002914:	f456                	sd	s5,40(sp)
    80002916:	1080                	addi	s0,sp,96
    80002918:	84aa                	mv	s1,a0
    8000291a:	89ae                	mv	s3,a1
    8000291c:	8a32                	mv	s4,a2
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    8000291e:	37dd                	addiw	a5,a5,-9
    80002920:	9bdd                	andi	a5,a5,-9
    80002922:	2781                	sext.w	a5,a5
    80002924:	c3f1                	beqz	a5,800029e8 <sigaction+0xec>
    return -1;
  }

  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((act->sigmask & (1 << SIGKILL)) != 0) || ((act->sigmask & (1 << SIGSTOP)) != 0)) ) {
    80002926:	c5e9                	beqz	a1,800029f0 <sigaction+0xf4>
    80002928:	659c                	ld	a5,8(a1)
    8000292a:	00020737          	lui	a4,0x20
    8000292e:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    80002932:	8ff9                	and	a5,a5,a4
    80002934:	efc5                	bnez	a5,800029ec <sigaction+0xf0>
    return -1;
  }

  struct proc *p = myproc();
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	04a080e7          	jalr	74(ra) # 80001980 <myproc>
    8000293e:	892a                	mv	s2,a0
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;
  acquire(&p->lock);
    80002940:	8aaa                	mv	s5,a0
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	280080e7          	jalr	640(ra) # 80000bc2 <acquire>

  if (oldact) {
    8000294a:	020a0c63          	beqz	s4,80002982 <sigaction+0x86>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    8000294e:	00848793          	addi	a5,s1,8
    80002952:	078e                	slli	a5,a5,0x3
    80002954:	97ca                	add	a5,a5,s2
    80002956:	639c                	ld	a5,0(a5)
    80002958:	faf43023          	sd	a5,-96(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    8000295c:	05048793          	addi	a5,s1,80
    80002960:	078a                	slli	a5,a5,0x2
    80002962:	97ca                	add	a5,a5,s2
    80002964:	439c                	lw	a5,0(a5)
    80002966:	faf42423          	sw	a5,-88(s0)

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    8000296a:	46c1                	li	a3,16
    8000296c:	fa040613          	addi	a2,s0,-96
    80002970:	85d2                	mv	a1,s4
    80002972:	1e893503          	ld	a0,488(s2)
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	cc8080e7          	jalr	-824(ra) # 8000163e <copyout>
    8000297e:	0a054f63          	bltz	a0,80002a3c <sigaction+0x140>
      return -1;
    }
  }

  if (act) {
    if(copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    80002982:	46c1                	li	a3,16
    80002984:	864e                	mv	a2,s3
    80002986:	fb040593          	addi	a1,s0,-80
    8000298a:	1e893503          	ld	a0,488(s2)
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	d3c080e7          	jalr	-708(ra) # 800016ca <copyin>
    80002996:	04054063          	bltz	a0,800029d6 <sigaction+0xda>
      release(&p->lock);
      return -1;
    }
    p->signal_handlers[signum] = kernel_act.sa_handler;
    8000299a:	00848793          	addi	a5,s1,8
    8000299e:	078e                	slli	a5,a5,0x3
    800029a0:	97ca                	add	a5,a5,s2
    800029a2:	fb043703          	ld	a4,-80(s0)
    800029a6:	e398                	sd	a4,0(a5)
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
    800029a8:	05048493          	addi	s1,s1,80
    800029ac:	048a                	slli	s1,s1,0x2
    800029ae:	9926                	add	s2,s2,s1
    800029b0:	fb842783          	lw	a5,-72(s0)
    800029b4:	00f92023          	sw	a5,0(s2)
  }
  release(&p->lock);
    800029b8:	8556                	mv	a0,s5
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	2bc080e7          	jalr	700(ra) # 80000c76 <release>
  return 0;
    800029c2:	4501                	li	a0,0
}
    800029c4:	60e6                	ld	ra,88(sp)
    800029c6:	6446                	ld	s0,80(sp)
    800029c8:	64a6                	ld	s1,72(sp)
    800029ca:	6906                	ld	s2,64(sp)
    800029cc:	79e2                	ld	s3,56(sp)
    800029ce:	7a42                	ld	s4,48(sp)
    800029d0:	7aa2                	ld	s5,40(sp)
    800029d2:	6125                	addi	sp,sp,96
    800029d4:	8082                	ret
      release(&p->lock);
    800029d6:	854a                	mv	a0,s2
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	29e080e7          	jalr	670(ra) # 80000c76 <release>
      return -1;
    800029e0:	557d                	li	a0,-1
    800029e2:	b7cd                	j	800029c4 <sigaction+0xc8>
    return -1;
    800029e4:	557d                	li	a0,-1
}
    800029e6:	8082                	ret
    return -1;
    800029e8:	557d                	li	a0,-1
    800029ea:	bfe9                	j	800029c4 <sigaction+0xc8>
    return -1;
    800029ec:	557d                	li	a0,-1
    800029ee:	bfd9                	j	800029c4 <sigaction+0xc8>
  struct proc *p = myproc();
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	f90080e7          	jalr	-112(ra) # 80001980 <myproc>
    800029f8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800029fa:	8aaa                	mv	s5,a0
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	1c6080e7          	jalr	454(ra) # 80000bc2 <acquire>
  if (oldact) {
    80002a04:	fa0a0ae3          	beqz	s4,800029b8 <sigaction+0xbc>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002a08:	00848793          	addi	a5,s1,8
    80002a0c:	078e                	slli	a5,a5,0x3
    80002a0e:	97ca                	add	a5,a5,s2
    80002a10:	639c                	ld	a5,0(a5)
    80002a12:	faf43023          	sd	a5,-96(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002a16:	05048493          	addi	s1,s1,80
    80002a1a:	048a                	slli	s1,s1,0x2
    80002a1c:	94ca                	add	s1,s1,s2
    80002a1e:	409c                	lw	a5,0(s1)
    80002a20:	faf42423          	sw	a5,-88(s0)
    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002a24:	46c1                	li	a3,16
    80002a26:	fa040613          	addi	a2,s0,-96
    80002a2a:	85d2                	mv	a1,s4
    80002a2c:	1e893503          	ld	a0,488(s2)
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	c0e080e7          	jalr	-1010(ra) # 8000163e <copyout>
    80002a38:	f80550e3          	bgez	a0,800029b8 <sigaction+0xbc>
      release(&p->lock);
    80002a3c:	8556                	mv	a0,s5
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	238080e7          	jalr	568(ra) # 80000c76 <release>
      return -1;
    80002a46:	557d                	li	a0,-1
    80002a48:	bfb5                	j	800029c4 <sigaction+0xc8>

0000000080002a4a <sigret>:

// ADDED Q2.1.5
void
sigret(void)
{
    80002a4a:	1101                	addi	sp,sp,-32
    80002a4c:	ec06                	sd	ra,24(sp)
    80002a4e:	e822                	sd	s0,16(sp)
    80002a50:	e426                	sd	s1,8(sp)
    80002a52:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	f2c080e7          	jalr	-212(ra) # 80001980 <myproc>
    80002a5c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	164080e7          	jalr	356(ra) # 80000bc2 <acquire>
  memmove(p->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    80002a66:	12000613          	li	a2,288
    80002a6a:	1c04b583          	ld	a1,448(s1)
    80002a6e:	1f04b503          	ld	a0,496(s1)
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	2a8080e7          	jalr	680(ra) # 80000d1a <memmove>
  p->signal_mask = p->signal_mask_backup;
    80002a7a:	5cdc                	lw	a5,60(s1)
    80002a7c:	dc9c                	sw	a5,56(s1)
  p->handling_user_level_signal = 0;
    80002a7e:	1c04a623          	sw	zero,460(s1)
  release(&p->lock);
    80002a82:	8526                	mv	a0,s1
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	1f2080e7          	jalr	498(ra) # 80000c76 <release>
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6105                	addi	sp,sp,32
    80002a94:	8082                	ret

0000000080002a96 <swtch>:
    80002a96:	00153023          	sd	ra,0(a0)
    80002a9a:	00253423          	sd	sp,8(a0)
    80002a9e:	e900                	sd	s0,16(a0)
    80002aa0:	ed04                	sd	s1,24(a0)
    80002aa2:	03253023          	sd	s2,32(a0)
    80002aa6:	03353423          	sd	s3,40(a0)
    80002aaa:	03453823          	sd	s4,48(a0)
    80002aae:	03553c23          	sd	s5,56(a0)
    80002ab2:	05653023          	sd	s6,64(a0)
    80002ab6:	05753423          	sd	s7,72(a0)
    80002aba:	05853823          	sd	s8,80(a0)
    80002abe:	05953c23          	sd	s9,88(a0)
    80002ac2:	07a53023          	sd	s10,96(a0)
    80002ac6:	07b53423          	sd	s11,104(a0)
    80002aca:	0005b083          	ld	ra,0(a1)
    80002ace:	0085b103          	ld	sp,8(a1)
    80002ad2:	6980                	ld	s0,16(a1)
    80002ad4:	6d84                	ld	s1,24(a1)
    80002ad6:	0205b903          	ld	s2,32(a1)
    80002ada:	0285b983          	ld	s3,40(a1)
    80002ade:	0305ba03          	ld	s4,48(a1)
    80002ae2:	0385ba83          	ld	s5,56(a1)
    80002ae6:	0405bb03          	ld	s6,64(a1)
    80002aea:	0485bb83          	ld	s7,72(a1)
    80002aee:	0505bc03          	ld	s8,80(a1)
    80002af2:	0585bc83          	ld	s9,88(a1)
    80002af6:	0605bd03          	ld	s10,96(a1)
    80002afa:	0685bd83          	ld	s11,104(a1)
    80002afe:	8082                	ret

0000000080002b00 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b00:	1141                	addi	sp,sp,-16
    80002b02:	e406                	sd	ra,8(sp)
    80002b04:	e022                	sd	s0,0(sp)
    80002b06:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b08:	00005597          	auipc	a1,0x5
    80002b0c:	7d058593          	addi	a1,a1,2000 # 800082d8 <states.0+0x30>
    80002b10:	0001b517          	auipc	a0,0x1b
    80002b14:	bc050513          	addi	a0,a0,-1088 # 8001d6d0 <tickslock>
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	01a080e7          	jalr	26(ra) # 80000b32 <initlock>
}
    80002b20:	60a2                	ld	ra,8(sp)
    80002b22:	6402                	ld	s0,0(sp)
    80002b24:	0141                	addi	sp,sp,16
    80002b26:	8082                	ret

0000000080002b28 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b28:	1141                	addi	sp,sp,-16
    80002b2a:	e422                	sd	s0,8(sp)
    80002b2c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b2e:	00003797          	auipc	a5,0x3
    80002b32:	5d278793          	addi	a5,a5,1490 # 80006100 <kernelvec>
    80002b36:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b3a:	6422                	ld	s0,8(sp)
    80002b3c:	0141                	addi	sp,sp,16
    80002b3e:	8082                	ret

0000000080002b40 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b40:	1101                	addi	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	e36080e7          	jalr	-458(ra) # 80001980 <myproc>
    80002b52:	84aa                	mv	s1,a0

  handle_signals(); // ADDED Q2.4
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	6fc080e7          	jalr	1788(ra) # 80002250 <handle_signals>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b5c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b60:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b62:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b66:	00004617          	auipc	a2,0x4
    80002b6a:	49a60613          	addi	a2,a2,1178 # 80007000 <_trampoline>
    80002b6e:	00004697          	auipc	a3,0x4
    80002b72:	49268693          	addi	a3,a3,1170 # 80007000 <_trampoline>
    80002b76:	8e91                	sub	a3,a3,a2
    80002b78:	040007b7          	lui	a5,0x4000
    80002b7c:	17fd                	addi	a5,a5,-1
    80002b7e:	07b2                	slli	a5,a5,0xc
    80002b80:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b82:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b86:	1f04b703          	ld	a4,496(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b8a:	180026f3          	csrr	a3,satp
    80002b8e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b90:	1f04b703          	ld	a4,496(s1)
    80002b94:	1d84b683          	ld	a3,472(s1)
    80002b98:	6585                	lui	a1,0x1
    80002b9a:	96ae                	add	a3,a3,a1
    80002b9c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b9e:	1f04b703          	ld	a4,496(s1)
    80002ba2:	00000697          	auipc	a3,0x0
    80002ba6:	14068693          	addi	a3,a3,320 # 80002ce2 <usertrap>
    80002baa:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bac:	1f04b703          	ld	a4,496(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bb0:	8692                	mv	a3,tp
    80002bb2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bb8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bbc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bc4:	1f04b703          	ld	a4,496(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bc8:	6f18                	ld	a4,24(a4)
    80002bca:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bce:	1e84b583          	ld	a1,488(s1)
    80002bd2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002bd4:	00004717          	auipc	a4,0x4
    80002bd8:	4bc70713          	addi	a4,a4,1212 # 80007090 <userret>
    80002bdc:	8f11                	sub	a4,a4,a2
    80002bde:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002be0:	577d                	li	a4,-1
    80002be2:	177e                	slli	a4,a4,0x3f
    80002be4:	8dd9                	or	a1,a1,a4
    80002be6:	02000537          	lui	a0,0x2000
    80002bea:	157d                	addi	a0,a0,-1
    80002bec:	0536                	slli	a0,a0,0xd
    80002bee:	9782                	jalr	a5
}
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	64a2                	ld	s1,8(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret

0000000080002bfa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c04:	0001b497          	auipc	s1,0x1b
    80002c08:	acc48493          	addi	s1,s1,-1332 # 8001d6d0 <tickslock>
    80002c0c:	8526                	mv	a0,s1
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	fb4080e7          	jalr	-76(ra) # 80000bc2 <acquire>
  ticks++;
    80002c16:	00006517          	auipc	a0,0x6
    80002c1a:	41a50513          	addi	a0,a0,1050 # 80009030 <ticks>
    80002c1e:	411c                	lw	a5,0(a0)
    80002c20:	2785                	addiw	a5,a5,1
    80002c22:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	8f2080e7          	jalr	-1806(ra) # 80002516 <wakeup>
  release(&tickslock);
    80002c2c:	8526                	mv	a0,s1
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	048080e7          	jalr	72(ra) # 80000c76 <release>
}
    80002c36:	60e2                	ld	ra,24(sp)
    80002c38:	6442                	ld	s0,16(sp)
    80002c3a:	64a2                	ld	s1,8(sp)
    80002c3c:	6105                	addi	sp,sp,32
    80002c3e:	8082                	ret

0000000080002c40 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c40:	1101                	addi	sp,sp,-32
    80002c42:	ec06                	sd	ra,24(sp)
    80002c44:	e822                	sd	s0,16(sp)
    80002c46:	e426                	sd	s1,8(sp)
    80002c48:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c4a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c4e:	00074d63          	bltz	a4,80002c68 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c52:	57fd                	li	a5,-1
    80002c54:	17fe                	slli	a5,a5,0x3f
    80002c56:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c58:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c5a:	06f70363          	beq	a4,a5,80002cc0 <devintr+0x80>
  }
}
    80002c5e:	60e2                	ld	ra,24(sp)
    80002c60:	6442                	ld	s0,16(sp)
    80002c62:	64a2                	ld	s1,8(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret
     (scause & 0xff) == 9){
    80002c68:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c6c:	46a5                	li	a3,9
    80002c6e:	fed792e3          	bne	a5,a3,80002c52 <devintr+0x12>
    int irq = plic_claim();
    80002c72:	00003097          	auipc	ra,0x3
    80002c76:	596080e7          	jalr	1430(ra) # 80006208 <plic_claim>
    80002c7a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c7c:	47a9                	li	a5,10
    80002c7e:	02f50763          	beq	a0,a5,80002cac <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c82:	4785                	li	a5,1
    80002c84:	02f50963          	beq	a0,a5,80002cb6 <devintr+0x76>
    return 1;
    80002c88:	4505                	li	a0,1
    } else if(irq){
    80002c8a:	d8f1                	beqz	s1,80002c5e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c8c:	85a6                	mv	a1,s1
    80002c8e:	00005517          	auipc	a0,0x5
    80002c92:	65250513          	addi	a0,a0,1618 # 800082e0 <states.0+0x38>
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	8de080e7          	jalr	-1826(ra) # 80000574 <printf>
      plic_complete(irq);
    80002c9e:	8526                	mv	a0,s1
    80002ca0:	00003097          	auipc	ra,0x3
    80002ca4:	58c080e7          	jalr	1420(ra) # 8000622c <plic_complete>
    return 1;
    80002ca8:	4505                	li	a0,1
    80002caa:	bf55                	j	80002c5e <devintr+0x1e>
      uartintr();
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	cda080e7          	jalr	-806(ra) # 80000986 <uartintr>
    80002cb4:	b7ed                	j	80002c9e <devintr+0x5e>
      virtio_disk_intr();
    80002cb6:	00004097          	auipc	ra,0x4
    80002cba:	a08080e7          	jalr	-1528(ra) # 800066be <virtio_disk_intr>
    80002cbe:	b7c5                	j	80002c9e <devintr+0x5e>
    if(cpuid() == 0){
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	c94080e7          	jalr	-876(ra) # 80001954 <cpuid>
    80002cc8:	c901                	beqz	a0,80002cd8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cca:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cd0:	14479073          	csrw	sip,a5
    return 2;
    80002cd4:	4509                	li	a0,2
    80002cd6:	b761                	j	80002c5e <devintr+0x1e>
      clockintr();
    80002cd8:	00000097          	auipc	ra,0x0
    80002cdc:	f22080e7          	jalr	-222(ra) # 80002bfa <clockintr>
    80002ce0:	b7ed                	j	80002cca <devintr+0x8a>

0000000080002ce2 <usertrap>:
{
    80002ce2:	1101                	addi	sp,sp,-32
    80002ce4:	ec06                	sd	ra,24(sp)
    80002ce6:	e822                	sd	s0,16(sp)
    80002ce8:	e426                	sd	s1,8(sp)
    80002cea:	e04a                	sd	s2,0(sp)
    80002cec:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cee:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002cf2:	1007f793          	andi	a5,a5,256
    80002cf6:	e3bd                	bnez	a5,80002d5c <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cf8:	00003797          	auipc	a5,0x3
    80002cfc:	40878793          	addi	a5,a5,1032 # 80006100 <kernelvec>
    80002d00:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	c7c080e7          	jalr	-900(ra) # 80001980 <myproc>
    80002d0c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d0e:	1f053783          	ld	a5,496(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d12:	14102773          	csrr	a4,sepc
    80002d16:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d18:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d1c:	47a1                	li	a5,8
    80002d1e:	04f71d63          	bne	a4,a5,80002d78 <usertrap+0x96>
    if(p->killed)
    80002d22:	551c                	lw	a5,40(a0)
    80002d24:	e7a1                	bnez	a5,80002d6c <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002d26:	1f04b703          	ld	a4,496(s1)
    80002d2a:	6f1c                	ld	a5,24(a4)
    80002d2c:	0791                	addi	a5,a5,4
    80002d2e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d38:	10079073          	csrw	sstatus,a5
    syscall();
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	2f2080e7          	jalr	754(ra) # 8000302e <syscall>
  if(p->killed)
    80002d44:	549c                	lw	a5,40(s1)
    80002d46:	ebc1                	bnez	a5,80002dd6 <usertrap+0xf4>
  usertrapret();
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	df8080e7          	jalr	-520(ra) # 80002b40 <usertrapret>
}
    80002d50:	60e2                	ld	ra,24(sp)
    80002d52:	6442                	ld	s0,16(sp)
    80002d54:	64a2                	ld	s1,8(sp)
    80002d56:	6902                	ld	s2,0(sp)
    80002d58:	6105                	addi	sp,sp,32
    80002d5a:	8082                	ret
    panic("usertrap: not from user mode");
    80002d5c:	00005517          	auipc	a0,0x5
    80002d60:	5a450513          	addi	a0,a0,1444 # 80008300 <states.0+0x58>
    80002d64:	ffffd097          	auipc	ra,0xffffd
    80002d68:	7c6080e7          	jalr	1990(ra) # 8000052a <panic>
      exit(-1);
    80002d6c:	557d                	li	a0,-1
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	87c080e7          	jalr	-1924(ra) # 800025ea <exit>
    80002d76:	bf45                	j	80002d26 <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002d78:	00000097          	auipc	ra,0x0
    80002d7c:	ec8080e7          	jalr	-312(ra) # 80002c40 <devintr>
    80002d80:	892a                	mv	s2,a0
    80002d82:	c501                	beqz	a0,80002d8a <usertrap+0xa8>
  if(p->killed)
    80002d84:	549c                	lw	a5,40(s1)
    80002d86:	c3a1                	beqz	a5,80002dc6 <usertrap+0xe4>
    80002d88:	a815                	j	80002dbc <usertrap+0xda>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d8a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d8e:	5890                	lw	a2,48(s1)
    80002d90:	00005517          	auipc	a0,0x5
    80002d94:	59050513          	addi	a0,a0,1424 # 80008320 <states.0+0x78>
    80002d98:	ffffd097          	auipc	ra,0xffffd
    80002d9c:	7dc080e7          	jalr	2012(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002da0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002da4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	5a850513          	addi	a0,a0,1448 # 80008350 <states.0+0xa8>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	7c4080e7          	jalr	1988(ra) # 80000574 <printf>
    p->killed = 1;
    80002db8:	4785                	li	a5,1
    80002dba:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002dbc:	557d                	li	a0,-1
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	82c080e7          	jalr	-2004(ra) # 800025ea <exit>
  if(which_dev == 2)
    80002dc6:	4789                	li	a5,2
    80002dc8:	f8f910e3          	bne	s2,a5,80002d48 <usertrap+0x66>
    yield();
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	3f4080e7          	jalr	1012(ra) # 800021c0 <yield>
    80002dd4:	bf95                	j	80002d48 <usertrap+0x66>
  int which_dev = 0;
    80002dd6:	4901                	li	s2,0
    80002dd8:	b7d5                	j	80002dbc <usertrap+0xda>

0000000080002dda <kerneltrap>:
{
    80002dda:	7179                	addi	sp,sp,-48
    80002ddc:	f406                	sd	ra,40(sp)
    80002dde:	f022                	sd	s0,32(sp)
    80002de0:	ec26                	sd	s1,24(sp)
    80002de2:	e84a                	sd	s2,16(sp)
    80002de4:	e44e                	sd	s3,8(sp)
    80002de6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002de8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dec:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002df4:	1004f793          	andi	a5,s1,256
    80002df8:	cb85                	beqz	a5,80002e28 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dfa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002dfe:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e00:	ef85                	bnez	a5,80002e38 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	e3e080e7          	jalr	-450(ra) # 80002c40 <devintr>
    80002e0a:	cd1d                	beqz	a0,80002e48 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e0c:	4789                	li	a5,2
    80002e0e:	06f50a63          	beq	a0,a5,80002e82 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e12:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e16:	10049073          	csrw	sstatus,s1
}
    80002e1a:	70a2                	ld	ra,40(sp)
    80002e1c:	7402                	ld	s0,32(sp)
    80002e1e:	64e2                	ld	s1,24(sp)
    80002e20:	6942                	ld	s2,16(sp)
    80002e22:	69a2                	ld	s3,8(sp)
    80002e24:	6145                	addi	sp,sp,48
    80002e26:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e28:	00005517          	auipc	a0,0x5
    80002e2c:	54850513          	addi	a0,a0,1352 # 80008370 <states.0+0xc8>
    80002e30:	ffffd097          	auipc	ra,0xffffd
    80002e34:	6fa080e7          	jalr	1786(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002e38:	00005517          	auipc	a0,0x5
    80002e3c:	56050513          	addi	a0,a0,1376 # 80008398 <states.0+0xf0>
    80002e40:	ffffd097          	auipc	ra,0xffffd
    80002e44:	6ea080e7          	jalr	1770(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002e48:	85ce                	mv	a1,s3
    80002e4a:	00005517          	auipc	a0,0x5
    80002e4e:	56e50513          	addi	a0,a0,1390 # 800083b8 <states.0+0x110>
    80002e52:	ffffd097          	auipc	ra,0xffffd
    80002e56:	722080e7          	jalr	1826(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e5a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e5e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e62:	00005517          	auipc	a0,0x5
    80002e66:	56650513          	addi	a0,a0,1382 # 800083c8 <states.0+0x120>
    80002e6a:	ffffd097          	auipc	ra,0xffffd
    80002e6e:	70a080e7          	jalr	1802(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	56e50513          	addi	a0,a0,1390 # 800083e0 <states.0+0x138>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	6b0080e7          	jalr	1712(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	afe080e7          	jalr	-1282(ra) # 80001980 <myproc>
    80002e8a:	d541                	beqz	a0,80002e12 <kerneltrap+0x38>
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	af4080e7          	jalr	-1292(ra) # 80001980 <myproc>
    80002e94:	4d18                	lw	a4,24(a0)
    80002e96:	4791                	li	a5,4
    80002e98:	f6f71de3          	bne	a4,a5,80002e12 <kerneltrap+0x38>
    yield();
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	324080e7          	jalr	804(ra) # 800021c0 <yield>
    80002ea4:	b7bd                	j	80002e12 <kerneltrap+0x38>

0000000080002ea6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ea6:	1101                	addi	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	e426                	sd	s1,8(sp)
    80002eae:	1000                	addi	s0,sp,32
    80002eb0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	ace080e7          	jalr	-1330(ra) # 80001980 <myproc>
  switch (n) {
    80002eba:	4795                	li	a5,5
    80002ebc:	0497e763          	bltu	a5,s1,80002f0a <argraw+0x64>
    80002ec0:	048a                	slli	s1,s1,0x2
    80002ec2:	00005717          	auipc	a4,0x5
    80002ec6:	55670713          	addi	a4,a4,1366 # 80008418 <states.0+0x170>
    80002eca:	94ba                	add	s1,s1,a4
    80002ecc:	409c                	lw	a5,0(s1)
    80002ece:	97ba                	add	a5,a5,a4
    80002ed0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ed2:	1f053783          	ld	a5,496(a0)
    80002ed6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	64a2                	ld	s1,8(sp)
    80002ede:	6105                	addi	sp,sp,32
    80002ee0:	8082                	ret
    return p->trapframe->a1;
    80002ee2:	1f053783          	ld	a5,496(a0)
    80002ee6:	7fa8                	ld	a0,120(a5)
    80002ee8:	bfc5                	j	80002ed8 <argraw+0x32>
    return p->trapframe->a2;
    80002eea:	1f053783          	ld	a5,496(a0)
    80002eee:	63c8                	ld	a0,128(a5)
    80002ef0:	b7e5                	j	80002ed8 <argraw+0x32>
    return p->trapframe->a3;
    80002ef2:	1f053783          	ld	a5,496(a0)
    80002ef6:	67c8                	ld	a0,136(a5)
    80002ef8:	b7c5                	j	80002ed8 <argraw+0x32>
    return p->trapframe->a4;
    80002efa:	1f053783          	ld	a5,496(a0)
    80002efe:	6bc8                	ld	a0,144(a5)
    80002f00:	bfe1                	j	80002ed8 <argraw+0x32>
    return p->trapframe->a5;
    80002f02:	1f053783          	ld	a5,496(a0)
    80002f06:	6fc8                	ld	a0,152(a5)
    80002f08:	bfc1                	j	80002ed8 <argraw+0x32>
  panic("argraw");
    80002f0a:	00005517          	auipc	a0,0x5
    80002f0e:	4e650513          	addi	a0,a0,1254 # 800083f0 <states.0+0x148>
    80002f12:	ffffd097          	auipc	ra,0xffffd
    80002f16:	618080e7          	jalr	1560(ra) # 8000052a <panic>

0000000080002f1a <fetchaddr>:
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	e426                	sd	s1,8(sp)
    80002f22:	e04a                	sd	s2,0(sp)
    80002f24:	1000                	addi	s0,sp,32
    80002f26:	84aa                	mv	s1,a0
    80002f28:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	a56080e7          	jalr	-1450(ra) # 80001980 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f32:	1e053783          	ld	a5,480(a0)
    80002f36:	02f4f963          	bgeu	s1,a5,80002f68 <fetchaddr+0x4e>
    80002f3a:	00848713          	addi	a4,s1,8
    80002f3e:	02e7e763          	bltu	a5,a4,80002f6c <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f42:	46a1                	li	a3,8
    80002f44:	8626                	mv	a2,s1
    80002f46:	85ca                	mv	a1,s2
    80002f48:	1e853503          	ld	a0,488(a0)
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	77e080e7          	jalr	1918(ra) # 800016ca <copyin>
    80002f54:	00a03533          	snez	a0,a0
    80002f58:	40a00533          	neg	a0,a0
}
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	64a2                	ld	s1,8(sp)
    80002f62:	6902                	ld	s2,0(sp)
    80002f64:	6105                	addi	sp,sp,32
    80002f66:	8082                	ret
    return -1;
    80002f68:	557d                	li	a0,-1
    80002f6a:	bfcd                	j	80002f5c <fetchaddr+0x42>
    80002f6c:	557d                	li	a0,-1
    80002f6e:	b7fd                	j	80002f5c <fetchaddr+0x42>

0000000080002f70 <fetchstr>:
{
    80002f70:	7179                	addi	sp,sp,-48
    80002f72:	f406                	sd	ra,40(sp)
    80002f74:	f022                	sd	s0,32(sp)
    80002f76:	ec26                	sd	s1,24(sp)
    80002f78:	e84a                	sd	s2,16(sp)
    80002f7a:	e44e                	sd	s3,8(sp)
    80002f7c:	1800                	addi	s0,sp,48
    80002f7e:	892a                	mv	s2,a0
    80002f80:	84ae                	mv	s1,a1
    80002f82:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	9fc080e7          	jalr	-1540(ra) # 80001980 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f8c:	86ce                	mv	a3,s3
    80002f8e:	864a                	mv	a2,s2
    80002f90:	85a6                	mv	a1,s1
    80002f92:	1e853503          	ld	a0,488(a0)
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	7c2080e7          	jalr	1986(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002f9e:	00054763          	bltz	a0,80002fac <fetchstr+0x3c>
  return strlen(buf);
    80002fa2:	8526                	mv	a0,s1
    80002fa4:	ffffe097          	auipc	ra,0xffffe
    80002fa8:	e9e080e7          	jalr	-354(ra) # 80000e42 <strlen>
}
    80002fac:	70a2                	ld	ra,40(sp)
    80002fae:	7402                	ld	s0,32(sp)
    80002fb0:	64e2                	ld	s1,24(sp)
    80002fb2:	6942                	ld	s2,16(sp)
    80002fb4:	69a2                	ld	s3,8(sp)
    80002fb6:	6145                	addi	sp,sp,48
    80002fb8:	8082                	ret

0000000080002fba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002fba:	1101                	addi	sp,sp,-32
    80002fbc:	ec06                	sd	ra,24(sp)
    80002fbe:	e822                	sd	s0,16(sp)
    80002fc0:	e426                	sd	s1,8(sp)
    80002fc2:	1000                	addi	s0,sp,32
    80002fc4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	ee0080e7          	jalr	-288(ra) # 80002ea6 <argraw>
    80002fce:	c088                	sw	a0,0(s1)
  return 0;
}
    80002fd0:	4501                	li	a0,0
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	64a2                	ld	s1,8(sp)
    80002fd8:	6105                	addi	sp,sp,32
    80002fda:	8082                	ret

0000000080002fdc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002fdc:	1101                	addi	sp,sp,-32
    80002fde:	ec06                	sd	ra,24(sp)
    80002fe0:	e822                	sd	s0,16(sp)
    80002fe2:	e426                	sd	s1,8(sp)
    80002fe4:	1000                	addi	s0,sp,32
    80002fe6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fe8:	00000097          	auipc	ra,0x0
    80002fec:	ebe080e7          	jalr	-322(ra) # 80002ea6 <argraw>
    80002ff0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ff2:	4501                	li	a0,0
    80002ff4:	60e2                	ld	ra,24(sp)
    80002ff6:	6442                	ld	s0,16(sp)
    80002ff8:	64a2                	ld	s1,8(sp)
    80002ffa:	6105                	addi	sp,sp,32
    80002ffc:	8082                	ret

0000000080002ffe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	e426                	sd	s1,8(sp)
    80003006:	e04a                	sd	s2,0(sp)
    80003008:	1000                	addi	s0,sp,32
    8000300a:	84ae                	mv	s1,a1
    8000300c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	e98080e7          	jalr	-360(ra) # 80002ea6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003016:	864a                	mv	a2,s2
    80003018:	85a6                	mv	a1,s1
    8000301a:	00000097          	auipc	ra,0x0
    8000301e:	f56080e7          	jalr	-170(ra) # 80002f70 <fetchstr>
}
    80003022:	60e2                	ld	ra,24(sp)
    80003024:	6442                	ld	s0,16(sp)
    80003026:	64a2                	ld	s1,8(sp)
    80003028:	6902                	ld	s2,0(sp)
    8000302a:	6105                	addi	sp,sp,32
    8000302c:	8082                	ret

000000008000302e <syscall>:
[SYS_sigret]   sys_sigret, // ADDED Q2.1.5
};

void
syscall(void)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	e04a                	sd	s2,0(sp)
    80003038:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	946080e7          	jalr	-1722(ra) # 80001980 <myproc>
    80003042:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003044:	1f053903          	ld	s2,496(a0)
    80003048:	0a893783          	ld	a5,168(s2)
    8000304c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003050:	37fd                	addiw	a5,a5,-1
    80003052:	475d                	li	a4,23
    80003054:	00f76f63          	bltu	a4,a5,80003072 <syscall+0x44>
    80003058:	00369713          	slli	a4,a3,0x3
    8000305c:	00005797          	auipc	a5,0x5
    80003060:	3d478793          	addi	a5,a5,980 # 80008430 <syscalls>
    80003064:	97ba                	add	a5,a5,a4
    80003066:	639c                	ld	a5,0(a5)
    80003068:	c789                	beqz	a5,80003072 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000306a:	9782                	jalr	a5
    8000306c:	06a93823          	sd	a0,112(s2)
    80003070:	a005                	j	80003090 <syscall+0x62>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003072:	2f048613          	addi	a2,s1,752
    80003076:	588c                	lw	a1,48(s1)
    80003078:	00005517          	auipc	a0,0x5
    8000307c:	38050513          	addi	a0,a0,896 # 800083f8 <states.0+0x150>
    80003080:	ffffd097          	auipc	ra,0xffffd
    80003084:	4f4080e7          	jalr	1268(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003088:	1f04b783          	ld	a5,496(s1)
    8000308c:	577d                	li	a4,-1
    8000308e:	fbb8                	sd	a4,112(a5)
  }
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6902                	ld	s2,0(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000309c:	1101                	addi	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030a4:	fec40593          	addi	a1,s0,-20
    800030a8:	4501                	li	a0,0
    800030aa:	00000097          	auipc	ra,0x0
    800030ae:	f10080e7          	jalr	-240(ra) # 80002fba <argint>
    return -1;
    800030b2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030b4:	00054963          	bltz	a0,800030c6 <sys_exit+0x2a>
  exit(n);
    800030b8:	fec42503          	lw	a0,-20(s0)
    800030bc:	fffff097          	auipc	ra,0xfffff
    800030c0:	52e080e7          	jalr	1326(ra) # 800025ea <exit>
  return 0;  // not reached
    800030c4:	4781                	li	a5,0
}
    800030c6:	853e                	mv	a0,a5
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	6105                	addi	sp,sp,32
    800030ce:	8082                	ret

00000000800030d0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030d0:	1141                	addi	sp,sp,-16
    800030d2:	e406                	sd	ra,8(sp)
    800030d4:	e022                	sd	s0,0(sp)
    800030d6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	8a8080e7          	jalr	-1880(ra) # 80001980 <myproc>
}
    800030e0:	5908                	lw	a0,48(a0)
    800030e2:	60a2                	ld	ra,8(sp)
    800030e4:	6402                	ld	s0,0(sp)
    800030e6:	0141                	addi	sp,sp,16
    800030e8:	8082                	ret

00000000800030ea <sys_fork>:

uint64
sys_fork(void)
{
    800030ea:	1141                	addi	sp,sp,-16
    800030ec:	e406                	sd	ra,8(sp)
    800030ee:	e022                	sd	s0,0(sp)
    800030f0:	0800                	addi	s0,sp,16
  return fork();
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	ca2080e7          	jalr	-862(ra) # 80001d94 <fork>
}
    800030fa:	60a2                	ld	ra,8(sp)
    800030fc:	6402                	ld	s0,0(sp)
    800030fe:	0141                	addi	sp,sp,16
    80003100:	8082                	ret

0000000080003102 <sys_wait>:

uint64
sys_wait(void)
{
    80003102:	1101                	addi	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000310a:	fe840593          	addi	a1,s0,-24
    8000310e:	4501                	li	a0,0
    80003110:	00000097          	auipc	ra,0x0
    80003114:	ecc080e7          	jalr	-308(ra) # 80002fdc <argaddr>
    80003118:	87aa                	mv	a5,a0
    return -1;
    8000311a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000311c:	0007c863          	bltz	a5,8000312c <sys_wait+0x2a>
  return wait(p);
    80003120:	fe843503          	ld	a0,-24(s0)
    80003124:	fffff097          	auipc	ra,0xfffff
    80003128:	2c8080e7          	jalr	712(ra) # 800023ec <wait>
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	6105                	addi	sp,sp,32
    80003132:	8082                	ret

0000000080003134 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003134:	7179                	addi	sp,sp,-48
    80003136:	f406                	sd	ra,40(sp)
    80003138:	f022                	sd	s0,32(sp)
    8000313a:	ec26                	sd	s1,24(sp)
    8000313c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000313e:	fdc40593          	addi	a1,s0,-36
    80003142:	4501                	li	a0,0
    80003144:	00000097          	auipc	ra,0x0
    80003148:	e76080e7          	jalr	-394(ra) # 80002fba <argint>
    return -1;
    8000314c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000314e:	02054063          	bltz	a0,8000316e <sys_sbrk+0x3a>
  addr = myproc()->sz;
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	82e080e7          	jalr	-2002(ra) # 80001980 <myproc>
    8000315a:	1e052483          	lw	s1,480(a0)
  if(growproc(n) < 0)
    8000315e:	fdc42503          	lw	a0,-36(s0)
    80003162:	fffff097          	auipc	ra,0xfffff
    80003166:	bb8080e7          	jalr	-1096(ra) # 80001d1a <growproc>
    8000316a:	00054863          	bltz	a0,8000317a <sys_sbrk+0x46>
    return -1;
  return addr;
}
    8000316e:	8526                	mv	a0,s1
    80003170:	70a2                	ld	ra,40(sp)
    80003172:	7402                	ld	s0,32(sp)
    80003174:	64e2                	ld	s1,24(sp)
    80003176:	6145                	addi	sp,sp,48
    80003178:	8082                	ret
    return -1;
    8000317a:	54fd                	li	s1,-1
    8000317c:	bfcd                	j	8000316e <sys_sbrk+0x3a>

000000008000317e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000317e:	7139                	addi	sp,sp,-64
    80003180:	fc06                	sd	ra,56(sp)
    80003182:	f822                	sd	s0,48(sp)
    80003184:	f426                	sd	s1,40(sp)
    80003186:	f04a                	sd	s2,32(sp)
    80003188:	ec4e                	sd	s3,24(sp)
    8000318a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000318c:	fcc40593          	addi	a1,s0,-52
    80003190:	4501                	li	a0,0
    80003192:	00000097          	auipc	ra,0x0
    80003196:	e28080e7          	jalr	-472(ra) # 80002fba <argint>
    return -1;
    8000319a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000319c:	06054563          	bltz	a0,80003206 <sys_sleep+0x88>
  acquire(&tickslock);
    800031a0:	0001a517          	auipc	a0,0x1a
    800031a4:	53050513          	addi	a0,a0,1328 # 8001d6d0 <tickslock>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	a1a080e7          	jalr	-1510(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    800031b0:	00006917          	auipc	s2,0x6
    800031b4:	e8092903          	lw	s2,-384(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800031b8:	fcc42783          	lw	a5,-52(s0)
    800031bc:	cf85                	beqz	a5,800031f4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800031be:	0001a997          	auipc	s3,0x1a
    800031c2:	51298993          	addi	s3,s3,1298 # 8001d6d0 <tickslock>
    800031c6:	00006497          	auipc	s1,0x6
    800031ca:	e6a48493          	addi	s1,s1,-406 # 80009030 <ticks>
    if(myproc()->killed){
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	7b2080e7          	jalr	1970(ra) # 80001980 <myproc>
    800031d6:	551c                	lw	a5,40(a0)
    800031d8:	ef9d                	bnez	a5,80003216 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800031da:	85ce                	mv	a1,s3
    800031dc:	8526                	mv	a0,s1
    800031de:	fffff097          	auipc	ra,0xfffff
    800031e2:	1aa080e7          	jalr	426(ra) # 80002388 <sleep>
  while(ticks - ticks0 < n){
    800031e6:	409c                	lw	a5,0(s1)
    800031e8:	412787bb          	subw	a5,a5,s2
    800031ec:	fcc42703          	lw	a4,-52(s0)
    800031f0:	fce7efe3          	bltu	a5,a4,800031ce <sys_sleep+0x50>
  }
  release(&tickslock);
    800031f4:	0001a517          	auipc	a0,0x1a
    800031f8:	4dc50513          	addi	a0,a0,1244 # 8001d6d0 <tickslock>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	a7a080e7          	jalr	-1414(ra) # 80000c76 <release>
  return 0;
    80003204:	4781                	li	a5,0
}
    80003206:	853e                	mv	a0,a5
    80003208:	70e2                	ld	ra,56(sp)
    8000320a:	7442                	ld	s0,48(sp)
    8000320c:	74a2                	ld	s1,40(sp)
    8000320e:	7902                	ld	s2,32(sp)
    80003210:	69e2                	ld	s3,24(sp)
    80003212:	6121                	addi	sp,sp,64
    80003214:	8082                	ret
      release(&tickslock);
    80003216:	0001a517          	auipc	a0,0x1a
    8000321a:	4ba50513          	addi	a0,a0,1210 # 8001d6d0 <tickslock>
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	a58080e7          	jalr	-1448(ra) # 80000c76 <release>
      return -1;
    80003226:	57fd                	li	a5,-1
    80003228:	bff9                	j	80003206 <sys_sleep+0x88>

000000008000322a <sys_kill>:

// ADDED Q2.2.1
uint64
sys_kill(void)
{
    8000322a:	1101                	addi	sp,sp,-32
    8000322c:	ec06                	sd	ra,24(sp)
    8000322e:	e822                	sd	s0,16(sp)
    80003230:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    80003232:	fec40593          	addi	a1,s0,-20
    80003236:	4501                	li	a0,0
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	d82080e7          	jalr	-638(ra) # 80002fba <argint>
    return -1;
    80003240:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80003242:	02054563          	bltz	a0,8000326c <sys_kill+0x42>

  if(argint(1, &signum) < 0)
    80003246:	fe840593          	addi	a1,s0,-24
    8000324a:	4505                	li	a0,1
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	d6e080e7          	jalr	-658(ra) # 80002fba <argint>
    return -1;
    80003254:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    80003256:	00054b63          	bltz	a0,8000326c <sys_kill+0x42>

  return kill(pid, signum);
    8000325a:	fe842583          	lw	a1,-24(s0)
    8000325e:	fec42503          	lw	a0,-20(s0)
    80003262:	fffff097          	auipc	ra,0xfffff
    80003266:	45e080e7          	jalr	1118(ra) # 800026c0 <kill>
    8000326a:	87aa                	mv	a5,a0
}
    8000326c:	853e                	mv	a0,a5
    8000326e:	60e2                	ld	ra,24(sp)
    80003270:	6442                	ld	s0,16(sp)
    80003272:	6105                	addi	sp,sp,32
    80003274:	8082                	ret

0000000080003276 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003276:	1101                	addi	sp,sp,-32
    80003278:	ec06                	sd	ra,24(sp)
    8000327a:	e822                	sd	s0,16(sp)
    8000327c:	e426                	sd	s1,8(sp)
    8000327e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003280:	0001a517          	auipc	a0,0x1a
    80003284:	45050513          	addi	a0,a0,1104 # 8001d6d0 <tickslock>
    80003288:	ffffe097          	auipc	ra,0xffffe
    8000328c:	93a080e7          	jalr	-1734(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003290:	00006497          	auipc	s1,0x6
    80003294:	da04a483          	lw	s1,-608(s1) # 80009030 <ticks>
  release(&tickslock);
    80003298:	0001a517          	auipc	a0,0x1a
    8000329c:	43850513          	addi	a0,a0,1080 # 8001d6d0 <tickslock>
    800032a0:	ffffe097          	auipc	ra,0xffffe
    800032a4:	9d6080e7          	jalr	-1578(ra) # 80000c76 <release>
  return xticks;
}
    800032a8:	02049513          	slli	a0,s1,0x20
    800032ac:	9101                	srli	a0,a0,0x20
    800032ae:	60e2                	ld	ra,24(sp)
    800032b0:	6442                	ld	s0,16(sp)
    800032b2:	64a2                	ld	s1,8(sp)
    800032b4:	6105                	addi	sp,sp,32
    800032b6:	8082                	ret

00000000800032b8 <sys_sigprocmask>:

// ADDED Q2.1.3
uint64
sys_sigprocmask(void)
{
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	1000                	addi	s0,sp,32
  uint sigmask;

  if(argint(0, (int *)&sigmask) < 0) 
    800032c0:	fec40593          	addi	a1,s0,-20
    800032c4:	4501                	li	a0,0
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	cf4080e7          	jalr	-780(ra) # 80002fba <argint>
    800032ce:	87aa                	mv	a5,a0
    return -1;
    800032d0:	557d                	li	a0,-1
  if(argint(0, (int *)&sigmask) < 0) 
    800032d2:	0007ca63          	bltz	a5,800032e6 <sys_sigprocmask+0x2e>

  return sigprocmask(sigmask);
    800032d6:	fec42503          	lw	a0,-20(s0)
    800032da:	fffff097          	auipc	ra,0xfffff
    800032de:	5c2080e7          	jalr	1474(ra) # 8000289c <sigprocmask>
    800032e2:	1502                	slli	a0,a0,0x20
    800032e4:	9101                	srli	a0,a0,0x20
}
    800032e6:	60e2                	ld	ra,24(sp)
    800032e8:	6442                	ld	s0,16(sp)
    800032ea:	6105                	addi	sp,sp,32
    800032ec:	8082                	ret

00000000800032ee <sys_sigaction>:

// ADDED Q2.1.4
uint64
sys_sigaction(void)
{
    800032ee:	7179                	addi	sp,sp,-48
    800032f0:	f406                	sd	ra,40(sp)
    800032f2:	f022                	sd	s0,32(sp)
    800032f4:	1800                	addi	s0,sp,48
  int signum;
  uint64 act;
  uint64 oldact;

  if(argint(0, &signum) < 0)
    800032f6:	fec40593          	addi	a1,s0,-20
    800032fa:	4501                	li	a0,0
    800032fc:	00000097          	auipc	ra,0x0
    80003300:	cbe080e7          	jalr	-834(ra) # 80002fba <argint>
    return -1;
    80003304:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    80003306:	04054163          	bltz	a0,80003348 <sys_sigaction+0x5a>

  if(argaddr(1, &act) < 0)
    8000330a:	fe040593          	addi	a1,s0,-32
    8000330e:	4505                	li	a0,1
    80003310:	00000097          	auipc	ra,0x0
    80003314:	ccc080e7          	jalr	-820(ra) # 80002fdc <argaddr>
    return -1;
    80003318:	57fd                	li	a5,-1
  if(argaddr(1, &act) < 0)
    8000331a:	02054763          	bltz	a0,80003348 <sys_sigaction+0x5a>

  if(argaddr(2, &oldact) < 0)
    8000331e:	fd840593          	addi	a1,s0,-40
    80003322:	4509                	li	a0,2
    80003324:	00000097          	auipc	ra,0x0
    80003328:	cb8080e7          	jalr	-840(ra) # 80002fdc <argaddr>
    return -1;
    8000332c:	57fd                	li	a5,-1
  if(argaddr(2, &oldact) < 0)
    8000332e:	00054d63          	bltz	a0,80003348 <sys_sigaction+0x5a>

  return sigaction(signum, (struct sigaction *)act, (struct sigaction *)oldact);
    80003332:	fd843603          	ld	a2,-40(s0)
    80003336:	fe043583          	ld	a1,-32(s0)
    8000333a:	fec42503          	lw	a0,-20(s0)
    8000333e:	fffff097          	auipc	ra,0xfffff
    80003342:	5be080e7          	jalr	1470(ra) # 800028fc <sigaction>
    80003346:	87aa                	mv	a5,a0
}
    80003348:	853e                	mv	a0,a5
    8000334a:	70a2                	ld	ra,40(sp)
    8000334c:	7402                	ld	s0,32(sp)
    8000334e:	6145                	addi	sp,sp,48
    80003350:	8082                	ret

0000000080003352 <sys_sigret>:

// ADDED Q2.1.5
uint64
sys_sigret(void)
{
    80003352:	1141                	addi	sp,sp,-16
    80003354:	e406                	sd	ra,8(sp)
    80003356:	e022                	sd	s0,0(sp)
    80003358:	0800                	addi	s0,sp,16
  sigret();
    8000335a:	fffff097          	auipc	ra,0xfffff
    8000335e:	6f0080e7          	jalr	1776(ra) # 80002a4a <sigret>
  return 0;
}
    80003362:	4501                	li	a0,0
    80003364:	60a2                	ld	ra,8(sp)
    80003366:	6402                	ld	s0,0(sp)
    80003368:	0141                	addi	sp,sp,16
    8000336a:	8082                	ret

000000008000336c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000336c:	7179                	addi	sp,sp,-48
    8000336e:	f406                	sd	ra,40(sp)
    80003370:	f022                	sd	s0,32(sp)
    80003372:	ec26                	sd	s1,24(sp)
    80003374:	e84a                	sd	s2,16(sp)
    80003376:	e44e                	sd	s3,8(sp)
    80003378:	e052                	sd	s4,0(sp)
    8000337a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000337c:	00005597          	auipc	a1,0x5
    80003380:	17c58593          	addi	a1,a1,380 # 800084f8 <syscalls+0xc8>
    80003384:	0001a517          	auipc	a0,0x1a
    80003388:	36450513          	addi	a0,a0,868 # 8001d6e8 <bcache>
    8000338c:	ffffd097          	auipc	ra,0xffffd
    80003390:	7a6080e7          	jalr	1958(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003394:	00022797          	auipc	a5,0x22
    80003398:	35478793          	addi	a5,a5,852 # 800256e8 <bcache+0x8000>
    8000339c:	00022717          	auipc	a4,0x22
    800033a0:	5b470713          	addi	a4,a4,1460 # 80025950 <bcache+0x8268>
    800033a4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033a8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ac:	0001a497          	auipc	s1,0x1a
    800033b0:	35448493          	addi	s1,s1,852 # 8001d700 <bcache+0x18>
    b->next = bcache.head.next;
    800033b4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033b6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033b8:	00005a17          	auipc	s4,0x5
    800033bc:	148a0a13          	addi	s4,s4,328 # 80008500 <syscalls+0xd0>
    b->next = bcache.head.next;
    800033c0:	2b893783          	ld	a5,696(s2)
    800033c4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033c6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033ca:	85d2                	mv	a1,s4
    800033cc:	01048513          	addi	a0,s1,16
    800033d0:	00001097          	auipc	ra,0x1
    800033d4:	4c2080e7          	jalr	1218(ra) # 80004892 <initsleeplock>
    bcache.head.next->prev = b;
    800033d8:	2b893783          	ld	a5,696(s2)
    800033dc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033de:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033e2:	45848493          	addi	s1,s1,1112
    800033e6:	fd349de3          	bne	s1,s3,800033c0 <binit+0x54>
  }
}
    800033ea:	70a2                	ld	ra,40(sp)
    800033ec:	7402                	ld	s0,32(sp)
    800033ee:	64e2                	ld	s1,24(sp)
    800033f0:	6942                	ld	s2,16(sp)
    800033f2:	69a2                	ld	s3,8(sp)
    800033f4:	6a02                	ld	s4,0(sp)
    800033f6:	6145                	addi	sp,sp,48
    800033f8:	8082                	ret

00000000800033fa <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033fa:	7179                	addi	sp,sp,-48
    800033fc:	f406                	sd	ra,40(sp)
    800033fe:	f022                	sd	s0,32(sp)
    80003400:	ec26                	sd	s1,24(sp)
    80003402:	e84a                	sd	s2,16(sp)
    80003404:	e44e                	sd	s3,8(sp)
    80003406:	1800                	addi	s0,sp,48
    80003408:	892a                	mv	s2,a0
    8000340a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000340c:	0001a517          	auipc	a0,0x1a
    80003410:	2dc50513          	addi	a0,a0,732 # 8001d6e8 <bcache>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	7ae080e7          	jalr	1966(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000341c:	00022497          	auipc	s1,0x22
    80003420:	5844b483          	ld	s1,1412(s1) # 800259a0 <bcache+0x82b8>
    80003424:	00022797          	auipc	a5,0x22
    80003428:	52c78793          	addi	a5,a5,1324 # 80025950 <bcache+0x8268>
    8000342c:	02f48f63          	beq	s1,a5,8000346a <bread+0x70>
    80003430:	873e                	mv	a4,a5
    80003432:	a021                	j	8000343a <bread+0x40>
    80003434:	68a4                	ld	s1,80(s1)
    80003436:	02e48a63          	beq	s1,a4,8000346a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000343a:	449c                	lw	a5,8(s1)
    8000343c:	ff279ce3          	bne	a5,s2,80003434 <bread+0x3a>
    80003440:	44dc                	lw	a5,12(s1)
    80003442:	ff3799e3          	bne	a5,s3,80003434 <bread+0x3a>
      b->refcnt++;
    80003446:	40bc                	lw	a5,64(s1)
    80003448:	2785                	addiw	a5,a5,1
    8000344a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000344c:	0001a517          	auipc	a0,0x1a
    80003450:	29c50513          	addi	a0,a0,668 # 8001d6e8 <bcache>
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	822080e7          	jalr	-2014(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000345c:	01048513          	addi	a0,s1,16
    80003460:	00001097          	auipc	ra,0x1
    80003464:	46c080e7          	jalr	1132(ra) # 800048cc <acquiresleep>
      return b;
    80003468:	a8b9                	j	800034c6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000346a:	00022497          	auipc	s1,0x22
    8000346e:	52e4b483          	ld	s1,1326(s1) # 80025998 <bcache+0x82b0>
    80003472:	00022797          	auipc	a5,0x22
    80003476:	4de78793          	addi	a5,a5,1246 # 80025950 <bcache+0x8268>
    8000347a:	00f48863          	beq	s1,a5,8000348a <bread+0x90>
    8000347e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003480:	40bc                	lw	a5,64(s1)
    80003482:	cf81                	beqz	a5,8000349a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003484:	64a4                	ld	s1,72(s1)
    80003486:	fee49de3          	bne	s1,a4,80003480 <bread+0x86>
  panic("bget: no buffers");
    8000348a:	00005517          	auipc	a0,0x5
    8000348e:	07e50513          	addi	a0,a0,126 # 80008508 <syscalls+0xd8>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	098080e7          	jalr	152(ra) # 8000052a <panic>
      b->dev = dev;
    8000349a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000349e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034a2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034a6:	4785                	li	a5,1
    800034a8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034aa:	0001a517          	auipc	a0,0x1a
    800034ae:	23e50513          	addi	a0,a0,574 # 8001d6e8 <bcache>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	7c4080e7          	jalr	1988(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800034ba:	01048513          	addi	a0,s1,16
    800034be:	00001097          	auipc	ra,0x1
    800034c2:	40e080e7          	jalr	1038(ra) # 800048cc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034c6:	409c                	lw	a5,0(s1)
    800034c8:	cb89                	beqz	a5,800034da <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034ca:	8526                	mv	a0,s1
    800034cc:	70a2                	ld	ra,40(sp)
    800034ce:	7402                	ld	s0,32(sp)
    800034d0:	64e2                	ld	s1,24(sp)
    800034d2:	6942                	ld	s2,16(sp)
    800034d4:	69a2                	ld	s3,8(sp)
    800034d6:	6145                	addi	sp,sp,48
    800034d8:	8082                	ret
    virtio_disk_rw(b, 0);
    800034da:	4581                	li	a1,0
    800034dc:	8526                	mv	a0,s1
    800034de:	00003097          	auipc	ra,0x3
    800034e2:	f58080e7          	jalr	-168(ra) # 80006436 <virtio_disk_rw>
    b->valid = 1;
    800034e6:	4785                	li	a5,1
    800034e8:	c09c                	sw	a5,0(s1)
  return b;
    800034ea:	b7c5                	j	800034ca <bread+0xd0>

00000000800034ec <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034ec:	1101                	addi	sp,sp,-32
    800034ee:	ec06                	sd	ra,24(sp)
    800034f0:	e822                	sd	s0,16(sp)
    800034f2:	e426                	sd	s1,8(sp)
    800034f4:	1000                	addi	s0,sp,32
    800034f6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034f8:	0541                	addi	a0,a0,16
    800034fa:	00001097          	auipc	ra,0x1
    800034fe:	46c080e7          	jalr	1132(ra) # 80004966 <holdingsleep>
    80003502:	cd01                	beqz	a0,8000351a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003504:	4585                	li	a1,1
    80003506:	8526                	mv	a0,s1
    80003508:	00003097          	auipc	ra,0x3
    8000350c:	f2e080e7          	jalr	-210(ra) # 80006436 <virtio_disk_rw>
}
    80003510:	60e2                	ld	ra,24(sp)
    80003512:	6442                	ld	s0,16(sp)
    80003514:	64a2                	ld	s1,8(sp)
    80003516:	6105                	addi	sp,sp,32
    80003518:	8082                	ret
    panic("bwrite");
    8000351a:	00005517          	auipc	a0,0x5
    8000351e:	00650513          	addi	a0,a0,6 # 80008520 <syscalls+0xf0>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	008080e7          	jalr	8(ra) # 8000052a <panic>

000000008000352a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000352a:	1101                	addi	sp,sp,-32
    8000352c:	ec06                	sd	ra,24(sp)
    8000352e:	e822                	sd	s0,16(sp)
    80003530:	e426                	sd	s1,8(sp)
    80003532:	e04a                	sd	s2,0(sp)
    80003534:	1000                	addi	s0,sp,32
    80003536:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003538:	01050913          	addi	s2,a0,16
    8000353c:	854a                	mv	a0,s2
    8000353e:	00001097          	auipc	ra,0x1
    80003542:	428080e7          	jalr	1064(ra) # 80004966 <holdingsleep>
    80003546:	c92d                	beqz	a0,800035b8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003548:	854a                	mv	a0,s2
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	3d8080e7          	jalr	984(ra) # 80004922 <releasesleep>

  acquire(&bcache.lock);
    80003552:	0001a517          	auipc	a0,0x1a
    80003556:	19650513          	addi	a0,a0,406 # 8001d6e8 <bcache>
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	668080e7          	jalr	1640(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003562:	40bc                	lw	a5,64(s1)
    80003564:	37fd                	addiw	a5,a5,-1
    80003566:	0007871b          	sext.w	a4,a5
    8000356a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000356c:	eb05                	bnez	a4,8000359c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000356e:	68bc                	ld	a5,80(s1)
    80003570:	64b8                	ld	a4,72(s1)
    80003572:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003574:	64bc                	ld	a5,72(s1)
    80003576:	68b8                	ld	a4,80(s1)
    80003578:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000357a:	00022797          	auipc	a5,0x22
    8000357e:	16e78793          	addi	a5,a5,366 # 800256e8 <bcache+0x8000>
    80003582:	2b87b703          	ld	a4,696(a5)
    80003586:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003588:	00022717          	auipc	a4,0x22
    8000358c:	3c870713          	addi	a4,a4,968 # 80025950 <bcache+0x8268>
    80003590:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003592:	2b87b703          	ld	a4,696(a5)
    80003596:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003598:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000359c:	0001a517          	auipc	a0,0x1a
    800035a0:	14c50513          	addi	a0,a0,332 # 8001d6e8 <bcache>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	6d2080e7          	jalr	1746(ra) # 80000c76 <release>
}
    800035ac:	60e2                	ld	ra,24(sp)
    800035ae:	6442                	ld	s0,16(sp)
    800035b0:	64a2                	ld	s1,8(sp)
    800035b2:	6902                	ld	s2,0(sp)
    800035b4:	6105                	addi	sp,sp,32
    800035b6:	8082                	ret
    panic("brelse");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	f7050513          	addi	a0,a0,-144 # 80008528 <syscalls+0xf8>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f6a080e7          	jalr	-150(ra) # 8000052a <panic>

00000000800035c8 <bpin>:

void
bpin(struct buf *b) {
    800035c8:	1101                	addi	sp,sp,-32
    800035ca:	ec06                	sd	ra,24(sp)
    800035cc:	e822                	sd	s0,16(sp)
    800035ce:	e426                	sd	s1,8(sp)
    800035d0:	1000                	addi	s0,sp,32
    800035d2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035d4:	0001a517          	auipc	a0,0x1a
    800035d8:	11450513          	addi	a0,a0,276 # 8001d6e8 <bcache>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	5e6080e7          	jalr	1510(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800035e4:	40bc                	lw	a5,64(s1)
    800035e6:	2785                	addiw	a5,a5,1
    800035e8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035ea:	0001a517          	auipc	a0,0x1a
    800035ee:	0fe50513          	addi	a0,a0,254 # 8001d6e8 <bcache>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	684080e7          	jalr	1668(ra) # 80000c76 <release>
}
    800035fa:	60e2                	ld	ra,24(sp)
    800035fc:	6442                	ld	s0,16(sp)
    800035fe:	64a2                	ld	s1,8(sp)
    80003600:	6105                	addi	sp,sp,32
    80003602:	8082                	ret

0000000080003604 <bunpin>:

void
bunpin(struct buf *b) {
    80003604:	1101                	addi	sp,sp,-32
    80003606:	ec06                	sd	ra,24(sp)
    80003608:	e822                	sd	s0,16(sp)
    8000360a:	e426                	sd	s1,8(sp)
    8000360c:	1000                	addi	s0,sp,32
    8000360e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003610:	0001a517          	auipc	a0,0x1a
    80003614:	0d850513          	addi	a0,a0,216 # 8001d6e8 <bcache>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	5aa080e7          	jalr	1450(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003620:	40bc                	lw	a5,64(s1)
    80003622:	37fd                	addiw	a5,a5,-1
    80003624:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003626:	0001a517          	auipc	a0,0x1a
    8000362a:	0c250513          	addi	a0,a0,194 # 8001d6e8 <bcache>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	648080e7          	jalr	1608(ra) # 80000c76 <release>
}
    80003636:	60e2                	ld	ra,24(sp)
    80003638:	6442                	ld	s0,16(sp)
    8000363a:	64a2                	ld	s1,8(sp)
    8000363c:	6105                	addi	sp,sp,32
    8000363e:	8082                	ret

0000000080003640 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003640:	1101                	addi	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	e04a                	sd	s2,0(sp)
    8000364a:	1000                	addi	s0,sp,32
    8000364c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000364e:	00d5d59b          	srliw	a1,a1,0xd
    80003652:	00022797          	auipc	a5,0x22
    80003656:	7727a783          	lw	a5,1906(a5) # 80025dc4 <sb+0x1c>
    8000365a:	9dbd                	addw	a1,a1,a5
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	d9e080e7          	jalr	-610(ra) # 800033fa <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003664:	0074f713          	andi	a4,s1,7
    80003668:	4785                	li	a5,1
    8000366a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000366e:	14ce                	slli	s1,s1,0x33
    80003670:	90d9                	srli	s1,s1,0x36
    80003672:	00950733          	add	a4,a0,s1
    80003676:	05874703          	lbu	a4,88(a4)
    8000367a:	00e7f6b3          	and	a3,a5,a4
    8000367e:	c69d                	beqz	a3,800036ac <bfree+0x6c>
    80003680:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003682:	94aa                	add	s1,s1,a0
    80003684:	fff7c793          	not	a5,a5
    80003688:	8ff9                	and	a5,a5,a4
    8000368a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000368e:	00001097          	auipc	ra,0x1
    80003692:	11e080e7          	jalr	286(ra) # 800047ac <log_write>
  brelse(bp);
    80003696:	854a                	mv	a0,s2
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	e92080e7          	jalr	-366(ra) # 8000352a <brelse>
}
    800036a0:	60e2                	ld	ra,24(sp)
    800036a2:	6442                	ld	s0,16(sp)
    800036a4:	64a2                	ld	s1,8(sp)
    800036a6:	6902                	ld	s2,0(sp)
    800036a8:	6105                	addi	sp,sp,32
    800036aa:	8082                	ret
    panic("freeing free block");
    800036ac:	00005517          	auipc	a0,0x5
    800036b0:	e8450513          	addi	a0,a0,-380 # 80008530 <syscalls+0x100>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	e76080e7          	jalr	-394(ra) # 8000052a <panic>

00000000800036bc <balloc>:
{
    800036bc:	711d                	addi	sp,sp,-96
    800036be:	ec86                	sd	ra,88(sp)
    800036c0:	e8a2                	sd	s0,80(sp)
    800036c2:	e4a6                	sd	s1,72(sp)
    800036c4:	e0ca                	sd	s2,64(sp)
    800036c6:	fc4e                	sd	s3,56(sp)
    800036c8:	f852                	sd	s4,48(sp)
    800036ca:	f456                	sd	s5,40(sp)
    800036cc:	f05a                	sd	s6,32(sp)
    800036ce:	ec5e                	sd	s7,24(sp)
    800036d0:	e862                	sd	s8,16(sp)
    800036d2:	e466                	sd	s9,8(sp)
    800036d4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036d6:	00022797          	auipc	a5,0x22
    800036da:	6d67a783          	lw	a5,1750(a5) # 80025dac <sb+0x4>
    800036de:	cbd1                	beqz	a5,80003772 <balloc+0xb6>
    800036e0:	8baa                	mv	s7,a0
    800036e2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036e4:	00022b17          	auipc	s6,0x22
    800036e8:	6c4b0b13          	addi	s6,s6,1732 # 80025da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ec:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036ee:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036f0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036f2:	6c89                	lui	s9,0x2
    800036f4:	a831                	j	80003710 <balloc+0x54>
    brelse(bp);
    800036f6:	854a                	mv	a0,s2
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	e32080e7          	jalr	-462(ra) # 8000352a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003700:	015c87bb          	addw	a5,s9,s5
    80003704:	00078a9b          	sext.w	s5,a5
    80003708:	004b2703          	lw	a4,4(s6)
    8000370c:	06eaf363          	bgeu	s5,a4,80003772 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003710:	41fad79b          	sraiw	a5,s5,0x1f
    80003714:	0137d79b          	srliw	a5,a5,0x13
    80003718:	015787bb          	addw	a5,a5,s5
    8000371c:	40d7d79b          	sraiw	a5,a5,0xd
    80003720:	01cb2583          	lw	a1,28(s6)
    80003724:	9dbd                	addw	a1,a1,a5
    80003726:	855e                	mv	a0,s7
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	cd2080e7          	jalr	-814(ra) # 800033fa <bread>
    80003730:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003732:	004b2503          	lw	a0,4(s6)
    80003736:	000a849b          	sext.w	s1,s5
    8000373a:	8662                	mv	a2,s8
    8000373c:	faa4fde3          	bgeu	s1,a0,800036f6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003740:	41f6579b          	sraiw	a5,a2,0x1f
    80003744:	01d7d69b          	srliw	a3,a5,0x1d
    80003748:	00c6873b          	addw	a4,a3,a2
    8000374c:	00777793          	andi	a5,a4,7
    80003750:	9f95                	subw	a5,a5,a3
    80003752:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003756:	4037571b          	sraiw	a4,a4,0x3
    8000375a:	00e906b3          	add	a3,s2,a4
    8000375e:	0586c683          	lbu	a3,88(a3)
    80003762:	00d7f5b3          	and	a1,a5,a3
    80003766:	cd91                	beqz	a1,80003782 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003768:	2605                	addiw	a2,a2,1
    8000376a:	2485                	addiw	s1,s1,1
    8000376c:	fd4618e3          	bne	a2,s4,8000373c <balloc+0x80>
    80003770:	b759                	j	800036f6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003772:	00005517          	auipc	a0,0x5
    80003776:	dd650513          	addi	a0,a0,-554 # 80008548 <syscalls+0x118>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	db0080e7          	jalr	-592(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003782:	974a                	add	a4,a4,s2
    80003784:	8fd5                	or	a5,a5,a3
    80003786:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000378a:	854a                	mv	a0,s2
    8000378c:	00001097          	auipc	ra,0x1
    80003790:	020080e7          	jalr	32(ra) # 800047ac <log_write>
        brelse(bp);
    80003794:	854a                	mv	a0,s2
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	d94080e7          	jalr	-620(ra) # 8000352a <brelse>
  bp = bread(dev, bno);
    8000379e:	85a6                	mv	a1,s1
    800037a0:	855e                	mv	a0,s7
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	c58080e7          	jalr	-936(ra) # 800033fa <bread>
    800037aa:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037ac:	40000613          	li	a2,1024
    800037b0:	4581                	li	a1,0
    800037b2:	05850513          	addi	a0,a0,88
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	508080e7          	jalr	1288(ra) # 80000cbe <memset>
  log_write(bp);
    800037be:	854a                	mv	a0,s2
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	fec080e7          	jalr	-20(ra) # 800047ac <log_write>
  brelse(bp);
    800037c8:	854a                	mv	a0,s2
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	d60080e7          	jalr	-672(ra) # 8000352a <brelse>
}
    800037d2:	8526                	mv	a0,s1
    800037d4:	60e6                	ld	ra,88(sp)
    800037d6:	6446                	ld	s0,80(sp)
    800037d8:	64a6                	ld	s1,72(sp)
    800037da:	6906                	ld	s2,64(sp)
    800037dc:	79e2                	ld	s3,56(sp)
    800037de:	7a42                	ld	s4,48(sp)
    800037e0:	7aa2                	ld	s5,40(sp)
    800037e2:	7b02                	ld	s6,32(sp)
    800037e4:	6be2                	ld	s7,24(sp)
    800037e6:	6c42                	ld	s8,16(sp)
    800037e8:	6ca2                	ld	s9,8(sp)
    800037ea:	6125                	addi	sp,sp,96
    800037ec:	8082                	ret

00000000800037ee <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037ee:	7179                	addi	sp,sp,-48
    800037f0:	f406                	sd	ra,40(sp)
    800037f2:	f022                	sd	s0,32(sp)
    800037f4:	ec26                	sd	s1,24(sp)
    800037f6:	e84a                	sd	s2,16(sp)
    800037f8:	e44e                	sd	s3,8(sp)
    800037fa:	e052                	sd	s4,0(sp)
    800037fc:	1800                	addi	s0,sp,48
    800037fe:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003800:	47ad                	li	a5,11
    80003802:	04b7fe63          	bgeu	a5,a1,8000385e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003806:	ff45849b          	addiw	s1,a1,-12
    8000380a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000380e:	0ff00793          	li	a5,255
    80003812:	0ae7e463          	bltu	a5,a4,800038ba <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003816:	08052583          	lw	a1,128(a0)
    8000381a:	c5b5                	beqz	a1,80003886 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000381c:	00092503          	lw	a0,0(s2)
    80003820:	00000097          	auipc	ra,0x0
    80003824:	bda080e7          	jalr	-1062(ra) # 800033fa <bread>
    80003828:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000382a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000382e:	02049713          	slli	a4,s1,0x20
    80003832:	01e75593          	srli	a1,a4,0x1e
    80003836:	00b784b3          	add	s1,a5,a1
    8000383a:	0004a983          	lw	s3,0(s1)
    8000383e:	04098e63          	beqz	s3,8000389a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003842:	8552                	mv	a0,s4
    80003844:	00000097          	auipc	ra,0x0
    80003848:	ce6080e7          	jalr	-794(ra) # 8000352a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000384c:	854e                	mv	a0,s3
    8000384e:	70a2                	ld	ra,40(sp)
    80003850:	7402                	ld	s0,32(sp)
    80003852:	64e2                	ld	s1,24(sp)
    80003854:	6942                	ld	s2,16(sp)
    80003856:	69a2                	ld	s3,8(sp)
    80003858:	6a02                	ld	s4,0(sp)
    8000385a:	6145                	addi	sp,sp,48
    8000385c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000385e:	02059793          	slli	a5,a1,0x20
    80003862:	01e7d593          	srli	a1,a5,0x1e
    80003866:	00b504b3          	add	s1,a0,a1
    8000386a:	0504a983          	lw	s3,80(s1)
    8000386e:	fc099fe3          	bnez	s3,8000384c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003872:	4108                	lw	a0,0(a0)
    80003874:	00000097          	auipc	ra,0x0
    80003878:	e48080e7          	jalr	-440(ra) # 800036bc <balloc>
    8000387c:	0005099b          	sext.w	s3,a0
    80003880:	0534a823          	sw	s3,80(s1)
    80003884:	b7e1                	j	8000384c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003886:	4108                	lw	a0,0(a0)
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	e34080e7          	jalr	-460(ra) # 800036bc <balloc>
    80003890:	0005059b          	sext.w	a1,a0
    80003894:	08b92023          	sw	a1,128(s2)
    80003898:	b751                	j	8000381c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000389a:	00092503          	lw	a0,0(s2)
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	e1e080e7          	jalr	-482(ra) # 800036bc <balloc>
    800038a6:	0005099b          	sext.w	s3,a0
    800038aa:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038ae:	8552                	mv	a0,s4
    800038b0:	00001097          	auipc	ra,0x1
    800038b4:	efc080e7          	jalr	-260(ra) # 800047ac <log_write>
    800038b8:	b769                	j	80003842 <bmap+0x54>
  panic("bmap: out of range");
    800038ba:	00005517          	auipc	a0,0x5
    800038be:	ca650513          	addi	a0,a0,-858 # 80008560 <syscalls+0x130>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	c68080e7          	jalr	-920(ra) # 8000052a <panic>

00000000800038ca <iget>:
{
    800038ca:	7179                	addi	sp,sp,-48
    800038cc:	f406                	sd	ra,40(sp)
    800038ce:	f022                	sd	s0,32(sp)
    800038d0:	ec26                	sd	s1,24(sp)
    800038d2:	e84a                	sd	s2,16(sp)
    800038d4:	e44e                	sd	s3,8(sp)
    800038d6:	e052                	sd	s4,0(sp)
    800038d8:	1800                	addi	s0,sp,48
    800038da:	89aa                	mv	s3,a0
    800038dc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038de:	00022517          	auipc	a0,0x22
    800038e2:	4ea50513          	addi	a0,a0,1258 # 80025dc8 <itable>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	2dc080e7          	jalr	732(ra) # 80000bc2 <acquire>
  empty = 0;
    800038ee:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038f0:	00022497          	auipc	s1,0x22
    800038f4:	4f048493          	addi	s1,s1,1264 # 80025de0 <itable+0x18>
    800038f8:	00024697          	auipc	a3,0x24
    800038fc:	f7868693          	addi	a3,a3,-136 # 80027870 <log>
    80003900:	a039                	j	8000390e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003902:	02090b63          	beqz	s2,80003938 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003906:	08848493          	addi	s1,s1,136
    8000390a:	02d48a63          	beq	s1,a3,8000393e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000390e:	449c                	lw	a5,8(s1)
    80003910:	fef059e3          	blez	a5,80003902 <iget+0x38>
    80003914:	4098                	lw	a4,0(s1)
    80003916:	ff3716e3          	bne	a4,s3,80003902 <iget+0x38>
    8000391a:	40d8                	lw	a4,4(s1)
    8000391c:	ff4713e3          	bne	a4,s4,80003902 <iget+0x38>
      ip->ref++;
    80003920:	2785                	addiw	a5,a5,1
    80003922:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003924:	00022517          	auipc	a0,0x22
    80003928:	4a450513          	addi	a0,a0,1188 # 80025dc8 <itable>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	34a080e7          	jalr	842(ra) # 80000c76 <release>
      return ip;
    80003934:	8926                	mv	s2,s1
    80003936:	a03d                	j	80003964 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003938:	f7f9                	bnez	a5,80003906 <iget+0x3c>
    8000393a:	8926                	mv	s2,s1
    8000393c:	b7e9                	j	80003906 <iget+0x3c>
  if(empty == 0)
    8000393e:	02090c63          	beqz	s2,80003976 <iget+0xac>
  ip->dev = dev;
    80003942:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003946:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000394a:	4785                	li	a5,1
    8000394c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003950:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003954:	00022517          	auipc	a0,0x22
    80003958:	47450513          	addi	a0,a0,1140 # 80025dc8 <itable>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	31a080e7          	jalr	794(ra) # 80000c76 <release>
}
    80003964:	854a                	mv	a0,s2
    80003966:	70a2                	ld	ra,40(sp)
    80003968:	7402                	ld	s0,32(sp)
    8000396a:	64e2                	ld	s1,24(sp)
    8000396c:	6942                	ld	s2,16(sp)
    8000396e:	69a2                	ld	s3,8(sp)
    80003970:	6a02                	ld	s4,0(sp)
    80003972:	6145                	addi	sp,sp,48
    80003974:	8082                	ret
    panic("iget: no inodes");
    80003976:	00005517          	auipc	a0,0x5
    8000397a:	c0250513          	addi	a0,a0,-1022 # 80008578 <syscalls+0x148>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	bac080e7          	jalr	-1108(ra) # 8000052a <panic>

0000000080003986 <fsinit>:
fsinit(int dev) {
    80003986:	7179                	addi	sp,sp,-48
    80003988:	f406                	sd	ra,40(sp)
    8000398a:	f022                	sd	s0,32(sp)
    8000398c:	ec26                	sd	s1,24(sp)
    8000398e:	e84a                	sd	s2,16(sp)
    80003990:	e44e                	sd	s3,8(sp)
    80003992:	1800                	addi	s0,sp,48
    80003994:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003996:	4585                	li	a1,1
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	a62080e7          	jalr	-1438(ra) # 800033fa <bread>
    800039a0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039a2:	00022997          	auipc	s3,0x22
    800039a6:	40698993          	addi	s3,s3,1030 # 80025da8 <sb>
    800039aa:	02000613          	li	a2,32
    800039ae:	05850593          	addi	a1,a0,88
    800039b2:	854e                	mv	a0,s3
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	366080e7          	jalr	870(ra) # 80000d1a <memmove>
  brelse(bp);
    800039bc:	8526                	mv	a0,s1
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	b6c080e7          	jalr	-1172(ra) # 8000352a <brelse>
  if(sb.magic != FSMAGIC)
    800039c6:	0009a703          	lw	a4,0(s3)
    800039ca:	102037b7          	lui	a5,0x10203
    800039ce:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039d2:	02f71263          	bne	a4,a5,800039f6 <fsinit+0x70>
  initlog(dev, &sb);
    800039d6:	00022597          	auipc	a1,0x22
    800039da:	3d258593          	addi	a1,a1,978 # 80025da8 <sb>
    800039de:	854a                	mv	a0,s2
    800039e0:	00001097          	auipc	ra,0x1
    800039e4:	b4e080e7          	jalr	-1202(ra) # 8000452e <initlog>
}
    800039e8:	70a2                	ld	ra,40(sp)
    800039ea:	7402                	ld	s0,32(sp)
    800039ec:	64e2                	ld	s1,24(sp)
    800039ee:	6942                	ld	s2,16(sp)
    800039f0:	69a2                	ld	s3,8(sp)
    800039f2:	6145                	addi	sp,sp,48
    800039f4:	8082                	ret
    panic("invalid file system");
    800039f6:	00005517          	auipc	a0,0x5
    800039fa:	b9250513          	addi	a0,a0,-1134 # 80008588 <syscalls+0x158>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	b2c080e7          	jalr	-1236(ra) # 8000052a <panic>

0000000080003a06 <iinit>:
{
    80003a06:	7179                	addi	sp,sp,-48
    80003a08:	f406                	sd	ra,40(sp)
    80003a0a:	f022                	sd	s0,32(sp)
    80003a0c:	ec26                	sd	s1,24(sp)
    80003a0e:	e84a                	sd	s2,16(sp)
    80003a10:	e44e                	sd	s3,8(sp)
    80003a12:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a14:	00005597          	auipc	a1,0x5
    80003a18:	b8c58593          	addi	a1,a1,-1140 # 800085a0 <syscalls+0x170>
    80003a1c:	00022517          	auipc	a0,0x22
    80003a20:	3ac50513          	addi	a0,a0,940 # 80025dc8 <itable>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	10e080e7          	jalr	270(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a2c:	00022497          	auipc	s1,0x22
    80003a30:	3c448493          	addi	s1,s1,964 # 80025df0 <itable+0x28>
    80003a34:	00024997          	auipc	s3,0x24
    80003a38:	e4c98993          	addi	s3,s3,-436 # 80027880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a3c:	00005917          	auipc	s2,0x5
    80003a40:	b6c90913          	addi	s2,s2,-1172 # 800085a8 <syscalls+0x178>
    80003a44:	85ca                	mv	a1,s2
    80003a46:	8526                	mv	a0,s1
    80003a48:	00001097          	auipc	ra,0x1
    80003a4c:	e4a080e7          	jalr	-438(ra) # 80004892 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a50:	08848493          	addi	s1,s1,136
    80003a54:	ff3498e3          	bne	s1,s3,80003a44 <iinit+0x3e>
}
    80003a58:	70a2                	ld	ra,40(sp)
    80003a5a:	7402                	ld	s0,32(sp)
    80003a5c:	64e2                	ld	s1,24(sp)
    80003a5e:	6942                	ld	s2,16(sp)
    80003a60:	69a2                	ld	s3,8(sp)
    80003a62:	6145                	addi	sp,sp,48
    80003a64:	8082                	ret

0000000080003a66 <ialloc>:
{
    80003a66:	715d                	addi	sp,sp,-80
    80003a68:	e486                	sd	ra,72(sp)
    80003a6a:	e0a2                	sd	s0,64(sp)
    80003a6c:	fc26                	sd	s1,56(sp)
    80003a6e:	f84a                	sd	s2,48(sp)
    80003a70:	f44e                	sd	s3,40(sp)
    80003a72:	f052                	sd	s4,32(sp)
    80003a74:	ec56                	sd	s5,24(sp)
    80003a76:	e85a                	sd	s6,16(sp)
    80003a78:	e45e                	sd	s7,8(sp)
    80003a7a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a7c:	00022717          	auipc	a4,0x22
    80003a80:	33872703          	lw	a4,824(a4) # 80025db4 <sb+0xc>
    80003a84:	4785                	li	a5,1
    80003a86:	04e7fa63          	bgeu	a5,a4,80003ada <ialloc+0x74>
    80003a8a:	8aaa                	mv	s5,a0
    80003a8c:	8bae                	mv	s7,a1
    80003a8e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a90:	00022a17          	auipc	s4,0x22
    80003a94:	318a0a13          	addi	s4,s4,792 # 80025da8 <sb>
    80003a98:	00048b1b          	sext.w	s6,s1
    80003a9c:	0044d793          	srli	a5,s1,0x4
    80003aa0:	018a2583          	lw	a1,24(s4)
    80003aa4:	9dbd                	addw	a1,a1,a5
    80003aa6:	8556                	mv	a0,s5
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	952080e7          	jalr	-1710(ra) # 800033fa <bread>
    80003ab0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ab2:	05850993          	addi	s3,a0,88
    80003ab6:	00f4f793          	andi	a5,s1,15
    80003aba:	079a                	slli	a5,a5,0x6
    80003abc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003abe:	00099783          	lh	a5,0(s3)
    80003ac2:	c785                	beqz	a5,80003aea <ialloc+0x84>
    brelse(bp);
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	a66080e7          	jalr	-1434(ra) # 8000352a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003acc:	0485                	addi	s1,s1,1
    80003ace:	00ca2703          	lw	a4,12(s4)
    80003ad2:	0004879b          	sext.w	a5,s1
    80003ad6:	fce7e1e3          	bltu	a5,a4,80003a98 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ada:	00005517          	auipc	a0,0x5
    80003ade:	ad650513          	addi	a0,a0,-1322 # 800085b0 <syscalls+0x180>
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	a48080e7          	jalr	-1464(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003aea:	04000613          	li	a2,64
    80003aee:	4581                	li	a1,0
    80003af0:	854e                	mv	a0,s3
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	1cc080e7          	jalr	460(ra) # 80000cbe <memset>
      dip->type = type;
    80003afa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003afe:	854a                	mv	a0,s2
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	cac080e7          	jalr	-852(ra) # 800047ac <log_write>
      brelse(bp);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	a20080e7          	jalr	-1504(ra) # 8000352a <brelse>
      return iget(dev, inum);
    80003b12:	85da                	mv	a1,s6
    80003b14:	8556                	mv	a0,s5
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	db4080e7          	jalr	-588(ra) # 800038ca <iget>
}
    80003b1e:	60a6                	ld	ra,72(sp)
    80003b20:	6406                	ld	s0,64(sp)
    80003b22:	74e2                	ld	s1,56(sp)
    80003b24:	7942                	ld	s2,48(sp)
    80003b26:	79a2                	ld	s3,40(sp)
    80003b28:	7a02                	ld	s4,32(sp)
    80003b2a:	6ae2                	ld	s5,24(sp)
    80003b2c:	6b42                	ld	s6,16(sp)
    80003b2e:	6ba2                	ld	s7,8(sp)
    80003b30:	6161                	addi	sp,sp,80
    80003b32:	8082                	ret

0000000080003b34 <iupdate>:
{
    80003b34:	1101                	addi	sp,sp,-32
    80003b36:	ec06                	sd	ra,24(sp)
    80003b38:	e822                	sd	s0,16(sp)
    80003b3a:	e426                	sd	s1,8(sp)
    80003b3c:	e04a                	sd	s2,0(sp)
    80003b3e:	1000                	addi	s0,sp,32
    80003b40:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b42:	415c                	lw	a5,4(a0)
    80003b44:	0047d79b          	srliw	a5,a5,0x4
    80003b48:	00022597          	auipc	a1,0x22
    80003b4c:	2785a583          	lw	a1,632(a1) # 80025dc0 <sb+0x18>
    80003b50:	9dbd                	addw	a1,a1,a5
    80003b52:	4108                	lw	a0,0(a0)
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	8a6080e7          	jalr	-1882(ra) # 800033fa <bread>
    80003b5c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b5e:	05850793          	addi	a5,a0,88
    80003b62:	40c8                	lw	a0,4(s1)
    80003b64:	893d                	andi	a0,a0,15
    80003b66:	051a                	slli	a0,a0,0x6
    80003b68:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b6a:	04449703          	lh	a4,68(s1)
    80003b6e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b72:	04649703          	lh	a4,70(s1)
    80003b76:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b7a:	04849703          	lh	a4,72(s1)
    80003b7e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b82:	04a49703          	lh	a4,74(s1)
    80003b86:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b8a:	44f8                	lw	a4,76(s1)
    80003b8c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b8e:	03400613          	li	a2,52
    80003b92:	05048593          	addi	a1,s1,80
    80003b96:	0531                	addi	a0,a0,12
    80003b98:	ffffd097          	auipc	ra,0xffffd
    80003b9c:	182080e7          	jalr	386(ra) # 80000d1a <memmove>
  log_write(bp);
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	00001097          	auipc	ra,0x1
    80003ba6:	c0a080e7          	jalr	-1014(ra) # 800047ac <log_write>
  brelse(bp);
    80003baa:	854a                	mv	a0,s2
    80003bac:	00000097          	auipc	ra,0x0
    80003bb0:	97e080e7          	jalr	-1666(ra) # 8000352a <brelse>
}
    80003bb4:	60e2                	ld	ra,24(sp)
    80003bb6:	6442                	ld	s0,16(sp)
    80003bb8:	64a2                	ld	s1,8(sp)
    80003bba:	6902                	ld	s2,0(sp)
    80003bbc:	6105                	addi	sp,sp,32
    80003bbe:	8082                	ret

0000000080003bc0 <idup>:
{
    80003bc0:	1101                	addi	sp,sp,-32
    80003bc2:	ec06                	sd	ra,24(sp)
    80003bc4:	e822                	sd	s0,16(sp)
    80003bc6:	e426                	sd	s1,8(sp)
    80003bc8:	1000                	addi	s0,sp,32
    80003bca:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bcc:	00022517          	auipc	a0,0x22
    80003bd0:	1fc50513          	addi	a0,a0,508 # 80025dc8 <itable>
    80003bd4:	ffffd097          	auipc	ra,0xffffd
    80003bd8:	fee080e7          	jalr	-18(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003bdc:	449c                	lw	a5,8(s1)
    80003bde:	2785                	addiw	a5,a5,1
    80003be0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003be2:	00022517          	auipc	a0,0x22
    80003be6:	1e650513          	addi	a0,a0,486 # 80025dc8 <itable>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	08c080e7          	jalr	140(ra) # 80000c76 <release>
}
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	60e2                	ld	ra,24(sp)
    80003bf6:	6442                	ld	s0,16(sp)
    80003bf8:	64a2                	ld	s1,8(sp)
    80003bfa:	6105                	addi	sp,sp,32
    80003bfc:	8082                	ret

0000000080003bfe <ilock>:
{
    80003bfe:	1101                	addi	sp,sp,-32
    80003c00:	ec06                	sd	ra,24(sp)
    80003c02:	e822                	sd	s0,16(sp)
    80003c04:	e426                	sd	s1,8(sp)
    80003c06:	e04a                	sd	s2,0(sp)
    80003c08:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c0a:	c115                	beqz	a0,80003c2e <ilock+0x30>
    80003c0c:	84aa                	mv	s1,a0
    80003c0e:	451c                	lw	a5,8(a0)
    80003c10:	00f05f63          	blez	a5,80003c2e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c14:	0541                	addi	a0,a0,16
    80003c16:	00001097          	auipc	ra,0x1
    80003c1a:	cb6080e7          	jalr	-842(ra) # 800048cc <acquiresleep>
  if(ip->valid == 0){
    80003c1e:	40bc                	lw	a5,64(s1)
    80003c20:	cf99                	beqz	a5,80003c3e <ilock+0x40>
}
    80003c22:	60e2                	ld	ra,24(sp)
    80003c24:	6442                	ld	s0,16(sp)
    80003c26:	64a2                	ld	s1,8(sp)
    80003c28:	6902                	ld	s2,0(sp)
    80003c2a:	6105                	addi	sp,sp,32
    80003c2c:	8082                	ret
    panic("ilock");
    80003c2e:	00005517          	auipc	a0,0x5
    80003c32:	99a50513          	addi	a0,a0,-1638 # 800085c8 <syscalls+0x198>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	8f4080e7          	jalr	-1804(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c3e:	40dc                	lw	a5,4(s1)
    80003c40:	0047d79b          	srliw	a5,a5,0x4
    80003c44:	00022597          	auipc	a1,0x22
    80003c48:	17c5a583          	lw	a1,380(a1) # 80025dc0 <sb+0x18>
    80003c4c:	9dbd                	addw	a1,a1,a5
    80003c4e:	4088                	lw	a0,0(s1)
    80003c50:	fffff097          	auipc	ra,0xfffff
    80003c54:	7aa080e7          	jalr	1962(ra) # 800033fa <bread>
    80003c58:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c5a:	05850593          	addi	a1,a0,88
    80003c5e:	40dc                	lw	a5,4(s1)
    80003c60:	8bbd                	andi	a5,a5,15
    80003c62:	079a                	slli	a5,a5,0x6
    80003c64:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c66:	00059783          	lh	a5,0(a1)
    80003c6a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c6e:	00259783          	lh	a5,2(a1)
    80003c72:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c76:	00459783          	lh	a5,4(a1)
    80003c7a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c7e:	00659783          	lh	a5,6(a1)
    80003c82:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c86:	459c                	lw	a5,8(a1)
    80003c88:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c8a:	03400613          	li	a2,52
    80003c8e:	05b1                	addi	a1,a1,12
    80003c90:	05048513          	addi	a0,s1,80
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	086080e7          	jalr	134(ra) # 80000d1a <memmove>
    brelse(bp);
    80003c9c:	854a                	mv	a0,s2
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	88c080e7          	jalr	-1908(ra) # 8000352a <brelse>
    ip->valid = 1;
    80003ca6:	4785                	li	a5,1
    80003ca8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003caa:	04449783          	lh	a5,68(s1)
    80003cae:	fbb5                	bnez	a5,80003c22 <ilock+0x24>
      panic("ilock: no type");
    80003cb0:	00005517          	auipc	a0,0x5
    80003cb4:	92050513          	addi	a0,a0,-1760 # 800085d0 <syscalls+0x1a0>
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	872080e7          	jalr	-1934(ra) # 8000052a <panic>

0000000080003cc0 <iunlock>:
{
    80003cc0:	1101                	addi	sp,sp,-32
    80003cc2:	ec06                	sd	ra,24(sp)
    80003cc4:	e822                	sd	s0,16(sp)
    80003cc6:	e426                	sd	s1,8(sp)
    80003cc8:	e04a                	sd	s2,0(sp)
    80003cca:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ccc:	c905                	beqz	a0,80003cfc <iunlock+0x3c>
    80003cce:	84aa                	mv	s1,a0
    80003cd0:	01050913          	addi	s2,a0,16
    80003cd4:	854a                	mv	a0,s2
    80003cd6:	00001097          	auipc	ra,0x1
    80003cda:	c90080e7          	jalr	-880(ra) # 80004966 <holdingsleep>
    80003cde:	cd19                	beqz	a0,80003cfc <iunlock+0x3c>
    80003ce0:	449c                	lw	a5,8(s1)
    80003ce2:	00f05d63          	blez	a5,80003cfc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00001097          	auipc	ra,0x1
    80003cec:	c3a080e7          	jalr	-966(ra) # 80004922 <releasesleep>
}
    80003cf0:	60e2                	ld	ra,24(sp)
    80003cf2:	6442                	ld	s0,16(sp)
    80003cf4:	64a2                	ld	s1,8(sp)
    80003cf6:	6902                	ld	s2,0(sp)
    80003cf8:	6105                	addi	sp,sp,32
    80003cfa:	8082                	ret
    panic("iunlock");
    80003cfc:	00005517          	auipc	a0,0x5
    80003d00:	8e450513          	addi	a0,a0,-1820 # 800085e0 <syscalls+0x1b0>
    80003d04:	ffffd097          	auipc	ra,0xffffd
    80003d08:	826080e7          	jalr	-2010(ra) # 8000052a <panic>

0000000080003d0c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d0c:	7179                	addi	sp,sp,-48
    80003d0e:	f406                	sd	ra,40(sp)
    80003d10:	f022                	sd	s0,32(sp)
    80003d12:	ec26                	sd	s1,24(sp)
    80003d14:	e84a                	sd	s2,16(sp)
    80003d16:	e44e                	sd	s3,8(sp)
    80003d18:	e052                	sd	s4,0(sp)
    80003d1a:	1800                	addi	s0,sp,48
    80003d1c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d1e:	05050493          	addi	s1,a0,80
    80003d22:	08050913          	addi	s2,a0,128
    80003d26:	a021                	j	80003d2e <itrunc+0x22>
    80003d28:	0491                	addi	s1,s1,4
    80003d2a:	01248d63          	beq	s1,s2,80003d44 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d2e:	408c                	lw	a1,0(s1)
    80003d30:	dde5                	beqz	a1,80003d28 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d32:	0009a503          	lw	a0,0(s3)
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	90a080e7          	jalr	-1782(ra) # 80003640 <bfree>
      ip->addrs[i] = 0;
    80003d3e:	0004a023          	sw	zero,0(s1)
    80003d42:	b7dd                	j	80003d28 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d44:	0809a583          	lw	a1,128(s3)
    80003d48:	e185                	bnez	a1,80003d68 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d4a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d4e:	854e                	mv	a0,s3
    80003d50:	00000097          	auipc	ra,0x0
    80003d54:	de4080e7          	jalr	-540(ra) # 80003b34 <iupdate>
}
    80003d58:	70a2                	ld	ra,40(sp)
    80003d5a:	7402                	ld	s0,32(sp)
    80003d5c:	64e2                	ld	s1,24(sp)
    80003d5e:	6942                	ld	s2,16(sp)
    80003d60:	69a2                	ld	s3,8(sp)
    80003d62:	6a02                	ld	s4,0(sp)
    80003d64:	6145                	addi	sp,sp,48
    80003d66:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d68:	0009a503          	lw	a0,0(s3)
    80003d6c:	fffff097          	auipc	ra,0xfffff
    80003d70:	68e080e7          	jalr	1678(ra) # 800033fa <bread>
    80003d74:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d76:	05850493          	addi	s1,a0,88
    80003d7a:	45850913          	addi	s2,a0,1112
    80003d7e:	a021                	j	80003d86 <itrunc+0x7a>
    80003d80:	0491                	addi	s1,s1,4
    80003d82:	01248b63          	beq	s1,s2,80003d98 <itrunc+0x8c>
      if(a[j])
    80003d86:	408c                	lw	a1,0(s1)
    80003d88:	dde5                	beqz	a1,80003d80 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d8a:	0009a503          	lw	a0,0(s3)
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	8b2080e7          	jalr	-1870(ra) # 80003640 <bfree>
    80003d96:	b7ed                	j	80003d80 <itrunc+0x74>
    brelse(bp);
    80003d98:	8552                	mv	a0,s4
    80003d9a:	fffff097          	auipc	ra,0xfffff
    80003d9e:	790080e7          	jalr	1936(ra) # 8000352a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003da2:	0809a583          	lw	a1,128(s3)
    80003da6:	0009a503          	lw	a0,0(s3)
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	896080e7          	jalr	-1898(ra) # 80003640 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003db2:	0809a023          	sw	zero,128(s3)
    80003db6:	bf51                	j	80003d4a <itrunc+0x3e>

0000000080003db8 <iput>:
{
    80003db8:	1101                	addi	sp,sp,-32
    80003dba:	ec06                	sd	ra,24(sp)
    80003dbc:	e822                	sd	s0,16(sp)
    80003dbe:	e426                	sd	s1,8(sp)
    80003dc0:	e04a                	sd	s2,0(sp)
    80003dc2:	1000                	addi	s0,sp,32
    80003dc4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dc6:	00022517          	auipc	a0,0x22
    80003dca:	00250513          	addi	a0,a0,2 # 80025dc8 <itable>
    80003dce:	ffffd097          	auipc	ra,0xffffd
    80003dd2:	df4080e7          	jalr	-524(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dd6:	4498                	lw	a4,8(s1)
    80003dd8:	4785                	li	a5,1
    80003dda:	02f70363          	beq	a4,a5,80003e00 <iput+0x48>
  ip->ref--;
    80003dde:	449c                	lw	a5,8(s1)
    80003de0:	37fd                	addiw	a5,a5,-1
    80003de2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003de4:	00022517          	auipc	a0,0x22
    80003de8:	fe450513          	addi	a0,a0,-28 # 80025dc8 <itable>
    80003dec:	ffffd097          	auipc	ra,0xffffd
    80003df0:	e8a080e7          	jalr	-374(ra) # 80000c76 <release>
}
    80003df4:	60e2                	ld	ra,24(sp)
    80003df6:	6442                	ld	s0,16(sp)
    80003df8:	64a2                	ld	s1,8(sp)
    80003dfa:	6902                	ld	s2,0(sp)
    80003dfc:	6105                	addi	sp,sp,32
    80003dfe:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e00:	40bc                	lw	a5,64(s1)
    80003e02:	dff1                	beqz	a5,80003dde <iput+0x26>
    80003e04:	04a49783          	lh	a5,74(s1)
    80003e08:	fbf9                	bnez	a5,80003dde <iput+0x26>
    acquiresleep(&ip->lock);
    80003e0a:	01048913          	addi	s2,s1,16
    80003e0e:	854a                	mv	a0,s2
    80003e10:	00001097          	auipc	ra,0x1
    80003e14:	abc080e7          	jalr	-1348(ra) # 800048cc <acquiresleep>
    release(&itable.lock);
    80003e18:	00022517          	auipc	a0,0x22
    80003e1c:	fb050513          	addi	a0,a0,-80 # 80025dc8 <itable>
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	e56080e7          	jalr	-426(ra) # 80000c76 <release>
    itrunc(ip);
    80003e28:	8526                	mv	a0,s1
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	ee2080e7          	jalr	-286(ra) # 80003d0c <itrunc>
    ip->type = 0;
    80003e32:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e36:	8526                	mv	a0,s1
    80003e38:	00000097          	auipc	ra,0x0
    80003e3c:	cfc080e7          	jalr	-772(ra) # 80003b34 <iupdate>
    ip->valid = 0;
    80003e40:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e44:	854a                	mv	a0,s2
    80003e46:	00001097          	auipc	ra,0x1
    80003e4a:	adc080e7          	jalr	-1316(ra) # 80004922 <releasesleep>
    acquire(&itable.lock);
    80003e4e:	00022517          	auipc	a0,0x22
    80003e52:	f7a50513          	addi	a0,a0,-134 # 80025dc8 <itable>
    80003e56:	ffffd097          	auipc	ra,0xffffd
    80003e5a:	d6c080e7          	jalr	-660(ra) # 80000bc2 <acquire>
    80003e5e:	b741                	j	80003dde <iput+0x26>

0000000080003e60 <iunlockput>:
{
    80003e60:	1101                	addi	sp,sp,-32
    80003e62:	ec06                	sd	ra,24(sp)
    80003e64:	e822                	sd	s0,16(sp)
    80003e66:	e426                	sd	s1,8(sp)
    80003e68:	1000                	addi	s0,sp,32
    80003e6a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	e54080e7          	jalr	-428(ra) # 80003cc0 <iunlock>
  iput(ip);
    80003e74:	8526                	mv	a0,s1
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	f42080e7          	jalr	-190(ra) # 80003db8 <iput>
}
    80003e7e:	60e2                	ld	ra,24(sp)
    80003e80:	6442                	ld	s0,16(sp)
    80003e82:	64a2                	ld	s1,8(sp)
    80003e84:	6105                	addi	sp,sp,32
    80003e86:	8082                	ret

0000000080003e88 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e88:	1141                	addi	sp,sp,-16
    80003e8a:	e422                	sd	s0,8(sp)
    80003e8c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e8e:	411c                	lw	a5,0(a0)
    80003e90:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e92:	415c                	lw	a5,4(a0)
    80003e94:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e96:	04451783          	lh	a5,68(a0)
    80003e9a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e9e:	04a51783          	lh	a5,74(a0)
    80003ea2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ea6:	04c56783          	lwu	a5,76(a0)
    80003eaa:	e99c                	sd	a5,16(a1)
}
    80003eac:	6422                	ld	s0,8(sp)
    80003eae:	0141                	addi	sp,sp,16
    80003eb0:	8082                	ret

0000000080003eb2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eb2:	457c                	lw	a5,76(a0)
    80003eb4:	0ed7e963          	bltu	a5,a3,80003fa6 <readi+0xf4>
{
    80003eb8:	7159                	addi	sp,sp,-112
    80003eba:	f486                	sd	ra,104(sp)
    80003ebc:	f0a2                	sd	s0,96(sp)
    80003ebe:	eca6                	sd	s1,88(sp)
    80003ec0:	e8ca                	sd	s2,80(sp)
    80003ec2:	e4ce                	sd	s3,72(sp)
    80003ec4:	e0d2                	sd	s4,64(sp)
    80003ec6:	fc56                	sd	s5,56(sp)
    80003ec8:	f85a                	sd	s6,48(sp)
    80003eca:	f45e                	sd	s7,40(sp)
    80003ecc:	f062                	sd	s8,32(sp)
    80003ece:	ec66                	sd	s9,24(sp)
    80003ed0:	e86a                	sd	s10,16(sp)
    80003ed2:	e46e                	sd	s11,8(sp)
    80003ed4:	1880                	addi	s0,sp,112
    80003ed6:	8baa                	mv	s7,a0
    80003ed8:	8c2e                	mv	s8,a1
    80003eda:	8ab2                	mv	s5,a2
    80003edc:	84b6                	mv	s1,a3
    80003ede:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ee0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ee2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ee4:	0ad76063          	bltu	a4,a3,80003f84 <readi+0xd2>
  if(off + n > ip->size)
    80003ee8:	00e7f463          	bgeu	a5,a4,80003ef0 <readi+0x3e>
    n = ip->size - off;
    80003eec:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ef0:	0a0b0963          	beqz	s6,80003fa2 <readi+0xf0>
    80003ef4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003efa:	5cfd                	li	s9,-1
    80003efc:	a82d                	j	80003f36 <readi+0x84>
    80003efe:	020a1d93          	slli	s11,s4,0x20
    80003f02:	020ddd93          	srli	s11,s11,0x20
    80003f06:	05890793          	addi	a5,s2,88
    80003f0a:	86ee                	mv	a3,s11
    80003f0c:	963e                	add	a2,a2,a5
    80003f0e:	85d6                	mv	a1,s5
    80003f10:	8562                	mv	a0,s8
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	82a080e7          	jalr	-2006(ra) # 8000273c <either_copyout>
    80003f1a:	05950d63          	beq	a0,s9,80003f74 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f1e:	854a                	mv	a0,s2
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	60a080e7          	jalr	1546(ra) # 8000352a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f28:	013a09bb          	addw	s3,s4,s3
    80003f2c:	009a04bb          	addw	s1,s4,s1
    80003f30:	9aee                	add	s5,s5,s11
    80003f32:	0569f763          	bgeu	s3,s6,80003f80 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f36:	000ba903          	lw	s2,0(s7)
    80003f3a:	00a4d59b          	srliw	a1,s1,0xa
    80003f3e:	855e                	mv	a0,s7
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	8ae080e7          	jalr	-1874(ra) # 800037ee <bmap>
    80003f48:	0005059b          	sext.w	a1,a0
    80003f4c:	854a                	mv	a0,s2
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	4ac080e7          	jalr	1196(ra) # 800033fa <bread>
    80003f56:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f58:	3ff4f613          	andi	a2,s1,1023
    80003f5c:	40cd07bb          	subw	a5,s10,a2
    80003f60:	413b073b          	subw	a4,s6,s3
    80003f64:	8a3e                	mv	s4,a5
    80003f66:	2781                	sext.w	a5,a5
    80003f68:	0007069b          	sext.w	a3,a4
    80003f6c:	f8f6f9e3          	bgeu	a3,a5,80003efe <readi+0x4c>
    80003f70:	8a3a                	mv	s4,a4
    80003f72:	b771                	j	80003efe <readi+0x4c>
      brelse(bp);
    80003f74:	854a                	mv	a0,s2
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	5b4080e7          	jalr	1460(ra) # 8000352a <brelse>
      tot = -1;
    80003f7e:	59fd                	li	s3,-1
  }
  return tot;
    80003f80:	0009851b          	sext.w	a0,s3
}
    80003f84:	70a6                	ld	ra,104(sp)
    80003f86:	7406                	ld	s0,96(sp)
    80003f88:	64e6                	ld	s1,88(sp)
    80003f8a:	6946                	ld	s2,80(sp)
    80003f8c:	69a6                	ld	s3,72(sp)
    80003f8e:	6a06                	ld	s4,64(sp)
    80003f90:	7ae2                	ld	s5,56(sp)
    80003f92:	7b42                	ld	s6,48(sp)
    80003f94:	7ba2                	ld	s7,40(sp)
    80003f96:	7c02                	ld	s8,32(sp)
    80003f98:	6ce2                	ld	s9,24(sp)
    80003f9a:	6d42                	ld	s10,16(sp)
    80003f9c:	6da2                	ld	s11,8(sp)
    80003f9e:	6165                	addi	sp,sp,112
    80003fa0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fa2:	89da                	mv	s3,s6
    80003fa4:	bff1                	j	80003f80 <readi+0xce>
    return 0;
    80003fa6:	4501                	li	a0,0
}
    80003fa8:	8082                	ret

0000000080003faa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003faa:	457c                	lw	a5,76(a0)
    80003fac:	10d7e863          	bltu	a5,a3,800040bc <writei+0x112>
{
    80003fb0:	7159                	addi	sp,sp,-112
    80003fb2:	f486                	sd	ra,104(sp)
    80003fb4:	f0a2                	sd	s0,96(sp)
    80003fb6:	eca6                	sd	s1,88(sp)
    80003fb8:	e8ca                	sd	s2,80(sp)
    80003fba:	e4ce                	sd	s3,72(sp)
    80003fbc:	e0d2                	sd	s4,64(sp)
    80003fbe:	fc56                	sd	s5,56(sp)
    80003fc0:	f85a                	sd	s6,48(sp)
    80003fc2:	f45e                	sd	s7,40(sp)
    80003fc4:	f062                	sd	s8,32(sp)
    80003fc6:	ec66                	sd	s9,24(sp)
    80003fc8:	e86a                	sd	s10,16(sp)
    80003fca:	e46e                	sd	s11,8(sp)
    80003fcc:	1880                	addi	s0,sp,112
    80003fce:	8b2a                	mv	s6,a0
    80003fd0:	8c2e                	mv	s8,a1
    80003fd2:	8ab2                	mv	s5,a2
    80003fd4:	8936                	mv	s2,a3
    80003fd6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003fd8:	00e687bb          	addw	a5,a3,a4
    80003fdc:	0ed7e263          	bltu	a5,a3,800040c0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fe0:	00043737          	lui	a4,0x43
    80003fe4:	0ef76063          	bltu	a4,a5,800040c4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fe8:	0c0b8863          	beqz	s7,800040b8 <writei+0x10e>
    80003fec:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fee:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ff2:	5cfd                	li	s9,-1
    80003ff4:	a091                	j	80004038 <writei+0x8e>
    80003ff6:	02099d93          	slli	s11,s3,0x20
    80003ffa:	020ddd93          	srli	s11,s11,0x20
    80003ffe:	05848793          	addi	a5,s1,88
    80004002:	86ee                	mv	a3,s11
    80004004:	8656                	mv	a2,s5
    80004006:	85e2                	mv	a1,s8
    80004008:	953e                	add	a0,a0,a5
    8000400a:	ffffe097          	auipc	ra,0xffffe
    8000400e:	78a080e7          	jalr	1930(ra) # 80002794 <either_copyin>
    80004012:	07950263          	beq	a0,s9,80004076 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004016:	8526                	mv	a0,s1
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	794080e7          	jalr	1940(ra) # 800047ac <log_write>
    brelse(bp);
    80004020:	8526                	mv	a0,s1
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	508080e7          	jalr	1288(ra) # 8000352a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000402a:	01498a3b          	addw	s4,s3,s4
    8000402e:	0129893b          	addw	s2,s3,s2
    80004032:	9aee                	add	s5,s5,s11
    80004034:	057a7663          	bgeu	s4,s7,80004080 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004038:	000b2483          	lw	s1,0(s6)
    8000403c:	00a9559b          	srliw	a1,s2,0xa
    80004040:	855a                	mv	a0,s6
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	7ac080e7          	jalr	1964(ra) # 800037ee <bmap>
    8000404a:	0005059b          	sext.w	a1,a0
    8000404e:	8526                	mv	a0,s1
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	3aa080e7          	jalr	938(ra) # 800033fa <bread>
    80004058:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000405a:	3ff97513          	andi	a0,s2,1023
    8000405e:	40ad07bb          	subw	a5,s10,a0
    80004062:	414b873b          	subw	a4,s7,s4
    80004066:	89be                	mv	s3,a5
    80004068:	2781                	sext.w	a5,a5
    8000406a:	0007069b          	sext.w	a3,a4
    8000406e:	f8f6f4e3          	bgeu	a3,a5,80003ff6 <writei+0x4c>
    80004072:	89ba                	mv	s3,a4
    80004074:	b749                	j	80003ff6 <writei+0x4c>
      brelse(bp);
    80004076:	8526                	mv	a0,s1
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	4b2080e7          	jalr	1202(ra) # 8000352a <brelse>
  }

  if(off > ip->size)
    80004080:	04cb2783          	lw	a5,76(s6)
    80004084:	0127f463          	bgeu	a5,s2,8000408c <writei+0xe2>
    ip->size = off;
    80004088:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000408c:	855a                	mv	a0,s6
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	aa6080e7          	jalr	-1370(ra) # 80003b34 <iupdate>

  return tot;
    80004096:	000a051b          	sext.w	a0,s4
}
    8000409a:	70a6                	ld	ra,104(sp)
    8000409c:	7406                	ld	s0,96(sp)
    8000409e:	64e6                	ld	s1,88(sp)
    800040a0:	6946                	ld	s2,80(sp)
    800040a2:	69a6                	ld	s3,72(sp)
    800040a4:	6a06                	ld	s4,64(sp)
    800040a6:	7ae2                	ld	s5,56(sp)
    800040a8:	7b42                	ld	s6,48(sp)
    800040aa:	7ba2                	ld	s7,40(sp)
    800040ac:	7c02                	ld	s8,32(sp)
    800040ae:	6ce2                	ld	s9,24(sp)
    800040b0:	6d42                	ld	s10,16(sp)
    800040b2:	6da2                	ld	s11,8(sp)
    800040b4:	6165                	addi	sp,sp,112
    800040b6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040b8:	8a5e                	mv	s4,s7
    800040ba:	bfc9                	j	8000408c <writei+0xe2>
    return -1;
    800040bc:	557d                	li	a0,-1
}
    800040be:	8082                	ret
    return -1;
    800040c0:	557d                	li	a0,-1
    800040c2:	bfe1                	j	8000409a <writei+0xf0>
    return -1;
    800040c4:	557d                	li	a0,-1
    800040c6:	bfd1                	j	8000409a <writei+0xf0>

00000000800040c8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040c8:	1141                	addi	sp,sp,-16
    800040ca:	e406                	sd	ra,8(sp)
    800040cc:	e022                	sd	s0,0(sp)
    800040ce:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040d0:	4639                	li	a2,14
    800040d2:	ffffd097          	auipc	ra,0xffffd
    800040d6:	cc4080e7          	jalr	-828(ra) # 80000d96 <strncmp>
}
    800040da:	60a2                	ld	ra,8(sp)
    800040dc:	6402                	ld	s0,0(sp)
    800040de:	0141                	addi	sp,sp,16
    800040e0:	8082                	ret

00000000800040e2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040e2:	7139                	addi	sp,sp,-64
    800040e4:	fc06                	sd	ra,56(sp)
    800040e6:	f822                	sd	s0,48(sp)
    800040e8:	f426                	sd	s1,40(sp)
    800040ea:	f04a                	sd	s2,32(sp)
    800040ec:	ec4e                	sd	s3,24(sp)
    800040ee:	e852                	sd	s4,16(sp)
    800040f0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040f2:	04451703          	lh	a4,68(a0)
    800040f6:	4785                	li	a5,1
    800040f8:	00f71a63          	bne	a4,a5,8000410c <dirlookup+0x2a>
    800040fc:	892a                	mv	s2,a0
    800040fe:	89ae                	mv	s3,a1
    80004100:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004102:	457c                	lw	a5,76(a0)
    80004104:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004106:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004108:	e79d                	bnez	a5,80004136 <dirlookup+0x54>
    8000410a:	a8a5                	j	80004182 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000410c:	00004517          	auipc	a0,0x4
    80004110:	4dc50513          	addi	a0,a0,1244 # 800085e8 <syscalls+0x1b8>
    80004114:	ffffc097          	auipc	ra,0xffffc
    80004118:	416080e7          	jalr	1046(ra) # 8000052a <panic>
      panic("dirlookup read");
    8000411c:	00004517          	auipc	a0,0x4
    80004120:	4e450513          	addi	a0,a0,1252 # 80008600 <syscalls+0x1d0>
    80004124:	ffffc097          	auipc	ra,0xffffc
    80004128:	406080e7          	jalr	1030(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000412c:	24c1                	addiw	s1,s1,16
    8000412e:	04c92783          	lw	a5,76(s2)
    80004132:	04f4f763          	bgeu	s1,a5,80004180 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004136:	4741                	li	a4,16
    80004138:	86a6                	mv	a3,s1
    8000413a:	fc040613          	addi	a2,s0,-64
    8000413e:	4581                	li	a1,0
    80004140:	854a                	mv	a0,s2
    80004142:	00000097          	auipc	ra,0x0
    80004146:	d70080e7          	jalr	-656(ra) # 80003eb2 <readi>
    8000414a:	47c1                	li	a5,16
    8000414c:	fcf518e3          	bne	a0,a5,8000411c <dirlookup+0x3a>
    if(de.inum == 0)
    80004150:	fc045783          	lhu	a5,-64(s0)
    80004154:	dfe1                	beqz	a5,8000412c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004156:	fc240593          	addi	a1,s0,-62
    8000415a:	854e                	mv	a0,s3
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	f6c080e7          	jalr	-148(ra) # 800040c8 <namecmp>
    80004164:	f561                	bnez	a0,8000412c <dirlookup+0x4a>
      if(poff)
    80004166:	000a0463          	beqz	s4,8000416e <dirlookup+0x8c>
        *poff = off;
    8000416a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000416e:	fc045583          	lhu	a1,-64(s0)
    80004172:	00092503          	lw	a0,0(s2)
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	754080e7          	jalr	1876(ra) # 800038ca <iget>
    8000417e:	a011                	j	80004182 <dirlookup+0xa0>
  return 0;
    80004180:	4501                	li	a0,0
}
    80004182:	70e2                	ld	ra,56(sp)
    80004184:	7442                	ld	s0,48(sp)
    80004186:	74a2                	ld	s1,40(sp)
    80004188:	7902                	ld	s2,32(sp)
    8000418a:	69e2                	ld	s3,24(sp)
    8000418c:	6a42                	ld	s4,16(sp)
    8000418e:	6121                	addi	sp,sp,64
    80004190:	8082                	ret

0000000080004192 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004192:	711d                	addi	sp,sp,-96
    80004194:	ec86                	sd	ra,88(sp)
    80004196:	e8a2                	sd	s0,80(sp)
    80004198:	e4a6                	sd	s1,72(sp)
    8000419a:	e0ca                	sd	s2,64(sp)
    8000419c:	fc4e                	sd	s3,56(sp)
    8000419e:	f852                	sd	s4,48(sp)
    800041a0:	f456                	sd	s5,40(sp)
    800041a2:	f05a                	sd	s6,32(sp)
    800041a4:	ec5e                	sd	s7,24(sp)
    800041a6:	e862                	sd	s8,16(sp)
    800041a8:	e466                	sd	s9,8(sp)
    800041aa:	1080                	addi	s0,sp,96
    800041ac:	84aa                	mv	s1,a0
    800041ae:	8aae                	mv	s5,a1
    800041b0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041b2:	00054703          	lbu	a4,0(a0)
    800041b6:	02f00793          	li	a5,47
    800041ba:	02f70363          	beq	a4,a5,800041e0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	7c2080e7          	jalr	1986(ra) # 80001980 <myproc>
    800041c6:	2e853503          	ld	a0,744(a0)
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	9f6080e7          	jalr	-1546(ra) # 80003bc0 <idup>
    800041d2:	89aa                	mv	s3,a0
  while(*path == '/')
    800041d4:	02f00913          	li	s2,47
  len = path - s;
    800041d8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800041da:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041dc:	4b85                	li	s7,1
    800041de:	a865                	j	80004296 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041e0:	4585                	li	a1,1
    800041e2:	4505                	li	a0,1
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	6e6080e7          	jalr	1766(ra) # 800038ca <iget>
    800041ec:	89aa                	mv	s3,a0
    800041ee:	b7dd                	j	800041d4 <namex+0x42>
      iunlockput(ip);
    800041f0:	854e                	mv	a0,s3
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	c6e080e7          	jalr	-914(ra) # 80003e60 <iunlockput>
      return 0;
    800041fa:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041fc:	854e                	mv	a0,s3
    800041fe:	60e6                	ld	ra,88(sp)
    80004200:	6446                	ld	s0,80(sp)
    80004202:	64a6                	ld	s1,72(sp)
    80004204:	6906                	ld	s2,64(sp)
    80004206:	79e2                	ld	s3,56(sp)
    80004208:	7a42                	ld	s4,48(sp)
    8000420a:	7aa2                	ld	s5,40(sp)
    8000420c:	7b02                	ld	s6,32(sp)
    8000420e:	6be2                	ld	s7,24(sp)
    80004210:	6c42                	ld	s8,16(sp)
    80004212:	6ca2                	ld	s9,8(sp)
    80004214:	6125                	addi	sp,sp,96
    80004216:	8082                	ret
      iunlock(ip);
    80004218:	854e                	mv	a0,s3
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	aa6080e7          	jalr	-1370(ra) # 80003cc0 <iunlock>
      return ip;
    80004222:	bfe9                	j	800041fc <namex+0x6a>
      iunlockput(ip);
    80004224:	854e                	mv	a0,s3
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	c3a080e7          	jalr	-966(ra) # 80003e60 <iunlockput>
      return 0;
    8000422e:	89e6                	mv	s3,s9
    80004230:	b7f1                	j	800041fc <namex+0x6a>
  len = path - s;
    80004232:	40b48633          	sub	a2,s1,a1
    80004236:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000423a:	099c5463          	bge	s8,s9,800042c2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000423e:	4639                	li	a2,14
    80004240:	8552                	mv	a0,s4
    80004242:	ffffd097          	auipc	ra,0xffffd
    80004246:	ad8080e7          	jalr	-1320(ra) # 80000d1a <memmove>
  while(*path == '/')
    8000424a:	0004c783          	lbu	a5,0(s1)
    8000424e:	01279763          	bne	a5,s2,8000425c <namex+0xca>
    path++;
    80004252:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004254:	0004c783          	lbu	a5,0(s1)
    80004258:	ff278de3          	beq	a5,s2,80004252 <namex+0xc0>
    ilock(ip);
    8000425c:	854e                	mv	a0,s3
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	9a0080e7          	jalr	-1632(ra) # 80003bfe <ilock>
    if(ip->type != T_DIR){
    80004266:	04499783          	lh	a5,68(s3)
    8000426a:	f97793e3          	bne	a5,s7,800041f0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000426e:	000a8563          	beqz	s5,80004278 <namex+0xe6>
    80004272:	0004c783          	lbu	a5,0(s1)
    80004276:	d3cd                	beqz	a5,80004218 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004278:	865a                	mv	a2,s6
    8000427a:	85d2                	mv	a1,s4
    8000427c:	854e                	mv	a0,s3
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	e64080e7          	jalr	-412(ra) # 800040e2 <dirlookup>
    80004286:	8caa                	mv	s9,a0
    80004288:	dd51                	beqz	a0,80004224 <namex+0x92>
    iunlockput(ip);
    8000428a:	854e                	mv	a0,s3
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	bd4080e7          	jalr	-1068(ra) # 80003e60 <iunlockput>
    ip = next;
    80004294:	89e6                	mv	s3,s9
  while(*path == '/')
    80004296:	0004c783          	lbu	a5,0(s1)
    8000429a:	05279763          	bne	a5,s2,800042e8 <namex+0x156>
    path++;
    8000429e:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042a0:	0004c783          	lbu	a5,0(s1)
    800042a4:	ff278de3          	beq	a5,s2,8000429e <namex+0x10c>
  if(*path == 0)
    800042a8:	c79d                	beqz	a5,800042d6 <namex+0x144>
    path++;
    800042aa:	85a6                	mv	a1,s1
  len = path - s;
    800042ac:	8cda                	mv	s9,s6
    800042ae:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800042b0:	01278963          	beq	a5,s2,800042c2 <namex+0x130>
    800042b4:	dfbd                	beqz	a5,80004232 <namex+0xa0>
    path++;
    800042b6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042b8:	0004c783          	lbu	a5,0(s1)
    800042bc:	ff279ce3          	bne	a5,s2,800042b4 <namex+0x122>
    800042c0:	bf8d                	j	80004232 <namex+0xa0>
    memmove(name, s, len);
    800042c2:	2601                	sext.w	a2,a2
    800042c4:	8552                	mv	a0,s4
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	a54080e7          	jalr	-1452(ra) # 80000d1a <memmove>
    name[len] = 0;
    800042ce:	9cd2                	add	s9,s9,s4
    800042d0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800042d4:	bf9d                	j	8000424a <namex+0xb8>
  if(nameiparent){
    800042d6:	f20a83e3          	beqz	s5,800041fc <namex+0x6a>
    iput(ip);
    800042da:	854e                	mv	a0,s3
    800042dc:	00000097          	auipc	ra,0x0
    800042e0:	adc080e7          	jalr	-1316(ra) # 80003db8 <iput>
    return 0;
    800042e4:	4981                	li	s3,0
    800042e6:	bf19                	j	800041fc <namex+0x6a>
  if(*path == 0)
    800042e8:	d7fd                	beqz	a5,800042d6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042ea:	0004c783          	lbu	a5,0(s1)
    800042ee:	85a6                	mv	a1,s1
    800042f0:	b7d1                	j	800042b4 <namex+0x122>

00000000800042f2 <dirlink>:
{
    800042f2:	7139                	addi	sp,sp,-64
    800042f4:	fc06                	sd	ra,56(sp)
    800042f6:	f822                	sd	s0,48(sp)
    800042f8:	f426                	sd	s1,40(sp)
    800042fa:	f04a                	sd	s2,32(sp)
    800042fc:	ec4e                	sd	s3,24(sp)
    800042fe:	e852                	sd	s4,16(sp)
    80004300:	0080                	addi	s0,sp,64
    80004302:	892a                	mv	s2,a0
    80004304:	8a2e                	mv	s4,a1
    80004306:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004308:	4601                	li	a2,0
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	dd8080e7          	jalr	-552(ra) # 800040e2 <dirlookup>
    80004312:	e93d                	bnez	a0,80004388 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004314:	04c92483          	lw	s1,76(s2)
    80004318:	c49d                	beqz	s1,80004346 <dirlink+0x54>
    8000431a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000431c:	4741                	li	a4,16
    8000431e:	86a6                	mv	a3,s1
    80004320:	fc040613          	addi	a2,s0,-64
    80004324:	4581                	li	a1,0
    80004326:	854a                	mv	a0,s2
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	b8a080e7          	jalr	-1142(ra) # 80003eb2 <readi>
    80004330:	47c1                	li	a5,16
    80004332:	06f51163          	bne	a0,a5,80004394 <dirlink+0xa2>
    if(de.inum == 0)
    80004336:	fc045783          	lhu	a5,-64(s0)
    8000433a:	c791                	beqz	a5,80004346 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000433c:	24c1                	addiw	s1,s1,16
    8000433e:	04c92783          	lw	a5,76(s2)
    80004342:	fcf4ede3          	bltu	s1,a5,8000431c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004346:	4639                	li	a2,14
    80004348:	85d2                	mv	a1,s4
    8000434a:	fc240513          	addi	a0,s0,-62
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	a84080e7          	jalr	-1404(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004356:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000435a:	4741                	li	a4,16
    8000435c:	86a6                	mv	a3,s1
    8000435e:	fc040613          	addi	a2,s0,-64
    80004362:	4581                	li	a1,0
    80004364:	854a                	mv	a0,s2
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	c44080e7          	jalr	-956(ra) # 80003faa <writei>
    8000436e:	872a                	mv	a4,a0
    80004370:	47c1                	li	a5,16
  return 0;
    80004372:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004374:	02f71863          	bne	a4,a5,800043a4 <dirlink+0xb2>
}
    80004378:	70e2                	ld	ra,56(sp)
    8000437a:	7442                	ld	s0,48(sp)
    8000437c:	74a2                	ld	s1,40(sp)
    8000437e:	7902                	ld	s2,32(sp)
    80004380:	69e2                	ld	s3,24(sp)
    80004382:	6a42                	ld	s4,16(sp)
    80004384:	6121                	addi	sp,sp,64
    80004386:	8082                	ret
    iput(ip);
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	a30080e7          	jalr	-1488(ra) # 80003db8 <iput>
    return -1;
    80004390:	557d                	li	a0,-1
    80004392:	b7dd                	j	80004378 <dirlink+0x86>
      panic("dirlink read");
    80004394:	00004517          	auipc	a0,0x4
    80004398:	27c50513          	addi	a0,a0,636 # 80008610 <syscalls+0x1e0>
    8000439c:	ffffc097          	auipc	ra,0xffffc
    800043a0:	18e080e7          	jalr	398(ra) # 8000052a <panic>
    panic("dirlink");
    800043a4:	00004517          	auipc	a0,0x4
    800043a8:	37c50513          	addi	a0,a0,892 # 80008720 <syscalls+0x2f0>
    800043ac:	ffffc097          	auipc	ra,0xffffc
    800043b0:	17e080e7          	jalr	382(ra) # 8000052a <panic>

00000000800043b4 <namei>:

struct inode*
namei(char *path)
{
    800043b4:	1101                	addi	sp,sp,-32
    800043b6:	ec06                	sd	ra,24(sp)
    800043b8:	e822                	sd	s0,16(sp)
    800043ba:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043bc:	fe040613          	addi	a2,s0,-32
    800043c0:	4581                	li	a1,0
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	dd0080e7          	jalr	-560(ra) # 80004192 <namex>
}
    800043ca:	60e2                	ld	ra,24(sp)
    800043cc:	6442                	ld	s0,16(sp)
    800043ce:	6105                	addi	sp,sp,32
    800043d0:	8082                	ret

00000000800043d2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043d2:	1141                	addi	sp,sp,-16
    800043d4:	e406                	sd	ra,8(sp)
    800043d6:	e022                	sd	s0,0(sp)
    800043d8:	0800                	addi	s0,sp,16
    800043da:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043dc:	4585                	li	a1,1
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	db4080e7          	jalr	-588(ra) # 80004192 <namex>
}
    800043e6:	60a2                	ld	ra,8(sp)
    800043e8:	6402                	ld	s0,0(sp)
    800043ea:	0141                	addi	sp,sp,16
    800043ec:	8082                	ret

00000000800043ee <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043ee:	1101                	addi	sp,sp,-32
    800043f0:	ec06                	sd	ra,24(sp)
    800043f2:	e822                	sd	s0,16(sp)
    800043f4:	e426                	sd	s1,8(sp)
    800043f6:	e04a                	sd	s2,0(sp)
    800043f8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043fa:	00023917          	auipc	s2,0x23
    800043fe:	47690913          	addi	s2,s2,1142 # 80027870 <log>
    80004402:	01892583          	lw	a1,24(s2)
    80004406:	02892503          	lw	a0,40(s2)
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	ff0080e7          	jalr	-16(ra) # 800033fa <bread>
    80004412:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004414:	02c92683          	lw	a3,44(s2)
    80004418:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000441a:	02d05863          	blez	a3,8000444a <write_head+0x5c>
    8000441e:	00023797          	auipc	a5,0x23
    80004422:	48278793          	addi	a5,a5,1154 # 800278a0 <log+0x30>
    80004426:	05c50713          	addi	a4,a0,92
    8000442a:	36fd                	addiw	a3,a3,-1
    8000442c:	02069613          	slli	a2,a3,0x20
    80004430:	01e65693          	srli	a3,a2,0x1e
    80004434:	00023617          	auipc	a2,0x23
    80004438:	47060613          	addi	a2,a2,1136 # 800278a4 <log+0x34>
    8000443c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000443e:	4390                	lw	a2,0(a5)
    80004440:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004442:	0791                	addi	a5,a5,4
    80004444:	0711                	addi	a4,a4,4
    80004446:	fed79ce3          	bne	a5,a3,8000443e <write_head+0x50>
  }
  bwrite(buf);
    8000444a:	8526                	mv	a0,s1
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	0a0080e7          	jalr	160(ra) # 800034ec <bwrite>
  brelse(buf);
    80004454:	8526                	mv	a0,s1
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	0d4080e7          	jalr	212(ra) # 8000352a <brelse>
}
    8000445e:	60e2                	ld	ra,24(sp)
    80004460:	6442                	ld	s0,16(sp)
    80004462:	64a2                	ld	s1,8(sp)
    80004464:	6902                	ld	s2,0(sp)
    80004466:	6105                	addi	sp,sp,32
    80004468:	8082                	ret

000000008000446a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000446a:	00023797          	auipc	a5,0x23
    8000446e:	4327a783          	lw	a5,1074(a5) # 8002789c <log+0x2c>
    80004472:	0af05d63          	blez	a5,8000452c <install_trans+0xc2>
{
    80004476:	7139                	addi	sp,sp,-64
    80004478:	fc06                	sd	ra,56(sp)
    8000447a:	f822                	sd	s0,48(sp)
    8000447c:	f426                	sd	s1,40(sp)
    8000447e:	f04a                	sd	s2,32(sp)
    80004480:	ec4e                	sd	s3,24(sp)
    80004482:	e852                	sd	s4,16(sp)
    80004484:	e456                	sd	s5,8(sp)
    80004486:	e05a                	sd	s6,0(sp)
    80004488:	0080                	addi	s0,sp,64
    8000448a:	8b2a                	mv	s6,a0
    8000448c:	00023a97          	auipc	s5,0x23
    80004490:	414a8a93          	addi	s5,s5,1044 # 800278a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004494:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004496:	00023997          	auipc	s3,0x23
    8000449a:	3da98993          	addi	s3,s3,986 # 80027870 <log>
    8000449e:	a00d                	j	800044c0 <install_trans+0x56>
    brelse(lbuf);
    800044a0:	854a                	mv	a0,s2
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	088080e7          	jalr	136(ra) # 8000352a <brelse>
    brelse(dbuf);
    800044aa:	8526                	mv	a0,s1
    800044ac:	fffff097          	auipc	ra,0xfffff
    800044b0:	07e080e7          	jalr	126(ra) # 8000352a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b4:	2a05                	addiw	s4,s4,1
    800044b6:	0a91                	addi	s5,s5,4
    800044b8:	02c9a783          	lw	a5,44(s3)
    800044bc:	04fa5e63          	bge	s4,a5,80004518 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044c0:	0189a583          	lw	a1,24(s3)
    800044c4:	014585bb          	addw	a1,a1,s4
    800044c8:	2585                	addiw	a1,a1,1
    800044ca:	0289a503          	lw	a0,40(s3)
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	f2c080e7          	jalr	-212(ra) # 800033fa <bread>
    800044d6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044d8:	000aa583          	lw	a1,0(s5)
    800044dc:	0289a503          	lw	a0,40(s3)
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	f1a080e7          	jalr	-230(ra) # 800033fa <bread>
    800044e8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044ea:	40000613          	li	a2,1024
    800044ee:	05890593          	addi	a1,s2,88
    800044f2:	05850513          	addi	a0,a0,88
    800044f6:	ffffd097          	auipc	ra,0xffffd
    800044fa:	824080e7          	jalr	-2012(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800044fe:	8526                	mv	a0,s1
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	fec080e7          	jalr	-20(ra) # 800034ec <bwrite>
    if(recovering == 0)
    80004508:	f80b1ce3          	bnez	s6,800044a0 <install_trans+0x36>
      bunpin(dbuf);
    8000450c:	8526                	mv	a0,s1
    8000450e:	fffff097          	auipc	ra,0xfffff
    80004512:	0f6080e7          	jalr	246(ra) # 80003604 <bunpin>
    80004516:	b769                	j	800044a0 <install_trans+0x36>
}
    80004518:	70e2                	ld	ra,56(sp)
    8000451a:	7442                	ld	s0,48(sp)
    8000451c:	74a2                	ld	s1,40(sp)
    8000451e:	7902                	ld	s2,32(sp)
    80004520:	69e2                	ld	s3,24(sp)
    80004522:	6a42                	ld	s4,16(sp)
    80004524:	6aa2                	ld	s5,8(sp)
    80004526:	6b02                	ld	s6,0(sp)
    80004528:	6121                	addi	sp,sp,64
    8000452a:	8082                	ret
    8000452c:	8082                	ret

000000008000452e <initlog>:
{
    8000452e:	7179                	addi	sp,sp,-48
    80004530:	f406                	sd	ra,40(sp)
    80004532:	f022                	sd	s0,32(sp)
    80004534:	ec26                	sd	s1,24(sp)
    80004536:	e84a                	sd	s2,16(sp)
    80004538:	e44e                	sd	s3,8(sp)
    8000453a:	1800                	addi	s0,sp,48
    8000453c:	892a                	mv	s2,a0
    8000453e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004540:	00023497          	auipc	s1,0x23
    80004544:	33048493          	addi	s1,s1,816 # 80027870 <log>
    80004548:	00004597          	auipc	a1,0x4
    8000454c:	0d858593          	addi	a1,a1,216 # 80008620 <syscalls+0x1f0>
    80004550:	8526                	mv	a0,s1
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	5e0080e7          	jalr	1504(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000455a:	0149a583          	lw	a1,20(s3)
    8000455e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004560:	0109a783          	lw	a5,16(s3)
    80004564:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004566:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000456a:	854a                	mv	a0,s2
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	e8e080e7          	jalr	-370(ra) # 800033fa <bread>
  log.lh.n = lh->n;
    80004574:	4d34                	lw	a3,88(a0)
    80004576:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004578:	02d05663          	blez	a3,800045a4 <initlog+0x76>
    8000457c:	05c50793          	addi	a5,a0,92
    80004580:	00023717          	auipc	a4,0x23
    80004584:	32070713          	addi	a4,a4,800 # 800278a0 <log+0x30>
    80004588:	36fd                	addiw	a3,a3,-1
    8000458a:	02069613          	slli	a2,a3,0x20
    8000458e:	01e65693          	srli	a3,a2,0x1e
    80004592:	06050613          	addi	a2,a0,96
    80004596:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004598:	4390                	lw	a2,0(a5)
    8000459a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000459c:	0791                	addi	a5,a5,4
    8000459e:	0711                	addi	a4,a4,4
    800045a0:	fed79ce3          	bne	a5,a3,80004598 <initlog+0x6a>
  brelse(buf);
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	f86080e7          	jalr	-122(ra) # 8000352a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045ac:	4505                	li	a0,1
    800045ae:	00000097          	auipc	ra,0x0
    800045b2:	ebc080e7          	jalr	-324(ra) # 8000446a <install_trans>
  log.lh.n = 0;
    800045b6:	00023797          	auipc	a5,0x23
    800045ba:	2e07a323          	sw	zero,742(a5) # 8002789c <log+0x2c>
  write_head(); // clear the log
    800045be:	00000097          	auipc	ra,0x0
    800045c2:	e30080e7          	jalr	-464(ra) # 800043ee <write_head>
}
    800045c6:	70a2                	ld	ra,40(sp)
    800045c8:	7402                	ld	s0,32(sp)
    800045ca:	64e2                	ld	s1,24(sp)
    800045cc:	6942                	ld	s2,16(sp)
    800045ce:	69a2                	ld	s3,8(sp)
    800045d0:	6145                	addi	sp,sp,48
    800045d2:	8082                	ret

00000000800045d4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045d4:	1101                	addi	sp,sp,-32
    800045d6:	ec06                	sd	ra,24(sp)
    800045d8:	e822                	sd	s0,16(sp)
    800045da:	e426                	sd	s1,8(sp)
    800045dc:	e04a                	sd	s2,0(sp)
    800045de:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045e0:	00023517          	auipc	a0,0x23
    800045e4:	29050513          	addi	a0,a0,656 # 80027870 <log>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	5da080e7          	jalr	1498(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800045f0:	00023497          	auipc	s1,0x23
    800045f4:	28048493          	addi	s1,s1,640 # 80027870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045f8:	4979                	li	s2,30
    800045fa:	a039                	j	80004608 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045fc:	85a6                	mv	a1,s1
    800045fe:	8526                	mv	a0,s1
    80004600:	ffffe097          	auipc	ra,0xffffe
    80004604:	d88080e7          	jalr	-632(ra) # 80002388 <sleep>
    if(log.committing){
    80004608:	50dc                	lw	a5,36(s1)
    8000460a:	fbed                	bnez	a5,800045fc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000460c:	509c                	lw	a5,32(s1)
    8000460e:	0017871b          	addiw	a4,a5,1
    80004612:	0007069b          	sext.w	a3,a4
    80004616:	0027179b          	slliw	a5,a4,0x2
    8000461a:	9fb9                	addw	a5,a5,a4
    8000461c:	0017979b          	slliw	a5,a5,0x1
    80004620:	54d8                	lw	a4,44(s1)
    80004622:	9fb9                	addw	a5,a5,a4
    80004624:	00f95963          	bge	s2,a5,80004636 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004628:	85a6                	mv	a1,s1
    8000462a:	8526                	mv	a0,s1
    8000462c:	ffffe097          	auipc	ra,0xffffe
    80004630:	d5c080e7          	jalr	-676(ra) # 80002388 <sleep>
    80004634:	bfd1                	j	80004608 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004636:	00023517          	auipc	a0,0x23
    8000463a:	23a50513          	addi	a0,a0,570 # 80027870 <log>
    8000463e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	636080e7          	jalr	1590(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004648:	60e2                	ld	ra,24(sp)
    8000464a:	6442                	ld	s0,16(sp)
    8000464c:	64a2                	ld	s1,8(sp)
    8000464e:	6902                	ld	s2,0(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004654:	7139                	addi	sp,sp,-64
    80004656:	fc06                	sd	ra,56(sp)
    80004658:	f822                	sd	s0,48(sp)
    8000465a:	f426                	sd	s1,40(sp)
    8000465c:	f04a                	sd	s2,32(sp)
    8000465e:	ec4e                	sd	s3,24(sp)
    80004660:	e852                	sd	s4,16(sp)
    80004662:	e456                	sd	s5,8(sp)
    80004664:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004666:	00023497          	auipc	s1,0x23
    8000466a:	20a48493          	addi	s1,s1,522 # 80027870 <log>
    8000466e:	8526                	mv	a0,s1
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	552080e7          	jalr	1362(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004678:	509c                	lw	a5,32(s1)
    8000467a:	37fd                	addiw	a5,a5,-1
    8000467c:	0007891b          	sext.w	s2,a5
    80004680:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004682:	50dc                	lw	a5,36(s1)
    80004684:	e7b9                	bnez	a5,800046d2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004686:	04091e63          	bnez	s2,800046e2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000468a:	00023497          	auipc	s1,0x23
    8000468e:	1e648493          	addi	s1,s1,486 # 80027870 <log>
    80004692:	4785                	li	a5,1
    80004694:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004696:	8526                	mv	a0,s1
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	5de080e7          	jalr	1502(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046a0:	54dc                	lw	a5,44(s1)
    800046a2:	06f04763          	bgtz	a5,80004710 <end_op+0xbc>
    acquire(&log.lock);
    800046a6:	00023497          	auipc	s1,0x23
    800046aa:	1ca48493          	addi	s1,s1,458 # 80027870 <log>
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	512080e7          	jalr	1298(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800046b8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046bc:	8526                	mv	a0,s1
    800046be:	ffffe097          	auipc	ra,0xffffe
    800046c2:	e58080e7          	jalr	-424(ra) # 80002516 <wakeup>
    release(&log.lock);
    800046c6:	8526                	mv	a0,s1
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5ae080e7          	jalr	1454(ra) # 80000c76 <release>
}
    800046d0:	a03d                	j	800046fe <end_op+0xaa>
    panic("log.committing");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	f5650513          	addi	a0,a0,-170 # 80008628 <syscalls+0x1f8>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e50080e7          	jalr	-432(ra) # 8000052a <panic>
    wakeup(&log);
    800046e2:	00023497          	auipc	s1,0x23
    800046e6:	18e48493          	addi	s1,s1,398 # 80027870 <log>
    800046ea:	8526                	mv	a0,s1
    800046ec:	ffffe097          	auipc	ra,0xffffe
    800046f0:	e2a080e7          	jalr	-470(ra) # 80002516 <wakeup>
  release(&log.lock);
    800046f4:	8526                	mv	a0,s1
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	580080e7          	jalr	1408(ra) # 80000c76 <release>
}
    800046fe:	70e2                	ld	ra,56(sp)
    80004700:	7442                	ld	s0,48(sp)
    80004702:	74a2                	ld	s1,40(sp)
    80004704:	7902                	ld	s2,32(sp)
    80004706:	69e2                	ld	s3,24(sp)
    80004708:	6a42                	ld	s4,16(sp)
    8000470a:	6aa2                	ld	s5,8(sp)
    8000470c:	6121                	addi	sp,sp,64
    8000470e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004710:	00023a97          	auipc	s5,0x23
    80004714:	190a8a93          	addi	s5,s5,400 # 800278a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004718:	00023a17          	auipc	s4,0x23
    8000471c:	158a0a13          	addi	s4,s4,344 # 80027870 <log>
    80004720:	018a2583          	lw	a1,24(s4)
    80004724:	012585bb          	addw	a1,a1,s2
    80004728:	2585                	addiw	a1,a1,1
    8000472a:	028a2503          	lw	a0,40(s4)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	ccc080e7          	jalr	-820(ra) # 800033fa <bread>
    80004736:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004738:	000aa583          	lw	a1,0(s5)
    8000473c:	028a2503          	lw	a0,40(s4)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	cba080e7          	jalr	-838(ra) # 800033fa <bread>
    80004748:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000474a:	40000613          	li	a2,1024
    8000474e:	05850593          	addi	a1,a0,88
    80004752:	05848513          	addi	a0,s1,88
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	5c4080e7          	jalr	1476(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000475e:	8526                	mv	a0,s1
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	d8c080e7          	jalr	-628(ra) # 800034ec <bwrite>
    brelse(from);
    80004768:	854e                	mv	a0,s3
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	dc0080e7          	jalr	-576(ra) # 8000352a <brelse>
    brelse(to);
    80004772:	8526                	mv	a0,s1
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	db6080e7          	jalr	-586(ra) # 8000352a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000477c:	2905                	addiw	s2,s2,1
    8000477e:	0a91                	addi	s5,s5,4
    80004780:	02ca2783          	lw	a5,44(s4)
    80004784:	f8f94ee3          	blt	s2,a5,80004720 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	c66080e7          	jalr	-922(ra) # 800043ee <write_head>
    install_trans(0); // Now install writes to home locations
    80004790:	4501                	li	a0,0
    80004792:	00000097          	auipc	ra,0x0
    80004796:	cd8080e7          	jalr	-808(ra) # 8000446a <install_trans>
    log.lh.n = 0;
    8000479a:	00023797          	auipc	a5,0x23
    8000479e:	1007a123          	sw	zero,258(a5) # 8002789c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	c4c080e7          	jalr	-948(ra) # 800043ee <write_head>
    800047aa:	bdf5                	j	800046a6 <end_op+0x52>

00000000800047ac <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047ac:	1101                	addi	sp,sp,-32
    800047ae:	ec06                	sd	ra,24(sp)
    800047b0:	e822                	sd	s0,16(sp)
    800047b2:	e426                	sd	s1,8(sp)
    800047b4:	e04a                	sd	s2,0(sp)
    800047b6:	1000                	addi	s0,sp,32
    800047b8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047ba:	00023917          	auipc	s2,0x23
    800047be:	0b690913          	addi	s2,s2,182 # 80027870 <log>
    800047c2:	854a                	mv	a0,s2
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	3fe080e7          	jalr	1022(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047cc:	02c92603          	lw	a2,44(s2)
    800047d0:	47f5                	li	a5,29
    800047d2:	06c7c563          	blt	a5,a2,8000483c <log_write+0x90>
    800047d6:	00023797          	auipc	a5,0x23
    800047da:	0b67a783          	lw	a5,182(a5) # 8002788c <log+0x1c>
    800047de:	37fd                	addiw	a5,a5,-1
    800047e0:	04f65e63          	bge	a2,a5,8000483c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047e4:	00023797          	auipc	a5,0x23
    800047e8:	0ac7a783          	lw	a5,172(a5) # 80027890 <log+0x20>
    800047ec:	06f05063          	blez	a5,8000484c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047f0:	4781                	li	a5,0
    800047f2:	06c05563          	blez	a2,8000485c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800047f6:	44cc                	lw	a1,12(s1)
    800047f8:	00023717          	auipc	a4,0x23
    800047fc:	0a870713          	addi	a4,a4,168 # 800278a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004800:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004802:	4314                	lw	a3,0(a4)
    80004804:	04b68c63          	beq	a3,a1,8000485c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004808:	2785                	addiw	a5,a5,1
    8000480a:	0711                	addi	a4,a4,4
    8000480c:	fef61be3          	bne	a2,a5,80004802 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004810:	0621                	addi	a2,a2,8
    80004812:	060a                	slli	a2,a2,0x2
    80004814:	00023797          	auipc	a5,0x23
    80004818:	05c78793          	addi	a5,a5,92 # 80027870 <log>
    8000481c:	963e                	add	a2,a2,a5
    8000481e:	44dc                	lw	a5,12(s1)
    80004820:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004822:	8526                	mv	a0,s1
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	da4080e7          	jalr	-604(ra) # 800035c8 <bpin>
    log.lh.n++;
    8000482c:	00023717          	auipc	a4,0x23
    80004830:	04470713          	addi	a4,a4,68 # 80027870 <log>
    80004834:	575c                	lw	a5,44(a4)
    80004836:	2785                	addiw	a5,a5,1
    80004838:	d75c                	sw	a5,44(a4)
    8000483a:	a835                	j	80004876 <log_write+0xca>
    panic("too big a transaction");
    8000483c:	00004517          	auipc	a0,0x4
    80004840:	dfc50513          	addi	a0,a0,-516 # 80008638 <syscalls+0x208>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	ce6080e7          	jalr	-794(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	e0450513          	addi	a0,a0,-508 # 80008650 <syscalls+0x220>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	cd6080e7          	jalr	-810(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000485c:	00878713          	addi	a4,a5,8
    80004860:	00271693          	slli	a3,a4,0x2
    80004864:	00023717          	auipc	a4,0x23
    80004868:	00c70713          	addi	a4,a4,12 # 80027870 <log>
    8000486c:	9736                	add	a4,a4,a3
    8000486e:	44d4                	lw	a3,12(s1)
    80004870:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004872:	faf608e3          	beq	a2,a5,80004822 <log_write+0x76>
  }
  release(&log.lock);
    80004876:	00023517          	auipc	a0,0x23
    8000487a:	ffa50513          	addi	a0,a0,-6 # 80027870 <log>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	3f8080e7          	jalr	1016(ra) # 80000c76 <release>
}
    80004886:	60e2                	ld	ra,24(sp)
    80004888:	6442                	ld	s0,16(sp)
    8000488a:	64a2                	ld	s1,8(sp)
    8000488c:	6902                	ld	s2,0(sp)
    8000488e:	6105                	addi	sp,sp,32
    80004890:	8082                	ret

0000000080004892 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004892:	1101                	addi	sp,sp,-32
    80004894:	ec06                	sd	ra,24(sp)
    80004896:	e822                	sd	s0,16(sp)
    80004898:	e426                	sd	s1,8(sp)
    8000489a:	e04a                	sd	s2,0(sp)
    8000489c:	1000                	addi	s0,sp,32
    8000489e:	84aa                	mv	s1,a0
    800048a0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048a2:	00004597          	auipc	a1,0x4
    800048a6:	dce58593          	addi	a1,a1,-562 # 80008670 <syscalls+0x240>
    800048aa:	0521                	addi	a0,a0,8
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	286080e7          	jalr	646(ra) # 80000b32 <initlock>
  lk->name = name;
    800048b4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048bc:	0204a423          	sw	zero,40(s1)
}
    800048c0:	60e2                	ld	ra,24(sp)
    800048c2:	6442                	ld	s0,16(sp)
    800048c4:	64a2                	ld	s1,8(sp)
    800048c6:	6902                	ld	s2,0(sp)
    800048c8:	6105                	addi	sp,sp,32
    800048ca:	8082                	ret

00000000800048cc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048cc:	1101                	addi	sp,sp,-32
    800048ce:	ec06                	sd	ra,24(sp)
    800048d0:	e822                	sd	s0,16(sp)
    800048d2:	e426                	sd	s1,8(sp)
    800048d4:	e04a                	sd	s2,0(sp)
    800048d6:	1000                	addi	s0,sp,32
    800048d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048da:	00850913          	addi	s2,a0,8
    800048de:	854a                	mv	a0,s2
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	2e2080e7          	jalr	738(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800048e8:	409c                	lw	a5,0(s1)
    800048ea:	cb89                	beqz	a5,800048fc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048ec:	85ca                	mv	a1,s2
    800048ee:	8526                	mv	a0,s1
    800048f0:	ffffe097          	auipc	ra,0xffffe
    800048f4:	a98080e7          	jalr	-1384(ra) # 80002388 <sleep>
  while (lk->locked) {
    800048f8:	409c                	lw	a5,0(s1)
    800048fa:	fbed                	bnez	a5,800048ec <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048fc:	4785                	li	a5,1
    800048fe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004900:	ffffd097          	auipc	ra,0xffffd
    80004904:	080080e7          	jalr	128(ra) # 80001980 <myproc>
    80004908:	591c                	lw	a5,48(a0)
    8000490a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000490c:	854a                	mv	a0,s2
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	368080e7          	jalr	872(ra) # 80000c76 <release>
}
    80004916:	60e2                	ld	ra,24(sp)
    80004918:	6442                	ld	s0,16(sp)
    8000491a:	64a2                	ld	s1,8(sp)
    8000491c:	6902                	ld	s2,0(sp)
    8000491e:	6105                	addi	sp,sp,32
    80004920:	8082                	ret

0000000080004922 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004922:	1101                	addi	sp,sp,-32
    80004924:	ec06                	sd	ra,24(sp)
    80004926:	e822                	sd	s0,16(sp)
    80004928:	e426                	sd	s1,8(sp)
    8000492a:	e04a                	sd	s2,0(sp)
    8000492c:	1000                	addi	s0,sp,32
    8000492e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004930:	00850913          	addi	s2,a0,8
    80004934:	854a                	mv	a0,s2
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	28c080e7          	jalr	652(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000493e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004942:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004946:	8526                	mv	a0,s1
    80004948:	ffffe097          	auipc	ra,0xffffe
    8000494c:	bce080e7          	jalr	-1074(ra) # 80002516 <wakeup>
  release(&lk->lk);
    80004950:	854a                	mv	a0,s2
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	324080e7          	jalr	804(ra) # 80000c76 <release>
}
    8000495a:	60e2                	ld	ra,24(sp)
    8000495c:	6442                	ld	s0,16(sp)
    8000495e:	64a2                	ld	s1,8(sp)
    80004960:	6902                	ld	s2,0(sp)
    80004962:	6105                	addi	sp,sp,32
    80004964:	8082                	ret

0000000080004966 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004966:	7179                	addi	sp,sp,-48
    80004968:	f406                	sd	ra,40(sp)
    8000496a:	f022                	sd	s0,32(sp)
    8000496c:	ec26                	sd	s1,24(sp)
    8000496e:	e84a                	sd	s2,16(sp)
    80004970:	e44e                	sd	s3,8(sp)
    80004972:	1800                	addi	s0,sp,48
    80004974:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004976:	00850913          	addi	s2,a0,8
    8000497a:	854a                	mv	a0,s2
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	246080e7          	jalr	582(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004984:	409c                	lw	a5,0(s1)
    80004986:	ef99                	bnez	a5,800049a4 <holdingsleep+0x3e>
    80004988:	4481                	li	s1,0
  release(&lk->lk);
    8000498a:	854a                	mv	a0,s2
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	2ea080e7          	jalr	746(ra) # 80000c76 <release>
  return r;
}
    80004994:	8526                	mv	a0,s1
    80004996:	70a2                	ld	ra,40(sp)
    80004998:	7402                	ld	s0,32(sp)
    8000499a:	64e2                	ld	s1,24(sp)
    8000499c:	6942                	ld	s2,16(sp)
    8000499e:	69a2                	ld	s3,8(sp)
    800049a0:	6145                	addi	sp,sp,48
    800049a2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049a4:	0284a983          	lw	s3,40(s1)
    800049a8:	ffffd097          	auipc	ra,0xffffd
    800049ac:	fd8080e7          	jalr	-40(ra) # 80001980 <myproc>
    800049b0:	5904                	lw	s1,48(a0)
    800049b2:	413484b3          	sub	s1,s1,s3
    800049b6:	0014b493          	seqz	s1,s1
    800049ba:	bfc1                	j	8000498a <holdingsleep+0x24>

00000000800049bc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049bc:	1141                	addi	sp,sp,-16
    800049be:	e406                	sd	ra,8(sp)
    800049c0:	e022                	sd	s0,0(sp)
    800049c2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049c4:	00004597          	auipc	a1,0x4
    800049c8:	cbc58593          	addi	a1,a1,-836 # 80008680 <syscalls+0x250>
    800049cc:	00023517          	auipc	a0,0x23
    800049d0:	fec50513          	addi	a0,a0,-20 # 800279b8 <ftable>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	15e080e7          	jalr	350(ra) # 80000b32 <initlock>
}
    800049dc:	60a2                	ld	ra,8(sp)
    800049de:	6402                	ld	s0,0(sp)
    800049e0:	0141                	addi	sp,sp,16
    800049e2:	8082                	ret

00000000800049e4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049e4:	1101                	addi	sp,sp,-32
    800049e6:	ec06                	sd	ra,24(sp)
    800049e8:	e822                	sd	s0,16(sp)
    800049ea:	e426                	sd	s1,8(sp)
    800049ec:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049ee:	00023517          	auipc	a0,0x23
    800049f2:	fca50513          	addi	a0,a0,-54 # 800279b8 <ftable>
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	1cc080e7          	jalr	460(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049fe:	00023497          	auipc	s1,0x23
    80004a02:	fd248493          	addi	s1,s1,-46 # 800279d0 <ftable+0x18>
    80004a06:	00024717          	auipc	a4,0x24
    80004a0a:	f6a70713          	addi	a4,a4,-150 # 80028970 <ftable+0xfb8>
    if(f->ref == 0){
    80004a0e:	40dc                	lw	a5,4(s1)
    80004a10:	cf99                	beqz	a5,80004a2e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a12:	02848493          	addi	s1,s1,40
    80004a16:	fee49ce3          	bne	s1,a4,80004a0e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a1a:	00023517          	auipc	a0,0x23
    80004a1e:	f9e50513          	addi	a0,a0,-98 # 800279b8 <ftable>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	254080e7          	jalr	596(ra) # 80000c76 <release>
  return 0;
    80004a2a:	4481                	li	s1,0
    80004a2c:	a819                	j	80004a42 <filealloc+0x5e>
      f->ref = 1;
    80004a2e:	4785                	li	a5,1
    80004a30:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a32:	00023517          	auipc	a0,0x23
    80004a36:	f8650513          	addi	a0,a0,-122 # 800279b8 <ftable>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	23c080e7          	jalr	572(ra) # 80000c76 <release>
}
    80004a42:	8526                	mv	a0,s1
    80004a44:	60e2                	ld	ra,24(sp)
    80004a46:	6442                	ld	s0,16(sp)
    80004a48:	64a2                	ld	s1,8(sp)
    80004a4a:	6105                	addi	sp,sp,32
    80004a4c:	8082                	ret

0000000080004a4e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a4e:	1101                	addi	sp,sp,-32
    80004a50:	ec06                	sd	ra,24(sp)
    80004a52:	e822                	sd	s0,16(sp)
    80004a54:	e426                	sd	s1,8(sp)
    80004a56:	1000                	addi	s0,sp,32
    80004a58:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a5a:	00023517          	auipc	a0,0x23
    80004a5e:	f5e50513          	addi	a0,a0,-162 # 800279b8 <ftable>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	160080e7          	jalr	352(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004a6a:	40dc                	lw	a5,4(s1)
    80004a6c:	02f05263          	blez	a5,80004a90 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a70:	2785                	addiw	a5,a5,1
    80004a72:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a74:	00023517          	auipc	a0,0x23
    80004a78:	f4450513          	addi	a0,a0,-188 # 800279b8 <ftable>
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	1fa080e7          	jalr	506(ra) # 80000c76 <release>
  return f;
}
    80004a84:	8526                	mv	a0,s1
    80004a86:	60e2                	ld	ra,24(sp)
    80004a88:	6442                	ld	s0,16(sp)
    80004a8a:	64a2                	ld	s1,8(sp)
    80004a8c:	6105                	addi	sp,sp,32
    80004a8e:	8082                	ret
    panic("filedup");
    80004a90:	00004517          	auipc	a0,0x4
    80004a94:	bf850513          	addi	a0,a0,-1032 # 80008688 <syscalls+0x258>
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	a92080e7          	jalr	-1390(ra) # 8000052a <panic>

0000000080004aa0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004aa0:	7139                	addi	sp,sp,-64
    80004aa2:	fc06                	sd	ra,56(sp)
    80004aa4:	f822                	sd	s0,48(sp)
    80004aa6:	f426                	sd	s1,40(sp)
    80004aa8:	f04a                	sd	s2,32(sp)
    80004aaa:	ec4e                	sd	s3,24(sp)
    80004aac:	e852                	sd	s4,16(sp)
    80004aae:	e456                	sd	s5,8(sp)
    80004ab0:	0080                	addi	s0,sp,64
    80004ab2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ab4:	00023517          	auipc	a0,0x23
    80004ab8:	f0450513          	addi	a0,a0,-252 # 800279b8 <ftable>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	106080e7          	jalr	262(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004ac4:	40dc                	lw	a5,4(s1)
    80004ac6:	06f05163          	blez	a5,80004b28 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004aca:	37fd                	addiw	a5,a5,-1
    80004acc:	0007871b          	sext.w	a4,a5
    80004ad0:	c0dc                	sw	a5,4(s1)
    80004ad2:	06e04363          	bgtz	a4,80004b38 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ad6:	0004a903          	lw	s2,0(s1)
    80004ada:	0094ca83          	lbu	s5,9(s1)
    80004ade:	0104ba03          	ld	s4,16(s1)
    80004ae2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ae6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004aea:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004aee:	00023517          	auipc	a0,0x23
    80004af2:	eca50513          	addi	a0,a0,-310 # 800279b8 <ftable>
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	180080e7          	jalr	384(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004afe:	4785                	li	a5,1
    80004b00:	04f90d63          	beq	s2,a5,80004b5a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b04:	3979                	addiw	s2,s2,-2
    80004b06:	4785                	li	a5,1
    80004b08:	0527e063          	bltu	a5,s2,80004b48 <fileclose+0xa8>
    begin_op();
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	ac8080e7          	jalr	-1336(ra) # 800045d4 <begin_op>
    iput(ff.ip);
    80004b14:	854e                	mv	a0,s3
    80004b16:	fffff097          	auipc	ra,0xfffff
    80004b1a:	2a2080e7          	jalr	674(ra) # 80003db8 <iput>
    end_op();
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	b36080e7          	jalr	-1226(ra) # 80004654 <end_op>
    80004b26:	a00d                	j	80004b48 <fileclose+0xa8>
    panic("fileclose");
    80004b28:	00004517          	auipc	a0,0x4
    80004b2c:	b6850513          	addi	a0,a0,-1176 # 80008690 <syscalls+0x260>
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	9fa080e7          	jalr	-1542(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004b38:	00023517          	auipc	a0,0x23
    80004b3c:	e8050513          	addi	a0,a0,-384 # 800279b8 <ftable>
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	136080e7          	jalr	310(ra) # 80000c76 <release>
  }
}
    80004b48:	70e2                	ld	ra,56(sp)
    80004b4a:	7442                	ld	s0,48(sp)
    80004b4c:	74a2                	ld	s1,40(sp)
    80004b4e:	7902                	ld	s2,32(sp)
    80004b50:	69e2                	ld	s3,24(sp)
    80004b52:	6a42                	ld	s4,16(sp)
    80004b54:	6aa2                	ld	s5,8(sp)
    80004b56:	6121                	addi	sp,sp,64
    80004b58:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b5a:	85d6                	mv	a1,s5
    80004b5c:	8552                	mv	a0,s4
    80004b5e:	00000097          	auipc	ra,0x0
    80004b62:	34c080e7          	jalr	844(ra) # 80004eaa <pipeclose>
    80004b66:	b7cd                	j	80004b48 <fileclose+0xa8>

0000000080004b68 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b68:	715d                	addi	sp,sp,-80
    80004b6a:	e486                	sd	ra,72(sp)
    80004b6c:	e0a2                	sd	s0,64(sp)
    80004b6e:	fc26                	sd	s1,56(sp)
    80004b70:	f84a                	sd	s2,48(sp)
    80004b72:	f44e                	sd	s3,40(sp)
    80004b74:	0880                	addi	s0,sp,80
    80004b76:	84aa                	mv	s1,a0
    80004b78:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	e06080e7          	jalr	-506(ra) # 80001980 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b82:	409c                	lw	a5,0(s1)
    80004b84:	37f9                	addiw	a5,a5,-2
    80004b86:	4705                	li	a4,1
    80004b88:	04f76763          	bltu	a4,a5,80004bd6 <filestat+0x6e>
    80004b8c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b8e:	6c88                	ld	a0,24(s1)
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	06e080e7          	jalr	110(ra) # 80003bfe <ilock>
    stati(f->ip, &st);
    80004b98:	fb840593          	addi	a1,s0,-72
    80004b9c:	6c88                	ld	a0,24(s1)
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	2ea080e7          	jalr	746(ra) # 80003e88 <stati>
    iunlock(f->ip);
    80004ba6:	6c88                	ld	a0,24(s1)
    80004ba8:	fffff097          	auipc	ra,0xfffff
    80004bac:	118080e7          	jalr	280(ra) # 80003cc0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bb0:	46e1                	li	a3,24
    80004bb2:	fb840613          	addi	a2,s0,-72
    80004bb6:	85ce                	mv	a1,s3
    80004bb8:	1e893503          	ld	a0,488(s2)
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	a82080e7          	jalr	-1406(ra) # 8000163e <copyout>
    80004bc4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bc8:	60a6                	ld	ra,72(sp)
    80004bca:	6406                	ld	s0,64(sp)
    80004bcc:	74e2                	ld	s1,56(sp)
    80004bce:	7942                	ld	s2,48(sp)
    80004bd0:	79a2                	ld	s3,40(sp)
    80004bd2:	6161                	addi	sp,sp,80
    80004bd4:	8082                	ret
  return -1;
    80004bd6:	557d                	li	a0,-1
    80004bd8:	bfc5                	j	80004bc8 <filestat+0x60>

0000000080004bda <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bda:	7179                	addi	sp,sp,-48
    80004bdc:	f406                	sd	ra,40(sp)
    80004bde:	f022                	sd	s0,32(sp)
    80004be0:	ec26                	sd	s1,24(sp)
    80004be2:	e84a                	sd	s2,16(sp)
    80004be4:	e44e                	sd	s3,8(sp)
    80004be6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004be8:	00854783          	lbu	a5,8(a0)
    80004bec:	c3d5                	beqz	a5,80004c90 <fileread+0xb6>
    80004bee:	84aa                	mv	s1,a0
    80004bf0:	89ae                	mv	s3,a1
    80004bf2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bf4:	411c                	lw	a5,0(a0)
    80004bf6:	4705                	li	a4,1
    80004bf8:	04e78963          	beq	a5,a4,80004c4a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bfc:	470d                	li	a4,3
    80004bfe:	04e78d63          	beq	a5,a4,80004c58 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c02:	4709                	li	a4,2
    80004c04:	06e79e63          	bne	a5,a4,80004c80 <fileread+0xa6>
    ilock(f->ip);
    80004c08:	6d08                	ld	a0,24(a0)
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	ff4080e7          	jalr	-12(ra) # 80003bfe <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c12:	874a                	mv	a4,s2
    80004c14:	5094                	lw	a3,32(s1)
    80004c16:	864e                	mv	a2,s3
    80004c18:	4585                	li	a1,1
    80004c1a:	6c88                	ld	a0,24(s1)
    80004c1c:	fffff097          	auipc	ra,0xfffff
    80004c20:	296080e7          	jalr	662(ra) # 80003eb2 <readi>
    80004c24:	892a                	mv	s2,a0
    80004c26:	00a05563          	blez	a0,80004c30 <fileread+0x56>
      f->off += r;
    80004c2a:	509c                	lw	a5,32(s1)
    80004c2c:	9fa9                	addw	a5,a5,a0
    80004c2e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c30:	6c88                	ld	a0,24(s1)
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	08e080e7          	jalr	142(ra) # 80003cc0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c3a:	854a                	mv	a0,s2
    80004c3c:	70a2                	ld	ra,40(sp)
    80004c3e:	7402                	ld	s0,32(sp)
    80004c40:	64e2                	ld	s1,24(sp)
    80004c42:	6942                	ld	s2,16(sp)
    80004c44:	69a2                	ld	s3,8(sp)
    80004c46:	6145                	addi	sp,sp,48
    80004c48:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c4a:	6908                	ld	a0,16(a0)
    80004c4c:	00000097          	auipc	ra,0x0
    80004c50:	3c0080e7          	jalr	960(ra) # 8000500c <piperead>
    80004c54:	892a                	mv	s2,a0
    80004c56:	b7d5                	j	80004c3a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c58:	02451783          	lh	a5,36(a0)
    80004c5c:	03079693          	slli	a3,a5,0x30
    80004c60:	92c1                	srli	a3,a3,0x30
    80004c62:	4725                	li	a4,9
    80004c64:	02d76863          	bltu	a4,a3,80004c94 <fileread+0xba>
    80004c68:	0792                	slli	a5,a5,0x4
    80004c6a:	00023717          	auipc	a4,0x23
    80004c6e:	cae70713          	addi	a4,a4,-850 # 80027918 <devsw>
    80004c72:	97ba                	add	a5,a5,a4
    80004c74:	639c                	ld	a5,0(a5)
    80004c76:	c38d                	beqz	a5,80004c98 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c78:	4505                	li	a0,1
    80004c7a:	9782                	jalr	a5
    80004c7c:	892a                	mv	s2,a0
    80004c7e:	bf75                	j	80004c3a <fileread+0x60>
    panic("fileread");
    80004c80:	00004517          	auipc	a0,0x4
    80004c84:	a2050513          	addi	a0,a0,-1504 # 800086a0 <syscalls+0x270>
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	8a2080e7          	jalr	-1886(ra) # 8000052a <panic>
    return -1;
    80004c90:	597d                	li	s2,-1
    80004c92:	b765                	j	80004c3a <fileread+0x60>
      return -1;
    80004c94:	597d                	li	s2,-1
    80004c96:	b755                	j	80004c3a <fileread+0x60>
    80004c98:	597d                	li	s2,-1
    80004c9a:	b745                	j	80004c3a <fileread+0x60>

0000000080004c9c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c9c:	715d                	addi	sp,sp,-80
    80004c9e:	e486                	sd	ra,72(sp)
    80004ca0:	e0a2                	sd	s0,64(sp)
    80004ca2:	fc26                	sd	s1,56(sp)
    80004ca4:	f84a                	sd	s2,48(sp)
    80004ca6:	f44e                	sd	s3,40(sp)
    80004ca8:	f052                	sd	s4,32(sp)
    80004caa:	ec56                	sd	s5,24(sp)
    80004cac:	e85a                	sd	s6,16(sp)
    80004cae:	e45e                	sd	s7,8(sp)
    80004cb0:	e062                	sd	s8,0(sp)
    80004cb2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cb4:	00954783          	lbu	a5,9(a0)
    80004cb8:	10078663          	beqz	a5,80004dc4 <filewrite+0x128>
    80004cbc:	892a                	mv	s2,a0
    80004cbe:	8aae                	mv	s5,a1
    80004cc0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cc2:	411c                	lw	a5,0(a0)
    80004cc4:	4705                	li	a4,1
    80004cc6:	02e78263          	beq	a5,a4,80004cea <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cca:	470d                	li	a4,3
    80004ccc:	02e78663          	beq	a5,a4,80004cf8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cd0:	4709                	li	a4,2
    80004cd2:	0ee79163          	bne	a5,a4,80004db4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cd6:	0ac05d63          	blez	a2,80004d90 <filewrite+0xf4>
    int i = 0;
    80004cda:	4981                	li	s3,0
    80004cdc:	6b05                	lui	s6,0x1
    80004cde:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ce2:	6b85                	lui	s7,0x1
    80004ce4:	c00b8b9b          	addiw	s7,s7,-1024
    80004ce8:	a861                	j	80004d80 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cea:	6908                	ld	a0,16(a0)
    80004cec:	00000097          	auipc	ra,0x0
    80004cf0:	22e080e7          	jalr	558(ra) # 80004f1a <pipewrite>
    80004cf4:	8a2a                	mv	s4,a0
    80004cf6:	a045                	j	80004d96 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cf8:	02451783          	lh	a5,36(a0)
    80004cfc:	03079693          	slli	a3,a5,0x30
    80004d00:	92c1                	srli	a3,a3,0x30
    80004d02:	4725                	li	a4,9
    80004d04:	0cd76263          	bltu	a4,a3,80004dc8 <filewrite+0x12c>
    80004d08:	0792                	slli	a5,a5,0x4
    80004d0a:	00023717          	auipc	a4,0x23
    80004d0e:	c0e70713          	addi	a4,a4,-1010 # 80027918 <devsw>
    80004d12:	97ba                	add	a5,a5,a4
    80004d14:	679c                	ld	a5,8(a5)
    80004d16:	cbdd                	beqz	a5,80004dcc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d18:	4505                	li	a0,1
    80004d1a:	9782                	jalr	a5
    80004d1c:	8a2a                	mv	s4,a0
    80004d1e:	a8a5                	j	80004d96 <filewrite+0xfa>
    80004d20:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d24:	00000097          	auipc	ra,0x0
    80004d28:	8b0080e7          	jalr	-1872(ra) # 800045d4 <begin_op>
      ilock(f->ip);
    80004d2c:	01893503          	ld	a0,24(s2)
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	ece080e7          	jalr	-306(ra) # 80003bfe <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d38:	8762                	mv	a4,s8
    80004d3a:	02092683          	lw	a3,32(s2)
    80004d3e:	01598633          	add	a2,s3,s5
    80004d42:	4585                	li	a1,1
    80004d44:	01893503          	ld	a0,24(s2)
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	262080e7          	jalr	610(ra) # 80003faa <writei>
    80004d50:	84aa                	mv	s1,a0
    80004d52:	00a05763          	blez	a0,80004d60 <filewrite+0xc4>
        f->off += r;
    80004d56:	02092783          	lw	a5,32(s2)
    80004d5a:	9fa9                	addw	a5,a5,a0
    80004d5c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d60:	01893503          	ld	a0,24(s2)
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	f5c080e7          	jalr	-164(ra) # 80003cc0 <iunlock>
      end_op();
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	8e8080e7          	jalr	-1816(ra) # 80004654 <end_op>

      if(r != n1){
    80004d74:	009c1f63          	bne	s8,s1,80004d92 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d78:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d7c:	0149db63          	bge	s3,s4,80004d92 <filewrite+0xf6>
      int n1 = n - i;
    80004d80:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d84:	84be                	mv	s1,a5
    80004d86:	2781                	sext.w	a5,a5
    80004d88:	f8fb5ce3          	bge	s6,a5,80004d20 <filewrite+0x84>
    80004d8c:	84de                	mv	s1,s7
    80004d8e:	bf49                	j	80004d20 <filewrite+0x84>
    int i = 0;
    80004d90:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d92:	013a1f63          	bne	s4,s3,80004db0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d96:	8552                	mv	a0,s4
    80004d98:	60a6                	ld	ra,72(sp)
    80004d9a:	6406                	ld	s0,64(sp)
    80004d9c:	74e2                	ld	s1,56(sp)
    80004d9e:	7942                	ld	s2,48(sp)
    80004da0:	79a2                	ld	s3,40(sp)
    80004da2:	7a02                	ld	s4,32(sp)
    80004da4:	6ae2                	ld	s5,24(sp)
    80004da6:	6b42                	ld	s6,16(sp)
    80004da8:	6ba2                	ld	s7,8(sp)
    80004daa:	6c02                	ld	s8,0(sp)
    80004dac:	6161                	addi	sp,sp,80
    80004dae:	8082                	ret
    ret = (i == n ? n : -1);
    80004db0:	5a7d                	li	s4,-1
    80004db2:	b7d5                	j	80004d96 <filewrite+0xfa>
    panic("filewrite");
    80004db4:	00004517          	auipc	a0,0x4
    80004db8:	8fc50513          	addi	a0,a0,-1796 # 800086b0 <syscalls+0x280>
    80004dbc:	ffffb097          	auipc	ra,0xffffb
    80004dc0:	76e080e7          	jalr	1902(ra) # 8000052a <panic>
    return -1;
    80004dc4:	5a7d                	li	s4,-1
    80004dc6:	bfc1                	j	80004d96 <filewrite+0xfa>
      return -1;
    80004dc8:	5a7d                	li	s4,-1
    80004dca:	b7f1                	j	80004d96 <filewrite+0xfa>
    80004dcc:	5a7d                	li	s4,-1
    80004dce:	b7e1                	j	80004d96 <filewrite+0xfa>

0000000080004dd0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004dd0:	7179                	addi	sp,sp,-48
    80004dd2:	f406                	sd	ra,40(sp)
    80004dd4:	f022                	sd	s0,32(sp)
    80004dd6:	ec26                	sd	s1,24(sp)
    80004dd8:	e84a                	sd	s2,16(sp)
    80004dda:	e44e                	sd	s3,8(sp)
    80004ddc:	e052                	sd	s4,0(sp)
    80004dde:	1800                	addi	s0,sp,48
    80004de0:	84aa                	mv	s1,a0
    80004de2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004de4:	0005b023          	sd	zero,0(a1)
    80004de8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dec:	00000097          	auipc	ra,0x0
    80004df0:	bf8080e7          	jalr	-1032(ra) # 800049e4 <filealloc>
    80004df4:	e088                	sd	a0,0(s1)
    80004df6:	c551                	beqz	a0,80004e82 <pipealloc+0xb2>
    80004df8:	00000097          	auipc	ra,0x0
    80004dfc:	bec080e7          	jalr	-1044(ra) # 800049e4 <filealloc>
    80004e00:	00aa3023          	sd	a0,0(s4)
    80004e04:	c92d                	beqz	a0,80004e76 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e06:	ffffc097          	auipc	ra,0xffffc
    80004e0a:	ccc080e7          	jalr	-820(ra) # 80000ad2 <kalloc>
    80004e0e:	892a                	mv	s2,a0
    80004e10:	c125                	beqz	a0,80004e70 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e12:	4985                	li	s3,1
    80004e14:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e18:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e1c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e20:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e24:	00004597          	auipc	a1,0x4
    80004e28:	89c58593          	addi	a1,a1,-1892 # 800086c0 <syscalls+0x290>
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	d06080e7          	jalr	-762(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004e34:	609c                	ld	a5,0(s1)
    80004e36:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e3a:	609c                	ld	a5,0(s1)
    80004e3c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e40:	609c                	ld	a5,0(s1)
    80004e42:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e46:	609c                	ld	a5,0(s1)
    80004e48:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e4c:	000a3783          	ld	a5,0(s4)
    80004e50:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e54:	000a3783          	ld	a5,0(s4)
    80004e58:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e5c:	000a3783          	ld	a5,0(s4)
    80004e60:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e64:	000a3783          	ld	a5,0(s4)
    80004e68:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e6c:	4501                	li	a0,0
    80004e6e:	a025                	j	80004e96 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e70:	6088                	ld	a0,0(s1)
    80004e72:	e501                	bnez	a0,80004e7a <pipealloc+0xaa>
    80004e74:	a039                	j	80004e82 <pipealloc+0xb2>
    80004e76:	6088                	ld	a0,0(s1)
    80004e78:	c51d                	beqz	a0,80004ea6 <pipealloc+0xd6>
    fileclose(*f0);
    80004e7a:	00000097          	auipc	ra,0x0
    80004e7e:	c26080e7          	jalr	-986(ra) # 80004aa0 <fileclose>
  if(*f1)
    80004e82:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e86:	557d                	li	a0,-1
  if(*f1)
    80004e88:	c799                	beqz	a5,80004e96 <pipealloc+0xc6>
    fileclose(*f1);
    80004e8a:	853e                	mv	a0,a5
    80004e8c:	00000097          	auipc	ra,0x0
    80004e90:	c14080e7          	jalr	-1004(ra) # 80004aa0 <fileclose>
  return -1;
    80004e94:	557d                	li	a0,-1
}
    80004e96:	70a2                	ld	ra,40(sp)
    80004e98:	7402                	ld	s0,32(sp)
    80004e9a:	64e2                	ld	s1,24(sp)
    80004e9c:	6942                	ld	s2,16(sp)
    80004e9e:	69a2                	ld	s3,8(sp)
    80004ea0:	6a02                	ld	s4,0(sp)
    80004ea2:	6145                	addi	sp,sp,48
    80004ea4:	8082                	ret
  return -1;
    80004ea6:	557d                	li	a0,-1
    80004ea8:	b7fd                	j	80004e96 <pipealloc+0xc6>

0000000080004eaa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004eaa:	1101                	addi	sp,sp,-32
    80004eac:	ec06                	sd	ra,24(sp)
    80004eae:	e822                	sd	s0,16(sp)
    80004eb0:	e426                	sd	s1,8(sp)
    80004eb2:	e04a                	sd	s2,0(sp)
    80004eb4:	1000                	addi	s0,sp,32
    80004eb6:	84aa                	mv	s1,a0
    80004eb8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	d08080e7          	jalr	-760(ra) # 80000bc2 <acquire>
  if(writable){
    80004ec2:	02090d63          	beqz	s2,80004efc <pipeclose+0x52>
    pi->writeopen = 0;
    80004ec6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004eca:	21848513          	addi	a0,s1,536
    80004ece:	ffffd097          	auipc	ra,0xffffd
    80004ed2:	648080e7          	jalr	1608(ra) # 80002516 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ed6:	2204b783          	ld	a5,544(s1)
    80004eda:	eb95                	bnez	a5,80004f0e <pipeclose+0x64>
    release(&pi->lock);
    80004edc:	8526                	mv	a0,s1
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	d98080e7          	jalr	-616(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	aee080e7          	jalr	-1298(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004ef0:	60e2                	ld	ra,24(sp)
    80004ef2:	6442                	ld	s0,16(sp)
    80004ef4:	64a2                	ld	s1,8(sp)
    80004ef6:	6902                	ld	s2,0(sp)
    80004ef8:	6105                	addi	sp,sp,32
    80004efa:	8082                	ret
    pi->readopen = 0;
    80004efc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f00:	21c48513          	addi	a0,s1,540
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	612080e7          	jalr	1554(ra) # 80002516 <wakeup>
    80004f0c:	b7e9                	j	80004ed6 <pipeclose+0x2c>
    release(&pi->lock);
    80004f0e:	8526                	mv	a0,s1
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	d66080e7          	jalr	-666(ra) # 80000c76 <release>
}
    80004f18:	bfe1                	j	80004ef0 <pipeclose+0x46>

0000000080004f1a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f1a:	711d                	addi	sp,sp,-96
    80004f1c:	ec86                	sd	ra,88(sp)
    80004f1e:	e8a2                	sd	s0,80(sp)
    80004f20:	e4a6                	sd	s1,72(sp)
    80004f22:	e0ca                	sd	s2,64(sp)
    80004f24:	fc4e                	sd	s3,56(sp)
    80004f26:	f852                	sd	s4,48(sp)
    80004f28:	f456                	sd	s5,40(sp)
    80004f2a:	f05a                	sd	s6,32(sp)
    80004f2c:	ec5e                	sd	s7,24(sp)
    80004f2e:	e862                	sd	s8,16(sp)
    80004f30:	1080                	addi	s0,sp,96
    80004f32:	84aa                	mv	s1,a0
    80004f34:	8aae                	mv	s5,a1
    80004f36:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f38:	ffffd097          	auipc	ra,0xffffd
    80004f3c:	a48080e7          	jalr	-1464(ra) # 80001980 <myproc>
    80004f40:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f42:	8526                	mv	a0,s1
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	c7e080e7          	jalr	-898(ra) # 80000bc2 <acquire>
  while(i < n){
    80004f4c:	0b405363          	blez	s4,80004ff2 <pipewrite+0xd8>
  int i = 0;
    80004f50:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f52:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f54:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f58:	21c48b93          	addi	s7,s1,540
    80004f5c:	a089                	j	80004f9e <pipewrite+0x84>
      release(&pi->lock);
    80004f5e:	8526                	mv	a0,s1
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	d16080e7          	jalr	-746(ra) # 80000c76 <release>
      return -1;
    80004f68:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f6a:	854a                	mv	a0,s2
    80004f6c:	60e6                	ld	ra,88(sp)
    80004f6e:	6446                	ld	s0,80(sp)
    80004f70:	64a6                	ld	s1,72(sp)
    80004f72:	6906                	ld	s2,64(sp)
    80004f74:	79e2                	ld	s3,56(sp)
    80004f76:	7a42                	ld	s4,48(sp)
    80004f78:	7aa2                	ld	s5,40(sp)
    80004f7a:	7b02                	ld	s6,32(sp)
    80004f7c:	6be2                	ld	s7,24(sp)
    80004f7e:	6c42                	ld	s8,16(sp)
    80004f80:	6125                	addi	sp,sp,96
    80004f82:	8082                	ret
      wakeup(&pi->nread);
    80004f84:	8562                	mv	a0,s8
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	590080e7          	jalr	1424(ra) # 80002516 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f8e:	85a6                	mv	a1,s1
    80004f90:	855e                	mv	a0,s7
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	3f6080e7          	jalr	1014(ra) # 80002388 <sleep>
  while(i < n){
    80004f9a:	05495d63          	bge	s2,s4,80004ff4 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004f9e:	2204a783          	lw	a5,544(s1)
    80004fa2:	dfd5                	beqz	a5,80004f5e <pipewrite+0x44>
    80004fa4:	0289a783          	lw	a5,40(s3)
    80004fa8:	fbdd                	bnez	a5,80004f5e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004faa:	2184a783          	lw	a5,536(s1)
    80004fae:	21c4a703          	lw	a4,540(s1)
    80004fb2:	2007879b          	addiw	a5,a5,512
    80004fb6:	fcf707e3          	beq	a4,a5,80004f84 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fba:	4685                	li	a3,1
    80004fbc:	01590633          	add	a2,s2,s5
    80004fc0:	faf40593          	addi	a1,s0,-81
    80004fc4:	1e89b503          	ld	a0,488(s3)
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	702080e7          	jalr	1794(ra) # 800016ca <copyin>
    80004fd0:	03650263          	beq	a0,s6,80004ff4 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fd4:	21c4a783          	lw	a5,540(s1)
    80004fd8:	0017871b          	addiw	a4,a5,1
    80004fdc:	20e4ae23          	sw	a4,540(s1)
    80004fe0:	1ff7f793          	andi	a5,a5,511
    80004fe4:	97a6                	add	a5,a5,s1
    80004fe6:	faf44703          	lbu	a4,-81(s0)
    80004fea:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fee:	2905                	addiw	s2,s2,1
    80004ff0:	b76d                	j	80004f9a <pipewrite+0x80>
  int i = 0;
    80004ff2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ff4:	21848513          	addi	a0,s1,536
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	51e080e7          	jalr	1310(ra) # 80002516 <wakeup>
  release(&pi->lock);
    80005000:	8526                	mv	a0,s1
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	c74080e7          	jalr	-908(ra) # 80000c76 <release>
  return i;
    8000500a:	b785                	j	80004f6a <pipewrite+0x50>

000000008000500c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000500c:	715d                	addi	sp,sp,-80
    8000500e:	e486                	sd	ra,72(sp)
    80005010:	e0a2                	sd	s0,64(sp)
    80005012:	fc26                	sd	s1,56(sp)
    80005014:	f84a                	sd	s2,48(sp)
    80005016:	f44e                	sd	s3,40(sp)
    80005018:	f052                	sd	s4,32(sp)
    8000501a:	ec56                	sd	s5,24(sp)
    8000501c:	e85a                	sd	s6,16(sp)
    8000501e:	0880                	addi	s0,sp,80
    80005020:	84aa                	mv	s1,a0
    80005022:	892e                	mv	s2,a1
    80005024:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005026:	ffffd097          	auipc	ra,0xffffd
    8000502a:	95a080e7          	jalr	-1702(ra) # 80001980 <myproc>
    8000502e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005030:	8526                	mv	a0,s1
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	b90080e7          	jalr	-1136(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000503a:	2184a703          	lw	a4,536(s1)
    8000503e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005042:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005046:	02f71463          	bne	a4,a5,8000506e <piperead+0x62>
    8000504a:	2244a783          	lw	a5,548(s1)
    8000504e:	c385                	beqz	a5,8000506e <piperead+0x62>
    if(pr->killed){
    80005050:	028a2783          	lw	a5,40(s4)
    80005054:	ebc1                	bnez	a5,800050e4 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005056:	85a6                	mv	a1,s1
    80005058:	854e                	mv	a0,s3
    8000505a:	ffffd097          	auipc	ra,0xffffd
    8000505e:	32e080e7          	jalr	814(ra) # 80002388 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005062:	2184a703          	lw	a4,536(s1)
    80005066:	21c4a783          	lw	a5,540(s1)
    8000506a:	fef700e3          	beq	a4,a5,8000504a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000506e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005070:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005072:	05505363          	blez	s5,800050b8 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005076:	2184a783          	lw	a5,536(s1)
    8000507a:	21c4a703          	lw	a4,540(s1)
    8000507e:	02f70d63          	beq	a4,a5,800050b8 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005082:	0017871b          	addiw	a4,a5,1
    80005086:	20e4ac23          	sw	a4,536(s1)
    8000508a:	1ff7f793          	andi	a5,a5,511
    8000508e:	97a6                	add	a5,a5,s1
    80005090:	0187c783          	lbu	a5,24(a5)
    80005094:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005098:	4685                	li	a3,1
    8000509a:	fbf40613          	addi	a2,s0,-65
    8000509e:	85ca                	mv	a1,s2
    800050a0:	1e8a3503          	ld	a0,488(s4)
    800050a4:	ffffc097          	auipc	ra,0xffffc
    800050a8:	59a080e7          	jalr	1434(ra) # 8000163e <copyout>
    800050ac:	01650663          	beq	a0,s6,800050b8 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050b0:	2985                	addiw	s3,s3,1
    800050b2:	0905                	addi	s2,s2,1
    800050b4:	fd3a91e3          	bne	s5,s3,80005076 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050b8:	21c48513          	addi	a0,s1,540
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	45a080e7          	jalr	1114(ra) # 80002516 <wakeup>
  release(&pi->lock);
    800050c4:	8526                	mv	a0,s1
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	bb0080e7          	jalr	-1104(ra) # 80000c76 <release>
  return i;
}
    800050ce:	854e                	mv	a0,s3
    800050d0:	60a6                	ld	ra,72(sp)
    800050d2:	6406                	ld	s0,64(sp)
    800050d4:	74e2                	ld	s1,56(sp)
    800050d6:	7942                	ld	s2,48(sp)
    800050d8:	79a2                	ld	s3,40(sp)
    800050da:	7a02                	ld	s4,32(sp)
    800050dc:	6ae2                	ld	s5,24(sp)
    800050de:	6b42                	ld	s6,16(sp)
    800050e0:	6161                	addi	sp,sp,80
    800050e2:	8082                	ret
      release(&pi->lock);
    800050e4:	8526                	mv	a0,s1
    800050e6:	ffffc097          	auipc	ra,0xffffc
    800050ea:	b90080e7          	jalr	-1136(ra) # 80000c76 <release>
      return -1;
    800050ee:	59fd                	li	s3,-1
    800050f0:	bff9                	j	800050ce <piperead+0xc2>

00000000800050f2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050f2:	de010113          	addi	sp,sp,-544
    800050f6:	20113c23          	sd	ra,536(sp)
    800050fa:	20813823          	sd	s0,528(sp)
    800050fe:	20913423          	sd	s1,520(sp)
    80005102:	21213023          	sd	s2,512(sp)
    80005106:	ffce                	sd	s3,504(sp)
    80005108:	fbd2                	sd	s4,496(sp)
    8000510a:	f7d6                	sd	s5,488(sp)
    8000510c:	f3da                	sd	s6,480(sp)
    8000510e:	efde                	sd	s7,472(sp)
    80005110:	ebe2                	sd	s8,464(sp)
    80005112:	e7e6                	sd	s9,456(sp)
    80005114:	e3ea                	sd	s10,448(sp)
    80005116:	ff6e                	sd	s11,440(sp)
    80005118:	1400                	addi	s0,sp,544
    8000511a:	892a                	mv	s2,a0
    8000511c:	dea43423          	sd	a0,-536(s0)
    80005120:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005124:	ffffd097          	auipc	ra,0xffffd
    80005128:	85c080e7          	jalr	-1956(ra) # 80001980 <myproc>
    8000512c:	84aa                	mv	s1,a0

  begin_op();
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	4a6080e7          	jalr	1190(ra) # 800045d4 <begin_op>

  if((ip = namei(path)) == 0){
    80005136:	854a                	mv	a0,s2
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	27c080e7          	jalr	636(ra) # 800043b4 <namei>
    80005140:	c93d                	beqz	a0,800051b6 <exec+0xc4>
    80005142:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	aba080e7          	jalr	-1350(ra) # 80003bfe <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000514c:	04000713          	li	a4,64
    80005150:	4681                	li	a3,0
    80005152:	e4840613          	addi	a2,s0,-440
    80005156:	4581                	li	a1,0
    80005158:	8556                	mv	a0,s5
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	d58080e7          	jalr	-680(ra) # 80003eb2 <readi>
    80005162:	04000793          	li	a5,64
    80005166:	00f51a63          	bne	a0,a5,8000517a <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000516a:	e4842703          	lw	a4,-440(s0)
    8000516e:	464c47b7          	lui	a5,0x464c4
    80005172:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005176:	04f70663          	beq	a4,a5,800051c2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000517a:	8556                	mv	a0,s5
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	ce4080e7          	jalr	-796(ra) # 80003e60 <iunlockput>
    end_op();
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	4d0080e7          	jalr	1232(ra) # 80004654 <end_op>
  }
  return -1;
    8000518c:	557d                	li	a0,-1
}
    8000518e:	21813083          	ld	ra,536(sp)
    80005192:	21013403          	ld	s0,528(sp)
    80005196:	20813483          	ld	s1,520(sp)
    8000519a:	20013903          	ld	s2,512(sp)
    8000519e:	79fe                	ld	s3,504(sp)
    800051a0:	7a5e                	ld	s4,496(sp)
    800051a2:	7abe                	ld	s5,488(sp)
    800051a4:	7b1e                	ld	s6,480(sp)
    800051a6:	6bfe                	ld	s7,472(sp)
    800051a8:	6c5e                	ld	s8,464(sp)
    800051aa:	6cbe                	ld	s9,456(sp)
    800051ac:	6d1e                	ld	s10,448(sp)
    800051ae:	7dfa                	ld	s11,440(sp)
    800051b0:	22010113          	addi	sp,sp,544
    800051b4:	8082                	ret
    end_op();
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	49e080e7          	jalr	1182(ra) # 80004654 <end_op>
    return -1;
    800051be:	557d                	li	a0,-1
    800051c0:	b7f9                	j	8000518e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800051c2:	8526                	mv	a0,s1
    800051c4:	ffffd097          	auipc	ra,0xffffd
    800051c8:	880080e7          	jalr	-1920(ra) # 80001a44 <proc_pagetable>
    800051cc:	8b2a                	mv	s6,a0
    800051ce:	d555                	beqz	a0,8000517a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d0:	e6842783          	lw	a5,-408(s0)
    800051d4:	e8045703          	lhu	a4,-384(s0)
    800051d8:	c735                	beqz	a4,80005244 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800051da:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051dc:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800051e0:	6a05                	lui	s4,0x1
    800051e2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800051e6:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800051ea:	6d85                	lui	s11,0x1
    800051ec:	7d7d                	lui	s10,0xfffff
    800051ee:	a49d                	j	80005454 <exec+0x362>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051f0:	00003517          	auipc	a0,0x3
    800051f4:	4d850513          	addi	a0,a0,1240 # 800086c8 <syscalls+0x298>
    800051f8:	ffffb097          	auipc	ra,0xffffb
    800051fc:	332080e7          	jalr	818(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005200:	874a                	mv	a4,s2
    80005202:	009c86bb          	addw	a3,s9,s1
    80005206:	4581                	li	a1,0
    80005208:	8556                	mv	a0,s5
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	ca8080e7          	jalr	-856(ra) # 80003eb2 <readi>
    80005212:	2501                	sext.w	a0,a0
    80005214:	1ea91063          	bne	s2,a0,800053f4 <exec+0x302>
  for(i = 0; i < sz; i += PGSIZE){
    80005218:	009d84bb          	addw	s1,s11,s1
    8000521c:	013d09bb          	addw	s3,s10,s3
    80005220:	2174fa63          	bgeu	s1,s7,80005434 <exec+0x342>
    pa = walkaddr(pagetable, va + i);
    80005224:	02049593          	slli	a1,s1,0x20
    80005228:	9181                	srli	a1,a1,0x20
    8000522a:	95e2                	add	a1,a1,s8
    8000522c:	855a                	mv	a0,s6
    8000522e:	ffffc097          	auipc	ra,0xffffc
    80005232:	e1e080e7          	jalr	-482(ra) # 8000104c <walkaddr>
    80005236:	862a                	mv	a2,a0
    if(pa == 0)
    80005238:	dd45                	beqz	a0,800051f0 <exec+0xfe>
      n = PGSIZE;
    8000523a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000523c:	fd49f2e3          	bgeu	s3,s4,80005200 <exec+0x10e>
      n = sz - i;
    80005240:	894e                	mv	s2,s3
    80005242:	bf7d                	j	80005200 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005244:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005246:	e0043423          	sd	zero,-504(s0)
  iunlockput(ip);
    8000524a:	8556                	mv	a0,s5
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	c14080e7          	jalr	-1004(ra) # 80003e60 <iunlockput>
  end_op();
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	400080e7          	jalr	1024(ra) # 80004654 <end_op>
  p = myproc();
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	724080e7          	jalr	1828(ra) # 80001980 <myproc>
    80005264:	8a2a                	mv	s4,a0
  uint64 oldsz = p->sz;
    80005266:	1e053d03          	ld	s10,480(a0)
  sz = PGROUNDUP(sz);
    8000526a:	6785                	lui	a5,0x1
    8000526c:	17fd                	addi	a5,a5,-1
    8000526e:	94be                	add	s1,s1,a5
    80005270:	77fd                	lui	a5,0xfffff
    80005272:	8fe5                	and	a5,a5,s1
    80005274:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005278:	6609                	lui	a2,0x2
    8000527a:	963e                	add	a2,a2,a5
    8000527c:	85be                	mv	a1,a5
    8000527e:	855a                	mv	a0,s6
    80005280:	ffffc097          	auipc	ra,0xffffc
    80005284:	16e080e7          	jalr	366(ra) # 800013ee <uvmalloc>
    80005288:	8caa                	mv	s9,a0
  ip = 0;
    8000528a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000528c:	16050463          	beqz	a0,800053f4 <exec+0x302>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005290:	75f9                	lui	a1,0xffffe
    80005292:	95aa                	add	a1,a1,a0
    80005294:	855a                	mv	a0,s6
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	376080e7          	jalr	886(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    8000529e:	7bfd                	lui	s7,0xfffff
    800052a0:	9be6                	add	s7,s7,s9
  for(argc = 0; argv[argc]; argc++) {
    800052a2:	df043783          	ld	a5,-528(s0)
    800052a6:	6388                	ld	a0,0(a5)
    800052a8:	c925                	beqz	a0,80005318 <exec+0x226>
    800052aa:	e8840993          	addi	s3,s0,-376
    800052ae:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    800052b2:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    800052b4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052b6:	ffffc097          	auipc	ra,0xffffc
    800052ba:	b8c080e7          	jalr	-1140(ra) # 80000e42 <strlen>
    800052be:	0015079b          	addiw	a5,a0,1
    800052c2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052c6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052ca:	15796963          	bltu	s2,s7,8000541c <exec+0x32a>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052ce:	df043d83          	ld	s11,-528(s0)
    800052d2:	000dba83          	ld	s5,0(s11) # 1000 <_entry-0x7ffff000>
    800052d6:	8556                	mv	a0,s5
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	b6a080e7          	jalr	-1174(ra) # 80000e42 <strlen>
    800052e0:	0015069b          	addiw	a3,a0,1
    800052e4:	8656                	mv	a2,s5
    800052e6:	85ca                	mv	a1,s2
    800052e8:	855a                	mv	a0,s6
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	354080e7          	jalr	852(ra) # 8000163e <copyout>
    800052f2:	12054963          	bltz	a0,80005424 <exec+0x332>
    ustack[argc] = sp;
    800052f6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052fa:	0485                	addi	s1,s1,1
    800052fc:	008d8793          	addi	a5,s11,8
    80005300:	def43823          	sd	a5,-528(s0)
    80005304:	008db503          	ld	a0,8(s11)
    80005308:	c911                	beqz	a0,8000531c <exec+0x22a>
    if(argc >= MAXARG)
    8000530a:	09a1                	addi	s3,s3,8
    8000530c:	fb8995e3          	bne	s3,s8,800052b6 <exec+0x1c4>
  sz = sz1;
    80005310:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    80005314:	4a81                	li	s5,0
    80005316:	a8f9                	j	800053f4 <exec+0x302>
  sp = sz;
    80005318:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    8000531a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000531c:	00349793          	slli	a5,s1,0x3
    80005320:	f9040713          	addi	a4,s0,-112
    80005324:	97ba                	add	a5,a5,a4
    80005326:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd2ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000532a:	00148693          	addi	a3,s1,1
    8000532e:	068e                	slli	a3,a3,0x3
    80005330:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005334:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005338:	01797663          	bgeu	s2,s7,80005344 <exec+0x252>
  sz = sz1;
    8000533c:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    80005340:	4a81                	li	s5,0
    80005342:	a84d                	j	800053f4 <exec+0x302>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005344:	e8840613          	addi	a2,s0,-376
    80005348:	85ca                	mv	a1,s2
    8000534a:	855a                	mv	a0,s6
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	2f2080e7          	jalr	754(ra) # 8000163e <copyout>
    80005354:	0c054c63          	bltz	a0,8000542c <exec+0x33a>
  p->trapframe->a1 = sp;
    80005358:	1f0a3783          	ld	a5,496(s4)
    8000535c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005360:	de843783          	ld	a5,-536(s0)
    80005364:	0007c703          	lbu	a4,0(a5)
    80005368:	cf11                	beqz	a4,80005384 <exec+0x292>
    8000536a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000536c:	02f00693          	li	a3,47
    80005370:	a039                	j	8000537e <exec+0x28c>
      last = s+1;
    80005372:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005376:	0785                	addi	a5,a5,1
    80005378:	fff7c703          	lbu	a4,-1(a5)
    8000537c:	c701                	beqz	a4,80005384 <exec+0x292>
    if(*s == '/')
    8000537e:	fed71ce3          	bne	a4,a3,80005376 <exec+0x284>
    80005382:	bfc5                	j	80005372 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005384:	4641                	li	a2,16
    80005386:	de843583          	ld	a1,-536(s0)
    8000538a:	2f0a0513          	addi	a0,s4,752
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	a82080e7          	jalr	-1406(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005396:	1e8a3503          	ld	a0,488(s4)
  p->pagetable = pagetable;
    8000539a:	1f6a3423          	sd	s6,488(s4)
  p->sz = sz;
    8000539e:	1f9a3023          	sd	s9,480(s4)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053a2:	1f0a3783          	ld	a5,496(s4)
    800053a6:	e6043703          	ld	a4,-416(s0)
    800053aa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053ac:	1f0a3783          	ld	a5,496(s4)
    800053b0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053b4:	85ea                	mv	a1,s10
    800053b6:	ffffc097          	auipc	ra,0xffffc
    800053ba:	72a080e7          	jalr	1834(ra) # 80001ae0 <proc_freepagetable>
  for(int signum=0; i<SIG_NUM; signum++){
    800053be:	47fd                	li	a5,31
    800053c0:	e0843703          	ld	a4,-504(s0)
    800053c4:	02e7c363          	blt	a5,a4,800053ea <exec+0x2f8>
    800053c8:	140a0793          	addi	a5,s4,320
    800053cc:	040a0a13          	addi	s4,s4,64
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    800053d0:	4705                	li	a4,1
    800053d2:	a019                	j	800053d8 <exec+0x2e6>
  for(int signum=0; i<SIG_NUM; signum++){
    800053d4:	0791                	addi	a5,a5,4
    800053d6:	0a21                	addi	s4,s4,8
    p->signal_handlers_masks[signum] = 0;
    800053d8:	0007a023          	sw	zero,0(a5)
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    800053dc:	000a3683          	ld	a3,0(s4)
    800053e0:	fee68ae3          	beq	a3,a4,800053d4 <exec+0x2e2>
      p->signal_handlers[signum] = SIG_DFL;
    800053e4:	000a3023          	sd	zero,0(s4)
    800053e8:	b7f5                	j	800053d4 <exec+0x2e2>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053ea:	0004851b          	sext.w	a0,s1
    800053ee:	b345                	j	8000518e <exec+0x9c>
    800053f0:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800053f4:	df843583          	ld	a1,-520(s0)
    800053f8:	855a                	mv	a0,s6
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	6e6080e7          	jalr	1766(ra) # 80001ae0 <proc_freepagetable>
  if(ip){
    80005402:	d60a9ce3          	bnez	s5,8000517a <exec+0x88>
  return -1;
    80005406:	557d                	li	a0,-1
    80005408:	b359                	j	8000518e <exec+0x9c>
    8000540a:	de943c23          	sd	s1,-520(s0)
    8000540e:	b7dd                	j	800053f4 <exec+0x302>
    80005410:	de943c23          	sd	s1,-520(s0)
    80005414:	b7c5                	j	800053f4 <exec+0x302>
    80005416:	de943c23          	sd	s1,-520(s0)
    8000541a:	bfe9                	j	800053f4 <exec+0x302>
  sz = sz1;
    8000541c:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    80005420:	4a81                	li	s5,0
    80005422:	bfc9                	j	800053f4 <exec+0x302>
  sz = sz1;
    80005424:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    80005428:	4a81                	li	s5,0
    8000542a:	b7e9                	j	800053f4 <exec+0x302>
  sz = sz1;
    8000542c:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    80005430:	4a81                	li	s5,0
    80005432:	b7c9                	j	800053f4 <exec+0x302>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005434:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005438:	e0843783          	ld	a5,-504(s0)
    8000543c:	0017869b          	addiw	a3,a5,1
    80005440:	e0d43423          	sd	a3,-504(s0)
    80005444:	e0043783          	ld	a5,-512(s0)
    80005448:	0387879b          	addiw	a5,a5,56
    8000544c:	e8045703          	lhu	a4,-384(s0)
    80005450:	dee6dde3          	bge	a3,a4,8000524a <exec+0x158>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005454:	2781                	sext.w	a5,a5
    80005456:	e0f43023          	sd	a5,-512(s0)
    8000545a:	03800713          	li	a4,56
    8000545e:	86be                	mv	a3,a5
    80005460:	e1040613          	addi	a2,s0,-496
    80005464:	4581                	li	a1,0
    80005466:	8556                	mv	a0,s5
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	a4a080e7          	jalr	-1462(ra) # 80003eb2 <readi>
    80005470:	03800793          	li	a5,56
    80005474:	f6f51ee3          	bne	a0,a5,800053f0 <exec+0x2fe>
    if(ph.type != ELF_PROG_LOAD)
    80005478:	e1042783          	lw	a5,-496(s0)
    8000547c:	4705                	li	a4,1
    8000547e:	fae79de3          	bne	a5,a4,80005438 <exec+0x346>
    if(ph.memsz < ph.filesz)
    80005482:	e3843603          	ld	a2,-456(s0)
    80005486:	e3043783          	ld	a5,-464(s0)
    8000548a:	f8f660e3          	bltu	a2,a5,8000540a <exec+0x318>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000548e:	e2043783          	ld	a5,-480(s0)
    80005492:	963e                	add	a2,a2,a5
    80005494:	f6f66ee3          	bltu	a2,a5,80005410 <exec+0x31e>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005498:	85a6                	mv	a1,s1
    8000549a:	855a                	mv	a0,s6
    8000549c:	ffffc097          	auipc	ra,0xffffc
    800054a0:	f52080e7          	jalr	-174(ra) # 800013ee <uvmalloc>
    800054a4:	dea43c23          	sd	a0,-520(s0)
    800054a8:	d53d                	beqz	a0,80005416 <exec+0x324>
    if(ph.vaddr % PGSIZE != 0)
    800054aa:	e2043c03          	ld	s8,-480(s0)
    800054ae:	de043783          	ld	a5,-544(s0)
    800054b2:	00fc77b3          	and	a5,s8,a5
    800054b6:	ff9d                	bnez	a5,800053f4 <exec+0x302>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054b8:	e1842c83          	lw	s9,-488(s0)
    800054bc:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054c0:	f60b8ae3          	beqz	s7,80005434 <exec+0x342>
    800054c4:	89de                	mv	s3,s7
    800054c6:	4481                	li	s1,0
    800054c8:	bbb1                	j	80005224 <exec+0x132>

00000000800054ca <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054ca:	7179                	addi	sp,sp,-48
    800054cc:	f406                	sd	ra,40(sp)
    800054ce:	f022                	sd	s0,32(sp)
    800054d0:	ec26                	sd	s1,24(sp)
    800054d2:	e84a                	sd	s2,16(sp)
    800054d4:	1800                	addi	s0,sp,48
    800054d6:	892e                	mv	s2,a1
    800054d8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054da:	fdc40593          	addi	a1,s0,-36
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	adc080e7          	jalr	-1316(ra) # 80002fba <argint>
    800054e6:	04054063          	bltz	a0,80005526 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054ea:	fdc42703          	lw	a4,-36(s0)
    800054ee:	47bd                	li	a5,15
    800054f0:	02e7ed63          	bltu	a5,a4,8000552a <argfd+0x60>
    800054f4:	ffffc097          	auipc	ra,0xffffc
    800054f8:	48c080e7          	jalr	1164(ra) # 80001980 <myproc>
    800054fc:	fdc42703          	lw	a4,-36(s0)
    80005500:	04c70793          	addi	a5,a4,76
    80005504:	078e                	slli	a5,a5,0x3
    80005506:	953e                	add	a0,a0,a5
    80005508:	651c                	ld	a5,8(a0)
    8000550a:	c395                	beqz	a5,8000552e <argfd+0x64>
    return -1;
  if(pfd)
    8000550c:	00090463          	beqz	s2,80005514 <argfd+0x4a>
    *pfd = fd;
    80005510:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005514:	4501                	li	a0,0
  if(pf)
    80005516:	c091                	beqz	s1,8000551a <argfd+0x50>
    *pf = f;
    80005518:	e09c                	sd	a5,0(s1)
}
    8000551a:	70a2                	ld	ra,40(sp)
    8000551c:	7402                	ld	s0,32(sp)
    8000551e:	64e2                	ld	s1,24(sp)
    80005520:	6942                	ld	s2,16(sp)
    80005522:	6145                	addi	sp,sp,48
    80005524:	8082                	ret
    return -1;
    80005526:	557d                	li	a0,-1
    80005528:	bfcd                	j	8000551a <argfd+0x50>
    return -1;
    8000552a:	557d                	li	a0,-1
    8000552c:	b7fd                	j	8000551a <argfd+0x50>
    8000552e:	557d                	li	a0,-1
    80005530:	b7ed                	j	8000551a <argfd+0x50>

0000000080005532 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005532:	1101                	addi	sp,sp,-32
    80005534:	ec06                	sd	ra,24(sp)
    80005536:	e822                	sd	s0,16(sp)
    80005538:	e426                	sd	s1,8(sp)
    8000553a:	1000                	addi	s0,sp,32
    8000553c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000553e:	ffffc097          	auipc	ra,0xffffc
    80005542:	442080e7          	jalr	1090(ra) # 80001980 <myproc>
    80005546:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005548:	26850793          	addi	a5,a0,616
    8000554c:	4501                	li	a0,0
    8000554e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005550:	6398                	ld	a4,0(a5)
    80005552:	cb19                	beqz	a4,80005568 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005554:	2505                	addiw	a0,a0,1
    80005556:	07a1                	addi	a5,a5,8
    80005558:	fed51ce3          	bne	a0,a3,80005550 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000555c:	557d                	li	a0,-1
}
    8000555e:	60e2                	ld	ra,24(sp)
    80005560:	6442                	ld	s0,16(sp)
    80005562:	64a2                	ld	s1,8(sp)
    80005564:	6105                	addi	sp,sp,32
    80005566:	8082                	ret
      p->ofile[fd] = f;
    80005568:	04c50793          	addi	a5,a0,76
    8000556c:	078e                	slli	a5,a5,0x3
    8000556e:	963e                	add	a2,a2,a5
    80005570:	e604                	sd	s1,8(a2)
      return fd;
    80005572:	b7f5                	j	8000555e <fdalloc+0x2c>

0000000080005574 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005574:	715d                	addi	sp,sp,-80
    80005576:	e486                	sd	ra,72(sp)
    80005578:	e0a2                	sd	s0,64(sp)
    8000557a:	fc26                	sd	s1,56(sp)
    8000557c:	f84a                	sd	s2,48(sp)
    8000557e:	f44e                	sd	s3,40(sp)
    80005580:	f052                	sd	s4,32(sp)
    80005582:	ec56                	sd	s5,24(sp)
    80005584:	0880                	addi	s0,sp,80
    80005586:	89ae                	mv	s3,a1
    80005588:	8ab2                	mv	s5,a2
    8000558a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000558c:	fb040593          	addi	a1,s0,-80
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	e42080e7          	jalr	-446(ra) # 800043d2 <nameiparent>
    80005598:	892a                	mv	s2,a0
    8000559a:	12050e63          	beqz	a0,800056d6 <create+0x162>
    return 0;

  ilock(dp);
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	660080e7          	jalr	1632(ra) # 80003bfe <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055a6:	4601                	li	a2,0
    800055a8:	fb040593          	addi	a1,s0,-80
    800055ac:	854a                	mv	a0,s2
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	b34080e7          	jalr	-1228(ra) # 800040e2 <dirlookup>
    800055b6:	84aa                	mv	s1,a0
    800055b8:	c921                	beqz	a0,80005608 <create+0x94>
    iunlockput(dp);
    800055ba:	854a                	mv	a0,s2
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	8a4080e7          	jalr	-1884(ra) # 80003e60 <iunlockput>
    ilock(ip);
    800055c4:	8526                	mv	a0,s1
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	638080e7          	jalr	1592(ra) # 80003bfe <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055ce:	2981                	sext.w	s3,s3
    800055d0:	4789                	li	a5,2
    800055d2:	02f99463          	bne	s3,a5,800055fa <create+0x86>
    800055d6:	0444d783          	lhu	a5,68(s1)
    800055da:	37f9                	addiw	a5,a5,-2
    800055dc:	17c2                	slli	a5,a5,0x30
    800055de:	93c1                	srli	a5,a5,0x30
    800055e0:	4705                	li	a4,1
    800055e2:	00f76c63          	bltu	a4,a5,800055fa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800055e6:	8526                	mv	a0,s1
    800055e8:	60a6                	ld	ra,72(sp)
    800055ea:	6406                	ld	s0,64(sp)
    800055ec:	74e2                	ld	s1,56(sp)
    800055ee:	7942                	ld	s2,48(sp)
    800055f0:	79a2                	ld	s3,40(sp)
    800055f2:	7a02                	ld	s4,32(sp)
    800055f4:	6ae2                	ld	s5,24(sp)
    800055f6:	6161                	addi	sp,sp,80
    800055f8:	8082                	ret
    iunlockput(ip);
    800055fa:	8526                	mv	a0,s1
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	864080e7          	jalr	-1948(ra) # 80003e60 <iunlockput>
    return 0;
    80005604:	4481                	li	s1,0
    80005606:	b7c5                	j	800055e6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005608:	85ce                	mv	a1,s3
    8000560a:	00092503          	lw	a0,0(s2)
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	458080e7          	jalr	1112(ra) # 80003a66 <ialloc>
    80005616:	84aa                	mv	s1,a0
    80005618:	c521                	beqz	a0,80005660 <create+0xec>
  ilock(ip);
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	5e4080e7          	jalr	1508(ra) # 80003bfe <ilock>
  ip->major = major;
    80005622:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005626:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000562a:	4a05                	li	s4,1
    8000562c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	502080e7          	jalr	1282(ra) # 80003b34 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000563a:	2981                	sext.w	s3,s3
    8000563c:	03498a63          	beq	s3,s4,80005670 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005640:	40d0                	lw	a2,4(s1)
    80005642:	fb040593          	addi	a1,s0,-80
    80005646:	854a                	mv	a0,s2
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	caa080e7          	jalr	-854(ra) # 800042f2 <dirlink>
    80005650:	06054b63          	bltz	a0,800056c6 <create+0x152>
  iunlockput(dp);
    80005654:	854a                	mv	a0,s2
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	80a080e7          	jalr	-2038(ra) # 80003e60 <iunlockput>
  return ip;
    8000565e:	b761                	j	800055e6 <create+0x72>
    panic("create: ialloc");
    80005660:	00003517          	auipc	a0,0x3
    80005664:	08850513          	addi	a0,a0,136 # 800086e8 <syscalls+0x2b8>
    80005668:	ffffb097          	auipc	ra,0xffffb
    8000566c:	ec2080e7          	jalr	-318(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005670:	04a95783          	lhu	a5,74(s2)
    80005674:	2785                	addiw	a5,a5,1
    80005676:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000567a:	854a                	mv	a0,s2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	4b8080e7          	jalr	1208(ra) # 80003b34 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005684:	40d0                	lw	a2,4(s1)
    80005686:	00003597          	auipc	a1,0x3
    8000568a:	07258593          	addi	a1,a1,114 # 800086f8 <syscalls+0x2c8>
    8000568e:	8526                	mv	a0,s1
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	c62080e7          	jalr	-926(ra) # 800042f2 <dirlink>
    80005698:	00054f63          	bltz	a0,800056b6 <create+0x142>
    8000569c:	00492603          	lw	a2,4(s2)
    800056a0:	00003597          	auipc	a1,0x3
    800056a4:	06058593          	addi	a1,a1,96 # 80008700 <syscalls+0x2d0>
    800056a8:	8526                	mv	a0,s1
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	c48080e7          	jalr	-952(ra) # 800042f2 <dirlink>
    800056b2:	f80557e3          	bgez	a0,80005640 <create+0xcc>
      panic("create dots");
    800056b6:	00003517          	auipc	a0,0x3
    800056ba:	05250513          	addi	a0,a0,82 # 80008708 <syscalls+0x2d8>
    800056be:	ffffb097          	auipc	ra,0xffffb
    800056c2:	e6c080e7          	jalr	-404(ra) # 8000052a <panic>
    panic("create: dirlink");
    800056c6:	00003517          	auipc	a0,0x3
    800056ca:	05250513          	addi	a0,a0,82 # 80008718 <syscalls+0x2e8>
    800056ce:	ffffb097          	auipc	ra,0xffffb
    800056d2:	e5c080e7          	jalr	-420(ra) # 8000052a <panic>
    return 0;
    800056d6:	84aa                	mv	s1,a0
    800056d8:	b739                	j	800055e6 <create+0x72>

00000000800056da <sys_dup>:
{
    800056da:	7179                	addi	sp,sp,-48
    800056dc:	f406                	sd	ra,40(sp)
    800056de:	f022                	sd	s0,32(sp)
    800056e0:	ec26                	sd	s1,24(sp)
    800056e2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056e4:	fd840613          	addi	a2,s0,-40
    800056e8:	4581                	li	a1,0
    800056ea:	4501                	li	a0,0
    800056ec:	00000097          	auipc	ra,0x0
    800056f0:	dde080e7          	jalr	-546(ra) # 800054ca <argfd>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056f6:	02054363          	bltz	a0,8000571c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056fa:	fd843503          	ld	a0,-40(s0)
    800056fe:	00000097          	auipc	ra,0x0
    80005702:	e34080e7          	jalr	-460(ra) # 80005532 <fdalloc>
    80005706:	84aa                	mv	s1,a0
    return -1;
    80005708:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000570a:	00054963          	bltz	a0,8000571c <sys_dup+0x42>
  filedup(f);
    8000570e:	fd843503          	ld	a0,-40(s0)
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	33c080e7          	jalr	828(ra) # 80004a4e <filedup>
  return fd;
    8000571a:	87a6                	mv	a5,s1
}
    8000571c:	853e                	mv	a0,a5
    8000571e:	70a2                	ld	ra,40(sp)
    80005720:	7402                	ld	s0,32(sp)
    80005722:	64e2                	ld	s1,24(sp)
    80005724:	6145                	addi	sp,sp,48
    80005726:	8082                	ret

0000000080005728 <sys_read>:
{
    80005728:	7179                	addi	sp,sp,-48
    8000572a:	f406                	sd	ra,40(sp)
    8000572c:	f022                	sd	s0,32(sp)
    8000572e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005730:	fe840613          	addi	a2,s0,-24
    80005734:	4581                	li	a1,0
    80005736:	4501                	li	a0,0
    80005738:	00000097          	auipc	ra,0x0
    8000573c:	d92080e7          	jalr	-622(ra) # 800054ca <argfd>
    return -1;
    80005740:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005742:	04054163          	bltz	a0,80005784 <sys_read+0x5c>
    80005746:	fe440593          	addi	a1,s0,-28
    8000574a:	4509                	li	a0,2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	86e080e7          	jalr	-1938(ra) # 80002fba <argint>
    return -1;
    80005754:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005756:	02054763          	bltz	a0,80005784 <sys_read+0x5c>
    8000575a:	fd840593          	addi	a1,s0,-40
    8000575e:	4505                	li	a0,1
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	87c080e7          	jalr	-1924(ra) # 80002fdc <argaddr>
    return -1;
    80005768:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000576a:	00054d63          	bltz	a0,80005784 <sys_read+0x5c>
  return fileread(f, p, n);
    8000576e:	fe442603          	lw	a2,-28(s0)
    80005772:	fd843583          	ld	a1,-40(s0)
    80005776:	fe843503          	ld	a0,-24(s0)
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	460080e7          	jalr	1120(ra) # 80004bda <fileread>
    80005782:	87aa                	mv	a5,a0
}
    80005784:	853e                	mv	a0,a5
    80005786:	70a2                	ld	ra,40(sp)
    80005788:	7402                	ld	s0,32(sp)
    8000578a:	6145                	addi	sp,sp,48
    8000578c:	8082                	ret

000000008000578e <sys_write>:
{
    8000578e:	7179                	addi	sp,sp,-48
    80005790:	f406                	sd	ra,40(sp)
    80005792:	f022                	sd	s0,32(sp)
    80005794:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005796:	fe840613          	addi	a2,s0,-24
    8000579a:	4581                	li	a1,0
    8000579c:	4501                	li	a0,0
    8000579e:	00000097          	auipc	ra,0x0
    800057a2:	d2c080e7          	jalr	-724(ra) # 800054ca <argfd>
    return -1;
    800057a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a8:	04054163          	bltz	a0,800057ea <sys_write+0x5c>
    800057ac:	fe440593          	addi	a1,s0,-28
    800057b0:	4509                	li	a0,2
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	808080e7          	jalr	-2040(ra) # 80002fba <argint>
    return -1;
    800057ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057bc:	02054763          	bltz	a0,800057ea <sys_write+0x5c>
    800057c0:	fd840593          	addi	a1,s0,-40
    800057c4:	4505                	li	a0,1
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	816080e7          	jalr	-2026(ra) # 80002fdc <argaddr>
    return -1;
    800057ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057d0:	00054d63          	bltz	a0,800057ea <sys_write+0x5c>
  return filewrite(f, p, n);
    800057d4:	fe442603          	lw	a2,-28(s0)
    800057d8:	fd843583          	ld	a1,-40(s0)
    800057dc:	fe843503          	ld	a0,-24(s0)
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	4bc080e7          	jalr	1212(ra) # 80004c9c <filewrite>
    800057e8:	87aa                	mv	a5,a0
}
    800057ea:	853e                	mv	a0,a5
    800057ec:	70a2                	ld	ra,40(sp)
    800057ee:	7402                	ld	s0,32(sp)
    800057f0:	6145                	addi	sp,sp,48
    800057f2:	8082                	ret

00000000800057f4 <sys_close>:
{
    800057f4:	1101                	addi	sp,sp,-32
    800057f6:	ec06                	sd	ra,24(sp)
    800057f8:	e822                	sd	s0,16(sp)
    800057fa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057fc:	fe040613          	addi	a2,s0,-32
    80005800:	fec40593          	addi	a1,s0,-20
    80005804:	4501                	li	a0,0
    80005806:	00000097          	auipc	ra,0x0
    8000580a:	cc4080e7          	jalr	-828(ra) # 800054ca <argfd>
    return -1;
    8000580e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005810:	02054563          	bltz	a0,8000583a <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005814:	ffffc097          	auipc	ra,0xffffc
    80005818:	16c080e7          	jalr	364(ra) # 80001980 <myproc>
    8000581c:	fec42783          	lw	a5,-20(s0)
    80005820:	04c78793          	addi	a5,a5,76
    80005824:	078e                	slli	a5,a5,0x3
    80005826:	97aa                	add	a5,a5,a0
    80005828:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000582c:	fe043503          	ld	a0,-32(s0)
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	270080e7          	jalr	624(ra) # 80004aa0 <fileclose>
  return 0;
    80005838:	4781                	li	a5,0
}
    8000583a:	853e                	mv	a0,a5
    8000583c:	60e2                	ld	ra,24(sp)
    8000583e:	6442                	ld	s0,16(sp)
    80005840:	6105                	addi	sp,sp,32
    80005842:	8082                	ret

0000000080005844 <sys_fstat>:
{
    80005844:	1101                	addi	sp,sp,-32
    80005846:	ec06                	sd	ra,24(sp)
    80005848:	e822                	sd	s0,16(sp)
    8000584a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000584c:	fe840613          	addi	a2,s0,-24
    80005850:	4581                	li	a1,0
    80005852:	4501                	li	a0,0
    80005854:	00000097          	auipc	ra,0x0
    80005858:	c76080e7          	jalr	-906(ra) # 800054ca <argfd>
    return -1;
    8000585c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000585e:	02054563          	bltz	a0,80005888 <sys_fstat+0x44>
    80005862:	fe040593          	addi	a1,s0,-32
    80005866:	4505                	li	a0,1
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	774080e7          	jalr	1908(ra) # 80002fdc <argaddr>
    return -1;
    80005870:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005872:	00054b63          	bltz	a0,80005888 <sys_fstat+0x44>
  return filestat(f, st);
    80005876:	fe043583          	ld	a1,-32(s0)
    8000587a:	fe843503          	ld	a0,-24(s0)
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	2ea080e7          	jalr	746(ra) # 80004b68 <filestat>
    80005886:	87aa                	mv	a5,a0
}
    80005888:	853e                	mv	a0,a5
    8000588a:	60e2                	ld	ra,24(sp)
    8000588c:	6442                	ld	s0,16(sp)
    8000588e:	6105                	addi	sp,sp,32
    80005890:	8082                	ret

0000000080005892 <sys_link>:
{
    80005892:	7169                	addi	sp,sp,-304
    80005894:	f606                	sd	ra,296(sp)
    80005896:	f222                	sd	s0,288(sp)
    80005898:	ee26                	sd	s1,280(sp)
    8000589a:	ea4a                	sd	s2,272(sp)
    8000589c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000589e:	08000613          	li	a2,128
    800058a2:	ed040593          	addi	a1,s0,-304
    800058a6:	4501                	li	a0,0
    800058a8:	ffffd097          	auipc	ra,0xffffd
    800058ac:	756080e7          	jalr	1878(ra) # 80002ffe <argstr>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058b2:	10054e63          	bltz	a0,800059ce <sys_link+0x13c>
    800058b6:	08000613          	li	a2,128
    800058ba:	f5040593          	addi	a1,s0,-176
    800058be:	4505                	li	a0,1
    800058c0:	ffffd097          	auipc	ra,0xffffd
    800058c4:	73e080e7          	jalr	1854(ra) # 80002ffe <argstr>
    return -1;
    800058c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ca:	10054263          	bltz	a0,800059ce <sys_link+0x13c>
  begin_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	d06080e7          	jalr	-762(ra) # 800045d4 <begin_op>
  if((ip = namei(old)) == 0){
    800058d6:	ed040513          	addi	a0,s0,-304
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	ada080e7          	jalr	-1318(ra) # 800043b4 <namei>
    800058e2:	84aa                	mv	s1,a0
    800058e4:	c551                	beqz	a0,80005970 <sys_link+0xde>
  ilock(ip);
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	318080e7          	jalr	792(ra) # 80003bfe <ilock>
  if(ip->type == T_DIR){
    800058ee:	04449703          	lh	a4,68(s1)
    800058f2:	4785                	li	a5,1
    800058f4:	08f70463          	beq	a4,a5,8000597c <sys_link+0xea>
  ip->nlink++;
    800058f8:	04a4d783          	lhu	a5,74(s1)
    800058fc:	2785                	addiw	a5,a5,1
    800058fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005902:	8526                	mv	a0,s1
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	230080e7          	jalr	560(ra) # 80003b34 <iupdate>
  iunlock(ip);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	3b2080e7          	jalr	946(ra) # 80003cc0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005916:	fd040593          	addi	a1,s0,-48
    8000591a:	f5040513          	addi	a0,s0,-176
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	ab4080e7          	jalr	-1356(ra) # 800043d2 <nameiparent>
    80005926:	892a                	mv	s2,a0
    80005928:	c935                	beqz	a0,8000599c <sys_link+0x10a>
  ilock(dp);
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	2d4080e7          	jalr	724(ra) # 80003bfe <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005932:	00092703          	lw	a4,0(s2)
    80005936:	409c                	lw	a5,0(s1)
    80005938:	04f71d63          	bne	a4,a5,80005992 <sys_link+0x100>
    8000593c:	40d0                	lw	a2,4(s1)
    8000593e:	fd040593          	addi	a1,s0,-48
    80005942:	854a                	mv	a0,s2
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	9ae080e7          	jalr	-1618(ra) # 800042f2 <dirlink>
    8000594c:	04054363          	bltz	a0,80005992 <sys_link+0x100>
  iunlockput(dp);
    80005950:	854a                	mv	a0,s2
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	50e080e7          	jalr	1294(ra) # 80003e60 <iunlockput>
  iput(ip);
    8000595a:	8526                	mv	a0,s1
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	45c080e7          	jalr	1116(ra) # 80003db8 <iput>
  end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	cf0080e7          	jalr	-784(ra) # 80004654 <end_op>
  return 0;
    8000596c:	4781                	li	a5,0
    8000596e:	a085                	j	800059ce <sys_link+0x13c>
    end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	ce4080e7          	jalr	-796(ra) # 80004654 <end_op>
    return -1;
    80005978:	57fd                	li	a5,-1
    8000597a:	a891                	j	800059ce <sys_link+0x13c>
    iunlockput(ip);
    8000597c:	8526                	mv	a0,s1
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	4e2080e7          	jalr	1250(ra) # 80003e60 <iunlockput>
    end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	cce080e7          	jalr	-818(ra) # 80004654 <end_op>
    return -1;
    8000598e:	57fd                	li	a5,-1
    80005990:	a83d                	j	800059ce <sys_link+0x13c>
    iunlockput(dp);
    80005992:	854a                	mv	a0,s2
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	4cc080e7          	jalr	1228(ra) # 80003e60 <iunlockput>
  ilock(ip);
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	260080e7          	jalr	608(ra) # 80003bfe <ilock>
  ip->nlink--;
    800059a6:	04a4d783          	lhu	a5,74(s1)
    800059aa:	37fd                	addiw	a5,a5,-1
    800059ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	182080e7          	jalr	386(ra) # 80003b34 <iupdate>
  iunlockput(ip);
    800059ba:	8526                	mv	a0,s1
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	4a4080e7          	jalr	1188(ra) # 80003e60 <iunlockput>
  end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	c90080e7          	jalr	-880(ra) # 80004654 <end_op>
  return -1;
    800059cc:	57fd                	li	a5,-1
}
    800059ce:	853e                	mv	a0,a5
    800059d0:	70b2                	ld	ra,296(sp)
    800059d2:	7412                	ld	s0,288(sp)
    800059d4:	64f2                	ld	s1,280(sp)
    800059d6:	6952                	ld	s2,272(sp)
    800059d8:	6155                	addi	sp,sp,304
    800059da:	8082                	ret

00000000800059dc <sys_unlink>:
{
    800059dc:	7151                	addi	sp,sp,-240
    800059de:	f586                	sd	ra,232(sp)
    800059e0:	f1a2                	sd	s0,224(sp)
    800059e2:	eda6                	sd	s1,216(sp)
    800059e4:	e9ca                	sd	s2,208(sp)
    800059e6:	e5ce                	sd	s3,200(sp)
    800059e8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059ea:	08000613          	li	a2,128
    800059ee:	f3040593          	addi	a1,s0,-208
    800059f2:	4501                	li	a0,0
    800059f4:	ffffd097          	auipc	ra,0xffffd
    800059f8:	60a080e7          	jalr	1546(ra) # 80002ffe <argstr>
    800059fc:	18054163          	bltz	a0,80005b7e <sys_unlink+0x1a2>
  begin_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	bd4080e7          	jalr	-1068(ra) # 800045d4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a08:	fb040593          	addi	a1,s0,-80
    80005a0c:	f3040513          	addi	a0,s0,-208
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	9c2080e7          	jalr	-1598(ra) # 800043d2 <nameiparent>
    80005a18:	84aa                	mv	s1,a0
    80005a1a:	c979                	beqz	a0,80005af0 <sys_unlink+0x114>
  ilock(dp);
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	1e2080e7          	jalr	482(ra) # 80003bfe <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a24:	00003597          	auipc	a1,0x3
    80005a28:	cd458593          	addi	a1,a1,-812 # 800086f8 <syscalls+0x2c8>
    80005a2c:	fb040513          	addi	a0,s0,-80
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	698080e7          	jalr	1688(ra) # 800040c8 <namecmp>
    80005a38:	14050a63          	beqz	a0,80005b8c <sys_unlink+0x1b0>
    80005a3c:	00003597          	auipc	a1,0x3
    80005a40:	cc458593          	addi	a1,a1,-828 # 80008700 <syscalls+0x2d0>
    80005a44:	fb040513          	addi	a0,s0,-80
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	680080e7          	jalr	1664(ra) # 800040c8 <namecmp>
    80005a50:	12050e63          	beqz	a0,80005b8c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a54:	f2c40613          	addi	a2,s0,-212
    80005a58:	fb040593          	addi	a1,s0,-80
    80005a5c:	8526                	mv	a0,s1
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	684080e7          	jalr	1668(ra) # 800040e2 <dirlookup>
    80005a66:	892a                	mv	s2,a0
    80005a68:	12050263          	beqz	a0,80005b8c <sys_unlink+0x1b0>
  ilock(ip);
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	192080e7          	jalr	402(ra) # 80003bfe <ilock>
  if(ip->nlink < 1)
    80005a74:	04a91783          	lh	a5,74(s2)
    80005a78:	08f05263          	blez	a5,80005afc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a7c:	04491703          	lh	a4,68(s2)
    80005a80:	4785                	li	a5,1
    80005a82:	08f70563          	beq	a4,a5,80005b0c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a86:	4641                	li	a2,16
    80005a88:	4581                	li	a1,0
    80005a8a:	fc040513          	addi	a0,s0,-64
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	230080e7          	jalr	560(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a96:	4741                	li	a4,16
    80005a98:	f2c42683          	lw	a3,-212(s0)
    80005a9c:	fc040613          	addi	a2,s0,-64
    80005aa0:	4581                	li	a1,0
    80005aa2:	8526                	mv	a0,s1
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	506080e7          	jalr	1286(ra) # 80003faa <writei>
    80005aac:	47c1                	li	a5,16
    80005aae:	0af51563          	bne	a0,a5,80005b58 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ab2:	04491703          	lh	a4,68(s2)
    80005ab6:	4785                	li	a5,1
    80005ab8:	0af70863          	beq	a4,a5,80005b68 <sys_unlink+0x18c>
  iunlockput(dp);
    80005abc:	8526                	mv	a0,s1
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	3a2080e7          	jalr	930(ra) # 80003e60 <iunlockput>
  ip->nlink--;
    80005ac6:	04a95783          	lhu	a5,74(s2)
    80005aca:	37fd                	addiw	a5,a5,-1
    80005acc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ad0:	854a                	mv	a0,s2
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	062080e7          	jalr	98(ra) # 80003b34 <iupdate>
  iunlockput(ip);
    80005ada:	854a                	mv	a0,s2
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	384080e7          	jalr	900(ra) # 80003e60 <iunlockput>
  end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	b70080e7          	jalr	-1168(ra) # 80004654 <end_op>
  return 0;
    80005aec:	4501                	li	a0,0
    80005aee:	a84d                	j	80005ba0 <sys_unlink+0x1c4>
    end_op();
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	b64080e7          	jalr	-1180(ra) # 80004654 <end_op>
    return -1;
    80005af8:	557d                	li	a0,-1
    80005afa:	a05d                	j	80005ba0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005afc:	00003517          	auipc	a0,0x3
    80005b00:	c2c50513          	addi	a0,a0,-980 # 80008728 <syscalls+0x2f8>
    80005b04:	ffffb097          	auipc	ra,0xffffb
    80005b08:	a26080e7          	jalr	-1498(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b0c:	04c92703          	lw	a4,76(s2)
    80005b10:	02000793          	li	a5,32
    80005b14:	f6e7f9e3          	bgeu	a5,a4,80005a86 <sys_unlink+0xaa>
    80005b18:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b1c:	4741                	li	a4,16
    80005b1e:	86ce                	mv	a3,s3
    80005b20:	f1840613          	addi	a2,s0,-232
    80005b24:	4581                	li	a1,0
    80005b26:	854a                	mv	a0,s2
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	38a080e7          	jalr	906(ra) # 80003eb2 <readi>
    80005b30:	47c1                	li	a5,16
    80005b32:	00f51b63          	bne	a0,a5,80005b48 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b36:	f1845783          	lhu	a5,-232(s0)
    80005b3a:	e7a1                	bnez	a5,80005b82 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b3c:	29c1                	addiw	s3,s3,16
    80005b3e:	04c92783          	lw	a5,76(s2)
    80005b42:	fcf9ede3          	bltu	s3,a5,80005b1c <sys_unlink+0x140>
    80005b46:	b781                	j	80005a86 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b48:	00003517          	auipc	a0,0x3
    80005b4c:	bf850513          	addi	a0,a0,-1032 # 80008740 <syscalls+0x310>
    80005b50:	ffffb097          	auipc	ra,0xffffb
    80005b54:	9da080e7          	jalr	-1574(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005b58:	00003517          	auipc	a0,0x3
    80005b5c:	c0050513          	addi	a0,a0,-1024 # 80008758 <syscalls+0x328>
    80005b60:	ffffb097          	auipc	ra,0xffffb
    80005b64:	9ca080e7          	jalr	-1590(ra) # 8000052a <panic>
    dp->nlink--;
    80005b68:	04a4d783          	lhu	a5,74(s1)
    80005b6c:	37fd                	addiw	a5,a5,-1
    80005b6e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b72:	8526                	mv	a0,s1
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	fc0080e7          	jalr	-64(ra) # 80003b34 <iupdate>
    80005b7c:	b781                	j	80005abc <sys_unlink+0xe0>
    return -1;
    80005b7e:	557d                	li	a0,-1
    80005b80:	a005                	j	80005ba0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b82:	854a                	mv	a0,s2
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	2dc080e7          	jalr	732(ra) # 80003e60 <iunlockput>
  iunlockput(dp);
    80005b8c:	8526                	mv	a0,s1
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	2d2080e7          	jalr	722(ra) # 80003e60 <iunlockput>
  end_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	abe080e7          	jalr	-1346(ra) # 80004654 <end_op>
  return -1;
    80005b9e:	557d                	li	a0,-1
}
    80005ba0:	70ae                	ld	ra,232(sp)
    80005ba2:	740e                	ld	s0,224(sp)
    80005ba4:	64ee                	ld	s1,216(sp)
    80005ba6:	694e                	ld	s2,208(sp)
    80005ba8:	69ae                	ld	s3,200(sp)
    80005baa:	616d                	addi	sp,sp,240
    80005bac:	8082                	ret

0000000080005bae <sys_open>:

uint64
sys_open(void)
{
    80005bae:	7131                	addi	sp,sp,-192
    80005bb0:	fd06                	sd	ra,184(sp)
    80005bb2:	f922                	sd	s0,176(sp)
    80005bb4:	f526                	sd	s1,168(sp)
    80005bb6:	f14a                	sd	s2,160(sp)
    80005bb8:	ed4e                	sd	s3,152(sp)
    80005bba:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bbc:	08000613          	li	a2,128
    80005bc0:	f5040593          	addi	a1,s0,-176
    80005bc4:	4501                	li	a0,0
    80005bc6:	ffffd097          	auipc	ra,0xffffd
    80005bca:	438080e7          	jalr	1080(ra) # 80002ffe <argstr>
    return -1;
    80005bce:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005bd0:	0c054163          	bltz	a0,80005c92 <sys_open+0xe4>
    80005bd4:	f4c40593          	addi	a1,s0,-180
    80005bd8:	4505                	li	a0,1
    80005bda:	ffffd097          	auipc	ra,0xffffd
    80005bde:	3e0080e7          	jalr	992(ra) # 80002fba <argint>
    80005be2:	0a054863          	bltz	a0,80005c92 <sys_open+0xe4>

  begin_op();
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	9ee080e7          	jalr	-1554(ra) # 800045d4 <begin_op>

  if(omode & O_CREATE){
    80005bee:	f4c42783          	lw	a5,-180(s0)
    80005bf2:	2007f793          	andi	a5,a5,512
    80005bf6:	cbdd                	beqz	a5,80005cac <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bf8:	4681                	li	a3,0
    80005bfa:	4601                	li	a2,0
    80005bfc:	4589                	li	a1,2
    80005bfe:	f5040513          	addi	a0,s0,-176
    80005c02:	00000097          	auipc	ra,0x0
    80005c06:	972080e7          	jalr	-1678(ra) # 80005574 <create>
    80005c0a:	892a                	mv	s2,a0
    if(ip == 0){
    80005c0c:	c959                	beqz	a0,80005ca2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c0e:	04491703          	lh	a4,68(s2)
    80005c12:	478d                	li	a5,3
    80005c14:	00f71763          	bne	a4,a5,80005c22 <sys_open+0x74>
    80005c18:	04695703          	lhu	a4,70(s2)
    80005c1c:	47a5                	li	a5,9
    80005c1e:	0ce7ec63          	bltu	a5,a4,80005cf6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	dc2080e7          	jalr	-574(ra) # 800049e4 <filealloc>
    80005c2a:	89aa                	mv	s3,a0
    80005c2c:	10050263          	beqz	a0,80005d30 <sys_open+0x182>
    80005c30:	00000097          	auipc	ra,0x0
    80005c34:	902080e7          	jalr	-1790(ra) # 80005532 <fdalloc>
    80005c38:	84aa                	mv	s1,a0
    80005c3a:	0e054663          	bltz	a0,80005d26 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c3e:	04491703          	lh	a4,68(s2)
    80005c42:	478d                	li	a5,3
    80005c44:	0cf70463          	beq	a4,a5,80005d0c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c48:	4789                	li	a5,2
    80005c4a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c4e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c52:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c56:	f4c42783          	lw	a5,-180(s0)
    80005c5a:	0017c713          	xori	a4,a5,1
    80005c5e:	8b05                	andi	a4,a4,1
    80005c60:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c64:	0037f713          	andi	a4,a5,3
    80005c68:	00e03733          	snez	a4,a4
    80005c6c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c70:	4007f793          	andi	a5,a5,1024
    80005c74:	c791                	beqz	a5,80005c80 <sys_open+0xd2>
    80005c76:	04491703          	lh	a4,68(s2)
    80005c7a:	4789                	li	a5,2
    80005c7c:	08f70f63          	beq	a4,a5,80005d1a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c80:	854a                	mv	a0,s2
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	03e080e7          	jalr	62(ra) # 80003cc0 <iunlock>
  end_op();
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	9ca080e7          	jalr	-1590(ra) # 80004654 <end_op>

  return fd;
}
    80005c92:	8526                	mv	a0,s1
    80005c94:	70ea                	ld	ra,184(sp)
    80005c96:	744a                	ld	s0,176(sp)
    80005c98:	74aa                	ld	s1,168(sp)
    80005c9a:	790a                	ld	s2,160(sp)
    80005c9c:	69ea                	ld	s3,152(sp)
    80005c9e:	6129                	addi	sp,sp,192
    80005ca0:	8082                	ret
      end_op();
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	9b2080e7          	jalr	-1614(ra) # 80004654 <end_op>
      return -1;
    80005caa:	b7e5                	j	80005c92 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cac:	f5040513          	addi	a0,s0,-176
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	704080e7          	jalr	1796(ra) # 800043b4 <namei>
    80005cb8:	892a                	mv	s2,a0
    80005cba:	c905                	beqz	a0,80005cea <sys_open+0x13c>
    ilock(ip);
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	f42080e7          	jalr	-190(ra) # 80003bfe <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cc4:	04491703          	lh	a4,68(s2)
    80005cc8:	4785                	li	a5,1
    80005cca:	f4f712e3          	bne	a4,a5,80005c0e <sys_open+0x60>
    80005cce:	f4c42783          	lw	a5,-180(s0)
    80005cd2:	dba1                	beqz	a5,80005c22 <sys_open+0x74>
      iunlockput(ip);
    80005cd4:	854a                	mv	a0,s2
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	18a080e7          	jalr	394(ra) # 80003e60 <iunlockput>
      end_op();
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	976080e7          	jalr	-1674(ra) # 80004654 <end_op>
      return -1;
    80005ce6:	54fd                	li	s1,-1
    80005ce8:	b76d                	j	80005c92 <sys_open+0xe4>
      end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	96a080e7          	jalr	-1686(ra) # 80004654 <end_op>
      return -1;
    80005cf2:	54fd                	li	s1,-1
    80005cf4:	bf79                	j	80005c92 <sys_open+0xe4>
    iunlockput(ip);
    80005cf6:	854a                	mv	a0,s2
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	168080e7          	jalr	360(ra) # 80003e60 <iunlockput>
    end_op();
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	954080e7          	jalr	-1708(ra) # 80004654 <end_op>
    return -1;
    80005d08:	54fd                	li	s1,-1
    80005d0a:	b761                	j	80005c92 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d0c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d10:	04691783          	lh	a5,70(s2)
    80005d14:	02f99223          	sh	a5,36(s3)
    80005d18:	bf2d                	j	80005c52 <sys_open+0xa4>
    itrunc(ip);
    80005d1a:	854a                	mv	a0,s2
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	ff0080e7          	jalr	-16(ra) # 80003d0c <itrunc>
    80005d24:	bfb1                	j	80005c80 <sys_open+0xd2>
      fileclose(f);
    80005d26:	854e                	mv	a0,s3
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	d78080e7          	jalr	-648(ra) # 80004aa0 <fileclose>
    iunlockput(ip);
    80005d30:	854a                	mv	a0,s2
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	12e080e7          	jalr	302(ra) # 80003e60 <iunlockput>
    end_op();
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	91a080e7          	jalr	-1766(ra) # 80004654 <end_op>
    return -1;
    80005d42:	54fd                	li	s1,-1
    80005d44:	b7b9                	j	80005c92 <sys_open+0xe4>

0000000080005d46 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d46:	7175                	addi	sp,sp,-144
    80005d48:	e506                	sd	ra,136(sp)
    80005d4a:	e122                	sd	s0,128(sp)
    80005d4c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	886080e7          	jalr	-1914(ra) # 800045d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d56:	08000613          	li	a2,128
    80005d5a:	f7040593          	addi	a1,s0,-144
    80005d5e:	4501                	li	a0,0
    80005d60:	ffffd097          	auipc	ra,0xffffd
    80005d64:	29e080e7          	jalr	670(ra) # 80002ffe <argstr>
    80005d68:	02054963          	bltz	a0,80005d9a <sys_mkdir+0x54>
    80005d6c:	4681                	li	a3,0
    80005d6e:	4601                	li	a2,0
    80005d70:	4585                	li	a1,1
    80005d72:	f7040513          	addi	a0,s0,-144
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	7fe080e7          	jalr	2046(ra) # 80005574 <create>
    80005d7e:	cd11                	beqz	a0,80005d9a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	0e0080e7          	jalr	224(ra) # 80003e60 <iunlockput>
  end_op();
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	8cc080e7          	jalr	-1844(ra) # 80004654 <end_op>
  return 0;
    80005d90:	4501                	li	a0,0
}
    80005d92:	60aa                	ld	ra,136(sp)
    80005d94:	640a                	ld	s0,128(sp)
    80005d96:	6149                	addi	sp,sp,144
    80005d98:	8082                	ret
    end_op();
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	8ba080e7          	jalr	-1862(ra) # 80004654 <end_op>
    return -1;
    80005da2:	557d                	li	a0,-1
    80005da4:	b7fd                	j	80005d92 <sys_mkdir+0x4c>

0000000080005da6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005da6:	7135                	addi	sp,sp,-160
    80005da8:	ed06                	sd	ra,152(sp)
    80005daa:	e922                	sd	s0,144(sp)
    80005dac:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	826080e7          	jalr	-2010(ra) # 800045d4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005db6:	08000613          	li	a2,128
    80005dba:	f7040593          	addi	a1,s0,-144
    80005dbe:	4501                	li	a0,0
    80005dc0:	ffffd097          	auipc	ra,0xffffd
    80005dc4:	23e080e7          	jalr	574(ra) # 80002ffe <argstr>
    80005dc8:	04054a63          	bltz	a0,80005e1c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005dcc:	f6c40593          	addi	a1,s0,-148
    80005dd0:	4505                	li	a0,1
    80005dd2:	ffffd097          	auipc	ra,0xffffd
    80005dd6:	1e8080e7          	jalr	488(ra) # 80002fba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dda:	04054163          	bltz	a0,80005e1c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005dde:	f6840593          	addi	a1,s0,-152
    80005de2:	4509                	li	a0,2
    80005de4:	ffffd097          	auipc	ra,0xffffd
    80005de8:	1d6080e7          	jalr	470(ra) # 80002fba <argint>
     argint(1, &major) < 0 ||
    80005dec:	02054863          	bltz	a0,80005e1c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005df0:	f6841683          	lh	a3,-152(s0)
    80005df4:	f6c41603          	lh	a2,-148(s0)
    80005df8:	458d                	li	a1,3
    80005dfa:	f7040513          	addi	a0,s0,-144
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	776080e7          	jalr	1910(ra) # 80005574 <create>
     argint(2, &minor) < 0 ||
    80005e06:	c919                	beqz	a0,80005e1c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	058080e7          	jalr	88(ra) # 80003e60 <iunlockput>
  end_op();
    80005e10:	fffff097          	auipc	ra,0xfffff
    80005e14:	844080e7          	jalr	-1980(ra) # 80004654 <end_op>
  return 0;
    80005e18:	4501                	li	a0,0
    80005e1a:	a031                	j	80005e26 <sys_mknod+0x80>
    end_op();
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	838080e7          	jalr	-1992(ra) # 80004654 <end_op>
    return -1;
    80005e24:	557d                	li	a0,-1
}
    80005e26:	60ea                	ld	ra,152(sp)
    80005e28:	644a                	ld	s0,144(sp)
    80005e2a:	610d                	addi	sp,sp,160
    80005e2c:	8082                	ret

0000000080005e2e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e2e:	7135                	addi	sp,sp,-160
    80005e30:	ed06                	sd	ra,152(sp)
    80005e32:	e922                	sd	s0,144(sp)
    80005e34:	e526                	sd	s1,136(sp)
    80005e36:	e14a                	sd	s2,128(sp)
    80005e38:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e3a:	ffffc097          	auipc	ra,0xffffc
    80005e3e:	b46080e7          	jalr	-1210(ra) # 80001980 <myproc>
    80005e42:	892a                	mv	s2,a0
  
  begin_op();
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	790080e7          	jalr	1936(ra) # 800045d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e4c:	08000613          	li	a2,128
    80005e50:	f6040593          	addi	a1,s0,-160
    80005e54:	4501                	li	a0,0
    80005e56:	ffffd097          	auipc	ra,0xffffd
    80005e5a:	1a8080e7          	jalr	424(ra) # 80002ffe <argstr>
    80005e5e:	04054b63          	bltz	a0,80005eb4 <sys_chdir+0x86>
    80005e62:	f6040513          	addi	a0,s0,-160
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	54e080e7          	jalr	1358(ra) # 800043b4 <namei>
    80005e6e:	84aa                	mv	s1,a0
    80005e70:	c131                	beqz	a0,80005eb4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	d8c080e7          	jalr	-628(ra) # 80003bfe <ilock>
  if(ip->type != T_DIR){
    80005e7a:	04449703          	lh	a4,68(s1)
    80005e7e:	4785                	li	a5,1
    80005e80:	04f71063          	bne	a4,a5,80005ec0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e84:	8526                	mv	a0,s1
    80005e86:	ffffe097          	auipc	ra,0xffffe
    80005e8a:	e3a080e7          	jalr	-454(ra) # 80003cc0 <iunlock>
  iput(p->cwd);
    80005e8e:	2e893503          	ld	a0,744(s2)
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	f26080e7          	jalr	-218(ra) # 80003db8 <iput>
  end_op();
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	7ba080e7          	jalr	1978(ra) # 80004654 <end_op>
  p->cwd = ip;
    80005ea2:	2e993423          	sd	s1,744(s2)
  return 0;
    80005ea6:	4501                	li	a0,0
}
    80005ea8:	60ea                	ld	ra,152(sp)
    80005eaa:	644a                	ld	s0,144(sp)
    80005eac:	64aa                	ld	s1,136(sp)
    80005eae:	690a                	ld	s2,128(sp)
    80005eb0:	610d                	addi	sp,sp,160
    80005eb2:	8082                	ret
    end_op();
    80005eb4:	ffffe097          	auipc	ra,0xffffe
    80005eb8:	7a0080e7          	jalr	1952(ra) # 80004654 <end_op>
    return -1;
    80005ebc:	557d                	li	a0,-1
    80005ebe:	b7ed                	j	80005ea8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ec0:	8526                	mv	a0,s1
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	f9e080e7          	jalr	-98(ra) # 80003e60 <iunlockput>
    end_op();
    80005eca:	ffffe097          	auipc	ra,0xffffe
    80005ece:	78a080e7          	jalr	1930(ra) # 80004654 <end_op>
    return -1;
    80005ed2:	557d                	li	a0,-1
    80005ed4:	bfd1                	j	80005ea8 <sys_chdir+0x7a>

0000000080005ed6 <sys_exec>:

uint64
sys_exec(void)
{
    80005ed6:	7145                	addi	sp,sp,-464
    80005ed8:	e786                	sd	ra,456(sp)
    80005eda:	e3a2                	sd	s0,448(sp)
    80005edc:	ff26                	sd	s1,440(sp)
    80005ede:	fb4a                	sd	s2,432(sp)
    80005ee0:	f74e                	sd	s3,424(sp)
    80005ee2:	f352                	sd	s4,416(sp)
    80005ee4:	ef56                	sd	s5,408(sp)
    80005ee6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ee8:	08000613          	li	a2,128
    80005eec:	f4040593          	addi	a1,s0,-192
    80005ef0:	4501                	li	a0,0
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	10c080e7          	jalr	268(ra) # 80002ffe <argstr>
    return -1;
    80005efa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005efc:	0c054a63          	bltz	a0,80005fd0 <sys_exec+0xfa>
    80005f00:	e3840593          	addi	a1,s0,-456
    80005f04:	4505                	li	a0,1
    80005f06:	ffffd097          	auipc	ra,0xffffd
    80005f0a:	0d6080e7          	jalr	214(ra) # 80002fdc <argaddr>
    80005f0e:	0c054163          	bltz	a0,80005fd0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f12:	10000613          	li	a2,256
    80005f16:	4581                	li	a1,0
    80005f18:	e4040513          	addi	a0,s0,-448
    80005f1c:	ffffb097          	auipc	ra,0xffffb
    80005f20:	da2080e7          	jalr	-606(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f24:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f28:	89a6                	mv	s3,s1
    80005f2a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f2c:	02000a13          	li	s4,32
    80005f30:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f34:	00391793          	slli	a5,s2,0x3
    80005f38:	e3040593          	addi	a1,s0,-464
    80005f3c:	e3843503          	ld	a0,-456(s0)
    80005f40:	953e                	add	a0,a0,a5
    80005f42:	ffffd097          	auipc	ra,0xffffd
    80005f46:	fd8080e7          	jalr	-40(ra) # 80002f1a <fetchaddr>
    80005f4a:	02054a63          	bltz	a0,80005f7e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f4e:	e3043783          	ld	a5,-464(s0)
    80005f52:	c3b9                	beqz	a5,80005f98 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f54:	ffffb097          	auipc	ra,0xffffb
    80005f58:	b7e080e7          	jalr	-1154(ra) # 80000ad2 <kalloc>
    80005f5c:	85aa                	mv	a1,a0
    80005f5e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f62:	cd11                	beqz	a0,80005f7e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f64:	6605                	lui	a2,0x1
    80005f66:	e3043503          	ld	a0,-464(s0)
    80005f6a:	ffffd097          	auipc	ra,0xffffd
    80005f6e:	006080e7          	jalr	6(ra) # 80002f70 <fetchstr>
    80005f72:	00054663          	bltz	a0,80005f7e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f76:	0905                	addi	s2,s2,1
    80005f78:	09a1                	addi	s3,s3,8
    80005f7a:	fb491be3          	bne	s2,s4,80005f30 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f7e:	10048913          	addi	s2,s1,256
    80005f82:	6088                	ld	a0,0(s1)
    80005f84:	c529                	beqz	a0,80005fce <sys_exec+0xf8>
    kfree(argv[i]);
    80005f86:	ffffb097          	auipc	ra,0xffffb
    80005f8a:	a50080e7          	jalr	-1456(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f8e:	04a1                	addi	s1,s1,8
    80005f90:	ff2499e3          	bne	s1,s2,80005f82 <sys_exec+0xac>
  return -1;
    80005f94:	597d                	li	s2,-1
    80005f96:	a82d                	j	80005fd0 <sys_exec+0xfa>
      argv[i] = 0;
    80005f98:	0a8e                	slli	s5,s5,0x3
    80005f9a:	fc040793          	addi	a5,s0,-64
    80005f9e:	9abe                	add	s5,s5,a5
    80005fa0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fa4:	e4040593          	addi	a1,s0,-448
    80005fa8:	f4040513          	addi	a0,s0,-192
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	146080e7          	jalr	326(ra) # 800050f2 <exec>
    80005fb4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb6:	10048993          	addi	s3,s1,256
    80005fba:	6088                	ld	a0,0(s1)
    80005fbc:	c911                	beqz	a0,80005fd0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005fbe:	ffffb097          	auipc	ra,0xffffb
    80005fc2:	a18080e7          	jalr	-1512(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc6:	04a1                	addi	s1,s1,8
    80005fc8:	ff3499e3          	bne	s1,s3,80005fba <sys_exec+0xe4>
    80005fcc:	a011                	j	80005fd0 <sys_exec+0xfa>
  return -1;
    80005fce:	597d                	li	s2,-1
}
    80005fd0:	854a                	mv	a0,s2
    80005fd2:	60be                	ld	ra,456(sp)
    80005fd4:	641e                	ld	s0,448(sp)
    80005fd6:	74fa                	ld	s1,440(sp)
    80005fd8:	795a                	ld	s2,432(sp)
    80005fda:	79ba                	ld	s3,424(sp)
    80005fdc:	7a1a                	ld	s4,416(sp)
    80005fde:	6afa                	ld	s5,408(sp)
    80005fe0:	6179                	addi	sp,sp,464
    80005fe2:	8082                	ret

0000000080005fe4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fe4:	7139                	addi	sp,sp,-64
    80005fe6:	fc06                	sd	ra,56(sp)
    80005fe8:	f822                	sd	s0,48(sp)
    80005fea:	f426                	sd	s1,40(sp)
    80005fec:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fee:	ffffc097          	auipc	ra,0xffffc
    80005ff2:	992080e7          	jalr	-1646(ra) # 80001980 <myproc>
    80005ff6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ff8:	fd840593          	addi	a1,s0,-40
    80005ffc:	4501                	li	a0,0
    80005ffe:	ffffd097          	auipc	ra,0xffffd
    80006002:	fde080e7          	jalr	-34(ra) # 80002fdc <argaddr>
    return -1;
    80006006:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006008:	0e054463          	bltz	a0,800060f0 <sys_pipe+0x10c>
  if(pipealloc(&rf, &wf) < 0)
    8000600c:	fc840593          	addi	a1,s0,-56
    80006010:	fd040513          	addi	a0,s0,-48
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	dbc080e7          	jalr	-580(ra) # 80004dd0 <pipealloc>
    return -1;
    8000601c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000601e:	0c054963          	bltz	a0,800060f0 <sys_pipe+0x10c>
  fd0 = -1;
    80006022:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006026:	fd043503          	ld	a0,-48(s0)
    8000602a:	fffff097          	auipc	ra,0xfffff
    8000602e:	508080e7          	jalr	1288(ra) # 80005532 <fdalloc>
    80006032:	fca42223          	sw	a0,-60(s0)
    80006036:	0a054063          	bltz	a0,800060d6 <sys_pipe+0xf2>
    8000603a:	fc843503          	ld	a0,-56(s0)
    8000603e:	fffff097          	auipc	ra,0xfffff
    80006042:	4f4080e7          	jalr	1268(ra) # 80005532 <fdalloc>
    80006046:	fca42023          	sw	a0,-64(s0)
    8000604a:	06054c63          	bltz	a0,800060c2 <sys_pipe+0xde>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000604e:	4691                	li	a3,4
    80006050:	fc440613          	addi	a2,s0,-60
    80006054:	fd843583          	ld	a1,-40(s0)
    80006058:	1e84b503          	ld	a0,488(s1)
    8000605c:	ffffb097          	auipc	ra,0xffffb
    80006060:	5e2080e7          	jalr	1506(ra) # 8000163e <copyout>
    80006064:	02054163          	bltz	a0,80006086 <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006068:	4691                	li	a3,4
    8000606a:	fc040613          	addi	a2,s0,-64
    8000606e:	fd843583          	ld	a1,-40(s0)
    80006072:	0591                	addi	a1,a1,4
    80006074:	1e84b503          	ld	a0,488(s1)
    80006078:	ffffb097          	auipc	ra,0xffffb
    8000607c:	5c6080e7          	jalr	1478(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006080:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006082:	06055763          	bgez	a0,800060f0 <sys_pipe+0x10c>
    p->ofile[fd0] = 0;
    80006086:	fc442783          	lw	a5,-60(s0)
    8000608a:	04c78793          	addi	a5,a5,76
    8000608e:	078e                	slli	a5,a5,0x3
    80006090:	97a6                	add	a5,a5,s1
    80006092:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006096:	fc042503          	lw	a0,-64(s0)
    8000609a:	04c50513          	addi	a0,a0,76
    8000609e:	050e                	slli	a0,a0,0x3
    800060a0:	9526                	add	a0,a0,s1
    800060a2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800060a6:	fd043503          	ld	a0,-48(s0)
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	9f6080e7          	jalr	-1546(ra) # 80004aa0 <fileclose>
    fileclose(wf);
    800060b2:	fc843503          	ld	a0,-56(s0)
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	9ea080e7          	jalr	-1558(ra) # 80004aa0 <fileclose>
    return -1;
    800060be:	57fd                	li	a5,-1
    800060c0:	a805                	j	800060f0 <sys_pipe+0x10c>
    if(fd0 >= 0)
    800060c2:	fc442783          	lw	a5,-60(s0)
    800060c6:	0007c863          	bltz	a5,800060d6 <sys_pipe+0xf2>
      p->ofile[fd0] = 0;
    800060ca:	04c78513          	addi	a0,a5,76
    800060ce:	050e                	slli	a0,a0,0x3
    800060d0:	9526                	add	a0,a0,s1
    800060d2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800060d6:	fd043503          	ld	a0,-48(s0)
    800060da:	fffff097          	auipc	ra,0xfffff
    800060de:	9c6080e7          	jalr	-1594(ra) # 80004aa0 <fileclose>
    fileclose(wf);
    800060e2:	fc843503          	ld	a0,-56(s0)
    800060e6:	fffff097          	auipc	ra,0xfffff
    800060ea:	9ba080e7          	jalr	-1606(ra) # 80004aa0 <fileclose>
    return -1;
    800060ee:	57fd                	li	a5,-1
}
    800060f0:	853e                	mv	a0,a5
    800060f2:	70e2                	ld	ra,56(sp)
    800060f4:	7442                	ld	s0,48(sp)
    800060f6:	74a2                	ld	s1,40(sp)
    800060f8:	6121                	addi	sp,sp,64
    800060fa:	8082                	ret
    800060fc:	0000                	unimp
	...

0000000080006100 <kernelvec>:
    80006100:	7111                	addi	sp,sp,-256
    80006102:	e006                	sd	ra,0(sp)
    80006104:	e40a                	sd	sp,8(sp)
    80006106:	e80e                	sd	gp,16(sp)
    80006108:	ec12                	sd	tp,24(sp)
    8000610a:	f016                	sd	t0,32(sp)
    8000610c:	f41a                	sd	t1,40(sp)
    8000610e:	f81e                	sd	t2,48(sp)
    80006110:	fc22                	sd	s0,56(sp)
    80006112:	e0a6                	sd	s1,64(sp)
    80006114:	e4aa                	sd	a0,72(sp)
    80006116:	e8ae                	sd	a1,80(sp)
    80006118:	ecb2                	sd	a2,88(sp)
    8000611a:	f0b6                	sd	a3,96(sp)
    8000611c:	f4ba                	sd	a4,104(sp)
    8000611e:	f8be                	sd	a5,112(sp)
    80006120:	fcc2                	sd	a6,120(sp)
    80006122:	e146                	sd	a7,128(sp)
    80006124:	e54a                	sd	s2,136(sp)
    80006126:	e94e                	sd	s3,144(sp)
    80006128:	ed52                	sd	s4,152(sp)
    8000612a:	f156                	sd	s5,160(sp)
    8000612c:	f55a                	sd	s6,168(sp)
    8000612e:	f95e                	sd	s7,176(sp)
    80006130:	fd62                	sd	s8,184(sp)
    80006132:	e1e6                	sd	s9,192(sp)
    80006134:	e5ea                	sd	s10,200(sp)
    80006136:	e9ee                	sd	s11,208(sp)
    80006138:	edf2                	sd	t3,216(sp)
    8000613a:	f1f6                	sd	t4,224(sp)
    8000613c:	f5fa                	sd	t5,232(sp)
    8000613e:	f9fe                	sd	t6,240(sp)
    80006140:	c9bfc0ef          	jal	ra,80002dda <kerneltrap>
    80006144:	6082                	ld	ra,0(sp)
    80006146:	6122                	ld	sp,8(sp)
    80006148:	61c2                	ld	gp,16(sp)
    8000614a:	7282                	ld	t0,32(sp)
    8000614c:	7322                	ld	t1,40(sp)
    8000614e:	73c2                	ld	t2,48(sp)
    80006150:	7462                	ld	s0,56(sp)
    80006152:	6486                	ld	s1,64(sp)
    80006154:	6526                	ld	a0,72(sp)
    80006156:	65c6                	ld	a1,80(sp)
    80006158:	6666                	ld	a2,88(sp)
    8000615a:	7686                	ld	a3,96(sp)
    8000615c:	7726                	ld	a4,104(sp)
    8000615e:	77c6                	ld	a5,112(sp)
    80006160:	7866                	ld	a6,120(sp)
    80006162:	688a                	ld	a7,128(sp)
    80006164:	692a                	ld	s2,136(sp)
    80006166:	69ca                	ld	s3,144(sp)
    80006168:	6a6a                	ld	s4,152(sp)
    8000616a:	7a8a                	ld	s5,160(sp)
    8000616c:	7b2a                	ld	s6,168(sp)
    8000616e:	7bca                	ld	s7,176(sp)
    80006170:	7c6a                	ld	s8,184(sp)
    80006172:	6c8e                	ld	s9,192(sp)
    80006174:	6d2e                	ld	s10,200(sp)
    80006176:	6dce                	ld	s11,208(sp)
    80006178:	6e6e                	ld	t3,216(sp)
    8000617a:	7e8e                	ld	t4,224(sp)
    8000617c:	7f2e                	ld	t5,232(sp)
    8000617e:	7fce                	ld	t6,240(sp)
    80006180:	6111                	addi	sp,sp,256
    80006182:	10200073          	sret
    80006186:	00000013          	nop
    8000618a:	00000013          	nop
    8000618e:	0001                	nop

0000000080006190 <timervec>:
    80006190:	34051573          	csrrw	a0,mscratch,a0
    80006194:	e10c                	sd	a1,0(a0)
    80006196:	e510                	sd	a2,8(a0)
    80006198:	e914                	sd	a3,16(a0)
    8000619a:	6d0c                	ld	a1,24(a0)
    8000619c:	7110                	ld	a2,32(a0)
    8000619e:	6194                	ld	a3,0(a1)
    800061a0:	96b2                	add	a3,a3,a2
    800061a2:	e194                	sd	a3,0(a1)
    800061a4:	4589                	li	a1,2
    800061a6:	14459073          	csrw	sip,a1
    800061aa:	6914                	ld	a3,16(a0)
    800061ac:	6510                	ld	a2,8(a0)
    800061ae:	610c                	ld	a1,0(a0)
    800061b0:	34051573          	csrrw	a0,mscratch,a0
    800061b4:	30200073          	mret
	...

00000000800061ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ba:	1141                	addi	sp,sp,-16
    800061bc:	e422                	sd	s0,8(sp)
    800061be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061c0:	0c0007b7          	lui	a5,0xc000
    800061c4:	4705                	li	a4,1
    800061c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061c8:	c3d8                	sw	a4,4(a5)
}
    800061ca:	6422                	ld	s0,8(sp)
    800061cc:	0141                	addi	sp,sp,16
    800061ce:	8082                	ret

00000000800061d0 <plicinithart>:

void
plicinithart(void)
{
    800061d0:	1141                	addi	sp,sp,-16
    800061d2:	e406                	sd	ra,8(sp)
    800061d4:	e022                	sd	s0,0(sp)
    800061d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061d8:	ffffb097          	auipc	ra,0xffffb
    800061dc:	77c080e7          	jalr	1916(ra) # 80001954 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061e0:	0085171b          	slliw	a4,a0,0x8
    800061e4:	0c0027b7          	lui	a5,0xc002
    800061e8:	97ba                	add	a5,a5,a4
    800061ea:	40200713          	li	a4,1026
    800061ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061f2:	00d5151b          	slliw	a0,a0,0xd
    800061f6:	0c2017b7          	lui	a5,0xc201
    800061fa:	953e                	add	a0,a0,a5
    800061fc:	00052023          	sw	zero,0(a0)
}
    80006200:	60a2                	ld	ra,8(sp)
    80006202:	6402                	ld	s0,0(sp)
    80006204:	0141                	addi	sp,sp,16
    80006206:	8082                	ret

0000000080006208 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006208:	1141                	addi	sp,sp,-16
    8000620a:	e406                	sd	ra,8(sp)
    8000620c:	e022                	sd	s0,0(sp)
    8000620e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006210:	ffffb097          	auipc	ra,0xffffb
    80006214:	744080e7          	jalr	1860(ra) # 80001954 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006218:	00d5179b          	slliw	a5,a0,0xd
    8000621c:	0c201537          	lui	a0,0xc201
    80006220:	953e                	add	a0,a0,a5
  return irq;
}
    80006222:	4148                	lw	a0,4(a0)
    80006224:	60a2                	ld	ra,8(sp)
    80006226:	6402                	ld	s0,0(sp)
    80006228:	0141                	addi	sp,sp,16
    8000622a:	8082                	ret

000000008000622c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000622c:	1101                	addi	sp,sp,-32
    8000622e:	ec06                	sd	ra,24(sp)
    80006230:	e822                	sd	s0,16(sp)
    80006232:	e426                	sd	s1,8(sp)
    80006234:	1000                	addi	s0,sp,32
    80006236:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006238:	ffffb097          	auipc	ra,0xffffb
    8000623c:	71c080e7          	jalr	1820(ra) # 80001954 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006240:	00d5151b          	slliw	a0,a0,0xd
    80006244:	0c2017b7          	lui	a5,0xc201
    80006248:	97aa                	add	a5,a5,a0
    8000624a:	c3c4                	sw	s1,4(a5)
}
    8000624c:	60e2                	ld	ra,24(sp)
    8000624e:	6442                	ld	s0,16(sp)
    80006250:	64a2                	ld	s1,8(sp)
    80006252:	6105                	addi	sp,sp,32
    80006254:	8082                	ret

0000000080006256 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006256:	1141                	addi	sp,sp,-16
    80006258:	e406                	sd	ra,8(sp)
    8000625a:	e022                	sd	s0,0(sp)
    8000625c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000625e:	479d                	li	a5,7
    80006260:	06a7c963          	blt	a5,a0,800062d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006264:	00023797          	auipc	a5,0x23
    80006268:	d9c78793          	addi	a5,a5,-612 # 80029000 <disk>
    8000626c:	00a78733          	add	a4,a5,a0
    80006270:	6789                	lui	a5,0x2
    80006272:	97ba                	add	a5,a5,a4
    80006274:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006278:	e7ad                	bnez	a5,800062e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000627a:	00451793          	slli	a5,a0,0x4
    8000627e:	00025717          	auipc	a4,0x25
    80006282:	d8270713          	addi	a4,a4,-638 # 8002b000 <disk+0x2000>
    80006286:	6314                	ld	a3,0(a4)
    80006288:	96be                	add	a3,a3,a5
    8000628a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000628e:	6314                	ld	a3,0(a4)
    80006290:	96be                	add	a3,a3,a5
    80006292:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006296:	6314                	ld	a3,0(a4)
    80006298:	96be                	add	a3,a3,a5
    8000629a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000629e:	6318                	ld	a4,0(a4)
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062a6:	00023797          	auipc	a5,0x23
    800062aa:	d5a78793          	addi	a5,a5,-678 # 80029000 <disk>
    800062ae:	97aa                	add	a5,a5,a0
    800062b0:	6509                	lui	a0,0x2
    800062b2:	953e                	add	a0,a0,a5
    800062b4:	4785                	li	a5,1
    800062b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062ba:	00025517          	auipc	a0,0x25
    800062be:	d5e50513          	addi	a0,a0,-674 # 8002b018 <disk+0x2018>
    800062c2:	ffffc097          	auipc	ra,0xffffc
    800062c6:	254080e7          	jalr	596(ra) # 80002516 <wakeup>
}
    800062ca:	60a2                	ld	ra,8(sp)
    800062cc:	6402                	ld	s0,0(sp)
    800062ce:	0141                	addi	sp,sp,16
    800062d0:	8082                	ret
    panic("free_desc 1");
    800062d2:	00002517          	auipc	a0,0x2
    800062d6:	49650513          	addi	a0,a0,1174 # 80008768 <syscalls+0x338>
    800062da:	ffffa097          	auipc	ra,0xffffa
    800062de:	250080e7          	jalr	592(ra) # 8000052a <panic>
    panic("free_desc 2");
    800062e2:	00002517          	auipc	a0,0x2
    800062e6:	49650513          	addi	a0,a0,1174 # 80008778 <syscalls+0x348>
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	240080e7          	jalr	576(ra) # 8000052a <panic>

00000000800062f2 <virtio_disk_init>:
{
    800062f2:	1101                	addi	sp,sp,-32
    800062f4:	ec06                	sd	ra,24(sp)
    800062f6:	e822                	sd	s0,16(sp)
    800062f8:	e426                	sd	s1,8(sp)
    800062fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062fc:	00002597          	auipc	a1,0x2
    80006300:	48c58593          	addi	a1,a1,1164 # 80008788 <syscalls+0x358>
    80006304:	00025517          	auipc	a0,0x25
    80006308:	e2450513          	addi	a0,a0,-476 # 8002b128 <disk+0x2128>
    8000630c:	ffffb097          	auipc	ra,0xffffb
    80006310:	826080e7          	jalr	-2010(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006314:	100017b7          	lui	a5,0x10001
    80006318:	4398                	lw	a4,0(a5)
    8000631a:	2701                	sext.w	a4,a4
    8000631c:	747277b7          	lui	a5,0x74727
    80006320:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006324:	0ef71163          	bne	a4,a5,80006406 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006328:	100017b7          	lui	a5,0x10001
    8000632c:	43dc                	lw	a5,4(a5)
    8000632e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006330:	4705                	li	a4,1
    80006332:	0ce79a63          	bne	a5,a4,80006406 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006336:	100017b7          	lui	a5,0x10001
    8000633a:	479c                	lw	a5,8(a5)
    8000633c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000633e:	4709                	li	a4,2
    80006340:	0ce79363          	bne	a5,a4,80006406 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006344:	100017b7          	lui	a5,0x10001
    80006348:	47d8                	lw	a4,12(a5)
    8000634a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000634c:	554d47b7          	lui	a5,0x554d4
    80006350:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006354:	0af71963          	bne	a4,a5,80006406 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006358:	100017b7          	lui	a5,0x10001
    8000635c:	4705                	li	a4,1
    8000635e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006360:	470d                	li	a4,3
    80006362:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006364:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006366:	c7ffe737          	lui	a4,0xc7ffe
    8000636a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd275f>
    8000636e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006370:	2701                	sext.w	a4,a4
    80006372:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006374:	472d                	li	a4,11
    80006376:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006378:	473d                	li	a4,15
    8000637a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000637c:	6705                	lui	a4,0x1
    8000637e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006380:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006384:	5bdc                	lw	a5,52(a5)
    80006386:	2781                	sext.w	a5,a5
  if(max == 0)
    80006388:	c7d9                	beqz	a5,80006416 <virtio_disk_init+0x124>
  if(max < NUM)
    8000638a:	471d                	li	a4,7
    8000638c:	08f77d63          	bgeu	a4,a5,80006426 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006390:	100014b7          	lui	s1,0x10001
    80006394:	47a1                	li	a5,8
    80006396:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006398:	6609                	lui	a2,0x2
    8000639a:	4581                	li	a1,0
    8000639c:	00023517          	auipc	a0,0x23
    800063a0:	c6450513          	addi	a0,a0,-924 # 80029000 <disk>
    800063a4:	ffffb097          	auipc	ra,0xffffb
    800063a8:	91a080e7          	jalr	-1766(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063ac:	00023717          	auipc	a4,0x23
    800063b0:	c5470713          	addi	a4,a4,-940 # 80029000 <disk>
    800063b4:	00c75793          	srli	a5,a4,0xc
    800063b8:	2781                	sext.w	a5,a5
    800063ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063bc:	00025797          	auipc	a5,0x25
    800063c0:	c4478793          	addi	a5,a5,-956 # 8002b000 <disk+0x2000>
    800063c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800063c6:	00023717          	auipc	a4,0x23
    800063ca:	cba70713          	addi	a4,a4,-838 # 80029080 <disk+0x80>
    800063ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063d0:	00024717          	auipc	a4,0x24
    800063d4:	c3070713          	addi	a4,a4,-976 # 8002a000 <disk+0x1000>
    800063d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800063da:	4705                	li	a4,1
    800063dc:	00e78c23          	sb	a4,24(a5)
    800063e0:	00e78ca3          	sb	a4,25(a5)
    800063e4:	00e78d23          	sb	a4,26(a5)
    800063e8:	00e78da3          	sb	a4,27(a5)
    800063ec:	00e78e23          	sb	a4,28(a5)
    800063f0:	00e78ea3          	sb	a4,29(a5)
    800063f4:	00e78f23          	sb	a4,30(a5)
    800063f8:	00e78fa3          	sb	a4,31(a5)
}
    800063fc:	60e2                	ld	ra,24(sp)
    800063fe:	6442                	ld	s0,16(sp)
    80006400:	64a2                	ld	s1,8(sp)
    80006402:	6105                	addi	sp,sp,32
    80006404:	8082                	ret
    panic("could not find virtio disk");
    80006406:	00002517          	auipc	a0,0x2
    8000640a:	39250513          	addi	a0,a0,914 # 80008798 <syscalls+0x368>
    8000640e:	ffffa097          	auipc	ra,0xffffa
    80006412:	11c080e7          	jalr	284(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006416:	00002517          	auipc	a0,0x2
    8000641a:	3a250513          	addi	a0,a0,930 # 800087b8 <syscalls+0x388>
    8000641e:	ffffa097          	auipc	ra,0xffffa
    80006422:	10c080e7          	jalr	268(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006426:	00002517          	auipc	a0,0x2
    8000642a:	3b250513          	addi	a0,a0,946 # 800087d8 <syscalls+0x3a8>
    8000642e:	ffffa097          	auipc	ra,0xffffa
    80006432:	0fc080e7          	jalr	252(ra) # 8000052a <panic>

0000000080006436 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006436:	7119                	addi	sp,sp,-128
    80006438:	fc86                	sd	ra,120(sp)
    8000643a:	f8a2                	sd	s0,112(sp)
    8000643c:	f4a6                	sd	s1,104(sp)
    8000643e:	f0ca                	sd	s2,96(sp)
    80006440:	ecce                	sd	s3,88(sp)
    80006442:	e8d2                	sd	s4,80(sp)
    80006444:	e4d6                	sd	s5,72(sp)
    80006446:	e0da                	sd	s6,64(sp)
    80006448:	fc5e                	sd	s7,56(sp)
    8000644a:	f862                	sd	s8,48(sp)
    8000644c:	f466                	sd	s9,40(sp)
    8000644e:	f06a                	sd	s10,32(sp)
    80006450:	ec6e                	sd	s11,24(sp)
    80006452:	0100                	addi	s0,sp,128
    80006454:	8aaa                	mv	s5,a0
    80006456:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006458:	00c52c83          	lw	s9,12(a0)
    8000645c:	001c9c9b          	slliw	s9,s9,0x1
    80006460:	1c82                	slli	s9,s9,0x20
    80006462:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006466:	00025517          	auipc	a0,0x25
    8000646a:	cc250513          	addi	a0,a0,-830 # 8002b128 <disk+0x2128>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	754080e7          	jalr	1876(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006476:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006478:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000647a:	00023c17          	auipc	s8,0x23
    8000647e:	b86c0c13          	addi	s8,s8,-1146 # 80029000 <disk>
    80006482:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006484:	4b0d                	li	s6,3
    80006486:	a0ad                	j	800064f0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006488:	00fc0733          	add	a4,s8,a5
    8000648c:	975e                	add	a4,a4,s7
    8000648e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006492:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006494:	0207c563          	bltz	a5,800064be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006498:	2905                	addiw	s2,s2,1
    8000649a:	0611                	addi	a2,a2,4
    8000649c:	19690d63          	beq	s2,s6,80006636 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800064a0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800064a2:	00025717          	auipc	a4,0x25
    800064a6:	b7670713          	addi	a4,a4,-1162 # 8002b018 <disk+0x2018>
    800064aa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800064ac:	00074683          	lbu	a3,0(a4)
    800064b0:	fee1                	bnez	a3,80006488 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064b2:	2785                	addiw	a5,a5,1
    800064b4:	0705                	addi	a4,a4,1
    800064b6:	fe979be3          	bne	a5,s1,800064ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064ba:	57fd                	li	a5,-1
    800064bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800064be:	01205d63          	blez	s2,800064d8 <virtio_disk_rw+0xa2>
    800064c2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800064c4:	000a2503          	lw	a0,0(s4)
    800064c8:	00000097          	auipc	ra,0x0
    800064cc:	d8e080e7          	jalr	-626(ra) # 80006256 <free_desc>
      for(int j = 0; j < i; j++)
    800064d0:	2d85                	addiw	s11,s11,1
    800064d2:	0a11                	addi	s4,s4,4
    800064d4:	ffb918e3          	bne	s2,s11,800064c4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064d8:	00025597          	auipc	a1,0x25
    800064dc:	c5058593          	addi	a1,a1,-944 # 8002b128 <disk+0x2128>
    800064e0:	00025517          	auipc	a0,0x25
    800064e4:	b3850513          	addi	a0,a0,-1224 # 8002b018 <disk+0x2018>
    800064e8:	ffffc097          	auipc	ra,0xffffc
    800064ec:	ea0080e7          	jalr	-352(ra) # 80002388 <sleep>
  for(int i = 0; i < 3; i++){
    800064f0:	f8040a13          	addi	s4,s0,-128
{
    800064f4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800064f6:	894e                	mv	s2,s3
    800064f8:	b765                	j	800064a0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064fa:	00025697          	auipc	a3,0x25
    800064fe:	b066b683          	ld	a3,-1274(a3) # 8002b000 <disk+0x2000>
    80006502:	96ba                	add	a3,a3,a4
    80006504:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006508:	00023817          	auipc	a6,0x23
    8000650c:	af880813          	addi	a6,a6,-1288 # 80029000 <disk>
    80006510:	00025697          	auipc	a3,0x25
    80006514:	af068693          	addi	a3,a3,-1296 # 8002b000 <disk+0x2000>
    80006518:	6290                	ld	a2,0(a3)
    8000651a:	963a                	add	a2,a2,a4
    8000651c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006520:	0015e593          	ori	a1,a1,1
    80006524:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006528:	f8842603          	lw	a2,-120(s0)
    8000652c:	628c                	ld	a1,0(a3)
    8000652e:	972e                	add	a4,a4,a1
    80006530:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006534:	20050593          	addi	a1,a0,512
    80006538:	0592                	slli	a1,a1,0x4
    8000653a:	95c2                	add	a1,a1,a6
    8000653c:	577d                	li	a4,-1
    8000653e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006542:	00461713          	slli	a4,a2,0x4
    80006546:	6290                	ld	a2,0(a3)
    80006548:	963a                	add	a2,a2,a4
    8000654a:	03078793          	addi	a5,a5,48
    8000654e:	97c2                	add	a5,a5,a6
    80006550:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006552:	629c                	ld	a5,0(a3)
    80006554:	97ba                	add	a5,a5,a4
    80006556:	4605                	li	a2,1
    80006558:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000655a:	629c                	ld	a5,0(a3)
    8000655c:	97ba                	add	a5,a5,a4
    8000655e:	4809                	li	a6,2
    80006560:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006564:	629c                	ld	a5,0(a3)
    80006566:	973e                	add	a4,a4,a5
    80006568:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000656c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006570:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006574:	6698                	ld	a4,8(a3)
    80006576:	00275783          	lhu	a5,2(a4)
    8000657a:	8b9d                	andi	a5,a5,7
    8000657c:	0786                	slli	a5,a5,0x1
    8000657e:	97ba                	add	a5,a5,a4
    80006580:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006584:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006588:	6698                	ld	a4,8(a3)
    8000658a:	00275783          	lhu	a5,2(a4)
    8000658e:	2785                	addiw	a5,a5,1
    80006590:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006594:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006598:	100017b7          	lui	a5,0x10001
    8000659c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065a0:	004aa783          	lw	a5,4(s5)
    800065a4:	02c79163          	bne	a5,a2,800065c6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800065a8:	00025917          	auipc	s2,0x25
    800065ac:	b8090913          	addi	s2,s2,-1152 # 8002b128 <disk+0x2128>
  while(b->disk == 1) {
    800065b0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065b2:	85ca                	mv	a1,s2
    800065b4:	8556                	mv	a0,s5
    800065b6:	ffffc097          	auipc	ra,0xffffc
    800065ba:	dd2080e7          	jalr	-558(ra) # 80002388 <sleep>
  while(b->disk == 1) {
    800065be:	004aa783          	lw	a5,4(s5)
    800065c2:	fe9788e3          	beq	a5,s1,800065b2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800065c6:	f8042903          	lw	s2,-128(s0)
    800065ca:	20090793          	addi	a5,s2,512
    800065ce:	00479713          	slli	a4,a5,0x4
    800065d2:	00023797          	auipc	a5,0x23
    800065d6:	a2e78793          	addi	a5,a5,-1490 # 80029000 <disk>
    800065da:	97ba                	add	a5,a5,a4
    800065dc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065e0:	00025997          	auipc	s3,0x25
    800065e4:	a2098993          	addi	s3,s3,-1504 # 8002b000 <disk+0x2000>
    800065e8:	00491713          	slli	a4,s2,0x4
    800065ec:	0009b783          	ld	a5,0(s3)
    800065f0:	97ba                	add	a5,a5,a4
    800065f2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065f6:	854a                	mv	a0,s2
    800065f8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065fc:	00000097          	auipc	ra,0x0
    80006600:	c5a080e7          	jalr	-934(ra) # 80006256 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006604:	8885                	andi	s1,s1,1
    80006606:	f0ed                	bnez	s1,800065e8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006608:	00025517          	auipc	a0,0x25
    8000660c:	b2050513          	addi	a0,a0,-1248 # 8002b128 <disk+0x2128>
    80006610:	ffffa097          	auipc	ra,0xffffa
    80006614:	666080e7          	jalr	1638(ra) # 80000c76 <release>
}
    80006618:	70e6                	ld	ra,120(sp)
    8000661a:	7446                	ld	s0,112(sp)
    8000661c:	74a6                	ld	s1,104(sp)
    8000661e:	7906                	ld	s2,96(sp)
    80006620:	69e6                	ld	s3,88(sp)
    80006622:	6a46                	ld	s4,80(sp)
    80006624:	6aa6                	ld	s5,72(sp)
    80006626:	6b06                	ld	s6,64(sp)
    80006628:	7be2                	ld	s7,56(sp)
    8000662a:	7c42                	ld	s8,48(sp)
    8000662c:	7ca2                	ld	s9,40(sp)
    8000662e:	7d02                	ld	s10,32(sp)
    80006630:	6de2                	ld	s11,24(sp)
    80006632:	6109                	addi	sp,sp,128
    80006634:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006636:	f8042503          	lw	a0,-128(s0)
    8000663a:	20050793          	addi	a5,a0,512
    8000663e:	0792                	slli	a5,a5,0x4
  if(write)
    80006640:	00023817          	auipc	a6,0x23
    80006644:	9c080813          	addi	a6,a6,-1600 # 80029000 <disk>
    80006648:	00f80733          	add	a4,a6,a5
    8000664c:	01a036b3          	snez	a3,s10
    80006650:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006654:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006658:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000665c:	7679                	lui	a2,0xffffe
    8000665e:	963e                	add	a2,a2,a5
    80006660:	00025697          	auipc	a3,0x25
    80006664:	9a068693          	addi	a3,a3,-1632 # 8002b000 <disk+0x2000>
    80006668:	6298                	ld	a4,0(a3)
    8000666a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000666c:	0a878593          	addi	a1,a5,168
    80006670:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006672:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006674:	6298                	ld	a4,0(a3)
    80006676:	9732                	add	a4,a4,a2
    80006678:	45c1                	li	a1,16
    8000667a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000667c:	6298                	ld	a4,0(a3)
    8000667e:	9732                	add	a4,a4,a2
    80006680:	4585                	li	a1,1
    80006682:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006686:	f8442703          	lw	a4,-124(s0)
    8000668a:	628c                	ld	a1,0(a3)
    8000668c:	962e                	add	a2,a2,a1
    8000668e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd200e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006692:	0712                	slli	a4,a4,0x4
    80006694:	6290                	ld	a2,0(a3)
    80006696:	963a                	add	a2,a2,a4
    80006698:	058a8593          	addi	a1,s5,88
    8000669c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000669e:	6294                	ld	a3,0(a3)
    800066a0:	96ba                	add	a3,a3,a4
    800066a2:	40000613          	li	a2,1024
    800066a6:	c690                	sw	a2,8(a3)
  if(write)
    800066a8:	e40d19e3          	bnez	s10,800064fa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066ac:	00025697          	auipc	a3,0x25
    800066b0:	9546b683          	ld	a3,-1708(a3) # 8002b000 <disk+0x2000>
    800066b4:	96ba                	add	a3,a3,a4
    800066b6:	4609                	li	a2,2
    800066b8:	00c69623          	sh	a2,12(a3)
    800066bc:	b5b1                	j	80006508 <virtio_disk_rw+0xd2>

00000000800066be <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066be:	1101                	addi	sp,sp,-32
    800066c0:	ec06                	sd	ra,24(sp)
    800066c2:	e822                	sd	s0,16(sp)
    800066c4:	e426                	sd	s1,8(sp)
    800066c6:	e04a                	sd	s2,0(sp)
    800066c8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066ca:	00025517          	auipc	a0,0x25
    800066ce:	a5e50513          	addi	a0,a0,-1442 # 8002b128 <disk+0x2128>
    800066d2:	ffffa097          	auipc	ra,0xffffa
    800066d6:	4f0080e7          	jalr	1264(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066da:	10001737          	lui	a4,0x10001
    800066de:	533c                	lw	a5,96(a4)
    800066e0:	8b8d                	andi	a5,a5,3
    800066e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066e8:	00025797          	auipc	a5,0x25
    800066ec:	91878793          	addi	a5,a5,-1768 # 8002b000 <disk+0x2000>
    800066f0:	6b94                	ld	a3,16(a5)
    800066f2:	0207d703          	lhu	a4,32(a5)
    800066f6:	0026d783          	lhu	a5,2(a3)
    800066fa:	06f70163          	beq	a4,a5,8000675c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066fe:	00023917          	auipc	s2,0x23
    80006702:	90290913          	addi	s2,s2,-1790 # 80029000 <disk>
    80006706:	00025497          	auipc	s1,0x25
    8000670a:	8fa48493          	addi	s1,s1,-1798 # 8002b000 <disk+0x2000>
    __sync_synchronize();
    8000670e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006712:	6898                	ld	a4,16(s1)
    80006714:	0204d783          	lhu	a5,32(s1)
    80006718:	8b9d                	andi	a5,a5,7
    8000671a:	078e                	slli	a5,a5,0x3
    8000671c:	97ba                	add	a5,a5,a4
    8000671e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006720:	20078713          	addi	a4,a5,512
    80006724:	0712                	slli	a4,a4,0x4
    80006726:	974a                	add	a4,a4,s2
    80006728:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000672c:	e731                	bnez	a4,80006778 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000672e:	20078793          	addi	a5,a5,512
    80006732:	0792                	slli	a5,a5,0x4
    80006734:	97ca                	add	a5,a5,s2
    80006736:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006738:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000673c:	ffffc097          	auipc	ra,0xffffc
    80006740:	dda080e7          	jalr	-550(ra) # 80002516 <wakeup>

    disk.used_idx += 1;
    80006744:	0204d783          	lhu	a5,32(s1)
    80006748:	2785                	addiw	a5,a5,1
    8000674a:	17c2                	slli	a5,a5,0x30
    8000674c:	93c1                	srli	a5,a5,0x30
    8000674e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006752:	6898                	ld	a4,16(s1)
    80006754:	00275703          	lhu	a4,2(a4)
    80006758:	faf71be3          	bne	a4,a5,8000670e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000675c:	00025517          	auipc	a0,0x25
    80006760:	9cc50513          	addi	a0,a0,-1588 # 8002b128 <disk+0x2128>
    80006764:	ffffa097          	auipc	ra,0xffffa
    80006768:	512080e7          	jalr	1298(ra) # 80000c76 <release>
}
    8000676c:	60e2                	ld	ra,24(sp)
    8000676e:	6442                	ld	s0,16(sp)
    80006770:	64a2                	ld	s1,8(sp)
    80006772:	6902                	ld	s2,0(sp)
    80006774:	6105                	addi	sp,sp,32
    80006776:	8082                	ret
      panic("virtio_disk_intr status");
    80006778:	00002517          	auipc	a0,0x2
    8000677c:	08050513          	addi	a0,a0,128 # 800087f8 <syscalls+0x3c8>
    80006780:	ffffa097          	auipc	ra,0xffffa
    80006784:	daa080e7          	jalr	-598(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret

0000000080007112 <start_inject_sigret>:
    80007112:	48e1                	li	a7,24
    80007114:	00000073          	ecall

0000000080007118 <end_inject_sigret>:
	...
