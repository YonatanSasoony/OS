
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
    80000068:	28c78793          	addi	a5,a5,652 # 800062f0 <timervec>
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
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	7b4080e7          	jalr	1972(ra) # 800028d2 <either_copyin>
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
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	802080e7          	jalr	-2046(ra) # 800019b4 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	2ea080e7          	jalr	746(ra) # 800024ac <sleep>
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
    80000202:	67c080e7          	jalr	1660(ra) # 8000287a <either_copyout>
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
    8000021e:	a6e080e7          	jalr	-1426(ra) # 80000c88 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
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
    800002e2:	64c080e7          	jalr	1612(ra) # 8000292a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
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
    80000436:	208080e7          	jalr	520(ra) # 8000263a <wakeup>
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
    8000055c:	dc850513          	addi	a0,a0,-568 # 80008320 <digits+0x2e0>
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
    80000882:	dbc080e7          	jalr	-580(ra) # 8000263a <wakeup>
    
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
    8000090e:	ba2080e7          	jalr	-1118(ra) # 800024ac <sleep>
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
    80000a06:	2e0080e7          	jalr	736(ra) # 80000ce2 <memset>

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
    80000a2c:	260080e7          	jalr	608(ra) # 80000c88 <release>
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
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
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
    80000b60:	e3c080e7          	jalr	-452(ra) # 80001998 <mycpu>
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
    80000b92:	e0a080e7          	jalr	-502(ra) # 80001998 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dfe080e7          	jalr	-514(ra) # 80001998 <mycpu>
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
    80000bb6:	de6080e7          	jalr	-538(ra) # 80001998 <mycpu>
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
    80000bf6:	da6080e7          	jalr	-602(ra) # 80001998 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    printf("PANIC-%s",lk->name);
    80000c06:	648c                	ld	a1,8(s1)
    80000c08:	00007517          	auipc	a0,0x7
    80000c0c:	46850513          	addi	a0,a0,1128 # 80008070 <digits+0x30>
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	964080e7          	jalr	-1692(ra) # 80000574 <printf>
    panic("acquire");
    80000c18:	00007517          	auipc	a0,0x7
    80000c1c:	46850513          	addi	a0,a0,1128 # 80008080 <digits+0x40>
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
    80000c34:	d68080e7          	jalr	-664(ra) # 80001998 <mycpu>
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
    80000c68:	00007517          	auipc	a0,0x7
    80000c6c:	42050513          	addi	a0,a0,1056 # 80008088 <digits+0x48>
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	8ba080e7          	jalr	-1862(ra) # 8000052a <panic>
    panic("pop_off");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	42850513          	addi	a0,a0,1064 # 800080a0 <digits+0x60>
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
    printf("PANIC-%s",lk->name);
    80000cc0:	648c                	ld	a1,8(s1)
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3ae50513          	addi	a0,a0,942 # 80008070 <digits+0x30>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	8aa080e7          	jalr	-1878(ra) # 80000574 <printf>
    panic("release");
    80000cd2:	00007517          	auipc	a0,0x7
    80000cd6:	3d650513          	addi	a0,a0,982 # 800080a8 <digits+0x68>
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
    80000e9c:	af0080e7          	jalr	-1296(ra) # 80001988 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea0:	00008717          	auipc	a4,0x8
    80000ea4:	17870713          	addi	a4,a4,376 # 80009018 <started>
  if(cpuid() == 0){
    80000ea8:	c939                	beqz	a0,80000efe <main+0x6e>
    while(started == 0)
    80000eaa:	431c                	lw	a5,0(a4)
    80000eac:	2781                	sext.w	a5,a5
    80000eae:	dff5                	beqz	a5,80000eaa <main+0x1a>
      ;
    __sync_synchronize();
    80000eb0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb4:	00001097          	auipc	ra,0x1
    80000eb8:	ad4080e7          	jalr	-1324(ra) # 80001988 <cpuid>
    80000ebc:	85aa                	mv	a1,a0
    80000ebe:	00007517          	auipc	a0,0x7
    80000ec2:	20a50513          	addi	a0,a0,522 # 800080c8 <digits+0x88>
    80000ec6:	fffff097          	auipc	ra,0xfffff
    80000eca:	6ae080e7          	jalr	1710(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000ece:	00000097          	auipc	ra,0x0
    80000ed2:	0e8080e7          	jalr	232(ra) # 80000fb6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed6:	00002097          	auipc	ra,0x2
    80000eda:	dc4080e7          	jalr	-572(ra) # 80002c9a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00005097          	auipc	ra,0x5
    80000ee2:	452080e7          	jalr	1106(ra) # 80006330 <plicinithart>
    
  }
  printf("BLA\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1fa50513          	addi	a0,a0,506 # 800080e0 <digits+0xa0>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	686080e7          	jalr	1670(ra) # 80000574 <printf>
  scheduler();        
    80000ef6:	00001097          	auipc	ra,0x1
    80000efa:	1da080e7          	jalr	474(ra) # 800020d0 <scheduler>
    consoleinit();
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	53e080e7          	jalr	1342(ra) # 8000043c <consoleinit>
    printfinit();
    80000f06:	00000097          	auipc	ra,0x0
    80000f0a:	84e080e7          	jalr	-1970(ra) # 80000754 <printfinit>
    printf("\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	41250513          	addi	a0,a0,1042 # 80008320 <digits+0x2e0>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	65e080e7          	jalr	1630(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	19250513          	addi	a0,a0,402 # 800080b0 <digits+0x70>
    80000f26:	fffff097          	auipc	ra,0xfffff
    80000f2a:	64e080e7          	jalr	1614(ra) # 80000574 <printf>
    printf("\n");
    80000f2e:	00007517          	auipc	a0,0x7
    80000f32:	3f250513          	addi	a0,a0,1010 # 80008320 <digits+0x2e0>
    80000f36:	fffff097          	auipc	ra,0xfffff
    80000f3a:	63e080e7          	jalr	1598(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f3e:	00000097          	auipc	ra,0x0
    80000f42:	b58080e7          	jalr	-1192(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	310080e7          	jalr	784(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	068080e7          	jalr	104(ra) # 80000fb6 <kvminithart>
    procinit();      // process table
    80000f56:	00001097          	auipc	ra,0x1
    80000f5a:	980080e7          	jalr	-1664(ra) # 800018d6 <procinit>
    trapinit();      // trap vectors
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	d14080e7          	jalr	-748(ra) # 80002c72 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f66:	00002097          	auipc	ra,0x2
    80000f6a:	d34080e7          	jalr	-716(ra) # 80002c9a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	3ac080e7          	jalr	940(ra) # 8000631a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	3ba080e7          	jalr	954(ra) # 80006330 <plicinithart>
    binit();         // buffer cache
    80000f7e:	00002097          	auipc	ra,0x2
    80000f82:	552080e7          	jalr	1362(ra) # 800034d0 <binit>
    iinit();         // inode cache
    80000f86:	00003097          	auipc	ra,0x3
    80000f8a:	be4080e7          	jalr	-1052(ra) # 80003b6a <iinit>
    fileinit();      // file table
    80000f8e:	00004097          	auipc	ra,0x4
    80000f92:	b92080e7          	jalr	-1134(ra) # 80004b20 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f96:	00005097          	auipc	ra,0x5
    80000f9a:	4bc080e7          	jalr	1212(ra) # 80006452 <virtio_disk_init>
    userinit();      // first user process
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	d58080e7          	jalr	-680(ra) # 80001cf6 <userinit>
    __sync_synchronize();
    80000fa6:	0ff0000f          	fence
    started = 1;
    80000faa:	4785                	li	a5,1
    80000fac:	00008717          	auipc	a4,0x8
    80000fb0:	06f72623          	sw	a5,108(a4) # 80009018 <started>
    80000fb4:	bf0d                	j	80000ee6 <main+0x56>

0000000080000fb6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fb6:	1141                	addi	sp,sp,-16
    80000fb8:	e422                	sd	s0,8(sp)
    80000fba:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fbc:	00008797          	auipc	a5,0x8
    80000fc0:	0647b783          	ld	a5,100(a5) # 80009020 <kernel_pagetable>
    80000fc4:	83b1                	srli	a5,a5,0xc
    80000fc6:	577d                	li	a4,-1
    80000fc8:	177e                	slli	a4,a4,0x3f
    80000fca:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fcc:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fd0:	12000073          	sfence.vma
  sfence_vma();
}
    80000fd4:	6422                	ld	s0,8(sp)
    80000fd6:	0141                	addi	sp,sp,16
    80000fd8:	8082                	ret

0000000080000fda <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fda:	7139                	addi	sp,sp,-64
    80000fdc:	fc06                	sd	ra,56(sp)
    80000fde:	f822                	sd	s0,48(sp)
    80000fe0:	f426                	sd	s1,40(sp)
    80000fe2:	f04a                	sd	s2,32(sp)
    80000fe4:	ec4e                	sd	s3,24(sp)
    80000fe6:	e852                	sd	s4,16(sp)
    80000fe8:	e456                	sd	s5,8(sp)
    80000fea:	e05a                	sd	s6,0(sp)
    80000fec:	0080                	addi	s0,sp,64
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	89ae                	mv	s3,a1
    80000ff2:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ff4:	57fd                	li	a5,-1
    80000ff6:	83e9                	srli	a5,a5,0x1a
    80000ff8:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ffa:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ffc:	04b7f263          	bgeu	a5,a1,80001040 <walk+0x66>
    panic("walk");
    80001000:	00007517          	auipc	a0,0x7
    80001004:	0e850513          	addi	a0,a0,232 # 800080e8 <digits+0xa8>
    80001008:	fffff097          	auipc	ra,0xfffff
    8000100c:	522080e7          	jalr	1314(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001010:	060a8663          	beqz	s5,8000107c <walk+0xa2>
    80001014:	00000097          	auipc	ra,0x0
    80001018:	abe080e7          	jalr	-1346(ra) # 80000ad2 <kalloc>
    8000101c:	84aa                	mv	s1,a0
    8000101e:	c529                	beqz	a0,80001068 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001020:	6605                	lui	a2,0x1
    80001022:	4581                	li	a1,0
    80001024:	00000097          	auipc	ra,0x0
    80001028:	cbe080e7          	jalr	-834(ra) # 80000ce2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000102c:	00c4d793          	srli	a5,s1,0xc
    80001030:	07aa                	slli	a5,a5,0xa
    80001032:	0017e793          	ori	a5,a5,1
    80001036:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000103a:	3a5d                	addiw	s4,s4,-9
    8000103c:	036a0063          	beq	s4,s6,8000105c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001040:	0149d933          	srl	s2,s3,s4
    80001044:	1ff97913          	andi	s2,s2,511
    80001048:	090e                	slli	s2,s2,0x3
    8000104a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000104c:	00093483          	ld	s1,0(s2)
    80001050:	0014f793          	andi	a5,s1,1
    80001054:	dfd5                	beqz	a5,80001010 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001056:	80a9                	srli	s1,s1,0xa
    80001058:	04b2                	slli	s1,s1,0xc
    8000105a:	b7c5                	j	8000103a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000105c:	00c9d513          	srli	a0,s3,0xc
    80001060:	1ff57513          	andi	a0,a0,511
    80001064:	050e                	slli	a0,a0,0x3
    80001066:	9526                	add	a0,a0,s1
}
    80001068:	70e2                	ld	ra,56(sp)
    8000106a:	7442                	ld	s0,48(sp)
    8000106c:	74a2                	ld	s1,40(sp)
    8000106e:	7902                	ld	s2,32(sp)
    80001070:	69e2                	ld	s3,24(sp)
    80001072:	6a42                	ld	s4,16(sp)
    80001074:	6aa2                	ld	s5,8(sp)
    80001076:	6b02                	ld	s6,0(sp)
    80001078:	6121                	addi	sp,sp,64
    8000107a:	8082                	ret
        return 0;
    8000107c:	4501                	li	a0,0
    8000107e:	b7ed                	j	80001068 <walk+0x8e>

0000000080001080 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001080:	57fd                	li	a5,-1
    80001082:	83e9                	srli	a5,a5,0x1a
    80001084:	00b7f463          	bgeu	a5,a1,8000108c <walkaddr+0xc>
    return 0;
    80001088:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000108a:	8082                	ret
{
    8000108c:	1141                	addi	sp,sp,-16
    8000108e:	e406                	sd	ra,8(sp)
    80001090:	e022                	sd	s0,0(sp)
    80001092:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001094:	4601                	li	a2,0
    80001096:	00000097          	auipc	ra,0x0
    8000109a:	f44080e7          	jalr	-188(ra) # 80000fda <walk>
  if(pte == 0)
    8000109e:	c105                	beqz	a0,800010be <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010a0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010a2:	0117f693          	andi	a3,a5,17
    800010a6:	4745                	li	a4,17
    return 0;
    800010a8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010aa:	00e68663          	beq	a3,a4,800010b6 <walkaddr+0x36>
}
    800010ae:	60a2                	ld	ra,8(sp)
    800010b0:	6402                	ld	s0,0(sp)
    800010b2:	0141                	addi	sp,sp,16
    800010b4:	8082                	ret
  pa = PTE2PA(*pte);
    800010b6:	00a7d513          	srli	a0,a5,0xa
    800010ba:	0532                	slli	a0,a0,0xc
  return pa;
    800010bc:	bfcd                	j	800010ae <walkaddr+0x2e>
    return 0;
    800010be:	4501                	li	a0,0
    800010c0:	b7fd                	j	800010ae <walkaddr+0x2e>

00000000800010c2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010c2:	715d                	addi	sp,sp,-80
    800010c4:	e486                	sd	ra,72(sp)
    800010c6:	e0a2                	sd	s0,64(sp)
    800010c8:	fc26                	sd	s1,56(sp)
    800010ca:	f84a                	sd	s2,48(sp)
    800010cc:	f44e                	sd	s3,40(sp)
    800010ce:	f052                	sd	s4,32(sp)
    800010d0:	ec56                	sd	s5,24(sp)
    800010d2:	e85a                	sd	s6,16(sp)
    800010d4:	e45e                	sd	s7,8(sp)
    800010d6:	0880                	addi	s0,sp,80
    800010d8:	8aaa                	mv	s5,a0
    800010da:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010dc:	777d                	lui	a4,0xfffff
    800010de:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010e2:	167d                	addi	a2,a2,-1
    800010e4:	00b609b3          	add	s3,a2,a1
    800010e8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ec:	893e                	mv	s2,a5
    800010ee:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010f2:	6b85                	lui	s7,0x1
    800010f4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f8:	4605                	li	a2,1
    800010fa:	85ca                	mv	a1,s2
    800010fc:	8556                	mv	a0,s5
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	edc080e7          	jalr	-292(ra) # 80000fda <walk>
    80001106:	c51d                	beqz	a0,80001134 <mappages+0x72>
    if(*pte & PTE_V)
    80001108:	611c                	ld	a5,0(a0)
    8000110a:	8b85                	andi	a5,a5,1
    8000110c:	ef81                	bnez	a5,80001124 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000110e:	80b1                	srli	s1,s1,0xc
    80001110:	04aa                	slli	s1,s1,0xa
    80001112:	0164e4b3          	or	s1,s1,s6
    80001116:	0014e493          	ori	s1,s1,1
    8000111a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000111c:	03390863          	beq	s2,s3,8000114c <mappages+0x8a>
    a += PGSIZE;
    80001120:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001122:	bfc9                	j	800010f4 <mappages+0x32>
      panic("remap");
    80001124:	00007517          	auipc	a0,0x7
    80001128:	fcc50513          	addi	a0,a0,-52 # 800080f0 <digits+0xb0>
    8000112c:	fffff097          	auipc	ra,0xfffff
    80001130:	3fe080e7          	jalr	1022(ra) # 8000052a <panic>
      return -1;
    80001134:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001136:	60a6                	ld	ra,72(sp)
    80001138:	6406                	ld	s0,64(sp)
    8000113a:	74e2                	ld	s1,56(sp)
    8000113c:	7942                	ld	s2,48(sp)
    8000113e:	79a2                	ld	s3,40(sp)
    80001140:	7a02                	ld	s4,32(sp)
    80001142:	6ae2                	ld	s5,24(sp)
    80001144:	6b42                	ld	s6,16(sp)
    80001146:	6ba2                	ld	s7,8(sp)
    80001148:	6161                	addi	sp,sp,80
    8000114a:	8082                	ret
  return 0;
    8000114c:	4501                	li	a0,0
    8000114e:	b7e5                	j	80001136 <mappages+0x74>

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f64080e7          	jalr	-156(ra) # 800010c2 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3b2080e7          	jalr	946(ra) # 8000052a <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	946080e7          	jalr	-1722(ra) # 80000ad2 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b48080e7          	jalr	-1208(ra) # 80000ce2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	600080e7          	jalr	1536(ra) # 80001840 <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e263          	bltu	a1,s3,80001306 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	266080e7          	jalr	614(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	256080e7          	jalr	598(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	246080e7          	jalr	582(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	236080e7          	jalr	566(ra) # 8000052a <panic>
    *pte = 0;
    800012fc:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001300:	995a                	add	s2,s2,s6
    80001302:	fb3972e3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001306:	4601                	li	a2,0
    80001308:	85ca                	mv	a1,s2
    8000130a:	8552                	mv	a0,s4
    8000130c:	00000097          	auipc	ra,0x0
    80001310:	cce080e7          	jalr	-818(ra) # 80000fda <walk>
    80001314:	84aa                	mv	s1,a0
    80001316:	d95d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001318:	6108                	ld	a0,0(a0)
    8000131a:	00157793          	andi	a5,a0,1
    8000131e:	dfdd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001320:	3ff57793          	andi	a5,a0,1023
    80001324:	fd7784e3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001328:	fc0a8ae3          	beqz	s5,800012fc <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000132c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000132e:	0532                	slli	a0,a0,0xc
    80001330:	fffff097          	auipc	ra,0xfffff
    80001334:	6a6080e7          	jalr	1702(ra) # 800009d6 <kfree>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	78e080e7          	jalr	1934(ra) # 80000ad2 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98e080e7          	jalr	-1650(ra) # 80000ce2 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	74e080e7          	jalr	1870(ra) # 80000ad2 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	950080e7          	jalr	-1712(ra) # 80000ce2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d1e080e7          	jalr	-738(ra) # 800010c2 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98c080e7          	jalr	-1652(ra) # 80000d3e <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	158080e7          	jalr	344(ra) # 8000052a <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	684080e7          	jalr	1668(ra) # 80000ad2 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	884080e7          	jalr	-1916(ra) # 80000ce2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c52080e7          	jalr	-942(ra) # 800010c2 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	52c080e7          	jalr	1324(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	016080e7          	jalr	22(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4b8080e7          	jalr	1208(ra) # 800009d6 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a46080e7          	jalr	-1466(ra) # 80000fda <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	520080e7          	jalr	1312(ra) # 80000ad2 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77c080e7          	jalr	1916(ra) # 80000d3e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	aee080e7          	jalr	-1298(ra) # 800010c2 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f3a080e7          	jalr	-198(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f2a080e7          	jalr	-214(ra) # 8000052a <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3cc080e7          	jalr	972(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	990080e7          	jalr	-1648(ra) # 80000fda <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ec0080e7          	jalr	-320(ra) # 8000052a <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	698080e7          	jalr	1688(ra) # 80000d3e <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9bc080e7          	jalr	-1604(ra) # 80001080 <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	caa5                	beqz	a3,8000176e <copyin+0x70>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a01d                	j	8000174a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	018505b3          	add	a1,a0,s8
    8000172a:	0004861b          	sext.w	a2,s1
    8000172e:	412585b3          	sub	a1,a1,s2
    80001732:	8552                	mv	a0,s4
    80001734:	fffff097          	auipc	ra,0xfffff
    80001738:	60a080e7          	jalr	1546(ra) # 80000d3e <memmove>

    len -= n;
    8000173c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001740:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001742:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001746:	02098263          	beqz	s3,8000176a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000174a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174e:	85ca                	mv	a1,s2
    80001750:	855a                	mv	a0,s6
    80001752:	00000097          	auipc	ra,0x0
    80001756:	92e080e7          	jalr	-1746(ra) # 80001080 <walkaddr>
    if(pa0 == 0)
    8000175a:	cd01                	beqz	a0,80001772 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000175c:	418904b3          	sub	s1,s2,s8
    80001760:	94d6                	add	s1,s1,s5
    if(n > len)
    80001762:	fc99f2e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001766:	84ce                	mv	s1,s3
    80001768:	bf7d                	j	80001726 <copyin+0x28>
  }
  return 0;
    8000176a:	4501                	li	a0,0
    8000176c:	a021                	j	80001774 <copyin+0x76>
    8000176e:	4501                	li	a0,0
}
    80001770:	8082                	ret
      return -1;
    80001772:	557d                	li	a0,-1
}
    80001774:	60a6                	ld	ra,72(sp)
    80001776:	6406                	ld	s0,64(sp)
    80001778:	74e2                	ld	s1,56(sp)
    8000177a:	7942                	ld	s2,48(sp)
    8000177c:	79a2                	ld	s3,40(sp)
    8000177e:	7a02                	ld	s4,32(sp)
    80001780:	6ae2                	ld	s5,24(sp)
    80001782:	6b42                	ld	s6,16(sp)
    80001784:	6ba2                	ld	s7,8(sp)
    80001786:	6c02                	ld	s8,0(sp)
    80001788:	6161                	addi	sp,sp,80
    8000178a:	8082                	ret

000000008000178c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178c:	c6c5                	beqz	a3,80001834 <copyinstr+0xa8>
{
    8000178e:	715d                	addi	sp,sp,-80
    80001790:	e486                	sd	ra,72(sp)
    80001792:	e0a2                	sd	s0,64(sp)
    80001794:	fc26                	sd	s1,56(sp)
    80001796:	f84a                	sd	s2,48(sp)
    80001798:	f44e                	sd	s3,40(sp)
    8000179a:	f052                	sd	s4,32(sp)
    8000179c:	ec56                	sd	s5,24(sp)
    8000179e:	e85a                	sd	s6,16(sp)
    800017a0:	e45e                	sd	s7,8(sp)
    800017a2:	0880                	addi	s0,sp,80
    800017a4:	8a2a                	mv	s4,a0
    800017a6:	8b2e                	mv	s6,a1
    800017a8:	8bb2                	mv	s7,a2
    800017aa:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ac:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ae:	6985                	lui	s3,0x1
    800017b0:	a035                	j	800017dc <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b8:	0017b793          	seqz	a5,a5
    800017bc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c0:	60a6                	ld	ra,72(sp)
    800017c2:	6406                	ld	s0,64(sp)
    800017c4:	74e2                	ld	s1,56(sp)
    800017c6:	7942                	ld	s2,48(sp)
    800017c8:	79a2                	ld	s3,40(sp)
    800017ca:	7a02                	ld	s4,32(sp)
    800017cc:	6ae2                	ld	s5,24(sp)
    800017ce:	6b42                	ld	s6,16(sp)
    800017d0:	6ba2                	ld	s7,8(sp)
    800017d2:	6161                	addi	sp,sp,80
    800017d4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017da:	c8a9                	beqz	s1,8000182c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017dc:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e0:	85ca                	mv	a1,s2
    800017e2:	8552                	mv	a0,s4
    800017e4:	00000097          	auipc	ra,0x0
    800017e8:	89c080e7          	jalr	-1892(ra) # 80001080 <walkaddr>
    if(pa0 == 0)
    800017ec:	c131                	beqz	a0,80001830 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ee:	41790833          	sub	a6,s2,s7
    800017f2:	984e                	add	a6,a6,s3
    if(n > max)
    800017f4:	0104f363          	bgeu	s1,a6,800017fa <copyinstr+0x6e>
    800017f8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017fa:	955e                	add	a0,a0,s7
    800017fc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001800:	fc080be3          	beqz	a6,800017d6 <copyinstr+0x4a>
    80001804:	985a                	add	a6,a6,s6
    80001806:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001808:	41650633          	sub	a2,a0,s6
    8000180c:	14fd                	addi	s1,s1,-1
    8000180e:	9b26                	add	s6,s6,s1
    80001810:	00f60733          	add	a4,a2,a5
    80001814:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd3000>
    80001818:	df49                	beqz	a4,800017b2 <copyinstr+0x26>
        *dst = *p;
    8000181a:	00e78023          	sb	a4,0(a5)
      --max;
    8000181e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001822:	0785                	addi	a5,a5,1
    while(n > 0){
    80001824:	ff0796e3          	bne	a5,a6,80001810 <copyinstr+0x84>
      dst++;
    80001828:	8b42                	mv	s6,a6
    8000182a:	b775                	j	800017d6 <copyinstr+0x4a>
    8000182c:	4781                	li	a5,0
    8000182e:	b769                	j	800017b8 <copyinstr+0x2c>
      return -1;
    80001830:	557d                	li	a0,-1
    80001832:	b779                	j	800017c0 <copyinstr+0x34>
  int got_null = 0;
    80001834:	4781                	li	a5,0
  if(got_null){
    80001836:	0017b793          	seqz	a5,a5
    8000183a:	40f00533          	neg	a0,a5
}
    8000183e:	8082                	ret

0000000080001840 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001840:	7139                	addi	sp,sp,-64
    80001842:	fc06                	sd	ra,56(sp)
    80001844:	f822                	sd	s0,48(sp)
    80001846:	f426                	sd	s1,40(sp)
    80001848:	f04a                	sd	s2,32(sp)
    8000184a:	ec4e                	sd	s3,24(sp)
    8000184c:	e852                	sd	s4,16(sp)
    8000184e:	e456                	sd	s5,8(sp)
    80001850:	e05a                	sd	s6,0(sp)
    80001852:	0080                	addi	s0,sp,64
    80001854:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001856:	00010497          	auipc	s1,0x10
    8000185a:	e7a48493          	addi	s1,s1,-390 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185e:	8b26                	mv	s6,s1
    80001860:	00006a97          	auipc	s5,0x6
    80001864:	7a0a8a93          	addi	s5,s5,1952 # 80008000 <etext>
    80001868:	04000937          	lui	s2,0x4000
    8000186c:	197d                	addi	s2,s2,-1
    8000186e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001870:	0001ca17          	auipc	s4,0x1c
    80001874:	e60a0a13          	addi	s4,s4,-416 # 8001d6d0 <tickslock>
    char *pa = kalloc();
    80001878:	fffff097          	auipc	ra,0xfffff
    8000187c:	25a080e7          	jalr	602(ra) # 80000ad2 <kalloc>
    80001880:	862a                	mv	a2,a0
    if(pa == 0)
    80001882:	c131                	beqz	a0,800018c6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001884:	416485b3          	sub	a1,s1,s6
    80001888:	85a1                	srai	a1,a1,0x8
    8000188a:	000ab783          	ld	a5,0(s5)
    8000188e:	02f585b3          	mul	a1,a1,a5
    80001892:	2585                	addiw	a1,a1,1
    80001894:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001898:	4719                	li	a4,6
    8000189a:	6685                	lui	a3,0x1
    8000189c:	40b905b3          	sub	a1,s2,a1
    800018a0:	854e                	mv	a0,s3
    800018a2:	00000097          	auipc	ra,0x0
    800018a6:	8ae080e7          	jalr	-1874(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018aa:	30048493          	addi	s1,s1,768
    800018ae:	fd4495e3          	bne	s1,s4,80001878 <proc_mapstacks+0x38>
  }
}
    800018b2:	70e2                	ld	ra,56(sp)
    800018b4:	7442                	ld	s0,48(sp)
    800018b6:	74a2                	ld	s1,40(sp)
    800018b8:	7902                	ld	s2,32(sp)
    800018ba:	69e2                	ld	s3,24(sp)
    800018bc:	6a42                	ld	s4,16(sp)
    800018be:	6aa2                	ld	s5,8(sp)
    800018c0:	6b02                	ld	s6,0(sp)
    800018c2:	6121                	addi	sp,sp,64
    800018c4:	8082                	ret
      panic("kalloc");
    800018c6:	00007517          	auipc	a0,0x7
    800018ca:	91250513          	addi	a0,a0,-1774 # 800081d8 <digits+0x198>
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	c5c080e7          	jalr	-932(ra) # 8000052a <panic>

00000000800018d6 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d6:	7139                	addi	sp,sp,-64
    800018d8:	fc06                	sd	ra,56(sp)
    800018da:	f822                	sd	s0,48(sp)
    800018dc:	f426                	sd	s1,40(sp)
    800018de:	f04a                	sd	s2,32(sp)
    800018e0:	ec4e                	sd	s3,24(sp)
    800018e2:	e852                	sd	s4,16(sp)
    800018e4:	e456                	sd	s5,8(sp)
    800018e6:	e05a                	sd	s6,0(sp)
    800018e8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ea:	00007597          	auipc	a1,0x7
    800018ee:	8f658593          	addi	a1,a1,-1802 # 800081e0 <digits+0x1a0>
    800018f2:	00010517          	auipc	a0,0x10
    800018f6:	9ae50513          	addi	a0,a0,-1618 # 800112a0 <pid_lock>
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	238080e7          	jalr	568(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001902:	00007597          	auipc	a1,0x7
    80001906:	8e658593          	addi	a1,a1,-1818 # 800081e8 <digits+0x1a8>
    8000190a:	00010517          	auipc	a0,0x10
    8000190e:	9ae50513          	addi	a0,a0,-1618 # 800112b8 <wait_lock>
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	220080e7          	jalr	544(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191a:	00010497          	auipc	s1,0x10
    8000191e:	db648493          	addi	s1,s1,-586 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001922:	00007b17          	auipc	s6,0x7
    80001926:	8d6b0b13          	addi	s6,s6,-1834 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000192a:	8aa6                	mv	s5,s1
    8000192c:	00006a17          	auipc	s4,0x6
    80001930:	6d4a0a13          	addi	s4,s4,1748 # 80008000 <etext>
    80001934:	04000937          	lui	s2,0x4000
    80001938:	197d                	addi	s2,s2,-1
    8000193a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193c:	0001c997          	auipc	s3,0x1c
    80001940:	d9498993          	addi	s3,s3,-620 # 8001d6d0 <tickslock>
      initlock(&p->lock, "proc");
    80001944:	85da                	mv	a1,s6
    80001946:	8526                	mv	a0,s1
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	1ea080e7          	jalr	490(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001950:	415487b3          	sub	a5,s1,s5
    80001954:	87a1                	srai	a5,a5,0x8
    80001956:	000a3703          	ld	a4,0(s4)
    8000195a:	02e787b3          	mul	a5,a5,a4
    8000195e:	2785                	addiw	a5,a5,1
    80001960:	00d7979b          	slliw	a5,a5,0xd
    80001964:	40f907b3          	sub	a5,s2,a5
    80001968:	1cf4bc23          	sd	a5,472(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	30048493          	addi	s1,s1,768
    80001970:	fd349ae3          	bne	s1,s3,80001944 <procinit+0x6e>
  }
}
    80001974:	70e2                	ld	ra,56(sp)
    80001976:	7442                	ld	s0,48(sp)
    80001978:	74a2                	ld	s1,40(sp)
    8000197a:	7902                	ld	s2,32(sp)
    8000197c:	69e2                	ld	s3,24(sp)
    8000197e:	6a42                	ld	s4,16(sp)
    80001980:	6aa2                	ld	s5,8(sp)
    80001982:	6b02                	ld	s6,0(sp)
    80001984:	6121                	addi	sp,sp,64
    80001986:	8082                	ret

0000000080001988 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001988:	1141                	addi	sp,sp,-16
    8000198a:	e422                	sd	s0,8(sp)
    8000198c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001990:	2501                	sext.w	a0,a0
    80001992:	6422                	ld	s0,8(sp)
    80001994:	0141                	addi	sp,sp,16
    80001996:	8082                	ret

0000000080001998 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001998:	1141                	addi	sp,sp,-16
    8000199a:	e422                	sd	s0,8(sp)
    8000199c:	0800                	addi	s0,sp,16
    8000199e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a0:	2781                	sext.w	a5,a5
    800019a2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a4:	00010517          	auipc	a0,0x10
    800019a8:	92c50513          	addi	a0,a0,-1748 # 800112d0 <cpus>
    800019ac:	953e                	add	a0,a0,a5
    800019ae:	6422                	ld	s0,8(sp)
    800019b0:	0141                	addi	sp,sp,16
    800019b2:	8082                	ret

00000000800019b4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b4:	1101                	addi	sp,sp,-32
    800019b6:	ec06                	sd	ra,24(sp)
    800019b8:	e822                	sd	s0,16(sp)
    800019ba:	e426                	sd	s1,8(sp)
    800019bc:	1000                	addi	s0,sp,32
  push_off();
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	1b8080e7          	jalr	440(ra) # 80000b76 <push_off>
    800019c6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c8:	2781                	sext.w	a5,a5
    800019ca:	079e                	slli	a5,a5,0x7
    800019cc:	00010717          	auipc	a4,0x10
    800019d0:	8d470713          	addi	a4,a4,-1836 # 800112a0 <pid_lock>
    800019d4:	97ba                	add	a5,a5,a4
    800019d6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	250080e7          	jalr	592(ra) # 80000c28 <pop_off>
  return p;
}
    800019e0:	8526                	mv	a0,s1
    800019e2:	60e2                	ld	ra,24(sp)
    800019e4:	6442                	ld	s0,16(sp)
    800019e6:	64a2                	ld	s1,8(sp)
    800019e8:	6105                	addi	sp,sp,32
    800019ea:	8082                	ret

00000000800019ec <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ec:	1141                	addi	sp,sp,-16
    800019ee:	e406                	sd	ra,8(sp)
    800019f0:	e022                	sd	s0,0(sp)
    800019f2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f4:	00000097          	auipc	ra,0x0
    800019f8:	fc0080e7          	jalr	-64(ra) # 800019b4 <myproc>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	28c080e7          	jalr	652(ra) # 80000c88 <release>

  if (first) {
    80001a04:	00007797          	auipc	a5,0x7
    80001a08:	f5c7a783          	lw	a5,-164(a5) # 80008960 <first.1>
    80001a0c:	eb89                	bnez	a5,80001a1e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0e:	00001097          	auipc	ra,0x1
    80001a12:	2a4080e7          	jalr	676(ra) # 80002cb2 <usertrapret>
}
    80001a16:	60a2                	ld	ra,8(sp)
    80001a18:	6402                	ld	s0,0(sp)
    80001a1a:	0141                	addi	sp,sp,16
    80001a1c:	8082                	ret
    first = 0;
    80001a1e:	00007797          	auipc	a5,0x7
    80001a22:	f407a123          	sw	zero,-190(a5) # 80008960 <first.1>
    fsinit(ROOTDEV);
    80001a26:	4505                	li	a0,1
    80001a28:	00002097          	auipc	ra,0x2
    80001a2c:	0c2080e7          	jalr	194(ra) # 80003aea <fsinit>
    80001a30:	bff9                	j	80001a0e <forkret+0x22>

0000000080001a32 <allocpid>:
allocpid() {
    80001a32:	1101                	addi	sp,sp,-32
    80001a34:	ec06                	sd	ra,24(sp)
    80001a36:	e822                	sd	s0,16(sp)
    80001a38:	e426                	sd	s1,8(sp)
    80001a3a:	e04a                	sd	s2,0(sp)
    80001a3c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3e:	00010917          	auipc	s2,0x10
    80001a42:	86290913          	addi	s2,s2,-1950 # 800112a0 <pid_lock>
    80001a46:	854a                	mv	a0,s2
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	17a080e7          	jalr	378(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a50:	00007797          	auipc	a5,0x7
    80001a54:	f1478793          	addi	a5,a5,-236 # 80008964 <nextpid>
    80001a58:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5a:	0014871b          	addiw	a4,s1,1
    80001a5e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a60:	854a                	mv	a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	226080e7          	jalr	550(ra) # 80000c88 <release>
}
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	60e2                	ld	ra,24(sp)
    80001a6e:	6442                	ld	s0,16(sp)
    80001a70:	64a2                	ld	s1,8(sp)
    80001a72:	6902                	ld	s2,0(sp)
    80001a74:	6105                	addi	sp,sp,32
    80001a76:	8082                	ret

0000000080001a78 <proc_pagetable>:
{
    80001a78:	1101                	addi	sp,sp,-32
    80001a7a:	ec06                	sd	ra,24(sp)
    80001a7c:	e822                	sd	s0,16(sp)
    80001a7e:	e426                	sd	s1,8(sp)
    80001a80:	e04a                	sd	s2,0(sp)
    80001a82:	1000                	addi	s0,sp,32
    80001a84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a86:	00000097          	auipc	ra,0x0
    80001a8a:	8b4080e7          	jalr	-1868(ra) # 8000133a <uvmcreate>
    80001a8e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a90:	c121                	beqz	a0,80001ad0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a92:	4729                	li	a4,10
    80001a94:	00005697          	auipc	a3,0x5
    80001a98:	56c68693          	addi	a3,a3,1388 # 80007000 <_trampoline>
    80001a9c:	6605                	lui	a2,0x1
    80001a9e:	040005b7          	lui	a1,0x4000
    80001aa2:	15fd                	addi	a1,a1,-1
    80001aa4:	05b2                	slli	a1,a1,0xc
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	61c080e7          	jalr	1564(ra) # 800010c2 <mappages>
    80001aae:	02054863          	bltz	a0,80001ade <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab2:	4719                	li	a4,6
    80001ab4:	1f093683          	ld	a3,496(s2)
    80001ab8:	6605                	lui	a2,0x1
    80001aba:	020005b7          	lui	a1,0x2000
    80001abe:	15fd                	addi	a1,a1,-1
    80001ac0:	05b6                	slli	a1,a1,0xd
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	5fe080e7          	jalr	1534(ra) # 800010c2 <mappages>
    80001acc:	02054163          	bltz	a0,80001aee <proc_pagetable+0x76>
}
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	60e2                	ld	ra,24(sp)
    80001ad4:	6442                	ld	s0,16(sp)
    80001ad6:	64a2                	ld	s1,8(sp)
    80001ad8:	6902                	ld	s2,0(sp)
    80001ada:	6105                	addi	sp,sp,32
    80001adc:	8082                	ret
    uvmfree(pagetable, 0);
    80001ade:	4581                	li	a1,0
    80001ae0:	8526                	mv	a0,s1
    80001ae2:	00000097          	auipc	ra,0x0
    80001ae6:	a54080e7          	jalr	-1452(ra) # 80001536 <uvmfree>
    return 0;
    80001aea:	4481                	li	s1,0
    80001aec:	b7d5                	j	80001ad0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	8526                	mv	a0,s1
    80001afc:	fffff097          	auipc	ra,0xfffff
    80001b00:	77a080e7          	jalr	1914(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b04:	4581                	li	a1,0
    80001b06:	8526                	mv	a0,s1
    80001b08:	00000097          	auipc	ra,0x0
    80001b0c:	a2e080e7          	jalr	-1490(ra) # 80001536 <uvmfree>
    return 0;
    80001b10:	4481                	li	s1,0
    80001b12:	bf7d                	j	80001ad0 <proc_pagetable+0x58>

0000000080001b14 <proc_freepagetable>:
{
    80001b14:	1101                	addi	sp,sp,-32
    80001b16:	ec06                	sd	ra,24(sp)
    80001b18:	e822                	sd	s0,16(sp)
    80001b1a:	e426                	sd	s1,8(sp)
    80001b1c:	e04a                	sd	s2,0(sp)
    80001b1e:	1000                	addi	s0,sp,32
    80001b20:	84aa                	mv	s1,a0
    80001b22:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b24:	4681                	li	a3,0
    80001b26:	4605                	li	a2,1
    80001b28:	040005b7          	lui	a1,0x4000
    80001b2c:	15fd                	addi	a1,a1,-1
    80001b2e:	05b2                	slli	a1,a1,0xc
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	746080e7          	jalr	1862(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	020005b7          	lui	a1,0x2000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b6                	slli	a1,a1,0xd
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	730080e7          	jalr	1840(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4e:	85ca                	mv	a1,s2
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	9e4080e7          	jalr	-1564(ra) # 80001536 <uvmfree>
}
    80001b5a:	60e2                	ld	ra,24(sp)
    80001b5c:	6442                	ld	s0,16(sp)
    80001b5e:	64a2                	ld	s1,8(sp)
    80001b60:	6902                	ld	s2,0(sp)
    80001b62:	6105                	addi	sp,sp,32
    80001b64:	8082                	ret

0000000080001b66 <freeproc>:
{
    80001b66:	1101                	addi	sp,sp,-32
    80001b68:	ec06                	sd	ra,24(sp)
    80001b6a:	e822                	sd	s0,16(sp)
    80001b6c:	e426                	sd	s1,8(sp)
    80001b6e:	1000                	addi	s0,sp,32
    80001b70:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b72:	1f053503          	ld	a0,496(a0)
    80001b76:	c509                	beqz	a0,80001b80 <freeproc+0x1a>
    kfree((void*)p->trapframe);
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	e5e080e7          	jalr	-418(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b80:	1e04b823          	sd	zero,496(s1)
  if(p->trapframe_backup) // ADDED ?
    80001b84:	1c04b503          	ld	a0,448(s1)
    80001b88:	c509                	beqz	a0,80001b92 <freeproc+0x2c>
    kfree((void*)p->trapframe_backup); //TODO ?
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	e4c080e7          	jalr	-436(ra) # 800009d6 <kfree>
  p->trapframe_backup = 0;
    80001b92:	1c04b023          	sd	zero,448(s1)
  if(p->pagetable)
    80001b96:	1e84b503          	ld	a0,488(s1)
    80001b9a:	c519                	beqz	a0,80001ba8 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001b9c:	1e04b583          	ld	a1,480(s1)
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	f74080e7          	jalr	-140(ra) # 80001b14 <proc_freepagetable>
  p->pagetable = 0;
    80001ba8:	1e04b423          	sd	zero,488(s1)
  p->sz = 0;
    80001bac:	1e04b023          	sd	zero,480(s1)
  p->pid = 0;
    80001bb0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb4:	1c04b823          	sd	zero,464(s1)
  p->name[0] = 0;
    80001bb8:	2e048823          	sb	zero,752(s1)
  p->chan = 0;
    80001bbc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc8:	0004ac23          	sw	zero,24(s1)
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <allocproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	e04a                	sd	s2,0(sp)
    80001be0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be2:	00010497          	auipc	s1,0x10
    80001be6:	aee48493          	addi	s1,s1,-1298 # 800116d0 <proc>
    80001bea:	0001c917          	auipc	s2,0x1c
    80001bee:	ae690913          	addi	s2,s2,-1306 # 8001d6d0 <tickslock>
    acquire(&p->lock);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	fce080e7          	jalr	-50(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bfc:	4c9c                	lw	a5,24(s1)
    80001bfe:	cf81                	beqz	a5,80001c16 <allocproc+0x40>
      release(&p->lock);
    80001c00:	8526                	mv	a0,s1
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	086080e7          	jalr	134(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	30048493          	addi	s1,s1,768
    80001c0e:	ff2492e3          	bne	s1,s2,80001bf2 <allocproc+0x1c>
  return 0;
    80001c12:	4481                	li	s1,0
    80001c14:	a8b5                	j	80001c90 <allocproc+0xba>
printf("ALLOC PROC\n");
    80001c16:	00006517          	auipc	a0,0x6
    80001c1a:	5ea50513          	addi	a0,a0,1514 # 80008200 <digits+0x1c0>
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	956080e7          	jalr	-1706(ra) # 80000574 <printf>
  p->pid = allocpid();
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	e0c080e7          	jalr	-500(ra) # 80001a32 <allocpid>
    80001c2e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c30:	4785                	li	a5,1
    80001c32:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	e9e080e7          	jalr	-354(ra) # 80000ad2 <kalloc>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	1ea4b823          	sd	a0,496(s1)
    80001c42:	cd31                	beqz	a0,80001c9e <allocproc+0xc8>
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	e8e080e7          	jalr	-370(ra) # 80000ad2 <kalloc>
    80001c4c:	892a                	mv	s2,a0
    80001c4e:	1ca4b023          	sd	a0,448(s1)
    80001c52:	c135                	beqz	a0,80001cb6 <allocproc+0xe0>
  p->pagetable = proc_pagetable(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	e22080e7          	jalr	-478(ra) # 80001a78 <proc_pagetable>
    80001c5e:	892a                	mv	s2,a0
    80001c60:	1ea4b423          	sd	a0,488(s1)
  if(p->pagetable == 0){
    80001c64:	cd2d                	beqz	a0,80001cde <allocproc+0x108>
  memset(&p->context, 0, sizeof(p->context));
    80001c66:	07000613          	li	a2,112
    80001c6a:	4581                	li	a1,0
    80001c6c:	1f848513          	addi	a0,s1,504
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	072080e7          	jalr	114(ra) # 80000ce2 <memset>
  p->context.ra = (uint64)forkret;
    80001c78:	00000797          	auipc	a5,0x0
    80001c7c:	d7478793          	addi	a5,a5,-652 # 800019ec <forkret>
    80001c80:	1ef4bc23          	sd	a5,504(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c84:	1d84b783          	ld	a5,472(s1)
    80001c88:	6705                	lui	a4,0x1
    80001c8a:	97ba                	add	a5,a5,a4
    80001c8c:	20f4b023          	sd	a5,512(s1)
}
    80001c90:	8526                	mv	a0,s1
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6902                	ld	s2,0(sp)
    80001c9a:	6105                	addi	sp,sp,32
    80001c9c:	8082                	ret
    freeproc(p);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	ec6080e7          	jalr	-314(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001ca8:	8526                	mv	a0,s1
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	fde080e7          	jalr	-34(ra) # 80000c88 <release>
    return 0;
    80001cb2:	84ca                	mv	s1,s2
    80001cb4:	bff1                	j	80001c90 <allocproc+0xba>
    printf("FAILED ALLOC TRAPFRAME BACKUP\n");//TODO REMOVE
    80001cb6:	00006517          	auipc	a0,0x6
    80001cba:	55a50513          	addi	a0,a0,1370 # 80008210 <digits+0x1d0>
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	8b6080e7          	jalr	-1866(ra) # 80000574 <printf>
    freeproc(p);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	00000097          	auipc	ra,0x0
    80001ccc:	e9e080e7          	jalr	-354(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	fb6080e7          	jalr	-74(ra) # 80000c88 <release>
    return 0;
    80001cda:	84ca                	mv	s1,s2
    80001cdc:	bf55                	j	80001c90 <allocproc+0xba>
    freeproc(p);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	e86080e7          	jalr	-378(ra) # 80001b66 <freeproc>
    release(&p->lock);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	f9e080e7          	jalr	-98(ra) # 80000c88 <release>
    return 0;
    80001cf2:	84ca                	mv	s1,s2
    80001cf4:	bf71                	j	80001c90 <allocproc+0xba>

0000000080001cf6 <userinit>:
{
    80001cf6:	1101                	addi	sp,sp,-32
    80001cf8:	ec06                	sd	ra,24(sp)
    80001cfa:	e822                	sd	s0,16(sp)
    80001cfc:	e426                	sd	s1,8(sp)
    80001cfe:	1000                	addi	s0,sp,32
  printf("USRT INIT\n");
    80001d00:	00006517          	auipc	a0,0x6
    80001d04:	53050513          	addi	a0,a0,1328 # 80008230 <digits+0x1f0>
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	86c080e7          	jalr	-1940(ra) # 80000574 <printf>
  p = allocproc();
    80001d10:	00000097          	auipc	ra,0x0
    80001d14:	ec6080e7          	jalr	-314(ra) # 80001bd6 <allocproc>
    80001d18:	84aa                	mv	s1,a0
  initproc = p;
    80001d1a:	00007797          	auipc	a5,0x7
    80001d1e:	30a7b723          	sd	a0,782(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d22:	03400613          	li	a2,52
    80001d26:	00007597          	auipc	a1,0x7
    80001d2a:	c4a58593          	addi	a1,a1,-950 # 80008970 <initcode>
    80001d2e:	1e853503          	ld	a0,488(a0)
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	636080e7          	jalr	1590(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d3a:	6785                	lui	a5,0x1
    80001d3c:	1ef4b023          	sd	a5,480(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d40:	1f04b703          	ld	a4,496(s1)
    80001d44:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d48:	1f04b703          	ld	a4,496(s1)
    80001d4c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d4e:	4641                	li	a2,16
    80001d50:	00006597          	auipc	a1,0x6
    80001d54:	4f058593          	addi	a1,a1,1264 # 80008240 <digits+0x200>
    80001d58:	2f048513          	addi	a0,s1,752
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	0d8080e7          	jalr	216(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001d64:	00006517          	auipc	a0,0x6
    80001d68:	4ec50513          	addi	a0,a0,1260 # 80008250 <digits+0x210>
    80001d6c:	00002097          	auipc	ra,0x2
    80001d70:	7ac080e7          	jalr	1964(ra) # 80004518 <namei>
    80001d74:	2ea4b423          	sd	a0,744(s1)
  p->state = RUNNABLE;
    80001d78:	478d                	li	a5,3
    80001d7a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	f0a080e7          	jalr	-246(ra) # 80000c88 <release>
}
    80001d86:	60e2                	ld	ra,24(sp)
    80001d88:	6442                	ld	s0,16(sp)
    80001d8a:	64a2                	ld	s1,8(sp)
    80001d8c:	6105                	addi	sp,sp,32
    80001d8e:	8082                	ret

0000000080001d90 <growproc>:
{
    80001d90:	1101                	addi	sp,sp,-32
    80001d92:	ec06                	sd	ra,24(sp)
    80001d94:	e822                	sd	s0,16(sp)
    80001d96:	e426                	sd	s1,8(sp)
    80001d98:	e04a                	sd	s2,0(sp)
    80001d9a:	1000                	addi	s0,sp,32
    80001d9c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	c16080e7          	jalr	-1002(ra) # 800019b4 <myproc>
    80001da6:	892a                	mv	s2,a0
  sz = p->sz;
    80001da8:	1e053583          	ld	a1,480(a0)
    80001dac:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001db0:	00904f63          	bgtz	s1,80001dce <growproc+0x3e>
  } else if(n < 0){
    80001db4:	0204cd63          	bltz	s1,80001dee <growproc+0x5e>
  p->sz = sz;
    80001db8:	1602                	slli	a2,a2,0x20
    80001dba:	9201                	srli	a2,a2,0x20
    80001dbc:	1ec93023          	sd	a2,480(s2)
  return 0;
    80001dc0:	4501                	li	a0,0
}
    80001dc2:	60e2                	ld	ra,24(sp)
    80001dc4:	6442                	ld	s0,16(sp)
    80001dc6:	64a2                	ld	s1,8(sp)
    80001dc8:	6902                	ld	s2,0(sp)
    80001dca:	6105                	addi	sp,sp,32
    80001dcc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dce:	9e25                	addw	a2,a2,s1
    80001dd0:	1602                	slli	a2,a2,0x20
    80001dd2:	9201                	srli	a2,a2,0x20
    80001dd4:	1582                	slli	a1,a1,0x20
    80001dd6:	9181                	srli	a1,a1,0x20
    80001dd8:	1e853503          	ld	a0,488(a0)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	646080e7          	jalr	1606(ra) # 80001422 <uvmalloc>
    80001de4:	0005061b          	sext.w	a2,a0
    80001de8:	fa61                	bnez	a2,80001db8 <growproc+0x28>
      return -1;
    80001dea:	557d                	li	a0,-1
    80001dec:	bfd9                	j	80001dc2 <growproc+0x32>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dee:	9e25                	addw	a2,a2,s1
    80001df0:	1602                	slli	a2,a2,0x20
    80001df2:	9201                	srli	a2,a2,0x20
    80001df4:	1582                	slli	a1,a1,0x20
    80001df6:	9181                	srli	a1,a1,0x20
    80001df8:	1e853503          	ld	a0,488(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	5de080e7          	jalr	1502(ra) # 800013da <uvmdealloc>
    80001e04:	0005061b          	sext.w	a2,a0
    80001e08:	bf45                	j	80001db8 <growproc+0x28>

0000000080001e0a <fork>:
{
    80001e0a:	7139                	addi	sp,sp,-64
    80001e0c:	fc06                	sd	ra,56(sp)
    80001e0e:	f822                	sd	s0,48(sp)
    80001e10:	f426                	sd	s1,40(sp)
    80001e12:	f04a                	sd	s2,32(sp)
    80001e14:	ec4e                	sd	s3,24(sp)
    80001e16:	e852                	sd	s4,16(sp)
    80001e18:	e456                	sd	s5,8(sp)
    80001e1a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	b98080e7          	jalr	-1128(ra) # 800019b4 <myproc>
    80001e24:	892a                	mv	s2,a0
  printf("FORK\n");
    80001e26:	00006517          	auipc	a0,0x6
    80001e2a:	43250513          	addi	a0,a0,1074 # 80008258 <digits+0x218>
    80001e2e:	ffffe097          	auipc	ra,0xffffe
    80001e32:	746080e7          	jalr	1862(ra) # 80000574 <printf>
  if((np = allocproc()) == 0) {
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	da0080e7          	jalr	-608(ra) # 80001bd6 <allocproc>
    80001e3e:	12050f63          	beqz	a0,80001f7c <fork+0x172>
    80001e42:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e44:	1e093603          	ld	a2,480(s2)
    80001e48:	1e853583          	ld	a1,488(a0)
    80001e4c:	1e893503          	ld	a0,488(s2)
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	71e080e7          	jalr	1822(ra) # 8000156e <uvmcopy>
    80001e58:	04054863          	bltz	a0,80001ea8 <fork+0x9e>
  np->sz = p->sz;
    80001e5c:	1e093783          	ld	a5,480(s2)
    80001e60:	1efa3023          	sd	a5,480(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e64:	1f093683          	ld	a3,496(s2)
    80001e68:	87b6                	mv	a5,a3
    80001e6a:	1f0a3703          	ld	a4,496(s4)
    80001e6e:	12068693          	addi	a3,a3,288
    80001e72:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e76:	6788                	ld	a0,8(a5)
    80001e78:	6b8c                	ld	a1,16(a5)
    80001e7a:	6f90                	ld	a2,24(a5)
    80001e7c:	01073023          	sd	a6,0(a4)
    80001e80:	e708                	sd	a0,8(a4)
    80001e82:	eb0c                	sd	a1,16(a4)
    80001e84:	ef10                	sd	a2,24(a4)
    80001e86:	02078793          	addi	a5,a5,32
    80001e8a:	02070713          	addi	a4,a4,32
    80001e8e:	fed792e3          	bne	a5,a3,80001e72 <fork+0x68>
  np->trapframe->a0 = 0;
    80001e92:	1f0a3783          	ld	a5,496(s4)
    80001e96:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e9a:	26890493          	addi	s1,s2,616
    80001e9e:	268a0993          	addi	s3,s4,616
    80001ea2:	2e890a93          	addi	s5,s2,744
    80001ea6:	a00d                	j	80001ec8 <fork+0xbe>
    freeproc(np);
    80001ea8:	8552                	mv	a0,s4
    80001eaa:	00000097          	auipc	ra,0x0
    80001eae:	cbc080e7          	jalr	-836(ra) # 80001b66 <freeproc>
    release(&np->lock);
    80001eb2:	8552                	mv	a0,s4
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	dd4080e7          	jalr	-556(ra) # 80000c88 <release>
    return -1;
    80001ebc:	59fd                	li	s3,-1
    80001ebe:	a06d                	j	80001f68 <fork+0x15e>
  for(i = 0; i < NOFILE; i++)
    80001ec0:	04a1                	addi	s1,s1,8
    80001ec2:	09a1                	addi	s3,s3,8
    80001ec4:	01548b63          	beq	s1,s5,80001eda <fork+0xd0>
    if(p->ofile[i])
    80001ec8:	6088                	ld	a0,0(s1)
    80001eca:	d97d                	beqz	a0,80001ec0 <fork+0xb6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ecc:	00003097          	auipc	ra,0x3
    80001ed0:	ce6080e7          	jalr	-794(ra) # 80004bb2 <filedup>
    80001ed4:	00a9b023          	sd	a0,0(s3)
    80001ed8:	b7e5                	j	80001ec0 <fork+0xb6>
  np->cwd = idup(p->cwd);
    80001eda:	2e893503          	ld	a0,744(s2)
    80001ede:	00002097          	auipc	ra,0x2
    80001ee2:	e46080e7          	jalr	-442(ra) # 80003d24 <idup>
    80001ee6:	2eaa3423          	sd	a0,744(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eea:	4641                	li	a2,16
    80001eec:	2f090593          	addi	a1,s2,752
    80001ef0:	2f0a0513          	addi	a0,s4,752
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	f40080e7          	jalr	-192(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    80001efc:	030a2983          	lw	s3,48(s4)
  release(&np->lock);
    80001f00:	8552                	mv	a0,s4
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	d86080e7          	jalr	-634(ra) # 80000c88 <release>
  acquire(&wait_lock);
    80001f0a:	0000f497          	auipc	s1,0xf
    80001f0e:	3ae48493          	addi	s1,s1,942 # 800112b8 <wait_lock>
    80001f12:	8526                	mv	a0,s1
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	cae080e7          	jalr	-850(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001f1c:	1d2a3823          	sd	s2,464(s4)
  release(&wait_lock);
    80001f20:	8526                	mv	a0,s1
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	d66080e7          	jalr	-666(ra) # 80000c88 <release>
  acquire(&np->lock);
    80001f2a:	8552                	mv	a0,s4
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	c96080e7          	jalr	-874(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001f34:	478d                	li	a5,3
    80001f36:	00fa2c23          	sw	a5,24(s4)
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
    80001f3a:	03892783          	lw	a5,56(s2)
    80001f3e:	02fa2c23          	sw	a5,56(s4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80001f42:	04090793          	addi	a5,s2,64
    80001f46:	040a0713          	addi	a4,s4,64
    80001f4a:	14090613          	addi	a2,s2,320
    np->signal_handlers[i] = p->signal_handlers[i];    
    80001f4e:	6394                	ld	a3,0(a5)
    80001f50:	e314                	sd	a3,0(a4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80001f52:	07a1                	addi	a5,a5,8
    80001f54:	0721                	addi	a4,a4,8
    80001f56:	fec79ce3          	bne	a5,a2,80001f4e <fork+0x144>
  np->pending_signals = 0; // ADDED Q2.1.2
    80001f5a:	020a2a23          	sw	zero,52(s4)
  release(&np->lock);
    80001f5e:	8552                	mv	a0,s4
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d28080e7          	jalr	-728(ra) # 80000c88 <release>
}
    80001f68:	854e                	mv	a0,s3
    80001f6a:	70e2                	ld	ra,56(sp)
    80001f6c:	7442                	ld	s0,48(sp)
    80001f6e:	74a2                	ld	s1,40(sp)
    80001f70:	7902                	ld	s2,32(sp)
    80001f72:	69e2                	ld	s3,24(sp)
    80001f74:	6a42                	ld	s4,16(sp)
    80001f76:	6aa2                	ld	s5,8(sp)
    80001f78:	6121                	addi	sp,sp,64
    80001f7a:	8082                	ret
    return -1;
    80001f7c:	59fd                	li	s3,-1
    80001f7e:	b7ed                	j	80001f68 <fork+0x15e>

0000000080001f80 <kill_handler>:
{
    80001f80:	1141                	addi	sp,sp,-16
    80001f82:	e406                	sd	ra,8(sp)
    80001f84:	e022                	sd	s0,0(sp)
    80001f86:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	a2c080e7          	jalr	-1492(ra) # 800019b4 <myproc>
  p->killed = 1; 
    80001f90:	4785                	li	a5,1
    80001f92:	d51c                	sw	a5,40(a0)
}
    80001f94:	60a2                	ld	ra,8(sp)
    80001f96:	6402                	ld	s0,0(sp)
    80001f98:	0141                	addi	sp,sp,16
    80001f9a:	8082                	ret

0000000080001f9c <received_continue>:
{
    80001f9c:	1101                	addi	sp,sp,-32
    80001f9e:	ec06                	sd	ra,24(sp)
    80001fa0:	e822                	sd	s0,16(sp)
    80001fa2:	e426                	sd	s1,8(sp)
    80001fa4:	e04a                	sd	s2,0(sp)
    80001fa6:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	a0c080e7          	jalr	-1524(ra) # 800019b4 <myproc>
    80001fb0:	892a                	mv	s2,a0
    acquire(&p->lock);
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	c10080e7          	jalr	-1008(ra) # 80000bc2 <acquire>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    80001fba:	03892683          	lw	a3,56(s2)
    80001fbe:	fff6c693          	not	a3,a3
    80001fc2:	03492783          	lw	a5,52(s2)
    80001fc6:	8efd                	and	a3,a3,a5
    80001fc8:	2681                	sext.w	a3,a3
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001fca:	04090713          	addi	a4,s2,64
    80001fce:	4781                	li	a5,0
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001fd0:	454d                	li	a0,19
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001fd2:	02000613          	li	a2,32
    80001fd6:	a801                	j	80001fe6 <received_continue+0x4a>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001fd8:	630c                	ld	a1,0(a4)
    80001fda:	00a58f63          	beq	a1,a0,80001ff8 <received_continue+0x5c>
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80001fde:	2785                	addiw	a5,a5,1
    80001fe0:	0721                	addi	a4,a4,8
    80001fe2:	02c78163          	beq	a5,a2,80002004 <received_continue+0x68>
      if( (pending_and_not_blocked & (1 << signum)) &&
    80001fe6:	40f6d4bb          	sraw	s1,a3,a5
    80001fea:	8885                	andi	s1,s1,1
    80001fec:	d8ed                	beqz	s1,80001fde <received_continue+0x42>
    80001fee:	0d893583          	ld	a1,216(s2)
    80001ff2:	f1fd                	bnez	a1,80001fd8 <received_continue+0x3c>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80001ff4:	fea792e3          	bne	a5,a0,80001fd8 <received_continue+0x3c>
            release(&p->lock);
    80001ff8:	854a                	mv	a0,s2
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	c8e080e7          	jalr	-882(ra) # 80000c88 <release>
            return 1;
    80002002:	a039                	j	80002010 <received_continue+0x74>
    release(&p->lock);
    80002004:	854a                	mv	a0,s2
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	c82080e7          	jalr	-894(ra) # 80000c88 <release>
    return 0;
    8000200e:	4481                	li	s1,0
}
    80002010:	8526                	mv	a0,s1
    80002012:	60e2                	ld	ra,24(sp)
    80002014:	6442                	ld	s0,16(sp)
    80002016:	64a2                	ld	s1,8(sp)
    80002018:	6902                	ld	s2,0(sp)
    8000201a:	6105                	addi	sp,sp,32
    8000201c:	8082                	ret

000000008000201e <continue_handler>:
{
    8000201e:	1141                	addi	sp,sp,-16
    80002020:	e406                	sd	ra,8(sp)
    80002022:	e022                	sd	s0,0(sp)
    80002024:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	98e080e7          	jalr	-1650(ra) # 800019b4 <myproc>
  p->stopped = 0;
    8000202e:	1c052423          	sw	zero,456(a0)
}
    80002032:	60a2                	ld	ra,8(sp)
    80002034:	6402                	ld	s0,0(sp)
    80002036:	0141                	addi	sp,sp,16
    80002038:	8082                	ret

000000008000203a <handle_user_signals>:
handle_user_signals(int signum) {
    8000203a:	1101                	addi	sp,sp,-32
    8000203c:	ec06                	sd	ra,24(sp)
    8000203e:	e822                	sd	s0,16(sp)
    80002040:	e426                	sd	s1,8(sp)
    80002042:	e04a                	sd	s2,0(sp)
    80002044:	1000                	addi	s0,sp,32
    80002046:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002048:	00000097          	auipc	ra,0x0
    8000204c:	96c080e7          	jalr	-1684(ra) # 800019b4 <myproc>
    80002050:	84aa                	mv	s1,a0
  p->signal_mask_backup = p->signal_mask;
    80002052:	5d1c                	lw	a5,56(a0)
    80002054:	dd5c                	sw	a5,60(a0)
  p->signal_mask = p->signal_handlers_masks[signum];  
    80002056:	05090793          	addi	a5,s2,80
    8000205a:	078a                	slli	a5,a5,0x2
    8000205c:	97aa                	add	a5,a5,a0
    8000205e:	439c                	lw	a5,0(a5)
    80002060:	dd1c                	sw	a5,56(a0)
  memmove(p->trapframe_backup, p->trapframe, sizeof(struct trapframe));
    80002062:	12000613          	li	a2,288
    80002066:	1f053583          	ld	a1,496(a0)
    8000206a:	1c053503          	ld	a0,448(a0)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	cd0080e7          	jalr	-816(ra) # 80000d3e <memmove>
  p->trapframe->sp = p->trapframe->sp - inject_sigret_size;
    80002076:	1f04b703          	ld	a4,496(s1)
  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
    8000207a:	00005617          	auipc	a2,0x5
    8000207e:	09860613          	addi	a2,a2,152 # 80007112 <start_inject_sigret>
  p->trapframe->sp = p->trapframe->sp - inject_sigret_size;
    80002082:	00005697          	auipc	a3,0x5
    80002086:	09668693          	addi	a3,a3,150 # 80007118 <end_inject_sigret>
    8000208a:	9e91                	subw	a3,a3,a2
    8000208c:	7b1c                	ld	a5,48(a4)
    8000208e:	8f95                	sub	a5,a5,a3
    80002090:	fb1c                	sd	a5,48(a4)
  copyout(p->pagetable, (uint64) (p->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);
    80002092:	1f04b783          	ld	a5,496(s1)
    80002096:	7b8c                	ld	a1,48(a5)
    80002098:	1e84b503          	ld	a0,488(s1)
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	5d6080e7          	jalr	1494(ra) # 80001672 <copyout>
  p->trapframe->a0 = signum;
    800020a4:	1f04b783          	ld	a5,496(s1)
    800020a8:	0727b823          	sd	s2,112(a5)
  p->trapframe->epc = (uint64)p->signal_handlers[signum];
    800020ac:	1f04b783          	ld	a5,496(s1)
    800020b0:	0921                	addi	s2,s2,8
    800020b2:	090e                	slli	s2,s2,0x3
    800020b4:	9926                	add	s2,s2,s1
    800020b6:	00093703          	ld	a4,0(s2)
    800020ba:	ef98                	sd	a4,24(a5)
  p->trapframe->ra = p->trapframe->sp;
    800020bc:	1f04b783          	ld	a5,496(s1)
    800020c0:	7b98                	ld	a4,48(a5)
    800020c2:	f798                	sd	a4,40(a5)
}
    800020c4:	60e2                	ld	ra,24(sp)
    800020c6:	6442                	ld	s0,16(sp)
    800020c8:	64a2                	ld	s1,8(sp)
    800020ca:	6902                	ld	s2,0(sp)
    800020cc:	6105                	addi	sp,sp,32
    800020ce:	8082                	ret

00000000800020d0 <scheduler>:
{
    800020d0:	7139                	addi	sp,sp,-64
    800020d2:	fc06                	sd	ra,56(sp)
    800020d4:	f822                	sd	s0,48(sp)
    800020d6:	f426                	sd	s1,40(sp)
    800020d8:	f04a                	sd	s2,32(sp)
    800020da:	ec4e                	sd	s3,24(sp)
    800020dc:	e852                	sd	s4,16(sp)
    800020de:	e456                	sd	s5,8(sp)
    800020e0:	e05a                	sd	s6,0(sp)
    800020e2:	0080                	addi	s0,sp,64
    800020e4:	8792                	mv	a5,tp
  int id = r_tp();
    800020e6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020e8:	00779a93          	slli	s5,a5,0x7
    800020ec:	0000f717          	auipc	a4,0xf
    800020f0:	1b470713          	addi	a4,a4,436 # 800112a0 <pid_lock>
    800020f4:	9756                	add	a4,a4,s5
    800020f6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800020fa:	0000f717          	auipc	a4,0xf
    800020fe:	1de70713          	addi	a4,a4,478 # 800112d8 <cpus+0x8>
    80002102:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002104:	498d                	li	s3,3
        p->state = RUNNING;
    80002106:	4b11                	li	s6,4
        c->proc = p;
    80002108:	079e                	slli	a5,a5,0x7
    8000210a:	0000fa17          	auipc	s4,0xf
    8000210e:	196a0a13          	addi	s4,s4,406 # 800112a0 <pid_lock>
    80002112:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002114:	0001b917          	auipc	s2,0x1b
    80002118:	5bc90913          	addi	s2,s2,1468 # 8001d6d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000211c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002120:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002124:	10079073          	csrw	sstatus,a5
    80002128:	0000f497          	auipc	s1,0xf
    8000212c:	5a848493          	addi	s1,s1,1448 # 800116d0 <proc>
    80002130:	a811                	j	80002144 <scheduler+0x74>
      release(&p->lock);
    80002132:	8526                	mv	a0,s1
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	b54080e7          	jalr	-1196(ra) # 80000c88 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000213c:	30048493          	addi	s1,s1,768
    80002140:	fd248ee3          	beq	s1,s2,8000211c <scheduler+0x4c>
      acquire(&p->lock);
    80002144:	8526                	mv	a0,s1
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	a7c080e7          	jalr	-1412(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    8000214e:	4c9c                	lw	a5,24(s1)
    80002150:	ff3791e3          	bne	a5,s3,80002132 <scheduler+0x62>
        p->state = RUNNING;
    80002154:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002158:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000215c:	1f848593          	addi	a1,s1,504
    80002160:	8556                	mv	a0,s5
    80002162:	00001097          	auipc	ra,0x1
    80002166:	aa6080e7          	jalr	-1370(ra) # 80002c08 <swtch>
        c->proc = 0;
    8000216a:	020a3823          	sd	zero,48(s4)
    8000216e:	b7d1                	j	80002132 <scheduler+0x62>

0000000080002170 <sched>:
{
    80002170:	7179                	addi	sp,sp,-48
    80002172:	f406                	sd	ra,40(sp)
    80002174:	f022                	sd	s0,32(sp)
    80002176:	ec26                	sd	s1,24(sp)
    80002178:	e84a                	sd	s2,16(sp)
    8000217a:	e44e                	sd	s3,8(sp)
    8000217c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	836080e7          	jalr	-1994(ra) # 800019b4 <myproc>
    80002186:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	9c0080e7          	jalr	-1600(ra) # 80000b48 <holding>
    80002190:	c93d                	beqz	a0,80002206 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002192:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002194:	2781                	sext.w	a5,a5
    80002196:	079e                	slli	a5,a5,0x7
    80002198:	0000f717          	auipc	a4,0xf
    8000219c:	10870713          	addi	a4,a4,264 # 800112a0 <pid_lock>
    800021a0:	97ba                	add	a5,a5,a4
    800021a2:	0a87a703          	lw	a4,168(a5)
    800021a6:	4785                	li	a5,1
    800021a8:	06f71763          	bne	a4,a5,80002216 <sched+0xa6>
  if(p->state == RUNNING)
    800021ac:	4c98                	lw	a4,24(s1)
    800021ae:	4791                	li	a5,4
    800021b0:	06f70b63          	beq	a4,a5,80002226 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021b8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021ba:	efb5                	bnez	a5,80002236 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021bc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021be:	0000f917          	auipc	s2,0xf
    800021c2:	0e290913          	addi	s2,s2,226 # 800112a0 <pid_lock>
    800021c6:	2781                	sext.w	a5,a5
    800021c8:	079e                	slli	a5,a5,0x7
    800021ca:	97ca                	add	a5,a5,s2
    800021cc:	0ac7a983          	lw	s3,172(a5)
    800021d0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021d2:	2781                	sext.w	a5,a5
    800021d4:	079e                	slli	a5,a5,0x7
    800021d6:	0000f597          	auipc	a1,0xf
    800021da:	10258593          	addi	a1,a1,258 # 800112d8 <cpus+0x8>
    800021de:	95be                	add	a1,a1,a5
    800021e0:	1f848513          	addi	a0,s1,504
    800021e4:	00001097          	auipc	ra,0x1
    800021e8:	a24080e7          	jalr	-1500(ra) # 80002c08 <swtch>
    800021ec:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021ee:	2781                	sext.w	a5,a5
    800021f0:	079e                	slli	a5,a5,0x7
    800021f2:	97ca                	add	a5,a5,s2
    800021f4:	0b37a623          	sw	s3,172(a5)
}
    800021f8:	70a2                	ld	ra,40(sp)
    800021fa:	7402                	ld	s0,32(sp)
    800021fc:	64e2                	ld	s1,24(sp)
    800021fe:	6942                	ld	s2,16(sp)
    80002200:	69a2                	ld	s3,8(sp)
    80002202:	6145                	addi	sp,sp,48
    80002204:	8082                	ret
    panic("sched p->lock");
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	05a50513          	addi	a0,a0,90 # 80008260 <digits+0x220>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	31c080e7          	jalr	796(ra) # 8000052a <panic>
    panic("sched locks");
    80002216:	00006517          	auipc	a0,0x6
    8000221a:	05a50513          	addi	a0,a0,90 # 80008270 <digits+0x230>
    8000221e:	ffffe097          	auipc	ra,0xffffe
    80002222:	30c080e7          	jalr	780(ra) # 8000052a <panic>
    panic("sched running");
    80002226:	00006517          	auipc	a0,0x6
    8000222a:	05a50513          	addi	a0,a0,90 # 80008280 <digits+0x240>
    8000222e:	ffffe097          	auipc	ra,0xffffe
    80002232:	2fc080e7          	jalr	764(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002236:	00006517          	auipc	a0,0x6
    8000223a:	05a50513          	addi	a0,a0,90 # 80008290 <digits+0x250>
    8000223e:	ffffe097          	auipc	ra,0xffffe
    80002242:	2ec080e7          	jalr	748(ra) # 8000052a <panic>

0000000080002246 <yield>:
{
    80002246:	1101                	addi	sp,sp,-32
    80002248:	ec06                	sd	ra,24(sp)
    8000224a:	e822                	sd	s0,16(sp)
    8000224c:	e426                	sd	s1,8(sp)
    8000224e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	764080e7          	jalr	1892(ra) # 800019b4 <myproc>
    80002258:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	968080e7          	jalr	-1688(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002262:	478d                	li	a5,3
    80002264:	cc9c                	sw	a5,24(s1)
  sched();
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	f0a080e7          	jalr	-246(ra) # 80002170 <sched>
  release(&p->lock);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a18080e7          	jalr	-1512(ra) # 80000c88 <release>
}
    80002278:	60e2                	ld	ra,24(sp)
    8000227a:	6442                	ld	s0,16(sp)
    8000227c:	64a2                	ld	s1,8(sp)
    8000227e:	6105                	addi	sp,sp,32
    80002280:	8082                	ret

0000000080002282 <stop_handler>:
{
    80002282:	1101                	addi	sp,sp,-32
    80002284:	ec06                	sd	ra,24(sp)
    80002286:	e822                	sd	s0,16(sp)
    80002288:	e426                	sd	s1,8(sp)
    8000228a:	e04a                	sd	s2,0(sp)
    8000228c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	726080e7          	jalr	1830(ra) # 800019b4 <myproc>
    80002296:	84aa                	mv	s1,a0
  p->stopped = 1;
    80002298:	4785                	li	a5,1
    8000229a:	1cf52423          	sw	a5,456(a0)
  release(&p->lock);
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	9ea080e7          	jalr	-1558(ra) # 80000c88 <release>
  while (p->stopped && !received_continue())
    800022a6:	1c84a783          	lw	a5,456(s1)
      printf("yoni\n"); //TODO REMOVE
    800022aa:	00006917          	auipc	s2,0x6
    800022ae:	ffe90913          	addi	s2,s2,-2 # 800082a8 <digits+0x268>
  while (p->stopped && !received_continue())
    800022b2:	c395                	beqz	a5,800022d6 <stop_handler+0x54>
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	ce8080e7          	jalr	-792(ra) # 80001f9c <received_continue>
    800022bc:	ed09                	bnez	a0,800022d6 <stop_handler+0x54>
      printf("yoni\n"); //TODO REMOVE
    800022be:	854a                	mv	a0,s2
    800022c0:	ffffe097          	auipc	ra,0xffffe
    800022c4:	2b4080e7          	jalr	692(ra) # 80000574 <printf>
      yield();
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	f7e080e7          	jalr	-130(ra) # 80002246 <yield>
  while (p->stopped && !received_continue())
    800022d0:	1c84a783          	lw	a5,456(s1)
    800022d4:	f3e5                	bnez	a5,800022b4 <stop_handler+0x32>
  acquire(&p->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	8ea080e7          	jalr	-1814(ra) # 80000bc2 <acquire>
}
    800022e0:	60e2                	ld	ra,24(sp)
    800022e2:	6442                	ld	s0,16(sp)
    800022e4:	64a2                	ld	s1,8(sp)
    800022e6:	6902                	ld	s2,0(sp)
    800022e8:	6105                	addi	sp,sp,32
    800022ea:	8082                	ret

00000000800022ec <handle_signals>:
{
    800022ec:	7159                	addi	sp,sp,-112
    800022ee:	f486                	sd	ra,104(sp)
    800022f0:	f0a2                	sd	s0,96(sp)
    800022f2:	eca6                	sd	s1,88(sp)
    800022f4:	e8ca                	sd	s2,80(sp)
    800022f6:	e4ce                	sd	s3,72(sp)
    800022f8:	e0d2                	sd	s4,64(sp)
    800022fa:	fc56                	sd	s5,56(sp)
    800022fc:	f85a                	sd	s6,48(sp)
    800022fe:	f45e                	sd	s7,40(sp)
    80002300:	f062                	sd	s8,32(sp)
    80002302:	ec66                	sd	s9,24(sp)
    80002304:	e86a                	sd	s10,16(sp)
    80002306:	e46e                	sd	s11,8(sp)
    80002308:	1880                	addi	s0,sp,112
  printf("@@@@@@@@@@\n"); //TODO REMOVE
    8000230a:	00006517          	auipc	a0,0x6
    8000230e:	fa650513          	addi	a0,a0,-90 # 800082b0 <digits+0x270>
    80002312:	ffffe097          	auipc	ra,0xffffe
    80002316:	262080e7          	jalr	610(ra) # 80000574 <printf>
  struct proc *p = myproc();
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	69a080e7          	jalr	1690(ra) # 800019b4 <myproc>
    80002322:	8a2a                	mv	s4,a0
  acquire(&p->lock);
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	89e080e7          	jalr	-1890(ra) # 80000bc2 <acquire>
  printf("handle_signals - lock acquired\n"); //TODO REMOVE
    8000232c:	00006517          	auipc	a0,0x6
    80002330:	f9450513          	addi	a0,a0,-108 # 800082c0 <digits+0x280>
    80002334:	ffffe097          	auipc	ra,0xffffe
    80002338:	240080e7          	jalr	576(ra) # 80000574 <printf>
  int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    8000233c:	038a2983          	lw	s3,56(s4)
    80002340:	fff9c993          	not	s3,s3
    80002344:	034a2783          	lw	a5,52(s4)
    80002348:	00f9f9b3          	and	s3,s3,a5
    8000234c:	2981                	sext.w	s3,s3
  for(int signum = 0; signum < SIG_NUM; signum++){
    8000234e:	040a0913          	addi	s2,s4,64
    80002352:	4481                	li	s1,0
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002354:	4b05                	li	s6,1
        printf("continue_handler\n");
    80002356:	00006d97          	auipc	s11,0x6
    8000235a:	f9ad8d93          	addi	s11,s11,-102 # 800082f0 <digits+0x2b0>
        printf("stop_handler\n");
    8000235e:	00006c97          	auipc	s9,0x6
    80002362:	f82c8c93          	addi	s9,s9,-126 # 800082e0 <digits+0x2a0>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    80002366:	4ac5                	li	s5,17
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    80002368:	4bcd                	li	s7,19
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    8000236a:	4c25                	li	s8,9
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    8000236c:	4d05                	li	s10,1
    8000236e:	a09d                	j	800023d4 <handle_signals+0xe8>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    80002370:	03548a63          	beq	s1,s5,800023a4 <handle_signals+0xb8>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    80002374:	0b748b63          	beq	s1,s7,8000242a <handle_signals+0x13e>
        printf("kill_handler\n");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	f9050513          	addi	a0,a0,-112 # 80008308 <digits+0x2c8>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1f4080e7          	jalr	500(ra) # 80000574 <printf>
        kill_handler();
    80002388:	00000097          	auipc	ra,0x0
    8000238c:	bf8080e7          	jalr	-1032(ra) # 80001f80 <kill_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002390:	009b17bb          	sllw	a5,s6,s1
    80002394:	fff7c793          	not	a5,a5
    80002398:	034a2703          	lw	a4,52(s4)
    8000239c:	8ff9                	and	a5,a5,a4
    8000239e:	02fa2a23          	sw	a5,52(s4)
    800023a2:	a01d                	j	800023c8 <handle_signals+0xdc>
        printf("stop_handler\n");
    800023a4:	8566                	mv	a0,s9
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	1ce080e7          	jalr	462(ra) # 80000574 <printf>
        stop_handler();
    800023ae:	00000097          	auipc	ra,0x0
    800023b2:	ed4080e7          	jalr	-300(ra) # 80002282 <stop_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800023b6:	009b17bb          	sllw	a5,s6,s1
    800023ba:	fff7c793          	not	a5,a5
    800023be:	034a2703          	lw	a4,52(s4)
    800023c2:	8ff9                	and	a5,a5,a4
    800023c4:	02fa2a23          	sw	a5,52(s4)
  for(int signum = 0; signum < SIG_NUM; signum++){
    800023c8:	2485                	addiw	s1,s1,1
    800023ca:	0921                	addi	s2,s2,8
    800023cc:	02000793          	li	a5,32
    800023d0:	0af48263          	beq	s1,a5,80002474 <handle_signals+0x188>
    if(pending_and_not_blocked & (1 << signum)){
    800023d4:	4099d7bb          	sraw	a5,s3,s1
    800023d8:	8b85                	andi	a5,a5,1
    800023da:	d7fd                	beqz	a5,800023c8 <handle_signals+0xdc>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800023dc:	00093783          	ld	a5,0(s2)
    800023e0:	dbc1                	beqz	a5,80002370 <handle_signals+0x84>
    800023e2:	fd5781e3          	beq	a5,s5,800023a4 <handle_signals+0xb8>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800023e6:	05778263          	beq	a5,s7,8000242a <handle_signals+0x13e>
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    800023ea:	f98787e3          	beq	a5,s8,80002378 <handle_signals+0x8c>
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    800023ee:	07a78163          	beq	a5,s10,80002450 <handle_signals+0x164>
      } else if (p->handling_user_level_signal == 0){
    800023f2:	1cca2783          	lw	a5,460(s4)
    800023f6:	fbe9                	bnez	a5,800023c8 <handle_signals+0xdc>
        p->handling_user_level_signal = 1;
    800023f8:	1daa2623          	sw	s10,460(s4)
        printf("handle_user_signals\n");
    800023fc:	00006517          	auipc	a0,0x6
    80002400:	f2c50513          	addi	a0,a0,-212 # 80008328 <digits+0x2e8>
    80002404:	ffffe097          	auipc	ra,0xffffe
    80002408:	170080e7          	jalr	368(ra) # 80000574 <printf>
        handle_user_signals(signum);
    8000240c:	8526                	mv	a0,s1
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	c2c080e7          	jalr	-980(ra) # 8000203a <handle_user_signals>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002416:	009b17bb          	sllw	a5,s6,s1
    8000241a:	fff7c793          	not	a5,a5
    8000241e:	034a2703          	lw	a4,52(s4)
    80002422:	8ff9                	and	a5,a5,a4
    80002424:	02fa2a23          	sw	a5,52(s4)
    80002428:	b745                	j	800023c8 <handle_signals+0xdc>
        printf("continue_handler\n");
    8000242a:	856e                	mv	a0,s11
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	148080e7          	jalr	328(ra) # 80000574 <printf>
        continue_handler();
    80002434:	00000097          	auipc	ra,0x0
    80002438:	bea080e7          	jalr	-1046(ra) # 8000201e <continue_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000243c:	009b17bb          	sllw	a5,s6,s1
    80002440:	fff7c793          	not	a5,a5
    80002444:	034a2703          	lw	a4,52(s4)
    80002448:	8ff9                	and	a5,a5,a4
    8000244a:	02fa2a23          	sw	a5,52(s4)
    8000244e:	bfad                	j	800023c8 <handle_signals+0xdc>
        printf("IGNORING\n");
    80002450:	00006517          	auipc	a0,0x6
    80002454:	ec850513          	addi	a0,a0,-312 # 80008318 <digits+0x2d8>
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	11c080e7          	jalr	284(ra) # 80000574 <printf>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002460:	009b17bb          	sllw	a5,s6,s1
    80002464:	fff7c793          	not	a5,a5
    80002468:	034a2703          	lw	a4,52(s4)
    8000246c:	8ff9                	and	a5,a5,a4
    8000246e:	02fa2a23          	sw	a5,52(s4)
    80002472:	bf99                	j	800023c8 <handle_signals+0xdc>
  release(&p->lock);
    80002474:	8552                	mv	a0,s4
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	812080e7          	jalr	-2030(ra) # 80000c88 <release>
  printf("handle_signals - lock released\n"); //TODO REMOVE
    8000247e:	00006517          	auipc	a0,0x6
    80002482:	ec250513          	addi	a0,a0,-318 # 80008340 <digits+0x300>
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	0ee080e7          	jalr	238(ra) # 80000574 <printf>
}
    8000248e:	70a6                	ld	ra,104(sp)
    80002490:	7406                	ld	s0,96(sp)
    80002492:	64e6                	ld	s1,88(sp)
    80002494:	6946                	ld	s2,80(sp)
    80002496:	69a6                	ld	s3,72(sp)
    80002498:	6a06                	ld	s4,64(sp)
    8000249a:	7ae2                	ld	s5,56(sp)
    8000249c:	7b42                	ld	s6,48(sp)
    8000249e:	7ba2                	ld	s7,40(sp)
    800024a0:	7c02                	ld	s8,32(sp)
    800024a2:	6ce2                	ld	s9,24(sp)
    800024a4:	6d42                	ld	s10,16(sp)
    800024a6:	6da2                	ld	s11,8(sp)
    800024a8:	6165                	addi	sp,sp,112
    800024aa:	8082                	ret

00000000800024ac <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800024ac:	7179                	addi	sp,sp,-48
    800024ae:	f406                	sd	ra,40(sp)
    800024b0:	f022                	sd	s0,32(sp)
    800024b2:	ec26                	sd	s1,24(sp)
    800024b4:	e84a                	sd	s2,16(sp)
    800024b6:	e44e                	sd	s3,8(sp)
    800024b8:	1800                	addi	s0,sp,48
    800024ba:	89aa                	mv	s3,a0
    800024bc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	4f6080e7          	jalr	1270(ra) # 800019b4 <myproc>
    800024c6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	6fa080e7          	jalr	1786(ra) # 80000bc2 <acquire>
  release(lk);
    800024d0:	854a                	mv	a0,s2
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7b6080e7          	jalr	1974(ra) # 80000c88 <release>

  // Go to sleep.
  p->chan = chan;
    800024da:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800024de:	4789                	li	a5,2
    800024e0:	cc9c                	sw	a5,24(s1)

  sched();
    800024e2:	00000097          	auipc	ra,0x0
    800024e6:	c8e080e7          	jalr	-882(ra) # 80002170 <sched>

  // Tidy up.
  p->chan = 0;
    800024ea:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	798080e7          	jalr	1944(ra) # 80000c88 <release>
  acquire(lk);
    800024f8:	854a                	mv	a0,s2
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6c8080e7          	jalr	1736(ra) # 80000bc2 <acquire>
}
    80002502:	70a2                	ld	ra,40(sp)
    80002504:	7402                	ld	s0,32(sp)
    80002506:	64e2                	ld	s1,24(sp)
    80002508:	6942                	ld	s2,16(sp)
    8000250a:	69a2                	ld	s3,8(sp)
    8000250c:	6145                	addi	sp,sp,48
    8000250e:	8082                	ret

0000000080002510 <wait>:
{
    80002510:	715d                	addi	sp,sp,-80
    80002512:	e486                	sd	ra,72(sp)
    80002514:	e0a2                	sd	s0,64(sp)
    80002516:	fc26                	sd	s1,56(sp)
    80002518:	f84a                	sd	s2,48(sp)
    8000251a:	f44e                	sd	s3,40(sp)
    8000251c:	f052                	sd	s4,32(sp)
    8000251e:	ec56                	sd	s5,24(sp)
    80002520:	e85a                	sd	s6,16(sp)
    80002522:	e45e                	sd	s7,8(sp)
    80002524:	e062                	sd	s8,0(sp)
    80002526:	0880                	addi	s0,sp,80
    80002528:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	48a080e7          	jalr	1162(ra) # 800019b4 <myproc>
    80002532:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002534:	0000f517          	auipc	a0,0xf
    80002538:	d8450513          	addi	a0,a0,-636 # 800112b8 <wait_lock>
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	686080e7          	jalr	1670(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002544:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002546:	4a15                	li	s4,5
        havekids = 1;
    80002548:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000254a:	0001b997          	auipc	s3,0x1b
    8000254e:	18698993          	addi	s3,s3,390 # 8001d6d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002552:	0000fc17          	auipc	s8,0xf
    80002556:	d66c0c13          	addi	s8,s8,-666 # 800112b8 <wait_lock>
    havekids = 0;
    8000255a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000255c:	0000f497          	auipc	s1,0xf
    80002560:	17448493          	addi	s1,s1,372 # 800116d0 <proc>
    80002564:	a0bd                	j	800025d2 <wait+0xc2>
          pid = np->pid;
    80002566:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000256a:	000b0e63          	beqz	s6,80002586 <wait+0x76>
    8000256e:	4691                	li	a3,4
    80002570:	02c48613          	addi	a2,s1,44
    80002574:	85da                	mv	a1,s6
    80002576:	1e893503          	ld	a0,488(s2)
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	0f8080e7          	jalr	248(ra) # 80001672 <copyout>
    80002582:	02054563          	bltz	a0,800025ac <wait+0x9c>
          freeproc(np);
    80002586:	8526                	mv	a0,s1
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	5de080e7          	jalr	1502(ra) # 80001b66 <freeproc>
          release(&np->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	6f6080e7          	jalr	1782(ra) # 80000c88 <release>
          release(&wait_lock);
    8000259a:	0000f517          	auipc	a0,0xf
    8000259e:	d1e50513          	addi	a0,a0,-738 # 800112b8 <wait_lock>
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	6e6080e7          	jalr	1766(ra) # 80000c88 <release>
          return pid;
    800025aa:	a0a5                	j	80002612 <wait+0x102>
            release(&np->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6da080e7          	jalr	1754(ra) # 80000c88 <release>
            release(&wait_lock);
    800025b6:	0000f517          	auipc	a0,0xf
    800025ba:	d0250513          	addi	a0,a0,-766 # 800112b8 <wait_lock>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	6ca080e7          	jalr	1738(ra) # 80000c88 <release>
            return -1;
    800025c6:	59fd                	li	s3,-1
    800025c8:	a0a9                	j	80002612 <wait+0x102>
    for(np = proc; np < &proc[NPROC]; np++){
    800025ca:	30048493          	addi	s1,s1,768
    800025ce:	03348563          	beq	s1,s3,800025f8 <wait+0xe8>
      if(np->parent == p){
    800025d2:	1d04b783          	ld	a5,464(s1)
    800025d6:	ff279ae3          	bne	a5,s2,800025ca <wait+0xba>
        acquire(&np->lock);
    800025da:	8526                	mv	a0,s1
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	5e6080e7          	jalr	1510(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800025e4:	4c9c                	lw	a5,24(s1)
    800025e6:	f94780e3          	beq	a5,s4,80002566 <wait+0x56>
        release(&np->lock);
    800025ea:	8526                	mv	a0,s1
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	69c080e7          	jalr	1692(ra) # 80000c88 <release>
        havekids = 1;
    800025f4:	8756                	mv	a4,s5
    800025f6:	bfd1                	j	800025ca <wait+0xba>
    if(!havekids || p->killed){
    800025f8:	c701                	beqz	a4,80002600 <wait+0xf0>
    800025fa:	02892783          	lw	a5,40(s2)
    800025fe:	c79d                	beqz	a5,8000262c <wait+0x11c>
      release(&wait_lock);
    80002600:	0000f517          	auipc	a0,0xf
    80002604:	cb850513          	addi	a0,a0,-840 # 800112b8 <wait_lock>
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	680080e7          	jalr	1664(ra) # 80000c88 <release>
      return -1;
    80002610:	59fd                	li	s3,-1
}
    80002612:	854e                	mv	a0,s3
    80002614:	60a6                	ld	ra,72(sp)
    80002616:	6406                	ld	s0,64(sp)
    80002618:	74e2                	ld	s1,56(sp)
    8000261a:	7942                	ld	s2,48(sp)
    8000261c:	79a2                	ld	s3,40(sp)
    8000261e:	7a02                	ld	s4,32(sp)
    80002620:	6ae2                	ld	s5,24(sp)
    80002622:	6b42                	ld	s6,16(sp)
    80002624:	6ba2                	ld	s7,8(sp)
    80002626:	6c02                	ld	s8,0(sp)
    80002628:	6161                	addi	sp,sp,80
    8000262a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000262c:	85e2                	mv	a1,s8
    8000262e:	854a                	mv	a0,s2
    80002630:	00000097          	auipc	ra,0x0
    80002634:	e7c080e7          	jalr	-388(ra) # 800024ac <sleep>
    havekids = 0;
    80002638:	b70d                	j	8000255a <wait+0x4a>

000000008000263a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000263a:	7139                	addi	sp,sp,-64
    8000263c:	fc06                	sd	ra,56(sp)
    8000263e:	f822                	sd	s0,48(sp)
    80002640:	f426                	sd	s1,40(sp)
    80002642:	f04a                	sd	s2,32(sp)
    80002644:	ec4e                	sd	s3,24(sp)
    80002646:	e852                	sd	s4,16(sp)
    80002648:	e456                	sd	s5,8(sp)
    8000264a:	0080                	addi	s0,sp,64
    8000264c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000264e:	0000f497          	auipc	s1,0xf
    80002652:	08248493          	addi	s1,s1,130 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002656:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002658:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000265a:	0001b917          	auipc	s2,0x1b
    8000265e:	07690913          	addi	s2,s2,118 # 8001d6d0 <tickslock>
    80002662:	a811                	j	80002676 <wakeup+0x3c>
      }
      release(&p->lock);
    80002664:	8526                	mv	a0,s1
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	622080e7          	jalr	1570(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000266e:	30048493          	addi	s1,s1,768
    80002672:	03248663          	beq	s1,s2,8000269e <wakeup+0x64>
    if(p != myproc()){
    80002676:	fffff097          	auipc	ra,0xfffff
    8000267a:	33e080e7          	jalr	830(ra) # 800019b4 <myproc>
    8000267e:	fea488e3          	beq	s1,a0,8000266e <wakeup+0x34>
      acquire(&p->lock);
    80002682:	8526                	mv	a0,s1
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	53e080e7          	jalr	1342(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000268c:	4c9c                	lw	a5,24(s1)
    8000268e:	fd379be3          	bne	a5,s3,80002664 <wakeup+0x2a>
    80002692:	709c                	ld	a5,32(s1)
    80002694:	fd4798e3          	bne	a5,s4,80002664 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002698:	0154ac23          	sw	s5,24(s1)
    8000269c:	b7e1                	j	80002664 <wakeup+0x2a>
    }
  }
}
    8000269e:	70e2                	ld	ra,56(sp)
    800026a0:	7442                	ld	s0,48(sp)
    800026a2:	74a2                	ld	s1,40(sp)
    800026a4:	7902                	ld	s2,32(sp)
    800026a6:	69e2                	ld	s3,24(sp)
    800026a8:	6a42                	ld	s4,16(sp)
    800026aa:	6aa2                	ld	s5,8(sp)
    800026ac:	6121                	addi	sp,sp,64
    800026ae:	8082                	ret

00000000800026b0 <reparent>:
{
    800026b0:	7179                	addi	sp,sp,-48
    800026b2:	f406                	sd	ra,40(sp)
    800026b4:	f022                	sd	s0,32(sp)
    800026b6:	ec26                	sd	s1,24(sp)
    800026b8:	e84a                	sd	s2,16(sp)
    800026ba:	e44e                	sd	s3,8(sp)
    800026bc:	e052                	sd	s4,0(sp)
    800026be:	1800                	addi	s0,sp,48
    800026c0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026c2:	0000f497          	auipc	s1,0xf
    800026c6:	00e48493          	addi	s1,s1,14 # 800116d0 <proc>
      pp->parent = initproc;
    800026ca:	00007a17          	auipc	s4,0x7
    800026ce:	95ea0a13          	addi	s4,s4,-1698 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026d2:	0001b997          	auipc	s3,0x1b
    800026d6:	ffe98993          	addi	s3,s3,-2 # 8001d6d0 <tickslock>
    800026da:	a029                	j	800026e4 <reparent+0x34>
    800026dc:	30048493          	addi	s1,s1,768
    800026e0:	01348f63          	beq	s1,s3,800026fe <reparent+0x4e>
    if(pp->parent == p){
    800026e4:	1d04b783          	ld	a5,464(s1)
    800026e8:	ff279ae3          	bne	a5,s2,800026dc <reparent+0x2c>
      pp->parent = initproc;
    800026ec:	000a3503          	ld	a0,0(s4)
    800026f0:	1ca4b823          	sd	a0,464(s1)
      wakeup(initproc);
    800026f4:	00000097          	auipc	ra,0x0
    800026f8:	f46080e7          	jalr	-186(ra) # 8000263a <wakeup>
    800026fc:	b7c5                	j	800026dc <reparent+0x2c>
}
    800026fe:	70a2                	ld	ra,40(sp)
    80002700:	7402                	ld	s0,32(sp)
    80002702:	64e2                	ld	s1,24(sp)
    80002704:	6942                	ld	s2,16(sp)
    80002706:	69a2                	ld	s3,8(sp)
    80002708:	6a02                	ld	s4,0(sp)
    8000270a:	6145                	addi	sp,sp,48
    8000270c:	8082                	ret

000000008000270e <exit>:
{
    8000270e:	7179                	addi	sp,sp,-48
    80002710:	f406                	sd	ra,40(sp)
    80002712:	f022                	sd	s0,32(sp)
    80002714:	ec26                	sd	s1,24(sp)
    80002716:	e84a                	sd	s2,16(sp)
    80002718:	e44e                	sd	s3,8(sp)
    8000271a:	e052                	sd	s4,0(sp)
    8000271c:	1800                	addi	s0,sp,48
    8000271e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	294080e7          	jalr	660(ra) # 800019b4 <myproc>
    80002728:	89aa                	mv	s3,a0
  if(p == initproc)
    8000272a:	00007797          	auipc	a5,0x7
    8000272e:	8fe7b783          	ld	a5,-1794(a5) # 80009028 <initproc>
    80002732:	26850493          	addi	s1,a0,616
    80002736:	2e850913          	addi	s2,a0,744
    8000273a:	02a79363          	bne	a5,a0,80002760 <exit+0x52>
    panic("init exiting");
    8000273e:	00006517          	auipc	a0,0x6
    80002742:	c2250513          	addi	a0,a0,-990 # 80008360 <digits+0x320>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	de4080e7          	jalr	-540(ra) # 8000052a <panic>
      fileclose(f);
    8000274e:	00002097          	auipc	ra,0x2
    80002752:	4b6080e7          	jalr	1206(ra) # 80004c04 <fileclose>
      p->ofile[fd] = 0;
    80002756:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000275a:	04a1                	addi	s1,s1,8
    8000275c:	01248563          	beq	s1,s2,80002766 <exit+0x58>
    if(p->ofile[fd]){
    80002760:	6088                	ld	a0,0(s1)
    80002762:	f575                	bnez	a0,8000274e <exit+0x40>
    80002764:	bfdd                	j	8000275a <exit+0x4c>
  begin_op();
    80002766:	00002097          	auipc	ra,0x2
    8000276a:	fd2080e7          	jalr	-46(ra) # 80004738 <begin_op>
  iput(p->cwd);
    8000276e:	2e89b503          	ld	a0,744(s3)
    80002772:	00001097          	auipc	ra,0x1
    80002776:	7aa080e7          	jalr	1962(ra) # 80003f1c <iput>
  end_op();
    8000277a:	00002097          	auipc	ra,0x2
    8000277e:	03e080e7          	jalr	62(ra) # 800047b8 <end_op>
  p->cwd = 0;
    80002782:	2e09b423          	sd	zero,744(s3)
  acquire(&wait_lock);
    80002786:	0000f497          	auipc	s1,0xf
    8000278a:	b3248493          	addi	s1,s1,-1230 # 800112b8 <wait_lock>
    8000278e:	8526                	mv	a0,s1
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	432080e7          	jalr	1074(ra) # 80000bc2 <acquire>
  reparent(p);
    80002798:	854e                	mv	a0,s3
    8000279a:	00000097          	auipc	ra,0x0
    8000279e:	f16080e7          	jalr	-234(ra) # 800026b0 <reparent>
  wakeup(p->parent);
    800027a2:	1d09b503          	ld	a0,464(s3)
    800027a6:	00000097          	auipc	ra,0x0
    800027aa:	e94080e7          	jalr	-364(ra) # 8000263a <wakeup>
  acquire(&p->lock);
    800027ae:	854e                	mv	a0,s3
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	412080e7          	jalr	1042(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800027b8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027bc:	4795                	li	a5,5
    800027be:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800027c2:	8526                	mv	a0,s1
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	4c4080e7          	jalr	1220(ra) # 80000c88 <release>
  sched();
    800027cc:	00000097          	auipc	ra,0x0
    800027d0:	9a4080e7          	jalr	-1628(ra) # 80002170 <sched>
  panic("zombie exit");
    800027d4:	00006517          	auipc	a0,0x6
    800027d8:	b9c50513          	addi	a0,a0,-1124 # 80008370 <digits+0x330>
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	d4e080e7          	jalr	-690(ra) # 8000052a <panic>

00000000800027e4 <kill>:

// ADDED Q2.2.1
int
kill(int pid, int signum)
{
    800027e4:	7179                	addi	sp,sp,-48
    800027e6:	f406                	sd	ra,40(sp)
    800027e8:	f022                	sd	s0,32(sp)
    800027ea:	ec26                	sd	s1,24(sp)
    800027ec:	e84a                	sd	s2,16(sp)
    800027ee:	e44e                	sd	s3,8(sp)
    800027f0:	e052                	sd	s4,0(sp)
    800027f2:	1800                	addi	s0,sp,48
    800027f4:	892a                	mv	s2,a0
    800027f6:	8a2e                	mv	s4,a1
  printf("kill syscall\n");//TODO REMOVE
    800027f8:	00006517          	auipc	a0,0x6
    800027fc:	b8850513          	addi	a0,a0,-1144 # 80008380 <digits+0x340>
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	d74080e7          	jalr	-652(ra) # 80000574 <printf>
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    80002808:	000a071b          	sext.w	a4,s4
    8000280c:	47fd                	li	a5,31
    8000280e:	06e7e463          	bltu	a5,a4,80002876 <kill+0x92>
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002812:	0000f497          	auipc	s1,0xf
    80002816:	ebe48493          	addi	s1,s1,-322 # 800116d0 <proc>
    8000281a:	0001b997          	auipc	s3,0x1b
    8000281e:	eb698993          	addi	s3,s3,-330 # 8001d6d0 <tickslock>
    acquire(&p->lock);
    80002822:	8526                	mv	a0,s1
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	39e080e7          	jalr	926(ra) # 80000bc2 <acquire>
    if(p->pid == pid) {
    8000282c:	589c                	lw	a5,48(s1)
    8000282e:	01278d63          	beq	a5,s2,80002848 <kill+0x64>
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002832:	8526                	mv	a0,s1
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	454080e7          	jalr	1108(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000283c:	30048493          	addi	s1,s1,768
    80002840:	ff3491e3          	bne	s1,s3,80002822 <kill+0x3e>
  }
  // no such pid
  return -1;
    80002844:	557d                	li	a0,-1
    80002846:	a005                	j	80002866 <kill+0x82>
      p->pending_signals = p->pending_signals | (1 << signum);
    80002848:	4585                	li	a1,1
    8000284a:	014595bb          	sllw	a1,a1,s4
    8000284e:	0344aa03          	lw	s4,52(s1)
    80002852:	00ba6a33          	or	s4,s4,a1
    80002856:	0344aa23          	sw	s4,52(s1)
      release(&p->lock);
    8000285a:	8526                	mv	a0,s1
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	42c080e7          	jalr	1068(ra) # 80000c88 <release>
      return 0;
    80002864:	4501                	li	a0,0
}
    80002866:	70a2                	ld	ra,40(sp)
    80002868:	7402                	ld	s0,32(sp)
    8000286a:	64e2                	ld	s1,24(sp)
    8000286c:	6942                	ld	s2,16(sp)
    8000286e:	69a2                	ld	s3,8(sp)
    80002870:	6a02                	ld	s4,0(sp)
    80002872:	6145                	addi	sp,sp,48
    80002874:	8082                	ret
    return -1;
    80002876:	557d                	li	a0,-1
    80002878:	b7fd                	j	80002866 <kill+0x82>

000000008000287a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000287a:	7179                	addi	sp,sp,-48
    8000287c:	f406                	sd	ra,40(sp)
    8000287e:	f022                	sd	s0,32(sp)
    80002880:	ec26                	sd	s1,24(sp)
    80002882:	e84a                	sd	s2,16(sp)
    80002884:	e44e                	sd	s3,8(sp)
    80002886:	e052                	sd	s4,0(sp)
    80002888:	1800                	addi	s0,sp,48
    8000288a:	84aa                	mv	s1,a0
    8000288c:	892e                	mv	s2,a1
    8000288e:	89b2                	mv	s3,a2
    80002890:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	122080e7          	jalr	290(ra) # 800019b4 <myproc>
  if(user_dst){
    8000289a:	c095                	beqz	s1,800028be <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    8000289c:	86d2                	mv	a3,s4
    8000289e:	864e                	mv	a2,s3
    800028a0:	85ca                	mv	a1,s2
    800028a2:	1e853503          	ld	a0,488(a0)
    800028a6:	fffff097          	auipc	ra,0xfffff
    800028aa:	dcc080e7          	jalr	-564(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800028ae:	70a2                	ld	ra,40(sp)
    800028b0:	7402                	ld	s0,32(sp)
    800028b2:	64e2                	ld	s1,24(sp)
    800028b4:	6942                	ld	s2,16(sp)
    800028b6:	69a2                	ld	s3,8(sp)
    800028b8:	6a02                	ld	s4,0(sp)
    800028ba:	6145                	addi	sp,sp,48
    800028bc:	8082                	ret
    memmove((char *)dst, src, len);
    800028be:	000a061b          	sext.w	a2,s4
    800028c2:	85ce                	mv	a1,s3
    800028c4:	854a                	mv	a0,s2
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	478080e7          	jalr	1144(ra) # 80000d3e <memmove>
    return 0;
    800028ce:	8526                	mv	a0,s1
    800028d0:	bff9                	j	800028ae <either_copyout+0x34>

00000000800028d2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028d2:	7179                	addi	sp,sp,-48
    800028d4:	f406                	sd	ra,40(sp)
    800028d6:	f022                	sd	s0,32(sp)
    800028d8:	ec26                	sd	s1,24(sp)
    800028da:	e84a                	sd	s2,16(sp)
    800028dc:	e44e                	sd	s3,8(sp)
    800028de:	e052                	sd	s4,0(sp)
    800028e0:	1800                	addi	s0,sp,48
    800028e2:	892a                	mv	s2,a0
    800028e4:	84ae                	mv	s1,a1
    800028e6:	89b2                	mv	s3,a2
    800028e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028ea:	fffff097          	auipc	ra,0xfffff
    800028ee:	0ca080e7          	jalr	202(ra) # 800019b4 <myproc>
  if(user_src){
    800028f2:	c095                	beqz	s1,80002916 <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    800028f4:	86d2                	mv	a3,s4
    800028f6:	864e                	mv	a2,s3
    800028f8:	85ca                	mv	a1,s2
    800028fa:	1e853503          	ld	a0,488(a0)
    800028fe:	fffff097          	auipc	ra,0xfffff
    80002902:	e00080e7          	jalr	-512(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002906:	70a2                	ld	ra,40(sp)
    80002908:	7402                	ld	s0,32(sp)
    8000290a:	64e2                	ld	s1,24(sp)
    8000290c:	6942                	ld	s2,16(sp)
    8000290e:	69a2                	ld	s3,8(sp)
    80002910:	6a02                	ld	s4,0(sp)
    80002912:	6145                	addi	sp,sp,48
    80002914:	8082                	ret
    memmove(dst, (char*)src, len);
    80002916:	000a061b          	sext.w	a2,s4
    8000291a:	85ce                	mv	a1,s3
    8000291c:	854a                	mv	a0,s2
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	420080e7          	jalr	1056(ra) # 80000d3e <memmove>
    return 0;
    80002926:	8526                	mv	a0,s1
    80002928:	bff9                	j	80002906 <either_copyin+0x34>

000000008000292a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000292a:	715d                	addi	sp,sp,-80
    8000292c:	e486                	sd	ra,72(sp)
    8000292e:	e0a2                	sd	s0,64(sp)
    80002930:	fc26                	sd	s1,56(sp)
    80002932:	f84a                	sd	s2,48(sp)
    80002934:	f44e                	sd	s3,40(sp)
    80002936:	f052                	sd	s4,32(sp)
    80002938:	ec56                	sd	s5,24(sp)
    8000293a:	e85a                	sd	s6,16(sp)
    8000293c:	e45e                	sd	s7,8(sp)
    8000293e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002940:	00006517          	auipc	a0,0x6
    80002944:	9e050513          	addi	a0,a0,-1568 # 80008320 <digits+0x2e0>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c2c080e7          	jalr	-980(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002950:	0000f497          	auipc	s1,0xf
    80002954:	07048493          	addi	s1,s1,112 # 800119c0 <proc+0x2f0>
    80002958:	0001b917          	auipc	s2,0x1b
    8000295c:	06890913          	addi	s2,s2,104 # 8001d9c0 <bcache+0x2d8>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002960:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002962:	00006997          	auipc	s3,0x6
    80002966:	a2e98993          	addi	s3,s3,-1490 # 80008390 <digits+0x350>
    printf("%d %s %s", p->pid, state, p->name);
    8000296a:	00006a97          	auipc	s5,0x6
    8000296e:	a2ea8a93          	addi	s5,s5,-1490 # 80008398 <digits+0x358>
    printf("\n");
    80002972:	00006a17          	auipc	s4,0x6
    80002976:	9aea0a13          	addi	s4,s4,-1618 # 80008320 <digits+0x2e0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000297a:	00006b97          	auipc	s7,0x6
    8000297e:	a7eb8b93          	addi	s7,s7,-1410 # 800083f8 <states.0>
    80002982:	a00d                	j	800029a4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002984:	d406a583          	lw	a1,-704(a3)
    80002988:	8556                	mv	a0,s5
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	bea080e7          	jalr	-1046(ra) # 80000574 <printf>
    printf("\n");
    80002992:	8552                	mv	a0,s4
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	be0080e7          	jalr	-1056(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000299c:	30048493          	addi	s1,s1,768
    800029a0:	03248263          	beq	s1,s2,800029c4 <procdump+0x9a>
    if(p->state == UNUSED)
    800029a4:	86a6                	mv	a3,s1
    800029a6:	d284a783          	lw	a5,-728(s1)
    800029aa:	dbed                	beqz	a5,8000299c <procdump+0x72>
      state = "???";
    800029ac:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ae:	fcfb6be3          	bltu	s6,a5,80002984 <procdump+0x5a>
    800029b2:	02079713          	slli	a4,a5,0x20
    800029b6:	01d75793          	srli	a5,a4,0x1d
    800029ba:	97de                	add	a5,a5,s7
    800029bc:	6390                	ld	a2,0(a5)
    800029be:	f279                	bnez	a2,80002984 <procdump+0x5a>
      state = "???";
    800029c0:	864e                	mv	a2,s3
    800029c2:	b7c9                	j	80002984 <procdump+0x5a>
  }
}
    800029c4:	60a6                	ld	ra,72(sp)
    800029c6:	6406                	ld	s0,64(sp)
    800029c8:	74e2                	ld	s1,56(sp)
    800029ca:	7942                	ld	s2,48(sp)
    800029cc:	79a2                	ld	s3,40(sp)
    800029ce:	7a02                	ld	s4,32(sp)
    800029d0:	6ae2                	ld	s5,24(sp)
    800029d2:	6b42                	ld	s6,16(sp)
    800029d4:	6ba2                	ld	s7,8(sp)
    800029d6:	6161                	addi	sp,sp,80
    800029d8:	8082                	ret

00000000800029da <sigprocmask>:

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
    800029da:	7179                	addi	sp,sp,-48
    800029dc:	f406                	sd	ra,40(sp)
    800029de:	f022                	sd	s0,32(sp)
    800029e0:	ec26                	sd	s1,24(sp)
    800029e2:	e84a                	sd	s2,16(sp)
    800029e4:	e44e                	sd	s3,8(sp)
    800029e6:	1800                	addi	s0,sp,48
    800029e8:	892a                	mv	s2,a0
  printf("sigprocmask\n"); // TODO REMOVE
    800029ea:	00006517          	auipc	a0,0x6
    800029ee:	9be50513          	addi	a0,a0,-1602 # 800083a8 <digits+0x368>
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	b82080e7          	jalr	-1150(ra) # 80000574 <printf>
  struct proc *p = myproc();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	fba080e7          	jalr	-70(ra) # 800019b4 <myproc>
    80002a02:	84aa                	mv	s1,a0
  uint old_mask = p->signal_mask;
    80002a04:	03852983          	lw	s3,56(a0)
  acquire(&p->lock);
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	1ba080e7          	jalr	442(ra) # 80000bc2 <acquire>

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    80002a10:	000207b7          	lui	a5,0x20
    80002a14:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    80002a18:	00f977b3          	and	a5,s2,a5
    80002a1c:	e385                	bnez	a5,80002a3c <sigprocmask+0x62>
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
    80002a1e:	0324ac23          	sw	s2,56(s1)
  release(&p->lock);
    80002a22:	8526                	mv	a0,s1
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	264080e7          	jalr	612(ra) # 80000c88 <release>
  return old_mask;
}
    80002a2c:	854e                	mv	a0,s3
    80002a2e:	70a2                	ld	ra,40(sp)
    80002a30:	7402                	ld	s0,32(sp)
    80002a32:	64e2                	ld	s1,24(sp)
    80002a34:	6942                	ld	s2,16(sp)
    80002a36:	69a2                	ld	s3,8(sp)
    80002a38:	6145                	addi	sp,sp,48
    80002a3a:	8082                	ret
    release(&p->lock);
    80002a3c:	8526                	mv	a0,s1
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	24a080e7          	jalr	586(ra) # 80000c88 <release>
    return -1;
    80002a46:	59fd                	li	s3,-1
    80002a48:	b7d5                	j	80002a2c <sigprocmask+0x52>

0000000080002a4a <sigaction>:

// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
    80002a4a:	711d                	addi	sp,sp,-96
    80002a4c:	ec86                	sd	ra,88(sp)
    80002a4e:	e8a2                	sd	s0,80(sp)
    80002a50:	e4a6                	sd	s1,72(sp)
    80002a52:	e0ca                	sd	s2,64(sp)
    80002a54:	fc4e                	sd	s3,56(sp)
    80002a56:	f852                	sd	s4,48(sp)
    80002a58:	f456                	sd	s5,40(sp)
    80002a5a:	1080                	addi	s0,sp,96
    80002a5c:	84aa                	mv	s1,a0
    80002a5e:	89ae                	mv	s3,a1
    80002a60:	8a32                	mv	s4,a2
  printf("sigaction\n"); // TODO REMOVE
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	95650513          	addi	a0,a0,-1706 # 800083b8 <digits+0x378>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b0a080e7          	jalr	-1270(ra) # 80000574 <printf>
  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    80002a72:	0004879b          	sext.w	a5,s1
    80002a76:	477d                	li	a4,31
    80002a78:	0cf76763          	bltu	a4,a5,80002b46 <sigaction+0xfc>
    80002a7c:	37dd                	addiw	a5,a5,-9
    80002a7e:	9bdd                	andi	a5,a5,-9
    80002a80:	2781                	sext.w	a5,a5
    80002a82:	c7e1                	beqz	a5,80002b4a <sigaction+0x100>
    return -1;
  }

  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((act->sigmask & (1 << SIGKILL)) != 0) || ((act->sigmask & (1 << SIGSTOP)) != 0)) ) {
    80002a84:	0c098763          	beqz	s3,80002b52 <sigaction+0x108>
    80002a88:	0089b783          	ld	a5,8(s3)
    80002a8c:	00020737          	lui	a4,0x20
    80002a90:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    80002a94:	8ff9                	and	a5,a5,a4
    80002a96:	efc5                	bnez	a5,80002b4e <sigaction+0x104>
    return -1;
  }

  struct proc *p = myproc();
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	f1c080e7          	jalr	-228(ra) # 800019b4 <myproc>
    80002aa0:	892a                	mv	s2,a0
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;
  acquire(&p->lock);
    80002aa2:	8aaa                	mv	s5,a0
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	11e080e7          	jalr	286(ra) # 80000bc2 <acquire>

  if (oldact) {
    80002aac:	020a0c63          	beqz	s4,80002ae4 <sigaction+0x9a>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002ab0:	00848793          	addi	a5,s1,8
    80002ab4:	078e                	slli	a5,a5,0x3
    80002ab6:	97ca                	add	a5,a5,s2
    80002ab8:	639c                	ld	a5,0(a5)
    80002aba:	faf43023          	sd	a5,-96(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002abe:	05048793          	addi	a5,s1,80
    80002ac2:	078a                	slli	a5,a5,0x2
    80002ac4:	97ca                	add	a5,a5,s2
    80002ac6:	439c                	lw	a5,0(a5)
    80002ac8:	faf42423          	sw	a5,-88(s0)

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002acc:	46c1                	li	a3,16
    80002ace:	fa040613          	addi	a2,s0,-96
    80002ad2:	85d2                	mv	a1,s4
    80002ad4:	1e893503          	ld	a0,488(s2)
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	b9a080e7          	jalr	-1126(ra) # 80001672 <copyout>
    80002ae0:	0a054f63          	bltz	a0,80002b9e <sigaction+0x154>
      return -1;
    }
  }

  if (act) {
    if(copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    80002ae4:	46c1                	li	a3,16
    80002ae6:	864e                	mv	a2,s3
    80002ae8:	fb040593          	addi	a1,s0,-80
    80002aec:	1e893503          	ld	a0,488(s2)
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	c0e080e7          	jalr	-1010(ra) # 800016fe <copyin>
    80002af8:	04054063          	bltz	a0,80002b38 <sigaction+0xee>
      release(&p->lock);
      return -1;
    }
    p->signal_handlers[signum] = kernel_act.sa_handler;
    80002afc:	00848793          	addi	a5,s1,8
    80002b00:	078e                	slli	a5,a5,0x3
    80002b02:	97ca                	add	a5,a5,s2
    80002b04:	fb043703          	ld	a4,-80(s0)
    80002b08:	e398                	sd	a4,0(a5)
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
    80002b0a:	05048493          	addi	s1,s1,80
    80002b0e:	048a                	slli	s1,s1,0x2
    80002b10:	9926                	add	s2,s2,s1
    80002b12:	fb842783          	lw	a5,-72(s0)
    80002b16:	00f92023          	sw	a5,0(s2)
  }
  release(&p->lock);
    80002b1a:	8556                	mv	a0,s5
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	16c080e7          	jalr	364(ra) # 80000c88 <release>
  return 0;
    80002b24:	4501                	li	a0,0
}
    80002b26:	60e6                	ld	ra,88(sp)
    80002b28:	6446                	ld	s0,80(sp)
    80002b2a:	64a6                	ld	s1,72(sp)
    80002b2c:	6906                	ld	s2,64(sp)
    80002b2e:	79e2                	ld	s3,56(sp)
    80002b30:	7a42                	ld	s4,48(sp)
    80002b32:	7aa2                	ld	s5,40(sp)
    80002b34:	6125                	addi	sp,sp,96
    80002b36:	8082                	ret
      release(&p->lock);
    80002b38:	854a                	mv	a0,s2
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	14e080e7          	jalr	334(ra) # 80000c88 <release>
      return -1;
    80002b42:	557d                	li	a0,-1
    80002b44:	b7cd                	j	80002b26 <sigaction+0xdc>
    return -1;
    80002b46:	557d                	li	a0,-1
    80002b48:	bff9                	j	80002b26 <sigaction+0xdc>
    80002b4a:	557d                	li	a0,-1
    80002b4c:	bfe9                	j	80002b26 <sigaction+0xdc>
    return -1;
    80002b4e:	557d                	li	a0,-1
    80002b50:	bfd9                	j	80002b26 <sigaction+0xdc>
  struct proc *p = myproc();
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	e62080e7          	jalr	-414(ra) # 800019b4 <myproc>
    80002b5a:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002b5c:	8aaa                	mv	s5,a0
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	064080e7          	jalr	100(ra) # 80000bc2 <acquire>
  if (oldact) {
    80002b66:	fa0a0ae3          	beqz	s4,80002b1a <sigaction+0xd0>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002b6a:	00848793          	addi	a5,s1,8
    80002b6e:	078e                	slli	a5,a5,0x3
    80002b70:	97ca                	add	a5,a5,s2
    80002b72:	639c                	ld	a5,0(a5)
    80002b74:	faf43023          	sd	a5,-96(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002b78:	05048493          	addi	s1,s1,80
    80002b7c:	048a                	slli	s1,s1,0x2
    80002b7e:	94ca                	add	s1,s1,s2
    80002b80:	409c                	lw	a5,0(s1)
    80002b82:	faf42423          	sw	a5,-88(s0)
    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002b86:	46c1                	li	a3,16
    80002b88:	fa040613          	addi	a2,s0,-96
    80002b8c:	85d2                	mv	a1,s4
    80002b8e:	1e893503          	ld	a0,488(s2)
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	ae0080e7          	jalr	-1312(ra) # 80001672 <copyout>
    80002b9a:	f80550e3          	bgez	a0,80002b1a <sigaction+0xd0>
      release(&p->lock);
    80002b9e:	8556                	mv	a0,s5
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	0e8080e7          	jalr	232(ra) # 80000c88 <release>
      return -1;
    80002ba8:	557d                	li	a0,-1
    80002baa:	bfb5                	j	80002b26 <sigaction+0xdc>

0000000080002bac <sigret>:

// ADDED Q2.1.5
void
sigret(void)
{
    80002bac:	1101                	addi	sp,sp,-32
    80002bae:	ec06                	sd	ra,24(sp)
    80002bb0:	e822                	sd	s0,16(sp)
    80002bb2:	e426                	sd	s1,8(sp)
    80002bb4:	1000                	addi	s0,sp,32
  printf("sigret\n"); // TODO REMOVE
    80002bb6:	00006517          	auipc	a0,0x6
    80002bba:	81250513          	addi	a0,a0,-2030 # 800083c8 <digits+0x388>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	9b6080e7          	jalr	-1610(ra) # 80000574 <printf>
  struct proc *p = myproc();
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	dee080e7          	jalr	-530(ra) # 800019b4 <myproc>
    80002bce:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	ff2080e7          	jalr	-14(ra) # 80000bc2 <acquire>
  memmove(p->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    80002bd8:	12000613          	li	a2,288
    80002bdc:	1c04b583          	ld	a1,448(s1)
    80002be0:	1f04b503          	ld	a0,496(s1)
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	15a080e7          	jalr	346(ra) # 80000d3e <memmove>
  p->signal_mask = p->signal_mask_backup;
    80002bec:	5cdc                	lw	a5,60(s1)
    80002bee:	dc9c                	sw	a5,56(s1)
  p->handling_user_level_signal = 0;
    80002bf0:	1c04a623          	sw	zero,460(s1)
  release(&p->lock);
    80002bf4:	8526                	mv	a0,s1
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	092080e7          	jalr	146(ra) # 80000c88 <release>
}
    80002bfe:	60e2                	ld	ra,24(sp)
    80002c00:	6442                	ld	s0,16(sp)
    80002c02:	64a2                	ld	s1,8(sp)
    80002c04:	6105                	addi	sp,sp,32
    80002c06:	8082                	ret

0000000080002c08 <swtch>:
    80002c08:	00153023          	sd	ra,0(a0)
    80002c0c:	00253423          	sd	sp,8(a0)
    80002c10:	e900                	sd	s0,16(a0)
    80002c12:	ed04                	sd	s1,24(a0)
    80002c14:	03253023          	sd	s2,32(a0)
    80002c18:	03353423          	sd	s3,40(a0)
    80002c1c:	03453823          	sd	s4,48(a0)
    80002c20:	03553c23          	sd	s5,56(a0)
    80002c24:	05653023          	sd	s6,64(a0)
    80002c28:	05753423          	sd	s7,72(a0)
    80002c2c:	05853823          	sd	s8,80(a0)
    80002c30:	05953c23          	sd	s9,88(a0)
    80002c34:	07a53023          	sd	s10,96(a0)
    80002c38:	07b53423          	sd	s11,104(a0)
    80002c3c:	0005b083          	ld	ra,0(a1)
    80002c40:	0085b103          	ld	sp,8(a1)
    80002c44:	6980                	ld	s0,16(a1)
    80002c46:	6d84                	ld	s1,24(a1)
    80002c48:	0205b903          	ld	s2,32(a1)
    80002c4c:	0285b983          	ld	s3,40(a1)
    80002c50:	0305ba03          	ld	s4,48(a1)
    80002c54:	0385ba83          	ld	s5,56(a1)
    80002c58:	0405bb03          	ld	s6,64(a1)
    80002c5c:	0485bb83          	ld	s7,72(a1)
    80002c60:	0505bc03          	ld	s8,80(a1)
    80002c64:	0585bc83          	ld	s9,88(a1)
    80002c68:	0605bd03          	ld	s10,96(a1)
    80002c6c:	0685bd83          	ld	s11,104(a1)
    80002c70:	8082                	ret

0000000080002c72 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c72:	1141                	addi	sp,sp,-16
    80002c74:	e406                	sd	ra,8(sp)
    80002c76:	e022                	sd	s0,0(sp)
    80002c78:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c7a:	00005597          	auipc	a1,0x5
    80002c7e:	7ae58593          	addi	a1,a1,1966 # 80008428 <states.0+0x30>
    80002c82:	0001b517          	auipc	a0,0x1b
    80002c86:	a4e50513          	addi	a0,a0,-1458 # 8001d6d0 <tickslock>
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	ea8080e7          	jalr	-344(ra) # 80000b32 <initlock>
}
    80002c92:	60a2                	ld	ra,8(sp)
    80002c94:	6402                	ld	s0,0(sp)
    80002c96:	0141                	addi	sp,sp,16
    80002c98:	8082                	ret

0000000080002c9a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c9a:	1141                	addi	sp,sp,-16
    80002c9c:	e422                	sd	s0,8(sp)
    80002c9e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ca0:	00003797          	auipc	a5,0x3
    80002ca4:	5c078793          	addi	a5,a5,1472 # 80006260 <kernelvec>
    80002ca8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cac:	6422                	ld	s0,8(sp)
    80002cae:	0141                	addi	sp,sp,16
    80002cb0:	8082                	ret

0000000080002cb2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cb2:	1141                	addi	sp,sp,-16
    80002cb4:	e406                	sd	ra,8(sp)
    80002cb6:	e022                	sd	s0,0(sp)
    80002cb8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	cfa080e7          	jalr	-774(ra) # 800019b4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cc6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cc8:	10079073          	csrw	sstatus,a5
  // we're back in user space, where usertrap() is correct.
  intr_off();
  //handle_signals(); // ADDED Q2.4 
  //TODO
  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ccc:	00004617          	auipc	a2,0x4
    80002cd0:	33460613          	addi	a2,a2,820 # 80007000 <_trampoline>
    80002cd4:	00004697          	auipc	a3,0x4
    80002cd8:	32c68693          	addi	a3,a3,812 # 80007000 <_trampoline>
    80002cdc:	8e91                	sub	a3,a3,a2
    80002cde:	040007b7          	lui	a5,0x4000
    80002ce2:	17fd                	addi	a5,a5,-1
    80002ce4:	07b2                	slli	a5,a5,0xc
    80002ce6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ce8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cec:	1f053703          	ld	a4,496(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cf0:	180026f3          	csrr	a3,satp
    80002cf4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cf6:	1f053703          	ld	a4,496(a0)
    80002cfa:	1d853683          	ld	a3,472(a0)
    80002cfe:	6585                	lui	a1,0x1
    80002d00:	96ae                	add	a3,a3,a1
    80002d02:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d04:	1f053703          	ld	a4,496(a0)
    80002d08:	00000697          	auipc	a3,0x0
    80002d0c:	13e68693          	addi	a3,a3,318 # 80002e46 <usertrap>
    80002d10:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d12:	1f053703          	ld	a4,496(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d16:	8692                	mv	a3,tp
    80002d18:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d1a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d1e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d22:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d26:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d2a:	1f053703          	ld	a4,496(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d2e:	6f18                	ld	a4,24(a4)
    80002d30:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d34:	1e853583          	ld	a1,488(a0)
    80002d38:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d3a:	00004717          	auipc	a4,0x4
    80002d3e:	35670713          	addi	a4,a4,854 # 80007090 <userret>
    80002d42:	8f11                	sub	a4,a4,a2
    80002d44:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d46:	577d                	li	a4,-1
    80002d48:	177e                	slli	a4,a4,0x3f
    80002d4a:	8dd9                	or	a1,a1,a4
    80002d4c:	02000537          	lui	a0,0x2000
    80002d50:	157d                	addi	a0,a0,-1
    80002d52:	0536                	slli	a0,a0,0xd
    80002d54:	9782                	jalr	a5
}
    80002d56:	60a2                	ld	ra,8(sp)
    80002d58:	6402                	ld	s0,0(sp)
    80002d5a:	0141                	addi	sp,sp,16
    80002d5c:	8082                	ret

0000000080002d5e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	e426                	sd	s1,8(sp)
    80002d66:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d68:	0001b497          	auipc	s1,0x1b
    80002d6c:	96848493          	addi	s1,s1,-1688 # 8001d6d0 <tickslock>
    80002d70:	8526                	mv	a0,s1
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	e50080e7          	jalr	-432(ra) # 80000bc2 <acquire>
  ticks++;
    80002d7a:	00006517          	auipc	a0,0x6
    80002d7e:	2b650513          	addi	a0,a0,694 # 80009030 <ticks>
    80002d82:	411c                	lw	a5,0(a0)
    80002d84:	2785                	addiw	a5,a5,1
    80002d86:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	8b2080e7          	jalr	-1870(ra) # 8000263a <wakeup>
  release(&tickslock);
    80002d90:	8526                	mv	a0,s1
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	ef6080e7          	jalr	-266(ra) # 80000c88 <release>
}
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	64a2                	ld	s1,8(sp)
    80002da0:	6105                	addi	sp,sp,32
    80002da2:	8082                	ret

0000000080002da4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	e426                	sd	s1,8(sp)
    80002dac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002db2:	00074d63          	bltz	a4,80002dcc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002db6:	57fd                	li	a5,-1
    80002db8:	17fe                	slli	a5,a5,0x3f
    80002dba:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dbc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002dbe:	06f70363          	beq	a4,a5,80002e24 <devintr+0x80>
  }
}
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	64a2                	ld	s1,8(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret
     (scause & 0xff) == 9){
    80002dcc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002dd0:	46a5                	li	a3,9
    80002dd2:	fed792e3          	bne	a5,a3,80002db6 <devintr+0x12>
    int irq = plic_claim();
    80002dd6:	00003097          	auipc	ra,0x3
    80002dda:	592080e7          	jalr	1426(ra) # 80006368 <plic_claim>
    80002dde:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002de0:	47a9                	li	a5,10
    80002de2:	02f50763          	beq	a0,a5,80002e10 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002de6:	4785                	li	a5,1
    80002de8:	02f50963          	beq	a0,a5,80002e1a <devintr+0x76>
    return 1;
    80002dec:	4505                	li	a0,1
    } else if(irq){
    80002dee:	d8f1                	beqz	s1,80002dc2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002df0:	85a6                	mv	a1,s1
    80002df2:	00005517          	auipc	a0,0x5
    80002df6:	63e50513          	addi	a0,a0,1598 # 80008430 <states.0+0x38>
    80002dfa:	ffffd097          	auipc	ra,0xffffd
    80002dfe:	77a080e7          	jalr	1914(ra) # 80000574 <printf>
      plic_complete(irq);
    80002e02:	8526                	mv	a0,s1
    80002e04:	00003097          	auipc	ra,0x3
    80002e08:	588080e7          	jalr	1416(ra) # 8000638c <plic_complete>
    return 1;
    80002e0c:	4505                	li	a0,1
    80002e0e:	bf55                	j	80002dc2 <devintr+0x1e>
      uartintr();
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	b76080e7          	jalr	-1162(ra) # 80000986 <uartintr>
    80002e18:	b7ed                	j	80002e02 <devintr+0x5e>
      virtio_disk_intr();
    80002e1a:	00004097          	auipc	ra,0x4
    80002e1e:	a04080e7          	jalr	-1532(ra) # 8000681e <virtio_disk_intr>
    80002e22:	b7c5                	j	80002e02 <devintr+0x5e>
    if(cpuid() == 0){
    80002e24:	fffff097          	auipc	ra,0xfffff
    80002e28:	b64080e7          	jalr	-1180(ra) # 80001988 <cpuid>
    80002e2c:	c901                	beqz	a0,80002e3c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e2e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e34:	14479073          	csrw	sip,a5
    return 2;
    80002e38:	4509                	li	a0,2
    80002e3a:	b761                	j	80002dc2 <devintr+0x1e>
      clockintr();
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	f22080e7          	jalr	-222(ra) # 80002d5e <clockintr>
    80002e44:	b7ed                	j	80002e2e <devintr+0x8a>

0000000080002e46 <usertrap>:
{
    80002e46:	1101                	addi	sp,sp,-32
    80002e48:	ec06                	sd	ra,24(sp)
    80002e4a:	e822                	sd	s0,16(sp)
    80002e4c:	e426                	sd	s1,8(sp)
    80002e4e:	e04a                	sd	s2,0(sp)
    80002e50:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e52:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e56:	1007f793          	andi	a5,a5,256
    80002e5a:	e3bd                	bnez	a5,80002ec0 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e5c:	00003797          	auipc	a5,0x3
    80002e60:	40478793          	addi	a5,a5,1028 # 80006260 <kernelvec>
    80002e64:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	b4c080e7          	jalr	-1204(ra) # 800019b4 <myproc>
    80002e70:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e72:	1f053783          	ld	a5,496(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e76:	14102773          	csrr	a4,sepc
    80002e7a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e7c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e80:	47a1                	li	a5,8
    80002e82:	04f71d63          	bne	a4,a5,80002edc <usertrap+0x96>
    if(p->killed)
    80002e86:	551c                	lw	a5,40(a0)
    80002e88:	e7a1                	bnez	a5,80002ed0 <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002e8a:	1f04b703          	ld	a4,496(s1)
    80002e8e:	6f1c                	ld	a5,24(a4)
    80002e90:	0791                	addi	a5,a5,4
    80002e92:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e9c:	10079073          	csrw	sstatus,a5
    syscall();
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	2f2080e7          	jalr	754(ra) # 80003192 <syscall>
  if(p->killed)
    80002ea8:	549c                	lw	a5,40(s1)
    80002eaa:	ebc1                	bnez	a5,80002f3a <usertrap+0xf4>
  usertrapret();
    80002eac:	00000097          	auipc	ra,0x0
    80002eb0:	e06080e7          	jalr	-506(ra) # 80002cb2 <usertrapret>
}
    80002eb4:	60e2                	ld	ra,24(sp)
    80002eb6:	6442                	ld	s0,16(sp)
    80002eb8:	64a2                	ld	s1,8(sp)
    80002eba:	6902                	ld	s2,0(sp)
    80002ebc:	6105                	addi	sp,sp,32
    80002ebe:	8082                	ret
    panic("usertrap: not from user mode");
    80002ec0:	00005517          	auipc	a0,0x5
    80002ec4:	59050513          	addi	a0,a0,1424 # 80008450 <states.0+0x58>
    80002ec8:	ffffd097          	auipc	ra,0xffffd
    80002ecc:	662080e7          	jalr	1634(ra) # 8000052a <panic>
      exit(-1);
    80002ed0:	557d                	li	a0,-1
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	83c080e7          	jalr	-1988(ra) # 8000270e <exit>
    80002eda:	bf45                	j	80002e8a <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002edc:	00000097          	auipc	ra,0x0
    80002ee0:	ec8080e7          	jalr	-312(ra) # 80002da4 <devintr>
    80002ee4:	892a                	mv	s2,a0
    80002ee6:	c501                	beqz	a0,80002eee <usertrap+0xa8>
  if(p->killed)
    80002ee8:	549c                	lw	a5,40(s1)
    80002eea:	c3a1                	beqz	a5,80002f2a <usertrap+0xe4>
    80002eec:	a815                	j	80002f20 <usertrap+0xda>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eee:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ef2:	5890                	lw	a2,48(s1)
    80002ef4:	00005517          	auipc	a0,0x5
    80002ef8:	57c50513          	addi	a0,a0,1404 # 80008470 <states.0+0x78>
    80002efc:	ffffd097          	auipc	ra,0xffffd
    80002f00:	678080e7          	jalr	1656(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f04:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f08:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	59450513          	addi	a0,a0,1428 # 800084a0 <states.0+0xa8>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	660080e7          	jalr	1632(ra) # 80000574 <printf>
    p->killed = 1;
    80002f1c:	4785                	li	a5,1
    80002f1e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f20:	557d                	li	a0,-1
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	7ec080e7          	jalr	2028(ra) # 8000270e <exit>
  if(which_dev == 2)
    80002f2a:	4789                	li	a5,2
    80002f2c:	f8f910e3          	bne	s2,a5,80002eac <usertrap+0x66>
    yield();
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	316080e7          	jalr	790(ra) # 80002246 <yield>
    80002f38:	bf95                	j	80002eac <usertrap+0x66>
  int which_dev = 0;
    80002f3a:	4901                	li	s2,0
    80002f3c:	b7d5                	j	80002f20 <usertrap+0xda>

0000000080002f3e <kerneltrap>:
{
    80002f3e:	7179                	addi	sp,sp,-48
    80002f40:	f406                	sd	ra,40(sp)
    80002f42:	f022                	sd	s0,32(sp)
    80002f44:	ec26                	sd	s1,24(sp)
    80002f46:	e84a                	sd	s2,16(sp)
    80002f48:	e44e                	sd	s3,8(sp)
    80002f4a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f4c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f50:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f54:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f58:	1004f793          	andi	a5,s1,256
    80002f5c:	cb85                	beqz	a5,80002f8c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f5e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f62:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f64:	ef85                	bnez	a5,80002f9c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	e3e080e7          	jalr	-450(ra) # 80002da4 <devintr>
    80002f6e:	cd1d                	beqz	a0,80002fac <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f70:	4789                	li	a5,2
    80002f72:	06f50a63          	beq	a0,a5,80002fe6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f76:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f7a:	10049073          	csrw	sstatus,s1
}
    80002f7e:	70a2                	ld	ra,40(sp)
    80002f80:	7402                	ld	s0,32(sp)
    80002f82:	64e2                	ld	s1,24(sp)
    80002f84:	6942                	ld	s2,16(sp)
    80002f86:	69a2                	ld	s3,8(sp)
    80002f88:	6145                	addi	sp,sp,48
    80002f8a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f8c:	00005517          	auipc	a0,0x5
    80002f90:	53450513          	addi	a0,a0,1332 # 800084c0 <states.0+0xc8>
    80002f94:	ffffd097          	auipc	ra,0xffffd
    80002f98:	596080e7          	jalr	1430(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002f9c:	00005517          	auipc	a0,0x5
    80002fa0:	54c50513          	addi	a0,a0,1356 # 800084e8 <states.0+0xf0>
    80002fa4:	ffffd097          	auipc	ra,0xffffd
    80002fa8:	586080e7          	jalr	1414(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002fac:	85ce                	mv	a1,s3
    80002fae:	00005517          	auipc	a0,0x5
    80002fb2:	55a50513          	addi	a0,a0,1370 # 80008508 <states.0+0x110>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	5be080e7          	jalr	1470(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fbe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fc2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	55250513          	addi	a0,a0,1362 # 80008518 <states.0+0x120>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	5a6080e7          	jalr	1446(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002fd6:	00005517          	auipc	a0,0x5
    80002fda:	55a50513          	addi	a0,a0,1370 # 80008530 <states.0+0x138>
    80002fde:	ffffd097          	auipc	ra,0xffffd
    80002fe2:	54c080e7          	jalr	1356(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fe6:	fffff097          	auipc	ra,0xfffff
    80002fea:	9ce080e7          	jalr	-1586(ra) # 800019b4 <myproc>
    80002fee:	d541                	beqz	a0,80002f76 <kerneltrap+0x38>
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	9c4080e7          	jalr	-1596(ra) # 800019b4 <myproc>
    80002ff8:	4d18                	lw	a4,24(a0)
    80002ffa:	4791                	li	a5,4
    80002ffc:	f6f71de3          	bne	a4,a5,80002f76 <kerneltrap+0x38>
    yield();
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	246080e7          	jalr	582(ra) # 80002246 <yield>
    80003008:	b7bd                	j	80002f76 <kerneltrap+0x38>

000000008000300a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000300a:	1101                	addi	sp,sp,-32
    8000300c:	ec06                	sd	ra,24(sp)
    8000300e:	e822                	sd	s0,16(sp)
    80003010:	e426                	sd	s1,8(sp)
    80003012:	1000                	addi	s0,sp,32
    80003014:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	99e080e7          	jalr	-1634(ra) # 800019b4 <myproc>
  switch (n) {
    8000301e:	4795                	li	a5,5
    80003020:	0497e763          	bltu	a5,s1,8000306e <argraw+0x64>
    80003024:	048a                	slli	s1,s1,0x2
    80003026:	00005717          	auipc	a4,0x5
    8000302a:	54270713          	addi	a4,a4,1346 # 80008568 <states.0+0x170>
    8000302e:	94ba                	add	s1,s1,a4
    80003030:	409c                	lw	a5,0(s1)
    80003032:	97ba                	add	a5,a5,a4
    80003034:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003036:	1f053783          	ld	a5,496(a0)
    8000303a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000303c:	60e2                	ld	ra,24(sp)
    8000303e:	6442                	ld	s0,16(sp)
    80003040:	64a2                	ld	s1,8(sp)
    80003042:	6105                	addi	sp,sp,32
    80003044:	8082                	ret
    return p->trapframe->a1;
    80003046:	1f053783          	ld	a5,496(a0)
    8000304a:	7fa8                	ld	a0,120(a5)
    8000304c:	bfc5                	j	8000303c <argraw+0x32>
    return p->trapframe->a2;
    8000304e:	1f053783          	ld	a5,496(a0)
    80003052:	63c8                	ld	a0,128(a5)
    80003054:	b7e5                	j	8000303c <argraw+0x32>
    return p->trapframe->a3;
    80003056:	1f053783          	ld	a5,496(a0)
    8000305a:	67c8                	ld	a0,136(a5)
    8000305c:	b7c5                	j	8000303c <argraw+0x32>
    return p->trapframe->a4;
    8000305e:	1f053783          	ld	a5,496(a0)
    80003062:	6bc8                	ld	a0,144(a5)
    80003064:	bfe1                	j	8000303c <argraw+0x32>
    return p->trapframe->a5;
    80003066:	1f053783          	ld	a5,496(a0)
    8000306a:	6fc8                	ld	a0,152(a5)
    8000306c:	bfc1                	j	8000303c <argraw+0x32>
  panic("argraw");
    8000306e:	00005517          	auipc	a0,0x5
    80003072:	4d250513          	addi	a0,a0,1234 # 80008540 <states.0+0x148>
    80003076:	ffffd097          	auipc	ra,0xffffd
    8000307a:	4b4080e7          	jalr	1204(ra) # 8000052a <panic>

000000008000307e <fetchaddr>:
{
    8000307e:	1101                	addi	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	e426                	sd	s1,8(sp)
    80003086:	e04a                	sd	s2,0(sp)
    80003088:	1000                	addi	s0,sp,32
    8000308a:	84aa                	mv	s1,a0
    8000308c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000308e:	fffff097          	auipc	ra,0xfffff
    80003092:	926080e7          	jalr	-1754(ra) # 800019b4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003096:	1e053783          	ld	a5,480(a0)
    8000309a:	02f4f963          	bgeu	s1,a5,800030cc <fetchaddr+0x4e>
    8000309e:	00848713          	addi	a4,s1,8
    800030a2:	02e7e763          	bltu	a5,a4,800030d0 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030a6:	46a1                	li	a3,8
    800030a8:	8626                	mv	a2,s1
    800030aa:	85ca                	mv	a1,s2
    800030ac:	1e853503          	ld	a0,488(a0)
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	64e080e7          	jalr	1614(ra) # 800016fe <copyin>
    800030b8:	00a03533          	snez	a0,a0
    800030bc:	40a00533          	neg	a0,a0
}
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6902                	ld	s2,0(sp)
    800030c8:	6105                	addi	sp,sp,32
    800030ca:	8082                	ret
    return -1;
    800030cc:	557d                	li	a0,-1
    800030ce:	bfcd                	j	800030c0 <fetchaddr+0x42>
    800030d0:	557d                	li	a0,-1
    800030d2:	b7fd                	j	800030c0 <fetchaddr+0x42>

00000000800030d4 <fetchstr>:
{
    800030d4:	7179                	addi	sp,sp,-48
    800030d6:	f406                	sd	ra,40(sp)
    800030d8:	f022                	sd	s0,32(sp)
    800030da:	ec26                	sd	s1,24(sp)
    800030dc:	e84a                	sd	s2,16(sp)
    800030de:	e44e                	sd	s3,8(sp)
    800030e0:	1800                	addi	s0,sp,48
    800030e2:	892a                	mv	s2,a0
    800030e4:	84ae                	mv	s1,a1
    800030e6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	8cc080e7          	jalr	-1844(ra) # 800019b4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800030f0:	86ce                	mv	a3,s3
    800030f2:	864a                	mv	a2,s2
    800030f4:	85a6                	mv	a1,s1
    800030f6:	1e853503          	ld	a0,488(a0)
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	692080e7          	jalr	1682(ra) # 8000178c <copyinstr>
  if(err < 0)
    80003102:	00054763          	bltz	a0,80003110 <fetchstr+0x3c>
  return strlen(buf);
    80003106:	8526                	mv	a0,s1
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	d5e080e7          	jalr	-674(ra) # 80000e66 <strlen>
}
    80003110:	70a2                	ld	ra,40(sp)
    80003112:	7402                	ld	s0,32(sp)
    80003114:	64e2                	ld	s1,24(sp)
    80003116:	6942                	ld	s2,16(sp)
    80003118:	69a2                	ld	s3,8(sp)
    8000311a:	6145                	addi	sp,sp,48
    8000311c:	8082                	ret

000000008000311e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	ee0080e7          	jalr	-288(ra) # 8000300a <argraw>
    80003132:	c088                	sw	a0,0(s1)
  return 0;
}
    80003134:	4501                	li	a0,0
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret

0000000080003140 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	e426                	sd	s1,8(sp)
    80003148:	1000                	addi	s0,sp,32
    8000314a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000314c:	00000097          	auipc	ra,0x0
    80003150:	ebe080e7          	jalr	-322(ra) # 8000300a <argraw>
    80003154:	e088                	sd	a0,0(s1)
  return 0;
}
    80003156:	4501                	li	a0,0
    80003158:	60e2                	ld	ra,24(sp)
    8000315a:	6442                	ld	s0,16(sp)
    8000315c:	64a2                	ld	s1,8(sp)
    8000315e:	6105                	addi	sp,sp,32
    80003160:	8082                	ret

0000000080003162 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	e426                	sd	s1,8(sp)
    8000316a:	e04a                	sd	s2,0(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84ae                	mv	s1,a1
    80003170:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003172:	00000097          	auipc	ra,0x0
    80003176:	e98080e7          	jalr	-360(ra) # 8000300a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000317a:	864a                	mv	a2,s2
    8000317c:	85a6                	mv	a1,s1
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	f56080e7          	jalr	-170(ra) # 800030d4 <fetchstr>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	64a2                	ld	s1,8(sp)
    8000318c:	6902                	ld	s2,0(sp)
    8000318e:	6105                	addi	sp,sp,32
    80003190:	8082                	ret

0000000080003192 <syscall>:
[SYS_sigret]   sys_sigret, // ADDED Q2.1.5
};

void
syscall(void)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	e04a                	sd	s2,0(sp)
    8000319c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	816080e7          	jalr	-2026(ra) # 800019b4 <myproc>
    800031a6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031a8:	1f053903          	ld	s2,496(a0)
    800031ac:	0a893783          	ld	a5,168(s2)
    800031b0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031b4:	37fd                	addiw	a5,a5,-1
    800031b6:	475d                	li	a4,23
    800031b8:	00f76f63          	bltu	a4,a5,800031d6 <syscall+0x44>
    800031bc:	00369713          	slli	a4,a3,0x3
    800031c0:	00005797          	auipc	a5,0x5
    800031c4:	3c078793          	addi	a5,a5,960 # 80008580 <syscalls>
    800031c8:	97ba                	add	a5,a5,a4
    800031ca:	639c                	ld	a5,0(a5)
    800031cc:	c789                	beqz	a5,800031d6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800031ce:	9782                	jalr	a5
    800031d0:	06a93823          	sd	a0,112(s2)
    800031d4:	a005                	j	800031f4 <syscall+0x62>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031d6:	2f048613          	addi	a2,s1,752
    800031da:	588c                	lw	a1,48(s1)
    800031dc:	00005517          	auipc	a0,0x5
    800031e0:	36c50513          	addi	a0,a0,876 # 80008548 <states.0+0x150>
    800031e4:	ffffd097          	auipc	ra,0xffffd
    800031e8:	390080e7          	jalr	912(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031ec:	1f04b783          	ld	a5,496(s1)
    800031f0:	577d                	li	a4,-1
    800031f2:	fbb8                	sd	a4,112(a5)
  }
}
    800031f4:	60e2                	ld	ra,24(sp)
    800031f6:	6442                	ld	s0,16(sp)
    800031f8:	64a2                	ld	s1,8(sp)
    800031fa:	6902                	ld	s2,0(sp)
    800031fc:	6105                	addi	sp,sp,32
    800031fe:	8082                	ret

0000000080003200 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003200:	1101                	addi	sp,sp,-32
    80003202:	ec06                	sd	ra,24(sp)
    80003204:	e822                	sd	s0,16(sp)
    80003206:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003208:	fec40593          	addi	a1,s0,-20
    8000320c:	4501                	li	a0,0
    8000320e:	00000097          	auipc	ra,0x0
    80003212:	f10080e7          	jalr	-240(ra) # 8000311e <argint>
    return -1;
    80003216:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003218:	00054963          	bltz	a0,8000322a <sys_exit+0x2a>
  exit(n);
    8000321c:	fec42503          	lw	a0,-20(s0)
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	4ee080e7          	jalr	1262(ra) # 8000270e <exit>
  return 0;  // not reached
    80003228:	4781                	li	a5,0
}
    8000322a:	853e                	mv	a0,a5
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	6105                	addi	sp,sp,32
    80003232:	8082                	ret

0000000080003234 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003234:	1141                	addi	sp,sp,-16
    80003236:	e406                	sd	ra,8(sp)
    80003238:	e022                	sd	s0,0(sp)
    8000323a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000323c:	ffffe097          	auipc	ra,0xffffe
    80003240:	778080e7          	jalr	1912(ra) # 800019b4 <myproc>
}
    80003244:	5908                	lw	a0,48(a0)
    80003246:	60a2                	ld	ra,8(sp)
    80003248:	6402                	ld	s0,0(sp)
    8000324a:	0141                	addi	sp,sp,16
    8000324c:	8082                	ret

000000008000324e <sys_fork>:

uint64
sys_fork(void)
{
    8000324e:	1141                	addi	sp,sp,-16
    80003250:	e406                	sd	ra,8(sp)
    80003252:	e022                	sd	s0,0(sp)
    80003254:	0800                	addi	s0,sp,16
  return fork();
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	bb4080e7          	jalr	-1100(ra) # 80001e0a <fork>
}
    8000325e:	60a2                	ld	ra,8(sp)
    80003260:	6402                	ld	s0,0(sp)
    80003262:	0141                	addi	sp,sp,16
    80003264:	8082                	ret

0000000080003266 <sys_wait>:

uint64
sys_wait(void)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000326e:	fe840593          	addi	a1,s0,-24
    80003272:	4501                	li	a0,0
    80003274:	00000097          	auipc	ra,0x0
    80003278:	ecc080e7          	jalr	-308(ra) # 80003140 <argaddr>
    8000327c:	87aa                	mv	a5,a0
    return -1;
    8000327e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003280:	0007c863          	bltz	a5,80003290 <sys_wait+0x2a>
  return wait(p);
    80003284:	fe843503          	ld	a0,-24(s0)
    80003288:	fffff097          	auipc	ra,0xfffff
    8000328c:	288080e7          	jalr	648(ra) # 80002510 <wait>
}
    80003290:	60e2                	ld	ra,24(sp)
    80003292:	6442                	ld	s0,16(sp)
    80003294:	6105                	addi	sp,sp,32
    80003296:	8082                	ret

0000000080003298 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003298:	7179                	addi	sp,sp,-48
    8000329a:	f406                	sd	ra,40(sp)
    8000329c:	f022                	sd	s0,32(sp)
    8000329e:	ec26                	sd	s1,24(sp)
    800032a0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032a2:	fdc40593          	addi	a1,s0,-36
    800032a6:	4501                	li	a0,0
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	e76080e7          	jalr	-394(ra) # 8000311e <argint>
    return -1;
    800032b0:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800032b2:	02054063          	bltz	a0,800032d2 <sys_sbrk+0x3a>
  addr = myproc()->sz;
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	6fe080e7          	jalr	1790(ra) # 800019b4 <myproc>
    800032be:	1e052483          	lw	s1,480(a0)
  if(growproc(n) < 0)
    800032c2:	fdc42503          	lw	a0,-36(s0)
    800032c6:	fffff097          	auipc	ra,0xfffff
    800032ca:	aca080e7          	jalr	-1334(ra) # 80001d90 <growproc>
    800032ce:	00054863          	bltz	a0,800032de <sys_sbrk+0x46>
    return -1;
  return addr;
}
    800032d2:	8526                	mv	a0,s1
    800032d4:	70a2                	ld	ra,40(sp)
    800032d6:	7402                	ld	s0,32(sp)
    800032d8:	64e2                	ld	s1,24(sp)
    800032da:	6145                	addi	sp,sp,48
    800032dc:	8082                	ret
    return -1;
    800032de:	54fd                	li	s1,-1
    800032e0:	bfcd                	j	800032d2 <sys_sbrk+0x3a>

00000000800032e2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032e2:	7139                	addi	sp,sp,-64
    800032e4:	fc06                	sd	ra,56(sp)
    800032e6:	f822                	sd	s0,48(sp)
    800032e8:	f426                	sd	s1,40(sp)
    800032ea:	f04a                	sd	s2,32(sp)
    800032ec:	ec4e                	sd	s3,24(sp)
    800032ee:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800032f0:	fcc40593          	addi	a1,s0,-52
    800032f4:	4501                	li	a0,0
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	e28080e7          	jalr	-472(ra) # 8000311e <argint>
    return -1;
    800032fe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003300:	06054563          	bltz	a0,8000336a <sys_sleep+0x88>
  acquire(&tickslock);
    80003304:	0001a517          	auipc	a0,0x1a
    80003308:	3cc50513          	addi	a0,a0,972 # 8001d6d0 <tickslock>
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	8b6080e7          	jalr	-1866(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003314:	00006917          	auipc	s2,0x6
    80003318:	d1c92903          	lw	s2,-740(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000331c:	fcc42783          	lw	a5,-52(s0)
    80003320:	cf85                	beqz	a5,80003358 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003322:	0001a997          	auipc	s3,0x1a
    80003326:	3ae98993          	addi	s3,s3,942 # 8001d6d0 <tickslock>
    8000332a:	00006497          	auipc	s1,0x6
    8000332e:	d0648493          	addi	s1,s1,-762 # 80009030 <ticks>
    if(myproc()->killed){
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	682080e7          	jalr	1666(ra) # 800019b4 <myproc>
    8000333a:	551c                	lw	a5,40(a0)
    8000333c:	ef9d                	bnez	a5,8000337a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000333e:	85ce                	mv	a1,s3
    80003340:	8526                	mv	a0,s1
    80003342:	fffff097          	auipc	ra,0xfffff
    80003346:	16a080e7          	jalr	362(ra) # 800024ac <sleep>
  while(ticks - ticks0 < n){
    8000334a:	409c                	lw	a5,0(s1)
    8000334c:	412787bb          	subw	a5,a5,s2
    80003350:	fcc42703          	lw	a4,-52(s0)
    80003354:	fce7efe3          	bltu	a5,a4,80003332 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003358:	0001a517          	auipc	a0,0x1a
    8000335c:	37850513          	addi	a0,a0,888 # 8001d6d0 <tickslock>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	928080e7          	jalr	-1752(ra) # 80000c88 <release>
  return 0;
    80003368:	4781                	li	a5,0
}
    8000336a:	853e                	mv	a0,a5
    8000336c:	70e2                	ld	ra,56(sp)
    8000336e:	7442                	ld	s0,48(sp)
    80003370:	74a2                	ld	s1,40(sp)
    80003372:	7902                	ld	s2,32(sp)
    80003374:	69e2                	ld	s3,24(sp)
    80003376:	6121                	addi	sp,sp,64
    80003378:	8082                	ret
      release(&tickslock);
    8000337a:	0001a517          	auipc	a0,0x1a
    8000337e:	35650513          	addi	a0,a0,854 # 8001d6d0 <tickslock>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	906080e7          	jalr	-1786(ra) # 80000c88 <release>
      return -1;
    8000338a:	57fd                	li	a5,-1
    8000338c:	bff9                	j	8000336a <sys_sleep+0x88>

000000008000338e <sys_kill>:

// ADDED Q2.2.1
uint64
sys_kill(void)
{
    8000338e:	1101                	addi	sp,sp,-32
    80003390:	ec06                	sd	ra,24(sp)
    80003392:	e822                	sd	s0,16(sp)
    80003394:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    80003396:	fec40593          	addi	a1,s0,-20
    8000339a:	4501                	li	a0,0
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	d82080e7          	jalr	-638(ra) # 8000311e <argint>
    return -1;
    800033a4:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    800033a6:	02054563          	bltz	a0,800033d0 <sys_kill+0x42>

  if(argint(1, &signum) < 0)
    800033aa:	fe840593          	addi	a1,s0,-24
    800033ae:	4505                	li	a0,1
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	d6e080e7          	jalr	-658(ra) # 8000311e <argint>
    return -1;
    800033b8:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    800033ba:	00054b63          	bltz	a0,800033d0 <sys_kill+0x42>

  return kill(pid, signum);
    800033be:	fe842583          	lw	a1,-24(s0)
    800033c2:	fec42503          	lw	a0,-20(s0)
    800033c6:	fffff097          	auipc	ra,0xfffff
    800033ca:	41e080e7          	jalr	1054(ra) # 800027e4 <kill>
    800033ce:	87aa                	mv	a5,a0
}
    800033d0:	853e                	mv	a0,a5
    800033d2:	60e2                	ld	ra,24(sp)
    800033d4:	6442                	ld	s0,16(sp)
    800033d6:	6105                	addi	sp,sp,32
    800033d8:	8082                	ret

00000000800033da <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033da:	1101                	addi	sp,sp,-32
    800033dc:	ec06                	sd	ra,24(sp)
    800033de:	e822                	sd	s0,16(sp)
    800033e0:	e426                	sd	s1,8(sp)
    800033e2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033e4:	0001a517          	auipc	a0,0x1a
    800033e8:	2ec50513          	addi	a0,a0,748 # 8001d6d0 <tickslock>
    800033ec:	ffffd097          	auipc	ra,0xffffd
    800033f0:	7d6080e7          	jalr	2006(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800033f4:	00006497          	auipc	s1,0x6
    800033f8:	c3c4a483          	lw	s1,-964(s1) # 80009030 <ticks>
  release(&tickslock);
    800033fc:	0001a517          	auipc	a0,0x1a
    80003400:	2d450513          	addi	a0,a0,724 # 8001d6d0 <tickslock>
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	884080e7          	jalr	-1916(ra) # 80000c88 <release>
  return xticks;
}
    8000340c:	02049513          	slli	a0,s1,0x20
    80003410:	9101                	srli	a0,a0,0x20
    80003412:	60e2                	ld	ra,24(sp)
    80003414:	6442                	ld	s0,16(sp)
    80003416:	64a2                	ld	s1,8(sp)
    80003418:	6105                	addi	sp,sp,32
    8000341a:	8082                	ret

000000008000341c <sys_sigprocmask>:

// ADDED Q2.1.3
uint64
sys_sigprocmask(void)
{
    8000341c:	1101                	addi	sp,sp,-32
    8000341e:	ec06                	sd	ra,24(sp)
    80003420:	e822                	sd	s0,16(sp)
    80003422:	1000                	addi	s0,sp,32
  uint sigmask;

  if(argint(0, (int *)&sigmask) < 0) 
    80003424:	fec40593          	addi	a1,s0,-20
    80003428:	4501                	li	a0,0
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	cf4080e7          	jalr	-780(ra) # 8000311e <argint>
    80003432:	87aa                	mv	a5,a0
    return -1;
    80003434:	557d                	li	a0,-1
  if(argint(0, (int *)&sigmask) < 0) 
    80003436:	0007ca63          	bltz	a5,8000344a <sys_sigprocmask+0x2e>

  return sigprocmask(sigmask);
    8000343a:	fec42503          	lw	a0,-20(s0)
    8000343e:	fffff097          	auipc	ra,0xfffff
    80003442:	59c080e7          	jalr	1436(ra) # 800029da <sigprocmask>
    80003446:	1502                	slli	a0,a0,0x20
    80003448:	9101                	srli	a0,a0,0x20
}
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	6105                	addi	sp,sp,32
    80003450:	8082                	ret

0000000080003452 <sys_sigaction>:

// ADDED Q2.1.4
uint64
sys_sigaction(void)
{
    80003452:	7179                	addi	sp,sp,-48
    80003454:	f406                	sd	ra,40(sp)
    80003456:	f022                	sd	s0,32(sp)
    80003458:	1800                	addi	s0,sp,48
  int signum;
  uint64 act;
  uint64 oldact;

  if(argint(0, &signum) < 0)
    8000345a:	fec40593          	addi	a1,s0,-20
    8000345e:	4501                	li	a0,0
    80003460:	00000097          	auipc	ra,0x0
    80003464:	cbe080e7          	jalr	-834(ra) # 8000311e <argint>
    return -1;
    80003468:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    8000346a:	04054163          	bltz	a0,800034ac <sys_sigaction+0x5a>

  if(argaddr(1, &act) < 0)
    8000346e:	fe040593          	addi	a1,s0,-32
    80003472:	4505                	li	a0,1
    80003474:	00000097          	auipc	ra,0x0
    80003478:	ccc080e7          	jalr	-820(ra) # 80003140 <argaddr>
    return -1;
    8000347c:	57fd                	li	a5,-1
  if(argaddr(1, &act) < 0)
    8000347e:	02054763          	bltz	a0,800034ac <sys_sigaction+0x5a>

  if(argaddr(2, &oldact) < 0)
    80003482:	fd840593          	addi	a1,s0,-40
    80003486:	4509                	li	a0,2
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	cb8080e7          	jalr	-840(ra) # 80003140 <argaddr>
    return -1;
    80003490:	57fd                	li	a5,-1
  if(argaddr(2, &oldact) < 0)
    80003492:	00054d63          	bltz	a0,800034ac <sys_sigaction+0x5a>

  return sigaction(signum, (struct sigaction *)act, (struct sigaction *)oldact);
    80003496:	fd843603          	ld	a2,-40(s0)
    8000349a:	fe043583          	ld	a1,-32(s0)
    8000349e:	fec42503          	lw	a0,-20(s0)
    800034a2:	fffff097          	auipc	ra,0xfffff
    800034a6:	5a8080e7          	jalr	1448(ra) # 80002a4a <sigaction>
    800034aa:	87aa                	mv	a5,a0
}
    800034ac:	853e                	mv	a0,a5
    800034ae:	70a2                	ld	ra,40(sp)
    800034b0:	7402                	ld	s0,32(sp)
    800034b2:	6145                	addi	sp,sp,48
    800034b4:	8082                	ret

00000000800034b6 <sys_sigret>:

// ADDED Q2.1.5
uint64
sys_sigret(void)
{
    800034b6:	1141                	addi	sp,sp,-16
    800034b8:	e406                	sd	ra,8(sp)
    800034ba:	e022                	sd	s0,0(sp)
    800034bc:	0800                	addi	s0,sp,16
  sigret();
    800034be:	fffff097          	auipc	ra,0xfffff
    800034c2:	6ee080e7          	jalr	1774(ra) # 80002bac <sigret>
  return 0;
}
    800034c6:	4501                	li	a0,0
    800034c8:	60a2                	ld	ra,8(sp)
    800034ca:	6402                	ld	s0,0(sp)
    800034cc:	0141                	addi	sp,sp,16
    800034ce:	8082                	ret

00000000800034d0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034d0:	7179                	addi	sp,sp,-48
    800034d2:	f406                	sd	ra,40(sp)
    800034d4:	f022                	sd	s0,32(sp)
    800034d6:	ec26                	sd	s1,24(sp)
    800034d8:	e84a                	sd	s2,16(sp)
    800034da:	e44e                	sd	s3,8(sp)
    800034dc:	e052                	sd	s4,0(sp)
    800034de:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034e0:	00005597          	auipc	a1,0x5
    800034e4:	16858593          	addi	a1,a1,360 # 80008648 <syscalls+0xc8>
    800034e8:	0001a517          	auipc	a0,0x1a
    800034ec:	20050513          	addi	a0,a0,512 # 8001d6e8 <bcache>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	642080e7          	jalr	1602(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034f8:	00022797          	auipc	a5,0x22
    800034fc:	1f078793          	addi	a5,a5,496 # 800256e8 <bcache+0x8000>
    80003500:	00022717          	auipc	a4,0x22
    80003504:	45070713          	addi	a4,a4,1104 # 80025950 <bcache+0x8268>
    80003508:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000350c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003510:	0001a497          	auipc	s1,0x1a
    80003514:	1f048493          	addi	s1,s1,496 # 8001d700 <bcache+0x18>
    b->next = bcache.head.next;
    80003518:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000351a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000351c:	00005a17          	auipc	s4,0x5
    80003520:	134a0a13          	addi	s4,s4,308 # 80008650 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003524:	2b893783          	ld	a5,696(s2)
    80003528:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000352a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000352e:	85d2                	mv	a1,s4
    80003530:	01048513          	addi	a0,s1,16
    80003534:	00001097          	auipc	ra,0x1
    80003538:	4c2080e7          	jalr	1218(ra) # 800049f6 <initsleeplock>
    bcache.head.next->prev = b;
    8000353c:	2b893783          	ld	a5,696(s2)
    80003540:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003542:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003546:	45848493          	addi	s1,s1,1112
    8000354a:	fd349de3          	bne	s1,s3,80003524 <binit+0x54>
  }
}
    8000354e:	70a2                	ld	ra,40(sp)
    80003550:	7402                	ld	s0,32(sp)
    80003552:	64e2                	ld	s1,24(sp)
    80003554:	6942                	ld	s2,16(sp)
    80003556:	69a2                	ld	s3,8(sp)
    80003558:	6a02                	ld	s4,0(sp)
    8000355a:	6145                	addi	sp,sp,48
    8000355c:	8082                	ret

000000008000355e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000355e:	7179                	addi	sp,sp,-48
    80003560:	f406                	sd	ra,40(sp)
    80003562:	f022                	sd	s0,32(sp)
    80003564:	ec26                	sd	s1,24(sp)
    80003566:	e84a                	sd	s2,16(sp)
    80003568:	e44e                	sd	s3,8(sp)
    8000356a:	1800                	addi	s0,sp,48
    8000356c:	892a                	mv	s2,a0
    8000356e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003570:	0001a517          	auipc	a0,0x1a
    80003574:	17850513          	addi	a0,a0,376 # 8001d6e8 <bcache>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	64a080e7          	jalr	1610(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003580:	00022497          	auipc	s1,0x22
    80003584:	4204b483          	ld	s1,1056(s1) # 800259a0 <bcache+0x82b8>
    80003588:	00022797          	auipc	a5,0x22
    8000358c:	3c878793          	addi	a5,a5,968 # 80025950 <bcache+0x8268>
    80003590:	02f48f63          	beq	s1,a5,800035ce <bread+0x70>
    80003594:	873e                	mv	a4,a5
    80003596:	a021                	j	8000359e <bread+0x40>
    80003598:	68a4                	ld	s1,80(s1)
    8000359a:	02e48a63          	beq	s1,a4,800035ce <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000359e:	449c                	lw	a5,8(s1)
    800035a0:	ff279ce3          	bne	a5,s2,80003598 <bread+0x3a>
    800035a4:	44dc                	lw	a5,12(s1)
    800035a6:	ff3799e3          	bne	a5,s3,80003598 <bread+0x3a>
      b->refcnt++;
    800035aa:	40bc                	lw	a5,64(s1)
    800035ac:	2785                	addiw	a5,a5,1
    800035ae:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035b0:	0001a517          	auipc	a0,0x1a
    800035b4:	13850513          	addi	a0,a0,312 # 8001d6e8 <bcache>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	6d0080e7          	jalr	1744(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    800035c0:	01048513          	addi	a0,s1,16
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	46c080e7          	jalr	1132(ra) # 80004a30 <acquiresleep>
      return b;
    800035cc:	a8b9                	j	8000362a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035ce:	00022497          	auipc	s1,0x22
    800035d2:	3ca4b483          	ld	s1,970(s1) # 80025998 <bcache+0x82b0>
    800035d6:	00022797          	auipc	a5,0x22
    800035da:	37a78793          	addi	a5,a5,890 # 80025950 <bcache+0x8268>
    800035de:	00f48863          	beq	s1,a5,800035ee <bread+0x90>
    800035e2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035e4:	40bc                	lw	a5,64(s1)
    800035e6:	cf81                	beqz	a5,800035fe <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035e8:	64a4                	ld	s1,72(s1)
    800035ea:	fee49de3          	bne	s1,a4,800035e4 <bread+0x86>
  panic("bget: no buffers");
    800035ee:	00005517          	auipc	a0,0x5
    800035f2:	06a50513          	addi	a0,a0,106 # 80008658 <syscalls+0xd8>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	f34080e7          	jalr	-204(ra) # 8000052a <panic>
      b->dev = dev;
    800035fe:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003602:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003606:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000360a:	4785                	li	a5,1
    8000360c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000360e:	0001a517          	auipc	a0,0x1a
    80003612:	0da50513          	addi	a0,a0,218 # 8001d6e8 <bcache>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	672080e7          	jalr	1650(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    8000361e:	01048513          	addi	a0,s1,16
    80003622:	00001097          	auipc	ra,0x1
    80003626:	40e080e7          	jalr	1038(ra) # 80004a30 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000362a:	409c                	lw	a5,0(s1)
    8000362c:	cb89                	beqz	a5,8000363e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000362e:	8526                	mv	a0,s1
    80003630:	70a2                	ld	ra,40(sp)
    80003632:	7402                	ld	s0,32(sp)
    80003634:	64e2                	ld	s1,24(sp)
    80003636:	6942                	ld	s2,16(sp)
    80003638:	69a2                	ld	s3,8(sp)
    8000363a:	6145                	addi	sp,sp,48
    8000363c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000363e:	4581                	li	a1,0
    80003640:	8526                	mv	a0,s1
    80003642:	00003097          	auipc	ra,0x3
    80003646:	f54080e7          	jalr	-172(ra) # 80006596 <virtio_disk_rw>
    b->valid = 1;
    8000364a:	4785                	li	a5,1
    8000364c:	c09c                	sw	a5,0(s1)
  return b;
    8000364e:	b7c5                	j	8000362e <bread+0xd0>

0000000080003650 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003650:	1101                	addi	sp,sp,-32
    80003652:	ec06                	sd	ra,24(sp)
    80003654:	e822                	sd	s0,16(sp)
    80003656:	e426                	sd	s1,8(sp)
    80003658:	1000                	addi	s0,sp,32
    8000365a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000365c:	0541                	addi	a0,a0,16
    8000365e:	00001097          	auipc	ra,0x1
    80003662:	46c080e7          	jalr	1132(ra) # 80004aca <holdingsleep>
    80003666:	cd01                	beqz	a0,8000367e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003668:	4585                	li	a1,1
    8000366a:	8526                	mv	a0,s1
    8000366c:	00003097          	auipc	ra,0x3
    80003670:	f2a080e7          	jalr	-214(ra) # 80006596 <virtio_disk_rw>
}
    80003674:	60e2                	ld	ra,24(sp)
    80003676:	6442                	ld	s0,16(sp)
    80003678:	64a2                	ld	s1,8(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret
    panic("bwrite");
    8000367e:	00005517          	auipc	a0,0x5
    80003682:	ff250513          	addi	a0,a0,-14 # 80008670 <syscalls+0xf0>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	ea4080e7          	jalr	-348(ra) # 8000052a <panic>

000000008000368e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000368e:	1101                	addi	sp,sp,-32
    80003690:	ec06                	sd	ra,24(sp)
    80003692:	e822                	sd	s0,16(sp)
    80003694:	e426                	sd	s1,8(sp)
    80003696:	e04a                	sd	s2,0(sp)
    80003698:	1000                	addi	s0,sp,32
    8000369a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000369c:	01050913          	addi	s2,a0,16
    800036a0:	854a                	mv	a0,s2
    800036a2:	00001097          	auipc	ra,0x1
    800036a6:	428080e7          	jalr	1064(ra) # 80004aca <holdingsleep>
    800036aa:	c92d                	beqz	a0,8000371c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800036ac:	854a                	mv	a0,s2
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	3d8080e7          	jalr	984(ra) # 80004a86 <releasesleep>

  acquire(&bcache.lock);
    800036b6:	0001a517          	auipc	a0,0x1a
    800036ba:	03250513          	addi	a0,a0,50 # 8001d6e8 <bcache>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	504080e7          	jalr	1284(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800036c6:	40bc                	lw	a5,64(s1)
    800036c8:	37fd                	addiw	a5,a5,-1
    800036ca:	0007871b          	sext.w	a4,a5
    800036ce:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036d0:	eb05                	bnez	a4,80003700 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036d2:	68bc                	ld	a5,80(s1)
    800036d4:	64b8                	ld	a4,72(s1)
    800036d6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036d8:	64bc                	ld	a5,72(s1)
    800036da:	68b8                	ld	a4,80(s1)
    800036dc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036de:	00022797          	auipc	a5,0x22
    800036e2:	00a78793          	addi	a5,a5,10 # 800256e8 <bcache+0x8000>
    800036e6:	2b87b703          	ld	a4,696(a5)
    800036ea:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036ec:	00022717          	auipc	a4,0x22
    800036f0:	26470713          	addi	a4,a4,612 # 80025950 <bcache+0x8268>
    800036f4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036f6:	2b87b703          	ld	a4,696(a5)
    800036fa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036fc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003700:	0001a517          	auipc	a0,0x1a
    80003704:	fe850513          	addi	a0,a0,-24 # 8001d6e8 <bcache>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	580080e7          	jalr	1408(ra) # 80000c88 <release>
}
    80003710:	60e2                	ld	ra,24(sp)
    80003712:	6442                	ld	s0,16(sp)
    80003714:	64a2                	ld	s1,8(sp)
    80003716:	6902                	ld	s2,0(sp)
    80003718:	6105                	addi	sp,sp,32
    8000371a:	8082                	ret
    panic("brelse");
    8000371c:	00005517          	auipc	a0,0x5
    80003720:	f5c50513          	addi	a0,a0,-164 # 80008678 <syscalls+0xf8>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	e06080e7          	jalr	-506(ra) # 8000052a <panic>

000000008000372c <bpin>:

void
bpin(struct buf *b) {
    8000372c:	1101                	addi	sp,sp,-32
    8000372e:	ec06                	sd	ra,24(sp)
    80003730:	e822                	sd	s0,16(sp)
    80003732:	e426                	sd	s1,8(sp)
    80003734:	1000                	addi	s0,sp,32
    80003736:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003738:	0001a517          	auipc	a0,0x1a
    8000373c:	fb050513          	addi	a0,a0,-80 # 8001d6e8 <bcache>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	482080e7          	jalr	1154(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003748:	40bc                	lw	a5,64(s1)
    8000374a:	2785                	addiw	a5,a5,1
    8000374c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000374e:	0001a517          	auipc	a0,0x1a
    80003752:	f9a50513          	addi	a0,a0,-102 # 8001d6e8 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	532080e7          	jalr	1330(ra) # 80000c88 <release>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret

0000000080003768 <bunpin>:

void
bunpin(struct buf *b) {
    80003768:	1101                	addi	sp,sp,-32
    8000376a:	ec06                	sd	ra,24(sp)
    8000376c:	e822                	sd	s0,16(sp)
    8000376e:	e426                	sd	s1,8(sp)
    80003770:	1000                	addi	s0,sp,32
    80003772:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003774:	0001a517          	auipc	a0,0x1a
    80003778:	f7450513          	addi	a0,a0,-140 # 8001d6e8 <bcache>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	446080e7          	jalr	1094(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003784:	40bc                	lw	a5,64(s1)
    80003786:	37fd                	addiw	a5,a5,-1
    80003788:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000378a:	0001a517          	auipc	a0,0x1a
    8000378e:	f5e50513          	addi	a0,a0,-162 # 8001d6e8 <bcache>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	4f6080e7          	jalr	1270(ra) # 80000c88 <release>
}
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	64a2                	ld	s1,8(sp)
    800037a0:	6105                	addi	sp,sp,32
    800037a2:	8082                	ret

00000000800037a4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037a4:	1101                	addi	sp,sp,-32
    800037a6:	ec06                	sd	ra,24(sp)
    800037a8:	e822                	sd	s0,16(sp)
    800037aa:	e426                	sd	s1,8(sp)
    800037ac:	e04a                	sd	s2,0(sp)
    800037ae:	1000                	addi	s0,sp,32
    800037b0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037b2:	00d5d59b          	srliw	a1,a1,0xd
    800037b6:	00022797          	auipc	a5,0x22
    800037ba:	60e7a783          	lw	a5,1550(a5) # 80025dc4 <sb+0x1c>
    800037be:	9dbd                	addw	a1,a1,a5
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	d9e080e7          	jalr	-610(ra) # 8000355e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037c8:	0074f713          	andi	a4,s1,7
    800037cc:	4785                	li	a5,1
    800037ce:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037d2:	14ce                	slli	s1,s1,0x33
    800037d4:	90d9                	srli	s1,s1,0x36
    800037d6:	00950733          	add	a4,a0,s1
    800037da:	05874703          	lbu	a4,88(a4)
    800037de:	00e7f6b3          	and	a3,a5,a4
    800037e2:	c69d                	beqz	a3,80003810 <bfree+0x6c>
    800037e4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037e6:	94aa                	add	s1,s1,a0
    800037e8:	fff7c793          	not	a5,a5
    800037ec:	8ff9                	and	a5,a5,a4
    800037ee:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037f2:	00001097          	auipc	ra,0x1
    800037f6:	11e080e7          	jalr	286(ra) # 80004910 <log_write>
  brelse(bp);
    800037fa:	854a                	mv	a0,s2
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	e92080e7          	jalr	-366(ra) # 8000368e <brelse>
}
    80003804:	60e2                	ld	ra,24(sp)
    80003806:	6442                	ld	s0,16(sp)
    80003808:	64a2                	ld	s1,8(sp)
    8000380a:	6902                	ld	s2,0(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret
    panic("freeing free block");
    80003810:	00005517          	auipc	a0,0x5
    80003814:	e7050513          	addi	a0,a0,-400 # 80008680 <syscalls+0x100>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	d12080e7          	jalr	-750(ra) # 8000052a <panic>

0000000080003820 <balloc>:
{
    80003820:	711d                	addi	sp,sp,-96
    80003822:	ec86                	sd	ra,88(sp)
    80003824:	e8a2                	sd	s0,80(sp)
    80003826:	e4a6                	sd	s1,72(sp)
    80003828:	e0ca                	sd	s2,64(sp)
    8000382a:	fc4e                	sd	s3,56(sp)
    8000382c:	f852                	sd	s4,48(sp)
    8000382e:	f456                	sd	s5,40(sp)
    80003830:	f05a                	sd	s6,32(sp)
    80003832:	ec5e                	sd	s7,24(sp)
    80003834:	e862                	sd	s8,16(sp)
    80003836:	e466                	sd	s9,8(sp)
    80003838:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000383a:	00022797          	auipc	a5,0x22
    8000383e:	5727a783          	lw	a5,1394(a5) # 80025dac <sb+0x4>
    80003842:	cbd1                	beqz	a5,800038d6 <balloc+0xb6>
    80003844:	8baa                	mv	s7,a0
    80003846:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003848:	00022b17          	auipc	s6,0x22
    8000384c:	560b0b13          	addi	s6,s6,1376 # 80025da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003850:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003852:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003854:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003856:	6c89                	lui	s9,0x2
    80003858:	a831                	j	80003874 <balloc+0x54>
    brelse(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	e32080e7          	jalr	-462(ra) # 8000368e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003864:	015c87bb          	addw	a5,s9,s5
    80003868:	00078a9b          	sext.w	s5,a5
    8000386c:	004b2703          	lw	a4,4(s6)
    80003870:	06eaf363          	bgeu	s5,a4,800038d6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003874:	41fad79b          	sraiw	a5,s5,0x1f
    80003878:	0137d79b          	srliw	a5,a5,0x13
    8000387c:	015787bb          	addw	a5,a5,s5
    80003880:	40d7d79b          	sraiw	a5,a5,0xd
    80003884:	01cb2583          	lw	a1,28(s6)
    80003888:	9dbd                	addw	a1,a1,a5
    8000388a:	855e                	mv	a0,s7
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	cd2080e7          	jalr	-814(ra) # 8000355e <bread>
    80003894:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003896:	004b2503          	lw	a0,4(s6)
    8000389a:	000a849b          	sext.w	s1,s5
    8000389e:	8662                	mv	a2,s8
    800038a0:	faa4fde3          	bgeu	s1,a0,8000385a <balloc+0x3a>
      m = 1 << (bi % 8);
    800038a4:	41f6579b          	sraiw	a5,a2,0x1f
    800038a8:	01d7d69b          	srliw	a3,a5,0x1d
    800038ac:	00c6873b          	addw	a4,a3,a2
    800038b0:	00777793          	andi	a5,a4,7
    800038b4:	9f95                	subw	a5,a5,a3
    800038b6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038ba:	4037571b          	sraiw	a4,a4,0x3
    800038be:	00e906b3          	add	a3,s2,a4
    800038c2:	0586c683          	lbu	a3,88(a3)
    800038c6:	00d7f5b3          	and	a1,a5,a3
    800038ca:	cd91                	beqz	a1,800038e6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038cc:	2605                	addiw	a2,a2,1
    800038ce:	2485                	addiw	s1,s1,1
    800038d0:	fd4618e3          	bne	a2,s4,800038a0 <balloc+0x80>
    800038d4:	b759                	j	8000385a <balloc+0x3a>
  panic("balloc: out of blocks");
    800038d6:	00005517          	auipc	a0,0x5
    800038da:	dc250513          	addi	a0,a0,-574 # 80008698 <syscalls+0x118>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	c4c080e7          	jalr	-948(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038e6:	974a                	add	a4,a4,s2
    800038e8:	8fd5                	or	a5,a5,a3
    800038ea:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00001097          	auipc	ra,0x1
    800038f4:	020080e7          	jalr	32(ra) # 80004910 <log_write>
        brelse(bp);
    800038f8:	854a                	mv	a0,s2
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	d94080e7          	jalr	-620(ra) # 8000368e <brelse>
  bp = bread(dev, bno);
    80003902:	85a6                	mv	a1,s1
    80003904:	855e                	mv	a0,s7
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	c58080e7          	jalr	-936(ra) # 8000355e <bread>
    8000390e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003910:	40000613          	li	a2,1024
    80003914:	4581                	li	a1,0
    80003916:	05850513          	addi	a0,a0,88
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	3c8080e7          	jalr	968(ra) # 80000ce2 <memset>
  log_write(bp);
    80003922:	854a                	mv	a0,s2
    80003924:	00001097          	auipc	ra,0x1
    80003928:	fec080e7          	jalr	-20(ra) # 80004910 <log_write>
  brelse(bp);
    8000392c:	854a                	mv	a0,s2
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	d60080e7          	jalr	-672(ra) # 8000368e <brelse>
}
    80003936:	8526                	mv	a0,s1
    80003938:	60e6                	ld	ra,88(sp)
    8000393a:	6446                	ld	s0,80(sp)
    8000393c:	64a6                	ld	s1,72(sp)
    8000393e:	6906                	ld	s2,64(sp)
    80003940:	79e2                	ld	s3,56(sp)
    80003942:	7a42                	ld	s4,48(sp)
    80003944:	7aa2                	ld	s5,40(sp)
    80003946:	7b02                	ld	s6,32(sp)
    80003948:	6be2                	ld	s7,24(sp)
    8000394a:	6c42                	ld	s8,16(sp)
    8000394c:	6ca2                	ld	s9,8(sp)
    8000394e:	6125                	addi	sp,sp,96
    80003950:	8082                	ret

0000000080003952 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003952:	7179                	addi	sp,sp,-48
    80003954:	f406                	sd	ra,40(sp)
    80003956:	f022                	sd	s0,32(sp)
    80003958:	ec26                	sd	s1,24(sp)
    8000395a:	e84a                	sd	s2,16(sp)
    8000395c:	e44e                	sd	s3,8(sp)
    8000395e:	e052                	sd	s4,0(sp)
    80003960:	1800                	addi	s0,sp,48
    80003962:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003964:	47ad                	li	a5,11
    80003966:	04b7fe63          	bgeu	a5,a1,800039c2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000396a:	ff45849b          	addiw	s1,a1,-12
    8000396e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003972:	0ff00793          	li	a5,255
    80003976:	0ae7e463          	bltu	a5,a4,80003a1e <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000397a:	08052583          	lw	a1,128(a0)
    8000397e:	c5b5                	beqz	a1,800039ea <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003980:	00092503          	lw	a0,0(s2)
    80003984:	00000097          	auipc	ra,0x0
    80003988:	bda080e7          	jalr	-1062(ra) # 8000355e <bread>
    8000398c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000398e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003992:	02049713          	slli	a4,s1,0x20
    80003996:	01e75593          	srli	a1,a4,0x1e
    8000399a:	00b784b3          	add	s1,a5,a1
    8000399e:	0004a983          	lw	s3,0(s1)
    800039a2:	04098e63          	beqz	s3,800039fe <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800039a6:	8552                	mv	a0,s4
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	ce6080e7          	jalr	-794(ra) # 8000368e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800039b0:	854e                	mv	a0,s3
    800039b2:	70a2                	ld	ra,40(sp)
    800039b4:	7402                	ld	s0,32(sp)
    800039b6:	64e2                	ld	s1,24(sp)
    800039b8:	6942                	ld	s2,16(sp)
    800039ba:	69a2                	ld	s3,8(sp)
    800039bc:	6a02                	ld	s4,0(sp)
    800039be:	6145                	addi	sp,sp,48
    800039c0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800039c2:	02059793          	slli	a5,a1,0x20
    800039c6:	01e7d593          	srli	a1,a5,0x1e
    800039ca:	00b504b3          	add	s1,a0,a1
    800039ce:	0504a983          	lw	s3,80(s1)
    800039d2:	fc099fe3          	bnez	s3,800039b0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800039d6:	4108                	lw	a0,0(a0)
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	e48080e7          	jalr	-440(ra) # 80003820 <balloc>
    800039e0:	0005099b          	sext.w	s3,a0
    800039e4:	0534a823          	sw	s3,80(s1)
    800039e8:	b7e1                	j	800039b0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800039ea:	4108                	lw	a0,0(a0)
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	e34080e7          	jalr	-460(ra) # 80003820 <balloc>
    800039f4:	0005059b          	sext.w	a1,a0
    800039f8:	08b92023          	sw	a1,128(s2)
    800039fc:	b751                	j	80003980 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039fe:	00092503          	lw	a0,0(s2)
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	e1e080e7          	jalr	-482(ra) # 80003820 <balloc>
    80003a0a:	0005099b          	sext.w	s3,a0
    80003a0e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a12:	8552                	mv	a0,s4
    80003a14:	00001097          	auipc	ra,0x1
    80003a18:	efc080e7          	jalr	-260(ra) # 80004910 <log_write>
    80003a1c:	b769                	j	800039a6 <bmap+0x54>
  panic("bmap: out of range");
    80003a1e:	00005517          	auipc	a0,0x5
    80003a22:	c9250513          	addi	a0,a0,-878 # 800086b0 <syscalls+0x130>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	b04080e7          	jalr	-1276(ra) # 8000052a <panic>

0000000080003a2e <iget>:
{
    80003a2e:	7179                	addi	sp,sp,-48
    80003a30:	f406                	sd	ra,40(sp)
    80003a32:	f022                	sd	s0,32(sp)
    80003a34:	ec26                	sd	s1,24(sp)
    80003a36:	e84a                	sd	s2,16(sp)
    80003a38:	e44e                	sd	s3,8(sp)
    80003a3a:	e052                	sd	s4,0(sp)
    80003a3c:	1800                	addi	s0,sp,48
    80003a3e:	89aa                	mv	s3,a0
    80003a40:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a42:	00022517          	auipc	a0,0x22
    80003a46:	38650513          	addi	a0,a0,902 # 80025dc8 <itable>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	178080e7          	jalr	376(ra) # 80000bc2 <acquire>
  empty = 0;
    80003a52:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a54:	00022497          	auipc	s1,0x22
    80003a58:	38c48493          	addi	s1,s1,908 # 80025de0 <itable+0x18>
    80003a5c:	00024697          	auipc	a3,0x24
    80003a60:	e1468693          	addi	a3,a3,-492 # 80027870 <log>
    80003a64:	a039                	j	80003a72 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a66:	02090b63          	beqz	s2,80003a9c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a6a:	08848493          	addi	s1,s1,136
    80003a6e:	02d48a63          	beq	s1,a3,80003aa2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a72:	449c                	lw	a5,8(s1)
    80003a74:	fef059e3          	blez	a5,80003a66 <iget+0x38>
    80003a78:	4098                	lw	a4,0(s1)
    80003a7a:	ff3716e3          	bne	a4,s3,80003a66 <iget+0x38>
    80003a7e:	40d8                	lw	a4,4(s1)
    80003a80:	ff4713e3          	bne	a4,s4,80003a66 <iget+0x38>
      ip->ref++;
    80003a84:	2785                	addiw	a5,a5,1
    80003a86:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a88:	00022517          	auipc	a0,0x22
    80003a8c:	34050513          	addi	a0,a0,832 # 80025dc8 <itable>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	1f8080e7          	jalr	504(ra) # 80000c88 <release>
      return ip;
    80003a98:	8926                	mv	s2,s1
    80003a9a:	a03d                	j	80003ac8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a9c:	f7f9                	bnez	a5,80003a6a <iget+0x3c>
    80003a9e:	8926                	mv	s2,s1
    80003aa0:	b7e9                	j	80003a6a <iget+0x3c>
  if(empty == 0)
    80003aa2:	02090c63          	beqz	s2,80003ada <iget+0xac>
  ip->dev = dev;
    80003aa6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003aaa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003aae:	4785                	li	a5,1
    80003ab0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ab4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ab8:	00022517          	auipc	a0,0x22
    80003abc:	31050513          	addi	a0,a0,784 # 80025dc8 <itable>
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	1c8080e7          	jalr	456(ra) # 80000c88 <release>
}
    80003ac8:	854a                	mv	a0,s2
    80003aca:	70a2                	ld	ra,40(sp)
    80003acc:	7402                	ld	s0,32(sp)
    80003ace:	64e2                	ld	s1,24(sp)
    80003ad0:	6942                	ld	s2,16(sp)
    80003ad2:	69a2                	ld	s3,8(sp)
    80003ad4:	6a02                	ld	s4,0(sp)
    80003ad6:	6145                	addi	sp,sp,48
    80003ad8:	8082                	ret
    panic("iget: no inodes");
    80003ada:	00005517          	auipc	a0,0x5
    80003ade:	bee50513          	addi	a0,a0,-1042 # 800086c8 <syscalls+0x148>
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	a48080e7          	jalr	-1464(ra) # 8000052a <panic>

0000000080003aea <fsinit>:
fsinit(int dev) {
    80003aea:	7179                	addi	sp,sp,-48
    80003aec:	f406                	sd	ra,40(sp)
    80003aee:	f022                	sd	s0,32(sp)
    80003af0:	ec26                	sd	s1,24(sp)
    80003af2:	e84a                	sd	s2,16(sp)
    80003af4:	e44e                	sd	s3,8(sp)
    80003af6:	1800                	addi	s0,sp,48
    80003af8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003afa:	4585                	li	a1,1
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	a62080e7          	jalr	-1438(ra) # 8000355e <bread>
    80003b04:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b06:	00022997          	auipc	s3,0x22
    80003b0a:	2a298993          	addi	s3,s3,674 # 80025da8 <sb>
    80003b0e:	02000613          	li	a2,32
    80003b12:	05850593          	addi	a1,a0,88
    80003b16:	854e                	mv	a0,s3
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	226080e7          	jalr	550(ra) # 80000d3e <memmove>
  brelse(bp);
    80003b20:	8526                	mv	a0,s1
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	b6c080e7          	jalr	-1172(ra) # 8000368e <brelse>
  if(sb.magic != FSMAGIC)
    80003b2a:	0009a703          	lw	a4,0(s3)
    80003b2e:	102037b7          	lui	a5,0x10203
    80003b32:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b36:	02f71263          	bne	a4,a5,80003b5a <fsinit+0x70>
  initlog(dev, &sb);
    80003b3a:	00022597          	auipc	a1,0x22
    80003b3e:	26e58593          	addi	a1,a1,622 # 80025da8 <sb>
    80003b42:	854a                	mv	a0,s2
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	b4e080e7          	jalr	-1202(ra) # 80004692 <initlog>
}
    80003b4c:	70a2                	ld	ra,40(sp)
    80003b4e:	7402                	ld	s0,32(sp)
    80003b50:	64e2                	ld	s1,24(sp)
    80003b52:	6942                	ld	s2,16(sp)
    80003b54:	69a2                	ld	s3,8(sp)
    80003b56:	6145                	addi	sp,sp,48
    80003b58:	8082                	ret
    panic("invalid file system");
    80003b5a:	00005517          	auipc	a0,0x5
    80003b5e:	b7e50513          	addi	a0,a0,-1154 # 800086d8 <syscalls+0x158>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	9c8080e7          	jalr	-1592(ra) # 8000052a <panic>

0000000080003b6a <iinit>:
{
    80003b6a:	7179                	addi	sp,sp,-48
    80003b6c:	f406                	sd	ra,40(sp)
    80003b6e:	f022                	sd	s0,32(sp)
    80003b70:	ec26                	sd	s1,24(sp)
    80003b72:	e84a                	sd	s2,16(sp)
    80003b74:	e44e                	sd	s3,8(sp)
    80003b76:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b78:	00005597          	auipc	a1,0x5
    80003b7c:	b7858593          	addi	a1,a1,-1160 # 800086f0 <syscalls+0x170>
    80003b80:	00022517          	auipc	a0,0x22
    80003b84:	24850513          	addi	a0,a0,584 # 80025dc8 <itable>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	faa080e7          	jalr	-86(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b90:	00022497          	auipc	s1,0x22
    80003b94:	26048493          	addi	s1,s1,608 # 80025df0 <itable+0x28>
    80003b98:	00024997          	auipc	s3,0x24
    80003b9c:	ce898993          	addi	s3,s3,-792 # 80027880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ba0:	00005917          	auipc	s2,0x5
    80003ba4:	b5890913          	addi	s2,s2,-1192 # 800086f8 <syscalls+0x178>
    80003ba8:	85ca                	mv	a1,s2
    80003baa:	8526                	mv	a0,s1
    80003bac:	00001097          	auipc	ra,0x1
    80003bb0:	e4a080e7          	jalr	-438(ra) # 800049f6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003bb4:	08848493          	addi	s1,s1,136
    80003bb8:	ff3498e3          	bne	s1,s3,80003ba8 <iinit+0x3e>
}
    80003bbc:	70a2                	ld	ra,40(sp)
    80003bbe:	7402                	ld	s0,32(sp)
    80003bc0:	64e2                	ld	s1,24(sp)
    80003bc2:	6942                	ld	s2,16(sp)
    80003bc4:	69a2                	ld	s3,8(sp)
    80003bc6:	6145                	addi	sp,sp,48
    80003bc8:	8082                	ret

0000000080003bca <ialloc>:
{
    80003bca:	715d                	addi	sp,sp,-80
    80003bcc:	e486                	sd	ra,72(sp)
    80003bce:	e0a2                	sd	s0,64(sp)
    80003bd0:	fc26                	sd	s1,56(sp)
    80003bd2:	f84a                	sd	s2,48(sp)
    80003bd4:	f44e                	sd	s3,40(sp)
    80003bd6:	f052                	sd	s4,32(sp)
    80003bd8:	ec56                	sd	s5,24(sp)
    80003bda:	e85a                	sd	s6,16(sp)
    80003bdc:	e45e                	sd	s7,8(sp)
    80003bde:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003be0:	00022717          	auipc	a4,0x22
    80003be4:	1d472703          	lw	a4,468(a4) # 80025db4 <sb+0xc>
    80003be8:	4785                	li	a5,1
    80003bea:	04e7fa63          	bgeu	a5,a4,80003c3e <ialloc+0x74>
    80003bee:	8aaa                	mv	s5,a0
    80003bf0:	8bae                	mv	s7,a1
    80003bf2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bf4:	00022a17          	auipc	s4,0x22
    80003bf8:	1b4a0a13          	addi	s4,s4,436 # 80025da8 <sb>
    80003bfc:	00048b1b          	sext.w	s6,s1
    80003c00:	0044d793          	srli	a5,s1,0x4
    80003c04:	018a2583          	lw	a1,24(s4)
    80003c08:	9dbd                	addw	a1,a1,a5
    80003c0a:	8556                	mv	a0,s5
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	952080e7          	jalr	-1710(ra) # 8000355e <bread>
    80003c14:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c16:	05850993          	addi	s3,a0,88
    80003c1a:	00f4f793          	andi	a5,s1,15
    80003c1e:	079a                	slli	a5,a5,0x6
    80003c20:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c22:	00099783          	lh	a5,0(s3)
    80003c26:	c785                	beqz	a5,80003c4e <ialloc+0x84>
    brelse(bp);
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	a66080e7          	jalr	-1434(ra) # 8000368e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c30:	0485                	addi	s1,s1,1
    80003c32:	00ca2703          	lw	a4,12(s4)
    80003c36:	0004879b          	sext.w	a5,s1
    80003c3a:	fce7e1e3          	bltu	a5,a4,80003bfc <ialloc+0x32>
  panic("ialloc: no inodes");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	ac250513          	addi	a0,a0,-1342 # 80008700 <syscalls+0x180>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8e4080e7          	jalr	-1820(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003c4e:	04000613          	li	a2,64
    80003c52:	4581                	li	a1,0
    80003c54:	854e                	mv	a0,s3
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	08c080e7          	jalr	140(ra) # 80000ce2 <memset>
      dip->type = type;
    80003c5e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c62:	854a                	mv	a0,s2
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	cac080e7          	jalr	-852(ra) # 80004910 <log_write>
      brelse(bp);
    80003c6c:	854a                	mv	a0,s2
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	a20080e7          	jalr	-1504(ra) # 8000368e <brelse>
      return iget(dev, inum);
    80003c76:	85da                	mv	a1,s6
    80003c78:	8556                	mv	a0,s5
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	db4080e7          	jalr	-588(ra) # 80003a2e <iget>
}
    80003c82:	60a6                	ld	ra,72(sp)
    80003c84:	6406                	ld	s0,64(sp)
    80003c86:	74e2                	ld	s1,56(sp)
    80003c88:	7942                	ld	s2,48(sp)
    80003c8a:	79a2                	ld	s3,40(sp)
    80003c8c:	7a02                	ld	s4,32(sp)
    80003c8e:	6ae2                	ld	s5,24(sp)
    80003c90:	6b42                	ld	s6,16(sp)
    80003c92:	6ba2                	ld	s7,8(sp)
    80003c94:	6161                	addi	sp,sp,80
    80003c96:	8082                	ret

0000000080003c98 <iupdate>:
{
    80003c98:	1101                	addi	sp,sp,-32
    80003c9a:	ec06                	sd	ra,24(sp)
    80003c9c:	e822                	sd	s0,16(sp)
    80003c9e:	e426                	sd	s1,8(sp)
    80003ca0:	e04a                	sd	s2,0(sp)
    80003ca2:	1000                	addi	s0,sp,32
    80003ca4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ca6:	415c                	lw	a5,4(a0)
    80003ca8:	0047d79b          	srliw	a5,a5,0x4
    80003cac:	00022597          	auipc	a1,0x22
    80003cb0:	1145a583          	lw	a1,276(a1) # 80025dc0 <sb+0x18>
    80003cb4:	9dbd                	addw	a1,a1,a5
    80003cb6:	4108                	lw	a0,0(a0)
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	8a6080e7          	jalr	-1882(ra) # 8000355e <bread>
    80003cc0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cc2:	05850793          	addi	a5,a0,88
    80003cc6:	40c8                	lw	a0,4(s1)
    80003cc8:	893d                	andi	a0,a0,15
    80003cca:	051a                	slli	a0,a0,0x6
    80003ccc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003cce:	04449703          	lh	a4,68(s1)
    80003cd2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003cd6:	04649703          	lh	a4,70(s1)
    80003cda:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003cde:	04849703          	lh	a4,72(s1)
    80003ce2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003ce6:	04a49703          	lh	a4,74(s1)
    80003cea:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cee:	44f8                	lw	a4,76(s1)
    80003cf0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cf2:	03400613          	li	a2,52
    80003cf6:	05048593          	addi	a1,s1,80
    80003cfa:	0531                	addi	a0,a0,12
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	042080e7          	jalr	66(ra) # 80000d3e <memmove>
  log_write(bp);
    80003d04:	854a                	mv	a0,s2
    80003d06:	00001097          	auipc	ra,0x1
    80003d0a:	c0a080e7          	jalr	-1014(ra) # 80004910 <log_write>
  brelse(bp);
    80003d0e:	854a                	mv	a0,s2
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	97e080e7          	jalr	-1666(ra) # 8000368e <brelse>
}
    80003d18:	60e2                	ld	ra,24(sp)
    80003d1a:	6442                	ld	s0,16(sp)
    80003d1c:	64a2                	ld	s1,8(sp)
    80003d1e:	6902                	ld	s2,0(sp)
    80003d20:	6105                	addi	sp,sp,32
    80003d22:	8082                	ret

0000000080003d24 <idup>:
{
    80003d24:	1101                	addi	sp,sp,-32
    80003d26:	ec06                	sd	ra,24(sp)
    80003d28:	e822                	sd	s0,16(sp)
    80003d2a:	e426                	sd	s1,8(sp)
    80003d2c:	1000                	addi	s0,sp,32
    80003d2e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d30:	00022517          	auipc	a0,0x22
    80003d34:	09850513          	addi	a0,a0,152 # 80025dc8 <itable>
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	e8a080e7          	jalr	-374(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003d40:	449c                	lw	a5,8(s1)
    80003d42:	2785                	addiw	a5,a5,1
    80003d44:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d46:	00022517          	auipc	a0,0x22
    80003d4a:	08250513          	addi	a0,a0,130 # 80025dc8 <itable>
    80003d4e:	ffffd097          	auipc	ra,0xffffd
    80003d52:	f3a080e7          	jalr	-198(ra) # 80000c88 <release>
}
    80003d56:	8526                	mv	a0,s1
    80003d58:	60e2                	ld	ra,24(sp)
    80003d5a:	6442                	ld	s0,16(sp)
    80003d5c:	64a2                	ld	s1,8(sp)
    80003d5e:	6105                	addi	sp,sp,32
    80003d60:	8082                	ret

0000000080003d62 <ilock>:
{
    80003d62:	1101                	addi	sp,sp,-32
    80003d64:	ec06                	sd	ra,24(sp)
    80003d66:	e822                	sd	s0,16(sp)
    80003d68:	e426                	sd	s1,8(sp)
    80003d6a:	e04a                	sd	s2,0(sp)
    80003d6c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d6e:	c115                	beqz	a0,80003d92 <ilock+0x30>
    80003d70:	84aa                	mv	s1,a0
    80003d72:	451c                	lw	a5,8(a0)
    80003d74:	00f05f63          	blez	a5,80003d92 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d78:	0541                	addi	a0,a0,16
    80003d7a:	00001097          	auipc	ra,0x1
    80003d7e:	cb6080e7          	jalr	-842(ra) # 80004a30 <acquiresleep>
  if(ip->valid == 0){
    80003d82:	40bc                	lw	a5,64(s1)
    80003d84:	cf99                	beqz	a5,80003da2 <ilock+0x40>
}
    80003d86:	60e2                	ld	ra,24(sp)
    80003d88:	6442                	ld	s0,16(sp)
    80003d8a:	64a2                	ld	s1,8(sp)
    80003d8c:	6902                	ld	s2,0(sp)
    80003d8e:	6105                	addi	sp,sp,32
    80003d90:	8082                	ret
    panic("ilock");
    80003d92:	00005517          	auipc	a0,0x5
    80003d96:	98650513          	addi	a0,a0,-1658 # 80008718 <syscalls+0x198>
    80003d9a:	ffffc097          	auipc	ra,0xffffc
    80003d9e:	790080e7          	jalr	1936(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003da2:	40dc                	lw	a5,4(s1)
    80003da4:	0047d79b          	srliw	a5,a5,0x4
    80003da8:	00022597          	auipc	a1,0x22
    80003dac:	0185a583          	lw	a1,24(a1) # 80025dc0 <sb+0x18>
    80003db0:	9dbd                	addw	a1,a1,a5
    80003db2:	4088                	lw	a0,0(s1)
    80003db4:	fffff097          	auipc	ra,0xfffff
    80003db8:	7aa080e7          	jalr	1962(ra) # 8000355e <bread>
    80003dbc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dbe:	05850593          	addi	a1,a0,88
    80003dc2:	40dc                	lw	a5,4(s1)
    80003dc4:	8bbd                	andi	a5,a5,15
    80003dc6:	079a                	slli	a5,a5,0x6
    80003dc8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003dca:	00059783          	lh	a5,0(a1)
    80003dce:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003dd2:	00259783          	lh	a5,2(a1)
    80003dd6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003dda:	00459783          	lh	a5,4(a1)
    80003dde:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003de2:	00659783          	lh	a5,6(a1)
    80003de6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003dea:	459c                	lw	a5,8(a1)
    80003dec:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dee:	03400613          	li	a2,52
    80003df2:	05b1                	addi	a1,a1,12
    80003df4:	05048513          	addi	a0,s1,80
    80003df8:	ffffd097          	auipc	ra,0xffffd
    80003dfc:	f46080e7          	jalr	-186(ra) # 80000d3e <memmove>
    brelse(bp);
    80003e00:	854a                	mv	a0,s2
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	88c080e7          	jalr	-1908(ra) # 8000368e <brelse>
    ip->valid = 1;
    80003e0a:	4785                	li	a5,1
    80003e0c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e0e:	04449783          	lh	a5,68(s1)
    80003e12:	fbb5                	bnez	a5,80003d86 <ilock+0x24>
      panic("ilock: no type");
    80003e14:	00005517          	auipc	a0,0x5
    80003e18:	90c50513          	addi	a0,a0,-1780 # 80008720 <syscalls+0x1a0>
    80003e1c:	ffffc097          	auipc	ra,0xffffc
    80003e20:	70e080e7          	jalr	1806(ra) # 8000052a <panic>

0000000080003e24 <iunlock>:
{
    80003e24:	1101                	addi	sp,sp,-32
    80003e26:	ec06                	sd	ra,24(sp)
    80003e28:	e822                	sd	s0,16(sp)
    80003e2a:	e426                	sd	s1,8(sp)
    80003e2c:	e04a                	sd	s2,0(sp)
    80003e2e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e30:	c905                	beqz	a0,80003e60 <iunlock+0x3c>
    80003e32:	84aa                	mv	s1,a0
    80003e34:	01050913          	addi	s2,a0,16
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00001097          	auipc	ra,0x1
    80003e3e:	c90080e7          	jalr	-880(ra) # 80004aca <holdingsleep>
    80003e42:	cd19                	beqz	a0,80003e60 <iunlock+0x3c>
    80003e44:	449c                	lw	a5,8(s1)
    80003e46:	00f05d63          	blez	a5,80003e60 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e4a:	854a                	mv	a0,s2
    80003e4c:	00001097          	auipc	ra,0x1
    80003e50:	c3a080e7          	jalr	-966(ra) # 80004a86 <releasesleep>
}
    80003e54:	60e2                	ld	ra,24(sp)
    80003e56:	6442                	ld	s0,16(sp)
    80003e58:	64a2                	ld	s1,8(sp)
    80003e5a:	6902                	ld	s2,0(sp)
    80003e5c:	6105                	addi	sp,sp,32
    80003e5e:	8082                	ret
    panic("iunlock");
    80003e60:	00005517          	auipc	a0,0x5
    80003e64:	8d050513          	addi	a0,a0,-1840 # 80008730 <syscalls+0x1b0>
    80003e68:	ffffc097          	auipc	ra,0xffffc
    80003e6c:	6c2080e7          	jalr	1730(ra) # 8000052a <panic>

0000000080003e70 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e70:	7179                	addi	sp,sp,-48
    80003e72:	f406                	sd	ra,40(sp)
    80003e74:	f022                	sd	s0,32(sp)
    80003e76:	ec26                	sd	s1,24(sp)
    80003e78:	e84a                	sd	s2,16(sp)
    80003e7a:	e44e                	sd	s3,8(sp)
    80003e7c:	e052                	sd	s4,0(sp)
    80003e7e:	1800                	addi	s0,sp,48
    80003e80:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e82:	05050493          	addi	s1,a0,80
    80003e86:	08050913          	addi	s2,a0,128
    80003e8a:	a021                	j	80003e92 <itrunc+0x22>
    80003e8c:	0491                	addi	s1,s1,4
    80003e8e:	01248d63          	beq	s1,s2,80003ea8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e92:	408c                	lw	a1,0(s1)
    80003e94:	dde5                	beqz	a1,80003e8c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e96:	0009a503          	lw	a0,0(s3)
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	90a080e7          	jalr	-1782(ra) # 800037a4 <bfree>
      ip->addrs[i] = 0;
    80003ea2:	0004a023          	sw	zero,0(s1)
    80003ea6:	b7dd                	j	80003e8c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ea8:	0809a583          	lw	a1,128(s3)
    80003eac:	e185                	bnez	a1,80003ecc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003eae:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003eb2:	854e                	mv	a0,s3
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	de4080e7          	jalr	-540(ra) # 80003c98 <iupdate>
}
    80003ebc:	70a2                	ld	ra,40(sp)
    80003ebe:	7402                	ld	s0,32(sp)
    80003ec0:	64e2                	ld	s1,24(sp)
    80003ec2:	6942                	ld	s2,16(sp)
    80003ec4:	69a2                	ld	s3,8(sp)
    80003ec6:	6a02                	ld	s4,0(sp)
    80003ec8:	6145                	addi	sp,sp,48
    80003eca:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ecc:	0009a503          	lw	a0,0(s3)
    80003ed0:	fffff097          	auipc	ra,0xfffff
    80003ed4:	68e080e7          	jalr	1678(ra) # 8000355e <bread>
    80003ed8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003eda:	05850493          	addi	s1,a0,88
    80003ede:	45850913          	addi	s2,a0,1112
    80003ee2:	a021                	j	80003eea <itrunc+0x7a>
    80003ee4:	0491                	addi	s1,s1,4
    80003ee6:	01248b63          	beq	s1,s2,80003efc <itrunc+0x8c>
      if(a[j])
    80003eea:	408c                	lw	a1,0(s1)
    80003eec:	dde5                	beqz	a1,80003ee4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003eee:	0009a503          	lw	a0,0(s3)
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	8b2080e7          	jalr	-1870(ra) # 800037a4 <bfree>
    80003efa:	b7ed                	j	80003ee4 <itrunc+0x74>
    brelse(bp);
    80003efc:	8552                	mv	a0,s4
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	790080e7          	jalr	1936(ra) # 8000368e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f06:	0809a583          	lw	a1,128(s3)
    80003f0a:	0009a503          	lw	a0,0(s3)
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	896080e7          	jalr	-1898(ra) # 800037a4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f16:	0809a023          	sw	zero,128(s3)
    80003f1a:	bf51                	j	80003eae <itrunc+0x3e>

0000000080003f1c <iput>:
{
    80003f1c:	1101                	addi	sp,sp,-32
    80003f1e:	ec06                	sd	ra,24(sp)
    80003f20:	e822                	sd	s0,16(sp)
    80003f22:	e426                	sd	s1,8(sp)
    80003f24:	e04a                	sd	s2,0(sp)
    80003f26:	1000                	addi	s0,sp,32
    80003f28:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f2a:	00022517          	auipc	a0,0x22
    80003f2e:	e9e50513          	addi	a0,a0,-354 # 80025dc8 <itable>
    80003f32:	ffffd097          	auipc	ra,0xffffd
    80003f36:	c90080e7          	jalr	-880(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f3a:	4498                	lw	a4,8(s1)
    80003f3c:	4785                	li	a5,1
    80003f3e:	02f70363          	beq	a4,a5,80003f64 <iput+0x48>
  ip->ref--;
    80003f42:	449c                	lw	a5,8(s1)
    80003f44:	37fd                	addiw	a5,a5,-1
    80003f46:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f48:	00022517          	auipc	a0,0x22
    80003f4c:	e8050513          	addi	a0,a0,-384 # 80025dc8 <itable>
    80003f50:	ffffd097          	auipc	ra,0xffffd
    80003f54:	d38080e7          	jalr	-712(ra) # 80000c88 <release>
}
    80003f58:	60e2                	ld	ra,24(sp)
    80003f5a:	6442                	ld	s0,16(sp)
    80003f5c:	64a2                	ld	s1,8(sp)
    80003f5e:	6902                	ld	s2,0(sp)
    80003f60:	6105                	addi	sp,sp,32
    80003f62:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f64:	40bc                	lw	a5,64(s1)
    80003f66:	dff1                	beqz	a5,80003f42 <iput+0x26>
    80003f68:	04a49783          	lh	a5,74(s1)
    80003f6c:	fbf9                	bnez	a5,80003f42 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f6e:	01048913          	addi	s2,s1,16
    80003f72:	854a                	mv	a0,s2
    80003f74:	00001097          	auipc	ra,0x1
    80003f78:	abc080e7          	jalr	-1348(ra) # 80004a30 <acquiresleep>
    release(&itable.lock);
    80003f7c:	00022517          	auipc	a0,0x22
    80003f80:	e4c50513          	addi	a0,a0,-436 # 80025dc8 <itable>
    80003f84:	ffffd097          	auipc	ra,0xffffd
    80003f88:	d04080e7          	jalr	-764(ra) # 80000c88 <release>
    itrunc(ip);
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	ee2080e7          	jalr	-286(ra) # 80003e70 <itrunc>
    ip->type = 0;
    80003f96:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f9a:	8526                	mv	a0,s1
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	cfc080e7          	jalr	-772(ra) # 80003c98 <iupdate>
    ip->valid = 0;
    80003fa4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003fa8:	854a                	mv	a0,s2
    80003faa:	00001097          	auipc	ra,0x1
    80003fae:	adc080e7          	jalr	-1316(ra) # 80004a86 <releasesleep>
    acquire(&itable.lock);
    80003fb2:	00022517          	auipc	a0,0x22
    80003fb6:	e1650513          	addi	a0,a0,-490 # 80025dc8 <itable>
    80003fba:	ffffd097          	auipc	ra,0xffffd
    80003fbe:	c08080e7          	jalr	-1016(ra) # 80000bc2 <acquire>
    80003fc2:	b741                	j	80003f42 <iput+0x26>

0000000080003fc4 <iunlockput>:
{
    80003fc4:	1101                	addi	sp,sp,-32
    80003fc6:	ec06                	sd	ra,24(sp)
    80003fc8:	e822                	sd	s0,16(sp)
    80003fca:	e426                	sd	s1,8(sp)
    80003fcc:	1000                	addi	s0,sp,32
    80003fce:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	e54080e7          	jalr	-428(ra) # 80003e24 <iunlock>
  iput(ip);
    80003fd8:	8526                	mv	a0,s1
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	f42080e7          	jalr	-190(ra) # 80003f1c <iput>
}
    80003fe2:	60e2                	ld	ra,24(sp)
    80003fe4:	6442                	ld	s0,16(sp)
    80003fe6:	64a2                	ld	s1,8(sp)
    80003fe8:	6105                	addi	sp,sp,32
    80003fea:	8082                	ret

0000000080003fec <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fec:	1141                	addi	sp,sp,-16
    80003fee:	e422                	sd	s0,8(sp)
    80003ff0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ff2:	411c                	lw	a5,0(a0)
    80003ff4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ff6:	415c                	lw	a5,4(a0)
    80003ff8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ffa:	04451783          	lh	a5,68(a0)
    80003ffe:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004002:	04a51783          	lh	a5,74(a0)
    80004006:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000400a:	04c56783          	lwu	a5,76(a0)
    8000400e:	e99c                	sd	a5,16(a1)
}
    80004010:	6422                	ld	s0,8(sp)
    80004012:	0141                	addi	sp,sp,16
    80004014:	8082                	ret

0000000080004016 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004016:	457c                	lw	a5,76(a0)
    80004018:	0ed7e963          	bltu	a5,a3,8000410a <readi+0xf4>
{
    8000401c:	7159                	addi	sp,sp,-112
    8000401e:	f486                	sd	ra,104(sp)
    80004020:	f0a2                	sd	s0,96(sp)
    80004022:	eca6                	sd	s1,88(sp)
    80004024:	e8ca                	sd	s2,80(sp)
    80004026:	e4ce                	sd	s3,72(sp)
    80004028:	e0d2                	sd	s4,64(sp)
    8000402a:	fc56                	sd	s5,56(sp)
    8000402c:	f85a                	sd	s6,48(sp)
    8000402e:	f45e                	sd	s7,40(sp)
    80004030:	f062                	sd	s8,32(sp)
    80004032:	ec66                	sd	s9,24(sp)
    80004034:	e86a                	sd	s10,16(sp)
    80004036:	e46e                	sd	s11,8(sp)
    80004038:	1880                	addi	s0,sp,112
    8000403a:	8baa                	mv	s7,a0
    8000403c:	8c2e                	mv	s8,a1
    8000403e:	8ab2                	mv	s5,a2
    80004040:	84b6                	mv	s1,a3
    80004042:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004044:	9f35                	addw	a4,a4,a3
    return 0;
    80004046:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004048:	0ad76063          	bltu	a4,a3,800040e8 <readi+0xd2>
  if(off + n > ip->size)
    8000404c:	00e7f463          	bgeu	a5,a4,80004054 <readi+0x3e>
    n = ip->size - off;
    80004050:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004054:	0a0b0963          	beqz	s6,80004106 <readi+0xf0>
    80004058:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000405a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000405e:	5cfd                	li	s9,-1
    80004060:	a82d                	j	8000409a <readi+0x84>
    80004062:	020a1d93          	slli	s11,s4,0x20
    80004066:	020ddd93          	srli	s11,s11,0x20
    8000406a:	05890793          	addi	a5,s2,88
    8000406e:	86ee                	mv	a3,s11
    80004070:	963e                	add	a2,a2,a5
    80004072:	85d6                	mv	a1,s5
    80004074:	8562                	mv	a0,s8
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	804080e7          	jalr	-2044(ra) # 8000287a <either_copyout>
    8000407e:	05950d63          	beq	a0,s9,800040d8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004082:	854a                	mv	a0,s2
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	60a080e7          	jalr	1546(ra) # 8000368e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000408c:	013a09bb          	addw	s3,s4,s3
    80004090:	009a04bb          	addw	s1,s4,s1
    80004094:	9aee                	add	s5,s5,s11
    80004096:	0569f763          	bgeu	s3,s6,800040e4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000409a:	000ba903          	lw	s2,0(s7)
    8000409e:	00a4d59b          	srliw	a1,s1,0xa
    800040a2:	855e                	mv	a0,s7
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	8ae080e7          	jalr	-1874(ra) # 80003952 <bmap>
    800040ac:	0005059b          	sext.w	a1,a0
    800040b0:	854a                	mv	a0,s2
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	4ac080e7          	jalr	1196(ra) # 8000355e <bread>
    800040ba:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040bc:	3ff4f613          	andi	a2,s1,1023
    800040c0:	40cd07bb          	subw	a5,s10,a2
    800040c4:	413b073b          	subw	a4,s6,s3
    800040c8:	8a3e                	mv	s4,a5
    800040ca:	2781                	sext.w	a5,a5
    800040cc:	0007069b          	sext.w	a3,a4
    800040d0:	f8f6f9e3          	bgeu	a3,a5,80004062 <readi+0x4c>
    800040d4:	8a3a                	mv	s4,a4
    800040d6:	b771                	j	80004062 <readi+0x4c>
      brelse(bp);
    800040d8:	854a                	mv	a0,s2
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	5b4080e7          	jalr	1460(ra) # 8000368e <brelse>
      tot = -1;
    800040e2:	59fd                	li	s3,-1
  }
  return tot;
    800040e4:	0009851b          	sext.w	a0,s3
}
    800040e8:	70a6                	ld	ra,104(sp)
    800040ea:	7406                	ld	s0,96(sp)
    800040ec:	64e6                	ld	s1,88(sp)
    800040ee:	6946                	ld	s2,80(sp)
    800040f0:	69a6                	ld	s3,72(sp)
    800040f2:	6a06                	ld	s4,64(sp)
    800040f4:	7ae2                	ld	s5,56(sp)
    800040f6:	7b42                	ld	s6,48(sp)
    800040f8:	7ba2                	ld	s7,40(sp)
    800040fa:	7c02                	ld	s8,32(sp)
    800040fc:	6ce2                	ld	s9,24(sp)
    800040fe:	6d42                	ld	s10,16(sp)
    80004100:	6da2                	ld	s11,8(sp)
    80004102:	6165                	addi	sp,sp,112
    80004104:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004106:	89da                	mv	s3,s6
    80004108:	bff1                	j	800040e4 <readi+0xce>
    return 0;
    8000410a:	4501                	li	a0,0
}
    8000410c:	8082                	ret

000000008000410e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000410e:	457c                	lw	a5,76(a0)
    80004110:	10d7e863          	bltu	a5,a3,80004220 <writei+0x112>
{
    80004114:	7159                	addi	sp,sp,-112
    80004116:	f486                	sd	ra,104(sp)
    80004118:	f0a2                	sd	s0,96(sp)
    8000411a:	eca6                	sd	s1,88(sp)
    8000411c:	e8ca                	sd	s2,80(sp)
    8000411e:	e4ce                	sd	s3,72(sp)
    80004120:	e0d2                	sd	s4,64(sp)
    80004122:	fc56                	sd	s5,56(sp)
    80004124:	f85a                	sd	s6,48(sp)
    80004126:	f45e                	sd	s7,40(sp)
    80004128:	f062                	sd	s8,32(sp)
    8000412a:	ec66                	sd	s9,24(sp)
    8000412c:	e86a                	sd	s10,16(sp)
    8000412e:	e46e                	sd	s11,8(sp)
    80004130:	1880                	addi	s0,sp,112
    80004132:	8b2a                	mv	s6,a0
    80004134:	8c2e                	mv	s8,a1
    80004136:	8ab2                	mv	s5,a2
    80004138:	8936                	mv	s2,a3
    8000413a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000413c:	00e687bb          	addw	a5,a3,a4
    80004140:	0ed7e263          	bltu	a5,a3,80004224 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004144:	00043737          	lui	a4,0x43
    80004148:	0ef76063          	bltu	a4,a5,80004228 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000414c:	0c0b8863          	beqz	s7,8000421c <writei+0x10e>
    80004150:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004152:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004156:	5cfd                	li	s9,-1
    80004158:	a091                	j	8000419c <writei+0x8e>
    8000415a:	02099d93          	slli	s11,s3,0x20
    8000415e:	020ddd93          	srli	s11,s11,0x20
    80004162:	05848793          	addi	a5,s1,88
    80004166:	86ee                	mv	a3,s11
    80004168:	8656                	mv	a2,s5
    8000416a:	85e2                	mv	a1,s8
    8000416c:	953e                	add	a0,a0,a5
    8000416e:	ffffe097          	auipc	ra,0xffffe
    80004172:	764080e7          	jalr	1892(ra) # 800028d2 <either_copyin>
    80004176:	07950263          	beq	a0,s9,800041da <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000417a:	8526                	mv	a0,s1
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	794080e7          	jalr	1940(ra) # 80004910 <log_write>
    brelse(bp);
    80004184:	8526                	mv	a0,s1
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	508080e7          	jalr	1288(ra) # 8000368e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000418e:	01498a3b          	addw	s4,s3,s4
    80004192:	0129893b          	addw	s2,s3,s2
    80004196:	9aee                	add	s5,s5,s11
    80004198:	057a7663          	bgeu	s4,s7,800041e4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000419c:	000b2483          	lw	s1,0(s6)
    800041a0:	00a9559b          	srliw	a1,s2,0xa
    800041a4:	855a                	mv	a0,s6
    800041a6:	fffff097          	auipc	ra,0xfffff
    800041aa:	7ac080e7          	jalr	1964(ra) # 80003952 <bmap>
    800041ae:	0005059b          	sext.w	a1,a0
    800041b2:	8526                	mv	a0,s1
    800041b4:	fffff097          	auipc	ra,0xfffff
    800041b8:	3aa080e7          	jalr	938(ra) # 8000355e <bread>
    800041bc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041be:	3ff97513          	andi	a0,s2,1023
    800041c2:	40ad07bb          	subw	a5,s10,a0
    800041c6:	414b873b          	subw	a4,s7,s4
    800041ca:	89be                	mv	s3,a5
    800041cc:	2781                	sext.w	a5,a5
    800041ce:	0007069b          	sext.w	a3,a4
    800041d2:	f8f6f4e3          	bgeu	a3,a5,8000415a <writei+0x4c>
    800041d6:	89ba                	mv	s3,a4
    800041d8:	b749                	j	8000415a <writei+0x4c>
      brelse(bp);
    800041da:	8526                	mv	a0,s1
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	4b2080e7          	jalr	1202(ra) # 8000368e <brelse>
  }

  if(off > ip->size)
    800041e4:	04cb2783          	lw	a5,76(s6)
    800041e8:	0127f463          	bgeu	a5,s2,800041f0 <writei+0xe2>
    ip->size = off;
    800041ec:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041f0:	855a                	mv	a0,s6
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	aa6080e7          	jalr	-1370(ra) # 80003c98 <iupdate>

  return tot;
    800041fa:	000a051b          	sext.w	a0,s4
}
    800041fe:	70a6                	ld	ra,104(sp)
    80004200:	7406                	ld	s0,96(sp)
    80004202:	64e6                	ld	s1,88(sp)
    80004204:	6946                	ld	s2,80(sp)
    80004206:	69a6                	ld	s3,72(sp)
    80004208:	6a06                	ld	s4,64(sp)
    8000420a:	7ae2                	ld	s5,56(sp)
    8000420c:	7b42                	ld	s6,48(sp)
    8000420e:	7ba2                	ld	s7,40(sp)
    80004210:	7c02                	ld	s8,32(sp)
    80004212:	6ce2                	ld	s9,24(sp)
    80004214:	6d42                	ld	s10,16(sp)
    80004216:	6da2                	ld	s11,8(sp)
    80004218:	6165                	addi	sp,sp,112
    8000421a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000421c:	8a5e                	mv	s4,s7
    8000421e:	bfc9                	j	800041f0 <writei+0xe2>
    return -1;
    80004220:	557d                	li	a0,-1
}
    80004222:	8082                	ret
    return -1;
    80004224:	557d                	li	a0,-1
    80004226:	bfe1                	j	800041fe <writei+0xf0>
    return -1;
    80004228:	557d                	li	a0,-1
    8000422a:	bfd1                	j	800041fe <writei+0xf0>

000000008000422c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000422c:	1141                	addi	sp,sp,-16
    8000422e:	e406                	sd	ra,8(sp)
    80004230:	e022                	sd	s0,0(sp)
    80004232:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004234:	4639                	li	a2,14
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	b84080e7          	jalr	-1148(ra) # 80000dba <strncmp>
}
    8000423e:	60a2                	ld	ra,8(sp)
    80004240:	6402                	ld	s0,0(sp)
    80004242:	0141                	addi	sp,sp,16
    80004244:	8082                	ret

0000000080004246 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004246:	7139                	addi	sp,sp,-64
    80004248:	fc06                	sd	ra,56(sp)
    8000424a:	f822                	sd	s0,48(sp)
    8000424c:	f426                	sd	s1,40(sp)
    8000424e:	f04a                	sd	s2,32(sp)
    80004250:	ec4e                	sd	s3,24(sp)
    80004252:	e852                	sd	s4,16(sp)
    80004254:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004256:	04451703          	lh	a4,68(a0)
    8000425a:	4785                	li	a5,1
    8000425c:	00f71a63          	bne	a4,a5,80004270 <dirlookup+0x2a>
    80004260:	892a                	mv	s2,a0
    80004262:	89ae                	mv	s3,a1
    80004264:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004266:	457c                	lw	a5,76(a0)
    80004268:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000426a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000426c:	e79d                	bnez	a5,8000429a <dirlookup+0x54>
    8000426e:	a8a5                	j	800042e6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004270:	00004517          	auipc	a0,0x4
    80004274:	4c850513          	addi	a0,a0,1224 # 80008738 <syscalls+0x1b8>
    80004278:	ffffc097          	auipc	ra,0xffffc
    8000427c:	2b2080e7          	jalr	690(ra) # 8000052a <panic>
      panic("dirlookup read");
    80004280:	00004517          	auipc	a0,0x4
    80004284:	4d050513          	addi	a0,a0,1232 # 80008750 <syscalls+0x1d0>
    80004288:	ffffc097          	auipc	ra,0xffffc
    8000428c:	2a2080e7          	jalr	674(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004290:	24c1                	addiw	s1,s1,16
    80004292:	04c92783          	lw	a5,76(s2)
    80004296:	04f4f763          	bgeu	s1,a5,800042e4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000429a:	4741                	li	a4,16
    8000429c:	86a6                	mv	a3,s1
    8000429e:	fc040613          	addi	a2,s0,-64
    800042a2:	4581                	li	a1,0
    800042a4:	854a                	mv	a0,s2
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	d70080e7          	jalr	-656(ra) # 80004016 <readi>
    800042ae:	47c1                	li	a5,16
    800042b0:	fcf518e3          	bne	a0,a5,80004280 <dirlookup+0x3a>
    if(de.inum == 0)
    800042b4:	fc045783          	lhu	a5,-64(s0)
    800042b8:	dfe1                	beqz	a5,80004290 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800042ba:	fc240593          	addi	a1,s0,-62
    800042be:	854e                	mv	a0,s3
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	f6c080e7          	jalr	-148(ra) # 8000422c <namecmp>
    800042c8:	f561                	bnez	a0,80004290 <dirlookup+0x4a>
      if(poff)
    800042ca:	000a0463          	beqz	s4,800042d2 <dirlookup+0x8c>
        *poff = off;
    800042ce:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042d2:	fc045583          	lhu	a1,-64(s0)
    800042d6:	00092503          	lw	a0,0(s2)
    800042da:	fffff097          	auipc	ra,0xfffff
    800042de:	754080e7          	jalr	1876(ra) # 80003a2e <iget>
    800042e2:	a011                	j	800042e6 <dirlookup+0xa0>
  return 0;
    800042e4:	4501                	li	a0,0
}
    800042e6:	70e2                	ld	ra,56(sp)
    800042e8:	7442                	ld	s0,48(sp)
    800042ea:	74a2                	ld	s1,40(sp)
    800042ec:	7902                	ld	s2,32(sp)
    800042ee:	69e2                	ld	s3,24(sp)
    800042f0:	6a42                	ld	s4,16(sp)
    800042f2:	6121                	addi	sp,sp,64
    800042f4:	8082                	ret

00000000800042f6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042f6:	711d                	addi	sp,sp,-96
    800042f8:	ec86                	sd	ra,88(sp)
    800042fa:	e8a2                	sd	s0,80(sp)
    800042fc:	e4a6                	sd	s1,72(sp)
    800042fe:	e0ca                	sd	s2,64(sp)
    80004300:	fc4e                	sd	s3,56(sp)
    80004302:	f852                	sd	s4,48(sp)
    80004304:	f456                	sd	s5,40(sp)
    80004306:	f05a                	sd	s6,32(sp)
    80004308:	ec5e                	sd	s7,24(sp)
    8000430a:	e862                	sd	s8,16(sp)
    8000430c:	e466                	sd	s9,8(sp)
    8000430e:	1080                	addi	s0,sp,96
    80004310:	84aa                	mv	s1,a0
    80004312:	8aae                	mv	s5,a1
    80004314:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004316:	00054703          	lbu	a4,0(a0)
    8000431a:	02f00793          	li	a5,47
    8000431e:	02f70363          	beq	a4,a5,80004344 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	692080e7          	jalr	1682(ra) # 800019b4 <myproc>
    8000432a:	2e853503          	ld	a0,744(a0)
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	9f6080e7          	jalr	-1546(ra) # 80003d24 <idup>
    80004336:	89aa                	mv	s3,a0
  while(*path == '/')
    80004338:	02f00913          	li	s2,47
  len = path - s;
    8000433c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000433e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004340:	4b85                	li	s7,1
    80004342:	a865                	j	800043fa <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004344:	4585                	li	a1,1
    80004346:	4505                	li	a0,1
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	6e6080e7          	jalr	1766(ra) # 80003a2e <iget>
    80004350:	89aa                	mv	s3,a0
    80004352:	b7dd                	j	80004338 <namex+0x42>
      iunlockput(ip);
    80004354:	854e                	mv	a0,s3
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	c6e080e7          	jalr	-914(ra) # 80003fc4 <iunlockput>
      return 0;
    8000435e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004360:	854e                	mv	a0,s3
    80004362:	60e6                	ld	ra,88(sp)
    80004364:	6446                	ld	s0,80(sp)
    80004366:	64a6                	ld	s1,72(sp)
    80004368:	6906                	ld	s2,64(sp)
    8000436a:	79e2                	ld	s3,56(sp)
    8000436c:	7a42                	ld	s4,48(sp)
    8000436e:	7aa2                	ld	s5,40(sp)
    80004370:	7b02                	ld	s6,32(sp)
    80004372:	6be2                	ld	s7,24(sp)
    80004374:	6c42                	ld	s8,16(sp)
    80004376:	6ca2                	ld	s9,8(sp)
    80004378:	6125                	addi	sp,sp,96
    8000437a:	8082                	ret
      iunlock(ip);
    8000437c:	854e                	mv	a0,s3
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	aa6080e7          	jalr	-1370(ra) # 80003e24 <iunlock>
      return ip;
    80004386:	bfe9                	j	80004360 <namex+0x6a>
      iunlockput(ip);
    80004388:	854e                	mv	a0,s3
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	c3a080e7          	jalr	-966(ra) # 80003fc4 <iunlockput>
      return 0;
    80004392:	89e6                	mv	s3,s9
    80004394:	b7f1                	j	80004360 <namex+0x6a>
  len = path - s;
    80004396:	40b48633          	sub	a2,s1,a1
    8000439a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000439e:	099c5463          	bge	s8,s9,80004426 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800043a2:	4639                	li	a2,14
    800043a4:	8552                	mv	a0,s4
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	998080e7          	jalr	-1640(ra) # 80000d3e <memmove>
  while(*path == '/')
    800043ae:	0004c783          	lbu	a5,0(s1)
    800043b2:	01279763          	bne	a5,s2,800043c0 <namex+0xca>
    path++;
    800043b6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043b8:	0004c783          	lbu	a5,0(s1)
    800043bc:	ff278de3          	beq	a5,s2,800043b6 <namex+0xc0>
    ilock(ip);
    800043c0:	854e                	mv	a0,s3
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	9a0080e7          	jalr	-1632(ra) # 80003d62 <ilock>
    if(ip->type != T_DIR){
    800043ca:	04499783          	lh	a5,68(s3)
    800043ce:	f97793e3          	bne	a5,s7,80004354 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800043d2:	000a8563          	beqz	s5,800043dc <namex+0xe6>
    800043d6:	0004c783          	lbu	a5,0(s1)
    800043da:	d3cd                	beqz	a5,8000437c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043dc:	865a                	mv	a2,s6
    800043de:	85d2                	mv	a1,s4
    800043e0:	854e                	mv	a0,s3
    800043e2:	00000097          	auipc	ra,0x0
    800043e6:	e64080e7          	jalr	-412(ra) # 80004246 <dirlookup>
    800043ea:	8caa                	mv	s9,a0
    800043ec:	dd51                	beqz	a0,80004388 <namex+0x92>
    iunlockput(ip);
    800043ee:	854e                	mv	a0,s3
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	bd4080e7          	jalr	-1068(ra) # 80003fc4 <iunlockput>
    ip = next;
    800043f8:	89e6                	mv	s3,s9
  while(*path == '/')
    800043fa:	0004c783          	lbu	a5,0(s1)
    800043fe:	05279763          	bne	a5,s2,8000444c <namex+0x156>
    path++;
    80004402:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004404:	0004c783          	lbu	a5,0(s1)
    80004408:	ff278de3          	beq	a5,s2,80004402 <namex+0x10c>
  if(*path == 0)
    8000440c:	c79d                	beqz	a5,8000443a <namex+0x144>
    path++;
    8000440e:	85a6                	mv	a1,s1
  len = path - s;
    80004410:	8cda                	mv	s9,s6
    80004412:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004414:	01278963          	beq	a5,s2,80004426 <namex+0x130>
    80004418:	dfbd                	beqz	a5,80004396 <namex+0xa0>
    path++;
    8000441a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000441c:	0004c783          	lbu	a5,0(s1)
    80004420:	ff279ce3          	bne	a5,s2,80004418 <namex+0x122>
    80004424:	bf8d                	j	80004396 <namex+0xa0>
    memmove(name, s, len);
    80004426:	2601                	sext.w	a2,a2
    80004428:	8552                	mv	a0,s4
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	914080e7          	jalr	-1772(ra) # 80000d3e <memmove>
    name[len] = 0;
    80004432:	9cd2                	add	s9,s9,s4
    80004434:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004438:	bf9d                	j	800043ae <namex+0xb8>
  if(nameiparent){
    8000443a:	f20a83e3          	beqz	s5,80004360 <namex+0x6a>
    iput(ip);
    8000443e:	854e                	mv	a0,s3
    80004440:	00000097          	auipc	ra,0x0
    80004444:	adc080e7          	jalr	-1316(ra) # 80003f1c <iput>
    return 0;
    80004448:	4981                	li	s3,0
    8000444a:	bf19                	j	80004360 <namex+0x6a>
  if(*path == 0)
    8000444c:	d7fd                	beqz	a5,8000443a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000444e:	0004c783          	lbu	a5,0(s1)
    80004452:	85a6                	mv	a1,s1
    80004454:	b7d1                	j	80004418 <namex+0x122>

0000000080004456 <dirlink>:
{
    80004456:	7139                	addi	sp,sp,-64
    80004458:	fc06                	sd	ra,56(sp)
    8000445a:	f822                	sd	s0,48(sp)
    8000445c:	f426                	sd	s1,40(sp)
    8000445e:	f04a                	sd	s2,32(sp)
    80004460:	ec4e                	sd	s3,24(sp)
    80004462:	e852                	sd	s4,16(sp)
    80004464:	0080                	addi	s0,sp,64
    80004466:	892a                	mv	s2,a0
    80004468:	8a2e                	mv	s4,a1
    8000446a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000446c:	4601                	li	a2,0
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	dd8080e7          	jalr	-552(ra) # 80004246 <dirlookup>
    80004476:	e93d                	bnez	a0,800044ec <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004478:	04c92483          	lw	s1,76(s2)
    8000447c:	c49d                	beqz	s1,800044aa <dirlink+0x54>
    8000447e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004480:	4741                	li	a4,16
    80004482:	86a6                	mv	a3,s1
    80004484:	fc040613          	addi	a2,s0,-64
    80004488:	4581                	li	a1,0
    8000448a:	854a                	mv	a0,s2
    8000448c:	00000097          	auipc	ra,0x0
    80004490:	b8a080e7          	jalr	-1142(ra) # 80004016 <readi>
    80004494:	47c1                	li	a5,16
    80004496:	06f51163          	bne	a0,a5,800044f8 <dirlink+0xa2>
    if(de.inum == 0)
    8000449a:	fc045783          	lhu	a5,-64(s0)
    8000449e:	c791                	beqz	a5,800044aa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044a0:	24c1                	addiw	s1,s1,16
    800044a2:	04c92783          	lw	a5,76(s2)
    800044a6:	fcf4ede3          	bltu	s1,a5,80004480 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044aa:	4639                	li	a2,14
    800044ac:	85d2                	mv	a1,s4
    800044ae:	fc240513          	addi	a0,s0,-62
    800044b2:	ffffd097          	auipc	ra,0xffffd
    800044b6:	944080e7          	jalr	-1724(ra) # 80000df6 <strncpy>
  de.inum = inum;
    800044ba:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044be:	4741                	li	a4,16
    800044c0:	86a6                	mv	a3,s1
    800044c2:	fc040613          	addi	a2,s0,-64
    800044c6:	4581                	li	a1,0
    800044c8:	854a                	mv	a0,s2
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	c44080e7          	jalr	-956(ra) # 8000410e <writei>
    800044d2:	872a                	mv	a4,a0
    800044d4:	47c1                	li	a5,16
  return 0;
    800044d6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044d8:	02f71863          	bne	a4,a5,80004508 <dirlink+0xb2>
}
    800044dc:	70e2                	ld	ra,56(sp)
    800044de:	7442                	ld	s0,48(sp)
    800044e0:	74a2                	ld	s1,40(sp)
    800044e2:	7902                	ld	s2,32(sp)
    800044e4:	69e2                	ld	s3,24(sp)
    800044e6:	6a42                	ld	s4,16(sp)
    800044e8:	6121                	addi	sp,sp,64
    800044ea:	8082                	ret
    iput(ip);
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	a30080e7          	jalr	-1488(ra) # 80003f1c <iput>
    return -1;
    800044f4:	557d                	li	a0,-1
    800044f6:	b7dd                	j	800044dc <dirlink+0x86>
      panic("dirlink read");
    800044f8:	00004517          	auipc	a0,0x4
    800044fc:	26850513          	addi	a0,a0,616 # 80008760 <syscalls+0x1e0>
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	02a080e7          	jalr	42(ra) # 8000052a <panic>
    panic("dirlink");
    80004508:	00004517          	auipc	a0,0x4
    8000450c:	36850513          	addi	a0,a0,872 # 80008870 <syscalls+0x2f0>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	01a080e7          	jalr	26(ra) # 8000052a <panic>

0000000080004518 <namei>:

struct inode*
namei(char *path)
{
    80004518:	1101                	addi	sp,sp,-32
    8000451a:	ec06                	sd	ra,24(sp)
    8000451c:	e822                	sd	s0,16(sp)
    8000451e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004520:	fe040613          	addi	a2,s0,-32
    80004524:	4581                	li	a1,0
    80004526:	00000097          	auipc	ra,0x0
    8000452a:	dd0080e7          	jalr	-560(ra) # 800042f6 <namex>
}
    8000452e:	60e2                	ld	ra,24(sp)
    80004530:	6442                	ld	s0,16(sp)
    80004532:	6105                	addi	sp,sp,32
    80004534:	8082                	ret

0000000080004536 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004536:	1141                	addi	sp,sp,-16
    80004538:	e406                	sd	ra,8(sp)
    8000453a:	e022                	sd	s0,0(sp)
    8000453c:	0800                	addi	s0,sp,16
    8000453e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004540:	4585                	li	a1,1
    80004542:	00000097          	auipc	ra,0x0
    80004546:	db4080e7          	jalr	-588(ra) # 800042f6 <namex>
}
    8000454a:	60a2                	ld	ra,8(sp)
    8000454c:	6402                	ld	s0,0(sp)
    8000454e:	0141                	addi	sp,sp,16
    80004550:	8082                	ret

0000000080004552 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004552:	1101                	addi	sp,sp,-32
    80004554:	ec06                	sd	ra,24(sp)
    80004556:	e822                	sd	s0,16(sp)
    80004558:	e426                	sd	s1,8(sp)
    8000455a:	e04a                	sd	s2,0(sp)
    8000455c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000455e:	00023917          	auipc	s2,0x23
    80004562:	31290913          	addi	s2,s2,786 # 80027870 <log>
    80004566:	01892583          	lw	a1,24(s2)
    8000456a:	02892503          	lw	a0,40(s2)
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	ff0080e7          	jalr	-16(ra) # 8000355e <bread>
    80004576:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004578:	02c92683          	lw	a3,44(s2)
    8000457c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000457e:	02d05863          	blez	a3,800045ae <write_head+0x5c>
    80004582:	00023797          	auipc	a5,0x23
    80004586:	31e78793          	addi	a5,a5,798 # 800278a0 <log+0x30>
    8000458a:	05c50713          	addi	a4,a0,92
    8000458e:	36fd                	addiw	a3,a3,-1
    80004590:	02069613          	slli	a2,a3,0x20
    80004594:	01e65693          	srli	a3,a2,0x1e
    80004598:	00023617          	auipc	a2,0x23
    8000459c:	30c60613          	addi	a2,a2,780 # 800278a4 <log+0x34>
    800045a0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800045a2:	4390                	lw	a2,0(a5)
    800045a4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045a6:	0791                	addi	a5,a5,4
    800045a8:	0711                	addi	a4,a4,4
    800045aa:	fed79ce3          	bne	a5,a3,800045a2 <write_head+0x50>
  }
  bwrite(buf);
    800045ae:	8526                	mv	a0,s1
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	0a0080e7          	jalr	160(ra) # 80003650 <bwrite>
  brelse(buf);
    800045b8:	8526                	mv	a0,s1
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	0d4080e7          	jalr	212(ra) # 8000368e <brelse>
}
    800045c2:	60e2                	ld	ra,24(sp)
    800045c4:	6442                	ld	s0,16(sp)
    800045c6:	64a2                	ld	s1,8(sp)
    800045c8:	6902                	ld	s2,0(sp)
    800045ca:	6105                	addi	sp,sp,32
    800045cc:	8082                	ret

00000000800045ce <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ce:	00023797          	auipc	a5,0x23
    800045d2:	2ce7a783          	lw	a5,718(a5) # 8002789c <log+0x2c>
    800045d6:	0af05d63          	blez	a5,80004690 <install_trans+0xc2>
{
    800045da:	7139                	addi	sp,sp,-64
    800045dc:	fc06                	sd	ra,56(sp)
    800045de:	f822                	sd	s0,48(sp)
    800045e0:	f426                	sd	s1,40(sp)
    800045e2:	f04a                	sd	s2,32(sp)
    800045e4:	ec4e                	sd	s3,24(sp)
    800045e6:	e852                	sd	s4,16(sp)
    800045e8:	e456                	sd	s5,8(sp)
    800045ea:	e05a                	sd	s6,0(sp)
    800045ec:	0080                	addi	s0,sp,64
    800045ee:	8b2a                	mv	s6,a0
    800045f0:	00023a97          	auipc	s5,0x23
    800045f4:	2b0a8a93          	addi	s5,s5,688 # 800278a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045f8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045fa:	00023997          	auipc	s3,0x23
    800045fe:	27698993          	addi	s3,s3,630 # 80027870 <log>
    80004602:	a00d                	j	80004624 <install_trans+0x56>
    brelse(lbuf);
    80004604:	854a                	mv	a0,s2
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	088080e7          	jalr	136(ra) # 8000368e <brelse>
    brelse(dbuf);
    8000460e:	8526                	mv	a0,s1
    80004610:	fffff097          	auipc	ra,0xfffff
    80004614:	07e080e7          	jalr	126(ra) # 8000368e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004618:	2a05                	addiw	s4,s4,1
    8000461a:	0a91                	addi	s5,s5,4
    8000461c:	02c9a783          	lw	a5,44(s3)
    80004620:	04fa5e63          	bge	s4,a5,8000467c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004624:	0189a583          	lw	a1,24(s3)
    80004628:	014585bb          	addw	a1,a1,s4
    8000462c:	2585                	addiw	a1,a1,1
    8000462e:	0289a503          	lw	a0,40(s3)
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	f2c080e7          	jalr	-212(ra) # 8000355e <bread>
    8000463a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000463c:	000aa583          	lw	a1,0(s5)
    80004640:	0289a503          	lw	a0,40(s3)
    80004644:	fffff097          	auipc	ra,0xfffff
    80004648:	f1a080e7          	jalr	-230(ra) # 8000355e <bread>
    8000464c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000464e:	40000613          	li	a2,1024
    80004652:	05890593          	addi	a1,s2,88
    80004656:	05850513          	addi	a0,a0,88
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	6e4080e7          	jalr	1764(ra) # 80000d3e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004662:	8526                	mv	a0,s1
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	fec080e7          	jalr	-20(ra) # 80003650 <bwrite>
    if(recovering == 0)
    8000466c:	f80b1ce3          	bnez	s6,80004604 <install_trans+0x36>
      bunpin(dbuf);
    80004670:	8526                	mv	a0,s1
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	0f6080e7          	jalr	246(ra) # 80003768 <bunpin>
    8000467a:	b769                	j	80004604 <install_trans+0x36>
}
    8000467c:	70e2                	ld	ra,56(sp)
    8000467e:	7442                	ld	s0,48(sp)
    80004680:	74a2                	ld	s1,40(sp)
    80004682:	7902                	ld	s2,32(sp)
    80004684:	69e2                	ld	s3,24(sp)
    80004686:	6a42                	ld	s4,16(sp)
    80004688:	6aa2                	ld	s5,8(sp)
    8000468a:	6b02                	ld	s6,0(sp)
    8000468c:	6121                	addi	sp,sp,64
    8000468e:	8082                	ret
    80004690:	8082                	ret

0000000080004692 <initlog>:
{
    80004692:	7179                	addi	sp,sp,-48
    80004694:	f406                	sd	ra,40(sp)
    80004696:	f022                	sd	s0,32(sp)
    80004698:	ec26                	sd	s1,24(sp)
    8000469a:	e84a                	sd	s2,16(sp)
    8000469c:	e44e                	sd	s3,8(sp)
    8000469e:	1800                	addi	s0,sp,48
    800046a0:	892a                	mv	s2,a0
    800046a2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046a4:	00023497          	auipc	s1,0x23
    800046a8:	1cc48493          	addi	s1,s1,460 # 80027870 <log>
    800046ac:	00004597          	auipc	a1,0x4
    800046b0:	0c458593          	addi	a1,a1,196 # 80008770 <syscalls+0x1f0>
    800046b4:	8526                	mv	a0,s1
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	47c080e7          	jalr	1148(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    800046be:	0149a583          	lw	a1,20(s3)
    800046c2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046c4:	0109a783          	lw	a5,16(s3)
    800046c8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046ca:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046ce:	854a                	mv	a0,s2
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	e8e080e7          	jalr	-370(ra) # 8000355e <bread>
  log.lh.n = lh->n;
    800046d8:	4d34                	lw	a3,88(a0)
    800046da:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046dc:	02d05663          	blez	a3,80004708 <initlog+0x76>
    800046e0:	05c50793          	addi	a5,a0,92
    800046e4:	00023717          	auipc	a4,0x23
    800046e8:	1bc70713          	addi	a4,a4,444 # 800278a0 <log+0x30>
    800046ec:	36fd                	addiw	a3,a3,-1
    800046ee:	02069613          	slli	a2,a3,0x20
    800046f2:	01e65693          	srli	a3,a2,0x1e
    800046f6:	06050613          	addi	a2,a0,96
    800046fa:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800046fc:	4390                	lw	a2,0(a5)
    800046fe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004700:	0791                	addi	a5,a5,4
    80004702:	0711                	addi	a4,a4,4
    80004704:	fed79ce3          	bne	a5,a3,800046fc <initlog+0x6a>
  brelse(buf);
    80004708:	fffff097          	auipc	ra,0xfffff
    8000470c:	f86080e7          	jalr	-122(ra) # 8000368e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004710:	4505                	li	a0,1
    80004712:	00000097          	auipc	ra,0x0
    80004716:	ebc080e7          	jalr	-324(ra) # 800045ce <install_trans>
  log.lh.n = 0;
    8000471a:	00023797          	auipc	a5,0x23
    8000471e:	1807a123          	sw	zero,386(a5) # 8002789c <log+0x2c>
  write_head(); // clear the log
    80004722:	00000097          	auipc	ra,0x0
    80004726:	e30080e7          	jalr	-464(ra) # 80004552 <write_head>
}
    8000472a:	70a2                	ld	ra,40(sp)
    8000472c:	7402                	ld	s0,32(sp)
    8000472e:	64e2                	ld	s1,24(sp)
    80004730:	6942                	ld	s2,16(sp)
    80004732:	69a2                	ld	s3,8(sp)
    80004734:	6145                	addi	sp,sp,48
    80004736:	8082                	ret

0000000080004738 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004738:	1101                	addi	sp,sp,-32
    8000473a:	ec06                	sd	ra,24(sp)
    8000473c:	e822                	sd	s0,16(sp)
    8000473e:	e426                	sd	s1,8(sp)
    80004740:	e04a                	sd	s2,0(sp)
    80004742:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004744:	00023517          	auipc	a0,0x23
    80004748:	12c50513          	addi	a0,a0,300 # 80027870 <log>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	476080e7          	jalr	1142(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004754:	00023497          	auipc	s1,0x23
    80004758:	11c48493          	addi	s1,s1,284 # 80027870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000475c:	4979                	li	s2,30
    8000475e:	a039                	j	8000476c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004760:	85a6                	mv	a1,s1
    80004762:	8526                	mv	a0,s1
    80004764:	ffffe097          	auipc	ra,0xffffe
    80004768:	d48080e7          	jalr	-696(ra) # 800024ac <sleep>
    if(log.committing){
    8000476c:	50dc                	lw	a5,36(s1)
    8000476e:	fbed                	bnez	a5,80004760 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004770:	509c                	lw	a5,32(s1)
    80004772:	0017871b          	addiw	a4,a5,1
    80004776:	0007069b          	sext.w	a3,a4
    8000477a:	0027179b          	slliw	a5,a4,0x2
    8000477e:	9fb9                	addw	a5,a5,a4
    80004780:	0017979b          	slliw	a5,a5,0x1
    80004784:	54d8                	lw	a4,44(s1)
    80004786:	9fb9                	addw	a5,a5,a4
    80004788:	00f95963          	bge	s2,a5,8000479a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000478c:	85a6                	mv	a1,s1
    8000478e:	8526                	mv	a0,s1
    80004790:	ffffe097          	auipc	ra,0xffffe
    80004794:	d1c080e7          	jalr	-740(ra) # 800024ac <sleep>
    80004798:	bfd1                	j	8000476c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000479a:	00023517          	auipc	a0,0x23
    8000479e:	0d650513          	addi	a0,a0,214 # 80027870 <log>
    800047a2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	4e4080e7          	jalr	1252(ra) # 80000c88 <release>
      break;
    }
  }
}
    800047ac:	60e2                	ld	ra,24(sp)
    800047ae:	6442                	ld	s0,16(sp)
    800047b0:	64a2                	ld	s1,8(sp)
    800047b2:	6902                	ld	s2,0(sp)
    800047b4:	6105                	addi	sp,sp,32
    800047b6:	8082                	ret

00000000800047b8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047b8:	7139                	addi	sp,sp,-64
    800047ba:	fc06                	sd	ra,56(sp)
    800047bc:	f822                	sd	s0,48(sp)
    800047be:	f426                	sd	s1,40(sp)
    800047c0:	f04a                	sd	s2,32(sp)
    800047c2:	ec4e                	sd	s3,24(sp)
    800047c4:	e852                	sd	s4,16(sp)
    800047c6:	e456                	sd	s5,8(sp)
    800047c8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047ca:	00023497          	auipc	s1,0x23
    800047ce:	0a648493          	addi	s1,s1,166 # 80027870 <log>
    800047d2:	8526                	mv	a0,s1
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	3ee080e7          	jalr	1006(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800047dc:	509c                	lw	a5,32(s1)
    800047de:	37fd                	addiw	a5,a5,-1
    800047e0:	0007891b          	sext.w	s2,a5
    800047e4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047e6:	50dc                	lw	a5,36(s1)
    800047e8:	e7b9                	bnez	a5,80004836 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047ea:	04091e63          	bnez	s2,80004846 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800047ee:	00023497          	auipc	s1,0x23
    800047f2:	08248493          	addi	s1,s1,130 # 80027870 <log>
    800047f6:	4785                	li	a5,1
    800047f8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047fa:	8526                	mv	a0,s1
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	48c080e7          	jalr	1164(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004804:	54dc                	lw	a5,44(s1)
    80004806:	06f04763          	bgtz	a5,80004874 <end_op+0xbc>
    acquire(&log.lock);
    8000480a:	00023497          	auipc	s1,0x23
    8000480e:	06648493          	addi	s1,s1,102 # 80027870 <log>
    80004812:	8526                	mv	a0,s1
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	3ae080e7          	jalr	942(ra) # 80000bc2 <acquire>
    log.committing = 0;
    8000481c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004820:	8526                	mv	a0,s1
    80004822:	ffffe097          	auipc	ra,0xffffe
    80004826:	e18080e7          	jalr	-488(ra) # 8000263a <wakeup>
    release(&log.lock);
    8000482a:	8526                	mv	a0,s1
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	45c080e7          	jalr	1116(ra) # 80000c88 <release>
}
    80004834:	a03d                	j	80004862 <end_op+0xaa>
    panic("log.committing");
    80004836:	00004517          	auipc	a0,0x4
    8000483a:	f4250513          	addi	a0,a0,-190 # 80008778 <syscalls+0x1f8>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	cec080e7          	jalr	-788(ra) # 8000052a <panic>
    wakeup(&log);
    80004846:	00023497          	auipc	s1,0x23
    8000484a:	02a48493          	addi	s1,s1,42 # 80027870 <log>
    8000484e:	8526                	mv	a0,s1
    80004850:	ffffe097          	auipc	ra,0xffffe
    80004854:	dea080e7          	jalr	-534(ra) # 8000263a <wakeup>
  release(&log.lock);
    80004858:	8526                	mv	a0,s1
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	42e080e7          	jalr	1070(ra) # 80000c88 <release>
}
    80004862:	70e2                	ld	ra,56(sp)
    80004864:	7442                	ld	s0,48(sp)
    80004866:	74a2                	ld	s1,40(sp)
    80004868:	7902                	ld	s2,32(sp)
    8000486a:	69e2                	ld	s3,24(sp)
    8000486c:	6a42                	ld	s4,16(sp)
    8000486e:	6aa2                	ld	s5,8(sp)
    80004870:	6121                	addi	sp,sp,64
    80004872:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004874:	00023a97          	auipc	s5,0x23
    80004878:	02ca8a93          	addi	s5,s5,44 # 800278a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000487c:	00023a17          	auipc	s4,0x23
    80004880:	ff4a0a13          	addi	s4,s4,-12 # 80027870 <log>
    80004884:	018a2583          	lw	a1,24(s4)
    80004888:	012585bb          	addw	a1,a1,s2
    8000488c:	2585                	addiw	a1,a1,1
    8000488e:	028a2503          	lw	a0,40(s4)
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	ccc080e7          	jalr	-820(ra) # 8000355e <bread>
    8000489a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000489c:	000aa583          	lw	a1,0(s5)
    800048a0:	028a2503          	lw	a0,40(s4)
    800048a4:	fffff097          	auipc	ra,0xfffff
    800048a8:	cba080e7          	jalr	-838(ra) # 8000355e <bread>
    800048ac:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048ae:	40000613          	li	a2,1024
    800048b2:	05850593          	addi	a1,a0,88
    800048b6:	05848513          	addi	a0,s1,88
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	484080e7          	jalr	1156(ra) # 80000d3e <memmove>
    bwrite(to);  // write the log
    800048c2:	8526                	mv	a0,s1
    800048c4:	fffff097          	auipc	ra,0xfffff
    800048c8:	d8c080e7          	jalr	-628(ra) # 80003650 <bwrite>
    brelse(from);
    800048cc:	854e                	mv	a0,s3
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	dc0080e7          	jalr	-576(ra) # 8000368e <brelse>
    brelse(to);
    800048d6:	8526                	mv	a0,s1
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	db6080e7          	jalr	-586(ra) # 8000368e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048e0:	2905                	addiw	s2,s2,1
    800048e2:	0a91                	addi	s5,s5,4
    800048e4:	02ca2783          	lw	a5,44(s4)
    800048e8:	f8f94ee3          	blt	s2,a5,80004884 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	c66080e7          	jalr	-922(ra) # 80004552 <write_head>
    install_trans(0); // Now install writes to home locations
    800048f4:	4501                	li	a0,0
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	cd8080e7          	jalr	-808(ra) # 800045ce <install_trans>
    log.lh.n = 0;
    800048fe:	00023797          	auipc	a5,0x23
    80004902:	f807af23          	sw	zero,-98(a5) # 8002789c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004906:	00000097          	auipc	ra,0x0
    8000490a:	c4c080e7          	jalr	-948(ra) # 80004552 <write_head>
    8000490e:	bdf5                	j	8000480a <end_op+0x52>

0000000080004910 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004910:	1101                	addi	sp,sp,-32
    80004912:	ec06                	sd	ra,24(sp)
    80004914:	e822                	sd	s0,16(sp)
    80004916:	e426                	sd	s1,8(sp)
    80004918:	e04a                	sd	s2,0(sp)
    8000491a:	1000                	addi	s0,sp,32
    8000491c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000491e:	00023917          	auipc	s2,0x23
    80004922:	f5290913          	addi	s2,s2,-174 # 80027870 <log>
    80004926:	854a                	mv	a0,s2
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	29a080e7          	jalr	666(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004930:	02c92603          	lw	a2,44(s2)
    80004934:	47f5                	li	a5,29
    80004936:	06c7c563          	blt	a5,a2,800049a0 <log_write+0x90>
    8000493a:	00023797          	auipc	a5,0x23
    8000493e:	f527a783          	lw	a5,-174(a5) # 8002788c <log+0x1c>
    80004942:	37fd                	addiw	a5,a5,-1
    80004944:	04f65e63          	bge	a2,a5,800049a0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004948:	00023797          	auipc	a5,0x23
    8000494c:	f487a783          	lw	a5,-184(a5) # 80027890 <log+0x20>
    80004950:	06f05063          	blez	a5,800049b0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004954:	4781                	li	a5,0
    80004956:	06c05563          	blez	a2,800049c0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000495a:	44cc                	lw	a1,12(s1)
    8000495c:	00023717          	auipc	a4,0x23
    80004960:	f4470713          	addi	a4,a4,-188 # 800278a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004964:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004966:	4314                	lw	a3,0(a4)
    80004968:	04b68c63          	beq	a3,a1,800049c0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000496c:	2785                	addiw	a5,a5,1
    8000496e:	0711                	addi	a4,a4,4
    80004970:	fef61be3          	bne	a2,a5,80004966 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004974:	0621                	addi	a2,a2,8
    80004976:	060a                	slli	a2,a2,0x2
    80004978:	00023797          	auipc	a5,0x23
    8000497c:	ef878793          	addi	a5,a5,-264 # 80027870 <log>
    80004980:	963e                	add	a2,a2,a5
    80004982:	44dc                	lw	a5,12(s1)
    80004984:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004986:	8526                	mv	a0,s1
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	da4080e7          	jalr	-604(ra) # 8000372c <bpin>
    log.lh.n++;
    80004990:	00023717          	auipc	a4,0x23
    80004994:	ee070713          	addi	a4,a4,-288 # 80027870 <log>
    80004998:	575c                	lw	a5,44(a4)
    8000499a:	2785                	addiw	a5,a5,1
    8000499c:	d75c                	sw	a5,44(a4)
    8000499e:	a835                	j	800049da <log_write+0xca>
    panic("too big a transaction");
    800049a0:	00004517          	auipc	a0,0x4
    800049a4:	de850513          	addi	a0,a0,-536 # 80008788 <syscalls+0x208>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	b82080e7          	jalr	-1150(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800049b0:	00004517          	auipc	a0,0x4
    800049b4:	df050513          	addi	a0,a0,-528 # 800087a0 <syscalls+0x220>
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	b72080e7          	jalr	-1166(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800049c0:	00878713          	addi	a4,a5,8
    800049c4:	00271693          	slli	a3,a4,0x2
    800049c8:	00023717          	auipc	a4,0x23
    800049cc:	ea870713          	addi	a4,a4,-344 # 80027870 <log>
    800049d0:	9736                	add	a4,a4,a3
    800049d2:	44d4                	lw	a3,12(s1)
    800049d4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049d6:	faf608e3          	beq	a2,a5,80004986 <log_write+0x76>
  }
  release(&log.lock);
    800049da:	00023517          	auipc	a0,0x23
    800049de:	e9650513          	addi	a0,a0,-362 # 80027870 <log>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	2a6080e7          	jalr	678(ra) # 80000c88 <release>
}
    800049ea:	60e2                	ld	ra,24(sp)
    800049ec:	6442                	ld	s0,16(sp)
    800049ee:	64a2                	ld	s1,8(sp)
    800049f0:	6902                	ld	s2,0(sp)
    800049f2:	6105                	addi	sp,sp,32
    800049f4:	8082                	ret

00000000800049f6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049f6:	1101                	addi	sp,sp,-32
    800049f8:	ec06                	sd	ra,24(sp)
    800049fa:	e822                	sd	s0,16(sp)
    800049fc:	e426                	sd	s1,8(sp)
    800049fe:	e04a                	sd	s2,0(sp)
    80004a00:	1000                	addi	s0,sp,32
    80004a02:	84aa                	mv	s1,a0
    80004a04:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a06:	00004597          	auipc	a1,0x4
    80004a0a:	dba58593          	addi	a1,a1,-582 # 800087c0 <syscalls+0x240>
    80004a0e:	0521                	addi	a0,a0,8
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	122080e7          	jalr	290(ra) # 80000b32 <initlock>
  lk->name = name;
    80004a18:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a1c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a20:	0204a423          	sw	zero,40(s1)
}
    80004a24:	60e2                	ld	ra,24(sp)
    80004a26:	6442                	ld	s0,16(sp)
    80004a28:	64a2                	ld	s1,8(sp)
    80004a2a:	6902                	ld	s2,0(sp)
    80004a2c:	6105                	addi	sp,sp,32
    80004a2e:	8082                	ret

0000000080004a30 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a30:	1101                	addi	sp,sp,-32
    80004a32:	ec06                	sd	ra,24(sp)
    80004a34:	e822                	sd	s0,16(sp)
    80004a36:	e426                	sd	s1,8(sp)
    80004a38:	e04a                	sd	s2,0(sp)
    80004a3a:	1000                	addi	s0,sp,32
    80004a3c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a3e:	00850913          	addi	s2,a0,8
    80004a42:	854a                	mv	a0,s2
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	17e080e7          	jalr	382(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004a4c:	409c                	lw	a5,0(s1)
    80004a4e:	cb89                	beqz	a5,80004a60 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a50:	85ca                	mv	a1,s2
    80004a52:	8526                	mv	a0,s1
    80004a54:	ffffe097          	auipc	ra,0xffffe
    80004a58:	a58080e7          	jalr	-1448(ra) # 800024ac <sleep>
  while (lk->locked) {
    80004a5c:	409c                	lw	a5,0(s1)
    80004a5e:	fbed                	bnez	a5,80004a50 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a60:	4785                	li	a5,1
    80004a62:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a64:	ffffd097          	auipc	ra,0xffffd
    80004a68:	f50080e7          	jalr	-176(ra) # 800019b4 <myproc>
    80004a6c:	591c                	lw	a5,48(a0)
    80004a6e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a70:	854a                	mv	a0,s2
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	216080e7          	jalr	534(ra) # 80000c88 <release>
}
    80004a7a:	60e2                	ld	ra,24(sp)
    80004a7c:	6442                	ld	s0,16(sp)
    80004a7e:	64a2                	ld	s1,8(sp)
    80004a80:	6902                	ld	s2,0(sp)
    80004a82:	6105                	addi	sp,sp,32
    80004a84:	8082                	ret

0000000080004a86 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a86:	1101                	addi	sp,sp,-32
    80004a88:	ec06                	sd	ra,24(sp)
    80004a8a:	e822                	sd	s0,16(sp)
    80004a8c:	e426                	sd	s1,8(sp)
    80004a8e:	e04a                	sd	s2,0(sp)
    80004a90:	1000                	addi	s0,sp,32
    80004a92:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a94:	00850913          	addi	s2,a0,8
    80004a98:	854a                	mv	a0,s2
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	128080e7          	jalr	296(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004aa2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aa6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffe097          	auipc	ra,0xffffe
    80004ab0:	b8e080e7          	jalr	-1138(ra) # 8000263a <wakeup>
  release(&lk->lk);
    80004ab4:	854a                	mv	a0,s2
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	1d2080e7          	jalr	466(ra) # 80000c88 <release>
}
    80004abe:	60e2                	ld	ra,24(sp)
    80004ac0:	6442                	ld	s0,16(sp)
    80004ac2:	64a2                	ld	s1,8(sp)
    80004ac4:	6902                	ld	s2,0(sp)
    80004ac6:	6105                	addi	sp,sp,32
    80004ac8:	8082                	ret

0000000080004aca <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004aca:	7179                	addi	sp,sp,-48
    80004acc:	f406                	sd	ra,40(sp)
    80004ace:	f022                	sd	s0,32(sp)
    80004ad0:	ec26                	sd	s1,24(sp)
    80004ad2:	e84a                	sd	s2,16(sp)
    80004ad4:	e44e                	sd	s3,8(sp)
    80004ad6:	1800                	addi	s0,sp,48
    80004ad8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ada:	00850913          	addi	s2,a0,8
    80004ade:	854a                	mv	a0,s2
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	0e2080e7          	jalr	226(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ae8:	409c                	lw	a5,0(s1)
    80004aea:	ef99                	bnez	a5,80004b08 <holdingsleep+0x3e>
    80004aec:	4481                	li	s1,0
  release(&lk->lk);
    80004aee:	854a                	mv	a0,s2
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	198080e7          	jalr	408(ra) # 80000c88 <release>
  return r;
}
    80004af8:	8526                	mv	a0,s1
    80004afa:	70a2                	ld	ra,40(sp)
    80004afc:	7402                	ld	s0,32(sp)
    80004afe:	64e2                	ld	s1,24(sp)
    80004b00:	6942                	ld	s2,16(sp)
    80004b02:	69a2                	ld	s3,8(sp)
    80004b04:	6145                	addi	sp,sp,48
    80004b06:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b08:	0284a983          	lw	s3,40(s1)
    80004b0c:	ffffd097          	auipc	ra,0xffffd
    80004b10:	ea8080e7          	jalr	-344(ra) # 800019b4 <myproc>
    80004b14:	5904                	lw	s1,48(a0)
    80004b16:	413484b3          	sub	s1,s1,s3
    80004b1a:	0014b493          	seqz	s1,s1
    80004b1e:	bfc1                	j	80004aee <holdingsleep+0x24>

0000000080004b20 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b20:	1141                	addi	sp,sp,-16
    80004b22:	e406                	sd	ra,8(sp)
    80004b24:	e022                	sd	s0,0(sp)
    80004b26:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b28:	00004597          	auipc	a1,0x4
    80004b2c:	ca858593          	addi	a1,a1,-856 # 800087d0 <syscalls+0x250>
    80004b30:	00023517          	auipc	a0,0x23
    80004b34:	e8850513          	addi	a0,a0,-376 # 800279b8 <ftable>
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	ffa080e7          	jalr	-6(ra) # 80000b32 <initlock>
}
    80004b40:	60a2                	ld	ra,8(sp)
    80004b42:	6402                	ld	s0,0(sp)
    80004b44:	0141                	addi	sp,sp,16
    80004b46:	8082                	ret

0000000080004b48 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b48:	1101                	addi	sp,sp,-32
    80004b4a:	ec06                	sd	ra,24(sp)
    80004b4c:	e822                	sd	s0,16(sp)
    80004b4e:	e426                	sd	s1,8(sp)
    80004b50:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b52:	00023517          	auipc	a0,0x23
    80004b56:	e6650513          	addi	a0,a0,-410 # 800279b8 <ftable>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	068080e7          	jalr	104(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b62:	00023497          	auipc	s1,0x23
    80004b66:	e6e48493          	addi	s1,s1,-402 # 800279d0 <ftable+0x18>
    80004b6a:	00024717          	auipc	a4,0x24
    80004b6e:	e0670713          	addi	a4,a4,-506 # 80028970 <ftable+0xfb8>
    if(f->ref == 0){
    80004b72:	40dc                	lw	a5,4(s1)
    80004b74:	cf99                	beqz	a5,80004b92 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b76:	02848493          	addi	s1,s1,40
    80004b7a:	fee49ce3          	bne	s1,a4,80004b72 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b7e:	00023517          	auipc	a0,0x23
    80004b82:	e3a50513          	addi	a0,a0,-454 # 800279b8 <ftable>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	102080e7          	jalr	258(ra) # 80000c88 <release>
  return 0;
    80004b8e:	4481                	li	s1,0
    80004b90:	a819                	j	80004ba6 <filealloc+0x5e>
      f->ref = 1;
    80004b92:	4785                	li	a5,1
    80004b94:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b96:	00023517          	auipc	a0,0x23
    80004b9a:	e2250513          	addi	a0,a0,-478 # 800279b8 <ftable>
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	0ea080e7          	jalr	234(ra) # 80000c88 <release>
}
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	60e2                	ld	ra,24(sp)
    80004baa:	6442                	ld	s0,16(sp)
    80004bac:	64a2                	ld	s1,8(sp)
    80004bae:	6105                	addi	sp,sp,32
    80004bb0:	8082                	ret

0000000080004bb2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bb2:	1101                	addi	sp,sp,-32
    80004bb4:	ec06                	sd	ra,24(sp)
    80004bb6:	e822                	sd	s0,16(sp)
    80004bb8:	e426                	sd	s1,8(sp)
    80004bba:	1000                	addi	s0,sp,32
    80004bbc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004bbe:	00023517          	auipc	a0,0x23
    80004bc2:	dfa50513          	addi	a0,a0,-518 # 800279b8 <ftable>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	ffc080e7          	jalr	-4(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004bce:	40dc                	lw	a5,4(s1)
    80004bd0:	02f05263          	blez	a5,80004bf4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bd4:	2785                	addiw	a5,a5,1
    80004bd6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bd8:	00023517          	auipc	a0,0x23
    80004bdc:	de050513          	addi	a0,a0,-544 # 800279b8 <ftable>
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	0a8080e7          	jalr	168(ra) # 80000c88 <release>
  return f;
}
    80004be8:	8526                	mv	a0,s1
    80004bea:	60e2                	ld	ra,24(sp)
    80004bec:	6442                	ld	s0,16(sp)
    80004bee:	64a2                	ld	s1,8(sp)
    80004bf0:	6105                	addi	sp,sp,32
    80004bf2:	8082                	ret
    panic("filedup");
    80004bf4:	00004517          	auipc	a0,0x4
    80004bf8:	be450513          	addi	a0,a0,-1052 # 800087d8 <syscalls+0x258>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	92e080e7          	jalr	-1746(ra) # 8000052a <panic>

0000000080004c04 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c04:	7139                	addi	sp,sp,-64
    80004c06:	fc06                	sd	ra,56(sp)
    80004c08:	f822                	sd	s0,48(sp)
    80004c0a:	f426                	sd	s1,40(sp)
    80004c0c:	f04a                	sd	s2,32(sp)
    80004c0e:	ec4e                	sd	s3,24(sp)
    80004c10:	e852                	sd	s4,16(sp)
    80004c12:	e456                	sd	s5,8(sp)
    80004c14:	0080                	addi	s0,sp,64
    80004c16:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c18:	00023517          	auipc	a0,0x23
    80004c1c:	da050513          	addi	a0,a0,-608 # 800279b8 <ftable>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	fa2080e7          	jalr	-94(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004c28:	40dc                	lw	a5,4(s1)
    80004c2a:	06f05163          	blez	a5,80004c8c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c2e:	37fd                	addiw	a5,a5,-1
    80004c30:	0007871b          	sext.w	a4,a5
    80004c34:	c0dc                	sw	a5,4(s1)
    80004c36:	06e04363          	bgtz	a4,80004c9c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c3a:	0004a903          	lw	s2,0(s1)
    80004c3e:	0094ca83          	lbu	s5,9(s1)
    80004c42:	0104ba03          	ld	s4,16(s1)
    80004c46:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c4a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c4e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c52:	00023517          	auipc	a0,0x23
    80004c56:	d6650513          	addi	a0,a0,-666 # 800279b8 <ftable>
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	02e080e7          	jalr	46(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    80004c62:	4785                	li	a5,1
    80004c64:	04f90d63          	beq	s2,a5,80004cbe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c68:	3979                	addiw	s2,s2,-2
    80004c6a:	4785                	li	a5,1
    80004c6c:	0527e063          	bltu	a5,s2,80004cac <fileclose+0xa8>
    begin_op();
    80004c70:	00000097          	auipc	ra,0x0
    80004c74:	ac8080e7          	jalr	-1336(ra) # 80004738 <begin_op>
    iput(ff.ip);
    80004c78:	854e                	mv	a0,s3
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	2a2080e7          	jalr	674(ra) # 80003f1c <iput>
    end_op();
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	b36080e7          	jalr	-1226(ra) # 800047b8 <end_op>
    80004c8a:	a00d                	j	80004cac <fileclose+0xa8>
    panic("fileclose");
    80004c8c:	00004517          	auipc	a0,0x4
    80004c90:	b5450513          	addi	a0,a0,-1196 # 800087e0 <syscalls+0x260>
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	896080e7          	jalr	-1898(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004c9c:	00023517          	auipc	a0,0x23
    80004ca0:	d1c50513          	addi	a0,a0,-740 # 800279b8 <ftable>
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	fe4080e7          	jalr	-28(ra) # 80000c88 <release>
  }
}
    80004cac:	70e2                	ld	ra,56(sp)
    80004cae:	7442                	ld	s0,48(sp)
    80004cb0:	74a2                	ld	s1,40(sp)
    80004cb2:	7902                	ld	s2,32(sp)
    80004cb4:	69e2                	ld	s3,24(sp)
    80004cb6:	6a42                	ld	s4,16(sp)
    80004cb8:	6aa2                	ld	s5,8(sp)
    80004cba:	6121                	addi	sp,sp,64
    80004cbc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004cbe:	85d6                	mv	a1,s5
    80004cc0:	8552                	mv	a0,s4
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	34c080e7          	jalr	844(ra) # 8000500e <pipeclose>
    80004cca:	b7cd                	j	80004cac <fileclose+0xa8>

0000000080004ccc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ccc:	715d                	addi	sp,sp,-80
    80004cce:	e486                	sd	ra,72(sp)
    80004cd0:	e0a2                	sd	s0,64(sp)
    80004cd2:	fc26                	sd	s1,56(sp)
    80004cd4:	f84a                	sd	s2,48(sp)
    80004cd6:	f44e                	sd	s3,40(sp)
    80004cd8:	0880                	addi	s0,sp,80
    80004cda:	84aa                	mv	s1,a0
    80004cdc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	cd6080e7          	jalr	-810(ra) # 800019b4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ce6:	409c                	lw	a5,0(s1)
    80004ce8:	37f9                	addiw	a5,a5,-2
    80004cea:	4705                	li	a4,1
    80004cec:	04f76763          	bltu	a4,a5,80004d3a <filestat+0x6e>
    80004cf0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cf2:	6c88                	ld	a0,24(s1)
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	06e080e7          	jalr	110(ra) # 80003d62 <ilock>
    stati(f->ip, &st);
    80004cfc:	fb840593          	addi	a1,s0,-72
    80004d00:	6c88                	ld	a0,24(s1)
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	2ea080e7          	jalr	746(ra) # 80003fec <stati>
    iunlock(f->ip);
    80004d0a:	6c88                	ld	a0,24(s1)
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	118080e7          	jalr	280(ra) # 80003e24 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d14:	46e1                	li	a3,24
    80004d16:	fb840613          	addi	a2,s0,-72
    80004d1a:	85ce                	mv	a1,s3
    80004d1c:	1e893503          	ld	a0,488(s2)
    80004d20:	ffffd097          	auipc	ra,0xffffd
    80004d24:	952080e7          	jalr	-1710(ra) # 80001672 <copyout>
    80004d28:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d2c:	60a6                	ld	ra,72(sp)
    80004d2e:	6406                	ld	s0,64(sp)
    80004d30:	74e2                	ld	s1,56(sp)
    80004d32:	7942                	ld	s2,48(sp)
    80004d34:	79a2                	ld	s3,40(sp)
    80004d36:	6161                	addi	sp,sp,80
    80004d38:	8082                	ret
  return -1;
    80004d3a:	557d                	li	a0,-1
    80004d3c:	bfc5                	j	80004d2c <filestat+0x60>

0000000080004d3e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d3e:	7179                	addi	sp,sp,-48
    80004d40:	f406                	sd	ra,40(sp)
    80004d42:	f022                	sd	s0,32(sp)
    80004d44:	ec26                	sd	s1,24(sp)
    80004d46:	e84a                	sd	s2,16(sp)
    80004d48:	e44e                	sd	s3,8(sp)
    80004d4a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d4c:	00854783          	lbu	a5,8(a0)
    80004d50:	c3d5                	beqz	a5,80004df4 <fileread+0xb6>
    80004d52:	84aa                	mv	s1,a0
    80004d54:	89ae                	mv	s3,a1
    80004d56:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d58:	411c                	lw	a5,0(a0)
    80004d5a:	4705                	li	a4,1
    80004d5c:	04e78963          	beq	a5,a4,80004dae <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d60:	470d                	li	a4,3
    80004d62:	04e78d63          	beq	a5,a4,80004dbc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d66:	4709                	li	a4,2
    80004d68:	06e79e63          	bne	a5,a4,80004de4 <fileread+0xa6>
    ilock(f->ip);
    80004d6c:	6d08                	ld	a0,24(a0)
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	ff4080e7          	jalr	-12(ra) # 80003d62 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d76:	874a                	mv	a4,s2
    80004d78:	5094                	lw	a3,32(s1)
    80004d7a:	864e                	mv	a2,s3
    80004d7c:	4585                	li	a1,1
    80004d7e:	6c88                	ld	a0,24(s1)
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	296080e7          	jalr	662(ra) # 80004016 <readi>
    80004d88:	892a                	mv	s2,a0
    80004d8a:	00a05563          	blez	a0,80004d94 <fileread+0x56>
      f->off += r;
    80004d8e:	509c                	lw	a5,32(s1)
    80004d90:	9fa9                	addw	a5,a5,a0
    80004d92:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d94:	6c88                	ld	a0,24(s1)
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	08e080e7          	jalr	142(ra) # 80003e24 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d9e:	854a                	mv	a0,s2
    80004da0:	70a2                	ld	ra,40(sp)
    80004da2:	7402                	ld	s0,32(sp)
    80004da4:	64e2                	ld	s1,24(sp)
    80004da6:	6942                	ld	s2,16(sp)
    80004da8:	69a2                	ld	s3,8(sp)
    80004daa:	6145                	addi	sp,sp,48
    80004dac:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dae:	6908                	ld	a0,16(a0)
    80004db0:	00000097          	auipc	ra,0x0
    80004db4:	3c0080e7          	jalr	960(ra) # 80005170 <piperead>
    80004db8:	892a                	mv	s2,a0
    80004dba:	b7d5                	j	80004d9e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004dbc:	02451783          	lh	a5,36(a0)
    80004dc0:	03079693          	slli	a3,a5,0x30
    80004dc4:	92c1                	srli	a3,a3,0x30
    80004dc6:	4725                	li	a4,9
    80004dc8:	02d76863          	bltu	a4,a3,80004df8 <fileread+0xba>
    80004dcc:	0792                	slli	a5,a5,0x4
    80004dce:	00023717          	auipc	a4,0x23
    80004dd2:	b4a70713          	addi	a4,a4,-1206 # 80027918 <devsw>
    80004dd6:	97ba                	add	a5,a5,a4
    80004dd8:	639c                	ld	a5,0(a5)
    80004dda:	c38d                	beqz	a5,80004dfc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ddc:	4505                	li	a0,1
    80004dde:	9782                	jalr	a5
    80004de0:	892a                	mv	s2,a0
    80004de2:	bf75                	j	80004d9e <fileread+0x60>
    panic("fileread");
    80004de4:	00004517          	auipc	a0,0x4
    80004de8:	a0c50513          	addi	a0,a0,-1524 # 800087f0 <syscalls+0x270>
    80004dec:	ffffb097          	auipc	ra,0xffffb
    80004df0:	73e080e7          	jalr	1854(ra) # 8000052a <panic>
    return -1;
    80004df4:	597d                	li	s2,-1
    80004df6:	b765                	j	80004d9e <fileread+0x60>
      return -1;
    80004df8:	597d                	li	s2,-1
    80004dfa:	b755                	j	80004d9e <fileread+0x60>
    80004dfc:	597d                	li	s2,-1
    80004dfe:	b745                	j	80004d9e <fileread+0x60>

0000000080004e00 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e00:	715d                	addi	sp,sp,-80
    80004e02:	e486                	sd	ra,72(sp)
    80004e04:	e0a2                	sd	s0,64(sp)
    80004e06:	fc26                	sd	s1,56(sp)
    80004e08:	f84a                	sd	s2,48(sp)
    80004e0a:	f44e                	sd	s3,40(sp)
    80004e0c:	f052                	sd	s4,32(sp)
    80004e0e:	ec56                	sd	s5,24(sp)
    80004e10:	e85a                	sd	s6,16(sp)
    80004e12:	e45e                	sd	s7,8(sp)
    80004e14:	e062                	sd	s8,0(sp)
    80004e16:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e18:	00954783          	lbu	a5,9(a0)
    80004e1c:	10078663          	beqz	a5,80004f28 <filewrite+0x128>
    80004e20:	892a                	mv	s2,a0
    80004e22:	8aae                	mv	s5,a1
    80004e24:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e26:	411c                	lw	a5,0(a0)
    80004e28:	4705                	li	a4,1
    80004e2a:	02e78263          	beq	a5,a4,80004e4e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e2e:	470d                	li	a4,3
    80004e30:	02e78663          	beq	a5,a4,80004e5c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e34:	4709                	li	a4,2
    80004e36:	0ee79163          	bne	a5,a4,80004f18 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e3a:	0ac05d63          	blez	a2,80004ef4 <filewrite+0xf4>
    int i = 0;
    80004e3e:	4981                	li	s3,0
    80004e40:	6b05                	lui	s6,0x1
    80004e42:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e46:	6b85                	lui	s7,0x1
    80004e48:	c00b8b9b          	addiw	s7,s7,-1024
    80004e4c:	a861                	j	80004ee4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e4e:	6908                	ld	a0,16(a0)
    80004e50:	00000097          	auipc	ra,0x0
    80004e54:	22e080e7          	jalr	558(ra) # 8000507e <pipewrite>
    80004e58:	8a2a                	mv	s4,a0
    80004e5a:	a045                	j	80004efa <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e5c:	02451783          	lh	a5,36(a0)
    80004e60:	03079693          	slli	a3,a5,0x30
    80004e64:	92c1                	srli	a3,a3,0x30
    80004e66:	4725                	li	a4,9
    80004e68:	0cd76263          	bltu	a4,a3,80004f2c <filewrite+0x12c>
    80004e6c:	0792                	slli	a5,a5,0x4
    80004e6e:	00023717          	auipc	a4,0x23
    80004e72:	aaa70713          	addi	a4,a4,-1366 # 80027918 <devsw>
    80004e76:	97ba                	add	a5,a5,a4
    80004e78:	679c                	ld	a5,8(a5)
    80004e7a:	cbdd                	beqz	a5,80004f30 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e7c:	4505                	li	a0,1
    80004e7e:	9782                	jalr	a5
    80004e80:	8a2a                	mv	s4,a0
    80004e82:	a8a5                	j	80004efa <filewrite+0xfa>
    80004e84:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e88:	00000097          	auipc	ra,0x0
    80004e8c:	8b0080e7          	jalr	-1872(ra) # 80004738 <begin_op>
      ilock(f->ip);
    80004e90:	01893503          	ld	a0,24(s2)
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	ece080e7          	jalr	-306(ra) # 80003d62 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e9c:	8762                	mv	a4,s8
    80004e9e:	02092683          	lw	a3,32(s2)
    80004ea2:	01598633          	add	a2,s3,s5
    80004ea6:	4585                	li	a1,1
    80004ea8:	01893503          	ld	a0,24(s2)
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	262080e7          	jalr	610(ra) # 8000410e <writei>
    80004eb4:	84aa                	mv	s1,a0
    80004eb6:	00a05763          	blez	a0,80004ec4 <filewrite+0xc4>
        f->off += r;
    80004eba:	02092783          	lw	a5,32(s2)
    80004ebe:	9fa9                	addw	a5,a5,a0
    80004ec0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ec4:	01893503          	ld	a0,24(s2)
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	f5c080e7          	jalr	-164(ra) # 80003e24 <iunlock>
      end_op();
    80004ed0:	00000097          	auipc	ra,0x0
    80004ed4:	8e8080e7          	jalr	-1816(ra) # 800047b8 <end_op>

      if(r != n1){
    80004ed8:	009c1f63          	bne	s8,s1,80004ef6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004edc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ee0:	0149db63          	bge	s3,s4,80004ef6 <filewrite+0xf6>
      int n1 = n - i;
    80004ee4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ee8:	84be                	mv	s1,a5
    80004eea:	2781                	sext.w	a5,a5
    80004eec:	f8fb5ce3          	bge	s6,a5,80004e84 <filewrite+0x84>
    80004ef0:	84de                	mv	s1,s7
    80004ef2:	bf49                	j	80004e84 <filewrite+0x84>
    int i = 0;
    80004ef4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ef6:	013a1f63          	bne	s4,s3,80004f14 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004efa:	8552                	mv	a0,s4
    80004efc:	60a6                	ld	ra,72(sp)
    80004efe:	6406                	ld	s0,64(sp)
    80004f00:	74e2                	ld	s1,56(sp)
    80004f02:	7942                	ld	s2,48(sp)
    80004f04:	79a2                	ld	s3,40(sp)
    80004f06:	7a02                	ld	s4,32(sp)
    80004f08:	6ae2                	ld	s5,24(sp)
    80004f0a:	6b42                	ld	s6,16(sp)
    80004f0c:	6ba2                	ld	s7,8(sp)
    80004f0e:	6c02                	ld	s8,0(sp)
    80004f10:	6161                	addi	sp,sp,80
    80004f12:	8082                	ret
    ret = (i == n ? n : -1);
    80004f14:	5a7d                	li	s4,-1
    80004f16:	b7d5                	j	80004efa <filewrite+0xfa>
    panic("filewrite");
    80004f18:	00004517          	auipc	a0,0x4
    80004f1c:	8e850513          	addi	a0,a0,-1816 # 80008800 <syscalls+0x280>
    80004f20:	ffffb097          	auipc	ra,0xffffb
    80004f24:	60a080e7          	jalr	1546(ra) # 8000052a <panic>
    return -1;
    80004f28:	5a7d                	li	s4,-1
    80004f2a:	bfc1                	j	80004efa <filewrite+0xfa>
      return -1;
    80004f2c:	5a7d                	li	s4,-1
    80004f2e:	b7f1                	j	80004efa <filewrite+0xfa>
    80004f30:	5a7d                	li	s4,-1
    80004f32:	b7e1                	j	80004efa <filewrite+0xfa>

0000000080004f34 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f34:	7179                	addi	sp,sp,-48
    80004f36:	f406                	sd	ra,40(sp)
    80004f38:	f022                	sd	s0,32(sp)
    80004f3a:	ec26                	sd	s1,24(sp)
    80004f3c:	e84a                	sd	s2,16(sp)
    80004f3e:	e44e                	sd	s3,8(sp)
    80004f40:	e052                	sd	s4,0(sp)
    80004f42:	1800                	addi	s0,sp,48
    80004f44:	84aa                	mv	s1,a0
    80004f46:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f48:	0005b023          	sd	zero,0(a1)
    80004f4c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f50:	00000097          	auipc	ra,0x0
    80004f54:	bf8080e7          	jalr	-1032(ra) # 80004b48 <filealloc>
    80004f58:	e088                	sd	a0,0(s1)
    80004f5a:	c551                	beqz	a0,80004fe6 <pipealloc+0xb2>
    80004f5c:	00000097          	auipc	ra,0x0
    80004f60:	bec080e7          	jalr	-1044(ra) # 80004b48 <filealloc>
    80004f64:	00aa3023          	sd	a0,0(s4)
    80004f68:	c92d                	beqz	a0,80004fda <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	b68080e7          	jalr	-1176(ra) # 80000ad2 <kalloc>
    80004f72:	892a                	mv	s2,a0
    80004f74:	c125                	beqz	a0,80004fd4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f76:	4985                	li	s3,1
    80004f78:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f7c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f80:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f84:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f88:	00004597          	auipc	a1,0x4
    80004f8c:	88858593          	addi	a1,a1,-1912 # 80008810 <syscalls+0x290>
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	ba2080e7          	jalr	-1118(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004f98:	609c                	ld	a5,0(s1)
    80004f9a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f9e:	609c                	ld	a5,0(s1)
    80004fa0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fa4:	609c                	ld	a5,0(s1)
    80004fa6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004faa:	609c                	ld	a5,0(s1)
    80004fac:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004fb0:	000a3783          	ld	a5,0(s4)
    80004fb4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004fb8:	000a3783          	ld	a5,0(s4)
    80004fbc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004fc0:	000a3783          	ld	a5,0(s4)
    80004fc4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fc8:	000a3783          	ld	a5,0(s4)
    80004fcc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fd0:	4501                	li	a0,0
    80004fd2:	a025                	j	80004ffa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fd4:	6088                	ld	a0,0(s1)
    80004fd6:	e501                	bnez	a0,80004fde <pipealloc+0xaa>
    80004fd8:	a039                	j	80004fe6 <pipealloc+0xb2>
    80004fda:	6088                	ld	a0,0(s1)
    80004fdc:	c51d                	beqz	a0,8000500a <pipealloc+0xd6>
    fileclose(*f0);
    80004fde:	00000097          	auipc	ra,0x0
    80004fe2:	c26080e7          	jalr	-986(ra) # 80004c04 <fileclose>
  if(*f1)
    80004fe6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fea:	557d                	li	a0,-1
  if(*f1)
    80004fec:	c799                	beqz	a5,80004ffa <pipealloc+0xc6>
    fileclose(*f1);
    80004fee:	853e                	mv	a0,a5
    80004ff0:	00000097          	auipc	ra,0x0
    80004ff4:	c14080e7          	jalr	-1004(ra) # 80004c04 <fileclose>
  return -1;
    80004ff8:	557d                	li	a0,-1
}
    80004ffa:	70a2                	ld	ra,40(sp)
    80004ffc:	7402                	ld	s0,32(sp)
    80004ffe:	64e2                	ld	s1,24(sp)
    80005000:	6942                	ld	s2,16(sp)
    80005002:	69a2                	ld	s3,8(sp)
    80005004:	6a02                	ld	s4,0(sp)
    80005006:	6145                	addi	sp,sp,48
    80005008:	8082                	ret
  return -1;
    8000500a:	557d                	li	a0,-1
    8000500c:	b7fd                	j	80004ffa <pipealloc+0xc6>

000000008000500e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000500e:	1101                	addi	sp,sp,-32
    80005010:	ec06                	sd	ra,24(sp)
    80005012:	e822                	sd	s0,16(sp)
    80005014:	e426                	sd	s1,8(sp)
    80005016:	e04a                	sd	s2,0(sp)
    80005018:	1000                	addi	s0,sp,32
    8000501a:	84aa                	mv	s1,a0
    8000501c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	ba4080e7          	jalr	-1116(ra) # 80000bc2 <acquire>
  if(writable){
    80005026:	02090d63          	beqz	s2,80005060 <pipeclose+0x52>
    pi->writeopen = 0;
    8000502a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000502e:	21848513          	addi	a0,s1,536
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	608080e7          	jalr	1544(ra) # 8000263a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000503a:	2204b783          	ld	a5,544(s1)
    8000503e:	eb95                	bnez	a5,80005072 <pipeclose+0x64>
    release(&pi->lock);
    80005040:	8526                	mv	a0,s1
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	c46080e7          	jalr	-954(ra) # 80000c88 <release>
    kfree((char*)pi);
    8000504a:	8526                	mv	a0,s1
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	98a080e7          	jalr	-1654(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005054:	60e2                	ld	ra,24(sp)
    80005056:	6442                	ld	s0,16(sp)
    80005058:	64a2                	ld	s1,8(sp)
    8000505a:	6902                	ld	s2,0(sp)
    8000505c:	6105                	addi	sp,sp,32
    8000505e:	8082                	ret
    pi->readopen = 0;
    80005060:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005064:	21c48513          	addi	a0,s1,540
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	5d2080e7          	jalr	1490(ra) # 8000263a <wakeup>
    80005070:	b7e9                	j	8000503a <pipeclose+0x2c>
    release(&pi->lock);
    80005072:	8526                	mv	a0,s1
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	c14080e7          	jalr	-1004(ra) # 80000c88 <release>
}
    8000507c:	bfe1                	j	80005054 <pipeclose+0x46>

000000008000507e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000507e:	711d                	addi	sp,sp,-96
    80005080:	ec86                	sd	ra,88(sp)
    80005082:	e8a2                	sd	s0,80(sp)
    80005084:	e4a6                	sd	s1,72(sp)
    80005086:	e0ca                	sd	s2,64(sp)
    80005088:	fc4e                	sd	s3,56(sp)
    8000508a:	f852                	sd	s4,48(sp)
    8000508c:	f456                	sd	s5,40(sp)
    8000508e:	f05a                	sd	s6,32(sp)
    80005090:	ec5e                	sd	s7,24(sp)
    80005092:	e862                	sd	s8,16(sp)
    80005094:	1080                	addi	s0,sp,96
    80005096:	84aa                	mv	s1,a0
    80005098:	8aae                	mv	s5,a1
    8000509a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	918080e7          	jalr	-1768(ra) # 800019b4 <myproc>
    800050a4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050a6:	8526                	mv	a0,s1
    800050a8:	ffffc097          	auipc	ra,0xffffc
    800050ac:	b1a080e7          	jalr	-1254(ra) # 80000bc2 <acquire>
  while(i < n){
    800050b0:	0b405363          	blez	s4,80005156 <pipewrite+0xd8>
  int i = 0;
    800050b4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050b6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050b8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050bc:	21c48b93          	addi	s7,s1,540
    800050c0:	a089                	j	80005102 <pipewrite+0x84>
      release(&pi->lock);
    800050c2:	8526                	mv	a0,s1
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	bc4080e7          	jalr	-1084(ra) # 80000c88 <release>
      return -1;
    800050cc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050ce:	854a                	mv	a0,s2
    800050d0:	60e6                	ld	ra,88(sp)
    800050d2:	6446                	ld	s0,80(sp)
    800050d4:	64a6                	ld	s1,72(sp)
    800050d6:	6906                	ld	s2,64(sp)
    800050d8:	79e2                	ld	s3,56(sp)
    800050da:	7a42                	ld	s4,48(sp)
    800050dc:	7aa2                	ld	s5,40(sp)
    800050de:	7b02                	ld	s6,32(sp)
    800050e0:	6be2                	ld	s7,24(sp)
    800050e2:	6c42                	ld	s8,16(sp)
    800050e4:	6125                	addi	sp,sp,96
    800050e6:	8082                	ret
      wakeup(&pi->nread);
    800050e8:	8562                	mv	a0,s8
    800050ea:	ffffd097          	auipc	ra,0xffffd
    800050ee:	550080e7          	jalr	1360(ra) # 8000263a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050f2:	85a6                	mv	a1,s1
    800050f4:	855e                	mv	a0,s7
    800050f6:	ffffd097          	auipc	ra,0xffffd
    800050fa:	3b6080e7          	jalr	950(ra) # 800024ac <sleep>
  while(i < n){
    800050fe:	05495d63          	bge	s2,s4,80005158 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005102:	2204a783          	lw	a5,544(s1)
    80005106:	dfd5                	beqz	a5,800050c2 <pipewrite+0x44>
    80005108:	0289a783          	lw	a5,40(s3)
    8000510c:	fbdd                	bnez	a5,800050c2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000510e:	2184a783          	lw	a5,536(s1)
    80005112:	21c4a703          	lw	a4,540(s1)
    80005116:	2007879b          	addiw	a5,a5,512
    8000511a:	fcf707e3          	beq	a4,a5,800050e8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000511e:	4685                	li	a3,1
    80005120:	01590633          	add	a2,s2,s5
    80005124:	faf40593          	addi	a1,s0,-81
    80005128:	1e89b503          	ld	a0,488(s3)
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	5d2080e7          	jalr	1490(ra) # 800016fe <copyin>
    80005134:	03650263          	beq	a0,s6,80005158 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005138:	21c4a783          	lw	a5,540(s1)
    8000513c:	0017871b          	addiw	a4,a5,1
    80005140:	20e4ae23          	sw	a4,540(s1)
    80005144:	1ff7f793          	andi	a5,a5,511
    80005148:	97a6                	add	a5,a5,s1
    8000514a:	faf44703          	lbu	a4,-81(s0)
    8000514e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005152:	2905                	addiw	s2,s2,1
    80005154:	b76d                	j	800050fe <pipewrite+0x80>
  int i = 0;
    80005156:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005158:	21848513          	addi	a0,s1,536
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	4de080e7          	jalr	1246(ra) # 8000263a <wakeup>
  release(&pi->lock);
    80005164:	8526                	mv	a0,s1
    80005166:	ffffc097          	auipc	ra,0xffffc
    8000516a:	b22080e7          	jalr	-1246(ra) # 80000c88 <release>
  return i;
    8000516e:	b785                	j	800050ce <pipewrite+0x50>

0000000080005170 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005170:	715d                	addi	sp,sp,-80
    80005172:	e486                	sd	ra,72(sp)
    80005174:	e0a2                	sd	s0,64(sp)
    80005176:	fc26                	sd	s1,56(sp)
    80005178:	f84a                	sd	s2,48(sp)
    8000517a:	f44e                	sd	s3,40(sp)
    8000517c:	f052                	sd	s4,32(sp)
    8000517e:	ec56                	sd	s5,24(sp)
    80005180:	e85a                	sd	s6,16(sp)
    80005182:	0880                	addi	s0,sp,80
    80005184:	84aa                	mv	s1,a0
    80005186:	892e                	mv	s2,a1
    80005188:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000518a:	ffffd097          	auipc	ra,0xffffd
    8000518e:	82a080e7          	jalr	-2006(ra) # 800019b4 <myproc>
    80005192:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005194:	8526                	mv	a0,s1
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	a2c080e7          	jalr	-1492(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000519e:	2184a703          	lw	a4,536(s1)
    800051a2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051a6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051aa:	02f71463          	bne	a4,a5,800051d2 <piperead+0x62>
    800051ae:	2244a783          	lw	a5,548(s1)
    800051b2:	c385                	beqz	a5,800051d2 <piperead+0x62>
    if(pr->killed){
    800051b4:	028a2783          	lw	a5,40(s4)
    800051b8:	ebc1                	bnez	a5,80005248 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051ba:	85a6                	mv	a1,s1
    800051bc:	854e                	mv	a0,s3
    800051be:	ffffd097          	auipc	ra,0xffffd
    800051c2:	2ee080e7          	jalr	750(ra) # 800024ac <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051c6:	2184a703          	lw	a4,536(s1)
    800051ca:	21c4a783          	lw	a5,540(s1)
    800051ce:	fef700e3          	beq	a4,a5,800051ae <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051d2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051d4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051d6:	05505363          	blez	s5,8000521c <piperead+0xac>
    if(pi->nread == pi->nwrite)
    800051da:	2184a783          	lw	a5,536(s1)
    800051de:	21c4a703          	lw	a4,540(s1)
    800051e2:	02f70d63          	beq	a4,a5,8000521c <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051e6:	0017871b          	addiw	a4,a5,1
    800051ea:	20e4ac23          	sw	a4,536(s1)
    800051ee:	1ff7f793          	andi	a5,a5,511
    800051f2:	97a6                	add	a5,a5,s1
    800051f4:	0187c783          	lbu	a5,24(a5)
    800051f8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051fc:	4685                	li	a3,1
    800051fe:	fbf40613          	addi	a2,s0,-65
    80005202:	85ca                	mv	a1,s2
    80005204:	1e8a3503          	ld	a0,488(s4)
    80005208:	ffffc097          	auipc	ra,0xffffc
    8000520c:	46a080e7          	jalr	1130(ra) # 80001672 <copyout>
    80005210:	01650663          	beq	a0,s6,8000521c <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005214:	2985                	addiw	s3,s3,1
    80005216:	0905                	addi	s2,s2,1
    80005218:	fd3a91e3          	bne	s5,s3,800051da <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000521c:	21c48513          	addi	a0,s1,540
    80005220:	ffffd097          	auipc	ra,0xffffd
    80005224:	41a080e7          	jalr	1050(ra) # 8000263a <wakeup>
  release(&pi->lock);
    80005228:	8526                	mv	a0,s1
    8000522a:	ffffc097          	auipc	ra,0xffffc
    8000522e:	a5e080e7          	jalr	-1442(ra) # 80000c88 <release>
  return i;
}
    80005232:	854e                	mv	a0,s3
    80005234:	60a6                	ld	ra,72(sp)
    80005236:	6406                	ld	s0,64(sp)
    80005238:	74e2                	ld	s1,56(sp)
    8000523a:	7942                	ld	s2,48(sp)
    8000523c:	79a2                	ld	s3,40(sp)
    8000523e:	7a02                	ld	s4,32(sp)
    80005240:	6ae2                	ld	s5,24(sp)
    80005242:	6b42                	ld	s6,16(sp)
    80005244:	6161                	addi	sp,sp,80
    80005246:	8082                	ret
      release(&pi->lock);
    80005248:	8526                	mv	a0,s1
    8000524a:	ffffc097          	auipc	ra,0xffffc
    8000524e:	a3e080e7          	jalr	-1474(ra) # 80000c88 <release>
      return -1;
    80005252:	59fd                	li	s3,-1
    80005254:	bff9                	j	80005232 <piperead+0xc2>

0000000080005256 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005256:	de010113          	addi	sp,sp,-544
    8000525a:	20113c23          	sd	ra,536(sp)
    8000525e:	20813823          	sd	s0,528(sp)
    80005262:	20913423          	sd	s1,520(sp)
    80005266:	21213023          	sd	s2,512(sp)
    8000526a:	ffce                	sd	s3,504(sp)
    8000526c:	fbd2                	sd	s4,496(sp)
    8000526e:	f7d6                	sd	s5,488(sp)
    80005270:	f3da                	sd	s6,480(sp)
    80005272:	efde                	sd	s7,472(sp)
    80005274:	ebe2                	sd	s8,464(sp)
    80005276:	e7e6                	sd	s9,456(sp)
    80005278:	e3ea                	sd	s10,448(sp)
    8000527a:	ff6e                	sd	s11,440(sp)
    8000527c:	1400                	addi	s0,sp,544
    8000527e:	892a                	mv	s2,a0
    80005280:	dea43423          	sd	a0,-536(s0)
    80005284:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005288:	ffffc097          	auipc	ra,0xffffc
    8000528c:	72c080e7          	jalr	1836(ra) # 800019b4 <myproc>
    80005290:	84aa                	mv	s1,a0

  begin_op();
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	4a6080e7          	jalr	1190(ra) # 80004738 <begin_op>

  if((ip = namei(path)) == 0){
    8000529a:	854a                	mv	a0,s2
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	27c080e7          	jalr	636(ra) # 80004518 <namei>
    800052a4:	c93d                	beqz	a0,8000531a <exec+0xc4>
    800052a6:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	aba080e7          	jalr	-1350(ra) # 80003d62 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052b0:	04000713          	li	a4,64
    800052b4:	4681                	li	a3,0
    800052b6:	e4840613          	addi	a2,s0,-440
    800052ba:	4581                	li	a1,0
    800052bc:	8556                	mv	a0,s5
    800052be:	fffff097          	auipc	ra,0xfffff
    800052c2:	d58080e7          	jalr	-680(ra) # 80004016 <readi>
    800052c6:	04000793          	li	a5,64
    800052ca:	00f51a63          	bne	a0,a5,800052de <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800052ce:	e4842703          	lw	a4,-440(s0)
    800052d2:	464c47b7          	lui	a5,0x464c4
    800052d6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052da:	04f70663          	beq	a4,a5,80005326 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052de:	8556                	mv	a0,s5
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	ce4080e7          	jalr	-796(ra) # 80003fc4 <iunlockput>
    end_op();
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	4d0080e7          	jalr	1232(ra) # 800047b8 <end_op>
  }
  return -1;
    800052f0:	557d                	li	a0,-1
}
    800052f2:	21813083          	ld	ra,536(sp)
    800052f6:	21013403          	ld	s0,528(sp)
    800052fa:	20813483          	ld	s1,520(sp)
    800052fe:	20013903          	ld	s2,512(sp)
    80005302:	79fe                	ld	s3,504(sp)
    80005304:	7a5e                	ld	s4,496(sp)
    80005306:	7abe                	ld	s5,488(sp)
    80005308:	7b1e                	ld	s6,480(sp)
    8000530a:	6bfe                	ld	s7,472(sp)
    8000530c:	6c5e                	ld	s8,464(sp)
    8000530e:	6cbe                	ld	s9,456(sp)
    80005310:	6d1e                	ld	s10,448(sp)
    80005312:	7dfa                	ld	s11,440(sp)
    80005314:	22010113          	addi	sp,sp,544
    80005318:	8082                	ret
    end_op();
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	49e080e7          	jalr	1182(ra) # 800047b8 <end_op>
    return -1;
    80005322:	557d                	li	a0,-1
    80005324:	b7f9                	j	800052f2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005326:	8526                	mv	a0,s1
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	750080e7          	jalr	1872(ra) # 80001a78 <proc_pagetable>
    80005330:	8b2a                	mv	s6,a0
    80005332:	d555                	beqz	a0,800052de <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005334:	e6842783          	lw	a5,-408(s0)
    80005338:	e8045703          	lhu	a4,-384(s0)
    8000533c:	c735                	beqz	a4,800053a8 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000533e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005340:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005344:	6a05                	lui	s4,0x1
    80005346:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000534a:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    8000534e:	6d85                	lui	s11,0x1
    80005350:	7d7d                	lui	s10,0xfffff
    80005352:	a49d                	j	800055b8 <exec+0x362>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005354:	00003517          	auipc	a0,0x3
    80005358:	4c450513          	addi	a0,a0,1220 # 80008818 <syscalls+0x298>
    8000535c:	ffffb097          	auipc	ra,0xffffb
    80005360:	1ce080e7          	jalr	462(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005364:	874a                	mv	a4,s2
    80005366:	009c86bb          	addw	a3,s9,s1
    8000536a:	4581                	li	a1,0
    8000536c:	8556                	mv	a0,s5
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	ca8080e7          	jalr	-856(ra) # 80004016 <readi>
    80005376:	2501                	sext.w	a0,a0
    80005378:	1ea91063          	bne	s2,a0,80005558 <exec+0x302>
  for(i = 0; i < sz; i += PGSIZE){
    8000537c:	009d84bb          	addw	s1,s11,s1
    80005380:	013d09bb          	addw	s3,s10,s3
    80005384:	2174fa63          	bgeu	s1,s7,80005598 <exec+0x342>
    pa = walkaddr(pagetable, va + i);
    80005388:	02049593          	slli	a1,s1,0x20
    8000538c:	9181                	srli	a1,a1,0x20
    8000538e:	95e2                	add	a1,a1,s8
    80005390:	855a                	mv	a0,s6
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	cee080e7          	jalr	-786(ra) # 80001080 <walkaddr>
    8000539a:	862a                	mv	a2,a0
    if(pa == 0)
    8000539c:	dd45                	beqz	a0,80005354 <exec+0xfe>
      n = PGSIZE;
    8000539e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800053a0:	fd49f2e3          	bgeu	s3,s4,80005364 <exec+0x10e>
      n = sz - i;
    800053a4:	894e                	mv	s2,s3
    800053a6:	bf7d                	j	80005364 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800053a8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053aa:	e0043423          	sd	zero,-504(s0)
  iunlockput(ip);
    800053ae:	8556                	mv	a0,s5
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	c14080e7          	jalr	-1004(ra) # 80003fc4 <iunlockput>
  end_op();
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	400080e7          	jalr	1024(ra) # 800047b8 <end_op>
  p = myproc();
    800053c0:	ffffc097          	auipc	ra,0xffffc
    800053c4:	5f4080e7          	jalr	1524(ra) # 800019b4 <myproc>
    800053c8:	8a2a                	mv	s4,a0
  uint64 oldsz = p->sz;
    800053ca:	1e053d03          	ld	s10,480(a0)
  sz = PGROUNDUP(sz);
    800053ce:	6785                	lui	a5,0x1
    800053d0:	17fd                	addi	a5,a5,-1
    800053d2:	94be                	add	s1,s1,a5
    800053d4:	77fd                	lui	a5,0xfffff
    800053d6:	8fe5                	and	a5,a5,s1
    800053d8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053dc:	6609                	lui	a2,0x2
    800053de:	963e                	add	a2,a2,a5
    800053e0:	85be                	mv	a1,a5
    800053e2:	855a                	mv	a0,s6
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	03e080e7          	jalr	62(ra) # 80001422 <uvmalloc>
    800053ec:	8caa                	mv	s9,a0
  ip = 0;
    800053ee:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053f0:	16050463          	beqz	a0,80005558 <exec+0x302>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053f4:	75f9                	lui	a1,0xffffe
    800053f6:	95aa                	add	a1,a1,a0
    800053f8:	855a                	mv	a0,s6
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	246080e7          	jalr	582(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005402:	7bfd                	lui	s7,0xfffff
    80005404:	9be6                	add	s7,s7,s9
  for(argc = 0; argv[argc]; argc++) {
    80005406:	df043783          	ld	a5,-528(s0)
    8000540a:	6388                	ld	a0,0(a5)
    8000540c:	c925                	beqz	a0,8000547c <exec+0x226>
    8000540e:	e8840993          	addi	s3,s0,-376
    80005412:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005416:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005418:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000541a:	ffffc097          	auipc	ra,0xffffc
    8000541e:	a4c080e7          	jalr	-1460(ra) # 80000e66 <strlen>
    80005422:	0015079b          	addiw	a5,a0,1
    80005426:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000542a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000542e:	15796963          	bltu	s2,s7,80005580 <exec+0x32a>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005432:	df043d83          	ld	s11,-528(s0)
    80005436:	000dba83          	ld	s5,0(s11) # 1000 <_entry-0x7ffff000>
    8000543a:	8556                	mv	a0,s5
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	a2a080e7          	jalr	-1494(ra) # 80000e66 <strlen>
    80005444:	0015069b          	addiw	a3,a0,1
    80005448:	8656                	mv	a2,s5
    8000544a:	85ca                	mv	a1,s2
    8000544c:	855a                	mv	a0,s6
    8000544e:	ffffc097          	auipc	ra,0xffffc
    80005452:	224080e7          	jalr	548(ra) # 80001672 <copyout>
    80005456:	12054963          	bltz	a0,80005588 <exec+0x332>
    ustack[argc] = sp;
    8000545a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000545e:	0485                	addi	s1,s1,1
    80005460:	008d8793          	addi	a5,s11,8
    80005464:	def43823          	sd	a5,-528(s0)
    80005468:	008db503          	ld	a0,8(s11)
    8000546c:	c911                	beqz	a0,80005480 <exec+0x22a>
    if(argc >= MAXARG)
    8000546e:	09a1                	addi	s3,s3,8
    80005470:	fb8995e3          	bne	s3,s8,8000541a <exec+0x1c4>
  sz = sz1;
    80005474:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    80005478:	4a81                	li	s5,0
    8000547a:	a8f9                	j	80005558 <exec+0x302>
  sp = sz;
    8000547c:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    8000547e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005480:	00349793          	slli	a5,s1,0x3
    80005484:	f9040713          	addi	a4,s0,-112
    80005488:	97ba                	add	a5,a5,a4
    8000548a:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd2ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000548e:	00148693          	addi	a3,s1,1
    80005492:	068e                	slli	a3,a3,0x3
    80005494:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005498:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000549c:	01797663          	bgeu	s2,s7,800054a8 <exec+0x252>
  sz = sz1;
    800054a0:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    800054a4:	4a81                	li	s5,0
    800054a6:	a84d                	j	80005558 <exec+0x302>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054a8:	e8840613          	addi	a2,s0,-376
    800054ac:	85ca                	mv	a1,s2
    800054ae:	855a                	mv	a0,s6
    800054b0:	ffffc097          	auipc	ra,0xffffc
    800054b4:	1c2080e7          	jalr	450(ra) # 80001672 <copyout>
    800054b8:	0c054c63          	bltz	a0,80005590 <exec+0x33a>
  p->trapframe->a1 = sp;
    800054bc:	1f0a3783          	ld	a5,496(s4)
    800054c0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054c4:	de843783          	ld	a5,-536(s0)
    800054c8:	0007c703          	lbu	a4,0(a5)
    800054cc:	cf11                	beqz	a4,800054e8 <exec+0x292>
    800054ce:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054d0:	02f00693          	li	a3,47
    800054d4:	a039                	j	800054e2 <exec+0x28c>
      last = s+1;
    800054d6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800054da:	0785                	addi	a5,a5,1
    800054dc:	fff7c703          	lbu	a4,-1(a5)
    800054e0:	c701                	beqz	a4,800054e8 <exec+0x292>
    if(*s == '/')
    800054e2:	fed71ce3          	bne	a4,a3,800054da <exec+0x284>
    800054e6:	bfc5                	j	800054d6 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800054e8:	4641                	li	a2,16
    800054ea:	de843583          	ld	a1,-536(s0)
    800054ee:	2f0a0513          	addi	a0,s4,752
    800054f2:	ffffc097          	auipc	ra,0xffffc
    800054f6:	942080e7          	jalr	-1726(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    800054fa:	1e8a3503          	ld	a0,488(s4)
  p->pagetable = pagetable;
    800054fe:	1f6a3423          	sd	s6,488(s4)
  p->sz = sz;
    80005502:	1f9a3023          	sd	s9,480(s4)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005506:	1f0a3783          	ld	a5,496(s4)
    8000550a:	e6043703          	ld	a4,-416(s0)
    8000550e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005510:	1f0a3783          	ld	a5,496(s4)
    80005514:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005518:	85ea                	mv	a1,s10
    8000551a:	ffffc097          	auipc	ra,0xffffc
    8000551e:	5fa080e7          	jalr	1530(ra) # 80001b14 <proc_freepagetable>
  for(int signum=0; i<SIG_NUM; signum++){
    80005522:	47fd                	li	a5,31
    80005524:	e0843703          	ld	a4,-504(s0)
    80005528:	02e7c363          	blt	a5,a4,8000554e <exec+0x2f8>
    8000552c:	140a0793          	addi	a5,s4,320
    80005530:	040a0a13          	addi	s4,s4,64
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005534:	4705                	li	a4,1
    80005536:	a019                	j	8000553c <exec+0x2e6>
  for(int signum=0; i<SIG_NUM; signum++){
    80005538:	0791                	addi	a5,a5,4
    8000553a:	0a21                	addi	s4,s4,8
    p->signal_handlers_masks[signum] = 0;
    8000553c:	0007a023          	sw	zero,0(a5)
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005540:	000a3683          	ld	a3,0(s4)
    80005544:	fee68ae3          	beq	a3,a4,80005538 <exec+0x2e2>
      p->signal_handlers[signum] = SIG_DFL;
    80005548:	000a3023          	sd	zero,0(s4)
    8000554c:	b7f5                	j	80005538 <exec+0x2e2>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000554e:	0004851b          	sext.w	a0,s1
    80005552:	b345                	j	800052f2 <exec+0x9c>
    80005554:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005558:	df843583          	ld	a1,-520(s0)
    8000555c:	855a                	mv	a0,s6
    8000555e:	ffffc097          	auipc	ra,0xffffc
    80005562:	5b6080e7          	jalr	1462(ra) # 80001b14 <proc_freepagetable>
  if(ip){
    80005566:	d60a9ce3          	bnez	s5,800052de <exec+0x88>
  return -1;
    8000556a:	557d                	li	a0,-1
    8000556c:	b359                	j	800052f2 <exec+0x9c>
    8000556e:	de943c23          	sd	s1,-520(s0)
    80005572:	b7dd                	j	80005558 <exec+0x302>
    80005574:	de943c23          	sd	s1,-520(s0)
    80005578:	b7c5                	j	80005558 <exec+0x302>
    8000557a:	de943c23          	sd	s1,-520(s0)
    8000557e:	bfe9                	j	80005558 <exec+0x302>
  sz = sz1;
    80005580:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    80005584:	4a81                	li	s5,0
    80005586:	bfc9                	j	80005558 <exec+0x302>
  sz = sz1;
    80005588:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    8000558c:	4a81                	li	s5,0
    8000558e:	b7e9                	j	80005558 <exec+0x302>
  sz = sz1;
    80005590:	df943c23          	sd	s9,-520(s0)
  ip = 0;
    80005594:	4a81                	li	s5,0
    80005596:	b7c9                	j	80005558 <exec+0x302>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005598:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000559c:	e0843783          	ld	a5,-504(s0)
    800055a0:	0017869b          	addiw	a3,a5,1
    800055a4:	e0d43423          	sd	a3,-504(s0)
    800055a8:	e0043783          	ld	a5,-512(s0)
    800055ac:	0387879b          	addiw	a5,a5,56
    800055b0:	e8045703          	lhu	a4,-384(s0)
    800055b4:	dee6dde3          	bge	a3,a4,800053ae <exec+0x158>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055b8:	2781                	sext.w	a5,a5
    800055ba:	e0f43023          	sd	a5,-512(s0)
    800055be:	03800713          	li	a4,56
    800055c2:	86be                	mv	a3,a5
    800055c4:	e1040613          	addi	a2,s0,-496
    800055c8:	4581                	li	a1,0
    800055ca:	8556                	mv	a0,s5
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	a4a080e7          	jalr	-1462(ra) # 80004016 <readi>
    800055d4:	03800793          	li	a5,56
    800055d8:	f6f51ee3          	bne	a0,a5,80005554 <exec+0x2fe>
    if(ph.type != ELF_PROG_LOAD)
    800055dc:	e1042783          	lw	a5,-496(s0)
    800055e0:	4705                	li	a4,1
    800055e2:	fae79de3          	bne	a5,a4,8000559c <exec+0x346>
    if(ph.memsz < ph.filesz)
    800055e6:	e3843603          	ld	a2,-456(s0)
    800055ea:	e3043783          	ld	a5,-464(s0)
    800055ee:	f8f660e3          	bltu	a2,a5,8000556e <exec+0x318>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055f2:	e2043783          	ld	a5,-480(s0)
    800055f6:	963e                	add	a2,a2,a5
    800055f8:	f6f66ee3          	bltu	a2,a5,80005574 <exec+0x31e>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055fc:	85a6                	mv	a1,s1
    800055fe:	855a                	mv	a0,s6
    80005600:	ffffc097          	auipc	ra,0xffffc
    80005604:	e22080e7          	jalr	-478(ra) # 80001422 <uvmalloc>
    80005608:	dea43c23          	sd	a0,-520(s0)
    8000560c:	d53d                	beqz	a0,8000557a <exec+0x324>
    if(ph.vaddr % PGSIZE != 0)
    8000560e:	e2043c03          	ld	s8,-480(s0)
    80005612:	de043783          	ld	a5,-544(s0)
    80005616:	00fc77b3          	and	a5,s8,a5
    8000561a:	ff9d                	bnez	a5,80005558 <exec+0x302>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000561c:	e1842c83          	lw	s9,-488(s0)
    80005620:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005624:	f60b8ae3          	beqz	s7,80005598 <exec+0x342>
    80005628:	89de                	mv	s3,s7
    8000562a:	4481                	li	s1,0
    8000562c:	bbb1                	j	80005388 <exec+0x132>

000000008000562e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000562e:	7179                	addi	sp,sp,-48
    80005630:	f406                	sd	ra,40(sp)
    80005632:	f022                	sd	s0,32(sp)
    80005634:	ec26                	sd	s1,24(sp)
    80005636:	e84a                	sd	s2,16(sp)
    80005638:	1800                	addi	s0,sp,48
    8000563a:	892e                	mv	s2,a1
    8000563c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000563e:	fdc40593          	addi	a1,s0,-36
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	adc080e7          	jalr	-1316(ra) # 8000311e <argint>
    8000564a:	04054063          	bltz	a0,8000568a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000564e:	fdc42703          	lw	a4,-36(s0)
    80005652:	47bd                	li	a5,15
    80005654:	02e7ed63          	bltu	a5,a4,8000568e <argfd+0x60>
    80005658:	ffffc097          	auipc	ra,0xffffc
    8000565c:	35c080e7          	jalr	860(ra) # 800019b4 <myproc>
    80005660:	fdc42703          	lw	a4,-36(s0)
    80005664:	04c70793          	addi	a5,a4,76
    80005668:	078e                	slli	a5,a5,0x3
    8000566a:	953e                	add	a0,a0,a5
    8000566c:	651c                	ld	a5,8(a0)
    8000566e:	c395                	beqz	a5,80005692 <argfd+0x64>
    return -1;
  if(pfd)
    80005670:	00090463          	beqz	s2,80005678 <argfd+0x4a>
    *pfd = fd;
    80005674:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005678:	4501                	li	a0,0
  if(pf)
    8000567a:	c091                	beqz	s1,8000567e <argfd+0x50>
    *pf = f;
    8000567c:	e09c                	sd	a5,0(s1)
}
    8000567e:	70a2                	ld	ra,40(sp)
    80005680:	7402                	ld	s0,32(sp)
    80005682:	64e2                	ld	s1,24(sp)
    80005684:	6942                	ld	s2,16(sp)
    80005686:	6145                	addi	sp,sp,48
    80005688:	8082                	ret
    return -1;
    8000568a:	557d                	li	a0,-1
    8000568c:	bfcd                	j	8000567e <argfd+0x50>
    return -1;
    8000568e:	557d                	li	a0,-1
    80005690:	b7fd                	j	8000567e <argfd+0x50>
    80005692:	557d                	li	a0,-1
    80005694:	b7ed                	j	8000567e <argfd+0x50>

0000000080005696 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005696:	1101                	addi	sp,sp,-32
    80005698:	ec06                	sd	ra,24(sp)
    8000569a:	e822                	sd	s0,16(sp)
    8000569c:	e426                	sd	s1,8(sp)
    8000569e:	1000                	addi	s0,sp,32
    800056a0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056a2:	ffffc097          	auipc	ra,0xffffc
    800056a6:	312080e7          	jalr	786(ra) # 800019b4 <myproc>
    800056aa:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056ac:	26850793          	addi	a5,a0,616
    800056b0:	4501                	li	a0,0
    800056b2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056b4:	6398                	ld	a4,0(a5)
    800056b6:	cb19                	beqz	a4,800056cc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056b8:	2505                	addiw	a0,a0,1
    800056ba:	07a1                	addi	a5,a5,8
    800056bc:	fed51ce3          	bne	a0,a3,800056b4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056c0:	557d                	li	a0,-1
}
    800056c2:	60e2                	ld	ra,24(sp)
    800056c4:	6442                	ld	s0,16(sp)
    800056c6:	64a2                	ld	s1,8(sp)
    800056c8:	6105                	addi	sp,sp,32
    800056ca:	8082                	ret
      p->ofile[fd] = f;
    800056cc:	04c50793          	addi	a5,a0,76
    800056d0:	078e                	slli	a5,a5,0x3
    800056d2:	963e                	add	a2,a2,a5
    800056d4:	e604                	sd	s1,8(a2)
      return fd;
    800056d6:	b7f5                	j	800056c2 <fdalloc+0x2c>

00000000800056d8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056d8:	715d                	addi	sp,sp,-80
    800056da:	e486                	sd	ra,72(sp)
    800056dc:	e0a2                	sd	s0,64(sp)
    800056de:	fc26                	sd	s1,56(sp)
    800056e0:	f84a                	sd	s2,48(sp)
    800056e2:	f44e                	sd	s3,40(sp)
    800056e4:	f052                	sd	s4,32(sp)
    800056e6:	ec56                	sd	s5,24(sp)
    800056e8:	0880                	addi	s0,sp,80
    800056ea:	89ae                	mv	s3,a1
    800056ec:	8ab2                	mv	s5,a2
    800056ee:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056f0:	fb040593          	addi	a1,s0,-80
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	e42080e7          	jalr	-446(ra) # 80004536 <nameiparent>
    800056fc:	892a                	mv	s2,a0
    800056fe:	12050e63          	beqz	a0,8000583a <create+0x162>
    return 0;

  ilock(dp);
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	660080e7          	jalr	1632(ra) # 80003d62 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000570a:	4601                	li	a2,0
    8000570c:	fb040593          	addi	a1,s0,-80
    80005710:	854a                	mv	a0,s2
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	b34080e7          	jalr	-1228(ra) # 80004246 <dirlookup>
    8000571a:	84aa                	mv	s1,a0
    8000571c:	c921                	beqz	a0,8000576c <create+0x94>
    iunlockput(dp);
    8000571e:	854a                	mv	a0,s2
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	8a4080e7          	jalr	-1884(ra) # 80003fc4 <iunlockput>
    ilock(ip);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	638080e7          	jalr	1592(ra) # 80003d62 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005732:	2981                	sext.w	s3,s3
    80005734:	4789                	li	a5,2
    80005736:	02f99463          	bne	s3,a5,8000575e <create+0x86>
    8000573a:	0444d783          	lhu	a5,68(s1)
    8000573e:	37f9                	addiw	a5,a5,-2
    80005740:	17c2                	slli	a5,a5,0x30
    80005742:	93c1                	srli	a5,a5,0x30
    80005744:	4705                	li	a4,1
    80005746:	00f76c63          	bltu	a4,a5,8000575e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000574a:	8526                	mv	a0,s1
    8000574c:	60a6                	ld	ra,72(sp)
    8000574e:	6406                	ld	s0,64(sp)
    80005750:	74e2                	ld	s1,56(sp)
    80005752:	7942                	ld	s2,48(sp)
    80005754:	79a2                	ld	s3,40(sp)
    80005756:	7a02                	ld	s4,32(sp)
    80005758:	6ae2                	ld	s5,24(sp)
    8000575a:	6161                	addi	sp,sp,80
    8000575c:	8082                	ret
    iunlockput(ip);
    8000575e:	8526                	mv	a0,s1
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	864080e7          	jalr	-1948(ra) # 80003fc4 <iunlockput>
    return 0;
    80005768:	4481                	li	s1,0
    8000576a:	b7c5                	j	8000574a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000576c:	85ce                	mv	a1,s3
    8000576e:	00092503          	lw	a0,0(s2)
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	458080e7          	jalr	1112(ra) # 80003bca <ialloc>
    8000577a:	84aa                	mv	s1,a0
    8000577c:	c521                	beqz	a0,800057c4 <create+0xec>
  ilock(ip);
    8000577e:	ffffe097          	auipc	ra,0xffffe
    80005782:	5e4080e7          	jalr	1508(ra) # 80003d62 <ilock>
  ip->major = major;
    80005786:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000578a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000578e:	4a05                	li	s4,1
    80005790:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005794:	8526                	mv	a0,s1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	502080e7          	jalr	1282(ra) # 80003c98 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000579e:	2981                	sext.w	s3,s3
    800057a0:	03498a63          	beq	s3,s4,800057d4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800057a4:	40d0                	lw	a2,4(s1)
    800057a6:	fb040593          	addi	a1,s0,-80
    800057aa:	854a                	mv	a0,s2
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	caa080e7          	jalr	-854(ra) # 80004456 <dirlink>
    800057b4:	06054b63          	bltz	a0,8000582a <create+0x152>
  iunlockput(dp);
    800057b8:	854a                	mv	a0,s2
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	80a080e7          	jalr	-2038(ra) # 80003fc4 <iunlockput>
  return ip;
    800057c2:	b761                	j	8000574a <create+0x72>
    panic("create: ialloc");
    800057c4:	00003517          	auipc	a0,0x3
    800057c8:	07450513          	addi	a0,a0,116 # 80008838 <syscalls+0x2b8>
    800057cc:	ffffb097          	auipc	ra,0xffffb
    800057d0:	d5e080e7          	jalr	-674(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800057d4:	04a95783          	lhu	a5,74(s2)
    800057d8:	2785                	addiw	a5,a5,1
    800057da:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800057de:	854a                	mv	a0,s2
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	4b8080e7          	jalr	1208(ra) # 80003c98 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057e8:	40d0                	lw	a2,4(s1)
    800057ea:	00003597          	auipc	a1,0x3
    800057ee:	05e58593          	addi	a1,a1,94 # 80008848 <syscalls+0x2c8>
    800057f2:	8526                	mv	a0,s1
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	c62080e7          	jalr	-926(ra) # 80004456 <dirlink>
    800057fc:	00054f63          	bltz	a0,8000581a <create+0x142>
    80005800:	00492603          	lw	a2,4(s2)
    80005804:	00003597          	auipc	a1,0x3
    80005808:	04c58593          	addi	a1,a1,76 # 80008850 <syscalls+0x2d0>
    8000580c:	8526                	mv	a0,s1
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	c48080e7          	jalr	-952(ra) # 80004456 <dirlink>
    80005816:	f80557e3          	bgez	a0,800057a4 <create+0xcc>
      panic("create dots");
    8000581a:	00003517          	auipc	a0,0x3
    8000581e:	03e50513          	addi	a0,a0,62 # 80008858 <syscalls+0x2d8>
    80005822:	ffffb097          	auipc	ra,0xffffb
    80005826:	d08080e7          	jalr	-760(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000582a:	00003517          	auipc	a0,0x3
    8000582e:	03e50513          	addi	a0,a0,62 # 80008868 <syscalls+0x2e8>
    80005832:	ffffb097          	auipc	ra,0xffffb
    80005836:	cf8080e7          	jalr	-776(ra) # 8000052a <panic>
    return 0;
    8000583a:	84aa                	mv	s1,a0
    8000583c:	b739                	j	8000574a <create+0x72>

000000008000583e <sys_dup>:
{
    8000583e:	7179                	addi	sp,sp,-48
    80005840:	f406                	sd	ra,40(sp)
    80005842:	f022                	sd	s0,32(sp)
    80005844:	ec26                	sd	s1,24(sp)
    80005846:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005848:	fd840613          	addi	a2,s0,-40
    8000584c:	4581                	li	a1,0
    8000584e:	4501                	li	a0,0
    80005850:	00000097          	auipc	ra,0x0
    80005854:	dde080e7          	jalr	-546(ra) # 8000562e <argfd>
    return -1;
    80005858:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000585a:	02054363          	bltz	a0,80005880 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000585e:	fd843503          	ld	a0,-40(s0)
    80005862:	00000097          	auipc	ra,0x0
    80005866:	e34080e7          	jalr	-460(ra) # 80005696 <fdalloc>
    8000586a:	84aa                	mv	s1,a0
    return -1;
    8000586c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000586e:	00054963          	bltz	a0,80005880 <sys_dup+0x42>
  filedup(f);
    80005872:	fd843503          	ld	a0,-40(s0)
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	33c080e7          	jalr	828(ra) # 80004bb2 <filedup>
  return fd;
    8000587e:	87a6                	mv	a5,s1
}
    80005880:	853e                	mv	a0,a5
    80005882:	70a2                	ld	ra,40(sp)
    80005884:	7402                	ld	s0,32(sp)
    80005886:	64e2                	ld	s1,24(sp)
    80005888:	6145                	addi	sp,sp,48
    8000588a:	8082                	ret

000000008000588c <sys_read>:
{
    8000588c:	7179                	addi	sp,sp,-48
    8000588e:	f406                	sd	ra,40(sp)
    80005890:	f022                	sd	s0,32(sp)
    80005892:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005894:	fe840613          	addi	a2,s0,-24
    80005898:	4581                	li	a1,0
    8000589a:	4501                	li	a0,0
    8000589c:	00000097          	auipc	ra,0x0
    800058a0:	d92080e7          	jalr	-622(ra) # 8000562e <argfd>
    return -1;
    800058a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058a6:	04054163          	bltz	a0,800058e8 <sys_read+0x5c>
    800058aa:	fe440593          	addi	a1,s0,-28
    800058ae:	4509                	li	a0,2
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	86e080e7          	jalr	-1938(ra) # 8000311e <argint>
    return -1;
    800058b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ba:	02054763          	bltz	a0,800058e8 <sys_read+0x5c>
    800058be:	fd840593          	addi	a1,s0,-40
    800058c2:	4505                	li	a0,1
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	87c080e7          	jalr	-1924(ra) # 80003140 <argaddr>
    return -1;
    800058cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ce:	00054d63          	bltz	a0,800058e8 <sys_read+0x5c>
  return fileread(f, p, n);
    800058d2:	fe442603          	lw	a2,-28(s0)
    800058d6:	fd843583          	ld	a1,-40(s0)
    800058da:	fe843503          	ld	a0,-24(s0)
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	460080e7          	jalr	1120(ra) # 80004d3e <fileread>
    800058e6:	87aa                	mv	a5,a0
}
    800058e8:	853e                	mv	a0,a5
    800058ea:	70a2                	ld	ra,40(sp)
    800058ec:	7402                	ld	s0,32(sp)
    800058ee:	6145                	addi	sp,sp,48
    800058f0:	8082                	ret

00000000800058f2 <sys_write>:
{
    800058f2:	7179                	addi	sp,sp,-48
    800058f4:	f406                	sd	ra,40(sp)
    800058f6:	f022                	sd	s0,32(sp)
    800058f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058fa:	fe840613          	addi	a2,s0,-24
    800058fe:	4581                	li	a1,0
    80005900:	4501                	li	a0,0
    80005902:	00000097          	auipc	ra,0x0
    80005906:	d2c080e7          	jalr	-724(ra) # 8000562e <argfd>
    return -1;
    8000590a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000590c:	04054163          	bltz	a0,8000594e <sys_write+0x5c>
    80005910:	fe440593          	addi	a1,s0,-28
    80005914:	4509                	li	a0,2
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	808080e7          	jalr	-2040(ra) # 8000311e <argint>
    return -1;
    8000591e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005920:	02054763          	bltz	a0,8000594e <sys_write+0x5c>
    80005924:	fd840593          	addi	a1,s0,-40
    80005928:	4505                	li	a0,1
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	816080e7          	jalr	-2026(ra) # 80003140 <argaddr>
    return -1;
    80005932:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005934:	00054d63          	bltz	a0,8000594e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005938:	fe442603          	lw	a2,-28(s0)
    8000593c:	fd843583          	ld	a1,-40(s0)
    80005940:	fe843503          	ld	a0,-24(s0)
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	4bc080e7          	jalr	1212(ra) # 80004e00 <filewrite>
    8000594c:	87aa                	mv	a5,a0
}
    8000594e:	853e                	mv	a0,a5
    80005950:	70a2                	ld	ra,40(sp)
    80005952:	7402                	ld	s0,32(sp)
    80005954:	6145                	addi	sp,sp,48
    80005956:	8082                	ret

0000000080005958 <sys_close>:
{
    80005958:	1101                	addi	sp,sp,-32
    8000595a:	ec06                	sd	ra,24(sp)
    8000595c:	e822                	sd	s0,16(sp)
    8000595e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005960:	fe040613          	addi	a2,s0,-32
    80005964:	fec40593          	addi	a1,s0,-20
    80005968:	4501                	li	a0,0
    8000596a:	00000097          	auipc	ra,0x0
    8000596e:	cc4080e7          	jalr	-828(ra) # 8000562e <argfd>
    return -1;
    80005972:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005974:	02054563          	bltz	a0,8000599e <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005978:	ffffc097          	auipc	ra,0xffffc
    8000597c:	03c080e7          	jalr	60(ra) # 800019b4 <myproc>
    80005980:	fec42783          	lw	a5,-20(s0)
    80005984:	04c78793          	addi	a5,a5,76
    80005988:	078e                	slli	a5,a5,0x3
    8000598a:	97aa                	add	a5,a5,a0
    8000598c:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005990:	fe043503          	ld	a0,-32(s0)
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	270080e7          	jalr	624(ra) # 80004c04 <fileclose>
  return 0;
    8000599c:	4781                	li	a5,0
}
    8000599e:	853e                	mv	a0,a5
    800059a0:	60e2                	ld	ra,24(sp)
    800059a2:	6442                	ld	s0,16(sp)
    800059a4:	6105                	addi	sp,sp,32
    800059a6:	8082                	ret

00000000800059a8 <sys_fstat>:
{
    800059a8:	1101                	addi	sp,sp,-32
    800059aa:	ec06                	sd	ra,24(sp)
    800059ac:	e822                	sd	s0,16(sp)
    800059ae:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059b0:	fe840613          	addi	a2,s0,-24
    800059b4:	4581                	li	a1,0
    800059b6:	4501                	li	a0,0
    800059b8:	00000097          	auipc	ra,0x0
    800059bc:	c76080e7          	jalr	-906(ra) # 8000562e <argfd>
    return -1;
    800059c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059c2:	02054563          	bltz	a0,800059ec <sys_fstat+0x44>
    800059c6:	fe040593          	addi	a1,s0,-32
    800059ca:	4505                	li	a0,1
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	774080e7          	jalr	1908(ra) # 80003140 <argaddr>
    return -1;
    800059d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059d6:	00054b63          	bltz	a0,800059ec <sys_fstat+0x44>
  return filestat(f, st);
    800059da:	fe043583          	ld	a1,-32(s0)
    800059de:	fe843503          	ld	a0,-24(s0)
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	2ea080e7          	jalr	746(ra) # 80004ccc <filestat>
    800059ea:	87aa                	mv	a5,a0
}
    800059ec:	853e                	mv	a0,a5
    800059ee:	60e2                	ld	ra,24(sp)
    800059f0:	6442                	ld	s0,16(sp)
    800059f2:	6105                	addi	sp,sp,32
    800059f4:	8082                	ret

00000000800059f6 <sys_link>:
{
    800059f6:	7169                	addi	sp,sp,-304
    800059f8:	f606                	sd	ra,296(sp)
    800059fa:	f222                	sd	s0,288(sp)
    800059fc:	ee26                	sd	s1,280(sp)
    800059fe:	ea4a                	sd	s2,272(sp)
    80005a00:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a02:	08000613          	li	a2,128
    80005a06:	ed040593          	addi	a1,s0,-304
    80005a0a:	4501                	li	a0,0
    80005a0c:	ffffd097          	auipc	ra,0xffffd
    80005a10:	756080e7          	jalr	1878(ra) # 80003162 <argstr>
    return -1;
    80005a14:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a16:	10054e63          	bltz	a0,80005b32 <sys_link+0x13c>
    80005a1a:	08000613          	li	a2,128
    80005a1e:	f5040593          	addi	a1,s0,-176
    80005a22:	4505                	li	a0,1
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	73e080e7          	jalr	1854(ra) # 80003162 <argstr>
    return -1;
    80005a2c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a2e:	10054263          	bltz	a0,80005b32 <sys_link+0x13c>
  begin_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	d06080e7          	jalr	-762(ra) # 80004738 <begin_op>
  if((ip = namei(old)) == 0){
    80005a3a:	ed040513          	addi	a0,s0,-304
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	ada080e7          	jalr	-1318(ra) # 80004518 <namei>
    80005a46:	84aa                	mv	s1,a0
    80005a48:	c551                	beqz	a0,80005ad4 <sys_link+0xde>
  ilock(ip);
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	318080e7          	jalr	792(ra) # 80003d62 <ilock>
  if(ip->type == T_DIR){
    80005a52:	04449703          	lh	a4,68(s1)
    80005a56:	4785                	li	a5,1
    80005a58:	08f70463          	beq	a4,a5,80005ae0 <sys_link+0xea>
  ip->nlink++;
    80005a5c:	04a4d783          	lhu	a5,74(s1)
    80005a60:	2785                	addiw	a5,a5,1
    80005a62:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a66:	8526                	mv	a0,s1
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	230080e7          	jalr	560(ra) # 80003c98 <iupdate>
  iunlock(ip);
    80005a70:	8526                	mv	a0,s1
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	3b2080e7          	jalr	946(ra) # 80003e24 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a7a:	fd040593          	addi	a1,s0,-48
    80005a7e:	f5040513          	addi	a0,s0,-176
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	ab4080e7          	jalr	-1356(ra) # 80004536 <nameiparent>
    80005a8a:	892a                	mv	s2,a0
    80005a8c:	c935                	beqz	a0,80005b00 <sys_link+0x10a>
  ilock(dp);
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	2d4080e7          	jalr	724(ra) # 80003d62 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a96:	00092703          	lw	a4,0(s2)
    80005a9a:	409c                	lw	a5,0(s1)
    80005a9c:	04f71d63          	bne	a4,a5,80005af6 <sys_link+0x100>
    80005aa0:	40d0                	lw	a2,4(s1)
    80005aa2:	fd040593          	addi	a1,s0,-48
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	9ae080e7          	jalr	-1618(ra) # 80004456 <dirlink>
    80005ab0:	04054363          	bltz	a0,80005af6 <sys_link+0x100>
  iunlockput(dp);
    80005ab4:	854a                	mv	a0,s2
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	50e080e7          	jalr	1294(ra) # 80003fc4 <iunlockput>
  iput(ip);
    80005abe:	8526                	mv	a0,s1
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	45c080e7          	jalr	1116(ra) # 80003f1c <iput>
  end_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	cf0080e7          	jalr	-784(ra) # 800047b8 <end_op>
  return 0;
    80005ad0:	4781                	li	a5,0
    80005ad2:	a085                	j	80005b32 <sys_link+0x13c>
    end_op();
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	ce4080e7          	jalr	-796(ra) # 800047b8 <end_op>
    return -1;
    80005adc:	57fd                	li	a5,-1
    80005ade:	a891                	j	80005b32 <sys_link+0x13c>
    iunlockput(ip);
    80005ae0:	8526                	mv	a0,s1
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	4e2080e7          	jalr	1250(ra) # 80003fc4 <iunlockput>
    end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	cce080e7          	jalr	-818(ra) # 800047b8 <end_op>
    return -1;
    80005af2:	57fd                	li	a5,-1
    80005af4:	a83d                	j	80005b32 <sys_link+0x13c>
    iunlockput(dp);
    80005af6:	854a                	mv	a0,s2
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	4cc080e7          	jalr	1228(ra) # 80003fc4 <iunlockput>
  ilock(ip);
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	260080e7          	jalr	608(ra) # 80003d62 <ilock>
  ip->nlink--;
    80005b0a:	04a4d783          	lhu	a5,74(s1)
    80005b0e:	37fd                	addiw	a5,a5,-1
    80005b10:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	182080e7          	jalr	386(ra) # 80003c98 <iupdate>
  iunlockput(ip);
    80005b1e:	8526                	mv	a0,s1
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	4a4080e7          	jalr	1188(ra) # 80003fc4 <iunlockput>
  end_op();
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	c90080e7          	jalr	-880(ra) # 800047b8 <end_op>
  return -1;
    80005b30:	57fd                	li	a5,-1
}
    80005b32:	853e                	mv	a0,a5
    80005b34:	70b2                	ld	ra,296(sp)
    80005b36:	7412                	ld	s0,288(sp)
    80005b38:	64f2                	ld	s1,280(sp)
    80005b3a:	6952                	ld	s2,272(sp)
    80005b3c:	6155                	addi	sp,sp,304
    80005b3e:	8082                	ret

0000000080005b40 <sys_unlink>:
{
    80005b40:	7151                	addi	sp,sp,-240
    80005b42:	f586                	sd	ra,232(sp)
    80005b44:	f1a2                	sd	s0,224(sp)
    80005b46:	eda6                	sd	s1,216(sp)
    80005b48:	e9ca                	sd	s2,208(sp)
    80005b4a:	e5ce                	sd	s3,200(sp)
    80005b4c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b4e:	08000613          	li	a2,128
    80005b52:	f3040593          	addi	a1,s0,-208
    80005b56:	4501                	li	a0,0
    80005b58:	ffffd097          	auipc	ra,0xffffd
    80005b5c:	60a080e7          	jalr	1546(ra) # 80003162 <argstr>
    80005b60:	18054163          	bltz	a0,80005ce2 <sys_unlink+0x1a2>
  begin_op();
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	bd4080e7          	jalr	-1068(ra) # 80004738 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b6c:	fb040593          	addi	a1,s0,-80
    80005b70:	f3040513          	addi	a0,s0,-208
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	9c2080e7          	jalr	-1598(ra) # 80004536 <nameiparent>
    80005b7c:	84aa                	mv	s1,a0
    80005b7e:	c979                	beqz	a0,80005c54 <sys_unlink+0x114>
  ilock(dp);
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	1e2080e7          	jalr	482(ra) # 80003d62 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b88:	00003597          	auipc	a1,0x3
    80005b8c:	cc058593          	addi	a1,a1,-832 # 80008848 <syscalls+0x2c8>
    80005b90:	fb040513          	addi	a0,s0,-80
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	698080e7          	jalr	1688(ra) # 8000422c <namecmp>
    80005b9c:	14050a63          	beqz	a0,80005cf0 <sys_unlink+0x1b0>
    80005ba0:	00003597          	auipc	a1,0x3
    80005ba4:	cb058593          	addi	a1,a1,-848 # 80008850 <syscalls+0x2d0>
    80005ba8:	fb040513          	addi	a0,s0,-80
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	680080e7          	jalr	1664(ra) # 8000422c <namecmp>
    80005bb4:	12050e63          	beqz	a0,80005cf0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bb8:	f2c40613          	addi	a2,s0,-212
    80005bbc:	fb040593          	addi	a1,s0,-80
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	684080e7          	jalr	1668(ra) # 80004246 <dirlookup>
    80005bca:	892a                	mv	s2,a0
    80005bcc:	12050263          	beqz	a0,80005cf0 <sys_unlink+0x1b0>
  ilock(ip);
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	192080e7          	jalr	402(ra) # 80003d62 <ilock>
  if(ip->nlink < 1)
    80005bd8:	04a91783          	lh	a5,74(s2)
    80005bdc:	08f05263          	blez	a5,80005c60 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005be0:	04491703          	lh	a4,68(s2)
    80005be4:	4785                	li	a5,1
    80005be6:	08f70563          	beq	a4,a5,80005c70 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005bea:	4641                	li	a2,16
    80005bec:	4581                	li	a1,0
    80005bee:	fc040513          	addi	a0,s0,-64
    80005bf2:	ffffb097          	auipc	ra,0xffffb
    80005bf6:	0f0080e7          	jalr	240(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bfa:	4741                	li	a4,16
    80005bfc:	f2c42683          	lw	a3,-212(s0)
    80005c00:	fc040613          	addi	a2,s0,-64
    80005c04:	4581                	li	a1,0
    80005c06:	8526                	mv	a0,s1
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	506080e7          	jalr	1286(ra) # 8000410e <writei>
    80005c10:	47c1                	li	a5,16
    80005c12:	0af51563          	bne	a0,a5,80005cbc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c16:	04491703          	lh	a4,68(s2)
    80005c1a:	4785                	li	a5,1
    80005c1c:	0af70863          	beq	a4,a5,80005ccc <sys_unlink+0x18c>
  iunlockput(dp);
    80005c20:	8526                	mv	a0,s1
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	3a2080e7          	jalr	930(ra) # 80003fc4 <iunlockput>
  ip->nlink--;
    80005c2a:	04a95783          	lhu	a5,74(s2)
    80005c2e:	37fd                	addiw	a5,a5,-1
    80005c30:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c34:	854a                	mv	a0,s2
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	062080e7          	jalr	98(ra) # 80003c98 <iupdate>
  iunlockput(ip);
    80005c3e:	854a                	mv	a0,s2
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	384080e7          	jalr	900(ra) # 80003fc4 <iunlockput>
  end_op();
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	b70080e7          	jalr	-1168(ra) # 800047b8 <end_op>
  return 0;
    80005c50:	4501                	li	a0,0
    80005c52:	a84d                	j	80005d04 <sys_unlink+0x1c4>
    end_op();
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	b64080e7          	jalr	-1180(ra) # 800047b8 <end_op>
    return -1;
    80005c5c:	557d                	li	a0,-1
    80005c5e:	a05d                	j	80005d04 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c60:	00003517          	auipc	a0,0x3
    80005c64:	c1850513          	addi	a0,a0,-1000 # 80008878 <syscalls+0x2f8>
    80005c68:	ffffb097          	auipc	ra,0xffffb
    80005c6c:	8c2080e7          	jalr	-1854(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c70:	04c92703          	lw	a4,76(s2)
    80005c74:	02000793          	li	a5,32
    80005c78:	f6e7f9e3          	bgeu	a5,a4,80005bea <sys_unlink+0xaa>
    80005c7c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c80:	4741                	li	a4,16
    80005c82:	86ce                	mv	a3,s3
    80005c84:	f1840613          	addi	a2,s0,-232
    80005c88:	4581                	li	a1,0
    80005c8a:	854a                	mv	a0,s2
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	38a080e7          	jalr	906(ra) # 80004016 <readi>
    80005c94:	47c1                	li	a5,16
    80005c96:	00f51b63          	bne	a0,a5,80005cac <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c9a:	f1845783          	lhu	a5,-232(s0)
    80005c9e:	e7a1                	bnez	a5,80005ce6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ca0:	29c1                	addiw	s3,s3,16
    80005ca2:	04c92783          	lw	a5,76(s2)
    80005ca6:	fcf9ede3          	bltu	s3,a5,80005c80 <sys_unlink+0x140>
    80005caa:	b781                	j	80005bea <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cac:	00003517          	auipc	a0,0x3
    80005cb0:	be450513          	addi	a0,a0,-1052 # 80008890 <syscalls+0x310>
    80005cb4:	ffffb097          	auipc	ra,0xffffb
    80005cb8:	876080e7          	jalr	-1930(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005cbc:	00003517          	auipc	a0,0x3
    80005cc0:	bec50513          	addi	a0,a0,-1044 # 800088a8 <syscalls+0x328>
    80005cc4:	ffffb097          	auipc	ra,0xffffb
    80005cc8:	866080e7          	jalr	-1946(ra) # 8000052a <panic>
    dp->nlink--;
    80005ccc:	04a4d783          	lhu	a5,74(s1)
    80005cd0:	37fd                	addiw	a5,a5,-1
    80005cd2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	fc0080e7          	jalr	-64(ra) # 80003c98 <iupdate>
    80005ce0:	b781                	j	80005c20 <sys_unlink+0xe0>
    return -1;
    80005ce2:	557d                	li	a0,-1
    80005ce4:	a005                	j	80005d04 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ce6:	854a                	mv	a0,s2
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	2dc080e7          	jalr	732(ra) # 80003fc4 <iunlockput>
  iunlockput(dp);
    80005cf0:	8526                	mv	a0,s1
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	2d2080e7          	jalr	722(ra) # 80003fc4 <iunlockput>
  end_op();
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	abe080e7          	jalr	-1346(ra) # 800047b8 <end_op>
  return -1;
    80005d02:	557d                	li	a0,-1
}
    80005d04:	70ae                	ld	ra,232(sp)
    80005d06:	740e                	ld	s0,224(sp)
    80005d08:	64ee                	ld	s1,216(sp)
    80005d0a:	694e                	ld	s2,208(sp)
    80005d0c:	69ae                	ld	s3,200(sp)
    80005d0e:	616d                	addi	sp,sp,240
    80005d10:	8082                	ret

0000000080005d12 <sys_open>:

uint64
sys_open(void)
{
    80005d12:	7131                	addi	sp,sp,-192
    80005d14:	fd06                	sd	ra,184(sp)
    80005d16:	f922                	sd	s0,176(sp)
    80005d18:	f526                	sd	s1,168(sp)
    80005d1a:	f14a                	sd	s2,160(sp)
    80005d1c:	ed4e                	sd	s3,152(sp)
    80005d1e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d20:	08000613          	li	a2,128
    80005d24:	f5040593          	addi	a1,s0,-176
    80005d28:	4501                	li	a0,0
    80005d2a:	ffffd097          	auipc	ra,0xffffd
    80005d2e:	438080e7          	jalr	1080(ra) # 80003162 <argstr>
    return -1;
    80005d32:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d34:	0c054163          	bltz	a0,80005df6 <sys_open+0xe4>
    80005d38:	f4c40593          	addi	a1,s0,-180
    80005d3c:	4505                	li	a0,1
    80005d3e:	ffffd097          	auipc	ra,0xffffd
    80005d42:	3e0080e7          	jalr	992(ra) # 8000311e <argint>
    80005d46:	0a054863          	bltz	a0,80005df6 <sys_open+0xe4>

  begin_op();
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	9ee080e7          	jalr	-1554(ra) # 80004738 <begin_op>

  if(omode & O_CREATE){
    80005d52:	f4c42783          	lw	a5,-180(s0)
    80005d56:	2007f793          	andi	a5,a5,512
    80005d5a:	cbdd                	beqz	a5,80005e10 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d5c:	4681                	li	a3,0
    80005d5e:	4601                	li	a2,0
    80005d60:	4589                	li	a1,2
    80005d62:	f5040513          	addi	a0,s0,-176
    80005d66:	00000097          	auipc	ra,0x0
    80005d6a:	972080e7          	jalr	-1678(ra) # 800056d8 <create>
    80005d6e:	892a                	mv	s2,a0
    if(ip == 0){
    80005d70:	c959                	beqz	a0,80005e06 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d72:	04491703          	lh	a4,68(s2)
    80005d76:	478d                	li	a5,3
    80005d78:	00f71763          	bne	a4,a5,80005d86 <sys_open+0x74>
    80005d7c:	04695703          	lhu	a4,70(s2)
    80005d80:	47a5                	li	a5,9
    80005d82:	0ce7ec63          	bltu	a5,a4,80005e5a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d86:	fffff097          	auipc	ra,0xfffff
    80005d8a:	dc2080e7          	jalr	-574(ra) # 80004b48 <filealloc>
    80005d8e:	89aa                	mv	s3,a0
    80005d90:	10050263          	beqz	a0,80005e94 <sys_open+0x182>
    80005d94:	00000097          	auipc	ra,0x0
    80005d98:	902080e7          	jalr	-1790(ra) # 80005696 <fdalloc>
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	0e054663          	bltz	a0,80005e8a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005da2:	04491703          	lh	a4,68(s2)
    80005da6:	478d                	li	a5,3
    80005da8:	0cf70463          	beq	a4,a5,80005e70 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005dac:	4789                	li	a5,2
    80005dae:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005db2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005db6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dba:	f4c42783          	lw	a5,-180(s0)
    80005dbe:	0017c713          	xori	a4,a5,1
    80005dc2:	8b05                	andi	a4,a4,1
    80005dc4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005dc8:	0037f713          	andi	a4,a5,3
    80005dcc:	00e03733          	snez	a4,a4
    80005dd0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005dd4:	4007f793          	andi	a5,a5,1024
    80005dd8:	c791                	beqz	a5,80005de4 <sys_open+0xd2>
    80005dda:	04491703          	lh	a4,68(s2)
    80005dde:	4789                	li	a5,2
    80005de0:	08f70f63          	beq	a4,a5,80005e7e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005de4:	854a                	mv	a0,s2
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	03e080e7          	jalr	62(ra) # 80003e24 <iunlock>
  end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	9ca080e7          	jalr	-1590(ra) # 800047b8 <end_op>

  return fd;
}
    80005df6:	8526                	mv	a0,s1
    80005df8:	70ea                	ld	ra,184(sp)
    80005dfa:	744a                	ld	s0,176(sp)
    80005dfc:	74aa                	ld	s1,168(sp)
    80005dfe:	790a                	ld	s2,160(sp)
    80005e00:	69ea                	ld	s3,152(sp)
    80005e02:	6129                	addi	sp,sp,192
    80005e04:	8082                	ret
      end_op();
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	9b2080e7          	jalr	-1614(ra) # 800047b8 <end_op>
      return -1;
    80005e0e:	b7e5                	j	80005df6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e10:	f5040513          	addi	a0,s0,-176
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	704080e7          	jalr	1796(ra) # 80004518 <namei>
    80005e1c:	892a                	mv	s2,a0
    80005e1e:	c905                	beqz	a0,80005e4e <sys_open+0x13c>
    ilock(ip);
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	f42080e7          	jalr	-190(ra) # 80003d62 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e28:	04491703          	lh	a4,68(s2)
    80005e2c:	4785                	li	a5,1
    80005e2e:	f4f712e3          	bne	a4,a5,80005d72 <sys_open+0x60>
    80005e32:	f4c42783          	lw	a5,-180(s0)
    80005e36:	dba1                	beqz	a5,80005d86 <sys_open+0x74>
      iunlockput(ip);
    80005e38:	854a                	mv	a0,s2
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	18a080e7          	jalr	394(ra) # 80003fc4 <iunlockput>
      end_op();
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	976080e7          	jalr	-1674(ra) # 800047b8 <end_op>
      return -1;
    80005e4a:	54fd                	li	s1,-1
    80005e4c:	b76d                	j	80005df6 <sys_open+0xe4>
      end_op();
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	96a080e7          	jalr	-1686(ra) # 800047b8 <end_op>
      return -1;
    80005e56:	54fd                	li	s1,-1
    80005e58:	bf79                	j	80005df6 <sys_open+0xe4>
    iunlockput(ip);
    80005e5a:	854a                	mv	a0,s2
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	168080e7          	jalr	360(ra) # 80003fc4 <iunlockput>
    end_op();
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	954080e7          	jalr	-1708(ra) # 800047b8 <end_op>
    return -1;
    80005e6c:	54fd                	li	s1,-1
    80005e6e:	b761                	j	80005df6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e70:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e74:	04691783          	lh	a5,70(s2)
    80005e78:	02f99223          	sh	a5,36(s3)
    80005e7c:	bf2d                	j	80005db6 <sys_open+0xa4>
    itrunc(ip);
    80005e7e:	854a                	mv	a0,s2
    80005e80:	ffffe097          	auipc	ra,0xffffe
    80005e84:	ff0080e7          	jalr	-16(ra) # 80003e70 <itrunc>
    80005e88:	bfb1                	j	80005de4 <sys_open+0xd2>
      fileclose(f);
    80005e8a:	854e                	mv	a0,s3
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	d78080e7          	jalr	-648(ra) # 80004c04 <fileclose>
    iunlockput(ip);
    80005e94:	854a                	mv	a0,s2
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	12e080e7          	jalr	302(ra) # 80003fc4 <iunlockput>
    end_op();
    80005e9e:	fffff097          	auipc	ra,0xfffff
    80005ea2:	91a080e7          	jalr	-1766(ra) # 800047b8 <end_op>
    return -1;
    80005ea6:	54fd                	li	s1,-1
    80005ea8:	b7b9                	j	80005df6 <sys_open+0xe4>

0000000080005eaa <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005eaa:	7175                	addi	sp,sp,-144
    80005eac:	e506                	sd	ra,136(sp)
    80005eae:	e122                	sd	s0,128(sp)
    80005eb0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	886080e7          	jalr	-1914(ra) # 80004738 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005eba:	08000613          	li	a2,128
    80005ebe:	f7040593          	addi	a1,s0,-144
    80005ec2:	4501                	li	a0,0
    80005ec4:	ffffd097          	auipc	ra,0xffffd
    80005ec8:	29e080e7          	jalr	670(ra) # 80003162 <argstr>
    80005ecc:	02054963          	bltz	a0,80005efe <sys_mkdir+0x54>
    80005ed0:	4681                	li	a3,0
    80005ed2:	4601                	li	a2,0
    80005ed4:	4585                	li	a1,1
    80005ed6:	f7040513          	addi	a0,s0,-144
    80005eda:	fffff097          	auipc	ra,0xfffff
    80005ede:	7fe080e7          	jalr	2046(ra) # 800056d8 <create>
    80005ee2:	cd11                	beqz	a0,80005efe <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ee4:	ffffe097          	auipc	ra,0xffffe
    80005ee8:	0e0080e7          	jalr	224(ra) # 80003fc4 <iunlockput>
  end_op();
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	8cc080e7          	jalr	-1844(ra) # 800047b8 <end_op>
  return 0;
    80005ef4:	4501                	li	a0,0
}
    80005ef6:	60aa                	ld	ra,136(sp)
    80005ef8:	640a                	ld	s0,128(sp)
    80005efa:	6149                	addi	sp,sp,144
    80005efc:	8082                	ret
    end_op();
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	8ba080e7          	jalr	-1862(ra) # 800047b8 <end_op>
    return -1;
    80005f06:	557d                	li	a0,-1
    80005f08:	b7fd                	j	80005ef6 <sys_mkdir+0x4c>

0000000080005f0a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f0a:	7135                	addi	sp,sp,-160
    80005f0c:	ed06                	sd	ra,152(sp)
    80005f0e:	e922                	sd	s0,144(sp)
    80005f10:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f12:	fffff097          	auipc	ra,0xfffff
    80005f16:	826080e7          	jalr	-2010(ra) # 80004738 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f1a:	08000613          	li	a2,128
    80005f1e:	f7040593          	addi	a1,s0,-144
    80005f22:	4501                	li	a0,0
    80005f24:	ffffd097          	auipc	ra,0xffffd
    80005f28:	23e080e7          	jalr	574(ra) # 80003162 <argstr>
    80005f2c:	04054a63          	bltz	a0,80005f80 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f30:	f6c40593          	addi	a1,s0,-148
    80005f34:	4505                	li	a0,1
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	1e8080e7          	jalr	488(ra) # 8000311e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f3e:	04054163          	bltz	a0,80005f80 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f42:	f6840593          	addi	a1,s0,-152
    80005f46:	4509                	li	a0,2
    80005f48:	ffffd097          	auipc	ra,0xffffd
    80005f4c:	1d6080e7          	jalr	470(ra) # 8000311e <argint>
     argint(1, &major) < 0 ||
    80005f50:	02054863          	bltz	a0,80005f80 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f54:	f6841683          	lh	a3,-152(s0)
    80005f58:	f6c41603          	lh	a2,-148(s0)
    80005f5c:	458d                	li	a1,3
    80005f5e:	f7040513          	addi	a0,s0,-144
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	776080e7          	jalr	1910(ra) # 800056d8 <create>
     argint(2, &minor) < 0 ||
    80005f6a:	c919                	beqz	a0,80005f80 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f6c:	ffffe097          	auipc	ra,0xffffe
    80005f70:	058080e7          	jalr	88(ra) # 80003fc4 <iunlockput>
  end_op();
    80005f74:	fffff097          	auipc	ra,0xfffff
    80005f78:	844080e7          	jalr	-1980(ra) # 800047b8 <end_op>
  return 0;
    80005f7c:	4501                	li	a0,0
    80005f7e:	a031                	j	80005f8a <sys_mknod+0x80>
    end_op();
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	838080e7          	jalr	-1992(ra) # 800047b8 <end_op>
    return -1;
    80005f88:	557d                	li	a0,-1
}
    80005f8a:	60ea                	ld	ra,152(sp)
    80005f8c:	644a                	ld	s0,144(sp)
    80005f8e:	610d                	addi	sp,sp,160
    80005f90:	8082                	ret

0000000080005f92 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f92:	7135                	addi	sp,sp,-160
    80005f94:	ed06                	sd	ra,152(sp)
    80005f96:	e922                	sd	s0,144(sp)
    80005f98:	e526                	sd	s1,136(sp)
    80005f9a:	e14a                	sd	s2,128(sp)
    80005f9c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f9e:	ffffc097          	auipc	ra,0xffffc
    80005fa2:	a16080e7          	jalr	-1514(ra) # 800019b4 <myproc>
    80005fa6:	892a                	mv	s2,a0
  
  begin_op();
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	790080e7          	jalr	1936(ra) # 80004738 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fb0:	08000613          	li	a2,128
    80005fb4:	f6040593          	addi	a1,s0,-160
    80005fb8:	4501                	li	a0,0
    80005fba:	ffffd097          	auipc	ra,0xffffd
    80005fbe:	1a8080e7          	jalr	424(ra) # 80003162 <argstr>
    80005fc2:	04054b63          	bltz	a0,80006018 <sys_chdir+0x86>
    80005fc6:	f6040513          	addi	a0,s0,-160
    80005fca:	ffffe097          	auipc	ra,0xffffe
    80005fce:	54e080e7          	jalr	1358(ra) # 80004518 <namei>
    80005fd2:	84aa                	mv	s1,a0
    80005fd4:	c131                	beqz	a0,80006018 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	d8c080e7          	jalr	-628(ra) # 80003d62 <ilock>
  if(ip->type != T_DIR){
    80005fde:	04449703          	lh	a4,68(s1)
    80005fe2:	4785                	li	a5,1
    80005fe4:	04f71063          	bne	a4,a5,80006024 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005fe8:	8526                	mv	a0,s1
    80005fea:	ffffe097          	auipc	ra,0xffffe
    80005fee:	e3a080e7          	jalr	-454(ra) # 80003e24 <iunlock>
  iput(p->cwd);
    80005ff2:	2e893503          	ld	a0,744(s2)
    80005ff6:	ffffe097          	auipc	ra,0xffffe
    80005ffa:	f26080e7          	jalr	-218(ra) # 80003f1c <iput>
  end_op();
    80005ffe:	ffffe097          	auipc	ra,0xffffe
    80006002:	7ba080e7          	jalr	1978(ra) # 800047b8 <end_op>
  p->cwd = ip;
    80006006:	2e993423          	sd	s1,744(s2)
  return 0;
    8000600a:	4501                	li	a0,0
}
    8000600c:	60ea                	ld	ra,152(sp)
    8000600e:	644a                	ld	s0,144(sp)
    80006010:	64aa                	ld	s1,136(sp)
    80006012:	690a                	ld	s2,128(sp)
    80006014:	610d                	addi	sp,sp,160
    80006016:	8082                	ret
    end_op();
    80006018:	ffffe097          	auipc	ra,0xffffe
    8000601c:	7a0080e7          	jalr	1952(ra) # 800047b8 <end_op>
    return -1;
    80006020:	557d                	li	a0,-1
    80006022:	b7ed                	j	8000600c <sys_chdir+0x7a>
    iunlockput(ip);
    80006024:	8526                	mv	a0,s1
    80006026:	ffffe097          	auipc	ra,0xffffe
    8000602a:	f9e080e7          	jalr	-98(ra) # 80003fc4 <iunlockput>
    end_op();
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	78a080e7          	jalr	1930(ra) # 800047b8 <end_op>
    return -1;
    80006036:	557d                	li	a0,-1
    80006038:	bfd1                	j	8000600c <sys_chdir+0x7a>

000000008000603a <sys_exec>:

uint64
sys_exec(void)
{
    8000603a:	7145                	addi	sp,sp,-464
    8000603c:	e786                	sd	ra,456(sp)
    8000603e:	e3a2                	sd	s0,448(sp)
    80006040:	ff26                	sd	s1,440(sp)
    80006042:	fb4a                	sd	s2,432(sp)
    80006044:	f74e                	sd	s3,424(sp)
    80006046:	f352                	sd	s4,416(sp)
    80006048:	ef56                	sd	s5,408(sp)
    8000604a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000604c:	08000613          	li	a2,128
    80006050:	f4040593          	addi	a1,s0,-192
    80006054:	4501                	li	a0,0
    80006056:	ffffd097          	auipc	ra,0xffffd
    8000605a:	10c080e7          	jalr	268(ra) # 80003162 <argstr>
    return -1;
    8000605e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006060:	0c054a63          	bltz	a0,80006134 <sys_exec+0xfa>
    80006064:	e3840593          	addi	a1,s0,-456
    80006068:	4505                	li	a0,1
    8000606a:	ffffd097          	auipc	ra,0xffffd
    8000606e:	0d6080e7          	jalr	214(ra) # 80003140 <argaddr>
    80006072:	0c054163          	bltz	a0,80006134 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006076:	10000613          	li	a2,256
    8000607a:	4581                	li	a1,0
    8000607c:	e4040513          	addi	a0,s0,-448
    80006080:	ffffb097          	auipc	ra,0xffffb
    80006084:	c62080e7          	jalr	-926(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006088:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000608c:	89a6                	mv	s3,s1
    8000608e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006090:	02000a13          	li	s4,32
    80006094:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006098:	00391793          	slli	a5,s2,0x3
    8000609c:	e3040593          	addi	a1,s0,-464
    800060a0:	e3843503          	ld	a0,-456(s0)
    800060a4:	953e                	add	a0,a0,a5
    800060a6:	ffffd097          	auipc	ra,0xffffd
    800060aa:	fd8080e7          	jalr	-40(ra) # 8000307e <fetchaddr>
    800060ae:	02054a63          	bltz	a0,800060e2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060b2:	e3043783          	ld	a5,-464(s0)
    800060b6:	c3b9                	beqz	a5,800060fc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060b8:	ffffb097          	auipc	ra,0xffffb
    800060bc:	a1a080e7          	jalr	-1510(ra) # 80000ad2 <kalloc>
    800060c0:	85aa                	mv	a1,a0
    800060c2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060c6:	cd11                	beqz	a0,800060e2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060c8:	6605                	lui	a2,0x1
    800060ca:	e3043503          	ld	a0,-464(s0)
    800060ce:	ffffd097          	auipc	ra,0xffffd
    800060d2:	006080e7          	jalr	6(ra) # 800030d4 <fetchstr>
    800060d6:	00054663          	bltz	a0,800060e2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800060da:	0905                	addi	s2,s2,1
    800060dc:	09a1                	addi	s3,s3,8
    800060de:	fb491be3          	bne	s2,s4,80006094 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060e2:	10048913          	addi	s2,s1,256
    800060e6:	6088                	ld	a0,0(s1)
    800060e8:	c529                	beqz	a0,80006132 <sys_exec+0xf8>
    kfree(argv[i]);
    800060ea:	ffffb097          	auipc	ra,0xffffb
    800060ee:	8ec080e7          	jalr	-1812(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060f2:	04a1                	addi	s1,s1,8
    800060f4:	ff2499e3          	bne	s1,s2,800060e6 <sys_exec+0xac>
  return -1;
    800060f8:	597d                	li	s2,-1
    800060fa:	a82d                	j	80006134 <sys_exec+0xfa>
      argv[i] = 0;
    800060fc:	0a8e                	slli	s5,s5,0x3
    800060fe:	fc040793          	addi	a5,s0,-64
    80006102:	9abe                	add	s5,s5,a5
    80006104:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006108:	e4040593          	addi	a1,s0,-448
    8000610c:	f4040513          	addi	a0,s0,-192
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	146080e7          	jalr	326(ra) # 80005256 <exec>
    80006118:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000611a:	10048993          	addi	s3,s1,256
    8000611e:	6088                	ld	a0,0(s1)
    80006120:	c911                	beqz	a0,80006134 <sys_exec+0xfa>
    kfree(argv[i]);
    80006122:	ffffb097          	auipc	ra,0xffffb
    80006126:	8b4080e7          	jalr	-1868(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000612a:	04a1                	addi	s1,s1,8
    8000612c:	ff3499e3          	bne	s1,s3,8000611e <sys_exec+0xe4>
    80006130:	a011                	j	80006134 <sys_exec+0xfa>
  return -1;
    80006132:	597d                	li	s2,-1
}
    80006134:	854a                	mv	a0,s2
    80006136:	60be                	ld	ra,456(sp)
    80006138:	641e                	ld	s0,448(sp)
    8000613a:	74fa                	ld	s1,440(sp)
    8000613c:	795a                	ld	s2,432(sp)
    8000613e:	79ba                	ld	s3,424(sp)
    80006140:	7a1a                	ld	s4,416(sp)
    80006142:	6afa                	ld	s5,408(sp)
    80006144:	6179                	addi	sp,sp,464
    80006146:	8082                	ret

0000000080006148 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006148:	7139                	addi	sp,sp,-64
    8000614a:	fc06                	sd	ra,56(sp)
    8000614c:	f822                	sd	s0,48(sp)
    8000614e:	f426                	sd	s1,40(sp)
    80006150:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	862080e7          	jalr	-1950(ra) # 800019b4 <myproc>
    8000615a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000615c:	fd840593          	addi	a1,s0,-40
    80006160:	4501                	li	a0,0
    80006162:	ffffd097          	auipc	ra,0xffffd
    80006166:	fde080e7          	jalr	-34(ra) # 80003140 <argaddr>
    return -1;
    8000616a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000616c:	0e054463          	bltz	a0,80006254 <sys_pipe+0x10c>
  if(pipealloc(&rf, &wf) < 0)
    80006170:	fc840593          	addi	a1,s0,-56
    80006174:	fd040513          	addi	a0,s0,-48
    80006178:	fffff097          	auipc	ra,0xfffff
    8000617c:	dbc080e7          	jalr	-580(ra) # 80004f34 <pipealloc>
    return -1;
    80006180:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006182:	0c054963          	bltz	a0,80006254 <sys_pipe+0x10c>
  fd0 = -1;
    80006186:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000618a:	fd043503          	ld	a0,-48(s0)
    8000618e:	fffff097          	auipc	ra,0xfffff
    80006192:	508080e7          	jalr	1288(ra) # 80005696 <fdalloc>
    80006196:	fca42223          	sw	a0,-60(s0)
    8000619a:	0a054063          	bltz	a0,8000623a <sys_pipe+0xf2>
    8000619e:	fc843503          	ld	a0,-56(s0)
    800061a2:	fffff097          	auipc	ra,0xfffff
    800061a6:	4f4080e7          	jalr	1268(ra) # 80005696 <fdalloc>
    800061aa:	fca42023          	sw	a0,-64(s0)
    800061ae:	06054c63          	bltz	a0,80006226 <sys_pipe+0xde>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061b2:	4691                	li	a3,4
    800061b4:	fc440613          	addi	a2,s0,-60
    800061b8:	fd843583          	ld	a1,-40(s0)
    800061bc:	1e84b503          	ld	a0,488(s1)
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	4b2080e7          	jalr	1202(ra) # 80001672 <copyout>
    800061c8:	02054163          	bltz	a0,800061ea <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061cc:	4691                	li	a3,4
    800061ce:	fc040613          	addi	a2,s0,-64
    800061d2:	fd843583          	ld	a1,-40(s0)
    800061d6:	0591                	addi	a1,a1,4
    800061d8:	1e84b503          	ld	a0,488(s1)
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	496080e7          	jalr	1174(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061e4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061e6:	06055763          	bgez	a0,80006254 <sys_pipe+0x10c>
    p->ofile[fd0] = 0;
    800061ea:	fc442783          	lw	a5,-60(s0)
    800061ee:	04c78793          	addi	a5,a5,76
    800061f2:	078e                	slli	a5,a5,0x3
    800061f4:	97a6                	add	a5,a5,s1
    800061f6:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800061fa:	fc042503          	lw	a0,-64(s0)
    800061fe:	04c50513          	addi	a0,a0,76
    80006202:	050e                	slli	a0,a0,0x3
    80006204:	9526                	add	a0,a0,s1
    80006206:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000620a:	fd043503          	ld	a0,-48(s0)
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	9f6080e7          	jalr	-1546(ra) # 80004c04 <fileclose>
    fileclose(wf);
    80006216:	fc843503          	ld	a0,-56(s0)
    8000621a:	fffff097          	auipc	ra,0xfffff
    8000621e:	9ea080e7          	jalr	-1558(ra) # 80004c04 <fileclose>
    return -1;
    80006222:	57fd                	li	a5,-1
    80006224:	a805                	j	80006254 <sys_pipe+0x10c>
    if(fd0 >= 0)
    80006226:	fc442783          	lw	a5,-60(s0)
    8000622a:	0007c863          	bltz	a5,8000623a <sys_pipe+0xf2>
      p->ofile[fd0] = 0;
    8000622e:	04c78513          	addi	a0,a5,76
    80006232:	050e                	slli	a0,a0,0x3
    80006234:	9526                	add	a0,a0,s1
    80006236:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000623a:	fd043503          	ld	a0,-48(s0)
    8000623e:	fffff097          	auipc	ra,0xfffff
    80006242:	9c6080e7          	jalr	-1594(ra) # 80004c04 <fileclose>
    fileclose(wf);
    80006246:	fc843503          	ld	a0,-56(s0)
    8000624a:	fffff097          	auipc	ra,0xfffff
    8000624e:	9ba080e7          	jalr	-1606(ra) # 80004c04 <fileclose>
    return -1;
    80006252:	57fd                	li	a5,-1
}
    80006254:	853e                	mv	a0,a5
    80006256:	70e2                	ld	ra,56(sp)
    80006258:	7442                	ld	s0,48(sp)
    8000625a:	74a2                	ld	s1,40(sp)
    8000625c:	6121                	addi	sp,sp,64
    8000625e:	8082                	ret

0000000080006260 <kernelvec>:
    80006260:	7111                	addi	sp,sp,-256
    80006262:	e006                	sd	ra,0(sp)
    80006264:	e40a                	sd	sp,8(sp)
    80006266:	e80e                	sd	gp,16(sp)
    80006268:	ec12                	sd	tp,24(sp)
    8000626a:	f016                	sd	t0,32(sp)
    8000626c:	f41a                	sd	t1,40(sp)
    8000626e:	f81e                	sd	t2,48(sp)
    80006270:	fc22                	sd	s0,56(sp)
    80006272:	e0a6                	sd	s1,64(sp)
    80006274:	e4aa                	sd	a0,72(sp)
    80006276:	e8ae                	sd	a1,80(sp)
    80006278:	ecb2                	sd	a2,88(sp)
    8000627a:	f0b6                	sd	a3,96(sp)
    8000627c:	f4ba                	sd	a4,104(sp)
    8000627e:	f8be                	sd	a5,112(sp)
    80006280:	fcc2                	sd	a6,120(sp)
    80006282:	e146                	sd	a7,128(sp)
    80006284:	e54a                	sd	s2,136(sp)
    80006286:	e94e                	sd	s3,144(sp)
    80006288:	ed52                	sd	s4,152(sp)
    8000628a:	f156                	sd	s5,160(sp)
    8000628c:	f55a                	sd	s6,168(sp)
    8000628e:	f95e                	sd	s7,176(sp)
    80006290:	fd62                	sd	s8,184(sp)
    80006292:	e1e6                	sd	s9,192(sp)
    80006294:	e5ea                	sd	s10,200(sp)
    80006296:	e9ee                	sd	s11,208(sp)
    80006298:	edf2                	sd	t3,216(sp)
    8000629a:	f1f6                	sd	t4,224(sp)
    8000629c:	f5fa                	sd	t5,232(sp)
    8000629e:	f9fe                	sd	t6,240(sp)
    800062a0:	c9ffc0ef          	jal	ra,80002f3e <kerneltrap>
    800062a4:	6082                	ld	ra,0(sp)
    800062a6:	6122                	ld	sp,8(sp)
    800062a8:	61c2                	ld	gp,16(sp)
    800062aa:	7282                	ld	t0,32(sp)
    800062ac:	7322                	ld	t1,40(sp)
    800062ae:	73c2                	ld	t2,48(sp)
    800062b0:	7462                	ld	s0,56(sp)
    800062b2:	6486                	ld	s1,64(sp)
    800062b4:	6526                	ld	a0,72(sp)
    800062b6:	65c6                	ld	a1,80(sp)
    800062b8:	6666                	ld	a2,88(sp)
    800062ba:	7686                	ld	a3,96(sp)
    800062bc:	7726                	ld	a4,104(sp)
    800062be:	77c6                	ld	a5,112(sp)
    800062c0:	7866                	ld	a6,120(sp)
    800062c2:	688a                	ld	a7,128(sp)
    800062c4:	692a                	ld	s2,136(sp)
    800062c6:	69ca                	ld	s3,144(sp)
    800062c8:	6a6a                	ld	s4,152(sp)
    800062ca:	7a8a                	ld	s5,160(sp)
    800062cc:	7b2a                	ld	s6,168(sp)
    800062ce:	7bca                	ld	s7,176(sp)
    800062d0:	7c6a                	ld	s8,184(sp)
    800062d2:	6c8e                	ld	s9,192(sp)
    800062d4:	6d2e                	ld	s10,200(sp)
    800062d6:	6dce                	ld	s11,208(sp)
    800062d8:	6e6e                	ld	t3,216(sp)
    800062da:	7e8e                	ld	t4,224(sp)
    800062dc:	7f2e                	ld	t5,232(sp)
    800062de:	7fce                	ld	t6,240(sp)
    800062e0:	6111                	addi	sp,sp,256
    800062e2:	10200073          	sret
    800062e6:	00000013          	nop
    800062ea:	00000013          	nop
    800062ee:	0001                	nop

00000000800062f0 <timervec>:
    800062f0:	34051573          	csrrw	a0,mscratch,a0
    800062f4:	e10c                	sd	a1,0(a0)
    800062f6:	e510                	sd	a2,8(a0)
    800062f8:	e914                	sd	a3,16(a0)
    800062fa:	6d0c                	ld	a1,24(a0)
    800062fc:	7110                	ld	a2,32(a0)
    800062fe:	6194                	ld	a3,0(a1)
    80006300:	96b2                	add	a3,a3,a2
    80006302:	e194                	sd	a3,0(a1)
    80006304:	4589                	li	a1,2
    80006306:	14459073          	csrw	sip,a1
    8000630a:	6914                	ld	a3,16(a0)
    8000630c:	6510                	ld	a2,8(a0)
    8000630e:	610c                	ld	a1,0(a0)
    80006310:	34051573          	csrrw	a0,mscratch,a0
    80006314:	30200073          	mret
	...

000000008000631a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000631a:	1141                	addi	sp,sp,-16
    8000631c:	e422                	sd	s0,8(sp)
    8000631e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006320:	0c0007b7          	lui	a5,0xc000
    80006324:	4705                	li	a4,1
    80006326:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006328:	c3d8                	sw	a4,4(a5)
}
    8000632a:	6422                	ld	s0,8(sp)
    8000632c:	0141                	addi	sp,sp,16
    8000632e:	8082                	ret

0000000080006330 <plicinithart>:

void
plicinithart(void)
{
    80006330:	1141                	addi	sp,sp,-16
    80006332:	e406                	sd	ra,8(sp)
    80006334:	e022                	sd	s0,0(sp)
    80006336:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006338:	ffffb097          	auipc	ra,0xffffb
    8000633c:	650080e7          	jalr	1616(ra) # 80001988 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006340:	0085171b          	slliw	a4,a0,0x8
    80006344:	0c0027b7          	lui	a5,0xc002
    80006348:	97ba                	add	a5,a5,a4
    8000634a:	40200713          	li	a4,1026
    8000634e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006352:	00d5151b          	slliw	a0,a0,0xd
    80006356:	0c2017b7          	lui	a5,0xc201
    8000635a:	953e                	add	a0,a0,a5
    8000635c:	00052023          	sw	zero,0(a0)
}
    80006360:	60a2                	ld	ra,8(sp)
    80006362:	6402                	ld	s0,0(sp)
    80006364:	0141                	addi	sp,sp,16
    80006366:	8082                	ret

0000000080006368 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006368:	1141                	addi	sp,sp,-16
    8000636a:	e406                	sd	ra,8(sp)
    8000636c:	e022                	sd	s0,0(sp)
    8000636e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	618080e7          	jalr	1560(ra) # 80001988 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006378:	00d5179b          	slliw	a5,a0,0xd
    8000637c:	0c201537          	lui	a0,0xc201
    80006380:	953e                	add	a0,a0,a5
  return irq;
}
    80006382:	4148                	lw	a0,4(a0)
    80006384:	60a2                	ld	ra,8(sp)
    80006386:	6402                	ld	s0,0(sp)
    80006388:	0141                	addi	sp,sp,16
    8000638a:	8082                	ret

000000008000638c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000638c:	1101                	addi	sp,sp,-32
    8000638e:	ec06                	sd	ra,24(sp)
    80006390:	e822                	sd	s0,16(sp)
    80006392:	e426                	sd	s1,8(sp)
    80006394:	1000                	addi	s0,sp,32
    80006396:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006398:	ffffb097          	auipc	ra,0xffffb
    8000639c:	5f0080e7          	jalr	1520(ra) # 80001988 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063a0:	00d5151b          	slliw	a0,a0,0xd
    800063a4:	0c2017b7          	lui	a5,0xc201
    800063a8:	97aa                	add	a5,a5,a0
    800063aa:	c3c4                	sw	s1,4(a5)
}
    800063ac:	60e2                	ld	ra,24(sp)
    800063ae:	6442                	ld	s0,16(sp)
    800063b0:	64a2                	ld	s1,8(sp)
    800063b2:	6105                	addi	sp,sp,32
    800063b4:	8082                	ret

00000000800063b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063b6:	1141                	addi	sp,sp,-16
    800063b8:	e406                	sd	ra,8(sp)
    800063ba:	e022                	sd	s0,0(sp)
    800063bc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063be:	479d                	li	a5,7
    800063c0:	06a7c963          	blt	a5,a0,80006432 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800063c4:	00023797          	auipc	a5,0x23
    800063c8:	c3c78793          	addi	a5,a5,-964 # 80029000 <disk>
    800063cc:	00a78733          	add	a4,a5,a0
    800063d0:	6789                	lui	a5,0x2
    800063d2:	97ba                	add	a5,a5,a4
    800063d4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800063d8:	e7ad                	bnez	a5,80006442 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063da:	00451793          	slli	a5,a0,0x4
    800063de:	00025717          	auipc	a4,0x25
    800063e2:	c2270713          	addi	a4,a4,-990 # 8002b000 <disk+0x2000>
    800063e6:	6314                	ld	a3,0(a4)
    800063e8:	96be                	add	a3,a3,a5
    800063ea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800063ee:	6314                	ld	a3,0(a4)
    800063f0:	96be                	add	a3,a3,a5
    800063f2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800063f6:	6314                	ld	a3,0(a4)
    800063f8:	96be                	add	a3,a3,a5
    800063fa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800063fe:	6318                	ld	a4,0(a4)
    80006400:	97ba                	add	a5,a5,a4
    80006402:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006406:	00023797          	auipc	a5,0x23
    8000640a:	bfa78793          	addi	a5,a5,-1030 # 80029000 <disk>
    8000640e:	97aa                	add	a5,a5,a0
    80006410:	6509                	lui	a0,0x2
    80006412:	953e                	add	a0,a0,a5
    80006414:	4785                	li	a5,1
    80006416:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000641a:	00025517          	auipc	a0,0x25
    8000641e:	bfe50513          	addi	a0,a0,-1026 # 8002b018 <disk+0x2018>
    80006422:	ffffc097          	auipc	ra,0xffffc
    80006426:	218080e7          	jalr	536(ra) # 8000263a <wakeup>
}
    8000642a:	60a2                	ld	ra,8(sp)
    8000642c:	6402                	ld	s0,0(sp)
    8000642e:	0141                	addi	sp,sp,16
    80006430:	8082                	ret
    panic("free_desc 1");
    80006432:	00002517          	auipc	a0,0x2
    80006436:	48650513          	addi	a0,a0,1158 # 800088b8 <syscalls+0x338>
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	0f0080e7          	jalr	240(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006442:	00002517          	auipc	a0,0x2
    80006446:	48650513          	addi	a0,a0,1158 # 800088c8 <syscalls+0x348>
    8000644a:	ffffa097          	auipc	ra,0xffffa
    8000644e:	0e0080e7          	jalr	224(ra) # 8000052a <panic>

0000000080006452 <virtio_disk_init>:
{
    80006452:	1101                	addi	sp,sp,-32
    80006454:	ec06                	sd	ra,24(sp)
    80006456:	e822                	sd	s0,16(sp)
    80006458:	e426                	sd	s1,8(sp)
    8000645a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000645c:	00002597          	auipc	a1,0x2
    80006460:	47c58593          	addi	a1,a1,1148 # 800088d8 <syscalls+0x358>
    80006464:	00025517          	auipc	a0,0x25
    80006468:	cc450513          	addi	a0,a0,-828 # 8002b128 <disk+0x2128>
    8000646c:	ffffa097          	auipc	ra,0xffffa
    80006470:	6c6080e7          	jalr	1734(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006474:	100017b7          	lui	a5,0x10001
    80006478:	4398                	lw	a4,0(a5)
    8000647a:	2701                	sext.w	a4,a4
    8000647c:	747277b7          	lui	a5,0x74727
    80006480:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006484:	0ef71163          	bne	a4,a5,80006566 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006488:	100017b7          	lui	a5,0x10001
    8000648c:	43dc                	lw	a5,4(a5)
    8000648e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006490:	4705                	li	a4,1
    80006492:	0ce79a63          	bne	a5,a4,80006566 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006496:	100017b7          	lui	a5,0x10001
    8000649a:	479c                	lw	a5,8(a5)
    8000649c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000649e:	4709                	li	a4,2
    800064a0:	0ce79363          	bne	a5,a4,80006566 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064a4:	100017b7          	lui	a5,0x10001
    800064a8:	47d8                	lw	a4,12(a5)
    800064aa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ac:	554d47b7          	lui	a5,0x554d4
    800064b0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064b4:	0af71963          	bne	a4,a5,80006566 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064b8:	100017b7          	lui	a5,0x10001
    800064bc:	4705                	li	a4,1
    800064be:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064c0:	470d                	li	a4,3
    800064c2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064c4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064c6:	c7ffe737          	lui	a4,0xc7ffe
    800064ca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd275f>
    800064ce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064d0:	2701                	sext.w	a4,a4
    800064d2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064d4:	472d                	li	a4,11
    800064d6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064d8:	473d                	li	a4,15
    800064da:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800064dc:	6705                	lui	a4,0x1
    800064de:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064e4:	5bdc                	lw	a5,52(a5)
    800064e6:	2781                	sext.w	a5,a5
  if(max == 0)
    800064e8:	c7d9                	beqz	a5,80006576 <virtio_disk_init+0x124>
  if(max < NUM)
    800064ea:	471d                	li	a4,7
    800064ec:	08f77d63          	bgeu	a4,a5,80006586 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800064f0:	100014b7          	lui	s1,0x10001
    800064f4:	47a1                	li	a5,8
    800064f6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800064f8:	6609                	lui	a2,0x2
    800064fa:	4581                	li	a1,0
    800064fc:	00023517          	auipc	a0,0x23
    80006500:	b0450513          	addi	a0,a0,-1276 # 80029000 <disk>
    80006504:	ffffa097          	auipc	ra,0xffffa
    80006508:	7de080e7          	jalr	2014(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000650c:	00023717          	auipc	a4,0x23
    80006510:	af470713          	addi	a4,a4,-1292 # 80029000 <disk>
    80006514:	00c75793          	srli	a5,a4,0xc
    80006518:	2781                	sext.w	a5,a5
    8000651a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000651c:	00025797          	auipc	a5,0x25
    80006520:	ae478793          	addi	a5,a5,-1308 # 8002b000 <disk+0x2000>
    80006524:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006526:	00023717          	auipc	a4,0x23
    8000652a:	b5a70713          	addi	a4,a4,-1190 # 80029080 <disk+0x80>
    8000652e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006530:	00024717          	auipc	a4,0x24
    80006534:	ad070713          	addi	a4,a4,-1328 # 8002a000 <disk+0x1000>
    80006538:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000653a:	4705                	li	a4,1
    8000653c:	00e78c23          	sb	a4,24(a5)
    80006540:	00e78ca3          	sb	a4,25(a5)
    80006544:	00e78d23          	sb	a4,26(a5)
    80006548:	00e78da3          	sb	a4,27(a5)
    8000654c:	00e78e23          	sb	a4,28(a5)
    80006550:	00e78ea3          	sb	a4,29(a5)
    80006554:	00e78f23          	sb	a4,30(a5)
    80006558:	00e78fa3          	sb	a4,31(a5)
}
    8000655c:	60e2                	ld	ra,24(sp)
    8000655e:	6442                	ld	s0,16(sp)
    80006560:	64a2                	ld	s1,8(sp)
    80006562:	6105                	addi	sp,sp,32
    80006564:	8082                	ret
    panic("could not find virtio disk");
    80006566:	00002517          	auipc	a0,0x2
    8000656a:	38250513          	addi	a0,a0,898 # 800088e8 <syscalls+0x368>
    8000656e:	ffffa097          	auipc	ra,0xffffa
    80006572:	fbc080e7          	jalr	-68(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006576:	00002517          	auipc	a0,0x2
    8000657a:	39250513          	addi	a0,a0,914 # 80008908 <syscalls+0x388>
    8000657e:	ffffa097          	auipc	ra,0xffffa
    80006582:	fac080e7          	jalr	-84(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006586:	00002517          	auipc	a0,0x2
    8000658a:	3a250513          	addi	a0,a0,930 # 80008928 <syscalls+0x3a8>
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	f9c080e7          	jalr	-100(ra) # 8000052a <panic>

0000000080006596 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006596:	7119                	addi	sp,sp,-128
    80006598:	fc86                	sd	ra,120(sp)
    8000659a:	f8a2                	sd	s0,112(sp)
    8000659c:	f4a6                	sd	s1,104(sp)
    8000659e:	f0ca                	sd	s2,96(sp)
    800065a0:	ecce                	sd	s3,88(sp)
    800065a2:	e8d2                	sd	s4,80(sp)
    800065a4:	e4d6                	sd	s5,72(sp)
    800065a6:	e0da                	sd	s6,64(sp)
    800065a8:	fc5e                	sd	s7,56(sp)
    800065aa:	f862                	sd	s8,48(sp)
    800065ac:	f466                	sd	s9,40(sp)
    800065ae:	f06a                	sd	s10,32(sp)
    800065b0:	ec6e                	sd	s11,24(sp)
    800065b2:	0100                	addi	s0,sp,128
    800065b4:	8aaa                	mv	s5,a0
    800065b6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065b8:	00c52c83          	lw	s9,12(a0)
    800065bc:	001c9c9b          	slliw	s9,s9,0x1
    800065c0:	1c82                	slli	s9,s9,0x20
    800065c2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800065c6:	00025517          	auipc	a0,0x25
    800065ca:	b6250513          	addi	a0,a0,-1182 # 8002b128 <disk+0x2128>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	5f4080e7          	jalr	1524(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    800065d6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800065d8:	44a1                	li	s1,8
      disk.free[i] = 0;
    800065da:	00023c17          	auipc	s8,0x23
    800065de:	a26c0c13          	addi	s8,s8,-1498 # 80029000 <disk>
    800065e2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800065e4:	4b0d                	li	s6,3
    800065e6:	a0ad                	j	80006650 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800065e8:	00fc0733          	add	a4,s8,a5
    800065ec:	975e                	add	a4,a4,s7
    800065ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800065f2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800065f4:	0207c563          	bltz	a5,8000661e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800065f8:	2905                	addiw	s2,s2,1
    800065fa:	0611                	addi	a2,a2,4
    800065fc:	19690d63          	beq	s2,s6,80006796 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006600:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006602:	00025717          	auipc	a4,0x25
    80006606:	a1670713          	addi	a4,a4,-1514 # 8002b018 <disk+0x2018>
    8000660a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000660c:	00074683          	lbu	a3,0(a4)
    80006610:	fee1                	bnez	a3,800065e8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006612:	2785                	addiw	a5,a5,1
    80006614:	0705                	addi	a4,a4,1
    80006616:	fe979be3          	bne	a5,s1,8000660c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000661a:	57fd                	li	a5,-1
    8000661c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000661e:	01205d63          	blez	s2,80006638 <virtio_disk_rw+0xa2>
    80006622:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006624:	000a2503          	lw	a0,0(s4)
    80006628:	00000097          	auipc	ra,0x0
    8000662c:	d8e080e7          	jalr	-626(ra) # 800063b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006630:	2d85                	addiw	s11,s11,1
    80006632:	0a11                	addi	s4,s4,4
    80006634:	ffb918e3          	bne	s2,s11,80006624 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006638:	00025597          	auipc	a1,0x25
    8000663c:	af058593          	addi	a1,a1,-1296 # 8002b128 <disk+0x2128>
    80006640:	00025517          	auipc	a0,0x25
    80006644:	9d850513          	addi	a0,a0,-1576 # 8002b018 <disk+0x2018>
    80006648:	ffffc097          	auipc	ra,0xffffc
    8000664c:	e64080e7          	jalr	-412(ra) # 800024ac <sleep>
  for(int i = 0; i < 3; i++){
    80006650:	f8040a13          	addi	s4,s0,-128
{
    80006654:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006656:	894e                	mv	s2,s3
    80006658:	b765                	j	80006600 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000665a:	00025697          	auipc	a3,0x25
    8000665e:	9a66b683          	ld	a3,-1626(a3) # 8002b000 <disk+0x2000>
    80006662:	96ba                	add	a3,a3,a4
    80006664:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006668:	00023817          	auipc	a6,0x23
    8000666c:	99880813          	addi	a6,a6,-1640 # 80029000 <disk>
    80006670:	00025697          	auipc	a3,0x25
    80006674:	99068693          	addi	a3,a3,-1648 # 8002b000 <disk+0x2000>
    80006678:	6290                	ld	a2,0(a3)
    8000667a:	963a                	add	a2,a2,a4
    8000667c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006680:	0015e593          	ori	a1,a1,1
    80006684:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006688:	f8842603          	lw	a2,-120(s0)
    8000668c:	628c                	ld	a1,0(a3)
    8000668e:	972e                	add	a4,a4,a1
    80006690:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006694:	20050593          	addi	a1,a0,512
    80006698:	0592                	slli	a1,a1,0x4
    8000669a:	95c2                	add	a1,a1,a6
    8000669c:	577d                	li	a4,-1
    8000669e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066a2:	00461713          	slli	a4,a2,0x4
    800066a6:	6290                	ld	a2,0(a3)
    800066a8:	963a                	add	a2,a2,a4
    800066aa:	03078793          	addi	a5,a5,48
    800066ae:	97c2                	add	a5,a5,a6
    800066b0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800066b2:	629c                	ld	a5,0(a3)
    800066b4:	97ba                	add	a5,a5,a4
    800066b6:	4605                	li	a2,1
    800066b8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066ba:	629c                	ld	a5,0(a3)
    800066bc:	97ba                	add	a5,a5,a4
    800066be:	4809                	li	a6,2
    800066c0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066c4:	629c                	ld	a5,0(a3)
    800066c6:	973e                	add	a4,a4,a5
    800066c8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066cc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800066d0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066d4:	6698                	ld	a4,8(a3)
    800066d6:	00275783          	lhu	a5,2(a4)
    800066da:	8b9d                	andi	a5,a5,7
    800066dc:	0786                	slli	a5,a5,0x1
    800066de:	97ba                	add	a5,a5,a4
    800066e0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    800066e4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066e8:	6698                	ld	a4,8(a3)
    800066ea:	00275783          	lhu	a5,2(a4)
    800066ee:	2785                	addiw	a5,a5,1
    800066f0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066f4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066f8:	100017b7          	lui	a5,0x10001
    800066fc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006700:	004aa783          	lw	a5,4(s5)
    80006704:	02c79163          	bne	a5,a2,80006726 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006708:	00025917          	auipc	s2,0x25
    8000670c:	a2090913          	addi	s2,s2,-1504 # 8002b128 <disk+0x2128>
  while(b->disk == 1) {
    80006710:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006712:	85ca                	mv	a1,s2
    80006714:	8556                	mv	a0,s5
    80006716:	ffffc097          	auipc	ra,0xffffc
    8000671a:	d96080e7          	jalr	-618(ra) # 800024ac <sleep>
  while(b->disk == 1) {
    8000671e:	004aa783          	lw	a5,4(s5)
    80006722:	fe9788e3          	beq	a5,s1,80006712 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006726:	f8042903          	lw	s2,-128(s0)
    8000672a:	20090793          	addi	a5,s2,512
    8000672e:	00479713          	slli	a4,a5,0x4
    80006732:	00023797          	auipc	a5,0x23
    80006736:	8ce78793          	addi	a5,a5,-1842 # 80029000 <disk>
    8000673a:	97ba                	add	a5,a5,a4
    8000673c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006740:	00025997          	auipc	s3,0x25
    80006744:	8c098993          	addi	s3,s3,-1856 # 8002b000 <disk+0x2000>
    80006748:	00491713          	slli	a4,s2,0x4
    8000674c:	0009b783          	ld	a5,0(s3)
    80006750:	97ba                	add	a5,a5,a4
    80006752:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006756:	854a                	mv	a0,s2
    80006758:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000675c:	00000097          	auipc	ra,0x0
    80006760:	c5a080e7          	jalr	-934(ra) # 800063b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006764:	8885                	andi	s1,s1,1
    80006766:	f0ed                	bnez	s1,80006748 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006768:	00025517          	auipc	a0,0x25
    8000676c:	9c050513          	addi	a0,a0,-1600 # 8002b128 <disk+0x2128>
    80006770:	ffffa097          	auipc	ra,0xffffa
    80006774:	518080e7          	jalr	1304(ra) # 80000c88 <release>
}
    80006778:	70e6                	ld	ra,120(sp)
    8000677a:	7446                	ld	s0,112(sp)
    8000677c:	74a6                	ld	s1,104(sp)
    8000677e:	7906                	ld	s2,96(sp)
    80006780:	69e6                	ld	s3,88(sp)
    80006782:	6a46                	ld	s4,80(sp)
    80006784:	6aa6                	ld	s5,72(sp)
    80006786:	6b06                	ld	s6,64(sp)
    80006788:	7be2                	ld	s7,56(sp)
    8000678a:	7c42                	ld	s8,48(sp)
    8000678c:	7ca2                	ld	s9,40(sp)
    8000678e:	7d02                	ld	s10,32(sp)
    80006790:	6de2                	ld	s11,24(sp)
    80006792:	6109                	addi	sp,sp,128
    80006794:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006796:	f8042503          	lw	a0,-128(s0)
    8000679a:	20050793          	addi	a5,a0,512
    8000679e:	0792                	slli	a5,a5,0x4
  if(write)
    800067a0:	00023817          	auipc	a6,0x23
    800067a4:	86080813          	addi	a6,a6,-1952 # 80029000 <disk>
    800067a8:	00f80733          	add	a4,a6,a5
    800067ac:	01a036b3          	snez	a3,s10
    800067b0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800067b4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800067b8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800067bc:	7679                	lui	a2,0xffffe
    800067be:	963e                	add	a2,a2,a5
    800067c0:	00025697          	auipc	a3,0x25
    800067c4:	84068693          	addi	a3,a3,-1984 # 8002b000 <disk+0x2000>
    800067c8:	6298                	ld	a4,0(a3)
    800067ca:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067cc:	0a878593          	addi	a1,a5,168
    800067d0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800067d2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800067d4:	6298                	ld	a4,0(a3)
    800067d6:	9732                	add	a4,a4,a2
    800067d8:	45c1                	li	a1,16
    800067da:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800067dc:	6298                	ld	a4,0(a3)
    800067de:	9732                	add	a4,a4,a2
    800067e0:	4585                	li	a1,1
    800067e2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800067e6:	f8442703          	lw	a4,-124(s0)
    800067ea:	628c                	ld	a1,0(a3)
    800067ec:	962e                	add	a2,a2,a1
    800067ee:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd200e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800067f2:	0712                	slli	a4,a4,0x4
    800067f4:	6290                	ld	a2,0(a3)
    800067f6:	963a                	add	a2,a2,a4
    800067f8:	058a8593          	addi	a1,s5,88
    800067fc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800067fe:	6294                	ld	a3,0(a3)
    80006800:	96ba                	add	a3,a3,a4
    80006802:	40000613          	li	a2,1024
    80006806:	c690                	sw	a2,8(a3)
  if(write)
    80006808:	e40d19e3          	bnez	s10,8000665a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000680c:	00024697          	auipc	a3,0x24
    80006810:	7f46b683          	ld	a3,2036(a3) # 8002b000 <disk+0x2000>
    80006814:	96ba                	add	a3,a3,a4
    80006816:	4609                	li	a2,2
    80006818:	00c69623          	sh	a2,12(a3)
    8000681c:	b5b1                	j	80006668 <virtio_disk_rw+0xd2>

000000008000681e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000681e:	1101                	addi	sp,sp,-32
    80006820:	ec06                	sd	ra,24(sp)
    80006822:	e822                	sd	s0,16(sp)
    80006824:	e426                	sd	s1,8(sp)
    80006826:	e04a                	sd	s2,0(sp)
    80006828:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000682a:	00025517          	auipc	a0,0x25
    8000682e:	8fe50513          	addi	a0,a0,-1794 # 8002b128 <disk+0x2128>
    80006832:	ffffa097          	auipc	ra,0xffffa
    80006836:	390080e7          	jalr	912(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000683a:	10001737          	lui	a4,0x10001
    8000683e:	533c                	lw	a5,96(a4)
    80006840:	8b8d                	andi	a5,a5,3
    80006842:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006844:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006848:	00024797          	auipc	a5,0x24
    8000684c:	7b878793          	addi	a5,a5,1976 # 8002b000 <disk+0x2000>
    80006850:	6b94                	ld	a3,16(a5)
    80006852:	0207d703          	lhu	a4,32(a5)
    80006856:	0026d783          	lhu	a5,2(a3)
    8000685a:	06f70163          	beq	a4,a5,800068bc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000685e:	00022917          	auipc	s2,0x22
    80006862:	7a290913          	addi	s2,s2,1954 # 80029000 <disk>
    80006866:	00024497          	auipc	s1,0x24
    8000686a:	79a48493          	addi	s1,s1,1946 # 8002b000 <disk+0x2000>
    __sync_synchronize();
    8000686e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006872:	6898                	ld	a4,16(s1)
    80006874:	0204d783          	lhu	a5,32(s1)
    80006878:	8b9d                	andi	a5,a5,7
    8000687a:	078e                	slli	a5,a5,0x3
    8000687c:	97ba                	add	a5,a5,a4
    8000687e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006880:	20078713          	addi	a4,a5,512
    80006884:	0712                	slli	a4,a4,0x4
    80006886:	974a                	add	a4,a4,s2
    80006888:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000688c:	e731                	bnez	a4,800068d8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000688e:	20078793          	addi	a5,a5,512
    80006892:	0792                	slli	a5,a5,0x4
    80006894:	97ca                	add	a5,a5,s2
    80006896:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006898:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000689c:	ffffc097          	auipc	ra,0xffffc
    800068a0:	d9e080e7          	jalr	-610(ra) # 8000263a <wakeup>

    disk.used_idx += 1;
    800068a4:	0204d783          	lhu	a5,32(s1)
    800068a8:	2785                	addiw	a5,a5,1
    800068aa:	17c2                	slli	a5,a5,0x30
    800068ac:	93c1                	srli	a5,a5,0x30
    800068ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068b2:	6898                	ld	a4,16(s1)
    800068b4:	00275703          	lhu	a4,2(a4)
    800068b8:	faf71be3          	bne	a4,a5,8000686e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800068bc:	00025517          	auipc	a0,0x25
    800068c0:	86c50513          	addi	a0,a0,-1940 # 8002b128 <disk+0x2128>
    800068c4:	ffffa097          	auipc	ra,0xffffa
    800068c8:	3c4080e7          	jalr	964(ra) # 80000c88 <release>
}
    800068cc:	60e2                	ld	ra,24(sp)
    800068ce:	6442                	ld	s0,16(sp)
    800068d0:	64a2                	ld	s1,8(sp)
    800068d2:	6902                	ld	s2,0(sp)
    800068d4:	6105                	addi	sp,sp,32
    800068d6:	8082                	ret
      panic("virtio_disk_intr status");
    800068d8:	00002517          	auipc	a0,0x2
    800068dc:	07050513          	addi	a0,a0,112 # 80008948 <syscalls+0x3c8>
    800068e0:	ffffa097          	auipc	ra,0xffffa
    800068e4:	c4a080e7          	jalr	-950(ra) # 8000052a <panic>
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
