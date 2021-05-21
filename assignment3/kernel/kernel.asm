
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
    80000064:	00007797          	auipc	a5,0x7
    80000068:	97c78793          	addi	a5,a5,-1668 # 800069e0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd07ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd078793          	addi	a5,a5,-560 # 80000e7e <main>
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
    80000122:	012080e7          	jalr	18(ra) # 80002130 <either_copyin>
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
    800001b6:	834080e7          	jalr	-1996(ra) # 800019e6 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	d72080e7          	jalr	-654(ra) # 80001f34 <sleep>
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
    80000202:	edc080e7          	jalr	-292(ra) # 800020da <either_copyout>
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
    800002e2:	ea8080e7          	jalr	-344(ra) # 80002186 <procdump>
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
    80000436:	b66080e7          	jalr	-1178(ra) # 80001f98 <wakeup>
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
    80000464:	00029797          	auipc	a5,0x29
    80000468:	2b478793          	addi	a5,a5,692 # 80029718 <devsw>
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
    8000055c:	b9050513          	addi	a0,a0,-1136 # 800080e8 <digits+0xa8>
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
    8000087e:	00001097          	auipc	ra,0x1
    80000882:	71a080e7          	jalr	1818(ra) # 80001f98 <wakeup>
    
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
    8000090e:	62a080e7          	jalr	1578(ra) # 80001f34 <sleep>
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
    800009ea:	0002d797          	auipc	a5,0x2d
    800009ee:	61678793          	addi	a5,a5,1558 # 8002e000 <end>
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
    80000a06:	2ce080e7          	jalr	718(ra) # 80000cd0 <memset>

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
    80000aba:	0002d517          	auipc	a0,0x2d
    80000abe:	54650513          	addi	a0,a0,1350 # 8002e000 <end>
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
    80000b10:	1c4080e7          	jalr	452(ra) # 80000cd0 <memset>
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
    80000b60:	e6e080e7          	jalr	-402(ra) # 800019ca <mycpu>
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
    80000b92:	e3c080e7          	jalr	-452(ra) # 800019ca <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e30080e7          	jalr	-464(ra) # 800019ca <mycpu>
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
    80000bb6:	e18080e7          	jalr	-488(ra) # 800019ca <mycpu>
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
  if(holding(lk)) { // REMOVE 
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk)) { // REMOVE 
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
    80000bf6:	dd8080e7          	jalr	-552(ra) # 800019ca <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    printf("acquired %s lock already\n", lk->name);
    80000c06:	648c                	ld	a1,8(s1)
    80000c08:	00007517          	auipc	a0,0x7
    80000c0c:	46850513          	addi	a0,a0,1128 # 80008070 <digits+0x30>
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	964080e7          	jalr	-1692(ra) # 80000574 <printf>
    panic("acquire");
    80000c18:	00007517          	auipc	a0,0x7
    80000c1c:	47850513          	addi	a0,a0,1144 # 80008090 <digits+0x50>
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
    80000c34:	d9a080e7          	jalr	-614(ra) # 800019ca <mycpu>
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
    80000c6c:	43050513          	addi	a0,a0,1072 # 80008098 <digits+0x58>
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	8ba080e7          	jalr	-1862(ra) # 8000052a <panic>
    panic("pop_off");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	43850513          	addi	a0,a0,1080 # 800080b0 <digits+0x70>
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
  if(!holding(lk))
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
    panic("release");
    80000cc0:	00007517          	auipc	a0,0x7
    80000cc4:	3f850513          	addi	a0,a0,1016 # 800080b8 <digits+0x78>
    80000cc8:	00000097          	auipc	ra,0x0
    80000ccc:	862080e7          	jalr	-1950(ra) # 8000052a <panic>

0000000080000cd0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd0:	1141                	addi	sp,sp,-16
    80000cd2:	e422                	sd	s0,8(sp)
    80000cd4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd6:	ca19                	beqz	a2,80000cec <memset+0x1c>
    80000cd8:	87aa                	mv	a5,a0
    80000cda:	1602                	slli	a2,a2,0x20
    80000cdc:	9201                	srli	a2,a2,0x20
    80000cde:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce6:	0785                	addi	a5,a5,1
    80000ce8:	fee79de3          	bne	a5,a4,80000ce2 <memset+0x12>
  }
  return dst;
}
    80000cec:	6422                	ld	s0,8(sp)
    80000cee:	0141                	addi	sp,sp,16
    80000cf0:	8082                	ret

0000000080000cf2 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf2:	1141                	addi	sp,sp,-16
    80000cf4:	e422                	sd	s0,8(sp)
    80000cf6:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf8:	ca05                	beqz	a2,80000d28 <memcmp+0x36>
    80000cfa:	fff6069b          	addiw	a3,a2,-1
    80000cfe:	1682                	slli	a3,a3,0x20
    80000d00:	9281                	srli	a3,a3,0x20
    80000d02:	0685                	addi	a3,a3,1
    80000d04:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d06:	00054783          	lbu	a5,0(a0)
    80000d0a:	0005c703          	lbu	a4,0(a1)
    80000d0e:	00e79863          	bne	a5,a4,80000d1e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d12:	0505                	addi	a0,a0,1
    80000d14:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d16:	fed518e3          	bne	a0,a3,80000d06 <memcmp+0x14>
  }

  return 0;
    80000d1a:	4501                	li	a0,0
    80000d1c:	a019                	j	80000d22 <memcmp+0x30>
      return *s1 - *s2;
    80000d1e:	40e7853b          	subw	a0,a5,a4
}
    80000d22:	6422                	ld	s0,8(sp)
    80000d24:	0141                	addi	sp,sp,16
    80000d26:	8082                	ret
  return 0;
    80000d28:	4501                	li	a0,0
    80000d2a:	bfe5                	j	80000d22 <memcmp+0x30>

0000000080000d2c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2c:	1141                	addi	sp,sp,-16
    80000d2e:	e422                	sd	s0,8(sp)
    80000d30:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e563          	bltu	a1,a0,80000d5c <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	fff6069b          	addiw	a3,a2,-1
    80000d3a:	ce11                	beqz	a2,80000d56 <memmove+0x2a>
    80000d3c:	1682                	slli	a3,a3,0x20
    80000d3e:	9281                	srli	a3,a3,0x20
    80000d40:	0685                	addi	a3,a3,1
    80000d42:	96ae                	add	a3,a3,a1
    80000d44:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d46:	0585                	addi	a1,a1,1
    80000d48:	0785                	addi	a5,a5,1
    80000d4a:	fff5c703          	lbu	a4,-1(a1)
    80000d4e:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d52:	fed59ae3          	bne	a1,a3,80000d46 <memmove+0x1a>

  return dst;
}
    80000d56:	6422                	ld	s0,8(sp)
    80000d58:	0141                	addi	sp,sp,16
    80000d5a:	8082                	ret
  if(s < d && s + n > d){
    80000d5c:	02061713          	slli	a4,a2,0x20
    80000d60:	9301                	srli	a4,a4,0x20
    80000d62:	00e587b3          	add	a5,a1,a4
    80000d66:	fcf578e3          	bgeu	a0,a5,80000d36 <memmove+0xa>
    d += n;
    80000d6a:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d6c:	fff6069b          	addiw	a3,a2,-1
    80000d70:	d27d                	beqz	a2,80000d56 <memmove+0x2a>
    80000d72:	02069613          	slli	a2,a3,0x20
    80000d76:	9201                	srli	a2,a2,0x20
    80000d78:	fff64613          	not	a2,a2
    80000d7c:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d7e:	17fd                	addi	a5,a5,-1
    80000d80:	177d                	addi	a4,a4,-1
    80000d82:	0007c683          	lbu	a3,0(a5)
    80000d86:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d8a:	fef61ae3          	bne	a2,a5,80000d7e <memmove+0x52>
    80000d8e:	b7e1                	j	80000d56 <memmove+0x2a>

0000000080000d90 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e406                	sd	ra,8(sp)
    80000d94:	e022                	sd	s0,0(sp)
    80000d96:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d98:	00000097          	auipc	ra,0x0
    80000d9c:	f94080e7          	jalr	-108(ra) # 80000d2c <memmove>
}
    80000da0:	60a2                	ld	ra,8(sp)
    80000da2:	6402                	ld	s0,0(sp)
    80000da4:	0141                	addi	sp,sp,16
    80000da6:	8082                	ret

0000000080000da8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da8:	1141                	addi	sp,sp,-16
    80000daa:	e422                	sd	s0,8(sp)
    80000dac:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dae:	ce11                	beqz	a2,80000dca <strncmp+0x22>
    80000db0:	00054783          	lbu	a5,0(a0)
    80000db4:	cf89                	beqz	a5,80000dce <strncmp+0x26>
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	00f71a63          	bne	a4,a5,80000dce <strncmp+0x26>
    n--, p++, q++;
    80000dbe:	367d                	addiw	a2,a2,-1
    80000dc0:	0505                	addi	a0,a0,1
    80000dc2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dc4:	f675                	bnez	a2,80000db0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc6:	4501                	li	a0,0
    80000dc8:	a809                	j	80000dda <strncmp+0x32>
    80000dca:	4501                	li	a0,0
    80000dcc:	a039                	j	80000dda <strncmp+0x32>
  if(n == 0)
    80000dce:	ca09                	beqz	a2,80000de0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd0:	00054503          	lbu	a0,0(a0)
    80000dd4:	0005c783          	lbu	a5,0(a1)
    80000dd8:	9d1d                	subw	a0,a0,a5
}
    80000dda:	6422                	ld	s0,8(sp)
    80000ddc:	0141                	addi	sp,sp,16
    80000dde:	8082                	ret
    return 0;
    80000de0:	4501                	li	a0,0
    80000de2:	bfe5                	j	80000dda <strncmp+0x32>

0000000080000de4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000de4:	1141                	addi	sp,sp,-16
    80000de6:	e422                	sd	s0,8(sp)
    80000de8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dea:	872a                	mv	a4,a0
    80000dec:	8832                	mv	a6,a2
    80000dee:	367d                	addiw	a2,a2,-1
    80000df0:	01005963          	blez	a6,80000e02 <strncpy+0x1e>
    80000df4:	0705                	addi	a4,a4,1
    80000df6:	0005c783          	lbu	a5,0(a1)
    80000dfa:	fef70fa3          	sb	a5,-1(a4)
    80000dfe:	0585                	addi	a1,a1,1
    80000e00:	f7f5                	bnez	a5,80000dec <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e02:	86ba                	mv	a3,a4
    80000e04:	00c05c63          	blez	a2,80000e1c <strncpy+0x38>
    *s++ = 0;
    80000e08:	0685                	addi	a3,a3,1
    80000e0a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e0e:	fff6c793          	not	a5,a3
    80000e12:	9fb9                	addw	a5,a5,a4
    80000e14:	010787bb          	addw	a5,a5,a6
    80000e18:	fef048e3          	bgtz	a5,80000e08 <strncpy+0x24>
  return os;
}
    80000e1c:	6422                	ld	s0,8(sp)
    80000e1e:	0141                	addi	sp,sp,16
    80000e20:	8082                	ret

0000000080000e22 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e22:	1141                	addi	sp,sp,-16
    80000e24:	e422                	sd	s0,8(sp)
    80000e26:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e28:	02c05363          	blez	a2,80000e4e <safestrcpy+0x2c>
    80000e2c:	fff6069b          	addiw	a3,a2,-1
    80000e30:	1682                	slli	a3,a3,0x20
    80000e32:	9281                	srli	a3,a3,0x20
    80000e34:	96ae                	add	a3,a3,a1
    80000e36:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e38:	00d58963          	beq	a1,a3,80000e4a <safestrcpy+0x28>
    80000e3c:	0585                	addi	a1,a1,1
    80000e3e:	0785                	addi	a5,a5,1
    80000e40:	fff5c703          	lbu	a4,-1(a1)
    80000e44:	fee78fa3          	sb	a4,-1(a5)
    80000e48:	fb65                	bnez	a4,80000e38 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e4a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e4e:	6422                	ld	s0,8(sp)
    80000e50:	0141                	addi	sp,sp,16
    80000e52:	8082                	ret

0000000080000e54 <strlen>:

int
strlen(const char *s)
{
    80000e54:	1141                	addi	sp,sp,-16
    80000e56:	e422                	sd	s0,8(sp)
    80000e58:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e5a:	00054783          	lbu	a5,0(a0)
    80000e5e:	cf91                	beqz	a5,80000e7a <strlen+0x26>
    80000e60:	0505                	addi	a0,a0,1
    80000e62:	87aa                	mv	a5,a0
    80000e64:	4685                	li	a3,1
    80000e66:	9e89                	subw	a3,a3,a0
    80000e68:	00f6853b          	addw	a0,a3,a5
    80000e6c:	0785                	addi	a5,a5,1
    80000e6e:	fff7c703          	lbu	a4,-1(a5)
    80000e72:	fb7d                	bnez	a4,80000e68 <strlen+0x14>
    ;
  return n;
}
    80000e74:	6422                	ld	s0,8(sp)
    80000e76:	0141                	addi	sp,sp,16
    80000e78:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e7a:	4501                	li	a0,0
    80000e7c:	bfe5                	j	80000e74 <strlen+0x20>

0000000080000e7e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e406                	sd	ra,8(sp)
    80000e82:	e022                	sd	s0,0(sp)
    80000e84:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e86:	00001097          	auipc	ra,0x1
    80000e8a:	b34080e7          	jalr	-1228(ra) # 800019ba <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e8e:	00008717          	auipc	a4,0x8
    80000e92:	18a70713          	addi	a4,a4,394 # 80009018 <started>
  if(cpuid() == 0){
    80000e96:	c139                	beqz	a0,80000edc <main+0x5e>
    while(started == 0)
    80000e98:	431c                	lw	a5,0(a4)
    80000e9a:	2781                	sext.w	a5,a5
    80000e9c:	dff5                	beqz	a5,80000e98 <main+0x1a>
      ;
    __sync_synchronize();
    80000e9e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea2:	00001097          	auipc	ra,0x1
    80000ea6:	b18080e7          	jalr	-1256(ra) # 800019ba <cpuid>
    80000eaa:	85aa                	mv	a1,a0
    80000eac:	00007517          	auipc	a0,0x7
    80000eb0:	22c50513          	addi	a0,a0,556 # 800080d8 <digits+0x98>
    80000eb4:	fffff097          	auipc	ra,0xfffff
    80000eb8:	6c0080e7          	jalr	1728(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000ebc:	00000097          	auipc	ra,0x0
    80000ec0:	0d8080e7          	jalr	216(ra) # 80000f94 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ec4:	00002097          	auipc	ra,0x2
    80000ec8:	fe0080e7          	jalr	-32(ra) # 80002ea4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ecc:	00006097          	auipc	ra,0x6
    80000ed0:	b54080e7          	jalr	-1196(ra) # 80006a20 <plicinithart>
  }

  scheduler();        
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	e94080e7          	jalr	-364(ra) # 80002d68 <scheduler>
    consoleinit();
    80000edc:	fffff097          	auipc	ra,0xfffff
    80000ee0:	560080e7          	jalr	1376(ra) # 8000043c <consoleinit>
    printfinit();
    80000ee4:	00000097          	auipc	ra,0x0
    80000ee8:	870080e7          	jalr	-1936(ra) # 80000754 <printfinit>
    printf("\n");
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1fc50513          	addi	a0,a0,508 # 800080e8 <digits+0xa8>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	680080e7          	jalr	1664(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1c450513          	addi	a0,a0,452 # 800080c0 <digits+0x80>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	670080e7          	jalr	1648(ra) # 80000574 <printf>
    printf("\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	1dc50513          	addi	a0,a0,476 # 800080e8 <digits+0xa8>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	660080e7          	jalr	1632(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f1c:	00000097          	auipc	ra,0x0
    80000f20:	b7a080e7          	jalr	-1158(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	320080e7          	jalr	800(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	068080e7          	jalr	104(ra) # 80000f94 <kvminithart>
    procinit();      // process table
    80000f34:	00001097          	auipc	ra,0x1
    80000f38:	9d6080e7          	jalr	-1578(ra) # 8000190a <procinit>
    trapinit();      // trap vectors
    80000f3c:	00002097          	auipc	ra,0x2
    80000f40:	f40080e7          	jalr	-192(ra) # 80002e7c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f44:	00002097          	auipc	ra,0x2
    80000f48:	f60080e7          	jalr	-160(ra) # 80002ea4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4c:	00006097          	auipc	ra,0x6
    80000f50:	abe080e7          	jalr	-1346(ra) # 80006a0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f54:	00006097          	auipc	ra,0x6
    80000f58:	acc080e7          	jalr	-1332(ra) # 80006a20 <plicinithart>
    binit();         // buffer cache
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	6be080e7          	jalr	1726(ra) # 8000361a <binit>
    iinit();         // inode cache
    80000f64:	00003097          	auipc	ra,0x3
    80000f68:	d50080e7          	jalr	-688(ra) # 80003cb4 <iinit>
    fileinit();      // file table
    80000f6c:	00004097          	auipc	ra,0x4
    80000f70:	010080e7          	jalr	16(ra) # 80004f7c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f74:	00006097          	auipc	ra,0x6
    80000f78:	bce080e7          	jalr	-1074(ra) # 80006b42 <virtio_disk_init>
    userinit();      // first user process
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	d42080e7          	jalr	-702(ra) # 80001cbe <userinit>
    __sync_synchronize();
    80000f84:	0ff0000f          	fence
    started = 1;
    80000f88:	4785                	li	a5,1
    80000f8a:	00008717          	auipc	a4,0x8
    80000f8e:	08f72723          	sw	a5,142(a4) # 80009018 <started>
    80000f92:	b789                	j	80000ed4 <main+0x56>

0000000080000f94 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f94:	1141                	addi	sp,sp,-16
    80000f96:	e422                	sd	s0,8(sp)
    80000f98:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f9a:	00008797          	auipc	a5,0x8
    80000f9e:	0867b783          	ld	a5,134(a5) # 80009020 <kernel_pagetable>
    80000fa2:	83b1                	srli	a5,a5,0xc
    80000fa4:	577d                	li	a4,-1
    80000fa6:	177e                	slli	a4,a4,0x3f
    80000fa8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000faa:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fae:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb2:	6422                	ld	s0,8(sp)
    80000fb4:	0141                	addi	sp,sp,16
    80000fb6:	8082                	ret

0000000080000fb8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb8:	7139                	addi	sp,sp,-64
    80000fba:	fc06                	sd	ra,56(sp)
    80000fbc:	f822                	sd	s0,48(sp)
    80000fbe:	f426                	sd	s1,40(sp)
    80000fc0:	f04a                	sd	s2,32(sp)
    80000fc2:	ec4e                	sd	s3,24(sp)
    80000fc4:	e852                	sd	s4,16(sp)
    80000fc6:	e456                	sd	s5,8(sp)
    80000fc8:	e05a                	sd	s6,0(sp)
    80000fca:	0080                	addi	s0,sp,64
    80000fcc:	84aa                	mv	s1,a0
    80000fce:	89ae                	mv	s3,a1
    80000fd0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd2:	57fd                	li	a5,-1
    80000fd4:	83e9                	srli	a5,a5,0x1a
    80000fd6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fda:	04b7f263          	bgeu	a5,a1,8000101e <walk+0x66>
    panic("walk");
    80000fde:	00007517          	auipc	a0,0x7
    80000fe2:	11250513          	addi	a0,a0,274 # 800080f0 <digits+0xb0>
    80000fe6:	fffff097          	auipc	ra,0xfffff
    80000fea:	544080e7          	jalr	1348(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fee:	060a8663          	beqz	s5,8000105a <walk+0xa2>
    80000ff2:	00000097          	auipc	ra,0x0
    80000ff6:	ae0080e7          	jalr	-1312(ra) # 80000ad2 <kalloc>
    80000ffa:	84aa                	mv	s1,a0
    80000ffc:	c529                	beqz	a0,80001046 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffe:	6605                	lui	a2,0x1
    80001000:	4581                	li	a1,0
    80001002:	00000097          	auipc	ra,0x0
    80001006:	cce080e7          	jalr	-818(ra) # 80000cd0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000100a:	00c4d793          	srli	a5,s1,0xc
    8000100e:	07aa                	slli	a5,a5,0xa
    80001010:	0017e793          	ori	a5,a5,1
    80001014:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001018:	3a5d                	addiw	s4,s4,-9
    8000101a:	036a0063          	beq	s4,s6,8000103a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101e:	0149d933          	srl	s2,s3,s4
    80001022:	1ff97913          	andi	s2,s2,511
    80001026:	090e                	slli	s2,s2,0x3
    80001028:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000102a:	00093483          	ld	s1,0(s2)
    8000102e:	0014f793          	andi	a5,s1,1
    80001032:	dfd5                	beqz	a5,80000fee <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001034:	80a9                	srli	s1,s1,0xa
    80001036:	04b2                	slli	s1,s1,0xc
    80001038:	b7c5                	j	80001018 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000103a:	00c9d513          	srli	a0,s3,0xc
    8000103e:	1ff57513          	andi	a0,a0,511
    80001042:	050e                	slli	a0,a0,0x3
    80001044:	9526                	add	a0,a0,s1
}
    80001046:	70e2                	ld	ra,56(sp)
    80001048:	7442                	ld	s0,48(sp)
    8000104a:	74a2                	ld	s1,40(sp)
    8000104c:	7902                	ld	s2,32(sp)
    8000104e:	69e2                	ld	s3,24(sp)
    80001050:	6a42                	ld	s4,16(sp)
    80001052:	6aa2                	ld	s5,8(sp)
    80001054:	6b02                	ld	s6,0(sp)
    80001056:	6121                	addi	sp,sp,64
    80001058:	8082                	ret
        return 0;
    8000105a:	4501                	li	a0,0
    8000105c:	b7ed                	j	80001046 <walk+0x8e>

000000008000105e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105e:	57fd                	li	a5,-1
    80001060:	83e9                	srli	a5,a5,0x1a
    80001062:	00b7f463          	bgeu	a5,a1,8000106a <walkaddr+0xc>
    return 0;
    80001066:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001068:	8082                	ret
{
    8000106a:	1141                	addi	sp,sp,-16
    8000106c:	e406                	sd	ra,8(sp)
    8000106e:	e022                	sd	s0,0(sp)
    80001070:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001072:	4601                	li	a2,0
    80001074:	00000097          	auipc	ra,0x0
    80001078:	f44080e7          	jalr	-188(ra) # 80000fb8 <walk>
  if(pte == 0)
    8000107c:	c105                	beqz	a0,8000109c <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001080:	0117f693          	andi	a3,a5,17
    80001084:	4745                	li	a4,17
    return 0;
    80001086:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001088:	00e68663          	beq	a3,a4,80001094 <walkaddr+0x36>
}
    8000108c:	60a2                	ld	ra,8(sp)
    8000108e:	6402                	ld	s0,0(sp)
    80001090:	0141                	addi	sp,sp,16
    80001092:	8082                	ret
  pa = PTE2PA(*pte);
    80001094:	00a7d513          	srli	a0,a5,0xa
    80001098:	0532                	slli	a0,a0,0xc
  return pa;
    8000109a:	bfcd                	j	8000108c <walkaddr+0x2e>
    return 0;
    8000109c:	4501                	li	a0,0
    8000109e:	b7fd                	j	8000108c <walkaddr+0x2e>

00000000800010a0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a0:	715d                	addi	sp,sp,-80
    800010a2:	e486                	sd	ra,72(sp)
    800010a4:	e0a2                	sd	s0,64(sp)
    800010a6:	fc26                	sd	s1,56(sp)
    800010a8:	f84a                	sd	s2,48(sp)
    800010aa:	f44e                	sd	s3,40(sp)
    800010ac:	f052                	sd	s4,32(sp)
    800010ae:	ec56                	sd	s5,24(sp)
    800010b0:	e85a                	sd	s6,16(sp)
    800010b2:	e45e                	sd	s7,8(sp)
    800010b4:	e062                	sd	s8,0(sp)
    800010b6:	0880                	addi	s0,sp,80
    800010b8:	8b2a                	mv	s6,a0
    800010ba:	8a3a                	mv	s4,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010bc:	777d                	lui	a4,0xfffff
    800010be:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c2:	167d                	addi	a2,a2,-1
    800010c4:	00b609b3          	add	s3,a2,a1
    800010c8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010cc:	893e                	mv	s2,a5
    800010ce:	40f68ab3          	sub	s5,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm;
    // ADDED Q1
    // PTE_V == 1 only when the page is located in the ram
    if(!(perm & PTE_PG)){
    800010d2:	200a7b93          	andi	s7,s4,512
      *pte = *pte | PTE_V;
    } 
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6c05                	lui	s8,0x1
    800010d8:	a839                	j	800010f6 <mappages+0x56>
      panic("remap");
    800010da:	00007517          	auipc	a0,0x7
    800010de:	01e50513          	addi	a0,a0,30 # 800080f8 <digits+0xb8>
    800010e2:	fffff097          	auipc	ra,0xfffff
    800010e6:	448080e7          	jalr	1096(ra) # 8000052a <panic>
      *pte = *pte | PTE_V;
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390563          	beq	s2,s3,8000113a <mappages+0x9a>
    a += PGSIZE;
    800010f4:	9962                	add	s2,s2,s8
  for(;;){
    800010f6:	012a84b3          	add	s1,s5,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fa:	4605                	li	a2,1
    800010fc:	85ca                	mv	a1,s2
    800010fe:	855a                	mv	a0,s6
    80001100:	00000097          	auipc	ra,0x0
    80001104:	eb8080e7          	jalr	-328(ra) # 80000fb8 <walk>
    80001108:	cd01                	beqz	a0,80001120 <mappages+0x80>
    if(*pte & PTE_V)
    8000110a:	611c                	ld	a5,0(a0)
    8000110c:	8b85                	andi	a5,a5,1
    8000110e:	f7f1                	bnez	a5,800010da <mappages+0x3a>
    *pte = PA2PTE(pa) | perm;
    80001110:	80b1                	srli	s1,s1,0xc
    80001112:	04aa                	slli	s1,s1,0xa
    80001114:	0144e4b3          	or	s1,s1,s4
    if(!(perm & PTE_PG)){
    80001118:	fc0b89e3          	beqz	s7,800010ea <mappages+0x4a>
    *pte = PA2PTE(pa) | perm;
    8000111c:	e104                	sd	s1,0(a0)
    8000111e:	bfc9                	j	800010f0 <mappages+0x50>
      return -1;
    80001120:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001122:	60a6                	ld	ra,72(sp)
    80001124:	6406                	ld	s0,64(sp)
    80001126:	74e2                	ld	s1,56(sp)
    80001128:	7942                	ld	s2,48(sp)
    8000112a:	79a2                	ld	s3,40(sp)
    8000112c:	7a02                	ld	s4,32(sp)
    8000112e:	6ae2                	ld	s5,24(sp)
    80001130:	6b42                	ld	s6,16(sp)
    80001132:	6ba2                	ld	s7,8(sp)
    80001134:	6c02                	ld	s8,0(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7dd                	j	80001122 <mappages+0x82>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f54080e7          	jalr	-172(ra) # 800010a0 <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	fa250513          	addi	a0,a0,-94 # 80008100 <digits+0xc0>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3c4080e7          	jalr	964(ra) # 8000052a <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	958080e7          	jalr	-1704(ra) # 80000ad2 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b48080e7          	jalr	-1208(ra) # 80000cd0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	646080e7          	jalr	1606(ra) # 80001874 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00008797          	auipc	a5,0x8
    80001258:	dca7b623          	sd	a0,-564(a5) # 80009020 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0 ) // ADDED Q1
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e963          	bltu	a1,s3,80001302 <uvmunmap+0x9e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5e50513          	addi	a0,a0,-418 # 80008108 <digits+0xc8>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	278080e7          	jalr	632(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e6650513          	addi	a0,a0,-410 # 80008120 <digits+0xe0>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	268080e7          	jalr	616(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e6650513          	addi	a0,a0,-410 # 80008130 <digits+0xf0>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	258080e7          	jalr	600(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6e50513          	addi	a0,a0,-402 # 80008148 <digits+0x108>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	248080e7          	jalr	584(ra) # 8000052a <panic>
      uint64 pa = PTE2PA(*pte);
    800012ea:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012ec:	00c79513          	slli	a0,a5,0xc
    800012f0:	fffff097          	auipc	ra,0xfffff
    800012f4:	6e6080e7          	jalr	1766(ra) # 800009d6 <kfree>
    *pte = 0;
    800012f8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fc:	995a                	add	s2,s2,s6
    800012fe:	f9397be3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001302:	4601                	li	a2,0
    80001304:	85ca                	mv	a1,s2
    80001306:	8552                	mv	a0,s4
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	cb0080e7          	jalr	-848(ra) # 80000fb8 <walk>
    80001310:	84aa                	mv	s1,a0
    80001312:	d545                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0 ) // ADDED Q1
    80001314:	611c                	ld	a5,0(a0)
    80001316:	2017f713          	andi	a4,a5,513
    8000131a:	db45                	beqz	a4,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000131c:	3ff7f713          	andi	a4,a5,1023
    80001320:	fb770de3          	beq	a4,s7,800012da <uvmunmap+0x76>
    if(do_free && (*pte & PTE_PG) == 0){ // ADDED Q1
    80001324:	fc0a8ae3          	beqz	s5,800012f8 <uvmunmap+0x94>
    80001328:	2007f713          	andi	a4,a5,512
    8000132c:	f771                	bnez	a4,800012f8 <uvmunmap+0x94>
    8000132e:	bf75                	j	800012ea <uvmunmap+0x86>

0000000080001330 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001330:	1101                	addi	sp,sp,-32
    80001332:	ec06                	sd	ra,24(sp)
    80001334:	e822                	sd	s0,16(sp)
    80001336:	e426                	sd	s1,8(sp)
    80001338:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	798080e7          	jalr	1944(ra) # 80000ad2 <kalloc>
    80001342:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001344:	c519                	beqz	a0,80001352 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001346:	6605                	lui	a2,0x1
    80001348:	4581                	li	a1,0
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	986080e7          	jalr	-1658(ra) # 80000cd0 <memset>
  return pagetable;
}
    80001352:	8526                	mv	a0,s1
    80001354:	60e2                	ld	ra,24(sp)
    80001356:	6442                	ld	s0,16(sp)
    80001358:	64a2                	ld	s1,8(sp)
    8000135a:	6105                	addi	sp,sp,32
    8000135c:	8082                	ret

000000008000135e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000135e:	7179                	addi	sp,sp,-48
    80001360:	f406                	sd	ra,40(sp)
    80001362:	f022                	sd	s0,32(sp)
    80001364:	ec26                	sd	s1,24(sp)
    80001366:	e84a                	sd	s2,16(sp)
    80001368:	e44e                	sd	s3,8(sp)
    8000136a:	e052                	sd	s4,0(sp)
    8000136c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000136e:	6785                	lui	a5,0x1
    80001370:	04f67863          	bgeu	a2,a5,800013c0 <uvminit+0x62>
    80001374:	8a2a                	mv	s4,a0
    80001376:	89ae                	mv	s3,a1
    80001378:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	758080e7          	jalr	1880(ra) # 80000ad2 <kalloc>
    80001382:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001384:	6605                	lui	a2,0x1
    80001386:	4581                	li	a1,0
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	948080e7          	jalr	-1720(ra) # 80000cd0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001390:	4779                	li	a4,30
    80001392:	86ca                	mv	a3,s2
    80001394:	6605                	lui	a2,0x1
    80001396:	4581                	li	a1,0
    80001398:	8552                	mv	a0,s4
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	d06080e7          	jalr	-762(ra) # 800010a0 <mappages>
  memmove(mem, src, sz);
    800013a2:	8626                	mv	a2,s1
    800013a4:	85ce                	mv	a1,s3
    800013a6:	854a                	mv	a0,s2
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	984080e7          	jalr	-1660(ra) # 80000d2c <memmove>
}
    800013b0:	70a2                	ld	ra,40(sp)
    800013b2:	7402                	ld	s0,32(sp)
    800013b4:	64e2                	ld	s1,24(sp)
    800013b6:	6942                	ld	s2,16(sp)
    800013b8:	69a2                	ld	s3,8(sp)
    800013ba:	6a02                	ld	s4,0(sp)
    800013bc:	6145                	addi	sp,sp,48
    800013be:	8082                	ret
    panic("inituvm: more than a page");
    800013c0:	00007517          	auipc	a0,0x7
    800013c4:	da050513          	addi	a0,a0,-608 # 80008160 <digits+0x120>
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	162080e7          	jalr	354(ra) # 8000052a <panic>

00000000800013d0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013d0:	7179                	addi	sp,sp,-48
    800013d2:	f406                	sd	ra,40(sp)
    800013d4:	f022                	sd	s0,32(sp)
    800013d6:	ec26                	sd	s1,24(sp)
    800013d8:	e84a                	sd	s2,16(sp)
    800013da:	e44e                	sd	s3,8(sp)
    800013dc:	e052                	sd	s4,0(sp)
    800013de:	1800                	addi	s0,sp,48
    800013e0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    return oldsz;
    800013e2:	892e                	mv	s2,a1
  if(newsz >= oldsz)
    800013e4:	00b67d63          	bgeu	a2,a1,800013fe <uvmdealloc+0x2e>
    800013e8:	8932                	mv	s2,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ea:	6785                	lui	a5,0x1
    800013ec:	17fd                	addi	a5,a5,-1
    800013ee:	00f605b3          	add	a1,a2,a5
    800013f2:	767d                	lui	a2,0xfffff
    800013f4:	8df1                	and	a1,a1,a2
    800013f6:	97a6                	add	a5,a5,s1
    800013f8:	8ff1                	and	a5,a5,a2
    800013fa:	00f5eb63          	bltu	a1,a5,80001410 <uvmdealloc+0x40>
      remove_page_from_ram(a);
    }
  }

  return newsz;
}
    800013fe:	854a                	mv	a0,s2
    80001400:	70a2                	ld	ra,40(sp)
    80001402:	7402                	ld	s0,32(sp)
    80001404:	64e2                	ld	s1,24(sp)
    80001406:	6942                	ld	s2,16(sp)
    80001408:	69a2                	ld	s3,8(sp)
    8000140a:	6a02                	ld	s4,0(sp)
    8000140c:	6145                	addi	sp,sp,48
    8000140e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001410:	8f8d                	sub	a5,a5,a1
    80001412:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001414:	4685                	li	a3,1
    80001416:	0007861b          	sext.w	a2,a5
    8000141a:	00000097          	auipc	ra,0x0
    8000141e:	e4a080e7          	jalr	-438(ra) # 80001264 <uvmunmap>
    for (int a = PGROUNDDOWN(oldsz); a > PGROUNDDOWN(newsz); a -= PGSIZE) {
    80001422:	77fd                	lui	a5,0xfffff
    80001424:	8cfd                	and	s1,s1,a5
    80001426:	2481                	sext.w	s1,s1
    80001428:	79fd                	lui	s3,0xfffff
    8000142a:	013979b3          	and	s3,s2,s3
    8000142e:	fc99f8e3          	bgeu	s3,s1,800013fe <uvmdealloc+0x2e>
    80001432:	7a7d                	lui	s4,0xfffff
      remove_page_from_ram(a);
    80001434:	8526                	mv	a0,s1
    80001436:	00001097          	auipc	ra,0x1
    8000143a:	5a6080e7          	jalr	1446(ra) # 800029dc <remove_page_from_ram>
    for (int a = PGROUNDDOWN(oldsz); a > PGROUNDDOWN(newsz); a -= PGSIZE) {
    8000143e:	94d2                	add	s1,s1,s4
    80001440:	fe99eae3          	bltu	s3,s1,80001434 <uvmdealloc+0x64>
    80001444:	bf6d                	j	800013fe <uvmdealloc+0x2e>

0000000080001446 <uvmalloc>:
  if(newsz < oldsz)
    80001446:	0ab66663          	bltu	a2,a1,800014f2 <uvmalloc+0xac>
{
    8000144a:	7139                	addi	sp,sp,-64
    8000144c:	fc06                	sd	ra,56(sp)
    8000144e:	f822                	sd	s0,48(sp)
    80001450:	f426                	sd	s1,40(sp)
    80001452:	f04a                	sd	s2,32(sp)
    80001454:	ec4e                	sd	s3,24(sp)
    80001456:	e852                	sd	s4,16(sp)
    80001458:	e456                	sd	s5,8(sp)
    8000145a:	0080                	addi	s0,sp,64
    8000145c:	8aaa                	mv	s5,a0
    8000145e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001460:	6985                	lui	s3,0x1
    80001462:	19fd                	addi	s3,s3,-1
    80001464:	95ce                	add	a1,a1,s3
    80001466:	79fd                	lui	s3,0xfffff
    80001468:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146c:	08c9f563          	bgeu	s3,a2,800014f6 <uvmalloc+0xb0>
    80001470:	894e                	mv	s2,s3
    mem = kalloc();
    80001472:	fffff097          	auipc	ra,0xfffff
    80001476:	660080e7          	jalr	1632(ra) # 80000ad2 <kalloc>
    8000147a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000147c:	cd05                	beqz	a0,800014b4 <uvmalloc+0x6e>
    memset(mem, 0, PGSIZE);
    8000147e:	6605                	lui	a2,0x1
    80001480:	4581                	li	a1,0
    80001482:	00000097          	auipc	ra,0x0
    80001486:	84e080e7          	jalr	-1970(ra) # 80000cd0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000148a:	4779                	li	a4,30
    8000148c:	86a6                	mv	a3,s1
    8000148e:	6605                	lui	a2,0x1
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	c0c080e7          	jalr	-1012(ra) # 800010a0 <mappages>
    8000149c:	ed0d                	bnez	a0,800014d6 <uvmalloc+0x90>
    insert_page_to_ram(a);
    8000149e:	854a                	mv	a0,s2
    800014a0:	00001097          	auipc	ra,0x1
    800014a4:	5da080e7          	jalr	1498(ra) # 80002a7a <insert_page_to_ram>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a8:	6785                	lui	a5,0x1
    800014aa:	993e                	add	s2,s2,a5
    800014ac:	fd4963e3          	bltu	s2,s4,80001472 <uvmalloc+0x2c>
  return newsz;
    800014b0:	8552                	mv	a0,s4
    800014b2:	a809                	j	800014c4 <uvmalloc+0x7e>
      uvmdealloc(pagetable, a, oldsz);
    800014b4:	864e                	mv	a2,s3
    800014b6:	85ca                	mv	a1,s2
    800014b8:	8556                	mv	a0,s5
    800014ba:	00000097          	auipc	ra,0x0
    800014be:	f16080e7          	jalr	-234(ra) # 800013d0 <uvmdealloc>
      return 0;
    800014c2:	4501                	li	a0,0
}
    800014c4:	70e2                	ld	ra,56(sp)
    800014c6:	7442                	ld	s0,48(sp)
    800014c8:	74a2                	ld	s1,40(sp)
    800014ca:	7902                	ld	s2,32(sp)
    800014cc:	69e2                	ld	s3,24(sp)
    800014ce:	6a42                	ld	s4,16(sp)
    800014d0:	6aa2                	ld	s5,8(sp)
    800014d2:	6121                	addi	sp,sp,64
    800014d4:	8082                	ret
      kfree(mem);
    800014d6:	8526                	mv	a0,s1
    800014d8:	fffff097          	auipc	ra,0xfffff
    800014dc:	4fe080e7          	jalr	1278(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014e0:	864e                	mv	a2,s3
    800014e2:	85ca                	mv	a1,s2
    800014e4:	8556                	mv	a0,s5
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	eea080e7          	jalr	-278(ra) # 800013d0 <uvmdealloc>
      return 0;
    800014ee:	4501                	li	a0,0
    800014f0:	bfd1                	j	800014c4 <uvmalloc+0x7e>
    return oldsz;
    800014f2:	852e                	mv	a0,a1
}
    800014f4:	8082                	ret
  return newsz;
    800014f6:	8532                	mv	a0,a2
    800014f8:	b7f1                	j	800014c4 <uvmalloc+0x7e>

00000000800014fa <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014fa:	7179                	addi	sp,sp,-48
    800014fc:	f406                	sd	ra,40(sp)
    800014fe:	f022                	sd	s0,32(sp)
    80001500:	ec26                	sd	s1,24(sp)
    80001502:	e84a                	sd	s2,16(sp)
    80001504:	e44e                	sd	s3,8(sp)
    80001506:	e052                	sd	s4,0(sp)
    80001508:	1800                	addi	s0,sp,48
    8000150a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000150c:	84aa                	mv	s1,a0
    8000150e:	6905                	lui	s2,0x1
    80001510:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	4985                	li	s3,1
    80001514:	a821                	j	8000152c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001516:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001518:	0532                	slli	a0,a0,0xc
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	fe0080e7          	jalr	-32(ra) # 800014fa <freewalk>
      pagetable[i] = 0;
    80001522:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001526:	04a1                	addi	s1,s1,8
    80001528:	03248163          	beq	s1,s2,8000154a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000152c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000152e:	00f57793          	andi	a5,a0,15
    80001532:	ff3782e3          	beq	a5,s3,80001516 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001536:	8905                	andi	a0,a0,1
    80001538:	d57d                	beqz	a0,80001526 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000153a:	00007517          	auipc	a0,0x7
    8000153e:	c4650513          	addi	a0,a0,-954 # 80008180 <digits+0x140>
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	fe8080e7          	jalr	-24(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    8000154a:	8552                	mv	a0,s4
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	48a080e7          	jalr	1162(ra) # 800009d6 <kfree>
}
    80001554:	70a2                	ld	ra,40(sp)
    80001556:	7402                	ld	s0,32(sp)
    80001558:	64e2                	ld	s1,24(sp)
    8000155a:	6942                	ld	s2,16(sp)
    8000155c:	69a2                	ld	s3,8(sp)
    8000155e:	6a02                	ld	s4,0(sp)
    80001560:	6145                	addi	sp,sp,48
    80001562:	8082                	ret

0000000080001564 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001564:	1101                	addi	sp,sp,-32
    80001566:	ec06                	sd	ra,24(sp)
    80001568:	e822                	sd	s0,16(sp)
    8000156a:	e426                	sd	s1,8(sp)
    8000156c:	1000                	addi	s0,sp,32
    8000156e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001570:	e999                	bnez	a1,80001586 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001572:	8526                	mv	a0,s1
    80001574:	00000097          	auipc	ra,0x0
    80001578:	f86080e7          	jalr	-122(ra) # 800014fa <freewalk>
}
    8000157c:	60e2                	ld	ra,24(sp)
    8000157e:	6442                	ld	s0,16(sp)
    80001580:	64a2                	ld	s1,8(sp)
    80001582:	6105                	addi	sp,sp,32
    80001584:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001586:	6605                	lui	a2,0x1
    80001588:	167d                	addi	a2,a2,-1
    8000158a:	962e                	add	a2,a2,a1
    8000158c:	4685                	li	a3,1
    8000158e:	8231                	srli	a2,a2,0xc
    80001590:	4581                	li	a1,0
    80001592:	00000097          	auipc	ra,0x0
    80001596:	cd2080e7          	jalr	-814(ra) # 80001264 <uvmunmap>
    8000159a:	bfe1                	j	80001572 <uvmfree+0xe>

000000008000159c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem = 0;

  for(i = 0; i < sz; i += PGSIZE){
    8000159c:	ca71                	beqz	a2,80001670 <uvmcopy+0xd4>
{
    8000159e:	715d                	addi	sp,sp,-80
    800015a0:	e486                	sd	ra,72(sp)
    800015a2:	e0a2                	sd	s0,64(sp)
    800015a4:	fc26                	sd	s1,56(sp)
    800015a6:	f84a                	sd	s2,48(sp)
    800015a8:	f44e                	sd	s3,40(sp)
    800015aa:	f052                	sd	s4,32(sp)
    800015ac:	ec56                	sd	s5,24(sp)
    800015ae:	e85a                	sd	s6,16(sp)
    800015b0:	e45e                	sd	s7,8(sp)
    800015b2:	0880                	addi	s0,sp,80
    800015b4:	8b2a                	mv	s6,a0
    800015b6:	8aae                	mv	s5,a1
    800015b8:	8a32                	mv	s4,a2
  char *mem = 0;
    800015ba:	4981                	li	s3,0
  for(i = 0; i < sz; i += PGSIZE){
    800015bc:	4901                	li	s2,0
    800015be:	a83d                	j	800015fc <uvmcopy+0x60>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015c0:	00007517          	auipc	a0,0x7
    800015c4:	bd050513          	addi	a0,a0,-1072 # 80008190 <digits+0x150>
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	f62080e7          	jalr	-158(ra) # 8000052a <panic>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
      panic("uvmcopy: page not present");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	be050513          	addi	a0,a0,-1056 # 800081b0 <digits+0x170>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f52080e7          	jalr	-174(ra) # 8000052a <panic>
    if ((flags & PTE_PG) == 0){ // ADDED Q1 - do not copy pages from disk (we are doing that in fork() system call)
      if((mem = kalloc()) == 0)
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
    }
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015e0:	875e                	mv	a4,s7
    800015e2:	86ce                	mv	a3,s3
    800015e4:	6605                	lui	a2,0x1
    800015e6:	85ca                	mv	a1,s2
    800015e8:	8556                	mv	a0,s5
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	ab6080e7          	jalr	-1354(ra) # 800010a0 <mappages>
    800015f2:	e529                	bnez	a0,8000163c <uvmcopy+0xa0>
  for(i = 0; i < sz; i += PGSIZE){
    800015f4:	6785                	lui	a5,0x1
    800015f6:	993e                	add	s2,s2,a5
    800015f8:	07497163          	bgeu	s2,s4,8000165a <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    800015fc:	4601                	li	a2,0
    800015fe:	85ca                	mv	a1,s2
    80001600:	855a                	mv	a0,s6
    80001602:	00000097          	auipc	ra,0x0
    80001606:	9b6080e7          	jalr	-1610(ra) # 80000fb8 <walk>
    8000160a:	d95d                	beqz	a0,800015c0 <uvmcopy+0x24>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
    8000160c:	6104                	ld	s1,0(a0)
    8000160e:	2014f793          	andi	a5,s1,513
    80001612:	dfdd                	beqz	a5,800015d0 <uvmcopy+0x34>
    flags = PTE_FLAGS(*pte);
    80001614:	3ff4fb93          	andi	s7,s1,1023
    if ((flags & PTE_PG) == 0){ // ADDED Q1 - do not copy pages from disk (we are doing that in fork() system call)
    80001618:	2004f793          	andi	a5,s1,512
    8000161c:	f3f1                	bnez	a5,800015e0 <uvmcopy+0x44>
      if((mem = kalloc()) == 0)
    8000161e:	fffff097          	auipc	ra,0xfffff
    80001622:	4b4080e7          	jalr	1204(ra) # 80000ad2 <kalloc>
    80001626:	89aa                	mv	s3,a0
    80001628:	cd19                	beqz	a0,80001646 <uvmcopy+0xaa>
    pa = PTE2PA(*pte);
    8000162a:	00a4d593          	srli	a1,s1,0xa
      memmove(mem, (char*)pa, PGSIZE);
    8000162e:	6605                	lui	a2,0x1
    80001630:	05b2                	slli	a1,a1,0xc
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	6fa080e7          	jalr	1786(ra) # 80000d2c <memmove>
    8000163a:	b75d                	j	800015e0 <uvmcopy+0x44>
      kfree(mem);
    8000163c:	854e                	mv	a0,s3
    8000163e:	fffff097          	auipc	ra,0xfffff
    80001642:	398080e7          	jalr	920(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001646:	4685                	li	a3,1
    80001648:	00c95613          	srli	a2,s2,0xc
    8000164c:	4581                	li	a1,0
    8000164e:	8556                	mv	a0,s5
    80001650:	00000097          	auipc	ra,0x0
    80001654:	c14080e7          	jalr	-1004(ra) # 80001264 <uvmunmap>
  return -1;
    80001658:	557d                	li	a0,-1
}
    8000165a:	60a6                	ld	ra,72(sp)
    8000165c:	6406                	ld	s0,64(sp)
    8000165e:	74e2                	ld	s1,56(sp)
    80001660:	7942                	ld	s2,48(sp)
    80001662:	79a2                	ld	s3,40(sp)
    80001664:	7a02                	ld	s4,32(sp)
    80001666:	6ae2                	ld	s5,24(sp)
    80001668:	6b42                	ld	s6,16(sp)
    8000166a:	6ba2                	ld	s7,8(sp)
    8000166c:	6161                	addi	sp,sp,80
    8000166e:	8082                	ret
  return 0;
    80001670:	4501                	li	a0,0
}
    80001672:	8082                	ret

0000000080001674 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001674:	1141                	addi	sp,sp,-16
    80001676:	e406                	sd	ra,8(sp)
    80001678:	e022                	sd	s0,0(sp)
    8000167a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000167c:	4601                	li	a2,0
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	93a080e7          	jalr	-1734(ra) # 80000fb8 <walk>
  if(pte == 0)
    80001686:	c901                	beqz	a0,80001696 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001688:	611c                	ld	a5,0(a0)
    8000168a:	9bbd                	andi	a5,a5,-17
    8000168c:	e11c                	sd	a5,0(a0)
}
    8000168e:	60a2                	ld	ra,8(sp)
    80001690:	6402                	ld	s0,0(sp)
    80001692:	0141                	addi	sp,sp,16
    80001694:	8082                	ret
    panic("uvmclear");
    80001696:	00007517          	auipc	a0,0x7
    8000169a:	b3a50513          	addi	a0,a0,-1222 # 800081d0 <digits+0x190>
    8000169e:	fffff097          	auipc	ra,0xfffff
    800016a2:	e8c080e7          	jalr	-372(ra) # 8000052a <panic>

00000000800016a6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016a6:	c6bd                	beqz	a3,80001714 <copyout+0x6e>
{
    800016a8:	715d                	addi	sp,sp,-80
    800016aa:	e486                	sd	ra,72(sp)
    800016ac:	e0a2                	sd	s0,64(sp)
    800016ae:	fc26                	sd	s1,56(sp)
    800016b0:	f84a                	sd	s2,48(sp)
    800016b2:	f44e                	sd	s3,40(sp)
    800016b4:	f052                	sd	s4,32(sp)
    800016b6:	ec56                	sd	s5,24(sp)
    800016b8:	e85a                	sd	s6,16(sp)
    800016ba:	e45e                	sd	s7,8(sp)
    800016bc:	e062                	sd	s8,0(sp)
    800016be:	0880                	addi	s0,sp,80
    800016c0:	8b2a                	mv	s6,a0
    800016c2:	8c2e                	mv	s8,a1
    800016c4:	8a32                	mv	s4,a2
    800016c6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016c8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ca:	6a85                	lui	s5,0x1
    800016cc:	a015                	j	800016f0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ce:	9562                	add	a0,a0,s8
    800016d0:	0004861b          	sext.w	a2,s1
    800016d4:	85d2                	mv	a1,s4
    800016d6:	41250533          	sub	a0,a0,s2
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	652080e7          	jalr	1618(ra) # 80000d2c <memmove>

    len -= n;
    800016e2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016e6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016e8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ec:	02098263          	beqz	s3,80001710 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016f4:	85ca                	mv	a1,s2
    800016f6:	855a                	mv	a0,s6
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	966080e7          	jalr	-1690(ra) # 8000105e <walkaddr>
    if(pa0 == 0)
    80001700:	cd01                	beqz	a0,80001718 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001702:	418904b3          	sub	s1,s2,s8
    80001706:	94d6                	add	s1,s1,s5
    if(n > len)
    80001708:	fc99f3e3          	bgeu	s3,s1,800016ce <copyout+0x28>
    8000170c:	84ce                	mv	s1,s3
    8000170e:	b7c1                	j	800016ce <copyout+0x28>
  }
  return 0;
    80001710:	4501                	li	a0,0
    80001712:	a021                	j	8000171a <copyout+0x74>
    80001714:	4501                	li	a0,0
}
    80001716:	8082                	ret
      return -1;
    80001718:	557d                	li	a0,-1
}
    8000171a:	60a6                	ld	ra,72(sp)
    8000171c:	6406                	ld	s0,64(sp)
    8000171e:	74e2                	ld	s1,56(sp)
    80001720:	7942                	ld	s2,48(sp)
    80001722:	79a2                	ld	s3,40(sp)
    80001724:	7a02                	ld	s4,32(sp)
    80001726:	6ae2                	ld	s5,24(sp)
    80001728:	6b42                	ld	s6,16(sp)
    8000172a:	6ba2                	ld	s7,8(sp)
    8000172c:	6c02                	ld	s8,0(sp)
    8000172e:	6161                	addi	sp,sp,80
    80001730:	8082                	ret

0000000080001732 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001732:	caa5                	beqz	a3,800017a2 <copyin+0x70>
{
    80001734:	715d                	addi	sp,sp,-80
    80001736:	e486                	sd	ra,72(sp)
    80001738:	e0a2                	sd	s0,64(sp)
    8000173a:	fc26                	sd	s1,56(sp)
    8000173c:	f84a                	sd	s2,48(sp)
    8000173e:	f44e                	sd	s3,40(sp)
    80001740:	f052                	sd	s4,32(sp)
    80001742:	ec56                	sd	s5,24(sp)
    80001744:	e85a                	sd	s6,16(sp)
    80001746:	e45e                	sd	s7,8(sp)
    80001748:	e062                	sd	s8,0(sp)
    8000174a:	0880                	addi	s0,sp,80
    8000174c:	8b2a                	mv	s6,a0
    8000174e:	8a2e                	mv	s4,a1
    80001750:	8c32                	mv	s8,a2
    80001752:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001754:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001756:	6a85                	lui	s5,0x1
    80001758:	a01d                	j	8000177e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000175a:	018505b3          	add	a1,a0,s8
    8000175e:	0004861b          	sext.w	a2,s1
    80001762:	412585b3          	sub	a1,a1,s2
    80001766:	8552                	mv	a0,s4
    80001768:	fffff097          	auipc	ra,0xfffff
    8000176c:	5c4080e7          	jalr	1476(ra) # 80000d2c <memmove>

    len -= n;
    80001770:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001774:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001776:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177a:	02098263          	beqz	s3,8000179e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000177e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001782:	85ca                	mv	a1,s2
    80001784:	855a                	mv	a0,s6
    80001786:	00000097          	auipc	ra,0x0
    8000178a:	8d8080e7          	jalr	-1832(ra) # 8000105e <walkaddr>
    if(pa0 == 0)
    8000178e:	cd01                	beqz	a0,800017a6 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001790:	418904b3          	sub	s1,s2,s8
    80001794:	94d6                	add	s1,s1,s5
    if(n > len)
    80001796:	fc99f2e3          	bgeu	s3,s1,8000175a <copyin+0x28>
    8000179a:	84ce                	mv	s1,s3
    8000179c:	bf7d                	j	8000175a <copyin+0x28>
  }
  return 0;
    8000179e:	4501                	li	a0,0
    800017a0:	a021                	j	800017a8 <copyin+0x76>
    800017a2:	4501                	li	a0,0
}
    800017a4:	8082                	ret
      return -1;
    800017a6:	557d                	li	a0,-1
}
    800017a8:	60a6                	ld	ra,72(sp)
    800017aa:	6406                	ld	s0,64(sp)
    800017ac:	74e2                	ld	s1,56(sp)
    800017ae:	7942                	ld	s2,48(sp)
    800017b0:	79a2                	ld	s3,40(sp)
    800017b2:	7a02                	ld	s4,32(sp)
    800017b4:	6ae2                	ld	s5,24(sp)
    800017b6:	6b42                	ld	s6,16(sp)
    800017b8:	6ba2                	ld	s7,8(sp)
    800017ba:	6c02                	ld	s8,0(sp)
    800017bc:	6161                	addi	sp,sp,80
    800017be:	8082                	ret

00000000800017c0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c0:	c6c5                	beqz	a3,80001868 <copyinstr+0xa8>
{
    800017c2:	715d                	addi	sp,sp,-80
    800017c4:	e486                	sd	ra,72(sp)
    800017c6:	e0a2                	sd	s0,64(sp)
    800017c8:	fc26                	sd	s1,56(sp)
    800017ca:	f84a                	sd	s2,48(sp)
    800017cc:	f44e                	sd	s3,40(sp)
    800017ce:	f052                	sd	s4,32(sp)
    800017d0:	ec56                	sd	s5,24(sp)
    800017d2:	e85a                	sd	s6,16(sp)
    800017d4:	e45e                	sd	s7,8(sp)
    800017d6:	0880                	addi	s0,sp,80
    800017d8:	8a2a                	mv	s4,a0
    800017da:	8b2e                	mv	s6,a1
    800017dc:	8bb2                	mv	s7,a2
    800017de:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017e0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e2:	6985                	lui	s3,0x1
    800017e4:	a035                	j	80001810 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017e6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ea:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ec:	0017b793          	seqz	a5,a5
    800017f0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f4:	60a6                	ld	ra,72(sp)
    800017f6:	6406                	ld	s0,64(sp)
    800017f8:	74e2                	ld	s1,56(sp)
    800017fa:	7942                	ld	s2,48(sp)
    800017fc:	79a2                	ld	s3,40(sp)
    800017fe:	7a02                	ld	s4,32(sp)
    80001800:	6ae2                	ld	s5,24(sp)
    80001802:	6b42                	ld	s6,16(sp)
    80001804:	6ba2                	ld	s7,8(sp)
    80001806:	6161                	addi	sp,sp,80
    80001808:	8082                	ret
    srcva = va0 + PGSIZE;
    8000180a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000180e:	c8a9                	beqz	s1,80001860 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001810:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001814:	85ca                	mv	a1,s2
    80001816:	8552                	mv	a0,s4
    80001818:	00000097          	auipc	ra,0x0
    8000181c:	846080e7          	jalr	-1978(ra) # 8000105e <walkaddr>
    if(pa0 == 0)
    80001820:	c131                	beqz	a0,80001864 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001822:	41790833          	sub	a6,s2,s7
    80001826:	984e                	add	a6,a6,s3
    if(n > max)
    80001828:	0104f363          	bgeu	s1,a6,8000182e <copyinstr+0x6e>
    8000182c:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000182e:	955e                	add	a0,a0,s7
    80001830:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001834:	fc080be3          	beqz	a6,8000180a <copyinstr+0x4a>
    80001838:	985a                	add	a6,a6,s6
    8000183a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000183c:	41650633          	sub	a2,a0,s6
    80001840:	14fd                	addi	s1,s1,-1
    80001842:	9b26                	add	s6,s6,s1
    80001844:	00f60733          	add	a4,a2,a5
    80001848:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd1000>
    8000184c:	df49                	beqz	a4,800017e6 <copyinstr+0x26>
        *dst = *p;
    8000184e:	00e78023          	sb	a4,0(a5)
      --max;
    80001852:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001856:	0785                	addi	a5,a5,1
    while(n > 0){
    80001858:	ff0796e3          	bne	a5,a6,80001844 <copyinstr+0x84>
      dst++;
    8000185c:	8b42                	mv	s6,a6
    8000185e:	b775                	j	8000180a <copyinstr+0x4a>
    80001860:	4781                	li	a5,0
    80001862:	b769                	j	800017ec <copyinstr+0x2c>
      return -1;
    80001864:	557d                	li	a0,-1
    80001866:	b779                	j	800017f4 <copyinstr+0x34>
  int got_null = 0;
    80001868:	4781                	li	a5,0
  if(got_null){
    8000186a:	0017b793          	seqz	a5,a5
    8000186e:	40f00533          	neg	a0,a5
}
    80001872:	8082                	ret

0000000080001874 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001874:	7139                	addi	sp,sp,-64
    80001876:	fc06                	sd	ra,56(sp)
    80001878:	f822                	sd	s0,48(sp)
    8000187a:	f426                	sd	s1,40(sp)
    8000187c:	f04a                	sd	s2,32(sp)
    8000187e:	ec4e                	sd	s3,24(sp)
    80001880:	e852                	sd	s4,16(sp)
    80001882:	e456                	sd	s5,8(sp)
    80001884:	e05a                	sd	s6,0(sp)
    80001886:	0080                	addi	s0,sp,64
    80001888:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188a:	00010497          	auipc	s1,0x10
    8000188e:	e4648493          	addi	s1,s1,-442 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001892:	8b26                	mv	s6,s1
    80001894:	00006a97          	auipc	s5,0x6
    80001898:	76ca8a93          	addi	s5,s5,1900 # 80008000 <etext>
    8000189c:	04000937          	lui	s2,0x4000
    800018a0:	197d                	addi	s2,s2,-1
    800018a2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a4:	0001ea17          	auipc	s4,0x1e
    800018a8:	c2ca0a13          	addi	s4,s4,-980 # 8001f4d0 <tickslock>
    char *pa = kalloc();
    800018ac:	fffff097          	auipc	ra,0xfffff
    800018b0:	226080e7          	jalr	550(ra) # 80000ad2 <kalloc>
    800018b4:	862a                	mv	a2,a0
    if(pa == 0)
    800018b6:	c131                	beqz	a0,800018fa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018b8:	416485b3          	sub	a1,s1,s6
    800018bc:	858d                	srai	a1,a1,0x3
    800018be:	000ab783          	ld	a5,0(s5)
    800018c2:	02f585b3          	mul	a1,a1,a5
    800018c6:	2585                	addiw	a1,a1,1
    800018c8:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018cc:	4719                	li	a4,6
    800018ce:	6685                	lui	a3,0x1
    800018d0:	40b905b3          	sub	a1,s2,a1
    800018d4:	854e                	mv	a0,s3
    800018d6:	00000097          	auipc	ra,0x0
    800018da:	868080e7          	jalr	-1944(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	37848493          	addi	s1,s1,888
    800018e2:	fd4495e3          	bne	s1,s4,800018ac <proc_mapstacks+0x38>
  }
}
    800018e6:	70e2                	ld	ra,56(sp)
    800018e8:	7442                	ld	s0,48(sp)
    800018ea:	74a2                	ld	s1,40(sp)
    800018ec:	7902                	ld	s2,32(sp)
    800018ee:	69e2                	ld	s3,24(sp)
    800018f0:	6a42                	ld	s4,16(sp)
    800018f2:	6aa2                	ld	s5,8(sp)
    800018f4:	6b02                	ld	s6,0(sp)
    800018f6:	6121                	addi	sp,sp,64
    800018f8:	8082                	ret
      panic("kalloc");
    800018fa:	00007517          	auipc	a0,0x7
    800018fe:	8e650513          	addi	a0,a0,-1818 # 800081e0 <digits+0x1a0>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	c28080e7          	jalr	-984(ra) # 8000052a <panic>

000000008000190a <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    8000190a:	7139                	addi	sp,sp,-64
    8000190c:	fc06                	sd	ra,56(sp)
    8000190e:	f822                	sd	s0,48(sp)
    80001910:	f426                	sd	s1,40(sp)
    80001912:	f04a                	sd	s2,32(sp)
    80001914:	ec4e                	sd	s3,24(sp)
    80001916:	e852                	sd	s4,16(sp)
    80001918:	e456                	sd	s5,8(sp)
    8000191a:	e05a                	sd	s6,0(sp)
    8000191c:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000191e:	00007597          	auipc	a1,0x7
    80001922:	8ca58593          	addi	a1,a1,-1846 # 800081e8 <digits+0x1a8>
    80001926:	00010517          	auipc	a0,0x10
    8000192a:	97a50513          	addi	a0,a0,-1670 # 800112a0 <pid_lock>
    8000192e:	fffff097          	auipc	ra,0xfffff
    80001932:	204080e7          	jalr	516(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001936:	00007597          	auipc	a1,0x7
    8000193a:	8ba58593          	addi	a1,a1,-1862 # 800081f0 <digits+0x1b0>
    8000193e:	00010517          	auipc	a0,0x10
    80001942:	97a50513          	addi	a0,a0,-1670 # 800112b8 <wait_lock>
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	1ec080e7          	jalr	492(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	00010497          	auipc	s1,0x10
    80001952:	d8248493          	addi	s1,s1,-638 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001956:	00007b17          	auipc	s6,0x7
    8000195a:	8aab0b13          	addi	s6,s6,-1878 # 80008200 <digits+0x1c0>
      p->kstack = KSTACK((int) (p - proc));
    8000195e:	8aa6                	mv	s5,s1
    80001960:	00006a17          	auipc	s4,0x6
    80001964:	6a0a0a13          	addi	s4,s4,1696 # 80008000 <etext>
    80001968:	04000937          	lui	s2,0x4000
    8000196c:	197d                	addi	s2,s2,-1
    8000196e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	0001e997          	auipc	s3,0x1e
    80001974:	b6098993          	addi	s3,s3,-1184 # 8001f4d0 <tickslock>
      initlock(&p->lock, "proc");
    80001978:	85da                	mv	a1,s6
    8000197a:	8526                	mv	a0,s1
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	1b6080e7          	jalr	438(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001984:	415487b3          	sub	a5,s1,s5
    80001988:	878d                	srai	a5,a5,0x3
    8000198a:	000a3703          	ld	a4,0(s4)
    8000198e:	02e787b3          	mul	a5,a5,a4
    80001992:	2785                	addiw	a5,a5,1
    80001994:	00d7979b          	slliw	a5,a5,0xd
    80001998:	40f907b3          	sub	a5,s2,a5
    8000199c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199e:	37848493          	addi	s1,s1,888
    800019a2:	fd349be3          	bne	s1,s3,80001978 <procinit+0x6e>
  }
}
    800019a6:	70e2                	ld	ra,56(sp)
    800019a8:	7442                	ld	s0,48(sp)
    800019aa:	74a2                	ld	s1,40(sp)
    800019ac:	7902                	ld	s2,32(sp)
    800019ae:	69e2                	ld	s3,24(sp)
    800019b0:	6a42                	ld	s4,16(sp)
    800019b2:	6aa2                	ld	s5,8(sp)
    800019b4:	6b02                	ld	s6,0(sp)
    800019b6:	6121                	addi	sp,sp,64
    800019b8:	8082                	ret

00000000800019ba <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019ba:	1141                	addi	sp,sp,-16
    800019bc:	e422                	sd	s0,8(sp)
    800019be:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019c0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019c2:	2501                	sext.w	a0,a0
    800019c4:	6422                	ld	s0,8(sp)
    800019c6:	0141                	addi	sp,sp,16
    800019c8:	8082                	ret

00000000800019ca <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019ca:	1141                	addi	sp,sp,-16
    800019cc:	e422                	sd	s0,8(sp)
    800019ce:	0800                	addi	s0,sp,16
    800019d0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019d2:	2781                	sext.w	a5,a5
    800019d4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019d6:	00010517          	auipc	a0,0x10
    800019da:	8fa50513          	addi	a0,a0,-1798 # 800112d0 <cpus>
    800019de:	953e                	add	a0,a0,a5
    800019e0:	6422                	ld	s0,8(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret

00000000800019e6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019e6:	1101                	addi	sp,sp,-32
    800019e8:	ec06                	sd	ra,24(sp)
    800019ea:	e822                	sd	s0,16(sp)
    800019ec:	e426                	sd	s1,8(sp)
    800019ee:	1000                	addi	s0,sp,32
  push_off();
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	186080e7          	jalr	390(ra) # 80000b76 <push_off>
    800019f8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019fa:	2781                	sext.w	a5,a5
    800019fc:	079e                	slli	a5,a5,0x7
    800019fe:	00010717          	auipc	a4,0x10
    80001a02:	8a270713          	addi	a4,a4,-1886 # 800112a0 <pid_lock>
    80001a06:	97ba                	add	a5,a5,a4
    80001a08:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	21e080e7          	jalr	542(ra) # 80000c28 <pop_off>
  return p;
}
    80001a12:	8526                	mv	a0,s1
    80001a14:	60e2                	ld	ra,24(sp)
    80001a16:	6442                	ld	s0,16(sp)
    80001a18:	64a2                	ld	s1,8(sp)
    80001a1a:	6105                	addi	sp,sp,32
    80001a1c:	8082                	ret

0000000080001a1e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a1e:	1141                	addi	sp,sp,-16
    80001a20:	e406                	sd	ra,8(sp)
    80001a22:	e022                	sd	s0,0(sp)
    80001a24:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a26:	00000097          	auipc	ra,0x0
    80001a2a:	fc0080e7          	jalr	-64(ra) # 800019e6 <myproc>
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	25a080e7          	jalr	602(ra) # 80000c88 <release>

  if (first) {
    80001a36:	00007797          	auipc	a5,0x7
    80001a3a:	06a7a783          	lw	a5,106(a5) # 80008aa0 <first.1>
    80001a3e:	eb89                	bnez	a5,80001a50 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a40:	00001097          	auipc	ra,0x1
    80001a44:	47c080e7          	jalr	1148(ra) # 80002ebc <usertrapret>
}
    80001a48:	60a2                	ld	ra,8(sp)
    80001a4a:	6402                	ld	s0,0(sp)
    80001a4c:	0141                	addi	sp,sp,16
    80001a4e:	8082                	ret
    first = 0;
    80001a50:	00007797          	auipc	a5,0x7
    80001a54:	0407a823          	sw	zero,80(a5) # 80008aa0 <first.1>
    fsinit(ROOTDEV);
    80001a58:	4505                	li	a0,1
    80001a5a:	00002097          	auipc	ra,0x2
    80001a5e:	1da080e7          	jalr	474(ra) # 80003c34 <fsinit>
    80001a62:	bff9                	j	80001a40 <forkret+0x22>

0000000080001a64 <allocpid>:
allocpid() {
    80001a64:	1101                	addi	sp,sp,-32
    80001a66:	ec06                	sd	ra,24(sp)
    80001a68:	e822                	sd	s0,16(sp)
    80001a6a:	e426                	sd	s1,8(sp)
    80001a6c:	e04a                	sd	s2,0(sp)
    80001a6e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a70:	00010917          	auipc	s2,0x10
    80001a74:	83090913          	addi	s2,s2,-2000 # 800112a0 <pid_lock>
    80001a78:	854a                	mv	a0,s2
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	148080e7          	jalr	328(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a82:	00007797          	auipc	a5,0x7
    80001a86:	02278793          	addi	a5,a5,34 # 80008aa4 <nextpid>
    80001a8a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a8c:	0014871b          	addiw	a4,s1,1
    80001a90:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a92:	854a                	mv	a0,s2
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	1f4080e7          	jalr	500(ra) # 80000c88 <release>
}
    80001a9c:	8526                	mv	a0,s1
    80001a9e:	60e2                	ld	ra,24(sp)
    80001aa0:	6442                	ld	s0,16(sp)
    80001aa2:	64a2                	ld	s1,8(sp)
    80001aa4:	6902                	ld	s2,0(sp)
    80001aa6:	6105                	addi	sp,sp,32
    80001aa8:	8082                	ret

0000000080001aaa <proc_pagetable>:
{
    80001aaa:	1101                	addi	sp,sp,-32
    80001aac:	ec06                	sd	ra,24(sp)
    80001aae:	e822                	sd	s0,16(sp)
    80001ab0:	e426                	sd	s1,8(sp)
    80001ab2:	e04a                	sd	s2,0(sp)
    80001ab4:	1000                	addi	s0,sp,32
    80001ab6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ab8:	00000097          	auipc	ra,0x0
    80001abc:	878080e7          	jalr	-1928(ra) # 80001330 <uvmcreate>
    80001ac0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ac2:	c121                	beqz	a0,80001b02 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ac4:	4729                	li	a4,10
    80001ac6:	00005697          	auipc	a3,0x5
    80001aca:	53a68693          	addi	a3,a3,1338 # 80007000 <_trampoline>
    80001ace:	6605                	lui	a2,0x1
    80001ad0:	040005b7          	lui	a1,0x4000
    80001ad4:	15fd                	addi	a1,a1,-1
    80001ad6:	05b2                	slli	a1,a1,0xc
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	5c8080e7          	jalr	1480(ra) # 800010a0 <mappages>
    80001ae0:	02054863          	bltz	a0,80001b10 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ae4:	4719                	li	a4,6
    80001ae6:	05893683          	ld	a3,88(s2)
    80001aea:	6605                	lui	a2,0x1
    80001aec:	020005b7          	lui	a1,0x2000
    80001af0:	15fd                	addi	a1,a1,-1
    80001af2:	05b6                	slli	a1,a1,0xd
    80001af4:	8526                	mv	a0,s1
    80001af6:	fffff097          	auipc	ra,0xfffff
    80001afa:	5aa080e7          	jalr	1450(ra) # 800010a0 <mappages>
    80001afe:	02054163          	bltz	a0,80001b20 <proc_pagetable+0x76>
}
    80001b02:	8526                	mv	a0,s1
    80001b04:	60e2                	ld	ra,24(sp)
    80001b06:	6442                	ld	s0,16(sp)
    80001b08:	64a2                	ld	s1,8(sp)
    80001b0a:	6902                	ld	s2,0(sp)
    80001b0c:	6105                	addi	sp,sp,32
    80001b0e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b10:	4581                	li	a1,0
    80001b12:	8526                	mv	a0,s1
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	a50080e7          	jalr	-1456(ra) # 80001564 <uvmfree>
    return 0;
    80001b1c:	4481                	li	s1,0
    80001b1e:	b7d5                	j	80001b02 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	8526                	mv	a0,s1
    80001b2e:	fffff097          	auipc	ra,0xfffff
    80001b32:	736080e7          	jalr	1846(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b36:	4581                	li	a1,0
    80001b38:	8526                	mv	a0,s1
    80001b3a:	00000097          	auipc	ra,0x0
    80001b3e:	a2a080e7          	jalr	-1494(ra) # 80001564 <uvmfree>
    return 0;
    80001b42:	4481                	li	s1,0
    80001b44:	bf7d                	j	80001b02 <proc_pagetable+0x58>

0000000080001b46 <proc_freepagetable>:
{
    80001b46:	1101                	addi	sp,sp,-32
    80001b48:	ec06                	sd	ra,24(sp)
    80001b4a:	e822                	sd	s0,16(sp)
    80001b4c:	e426                	sd	s1,8(sp)
    80001b4e:	e04a                	sd	s2,0(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
    80001b54:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b56:	4681                	li	a3,0
    80001b58:	4605                	li	a2,1
    80001b5a:	040005b7          	lui	a1,0x4000
    80001b5e:	15fd                	addi	a1,a1,-1
    80001b60:	05b2                	slli	a1,a1,0xc
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	702080e7          	jalr	1794(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b6a:	4681                	li	a3,0
    80001b6c:	4605                	li	a2,1
    80001b6e:	020005b7          	lui	a1,0x2000
    80001b72:	15fd                	addi	a1,a1,-1
    80001b74:	05b6                	slli	a1,a1,0xd
    80001b76:	8526                	mv	a0,s1
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	6ec080e7          	jalr	1772(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b80:	85ca                	mv	a1,s2
    80001b82:	8526                	mv	a0,s1
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	9e0080e7          	jalr	-1568(ra) # 80001564 <uvmfree>
}
    80001b8c:	60e2                	ld	ra,24(sp)
    80001b8e:	6442                	ld	s0,16(sp)
    80001b90:	64a2                	ld	s1,8(sp)
    80001b92:	6902                	ld	s2,0(sp)
    80001b94:	6105                	addi	sp,sp,32
    80001b96:	8082                	ret

0000000080001b98 <freeproc>:
{
    80001b98:	1101                	addi	sp,sp,-32
    80001b9a:	ec06                	sd	ra,24(sp)
    80001b9c:	e822                	sd	s0,16(sp)
    80001b9e:	e426                	sd	s1,8(sp)
    80001ba0:	1000                	addi	s0,sp,32
    80001ba2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ba4:	6d28                	ld	a0,88(a0)
    80001ba6:	c509                	beqz	a0,80001bb0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	e2e080e7          	jalr	-466(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001bb0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bb4:	68a8                	ld	a0,80(s1)
    80001bb6:	c511                	beqz	a0,80001bc2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bb8:	64ac                	ld	a1,72(s1)
    80001bba:	00000097          	auipc	ra,0x0
    80001bbe:	f8c080e7          	jalr	-116(ra) # 80001b46 <proc_freepagetable>
  p->pagetable = 0;
    80001bc2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bc6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bca:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bce:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bd2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bd6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bda:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bde:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001be2:	0004ac23          	sw	zero,24(s1)
}
    80001be6:	60e2                	ld	ra,24(sp)
    80001be8:	6442                	ld	s0,16(sp)
    80001bea:	64a2                	ld	s1,8(sp)
    80001bec:	6105                	addi	sp,sp,32
    80001bee:	8082                	ret

0000000080001bf0 <allocproc>:
{
    80001bf0:	1101                	addi	sp,sp,-32
    80001bf2:	ec06                	sd	ra,24(sp)
    80001bf4:	e822                	sd	s0,16(sp)
    80001bf6:	e426                	sd	s1,8(sp)
    80001bf8:	e04a                	sd	s2,0(sp)
    80001bfa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfc:	00010497          	auipc	s1,0x10
    80001c00:	ad448493          	addi	s1,s1,-1324 # 800116d0 <proc>
    80001c04:	0001e917          	auipc	s2,0x1e
    80001c08:	8cc90913          	addi	s2,s2,-1844 # 8001f4d0 <tickslock>
    acquire(&p->lock);
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	fb4080e7          	jalr	-76(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001c16:	4c9c                	lw	a5,24(s1)
    80001c18:	cf81                	beqz	a5,80001c30 <allocproc+0x40>
      release(&p->lock);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	06c080e7          	jalr	108(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c24:	37848493          	addi	s1,s1,888
    80001c28:	ff2492e3          	bne	s1,s2,80001c0c <allocproc+0x1c>
  return 0;
    80001c2c:	4481                	li	s1,0
    80001c2e:	a889                	j	80001c80 <allocproc+0x90>
  p->pid = allocpid();
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	e34080e7          	jalr	-460(ra) # 80001a64 <allocpid>
    80001c38:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c3a:	4785                	li	a5,1
    80001c3c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	e94080e7          	jalr	-364(ra) # 80000ad2 <kalloc>
    80001c46:	892a                	mv	s2,a0
    80001c48:	eca8                	sd	a0,88(s1)
    80001c4a:	c131                	beqz	a0,80001c8e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	e5c080e7          	jalr	-420(ra) # 80001aaa <proc_pagetable>
    80001c56:	892a                	mv	s2,a0
    80001c58:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c5a:	c531                	beqz	a0,80001ca6 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c5c:	07000613          	li	a2,112
    80001c60:	4581                	li	a1,0
    80001c62:	06048513          	addi	a0,s1,96
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	06a080e7          	jalr	106(ra) # 80000cd0 <memset>
  p->context.ra = (uint64)forkret;
    80001c6e:	00000797          	auipc	a5,0x0
    80001c72:	db078793          	addi	a5,a5,-592 # 80001a1e <forkret>
    80001c76:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c78:	60bc                	ld	a5,64(s1)
    80001c7a:	6705                	lui	a4,0x1
    80001c7c:	97ba                	add	a5,a5,a4
    80001c7e:	f4bc                	sd	a5,104(s1)
}
    80001c80:	8526                	mv	a0,s1
    80001c82:	60e2                	ld	ra,24(sp)
    80001c84:	6442                	ld	s0,16(sp)
    80001c86:	64a2                	ld	s1,8(sp)
    80001c88:	6902                	ld	s2,0(sp)
    80001c8a:	6105                	addi	sp,sp,32
    80001c8c:	8082                	ret
    freeproc(p);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	f08080e7          	jalr	-248(ra) # 80001b98 <freeproc>
    release(&p->lock);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	fee080e7          	jalr	-18(ra) # 80000c88 <release>
    return 0;
    80001ca2:	84ca                	mv	s1,s2
    80001ca4:	bff1                	j	80001c80 <allocproc+0x90>
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	ef0080e7          	jalr	-272(ra) # 80001b98 <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fd6080e7          	jalr	-42(ra) # 80000c88 <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	b7d1                	j	80001c80 <allocproc+0x90>

0000000080001cbe <userinit>:
{
    80001cbe:	1101                	addi	sp,sp,-32
    80001cc0:	ec06                	sd	ra,24(sp)
    80001cc2:	e822                	sd	s0,16(sp)
    80001cc4:	e426                	sd	s1,8(sp)
    80001cc6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc8:	00000097          	auipc	ra,0x0
    80001ccc:	f28080e7          	jalr	-216(ra) # 80001bf0 <allocproc>
    80001cd0:	84aa                	mv	s1,a0
  initproc = p;
    80001cd2:	00007797          	auipc	a5,0x7
    80001cd6:	34a7bb23          	sd	a0,854(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cda:	03400613          	li	a2,52
    80001cde:	00007597          	auipc	a1,0x7
    80001ce2:	dd258593          	addi	a1,a1,-558 # 80008ab0 <initcode>
    80001ce6:	6928                	ld	a0,80(a0)
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	676080e7          	jalr	1654(ra) # 8000135e <uvminit>
  p->sz = PGSIZE;
    80001cf0:	6785                	lui	a5,0x1
    80001cf2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf4:	6cb8                	ld	a4,88(s1)
    80001cf6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cfa:	6cb8                	ld	a4,88(s1)
    80001cfc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfe:	4641                	li	a2,16
    80001d00:	00006597          	auipc	a1,0x6
    80001d04:	50858593          	addi	a1,a1,1288 # 80008208 <digits+0x1c8>
    80001d08:	15848513          	addi	a0,s1,344
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	116080e7          	jalr	278(ra) # 80000e22 <safestrcpy>
  p->cwd = namei("/");
    80001d14:	00006517          	auipc	a0,0x6
    80001d18:	50450513          	addi	a0,a0,1284 # 80008218 <digits+0x1d8>
    80001d1c:	00003097          	auipc	ra,0x3
    80001d20:	946080e7          	jalr	-1722(ra) # 80004662 <namei>
    80001d24:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d28:	478d                	li	a5,3
    80001d2a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	f5a080e7          	jalr	-166(ra) # 80000c88 <release>
}
    80001d36:	60e2                	ld	ra,24(sp)
    80001d38:	6442                	ld	s0,16(sp)
    80001d3a:	64a2                	ld	s1,8(sp)
    80001d3c:	6105                	addi	sp,sp,32
    80001d3e:	8082                	ret

0000000080001d40 <growproc>:
{
    80001d40:	1101                	addi	sp,sp,-32
    80001d42:	ec06                	sd	ra,24(sp)
    80001d44:	e822                	sd	s0,16(sp)
    80001d46:	e426                	sd	s1,8(sp)
    80001d48:	e04a                	sd	s2,0(sp)
    80001d4a:	1000                	addi	s0,sp,32
    80001d4c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	c98080e7          	jalr	-872(ra) # 800019e6 <myproc>
    80001d56:	892a                	mv	s2,a0
  sz = p->sz;
    80001d58:	652c                	ld	a1,72(a0)
    80001d5a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d5e:	00904f63          	bgtz	s1,80001d7c <growproc+0x3c>
  } else if(n < 0){
    80001d62:	0204cc63          	bltz	s1,80001d9a <growproc+0x5a>
  p->sz = sz;
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d6e:	4501                	li	a0,0
}
    80001d70:	60e2                	ld	ra,24(sp)
    80001d72:	6442                	ld	s0,16(sp)
    80001d74:	64a2                	ld	s1,8(sp)
    80001d76:	6902                	ld	s2,0(sp)
    80001d78:	6105                	addi	sp,sp,32
    80001d7a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d7c:	9e25                	addw	a2,a2,s1
    80001d7e:	1602                	slli	a2,a2,0x20
    80001d80:	9201                	srli	a2,a2,0x20
    80001d82:	1582                	slli	a1,a1,0x20
    80001d84:	9181                	srli	a1,a1,0x20
    80001d86:	6928                	ld	a0,80(a0)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	6be080e7          	jalr	1726(ra) # 80001446 <uvmalloc>
    80001d90:	0005061b          	sext.w	a2,a0
    80001d94:	fa69                	bnez	a2,80001d66 <growproc+0x26>
      return -1;
    80001d96:	557d                	li	a0,-1
    80001d98:	bfe1                	j	80001d70 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9a:	9e25                	addw	a2,a2,s1
    80001d9c:	1602                	slli	a2,a2,0x20
    80001d9e:	9201                	srli	a2,a2,0x20
    80001da0:	1582                	slli	a1,a1,0x20
    80001da2:	9181                	srli	a1,a1,0x20
    80001da4:	6928                	ld	a0,80(a0)
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	62a080e7          	jalr	1578(ra) # 800013d0 <uvmdealloc>
    80001dae:	0005061b          	sext.w	a2,a0
    80001db2:	bf55                	j	80001d66 <growproc+0x26>

0000000080001db4 <copy_swapFile>:
    if(!src || !src->swapFile || !dst || dst->swapFile)
    80001db4:	cd29                	beqz	a0,80001e0e <copy_swapFile+0x5a>
int copy_swapFile(struct proc *src, struct proc *dst) {
    80001db6:	1101                	addi	sp,sp,-32
    80001db8:	ec06                	sd	ra,24(sp)
    80001dba:	e822                	sd	s0,16(sp)
    80001dbc:	e426                	sd	s1,8(sp)
    80001dbe:	e04a                	sd	s2,0(sp)
    80001dc0:	1000                	addi	s0,sp,32
    80001dc2:	84ae                	mv	s1,a1
    if(!src || !src->swapFile || !dst || dst->swapFile)
    80001dc4:	16853783          	ld	a5,360(a0)
    80001dc8:	c7a9                	beqz	a5,80001e12 <copy_swapFile+0x5e>
    80001dca:	c5b1                	beqz	a1,80001e16 <copy_swapFile+0x62>
    80001dcc:	1685b783          	ld	a5,360(a1)
    80001dd0:	e7a9                	bnez	a5,80001e1a <copy_swapFile+0x66>
    char buffer[total_size];
    80001dd2:	77c1                	lui	a5,0xffff0
    80001dd4:	913e                	add	sp,sp,a5
    80001dd6:	890a                	mv	s2,sp
    if(readFromSwapFile(src, buffer, 0, total_size) < 0) {
    80001dd8:	66c1                	lui	a3,0x10
    80001dda:	4601                	li	a2,0
    80001ddc:	858a                	mv	a1,sp
    80001dde:	00003097          	auipc	ra,0x3
    80001de2:	bac080e7          	jalr	-1108(ra) # 8000498a <readFromSwapFile>
    80001de6:	02054c63          	bltz	a0,80001e1e <copy_swapFile+0x6a>
    if(writeToSwapFile(dst, buffer, 0, total_size) < 0) {
    80001dea:	66c1                	lui	a3,0x10
    80001dec:	4601                	li	a2,0
    80001dee:	85ca                	mv	a1,s2
    80001df0:	8526                	mv	a0,s1
    80001df2:	00003097          	auipc	ra,0x3
    80001df6:	b74080e7          	jalr	-1164(ra) # 80004966 <writeToSwapFile>
    80001dfa:	41f5551b          	sraiw	a0,a0,0x1f
}
    80001dfe:	fe040113          	addi	sp,s0,-32
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6902                	ld	s2,0(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret
        return -1;
    80001e0e:	557d                	li	a0,-1
}
    80001e10:	8082                	ret
        return -1;
    80001e12:	557d                	li	a0,-1
    80001e14:	b7ed                	j	80001dfe <copy_swapFile+0x4a>
    80001e16:	557d                	li	a0,-1
    80001e18:	b7dd                	j	80001dfe <copy_swapFile+0x4a>
    80001e1a:	557d                	li	a0,-1
    80001e1c:	b7cd                	j	80001dfe <copy_swapFile+0x4a>
      return -1;
    80001e1e:	557d                	li	a0,-1
    80001e20:	bff9                	j	80001dfe <copy_swapFile+0x4a>

0000000080001e22 <sched>:
{
    80001e22:	7179                	addi	sp,sp,-48
    80001e24:	f406                	sd	ra,40(sp)
    80001e26:	f022                	sd	s0,32(sp)
    80001e28:	ec26                	sd	s1,24(sp)
    80001e2a:	e84a                	sd	s2,16(sp)
    80001e2c:	e44e                	sd	s3,8(sp)
    80001e2e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	bb6080e7          	jalr	-1098(ra) # 800019e6 <myproc>
    80001e38:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	d0e080e7          	jalr	-754(ra) # 80000b48 <holding>
    80001e42:	c93d                	beqz	a0,80001eb8 <sched+0x96>
    80001e44:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001e46:	2781                	sext.w	a5,a5
    80001e48:	079e                	slli	a5,a5,0x7
    80001e4a:	0000f717          	auipc	a4,0xf
    80001e4e:	45670713          	addi	a4,a4,1110 # 800112a0 <pid_lock>
    80001e52:	97ba                	add	a5,a5,a4
    80001e54:	0a87a703          	lw	a4,168(a5) # ffffffffffff00a8 <end+0xffffffff7ffc20a8>
    80001e58:	4785                	li	a5,1
    80001e5a:	06f71763          	bne	a4,a5,80001ec8 <sched+0xa6>
  if(p->state == RUNNING)
    80001e5e:	4c98                	lw	a4,24(s1)
    80001e60:	4791                	li	a5,4
    80001e62:	06f70b63          	beq	a4,a5,80001ed8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e66:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e6a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e6c:	efb5                	bnez	a5,80001ee8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e6e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e70:	0000f917          	auipc	s2,0xf
    80001e74:	43090913          	addi	s2,s2,1072 # 800112a0 <pid_lock>
    80001e78:	2781                	sext.w	a5,a5
    80001e7a:	079e                	slli	a5,a5,0x7
    80001e7c:	97ca                	add	a5,a5,s2
    80001e7e:	0ac7a983          	lw	s3,172(a5)
    80001e82:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e84:	2781                	sext.w	a5,a5
    80001e86:	079e                	slli	a5,a5,0x7
    80001e88:	0000f597          	auipc	a1,0xf
    80001e8c:	45058593          	addi	a1,a1,1104 # 800112d8 <cpus+0x8>
    80001e90:	95be                	add	a1,a1,a5
    80001e92:	06048513          	addi	a0,s1,96
    80001e96:	00001097          	auipc	ra,0x1
    80001e9a:	f7c080e7          	jalr	-132(ra) # 80002e12 <swtch>
    80001e9e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ea0:	2781                	sext.w	a5,a5
    80001ea2:	079e                	slli	a5,a5,0x7
    80001ea4:	97ca                	add	a5,a5,s2
    80001ea6:	0b37a623          	sw	s3,172(a5)
}
    80001eaa:	70a2                	ld	ra,40(sp)
    80001eac:	7402                	ld	s0,32(sp)
    80001eae:	64e2                	ld	s1,24(sp)
    80001eb0:	6942                	ld	s2,16(sp)
    80001eb2:	69a2                	ld	s3,8(sp)
    80001eb4:	6145                	addi	sp,sp,48
    80001eb6:	8082                	ret
    panic("sched p->lock");
    80001eb8:	00006517          	auipc	a0,0x6
    80001ebc:	36850513          	addi	a0,a0,872 # 80008220 <digits+0x1e0>
    80001ec0:	ffffe097          	auipc	ra,0xffffe
    80001ec4:	66a080e7          	jalr	1642(ra) # 8000052a <panic>
    panic("sched locks");
    80001ec8:	00006517          	auipc	a0,0x6
    80001ecc:	36850513          	addi	a0,a0,872 # 80008230 <digits+0x1f0>
    80001ed0:	ffffe097          	auipc	ra,0xffffe
    80001ed4:	65a080e7          	jalr	1626(ra) # 8000052a <panic>
    panic("sched running");
    80001ed8:	00006517          	auipc	a0,0x6
    80001edc:	36850513          	addi	a0,a0,872 # 80008240 <digits+0x200>
    80001ee0:	ffffe097          	auipc	ra,0xffffe
    80001ee4:	64a080e7          	jalr	1610(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001ee8:	00006517          	auipc	a0,0x6
    80001eec:	36850513          	addi	a0,a0,872 # 80008250 <digits+0x210>
    80001ef0:	ffffe097          	auipc	ra,0xffffe
    80001ef4:	63a080e7          	jalr	1594(ra) # 8000052a <panic>

0000000080001ef8 <yield>:
{
    80001ef8:	1101                	addi	sp,sp,-32
    80001efa:	ec06                	sd	ra,24(sp)
    80001efc:	e822                	sd	s0,16(sp)
    80001efe:	e426                	sd	s1,8(sp)
    80001f00:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	ae4080e7          	jalr	-1308(ra) # 800019e6 <myproc>
    80001f0a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	cb6080e7          	jalr	-842(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80001f14:	478d                	li	a5,3
    80001f16:	cc9c                	sw	a5,24(s1)
  sched();
    80001f18:	00000097          	auipc	ra,0x0
    80001f1c:	f0a080e7          	jalr	-246(ra) # 80001e22 <sched>
  release(&p->lock);
    80001f20:	8526                	mv	a0,s1
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	d66080e7          	jalr	-666(ra) # 80000c88 <release>
}
    80001f2a:	60e2                	ld	ra,24(sp)
    80001f2c:	6442                	ld	s0,16(sp)
    80001f2e:	64a2                	ld	s1,8(sp)
    80001f30:	6105                	addi	sp,sp,32
    80001f32:	8082                	ret

0000000080001f34 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001f34:	7179                	addi	sp,sp,-48
    80001f36:	f406                	sd	ra,40(sp)
    80001f38:	f022                	sd	s0,32(sp)
    80001f3a:	ec26                	sd	s1,24(sp)
    80001f3c:	e84a                	sd	s2,16(sp)
    80001f3e:	e44e                	sd	s3,8(sp)
    80001f40:	1800                	addi	s0,sp,48
    80001f42:	89aa                	mv	s3,a0
    80001f44:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	aa0080e7          	jalr	-1376(ra) # 800019e6 <myproc>
    80001f4e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	c72080e7          	jalr	-910(ra) # 80000bc2 <acquire>
  release(lk);
    80001f58:	854a                	mv	a0,s2
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d2e080e7          	jalr	-722(ra) # 80000c88 <release>

  // Go to sleep.
  p->chan = chan;
    80001f62:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001f66:	4789                	li	a5,2
    80001f68:	cc9c                	sw	a5,24(s1)

  sched();
    80001f6a:	00000097          	auipc	ra,0x0
    80001f6e:	eb8080e7          	jalr	-328(ra) # 80001e22 <sched>

  // Tidy up.
  p->chan = 0;
    80001f72:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f76:	8526                	mv	a0,s1
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	d10080e7          	jalr	-752(ra) # 80000c88 <release>
  acquire(lk);
    80001f80:	854a                	mv	a0,s2
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	c40080e7          	jalr	-960(ra) # 80000bc2 <acquire>
}
    80001f8a:	70a2                	ld	ra,40(sp)
    80001f8c:	7402                	ld	s0,32(sp)
    80001f8e:	64e2                	ld	s1,24(sp)
    80001f90:	6942                	ld	s2,16(sp)
    80001f92:	69a2                	ld	s3,8(sp)
    80001f94:	6145                	addi	sp,sp,48
    80001f96:	8082                	ret

0000000080001f98 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80001f98:	7139                	addi	sp,sp,-64
    80001f9a:	fc06                	sd	ra,56(sp)
    80001f9c:	f822                	sd	s0,48(sp)
    80001f9e:	f426                	sd	s1,40(sp)
    80001fa0:	f04a                	sd	s2,32(sp)
    80001fa2:	ec4e                	sd	s3,24(sp)
    80001fa4:	e852                	sd	s4,16(sp)
    80001fa6:	e456                	sd	s5,8(sp)
    80001fa8:	0080                	addi	s0,sp,64
    80001faa:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001fac:	0000f497          	auipc	s1,0xf
    80001fb0:	72448493          	addi	s1,s1,1828 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001fb4:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001fb6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fb8:	0001d917          	auipc	s2,0x1d
    80001fbc:	51890913          	addi	s2,s2,1304 # 8001f4d0 <tickslock>
    80001fc0:	a811                	j	80001fd4 <wakeup+0x3c>
      }
      release(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	cc4080e7          	jalr	-828(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fcc:	37848493          	addi	s1,s1,888
    80001fd0:	03248663          	beq	s1,s2,80001ffc <wakeup+0x64>
    if(p != myproc()){
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	a12080e7          	jalr	-1518(ra) # 800019e6 <myproc>
    80001fdc:	fea488e3          	beq	s1,a0,80001fcc <wakeup+0x34>
      acquire(&p->lock);
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	be0080e7          	jalr	-1056(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001fea:	4c9c                	lw	a5,24(s1)
    80001fec:	fd379be3          	bne	a5,s3,80001fc2 <wakeup+0x2a>
    80001ff0:	709c                	ld	a5,32(s1)
    80001ff2:	fd4798e3          	bne	a5,s4,80001fc2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80001ff6:	0154ac23          	sw	s5,24(s1)
    80001ffa:	b7e1                	j	80001fc2 <wakeup+0x2a>
    }
  }
}
    80001ffc:	70e2                	ld	ra,56(sp)
    80001ffe:	7442                	ld	s0,48(sp)
    80002000:	74a2                	ld	s1,40(sp)
    80002002:	7902                	ld	s2,32(sp)
    80002004:	69e2                	ld	s3,24(sp)
    80002006:	6a42                	ld	s4,16(sp)
    80002008:	6aa2                	ld	s5,8(sp)
    8000200a:	6121                	addi	sp,sp,64
    8000200c:	8082                	ret

000000008000200e <reparent>:
{
    8000200e:	7179                	addi	sp,sp,-48
    80002010:	f406                	sd	ra,40(sp)
    80002012:	f022                	sd	s0,32(sp)
    80002014:	ec26                	sd	s1,24(sp)
    80002016:	e84a                	sd	s2,16(sp)
    80002018:	e44e                	sd	s3,8(sp)
    8000201a:	e052                	sd	s4,0(sp)
    8000201c:	1800                	addi	s0,sp,48
    8000201e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002020:	0000f497          	auipc	s1,0xf
    80002024:	6b048493          	addi	s1,s1,1712 # 800116d0 <proc>
      pp->parent = initproc;
    80002028:	00007a17          	auipc	s4,0x7
    8000202c:	000a0a13          	mv	s4,s4
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002030:	0001d997          	auipc	s3,0x1d
    80002034:	4a098993          	addi	s3,s3,1184 # 8001f4d0 <tickslock>
    80002038:	a029                	j	80002042 <reparent+0x34>
    8000203a:	37848493          	addi	s1,s1,888
    8000203e:	01348d63          	beq	s1,s3,80002058 <reparent+0x4a>
    if(pp->parent == p){
    80002042:	7c9c                	ld	a5,56(s1)
    80002044:	ff279be3          	bne	a5,s2,8000203a <reparent+0x2c>
      pp->parent = initproc;
    80002048:	000a3503          	ld	a0,0(s4) # 80009028 <initproc>
    8000204c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	f4a080e7          	jalr	-182(ra) # 80001f98 <wakeup>
    80002056:	b7d5                	j	8000203a <reparent+0x2c>
}
    80002058:	70a2                	ld	ra,40(sp)
    8000205a:	7402                	ld	s0,32(sp)
    8000205c:	64e2                	ld	s1,24(sp)
    8000205e:	6942                	ld	s2,16(sp)
    80002060:	69a2                	ld	s3,8(sp)
    80002062:	6a02                	ld	s4,0(sp)
    80002064:	6145                	addi	sp,sp,48
    80002066:	8082                	ret

0000000080002068 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002068:	7179                	addi	sp,sp,-48
    8000206a:	f406                	sd	ra,40(sp)
    8000206c:	f022                	sd	s0,32(sp)
    8000206e:	ec26                	sd	s1,24(sp)
    80002070:	e84a                	sd	s2,16(sp)
    80002072:	e44e                	sd	s3,8(sp)
    80002074:	1800                	addi	s0,sp,48
    80002076:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002078:	0000f497          	auipc	s1,0xf
    8000207c:	65848493          	addi	s1,s1,1624 # 800116d0 <proc>
    80002080:	0001d997          	auipc	s3,0x1d
    80002084:	45098993          	addi	s3,s3,1104 # 8001f4d0 <tickslock>
    acquire(&p->lock);
    80002088:	8526                	mv	a0,s1
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	b38080e7          	jalr	-1224(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    80002092:	589c                	lw	a5,48(s1)
    80002094:	01278d63          	beq	a5,s2,800020ae <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bee080e7          	jalr	-1042(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800020a2:	37848493          	addi	s1,s1,888
    800020a6:	ff3491e3          	bne	s1,s3,80002088 <kill+0x20>
  }
  return -1;
    800020aa:	557d                	li	a0,-1
    800020ac:	a829                	j	800020c6 <kill+0x5e>
      p->killed = 1;
    800020ae:	4785                	li	a5,1
    800020b0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800020b2:	4c98                	lw	a4,24(s1)
    800020b4:	4789                	li	a5,2
    800020b6:	00f70f63          	beq	a4,a5,800020d4 <kill+0x6c>
      release(&p->lock);
    800020ba:	8526                	mv	a0,s1
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	bcc080e7          	jalr	-1076(ra) # 80000c88 <release>
      return 0;
    800020c4:	4501                	li	a0,0
}
    800020c6:	70a2                	ld	ra,40(sp)
    800020c8:	7402                	ld	s0,32(sp)
    800020ca:	64e2                	ld	s1,24(sp)
    800020cc:	6942                	ld	s2,16(sp)
    800020ce:	69a2                	ld	s3,8(sp)
    800020d0:	6145                	addi	sp,sp,48
    800020d2:	8082                	ret
        p->state = RUNNABLE;
    800020d4:	478d                	li	a5,3
    800020d6:	cc9c                	sw	a5,24(s1)
    800020d8:	b7cd                	j	800020ba <kill+0x52>

00000000800020da <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800020da:	7179                	addi	sp,sp,-48
    800020dc:	f406                	sd	ra,40(sp)
    800020de:	f022                	sd	s0,32(sp)
    800020e0:	ec26                	sd	s1,24(sp)
    800020e2:	e84a                	sd	s2,16(sp)
    800020e4:	e44e                	sd	s3,8(sp)
    800020e6:	e052                	sd	s4,0(sp)
    800020e8:	1800                	addi	s0,sp,48
    800020ea:	84aa                	mv	s1,a0
    800020ec:	892e                	mv	s2,a1
    800020ee:	89b2                	mv	s3,a2
    800020f0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	8f4080e7          	jalr	-1804(ra) # 800019e6 <myproc>
  if(user_dst){
    800020fa:	c08d                	beqz	s1,8000211c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800020fc:	86d2                	mv	a3,s4
    800020fe:	864e                	mv	a2,s3
    80002100:	85ca                	mv	a1,s2
    80002102:	6928                	ld	a0,80(a0)
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	5a2080e7          	jalr	1442(ra) # 800016a6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000210c:	70a2                	ld	ra,40(sp)
    8000210e:	7402                	ld	s0,32(sp)
    80002110:	64e2                	ld	s1,24(sp)
    80002112:	6942                	ld	s2,16(sp)
    80002114:	69a2                	ld	s3,8(sp)
    80002116:	6a02                	ld	s4,0(sp)
    80002118:	6145                	addi	sp,sp,48
    8000211a:	8082                	ret
    memmove((char *)dst, src, len);
    8000211c:	000a061b          	sext.w	a2,s4
    80002120:	85ce                	mv	a1,s3
    80002122:	854a                	mv	a0,s2
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	c08080e7          	jalr	-1016(ra) # 80000d2c <memmove>
    return 0;
    8000212c:	8526                	mv	a0,s1
    8000212e:	bff9                	j	8000210c <either_copyout+0x32>

0000000080002130 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002130:	7179                	addi	sp,sp,-48
    80002132:	f406                	sd	ra,40(sp)
    80002134:	f022                	sd	s0,32(sp)
    80002136:	ec26                	sd	s1,24(sp)
    80002138:	e84a                	sd	s2,16(sp)
    8000213a:	e44e                	sd	s3,8(sp)
    8000213c:	e052                	sd	s4,0(sp)
    8000213e:	1800                	addi	s0,sp,48
    80002140:	892a                	mv	s2,a0
    80002142:	84ae                	mv	s1,a1
    80002144:	89b2                	mv	s3,a2
    80002146:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	89e080e7          	jalr	-1890(ra) # 800019e6 <myproc>
  if(user_src){
    80002150:	c08d                	beqz	s1,80002172 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002152:	86d2                	mv	a3,s4
    80002154:	864e                	mv	a2,s3
    80002156:	85ca                	mv	a1,s2
    80002158:	6928                	ld	a0,80(a0)
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	5d8080e7          	jalr	1496(ra) # 80001732 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002162:	70a2                	ld	ra,40(sp)
    80002164:	7402                	ld	s0,32(sp)
    80002166:	64e2                	ld	s1,24(sp)
    80002168:	6942                	ld	s2,16(sp)
    8000216a:	69a2                	ld	s3,8(sp)
    8000216c:	6a02                	ld	s4,0(sp)
    8000216e:	6145                	addi	sp,sp,48
    80002170:	8082                	ret
    memmove(dst, (char*)src, len);
    80002172:	000a061b          	sext.w	a2,s4
    80002176:	85ce                	mv	a1,s3
    80002178:	854a                	mv	a0,s2
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	bb2080e7          	jalr	-1102(ra) # 80000d2c <memmove>
    return 0;
    80002182:	8526                	mv	a0,s1
    80002184:	bff9                	j	80002162 <either_copyin+0x32>

0000000080002186 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002186:	715d                	addi	sp,sp,-80
    80002188:	e486                	sd	ra,72(sp)
    8000218a:	e0a2                	sd	s0,64(sp)
    8000218c:	fc26                	sd	s1,56(sp)
    8000218e:	f84a                	sd	s2,48(sp)
    80002190:	f44e                	sd	s3,40(sp)
    80002192:	f052                	sd	s4,32(sp)
    80002194:	ec56                	sd	s5,24(sp)
    80002196:	e85a                	sd	s6,16(sp)
    80002198:	e45e                	sd	s7,8(sp)
    8000219a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000219c:	00006517          	auipc	a0,0x6
    800021a0:	f4c50513          	addi	a0,a0,-180 # 800080e8 <digits+0xa8>
    800021a4:	ffffe097          	auipc	ra,0xffffe
    800021a8:	3d0080e7          	jalr	976(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800021ac:	0000f497          	auipc	s1,0xf
    800021b0:	67c48493          	addi	s1,s1,1660 # 80011828 <proc+0x158>
    800021b4:	0001d917          	auipc	s2,0x1d
    800021b8:	47490913          	addi	s2,s2,1140 # 8001f628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800021bc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800021be:	00006997          	auipc	s3,0x6
    800021c2:	0aa98993          	addi	s3,s3,170 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800021c6:	00006a97          	auipc	s5,0x6
    800021ca:	0aaa8a93          	addi	s5,s5,170 # 80008270 <digits+0x230>
    printf("\n");
    800021ce:	00006a17          	auipc	s4,0x6
    800021d2:	f1aa0a13          	addi	s4,s4,-230 # 800080e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800021d6:	00006b97          	auipc	s7,0x6
    800021da:	342b8b93          	addi	s7,s7,834 # 80008518 <states.0>
    800021de:	a00d                	j	80002200 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800021e0:	ed86a583          	lw	a1,-296(a3) # fed8 <_entry-0x7fff0128>
    800021e4:	8556                	mv	a0,s5
    800021e6:	ffffe097          	auipc	ra,0xffffe
    800021ea:	38e080e7          	jalr	910(ra) # 80000574 <printf>
    printf("\n");
    800021ee:	8552                	mv	a0,s4
    800021f0:	ffffe097          	auipc	ra,0xffffe
    800021f4:	384080e7          	jalr	900(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800021f8:	37848493          	addi	s1,s1,888
    800021fc:	03248263          	beq	s1,s2,80002220 <procdump+0x9a>
    if(p->state == UNUSED)
    80002200:	86a6                	mv	a3,s1
    80002202:	ec04a783          	lw	a5,-320(s1)
    80002206:	dbed                	beqz	a5,800021f8 <procdump+0x72>
      state = "???";
    80002208:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000220a:	fcfb6be3          	bltu	s6,a5,800021e0 <procdump+0x5a>
    8000220e:	02079713          	slli	a4,a5,0x20
    80002212:	01d75793          	srli	a5,a4,0x1d
    80002216:	97de                	add	a5,a5,s7
    80002218:	6390                	ld	a2,0(a5)
    8000221a:	f279                	bnez	a2,800021e0 <procdump+0x5a>
      state = "???";
    8000221c:	864e                	mv	a2,s3
    8000221e:	b7c9                	j	800021e0 <procdump+0x5a>
  }
}
    80002220:	60a6                	ld	ra,72(sp)
    80002222:	6406                	ld	s0,64(sp)
    80002224:	74e2                	ld	s1,56(sp)
    80002226:	7942                	ld	s2,48(sp)
    80002228:	79a2                	ld	s3,40(sp)
    8000222a:	7a02                	ld	s4,32(sp)
    8000222c:	6ae2                	ld	s5,24(sp)
    8000222e:	6b42                	ld	s6,16(sp)
    80002230:	6ba2                	ld	s7,8(sp)
    80002232:	6161                	addi	sp,sp,80
    80002234:	8082                	ret

0000000080002236 <init_metadata>:

// ADDED Q1
int init_metadata(struct proc *p)
{
    80002236:	1101                	addi	sp,sp,-32
    80002238:	ec06                	sd	ra,24(sp)
    8000223a:	e822                	sd	s0,16(sp)
    8000223c:	e426                	sd	s1,8(sp)
    8000223e:	1000                	addi	s0,sp,32
    80002240:	84aa                	mv	s1,a0
  if (!p->swapFile && createSwapFile(p) < 0) {
    80002242:	16853783          	ld	a5,360(a0)
    80002246:	cf95                	beqz	a5,80002282 <init_metadata+0x4c>
    return -1;
  }

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002248:	17048793          	addi	a5,s1,368
{
    8000224c:	4701                	li	a4,0
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000224e:	6605                	lui	a2,0x1
    80002250:	66c1                	lui	a3,0x10
    p->ram_pages[i].va = 0;
    80002252:	0007b023          	sd	zero,0(a5)
    p->ram_pages[i].age = 0; // ADDED Q2
    80002256:	0007a423          	sw	zero,8(a5)
    p->ram_pages[i].used = 0;
    8000225a:	0007a623          	sw	zero,12(a5)
    
    p->disk_pages[i].va = 0;
    8000225e:	1007b023          	sd	zero,256(a5)
    p->disk_pages[i].offset = i * PGSIZE;
    80002262:	10e7a423          	sw	a4,264(a5)
    p->disk_pages[i].used = 0;
    80002266:	1007a623          	sw	zero,268(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000226a:	07c1                	addi	a5,a5,16
    8000226c:	9f31                	addw	a4,a4,a2
    8000226e:	fed712e3          	bne	a4,a3,80002252 <init_metadata+0x1c>
    80002272:	3604a823          	sw	zero,880(s1)

    p->scfifo_index = 0; // ADDED Q2
  }
  return 0;
    80002276:	4501                	li	a0,0
}
    80002278:	60e2                	ld	ra,24(sp)
    8000227a:	6442                	ld	s0,16(sp)
    8000227c:	64a2                	ld	s1,8(sp)
    8000227e:	6105                	addi	sp,sp,32
    80002280:	8082                	ret
  if (!p->swapFile && createSwapFile(p) < 0) {
    80002282:	00002097          	auipc	ra,0x2
    80002286:	634080e7          	jalr	1588(ra) # 800048b6 <createSwapFile>
    8000228a:	fa055fe3          	bgez	a0,80002248 <init_metadata+0x12>
    return -1;
    8000228e:	557d                	li	a0,-1
    80002290:	b7e5                	j	80002278 <init_metadata+0x42>

0000000080002292 <free_metadata>:

void free_metadata(struct proc *p)
{
    80002292:	1101                	addi	sp,sp,-32
    80002294:	ec06                	sd	ra,24(sp)
    80002296:	e822                	sd	s0,16(sp)
    80002298:	e426                	sd	s1,8(sp)
    8000229a:	1000                	addi	s0,sp,32
    8000229c:	84aa                	mv	s1,a0
    if (removeSwapFile(p) < 0) {
    8000229e:	00002097          	auipc	ra,0x2
    800022a2:	470080e7          	jalr	1136(ra) # 8000470e <removeSwapFile>
    800022a6:	02054c63          	bltz	a0,800022de <free_metadata+0x4c>
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;
    800022aa:	1604b423          	sd	zero,360(s1)

    for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800022ae:	17048793          	addi	a5,s1,368
    800022b2:	27048713          	addi	a4,s1,624
      p->ram_pages[i].va = 0;
    800022b6:	0007b023          	sd	zero,0(a5)
      p->ram_pages[i].age = 0; // ADDED Q2
    800022ba:	0007a423          	sw	zero,8(a5)
      p->ram_pages[i].used = 0;
    800022be:	0007a623          	sw	zero,12(a5)

      p->disk_pages[i].va = 0;
    800022c2:	1007b023          	sd	zero,256(a5)
      p->disk_pages[i].offset = 0;
    800022c6:	1007a423          	sw	zero,264(a5)
      p->disk_pages[i].used = 0;
    800022ca:	1007a623          	sw	zero,268(a5)
    for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800022ce:	07c1                	addi	a5,a5,16
    800022d0:	fee793e3          	bne	a5,a4,800022b6 <free_metadata+0x24>
    }
}
    800022d4:	60e2                	ld	ra,24(sp)
    800022d6:	6442                	ld	s0,16(sp)
    800022d8:	64a2                	ld	s1,8(sp)
    800022da:	6105                	addi	sp,sp,32
    800022dc:	8082                	ret
      panic("free_metadata: removeSwapFile failed");
    800022de:	00006517          	auipc	a0,0x6
    800022e2:	fa250513          	addi	a0,a0,-94 # 80008280 <digits+0x240>
    800022e6:	ffffe097          	auipc	ra,0xffffe
    800022ea:	244080e7          	jalr	580(ra) # 8000052a <panic>

00000000800022ee <fork>:
{
    800022ee:	7139                	addi	sp,sp,-64
    800022f0:	fc06                	sd	ra,56(sp)
    800022f2:	f822                	sd	s0,48(sp)
    800022f4:	f426                	sd	s1,40(sp)
    800022f6:	f04a                	sd	s2,32(sp)
    800022f8:	ec4e                	sd	s3,24(sp)
    800022fa:	e852                	sd	s4,16(sp)
    800022fc:	e456                	sd	s5,8(sp)
    800022fe:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	6e6080e7          	jalr	1766(ra) # 800019e6 <myproc>
    80002308:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	8e6080e7          	jalr	-1818(ra) # 80001bf0 <allocproc>
    80002312:	1a050b63          	beqz	a0,800024c8 <fork+0x1da>
    80002316:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002318:	048ab603          	ld	a2,72(s5)
    8000231c:	692c                	ld	a1,80(a0)
    8000231e:	050ab503          	ld	a0,80(s5)
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	27a080e7          	jalr	634(ra) # 8000159c <uvmcopy>
    8000232a:	04054863          	bltz	a0,8000237a <fork+0x8c>
  np->sz = p->sz;
    8000232e:	048ab783          	ld	a5,72(s5)
    80002332:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002336:	058ab683          	ld	a3,88(s5)
    8000233a:	87b6                	mv	a5,a3
    8000233c:	0589b703          	ld	a4,88(s3)
    80002340:	12068693          	addi	a3,a3,288 # 10120 <_entry-0x7ffefee0>
    80002344:	0007b803          	ld	a6,0(a5)
    80002348:	6788                	ld	a0,8(a5)
    8000234a:	6b8c                	ld	a1,16(a5)
    8000234c:	6f90                	ld	a2,24(a5)
    8000234e:	01073023          	sd	a6,0(a4)
    80002352:	e708                	sd	a0,8(a4)
    80002354:	eb0c                	sd	a1,16(a4)
    80002356:	ef10                	sd	a2,24(a4)
    80002358:	02078793          	addi	a5,a5,32
    8000235c:	02070713          	addi	a4,a4,32
    80002360:	fed792e3          	bne	a5,a3,80002344 <fork+0x56>
  np->trapframe->a0 = 0;
    80002364:	0589b783          	ld	a5,88(s3)
    80002368:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000236c:	0d0a8493          	addi	s1,s5,208
    80002370:	0d098913          	addi	s2,s3,208
    80002374:	150a8a13          	addi	s4,s5,336
    80002378:	a00d                	j	8000239a <fork+0xac>
    freeproc(np);
    8000237a:	854e                	mv	a0,s3
    8000237c:	00000097          	auipc	ra,0x0
    80002380:	81c080e7          	jalr	-2020(ra) # 80001b98 <freeproc>
    release(&np->lock);
    80002384:	854e                	mv	a0,s3
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	902080e7          	jalr	-1790(ra) # 80000c88 <release>
    return -1;
    8000238e:	54fd                	li	s1,-1
    80002390:	a8f1                	j	8000246c <fork+0x17e>
  for(i = 0; i < NOFILE; i++)
    80002392:	04a1                	addi	s1,s1,8
    80002394:	0921                	addi	s2,s2,8
    80002396:	01448b63          	beq	s1,s4,800023ac <fork+0xbe>
    if(p->ofile[i])
    8000239a:	6088                	ld	a0,0(s1)
    8000239c:	d97d                	beqz	a0,80002392 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000239e:	00003097          	auipc	ra,0x3
    800023a2:	c70080e7          	jalr	-912(ra) # 8000500e <filedup>
    800023a6:	00a93023          	sd	a0,0(s2)
    800023aa:	b7e5                	j	80002392 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800023ac:	150ab503          	ld	a0,336(s5)
    800023b0:	00002097          	auipc	ra,0x2
    800023b4:	abe080e7          	jalr	-1346(ra) # 80003e6e <idup>
    800023b8:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800023bc:	4641                	li	a2,16
    800023be:	158a8593          	addi	a1,s5,344
    800023c2:	15898513          	addi	a0,s3,344
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	a5c080e7          	jalr	-1444(ra) # 80000e22 <safestrcpy>
  pid = np->pid;
    800023ce:	0309a483          	lw	s1,48(s3)
  if (np->pid != INIT_PID && np->pid != SHELL_PID) {
    800023d2:	fff4871b          	addiw	a4,s1,-1
    800023d6:	4785                	li	a5,1
    800023d8:	0ae7e463          	bltu	a5,a4,80002480 <fork+0x192>
  if (p->pid != INIT_PID && p->pid != SHELL_PID) {
    800023dc:	030aa783          	lw	a5,48(s5)
    800023e0:	37fd                	addiw	a5,a5,-1
    800023e2:	4705                	li	a4,1
    800023e4:	04f77263          	bgeu	a4,a5,80002428 <fork+0x13a>
    if (copy_swapFile(p, np) < 0) {
    800023e8:	85ce                	mv	a1,s3
    800023ea:	8556                	mv	a0,s5
    800023ec:	00000097          	auipc	ra,0x0
    800023f0:	9c8080e7          	jalr	-1592(ra) # 80001db4 <copy_swapFile>
    800023f4:	0a054963          	bltz	a0,800024a6 <fork+0x1b8>
    memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
    800023f8:	10000613          	li	a2,256
    800023fc:	170a8593          	addi	a1,s5,368
    80002400:	17098513          	addi	a0,s3,368
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	928080e7          	jalr	-1752(ra) # 80000d2c <memmove>
    memmove(np->disk_pages, p->disk_pages, sizeof(p->disk_pages));
    8000240c:	10000613          	li	a2,256
    80002410:	270a8593          	addi	a1,s5,624
    80002414:	27098513          	addi	a0,s3,624
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	914080e7          	jalr	-1772(ra) # 80000d2c <memmove>
    np->scfifo_index = p->scfifo_index; // ADDED Q2;
    80002420:	370aa783          	lw	a5,880(s5)
    80002424:	36f9a823          	sw	a5,880(s3)
  release(&np->lock);
    80002428:	854e                	mv	a0,s3
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	85e080e7          	jalr	-1954(ra) # 80000c88 <release>
  acquire(&wait_lock);
    80002432:	0000f917          	auipc	s2,0xf
    80002436:	e8690913          	addi	s2,s2,-378 # 800112b8 <wait_lock>
    8000243a:	854a                	mv	a0,s2
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	786080e7          	jalr	1926(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002444:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002448:	854a                	mv	a0,s2
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	83e080e7          	jalr	-1986(ra) # 80000c88 <release>
  acquire(&np->lock);
    80002452:	854e                	mv	a0,s3
    80002454:	ffffe097          	auipc	ra,0xffffe
    80002458:	76e080e7          	jalr	1902(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    8000245c:	478d                	li	a5,3
    8000245e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002462:	854e                	mv	a0,s3
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	824080e7          	jalr	-2012(ra) # 80000c88 <release>
}
    8000246c:	8526                	mv	a0,s1
    8000246e:	70e2                	ld	ra,56(sp)
    80002470:	7442                	ld	s0,48(sp)
    80002472:	74a2                	ld	s1,40(sp)
    80002474:	7902                	ld	s2,32(sp)
    80002476:	69e2                	ld	s3,24(sp)
    80002478:	6a42                	ld	s4,16(sp)
    8000247a:	6aa2                	ld	s5,8(sp)
    8000247c:	6121                	addi	sp,sp,64
    8000247e:	8082                	ret
    if (init_metadata(np) < 0) {
    80002480:	854e                	mv	a0,s3
    80002482:	00000097          	auipc	ra,0x0
    80002486:	db4080e7          	jalr	-588(ra) # 80002236 <init_metadata>
    8000248a:	f40559e3          	bgez	a0,800023dc <fork+0xee>
      freeproc(np);
    8000248e:	854e                	mv	a0,s3
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	708080e7          	jalr	1800(ra) # 80001b98 <freeproc>
      release(&np->lock);
    80002498:	854e                	mv	a0,s3
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	7ee080e7          	jalr	2030(ra) # 80000c88 <release>
      return -1;
    800024a2:	54fd                	li	s1,-1
    800024a4:	b7e1                	j	8000246c <fork+0x17e>
      freeproc(np);
    800024a6:	854e                	mv	a0,s3
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	6f0080e7          	jalr	1776(ra) # 80001b98 <freeproc>
      free_metadata(np);
    800024b0:	854e                	mv	a0,s3
    800024b2:	00000097          	auipc	ra,0x0
    800024b6:	de0080e7          	jalr	-544(ra) # 80002292 <free_metadata>
      release(&np->lock);
    800024ba:	854e                	mv	a0,s3
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7cc080e7          	jalr	1996(ra) # 80000c88 <release>
      return -1;
    800024c4:	54fd                	li	s1,-1
    800024c6:	b75d                	j	8000246c <fork+0x17e>
    return -1;
    800024c8:	54fd                	li	s1,-1
    800024ca:	b74d                	j	8000246c <fork+0x17e>

00000000800024cc <exit>:
{
    800024cc:	7179                	addi	sp,sp,-48
    800024ce:	f406                	sd	ra,40(sp)
    800024d0:	f022                	sd	s0,32(sp)
    800024d2:	ec26                	sd	s1,24(sp)
    800024d4:	e84a                	sd	s2,16(sp)
    800024d6:	e44e                	sd	s3,8(sp)
    800024d8:	e052                	sd	s4,0(sp)
    800024da:	1800                	addi	s0,sp,48
    800024dc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	508080e7          	jalr	1288(ra) # 800019e6 <myproc>
    800024e6:	89aa                	mv	s3,a0
  if(p == initproc)
    800024e8:	00007797          	auipc	a5,0x7
    800024ec:	b407b783          	ld	a5,-1216(a5) # 80009028 <initproc>
    800024f0:	0d050493          	addi	s1,a0,208
    800024f4:	15050913          	addi	s2,a0,336
    800024f8:	02a79363          	bne	a5,a0,8000251e <exit+0x52>
    panic("init exiting");
    800024fc:	00006517          	auipc	a0,0x6
    80002500:	dac50513          	addi	a0,a0,-596 # 800082a8 <digits+0x268>
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	026080e7          	jalr	38(ra) # 8000052a <panic>
      fileclose(f);
    8000250c:	00003097          	auipc	ra,0x3
    80002510:	b54080e7          	jalr	-1196(ra) # 80005060 <fileclose>
      p->ofile[fd] = 0;
    80002514:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002518:	04a1                	addi	s1,s1,8
    8000251a:	01248563          	beq	s1,s2,80002524 <exit+0x58>
    if(p->ofile[fd]){
    8000251e:	6088                	ld	a0,0(s1)
    80002520:	f575                	bnez	a0,8000250c <exit+0x40>
    80002522:	bfdd                	j	80002518 <exit+0x4c>
  if (p->pid != INIT_PID && p->pid != SHELL_PID) {
    80002524:	0309a783          	lw	a5,48(s3)
    80002528:	37fd                	addiw	a5,a5,-1
    8000252a:	4705                	li	a4,1
    8000252c:	08f76163          	bltu	a4,a5,800025ae <exit+0xe2>
  begin_op();
    80002530:	00002097          	auipc	ra,0x2
    80002534:	664080e7          	jalr	1636(ra) # 80004b94 <begin_op>
  iput(p->cwd);
    80002538:	1509b503          	ld	a0,336(s3)
    8000253c:	00002097          	auipc	ra,0x2
    80002540:	b2a080e7          	jalr	-1238(ra) # 80004066 <iput>
  end_op();
    80002544:	00002097          	auipc	ra,0x2
    80002548:	6d0080e7          	jalr	1744(ra) # 80004c14 <end_op>
  p->cwd = 0;
    8000254c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002550:	0000f497          	auipc	s1,0xf
    80002554:	d6848493          	addi	s1,s1,-664 # 800112b8 <wait_lock>
    80002558:	8526                	mv	a0,s1
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	668080e7          	jalr	1640(ra) # 80000bc2 <acquire>
  reparent(p);
    80002562:	854e                	mv	a0,s3
    80002564:	00000097          	auipc	ra,0x0
    80002568:	aaa080e7          	jalr	-1366(ra) # 8000200e <reparent>
  wakeup(p->parent);
    8000256c:	0389b503          	ld	a0,56(s3)
    80002570:	00000097          	auipc	ra,0x0
    80002574:	a28080e7          	jalr	-1496(ra) # 80001f98 <wakeup>
  acquire(&p->lock);
    80002578:	854e                	mv	a0,s3
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	648080e7          	jalr	1608(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002582:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002586:	4795                	li	a5,5
    80002588:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	6fa080e7          	jalr	1786(ra) # 80000c88 <release>
  sched();
    80002596:	00000097          	auipc	ra,0x0
    8000259a:	88c080e7          	jalr	-1908(ra) # 80001e22 <sched>
  panic("zombie exit");
    8000259e:	00006517          	auipc	a0,0x6
    800025a2:	d1a50513          	addi	a0,a0,-742 # 800082b8 <digits+0x278>
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	f84080e7          	jalr	-124(ra) # 8000052a <panic>
    free_metadata(p);
    800025ae:	854e                	mv	a0,s3
    800025b0:	00000097          	auipc	ra,0x0
    800025b4:	ce2080e7          	jalr	-798(ra) # 80002292 <free_metadata>
    800025b8:	bfa5                	j	80002530 <exit+0x64>

00000000800025ba <wait>:
{
    800025ba:	715d                	addi	sp,sp,-80
    800025bc:	e486                	sd	ra,72(sp)
    800025be:	e0a2                	sd	s0,64(sp)
    800025c0:	fc26                	sd	s1,56(sp)
    800025c2:	f84a                	sd	s2,48(sp)
    800025c4:	f44e                	sd	s3,40(sp)
    800025c6:	f052                	sd	s4,32(sp)
    800025c8:	ec56                	sd	s5,24(sp)
    800025ca:	e85a                	sd	s6,16(sp)
    800025cc:	e45e                	sd	s7,8(sp)
    800025ce:	e062                	sd	s8,0(sp)
    800025d0:	0880                	addi	s0,sp,80
    800025d2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025d4:	fffff097          	auipc	ra,0xfffff
    800025d8:	412080e7          	jalr	1042(ra) # 800019e6 <myproc>
    800025dc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025de:	0000f517          	auipc	a0,0xf
    800025e2:	cda50513          	addi	a0,a0,-806 # 800112b8 <wait_lock>
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	5dc080e7          	jalr	1500(ra) # 80000bc2 <acquire>
    havekids = 0;
    800025ee:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025f0:	4a15                	li	s4,5
        havekids = 1;
    800025f2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025f4:	0001d997          	auipc	s3,0x1d
    800025f8:	edc98993          	addi	s3,s3,-292 # 8001f4d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025fc:	0000fc17          	auipc	s8,0xf
    80002600:	cbcc0c13          	addi	s8,s8,-836 # 800112b8 <wait_lock>
    havekids = 0;
    80002604:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002606:	0000f497          	auipc	s1,0xf
    8000260a:	0ca48493          	addi	s1,s1,202 # 800116d0 <proc>
    8000260e:	a059                	j	80002694 <wait+0xda>
          pid = np->pid;
    80002610:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002614:	000b0e63          	beqz	s6,80002630 <wait+0x76>
    80002618:	4691                	li	a3,4
    8000261a:	02c48613          	addi	a2,s1,44
    8000261e:	85da                	mv	a1,s6
    80002620:	05093503          	ld	a0,80(s2)
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	082080e7          	jalr	130(ra) # 800016a6 <copyout>
    8000262c:	02054b63          	bltz	a0,80002662 <wait+0xa8>
          freeproc(np);
    80002630:	8526                	mv	a0,s1
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	566080e7          	jalr	1382(ra) # 80001b98 <freeproc>
          if (p->pid != INIT_PID && p->pid != SHELL_PID) {
    8000263a:	03092783          	lw	a5,48(s2)
    8000263e:	37fd                	addiw	a5,a5,-1
    80002640:	4705                	li	a4,1
    80002642:	02f76f63          	bltu	a4,a5,80002680 <wait+0xc6>
          release(&np->lock);
    80002646:	8526                	mv	a0,s1
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	640080e7          	jalr	1600(ra) # 80000c88 <release>
          release(&wait_lock);
    80002650:	0000f517          	auipc	a0,0xf
    80002654:	c6850513          	addi	a0,a0,-920 # 800112b8 <wait_lock>
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	630080e7          	jalr	1584(ra) # 80000c88 <release>
          return pid;
    80002660:	a88d                	j	800026d2 <wait+0x118>
            release(&np->lock);
    80002662:	8526                	mv	a0,s1
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	624080e7          	jalr	1572(ra) # 80000c88 <release>
            release(&wait_lock);
    8000266c:	0000f517          	auipc	a0,0xf
    80002670:	c4c50513          	addi	a0,a0,-948 # 800112b8 <wait_lock>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	614080e7          	jalr	1556(ra) # 80000c88 <release>
            return -1;
    8000267c:	59fd                	li	s3,-1
    8000267e:	a891                	j	800026d2 <wait+0x118>
            free_metadata(p);
    80002680:	854a                	mv	a0,s2
    80002682:	00000097          	auipc	ra,0x0
    80002686:	c10080e7          	jalr	-1008(ra) # 80002292 <free_metadata>
    8000268a:	bf75                	j	80002646 <wait+0x8c>
    for(np = proc; np < &proc[NPROC]; np++){
    8000268c:	37848493          	addi	s1,s1,888
    80002690:	03348463          	beq	s1,s3,800026b8 <wait+0xfe>
      if(np->parent == p){
    80002694:	7c9c                	ld	a5,56(s1)
    80002696:	ff279be3          	bne	a5,s2,8000268c <wait+0xd2>
        acquire(&np->lock);
    8000269a:	8526                	mv	a0,s1
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	526080e7          	jalr	1318(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800026a4:	4c9c                	lw	a5,24(s1)
    800026a6:	f74785e3          	beq	a5,s4,80002610 <wait+0x56>
        release(&np->lock);
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	5dc080e7          	jalr	1500(ra) # 80000c88 <release>
        havekids = 1;
    800026b4:	8756                	mv	a4,s5
    800026b6:	bfd9                	j	8000268c <wait+0xd2>
    if(!havekids || p->killed){
    800026b8:	c701                	beqz	a4,800026c0 <wait+0x106>
    800026ba:	02892783          	lw	a5,40(s2)
    800026be:	c79d                	beqz	a5,800026ec <wait+0x132>
      release(&wait_lock);
    800026c0:	0000f517          	auipc	a0,0xf
    800026c4:	bf850513          	addi	a0,a0,-1032 # 800112b8 <wait_lock>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	5c0080e7          	jalr	1472(ra) # 80000c88 <release>
      return -1;
    800026d0:	59fd                	li	s3,-1
}
    800026d2:	854e                	mv	a0,s3
    800026d4:	60a6                	ld	ra,72(sp)
    800026d6:	6406                	ld	s0,64(sp)
    800026d8:	74e2                	ld	s1,56(sp)
    800026da:	7942                	ld	s2,48(sp)
    800026dc:	79a2                	ld	s3,40(sp)
    800026de:	7a02                	ld	s4,32(sp)
    800026e0:	6ae2                	ld	s5,24(sp)
    800026e2:	6b42                	ld	s6,16(sp)
    800026e4:	6ba2                	ld	s7,8(sp)
    800026e6:	6c02                	ld	s8,0(sp)
    800026e8:	6161                	addi	sp,sp,80
    800026ea:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026ec:	85e2                	mv	a1,s8
    800026ee:	854a                	mv	a0,s2
    800026f0:	00000097          	auipc	ra,0x0
    800026f4:	844080e7          	jalr	-1980(ra) # 80001f34 <sleep>
    havekids = 0;
    800026f8:	b731                	j	80002604 <wait+0x4a>

00000000800026fa <find_free_page_in_disk>:
// ADDED YONI
int find_free_page_in_disk()
{
    800026fa:	1141                	addi	sp,sp,-16
    800026fc:	e406                	sd	ra,8(sp)
    800026fe:	e022                	sd	s0,0(sp)
    80002700:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	2e4080e7          	jalr	740(ra) # 800019e6 <myproc>
  int index = 0;
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    8000270a:	27050793          	addi	a5,a0,624
  int index = 0;
    8000270e:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    80002710:	46c1                	li	a3,16
    if (!disk_pg->used) {
    80002712:	47d8                	lw	a4,12(a5)
    80002714:	c711                	beqz	a4,80002720 <find_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    80002716:	07c1                	addi	a5,a5,16
    80002718:	2505                	addiw	a0,a0,1
    8000271a:	fed51ce3          	bne	a0,a3,80002712 <find_free_page_in_disk+0x18>
      return index;
    }
  }
  return -1;
    8000271e:	557d                	li	a0,-1
}
    80002720:	60a2                	ld	ra,8(sp)
    80002722:	6402                	ld	s0,0(sp)
    80002724:	0141                	addi	sp,sp,16
    80002726:	8082                	ret

0000000080002728 <swapout>:

void swapout(int ram_pg_index)
{
    80002728:	715d                	addi	sp,sp,-80
    8000272a:	e486                	sd	ra,72(sp)
    8000272c:	e0a2                	sd	s0,64(sp)
    8000272e:	fc26                	sd	s1,56(sp)
    80002730:	f84a                	sd	s2,48(sp)
    80002732:	f44e                	sd	s3,40(sp)
    80002734:	f052                	sd	s4,32(sp)
    80002736:	ec56                	sd	s5,24(sp)
    80002738:	e85a                	sd	s6,16(sp)
    8000273a:	0880                	addi	s0,sp,80
    8000273c:	737d                	lui	t1,0xfffff
    8000273e:	911a                	add	sp,sp,t1
    80002740:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002742:	fffff097          	auipc	ra,0xfffff
    80002746:	2a4080e7          	jalr	676(ra) # 800019e6 <myproc>
  if (ram_pg_index < 0 || ram_pg_index > MAX_PSYC_PAGES) {
    8000274a:	0004871b          	sext.w	a4,s1
    8000274e:	47c1                	li	a5,16
    80002750:	0ce7e063          	bltu	a5,a4,80002810 <swapout+0xe8>
    80002754:	89aa                	mv	s3,a0
  // REMOVE
  // if (!ram_pg->used) {
  //   panic("swapout: page unused");
  // }
  pte_t *pte;
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    80002756:	0492                	slli	s1,s1,0x4
    80002758:	94aa                	add	s1,s1,a0
    8000275a:	4601                	li	a2,0
    8000275c:	1704b583          	ld	a1,368(s1)
    80002760:	6928                	ld	a0,80(a0)
    80002762:	fffff097          	auipc	ra,0xfffff
    80002766:	856080e7          	jalr	-1962(ra) # 80000fb8 <walk>
    8000276a:	8a2a                	mv	s4,a0
    8000276c:	c955                	beqz	a0,80002820 <swapout+0xf8>
  // REMOVE
  // if (!(*pte & PTE_V))
  //   panic("swapout: invalid page");

  int unused_disk_pg_index;
  if ((unused_disk_pg_index = find_free_page_in_disk()) < 0) {
    8000276e:	00000097          	auipc	ra,0x0
    80002772:	f8c080e7          	jalr	-116(ra) # 800026fa <find_free_page_in_disk>
    80002776:	892a                	mv	s2,a0
    80002778:	0a054c63          	bltz	a0,80002830 <swapout+0x108>
    panic("swapout: disk overflow");
  }
  struct disk_page *disk_pg_to_store = &p->disk_pages[unused_disk_pg_index];
  uint64 pa = PTE2PA(*pte);
    8000277c:	000a3a83          	ld	s5,0(s4)
    80002780:	00aada93          	srli	s5,s5,0xa
    80002784:	0ab2                	slli	s5,s5,0xc
  char buffer[PGSIZE];
  memmove(buffer, (void *)pa, PGSIZE); // TODO: Check va as opposed to pa.
    80002786:	77fd                	lui	a5,0xfffff
    80002788:	fc040713          	addi	a4,s0,-64
    8000278c:	97ba                	add	a5,a5,a4
    8000278e:	7b7d                	lui	s6,0xfffff
    80002790:	fb8b0713          	addi	a4,s6,-72 # ffffffffffffefb8 <end+0xffffffff7ffd0fb8>
    80002794:	9722                	add	a4,a4,s0
    80002796:	e31c                	sd	a5,0(a4)
    80002798:	6605                	lui	a2,0x1
    8000279a:	85d6                	mv	a1,s5
    8000279c:	6308                	ld	a0,0(a4)
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	58e080e7          	jalr	1422(ra) # 80000d2c <memmove>
  if (writeToSwapFile(p, buffer, disk_pg_to_store->offset, PGSIZE) < 0) {
    800027a6:	0912                	slli	s2,s2,0x4
    800027a8:	994e                	add	s2,s2,s3
    800027aa:	6685                	lui	a3,0x1
    800027ac:	27892603          	lw	a2,632(s2)
    800027b0:	fb8b0793          	addi	a5,s6,-72
    800027b4:	97a2                	add	a5,a5,s0
    800027b6:	638c                	ld	a1,0(a5)
    800027b8:	854e                	mv	a0,s3
    800027ba:	00002097          	auipc	ra,0x2
    800027be:	1ac080e7          	jalr	428(ra) # 80004966 <writeToSwapFile>
    800027c2:	06054f63          	bltz	a0,80002840 <swapout+0x118>
    panic("swapout: failed to write to swapFile");
  }
  disk_pg_to_store->used = 1;
    800027c6:	4785                	li	a5,1
    800027c8:	26f92e23          	sw	a5,636(s2)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    800027cc:	1704b783          	ld	a5,368(s1)
    800027d0:	26f93823          	sd	a5,624(s2)
  kfree((void *)pa);
    800027d4:	8556                	mv	a0,s5
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	200080e7          	jalr	512(ra) # 800009d6 <kfree>

  ram_pg_to_swap->va = 0;
    800027de:	1604b823          	sd	zero,368(s1)
  ram_pg_to_swap->used = 0;
    800027e2:	1604ae23          	sw	zero,380(s1)

  *pte = *pte & ~PTE_V;
    800027e6:	000a3783          	ld	a5,0(s4)
    800027ea:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    800027ec:	2007e793          	ori	a5,a5,512
    800027f0:	00fa3023          	sd	a5,0(s4)
  asm volatile("sfence.vma zero, zero");
    800027f4:	12000073          	sfence.vma
  sfence_vma();   // clear TLB
}
    800027f8:	6305                	lui	t1,0x1
    800027fa:	911a                	add	sp,sp,t1
    800027fc:	60a6                	ld	ra,72(sp)
    800027fe:	6406                	ld	s0,64(sp)
    80002800:	74e2                	ld	s1,56(sp)
    80002802:	7942                	ld	s2,48(sp)
    80002804:	79a2                	ld	s3,40(sp)
    80002806:	7a02                	ld	s4,32(sp)
    80002808:	6ae2                	ld	s5,24(sp)
    8000280a:	6b42                	ld	s6,16(sp)
    8000280c:	6161                	addi	sp,sp,80
    8000280e:	8082                	ret
    panic("swapout: ram page index out of bounds");
    80002810:	00006517          	auipc	a0,0x6
    80002814:	ab850513          	addi	a0,a0,-1352 # 800082c8 <digits+0x288>
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	d12080e7          	jalr	-750(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    80002820:	00006517          	auipc	a0,0x6
    80002824:	ad050513          	addi	a0,a0,-1328 # 800082f0 <digits+0x2b0>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	d02080e7          	jalr	-766(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    80002830:	00006517          	auipc	a0,0x6
    80002834:	ad850513          	addi	a0,a0,-1320 # 80008308 <digits+0x2c8>
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	cf2080e7          	jalr	-782(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    80002840:	00006517          	auipc	a0,0x6
    80002844:	ae050513          	addi	a0,a0,-1312 # 80008320 <digits+0x2e0>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	ce2080e7          	jalr	-798(ra) # 8000052a <panic>

0000000080002850 <swapin>:

void swapin(int disk_index, int ram_index)
{
    80002850:	715d                	addi	sp,sp,-80
    80002852:	e486                	sd	ra,72(sp)
    80002854:	e0a2                	sd	s0,64(sp)
    80002856:	fc26                	sd	s1,56(sp)
    80002858:	f84a                	sd	s2,48(sp)
    8000285a:	f44e                	sd	s3,40(sp)
    8000285c:	f052                	sd	s4,32(sp)
    8000285e:	ec56                	sd	s5,24(sp)
    80002860:	0880                	addi	s0,sp,80
    80002862:	737d                	lui	t1,0xfffff
    80002864:	0341                	addi	t1,t1,16
    80002866:	911a                	add	sp,sp,t1
    80002868:	892a                	mv	s2,a0
    8000286a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	17a080e7          	jalr	378(ra) # 800019e6 <myproc>
  if (disk_index < 0 || disk_index > MAX_PSYC_PAGES) {
    80002874:	0009071b          	sext.w	a4,s2
    80002878:	47c1                	li	a5,16
    8000287a:	0ae7ee63          	bltu	a5,a4,80002936 <swapin+0xe6>
    8000287e:	8aaa                	mv	s5,a0
    panic("swapin: disk index out of bounds");
  }

  if (ram_index < 0 || ram_index > MAX_PSYC_PAGES) {
    80002880:	0009879b          	sext.w	a5,s3
    80002884:	4741                	li	a4,16
    80002886:	0cf76063          	bltu	a4,a5,80002946 <swapin+0xf6>
  // REMOVE
  // if (!disk_pg->used) {
  //   panic("swapin: page free");
  // }
  pte_t *pte;
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    8000288a:	0912                	slli	s2,s2,0x4
    8000288c:	992a                	add	s2,s2,a0
    8000288e:	4601                	li	a2,0
    80002890:	27093583          	ld	a1,624(s2)
    80002894:	6928                	ld	a0,80(a0)
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	722080e7          	jalr	1826(ra) # 80000fb8 <walk>
    8000289e:	8a2a                	mv	s4,a0
    800028a0:	c95d                	beqz	a0,80002956 <swapin+0x106>
  // page should be valid when we swap out, if not, panic
  // if (*pte & PTE_V || !(*pte & PTE_PG))
  //     panic("swapin: valid page");

  struct ram_page *ram_pg = &p->ram_pages[ram_index];
  if (ram_pg->used) {
    800028a2:	0992                	slli	s3,s3,0x4
    800028a4:	99d6                	add	s3,s3,s5
    800028a6:	17c9a783          	lw	a5,380(s3)
    800028aa:	efd5                	bnez	a5,80002966 <swapin+0x116>
    panic("swapin: ram page used");
  }

  uint64 npa;
  if ( (npa = (uint64)kalloc()) == 0 ) {
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	226080e7          	jalr	550(ra) # 80000ad2 <kalloc>
    800028b4:	84aa                	mv	s1,a0
    800028b6:	c161                	beqz	a0,80002976 <swapin+0x126>
    panic("swapin: failed alocate physical address");
  }
  char buffer[PGSIZE];
  if (readFromSwapFile(p, buffer, disk_pg->offset, PGSIZE) < 0) {
    800028b8:	6685                	lui	a3,0x1
    800028ba:	27892603          	lw	a2,632(s2)
    800028be:	75fd                	lui	a1,0xfffff
    800028c0:	fc040793          	addi	a5,s0,-64
    800028c4:	95be                	add	a1,a1,a5
    800028c6:	8556                	mv	a0,s5
    800028c8:	00002097          	auipc	ra,0x2
    800028cc:	0c2080e7          	jalr	194(ra) # 8000498a <readFromSwapFile>
    800028d0:	0a054b63          	bltz	a0,80002986 <swapin+0x136>
    panic("swapin: read from disk failed");
  }

  memmove((void *)npa, buffer, PGSIZE); 
    800028d4:	6605                	lui	a2,0x1
    800028d6:	75fd                	lui	a1,0xfffff
    800028d8:	fc040793          	addi	a5,s0,-64
    800028dc:	95be                	add	a1,a1,a5
    800028de:	8526                	mv	a0,s1
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	44c080e7          	jalr	1100(ra) # 80000d2c <memmove>

  ram_pg->used = 1;
    800028e8:	4785                	li	a5,1
    800028ea:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    800028ee:	27093783          	ld	a5,624(s2)
    800028f2:	16f9b823          	sd	a5,368(s3)
  // ADDED Q2
  #if SELECTION == LAPA
    ram_pg->age = 0xFFFFFFFF;
    800028f6:	57fd                	li	a5,-1
    800028f8:	16f9ac23          	sw	a5,376(s3)
  #endif
  #if SELECTION != LAPA 
    ram_pg->age = 0;
  #endif

  disk_pg->va = 0;
    800028fc:	26093823          	sd	zero,624(s2)
  disk_pg->used = 0;
    80002900:	26092e23          	sw	zero,636(s2)

  *pte = *pte | PTE_V;                           
  *pte = *pte & ~PTE_PG;                         
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    80002904:	80b1                	srli	s1,s1,0xc
    80002906:	04aa                	slli	s1,s1,0xa
    80002908:	000a3783          	ld	a5,0(s4)
    8000290c:	1ff7f793          	andi	a5,a5,511
    80002910:	8cdd                	or	s1,s1,a5
    80002912:	0014e493          	ori	s1,s1,1
    80002916:	009a3023          	sd	s1,0(s4)
    8000291a:	12000073          	sfence.vma
  sfence_vma(); // clear TLB
}
    8000291e:	6305                	lui	t1,0x1
    80002920:	1341                	addi	t1,t1,-16
    80002922:	911a                	add	sp,sp,t1
    80002924:	60a6                	ld	ra,72(sp)
    80002926:	6406                	ld	s0,64(sp)
    80002928:	74e2                	ld	s1,56(sp)
    8000292a:	7942                	ld	s2,48(sp)
    8000292c:	79a2                	ld	s3,40(sp)
    8000292e:	7a02                	ld	s4,32(sp)
    80002930:	6ae2                	ld	s5,24(sp)
    80002932:	6161                	addi	sp,sp,80
    80002934:	8082                	ret
    panic("swapin: disk index out of bounds");
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	a1250513          	addi	a0,a0,-1518 # 80008348 <digits+0x308>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	bec080e7          	jalr	-1044(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a2a50513          	addi	a0,a0,-1494 # 80008370 <digits+0x330>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	bdc080e7          	jalr	-1060(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    80002956:	00006517          	auipc	a0,0x6
    8000295a:	a3a50513          	addi	a0,a0,-1478 # 80008390 <digits+0x350>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	bcc080e7          	jalr	-1076(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	a4250513          	addi	a0,a0,-1470 # 800083a8 <digits+0x368>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	bbc080e7          	jalr	-1092(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    80002976:	00006517          	auipc	a0,0x6
    8000297a:	a4a50513          	addi	a0,a0,-1462 # 800083c0 <digits+0x380>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	bac080e7          	jalr	-1108(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	a6250513          	addi	a0,a0,-1438 # 800083e8 <digits+0x3a8>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	b9c080e7          	jalr	-1124(ra) # 8000052a <panic>

0000000080002996 <get_unused_ram_index>:

int get_unused_ram_index(struct proc* p)
{
    80002996:	1141                	addi	sp,sp,-16
    80002998:	e422                	sd	s0,8(sp)
    8000299a:	0800                	addi	s0,sp,16
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    8000299c:	17c50793          	addi	a5,a0,380
    800029a0:	4501                	li	a0,0
    800029a2:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    800029a4:	4398                	lw	a4,0(a5)
    800029a6:	c711                	beqz	a4,800029b2 <get_unused_ram_index+0x1c>
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    800029a8:	2505                	addiw	a0,a0,1
    800029aa:	07c1                	addi	a5,a5,16
    800029ac:	fed51ce3          	bne	a0,a3,800029a4 <get_unused_ram_index+0xe>
      return i;
    }
  }
  return -1;
    800029b0:	557d                	li	a0,-1
}
    800029b2:	6422                	ld	s0,8(sp)
    800029b4:	0141                	addi	sp,sp,16
    800029b6:	8082                	ret

00000000800029b8 <get_disk_page_index>:

int get_disk_page_index(struct proc *p, uint64 va)
{
    800029b8:	1141                	addi	sp,sp,-16
    800029ba:	e422                	sd	s0,8(sp)
    800029bc:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800029be:	27050793          	addi	a5,a0,624
    800029c2:	4501                	li	a0,0
    800029c4:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    800029c6:	6398                	ld	a4,0(a5)
    800029c8:	00b70763          	beq	a4,a1,800029d6 <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800029cc:	2505                	addiw	a0,a0,1
    800029ce:	07c1                	addi	a5,a5,16
    800029d0:	fed51be3          	bne	a0,a3,800029c6 <get_disk_page_index+0xe>
      return i;
    }
  }
  return -1;
    800029d4:	557d                	li	a0,-1
}
    800029d6:	6422                	ld	s0,8(sp)
    800029d8:	0141                	addi	sp,sp,16
    800029da:	8082                	ret

00000000800029dc <remove_page_from_ram>:
    #endif
}

// TODO assume remove page only located in ram?? or we should also iterate over the disk pages?
void remove_page_from_ram(uint64 va)
{
    800029dc:	1101                	addi	sp,sp,-32
    800029de:	ec06                	sd	ra,24(sp)
    800029e0:	e822                	sd	s0,16(sp)
    800029e2:	e426                	sd	s1,8(sp)
    800029e4:	1000                	addi	s0,sp,32
    800029e6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	ffe080e7          	jalr	-2(ra) # 800019e6 <myproc>
  if (p->pid == INIT_PID || p->pid == SHELL_PID) {
    800029f0:	591c                	lw	a5,48(a0)
    800029f2:	37fd                	addiw	a5,a5,-1
    800029f4:	4705                	li	a4,1
    800029f6:	02f77863          	bgeu	a4,a5,80002a26 <remove_page_from_ram+0x4a>
    800029fa:	17050793          	addi	a5,a0,368
    return;
  }
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800029fe:	4701                	li	a4,0
    80002a00:	4641                	li	a2,16
    80002a02:	a029                	j	80002a0c <remove_page_from_ram+0x30>
    80002a04:	2705                	addiw	a4,a4,1
    80002a06:	07c1                	addi	a5,a5,16
    80002a08:	02c70463          	beq	a4,a2,80002a30 <remove_page_from_ram+0x54>
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
    80002a0c:	6394                	ld	a3,0(a5)
    80002a0e:	fe969be3          	bne	a3,s1,80002a04 <remove_page_from_ram+0x28>
    80002a12:	47d4                	lw	a3,12(a5)
    80002a14:	dae5                	beqz	a3,80002a04 <remove_page_from_ram+0x28>
      p->ram_pages[i].va = 0;
    80002a16:	0712                	slli	a4,a4,0x4
    80002a18:	972a                	add	a4,a4,a0
    80002a1a:	16073823          	sd	zero,368(a4)
      p->ram_pages[i].used = 0;
    80002a1e:	16072e23          	sw	zero,380(a4)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002a22:	16072c23          	sw	zero,376(a4)
      return;
    }
  }
  panic("remove_page_from_ram failed");
}
    80002a26:	60e2                	ld	ra,24(sp)
    80002a28:	6442                	ld	s0,16(sp)
    80002a2a:	64a2                	ld	s1,8(sp)
    80002a2c:	6105                	addi	sp,sp,32
    80002a2e:	8082                	ret
  panic("remove_page_from_ram failed");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	9d850513          	addi	a0,a0,-1576 # 80008408 <digits+0x3c8>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	af2080e7          	jalr	-1294(ra) # 8000052a <panic>

0000000080002a40 <nfua>:

int nfua()
{
    80002a40:	1141                	addi	sp,sp,-16
    80002a42:	e406                	sd	ra,8(sp)
    80002a44:	e022                	sd	s0,0(sp)
    80002a46:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	f9e080e7          	jalr	-98(ra) # 800019e6 <myproc>
  int i = 0;
  int min_index = 0;
  uint min_age = 0xFFFFFFFF;
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002a50:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002a54:	567d                	li	a2,-1
  int min_index = 0;
    80002a56:	4501                	li	a0,0
  int i = 0;
    80002a58:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002a5a:	45c1                	li	a1,16
    80002a5c:	a029                	j	80002a66 <nfua+0x26>
    80002a5e:	0741                	addi	a4,a4,16
    80002a60:	2785                	addiw	a5,a5,1
    80002a62:	00b78863          	beq	a5,a1,80002a72 <nfua+0x32>
    if(ram_pg->age < min_age){
    80002a66:	4714                	lw	a3,8(a4)
    80002a68:	fec6fbe3          	bgeu	a3,a2,80002a5e <nfua+0x1e>
      min_index = i;
      min_age = ram_pg->age;
    80002a6c:	8636                	mv	a2,a3
    if(ram_pg->age < min_age){
    80002a6e:	853e                	mv	a0,a5
    80002a70:	b7fd                	j	80002a5e <nfua+0x1e>
    }
  }
  return min_index;
}
    80002a72:	60a2                	ld	ra,8(sp)
    80002a74:	6402                	ld	s0,0(sp)
    80002a76:	0141                	addi	sp,sp,16
    80002a78:	8082                	ret

0000000080002a7a <insert_page_to_ram>:
{
    80002a7a:	7179                	addi	sp,sp,-48
    80002a7c:	f406                	sd	ra,40(sp)
    80002a7e:	f022                	sd	s0,32(sp)
    80002a80:	ec26                	sd	s1,24(sp)
    80002a82:	e84a                	sd	s2,16(sp)
    80002a84:	e44e                	sd	s3,8(sp)
    80002a86:	1800                	addi	s0,sp,48
    80002a88:	89aa                	mv	s3,a0
    struct proc *p = myproc();
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	f5c080e7          	jalr	-164(ra) # 800019e6 <myproc>
    if (p->pid == INIT_PID || p->pid == SHELL_PID) {
    80002a92:	591c                	lw	a5,48(a0)
    80002a94:	37fd                	addiw	a5,a5,-1
    80002a96:	4705                	li	a4,1
    80002a98:	02f77463          	bgeu	a4,a5,80002ac0 <insert_page_to_ram+0x46>
    80002a9c:	84aa                	mv	s1,a0
    if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0)
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	ef8080e7          	jalr	-264(ra) # 80002996 <get_unused_ram_index>
    80002aa6:	892a                	mv	s2,a0
    80002aa8:	02054363          	bltz	a0,80002ace <insert_page_to_ram+0x54>
    ram_pg->va = va;
    80002aac:	0912                	slli	s2,s2,0x4
    80002aae:	94ca                	add	s1,s1,s2
    80002ab0:	1734b823          	sd	s3,368(s1)
    ram_pg->used = 1;
    80002ab4:	4785                	li	a5,1
    80002ab6:	16f4ae23          	sw	a5,380(s1)
      ram_pg->age = 0xFFFFFFFF;
    80002aba:	57fd                	li	a5,-1
    80002abc:	16f4ac23          	sw	a5,376(s1)
}
    80002ac0:	70a2                	ld	ra,40(sp)
    80002ac2:	7402                	ld	s0,32(sp)
    80002ac4:	64e2                	ld	s1,24(sp)
    80002ac6:	6942                	ld	s2,16(sp)
    80002ac8:	69a2                	ld	s3,8(sp)
    80002aca:	6145                	addi	sp,sp,48
    80002acc:	8082                	ret
}

int index_page_to_swap()
{
  #if SELECTION == NFUA
    return nfua();
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	f72080e7          	jalr	-142(ra) # 80002a40 <nfua>
    80002ad6:	892a                	mv	s2,a0
        swapout(ram_pg_index_to_swap);
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	c50080e7          	jalr	-944(ra) # 80002728 <swapout>
        unused_ram_pg_index = ram_pg_index_to_swap;
    80002ae0:	b7f1                	j	80002aac <insert_page_to_ram+0x32>

0000000080002ae2 <handle_page_fault>:
{
    80002ae2:	7179                	addi	sp,sp,-48
    80002ae4:	f406                	sd	ra,40(sp)
    80002ae6:	f022                	sd	s0,32(sp)
    80002ae8:	ec26                	sd	s1,24(sp)
    80002aea:	e84a                	sd	s2,16(sp)
    80002aec:	e44e                	sd	s3,8(sp)
    80002aee:	1800                	addi	s0,sp,48
    80002af0:	89aa                	mv	s3,a0
    struct proc *p = myproc();
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	ef4080e7          	jalr	-268(ra) # 800019e6 <myproc>
    80002afa:	84aa                	mv	s1,a0
    if (!(pte = walk(p->pagetable, va, 0))) {
    80002afc:	4601                	li	a2,0
    80002afe:	85ce                	mv	a1,s3
    80002b00:	6928                	ld	a0,80(a0)
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	4b6080e7          	jalr	1206(ra) # 80000fb8 <walk>
    80002b0a:	c531                	beqz	a0,80002b56 <handle_page_fault+0x74>
    if(*pte & PTE_V){
    80002b0c:	611c                	ld	a5,0(a0)
    80002b0e:	0017f713          	andi	a4,a5,1
    80002b12:	eb31                	bnez	a4,80002b66 <handle_page_fault+0x84>
    if(!(*pte & PTE_PG)) {
    80002b14:	2007f793          	andi	a5,a5,512
    80002b18:	cfb9                	beqz	a5,80002b76 <handle_page_fault+0x94>
    if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	e7a080e7          	jalr	-390(ra) # 80002996 <get_unused_ram_index>
    80002b24:	892a                	mv	s2,a0
    80002b26:	06054063          	bltz	a0,80002b86 <handle_page_fault+0xa4>
    if( (target_idx = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002b2a:	75fd                	lui	a1,0xfffff
    80002b2c:	00b9f5b3          	and	a1,s3,a1
    80002b30:	8526                	mv	a0,s1
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	e86080e7          	jalr	-378(ra) # 800029b8 <get_disk_page_index>
    80002b3a:	06054063          	bltz	a0,80002b9a <handle_page_fault+0xb8>
    swapin(target_idx, unused_ram_pg_index);
    80002b3e:	85ca                	mv	a1,s2
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	d10080e7          	jalr	-752(ra) # 80002850 <swapin>
}
    80002b48:	70a2                	ld	ra,40(sp)
    80002b4a:	7402                	ld	s0,32(sp)
    80002b4c:	64e2                	ld	s1,24(sp)
    80002b4e:	6942                	ld	s2,16(sp)
    80002b50:	69a2                	ld	s3,8(sp)
    80002b52:	6145                	addi	sp,sp,48
    80002b54:	8082                	ret
      panic("handle_page_fault: walk failed");
    80002b56:	00006517          	auipc	a0,0x6
    80002b5a:	8d250513          	addi	a0,a0,-1838 # 80008428 <digits+0x3e8>
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	9cc080e7          	jalr	-1588(ra) # 8000052a <panic>
      panic("handle_page_fault: invalid pte");
    80002b66:	00006517          	auipc	a0,0x6
    80002b6a:	8e250513          	addi	a0,a0,-1822 # 80008448 <digits+0x408>
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	9bc080e7          	jalr	-1604(ra) # 8000052a <panic>
      panic("handle_page_fault: PTE_PG off");
    80002b76:	00006517          	auipc	a0,0x6
    80002b7a:	8f250513          	addi	a0,a0,-1806 # 80008468 <digits+0x428>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	9ac080e7          	jalr	-1620(ra) # 8000052a <panic>
    return nfua();
    80002b86:	00000097          	auipc	ra,0x0
    80002b8a:	eba080e7          	jalr	-326(ra) # 80002a40 <nfua>
    80002b8e:	892a                	mv	s2,a0
        swapout(ram_pg_index_to_swap); 
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	b98080e7          	jalr	-1128(ra) # 80002728 <swapout>
        unused_ram_pg_index = ram_pg_index_to_swap;
    80002b98:	bf49                	j	80002b2a <handle_page_fault+0x48>
      panic("handle_page_fault: get_disk_page_index failed");
    80002b9a:	00006517          	auipc	a0,0x6
    80002b9e:	8ee50513          	addi	a0,a0,-1810 # 80008488 <digits+0x448>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	988080e7          	jalr	-1656(ra) # 8000052a <panic>

0000000080002baa <count_ones>:
{
    80002baa:	1141                	addi	sp,sp,-16
    80002bac:	e422                	sd	s0,8(sp)
    80002bae:	0800                	addi	s0,sp,16
  while(num > 0){
    80002bb0:	c105                	beqz	a0,80002bd0 <count_ones+0x26>
    80002bb2:	87aa                	mv	a5,a0
  int count = 0;
    80002bb4:	4501                	li	a0,0
  while(num > 0){
    80002bb6:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002bb8:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002bbc:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002bbe:	0007871b          	sext.w	a4,a5
    80002bc2:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002bc6:	fee6e9e3          	bltu	a3,a4,80002bb8 <count_ones+0xe>
}
    80002bca:	6422                	ld	s0,8(sp)
    80002bcc:	0141                	addi	sp,sp,16
    80002bce:	8082                	ret
  int count = 0;
    80002bd0:	4501                	li	a0,0
    80002bd2:	bfe5                	j	80002bca <count_ones+0x20>

0000000080002bd4 <lapa>:
{
    80002bd4:	715d                	addi	sp,sp,-80
    80002bd6:	e486                	sd	ra,72(sp)
    80002bd8:	e0a2                	sd	s0,64(sp)
    80002bda:	fc26                	sd	s1,56(sp)
    80002bdc:	f84a                	sd	s2,48(sp)
    80002bde:	f44e                	sd	s3,40(sp)
    80002be0:	f052                	sd	s4,32(sp)
    80002be2:	ec56                	sd	s5,24(sp)
    80002be4:	e85a                	sd	s6,16(sp)
    80002be6:	e45e                	sd	s7,8(sp)
    80002be8:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	dfc080e7          	jalr	-516(ra) # 800019e6 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bf2:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002bf6:	5afd                	li	s5,-1
  int min_index = 0;
    80002bf8:	4b81                	li	s7,0
  int i = 0;
    80002bfa:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bfc:	4b41                	li	s6,16
    80002bfe:	a039                	j	80002c0c <lapa+0x38>
      min_age = ram_pg->age;
    80002c00:	8ad2                	mv	s5,s4
    80002c02:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c04:	09c1                	addi	s3,s3,16
    80002c06:	2905                	addiw	s2,s2,1
    80002c08:	03690863          	beq	s2,s6,80002c38 <lapa+0x64>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002c0c:	0089aa03          	lw	s4,8(s3)
    80002c10:	8552                	mv	a0,s4
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	f98080e7          	jalr	-104(ra) # 80002baa <count_ones>
    80002c1a:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002c1c:	8556                	mv	a0,s5
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	f8c080e7          	jalr	-116(ra) # 80002baa <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002c26:	fca4cde3          	blt	s1,a0,80002c00 <lapa+0x2c>
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c2a:	fca49de3          	bne	s1,a0,80002c04 <lapa+0x30>
    80002c2e:	fd5a7be3          	bgeu	s4,s5,80002c04 <lapa+0x30>
      min_age = ram_pg->age;
    80002c32:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c34:	8bca                	mv	s7,s2
    80002c36:	b7f9                	j	80002c04 <lapa+0x30>
}
    80002c38:	855e                	mv	a0,s7
    80002c3a:	60a6                	ld	ra,72(sp)
    80002c3c:	6406                	ld	s0,64(sp)
    80002c3e:	74e2                	ld	s1,56(sp)
    80002c40:	7942                	ld	s2,48(sp)
    80002c42:	79a2                	ld	s3,40(sp)
    80002c44:	7a02                	ld	s4,32(sp)
    80002c46:	6ae2                	ld	s5,24(sp)
    80002c48:	6b42                	ld	s6,16(sp)
    80002c4a:	6ba2                	ld	s7,8(sp)
    80002c4c:	6161                	addi	sp,sp,80
    80002c4e:	8082                	ret

0000000080002c50 <scfifo>:
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	e426                	sd	s1,8(sp)
    80002c58:	e04a                	sd	s2,0(sp)
    80002c5a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	d8a080e7          	jalr	-630(ra) # 800019e6 <myproc>
    80002c64:	892a                	mv	s2,a0
  int index = p->scfifo_index;
    80002c66:	37052483          	lw	s1,880(a0)
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
    80002c6a:	01748793          	addi	a5,s1,23
    80002c6e:	0792                	slli	a5,a5,0x4
    80002c70:	97ca                	add	a5,a5,s2
    80002c72:	4601                	li	a2,0
    80002c74:	638c                	ld	a1,0(a5)
    80002c76:	05093503          	ld	a0,80(s2)
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	33e080e7          	jalr	830(ra) # 80000fb8 <walk>
    80002c82:	c10d                	beqz	a0,80002ca4 <scfifo+0x54>
    if(*pte & PTE_A){
    80002c84:	611c                	ld	a5,0(a0)
    80002c86:	0407f713          	andi	a4,a5,64
    80002c8a:	c70d                	beqz	a4,80002cb4 <scfifo+0x64>
      *pte = *pte & ~PTE_A;
    80002c8c:	fbf7f793          	andi	a5,a5,-65
    80002c90:	e11c                	sd	a5,0(a0)
      index = (index + 1) % MAX_PSYC_PAGES;
    80002c92:	2485                	addiw	s1,s1,1
    80002c94:	41f4d79b          	sraiw	a5,s1,0x1f
    80002c98:	01c7d79b          	srliw	a5,a5,0x1c
    80002c9c:	9cbd                	addw	s1,s1,a5
    80002c9e:	88bd                	andi	s1,s1,15
    80002ca0:	9c9d                	subw	s1,s1,a5
  while(1){
    80002ca2:	b7e1                	j	80002c6a <scfifo+0x1a>
      panic("scfifo: walk failed");
    80002ca4:	00006517          	auipc	a0,0x6
    80002ca8:	81450513          	addi	a0,a0,-2028 # 800084b8 <digits+0x478>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	87e080e7          	jalr	-1922(ra) # 8000052a <panic>
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
    80002cb4:	0014879b          	addiw	a5,s1,1
    80002cb8:	41f7d71b          	sraiw	a4,a5,0x1f
    80002cbc:	01c7571b          	srliw	a4,a4,0x1c
    80002cc0:	9fb9                	addw	a5,a5,a4
    80002cc2:	8bbd                	andi	a5,a5,15
    80002cc4:	9f99                	subw	a5,a5,a4
    80002cc6:	36f92823          	sw	a5,880(s2)
}
    80002cca:	8526                	mv	a0,s1
    80002ccc:	60e2                	ld	ra,24(sp)
    80002cce:	6442                	ld	s0,16(sp)
    80002cd0:	64a2                	ld	s1,8(sp)
    80002cd2:	6902                	ld	s2,0(sp)
    80002cd4:	6105                	addi	sp,sp,32
    80002cd6:	8082                	ret

0000000080002cd8 <index_page_to_swap>:
{
    80002cd8:	1141                	addi	sp,sp,-16
    80002cda:	e406                	sd	ra,8(sp)
    80002cdc:	e022                	sd	s0,0(sp)
    80002cde:	0800                	addi	s0,sp,16
    return nfua();
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	d60080e7          	jalr	-672(ra) # 80002a40 <nfua>
  #if SELECTION == NONE
    return -1;
  #endif

  return -1;
}
    80002ce8:	60a2                	ld	ra,8(sp)
    80002cea:	6402                	ld	s0,0(sp)
    80002cec:	0141                	addi	sp,sp,16
    80002cee:	8082                	ret

0000000080002cf0 <maintain_age>:

void maintain_age(struct proc *p){
    80002cf0:	7179                	addi	sp,sp,-48
    80002cf2:	f406                	sd	ra,40(sp)
    80002cf4:	f022                	sd	s0,32(sp)
    80002cf6:	ec26                	sd	s1,24(sp)
    80002cf8:	e84a                	sd	s2,16(sp)
    80002cfa:	e44e                	sd	s3,8(sp)
    80002cfc:	e052                	sd	s4,0(sp)
    80002cfe:	1800                	addi	s0,sp,48
    80002d00:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002d02:	17050493          	addi	s1,a0,368
    80002d06:	27050993          	addi	s3,a0,624
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
      panic("maintain_age: walk failed");
    }
    ram_pg->age = (ram_pg->age >> 1);
    if (*pte & PTE_A){
      ram_pg->age = ram_pg->age | (1 << 31);
    80002d0a:	80000a37          	lui	s4,0x80000
    80002d0e:	a821                	j	80002d26 <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002d10:	00005517          	auipc	a0,0x5
    80002d14:	7c050513          	addi	a0,a0,1984 # 800084d0 <digits+0x490>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	812080e7          	jalr	-2030(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002d20:	04c1                	addi	s1,s1,16
    80002d22:	02998b63          	beq	s3,s1,80002d58 <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002d26:	4601                	li	a2,0
    80002d28:	608c                	ld	a1,0(s1)
    80002d2a:	05093503          	ld	a0,80(s2)
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	28a080e7          	jalr	650(ra) # 80000fb8 <walk>
    80002d36:	dd69                	beqz	a0,80002d10 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002d38:	449c                	lw	a5,8(s1)
    80002d3a:	0017d79b          	srliw	a5,a5,0x1
    80002d3e:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002d40:	6118                	ld	a4,0(a0)
    80002d42:	04077713          	andi	a4,a4,64
    80002d46:	df69                	beqz	a4,80002d20 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002d48:	0147e7b3          	or	a5,a5,s4
    80002d4c:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002d4e:	611c                	ld	a5,0(a0)
    80002d50:	fbf7f793          	andi	a5,a5,-65
    80002d54:	e11c                	sd	a5,0(a0)
    80002d56:	b7e9                	j	80002d20 <maintain_age+0x30>
    }
  }
}
    80002d58:	70a2                	ld	ra,40(sp)
    80002d5a:	7402                	ld	s0,32(sp)
    80002d5c:	64e2                	ld	s1,24(sp)
    80002d5e:	6942                	ld	s2,16(sp)
    80002d60:	69a2                	ld	s3,8(sp)
    80002d62:	6a02                	ld	s4,0(sp)
    80002d64:	6145                	addi	sp,sp,48
    80002d66:	8082                	ret

0000000080002d68 <scheduler>:
{
    80002d68:	7139                	addi	sp,sp,-64
    80002d6a:	fc06                	sd	ra,56(sp)
    80002d6c:	f822                	sd	s0,48(sp)
    80002d6e:	f426                	sd	s1,40(sp)
    80002d70:	f04a                	sd	s2,32(sp)
    80002d72:	ec4e                	sd	s3,24(sp)
    80002d74:	e852                	sd	s4,16(sp)
    80002d76:	e456                	sd	s5,8(sp)
    80002d78:	e05a                	sd	s6,0(sp)
    80002d7a:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d7c:	8792                	mv	a5,tp
  int id = r_tp();
    80002d7e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002d80:	00779a93          	slli	s5,a5,0x7
    80002d84:	0000e717          	auipc	a4,0xe
    80002d88:	51c70713          	addi	a4,a4,1308 # 800112a0 <pid_lock>
    80002d8c:	9756                	add	a4,a4,s5
    80002d8e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002d92:	0000e717          	auipc	a4,0xe
    80002d96:	54670713          	addi	a4,a4,1350 # 800112d8 <cpus+0x8>
    80002d9a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002d9c:	498d                	li	s3,3
        p->state = RUNNING;
    80002d9e:	4b11                	li	s6,4
        c->proc = p;
    80002da0:	079e                	slli	a5,a5,0x7
    80002da2:	0000ea17          	auipc	s4,0xe
    80002da6:	4fea0a13          	addi	s4,s4,1278 # 800112a0 <pid_lock>
    80002daa:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002dac:	0001c917          	auipc	s2,0x1c
    80002db0:	72490913          	addi	s2,s2,1828 # 8001f4d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002db8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dbc:	10079073          	csrw	sstatus,a5
    80002dc0:	0000f497          	auipc	s1,0xf
    80002dc4:	91048493          	addi	s1,s1,-1776 # 800116d0 <proc>
    80002dc8:	a811                	j	80002ddc <scheduler+0x74>
      release(&p->lock);
    80002dca:	8526                	mv	a0,s1
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	ebc080e7          	jalr	-324(ra) # 80000c88 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002dd4:	37848493          	addi	s1,s1,888
    80002dd8:	fd248ee3          	beq	s1,s2,80002db4 <scheduler+0x4c>
      acquire(&p->lock);
    80002ddc:	8526                	mv	a0,s1
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	de4080e7          	jalr	-540(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80002de6:	4c9c                	lw	a5,24(s1)
    80002de8:	ff3791e3          	bne	a5,s3,80002dca <scheduler+0x62>
        p->state = RUNNING;
    80002dec:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002df0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002df4:	06048593          	addi	a1,s1,96
    80002df8:	8556                	mv	a0,s5
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	018080e7          	jalr	24(ra) # 80002e12 <swtch>
          maintain_age(p);
    80002e02:	8526                	mv	a0,s1
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	eec080e7          	jalr	-276(ra) # 80002cf0 <maintain_age>
        c->proc = 0;
    80002e0c:	020a3823          	sd	zero,48(s4)
    80002e10:	bf6d                	j	80002dca <scheduler+0x62>

0000000080002e12 <swtch>:
    80002e12:	00153023          	sd	ra,0(a0)
    80002e16:	00253423          	sd	sp,8(a0)
    80002e1a:	e900                	sd	s0,16(a0)
    80002e1c:	ed04                	sd	s1,24(a0)
    80002e1e:	03253023          	sd	s2,32(a0)
    80002e22:	03353423          	sd	s3,40(a0)
    80002e26:	03453823          	sd	s4,48(a0)
    80002e2a:	03553c23          	sd	s5,56(a0)
    80002e2e:	05653023          	sd	s6,64(a0)
    80002e32:	05753423          	sd	s7,72(a0)
    80002e36:	05853823          	sd	s8,80(a0)
    80002e3a:	05953c23          	sd	s9,88(a0)
    80002e3e:	07a53023          	sd	s10,96(a0)
    80002e42:	07b53423          	sd	s11,104(a0)
    80002e46:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd1000>
    80002e4a:	0085b103          	ld	sp,8(a1)
    80002e4e:	6980                	ld	s0,16(a1)
    80002e50:	6d84                	ld	s1,24(a1)
    80002e52:	0205b903          	ld	s2,32(a1)
    80002e56:	0285b983          	ld	s3,40(a1)
    80002e5a:	0305ba03          	ld	s4,48(a1)
    80002e5e:	0385ba83          	ld	s5,56(a1)
    80002e62:	0405bb03          	ld	s6,64(a1)
    80002e66:	0485bb83          	ld	s7,72(a1)
    80002e6a:	0505bc03          	ld	s8,80(a1)
    80002e6e:	0585bc83          	ld	s9,88(a1)
    80002e72:	0605bd03          	ld	s10,96(a1)
    80002e76:	0685bd83          	ld	s11,104(a1)
    80002e7a:	8082                	ret

0000000080002e7c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002e7c:	1141                	addi	sp,sp,-16
    80002e7e:	e406                	sd	ra,8(sp)
    80002e80:	e022                	sd	s0,0(sp)
    80002e82:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e84:	00005597          	auipc	a1,0x5
    80002e88:	6c458593          	addi	a1,a1,1732 # 80008548 <states.0+0x30>
    80002e8c:	0001c517          	auipc	a0,0x1c
    80002e90:	64450513          	addi	a0,a0,1604 # 8001f4d0 <tickslock>
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	c9e080e7          	jalr	-866(ra) # 80000b32 <initlock>
}
    80002e9c:	60a2                	ld	ra,8(sp)
    80002e9e:	6402                	ld	s0,0(sp)
    80002ea0:	0141                	addi	sp,sp,16
    80002ea2:	8082                	ret

0000000080002ea4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ea4:	1141                	addi	sp,sp,-16
    80002ea6:	e422                	sd	s0,8(sp)
    80002ea8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002eaa:	00004797          	auipc	a5,0x4
    80002eae:	aa678793          	addi	a5,a5,-1370 # 80006950 <kernelvec>
    80002eb2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002eb6:	6422                	ld	s0,8(sp)
    80002eb8:	0141                	addi	sp,sp,16
    80002eba:	8082                	ret

0000000080002ebc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ebc:	1141                	addi	sp,sp,-16
    80002ebe:	e406                	sd	ra,8(sp)
    80002ec0:	e022                	sd	s0,0(sp)
    80002ec2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	b22080e7          	jalr	-1246(ra) # 800019e6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ecc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ed0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ed2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ed6:	00004617          	auipc	a2,0x4
    80002eda:	12a60613          	addi	a2,a2,298 # 80007000 <_trampoline>
    80002ede:	00004697          	auipc	a3,0x4
    80002ee2:	12268693          	addi	a3,a3,290 # 80007000 <_trampoline>
    80002ee6:	8e91                	sub	a3,a3,a2
    80002ee8:	040007b7          	lui	a5,0x4000
    80002eec:	17fd                	addi	a5,a5,-1
    80002eee:	07b2                	slli	a5,a5,0xc
    80002ef0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ef2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ef6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ef8:	180026f3          	csrr	a3,satp
    80002efc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002efe:	6d38                	ld	a4,88(a0)
    80002f00:	6134                	ld	a3,64(a0)
    80002f02:	6585                	lui	a1,0x1
    80002f04:	96ae                	add	a3,a3,a1
    80002f06:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002f08:	6d38                	ld	a4,88(a0)
    80002f0a:	00000697          	auipc	a3,0x0
    80002f0e:	13868693          	addi	a3,a3,312 # 80003042 <usertrap>
    80002f12:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002f14:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f16:	8692                	mv	a3,tp
    80002f18:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002f1e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002f22:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f26:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002f2a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f2c:	6f18                	ld	a4,24(a4)
    80002f2e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f32:	692c                	ld	a1,80(a0)
    80002f34:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002f36:	00004717          	auipc	a4,0x4
    80002f3a:	15a70713          	addi	a4,a4,346 # 80007090 <userret>
    80002f3e:	8f11                	sub	a4,a4,a2
    80002f40:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f42:	577d                	li	a4,-1
    80002f44:	177e                	slli	a4,a4,0x3f
    80002f46:	8dd9                	or	a1,a1,a4
    80002f48:	02000537          	lui	a0,0x2000
    80002f4c:	157d                	addi	a0,a0,-1
    80002f4e:	0536                	slli	a0,a0,0xd
    80002f50:	9782                	jalr	a5
}
    80002f52:	60a2                	ld	ra,8(sp)
    80002f54:	6402                	ld	s0,0(sp)
    80002f56:	0141                	addi	sp,sp,16
    80002f58:	8082                	ret

0000000080002f5a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002f5a:	1101                	addi	sp,sp,-32
    80002f5c:	ec06                	sd	ra,24(sp)
    80002f5e:	e822                	sd	s0,16(sp)
    80002f60:	e426                	sd	s1,8(sp)
    80002f62:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002f64:	0001c497          	auipc	s1,0x1c
    80002f68:	56c48493          	addi	s1,s1,1388 # 8001f4d0 <tickslock>
    80002f6c:	8526                	mv	a0,s1
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	c54080e7          	jalr	-940(ra) # 80000bc2 <acquire>
  ticks++;
    80002f76:	00006517          	auipc	a0,0x6
    80002f7a:	0ba50513          	addi	a0,a0,186 # 80009030 <ticks>
    80002f7e:	411c                	lw	a5,0(a0)
    80002f80:	2785                	addiw	a5,a5,1
    80002f82:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	014080e7          	jalr	20(ra) # 80001f98 <wakeup>
  release(&tickslock);
    80002f8c:	8526                	mv	a0,s1
    80002f8e:	ffffe097          	auipc	ra,0xffffe
    80002f92:	cfa080e7          	jalr	-774(ra) # 80000c88 <release>
}
    80002f96:	60e2                	ld	ra,24(sp)
    80002f98:	6442                	ld	s0,16(sp)
    80002f9a:	64a2                	ld	s1,8(sp)
    80002f9c:	6105                	addi	sp,sp,32
    80002f9e:	8082                	ret

0000000080002fa0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002fa0:	1101                	addi	sp,sp,-32
    80002fa2:	ec06                	sd	ra,24(sp)
    80002fa4:	e822                	sd	s0,16(sp)
    80002fa6:	e426                	sd	s1,8(sp)
    80002fa8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002faa:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002fae:	00074d63          	bltz	a4,80002fc8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002fb2:	57fd                	li	a5,-1
    80002fb4:	17fe                	slli	a5,a5,0x3f
    80002fb6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002fb8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002fba:	06f70363          	beq	a4,a5,80003020 <devintr+0x80>
  }
}
    80002fbe:	60e2                	ld	ra,24(sp)
    80002fc0:	6442                	ld	s0,16(sp)
    80002fc2:	64a2                	ld	s1,8(sp)
    80002fc4:	6105                	addi	sp,sp,32
    80002fc6:	8082                	ret
     (scause & 0xff) == 9){
    80002fc8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002fcc:	46a5                	li	a3,9
    80002fce:	fed792e3          	bne	a5,a3,80002fb2 <devintr+0x12>
    int irq = plic_claim();
    80002fd2:	00004097          	auipc	ra,0x4
    80002fd6:	a86080e7          	jalr	-1402(ra) # 80006a58 <plic_claim>
    80002fda:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002fdc:	47a9                	li	a5,10
    80002fde:	02f50763          	beq	a0,a5,8000300c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002fe2:	4785                	li	a5,1
    80002fe4:	02f50963          	beq	a0,a5,80003016 <devintr+0x76>
    return 1;
    80002fe8:	4505                	li	a0,1
    } else if(irq){
    80002fea:	d8f1                	beqz	s1,80002fbe <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002fec:	85a6                	mv	a1,s1
    80002fee:	00005517          	auipc	a0,0x5
    80002ff2:	56250513          	addi	a0,a0,1378 # 80008550 <states.0+0x38>
    80002ff6:	ffffd097          	auipc	ra,0xffffd
    80002ffa:	57e080e7          	jalr	1406(ra) # 80000574 <printf>
      plic_complete(irq);
    80002ffe:	8526                	mv	a0,s1
    80003000:	00004097          	auipc	ra,0x4
    80003004:	a7c080e7          	jalr	-1412(ra) # 80006a7c <plic_complete>
    return 1;
    80003008:	4505                	li	a0,1
    8000300a:	bf55                	j	80002fbe <devintr+0x1e>
      uartintr();
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	97a080e7          	jalr	-1670(ra) # 80000986 <uartintr>
    80003014:	b7ed                	j	80002ffe <devintr+0x5e>
      virtio_disk_intr();
    80003016:	00004097          	auipc	ra,0x4
    8000301a:	ef8080e7          	jalr	-264(ra) # 80006f0e <virtio_disk_intr>
    8000301e:	b7c5                	j	80002ffe <devintr+0x5e>
    if(cpuid() == 0){
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	99a080e7          	jalr	-1638(ra) # 800019ba <cpuid>
    80003028:	c901                	beqz	a0,80003038 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000302a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000302e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003030:	14479073          	csrw	sip,a5
    return 2;
    80003034:	4509                	li	a0,2
    80003036:	b761                	j	80002fbe <devintr+0x1e>
      clockintr();
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	f22080e7          	jalr	-222(ra) # 80002f5a <clockintr>
    80003040:	b7ed                	j	8000302a <devintr+0x8a>

0000000080003042 <usertrap>:
{
    80003042:	1101                	addi	sp,sp,-32
    80003044:	ec06                	sd	ra,24(sp)
    80003046:	e822                	sd	s0,16(sp)
    80003048:	e426                	sd	s1,8(sp)
    8000304a:	e04a                	sd	s2,0(sp)
    8000304c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000304e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003052:	1007f793          	andi	a5,a5,256
    80003056:	e3ad                	bnez	a5,800030b8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003058:	00004797          	auipc	a5,0x4
    8000305c:	8f878793          	addi	a5,a5,-1800 # 80006950 <kernelvec>
    80003060:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	982080e7          	jalr	-1662(ra) # 800019e6 <myproc>
    8000306c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000306e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003070:	14102773          	csrr	a4,sepc
    80003074:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003076:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000307a:	47a1                	li	a5,8
    8000307c:	04f71c63          	bne	a4,a5,800030d4 <usertrap+0x92>
    if(p->killed)
    80003080:	551c                	lw	a5,40(a0)
    80003082:	e3b9                	bnez	a5,800030c8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003084:	6cb8                	ld	a4,88(s1)
    80003086:	6f1c                	ld	a5,24(a4)
    80003088:	0791                	addi	a5,a5,4
    8000308a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000308c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003090:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003094:	10079073          	csrw	sstatus,a5
    syscall();
    80003098:	00000097          	auipc	ra,0x0
    8000309c:	316080e7          	jalr	790(ra) # 800033ae <syscall>
  if(p->killed)
    800030a0:	549c                	lw	a5,40(s1)
    800030a2:	e7dd                	bnez	a5,80003150 <usertrap+0x10e>
  usertrapret();
    800030a4:	00000097          	auipc	ra,0x0
    800030a8:	e18080e7          	jalr	-488(ra) # 80002ebc <usertrapret>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6902                	ld	s2,0(sp)
    800030b4:	6105                	addi	sp,sp,32
    800030b6:	8082                	ret
    panic("usertrap: not from user mode");
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	4b850513          	addi	a0,a0,1208 # 80008570 <states.0+0x58>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	46a080e7          	jalr	1130(ra) # 8000052a <panic>
      exit(-1);
    800030c8:	557d                	li	a0,-1
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	402080e7          	jalr	1026(ra) # 800024cc <exit>
    800030d2:	bf4d                	j	80003084 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800030d4:	00000097          	auipc	ra,0x0
    800030d8:	ecc080e7          	jalr	-308(ra) # 80002fa0 <devintr>
    800030dc:	892a                	mv	s2,a0
    800030de:	e535                	bnez	a0,8000314a <usertrap+0x108>
  } else if ((p->pid != INIT_PID && p->pid != SHELL_PID) && 
    800030e0:	5890                	lw	a2,48(s1)
    800030e2:	fff6071b          	addiw	a4,a2,-1
    800030e6:	4785                	li	a5,1
    800030e8:	02e7f163          	bgeu	a5,a4,8000310a <usertrap+0xc8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030ec:	14202773          	csrr	a4,scause
    800030f0:	47b1                	li	a5,12
    800030f2:	04f70563          	beq	a4,a5,8000313c <usertrap+0xfa>
    800030f6:	14202773          	csrr	a4,scause
             (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    800030fa:	47b5                	li	a5,13
    800030fc:	04f70063          	beq	a4,a5,8000313c <usertrap+0xfa>
    80003100:	14202773          	csrr	a4,scause
    80003104:	47bd                	li	a5,15
    80003106:	02f70b63          	beq	a4,a5,8000313c <usertrap+0xfa>
    8000310a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000310e:	00005517          	auipc	a0,0x5
    80003112:	48250513          	addi	a0,a0,1154 # 80008590 <states.0+0x78>
    80003116:	ffffd097          	auipc	ra,0xffffd
    8000311a:	45e080e7          	jalr	1118(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000311e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003122:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003126:	00005517          	auipc	a0,0x5
    8000312a:	49a50513          	addi	a0,a0,1178 # 800085c0 <states.0+0xa8>
    8000312e:	ffffd097          	auipc	ra,0xffffd
    80003132:	446080e7          	jalr	1094(ra) # 80000574 <printf>
    p->killed = 1;
    80003136:	4785                	li	a5,1
    80003138:	d49c                	sw	a5,40(s1)
  if(p->killed)
    8000313a:	a821                	j	80003152 <usertrap+0x110>
    8000313c:	14302573          	csrr	a0,stval
    handle_page_fault(va);    
    80003140:	00000097          	auipc	ra,0x0
    80003144:	9a2080e7          	jalr	-1630(ra) # 80002ae2 <handle_page_fault>
             (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    80003148:	bfa1                	j	800030a0 <usertrap+0x5e>
  if(p->killed)
    8000314a:	549c                	lw	a5,40(s1)
    8000314c:	cb81                	beqz	a5,8000315c <usertrap+0x11a>
    8000314e:	a011                	j	80003152 <usertrap+0x110>
    80003150:	4901                	li	s2,0
    exit(-1);
    80003152:	557d                	li	a0,-1
    80003154:	fffff097          	auipc	ra,0xfffff
    80003158:	378080e7          	jalr	888(ra) # 800024cc <exit>
  if(which_dev == 2)
    8000315c:	4789                	li	a5,2
    8000315e:	f4f913e3          	bne	s2,a5,800030a4 <usertrap+0x62>
    yield();
    80003162:	fffff097          	auipc	ra,0xfffff
    80003166:	d96080e7          	jalr	-618(ra) # 80001ef8 <yield>
    8000316a:	bf2d                	j	800030a4 <usertrap+0x62>

000000008000316c <kerneltrap>:
{
    8000316c:	7179                	addi	sp,sp,-48
    8000316e:	f406                	sd	ra,40(sp)
    80003170:	f022                	sd	s0,32(sp)
    80003172:	ec26                	sd	s1,24(sp)
    80003174:	e84a                	sd	s2,16(sp)
    80003176:	e44e                	sd	s3,8(sp)
    80003178:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000317a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000317e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003182:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003186:	1004f793          	andi	a5,s1,256
    8000318a:	cb85                	beqz	a5,800031ba <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000318c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003190:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003192:	ef85                	bnez	a5,800031ca <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003194:	00000097          	auipc	ra,0x0
    80003198:	e0c080e7          	jalr	-500(ra) # 80002fa0 <devintr>
    8000319c:	cd1d                	beqz	a0,800031da <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000319e:	4789                	li	a5,2
    800031a0:	06f50a63          	beq	a0,a5,80003214 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031a4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031a8:	10049073          	csrw	sstatus,s1
}
    800031ac:	70a2                	ld	ra,40(sp)
    800031ae:	7402                	ld	s0,32(sp)
    800031b0:	64e2                	ld	s1,24(sp)
    800031b2:	6942                	ld	s2,16(sp)
    800031b4:	69a2                	ld	s3,8(sp)
    800031b6:	6145                	addi	sp,sp,48
    800031b8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031ba:	00005517          	auipc	a0,0x5
    800031be:	42650513          	addi	a0,a0,1062 # 800085e0 <states.0+0xc8>
    800031c2:	ffffd097          	auipc	ra,0xffffd
    800031c6:	368080e7          	jalr	872(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800031ca:	00005517          	auipc	a0,0x5
    800031ce:	43e50513          	addi	a0,a0,1086 # 80008608 <states.0+0xf0>
    800031d2:	ffffd097          	auipc	ra,0xffffd
    800031d6:	358080e7          	jalr	856(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800031da:	85ce                	mv	a1,s3
    800031dc:	00005517          	auipc	a0,0x5
    800031e0:	44c50513          	addi	a0,a0,1100 # 80008628 <states.0+0x110>
    800031e4:	ffffd097          	auipc	ra,0xffffd
    800031e8:	390080e7          	jalr	912(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031ec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800031f0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031f4:	00005517          	auipc	a0,0x5
    800031f8:	44450513          	addi	a0,a0,1092 # 80008638 <states.0+0x120>
    800031fc:	ffffd097          	auipc	ra,0xffffd
    80003200:	378080e7          	jalr	888(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003204:	00005517          	auipc	a0,0x5
    80003208:	44c50513          	addi	a0,a0,1100 # 80008650 <states.0+0x138>
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	31e080e7          	jalr	798(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	7d2080e7          	jalr	2002(ra) # 800019e6 <myproc>
    8000321c:	d541                	beqz	a0,800031a4 <kerneltrap+0x38>
    8000321e:	ffffe097          	auipc	ra,0xffffe
    80003222:	7c8080e7          	jalr	1992(ra) # 800019e6 <myproc>
    80003226:	4d18                	lw	a4,24(a0)
    80003228:	4791                	li	a5,4
    8000322a:	f6f71de3          	bne	a4,a5,800031a4 <kerneltrap+0x38>
    yield();
    8000322e:	fffff097          	auipc	ra,0xfffff
    80003232:	cca080e7          	jalr	-822(ra) # 80001ef8 <yield>
    80003236:	b7bd                	j	800031a4 <kerneltrap+0x38>

0000000080003238 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003238:	1101                	addi	sp,sp,-32
    8000323a:	ec06                	sd	ra,24(sp)
    8000323c:	e822                	sd	s0,16(sp)
    8000323e:	e426                	sd	s1,8(sp)
    80003240:	1000                	addi	s0,sp,32
    80003242:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003244:	ffffe097          	auipc	ra,0xffffe
    80003248:	7a2080e7          	jalr	1954(ra) # 800019e6 <myproc>
  switch (n) {
    8000324c:	4795                	li	a5,5
    8000324e:	0497e163          	bltu	a5,s1,80003290 <argraw+0x58>
    80003252:	048a                	slli	s1,s1,0x2
    80003254:	00005717          	auipc	a4,0x5
    80003258:	43470713          	addi	a4,a4,1076 # 80008688 <states.0+0x170>
    8000325c:	94ba                	add	s1,s1,a4
    8000325e:	409c                	lw	a5,0(s1)
    80003260:	97ba                	add	a5,a5,a4
    80003262:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003264:	6d3c                	ld	a5,88(a0)
    80003266:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret
    return p->trapframe->a1;
    80003272:	6d3c                	ld	a5,88(a0)
    80003274:	7fa8                	ld	a0,120(a5)
    80003276:	bfcd                	j	80003268 <argraw+0x30>
    return p->trapframe->a2;
    80003278:	6d3c                	ld	a5,88(a0)
    8000327a:	63c8                	ld	a0,128(a5)
    8000327c:	b7f5                	j	80003268 <argraw+0x30>
    return p->trapframe->a3;
    8000327e:	6d3c                	ld	a5,88(a0)
    80003280:	67c8                	ld	a0,136(a5)
    80003282:	b7dd                	j	80003268 <argraw+0x30>
    return p->trapframe->a4;
    80003284:	6d3c                	ld	a5,88(a0)
    80003286:	6bc8                	ld	a0,144(a5)
    80003288:	b7c5                	j	80003268 <argraw+0x30>
    return p->trapframe->a5;
    8000328a:	6d3c                	ld	a5,88(a0)
    8000328c:	6fc8                	ld	a0,152(a5)
    8000328e:	bfe9                	j	80003268 <argraw+0x30>
  panic("argraw");
    80003290:	00005517          	auipc	a0,0x5
    80003294:	3d050513          	addi	a0,a0,976 # 80008660 <states.0+0x148>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	292080e7          	jalr	658(ra) # 8000052a <panic>

00000000800032a0 <fetchaddr>:
{
    800032a0:	1101                	addi	sp,sp,-32
    800032a2:	ec06                	sd	ra,24(sp)
    800032a4:	e822                	sd	s0,16(sp)
    800032a6:	e426                	sd	s1,8(sp)
    800032a8:	e04a                	sd	s2,0(sp)
    800032aa:	1000                	addi	s0,sp,32
    800032ac:	84aa                	mv	s1,a0
    800032ae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800032b0:	ffffe097          	auipc	ra,0xffffe
    800032b4:	736080e7          	jalr	1846(ra) # 800019e6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800032b8:	653c                	ld	a5,72(a0)
    800032ba:	02f4f863          	bgeu	s1,a5,800032ea <fetchaddr+0x4a>
    800032be:	00848713          	addi	a4,s1,8
    800032c2:	02e7e663          	bltu	a5,a4,800032ee <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800032c6:	46a1                	li	a3,8
    800032c8:	8626                	mv	a2,s1
    800032ca:	85ca                	mv	a1,s2
    800032cc:	6928                	ld	a0,80(a0)
    800032ce:	ffffe097          	auipc	ra,0xffffe
    800032d2:	464080e7          	jalr	1124(ra) # 80001732 <copyin>
    800032d6:	00a03533          	snez	a0,a0
    800032da:	40a00533          	neg	a0,a0
}
    800032de:	60e2                	ld	ra,24(sp)
    800032e0:	6442                	ld	s0,16(sp)
    800032e2:	64a2                	ld	s1,8(sp)
    800032e4:	6902                	ld	s2,0(sp)
    800032e6:	6105                	addi	sp,sp,32
    800032e8:	8082                	ret
    return -1;
    800032ea:	557d                	li	a0,-1
    800032ec:	bfcd                	j	800032de <fetchaddr+0x3e>
    800032ee:	557d                	li	a0,-1
    800032f0:	b7fd                	j	800032de <fetchaddr+0x3e>

00000000800032f2 <fetchstr>:
{
    800032f2:	7179                	addi	sp,sp,-48
    800032f4:	f406                	sd	ra,40(sp)
    800032f6:	f022                	sd	s0,32(sp)
    800032f8:	ec26                	sd	s1,24(sp)
    800032fa:	e84a                	sd	s2,16(sp)
    800032fc:	e44e                	sd	s3,8(sp)
    800032fe:	1800                	addi	s0,sp,48
    80003300:	892a                	mv	s2,a0
    80003302:	84ae                	mv	s1,a1
    80003304:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	6e0080e7          	jalr	1760(ra) # 800019e6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000330e:	86ce                	mv	a3,s3
    80003310:	864a                	mv	a2,s2
    80003312:	85a6                	mv	a1,s1
    80003314:	6928                	ld	a0,80(a0)
    80003316:	ffffe097          	auipc	ra,0xffffe
    8000331a:	4aa080e7          	jalr	1194(ra) # 800017c0 <copyinstr>
  if(err < 0)
    8000331e:	00054763          	bltz	a0,8000332c <fetchstr+0x3a>
  return strlen(buf);
    80003322:	8526                	mv	a0,s1
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	b30080e7          	jalr	-1232(ra) # 80000e54 <strlen>
}
    8000332c:	70a2                	ld	ra,40(sp)
    8000332e:	7402                	ld	s0,32(sp)
    80003330:	64e2                	ld	s1,24(sp)
    80003332:	6942                	ld	s2,16(sp)
    80003334:	69a2                	ld	s3,8(sp)
    80003336:	6145                	addi	sp,sp,48
    80003338:	8082                	ret

000000008000333a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000333a:	1101                	addi	sp,sp,-32
    8000333c:	ec06                	sd	ra,24(sp)
    8000333e:	e822                	sd	s0,16(sp)
    80003340:	e426                	sd	s1,8(sp)
    80003342:	1000                	addi	s0,sp,32
    80003344:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	ef2080e7          	jalr	-270(ra) # 80003238 <argraw>
    8000334e:	c088                	sw	a0,0(s1)
  return 0;
}
    80003350:	4501                	li	a0,0
    80003352:	60e2                	ld	ra,24(sp)
    80003354:	6442                	ld	s0,16(sp)
    80003356:	64a2                	ld	s1,8(sp)
    80003358:	6105                	addi	sp,sp,32
    8000335a:	8082                	ret

000000008000335c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000335c:	1101                	addi	sp,sp,-32
    8000335e:	ec06                	sd	ra,24(sp)
    80003360:	e822                	sd	s0,16(sp)
    80003362:	e426                	sd	s1,8(sp)
    80003364:	1000                	addi	s0,sp,32
    80003366:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	ed0080e7          	jalr	-304(ra) # 80003238 <argraw>
    80003370:	e088                	sd	a0,0(s1)
  return 0;
}
    80003372:	4501                	li	a0,0
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6105                	addi	sp,sp,32
    8000337c:	8082                	ret

000000008000337e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000337e:	1101                	addi	sp,sp,-32
    80003380:	ec06                	sd	ra,24(sp)
    80003382:	e822                	sd	s0,16(sp)
    80003384:	e426                	sd	s1,8(sp)
    80003386:	e04a                	sd	s2,0(sp)
    80003388:	1000                	addi	s0,sp,32
    8000338a:	84ae                	mv	s1,a1
    8000338c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	eaa080e7          	jalr	-342(ra) # 80003238 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003396:	864a                	mv	a2,s2
    80003398:	85a6                	mv	a1,s1
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	f58080e7          	jalr	-168(ra) # 800032f2 <fetchstr>
}
    800033a2:	60e2                	ld	ra,24(sp)
    800033a4:	6442                	ld	s0,16(sp)
    800033a6:	64a2                	ld	s1,8(sp)
    800033a8:	6902                	ld	s2,0(sp)
    800033aa:	6105                	addi	sp,sp,32
    800033ac:	8082                	ret

00000000800033ae <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800033ae:	1101                	addi	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	e04a                	sd	s2,0(sp)
    800033b8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	62c080e7          	jalr	1580(ra) # 800019e6 <myproc>
    800033c2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800033c4:	05853903          	ld	s2,88(a0)
    800033c8:	0a893783          	ld	a5,168(s2)
    800033cc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800033d0:	37fd                	addiw	a5,a5,-1
    800033d2:	4751                	li	a4,20
    800033d4:	00f76f63          	bltu	a4,a5,800033f2 <syscall+0x44>
    800033d8:	00369713          	slli	a4,a3,0x3
    800033dc:	00005797          	auipc	a5,0x5
    800033e0:	2c478793          	addi	a5,a5,708 # 800086a0 <syscalls>
    800033e4:	97ba                	add	a5,a5,a4
    800033e6:	639c                	ld	a5,0(a5)
    800033e8:	c789                	beqz	a5,800033f2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800033ea:	9782                	jalr	a5
    800033ec:	06a93823          	sd	a0,112(s2)
    800033f0:	a839                	j	8000340e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800033f2:	15848613          	addi	a2,s1,344
    800033f6:	588c                	lw	a1,48(s1)
    800033f8:	00005517          	auipc	a0,0x5
    800033fc:	27050513          	addi	a0,a0,624 # 80008668 <states.0+0x150>
    80003400:	ffffd097          	auipc	ra,0xffffd
    80003404:	174080e7          	jalr	372(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003408:	6cbc                	ld	a5,88(s1)
    8000340a:	577d                	li	a4,-1
    8000340c:	fbb8                	sd	a4,112(a5)
  }
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6902                	ld	s2,0(sp)
    80003416:	6105                	addi	sp,sp,32
    80003418:	8082                	ret

000000008000341a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000341a:	1101                	addi	sp,sp,-32
    8000341c:	ec06                	sd	ra,24(sp)
    8000341e:	e822                	sd	s0,16(sp)
    80003420:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003422:	fec40593          	addi	a1,s0,-20
    80003426:	4501                	li	a0,0
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	f12080e7          	jalr	-238(ra) # 8000333a <argint>
    return -1;
    80003430:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003432:	00054963          	bltz	a0,80003444 <sys_exit+0x2a>
  exit(n);
    80003436:	fec42503          	lw	a0,-20(s0)
    8000343a:	fffff097          	auipc	ra,0xfffff
    8000343e:	092080e7          	jalr	146(ra) # 800024cc <exit>
  return 0;  // not reached
    80003442:	4781                	li	a5,0
}
    80003444:	853e                	mv	a0,a5
    80003446:	60e2                	ld	ra,24(sp)
    80003448:	6442                	ld	s0,16(sp)
    8000344a:	6105                	addi	sp,sp,32
    8000344c:	8082                	ret

000000008000344e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000344e:	1141                	addi	sp,sp,-16
    80003450:	e406                	sd	ra,8(sp)
    80003452:	e022                	sd	s0,0(sp)
    80003454:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	590080e7          	jalr	1424(ra) # 800019e6 <myproc>
}
    8000345e:	5908                	lw	a0,48(a0)
    80003460:	60a2                	ld	ra,8(sp)
    80003462:	6402                	ld	s0,0(sp)
    80003464:	0141                	addi	sp,sp,16
    80003466:	8082                	ret

0000000080003468 <sys_fork>:

uint64
sys_fork(void)
{
    80003468:	1141                	addi	sp,sp,-16
    8000346a:	e406                	sd	ra,8(sp)
    8000346c:	e022                	sd	s0,0(sp)
    8000346e:	0800                	addi	s0,sp,16
  return fork();
    80003470:	fffff097          	auipc	ra,0xfffff
    80003474:	e7e080e7          	jalr	-386(ra) # 800022ee <fork>
}
    80003478:	60a2                	ld	ra,8(sp)
    8000347a:	6402                	ld	s0,0(sp)
    8000347c:	0141                	addi	sp,sp,16
    8000347e:	8082                	ret

0000000080003480 <sys_wait>:

uint64
sys_wait(void)
{
    80003480:	1101                	addi	sp,sp,-32
    80003482:	ec06                	sd	ra,24(sp)
    80003484:	e822                	sd	s0,16(sp)
    80003486:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003488:	fe840593          	addi	a1,s0,-24
    8000348c:	4501                	li	a0,0
    8000348e:	00000097          	auipc	ra,0x0
    80003492:	ece080e7          	jalr	-306(ra) # 8000335c <argaddr>
    80003496:	87aa                	mv	a5,a0
    return -1;
    80003498:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000349a:	0007c863          	bltz	a5,800034aa <sys_wait+0x2a>
  return wait(p);
    8000349e:	fe843503          	ld	a0,-24(s0)
    800034a2:	fffff097          	auipc	ra,0xfffff
    800034a6:	118080e7          	jalr	280(ra) # 800025ba <wait>
}
    800034aa:	60e2                	ld	ra,24(sp)
    800034ac:	6442                	ld	s0,16(sp)
    800034ae:	6105                	addi	sp,sp,32
    800034b0:	8082                	ret

00000000800034b2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800034bc:	fdc40593          	addi	a1,s0,-36
    800034c0:	4501                	li	a0,0
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	e78080e7          	jalr	-392(ra) # 8000333a <argint>
    return -1;
    800034ca:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800034cc:	00054f63          	bltz	a0,800034ea <sys_sbrk+0x38>
  addr = myproc()->sz;
    800034d0:	ffffe097          	auipc	ra,0xffffe
    800034d4:	516080e7          	jalr	1302(ra) # 800019e6 <myproc>
    800034d8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800034da:	fdc42503          	lw	a0,-36(s0)
    800034de:	fffff097          	auipc	ra,0xfffff
    800034e2:	862080e7          	jalr	-1950(ra) # 80001d40 <growproc>
    800034e6:	00054863          	bltz	a0,800034f6 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800034ea:	8526                	mv	a0,s1
    800034ec:	70a2                	ld	ra,40(sp)
    800034ee:	7402                	ld	s0,32(sp)
    800034f0:	64e2                	ld	s1,24(sp)
    800034f2:	6145                	addi	sp,sp,48
    800034f4:	8082                	ret
    return -1;
    800034f6:	54fd                	li	s1,-1
    800034f8:	bfcd                	j	800034ea <sys_sbrk+0x38>

00000000800034fa <sys_sleep>:

uint64
sys_sleep(void)
{
    800034fa:	7139                	addi	sp,sp,-64
    800034fc:	fc06                	sd	ra,56(sp)
    800034fe:	f822                	sd	s0,48(sp)
    80003500:	f426                	sd	s1,40(sp)
    80003502:	f04a                	sd	s2,32(sp)
    80003504:	ec4e                	sd	s3,24(sp)
    80003506:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003508:	fcc40593          	addi	a1,s0,-52
    8000350c:	4501                	li	a0,0
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	e2c080e7          	jalr	-468(ra) # 8000333a <argint>
    return -1;
    80003516:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003518:	06054563          	bltz	a0,80003582 <sys_sleep+0x88>
  acquire(&tickslock);
    8000351c:	0001c517          	auipc	a0,0x1c
    80003520:	fb450513          	addi	a0,a0,-76 # 8001f4d0 <tickslock>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	69e080e7          	jalr	1694(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000352c:	00006917          	auipc	s2,0x6
    80003530:	b0492903          	lw	s2,-1276(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003534:	fcc42783          	lw	a5,-52(s0)
    80003538:	cf85                	beqz	a5,80003570 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000353a:	0001c997          	auipc	s3,0x1c
    8000353e:	f9698993          	addi	s3,s3,-106 # 8001f4d0 <tickslock>
    80003542:	00006497          	auipc	s1,0x6
    80003546:	aee48493          	addi	s1,s1,-1298 # 80009030 <ticks>
    if(myproc()->killed){
    8000354a:	ffffe097          	auipc	ra,0xffffe
    8000354e:	49c080e7          	jalr	1180(ra) # 800019e6 <myproc>
    80003552:	551c                	lw	a5,40(a0)
    80003554:	ef9d                	bnez	a5,80003592 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003556:	85ce                	mv	a1,s3
    80003558:	8526                	mv	a0,s1
    8000355a:	fffff097          	auipc	ra,0xfffff
    8000355e:	9da080e7          	jalr	-1574(ra) # 80001f34 <sleep>
  while(ticks - ticks0 < n){
    80003562:	409c                	lw	a5,0(s1)
    80003564:	412787bb          	subw	a5,a5,s2
    80003568:	fcc42703          	lw	a4,-52(s0)
    8000356c:	fce7efe3          	bltu	a5,a4,8000354a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003570:	0001c517          	auipc	a0,0x1c
    80003574:	f6050513          	addi	a0,a0,-160 # 8001f4d0 <tickslock>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	710080e7          	jalr	1808(ra) # 80000c88 <release>
  return 0;
    80003580:	4781                	li	a5,0
}
    80003582:	853e                	mv	a0,a5
    80003584:	70e2                	ld	ra,56(sp)
    80003586:	7442                	ld	s0,48(sp)
    80003588:	74a2                	ld	s1,40(sp)
    8000358a:	7902                	ld	s2,32(sp)
    8000358c:	69e2                	ld	s3,24(sp)
    8000358e:	6121                	addi	sp,sp,64
    80003590:	8082                	ret
      release(&tickslock);
    80003592:	0001c517          	auipc	a0,0x1c
    80003596:	f3e50513          	addi	a0,a0,-194 # 8001f4d0 <tickslock>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	6ee080e7          	jalr	1774(ra) # 80000c88 <release>
      return -1;
    800035a2:	57fd                	li	a5,-1
    800035a4:	bff9                	j	80003582 <sys_sleep+0x88>

00000000800035a6 <sys_kill>:

uint64
sys_kill(void)
{
    800035a6:	1101                	addi	sp,sp,-32
    800035a8:	ec06                	sd	ra,24(sp)
    800035aa:	e822                	sd	s0,16(sp)
    800035ac:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800035ae:	fec40593          	addi	a1,s0,-20
    800035b2:	4501                	li	a0,0
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	d86080e7          	jalr	-634(ra) # 8000333a <argint>
    800035bc:	87aa                	mv	a5,a0
    return -1;
    800035be:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800035c0:	0007c863          	bltz	a5,800035d0 <sys_kill+0x2a>
  return kill(pid);
    800035c4:	fec42503          	lw	a0,-20(s0)
    800035c8:	fffff097          	auipc	ra,0xfffff
    800035cc:	aa0080e7          	jalr	-1376(ra) # 80002068 <kill>
}
    800035d0:	60e2                	ld	ra,24(sp)
    800035d2:	6442                	ld	s0,16(sp)
    800035d4:	6105                	addi	sp,sp,32
    800035d6:	8082                	ret

00000000800035d8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800035d8:	1101                	addi	sp,sp,-32
    800035da:	ec06                	sd	ra,24(sp)
    800035dc:	e822                	sd	s0,16(sp)
    800035de:	e426                	sd	s1,8(sp)
    800035e0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800035e2:	0001c517          	auipc	a0,0x1c
    800035e6:	eee50513          	addi	a0,a0,-274 # 8001f4d0 <tickslock>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	5d8080e7          	jalr	1496(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800035f2:	00006497          	auipc	s1,0x6
    800035f6:	a3e4a483          	lw	s1,-1474(s1) # 80009030 <ticks>
  release(&tickslock);
    800035fa:	0001c517          	auipc	a0,0x1c
    800035fe:	ed650513          	addi	a0,a0,-298 # 8001f4d0 <tickslock>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	686080e7          	jalr	1670(ra) # 80000c88 <release>
  return xticks;
}
    8000360a:	02049513          	slli	a0,s1,0x20
    8000360e:	9101                	srli	a0,a0,0x20
    80003610:	60e2                	ld	ra,24(sp)
    80003612:	6442                	ld	s0,16(sp)
    80003614:	64a2                	ld	s1,8(sp)
    80003616:	6105                	addi	sp,sp,32
    80003618:	8082                	ret

000000008000361a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000361a:	7179                	addi	sp,sp,-48
    8000361c:	f406                	sd	ra,40(sp)
    8000361e:	f022                	sd	s0,32(sp)
    80003620:	ec26                	sd	s1,24(sp)
    80003622:	e84a                	sd	s2,16(sp)
    80003624:	e44e                	sd	s3,8(sp)
    80003626:	e052                	sd	s4,0(sp)
    80003628:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000362a:	00005597          	auipc	a1,0x5
    8000362e:	12658593          	addi	a1,a1,294 # 80008750 <syscalls+0xb0>
    80003632:	0001c517          	auipc	a0,0x1c
    80003636:	eb650513          	addi	a0,a0,-330 # 8001f4e8 <bcache>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	4f8080e7          	jalr	1272(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003642:	00024797          	auipc	a5,0x24
    80003646:	ea678793          	addi	a5,a5,-346 # 800274e8 <bcache+0x8000>
    8000364a:	00024717          	auipc	a4,0x24
    8000364e:	10670713          	addi	a4,a4,262 # 80027750 <bcache+0x8268>
    80003652:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003656:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000365a:	0001c497          	auipc	s1,0x1c
    8000365e:	ea648493          	addi	s1,s1,-346 # 8001f500 <bcache+0x18>
    b->next = bcache.head.next;
    80003662:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003664:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003666:	00005a17          	auipc	s4,0x5
    8000366a:	0f2a0a13          	addi	s4,s4,242 # 80008758 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000366e:	2b893783          	ld	a5,696(s2)
    80003672:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003674:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003678:	85d2                	mv	a1,s4
    8000367a:	01048513          	addi	a0,s1,16
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	7d4080e7          	jalr	2004(ra) # 80004e52 <initsleeplock>
    bcache.head.next->prev = b;
    80003686:	2b893783          	ld	a5,696(s2)
    8000368a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000368c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003690:	45848493          	addi	s1,s1,1112
    80003694:	fd349de3          	bne	s1,s3,8000366e <binit+0x54>
  }
}
    80003698:	70a2                	ld	ra,40(sp)
    8000369a:	7402                	ld	s0,32(sp)
    8000369c:	64e2                	ld	s1,24(sp)
    8000369e:	6942                	ld	s2,16(sp)
    800036a0:	69a2                	ld	s3,8(sp)
    800036a2:	6a02                	ld	s4,0(sp)
    800036a4:	6145                	addi	sp,sp,48
    800036a6:	8082                	ret

00000000800036a8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036a8:	7179                	addi	sp,sp,-48
    800036aa:	f406                	sd	ra,40(sp)
    800036ac:	f022                	sd	s0,32(sp)
    800036ae:	ec26                	sd	s1,24(sp)
    800036b0:	e84a                	sd	s2,16(sp)
    800036b2:	e44e                	sd	s3,8(sp)
    800036b4:	1800                	addi	s0,sp,48
    800036b6:	892a                	mv	s2,a0
    800036b8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036ba:	0001c517          	auipc	a0,0x1c
    800036be:	e2e50513          	addi	a0,a0,-466 # 8001f4e8 <bcache>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	500080e7          	jalr	1280(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036ca:	00024497          	auipc	s1,0x24
    800036ce:	0d64b483          	ld	s1,214(s1) # 800277a0 <bcache+0x82b8>
    800036d2:	00024797          	auipc	a5,0x24
    800036d6:	07e78793          	addi	a5,a5,126 # 80027750 <bcache+0x8268>
    800036da:	02f48f63          	beq	s1,a5,80003718 <bread+0x70>
    800036de:	873e                	mv	a4,a5
    800036e0:	a021                	j	800036e8 <bread+0x40>
    800036e2:	68a4                	ld	s1,80(s1)
    800036e4:	02e48a63          	beq	s1,a4,80003718 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036e8:	449c                	lw	a5,8(s1)
    800036ea:	ff279ce3          	bne	a5,s2,800036e2 <bread+0x3a>
    800036ee:	44dc                	lw	a5,12(s1)
    800036f0:	ff3799e3          	bne	a5,s3,800036e2 <bread+0x3a>
      b->refcnt++;
    800036f4:	40bc                	lw	a5,64(s1)
    800036f6:	2785                	addiw	a5,a5,1
    800036f8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036fa:	0001c517          	auipc	a0,0x1c
    800036fe:	dee50513          	addi	a0,a0,-530 # 8001f4e8 <bcache>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	586080e7          	jalr	1414(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    8000370a:	01048513          	addi	a0,s1,16
    8000370e:	00001097          	auipc	ra,0x1
    80003712:	77e080e7          	jalr	1918(ra) # 80004e8c <acquiresleep>
      return b;
    80003716:	a8b9                	j	80003774 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003718:	00024497          	auipc	s1,0x24
    8000371c:	0804b483          	ld	s1,128(s1) # 80027798 <bcache+0x82b0>
    80003720:	00024797          	auipc	a5,0x24
    80003724:	03078793          	addi	a5,a5,48 # 80027750 <bcache+0x8268>
    80003728:	00f48863          	beq	s1,a5,80003738 <bread+0x90>
    8000372c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000372e:	40bc                	lw	a5,64(s1)
    80003730:	cf81                	beqz	a5,80003748 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003732:	64a4                	ld	s1,72(s1)
    80003734:	fee49de3          	bne	s1,a4,8000372e <bread+0x86>
  panic("bget: no buffers");
    80003738:	00005517          	auipc	a0,0x5
    8000373c:	02850513          	addi	a0,a0,40 # 80008760 <syscalls+0xc0>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	dea080e7          	jalr	-534(ra) # 8000052a <panic>
      b->dev = dev;
    80003748:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000374c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003750:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003754:	4785                	li	a5,1
    80003756:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003758:	0001c517          	auipc	a0,0x1c
    8000375c:	d9050513          	addi	a0,a0,-624 # 8001f4e8 <bcache>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	528080e7          	jalr	1320(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003768:	01048513          	addi	a0,s1,16
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	720080e7          	jalr	1824(ra) # 80004e8c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003774:	409c                	lw	a5,0(s1)
    80003776:	cb89                	beqz	a5,80003788 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003778:	8526                	mv	a0,s1
    8000377a:	70a2                	ld	ra,40(sp)
    8000377c:	7402                	ld	s0,32(sp)
    8000377e:	64e2                	ld	s1,24(sp)
    80003780:	6942                	ld	s2,16(sp)
    80003782:	69a2                	ld	s3,8(sp)
    80003784:	6145                	addi	sp,sp,48
    80003786:	8082                	ret
    virtio_disk_rw(b, 0);
    80003788:	4581                	li	a1,0
    8000378a:	8526                	mv	a0,s1
    8000378c:	00003097          	auipc	ra,0x3
    80003790:	4fa080e7          	jalr	1274(ra) # 80006c86 <virtio_disk_rw>
    b->valid = 1;
    80003794:	4785                	li	a5,1
    80003796:	c09c                	sw	a5,0(s1)
  return b;
    80003798:	b7c5                	j	80003778 <bread+0xd0>

000000008000379a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000379a:	1101                	addi	sp,sp,-32
    8000379c:	ec06                	sd	ra,24(sp)
    8000379e:	e822                	sd	s0,16(sp)
    800037a0:	e426                	sd	s1,8(sp)
    800037a2:	1000                	addi	s0,sp,32
    800037a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037a6:	0541                	addi	a0,a0,16
    800037a8:	00001097          	auipc	ra,0x1
    800037ac:	77e080e7          	jalr	1918(ra) # 80004f26 <holdingsleep>
    800037b0:	cd01                	beqz	a0,800037c8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037b2:	4585                	li	a1,1
    800037b4:	8526                	mv	a0,s1
    800037b6:	00003097          	auipc	ra,0x3
    800037ba:	4d0080e7          	jalr	1232(ra) # 80006c86 <virtio_disk_rw>
}
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6105                	addi	sp,sp,32
    800037c6:	8082                	ret
    panic("bwrite");
    800037c8:	00005517          	auipc	a0,0x5
    800037cc:	fb050513          	addi	a0,a0,-80 # 80008778 <syscalls+0xd8>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	d5a080e7          	jalr	-678(ra) # 8000052a <panic>

00000000800037d8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037d8:	1101                	addi	sp,sp,-32
    800037da:	ec06                	sd	ra,24(sp)
    800037dc:	e822                	sd	s0,16(sp)
    800037de:	e426                	sd	s1,8(sp)
    800037e0:	e04a                	sd	s2,0(sp)
    800037e2:	1000                	addi	s0,sp,32
    800037e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037e6:	01050913          	addi	s2,a0,16
    800037ea:	854a                	mv	a0,s2
    800037ec:	00001097          	auipc	ra,0x1
    800037f0:	73a080e7          	jalr	1850(ra) # 80004f26 <holdingsleep>
    800037f4:	c92d                	beqz	a0,80003866 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	6ea080e7          	jalr	1770(ra) # 80004ee2 <releasesleep>

  acquire(&bcache.lock);
    80003800:	0001c517          	auipc	a0,0x1c
    80003804:	ce850513          	addi	a0,a0,-792 # 8001f4e8 <bcache>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	3ba080e7          	jalr	954(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003810:	40bc                	lw	a5,64(s1)
    80003812:	37fd                	addiw	a5,a5,-1
    80003814:	0007871b          	sext.w	a4,a5
    80003818:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000381a:	eb05                	bnez	a4,8000384a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000381c:	68bc                	ld	a5,80(s1)
    8000381e:	64b8                	ld	a4,72(s1)
    80003820:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003822:	64bc                	ld	a5,72(s1)
    80003824:	68b8                	ld	a4,80(s1)
    80003826:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003828:	00024797          	auipc	a5,0x24
    8000382c:	cc078793          	addi	a5,a5,-832 # 800274e8 <bcache+0x8000>
    80003830:	2b87b703          	ld	a4,696(a5)
    80003834:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003836:	00024717          	auipc	a4,0x24
    8000383a:	f1a70713          	addi	a4,a4,-230 # 80027750 <bcache+0x8268>
    8000383e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003840:	2b87b703          	ld	a4,696(a5)
    80003844:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003846:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000384a:	0001c517          	auipc	a0,0x1c
    8000384e:	c9e50513          	addi	a0,a0,-866 # 8001f4e8 <bcache>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	436080e7          	jalr	1078(ra) # 80000c88 <release>
}
    8000385a:	60e2                	ld	ra,24(sp)
    8000385c:	6442                	ld	s0,16(sp)
    8000385e:	64a2                	ld	s1,8(sp)
    80003860:	6902                	ld	s2,0(sp)
    80003862:	6105                	addi	sp,sp,32
    80003864:	8082                	ret
    panic("brelse");
    80003866:	00005517          	auipc	a0,0x5
    8000386a:	f1a50513          	addi	a0,a0,-230 # 80008780 <syscalls+0xe0>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	cbc080e7          	jalr	-836(ra) # 8000052a <panic>

0000000080003876 <bpin>:

void
bpin(struct buf *b) {
    80003876:	1101                	addi	sp,sp,-32
    80003878:	ec06                	sd	ra,24(sp)
    8000387a:	e822                	sd	s0,16(sp)
    8000387c:	e426                	sd	s1,8(sp)
    8000387e:	1000                	addi	s0,sp,32
    80003880:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003882:	0001c517          	auipc	a0,0x1c
    80003886:	c6650513          	addi	a0,a0,-922 # 8001f4e8 <bcache>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	338080e7          	jalr	824(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003892:	40bc                	lw	a5,64(s1)
    80003894:	2785                	addiw	a5,a5,1
    80003896:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003898:	0001c517          	auipc	a0,0x1c
    8000389c:	c5050513          	addi	a0,a0,-944 # 8001f4e8 <bcache>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	3e8080e7          	jalr	1000(ra) # 80000c88 <release>
}
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	64a2                	ld	s1,8(sp)
    800038ae:	6105                	addi	sp,sp,32
    800038b0:	8082                	ret

00000000800038b2 <bunpin>:

void
bunpin(struct buf *b) {
    800038b2:	1101                	addi	sp,sp,-32
    800038b4:	ec06                	sd	ra,24(sp)
    800038b6:	e822                	sd	s0,16(sp)
    800038b8:	e426                	sd	s1,8(sp)
    800038ba:	1000                	addi	s0,sp,32
    800038bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038be:	0001c517          	auipc	a0,0x1c
    800038c2:	c2a50513          	addi	a0,a0,-982 # 8001f4e8 <bcache>
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	2fc080e7          	jalr	764(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800038ce:	40bc                	lw	a5,64(s1)
    800038d0:	37fd                	addiw	a5,a5,-1
    800038d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038d4:	0001c517          	auipc	a0,0x1c
    800038d8:	c1450513          	addi	a0,a0,-1004 # 8001f4e8 <bcache>
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	3ac080e7          	jalr	940(ra) # 80000c88 <release>
}
    800038e4:	60e2                	ld	ra,24(sp)
    800038e6:	6442                	ld	s0,16(sp)
    800038e8:	64a2                	ld	s1,8(sp)
    800038ea:	6105                	addi	sp,sp,32
    800038ec:	8082                	ret

00000000800038ee <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800038ee:	1101                	addi	sp,sp,-32
    800038f0:	ec06                	sd	ra,24(sp)
    800038f2:	e822                	sd	s0,16(sp)
    800038f4:	e426                	sd	s1,8(sp)
    800038f6:	e04a                	sd	s2,0(sp)
    800038f8:	1000                	addi	s0,sp,32
    800038fa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800038fc:	00d5d59b          	srliw	a1,a1,0xd
    80003900:	00024797          	auipc	a5,0x24
    80003904:	2c47a783          	lw	a5,708(a5) # 80027bc4 <sb+0x1c>
    80003908:	9dbd                	addw	a1,a1,a5
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	d9e080e7          	jalr	-610(ra) # 800036a8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003912:	0074f713          	andi	a4,s1,7
    80003916:	4785                	li	a5,1
    80003918:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000391c:	14ce                	slli	s1,s1,0x33
    8000391e:	90d9                	srli	s1,s1,0x36
    80003920:	00950733          	add	a4,a0,s1
    80003924:	05874703          	lbu	a4,88(a4)
    80003928:	00e7f6b3          	and	a3,a5,a4
    8000392c:	c69d                	beqz	a3,8000395a <bfree+0x6c>
    8000392e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003930:	94aa                	add	s1,s1,a0
    80003932:	fff7c793          	not	a5,a5
    80003936:	8ff9                	and	a5,a5,a4
    80003938:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000393c:	00001097          	auipc	ra,0x1
    80003940:	430080e7          	jalr	1072(ra) # 80004d6c <log_write>
  brelse(bp);
    80003944:	854a                	mv	a0,s2
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	e92080e7          	jalr	-366(ra) # 800037d8 <brelse>
}
    8000394e:	60e2                	ld	ra,24(sp)
    80003950:	6442                	ld	s0,16(sp)
    80003952:	64a2                	ld	s1,8(sp)
    80003954:	6902                	ld	s2,0(sp)
    80003956:	6105                	addi	sp,sp,32
    80003958:	8082                	ret
    panic("freeing free block");
    8000395a:	00005517          	auipc	a0,0x5
    8000395e:	e2e50513          	addi	a0,a0,-466 # 80008788 <syscalls+0xe8>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	bc8080e7          	jalr	-1080(ra) # 8000052a <panic>

000000008000396a <balloc>:
{
    8000396a:	711d                	addi	sp,sp,-96
    8000396c:	ec86                	sd	ra,88(sp)
    8000396e:	e8a2                	sd	s0,80(sp)
    80003970:	e4a6                	sd	s1,72(sp)
    80003972:	e0ca                	sd	s2,64(sp)
    80003974:	fc4e                	sd	s3,56(sp)
    80003976:	f852                	sd	s4,48(sp)
    80003978:	f456                	sd	s5,40(sp)
    8000397a:	f05a                	sd	s6,32(sp)
    8000397c:	ec5e                	sd	s7,24(sp)
    8000397e:	e862                	sd	s8,16(sp)
    80003980:	e466                	sd	s9,8(sp)
    80003982:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003984:	00024797          	auipc	a5,0x24
    80003988:	2287a783          	lw	a5,552(a5) # 80027bac <sb+0x4>
    8000398c:	cbd1                	beqz	a5,80003a20 <balloc+0xb6>
    8000398e:	8baa                	mv	s7,a0
    80003990:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003992:	00024b17          	auipc	s6,0x24
    80003996:	216b0b13          	addi	s6,s6,534 # 80027ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000399a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000399c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000399e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039a0:	6c89                	lui	s9,0x2
    800039a2:	a831                	j	800039be <balloc+0x54>
    brelse(bp);
    800039a4:	854a                	mv	a0,s2
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	e32080e7          	jalr	-462(ra) # 800037d8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039ae:	015c87bb          	addw	a5,s9,s5
    800039b2:	00078a9b          	sext.w	s5,a5
    800039b6:	004b2703          	lw	a4,4(s6)
    800039ba:	06eaf363          	bgeu	s5,a4,80003a20 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800039be:	41fad79b          	sraiw	a5,s5,0x1f
    800039c2:	0137d79b          	srliw	a5,a5,0x13
    800039c6:	015787bb          	addw	a5,a5,s5
    800039ca:	40d7d79b          	sraiw	a5,a5,0xd
    800039ce:	01cb2583          	lw	a1,28(s6)
    800039d2:	9dbd                	addw	a1,a1,a5
    800039d4:	855e                	mv	a0,s7
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	cd2080e7          	jalr	-814(ra) # 800036a8 <bread>
    800039de:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039e0:	004b2503          	lw	a0,4(s6)
    800039e4:	000a849b          	sext.w	s1,s5
    800039e8:	8662                	mv	a2,s8
    800039ea:	faa4fde3          	bgeu	s1,a0,800039a4 <balloc+0x3a>
      m = 1 << (bi % 8);
    800039ee:	41f6579b          	sraiw	a5,a2,0x1f
    800039f2:	01d7d69b          	srliw	a3,a5,0x1d
    800039f6:	00c6873b          	addw	a4,a3,a2
    800039fa:	00777793          	andi	a5,a4,7
    800039fe:	9f95                	subw	a5,a5,a3
    80003a00:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a04:	4037571b          	sraiw	a4,a4,0x3
    80003a08:	00e906b3          	add	a3,s2,a4
    80003a0c:	0586c683          	lbu	a3,88(a3)
    80003a10:	00d7f5b3          	and	a1,a5,a3
    80003a14:	cd91                	beqz	a1,80003a30 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a16:	2605                	addiw	a2,a2,1
    80003a18:	2485                	addiw	s1,s1,1
    80003a1a:	fd4618e3          	bne	a2,s4,800039ea <balloc+0x80>
    80003a1e:	b759                	j	800039a4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a20:	00005517          	auipc	a0,0x5
    80003a24:	d8050513          	addi	a0,a0,-640 # 800087a0 <syscalls+0x100>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	b02080e7          	jalr	-1278(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a30:	974a                	add	a4,a4,s2
    80003a32:	8fd5                	or	a5,a5,a3
    80003a34:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a38:	854a                	mv	a0,s2
    80003a3a:	00001097          	auipc	ra,0x1
    80003a3e:	332080e7          	jalr	818(ra) # 80004d6c <log_write>
        brelse(bp);
    80003a42:	854a                	mv	a0,s2
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	d94080e7          	jalr	-620(ra) # 800037d8 <brelse>
  bp = bread(dev, bno);
    80003a4c:	85a6                	mv	a1,s1
    80003a4e:	855e                	mv	a0,s7
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	c58080e7          	jalr	-936(ra) # 800036a8 <bread>
    80003a58:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a5a:	40000613          	li	a2,1024
    80003a5e:	4581                	li	a1,0
    80003a60:	05850513          	addi	a0,a0,88
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	26c080e7          	jalr	620(ra) # 80000cd0 <memset>
  log_write(bp);
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	00001097          	auipc	ra,0x1
    80003a72:	2fe080e7          	jalr	766(ra) # 80004d6c <log_write>
  brelse(bp);
    80003a76:	854a                	mv	a0,s2
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	d60080e7          	jalr	-672(ra) # 800037d8 <brelse>
}
    80003a80:	8526                	mv	a0,s1
    80003a82:	60e6                	ld	ra,88(sp)
    80003a84:	6446                	ld	s0,80(sp)
    80003a86:	64a6                	ld	s1,72(sp)
    80003a88:	6906                	ld	s2,64(sp)
    80003a8a:	79e2                	ld	s3,56(sp)
    80003a8c:	7a42                	ld	s4,48(sp)
    80003a8e:	7aa2                	ld	s5,40(sp)
    80003a90:	7b02                	ld	s6,32(sp)
    80003a92:	6be2                	ld	s7,24(sp)
    80003a94:	6c42                	ld	s8,16(sp)
    80003a96:	6ca2                	ld	s9,8(sp)
    80003a98:	6125                	addi	sp,sp,96
    80003a9a:	8082                	ret

0000000080003a9c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a9c:	7179                	addi	sp,sp,-48
    80003a9e:	f406                	sd	ra,40(sp)
    80003aa0:	f022                	sd	s0,32(sp)
    80003aa2:	ec26                	sd	s1,24(sp)
    80003aa4:	e84a                	sd	s2,16(sp)
    80003aa6:	e44e                	sd	s3,8(sp)
    80003aa8:	e052                	sd	s4,0(sp)
    80003aaa:	1800                	addi	s0,sp,48
    80003aac:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003aae:	47ad                	li	a5,11
    80003ab0:	04b7fe63          	bgeu	a5,a1,80003b0c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003ab4:	ff45849b          	addiw	s1,a1,-12
    80003ab8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003abc:	0ff00793          	li	a5,255
    80003ac0:	0ae7e463          	bltu	a5,a4,80003b68 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ac4:	08052583          	lw	a1,128(a0)
    80003ac8:	c5b5                	beqz	a1,80003b34 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003aca:	00092503          	lw	a0,0(s2)
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	bda080e7          	jalr	-1062(ra) # 800036a8 <bread>
    80003ad6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ad8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003adc:	02049713          	slli	a4,s1,0x20
    80003ae0:	01e75593          	srli	a1,a4,0x1e
    80003ae4:	00b784b3          	add	s1,a5,a1
    80003ae8:	0004a983          	lw	s3,0(s1)
    80003aec:	04098e63          	beqz	s3,80003b48 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003af0:	8552                	mv	a0,s4
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	ce6080e7          	jalr	-794(ra) # 800037d8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003afa:	854e                	mv	a0,s3
    80003afc:	70a2                	ld	ra,40(sp)
    80003afe:	7402                	ld	s0,32(sp)
    80003b00:	64e2                	ld	s1,24(sp)
    80003b02:	6942                	ld	s2,16(sp)
    80003b04:	69a2                	ld	s3,8(sp)
    80003b06:	6a02                	ld	s4,0(sp)
    80003b08:	6145                	addi	sp,sp,48
    80003b0a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b0c:	02059793          	slli	a5,a1,0x20
    80003b10:	01e7d593          	srli	a1,a5,0x1e
    80003b14:	00b504b3          	add	s1,a0,a1
    80003b18:	0504a983          	lw	s3,80(s1)
    80003b1c:	fc099fe3          	bnez	s3,80003afa <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b20:	4108                	lw	a0,0(a0)
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	e48080e7          	jalr	-440(ra) # 8000396a <balloc>
    80003b2a:	0005099b          	sext.w	s3,a0
    80003b2e:	0534a823          	sw	s3,80(s1)
    80003b32:	b7e1                	j	80003afa <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b34:	4108                	lw	a0,0(a0)
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	e34080e7          	jalr	-460(ra) # 8000396a <balloc>
    80003b3e:	0005059b          	sext.w	a1,a0
    80003b42:	08b92023          	sw	a1,128(s2)
    80003b46:	b751                	j	80003aca <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b48:	00092503          	lw	a0,0(s2)
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	e1e080e7          	jalr	-482(ra) # 8000396a <balloc>
    80003b54:	0005099b          	sext.w	s3,a0
    80003b58:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b5c:	8552                	mv	a0,s4
    80003b5e:	00001097          	auipc	ra,0x1
    80003b62:	20e080e7          	jalr	526(ra) # 80004d6c <log_write>
    80003b66:	b769                	j	80003af0 <bmap+0x54>
  panic("bmap: out of range");
    80003b68:	00005517          	auipc	a0,0x5
    80003b6c:	c5050513          	addi	a0,a0,-944 # 800087b8 <syscalls+0x118>
    80003b70:	ffffd097          	auipc	ra,0xffffd
    80003b74:	9ba080e7          	jalr	-1606(ra) # 8000052a <panic>

0000000080003b78 <iget>:
{
    80003b78:	7179                	addi	sp,sp,-48
    80003b7a:	f406                	sd	ra,40(sp)
    80003b7c:	f022                	sd	s0,32(sp)
    80003b7e:	ec26                	sd	s1,24(sp)
    80003b80:	e84a                	sd	s2,16(sp)
    80003b82:	e44e                	sd	s3,8(sp)
    80003b84:	e052                	sd	s4,0(sp)
    80003b86:	1800                	addi	s0,sp,48
    80003b88:	89aa                	mv	s3,a0
    80003b8a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b8c:	00024517          	auipc	a0,0x24
    80003b90:	03c50513          	addi	a0,a0,60 # 80027bc8 <itable>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	02e080e7          	jalr	46(ra) # 80000bc2 <acquire>
  empty = 0;
    80003b9c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b9e:	00024497          	auipc	s1,0x24
    80003ba2:	04248493          	addi	s1,s1,66 # 80027be0 <itable+0x18>
    80003ba6:	00026697          	auipc	a3,0x26
    80003baa:	aca68693          	addi	a3,a3,-1334 # 80029670 <log>
    80003bae:	a039                	j	80003bbc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bb0:	02090b63          	beqz	s2,80003be6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bb4:	08848493          	addi	s1,s1,136
    80003bb8:	02d48a63          	beq	s1,a3,80003bec <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bbc:	449c                	lw	a5,8(s1)
    80003bbe:	fef059e3          	blez	a5,80003bb0 <iget+0x38>
    80003bc2:	4098                	lw	a4,0(s1)
    80003bc4:	ff3716e3          	bne	a4,s3,80003bb0 <iget+0x38>
    80003bc8:	40d8                	lw	a4,4(s1)
    80003bca:	ff4713e3          	bne	a4,s4,80003bb0 <iget+0x38>
      ip->ref++;
    80003bce:	2785                	addiw	a5,a5,1
    80003bd0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bd2:	00024517          	auipc	a0,0x24
    80003bd6:	ff650513          	addi	a0,a0,-10 # 80027bc8 <itable>
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	0ae080e7          	jalr	174(ra) # 80000c88 <release>
      return ip;
    80003be2:	8926                	mv	s2,s1
    80003be4:	a03d                	j	80003c12 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003be6:	f7f9                	bnez	a5,80003bb4 <iget+0x3c>
    80003be8:	8926                	mv	s2,s1
    80003bea:	b7e9                	j	80003bb4 <iget+0x3c>
  if(empty == 0)
    80003bec:	02090c63          	beqz	s2,80003c24 <iget+0xac>
  ip->dev = dev;
    80003bf0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003bf4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003bf8:	4785                	li	a5,1
    80003bfa:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003bfe:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c02:	00024517          	auipc	a0,0x24
    80003c06:	fc650513          	addi	a0,a0,-58 # 80027bc8 <itable>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	07e080e7          	jalr	126(ra) # 80000c88 <release>
}
    80003c12:	854a                	mv	a0,s2
    80003c14:	70a2                	ld	ra,40(sp)
    80003c16:	7402                	ld	s0,32(sp)
    80003c18:	64e2                	ld	s1,24(sp)
    80003c1a:	6942                	ld	s2,16(sp)
    80003c1c:	69a2                	ld	s3,8(sp)
    80003c1e:	6a02                	ld	s4,0(sp)
    80003c20:	6145                	addi	sp,sp,48
    80003c22:	8082                	ret
    panic("iget: no inodes");
    80003c24:	00005517          	auipc	a0,0x5
    80003c28:	bac50513          	addi	a0,a0,-1108 # 800087d0 <syscalls+0x130>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	8fe080e7          	jalr	-1794(ra) # 8000052a <panic>

0000000080003c34 <fsinit>:
fsinit(int dev) {
    80003c34:	7179                	addi	sp,sp,-48
    80003c36:	f406                	sd	ra,40(sp)
    80003c38:	f022                	sd	s0,32(sp)
    80003c3a:	ec26                	sd	s1,24(sp)
    80003c3c:	e84a                	sd	s2,16(sp)
    80003c3e:	e44e                	sd	s3,8(sp)
    80003c40:	1800                	addi	s0,sp,48
    80003c42:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c44:	4585                	li	a1,1
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	a62080e7          	jalr	-1438(ra) # 800036a8 <bread>
    80003c4e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c50:	00024997          	auipc	s3,0x24
    80003c54:	f5898993          	addi	s3,s3,-168 # 80027ba8 <sb>
    80003c58:	02000613          	li	a2,32
    80003c5c:	05850593          	addi	a1,a0,88
    80003c60:	854e                	mv	a0,s3
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	0ca080e7          	jalr	202(ra) # 80000d2c <memmove>
  brelse(bp);
    80003c6a:	8526                	mv	a0,s1
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	b6c080e7          	jalr	-1172(ra) # 800037d8 <brelse>
  if(sb.magic != FSMAGIC)
    80003c74:	0009a703          	lw	a4,0(s3)
    80003c78:	102037b7          	lui	a5,0x10203
    80003c7c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c80:	02f71263          	bne	a4,a5,80003ca4 <fsinit+0x70>
  initlog(dev, &sb);
    80003c84:	00024597          	auipc	a1,0x24
    80003c88:	f2458593          	addi	a1,a1,-220 # 80027ba8 <sb>
    80003c8c:	854a                	mv	a0,s2
    80003c8e:	00001097          	auipc	ra,0x1
    80003c92:	e60080e7          	jalr	-416(ra) # 80004aee <initlog>
}
    80003c96:	70a2                	ld	ra,40(sp)
    80003c98:	7402                	ld	s0,32(sp)
    80003c9a:	64e2                	ld	s1,24(sp)
    80003c9c:	6942                	ld	s2,16(sp)
    80003c9e:	69a2                	ld	s3,8(sp)
    80003ca0:	6145                	addi	sp,sp,48
    80003ca2:	8082                	ret
    panic("invalid file system");
    80003ca4:	00005517          	auipc	a0,0x5
    80003ca8:	b3c50513          	addi	a0,a0,-1220 # 800087e0 <syscalls+0x140>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	87e080e7          	jalr	-1922(ra) # 8000052a <panic>

0000000080003cb4 <iinit>:
{
    80003cb4:	7179                	addi	sp,sp,-48
    80003cb6:	f406                	sd	ra,40(sp)
    80003cb8:	f022                	sd	s0,32(sp)
    80003cba:	ec26                	sd	s1,24(sp)
    80003cbc:	e84a                	sd	s2,16(sp)
    80003cbe:	e44e                	sd	s3,8(sp)
    80003cc0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cc2:	00005597          	auipc	a1,0x5
    80003cc6:	b3658593          	addi	a1,a1,-1226 # 800087f8 <syscalls+0x158>
    80003cca:	00024517          	auipc	a0,0x24
    80003cce:	efe50513          	addi	a0,a0,-258 # 80027bc8 <itable>
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	e60080e7          	jalr	-416(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003cda:	00024497          	auipc	s1,0x24
    80003cde:	f1648493          	addi	s1,s1,-234 # 80027bf0 <itable+0x28>
    80003ce2:	00026997          	auipc	s3,0x26
    80003ce6:	99e98993          	addi	s3,s3,-1634 # 80029680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003cea:	00005917          	auipc	s2,0x5
    80003cee:	b1690913          	addi	s2,s2,-1258 # 80008800 <syscalls+0x160>
    80003cf2:	85ca                	mv	a1,s2
    80003cf4:	8526                	mv	a0,s1
    80003cf6:	00001097          	auipc	ra,0x1
    80003cfa:	15c080e7          	jalr	348(ra) # 80004e52 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003cfe:	08848493          	addi	s1,s1,136
    80003d02:	ff3498e3          	bne	s1,s3,80003cf2 <iinit+0x3e>
}
    80003d06:	70a2                	ld	ra,40(sp)
    80003d08:	7402                	ld	s0,32(sp)
    80003d0a:	64e2                	ld	s1,24(sp)
    80003d0c:	6942                	ld	s2,16(sp)
    80003d0e:	69a2                	ld	s3,8(sp)
    80003d10:	6145                	addi	sp,sp,48
    80003d12:	8082                	ret

0000000080003d14 <ialloc>:
{
    80003d14:	715d                	addi	sp,sp,-80
    80003d16:	e486                	sd	ra,72(sp)
    80003d18:	e0a2                	sd	s0,64(sp)
    80003d1a:	fc26                	sd	s1,56(sp)
    80003d1c:	f84a                	sd	s2,48(sp)
    80003d1e:	f44e                	sd	s3,40(sp)
    80003d20:	f052                	sd	s4,32(sp)
    80003d22:	ec56                	sd	s5,24(sp)
    80003d24:	e85a                	sd	s6,16(sp)
    80003d26:	e45e                	sd	s7,8(sp)
    80003d28:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d2a:	00024717          	auipc	a4,0x24
    80003d2e:	e8a72703          	lw	a4,-374(a4) # 80027bb4 <sb+0xc>
    80003d32:	4785                	li	a5,1
    80003d34:	04e7fa63          	bgeu	a5,a4,80003d88 <ialloc+0x74>
    80003d38:	8aaa                	mv	s5,a0
    80003d3a:	8bae                	mv	s7,a1
    80003d3c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d3e:	00024a17          	auipc	s4,0x24
    80003d42:	e6aa0a13          	addi	s4,s4,-406 # 80027ba8 <sb>
    80003d46:	00048b1b          	sext.w	s6,s1
    80003d4a:	0044d793          	srli	a5,s1,0x4
    80003d4e:	018a2583          	lw	a1,24(s4)
    80003d52:	9dbd                	addw	a1,a1,a5
    80003d54:	8556                	mv	a0,s5
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	952080e7          	jalr	-1710(ra) # 800036a8 <bread>
    80003d5e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d60:	05850993          	addi	s3,a0,88
    80003d64:	00f4f793          	andi	a5,s1,15
    80003d68:	079a                	slli	a5,a5,0x6
    80003d6a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d6c:	00099783          	lh	a5,0(s3)
    80003d70:	c785                	beqz	a5,80003d98 <ialloc+0x84>
    brelse(bp);
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	a66080e7          	jalr	-1434(ra) # 800037d8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d7a:	0485                	addi	s1,s1,1
    80003d7c:	00ca2703          	lw	a4,12(s4)
    80003d80:	0004879b          	sext.w	a5,s1
    80003d84:	fce7e1e3          	bltu	a5,a4,80003d46 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d88:	00005517          	auipc	a0,0x5
    80003d8c:	a8050513          	addi	a0,a0,-1408 # 80008808 <syscalls+0x168>
    80003d90:	ffffc097          	auipc	ra,0xffffc
    80003d94:	79a080e7          	jalr	1946(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003d98:	04000613          	li	a2,64
    80003d9c:	4581                	li	a1,0
    80003d9e:	854e                	mv	a0,s3
    80003da0:	ffffd097          	auipc	ra,0xffffd
    80003da4:	f30080e7          	jalr	-208(ra) # 80000cd0 <memset>
      dip->type = type;
    80003da8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dac:	854a                	mv	a0,s2
    80003dae:	00001097          	auipc	ra,0x1
    80003db2:	fbe080e7          	jalr	-66(ra) # 80004d6c <log_write>
      brelse(bp);
    80003db6:	854a                	mv	a0,s2
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	a20080e7          	jalr	-1504(ra) # 800037d8 <brelse>
      return iget(dev, inum);
    80003dc0:	85da                	mv	a1,s6
    80003dc2:	8556                	mv	a0,s5
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	db4080e7          	jalr	-588(ra) # 80003b78 <iget>
}
    80003dcc:	60a6                	ld	ra,72(sp)
    80003dce:	6406                	ld	s0,64(sp)
    80003dd0:	74e2                	ld	s1,56(sp)
    80003dd2:	7942                	ld	s2,48(sp)
    80003dd4:	79a2                	ld	s3,40(sp)
    80003dd6:	7a02                	ld	s4,32(sp)
    80003dd8:	6ae2                	ld	s5,24(sp)
    80003dda:	6b42                	ld	s6,16(sp)
    80003ddc:	6ba2                	ld	s7,8(sp)
    80003dde:	6161                	addi	sp,sp,80
    80003de0:	8082                	ret

0000000080003de2 <iupdate>:
{
    80003de2:	1101                	addi	sp,sp,-32
    80003de4:	ec06                	sd	ra,24(sp)
    80003de6:	e822                	sd	s0,16(sp)
    80003de8:	e426                	sd	s1,8(sp)
    80003dea:	e04a                	sd	s2,0(sp)
    80003dec:	1000                	addi	s0,sp,32
    80003dee:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003df0:	415c                	lw	a5,4(a0)
    80003df2:	0047d79b          	srliw	a5,a5,0x4
    80003df6:	00024597          	auipc	a1,0x24
    80003dfa:	dca5a583          	lw	a1,-566(a1) # 80027bc0 <sb+0x18>
    80003dfe:	9dbd                	addw	a1,a1,a5
    80003e00:	4108                	lw	a0,0(a0)
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	8a6080e7          	jalr	-1882(ra) # 800036a8 <bread>
    80003e0a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e0c:	05850793          	addi	a5,a0,88
    80003e10:	40c8                	lw	a0,4(s1)
    80003e12:	893d                	andi	a0,a0,15
    80003e14:	051a                	slli	a0,a0,0x6
    80003e16:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e18:	04449703          	lh	a4,68(s1)
    80003e1c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e20:	04649703          	lh	a4,70(s1)
    80003e24:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e28:	04849703          	lh	a4,72(s1)
    80003e2c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e30:	04a49703          	lh	a4,74(s1)
    80003e34:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e38:	44f8                	lw	a4,76(s1)
    80003e3a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e3c:	03400613          	li	a2,52
    80003e40:	05048593          	addi	a1,s1,80
    80003e44:	0531                	addi	a0,a0,12
    80003e46:	ffffd097          	auipc	ra,0xffffd
    80003e4a:	ee6080e7          	jalr	-282(ra) # 80000d2c <memmove>
  log_write(bp);
    80003e4e:	854a                	mv	a0,s2
    80003e50:	00001097          	auipc	ra,0x1
    80003e54:	f1c080e7          	jalr	-228(ra) # 80004d6c <log_write>
  brelse(bp);
    80003e58:	854a                	mv	a0,s2
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	97e080e7          	jalr	-1666(ra) # 800037d8 <brelse>
}
    80003e62:	60e2                	ld	ra,24(sp)
    80003e64:	6442                	ld	s0,16(sp)
    80003e66:	64a2                	ld	s1,8(sp)
    80003e68:	6902                	ld	s2,0(sp)
    80003e6a:	6105                	addi	sp,sp,32
    80003e6c:	8082                	ret

0000000080003e6e <idup>:
{
    80003e6e:	1101                	addi	sp,sp,-32
    80003e70:	ec06                	sd	ra,24(sp)
    80003e72:	e822                	sd	s0,16(sp)
    80003e74:	e426                	sd	s1,8(sp)
    80003e76:	1000                	addi	s0,sp,32
    80003e78:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e7a:	00024517          	auipc	a0,0x24
    80003e7e:	d4e50513          	addi	a0,a0,-690 # 80027bc8 <itable>
    80003e82:	ffffd097          	auipc	ra,0xffffd
    80003e86:	d40080e7          	jalr	-704(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003e8a:	449c                	lw	a5,8(s1)
    80003e8c:	2785                	addiw	a5,a5,1
    80003e8e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e90:	00024517          	auipc	a0,0x24
    80003e94:	d3850513          	addi	a0,a0,-712 # 80027bc8 <itable>
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	df0080e7          	jalr	-528(ra) # 80000c88 <release>
}
    80003ea0:	8526                	mv	a0,s1
    80003ea2:	60e2                	ld	ra,24(sp)
    80003ea4:	6442                	ld	s0,16(sp)
    80003ea6:	64a2                	ld	s1,8(sp)
    80003ea8:	6105                	addi	sp,sp,32
    80003eaa:	8082                	ret

0000000080003eac <ilock>:
{
    80003eac:	1101                	addi	sp,sp,-32
    80003eae:	ec06                	sd	ra,24(sp)
    80003eb0:	e822                	sd	s0,16(sp)
    80003eb2:	e426                	sd	s1,8(sp)
    80003eb4:	e04a                	sd	s2,0(sp)
    80003eb6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003eb8:	c115                	beqz	a0,80003edc <ilock+0x30>
    80003eba:	84aa                	mv	s1,a0
    80003ebc:	451c                	lw	a5,8(a0)
    80003ebe:	00f05f63          	blez	a5,80003edc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ec2:	0541                	addi	a0,a0,16
    80003ec4:	00001097          	auipc	ra,0x1
    80003ec8:	fc8080e7          	jalr	-56(ra) # 80004e8c <acquiresleep>
  if(ip->valid == 0){
    80003ecc:	40bc                	lw	a5,64(s1)
    80003ece:	cf99                	beqz	a5,80003eec <ilock+0x40>
}
    80003ed0:	60e2                	ld	ra,24(sp)
    80003ed2:	6442                	ld	s0,16(sp)
    80003ed4:	64a2                	ld	s1,8(sp)
    80003ed6:	6902                	ld	s2,0(sp)
    80003ed8:	6105                	addi	sp,sp,32
    80003eda:	8082                	ret
    panic("ilock");
    80003edc:	00005517          	auipc	a0,0x5
    80003ee0:	94450513          	addi	a0,a0,-1724 # 80008820 <syscalls+0x180>
    80003ee4:	ffffc097          	auipc	ra,0xffffc
    80003ee8:	646080e7          	jalr	1606(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003eec:	40dc                	lw	a5,4(s1)
    80003eee:	0047d79b          	srliw	a5,a5,0x4
    80003ef2:	00024597          	auipc	a1,0x24
    80003ef6:	cce5a583          	lw	a1,-818(a1) # 80027bc0 <sb+0x18>
    80003efa:	9dbd                	addw	a1,a1,a5
    80003efc:	4088                	lw	a0,0(s1)
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	7aa080e7          	jalr	1962(ra) # 800036a8 <bread>
    80003f06:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f08:	05850593          	addi	a1,a0,88
    80003f0c:	40dc                	lw	a5,4(s1)
    80003f0e:	8bbd                	andi	a5,a5,15
    80003f10:	079a                	slli	a5,a5,0x6
    80003f12:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f14:	00059783          	lh	a5,0(a1)
    80003f18:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f1c:	00259783          	lh	a5,2(a1)
    80003f20:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f24:	00459783          	lh	a5,4(a1)
    80003f28:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f2c:	00659783          	lh	a5,6(a1)
    80003f30:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f34:	459c                	lw	a5,8(a1)
    80003f36:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f38:	03400613          	li	a2,52
    80003f3c:	05b1                	addi	a1,a1,12
    80003f3e:	05048513          	addi	a0,s1,80
    80003f42:	ffffd097          	auipc	ra,0xffffd
    80003f46:	dea080e7          	jalr	-534(ra) # 80000d2c <memmove>
    brelse(bp);
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	88c080e7          	jalr	-1908(ra) # 800037d8 <brelse>
    ip->valid = 1;
    80003f54:	4785                	li	a5,1
    80003f56:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f58:	04449783          	lh	a5,68(s1)
    80003f5c:	fbb5                	bnez	a5,80003ed0 <ilock+0x24>
      panic("ilock: no type");
    80003f5e:	00005517          	auipc	a0,0x5
    80003f62:	8ca50513          	addi	a0,a0,-1846 # 80008828 <syscalls+0x188>
    80003f66:	ffffc097          	auipc	ra,0xffffc
    80003f6a:	5c4080e7          	jalr	1476(ra) # 8000052a <panic>

0000000080003f6e <iunlock>:
{
    80003f6e:	1101                	addi	sp,sp,-32
    80003f70:	ec06                	sd	ra,24(sp)
    80003f72:	e822                	sd	s0,16(sp)
    80003f74:	e426                	sd	s1,8(sp)
    80003f76:	e04a                	sd	s2,0(sp)
    80003f78:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f7a:	c905                	beqz	a0,80003faa <iunlock+0x3c>
    80003f7c:	84aa                	mv	s1,a0
    80003f7e:	01050913          	addi	s2,a0,16
    80003f82:	854a                	mv	a0,s2
    80003f84:	00001097          	auipc	ra,0x1
    80003f88:	fa2080e7          	jalr	-94(ra) # 80004f26 <holdingsleep>
    80003f8c:	cd19                	beqz	a0,80003faa <iunlock+0x3c>
    80003f8e:	449c                	lw	a5,8(s1)
    80003f90:	00f05d63          	blez	a5,80003faa <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f94:	854a                	mv	a0,s2
    80003f96:	00001097          	auipc	ra,0x1
    80003f9a:	f4c080e7          	jalr	-180(ra) # 80004ee2 <releasesleep>
}
    80003f9e:	60e2                	ld	ra,24(sp)
    80003fa0:	6442                	ld	s0,16(sp)
    80003fa2:	64a2                	ld	s1,8(sp)
    80003fa4:	6902                	ld	s2,0(sp)
    80003fa6:	6105                	addi	sp,sp,32
    80003fa8:	8082                	ret
    panic("iunlock");
    80003faa:	00005517          	auipc	a0,0x5
    80003fae:	88e50513          	addi	a0,a0,-1906 # 80008838 <syscalls+0x198>
    80003fb2:	ffffc097          	auipc	ra,0xffffc
    80003fb6:	578080e7          	jalr	1400(ra) # 8000052a <panic>

0000000080003fba <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fba:	7179                	addi	sp,sp,-48
    80003fbc:	f406                	sd	ra,40(sp)
    80003fbe:	f022                	sd	s0,32(sp)
    80003fc0:	ec26                	sd	s1,24(sp)
    80003fc2:	e84a                	sd	s2,16(sp)
    80003fc4:	e44e                	sd	s3,8(sp)
    80003fc6:	e052                	sd	s4,0(sp)
    80003fc8:	1800                	addi	s0,sp,48
    80003fca:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fcc:	05050493          	addi	s1,a0,80
    80003fd0:	08050913          	addi	s2,a0,128
    80003fd4:	a021                	j	80003fdc <itrunc+0x22>
    80003fd6:	0491                	addi	s1,s1,4
    80003fd8:	01248d63          	beq	s1,s2,80003ff2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003fdc:	408c                	lw	a1,0(s1)
    80003fde:	dde5                	beqz	a1,80003fd6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003fe0:	0009a503          	lw	a0,0(s3)
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	90a080e7          	jalr	-1782(ra) # 800038ee <bfree>
      ip->addrs[i] = 0;
    80003fec:	0004a023          	sw	zero,0(s1)
    80003ff0:	b7dd                	j	80003fd6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ff2:	0809a583          	lw	a1,128(s3)
    80003ff6:	e185                	bnez	a1,80004016 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ff8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ffc:	854e                	mv	a0,s3
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	de4080e7          	jalr	-540(ra) # 80003de2 <iupdate>
}
    80004006:	70a2                	ld	ra,40(sp)
    80004008:	7402                	ld	s0,32(sp)
    8000400a:	64e2                	ld	s1,24(sp)
    8000400c:	6942                	ld	s2,16(sp)
    8000400e:	69a2                	ld	s3,8(sp)
    80004010:	6a02                	ld	s4,0(sp)
    80004012:	6145                	addi	sp,sp,48
    80004014:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004016:	0009a503          	lw	a0,0(s3)
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	68e080e7          	jalr	1678(ra) # 800036a8 <bread>
    80004022:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004024:	05850493          	addi	s1,a0,88
    80004028:	45850913          	addi	s2,a0,1112
    8000402c:	a021                	j	80004034 <itrunc+0x7a>
    8000402e:	0491                	addi	s1,s1,4
    80004030:	01248b63          	beq	s1,s2,80004046 <itrunc+0x8c>
      if(a[j])
    80004034:	408c                	lw	a1,0(s1)
    80004036:	dde5                	beqz	a1,8000402e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004038:	0009a503          	lw	a0,0(s3)
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	8b2080e7          	jalr	-1870(ra) # 800038ee <bfree>
    80004044:	b7ed                	j	8000402e <itrunc+0x74>
    brelse(bp);
    80004046:	8552                	mv	a0,s4
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	790080e7          	jalr	1936(ra) # 800037d8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004050:	0809a583          	lw	a1,128(s3)
    80004054:	0009a503          	lw	a0,0(s3)
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	896080e7          	jalr	-1898(ra) # 800038ee <bfree>
    ip->addrs[NDIRECT] = 0;
    80004060:	0809a023          	sw	zero,128(s3)
    80004064:	bf51                	j	80003ff8 <itrunc+0x3e>

0000000080004066 <iput>:
{
    80004066:	1101                	addi	sp,sp,-32
    80004068:	ec06                	sd	ra,24(sp)
    8000406a:	e822                	sd	s0,16(sp)
    8000406c:	e426                	sd	s1,8(sp)
    8000406e:	e04a                	sd	s2,0(sp)
    80004070:	1000                	addi	s0,sp,32
    80004072:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004074:	00024517          	auipc	a0,0x24
    80004078:	b5450513          	addi	a0,a0,-1196 # 80027bc8 <itable>
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	b46080e7          	jalr	-1210(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004084:	4498                	lw	a4,8(s1)
    80004086:	4785                	li	a5,1
    80004088:	02f70363          	beq	a4,a5,800040ae <iput+0x48>
  ip->ref--;
    8000408c:	449c                	lw	a5,8(s1)
    8000408e:	37fd                	addiw	a5,a5,-1
    80004090:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004092:	00024517          	auipc	a0,0x24
    80004096:	b3650513          	addi	a0,a0,-1226 # 80027bc8 <itable>
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	bee080e7          	jalr	-1042(ra) # 80000c88 <release>
}
    800040a2:	60e2                	ld	ra,24(sp)
    800040a4:	6442                	ld	s0,16(sp)
    800040a6:	64a2                	ld	s1,8(sp)
    800040a8:	6902                	ld	s2,0(sp)
    800040aa:	6105                	addi	sp,sp,32
    800040ac:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040ae:	40bc                	lw	a5,64(s1)
    800040b0:	dff1                	beqz	a5,8000408c <iput+0x26>
    800040b2:	04a49783          	lh	a5,74(s1)
    800040b6:	fbf9                	bnez	a5,8000408c <iput+0x26>
    acquiresleep(&ip->lock);
    800040b8:	01048913          	addi	s2,s1,16
    800040bc:	854a                	mv	a0,s2
    800040be:	00001097          	auipc	ra,0x1
    800040c2:	dce080e7          	jalr	-562(ra) # 80004e8c <acquiresleep>
    release(&itable.lock);
    800040c6:	00024517          	auipc	a0,0x24
    800040ca:	b0250513          	addi	a0,a0,-1278 # 80027bc8 <itable>
    800040ce:	ffffd097          	auipc	ra,0xffffd
    800040d2:	bba080e7          	jalr	-1094(ra) # 80000c88 <release>
    itrunc(ip);
    800040d6:	8526                	mv	a0,s1
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	ee2080e7          	jalr	-286(ra) # 80003fba <itrunc>
    ip->type = 0;
    800040e0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800040e4:	8526                	mv	a0,s1
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	cfc080e7          	jalr	-772(ra) # 80003de2 <iupdate>
    ip->valid = 0;
    800040ee:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800040f2:	854a                	mv	a0,s2
    800040f4:	00001097          	auipc	ra,0x1
    800040f8:	dee080e7          	jalr	-530(ra) # 80004ee2 <releasesleep>
    acquire(&itable.lock);
    800040fc:	00024517          	auipc	a0,0x24
    80004100:	acc50513          	addi	a0,a0,-1332 # 80027bc8 <itable>
    80004104:	ffffd097          	auipc	ra,0xffffd
    80004108:	abe080e7          	jalr	-1346(ra) # 80000bc2 <acquire>
    8000410c:	b741                	j	8000408c <iput+0x26>

000000008000410e <iunlockput>:
{
    8000410e:	1101                	addi	sp,sp,-32
    80004110:	ec06                	sd	ra,24(sp)
    80004112:	e822                	sd	s0,16(sp)
    80004114:	e426                	sd	s1,8(sp)
    80004116:	1000                	addi	s0,sp,32
    80004118:	84aa                	mv	s1,a0
  iunlock(ip);
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	e54080e7          	jalr	-428(ra) # 80003f6e <iunlock>
  iput(ip);
    80004122:	8526                	mv	a0,s1
    80004124:	00000097          	auipc	ra,0x0
    80004128:	f42080e7          	jalr	-190(ra) # 80004066 <iput>
}
    8000412c:	60e2                	ld	ra,24(sp)
    8000412e:	6442                	ld	s0,16(sp)
    80004130:	64a2                	ld	s1,8(sp)
    80004132:	6105                	addi	sp,sp,32
    80004134:	8082                	ret

0000000080004136 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004136:	1141                	addi	sp,sp,-16
    80004138:	e422                	sd	s0,8(sp)
    8000413a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000413c:	411c                	lw	a5,0(a0)
    8000413e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004140:	415c                	lw	a5,4(a0)
    80004142:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004144:	04451783          	lh	a5,68(a0)
    80004148:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000414c:	04a51783          	lh	a5,74(a0)
    80004150:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004154:	04c56783          	lwu	a5,76(a0)
    80004158:	e99c                	sd	a5,16(a1)
}
    8000415a:	6422                	ld	s0,8(sp)
    8000415c:	0141                	addi	sp,sp,16
    8000415e:	8082                	ret

0000000080004160 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004160:	457c                	lw	a5,76(a0)
    80004162:	0ed7e963          	bltu	a5,a3,80004254 <readi+0xf4>
{
    80004166:	7159                	addi	sp,sp,-112
    80004168:	f486                	sd	ra,104(sp)
    8000416a:	f0a2                	sd	s0,96(sp)
    8000416c:	eca6                	sd	s1,88(sp)
    8000416e:	e8ca                	sd	s2,80(sp)
    80004170:	e4ce                	sd	s3,72(sp)
    80004172:	e0d2                	sd	s4,64(sp)
    80004174:	fc56                	sd	s5,56(sp)
    80004176:	f85a                	sd	s6,48(sp)
    80004178:	f45e                	sd	s7,40(sp)
    8000417a:	f062                	sd	s8,32(sp)
    8000417c:	ec66                	sd	s9,24(sp)
    8000417e:	e86a                	sd	s10,16(sp)
    80004180:	e46e                	sd	s11,8(sp)
    80004182:	1880                	addi	s0,sp,112
    80004184:	8baa                	mv	s7,a0
    80004186:	8c2e                	mv	s8,a1
    80004188:	8ab2                	mv	s5,a2
    8000418a:	84b6                	mv	s1,a3
    8000418c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000418e:	9f35                	addw	a4,a4,a3
    return 0;
    80004190:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004192:	0ad76063          	bltu	a4,a3,80004232 <readi+0xd2>
  if(off + n > ip->size)
    80004196:	00e7f463          	bgeu	a5,a4,8000419e <readi+0x3e>
    n = ip->size - off;
    8000419a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000419e:	0a0b0963          	beqz	s6,80004250 <readi+0xf0>
    800041a2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041a4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041a8:	5cfd                	li	s9,-1
    800041aa:	a82d                	j	800041e4 <readi+0x84>
    800041ac:	020a1d93          	slli	s11,s4,0x20
    800041b0:	020ddd93          	srli	s11,s11,0x20
    800041b4:	05890793          	addi	a5,s2,88
    800041b8:	86ee                	mv	a3,s11
    800041ba:	963e                	add	a2,a2,a5
    800041bc:	85d6                	mv	a1,s5
    800041be:	8562                	mv	a0,s8
    800041c0:	ffffe097          	auipc	ra,0xffffe
    800041c4:	f1a080e7          	jalr	-230(ra) # 800020da <either_copyout>
    800041c8:	05950d63          	beq	a0,s9,80004222 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041cc:	854a                	mv	a0,s2
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	60a080e7          	jalr	1546(ra) # 800037d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041d6:	013a09bb          	addw	s3,s4,s3
    800041da:	009a04bb          	addw	s1,s4,s1
    800041de:	9aee                	add	s5,s5,s11
    800041e0:	0569f763          	bgeu	s3,s6,8000422e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800041e4:	000ba903          	lw	s2,0(s7)
    800041e8:	00a4d59b          	srliw	a1,s1,0xa
    800041ec:	855e                	mv	a0,s7
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	8ae080e7          	jalr	-1874(ra) # 80003a9c <bmap>
    800041f6:	0005059b          	sext.w	a1,a0
    800041fa:	854a                	mv	a0,s2
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	4ac080e7          	jalr	1196(ra) # 800036a8 <bread>
    80004204:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004206:	3ff4f613          	andi	a2,s1,1023
    8000420a:	40cd07bb          	subw	a5,s10,a2
    8000420e:	413b073b          	subw	a4,s6,s3
    80004212:	8a3e                	mv	s4,a5
    80004214:	2781                	sext.w	a5,a5
    80004216:	0007069b          	sext.w	a3,a4
    8000421a:	f8f6f9e3          	bgeu	a3,a5,800041ac <readi+0x4c>
    8000421e:	8a3a                	mv	s4,a4
    80004220:	b771                	j	800041ac <readi+0x4c>
      brelse(bp);
    80004222:	854a                	mv	a0,s2
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	5b4080e7          	jalr	1460(ra) # 800037d8 <brelse>
      tot = -1;
    8000422c:	59fd                	li	s3,-1
  }
  return tot;
    8000422e:	0009851b          	sext.w	a0,s3
}
    80004232:	70a6                	ld	ra,104(sp)
    80004234:	7406                	ld	s0,96(sp)
    80004236:	64e6                	ld	s1,88(sp)
    80004238:	6946                	ld	s2,80(sp)
    8000423a:	69a6                	ld	s3,72(sp)
    8000423c:	6a06                	ld	s4,64(sp)
    8000423e:	7ae2                	ld	s5,56(sp)
    80004240:	7b42                	ld	s6,48(sp)
    80004242:	7ba2                	ld	s7,40(sp)
    80004244:	7c02                	ld	s8,32(sp)
    80004246:	6ce2                	ld	s9,24(sp)
    80004248:	6d42                	ld	s10,16(sp)
    8000424a:	6da2                	ld	s11,8(sp)
    8000424c:	6165                	addi	sp,sp,112
    8000424e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004250:	89da                	mv	s3,s6
    80004252:	bff1                	j	8000422e <readi+0xce>
    return 0;
    80004254:	4501                	li	a0,0
}
    80004256:	8082                	ret

0000000080004258 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004258:	457c                	lw	a5,76(a0)
    8000425a:	10d7e863          	bltu	a5,a3,8000436a <writei+0x112>
{
    8000425e:	7159                	addi	sp,sp,-112
    80004260:	f486                	sd	ra,104(sp)
    80004262:	f0a2                	sd	s0,96(sp)
    80004264:	eca6                	sd	s1,88(sp)
    80004266:	e8ca                	sd	s2,80(sp)
    80004268:	e4ce                	sd	s3,72(sp)
    8000426a:	e0d2                	sd	s4,64(sp)
    8000426c:	fc56                	sd	s5,56(sp)
    8000426e:	f85a                	sd	s6,48(sp)
    80004270:	f45e                	sd	s7,40(sp)
    80004272:	f062                	sd	s8,32(sp)
    80004274:	ec66                	sd	s9,24(sp)
    80004276:	e86a                	sd	s10,16(sp)
    80004278:	e46e                	sd	s11,8(sp)
    8000427a:	1880                	addi	s0,sp,112
    8000427c:	8b2a                	mv	s6,a0
    8000427e:	8c2e                	mv	s8,a1
    80004280:	8ab2                	mv	s5,a2
    80004282:	8936                	mv	s2,a3
    80004284:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004286:	00e687bb          	addw	a5,a3,a4
    8000428a:	0ed7e263          	bltu	a5,a3,8000436e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000428e:	00043737          	lui	a4,0x43
    80004292:	0ef76063          	bltu	a4,a5,80004372 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004296:	0c0b8863          	beqz	s7,80004366 <writei+0x10e>
    8000429a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000429c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042a0:	5cfd                	li	s9,-1
    800042a2:	a091                	j	800042e6 <writei+0x8e>
    800042a4:	02099d93          	slli	s11,s3,0x20
    800042a8:	020ddd93          	srli	s11,s11,0x20
    800042ac:	05848793          	addi	a5,s1,88
    800042b0:	86ee                	mv	a3,s11
    800042b2:	8656                	mv	a2,s5
    800042b4:	85e2                	mv	a1,s8
    800042b6:	953e                	add	a0,a0,a5
    800042b8:	ffffe097          	auipc	ra,0xffffe
    800042bc:	e78080e7          	jalr	-392(ra) # 80002130 <either_copyin>
    800042c0:	07950263          	beq	a0,s9,80004324 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042c4:	8526                	mv	a0,s1
    800042c6:	00001097          	auipc	ra,0x1
    800042ca:	aa6080e7          	jalr	-1370(ra) # 80004d6c <log_write>
    brelse(bp);
    800042ce:	8526                	mv	a0,s1
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	508080e7          	jalr	1288(ra) # 800037d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042d8:	01498a3b          	addw	s4,s3,s4
    800042dc:	0129893b          	addw	s2,s3,s2
    800042e0:	9aee                	add	s5,s5,s11
    800042e2:	057a7663          	bgeu	s4,s7,8000432e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042e6:	000b2483          	lw	s1,0(s6)
    800042ea:	00a9559b          	srliw	a1,s2,0xa
    800042ee:	855a                	mv	a0,s6
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	7ac080e7          	jalr	1964(ra) # 80003a9c <bmap>
    800042f8:	0005059b          	sext.w	a1,a0
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	3aa080e7          	jalr	938(ra) # 800036a8 <bread>
    80004306:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004308:	3ff97513          	andi	a0,s2,1023
    8000430c:	40ad07bb          	subw	a5,s10,a0
    80004310:	414b873b          	subw	a4,s7,s4
    80004314:	89be                	mv	s3,a5
    80004316:	2781                	sext.w	a5,a5
    80004318:	0007069b          	sext.w	a3,a4
    8000431c:	f8f6f4e3          	bgeu	a3,a5,800042a4 <writei+0x4c>
    80004320:	89ba                	mv	s3,a4
    80004322:	b749                	j	800042a4 <writei+0x4c>
      brelse(bp);
    80004324:	8526                	mv	a0,s1
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	4b2080e7          	jalr	1202(ra) # 800037d8 <brelse>
  }

  if(off > ip->size)
    8000432e:	04cb2783          	lw	a5,76(s6)
    80004332:	0127f463          	bgeu	a5,s2,8000433a <writei+0xe2>
    ip->size = off;
    80004336:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000433a:	855a                	mv	a0,s6
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	aa6080e7          	jalr	-1370(ra) # 80003de2 <iupdate>

  return tot;
    80004344:	000a051b          	sext.w	a0,s4
}
    80004348:	70a6                	ld	ra,104(sp)
    8000434a:	7406                	ld	s0,96(sp)
    8000434c:	64e6                	ld	s1,88(sp)
    8000434e:	6946                	ld	s2,80(sp)
    80004350:	69a6                	ld	s3,72(sp)
    80004352:	6a06                	ld	s4,64(sp)
    80004354:	7ae2                	ld	s5,56(sp)
    80004356:	7b42                	ld	s6,48(sp)
    80004358:	7ba2                	ld	s7,40(sp)
    8000435a:	7c02                	ld	s8,32(sp)
    8000435c:	6ce2                	ld	s9,24(sp)
    8000435e:	6d42                	ld	s10,16(sp)
    80004360:	6da2                	ld	s11,8(sp)
    80004362:	6165                	addi	sp,sp,112
    80004364:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004366:	8a5e                	mv	s4,s7
    80004368:	bfc9                	j	8000433a <writei+0xe2>
    return -1;
    8000436a:	557d                	li	a0,-1
}
    8000436c:	8082                	ret
    return -1;
    8000436e:	557d                	li	a0,-1
    80004370:	bfe1                	j	80004348 <writei+0xf0>
    return -1;
    80004372:	557d                	li	a0,-1
    80004374:	bfd1                	j	80004348 <writei+0xf0>

0000000080004376 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004376:	1141                	addi	sp,sp,-16
    80004378:	e406                	sd	ra,8(sp)
    8000437a:	e022                	sd	s0,0(sp)
    8000437c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000437e:	4639                	li	a2,14
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	a28080e7          	jalr	-1496(ra) # 80000da8 <strncmp>
}
    80004388:	60a2                	ld	ra,8(sp)
    8000438a:	6402                	ld	s0,0(sp)
    8000438c:	0141                	addi	sp,sp,16
    8000438e:	8082                	ret

0000000080004390 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004390:	7139                	addi	sp,sp,-64
    80004392:	fc06                	sd	ra,56(sp)
    80004394:	f822                	sd	s0,48(sp)
    80004396:	f426                	sd	s1,40(sp)
    80004398:	f04a                	sd	s2,32(sp)
    8000439a:	ec4e                	sd	s3,24(sp)
    8000439c:	e852                	sd	s4,16(sp)
    8000439e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043a0:	04451703          	lh	a4,68(a0)
    800043a4:	4785                	li	a5,1
    800043a6:	00f71a63          	bne	a4,a5,800043ba <dirlookup+0x2a>
    800043aa:	892a                	mv	s2,a0
    800043ac:	89ae                	mv	s3,a1
    800043ae:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b0:	457c                	lw	a5,76(a0)
    800043b2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043b4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b6:	e79d                	bnez	a5,800043e4 <dirlookup+0x54>
    800043b8:	a8a5                	j	80004430 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043ba:	00004517          	auipc	a0,0x4
    800043be:	48650513          	addi	a0,a0,1158 # 80008840 <syscalls+0x1a0>
    800043c2:	ffffc097          	auipc	ra,0xffffc
    800043c6:	168080e7          	jalr	360(ra) # 8000052a <panic>
      panic("dirlookup read");
    800043ca:	00004517          	auipc	a0,0x4
    800043ce:	48e50513          	addi	a0,a0,1166 # 80008858 <syscalls+0x1b8>
    800043d2:	ffffc097          	auipc	ra,0xffffc
    800043d6:	158080e7          	jalr	344(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043da:	24c1                	addiw	s1,s1,16
    800043dc:	04c92783          	lw	a5,76(s2)
    800043e0:	04f4f763          	bgeu	s1,a5,8000442e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043e4:	4741                	li	a4,16
    800043e6:	86a6                	mv	a3,s1
    800043e8:	fc040613          	addi	a2,s0,-64
    800043ec:	4581                	li	a1,0
    800043ee:	854a                	mv	a0,s2
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	d70080e7          	jalr	-656(ra) # 80004160 <readi>
    800043f8:	47c1                	li	a5,16
    800043fa:	fcf518e3          	bne	a0,a5,800043ca <dirlookup+0x3a>
    if(de.inum == 0)
    800043fe:	fc045783          	lhu	a5,-64(s0)
    80004402:	dfe1                	beqz	a5,800043da <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004404:	fc240593          	addi	a1,s0,-62
    80004408:	854e                	mv	a0,s3
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	f6c080e7          	jalr	-148(ra) # 80004376 <namecmp>
    80004412:	f561                	bnez	a0,800043da <dirlookup+0x4a>
      if(poff)
    80004414:	000a0463          	beqz	s4,8000441c <dirlookup+0x8c>
        *poff = off;
    80004418:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000441c:	fc045583          	lhu	a1,-64(s0)
    80004420:	00092503          	lw	a0,0(s2)
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	754080e7          	jalr	1876(ra) # 80003b78 <iget>
    8000442c:	a011                	j	80004430 <dirlookup+0xa0>
  return 0;
    8000442e:	4501                	li	a0,0
}
    80004430:	70e2                	ld	ra,56(sp)
    80004432:	7442                	ld	s0,48(sp)
    80004434:	74a2                	ld	s1,40(sp)
    80004436:	7902                	ld	s2,32(sp)
    80004438:	69e2                	ld	s3,24(sp)
    8000443a:	6a42                	ld	s4,16(sp)
    8000443c:	6121                	addi	sp,sp,64
    8000443e:	8082                	ret

0000000080004440 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004440:	711d                	addi	sp,sp,-96
    80004442:	ec86                	sd	ra,88(sp)
    80004444:	e8a2                	sd	s0,80(sp)
    80004446:	e4a6                	sd	s1,72(sp)
    80004448:	e0ca                	sd	s2,64(sp)
    8000444a:	fc4e                	sd	s3,56(sp)
    8000444c:	f852                	sd	s4,48(sp)
    8000444e:	f456                	sd	s5,40(sp)
    80004450:	f05a                	sd	s6,32(sp)
    80004452:	ec5e                	sd	s7,24(sp)
    80004454:	e862                	sd	s8,16(sp)
    80004456:	e466                	sd	s9,8(sp)
    80004458:	1080                	addi	s0,sp,96
    8000445a:	84aa                	mv	s1,a0
    8000445c:	8aae                	mv	s5,a1
    8000445e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004460:	00054703          	lbu	a4,0(a0)
    80004464:	02f00793          	li	a5,47
    80004468:	02f70363          	beq	a4,a5,8000448e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000446c:	ffffd097          	auipc	ra,0xffffd
    80004470:	57a080e7          	jalr	1402(ra) # 800019e6 <myproc>
    80004474:	15053503          	ld	a0,336(a0)
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	9f6080e7          	jalr	-1546(ra) # 80003e6e <idup>
    80004480:	89aa                	mv	s3,a0
  while(*path == '/')
    80004482:	02f00913          	li	s2,47
  len = path - s;
    80004486:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004488:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000448a:	4b85                	li	s7,1
    8000448c:	a865                	j	80004544 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000448e:	4585                	li	a1,1
    80004490:	4505                	li	a0,1
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	6e6080e7          	jalr	1766(ra) # 80003b78 <iget>
    8000449a:	89aa                	mv	s3,a0
    8000449c:	b7dd                	j	80004482 <namex+0x42>
      iunlockput(ip);
    8000449e:	854e                	mv	a0,s3
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	c6e080e7          	jalr	-914(ra) # 8000410e <iunlockput>
      return 0;
    800044a8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044aa:	854e                	mv	a0,s3
    800044ac:	60e6                	ld	ra,88(sp)
    800044ae:	6446                	ld	s0,80(sp)
    800044b0:	64a6                	ld	s1,72(sp)
    800044b2:	6906                	ld	s2,64(sp)
    800044b4:	79e2                	ld	s3,56(sp)
    800044b6:	7a42                	ld	s4,48(sp)
    800044b8:	7aa2                	ld	s5,40(sp)
    800044ba:	7b02                	ld	s6,32(sp)
    800044bc:	6be2                	ld	s7,24(sp)
    800044be:	6c42                	ld	s8,16(sp)
    800044c0:	6ca2                	ld	s9,8(sp)
    800044c2:	6125                	addi	sp,sp,96
    800044c4:	8082                	ret
      iunlock(ip);
    800044c6:	854e                	mv	a0,s3
    800044c8:	00000097          	auipc	ra,0x0
    800044cc:	aa6080e7          	jalr	-1370(ra) # 80003f6e <iunlock>
      return ip;
    800044d0:	bfe9                	j	800044aa <namex+0x6a>
      iunlockput(ip);
    800044d2:	854e                	mv	a0,s3
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	c3a080e7          	jalr	-966(ra) # 8000410e <iunlockput>
      return 0;
    800044dc:	89e6                	mv	s3,s9
    800044de:	b7f1                	j	800044aa <namex+0x6a>
  len = path - s;
    800044e0:	40b48633          	sub	a2,s1,a1
    800044e4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800044e8:	099c5463          	bge	s8,s9,80004570 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800044ec:	4639                	li	a2,14
    800044ee:	8552                	mv	a0,s4
    800044f0:	ffffd097          	auipc	ra,0xffffd
    800044f4:	83c080e7          	jalr	-1988(ra) # 80000d2c <memmove>
  while(*path == '/')
    800044f8:	0004c783          	lbu	a5,0(s1)
    800044fc:	01279763          	bne	a5,s2,8000450a <namex+0xca>
    path++;
    80004500:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004502:	0004c783          	lbu	a5,0(s1)
    80004506:	ff278de3          	beq	a5,s2,80004500 <namex+0xc0>
    ilock(ip);
    8000450a:	854e                	mv	a0,s3
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	9a0080e7          	jalr	-1632(ra) # 80003eac <ilock>
    if(ip->type != T_DIR){
    80004514:	04499783          	lh	a5,68(s3)
    80004518:	f97793e3          	bne	a5,s7,8000449e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000451c:	000a8563          	beqz	s5,80004526 <namex+0xe6>
    80004520:	0004c783          	lbu	a5,0(s1)
    80004524:	d3cd                	beqz	a5,800044c6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004526:	865a                	mv	a2,s6
    80004528:	85d2                	mv	a1,s4
    8000452a:	854e                	mv	a0,s3
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	e64080e7          	jalr	-412(ra) # 80004390 <dirlookup>
    80004534:	8caa                	mv	s9,a0
    80004536:	dd51                	beqz	a0,800044d2 <namex+0x92>
    iunlockput(ip);
    80004538:	854e                	mv	a0,s3
    8000453a:	00000097          	auipc	ra,0x0
    8000453e:	bd4080e7          	jalr	-1068(ra) # 8000410e <iunlockput>
    ip = next;
    80004542:	89e6                	mv	s3,s9
  while(*path == '/')
    80004544:	0004c783          	lbu	a5,0(s1)
    80004548:	05279763          	bne	a5,s2,80004596 <namex+0x156>
    path++;
    8000454c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000454e:	0004c783          	lbu	a5,0(s1)
    80004552:	ff278de3          	beq	a5,s2,8000454c <namex+0x10c>
  if(*path == 0)
    80004556:	c79d                	beqz	a5,80004584 <namex+0x144>
    path++;
    80004558:	85a6                	mv	a1,s1
  len = path - s;
    8000455a:	8cda                	mv	s9,s6
    8000455c:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000455e:	01278963          	beq	a5,s2,80004570 <namex+0x130>
    80004562:	dfbd                	beqz	a5,800044e0 <namex+0xa0>
    path++;
    80004564:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004566:	0004c783          	lbu	a5,0(s1)
    8000456a:	ff279ce3          	bne	a5,s2,80004562 <namex+0x122>
    8000456e:	bf8d                	j	800044e0 <namex+0xa0>
    memmove(name, s, len);
    80004570:	2601                	sext.w	a2,a2
    80004572:	8552                	mv	a0,s4
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	7b8080e7          	jalr	1976(ra) # 80000d2c <memmove>
    name[len] = 0;
    8000457c:	9cd2                	add	s9,s9,s4
    8000457e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004582:	bf9d                	j	800044f8 <namex+0xb8>
  if(nameiparent){
    80004584:	f20a83e3          	beqz	s5,800044aa <namex+0x6a>
    iput(ip);
    80004588:	854e                	mv	a0,s3
    8000458a:	00000097          	auipc	ra,0x0
    8000458e:	adc080e7          	jalr	-1316(ra) # 80004066 <iput>
    return 0;
    80004592:	4981                	li	s3,0
    80004594:	bf19                	j	800044aa <namex+0x6a>
  if(*path == 0)
    80004596:	d7fd                	beqz	a5,80004584 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004598:	0004c783          	lbu	a5,0(s1)
    8000459c:	85a6                	mv	a1,s1
    8000459e:	b7d1                	j	80004562 <namex+0x122>

00000000800045a0 <dirlink>:
{
    800045a0:	7139                	addi	sp,sp,-64
    800045a2:	fc06                	sd	ra,56(sp)
    800045a4:	f822                	sd	s0,48(sp)
    800045a6:	f426                	sd	s1,40(sp)
    800045a8:	f04a                	sd	s2,32(sp)
    800045aa:	ec4e                	sd	s3,24(sp)
    800045ac:	e852                	sd	s4,16(sp)
    800045ae:	0080                	addi	s0,sp,64
    800045b0:	892a                	mv	s2,a0
    800045b2:	8a2e                	mv	s4,a1
    800045b4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045b6:	4601                	li	a2,0
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	dd8080e7          	jalr	-552(ra) # 80004390 <dirlookup>
    800045c0:	e93d                	bnez	a0,80004636 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045c2:	04c92483          	lw	s1,76(s2)
    800045c6:	c49d                	beqz	s1,800045f4 <dirlink+0x54>
    800045c8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045ca:	4741                	li	a4,16
    800045cc:	86a6                	mv	a3,s1
    800045ce:	fc040613          	addi	a2,s0,-64
    800045d2:	4581                	li	a1,0
    800045d4:	854a                	mv	a0,s2
    800045d6:	00000097          	auipc	ra,0x0
    800045da:	b8a080e7          	jalr	-1142(ra) # 80004160 <readi>
    800045de:	47c1                	li	a5,16
    800045e0:	06f51163          	bne	a0,a5,80004642 <dirlink+0xa2>
    if(de.inum == 0)
    800045e4:	fc045783          	lhu	a5,-64(s0)
    800045e8:	c791                	beqz	a5,800045f4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045ea:	24c1                	addiw	s1,s1,16
    800045ec:	04c92783          	lw	a5,76(s2)
    800045f0:	fcf4ede3          	bltu	s1,a5,800045ca <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800045f4:	4639                	li	a2,14
    800045f6:	85d2                	mv	a1,s4
    800045f8:	fc240513          	addi	a0,s0,-62
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	7e8080e7          	jalr	2024(ra) # 80000de4 <strncpy>
  de.inum = inum;
    80004604:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004608:	4741                	li	a4,16
    8000460a:	86a6                	mv	a3,s1
    8000460c:	fc040613          	addi	a2,s0,-64
    80004610:	4581                	li	a1,0
    80004612:	854a                	mv	a0,s2
    80004614:	00000097          	auipc	ra,0x0
    80004618:	c44080e7          	jalr	-956(ra) # 80004258 <writei>
    8000461c:	872a                	mv	a4,a0
    8000461e:	47c1                	li	a5,16
  return 0;
    80004620:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004622:	02f71863          	bne	a4,a5,80004652 <dirlink+0xb2>
}
    80004626:	70e2                	ld	ra,56(sp)
    80004628:	7442                	ld	s0,48(sp)
    8000462a:	74a2                	ld	s1,40(sp)
    8000462c:	7902                	ld	s2,32(sp)
    8000462e:	69e2                	ld	s3,24(sp)
    80004630:	6a42                	ld	s4,16(sp)
    80004632:	6121                	addi	sp,sp,64
    80004634:	8082                	ret
    iput(ip);
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	a30080e7          	jalr	-1488(ra) # 80004066 <iput>
    return -1;
    8000463e:	557d                	li	a0,-1
    80004640:	b7dd                	j	80004626 <dirlink+0x86>
      panic("dirlink read");
    80004642:	00004517          	auipc	a0,0x4
    80004646:	22650513          	addi	a0,a0,550 # 80008868 <syscalls+0x1c8>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	ee0080e7          	jalr	-288(ra) # 8000052a <panic>
    panic("dirlink");
    80004652:	00004517          	auipc	a0,0x4
    80004656:	39e50513          	addi	a0,a0,926 # 800089f0 <syscalls+0x350>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	ed0080e7          	jalr	-304(ra) # 8000052a <panic>

0000000080004662 <namei>:

struct inode*
namei(char *path)
{
    80004662:	1101                	addi	sp,sp,-32
    80004664:	ec06                	sd	ra,24(sp)
    80004666:	e822                	sd	s0,16(sp)
    80004668:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000466a:	fe040613          	addi	a2,s0,-32
    8000466e:	4581                	li	a1,0
    80004670:	00000097          	auipc	ra,0x0
    80004674:	dd0080e7          	jalr	-560(ra) # 80004440 <namex>
}
    80004678:	60e2                	ld	ra,24(sp)
    8000467a:	6442                	ld	s0,16(sp)
    8000467c:	6105                	addi	sp,sp,32
    8000467e:	8082                	ret

0000000080004680 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004680:	1141                	addi	sp,sp,-16
    80004682:	e406                	sd	ra,8(sp)
    80004684:	e022                	sd	s0,0(sp)
    80004686:	0800                	addi	s0,sp,16
    80004688:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000468a:	4585                	li	a1,1
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	db4080e7          	jalr	-588(ra) # 80004440 <namex>
}
    80004694:	60a2                	ld	ra,8(sp)
    80004696:	6402                	ld	s0,0(sp)
    80004698:	0141                	addi	sp,sp,16
    8000469a:	8082                	ret

000000008000469c <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    8000469c:	1101                	addi	sp,sp,-32
    8000469e:	ec22                	sd	s0,24(sp)
    800046a0:	1000                	addi	s0,sp,32
    800046a2:	872a                	mv	a4,a0
    800046a4:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800046a6:	00004797          	auipc	a5,0x4
    800046aa:	1d278793          	addi	a5,a5,466 # 80008878 <syscalls+0x1d8>
    800046ae:	6394                	ld	a3,0(a5)
    800046b0:	fed43023          	sd	a3,-32(s0)
    800046b4:	0087d683          	lhu	a3,8(a5)
    800046b8:	fed41423          	sh	a3,-24(s0)
    800046bc:	00a7c783          	lbu	a5,10(a5)
    800046c0:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800046c4:	87ae                	mv	a5,a1
    if(i<0){
    800046c6:	02074b63          	bltz	a4,800046fc <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800046ca:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800046cc:	4629                	li	a2,10
        ++p;
    800046ce:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800046d0:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800046d4:	feed                	bnez	a3,800046ce <itoa+0x32>
    *p = '\0';
    800046d6:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800046da:	4629                	li	a2,10
    800046dc:	17fd                	addi	a5,a5,-1
    800046de:	02c766bb          	remw	a3,a4,a2
    800046e2:	ff040593          	addi	a1,s0,-16
    800046e6:	96ae                	add	a3,a3,a1
    800046e8:	ff06c683          	lbu	a3,-16(a3)
    800046ec:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800046f0:	02c7473b          	divw	a4,a4,a2
    }while(i);
    800046f4:	f765                	bnez	a4,800046dc <itoa+0x40>
    return b;
}
    800046f6:	6462                	ld	s0,24(sp)
    800046f8:	6105                	addi	sp,sp,32
    800046fa:	8082                	ret
        *p++ = '-';
    800046fc:	00158793          	addi	a5,a1,1
    80004700:	02d00693          	li	a3,45
    80004704:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004708:	40e0073b          	negw	a4,a4
    8000470c:	bf7d                	j	800046ca <itoa+0x2e>

000000008000470e <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    8000470e:	711d                	addi	sp,sp,-96
    80004710:	ec86                	sd	ra,88(sp)
    80004712:	e8a2                	sd	s0,80(sp)
    80004714:	e4a6                	sd	s1,72(sp)
    80004716:	e0ca                	sd	s2,64(sp)
    80004718:	1080                	addi	s0,sp,96
    8000471a:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000471c:	4619                	li	a2,6
    8000471e:	00004597          	auipc	a1,0x4
    80004722:	16a58593          	addi	a1,a1,362 # 80008888 <syscalls+0x1e8>
    80004726:	fd040513          	addi	a0,s0,-48
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	602080e7          	jalr	1538(ra) # 80000d2c <memmove>
  itoa(p->pid, path+ 6);
    80004732:	fd640593          	addi	a1,s0,-42
    80004736:	5888                	lw	a0,48(s1)
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	f64080e7          	jalr	-156(ra) # 8000469c <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004740:	1684b503          	ld	a0,360(s1)
    80004744:	16050763          	beqz	a0,800048b2 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004748:	00001097          	auipc	ra,0x1
    8000474c:	918080e7          	jalr	-1768(ra) # 80005060 <fileclose>

  begin_op();
    80004750:	00000097          	auipc	ra,0x0
    80004754:	444080e7          	jalr	1092(ra) # 80004b94 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    80004758:	fb040593          	addi	a1,s0,-80
    8000475c:	fd040513          	addi	a0,s0,-48
    80004760:	00000097          	auipc	ra,0x0
    80004764:	f20080e7          	jalr	-224(ra) # 80004680 <nameiparent>
    80004768:	892a                	mv	s2,a0
    8000476a:	cd69                	beqz	a0,80004844 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	740080e7          	jalr	1856(ra) # 80003eac <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004774:	00004597          	auipc	a1,0x4
    80004778:	11c58593          	addi	a1,a1,284 # 80008890 <syscalls+0x1f0>
    8000477c:	fb040513          	addi	a0,s0,-80
    80004780:	00000097          	auipc	ra,0x0
    80004784:	bf6080e7          	jalr	-1034(ra) # 80004376 <namecmp>
    80004788:	c57d                	beqz	a0,80004876 <removeSwapFile+0x168>
    8000478a:	00004597          	auipc	a1,0x4
    8000478e:	10e58593          	addi	a1,a1,270 # 80008898 <syscalls+0x1f8>
    80004792:	fb040513          	addi	a0,s0,-80
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	be0080e7          	jalr	-1056(ra) # 80004376 <namecmp>
    8000479e:	cd61                	beqz	a0,80004876 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800047a0:	fac40613          	addi	a2,s0,-84
    800047a4:	fb040593          	addi	a1,s0,-80
    800047a8:	854a                	mv	a0,s2
    800047aa:	00000097          	auipc	ra,0x0
    800047ae:	be6080e7          	jalr	-1050(ra) # 80004390 <dirlookup>
    800047b2:	84aa                	mv	s1,a0
    800047b4:	c169                	beqz	a0,80004876 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	6f6080e7          	jalr	1782(ra) # 80003eac <ilock>

  if(ip->nlink < 1)
    800047be:	04a49783          	lh	a5,74(s1)
    800047c2:	08f05763          	blez	a5,80004850 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800047c6:	04449703          	lh	a4,68(s1)
    800047ca:	4785                	li	a5,1
    800047cc:	08f70a63          	beq	a4,a5,80004860 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800047d0:	4641                	li	a2,16
    800047d2:	4581                	li	a1,0
    800047d4:	fc040513          	addi	a0,s0,-64
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	4f8080e7          	jalr	1272(ra) # 80000cd0 <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047e0:	4741                	li	a4,16
    800047e2:	fac42683          	lw	a3,-84(s0)
    800047e6:	fc040613          	addi	a2,s0,-64
    800047ea:	4581                	li	a1,0
    800047ec:	854a                	mv	a0,s2
    800047ee:	00000097          	auipc	ra,0x0
    800047f2:	a6a080e7          	jalr	-1430(ra) # 80004258 <writei>
    800047f6:	47c1                	li	a5,16
    800047f8:	08f51a63          	bne	a0,a5,8000488c <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800047fc:	04449703          	lh	a4,68(s1)
    80004800:	4785                	li	a5,1
    80004802:	08f70d63          	beq	a4,a5,8000489c <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004806:	854a                	mv	a0,s2
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	906080e7          	jalr	-1786(ra) # 8000410e <iunlockput>

  ip->nlink--;
    80004810:	04a4d783          	lhu	a5,74(s1)
    80004814:	37fd                	addiw	a5,a5,-1
    80004816:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000481a:	8526                	mv	a0,s1
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	5c6080e7          	jalr	1478(ra) # 80003de2 <iupdate>
  iunlockput(ip);
    80004824:	8526                	mv	a0,s1
    80004826:	00000097          	auipc	ra,0x0
    8000482a:	8e8080e7          	jalr	-1816(ra) # 8000410e <iunlockput>

  end_op();
    8000482e:	00000097          	auipc	ra,0x0
    80004832:	3e6080e7          	jalr	998(ra) # 80004c14 <end_op>

  return 0;
    80004836:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004838:	60e6                	ld	ra,88(sp)
    8000483a:	6446                	ld	s0,80(sp)
    8000483c:	64a6                	ld	s1,72(sp)
    8000483e:	6906                	ld	s2,64(sp)
    80004840:	6125                	addi	sp,sp,96
    80004842:	8082                	ret
    end_op();
    80004844:	00000097          	auipc	ra,0x0
    80004848:	3d0080e7          	jalr	976(ra) # 80004c14 <end_op>
    return -1;
    8000484c:	557d                	li	a0,-1
    8000484e:	b7ed                	j	80004838 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004850:	00004517          	auipc	a0,0x4
    80004854:	05050513          	addi	a0,a0,80 # 800088a0 <syscalls+0x200>
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	cd2080e7          	jalr	-814(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004860:	8526                	mv	a0,s1
    80004862:	00002097          	auipc	ra,0x2
    80004866:	848080e7          	jalr	-1976(ra) # 800060aa <isdirempty>
    8000486a:	f13d                	bnez	a0,800047d0 <removeSwapFile+0xc2>
    iunlockput(ip);
    8000486c:	8526                	mv	a0,s1
    8000486e:	00000097          	auipc	ra,0x0
    80004872:	8a0080e7          	jalr	-1888(ra) # 8000410e <iunlockput>
    iunlockput(dp);
    80004876:	854a                	mv	a0,s2
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	896080e7          	jalr	-1898(ra) # 8000410e <iunlockput>
    end_op();
    80004880:	00000097          	auipc	ra,0x0
    80004884:	394080e7          	jalr	916(ra) # 80004c14 <end_op>
    return -1;
    80004888:	557d                	li	a0,-1
    8000488a:	b77d                	j	80004838 <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000488c:	00004517          	auipc	a0,0x4
    80004890:	02c50513          	addi	a0,a0,44 # 800088b8 <syscalls+0x218>
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	c96080e7          	jalr	-874(ra) # 8000052a <panic>
    dp->nlink--;
    8000489c:	04a95783          	lhu	a5,74(s2)
    800048a0:	37fd                	addiw	a5,a5,-1
    800048a2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800048a6:	854a                	mv	a0,s2
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	53a080e7          	jalr	1338(ra) # 80003de2 <iupdate>
    800048b0:	bf99                	j	80004806 <removeSwapFile+0xf8>
    return -1;
    800048b2:	557d                	li	a0,-1
    800048b4:	b751                	j	80004838 <removeSwapFile+0x12a>

00000000800048b6 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800048b6:	7179                	addi	sp,sp,-48
    800048b8:	f406                	sd	ra,40(sp)
    800048ba:	f022                	sd	s0,32(sp)
    800048bc:	ec26                	sd	s1,24(sp)
    800048be:	e84a                	sd	s2,16(sp)
    800048c0:	1800                	addi	s0,sp,48
    800048c2:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800048c4:	4619                	li	a2,6
    800048c6:	00004597          	auipc	a1,0x4
    800048ca:	fc258593          	addi	a1,a1,-62 # 80008888 <syscalls+0x1e8>
    800048ce:	fd040513          	addi	a0,s0,-48
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	45a080e7          	jalr	1114(ra) # 80000d2c <memmove>
  itoa(p->pid, path+ 6);
    800048da:	fd640593          	addi	a1,s0,-42
    800048de:	5888                	lw	a0,48(s1)
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	dbc080e7          	jalr	-580(ra) # 8000469c <itoa>

  begin_op();
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	2ac080e7          	jalr	684(ra) # 80004b94 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    800048f0:	4681                	li	a3,0
    800048f2:	4601                	li	a2,0
    800048f4:	4589                	li	a1,2
    800048f6:	fd040513          	addi	a0,s0,-48
    800048fa:	00002097          	auipc	ra,0x2
    800048fe:	9a4080e7          	jalr	-1628(ra) # 8000629e <create>
    80004902:	892a                	mv	s2,a0
  iunlock(in);
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	66a080e7          	jalr	1642(ra) # 80003f6e <iunlock>
  p->swapFile = filealloc();
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	698080e7          	jalr	1688(ra) # 80004fa4 <filealloc>
    80004914:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004918:	cd1d                	beqz	a0,80004956 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000491a:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    8000491e:	1684b703          	ld	a4,360(s1)
    80004922:	4789                	li	a5,2
    80004924:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004926:	1684b703          	ld	a4,360(s1)
    8000492a:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    8000492e:	1684b703          	ld	a4,360(s1)
    80004932:	4685                	li	a3,1
    80004934:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004938:	1684b703          	ld	a4,360(s1)
    8000493c:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004940:	00000097          	auipc	ra,0x0
    80004944:	2d4080e7          	jalr	724(ra) # 80004c14 <end_op>

    return 0;
}
    80004948:	4501                	li	a0,0
    8000494a:	70a2                	ld	ra,40(sp)
    8000494c:	7402                	ld	s0,32(sp)
    8000494e:	64e2                	ld	s1,24(sp)
    80004950:	6942                	ld	s2,16(sp)
    80004952:	6145                	addi	sp,sp,48
    80004954:	8082                	ret
    panic("no slot for files on /store");
    80004956:	00004517          	auipc	a0,0x4
    8000495a:	f7250513          	addi	a0,a0,-142 # 800088c8 <syscalls+0x228>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	bcc080e7          	jalr	-1076(ra) # 8000052a <panic>

0000000080004966 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004966:	1141                	addi	sp,sp,-16
    80004968:	e406                	sd	ra,8(sp)
    8000496a:	e022                	sd	s0,0(sp)
    8000496c:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    8000496e:	16853783          	ld	a5,360(a0)
    80004972:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004974:	8636                	mv	a2,a3
    80004976:	16853503          	ld	a0,360(a0)
    8000497a:	00001097          	auipc	ra,0x1
    8000497e:	ad8080e7          	jalr	-1320(ra) # 80005452 <kfilewrite>
}
    80004982:	60a2                	ld	ra,8(sp)
    80004984:	6402                	ld	s0,0(sp)
    80004986:	0141                	addi	sp,sp,16
    80004988:	8082                	ret

000000008000498a <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    8000498a:	1141                	addi	sp,sp,-16
    8000498c:	e406                	sd	ra,8(sp)
    8000498e:	e022                	sd	s0,0(sp)
    80004990:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004992:	16853783          	ld	a5,360(a0)
    80004996:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004998:	8636                	mv	a2,a3
    8000499a:	16853503          	ld	a0,360(a0)
    8000499e:	00001097          	auipc	ra,0x1
    800049a2:	9f2080e7          	jalr	-1550(ra) # 80005390 <kfileread>
    800049a6:	60a2                	ld	ra,8(sp)
    800049a8:	6402                	ld	s0,0(sp)
    800049aa:	0141                	addi	sp,sp,16
    800049ac:	8082                	ret

00000000800049ae <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800049ae:	1101                	addi	sp,sp,-32
    800049b0:	ec06                	sd	ra,24(sp)
    800049b2:	e822                	sd	s0,16(sp)
    800049b4:	e426                	sd	s1,8(sp)
    800049b6:	e04a                	sd	s2,0(sp)
    800049b8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800049ba:	00025917          	auipc	s2,0x25
    800049be:	cb690913          	addi	s2,s2,-842 # 80029670 <log>
    800049c2:	01892583          	lw	a1,24(s2)
    800049c6:	02892503          	lw	a0,40(s2)
    800049ca:	fffff097          	auipc	ra,0xfffff
    800049ce:	cde080e7          	jalr	-802(ra) # 800036a8 <bread>
    800049d2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800049d4:	02c92683          	lw	a3,44(s2)
    800049d8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800049da:	02d05863          	blez	a3,80004a0a <write_head+0x5c>
    800049de:	00025797          	auipc	a5,0x25
    800049e2:	cc278793          	addi	a5,a5,-830 # 800296a0 <log+0x30>
    800049e6:	05c50713          	addi	a4,a0,92
    800049ea:	36fd                	addiw	a3,a3,-1
    800049ec:	02069613          	slli	a2,a3,0x20
    800049f0:	01e65693          	srli	a3,a2,0x1e
    800049f4:	00025617          	auipc	a2,0x25
    800049f8:	cb060613          	addi	a2,a2,-848 # 800296a4 <log+0x34>
    800049fc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800049fe:	4390                	lw	a2,0(a5)
    80004a00:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a02:	0791                	addi	a5,a5,4
    80004a04:	0711                	addi	a4,a4,4
    80004a06:	fed79ce3          	bne	a5,a3,800049fe <write_head+0x50>
  }
  bwrite(buf);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	fffff097          	auipc	ra,0xfffff
    80004a10:	d8e080e7          	jalr	-626(ra) # 8000379a <bwrite>
  brelse(buf);
    80004a14:	8526                	mv	a0,s1
    80004a16:	fffff097          	auipc	ra,0xfffff
    80004a1a:	dc2080e7          	jalr	-574(ra) # 800037d8 <brelse>
}
    80004a1e:	60e2                	ld	ra,24(sp)
    80004a20:	6442                	ld	s0,16(sp)
    80004a22:	64a2                	ld	s1,8(sp)
    80004a24:	6902                	ld	s2,0(sp)
    80004a26:	6105                	addi	sp,sp,32
    80004a28:	8082                	ret

0000000080004a2a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a2a:	00025797          	auipc	a5,0x25
    80004a2e:	c727a783          	lw	a5,-910(a5) # 8002969c <log+0x2c>
    80004a32:	0af05d63          	blez	a5,80004aec <install_trans+0xc2>
{
    80004a36:	7139                	addi	sp,sp,-64
    80004a38:	fc06                	sd	ra,56(sp)
    80004a3a:	f822                	sd	s0,48(sp)
    80004a3c:	f426                	sd	s1,40(sp)
    80004a3e:	f04a                	sd	s2,32(sp)
    80004a40:	ec4e                	sd	s3,24(sp)
    80004a42:	e852                	sd	s4,16(sp)
    80004a44:	e456                	sd	s5,8(sp)
    80004a46:	e05a                	sd	s6,0(sp)
    80004a48:	0080                	addi	s0,sp,64
    80004a4a:	8b2a                	mv	s6,a0
    80004a4c:	00025a97          	auipc	s5,0x25
    80004a50:	c54a8a93          	addi	s5,s5,-940 # 800296a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a54:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a56:	00025997          	auipc	s3,0x25
    80004a5a:	c1a98993          	addi	s3,s3,-998 # 80029670 <log>
    80004a5e:	a00d                	j	80004a80 <install_trans+0x56>
    brelse(lbuf);
    80004a60:	854a                	mv	a0,s2
    80004a62:	fffff097          	auipc	ra,0xfffff
    80004a66:	d76080e7          	jalr	-650(ra) # 800037d8 <brelse>
    brelse(dbuf);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	d6c080e7          	jalr	-660(ra) # 800037d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a74:	2a05                	addiw	s4,s4,1
    80004a76:	0a91                	addi	s5,s5,4
    80004a78:	02c9a783          	lw	a5,44(s3)
    80004a7c:	04fa5e63          	bge	s4,a5,80004ad8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a80:	0189a583          	lw	a1,24(s3)
    80004a84:	014585bb          	addw	a1,a1,s4
    80004a88:	2585                	addiw	a1,a1,1
    80004a8a:	0289a503          	lw	a0,40(s3)
    80004a8e:	fffff097          	auipc	ra,0xfffff
    80004a92:	c1a080e7          	jalr	-998(ra) # 800036a8 <bread>
    80004a96:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004a98:	000aa583          	lw	a1,0(s5)
    80004a9c:	0289a503          	lw	a0,40(s3)
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	c08080e7          	jalr	-1016(ra) # 800036a8 <bread>
    80004aa8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004aaa:	40000613          	li	a2,1024
    80004aae:	05890593          	addi	a1,s2,88
    80004ab2:	05850513          	addi	a0,a0,88
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	276080e7          	jalr	630(ra) # 80000d2c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004abe:	8526                	mv	a0,s1
    80004ac0:	fffff097          	auipc	ra,0xfffff
    80004ac4:	cda080e7          	jalr	-806(ra) # 8000379a <bwrite>
    if(recovering == 0)
    80004ac8:	f80b1ce3          	bnez	s6,80004a60 <install_trans+0x36>
      bunpin(dbuf);
    80004acc:	8526                	mv	a0,s1
    80004ace:	fffff097          	auipc	ra,0xfffff
    80004ad2:	de4080e7          	jalr	-540(ra) # 800038b2 <bunpin>
    80004ad6:	b769                	j	80004a60 <install_trans+0x36>
}
    80004ad8:	70e2                	ld	ra,56(sp)
    80004ada:	7442                	ld	s0,48(sp)
    80004adc:	74a2                	ld	s1,40(sp)
    80004ade:	7902                	ld	s2,32(sp)
    80004ae0:	69e2                	ld	s3,24(sp)
    80004ae2:	6a42                	ld	s4,16(sp)
    80004ae4:	6aa2                	ld	s5,8(sp)
    80004ae6:	6b02                	ld	s6,0(sp)
    80004ae8:	6121                	addi	sp,sp,64
    80004aea:	8082                	ret
    80004aec:	8082                	ret

0000000080004aee <initlog>:
{
    80004aee:	7179                	addi	sp,sp,-48
    80004af0:	f406                	sd	ra,40(sp)
    80004af2:	f022                	sd	s0,32(sp)
    80004af4:	ec26                	sd	s1,24(sp)
    80004af6:	e84a                	sd	s2,16(sp)
    80004af8:	e44e                	sd	s3,8(sp)
    80004afa:	1800                	addi	s0,sp,48
    80004afc:	892a                	mv	s2,a0
    80004afe:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004b00:	00025497          	auipc	s1,0x25
    80004b04:	b7048493          	addi	s1,s1,-1168 # 80029670 <log>
    80004b08:	00004597          	auipc	a1,0x4
    80004b0c:	de058593          	addi	a1,a1,-544 # 800088e8 <syscalls+0x248>
    80004b10:	8526                	mv	a0,s1
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	020080e7          	jalr	32(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004b1a:	0149a583          	lw	a1,20(s3)
    80004b1e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004b20:	0109a783          	lw	a5,16(s3)
    80004b24:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004b26:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004b2a:	854a                	mv	a0,s2
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	b7c080e7          	jalr	-1156(ra) # 800036a8 <bread>
  log.lh.n = lh->n;
    80004b34:	4d34                	lw	a3,88(a0)
    80004b36:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004b38:	02d05663          	blez	a3,80004b64 <initlog+0x76>
    80004b3c:	05c50793          	addi	a5,a0,92
    80004b40:	00025717          	auipc	a4,0x25
    80004b44:	b6070713          	addi	a4,a4,-1184 # 800296a0 <log+0x30>
    80004b48:	36fd                	addiw	a3,a3,-1
    80004b4a:	02069613          	slli	a2,a3,0x20
    80004b4e:	01e65693          	srli	a3,a2,0x1e
    80004b52:	06050613          	addi	a2,a0,96
    80004b56:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004b58:	4390                	lw	a2,0(a5)
    80004b5a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b5c:	0791                	addi	a5,a5,4
    80004b5e:	0711                	addi	a4,a4,4
    80004b60:	fed79ce3          	bne	a5,a3,80004b58 <initlog+0x6a>
  brelse(buf);
    80004b64:	fffff097          	auipc	ra,0xfffff
    80004b68:	c74080e7          	jalr	-908(ra) # 800037d8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004b6c:	4505                	li	a0,1
    80004b6e:	00000097          	auipc	ra,0x0
    80004b72:	ebc080e7          	jalr	-324(ra) # 80004a2a <install_trans>
  log.lh.n = 0;
    80004b76:	00025797          	auipc	a5,0x25
    80004b7a:	b207a323          	sw	zero,-1242(a5) # 8002969c <log+0x2c>
  write_head(); // clear the log
    80004b7e:	00000097          	auipc	ra,0x0
    80004b82:	e30080e7          	jalr	-464(ra) # 800049ae <write_head>
}
    80004b86:	70a2                	ld	ra,40(sp)
    80004b88:	7402                	ld	s0,32(sp)
    80004b8a:	64e2                	ld	s1,24(sp)
    80004b8c:	6942                	ld	s2,16(sp)
    80004b8e:	69a2                	ld	s3,8(sp)
    80004b90:	6145                	addi	sp,sp,48
    80004b92:	8082                	ret

0000000080004b94 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004b94:	1101                	addi	sp,sp,-32
    80004b96:	ec06                	sd	ra,24(sp)
    80004b98:	e822                	sd	s0,16(sp)
    80004b9a:	e426                	sd	s1,8(sp)
    80004b9c:	e04a                	sd	s2,0(sp)
    80004b9e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ba0:	00025517          	auipc	a0,0x25
    80004ba4:	ad050513          	addi	a0,a0,-1328 # 80029670 <log>
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	01a080e7          	jalr	26(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004bb0:	00025497          	auipc	s1,0x25
    80004bb4:	ac048493          	addi	s1,s1,-1344 # 80029670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004bb8:	4979                	li	s2,30
    80004bba:	a039                	j	80004bc8 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004bbc:	85a6                	mv	a1,s1
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	ffffd097          	auipc	ra,0xffffd
    80004bc4:	374080e7          	jalr	884(ra) # 80001f34 <sleep>
    if(log.committing){
    80004bc8:	50dc                	lw	a5,36(s1)
    80004bca:	fbed                	bnez	a5,80004bbc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004bcc:	509c                	lw	a5,32(s1)
    80004bce:	0017871b          	addiw	a4,a5,1
    80004bd2:	0007069b          	sext.w	a3,a4
    80004bd6:	0027179b          	slliw	a5,a4,0x2
    80004bda:	9fb9                	addw	a5,a5,a4
    80004bdc:	0017979b          	slliw	a5,a5,0x1
    80004be0:	54d8                	lw	a4,44(s1)
    80004be2:	9fb9                	addw	a5,a5,a4
    80004be4:	00f95963          	bge	s2,a5,80004bf6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004be8:	85a6                	mv	a1,s1
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffd097          	auipc	ra,0xffffd
    80004bf0:	348080e7          	jalr	840(ra) # 80001f34 <sleep>
    80004bf4:	bfd1                	j	80004bc8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004bf6:	00025517          	auipc	a0,0x25
    80004bfa:	a7a50513          	addi	a0,a0,-1414 # 80029670 <log>
    80004bfe:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	088080e7          	jalr	136(ra) # 80000c88 <release>
      break;
    }
  }
}
    80004c08:	60e2                	ld	ra,24(sp)
    80004c0a:	6442                	ld	s0,16(sp)
    80004c0c:	64a2                	ld	s1,8(sp)
    80004c0e:	6902                	ld	s2,0(sp)
    80004c10:	6105                	addi	sp,sp,32
    80004c12:	8082                	ret

0000000080004c14 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004c14:	7139                	addi	sp,sp,-64
    80004c16:	fc06                	sd	ra,56(sp)
    80004c18:	f822                	sd	s0,48(sp)
    80004c1a:	f426                	sd	s1,40(sp)
    80004c1c:	f04a                	sd	s2,32(sp)
    80004c1e:	ec4e                	sd	s3,24(sp)
    80004c20:	e852                	sd	s4,16(sp)
    80004c22:	e456                	sd	s5,8(sp)
    80004c24:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004c26:	00025497          	auipc	s1,0x25
    80004c2a:	a4a48493          	addi	s1,s1,-1462 # 80029670 <log>
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	f92080e7          	jalr	-110(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004c38:	509c                	lw	a5,32(s1)
    80004c3a:	37fd                	addiw	a5,a5,-1
    80004c3c:	0007891b          	sext.w	s2,a5
    80004c40:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004c42:	50dc                	lw	a5,36(s1)
    80004c44:	e7b9                	bnez	a5,80004c92 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004c46:	04091e63          	bnez	s2,80004ca2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004c4a:	00025497          	auipc	s1,0x25
    80004c4e:	a2648493          	addi	s1,s1,-1498 # 80029670 <log>
    80004c52:	4785                	li	a5,1
    80004c54:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	030080e7          	jalr	48(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004c60:	54dc                	lw	a5,44(s1)
    80004c62:	06f04763          	bgtz	a5,80004cd0 <end_op+0xbc>
    acquire(&log.lock);
    80004c66:	00025497          	auipc	s1,0x25
    80004c6a:	a0a48493          	addi	s1,s1,-1526 # 80029670 <log>
    80004c6e:	8526                	mv	a0,s1
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	f52080e7          	jalr	-174(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004c78:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	31a080e7          	jalr	794(ra) # 80001f98 <wakeup>
    release(&log.lock);
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	000080e7          	jalr	ra # 80000c88 <release>
}
    80004c90:	a03d                	j	80004cbe <end_op+0xaa>
    panic("log.committing");
    80004c92:	00004517          	auipc	a0,0x4
    80004c96:	c5e50513          	addi	a0,a0,-930 # 800088f0 <syscalls+0x250>
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	890080e7          	jalr	-1904(ra) # 8000052a <panic>
    wakeup(&log);
    80004ca2:	00025497          	auipc	s1,0x25
    80004ca6:	9ce48493          	addi	s1,s1,-1586 # 80029670 <log>
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffd097          	auipc	ra,0xffffd
    80004cb0:	2ec080e7          	jalr	748(ra) # 80001f98 <wakeup>
  release(&log.lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	fd2080e7          	jalr	-46(ra) # 80000c88 <release>
}
    80004cbe:	70e2                	ld	ra,56(sp)
    80004cc0:	7442                	ld	s0,48(sp)
    80004cc2:	74a2                	ld	s1,40(sp)
    80004cc4:	7902                	ld	s2,32(sp)
    80004cc6:	69e2                	ld	s3,24(sp)
    80004cc8:	6a42                	ld	s4,16(sp)
    80004cca:	6aa2                	ld	s5,8(sp)
    80004ccc:	6121                	addi	sp,sp,64
    80004cce:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004cd0:	00025a97          	auipc	s5,0x25
    80004cd4:	9d0a8a93          	addi	s5,s5,-1584 # 800296a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004cd8:	00025a17          	auipc	s4,0x25
    80004cdc:	998a0a13          	addi	s4,s4,-1640 # 80029670 <log>
    80004ce0:	018a2583          	lw	a1,24(s4)
    80004ce4:	012585bb          	addw	a1,a1,s2
    80004ce8:	2585                	addiw	a1,a1,1
    80004cea:	028a2503          	lw	a0,40(s4)
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	9ba080e7          	jalr	-1606(ra) # 800036a8 <bread>
    80004cf6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004cf8:	000aa583          	lw	a1,0(s5)
    80004cfc:	028a2503          	lw	a0,40(s4)
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	9a8080e7          	jalr	-1624(ra) # 800036a8 <bread>
    80004d08:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004d0a:	40000613          	li	a2,1024
    80004d0e:	05850593          	addi	a1,a0,88
    80004d12:	05848513          	addi	a0,s1,88
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	016080e7          	jalr	22(ra) # 80000d2c <memmove>
    bwrite(to);  // write the log
    80004d1e:	8526                	mv	a0,s1
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	a7a080e7          	jalr	-1414(ra) # 8000379a <bwrite>
    brelse(from);
    80004d28:	854e                	mv	a0,s3
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	aae080e7          	jalr	-1362(ra) # 800037d8 <brelse>
    brelse(to);
    80004d32:	8526                	mv	a0,s1
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	aa4080e7          	jalr	-1372(ra) # 800037d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d3c:	2905                	addiw	s2,s2,1
    80004d3e:	0a91                	addi	s5,s5,4
    80004d40:	02ca2783          	lw	a5,44(s4)
    80004d44:	f8f94ee3          	blt	s2,a5,80004ce0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004d48:	00000097          	auipc	ra,0x0
    80004d4c:	c66080e7          	jalr	-922(ra) # 800049ae <write_head>
    install_trans(0); // Now install writes to home locations
    80004d50:	4501                	li	a0,0
    80004d52:	00000097          	auipc	ra,0x0
    80004d56:	cd8080e7          	jalr	-808(ra) # 80004a2a <install_trans>
    log.lh.n = 0;
    80004d5a:	00025797          	auipc	a5,0x25
    80004d5e:	9407a123          	sw	zero,-1726(a5) # 8002969c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004d62:	00000097          	auipc	ra,0x0
    80004d66:	c4c080e7          	jalr	-948(ra) # 800049ae <write_head>
    80004d6a:	bdf5                	j	80004c66 <end_op+0x52>

0000000080004d6c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004d6c:	1101                	addi	sp,sp,-32
    80004d6e:	ec06                	sd	ra,24(sp)
    80004d70:	e822                	sd	s0,16(sp)
    80004d72:	e426                	sd	s1,8(sp)
    80004d74:	e04a                	sd	s2,0(sp)
    80004d76:	1000                	addi	s0,sp,32
    80004d78:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004d7a:	00025917          	auipc	s2,0x25
    80004d7e:	8f690913          	addi	s2,s2,-1802 # 80029670 <log>
    80004d82:	854a                	mv	a0,s2
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	e3e080e7          	jalr	-450(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004d8c:	02c92603          	lw	a2,44(s2)
    80004d90:	47f5                	li	a5,29
    80004d92:	06c7c563          	blt	a5,a2,80004dfc <log_write+0x90>
    80004d96:	00025797          	auipc	a5,0x25
    80004d9a:	8f67a783          	lw	a5,-1802(a5) # 8002968c <log+0x1c>
    80004d9e:	37fd                	addiw	a5,a5,-1
    80004da0:	04f65e63          	bge	a2,a5,80004dfc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004da4:	00025797          	auipc	a5,0x25
    80004da8:	8ec7a783          	lw	a5,-1812(a5) # 80029690 <log+0x20>
    80004dac:	06f05063          	blez	a5,80004e0c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004db0:	4781                	li	a5,0
    80004db2:	06c05563          	blez	a2,80004e1c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004db6:	44cc                	lw	a1,12(s1)
    80004db8:	00025717          	auipc	a4,0x25
    80004dbc:	8e870713          	addi	a4,a4,-1816 # 800296a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004dc0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004dc2:	4314                	lw	a3,0(a4)
    80004dc4:	04b68c63          	beq	a3,a1,80004e1c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004dc8:	2785                	addiw	a5,a5,1
    80004dca:	0711                	addi	a4,a4,4
    80004dcc:	fef61be3          	bne	a2,a5,80004dc2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004dd0:	0621                	addi	a2,a2,8
    80004dd2:	060a                	slli	a2,a2,0x2
    80004dd4:	00025797          	auipc	a5,0x25
    80004dd8:	89c78793          	addi	a5,a5,-1892 # 80029670 <log>
    80004ddc:	963e                	add	a2,a2,a5
    80004dde:	44dc                	lw	a5,12(s1)
    80004de0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004de2:	8526                	mv	a0,s1
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	a92080e7          	jalr	-1390(ra) # 80003876 <bpin>
    log.lh.n++;
    80004dec:	00025717          	auipc	a4,0x25
    80004df0:	88470713          	addi	a4,a4,-1916 # 80029670 <log>
    80004df4:	575c                	lw	a5,44(a4)
    80004df6:	2785                	addiw	a5,a5,1
    80004df8:	d75c                	sw	a5,44(a4)
    80004dfa:	a835                	j	80004e36 <log_write+0xca>
    panic("too big a transaction");
    80004dfc:	00004517          	auipc	a0,0x4
    80004e00:	b0450513          	addi	a0,a0,-1276 # 80008900 <syscalls+0x260>
    80004e04:	ffffb097          	auipc	ra,0xffffb
    80004e08:	726080e7          	jalr	1830(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004e0c:	00004517          	auipc	a0,0x4
    80004e10:	b0c50513          	addi	a0,a0,-1268 # 80008918 <syscalls+0x278>
    80004e14:	ffffb097          	auipc	ra,0xffffb
    80004e18:	716080e7          	jalr	1814(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004e1c:	00878713          	addi	a4,a5,8
    80004e20:	00271693          	slli	a3,a4,0x2
    80004e24:	00025717          	auipc	a4,0x25
    80004e28:	84c70713          	addi	a4,a4,-1972 # 80029670 <log>
    80004e2c:	9736                	add	a4,a4,a3
    80004e2e:	44d4                	lw	a3,12(s1)
    80004e30:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004e32:	faf608e3          	beq	a2,a5,80004de2 <log_write+0x76>
  }
  release(&log.lock);
    80004e36:	00025517          	auipc	a0,0x25
    80004e3a:	83a50513          	addi	a0,a0,-1990 # 80029670 <log>
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	e4a080e7          	jalr	-438(ra) # 80000c88 <release>
}
    80004e46:	60e2                	ld	ra,24(sp)
    80004e48:	6442                	ld	s0,16(sp)
    80004e4a:	64a2                	ld	s1,8(sp)
    80004e4c:	6902                	ld	s2,0(sp)
    80004e4e:	6105                	addi	sp,sp,32
    80004e50:	8082                	ret

0000000080004e52 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004e52:	1101                	addi	sp,sp,-32
    80004e54:	ec06                	sd	ra,24(sp)
    80004e56:	e822                	sd	s0,16(sp)
    80004e58:	e426                	sd	s1,8(sp)
    80004e5a:	e04a                	sd	s2,0(sp)
    80004e5c:	1000                	addi	s0,sp,32
    80004e5e:	84aa                	mv	s1,a0
    80004e60:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004e62:	00004597          	auipc	a1,0x4
    80004e66:	ad658593          	addi	a1,a1,-1322 # 80008938 <syscalls+0x298>
    80004e6a:	0521                	addi	a0,a0,8
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	cc6080e7          	jalr	-826(ra) # 80000b32 <initlock>
  lk->name = name;
    80004e74:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004e78:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e7c:	0204a423          	sw	zero,40(s1)
}
    80004e80:	60e2                	ld	ra,24(sp)
    80004e82:	6442                	ld	s0,16(sp)
    80004e84:	64a2                	ld	s1,8(sp)
    80004e86:	6902                	ld	s2,0(sp)
    80004e88:	6105                	addi	sp,sp,32
    80004e8a:	8082                	ret

0000000080004e8c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004e8c:	1101                	addi	sp,sp,-32
    80004e8e:	ec06                	sd	ra,24(sp)
    80004e90:	e822                	sd	s0,16(sp)
    80004e92:	e426                	sd	s1,8(sp)
    80004e94:	e04a                	sd	s2,0(sp)
    80004e96:	1000                	addi	s0,sp,32
    80004e98:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e9a:	00850913          	addi	s2,a0,8
    80004e9e:	854a                	mv	a0,s2
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	d22080e7          	jalr	-734(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004ea8:	409c                	lw	a5,0(s1)
    80004eaa:	cb89                	beqz	a5,80004ebc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004eac:	85ca                	mv	a1,s2
    80004eae:	8526                	mv	a0,s1
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	084080e7          	jalr	132(ra) # 80001f34 <sleep>
  while (lk->locked) {
    80004eb8:	409c                	lw	a5,0(s1)
    80004eba:	fbed                	bnez	a5,80004eac <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ebc:	4785                	li	a5,1
    80004ebe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ec0:	ffffd097          	auipc	ra,0xffffd
    80004ec4:	b26080e7          	jalr	-1242(ra) # 800019e6 <myproc>
    80004ec8:	591c                	lw	a5,48(a0)
    80004eca:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ecc:	854a                	mv	a0,s2
    80004ece:	ffffc097          	auipc	ra,0xffffc
    80004ed2:	dba080e7          	jalr	-582(ra) # 80000c88 <release>
}
    80004ed6:	60e2                	ld	ra,24(sp)
    80004ed8:	6442                	ld	s0,16(sp)
    80004eda:	64a2                	ld	s1,8(sp)
    80004edc:	6902                	ld	s2,0(sp)
    80004ede:	6105                	addi	sp,sp,32
    80004ee0:	8082                	ret

0000000080004ee2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ee2:	1101                	addi	sp,sp,-32
    80004ee4:	ec06                	sd	ra,24(sp)
    80004ee6:	e822                	sd	s0,16(sp)
    80004ee8:	e426                	sd	s1,8(sp)
    80004eea:	e04a                	sd	s2,0(sp)
    80004eec:	1000                	addi	s0,sp,32
    80004eee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ef0:	00850913          	addi	s2,a0,8
    80004ef4:	854a                	mv	a0,s2
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	ccc080e7          	jalr	-820(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004efe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f02:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004f06:	8526                	mv	a0,s1
    80004f08:	ffffd097          	auipc	ra,0xffffd
    80004f0c:	090080e7          	jalr	144(ra) # 80001f98 <wakeup>
  release(&lk->lk);
    80004f10:	854a                	mv	a0,s2
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	d76080e7          	jalr	-650(ra) # 80000c88 <release>
}
    80004f1a:	60e2                	ld	ra,24(sp)
    80004f1c:	6442                	ld	s0,16(sp)
    80004f1e:	64a2                	ld	s1,8(sp)
    80004f20:	6902                	ld	s2,0(sp)
    80004f22:	6105                	addi	sp,sp,32
    80004f24:	8082                	ret

0000000080004f26 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004f26:	7179                	addi	sp,sp,-48
    80004f28:	f406                	sd	ra,40(sp)
    80004f2a:	f022                	sd	s0,32(sp)
    80004f2c:	ec26                	sd	s1,24(sp)
    80004f2e:	e84a                	sd	s2,16(sp)
    80004f30:	e44e                	sd	s3,8(sp)
    80004f32:	1800                	addi	s0,sp,48
    80004f34:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004f36:	00850913          	addi	s2,a0,8
    80004f3a:	854a                	mv	a0,s2
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	c86080e7          	jalr	-890(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f44:	409c                	lw	a5,0(s1)
    80004f46:	ef99                	bnez	a5,80004f64 <holdingsleep+0x3e>
    80004f48:	4481                	li	s1,0
  release(&lk->lk);
    80004f4a:	854a                	mv	a0,s2
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	d3c080e7          	jalr	-708(ra) # 80000c88 <release>
  return r;
}
    80004f54:	8526                	mv	a0,s1
    80004f56:	70a2                	ld	ra,40(sp)
    80004f58:	7402                	ld	s0,32(sp)
    80004f5a:	64e2                	ld	s1,24(sp)
    80004f5c:	6942                	ld	s2,16(sp)
    80004f5e:	69a2                	ld	s3,8(sp)
    80004f60:	6145                	addi	sp,sp,48
    80004f62:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f64:	0284a983          	lw	s3,40(s1)
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	a7e080e7          	jalr	-1410(ra) # 800019e6 <myproc>
    80004f70:	5904                	lw	s1,48(a0)
    80004f72:	413484b3          	sub	s1,s1,s3
    80004f76:	0014b493          	seqz	s1,s1
    80004f7a:	bfc1                	j	80004f4a <holdingsleep+0x24>

0000000080004f7c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004f7c:	1141                	addi	sp,sp,-16
    80004f7e:	e406                	sd	ra,8(sp)
    80004f80:	e022                	sd	s0,0(sp)
    80004f82:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004f84:	00004597          	auipc	a1,0x4
    80004f88:	9c458593          	addi	a1,a1,-1596 # 80008948 <syscalls+0x2a8>
    80004f8c:	00025517          	auipc	a0,0x25
    80004f90:	82c50513          	addi	a0,a0,-2004 # 800297b8 <ftable>
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	b9e080e7          	jalr	-1122(ra) # 80000b32 <initlock>
}
    80004f9c:	60a2                	ld	ra,8(sp)
    80004f9e:	6402                	ld	s0,0(sp)
    80004fa0:	0141                	addi	sp,sp,16
    80004fa2:	8082                	ret

0000000080004fa4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004fa4:	1101                	addi	sp,sp,-32
    80004fa6:	ec06                	sd	ra,24(sp)
    80004fa8:	e822                	sd	s0,16(sp)
    80004faa:	e426                	sd	s1,8(sp)
    80004fac:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004fae:	00025517          	auipc	a0,0x25
    80004fb2:	80a50513          	addi	a0,a0,-2038 # 800297b8 <ftable>
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	c0c080e7          	jalr	-1012(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004fbe:	00025497          	auipc	s1,0x25
    80004fc2:	81248493          	addi	s1,s1,-2030 # 800297d0 <ftable+0x18>
    80004fc6:	00025717          	auipc	a4,0x25
    80004fca:	7aa70713          	addi	a4,a4,1962 # 8002a770 <ftable+0xfb8>
    if(f->ref == 0){
    80004fce:	40dc                	lw	a5,4(s1)
    80004fd0:	cf99                	beqz	a5,80004fee <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004fd2:	02848493          	addi	s1,s1,40
    80004fd6:	fee49ce3          	bne	s1,a4,80004fce <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004fda:	00024517          	auipc	a0,0x24
    80004fde:	7de50513          	addi	a0,a0,2014 # 800297b8 <ftable>
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	ca6080e7          	jalr	-858(ra) # 80000c88 <release>
  return 0;
    80004fea:	4481                	li	s1,0
    80004fec:	a819                	j	80005002 <filealloc+0x5e>
      f->ref = 1;
    80004fee:	4785                	li	a5,1
    80004ff0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ff2:	00024517          	auipc	a0,0x24
    80004ff6:	7c650513          	addi	a0,a0,1990 # 800297b8 <ftable>
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	c8e080e7          	jalr	-882(ra) # 80000c88 <release>
}
    80005002:	8526                	mv	a0,s1
    80005004:	60e2                	ld	ra,24(sp)
    80005006:	6442                	ld	s0,16(sp)
    80005008:	64a2                	ld	s1,8(sp)
    8000500a:	6105                	addi	sp,sp,32
    8000500c:	8082                	ret

000000008000500e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000500e:	1101                	addi	sp,sp,-32
    80005010:	ec06                	sd	ra,24(sp)
    80005012:	e822                	sd	s0,16(sp)
    80005014:	e426                	sd	s1,8(sp)
    80005016:	1000                	addi	s0,sp,32
    80005018:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000501a:	00024517          	auipc	a0,0x24
    8000501e:	79e50513          	addi	a0,a0,1950 # 800297b8 <ftable>
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	ba0080e7          	jalr	-1120(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000502a:	40dc                	lw	a5,4(s1)
    8000502c:	02f05263          	blez	a5,80005050 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005030:	2785                	addiw	a5,a5,1
    80005032:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005034:	00024517          	auipc	a0,0x24
    80005038:	78450513          	addi	a0,a0,1924 # 800297b8 <ftable>
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	c4c080e7          	jalr	-948(ra) # 80000c88 <release>
  return f;
}
    80005044:	8526                	mv	a0,s1
    80005046:	60e2                	ld	ra,24(sp)
    80005048:	6442                	ld	s0,16(sp)
    8000504a:	64a2                	ld	s1,8(sp)
    8000504c:	6105                	addi	sp,sp,32
    8000504e:	8082                	ret
    panic("filedup");
    80005050:	00004517          	auipc	a0,0x4
    80005054:	90050513          	addi	a0,a0,-1792 # 80008950 <syscalls+0x2b0>
    80005058:	ffffb097          	auipc	ra,0xffffb
    8000505c:	4d2080e7          	jalr	1234(ra) # 8000052a <panic>

0000000080005060 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005060:	7139                	addi	sp,sp,-64
    80005062:	fc06                	sd	ra,56(sp)
    80005064:	f822                	sd	s0,48(sp)
    80005066:	f426                	sd	s1,40(sp)
    80005068:	f04a                	sd	s2,32(sp)
    8000506a:	ec4e                	sd	s3,24(sp)
    8000506c:	e852                	sd	s4,16(sp)
    8000506e:	e456                	sd	s5,8(sp)
    80005070:	0080                	addi	s0,sp,64
    80005072:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005074:	00024517          	auipc	a0,0x24
    80005078:	74450513          	addi	a0,a0,1860 # 800297b8 <ftable>
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	b46080e7          	jalr	-1210(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005084:	40dc                	lw	a5,4(s1)
    80005086:	06f05163          	blez	a5,800050e8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000508a:	37fd                	addiw	a5,a5,-1
    8000508c:	0007871b          	sext.w	a4,a5
    80005090:	c0dc                	sw	a5,4(s1)
    80005092:	06e04363          	bgtz	a4,800050f8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005096:	0004a903          	lw	s2,0(s1)
    8000509a:	0094ca83          	lbu	s5,9(s1)
    8000509e:	0104ba03          	ld	s4,16(s1)
    800050a2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800050a6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800050aa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800050ae:	00024517          	auipc	a0,0x24
    800050b2:	70a50513          	addi	a0,a0,1802 # 800297b8 <ftable>
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	bd2080e7          	jalr	-1070(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    800050be:	4785                	li	a5,1
    800050c0:	04f90d63          	beq	s2,a5,8000511a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800050c4:	3979                	addiw	s2,s2,-2
    800050c6:	4785                	li	a5,1
    800050c8:	0527e063          	bltu	a5,s2,80005108 <fileclose+0xa8>
    begin_op();
    800050cc:	00000097          	auipc	ra,0x0
    800050d0:	ac8080e7          	jalr	-1336(ra) # 80004b94 <begin_op>
    iput(ff.ip);
    800050d4:	854e                	mv	a0,s3
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	f90080e7          	jalr	-112(ra) # 80004066 <iput>
    end_op();
    800050de:	00000097          	auipc	ra,0x0
    800050e2:	b36080e7          	jalr	-1226(ra) # 80004c14 <end_op>
    800050e6:	a00d                	j	80005108 <fileclose+0xa8>
    panic("fileclose");
    800050e8:	00004517          	auipc	a0,0x4
    800050ec:	87050513          	addi	a0,a0,-1936 # 80008958 <syscalls+0x2b8>
    800050f0:	ffffb097          	auipc	ra,0xffffb
    800050f4:	43a080e7          	jalr	1082(ra) # 8000052a <panic>
    release(&ftable.lock);
    800050f8:	00024517          	auipc	a0,0x24
    800050fc:	6c050513          	addi	a0,a0,1728 # 800297b8 <ftable>
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	b88080e7          	jalr	-1144(ra) # 80000c88 <release>
  }
}
    80005108:	70e2                	ld	ra,56(sp)
    8000510a:	7442                	ld	s0,48(sp)
    8000510c:	74a2                	ld	s1,40(sp)
    8000510e:	7902                	ld	s2,32(sp)
    80005110:	69e2                	ld	s3,24(sp)
    80005112:	6a42                	ld	s4,16(sp)
    80005114:	6aa2                	ld	s5,8(sp)
    80005116:	6121                	addi	sp,sp,64
    80005118:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000511a:	85d6                	mv	a1,s5
    8000511c:	8552                	mv	a0,s4
    8000511e:	00000097          	auipc	ra,0x0
    80005122:	542080e7          	jalr	1346(ra) # 80005660 <pipeclose>
    80005126:	b7cd                	j	80005108 <fileclose+0xa8>

0000000080005128 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005128:	715d                	addi	sp,sp,-80
    8000512a:	e486                	sd	ra,72(sp)
    8000512c:	e0a2                	sd	s0,64(sp)
    8000512e:	fc26                	sd	s1,56(sp)
    80005130:	f84a                	sd	s2,48(sp)
    80005132:	f44e                	sd	s3,40(sp)
    80005134:	0880                	addi	s0,sp,80
    80005136:	84aa                	mv	s1,a0
    80005138:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	8ac080e7          	jalr	-1876(ra) # 800019e6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005142:	409c                	lw	a5,0(s1)
    80005144:	37f9                	addiw	a5,a5,-2
    80005146:	4705                	li	a4,1
    80005148:	04f76763          	bltu	a4,a5,80005196 <filestat+0x6e>
    8000514c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000514e:	6c88                	ld	a0,24(s1)
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	d5c080e7          	jalr	-676(ra) # 80003eac <ilock>
    stati(f->ip, &st);
    80005158:	fb840593          	addi	a1,s0,-72
    8000515c:	6c88                	ld	a0,24(s1)
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	fd8080e7          	jalr	-40(ra) # 80004136 <stati>
    iunlock(f->ip);
    80005166:	6c88                	ld	a0,24(s1)
    80005168:	fffff097          	auipc	ra,0xfffff
    8000516c:	e06080e7          	jalr	-506(ra) # 80003f6e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005170:	46e1                	li	a3,24
    80005172:	fb840613          	addi	a2,s0,-72
    80005176:	85ce                	mv	a1,s3
    80005178:	05093503          	ld	a0,80(s2)
    8000517c:	ffffc097          	auipc	ra,0xffffc
    80005180:	52a080e7          	jalr	1322(ra) # 800016a6 <copyout>
    80005184:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005188:	60a6                	ld	ra,72(sp)
    8000518a:	6406                	ld	s0,64(sp)
    8000518c:	74e2                	ld	s1,56(sp)
    8000518e:	7942                	ld	s2,48(sp)
    80005190:	79a2                	ld	s3,40(sp)
    80005192:	6161                	addi	sp,sp,80
    80005194:	8082                	ret
  return -1;
    80005196:	557d                	li	a0,-1
    80005198:	bfc5                	j	80005188 <filestat+0x60>

000000008000519a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000519a:	7179                	addi	sp,sp,-48
    8000519c:	f406                	sd	ra,40(sp)
    8000519e:	f022                	sd	s0,32(sp)
    800051a0:	ec26                	sd	s1,24(sp)
    800051a2:	e84a                	sd	s2,16(sp)
    800051a4:	e44e                	sd	s3,8(sp)
    800051a6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800051a8:	00854783          	lbu	a5,8(a0)
    800051ac:	c3d5                	beqz	a5,80005250 <fileread+0xb6>
    800051ae:	84aa                	mv	s1,a0
    800051b0:	89ae                	mv	s3,a1
    800051b2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800051b4:	411c                	lw	a5,0(a0)
    800051b6:	4705                	li	a4,1
    800051b8:	04e78963          	beq	a5,a4,8000520a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051bc:	470d                	li	a4,3
    800051be:	04e78d63          	beq	a5,a4,80005218 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800051c2:	4709                	li	a4,2
    800051c4:	06e79e63          	bne	a5,a4,80005240 <fileread+0xa6>
    ilock(f->ip);
    800051c8:	6d08                	ld	a0,24(a0)
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	ce2080e7          	jalr	-798(ra) # 80003eac <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800051d2:	874a                	mv	a4,s2
    800051d4:	5094                	lw	a3,32(s1)
    800051d6:	864e                	mv	a2,s3
    800051d8:	4585                	li	a1,1
    800051da:	6c88                	ld	a0,24(s1)
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	f84080e7          	jalr	-124(ra) # 80004160 <readi>
    800051e4:	892a                	mv	s2,a0
    800051e6:	00a05563          	blez	a0,800051f0 <fileread+0x56>
      f->off += r;
    800051ea:	509c                	lw	a5,32(s1)
    800051ec:	9fa9                	addw	a5,a5,a0
    800051ee:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800051f0:	6c88                	ld	a0,24(s1)
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	d7c080e7          	jalr	-644(ra) # 80003f6e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800051fa:	854a                	mv	a0,s2
    800051fc:	70a2                	ld	ra,40(sp)
    800051fe:	7402                	ld	s0,32(sp)
    80005200:	64e2                	ld	s1,24(sp)
    80005202:	6942                	ld	s2,16(sp)
    80005204:	69a2                	ld	s3,8(sp)
    80005206:	6145                	addi	sp,sp,48
    80005208:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000520a:	6908                	ld	a0,16(a0)
    8000520c:	00000097          	auipc	ra,0x0
    80005210:	5b6080e7          	jalr	1462(ra) # 800057c2 <piperead>
    80005214:	892a                	mv	s2,a0
    80005216:	b7d5                	j	800051fa <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005218:	02451783          	lh	a5,36(a0)
    8000521c:	03079693          	slli	a3,a5,0x30
    80005220:	92c1                	srli	a3,a3,0x30
    80005222:	4725                	li	a4,9
    80005224:	02d76863          	bltu	a4,a3,80005254 <fileread+0xba>
    80005228:	0792                	slli	a5,a5,0x4
    8000522a:	00024717          	auipc	a4,0x24
    8000522e:	4ee70713          	addi	a4,a4,1262 # 80029718 <devsw>
    80005232:	97ba                	add	a5,a5,a4
    80005234:	639c                	ld	a5,0(a5)
    80005236:	c38d                	beqz	a5,80005258 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005238:	4505                	li	a0,1
    8000523a:	9782                	jalr	a5
    8000523c:	892a                	mv	s2,a0
    8000523e:	bf75                	j	800051fa <fileread+0x60>
    panic("fileread");
    80005240:	00003517          	auipc	a0,0x3
    80005244:	72850513          	addi	a0,a0,1832 # 80008968 <syscalls+0x2c8>
    80005248:	ffffb097          	auipc	ra,0xffffb
    8000524c:	2e2080e7          	jalr	738(ra) # 8000052a <panic>
    return -1;
    80005250:	597d                	li	s2,-1
    80005252:	b765                	j	800051fa <fileread+0x60>
      return -1;
    80005254:	597d                	li	s2,-1
    80005256:	b755                	j	800051fa <fileread+0x60>
    80005258:	597d                	li	s2,-1
    8000525a:	b745                	j	800051fa <fileread+0x60>

000000008000525c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000525c:	715d                	addi	sp,sp,-80
    8000525e:	e486                	sd	ra,72(sp)
    80005260:	e0a2                	sd	s0,64(sp)
    80005262:	fc26                	sd	s1,56(sp)
    80005264:	f84a                	sd	s2,48(sp)
    80005266:	f44e                	sd	s3,40(sp)
    80005268:	f052                	sd	s4,32(sp)
    8000526a:	ec56                	sd	s5,24(sp)
    8000526c:	e85a                	sd	s6,16(sp)
    8000526e:	e45e                	sd	s7,8(sp)
    80005270:	e062                	sd	s8,0(sp)
    80005272:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005274:	00954783          	lbu	a5,9(a0)
    80005278:	10078663          	beqz	a5,80005384 <filewrite+0x128>
    8000527c:	892a                	mv	s2,a0
    8000527e:	8aae                	mv	s5,a1
    80005280:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005282:	411c                	lw	a5,0(a0)
    80005284:	4705                	li	a4,1
    80005286:	02e78263          	beq	a5,a4,800052aa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000528a:	470d                	li	a4,3
    8000528c:	02e78663          	beq	a5,a4,800052b8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005290:	4709                	li	a4,2
    80005292:	0ee79163          	bne	a5,a4,80005374 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005296:	0ac05d63          	blez	a2,80005350 <filewrite+0xf4>
    int i = 0;
    8000529a:	4981                	li	s3,0
    8000529c:	6b05                	lui	s6,0x1
    8000529e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800052a2:	6b85                	lui	s7,0x1
    800052a4:	c00b8b9b          	addiw	s7,s7,-1024
    800052a8:	a861                	j	80005340 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800052aa:	6908                	ld	a0,16(a0)
    800052ac:	00000097          	auipc	ra,0x0
    800052b0:	424080e7          	jalr	1060(ra) # 800056d0 <pipewrite>
    800052b4:	8a2a                	mv	s4,a0
    800052b6:	a045                	j	80005356 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800052b8:	02451783          	lh	a5,36(a0)
    800052bc:	03079693          	slli	a3,a5,0x30
    800052c0:	92c1                	srli	a3,a3,0x30
    800052c2:	4725                	li	a4,9
    800052c4:	0cd76263          	bltu	a4,a3,80005388 <filewrite+0x12c>
    800052c8:	0792                	slli	a5,a5,0x4
    800052ca:	00024717          	auipc	a4,0x24
    800052ce:	44e70713          	addi	a4,a4,1102 # 80029718 <devsw>
    800052d2:	97ba                	add	a5,a5,a4
    800052d4:	679c                	ld	a5,8(a5)
    800052d6:	cbdd                	beqz	a5,8000538c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800052d8:	4505                	li	a0,1
    800052da:	9782                	jalr	a5
    800052dc:	8a2a                	mv	s4,a0
    800052de:	a8a5                	j	80005356 <filewrite+0xfa>
    800052e0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800052e4:	00000097          	auipc	ra,0x0
    800052e8:	8b0080e7          	jalr	-1872(ra) # 80004b94 <begin_op>
      ilock(f->ip);
    800052ec:	01893503          	ld	a0,24(s2)
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	bbc080e7          	jalr	-1092(ra) # 80003eac <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800052f8:	8762                	mv	a4,s8
    800052fa:	02092683          	lw	a3,32(s2)
    800052fe:	01598633          	add	a2,s3,s5
    80005302:	4585                	li	a1,1
    80005304:	01893503          	ld	a0,24(s2)
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	f50080e7          	jalr	-176(ra) # 80004258 <writei>
    80005310:	84aa                	mv	s1,a0
    80005312:	00a05763          	blez	a0,80005320 <filewrite+0xc4>
        f->off += r;
    80005316:	02092783          	lw	a5,32(s2)
    8000531a:	9fa9                	addw	a5,a5,a0
    8000531c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005320:	01893503          	ld	a0,24(s2)
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	c4a080e7          	jalr	-950(ra) # 80003f6e <iunlock>
      end_op();
    8000532c:	00000097          	auipc	ra,0x0
    80005330:	8e8080e7          	jalr	-1816(ra) # 80004c14 <end_op>

      if(r != n1){
    80005334:	009c1f63          	bne	s8,s1,80005352 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005338:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000533c:	0149db63          	bge	s3,s4,80005352 <filewrite+0xf6>
      int n1 = n - i;
    80005340:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005344:	84be                	mv	s1,a5
    80005346:	2781                	sext.w	a5,a5
    80005348:	f8fb5ce3          	bge	s6,a5,800052e0 <filewrite+0x84>
    8000534c:	84de                	mv	s1,s7
    8000534e:	bf49                	j	800052e0 <filewrite+0x84>
    int i = 0;
    80005350:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005352:	013a1f63          	bne	s4,s3,80005370 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005356:	8552                	mv	a0,s4
    80005358:	60a6                	ld	ra,72(sp)
    8000535a:	6406                	ld	s0,64(sp)
    8000535c:	74e2                	ld	s1,56(sp)
    8000535e:	7942                	ld	s2,48(sp)
    80005360:	79a2                	ld	s3,40(sp)
    80005362:	7a02                	ld	s4,32(sp)
    80005364:	6ae2                	ld	s5,24(sp)
    80005366:	6b42                	ld	s6,16(sp)
    80005368:	6ba2                	ld	s7,8(sp)
    8000536a:	6c02                	ld	s8,0(sp)
    8000536c:	6161                	addi	sp,sp,80
    8000536e:	8082                	ret
    ret = (i == n ? n : -1);
    80005370:	5a7d                	li	s4,-1
    80005372:	b7d5                	j	80005356 <filewrite+0xfa>
    panic("filewrite");
    80005374:	00003517          	auipc	a0,0x3
    80005378:	60450513          	addi	a0,a0,1540 # 80008978 <syscalls+0x2d8>
    8000537c:	ffffb097          	auipc	ra,0xffffb
    80005380:	1ae080e7          	jalr	430(ra) # 8000052a <panic>
    return -1;
    80005384:	5a7d                	li	s4,-1
    80005386:	bfc1                	j	80005356 <filewrite+0xfa>
      return -1;
    80005388:	5a7d                	li	s4,-1
    8000538a:	b7f1                	j	80005356 <filewrite+0xfa>
    8000538c:	5a7d                	li	s4,-1
    8000538e:	b7e1                	j	80005356 <filewrite+0xfa>

0000000080005390 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80005390:	7179                	addi	sp,sp,-48
    80005392:	f406                	sd	ra,40(sp)
    80005394:	f022                	sd	s0,32(sp)
    80005396:	ec26                	sd	s1,24(sp)
    80005398:	e84a                	sd	s2,16(sp)
    8000539a:	e44e                	sd	s3,8(sp)
    8000539c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000539e:	00854783          	lbu	a5,8(a0)
    800053a2:	c3d5                	beqz	a5,80005446 <kfileread+0xb6>
    800053a4:	84aa                	mv	s1,a0
    800053a6:	89ae                	mv	s3,a1
    800053a8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800053aa:	411c                	lw	a5,0(a0)
    800053ac:	4705                	li	a4,1
    800053ae:	04e78963          	beq	a5,a4,80005400 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053b2:	470d                	li	a4,3
    800053b4:	04e78d63          	beq	a5,a4,8000540e <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800053b8:	4709                	li	a4,2
    800053ba:	06e79e63          	bne	a5,a4,80005436 <kfileread+0xa6>
    ilock(f->ip);
    800053be:	6d08                	ld	a0,24(a0)
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	aec080e7          	jalr	-1300(ra) # 80003eac <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800053c8:	874a                	mv	a4,s2
    800053ca:	5094                	lw	a3,32(s1)
    800053cc:	864e                	mv	a2,s3
    800053ce:	4581                	li	a1,0
    800053d0:	6c88                	ld	a0,24(s1)
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	d8e080e7          	jalr	-626(ra) # 80004160 <readi>
    800053da:	892a                	mv	s2,a0
    800053dc:	00a05563          	blez	a0,800053e6 <kfileread+0x56>
      f->off += r;
    800053e0:	509c                	lw	a5,32(s1)
    800053e2:	9fa9                	addw	a5,a5,a0
    800053e4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800053e6:	6c88                	ld	a0,24(s1)
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	b86080e7          	jalr	-1146(ra) # 80003f6e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800053f0:	854a                	mv	a0,s2
    800053f2:	70a2                	ld	ra,40(sp)
    800053f4:	7402                	ld	s0,32(sp)
    800053f6:	64e2                	ld	s1,24(sp)
    800053f8:	6942                	ld	s2,16(sp)
    800053fa:	69a2                	ld	s3,8(sp)
    800053fc:	6145                	addi	sp,sp,48
    800053fe:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005400:	6908                	ld	a0,16(a0)
    80005402:	00000097          	auipc	ra,0x0
    80005406:	3c0080e7          	jalr	960(ra) # 800057c2 <piperead>
    8000540a:	892a                	mv	s2,a0
    8000540c:	b7d5                	j	800053f0 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000540e:	02451783          	lh	a5,36(a0)
    80005412:	03079693          	slli	a3,a5,0x30
    80005416:	92c1                	srli	a3,a3,0x30
    80005418:	4725                	li	a4,9
    8000541a:	02d76863          	bltu	a4,a3,8000544a <kfileread+0xba>
    8000541e:	0792                	slli	a5,a5,0x4
    80005420:	00024717          	auipc	a4,0x24
    80005424:	2f870713          	addi	a4,a4,760 # 80029718 <devsw>
    80005428:	97ba                	add	a5,a5,a4
    8000542a:	639c                	ld	a5,0(a5)
    8000542c:	c38d                	beqz	a5,8000544e <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000542e:	4505                	li	a0,1
    80005430:	9782                	jalr	a5
    80005432:	892a                	mv	s2,a0
    80005434:	bf75                	j	800053f0 <kfileread+0x60>
    panic("fileread");
    80005436:	00003517          	auipc	a0,0x3
    8000543a:	53250513          	addi	a0,a0,1330 # 80008968 <syscalls+0x2c8>
    8000543e:	ffffb097          	auipc	ra,0xffffb
    80005442:	0ec080e7          	jalr	236(ra) # 8000052a <panic>
    return -1;
    80005446:	597d                	li	s2,-1
    80005448:	b765                	j	800053f0 <kfileread+0x60>
      return -1;
    8000544a:	597d                	li	s2,-1
    8000544c:	b755                	j	800053f0 <kfileread+0x60>
    8000544e:	597d                	li	s2,-1
    80005450:	b745                	j	800053f0 <kfileread+0x60>

0000000080005452 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005452:	715d                	addi	sp,sp,-80
    80005454:	e486                	sd	ra,72(sp)
    80005456:	e0a2                	sd	s0,64(sp)
    80005458:	fc26                	sd	s1,56(sp)
    8000545a:	f84a                	sd	s2,48(sp)
    8000545c:	f44e                	sd	s3,40(sp)
    8000545e:	f052                	sd	s4,32(sp)
    80005460:	ec56                	sd	s5,24(sp)
    80005462:	e85a                	sd	s6,16(sp)
    80005464:	e45e                	sd	s7,8(sp)
    80005466:	e062                	sd	s8,0(sp)
    80005468:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000546a:	00954783          	lbu	a5,9(a0)
    8000546e:	10078663          	beqz	a5,8000557a <kfilewrite+0x128>
    80005472:	892a                	mv	s2,a0
    80005474:	8aae                	mv	s5,a1
    80005476:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005478:	411c                	lw	a5,0(a0)
    8000547a:	4705                	li	a4,1
    8000547c:	02e78263          	beq	a5,a4,800054a0 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005480:	470d                	li	a4,3
    80005482:	02e78663          	beq	a5,a4,800054ae <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005486:	4709                	li	a4,2
    80005488:	0ee79163          	bne	a5,a4,8000556a <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000548c:	0ac05d63          	blez	a2,80005546 <kfilewrite+0xf4>
    int i = 0;
    80005490:	4981                	li	s3,0
    80005492:	6b05                	lui	s6,0x1
    80005494:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005498:	6b85                	lui	s7,0x1
    8000549a:	c00b8b9b          	addiw	s7,s7,-1024
    8000549e:	a861                	j	80005536 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800054a0:	6908                	ld	a0,16(a0)
    800054a2:	00000097          	auipc	ra,0x0
    800054a6:	22e080e7          	jalr	558(ra) # 800056d0 <pipewrite>
    800054aa:	8a2a                	mv	s4,a0
    800054ac:	a045                	j	8000554c <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800054ae:	02451783          	lh	a5,36(a0)
    800054b2:	03079693          	slli	a3,a5,0x30
    800054b6:	92c1                	srli	a3,a3,0x30
    800054b8:	4725                	li	a4,9
    800054ba:	0cd76263          	bltu	a4,a3,8000557e <kfilewrite+0x12c>
    800054be:	0792                	slli	a5,a5,0x4
    800054c0:	00024717          	auipc	a4,0x24
    800054c4:	25870713          	addi	a4,a4,600 # 80029718 <devsw>
    800054c8:	97ba                	add	a5,a5,a4
    800054ca:	679c                	ld	a5,8(a5)
    800054cc:	cbdd                	beqz	a5,80005582 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800054ce:	4505                	li	a0,1
    800054d0:	9782                	jalr	a5
    800054d2:	8a2a                	mv	s4,a0
    800054d4:	a8a5                	j	8000554c <kfilewrite+0xfa>
    800054d6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	6ba080e7          	jalr	1722(ra) # 80004b94 <begin_op>
      ilock(f->ip);
    800054e2:	01893503          	ld	a0,24(s2)
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	9c6080e7          	jalr	-1594(ra) # 80003eac <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800054ee:	8762                	mv	a4,s8
    800054f0:	02092683          	lw	a3,32(s2)
    800054f4:	01598633          	add	a2,s3,s5
    800054f8:	4581                	li	a1,0
    800054fa:	01893503          	ld	a0,24(s2)
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	d5a080e7          	jalr	-678(ra) # 80004258 <writei>
    80005506:	84aa                	mv	s1,a0
    80005508:	00a05763          	blez	a0,80005516 <kfilewrite+0xc4>
        f->off += r;
    8000550c:	02092783          	lw	a5,32(s2)
    80005510:	9fa9                	addw	a5,a5,a0
    80005512:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005516:	01893503          	ld	a0,24(s2)
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	a54080e7          	jalr	-1452(ra) # 80003f6e <iunlock>
      end_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	6f2080e7          	jalr	1778(ra) # 80004c14 <end_op>

      if(r != n1){
    8000552a:	009c1f63          	bne	s8,s1,80005548 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000552e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005532:	0149db63          	bge	s3,s4,80005548 <kfilewrite+0xf6>
      int n1 = n - i;
    80005536:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000553a:	84be                	mv	s1,a5
    8000553c:	2781                	sext.w	a5,a5
    8000553e:	f8fb5ce3          	bge	s6,a5,800054d6 <kfilewrite+0x84>
    80005542:	84de                	mv	s1,s7
    80005544:	bf49                	j	800054d6 <kfilewrite+0x84>
    int i = 0;
    80005546:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005548:	013a1f63          	bne	s4,s3,80005566 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    8000554c:	8552                	mv	a0,s4
    8000554e:	60a6                	ld	ra,72(sp)
    80005550:	6406                	ld	s0,64(sp)
    80005552:	74e2                	ld	s1,56(sp)
    80005554:	7942                	ld	s2,48(sp)
    80005556:	79a2                	ld	s3,40(sp)
    80005558:	7a02                	ld	s4,32(sp)
    8000555a:	6ae2                	ld	s5,24(sp)
    8000555c:	6b42                	ld	s6,16(sp)
    8000555e:	6ba2                	ld	s7,8(sp)
    80005560:	6c02                	ld	s8,0(sp)
    80005562:	6161                	addi	sp,sp,80
    80005564:	8082                	ret
    ret = (i == n ? n : -1);
    80005566:	5a7d                	li	s4,-1
    80005568:	b7d5                	j	8000554c <kfilewrite+0xfa>
    panic("filewrite");
    8000556a:	00003517          	auipc	a0,0x3
    8000556e:	40e50513          	addi	a0,a0,1038 # 80008978 <syscalls+0x2d8>
    80005572:	ffffb097          	auipc	ra,0xffffb
    80005576:	fb8080e7          	jalr	-72(ra) # 8000052a <panic>
    return -1;
    8000557a:	5a7d                	li	s4,-1
    8000557c:	bfc1                	j	8000554c <kfilewrite+0xfa>
      return -1;
    8000557e:	5a7d                	li	s4,-1
    80005580:	b7f1                	j	8000554c <kfilewrite+0xfa>
    80005582:	5a7d                	li	s4,-1
    80005584:	b7e1                	j	8000554c <kfilewrite+0xfa>

0000000080005586 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005586:	7179                	addi	sp,sp,-48
    80005588:	f406                	sd	ra,40(sp)
    8000558a:	f022                	sd	s0,32(sp)
    8000558c:	ec26                	sd	s1,24(sp)
    8000558e:	e84a                	sd	s2,16(sp)
    80005590:	e44e                	sd	s3,8(sp)
    80005592:	e052                	sd	s4,0(sp)
    80005594:	1800                	addi	s0,sp,48
    80005596:	84aa                	mv	s1,a0
    80005598:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000559a:	0005b023          	sd	zero,0(a1)
    8000559e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800055a2:	00000097          	auipc	ra,0x0
    800055a6:	a02080e7          	jalr	-1534(ra) # 80004fa4 <filealloc>
    800055aa:	e088                	sd	a0,0(s1)
    800055ac:	c551                	beqz	a0,80005638 <pipealloc+0xb2>
    800055ae:	00000097          	auipc	ra,0x0
    800055b2:	9f6080e7          	jalr	-1546(ra) # 80004fa4 <filealloc>
    800055b6:	00aa3023          	sd	a0,0(s4)
    800055ba:	c92d                	beqz	a0,8000562c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800055bc:	ffffb097          	auipc	ra,0xffffb
    800055c0:	516080e7          	jalr	1302(ra) # 80000ad2 <kalloc>
    800055c4:	892a                	mv	s2,a0
    800055c6:	c125                	beqz	a0,80005626 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800055c8:	4985                	li	s3,1
    800055ca:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800055ce:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800055d2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800055d6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800055da:	00003597          	auipc	a1,0x3
    800055de:	3ae58593          	addi	a1,a1,942 # 80008988 <syscalls+0x2e8>
    800055e2:	ffffb097          	auipc	ra,0xffffb
    800055e6:	550080e7          	jalr	1360(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800055ea:	609c                	ld	a5,0(s1)
    800055ec:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800055f0:	609c                	ld	a5,0(s1)
    800055f2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800055f6:	609c                	ld	a5,0(s1)
    800055f8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800055fc:	609c                	ld	a5,0(s1)
    800055fe:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005602:	000a3783          	ld	a5,0(s4)
    80005606:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000560a:	000a3783          	ld	a5,0(s4)
    8000560e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005612:	000a3783          	ld	a5,0(s4)
    80005616:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000561a:	000a3783          	ld	a5,0(s4)
    8000561e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005622:	4501                	li	a0,0
    80005624:	a025                	j	8000564c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005626:	6088                	ld	a0,0(s1)
    80005628:	e501                	bnez	a0,80005630 <pipealloc+0xaa>
    8000562a:	a039                	j	80005638 <pipealloc+0xb2>
    8000562c:	6088                	ld	a0,0(s1)
    8000562e:	c51d                	beqz	a0,8000565c <pipealloc+0xd6>
    fileclose(*f0);
    80005630:	00000097          	auipc	ra,0x0
    80005634:	a30080e7          	jalr	-1488(ra) # 80005060 <fileclose>
  if(*f1)
    80005638:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000563c:	557d                	li	a0,-1
  if(*f1)
    8000563e:	c799                	beqz	a5,8000564c <pipealloc+0xc6>
    fileclose(*f1);
    80005640:	853e                	mv	a0,a5
    80005642:	00000097          	auipc	ra,0x0
    80005646:	a1e080e7          	jalr	-1506(ra) # 80005060 <fileclose>
  return -1;
    8000564a:	557d                	li	a0,-1
}
    8000564c:	70a2                	ld	ra,40(sp)
    8000564e:	7402                	ld	s0,32(sp)
    80005650:	64e2                	ld	s1,24(sp)
    80005652:	6942                	ld	s2,16(sp)
    80005654:	69a2                	ld	s3,8(sp)
    80005656:	6a02                	ld	s4,0(sp)
    80005658:	6145                	addi	sp,sp,48
    8000565a:	8082                	ret
  return -1;
    8000565c:	557d                	li	a0,-1
    8000565e:	b7fd                	j	8000564c <pipealloc+0xc6>

0000000080005660 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005660:	1101                	addi	sp,sp,-32
    80005662:	ec06                	sd	ra,24(sp)
    80005664:	e822                	sd	s0,16(sp)
    80005666:	e426                	sd	s1,8(sp)
    80005668:	e04a                	sd	s2,0(sp)
    8000566a:	1000                	addi	s0,sp,32
    8000566c:	84aa                	mv	s1,a0
    8000566e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005670:	ffffb097          	auipc	ra,0xffffb
    80005674:	552080e7          	jalr	1362(ra) # 80000bc2 <acquire>
  if(writable){
    80005678:	02090d63          	beqz	s2,800056b2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000567c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005680:	21848513          	addi	a0,s1,536
    80005684:	ffffd097          	auipc	ra,0xffffd
    80005688:	914080e7          	jalr	-1772(ra) # 80001f98 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000568c:	2204b783          	ld	a5,544(s1)
    80005690:	eb95                	bnez	a5,800056c4 <pipeclose+0x64>
    release(&pi->lock);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffb097          	auipc	ra,0xffffb
    80005698:	5f4080e7          	jalr	1524(ra) # 80000c88 <release>
    kfree((char*)pi);
    8000569c:	8526                	mv	a0,s1
    8000569e:	ffffb097          	auipc	ra,0xffffb
    800056a2:	338080e7          	jalr	824(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800056a6:	60e2                	ld	ra,24(sp)
    800056a8:	6442                	ld	s0,16(sp)
    800056aa:	64a2                	ld	s1,8(sp)
    800056ac:	6902                	ld	s2,0(sp)
    800056ae:	6105                	addi	sp,sp,32
    800056b0:	8082                	ret
    pi->readopen = 0;
    800056b2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800056b6:	21c48513          	addi	a0,s1,540
    800056ba:	ffffd097          	auipc	ra,0xffffd
    800056be:	8de080e7          	jalr	-1826(ra) # 80001f98 <wakeup>
    800056c2:	b7e9                	j	8000568c <pipeclose+0x2c>
    release(&pi->lock);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffb097          	auipc	ra,0xffffb
    800056ca:	5c2080e7          	jalr	1474(ra) # 80000c88 <release>
}
    800056ce:	bfe1                	j	800056a6 <pipeclose+0x46>

00000000800056d0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800056d0:	711d                	addi	sp,sp,-96
    800056d2:	ec86                	sd	ra,88(sp)
    800056d4:	e8a2                	sd	s0,80(sp)
    800056d6:	e4a6                	sd	s1,72(sp)
    800056d8:	e0ca                	sd	s2,64(sp)
    800056da:	fc4e                	sd	s3,56(sp)
    800056dc:	f852                	sd	s4,48(sp)
    800056de:	f456                	sd	s5,40(sp)
    800056e0:	f05a                	sd	s6,32(sp)
    800056e2:	ec5e                	sd	s7,24(sp)
    800056e4:	e862                	sd	s8,16(sp)
    800056e6:	1080                	addi	s0,sp,96
    800056e8:	84aa                	mv	s1,a0
    800056ea:	8aae                	mv	s5,a1
    800056ec:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800056ee:	ffffc097          	auipc	ra,0xffffc
    800056f2:	2f8080e7          	jalr	760(ra) # 800019e6 <myproc>
    800056f6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffb097          	auipc	ra,0xffffb
    800056fe:	4c8080e7          	jalr	1224(ra) # 80000bc2 <acquire>
  while(i < n){
    80005702:	0b405363          	blez	s4,800057a8 <pipewrite+0xd8>
  int i = 0;
    80005706:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005708:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000570a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000570e:	21c48b93          	addi	s7,s1,540
    80005712:	a089                	j	80005754 <pipewrite+0x84>
      release(&pi->lock);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffb097          	auipc	ra,0xffffb
    8000571a:	572080e7          	jalr	1394(ra) # 80000c88 <release>
      return -1;
    8000571e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005720:	854a                	mv	a0,s2
    80005722:	60e6                	ld	ra,88(sp)
    80005724:	6446                	ld	s0,80(sp)
    80005726:	64a6                	ld	s1,72(sp)
    80005728:	6906                	ld	s2,64(sp)
    8000572a:	79e2                	ld	s3,56(sp)
    8000572c:	7a42                	ld	s4,48(sp)
    8000572e:	7aa2                	ld	s5,40(sp)
    80005730:	7b02                	ld	s6,32(sp)
    80005732:	6be2                	ld	s7,24(sp)
    80005734:	6c42                	ld	s8,16(sp)
    80005736:	6125                	addi	sp,sp,96
    80005738:	8082                	ret
      wakeup(&pi->nread);
    8000573a:	8562                	mv	a0,s8
    8000573c:	ffffd097          	auipc	ra,0xffffd
    80005740:	85c080e7          	jalr	-1956(ra) # 80001f98 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005744:	85a6                	mv	a1,s1
    80005746:	855e                	mv	a0,s7
    80005748:	ffffc097          	auipc	ra,0xffffc
    8000574c:	7ec080e7          	jalr	2028(ra) # 80001f34 <sleep>
  while(i < n){
    80005750:	05495d63          	bge	s2,s4,800057aa <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005754:	2204a783          	lw	a5,544(s1)
    80005758:	dfd5                	beqz	a5,80005714 <pipewrite+0x44>
    8000575a:	0289a783          	lw	a5,40(s3)
    8000575e:	fbdd                	bnez	a5,80005714 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005760:	2184a783          	lw	a5,536(s1)
    80005764:	21c4a703          	lw	a4,540(s1)
    80005768:	2007879b          	addiw	a5,a5,512
    8000576c:	fcf707e3          	beq	a4,a5,8000573a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005770:	4685                	li	a3,1
    80005772:	01590633          	add	a2,s2,s5
    80005776:	faf40593          	addi	a1,s0,-81
    8000577a:	0509b503          	ld	a0,80(s3)
    8000577e:	ffffc097          	auipc	ra,0xffffc
    80005782:	fb4080e7          	jalr	-76(ra) # 80001732 <copyin>
    80005786:	03650263          	beq	a0,s6,800057aa <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000578a:	21c4a783          	lw	a5,540(s1)
    8000578e:	0017871b          	addiw	a4,a5,1
    80005792:	20e4ae23          	sw	a4,540(s1)
    80005796:	1ff7f793          	andi	a5,a5,511
    8000579a:	97a6                	add	a5,a5,s1
    8000579c:	faf44703          	lbu	a4,-81(s0)
    800057a0:	00e78c23          	sb	a4,24(a5)
      i++;
    800057a4:	2905                	addiw	s2,s2,1
    800057a6:	b76d                	j	80005750 <pipewrite+0x80>
  int i = 0;
    800057a8:	4901                	li	s2,0
  wakeup(&pi->nread);
    800057aa:	21848513          	addi	a0,s1,536
    800057ae:	ffffc097          	auipc	ra,0xffffc
    800057b2:	7ea080e7          	jalr	2026(ra) # 80001f98 <wakeup>
  release(&pi->lock);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffb097          	auipc	ra,0xffffb
    800057bc:	4d0080e7          	jalr	1232(ra) # 80000c88 <release>
  return i;
    800057c0:	b785                	j	80005720 <pipewrite+0x50>

00000000800057c2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800057c2:	715d                	addi	sp,sp,-80
    800057c4:	e486                	sd	ra,72(sp)
    800057c6:	e0a2                	sd	s0,64(sp)
    800057c8:	fc26                	sd	s1,56(sp)
    800057ca:	f84a                	sd	s2,48(sp)
    800057cc:	f44e                	sd	s3,40(sp)
    800057ce:	f052                	sd	s4,32(sp)
    800057d0:	ec56                	sd	s5,24(sp)
    800057d2:	e85a                	sd	s6,16(sp)
    800057d4:	0880                	addi	s0,sp,80
    800057d6:	84aa                	mv	s1,a0
    800057d8:	892e                	mv	s2,a1
    800057da:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800057dc:	ffffc097          	auipc	ra,0xffffc
    800057e0:	20a080e7          	jalr	522(ra) # 800019e6 <myproc>
    800057e4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800057e6:	8526                	mv	a0,s1
    800057e8:	ffffb097          	auipc	ra,0xffffb
    800057ec:	3da080e7          	jalr	986(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057f0:	2184a703          	lw	a4,536(s1)
    800057f4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800057f8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057fc:	02f71463          	bne	a4,a5,80005824 <piperead+0x62>
    80005800:	2244a783          	lw	a5,548(s1)
    80005804:	c385                	beqz	a5,80005824 <piperead+0x62>
    if(pr->killed){
    80005806:	028a2783          	lw	a5,40(s4)
    8000580a:	ebc1                	bnez	a5,8000589a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000580c:	85a6                	mv	a1,s1
    8000580e:	854e                	mv	a0,s3
    80005810:	ffffc097          	auipc	ra,0xffffc
    80005814:	724080e7          	jalr	1828(ra) # 80001f34 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005818:	2184a703          	lw	a4,536(s1)
    8000581c:	21c4a783          	lw	a5,540(s1)
    80005820:	fef700e3          	beq	a4,a5,80005800 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005824:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005826:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005828:	05505363          	blez	s5,8000586e <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000582c:	2184a783          	lw	a5,536(s1)
    80005830:	21c4a703          	lw	a4,540(s1)
    80005834:	02f70d63          	beq	a4,a5,8000586e <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005838:	0017871b          	addiw	a4,a5,1
    8000583c:	20e4ac23          	sw	a4,536(s1)
    80005840:	1ff7f793          	andi	a5,a5,511
    80005844:	97a6                	add	a5,a5,s1
    80005846:	0187c783          	lbu	a5,24(a5)
    8000584a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000584e:	4685                	li	a3,1
    80005850:	fbf40613          	addi	a2,s0,-65
    80005854:	85ca                	mv	a1,s2
    80005856:	050a3503          	ld	a0,80(s4)
    8000585a:	ffffc097          	auipc	ra,0xffffc
    8000585e:	e4c080e7          	jalr	-436(ra) # 800016a6 <copyout>
    80005862:	01650663          	beq	a0,s6,8000586e <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005866:	2985                	addiw	s3,s3,1
    80005868:	0905                	addi	s2,s2,1
    8000586a:	fd3a91e3          	bne	s5,s3,8000582c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000586e:	21c48513          	addi	a0,s1,540
    80005872:	ffffc097          	auipc	ra,0xffffc
    80005876:	726080e7          	jalr	1830(ra) # 80001f98 <wakeup>
  release(&pi->lock);
    8000587a:	8526                	mv	a0,s1
    8000587c:	ffffb097          	auipc	ra,0xffffb
    80005880:	40c080e7          	jalr	1036(ra) # 80000c88 <release>
  return i;
}
    80005884:	854e                	mv	a0,s3
    80005886:	60a6                	ld	ra,72(sp)
    80005888:	6406                	ld	s0,64(sp)
    8000588a:	74e2                	ld	s1,56(sp)
    8000588c:	7942                	ld	s2,48(sp)
    8000588e:	79a2                	ld	s3,40(sp)
    80005890:	7a02                	ld	s4,32(sp)
    80005892:	6ae2                	ld	s5,24(sp)
    80005894:	6b42                	ld	s6,16(sp)
    80005896:	6161                	addi	sp,sp,80
    80005898:	8082                	ret
      release(&pi->lock);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	3ec080e7          	jalr	1004(ra) # 80000c88 <release>
      return -1;
    800058a4:	59fd                	li	s3,-1
    800058a6:	bff9                	j	80005884 <piperead+0xc2>

00000000800058a8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800058a8:	bd010113          	addi	sp,sp,-1072
    800058ac:	42113423          	sd	ra,1064(sp)
    800058b0:	42813023          	sd	s0,1056(sp)
    800058b4:	40913c23          	sd	s1,1048(sp)
    800058b8:	41213823          	sd	s2,1040(sp)
    800058bc:	41313423          	sd	s3,1032(sp)
    800058c0:	41413023          	sd	s4,1024(sp)
    800058c4:	3f513c23          	sd	s5,1016(sp)
    800058c8:	3f613823          	sd	s6,1008(sp)
    800058cc:	3f713423          	sd	s7,1000(sp)
    800058d0:	3f813023          	sd	s8,992(sp)
    800058d4:	3d913c23          	sd	s9,984(sp)
    800058d8:	3da13823          	sd	s10,976(sp)
    800058dc:	3db13423          	sd	s11,968(sp)
    800058e0:	43010413          	addi	s0,sp,1072
    800058e4:	89aa                	mv	s3,a0
    800058e6:	bea43023          	sd	a0,-1056(s0)
    800058ea:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800058ee:	ffffc097          	auipc	ra,0xffffc
    800058f2:	0f8080e7          	jalr	248(ra) # 800019e6 <myproc>
    800058f6:	84aa                	mv	s1,a0
    800058f8:	bea43c23          	sd	a0,-1032(s0)
  
  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_PSYC_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    800058fc:	17050913          	addi	s2,a0,368
    80005900:	10000613          	li	a2,256
    80005904:	85ca                	mv	a1,s2
    80005906:	d1040513          	addi	a0,s0,-752
    8000590a:	ffffb097          	auipc	ra,0xffffb
    8000590e:	422080e7          	jalr	1058(ra) # 80000d2c <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    80005912:	27048493          	addi	s1,s1,624
    80005916:	10000613          	li	a2,256
    8000591a:	85a6                	mv	a1,s1
    8000591c:	c1040513          	addi	a0,s0,-1008
    80005920:	ffffb097          	auipc	ra,0xffffb
    80005924:	40c080e7          	jalr	1036(ra) # 80000d2c <memmove>

  begin_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	26c080e7          	jalr	620(ra) # 80004b94 <begin_op>

  if((ip = namei(path)) == 0){
    80005930:	854e                	mv	a0,s3
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	d30080e7          	jalr	-720(ra) # 80004662 <namei>
    8000593a:	c555                	beqz	a0,800059e6 <exec+0x13e>
    8000593c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	56e080e7          	jalr	1390(ra) # 80003eac <ilock>
  // if(isSwapProc(p) && init_metadata(p) < 0){
  //   goto bad;
  // }

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005946:	04000713          	li	a4,64
    8000594a:	4681                	li	a3,0
    8000594c:	e4840613          	addi	a2,s0,-440
    80005950:	4581                	li	a1,0
    80005952:	8556                	mv	a0,s5
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	80c080e7          	jalr	-2036(ra) # 80004160 <readi>
    8000595c:	04000793          	li	a5,64
    80005960:	00f51a63          	bne	a0,a5,80005974 <exec+0xcc>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005964:	e4842703          	lw	a4,-440(s0)
    80005968:	464c47b7          	lui	a5,0x464c4
    8000596c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005970:	08f70163          	beq	a4,a5,800059f2 <exec+0x14a>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005974:	10000613          	li	a2,256
    80005978:	d1040593          	addi	a1,s0,-752
    8000597c:	854a                	mv	a0,s2
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	3ae080e7          	jalr	942(ra) # 80000d2c <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005986:	10000613          	li	a2,256
    8000598a:	c1040593          	addi	a1,s0,-1008
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffb097          	auipc	ra,0xffffb
    80005994:	39c080e7          	jalr	924(ra) # 80000d2c <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005998:	8556                	mv	a0,s5
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	774080e7          	jalr	1908(ra) # 8000410e <iunlockput>
    end_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	272080e7          	jalr	626(ra) # 80004c14 <end_op>
  }
  return -1;
    800059aa:	557d                	li	a0,-1
}
    800059ac:	42813083          	ld	ra,1064(sp)
    800059b0:	42013403          	ld	s0,1056(sp)
    800059b4:	41813483          	ld	s1,1048(sp)
    800059b8:	41013903          	ld	s2,1040(sp)
    800059bc:	40813983          	ld	s3,1032(sp)
    800059c0:	40013a03          	ld	s4,1024(sp)
    800059c4:	3f813a83          	ld	s5,1016(sp)
    800059c8:	3f013b03          	ld	s6,1008(sp)
    800059cc:	3e813b83          	ld	s7,1000(sp)
    800059d0:	3e013c03          	ld	s8,992(sp)
    800059d4:	3d813c83          	ld	s9,984(sp)
    800059d8:	3d013d03          	ld	s10,976(sp)
    800059dc:	3c813d83          	ld	s11,968(sp)
    800059e0:	43010113          	addi	sp,sp,1072
    800059e4:	8082                	ret
    end_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	22e080e7          	jalr	558(ra) # 80004c14 <end_op>
    return -1;
    800059ee:	557d                	li	a0,-1
    800059f0:	bf75                	j	800059ac <exec+0x104>
  if((pagetable = proc_pagetable(p)) == 0)
    800059f2:	bf843503          	ld	a0,-1032(s0)
    800059f6:	ffffc097          	auipc	ra,0xffffc
    800059fa:	0b4080e7          	jalr	180(ra) # 80001aaa <proc_pagetable>
    800059fe:	8b2a                	mv	s6,a0
    80005a00:	d935                	beqz	a0,80005974 <exec+0xcc>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a02:	e6842783          	lw	a5,-408(s0)
    80005a06:	e8045703          	lhu	a4,-384(s0)
    80005a0a:	c735                	beqz	a4,80005a76 <exec+0x1ce>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005a0c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a0e:	c0043423          	sd	zero,-1016(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005a12:	6a05                	lui	s4,0x1
    80005a14:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005a18:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005a1c:	6d85                	lui	s11,0x1
    80005a1e:	7d7d                	lui	s10,0xfffff
    80005a20:	a4ad                	j	80005c8a <exec+0x3e2>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005a22:	00003517          	auipc	a0,0x3
    80005a26:	f6e50513          	addi	a0,a0,-146 # 80008990 <syscalls+0x2f0>
    80005a2a:	ffffb097          	auipc	ra,0xffffb
    80005a2e:	b00080e7          	jalr	-1280(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005a32:	874a                	mv	a4,s2
    80005a34:	009c86bb          	addw	a3,s9,s1
    80005a38:	4581                	li	a1,0
    80005a3a:	8556                	mv	a0,s5
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	724080e7          	jalr	1828(ra) # 80004160 <readi>
    80005a44:	2501                	sext.w	a0,a0
    80005a46:	1aa91c63          	bne	s2,a0,80005bfe <exec+0x356>
  for(i = 0; i < sz; i += PGSIZE){
    80005a4a:	009d84bb          	addw	s1,s11,s1
    80005a4e:	013d09bb          	addw	s3,s10,s3
    80005a52:	2174fc63          	bgeu	s1,s7,80005c6a <exec+0x3c2>
    pa = walkaddr(pagetable, va + i);
    80005a56:	02049593          	slli	a1,s1,0x20
    80005a5a:	9181                	srli	a1,a1,0x20
    80005a5c:	95e2                	add	a1,a1,s8
    80005a5e:	855a                	mv	a0,s6
    80005a60:	ffffb097          	auipc	ra,0xffffb
    80005a64:	5fe080e7          	jalr	1534(ra) # 8000105e <walkaddr>
    80005a68:	862a                	mv	a2,a0
    if(pa == 0)
    80005a6a:	dd45                	beqz	a0,80005a22 <exec+0x17a>
      n = PGSIZE;
    80005a6c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005a6e:	fd49f2e3          	bgeu	s3,s4,80005a32 <exec+0x18a>
      n = sz - i;
    80005a72:	894e                	mv	s2,s3
    80005a74:	bf7d                	j	80005a32 <exec+0x18a>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005a76:	4481                	li	s1,0
  iunlockput(ip);
    80005a78:	8556                	mv	a0,s5
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	694080e7          	jalr	1684(ra) # 8000410e <iunlockput>
  end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	192080e7          	jalr	402(ra) # 80004c14 <end_op>
  p = myproc();
    80005a8a:	ffffc097          	auipc	ra,0xffffc
    80005a8e:	f5c080e7          	jalr	-164(ra) # 800019e6 <myproc>
    80005a92:	bea43c23          	sd	a0,-1032(s0)
  uint64 oldsz = p->sz;
    80005a96:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005a9a:	6785                	lui	a5,0x1
    80005a9c:	17fd                	addi	a5,a5,-1
    80005a9e:	94be                	add	s1,s1,a5
    80005aa0:	77fd                	lui	a5,0xfffff
    80005aa2:	8fe5                	and	a5,a5,s1
    80005aa4:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005aa8:	6609                	lui	a2,0x2
    80005aaa:	963e                	add	a2,a2,a5
    80005aac:	85be                	mv	a1,a5
    80005aae:	855a                	mv	a0,s6
    80005ab0:	ffffc097          	auipc	ra,0xffffc
    80005ab4:	996080e7          	jalr	-1642(ra) # 80001446 <uvmalloc>
    80005ab8:	8baa                	mv	s7,a0
  ip = 0;
    80005aba:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005abc:	14050163          	beqz	a0,80005bfe <exec+0x356>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005ac0:	75f9                	lui	a1,0xffffe
    80005ac2:	95aa                	add	a1,a1,a0
    80005ac4:	855a                	mv	a0,s6
    80005ac6:	ffffc097          	auipc	ra,0xffffc
    80005aca:	bae080e7          	jalr	-1106(ra) # 80001674 <uvmclear>
  stackbase = sp - PGSIZE;
    80005ace:	7afd                	lui	s5,0xfffff
    80005ad0:	9ade                	add	s5,s5,s7
  for(argc = 0; argv[argc]; argc++) {
    80005ad2:	be843783          	ld	a5,-1048(s0)
    80005ad6:	6388                	ld	a0,0(a5)
    80005ad8:	c925                	beqz	a0,80005b48 <exec+0x2a0>
    80005ada:	e8840993          	addi	s3,s0,-376
    80005ade:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005ae2:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    80005ae4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005ae6:	ffffb097          	auipc	ra,0xffffb
    80005aea:	36e080e7          	jalr	878(ra) # 80000e54 <strlen>
    80005aee:	0015079b          	addiw	a5,a0,1
    80005af2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005af6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005afa:	15596c63          	bltu	s2,s5,80005c52 <exec+0x3aa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005afe:	be843d03          	ld	s10,-1048(s0)
    80005b02:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd1000>
    80005b06:	8552                	mv	a0,s4
    80005b08:	ffffb097          	auipc	ra,0xffffb
    80005b0c:	34c080e7          	jalr	844(ra) # 80000e54 <strlen>
    80005b10:	0015069b          	addiw	a3,a0,1
    80005b14:	8652                	mv	a2,s4
    80005b16:	85ca                	mv	a1,s2
    80005b18:	855a                	mv	a0,s6
    80005b1a:	ffffc097          	auipc	ra,0xffffc
    80005b1e:	b8c080e7          	jalr	-1140(ra) # 800016a6 <copyout>
    80005b22:	12054c63          	bltz	a0,80005c5a <exec+0x3b2>
    ustack[argc] = sp;
    80005b26:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005b2a:	0485                	addi	s1,s1,1
    80005b2c:	008d0793          	addi	a5,s10,8
    80005b30:	bef43423          	sd	a5,-1048(s0)
    80005b34:	008d3503          	ld	a0,8(s10)
    80005b38:	c911                	beqz	a0,80005b4c <exec+0x2a4>
    if(argc >= MAXARG)
    80005b3a:	09a1                	addi	s3,s3,8
    80005b3c:	fb8995e3          	bne	s3,s8,80005ae6 <exec+0x23e>
  sz = sz1;
    80005b40:	bf743823          	sd	s7,-1040(s0)
  ip = 0;
    80005b44:	4a81                	li	s5,0
    80005b46:	a865                	j	80005bfe <exec+0x356>
  sp = sz;
    80005b48:	895e                	mv	s2,s7
  for(argc = 0; argv[argc]; argc++) {
    80005b4a:	4481                	li	s1,0
  ustack[argc] = 0;
    80005b4c:	00349793          	slli	a5,s1,0x3
    80005b50:	f9040713          	addi	a4,s0,-112
    80005b54:	97ba                	add	a5,a5,a4
    80005b56:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd0ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005b5a:	00148693          	addi	a3,s1,1
    80005b5e:	068e                	slli	a3,a3,0x3
    80005b60:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005b64:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005b68:	01597663          	bgeu	s2,s5,80005b74 <exec+0x2cc>
  sz = sz1;
    80005b6c:	bf743823          	sd	s7,-1040(s0)
  ip = 0;
    80005b70:	4a81                	li	s5,0
    80005b72:	a071                	j	80005bfe <exec+0x356>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005b74:	e8840613          	addi	a2,s0,-376
    80005b78:	85ca                	mv	a1,s2
    80005b7a:	855a                	mv	a0,s6
    80005b7c:	ffffc097          	auipc	ra,0xffffc
    80005b80:	b2a080e7          	jalr	-1238(ra) # 800016a6 <copyout>
    80005b84:	0c054f63          	bltz	a0,80005c62 <exec+0x3ba>
  p->trapframe->a1 = sp;
    80005b88:	bf843783          	ld	a5,-1032(s0)
    80005b8c:	6fbc                	ld	a5,88(a5)
    80005b8e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005b92:	be043783          	ld	a5,-1056(s0)
    80005b96:	0007c703          	lbu	a4,0(a5)
    80005b9a:	cf11                	beqz	a4,80005bb6 <exec+0x30e>
    80005b9c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005b9e:	02f00693          	li	a3,47
    80005ba2:	a039                	j	80005bb0 <exec+0x308>
      last = s+1;
    80005ba4:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005ba8:	0785                	addi	a5,a5,1
    80005baa:	fff7c703          	lbu	a4,-1(a5)
    80005bae:	c701                	beqz	a4,80005bb6 <exec+0x30e>
    if(*s == '/')
    80005bb0:	fed71ce3          	bne	a4,a3,80005ba8 <exec+0x300>
    80005bb4:	bfc5                	j	80005ba4 <exec+0x2fc>
  safestrcpy(p->name, last, sizeof(p->name));
    80005bb6:	4641                	li	a2,16
    80005bb8:	be043583          	ld	a1,-1056(s0)
    80005bbc:	bf843983          	ld	s3,-1032(s0)
    80005bc0:	15898513          	addi	a0,s3,344
    80005bc4:	ffffb097          	auipc	ra,0xffffb
    80005bc8:	25e080e7          	jalr	606(ra) # 80000e22 <safestrcpy>
  oldpagetable = p->pagetable;
    80005bcc:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005bd0:	0569b823          	sd	s6,80(s3)
  p->sz = sz;
    80005bd4:	0579b423          	sd	s7,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005bd8:	0589b783          	ld	a5,88(s3)
    80005bdc:	e6043703          	ld	a4,-416(s0)
    80005be0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005be2:	0589b783          	ld	a5,88(s3)
    80005be6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005bea:	85e6                	mv	a1,s9
    80005bec:	ffffc097          	auipc	ra,0xffffc
    80005bf0:	f5a080e7          	jalr	-166(ra) # 80001b46 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005bf4:	0004851b          	sext.w	a0,s1
    80005bf8:	bb55                	j	800059ac <exec+0x104>
    80005bfa:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005bfe:	10000613          	li	a2,256
    80005c02:	d1040593          	addi	a1,s0,-752
    80005c06:	bf843483          	ld	s1,-1032(s0)
    80005c0a:	17048513          	addi	a0,s1,368
    80005c0e:	ffffb097          	auipc	ra,0xffffb
    80005c12:	11e080e7          	jalr	286(ra) # 80000d2c <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005c16:	10000613          	li	a2,256
    80005c1a:	c1040593          	addi	a1,s0,-1008
    80005c1e:	27048513          	addi	a0,s1,624
    80005c22:	ffffb097          	auipc	ra,0xffffb
    80005c26:	10a080e7          	jalr	266(ra) # 80000d2c <memmove>
    proc_freepagetable(pagetable, sz);
    80005c2a:	bf043583          	ld	a1,-1040(s0)
    80005c2e:	855a                	mv	a0,s6
    80005c30:	ffffc097          	auipc	ra,0xffffc
    80005c34:	f16080e7          	jalr	-234(ra) # 80001b46 <proc_freepagetable>
  if(ip){
    80005c38:	d60a90e3          	bnez	s5,80005998 <exec+0xf0>
  return -1;
    80005c3c:	557d                	li	a0,-1
    80005c3e:	b3bd                	j	800059ac <exec+0x104>
    80005c40:	be943823          	sd	s1,-1040(s0)
    80005c44:	bf6d                	j	80005bfe <exec+0x356>
    80005c46:	be943823          	sd	s1,-1040(s0)
    80005c4a:	bf55                	j	80005bfe <exec+0x356>
    80005c4c:	be943823          	sd	s1,-1040(s0)
    80005c50:	b77d                	j	80005bfe <exec+0x356>
  sz = sz1;
    80005c52:	bf743823          	sd	s7,-1040(s0)
  ip = 0;
    80005c56:	4a81                	li	s5,0
    80005c58:	b75d                	j	80005bfe <exec+0x356>
  sz = sz1;
    80005c5a:	bf743823          	sd	s7,-1040(s0)
  ip = 0;
    80005c5e:	4a81                	li	s5,0
    80005c60:	bf79                	j	80005bfe <exec+0x356>
  sz = sz1;
    80005c62:	bf743823          	sd	s7,-1040(s0)
  ip = 0;
    80005c66:	4a81                	li	s5,0
    80005c68:	bf59                	j	80005bfe <exec+0x356>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005c6a:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005c6e:	c0843783          	ld	a5,-1016(s0)
    80005c72:	0017869b          	addiw	a3,a5,1
    80005c76:	c0d43423          	sd	a3,-1016(s0)
    80005c7a:	c0043783          	ld	a5,-1024(s0)
    80005c7e:	0387879b          	addiw	a5,a5,56
    80005c82:	e8045703          	lhu	a4,-384(s0)
    80005c86:	dee6d9e3          	bge	a3,a4,80005a78 <exec+0x1d0>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005c8a:	2781                	sext.w	a5,a5
    80005c8c:	c0f43023          	sd	a5,-1024(s0)
    80005c90:	03800713          	li	a4,56
    80005c94:	86be                	mv	a3,a5
    80005c96:	e1040613          	addi	a2,s0,-496
    80005c9a:	4581                	li	a1,0
    80005c9c:	8556                	mv	a0,s5
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	4c2080e7          	jalr	1218(ra) # 80004160 <readi>
    80005ca6:	03800793          	li	a5,56
    80005caa:	f4f518e3          	bne	a0,a5,80005bfa <exec+0x352>
    if(ph.type != ELF_PROG_LOAD)
    80005cae:	e1042783          	lw	a5,-496(s0)
    80005cb2:	4705                	li	a4,1
    80005cb4:	fae79de3          	bne	a5,a4,80005c6e <exec+0x3c6>
    if(ph.memsz < ph.filesz)
    80005cb8:	e3843603          	ld	a2,-456(s0)
    80005cbc:	e3043783          	ld	a5,-464(s0)
    80005cc0:	f8f660e3          	bltu	a2,a5,80005c40 <exec+0x398>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005cc4:	e2043783          	ld	a5,-480(s0)
    80005cc8:	963e                	add	a2,a2,a5
    80005cca:	f6f66ee3          	bltu	a2,a5,80005c46 <exec+0x39e>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005cce:	85a6                	mv	a1,s1
    80005cd0:	855a                	mv	a0,s6
    80005cd2:	ffffb097          	auipc	ra,0xffffb
    80005cd6:	774080e7          	jalr	1908(ra) # 80001446 <uvmalloc>
    80005cda:	bea43823          	sd	a0,-1040(s0)
    80005cde:	d53d                	beqz	a0,80005c4c <exec+0x3a4>
    if(ph.vaddr % PGSIZE != 0)
    80005ce0:	e2043c03          	ld	s8,-480(s0)
    80005ce4:	bd843783          	ld	a5,-1064(s0)
    80005ce8:	00fc77b3          	and	a5,s8,a5
    80005cec:	fb89                	bnez	a5,80005bfe <exec+0x356>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005cee:	e1842c83          	lw	s9,-488(s0)
    80005cf2:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005cf6:	f60b8ae3          	beqz	s7,80005c6a <exec+0x3c2>
    80005cfa:	89de                	mv	s3,s7
    80005cfc:	4481                	li	s1,0
    80005cfe:	bba1                	j	80005a56 <exec+0x1ae>

0000000080005d00 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005d00:	7179                	addi	sp,sp,-48
    80005d02:	f406                	sd	ra,40(sp)
    80005d04:	f022                	sd	s0,32(sp)
    80005d06:	ec26                	sd	s1,24(sp)
    80005d08:	e84a                	sd	s2,16(sp)
    80005d0a:	1800                	addi	s0,sp,48
    80005d0c:	892e                	mv	s2,a1
    80005d0e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005d10:	fdc40593          	addi	a1,s0,-36
    80005d14:	ffffd097          	auipc	ra,0xffffd
    80005d18:	626080e7          	jalr	1574(ra) # 8000333a <argint>
    80005d1c:	04054063          	bltz	a0,80005d5c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005d20:	fdc42703          	lw	a4,-36(s0)
    80005d24:	47bd                	li	a5,15
    80005d26:	02e7ed63          	bltu	a5,a4,80005d60 <argfd+0x60>
    80005d2a:	ffffc097          	auipc	ra,0xffffc
    80005d2e:	cbc080e7          	jalr	-836(ra) # 800019e6 <myproc>
    80005d32:	fdc42703          	lw	a4,-36(s0)
    80005d36:	01a70793          	addi	a5,a4,26
    80005d3a:	078e                	slli	a5,a5,0x3
    80005d3c:	953e                	add	a0,a0,a5
    80005d3e:	611c                	ld	a5,0(a0)
    80005d40:	c395                	beqz	a5,80005d64 <argfd+0x64>
    return -1;
  if(pfd)
    80005d42:	00090463          	beqz	s2,80005d4a <argfd+0x4a>
    *pfd = fd;
    80005d46:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005d4a:	4501                	li	a0,0
  if(pf)
    80005d4c:	c091                	beqz	s1,80005d50 <argfd+0x50>
    *pf = f;
    80005d4e:	e09c                	sd	a5,0(s1)
}
    80005d50:	70a2                	ld	ra,40(sp)
    80005d52:	7402                	ld	s0,32(sp)
    80005d54:	64e2                	ld	s1,24(sp)
    80005d56:	6942                	ld	s2,16(sp)
    80005d58:	6145                	addi	sp,sp,48
    80005d5a:	8082                	ret
    return -1;
    80005d5c:	557d                	li	a0,-1
    80005d5e:	bfcd                	j	80005d50 <argfd+0x50>
    return -1;
    80005d60:	557d                	li	a0,-1
    80005d62:	b7fd                	j	80005d50 <argfd+0x50>
    80005d64:	557d                	li	a0,-1
    80005d66:	b7ed                	j	80005d50 <argfd+0x50>

0000000080005d68 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005d68:	1101                	addi	sp,sp,-32
    80005d6a:	ec06                	sd	ra,24(sp)
    80005d6c:	e822                	sd	s0,16(sp)
    80005d6e:	e426                	sd	s1,8(sp)
    80005d70:	1000                	addi	s0,sp,32
    80005d72:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005d74:	ffffc097          	auipc	ra,0xffffc
    80005d78:	c72080e7          	jalr	-910(ra) # 800019e6 <myproc>
    80005d7c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005d7e:	0d050793          	addi	a5,a0,208
    80005d82:	4501                	li	a0,0
    80005d84:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005d86:	6398                	ld	a4,0(a5)
    80005d88:	cb19                	beqz	a4,80005d9e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005d8a:	2505                	addiw	a0,a0,1
    80005d8c:	07a1                	addi	a5,a5,8
    80005d8e:	fed51ce3          	bne	a0,a3,80005d86 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005d92:	557d                	li	a0,-1
}
    80005d94:	60e2                	ld	ra,24(sp)
    80005d96:	6442                	ld	s0,16(sp)
    80005d98:	64a2                	ld	s1,8(sp)
    80005d9a:	6105                	addi	sp,sp,32
    80005d9c:	8082                	ret
      p->ofile[fd] = f;
    80005d9e:	01a50793          	addi	a5,a0,26
    80005da2:	078e                	slli	a5,a5,0x3
    80005da4:	963e                	add	a2,a2,a5
    80005da6:	e204                	sd	s1,0(a2)
      return fd;
    80005da8:	b7f5                	j	80005d94 <fdalloc+0x2c>

0000000080005daa <sys_dup>:

uint64
sys_dup(void)
{
    80005daa:	7179                	addi	sp,sp,-48
    80005dac:	f406                	sd	ra,40(sp)
    80005dae:	f022                	sd	s0,32(sp)
    80005db0:	ec26                	sd	s1,24(sp)
    80005db2:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005db4:	fd840613          	addi	a2,s0,-40
    80005db8:	4581                	li	a1,0
    80005dba:	4501                	li	a0,0
    80005dbc:	00000097          	auipc	ra,0x0
    80005dc0:	f44080e7          	jalr	-188(ra) # 80005d00 <argfd>
    return -1;
    80005dc4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005dc6:	02054363          	bltz	a0,80005dec <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005dca:	fd843503          	ld	a0,-40(s0)
    80005dce:	00000097          	auipc	ra,0x0
    80005dd2:	f9a080e7          	jalr	-102(ra) # 80005d68 <fdalloc>
    80005dd6:	84aa                	mv	s1,a0
    return -1;
    80005dd8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005dda:	00054963          	bltz	a0,80005dec <sys_dup+0x42>
  filedup(f);
    80005dde:	fd843503          	ld	a0,-40(s0)
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	22c080e7          	jalr	556(ra) # 8000500e <filedup>
  return fd;
    80005dea:	87a6                	mv	a5,s1
}
    80005dec:	853e                	mv	a0,a5
    80005dee:	70a2                	ld	ra,40(sp)
    80005df0:	7402                	ld	s0,32(sp)
    80005df2:	64e2                	ld	s1,24(sp)
    80005df4:	6145                	addi	sp,sp,48
    80005df6:	8082                	ret

0000000080005df8 <sys_read>:

uint64
sys_read(void)
{
    80005df8:	7179                	addi	sp,sp,-48
    80005dfa:	f406                	sd	ra,40(sp)
    80005dfc:	f022                	sd	s0,32(sp)
    80005dfe:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e00:	fe840613          	addi	a2,s0,-24
    80005e04:	4581                	li	a1,0
    80005e06:	4501                	li	a0,0
    80005e08:	00000097          	auipc	ra,0x0
    80005e0c:	ef8080e7          	jalr	-264(ra) # 80005d00 <argfd>
    return -1;
    80005e10:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e12:	04054163          	bltz	a0,80005e54 <sys_read+0x5c>
    80005e16:	fe440593          	addi	a1,s0,-28
    80005e1a:	4509                	li	a0,2
    80005e1c:	ffffd097          	auipc	ra,0xffffd
    80005e20:	51e080e7          	jalr	1310(ra) # 8000333a <argint>
    return -1;
    80005e24:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e26:	02054763          	bltz	a0,80005e54 <sys_read+0x5c>
    80005e2a:	fd840593          	addi	a1,s0,-40
    80005e2e:	4505                	li	a0,1
    80005e30:	ffffd097          	auipc	ra,0xffffd
    80005e34:	52c080e7          	jalr	1324(ra) # 8000335c <argaddr>
    return -1;
    80005e38:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e3a:	00054d63          	bltz	a0,80005e54 <sys_read+0x5c>
  return fileread(f, p, n);
    80005e3e:	fe442603          	lw	a2,-28(s0)
    80005e42:	fd843583          	ld	a1,-40(s0)
    80005e46:	fe843503          	ld	a0,-24(s0)
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	350080e7          	jalr	848(ra) # 8000519a <fileread>
    80005e52:	87aa                	mv	a5,a0
}
    80005e54:	853e                	mv	a0,a5
    80005e56:	70a2                	ld	ra,40(sp)
    80005e58:	7402                	ld	s0,32(sp)
    80005e5a:	6145                	addi	sp,sp,48
    80005e5c:	8082                	ret

0000000080005e5e <sys_write>:

uint64
sys_write(void)
{
    80005e5e:	7179                	addi	sp,sp,-48
    80005e60:	f406                	sd	ra,40(sp)
    80005e62:	f022                	sd	s0,32(sp)
    80005e64:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e66:	fe840613          	addi	a2,s0,-24
    80005e6a:	4581                	li	a1,0
    80005e6c:	4501                	li	a0,0
    80005e6e:	00000097          	auipc	ra,0x0
    80005e72:	e92080e7          	jalr	-366(ra) # 80005d00 <argfd>
    return -1;
    80005e76:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e78:	04054163          	bltz	a0,80005eba <sys_write+0x5c>
    80005e7c:	fe440593          	addi	a1,s0,-28
    80005e80:	4509                	li	a0,2
    80005e82:	ffffd097          	auipc	ra,0xffffd
    80005e86:	4b8080e7          	jalr	1208(ra) # 8000333a <argint>
    return -1;
    80005e8a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e8c:	02054763          	bltz	a0,80005eba <sys_write+0x5c>
    80005e90:	fd840593          	addi	a1,s0,-40
    80005e94:	4505                	li	a0,1
    80005e96:	ffffd097          	auipc	ra,0xffffd
    80005e9a:	4c6080e7          	jalr	1222(ra) # 8000335c <argaddr>
    return -1;
    80005e9e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ea0:	00054d63          	bltz	a0,80005eba <sys_write+0x5c>

  return filewrite(f, p, n);
    80005ea4:	fe442603          	lw	a2,-28(s0)
    80005ea8:	fd843583          	ld	a1,-40(s0)
    80005eac:	fe843503          	ld	a0,-24(s0)
    80005eb0:	fffff097          	auipc	ra,0xfffff
    80005eb4:	3ac080e7          	jalr	940(ra) # 8000525c <filewrite>
    80005eb8:	87aa                	mv	a5,a0
}
    80005eba:	853e                	mv	a0,a5
    80005ebc:	70a2                	ld	ra,40(sp)
    80005ebe:	7402                	ld	s0,32(sp)
    80005ec0:	6145                	addi	sp,sp,48
    80005ec2:	8082                	ret

0000000080005ec4 <sys_close>:

uint64
sys_close(void)
{
    80005ec4:	1101                	addi	sp,sp,-32
    80005ec6:	ec06                	sd	ra,24(sp)
    80005ec8:	e822                	sd	s0,16(sp)
    80005eca:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005ecc:	fe040613          	addi	a2,s0,-32
    80005ed0:	fec40593          	addi	a1,s0,-20
    80005ed4:	4501                	li	a0,0
    80005ed6:	00000097          	auipc	ra,0x0
    80005eda:	e2a080e7          	jalr	-470(ra) # 80005d00 <argfd>
    return -1;
    80005ede:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ee0:	02054463          	bltz	a0,80005f08 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005ee4:	ffffc097          	auipc	ra,0xffffc
    80005ee8:	b02080e7          	jalr	-1278(ra) # 800019e6 <myproc>
    80005eec:	fec42783          	lw	a5,-20(s0)
    80005ef0:	07e9                	addi	a5,a5,26
    80005ef2:	078e                	slli	a5,a5,0x3
    80005ef4:	97aa                	add	a5,a5,a0
    80005ef6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005efa:	fe043503          	ld	a0,-32(s0)
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	162080e7          	jalr	354(ra) # 80005060 <fileclose>
  return 0;
    80005f06:	4781                	li	a5,0
}
    80005f08:	853e                	mv	a0,a5
    80005f0a:	60e2                	ld	ra,24(sp)
    80005f0c:	6442                	ld	s0,16(sp)
    80005f0e:	6105                	addi	sp,sp,32
    80005f10:	8082                	ret

0000000080005f12 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005f12:	1101                	addi	sp,sp,-32
    80005f14:	ec06                	sd	ra,24(sp)
    80005f16:	e822                	sd	s0,16(sp)
    80005f18:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f1a:	fe840613          	addi	a2,s0,-24
    80005f1e:	4581                	li	a1,0
    80005f20:	4501                	li	a0,0
    80005f22:	00000097          	auipc	ra,0x0
    80005f26:	dde080e7          	jalr	-546(ra) # 80005d00 <argfd>
    return -1;
    80005f2a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f2c:	02054563          	bltz	a0,80005f56 <sys_fstat+0x44>
    80005f30:	fe040593          	addi	a1,s0,-32
    80005f34:	4505                	li	a0,1
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	426080e7          	jalr	1062(ra) # 8000335c <argaddr>
    return -1;
    80005f3e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f40:	00054b63          	bltz	a0,80005f56 <sys_fstat+0x44>
  return filestat(f, st);
    80005f44:	fe043583          	ld	a1,-32(s0)
    80005f48:	fe843503          	ld	a0,-24(s0)
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	1dc080e7          	jalr	476(ra) # 80005128 <filestat>
    80005f54:	87aa                	mv	a5,a0
}
    80005f56:	853e                	mv	a0,a5
    80005f58:	60e2                	ld	ra,24(sp)
    80005f5a:	6442                	ld	s0,16(sp)
    80005f5c:	6105                	addi	sp,sp,32
    80005f5e:	8082                	ret

0000000080005f60 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005f60:	7169                	addi	sp,sp,-304
    80005f62:	f606                	sd	ra,296(sp)
    80005f64:	f222                	sd	s0,288(sp)
    80005f66:	ee26                	sd	s1,280(sp)
    80005f68:	ea4a                	sd	s2,272(sp)
    80005f6a:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f6c:	08000613          	li	a2,128
    80005f70:	ed040593          	addi	a1,s0,-304
    80005f74:	4501                	li	a0,0
    80005f76:	ffffd097          	auipc	ra,0xffffd
    80005f7a:	408080e7          	jalr	1032(ra) # 8000337e <argstr>
    return -1;
    80005f7e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f80:	10054e63          	bltz	a0,8000609c <sys_link+0x13c>
    80005f84:	08000613          	li	a2,128
    80005f88:	f5040593          	addi	a1,s0,-176
    80005f8c:	4505                	li	a0,1
    80005f8e:	ffffd097          	auipc	ra,0xffffd
    80005f92:	3f0080e7          	jalr	1008(ra) # 8000337e <argstr>
    return -1;
    80005f96:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f98:	10054263          	bltz	a0,8000609c <sys_link+0x13c>

  begin_op();
    80005f9c:	fffff097          	auipc	ra,0xfffff
    80005fa0:	bf8080e7          	jalr	-1032(ra) # 80004b94 <begin_op>
  if((ip = namei(old)) == 0){
    80005fa4:	ed040513          	addi	a0,s0,-304
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	6ba080e7          	jalr	1722(ra) # 80004662 <namei>
    80005fb0:	84aa                	mv	s1,a0
    80005fb2:	c551                	beqz	a0,8000603e <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005fb4:	ffffe097          	auipc	ra,0xffffe
    80005fb8:	ef8080e7          	jalr	-264(ra) # 80003eac <ilock>
  if(ip->type == T_DIR){
    80005fbc:	04449703          	lh	a4,68(s1)
    80005fc0:	4785                	li	a5,1
    80005fc2:	08f70463          	beq	a4,a5,8000604a <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005fc6:	04a4d783          	lhu	a5,74(s1)
    80005fca:	2785                	addiw	a5,a5,1
    80005fcc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005fd0:	8526                	mv	a0,s1
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	e10080e7          	jalr	-496(ra) # 80003de2 <iupdate>
  iunlock(ip);
    80005fda:	8526                	mv	a0,s1
    80005fdc:	ffffe097          	auipc	ra,0xffffe
    80005fe0:	f92080e7          	jalr	-110(ra) # 80003f6e <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005fe4:	fd040593          	addi	a1,s0,-48
    80005fe8:	f5040513          	addi	a0,s0,-176
    80005fec:	ffffe097          	auipc	ra,0xffffe
    80005ff0:	694080e7          	jalr	1684(ra) # 80004680 <nameiparent>
    80005ff4:	892a                	mv	s2,a0
    80005ff6:	c935                	beqz	a0,8000606a <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	eb4080e7          	jalr	-332(ra) # 80003eac <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006000:	00092703          	lw	a4,0(s2)
    80006004:	409c                	lw	a5,0(s1)
    80006006:	04f71d63          	bne	a4,a5,80006060 <sys_link+0x100>
    8000600a:	40d0                	lw	a2,4(s1)
    8000600c:	fd040593          	addi	a1,s0,-48
    80006010:	854a                	mv	a0,s2
    80006012:	ffffe097          	auipc	ra,0xffffe
    80006016:	58e080e7          	jalr	1422(ra) # 800045a0 <dirlink>
    8000601a:	04054363          	bltz	a0,80006060 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    8000601e:	854a                	mv	a0,s2
    80006020:	ffffe097          	auipc	ra,0xffffe
    80006024:	0ee080e7          	jalr	238(ra) # 8000410e <iunlockput>
  iput(ip);
    80006028:	8526                	mv	a0,s1
    8000602a:	ffffe097          	auipc	ra,0xffffe
    8000602e:	03c080e7          	jalr	60(ra) # 80004066 <iput>

  end_op();
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	be2080e7          	jalr	-1054(ra) # 80004c14 <end_op>

  return 0;
    8000603a:	4781                	li	a5,0
    8000603c:	a085                	j	8000609c <sys_link+0x13c>
    end_op();
    8000603e:	fffff097          	auipc	ra,0xfffff
    80006042:	bd6080e7          	jalr	-1066(ra) # 80004c14 <end_op>
    return -1;
    80006046:	57fd                	li	a5,-1
    80006048:	a891                	j	8000609c <sys_link+0x13c>
    iunlockput(ip);
    8000604a:	8526                	mv	a0,s1
    8000604c:	ffffe097          	auipc	ra,0xffffe
    80006050:	0c2080e7          	jalr	194(ra) # 8000410e <iunlockput>
    end_op();
    80006054:	fffff097          	auipc	ra,0xfffff
    80006058:	bc0080e7          	jalr	-1088(ra) # 80004c14 <end_op>
    return -1;
    8000605c:	57fd                	li	a5,-1
    8000605e:	a83d                	j	8000609c <sys_link+0x13c>
    iunlockput(dp);
    80006060:	854a                	mv	a0,s2
    80006062:	ffffe097          	auipc	ra,0xffffe
    80006066:	0ac080e7          	jalr	172(ra) # 8000410e <iunlockput>

bad:
  ilock(ip);
    8000606a:	8526                	mv	a0,s1
    8000606c:	ffffe097          	auipc	ra,0xffffe
    80006070:	e40080e7          	jalr	-448(ra) # 80003eac <ilock>
  ip->nlink--;
    80006074:	04a4d783          	lhu	a5,74(s1)
    80006078:	37fd                	addiw	a5,a5,-1
    8000607a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000607e:	8526                	mv	a0,s1
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	d62080e7          	jalr	-670(ra) # 80003de2 <iupdate>
  iunlockput(ip);
    80006088:	8526                	mv	a0,s1
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	084080e7          	jalr	132(ra) # 8000410e <iunlockput>
  end_op();
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	b82080e7          	jalr	-1150(ra) # 80004c14 <end_op>
  return -1;
    8000609a:	57fd                	li	a5,-1
}
    8000609c:	853e                	mv	a0,a5
    8000609e:	70b2                	ld	ra,296(sp)
    800060a0:	7412                	ld	s0,288(sp)
    800060a2:	64f2                	ld	s1,280(sp)
    800060a4:	6952                	ld	s2,272(sp)
    800060a6:	6155                	addi	sp,sp,304
    800060a8:	8082                	ret

00000000800060aa <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800060aa:	4578                	lw	a4,76(a0)
    800060ac:	02000793          	li	a5,32
    800060b0:	04e7fa63          	bgeu	a5,a4,80006104 <isdirempty+0x5a>
{
    800060b4:	7179                	addi	sp,sp,-48
    800060b6:	f406                	sd	ra,40(sp)
    800060b8:	f022                	sd	s0,32(sp)
    800060ba:	ec26                	sd	s1,24(sp)
    800060bc:	e84a                	sd	s2,16(sp)
    800060be:	1800                	addi	s0,sp,48
    800060c0:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800060c2:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060c6:	4741                	li	a4,16
    800060c8:	86a6                	mv	a3,s1
    800060ca:	fd040613          	addi	a2,s0,-48
    800060ce:	4581                	li	a1,0
    800060d0:	854a                	mv	a0,s2
    800060d2:	ffffe097          	auipc	ra,0xffffe
    800060d6:	08e080e7          	jalr	142(ra) # 80004160 <readi>
    800060da:	47c1                	li	a5,16
    800060dc:	00f51c63          	bne	a0,a5,800060f4 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    800060e0:	fd045783          	lhu	a5,-48(s0)
    800060e4:	e395                	bnez	a5,80006108 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800060e6:	24c1                	addiw	s1,s1,16
    800060e8:	04c92783          	lw	a5,76(s2)
    800060ec:	fcf4ede3          	bltu	s1,a5,800060c6 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    800060f0:	4505                	li	a0,1
    800060f2:	a821                	j	8000610a <isdirempty+0x60>
      panic("isdirempty: readi");
    800060f4:	00003517          	auipc	a0,0x3
    800060f8:	8bc50513          	addi	a0,a0,-1860 # 800089b0 <syscalls+0x310>
    800060fc:	ffffa097          	auipc	ra,0xffffa
    80006100:	42e080e7          	jalr	1070(ra) # 8000052a <panic>
  return 1;
    80006104:	4505                	li	a0,1
}
    80006106:	8082                	ret
      return 0;
    80006108:	4501                	li	a0,0
}
    8000610a:	70a2                	ld	ra,40(sp)
    8000610c:	7402                	ld	s0,32(sp)
    8000610e:	64e2                	ld	s1,24(sp)
    80006110:	6942                	ld	s2,16(sp)
    80006112:	6145                	addi	sp,sp,48
    80006114:	8082                	ret

0000000080006116 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006116:	7155                	addi	sp,sp,-208
    80006118:	e586                	sd	ra,200(sp)
    8000611a:	e1a2                	sd	s0,192(sp)
    8000611c:	fd26                	sd	s1,184(sp)
    8000611e:	f94a                	sd	s2,176(sp)
    80006120:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006122:	08000613          	li	a2,128
    80006126:	f4040593          	addi	a1,s0,-192
    8000612a:	4501                	li	a0,0
    8000612c:	ffffd097          	auipc	ra,0xffffd
    80006130:	252080e7          	jalr	594(ra) # 8000337e <argstr>
    80006134:	16054363          	bltz	a0,8000629a <sys_unlink+0x184>
    return -1;

  begin_op();
    80006138:	fffff097          	auipc	ra,0xfffff
    8000613c:	a5c080e7          	jalr	-1444(ra) # 80004b94 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006140:	fc040593          	addi	a1,s0,-64
    80006144:	f4040513          	addi	a0,s0,-192
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	538080e7          	jalr	1336(ra) # 80004680 <nameiparent>
    80006150:	84aa                	mv	s1,a0
    80006152:	c961                	beqz	a0,80006222 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80006154:	ffffe097          	auipc	ra,0xffffe
    80006158:	d58080e7          	jalr	-680(ra) # 80003eac <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000615c:	00002597          	auipc	a1,0x2
    80006160:	73458593          	addi	a1,a1,1844 # 80008890 <syscalls+0x1f0>
    80006164:	fc040513          	addi	a0,s0,-64
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	20e080e7          	jalr	526(ra) # 80004376 <namecmp>
    80006170:	c175                	beqz	a0,80006254 <sys_unlink+0x13e>
    80006172:	00002597          	auipc	a1,0x2
    80006176:	72658593          	addi	a1,a1,1830 # 80008898 <syscalls+0x1f8>
    8000617a:	fc040513          	addi	a0,s0,-64
    8000617e:	ffffe097          	auipc	ra,0xffffe
    80006182:	1f8080e7          	jalr	504(ra) # 80004376 <namecmp>
    80006186:	c579                	beqz	a0,80006254 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80006188:	f3c40613          	addi	a2,s0,-196
    8000618c:	fc040593          	addi	a1,s0,-64
    80006190:	8526                	mv	a0,s1
    80006192:	ffffe097          	auipc	ra,0xffffe
    80006196:	1fe080e7          	jalr	510(ra) # 80004390 <dirlookup>
    8000619a:	892a                	mv	s2,a0
    8000619c:	cd45                	beqz	a0,80006254 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    8000619e:	ffffe097          	auipc	ra,0xffffe
    800061a2:	d0e080e7          	jalr	-754(ra) # 80003eac <ilock>

  if(ip->nlink < 1)
    800061a6:	04a91783          	lh	a5,74(s2)
    800061aa:	08f05263          	blez	a5,8000622e <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800061ae:	04491703          	lh	a4,68(s2)
    800061b2:	4785                	li	a5,1
    800061b4:	08f70563          	beq	a4,a5,8000623e <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800061b8:	4641                	li	a2,16
    800061ba:	4581                	li	a1,0
    800061bc:	fd040513          	addi	a0,s0,-48
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	b10080e7          	jalr	-1264(ra) # 80000cd0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061c8:	4741                	li	a4,16
    800061ca:	f3c42683          	lw	a3,-196(s0)
    800061ce:	fd040613          	addi	a2,s0,-48
    800061d2:	4581                	li	a1,0
    800061d4:	8526                	mv	a0,s1
    800061d6:	ffffe097          	auipc	ra,0xffffe
    800061da:	082080e7          	jalr	130(ra) # 80004258 <writei>
    800061de:	47c1                	li	a5,16
    800061e0:	08f51a63          	bne	a0,a5,80006274 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800061e4:	04491703          	lh	a4,68(s2)
    800061e8:	4785                	li	a5,1
    800061ea:	08f70d63          	beq	a4,a5,80006284 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800061ee:	8526                	mv	a0,s1
    800061f0:	ffffe097          	auipc	ra,0xffffe
    800061f4:	f1e080e7          	jalr	-226(ra) # 8000410e <iunlockput>

  ip->nlink--;
    800061f8:	04a95783          	lhu	a5,74(s2)
    800061fc:	37fd                	addiw	a5,a5,-1
    800061fe:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006202:	854a                	mv	a0,s2
    80006204:	ffffe097          	auipc	ra,0xffffe
    80006208:	bde080e7          	jalr	-1058(ra) # 80003de2 <iupdate>
  iunlockput(ip);
    8000620c:	854a                	mv	a0,s2
    8000620e:	ffffe097          	auipc	ra,0xffffe
    80006212:	f00080e7          	jalr	-256(ra) # 8000410e <iunlockput>

  end_op();
    80006216:	fffff097          	auipc	ra,0xfffff
    8000621a:	9fe080e7          	jalr	-1538(ra) # 80004c14 <end_op>

  return 0;
    8000621e:	4501                	li	a0,0
    80006220:	a0a1                	j	80006268 <sys_unlink+0x152>
    end_op();
    80006222:	fffff097          	auipc	ra,0xfffff
    80006226:	9f2080e7          	jalr	-1550(ra) # 80004c14 <end_op>
    return -1;
    8000622a:	557d                	li	a0,-1
    8000622c:	a835                	j	80006268 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    8000622e:	00002517          	auipc	a0,0x2
    80006232:	67250513          	addi	a0,a0,1650 # 800088a0 <syscalls+0x200>
    80006236:	ffffa097          	auipc	ra,0xffffa
    8000623a:	2f4080e7          	jalr	756(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000623e:	854a                	mv	a0,s2
    80006240:	00000097          	auipc	ra,0x0
    80006244:	e6a080e7          	jalr	-406(ra) # 800060aa <isdirempty>
    80006248:	f925                	bnez	a0,800061b8 <sys_unlink+0xa2>
    iunlockput(ip);
    8000624a:	854a                	mv	a0,s2
    8000624c:	ffffe097          	auipc	ra,0xffffe
    80006250:	ec2080e7          	jalr	-318(ra) # 8000410e <iunlockput>

bad:
  iunlockput(dp);
    80006254:	8526                	mv	a0,s1
    80006256:	ffffe097          	auipc	ra,0xffffe
    8000625a:	eb8080e7          	jalr	-328(ra) # 8000410e <iunlockput>
  end_op();
    8000625e:	fffff097          	auipc	ra,0xfffff
    80006262:	9b6080e7          	jalr	-1610(ra) # 80004c14 <end_op>
  return -1;
    80006266:	557d                	li	a0,-1
}
    80006268:	60ae                	ld	ra,200(sp)
    8000626a:	640e                	ld	s0,192(sp)
    8000626c:	74ea                	ld	s1,184(sp)
    8000626e:	794a                	ld	s2,176(sp)
    80006270:	6169                	addi	sp,sp,208
    80006272:	8082                	ret
    panic("unlink: writei");
    80006274:	00002517          	auipc	a0,0x2
    80006278:	64450513          	addi	a0,a0,1604 # 800088b8 <syscalls+0x218>
    8000627c:	ffffa097          	auipc	ra,0xffffa
    80006280:	2ae080e7          	jalr	686(ra) # 8000052a <panic>
    dp->nlink--;
    80006284:	04a4d783          	lhu	a5,74(s1)
    80006288:	37fd                	addiw	a5,a5,-1
    8000628a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000628e:	8526                	mv	a0,s1
    80006290:	ffffe097          	auipc	ra,0xffffe
    80006294:	b52080e7          	jalr	-1198(ra) # 80003de2 <iupdate>
    80006298:	bf99                	j	800061ee <sys_unlink+0xd8>
    return -1;
    8000629a:	557d                	li	a0,-1
    8000629c:	b7f1                	j	80006268 <sys_unlink+0x152>

000000008000629e <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000629e:	715d                	addi	sp,sp,-80
    800062a0:	e486                	sd	ra,72(sp)
    800062a2:	e0a2                	sd	s0,64(sp)
    800062a4:	fc26                	sd	s1,56(sp)
    800062a6:	f84a                	sd	s2,48(sp)
    800062a8:	f44e                	sd	s3,40(sp)
    800062aa:	f052                	sd	s4,32(sp)
    800062ac:	ec56                	sd	s5,24(sp)
    800062ae:	0880                	addi	s0,sp,80
    800062b0:	89ae                	mv	s3,a1
    800062b2:	8ab2                	mv	s5,a2
    800062b4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800062b6:	fb040593          	addi	a1,s0,-80
    800062ba:	ffffe097          	auipc	ra,0xffffe
    800062be:	3c6080e7          	jalr	966(ra) # 80004680 <nameiparent>
    800062c2:	892a                	mv	s2,a0
    800062c4:	12050e63          	beqz	a0,80006400 <create+0x162>
    return 0;

  ilock(dp);
    800062c8:	ffffe097          	auipc	ra,0xffffe
    800062cc:	be4080e7          	jalr	-1052(ra) # 80003eac <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    800062d0:	4601                	li	a2,0
    800062d2:	fb040593          	addi	a1,s0,-80
    800062d6:	854a                	mv	a0,s2
    800062d8:	ffffe097          	auipc	ra,0xffffe
    800062dc:	0b8080e7          	jalr	184(ra) # 80004390 <dirlookup>
    800062e0:	84aa                	mv	s1,a0
    800062e2:	c921                	beqz	a0,80006332 <create+0x94>
    iunlockput(dp);
    800062e4:	854a                	mv	a0,s2
    800062e6:	ffffe097          	auipc	ra,0xffffe
    800062ea:	e28080e7          	jalr	-472(ra) # 8000410e <iunlockput>
    ilock(ip);
    800062ee:	8526                	mv	a0,s1
    800062f0:	ffffe097          	auipc	ra,0xffffe
    800062f4:	bbc080e7          	jalr	-1092(ra) # 80003eac <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800062f8:	2981                	sext.w	s3,s3
    800062fa:	4789                	li	a5,2
    800062fc:	02f99463          	bne	s3,a5,80006324 <create+0x86>
    80006300:	0444d783          	lhu	a5,68(s1)
    80006304:	37f9                	addiw	a5,a5,-2
    80006306:	17c2                	slli	a5,a5,0x30
    80006308:	93c1                	srli	a5,a5,0x30
    8000630a:	4705                	li	a4,1
    8000630c:	00f76c63          	bltu	a4,a5,80006324 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006310:	8526                	mv	a0,s1
    80006312:	60a6                	ld	ra,72(sp)
    80006314:	6406                	ld	s0,64(sp)
    80006316:	74e2                	ld	s1,56(sp)
    80006318:	7942                	ld	s2,48(sp)
    8000631a:	79a2                	ld	s3,40(sp)
    8000631c:	7a02                	ld	s4,32(sp)
    8000631e:	6ae2                	ld	s5,24(sp)
    80006320:	6161                	addi	sp,sp,80
    80006322:	8082                	ret
    iunlockput(ip);
    80006324:	8526                	mv	a0,s1
    80006326:	ffffe097          	auipc	ra,0xffffe
    8000632a:	de8080e7          	jalr	-536(ra) # 8000410e <iunlockput>
    return 0;
    8000632e:	4481                	li	s1,0
    80006330:	b7c5                	j	80006310 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80006332:	85ce                	mv	a1,s3
    80006334:	00092503          	lw	a0,0(s2)
    80006338:	ffffe097          	auipc	ra,0xffffe
    8000633c:	9dc080e7          	jalr	-1572(ra) # 80003d14 <ialloc>
    80006340:	84aa                	mv	s1,a0
    80006342:	c521                	beqz	a0,8000638a <create+0xec>
  ilock(ip);
    80006344:	ffffe097          	auipc	ra,0xffffe
    80006348:	b68080e7          	jalr	-1176(ra) # 80003eac <ilock>
  ip->major = major;
    8000634c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006350:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006354:	4a05                	li	s4,1
    80006356:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000635a:	8526                	mv	a0,s1
    8000635c:	ffffe097          	auipc	ra,0xffffe
    80006360:	a86080e7          	jalr	-1402(ra) # 80003de2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006364:	2981                	sext.w	s3,s3
    80006366:	03498a63          	beq	s3,s4,8000639a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000636a:	40d0                	lw	a2,4(s1)
    8000636c:	fb040593          	addi	a1,s0,-80
    80006370:	854a                	mv	a0,s2
    80006372:	ffffe097          	auipc	ra,0xffffe
    80006376:	22e080e7          	jalr	558(ra) # 800045a0 <dirlink>
    8000637a:	06054b63          	bltz	a0,800063f0 <create+0x152>
  iunlockput(dp);
    8000637e:	854a                	mv	a0,s2
    80006380:	ffffe097          	auipc	ra,0xffffe
    80006384:	d8e080e7          	jalr	-626(ra) # 8000410e <iunlockput>
  return ip;
    80006388:	b761                	j	80006310 <create+0x72>
    panic("create: ialloc");
    8000638a:	00002517          	auipc	a0,0x2
    8000638e:	63e50513          	addi	a0,a0,1598 # 800089c8 <syscalls+0x328>
    80006392:	ffffa097          	auipc	ra,0xffffa
    80006396:	198080e7          	jalr	408(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000639a:	04a95783          	lhu	a5,74(s2)
    8000639e:	2785                	addiw	a5,a5,1
    800063a0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800063a4:	854a                	mv	a0,s2
    800063a6:	ffffe097          	auipc	ra,0xffffe
    800063aa:	a3c080e7          	jalr	-1476(ra) # 80003de2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800063ae:	40d0                	lw	a2,4(s1)
    800063b0:	00002597          	auipc	a1,0x2
    800063b4:	4e058593          	addi	a1,a1,1248 # 80008890 <syscalls+0x1f0>
    800063b8:	8526                	mv	a0,s1
    800063ba:	ffffe097          	auipc	ra,0xffffe
    800063be:	1e6080e7          	jalr	486(ra) # 800045a0 <dirlink>
    800063c2:	00054f63          	bltz	a0,800063e0 <create+0x142>
    800063c6:	00492603          	lw	a2,4(s2)
    800063ca:	00002597          	auipc	a1,0x2
    800063ce:	4ce58593          	addi	a1,a1,1230 # 80008898 <syscalls+0x1f8>
    800063d2:	8526                	mv	a0,s1
    800063d4:	ffffe097          	auipc	ra,0xffffe
    800063d8:	1cc080e7          	jalr	460(ra) # 800045a0 <dirlink>
    800063dc:	f80557e3          	bgez	a0,8000636a <create+0xcc>
      panic("create dots");
    800063e0:	00002517          	auipc	a0,0x2
    800063e4:	5f850513          	addi	a0,a0,1528 # 800089d8 <syscalls+0x338>
    800063e8:	ffffa097          	auipc	ra,0xffffa
    800063ec:	142080e7          	jalr	322(ra) # 8000052a <panic>
    panic("create: dirlink");
    800063f0:	00002517          	auipc	a0,0x2
    800063f4:	5f850513          	addi	a0,a0,1528 # 800089e8 <syscalls+0x348>
    800063f8:	ffffa097          	auipc	ra,0xffffa
    800063fc:	132080e7          	jalr	306(ra) # 8000052a <panic>
    return 0;
    80006400:	84aa                	mv	s1,a0
    80006402:	b739                	j	80006310 <create+0x72>

0000000080006404 <sys_open>:

uint64
sys_open(void)
{
    80006404:	7131                	addi	sp,sp,-192
    80006406:	fd06                	sd	ra,184(sp)
    80006408:	f922                	sd	s0,176(sp)
    8000640a:	f526                	sd	s1,168(sp)
    8000640c:	f14a                	sd	s2,160(sp)
    8000640e:	ed4e                	sd	s3,152(sp)
    80006410:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006412:	08000613          	li	a2,128
    80006416:	f5040593          	addi	a1,s0,-176
    8000641a:	4501                	li	a0,0
    8000641c:	ffffd097          	auipc	ra,0xffffd
    80006420:	f62080e7          	jalr	-158(ra) # 8000337e <argstr>
    return -1;
    80006424:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006426:	0c054163          	bltz	a0,800064e8 <sys_open+0xe4>
    8000642a:	f4c40593          	addi	a1,s0,-180
    8000642e:	4505                	li	a0,1
    80006430:	ffffd097          	auipc	ra,0xffffd
    80006434:	f0a080e7          	jalr	-246(ra) # 8000333a <argint>
    80006438:	0a054863          	bltz	a0,800064e8 <sys_open+0xe4>

  begin_op();
    8000643c:	ffffe097          	auipc	ra,0xffffe
    80006440:	758080e7          	jalr	1880(ra) # 80004b94 <begin_op>

  if(omode & O_CREATE){
    80006444:	f4c42783          	lw	a5,-180(s0)
    80006448:	2007f793          	andi	a5,a5,512
    8000644c:	cbdd                	beqz	a5,80006502 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000644e:	4681                	li	a3,0
    80006450:	4601                	li	a2,0
    80006452:	4589                	li	a1,2
    80006454:	f5040513          	addi	a0,s0,-176
    80006458:	00000097          	auipc	ra,0x0
    8000645c:	e46080e7          	jalr	-442(ra) # 8000629e <create>
    80006460:	892a                	mv	s2,a0
    if(ip == 0){
    80006462:	c959                	beqz	a0,800064f8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006464:	04491703          	lh	a4,68(s2)
    80006468:	478d                	li	a5,3
    8000646a:	00f71763          	bne	a4,a5,80006478 <sys_open+0x74>
    8000646e:	04695703          	lhu	a4,70(s2)
    80006472:	47a5                	li	a5,9
    80006474:	0ce7ec63          	bltu	a5,a4,8000654c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006478:	fffff097          	auipc	ra,0xfffff
    8000647c:	b2c080e7          	jalr	-1236(ra) # 80004fa4 <filealloc>
    80006480:	89aa                	mv	s3,a0
    80006482:	10050263          	beqz	a0,80006586 <sys_open+0x182>
    80006486:	00000097          	auipc	ra,0x0
    8000648a:	8e2080e7          	jalr	-1822(ra) # 80005d68 <fdalloc>
    8000648e:	84aa                	mv	s1,a0
    80006490:	0e054663          	bltz	a0,8000657c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006494:	04491703          	lh	a4,68(s2)
    80006498:	478d                	li	a5,3
    8000649a:	0cf70463          	beq	a4,a5,80006562 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000649e:	4789                	li	a5,2
    800064a0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800064a4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800064a8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800064ac:	f4c42783          	lw	a5,-180(s0)
    800064b0:	0017c713          	xori	a4,a5,1
    800064b4:	8b05                	andi	a4,a4,1
    800064b6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800064ba:	0037f713          	andi	a4,a5,3
    800064be:	00e03733          	snez	a4,a4
    800064c2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800064c6:	4007f793          	andi	a5,a5,1024
    800064ca:	c791                	beqz	a5,800064d6 <sys_open+0xd2>
    800064cc:	04491703          	lh	a4,68(s2)
    800064d0:	4789                	li	a5,2
    800064d2:	08f70f63          	beq	a4,a5,80006570 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800064d6:	854a                	mv	a0,s2
    800064d8:	ffffe097          	auipc	ra,0xffffe
    800064dc:	a96080e7          	jalr	-1386(ra) # 80003f6e <iunlock>
  end_op();
    800064e0:	ffffe097          	auipc	ra,0xffffe
    800064e4:	734080e7          	jalr	1844(ra) # 80004c14 <end_op>

  return fd;
}
    800064e8:	8526                	mv	a0,s1
    800064ea:	70ea                	ld	ra,184(sp)
    800064ec:	744a                	ld	s0,176(sp)
    800064ee:	74aa                	ld	s1,168(sp)
    800064f0:	790a                	ld	s2,160(sp)
    800064f2:	69ea                	ld	s3,152(sp)
    800064f4:	6129                	addi	sp,sp,192
    800064f6:	8082                	ret
      end_op();
    800064f8:	ffffe097          	auipc	ra,0xffffe
    800064fc:	71c080e7          	jalr	1820(ra) # 80004c14 <end_op>
      return -1;
    80006500:	b7e5                	j	800064e8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006502:	f5040513          	addi	a0,s0,-176
    80006506:	ffffe097          	auipc	ra,0xffffe
    8000650a:	15c080e7          	jalr	348(ra) # 80004662 <namei>
    8000650e:	892a                	mv	s2,a0
    80006510:	c905                	beqz	a0,80006540 <sys_open+0x13c>
    ilock(ip);
    80006512:	ffffe097          	auipc	ra,0xffffe
    80006516:	99a080e7          	jalr	-1638(ra) # 80003eac <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000651a:	04491703          	lh	a4,68(s2)
    8000651e:	4785                	li	a5,1
    80006520:	f4f712e3          	bne	a4,a5,80006464 <sys_open+0x60>
    80006524:	f4c42783          	lw	a5,-180(s0)
    80006528:	dba1                	beqz	a5,80006478 <sys_open+0x74>
      iunlockput(ip);
    8000652a:	854a                	mv	a0,s2
    8000652c:	ffffe097          	auipc	ra,0xffffe
    80006530:	be2080e7          	jalr	-1054(ra) # 8000410e <iunlockput>
      end_op();
    80006534:	ffffe097          	auipc	ra,0xffffe
    80006538:	6e0080e7          	jalr	1760(ra) # 80004c14 <end_op>
      return -1;
    8000653c:	54fd                	li	s1,-1
    8000653e:	b76d                	j	800064e8 <sys_open+0xe4>
      end_op();
    80006540:	ffffe097          	auipc	ra,0xffffe
    80006544:	6d4080e7          	jalr	1748(ra) # 80004c14 <end_op>
      return -1;
    80006548:	54fd                	li	s1,-1
    8000654a:	bf79                	j	800064e8 <sys_open+0xe4>
    iunlockput(ip);
    8000654c:	854a                	mv	a0,s2
    8000654e:	ffffe097          	auipc	ra,0xffffe
    80006552:	bc0080e7          	jalr	-1088(ra) # 8000410e <iunlockput>
    end_op();
    80006556:	ffffe097          	auipc	ra,0xffffe
    8000655a:	6be080e7          	jalr	1726(ra) # 80004c14 <end_op>
    return -1;
    8000655e:	54fd                	li	s1,-1
    80006560:	b761                	j	800064e8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006562:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006566:	04691783          	lh	a5,70(s2)
    8000656a:	02f99223          	sh	a5,36(s3)
    8000656e:	bf2d                	j	800064a8 <sys_open+0xa4>
    itrunc(ip);
    80006570:	854a                	mv	a0,s2
    80006572:	ffffe097          	auipc	ra,0xffffe
    80006576:	a48080e7          	jalr	-1464(ra) # 80003fba <itrunc>
    8000657a:	bfb1                	j	800064d6 <sys_open+0xd2>
      fileclose(f);
    8000657c:	854e                	mv	a0,s3
    8000657e:	fffff097          	auipc	ra,0xfffff
    80006582:	ae2080e7          	jalr	-1310(ra) # 80005060 <fileclose>
    iunlockput(ip);
    80006586:	854a                	mv	a0,s2
    80006588:	ffffe097          	auipc	ra,0xffffe
    8000658c:	b86080e7          	jalr	-1146(ra) # 8000410e <iunlockput>
    end_op();
    80006590:	ffffe097          	auipc	ra,0xffffe
    80006594:	684080e7          	jalr	1668(ra) # 80004c14 <end_op>
    return -1;
    80006598:	54fd                	li	s1,-1
    8000659a:	b7b9                	j	800064e8 <sys_open+0xe4>

000000008000659c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000659c:	7175                	addi	sp,sp,-144
    8000659e:	e506                	sd	ra,136(sp)
    800065a0:	e122                	sd	s0,128(sp)
    800065a2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800065a4:	ffffe097          	auipc	ra,0xffffe
    800065a8:	5f0080e7          	jalr	1520(ra) # 80004b94 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800065ac:	08000613          	li	a2,128
    800065b0:	f7040593          	addi	a1,s0,-144
    800065b4:	4501                	li	a0,0
    800065b6:	ffffd097          	auipc	ra,0xffffd
    800065ba:	dc8080e7          	jalr	-568(ra) # 8000337e <argstr>
    800065be:	02054963          	bltz	a0,800065f0 <sys_mkdir+0x54>
    800065c2:	4681                	li	a3,0
    800065c4:	4601                	li	a2,0
    800065c6:	4585                	li	a1,1
    800065c8:	f7040513          	addi	a0,s0,-144
    800065cc:	00000097          	auipc	ra,0x0
    800065d0:	cd2080e7          	jalr	-814(ra) # 8000629e <create>
    800065d4:	cd11                	beqz	a0,800065f0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800065d6:	ffffe097          	auipc	ra,0xffffe
    800065da:	b38080e7          	jalr	-1224(ra) # 8000410e <iunlockput>
  end_op();
    800065de:	ffffe097          	auipc	ra,0xffffe
    800065e2:	636080e7          	jalr	1590(ra) # 80004c14 <end_op>
  return 0;
    800065e6:	4501                	li	a0,0
}
    800065e8:	60aa                	ld	ra,136(sp)
    800065ea:	640a                	ld	s0,128(sp)
    800065ec:	6149                	addi	sp,sp,144
    800065ee:	8082                	ret
    end_op();
    800065f0:	ffffe097          	auipc	ra,0xffffe
    800065f4:	624080e7          	jalr	1572(ra) # 80004c14 <end_op>
    return -1;
    800065f8:	557d                	li	a0,-1
    800065fa:	b7fd                	j	800065e8 <sys_mkdir+0x4c>

00000000800065fc <sys_mknod>:

uint64
sys_mknod(void)
{
    800065fc:	7135                	addi	sp,sp,-160
    800065fe:	ed06                	sd	ra,152(sp)
    80006600:	e922                	sd	s0,144(sp)
    80006602:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006604:	ffffe097          	auipc	ra,0xffffe
    80006608:	590080e7          	jalr	1424(ra) # 80004b94 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000660c:	08000613          	li	a2,128
    80006610:	f7040593          	addi	a1,s0,-144
    80006614:	4501                	li	a0,0
    80006616:	ffffd097          	auipc	ra,0xffffd
    8000661a:	d68080e7          	jalr	-664(ra) # 8000337e <argstr>
    8000661e:	04054a63          	bltz	a0,80006672 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006622:	f6c40593          	addi	a1,s0,-148
    80006626:	4505                	li	a0,1
    80006628:	ffffd097          	auipc	ra,0xffffd
    8000662c:	d12080e7          	jalr	-750(ra) # 8000333a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006630:	04054163          	bltz	a0,80006672 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006634:	f6840593          	addi	a1,s0,-152
    80006638:	4509                	li	a0,2
    8000663a:	ffffd097          	auipc	ra,0xffffd
    8000663e:	d00080e7          	jalr	-768(ra) # 8000333a <argint>
     argint(1, &major) < 0 ||
    80006642:	02054863          	bltz	a0,80006672 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006646:	f6841683          	lh	a3,-152(s0)
    8000664a:	f6c41603          	lh	a2,-148(s0)
    8000664e:	458d                	li	a1,3
    80006650:	f7040513          	addi	a0,s0,-144
    80006654:	00000097          	auipc	ra,0x0
    80006658:	c4a080e7          	jalr	-950(ra) # 8000629e <create>
     argint(2, &minor) < 0 ||
    8000665c:	c919                	beqz	a0,80006672 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000665e:	ffffe097          	auipc	ra,0xffffe
    80006662:	ab0080e7          	jalr	-1360(ra) # 8000410e <iunlockput>
  end_op();
    80006666:	ffffe097          	auipc	ra,0xffffe
    8000666a:	5ae080e7          	jalr	1454(ra) # 80004c14 <end_op>
  return 0;
    8000666e:	4501                	li	a0,0
    80006670:	a031                	j	8000667c <sys_mknod+0x80>
    end_op();
    80006672:	ffffe097          	auipc	ra,0xffffe
    80006676:	5a2080e7          	jalr	1442(ra) # 80004c14 <end_op>
    return -1;
    8000667a:	557d                	li	a0,-1
}
    8000667c:	60ea                	ld	ra,152(sp)
    8000667e:	644a                	ld	s0,144(sp)
    80006680:	610d                	addi	sp,sp,160
    80006682:	8082                	ret

0000000080006684 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006684:	7135                	addi	sp,sp,-160
    80006686:	ed06                	sd	ra,152(sp)
    80006688:	e922                	sd	s0,144(sp)
    8000668a:	e526                	sd	s1,136(sp)
    8000668c:	e14a                	sd	s2,128(sp)
    8000668e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006690:	ffffb097          	auipc	ra,0xffffb
    80006694:	356080e7          	jalr	854(ra) # 800019e6 <myproc>
    80006698:	892a                	mv	s2,a0
  
  begin_op();
    8000669a:	ffffe097          	auipc	ra,0xffffe
    8000669e:	4fa080e7          	jalr	1274(ra) # 80004b94 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800066a2:	08000613          	li	a2,128
    800066a6:	f6040593          	addi	a1,s0,-160
    800066aa:	4501                	li	a0,0
    800066ac:	ffffd097          	auipc	ra,0xffffd
    800066b0:	cd2080e7          	jalr	-814(ra) # 8000337e <argstr>
    800066b4:	04054b63          	bltz	a0,8000670a <sys_chdir+0x86>
    800066b8:	f6040513          	addi	a0,s0,-160
    800066bc:	ffffe097          	auipc	ra,0xffffe
    800066c0:	fa6080e7          	jalr	-90(ra) # 80004662 <namei>
    800066c4:	84aa                	mv	s1,a0
    800066c6:	c131                	beqz	a0,8000670a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800066c8:	ffffd097          	auipc	ra,0xffffd
    800066cc:	7e4080e7          	jalr	2020(ra) # 80003eac <ilock>
  if(ip->type != T_DIR){
    800066d0:	04449703          	lh	a4,68(s1)
    800066d4:	4785                	li	a5,1
    800066d6:	04f71063          	bne	a4,a5,80006716 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800066da:	8526                	mv	a0,s1
    800066dc:	ffffe097          	auipc	ra,0xffffe
    800066e0:	892080e7          	jalr	-1902(ra) # 80003f6e <iunlock>
  iput(p->cwd);
    800066e4:	15093503          	ld	a0,336(s2)
    800066e8:	ffffe097          	auipc	ra,0xffffe
    800066ec:	97e080e7          	jalr	-1666(ra) # 80004066 <iput>
  end_op();
    800066f0:	ffffe097          	auipc	ra,0xffffe
    800066f4:	524080e7          	jalr	1316(ra) # 80004c14 <end_op>
  p->cwd = ip;
    800066f8:	14993823          	sd	s1,336(s2)
  return 0;
    800066fc:	4501                	li	a0,0
}
    800066fe:	60ea                	ld	ra,152(sp)
    80006700:	644a                	ld	s0,144(sp)
    80006702:	64aa                	ld	s1,136(sp)
    80006704:	690a                	ld	s2,128(sp)
    80006706:	610d                	addi	sp,sp,160
    80006708:	8082                	ret
    end_op();
    8000670a:	ffffe097          	auipc	ra,0xffffe
    8000670e:	50a080e7          	jalr	1290(ra) # 80004c14 <end_op>
    return -1;
    80006712:	557d                	li	a0,-1
    80006714:	b7ed                	j	800066fe <sys_chdir+0x7a>
    iunlockput(ip);
    80006716:	8526                	mv	a0,s1
    80006718:	ffffe097          	auipc	ra,0xffffe
    8000671c:	9f6080e7          	jalr	-1546(ra) # 8000410e <iunlockput>
    end_op();
    80006720:	ffffe097          	auipc	ra,0xffffe
    80006724:	4f4080e7          	jalr	1268(ra) # 80004c14 <end_op>
    return -1;
    80006728:	557d                	li	a0,-1
    8000672a:	bfd1                	j	800066fe <sys_chdir+0x7a>

000000008000672c <sys_exec>:

uint64
sys_exec(void)
{
    8000672c:	7145                	addi	sp,sp,-464
    8000672e:	e786                	sd	ra,456(sp)
    80006730:	e3a2                	sd	s0,448(sp)
    80006732:	ff26                	sd	s1,440(sp)
    80006734:	fb4a                	sd	s2,432(sp)
    80006736:	f74e                	sd	s3,424(sp)
    80006738:	f352                	sd	s4,416(sp)
    8000673a:	ef56                	sd	s5,408(sp)
    8000673c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000673e:	08000613          	li	a2,128
    80006742:	f4040593          	addi	a1,s0,-192
    80006746:	4501                	li	a0,0
    80006748:	ffffd097          	auipc	ra,0xffffd
    8000674c:	c36080e7          	jalr	-970(ra) # 8000337e <argstr>
    return -1;
    80006750:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006752:	0c054a63          	bltz	a0,80006826 <sys_exec+0xfa>
    80006756:	e3840593          	addi	a1,s0,-456
    8000675a:	4505                	li	a0,1
    8000675c:	ffffd097          	auipc	ra,0xffffd
    80006760:	c00080e7          	jalr	-1024(ra) # 8000335c <argaddr>
    80006764:	0c054163          	bltz	a0,80006826 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006768:	10000613          	li	a2,256
    8000676c:	4581                	li	a1,0
    8000676e:	e4040513          	addi	a0,s0,-448
    80006772:	ffffa097          	auipc	ra,0xffffa
    80006776:	55e080e7          	jalr	1374(ra) # 80000cd0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000677a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000677e:	89a6                	mv	s3,s1
    80006780:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006782:	02000a13          	li	s4,32
    80006786:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000678a:	00391793          	slli	a5,s2,0x3
    8000678e:	e3040593          	addi	a1,s0,-464
    80006792:	e3843503          	ld	a0,-456(s0)
    80006796:	953e                	add	a0,a0,a5
    80006798:	ffffd097          	auipc	ra,0xffffd
    8000679c:	b08080e7          	jalr	-1272(ra) # 800032a0 <fetchaddr>
    800067a0:	02054a63          	bltz	a0,800067d4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800067a4:	e3043783          	ld	a5,-464(s0)
    800067a8:	c3b9                	beqz	a5,800067ee <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800067aa:	ffffa097          	auipc	ra,0xffffa
    800067ae:	328080e7          	jalr	808(ra) # 80000ad2 <kalloc>
    800067b2:	85aa                	mv	a1,a0
    800067b4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800067b8:	cd11                	beqz	a0,800067d4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800067ba:	6605                	lui	a2,0x1
    800067bc:	e3043503          	ld	a0,-464(s0)
    800067c0:	ffffd097          	auipc	ra,0xffffd
    800067c4:	b32080e7          	jalr	-1230(ra) # 800032f2 <fetchstr>
    800067c8:	00054663          	bltz	a0,800067d4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800067cc:	0905                	addi	s2,s2,1
    800067ce:	09a1                	addi	s3,s3,8
    800067d0:	fb491be3          	bne	s2,s4,80006786 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800067d4:	10048913          	addi	s2,s1,256
    800067d8:	6088                	ld	a0,0(s1)
    800067da:	c529                	beqz	a0,80006824 <sys_exec+0xf8>
    kfree(argv[i]);
    800067dc:	ffffa097          	auipc	ra,0xffffa
    800067e0:	1fa080e7          	jalr	506(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800067e4:	04a1                	addi	s1,s1,8
    800067e6:	ff2499e3          	bne	s1,s2,800067d8 <sys_exec+0xac>
  return -1;
    800067ea:	597d                	li	s2,-1
    800067ec:	a82d                	j	80006826 <sys_exec+0xfa>
      argv[i] = 0;
    800067ee:	0a8e                	slli	s5,s5,0x3
    800067f0:	fc040793          	addi	a5,s0,-64
    800067f4:	9abe                	add	s5,s5,a5
    800067f6:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd0e80>
  int ret = exec(path, argv);
    800067fa:	e4040593          	addi	a1,s0,-448
    800067fe:	f4040513          	addi	a0,s0,-192
    80006802:	fffff097          	auipc	ra,0xfffff
    80006806:	0a6080e7          	jalr	166(ra) # 800058a8 <exec>
    8000680a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000680c:	10048993          	addi	s3,s1,256
    80006810:	6088                	ld	a0,0(s1)
    80006812:	c911                	beqz	a0,80006826 <sys_exec+0xfa>
    kfree(argv[i]);
    80006814:	ffffa097          	auipc	ra,0xffffa
    80006818:	1c2080e7          	jalr	450(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000681c:	04a1                	addi	s1,s1,8
    8000681e:	ff3499e3          	bne	s1,s3,80006810 <sys_exec+0xe4>
    80006822:	a011                	j	80006826 <sys_exec+0xfa>
  return -1;
    80006824:	597d                	li	s2,-1
}
    80006826:	854a                	mv	a0,s2
    80006828:	60be                	ld	ra,456(sp)
    8000682a:	641e                	ld	s0,448(sp)
    8000682c:	74fa                	ld	s1,440(sp)
    8000682e:	795a                	ld	s2,432(sp)
    80006830:	79ba                	ld	s3,424(sp)
    80006832:	7a1a                	ld	s4,416(sp)
    80006834:	6afa                	ld	s5,408(sp)
    80006836:	6179                	addi	sp,sp,464
    80006838:	8082                	ret

000000008000683a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000683a:	7139                	addi	sp,sp,-64
    8000683c:	fc06                	sd	ra,56(sp)
    8000683e:	f822                	sd	s0,48(sp)
    80006840:	f426                	sd	s1,40(sp)
    80006842:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006844:	ffffb097          	auipc	ra,0xffffb
    80006848:	1a2080e7          	jalr	418(ra) # 800019e6 <myproc>
    8000684c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000684e:	fd840593          	addi	a1,s0,-40
    80006852:	4501                	li	a0,0
    80006854:	ffffd097          	auipc	ra,0xffffd
    80006858:	b08080e7          	jalr	-1272(ra) # 8000335c <argaddr>
    return -1;
    8000685c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000685e:	0e054063          	bltz	a0,8000693e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006862:	fc840593          	addi	a1,s0,-56
    80006866:	fd040513          	addi	a0,s0,-48
    8000686a:	fffff097          	auipc	ra,0xfffff
    8000686e:	d1c080e7          	jalr	-740(ra) # 80005586 <pipealloc>
    return -1;
    80006872:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006874:	0c054563          	bltz	a0,8000693e <sys_pipe+0x104>
  fd0 = -1;
    80006878:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000687c:	fd043503          	ld	a0,-48(s0)
    80006880:	fffff097          	auipc	ra,0xfffff
    80006884:	4e8080e7          	jalr	1256(ra) # 80005d68 <fdalloc>
    80006888:	fca42223          	sw	a0,-60(s0)
    8000688c:	08054c63          	bltz	a0,80006924 <sys_pipe+0xea>
    80006890:	fc843503          	ld	a0,-56(s0)
    80006894:	fffff097          	auipc	ra,0xfffff
    80006898:	4d4080e7          	jalr	1236(ra) # 80005d68 <fdalloc>
    8000689c:	fca42023          	sw	a0,-64(s0)
    800068a0:	06054863          	bltz	a0,80006910 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800068a4:	4691                	li	a3,4
    800068a6:	fc440613          	addi	a2,s0,-60
    800068aa:	fd843583          	ld	a1,-40(s0)
    800068ae:	68a8                	ld	a0,80(s1)
    800068b0:	ffffb097          	auipc	ra,0xffffb
    800068b4:	df6080e7          	jalr	-522(ra) # 800016a6 <copyout>
    800068b8:	02054063          	bltz	a0,800068d8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800068bc:	4691                	li	a3,4
    800068be:	fc040613          	addi	a2,s0,-64
    800068c2:	fd843583          	ld	a1,-40(s0)
    800068c6:	0591                	addi	a1,a1,4
    800068c8:	68a8                	ld	a0,80(s1)
    800068ca:	ffffb097          	auipc	ra,0xffffb
    800068ce:	ddc080e7          	jalr	-548(ra) # 800016a6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800068d2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800068d4:	06055563          	bgez	a0,8000693e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800068d8:	fc442783          	lw	a5,-60(s0)
    800068dc:	07e9                	addi	a5,a5,26
    800068de:	078e                	slli	a5,a5,0x3
    800068e0:	97a6                	add	a5,a5,s1
    800068e2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800068e6:	fc042503          	lw	a0,-64(s0)
    800068ea:	0569                	addi	a0,a0,26
    800068ec:	050e                	slli	a0,a0,0x3
    800068ee:	9526                	add	a0,a0,s1
    800068f0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800068f4:	fd043503          	ld	a0,-48(s0)
    800068f8:	ffffe097          	auipc	ra,0xffffe
    800068fc:	768080e7          	jalr	1896(ra) # 80005060 <fileclose>
    fileclose(wf);
    80006900:	fc843503          	ld	a0,-56(s0)
    80006904:	ffffe097          	auipc	ra,0xffffe
    80006908:	75c080e7          	jalr	1884(ra) # 80005060 <fileclose>
    return -1;
    8000690c:	57fd                	li	a5,-1
    8000690e:	a805                	j	8000693e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006910:	fc442783          	lw	a5,-60(s0)
    80006914:	0007c863          	bltz	a5,80006924 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006918:	01a78513          	addi	a0,a5,26
    8000691c:	050e                	slli	a0,a0,0x3
    8000691e:	9526                	add	a0,a0,s1
    80006920:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006924:	fd043503          	ld	a0,-48(s0)
    80006928:	ffffe097          	auipc	ra,0xffffe
    8000692c:	738080e7          	jalr	1848(ra) # 80005060 <fileclose>
    fileclose(wf);
    80006930:	fc843503          	ld	a0,-56(s0)
    80006934:	ffffe097          	auipc	ra,0xffffe
    80006938:	72c080e7          	jalr	1836(ra) # 80005060 <fileclose>
    return -1;
    8000693c:	57fd                	li	a5,-1
}
    8000693e:	853e                	mv	a0,a5
    80006940:	70e2                	ld	ra,56(sp)
    80006942:	7442                	ld	s0,48(sp)
    80006944:	74a2                	ld	s1,40(sp)
    80006946:	6121                	addi	sp,sp,64
    80006948:	8082                	ret
    8000694a:	0000                	unimp
    8000694c:	0000                	unimp
	...

0000000080006950 <kernelvec>:
    80006950:	7111                	addi	sp,sp,-256
    80006952:	e006                	sd	ra,0(sp)
    80006954:	e40a                	sd	sp,8(sp)
    80006956:	e80e                	sd	gp,16(sp)
    80006958:	ec12                	sd	tp,24(sp)
    8000695a:	f016                	sd	t0,32(sp)
    8000695c:	f41a                	sd	t1,40(sp)
    8000695e:	f81e                	sd	t2,48(sp)
    80006960:	fc22                	sd	s0,56(sp)
    80006962:	e0a6                	sd	s1,64(sp)
    80006964:	e4aa                	sd	a0,72(sp)
    80006966:	e8ae                	sd	a1,80(sp)
    80006968:	ecb2                	sd	a2,88(sp)
    8000696a:	f0b6                	sd	a3,96(sp)
    8000696c:	f4ba                	sd	a4,104(sp)
    8000696e:	f8be                	sd	a5,112(sp)
    80006970:	fcc2                	sd	a6,120(sp)
    80006972:	e146                	sd	a7,128(sp)
    80006974:	e54a                	sd	s2,136(sp)
    80006976:	e94e                	sd	s3,144(sp)
    80006978:	ed52                	sd	s4,152(sp)
    8000697a:	f156                	sd	s5,160(sp)
    8000697c:	f55a                	sd	s6,168(sp)
    8000697e:	f95e                	sd	s7,176(sp)
    80006980:	fd62                	sd	s8,184(sp)
    80006982:	e1e6                	sd	s9,192(sp)
    80006984:	e5ea                	sd	s10,200(sp)
    80006986:	e9ee                	sd	s11,208(sp)
    80006988:	edf2                	sd	t3,216(sp)
    8000698a:	f1f6                	sd	t4,224(sp)
    8000698c:	f5fa                	sd	t5,232(sp)
    8000698e:	f9fe                	sd	t6,240(sp)
    80006990:	fdcfc0ef          	jal	ra,8000316c <kerneltrap>
    80006994:	6082                	ld	ra,0(sp)
    80006996:	6122                	ld	sp,8(sp)
    80006998:	61c2                	ld	gp,16(sp)
    8000699a:	7282                	ld	t0,32(sp)
    8000699c:	7322                	ld	t1,40(sp)
    8000699e:	73c2                	ld	t2,48(sp)
    800069a0:	7462                	ld	s0,56(sp)
    800069a2:	6486                	ld	s1,64(sp)
    800069a4:	6526                	ld	a0,72(sp)
    800069a6:	65c6                	ld	a1,80(sp)
    800069a8:	6666                	ld	a2,88(sp)
    800069aa:	7686                	ld	a3,96(sp)
    800069ac:	7726                	ld	a4,104(sp)
    800069ae:	77c6                	ld	a5,112(sp)
    800069b0:	7866                	ld	a6,120(sp)
    800069b2:	688a                	ld	a7,128(sp)
    800069b4:	692a                	ld	s2,136(sp)
    800069b6:	69ca                	ld	s3,144(sp)
    800069b8:	6a6a                	ld	s4,152(sp)
    800069ba:	7a8a                	ld	s5,160(sp)
    800069bc:	7b2a                	ld	s6,168(sp)
    800069be:	7bca                	ld	s7,176(sp)
    800069c0:	7c6a                	ld	s8,184(sp)
    800069c2:	6c8e                	ld	s9,192(sp)
    800069c4:	6d2e                	ld	s10,200(sp)
    800069c6:	6dce                	ld	s11,208(sp)
    800069c8:	6e6e                	ld	t3,216(sp)
    800069ca:	7e8e                	ld	t4,224(sp)
    800069cc:	7f2e                	ld	t5,232(sp)
    800069ce:	7fce                	ld	t6,240(sp)
    800069d0:	6111                	addi	sp,sp,256
    800069d2:	10200073          	sret
    800069d6:	00000013          	nop
    800069da:	00000013          	nop
    800069de:	0001                	nop

00000000800069e0 <timervec>:
    800069e0:	34051573          	csrrw	a0,mscratch,a0
    800069e4:	e10c                	sd	a1,0(a0)
    800069e6:	e510                	sd	a2,8(a0)
    800069e8:	e914                	sd	a3,16(a0)
    800069ea:	6d0c                	ld	a1,24(a0)
    800069ec:	7110                	ld	a2,32(a0)
    800069ee:	6194                	ld	a3,0(a1)
    800069f0:	96b2                	add	a3,a3,a2
    800069f2:	e194                	sd	a3,0(a1)
    800069f4:	4589                	li	a1,2
    800069f6:	14459073          	csrw	sip,a1
    800069fa:	6914                	ld	a3,16(a0)
    800069fc:	6510                	ld	a2,8(a0)
    800069fe:	610c                	ld	a1,0(a0)
    80006a00:	34051573          	csrrw	a0,mscratch,a0
    80006a04:	30200073          	mret
	...

0000000080006a0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006a0a:	1141                	addi	sp,sp,-16
    80006a0c:	e422                	sd	s0,8(sp)
    80006a0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006a10:	0c0007b7          	lui	a5,0xc000
    80006a14:	4705                	li	a4,1
    80006a16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006a18:	c3d8                	sw	a4,4(a5)
}
    80006a1a:	6422                	ld	s0,8(sp)
    80006a1c:	0141                	addi	sp,sp,16
    80006a1e:	8082                	ret

0000000080006a20 <plicinithart>:

void
plicinithart(void)
{
    80006a20:	1141                	addi	sp,sp,-16
    80006a22:	e406                	sd	ra,8(sp)
    80006a24:	e022                	sd	s0,0(sp)
    80006a26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006a28:	ffffb097          	auipc	ra,0xffffb
    80006a2c:	f92080e7          	jalr	-110(ra) # 800019ba <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006a30:	0085171b          	slliw	a4,a0,0x8
    80006a34:	0c0027b7          	lui	a5,0xc002
    80006a38:	97ba                	add	a5,a5,a4
    80006a3a:	40200713          	li	a4,1026
    80006a3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006a42:	00d5151b          	slliw	a0,a0,0xd
    80006a46:	0c2017b7          	lui	a5,0xc201
    80006a4a:	953e                	add	a0,a0,a5
    80006a4c:	00052023          	sw	zero,0(a0)
}
    80006a50:	60a2                	ld	ra,8(sp)
    80006a52:	6402                	ld	s0,0(sp)
    80006a54:	0141                	addi	sp,sp,16
    80006a56:	8082                	ret

0000000080006a58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006a58:	1141                	addi	sp,sp,-16
    80006a5a:	e406                	sd	ra,8(sp)
    80006a5c:	e022                	sd	s0,0(sp)
    80006a5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006a60:	ffffb097          	auipc	ra,0xffffb
    80006a64:	f5a080e7          	jalr	-166(ra) # 800019ba <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006a68:	00d5179b          	slliw	a5,a0,0xd
    80006a6c:	0c201537          	lui	a0,0xc201
    80006a70:	953e                	add	a0,a0,a5
  return irq;
}
    80006a72:	4148                	lw	a0,4(a0)
    80006a74:	60a2                	ld	ra,8(sp)
    80006a76:	6402                	ld	s0,0(sp)
    80006a78:	0141                	addi	sp,sp,16
    80006a7a:	8082                	ret

0000000080006a7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006a7c:	1101                	addi	sp,sp,-32
    80006a7e:	ec06                	sd	ra,24(sp)
    80006a80:	e822                	sd	s0,16(sp)
    80006a82:	e426                	sd	s1,8(sp)
    80006a84:	1000                	addi	s0,sp,32
    80006a86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006a88:	ffffb097          	auipc	ra,0xffffb
    80006a8c:	f32080e7          	jalr	-206(ra) # 800019ba <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006a90:	00d5151b          	slliw	a0,a0,0xd
    80006a94:	0c2017b7          	lui	a5,0xc201
    80006a98:	97aa                	add	a5,a5,a0
    80006a9a:	c3c4                	sw	s1,4(a5)
}
    80006a9c:	60e2                	ld	ra,24(sp)
    80006a9e:	6442                	ld	s0,16(sp)
    80006aa0:	64a2                	ld	s1,8(sp)
    80006aa2:	6105                	addi	sp,sp,32
    80006aa4:	8082                	ret

0000000080006aa6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006aa6:	1141                	addi	sp,sp,-16
    80006aa8:	e406                	sd	ra,8(sp)
    80006aaa:	e022                	sd	s0,0(sp)
    80006aac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006aae:	479d                	li	a5,7
    80006ab0:	06a7c963          	blt	a5,a0,80006b22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006ab4:	00024797          	auipc	a5,0x24
    80006ab8:	54c78793          	addi	a5,a5,1356 # 8002b000 <disk>
    80006abc:	00a78733          	add	a4,a5,a0
    80006ac0:	6789                	lui	a5,0x2
    80006ac2:	97ba                	add	a5,a5,a4
    80006ac4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006ac8:	e7ad                	bnez	a5,80006b32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006aca:	00451793          	slli	a5,a0,0x4
    80006ace:	00026717          	auipc	a4,0x26
    80006ad2:	53270713          	addi	a4,a4,1330 # 8002d000 <disk+0x2000>
    80006ad6:	6314                	ld	a3,0(a4)
    80006ad8:	96be                	add	a3,a3,a5
    80006ada:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006ade:	6314                	ld	a3,0(a4)
    80006ae0:	96be                	add	a3,a3,a5
    80006ae2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006ae6:	6314                	ld	a3,0(a4)
    80006ae8:	96be                	add	a3,a3,a5
    80006aea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006aee:	6318                	ld	a4,0(a4)
    80006af0:	97ba                	add	a5,a5,a4
    80006af2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006af6:	00024797          	auipc	a5,0x24
    80006afa:	50a78793          	addi	a5,a5,1290 # 8002b000 <disk>
    80006afe:	97aa                	add	a5,a5,a0
    80006b00:	6509                	lui	a0,0x2
    80006b02:	953e                	add	a0,a0,a5
    80006b04:	4785                	li	a5,1
    80006b06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006b0a:	00026517          	auipc	a0,0x26
    80006b0e:	50e50513          	addi	a0,a0,1294 # 8002d018 <disk+0x2018>
    80006b12:	ffffb097          	auipc	ra,0xffffb
    80006b16:	486080e7          	jalr	1158(ra) # 80001f98 <wakeup>
}
    80006b1a:	60a2                	ld	ra,8(sp)
    80006b1c:	6402                	ld	s0,0(sp)
    80006b1e:	0141                	addi	sp,sp,16
    80006b20:	8082                	ret
    panic("free_desc 1");
    80006b22:	00002517          	auipc	a0,0x2
    80006b26:	ed650513          	addi	a0,a0,-298 # 800089f8 <syscalls+0x358>
    80006b2a:	ffffa097          	auipc	ra,0xffffa
    80006b2e:	a00080e7          	jalr	-1536(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006b32:	00002517          	auipc	a0,0x2
    80006b36:	ed650513          	addi	a0,a0,-298 # 80008a08 <syscalls+0x368>
    80006b3a:	ffffa097          	auipc	ra,0xffffa
    80006b3e:	9f0080e7          	jalr	-1552(ra) # 8000052a <panic>

0000000080006b42 <virtio_disk_init>:
{
    80006b42:	1101                	addi	sp,sp,-32
    80006b44:	ec06                	sd	ra,24(sp)
    80006b46:	e822                	sd	s0,16(sp)
    80006b48:	e426                	sd	s1,8(sp)
    80006b4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006b4c:	00002597          	auipc	a1,0x2
    80006b50:	ecc58593          	addi	a1,a1,-308 # 80008a18 <syscalls+0x378>
    80006b54:	00026517          	auipc	a0,0x26
    80006b58:	5d450513          	addi	a0,a0,1492 # 8002d128 <disk+0x2128>
    80006b5c:	ffffa097          	auipc	ra,0xffffa
    80006b60:	fd6080e7          	jalr	-42(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006b64:	100017b7          	lui	a5,0x10001
    80006b68:	4398                	lw	a4,0(a5)
    80006b6a:	2701                	sext.w	a4,a4
    80006b6c:	747277b7          	lui	a5,0x74727
    80006b70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006b74:	0ef71163          	bne	a4,a5,80006c56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006b78:	100017b7          	lui	a5,0x10001
    80006b7c:	43dc                	lw	a5,4(a5)
    80006b7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006b80:	4705                	li	a4,1
    80006b82:	0ce79a63          	bne	a5,a4,80006c56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006b86:	100017b7          	lui	a5,0x10001
    80006b8a:	479c                	lw	a5,8(a5)
    80006b8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006b8e:	4709                	li	a4,2
    80006b90:	0ce79363          	bne	a5,a4,80006c56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006b94:	100017b7          	lui	a5,0x10001
    80006b98:	47d8                	lw	a4,12(a5)
    80006b9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006b9c:	554d47b7          	lui	a5,0x554d4
    80006ba0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006ba4:	0af71963          	bne	a4,a5,80006c56 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ba8:	100017b7          	lui	a5,0x10001
    80006bac:	4705                	li	a4,1
    80006bae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006bb0:	470d                	li	a4,3
    80006bb2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006bb4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006bb6:	c7ffe737          	lui	a4,0xc7ffe
    80006bba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd075f>
    80006bbe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006bc0:	2701                	sext.w	a4,a4
    80006bc2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006bc4:	472d                	li	a4,11
    80006bc6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006bc8:	473d                	li	a4,15
    80006bca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006bcc:	6705                	lui	a4,0x1
    80006bce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006bd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006bd4:	5bdc                	lw	a5,52(a5)
    80006bd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006bd8:	c7d9                	beqz	a5,80006c66 <virtio_disk_init+0x124>
  if(max < NUM)
    80006bda:	471d                	li	a4,7
    80006bdc:	08f77d63          	bgeu	a4,a5,80006c76 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006be0:	100014b7          	lui	s1,0x10001
    80006be4:	47a1                	li	a5,8
    80006be6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006be8:	6609                	lui	a2,0x2
    80006bea:	4581                	li	a1,0
    80006bec:	00024517          	auipc	a0,0x24
    80006bf0:	41450513          	addi	a0,a0,1044 # 8002b000 <disk>
    80006bf4:	ffffa097          	auipc	ra,0xffffa
    80006bf8:	0dc080e7          	jalr	220(ra) # 80000cd0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006bfc:	00024717          	auipc	a4,0x24
    80006c00:	40470713          	addi	a4,a4,1028 # 8002b000 <disk>
    80006c04:	00c75793          	srli	a5,a4,0xc
    80006c08:	2781                	sext.w	a5,a5
    80006c0a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006c0c:	00026797          	auipc	a5,0x26
    80006c10:	3f478793          	addi	a5,a5,1012 # 8002d000 <disk+0x2000>
    80006c14:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006c16:	00024717          	auipc	a4,0x24
    80006c1a:	46a70713          	addi	a4,a4,1130 # 8002b080 <disk+0x80>
    80006c1e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006c20:	00025717          	auipc	a4,0x25
    80006c24:	3e070713          	addi	a4,a4,992 # 8002c000 <disk+0x1000>
    80006c28:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006c2a:	4705                	li	a4,1
    80006c2c:	00e78c23          	sb	a4,24(a5)
    80006c30:	00e78ca3          	sb	a4,25(a5)
    80006c34:	00e78d23          	sb	a4,26(a5)
    80006c38:	00e78da3          	sb	a4,27(a5)
    80006c3c:	00e78e23          	sb	a4,28(a5)
    80006c40:	00e78ea3          	sb	a4,29(a5)
    80006c44:	00e78f23          	sb	a4,30(a5)
    80006c48:	00e78fa3          	sb	a4,31(a5)
}
    80006c4c:	60e2                	ld	ra,24(sp)
    80006c4e:	6442                	ld	s0,16(sp)
    80006c50:	64a2                	ld	s1,8(sp)
    80006c52:	6105                	addi	sp,sp,32
    80006c54:	8082                	ret
    panic("could not find virtio disk");
    80006c56:	00002517          	auipc	a0,0x2
    80006c5a:	dd250513          	addi	a0,a0,-558 # 80008a28 <syscalls+0x388>
    80006c5e:	ffffa097          	auipc	ra,0xffffa
    80006c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006c66:	00002517          	auipc	a0,0x2
    80006c6a:	de250513          	addi	a0,a0,-542 # 80008a48 <syscalls+0x3a8>
    80006c6e:	ffffa097          	auipc	ra,0xffffa
    80006c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006c76:	00002517          	auipc	a0,0x2
    80006c7a:	df250513          	addi	a0,a0,-526 # 80008a68 <syscalls+0x3c8>
    80006c7e:	ffffa097          	auipc	ra,0xffffa
    80006c82:	8ac080e7          	jalr	-1876(ra) # 8000052a <panic>

0000000080006c86 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006c86:	7119                	addi	sp,sp,-128
    80006c88:	fc86                	sd	ra,120(sp)
    80006c8a:	f8a2                	sd	s0,112(sp)
    80006c8c:	f4a6                	sd	s1,104(sp)
    80006c8e:	f0ca                	sd	s2,96(sp)
    80006c90:	ecce                	sd	s3,88(sp)
    80006c92:	e8d2                	sd	s4,80(sp)
    80006c94:	e4d6                	sd	s5,72(sp)
    80006c96:	e0da                	sd	s6,64(sp)
    80006c98:	fc5e                	sd	s7,56(sp)
    80006c9a:	f862                	sd	s8,48(sp)
    80006c9c:	f466                	sd	s9,40(sp)
    80006c9e:	f06a                	sd	s10,32(sp)
    80006ca0:	ec6e                	sd	s11,24(sp)
    80006ca2:	0100                	addi	s0,sp,128
    80006ca4:	8aaa                	mv	s5,a0
    80006ca6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006ca8:	00c52c83          	lw	s9,12(a0)
    80006cac:	001c9c9b          	slliw	s9,s9,0x1
    80006cb0:	1c82                	slli	s9,s9,0x20
    80006cb2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006cb6:	00026517          	auipc	a0,0x26
    80006cba:	47250513          	addi	a0,a0,1138 # 8002d128 <disk+0x2128>
    80006cbe:	ffffa097          	auipc	ra,0xffffa
    80006cc2:	f04080e7          	jalr	-252(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006cc6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006cc8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006cca:	00024c17          	auipc	s8,0x24
    80006cce:	336c0c13          	addi	s8,s8,822 # 8002b000 <disk>
    80006cd2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006cd4:	4b0d                	li	s6,3
    80006cd6:	a0ad                	j	80006d40 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006cd8:	00fc0733          	add	a4,s8,a5
    80006cdc:	975e                	add	a4,a4,s7
    80006cde:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006ce2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006ce4:	0207c563          	bltz	a5,80006d0e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006ce8:	2905                	addiw	s2,s2,1
    80006cea:	0611                	addi	a2,a2,4
    80006cec:	19690d63          	beq	s2,s6,80006e86 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006cf0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006cf2:	00026717          	auipc	a4,0x26
    80006cf6:	32670713          	addi	a4,a4,806 # 8002d018 <disk+0x2018>
    80006cfa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006cfc:	00074683          	lbu	a3,0(a4)
    80006d00:	fee1                	bnez	a3,80006cd8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006d02:	2785                	addiw	a5,a5,1
    80006d04:	0705                	addi	a4,a4,1
    80006d06:	fe979be3          	bne	a5,s1,80006cfc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006d0a:	57fd                	li	a5,-1
    80006d0c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006d0e:	01205d63          	blez	s2,80006d28 <virtio_disk_rw+0xa2>
    80006d12:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006d14:	000a2503          	lw	a0,0(s4)
    80006d18:	00000097          	auipc	ra,0x0
    80006d1c:	d8e080e7          	jalr	-626(ra) # 80006aa6 <free_desc>
      for(int j = 0; j < i; j++)
    80006d20:	2d85                	addiw	s11,s11,1
    80006d22:	0a11                	addi	s4,s4,4
    80006d24:	ffb918e3          	bne	s2,s11,80006d14 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006d28:	00026597          	auipc	a1,0x26
    80006d2c:	40058593          	addi	a1,a1,1024 # 8002d128 <disk+0x2128>
    80006d30:	00026517          	auipc	a0,0x26
    80006d34:	2e850513          	addi	a0,a0,744 # 8002d018 <disk+0x2018>
    80006d38:	ffffb097          	auipc	ra,0xffffb
    80006d3c:	1fc080e7          	jalr	508(ra) # 80001f34 <sleep>
  for(int i = 0; i < 3; i++){
    80006d40:	f8040a13          	addi	s4,s0,-128
{
    80006d44:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006d46:	894e                	mv	s2,s3
    80006d48:	b765                	j	80006cf0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006d4a:	00026697          	auipc	a3,0x26
    80006d4e:	2b66b683          	ld	a3,694(a3) # 8002d000 <disk+0x2000>
    80006d52:	96ba                	add	a3,a3,a4
    80006d54:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006d58:	00024817          	auipc	a6,0x24
    80006d5c:	2a880813          	addi	a6,a6,680 # 8002b000 <disk>
    80006d60:	00026697          	auipc	a3,0x26
    80006d64:	2a068693          	addi	a3,a3,672 # 8002d000 <disk+0x2000>
    80006d68:	6290                	ld	a2,0(a3)
    80006d6a:	963a                	add	a2,a2,a4
    80006d6c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006d70:	0015e593          	ori	a1,a1,1
    80006d74:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006d78:	f8842603          	lw	a2,-120(s0)
    80006d7c:	628c                	ld	a1,0(a3)
    80006d7e:	972e                	add	a4,a4,a1
    80006d80:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d84:	20050593          	addi	a1,a0,512
    80006d88:	0592                	slli	a1,a1,0x4
    80006d8a:	95c2                	add	a1,a1,a6
    80006d8c:	577d                	li	a4,-1
    80006d8e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d92:	00461713          	slli	a4,a2,0x4
    80006d96:	6290                	ld	a2,0(a3)
    80006d98:	963a                	add	a2,a2,a4
    80006d9a:	03078793          	addi	a5,a5,48
    80006d9e:	97c2                	add	a5,a5,a6
    80006da0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006da2:	629c                	ld	a5,0(a3)
    80006da4:	97ba                	add	a5,a5,a4
    80006da6:	4605                	li	a2,1
    80006da8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006daa:	629c                	ld	a5,0(a3)
    80006dac:	97ba                	add	a5,a5,a4
    80006dae:	4809                	li	a6,2
    80006db0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006db4:	629c                	ld	a5,0(a3)
    80006db6:	973e                	add	a4,a4,a5
    80006db8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006dbc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006dc0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006dc4:	6698                	ld	a4,8(a3)
    80006dc6:	00275783          	lhu	a5,2(a4)
    80006dca:	8b9d                	andi	a5,a5,7
    80006dcc:	0786                	slli	a5,a5,0x1
    80006dce:	97ba                	add	a5,a5,a4
    80006dd0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006dd4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006dd8:	6698                	ld	a4,8(a3)
    80006dda:	00275783          	lhu	a5,2(a4)
    80006dde:	2785                	addiw	a5,a5,1
    80006de0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006de4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006de8:	100017b7          	lui	a5,0x10001
    80006dec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006df0:	004aa783          	lw	a5,4(s5)
    80006df4:	02c79163          	bne	a5,a2,80006e16 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006df8:	00026917          	auipc	s2,0x26
    80006dfc:	33090913          	addi	s2,s2,816 # 8002d128 <disk+0x2128>
  while(b->disk == 1) {
    80006e00:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006e02:	85ca                	mv	a1,s2
    80006e04:	8556                	mv	a0,s5
    80006e06:	ffffb097          	auipc	ra,0xffffb
    80006e0a:	12e080e7          	jalr	302(ra) # 80001f34 <sleep>
  while(b->disk == 1) {
    80006e0e:	004aa783          	lw	a5,4(s5)
    80006e12:	fe9788e3          	beq	a5,s1,80006e02 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006e16:	f8042903          	lw	s2,-128(s0)
    80006e1a:	20090793          	addi	a5,s2,512
    80006e1e:	00479713          	slli	a4,a5,0x4
    80006e22:	00024797          	auipc	a5,0x24
    80006e26:	1de78793          	addi	a5,a5,478 # 8002b000 <disk>
    80006e2a:	97ba                	add	a5,a5,a4
    80006e2c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006e30:	00026997          	auipc	s3,0x26
    80006e34:	1d098993          	addi	s3,s3,464 # 8002d000 <disk+0x2000>
    80006e38:	00491713          	slli	a4,s2,0x4
    80006e3c:	0009b783          	ld	a5,0(s3)
    80006e40:	97ba                	add	a5,a5,a4
    80006e42:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006e46:	854a                	mv	a0,s2
    80006e48:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006e4c:	00000097          	auipc	ra,0x0
    80006e50:	c5a080e7          	jalr	-934(ra) # 80006aa6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006e54:	8885                	andi	s1,s1,1
    80006e56:	f0ed                	bnez	s1,80006e38 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006e58:	00026517          	auipc	a0,0x26
    80006e5c:	2d050513          	addi	a0,a0,720 # 8002d128 <disk+0x2128>
    80006e60:	ffffa097          	auipc	ra,0xffffa
    80006e64:	e28080e7          	jalr	-472(ra) # 80000c88 <release>
}
    80006e68:	70e6                	ld	ra,120(sp)
    80006e6a:	7446                	ld	s0,112(sp)
    80006e6c:	74a6                	ld	s1,104(sp)
    80006e6e:	7906                	ld	s2,96(sp)
    80006e70:	69e6                	ld	s3,88(sp)
    80006e72:	6a46                	ld	s4,80(sp)
    80006e74:	6aa6                	ld	s5,72(sp)
    80006e76:	6b06                	ld	s6,64(sp)
    80006e78:	7be2                	ld	s7,56(sp)
    80006e7a:	7c42                	ld	s8,48(sp)
    80006e7c:	7ca2                	ld	s9,40(sp)
    80006e7e:	7d02                	ld	s10,32(sp)
    80006e80:	6de2                	ld	s11,24(sp)
    80006e82:	6109                	addi	sp,sp,128
    80006e84:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e86:	f8042503          	lw	a0,-128(s0)
    80006e8a:	20050793          	addi	a5,a0,512
    80006e8e:	0792                	slli	a5,a5,0x4
  if(write)
    80006e90:	00024817          	auipc	a6,0x24
    80006e94:	17080813          	addi	a6,a6,368 # 8002b000 <disk>
    80006e98:	00f80733          	add	a4,a6,a5
    80006e9c:	01a036b3          	snez	a3,s10
    80006ea0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006ea4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006ea8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006eac:	7679                	lui	a2,0xffffe
    80006eae:	963e                	add	a2,a2,a5
    80006eb0:	00026697          	auipc	a3,0x26
    80006eb4:	15068693          	addi	a3,a3,336 # 8002d000 <disk+0x2000>
    80006eb8:	6298                	ld	a4,0(a3)
    80006eba:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006ebc:	0a878593          	addi	a1,a5,168
    80006ec0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006ec2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006ec4:	6298                	ld	a4,0(a3)
    80006ec6:	9732                	add	a4,a4,a2
    80006ec8:	45c1                	li	a1,16
    80006eca:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006ecc:	6298                	ld	a4,0(a3)
    80006ece:	9732                	add	a4,a4,a2
    80006ed0:	4585                	li	a1,1
    80006ed2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006ed6:	f8442703          	lw	a4,-124(s0)
    80006eda:	628c                	ld	a1,0(a3)
    80006edc:	962e                	add	a2,a2,a1
    80006ede:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd000e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ee2:	0712                	slli	a4,a4,0x4
    80006ee4:	6290                	ld	a2,0(a3)
    80006ee6:	963a                	add	a2,a2,a4
    80006ee8:	058a8593          	addi	a1,s5,88
    80006eec:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006eee:	6294                	ld	a3,0(a3)
    80006ef0:	96ba                	add	a3,a3,a4
    80006ef2:	40000613          	li	a2,1024
    80006ef6:	c690                	sw	a2,8(a3)
  if(write)
    80006ef8:	e40d19e3          	bnez	s10,80006d4a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006efc:	00026697          	auipc	a3,0x26
    80006f00:	1046b683          	ld	a3,260(a3) # 8002d000 <disk+0x2000>
    80006f04:	96ba                	add	a3,a3,a4
    80006f06:	4609                	li	a2,2
    80006f08:	00c69623          	sh	a2,12(a3)
    80006f0c:	b5b1                	j	80006d58 <virtio_disk_rw+0xd2>

0000000080006f0e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006f0e:	1101                	addi	sp,sp,-32
    80006f10:	ec06                	sd	ra,24(sp)
    80006f12:	e822                	sd	s0,16(sp)
    80006f14:	e426                	sd	s1,8(sp)
    80006f16:	e04a                	sd	s2,0(sp)
    80006f18:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006f1a:	00026517          	auipc	a0,0x26
    80006f1e:	20e50513          	addi	a0,a0,526 # 8002d128 <disk+0x2128>
    80006f22:	ffffa097          	auipc	ra,0xffffa
    80006f26:	ca0080e7          	jalr	-864(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006f2a:	10001737          	lui	a4,0x10001
    80006f2e:	533c                	lw	a5,96(a4)
    80006f30:	8b8d                	andi	a5,a5,3
    80006f32:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006f34:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006f38:	00026797          	auipc	a5,0x26
    80006f3c:	0c878793          	addi	a5,a5,200 # 8002d000 <disk+0x2000>
    80006f40:	6b94                	ld	a3,16(a5)
    80006f42:	0207d703          	lhu	a4,32(a5)
    80006f46:	0026d783          	lhu	a5,2(a3)
    80006f4a:	06f70163          	beq	a4,a5,80006fac <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006f4e:	00024917          	auipc	s2,0x24
    80006f52:	0b290913          	addi	s2,s2,178 # 8002b000 <disk>
    80006f56:	00026497          	auipc	s1,0x26
    80006f5a:	0aa48493          	addi	s1,s1,170 # 8002d000 <disk+0x2000>
    __sync_synchronize();
    80006f5e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006f62:	6898                	ld	a4,16(s1)
    80006f64:	0204d783          	lhu	a5,32(s1)
    80006f68:	8b9d                	andi	a5,a5,7
    80006f6a:	078e                	slli	a5,a5,0x3
    80006f6c:	97ba                	add	a5,a5,a4
    80006f6e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006f70:	20078713          	addi	a4,a5,512
    80006f74:	0712                	slli	a4,a4,0x4
    80006f76:	974a                	add	a4,a4,s2
    80006f78:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006f7c:	e731                	bnez	a4,80006fc8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006f7e:	20078793          	addi	a5,a5,512
    80006f82:	0792                	slli	a5,a5,0x4
    80006f84:	97ca                	add	a5,a5,s2
    80006f86:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006f88:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006f8c:	ffffb097          	auipc	ra,0xffffb
    80006f90:	00c080e7          	jalr	12(ra) # 80001f98 <wakeup>

    disk.used_idx += 1;
    80006f94:	0204d783          	lhu	a5,32(s1)
    80006f98:	2785                	addiw	a5,a5,1
    80006f9a:	17c2                	slli	a5,a5,0x30
    80006f9c:	93c1                	srli	a5,a5,0x30
    80006f9e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006fa2:	6898                	ld	a4,16(s1)
    80006fa4:	00275703          	lhu	a4,2(a4)
    80006fa8:	faf71be3          	bne	a4,a5,80006f5e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006fac:	00026517          	auipc	a0,0x26
    80006fb0:	17c50513          	addi	a0,a0,380 # 8002d128 <disk+0x2128>
    80006fb4:	ffffa097          	auipc	ra,0xffffa
    80006fb8:	cd4080e7          	jalr	-812(ra) # 80000c88 <release>
}
    80006fbc:	60e2                	ld	ra,24(sp)
    80006fbe:	6442                	ld	s0,16(sp)
    80006fc0:	64a2                	ld	s1,8(sp)
    80006fc2:	6902                	ld	s2,0(sp)
    80006fc4:	6105                	addi	sp,sp,32
    80006fc6:	8082                	ret
      panic("virtio_disk_intr status");
    80006fc8:	00002517          	auipc	a0,0x2
    80006fcc:	ac050513          	addi	a0,a0,-1344 # 80008a88 <syscalls+0x3e8>
    80006fd0:	ffff9097          	auipc	ra,0xffff9
    80006fd4:	55a080e7          	jalr	1370(ra) # 8000052a <panic>
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
