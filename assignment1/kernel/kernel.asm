
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
    80000068:	d0c78793          	addi	a5,a5,-756 # 80005d70 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
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
    80000122:	322080e7          	jalr	802(ra) # 80002440 <either_copyin>
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
    800001b6:	7cc080e7          	jalr	1996(ra) # 8000197e <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e84080e7          	jalr	-380(ra) # 80002046 <sleep>
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
    80000202:	1ec080e7          	jalr	492(ra) # 800023ea <either_copyout>
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
    800002e2:	1b8080e7          	jalr	440(ra) # 80002496 <procdump>
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
    80000436:	da0080e7          	jalr	-608(ra) # 800021d2 <wakeup>
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
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
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
    80000882:	954080e7          	jalr	-1708(ra) # 800021d2 <wakeup>
    
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
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	73c080e7          	jalr	1852(ra) # 80002046 <sleep>
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
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
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
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
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
    80000b60:	e06080e7          	jalr	-506(ra) # 80001962 <mycpu>
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
    80000b92:	dd4080e7          	jalr	-556(ra) # 80001962 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dc8080e7          	jalr	-568(ra) # 80001962 <mycpu>
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
    80000bb6:	db0080e7          	jalr	-592(ra) # 80001962 <mycpu>
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
    80000bf6:	d70080e7          	jalr	-656(ra) # 80001962 <mycpu>
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
    80000c22:	d44080e7          	jalr	-700(ra) # 80001962 <mycpu>
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
    80000e78:	ade080e7          	jalr	-1314(ra) # 80001952 <cpuid>
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
    80000e94:	ac2080e7          	jalr	-1342(ra) # 80001952 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	790080e7          	jalr	1936(ra) # 80002642 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	ef6080e7          	jalr	-266(ra) # 80005db0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fd2080e7          	jalr	-46(ra) # 80001e94 <scheduler>
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
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	6f0080e7          	jalr	1776(ra) # 8000261a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	710080e7          	jalr	1808(ra) # 80002642 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	e60080e7          	jalr	-416(ra) # 80005d9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	e6e080e7          	jalr	-402(ra) # 80005db0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	03a080e7          	jalr	58(ra) # 80002f84 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	6cc080e7          	jalr	1740(ra) # 8000361e <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	67a080e7          	jalr	1658(ra) # 800045d4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f70080e7          	jalr	-144(ra) # 80005ed2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	cec080e7          	jalr	-788(ra) # 80001c56 <userinit>
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
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
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
    8000183c:	00016a17          	auipc	s4,0x16
    80001840:	894a0a13          	addi	s4,s4,-1900 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	28e080e7          	jalr	654(ra) # 80000ad2 <kalloc>
    8000184c:	862a                	mv	a2,a0
    if(pa == 0)
    8000184e:	c131                	beqz	a0,80001892 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001850:	416485b3          	sub	a1,s1,s6
    80001854:	858d                	srai	a1,a1,0x3
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
    80001876:	16848493          	addi	s1,s1,360
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
    80001908:	00015997          	auipc	s3,0x15
    8000190c:	7c898993          	addi	s3,s3,1992 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001910:	85da                	mv	a1,s6
    80001912:	8526                	mv	a0,s1
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	21e080e7          	jalr	542(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000191c:	415487b3          	sub	a5,s1,s5
    80001920:	878d                	srai	a5,a5,0x3
    80001922:	000a3703          	ld	a4,0(s4)
    80001926:	02e787b3          	mul	a5,a5,a4
    8000192a:	2785                	addiw	a5,a5,1
    8000192c:	00d7979b          	slliw	a5,a5,0xd
    80001930:	40f907b3          	sub	a5,s2,a5
    80001934:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	16848493          	addi	s1,s1,360
    8000193a:	fd349be3          	bne	s1,s3,80001910 <procinit+0x6e>
  }
}
    8000193e:	70e2                	ld	ra,56(sp)
    80001940:	7442                	ld	s0,48(sp)
    80001942:	74a2                	ld	s1,40(sp)
    80001944:	7902                	ld	s2,32(sp)
    80001946:	69e2                	ld	s3,24(sp)
    80001948:	6a42                	ld	s4,16(sp)
    8000194a:	6aa2                	ld	s5,8(sp)
    8000194c:	6b02                	ld	s6,0(sp)
    8000194e:	6121                	addi	sp,sp,64
    80001950:	8082                	ret

0000000080001952 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001952:	1141                	addi	sp,sp,-16
    80001954:	e422                	sd	s0,8(sp)
    80001956:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001958:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000195a:	2501                	sext.w	a0,a0
    8000195c:	6422                	ld	s0,8(sp)
    8000195e:	0141                	addi	sp,sp,16
    80001960:	8082                	ret

0000000080001962 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001962:	1141                	addi	sp,sp,-16
    80001964:	e422                	sd	s0,8(sp)
    80001966:	0800                	addi	s0,sp,16
    80001968:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000196a:	2781                	sext.w	a5,a5
    8000196c:	079e                	slli	a5,a5,0x7
  return c;
}
    8000196e:	00010517          	auipc	a0,0x10
    80001972:	96250513          	addi	a0,a0,-1694 # 800112d0 <cpus>
    80001976:	953e                	add	a0,a0,a5
    80001978:	6422                	ld	s0,8(sp)
    8000197a:	0141                	addi	sp,sp,16
    8000197c:	8082                	ret

000000008000197e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    8000197e:	1101                	addi	sp,sp,-32
    80001980:	ec06                	sd	ra,24(sp)
    80001982:	e822                	sd	s0,16(sp)
    80001984:	e426                	sd	s1,8(sp)
    80001986:	1000                	addi	s0,sp,32
  push_off();
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1ee080e7          	jalr	494(ra) # 80000b76 <push_off>
    80001990:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
    80001996:	00010717          	auipc	a4,0x10
    8000199a:	90a70713          	addi	a4,a4,-1782 # 800112a0 <pid_lock>
    8000199e:	97ba                	add	a5,a5,a4
    800019a0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	274080e7          	jalr	628(ra) # 80000c16 <pop_off>
  return p;
}
    800019aa:	8526                	mv	a0,s1
    800019ac:	60e2                	ld	ra,24(sp)
    800019ae:	6442                	ld	s0,16(sp)
    800019b0:	64a2                	ld	s1,8(sp)
    800019b2:	6105                	addi	sp,sp,32
    800019b4:	8082                	ret

00000000800019b6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e406                	sd	ra,8(sp)
    800019ba:	e022                	sd	s0,0(sp)
    800019bc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	fc0080e7          	jalr	-64(ra) # 8000197e <myproc>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	2b0080e7          	jalr	688(ra) # 80000c76 <release>

  if (first) {
    800019ce:	00007797          	auipc	a5,0x7
    800019d2:	fa27a783          	lw	a5,-94(a5) # 80008970 <first.1>
    800019d6:	eb89                	bnez	a5,800019e8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019d8:	00001097          	auipc	ra,0x1
    800019dc:	c82080e7          	jalr	-894(ra) # 8000265a <usertrapret>
}
    800019e0:	60a2                	ld	ra,8(sp)
    800019e2:	6402                	ld	s0,0(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret
    first = 0;
    800019e8:	00007797          	auipc	a5,0x7
    800019ec:	f807a423          	sw	zero,-120(a5) # 80008970 <first.1>
    fsinit(ROOTDEV);
    800019f0:	4505                	li	a0,1
    800019f2:	00002097          	auipc	ra,0x2
    800019f6:	bac080e7          	jalr	-1108(ra) # 8000359e <fsinit>
    800019fa:	bff9                	j	800019d8 <forkret+0x22>

00000000800019fc <allocpid>:
allocpid() {
    800019fc:	1101                	addi	sp,sp,-32
    800019fe:	ec06                	sd	ra,24(sp)
    80001a00:	e822                	sd	s0,16(sp)
    80001a02:	e426                	sd	s1,8(sp)
    80001a04:	e04a                	sd	s2,0(sp)
    80001a06:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a08:	00010917          	auipc	s2,0x10
    80001a0c:	89890913          	addi	s2,s2,-1896 # 800112a0 <pid_lock>
    80001a10:	854a                	mv	a0,s2
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	1b0080e7          	jalr	432(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	f5a78793          	addi	a5,a5,-166 # 80008974 <nextpid>
    80001a22:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a24:	0014871b          	addiw	a4,s1,1
    80001a28:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a2a:	854a                	mv	a0,s2
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	24a080e7          	jalr	586(ra) # 80000c76 <release>
}
    80001a34:	8526                	mv	a0,s1
    80001a36:	60e2                	ld	ra,24(sp)
    80001a38:	6442                	ld	s0,16(sp)
    80001a3a:	64a2                	ld	s1,8(sp)
    80001a3c:	6902                	ld	s2,0(sp)
    80001a3e:	6105                	addi	sp,sp,32
    80001a40:	8082                	ret

0000000080001a42 <proc_pagetable>:
{
    80001a42:	1101                	addi	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	e04a                	sd	s2,0(sp)
    80001a4c:	1000                	addi	s0,sp,32
    80001a4e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a50:	00000097          	auipc	ra,0x0
    80001a54:	8b6080e7          	jalr	-1866(ra) # 80001306 <uvmcreate>
    80001a58:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a5a:	c121                	beqz	a0,80001a9a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a5c:	4729                	li	a4,10
    80001a5e:	00005697          	auipc	a3,0x5
    80001a62:	5a268693          	addi	a3,a3,1442 # 80007000 <_trampoline>
    80001a66:	6605                	lui	a2,0x1
    80001a68:	040005b7          	lui	a1,0x4000
    80001a6c:	15fd                	addi	a1,a1,-1
    80001a6e:	05b2                	slli	a1,a1,0xc
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	61e080e7          	jalr	1566(ra) # 8000108e <mappages>
    80001a78:	02054863          	bltz	a0,80001aa8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a7c:	4719                	li	a4,6
    80001a7e:	05893683          	ld	a3,88(s2)
    80001a82:	6605                	lui	a2,0x1
    80001a84:	020005b7          	lui	a1,0x2000
    80001a88:	15fd                	addi	a1,a1,-1
    80001a8a:	05b6                	slli	a1,a1,0xd
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	600080e7          	jalr	1536(ra) # 8000108e <mappages>
    80001a96:	02054163          	bltz	a0,80001ab8 <proc_pagetable+0x76>
}
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	60e2                	ld	ra,24(sp)
    80001a9e:	6442                	ld	s0,16(sp)
    80001aa0:	64a2                	ld	s1,8(sp)
    80001aa2:	6902                	ld	s2,0(sp)
    80001aa4:	6105                	addi	sp,sp,32
    80001aa6:	8082                	ret
    uvmfree(pagetable, 0);
    80001aa8:	4581                	li	a1,0
    80001aaa:	8526                	mv	a0,s1
    80001aac:	00000097          	auipc	ra,0x0
    80001ab0:	a56080e7          	jalr	-1450(ra) # 80001502 <uvmfree>
    return 0;
    80001ab4:	4481                	li	s1,0
    80001ab6:	b7d5                	j	80001a9a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ab8:	4681                	li	a3,0
    80001aba:	4605                	li	a2,1
    80001abc:	040005b7          	lui	a1,0x4000
    80001ac0:	15fd                	addi	a1,a1,-1
    80001ac2:	05b2                	slli	a1,a1,0xc
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	77c080e7          	jalr	1916(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ace:	4581                	li	a1,0
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	a30080e7          	jalr	-1488(ra) # 80001502 <uvmfree>
    return 0;
    80001ada:	4481                	li	s1,0
    80001adc:	bf7d                	j	80001a9a <proc_pagetable+0x58>

0000000080001ade <proc_freepagetable>:
{
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	e04a                	sd	s2,0(sp)
    80001ae8:	1000                	addi	s0,sp,32
    80001aea:	84aa                	mv	s1,a0
    80001aec:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	748080e7          	jalr	1864(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	020005b7          	lui	a1,0x2000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b6                	slli	a1,a1,0xd
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	732080e7          	jalr	1842(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b18:	85ca                	mv	a1,s2
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	9e6080e7          	jalr	-1562(ra) # 80001502 <uvmfree>
}
    80001b24:	60e2                	ld	ra,24(sp)
    80001b26:	6442                	ld	s0,16(sp)
    80001b28:	64a2                	ld	s1,8(sp)
    80001b2a:	6902                	ld	s2,0(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <freeproc>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b3c:	6d28                	ld	a0,88(a0)
    80001b3e:	c509                	beqz	a0,80001b48 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b48:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b4c:	68a8                	ld	a0,80(s1)
    80001b4e:	c511                	beqz	a0,80001b5a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b50:	64ac                	ld	a1,72(s1)
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	f8c080e7          	jalr	-116(ra) # 80001ade <proc_freepagetable>
  p->pagetable = 0;
    80001b5a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b5e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b62:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b66:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b6a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b6e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b72:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b76:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b7a:	0004ac23          	sw	zero,24(s1)
}
    80001b7e:	60e2                	ld	ra,24(sp)
    80001b80:	6442                	ld	s0,16(sp)
    80001b82:	64a2                	ld	s1,8(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret

0000000080001b88 <allocproc>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b94:	00010497          	auipc	s1,0x10
    80001b98:	b3c48493          	addi	s1,s1,-1220 # 800116d0 <proc>
    80001b9c:	00015917          	auipc	s2,0x15
    80001ba0:	53490913          	addi	s2,s2,1332 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	01c080e7          	jalr	28(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bae:	4c9c                	lw	a5,24(s1)
    80001bb0:	cf81                	beqz	a5,80001bc8 <allocproc+0x40>
      release(&p->lock);
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	0c2080e7          	jalr	194(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbc:	16848493          	addi	s1,s1,360
    80001bc0:	ff2492e3          	bne	s1,s2,80001ba4 <allocproc+0x1c>
  return 0;
    80001bc4:	4481                	li	s1,0
    80001bc6:	a889                	j	80001c18 <allocproc+0x90>
  p->pid = allocpid();
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	e34080e7          	jalr	-460(ra) # 800019fc <allocpid>
    80001bd0:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bd2:	4785                	li	a5,1
    80001bd4:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	efc080e7          	jalr	-260(ra) # 80000ad2 <kalloc>
    80001bde:	892a                	mv	s2,a0
    80001be0:	eca8                	sd	a0,88(s1)
    80001be2:	c131                	beqz	a0,80001c26 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001be4:	8526                	mv	a0,s1
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	e5c080e7          	jalr	-420(ra) # 80001a42 <proc_pagetable>
    80001bee:	892a                	mv	s2,a0
    80001bf0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001bf2:	c531                	beqz	a0,80001c3e <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001bf4:	07000613          	li	a2,112
    80001bf8:	4581                	li	a1,0
    80001bfa:	06048513          	addi	a0,s1,96
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	0c0080e7          	jalr	192(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c06:	00000797          	auipc	a5,0x0
    80001c0a:	db078793          	addi	a5,a5,-592 # 800019b6 <forkret>
    80001c0e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c10:	60bc                	ld	a5,64(s1)
    80001c12:	6705                	lui	a4,0x1
    80001c14:	97ba                	add	a5,a5,a4
    80001c16:	f4bc                	sd	a5,104(s1)
}
    80001c18:	8526                	mv	a0,s1
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6902                	ld	s2,0(sp)
    80001c22:	6105                	addi	sp,sp,32
    80001c24:	8082                	ret
    freeproc(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	f08080e7          	jalr	-248(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c30:	8526                	mv	a0,s1
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	044080e7          	jalr	68(ra) # 80000c76 <release>
    return 0;
    80001c3a:	84ca                	mv	s1,s2
    80001c3c:	bff1                	j	80001c18 <allocproc+0x90>
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	ef0080e7          	jalr	-272(ra) # 80001b30 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	02c080e7          	jalr	44(ra) # 80000c76 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	b7d1                	j	80001c18 <allocproc+0x90>

0000000080001c56 <userinit>:
{
    80001c56:	1101                	addi	sp,sp,-32
    80001c58:	ec06                	sd	ra,24(sp)
    80001c5a:	e822                	sd	s0,16(sp)
    80001c5c:	e426                	sd	s1,8(sp)
    80001c5e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	f28080e7          	jalr	-216(ra) # 80001b88 <allocproc>
    80001c68:	84aa                	mv	s1,a0
  initproc = p;
    80001c6a:	00007797          	auipc	a5,0x7
    80001c6e:	3aa7bf23          	sd	a0,958(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c72:	03400613          	li	a2,52
    80001c76:	00007597          	auipc	a1,0x7
    80001c7a:	d0a58593          	addi	a1,a1,-758 # 80008980 <initcode>
    80001c7e:	6928                	ld	a0,80(a0)
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	6b4080e7          	jalr	1716(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001c88:	6785                	lui	a5,0x1
    80001c8a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001c8c:	6cb8                	ld	a4,88(s1)
    80001c8e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001c92:	6cb8                	ld	a4,88(s1)
    80001c94:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001c96:	4641                	li	a2,16
    80001c98:	00006597          	auipc	a1,0x6
    80001c9c:	55058593          	addi	a1,a1,1360 # 800081e8 <digits+0x1a8>
    80001ca0:	15848513          	addi	a0,s1,344
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	16c080e7          	jalr	364(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cac:	00006517          	auipc	a0,0x6
    80001cb0:	54c50513          	addi	a0,a0,1356 # 800081f8 <digits+0x1b8>
    80001cb4:	00002097          	auipc	ra,0x2
    80001cb8:	318080e7          	jalr	792(ra) # 80003fcc <namei>
    80001cbc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cc0:	478d                	li	a5,3
    80001cc2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	fb0080e7          	jalr	-80(ra) # 80000c76 <release>
}
    80001cce:	60e2                	ld	ra,24(sp)
    80001cd0:	6442                	ld	s0,16(sp)
    80001cd2:	64a2                	ld	s1,8(sp)
    80001cd4:	6105                	addi	sp,sp,32
    80001cd6:	8082                	ret

0000000080001cd8 <growproc>:
{
    80001cd8:	1101                	addi	sp,sp,-32
    80001cda:	ec06                	sd	ra,24(sp)
    80001cdc:	e822                	sd	s0,16(sp)
    80001cde:	e426                	sd	s1,8(sp)
    80001ce0:	e04a                	sd	s2,0(sp)
    80001ce2:	1000                	addi	s0,sp,32
    80001ce4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	c98080e7          	jalr	-872(ra) # 8000197e <myproc>
    80001cee:	892a                	mv	s2,a0
  sz = p->sz;
    80001cf0:	652c                	ld	a1,72(a0)
    80001cf2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001cf6:	00904f63          	bgtz	s1,80001d14 <growproc+0x3c>
  } else if(n < 0){
    80001cfa:	0204cc63          	bltz	s1,80001d32 <growproc+0x5a>
  p->sz = sz;
    80001cfe:	1602                	slli	a2,a2,0x20
    80001d00:	9201                	srli	a2,a2,0x20
    80001d02:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d06:	4501                	li	a0,0
}
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6902                	ld	s2,0(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d14:	9e25                	addw	a2,a2,s1
    80001d16:	1602                	slli	a2,a2,0x20
    80001d18:	9201                	srli	a2,a2,0x20
    80001d1a:	1582                	slli	a1,a1,0x20
    80001d1c:	9181                	srli	a1,a1,0x20
    80001d1e:	6928                	ld	a0,80(a0)
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	6ce080e7          	jalr	1742(ra) # 800013ee <uvmalloc>
    80001d28:	0005061b          	sext.w	a2,a0
    80001d2c:	fa69                	bnez	a2,80001cfe <growproc+0x26>
      return -1;
    80001d2e:	557d                	li	a0,-1
    80001d30:	bfe1                	j	80001d08 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d32:	9e25                	addw	a2,a2,s1
    80001d34:	1602                	slli	a2,a2,0x20
    80001d36:	9201                	srli	a2,a2,0x20
    80001d38:	1582                	slli	a1,a1,0x20
    80001d3a:	9181                	srli	a1,a1,0x20
    80001d3c:	6928                	ld	a0,80(a0)
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	668080e7          	jalr	1640(ra) # 800013a6 <uvmdealloc>
    80001d46:	0005061b          	sext.w	a2,a0
    80001d4a:	bf55                	j	80001cfe <growproc+0x26>

0000000080001d4c <fork>:
{
    80001d4c:	7139                	addi	sp,sp,-64
    80001d4e:	fc06                	sd	ra,56(sp)
    80001d50:	f822                	sd	s0,48(sp)
    80001d52:	f426                	sd	s1,40(sp)
    80001d54:	f04a                	sd	s2,32(sp)
    80001d56:	ec4e                	sd	s3,24(sp)
    80001d58:	e852                	sd	s4,16(sp)
    80001d5a:	e456                	sd	s5,8(sp)
    80001d5c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	c20080e7          	jalr	-992(ra) # 8000197e <myproc>
    80001d66:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	e20080e7          	jalr	-480(ra) # 80001b88 <allocproc>
    80001d70:	12050063          	beqz	a0,80001e90 <fork+0x144>
    80001d74:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d76:	048ab603          	ld	a2,72(s5)
    80001d7a:	692c                	ld	a1,80(a0)
    80001d7c:	050ab503          	ld	a0,80(s5)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	7ba080e7          	jalr	1978(ra) # 8000153a <uvmcopy>
    80001d88:	04054863          	bltz	a0,80001dd8 <fork+0x8c>
  np->sz = p->sz;
    80001d8c:	048ab783          	ld	a5,72(s5)
    80001d90:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001d94:	058ab683          	ld	a3,88(s5)
    80001d98:	87b6                	mv	a5,a3
    80001d9a:	0589b703          	ld	a4,88(s3)
    80001d9e:	12068693          	addi	a3,a3,288
    80001da2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001da6:	6788                	ld	a0,8(a5)
    80001da8:	6b8c                	ld	a1,16(a5)
    80001daa:	6f90                	ld	a2,24(a5)
    80001dac:	01073023          	sd	a6,0(a4)
    80001db0:	e708                	sd	a0,8(a4)
    80001db2:	eb0c                	sd	a1,16(a4)
    80001db4:	ef10                	sd	a2,24(a4)
    80001db6:	02078793          	addi	a5,a5,32
    80001dba:	02070713          	addi	a4,a4,32
    80001dbe:	fed792e3          	bne	a5,a3,80001da2 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dc2:	0589b783          	ld	a5,88(s3)
    80001dc6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dca:	0d0a8493          	addi	s1,s5,208
    80001dce:	0d098913          	addi	s2,s3,208
    80001dd2:	150a8a13          	addi	s4,s5,336
    80001dd6:	a00d                	j	80001df8 <fork+0xac>
    freeproc(np);
    80001dd8:	854e                	mv	a0,s3
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	d56080e7          	jalr	-682(ra) # 80001b30 <freeproc>
    release(&np->lock);
    80001de2:	854e                	mv	a0,s3
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	e92080e7          	jalr	-366(ra) # 80000c76 <release>
    return -1;
    80001dec:	597d                	li	s2,-1
    80001dee:	a079                	j	80001e7c <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001df0:	04a1                	addi	s1,s1,8
    80001df2:	0921                	addi	s2,s2,8
    80001df4:	01448b63          	beq	s1,s4,80001e0a <fork+0xbe>
    if(p->ofile[i])
    80001df8:	6088                	ld	a0,0(s1)
    80001dfa:	d97d                	beqz	a0,80001df0 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001dfc:	00003097          	auipc	ra,0x3
    80001e00:	86a080e7          	jalr	-1942(ra) # 80004666 <filedup>
    80001e04:	00a93023          	sd	a0,0(s2)
    80001e08:	b7e5                	j	80001df0 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e0a:	150ab503          	ld	a0,336(s5)
    80001e0e:	00002097          	auipc	ra,0x2
    80001e12:	9ca080e7          	jalr	-1590(ra) # 800037d8 <idup>
    80001e16:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e1a:	4641                	li	a2,16
    80001e1c:	158a8593          	addi	a1,s5,344
    80001e20:	15898513          	addi	a0,s3,344
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	fec080e7          	jalr	-20(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e2c:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e30:	854e                	mv	a0,s3
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e44080e7          	jalr	-444(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e3a:	0000f497          	auipc	s1,0xf
    80001e3e:	47e48493          	addi	s1,s1,1150 # 800112b8 <wait_lock>
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	d7e080e7          	jalr	-642(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e4c:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e24080e7          	jalr	-476(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e5a:	854e                	mv	a0,s3
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	d66080e7          	jalr	-666(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001e64:	478d                	li	a5,3
    80001e66:	00f9ac23          	sw	a5,24(s3)
  np->trace_mask = p->trace_mask;
    80001e6a:	034aa783          	lw	a5,52(s5)
    80001e6e:	02f9aa23          	sw	a5,52(s3)
  release(&np->lock);
    80001e72:	854e                	mv	a0,s3
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e02080e7          	jalr	-510(ra) # 80000c76 <release>
}
    80001e7c:	854a                	mv	a0,s2
    80001e7e:	70e2                	ld	ra,56(sp)
    80001e80:	7442                	ld	s0,48(sp)
    80001e82:	74a2                	ld	s1,40(sp)
    80001e84:	7902                	ld	s2,32(sp)
    80001e86:	69e2                	ld	s3,24(sp)
    80001e88:	6a42                	ld	s4,16(sp)
    80001e8a:	6aa2                	ld	s5,8(sp)
    80001e8c:	6121                	addi	sp,sp,64
    80001e8e:	8082                	ret
    return -1;
    80001e90:	597d                	li	s2,-1
    80001e92:	b7ed                	j	80001e7c <fork+0x130>

0000000080001e94 <scheduler>:
{
    80001e94:	7139                	addi	sp,sp,-64
    80001e96:	fc06                	sd	ra,56(sp)
    80001e98:	f822                	sd	s0,48(sp)
    80001e9a:	f426                	sd	s1,40(sp)
    80001e9c:	f04a                	sd	s2,32(sp)
    80001e9e:	ec4e                	sd	s3,24(sp)
    80001ea0:	e852                	sd	s4,16(sp)
    80001ea2:	e456                	sd	s5,8(sp)
    80001ea4:	e05a                	sd	s6,0(sp)
    80001ea6:	0080                	addi	s0,sp,64
    80001ea8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eaa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eac:	00779a93          	slli	s5,a5,0x7
    80001eb0:	0000f717          	auipc	a4,0xf
    80001eb4:	3f070713          	addi	a4,a4,1008 # 800112a0 <pid_lock>
    80001eb8:	9756                	add	a4,a4,s5
    80001eba:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	41a70713          	addi	a4,a4,1050 # 800112d8 <cpus+0x8>
    80001ec6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ec8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eca:	4b11                	li	s6,4
        c->proc = p;
    80001ecc:	079e                	slli	a5,a5,0x7
    80001ece:	0000fa17          	auipc	s4,0xf
    80001ed2:	3d2a0a13          	addi	s4,s4,978 # 800112a0 <pid_lock>
    80001ed6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ed8:	00015917          	auipc	s2,0x15
    80001edc:	1f890913          	addi	s2,s2,504 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ee0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ee4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ee8:	10079073          	csrw	sstatus,a5
    80001eec:	0000f497          	auipc	s1,0xf
    80001ef0:	7e448493          	addi	s1,s1,2020 # 800116d0 <proc>
    80001ef4:	a811                	j	80001f08 <scheduler+0x74>
      release(&p->lock);
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	d7e080e7          	jalr	-642(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f00:	16848493          	addi	s1,s1,360
    80001f04:	fd248ee3          	beq	s1,s2,80001ee0 <scheduler+0x4c>
      acquire(&p->lock);
    80001f08:	8526                	mv	a0,s1
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	cb8080e7          	jalr	-840(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f12:	4c9c                	lw	a5,24(s1)
    80001f14:	ff3791e3          	bne	a5,s3,80001ef6 <scheduler+0x62>
        p->state = RUNNING;
    80001f18:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f1c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f20:	06048593          	addi	a1,s1,96
    80001f24:	8556                	mv	a0,s5
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	68a080e7          	jalr	1674(ra) # 800025b0 <swtch>
        c->proc = 0;
    80001f2e:	020a3823          	sd	zero,48(s4)
    80001f32:	b7d1                	j	80001ef6 <scheduler+0x62>

0000000080001f34 <sched>:
{
    80001f34:	7179                	addi	sp,sp,-48
    80001f36:	f406                	sd	ra,40(sp)
    80001f38:	f022                	sd	s0,32(sp)
    80001f3a:	ec26                	sd	s1,24(sp)
    80001f3c:	e84a                	sd	s2,16(sp)
    80001f3e:	e44e                	sd	s3,8(sp)
    80001f40:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	a3c080e7          	jalr	-1476(ra) # 8000197e <myproc>
    80001f4a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	bfc080e7          	jalr	-1028(ra) # 80000b48 <holding>
    80001f54:	c93d                	beqz	a0,80001fca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f56:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f58:	2781                	sext.w	a5,a5
    80001f5a:	079e                	slli	a5,a5,0x7
    80001f5c:	0000f717          	auipc	a4,0xf
    80001f60:	34470713          	addi	a4,a4,836 # 800112a0 <pid_lock>
    80001f64:	97ba                	add	a5,a5,a4
    80001f66:	0a87a703          	lw	a4,168(a5)
    80001f6a:	4785                	li	a5,1
    80001f6c:	06f71763          	bne	a4,a5,80001fda <sched+0xa6>
  if(p->state == RUNNING)
    80001f70:	4c98                	lw	a4,24(s1)
    80001f72:	4791                	li	a5,4
    80001f74:	06f70b63          	beq	a4,a5,80001fea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f78:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f7c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f7e:	efb5                	bnez	a5,80001ffa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f80:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f82:	0000f917          	auipc	s2,0xf
    80001f86:	31e90913          	addi	s2,s2,798 # 800112a0 <pid_lock>
    80001f8a:	2781                	sext.w	a5,a5
    80001f8c:	079e                	slli	a5,a5,0x7
    80001f8e:	97ca                	add	a5,a5,s2
    80001f90:	0ac7a983          	lw	s3,172(a5)
    80001f94:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f96:	2781                	sext.w	a5,a5
    80001f98:	079e                	slli	a5,a5,0x7
    80001f9a:	0000f597          	auipc	a1,0xf
    80001f9e:	33e58593          	addi	a1,a1,830 # 800112d8 <cpus+0x8>
    80001fa2:	95be                	add	a1,a1,a5
    80001fa4:	06048513          	addi	a0,s1,96
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	608080e7          	jalr	1544(ra) # 800025b0 <swtch>
    80001fb0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fb2:	2781                	sext.w	a5,a5
    80001fb4:	079e                	slli	a5,a5,0x7
    80001fb6:	97ca                	add	a5,a5,s2
    80001fb8:	0b37a623          	sw	s3,172(a5)
}
    80001fbc:	70a2                	ld	ra,40(sp)
    80001fbe:	7402                	ld	s0,32(sp)
    80001fc0:	64e2                	ld	s1,24(sp)
    80001fc2:	6942                	ld	s2,16(sp)
    80001fc4:	69a2                	ld	s3,8(sp)
    80001fc6:	6145                	addi	sp,sp,48
    80001fc8:	8082                	ret
    panic("sched p->lock");
    80001fca:	00006517          	auipc	a0,0x6
    80001fce:	23650513          	addi	a0,a0,566 # 80008200 <digits+0x1c0>
    80001fd2:	ffffe097          	auipc	ra,0xffffe
    80001fd6:	558080e7          	jalr	1368(ra) # 8000052a <panic>
    panic("sched locks");
    80001fda:	00006517          	auipc	a0,0x6
    80001fde:	23650513          	addi	a0,a0,566 # 80008210 <digits+0x1d0>
    80001fe2:	ffffe097          	auipc	ra,0xffffe
    80001fe6:	548080e7          	jalr	1352(ra) # 8000052a <panic>
    panic("sched running");
    80001fea:	00006517          	auipc	a0,0x6
    80001fee:	23650513          	addi	a0,a0,566 # 80008220 <digits+0x1e0>
    80001ff2:	ffffe097          	auipc	ra,0xffffe
    80001ff6:	538080e7          	jalr	1336(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001ffa:	00006517          	auipc	a0,0x6
    80001ffe:	23650513          	addi	a0,a0,566 # 80008230 <digits+0x1f0>
    80002002:	ffffe097          	auipc	ra,0xffffe
    80002006:	528080e7          	jalr	1320(ra) # 8000052a <panic>

000000008000200a <yield>:
{
    8000200a:	1101                	addi	sp,sp,-32
    8000200c:	ec06                	sd	ra,24(sp)
    8000200e:	e822                	sd	s0,16(sp)
    80002010:	e426                	sd	s1,8(sp)
    80002012:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	96a080e7          	jalr	-1686(ra) # 8000197e <myproc>
    8000201c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	ba4080e7          	jalr	-1116(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002026:	478d                	li	a5,3
    80002028:	cc9c                	sw	a5,24(s1)
  sched();
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	f0a080e7          	jalr	-246(ra) # 80001f34 <sched>
  release(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	c42080e7          	jalr	-958(ra) # 80000c76 <release>
}
    8000203c:	60e2                	ld	ra,24(sp)
    8000203e:	6442                	ld	s0,16(sp)
    80002040:	64a2                	ld	s1,8(sp)
    80002042:	6105                	addi	sp,sp,32
    80002044:	8082                	ret

0000000080002046 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002046:	7179                	addi	sp,sp,-48
    80002048:	f406                	sd	ra,40(sp)
    8000204a:	f022                	sd	s0,32(sp)
    8000204c:	ec26                	sd	s1,24(sp)
    8000204e:	e84a                	sd	s2,16(sp)
    80002050:	e44e                	sd	s3,8(sp)
    80002052:	1800                	addi	s0,sp,48
    80002054:	89aa                	mv	s3,a0
    80002056:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	926080e7          	jalr	-1754(ra) # 8000197e <myproc>
    80002060:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	b60080e7          	jalr	-1184(ra) # 80000bc2 <acquire>
  release(lk);
    8000206a:	854a                	mv	a0,s2
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	c0a080e7          	jalr	-1014(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002074:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002078:	4789                	li	a5,2
    8000207a:	cc9c                	sw	a5,24(s1)

  sched();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	eb8080e7          	jalr	-328(ra) # 80001f34 <sched>

  // Tidy up.
  p->chan = 0;
    80002084:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002088:	8526                	mv	a0,s1
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	bec080e7          	jalr	-1044(ra) # 80000c76 <release>
  acquire(lk);
    80002092:	854a                	mv	a0,s2
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b2e080e7          	jalr	-1234(ra) # 80000bc2 <acquire>
}
    8000209c:	70a2                	ld	ra,40(sp)
    8000209e:	7402                	ld	s0,32(sp)
    800020a0:	64e2                	ld	s1,24(sp)
    800020a2:	6942                	ld	s2,16(sp)
    800020a4:	69a2                	ld	s3,8(sp)
    800020a6:	6145                	addi	sp,sp,48
    800020a8:	8082                	ret

00000000800020aa <wait>:
{
    800020aa:	715d                	addi	sp,sp,-80
    800020ac:	e486                	sd	ra,72(sp)
    800020ae:	e0a2                	sd	s0,64(sp)
    800020b0:	fc26                	sd	s1,56(sp)
    800020b2:	f84a                	sd	s2,48(sp)
    800020b4:	f44e                	sd	s3,40(sp)
    800020b6:	f052                	sd	s4,32(sp)
    800020b8:	ec56                	sd	s5,24(sp)
    800020ba:	e85a                	sd	s6,16(sp)
    800020bc:	e45e                	sd	s7,8(sp)
    800020be:	e062                	sd	s8,0(sp)
    800020c0:	0880                	addi	s0,sp,80
    800020c2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	8ba080e7          	jalr	-1862(ra) # 8000197e <myproc>
    800020cc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020ce:	0000f517          	auipc	a0,0xf
    800020d2:	1ea50513          	addi	a0,a0,490 # 800112b8 <wait_lock>
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	aec080e7          	jalr	-1300(ra) # 80000bc2 <acquire>
    havekids = 0;
    800020de:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020e0:	4a15                	li	s4,5
        havekids = 1;
    800020e2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020e4:	00015997          	auipc	s3,0x15
    800020e8:	fec98993          	addi	s3,s3,-20 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020ec:	0000fc17          	auipc	s8,0xf
    800020f0:	1ccc0c13          	addi	s8,s8,460 # 800112b8 <wait_lock>
    havekids = 0;
    800020f4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020f6:	0000f497          	auipc	s1,0xf
    800020fa:	5da48493          	addi	s1,s1,1498 # 800116d0 <proc>
    800020fe:	a0bd                	j	8000216c <wait+0xc2>
          pid = np->pid;
    80002100:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002104:	000b0e63          	beqz	s6,80002120 <wait+0x76>
    80002108:	4691                	li	a3,4
    8000210a:	02c48613          	addi	a2,s1,44
    8000210e:	85da                	mv	a1,s6
    80002110:	05093503          	ld	a0,80(s2)
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	52a080e7          	jalr	1322(ra) # 8000163e <copyout>
    8000211c:	02054563          	bltz	a0,80002146 <wait+0x9c>
          freeproc(np);
    80002120:	8526                	mv	a0,s1
    80002122:	00000097          	auipc	ra,0x0
    80002126:	a0e080e7          	jalr	-1522(ra) # 80001b30 <freeproc>
          release(&np->lock);
    8000212a:	8526                	mv	a0,s1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	b4a080e7          	jalr	-1206(ra) # 80000c76 <release>
          release(&wait_lock);
    80002134:	0000f517          	auipc	a0,0xf
    80002138:	18450513          	addi	a0,a0,388 # 800112b8 <wait_lock>
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b3a080e7          	jalr	-1222(ra) # 80000c76 <release>
          return pid;
    80002144:	a09d                	j	800021aa <wait+0x100>
            release(&np->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b2e080e7          	jalr	-1234(ra) # 80000c76 <release>
            release(&wait_lock);
    80002150:	0000f517          	auipc	a0,0xf
    80002154:	16850513          	addi	a0,a0,360 # 800112b8 <wait_lock>
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b1e080e7          	jalr	-1250(ra) # 80000c76 <release>
            return -1;
    80002160:	59fd                	li	s3,-1
    80002162:	a0a1                	j	800021aa <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002164:	16848493          	addi	s1,s1,360
    80002168:	03348463          	beq	s1,s3,80002190 <wait+0xe6>
      if(np->parent == p){
    8000216c:	7c9c                	ld	a5,56(s1)
    8000216e:	ff279be3          	bne	a5,s2,80002164 <wait+0xba>
        acquire(&np->lock);
    80002172:	8526                	mv	a0,s1
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	a4e080e7          	jalr	-1458(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000217c:	4c9c                	lw	a5,24(s1)
    8000217e:	f94781e3          	beq	a5,s4,80002100 <wait+0x56>
        release(&np->lock);
    80002182:	8526                	mv	a0,s1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	af2080e7          	jalr	-1294(ra) # 80000c76 <release>
        havekids = 1;
    8000218c:	8756                	mv	a4,s5
    8000218e:	bfd9                	j	80002164 <wait+0xba>
    if(!havekids || p->killed){
    80002190:	c701                	beqz	a4,80002198 <wait+0xee>
    80002192:	02892783          	lw	a5,40(s2)
    80002196:	c79d                	beqz	a5,800021c4 <wait+0x11a>
      release(&wait_lock);
    80002198:	0000f517          	auipc	a0,0xf
    8000219c:	12050513          	addi	a0,a0,288 # 800112b8 <wait_lock>
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	ad6080e7          	jalr	-1322(ra) # 80000c76 <release>
      return -1;
    800021a8:	59fd                	li	s3,-1
}
    800021aa:	854e                	mv	a0,s3
    800021ac:	60a6                	ld	ra,72(sp)
    800021ae:	6406                	ld	s0,64(sp)
    800021b0:	74e2                	ld	s1,56(sp)
    800021b2:	7942                	ld	s2,48(sp)
    800021b4:	79a2                	ld	s3,40(sp)
    800021b6:	7a02                	ld	s4,32(sp)
    800021b8:	6ae2                	ld	s5,24(sp)
    800021ba:	6b42                	ld	s6,16(sp)
    800021bc:	6ba2                	ld	s7,8(sp)
    800021be:	6c02                	ld	s8,0(sp)
    800021c0:	6161                	addi	sp,sp,80
    800021c2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021c4:	85e2                	mv	a1,s8
    800021c6:	854a                	mv	a0,s2
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	e7e080e7          	jalr	-386(ra) # 80002046 <sleep>
    havekids = 0;
    800021d0:	b715                	j	800020f4 <wait+0x4a>

00000000800021d2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021d2:	7139                	addi	sp,sp,-64
    800021d4:	fc06                	sd	ra,56(sp)
    800021d6:	f822                	sd	s0,48(sp)
    800021d8:	f426                	sd	s1,40(sp)
    800021da:	f04a                	sd	s2,32(sp)
    800021dc:	ec4e                	sd	s3,24(sp)
    800021de:	e852                	sd	s4,16(sp)
    800021e0:	e456                	sd	s5,8(sp)
    800021e2:	0080                	addi	s0,sp,64
    800021e4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021e6:	0000f497          	auipc	s1,0xf
    800021ea:	4ea48493          	addi	s1,s1,1258 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021ee:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021f0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021f2:	00015917          	auipc	s2,0x15
    800021f6:	ede90913          	addi	s2,s2,-290 # 800170d0 <tickslock>
    800021fa:	a811                	j	8000220e <wakeup+0x3c>
      }
      release(&p->lock);
    800021fc:	8526                	mv	a0,s1
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	a78080e7          	jalr	-1416(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002206:	16848493          	addi	s1,s1,360
    8000220a:	03248663          	beq	s1,s2,80002236 <wakeup+0x64>
    if(p != myproc()){
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	770080e7          	jalr	1904(ra) # 8000197e <myproc>
    80002216:	fea488e3          	beq	s1,a0,80002206 <wakeup+0x34>
      acquire(&p->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	9a6080e7          	jalr	-1626(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002224:	4c9c                	lw	a5,24(s1)
    80002226:	fd379be3          	bne	a5,s3,800021fc <wakeup+0x2a>
    8000222a:	709c                	ld	a5,32(s1)
    8000222c:	fd4798e3          	bne	a5,s4,800021fc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002230:	0154ac23          	sw	s5,24(s1)
    80002234:	b7e1                	j	800021fc <wakeup+0x2a>
    }
  }
}
    80002236:	70e2                	ld	ra,56(sp)
    80002238:	7442                	ld	s0,48(sp)
    8000223a:	74a2                	ld	s1,40(sp)
    8000223c:	7902                	ld	s2,32(sp)
    8000223e:	69e2                	ld	s3,24(sp)
    80002240:	6a42                	ld	s4,16(sp)
    80002242:	6aa2                	ld	s5,8(sp)
    80002244:	6121                	addi	sp,sp,64
    80002246:	8082                	ret

0000000080002248 <reparent>:
{
    80002248:	7179                	addi	sp,sp,-48
    8000224a:	f406                	sd	ra,40(sp)
    8000224c:	f022                	sd	s0,32(sp)
    8000224e:	ec26                	sd	s1,24(sp)
    80002250:	e84a                	sd	s2,16(sp)
    80002252:	e44e                	sd	s3,8(sp)
    80002254:	e052                	sd	s4,0(sp)
    80002256:	1800                	addi	s0,sp,48
    80002258:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000225a:	0000f497          	auipc	s1,0xf
    8000225e:	47648493          	addi	s1,s1,1142 # 800116d0 <proc>
      pp->parent = initproc;
    80002262:	00007a17          	auipc	s4,0x7
    80002266:	dc6a0a13          	addi	s4,s4,-570 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226a:	00015997          	auipc	s3,0x15
    8000226e:	e6698993          	addi	s3,s3,-410 # 800170d0 <tickslock>
    80002272:	a029                	j	8000227c <reparent+0x34>
    80002274:	16848493          	addi	s1,s1,360
    80002278:	01348d63          	beq	s1,s3,80002292 <reparent+0x4a>
    if(pp->parent == p){
    8000227c:	7c9c                	ld	a5,56(s1)
    8000227e:	ff279be3          	bne	a5,s2,80002274 <reparent+0x2c>
      pp->parent = initproc;
    80002282:	000a3503          	ld	a0,0(s4)
    80002286:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	f4a080e7          	jalr	-182(ra) # 800021d2 <wakeup>
    80002290:	b7d5                	j	80002274 <reparent+0x2c>
}
    80002292:	70a2                	ld	ra,40(sp)
    80002294:	7402                	ld	s0,32(sp)
    80002296:	64e2                	ld	s1,24(sp)
    80002298:	6942                	ld	s2,16(sp)
    8000229a:	69a2                	ld	s3,8(sp)
    8000229c:	6a02                	ld	s4,0(sp)
    8000229e:	6145                	addi	sp,sp,48
    800022a0:	8082                	ret

00000000800022a2 <exit>:
{
    800022a2:	7179                	addi	sp,sp,-48
    800022a4:	f406                	sd	ra,40(sp)
    800022a6:	f022                	sd	s0,32(sp)
    800022a8:	ec26                	sd	s1,24(sp)
    800022aa:	e84a                	sd	s2,16(sp)
    800022ac:	e44e                	sd	s3,8(sp)
    800022ae:	e052                	sd	s4,0(sp)
    800022b0:	1800                	addi	s0,sp,48
    800022b2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	6ca080e7          	jalr	1738(ra) # 8000197e <myproc>
    800022bc:	89aa                	mv	s3,a0
  if(p == initproc)
    800022be:	00007797          	auipc	a5,0x7
    800022c2:	d6a7b783          	ld	a5,-662(a5) # 80009028 <initproc>
    800022c6:	0d050493          	addi	s1,a0,208
    800022ca:	15050913          	addi	s2,a0,336
    800022ce:	02a79363          	bne	a5,a0,800022f4 <exit+0x52>
    panic("init exiting");
    800022d2:	00006517          	auipc	a0,0x6
    800022d6:	f7650513          	addi	a0,a0,-138 # 80008248 <digits+0x208>
    800022da:	ffffe097          	auipc	ra,0xffffe
    800022de:	250080e7          	jalr	592(ra) # 8000052a <panic>
      fileclose(f);
    800022e2:	00002097          	auipc	ra,0x2
    800022e6:	3d6080e7          	jalr	982(ra) # 800046b8 <fileclose>
      p->ofile[fd] = 0;
    800022ea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022ee:	04a1                	addi	s1,s1,8
    800022f0:	01248563          	beq	s1,s2,800022fa <exit+0x58>
    if(p->ofile[fd]){
    800022f4:	6088                	ld	a0,0(s1)
    800022f6:	f575                	bnez	a0,800022e2 <exit+0x40>
    800022f8:	bfdd                	j	800022ee <exit+0x4c>
  begin_op();
    800022fa:	00002097          	auipc	ra,0x2
    800022fe:	ef2080e7          	jalr	-270(ra) # 800041ec <begin_op>
  iput(p->cwd);
    80002302:	1509b503          	ld	a0,336(s3)
    80002306:	00001097          	auipc	ra,0x1
    8000230a:	6ca080e7          	jalr	1738(ra) # 800039d0 <iput>
  end_op();
    8000230e:	00002097          	auipc	ra,0x2
    80002312:	f5e080e7          	jalr	-162(ra) # 8000426c <end_op>
  p->cwd = 0;
    80002316:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000231a:	0000f497          	auipc	s1,0xf
    8000231e:	f9e48493          	addi	s1,s1,-98 # 800112b8 <wait_lock>
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	89e080e7          	jalr	-1890(ra) # 80000bc2 <acquire>
  reparent(p);
    8000232c:	854e                	mv	a0,s3
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	f1a080e7          	jalr	-230(ra) # 80002248 <reparent>
  wakeup(p->parent);
    80002336:	0389b503          	ld	a0,56(s3)
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	e98080e7          	jalr	-360(ra) # 800021d2 <wakeup>
  acquire(&p->lock);
    80002342:	854e                	mv	a0,s3
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	87e080e7          	jalr	-1922(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000234c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002350:	4795                	li	a5,5
    80002352:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	91e080e7          	jalr	-1762(ra) # 80000c76 <release>
  sched();
    80002360:	00000097          	auipc	ra,0x0
    80002364:	bd4080e7          	jalr	-1068(ra) # 80001f34 <sched>
  panic("zombie exit");
    80002368:	00006517          	auipc	a0,0x6
    8000236c:	ef050513          	addi	a0,a0,-272 # 80008258 <digits+0x218>
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	1ba080e7          	jalr	442(ra) # 8000052a <panic>

0000000080002378 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002378:	7179                	addi	sp,sp,-48
    8000237a:	f406                	sd	ra,40(sp)
    8000237c:	f022                	sd	s0,32(sp)
    8000237e:	ec26                	sd	s1,24(sp)
    80002380:	e84a                	sd	s2,16(sp)
    80002382:	e44e                	sd	s3,8(sp)
    80002384:	1800                	addi	s0,sp,48
    80002386:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002388:	0000f497          	auipc	s1,0xf
    8000238c:	34848493          	addi	s1,s1,840 # 800116d0 <proc>
    80002390:	00015997          	auipc	s3,0x15
    80002394:	d4098993          	addi	s3,s3,-704 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	828080e7          	jalr	-2008(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800023a2:	589c                	lw	a5,48(s1)
    800023a4:	01278d63          	beq	a5,s2,800023be <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	8cc080e7          	jalr	-1844(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023b2:	16848493          	addi	s1,s1,360
    800023b6:	ff3491e3          	bne	s1,s3,80002398 <kill+0x20>
  }
  return -1;
    800023ba:	557d                	li	a0,-1
    800023bc:	a829                	j	800023d6 <kill+0x5e>
      p->killed = 1;
    800023be:	4785                	li	a5,1
    800023c0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023c2:	4c98                	lw	a4,24(s1)
    800023c4:	4789                	li	a5,2
    800023c6:	00f70f63          	beq	a4,a5,800023e4 <kill+0x6c>
      release(&p->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8aa080e7          	jalr	-1878(ra) # 80000c76 <release>
      return 0;
    800023d4:	4501                	li	a0,0
}
    800023d6:	70a2                	ld	ra,40(sp)
    800023d8:	7402                	ld	s0,32(sp)
    800023da:	64e2                	ld	s1,24(sp)
    800023dc:	6942                	ld	s2,16(sp)
    800023de:	69a2                	ld	s3,8(sp)
    800023e0:	6145                	addi	sp,sp,48
    800023e2:	8082                	ret
        p->state = RUNNABLE;
    800023e4:	478d                	li	a5,3
    800023e6:	cc9c                	sw	a5,24(s1)
    800023e8:	b7cd                	j	800023ca <kill+0x52>

00000000800023ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023ea:	7179                	addi	sp,sp,-48
    800023ec:	f406                	sd	ra,40(sp)
    800023ee:	f022                	sd	s0,32(sp)
    800023f0:	ec26                	sd	s1,24(sp)
    800023f2:	e84a                	sd	s2,16(sp)
    800023f4:	e44e                	sd	s3,8(sp)
    800023f6:	e052                	sd	s4,0(sp)
    800023f8:	1800                	addi	s0,sp,48
    800023fa:	84aa                	mv	s1,a0
    800023fc:	892e                	mv	s2,a1
    800023fe:	89b2                	mv	s3,a2
    80002400:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	57c080e7          	jalr	1404(ra) # 8000197e <myproc>
  if(user_dst){
    8000240a:	c08d                	beqz	s1,8000242c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000240c:	86d2                	mv	a3,s4
    8000240e:	864e                	mv	a2,s3
    80002410:	85ca                	mv	a1,s2
    80002412:	6928                	ld	a0,80(a0)
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	22a080e7          	jalr	554(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000241c:	70a2                	ld	ra,40(sp)
    8000241e:	7402                	ld	s0,32(sp)
    80002420:	64e2                	ld	s1,24(sp)
    80002422:	6942                	ld	s2,16(sp)
    80002424:	69a2                	ld	s3,8(sp)
    80002426:	6a02                	ld	s4,0(sp)
    80002428:	6145                	addi	sp,sp,48
    8000242a:	8082                	ret
    memmove((char *)dst, src, len);
    8000242c:	000a061b          	sext.w	a2,s4
    80002430:	85ce                	mv	a1,s3
    80002432:	854a                	mv	a0,s2
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	8e6080e7          	jalr	-1818(ra) # 80000d1a <memmove>
    return 0;
    8000243c:	8526                	mv	a0,s1
    8000243e:	bff9                	j	8000241c <either_copyout+0x32>

0000000080002440 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002440:	7179                	addi	sp,sp,-48
    80002442:	f406                	sd	ra,40(sp)
    80002444:	f022                	sd	s0,32(sp)
    80002446:	ec26                	sd	s1,24(sp)
    80002448:	e84a                	sd	s2,16(sp)
    8000244a:	e44e                	sd	s3,8(sp)
    8000244c:	e052                	sd	s4,0(sp)
    8000244e:	1800                	addi	s0,sp,48
    80002450:	892a                	mv	s2,a0
    80002452:	84ae                	mv	s1,a1
    80002454:	89b2                	mv	s3,a2
    80002456:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	526080e7          	jalr	1318(ra) # 8000197e <myproc>
  if(user_src){
    80002460:	c08d                	beqz	s1,80002482 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002462:	86d2                	mv	a3,s4
    80002464:	864e                	mv	a2,s3
    80002466:	85ca                	mv	a1,s2
    80002468:	6928                	ld	a0,80(a0)
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	260080e7          	jalr	608(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002472:	70a2                	ld	ra,40(sp)
    80002474:	7402                	ld	s0,32(sp)
    80002476:	64e2                	ld	s1,24(sp)
    80002478:	6942                	ld	s2,16(sp)
    8000247a:	69a2                	ld	s3,8(sp)
    8000247c:	6a02                	ld	s4,0(sp)
    8000247e:	6145                	addi	sp,sp,48
    80002480:	8082                	ret
    memmove(dst, (char*)src, len);
    80002482:	000a061b          	sext.w	a2,s4
    80002486:	85ce                	mv	a1,s3
    80002488:	854a                	mv	a0,s2
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	890080e7          	jalr	-1904(ra) # 80000d1a <memmove>
    return 0;
    80002492:	8526                	mv	a0,s1
    80002494:	bff9                	j	80002472 <either_copyin+0x32>

0000000080002496 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002496:	715d                	addi	sp,sp,-80
    80002498:	e486                	sd	ra,72(sp)
    8000249a:	e0a2                	sd	s0,64(sp)
    8000249c:	fc26                	sd	s1,56(sp)
    8000249e:	f84a                	sd	s2,48(sp)
    800024a0:	f44e                	sd	s3,40(sp)
    800024a2:	f052                	sd	s4,32(sp)
    800024a4:	ec56                	sd	s5,24(sp)
    800024a6:	e85a                	sd	s6,16(sp)
    800024a8:	e45e                	sd	s7,8(sp)
    800024aa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024ac:	00006517          	auipc	a0,0x6
    800024b0:	c1c50513          	addi	a0,a0,-996 # 800080c8 <digits+0x88>
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	0c0080e7          	jalr	192(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024bc:	0000f497          	auipc	s1,0xf
    800024c0:	36c48493          	addi	s1,s1,876 # 80011828 <proc+0x158>
    800024c4:	00015917          	auipc	s2,0x15
    800024c8:	d6490913          	addi	s2,s2,-668 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024cc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024ce:	00006997          	auipc	s3,0x6
    800024d2:	d9a98993          	addi	s3,s3,-614 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800024d6:	00006a97          	auipc	s5,0x6
    800024da:	d9aa8a93          	addi	s5,s5,-614 # 80008270 <digits+0x230>
    printf("\n");
    800024de:	00006a17          	auipc	s4,0x6
    800024e2:	beaa0a13          	addi	s4,s4,-1046 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024e6:	00006b97          	auipc	s7,0x6
    800024ea:	dc2b8b93          	addi	s7,s7,-574 # 800082a8 <states.0>
    800024ee:	a00d                	j	80002510 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800024f0:	ed86a583          	lw	a1,-296(a3)
    800024f4:	8556                	mv	a0,s5
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	07e080e7          	jalr	126(ra) # 80000574 <printf>
    printf("\n");
    800024fe:	8552                	mv	a0,s4
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	074080e7          	jalr	116(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002508:	16848493          	addi	s1,s1,360
    8000250c:	03248263          	beq	s1,s2,80002530 <procdump+0x9a>
    if(p->state == UNUSED)
    80002510:	86a6                	mv	a3,s1
    80002512:	ec04a783          	lw	a5,-320(s1)
    80002516:	dbed                	beqz	a5,80002508 <procdump+0x72>
      state = "???";
    80002518:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000251a:	fcfb6be3          	bltu	s6,a5,800024f0 <procdump+0x5a>
    8000251e:	02079713          	slli	a4,a5,0x20
    80002522:	01d75793          	srli	a5,a4,0x1d
    80002526:	97de                	add	a5,a5,s7
    80002528:	6390                	ld	a2,0(a5)
    8000252a:	f279                	bnez	a2,800024f0 <procdump+0x5a>
      state = "???";
    8000252c:	864e                	mv	a2,s3
    8000252e:	b7c9                	j	800024f0 <procdump+0x5a>
  }
}
    80002530:	60a6                	ld	ra,72(sp)
    80002532:	6406                	ld	s0,64(sp)
    80002534:	74e2                	ld	s1,56(sp)
    80002536:	7942                	ld	s2,48(sp)
    80002538:	79a2                	ld	s3,40(sp)
    8000253a:	7a02                	ld	s4,32(sp)
    8000253c:	6ae2                	ld	s5,24(sp)
    8000253e:	6b42                	ld	s6,16(sp)
    80002540:	6ba2                	ld	s7,8(sp)
    80002542:	6161                	addi	sp,sp,80
    80002544:	8082                	ret

0000000080002546 <trace>:

int
trace(int mask, int pid){
    80002546:	7179                	addi	sp,sp,-48
    80002548:	f406                	sd	ra,40(sp)
    8000254a:	f022                	sd	s0,32(sp)
    8000254c:	ec26                	sd	s1,24(sp)
    8000254e:	e84a                	sd	s2,16(sp)
    80002550:	e44e                	sd	s3,8(sp)
    80002552:	e052                	sd	s4,0(sp)
    80002554:	1800                	addi	s0,sp,48
    80002556:	8a2a                	mv	s4,a0
    80002558:	892e                	mv	s2,a1
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000255a:	0000f497          	auipc	s1,0xf
    8000255e:	17648493          	addi	s1,s1,374 # 800116d0 <proc>
    80002562:	00015997          	auipc	s3,0x15
    80002566:	b6e98993          	addi	s3,s3,-1170 # 800170d0 <tickslock>
    acquire(&p->lock);
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	656080e7          	jalr	1622(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002574:	589c                	lw	a5,48(s1)
    80002576:	01278d63          	beq	a5,s2,80002590 <trace+0x4a>
      p->trace_mask = mask;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000257a:	8526                	mv	a0,s1
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	6fa080e7          	jalr	1786(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002584:	16848493          	addi	s1,s1,360
    80002588:	ff3491e3          	bne	s1,s3,8000256a <trace+0x24>
  }
  return -1;
    8000258c:	557d                	li	a0,-1
    8000258e:	a809                	j	800025a0 <trace+0x5a>
      p->trace_mask = mask;
    80002590:	0344aa23          	sw	s4,52(s1)
      release(&p->lock);
    80002594:	8526                	mv	a0,s1
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	6e0080e7          	jalr	1760(ra) # 80000c76 <release>
      return 0;
    8000259e:	4501                	li	a0,0
}
    800025a0:	70a2                	ld	ra,40(sp)
    800025a2:	7402                	ld	s0,32(sp)
    800025a4:	64e2                	ld	s1,24(sp)
    800025a6:	6942                	ld	s2,16(sp)
    800025a8:	69a2                	ld	s3,8(sp)
    800025aa:	6a02                	ld	s4,0(sp)
    800025ac:	6145                	addi	sp,sp,48
    800025ae:	8082                	ret

00000000800025b0 <swtch>:
    800025b0:	00153023          	sd	ra,0(a0)
    800025b4:	00253423          	sd	sp,8(a0)
    800025b8:	e900                	sd	s0,16(a0)
    800025ba:	ed04                	sd	s1,24(a0)
    800025bc:	03253023          	sd	s2,32(a0)
    800025c0:	03353423          	sd	s3,40(a0)
    800025c4:	03453823          	sd	s4,48(a0)
    800025c8:	03553c23          	sd	s5,56(a0)
    800025cc:	05653023          	sd	s6,64(a0)
    800025d0:	05753423          	sd	s7,72(a0)
    800025d4:	05853823          	sd	s8,80(a0)
    800025d8:	05953c23          	sd	s9,88(a0)
    800025dc:	07a53023          	sd	s10,96(a0)
    800025e0:	07b53423          	sd	s11,104(a0)
    800025e4:	0005b083          	ld	ra,0(a1)
    800025e8:	0085b103          	ld	sp,8(a1)
    800025ec:	6980                	ld	s0,16(a1)
    800025ee:	6d84                	ld	s1,24(a1)
    800025f0:	0205b903          	ld	s2,32(a1)
    800025f4:	0285b983          	ld	s3,40(a1)
    800025f8:	0305ba03          	ld	s4,48(a1)
    800025fc:	0385ba83          	ld	s5,56(a1)
    80002600:	0405bb03          	ld	s6,64(a1)
    80002604:	0485bb83          	ld	s7,72(a1)
    80002608:	0505bc03          	ld	s8,80(a1)
    8000260c:	0585bc83          	ld	s9,88(a1)
    80002610:	0605bd03          	ld	s10,96(a1)
    80002614:	0685bd83          	ld	s11,104(a1)
    80002618:	8082                	ret

000000008000261a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000261a:	1141                	addi	sp,sp,-16
    8000261c:	e406                	sd	ra,8(sp)
    8000261e:	e022                	sd	s0,0(sp)
    80002620:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002622:	00006597          	auipc	a1,0x6
    80002626:	cb658593          	addi	a1,a1,-842 # 800082d8 <states.0+0x30>
    8000262a:	00015517          	auipc	a0,0x15
    8000262e:	aa650513          	addi	a0,a0,-1370 # 800170d0 <tickslock>
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	500080e7          	jalr	1280(ra) # 80000b32 <initlock>
}
    8000263a:	60a2                	ld	ra,8(sp)
    8000263c:	6402                	ld	s0,0(sp)
    8000263e:	0141                	addi	sp,sp,16
    80002640:	8082                	ret

0000000080002642 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002642:	1141                	addi	sp,sp,-16
    80002644:	e422                	sd	s0,8(sp)
    80002646:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002648:	00003797          	auipc	a5,0x3
    8000264c:	69878793          	addi	a5,a5,1688 # 80005ce0 <kernelvec>
    80002650:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002654:	6422                	ld	s0,8(sp)
    80002656:	0141                	addi	sp,sp,16
    80002658:	8082                	ret

000000008000265a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000265a:	1141                	addi	sp,sp,-16
    8000265c:	e406                	sd	ra,8(sp)
    8000265e:	e022                	sd	s0,0(sp)
    80002660:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	31c080e7          	jalr	796(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000266a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000266e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002670:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002674:	00005617          	auipc	a2,0x5
    80002678:	98c60613          	addi	a2,a2,-1652 # 80007000 <_trampoline>
    8000267c:	00005697          	auipc	a3,0x5
    80002680:	98468693          	addi	a3,a3,-1660 # 80007000 <_trampoline>
    80002684:	8e91                	sub	a3,a3,a2
    80002686:	040007b7          	lui	a5,0x4000
    8000268a:	17fd                	addi	a5,a5,-1
    8000268c:	07b2                	slli	a5,a5,0xc
    8000268e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002690:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002694:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002696:	180026f3          	csrr	a3,satp
    8000269a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000269c:	6d38                	ld	a4,88(a0)
    8000269e:	6134                	ld	a3,64(a0)
    800026a0:	6585                	lui	a1,0x1
    800026a2:	96ae                	add	a3,a3,a1
    800026a4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026a6:	6d38                	ld	a4,88(a0)
    800026a8:	00000697          	auipc	a3,0x0
    800026ac:	13868693          	addi	a3,a3,312 # 800027e0 <usertrap>
    800026b0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026b2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026b4:	8692                	mv	a3,tp
    800026b6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026bc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026c0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ca:	6f18                	ld	a4,24(a4)
    800026cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026d0:	692c                	ld	a1,80(a0)
    800026d2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026d4:	00005717          	auipc	a4,0x5
    800026d8:	9bc70713          	addi	a4,a4,-1604 # 80007090 <userret>
    800026dc:	8f11                	sub	a4,a4,a2
    800026de:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026e0:	577d                	li	a4,-1
    800026e2:	177e                	slli	a4,a4,0x3f
    800026e4:	8dd9                	or	a1,a1,a4
    800026e6:	02000537          	lui	a0,0x2000
    800026ea:	157d                	addi	a0,a0,-1
    800026ec:	0536                	slli	a0,a0,0xd
    800026ee:	9782                	jalr	a5
}
    800026f0:	60a2                	ld	ra,8(sp)
    800026f2:	6402                	ld	s0,0(sp)
    800026f4:	0141                	addi	sp,sp,16
    800026f6:	8082                	ret

00000000800026f8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f8:	1101                	addi	sp,sp,-32
    800026fa:	ec06                	sd	ra,24(sp)
    800026fc:	e822                	sd	s0,16(sp)
    800026fe:	e426                	sd	s1,8(sp)
    80002700:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002702:	00015497          	auipc	s1,0x15
    80002706:	9ce48493          	addi	s1,s1,-1586 # 800170d0 <tickslock>
    8000270a:	8526                	mv	a0,s1
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	4b6080e7          	jalr	1206(ra) # 80000bc2 <acquire>
  ticks++;
    80002714:	00007517          	auipc	a0,0x7
    80002718:	91c50513          	addi	a0,a0,-1764 # 80009030 <ticks>
    8000271c:	411c                	lw	a5,0(a0)
    8000271e:	2785                	addiw	a5,a5,1
    80002720:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002722:	00000097          	auipc	ra,0x0
    80002726:	ab0080e7          	jalr	-1360(ra) # 800021d2 <wakeup>
  release(&tickslock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	54a080e7          	jalr	1354(ra) # 80000c76 <release>
}
    80002734:	60e2                	ld	ra,24(sp)
    80002736:	6442                	ld	s0,16(sp)
    80002738:	64a2                	ld	s1,8(sp)
    8000273a:	6105                	addi	sp,sp,32
    8000273c:	8082                	ret

000000008000273e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000273e:	1101                	addi	sp,sp,-32
    80002740:	ec06                	sd	ra,24(sp)
    80002742:	e822                	sd	s0,16(sp)
    80002744:	e426                	sd	s1,8(sp)
    80002746:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002748:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000274c:	00074d63          	bltz	a4,80002766 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002750:	57fd                	li	a5,-1
    80002752:	17fe                	slli	a5,a5,0x3f
    80002754:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002756:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002758:	06f70363          	beq	a4,a5,800027be <devintr+0x80>
  }
}
    8000275c:	60e2                	ld	ra,24(sp)
    8000275e:	6442                	ld	s0,16(sp)
    80002760:	64a2                	ld	s1,8(sp)
    80002762:	6105                	addi	sp,sp,32
    80002764:	8082                	ret
     (scause & 0xff) == 9){
    80002766:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000276a:	46a5                	li	a3,9
    8000276c:	fed792e3          	bne	a5,a3,80002750 <devintr+0x12>
    int irq = plic_claim();
    80002770:	00003097          	auipc	ra,0x3
    80002774:	678080e7          	jalr	1656(ra) # 80005de8 <plic_claim>
    80002778:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000277a:	47a9                	li	a5,10
    8000277c:	02f50763          	beq	a0,a5,800027aa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002780:	4785                	li	a5,1
    80002782:	02f50963          	beq	a0,a5,800027b4 <devintr+0x76>
    return 1;
    80002786:	4505                	li	a0,1
    } else if(irq){
    80002788:	d8f1                	beqz	s1,8000275c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000278a:	85a6                	mv	a1,s1
    8000278c:	00006517          	auipc	a0,0x6
    80002790:	b5450513          	addi	a0,a0,-1196 # 800082e0 <states.0+0x38>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	de0080e7          	jalr	-544(ra) # 80000574 <printf>
      plic_complete(irq);
    8000279c:	8526                	mv	a0,s1
    8000279e:	00003097          	auipc	ra,0x3
    800027a2:	66e080e7          	jalr	1646(ra) # 80005e0c <plic_complete>
    return 1;
    800027a6:	4505                	li	a0,1
    800027a8:	bf55                	j	8000275c <devintr+0x1e>
      uartintr();
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	1dc080e7          	jalr	476(ra) # 80000986 <uartintr>
    800027b2:	b7ed                	j	8000279c <devintr+0x5e>
      virtio_disk_intr();
    800027b4:	00004097          	auipc	ra,0x4
    800027b8:	aea080e7          	jalr	-1302(ra) # 8000629e <virtio_disk_intr>
    800027bc:	b7c5                	j	8000279c <devintr+0x5e>
    if(cpuid() == 0){
    800027be:	fffff097          	auipc	ra,0xfffff
    800027c2:	194080e7          	jalr	404(ra) # 80001952 <cpuid>
    800027c6:	c901                	beqz	a0,800027d6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027cc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ce:	14479073          	csrw	sip,a5
    return 2;
    800027d2:	4509                	li	a0,2
    800027d4:	b761                	j	8000275c <devintr+0x1e>
      clockintr();
    800027d6:	00000097          	auipc	ra,0x0
    800027da:	f22080e7          	jalr	-222(ra) # 800026f8 <clockintr>
    800027de:	b7ed                	j	800027c8 <devintr+0x8a>

00000000800027e0 <usertrap>:
{
    800027e0:	1101                	addi	sp,sp,-32
    800027e2:	ec06                	sd	ra,24(sp)
    800027e4:	e822                	sd	s0,16(sp)
    800027e6:	e426                	sd	s1,8(sp)
    800027e8:	e04a                	sd	s2,0(sp)
    800027ea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ec:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027f0:	1007f793          	andi	a5,a5,256
    800027f4:	e3ad                	bnez	a5,80002856 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f6:	00003797          	auipc	a5,0x3
    800027fa:	4ea78793          	addi	a5,a5,1258 # 80005ce0 <kernelvec>
    800027fe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002802:	fffff097          	auipc	ra,0xfffff
    80002806:	17c080e7          	jalr	380(ra) # 8000197e <myproc>
    8000280a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000280c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000280e:	14102773          	csrr	a4,sepc
    80002812:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002814:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002818:	47a1                	li	a5,8
    8000281a:	04f71c63          	bne	a4,a5,80002872 <usertrap+0x92>
    if(p->killed)
    8000281e:	551c                	lw	a5,40(a0)
    80002820:	e3b9                	bnez	a5,80002866 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002822:	6cb8                	ld	a4,88(s1)
    80002824:	6f1c                	ld	a5,24(a4)
    80002826:	0791                	addi	a5,a5,4
    80002828:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000282a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000282e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002832:	10079073          	csrw	sstatus,a5
    syscall();
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	3e8080e7          	jalr	1000(ra) # 80002c1e <syscall>
  if(p->killed)
    8000283e:	549c                	lw	a5,40(s1)
    80002840:	ebc1                	bnez	a5,800028d0 <usertrap+0xf0>
  usertrapret();
    80002842:	00000097          	auipc	ra,0x0
    80002846:	e18080e7          	jalr	-488(ra) # 8000265a <usertrapret>
}
    8000284a:	60e2                	ld	ra,24(sp)
    8000284c:	6442                	ld	s0,16(sp)
    8000284e:	64a2                	ld	s1,8(sp)
    80002850:	6902                	ld	s2,0(sp)
    80002852:	6105                	addi	sp,sp,32
    80002854:	8082                	ret
    panic("usertrap: not from user mode");
    80002856:	00006517          	auipc	a0,0x6
    8000285a:	aaa50513          	addi	a0,a0,-1366 # 80008300 <states.0+0x58>
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	ccc080e7          	jalr	-820(ra) # 8000052a <panic>
      exit(-1);
    80002866:	557d                	li	a0,-1
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	a3a080e7          	jalr	-1478(ra) # 800022a2 <exit>
    80002870:	bf4d                	j	80002822 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002872:	00000097          	auipc	ra,0x0
    80002876:	ecc080e7          	jalr	-308(ra) # 8000273e <devintr>
    8000287a:	892a                	mv	s2,a0
    8000287c:	c501                	beqz	a0,80002884 <usertrap+0xa4>
  if(p->killed)
    8000287e:	549c                	lw	a5,40(s1)
    80002880:	c3a1                	beqz	a5,800028c0 <usertrap+0xe0>
    80002882:	a815                	j	800028b6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002884:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002888:	5890                	lw	a2,48(s1)
    8000288a:	00006517          	auipc	a0,0x6
    8000288e:	a9650513          	addi	a0,a0,-1386 # 80008320 <states.0+0x78>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	ce2080e7          	jalr	-798(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000289a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000289e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028a2:	00006517          	auipc	a0,0x6
    800028a6:	aae50513          	addi	a0,a0,-1362 # 80008350 <states.0+0xa8>
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	cca080e7          	jalr	-822(ra) # 80000574 <printf>
    p->killed = 1;
    800028b2:	4785                	li	a5,1
    800028b4:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028b6:	557d                	li	a0,-1
    800028b8:	00000097          	auipc	ra,0x0
    800028bc:	9ea080e7          	jalr	-1558(ra) # 800022a2 <exit>
  if(which_dev == 2)
    800028c0:	4789                	li	a5,2
    800028c2:	f8f910e3          	bne	s2,a5,80002842 <usertrap+0x62>
    yield();
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	744080e7          	jalr	1860(ra) # 8000200a <yield>
    800028ce:	bf95                	j	80002842 <usertrap+0x62>
  int which_dev = 0;
    800028d0:	4901                	li	s2,0
    800028d2:	b7d5                	j	800028b6 <usertrap+0xd6>

00000000800028d4 <kerneltrap>:
{
    800028d4:	7179                	addi	sp,sp,-48
    800028d6:	f406                	sd	ra,40(sp)
    800028d8:	f022                	sd	s0,32(sp)
    800028da:	ec26                	sd	s1,24(sp)
    800028dc:	e84a                	sd	s2,16(sp)
    800028de:	e44e                	sd	s3,8(sp)
    800028e0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ea:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028ee:	1004f793          	andi	a5,s1,256
    800028f2:	cb85                	beqz	a5,80002922 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028f8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028fa:	ef85                	bnez	a5,80002932 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	e42080e7          	jalr	-446(ra) # 8000273e <devintr>
    80002904:	cd1d                	beqz	a0,80002942 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002906:	4789                	li	a5,2
    80002908:	06f50a63          	beq	a0,a5,8000297c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000290c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10049073          	csrw	sstatus,s1
}
    80002914:	70a2                	ld	ra,40(sp)
    80002916:	7402                	ld	s0,32(sp)
    80002918:	64e2                	ld	s1,24(sp)
    8000291a:	6942                	ld	s2,16(sp)
    8000291c:	69a2                	ld	s3,8(sp)
    8000291e:	6145                	addi	sp,sp,48
    80002920:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002922:	00006517          	auipc	a0,0x6
    80002926:	a4e50513          	addi	a0,a0,-1458 # 80008370 <states.0+0xc8>
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	c00080e7          	jalr	-1024(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002932:	00006517          	auipc	a0,0x6
    80002936:	a6650513          	addi	a0,a0,-1434 # 80008398 <states.0+0xf0>
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	bf0080e7          	jalr	-1040(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002942:	85ce                	mv	a1,s3
    80002944:	00006517          	auipc	a0,0x6
    80002948:	a7450513          	addi	a0,a0,-1420 # 800083b8 <states.0+0x110>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	c28080e7          	jalr	-984(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002954:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002958:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	a6c50513          	addi	a0,a0,-1428 # 800083c8 <states.0+0x120>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c10080e7          	jalr	-1008(ra) # 80000574 <printf>
    panic("kerneltrap");
    8000296c:	00006517          	auipc	a0,0x6
    80002970:	a7450513          	addi	a0,a0,-1420 # 800083e0 <states.0+0x138>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	bb6080e7          	jalr	-1098(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	002080e7          	jalr	2(ra) # 8000197e <myproc>
    80002984:	d541                	beqz	a0,8000290c <kerneltrap+0x38>
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	ff8080e7          	jalr	-8(ra) # 8000197e <myproc>
    8000298e:	4d18                	lw	a4,24(a0)
    80002990:	4791                	li	a5,4
    80002992:	f6f71de3          	bne	a4,a5,8000290c <kerneltrap+0x38>
    yield();
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	674080e7          	jalr	1652(ra) # 8000200a <yield>
    8000299e:	b7bd                	j	8000290c <kerneltrap+0x38>

00000000800029a0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029a0:	1101                	addi	sp,sp,-32
    800029a2:	ec06                	sd	ra,24(sp)
    800029a4:	e822                	sd	s0,16(sp)
    800029a6:	e426                	sd	s1,8(sp)
    800029a8:	1000                	addi	s0,sp,32
    800029aa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029ac:	fffff097          	auipc	ra,0xfffff
    800029b0:	fd2080e7          	jalr	-46(ra) # 8000197e <myproc>
  switch (n) {
    800029b4:	4795                	li	a5,5
    800029b6:	0497e163          	bltu	a5,s1,800029f8 <argraw+0x58>
    800029ba:	048a                	slli	s1,s1,0x2
    800029bc:	00006717          	auipc	a4,0x6
    800029c0:	b7470713          	addi	a4,a4,-1164 # 80008530 <states.0+0x288>
    800029c4:	94ba                	add	s1,s1,a4
    800029c6:	409c                	lw	a5,0(s1)
    800029c8:	97ba                	add	a5,a5,a4
    800029ca:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029cc:	6d3c                	ld	a5,88(a0)
    800029ce:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029d0:	60e2                	ld	ra,24(sp)
    800029d2:	6442                	ld	s0,16(sp)
    800029d4:	64a2                	ld	s1,8(sp)
    800029d6:	6105                	addi	sp,sp,32
    800029d8:	8082                	ret
    return p->trapframe->a1;
    800029da:	6d3c                	ld	a5,88(a0)
    800029dc:	7fa8                	ld	a0,120(a5)
    800029de:	bfcd                	j	800029d0 <argraw+0x30>
    return p->trapframe->a2;
    800029e0:	6d3c                	ld	a5,88(a0)
    800029e2:	63c8                	ld	a0,128(a5)
    800029e4:	b7f5                	j	800029d0 <argraw+0x30>
    return p->trapframe->a3;
    800029e6:	6d3c                	ld	a5,88(a0)
    800029e8:	67c8                	ld	a0,136(a5)
    800029ea:	b7dd                	j	800029d0 <argraw+0x30>
    return p->trapframe->a4;
    800029ec:	6d3c                	ld	a5,88(a0)
    800029ee:	6bc8                	ld	a0,144(a5)
    800029f0:	b7c5                	j	800029d0 <argraw+0x30>
    return p->trapframe->a5;
    800029f2:	6d3c                	ld	a5,88(a0)
    800029f4:	6fc8                	ld	a0,152(a5)
    800029f6:	bfe9                	j	800029d0 <argraw+0x30>
  panic("argraw");
    800029f8:	00006517          	auipc	a0,0x6
    800029fc:	9f850513          	addi	a0,a0,-1544 # 800083f0 <states.0+0x148>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b2a080e7          	jalr	-1238(ra) # 8000052a <panic>

0000000080002a08 <fetchaddr>:
{
    80002a08:	1101                	addi	sp,sp,-32
    80002a0a:	ec06                	sd	ra,24(sp)
    80002a0c:	e822                	sd	s0,16(sp)
    80002a0e:	e426                	sd	s1,8(sp)
    80002a10:	e04a                	sd	s2,0(sp)
    80002a12:	1000                	addi	s0,sp,32
    80002a14:	84aa                	mv	s1,a0
    80002a16:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	f66080e7          	jalr	-154(ra) # 8000197e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a20:	653c                	ld	a5,72(a0)
    80002a22:	02f4f863          	bgeu	s1,a5,80002a52 <fetchaddr+0x4a>
    80002a26:	00848713          	addi	a4,s1,8
    80002a2a:	02e7e663          	bltu	a5,a4,80002a56 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a2e:	46a1                	li	a3,8
    80002a30:	8626                	mv	a2,s1
    80002a32:	85ca                	mv	a1,s2
    80002a34:	6928                	ld	a0,80(a0)
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	c94080e7          	jalr	-876(ra) # 800016ca <copyin>
    80002a3e:	00a03533          	snez	a0,a0
    80002a42:	40a00533          	neg	a0,a0
}
    80002a46:	60e2                	ld	ra,24(sp)
    80002a48:	6442                	ld	s0,16(sp)
    80002a4a:	64a2                	ld	s1,8(sp)
    80002a4c:	6902                	ld	s2,0(sp)
    80002a4e:	6105                	addi	sp,sp,32
    80002a50:	8082                	ret
    return -1;
    80002a52:	557d                	li	a0,-1
    80002a54:	bfcd                	j	80002a46 <fetchaddr+0x3e>
    80002a56:	557d                	li	a0,-1
    80002a58:	b7fd                	j	80002a46 <fetchaddr+0x3e>

0000000080002a5a <fetchstr>:
{
    80002a5a:	7179                	addi	sp,sp,-48
    80002a5c:	f406                	sd	ra,40(sp)
    80002a5e:	f022                	sd	s0,32(sp)
    80002a60:	ec26                	sd	s1,24(sp)
    80002a62:	e84a                	sd	s2,16(sp)
    80002a64:	e44e                	sd	s3,8(sp)
    80002a66:	1800                	addi	s0,sp,48
    80002a68:	892a                	mv	s2,a0
    80002a6a:	84ae                	mv	s1,a1
    80002a6c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	f10080e7          	jalr	-240(ra) # 8000197e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a76:	86ce                	mv	a3,s3
    80002a78:	864a                	mv	a2,s2
    80002a7a:	85a6                	mv	a1,s1
    80002a7c:	6928                	ld	a0,80(a0)
    80002a7e:	fffff097          	auipc	ra,0xfffff
    80002a82:	cda080e7          	jalr	-806(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002a86:	00054763          	bltz	a0,80002a94 <fetchstr+0x3a>
  return strlen(buf);
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	3b6080e7          	jalr	950(ra) # 80000e42 <strlen>
}
    80002a94:	70a2                	ld	ra,40(sp)
    80002a96:	7402                	ld	s0,32(sp)
    80002a98:	64e2                	ld	s1,24(sp)
    80002a9a:	6942                	ld	s2,16(sp)
    80002a9c:	69a2                	ld	s3,8(sp)
    80002a9e:	6145                	addi	sp,sp,48
    80002aa0:	8082                	ret

0000000080002aa2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002aa2:	1101                	addi	sp,sp,-32
    80002aa4:	ec06                	sd	ra,24(sp)
    80002aa6:	e822                	sd	s0,16(sp)
    80002aa8:	e426                	sd	s1,8(sp)
    80002aaa:	1000                	addi	s0,sp,32
    80002aac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aae:	00000097          	auipc	ra,0x0
    80002ab2:	ef2080e7          	jalr	-270(ra) # 800029a0 <argraw>
    80002ab6:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ab8:	4501                	li	a0,0
    80002aba:	60e2                	ld	ra,24(sp)
    80002abc:	6442                	ld	s0,16(sp)
    80002abe:	64a2                	ld	s1,8(sp)
    80002ac0:	6105                	addi	sp,sp,32
    80002ac2:	8082                	ret

0000000080002ac4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ac4:	1101                	addi	sp,sp,-32
    80002ac6:	ec06                	sd	ra,24(sp)
    80002ac8:	e822                	sd	s0,16(sp)
    80002aca:	e426                	sd	s1,8(sp)
    80002acc:	1000                	addi	s0,sp,32
    80002ace:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	ed0080e7          	jalr	-304(ra) # 800029a0 <argraw>
    80002ad8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ada:	4501                	li	a0,0
    80002adc:	60e2                	ld	ra,24(sp)
    80002ade:	6442                	ld	s0,16(sp)
    80002ae0:	64a2                	ld	s1,8(sp)
    80002ae2:	6105                	addi	sp,sp,32
    80002ae4:	8082                	ret

0000000080002ae6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ae6:	1101                	addi	sp,sp,-32
    80002ae8:	ec06                	sd	ra,24(sp)
    80002aea:	e822                	sd	s0,16(sp)
    80002aec:	e426                	sd	s1,8(sp)
    80002aee:	e04a                	sd	s2,0(sp)
    80002af0:	1000                	addi	s0,sp,32
    80002af2:	84ae                	mv	s1,a1
    80002af4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002af6:	00000097          	auipc	ra,0x0
    80002afa:	eaa080e7          	jalr	-342(ra) # 800029a0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002afe:	864a                	mv	a2,s2
    80002b00:	85a6                	mv	a1,s1
    80002b02:	00000097          	auipc	ra,0x0
    80002b06:	f58080e7          	jalr	-168(ra) # 80002a5a <fetchstr>
}
    80002b0a:	60e2                	ld	ra,24(sp)
    80002b0c:	6442                	ld	s0,16(sp)
    80002b0e:	64a2                	ld	s1,8(sp)
    80002b10:	6902                	ld	s2,0(sp)
    80002b12:	6105                	addi	sp,sp,32
    80002b14:	8082                	ret

0000000080002b16 <get_syscall_name>:
[SYS_close]   sys_close,
[SYS_trace]   sys_trace,
};

char*
get_syscall_name(int num){
    80002b16:	1141                	addi	sp,sp,-16
    80002b18:	e422                	sd	s0,8(sp)
    80002b1a:	0800                	addi	s0,sp,16
  switch (num)
    80002b1c:	47d9                	li	a5,22
    80002b1e:	0ea7e663          	bltu	a5,a0,80002c0a <get_syscall_name+0xf4>
    80002b22:	050a                	slli	a0,a0,0x2
    80002b24:	00006717          	auipc	a4,0x6
    80002b28:	a2470713          	addi	a4,a4,-1500 # 80008548 <states.0+0x2a0>
    80002b2c:	953a                	add	a0,a0,a4
    80002b2e:	411c                	lw	a5,0(a0)
    80002b30:	97ba                	add	a5,a5,a4
    80002b32:	8782                	jr	a5
  case SYS_close:
    return "close";
    break;
  
  case SYS_trace:
    return "trace";
    80002b34:	00006517          	auipc	a0,0x6
    80002b38:	97c50513          	addi	a0,a0,-1668 # 800084b0 <states.0+0x208>
  
  default:
    return "unknown syscall name";
    break;
  }
}
    80002b3c:	6422                	ld	s0,8(sp)
    80002b3e:	0141                	addi	sp,sp,16
    80002b40:	8082                	ret
    return "wait";
    80002b42:	00006517          	auipc	a0,0x6
    80002b46:	8d650513          	addi	a0,a0,-1834 # 80008418 <states.0+0x170>
    80002b4a:	bfcd                	j	80002b3c <get_syscall_name+0x26>
    return "pipe";
    80002b4c:	00006517          	auipc	a0,0x6
    80002b50:	8d450513          	addi	a0,a0,-1836 # 80008420 <states.0+0x178>
    80002b54:	b7e5                	j	80002b3c <get_syscall_name+0x26>
    return "read";
    80002b56:	00006517          	auipc	a0,0x6
    80002b5a:	c2a50513          	addi	a0,a0,-982 # 80008780 <syscalls+0x1d8>
    80002b5e:	bff9                	j	80002b3c <get_syscall_name+0x26>
    return "kill";
    80002b60:	00006517          	auipc	a0,0x6
    80002b64:	8c850513          	addi	a0,a0,-1848 # 80008428 <states.0+0x180>
    80002b68:	bfd1                	j	80002b3c <get_syscall_name+0x26>
    return "exec";
    80002b6a:	00006517          	auipc	a0,0x6
    80002b6e:	8c650513          	addi	a0,a0,-1850 # 80008430 <states.0+0x188>
    80002b72:	b7e9                	j	80002b3c <get_syscall_name+0x26>
    return "fstat";
    80002b74:	00006517          	auipc	a0,0x6
    80002b78:	8c450513          	addi	a0,a0,-1852 # 80008438 <states.0+0x190>
    80002b7c:	b7c1                	j	80002b3c <get_syscall_name+0x26>
    return "chdir";
    80002b7e:	00006517          	auipc	a0,0x6
    80002b82:	8c250513          	addi	a0,a0,-1854 # 80008440 <states.0+0x198>
    80002b86:	bf5d                	j	80002b3c <get_syscall_name+0x26>
    return "dup";
    80002b88:	00006517          	auipc	a0,0x6
    80002b8c:	8c050513          	addi	a0,a0,-1856 # 80008448 <states.0+0x1a0>
    80002b90:	b775                	j	80002b3c <get_syscall_name+0x26>
    return "getpid";
    80002b92:	00006517          	auipc	a0,0x6
    80002b96:	8be50513          	addi	a0,a0,-1858 # 80008450 <states.0+0x1a8>
    80002b9a:	b74d                	j	80002b3c <get_syscall_name+0x26>
    return "sbrk";
    80002b9c:	00006517          	auipc	a0,0x6
    80002ba0:	8bc50513          	addi	a0,a0,-1860 # 80008458 <states.0+0x1b0>
    80002ba4:	bf61                	j	80002b3c <get_syscall_name+0x26>
    return "sleep";
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	8ba50513          	addi	a0,a0,-1862 # 80008460 <states.0+0x1b8>
    80002bae:	b779                	j	80002b3c <get_syscall_name+0x26>
    return "uptime";
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	8b850513          	addi	a0,a0,-1864 # 80008468 <states.0+0x1c0>
    80002bb8:	b751                	j	80002b3c <get_syscall_name+0x26>
    return "open";
    80002bba:	00006517          	auipc	a0,0x6
    80002bbe:	8b650513          	addi	a0,a0,-1866 # 80008470 <states.0+0x1c8>
    80002bc2:	bfad                	j	80002b3c <get_syscall_name+0x26>
    return "write";
    80002bc4:	00006517          	auipc	a0,0x6
    80002bc8:	8b450513          	addi	a0,a0,-1868 # 80008478 <states.0+0x1d0>
    80002bcc:	bf85                	j	80002b3c <get_syscall_name+0x26>
    return "mknod";
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	8b250513          	addi	a0,a0,-1870 # 80008480 <states.0+0x1d8>
    80002bd6:	b79d                	j	80002b3c <get_syscall_name+0x26>
    return "unlink";
    80002bd8:	00006517          	auipc	a0,0x6
    80002bdc:	8b050513          	addi	a0,a0,-1872 # 80008488 <states.0+0x1e0>
    80002be0:	bfb1                	j	80002b3c <get_syscall_name+0x26>
    return "link";
    80002be2:	00006517          	auipc	a0,0x6
    80002be6:	8ae50513          	addi	a0,a0,-1874 # 80008490 <states.0+0x1e8>
    80002bea:	bf89                	j	80002b3c <get_syscall_name+0x26>
    return "mkdir";
    80002bec:	00006517          	auipc	a0,0x6
    80002bf0:	8ac50513          	addi	a0,a0,-1876 # 80008498 <states.0+0x1f0>
    80002bf4:	b7a1                	j	80002b3c <get_syscall_name+0x26>
    return "close";
    80002bf6:	00006517          	auipc	a0,0x6
    80002bfa:	8aa50513          	addi	a0,a0,-1878 # 800084a0 <states.0+0x1f8>
    80002bfe:	bf3d                	j	80002b3c <get_syscall_name+0x26>
    return "trace";
    80002c00:	00006517          	auipc	a0,0x6
    80002c04:	8a850513          	addi	a0,a0,-1880 # 800084a8 <states.0+0x200>
    80002c08:	bf15                	j	80002b3c <get_syscall_name+0x26>
    return "unknown syscall name";
    80002c0a:	00005517          	auipc	a0,0x5
    80002c0e:	7ee50513          	addi	a0,a0,2030 # 800083f8 <states.0+0x150>
    80002c12:	b72d                	j	80002b3c <get_syscall_name+0x26>
    return "fork";
    80002c14:	00005517          	auipc	a0,0x5
    80002c18:	7fc50513          	addi	a0,a0,2044 # 80008410 <states.0+0x168>
    break;
    80002c1c:	b705                	j	80002b3c <get_syscall_name+0x26>

0000000080002c1e <syscall>:

void
syscall(void)
{
    80002c1e:	7139                	addi	sp,sp,-64
    80002c20:	fc06                	sd	ra,56(sp)
    80002c22:	f822                	sd	s0,48(sp)
    80002c24:	f426                	sd	s1,40(sp)
    80002c26:	f04a                	sd	s2,32(sp)
    80002c28:	ec4e                	sd	s3,24(sp)
    80002c2a:	e852                	sd	s4,16(sp)
    80002c2c:	e456                	sd	s5,8(sp)
    80002c2e:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	d4e080e7          	jalr	-690(ra) # 8000197e <myproc>
    80002c38:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3a:	6d3c                	ld	a5,88(a0)
    80002c3c:	77dc                	ld	a5,168(a5)
    80002c3e:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c42:	37fd                	addiw	a5,a5,-1
    80002c44:	4755                	li	a4,21
    80002c46:	0cf76163          	bltu	a4,a5,80002d08 <syscall+0xea>
    80002c4a:	00391713          	slli	a4,s2,0x3
    80002c4e:	00006797          	auipc	a5,0x6
    80002c52:	95a78793          	addi	a5,a5,-1702 # 800085a8 <syscalls>
    80002c56:	97ba                	add	a5,a5,a4
    80002c58:	0007b983          	ld	s3,0(a5)
    80002c5c:	0a098663          	beqz	s3,80002d08 <syscall+0xea>
  *ip = argraw(n);
    80002c60:	4501                	li	a0,0
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	d3e080e7          	jalr	-706(ra) # 800029a0 <argraw>
    80002c6a:	8a2a                	mv	s4,a0
    int arg;
    int arg_int = argint(0, &arg);
    p->trapframe->a0 = syscalls[num]();
    80002c6c:	0584ba83          	ld	s5,88(s1)
    80002c70:	9982                	jalr	s3
    80002c72:	06aab823          	sd	a0,112(s5)
    //Q2
    int syscall_on = p->trace_mask & (1 << num);
    80002c76:	4785                	li	a5,1
    80002c78:	0127973b          	sllw	a4,a5,s2
    80002c7c:	58dc                	lw	a5,52(s1)
    80002c7e:	8ff9                	and	a5,a5,a4

    if(syscall_on){
    80002c80:	2781                	sext.w	a5,a5
    80002c82:	c3d5                	beqz	a5,80002d26 <syscall+0x108>
  *ip = argraw(n);
    80002c84:	2a01                	sext.w	s4,s4
      char *syscall_name = get_syscall_name(num);
    80002c86:	854a                	mv	a0,s2
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	e8e080e7          	jalr	-370(ra) # 80002b16 <get_syscall_name>
    80002c90:	862a                	mv	a2,a0
      switch (num) {
    80002c92:	4799                	li	a5,6
    80002c94:	04f90063          	beq	s2,a5,80002cd4 <syscall+0xb6>
    80002c98:	47b1                	li	a5,12
    80002c9a:	04f90a63          	beq	s2,a5,80002cee <syscall+0xd0>
    80002c9e:	4785                	li	a5,1
    80002ca0:	00f90e63          	beq	s2,a5,80002cbc <syscall+0x9e>
          break;
        printf("%d: syscall %s %d -> %d\n",p->pid, syscall_name, arg, p->trapframe->a0);
        break;

      default:
        printf("%d: syscall %s -> %d\n",p->pid, syscall_name, p->trapframe->a0);
    80002ca4:	6cbc                	ld	a5,88(s1)
    80002ca6:	7bb4                	ld	a3,112(a5)
    80002ca8:	588c                	lw	a1,48(s1)
    80002caa:	00006517          	auipc	a0,0x6
    80002cae:	84e50513          	addi	a0,a0,-1970 # 800084f8 <states.0+0x250>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8c2080e7          	jalr	-1854(ra) # 80000574 <printf>
        break;
    80002cba:	a0b5                	j	80002d26 <syscall+0x108>
        printf("%d: syscall %s NULL -> %d\n",p->pid, syscall_name, p->trapframe->a0);
    80002cbc:	6cbc                	ld	a5,88(s1)
    80002cbe:	7bb4                	ld	a3,112(a5)
    80002cc0:	588c                	lw	a1,48(s1)
    80002cc2:	00005517          	auipc	a0,0x5
    80002cc6:	7f650513          	addi	a0,a0,2038 # 800084b8 <states.0+0x210>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	8aa080e7          	jalr	-1878(ra) # 80000574 <printf>
        break;
    80002cd2:	a891                	j	80002d26 <syscall+0x108>
        printf("%d: syscall %s %d -> %d\n",p->pid, syscall_name, arg, p->trapframe->a0);
    80002cd4:	6cbc                	ld	a5,88(s1)
    80002cd6:	7bb8                	ld	a4,112(a5)
    80002cd8:	86d2                	mv	a3,s4
    80002cda:	588c                	lw	a1,48(s1)
    80002cdc:	00005517          	auipc	a0,0x5
    80002ce0:	7fc50513          	addi	a0,a0,2044 # 800084d8 <states.0+0x230>
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	890080e7          	jalr	-1904(ra) # 80000574 <printf>
        break;
    80002cec:	a82d                	j	80002d26 <syscall+0x108>
        printf("%d: syscall %s %d -> %d\n",p->pid, syscall_name, arg, p->trapframe->a0);
    80002cee:	6cbc                	ld	a5,88(s1)
    80002cf0:	7bb8                	ld	a4,112(a5)
    80002cf2:	86d2                	mv	a3,s4
    80002cf4:	588c                	lw	a1,48(s1)
    80002cf6:	00005517          	auipc	a0,0x5
    80002cfa:	7e250513          	addi	a0,a0,2018 # 800084d8 <states.0+0x230>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	876080e7          	jalr	-1930(ra) # 80000574 <printf>
        break;
    80002d06:	a005                	j	80002d26 <syscall+0x108>
      }
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d08:	86ca                	mv	a3,s2
    80002d0a:	15848613          	addi	a2,s1,344
    80002d0e:	588c                	lw	a1,48(s1)
    80002d10:	00006517          	auipc	a0,0x6
    80002d14:	80050513          	addi	a0,a0,-2048 # 80008510 <states.0+0x268>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	85c080e7          	jalr	-1956(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d20:	6cbc                	ld	a5,88(s1)
    80002d22:	577d                	li	a4,-1
    80002d24:	fbb8                	sd	a4,112(a5)
  }
}
    80002d26:	70e2                	ld	ra,56(sp)
    80002d28:	7442                	ld	s0,48(sp)
    80002d2a:	74a2                	ld	s1,40(sp)
    80002d2c:	7902                	ld	s2,32(sp)
    80002d2e:	69e2                	ld	s3,24(sp)
    80002d30:	6a42                	ld	s4,16(sp)
    80002d32:	6aa2                	ld	s5,8(sp)
    80002d34:	6121                	addi	sp,sp,64
    80002d36:	8082                	ret

0000000080002d38 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d38:	1101                	addi	sp,sp,-32
    80002d3a:	ec06                	sd	ra,24(sp)
    80002d3c:	e822                	sd	s0,16(sp)
    80002d3e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d40:	fec40593          	addi	a1,s0,-20
    80002d44:	4501                	li	a0,0
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	d5c080e7          	jalr	-676(ra) # 80002aa2 <argint>
    return -1;
    80002d4e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d50:	00054963          	bltz	a0,80002d62 <sys_exit+0x2a>
  exit(n);
    80002d54:	fec42503          	lw	a0,-20(s0)
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	54a080e7          	jalr	1354(ra) # 800022a2 <exit>
  return 0;  // not reached
    80002d60:	4781                	li	a5,0
}
    80002d62:	853e                	mv	a0,a5
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret

0000000080002d6c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d6c:	1141                	addi	sp,sp,-16
    80002d6e:	e406                	sd	ra,8(sp)
    80002d70:	e022                	sd	s0,0(sp)
    80002d72:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	c0a080e7          	jalr	-1014(ra) # 8000197e <myproc>
}
    80002d7c:	5908                	lw	a0,48(a0)
    80002d7e:	60a2                	ld	ra,8(sp)
    80002d80:	6402                	ld	s0,0(sp)
    80002d82:	0141                	addi	sp,sp,16
    80002d84:	8082                	ret

0000000080002d86 <sys_fork>:

uint64
sys_fork(void)
{
    80002d86:	1141                	addi	sp,sp,-16
    80002d88:	e406                	sd	ra,8(sp)
    80002d8a:	e022                	sd	s0,0(sp)
    80002d8c:	0800                	addi	s0,sp,16
  return fork();
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	fbe080e7          	jalr	-66(ra) # 80001d4c <fork>
}
    80002d96:	60a2                	ld	ra,8(sp)
    80002d98:	6402                	ld	s0,0(sp)
    80002d9a:	0141                	addi	sp,sp,16
    80002d9c:	8082                	ret

0000000080002d9e <sys_wait>:

uint64
sys_wait(void)
{
    80002d9e:	1101                	addi	sp,sp,-32
    80002da0:	ec06                	sd	ra,24(sp)
    80002da2:	e822                	sd	s0,16(sp)
    80002da4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002da6:	fe840593          	addi	a1,s0,-24
    80002daa:	4501                	li	a0,0
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	d18080e7          	jalr	-744(ra) # 80002ac4 <argaddr>
    80002db4:	87aa                	mv	a5,a0
    return -1;
    80002db6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002db8:	0007c863          	bltz	a5,80002dc8 <sys_wait+0x2a>
  return wait(p);
    80002dbc:	fe843503          	ld	a0,-24(s0)
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	2ea080e7          	jalr	746(ra) # 800020aa <wait>
}
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret

0000000080002dd0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dd0:	7179                	addi	sp,sp,-48
    80002dd2:	f406                	sd	ra,40(sp)
    80002dd4:	f022                	sd	s0,32(sp)
    80002dd6:	ec26                	sd	s1,24(sp)
    80002dd8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dda:	fdc40593          	addi	a1,s0,-36
    80002dde:	4501                	li	a0,0
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	cc2080e7          	jalr	-830(ra) # 80002aa2 <argint>
    return -1;
    80002de8:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002dea:	00054f63          	bltz	a0,80002e08 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	b90080e7          	jalr	-1136(ra) # 8000197e <myproc>
    80002df6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002df8:	fdc42503          	lw	a0,-36(s0)
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	edc080e7          	jalr	-292(ra) # 80001cd8 <growproc>
    80002e04:	00054863          	bltz	a0,80002e14 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002e08:	8526                	mv	a0,s1
    80002e0a:	70a2                	ld	ra,40(sp)
    80002e0c:	7402                	ld	s0,32(sp)
    80002e0e:	64e2                	ld	s1,24(sp)
    80002e10:	6145                	addi	sp,sp,48
    80002e12:	8082                	ret
    return -1;
    80002e14:	54fd                	li	s1,-1
    80002e16:	bfcd                	j	80002e08 <sys_sbrk+0x38>

0000000080002e18 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e18:	7139                	addi	sp,sp,-64
    80002e1a:	fc06                	sd	ra,56(sp)
    80002e1c:	f822                	sd	s0,48(sp)
    80002e1e:	f426                	sd	s1,40(sp)
    80002e20:	f04a                	sd	s2,32(sp)
    80002e22:	ec4e                	sd	s3,24(sp)
    80002e24:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e26:	fcc40593          	addi	a1,s0,-52
    80002e2a:	4501                	li	a0,0
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	c76080e7          	jalr	-906(ra) # 80002aa2 <argint>
    return -1;
    80002e34:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e36:	06054563          	bltz	a0,80002ea0 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e3a:	00014517          	auipc	a0,0x14
    80002e3e:	29650513          	addi	a0,a0,662 # 800170d0 <tickslock>
    80002e42:	ffffe097          	auipc	ra,0xffffe
    80002e46:	d80080e7          	jalr	-640(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002e4a:	00006917          	auipc	s2,0x6
    80002e4e:	1e692903          	lw	s2,486(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e52:	fcc42783          	lw	a5,-52(s0)
    80002e56:	cf85                	beqz	a5,80002e8e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e58:	00014997          	auipc	s3,0x14
    80002e5c:	27898993          	addi	s3,s3,632 # 800170d0 <tickslock>
    80002e60:	00006497          	auipc	s1,0x6
    80002e64:	1d048493          	addi	s1,s1,464 # 80009030 <ticks>
    if(myproc()->killed){
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	b16080e7          	jalr	-1258(ra) # 8000197e <myproc>
    80002e70:	551c                	lw	a5,40(a0)
    80002e72:	ef9d                	bnez	a5,80002eb0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e74:	85ce                	mv	a1,s3
    80002e76:	8526                	mv	a0,s1
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	1ce080e7          	jalr	462(ra) # 80002046 <sleep>
  while(ticks - ticks0 < n){
    80002e80:	409c                	lw	a5,0(s1)
    80002e82:	412787bb          	subw	a5,a5,s2
    80002e86:	fcc42703          	lw	a4,-52(s0)
    80002e8a:	fce7efe3          	bltu	a5,a4,80002e68 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e8e:	00014517          	auipc	a0,0x14
    80002e92:	24250513          	addi	a0,a0,578 # 800170d0 <tickslock>
    80002e96:	ffffe097          	auipc	ra,0xffffe
    80002e9a:	de0080e7          	jalr	-544(ra) # 80000c76 <release>
  return 0;
    80002e9e:	4781                	li	a5,0
}
    80002ea0:	853e                	mv	a0,a5
    80002ea2:	70e2                	ld	ra,56(sp)
    80002ea4:	7442                	ld	s0,48(sp)
    80002ea6:	74a2                	ld	s1,40(sp)
    80002ea8:	7902                	ld	s2,32(sp)
    80002eaa:	69e2                	ld	s3,24(sp)
    80002eac:	6121                	addi	sp,sp,64
    80002eae:	8082                	ret
      release(&tickslock);
    80002eb0:	00014517          	auipc	a0,0x14
    80002eb4:	22050513          	addi	a0,a0,544 # 800170d0 <tickslock>
    80002eb8:	ffffe097          	auipc	ra,0xffffe
    80002ebc:	dbe080e7          	jalr	-578(ra) # 80000c76 <release>
      return -1;
    80002ec0:	57fd                	li	a5,-1
    80002ec2:	bff9                	j	80002ea0 <sys_sleep+0x88>

0000000080002ec4 <sys_kill>:

uint64
sys_kill(void)
{
    80002ec4:	1101                	addi	sp,sp,-32
    80002ec6:	ec06                	sd	ra,24(sp)
    80002ec8:	e822                	sd	s0,16(sp)
    80002eca:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ecc:	fec40593          	addi	a1,s0,-20
    80002ed0:	4501                	li	a0,0
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	bd0080e7          	jalr	-1072(ra) # 80002aa2 <argint>
    80002eda:	87aa                	mv	a5,a0
    return -1;
    80002edc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ede:	0007c863          	bltz	a5,80002eee <sys_kill+0x2a>
  return kill(pid);
    80002ee2:	fec42503          	lw	a0,-20(s0)
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	492080e7          	jalr	1170(ra) # 80002378 <kill>
}
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	6105                	addi	sp,sp,32
    80002ef4:	8082                	ret

0000000080002ef6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ef6:	1101                	addi	sp,sp,-32
    80002ef8:	ec06                	sd	ra,24(sp)
    80002efa:	e822                	sd	s0,16(sp)
    80002efc:	e426                	sd	s1,8(sp)
    80002efe:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f00:	00014517          	auipc	a0,0x14
    80002f04:	1d050513          	addi	a0,a0,464 # 800170d0 <tickslock>
    80002f08:	ffffe097          	auipc	ra,0xffffe
    80002f0c:	cba080e7          	jalr	-838(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002f10:	00006497          	auipc	s1,0x6
    80002f14:	1204a483          	lw	s1,288(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f18:	00014517          	auipc	a0,0x14
    80002f1c:	1b850513          	addi	a0,a0,440 # 800170d0 <tickslock>
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	d56080e7          	jalr	-682(ra) # 80000c76 <release>
  return xticks;
}
    80002f28:	02049513          	slli	a0,s1,0x20
    80002f2c:	9101                	srli	a0,a0,0x20
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	64a2                	ld	s1,8(sp)
    80002f34:	6105                	addi	sp,sp,32
    80002f36:	8082                	ret

0000000080002f38 <sys_trace>:

uint64
sys_trace(void)
{
    80002f38:	1101                	addi	sp,sp,-32
    80002f3a:	ec06                	sd	ra,24(sp)
    80002f3c:	e822                	sd	s0,16(sp)
    80002f3e:	1000                	addi	s0,sp,32
  int mask;
  int pid;

  if(argint(0, &mask) < 0)
    80002f40:	fec40593          	addi	a1,s0,-20
    80002f44:	4501                	li	a0,0
    80002f46:	00000097          	auipc	ra,0x0
    80002f4a:	b5c080e7          	jalr	-1188(ra) # 80002aa2 <argint>
    return -1;
    80002f4e:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0)
    80002f50:	02054563          	bltz	a0,80002f7a <sys_trace+0x42>

  if(argint(1, &pid) < 0)
    80002f54:	fe840593          	addi	a1,s0,-24
    80002f58:	4505                	li	a0,1
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	b48080e7          	jalr	-1208(ra) # 80002aa2 <argint>
    return -1;
    80002f62:	57fd                	li	a5,-1
  if(argint(1, &pid) < 0)
    80002f64:	00054b63          	bltz	a0,80002f7a <sys_trace+0x42>

  return trace(mask, pid);
    80002f68:	fe842583          	lw	a1,-24(s0)
    80002f6c:	fec42503          	lw	a0,-20(s0)
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	5d6080e7          	jalr	1494(ra) # 80002546 <trace>
    80002f78:	87aa                	mv	a5,a0
}
    80002f7a:	853e                	mv	a0,a5
    80002f7c:	60e2                	ld	ra,24(sp)
    80002f7e:	6442                	ld	s0,16(sp)
    80002f80:	6105                	addi	sp,sp,32
    80002f82:	8082                	ret

0000000080002f84 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f84:	7179                	addi	sp,sp,-48
    80002f86:	f406                	sd	ra,40(sp)
    80002f88:	f022                	sd	s0,32(sp)
    80002f8a:	ec26                	sd	s1,24(sp)
    80002f8c:	e84a                	sd	s2,16(sp)
    80002f8e:	e44e                	sd	s3,8(sp)
    80002f90:	e052                	sd	s4,0(sp)
    80002f92:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f94:	00005597          	auipc	a1,0x5
    80002f98:	6cc58593          	addi	a1,a1,1740 # 80008660 <syscalls+0xb8>
    80002f9c:	00014517          	auipc	a0,0x14
    80002fa0:	14c50513          	addi	a0,a0,332 # 800170e8 <bcache>
    80002fa4:	ffffe097          	auipc	ra,0xffffe
    80002fa8:	b8e080e7          	jalr	-1138(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fac:	0001c797          	auipc	a5,0x1c
    80002fb0:	13c78793          	addi	a5,a5,316 # 8001f0e8 <bcache+0x8000>
    80002fb4:	0001c717          	auipc	a4,0x1c
    80002fb8:	39c70713          	addi	a4,a4,924 # 8001f350 <bcache+0x8268>
    80002fbc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fc0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc4:	00014497          	auipc	s1,0x14
    80002fc8:	13c48493          	addi	s1,s1,316 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002fcc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fce:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fd0:	00005a17          	auipc	s4,0x5
    80002fd4:	698a0a13          	addi	s4,s4,1688 # 80008668 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002fd8:	2b893783          	ld	a5,696(s2)
    80002fdc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fde:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fe2:	85d2                	mv	a1,s4
    80002fe4:	01048513          	addi	a0,s1,16
    80002fe8:	00001097          	auipc	ra,0x1
    80002fec:	4c2080e7          	jalr	1218(ra) # 800044aa <initsleeplock>
    bcache.head.next->prev = b;
    80002ff0:	2b893783          	ld	a5,696(s2)
    80002ff4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ff6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ffa:	45848493          	addi	s1,s1,1112
    80002ffe:	fd349de3          	bne	s1,s3,80002fd8 <binit+0x54>
  }
}
    80003002:	70a2                	ld	ra,40(sp)
    80003004:	7402                	ld	s0,32(sp)
    80003006:	64e2                	ld	s1,24(sp)
    80003008:	6942                	ld	s2,16(sp)
    8000300a:	69a2                	ld	s3,8(sp)
    8000300c:	6a02                	ld	s4,0(sp)
    8000300e:	6145                	addi	sp,sp,48
    80003010:	8082                	ret

0000000080003012 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003012:	7179                	addi	sp,sp,-48
    80003014:	f406                	sd	ra,40(sp)
    80003016:	f022                	sd	s0,32(sp)
    80003018:	ec26                	sd	s1,24(sp)
    8000301a:	e84a                	sd	s2,16(sp)
    8000301c:	e44e                	sd	s3,8(sp)
    8000301e:	1800                	addi	s0,sp,48
    80003020:	892a                	mv	s2,a0
    80003022:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	0c450513          	addi	a0,a0,196 # 800170e8 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	b96080e7          	jalr	-1130(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003034:	0001c497          	auipc	s1,0x1c
    80003038:	36c4b483          	ld	s1,876(s1) # 8001f3a0 <bcache+0x82b8>
    8000303c:	0001c797          	auipc	a5,0x1c
    80003040:	31478793          	addi	a5,a5,788 # 8001f350 <bcache+0x8268>
    80003044:	02f48f63          	beq	s1,a5,80003082 <bread+0x70>
    80003048:	873e                	mv	a4,a5
    8000304a:	a021                	j	80003052 <bread+0x40>
    8000304c:	68a4                	ld	s1,80(s1)
    8000304e:	02e48a63          	beq	s1,a4,80003082 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003052:	449c                	lw	a5,8(s1)
    80003054:	ff279ce3          	bne	a5,s2,8000304c <bread+0x3a>
    80003058:	44dc                	lw	a5,12(s1)
    8000305a:	ff3799e3          	bne	a5,s3,8000304c <bread+0x3a>
      b->refcnt++;
    8000305e:	40bc                	lw	a5,64(s1)
    80003060:	2785                	addiw	a5,a5,1
    80003062:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003064:	00014517          	auipc	a0,0x14
    80003068:	08450513          	addi	a0,a0,132 # 800170e8 <bcache>
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	c0a080e7          	jalr	-1014(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003074:	01048513          	addi	a0,s1,16
    80003078:	00001097          	auipc	ra,0x1
    8000307c:	46c080e7          	jalr	1132(ra) # 800044e4 <acquiresleep>
      return b;
    80003080:	a8b9                	j	800030de <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003082:	0001c497          	auipc	s1,0x1c
    80003086:	3164b483          	ld	s1,790(s1) # 8001f398 <bcache+0x82b0>
    8000308a:	0001c797          	auipc	a5,0x1c
    8000308e:	2c678793          	addi	a5,a5,710 # 8001f350 <bcache+0x8268>
    80003092:	00f48863          	beq	s1,a5,800030a2 <bread+0x90>
    80003096:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003098:	40bc                	lw	a5,64(s1)
    8000309a:	cf81                	beqz	a5,800030b2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000309c:	64a4                	ld	s1,72(s1)
    8000309e:	fee49de3          	bne	s1,a4,80003098 <bread+0x86>
  panic("bget: no buffers");
    800030a2:	00005517          	auipc	a0,0x5
    800030a6:	5ce50513          	addi	a0,a0,1486 # 80008670 <syscalls+0xc8>
    800030aa:	ffffd097          	auipc	ra,0xffffd
    800030ae:	480080e7          	jalr	1152(ra) # 8000052a <panic>
      b->dev = dev;
    800030b2:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030b6:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030ba:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030be:	4785                	li	a5,1
    800030c0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030c2:	00014517          	auipc	a0,0x14
    800030c6:	02650513          	addi	a0,a0,38 # 800170e8 <bcache>
    800030ca:	ffffe097          	auipc	ra,0xffffe
    800030ce:	bac080e7          	jalr	-1108(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800030d2:	01048513          	addi	a0,s1,16
    800030d6:	00001097          	auipc	ra,0x1
    800030da:	40e080e7          	jalr	1038(ra) # 800044e4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030de:	409c                	lw	a5,0(s1)
    800030e0:	cb89                	beqz	a5,800030f2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030e2:	8526                	mv	a0,s1
    800030e4:	70a2                	ld	ra,40(sp)
    800030e6:	7402                	ld	s0,32(sp)
    800030e8:	64e2                	ld	s1,24(sp)
    800030ea:	6942                	ld	s2,16(sp)
    800030ec:	69a2                	ld	s3,8(sp)
    800030ee:	6145                	addi	sp,sp,48
    800030f0:	8082                	ret
    virtio_disk_rw(b, 0);
    800030f2:	4581                	li	a1,0
    800030f4:	8526                	mv	a0,s1
    800030f6:	00003097          	auipc	ra,0x3
    800030fa:	f20080e7          	jalr	-224(ra) # 80006016 <virtio_disk_rw>
    b->valid = 1;
    800030fe:	4785                	li	a5,1
    80003100:	c09c                	sw	a5,0(s1)
  return b;
    80003102:	b7c5                	j	800030e2 <bread+0xd0>

0000000080003104 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	e426                	sd	s1,8(sp)
    8000310c:	1000                	addi	s0,sp,32
    8000310e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003110:	0541                	addi	a0,a0,16
    80003112:	00001097          	auipc	ra,0x1
    80003116:	46c080e7          	jalr	1132(ra) # 8000457e <holdingsleep>
    8000311a:	cd01                	beqz	a0,80003132 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000311c:	4585                	li	a1,1
    8000311e:	8526                	mv	a0,s1
    80003120:	00003097          	auipc	ra,0x3
    80003124:	ef6080e7          	jalr	-266(ra) # 80006016 <virtio_disk_rw>
}
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	64a2                	ld	s1,8(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret
    panic("bwrite");
    80003132:	00005517          	auipc	a0,0x5
    80003136:	55650513          	addi	a0,a0,1366 # 80008688 <syscalls+0xe0>
    8000313a:	ffffd097          	auipc	ra,0xffffd
    8000313e:	3f0080e7          	jalr	1008(ra) # 8000052a <panic>

0000000080003142 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	e04a                	sd	s2,0(sp)
    8000314c:	1000                	addi	s0,sp,32
    8000314e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003150:	01050913          	addi	s2,a0,16
    80003154:	854a                	mv	a0,s2
    80003156:	00001097          	auipc	ra,0x1
    8000315a:	428080e7          	jalr	1064(ra) # 8000457e <holdingsleep>
    8000315e:	c92d                	beqz	a0,800031d0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003160:	854a                	mv	a0,s2
    80003162:	00001097          	auipc	ra,0x1
    80003166:	3d8080e7          	jalr	984(ra) # 8000453a <releasesleep>

  acquire(&bcache.lock);
    8000316a:	00014517          	auipc	a0,0x14
    8000316e:	f7e50513          	addi	a0,a0,-130 # 800170e8 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	a50080e7          	jalr	-1456(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000317a:	40bc                	lw	a5,64(s1)
    8000317c:	37fd                	addiw	a5,a5,-1
    8000317e:	0007871b          	sext.w	a4,a5
    80003182:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003184:	eb05                	bnez	a4,800031b4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003186:	68bc                	ld	a5,80(s1)
    80003188:	64b8                	ld	a4,72(s1)
    8000318a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000318c:	64bc                	ld	a5,72(s1)
    8000318e:	68b8                	ld	a4,80(s1)
    80003190:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003192:	0001c797          	auipc	a5,0x1c
    80003196:	f5678793          	addi	a5,a5,-170 # 8001f0e8 <bcache+0x8000>
    8000319a:	2b87b703          	ld	a4,696(a5)
    8000319e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031a0:	0001c717          	auipc	a4,0x1c
    800031a4:	1b070713          	addi	a4,a4,432 # 8001f350 <bcache+0x8268>
    800031a8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031aa:	2b87b703          	ld	a4,696(a5)
    800031ae:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031b0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031b4:	00014517          	auipc	a0,0x14
    800031b8:	f3450513          	addi	a0,a0,-204 # 800170e8 <bcache>
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	aba080e7          	jalr	-1350(ra) # 80000c76 <release>
}
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	64a2                	ld	s1,8(sp)
    800031ca:	6902                	ld	s2,0(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret
    panic("brelse");
    800031d0:	00005517          	auipc	a0,0x5
    800031d4:	4c050513          	addi	a0,a0,1216 # 80008690 <syscalls+0xe8>
    800031d8:	ffffd097          	auipc	ra,0xffffd
    800031dc:	352080e7          	jalr	850(ra) # 8000052a <panic>

00000000800031e0 <bpin>:

void
bpin(struct buf *b) {
    800031e0:	1101                	addi	sp,sp,-32
    800031e2:	ec06                	sd	ra,24(sp)
    800031e4:	e822                	sd	s0,16(sp)
    800031e6:	e426                	sd	s1,8(sp)
    800031e8:	1000                	addi	s0,sp,32
    800031ea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ec:	00014517          	auipc	a0,0x14
    800031f0:	efc50513          	addi	a0,a0,-260 # 800170e8 <bcache>
    800031f4:	ffffe097          	auipc	ra,0xffffe
    800031f8:	9ce080e7          	jalr	-1586(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800031fc:	40bc                	lw	a5,64(s1)
    800031fe:	2785                	addiw	a5,a5,1
    80003200:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003202:	00014517          	auipc	a0,0x14
    80003206:	ee650513          	addi	a0,a0,-282 # 800170e8 <bcache>
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	a6c080e7          	jalr	-1428(ra) # 80000c76 <release>
}
    80003212:	60e2                	ld	ra,24(sp)
    80003214:	6442                	ld	s0,16(sp)
    80003216:	64a2                	ld	s1,8(sp)
    80003218:	6105                	addi	sp,sp,32
    8000321a:	8082                	ret

000000008000321c <bunpin>:

void
bunpin(struct buf *b) {
    8000321c:	1101                	addi	sp,sp,-32
    8000321e:	ec06                	sd	ra,24(sp)
    80003220:	e822                	sd	s0,16(sp)
    80003222:	e426                	sd	s1,8(sp)
    80003224:	1000                	addi	s0,sp,32
    80003226:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003228:	00014517          	auipc	a0,0x14
    8000322c:	ec050513          	addi	a0,a0,-320 # 800170e8 <bcache>
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	992080e7          	jalr	-1646(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003238:	40bc                	lw	a5,64(s1)
    8000323a:	37fd                	addiw	a5,a5,-1
    8000323c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000323e:	00014517          	auipc	a0,0x14
    80003242:	eaa50513          	addi	a0,a0,-342 # 800170e8 <bcache>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	a30080e7          	jalr	-1488(ra) # 80000c76 <release>
}
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	64a2                	ld	s1,8(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret

0000000080003258 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	e426                	sd	s1,8(sp)
    80003260:	e04a                	sd	s2,0(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003266:	00d5d59b          	srliw	a1,a1,0xd
    8000326a:	0001c797          	auipc	a5,0x1c
    8000326e:	55a7a783          	lw	a5,1370(a5) # 8001f7c4 <sb+0x1c>
    80003272:	9dbd                	addw	a1,a1,a5
    80003274:	00000097          	auipc	ra,0x0
    80003278:	d9e080e7          	jalr	-610(ra) # 80003012 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000327c:	0074f713          	andi	a4,s1,7
    80003280:	4785                	li	a5,1
    80003282:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003286:	14ce                	slli	s1,s1,0x33
    80003288:	90d9                	srli	s1,s1,0x36
    8000328a:	00950733          	add	a4,a0,s1
    8000328e:	05874703          	lbu	a4,88(a4)
    80003292:	00e7f6b3          	and	a3,a5,a4
    80003296:	c69d                	beqz	a3,800032c4 <bfree+0x6c>
    80003298:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000329a:	94aa                	add	s1,s1,a0
    8000329c:	fff7c793          	not	a5,a5
    800032a0:	8ff9                	and	a5,a5,a4
    800032a2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032a6:	00001097          	auipc	ra,0x1
    800032aa:	11e080e7          	jalr	286(ra) # 800043c4 <log_write>
  brelse(bp);
    800032ae:	854a                	mv	a0,s2
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	e92080e7          	jalr	-366(ra) # 80003142 <brelse>
}
    800032b8:	60e2                	ld	ra,24(sp)
    800032ba:	6442                	ld	s0,16(sp)
    800032bc:	64a2                	ld	s1,8(sp)
    800032be:	6902                	ld	s2,0(sp)
    800032c0:	6105                	addi	sp,sp,32
    800032c2:	8082                	ret
    panic("freeing free block");
    800032c4:	00005517          	auipc	a0,0x5
    800032c8:	3d450513          	addi	a0,a0,980 # 80008698 <syscalls+0xf0>
    800032cc:	ffffd097          	auipc	ra,0xffffd
    800032d0:	25e080e7          	jalr	606(ra) # 8000052a <panic>

00000000800032d4 <balloc>:
{
    800032d4:	711d                	addi	sp,sp,-96
    800032d6:	ec86                	sd	ra,88(sp)
    800032d8:	e8a2                	sd	s0,80(sp)
    800032da:	e4a6                	sd	s1,72(sp)
    800032dc:	e0ca                	sd	s2,64(sp)
    800032de:	fc4e                	sd	s3,56(sp)
    800032e0:	f852                	sd	s4,48(sp)
    800032e2:	f456                	sd	s5,40(sp)
    800032e4:	f05a                	sd	s6,32(sp)
    800032e6:	ec5e                	sd	s7,24(sp)
    800032e8:	e862                	sd	s8,16(sp)
    800032ea:	e466                	sd	s9,8(sp)
    800032ec:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032ee:	0001c797          	auipc	a5,0x1c
    800032f2:	4be7a783          	lw	a5,1214(a5) # 8001f7ac <sb+0x4>
    800032f6:	cbd1                	beqz	a5,8000338a <balloc+0xb6>
    800032f8:	8baa                	mv	s7,a0
    800032fa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032fc:	0001cb17          	auipc	s6,0x1c
    80003300:	4acb0b13          	addi	s6,s6,1196 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003304:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003306:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003308:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000330a:	6c89                	lui	s9,0x2
    8000330c:	a831                	j	80003328 <balloc+0x54>
    brelse(bp);
    8000330e:	854a                	mv	a0,s2
    80003310:	00000097          	auipc	ra,0x0
    80003314:	e32080e7          	jalr	-462(ra) # 80003142 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003318:	015c87bb          	addw	a5,s9,s5
    8000331c:	00078a9b          	sext.w	s5,a5
    80003320:	004b2703          	lw	a4,4(s6)
    80003324:	06eaf363          	bgeu	s5,a4,8000338a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003328:	41fad79b          	sraiw	a5,s5,0x1f
    8000332c:	0137d79b          	srliw	a5,a5,0x13
    80003330:	015787bb          	addw	a5,a5,s5
    80003334:	40d7d79b          	sraiw	a5,a5,0xd
    80003338:	01cb2583          	lw	a1,28(s6)
    8000333c:	9dbd                	addw	a1,a1,a5
    8000333e:	855e                	mv	a0,s7
    80003340:	00000097          	auipc	ra,0x0
    80003344:	cd2080e7          	jalr	-814(ra) # 80003012 <bread>
    80003348:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000334a:	004b2503          	lw	a0,4(s6)
    8000334e:	000a849b          	sext.w	s1,s5
    80003352:	8662                	mv	a2,s8
    80003354:	faa4fde3          	bgeu	s1,a0,8000330e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003358:	41f6579b          	sraiw	a5,a2,0x1f
    8000335c:	01d7d69b          	srliw	a3,a5,0x1d
    80003360:	00c6873b          	addw	a4,a3,a2
    80003364:	00777793          	andi	a5,a4,7
    80003368:	9f95                	subw	a5,a5,a3
    8000336a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000336e:	4037571b          	sraiw	a4,a4,0x3
    80003372:	00e906b3          	add	a3,s2,a4
    80003376:	0586c683          	lbu	a3,88(a3)
    8000337a:	00d7f5b3          	and	a1,a5,a3
    8000337e:	cd91                	beqz	a1,8000339a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003380:	2605                	addiw	a2,a2,1
    80003382:	2485                	addiw	s1,s1,1
    80003384:	fd4618e3          	bne	a2,s4,80003354 <balloc+0x80>
    80003388:	b759                	j	8000330e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000338a:	00005517          	auipc	a0,0x5
    8000338e:	32650513          	addi	a0,a0,806 # 800086b0 <syscalls+0x108>
    80003392:	ffffd097          	auipc	ra,0xffffd
    80003396:	198080e7          	jalr	408(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000339a:	974a                	add	a4,a4,s2
    8000339c:	8fd5                	or	a5,a5,a3
    8000339e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033a2:	854a                	mv	a0,s2
    800033a4:	00001097          	auipc	ra,0x1
    800033a8:	020080e7          	jalr	32(ra) # 800043c4 <log_write>
        brelse(bp);
    800033ac:	854a                	mv	a0,s2
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	d94080e7          	jalr	-620(ra) # 80003142 <brelse>
  bp = bread(dev, bno);
    800033b6:	85a6                	mv	a1,s1
    800033b8:	855e                	mv	a0,s7
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	c58080e7          	jalr	-936(ra) # 80003012 <bread>
    800033c2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033c4:	40000613          	li	a2,1024
    800033c8:	4581                	li	a1,0
    800033ca:	05850513          	addi	a0,a0,88
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	8f0080e7          	jalr	-1808(ra) # 80000cbe <memset>
  log_write(bp);
    800033d6:	854a                	mv	a0,s2
    800033d8:	00001097          	auipc	ra,0x1
    800033dc:	fec080e7          	jalr	-20(ra) # 800043c4 <log_write>
  brelse(bp);
    800033e0:	854a                	mv	a0,s2
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	d60080e7          	jalr	-672(ra) # 80003142 <brelse>
}
    800033ea:	8526                	mv	a0,s1
    800033ec:	60e6                	ld	ra,88(sp)
    800033ee:	6446                	ld	s0,80(sp)
    800033f0:	64a6                	ld	s1,72(sp)
    800033f2:	6906                	ld	s2,64(sp)
    800033f4:	79e2                	ld	s3,56(sp)
    800033f6:	7a42                	ld	s4,48(sp)
    800033f8:	7aa2                	ld	s5,40(sp)
    800033fa:	7b02                	ld	s6,32(sp)
    800033fc:	6be2                	ld	s7,24(sp)
    800033fe:	6c42                	ld	s8,16(sp)
    80003400:	6ca2                	ld	s9,8(sp)
    80003402:	6125                	addi	sp,sp,96
    80003404:	8082                	ret

0000000080003406 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003406:	7179                	addi	sp,sp,-48
    80003408:	f406                	sd	ra,40(sp)
    8000340a:	f022                	sd	s0,32(sp)
    8000340c:	ec26                	sd	s1,24(sp)
    8000340e:	e84a                	sd	s2,16(sp)
    80003410:	e44e                	sd	s3,8(sp)
    80003412:	e052                	sd	s4,0(sp)
    80003414:	1800                	addi	s0,sp,48
    80003416:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003418:	47ad                	li	a5,11
    8000341a:	04b7fe63          	bgeu	a5,a1,80003476 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000341e:	ff45849b          	addiw	s1,a1,-12
    80003422:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003426:	0ff00793          	li	a5,255
    8000342a:	0ae7e463          	bltu	a5,a4,800034d2 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000342e:	08052583          	lw	a1,128(a0)
    80003432:	c5b5                	beqz	a1,8000349e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003434:	00092503          	lw	a0,0(s2)
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	bda080e7          	jalr	-1062(ra) # 80003012 <bread>
    80003440:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003442:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003446:	02049713          	slli	a4,s1,0x20
    8000344a:	01e75593          	srli	a1,a4,0x1e
    8000344e:	00b784b3          	add	s1,a5,a1
    80003452:	0004a983          	lw	s3,0(s1)
    80003456:	04098e63          	beqz	s3,800034b2 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000345a:	8552                	mv	a0,s4
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	ce6080e7          	jalr	-794(ra) # 80003142 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003464:	854e                	mv	a0,s3
    80003466:	70a2                	ld	ra,40(sp)
    80003468:	7402                	ld	s0,32(sp)
    8000346a:	64e2                	ld	s1,24(sp)
    8000346c:	6942                	ld	s2,16(sp)
    8000346e:	69a2                	ld	s3,8(sp)
    80003470:	6a02                	ld	s4,0(sp)
    80003472:	6145                	addi	sp,sp,48
    80003474:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003476:	02059793          	slli	a5,a1,0x20
    8000347a:	01e7d593          	srli	a1,a5,0x1e
    8000347e:	00b504b3          	add	s1,a0,a1
    80003482:	0504a983          	lw	s3,80(s1)
    80003486:	fc099fe3          	bnez	s3,80003464 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000348a:	4108                	lw	a0,0(a0)
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	e48080e7          	jalr	-440(ra) # 800032d4 <balloc>
    80003494:	0005099b          	sext.w	s3,a0
    80003498:	0534a823          	sw	s3,80(s1)
    8000349c:	b7e1                	j	80003464 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000349e:	4108                	lw	a0,0(a0)
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	e34080e7          	jalr	-460(ra) # 800032d4 <balloc>
    800034a8:	0005059b          	sext.w	a1,a0
    800034ac:	08b92023          	sw	a1,128(s2)
    800034b0:	b751                	j	80003434 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034b2:	00092503          	lw	a0,0(s2)
    800034b6:	00000097          	auipc	ra,0x0
    800034ba:	e1e080e7          	jalr	-482(ra) # 800032d4 <balloc>
    800034be:	0005099b          	sext.w	s3,a0
    800034c2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034c6:	8552                	mv	a0,s4
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	efc080e7          	jalr	-260(ra) # 800043c4 <log_write>
    800034d0:	b769                	j	8000345a <bmap+0x54>
  panic("bmap: out of range");
    800034d2:	00005517          	auipc	a0,0x5
    800034d6:	1f650513          	addi	a0,a0,502 # 800086c8 <syscalls+0x120>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	050080e7          	jalr	80(ra) # 8000052a <panic>

00000000800034e2 <iget>:
{
    800034e2:	7179                	addi	sp,sp,-48
    800034e4:	f406                	sd	ra,40(sp)
    800034e6:	f022                	sd	s0,32(sp)
    800034e8:	ec26                	sd	s1,24(sp)
    800034ea:	e84a                	sd	s2,16(sp)
    800034ec:	e44e                	sd	s3,8(sp)
    800034ee:	e052                	sd	s4,0(sp)
    800034f0:	1800                	addi	s0,sp,48
    800034f2:	89aa                	mv	s3,a0
    800034f4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034f6:	0001c517          	auipc	a0,0x1c
    800034fa:	2d250513          	addi	a0,a0,722 # 8001f7c8 <itable>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	6c4080e7          	jalr	1732(ra) # 80000bc2 <acquire>
  empty = 0;
    80003506:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003508:	0001c497          	auipc	s1,0x1c
    8000350c:	2d848493          	addi	s1,s1,728 # 8001f7e0 <itable+0x18>
    80003510:	0001e697          	auipc	a3,0x1e
    80003514:	d6068693          	addi	a3,a3,-672 # 80021270 <log>
    80003518:	a039                	j	80003526 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000351a:	02090b63          	beqz	s2,80003550 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000351e:	08848493          	addi	s1,s1,136
    80003522:	02d48a63          	beq	s1,a3,80003556 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003526:	449c                	lw	a5,8(s1)
    80003528:	fef059e3          	blez	a5,8000351a <iget+0x38>
    8000352c:	4098                	lw	a4,0(s1)
    8000352e:	ff3716e3          	bne	a4,s3,8000351a <iget+0x38>
    80003532:	40d8                	lw	a4,4(s1)
    80003534:	ff4713e3          	bne	a4,s4,8000351a <iget+0x38>
      ip->ref++;
    80003538:	2785                	addiw	a5,a5,1
    8000353a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000353c:	0001c517          	auipc	a0,0x1c
    80003540:	28c50513          	addi	a0,a0,652 # 8001f7c8 <itable>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	732080e7          	jalr	1842(ra) # 80000c76 <release>
      return ip;
    8000354c:	8926                	mv	s2,s1
    8000354e:	a03d                	j	8000357c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003550:	f7f9                	bnez	a5,8000351e <iget+0x3c>
    80003552:	8926                	mv	s2,s1
    80003554:	b7e9                	j	8000351e <iget+0x3c>
  if(empty == 0)
    80003556:	02090c63          	beqz	s2,8000358e <iget+0xac>
  ip->dev = dev;
    8000355a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000355e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003562:	4785                	li	a5,1
    80003564:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003568:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000356c:	0001c517          	auipc	a0,0x1c
    80003570:	25c50513          	addi	a0,a0,604 # 8001f7c8 <itable>
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	702080e7          	jalr	1794(ra) # 80000c76 <release>
}
    8000357c:	854a                	mv	a0,s2
    8000357e:	70a2                	ld	ra,40(sp)
    80003580:	7402                	ld	s0,32(sp)
    80003582:	64e2                	ld	s1,24(sp)
    80003584:	6942                	ld	s2,16(sp)
    80003586:	69a2                	ld	s3,8(sp)
    80003588:	6a02                	ld	s4,0(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret
    panic("iget: no inodes");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	15250513          	addi	a0,a0,338 # 800086e0 <syscalls+0x138>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	f94080e7          	jalr	-108(ra) # 8000052a <panic>

000000008000359e <fsinit>:
fsinit(int dev) {
    8000359e:	7179                	addi	sp,sp,-48
    800035a0:	f406                	sd	ra,40(sp)
    800035a2:	f022                	sd	s0,32(sp)
    800035a4:	ec26                	sd	s1,24(sp)
    800035a6:	e84a                	sd	s2,16(sp)
    800035a8:	e44e                	sd	s3,8(sp)
    800035aa:	1800                	addi	s0,sp,48
    800035ac:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ae:	4585                	li	a1,1
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	a62080e7          	jalr	-1438(ra) # 80003012 <bread>
    800035b8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035ba:	0001c997          	auipc	s3,0x1c
    800035be:	1ee98993          	addi	s3,s3,494 # 8001f7a8 <sb>
    800035c2:	02000613          	li	a2,32
    800035c6:	05850593          	addi	a1,a0,88
    800035ca:	854e                	mv	a0,s3
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	74e080e7          	jalr	1870(ra) # 80000d1a <memmove>
  brelse(bp);
    800035d4:	8526                	mv	a0,s1
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	b6c080e7          	jalr	-1172(ra) # 80003142 <brelse>
  if(sb.magic != FSMAGIC)
    800035de:	0009a703          	lw	a4,0(s3)
    800035e2:	102037b7          	lui	a5,0x10203
    800035e6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035ea:	02f71263          	bne	a4,a5,8000360e <fsinit+0x70>
  initlog(dev, &sb);
    800035ee:	0001c597          	auipc	a1,0x1c
    800035f2:	1ba58593          	addi	a1,a1,442 # 8001f7a8 <sb>
    800035f6:	854a                	mv	a0,s2
    800035f8:	00001097          	auipc	ra,0x1
    800035fc:	b4e080e7          	jalr	-1202(ra) # 80004146 <initlog>
}
    80003600:	70a2                	ld	ra,40(sp)
    80003602:	7402                	ld	s0,32(sp)
    80003604:	64e2                	ld	s1,24(sp)
    80003606:	6942                	ld	s2,16(sp)
    80003608:	69a2                	ld	s3,8(sp)
    8000360a:	6145                	addi	sp,sp,48
    8000360c:	8082                	ret
    panic("invalid file system");
    8000360e:	00005517          	auipc	a0,0x5
    80003612:	0e250513          	addi	a0,a0,226 # 800086f0 <syscalls+0x148>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	f14080e7          	jalr	-236(ra) # 8000052a <panic>

000000008000361e <iinit>:
{
    8000361e:	7179                	addi	sp,sp,-48
    80003620:	f406                	sd	ra,40(sp)
    80003622:	f022                	sd	s0,32(sp)
    80003624:	ec26                	sd	s1,24(sp)
    80003626:	e84a                	sd	s2,16(sp)
    80003628:	e44e                	sd	s3,8(sp)
    8000362a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000362c:	00005597          	auipc	a1,0x5
    80003630:	0dc58593          	addi	a1,a1,220 # 80008708 <syscalls+0x160>
    80003634:	0001c517          	auipc	a0,0x1c
    80003638:	19450513          	addi	a0,a0,404 # 8001f7c8 <itable>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	4f6080e7          	jalr	1270(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003644:	0001c497          	auipc	s1,0x1c
    80003648:	1ac48493          	addi	s1,s1,428 # 8001f7f0 <itable+0x28>
    8000364c:	0001e997          	auipc	s3,0x1e
    80003650:	c3498993          	addi	s3,s3,-972 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003654:	00005917          	auipc	s2,0x5
    80003658:	0bc90913          	addi	s2,s2,188 # 80008710 <syscalls+0x168>
    8000365c:	85ca                	mv	a1,s2
    8000365e:	8526                	mv	a0,s1
    80003660:	00001097          	auipc	ra,0x1
    80003664:	e4a080e7          	jalr	-438(ra) # 800044aa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003668:	08848493          	addi	s1,s1,136
    8000366c:	ff3498e3          	bne	s1,s3,8000365c <iinit+0x3e>
}
    80003670:	70a2                	ld	ra,40(sp)
    80003672:	7402                	ld	s0,32(sp)
    80003674:	64e2                	ld	s1,24(sp)
    80003676:	6942                	ld	s2,16(sp)
    80003678:	69a2                	ld	s3,8(sp)
    8000367a:	6145                	addi	sp,sp,48
    8000367c:	8082                	ret

000000008000367e <ialloc>:
{
    8000367e:	715d                	addi	sp,sp,-80
    80003680:	e486                	sd	ra,72(sp)
    80003682:	e0a2                	sd	s0,64(sp)
    80003684:	fc26                	sd	s1,56(sp)
    80003686:	f84a                	sd	s2,48(sp)
    80003688:	f44e                	sd	s3,40(sp)
    8000368a:	f052                	sd	s4,32(sp)
    8000368c:	ec56                	sd	s5,24(sp)
    8000368e:	e85a                	sd	s6,16(sp)
    80003690:	e45e                	sd	s7,8(sp)
    80003692:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003694:	0001c717          	auipc	a4,0x1c
    80003698:	12072703          	lw	a4,288(a4) # 8001f7b4 <sb+0xc>
    8000369c:	4785                	li	a5,1
    8000369e:	04e7fa63          	bgeu	a5,a4,800036f2 <ialloc+0x74>
    800036a2:	8aaa                	mv	s5,a0
    800036a4:	8bae                	mv	s7,a1
    800036a6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036a8:	0001ca17          	auipc	s4,0x1c
    800036ac:	100a0a13          	addi	s4,s4,256 # 8001f7a8 <sb>
    800036b0:	00048b1b          	sext.w	s6,s1
    800036b4:	0044d793          	srli	a5,s1,0x4
    800036b8:	018a2583          	lw	a1,24(s4)
    800036bc:	9dbd                	addw	a1,a1,a5
    800036be:	8556                	mv	a0,s5
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	952080e7          	jalr	-1710(ra) # 80003012 <bread>
    800036c8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036ca:	05850993          	addi	s3,a0,88
    800036ce:	00f4f793          	andi	a5,s1,15
    800036d2:	079a                	slli	a5,a5,0x6
    800036d4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036d6:	00099783          	lh	a5,0(s3)
    800036da:	c785                	beqz	a5,80003702 <ialloc+0x84>
    brelse(bp);
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	a66080e7          	jalr	-1434(ra) # 80003142 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036e4:	0485                	addi	s1,s1,1
    800036e6:	00ca2703          	lw	a4,12(s4)
    800036ea:	0004879b          	sext.w	a5,s1
    800036ee:	fce7e1e3          	bltu	a5,a4,800036b0 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036f2:	00005517          	auipc	a0,0x5
    800036f6:	02650513          	addi	a0,a0,38 # 80008718 <syscalls+0x170>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	e30080e7          	jalr	-464(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003702:	04000613          	li	a2,64
    80003706:	4581                	li	a1,0
    80003708:	854e                	mv	a0,s3
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	5b4080e7          	jalr	1460(ra) # 80000cbe <memset>
      dip->type = type;
    80003712:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003716:	854a                	mv	a0,s2
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	cac080e7          	jalr	-852(ra) # 800043c4 <log_write>
      brelse(bp);
    80003720:	854a                	mv	a0,s2
    80003722:	00000097          	auipc	ra,0x0
    80003726:	a20080e7          	jalr	-1504(ra) # 80003142 <brelse>
      return iget(dev, inum);
    8000372a:	85da                	mv	a1,s6
    8000372c:	8556                	mv	a0,s5
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	db4080e7          	jalr	-588(ra) # 800034e2 <iget>
}
    80003736:	60a6                	ld	ra,72(sp)
    80003738:	6406                	ld	s0,64(sp)
    8000373a:	74e2                	ld	s1,56(sp)
    8000373c:	7942                	ld	s2,48(sp)
    8000373e:	79a2                	ld	s3,40(sp)
    80003740:	7a02                	ld	s4,32(sp)
    80003742:	6ae2                	ld	s5,24(sp)
    80003744:	6b42                	ld	s6,16(sp)
    80003746:	6ba2                	ld	s7,8(sp)
    80003748:	6161                	addi	sp,sp,80
    8000374a:	8082                	ret

000000008000374c <iupdate>:
{
    8000374c:	1101                	addi	sp,sp,-32
    8000374e:	ec06                	sd	ra,24(sp)
    80003750:	e822                	sd	s0,16(sp)
    80003752:	e426                	sd	s1,8(sp)
    80003754:	e04a                	sd	s2,0(sp)
    80003756:	1000                	addi	s0,sp,32
    80003758:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000375a:	415c                	lw	a5,4(a0)
    8000375c:	0047d79b          	srliw	a5,a5,0x4
    80003760:	0001c597          	auipc	a1,0x1c
    80003764:	0605a583          	lw	a1,96(a1) # 8001f7c0 <sb+0x18>
    80003768:	9dbd                	addw	a1,a1,a5
    8000376a:	4108                	lw	a0,0(a0)
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	8a6080e7          	jalr	-1882(ra) # 80003012 <bread>
    80003774:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003776:	05850793          	addi	a5,a0,88
    8000377a:	40c8                	lw	a0,4(s1)
    8000377c:	893d                	andi	a0,a0,15
    8000377e:	051a                	slli	a0,a0,0x6
    80003780:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003782:	04449703          	lh	a4,68(s1)
    80003786:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000378a:	04649703          	lh	a4,70(s1)
    8000378e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003792:	04849703          	lh	a4,72(s1)
    80003796:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000379a:	04a49703          	lh	a4,74(s1)
    8000379e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037a2:	44f8                	lw	a4,76(s1)
    800037a4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037a6:	03400613          	li	a2,52
    800037aa:	05048593          	addi	a1,s1,80
    800037ae:	0531                	addi	a0,a0,12
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	56a080e7          	jalr	1386(ra) # 80000d1a <memmove>
  log_write(bp);
    800037b8:	854a                	mv	a0,s2
    800037ba:	00001097          	auipc	ra,0x1
    800037be:	c0a080e7          	jalr	-1014(ra) # 800043c4 <log_write>
  brelse(bp);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	97e080e7          	jalr	-1666(ra) # 80003142 <brelse>
}
    800037cc:	60e2                	ld	ra,24(sp)
    800037ce:	6442                	ld	s0,16(sp)
    800037d0:	64a2                	ld	s1,8(sp)
    800037d2:	6902                	ld	s2,0(sp)
    800037d4:	6105                	addi	sp,sp,32
    800037d6:	8082                	ret

00000000800037d8 <idup>:
{
    800037d8:	1101                	addi	sp,sp,-32
    800037da:	ec06                	sd	ra,24(sp)
    800037dc:	e822                	sd	s0,16(sp)
    800037de:	e426                	sd	s1,8(sp)
    800037e0:	1000                	addi	s0,sp,32
    800037e2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037e4:	0001c517          	auipc	a0,0x1c
    800037e8:	fe450513          	addi	a0,a0,-28 # 8001f7c8 <itable>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	3d6080e7          	jalr	982(ra) # 80000bc2 <acquire>
  ip->ref++;
    800037f4:	449c                	lw	a5,8(s1)
    800037f6:	2785                	addiw	a5,a5,1
    800037f8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037fa:	0001c517          	auipc	a0,0x1c
    800037fe:	fce50513          	addi	a0,a0,-50 # 8001f7c8 <itable>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	474080e7          	jalr	1140(ra) # 80000c76 <release>
}
    8000380a:	8526                	mv	a0,s1
    8000380c:	60e2                	ld	ra,24(sp)
    8000380e:	6442                	ld	s0,16(sp)
    80003810:	64a2                	ld	s1,8(sp)
    80003812:	6105                	addi	sp,sp,32
    80003814:	8082                	ret

0000000080003816 <ilock>:
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	e04a                	sd	s2,0(sp)
    80003820:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003822:	c115                	beqz	a0,80003846 <ilock+0x30>
    80003824:	84aa                	mv	s1,a0
    80003826:	451c                	lw	a5,8(a0)
    80003828:	00f05f63          	blez	a5,80003846 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000382c:	0541                	addi	a0,a0,16
    8000382e:	00001097          	auipc	ra,0x1
    80003832:	cb6080e7          	jalr	-842(ra) # 800044e4 <acquiresleep>
  if(ip->valid == 0){
    80003836:	40bc                	lw	a5,64(s1)
    80003838:	cf99                	beqz	a5,80003856 <ilock+0x40>
}
    8000383a:	60e2                	ld	ra,24(sp)
    8000383c:	6442                	ld	s0,16(sp)
    8000383e:	64a2                	ld	s1,8(sp)
    80003840:	6902                	ld	s2,0(sp)
    80003842:	6105                	addi	sp,sp,32
    80003844:	8082                	ret
    panic("ilock");
    80003846:	00005517          	auipc	a0,0x5
    8000384a:	eea50513          	addi	a0,a0,-278 # 80008730 <syscalls+0x188>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	cdc080e7          	jalr	-804(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003856:	40dc                	lw	a5,4(s1)
    80003858:	0047d79b          	srliw	a5,a5,0x4
    8000385c:	0001c597          	auipc	a1,0x1c
    80003860:	f645a583          	lw	a1,-156(a1) # 8001f7c0 <sb+0x18>
    80003864:	9dbd                	addw	a1,a1,a5
    80003866:	4088                	lw	a0,0(s1)
    80003868:	fffff097          	auipc	ra,0xfffff
    8000386c:	7aa080e7          	jalr	1962(ra) # 80003012 <bread>
    80003870:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003872:	05850593          	addi	a1,a0,88
    80003876:	40dc                	lw	a5,4(s1)
    80003878:	8bbd                	andi	a5,a5,15
    8000387a:	079a                	slli	a5,a5,0x6
    8000387c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000387e:	00059783          	lh	a5,0(a1)
    80003882:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003886:	00259783          	lh	a5,2(a1)
    8000388a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000388e:	00459783          	lh	a5,4(a1)
    80003892:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003896:	00659783          	lh	a5,6(a1)
    8000389a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000389e:	459c                	lw	a5,8(a1)
    800038a0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038a2:	03400613          	li	a2,52
    800038a6:	05b1                	addi	a1,a1,12
    800038a8:	05048513          	addi	a0,s1,80
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	46e080e7          	jalr	1134(ra) # 80000d1a <memmove>
    brelse(bp);
    800038b4:	854a                	mv	a0,s2
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	88c080e7          	jalr	-1908(ra) # 80003142 <brelse>
    ip->valid = 1;
    800038be:	4785                	li	a5,1
    800038c0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038c2:	04449783          	lh	a5,68(s1)
    800038c6:	fbb5                	bnez	a5,8000383a <ilock+0x24>
      panic("ilock: no type");
    800038c8:	00005517          	auipc	a0,0x5
    800038cc:	e7050513          	addi	a0,a0,-400 # 80008738 <syscalls+0x190>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	c5a080e7          	jalr	-934(ra) # 8000052a <panic>

00000000800038d8 <iunlock>:
{
    800038d8:	1101                	addi	sp,sp,-32
    800038da:	ec06                	sd	ra,24(sp)
    800038dc:	e822                	sd	s0,16(sp)
    800038de:	e426                	sd	s1,8(sp)
    800038e0:	e04a                	sd	s2,0(sp)
    800038e2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038e4:	c905                	beqz	a0,80003914 <iunlock+0x3c>
    800038e6:	84aa                	mv	s1,a0
    800038e8:	01050913          	addi	s2,a0,16
    800038ec:	854a                	mv	a0,s2
    800038ee:	00001097          	auipc	ra,0x1
    800038f2:	c90080e7          	jalr	-880(ra) # 8000457e <holdingsleep>
    800038f6:	cd19                	beqz	a0,80003914 <iunlock+0x3c>
    800038f8:	449c                	lw	a5,8(s1)
    800038fa:	00f05d63          	blez	a5,80003914 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038fe:	854a                	mv	a0,s2
    80003900:	00001097          	auipc	ra,0x1
    80003904:	c3a080e7          	jalr	-966(ra) # 8000453a <releasesleep>
}
    80003908:	60e2                	ld	ra,24(sp)
    8000390a:	6442                	ld	s0,16(sp)
    8000390c:	64a2                	ld	s1,8(sp)
    8000390e:	6902                	ld	s2,0(sp)
    80003910:	6105                	addi	sp,sp,32
    80003912:	8082                	ret
    panic("iunlock");
    80003914:	00005517          	auipc	a0,0x5
    80003918:	e3450513          	addi	a0,a0,-460 # 80008748 <syscalls+0x1a0>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	c0e080e7          	jalr	-1010(ra) # 8000052a <panic>

0000000080003924 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003924:	7179                	addi	sp,sp,-48
    80003926:	f406                	sd	ra,40(sp)
    80003928:	f022                	sd	s0,32(sp)
    8000392a:	ec26                	sd	s1,24(sp)
    8000392c:	e84a                	sd	s2,16(sp)
    8000392e:	e44e                	sd	s3,8(sp)
    80003930:	e052                	sd	s4,0(sp)
    80003932:	1800                	addi	s0,sp,48
    80003934:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003936:	05050493          	addi	s1,a0,80
    8000393a:	08050913          	addi	s2,a0,128
    8000393e:	a021                	j	80003946 <itrunc+0x22>
    80003940:	0491                	addi	s1,s1,4
    80003942:	01248d63          	beq	s1,s2,8000395c <itrunc+0x38>
    if(ip->addrs[i]){
    80003946:	408c                	lw	a1,0(s1)
    80003948:	dde5                	beqz	a1,80003940 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000394a:	0009a503          	lw	a0,0(s3)
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	90a080e7          	jalr	-1782(ra) # 80003258 <bfree>
      ip->addrs[i] = 0;
    80003956:	0004a023          	sw	zero,0(s1)
    8000395a:	b7dd                	j	80003940 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000395c:	0809a583          	lw	a1,128(s3)
    80003960:	e185                	bnez	a1,80003980 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003962:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003966:	854e                	mv	a0,s3
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	de4080e7          	jalr	-540(ra) # 8000374c <iupdate>
}
    80003970:	70a2                	ld	ra,40(sp)
    80003972:	7402                	ld	s0,32(sp)
    80003974:	64e2                	ld	s1,24(sp)
    80003976:	6942                	ld	s2,16(sp)
    80003978:	69a2                	ld	s3,8(sp)
    8000397a:	6a02                	ld	s4,0(sp)
    8000397c:	6145                	addi	sp,sp,48
    8000397e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003980:	0009a503          	lw	a0,0(s3)
    80003984:	fffff097          	auipc	ra,0xfffff
    80003988:	68e080e7          	jalr	1678(ra) # 80003012 <bread>
    8000398c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000398e:	05850493          	addi	s1,a0,88
    80003992:	45850913          	addi	s2,a0,1112
    80003996:	a021                	j	8000399e <itrunc+0x7a>
    80003998:	0491                	addi	s1,s1,4
    8000399a:	01248b63          	beq	s1,s2,800039b0 <itrunc+0x8c>
      if(a[j])
    8000399e:	408c                	lw	a1,0(s1)
    800039a0:	dde5                	beqz	a1,80003998 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039a2:	0009a503          	lw	a0,0(s3)
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	8b2080e7          	jalr	-1870(ra) # 80003258 <bfree>
    800039ae:	b7ed                	j	80003998 <itrunc+0x74>
    brelse(bp);
    800039b0:	8552                	mv	a0,s4
    800039b2:	fffff097          	auipc	ra,0xfffff
    800039b6:	790080e7          	jalr	1936(ra) # 80003142 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039ba:	0809a583          	lw	a1,128(s3)
    800039be:	0009a503          	lw	a0,0(s3)
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	896080e7          	jalr	-1898(ra) # 80003258 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039ca:	0809a023          	sw	zero,128(s3)
    800039ce:	bf51                	j	80003962 <itrunc+0x3e>

00000000800039d0 <iput>:
{
    800039d0:	1101                	addi	sp,sp,-32
    800039d2:	ec06                	sd	ra,24(sp)
    800039d4:	e822                	sd	s0,16(sp)
    800039d6:	e426                	sd	s1,8(sp)
    800039d8:	e04a                	sd	s2,0(sp)
    800039da:	1000                	addi	s0,sp,32
    800039dc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039de:	0001c517          	auipc	a0,0x1c
    800039e2:	dea50513          	addi	a0,a0,-534 # 8001f7c8 <itable>
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	1dc080e7          	jalr	476(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ee:	4498                	lw	a4,8(s1)
    800039f0:	4785                	li	a5,1
    800039f2:	02f70363          	beq	a4,a5,80003a18 <iput+0x48>
  ip->ref--;
    800039f6:	449c                	lw	a5,8(s1)
    800039f8:	37fd                	addiw	a5,a5,-1
    800039fa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039fc:	0001c517          	auipc	a0,0x1c
    80003a00:	dcc50513          	addi	a0,a0,-564 # 8001f7c8 <itable>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	272080e7          	jalr	626(ra) # 80000c76 <release>
}
    80003a0c:	60e2                	ld	ra,24(sp)
    80003a0e:	6442                	ld	s0,16(sp)
    80003a10:	64a2                	ld	s1,8(sp)
    80003a12:	6902                	ld	s2,0(sp)
    80003a14:	6105                	addi	sp,sp,32
    80003a16:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a18:	40bc                	lw	a5,64(s1)
    80003a1a:	dff1                	beqz	a5,800039f6 <iput+0x26>
    80003a1c:	04a49783          	lh	a5,74(s1)
    80003a20:	fbf9                	bnez	a5,800039f6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a22:	01048913          	addi	s2,s1,16
    80003a26:	854a                	mv	a0,s2
    80003a28:	00001097          	auipc	ra,0x1
    80003a2c:	abc080e7          	jalr	-1348(ra) # 800044e4 <acquiresleep>
    release(&itable.lock);
    80003a30:	0001c517          	auipc	a0,0x1c
    80003a34:	d9850513          	addi	a0,a0,-616 # 8001f7c8 <itable>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	23e080e7          	jalr	574(ra) # 80000c76 <release>
    itrunc(ip);
    80003a40:	8526                	mv	a0,s1
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	ee2080e7          	jalr	-286(ra) # 80003924 <itrunc>
    ip->type = 0;
    80003a4a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a4e:	8526                	mv	a0,s1
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	cfc080e7          	jalr	-772(ra) # 8000374c <iupdate>
    ip->valid = 0;
    80003a58:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	00001097          	auipc	ra,0x1
    80003a62:	adc080e7          	jalr	-1316(ra) # 8000453a <releasesleep>
    acquire(&itable.lock);
    80003a66:	0001c517          	auipc	a0,0x1c
    80003a6a:	d6250513          	addi	a0,a0,-670 # 8001f7c8 <itable>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	154080e7          	jalr	340(ra) # 80000bc2 <acquire>
    80003a76:	b741                	j	800039f6 <iput+0x26>

0000000080003a78 <iunlockput>:
{
    80003a78:	1101                	addi	sp,sp,-32
    80003a7a:	ec06                	sd	ra,24(sp)
    80003a7c:	e822                	sd	s0,16(sp)
    80003a7e:	e426                	sd	s1,8(sp)
    80003a80:	1000                	addi	s0,sp,32
    80003a82:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	e54080e7          	jalr	-428(ra) # 800038d8 <iunlock>
  iput(ip);
    80003a8c:	8526                	mv	a0,s1
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	f42080e7          	jalr	-190(ra) # 800039d0 <iput>
}
    80003a96:	60e2                	ld	ra,24(sp)
    80003a98:	6442                	ld	s0,16(sp)
    80003a9a:	64a2                	ld	s1,8(sp)
    80003a9c:	6105                	addi	sp,sp,32
    80003a9e:	8082                	ret

0000000080003aa0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aa0:	1141                	addi	sp,sp,-16
    80003aa2:	e422                	sd	s0,8(sp)
    80003aa4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003aa6:	411c                	lw	a5,0(a0)
    80003aa8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003aaa:	415c                	lw	a5,4(a0)
    80003aac:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aae:	04451783          	lh	a5,68(a0)
    80003ab2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ab6:	04a51783          	lh	a5,74(a0)
    80003aba:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003abe:	04c56783          	lwu	a5,76(a0)
    80003ac2:	e99c                	sd	a5,16(a1)
}
    80003ac4:	6422                	ld	s0,8(sp)
    80003ac6:	0141                	addi	sp,sp,16
    80003ac8:	8082                	ret

0000000080003aca <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aca:	457c                	lw	a5,76(a0)
    80003acc:	0ed7e963          	bltu	a5,a3,80003bbe <readi+0xf4>
{
    80003ad0:	7159                	addi	sp,sp,-112
    80003ad2:	f486                	sd	ra,104(sp)
    80003ad4:	f0a2                	sd	s0,96(sp)
    80003ad6:	eca6                	sd	s1,88(sp)
    80003ad8:	e8ca                	sd	s2,80(sp)
    80003ada:	e4ce                	sd	s3,72(sp)
    80003adc:	e0d2                	sd	s4,64(sp)
    80003ade:	fc56                	sd	s5,56(sp)
    80003ae0:	f85a                	sd	s6,48(sp)
    80003ae2:	f45e                	sd	s7,40(sp)
    80003ae4:	f062                	sd	s8,32(sp)
    80003ae6:	ec66                	sd	s9,24(sp)
    80003ae8:	e86a                	sd	s10,16(sp)
    80003aea:	e46e                	sd	s11,8(sp)
    80003aec:	1880                	addi	s0,sp,112
    80003aee:	8baa                	mv	s7,a0
    80003af0:	8c2e                	mv	s8,a1
    80003af2:	8ab2                	mv	s5,a2
    80003af4:	84b6                	mv	s1,a3
    80003af6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003af8:	9f35                	addw	a4,a4,a3
    return 0;
    80003afa:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003afc:	0ad76063          	bltu	a4,a3,80003b9c <readi+0xd2>
  if(off + n > ip->size)
    80003b00:	00e7f463          	bgeu	a5,a4,80003b08 <readi+0x3e>
    n = ip->size - off;
    80003b04:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b08:	0a0b0963          	beqz	s6,80003bba <readi+0xf0>
    80003b0c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b0e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b12:	5cfd                	li	s9,-1
    80003b14:	a82d                	j	80003b4e <readi+0x84>
    80003b16:	020a1d93          	slli	s11,s4,0x20
    80003b1a:	020ddd93          	srli	s11,s11,0x20
    80003b1e:	05890793          	addi	a5,s2,88
    80003b22:	86ee                	mv	a3,s11
    80003b24:	963e                	add	a2,a2,a5
    80003b26:	85d6                	mv	a1,s5
    80003b28:	8562                	mv	a0,s8
    80003b2a:	fffff097          	auipc	ra,0xfffff
    80003b2e:	8c0080e7          	jalr	-1856(ra) # 800023ea <either_copyout>
    80003b32:	05950d63          	beq	a0,s9,80003b8c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b36:	854a                	mv	a0,s2
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	60a080e7          	jalr	1546(ra) # 80003142 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b40:	013a09bb          	addw	s3,s4,s3
    80003b44:	009a04bb          	addw	s1,s4,s1
    80003b48:	9aee                	add	s5,s5,s11
    80003b4a:	0569f763          	bgeu	s3,s6,80003b98 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b4e:	000ba903          	lw	s2,0(s7)
    80003b52:	00a4d59b          	srliw	a1,s1,0xa
    80003b56:	855e                	mv	a0,s7
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	8ae080e7          	jalr	-1874(ra) # 80003406 <bmap>
    80003b60:	0005059b          	sext.w	a1,a0
    80003b64:	854a                	mv	a0,s2
    80003b66:	fffff097          	auipc	ra,0xfffff
    80003b6a:	4ac080e7          	jalr	1196(ra) # 80003012 <bread>
    80003b6e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b70:	3ff4f613          	andi	a2,s1,1023
    80003b74:	40cd07bb          	subw	a5,s10,a2
    80003b78:	413b073b          	subw	a4,s6,s3
    80003b7c:	8a3e                	mv	s4,a5
    80003b7e:	2781                	sext.w	a5,a5
    80003b80:	0007069b          	sext.w	a3,a4
    80003b84:	f8f6f9e3          	bgeu	a3,a5,80003b16 <readi+0x4c>
    80003b88:	8a3a                	mv	s4,a4
    80003b8a:	b771                	j	80003b16 <readi+0x4c>
      brelse(bp);
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	fffff097          	auipc	ra,0xfffff
    80003b92:	5b4080e7          	jalr	1460(ra) # 80003142 <brelse>
      tot = -1;
    80003b96:	59fd                	li	s3,-1
  }
  return tot;
    80003b98:	0009851b          	sext.w	a0,s3
}
    80003b9c:	70a6                	ld	ra,104(sp)
    80003b9e:	7406                	ld	s0,96(sp)
    80003ba0:	64e6                	ld	s1,88(sp)
    80003ba2:	6946                	ld	s2,80(sp)
    80003ba4:	69a6                	ld	s3,72(sp)
    80003ba6:	6a06                	ld	s4,64(sp)
    80003ba8:	7ae2                	ld	s5,56(sp)
    80003baa:	7b42                	ld	s6,48(sp)
    80003bac:	7ba2                	ld	s7,40(sp)
    80003bae:	7c02                	ld	s8,32(sp)
    80003bb0:	6ce2                	ld	s9,24(sp)
    80003bb2:	6d42                	ld	s10,16(sp)
    80003bb4:	6da2                	ld	s11,8(sp)
    80003bb6:	6165                	addi	sp,sp,112
    80003bb8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bba:	89da                	mv	s3,s6
    80003bbc:	bff1                	j	80003b98 <readi+0xce>
    return 0;
    80003bbe:	4501                	li	a0,0
}
    80003bc0:	8082                	ret

0000000080003bc2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bc2:	457c                	lw	a5,76(a0)
    80003bc4:	10d7e863          	bltu	a5,a3,80003cd4 <writei+0x112>
{
    80003bc8:	7159                	addi	sp,sp,-112
    80003bca:	f486                	sd	ra,104(sp)
    80003bcc:	f0a2                	sd	s0,96(sp)
    80003bce:	eca6                	sd	s1,88(sp)
    80003bd0:	e8ca                	sd	s2,80(sp)
    80003bd2:	e4ce                	sd	s3,72(sp)
    80003bd4:	e0d2                	sd	s4,64(sp)
    80003bd6:	fc56                	sd	s5,56(sp)
    80003bd8:	f85a                	sd	s6,48(sp)
    80003bda:	f45e                	sd	s7,40(sp)
    80003bdc:	f062                	sd	s8,32(sp)
    80003bde:	ec66                	sd	s9,24(sp)
    80003be0:	e86a                	sd	s10,16(sp)
    80003be2:	e46e                	sd	s11,8(sp)
    80003be4:	1880                	addi	s0,sp,112
    80003be6:	8b2a                	mv	s6,a0
    80003be8:	8c2e                	mv	s8,a1
    80003bea:	8ab2                	mv	s5,a2
    80003bec:	8936                	mv	s2,a3
    80003bee:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003bf0:	00e687bb          	addw	a5,a3,a4
    80003bf4:	0ed7e263          	bltu	a5,a3,80003cd8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bf8:	00043737          	lui	a4,0x43
    80003bfc:	0ef76063          	bltu	a4,a5,80003cdc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c00:	0c0b8863          	beqz	s7,80003cd0 <writei+0x10e>
    80003c04:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c06:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c0a:	5cfd                	li	s9,-1
    80003c0c:	a091                	j	80003c50 <writei+0x8e>
    80003c0e:	02099d93          	slli	s11,s3,0x20
    80003c12:	020ddd93          	srli	s11,s11,0x20
    80003c16:	05848793          	addi	a5,s1,88
    80003c1a:	86ee                	mv	a3,s11
    80003c1c:	8656                	mv	a2,s5
    80003c1e:	85e2                	mv	a1,s8
    80003c20:	953e                	add	a0,a0,a5
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	81e080e7          	jalr	-2018(ra) # 80002440 <either_copyin>
    80003c2a:	07950263          	beq	a0,s9,80003c8e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c2e:	8526                	mv	a0,s1
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	794080e7          	jalr	1940(ra) # 800043c4 <log_write>
    brelse(bp);
    80003c38:	8526                	mv	a0,s1
    80003c3a:	fffff097          	auipc	ra,0xfffff
    80003c3e:	508080e7          	jalr	1288(ra) # 80003142 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c42:	01498a3b          	addw	s4,s3,s4
    80003c46:	0129893b          	addw	s2,s3,s2
    80003c4a:	9aee                	add	s5,s5,s11
    80003c4c:	057a7663          	bgeu	s4,s7,80003c98 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c50:	000b2483          	lw	s1,0(s6)
    80003c54:	00a9559b          	srliw	a1,s2,0xa
    80003c58:	855a                	mv	a0,s6
    80003c5a:	fffff097          	auipc	ra,0xfffff
    80003c5e:	7ac080e7          	jalr	1964(ra) # 80003406 <bmap>
    80003c62:	0005059b          	sext.w	a1,a0
    80003c66:	8526                	mv	a0,s1
    80003c68:	fffff097          	auipc	ra,0xfffff
    80003c6c:	3aa080e7          	jalr	938(ra) # 80003012 <bread>
    80003c70:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c72:	3ff97513          	andi	a0,s2,1023
    80003c76:	40ad07bb          	subw	a5,s10,a0
    80003c7a:	414b873b          	subw	a4,s7,s4
    80003c7e:	89be                	mv	s3,a5
    80003c80:	2781                	sext.w	a5,a5
    80003c82:	0007069b          	sext.w	a3,a4
    80003c86:	f8f6f4e3          	bgeu	a3,a5,80003c0e <writei+0x4c>
    80003c8a:	89ba                	mv	s3,a4
    80003c8c:	b749                	j	80003c0e <writei+0x4c>
      brelse(bp);
    80003c8e:	8526                	mv	a0,s1
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	4b2080e7          	jalr	1202(ra) # 80003142 <brelse>
  }

  if(off > ip->size)
    80003c98:	04cb2783          	lw	a5,76(s6)
    80003c9c:	0127f463          	bgeu	a5,s2,80003ca4 <writei+0xe2>
    ip->size = off;
    80003ca0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ca4:	855a                	mv	a0,s6
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	aa6080e7          	jalr	-1370(ra) # 8000374c <iupdate>

  return tot;
    80003cae:	000a051b          	sext.w	a0,s4
}
    80003cb2:	70a6                	ld	ra,104(sp)
    80003cb4:	7406                	ld	s0,96(sp)
    80003cb6:	64e6                	ld	s1,88(sp)
    80003cb8:	6946                	ld	s2,80(sp)
    80003cba:	69a6                	ld	s3,72(sp)
    80003cbc:	6a06                	ld	s4,64(sp)
    80003cbe:	7ae2                	ld	s5,56(sp)
    80003cc0:	7b42                	ld	s6,48(sp)
    80003cc2:	7ba2                	ld	s7,40(sp)
    80003cc4:	7c02                	ld	s8,32(sp)
    80003cc6:	6ce2                	ld	s9,24(sp)
    80003cc8:	6d42                	ld	s10,16(sp)
    80003cca:	6da2                	ld	s11,8(sp)
    80003ccc:	6165                	addi	sp,sp,112
    80003cce:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cd0:	8a5e                	mv	s4,s7
    80003cd2:	bfc9                	j	80003ca4 <writei+0xe2>
    return -1;
    80003cd4:	557d                	li	a0,-1
}
    80003cd6:	8082                	ret
    return -1;
    80003cd8:	557d                	li	a0,-1
    80003cda:	bfe1                	j	80003cb2 <writei+0xf0>
    return -1;
    80003cdc:	557d                	li	a0,-1
    80003cde:	bfd1                	j	80003cb2 <writei+0xf0>

0000000080003ce0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ce0:	1141                	addi	sp,sp,-16
    80003ce2:	e406                	sd	ra,8(sp)
    80003ce4:	e022                	sd	s0,0(sp)
    80003ce6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ce8:	4639                	li	a2,14
    80003cea:	ffffd097          	auipc	ra,0xffffd
    80003cee:	0ac080e7          	jalr	172(ra) # 80000d96 <strncmp>
}
    80003cf2:	60a2                	ld	ra,8(sp)
    80003cf4:	6402                	ld	s0,0(sp)
    80003cf6:	0141                	addi	sp,sp,16
    80003cf8:	8082                	ret

0000000080003cfa <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cfa:	7139                	addi	sp,sp,-64
    80003cfc:	fc06                	sd	ra,56(sp)
    80003cfe:	f822                	sd	s0,48(sp)
    80003d00:	f426                	sd	s1,40(sp)
    80003d02:	f04a                	sd	s2,32(sp)
    80003d04:	ec4e                	sd	s3,24(sp)
    80003d06:	e852                	sd	s4,16(sp)
    80003d08:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d0a:	04451703          	lh	a4,68(a0)
    80003d0e:	4785                	li	a5,1
    80003d10:	00f71a63          	bne	a4,a5,80003d24 <dirlookup+0x2a>
    80003d14:	892a                	mv	s2,a0
    80003d16:	89ae                	mv	s3,a1
    80003d18:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d1a:	457c                	lw	a5,76(a0)
    80003d1c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d1e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d20:	e79d                	bnez	a5,80003d4e <dirlookup+0x54>
    80003d22:	a8a5                	j	80003d9a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d24:	00005517          	auipc	a0,0x5
    80003d28:	a2c50513          	addi	a0,a0,-1492 # 80008750 <syscalls+0x1a8>
    80003d2c:	ffffc097          	auipc	ra,0xffffc
    80003d30:	7fe080e7          	jalr	2046(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003d34:	00005517          	auipc	a0,0x5
    80003d38:	a3450513          	addi	a0,a0,-1484 # 80008768 <syscalls+0x1c0>
    80003d3c:	ffffc097          	auipc	ra,0xffffc
    80003d40:	7ee080e7          	jalr	2030(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d44:	24c1                	addiw	s1,s1,16
    80003d46:	04c92783          	lw	a5,76(s2)
    80003d4a:	04f4f763          	bgeu	s1,a5,80003d98 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d4e:	4741                	li	a4,16
    80003d50:	86a6                	mv	a3,s1
    80003d52:	fc040613          	addi	a2,s0,-64
    80003d56:	4581                	li	a1,0
    80003d58:	854a                	mv	a0,s2
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	d70080e7          	jalr	-656(ra) # 80003aca <readi>
    80003d62:	47c1                	li	a5,16
    80003d64:	fcf518e3          	bne	a0,a5,80003d34 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d68:	fc045783          	lhu	a5,-64(s0)
    80003d6c:	dfe1                	beqz	a5,80003d44 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d6e:	fc240593          	addi	a1,s0,-62
    80003d72:	854e                	mv	a0,s3
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	f6c080e7          	jalr	-148(ra) # 80003ce0 <namecmp>
    80003d7c:	f561                	bnez	a0,80003d44 <dirlookup+0x4a>
      if(poff)
    80003d7e:	000a0463          	beqz	s4,80003d86 <dirlookup+0x8c>
        *poff = off;
    80003d82:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d86:	fc045583          	lhu	a1,-64(s0)
    80003d8a:	00092503          	lw	a0,0(s2)
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	754080e7          	jalr	1876(ra) # 800034e2 <iget>
    80003d96:	a011                	j	80003d9a <dirlookup+0xa0>
  return 0;
    80003d98:	4501                	li	a0,0
}
    80003d9a:	70e2                	ld	ra,56(sp)
    80003d9c:	7442                	ld	s0,48(sp)
    80003d9e:	74a2                	ld	s1,40(sp)
    80003da0:	7902                	ld	s2,32(sp)
    80003da2:	69e2                	ld	s3,24(sp)
    80003da4:	6a42                	ld	s4,16(sp)
    80003da6:	6121                	addi	sp,sp,64
    80003da8:	8082                	ret

0000000080003daa <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003daa:	711d                	addi	sp,sp,-96
    80003dac:	ec86                	sd	ra,88(sp)
    80003dae:	e8a2                	sd	s0,80(sp)
    80003db0:	e4a6                	sd	s1,72(sp)
    80003db2:	e0ca                	sd	s2,64(sp)
    80003db4:	fc4e                	sd	s3,56(sp)
    80003db6:	f852                	sd	s4,48(sp)
    80003db8:	f456                	sd	s5,40(sp)
    80003dba:	f05a                	sd	s6,32(sp)
    80003dbc:	ec5e                	sd	s7,24(sp)
    80003dbe:	e862                	sd	s8,16(sp)
    80003dc0:	e466                	sd	s9,8(sp)
    80003dc2:	1080                	addi	s0,sp,96
    80003dc4:	84aa                	mv	s1,a0
    80003dc6:	8aae                	mv	s5,a1
    80003dc8:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dca:	00054703          	lbu	a4,0(a0)
    80003dce:	02f00793          	li	a5,47
    80003dd2:	02f70363          	beq	a4,a5,80003df8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dd6:	ffffe097          	auipc	ra,0xffffe
    80003dda:	ba8080e7          	jalr	-1112(ra) # 8000197e <myproc>
    80003dde:	15053503          	ld	a0,336(a0)
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	9f6080e7          	jalr	-1546(ra) # 800037d8 <idup>
    80003dea:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dec:	02f00913          	li	s2,47
  len = path - s;
    80003df0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003df2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003df4:	4b85                	li	s7,1
    80003df6:	a865                	j	80003eae <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003df8:	4585                	li	a1,1
    80003dfa:	4505                	li	a0,1
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	6e6080e7          	jalr	1766(ra) # 800034e2 <iget>
    80003e04:	89aa                	mv	s3,a0
    80003e06:	b7dd                	j	80003dec <namex+0x42>
      iunlockput(ip);
    80003e08:	854e                	mv	a0,s3
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	c6e080e7          	jalr	-914(ra) # 80003a78 <iunlockput>
      return 0;
    80003e12:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e14:	854e                	mv	a0,s3
    80003e16:	60e6                	ld	ra,88(sp)
    80003e18:	6446                	ld	s0,80(sp)
    80003e1a:	64a6                	ld	s1,72(sp)
    80003e1c:	6906                	ld	s2,64(sp)
    80003e1e:	79e2                	ld	s3,56(sp)
    80003e20:	7a42                	ld	s4,48(sp)
    80003e22:	7aa2                	ld	s5,40(sp)
    80003e24:	7b02                	ld	s6,32(sp)
    80003e26:	6be2                	ld	s7,24(sp)
    80003e28:	6c42                	ld	s8,16(sp)
    80003e2a:	6ca2                	ld	s9,8(sp)
    80003e2c:	6125                	addi	sp,sp,96
    80003e2e:	8082                	ret
      iunlock(ip);
    80003e30:	854e                	mv	a0,s3
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	aa6080e7          	jalr	-1370(ra) # 800038d8 <iunlock>
      return ip;
    80003e3a:	bfe9                	j	80003e14 <namex+0x6a>
      iunlockput(ip);
    80003e3c:	854e                	mv	a0,s3
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	c3a080e7          	jalr	-966(ra) # 80003a78 <iunlockput>
      return 0;
    80003e46:	89e6                	mv	s3,s9
    80003e48:	b7f1                	j	80003e14 <namex+0x6a>
  len = path - s;
    80003e4a:	40b48633          	sub	a2,s1,a1
    80003e4e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e52:	099c5463          	bge	s8,s9,80003eda <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e56:	4639                	li	a2,14
    80003e58:	8552                	mv	a0,s4
    80003e5a:	ffffd097          	auipc	ra,0xffffd
    80003e5e:	ec0080e7          	jalr	-320(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003e62:	0004c783          	lbu	a5,0(s1)
    80003e66:	01279763          	bne	a5,s2,80003e74 <namex+0xca>
    path++;
    80003e6a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e6c:	0004c783          	lbu	a5,0(s1)
    80003e70:	ff278de3          	beq	a5,s2,80003e6a <namex+0xc0>
    ilock(ip);
    80003e74:	854e                	mv	a0,s3
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	9a0080e7          	jalr	-1632(ra) # 80003816 <ilock>
    if(ip->type != T_DIR){
    80003e7e:	04499783          	lh	a5,68(s3)
    80003e82:	f97793e3          	bne	a5,s7,80003e08 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e86:	000a8563          	beqz	s5,80003e90 <namex+0xe6>
    80003e8a:	0004c783          	lbu	a5,0(s1)
    80003e8e:	d3cd                	beqz	a5,80003e30 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e90:	865a                	mv	a2,s6
    80003e92:	85d2                	mv	a1,s4
    80003e94:	854e                	mv	a0,s3
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	e64080e7          	jalr	-412(ra) # 80003cfa <dirlookup>
    80003e9e:	8caa                	mv	s9,a0
    80003ea0:	dd51                	beqz	a0,80003e3c <namex+0x92>
    iunlockput(ip);
    80003ea2:	854e                	mv	a0,s3
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	bd4080e7          	jalr	-1068(ra) # 80003a78 <iunlockput>
    ip = next;
    80003eac:	89e6                	mv	s3,s9
  while(*path == '/')
    80003eae:	0004c783          	lbu	a5,0(s1)
    80003eb2:	05279763          	bne	a5,s2,80003f00 <namex+0x156>
    path++;
    80003eb6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eb8:	0004c783          	lbu	a5,0(s1)
    80003ebc:	ff278de3          	beq	a5,s2,80003eb6 <namex+0x10c>
  if(*path == 0)
    80003ec0:	c79d                	beqz	a5,80003eee <namex+0x144>
    path++;
    80003ec2:	85a6                	mv	a1,s1
  len = path - s;
    80003ec4:	8cda                	mv	s9,s6
    80003ec6:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003ec8:	01278963          	beq	a5,s2,80003eda <namex+0x130>
    80003ecc:	dfbd                	beqz	a5,80003e4a <namex+0xa0>
    path++;
    80003ece:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ed0:	0004c783          	lbu	a5,0(s1)
    80003ed4:	ff279ce3          	bne	a5,s2,80003ecc <namex+0x122>
    80003ed8:	bf8d                	j	80003e4a <namex+0xa0>
    memmove(name, s, len);
    80003eda:	2601                	sext.w	a2,a2
    80003edc:	8552                	mv	a0,s4
    80003ede:	ffffd097          	auipc	ra,0xffffd
    80003ee2:	e3c080e7          	jalr	-452(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003ee6:	9cd2                	add	s9,s9,s4
    80003ee8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003eec:	bf9d                	j	80003e62 <namex+0xb8>
  if(nameiparent){
    80003eee:	f20a83e3          	beqz	s5,80003e14 <namex+0x6a>
    iput(ip);
    80003ef2:	854e                	mv	a0,s3
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	adc080e7          	jalr	-1316(ra) # 800039d0 <iput>
    return 0;
    80003efc:	4981                	li	s3,0
    80003efe:	bf19                	j	80003e14 <namex+0x6a>
  if(*path == 0)
    80003f00:	d7fd                	beqz	a5,80003eee <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f02:	0004c783          	lbu	a5,0(s1)
    80003f06:	85a6                	mv	a1,s1
    80003f08:	b7d1                	j	80003ecc <namex+0x122>

0000000080003f0a <dirlink>:
{
    80003f0a:	7139                	addi	sp,sp,-64
    80003f0c:	fc06                	sd	ra,56(sp)
    80003f0e:	f822                	sd	s0,48(sp)
    80003f10:	f426                	sd	s1,40(sp)
    80003f12:	f04a                	sd	s2,32(sp)
    80003f14:	ec4e                	sd	s3,24(sp)
    80003f16:	e852                	sd	s4,16(sp)
    80003f18:	0080                	addi	s0,sp,64
    80003f1a:	892a                	mv	s2,a0
    80003f1c:	8a2e                	mv	s4,a1
    80003f1e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f20:	4601                	li	a2,0
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	dd8080e7          	jalr	-552(ra) # 80003cfa <dirlookup>
    80003f2a:	e93d                	bnez	a0,80003fa0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f2c:	04c92483          	lw	s1,76(s2)
    80003f30:	c49d                	beqz	s1,80003f5e <dirlink+0x54>
    80003f32:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f34:	4741                	li	a4,16
    80003f36:	86a6                	mv	a3,s1
    80003f38:	fc040613          	addi	a2,s0,-64
    80003f3c:	4581                	li	a1,0
    80003f3e:	854a                	mv	a0,s2
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	b8a080e7          	jalr	-1142(ra) # 80003aca <readi>
    80003f48:	47c1                	li	a5,16
    80003f4a:	06f51163          	bne	a0,a5,80003fac <dirlink+0xa2>
    if(de.inum == 0)
    80003f4e:	fc045783          	lhu	a5,-64(s0)
    80003f52:	c791                	beqz	a5,80003f5e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f54:	24c1                	addiw	s1,s1,16
    80003f56:	04c92783          	lw	a5,76(s2)
    80003f5a:	fcf4ede3          	bltu	s1,a5,80003f34 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f5e:	4639                	li	a2,14
    80003f60:	85d2                	mv	a1,s4
    80003f62:	fc240513          	addi	a0,s0,-62
    80003f66:	ffffd097          	auipc	ra,0xffffd
    80003f6a:	e6c080e7          	jalr	-404(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003f6e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f72:	4741                	li	a4,16
    80003f74:	86a6                	mv	a3,s1
    80003f76:	fc040613          	addi	a2,s0,-64
    80003f7a:	4581                	li	a1,0
    80003f7c:	854a                	mv	a0,s2
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	c44080e7          	jalr	-956(ra) # 80003bc2 <writei>
    80003f86:	872a                	mv	a4,a0
    80003f88:	47c1                	li	a5,16
  return 0;
    80003f8a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f8c:	02f71863          	bne	a4,a5,80003fbc <dirlink+0xb2>
}
    80003f90:	70e2                	ld	ra,56(sp)
    80003f92:	7442                	ld	s0,48(sp)
    80003f94:	74a2                	ld	s1,40(sp)
    80003f96:	7902                	ld	s2,32(sp)
    80003f98:	69e2                	ld	s3,24(sp)
    80003f9a:	6a42                	ld	s4,16(sp)
    80003f9c:	6121                	addi	sp,sp,64
    80003f9e:	8082                	ret
    iput(ip);
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	a30080e7          	jalr	-1488(ra) # 800039d0 <iput>
    return -1;
    80003fa8:	557d                	li	a0,-1
    80003faa:	b7dd                	j	80003f90 <dirlink+0x86>
      panic("dirlink read");
    80003fac:	00004517          	auipc	a0,0x4
    80003fb0:	7cc50513          	addi	a0,a0,1996 # 80008778 <syscalls+0x1d0>
    80003fb4:	ffffc097          	auipc	ra,0xffffc
    80003fb8:	576080e7          	jalr	1398(ra) # 8000052a <panic>
    panic("dirlink");
    80003fbc:	00005517          	auipc	a0,0x5
    80003fc0:	8c450513          	addi	a0,a0,-1852 # 80008880 <syscalls+0x2d8>
    80003fc4:	ffffc097          	auipc	ra,0xffffc
    80003fc8:	566080e7          	jalr	1382(ra) # 8000052a <panic>

0000000080003fcc <namei>:

struct inode*
namei(char *path)
{
    80003fcc:	1101                	addi	sp,sp,-32
    80003fce:	ec06                	sd	ra,24(sp)
    80003fd0:	e822                	sd	s0,16(sp)
    80003fd2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fd4:	fe040613          	addi	a2,s0,-32
    80003fd8:	4581                	li	a1,0
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	dd0080e7          	jalr	-560(ra) # 80003daa <namex>
}
    80003fe2:	60e2                	ld	ra,24(sp)
    80003fe4:	6442                	ld	s0,16(sp)
    80003fe6:	6105                	addi	sp,sp,32
    80003fe8:	8082                	ret

0000000080003fea <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fea:	1141                	addi	sp,sp,-16
    80003fec:	e406                	sd	ra,8(sp)
    80003fee:	e022                	sd	s0,0(sp)
    80003ff0:	0800                	addi	s0,sp,16
    80003ff2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ff4:	4585                	li	a1,1
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	db4080e7          	jalr	-588(ra) # 80003daa <namex>
}
    80003ffe:	60a2                	ld	ra,8(sp)
    80004000:	6402                	ld	s0,0(sp)
    80004002:	0141                	addi	sp,sp,16
    80004004:	8082                	ret

0000000080004006 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004006:	1101                	addi	sp,sp,-32
    80004008:	ec06                	sd	ra,24(sp)
    8000400a:	e822                	sd	s0,16(sp)
    8000400c:	e426                	sd	s1,8(sp)
    8000400e:	e04a                	sd	s2,0(sp)
    80004010:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004012:	0001d917          	auipc	s2,0x1d
    80004016:	25e90913          	addi	s2,s2,606 # 80021270 <log>
    8000401a:	01892583          	lw	a1,24(s2)
    8000401e:	02892503          	lw	a0,40(s2)
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	ff0080e7          	jalr	-16(ra) # 80003012 <bread>
    8000402a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000402c:	02c92683          	lw	a3,44(s2)
    80004030:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004032:	02d05863          	blez	a3,80004062 <write_head+0x5c>
    80004036:	0001d797          	auipc	a5,0x1d
    8000403a:	26a78793          	addi	a5,a5,618 # 800212a0 <log+0x30>
    8000403e:	05c50713          	addi	a4,a0,92
    80004042:	36fd                	addiw	a3,a3,-1
    80004044:	02069613          	slli	a2,a3,0x20
    80004048:	01e65693          	srli	a3,a2,0x1e
    8000404c:	0001d617          	auipc	a2,0x1d
    80004050:	25860613          	addi	a2,a2,600 # 800212a4 <log+0x34>
    80004054:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004056:	4390                	lw	a2,0(a5)
    80004058:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000405a:	0791                	addi	a5,a5,4
    8000405c:	0711                	addi	a4,a4,4
    8000405e:	fed79ce3          	bne	a5,a3,80004056 <write_head+0x50>
  }
  bwrite(buf);
    80004062:	8526                	mv	a0,s1
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	0a0080e7          	jalr	160(ra) # 80003104 <bwrite>
  brelse(buf);
    8000406c:	8526                	mv	a0,s1
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	0d4080e7          	jalr	212(ra) # 80003142 <brelse>
}
    80004076:	60e2                	ld	ra,24(sp)
    80004078:	6442                	ld	s0,16(sp)
    8000407a:	64a2                	ld	s1,8(sp)
    8000407c:	6902                	ld	s2,0(sp)
    8000407e:	6105                	addi	sp,sp,32
    80004080:	8082                	ret

0000000080004082 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004082:	0001d797          	auipc	a5,0x1d
    80004086:	21a7a783          	lw	a5,538(a5) # 8002129c <log+0x2c>
    8000408a:	0af05d63          	blez	a5,80004144 <install_trans+0xc2>
{
    8000408e:	7139                	addi	sp,sp,-64
    80004090:	fc06                	sd	ra,56(sp)
    80004092:	f822                	sd	s0,48(sp)
    80004094:	f426                	sd	s1,40(sp)
    80004096:	f04a                	sd	s2,32(sp)
    80004098:	ec4e                	sd	s3,24(sp)
    8000409a:	e852                	sd	s4,16(sp)
    8000409c:	e456                	sd	s5,8(sp)
    8000409e:	e05a                	sd	s6,0(sp)
    800040a0:	0080                	addi	s0,sp,64
    800040a2:	8b2a                	mv	s6,a0
    800040a4:	0001da97          	auipc	s5,0x1d
    800040a8:	1fca8a93          	addi	s5,s5,508 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ac:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ae:	0001d997          	auipc	s3,0x1d
    800040b2:	1c298993          	addi	s3,s3,450 # 80021270 <log>
    800040b6:	a00d                	j	800040d8 <install_trans+0x56>
    brelse(lbuf);
    800040b8:	854a                	mv	a0,s2
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	088080e7          	jalr	136(ra) # 80003142 <brelse>
    brelse(dbuf);
    800040c2:	8526                	mv	a0,s1
    800040c4:	fffff097          	auipc	ra,0xfffff
    800040c8:	07e080e7          	jalr	126(ra) # 80003142 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040cc:	2a05                	addiw	s4,s4,1
    800040ce:	0a91                	addi	s5,s5,4
    800040d0:	02c9a783          	lw	a5,44(s3)
    800040d4:	04fa5e63          	bge	s4,a5,80004130 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040d8:	0189a583          	lw	a1,24(s3)
    800040dc:	014585bb          	addw	a1,a1,s4
    800040e0:	2585                	addiw	a1,a1,1
    800040e2:	0289a503          	lw	a0,40(s3)
    800040e6:	fffff097          	auipc	ra,0xfffff
    800040ea:	f2c080e7          	jalr	-212(ra) # 80003012 <bread>
    800040ee:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040f0:	000aa583          	lw	a1,0(s5)
    800040f4:	0289a503          	lw	a0,40(s3)
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	f1a080e7          	jalr	-230(ra) # 80003012 <bread>
    80004100:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004102:	40000613          	li	a2,1024
    80004106:	05890593          	addi	a1,s2,88
    8000410a:	05850513          	addi	a0,a0,88
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	c0c080e7          	jalr	-1012(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004116:	8526                	mv	a0,s1
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	fec080e7          	jalr	-20(ra) # 80003104 <bwrite>
    if(recovering == 0)
    80004120:	f80b1ce3          	bnez	s6,800040b8 <install_trans+0x36>
      bunpin(dbuf);
    80004124:	8526                	mv	a0,s1
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	0f6080e7          	jalr	246(ra) # 8000321c <bunpin>
    8000412e:	b769                	j	800040b8 <install_trans+0x36>
}
    80004130:	70e2                	ld	ra,56(sp)
    80004132:	7442                	ld	s0,48(sp)
    80004134:	74a2                	ld	s1,40(sp)
    80004136:	7902                	ld	s2,32(sp)
    80004138:	69e2                	ld	s3,24(sp)
    8000413a:	6a42                	ld	s4,16(sp)
    8000413c:	6aa2                	ld	s5,8(sp)
    8000413e:	6b02                	ld	s6,0(sp)
    80004140:	6121                	addi	sp,sp,64
    80004142:	8082                	ret
    80004144:	8082                	ret

0000000080004146 <initlog>:
{
    80004146:	7179                	addi	sp,sp,-48
    80004148:	f406                	sd	ra,40(sp)
    8000414a:	f022                	sd	s0,32(sp)
    8000414c:	ec26                	sd	s1,24(sp)
    8000414e:	e84a                	sd	s2,16(sp)
    80004150:	e44e                	sd	s3,8(sp)
    80004152:	1800                	addi	s0,sp,48
    80004154:	892a                	mv	s2,a0
    80004156:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004158:	0001d497          	auipc	s1,0x1d
    8000415c:	11848493          	addi	s1,s1,280 # 80021270 <log>
    80004160:	00004597          	auipc	a1,0x4
    80004164:	62858593          	addi	a1,a1,1576 # 80008788 <syscalls+0x1e0>
    80004168:	8526                	mv	a0,s1
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	9c8080e7          	jalr	-1592(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004172:	0149a583          	lw	a1,20(s3)
    80004176:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004178:	0109a783          	lw	a5,16(s3)
    8000417c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000417e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004182:	854a                	mv	a0,s2
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	e8e080e7          	jalr	-370(ra) # 80003012 <bread>
  log.lh.n = lh->n;
    8000418c:	4d34                	lw	a3,88(a0)
    8000418e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004190:	02d05663          	blez	a3,800041bc <initlog+0x76>
    80004194:	05c50793          	addi	a5,a0,92
    80004198:	0001d717          	auipc	a4,0x1d
    8000419c:	10870713          	addi	a4,a4,264 # 800212a0 <log+0x30>
    800041a0:	36fd                	addiw	a3,a3,-1
    800041a2:	02069613          	slli	a2,a3,0x20
    800041a6:	01e65693          	srli	a3,a2,0x1e
    800041aa:	06050613          	addi	a2,a0,96
    800041ae:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041b0:	4390                	lw	a2,0(a5)
    800041b2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041b4:	0791                	addi	a5,a5,4
    800041b6:	0711                	addi	a4,a4,4
    800041b8:	fed79ce3          	bne	a5,a3,800041b0 <initlog+0x6a>
  brelse(buf);
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	f86080e7          	jalr	-122(ra) # 80003142 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041c4:	4505                	li	a0,1
    800041c6:	00000097          	auipc	ra,0x0
    800041ca:	ebc080e7          	jalr	-324(ra) # 80004082 <install_trans>
  log.lh.n = 0;
    800041ce:	0001d797          	auipc	a5,0x1d
    800041d2:	0c07a723          	sw	zero,206(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	e30080e7          	jalr	-464(ra) # 80004006 <write_head>
}
    800041de:	70a2                	ld	ra,40(sp)
    800041e0:	7402                	ld	s0,32(sp)
    800041e2:	64e2                	ld	s1,24(sp)
    800041e4:	6942                	ld	s2,16(sp)
    800041e6:	69a2                	ld	s3,8(sp)
    800041e8:	6145                	addi	sp,sp,48
    800041ea:	8082                	ret

00000000800041ec <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041ec:	1101                	addi	sp,sp,-32
    800041ee:	ec06                	sd	ra,24(sp)
    800041f0:	e822                	sd	s0,16(sp)
    800041f2:	e426                	sd	s1,8(sp)
    800041f4:	e04a                	sd	s2,0(sp)
    800041f6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041f8:	0001d517          	auipc	a0,0x1d
    800041fc:	07850513          	addi	a0,a0,120 # 80021270 <log>
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	9c2080e7          	jalr	-1598(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004208:	0001d497          	auipc	s1,0x1d
    8000420c:	06848493          	addi	s1,s1,104 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004210:	4979                	li	s2,30
    80004212:	a039                	j	80004220 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004214:	85a6                	mv	a1,s1
    80004216:	8526                	mv	a0,s1
    80004218:	ffffe097          	auipc	ra,0xffffe
    8000421c:	e2e080e7          	jalr	-466(ra) # 80002046 <sleep>
    if(log.committing){
    80004220:	50dc                	lw	a5,36(s1)
    80004222:	fbed                	bnez	a5,80004214 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004224:	509c                	lw	a5,32(s1)
    80004226:	0017871b          	addiw	a4,a5,1
    8000422a:	0007069b          	sext.w	a3,a4
    8000422e:	0027179b          	slliw	a5,a4,0x2
    80004232:	9fb9                	addw	a5,a5,a4
    80004234:	0017979b          	slliw	a5,a5,0x1
    80004238:	54d8                	lw	a4,44(s1)
    8000423a:	9fb9                	addw	a5,a5,a4
    8000423c:	00f95963          	bge	s2,a5,8000424e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004240:	85a6                	mv	a1,s1
    80004242:	8526                	mv	a0,s1
    80004244:	ffffe097          	auipc	ra,0xffffe
    80004248:	e02080e7          	jalr	-510(ra) # 80002046 <sleep>
    8000424c:	bfd1                	j	80004220 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000424e:	0001d517          	auipc	a0,0x1d
    80004252:	02250513          	addi	a0,a0,34 # 80021270 <log>
    80004256:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	a1e080e7          	jalr	-1506(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004260:	60e2                	ld	ra,24(sp)
    80004262:	6442                	ld	s0,16(sp)
    80004264:	64a2                	ld	s1,8(sp)
    80004266:	6902                	ld	s2,0(sp)
    80004268:	6105                	addi	sp,sp,32
    8000426a:	8082                	ret

000000008000426c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000426c:	7139                	addi	sp,sp,-64
    8000426e:	fc06                	sd	ra,56(sp)
    80004270:	f822                	sd	s0,48(sp)
    80004272:	f426                	sd	s1,40(sp)
    80004274:	f04a                	sd	s2,32(sp)
    80004276:	ec4e                	sd	s3,24(sp)
    80004278:	e852                	sd	s4,16(sp)
    8000427a:	e456                	sd	s5,8(sp)
    8000427c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000427e:	0001d497          	auipc	s1,0x1d
    80004282:	ff248493          	addi	s1,s1,-14 # 80021270 <log>
    80004286:	8526                	mv	a0,s1
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	93a080e7          	jalr	-1734(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004290:	509c                	lw	a5,32(s1)
    80004292:	37fd                	addiw	a5,a5,-1
    80004294:	0007891b          	sext.w	s2,a5
    80004298:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000429a:	50dc                	lw	a5,36(s1)
    8000429c:	e7b9                	bnez	a5,800042ea <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000429e:	04091e63          	bnez	s2,800042fa <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042a2:	0001d497          	auipc	s1,0x1d
    800042a6:	fce48493          	addi	s1,s1,-50 # 80021270 <log>
    800042aa:	4785                	li	a5,1
    800042ac:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	9c6080e7          	jalr	-1594(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042b8:	54dc                	lw	a5,44(s1)
    800042ba:	06f04763          	bgtz	a5,80004328 <end_op+0xbc>
    acquire(&log.lock);
    800042be:	0001d497          	auipc	s1,0x1d
    800042c2:	fb248493          	addi	s1,s1,-78 # 80021270 <log>
    800042c6:	8526                	mv	a0,s1
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	8fa080e7          	jalr	-1798(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800042d0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffe097          	auipc	ra,0xffffe
    800042da:	efc080e7          	jalr	-260(ra) # 800021d2 <wakeup>
    release(&log.lock);
    800042de:	8526                	mv	a0,s1
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	996080e7          	jalr	-1642(ra) # 80000c76 <release>
}
    800042e8:	a03d                	j	80004316 <end_op+0xaa>
    panic("log.committing");
    800042ea:	00004517          	auipc	a0,0x4
    800042ee:	4a650513          	addi	a0,a0,1190 # 80008790 <syscalls+0x1e8>
    800042f2:	ffffc097          	auipc	ra,0xffffc
    800042f6:	238080e7          	jalr	568(ra) # 8000052a <panic>
    wakeup(&log);
    800042fa:	0001d497          	auipc	s1,0x1d
    800042fe:	f7648493          	addi	s1,s1,-138 # 80021270 <log>
    80004302:	8526                	mv	a0,s1
    80004304:	ffffe097          	auipc	ra,0xffffe
    80004308:	ece080e7          	jalr	-306(ra) # 800021d2 <wakeup>
  release(&log.lock);
    8000430c:	8526                	mv	a0,s1
    8000430e:	ffffd097          	auipc	ra,0xffffd
    80004312:	968080e7          	jalr	-1688(ra) # 80000c76 <release>
}
    80004316:	70e2                	ld	ra,56(sp)
    80004318:	7442                	ld	s0,48(sp)
    8000431a:	74a2                	ld	s1,40(sp)
    8000431c:	7902                	ld	s2,32(sp)
    8000431e:	69e2                	ld	s3,24(sp)
    80004320:	6a42                	ld	s4,16(sp)
    80004322:	6aa2                	ld	s5,8(sp)
    80004324:	6121                	addi	sp,sp,64
    80004326:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004328:	0001da97          	auipc	s5,0x1d
    8000432c:	f78a8a93          	addi	s5,s5,-136 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004330:	0001da17          	auipc	s4,0x1d
    80004334:	f40a0a13          	addi	s4,s4,-192 # 80021270 <log>
    80004338:	018a2583          	lw	a1,24(s4)
    8000433c:	012585bb          	addw	a1,a1,s2
    80004340:	2585                	addiw	a1,a1,1
    80004342:	028a2503          	lw	a0,40(s4)
    80004346:	fffff097          	auipc	ra,0xfffff
    8000434a:	ccc080e7          	jalr	-820(ra) # 80003012 <bread>
    8000434e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004350:	000aa583          	lw	a1,0(s5)
    80004354:	028a2503          	lw	a0,40(s4)
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	cba080e7          	jalr	-838(ra) # 80003012 <bread>
    80004360:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004362:	40000613          	li	a2,1024
    80004366:	05850593          	addi	a1,a0,88
    8000436a:	05848513          	addi	a0,s1,88
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	9ac080e7          	jalr	-1620(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004376:	8526                	mv	a0,s1
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	d8c080e7          	jalr	-628(ra) # 80003104 <bwrite>
    brelse(from);
    80004380:	854e                	mv	a0,s3
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	dc0080e7          	jalr	-576(ra) # 80003142 <brelse>
    brelse(to);
    8000438a:	8526                	mv	a0,s1
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	db6080e7          	jalr	-586(ra) # 80003142 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004394:	2905                	addiw	s2,s2,1
    80004396:	0a91                	addi	s5,s5,4
    80004398:	02ca2783          	lw	a5,44(s4)
    8000439c:	f8f94ee3          	blt	s2,a5,80004338 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	c66080e7          	jalr	-922(ra) # 80004006 <write_head>
    install_trans(0); // Now install writes to home locations
    800043a8:	4501                	li	a0,0
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	cd8080e7          	jalr	-808(ra) # 80004082 <install_trans>
    log.lh.n = 0;
    800043b2:	0001d797          	auipc	a5,0x1d
    800043b6:	ee07a523          	sw	zero,-278(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043ba:	00000097          	auipc	ra,0x0
    800043be:	c4c080e7          	jalr	-948(ra) # 80004006 <write_head>
    800043c2:	bdf5                	j	800042be <end_op+0x52>

00000000800043c4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043c4:	1101                	addi	sp,sp,-32
    800043c6:	ec06                	sd	ra,24(sp)
    800043c8:	e822                	sd	s0,16(sp)
    800043ca:	e426                	sd	s1,8(sp)
    800043cc:	e04a                	sd	s2,0(sp)
    800043ce:	1000                	addi	s0,sp,32
    800043d0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043d2:	0001d917          	auipc	s2,0x1d
    800043d6:	e9e90913          	addi	s2,s2,-354 # 80021270 <log>
    800043da:	854a                	mv	a0,s2
    800043dc:	ffffc097          	auipc	ra,0xffffc
    800043e0:	7e6080e7          	jalr	2022(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043e4:	02c92603          	lw	a2,44(s2)
    800043e8:	47f5                	li	a5,29
    800043ea:	06c7c563          	blt	a5,a2,80004454 <log_write+0x90>
    800043ee:	0001d797          	auipc	a5,0x1d
    800043f2:	e9e7a783          	lw	a5,-354(a5) # 8002128c <log+0x1c>
    800043f6:	37fd                	addiw	a5,a5,-1
    800043f8:	04f65e63          	bge	a2,a5,80004454 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043fc:	0001d797          	auipc	a5,0x1d
    80004400:	e947a783          	lw	a5,-364(a5) # 80021290 <log+0x20>
    80004404:	06f05063          	blez	a5,80004464 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004408:	4781                	li	a5,0
    8000440a:	06c05563          	blez	a2,80004474 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000440e:	44cc                	lw	a1,12(s1)
    80004410:	0001d717          	auipc	a4,0x1d
    80004414:	e9070713          	addi	a4,a4,-368 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004418:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000441a:	4314                	lw	a3,0(a4)
    8000441c:	04b68c63          	beq	a3,a1,80004474 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004420:	2785                	addiw	a5,a5,1
    80004422:	0711                	addi	a4,a4,4
    80004424:	fef61be3          	bne	a2,a5,8000441a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004428:	0621                	addi	a2,a2,8
    8000442a:	060a                	slli	a2,a2,0x2
    8000442c:	0001d797          	auipc	a5,0x1d
    80004430:	e4478793          	addi	a5,a5,-444 # 80021270 <log>
    80004434:	963e                	add	a2,a2,a5
    80004436:	44dc                	lw	a5,12(s1)
    80004438:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000443a:	8526                	mv	a0,s1
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	da4080e7          	jalr	-604(ra) # 800031e0 <bpin>
    log.lh.n++;
    80004444:	0001d717          	auipc	a4,0x1d
    80004448:	e2c70713          	addi	a4,a4,-468 # 80021270 <log>
    8000444c:	575c                	lw	a5,44(a4)
    8000444e:	2785                	addiw	a5,a5,1
    80004450:	d75c                	sw	a5,44(a4)
    80004452:	a835                	j	8000448e <log_write+0xca>
    panic("too big a transaction");
    80004454:	00004517          	auipc	a0,0x4
    80004458:	34c50513          	addi	a0,a0,844 # 800087a0 <syscalls+0x1f8>
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	0ce080e7          	jalr	206(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004464:	00004517          	auipc	a0,0x4
    80004468:	35450513          	addi	a0,a0,852 # 800087b8 <syscalls+0x210>
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	0be080e7          	jalr	190(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004474:	00878713          	addi	a4,a5,8
    80004478:	00271693          	slli	a3,a4,0x2
    8000447c:	0001d717          	auipc	a4,0x1d
    80004480:	df470713          	addi	a4,a4,-524 # 80021270 <log>
    80004484:	9736                	add	a4,a4,a3
    80004486:	44d4                	lw	a3,12(s1)
    80004488:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000448a:	faf608e3          	beq	a2,a5,8000443a <log_write+0x76>
  }
  release(&log.lock);
    8000448e:	0001d517          	auipc	a0,0x1d
    80004492:	de250513          	addi	a0,a0,-542 # 80021270 <log>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	7e0080e7          	jalr	2016(ra) # 80000c76 <release>
}
    8000449e:	60e2                	ld	ra,24(sp)
    800044a0:	6442                	ld	s0,16(sp)
    800044a2:	64a2                	ld	s1,8(sp)
    800044a4:	6902                	ld	s2,0(sp)
    800044a6:	6105                	addi	sp,sp,32
    800044a8:	8082                	ret

00000000800044aa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044aa:	1101                	addi	sp,sp,-32
    800044ac:	ec06                	sd	ra,24(sp)
    800044ae:	e822                	sd	s0,16(sp)
    800044b0:	e426                	sd	s1,8(sp)
    800044b2:	e04a                	sd	s2,0(sp)
    800044b4:	1000                	addi	s0,sp,32
    800044b6:	84aa                	mv	s1,a0
    800044b8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044ba:	00004597          	auipc	a1,0x4
    800044be:	31e58593          	addi	a1,a1,798 # 800087d8 <syscalls+0x230>
    800044c2:	0521                	addi	a0,a0,8
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	66e080e7          	jalr	1646(ra) # 80000b32 <initlock>
  lk->name = name;
    800044cc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d4:	0204a423          	sw	zero,40(s1)
}
    800044d8:	60e2                	ld	ra,24(sp)
    800044da:	6442                	ld	s0,16(sp)
    800044dc:	64a2                	ld	s1,8(sp)
    800044de:	6902                	ld	s2,0(sp)
    800044e0:	6105                	addi	sp,sp,32
    800044e2:	8082                	ret

00000000800044e4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044e4:	1101                	addi	sp,sp,-32
    800044e6:	ec06                	sd	ra,24(sp)
    800044e8:	e822                	sd	s0,16(sp)
    800044ea:	e426                	sd	s1,8(sp)
    800044ec:	e04a                	sd	s2,0(sp)
    800044ee:	1000                	addi	s0,sp,32
    800044f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044f2:	00850913          	addi	s2,a0,8
    800044f6:	854a                	mv	a0,s2
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	6ca080e7          	jalr	1738(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004500:	409c                	lw	a5,0(s1)
    80004502:	cb89                	beqz	a5,80004514 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004504:	85ca                	mv	a1,s2
    80004506:	8526                	mv	a0,s1
    80004508:	ffffe097          	auipc	ra,0xffffe
    8000450c:	b3e080e7          	jalr	-1218(ra) # 80002046 <sleep>
  while (lk->locked) {
    80004510:	409c                	lw	a5,0(s1)
    80004512:	fbed                	bnez	a5,80004504 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004514:	4785                	li	a5,1
    80004516:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004518:	ffffd097          	auipc	ra,0xffffd
    8000451c:	466080e7          	jalr	1126(ra) # 8000197e <myproc>
    80004520:	591c                	lw	a5,48(a0)
    80004522:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004524:	854a                	mv	a0,s2
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	750080e7          	jalr	1872(ra) # 80000c76 <release>
}
    8000452e:	60e2                	ld	ra,24(sp)
    80004530:	6442                	ld	s0,16(sp)
    80004532:	64a2                	ld	s1,8(sp)
    80004534:	6902                	ld	s2,0(sp)
    80004536:	6105                	addi	sp,sp,32
    80004538:	8082                	ret

000000008000453a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000453a:	1101                	addi	sp,sp,-32
    8000453c:	ec06                	sd	ra,24(sp)
    8000453e:	e822                	sd	s0,16(sp)
    80004540:	e426                	sd	s1,8(sp)
    80004542:	e04a                	sd	s2,0(sp)
    80004544:	1000                	addi	s0,sp,32
    80004546:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004548:	00850913          	addi	s2,a0,8
    8000454c:	854a                	mv	a0,s2
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	674080e7          	jalr	1652(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004556:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000455a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000455e:	8526                	mv	a0,s1
    80004560:	ffffe097          	auipc	ra,0xffffe
    80004564:	c72080e7          	jalr	-910(ra) # 800021d2 <wakeup>
  release(&lk->lk);
    80004568:	854a                	mv	a0,s2
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	70c080e7          	jalr	1804(ra) # 80000c76 <release>
}
    80004572:	60e2                	ld	ra,24(sp)
    80004574:	6442                	ld	s0,16(sp)
    80004576:	64a2                	ld	s1,8(sp)
    80004578:	6902                	ld	s2,0(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret

000000008000457e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000457e:	7179                	addi	sp,sp,-48
    80004580:	f406                	sd	ra,40(sp)
    80004582:	f022                	sd	s0,32(sp)
    80004584:	ec26                	sd	s1,24(sp)
    80004586:	e84a                	sd	s2,16(sp)
    80004588:	e44e                	sd	s3,8(sp)
    8000458a:	1800                	addi	s0,sp,48
    8000458c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000458e:	00850913          	addi	s2,a0,8
    80004592:	854a                	mv	a0,s2
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	62e080e7          	jalr	1582(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000459c:	409c                	lw	a5,0(s1)
    8000459e:	ef99                	bnez	a5,800045bc <holdingsleep+0x3e>
    800045a0:	4481                	li	s1,0
  release(&lk->lk);
    800045a2:	854a                	mv	a0,s2
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	6d2080e7          	jalr	1746(ra) # 80000c76 <release>
  return r;
}
    800045ac:	8526                	mv	a0,s1
    800045ae:	70a2                	ld	ra,40(sp)
    800045b0:	7402                	ld	s0,32(sp)
    800045b2:	64e2                	ld	s1,24(sp)
    800045b4:	6942                	ld	s2,16(sp)
    800045b6:	69a2                	ld	s3,8(sp)
    800045b8:	6145                	addi	sp,sp,48
    800045ba:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045bc:	0284a983          	lw	s3,40(s1)
    800045c0:	ffffd097          	auipc	ra,0xffffd
    800045c4:	3be080e7          	jalr	958(ra) # 8000197e <myproc>
    800045c8:	5904                	lw	s1,48(a0)
    800045ca:	413484b3          	sub	s1,s1,s3
    800045ce:	0014b493          	seqz	s1,s1
    800045d2:	bfc1                	j	800045a2 <holdingsleep+0x24>

00000000800045d4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045d4:	1141                	addi	sp,sp,-16
    800045d6:	e406                	sd	ra,8(sp)
    800045d8:	e022                	sd	s0,0(sp)
    800045da:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045dc:	00004597          	auipc	a1,0x4
    800045e0:	20c58593          	addi	a1,a1,524 # 800087e8 <syscalls+0x240>
    800045e4:	0001d517          	auipc	a0,0x1d
    800045e8:	dd450513          	addi	a0,a0,-556 # 800213b8 <ftable>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	546080e7          	jalr	1350(ra) # 80000b32 <initlock>
}
    800045f4:	60a2                	ld	ra,8(sp)
    800045f6:	6402                	ld	s0,0(sp)
    800045f8:	0141                	addi	sp,sp,16
    800045fa:	8082                	ret

00000000800045fc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045fc:	1101                	addi	sp,sp,-32
    800045fe:	ec06                	sd	ra,24(sp)
    80004600:	e822                	sd	s0,16(sp)
    80004602:	e426                	sd	s1,8(sp)
    80004604:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004606:	0001d517          	auipc	a0,0x1d
    8000460a:	db250513          	addi	a0,a0,-590 # 800213b8 <ftable>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	5b4080e7          	jalr	1460(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004616:	0001d497          	auipc	s1,0x1d
    8000461a:	dba48493          	addi	s1,s1,-582 # 800213d0 <ftable+0x18>
    8000461e:	0001e717          	auipc	a4,0x1e
    80004622:	d5270713          	addi	a4,a4,-686 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004626:	40dc                	lw	a5,4(s1)
    80004628:	cf99                	beqz	a5,80004646 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000462a:	02848493          	addi	s1,s1,40
    8000462e:	fee49ce3          	bne	s1,a4,80004626 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004632:	0001d517          	auipc	a0,0x1d
    80004636:	d8650513          	addi	a0,a0,-634 # 800213b8 <ftable>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	63c080e7          	jalr	1596(ra) # 80000c76 <release>
  return 0;
    80004642:	4481                	li	s1,0
    80004644:	a819                	j	8000465a <filealloc+0x5e>
      f->ref = 1;
    80004646:	4785                	li	a5,1
    80004648:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000464a:	0001d517          	auipc	a0,0x1d
    8000464e:	d6e50513          	addi	a0,a0,-658 # 800213b8 <ftable>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	624080e7          	jalr	1572(ra) # 80000c76 <release>
}
    8000465a:	8526                	mv	a0,s1
    8000465c:	60e2                	ld	ra,24(sp)
    8000465e:	6442                	ld	s0,16(sp)
    80004660:	64a2                	ld	s1,8(sp)
    80004662:	6105                	addi	sp,sp,32
    80004664:	8082                	ret

0000000080004666 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004666:	1101                	addi	sp,sp,-32
    80004668:	ec06                	sd	ra,24(sp)
    8000466a:	e822                	sd	s0,16(sp)
    8000466c:	e426                	sd	s1,8(sp)
    8000466e:	1000                	addi	s0,sp,32
    80004670:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	d4650513          	addi	a0,a0,-698 # 800213b8 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	548080e7          	jalr	1352(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004682:	40dc                	lw	a5,4(s1)
    80004684:	02f05263          	blez	a5,800046a8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004688:	2785                	addiw	a5,a5,1
    8000468a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000468c:	0001d517          	auipc	a0,0x1d
    80004690:	d2c50513          	addi	a0,a0,-724 # 800213b8 <ftable>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	5e2080e7          	jalr	1506(ra) # 80000c76 <release>
  return f;
}
    8000469c:	8526                	mv	a0,s1
    8000469e:	60e2                	ld	ra,24(sp)
    800046a0:	6442                	ld	s0,16(sp)
    800046a2:	64a2                	ld	s1,8(sp)
    800046a4:	6105                	addi	sp,sp,32
    800046a6:	8082                	ret
    panic("filedup");
    800046a8:	00004517          	auipc	a0,0x4
    800046ac:	14850513          	addi	a0,a0,328 # 800087f0 <syscalls+0x248>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	e7a080e7          	jalr	-390(ra) # 8000052a <panic>

00000000800046b8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046b8:	7139                	addi	sp,sp,-64
    800046ba:	fc06                	sd	ra,56(sp)
    800046bc:	f822                	sd	s0,48(sp)
    800046be:	f426                	sd	s1,40(sp)
    800046c0:	f04a                	sd	s2,32(sp)
    800046c2:	ec4e                	sd	s3,24(sp)
    800046c4:	e852                	sd	s4,16(sp)
    800046c6:	e456                	sd	s5,8(sp)
    800046c8:	0080                	addi	s0,sp,64
    800046ca:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046cc:	0001d517          	auipc	a0,0x1d
    800046d0:	cec50513          	addi	a0,a0,-788 # 800213b8 <ftable>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	4ee080e7          	jalr	1262(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800046dc:	40dc                	lw	a5,4(s1)
    800046de:	06f05163          	blez	a5,80004740 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046e2:	37fd                	addiw	a5,a5,-1
    800046e4:	0007871b          	sext.w	a4,a5
    800046e8:	c0dc                	sw	a5,4(s1)
    800046ea:	06e04363          	bgtz	a4,80004750 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046ee:	0004a903          	lw	s2,0(s1)
    800046f2:	0094ca83          	lbu	s5,9(s1)
    800046f6:	0104ba03          	ld	s4,16(s1)
    800046fa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046fe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004702:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004706:	0001d517          	auipc	a0,0x1d
    8000470a:	cb250513          	addi	a0,a0,-846 # 800213b8 <ftable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	568080e7          	jalr	1384(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004716:	4785                	li	a5,1
    80004718:	04f90d63          	beq	s2,a5,80004772 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000471c:	3979                	addiw	s2,s2,-2
    8000471e:	4785                	li	a5,1
    80004720:	0527e063          	bltu	a5,s2,80004760 <fileclose+0xa8>
    begin_op();
    80004724:	00000097          	auipc	ra,0x0
    80004728:	ac8080e7          	jalr	-1336(ra) # 800041ec <begin_op>
    iput(ff.ip);
    8000472c:	854e                	mv	a0,s3
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	2a2080e7          	jalr	674(ra) # 800039d0 <iput>
    end_op();
    80004736:	00000097          	auipc	ra,0x0
    8000473a:	b36080e7          	jalr	-1226(ra) # 8000426c <end_op>
    8000473e:	a00d                	j	80004760 <fileclose+0xa8>
    panic("fileclose");
    80004740:	00004517          	auipc	a0,0x4
    80004744:	0b850513          	addi	a0,a0,184 # 800087f8 <syscalls+0x250>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	de2080e7          	jalr	-542(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004750:	0001d517          	auipc	a0,0x1d
    80004754:	c6850513          	addi	a0,a0,-920 # 800213b8 <ftable>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	51e080e7          	jalr	1310(ra) # 80000c76 <release>
  }
}
    80004760:	70e2                	ld	ra,56(sp)
    80004762:	7442                	ld	s0,48(sp)
    80004764:	74a2                	ld	s1,40(sp)
    80004766:	7902                	ld	s2,32(sp)
    80004768:	69e2                	ld	s3,24(sp)
    8000476a:	6a42                	ld	s4,16(sp)
    8000476c:	6aa2                	ld	s5,8(sp)
    8000476e:	6121                	addi	sp,sp,64
    80004770:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004772:	85d6                	mv	a1,s5
    80004774:	8552                	mv	a0,s4
    80004776:	00000097          	auipc	ra,0x0
    8000477a:	34c080e7          	jalr	844(ra) # 80004ac2 <pipeclose>
    8000477e:	b7cd                	j	80004760 <fileclose+0xa8>

0000000080004780 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004780:	715d                	addi	sp,sp,-80
    80004782:	e486                	sd	ra,72(sp)
    80004784:	e0a2                	sd	s0,64(sp)
    80004786:	fc26                	sd	s1,56(sp)
    80004788:	f84a                	sd	s2,48(sp)
    8000478a:	f44e                	sd	s3,40(sp)
    8000478c:	0880                	addi	s0,sp,80
    8000478e:	84aa                	mv	s1,a0
    80004790:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004792:	ffffd097          	auipc	ra,0xffffd
    80004796:	1ec080e7          	jalr	492(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000479a:	409c                	lw	a5,0(s1)
    8000479c:	37f9                	addiw	a5,a5,-2
    8000479e:	4705                	li	a4,1
    800047a0:	04f76763          	bltu	a4,a5,800047ee <filestat+0x6e>
    800047a4:	892a                	mv	s2,a0
    ilock(f->ip);
    800047a6:	6c88                	ld	a0,24(s1)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	06e080e7          	jalr	110(ra) # 80003816 <ilock>
    stati(f->ip, &st);
    800047b0:	fb840593          	addi	a1,s0,-72
    800047b4:	6c88                	ld	a0,24(s1)
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	2ea080e7          	jalr	746(ra) # 80003aa0 <stati>
    iunlock(f->ip);
    800047be:	6c88                	ld	a0,24(s1)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	118080e7          	jalr	280(ra) # 800038d8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047c8:	46e1                	li	a3,24
    800047ca:	fb840613          	addi	a2,s0,-72
    800047ce:	85ce                	mv	a1,s3
    800047d0:	05093503          	ld	a0,80(s2)
    800047d4:	ffffd097          	auipc	ra,0xffffd
    800047d8:	e6a080e7          	jalr	-406(ra) # 8000163e <copyout>
    800047dc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047e0:	60a6                	ld	ra,72(sp)
    800047e2:	6406                	ld	s0,64(sp)
    800047e4:	74e2                	ld	s1,56(sp)
    800047e6:	7942                	ld	s2,48(sp)
    800047e8:	79a2                	ld	s3,40(sp)
    800047ea:	6161                	addi	sp,sp,80
    800047ec:	8082                	ret
  return -1;
    800047ee:	557d                	li	a0,-1
    800047f0:	bfc5                	j	800047e0 <filestat+0x60>

00000000800047f2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047f2:	7179                	addi	sp,sp,-48
    800047f4:	f406                	sd	ra,40(sp)
    800047f6:	f022                	sd	s0,32(sp)
    800047f8:	ec26                	sd	s1,24(sp)
    800047fa:	e84a                	sd	s2,16(sp)
    800047fc:	e44e                	sd	s3,8(sp)
    800047fe:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004800:	00854783          	lbu	a5,8(a0)
    80004804:	c3d5                	beqz	a5,800048a8 <fileread+0xb6>
    80004806:	84aa                	mv	s1,a0
    80004808:	89ae                	mv	s3,a1
    8000480a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000480c:	411c                	lw	a5,0(a0)
    8000480e:	4705                	li	a4,1
    80004810:	04e78963          	beq	a5,a4,80004862 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004814:	470d                	li	a4,3
    80004816:	04e78d63          	beq	a5,a4,80004870 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000481a:	4709                	li	a4,2
    8000481c:	06e79e63          	bne	a5,a4,80004898 <fileread+0xa6>
    ilock(f->ip);
    80004820:	6d08                	ld	a0,24(a0)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	ff4080e7          	jalr	-12(ra) # 80003816 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000482a:	874a                	mv	a4,s2
    8000482c:	5094                	lw	a3,32(s1)
    8000482e:	864e                	mv	a2,s3
    80004830:	4585                	li	a1,1
    80004832:	6c88                	ld	a0,24(s1)
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	296080e7          	jalr	662(ra) # 80003aca <readi>
    8000483c:	892a                	mv	s2,a0
    8000483e:	00a05563          	blez	a0,80004848 <fileread+0x56>
      f->off += r;
    80004842:	509c                	lw	a5,32(s1)
    80004844:	9fa9                	addw	a5,a5,a0
    80004846:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004848:	6c88                	ld	a0,24(s1)
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	08e080e7          	jalr	142(ra) # 800038d8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004852:	854a                	mv	a0,s2
    80004854:	70a2                	ld	ra,40(sp)
    80004856:	7402                	ld	s0,32(sp)
    80004858:	64e2                	ld	s1,24(sp)
    8000485a:	6942                	ld	s2,16(sp)
    8000485c:	69a2                	ld	s3,8(sp)
    8000485e:	6145                	addi	sp,sp,48
    80004860:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004862:	6908                	ld	a0,16(a0)
    80004864:	00000097          	auipc	ra,0x0
    80004868:	3c0080e7          	jalr	960(ra) # 80004c24 <piperead>
    8000486c:	892a                	mv	s2,a0
    8000486e:	b7d5                	j	80004852 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004870:	02451783          	lh	a5,36(a0)
    80004874:	03079693          	slli	a3,a5,0x30
    80004878:	92c1                	srli	a3,a3,0x30
    8000487a:	4725                	li	a4,9
    8000487c:	02d76863          	bltu	a4,a3,800048ac <fileread+0xba>
    80004880:	0792                	slli	a5,a5,0x4
    80004882:	0001d717          	auipc	a4,0x1d
    80004886:	a9670713          	addi	a4,a4,-1386 # 80021318 <devsw>
    8000488a:	97ba                	add	a5,a5,a4
    8000488c:	639c                	ld	a5,0(a5)
    8000488e:	c38d                	beqz	a5,800048b0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004890:	4505                	li	a0,1
    80004892:	9782                	jalr	a5
    80004894:	892a                	mv	s2,a0
    80004896:	bf75                	j	80004852 <fileread+0x60>
    panic("fileread");
    80004898:	00004517          	auipc	a0,0x4
    8000489c:	f7050513          	addi	a0,a0,-144 # 80008808 <syscalls+0x260>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	c8a080e7          	jalr	-886(ra) # 8000052a <panic>
    return -1;
    800048a8:	597d                	li	s2,-1
    800048aa:	b765                	j	80004852 <fileread+0x60>
      return -1;
    800048ac:	597d                	li	s2,-1
    800048ae:	b755                	j	80004852 <fileread+0x60>
    800048b0:	597d                	li	s2,-1
    800048b2:	b745                	j	80004852 <fileread+0x60>

00000000800048b4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048b4:	715d                	addi	sp,sp,-80
    800048b6:	e486                	sd	ra,72(sp)
    800048b8:	e0a2                	sd	s0,64(sp)
    800048ba:	fc26                	sd	s1,56(sp)
    800048bc:	f84a                	sd	s2,48(sp)
    800048be:	f44e                	sd	s3,40(sp)
    800048c0:	f052                	sd	s4,32(sp)
    800048c2:	ec56                	sd	s5,24(sp)
    800048c4:	e85a                	sd	s6,16(sp)
    800048c6:	e45e                	sd	s7,8(sp)
    800048c8:	e062                	sd	s8,0(sp)
    800048ca:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048cc:	00954783          	lbu	a5,9(a0)
    800048d0:	10078663          	beqz	a5,800049dc <filewrite+0x128>
    800048d4:	892a                	mv	s2,a0
    800048d6:	8aae                	mv	s5,a1
    800048d8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048da:	411c                	lw	a5,0(a0)
    800048dc:	4705                	li	a4,1
    800048de:	02e78263          	beq	a5,a4,80004902 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048e2:	470d                	li	a4,3
    800048e4:	02e78663          	beq	a5,a4,80004910 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048e8:	4709                	li	a4,2
    800048ea:	0ee79163          	bne	a5,a4,800049cc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048ee:	0ac05d63          	blez	a2,800049a8 <filewrite+0xf4>
    int i = 0;
    800048f2:	4981                	li	s3,0
    800048f4:	6b05                	lui	s6,0x1
    800048f6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048fa:	6b85                	lui	s7,0x1
    800048fc:	c00b8b9b          	addiw	s7,s7,-1024
    80004900:	a861                	j	80004998 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004902:	6908                	ld	a0,16(a0)
    80004904:	00000097          	auipc	ra,0x0
    80004908:	22e080e7          	jalr	558(ra) # 80004b32 <pipewrite>
    8000490c:	8a2a                	mv	s4,a0
    8000490e:	a045                	j	800049ae <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004910:	02451783          	lh	a5,36(a0)
    80004914:	03079693          	slli	a3,a5,0x30
    80004918:	92c1                	srli	a3,a3,0x30
    8000491a:	4725                	li	a4,9
    8000491c:	0cd76263          	bltu	a4,a3,800049e0 <filewrite+0x12c>
    80004920:	0792                	slli	a5,a5,0x4
    80004922:	0001d717          	auipc	a4,0x1d
    80004926:	9f670713          	addi	a4,a4,-1546 # 80021318 <devsw>
    8000492a:	97ba                	add	a5,a5,a4
    8000492c:	679c                	ld	a5,8(a5)
    8000492e:	cbdd                	beqz	a5,800049e4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004930:	4505                	li	a0,1
    80004932:	9782                	jalr	a5
    80004934:	8a2a                	mv	s4,a0
    80004936:	a8a5                	j	800049ae <filewrite+0xfa>
    80004938:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000493c:	00000097          	auipc	ra,0x0
    80004940:	8b0080e7          	jalr	-1872(ra) # 800041ec <begin_op>
      ilock(f->ip);
    80004944:	01893503          	ld	a0,24(s2)
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	ece080e7          	jalr	-306(ra) # 80003816 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004950:	8762                	mv	a4,s8
    80004952:	02092683          	lw	a3,32(s2)
    80004956:	01598633          	add	a2,s3,s5
    8000495a:	4585                	li	a1,1
    8000495c:	01893503          	ld	a0,24(s2)
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	262080e7          	jalr	610(ra) # 80003bc2 <writei>
    80004968:	84aa                	mv	s1,a0
    8000496a:	00a05763          	blez	a0,80004978 <filewrite+0xc4>
        f->off += r;
    8000496e:	02092783          	lw	a5,32(s2)
    80004972:	9fa9                	addw	a5,a5,a0
    80004974:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004978:	01893503          	ld	a0,24(s2)
    8000497c:	fffff097          	auipc	ra,0xfffff
    80004980:	f5c080e7          	jalr	-164(ra) # 800038d8 <iunlock>
      end_op();
    80004984:	00000097          	auipc	ra,0x0
    80004988:	8e8080e7          	jalr	-1816(ra) # 8000426c <end_op>

      if(r != n1){
    8000498c:	009c1f63          	bne	s8,s1,800049aa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004990:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004994:	0149db63          	bge	s3,s4,800049aa <filewrite+0xf6>
      int n1 = n - i;
    80004998:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000499c:	84be                	mv	s1,a5
    8000499e:	2781                	sext.w	a5,a5
    800049a0:	f8fb5ce3          	bge	s6,a5,80004938 <filewrite+0x84>
    800049a4:	84de                	mv	s1,s7
    800049a6:	bf49                	j	80004938 <filewrite+0x84>
    int i = 0;
    800049a8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049aa:	013a1f63          	bne	s4,s3,800049c8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049ae:	8552                	mv	a0,s4
    800049b0:	60a6                	ld	ra,72(sp)
    800049b2:	6406                	ld	s0,64(sp)
    800049b4:	74e2                	ld	s1,56(sp)
    800049b6:	7942                	ld	s2,48(sp)
    800049b8:	79a2                	ld	s3,40(sp)
    800049ba:	7a02                	ld	s4,32(sp)
    800049bc:	6ae2                	ld	s5,24(sp)
    800049be:	6b42                	ld	s6,16(sp)
    800049c0:	6ba2                	ld	s7,8(sp)
    800049c2:	6c02                	ld	s8,0(sp)
    800049c4:	6161                	addi	sp,sp,80
    800049c6:	8082                	ret
    ret = (i == n ? n : -1);
    800049c8:	5a7d                	li	s4,-1
    800049ca:	b7d5                	j	800049ae <filewrite+0xfa>
    panic("filewrite");
    800049cc:	00004517          	auipc	a0,0x4
    800049d0:	e4c50513          	addi	a0,a0,-436 # 80008818 <syscalls+0x270>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	b56080e7          	jalr	-1194(ra) # 8000052a <panic>
    return -1;
    800049dc:	5a7d                	li	s4,-1
    800049de:	bfc1                	j	800049ae <filewrite+0xfa>
      return -1;
    800049e0:	5a7d                	li	s4,-1
    800049e2:	b7f1                	j	800049ae <filewrite+0xfa>
    800049e4:	5a7d                	li	s4,-1
    800049e6:	b7e1                	j	800049ae <filewrite+0xfa>

00000000800049e8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049e8:	7179                	addi	sp,sp,-48
    800049ea:	f406                	sd	ra,40(sp)
    800049ec:	f022                	sd	s0,32(sp)
    800049ee:	ec26                	sd	s1,24(sp)
    800049f0:	e84a                	sd	s2,16(sp)
    800049f2:	e44e                	sd	s3,8(sp)
    800049f4:	e052                	sd	s4,0(sp)
    800049f6:	1800                	addi	s0,sp,48
    800049f8:	84aa                	mv	s1,a0
    800049fa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049fc:	0005b023          	sd	zero,0(a1)
    80004a00:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	bf8080e7          	jalr	-1032(ra) # 800045fc <filealloc>
    80004a0c:	e088                	sd	a0,0(s1)
    80004a0e:	c551                	beqz	a0,80004a9a <pipealloc+0xb2>
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	bec080e7          	jalr	-1044(ra) # 800045fc <filealloc>
    80004a18:	00aa3023          	sd	a0,0(s4)
    80004a1c:	c92d                	beqz	a0,80004a8e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	0b4080e7          	jalr	180(ra) # 80000ad2 <kalloc>
    80004a26:	892a                	mv	s2,a0
    80004a28:	c125                	beqz	a0,80004a88 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a2a:	4985                	li	s3,1
    80004a2c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a30:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a34:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a38:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a3c:	00004597          	auipc	a1,0x4
    80004a40:	9e458593          	addi	a1,a1,-1564 # 80008420 <states.0+0x178>
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	0ee080e7          	jalr	238(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004a4c:	609c                	ld	a5,0(s1)
    80004a4e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a52:	609c                	ld	a5,0(s1)
    80004a54:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a58:	609c                	ld	a5,0(s1)
    80004a5a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a5e:	609c                	ld	a5,0(s1)
    80004a60:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a64:	000a3783          	ld	a5,0(s4)
    80004a68:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a6c:	000a3783          	ld	a5,0(s4)
    80004a70:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a74:	000a3783          	ld	a5,0(s4)
    80004a78:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a7c:	000a3783          	ld	a5,0(s4)
    80004a80:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a84:	4501                	li	a0,0
    80004a86:	a025                	j	80004aae <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a88:	6088                	ld	a0,0(s1)
    80004a8a:	e501                	bnez	a0,80004a92 <pipealloc+0xaa>
    80004a8c:	a039                	j	80004a9a <pipealloc+0xb2>
    80004a8e:	6088                	ld	a0,0(s1)
    80004a90:	c51d                	beqz	a0,80004abe <pipealloc+0xd6>
    fileclose(*f0);
    80004a92:	00000097          	auipc	ra,0x0
    80004a96:	c26080e7          	jalr	-986(ra) # 800046b8 <fileclose>
  if(*f1)
    80004a9a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a9e:	557d                	li	a0,-1
  if(*f1)
    80004aa0:	c799                	beqz	a5,80004aae <pipealloc+0xc6>
    fileclose(*f1);
    80004aa2:	853e                	mv	a0,a5
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	c14080e7          	jalr	-1004(ra) # 800046b8 <fileclose>
  return -1;
    80004aac:	557d                	li	a0,-1
}
    80004aae:	70a2                	ld	ra,40(sp)
    80004ab0:	7402                	ld	s0,32(sp)
    80004ab2:	64e2                	ld	s1,24(sp)
    80004ab4:	6942                	ld	s2,16(sp)
    80004ab6:	69a2                	ld	s3,8(sp)
    80004ab8:	6a02                	ld	s4,0(sp)
    80004aba:	6145                	addi	sp,sp,48
    80004abc:	8082                	ret
  return -1;
    80004abe:	557d                	li	a0,-1
    80004ac0:	b7fd                	j	80004aae <pipealloc+0xc6>

0000000080004ac2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ac2:	1101                	addi	sp,sp,-32
    80004ac4:	ec06                	sd	ra,24(sp)
    80004ac6:	e822                	sd	s0,16(sp)
    80004ac8:	e426                	sd	s1,8(sp)
    80004aca:	e04a                	sd	s2,0(sp)
    80004acc:	1000                	addi	s0,sp,32
    80004ace:	84aa                	mv	s1,a0
    80004ad0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	0f0080e7          	jalr	240(ra) # 80000bc2 <acquire>
  if(writable){
    80004ada:	02090d63          	beqz	s2,80004b14 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ade:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ae2:	21848513          	addi	a0,s1,536
    80004ae6:	ffffd097          	auipc	ra,0xffffd
    80004aea:	6ec080e7          	jalr	1772(ra) # 800021d2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004aee:	2204b783          	ld	a5,544(s1)
    80004af2:	eb95                	bnez	a5,80004b26 <pipeclose+0x64>
    release(&pi->lock);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	180080e7          	jalr	384(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004afe:	8526                	mv	a0,s1
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	ed6080e7          	jalr	-298(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004b08:	60e2                	ld	ra,24(sp)
    80004b0a:	6442                	ld	s0,16(sp)
    80004b0c:	64a2                	ld	s1,8(sp)
    80004b0e:	6902                	ld	s2,0(sp)
    80004b10:	6105                	addi	sp,sp,32
    80004b12:	8082                	ret
    pi->readopen = 0;
    80004b14:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b18:	21c48513          	addi	a0,s1,540
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	6b6080e7          	jalr	1718(ra) # 800021d2 <wakeup>
    80004b24:	b7e9                	j	80004aee <pipeclose+0x2c>
    release(&pi->lock);
    80004b26:	8526                	mv	a0,s1
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
}
    80004b30:	bfe1                	j	80004b08 <pipeclose+0x46>

0000000080004b32 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b32:	711d                	addi	sp,sp,-96
    80004b34:	ec86                	sd	ra,88(sp)
    80004b36:	e8a2                	sd	s0,80(sp)
    80004b38:	e4a6                	sd	s1,72(sp)
    80004b3a:	e0ca                	sd	s2,64(sp)
    80004b3c:	fc4e                	sd	s3,56(sp)
    80004b3e:	f852                	sd	s4,48(sp)
    80004b40:	f456                	sd	s5,40(sp)
    80004b42:	f05a                	sd	s6,32(sp)
    80004b44:	ec5e                	sd	s7,24(sp)
    80004b46:	e862                	sd	s8,16(sp)
    80004b48:	1080                	addi	s0,sp,96
    80004b4a:	84aa                	mv	s1,a0
    80004b4c:	8aae                	mv	s5,a1
    80004b4e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b50:	ffffd097          	auipc	ra,0xffffd
    80004b54:	e2e080e7          	jalr	-466(ra) # 8000197e <myproc>
    80004b58:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	066080e7          	jalr	102(ra) # 80000bc2 <acquire>
  while(i < n){
    80004b64:	0b405363          	blez	s4,80004c0a <pipewrite+0xd8>
  int i = 0;
    80004b68:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b6a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b6c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b70:	21c48b93          	addi	s7,s1,540
    80004b74:	a089                	j	80004bb6 <pipewrite+0x84>
      release(&pi->lock);
    80004b76:	8526                	mv	a0,s1
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	0fe080e7          	jalr	254(ra) # 80000c76 <release>
      return -1;
    80004b80:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b82:	854a                	mv	a0,s2
    80004b84:	60e6                	ld	ra,88(sp)
    80004b86:	6446                	ld	s0,80(sp)
    80004b88:	64a6                	ld	s1,72(sp)
    80004b8a:	6906                	ld	s2,64(sp)
    80004b8c:	79e2                	ld	s3,56(sp)
    80004b8e:	7a42                	ld	s4,48(sp)
    80004b90:	7aa2                	ld	s5,40(sp)
    80004b92:	7b02                	ld	s6,32(sp)
    80004b94:	6be2                	ld	s7,24(sp)
    80004b96:	6c42                	ld	s8,16(sp)
    80004b98:	6125                	addi	sp,sp,96
    80004b9a:	8082                	ret
      wakeup(&pi->nread);
    80004b9c:	8562                	mv	a0,s8
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	634080e7          	jalr	1588(ra) # 800021d2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ba6:	85a6                	mv	a1,s1
    80004ba8:	855e                	mv	a0,s7
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	49c080e7          	jalr	1180(ra) # 80002046 <sleep>
  while(i < n){
    80004bb2:	05495d63          	bge	s2,s4,80004c0c <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004bb6:	2204a783          	lw	a5,544(s1)
    80004bba:	dfd5                	beqz	a5,80004b76 <pipewrite+0x44>
    80004bbc:	0289a783          	lw	a5,40(s3)
    80004bc0:	fbdd                	bnez	a5,80004b76 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bc2:	2184a783          	lw	a5,536(s1)
    80004bc6:	21c4a703          	lw	a4,540(s1)
    80004bca:	2007879b          	addiw	a5,a5,512
    80004bce:	fcf707e3          	beq	a4,a5,80004b9c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bd2:	4685                	li	a3,1
    80004bd4:	01590633          	add	a2,s2,s5
    80004bd8:	faf40593          	addi	a1,s0,-81
    80004bdc:	0509b503          	ld	a0,80(s3)
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	aea080e7          	jalr	-1302(ra) # 800016ca <copyin>
    80004be8:	03650263          	beq	a0,s6,80004c0c <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bec:	21c4a783          	lw	a5,540(s1)
    80004bf0:	0017871b          	addiw	a4,a5,1
    80004bf4:	20e4ae23          	sw	a4,540(s1)
    80004bf8:	1ff7f793          	andi	a5,a5,511
    80004bfc:	97a6                	add	a5,a5,s1
    80004bfe:	faf44703          	lbu	a4,-81(s0)
    80004c02:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c06:	2905                	addiw	s2,s2,1
    80004c08:	b76d                	j	80004bb2 <pipewrite+0x80>
  int i = 0;
    80004c0a:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c0c:	21848513          	addi	a0,s1,536
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	5c2080e7          	jalr	1474(ra) # 800021d2 <wakeup>
  release(&pi->lock);
    80004c18:	8526                	mv	a0,s1
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	05c080e7          	jalr	92(ra) # 80000c76 <release>
  return i;
    80004c22:	b785                	j	80004b82 <pipewrite+0x50>

0000000080004c24 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c24:	715d                	addi	sp,sp,-80
    80004c26:	e486                	sd	ra,72(sp)
    80004c28:	e0a2                	sd	s0,64(sp)
    80004c2a:	fc26                	sd	s1,56(sp)
    80004c2c:	f84a                	sd	s2,48(sp)
    80004c2e:	f44e                	sd	s3,40(sp)
    80004c30:	f052                	sd	s4,32(sp)
    80004c32:	ec56                	sd	s5,24(sp)
    80004c34:	e85a                	sd	s6,16(sp)
    80004c36:	0880                	addi	s0,sp,80
    80004c38:	84aa                	mv	s1,a0
    80004c3a:	892e                	mv	s2,a1
    80004c3c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	d40080e7          	jalr	-704(ra) # 8000197e <myproc>
    80004c46:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	f78080e7          	jalr	-136(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c52:	2184a703          	lw	a4,536(s1)
    80004c56:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c5a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c5e:	02f71463          	bne	a4,a5,80004c86 <piperead+0x62>
    80004c62:	2244a783          	lw	a5,548(s1)
    80004c66:	c385                	beqz	a5,80004c86 <piperead+0x62>
    if(pr->killed){
    80004c68:	028a2783          	lw	a5,40(s4)
    80004c6c:	ebc1                	bnez	a5,80004cfc <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c6e:	85a6                	mv	a1,s1
    80004c70:	854e                	mv	a0,s3
    80004c72:	ffffd097          	auipc	ra,0xffffd
    80004c76:	3d4080e7          	jalr	980(ra) # 80002046 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c7a:	2184a703          	lw	a4,536(s1)
    80004c7e:	21c4a783          	lw	a5,540(s1)
    80004c82:	fef700e3          	beq	a4,a5,80004c62 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c86:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c88:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c8a:	05505363          	blez	s5,80004cd0 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004c8e:	2184a783          	lw	a5,536(s1)
    80004c92:	21c4a703          	lw	a4,540(s1)
    80004c96:	02f70d63          	beq	a4,a5,80004cd0 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c9a:	0017871b          	addiw	a4,a5,1
    80004c9e:	20e4ac23          	sw	a4,536(s1)
    80004ca2:	1ff7f793          	andi	a5,a5,511
    80004ca6:	97a6                	add	a5,a5,s1
    80004ca8:	0187c783          	lbu	a5,24(a5)
    80004cac:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cb0:	4685                	li	a3,1
    80004cb2:	fbf40613          	addi	a2,s0,-65
    80004cb6:	85ca                	mv	a1,s2
    80004cb8:	050a3503          	ld	a0,80(s4)
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	982080e7          	jalr	-1662(ra) # 8000163e <copyout>
    80004cc4:	01650663          	beq	a0,s6,80004cd0 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc8:	2985                	addiw	s3,s3,1
    80004cca:	0905                	addi	s2,s2,1
    80004ccc:	fd3a91e3          	bne	s5,s3,80004c8e <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cd0:	21c48513          	addi	a0,s1,540
    80004cd4:	ffffd097          	auipc	ra,0xffffd
    80004cd8:	4fe080e7          	jalr	1278(ra) # 800021d2 <wakeup>
  release(&pi->lock);
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	f98080e7          	jalr	-104(ra) # 80000c76 <release>
  return i;
}
    80004ce6:	854e                	mv	a0,s3
    80004ce8:	60a6                	ld	ra,72(sp)
    80004cea:	6406                	ld	s0,64(sp)
    80004cec:	74e2                	ld	s1,56(sp)
    80004cee:	7942                	ld	s2,48(sp)
    80004cf0:	79a2                	ld	s3,40(sp)
    80004cf2:	7a02                	ld	s4,32(sp)
    80004cf4:	6ae2                	ld	s5,24(sp)
    80004cf6:	6b42                	ld	s6,16(sp)
    80004cf8:	6161                	addi	sp,sp,80
    80004cfa:	8082                	ret
      release(&pi->lock);
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	f78080e7          	jalr	-136(ra) # 80000c76 <release>
      return -1;
    80004d06:	59fd                	li	s3,-1
    80004d08:	bff9                	j	80004ce6 <piperead+0xc2>

0000000080004d0a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d0a:	de010113          	addi	sp,sp,-544
    80004d0e:	20113c23          	sd	ra,536(sp)
    80004d12:	20813823          	sd	s0,528(sp)
    80004d16:	20913423          	sd	s1,520(sp)
    80004d1a:	21213023          	sd	s2,512(sp)
    80004d1e:	ffce                	sd	s3,504(sp)
    80004d20:	fbd2                	sd	s4,496(sp)
    80004d22:	f7d6                	sd	s5,488(sp)
    80004d24:	f3da                	sd	s6,480(sp)
    80004d26:	efde                	sd	s7,472(sp)
    80004d28:	ebe2                	sd	s8,464(sp)
    80004d2a:	e7e6                	sd	s9,456(sp)
    80004d2c:	e3ea                	sd	s10,448(sp)
    80004d2e:	ff6e                	sd	s11,440(sp)
    80004d30:	1400                	addi	s0,sp,544
    80004d32:	892a                	mv	s2,a0
    80004d34:	dea43423          	sd	a0,-536(s0)
    80004d38:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	c42080e7          	jalr	-958(ra) # 8000197e <myproc>
    80004d44:	84aa                	mv	s1,a0

  begin_op();
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	4a6080e7          	jalr	1190(ra) # 800041ec <begin_op>

  if((ip = namei(path)) == 0){
    80004d4e:	854a                	mv	a0,s2
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	27c080e7          	jalr	636(ra) # 80003fcc <namei>
    80004d58:	c93d                	beqz	a0,80004dce <exec+0xc4>
    80004d5a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	aba080e7          	jalr	-1350(ra) # 80003816 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d64:	04000713          	li	a4,64
    80004d68:	4681                	li	a3,0
    80004d6a:	e4840613          	addi	a2,s0,-440
    80004d6e:	4581                	li	a1,0
    80004d70:	8556                	mv	a0,s5
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	d58080e7          	jalr	-680(ra) # 80003aca <readi>
    80004d7a:	04000793          	li	a5,64
    80004d7e:	00f51a63          	bne	a0,a5,80004d92 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d82:	e4842703          	lw	a4,-440(s0)
    80004d86:	464c47b7          	lui	a5,0x464c4
    80004d8a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d8e:	04f70663          	beq	a4,a5,80004dda <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d92:	8556                	mv	a0,s5
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	ce4080e7          	jalr	-796(ra) # 80003a78 <iunlockput>
    end_op();
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	4d0080e7          	jalr	1232(ra) # 8000426c <end_op>
  }
  return -1;
    80004da4:	557d                	li	a0,-1
}
    80004da6:	21813083          	ld	ra,536(sp)
    80004daa:	21013403          	ld	s0,528(sp)
    80004dae:	20813483          	ld	s1,520(sp)
    80004db2:	20013903          	ld	s2,512(sp)
    80004db6:	79fe                	ld	s3,504(sp)
    80004db8:	7a5e                	ld	s4,496(sp)
    80004dba:	7abe                	ld	s5,488(sp)
    80004dbc:	7b1e                	ld	s6,480(sp)
    80004dbe:	6bfe                	ld	s7,472(sp)
    80004dc0:	6c5e                	ld	s8,464(sp)
    80004dc2:	6cbe                	ld	s9,456(sp)
    80004dc4:	6d1e                	ld	s10,448(sp)
    80004dc6:	7dfa                	ld	s11,440(sp)
    80004dc8:	22010113          	addi	sp,sp,544
    80004dcc:	8082                	ret
    end_op();
    80004dce:	fffff097          	auipc	ra,0xfffff
    80004dd2:	49e080e7          	jalr	1182(ra) # 8000426c <end_op>
    return -1;
    80004dd6:	557d                	li	a0,-1
    80004dd8:	b7f9                	j	80004da6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dda:	8526                	mv	a0,s1
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	c66080e7          	jalr	-922(ra) # 80001a42 <proc_pagetable>
    80004de4:	8b2a                	mv	s6,a0
    80004de6:	d555                	beqz	a0,80004d92 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de8:	e6842783          	lw	a5,-408(s0)
    80004dec:	e8045703          	lhu	a4,-384(s0)
    80004df0:	c735                	beqz	a4,80004e5c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004df2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004df8:	6a05                	lui	s4,0x1
    80004dfa:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004dfe:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e02:	6d85                	lui	s11,0x1
    80004e04:	7d7d                	lui	s10,0xfffff
    80004e06:	ac1d                	j	8000503c <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e08:	00004517          	auipc	a0,0x4
    80004e0c:	a2050513          	addi	a0,a0,-1504 # 80008828 <syscalls+0x280>
    80004e10:	ffffb097          	auipc	ra,0xffffb
    80004e14:	71a080e7          	jalr	1818(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e18:	874a                	mv	a4,s2
    80004e1a:	009c86bb          	addw	a3,s9,s1
    80004e1e:	4581                	li	a1,0
    80004e20:	8556                	mv	a0,s5
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	ca8080e7          	jalr	-856(ra) # 80003aca <readi>
    80004e2a:	2501                	sext.w	a0,a0
    80004e2c:	1aa91863          	bne	s2,a0,80004fdc <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e30:	009d84bb          	addw	s1,s11,s1
    80004e34:	013d09bb          	addw	s3,s10,s3
    80004e38:	1f74f263          	bgeu	s1,s7,8000501c <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e3c:	02049593          	slli	a1,s1,0x20
    80004e40:	9181                	srli	a1,a1,0x20
    80004e42:	95e2                	add	a1,a1,s8
    80004e44:	855a                	mv	a0,s6
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	206080e7          	jalr	518(ra) # 8000104c <walkaddr>
    80004e4e:	862a                	mv	a2,a0
    if(pa == 0)
    80004e50:	dd45                	beqz	a0,80004e08 <exec+0xfe>
      n = PGSIZE;
    80004e52:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e54:	fd49f2e3          	bgeu	s3,s4,80004e18 <exec+0x10e>
      n = sz - i;
    80004e58:	894e                	mv	s2,s3
    80004e5a:	bf7d                	j	80004e18 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e5c:	4481                	li	s1,0
  iunlockput(ip);
    80004e5e:	8556                	mv	a0,s5
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	c18080e7          	jalr	-1000(ra) # 80003a78 <iunlockput>
  end_op();
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	404080e7          	jalr	1028(ra) # 8000426c <end_op>
  p = myproc();
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	b0e080e7          	jalr	-1266(ra) # 8000197e <myproc>
    80004e78:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e7a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e7e:	6785                	lui	a5,0x1
    80004e80:	17fd                	addi	a5,a5,-1
    80004e82:	94be                	add	s1,s1,a5
    80004e84:	77fd                	lui	a5,0xfffff
    80004e86:	8fe5                	and	a5,a5,s1
    80004e88:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e8c:	6609                	lui	a2,0x2
    80004e8e:	963e                	add	a2,a2,a5
    80004e90:	85be                	mv	a1,a5
    80004e92:	855a                	mv	a0,s6
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	55a080e7          	jalr	1370(ra) # 800013ee <uvmalloc>
    80004e9c:	8c2a                	mv	s8,a0
  ip = 0;
    80004e9e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ea0:	12050e63          	beqz	a0,80004fdc <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ea4:	75f9                	lui	a1,0xffffe
    80004ea6:	95aa                	add	a1,a1,a0
    80004ea8:	855a                	mv	a0,s6
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	762080e7          	jalr	1890(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004eb2:	7afd                	lui	s5,0xfffff
    80004eb4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eb6:	df043783          	ld	a5,-528(s0)
    80004eba:	6388                	ld	a0,0(a5)
    80004ebc:	c925                	beqz	a0,80004f2c <exec+0x222>
    80004ebe:	e8840993          	addi	s3,s0,-376
    80004ec2:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ec6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ec8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	f78080e7          	jalr	-136(ra) # 80000e42 <strlen>
    80004ed2:	0015079b          	addiw	a5,a0,1
    80004ed6:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eda:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ede:	13596363          	bltu	s2,s5,80005004 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ee2:	df043d83          	ld	s11,-528(s0)
    80004ee6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004eea:	8552                	mv	a0,s4
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	f56080e7          	jalr	-170(ra) # 80000e42 <strlen>
    80004ef4:	0015069b          	addiw	a3,a0,1
    80004ef8:	8652                	mv	a2,s4
    80004efa:	85ca                	mv	a1,s2
    80004efc:	855a                	mv	a0,s6
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	740080e7          	jalr	1856(ra) # 8000163e <copyout>
    80004f06:	10054363          	bltz	a0,8000500c <exec+0x302>
    ustack[argc] = sp;
    80004f0a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f0e:	0485                	addi	s1,s1,1
    80004f10:	008d8793          	addi	a5,s11,8
    80004f14:	def43823          	sd	a5,-528(s0)
    80004f18:	008db503          	ld	a0,8(s11)
    80004f1c:	c911                	beqz	a0,80004f30 <exec+0x226>
    if(argc >= MAXARG)
    80004f1e:	09a1                	addi	s3,s3,8
    80004f20:	fb3c95e3          	bne	s9,s3,80004eca <exec+0x1c0>
  sz = sz1;
    80004f24:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f28:	4a81                	li	s5,0
    80004f2a:	a84d                	j	80004fdc <exec+0x2d2>
  sp = sz;
    80004f2c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f2e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f30:	00349793          	slli	a5,s1,0x3
    80004f34:	f9040713          	addi	a4,s0,-112
    80004f38:	97ba                	add	a5,a5,a4
    80004f3a:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f3e:	00148693          	addi	a3,s1,1
    80004f42:	068e                	slli	a3,a3,0x3
    80004f44:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f48:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f4c:	01597663          	bgeu	s2,s5,80004f58 <exec+0x24e>
  sz = sz1;
    80004f50:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f54:	4a81                	li	s5,0
    80004f56:	a059                	j	80004fdc <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f58:	e8840613          	addi	a2,s0,-376
    80004f5c:	85ca                	mv	a1,s2
    80004f5e:	855a                	mv	a0,s6
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	6de080e7          	jalr	1758(ra) # 8000163e <copyout>
    80004f68:	0a054663          	bltz	a0,80005014 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f6c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f70:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f74:	de843783          	ld	a5,-536(s0)
    80004f78:	0007c703          	lbu	a4,0(a5)
    80004f7c:	cf11                	beqz	a4,80004f98 <exec+0x28e>
    80004f7e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f80:	02f00693          	li	a3,47
    80004f84:	a039                	j	80004f92 <exec+0x288>
      last = s+1;
    80004f86:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f8a:	0785                	addi	a5,a5,1
    80004f8c:	fff7c703          	lbu	a4,-1(a5)
    80004f90:	c701                	beqz	a4,80004f98 <exec+0x28e>
    if(*s == '/')
    80004f92:	fed71ce3          	bne	a4,a3,80004f8a <exec+0x280>
    80004f96:	bfc5                	j	80004f86 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f98:	4641                	li	a2,16
    80004f9a:	de843583          	ld	a1,-536(s0)
    80004f9e:	158b8513          	addi	a0,s7,344
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	e6e080e7          	jalr	-402(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004faa:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fae:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004fb2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fb6:	058bb783          	ld	a5,88(s7)
    80004fba:	e6043703          	ld	a4,-416(s0)
    80004fbe:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fc0:	058bb783          	ld	a5,88(s7)
    80004fc4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fc8:	85ea                	mv	a1,s10
    80004fca:	ffffd097          	auipc	ra,0xffffd
    80004fce:	b14080e7          	jalr	-1260(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fd2:	0004851b          	sext.w	a0,s1
    80004fd6:	bbc1                	j	80004da6 <exec+0x9c>
    80004fd8:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fdc:	df843583          	ld	a1,-520(s0)
    80004fe0:	855a                	mv	a0,s6
    80004fe2:	ffffd097          	auipc	ra,0xffffd
    80004fe6:	afc080e7          	jalr	-1284(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80004fea:	da0a94e3          	bnez	s5,80004d92 <exec+0x88>
  return -1;
    80004fee:	557d                	li	a0,-1
    80004ff0:	bb5d                	j	80004da6 <exec+0x9c>
    80004ff2:	de943c23          	sd	s1,-520(s0)
    80004ff6:	b7dd                	j	80004fdc <exec+0x2d2>
    80004ff8:	de943c23          	sd	s1,-520(s0)
    80004ffc:	b7c5                	j	80004fdc <exec+0x2d2>
    80004ffe:	de943c23          	sd	s1,-520(s0)
    80005002:	bfe9                	j	80004fdc <exec+0x2d2>
  sz = sz1;
    80005004:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005008:	4a81                	li	s5,0
    8000500a:	bfc9                	j	80004fdc <exec+0x2d2>
  sz = sz1;
    8000500c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005010:	4a81                	li	s5,0
    80005012:	b7e9                	j	80004fdc <exec+0x2d2>
  sz = sz1;
    80005014:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005018:	4a81                	li	s5,0
    8000501a:	b7c9                	j	80004fdc <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000501c:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005020:	e0843783          	ld	a5,-504(s0)
    80005024:	0017869b          	addiw	a3,a5,1
    80005028:	e0d43423          	sd	a3,-504(s0)
    8000502c:	e0043783          	ld	a5,-512(s0)
    80005030:	0387879b          	addiw	a5,a5,56
    80005034:	e8045703          	lhu	a4,-384(s0)
    80005038:	e2e6d3e3          	bge	a3,a4,80004e5e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000503c:	2781                	sext.w	a5,a5
    8000503e:	e0f43023          	sd	a5,-512(s0)
    80005042:	03800713          	li	a4,56
    80005046:	86be                	mv	a3,a5
    80005048:	e1040613          	addi	a2,s0,-496
    8000504c:	4581                	li	a1,0
    8000504e:	8556                	mv	a0,s5
    80005050:	fffff097          	auipc	ra,0xfffff
    80005054:	a7a080e7          	jalr	-1414(ra) # 80003aca <readi>
    80005058:	03800793          	li	a5,56
    8000505c:	f6f51ee3          	bne	a0,a5,80004fd8 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005060:	e1042783          	lw	a5,-496(s0)
    80005064:	4705                	li	a4,1
    80005066:	fae79de3          	bne	a5,a4,80005020 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000506a:	e3843603          	ld	a2,-456(s0)
    8000506e:	e3043783          	ld	a5,-464(s0)
    80005072:	f8f660e3          	bltu	a2,a5,80004ff2 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005076:	e2043783          	ld	a5,-480(s0)
    8000507a:	963e                	add	a2,a2,a5
    8000507c:	f6f66ee3          	bltu	a2,a5,80004ff8 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005080:	85a6                	mv	a1,s1
    80005082:	855a                	mv	a0,s6
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	36a080e7          	jalr	874(ra) # 800013ee <uvmalloc>
    8000508c:	dea43c23          	sd	a0,-520(s0)
    80005090:	d53d                	beqz	a0,80004ffe <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005092:	e2043c03          	ld	s8,-480(s0)
    80005096:	de043783          	ld	a5,-544(s0)
    8000509a:	00fc77b3          	and	a5,s8,a5
    8000509e:	ff9d                	bnez	a5,80004fdc <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050a0:	e1842c83          	lw	s9,-488(s0)
    800050a4:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050a8:	f60b8ae3          	beqz	s7,8000501c <exec+0x312>
    800050ac:	89de                	mv	s3,s7
    800050ae:	4481                	li	s1,0
    800050b0:	b371                	j	80004e3c <exec+0x132>

00000000800050b2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050b2:	7179                	addi	sp,sp,-48
    800050b4:	f406                	sd	ra,40(sp)
    800050b6:	f022                	sd	s0,32(sp)
    800050b8:	ec26                	sd	s1,24(sp)
    800050ba:	e84a                	sd	s2,16(sp)
    800050bc:	1800                	addi	s0,sp,48
    800050be:	892e                	mv	s2,a1
    800050c0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050c2:	fdc40593          	addi	a1,s0,-36
    800050c6:	ffffe097          	auipc	ra,0xffffe
    800050ca:	9dc080e7          	jalr	-1572(ra) # 80002aa2 <argint>
    800050ce:	04054063          	bltz	a0,8000510e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050d2:	fdc42703          	lw	a4,-36(s0)
    800050d6:	47bd                	li	a5,15
    800050d8:	02e7ed63          	bltu	a5,a4,80005112 <argfd+0x60>
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	8a2080e7          	jalr	-1886(ra) # 8000197e <myproc>
    800050e4:	fdc42703          	lw	a4,-36(s0)
    800050e8:	01a70793          	addi	a5,a4,26
    800050ec:	078e                	slli	a5,a5,0x3
    800050ee:	953e                	add	a0,a0,a5
    800050f0:	611c                	ld	a5,0(a0)
    800050f2:	c395                	beqz	a5,80005116 <argfd+0x64>
    return -1;
  if(pfd)
    800050f4:	00090463          	beqz	s2,800050fc <argfd+0x4a>
    *pfd = fd;
    800050f8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050fc:	4501                	li	a0,0
  if(pf)
    800050fe:	c091                	beqz	s1,80005102 <argfd+0x50>
    *pf = f;
    80005100:	e09c                	sd	a5,0(s1)
}
    80005102:	70a2                	ld	ra,40(sp)
    80005104:	7402                	ld	s0,32(sp)
    80005106:	64e2                	ld	s1,24(sp)
    80005108:	6942                	ld	s2,16(sp)
    8000510a:	6145                	addi	sp,sp,48
    8000510c:	8082                	ret
    return -1;
    8000510e:	557d                	li	a0,-1
    80005110:	bfcd                	j	80005102 <argfd+0x50>
    return -1;
    80005112:	557d                	li	a0,-1
    80005114:	b7fd                	j	80005102 <argfd+0x50>
    80005116:	557d                	li	a0,-1
    80005118:	b7ed                	j	80005102 <argfd+0x50>

000000008000511a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000511a:	1101                	addi	sp,sp,-32
    8000511c:	ec06                	sd	ra,24(sp)
    8000511e:	e822                	sd	s0,16(sp)
    80005120:	e426                	sd	s1,8(sp)
    80005122:	1000                	addi	s0,sp,32
    80005124:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005126:	ffffd097          	auipc	ra,0xffffd
    8000512a:	858080e7          	jalr	-1960(ra) # 8000197e <myproc>
    8000512e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005130:	0d050793          	addi	a5,a0,208
    80005134:	4501                	li	a0,0
    80005136:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005138:	6398                	ld	a4,0(a5)
    8000513a:	cb19                	beqz	a4,80005150 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000513c:	2505                	addiw	a0,a0,1
    8000513e:	07a1                	addi	a5,a5,8
    80005140:	fed51ce3          	bne	a0,a3,80005138 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005144:	557d                	li	a0,-1
}
    80005146:	60e2                	ld	ra,24(sp)
    80005148:	6442                	ld	s0,16(sp)
    8000514a:	64a2                	ld	s1,8(sp)
    8000514c:	6105                	addi	sp,sp,32
    8000514e:	8082                	ret
      p->ofile[fd] = f;
    80005150:	01a50793          	addi	a5,a0,26
    80005154:	078e                	slli	a5,a5,0x3
    80005156:	963e                	add	a2,a2,a5
    80005158:	e204                	sd	s1,0(a2)
      return fd;
    8000515a:	b7f5                	j	80005146 <fdalloc+0x2c>

000000008000515c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000515c:	715d                	addi	sp,sp,-80
    8000515e:	e486                	sd	ra,72(sp)
    80005160:	e0a2                	sd	s0,64(sp)
    80005162:	fc26                	sd	s1,56(sp)
    80005164:	f84a                	sd	s2,48(sp)
    80005166:	f44e                	sd	s3,40(sp)
    80005168:	f052                	sd	s4,32(sp)
    8000516a:	ec56                	sd	s5,24(sp)
    8000516c:	0880                	addi	s0,sp,80
    8000516e:	89ae                	mv	s3,a1
    80005170:	8ab2                	mv	s5,a2
    80005172:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005174:	fb040593          	addi	a1,s0,-80
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	e72080e7          	jalr	-398(ra) # 80003fea <nameiparent>
    80005180:	892a                	mv	s2,a0
    80005182:	12050e63          	beqz	a0,800052be <create+0x162>
    return 0;

  ilock(dp);
    80005186:	ffffe097          	auipc	ra,0xffffe
    8000518a:	690080e7          	jalr	1680(ra) # 80003816 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000518e:	4601                	li	a2,0
    80005190:	fb040593          	addi	a1,s0,-80
    80005194:	854a                	mv	a0,s2
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	b64080e7          	jalr	-1180(ra) # 80003cfa <dirlookup>
    8000519e:	84aa                	mv	s1,a0
    800051a0:	c921                	beqz	a0,800051f0 <create+0x94>
    iunlockput(dp);
    800051a2:	854a                	mv	a0,s2
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	8d4080e7          	jalr	-1836(ra) # 80003a78 <iunlockput>
    ilock(ip);
    800051ac:	8526                	mv	a0,s1
    800051ae:	ffffe097          	auipc	ra,0xffffe
    800051b2:	668080e7          	jalr	1640(ra) # 80003816 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051b6:	2981                	sext.w	s3,s3
    800051b8:	4789                	li	a5,2
    800051ba:	02f99463          	bne	s3,a5,800051e2 <create+0x86>
    800051be:	0444d783          	lhu	a5,68(s1)
    800051c2:	37f9                	addiw	a5,a5,-2
    800051c4:	17c2                	slli	a5,a5,0x30
    800051c6:	93c1                	srli	a5,a5,0x30
    800051c8:	4705                	li	a4,1
    800051ca:	00f76c63          	bltu	a4,a5,800051e2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051ce:	8526                	mv	a0,s1
    800051d0:	60a6                	ld	ra,72(sp)
    800051d2:	6406                	ld	s0,64(sp)
    800051d4:	74e2                	ld	s1,56(sp)
    800051d6:	7942                	ld	s2,48(sp)
    800051d8:	79a2                	ld	s3,40(sp)
    800051da:	7a02                	ld	s4,32(sp)
    800051dc:	6ae2                	ld	s5,24(sp)
    800051de:	6161                	addi	sp,sp,80
    800051e0:	8082                	ret
    iunlockput(ip);
    800051e2:	8526                	mv	a0,s1
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	894080e7          	jalr	-1900(ra) # 80003a78 <iunlockput>
    return 0;
    800051ec:	4481                	li	s1,0
    800051ee:	b7c5                	j	800051ce <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051f0:	85ce                	mv	a1,s3
    800051f2:	00092503          	lw	a0,0(s2)
    800051f6:	ffffe097          	auipc	ra,0xffffe
    800051fa:	488080e7          	jalr	1160(ra) # 8000367e <ialloc>
    800051fe:	84aa                	mv	s1,a0
    80005200:	c521                	beqz	a0,80005248 <create+0xec>
  ilock(ip);
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	614080e7          	jalr	1556(ra) # 80003816 <ilock>
  ip->major = major;
    8000520a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000520e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005212:	4a05                	li	s4,1
    80005214:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	532080e7          	jalr	1330(ra) # 8000374c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005222:	2981                	sext.w	s3,s3
    80005224:	03498a63          	beq	s3,s4,80005258 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005228:	40d0                	lw	a2,4(s1)
    8000522a:	fb040593          	addi	a1,s0,-80
    8000522e:	854a                	mv	a0,s2
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	cda080e7          	jalr	-806(ra) # 80003f0a <dirlink>
    80005238:	06054b63          	bltz	a0,800052ae <create+0x152>
  iunlockput(dp);
    8000523c:	854a                	mv	a0,s2
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	83a080e7          	jalr	-1990(ra) # 80003a78 <iunlockput>
  return ip;
    80005246:	b761                	j	800051ce <create+0x72>
    panic("create: ialloc");
    80005248:	00003517          	auipc	a0,0x3
    8000524c:	60050513          	addi	a0,a0,1536 # 80008848 <syscalls+0x2a0>
    80005250:	ffffb097          	auipc	ra,0xffffb
    80005254:	2da080e7          	jalr	730(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005258:	04a95783          	lhu	a5,74(s2)
    8000525c:	2785                	addiw	a5,a5,1
    8000525e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005262:	854a                	mv	a0,s2
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	4e8080e7          	jalr	1256(ra) # 8000374c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000526c:	40d0                	lw	a2,4(s1)
    8000526e:	00003597          	auipc	a1,0x3
    80005272:	5ea58593          	addi	a1,a1,1514 # 80008858 <syscalls+0x2b0>
    80005276:	8526                	mv	a0,s1
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	c92080e7          	jalr	-878(ra) # 80003f0a <dirlink>
    80005280:	00054f63          	bltz	a0,8000529e <create+0x142>
    80005284:	00492603          	lw	a2,4(s2)
    80005288:	00003597          	auipc	a1,0x3
    8000528c:	5d858593          	addi	a1,a1,1496 # 80008860 <syscalls+0x2b8>
    80005290:	8526                	mv	a0,s1
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	c78080e7          	jalr	-904(ra) # 80003f0a <dirlink>
    8000529a:	f80557e3          	bgez	a0,80005228 <create+0xcc>
      panic("create dots");
    8000529e:	00003517          	auipc	a0,0x3
    800052a2:	5ca50513          	addi	a0,a0,1482 # 80008868 <syscalls+0x2c0>
    800052a6:	ffffb097          	auipc	ra,0xffffb
    800052aa:	284080e7          	jalr	644(ra) # 8000052a <panic>
    panic("create: dirlink");
    800052ae:	00003517          	auipc	a0,0x3
    800052b2:	5ca50513          	addi	a0,a0,1482 # 80008878 <syscalls+0x2d0>
    800052b6:	ffffb097          	auipc	ra,0xffffb
    800052ba:	274080e7          	jalr	628(ra) # 8000052a <panic>
    return 0;
    800052be:	84aa                	mv	s1,a0
    800052c0:	b739                	j	800051ce <create+0x72>

00000000800052c2 <sys_dup>:
{
    800052c2:	7179                	addi	sp,sp,-48
    800052c4:	f406                	sd	ra,40(sp)
    800052c6:	f022                	sd	s0,32(sp)
    800052c8:	ec26                	sd	s1,24(sp)
    800052ca:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052cc:	fd840613          	addi	a2,s0,-40
    800052d0:	4581                	li	a1,0
    800052d2:	4501                	li	a0,0
    800052d4:	00000097          	auipc	ra,0x0
    800052d8:	dde080e7          	jalr	-546(ra) # 800050b2 <argfd>
    return -1;
    800052dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052de:	02054363          	bltz	a0,80005304 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052e2:	fd843503          	ld	a0,-40(s0)
    800052e6:	00000097          	auipc	ra,0x0
    800052ea:	e34080e7          	jalr	-460(ra) # 8000511a <fdalloc>
    800052ee:	84aa                	mv	s1,a0
    return -1;
    800052f0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052f2:	00054963          	bltz	a0,80005304 <sys_dup+0x42>
  filedup(f);
    800052f6:	fd843503          	ld	a0,-40(s0)
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	36c080e7          	jalr	876(ra) # 80004666 <filedup>
  return fd;
    80005302:	87a6                	mv	a5,s1
}
    80005304:	853e                	mv	a0,a5
    80005306:	70a2                	ld	ra,40(sp)
    80005308:	7402                	ld	s0,32(sp)
    8000530a:	64e2                	ld	s1,24(sp)
    8000530c:	6145                	addi	sp,sp,48
    8000530e:	8082                	ret

0000000080005310 <sys_read>:
{
    80005310:	7179                	addi	sp,sp,-48
    80005312:	f406                	sd	ra,40(sp)
    80005314:	f022                	sd	s0,32(sp)
    80005316:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005318:	fe840613          	addi	a2,s0,-24
    8000531c:	4581                	li	a1,0
    8000531e:	4501                	li	a0,0
    80005320:	00000097          	auipc	ra,0x0
    80005324:	d92080e7          	jalr	-622(ra) # 800050b2 <argfd>
    return -1;
    80005328:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532a:	04054163          	bltz	a0,8000536c <sys_read+0x5c>
    8000532e:	fe440593          	addi	a1,s0,-28
    80005332:	4509                	li	a0,2
    80005334:	ffffd097          	auipc	ra,0xffffd
    80005338:	76e080e7          	jalr	1902(ra) # 80002aa2 <argint>
    return -1;
    8000533c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533e:	02054763          	bltz	a0,8000536c <sys_read+0x5c>
    80005342:	fd840593          	addi	a1,s0,-40
    80005346:	4505                	li	a0,1
    80005348:	ffffd097          	auipc	ra,0xffffd
    8000534c:	77c080e7          	jalr	1916(ra) # 80002ac4 <argaddr>
    return -1;
    80005350:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005352:	00054d63          	bltz	a0,8000536c <sys_read+0x5c>
  return fileread(f, p, n);
    80005356:	fe442603          	lw	a2,-28(s0)
    8000535a:	fd843583          	ld	a1,-40(s0)
    8000535e:	fe843503          	ld	a0,-24(s0)
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	490080e7          	jalr	1168(ra) # 800047f2 <fileread>
    8000536a:	87aa                	mv	a5,a0
}
    8000536c:	853e                	mv	a0,a5
    8000536e:	70a2                	ld	ra,40(sp)
    80005370:	7402                	ld	s0,32(sp)
    80005372:	6145                	addi	sp,sp,48
    80005374:	8082                	ret

0000000080005376 <sys_write>:
{
    80005376:	7179                	addi	sp,sp,-48
    80005378:	f406                	sd	ra,40(sp)
    8000537a:	f022                	sd	s0,32(sp)
    8000537c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537e:	fe840613          	addi	a2,s0,-24
    80005382:	4581                	li	a1,0
    80005384:	4501                	li	a0,0
    80005386:	00000097          	auipc	ra,0x0
    8000538a:	d2c080e7          	jalr	-724(ra) # 800050b2 <argfd>
    return -1;
    8000538e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005390:	04054163          	bltz	a0,800053d2 <sys_write+0x5c>
    80005394:	fe440593          	addi	a1,s0,-28
    80005398:	4509                	li	a0,2
    8000539a:	ffffd097          	auipc	ra,0xffffd
    8000539e:	708080e7          	jalr	1800(ra) # 80002aa2 <argint>
    return -1;
    800053a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a4:	02054763          	bltz	a0,800053d2 <sys_write+0x5c>
    800053a8:	fd840593          	addi	a1,s0,-40
    800053ac:	4505                	li	a0,1
    800053ae:	ffffd097          	auipc	ra,0xffffd
    800053b2:	716080e7          	jalr	1814(ra) # 80002ac4 <argaddr>
    return -1;
    800053b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b8:	00054d63          	bltz	a0,800053d2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053bc:	fe442603          	lw	a2,-28(s0)
    800053c0:	fd843583          	ld	a1,-40(s0)
    800053c4:	fe843503          	ld	a0,-24(s0)
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	4ec080e7          	jalr	1260(ra) # 800048b4 <filewrite>
    800053d0:	87aa                	mv	a5,a0
}
    800053d2:	853e                	mv	a0,a5
    800053d4:	70a2                	ld	ra,40(sp)
    800053d6:	7402                	ld	s0,32(sp)
    800053d8:	6145                	addi	sp,sp,48
    800053da:	8082                	ret

00000000800053dc <sys_close>:
{
    800053dc:	1101                	addi	sp,sp,-32
    800053de:	ec06                	sd	ra,24(sp)
    800053e0:	e822                	sd	s0,16(sp)
    800053e2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053e4:	fe040613          	addi	a2,s0,-32
    800053e8:	fec40593          	addi	a1,s0,-20
    800053ec:	4501                	li	a0,0
    800053ee:	00000097          	auipc	ra,0x0
    800053f2:	cc4080e7          	jalr	-828(ra) # 800050b2 <argfd>
    return -1;
    800053f6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053f8:	02054463          	bltz	a0,80005420 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053fc:	ffffc097          	auipc	ra,0xffffc
    80005400:	582080e7          	jalr	1410(ra) # 8000197e <myproc>
    80005404:	fec42783          	lw	a5,-20(s0)
    80005408:	07e9                	addi	a5,a5,26
    8000540a:	078e                	slli	a5,a5,0x3
    8000540c:	97aa                	add	a5,a5,a0
    8000540e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005412:	fe043503          	ld	a0,-32(s0)
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	2a2080e7          	jalr	674(ra) # 800046b8 <fileclose>
  return 0;
    8000541e:	4781                	li	a5,0
}
    80005420:	853e                	mv	a0,a5
    80005422:	60e2                	ld	ra,24(sp)
    80005424:	6442                	ld	s0,16(sp)
    80005426:	6105                	addi	sp,sp,32
    80005428:	8082                	ret

000000008000542a <sys_fstat>:
{
    8000542a:	1101                	addi	sp,sp,-32
    8000542c:	ec06                	sd	ra,24(sp)
    8000542e:	e822                	sd	s0,16(sp)
    80005430:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005432:	fe840613          	addi	a2,s0,-24
    80005436:	4581                	li	a1,0
    80005438:	4501                	li	a0,0
    8000543a:	00000097          	auipc	ra,0x0
    8000543e:	c78080e7          	jalr	-904(ra) # 800050b2 <argfd>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005444:	02054563          	bltz	a0,8000546e <sys_fstat+0x44>
    80005448:	fe040593          	addi	a1,s0,-32
    8000544c:	4505                	li	a0,1
    8000544e:	ffffd097          	auipc	ra,0xffffd
    80005452:	676080e7          	jalr	1654(ra) # 80002ac4 <argaddr>
    return -1;
    80005456:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005458:	00054b63          	bltz	a0,8000546e <sys_fstat+0x44>
  return filestat(f, st);
    8000545c:	fe043583          	ld	a1,-32(s0)
    80005460:	fe843503          	ld	a0,-24(s0)
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	31c080e7          	jalr	796(ra) # 80004780 <filestat>
    8000546c:	87aa                	mv	a5,a0
}
    8000546e:	853e                	mv	a0,a5
    80005470:	60e2                	ld	ra,24(sp)
    80005472:	6442                	ld	s0,16(sp)
    80005474:	6105                	addi	sp,sp,32
    80005476:	8082                	ret

0000000080005478 <sys_link>:
{
    80005478:	7169                	addi	sp,sp,-304
    8000547a:	f606                	sd	ra,296(sp)
    8000547c:	f222                	sd	s0,288(sp)
    8000547e:	ee26                	sd	s1,280(sp)
    80005480:	ea4a                	sd	s2,272(sp)
    80005482:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005484:	08000613          	li	a2,128
    80005488:	ed040593          	addi	a1,s0,-304
    8000548c:	4501                	li	a0,0
    8000548e:	ffffd097          	auipc	ra,0xffffd
    80005492:	658080e7          	jalr	1624(ra) # 80002ae6 <argstr>
    return -1;
    80005496:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005498:	10054e63          	bltz	a0,800055b4 <sys_link+0x13c>
    8000549c:	08000613          	li	a2,128
    800054a0:	f5040593          	addi	a1,s0,-176
    800054a4:	4505                	li	a0,1
    800054a6:	ffffd097          	auipc	ra,0xffffd
    800054aa:	640080e7          	jalr	1600(ra) # 80002ae6 <argstr>
    return -1;
    800054ae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b0:	10054263          	bltz	a0,800055b4 <sys_link+0x13c>
  begin_op();
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	d38080e7          	jalr	-712(ra) # 800041ec <begin_op>
  if((ip = namei(old)) == 0){
    800054bc:	ed040513          	addi	a0,s0,-304
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	b0c080e7          	jalr	-1268(ra) # 80003fcc <namei>
    800054c8:	84aa                	mv	s1,a0
    800054ca:	c551                	beqz	a0,80005556 <sys_link+0xde>
  ilock(ip);
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	34a080e7          	jalr	842(ra) # 80003816 <ilock>
  if(ip->type == T_DIR){
    800054d4:	04449703          	lh	a4,68(s1)
    800054d8:	4785                	li	a5,1
    800054da:	08f70463          	beq	a4,a5,80005562 <sys_link+0xea>
  ip->nlink++;
    800054de:	04a4d783          	lhu	a5,74(s1)
    800054e2:	2785                	addiw	a5,a5,1
    800054e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	262080e7          	jalr	610(ra) # 8000374c <iupdate>
  iunlock(ip);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	3e4080e7          	jalr	996(ra) # 800038d8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054fc:	fd040593          	addi	a1,s0,-48
    80005500:	f5040513          	addi	a0,s0,-176
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	ae6080e7          	jalr	-1306(ra) # 80003fea <nameiparent>
    8000550c:	892a                	mv	s2,a0
    8000550e:	c935                	beqz	a0,80005582 <sys_link+0x10a>
  ilock(dp);
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	306080e7          	jalr	774(ra) # 80003816 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005518:	00092703          	lw	a4,0(s2)
    8000551c:	409c                	lw	a5,0(s1)
    8000551e:	04f71d63          	bne	a4,a5,80005578 <sys_link+0x100>
    80005522:	40d0                	lw	a2,4(s1)
    80005524:	fd040593          	addi	a1,s0,-48
    80005528:	854a                	mv	a0,s2
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	9e0080e7          	jalr	-1568(ra) # 80003f0a <dirlink>
    80005532:	04054363          	bltz	a0,80005578 <sys_link+0x100>
  iunlockput(dp);
    80005536:	854a                	mv	a0,s2
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	540080e7          	jalr	1344(ra) # 80003a78 <iunlockput>
  iput(ip);
    80005540:	8526                	mv	a0,s1
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	48e080e7          	jalr	1166(ra) # 800039d0 <iput>
  end_op();
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	d22080e7          	jalr	-734(ra) # 8000426c <end_op>
  return 0;
    80005552:	4781                	li	a5,0
    80005554:	a085                	j	800055b4 <sys_link+0x13c>
    end_op();
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	d16080e7          	jalr	-746(ra) # 8000426c <end_op>
    return -1;
    8000555e:	57fd                	li	a5,-1
    80005560:	a891                	j	800055b4 <sys_link+0x13c>
    iunlockput(ip);
    80005562:	8526                	mv	a0,s1
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	514080e7          	jalr	1300(ra) # 80003a78 <iunlockput>
    end_op();
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	d00080e7          	jalr	-768(ra) # 8000426c <end_op>
    return -1;
    80005574:	57fd                	li	a5,-1
    80005576:	a83d                	j	800055b4 <sys_link+0x13c>
    iunlockput(dp);
    80005578:	854a                	mv	a0,s2
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	4fe080e7          	jalr	1278(ra) # 80003a78 <iunlockput>
  ilock(ip);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	292080e7          	jalr	658(ra) # 80003816 <ilock>
  ip->nlink--;
    8000558c:	04a4d783          	lhu	a5,74(s1)
    80005590:	37fd                	addiw	a5,a5,-1
    80005592:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005596:	8526                	mv	a0,s1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	1b4080e7          	jalr	436(ra) # 8000374c <iupdate>
  iunlockput(ip);
    800055a0:	8526                	mv	a0,s1
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	4d6080e7          	jalr	1238(ra) # 80003a78 <iunlockput>
  end_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	cc2080e7          	jalr	-830(ra) # 8000426c <end_op>
  return -1;
    800055b2:	57fd                	li	a5,-1
}
    800055b4:	853e                	mv	a0,a5
    800055b6:	70b2                	ld	ra,296(sp)
    800055b8:	7412                	ld	s0,288(sp)
    800055ba:	64f2                	ld	s1,280(sp)
    800055bc:	6952                	ld	s2,272(sp)
    800055be:	6155                	addi	sp,sp,304
    800055c0:	8082                	ret

00000000800055c2 <sys_unlink>:
{
    800055c2:	7151                	addi	sp,sp,-240
    800055c4:	f586                	sd	ra,232(sp)
    800055c6:	f1a2                	sd	s0,224(sp)
    800055c8:	eda6                	sd	s1,216(sp)
    800055ca:	e9ca                	sd	s2,208(sp)
    800055cc:	e5ce                	sd	s3,200(sp)
    800055ce:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055d0:	08000613          	li	a2,128
    800055d4:	f3040593          	addi	a1,s0,-208
    800055d8:	4501                	li	a0,0
    800055da:	ffffd097          	auipc	ra,0xffffd
    800055de:	50c080e7          	jalr	1292(ra) # 80002ae6 <argstr>
    800055e2:	18054163          	bltz	a0,80005764 <sys_unlink+0x1a2>
  begin_op();
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	c06080e7          	jalr	-1018(ra) # 800041ec <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055ee:	fb040593          	addi	a1,s0,-80
    800055f2:	f3040513          	addi	a0,s0,-208
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	9f4080e7          	jalr	-1548(ra) # 80003fea <nameiparent>
    800055fe:	84aa                	mv	s1,a0
    80005600:	c979                	beqz	a0,800056d6 <sys_unlink+0x114>
  ilock(dp);
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	214080e7          	jalr	532(ra) # 80003816 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000560a:	00003597          	auipc	a1,0x3
    8000560e:	24e58593          	addi	a1,a1,590 # 80008858 <syscalls+0x2b0>
    80005612:	fb040513          	addi	a0,s0,-80
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	6ca080e7          	jalr	1738(ra) # 80003ce0 <namecmp>
    8000561e:	14050a63          	beqz	a0,80005772 <sys_unlink+0x1b0>
    80005622:	00003597          	auipc	a1,0x3
    80005626:	23e58593          	addi	a1,a1,574 # 80008860 <syscalls+0x2b8>
    8000562a:	fb040513          	addi	a0,s0,-80
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	6b2080e7          	jalr	1714(ra) # 80003ce0 <namecmp>
    80005636:	12050e63          	beqz	a0,80005772 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000563a:	f2c40613          	addi	a2,s0,-212
    8000563e:	fb040593          	addi	a1,s0,-80
    80005642:	8526                	mv	a0,s1
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	6b6080e7          	jalr	1718(ra) # 80003cfa <dirlookup>
    8000564c:	892a                	mv	s2,a0
    8000564e:	12050263          	beqz	a0,80005772 <sys_unlink+0x1b0>
  ilock(ip);
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	1c4080e7          	jalr	452(ra) # 80003816 <ilock>
  if(ip->nlink < 1)
    8000565a:	04a91783          	lh	a5,74(s2)
    8000565e:	08f05263          	blez	a5,800056e2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005662:	04491703          	lh	a4,68(s2)
    80005666:	4785                	li	a5,1
    80005668:	08f70563          	beq	a4,a5,800056f2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000566c:	4641                	li	a2,16
    8000566e:	4581                	li	a1,0
    80005670:	fc040513          	addi	a0,s0,-64
    80005674:	ffffb097          	auipc	ra,0xffffb
    80005678:	64a080e7          	jalr	1610(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000567c:	4741                	li	a4,16
    8000567e:	f2c42683          	lw	a3,-212(s0)
    80005682:	fc040613          	addi	a2,s0,-64
    80005686:	4581                	li	a1,0
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	538080e7          	jalr	1336(ra) # 80003bc2 <writei>
    80005692:	47c1                	li	a5,16
    80005694:	0af51563          	bne	a0,a5,8000573e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005698:	04491703          	lh	a4,68(s2)
    8000569c:	4785                	li	a5,1
    8000569e:	0af70863          	beq	a4,a5,8000574e <sys_unlink+0x18c>
  iunlockput(dp);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	3d4080e7          	jalr	980(ra) # 80003a78 <iunlockput>
  ip->nlink--;
    800056ac:	04a95783          	lhu	a5,74(s2)
    800056b0:	37fd                	addiw	a5,a5,-1
    800056b2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056b6:	854a                	mv	a0,s2
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	094080e7          	jalr	148(ra) # 8000374c <iupdate>
  iunlockput(ip);
    800056c0:	854a                	mv	a0,s2
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	3b6080e7          	jalr	950(ra) # 80003a78 <iunlockput>
  end_op();
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	ba2080e7          	jalr	-1118(ra) # 8000426c <end_op>
  return 0;
    800056d2:	4501                	li	a0,0
    800056d4:	a84d                	j	80005786 <sys_unlink+0x1c4>
    end_op();
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	b96080e7          	jalr	-1130(ra) # 8000426c <end_op>
    return -1;
    800056de:	557d                	li	a0,-1
    800056e0:	a05d                	j	80005786 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056e2:	00003517          	auipc	a0,0x3
    800056e6:	1a650513          	addi	a0,a0,422 # 80008888 <syscalls+0x2e0>
    800056ea:	ffffb097          	auipc	ra,0xffffb
    800056ee:	e40080e7          	jalr	-448(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056f2:	04c92703          	lw	a4,76(s2)
    800056f6:	02000793          	li	a5,32
    800056fa:	f6e7f9e3          	bgeu	a5,a4,8000566c <sys_unlink+0xaa>
    800056fe:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005702:	4741                	li	a4,16
    80005704:	86ce                	mv	a3,s3
    80005706:	f1840613          	addi	a2,s0,-232
    8000570a:	4581                	li	a1,0
    8000570c:	854a                	mv	a0,s2
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	3bc080e7          	jalr	956(ra) # 80003aca <readi>
    80005716:	47c1                	li	a5,16
    80005718:	00f51b63          	bne	a0,a5,8000572e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000571c:	f1845783          	lhu	a5,-232(s0)
    80005720:	e7a1                	bnez	a5,80005768 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005722:	29c1                	addiw	s3,s3,16
    80005724:	04c92783          	lw	a5,76(s2)
    80005728:	fcf9ede3          	bltu	s3,a5,80005702 <sys_unlink+0x140>
    8000572c:	b781                	j	8000566c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000572e:	00003517          	auipc	a0,0x3
    80005732:	17250513          	addi	a0,a0,370 # 800088a0 <syscalls+0x2f8>
    80005736:	ffffb097          	auipc	ra,0xffffb
    8000573a:	df4080e7          	jalr	-524(ra) # 8000052a <panic>
    panic("unlink: writei");
    8000573e:	00003517          	auipc	a0,0x3
    80005742:	17a50513          	addi	a0,a0,378 # 800088b8 <syscalls+0x310>
    80005746:	ffffb097          	auipc	ra,0xffffb
    8000574a:	de4080e7          	jalr	-540(ra) # 8000052a <panic>
    dp->nlink--;
    8000574e:	04a4d783          	lhu	a5,74(s1)
    80005752:	37fd                	addiw	a5,a5,-1
    80005754:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005758:	8526                	mv	a0,s1
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	ff2080e7          	jalr	-14(ra) # 8000374c <iupdate>
    80005762:	b781                	j	800056a2 <sys_unlink+0xe0>
    return -1;
    80005764:	557d                	li	a0,-1
    80005766:	a005                	j	80005786 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	30e080e7          	jalr	782(ra) # 80003a78 <iunlockput>
  iunlockput(dp);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	304080e7          	jalr	772(ra) # 80003a78 <iunlockput>
  end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	af0080e7          	jalr	-1296(ra) # 8000426c <end_op>
  return -1;
    80005784:	557d                	li	a0,-1
}
    80005786:	70ae                	ld	ra,232(sp)
    80005788:	740e                	ld	s0,224(sp)
    8000578a:	64ee                	ld	s1,216(sp)
    8000578c:	694e                	ld	s2,208(sp)
    8000578e:	69ae                	ld	s3,200(sp)
    80005790:	616d                	addi	sp,sp,240
    80005792:	8082                	ret

0000000080005794 <sys_open>:

uint64
sys_open(void)
{
    80005794:	7131                	addi	sp,sp,-192
    80005796:	fd06                	sd	ra,184(sp)
    80005798:	f922                	sd	s0,176(sp)
    8000579a:	f526                	sd	s1,168(sp)
    8000579c:	f14a                	sd	s2,160(sp)
    8000579e:	ed4e                	sd	s3,152(sp)
    800057a0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057a2:	08000613          	li	a2,128
    800057a6:	f5040593          	addi	a1,s0,-176
    800057aa:	4501                	li	a0,0
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	33a080e7          	jalr	826(ra) # 80002ae6 <argstr>
    return -1;
    800057b4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057b6:	0c054163          	bltz	a0,80005878 <sys_open+0xe4>
    800057ba:	f4c40593          	addi	a1,s0,-180
    800057be:	4505                	li	a0,1
    800057c0:	ffffd097          	auipc	ra,0xffffd
    800057c4:	2e2080e7          	jalr	738(ra) # 80002aa2 <argint>
    800057c8:	0a054863          	bltz	a0,80005878 <sys_open+0xe4>

  begin_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	a20080e7          	jalr	-1504(ra) # 800041ec <begin_op>

  if(omode & O_CREATE){
    800057d4:	f4c42783          	lw	a5,-180(s0)
    800057d8:	2007f793          	andi	a5,a5,512
    800057dc:	cbdd                	beqz	a5,80005892 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057de:	4681                	li	a3,0
    800057e0:	4601                	li	a2,0
    800057e2:	4589                	li	a1,2
    800057e4:	f5040513          	addi	a0,s0,-176
    800057e8:	00000097          	auipc	ra,0x0
    800057ec:	974080e7          	jalr	-1676(ra) # 8000515c <create>
    800057f0:	892a                	mv	s2,a0
    if(ip == 0){
    800057f2:	c959                	beqz	a0,80005888 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057f4:	04491703          	lh	a4,68(s2)
    800057f8:	478d                	li	a5,3
    800057fa:	00f71763          	bne	a4,a5,80005808 <sys_open+0x74>
    800057fe:	04695703          	lhu	a4,70(s2)
    80005802:	47a5                	li	a5,9
    80005804:	0ce7ec63          	bltu	a5,a4,800058dc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	df4080e7          	jalr	-524(ra) # 800045fc <filealloc>
    80005810:	89aa                	mv	s3,a0
    80005812:	10050263          	beqz	a0,80005916 <sys_open+0x182>
    80005816:	00000097          	auipc	ra,0x0
    8000581a:	904080e7          	jalr	-1788(ra) # 8000511a <fdalloc>
    8000581e:	84aa                	mv	s1,a0
    80005820:	0e054663          	bltz	a0,8000590c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005824:	04491703          	lh	a4,68(s2)
    80005828:	478d                	li	a5,3
    8000582a:	0cf70463          	beq	a4,a5,800058f2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000582e:	4789                	li	a5,2
    80005830:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005834:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005838:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000583c:	f4c42783          	lw	a5,-180(s0)
    80005840:	0017c713          	xori	a4,a5,1
    80005844:	8b05                	andi	a4,a4,1
    80005846:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000584a:	0037f713          	andi	a4,a5,3
    8000584e:	00e03733          	snez	a4,a4
    80005852:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005856:	4007f793          	andi	a5,a5,1024
    8000585a:	c791                	beqz	a5,80005866 <sys_open+0xd2>
    8000585c:	04491703          	lh	a4,68(s2)
    80005860:	4789                	li	a5,2
    80005862:	08f70f63          	beq	a4,a5,80005900 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005866:	854a                	mv	a0,s2
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	070080e7          	jalr	112(ra) # 800038d8 <iunlock>
  end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	9fc080e7          	jalr	-1540(ra) # 8000426c <end_op>

  return fd;
}
    80005878:	8526                	mv	a0,s1
    8000587a:	70ea                	ld	ra,184(sp)
    8000587c:	744a                	ld	s0,176(sp)
    8000587e:	74aa                	ld	s1,168(sp)
    80005880:	790a                	ld	s2,160(sp)
    80005882:	69ea                	ld	s3,152(sp)
    80005884:	6129                	addi	sp,sp,192
    80005886:	8082                	ret
      end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	9e4080e7          	jalr	-1564(ra) # 8000426c <end_op>
      return -1;
    80005890:	b7e5                	j	80005878 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005892:	f5040513          	addi	a0,s0,-176
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	736080e7          	jalr	1846(ra) # 80003fcc <namei>
    8000589e:	892a                	mv	s2,a0
    800058a0:	c905                	beqz	a0,800058d0 <sys_open+0x13c>
    ilock(ip);
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	f74080e7          	jalr	-140(ra) # 80003816 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058aa:	04491703          	lh	a4,68(s2)
    800058ae:	4785                	li	a5,1
    800058b0:	f4f712e3          	bne	a4,a5,800057f4 <sys_open+0x60>
    800058b4:	f4c42783          	lw	a5,-180(s0)
    800058b8:	dba1                	beqz	a5,80005808 <sys_open+0x74>
      iunlockput(ip);
    800058ba:	854a                	mv	a0,s2
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	1bc080e7          	jalr	444(ra) # 80003a78 <iunlockput>
      end_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	9a8080e7          	jalr	-1624(ra) # 8000426c <end_op>
      return -1;
    800058cc:	54fd                	li	s1,-1
    800058ce:	b76d                	j	80005878 <sys_open+0xe4>
      end_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	99c080e7          	jalr	-1636(ra) # 8000426c <end_op>
      return -1;
    800058d8:	54fd                	li	s1,-1
    800058da:	bf79                	j	80005878 <sys_open+0xe4>
    iunlockput(ip);
    800058dc:	854a                	mv	a0,s2
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	19a080e7          	jalr	410(ra) # 80003a78 <iunlockput>
    end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	986080e7          	jalr	-1658(ra) # 8000426c <end_op>
    return -1;
    800058ee:	54fd                	li	s1,-1
    800058f0:	b761                	j	80005878 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058f2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058f6:	04691783          	lh	a5,70(s2)
    800058fa:	02f99223          	sh	a5,36(s3)
    800058fe:	bf2d                	j	80005838 <sys_open+0xa4>
    itrunc(ip);
    80005900:	854a                	mv	a0,s2
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	022080e7          	jalr	34(ra) # 80003924 <itrunc>
    8000590a:	bfb1                	j	80005866 <sys_open+0xd2>
      fileclose(f);
    8000590c:	854e                	mv	a0,s3
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	daa080e7          	jalr	-598(ra) # 800046b8 <fileclose>
    iunlockput(ip);
    80005916:	854a                	mv	a0,s2
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	160080e7          	jalr	352(ra) # 80003a78 <iunlockput>
    end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	94c080e7          	jalr	-1716(ra) # 8000426c <end_op>
    return -1;
    80005928:	54fd                	li	s1,-1
    8000592a:	b7b9                	j	80005878 <sys_open+0xe4>

000000008000592c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000592c:	7175                	addi	sp,sp,-144
    8000592e:	e506                	sd	ra,136(sp)
    80005930:	e122                	sd	s0,128(sp)
    80005932:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	8b8080e7          	jalr	-1864(ra) # 800041ec <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000593c:	08000613          	li	a2,128
    80005940:	f7040593          	addi	a1,s0,-144
    80005944:	4501                	li	a0,0
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	1a0080e7          	jalr	416(ra) # 80002ae6 <argstr>
    8000594e:	02054963          	bltz	a0,80005980 <sys_mkdir+0x54>
    80005952:	4681                	li	a3,0
    80005954:	4601                	li	a2,0
    80005956:	4585                	li	a1,1
    80005958:	f7040513          	addi	a0,s0,-144
    8000595c:	00000097          	auipc	ra,0x0
    80005960:	800080e7          	jalr	-2048(ra) # 8000515c <create>
    80005964:	cd11                	beqz	a0,80005980 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	112080e7          	jalr	274(ra) # 80003a78 <iunlockput>
  end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	8fe080e7          	jalr	-1794(ra) # 8000426c <end_op>
  return 0;
    80005976:	4501                	li	a0,0
}
    80005978:	60aa                	ld	ra,136(sp)
    8000597a:	640a                	ld	s0,128(sp)
    8000597c:	6149                	addi	sp,sp,144
    8000597e:	8082                	ret
    end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	8ec080e7          	jalr	-1812(ra) # 8000426c <end_op>
    return -1;
    80005988:	557d                	li	a0,-1
    8000598a:	b7fd                	j	80005978 <sys_mkdir+0x4c>

000000008000598c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000598c:	7135                	addi	sp,sp,-160
    8000598e:	ed06                	sd	ra,152(sp)
    80005990:	e922                	sd	s0,144(sp)
    80005992:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	858080e7          	jalr	-1960(ra) # 800041ec <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000599c:	08000613          	li	a2,128
    800059a0:	f7040593          	addi	a1,s0,-144
    800059a4:	4501                	li	a0,0
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	140080e7          	jalr	320(ra) # 80002ae6 <argstr>
    800059ae:	04054a63          	bltz	a0,80005a02 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059b2:	f6c40593          	addi	a1,s0,-148
    800059b6:	4505                	li	a0,1
    800059b8:	ffffd097          	auipc	ra,0xffffd
    800059bc:	0ea080e7          	jalr	234(ra) # 80002aa2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c0:	04054163          	bltz	a0,80005a02 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059c4:	f6840593          	addi	a1,s0,-152
    800059c8:	4509                	li	a0,2
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	0d8080e7          	jalr	216(ra) # 80002aa2 <argint>
     argint(1, &major) < 0 ||
    800059d2:	02054863          	bltz	a0,80005a02 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059d6:	f6841683          	lh	a3,-152(s0)
    800059da:	f6c41603          	lh	a2,-148(s0)
    800059de:	458d                	li	a1,3
    800059e0:	f7040513          	addi	a0,s0,-144
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	778080e7          	jalr	1912(ra) # 8000515c <create>
     argint(2, &minor) < 0 ||
    800059ec:	c919                	beqz	a0,80005a02 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	08a080e7          	jalr	138(ra) # 80003a78 <iunlockput>
  end_op();
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	876080e7          	jalr	-1930(ra) # 8000426c <end_op>
  return 0;
    800059fe:	4501                	li	a0,0
    80005a00:	a031                	j	80005a0c <sys_mknod+0x80>
    end_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	86a080e7          	jalr	-1942(ra) # 8000426c <end_op>
    return -1;
    80005a0a:	557d                	li	a0,-1
}
    80005a0c:	60ea                	ld	ra,152(sp)
    80005a0e:	644a                	ld	s0,144(sp)
    80005a10:	610d                	addi	sp,sp,160
    80005a12:	8082                	ret

0000000080005a14 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a14:	7135                	addi	sp,sp,-160
    80005a16:	ed06                	sd	ra,152(sp)
    80005a18:	e922                	sd	s0,144(sp)
    80005a1a:	e526                	sd	s1,136(sp)
    80005a1c:	e14a                	sd	s2,128(sp)
    80005a1e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a20:	ffffc097          	auipc	ra,0xffffc
    80005a24:	f5e080e7          	jalr	-162(ra) # 8000197e <myproc>
    80005a28:	892a                	mv	s2,a0
  
  begin_op();
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	7c2080e7          	jalr	1986(ra) # 800041ec <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a32:	08000613          	li	a2,128
    80005a36:	f6040593          	addi	a1,s0,-160
    80005a3a:	4501                	li	a0,0
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	0aa080e7          	jalr	170(ra) # 80002ae6 <argstr>
    80005a44:	04054b63          	bltz	a0,80005a9a <sys_chdir+0x86>
    80005a48:	f6040513          	addi	a0,s0,-160
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	580080e7          	jalr	1408(ra) # 80003fcc <namei>
    80005a54:	84aa                	mv	s1,a0
    80005a56:	c131                	beqz	a0,80005a9a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	dbe080e7          	jalr	-578(ra) # 80003816 <ilock>
  if(ip->type != T_DIR){
    80005a60:	04449703          	lh	a4,68(s1)
    80005a64:	4785                	li	a5,1
    80005a66:	04f71063          	bne	a4,a5,80005aa6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	e6c080e7          	jalr	-404(ra) # 800038d8 <iunlock>
  iput(p->cwd);
    80005a74:	15093503          	ld	a0,336(s2)
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	f58080e7          	jalr	-168(ra) # 800039d0 <iput>
  end_op();
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	7ec080e7          	jalr	2028(ra) # 8000426c <end_op>
  p->cwd = ip;
    80005a88:	14993823          	sd	s1,336(s2)
  return 0;
    80005a8c:	4501                	li	a0,0
}
    80005a8e:	60ea                	ld	ra,152(sp)
    80005a90:	644a                	ld	s0,144(sp)
    80005a92:	64aa                	ld	s1,136(sp)
    80005a94:	690a                	ld	s2,128(sp)
    80005a96:	610d                	addi	sp,sp,160
    80005a98:	8082                	ret
    end_op();
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	7d2080e7          	jalr	2002(ra) # 8000426c <end_op>
    return -1;
    80005aa2:	557d                	li	a0,-1
    80005aa4:	b7ed                	j	80005a8e <sys_chdir+0x7a>
    iunlockput(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	fd0080e7          	jalr	-48(ra) # 80003a78 <iunlockput>
    end_op();
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	7bc080e7          	jalr	1980(ra) # 8000426c <end_op>
    return -1;
    80005ab8:	557d                	li	a0,-1
    80005aba:	bfd1                	j	80005a8e <sys_chdir+0x7a>

0000000080005abc <sys_exec>:

uint64
sys_exec(void)
{
    80005abc:	7145                	addi	sp,sp,-464
    80005abe:	e786                	sd	ra,456(sp)
    80005ac0:	e3a2                	sd	s0,448(sp)
    80005ac2:	ff26                	sd	s1,440(sp)
    80005ac4:	fb4a                	sd	s2,432(sp)
    80005ac6:	f74e                	sd	s3,424(sp)
    80005ac8:	f352                	sd	s4,416(sp)
    80005aca:	ef56                	sd	s5,408(sp)
    80005acc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ace:	08000613          	li	a2,128
    80005ad2:	f4040593          	addi	a1,s0,-192
    80005ad6:	4501                	li	a0,0
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	00e080e7          	jalr	14(ra) # 80002ae6 <argstr>
    return -1;
    80005ae0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ae2:	0c054a63          	bltz	a0,80005bb6 <sys_exec+0xfa>
    80005ae6:	e3840593          	addi	a1,s0,-456
    80005aea:	4505                	li	a0,1
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	fd8080e7          	jalr	-40(ra) # 80002ac4 <argaddr>
    80005af4:	0c054163          	bltz	a0,80005bb6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005af8:	10000613          	li	a2,256
    80005afc:	4581                	li	a1,0
    80005afe:	e4040513          	addi	a0,s0,-448
    80005b02:	ffffb097          	auipc	ra,0xffffb
    80005b06:	1bc080e7          	jalr	444(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b0a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b0e:	89a6                	mv	s3,s1
    80005b10:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b12:	02000a13          	li	s4,32
    80005b16:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b1a:	00391793          	slli	a5,s2,0x3
    80005b1e:	e3040593          	addi	a1,s0,-464
    80005b22:	e3843503          	ld	a0,-456(s0)
    80005b26:	953e                	add	a0,a0,a5
    80005b28:	ffffd097          	auipc	ra,0xffffd
    80005b2c:	ee0080e7          	jalr	-288(ra) # 80002a08 <fetchaddr>
    80005b30:	02054a63          	bltz	a0,80005b64 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b34:	e3043783          	ld	a5,-464(s0)
    80005b38:	c3b9                	beqz	a5,80005b7e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b3a:	ffffb097          	auipc	ra,0xffffb
    80005b3e:	f98080e7          	jalr	-104(ra) # 80000ad2 <kalloc>
    80005b42:	85aa                	mv	a1,a0
    80005b44:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b48:	cd11                	beqz	a0,80005b64 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b4a:	6605                	lui	a2,0x1
    80005b4c:	e3043503          	ld	a0,-464(s0)
    80005b50:	ffffd097          	auipc	ra,0xffffd
    80005b54:	f0a080e7          	jalr	-246(ra) # 80002a5a <fetchstr>
    80005b58:	00054663          	bltz	a0,80005b64 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b5c:	0905                	addi	s2,s2,1
    80005b5e:	09a1                	addi	s3,s3,8
    80005b60:	fb491be3          	bne	s2,s4,80005b16 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b64:	10048913          	addi	s2,s1,256
    80005b68:	6088                	ld	a0,0(s1)
    80005b6a:	c529                	beqz	a0,80005bb4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b6c:	ffffb097          	auipc	ra,0xffffb
    80005b70:	e6a080e7          	jalr	-406(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b74:	04a1                	addi	s1,s1,8
    80005b76:	ff2499e3          	bne	s1,s2,80005b68 <sys_exec+0xac>
  return -1;
    80005b7a:	597d                	li	s2,-1
    80005b7c:	a82d                	j	80005bb6 <sys_exec+0xfa>
      argv[i] = 0;
    80005b7e:	0a8e                	slli	s5,s5,0x3
    80005b80:	fc040793          	addi	a5,s0,-64
    80005b84:	9abe                	add	s5,s5,a5
    80005b86:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005b8a:	e4040593          	addi	a1,s0,-448
    80005b8e:	f4040513          	addi	a0,s0,-192
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	178080e7          	jalr	376(ra) # 80004d0a <exec>
    80005b9a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9c:	10048993          	addi	s3,s1,256
    80005ba0:	6088                	ld	a0,0(s1)
    80005ba2:	c911                	beqz	a0,80005bb6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ba4:	ffffb097          	auipc	ra,0xffffb
    80005ba8:	e32080e7          	jalr	-462(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bac:	04a1                	addi	s1,s1,8
    80005bae:	ff3499e3          	bne	s1,s3,80005ba0 <sys_exec+0xe4>
    80005bb2:	a011                	j	80005bb6 <sys_exec+0xfa>
  return -1;
    80005bb4:	597d                	li	s2,-1
}
    80005bb6:	854a                	mv	a0,s2
    80005bb8:	60be                	ld	ra,456(sp)
    80005bba:	641e                	ld	s0,448(sp)
    80005bbc:	74fa                	ld	s1,440(sp)
    80005bbe:	795a                	ld	s2,432(sp)
    80005bc0:	79ba                	ld	s3,424(sp)
    80005bc2:	7a1a                	ld	s4,416(sp)
    80005bc4:	6afa                	ld	s5,408(sp)
    80005bc6:	6179                	addi	sp,sp,464
    80005bc8:	8082                	ret

0000000080005bca <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bca:	7139                	addi	sp,sp,-64
    80005bcc:	fc06                	sd	ra,56(sp)
    80005bce:	f822                	sd	s0,48(sp)
    80005bd0:	f426                	sd	s1,40(sp)
    80005bd2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bd4:	ffffc097          	auipc	ra,0xffffc
    80005bd8:	daa080e7          	jalr	-598(ra) # 8000197e <myproc>
    80005bdc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bde:	fd840593          	addi	a1,s0,-40
    80005be2:	4501                	li	a0,0
    80005be4:	ffffd097          	auipc	ra,0xffffd
    80005be8:	ee0080e7          	jalr	-288(ra) # 80002ac4 <argaddr>
    return -1;
    80005bec:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bee:	0e054063          	bltz	a0,80005cce <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bf2:	fc840593          	addi	a1,s0,-56
    80005bf6:	fd040513          	addi	a0,s0,-48
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	dee080e7          	jalr	-530(ra) # 800049e8 <pipealloc>
    return -1;
    80005c02:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c04:	0c054563          	bltz	a0,80005cce <sys_pipe+0x104>
  fd0 = -1;
    80005c08:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c0c:	fd043503          	ld	a0,-48(s0)
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	50a080e7          	jalr	1290(ra) # 8000511a <fdalloc>
    80005c18:	fca42223          	sw	a0,-60(s0)
    80005c1c:	08054c63          	bltz	a0,80005cb4 <sys_pipe+0xea>
    80005c20:	fc843503          	ld	a0,-56(s0)
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	4f6080e7          	jalr	1270(ra) # 8000511a <fdalloc>
    80005c2c:	fca42023          	sw	a0,-64(s0)
    80005c30:	06054863          	bltz	a0,80005ca0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c34:	4691                	li	a3,4
    80005c36:	fc440613          	addi	a2,s0,-60
    80005c3a:	fd843583          	ld	a1,-40(s0)
    80005c3e:	68a8                	ld	a0,80(s1)
    80005c40:	ffffc097          	auipc	ra,0xffffc
    80005c44:	9fe080e7          	jalr	-1538(ra) # 8000163e <copyout>
    80005c48:	02054063          	bltz	a0,80005c68 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c4c:	4691                	li	a3,4
    80005c4e:	fc040613          	addi	a2,s0,-64
    80005c52:	fd843583          	ld	a1,-40(s0)
    80005c56:	0591                	addi	a1,a1,4
    80005c58:	68a8                	ld	a0,80(s1)
    80005c5a:	ffffc097          	auipc	ra,0xffffc
    80005c5e:	9e4080e7          	jalr	-1564(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c62:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c64:	06055563          	bgez	a0,80005cce <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c68:	fc442783          	lw	a5,-60(s0)
    80005c6c:	07e9                	addi	a5,a5,26
    80005c6e:	078e                	slli	a5,a5,0x3
    80005c70:	97a6                	add	a5,a5,s1
    80005c72:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c76:	fc042503          	lw	a0,-64(s0)
    80005c7a:	0569                	addi	a0,a0,26
    80005c7c:	050e                	slli	a0,a0,0x3
    80005c7e:	9526                	add	a0,a0,s1
    80005c80:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c84:	fd043503          	ld	a0,-48(s0)
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	a30080e7          	jalr	-1488(ra) # 800046b8 <fileclose>
    fileclose(wf);
    80005c90:	fc843503          	ld	a0,-56(s0)
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	a24080e7          	jalr	-1500(ra) # 800046b8 <fileclose>
    return -1;
    80005c9c:	57fd                	li	a5,-1
    80005c9e:	a805                	j	80005cce <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ca0:	fc442783          	lw	a5,-60(s0)
    80005ca4:	0007c863          	bltz	a5,80005cb4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ca8:	01a78513          	addi	a0,a5,26
    80005cac:	050e                	slli	a0,a0,0x3
    80005cae:	9526                	add	a0,a0,s1
    80005cb0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cb4:	fd043503          	ld	a0,-48(s0)
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	a00080e7          	jalr	-1536(ra) # 800046b8 <fileclose>
    fileclose(wf);
    80005cc0:	fc843503          	ld	a0,-56(s0)
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	9f4080e7          	jalr	-1548(ra) # 800046b8 <fileclose>
    return -1;
    80005ccc:	57fd                	li	a5,-1
}
    80005cce:	853e                	mv	a0,a5
    80005cd0:	70e2                	ld	ra,56(sp)
    80005cd2:	7442                	ld	s0,48(sp)
    80005cd4:	74a2                	ld	s1,40(sp)
    80005cd6:	6121                	addi	sp,sp,64
    80005cd8:	8082                	ret
    80005cda:	0000                	unimp
    80005cdc:	0000                	unimp
	...

0000000080005ce0 <kernelvec>:
    80005ce0:	7111                	addi	sp,sp,-256
    80005ce2:	e006                	sd	ra,0(sp)
    80005ce4:	e40a                	sd	sp,8(sp)
    80005ce6:	e80e                	sd	gp,16(sp)
    80005ce8:	ec12                	sd	tp,24(sp)
    80005cea:	f016                	sd	t0,32(sp)
    80005cec:	f41a                	sd	t1,40(sp)
    80005cee:	f81e                	sd	t2,48(sp)
    80005cf0:	fc22                	sd	s0,56(sp)
    80005cf2:	e0a6                	sd	s1,64(sp)
    80005cf4:	e4aa                	sd	a0,72(sp)
    80005cf6:	e8ae                	sd	a1,80(sp)
    80005cf8:	ecb2                	sd	a2,88(sp)
    80005cfa:	f0b6                	sd	a3,96(sp)
    80005cfc:	f4ba                	sd	a4,104(sp)
    80005cfe:	f8be                	sd	a5,112(sp)
    80005d00:	fcc2                	sd	a6,120(sp)
    80005d02:	e146                	sd	a7,128(sp)
    80005d04:	e54a                	sd	s2,136(sp)
    80005d06:	e94e                	sd	s3,144(sp)
    80005d08:	ed52                	sd	s4,152(sp)
    80005d0a:	f156                	sd	s5,160(sp)
    80005d0c:	f55a                	sd	s6,168(sp)
    80005d0e:	f95e                	sd	s7,176(sp)
    80005d10:	fd62                	sd	s8,184(sp)
    80005d12:	e1e6                	sd	s9,192(sp)
    80005d14:	e5ea                	sd	s10,200(sp)
    80005d16:	e9ee                	sd	s11,208(sp)
    80005d18:	edf2                	sd	t3,216(sp)
    80005d1a:	f1f6                	sd	t4,224(sp)
    80005d1c:	f5fa                	sd	t5,232(sp)
    80005d1e:	f9fe                	sd	t6,240(sp)
    80005d20:	bb5fc0ef          	jal	ra,800028d4 <kerneltrap>
    80005d24:	6082                	ld	ra,0(sp)
    80005d26:	6122                	ld	sp,8(sp)
    80005d28:	61c2                	ld	gp,16(sp)
    80005d2a:	7282                	ld	t0,32(sp)
    80005d2c:	7322                	ld	t1,40(sp)
    80005d2e:	73c2                	ld	t2,48(sp)
    80005d30:	7462                	ld	s0,56(sp)
    80005d32:	6486                	ld	s1,64(sp)
    80005d34:	6526                	ld	a0,72(sp)
    80005d36:	65c6                	ld	a1,80(sp)
    80005d38:	6666                	ld	a2,88(sp)
    80005d3a:	7686                	ld	a3,96(sp)
    80005d3c:	7726                	ld	a4,104(sp)
    80005d3e:	77c6                	ld	a5,112(sp)
    80005d40:	7866                	ld	a6,120(sp)
    80005d42:	688a                	ld	a7,128(sp)
    80005d44:	692a                	ld	s2,136(sp)
    80005d46:	69ca                	ld	s3,144(sp)
    80005d48:	6a6a                	ld	s4,152(sp)
    80005d4a:	7a8a                	ld	s5,160(sp)
    80005d4c:	7b2a                	ld	s6,168(sp)
    80005d4e:	7bca                	ld	s7,176(sp)
    80005d50:	7c6a                	ld	s8,184(sp)
    80005d52:	6c8e                	ld	s9,192(sp)
    80005d54:	6d2e                	ld	s10,200(sp)
    80005d56:	6dce                	ld	s11,208(sp)
    80005d58:	6e6e                	ld	t3,216(sp)
    80005d5a:	7e8e                	ld	t4,224(sp)
    80005d5c:	7f2e                	ld	t5,232(sp)
    80005d5e:	7fce                	ld	t6,240(sp)
    80005d60:	6111                	addi	sp,sp,256
    80005d62:	10200073          	sret
    80005d66:	00000013          	nop
    80005d6a:	00000013          	nop
    80005d6e:	0001                	nop

0000000080005d70 <timervec>:
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	e10c                	sd	a1,0(a0)
    80005d76:	e510                	sd	a2,8(a0)
    80005d78:	e914                	sd	a3,16(a0)
    80005d7a:	6d0c                	ld	a1,24(a0)
    80005d7c:	7110                	ld	a2,32(a0)
    80005d7e:	6194                	ld	a3,0(a1)
    80005d80:	96b2                	add	a3,a3,a2
    80005d82:	e194                	sd	a3,0(a1)
    80005d84:	4589                	li	a1,2
    80005d86:	14459073          	csrw	sip,a1
    80005d8a:	6914                	ld	a3,16(a0)
    80005d8c:	6510                	ld	a2,8(a0)
    80005d8e:	610c                	ld	a1,0(a0)
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	30200073          	mret
	...

0000000080005d9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d9a:	1141                	addi	sp,sp,-16
    80005d9c:	e422                	sd	s0,8(sp)
    80005d9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005da0:	0c0007b7          	lui	a5,0xc000
    80005da4:	4705                	li	a4,1
    80005da6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005da8:	c3d8                	sw	a4,4(a5)
}
    80005daa:	6422                	ld	s0,8(sp)
    80005dac:	0141                	addi	sp,sp,16
    80005dae:	8082                	ret

0000000080005db0 <plicinithart>:

void
plicinithart(void)
{
    80005db0:	1141                	addi	sp,sp,-16
    80005db2:	e406                	sd	ra,8(sp)
    80005db4:	e022                	sd	s0,0(sp)
    80005db6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	b9a080e7          	jalr	-1126(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005dc0:	0085171b          	slliw	a4,a0,0x8
    80005dc4:	0c0027b7          	lui	a5,0xc002
    80005dc8:	97ba                	add	a5,a5,a4
    80005dca:	40200713          	li	a4,1026
    80005dce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005dd2:	00d5151b          	slliw	a0,a0,0xd
    80005dd6:	0c2017b7          	lui	a5,0xc201
    80005dda:	953e                	add	a0,a0,a5
    80005ddc:	00052023          	sw	zero,0(a0)
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret

0000000080005de8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005de8:	1141                	addi	sp,sp,-16
    80005dea:	e406                	sd	ra,8(sp)
    80005dec:	e022                	sd	s0,0(sp)
    80005dee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005df0:	ffffc097          	auipc	ra,0xffffc
    80005df4:	b62080e7          	jalr	-1182(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005df8:	00d5179b          	slliw	a5,a0,0xd
    80005dfc:	0c201537          	lui	a0,0xc201
    80005e00:	953e                	add	a0,a0,a5
  return irq;
}
    80005e02:	4148                	lw	a0,4(a0)
    80005e04:	60a2                	ld	ra,8(sp)
    80005e06:	6402                	ld	s0,0(sp)
    80005e08:	0141                	addi	sp,sp,16
    80005e0a:	8082                	ret

0000000080005e0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e0c:	1101                	addi	sp,sp,-32
    80005e0e:	ec06                	sd	ra,24(sp)
    80005e10:	e822                	sd	s0,16(sp)
    80005e12:	e426                	sd	s1,8(sp)
    80005e14:	1000                	addi	s0,sp,32
    80005e16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	b3a080e7          	jalr	-1222(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e20:	00d5151b          	slliw	a0,a0,0xd
    80005e24:	0c2017b7          	lui	a5,0xc201
    80005e28:	97aa                	add	a5,a5,a0
    80005e2a:	c3c4                	sw	s1,4(a5)
}
    80005e2c:	60e2                	ld	ra,24(sp)
    80005e2e:	6442                	ld	s0,16(sp)
    80005e30:	64a2                	ld	s1,8(sp)
    80005e32:	6105                	addi	sp,sp,32
    80005e34:	8082                	ret

0000000080005e36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e36:	1141                	addi	sp,sp,-16
    80005e38:	e406                	sd	ra,8(sp)
    80005e3a:	e022                	sd	s0,0(sp)
    80005e3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e3e:	479d                	li	a5,7
    80005e40:	06a7c963          	blt	a5,a0,80005eb2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e44:	0001d797          	auipc	a5,0x1d
    80005e48:	1bc78793          	addi	a5,a5,444 # 80023000 <disk>
    80005e4c:	00a78733          	add	a4,a5,a0
    80005e50:	6789                	lui	a5,0x2
    80005e52:	97ba                	add	a5,a5,a4
    80005e54:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e58:	e7ad                	bnez	a5,80005ec2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e5a:	00451793          	slli	a5,a0,0x4
    80005e5e:	0001f717          	auipc	a4,0x1f
    80005e62:	1a270713          	addi	a4,a4,418 # 80025000 <disk+0x2000>
    80005e66:	6314                	ld	a3,0(a4)
    80005e68:	96be                	add	a3,a3,a5
    80005e6a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e6e:	6314                	ld	a3,0(a4)
    80005e70:	96be                	add	a3,a3,a5
    80005e72:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e76:	6314                	ld	a3,0(a4)
    80005e78:	96be                	add	a3,a3,a5
    80005e7a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e7e:	6318                	ld	a4,0(a4)
    80005e80:	97ba                	add	a5,a5,a4
    80005e82:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e86:	0001d797          	auipc	a5,0x1d
    80005e8a:	17a78793          	addi	a5,a5,378 # 80023000 <disk>
    80005e8e:	97aa                	add	a5,a5,a0
    80005e90:	6509                	lui	a0,0x2
    80005e92:	953e                	add	a0,a0,a5
    80005e94:	4785                	li	a5,1
    80005e96:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e9a:	0001f517          	auipc	a0,0x1f
    80005e9e:	17e50513          	addi	a0,a0,382 # 80025018 <disk+0x2018>
    80005ea2:	ffffc097          	auipc	ra,0xffffc
    80005ea6:	330080e7          	jalr	816(ra) # 800021d2 <wakeup>
}
    80005eaa:	60a2                	ld	ra,8(sp)
    80005eac:	6402                	ld	s0,0(sp)
    80005eae:	0141                	addi	sp,sp,16
    80005eb0:	8082                	ret
    panic("free_desc 1");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	a1650513          	addi	a0,a0,-1514 # 800088c8 <syscalls+0x320>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	670080e7          	jalr	1648(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	a1650513          	addi	a0,a0,-1514 # 800088d8 <syscalls+0x330>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	660080e7          	jalr	1632(ra) # 8000052a <panic>

0000000080005ed2 <virtio_disk_init>:
{
    80005ed2:	1101                	addi	sp,sp,-32
    80005ed4:	ec06                	sd	ra,24(sp)
    80005ed6:	e822                	sd	s0,16(sp)
    80005ed8:	e426                	sd	s1,8(sp)
    80005eda:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005edc:	00003597          	auipc	a1,0x3
    80005ee0:	a0c58593          	addi	a1,a1,-1524 # 800088e8 <syscalls+0x340>
    80005ee4:	0001f517          	auipc	a0,0x1f
    80005ee8:	24450513          	addi	a0,a0,580 # 80025128 <disk+0x2128>
    80005eec:	ffffb097          	auipc	ra,0xffffb
    80005ef0:	c46080e7          	jalr	-954(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ef4:	100017b7          	lui	a5,0x10001
    80005ef8:	4398                	lw	a4,0(a5)
    80005efa:	2701                	sext.w	a4,a4
    80005efc:	747277b7          	lui	a5,0x74727
    80005f00:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f04:	0ef71163          	bne	a4,a5,80005fe6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f08:	100017b7          	lui	a5,0x10001
    80005f0c:	43dc                	lw	a5,4(a5)
    80005f0e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f10:	4705                	li	a4,1
    80005f12:	0ce79a63          	bne	a5,a4,80005fe6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f16:	100017b7          	lui	a5,0x10001
    80005f1a:	479c                	lw	a5,8(a5)
    80005f1c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f1e:	4709                	li	a4,2
    80005f20:	0ce79363          	bne	a5,a4,80005fe6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f24:	100017b7          	lui	a5,0x10001
    80005f28:	47d8                	lw	a4,12(a5)
    80005f2a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f2c:	554d47b7          	lui	a5,0x554d4
    80005f30:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f34:	0af71963          	bne	a4,a5,80005fe6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f38:	100017b7          	lui	a5,0x10001
    80005f3c:	4705                	li	a4,1
    80005f3e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f40:	470d                	li	a4,3
    80005f42:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f44:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f46:	c7ffe737          	lui	a4,0xc7ffe
    80005f4a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f4e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f50:	2701                	sext.w	a4,a4
    80005f52:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f54:	472d                	li	a4,11
    80005f56:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f58:	473d                	li	a4,15
    80005f5a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f5c:	6705                	lui	a4,0x1
    80005f5e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f60:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f64:	5bdc                	lw	a5,52(a5)
    80005f66:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f68:	c7d9                	beqz	a5,80005ff6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f6a:	471d                	li	a4,7
    80005f6c:	08f77d63          	bgeu	a4,a5,80006006 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f70:	100014b7          	lui	s1,0x10001
    80005f74:	47a1                	li	a5,8
    80005f76:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f78:	6609                	lui	a2,0x2
    80005f7a:	4581                	li	a1,0
    80005f7c:	0001d517          	auipc	a0,0x1d
    80005f80:	08450513          	addi	a0,a0,132 # 80023000 <disk>
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	d3a080e7          	jalr	-710(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f8c:	0001d717          	auipc	a4,0x1d
    80005f90:	07470713          	addi	a4,a4,116 # 80023000 <disk>
    80005f94:	00c75793          	srli	a5,a4,0xc
    80005f98:	2781                	sext.w	a5,a5
    80005f9a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f9c:	0001f797          	auipc	a5,0x1f
    80005fa0:	06478793          	addi	a5,a5,100 # 80025000 <disk+0x2000>
    80005fa4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fa6:	0001d717          	auipc	a4,0x1d
    80005faa:	0da70713          	addi	a4,a4,218 # 80023080 <disk+0x80>
    80005fae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fb0:	0001e717          	auipc	a4,0x1e
    80005fb4:	05070713          	addi	a4,a4,80 # 80024000 <disk+0x1000>
    80005fb8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fba:	4705                	li	a4,1
    80005fbc:	00e78c23          	sb	a4,24(a5)
    80005fc0:	00e78ca3          	sb	a4,25(a5)
    80005fc4:	00e78d23          	sb	a4,26(a5)
    80005fc8:	00e78da3          	sb	a4,27(a5)
    80005fcc:	00e78e23          	sb	a4,28(a5)
    80005fd0:	00e78ea3          	sb	a4,29(a5)
    80005fd4:	00e78f23          	sb	a4,30(a5)
    80005fd8:	00e78fa3          	sb	a4,31(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6105                	addi	sp,sp,32
    80005fe4:	8082                	ret
    panic("could not find virtio disk");
    80005fe6:	00003517          	auipc	a0,0x3
    80005fea:	91250513          	addi	a0,a0,-1774 # 800088f8 <syscalls+0x350>
    80005fee:	ffffa097          	auipc	ra,0xffffa
    80005ff2:	53c080e7          	jalr	1340(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80005ff6:	00003517          	auipc	a0,0x3
    80005ffa:	92250513          	addi	a0,a0,-1758 # 80008918 <syscalls+0x370>
    80005ffe:	ffffa097          	auipc	ra,0xffffa
    80006002:	52c080e7          	jalr	1324(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006006:	00003517          	auipc	a0,0x3
    8000600a:	93250513          	addi	a0,a0,-1742 # 80008938 <syscalls+0x390>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	51c080e7          	jalr	1308(ra) # 8000052a <panic>

0000000080006016 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006016:	7119                	addi	sp,sp,-128
    80006018:	fc86                	sd	ra,120(sp)
    8000601a:	f8a2                	sd	s0,112(sp)
    8000601c:	f4a6                	sd	s1,104(sp)
    8000601e:	f0ca                	sd	s2,96(sp)
    80006020:	ecce                	sd	s3,88(sp)
    80006022:	e8d2                	sd	s4,80(sp)
    80006024:	e4d6                	sd	s5,72(sp)
    80006026:	e0da                	sd	s6,64(sp)
    80006028:	fc5e                	sd	s7,56(sp)
    8000602a:	f862                	sd	s8,48(sp)
    8000602c:	f466                	sd	s9,40(sp)
    8000602e:	f06a                	sd	s10,32(sp)
    80006030:	ec6e                	sd	s11,24(sp)
    80006032:	0100                	addi	s0,sp,128
    80006034:	8aaa                	mv	s5,a0
    80006036:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006038:	00c52c83          	lw	s9,12(a0)
    8000603c:	001c9c9b          	slliw	s9,s9,0x1
    80006040:	1c82                	slli	s9,s9,0x20
    80006042:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006046:	0001f517          	auipc	a0,0x1f
    8000604a:	0e250513          	addi	a0,a0,226 # 80025128 <disk+0x2128>
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	b74080e7          	jalr	-1164(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006056:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006058:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000605a:	0001dc17          	auipc	s8,0x1d
    8000605e:	fa6c0c13          	addi	s8,s8,-90 # 80023000 <disk>
    80006062:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006064:	4b0d                	li	s6,3
    80006066:	a0ad                	j	800060d0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006068:	00fc0733          	add	a4,s8,a5
    8000606c:	975e                	add	a4,a4,s7
    8000606e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006072:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006074:	0207c563          	bltz	a5,8000609e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006078:	2905                	addiw	s2,s2,1
    8000607a:	0611                	addi	a2,a2,4
    8000607c:	19690d63          	beq	s2,s6,80006216 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006080:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006082:	0001f717          	auipc	a4,0x1f
    80006086:	f9670713          	addi	a4,a4,-106 # 80025018 <disk+0x2018>
    8000608a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000608c:	00074683          	lbu	a3,0(a4)
    80006090:	fee1                	bnez	a3,80006068 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006092:	2785                	addiw	a5,a5,1
    80006094:	0705                	addi	a4,a4,1
    80006096:	fe979be3          	bne	a5,s1,8000608c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000609a:	57fd                	li	a5,-1
    8000609c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000609e:	01205d63          	blez	s2,800060b8 <virtio_disk_rw+0xa2>
    800060a2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060a4:	000a2503          	lw	a0,0(s4)
    800060a8:	00000097          	auipc	ra,0x0
    800060ac:	d8e080e7          	jalr	-626(ra) # 80005e36 <free_desc>
      for(int j = 0; j < i; j++)
    800060b0:	2d85                	addiw	s11,s11,1
    800060b2:	0a11                	addi	s4,s4,4
    800060b4:	ffb918e3          	bne	s2,s11,800060a4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060b8:	0001f597          	auipc	a1,0x1f
    800060bc:	07058593          	addi	a1,a1,112 # 80025128 <disk+0x2128>
    800060c0:	0001f517          	auipc	a0,0x1f
    800060c4:	f5850513          	addi	a0,a0,-168 # 80025018 <disk+0x2018>
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	f7e080e7          	jalr	-130(ra) # 80002046 <sleep>
  for(int i = 0; i < 3; i++){
    800060d0:	f8040a13          	addi	s4,s0,-128
{
    800060d4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060d6:	894e                	mv	s2,s3
    800060d8:	b765                	j	80006080 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060da:	0001f697          	auipc	a3,0x1f
    800060de:	f266b683          	ld	a3,-218(a3) # 80025000 <disk+0x2000>
    800060e2:	96ba                	add	a3,a3,a4
    800060e4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060e8:	0001d817          	auipc	a6,0x1d
    800060ec:	f1880813          	addi	a6,a6,-232 # 80023000 <disk>
    800060f0:	0001f697          	auipc	a3,0x1f
    800060f4:	f1068693          	addi	a3,a3,-240 # 80025000 <disk+0x2000>
    800060f8:	6290                	ld	a2,0(a3)
    800060fa:	963a                	add	a2,a2,a4
    800060fc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006100:	0015e593          	ori	a1,a1,1
    80006104:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006108:	f8842603          	lw	a2,-120(s0)
    8000610c:	628c                	ld	a1,0(a3)
    8000610e:	972e                	add	a4,a4,a1
    80006110:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006114:	20050593          	addi	a1,a0,512
    80006118:	0592                	slli	a1,a1,0x4
    8000611a:	95c2                	add	a1,a1,a6
    8000611c:	577d                	li	a4,-1
    8000611e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006122:	00461713          	slli	a4,a2,0x4
    80006126:	6290                	ld	a2,0(a3)
    80006128:	963a                	add	a2,a2,a4
    8000612a:	03078793          	addi	a5,a5,48
    8000612e:	97c2                	add	a5,a5,a6
    80006130:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006132:	629c                	ld	a5,0(a3)
    80006134:	97ba                	add	a5,a5,a4
    80006136:	4605                	li	a2,1
    80006138:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000613a:	629c                	ld	a5,0(a3)
    8000613c:	97ba                	add	a5,a5,a4
    8000613e:	4809                	li	a6,2
    80006140:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006144:	629c                	ld	a5,0(a3)
    80006146:	973e                	add	a4,a4,a5
    80006148:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000614c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006150:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006154:	6698                	ld	a4,8(a3)
    80006156:	00275783          	lhu	a5,2(a4)
    8000615a:	8b9d                	andi	a5,a5,7
    8000615c:	0786                	slli	a5,a5,0x1
    8000615e:	97ba                	add	a5,a5,a4
    80006160:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006164:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006168:	6698                	ld	a4,8(a3)
    8000616a:	00275783          	lhu	a5,2(a4)
    8000616e:	2785                	addiw	a5,a5,1
    80006170:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006174:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006178:	100017b7          	lui	a5,0x10001
    8000617c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006180:	004aa783          	lw	a5,4(s5)
    80006184:	02c79163          	bne	a5,a2,800061a6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006188:	0001f917          	auipc	s2,0x1f
    8000618c:	fa090913          	addi	s2,s2,-96 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006190:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006192:	85ca                	mv	a1,s2
    80006194:	8556                	mv	a0,s5
    80006196:	ffffc097          	auipc	ra,0xffffc
    8000619a:	eb0080e7          	jalr	-336(ra) # 80002046 <sleep>
  while(b->disk == 1) {
    8000619e:	004aa783          	lw	a5,4(s5)
    800061a2:	fe9788e3          	beq	a5,s1,80006192 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800061a6:	f8042903          	lw	s2,-128(s0)
    800061aa:	20090793          	addi	a5,s2,512
    800061ae:	00479713          	slli	a4,a5,0x4
    800061b2:	0001d797          	auipc	a5,0x1d
    800061b6:	e4e78793          	addi	a5,a5,-434 # 80023000 <disk>
    800061ba:	97ba                	add	a5,a5,a4
    800061bc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061c0:	0001f997          	auipc	s3,0x1f
    800061c4:	e4098993          	addi	s3,s3,-448 # 80025000 <disk+0x2000>
    800061c8:	00491713          	slli	a4,s2,0x4
    800061cc:	0009b783          	ld	a5,0(s3)
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061d6:	854a                	mv	a0,s2
    800061d8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061dc:	00000097          	auipc	ra,0x0
    800061e0:	c5a080e7          	jalr	-934(ra) # 80005e36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061e4:	8885                	andi	s1,s1,1
    800061e6:	f0ed                	bnez	s1,800061c8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061e8:	0001f517          	auipc	a0,0x1f
    800061ec:	f4050513          	addi	a0,a0,-192 # 80025128 <disk+0x2128>
    800061f0:	ffffb097          	auipc	ra,0xffffb
    800061f4:	a86080e7          	jalr	-1402(ra) # 80000c76 <release>
}
    800061f8:	70e6                	ld	ra,120(sp)
    800061fa:	7446                	ld	s0,112(sp)
    800061fc:	74a6                	ld	s1,104(sp)
    800061fe:	7906                	ld	s2,96(sp)
    80006200:	69e6                	ld	s3,88(sp)
    80006202:	6a46                	ld	s4,80(sp)
    80006204:	6aa6                	ld	s5,72(sp)
    80006206:	6b06                	ld	s6,64(sp)
    80006208:	7be2                	ld	s7,56(sp)
    8000620a:	7c42                	ld	s8,48(sp)
    8000620c:	7ca2                	ld	s9,40(sp)
    8000620e:	7d02                	ld	s10,32(sp)
    80006210:	6de2                	ld	s11,24(sp)
    80006212:	6109                	addi	sp,sp,128
    80006214:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006216:	f8042503          	lw	a0,-128(s0)
    8000621a:	20050793          	addi	a5,a0,512
    8000621e:	0792                	slli	a5,a5,0x4
  if(write)
    80006220:	0001d817          	auipc	a6,0x1d
    80006224:	de080813          	addi	a6,a6,-544 # 80023000 <disk>
    80006228:	00f80733          	add	a4,a6,a5
    8000622c:	01a036b3          	snez	a3,s10
    80006230:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006234:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006238:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000623c:	7679                	lui	a2,0xffffe
    8000623e:	963e                	add	a2,a2,a5
    80006240:	0001f697          	auipc	a3,0x1f
    80006244:	dc068693          	addi	a3,a3,-576 # 80025000 <disk+0x2000>
    80006248:	6298                	ld	a4,0(a3)
    8000624a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000624c:	0a878593          	addi	a1,a5,168
    80006250:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006252:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006254:	6298                	ld	a4,0(a3)
    80006256:	9732                	add	a4,a4,a2
    80006258:	45c1                	li	a1,16
    8000625a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000625c:	6298                	ld	a4,0(a3)
    8000625e:	9732                	add	a4,a4,a2
    80006260:	4585                	li	a1,1
    80006262:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006266:	f8442703          	lw	a4,-124(s0)
    8000626a:	628c                	ld	a1,0(a3)
    8000626c:	962e                	add	a2,a2,a1
    8000626e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006272:	0712                	slli	a4,a4,0x4
    80006274:	6290                	ld	a2,0(a3)
    80006276:	963a                	add	a2,a2,a4
    80006278:	058a8593          	addi	a1,s5,88
    8000627c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000627e:	6294                	ld	a3,0(a3)
    80006280:	96ba                	add	a3,a3,a4
    80006282:	40000613          	li	a2,1024
    80006286:	c690                	sw	a2,8(a3)
  if(write)
    80006288:	e40d19e3          	bnez	s10,800060da <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000628c:	0001f697          	auipc	a3,0x1f
    80006290:	d746b683          	ld	a3,-652(a3) # 80025000 <disk+0x2000>
    80006294:	96ba                	add	a3,a3,a4
    80006296:	4609                	li	a2,2
    80006298:	00c69623          	sh	a2,12(a3)
    8000629c:	b5b1                	j	800060e8 <virtio_disk_rw+0xd2>

000000008000629e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000629e:	1101                	addi	sp,sp,-32
    800062a0:	ec06                	sd	ra,24(sp)
    800062a2:	e822                	sd	s0,16(sp)
    800062a4:	e426                	sd	s1,8(sp)
    800062a6:	e04a                	sd	s2,0(sp)
    800062a8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062aa:	0001f517          	auipc	a0,0x1f
    800062ae:	e7e50513          	addi	a0,a0,-386 # 80025128 <disk+0x2128>
    800062b2:	ffffb097          	auipc	ra,0xffffb
    800062b6:	910080e7          	jalr	-1776(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062ba:	10001737          	lui	a4,0x10001
    800062be:	533c                	lw	a5,96(a4)
    800062c0:	8b8d                	andi	a5,a5,3
    800062c2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062c4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062c8:	0001f797          	auipc	a5,0x1f
    800062cc:	d3878793          	addi	a5,a5,-712 # 80025000 <disk+0x2000>
    800062d0:	6b94                	ld	a3,16(a5)
    800062d2:	0207d703          	lhu	a4,32(a5)
    800062d6:	0026d783          	lhu	a5,2(a3)
    800062da:	06f70163          	beq	a4,a5,8000633c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062de:	0001d917          	auipc	s2,0x1d
    800062e2:	d2290913          	addi	s2,s2,-734 # 80023000 <disk>
    800062e6:	0001f497          	auipc	s1,0x1f
    800062ea:	d1a48493          	addi	s1,s1,-742 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062ee:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062f2:	6898                	ld	a4,16(s1)
    800062f4:	0204d783          	lhu	a5,32(s1)
    800062f8:	8b9d                	andi	a5,a5,7
    800062fa:	078e                	slli	a5,a5,0x3
    800062fc:	97ba                	add	a5,a5,a4
    800062fe:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006300:	20078713          	addi	a4,a5,512
    80006304:	0712                	slli	a4,a4,0x4
    80006306:	974a                	add	a4,a4,s2
    80006308:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000630c:	e731                	bnez	a4,80006358 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000630e:	20078793          	addi	a5,a5,512
    80006312:	0792                	slli	a5,a5,0x4
    80006314:	97ca                	add	a5,a5,s2
    80006316:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006318:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000631c:	ffffc097          	auipc	ra,0xffffc
    80006320:	eb6080e7          	jalr	-330(ra) # 800021d2 <wakeup>

    disk.used_idx += 1;
    80006324:	0204d783          	lhu	a5,32(s1)
    80006328:	2785                	addiw	a5,a5,1
    8000632a:	17c2                	slli	a5,a5,0x30
    8000632c:	93c1                	srli	a5,a5,0x30
    8000632e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006332:	6898                	ld	a4,16(s1)
    80006334:	00275703          	lhu	a4,2(a4)
    80006338:	faf71be3          	bne	a4,a5,800062ee <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000633c:	0001f517          	auipc	a0,0x1f
    80006340:	dec50513          	addi	a0,a0,-532 # 80025128 <disk+0x2128>
    80006344:	ffffb097          	auipc	ra,0xffffb
    80006348:	932080e7          	jalr	-1742(ra) # 80000c76 <release>
}
    8000634c:	60e2                	ld	ra,24(sp)
    8000634e:	6442                	ld	s0,16(sp)
    80006350:	64a2                	ld	s1,8(sp)
    80006352:	6902                	ld	s2,0(sp)
    80006354:	6105                	addi	sp,sp,32
    80006356:	8082                	ret
      panic("virtio_disk_intr status");
    80006358:	00002517          	auipc	a0,0x2
    8000635c:	60050513          	addi	a0,a0,1536 # 80008958 <syscalls+0x3b0>
    80006360:	ffffa097          	auipc	ra,0xffffa
    80006364:	1ca080e7          	jalr	458(ra) # 8000052a <panic>
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
	...
