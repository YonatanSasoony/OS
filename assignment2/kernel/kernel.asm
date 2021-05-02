
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
    80000068:	8ac78793          	addi	a5,a5,-1876 # 80006910 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffbc7ff>
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
    80000122:	8da080e7          	jalr	-1830(ra) # 800029f8 <either_copyin>
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
    800001b6:	844080e7          	jalr	-1980(ra) # 800019f6 <myproc>
    800001ba:	4d5c                	lw	a5,28(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	4da080e7          	jalr	1242(ra) # 8000269c <sleep>
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
    80000202:	7a2080e7          	jalr	1954(ra) # 800029a0 <either_copyout>
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
    800002e2:	772080e7          	jalr	1906(ra) # 80002a50 <procdump>
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
    80000436:	3f4080e7          	jalr	1012(ra) # 80002826 <wakeup>
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
    80000464:	0003d797          	auipc	a5,0x3d
    80000468:	4cc78793          	addi	a5,a5,1228 # 8003d930 <devsw>
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
    8000055c:	ce050513          	addi	a0,a0,-800 # 80008238 <digits+0x1f8>
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
    80000882:	fa8080e7          	jalr	-88(ra) # 80002826 <wakeup>
    
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
    8000090e:	d92080e7          	jalr	-622(ra) # 8000269c <sleep>
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
    800009ea:	00041797          	auipc	a5,0x41
    800009ee:	61678793          	addi	a5,a5,1558 # 80042000 <end>
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
    80000aba:	00041517          	auipc	a0,0x41
    80000abe:	54650513          	addi	a0,a0,1350 # 80042000 <end>
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
    80000b60:	e7e080e7          	jalr	-386(ra) # 800019da <mycpu>
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
    80000b92:	e4c080e7          	jalr	-436(ra) # 800019da <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e40080e7          	jalr	-448(ra) # 800019da <mycpu>
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
    80000bb6:	e28080e7          	jalr	-472(ra) # 800019da <mycpu>
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
    80000bf6:	de8080e7          	jalr	-536(ra) # 800019da <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    printf("PANIC-%s\n",lk->name); //REMOVE
    80000c06:	648c                	ld	a1,8(s1)
    80000c08:	00007517          	auipc	a0,0x7
    80000c0c:	46850513          	addi	a0,a0,1128 # 80008070 <digits+0x30>
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	964080e7          	jalr	-1692(ra) # 80000574 <printf>
    panic("acquire\n");
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
    80000c34:	daa080e7          	jalr	-598(ra) # 800019da <mycpu>
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
    80000c6c:	42850513          	addi	a0,a0,1064 # 80008090 <digits+0x50>
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	8ba080e7          	jalr	-1862(ra) # 8000052a <panic>
    panic("pop_off");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	43050513          	addi	a0,a0,1072 # 800080a8 <digits+0x68>
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
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3ae50513          	addi	a0,a0,942 # 80008070 <digits+0x30>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	8aa080e7          	jalr	-1878(ra) # 80000574 <printf>
    panic("release");
    80000cd2:	00007517          	auipc	a0,0x7
    80000cd6:	3de50513          	addi	a0,a0,990 # 800080b0 <digits+0x70>
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
    80000e9c:	b32080e7          	jalr	-1230(ra) # 800019ca <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea0:	00008717          	auipc	a4,0x8
    80000ea4:	17870713          	addi	a4,a4,376 # 80009018 <started>
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
    80000eb8:	b16080e7          	jalr	-1258(ra) # 800019ca <cpuid>
    80000ebc:	85aa                	mv	a1,a0
    80000ebe:	00007517          	auipc	a0,0x7
    80000ec2:	21250513          	addi	a0,a0,530 # 800080d0 <digits+0x90>
    80000ec6:	fffff097          	auipc	ra,0xfffff
    80000eca:	6ae080e7          	jalr	1710(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000ece:	00000097          	auipc	ra,0x0
    80000ed2:	0d8080e7          	jalr	216(ra) # 80000fa6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed6:	00002097          	auipc	ra,0x2
    80000eda:	260080e7          	jalr	608(ra) # 80003136 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00006097          	auipc	ra,0x6
    80000ee2:	a72080e7          	jalr	-1422(ra) # 80006950 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	426080e7          	jalr	1062(ra) # 8000230c <scheduler>
    consoleinit();
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	54e080e7          	jalr	1358(ra) # 8000043c <consoleinit>
    printfinit();
    80000ef6:	00000097          	auipc	ra,0x0
    80000efa:	85e080e7          	jalr	-1954(ra) # 80000754 <printfinit>
    printf("\n");
    80000efe:	00007517          	auipc	a0,0x7
    80000f02:	33a50513          	addi	a0,a0,826 # 80008238 <digits+0x1f8>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	66e080e7          	jalr	1646(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	1aa50513          	addi	a0,a0,426 # 800080b8 <digits+0x78>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	65e080e7          	jalr	1630(ra) # 80000574 <printf>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	31a50513          	addi	a0,a0,794 # 80008238 <digits+0x1f8>
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
    80000f4a:	9cc080e7          	jalr	-1588(ra) # 80001912 <procinit>
    trapinit();      // trap vectors
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	1c0080e7          	jalr	448(ra) # 8000310e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	1e0080e7          	jalr	480(ra) # 80003136 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00006097          	auipc	ra,0x6
    80000f62:	9dc080e7          	jalr	-1572(ra) # 8000693a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00006097          	auipc	ra,0x6
    80000f6a:	9ea080e7          	jalr	-1558(ra) # 80006950 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00003097          	auipc	ra,0x3
    80000f72:	b18080e7          	jalr	-1256(ra) # 80003a86 <binit>
    iinit();         // inode cache
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	1aa080e7          	jalr	426(ra) # 80004120 <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	158080e7          	jalr	344(ra) # 800050d6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00006097          	auipc	ra,0x6
    80000f8a:	aec080e7          	jalr	-1300(ra) # 80006a72 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	f4e080e7          	jalr	-178(ra) # 80001edc <userinit>
    __sync_synchronize();
    80000f96:	0ff0000f          	fence
    started = 1;
    80000f9a:	4785                	li	a5,1
    80000f9c:	00008717          	auipc	a4,0x8
    80000fa0:	06f72e23          	sw	a5,124(a4) # 80009018 <started>
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
    80000fac:	00008797          	auipc	a5,0x8
    80000fb0:	0747b783          	ld	a5,116(a5) # 80009020 <kernel_pagetable>
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
    80000ff0:	00007517          	auipc	a0,0x7
    80000ff4:	0f850513          	addi	a0,a0,248 # 800080e8 <digits+0xa8>
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
    80001114:	00007517          	auipc	a0,0x7
    80001118:	fdc50513          	addi	a0,a0,-36 # 800080f0 <digits+0xb0>
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
    80001160:	00007517          	auipc	a0,0x7
    80001164:	f9850513          	addi	a0,a0,-104 # 800080f8 <digits+0xb8>
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
    800011d6:	00007917          	auipc	s2,0x7
    800011da:	e2a90913          	addi	s2,s2,-470 # 80008000 <etext>
    800011de:	4729                	li	a4,10
    800011e0:	80007697          	auipc	a3,0x80007
    800011e4:	e2068693          	addi	a3,a3,-480 # 8000 <_entry-0x7fff8000>
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
    80001214:	00006617          	auipc	a2,0x6
    80001218:	dec60613          	addi	a2,a2,-532 # 80007000 <_trampoline>
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
    80001256:	00008797          	auipc	a5,0x8
    8000125a:	dca7b523          	sd	a0,-566(a5) # 80009020 <kernel_pagetable>
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
    800012ac:	00007517          	auipc	a0,0x7
    800012b0:	e5450513          	addi	a0,a0,-428 # 80008100 <digits+0xc0>
    800012b4:	fffff097          	auipc	ra,0xfffff
    800012b8:	276080e7          	jalr	630(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e5c50513          	addi	a0,a0,-420 # 80008118 <digits+0xd8>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	266080e7          	jalr	614(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e5c50513          	addi	a0,a0,-420 # 80008128 <digits+0xe8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	256080e7          	jalr	598(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e6450513          	addi	a0,a0,-412 # 80008140 <digits+0x100>
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
    800013ba:	00007517          	auipc	a0,0x7
    800013be:	d9e50513          	addi	a0,a0,-610 # 80008158 <digits+0x118>
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
    800014fc:	00007517          	auipc	a0,0x7
    80001500:	c7c50513          	addi	a0,a0,-900 # 80008178 <digits+0x138>
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
    800015d8:	00007517          	auipc	a0,0x7
    800015dc:	bb050513          	addi	a0,a0,-1104 # 80008188 <digits+0x148>
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	f4a080e7          	jalr	-182(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	bc050513          	addi	a0,a0,-1088 # 800081a8 <digits+0x168>
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
    80001652:	00007517          	auipc	a0,0x7
    80001656:	b7650513          	addi	a0,a0,-1162 # 800081c8 <digits+0x188>
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
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffbd000>
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
    8000188a:	00010497          	auipc	s1,0x10
    8000188e:	e5e48493          	addi	s1,s1,-418 # 800116e8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    80001892:	8c26                	mv	s8,s1
    80001894:	00006b97          	auipc	s7,0x6
    80001898:	76cb8b93          	addi	s7,s7,1900 # 80008000 <etext>
    8000189c:	04000937          	lui	s2,0x4000
    800018a0:	197d                	addi	s2,s2,-1
    800018a2:	0932                	slli	s2,s2,0xc
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a4:	6a05                	lui	s4,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a6:	880a0b13          	addi	s6,s4,-1920 # 880 <_entry-0x7ffff780>
    800018aa:	00032a97          	auipc	s5,0x32
    800018ae:	e3ea8a93          	addi	s5,s5,-450 # 800336e8 <tickslock>
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
    80001902:	00007517          	auipc	a0,0x7
    80001906:	8d650513          	addi	a0,a0,-1834 # 800081d8 <digits+0x198>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	c20080e7          	jalr	-992(ra) # 8000052a <panic>

0000000080001912 <procinit>:
{
    80001912:	715d                	addi	sp,sp,-80
    80001914:	e486                	sd	ra,72(sp)
    80001916:	e0a2                	sd	s0,64(sp)
    80001918:	fc26                	sd	s1,56(sp)
    8000191a:	f84a                	sd	s2,48(sp)
    8000191c:	f44e                	sd	s3,40(sp)
    8000191e:	f052                	sd	s4,32(sp)
    80001920:	ec56                	sd	s5,24(sp)
    80001922:	e85a                	sd	s6,16(sp)
    80001924:	e45e                	sd	s7,8(sp)
    80001926:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001928:	00007597          	auipc	a1,0x7
    8000192c:	8b858593          	addi	a1,a1,-1864 # 800081e0 <digits+0x1a0>
    80001930:	00010517          	auipc	a0,0x10
    80001934:	97050513          	addi	a0,a0,-1680 # 800112a0 <pid_lock>
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	1fa080e7          	jalr	506(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001940:	00007597          	auipc	a1,0x7
    80001944:	8a858593          	addi	a1,a1,-1880 # 800081e8 <digits+0x1a8>
    80001948:	00010517          	auipc	a0,0x10
    8000194c:	97050513          	addi	a0,a0,-1680 # 800112b8 <wait_lock>
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	1e2080e7          	jalr	482(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	00010917          	auipc	s2,0x10
    8000195c:	60890913          	addi	s2,s2,1544 # 80011f60 <proc+0x878>
    80001960:	00032b97          	auipc	s7,0x32
    80001964:	600b8b93          	addi	s7,s7,1536 # 80033f60 <bcache+0x860>
    initlock(&p->lock, "proc");
    80001968:	7afd                	lui	s5,0xfffff
    8000196a:	788a8a93          	addi	s5,s5,1928 # fffffffffffff788 <end+0xffffffff7ffbd788>
    8000196e:	00007b17          	auipc	s6,0x7
    80001972:	88ab0b13          	addi	s6,s6,-1910 # 800081f8 <digits+0x1b8>
      initlock(&t->lock, "thread");
    80001976:	00007997          	auipc	s3,0x7
    8000197a:	88a98993          	addi	s3,s3,-1910 # 80008200 <digits+0x1c0>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	6a05                	lui	s4,0x1
    80001980:	880a0a13          	addi	s4,s4,-1920 # 880 <_entry-0x7ffff780>
    80001984:	a021                	j	8000198c <procinit+0x7a>
    80001986:	9952                	add	s2,s2,s4
    80001988:	03790663          	beq	s2,s7,800019b4 <procinit+0xa2>
    initlock(&p->lock, "proc");
    8000198c:	85da                	mv	a1,s6
    8000198e:	01590533          	add	a0,s2,s5
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	1a0080e7          	jalr	416(ra) # 80000b32 <initlock>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000199a:	a0090493          	addi	s1,s2,-1536
      initlock(&t->lock, "thread");
    8000199e:	85ce                	mv	a1,s3
    800019a0:	8526                	mv	a0,s1
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	190080e7          	jalr	400(ra) # 80000b32 <initlock>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800019aa:	0c048493          	addi	s1,s1,192
    800019ae:	ff2498e3          	bne	s1,s2,8000199e <procinit+0x8c>
    800019b2:	bfd1                	j	80001986 <procinit+0x74>
}
    800019b4:	60a6                	ld	ra,72(sp)
    800019b6:	6406                	ld	s0,64(sp)
    800019b8:	74e2                	ld	s1,56(sp)
    800019ba:	7942                	ld	s2,48(sp)
    800019bc:	79a2                	ld	s3,40(sp)
    800019be:	7a02                	ld	s4,32(sp)
    800019c0:	6ae2                	ld	s5,24(sp)
    800019c2:	6b42                	ld	s6,16(sp)
    800019c4:	6ba2                	ld	s7,8(sp)
    800019c6:	6161                	addi	sp,sp,80
    800019c8:	8082                	ret

00000000800019ca <cpuid>:
{
    800019ca:	1141                	addi	sp,sp,-16
    800019cc:	e422                	sd	s0,8(sp)
    800019ce:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019d0:	8512                	mv	a0,tp
}
    800019d2:	2501                	sext.w	a0,a0
    800019d4:	6422                	ld	s0,8(sp)
    800019d6:	0141                	addi	sp,sp,16
    800019d8:	8082                	ret

00000000800019da <mycpu>:
mycpu(void) {
    800019da:	1141                	addi	sp,sp,-16
    800019dc:	e422                	sd	s0,8(sp)
    800019de:	0800                	addi	s0,sp,16
    800019e0:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
}
    800019e6:	00010517          	auipc	a0,0x10
    800019ea:	8ea50513          	addi	a0,a0,-1814 # 800112d0 <cpus>
    800019ee:	953e                	add	a0,a0,a5
    800019f0:	6422                	ld	s0,8(sp)
    800019f2:	0141                	addi	sp,sp,16
    800019f4:	8082                	ret

00000000800019f6 <myproc>:
myproc(void) {
    800019f6:	1101                	addi	sp,sp,-32
    800019f8:	ec06                	sd	ra,24(sp)
    800019fa:	e822                	sd	s0,16(sp)
    800019fc:	e426                	sd	s1,8(sp)
    800019fe:	1000                	addi	s0,sp,32
  push_off();
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	176080e7          	jalr	374(ra) # 80000b76 <push_off>
    80001a08:	8792                	mv	a5,tp
  struct proc *p = c->thread->proc; //ADDED Q3
    80001a0a:	2781                	sext.w	a5,a5
    80001a0c:	079e                	slli	a5,a5,0x7
    80001a0e:	00010717          	auipc	a4,0x10
    80001a12:	89270713          	addi	a4,a4,-1902 # 800112a0 <pid_lock>
    80001a16:	97ba                	add	a5,a5,a4
    80001a18:	7b9c                	ld	a5,48(a5)
    80001a1a:	7f84                	ld	s1,56(a5)
  pop_off();
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	20c080e7          	jalr	524(ra) # 80000c28 <pop_off>
}
    80001a24:	8526                	mv	a0,s1
    80001a26:	60e2                	ld	ra,24(sp)
    80001a28:	6442                	ld	s0,16(sp)
    80001a2a:	64a2                	ld	s1,8(sp)
    80001a2c:	6105                	addi	sp,sp,32
    80001a2e:	8082                	ret

0000000080001a30 <mythread>:
mythread(void) {
    80001a30:	1101                	addi	sp,sp,-32
    80001a32:	ec06                	sd	ra,24(sp)
    80001a34:	e822                	sd	s0,16(sp)
    80001a36:	e426                	sd	s1,8(sp)
    80001a38:	1000                	addi	s0,sp,32
  push_off();
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	13c080e7          	jalr	316(ra) # 80000b76 <push_off>
    80001a42:	8792                	mv	a5,tp
  struct thread *t = c->thread;
    80001a44:	2781                	sext.w	a5,a5
    80001a46:	079e                	slli	a5,a5,0x7
    80001a48:	00010717          	auipc	a4,0x10
    80001a4c:	85870713          	addi	a4,a4,-1960 # 800112a0 <pid_lock>
    80001a50:	97ba                	add	a5,a5,a4
    80001a52:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	1d4080e7          	jalr	468(ra) # 80000c28 <pop_off>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6105                	addi	sp,sp,32
    80001a66:	8082                	ret

0000000080001a68 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a68:	1141                	addi	sp,sp,-16
    80001a6a:	e406                	sd	ra,8(sp)
    80001a6c:	e022                	sd	s0,0(sp)
    80001a6e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding t->lock from scheduler.
  release(&mythread()->lock); // ADDED Q3
    80001a70:	00000097          	auipc	ra,0x0
    80001a74:	fc0080e7          	jalr	-64(ra) # 80001a30 <mythread>
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	210080e7          	jalr	528(ra) # 80000c88 <release>

  if (first) {
    80001a80:	00007797          	auipc	a5,0x7
    80001a84:	dd07a783          	lw	a5,-560(a5) # 80008850 <first.1>
    80001a88:	eb89                	bnez	a5,80001a9a <forkret+0x32>
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }
  usertrapret();
    80001a8a:	00001097          	auipc	ra,0x1
    80001a8e:	6c4080e7          	jalr	1732(ra) # 8000314e <usertrapret>
}
    80001a92:	60a2                	ld	ra,8(sp)
    80001a94:	6402                	ld	s0,0(sp)
    80001a96:	0141                	addi	sp,sp,16
    80001a98:	8082                	ret
    first = 0;
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	da07ab23          	sw	zero,-586(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001aa2:	4505                	li	a0,1
    80001aa4:	00002097          	auipc	ra,0x2
    80001aa8:	5fc080e7          	jalr	1532(ra) # 800040a0 <fsinit>
    80001aac:	bff9                	j	80001a8a <forkret+0x22>

0000000080001aae <allocpid>:
allocpid() {
    80001aae:	1101                	addi	sp,sp,-32
    80001ab0:	ec06                	sd	ra,24(sp)
    80001ab2:	e822                	sd	s0,16(sp)
    80001ab4:	e426                	sd	s1,8(sp)
    80001ab6:	e04a                	sd	s2,0(sp)
    80001ab8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aba:	0000f917          	auipc	s2,0xf
    80001abe:	7e690913          	addi	s2,s2,2022 # 800112a0 <pid_lock>
    80001ac2:	854a                	mv	a0,s2
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	0fe080e7          	jalr	254(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001acc:	00007797          	auipc	a5,0x7
    80001ad0:	d8c78793          	addi	a5,a5,-628 # 80008858 <nextpid>
    80001ad4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ad6:	0014871b          	addiw	a4,s1,1
    80001ada:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001adc:	854a                	mv	a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	1aa080e7          	jalr	426(ra) # 80000c88 <release>
}
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	60e2                	ld	ra,24(sp)
    80001aea:	6442                	ld	s0,16(sp)
    80001aec:	64a2                	ld	s1,8(sp)
    80001aee:	6902                	ld	s2,0(sp)
    80001af0:	6105                	addi	sp,sp,32
    80001af2:	8082                	ret

0000000080001af4 <alloctid>:
alloctid() {
    80001af4:	1101                	addi	sp,sp,-32
    80001af6:	ec06                	sd	ra,24(sp)
    80001af8:	e822                	sd	s0,16(sp)
    80001afa:	e426                	sd	s1,8(sp)
    80001afc:	e04a                	sd	s2,0(sp)
    80001afe:	1000                	addi	s0,sp,32
  acquire(&tid_lock);
    80001b00:	00010917          	auipc	s2,0x10
    80001b04:	bd090913          	addi	s2,s2,-1072 # 800116d0 <tid_lock>
    80001b08:	854a                	mv	a0,s2
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	0b8080e7          	jalr	184(ra) # 80000bc2 <acquire>
  tid = nexttid;
    80001b12:	00007797          	auipc	a5,0x7
    80001b16:	d4278793          	addi	a5,a5,-702 # 80008854 <nexttid>
    80001b1a:	4384                	lw	s1,0(a5)
  nexttid = nexttid + 1;
    80001b1c:	0014871b          	addiw	a4,s1,1
    80001b20:	c398                	sw	a4,0(a5)
  release(&tid_lock);
    80001b22:	854a                	mv	a0,s2
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	164080e7          	jalr	356(ra) # 80000c88 <release>
}
    80001b2c:	8526                	mv	a0,s1
    80001b2e:	60e2                	ld	ra,24(sp)
    80001b30:	6442                	ld	s0,16(sp)
    80001b32:	64a2                	ld	s1,8(sp)
    80001b34:	6902                	ld	s2,0(sp)
    80001b36:	6105                	addi	sp,sp,32
    80001b38:	8082                	ret

0000000080001b3a <allocthread>:
{
    80001b3a:	7179                	addi	sp,sp,-48
    80001b3c:	f406                	sd	ra,40(sp)
    80001b3e:	f022                	sd	s0,32(sp)
    80001b40:	ec26                	sd	s1,24(sp)
    80001b42:	e84a                	sd	s2,16(sp)
    80001b44:	e44e                	sd	s3,8(sp)
    80001b46:	e052                	sd	s4,0(sp)
    80001b48:	1800                	addi	s0,sp,48
    80001b4a:	8a2a                	mv	s4,a0
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001b4c:	27850493          	addi	s1,a0,632
    int t_index = 0;
    80001b50:	4901                	li	s2,0
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001b52:	49a1                	li	s3,8
    80001b54:	a88d                	j	80001bc6 <allocthread+0x8c>
  t->tid = alloctid();
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	f9e080e7          	jalr	-98(ra) # 80001af4 <alloctid>
    80001b5e:	d888                	sw	a0,48(s1)
  t->index = t_index;
    80001b60:	0324aa23          	sw	s2,52(s1)
  t->state = USED_T;
    80001b64:	4785                	li	a5,1
    80001b66:	cc9c                	sw	a5,24(s1)
  t->trapframe = &p->trapframes[t_index];
    80001b68:	6705                	lui	a4,0x1
    80001b6a:	9752                	add	a4,a4,s4
    80001b6c:	00391793          	slli	a5,s2,0x3
    80001b70:	993e                	add	s2,s2,a5
    80001b72:	0916                	slli	s2,s2,0x5
    80001b74:	87873783          	ld	a5,-1928(a4) # 878 <_entry-0x7ffff788>
    80001b78:	993e                	add	s2,s2,a5
    80001b7a:	0524b423          	sd	s2,72(s1)
  t->terminated = 0;
    80001b7e:	0204a423          	sw	zero,40(s1)
  t->proc = p;
    80001b82:	0344bc23          	sd	s4,56(s1)
  memset(&t->context, 0, sizeof(t->context));
    80001b86:	07000613          	li	a2,112
    80001b8a:	4581                	li	a1,0
    80001b8c:	05048513          	addi	a0,s1,80
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	152080e7          	jalr	338(ra) # 80000ce2 <memset>
  t->context.ra = (uint64)forkret;
    80001b98:	00000797          	auipc	a5,0x0
    80001b9c:	ed078793          	addi	a5,a5,-304 # 80001a68 <forkret>
    80001ba0:	e8bc                	sd	a5,80(s1)
  if((t->kstack = (uint64)kalloc()) == 0) {
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	f30080e7          	jalr	-208(ra) # 80000ad2 <kalloc>
    80001baa:	892a                	mv	s2,a0
    80001bac:	e0a8                	sd	a0,64(s1)
    80001bae:	c929                	beqz	a0,80001c00 <allocthread+0xc6>
  t->context.sp = t->kstack + PGSIZE;
    80001bb0:	6785                	lui	a5,0x1
    80001bb2:	00f50933          	add	s2,a0,a5
    80001bb6:	0524bc23          	sd	s2,88(s1)
  return t;
    80001bba:	a815                	j	80001bee <allocthread+0xb4>
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001bbc:	0c048493          	addi	s1,s1,192
    80001bc0:	2905                	addiw	s2,s2,1
    80001bc2:	03390563          	beq	s2,s3,80001bec <allocthread+0xb2>
      if (t != mythread()) {
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	e6a080e7          	jalr	-406(ra) # 80001a30 <mythread>
    80001bce:	fea487e3          	beq	s1,a0,80001bbc <allocthread+0x82>
        acquire(&t->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	fee080e7          	jalr	-18(ra) # 80000bc2 <acquire>
        if (t->state == UNUSED_T) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	dfa5                	beqz	a5,80001b56 <allocthread+0x1c>
        release(&t->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a6080e7          	jalr	166(ra) # 80000c88 <release>
    80001bea:	bfc9                	j	80001bbc <allocthread+0x82>
    return 0;
    80001bec:	4481                	li	s1,0
}
    80001bee:	8526                	mv	a0,s1
    80001bf0:	70a2                	ld	ra,40(sp)
    80001bf2:	7402                	ld	s0,32(sp)
    80001bf4:	64e2                	ld	s1,24(sp)
    80001bf6:	6942                	ld	s2,16(sp)
    80001bf8:	69a2                	ld	s3,8(sp)
    80001bfa:	6a02                	ld	s4,0(sp)
    80001bfc:	6145                	addi	sp,sp,48
    80001bfe:	8082                	ret
      freethread(t);
    80001c00:	8526                	mv	a0,s1
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	c2e080e7          	jalr	-978(ra) # 80001830 <freethread>
      release(&t->lock);
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	07c080e7          	jalr	124(ra) # 80000c88 <release>
      return 0;
    80001c14:	84ca                	mv	s1,s2
    80001c16:	bfe1                	j	80001bee <allocthread+0xb4>

0000000080001c18 <proc_pagetable>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
    80001c24:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	704080e7          	jalr	1796(ra) # 8000132a <uvmcreate>
    80001c2e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c30:	c131                	beqz	a0,80001c74 <proc_pagetable+0x5c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c32:	4729                	li	a4,10
    80001c34:	00005697          	auipc	a3,0x5
    80001c38:	3cc68693          	addi	a3,a3,972 # 80007000 <_trampoline>
    80001c3c:	6605                	lui	a2,0x1
    80001c3e:	040005b7          	lui	a1,0x4000
    80001c42:	15fd                	addi	a1,a1,-1
    80001c44:	05b2                	slli	a1,a1,0xc
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	46c080e7          	jalr	1132(ra) # 800010b2 <mappages>
    80001c4e:	02054a63          	bltz	a0,80001c82 <proc_pagetable+0x6a>
              (uint64)(p->trapframes), PTE_R | PTE_W) < 0){
    80001c52:	6505                	lui	a0,0x1
    80001c54:	954a                	add	a0,a0,s2
  if(mappages(pagetable, TRAPFRAME(0), PGSIZE,
    80001c56:	4719                	li	a4,6
    80001c58:	87853683          	ld	a3,-1928(a0) # 878 <_entry-0x7ffff788>
    80001c5c:	6605                	lui	a2,0x1
    80001c5e:	020005b7          	lui	a1,0x2000
    80001c62:	15fd                	addi	a1,a1,-1
    80001c64:	05b6                	slli	a1,a1,0xd
    80001c66:	8526                	mv	a0,s1
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	44a080e7          	jalr	1098(ra) # 800010b2 <mappages>
    80001c70:	02054163          	bltz	a0,80001c92 <proc_pagetable+0x7a>
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6902                	ld	s2,0(sp)
    80001c7e:	6105                	addi	sp,sp,32
    80001c80:	8082                	ret
    uvmfree(pagetable, 0);
    80001c82:	4581                	li	a1,0
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	8a0080e7          	jalr	-1888(ra) # 80001526 <uvmfree>
    return 0;
    80001c8e:	4481                	li	s1,0
    80001c90:	b7d5                	j	80001c74 <proc_pagetable+0x5c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c92:	4681                	li	a3,0
    80001c94:	4605                	li	a2,1
    80001c96:	040005b7          	lui	a1,0x4000
    80001c9a:	15fd                	addi	a1,a1,-1
    80001c9c:	05b2                	slli	a1,a1,0xc
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	5c6080e7          	jalr	1478(ra) # 80001266 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ca8:	4581                	li	a1,0
    80001caa:	8526                	mv	a0,s1
    80001cac:	00000097          	auipc	ra,0x0
    80001cb0:	87a080e7          	jalr	-1926(ra) # 80001526 <uvmfree>
    return 0;
    80001cb4:	4481                	li	s1,0
    80001cb6:	bf7d                	j	80001c74 <proc_pagetable+0x5c>

0000000080001cb8 <proc_freepagetable>:
{
    80001cb8:	1101                	addi	sp,sp,-32
    80001cba:	ec06                	sd	ra,24(sp)
    80001cbc:	e822                	sd	s0,16(sp)
    80001cbe:	e426                	sd	s1,8(sp)
    80001cc0:	e04a                	sd	s2,0(sp)
    80001cc2:	1000                	addi	s0,sp,32
    80001cc4:	84aa                	mv	s1,a0
    80001cc6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc8:	4681                	li	a3,0
    80001cca:	4605                	li	a2,1
    80001ccc:	040005b7          	lui	a1,0x4000
    80001cd0:	15fd                	addi	a1,a1,-1
    80001cd2:	05b2                	slli	a1,a1,0xc
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	592080e7          	jalr	1426(ra) # 80001266 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME(0), 1, 0);
    80001cdc:	4681                	li	a3,0
    80001cde:	4605                	li	a2,1
    80001ce0:	020005b7          	lui	a1,0x2000
    80001ce4:	15fd                	addi	a1,a1,-1
    80001ce6:	05b6                	slli	a1,a1,0xd
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	57c080e7          	jalr	1404(ra) # 80001266 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cf2:	85ca                	mv	a1,s2
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	830080e7          	jalr	-2000(ra) # 80001526 <uvmfree>
}
    80001cfe:	60e2                	ld	ra,24(sp)
    80001d00:	6442                	ld	s0,16(sp)
    80001d02:	64a2                	ld	s1,8(sp)
    80001d04:	6902                	ld	s2,0(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <freeproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	892a                	mv	s2,a0
  if(p->trapframes)
    80001d18:	6785                	lui	a5,0x1
    80001d1a:	97aa                	add	a5,a5,a0
    80001d1c:	8787b503          	ld	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001d20:	c509                	beqz	a0,80001d2a <freeproc+0x20>
    kfree((void*)p->trapframes);
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	cb4080e7          	jalr	-844(ra) # 800009d6 <kfree>
  p->trapframes = 0;
    80001d2a:	6785                	lui	a5,0x1
    80001d2c:	97ca                	add	a5,a5,s2
    80001d2e:	8607bc23          	sd	zero,-1928(a5) # 878 <_entry-0x7ffff788>
  if(p->trapframe_backup)
    80001d32:	1b893503          	ld	a0,440(s2)
    80001d36:	c509                	beqz	a0,80001d40 <freeproc+0x36>
    kfree((void*)p->trapframe_backup);
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	c9e080e7          	jalr	-866(ra) # 800009d6 <kfree>
  p->trapframe_backup = 0;
    80001d40:	1a093c23          	sd	zero,440(s2)
  if(p->pagetable)
    80001d44:	1d893503          	ld	a0,472(s2)
    80001d48:	c519                	beqz	a0,80001d56 <freeproc+0x4c>
    proc_freepagetable(p->pagetable, p->sz);
    80001d4a:	1d093583          	ld	a1,464(s2)
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	f6a080e7          	jalr	-150(ra) # 80001cb8 <proc_freepagetable>
  p->pagetable = 0;
    80001d56:	1c093c23          	sd	zero,472(s2)
  p->sz = 0;
    80001d5a:	1c093823          	sd	zero,464(s2)
  p->pid = 0;
    80001d5e:	02092223          	sw	zero,36(s2)
  p->parent = 0;
    80001d62:	1c093423          	sd	zero,456(s2)
  p->name[0] = 0;
    80001d66:	26090423          	sb	zero,616(s2)
  p->killed = 0;
    80001d6a:	00092e23          	sw	zero,28(s2)
  p->stopped = 0;
    80001d6e:	1c092023          	sw	zero,448(s2)
  p->xstate = 0;
    80001d72:	02092023          	sw	zero,32(s2)
  p->state = UNUSED;
    80001d76:	00092c23          	sw	zero,24(s2)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001d7a:	27890493          	addi	s1,s2,632
    80001d7e:	6505                	lui	a0,0x1
    80001d80:	87850513          	addi	a0,a0,-1928 # 878 <_entry-0x7ffff788>
    80001d84:	992a                	add	s2,s2,a0
    freethread(t);
    80001d86:	8526                	mv	a0,s1
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	aa8080e7          	jalr	-1368(ra) # 80001830 <freethread>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001d90:	0c048493          	addi	s1,s1,192
    80001d94:	fe9919e3          	bne	s2,s1,80001d86 <freeproc+0x7c>
}
    80001d98:	60e2                	ld	ra,24(sp)
    80001d9a:	6442                	ld	s0,16(sp)
    80001d9c:	64a2                	ld	s1,8(sp)
    80001d9e:	6902                	ld	s2,0(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret

0000000080001da4 <allocproc>:
{
    80001da4:	7179                	addi	sp,sp,-48
    80001da6:	f406                	sd	ra,40(sp)
    80001da8:	f022                	sd	s0,32(sp)
    80001daa:	ec26                	sd	s1,24(sp)
    80001dac:	e84a                	sd	s2,16(sp)
    80001dae:	e44e                	sd	s3,8(sp)
    80001db0:	e052                	sd	s4,0(sp)
    80001db2:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db4:	00010497          	auipc	s1,0x10
    80001db8:	93448493          	addi	s1,s1,-1740 # 800116e8 <proc>
    80001dbc:	6985                	lui	s3,0x1
    80001dbe:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80001dc2:	00032a17          	auipc	s4,0x32
    80001dc6:	926a0a13          	addi	s4,s4,-1754 # 800336e8 <tickslock>
    acquire(&p->lock);
    80001dca:	8526                	mv	a0,s1
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	df6080e7          	jalr	-522(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001dd4:	4c9c                	lw	a5,24(s1)
    80001dd6:	cb99                	beqz	a5,80001dec <allocproc+0x48>
      release(&p->lock);
    80001dd8:	8526                	mv	a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	eae080e7          	jalr	-338(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de2:	94ce                	add	s1,s1,s3
    80001de4:	ff4493e3          	bne	s1,s4,80001dca <allocproc+0x26>
  return 0;
    80001de8:	4481                	li	s1,0
    80001dea:	a89d                	j	80001e60 <allocproc+0xbc>
  p->pid = allocpid();
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	cc2080e7          	jalr	-830(ra) # 80001aae <allocpid>
    80001df4:	d0c8                	sw	a0,36(s1)
  p->state = USED;
    80001df6:	4785                	li	a5,1
    80001df8:	cc9c                	sw	a5,24(s1)
  p->pending_signals = 0;
    80001dfa:	0204a423          	sw	zero,40(s1)
  p->signal_mask = 0;
    80001dfe:	0204a623          	sw	zero,44(s1)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001e02:	03848793          	addi	a5,s1,56
    80001e06:	13848713          	addi	a4,s1,312
    p->signal_handlers[signum] = SIG_DFL;
    80001e0a:	0007b023          	sd	zero,0(a5)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001e0e:	07a1                	addi	a5,a5,8
    80001e10:	fee79de3          	bne	a5,a4,80001e0a <allocproc+0x66>
  if((p->trapframes = (struct trapframe *)kalloc()) == 0){
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	cbe080e7          	jalr	-834(ra) # 80000ad2 <kalloc>
    80001e1c:	892a                	mv	s2,a0
    80001e1e:	6785                	lui	a5,0x1
    80001e20:	97a6                	add	a5,a5,s1
    80001e22:	86a7bc23          	sd	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001e26:	c531                	beqz	a0,80001e72 <allocproc+0xce>
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    80001e28:	fffff097          	auipc	ra,0xfffff
    80001e2c:	caa080e7          	jalr	-854(ra) # 80000ad2 <kalloc>
    80001e30:	892a                	mv	s2,a0
    80001e32:	1aa4bc23          	sd	a0,440(s1)
    80001e36:	c931                	beqz	a0,80001e8a <allocproc+0xe6>
  p->pagetable = proc_pagetable(p);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	dde080e7          	jalr	-546(ra) # 80001c18 <proc_pagetable>
    80001e42:	892a                	mv	s2,a0
    80001e44:	1ca4bc23          	sd	a0,472(s1)
  if(p->pagetable == 0){
    80001e48:	cd29                	beqz	a0,80001ea2 <allocproc+0xfe>
  if ((t = allocthread(p)) == 0) {
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	cee080e7          	jalr	-786(ra) # 80001b3a <allocthread>
    80001e54:	892a                	mv	s2,a0
    80001e56:	c135                	beqz	a0,80001eba <allocproc+0x116>
  release(&t->lock);
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	e30080e7          	jalr	-464(ra) # 80000c88 <release>
}
    80001e60:	8526                	mv	a0,s1
    80001e62:	70a2                	ld	ra,40(sp)
    80001e64:	7402                	ld	s0,32(sp)
    80001e66:	64e2                	ld	s1,24(sp)
    80001e68:	6942                	ld	s2,16(sp)
    80001e6a:	69a2                	ld	s3,8(sp)
    80001e6c:	6a02                	ld	s4,0(sp)
    80001e6e:	6145                	addi	sp,sp,48
    80001e70:	8082                	ret
    freeproc(p);
    80001e72:	8526                	mv	a0,s1
    80001e74:	00000097          	auipc	ra,0x0
    80001e78:	e96080e7          	jalr	-362(ra) # 80001d0a <freeproc>
    release(&p->lock);
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	e0a080e7          	jalr	-502(ra) # 80000c88 <release>
    return 0;
    80001e86:	84ca                	mv	s1,s2
    80001e88:	bfe1                	j	80001e60 <allocproc+0xbc>
    freeproc(p);
    80001e8a:	8526                	mv	a0,s1
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	e7e080e7          	jalr	-386(ra) # 80001d0a <freeproc>
    release(&p->lock);
    80001e94:	8526                	mv	a0,s1
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df2080e7          	jalr	-526(ra) # 80000c88 <release>
    return 0;
    80001e9e:	84ca                	mv	s1,s2
    80001ea0:	b7c1                	j	80001e60 <allocproc+0xbc>
    freeproc(p);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	00000097          	auipc	ra,0x0
    80001ea8:	e66080e7          	jalr	-410(ra) # 80001d0a <freeproc>
    release(&p->lock);
    80001eac:	8526                	mv	a0,s1
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	dda080e7          	jalr	-550(ra) # 80000c88 <release>
    return 0;
    80001eb6:	84ca                	mv	s1,s2
    80001eb8:	b765                	j	80001e60 <allocproc+0xbc>
    release(&t->lock);
    80001eba:	4501                	li	a0,0
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	dcc080e7          	jalr	-564(ra) # 80000c88 <release>
    release(&p->lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	dc2080e7          	jalr	-574(ra) # 80000c88 <release>
    freeproc(p);
    80001ece:	8526                	mv	a0,s1
    80001ed0:	00000097          	auipc	ra,0x0
    80001ed4:	e3a080e7          	jalr	-454(ra) # 80001d0a <freeproc>
    return 0;
    80001ed8:	84ca                	mv	s1,s2
    80001eda:	b759                	j	80001e60 <allocproc+0xbc>

0000000080001edc <userinit>:
{
    80001edc:	1101                	addi	sp,sp,-32
    80001ede:	ec06                	sd	ra,24(sp)
    80001ee0:	e822                	sd	s0,16(sp)
    80001ee2:	e426                	sd	s1,8(sp)
    80001ee4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ee6:	00000097          	auipc	ra,0x0
    80001eea:	ebe080e7          	jalr	-322(ra) # 80001da4 <allocproc>
    80001eee:	84aa                	mv	s1,a0
  initproc = p;
    80001ef0:	00007797          	auipc	a5,0x7
    80001ef4:	12a7bc23          	sd	a0,312(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ef8:	03400613          	li	a2,52
    80001efc:	00007597          	auipc	a1,0x7
    80001f00:	96458593          	addi	a1,a1,-1692 # 80008860 <initcode>
    80001f04:	1d853503          	ld	a0,472(a0)
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	450080e7          	jalr	1104(ra) # 80001358 <uvminit>
  p->sz = PGSIZE;
    80001f10:	6785                	lui	a5,0x1
    80001f12:	1cf4b823          	sd	a5,464(s1)
  p->trapframes->epc = 0;      // user program counter
    80001f16:	00f48733          	add	a4,s1,a5
    80001f1a:	87873683          	ld	a3,-1928(a4)
    80001f1e:	0006bc23          	sd	zero,24(a3)
  p->trapframes->sp = PGSIZE;  // user stack pointer
    80001f22:	87873703          	ld	a4,-1928(a4)
    80001f26:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f28:	4641                	li	a2,16
    80001f2a:	00006597          	auipc	a1,0x6
    80001f2e:	2de58593          	addi	a1,a1,734 # 80008208 <digits+0x1c8>
    80001f32:	26848513          	addi	a0,s1,616
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	efe080e7          	jalr	-258(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001f3e:	00006517          	auipc	a0,0x6
    80001f42:	2da50513          	addi	a0,a0,730 # 80008218 <digits+0x1d8>
    80001f46:	00003097          	auipc	ra,0x3
    80001f4a:	b88080e7          	jalr	-1144(ra) # 80004ace <namei>
    80001f4e:	26a4b023          	sd	a0,608(s1)
  p->threads[0].state = RUNNABLE;
    80001f52:	478d                	li	a5,3
    80001f54:	28f4a823          	sw	a5,656(s1)
  release(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d2e080e7          	jalr	-722(ra) # 80000c88 <release>
}
    80001f62:	60e2                	ld	ra,24(sp)
    80001f64:	6442                	ld	s0,16(sp)
    80001f66:	64a2                	ld	s1,8(sp)
    80001f68:	6105                	addi	sp,sp,32
    80001f6a:	8082                	ret

0000000080001f6c <growproc>:
{
    80001f6c:	1101                	addi	sp,sp,-32
    80001f6e:	ec06                	sd	ra,24(sp)
    80001f70:	e822                	sd	s0,16(sp)
    80001f72:	e426                	sd	s1,8(sp)
    80001f74:	e04a                	sd	s2,0(sp)
    80001f76:	1000                	addi	s0,sp,32
    80001f78:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	a7c080e7          	jalr	-1412(ra) # 800019f6 <myproc>
    80001f82:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	c3e080e7          	jalr	-962(ra) # 80000bc2 <acquire>
  sz = p->sz;
    80001f8c:	1d04b583          	ld	a1,464(s1)
    80001f90:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f94:	03204463          	bgtz	s2,80001fbc <growproc+0x50>
  } else if(n < 0){
    80001f98:	04094863          	bltz	s2,80001fe8 <growproc+0x7c>
  p->sz = sz;
    80001f9c:	1602                	slli	a2,a2,0x20
    80001f9e:	9201                	srli	a2,a2,0x20
    80001fa0:	1cc4b823          	sd	a2,464(s1)
  release(&p->lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	ce2080e7          	jalr	-798(ra) # 80000c88 <release>
  return 0;
    80001fae:	4501                	li	a0,0
}
    80001fb0:	60e2                	ld	ra,24(sp)
    80001fb2:	6442                	ld	s0,16(sp)
    80001fb4:	64a2                	ld	s1,8(sp)
    80001fb6:	6902                	ld	s2,0(sp)
    80001fb8:	6105                	addi	sp,sp,32
    80001fba:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fbc:	00c9063b          	addw	a2,s2,a2
    80001fc0:	1602                	slli	a2,a2,0x20
    80001fc2:	9201                	srli	a2,a2,0x20
    80001fc4:	1582                	slli	a1,a1,0x20
    80001fc6:	9181                	srli	a1,a1,0x20
    80001fc8:	1d84b503          	ld	a0,472(s1)
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	446080e7          	jalr	1094(ra) # 80001412 <uvmalloc>
    80001fd4:	0005061b          	sext.w	a2,a0
    80001fd8:	f271                	bnez	a2,80001f9c <growproc+0x30>
      release(&p->lock);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	cac080e7          	jalr	-852(ra) # 80000c88 <release>
      return -1;
    80001fe4:	557d                	li	a0,-1
    80001fe6:	b7e9                	j	80001fb0 <growproc+0x44>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fe8:	00c9063b          	addw	a2,s2,a2
    80001fec:	1602                	slli	a2,a2,0x20
    80001fee:	9201                	srli	a2,a2,0x20
    80001ff0:	1582                	slli	a1,a1,0x20
    80001ff2:	9181                	srli	a1,a1,0x20
    80001ff4:	1d84b503          	ld	a0,472(s1)
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	3d2080e7          	jalr	978(ra) # 800013ca <uvmdealloc>
    80002000:	0005061b          	sext.w	a2,a0
    80002004:	bf61                	j	80001f9c <growproc+0x30>

0000000080002006 <fork>:
{
    80002006:	7139                	addi	sp,sp,-64
    80002008:	fc06                	sd	ra,56(sp)
    8000200a:	f822                	sd	s0,48(sp)
    8000200c:	f426                	sd	s1,40(sp)
    8000200e:	f04a                	sd	s2,32(sp)
    80002010:	ec4e                	sd	s3,24(sp)
    80002012:	e852                	sd	s4,16(sp)
    80002014:	e456                	sd	s5,8(sp)
    80002016:	0080                	addi	s0,sp,64
  struct thread *t = mythread();
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	a18080e7          	jalr	-1512(ra) # 80001a30 <mythread>
    80002020:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	9d4080e7          	jalr	-1580(ra) # 800019f6 <myproc>
    8000202a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0) {
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	d78080e7          	jalr	-648(ra) # 80001da4 <allocproc>
    80002034:	14050a63          	beqz	a0,80002188 <fork+0x182>
    80002038:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000203a:	1d093603          	ld	a2,464(s2)
    8000203e:	1d853583          	ld	a1,472(a0)
    80002042:	1d893503          	ld	a0,472(s2)
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	518080e7          	jalr	1304(ra) # 8000155e <uvmcopy>
    8000204e:	04054763          	bltz	a0,8000209c <fork+0x96>
  np->sz = p->sz;
    80002052:	1d093783          	ld	a5,464(s2)
    80002056:	1cfa3823          	sd	a5,464(s4)
  *(nt->trapframe) = *(t->trapframe); 
    8000205a:	64b4                	ld	a3,72(s1)
    8000205c:	87b6                	mv	a5,a3
    8000205e:	2c0a3703          	ld	a4,704(s4)
    80002062:	12068693          	addi	a3,a3,288
    80002066:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000206a:	6788                	ld	a0,8(a5)
    8000206c:	6b8c                	ld	a1,16(a5)
    8000206e:	6f90                	ld	a2,24(a5)
    80002070:	01073023          	sd	a6,0(a4)
    80002074:	e708                	sd	a0,8(a4)
    80002076:	eb0c                	sd	a1,16(a4)
    80002078:	ef10                	sd	a2,24(a4)
    8000207a:	02078793          	addi	a5,a5,32
    8000207e:	02070713          	addi	a4,a4,32
    80002082:	fed792e3          	bne	a5,a3,80002066 <fork+0x60>
  nt->trapframe->a0 = 0;
    80002086:	2c0a3783          	ld	a5,704(s4)
    8000208a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000208e:	1e090493          	addi	s1,s2,480
    80002092:	1e0a0993          	addi	s3,s4,480
    80002096:	26090a93          	addi	s5,s2,608
    8000209a:	a00d                	j	800020bc <fork+0xb6>
    freeproc(np);
    8000209c:	8552                	mv	a0,s4
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	c6c080e7          	jalr	-916(ra) # 80001d0a <freeproc>
    release(&np->lock);
    800020a6:	8552                	mv	a0,s4
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	be0080e7          	jalr	-1056(ra) # 80000c88 <release>
    return -1;
    800020b0:	59fd                	li	s3,-1
    800020b2:	a0c9                	j	80002174 <fork+0x16e>
  for(i = 0; i < NOFILE; i++)
    800020b4:	04a1                	addi	s1,s1,8
    800020b6:	09a1                	addi	s3,s3,8
    800020b8:	01548b63          	beq	s1,s5,800020ce <fork+0xc8>
    if(p->ofile[i])
    800020bc:	6088                	ld	a0,0(s1)
    800020be:	d97d                	beqz	a0,800020b4 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    800020c0:	00003097          	auipc	ra,0x3
    800020c4:	0a8080e7          	jalr	168(ra) # 80005168 <filedup>
    800020c8:	00a9b023          	sd	a0,0(s3)
    800020cc:	b7e5                	j	800020b4 <fork+0xae>
  np->cwd = idup(p->cwd);
    800020ce:	26093503          	ld	a0,608(s2)
    800020d2:	00002097          	auipc	ra,0x2
    800020d6:	208080e7          	jalr	520(ra) # 800042da <idup>
    800020da:	26aa3023          	sd	a0,608(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020de:	4641                	li	a2,16
    800020e0:	26890593          	addi	a1,s2,616
    800020e4:	268a0513          	addi	a0,s4,616
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	d4c080e7          	jalr	-692(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    800020f0:	024a2983          	lw	s3,36(s4)
  release(&np->lock);
    800020f4:	8552                	mv	a0,s4
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	b92080e7          	jalr	-1134(ra) # 80000c88 <release>
  acquire(&wait_lock);
    800020fe:	0000f497          	auipc	s1,0xf
    80002102:	1ba48493          	addi	s1,s1,442 # 800112b8 <wait_lock>
    80002106:	8526                	mv	a0,s1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	aba080e7          	jalr	-1350(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002110:	1d2a3423          	sd	s2,456(s4)
  release(&wait_lock);
    80002114:	8526                	mv	a0,s1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b72080e7          	jalr	-1166(ra) # 80000c88 <release>
  acquire(&np->lock);
    8000211e:	8552                	mv	a0,s4
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	aa2080e7          	jalr	-1374(ra) # 80000bc2 <acquire>
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
    80002128:	02c92783          	lw	a5,44(s2)
    8000212c:	02fa2623          	sw	a5,44(s4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80002130:	03890793          	addi	a5,s2,56
    80002134:	038a0713          	addi	a4,s4,56
    80002138:	13890613          	addi	a2,s2,312
    np->signal_handlers[i] = p->signal_handlers[i];    
    8000213c:	6394                	ld	a3,0(a5)
    8000213e:	e314                	sd	a3,0(a4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80002140:	07a1                	addi	a5,a5,8
    80002142:	0721                	addi	a4,a4,8
    80002144:	fec79ce3          	bne	a5,a2,8000213c <fork+0x136>
  np->pending_signals = 0; // ADDED Q2.1.2
    80002148:	020a2423          	sw	zero,40(s4)
  release(&np->lock);
    8000214c:	8552                	mv	a0,s4
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	b3a080e7          	jalr	-1222(ra) # 80000c88 <release>
  acquire(&nt->lock);
    80002156:	278a0493          	addi	s1,s4,632
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	a66080e7          	jalr	-1434(ra) # 80000bc2 <acquire>
  nt->state = RUNNABLE;
    80002164:	478d                	li	a5,3
    80002166:	28fa2823          	sw	a5,656(s4)
  release(&nt->lock);
    8000216a:	8526                	mv	a0,s1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b1c080e7          	jalr	-1252(ra) # 80000c88 <release>
}
    80002174:	854e                	mv	a0,s3
    80002176:	70e2                	ld	ra,56(sp)
    80002178:	7442                	ld	s0,48(sp)
    8000217a:	74a2                	ld	s1,40(sp)
    8000217c:	7902                	ld	s2,32(sp)
    8000217e:	69e2                	ld	s3,24(sp)
    80002180:	6a42                	ld	s4,16(sp)
    80002182:	6aa2                	ld	s5,8(sp)
    80002184:	6121                	addi	sp,sp,64
    80002186:	8082                	ret
    return -1;
    80002188:	59fd                	li	s3,-1
    8000218a:	b7ed                	j	80002174 <fork+0x16e>

000000008000218c <kill_handler>:
{
    8000218c:	1141                	addi	sp,sp,-16
    8000218e:	e406                	sd	ra,8(sp)
    80002190:	e022                	sd	s0,0(sp)
    80002192:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	862080e7          	jalr	-1950(ra) # 800019f6 <myproc>
  p->killed = 1; 
    8000219c:	4785                	li	a5,1
    8000219e:	cd5c                	sw	a5,28(a0)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800021a0:	27850793          	addi	a5,a0,632
    800021a4:	6705                	lui	a4,0x1
    800021a6:	87870713          	addi	a4,a4,-1928 # 878 <_entry-0x7ffff788>
    800021aa:	953a                	add	a0,a0,a4
    if (t->state == SLEEPING) {
    800021ac:	4689                	li	a3,2
      t->state = RUNNABLE;
    800021ae:	460d                	li	a2,3
    800021b0:	a029                	j	800021ba <kill_handler+0x2e>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800021b2:	0c078793          	addi	a5,a5,192
    800021b6:	00f50763          	beq	a0,a5,800021c4 <kill_handler+0x38>
    if (t->state == SLEEPING) {
    800021ba:	4f98                	lw	a4,24(a5)
    800021bc:	fed71be3          	bne	a4,a3,800021b2 <kill_handler+0x26>
      t->state = RUNNABLE;
    800021c0:	cf90                	sw	a2,24(a5)
    800021c2:	bfc5                	j	800021b2 <kill_handler+0x26>
}
    800021c4:	60a2                	ld	ra,8(sp)
    800021c6:	6402                	ld	s0,0(sp)
    800021c8:	0141                	addi	sp,sp,16
    800021ca:	8082                	ret

00000000800021cc <received_continue>:
{
    800021cc:	1101                	addi	sp,sp,-32
    800021ce:	ec06                	sd	ra,24(sp)
    800021d0:	e822                	sd	s0,16(sp)
    800021d2:	e426                	sd	s1,8(sp)
    800021d4:	e04a                	sd	s2,0(sp)
    800021d6:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800021d8:	00000097          	auipc	ra,0x0
    800021dc:	81e080e7          	jalr	-2018(ra) # 800019f6 <myproc>
    800021e0:	892a                	mv	s2,a0
    acquire(&p->lock);
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	9e0080e7          	jalr	-1568(ra) # 80000bc2 <acquire>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    800021ea:	02c92683          	lw	a3,44(s2)
    800021ee:	fff6c693          	not	a3,a3
    800021f2:	02892783          	lw	a5,40(s2)
    800021f6:	8efd                	and	a3,a3,a5
    800021f8:	2681                	sext.w	a3,a3
    for (int signum = 0; signum < SIG_NUM; signum++) {
    800021fa:	03890713          	addi	a4,s2,56
    800021fe:	4781                	li	a5,0
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002200:	454d                	li	a0,19
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80002202:	02000613          	li	a2,32
    80002206:	a801                	j	80002216 <received_continue+0x4a>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002208:	630c                	ld	a1,0(a4)
    8000220a:	00a58f63          	beq	a1,a0,80002228 <received_continue+0x5c>
    for (int signum = 0; signum < SIG_NUM; signum++) {
    8000220e:	2785                	addiw	a5,a5,1
    80002210:	0721                	addi	a4,a4,8
    80002212:	02c78163          	beq	a5,a2,80002234 <received_continue+0x68>
      if( (pending_and_not_blocked & (1 << signum)) &&
    80002216:	40f6d4bb          	sraw	s1,a3,a5
    8000221a:	8885                	andi	s1,s1,1
    8000221c:	d8ed                	beqz	s1,8000220e <received_continue+0x42>
    8000221e:	0d093583          	ld	a1,208(s2)
    80002222:	f1fd                	bnez	a1,80002208 <received_continue+0x3c>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002224:	fea792e3          	bne	a5,a0,80002208 <received_continue+0x3c>
            release(&p->lock);
    80002228:	854a                	mv	a0,s2
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	a5e080e7          	jalr	-1442(ra) # 80000c88 <release>
            return 1;
    80002232:	a039                	j	80002240 <received_continue+0x74>
    release(&p->lock);
    80002234:	854a                	mv	a0,s2
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a52080e7          	jalr	-1454(ra) # 80000c88 <release>
    return 0;
    8000223e:	4481                	li	s1,0
}
    80002240:	8526                	mv	a0,s1
    80002242:	60e2                	ld	ra,24(sp)
    80002244:	6442                	ld	s0,16(sp)
    80002246:	64a2                	ld	s1,8(sp)
    80002248:	6902                	ld	s2,0(sp)
    8000224a:	6105                	addi	sp,sp,32
    8000224c:	8082                	ret

000000008000224e <continue_handler>:
{
    8000224e:	1141                	addi	sp,sp,-16
    80002250:	e406                	sd	ra,8(sp)
    80002252:	e022                	sd	s0,0(sp)
    80002254:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	7a0080e7          	jalr	1952(ra) # 800019f6 <myproc>
  p->stopped = 0;
    8000225e:	1c052023          	sw	zero,448(a0)
}
    80002262:	60a2                	ld	ra,8(sp)
    80002264:	6402                	ld	s0,0(sp)
    80002266:	0141                	addi	sp,sp,16
    80002268:	8082                	ret

000000008000226a <handle_user_signals>:
handle_user_signals(int signum) {
    8000226a:	7179                	addi	sp,sp,-48
    8000226c:	f406                	sd	ra,40(sp)
    8000226e:	f022                	sd	s0,32(sp)
    80002270:	ec26                	sd	s1,24(sp)
    80002272:	e84a                	sd	s2,16(sp)
    80002274:	e44e                	sd	s3,8(sp)
    80002276:	1800                	addi	s0,sp,48
    80002278:	892a                	mv	s2,a0
  struct thread *t = mythread();
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	7b6080e7          	jalr	1974(ra) # 80001a30 <mythread>
    80002282:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	772080e7          	jalr	1906(ra) # 800019f6 <myproc>
    8000228c:	84aa                	mv	s1,a0
  p->signal_mask_backup = p->signal_mask;
    8000228e:	555c                	lw	a5,44(a0)
    80002290:	d91c                	sw	a5,48(a0)
  p->signal_mask = p->signal_handlers_masks[signum];  
    80002292:	04c90793          	addi	a5,s2,76
    80002296:	078a                	slli	a5,a5,0x2
    80002298:	97aa                	add	a5,a5,a0
    8000229a:	479c                	lw	a5,8(a5)
    8000229c:	d55c                	sw	a5,44(a0)
  memmove(p->trapframe_backup, t->trapframe, sizeof(struct trapframe));
    8000229e:	12000613          	li	a2,288
    800022a2:	0489b583          	ld	a1,72(s3)
    800022a6:	1b853503          	ld	a0,440(a0)
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	a94080e7          	jalr	-1388(ra) # 80000d3e <memmove>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    800022b2:	0489b703          	ld	a4,72(s3)
  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
    800022b6:	00005617          	auipc	a2,0x5
    800022ba:	e5c60613          	addi	a2,a2,-420 # 80007112 <start_inject_sigret>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    800022be:	00005697          	auipc	a3,0x5
    800022c2:	e5a68693          	addi	a3,a3,-422 # 80007118 <end_inject_sigret>
    800022c6:	9e91                	subw	a3,a3,a2
    800022c8:	7b1c                	ld	a5,48(a4)
    800022ca:	8f95                	sub	a5,a5,a3
    800022cc:	fb1c                	sd	a5,48(a4)
  copyout(p->pagetable, (uint64) (t->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);
    800022ce:	0489b783          	ld	a5,72(s3)
    800022d2:	7b8c                	ld	a1,48(a5)
    800022d4:	1d84b503          	ld	a0,472(s1)
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	38a080e7          	jalr	906(ra) # 80001662 <copyout>
  t->trapframe->a0 = signum;
    800022e0:	0489b783          	ld	a5,72(s3)
    800022e4:	0727b823          	sd	s2,112(a5)
  t->trapframe->epc = (uint64)p->signal_handlers[signum];
    800022e8:	0489b783          	ld	a5,72(s3)
    800022ec:	0919                	addi	s2,s2,6
    800022ee:	090e                	slli	s2,s2,0x3
    800022f0:	94ca                	add	s1,s1,s2
    800022f2:	6498                	ld	a4,8(s1)
    800022f4:	ef98                	sd	a4,24(a5)
  t->trapframe->ra = t->trapframe->sp;
    800022f6:	0489b783          	ld	a5,72(s3)
    800022fa:	7b98                	ld	a4,48(a5)
    800022fc:	f798                	sd	a4,40(a5)
}
    800022fe:	70a2                	ld	ra,40(sp)
    80002300:	7402                	ld	s0,32(sp)
    80002302:	64e2                	ld	s1,24(sp)
    80002304:	6942                	ld	s2,16(sp)
    80002306:	69a2                	ld	s3,8(sp)
    80002308:	6145                	addi	sp,sp,48
    8000230a:	8082                	ret

000000008000230c <scheduler>:
{
    8000230c:	715d                	addi	sp,sp,-80
    8000230e:	e486                	sd	ra,72(sp)
    80002310:	e0a2                	sd	s0,64(sp)
    80002312:	fc26                	sd	s1,56(sp)
    80002314:	f84a                	sd	s2,48(sp)
    80002316:	f44e                	sd	s3,40(sp)
    80002318:	f052                	sd	s4,32(sp)
    8000231a:	ec56                	sd	s5,24(sp)
    8000231c:	e85a                	sd	s6,16(sp)
    8000231e:	e45e                	sd	s7,8(sp)
    80002320:	e062                	sd	s8,0(sp)
    80002322:	0880                	addi	s0,sp,80
    80002324:	8792                	mv	a5,tp
  int id = r_tp();
    80002326:	2781                	sext.w	a5,a5
  c->thread = 0;
    80002328:	00779a93          	slli	s5,a5,0x7
    8000232c:	0000f717          	auipc	a4,0xf
    80002330:	f7470713          	addi	a4,a4,-140 # 800112a0 <pid_lock>
    80002334:	9756                	add	a4,a4,s5
    80002336:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &t->context);
    8000233a:	0000f717          	auipc	a4,0xf
    8000233e:	f9e70713          	addi	a4,a4,-98 # 800112d8 <cpus+0x8>
    80002342:	9aba                	add	s5,s5,a4
    80002344:	00032c17          	auipc	s8,0x32
    80002348:	c1cc0c13          	addi	s8,s8,-996 # 80033f60 <bcache+0x860>
          t->state = RUNNING;
    8000234c:	4b11                	li	s6,4
          c->thread = t;
    8000234e:	079e                	slli	a5,a5,0x7
    80002350:	0000fa17          	auipc	s4,0xf
    80002354:	f50a0a13          	addi	s4,s4,-176 # 800112a0 <pid_lock>
    80002358:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000235a:	6b85                	lui	s7,0x1
    8000235c:	880b8b93          	addi	s7,s7,-1920 # 880 <_entry-0x7ffff780>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002360:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002364:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002368:	10079073          	csrw	sstatus,a5
    8000236c:	00010917          	auipc	s2,0x10
    80002370:	bf490913          	addi	s2,s2,-1036 # 80011f60 <proc+0x878>
        if(t->state == RUNNABLE) {
    80002374:	498d                	li	s3,3
    80002376:	a099                	j	800023bc <scheduler+0xb0>
        release(&t->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	90e080e7          	jalr	-1778(ra) # 80000c88 <release>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002382:	0c048493          	addi	s1,s1,192
    80002386:	03248863          	beq	s1,s2,800023b6 <scheduler+0xaa>
        acquire(&t->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	836080e7          	jalr	-1994(ra) # 80000bc2 <acquire>
        if(t->state == RUNNABLE) {
    80002394:	4c9c                	lw	a5,24(s1)
    80002396:	ff3791e3          	bne	a5,s3,80002378 <scheduler+0x6c>
          t->state = RUNNING;
    8000239a:	0164ac23          	sw	s6,24(s1)
          c->thread = t;
    8000239e:	029a3823          	sd	s1,48(s4)
          swtch(&c->context, &t->context);
    800023a2:	05048593          	addi	a1,s1,80
    800023a6:	8556                	mv	a0,s5
    800023a8:	00001097          	auipc	ra,0x1
    800023ac:	cfc080e7          	jalr	-772(ra) # 800030a4 <swtch>
          c->thread = 0;
    800023b0:	020a3823          	sd	zero,48(s4)
    800023b4:	b7d1                	j	80002378 <scheduler+0x6c>
    for(p = proc; p < &proc[NPROC]; p++) {
    800023b6:	995e                	add	s2,s2,s7
    800023b8:	fb8904e3          	beq	s2,s8,80002360 <scheduler+0x54>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800023bc:	a0090493          	addi	s1,s2,-1536
    800023c0:	b7e9                	j	8000238a <scheduler+0x7e>

00000000800023c2 <sched>:
{
    800023c2:	7179                	addi	sp,sp,-48
    800023c4:	f406                	sd	ra,40(sp)
    800023c6:	f022                	sd	s0,32(sp)
    800023c8:	ec26                	sd	s1,24(sp)
    800023ca:	e84a                	sd	s2,16(sp)
    800023cc:	e44e                	sd	s3,8(sp)
    800023ce:	1800                	addi	s0,sp,48
  struct thread *t = mythread();
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	660080e7          	jalr	1632(ra) # 80001a30 <mythread>
    800023d8:	84aa                	mv	s1,a0
  if(!holding(&t->lock))
    800023da:	ffffe097          	auipc	ra,0xffffe
    800023de:	76e080e7          	jalr	1902(ra) # 80000b48 <holding>
    800023e2:	c93d                	beqz	a0,80002458 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023e4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1) {
    800023e6:	2781                	sext.w	a5,a5
    800023e8:	079e                	slli	a5,a5,0x7
    800023ea:	0000f717          	auipc	a4,0xf
    800023ee:	eb670713          	addi	a4,a4,-330 # 800112a0 <pid_lock>
    800023f2:	97ba                	add	a5,a5,a4
    800023f4:	0a87a703          	lw	a4,168(a5)
    800023f8:	4785                	li	a5,1
    800023fa:	06f71763          	bne	a4,a5,80002468 <sched+0xa6>
  if(t->state == RUNNING)
    800023fe:	4c98                	lw	a4,24(s1)
    80002400:	4791                	li	a5,4
    80002402:	0af70f63          	beq	a4,a5,800024c0 <sched+0xfe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002406:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000240a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000240c:	e3f1                	bnez	a5,800024d0 <sched+0x10e>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000240e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002410:	0000f917          	auipc	s2,0xf
    80002414:	e9090913          	addi	s2,s2,-368 # 800112a0 <pid_lock>
    80002418:	2781                	sext.w	a5,a5
    8000241a:	079e                	slli	a5,a5,0x7
    8000241c:	97ca                	add	a5,a5,s2
    8000241e:	0ac7a983          	lw	s3,172(a5)
    80002422:	8792                	mv	a5,tp
  swtch(&t->context, &mycpu()->context);
    80002424:	2781                	sext.w	a5,a5
    80002426:	079e                	slli	a5,a5,0x7
    80002428:	0000f597          	auipc	a1,0xf
    8000242c:	eb058593          	addi	a1,a1,-336 # 800112d8 <cpus+0x8>
    80002430:	95be                	add	a1,a1,a5
    80002432:	05048513          	addi	a0,s1,80
    80002436:	00001097          	auipc	ra,0x1
    8000243a:	c6e080e7          	jalr	-914(ra) # 800030a4 <swtch>
    8000243e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002440:	2781                	sext.w	a5,a5
    80002442:	079e                	slli	a5,a5,0x7
    80002444:	97ca                	add	a5,a5,s2
    80002446:	0b37a623          	sw	s3,172(a5)
}
    8000244a:	70a2                	ld	ra,40(sp)
    8000244c:	7402                	ld	s0,32(sp)
    8000244e:	64e2                	ld	s1,24(sp)
    80002450:	6942                	ld	s2,16(sp)
    80002452:	69a2                	ld	s3,8(sp)
    80002454:	6145                	addi	sp,sp,48
    80002456:	8082                	ret
    panic("sched t->lock");
    80002458:	00006517          	auipc	a0,0x6
    8000245c:	dc850513          	addi	a0,a0,-568 # 80008220 <digits+0x1e0>
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	0ca080e7          	jalr	202(ra) # 8000052a <panic>
    80002468:	8792                	mv	a5,tp
    printf("noff: %d\n", mycpu()->noff); // REMOVE
    8000246a:	2781                	sext.w	a5,a5
    8000246c:	079e                	slli	a5,a5,0x7
    8000246e:	0000f717          	auipc	a4,0xf
    80002472:	e3270713          	addi	a4,a4,-462 # 800112a0 <pid_lock>
    80002476:	97ba                	add	a5,a5,a4
    80002478:	0a87a583          	lw	a1,168(a5)
    8000247c:	00006517          	auipc	a0,0x6
    80002480:	db450513          	addi	a0,a0,-588 # 80008230 <digits+0x1f0>
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	0f0080e7          	jalr	240(ra) # 80000574 <printf>
    if (holding(&myproc()->lock))
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	56a080e7          	jalr	1386(ra) # 800019f6 <myproc>
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	6b4080e7          	jalr	1716(ra) # 80000b48 <holding>
    8000249c:	e909                	bnez	a0,800024ae <sched+0xec>
    panic("sched locks\n");
    8000249e:	00006517          	auipc	a0,0x6
    800024a2:	dba50513          	addi	a0,a0,-582 # 80008258 <digits+0x218>
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	084080e7          	jalr	132(ra) # 8000052a <panic>
      printf("holding proc lock\n"); //REMOVE
    800024ae:	00006517          	auipc	a0,0x6
    800024b2:	d9250513          	addi	a0,a0,-622 # 80008240 <digits+0x200>
    800024b6:	ffffe097          	auipc	ra,0xffffe
    800024ba:	0be080e7          	jalr	190(ra) # 80000574 <printf>
    800024be:	b7c5                	j	8000249e <sched+0xdc>
    panic("sched running");
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	da850513          	addi	a0,a0,-600 # 80008268 <digits+0x228>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	062080e7          	jalr	98(ra) # 8000052a <panic>
    panic("sched interruptible");
    800024d0:	00006517          	auipc	a0,0x6
    800024d4:	da850513          	addi	a0,a0,-600 # 80008278 <digits+0x238>
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	052080e7          	jalr	82(ra) # 8000052a <panic>

00000000800024e0 <yield>:
{
    800024e0:	1101                	addi	sp,sp,-32
    800024e2:	ec06                	sd	ra,24(sp)
    800024e4:	e822                	sd	s0,16(sp)
    800024e6:	e426                	sd	s1,8(sp)
    800024e8:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	546080e7          	jalr	1350(ra) # 80001a30 <mythread>
    800024f2:	84aa                	mv	s1,a0
  acquire(&t->lock);
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	6ce080e7          	jalr	1742(ra) # 80000bc2 <acquire>
  t->state = RUNNABLE;
    800024fc:	478d                	li	a5,3
    800024fe:	cc9c                	sw	a5,24(s1)
  sched();
    80002500:	00000097          	auipc	ra,0x0
    80002504:	ec2080e7          	jalr	-318(ra) # 800023c2 <sched>
  release(&t->lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	77e080e7          	jalr	1918(ra) # 80000c88 <release>
}
    80002512:	60e2                	ld	ra,24(sp)
    80002514:	6442                	ld	s0,16(sp)
    80002516:	64a2                	ld	s1,8(sp)
    80002518:	6105                	addi	sp,sp,32
    8000251a:	8082                	ret

000000008000251c <stop_handler>:
{
    8000251c:	1101                	addi	sp,sp,-32
    8000251e:	ec06                	sd	ra,24(sp)
    80002520:	e822                	sd	s0,16(sp)
    80002522:	e426                	sd	s1,8(sp)
    80002524:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	4d0080e7          	jalr	1232(ra) # 800019f6 <myproc>
    8000252e:	84aa                	mv	s1,a0
  p->stopped = 1;
    80002530:	4785                	li	a5,1
    80002532:	1cf52023          	sw	a5,448(a0)
  release(&p->lock);
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	752080e7          	jalr	1874(ra) # 80000c88 <release>
  while (p->stopped && !received_continue())
    8000253e:	1c04a783          	lw	a5,448(s1)
    80002542:	cf89                	beqz	a5,8000255c <stop_handler+0x40>
    80002544:	00000097          	auipc	ra,0x0
    80002548:	c88080e7          	jalr	-888(ra) # 800021cc <received_continue>
    8000254c:	e901                	bnez	a0,8000255c <stop_handler+0x40>
      yield();
    8000254e:	00000097          	auipc	ra,0x0
    80002552:	f92080e7          	jalr	-110(ra) # 800024e0 <yield>
  while (p->stopped && !received_continue())
    80002556:	1c04a783          	lw	a5,448(s1)
    8000255a:	f7ed                	bnez	a5,80002544 <stop_handler+0x28>
  acquire(&p->lock);
    8000255c:	8526                	mv	a0,s1
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	664080e7          	jalr	1636(ra) # 80000bc2 <acquire>
}
    80002566:	60e2                	ld	ra,24(sp)
    80002568:	6442                	ld	s0,16(sp)
    8000256a:	64a2                	ld	s1,8(sp)
    8000256c:	6105                	addi	sp,sp,32
    8000256e:	8082                	ret

0000000080002570 <handle_signals>:
{
    80002570:	711d                	addi	sp,sp,-96
    80002572:	ec86                	sd	ra,88(sp)
    80002574:	e8a2                	sd	s0,80(sp)
    80002576:	e4a6                	sd	s1,72(sp)
    80002578:	e0ca                	sd	s2,64(sp)
    8000257a:	fc4e                	sd	s3,56(sp)
    8000257c:	f852                	sd	s4,48(sp)
    8000257e:	f456                	sd	s5,40(sp)
    80002580:	f05a                	sd	s6,32(sp)
    80002582:	ec5e                	sd	s7,24(sp)
    80002584:	e862                	sd	s8,16(sp)
    80002586:	e466                	sd	s9,8(sp)
    80002588:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	46c080e7          	jalr	1132(ra) # 800019f6 <myproc>
    80002592:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	62e080e7          	jalr	1582(ra) # 80000bc2 <acquire>
  for(int signum = 0; signum < SIG_NUM; signum++){
    8000259c:	03890993          	addi	s3,s2,56
    800025a0:	4481                	li	s1,0
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025a2:	4b05                	li	s6,1
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800025a4:	4ac5                	li	s5,17
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800025a6:	4bcd                	li	s7,19
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    800025a8:	4c25                	li	s8,9
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    800025aa:	4c85                	li	s9,1
  for(int signum = 0; signum < SIG_NUM; signum++){
    800025ac:	02000a13          	li	s4,32
    800025b0:	a0a1                	j	800025f8 <handle_signals+0x88>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800025b2:	03548263          	beq	s1,s5,800025d6 <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800025b6:	09748b63          	beq	s1,s7,8000264c <handle_signals+0xdc>
        kill_handler();
    800025ba:	00000097          	auipc	ra,0x0
    800025be:	bd2080e7          	jalr	-1070(ra) # 8000218c <kill_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025c2:	009b17bb          	sllw	a5,s6,s1
    800025c6:	fff7c793          	not	a5,a5
    800025ca:	02892703          	lw	a4,40(s2)
    800025ce:	8ff9                	and	a5,a5,a4
    800025d0:	02f92423          	sw	a5,40(s2)
    800025d4:	a831                	j	800025f0 <handle_signals+0x80>
        stop_handler();
    800025d6:	00000097          	auipc	ra,0x0
    800025da:	f46080e7          	jalr	-186(ra) # 8000251c <stop_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025de:	009b17bb          	sllw	a5,s6,s1
    800025e2:	fff7c793          	not	a5,a5
    800025e6:	02892703          	lw	a4,40(s2)
    800025ea:	8ff9                	and	a5,a5,a4
    800025ec:	02f92423          	sw	a5,40(s2)
  for(int signum = 0; signum < SIG_NUM; signum++){
    800025f0:	2485                	addiw	s1,s1,1
    800025f2:	09a1                	addi	s3,s3,8
    800025f4:	09448263          	beq	s1,s4,80002678 <handle_signals+0x108>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    800025f8:	02892703          	lw	a4,40(s2)
    800025fc:	02c92783          	lw	a5,44(s2)
    80002600:	fff7c793          	not	a5,a5
    80002604:	8ff9                	and	a5,a5,a4
    if(pending_and_not_blocked & (1 << signum)){
    80002606:	4097d7bb          	sraw	a5,a5,s1
    8000260a:	8b85                	andi	a5,a5,1
    8000260c:	d3f5                	beqz	a5,800025f0 <handle_signals+0x80>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    8000260e:	0009b783          	ld	a5,0(s3)
    80002612:	d3c5                	beqz	a5,800025b2 <handle_signals+0x42>
    80002614:	fd5781e3          	beq	a5,s5,800025d6 <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    80002618:	03778a63          	beq	a5,s7,8000264c <handle_signals+0xdc>
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    8000261c:	f9878fe3          	beq	a5,s8,800025ba <handle_signals+0x4a>
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    80002620:	05978463          	beq	a5,s9,80002668 <handle_signals+0xf8>
      } else if (p->handling_user_level_signal == 0){
    80002624:	1c492783          	lw	a5,452(s2)
    80002628:	f7e1                	bnez	a5,800025f0 <handle_signals+0x80>
        p->handling_user_level_signal = 1;
    8000262a:	1d992223          	sw	s9,452(s2)
        handle_user_signals(signum);
    8000262e:	8526                	mv	a0,s1
    80002630:	00000097          	auipc	ra,0x0
    80002634:	c3a080e7          	jalr	-966(ra) # 8000226a <handle_user_signals>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002638:	009b17bb          	sllw	a5,s6,s1
    8000263c:	fff7c793          	not	a5,a5
    80002640:	02892703          	lw	a4,40(s2)
    80002644:	8ff9                	and	a5,a5,a4
    80002646:	02f92423          	sw	a5,40(s2)
    8000264a:	b75d                	j	800025f0 <handle_signals+0x80>
        continue_handler();
    8000264c:	00000097          	auipc	ra,0x0
    80002650:	c02080e7          	jalr	-1022(ra) # 8000224e <continue_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002654:	009b17bb          	sllw	a5,s6,s1
    80002658:	fff7c793          	not	a5,a5
    8000265c:	02892703          	lw	a4,40(s2)
    80002660:	8ff9                	and	a5,a5,a4
    80002662:	02f92423          	sw	a5,40(s2)
    80002666:	b769                	j	800025f0 <handle_signals+0x80>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002668:	009b17bb          	sllw	a5,s6,s1
    8000266c:	fff7c793          	not	a5,a5
    80002670:	8f7d                	and	a4,a4,a5
    80002672:	02e92423          	sw	a4,40(s2)
    80002676:	bfad                	j	800025f0 <handle_signals+0x80>
  release(&p->lock);
    80002678:	854a                	mv	a0,s2
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	60e080e7          	jalr	1550(ra) # 80000c88 <release>
}
    80002682:	60e6                	ld	ra,88(sp)
    80002684:	6446                	ld	s0,80(sp)
    80002686:	64a6                	ld	s1,72(sp)
    80002688:	6906                	ld	s2,64(sp)
    8000268a:	79e2                	ld	s3,56(sp)
    8000268c:	7a42                	ld	s4,48(sp)
    8000268e:	7aa2                	ld	s5,40(sp)
    80002690:	7b02                	ld	s6,32(sp)
    80002692:	6be2                	ld	s7,24(sp)
    80002694:	6c42                	ld	s8,16(sp)
    80002696:	6ca2                	ld	s9,8(sp)
    80002698:	6125                	addi	sp,sp,96
    8000269a:	8082                	ret

000000008000269c <sleep>:
// ADDED Q3
// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000269c:	7179                	addi	sp,sp,-48
    8000269e:	f406                	sd	ra,40(sp)
    800026a0:	f022                	sd	s0,32(sp)
    800026a2:	ec26                	sd	s1,24(sp)
    800026a4:	e84a                	sd	s2,16(sp)
    800026a6:	e44e                	sd	s3,8(sp)
    800026a8:	1800                	addi	s0,sp,48
    800026aa:	89aa                	mv	s3,a0
    800026ac:	892e                	mv	s2,a1
  struct thread *t = mythread();
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	382080e7          	jalr	898(ra) # 80001a30 <mythread>
    800026b6:	84aa                	mv	s1,a0
  // Once we hold t->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks t->lock),
  // so it's okay to release lk.

  acquire(&t->lock);  //DOC: sleeplock1
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	50a080e7          	jalr	1290(ra) # 80000bc2 <acquire>
  release(lk);
    800026c0:	854a                	mv	a0,s2
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5c6080e7          	jalr	1478(ra) # 80000c88 <release>

  // Go to sleep.
  t->chan = chan;
    800026ca:	0334b023          	sd	s3,32(s1)
  t->state = SLEEPING;
    800026ce:	4789                	li	a5,2
    800026d0:	cc9c                	sw	a5,24(s1)

  sched();
    800026d2:	00000097          	auipc	ra,0x0
    800026d6:	cf0080e7          	jalr	-784(ra) # 800023c2 <sched>

  // Tidy up.
  t->chan = 0;
    800026da:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&t->lock);
    800026de:	8526                	mv	a0,s1
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	5a8080e7          	jalr	1448(ra) # 80000c88 <release>
  acquire(lk);
    800026e8:	854a                	mv	a0,s2
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	4d8080e7          	jalr	1240(ra) # 80000bc2 <acquire>
}
    800026f2:	70a2                	ld	ra,40(sp)
    800026f4:	7402                	ld	s0,32(sp)
    800026f6:	64e2                	ld	s1,24(sp)
    800026f8:	6942                	ld	s2,16(sp)
    800026fa:	69a2                	ld	s3,8(sp)
    800026fc:	6145                	addi	sp,sp,48
    800026fe:	8082                	ret

0000000080002700 <wait>:
{
    80002700:	715d                	addi	sp,sp,-80
    80002702:	e486                	sd	ra,72(sp)
    80002704:	e0a2                	sd	s0,64(sp)
    80002706:	fc26                	sd	s1,56(sp)
    80002708:	f84a                	sd	s2,48(sp)
    8000270a:	f44e                	sd	s3,40(sp)
    8000270c:	f052                	sd	s4,32(sp)
    8000270e:	ec56                	sd	s5,24(sp)
    80002710:	e85a                	sd	s6,16(sp)
    80002712:	e45e                	sd	s7,8(sp)
    80002714:	0880                	addi	s0,sp,80
    80002716:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	2de080e7          	jalr	734(ra) # 800019f6 <myproc>
    80002720:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002722:	0000f517          	auipc	a0,0xf
    80002726:	b9650513          	addi	a0,a0,-1130 # 800112b8 <wait_lock>
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	498080e7          	jalr	1176(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002732:	4a89                	li	s5,2
        havekids = 1;
    80002734:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002736:	6985                	lui	s3,0x1
    80002738:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    8000273c:	00031a17          	auipc	s4,0x31
    80002740:	faca0a13          	addi	s4,s4,-84 # 800336e8 <tickslock>
    havekids = 0;
    80002744:	4701                	li	a4,0
    for(np = proc; np < &proc[NPROC]; np++){
    80002746:	0000f497          	auipc	s1,0xf
    8000274a:	fa248493          	addi	s1,s1,-94 # 800116e8 <proc>
    8000274e:	a0b5                	j	800027ba <wait+0xba>
          pid = np->pid;
    80002750:	0244a983          	lw	s3,36(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002754:	000b8e63          	beqz	s7,80002770 <wait+0x70>
    80002758:	4691                	li	a3,4
    8000275a:	02048613          	addi	a2,s1,32
    8000275e:	85de                	mv	a1,s7
    80002760:	1d893503          	ld	a0,472(s2)
    80002764:	fffff097          	auipc	ra,0xfffff
    80002768:	efe080e7          	jalr	-258(ra) # 80001662 <copyout>
    8000276c:	02054563          	bltz	a0,80002796 <wait+0x96>
          freeproc(np);
    80002770:	8526                	mv	a0,s1
    80002772:	fffff097          	auipc	ra,0xfffff
    80002776:	598080e7          	jalr	1432(ra) # 80001d0a <freeproc>
          release(&np->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	50c080e7          	jalr	1292(ra) # 80000c88 <release>
          release(&wait_lock);
    80002784:	0000f517          	auipc	a0,0xf
    80002788:	b3450513          	addi	a0,a0,-1228 # 800112b8 <wait_lock>
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	4fc080e7          	jalr	1276(ra) # 80000c88 <release>
          return pid;
    80002794:	a09d                	j	800027fa <wait+0xfa>
            release(&np->lock);
    80002796:	8526                	mv	a0,s1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	4f0080e7          	jalr	1264(ra) # 80000c88 <release>
            release(&wait_lock);
    800027a0:	0000f517          	auipc	a0,0xf
    800027a4:	b1850513          	addi	a0,a0,-1256 # 800112b8 <wait_lock>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	4e0080e7          	jalr	1248(ra) # 80000c88 <release>
            return -1;
    800027b0:	59fd                	li	s3,-1
    800027b2:	a0a1                	j	800027fa <wait+0xfa>
    for(np = proc; np < &proc[NPROC]; np++){
    800027b4:	94ce                	add	s1,s1,s3
    800027b6:	03448563          	beq	s1,s4,800027e0 <wait+0xe0>
      if(np->parent == p){
    800027ba:	1c84b783          	ld	a5,456(s1)
    800027be:	ff279be3          	bne	a5,s2,800027b4 <wait+0xb4>
        acquire(&np->lock);
    800027c2:	8526                	mv	a0,s1
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	3fe080e7          	jalr	1022(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800027cc:	4c9c                	lw	a5,24(s1)
    800027ce:	f95781e3          	beq	a5,s5,80002750 <wait+0x50>
        release(&np->lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	4b4080e7          	jalr	1204(ra) # 80000c88 <release>
        havekids = 1;
    800027dc:	875a                	mv	a4,s6
    800027de:	bfd9                	j	800027b4 <wait+0xb4>
    if(!havekids || p->killed){
    800027e0:	c701                	beqz	a4,800027e8 <wait+0xe8>
    800027e2:	01c92783          	lw	a5,28(s2)
    800027e6:	c795                	beqz	a5,80002812 <wait+0x112>
      release(&wait_lock);
    800027e8:	0000f517          	auipc	a0,0xf
    800027ec:	ad050513          	addi	a0,a0,-1328 # 800112b8 <wait_lock>
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	498080e7          	jalr	1176(ra) # 80000c88 <release>
      return -1;
    800027f8:	59fd                	li	s3,-1
}
    800027fa:	854e                	mv	a0,s3
    800027fc:	60a6                	ld	ra,72(sp)
    800027fe:	6406                	ld	s0,64(sp)
    80002800:	74e2                	ld	s1,56(sp)
    80002802:	7942                	ld	s2,48(sp)
    80002804:	79a2                	ld	s3,40(sp)
    80002806:	7a02                	ld	s4,32(sp)
    80002808:	6ae2                	ld	s5,24(sp)
    8000280a:	6b42                	ld	s6,16(sp)
    8000280c:	6ba2                	ld	s7,8(sp)
    8000280e:	6161                	addi	sp,sp,80
    80002810:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002812:	0000f597          	auipc	a1,0xf
    80002816:	aa658593          	addi	a1,a1,-1370 # 800112b8 <wait_lock>
    8000281a:	854a                	mv	a0,s2
    8000281c:	00000097          	auipc	ra,0x0
    80002820:	e80080e7          	jalr	-384(ra) # 8000269c <sleep>
    havekids = 0;
    80002824:	b705                	j	80002744 <wait+0x44>

0000000080002826 <wakeup>:
// Wake up all threads sleeping on chan.
// Must be called without any p->lock.
// ADDED Q3
void
wakeup(void *chan)
{
    80002826:	715d                	addi	sp,sp,-80
    80002828:	e486                	sd	ra,72(sp)
    8000282a:	e0a2                	sd	s0,64(sp)
    8000282c:	fc26                	sd	s1,56(sp)
    8000282e:	f84a                	sd	s2,48(sp)
    80002830:	f44e                	sd	s3,40(sp)
    80002832:	f052                	sd	s4,32(sp)
    80002834:	ec56                	sd	s5,24(sp)
    80002836:	e85a                	sd	s6,16(sp)
    80002838:	e45e                	sd	s7,8(sp)
    8000283a:	0880                	addi	s0,sp,80
    8000283c:	8a2a                	mv	s4,a0
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    8000283e:	0000f917          	auipc	s2,0xf
    80002842:	72290913          	addi	s2,s2,1826 # 80011f60 <proc+0x878>
    80002846:	00031b17          	auipc	s6,0x31
    8000284a:	71ab0b13          	addi	s6,s6,1818 # 80033f60 <bcache+0x860>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
      if(t != mythread()){
        acquire(&t->lock);
        if (t->state == SLEEPING && t->chan == chan) {
    8000284e:	4989                	li	s3,2
          t->state = RUNNABLE;
    80002850:	4b8d                	li	s7,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002852:	6a85                	lui	s5,0x1
    80002854:	880a8a93          	addi	s5,s5,-1920 # 880 <_entry-0x7ffff780>
    80002858:	a089                	j	8000289a <wakeup+0x74>
        }
        release(&t->lock);
    8000285a:	8526                	mv	a0,s1
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	42c080e7          	jalr	1068(ra) # 80000c88 <release>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002864:	0c048493          	addi	s1,s1,192
    80002868:	03248663          	beq	s1,s2,80002894 <wakeup+0x6e>
      if(t != mythread()){
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	1c4080e7          	jalr	452(ra) # 80001a30 <mythread>
    80002874:	fea488e3          	beq	s1,a0,80002864 <wakeup+0x3e>
        acquire(&t->lock);
    80002878:	8526                	mv	a0,s1
    8000287a:	ffffe097          	auipc	ra,0xffffe
    8000287e:	348080e7          	jalr	840(ra) # 80000bc2 <acquire>
        if (t->state == SLEEPING && t->chan == chan) {
    80002882:	4c9c                	lw	a5,24(s1)
    80002884:	fd379be3          	bne	a5,s3,8000285a <wakeup+0x34>
    80002888:	709c                	ld	a5,32(s1)
    8000288a:	fd4798e3          	bne	a5,s4,8000285a <wakeup+0x34>
          t->state = RUNNABLE;
    8000288e:	0174ac23          	sw	s7,24(s1)
    80002892:	b7e1                	j	8000285a <wakeup+0x34>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002894:	9956                	add	s2,s2,s5
    80002896:	01690563          	beq	s2,s6,800028a0 <wakeup+0x7a>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000289a:	a0090493          	addi	s1,s2,-1536
    8000289e:	b7f9                	j	8000286c <wakeup+0x46>
      }
    }
  }
}
    800028a0:	60a6                	ld	ra,72(sp)
    800028a2:	6406                	ld	s0,64(sp)
    800028a4:	74e2                	ld	s1,56(sp)
    800028a6:	7942                	ld	s2,48(sp)
    800028a8:	79a2                	ld	s3,40(sp)
    800028aa:	7a02                	ld	s4,32(sp)
    800028ac:	6ae2                	ld	s5,24(sp)
    800028ae:	6b42                	ld	s6,16(sp)
    800028b0:	6ba2                	ld	s7,8(sp)
    800028b2:	6161                	addi	sp,sp,80
    800028b4:	8082                	ret

00000000800028b6 <reparent>:
{
    800028b6:	7139                	addi	sp,sp,-64
    800028b8:	fc06                	sd	ra,56(sp)
    800028ba:	f822                	sd	s0,48(sp)
    800028bc:	f426                	sd	s1,40(sp)
    800028be:	f04a                	sd	s2,32(sp)
    800028c0:	ec4e                	sd	s3,24(sp)
    800028c2:	e852                	sd	s4,16(sp)
    800028c4:	e456                	sd	s5,8(sp)
    800028c6:	0080                	addi	s0,sp,64
    800028c8:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028ca:	0000f497          	auipc	s1,0xf
    800028ce:	e1e48493          	addi	s1,s1,-482 # 800116e8 <proc>
      pp->parent = initproc;
    800028d2:	00006a97          	auipc	s5,0x6
    800028d6:	756a8a93          	addi	s5,s5,1878 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028da:	6905                	lui	s2,0x1
    800028dc:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    800028e0:	00031a17          	auipc	s4,0x31
    800028e4:	e08a0a13          	addi	s4,s4,-504 # 800336e8 <tickslock>
    800028e8:	a021                	j	800028f0 <reparent+0x3a>
    800028ea:	94ca                	add	s1,s1,s2
    800028ec:	01448f63          	beq	s1,s4,8000290a <reparent+0x54>
    if(pp->parent == p){
    800028f0:	1c84b783          	ld	a5,456(s1)
    800028f4:	ff379be3          	bne	a5,s3,800028ea <reparent+0x34>
      pp->parent = initproc;
    800028f8:	000ab503          	ld	a0,0(s5)
    800028fc:	1ca4b423          	sd	a0,456(s1)
      wakeup(initproc);
    80002900:	00000097          	auipc	ra,0x0
    80002904:	f26080e7          	jalr	-218(ra) # 80002826 <wakeup>
    80002908:	b7cd                	j	800028ea <reparent+0x34>
}
    8000290a:	70e2                	ld	ra,56(sp)
    8000290c:	7442                	ld	s0,48(sp)
    8000290e:	74a2                	ld	s1,40(sp)
    80002910:	7902                	ld	s2,32(sp)
    80002912:	69e2                	ld	s3,24(sp)
    80002914:	6a42                	ld	s4,16(sp)
    80002916:	6aa2                	ld	s5,8(sp)
    80002918:	6121                	addi	sp,sp,64
    8000291a:	8082                	ret

000000008000291c <kill>:
// ADDED Q2.2.1
int
kill(int pid, int signum)
{
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    8000291c:	47fd                	li	a5,31
    8000291e:	06b7ef63          	bltu	a5,a1,8000299c <kill+0x80>
{
    80002922:	7139                	addi	sp,sp,-64
    80002924:	fc06                	sd	ra,56(sp)
    80002926:	f822                	sd	s0,48(sp)
    80002928:	f426                	sd	s1,40(sp)
    8000292a:	f04a                	sd	s2,32(sp)
    8000292c:	ec4e                	sd	s3,24(sp)
    8000292e:	e852                	sd	s4,16(sp)
    80002930:	e456                	sd	s5,8(sp)
    80002932:	0080                	addi	s0,sp,64
    80002934:	892a                	mv	s2,a0
    80002936:	8aae                	mv	s5,a1
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002938:	0000f497          	auipc	s1,0xf
    8000293c:	db048493          	addi	s1,s1,-592 # 800116e8 <proc>
    80002940:	6985                	lui	s3,0x1
    80002942:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80002946:	00031a17          	auipc	s4,0x31
    8000294a:	da2a0a13          	addi	s4,s4,-606 # 800336e8 <tickslock>
    acquire(&p->lock);
    8000294e:	8526                	mv	a0,s1
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	272080e7          	jalr	626(ra) # 80000bc2 <acquire>
    if(p->pid == pid) {
    80002958:	50dc                	lw	a5,36(s1)
    8000295a:	01278c63          	beq	a5,s2,80002972 <kill+0x56>
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	328080e7          	jalr	808(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002968:	94ce                	add	s1,s1,s3
    8000296a:	ff4492e3          	bne	s1,s4,8000294e <kill+0x32>
  }
  // no such pid
  return -1;
    8000296e:	557d                	li	a0,-1
    80002970:	a829                	j	8000298a <kill+0x6e>
      p->pending_signals = p->pending_signals | (1 << signum);
    80002972:	4785                	li	a5,1
    80002974:	0157973b          	sllw	a4,a5,s5
    80002978:	549c                	lw	a5,40(s1)
    8000297a:	8fd9                	or	a5,a5,a4
    8000297c:	d49c                	sw	a5,40(s1)
      release(&p->lock);
    8000297e:	8526                	mv	a0,s1
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	308080e7          	jalr	776(ra) # 80000c88 <release>
      return 0;
    80002988:	4501                	li	a0,0
}
    8000298a:	70e2                	ld	ra,56(sp)
    8000298c:	7442                	ld	s0,48(sp)
    8000298e:	74a2                	ld	s1,40(sp)
    80002990:	7902                	ld	s2,32(sp)
    80002992:	69e2                	ld	s3,24(sp)
    80002994:	6a42                	ld	s4,16(sp)
    80002996:	6aa2                	ld	s5,8(sp)
    80002998:	6121                	addi	sp,sp,64
    8000299a:	8082                	ret
    return -1;
    8000299c:	557d                	li	a0,-1
}
    8000299e:	8082                	ret

00000000800029a0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029a0:	7179                	addi	sp,sp,-48
    800029a2:	f406                	sd	ra,40(sp)
    800029a4:	f022                	sd	s0,32(sp)
    800029a6:	ec26                	sd	s1,24(sp)
    800029a8:	e84a                	sd	s2,16(sp)
    800029aa:	e44e                	sd	s3,8(sp)
    800029ac:	e052                	sd	s4,0(sp)
    800029ae:	1800                	addi	s0,sp,48
    800029b0:	84aa                	mv	s1,a0
    800029b2:	892e                	mv	s2,a1
    800029b4:	89b2                	mv	s3,a2
    800029b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	03e080e7          	jalr	62(ra) # 800019f6 <myproc>
  if(user_dst){
    800029c0:	c095                	beqz	s1,800029e4 <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    800029c2:	86d2                	mv	a3,s4
    800029c4:	864e                	mv	a2,s3
    800029c6:	85ca                	mv	a1,s2
    800029c8:	1d853503          	ld	a0,472(a0)
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	c96080e7          	jalr	-874(ra) # 80001662 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029d4:	70a2                	ld	ra,40(sp)
    800029d6:	7402                	ld	s0,32(sp)
    800029d8:	64e2                	ld	s1,24(sp)
    800029da:	6942                	ld	s2,16(sp)
    800029dc:	69a2                	ld	s3,8(sp)
    800029de:	6a02                	ld	s4,0(sp)
    800029e0:	6145                	addi	sp,sp,48
    800029e2:	8082                	ret
    memmove((char *)dst, src, len);
    800029e4:	000a061b          	sext.w	a2,s4
    800029e8:	85ce                	mv	a1,s3
    800029ea:	854a                	mv	a0,s2
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	352080e7          	jalr	850(ra) # 80000d3e <memmove>
    return 0;
    800029f4:	8526                	mv	a0,s1
    800029f6:	bff9                	j	800029d4 <either_copyout+0x34>

00000000800029f8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029f8:	7179                	addi	sp,sp,-48
    800029fa:	f406                	sd	ra,40(sp)
    800029fc:	f022                	sd	s0,32(sp)
    800029fe:	ec26                	sd	s1,24(sp)
    80002a00:	e84a                	sd	s2,16(sp)
    80002a02:	e44e                	sd	s3,8(sp)
    80002a04:	e052                	sd	s4,0(sp)
    80002a06:	1800                	addi	s0,sp,48
    80002a08:	892a                	mv	s2,a0
    80002a0a:	84ae                	mv	s1,a1
    80002a0c:	89b2                	mv	s3,a2
    80002a0e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	fe6080e7          	jalr	-26(ra) # 800019f6 <myproc>
  if(user_src){
    80002a18:	c095                	beqz	s1,80002a3c <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    80002a1a:	86d2                	mv	a3,s4
    80002a1c:	864e                	mv	a2,s3
    80002a1e:	85ca                	mv	a1,s2
    80002a20:	1d853503          	ld	a0,472(a0)
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	cca080e7          	jalr	-822(ra) # 800016ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a2c:	70a2                	ld	ra,40(sp)
    80002a2e:	7402                	ld	s0,32(sp)
    80002a30:	64e2                	ld	s1,24(sp)
    80002a32:	6942                	ld	s2,16(sp)
    80002a34:	69a2                	ld	s3,8(sp)
    80002a36:	6a02                	ld	s4,0(sp)
    80002a38:	6145                	addi	sp,sp,48
    80002a3a:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a3c:	000a061b          	sext.w	a2,s4
    80002a40:	85ce                	mv	a1,s3
    80002a42:	854a                	mv	a0,s2
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	2fa080e7          	jalr	762(ra) # 80000d3e <memmove>
    return 0;
    80002a4c:	8526                	mv	a0,s1
    80002a4e:	bff9                	j	80002a2c <either_copyin+0x34>

0000000080002a50 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a50:	715d                	addi	sp,sp,-80
    80002a52:	e486                	sd	ra,72(sp)
    80002a54:	e0a2                	sd	s0,64(sp)
    80002a56:	fc26                	sd	s1,56(sp)
    80002a58:	f84a                	sd	s2,48(sp)
    80002a5a:	f44e                	sd	s3,40(sp)
    80002a5c:	f052                	sd	s4,32(sp)
    80002a5e:	ec56                	sd	s5,24(sp)
    80002a60:	e85a                	sd	s6,16(sp)
    80002a62:	e45e                	sd	s7,8(sp)
    80002a64:	e062                	sd	s8,0(sp)
    80002a66:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a68:	00005517          	auipc	a0,0x5
    80002a6c:	7d050513          	addi	a0,a0,2000 # 80008238 <digits+0x1f8>
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	b04080e7          	jalr	-1276(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a78:	0000f497          	auipc	s1,0xf
    80002a7c:	ed848493          	addi	s1,s1,-296 # 80011950 <proc+0x268>
    80002a80:	00031997          	auipc	s3,0x31
    80002a84:	ed098993          	addi	s3,s3,-304 # 80033950 <bcache+0x250>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a88:	4b89                	li	s7,2
      state = states[p->state];
    else
      state = "???";
    80002a8a:	00006a17          	auipc	s4,0x6
    80002a8e:	806a0a13          	addi	s4,s4,-2042 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    80002a92:	00006b17          	auipc	s6,0x6
    80002a96:	806b0b13          	addi	s6,s6,-2042 # 80008298 <digits+0x258>
    printf("\n");
    80002a9a:	00005a97          	auipc	s5,0x5
    80002a9e:	79ea8a93          	addi	s5,s5,1950 # 80008238 <digits+0x1f8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aa2:	00006c17          	auipc	s8,0x6
    80002aa6:	836c0c13          	addi	s8,s8,-1994 # 800082d8 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    80002aaa:	6905                	lui	s2,0x1
    80002aac:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    80002ab0:	a005                	j	80002ad0 <procdump+0x80>
    printf("%d %s %s", p->pid, state, p->name);
    80002ab2:	dbc6a583          	lw	a1,-580(a3)
    80002ab6:	855a                	mv	a0,s6
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	abc080e7          	jalr	-1348(ra) # 80000574 <printf>
    printf("\n");
    80002ac0:	8556                	mv	a0,s5
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	ab2080e7          	jalr	-1358(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002aca:	94ca                	add	s1,s1,s2
    80002acc:	03348263          	beq	s1,s3,80002af0 <procdump+0xa0>
    if(p->state == UNUSED)
    80002ad0:	86a6                	mv	a3,s1
    80002ad2:	db04a783          	lw	a5,-592(s1)
    80002ad6:	dbf5                	beqz	a5,80002aca <procdump+0x7a>
      state = "???";
    80002ad8:	8652                	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ada:	fcfbece3          	bltu	s7,a5,80002ab2 <procdump+0x62>
    80002ade:	02079713          	slli	a4,a5,0x20
    80002ae2:	01d75793          	srli	a5,a4,0x1d
    80002ae6:	97e2                	add	a5,a5,s8
    80002ae8:	6390                	ld	a2,0(a5)
    80002aea:	f661                	bnez	a2,80002ab2 <procdump+0x62>
      state = "???";
    80002aec:	8652                	mv	a2,s4
    80002aee:	b7d1                	j	80002ab2 <procdump+0x62>
  }
}
    80002af0:	60a6                	ld	ra,72(sp)
    80002af2:	6406                	ld	s0,64(sp)
    80002af4:	74e2                	ld	s1,56(sp)
    80002af6:	7942                	ld	s2,48(sp)
    80002af8:	79a2                	ld	s3,40(sp)
    80002afa:	7a02                	ld	s4,32(sp)
    80002afc:	6ae2                	ld	s5,24(sp)
    80002afe:	6b42                	ld	s6,16(sp)
    80002b00:	6ba2                	ld	s7,8(sp)
    80002b02:	6c02                	ld	s8,0(sp)
    80002b04:	6161                	addi	sp,sp,80
    80002b06:	8082                	ret

0000000080002b08 <sigprocmask>:

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
    80002b08:	7179                	addi	sp,sp,-48
    80002b0a:	f406                	sd	ra,40(sp)
    80002b0c:	f022                	sd	s0,32(sp)
    80002b0e:	ec26                	sd	s1,24(sp)
    80002b10:	e84a                	sd	s2,16(sp)
    80002b12:	e44e                	sd	s3,8(sp)
    80002b14:	1800                	addi	s0,sp,48
    80002b16:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002b18:	fffff097          	auipc	ra,0xfffff
    80002b1c:	ede080e7          	jalr	-290(ra) # 800019f6 <myproc>
    80002b20:	84aa                	mv	s1,a0
  uint old_mask = p->signal_mask;
    80002b22:	02c52983          	lw	s3,44(a0)
  acquire(&p->lock);
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	09c080e7          	jalr	156(ra) # 80000bc2 <acquire>

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    80002b2e:	000207b7          	lui	a5,0x20
    80002b32:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    80002b36:	00f977b3          	and	a5,s2,a5
    80002b3a:	e385                	bnez	a5,80002b5a <sigprocmask+0x52>
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
    80002b3c:	0324a623          	sw	s2,44(s1)
  release(&p->lock);
    80002b40:	8526                	mv	a0,s1
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	146080e7          	jalr	326(ra) # 80000c88 <release>
  return old_mask;
}
    80002b4a:	854e                	mv	a0,s3
    80002b4c:	70a2                	ld	ra,40(sp)
    80002b4e:	7402                	ld	s0,32(sp)
    80002b50:	64e2                	ld	s1,24(sp)
    80002b52:	6942                	ld	s2,16(sp)
    80002b54:	69a2                	ld	s3,8(sp)
    80002b56:	6145                	addi	sp,sp,48
    80002b58:	8082                	ret
    release(&p->lock);
    80002b5a:	8526                	mv	a0,s1
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	12c080e7          	jalr	300(ra) # 80000c88 <release>
    return -1;
    80002b64:	59fd                	li	s3,-1
    80002b66:	b7d5                	j	80002b4a <sigprocmask+0x42>

0000000080002b68 <sigaction>:

// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
    80002b68:	715d                	addi	sp,sp,-80
    80002b6a:	e486                	sd	ra,72(sp)
    80002b6c:	e0a2                	sd	s0,64(sp)
    80002b6e:	fc26                	sd	s1,56(sp)
    80002b70:	f84a                	sd	s2,48(sp)
    80002b72:	f44e                	sd	s3,40(sp)
    80002b74:	f052                	sd	s4,32(sp)
    80002b76:	0880                	addi	s0,sp,80
    80002b78:	84aa                	mv	s1,a0
    80002b7a:	89ae                	mv	s3,a1
    80002b7c:	8a32                	mv	s4,a2
  struct proc *p = myproc();
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	e78080e7          	jalr	-392(ra) # 800019f6 <myproc>
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;

  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    80002b86:	0004879b          	sext.w	a5,s1
    80002b8a:	477d                	li	a4,31
    80002b8c:	0cf76763          	bltu	a4,a5,80002c5a <sigaction+0xf2>
    80002b90:	892a                	mv	s2,a0
    80002b92:	37dd                	addiw	a5,a5,-9
    80002b94:	9bdd                	andi	a5,a5,-9
    80002b96:	2781                	sext.w	a5,a5
    80002b98:	c3f9                	beqz	a5,80002c5e <sigaction+0xf6>
    return -1;
  }

  acquire(&p->lock);
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	028080e7          	jalr	40(ra) # 80000bc2 <acquire>

  if(act && copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    80002ba2:	0c098063          	beqz	s3,80002c62 <sigaction+0xfa>
    80002ba6:	46c1                	li	a3,16
    80002ba8:	864e                	mv	a2,s3
    80002baa:	fc040593          	addi	a1,s0,-64
    80002bae:	1d893503          	ld	a0,472(s2)
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	b3c080e7          	jalr	-1220(ra) # 800016ee <copyin>
    80002bba:	08054263          	bltz	a0,80002c3e <sigaction+0xd6>
    release(&p->lock);
    return -1;
  }
  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((kernel_act.sigmask & (1 << SIGKILL)) != 0) || ((kernel_act.sigmask & (1 << SIGSTOP)) != 0)) ) {
    80002bbe:	fc843783          	ld	a5,-56(s0)
    80002bc2:	00020737          	lui	a4,0x20
    80002bc6:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    80002bca:	8ff9                	and	a5,a5,a4
    80002bcc:	e3c1                	bnez	a5,80002c4c <sigaction+0xe4>
    return -1;
  }

  

  if (oldact) {
    80002bce:	020a0c63          	beqz	s4,80002c06 <sigaction+0x9e>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002bd2:	00648793          	addi	a5,s1,6
    80002bd6:	078e                	slli	a5,a5,0x3
    80002bd8:	97ca                	add	a5,a5,s2
    80002bda:	679c                	ld	a5,8(a5)
    80002bdc:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002be0:	04c48793          	addi	a5,s1,76
    80002be4:	078a                	slli	a5,a5,0x2
    80002be6:	97ca                	add	a5,a5,s2
    80002be8:	479c                	lw	a5,8(a5)
    80002bea:	faf42c23          	sw	a5,-72(s0)

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002bee:	46c1                	li	a3,16
    80002bf0:	fb040613          	addi	a2,s0,-80
    80002bf4:	85d2                	mv	a1,s4
    80002bf6:	1d893503          	ld	a0,472(s2)
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	a68080e7          	jalr	-1432(ra) # 80001662 <copyout>
    80002c02:	08054c63          	bltz	a0,80002c9a <sigaction+0x132>
      return -1;
    }
  }

  if (act) {
    p->signal_handlers[signum] = kernel_act.sa_handler;
    80002c06:	00648793          	addi	a5,s1,6
    80002c0a:	078e                	slli	a5,a5,0x3
    80002c0c:	97ca                	add	a5,a5,s2
    80002c0e:	fc043703          	ld	a4,-64(s0)
    80002c12:	e798                	sd	a4,8(a5)
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
    80002c14:	04c48493          	addi	s1,s1,76
    80002c18:	048a                	slli	s1,s1,0x2
    80002c1a:	94ca                	add	s1,s1,s2
    80002c1c:	fc842783          	lw	a5,-56(s0)
    80002c20:	c49c                	sw	a5,8(s1)
  }

  release(&p->lock);
    80002c22:	854a                	mv	a0,s2
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	064080e7          	jalr	100(ra) # 80000c88 <release>
  return 0;
    80002c2c:	4501                	li	a0,0
}
    80002c2e:	60a6                	ld	ra,72(sp)
    80002c30:	6406                	ld	s0,64(sp)
    80002c32:	74e2                	ld	s1,56(sp)
    80002c34:	7942                	ld	s2,48(sp)
    80002c36:	79a2                	ld	s3,40(sp)
    80002c38:	7a02                	ld	s4,32(sp)
    80002c3a:	6161                	addi	sp,sp,80
    80002c3c:	8082                	ret
    release(&p->lock);
    80002c3e:	854a                	mv	a0,s2
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	048080e7          	jalr	72(ra) # 80000c88 <release>
    return -1;
    80002c48:	557d                	li	a0,-1
    80002c4a:	b7d5                	j	80002c2e <sigaction+0xc6>
    release(&p->lock);
    80002c4c:	854a                	mv	a0,s2
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	03a080e7          	jalr	58(ra) # 80000c88 <release>
    return -1;
    80002c56:	557d                	li	a0,-1
    80002c58:	bfd9                	j	80002c2e <sigaction+0xc6>
    return -1;
    80002c5a:	557d                	li	a0,-1
    80002c5c:	bfc9                	j	80002c2e <sigaction+0xc6>
    80002c5e:	557d                	li	a0,-1
    80002c60:	b7f9                	j	80002c2e <sigaction+0xc6>
  if (oldact) {
    80002c62:	fc0a00e3          	beqz	s4,80002c22 <sigaction+0xba>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002c66:	00648793          	addi	a5,s1,6
    80002c6a:	078e                	slli	a5,a5,0x3
    80002c6c:	97ca                	add	a5,a5,s2
    80002c6e:	679c                	ld	a5,8(a5)
    80002c70:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002c74:	04c48493          	addi	s1,s1,76
    80002c78:	048a                	slli	s1,s1,0x2
    80002c7a:	94ca                	add	s1,s1,s2
    80002c7c:	449c                	lw	a5,8(s1)
    80002c7e:	faf42c23          	sw	a5,-72(s0)
    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002c82:	46c1                	li	a3,16
    80002c84:	fb040613          	addi	a2,s0,-80
    80002c88:	85d2                	mv	a1,s4
    80002c8a:	1d893503          	ld	a0,472(s2)
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	9d4080e7          	jalr	-1580(ra) # 80001662 <copyout>
    80002c96:	f80556e3          	bgez	a0,80002c22 <sigaction+0xba>
      release(&p->lock);
    80002c9a:	854a                	mv	a0,s2
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	fec080e7          	jalr	-20(ra) # 80000c88 <release>
      return -1;
    80002ca4:	557d                	li	a0,-1
    80002ca6:	b761                	j	80002c2e <sigaction+0xc6>

0000000080002ca8 <sigret>:

// ADDED Q2.1.5
// ADDED Q3
void
sigret(void)
{
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	e426                	sd	s1,8(sp)
    80002cb0:	e04a                	sd	s2,0(sp)
    80002cb2:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	d7c080e7          	jalr	-644(ra) # 80001a30 <mythread>
    80002cbc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	d38080e7          	jalr	-712(ra) # 800019f6 <myproc>
    80002cc6:	84aa                	mv	s1,a0

  acquire(&p->lock);
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	efa080e7          	jalr	-262(ra) # 80000bc2 <acquire>
  acquire(&t->lock);
    80002cd0:	854a                	mv	a0,s2
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	ef0080e7          	jalr	-272(ra) # 80000bc2 <acquire>
  memmove(t->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    80002cda:	12000613          	li	a2,288
    80002cde:	1b84b583          	ld	a1,440(s1)
    80002ce2:	04893503          	ld	a0,72(s2)
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	058080e7          	jalr	88(ra) # 80000d3e <memmove>
  p->signal_mask = p->signal_mask_backup;
    80002cee:	589c                	lw	a5,48(s1)
    80002cf0:	d4dc                	sw	a5,44(s1)
  p->handling_user_level_signal = 0;
    80002cf2:	1c04a223          	sw	zero,452(s1)
  release(&t->lock);
    80002cf6:	854a                	mv	a0,s2
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	f90080e7          	jalr	-112(ra) # 80000c88 <release>
  release(&p->lock);
    80002d00:	8526                	mv	a0,s1
    80002d02:	ffffe097          	auipc	ra,0xffffe
    80002d06:	f86080e7          	jalr	-122(ra) # 80000c88 <release>
}
    80002d0a:	60e2                	ld	ra,24(sp)
    80002d0c:	6442                	ld	s0,16(sp)
    80002d0e:	64a2                	ld	s1,8(sp)
    80002d10:	6902                	ld	s2,0(sp)
    80002d12:	6105                	addi	sp,sp,32
    80002d14:	8082                	ret

0000000080002d16 <kthread_create>:

int
//kthread_create(void (*start_func)(), void* stack)
kthread_create(uint64 start_func, uint64 stack)
{ 
    80002d16:	7179                	addi	sp,sp,-48
    80002d18:	f406                	sd	ra,40(sp)
    80002d1a:	f022                	sd	s0,32(sp)
    80002d1c:	ec26                	sd	s1,24(sp)
    80002d1e:	e84a                	sd	s2,16(sp)
    80002d20:	e44e                	sd	s3,8(sp)
    80002d22:	e052                	sd	s4,0(sp)
    80002d24:	1800                	addi	s0,sp,48
    80002d26:	89aa                	mv	s3,a0
    80002d28:	892e                	mv	s2,a1
    struct thread* t = mythread();
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	d06080e7          	jalr	-762(ra) # 80001a30 <mythread>
    80002d32:	8a2a                	mv	s4,a0
    struct thread* nt;

    if((nt = allocthread(myproc())) == 0) {
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	cc2080e7          	jalr	-830(ra) # 800019f6 <myproc>
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	dfe080e7          	jalr	-514(ra) # 80001b3a <allocthread>
    80002d44:	c135                	beqz	a0,80002da8 <kthread_create+0x92>
    80002d46:	84aa                	mv	s1,a0
        return -1;
    }
    *nt->trapframe = *t->trapframe;
    80002d48:	048a3683          	ld	a3,72(s4)
    80002d4c:	87b6                	mv	a5,a3
    80002d4e:	6538                	ld	a4,72(a0)
    80002d50:	12068693          	addi	a3,a3,288
    80002d54:	0007b803          	ld	a6,0(a5)
    80002d58:	6788                	ld	a0,8(a5)
    80002d5a:	6b8c                	ld	a1,16(a5)
    80002d5c:	6f90                	ld	a2,24(a5)
    80002d5e:	01073023          	sd	a6,0(a4)
    80002d62:	e708                	sd	a0,8(a4)
    80002d64:	eb0c                	sd	a1,16(a4)
    80002d66:	ef10                	sd	a2,24(a4)
    80002d68:	02078793          	addi	a5,a5,32
    80002d6c:	02070713          	addi	a4,a4,32
    80002d70:	fed792e3          	bne	a5,a3,80002d54 <kthread_create+0x3e>
    nt->trapframe->epc = (uint64)start_func;
    80002d74:	64bc                	ld	a5,72(s1)
    80002d76:	0137bc23          	sd	s3,24(a5)
    nt->trapframe->sp = (uint64)(stack + MAX_STACK_SIZE);
    80002d7a:	64bc                	ld	a5,72(s1)
    80002d7c:	6585                	lui	a1,0x1
    80002d7e:	fa058593          	addi	a1,a1,-96 # fa0 <_entry-0x7ffff060>
    80002d82:	992e                	add	s2,s2,a1
    80002d84:	0327b823          	sd	s2,48(a5)
    nt->state = RUNNABLE;
    80002d88:	478d                	li	a5,3
    80002d8a:	cc9c                	sw	a5,24(s1)

    release(&nt->lock);
    80002d8c:	8526                	mv	a0,s1
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	efa080e7          	jalr	-262(ra) # 80000c88 <release>
    return nt->tid;
    80002d96:	5888                	lw	a0,48(s1)
}
    80002d98:	70a2                	ld	ra,40(sp)
    80002d9a:	7402                	ld	s0,32(sp)
    80002d9c:	64e2                	ld	s1,24(sp)
    80002d9e:	6942                	ld	s2,16(sp)
    80002da0:	69a2                	ld	s3,8(sp)
    80002da2:	6a02                	ld	s4,0(sp)
    80002da4:	6145                	addi	sp,sp,48
    80002da6:	8082                	ret
        return -1;
    80002da8:	557d                	li	a0,-1
    80002daa:	b7fd                	j	80002d98 <kthread_create+0x82>

0000000080002dac <exit_single_thread>:

void
exit_single_thread(int status) {
    80002dac:	7179                	addi	sp,sp,-48
    80002dae:	f406                	sd	ra,40(sp)
    80002db0:	f022                	sd	s0,32(sp)
    80002db2:	ec26                	sd	s1,24(sp)
    80002db4:	e84a                	sd	s2,16(sp)
    80002db6:	e44e                	sd	s3,8(sp)
    80002db8:	1800                	addi	s0,sp,48
    80002dba:	89aa                	mv	s3,a0
  struct thread *t = mythread();
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	c74080e7          	jalr	-908(ra) # 80001a30 <mythread>
    80002dc4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	c30080e7          	jalr	-976(ra) # 800019f6 <myproc>
    80002dce:	892a                	mv	s2,a0

  acquire(&t->lock);
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	df0080e7          	jalr	-528(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80002dda:	0334a623          	sw	s3,44(s1)
  t->state = ZOMBIE_T;
    80002dde:	4795                	li	a5,5
    80002de0:	cc9c                	sw	a5,24(s1)

  release(&p->lock);
    80002de2:	854a                	mv	a0,s2
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	ea4080e7          	jalr	-348(ra) # 80000c88 <release>
  wakeup(t);
    80002dec:	8526                	mv	a0,s1
    80002dee:	00000097          	auipc	ra,0x0
    80002df2:	a38080e7          	jalr	-1480(ra) # 80002826 <wakeup>
  // Jump into the scheduler, never to return.
  sched();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	5cc080e7          	jalr	1484(ra) # 800023c2 <sched>
  panic("zombie exit");
    80002dfe:	00005517          	auipc	a0,0x5
    80002e02:	4aa50513          	addi	a0,a0,1194 # 800082a8 <digits+0x268>
    80002e06:	ffffd097          	auipc	ra,0xffffd
    80002e0a:	724080e7          	jalr	1828(ra) # 8000052a <panic>

0000000080002e0e <kthread_join>:
  exit_single_thread(status);
}

int
kthread_join(int thread_id, int *status)
{
    80002e0e:	7139                	addi	sp,sp,-64
    80002e10:	fc06                	sd	ra,56(sp)
    80002e12:	f822                	sd	s0,48(sp)
    80002e14:	f426                	sd	s1,40(sp)
    80002e16:	f04a                	sd	s2,32(sp)
    80002e18:	ec4e                	sd	s3,24(sp)
    80002e1a:	e852                	sd	s4,16(sp)
    80002e1c:	e456                	sd	s5,8(sp)
    80002e1e:	0080                	addi	s0,sp,64
    80002e20:	892a                	mv	s2,a0
    80002e22:	8aae                	mv	s5,a1
  struct thread *jt  = 0;
  struct proc *p = myproc();  
    80002e24:	fffff097          	auipc	ra,0xfffff
    80002e28:	bd2080e7          	jalr	-1070(ra) # 800019f6 <myproc>
    80002e2c:	8a2a                	mv	s4,a0

  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002e2e:	27850493          	addi	s1,a0,632
    80002e32:	6985                	lui	s3,0x1
    80002e34:	87898993          	addi	s3,s3,-1928 # 878 <_entry-0x7ffff788>
    80002e38:	99aa                	add	s3,s3,a0
    acquire(&temp_t->lock);
    80002e3a:	8526                	mv	a0,s1
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	d86080e7          	jalr	-634(ra) # 80000bc2 <acquire>
    if (thread_id == temp_t->tid) {
    80002e44:	589c                	lw	a5,48(s1)
    80002e46:	03278563          	beq	a5,s2,80002e70 <kthread_join+0x62>
      jt = temp_t;
      goto found;
    }
    release(&temp_t->lock);
    80002e4a:	8526                	mv	a0,s1
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	e3c080e7          	jalr	-452(ra) # 80000c88 <release>
  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002e54:	0c048493          	addi	s1,s1,192
    80002e58:	ff3491e3          	bne	s1,s3,80002e3a <kthread_join+0x2c>
  }  

  //not found
  return -1;
    80002e5c:	557d                	li	a0,-1
    freethread(jt);
  } 

  release(&jt->lock);
  return 0;
}
    80002e5e:	70e2                	ld	ra,56(sp)
    80002e60:	7442                	ld	s0,48(sp)
    80002e62:	74a2                	ld	s1,40(sp)
    80002e64:	7902                	ld	s2,32(sp)
    80002e66:	69e2                	ld	s3,24(sp)
    80002e68:	6a42                	ld	s4,16(sp)
    80002e6a:	6aa2                	ld	s5,8(sp)
    80002e6c:	6121                	addi	sp,sp,64
    80002e6e:	8082                	ret
  while (jt->state != ZOMBIE_T && jt->state != UNUSED_T && jt->tid == thread_id) {
    80002e70:	4c9c                	lw	a5,24(s1)
    80002e72:	4715                	li	a4,5
    80002e74:	4995                	li	s3,5
    80002e76:	00e78f63          	beq	a5,a4,80002e94 <kthread_join+0x86>
    80002e7a:	c3b9                	beqz	a5,80002ec0 <kthread_join+0xb2>
    80002e7c:	589c                	lw	a5,48(s1)
    80002e7e:	05279163          	bne	a5,s2,80002ec0 <kthread_join+0xb2>
    sleep(jt, &jt->lock);
    80002e82:	85a6                	mv	a1,s1
    80002e84:	8526                	mv	a0,s1
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	816080e7          	jalr	-2026(ra) # 8000269c <sleep>
  while (jt->state != ZOMBIE_T && jt->state != UNUSED_T && jt->tid == thread_id) {
    80002e8e:	4c9c                	lw	a5,24(s1)
    80002e90:	ff3795e3          	bne	a5,s3,80002e7a <kthread_join+0x6c>
  if (jt->state == ZOMBIE_T && jt->tid == thread_id) {
    80002e94:	589c                	lw	a5,48(s1)
    80002e96:	03279563          	bne	a5,s2,80002ec0 <kthread_join+0xb2>
    if (status != 0 && copyout(p->pagetable, (uint64)status, (char *)&jt->xstate, sizeof(jt->xstate)) < 0) {
    80002e9a:	000a8e63          	beqz	s5,80002eb6 <kthread_join+0xa8>
    80002e9e:	4691                	li	a3,4
    80002ea0:	02c48613          	addi	a2,s1,44
    80002ea4:	85d6                	mv	a1,s5
    80002ea6:	1d8a3503          	ld	a0,472(s4)
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	7b8080e7          	jalr	1976(ra) # 80001662 <copyout>
    80002eb2:	00054e63          	bltz	a0,80002ece <kthread_join+0xc0>
    freethread(jt);
    80002eb6:	8526                	mv	a0,s1
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	978080e7          	jalr	-1672(ra) # 80001830 <freethread>
  release(&jt->lock);
    80002ec0:	8526                	mv	a0,s1
    80002ec2:	ffffe097          	auipc	ra,0xffffe
    80002ec6:	dc6080e7          	jalr	-570(ra) # 80000c88 <release>
  return 0;
    80002eca:	4501                	li	a0,0
    80002ecc:	bf49                	j	80002e5e <kthread_join+0x50>
      release(&jt->lock);
    80002ece:	8526                	mv	a0,s1
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	db8080e7          	jalr	-584(ra) # 80000c88 <release>
      return -1;
    80002ed8:	557d                	li	a0,-1
    80002eda:	b751                	j	80002e5e <kthread_join+0x50>

0000000080002edc <exit>:
{
    80002edc:	715d                	addi	sp,sp,-80
    80002ede:	e486                	sd	ra,72(sp)
    80002ee0:	e0a2                	sd	s0,64(sp)
    80002ee2:	fc26                	sd	s1,56(sp)
    80002ee4:	f84a                	sd	s2,48(sp)
    80002ee6:	f44e                	sd	s3,40(sp)
    80002ee8:	f052                	sd	s4,32(sp)
    80002eea:	ec56                	sd	s5,24(sp)
    80002eec:	e85a                	sd	s6,16(sp)
    80002eee:	e45e                	sd	s7,8(sp)
    80002ef0:	e062                	sd	s8,0(sp)
    80002ef2:	0880                	addi	s0,sp,80
    80002ef4:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	b00080e7          	jalr	-1280(ra) # 800019f6 <myproc>
    80002efe:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f00:	00006797          	auipc	a5,0x6
    80002f04:	1287b783          	ld	a5,296(a5) # 80009028 <initproc>
    80002f08:	1e050493          	addi	s1,a0,480
    80002f0c:	26050913          	addi	s2,a0,608
    80002f10:	02a79363          	bne	a5,a0,80002f36 <exit+0x5a>
    panic("init exiting");
    80002f14:	00005517          	auipc	a0,0x5
    80002f18:	3a450513          	addi	a0,a0,932 # 800082b8 <digits+0x278>
    80002f1c:	ffffd097          	auipc	ra,0xffffd
    80002f20:	60e080e7          	jalr	1550(ra) # 8000052a <panic>
      fileclose(f);
    80002f24:	00002097          	auipc	ra,0x2
    80002f28:	296080e7          	jalr	662(ra) # 800051ba <fileclose>
      p->ofile[fd] = 0;
    80002f2c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002f30:	04a1                	addi	s1,s1,8
    80002f32:	01248563          	beq	s1,s2,80002f3c <exit+0x60>
    if(p->ofile[fd]){
    80002f36:	6088                	ld	a0,0(s1)
    80002f38:	f575                	bnez	a0,80002f24 <exit+0x48>
    80002f3a:	bfdd                	j	80002f30 <exit+0x54>
  begin_op();
    80002f3c:	00002097          	auipc	ra,0x2
    80002f40:	db2080e7          	jalr	-590(ra) # 80004cee <begin_op>
  iput(p->cwd);
    80002f44:	2609b503          	ld	a0,608(s3)
    80002f48:	00001097          	auipc	ra,0x1
    80002f4c:	58a080e7          	jalr	1418(ra) # 800044d2 <iput>
  end_op();
    80002f50:	00002097          	auipc	ra,0x2
    80002f54:	e1e080e7          	jalr	-482(ra) # 80004d6e <end_op>
  p->cwd = 0;
    80002f58:	2609b023          	sd	zero,608(s3)
  acquire(&wait_lock);
    80002f5c:	0000e517          	auipc	a0,0xe
    80002f60:	35c50513          	addi	a0,a0,860 # 800112b8 <wait_lock>
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	c5e080e7          	jalr	-930(ra) # 80000bc2 <acquire>
  reparent(p);
    80002f6c:	854e                	mv	a0,s3
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	948080e7          	jalr	-1720(ra) # 800028b6 <reparent>
  wakeup(p->parent);
    80002f76:	1c89b503          	ld	a0,456(s3)
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	8ac080e7          	jalr	-1876(ra) # 80002826 <wakeup>
  acquire(&p->lock);
    80002f82:	854e                	mv	a0,s3
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	c3e080e7          	jalr	-962(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002f8c:	0359a023          	sw	s5,32(s3)
  p->state = ZOMBIE;
    80002f90:	4789                	li	a5,2
    80002f92:	00f9ac23          	sw	a5,24(s3)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002f96:	27898493          	addi	s1,s3,632
    80002f9a:	6a05                	lui	s4,0x1
    80002f9c:	878a0a13          	addi	s4,s4,-1928 # 878 <_entry-0x7ffff788>
    80002fa0:	9a4e                	add	s4,s4,s3
      t->terminated = 1;
    80002fa2:	4b85                	li	s7,1
      if (t->state == SLEEPING) {
    80002fa4:	4b09                	li	s6,2
          t->state = RUNNABLE;
    80002fa6:	4c0d                	li	s8,3
    80002fa8:	a005                	j	80002fc8 <exit+0xec>
      release(&t->lock);
    80002faa:	8526                	mv	a0,s1
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	cdc080e7          	jalr	-804(ra) # 80000c88 <release>
      kthread_join(t->tid, 0);
    80002fb4:	4581                	li	a1,0
    80002fb6:	5888                	lw	a0,48(s1)
    80002fb8:	00000097          	auipc	ra,0x0
    80002fbc:	e56080e7          	jalr	-426(ra) # 80002e0e <kthread_join>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002fc0:	0c048493          	addi	s1,s1,192
    80002fc4:	029a0863          	beq	s4,s1,80002ff4 <exit+0x118>
    if (t->tid != mythread()->tid) {
    80002fc8:	0304a903          	lw	s2,48(s1)
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	a64080e7          	jalr	-1436(ra) # 80001a30 <mythread>
    80002fd4:	591c                	lw	a5,48(a0)
    80002fd6:	ff2785e3          	beq	a5,s2,80002fc0 <exit+0xe4>
      acquire(&t->lock);
    80002fda:	8526                	mv	a0,s1
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	be6080e7          	jalr	-1050(ra) # 80000bc2 <acquire>
      t->terminated = 1;
    80002fe4:	0374a423          	sw	s7,40(s1)
      if (t->state == SLEEPING) {
    80002fe8:	4c9c                	lw	a5,24(s1)
    80002fea:	fd6790e3          	bne	a5,s6,80002faa <exit+0xce>
          t->state = RUNNABLE;
    80002fee:	0184ac23          	sw	s8,24(s1)
    80002ff2:	bf65                	j	80002faa <exit+0xce>
  release(&p->lock);
    80002ff4:	854e                	mv	a0,s3
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	c92080e7          	jalr	-878(ra) # 80000c88 <release>
  struct thread *t = mythread();
    80002ffe:	fffff097          	auipc	ra,0xfffff
    80003002:	a32080e7          	jalr	-1486(ra) # 80001a30 <mythread>
    80003006:	84aa                	mv	s1,a0
  acquire(&t->lock);
    80003008:	ffffe097          	auipc	ra,0xffffe
    8000300c:	bba080e7          	jalr	-1094(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80003010:	0354a623          	sw	s5,44(s1)
  t->state = ZOMBIE_T;
    80003014:	4795                	li	a5,5
    80003016:	cc9c                	sw	a5,24(s1)
  release(&wait_lock);
    80003018:	0000e517          	auipc	a0,0xe
    8000301c:	2a050513          	addi	a0,a0,672 # 800112b8 <wait_lock>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	c68080e7          	jalr	-920(ra) # 80000c88 <release>
  sched();
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	39a080e7          	jalr	922(ra) # 800023c2 <sched>
  panic("zombie exit");
    80003030:	00005517          	auipc	a0,0x5
    80003034:	27850513          	addi	a0,a0,632 # 800082a8 <digits+0x268>
    80003038:	ffffd097          	auipc	ra,0xffffd
    8000303c:	4f2080e7          	jalr	1266(ra) # 8000052a <panic>

0000000080003040 <kthread_exit>:
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	e04a                	sd	s2,0(sp)
    8000304a:	1000                	addi	s0,sp,32
    8000304c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000304e:	fffff097          	auipc	ra,0xfffff
    80003052:	9a8080e7          	jalr	-1624(ra) # 800019f6 <myproc>
    80003056:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	b6a080e7          	jalr	-1174(ra) # 80000bc2 <acquire>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80003060:	27848793          	addi	a5,s1,632
    80003064:	6685                	lui	a3,0x1
    80003066:	87868693          	addi	a3,a3,-1928 # 878 <_entry-0x7ffff788>
    8000306a:	96a6                	add	a3,a3,s1
  int used_threads = 0;
    8000306c:	4601                	li	a2,0
    8000306e:	a029                	j	80003078 <kthread_exit+0x38>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80003070:	0c078793          	addi	a5,a5,192
    80003074:	00f68663          	beq	a3,a5,80003080 <kthread_exit+0x40>
    if (t->state != UNUSED_T) {
    80003078:	4f98                	lw	a4,24(a5)
    8000307a:	db7d                	beqz	a4,80003070 <kthread_exit+0x30>
      used_threads++;
    8000307c:	2605                	addiw	a2,a2,1
    8000307e:	bfcd                	j	80003070 <kthread_exit+0x30>
  if (used_threads <= 1) {
    80003080:	4785                	li	a5,1
    80003082:	00c7d763          	bge	a5,a2,80003090 <kthread_exit+0x50>
  exit_single_thread(status);
    80003086:	854a                	mv	a0,s2
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	d24080e7          	jalr	-732(ra) # 80002dac <exit_single_thread>
    release(&p->lock);
    80003090:	8526                	mv	a0,s1
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	bf6080e7          	jalr	-1034(ra) # 80000c88 <release>
    exit(status);
    8000309a:	854a                	mv	a0,s2
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	e40080e7          	jalr	-448(ra) # 80002edc <exit>

00000000800030a4 <swtch>:
    800030a4:	00153023          	sd	ra,0(a0)
    800030a8:	00253423          	sd	sp,8(a0)
    800030ac:	e900                	sd	s0,16(a0)
    800030ae:	ed04                	sd	s1,24(a0)
    800030b0:	03253023          	sd	s2,32(a0)
    800030b4:	03353423          	sd	s3,40(a0)
    800030b8:	03453823          	sd	s4,48(a0)
    800030bc:	03553c23          	sd	s5,56(a0)
    800030c0:	05653023          	sd	s6,64(a0)
    800030c4:	05753423          	sd	s7,72(a0)
    800030c8:	05853823          	sd	s8,80(a0)
    800030cc:	05953c23          	sd	s9,88(a0)
    800030d0:	07a53023          	sd	s10,96(a0)
    800030d4:	07b53423          	sd	s11,104(a0)
    800030d8:	0005b083          	ld	ra,0(a1)
    800030dc:	0085b103          	ld	sp,8(a1)
    800030e0:	6980                	ld	s0,16(a1)
    800030e2:	6d84                	ld	s1,24(a1)
    800030e4:	0205b903          	ld	s2,32(a1)
    800030e8:	0285b983          	ld	s3,40(a1)
    800030ec:	0305ba03          	ld	s4,48(a1)
    800030f0:	0385ba83          	ld	s5,56(a1)
    800030f4:	0405bb03          	ld	s6,64(a1)
    800030f8:	0485bb83          	ld	s7,72(a1)
    800030fc:	0505bc03          	ld	s8,80(a1)
    80003100:	0585bc83          	ld	s9,88(a1)
    80003104:	0605bd03          	ld	s10,96(a1)
    80003108:	0685bd83          	ld	s11,104(a1)
    8000310c:	8082                	ret

000000008000310e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000310e:	1141                	addi	sp,sp,-16
    80003110:	e406                	sd	ra,8(sp)
    80003112:	e022                	sd	s0,0(sp)
    80003114:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003116:	00005597          	auipc	a1,0x5
    8000311a:	1da58593          	addi	a1,a1,474 # 800082f0 <states.0+0x18>
    8000311e:	00030517          	auipc	a0,0x30
    80003122:	5ca50513          	addi	a0,a0,1482 # 800336e8 <tickslock>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	a0c080e7          	jalr	-1524(ra) # 80000b32 <initlock>
}
    8000312e:	60a2                	ld	ra,8(sp)
    80003130:	6402                	ld	s0,0(sp)
    80003132:	0141                	addi	sp,sp,16
    80003134:	8082                	ret

0000000080003136 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003136:	1141                	addi	sp,sp,-16
    80003138:	e422                	sd	s0,8(sp)
    8000313a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000313c:	00003797          	auipc	a5,0x3
    80003140:	74478793          	addi	a5,a5,1860 # 80006880 <kernelvec>
    80003144:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003148:	6422                	ld	s0,8(sp)
    8000314a:	0141                	addi	sp,sp,16
    8000314c:	8082                	ret

000000008000314e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	e426                	sd	s1,8(sp)
    80003156:	e04a                	sd	s2,0(sp)
    80003158:	1000                	addi	s0,sp,32
  struct thread *t = mythread(); // ADDED Q3
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	8d6080e7          	jalr	-1834(ra) # 80001a30 <mythread>
    80003162:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	892080e7          	jalr	-1902(ra) # 800019f6 <myproc>
    8000316c:	892a                	mv	s2,a0

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  handle_signals(); // ADDED Q2.4 
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	402080e7          	jalr	1026(ra) # 80002570 <handle_signals>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003176:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000317a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000317c:	10079073          	csrw	sstatus,a5
  intr_off();
  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003180:	00004617          	auipc	a2,0x4
    80003184:	e8060613          	addi	a2,a2,-384 # 80007000 <_trampoline>
    80003188:	00004697          	auipc	a3,0x4
    8000318c:	e7868693          	addi	a3,a3,-392 # 80007000 <_trampoline>
    80003190:	8e91                	sub	a3,a3,a2
    80003192:	040007b7          	lui	a5,0x4000
    80003196:	17fd                	addi	a5,a5,-1
    80003198:	07b2                	slli	a5,a5,0xc
    8000319a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000319c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  t->trapframe->kernel_satp = r_satp();         // kernel page table
    800031a0:	64b8                	ld	a4,72(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800031a2:	180026f3          	csrr	a3,satp
    800031a6:	e314                	sd	a3,0(a4)
  t->trapframe->kernel_sp = t->kstack + PGSIZE; // thread's kernel stack
    800031a8:	64b8                	ld	a4,72(s1)
    800031aa:	60b4                	ld	a3,64(s1)
    800031ac:	6585                	lui	a1,0x1
    800031ae:	96ae                	add	a3,a3,a1
    800031b0:	e714                	sd	a3,8(a4)
  t->trapframe->kernel_trap = (uint64)usertrap;
    800031b2:	64b8                	ld	a4,72(s1)
    800031b4:	00000697          	auipc	a3,0x0
    800031b8:	14a68693          	addi	a3,a3,330 # 800032fe <usertrap>
    800031bc:	eb14                	sd	a3,16(a4)
  t->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800031be:	64b8                	ld	a4,72(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    800031c0:	8692                	mv	a3,tp
    800031c2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031c4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800031c8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800031cc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031d0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(t->trapframe->epc);
    800031d4:	64b8                	ld	a4,72(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031d6:	6f18                	ld	a4,24(a4)
    800031d8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800031dc:	1d893583          	ld	a1,472(s2)
    800031e0:	81b1                	srli	a1,a1,0xc
  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    800031e2:	58d8                	lw	a4,52(s1)
    800031e4:	00371513          	slli	a0,a4,0x3
    800031e8:	953a                	add	a0,a0,a4
    800031ea:	0516                	slli	a0,a0,0x5
    800031ec:	020006b7          	lui	a3,0x2000
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800031f0:	00004717          	auipc	a4,0x4
    800031f4:	ea070713          	addi	a4,a4,-352 # 80007090 <userret>
    800031f8:	8f11                	sub	a4,a4,a2
    800031fa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    800031fc:	577d                	li	a4,-1
    800031fe:	177e                	slli	a4,a4,0x3f
    80003200:	8dd9                	or	a1,a1,a4
    80003202:	16fd                	addi	a3,a3,-1
    80003204:	06b6                	slli	a3,a3,0xd
    80003206:	9536                	add	a0,a0,a3
    80003208:	9782                	jalr	a5
}
    8000320a:	60e2                	ld	ra,24(sp)
    8000320c:	6442                	ld	s0,16(sp)
    8000320e:	64a2                	ld	s1,8(sp)
    80003210:	6902                	ld	s2,0(sp)
    80003212:	6105                	addi	sp,sp,32
    80003214:	8082                	ret

0000000080003216 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	e426                	sd	s1,8(sp)
    8000321e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003220:	00030497          	auipc	s1,0x30
    80003224:	4c848493          	addi	s1,s1,1224 # 800336e8 <tickslock>
    80003228:	8526                	mv	a0,s1
    8000322a:	ffffe097          	auipc	ra,0xffffe
    8000322e:	998080e7          	jalr	-1640(ra) # 80000bc2 <acquire>
  ticks++;
    80003232:	00006517          	auipc	a0,0x6
    80003236:	dfe50513          	addi	a0,a0,-514 # 80009030 <ticks>
    8000323a:	411c                	lw	a5,0(a0)
    8000323c:	2785                	addiw	a5,a5,1
    8000323e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003240:	fffff097          	auipc	ra,0xfffff
    80003244:	5e6080e7          	jalr	1510(ra) # 80002826 <wakeup>
  release(&tickslock);
    80003248:	8526                	mv	a0,s1
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	a3e080e7          	jalr	-1474(ra) # 80000c88 <release>
}
    80003252:	60e2                	ld	ra,24(sp)
    80003254:	6442                	ld	s0,16(sp)
    80003256:	64a2                	ld	s1,8(sp)
    80003258:	6105                	addi	sp,sp,32
    8000325a:	8082                	ret

000000008000325c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000325c:	1101                	addi	sp,sp,-32
    8000325e:	ec06                	sd	ra,24(sp)
    80003260:	e822                	sd	s0,16(sp)
    80003262:	e426                	sd	s1,8(sp)
    80003264:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003266:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000326a:	00074d63          	bltz	a4,80003284 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000326e:	57fd                	li	a5,-1
    80003270:	17fe                	slli	a5,a5,0x3f
    80003272:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003274:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003276:	06f70363          	beq	a4,a5,800032dc <devintr+0x80>
  }
}
    8000327a:	60e2                	ld	ra,24(sp)
    8000327c:	6442                	ld	s0,16(sp)
    8000327e:	64a2                	ld	s1,8(sp)
    80003280:	6105                	addi	sp,sp,32
    80003282:	8082                	ret
     (scause & 0xff) == 9){
    80003284:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003288:	46a5                	li	a3,9
    8000328a:	fed792e3          	bne	a5,a3,8000326e <devintr+0x12>
    int irq = plic_claim();
    8000328e:	00003097          	auipc	ra,0x3
    80003292:	6fa080e7          	jalr	1786(ra) # 80006988 <plic_claim>
    80003296:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003298:	47a9                	li	a5,10
    8000329a:	02f50763          	beq	a0,a5,800032c8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000329e:	4785                	li	a5,1
    800032a0:	02f50963          	beq	a0,a5,800032d2 <devintr+0x76>
    return 1;
    800032a4:	4505                	li	a0,1
    } else if(irq){
    800032a6:	d8f1                	beqz	s1,8000327a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800032a8:	85a6                	mv	a1,s1
    800032aa:	00005517          	auipc	a0,0x5
    800032ae:	04e50513          	addi	a0,a0,78 # 800082f8 <states.0+0x20>
    800032b2:	ffffd097          	auipc	ra,0xffffd
    800032b6:	2c2080e7          	jalr	706(ra) # 80000574 <printf>
      plic_complete(irq);
    800032ba:	8526                	mv	a0,s1
    800032bc:	00003097          	auipc	ra,0x3
    800032c0:	6f0080e7          	jalr	1776(ra) # 800069ac <plic_complete>
    return 1;
    800032c4:	4505                	li	a0,1
    800032c6:	bf55                	j	8000327a <devintr+0x1e>
      uartintr();
    800032c8:	ffffd097          	auipc	ra,0xffffd
    800032cc:	6be080e7          	jalr	1726(ra) # 80000986 <uartintr>
    800032d0:	b7ed                	j	800032ba <devintr+0x5e>
      virtio_disk_intr();
    800032d2:	00004097          	auipc	ra,0x4
    800032d6:	b6c080e7          	jalr	-1172(ra) # 80006e3e <virtio_disk_intr>
    800032da:	b7c5                	j	800032ba <devintr+0x5e>
    if(cpuid() == 0){
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	6ee080e7          	jalr	1774(ra) # 800019ca <cpuid>
    800032e4:	c901                	beqz	a0,800032f4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800032e6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800032ea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800032ec:	14479073          	csrw	sip,a5
    return 2;
    800032f0:	4509                	li	a0,2
    800032f2:	b761                	j	8000327a <devintr+0x1e>
      clockintr();
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	f22080e7          	jalr	-222(ra) # 80003216 <clockintr>
    800032fc:	b7ed                	j	800032e6 <devintr+0x8a>

00000000800032fe <usertrap>:
{
    800032fe:	7179                	addi	sp,sp,-48
    80003300:	f406                	sd	ra,40(sp)
    80003302:	f022                	sd	s0,32(sp)
    80003304:	ec26                	sd	s1,24(sp)
    80003306:	e84a                	sd	s2,16(sp)
    80003308:	e44e                	sd	s3,8(sp)
    8000330a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000330c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003310:	1007f793          	andi	a5,a5,256
    80003314:	e3c9                	bnez	a5,80003396 <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003316:	00003797          	auipc	a5,0x3
    8000331a:	56a78793          	addi	a5,a5,1386 # 80006880 <kernelvec>
    8000331e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	6d4080e7          	jalr	1748(ra) # 800019f6 <myproc>
    8000332a:	892a                	mv	s2,a0
  struct thread *t = mythread(); // ADDED Q3
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	704080e7          	jalr	1796(ra) # 80001a30 <mythread>
    80003334:	84aa                	mv	s1,a0
  t->trapframe->epc = r_sepc();
    80003336:	653c                	ld	a5,72(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003338:	14102773          	csrr	a4,sepc
    8000333c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000333e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003342:	47a1                	li	a5,8
    80003344:	06f71d63          	bne	a4,a5,800033be <usertrap+0xc0>
    if(p->killed)
    80003348:	01c92783          	lw	a5,28(s2)
    8000334c:	efa9                	bnez	a5,800033a6 <usertrap+0xa8>
    if (t->terminated) {
    8000334e:	549c                	lw	a5,40(s1)
    80003350:	e3ad                	bnez	a5,800033b2 <usertrap+0xb4>
    t->trapframe->epc += 4;
    80003352:	64b8                	ld	a4,72(s1)
    80003354:	6f1c                	ld	a5,24(a4)
    80003356:	0791                	addi	a5,a5,4
    80003358:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000335a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000335e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003362:	10079073          	csrw	sstatus,a5
    syscall();
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	302080e7          	jalr	770(ra) # 80003668 <syscall>
  int which_dev = 0;
    8000336e:	4981                	li	s3,0
  if(p->killed)
    80003370:	01c92783          	lw	a5,28(s2)
    80003374:	e7d1                	bnez	a5,80003400 <usertrap+0x102>
  if (t->terminated) {
    80003376:	549c                	lw	a5,40(s1)
    80003378:	ebd1                	bnez	a5,8000340c <usertrap+0x10e>
  if(which_dev == 2)
    8000337a:	4789                	li	a5,2
    8000337c:	08f98e63          	beq	s3,a5,80003418 <usertrap+0x11a>
  usertrapret();
    80003380:	00000097          	auipc	ra,0x0
    80003384:	dce080e7          	jalr	-562(ra) # 8000314e <usertrapret>
}
    80003388:	70a2                	ld	ra,40(sp)
    8000338a:	7402                	ld	s0,32(sp)
    8000338c:	64e2                	ld	s1,24(sp)
    8000338e:	6942                	ld	s2,16(sp)
    80003390:	69a2                	ld	s3,8(sp)
    80003392:	6145                	addi	sp,sp,48
    80003394:	8082                	ret
    panic("usertrap: not from user mode");
    80003396:	00005517          	auipc	a0,0x5
    8000339a:	f8250513          	addi	a0,a0,-126 # 80008318 <states.0+0x40>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>
      exit(-1);
    800033a6:	557d                	li	a0,-1
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	b34080e7          	jalr	-1228(ra) # 80002edc <exit>
    800033b0:	bf79                	j	8000334e <usertrap+0x50>
      kthread_exit(-1);
    800033b2:	557d                	li	a0,-1
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	c8c080e7          	jalr	-884(ra) # 80003040 <kthread_exit>
    800033bc:	bf59                	j	80003352 <usertrap+0x54>
  } else if((which_dev = devintr()) != 0){
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	e9e080e7          	jalr	-354(ra) # 8000325c <devintr>
    800033c6:	89aa                	mv	s3,a0
    800033c8:	f545                	bnez	a0,80003370 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033ca:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800033ce:	02492603          	lw	a2,36(s2)
    800033d2:	00005517          	auipc	a0,0x5
    800033d6:	f6650513          	addi	a0,a0,-154 # 80008338 <states.0+0x60>
    800033da:	ffffd097          	auipc	ra,0xffffd
    800033de:	19a080e7          	jalr	410(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033e2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800033e6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800033ea:	00005517          	auipc	a0,0x5
    800033ee:	f7e50513          	addi	a0,a0,-130 # 80008368 <states.0+0x90>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	182080e7          	jalr	386(ra) # 80000574 <printf>
    p->killed = 1;
    800033fa:	4785                	li	a5,1
    800033fc:	00f92e23          	sw	a5,28(s2)
    exit(-1);
    80003400:	557d                	li	a0,-1
    80003402:	00000097          	auipc	ra,0x0
    80003406:	ada080e7          	jalr	-1318(ra) # 80002edc <exit>
    8000340a:	b7b5                	j	80003376 <usertrap+0x78>
    kthread_exit(-1);
    8000340c:	557d                	li	a0,-1
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	c32080e7          	jalr	-974(ra) # 80003040 <kthread_exit>
    80003416:	b795                	j	8000337a <usertrap+0x7c>
    yield();
    80003418:	fffff097          	auipc	ra,0xfffff
    8000341c:	0c8080e7          	jalr	200(ra) # 800024e0 <yield>
    80003420:	b785                	j	80003380 <usertrap+0x82>

0000000080003422 <kerneltrap>:
{
    80003422:	7179                	addi	sp,sp,-48
    80003424:	f406                	sd	ra,40(sp)
    80003426:	f022                	sd	s0,32(sp)
    80003428:	ec26                	sd	s1,24(sp)
    8000342a:	e84a                	sd	s2,16(sp)
    8000342c:	e44e                	sd	s3,8(sp)
    8000342e:	e052                	sd	s4,0(sp)
    80003430:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003432:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003436:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000343a:	14202a73          	csrr	s4,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000343e:	10097793          	andi	a5,s2,256
    80003442:	cf95                	beqz	a5,8000347e <kerneltrap+0x5c>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003444:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003448:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000344a:	e3b1                	bnez	a5,8000348e <kerneltrap+0x6c>
  if((which_dev = devintr()) == 0){
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	e10080e7          	jalr	-496(ra) # 8000325c <devintr>
    80003454:	84aa                	mv	s1,a0
    80003456:	c521                	beqz	a0,8000349e <kerneltrap+0x7c>
  struct thread *t = mythread();
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	5d8080e7          	jalr	1496(ra) # 80001a30 <mythread>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    80003460:	4789                	li	a5,2
    80003462:	06f48b63          	beq	s1,a5,800034d8 <kerneltrap+0xb6>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003466:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000346a:	10091073          	csrw	sstatus,s2
}
    8000346e:	70a2                	ld	ra,40(sp)
    80003470:	7402                	ld	s0,32(sp)
    80003472:	64e2                	ld	s1,24(sp)
    80003474:	6942                	ld	s2,16(sp)
    80003476:	69a2                	ld	s3,8(sp)
    80003478:	6a02                	ld	s4,0(sp)
    8000347a:	6145                	addi	sp,sp,48
    8000347c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000347e:	00005517          	auipc	a0,0x5
    80003482:	f0a50513          	addi	a0,a0,-246 # 80008388 <states.0+0xb0>
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	0a4080e7          	jalr	164(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000348e:	00005517          	auipc	a0,0x5
    80003492:	f2250513          	addi	a0,a0,-222 # 800083b0 <states.0+0xd8>
    80003496:	ffffd097          	auipc	ra,0xffffd
    8000349a:	094080e7          	jalr	148(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000349e:	85d2                	mv	a1,s4
    800034a0:	00005517          	auipc	a0,0x5
    800034a4:	f3050513          	addi	a0,a0,-208 # 800083d0 <states.0+0xf8>
    800034a8:	ffffd097          	auipc	ra,0xffffd
    800034ac:	0cc080e7          	jalr	204(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034b0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800034b4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800034b8:	00005517          	auipc	a0,0x5
    800034bc:	f2850513          	addi	a0,a0,-216 # 800083e0 <states.0+0x108>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	0b4080e7          	jalr	180(ra) # 80000574 <printf>
    panic("kerneltrap");
    800034c8:	00005517          	auipc	a0,0x5
    800034cc:	f3050513          	addi	a0,a0,-208 # 800083f8 <states.0+0x120>
    800034d0:	ffffd097          	auipc	ra,0xffffd
    800034d4:	05a080e7          	jalr	90(ra) # 8000052a <panic>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    800034d8:	d559                	beqz	a0,80003466 <kerneltrap+0x44>
    800034da:	4d18                	lw	a4,24(a0)
    800034dc:	4791                	li	a5,4
    800034de:	f8f714e3          	bne	a4,a5,80003466 <kerneltrap+0x44>
    yield();
    800034e2:	fffff097          	auipc	ra,0xfffff
    800034e6:	ffe080e7          	jalr	-2(ra) # 800024e0 <yield>
    800034ea:	bfb5                	j	80003466 <kerneltrap+0x44>

00000000800034ec <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800034ec:	1101                	addi	sp,sp,-32
    800034ee:	ec06                	sd	ra,24(sp)
    800034f0:	e822                	sd	s0,16(sp)
    800034f2:	e426                	sd	s1,8(sp)
    800034f4:	1000                	addi	s0,sp,32
    800034f6:	84aa                	mv	s1,a0
  struct thread *t = mythread();
    800034f8:	ffffe097          	auipc	ra,0xffffe
    800034fc:	538080e7          	jalr	1336(ra) # 80001a30 <mythread>
  switch (n) {
    80003500:	4795                	li	a5,5
    80003502:	0497e163          	bltu	a5,s1,80003544 <argraw+0x58>
    80003506:	048a                	slli	s1,s1,0x2
    80003508:	00005717          	auipc	a4,0x5
    8000350c:	f2870713          	addi	a4,a4,-216 # 80008430 <states.0+0x158>
    80003510:	94ba                	add	s1,s1,a4
    80003512:	409c                	lw	a5,0(s1)
    80003514:	97ba                	add	a5,a5,a4
    80003516:	8782                	jr	a5
  case 0:
    return t->trapframe->a0;
    80003518:	653c                	ld	a5,72(a0)
    8000351a:	7ba8                	ld	a0,112(a5)
  case 5:
    return t->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000351c:	60e2                	ld	ra,24(sp)
    8000351e:	6442                	ld	s0,16(sp)
    80003520:	64a2                	ld	s1,8(sp)
    80003522:	6105                	addi	sp,sp,32
    80003524:	8082                	ret
    return t->trapframe->a1;
    80003526:	653c                	ld	a5,72(a0)
    80003528:	7fa8                	ld	a0,120(a5)
    8000352a:	bfcd                	j	8000351c <argraw+0x30>
    return t->trapframe->a2;
    8000352c:	653c                	ld	a5,72(a0)
    8000352e:	63c8                	ld	a0,128(a5)
    80003530:	b7f5                	j	8000351c <argraw+0x30>
    return t->trapframe->a3;
    80003532:	653c                	ld	a5,72(a0)
    80003534:	67c8                	ld	a0,136(a5)
    80003536:	b7dd                	j	8000351c <argraw+0x30>
    return t->trapframe->a4;
    80003538:	653c                	ld	a5,72(a0)
    8000353a:	6bc8                	ld	a0,144(a5)
    8000353c:	b7c5                	j	8000351c <argraw+0x30>
    return t->trapframe->a5;
    8000353e:	653c                	ld	a5,72(a0)
    80003540:	6fc8                	ld	a0,152(a5)
    80003542:	bfe9                	j	8000351c <argraw+0x30>
  panic("argraw");
    80003544:	00005517          	auipc	a0,0x5
    80003548:	ec450513          	addi	a0,a0,-316 # 80008408 <states.0+0x130>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	fde080e7          	jalr	-34(ra) # 8000052a <panic>

0000000080003554 <fetchaddr>:
{
    80003554:	1101                	addi	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	e04a                	sd	s2,0(sp)
    8000355e:	1000                	addi	s0,sp,32
    80003560:	84aa                	mv	s1,a0
    80003562:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003564:	ffffe097          	auipc	ra,0xffffe
    80003568:	492080e7          	jalr	1170(ra) # 800019f6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000356c:	1d053783          	ld	a5,464(a0)
    80003570:	02f4f963          	bgeu	s1,a5,800035a2 <fetchaddr+0x4e>
    80003574:	00848713          	addi	a4,s1,8
    80003578:	02e7e763          	bltu	a5,a4,800035a6 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000357c:	46a1                	li	a3,8
    8000357e:	8626                	mv	a2,s1
    80003580:	85ca                	mv	a1,s2
    80003582:	1d853503          	ld	a0,472(a0)
    80003586:	ffffe097          	auipc	ra,0xffffe
    8000358a:	168080e7          	jalr	360(ra) # 800016ee <copyin>
    8000358e:	00a03533          	snez	a0,a0
    80003592:	40a00533          	neg	a0,a0
}
    80003596:	60e2                	ld	ra,24(sp)
    80003598:	6442                	ld	s0,16(sp)
    8000359a:	64a2                	ld	s1,8(sp)
    8000359c:	6902                	ld	s2,0(sp)
    8000359e:	6105                	addi	sp,sp,32
    800035a0:	8082                	ret
    return -1;
    800035a2:	557d                	li	a0,-1
    800035a4:	bfcd                	j	80003596 <fetchaddr+0x42>
    800035a6:	557d                	li	a0,-1
    800035a8:	b7fd                	j	80003596 <fetchaddr+0x42>

00000000800035aa <fetchstr>:
{
    800035aa:	7179                	addi	sp,sp,-48
    800035ac:	f406                	sd	ra,40(sp)
    800035ae:	f022                	sd	s0,32(sp)
    800035b0:	ec26                	sd	s1,24(sp)
    800035b2:	e84a                	sd	s2,16(sp)
    800035b4:	e44e                	sd	s3,8(sp)
    800035b6:	1800                	addi	s0,sp,48
    800035b8:	892a                	mv	s2,a0
    800035ba:	84ae                	mv	s1,a1
    800035bc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800035be:	ffffe097          	auipc	ra,0xffffe
    800035c2:	438080e7          	jalr	1080(ra) # 800019f6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800035c6:	86ce                	mv	a3,s3
    800035c8:	864a                	mv	a2,s2
    800035ca:	85a6                	mv	a1,s1
    800035cc:	1d853503          	ld	a0,472(a0)
    800035d0:	ffffe097          	auipc	ra,0xffffe
    800035d4:	1ac080e7          	jalr	428(ra) # 8000177c <copyinstr>
  if(err < 0)
    800035d8:	00054763          	bltz	a0,800035e6 <fetchstr+0x3c>
  return strlen(buf);
    800035dc:	8526                	mv	a0,s1
    800035de:	ffffe097          	auipc	ra,0xffffe
    800035e2:	888080e7          	jalr	-1912(ra) # 80000e66 <strlen>
}
    800035e6:	70a2                	ld	ra,40(sp)
    800035e8:	7402                	ld	s0,32(sp)
    800035ea:	64e2                	ld	s1,24(sp)
    800035ec:	6942                	ld	s2,16(sp)
    800035ee:	69a2                	ld	s3,8(sp)
    800035f0:	6145                	addi	sp,sp,48
    800035f2:	8082                	ret

00000000800035f4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800035f4:	1101                	addi	sp,sp,-32
    800035f6:	ec06                	sd	ra,24(sp)
    800035f8:	e822                	sd	s0,16(sp)
    800035fa:	e426                	sd	s1,8(sp)
    800035fc:	1000                	addi	s0,sp,32
    800035fe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003600:	00000097          	auipc	ra,0x0
    80003604:	eec080e7          	jalr	-276(ra) # 800034ec <argraw>
    80003608:	c088                	sw	a0,0(s1)
  return 0;
}
    8000360a:	4501                	li	a0,0
    8000360c:	60e2                	ld	ra,24(sp)
    8000360e:	6442                	ld	s0,16(sp)
    80003610:	64a2                	ld	s1,8(sp)
    80003612:	6105                	addi	sp,sp,32
    80003614:	8082                	ret

0000000080003616 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003616:	1101                	addi	sp,sp,-32
    80003618:	ec06                	sd	ra,24(sp)
    8000361a:	e822                	sd	s0,16(sp)
    8000361c:	e426                	sd	s1,8(sp)
    8000361e:	1000                	addi	s0,sp,32
    80003620:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003622:	00000097          	auipc	ra,0x0
    80003626:	eca080e7          	jalr	-310(ra) # 800034ec <argraw>
    8000362a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000362c:	4501                	li	a0,0
    8000362e:	60e2                	ld	ra,24(sp)
    80003630:	6442                	ld	s0,16(sp)
    80003632:	64a2                	ld	s1,8(sp)
    80003634:	6105                	addi	sp,sp,32
    80003636:	8082                	ret

0000000080003638 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003638:	1101                	addi	sp,sp,-32
    8000363a:	ec06                	sd	ra,24(sp)
    8000363c:	e822                	sd	s0,16(sp)
    8000363e:	e426                	sd	s1,8(sp)
    80003640:	e04a                	sd	s2,0(sp)
    80003642:	1000                	addi	s0,sp,32
    80003644:	84ae                	mv	s1,a1
    80003646:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003648:	00000097          	auipc	ra,0x0
    8000364c:	ea4080e7          	jalr	-348(ra) # 800034ec <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003650:	864a                	mv	a2,s2
    80003652:	85a6                	mv	a1,s1
    80003654:	00000097          	auipc	ra,0x0
    80003658:	f56080e7          	jalr	-170(ra) # 800035aa <fetchstr>
}
    8000365c:	60e2                	ld	ra,24(sp)
    8000365e:	6442                	ld	s0,16(sp)
    80003660:	64a2                	ld	s1,8(sp)
    80003662:	6902                	ld	s2,0(sp)
    80003664:	6105                	addi	sp,sp,32
    80003666:	8082                	ret

0000000080003668 <syscall>:
[SYS_kthread_join]   sys_kthread_join,
};

void
syscall(void)
{
    80003668:	1101                	addi	sp,sp,-32
    8000366a:	ec06                	sd	ra,24(sp)
    8000366c:	e822                	sd	s0,16(sp)
    8000366e:	e426                	sd	s1,8(sp)
    80003670:	e04a                	sd	s2,0(sp)
    80003672:	1000                	addi	s0,sp,32
  int num;
  struct thread *t = mythread();
    80003674:	ffffe097          	auipc	ra,0xffffe
    80003678:	3bc080e7          	jalr	956(ra) # 80001a30 <mythread>
    8000367c:	84aa                	mv	s1,a0

  num = t->trapframe->a7;
    8000367e:	04853903          	ld	s2,72(a0)
    80003682:	0a893783          	ld	a5,168(s2)
    80003686:	0007861b          	sext.w	a2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000368a:	37fd                	addiw	a5,a5,-1
    8000368c:	476d                	li	a4,27
    8000368e:	00f76f63          	bltu	a4,a5,800036ac <syscall+0x44>
    80003692:	00361713          	slli	a4,a2,0x3
    80003696:	00005797          	auipc	a5,0x5
    8000369a:	db278793          	addi	a5,a5,-590 # 80008448 <syscalls>
    8000369e:	97ba                	add	a5,a5,a4
    800036a0:	639c                	ld	a5,0(a5)
    800036a2:	c789                	beqz	a5,800036ac <syscall+0x44>
    t->trapframe->a0 = syscalls[num]();
    800036a4:	9782                	jalr	a5
    800036a6:	06a93823          	sd	a0,112(s2)
    800036aa:	a829                	j	800036c4 <syscall+0x5c>
  } else {
    printf("thread %d: unknown sys call %d\n",
    800036ac:	588c                	lw	a1,48(s1)
    800036ae:	00005517          	auipc	a0,0x5
    800036b2:	d6250513          	addi	a0,a0,-670 # 80008410 <states.0+0x138>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	ebe080e7          	jalr	-322(ra) # 80000574 <printf>
            t->tid, num);
    t->trapframe->a0 = -1;
    800036be:	64bc                	ld	a5,72(s1)
    800036c0:	577d                	li	a4,-1
    800036c2:	fbb8                	sd	a4,112(a5)
  }
}
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	6442                	ld	s0,16(sp)
    800036c8:	64a2                	ld	s1,8(sp)
    800036ca:	6902                	ld	s2,0(sp)
    800036cc:	6105                	addi	sp,sp,32
    800036ce:	8082                	ret

00000000800036d0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800036d0:	1101                	addi	sp,sp,-32
    800036d2:	ec06                	sd	ra,24(sp)
    800036d4:	e822                	sd	s0,16(sp)
    800036d6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800036d8:	fec40593          	addi	a1,s0,-20
    800036dc:	4501                	li	a0,0
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	f16080e7          	jalr	-234(ra) # 800035f4 <argint>
    return -1;
    800036e6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800036e8:	00054963          	bltz	a0,800036fa <sys_exit+0x2a>
  exit(n);
    800036ec:	fec42503          	lw	a0,-20(s0)
    800036f0:	fffff097          	auipc	ra,0xfffff
    800036f4:	7ec080e7          	jalr	2028(ra) # 80002edc <exit>
  return 0;  // not reached
    800036f8:	4781                	li	a5,0
}
    800036fa:	853e                	mv	a0,a5
    800036fc:	60e2                	ld	ra,24(sp)
    800036fe:	6442                	ld	s0,16(sp)
    80003700:	6105                	addi	sp,sp,32
    80003702:	8082                	ret

0000000080003704 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003704:	1141                	addi	sp,sp,-16
    80003706:	e406                	sd	ra,8(sp)
    80003708:	e022                	sd	s0,0(sp)
    8000370a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000370c:	ffffe097          	auipc	ra,0xffffe
    80003710:	2ea080e7          	jalr	746(ra) # 800019f6 <myproc>
}
    80003714:	5148                	lw	a0,36(a0)
    80003716:	60a2                	ld	ra,8(sp)
    80003718:	6402                	ld	s0,0(sp)
    8000371a:	0141                	addi	sp,sp,16
    8000371c:	8082                	ret

000000008000371e <sys_fork>:

uint64
sys_fork(void)
{
    8000371e:	1141                	addi	sp,sp,-16
    80003720:	e406                	sd	ra,8(sp)
    80003722:	e022                	sd	s0,0(sp)
    80003724:	0800                	addi	s0,sp,16
  return fork();
    80003726:	fffff097          	auipc	ra,0xfffff
    8000372a:	8e0080e7          	jalr	-1824(ra) # 80002006 <fork>
}
    8000372e:	60a2                	ld	ra,8(sp)
    80003730:	6402                	ld	s0,0(sp)
    80003732:	0141                	addi	sp,sp,16
    80003734:	8082                	ret

0000000080003736 <sys_wait>:

uint64
sys_wait(void)
{
    80003736:	1101                	addi	sp,sp,-32
    80003738:	ec06                	sd	ra,24(sp)
    8000373a:	e822                	sd	s0,16(sp)
    8000373c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000373e:	fe840593          	addi	a1,s0,-24
    80003742:	4501                	li	a0,0
    80003744:	00000097          	auipc	ra,0x0
    80003748:	ed2080e7          	jalr	-302(ra) # 80003616 <argaddr>
    8000374c:	87aa                	mv	a5,a0
    return -1;
    8000374e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003750:	0007c863          	bltz	a5,80003760 <sys_wait+0x2a>
  return wait(p);
    80003754:	fe843503          	ld	a0,-24(s0)
    80003758:	fffff097          	auipc	ra,0xfffff
    8000375c:	fa8080e7          	jalr	-88(ra) # 80002700 <wait>
}
    80003760:	60e2                	ld	ra,24(sp)
    80003762:	6442                	ld	s0,16(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret

0000000080003768 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003768:	7179                	addi	sp,sp,-48
    8000376a:	f406                	sd	ra,40(sp)
    8000376c:	f022                	sd	s0,32(sp)
    8000376e:	ec26                	sd	s1,24(sp)
    80003770:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003772:	fdc40593          	addi	a1,s0,-36
    80003776:	4501                	li	a0,0
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	e7c080e7          	jalr	-388(ra) # 800035f4 <argint>
    return -1;
    80003780:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003782:	02054063          	bltz	a0,800037a2 <sys_sbrk+0x3a>
  addr = myproc()->sz;
    80003786:	ffffe097          	auipc	ra,0xffffe
    8000378a:	270080e7          	jalr	624(ra) # 800019f6 <myproc>
    8000378e:	1d052483          	lw	s1,464(a0)
  if(growproc(n) < 0)
    80003792:	fdc42503          	lw	a0,-36(s0)
    80003796:	ffffe097          	auipc	ra,0xffffe
    8000379a:	7d6080e7          	jalr	2006(ra) # 80001f6c <growproc>
    8000379e:	00054863          	bltz	a0,800037ae <sys_sbrk+0x46>
    return -1;
  return addr;
}
    800037a2:	8526                	mv	a0,s1
    800037a4:	70a2                	ld	ra,40(sp)
    800037a6:	7402                	ld	s0,32(sp)
    800037a8:	64e2                	ld	s1,24(sp)
    800037aa:	6145                	addi	sp,sp,48
    800037ac:	8082                	ret
    return -1;
    800037ae:	54fd                	li	s1,-1
    800037b0:	bfcd                	j	800037a2 <sys_sbrk+0x3a>

00000000800037b2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800037b2:	7139                	addi	sp,sp,-64
    800037b4:	fc06                	sd	ra,56(sp)
    800037b6:	f822                	sd	s0,48(sp)
    800037b8:	f426                	sd	s1,40(sp)
    800037ba:	f04a                	sd	s2,32(sp)
    800037bc:	ec4e                	sd	s3,24(sp)
    800037be:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800037c0:	fcc40593          	addi	a1,s0,-52
    800037c4:	4501                	li	a0,0
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	e2e080e7          	jalr	-466(ra) # 800035f4 <argint>
    return -1;
    800037ce:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800037d0:	06054563          	bltz	a0,8000383a <sys_sleep+0x88>
  acquire(&tickslock);
    800037d4:	00030517          	auipc	a0,0x30
    800037d8:	f1450513          	addi	a0,a0,-236 # 800336e8 <tickslock>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	3e6080e7          	jalr	998(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    800037e4:	00006917          	auipc	s2,0x6
    800037e8:	84c92903          	lw	s2,-1972(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800037ec:	fcc42783          	lw	a5,-52(s0)
    800037f0:	cf85                	beqz	a5,80003828 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800037f2:	00030997          	auipc	s3,0x30
    800037f6:	ef698993          	addi	s3,s3,-266 # 800336e8 <tickslock>
    800037fa:	00006497          	auipc	s1,0x6
    800037fe:	83648493          	addi	s1,s1,-1994 # 80009030 <ticks>
    if(myproc()->killed){
    80003802:	ffffe097          	auipc	ra,0xffffe
    80003806:	1f4080e7          	jalr	500(ra) # 800019f6 <myproc>
    8000380a:	4d5c                	lw	a5,28(a0)
    8000380c:	ef9d                	bnez	a5,8000384a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000380e:	85ce                	mv	a1,s3
    80003810:	8526                	mv	a0,s1
    80003812:	fffff097          	auipc	ra,0xfffff
    80003816:	e8a080e7          	jalr	-374(ra) # 8000269c <sleep>
  while(ticks - ticks0 < n){
    8000381a:	409c                	lw	a5,0(s1)
    8000381c:	412787bb          	subw	a5,a5,s2
    80003820:	fcc42703          	lw	a4,-52(s0)
    80003824:	fce7efe3          	bltu	a5,a4,80003802 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003828:	00030517          	auipc	a0,0x30
    8000382c:	ec050513          	addi	a0,a0,-320 # 800336e8 <tickslock>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	458080e7          	jalr	1112(ra) # 80000c88 <release>
  return 0;
    80003838:	4781                	li	a5,0
}
    8000383a:	853e                	mv	a0,a5
    8000383c:	70e2                	ld	ra,56(sp)
    8000383e:	7442                	ld	s0,48(sp)
    80003840:	74a2                	ld	s1,40(sp)
    80003842:	7902                	ld	s2,32(sp)
    80003844:	69e2                	ld	s3,24(sp)
    80003846:	6121                	addi	sp,sp,64
    80003848:	8082                	ret
      release(&tickslock);
    8000384a:	00030517          	auipc	a0,0x30
    8000384e:	e9e50513          	addi	a0,a0,-354 # 800336e8 <tickslock>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	436080e7          	jalr	1078(ra) # 80000c88 <release>
      return -1;
    8000385a:	57fd                	li	a5,-1
    8000385c:	bff9                	j	8000383a <sys_sleep+0x88>

000000008000385e <sys_kill>:

// ADDED Q2.2.1
uint64
sys_kill(void)
{
    8000385e:	1101                	addi	sp,sp,-32
    80003860:	ec06                	sd	ra,24(sp)
    80003862:	e822                	sd	s0,16(sp)
    80003864:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    80003866:	fec40593          	addi	a1,s0,-20
    8000386a:	4501                	li	a0,0
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	d88080e7          	jalr	-632(ra) # 800035f4 <argint>
    return -1;
    80003874:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80003876:	02054563          	bltz	a0,800038a0 <sys_kill+0x42>

  if(argint(1, &signum) < 0)
    8000387a:	fe840593          	addi	a1,s0,-24
    8000387e:	4505                	li	a0,1
    80003880:	00000097          	auipc	ra,0x0
    80003884:	d74080e7          	jalr	-652(ra) # 800035f4 <argint>
    return -1;
    80003888:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    8000388a:	00054b63          	bltz	a0,800038a0 <sys_kill+0x42>

  return kill(pid, signum);
    8000388e:	fe842583          	lw	a1,-24(s0)
    80003892:	fec42503          	lw	a0,-20(s0)
    80003896:	fffff097          	auipc	ra,0xfffff
    8000389a:	086080e7          	jalr	134(ra) # 8000291c <kill>
    8000389e:	87aa                	mv	a5,a0
}
    800038a0:	853e                	mv	a0,a5
    800038a2:	60e2                	ld	ra,24(sp)
    800038a4:	6442                	ld	s0,16(sp)
    800038a6:	6105                	addi	sp,sp,32
    800038a8:	8082                	ret

00000000800038aa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800038aa:	1101                	addi	sp,sp,-32
    800038ac:	ec06                	sd	ra,24(sp)
    800038ae:	e822                	sd	s0,16(sp)
    800038b0:	e426                	sd	s1,8(sp)
    800038b2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800038b4:	00030517          	auipc	a0,0x30
    800038b8:	e3450513          	addi	a0,a0,-460 # 800336e8 <tickslock>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	306080e7          	jalr	774(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800038c4:	00005497          	auipc	s1,0x5
    800038c8:	76c4a483          	lw	s1,1900(s1) # 80009030 <ticks>
  release(&tickslock);
    800038cc:	00030517          	auipc	a0,0x30
    800038d0:	e1c50513          	addi	a0,a0,-484 # 800336e8 <tickslock>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	3b4080e7          	jalr	948(ra) # 80000c88 <release>
  return xticks;
}
    800038dc:	02049513          	slli	a0,s1,0x20
    800038e0:	9101                	srli	a0,a0,0x20
    800038e2:	60e2                	ld	ra,24(sp)
    800038e4:	6442                	ld	s0,16(sp)
    800038e6:	64a2                	ld	s1,8(sp)
    800038e8:	6105                	addi	sp,sp,32
    800038ea:	8082                	ret

00000000800038ec <sys_sigprocmask>:

// ADDED Q2.1.3
uint64
sys_sigprocmask(void)
{
    800038ec:	1101                	addi	sp,sp,-32
    800038ee:	ec06                	sd	ra,24(sp)
    800038f0:	e822                	sd	s0,16(sp)
    800038f2:	1000                	addi	s0,sp,32
  uint sigmask;

  if(argint(0, (int *)&sigmask) < 0) 
    800038f4:	fec40593          	addi	a1,s0,-20
    800038f8:	4501                	li	a0,0
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	cfa080e7          	jalr	-774(ra) # 800035f4 <argint>
    80003902:	87aa                	mv	a5,a0
    return -1;
    80003904:	557d                	li	a0,-1
  if(argint(0, (int *)&sigmask) < 0) 
    80003906:	0007ca63          	bltz	a5,8000391a <sys_sigprocmask+0x2e>

  return sigprocmask(sigmask);
    8000390a:	fec42503          	lw	a0,-20(s0)
    8000390e:	fffff097          	auipc	ra,0xfffff
    80003912:	1fa080e7          	jalr	506(ra) # 80002b08 <sigprocmask>
    80003916:	1502                	slli	a0,a0,0x20
    80003918:	9101                	srli	a0,a0,0x20
}
    8000391a:	60e2                	ld	ra,24(sp)
    8000391c:	6442                	ld	s0,16(sp)
    8000391e:	6105                	addi	sp,sp,32
    80003920:	8082                	ret

0000000080003922 <sys_sigaction>:

// ADDED Q2.1.4
uint64
sys_sigaction(void)
{
    80003922:	7179                	addi	sp,sp,-48
    80003924:	f406                	sd	ra,40(sp)
    80003926:	f022                	sd	s0,32(sp)
    80003928:	1800                	addi	s0,sp,48
  int signum;
  struct sigaction *act;
  struct sigaction *oldact;

  if(argint(0, &signum) < 0)
    8000392a:	fec40593          	addi	a1,s0,-20
    8000392e:	4501                	li	a0,0
    80003930:	00000097          	auipc	ra,0x0
    80003934:	cc4080e7          	jalr	-828(ra) # 800035f4 <argint>
    return -1;
    80003938:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    8000393a:	04054163          	bltz	a0,8000397c <sys_sigaction+0x5a>

  if(argaddr(1, (uint64 *)&act) < 0)
    8000393e:	fe040593          	addi	a1,s0,-32
    80003942:	4505                	li	a0,1
    80003944:	00000097          	auipc	ra,0x0
    80003948:	cd2080e7          	jalr	-814(ra) # 80003616 <argaddr>
    return -1;
    8000394c:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&act) < 0)
    8000394e:	02054763          	bltz	a0,8000397c <sys_sigaction+0x5a>

  if(argaddr(2, (uint64 *)&oldact) < 0)
    80003952:	fd840593          	addi	a1,s0,-40
    80003956:	4509                	li	a0,2
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	cbe080e7          	jalr	-834(ra) # 80003616 <argaddr>
    return -1;
    80003960:	57fd                	li	a5,-1
  if(argaddr(2, (uint64 *)&oldact) < 0)
    80003962:	00054d63          	bltz	a0,8000397c <sys_sigaction+0x5a>

  return sigaction(signum, act, oldact);
    80003966:	fd843603          	ld	a2,-40(s0)
    8000396a:	fe043583          	ld	a1,-32(s0)
    8000396e:	fec42503          	lw	a0,-20(s0)
    80003972:	fffff097          	auipc	ra,0xfffff
    80003976:	1f6080e7          	jalr	502(ra) # 80002b68 <sigaction>
    8000397a:	87aa                	mv	a5,a0
}
    8000397c:	853e                	mv	a0,a5
    8000397e:	70a2                	ld	ra,40(sp)
    80003980:	7402                	ld	s0,32(sp)
    80003982:	6145                	addi	sp,sp,48
    80003984:	8082                	ret

0000000080003986 <sys_sigret>:

// ADDED Q2.1.5
uint64
sys_sigret(void)
{
    80003986:	1141                	addi	sp,sp,-16
    80003988:	e406                	sd	ra,8(sp)
    8000398a:	e022                	sd	s0,0(sp)
    8000398c:	0800                	addi	s0,sp,16
  sigret();
    8000398e:	fffff097          	auipc	ra,0xfffff
    80003992:	31a080e7          	jalr	794(ra) # 80002ca8 <sigret>
  return 0;
}
    80003996:	4501                	li	a0,0
    80003998:	60a2                	ld	ra,8(sp)
    8000399a:	6402                	ld	s0,0(sp)
    8000399c:	0141                	addi	sp,sp,16
    8000399e:	8082                	ret

00000000800039a0 <sys_kthread_create>:

// ADDED Q3.2
uint64
sys_kthread_create(void)
{
    800039a0:	1101                	addi	sp,sp,-32
    800039a2:	ec06                	sd	ra,24(sp)
    800039a4:	e822                	sd	s0,16(sp)
    800039a6:	1000                	addi	s0,sp,32
  uint64 start_func;
  uint64 stack;

  if(argaddr(0, &start_func) < 0)
    800039a8:	fe840593          	addi	a1,s0,-24
    800039ac:	4501                	li	a0,0
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	c68080e7          	jalr	-920(ra) # 80003616 <argaddr>
    return -1;
    800039b6:	57fd                	li	a5,-1
  if(argaddr(0, &start_func) < 0)
    800039b8:	02054563          	bltz	a0,800039e2 <sys_kthread_create+0x42>

  if(argaddr(1, &stack) < 0)
    800039bc:	fe040593          	addi	a1,s0,-32
    800039c0:	4505                	li	a0,1
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	c54080e7          	jalr	-940(ra) # 80003616 <argaddr>
    return -1;
    800039ca:	57fd                	li	a5,-1
  if(argaddr(1, &stack) < 0)
    800039cc:	00054b63          	bltz	a0,800039e2 <sys_kthread_create+0x42>

  return kthread_create(start_func, stack);
    800039d0:	fe043583          	ld	a1,-32(s0)
    800039d4:	fe843503          	ld	a0,-24(s0)
    800039d8:	fffff097          	auipc	ra,0xfffff
    800039dc:	33e080e7          	jalr	830(ra) # 80002d16 <kthread_create>
    800039e0:	87aa                	mv	a5,a0
}
    800039e2:	853e                	mv	a0,a5
    800039e4:	60e2                	ld	ra,24(sp)
    800039e6:	6442                	ld	s0,16(sp)
    800039e8:	6105                	addi	sp,sp,32
    800039ea:	8082                	ret

00000000800039ec <sys_kthread_id>:

uint64
sys_kthread_id(void)
{
    800039ec:	1141                	addi	sp,sp,-16
    800039ee:	e406                	sd	ra,8(sp)
    800039f0:	e022                	sd	s0,0(sp)
    800039f2:	0800                	addi	s0,sp,16
  return mythread()->tid;
    800039f4:	ffffe097          	auipc	ra,0xffffe
    800039f8:	03c080e7          	jalr	60(ra) # 80001a30 <mythread>
}
    800039fc:	5908                	lw	a0,48(a0)
    800039fe:	60a2                	ld	ra,8(sp)
    80003a00:	6402                	ld	s0,0(sp)
    80003a02:	0141                	addi	sp,sp,16
    80003a04:	8082                	ret

0000000080003a06 <sys_kthread_exit>:

uint64
sys_kthread_exit(void)
{
    80003a06:	1101                	addi	sp,sp,-32
    80003a08:	ec06                	sd	ra,24(sp)
    80003a0a:	e822                	sd	s0,16(sp)
    80003a0c:	1000                	addi	s0,sp,32
  int status;

  if(argint(0, &status) < 0)
    80003a0e:	fec40593          	addi	a1,s0,-20
    80003a12:	4501                	li	a0,0
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	be0080e7          	jalr	-1056(ra) # 800035f4 <argint>
    return -1;
    80003a1c:	57fd                	li	a5,-1
  if(argint(0, &status) < 0)
    80003a1e:	00054963          	bltz	a0,80003a30 <sys_kthread_exit+0x2a>

  kthread_exit(status);
    80003a22:	fec42503          	lw	a0,-20(s0)
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	61a080e7          	jalr	1562(ra) # 80003040 <kthread_exit>
  return 0;
    80003a2e:	4781                	li	a5,0
}
    80003a30:	853e                	mv	a0,a5
    80003a32:	60e2                	ld	ra,24(sp)
    80003a34:	6442                	ld	s0,16(sp)
    80003a36:	6105                	addi	sp,sp,32
    80003a38:	8082                	ret

0000000080003a3a <sys_kthread_join>:

uint64
sys_kthread_join(void)
{
    80003a3a:	1101                	addi	sp,sp,-32
    80003a3c:	ec06                	sd	ra,24(sp)
    80003a3e:	e822                	sd	s0,16(sp)
    80003a40:	1000                	addi	s0,sp,32
  int thread_id;
  int *status;

  if(argint(0, &thread_id) < 0)
    80003a42:	fec40593          	addi	a1,s0,-20
    80003a46:	4501                	li	a0,0
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	bac080e7          	jalr	-1108(ra) # 800035f4 <argint>
    return -1;
    80003a50:	57fd                	li	a5,-1
  if(argint(0, &thread_id) < 0)
    80003a52:	02054563          	bltz	a0,80003a7c <sys_kthread_join+0x42>

  if(argaddr(1, (uint64 *)&status) < 0)
    80003a56:	fe040593          	addi	a1,s0,-32
    80003a5a:	4505                	li	a0,1
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	bba080e7          	jalr	-1094(ra) # 80003616 <argaddr>
    return -1;
    80003a64:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&status) < 0)
    80003a66:	00054b63          	bltz	a0,80003a7c <sys_kthread_join+0x42>

  return kthread_join(thread_id, status);
    80003a6a:	fe043583          	ld	a1,-32(s0)
    80003a6e:	fec42503          	lw	a0,-20(s0)
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	39c080e7          	jalr	924(ra) # 80002e0e <kthread_join>
    80003a7a:	87aa                	mv	a5,a0
    80003a7c:	853e                	mv	a0,a5
    80003a7e:	60e2                	ld	ra,24(sp)
    80003a80:	6442                	ld	s0,16(sp)
    80003a82:	6105                	addi	sp,sp,32
    80003a84:	8082                	ret

0000000080003a86 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a86:	7179                	addi	sp,sp,-48
    80003a88:	f406                	sd	ra,40(sp)
    80003a8a:	f022                	sd	s0,32(sp)
    80003a8c:	ec26                	sd	s1,24(sp)
    80003a8e:	e84a                	sd	s2,16(sp)
    80003a90:	e44e                	sd	s3,8(sp)
    80003a92:	e052                	sd	s4,0(sp)
    80003a94:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a96:	00005597          	auipc	a1,0x5
    80003a9a:	a9a58593          	addi	a1,a1,-1382 # 80008530 <syscalls+0xe8>
    80003a9e:	00030517          	auipc	a0,0x30
    80003aa2:	c6250513          	addi	a0,a0,-926 # 80033700 <bcache>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	08c080e7          	jalr	140(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003aae:	00038797          	auipc	a5,0x38
    80003ab2:	c5278793          	addi	a5,a5,-942 # 8003b700 <bcache+0x8000>
    80003ab6:	00038717          	auipc	a4,0x38
    80003aba:	eb270713          	addi	a4,a4,-334 # 8003b968 <bcache+0x8268>
    80003abe:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003ac2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ac6:	00030497          	auipc	s1,0x30
    80003aca:	c5248493          	addi	s1,s1,-942 # 80033718 <bcache+0x18>
    b->next = bcache.head.next;
    80003ace:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003ad0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003ad2:	00005a17          	auipc	s4,0x5
    80003ad6:	a66a0a13          	addi	s4,s4,-1434 # 80008538 <syscalls+0xf0>
    b->next = bcache.head.next;
    80003ada:	2b893783          	ld	a5,696(s2)
    80003ade:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003ae0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003ae4:	85d2                	mv	a1,s4
    80003ae6:	01048513          	addi	a0,s1,16
    80003aea:	00001097          	auipc	ra,0x1
    80003aee:	4c2080e7          	jalr	1218(ra) # 80004fac <initsleeplock>
    bcache.head.next->prev = b;
    80003af2:	2b893783          	ld	a5,696(s2)
    80003af6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003af8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003afc:	45848493          	addi	s1,s1,1112
    80003b00:	fd349de3          	bne	s1,s3,80003ada <binit+0x54>
  }
}
    80003b04:	70a2                	ld	ra,40(sp)
    80003b06:	7402                	ld	s0,32(sp)
    80003b08:	64e2                	ld	s1,24(sp)
    80003b0a:	6942                	ld	s2,16(sp)
    80003b0c:	69a2                	ld	s3,8(sp)
    80003b0e:	6a02                	ld	s4,0(sp)
    80003b10:	6145                	addi	sp,sp,48
    80003b12:	8082                	ret

0000000080003b14 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b14:	7179                	addi	sp,sp,-48
    80003b16:	f406                	sd	ra,40(sp)
    80003b18:	f022                	sd	s0,32(sp)
    80003b1a:	ec26                	sd	s1,24(sp)
    80003b1c:	e84a                	sd	s2,16(sp)
    80003b1e:	e44e                	sd	s3,8(sp)
    80003b20:	1800                	addi	s0,sp,48
    80003b22:	892a                	mv	s2,a0
    80003b24:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003b26:	00030517          	auipc	a0,0x30
    80003b2a:	bda50513          	addi	a0,a0,-1062 # 80033700 <bcache>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	094080e7          	jalr	148(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b36:	00038497          	auipc	s1,0x38
    80003b3a:	e824b483          	ld	s1,-382(s1) # 8003b9b8 <bcache+0x82b8>
    80003b3e:	00038797          	auipc	a5,0x38
    80003b42:	e2a78793          	addi	a5,a5,-470 # 8003b968 <bcache+0x8268>
    80003b46:	02f48f63          	beq	s1,a5,80003b84 <bread+0x70>
    80003b4a:	873e                	mv	a4,a5
    80003b4c:	a021                	j	80003b54 <bread+0x40>
    80003b4e:	68a4                	ld	s1,80(s1)
    80003b50:	02e48a63          	beq	s1,a4,80003b84 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b54:	449c                	lw	a5,8(s1)
    80003b56:	ff279ce3          	bne	a5,s2,80003b4e <bread+0x3a>
    80003b5a:	44dc                	lw	a5,12(s1)
    80003b5c:	ff3799e3          	bne	a5,s3,80003b4e <bread+0x3a>
      b->refcnt++;
    80003b60:	40bc                	lw	a5,64(s1)
    80003b62:	2785                	addiw	a5,a5,1
    80003b64:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b66:	00030517          	auipc	a0,0x30
    80003b6a:	b9a50513          	addi	a0,a0,-1126 # 80033700 <bcache>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	11a080e7          	jalr	282(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003b76:	01048513          	addi	a0,s1,16
    80003b7a:	00001097          	auipc	ra,0x1
    80003b7e:	46c080e7          	jalr	1132(ra) # 80004fe6 <acquiresleep>
      return b;
    80003b82:	a8b9                	j	80003be0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b84:	00038497          	auipc	s1,0x38
    80003b88:	e2c4b483          	ld	s1,-468(s1) # 8003b9b0 <bcache+0x82b0>
    80003b8c:	00038797          	auipc	a5,0x38
    80003b90:	ddc78793          	addi	a5,a5,-548 # 8003b968 <bcache+0x8268>
    80003b94:	00f48863          	beq	s1,a5,80003ba4 <bread+0x90>
    80003b98:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b9a:	40bc                	lw	a5,64(s1)
    80003b9c:	cf81                	beqz	a5,80003bb4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b9e:	64a4                	ld	s1,72(s1)
    80003ba0:	fee49de3          	bne	s1,a4,80003b9a <bread+0x86>
  panic("bget: no buffers");
    80003ba4:	00005517          	auipc	a0,0x5
    80003ba8:	99c50513          	addi	a0,a0,-1636 # 80008540 <syscalls+0xf8>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	97e080e7          	jalr	-1666(ra) # 8000052a <panic>
      b->dev = dev;
    80003bb4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003bb8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003bbc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003bc0:	4785                	li	a5,1
    80003bc2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003bc4:	00030517          	auipc	a0,0x30
    80003bc8:	b3c50513          	addi	a0,a0,-1220 # 80033700 <bcache>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	0bc080e7          	jalr	188(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003bd4:	01048513          	addi	a0,s1,16
    80003bd8:	00001097          	auipc	ra,0x1
    80003bdc:	40e080e7          	jalr	1038(ra) # 80004fe6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003be0:	409c                	lw	a5,0(s1)
    80003be2:	cb89                	beqz	a5,80003bf4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003be4:	8526                	mv	a0,s1
    80003be6:	70a2                	ld	ra,40(sp)
    80003be8:	7402                	ld	s0,32(sp)
    80003bea:	64e2                	ld	s1,24(sp)
    80003bec:	6942                	ld	s2,16(sp)
    80003bee:	69a2                	ld	s3,8(sp)
    80003bf0:	6145                	addi	sp,sp,48
    80003bf2:	8082                	ret
    virtio_disk_rw(b, 0);
    80003bf4:	4581                	li	a1,0
    80003bf6:	8526                	mv	a0,s1
    80003bf8:	00003097          	auipc	ra,0x3
    80003bfc:	fbe080e7          	jalr	-66(ra) # 80006bb6 <virtio_disk_rw>
    b->valid = 1;
    80003c00:	4785                	li	a5,1
    80003c02:	c09c                	sw	a5,0(s1)
  return b;
    80003c04:	b7c5                	j	80003be4 <bread+0xd0>

0000000080003c06 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003c06:	1101                	addi	sp,sp,-32
    80003c08:	ec06                	sd	ra,24(sp)
    80003c0a:	e822                	sd	s0,16(sp)
    80003c0c:	e426                	sd	s1,8(sp)
    80003c0e:	1000                	addi	s0,sp,32
    80003c10:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c12:	0541                	addi	a0,a0,16
    80003c14:	00001097          	auipc	ra,0x1
    80003c18:	46c080e7          	jalr	1132(ra) # 80005080 <holdingsleep>
    80003c1c:	cd01                	beqz	a0,80003c34 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c1e:	4585                	li	a1,1
    80003c20:	8526                	mv	a0,s1
    80003c22:	00003097          	auipc	ra,0x3
    80003c26:	f94080e7          	jalr	-108(ra) # 80006bb6 <virtio_disk_rw>
}
    80003c2a:	60e2                	ld	ra,24(sp)
    80003c2c:	6442                	ld	s0,16(sp)
    80003c2e:	64a2                	ld	s1,8(sp)
    80003c30:	6105                	addi	sp,sp,32
    80003c32:	8082                	ret
    panic("bwrite");
    80003c34:	00005517          	auipc	a0,0x5
    80003c38:	92450513          	addi	a0,a0,-1756 # 80008558 <syscalls+0x110>
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	8ee080e7          	jalr	-1810(ra) # 8000052a <panic>

0000000080003c44 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c44:	1101                	addi	sp,sp,-32
    80003c46:	ec06                	sd	ra,24(sp)
    80003c48:	e822                	sd	s0,16(sp)
    80003c4a:	e426                	sd	s1,8(sp)
    80003c4c:	e04a                	sd	s2,0(sp)
    80003c4e:	1000                	addi	s0,sp,32
    80003c50:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c52:	01050913          	addi	s2,a0,16
    80003c56:	854a                	mv	a0,s2
    80003c58:	00001097          	auipc	ra,0x1
    80003c5c:	428080e7          	jalr	1064(ra) # 80005080 <holdingsleep>
    80003c60:	c92d                	beqz	a0,80003cd2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c62:	854a                	mv	a0,s2
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	3d8080e7          	jalr	984(ra) # 8000503c <releasesleep>

  acquire(&bcache.lock);
    80003c6c:	00030517          	auipc	a0,0x30
    80003c70:	a9450513          	addi	a0,a0,-1388 # 80033700 <bcache>
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	f4e080e7          	jalr	-178(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003c7c:	40bc                	lw	a5,64(s1)
    80003c7e:	37fd                	addiw	a5,a5,-1
    80003c80:	0007871b          	sext.w	a4,a5
    80003c84:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c86:	eb05                	bnez	a4,80003cb6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c88:	68bc                	ld	a5,80(s1)
    80003c8a:	64b8                	ld	a4,72(s1)
    80003c8c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c8e:	64bc                	ld	a5,72(s1)
    80003c90:	68b8                	ld	a4,80(s1)
    80003c92:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c94:	00038797          	auipc	a5,0x38
    80003c98:	a6c78793          	addi	a5,a5,-1428 # 8003b700 <bcache+0x8000>
    80003c9c:	2b87b703          	ld	a4,696(a5)
    80003ca0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003ca2:	00038717          	auipc	a4,0x38
    80003ca6:	cc670713          	addi	a4,a4,-826 # 8003b968 <bcache+0x8268>
    80003caa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003cac:	2b87b703          	ld	a4,696(a5)
    80003cb0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003cb2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003cb6:	00030517          	auipc	a0,0x30
    80003cba:	a4a50513          	addi	a0,a0,-1462 # 80033700 <bcache>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	fca080e7          	jalr	-54(ra) # 80000c88 <release>
}
    80003cc6:	60e2                	ld	ra,24(sp)
    80003cc8:	6442                	ld	s0,16(sp)
    80003cca:	64a2                	ld	s1,8(sp)
    80003ccc:	6902                	ld	s2,0(sp)
    80003cce:	6105                	addi	sp,sp,32
    80003cd0:	8082                	ret
    panic("brelse");
    80003cd2:	00005517          	auipc	a0,0x5
    80003cd6:	88e50513          	addi	a0,a0,-1906 # 80008560 <syscalls+0x118>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	850080e7          	jalr	-1968(ra) # 8000052a <panic>

0000000080003ce2 <bpin>:

void
bpin(struct buf *b) {
    80003ce2:	1101                	addi	sp,sp,-32
    80003ce4:	ec06                	sd	ra,24(sp)
    80003ce6:	e822                	sd	s0,16(sp)
    80003ce8:	e426                	sd	s1,8(sp)
    80003cea:	1000                	addi	s0,sp,32
    80003cec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cee:	00030517          	auipc	a0,0x30
    80003cf2:	a1250513          	addi	a0,a0,-1518 # 80033700 <bcache>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	ecc080e7          	jalr	-308(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003cfe:	40bc                	lw	a5,64(s1)
    80003d00:	2785                	addiw	a5,a5,1
    80003d02:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d04:	00030517          	auipc	a0,0x30
    80003d08:	9fc50513          	addi	a0,a0,-1540 # 80033700 <bcache>
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	f7c080e7          	jalr	-132(ra) # 80000c88 <release>
}
    80003d14:	60e2                	ld	ra,24(sp)
    80003d16:	6442                	ld	s0,16(sp)
    80003d18:	64a2                	ld	s1,8(sp)
    80003d1a:	6105                	addi	sp,sp,32
    80003d1c:	8082                	ret

0000000080003d1e <bunpin>:

void
bunpin(struct buf *b) {
    80003d1e:	1101                	addi	sp,sp,-32
    80003d20:	ec06                	sd	ra,24(sp)
    80003d22:	e822                	sd	s0,16(sp)
    80003d24:	e426                	sd	s1,8(sp)
    80003d26:	1000                	addi	s0,sp,32
    80003d28:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d2a:	00030517          	auipc	a0,0x30
    80003d2e:	9d650513          	addi	a0,a0,-1578 # 80033700 <bcache>
    80003d32:	ffffd097          	auipc	ra,0xffffd
    80003d36:	e90080e7          	jalr	-368(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003d3a:	40bc                	lw	a5,64(s1)
    80003d3c:	37fd                	addiw	a5,a5,-1
    80003d3e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d40:	00030517          	auipc	a0,0x30
    80003d44:	9c050513          	addi	a0,a0,-1600 # 80033700 <bcache>
    80003d48:	ffffd097          	auipc	ra,0xffffd
    80003d4c:	f40080e7          	jalr	-192(ra) # 80000c88 <release>
}
    80003d50:	60e2                	ld	ra,24(sp)
    80003d52:	6442                	ld	s0,16(sp)
    80003d54:	64a2                	ld	s1,8(sp)
    80003d56:	6105                	addi	sp,sp,32
    80003d58:	8082                	ret

0000000080003d5a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d5a:	1101                	addi	sp,sp,-32
    80003d5c:	ec06                	sd	ra,24(sp)
    80003d5e:	e822                	sd	s0,16(sp)
    80003d60:	e426                	sd	s1,8(sp)
    80003d62:	e04a                	sd	s2,0(sp)
    80003d64:	1000                	addi	s0,sp,32
    80003d66:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d68:	00d5d59b          	srliw	a1,a1,0xd
    80003d6c:	00038797          	auipc	a5,0x38
    80003d70:	0707a783          	lw	a5,112(a5) # 8003bddc <sb+0x1c>
    80003d74:	9dbd                	addw	a1,a1,a5
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	d9e080e7          	jalr	-610(ra) # 80003b14 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d7e:	0074f713          	andi	a4,s1,7
    80003d82:	4785                	li	a5,1
    80003d84:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d88:	14ce                	slli	s1,s1,0x33
    80003d8a:	90d9                	srli	s1,s1,0x36
    80003d8c:	00950733          	add	a4,a0,s1
    80003d90:	05874703          	lbu	a4,88(a4)
    80003d94:	00e7f6b3          	and	a3,a5,a4
    80003d98:	c69d                	beqz	a3,80003dc6 <bfree+0x6c>
    80003d9a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d9c:	94aa                	add	s1,s1,a0
    80003d9e:	fff7c793          	not	a5,a5
    80003da2:	8ff9                	and	a5,a5,a4
    80003da4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003da8:	00001097          	auipc	ra,0x1
    80003dac:	11e080e7          	jalr	286(ra) # 80004ec6 <log_write>
  brelse(bp);
    80003db0:	854a                	mv	a0,s2
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	e92080e7          	jalr	-366(ra) # 80003c44 <brelse>
}
    80003dba:	60e2                	ld	ra,24(sp)
    80003dbc:	6442                	ld	s0,16(sp)
    80003dbe:	64a2                	ld	s1,8(sp)
    80003dc0:	6902                	ld	s2,0(sp)
    80003dc2:	6105                	addi	sp,sp,32
    80003dc4:	8082                	ret
    panic("freeing free block");
    80003dc6:	00004517          	auipc	a0,0x4
    80003dca:	7a250513          	addi	a0,a0,1954 # 80008568 <syscalls+0x120>
    80003dce:	ffffc097          	auipc	ra,0xffffc
    80003dd2:	75c080e7          	jalr	1884(ra) # 8000052a <panic>

0000000080003dd6 <balloc>:
{
    80003dd6:	711d                	addi	sp,sp,-96
    80003dd8:	ec86                	sd	ra,88(sp)
    80003dda:	e8a2                	sd	s0,80(sp)
    80003ddc:	e4a6                	sd	s1,72(sp)
    80003dde:	e0ca                	sd	s2,64(sp)
    80003de0:	fc4e                	sd	s3,56(sp)
    80003de2:	f852                	sd	s4,48(sp)
    80003de4:	f456                	sd	s5,40(sp)
    80003de6:	f05a                	sd	s6,32(sp)
    80003de8:	ec5e                	sd	s7,24(sp)
    80003dea:	e862                	sd	s8,16(sp)
    80003dec:	e466                	sd	s9,8(sp)
    80003dee:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003df0:	00038797          	auipc	a5,0x38
    80003df4:	fd47a783          	lw	a5,-44(a5) # 8003bdc4 <sb+0x4>
    80003df8:	cbd1                	beqz	a5,80003e8c <balloc+0xb6>
    80003dfa:	8baa                	mv	s7,a0
    80003dfc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003dfe:	00038b17          	auipc	s6,0x38
    80003e02:	fc2b0b13          	addi	s6,s6,-62 # 8003bdc0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e06:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003e08:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e0a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003e0c:	6c89                	lui	s9,0x2
    80003e0e:	a831                	j	80003e2a <balloc+0x54>
    brelse(bp);
    80003e10:	854a                	mv	a0,s2
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	e32080e7          	jalr	-462(ra) # 80003c44 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003e1a:	015c87bb          	addw	a5,s9,s5
    80003e1e:	00078a9b          	sext.w	s5,a5
    80003e22:	004b2703          	lw	a4,4(s6)
    80003e26:	06eaf363          	bgeu	s5,a4,80003e8c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003e2a:	41fad79b          	sraiw	a5,s5,0x1f
    80003e2e:	0137d79b          	srliw	a5,a5,0x13
    80003e32:	015787bb          	addw	a5,a5,s5
    80003e36:	40d7d79b          	sraiw	a5,a5,0xd
    80003e3a:	01cb2583          	lw	a1,28(s6)
    80003e3e:	9dbd                	addw	a1,a1,a5
    80003e40:	855e                	mv	a0,s7
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	cd2080e7          	jalr	-814(ra) # 80003b14 <bread>
    80003e4a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e4c:	004b2503          	lw	a0,4(s6)
    80003e50:	000a849b          	sext.w	s1,s5
    80003e54:	8662                	mv	a2,s8
    80003e56:	faa4fde3          	bgeu	s1,a0,80003e10 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003e5a:	41f6579b          	sraiw	a5,a2,0x1f
    80003e5e:	01d7d69b          	srliw	a3,a5,0x1d
    80003e62:	00c6873b          	addw	a4,a3,a2
    80003e66:	00777793          	andi	a5,a4,7
    80003e6a:	9f95                	subw	a5,a5,a3
    80003e6c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e70:	4037571b          	sraiw	a4,a4,0x3
    80003e74:	00e906b3          	add	a3,s2,a4
    80003e78:	0586c683          	lbu	a3,88(a3) # 2000058 <_entry-0x7dffffa8>
    80003e7c:	00d7f5b3          	and	a1,a5,a3
    80003e80:	cd91                	beqz	a1,80003e9c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e82:	2605                	addiw	a2,a2,1
    80003e84:	2485                	addiw	s1,s1,1
    80003e86:	fd4618e3          	bne	a2,s4,80003e56 <balloc+0x80>
    80003e8a:	b759                	j	80003e10 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e8c:	00004517          	auipc	a0,0x4
    80003e90:	6f450513          	addi	a0,a0,1780 # 80008580 <syscalls+0x138>
    80003e94:	ffffc097          	auipc	ra,0xffffc
    80003e98:	696080e7          	jalr	1686(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e9c:	974a                	add	a4,a4,s2
    80003e9e:	8fd5                	or	a5,a5,a3
    80003ea0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003ea4:	854a                	mv	a0,s2
    80003ea6:	00001097          	auipc	ra,0x1
    80003eaa:	020080e7          	jalr	32(ra) # 80004ec6 <log_write>
        brelse(bp);
    80003eae:	854a                	mv	a0,s2
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	d94080e7          	jalr	-620(ra) # 80003c44 <brelse>
  bp = bread(dev, bno);
    80003eb8:	85a6                	mv	a1,s1
    80003eba:	855e                	mv	a0,s7
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	c58080e7          	jalr	-936(ra) # 80003b14 <bread>
    80003ec4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003ec6:	40000613          	li	a2,1024
    80003eca:	4581                	li	a1,0
    80003ecc:	05850513          	addi	a0,a0,88
    80003ed0:	ffffd097          	auipc	ra,0xffffd
    80003ed4:	e12080e7          	jalr	-494(ra) # 80000ce2 <memset>
  log_write(bp);
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00001097          	auipc	ra,0x1
    80003ede:	fec080e7          	jalr	-20(ra) # 80004ec6 <log_write>
  brelse(bp);
    80003ee2:	854a                	mv	a0,s2
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	d60080e7          	jalr	-672(ra) # 80003c44 <brelse>
}
    80003eec:	8526                	mv	a0,s1
    80003eee:	60e6                	ld	ra,88(sp)
    80003ef0:	6446                	ld	s0,80(sp)
    80003ef2:	64a6                	ld	s1,72(sp)
    80003ef4:	6906                	ld	s2,64(sp)
    80003ef6:	79e2                	ld	s3,56(sp)
    80003ef8:	7a42                	ld	s4,48(sp)
    80003efa:	7aa2                	ld	s5,40(sp)
    80003efc:	7b02                	ld	s6,32(sp)
    80003efe:	6be2                	ld	s7,24(sp)
    80003f00:	6c42                	ld	s8,16(sp)
    80003f02:	6ca2                	ld	s9,8(sp)
    80003f04:	6125                	addi	sp,sp,96
    80003f06:	8082                	ret

0000000080003f08 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003f08:	7179                	addi	sp,sp,-48
    80003f0a:	f406                	sd	ra,40(sp)
    80003f0c:	f022                	sd	s0,32(sp)
    80003f0e:	ec26                	sd	s1,24(sp)
    80003f10:	e84a                	sd	s2,16(sp)
    80003f12:	e44e                	sd	s3,8(sp)
    80003f14:	e052                	sd	s4,0(sp)
    80003f16:	1800                	addi	s0,sp,48
    80003f18:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003f1a:	47ad                	li	a5,11
    80003f1c:	04b7fe63          	bgeu	a5,a1,80003f78 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003f20:	ff45849b          	addiw	s1,a1,-12
    80003f24:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003f28:	0ff00793          	li	a5,255
    80003f2c:	0ae7e463          	bltu	a5,a4,80003fd4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003f30:	08052583          	lw	a1,128(a0)
    80003f34:	c5b5                	beqz	a1,80003fa0 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003f36:	00092503          	lw	a0,0(s2)
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	bda080e7          	jalr	-1062(ra) # 80003b14 <bread>
    80003f42:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003f44:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003f48:	02049713          	slli	a4,s1,0x20
    80003f4c:	01e75593          	srli	a1,a4,0x1e
    80003f50:	00b784b3          	add	s1,a5,a1
    80003f54:	0004a983          	lw	s3,0(s1)
    80003f58:	04098e63          	beqz	s3,80003fb4 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003f5c:	8552                	mv	a0,s4
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	ce6080e7          	jalr	-794(ra) # 80003c44 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f66:	854e                	mv	a0,s3
    80003f68:	70a2                	ld	ra,40(sp)
    80003f6a:	7402                	ld	s0,32(sp)
    80003f6c:	64e2                	ld	s1,24(sp)
    80003f6e:	6942                	ld	s2,16(sp)
    80003f70:	69a2                	ld	s3,8(sp)
    80003f72:	6a02                	ld	s4,0(sp)
    80003f74:	6145                	addi	sp,sp,48
    80003f76:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f78:	02059793          	slli	a5,a1,0x20
    80003f7c:	01e7d593          	srli	a1,a5,0x1e
    80003f80:	00b504b3          	add	s1,a0,a1
    80003f84:	0504a983          	lw	s3,80(s1)
    80003f88:	fc099fe3          	bnez	s3,80003f66 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f8c:	4108                	lw	a0,0(a0)
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	e48080e7          	jalr	-440(ra) # 80003dd6 <balloc>
    80003f96:	0005099b          	sext.w	s3,a0
    80003f9a:	0534a823          	sw	s3,80(s1)
    80003f9e:	b7e1                	j	80003f66 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003fa0:	4108                	lw	a0,0(a0)
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	e34080e7          	jalr	-460(ra) # 80003dd6 <balloc>
    80003faa:	0005059b          	sext.w	a1,a0
    80003fae:	08b92023          	sw	a1,128(s2)
    80003fb2:	b751                	j	80003f36 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003fb4:	00092503          	lw	a0,0(s2)
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	e1e080e7          	jalr	-482(ra) # 80003dd6 <balloc>
    80003fc0:	0005099b          	sext.w	s3,a0
    80003fc4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003fc8:	8552                	mv	a0,s4
    80003fca:	00001097          	auipc	ra,0x1
    80003fce:	efc080e7          	jalr	-260(ra) # 80004ec6 <log_write>
    80003fd2:	b769                	j	80003f5c <bmap+0x54>
  panic("bmap: out of range");
    80003fd4:	00004517          	auipc	a0,0x4
    80003fd8:	5c450513          	addi	a0,a0,1476 # 80008598 <syscalls+0x150>
    80003fdc:	ffffc097          	auipc	ra,0xffffc
    80003fe0:	54e080e7          	jalr	1358(ra) # 8000052a <panic>

0000000080003fe4 <iget>:
{
    80003fe4:	7179                	addi	sp,sp,-48
    80003fe6:	f406                	sd	ra,40(sp)
    80003fe8:	f022                	sd	s0,32(sp)
    80003fea:	ec26                	sd	s1,24(sp)
    80003fec:	e84a                	sd	s2,16(sp)
    80003fee:	e44e                	sd	s3,8(sp)
    80003ff0:	e052                	sd	s4,0(sp)
    80003ff2:	1800                	addi	s0,sp,48
    80003ff4:	89aa                	mv	s3,a0
    80003ff6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ff8:	00038517          	auipc	a0,0x38
    80003ffc:	de850513          	addi	a0,a0,-536 # 8003bde0 <itable>
    80004000:	ffffd097          	auipc	ra,0xffffd
    80004004:	bc2080e7          	jalr	-1086(ra) # 80000bc2 <acquire>
  empty = 0;
    80004008:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000400a:	00038497          	auipc	s1,0x38
    8000400e:	dee48493          	addi	s1,s1,-530 # 8003bdf8 <itable+0x18>
    80004012:	0003a697          	auipc	a3,0x3a
    80004016:	87668693          	addi	a3,a3,-1930 # 8003d888 <log>
    8000401a:	a039                	j	80004028 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000401c:	02090b63          	beqz	s2,80004052 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004020:	08848493          	addi	s1,s1,136
    80004024:	02d48a63          	beq	s1,a3,80004058 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004028:	449c                	lw	a5,8(s1)
    8000402a:	fef059e3          	blez	a5,8000401c <iget+0x38>
    8000402e:	4098                	lw	a4,0(s1)
    80004030:	ff3716e3          	bne	a4,s3,8000401c <iget+0x38>
    80004034:	40d8                	lw	a4,4(s1)
    80004036:	ff4713e3          	bne	a4,s4,8000401c <iget+0x38>
      ip->ref++;
    8000403a:	2785                	addiw	a5,a5,1
    8000403c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000403e:	00038517          	auipc	a0,0x38
    80004042:	da250513          	addi	a0,a0,-606 # 8003bde0 <itable>
    80004046:	ffffd097          	auipc	ra,0xffffd
    8000404a:	c42080e7          	jalr	-958(ra) # 80000c88 <release>
      return ip;
    8000404e:	8926                	mv	s2,s1
    80004050:	a03d                	j	8000407e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004052:	f7f9                	bnez	a5,80004020 <iget+0x3c>
    80004054:	8926                	mv	s2,s1
    80004056:	b7e9                	j	80004020 <iget+0x3c>
  if(empty == 0)
    80004058:	02090c63          	beqz	s2,80004090 <iget+0xac>
  ip->dev = dev;
    8000405c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004060:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004064:	4785                	li	a5,1
    80004066:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000406a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000406e:	00038517          	auipc	a0,0x38
    80004072:	d7250513          	addi	a0,a0,-654 # 8003bde0 <itable>
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	c12080e7          	jalr	-1006(ra) # 80000c88 <release>
}
    8000407e:	854a                	mv	a0,s2
    80004080:	70a2                	ld	ra,40(sp)
    80004082:	7402                	ld	s0,32(sp)
    80004084:	64e2                	ld	s1,24(sp)
    80004086:	6942                	ld	s2,16(sp)
    80004088:	69a2                	ld	s3,8(sp)
    8000408a:	6a02                	ld	s4,0(sp)
    8000408c:	6145                	addi	sp,sp,48
    8000408e:	8082                	ret
    panic("iget: no inodes");
    80004090:	00004517          	auipc	a0,0x4
    80004094:	52050513          	addi	a0,a0,1312 # 800085b0 <syscalls+0x168>
    80004098:	ffffc097          	auipc	ra,0xffffc
    8000409c:	492080e7          	jalr	1170(ra) # 8000052a <panic>

00000000800040a0 <fsinit>:
fsinit(int dev) {
    800040a0:	7179                	addi	sp,sp,-48
    800040a2:	f406                	sd	ra,40(sp)
    800040a4:	f022                	sd	s0,32(sp)
    800040a6:	ec26                	sd	s1,24(sp)
    800040a8:	e84a                	sd	s2,16(sp)
    800040aa:	e44e                	sd	s3,8(sp)
    800040ac:	1800                	addi	s0,sp,48
    800040ae:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800040b0:	4585                	li	a1,1
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	a62080e7          	jalr	-1438(ra) # 80003b14 <bread>
    800040ba:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800040bc:	00038997          	auipc	s3,0x38
    800040c0:	d0498993          	addi	s3,s3,-764 # 8003bdc0 <sb>
    800040c4:	02000613          	li	a2,32
    800040c8:	05850593          	addi	a1,a0,88
    800040cc:	854e                	mv	a0,s3
    800040ce:	ffffd097          	auipc	ra,0xffffd
    800040d2:	c70080e7          	jalr	-912(ra) # 80000d3e <memmove>
  brelse(bp);
    800040d6:	8526                	mv	a0,s1
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	b6c080e7          	jalr	-1172(ra) # 80003c44 <brelse>
  if(sb.magic != FSMAGIC)
    800040e0:	0009a703          	lw	a4,0(s3)
    800040e4:	102037b7          	lui	a5,0x10203
    800040e8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800040ec:	02f71263          	bne	a4,a5,80004110 <fsinit+0x70>
  initlog(dev, &sb);
    800040f0:	00038597          	auipc	a1,0x38
    800040f4:	cd058593          	addi	a1,a1,-816 # 8003bdc0 <sb>
    800040f8:	854a                	mv	a0,s2
    800040fa:	00001097          	auipc	ra,0x1
    800040fe:	b4e080e7          	jalr	-1202(ra) # 80004c48 <initlog>
}
    80004102:	70a2                	ld	ra,40(sp)
    80004104:	7402                	ld	s0,32(sp)
    80004106:	64e2                	ld	s1,24(sp)
    80004108:	6942                	ld	s2,16(sp)
    8000410a:	69a2                	ld	s3,8(sp)
    8000410c:	6145                	addi	sp,sp,48
    8000410e:	8082                	ret
    panic("invalid file system");
    80004110:	00004517          	auipc	a0,0x4
    80004114:	4b050513          	addi	a0,a0,1200 # 800085c0 <syscalls+0x178>
    80004118:	ffffc097          	auipc	ra,0xffffc
    8000411c:	412080e7          	jalr	1042(ra) # 8000052a <panic>

0000000080004120 <iinit>:
{
    80004120:	7179                	addi	sp,sp,-48
    80004122:	f406                	sd	ra,40(sp)
    80004124:	f022                	sd	s0,32(sp)
    80004126:	ec26                	sd	s1,24(sp)
    80004128:	e84a                	sd	s2,16(sp)
    8000412a:	e44e                	sd	s3,8(sp)
    8000412c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000412e:	00004597          	auipc	a1,0x4
    80004132:	4aa58593          	addi	a1,a1,1194 # 800085d8 <syscalls+0x190>
    80004136:	00038517          	auipc	a0,0x38
    8000413a:	caa50513          	addi	a0,a0,-854 # 8003bde0 <itable>
    8000413e:	ffffd097          	auipc	ra,0xffffd
    80004142:	9f4080e7          	jalr	-1548(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004146:	00038497          	auipc	s1,0x38
    8000414a:	cc248493          	addi	s1,s1,-830 # 8003be08 <itable+0x28>
    8000414e:	00039997          	auipc	s3,0x39
    80004152:	74a98993          	addi	s3,s3,1866 # 8003d898 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004156:	00004917          	auipc	s2,0x4
    8000415a:	48a90913          	addi	s2,s2,1162 # 800085e0 <syscalls+0x198>
    8000415e:	85ca                	mv	a1,s2
    80004160:	8526                	mv	a0,s1
    80004162:	00001097          	auipc	ra,0x1
    80004166:	e4a080e7          	jalr	-438(ra) # 80004fac <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000416a:	08848493          	addi	s1,s1,136
    8000416e:	ff3498e3          	bne	s1,s3,8000415e <iinit+0x3e>
}
    80004172:	70a2                	ld	ra,40(sp)
    80004174:	7402                	ld	s0,32(sp)
    80004176:	64e2                	ld	s1,24(sp)
    80004178:	6942                	ld	s2,16(sp)
    8000417a:	69a2                	ld	s3,8(sp)
    8000417c:	6145                	addi	sp,sp,48
    8000417e:	8082                	ret

0000000080004180 <ialloc>:
{
    80004180:	715d                	addi	sp,sp,-80
    80004182:	e486                	sd	ra,72(sp)
    80004184:	e0a2                	sd	s0,64(sp)
    80004186:	fc26                	sd	s1,56(sp)
    80004188:	f84a                	sd	s2,48(sp)
    8000418a:	f44e                	sd	s3,40(sp)
    8000418c:	f052                	sd	s4,32(sp)
    8000418e:	ec56                	sd	s5,24(sp)
    80004190:	e85a                	sd	s6,16(sp)
    80004192:	e45e                	sd	s7,8(sp)
    80004194:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004196:	00038717          	auipc	a4,0x38
    8000419a:	c3672703          	lw	a4,-970(a4) # 8003bdcc <sb+0xc>
    8000419e:	4785                	li	a5,1
    800041a0:	04e7fa63          	bgeu	a5,a4,800041f4 <ialloc+0x74>
    800041a4:	8aaa                	mv	s5,a0
    800041a6:	8bae                	mv	s7,a1
    800041a8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800041aa:	00038a17          	auipc	s4,0x38
    800041ae:	c16a0a13          	addi	s4,s4,-1002 # 8003bdc0 <sb>
    800041b2:	00048b1b          	sext.w	s6,s1
    800041b6:	0044d793          	srli	a5,s1,0x4
    800041ba:	018a2583          	lw	a1,24(s4)
    800041be:	9dbd                	addw	a1,a1,a5
    800041c0:	8556                	mv	a0,s5
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	952080e7          	jalr	-1710(ra) # 80003b14 <bread>
    800041ca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800041cc:	05850993          	addi	s3,a0,88
    800041d0:	00f4f793          	andi	a5,s1,15
    800041d4:	079a                	slli	a5,a5,0x6
    800041d6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800041d8:	00099783          	lh	a5,0(s3)
    800041dc:	c785                	beqz	a5,80004204 <ialloc+0x84>
    brelse(bp);
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	a66080e7          	jalr	-1434(ra) # 80003c44 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800041e6:	0485                	addi	s1,s1,1
    800041e8:	00ca2703          	lw	a4,12(s4)
    800041ec:	0004879b          	sext.w	a5,s1
    800041f0:	fce7e1e3          	bltu	a5,a4,800041b2 <ialloc+0x32>
  panic("ialloc: no inodes");
    800041f4:	00004517          	auipc	a0,0x4
    800041f8:	3f450513          	addi	a0,a0,1012 # 800085e8 <syscalls+0x1a0>
    800041fc:	ffffc097          	auipc	ra,0xffffc
    80004200:	32e080e7          	jalr	814(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80004204:	04000613          	li	a2,64
    80004208:	4581                	li	a1,0
    8000420a:	854e                	mv	a0,s3
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	ad6080e7          	jalr	-1322(ra) # 80000ce2 <memset>
      dip->type = type;
    80004214:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004218:	854a                	mv	a0,s2
    8000421a:	00001097          	auipc	ra,0x1
    8000421e:	cac080e7          	jalr	-852(ra) # 80004ec6 <log_write>
      brelse(bp);
    80004222:	854a                	mv	a0,s2
    80004224:	00000097          	auipc	ra,0x0
    80004228:	a20080e7          	jalr	-1504(ra) # 80003c44 <brelse>
      return iget(dev, inum);
    8000422c:	85da                	mv	a1,s6
    8000422e:	8556                	mv	a0,s5
    80004230:	00000097          	auipc	ra,0x0
    80004234:	db4080e7          	jalr	-588(ra) # 80003fe4 <iget>
}
    80004238:	60a6                	ld	ra,72(sp)
    8000423a:	6406                	ld	s0,64(sp)
    8000423c:	74e2                	ld	s1,56(sp)
    8000423e:	7942                	ld	s2,48(sp)
    80004240:	79a2                	ld	s3,40(sp)
    80004242:	7a02                	ld	s4,32(sp)
    80004244:	6ae2                	ld	s5,24(sp)
    80004246:	6b42                	ld	s6,16(sp)
    80004248:	6ba2                	ld	s7,8(sp)
    8000424a:	6161                	addi	sp,sp,80
    8000424c:	8082                	ret

000000008000424e <iupdate>:
{
    8000424e:	1101                	addi	sp,sp,-32
    80004250:	ec06                	sd	ra,24(sp)
    80004252:	e822                	sd	s0,16(sp)
    80004254:	e426                	sd	s1,8(sp)
    80004256:	e04a                	sd	s2,0(sp)
    80004258:	1000                	addi	s0,sp,32
    8000425a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000425c:	415c                	lw	a5,4(a0)
    8000425e:	0047d79b          	srliw	a5,a5,0x4
    80004262:	00038597          	auipc	a1,0x38
    80004266:	b765a583          	lw	a1,-1162(a1) # 8003bdd8 <sb+0x18>
    8000426a:	9dbd                	addw	a1,a1,a5
    8000426c:	4108                	lw	a0,0(a0)
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	8a6080e7          	jalr	-1882(ra) # 80003b14 <bread>
    80004276:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004278:	05850793          	addi	a5,a0,88
    8000427c:	40c8                	lw	a0,4(s1)
    8000427e:	893d                	andi	a0,a0,15
    80004280:	051a                	slli	a0,a0,0x6
    80004282:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004284:	04449703          	lh	a4,68(s1)
    80004288:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000428c:	04649703          	lh	a4,70(s1)
    80004290:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004294:	04849703          	lh	a4,72(s1)
    80004298:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000429c:	04a49703          	lh	a4,74(s1)
    800042a0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800042a4:	44f8                	lw	a4,76(s1)
    800042a6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800042a8:	03400613          	li	a2,52
    800042ac:	05048593          	addi	a1,s1,80
    800042b0:	0531                	addi	a0,a0,12
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	a8c080e7          	jalr	-1396(ra) # 80000d3e <memmove>
  log_write(bp);
    800042ba:	854a                	mv	a0,s2
    800042bc:	00001097          	auipc	ra,0x1
    800042c0:	c0a080e7          	jalr	-1014(ra) # 80004ec6 <log_write>
  brelse(bp);
    800042c4:	854a                	mv	a0,s2
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	97e080e7          	jalr	-1666(ra) # 80003c44 <brelse>
}
    800042ce:	60e2                	ld	ra,24(sp)
    800042d0:	6442                	ld	s0,16(sp)
    800042d2:	64a2                	ld	s1,8(sp)
    800042d4:	6902                	ld	s2,0(sp)
    800042d6:	6105                	addi	sp,sp,32
    800042d8:	8082                	ret

00000000800042da <idup>:
{
    800042da:	1101                	addi	sp,sp,-32
    800042dc:	ec06                	sd	ra,24(sp)
    800042de:	e822                	sd	s0,16(sp)
    800042e0:	e426                	sd	s1,8(sp)
    800042e2:	1000                	addi	s0,sp,32
    800042e4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042e6:	00038517          	auipc	a0,0x38
    800042ea:	afa50513          	addi	a0,a0,-1286 # 8003bde0 <itable>
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	8d4080e7          	jalr	-1836(ra) # 80000bc2 <acquire>
  ip->ref++;
    800042f6:	449c                	lw	a5,8(s1)
    800042f8:	2785                	addiw	a5,a5,1
    800042fa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042fc:	00038517          	auipc	a0,0x38
    80004300:	ae450513          	addi	a0,a0,-1308 # 8003bde0 <itable>
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	984080e7          	jalr	-1660(ra) # 80000c88 <release>
}
    8000430c:	8526                	mv	a0,s1
    8000430e:	60e2                	ld	ra,24(sp)
    80004310:	6442                	ld	s0,16(sp)
    80004312:	64a2                	ld	s1,8(sp)
    80004314:	6105                	addi	sp,sp,32
    80004316:	8082                	ret

0000000080004318 <ilock>:
{
    80004318:	1101                	addi	sp,sp,-32
    8000431a:	ec06                	sd	ra,24(sp)
    8000431c:	e822                	sd	s0,16(sp)
    8000431e:	e426                	sd	s1,8(sp)
    80004320:	e04a                	sd	s2,0(sp)
    80004322:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004324:	c115                	beqz	a0,80004348 <ilock+0x30>
    80004326:	84aa                	mv	s1,a0
    80004328:	451c                	lw	a5,8(a0)
    8000432a:	00f05f63          	blez	a5,80004348 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000432e:	0541                	addi	a0,a0,16
    80004330:	00001097          	auipc	ra,0x1
    80004334:	cb6080e7          	jalr	-842(ra) # 80004fe6 <acquiresleep>
  if(ip->valid == 0){
    80004338:	40bc                	lw	a5,64(s1)
    8000433a:	cf99                	beqz	a5,80004358 <ilock+0x40>
}
    8000433c:	60e2                	ld	ra,24(sp)
    8000433e:	6442                	ld	s0,16(sp)
    80004340:	64a2                	ld	s1,8(sp)
    80004342:	6902                	ld	s2,0(sp)
    80004344:	6105                	addi	sp,sp,32
    80004346:	8082                	ret
    panic("ilock");
    80004348:	00004517          	auipc	a0,0x4
    8000434c:	2b850513          	addi	a0,a0,696 # 80008600 <syscalls+0x1b8>
    80004350:	ffffc097          	auipc	ra,0xffffc
    80004354:	1da080e7          	jalr	474(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004358:	40dc                	lw	a5,4(s1)
    8000435a:	0047d79b          	srliw	a5,a5,0x4
    8000435e:	00038597          	auipc	a1,0x38
    80004362:	a7a5a583          	lw	a1,-1414(a1) # 8003bdd8 <sb+0x18>
    80004366:	9dbd                	addw	a1,a1,a5
    80004368:	4088                	lw	a0,0(s1)
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	7aa080e7          	jalr	1962(ra) # 80003b14 <bread>
    80004372:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004374:	05850593          	addi	a1,a0,88
    80004378:	40dc                	lw	a5,4(s1)
    8000437a:	8bbd                	andi	a5,a5,15
    8000437c:	079a                	slli	a5,a5,0x6
    8000437e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004380:	00059783          	lh	a5,0(a1)
    80004384:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004388:	00259783          	lh	a5,2(a1)
    8000438c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004390:	00459783          	lh	a5,4(a1)
    80004394:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004398:	00659783          	lh	a5,6(a1)
    8000439c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800043a0:	459c                	lw	a5,8(a1)
    800043a2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800043a4:	03400613          	li	a2,52
    800043a8:	05b1                	addi	a1,a1,12
    800043aa:	05048513          	addi	a0,s1,80
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	990080e7          	jalr	-1648(ra) # 80000d3e <memmove>
    brelse(bp);
    800043b6:	854a                	mv	a0,s2
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	88c080e7          	jalr	-1908(ra) # 80003c44 <brelse>
    ip->valid = 1;
    800043c0:	4785                	li	a5,1
    800043c2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800043c4:	04449783          	lh	a5,68(s1)
    800043c8:	fbb5                	bnez	a5,8000433c <ilock+0x24>
      panic("ilock: no type");
    800043ca:	00004517          	auipc	a0,0x4
    800043ce:	23e50513          	addi	a0,a0,574 # 80008608 <syscalls+0x1c0>
    800043d2:	ffffc097          	auipc	ra,0xffffc
    800043d6:	158080e7          	jalr	344(ra) # 8000052a <panic>

00000000800043da <iunlock>:
{
    800043da:	1101                	addi	sp,sp,-32
    800043dc:	ec06                	sd	ra,24(sp)
    800043de:	e822                	sd	s0,16(sp)
    800043e0:	e426                	sd	s1,8(sp)
    800043e2:	e04a                	sd	s2,0(sp)
    800043e4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800043e6:	c905                	beqz	a0,80004416 <iunlock+0x3c>
    800043e8:	84aa                	mv	s1,a0
    800043ea:	01050913          	addi	s2,a0,16
    800043ee:	854a                	mv	a0,s2
    800043f0:	00001097          	auipc	ra,0x1
    800043f4:	c90080e7          	jalr	-880(ra) # 80005080 <holdingsleep>
    800043f8:	cd19                	beqz	a0,80004416 <iunlock+0x3c>
    800043fa:	449c                	lw	a5,8(s1)
    800043fc:	00f05d63          	blez	a5,80004416 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004400:	854a                	mv	a0,s2
    80004402:	00001097          	auipc	ra,0x1
    80004406:	c3a080e7          	jalr	-966(ra) # 8000503c <releasesleep>
}
    8000440a:	60e2                	ld	ra,24(sp)
    8000440c:	6442                	ld	s0,16(sp)
    8000440e:	64a2                	ld	s1,8(sp)
    80004410:	6902                	ld	s2,0(sp)
    80004412:	6105                	addi	sp,sp,32
    80004414:	8082                	ret
    panic("iunlock");
    80004416:	00004517          	auipc	a0,0x4
    8000441a:	20250513          	addi	a0,a0,514 # 80008618 <syscalls+0x1d0>
    8000441e:	ffffc097          	auipc	ra,0xffffc
    80004422:	10c080e7          	jalr	268(ra) # 8000052a <panic>

0000000080004426 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004426:	7179                	addi	sp,sp,-48
    80004428:	f406                	sd	ra,40(sp)
    8000442a:	f022                	sd	s0,32(sp)
    8000442c:	ec26                	sd	s1,24(sp)
    8000442e:	e84a                	sd	s2,16(sp)
    80004430:	e44e                	sd	s3,8(sp)
    80004432:	e052                	sd	s4,0(sp)
    80004434:	1800                	addi	s0,sp,48
    80004436:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004438:	05050493          	addi	s1,a0,80
    8000443c:	08050913          	addi	s2,a0,128
    80004440:	a021                	j	80004448 <itrunc+0x22>
    80004442:	0491                	addi	s1,s1,4
    80004444:	01248d63          	beq	s1,s2,8000445e <itrunc+0x38>
    if(ip->addrs[i]){
    80004448:	408c                	lw	a1,0(s1)
    8000444a:	dde5                	beqz	a1,80004442 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000444c:	0009a503          	lw	a0,0(s3)
    80004450:	00000097          	auipc	ra,0x0
    80004454:	90a080e7          	jalr	-1782(ra) # 80003d5a <bfree>
      ip->addrs[i] = 0;
    80004458:	0004a023          	sw	zero,0(s1)
    8000445c:	b7dd                	j	80004442 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000445e:	0809a583          	lw	a1,128(s3)
    80004462:	e185                	bnez	a1,80004482 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004464:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004468:	854e                	mv	a0,s3
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	de4080e7          	jalr	-540(ra) # 8000424e <iupdate>
}
    80004472:	70a2                	ld	ra,40(sp)
    80004474:	7402                	ld	s0,32(sp)
    80004476:	64e2                	ld	s1,24(sp)
    80004478:	6942                	ld	s2,16(sp)
    8000447a:	69a2                	ld	s3,8(sp)
    8000447c:	6a02                	ld	s4,0(sp)
    8000447e:	6145                	addi	sp,sp,48
    80004480:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004482:	0009a503          	lw	a0,0(s3)
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	68e080e7          	jalr	1678(ra) # 80003b14 <bread>
    8000448e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004490:	05850493          	addi	s1,a0,88
    80004494:	45850913          	addi	s2,a0,1112
    80004498:	a021                	j	800044a0 <itrunc+0x7a>
    8000449a:	0491                	addi	s1,s1,4
    8000449c:	01248b63          	beq	s1,s2,800044b2 <itrunc+0x8c>
      if(a[j])
    800044a0:	408c                	lw	a1,0(s1)
    800044a2:	dde5                	beqz	a1,8000449a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800044a4:	0009a503          	lw	a0,0(s3)
    800044a8:	00000097          	auipc	ra,0x0
    800044ac:	8b2080e7          	jalr	-1870(ra) # 80003d5a <bfree>
    800044b0:	b7ed                	j	8000449a <itrunc+0x74>
    brelse(bp);
    800044b2:	8552                	mv	a0,s4
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	790080e7          	jalr	1936(ra) # 80003c44 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800044bc:	0809a583          	lw	a1,128(s3)
    800044c0:	0009a503          	lw	a0,0(s3)
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	896080e7          	jalr	-1898(ra) # 80003d5a <bfree>
    ip->addrs[NDIRECT] = 0;
    800044cc:	0809a023          	sw	zero,128(s3)
    800044d0:	bf51                	j	80004464 <itrunc+0x3e>

00000000800044d2 <iput>:
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	e04a                	sd	s2,0(sp)
    800044dc:	1000                	addi	s0,sp,32
    800044de:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800044e0:	00038517          	auipc	a0,0x38
    800044e4:	90050513          	addi	a0,a0,-1792 # 8003bde0 <itable>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	6da080e7          	jalr	1754(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044f0:	4498                	lw	a4,8(s1)
    800044f2:	4785                	li	a5,1
    800044f4:	02f70363          	beq	a4,a5,8000451a <iput+0x48>
  ip->ref--;
    800044f8:	449c                	lw	a5,8(s1)
    800044fa:	37fd                	addiw	a5,a5,-1
    800044fc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044fe:	00038517          	auipc	a0,0x38
    80004502:	8e250513          	addi	a0,a0,-1822 # 8003bde0 <itable>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	782080e7          	jalr	1922(ra) # 80000c88 <release>
}
    8000450e:	60e2                	ld	ra,24(sp)
    80004510:	6442                	ld	s0,16(sp)
    80004512:	64a2                	ld	s1,8(sp)
    80004514:	6902                	ld	s2,0(sp)
    80004516:	6105                	addi	sp,sp,32
    80004518:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000451a:	40bc                	lw	a5,64(s1)
    8000451c:	dff1                	beqz	a5,800044f8 <iput+0x26>
    8000451e:	04a49783          	lh	a5,74(s1)
    80004522:	fbf9                	bnez	a5,800044f8 <iput+0x26>
    acquiresleep(&ip->lock);
    80004524:	01048913          	addi	s2,s1,16
    80004528:	854a                	mv	a0,s2
    8000452a:	00001097          	auipc	ra,0x1
    8000452e:	abc080e7          	jalr	-1348(ra) # 80004fe6 <acquiresleep>
    release(&itable.lock);
    80004532:	00038517          	auipc	a0,0x38
    80004536:	8ae50513          	addi	a0,a0,-1874 # 8003bde0 <itable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	74e080e7          	jalr	1870(ra) # 80000c88 <release>
    itrunc(ip);
    80004542:	8526                	mv	a0,s1
    80004544:	00000097          	auipc	ra,0x0
    80004548:	ee2080e7          	jalr	-286(ra) # 80004426 <itrunc>
    ip->type = 0;
    8000454c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004550:	8526                	mv	a0,s1
    80004552:	00000097          	auipc	ra,0x0
    80004556:	cfc080e7          	jalr	-772(ra) # 8000424e <iupdate>
    ip->valid = 0;
    8000455a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000455e:	854a                	mv	a0,s2
    80004560:	00001097          	auipc	ra,0x1
    80004564:	adc080e7          	jalr	-1316(ra) # 8000503c <releasesleep>
    acquire(&itable.lock);
    80004568:	00038517          	auipc	a0,0x38
    8000456c:	87850513          	addi	a0,a0,-1928 # 8003bde0 <itable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	652080e7          	jalr	1618(ra) # 80000bc2 <acquire>
    80004578:	b741                	j	800044f8 <iput+0x26>

000000008000457a <iunlockput>:
{
    8000457a:	1101                	addi	sp,sp,-32
    8000457c:	ec06                	sd	ra,24(sp)
    8000457e:	e822                	sd	s0,16(sp)
    80004580:	e426                	sd	s1,8(sp)
    80004582:	1000                	addi	s0,sp,32
    80004584:	84aa                	mv	s1,a0
  iunlock(ip);
    80004586:	00000097          	auipc	ra,0x0
    8000458a:	e54080e7          	jalr	-428(ra) # 800043da <iunlock>
  iput(ip);
    8000458e:	8526                	mv	a0,s1
    80004590:	00000097          	auipc	ra,0x0
    80004594:	f42080e7          	jalr	-190(ra) # 800044d2 <iput>
}
    80004598:	60e2                	ld	ra,24(sp)
    8000459a:	6442                	ld	s0,16(sp)
    8000459c:	64a2                	ld	s1,8(sp)
    8000459e:	6105                	addi	sp,sp,32
    800045a0:	8082                	ret

00000000800045a2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800045a2:	1141                	addi	sp,sp,-16
    800045a4:	e422                	sd	s0,8(sp)
    800045a6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800045a8:	411c                	lw	a5,0(a0)
    800045aa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800045ac:	415c                	lw	a5,4(a0)
    800045ae:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800045b0:	04451783          	lh	a5,68(a0)
    800045b4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800045b8:	04a51783          	lh	a5,74(a0)
    800045bc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800045c0:	04c56783          	lwu	a5,76(a0)
    800045c4:	e99c                	sd	a5,16(a1)
}
    800045c6:	6422                	ld	s0,8(sp)
    800045c8:	0141                	addi	sp,sp,16
    800045ca:	8082                	ret

00000000800045cc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800045cc:	457c                	lw	a5,76(a0)
    800045ce:	0ed7e963          	bltu	a5,a3,800046c0 <readi+0xf4>
{
    800045d2:	7159                	addi	sp,sp,-112
    800045d4:	f486                	sd	ra,104(sp)
    800045d6:	f0a2                	sd	s0,96(sp)
    800045d8:	eca6                	sd	s1,88(sp)
    800045da:	e8ca                	sd	s2,80(sp)
    800045dc:	e4ce                	sd	s3,72(sp)
    800045de:	e0d2                	sd	s4,64(sp)
    800045e0:	fc56                	sd	s5,56(sp)
    800045e2:	f85a                	sd	s6,48(sp)
    800045e4:	f45e                	sd	s7,40(sp)
    800045e6:	f062                	sd	s8,32(sp)
    800045e8:	ec66                	sd	s9,24(sp)
    800045ea:	e86a                	sd	s10,16(sp)
    800045ec:	e46e                	sd	s11,8(sp)
    800045ee:	1880                	addi	s0,sp,112
    800045f0:	8baa                	mv	s7,a0
    800045f2:	8c2e                	mv	s8,a1
    800045f4:	8ab2                	mv	s5,a2
    800045f6:	84b6                	mv	s1,a3
    800045f8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800045fa:	9f35                	addw	a4,a4,a3
    return 0;
    800045fc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800045fe:	0ad76063          	bltu	a4,a3,8000469e <readi+0xd2>
  if(off + n > ip->size)
    80004602:	00e7f463          	bgeu	a5,a4,8000460a <readi+0x3e>
    n = ip->size - off;
    80004606:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000460a:	0a0b0963          	beqz	s6,800046bc <readi+0xf0>
    8000460e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004610:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004614:	5cfd                	li	s9,-1
    80004616:	a82d                	j	80004650 <readi+0x84>
    80004618:	020a1d93          	slli	s11,s4,0x20
    8000461c:	020ddd93          	srli	s11,s11,0x20
    80004620:	05890793          	addi	a5,s2,88
    80004624:	86ee                	mv	a3,s11
    80004626:	963e                	add	a2,a2,a5
    80004628:	85d6                	mv	a1,s5
    8000462a:	8562                	mv	a0,s8
    8000462c:	ffffe097          	auipc	ra,0xffffe
    80004630:	374080e7          	jalr	884(ra) # 800029a0 <either_copyout>
    80004634:	05950d63          	beq	a0,s9,8000468e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004638:	854a                	mv	a0,s2
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	60a080e7          	jalr	1546(ra) # 80003c44 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004642:	013a09bb          	addw	s3,s4,s3
    80004646:	009a04bb          	addw	s1,s4,s1
    8000464a:	9aee                	add	s5,s5,s11
    8000464c:	0569f763          	bgeu	s3,s6,8000469a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004650:	000ba903          	lw	s2,0(s7)
    80004654:	00a4d59b          	srliw	a1,s1,0xa
    80004658:	855e                	mv	a0,s7
    8000465a:	00000097          	auipc	ra,0x0
    8000465e:	8ae080e7          	jalr	-1874(ra) # 80003f08 <bmap>
    80004662:	0005059b          	sext.w	a1,a0
    80004666:	854a                	mv	a0,s2
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	4ac080e7          	jalr	1196(ra) # 80003b14 <bread>
    80004670:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004672:	3ff4f613          	andi	a2,s1,1023
    80004676:	40cd07bb          	subw	a5,s10,a2
    8000467a:	413b073b          	subw	a4,s6,s3
    8000467e:	8a3e                	mv	s4,a5
    80004680:	2781                	sext.w	a5,a5
    80004682:	0007069b          	sext.w	a3,a4
    80004686:	f8f6f9e3          	bgeu	a3,a5,80004618 <readi+0x4c>
    8000468a:	8a3a                	mv	s4,a4
    8000468c:	b771                	j	80004618 <readi+0x4c>
      brelse(bp);
    8000468e:	854a                	mv	a0,s2
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	5b4080e7          	jalr	1460(ra) # 80003c44 <brelse>
      tot = -1;
    80004698:	59fd                	li	s3,-1
  }
  return tot;
    8000469a:	0009851b          	sext.w	a0,s3
}
    8000469e:	70a6                	ld	ra,104(sp)
    800046a0:	7406                	ld	s0,96(sp)
    800046a2:	64e6                	ld	s1,88(sp)
    800046a4:	6946                	ld	s2,80(sp)
    800046a6:	69a6                	ld	s3,72(sp)
    800046a8:	6a06                	ld	s4,64(sp)
    800046aa:	7ae2                	ld	s5,56(sp)
    800046ac:	7b42                	ld	s6,48(sp)
    800046ae:	7ba2                	ld	s7,40(sp)
    800046b0:	7c02                	ld	s8,32(sp)
    800046b2:	6ce2                	ld	s9,24(sp)
    800046b4:	6d42                	ld	s10,16(sp)
    800046b6:	6da2                	ld	s11,8(sp)
    800046b8:	6165                	addi	sp,sp,112
    800046ba:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046bc:	89da                	mv	s3,s6
    800046be:	bff1                	j	8000469a <readi+0xce>
    return 0;
    800046c0:	4501                	li	a0,0
}
    800046c2:	8082                	ret

00000000800046c4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800046c4:	457c                	lw	a5,76(a0)
    800046c6:	10d7e863          	bltu	a5,a3,800047d6 <writei+0x112>
{
    800046ca:	7159                	addi	sp,sp,-112
    800046cc:	f486                	sd	ra,104(sp)
    800046ce:	f0a2                	sd	s0,96(sp)
    800046d0:	eca6                	sd	s1,88(sp)
    800046d2:	e8ca                	sd	s2,80(sp)
    800046d4:	e4ce                	sd	s3,72(sp)
    800046d6:	e0d2                	sd	s4,64(sp)
    800046d8:	fc56                	sd	s5,56(sp)
    800046da:	f85a                	sd	s6,48(sp)
    800046dc:	f45e                	sd	s7,40(sp)
    800046de:	f062                	sd	s8,32(sp)
    800046e0:	ec66                	sd	s9,24(sp)
    800046e2:	e86a                	sd	s10,16(sp)
    800046e4:	e46e                	sd	s11,8(sp)
    800046e6:	1880                	addi	s0,sp,112
    800046e8:	8b2a                	mv	s6,a0
    800046ea:	8c2e                	mv	s8,a1
    800046ec:	8ab2                	mv	s5,a2
    800046ee:	8936                	mv	s2,a3
    800046f0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800046f2:	00e687bb          	addw	a5,a3,a4
    800046f6:	0ed7e263          	bltu	a5,a3,800047da <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800046fa:	00043737          	lui	a4,0x43
    800046fe:	0ef76063          	bltu	a4,a5,800047de <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004702:	0c0b8863          	beqz	s7,800047d2 <writei+0x10e>
    80004706:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004708:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000470c:	5cfd                	li	s9,-1
    8000470e:	a091                	j	80004752 <writei+0x8e>
    80004710:	02099d93          	slli	s11,s3,0x20
    80004714:	020ddd93          	srli	s11,s11,0x20
    80004718:	05848793          	addi	a5,s1,88
    8000471c:	86ee                	mv	a3,s11
    8000471e:	8656                	mv	a2,s5
    80004720:	85e2                	mv	a1,s8
    80004722:	953e                	add	a0,a0,a5
    80004724:	ffffe097          	auipc	ra,0xffffe
    80004728:	2d4080e7          	jalr	724(ra) # 800029f8 <either_copyin>
    8000472c:	07950263          	beq	a0,s9,80004790 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004730:	8526                	mv	a0,s1
    80004732:	00000097          	auipc	ra,0x0
    80004736:	794080e7          	jalr	1940(ra) # 80004ec6 <log_write>
    brelse(bp);
    8000473a:	8526                	mv	a0,s1
    8000473c:	fffff097          	auipc	ra,0xfffff
    80004740:	508080e7          	jalr	1288(ra) # 80003c44 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004744:	01498a3b          	addw	s4,s3,s4
    80004748:	0129893b          	addw	s2,s3,s2
    8000474c:	9aee                	add	s5,s5,s11
    8000474e:	057a7663          	bgeu	s4,s7,8000479a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004752:	000b2483          	lw	s1,0(s6)
    80004756:	00a9559b          	srliw	a1,s2,0xa
    8000475a:	855a                	mv	a0,s6
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	7ac080e7          	jalr	1964(ra) # 80003f08 <bmap>
    80004764:	0005059b          	sext.w	a1,a0
    80004768:	8526                	mv	a0,s1
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	3aa080e7          	jalr	938(ra) # 80003b14 <bread>
    80004772:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004774:	3ff97513          	andi	a0,s2,1023
    80004778:	40ad07bb          	subw	a5,s10,a0
    8000477c:	414b873b          	subw	a4,s7,s4
    80004780:	89be                	mv	s3,a5
    80004782:	2781                	sext.w	a5,a5
    80004784:	0007069b          	sext.w	a3,a4
    80004788:	f8f6f4e3          	bgeu	a3,a5,80004710 <writei+0x4c>
    8000478c:	89ba                	mv	s3,a4
    8000478e:	b749                	j	80004710 <writei+0x4c>
      brelse(bp);
    80004790:	8526                	mv	a0,s1
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	4b2080e7          	jalr	1202(ra) # 80003c44 <brelse>
  }

  if(off > ip->size)
    8000479a:	04cb2783          	lw	a5,76(s6)
    8000479e:	0127f463          	bgeu	a5,s2,800047a6 <writei+0xe2>
    ip->size = off;
    800047a2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800047a6:	855a                	mv	a0,s6
    800047a8:	00000097          	auipc	ra,0x0
    800047ac:	aa6080e7          	jalr	-1370(ra) # 8000424e <iupdate>

  return tot;
    800047b0:	000a051b          	sext.w	a0,s4
}
    800047b4:	70a6                	ld	ra,104(sp)
    800047b6:	7406                	ld	s0,96(sp)
    800047b8:	64e6                	ld	s1,88(sp)
    800047ba:	6946                	ld	s2,80(sp)
    800047bc:	69a6                	ld	s3,72(sp)
    800047be:	6a06                	ld	s4,64(sp)
    800047c0:	7ae2                	ld	s5,56(sp)
    800047c2:	7b42                	ld	s6,48(sp)
    800047c4:	7ba2                	ld	s7,40(sp)
    800047c6:	7c02                	ld	s8,32(sp)
    800047c8:	6ce2                	ld	s9,24(sp)
    800047ca:	6d42                	ld	s10,16(sp)
    800047cc:	6da2                	ld	s11,8(sp)
    800047ce:	6165                	addi	sp,sp,112
    800047d0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800047d2:	8a5e                	mv	s4,s7
    800047d4:	bfc9                	j	800047a6 <writei+0xe2>
    return -1;
    800047d6:	557d                	li	a0,-1
}
    800047d8:	8082                	ret
    return -1;
    800047da:	557d                	li	a0,-1
    800047dc:	bfe1                	j	800047b4 <writei+0xf0>
    return -1;
    800047de:	557d                	li	a0,-1
    800047e0:	bfd1                	j	800047b4 <writei+0xf0>

00000000800047e2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800047e2:	1141                	addi	sp,sp,-16
    800047e4:	e406                	sd	ra,8(sp)
    800047e6:	e022                	sd	s0,0(sp)
    800047e8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800047ea:	4639                	li	a2,14
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	5ce080e7          	jalr	1486(ra) # 80000dba <strncmp>
}
    800047f4:	60a2                	ld	ra,8(sp)
    800047f6:	6402                	ld	s0,0(sp)
    800047f8:	0141                	addi	sp,sp,16
    800047fa:	8082                	ret

00000000800047fc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800047fc:	7139                	addi	sp,sp,-64
    800047fe:	fc06                	sd	ra,56(sp)
    80004800:	f822                	sd	s0,48(sp)
    80004802:	f426                	sd	s1,40(sp)
    80004804:	f04a                	sd	s2,32(sp)
    80004806:	ec4e                	sd	s3,24(sp)
    80004808:	e852                	sd	s4,16(sp)
    8000480a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000480c:	04451703          	lh	a4,68(a0)
    80004810:	4785                	li	a5,1
    80004812:	00f71a63          	bne	a4,a5,80004826 <dirlookup+0x2a>
    80004816:	892a                	mv	s2,a0
    80004818:	89ae                	mv	s3,a1
    8000481a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000481c:	457c                	lw	a5,76(a0)
    8000481e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004820:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004822:	e79d                	bnez	a5,80004850 <dirlookup+0x54>
    80004824:	a8a5                	j	8000489c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004826:	00004517          	auipc	a0,0x4
    8000482a:	dfa50513          	addi	a0,a0,-518 # 80008620 <syscalls+0x1d8>
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	cfc080e7          	jalr	-772(ra) # 8000052a <panic>
      panic("dirlookup read");
    80004836:	00004517          	auipc	a0,0x4
    8000483a:	e0250513          	addi	a0,a0,-510 # 80008638 <syscalls+0x1f0>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	cec080e7          	jalr	-788(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004846:	24c1                	addiw	s1,s1,16
    80004848:	04c92783          	lw	a5,76(s2)
    8000484c:	04f4f763          	bgeu	s1,a5,8000489a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004850:	4741                	li	a4,16
    80004852:	86a6                	mv	a3,s1
    80004854:	fc040613          	addi	a2,s0,-64
    80004858:	4581                	li	a1,0
    8000485a:	854a                	mv	a0,s2
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	d70080e7          	jalr	-656(ra) # 800045cc <readi>
    80004864:	47c1                	li	a5,16
    80004866:	fcf518e3          	bne	a0,a5,80004836 <dirlookup+0x3a>
    if(de.inum == 0)
    8000486a:	fc045783          	lhu	a5,-64(s0)
    8000486e:	dfe1                	beqz	a5,80004846 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004870:	fc240593          	addi	a1,s0,-62
    80004874:	854e                	mv	a0,s3
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	f6c080e7          	jalr	-148(ra) # 800047e2 <namecmp>
    8000487e:	f561                	bnez	a0,80004846 <dirlookup+0x4a>
      if(poff)
    80004880:	000a0463          	beqz	s4,80004888 <dirlookup+0x8c>
        *poff = off;
    80004884:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004888:	fc045583          	lhu	a1,-64(s0)
    8000488c:	00092503          	lw	a0,0(s2)
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	754080e7          	jalr	1876(ra) # 80003fe4 <iget>
    80004898:	a011                	j	8000489c <dirlookup+0xa0>
  return 0;
    8000489a:	4501                	li	a0,0
}
    8000489c:	70e2                	ld	ra,56(sp)
    8000489e:	7442                	ld	s0,48(sp)
    800048a0:	74a2                	ld	s1,40(sp)
    800048a2:	7902                	ld	s2,32(sp)
    800048a4:	69e2                	ld	s3,24(sp)
    800048a6:	6a42                	ld	s4,16(sp)
    800048a8:	6121                	addi	sp,sp,64
    800048aa:	8082                	ret

00000000800048ac <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800048ac:	711d                	addi	sp,sp,-96
    800048ae:	ec86                	sd	ra,88(sp)
    800048b0:	e8a2                	sd	s0,80(sp)
    800048b2:	e4a6                	sd	s1,72(sp)
    800048b4:	e0ca                	sd	s2,64(sp)
    800048b6:	fc4e                	sd	s3,56(sp)
    800048b8:	f852                	sd	s4,48(sp)
    800048ba:	f456                	sd	s5,40(sp)
    800048bc:	f05a                	sd	s6,32(sp)
    800048be:	ec5e                	sd	s7,24(sp)
    800048c0:	e862                	sd	s8,16(sp)
    800048c2:	e466                	sd	s9,8(sp)
    800048c4:	1080                	addi	s0,sp,96
    800048c6:	84aa                	mv	s1,a0
    800048c8:	8aae                	mv	s5,a1
    800048ca:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800048cc:	00054703          	lbu	a4,0(a0)
    800048d0:	02f00793          	li	a5,47
    800048d4:	02f70363          	beq	a4,a5,800048fa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800048d8:	ffffd097          	auipc	ra,0xffffd
    800048dc:	11e080e7          	jalr	286(ra) # 800019f6 <myproc>
    800048e0:	26053503          	ld	a0,608(a0)
    800048e4:	00000097          	auipc	ra,0x0
    800048e8:	9f6080e7          	jalr	-1546(ra) # 800042da <idup>
    800048ec:	89aa                	mv	s3,a0
  while(*path == '/')
    800048ee:	02f00913          	li	s2,47
  len = path - s;
    800048f2:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800048f4:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800048f6:	4b85                	li	s7,1
    800048f8:	a865                	j	800049b0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800048fa:	4585                	li	a1,1
    800048fc:	4505                	li	a0,1
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	6e6080e7          	jalr	1766(ra) # 80003fe4 <iget>
    80004906:	89aa                	mv	s3,a0
    80004908:	b7dd                	j	800048ee <namex+0x42>
      iunlockput(ip);
    8000490a:	854e                	mv	a0,s3
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	c6e080e7          	jalr	-914(ra) # 8000457a <iunlockput>
      return 0;
    80004914:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004916:	854e                	mv	a0,s3
    80004918:	60e6                	ld	ra,88(sp)
    8000491a:	6446                	ld	s0,80(sp)
    8000491c:	64a6                	ld	s1,72(sp)
    8000491e:	6906                	ld	s2,64(sp)
    80004920:	79e2                	ld	s3,56(sp)
    80004922:	7a42                	ld	s4,48(sp)
    80004924:	7aa2                	ld	s5,40(sp)
    80004926:	7b02                	ld	s6,32(sp)
    80004928:	6be2                	ld	s7,24(sp)
    8000492a:	6c42                	ld	s8,16(sp)
    8000492c:	6ca2                	ld	s9,8(sp)
    8000492e:	6125                	addi	sp,sp,96
    80004930:	8082                	ret
      iunlock(ip);
    80004932:	854e                	mv	a0,s3
    80004934:	00000097          	auipc	ra,0x0
    80004938:	aa6080e7          	jalr	-1370(ra) # 800043da <iunlock>
      return ip;
    8000493c:	bfe9                	j	80004916 <namex+0x6a>
      iunlockput(ip);
    8000493e:	854e                	mv	a0,s3
    80004940:	00000097          	auipc	ra,0x0
    80004944:	c3a080e7          	jalr	-966(ra) # 8000457a <iunlockput>
      return 0;
    80004948:	89e6                	mv	s3,s9
    8000494a:	b7f1                	j	80004916 <namex+0x6a>
  len = path - s;
    8000494c:	40b48633          	sub	a2,s1,a1
    80004950:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004954:	099c5463          	bge	s8,s9,800049dc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004958:	4639                	li	a2,14
    8000495a:	8552                	mv	a0,s4
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	3e2080e7          	jalr	994(ra) # 80000d3e <memmove>
  while(*path == '/')
    80004964:	0004c783          	lbu	a5,0(s1)
    80004968:	01279763          	bne	a5,s2,80004976 <namex+0xca>
    path++;
    8000496c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000496e:	0004c783          	lbu	a5,0(s1)
    80004972:	ff278de3          	beq	a5,s2,8000496c <namex+0xc0>
    ilock(ip);
    80004976:	854e                	mv	a0,s3
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	9a0080e7          	jalr	-1632(ra) # 80004318 <ilock>
    if(ip->type != T_DIR){
    80004980:	04499783          	lh	a5,68(s3)
    80004984:	f97793e3          	bne	a5,s7,8000490a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004988:	000a8563          	beqz	s5,80004992 <namex+0xe6>
    8000498c:	0004c783          	lbu	a5,0(s1)
    80004990:	d3cd                	beqz	a5,80004932 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004992:	865a                	mv	a2,s6
    80004994:	85d2                	mv	a1,s4
    80004996:	854e                	mv	a0,s3
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	e64080e7          	jalr	-412(ra) # 800047fc <dirlookup>
    800049a0:	8caa                	mv	s9,a0
    800049a2:	dd51                	beqz	a0,8000493e <namex+0x92>
    iunlockput(ip);
    800049a4:	854e                	mv	a0,s3
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	bd4080e7          	jalr	-1068(ra) # 8000457a <iunlockput>
    ip = next;
    800049ae:	89e6                	mv	s3,s9
  while(*path == '/')
    800049b0:	0004c783          	lbu	a5,0(s1)
    800049b4:	05279763          	bne	a5,s2,80004a02 <namex+0x156>
    path++;
    800049b8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800049ba:	0004c783          	lbu	a5,0(s1)
    800049be:	ff278de3          	beq	a5,s2,800049b8 <namex+0x10c>
  if(*path == 0)
    800049c2:	c79d                	beqz	a5,800049f0 <namex+0x144>
    path++;
    800049c4:	85a6                	mv	a1,s1
  len = path - s;
    800049c6:	8cda                	mv	s9,s6
    800049c8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800049ca:	01278963          	beq	a5,s2,800049dc <namex+0x130>
    800049ce:	dfbd                	beqz	a5,8000494c <namex+0xa0>
    path++;
    800049d0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800049d2:	0004c783          	lbu	a5,0(s1)
    800049d6:	ff279ce3          	bne	a5,s2,800049ce <namex+0x122>
    800049da:	bf8d                	j	8000494c <namex+0xa0>
    memmove(name, s, len);
    800049dc:	2601                	sext.w	a2,a2
    800049de:	8552                	mv	a0,s4
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	35e080e7          	jalr	862(ra) # 80000d3e <memmove>
    name[len] = 0;
    800049e8:	9cd2                	add	s9,s9,s4
    800049ea:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800049ee:	bf9d                	j	80004964 <namex+0xb8>
  if(nameiparent){
    800049f0:	f20a83e3          	beqz	s5,80004916 <namex+0x6a>
    iput(ip);
    800049f4:	854e                	mv	a0,s3
    800049f6:	00000097          	auipc	ra,0x0
    800049fa:	adc080e7          	jalr	-1316(ra) # 800044d2 <iput>
    return 0;
    800049fe:	4981                	li	s3,0
    80004a00:	bf19                	j	80004916 <namex+0x6a>
  if(*path == 0)
    80004a02:	d7fd                	beqz	a5,800049f0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004a04:	0004c783          	lbu	a5,0(s1)
    80004a08:	85a6                	mv	a1,s1
    80004a0a:	b7d1                	j	800049ce <namex+0x122>

0000000080004a0c <dirlink>:
{
    80004a0c:	7139                	addi	sp,sp,-64
    80004a0e:	fc06                	sd	ra,56(sp)
    80004a10:	f822                	sd	s0,48(sp)
    80004a12:	f426                	sd	s1,40(sp)
    80004a14:	f04a                	sd	s2,32(sp)
    80004a16:	ec4e                	sd	s3,24(sp)
    80004a18:	e852                	sd	s4,16(sp)
    80004a1a:	0080                	addi	s0,sp,64
    80004a1c:	892a                	mv	s2,a0
    80004a1e:	8a2e                	mv	s4,a1
    80004a20:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a22:	4601                	li	a2,0
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	dd8080e7          	jalr	-552(ra) # 800047fc <dirlookup>
    80004a2c:	e93d                	bnez	a0,80004aa2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a2e:	04c92483          	lw	s1,76(s2)
    80004a32:	c49d                	beqz	s1,80004a60 <dirlink+0x54>
    80004a34:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a36:	4741                	li	a4,16
    80004a38:	86a6                	mv	a3,s1
    80004a3a:	fc040613          	addi	a2,s0,-64
    80004a3e:	4581                	li	a1,0
    80004a40:	854a                	mv	a0,s2
    80004a42:	00000097          	auipc	ra,0x0
    80004a46:	b8a080e7          	jalr	-1142(ra) # 800045cc <readi>
    80004a4a:	47c1                	li	a5,16
    80004a4c:	06f51163          	bne	a0,a5,80004aae <dirlink+0xa2>
    if(de.inum == 0)
    80004a50:	fc045783          	lhu	a5,-64(s0)
    80004a54:	c791                	beqz	a5,80004a60 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a56:	24c1                	addiw	s1,s1,16
    80004a58:	04c92783          	lw	a5,76(s2)
    80004a5c:	fcf4ede3          	bltu	s1,a5,80004a36 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a60:	4639                	li	a2,14
    80004a62:	85d2                	mv	a1,s4
    80004a64:	fc240513          	addi	a0,s0,-62
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	38e080e7          	jalr	910(ra) # 80000df6 <strncpy>
  de.inum = inum;
    80004a70:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a74:	4741                	li	a4,16
    80004a76:	86a6                	mv	a3,s1
    80004a78:	fc040613          	addi	a2,s0,-64
    80004a7c:	4581                	li	a1,0
    80004a7e:	854a                	mv	a0,s2
    80004a80:	00000097          	auipc	ra,0x0
    80004a84:	c44080e7          	jalr	-956(ra) # 800046c4 <writei>
    80004a88:	872a                	mv	a4,a0
    80004a8a:	47c1                	li	a5,16
  return 0;
    80004a8c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a8e:	02f71863          	bne	a4,a5,80004abe <dirlink+0xb2>
}
    80004a92:	70e2                	ld	ra,56(sp)
    80004a94:	7442                	ld	s0,48(sp)
    80004a96:	74a2                	ld	s1,40(sp)
    80004a98:	7902                	ld	s2,32(sp)
    80004a9a:	69e2                	ld	s3,24(sp)
    80004a9c:	6a42                	ld	s4,16(sp)
    80004a9e:	6121                	addi	sp,sp,64
    80004aa0:	8082                	ret
    iput(ip);
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	a30080e7          	jalr	-1488(ra) # 800044d2 <iput>
    return -1;
    80004aaa:	557d                	li	a0,-1
    80004aac:	b7dd                	j	80004a92 <dirlink+0x86>
      panic("dirlink read");
    80004aae:	00004517          	auipc	a0,0x4
    80004ab2:	b9a50513          	addi	a0,a0,-1126 # 80008648 <syscalls+0x200>
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	a74080e7          	jalr	-1420(ra) # 8000052a <panic>
    panic("dirlink");
    80004abe:	00004517          	auipc	a0,0x4
    80004ac2:	c9a50513          	addi	a0,a0,-870 # 80008758 <syscalls+0x310>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	a64080e7          	jalr	-1436(ra) # 8000052a <panic>

0000000080004ace <namei>:

struct inode*
namei(char *path)
{
    80004ace:	1101                	addi	sp,sp,-32
    80004ad0:	ec06                	sd	ra,24(sp)
    80004ad2:	e822                	sd	s0,16(sp)
    80004ad4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004ad6:	fe040613          	addi	a2,s0,-32
    80004ada:	4581                	li	a1,0
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	dd0080e7          	jalr	-560(ra) # 800048ac <namex>
}
    80004ae4:	60e2                	ld	ra,24(sp)
    80004ae6:	6442                	ld	s0,16(sp)
    80004ae8:	6105                	addi	sp,sp,32
    80004aea:	8082                	ret

0000000080004aec <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004aec:	1141                	addi	sp,sp,-16
    80004aee:	e406                	sd	ra,8(sp)
    80004af0:	e022                	sd	s0,0(sp)
    80004af2:	0800                	addi	s0,sp,16
    80004af4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004af6:	4585                	li	a1,1
    80004af8:	00000097          	auipc	ra,0x0
    80004afc:	db4080e7          	jalr	-588(ra) # 800048ac <namex>
}
    80004b00:	60a2                	ld	ra,8(sp)
    80004b02:	6402                	ld	s0,0(sp)
    80004b04:	0141                	addi	sp,sp,16
    80004b06:	8082                	ret

0000000080004b08 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b08:	1101                	addi	sp,sp,-32
    80004b0a:	ec06                	sd	ra,24(sp)
    80004b0c:	e822                	sd	s0,16(sp)
    80004b0e:	e426                	sd	s1,8(sp)
    80004b10:	e04a                	sd	s2,0(sp)
    80004b12:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b14:	00039917          	auipc	s2,0x39
    80004b18:	d7490913          	addi	s2,s2,-652 # 8003d888 <log>
    80004b1c:	01892583          	lw	a1,24(s2)
    80004b20:	02892503          	lw	a0,40(s2)
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	ff0080e7          	jalr	-16(ra) # 80003b14 <bread>
    80004b2c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b2e:	02c92683          	lw	a3,44(s2)
    80004b32:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b34:	02d05863          	blez	a3,80004b64 <write_head+0x5c>
    80004b38:	00039797          	auipc	a5,0x39
    80004b3c:	d8078793          	addi	a5,a5,-640 # 8003d8b8 <log+0x30>
    80004b40:	05c50713          	addi	a4,a0,92
    80004b44:	36fd                	addiw	a3,a3,-1
    80004b46:	02069613          	slli	a2,a3,0x20
    80004b4a:	01e65693          	srli	a3,a2,0x1e
    80004b4e:	00039617          	auipc	a2,0x39
    80004b52:	d6e60613          	addi	a2,a2,-658 # 8003d8bc <log+0x34>
    80004b56:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b58:	4390                	lw	a2,0(a5)
    80004b5a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b5c:	0791                	addi	a5,a5,4
    80004b5e:	0711                	addi	a4,a4,4
    80004b60:	fed79ce3          	bne	a5,a3,80004b58 <write_head+0x50>
  }
  bwrite(buf);
    80004b64:	8526                	mv	a0,s1
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	0a0080e7          	jalr	160(ra) # 80003c06 <bwrite>
  brelse(buf);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	fffff097          	auipc	ra,0xfffff
    80004b74:	0d4080e7          	jalr	212(ra) # 80003c44 <brelse>
}
    80004b78:	60e2                	ld	ra,24(sp)
    80004b7a:	6442                	ld	s0,16(sp)
    80004b7c:	64a2                	ld	s1,8(sp)
    80004b7e:	6902                	ld	s2,0(sp)
    80004b80:	6105                	addi	sp,sp,32
    80004b82:	8082                	ret

0000000080004b84 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b84:	00039797          	auipc	a5,0x39
    80004b88:	d307a783          	lw	a5,-720(a5) # 8003d8b4 <log+0x2c>
    80004b8c:	0af05d63          	blez	a5,80004c46 <install_trans+0xc2>
{
    80004b90:	7139                	addi	sp,sp,-64
    80004b92:	fc06                	sd	ra,56(sp)
    80004b94:	f822                	sd	s0,48(sp)
    80004b96:	f426                	sd	s1,40(sp)
    80004b98:	f04a                	sd	s2,32(sp)
    80004b9a:	ec4e                	sd	s3,24(sp)
    80004b9c:	e852                	sd	s4,16(sp)
    80004b9e:	e456                	sd	s5,8(sp)
    80004ba0:	e05a                	sd	s6,0(sp)
    80004ba2:	0080                	addi	s0,sp,64
    80004ba4:	8b2a                	mv	s6,a0
    80004ba6:	00039a97          	auipc	s5,0x39
    80004baa:	d12a8a93          	addi	s5,s5,-750 # 8003d8b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bae:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bb0:	00039997          	auipc	s3,0x39
    80004bb4:	cd898993          	addi	s3,s3,-808 # 8003d888 <log>
    80004bb8:	a00d                	j	80004bda <install_trans+0x56>
    brelse(lbuf);
    80004bba:	854a                	mv	a0,s2
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	088080e7          	jalr	136(ra) # 80003c44 <brelse>
    brelse(dbuf);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	fffff097          	auipc	ra,0xfffff
    80004bca:	07e080e7          	jalr	126(ra) # 80003c44 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bce:	2a05                	addiw	s4,s4,1
    80004bd0:	0a91                	addi	s5,s5,4
    80004bd2:	02c9a783          	lw	a5,44(s3)
    80004bd6:	04fa5e63          	bge	s4,a5,80004c32 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bda:	0189a583          	lw	a1,24(s3)
    80004bde:	014585bb          	addw	a1,a1,s4
    80004be2:	2585                	addiw	a1,a1,1
    80004be4:	0289a503          	lw	a0,40(s3)
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	f2c080e7          	jalr	-212(ra) # 80003b14 <bread>
    80004bf0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004bf2:	000aa583          	lw	a1,0(s5)
    80004bf6:	0289a503          	lw	a0,40(s3)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	f1a080e7          	jalr	-230(ra) # 80003b14 <bread>
    80004c02:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c04:	40000613          	li	a2,1024
    80004c08:	05890593          	addi	a1,s2,88
    80004c0c:	05850513          	addi	a0,a0,88
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	12e080e7          	jalr	302(ra) # 80000d3e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c18:	8526                	mv	a0,s1
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	fec080e7          	jalr	-20(ra) # 80003c06 <bwrite>
    if(recovering == 0)
    80004c22:	f80b1ce3          	bnez	s6,80004bba <install_trans+0x36>
      bunpin(dbuf);
    80004c26:	8526                	mv	a0,s1
    80004c28:	fffff097          	auipc	ra,0xfffff
    80004c2c:	0f6080e7          	jalr	246(ra) # 80003d1e <bunpin>
    80004c30:	b769                	j	80004bba <install_trans+0x36>
}
    80004c32:	70e2                	ld	ra,56(sp)
    80004c34:	7442                	ld	s0,48(sp)
    80004c36:	74a2                	ld	s1,40(sp)
    80004c38:	7902                	ld	s2,32(sp)
    80004c3a:	69e2                	ld	s3,24(sp)
    80004c3c:	6a42                	ld	s4,16(sp)
    80004c3e:	6aa2                	ld	s5,8(sp)
    80004c40:	6b02                	ld	s6,0(sp)
    80004c42:	6121                	addi	sp,sp,64
    80004c44:	8082                	ret
    80004c46:	8082                	ret

0000000080004c48 <initlog>:
{
    80004c48:	7179                	addi	sp,sp,-48
    80004c4a:	f406                	sd	ra,40(sp)
    80004c4c:	f022                	sd	s0,32(sp)
    80004c4e:	ec26                	sd	s1,24(sp)
    80004c50:	e84a                	sd	s2,16(sp)
    80004c52:	e44e                	sd	s3,8(sp)
    80004c54:	1800                	addi	s0,sp,48
    80004c56:	892a                	mv	s2,a0
    80004c58:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c5a:	00039497          	auipc	s1,0x39
    80004c5e:	c2e48493          	addi	s1,s1,-978 # 8003d888 <log>
    80004c62:	00004597          	auipc	a1,0x4
    80004c66:	9f658593          	addi	a1,a1,-1546 # 80008658 <syscalls+0x210>
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	ec6080e7          	jalr	-314(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004c74:	0149a583          	lw	a1,20(s3)
    80004c78:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c7a:	0109a783          	lw	a5,16(s3)
    80004c7e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c80:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c84:	854a                	mv	a0,s2
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	e8e080e7          	jalr	-370(ra) # 80003b14 <bread>
  log.lh.n = lh->n;
    80004c8e:	4d34                	lw	a3,88(a0)
    80004c90:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c92:	02d05663          	blez	a3,80004cbe <initlog+0x76>
    80004c96:	05c50793          	addi	a5,a0,92
    80004c9a:	00039717          	auipc	a4,0x39
    80004c9e:	c1e70713          	addi	a4,a4,-994 # 8003d8b8 <log+0x30>
    80004ca2:	36fd                	addiw	a3,a3,-1
    80004ca4:	02069613          	slli	a2,a3,0x20
    80004ca8:	01e65693          	srli	a3,a2,0x1e
    80004cac:	06050613          	addi	a2,a0,96
    80004cb0:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004cb2:	4390                	lw	a2,0(a5)
    80004cb4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004cb6:	0791                	addi	a5,a5,4
    80004cb8:	0711                	addi	a4,a4,4
    80004cba:	fed79ce3          	bne	a5,a3,80004cb2 <initlog+0x6a>
  brelse(buf);
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	f86080e7          	jalr	-122(ra) # 80003c44 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004cc6:	4505                	li	a0,1
    80004cc8:	00000097          	auipc	ra,0x0
    80004ccc:	ebc080e7          	jalr	-324(ra) # 80004b84 <install_trans>
  log.lh.n = 0;
    80004cd0:	00039797          	auipc	a5,0x39
    80004cd4:	be07a223          	sw	zero,-1052(a5) # 8003d8b4 <log+0x2c>
  write_head(); // clear the log
    80004cd8:	00000097          	auipc	ra,0x0
    80004cdc:	e30080e7          	jalr	-464(ra) # 80004b08 <write_head>
}
    80004ce0:	70a2                	ld	ra,40(sp)
    80004ce2:	7402                	ld	s0,32(sp)
    80004ce4:	64e2                	ld	s1,24(sp)
    80004ce6:	6942                	ld	s2,16(sp)
    80004ce8:	69a2                	ld	s3,8(sp)
    80004cea:	6145                	addi	sp,sp,48
    80004cec:	8082                	ret

0000000080004cee <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004cee:	1101                	addi	sp,sp,-32
    80004cf0:	ec06                	sd	ra,24(sp)
    80004cf2:	e822                	sd	s0,16(sp)
    80004cf4:	e426                	sd	s1,8(sp)
    80004cf6:	e04a                	sd	s2,0(sp)
    80004cf8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004cfa:	00039517          	auipc	a0,0x39
    80004cfe:	b8e50513          	addi	a0,a0,-1138 # 8003d888 <log>
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	ec0080e7          	jalr	-320(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004d0a:	00039497          	auipc	s1,0x39
    80004d0e:	b7e48493          	addi	s1,s1,-1154 # 8003d888 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d12:	4979                	li	s2,30
    80004d14:	a039                	j	80004d22 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d16:	85a6                	mv	a1,s1
    80004d18:	8526                	mv	a0,s1
    80004d1a:	ffffe097          	auipc	ra,0xffffe
    80004d1e:	982080e7          	jalr	-1662(ra) # 8000269c <sleep>
    if(log.committing){
    80004d22:	50dc                	lw	a5,36(s1)
    80004d24:	fbed                	bnez	a5,80004d16 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d26:	509c                	lw	a5,32(s1)
    80004d28:	0017871b          	addiw	a4,a5,1
    80004d2c:	0007069b          	sext.w	a3,a4
    80004d30:	0027179b          	slliw	a5,a4,0x2
    80004d34:	9fb9                	addw	a5,a5,a4
    80004d36:	0017979b          	slliw	a5,a5,0x1
    80004d3a:	54d8                	lw	a4,44(s1)
    80004d3c:	9fb9                	addw	a5,a5,a4
    80004d3e:	00f95963          	bge	s2,a5,80004d50 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d42:	85a6                	mv	a1,s1
    80004d44:	8526                	mv	a0,s1
    80004d46:	ffffe097          	auipc	ra,0xffffe
    80004d4a:	956080e7          	jalr	-1706(ra) # 8000269c <sleep>
    80004d4e:	bfd1                	j	80004d22 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d50:	00039517          	auipc	a0,0x39
    80004d54:	b3850513          	addi	a0,a0,-1224 # 8003d888 <log>
    80004d58:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d5a:	ffffc097          	auipc	ra,0xffffc
    80004d5e:	f2e080e7          	jalr	-210(ra) # 80000c88 <release>
      break;
    }
  }
}
    80004d62:	60e2                	ld	ra,24(sp)
    80004d64:	6442                	ld	s0,16(sp)
    80004d66:	64a2                	ld	s1,8(sp)
    80004d68:	6902                	ld	s2,0(sp)
    80004d6a:	6105                	addi	sp,sp,32
    80004d6c:	8082                	ret

0000000080004d6e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d6e:	7139                	addi	sp,sp,-64
    80004d70:	fc06                	sd	ra,56(sp)
    80004d72:	f822                	sd	s0,48(sp)
    80004d74:	f426                	sd	s1,40(sp)
    80004d76:	f04a                	sd	s2,32(sp)
    80004d78:	ec4e                	sd	s3,24(sp)
    80004d7a:	e852                	sd	s4,16(sp)
    80004d7c:	e456                	sd	s5,8(sp)
    80004d7e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d80:	00039497          	auipc	s1,0x39
    80004d84:	b0848493          	addi	s1,s1,-1272 # 8003d888 <log>
    80004d88:	8526                	mv	a0,s1
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	e38080e7          	jalr	-456(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004d92:	509c                	lw	a5,32(s1)
    80004d94:	37fd                	addiw	a5,a5,-1
    80004d96:	0007891b          	sext.w	s2,a5
    80004d9a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d9c:	50dc                	lw	a5,36(s1)
    80004d9e:	e7b9                	bnez	a5,80004dec <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004da0:	04091e63          	bnez	s2,80004dfc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004da4:	00039497          	auipc	s1,0x39
    80004da8:	ae448493          	addi	s1,s1,-1308 # 8003d888 <log>
    80004dac:	4785                	li	a5,1
    80004dae:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004db0:	8526                	mv	a0,s1
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	ed6080e7          	jalr	-298(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004dba:	54dc                	lw	a5,44(s1)
    80004dbc:	06f04763          	bgtz	a5,80004e2a <end_op+0xbc>
    acquire(&log.lock);
    80004dc0:	00039497          	auipc	s1,0x39
    80004dc4:	ac848493          	addi	s1,s1,-1336 # 8003d888 <log>
    80004dc8:	8526                	mv	a0,s1
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	df8080e7          	jalr	-520(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004dd2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004dd6:	8526                	mv	a0,s1
    80004dd8:	ffffe097          	auipc	ra,0xffffe
    80004ddc:	a4e080e7          	jalr	-1458(ra) # 80002826 <wakeup>
    release(&log.lock);
    80004de0:	8526                	mv	a0,s1
    80004de2:	ffffc097          	auipc	ra,0xffffc
    80004de6:	ea6080e7          	jalr	-346(ra) # 80000c88 <release>
}
    80004dea:	a03d                	j	80004e18 <end_op+0xaa>
    panic("log.committing");
    80004dec:	00004517          	auipc	a0,0x4
    80004df0:	87450513          	addi	a0,a0,-1932 # 80008660 <syscalls+0x218>
    80004df4:	ffffb097          	auipc	ra,0xffffb
    80004df8:	736080e7          	jalr	1846(ra) # 8000052a <panic>
    wakeup(&log);
    80004dfc:	00039497          	auipc	s1,0x39
    80004e00:	a8c48493          	addi	s1,s1,-1396 # 8003d888 <log>
    80004e04:	8526                	mv	a0,s1
    80004e06:	ffffe097          	auipc	ra,0xffffe
    80004e0a:	a20080e7          	jalr	-1504(ra) # 80002826 <wakeup>
  release(&log.lock);
    80004e0e:	8526                	mv	a0,s1
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	e78080e7          	jalr	-392(ra) # 80000c88 <release>
}
    80004e18:	70e2                	ld	ra,56(sp)
    80004e1a:	7442                	ld	s0,48(sp)
    80004e1c:	74a2                	ld	s1,40(sp)
    80004e1e:	7902                	ld	s2,32(sp)
    80004e20:	69e2                	ld	s3,24(sp)
    80004e22:	6a42                	ld	s4,16(sp)
    80004e24:	6aa2                	ld	s5,8(sp)
    80004e26:	6121                	addi	sp,sp,64
    80004e28:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e2a:	00039a97          	auipc	s5,0x39
    80004e2e:	a8ea8a93          	addi	s5,s5,-1394 # 8003d8b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e32:	00039a17          	auipc	s4,0x39
    80004e36:	a56a0a13          	addi	s4,s4,-1450 # 8003d888 <log>
    80004e3a:	018a2583          	lw	a1,24(s4)
    80004e3e:	012585bb          	addw	a1,a1,s2
    80004e42:	2585                	addiw	a1,a1,1
    80004e44:	028a2503          	lw	a0,40(s4)
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	ccc080e7          	jalr	-820(ra) # 80003b14 <bread>
    80004e50:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e52:	000aa583          	lw	a1,0(s5)
    80004e56:	028a2503          	lw	a0,40(s4)
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	cba080e7          	jalr	-838(ra) # 80003b14 <bread>
    80004e62:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e64:	40000613          	li	a2,1024
    80004e68:	05850593          	addi	a1,a0,88
    80004e6c:	05848513          	addi	a0,s1,88
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	ece080e7          	jalr	-306(ra) # 80000d3e <memmove>
    bwrite(to);  // write the log
    80004e78:	8526                	mv	a0,s1
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	d8c080e7          	jalr	-628(ra) # 80003c06 <bwrite>
    brelse(from);
    80004e82:	854e                	mv	a0,s3
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	dc0080e7          	jalr	-576(ra) # 80003c44 <brelse>
    brelse(to);
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	db6080e7          	jalr	-586(ra) # 80003c44 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e96:	2905                	addiw	s2,s2,1
    80004e98:	0a91                	addi	s5,s5,4
    80004e9a:	02ca2783          	lw	a5,44(s4)
    80004e9e:	f8f94ee3          	blt	s2,a5,80004e3a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ea2:	00000097          	auipc	ra,0x0
    80004ea6:	c66080e7          	jalr	-922(ra) # 80004b08 <write_head>
    install_trans(0); // Now install writes to home locations
    80004eaa:	4501                	li	a0,0
    80004eac:	00000097          	auipc	ra,0x0
    80004eb0:	cd8080e7          	jalr	-808(ra) # 80004b84 <install_trans>
    log.lh.n = 0;
    80004eb4:	00039797          	auipc	a5,0x39
    80004eb8:	a007a023          	sw	zero,-1536(a5) # 8003d8b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ebc:	00000097          	auipc	ra,0x0
    80004ec0:	c4c080e7          	jalr	-948(ra) # 80004b08 <write_head>
    80004ec4:	bdf5                	j	80004dc0 <end_op+0x52>

0000000080004ec6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ec6:	1101                	addi	sp,sp,-32
    80004ec8:	ec06                	sd	ra,24(sp)
    80004eca:	e822                	sd	s0,16(sp)
    80004ecc:	e426                	sd	s1,8(sp)
    80004ece:	e04a                	sd	s2,0(sp)
    80004ed0:	1000                	addi	s0,sp,32
    80004ed2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ed4:	00039917          	auipc	s2,0x39
    80004ed8:	9b490913          	addi	s2,s2,-1612 # 8003d888 <log>
    80004edc:	854a                	mv	a0,s2
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	ce4080e7          	jalr	-796(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ee6:	02c92603          	lw	a2,44(s2)
    80004eea:	47f5                	li	a5,29
    80004eec:	06c7c563          	blt	a5,a2,80004f56 <log_write+0x90>
    80004ef0:	00039797          	auipc	a5,0x39
    80004ef4:	9b47a783          	lw	a5,-1612(a5) # 8003d8a4 <log+0x1c>
    80004ef8:	37fd                	addiw	a5,a5,-1
    80004efa:	04f65e63          	bge	a2,a5,80004f56 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004efe:	00039797          	auipc	a5,0x39
    80004f02:	9aa7a783          	lw	a5,-1622(a5) # 8003d8a8 <log+0x20>
    80004f06:	06f05063          	blez	a5,80004f66 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f0a:	4781                	li	a5,0
    80004f0c:	06c05563          	blez	a2,80004f76 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004f10:	44cc                	lw	a1,12(s1)
    80004f12:	00039717          	auipc	a4,0x39
    80004f16:	9a670713          	addi	a4,a4,-1626 # 8003d8b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f1a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004f1c:	4314                	lw	a3,0(a4)
    80004f1e:	04b68c63          	beq	a3,a1,80004f76 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f22:	2785                	addiw	a5,a5,1
    80004f24:	0711                	addi	a4,a4,4
    80004f26:	fef61be3          	bne	a2,a5,80004f1c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f2a:	0621                	addi	a2,a2,8
    80004f2c:	060a                	slli	a2,a2,0x2
    80004f2e:	00039797          	auipc	a5,0x39
    80004f32:	95a78793          	addi	a5,a5,-1702 # 8003d888 <log>
    80004f36:	963e                	add	a2,a2,a5
    80004f38:	44dc                	lw	a5,12(s1)
    80004f3a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	da4080e7          	jalr	-604(ra) # 80003ce2 <bpin>
    log.lh.n++;
    80004f46:	00039717          	auipc	a4,0x39
    80004f4a:	94270713          	addi	a4,a4,-1726 # 8003d888 <log>
    80004f4e:	575c                	lw	a5,44(a4)
    80004f50:	2785                	addiw	a5,a5,1
    80004f52:	d75c                	sw	a5,44(a4)
    80004f54:	a835                	j	80004f90 <log_write+0xca>
    panic("too big a transaction");
    80004f56:	00003517          	auipc	a0,0x3
    80004f5a:	71a50513          	addi	a0,a0,1818 # 80008670 <syscalls+0x228>
    80004f5e:	ffffb097          	auipc	ra,0xffffb
    80004f62:	5cc080e7          	jalr	1484(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004f66:	00003517          	auipc	a0,0x3
    80004f6a:	72250513          	addi	a0,a0,1826 # 80008688 <syscalls+0x240>
    80004f6e:	ffffb097          	auipc	ra,0xffffb
    80004f72:	5bc080e7          	jalr	1468(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004f76:	00878713          	addi	a4,a5,8
    80004f7a:	00271693          	slli	a3,a4,0x2
    80004f7e:	00039717          	auipc	a4,0x39
    80004f82:	90a70713          	addi	a4,a4,-1782 # 8003d888 <log>
    80004f86:	9736                	add	a4,a4,a3
    80004f88:	44d4                	lw	a3,12(s1)
    80004f8a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f8c:	faf608e3          	beq	a2,a5,80004f3c <log_write+0x76>
  }
  release(&log.lock);
    80004f90:	00039517          	auipc	a0,0x39
    80004f94:	8f850513          	addi	a0,a0,-1800 # 8003d888 <log>
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	cf0080e7          	jalr	-784(ra) # 80000c88 <release>
}
    80004fa0:	60e2                	ld	ra,24(sp)
    80004fa2:	6442                	ld	s0,16(sp)
    80004fa4:	64a2                	ld	s1,8(sp)
    80004fa6:	6902                	ld	s2,0(sp)
    80004fa8:	6105                	addi	sp,sp,32
    80004faa:	8082                	ret

0000000080004fac <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004fac:	1101                	addi	sp,sp,-32
    80004fae:	ec06                	sd	ra,24(sp)
    80004fb0:	e822                	sd	s0,16(sp)
    80004fb2:	e426                	sd	s1,8(sp)
    80004fb4:	e04a                	sd	s2,0(sp)
    80004fb6:	1000                	addi	s0,sp,32
    80004fb8:	84aa                	mv	s1,a0
    80004fba:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004fbc:	00003597          	auipc	a1,0x3
    80004fc0:	6ec58593          	addi	a1,a1,1772 # 800086a8 <syscalls+0x260>
    80004fc4:	0521                	addi	a0,a0,8
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	b6c080e7          	jalr	-1172(ra) # 80000b32 <initlock>
  lk->name = name;
    80004fce:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004fd2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fd6:	0204a423          	sw	zero,40(s1)
}
    80004fda:	60e2                	ld	ra,24(sp)
    80004fdc:	6442                	ld	s0,16(sp)
    80004fde:	64a2                	ld	s1,8(sp)
    80004fe0:	6902                	ld	s2,0(sp)
    80004fe2:	6105                	addi	sp,sp,32
    80004fe4:	8082                	ret

0000000080004fe6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004fe6:	1101                	addi	sp,sp,-32
    80004fe8:	ec06                	sd	ra,24(sp)
    80004fea:	e822                	sd	s0,16(sp)
    80004fec:	e426                	sd	s1,8(sp)
    80004fee:	e04a                	sd	s2,0(sp)
    80004ff0:	1000                	addi	s0,sp,32
    80004ff2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ff4:	00850913          	addi	s2,a0,8
    80004ff8:	854a                	mv	a0,s2
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	bc8080e7          	jalr	-1080(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80005002:	409c                	lw	a5,0(s1)
    80005004:	cb89                	beqz	a5,80005016 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005006:	85ca                	mv	a1,s2
    80005008:	8526                	mv	a0,s1
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	692080e7          	jalr	1682(ra) # 8000269c <sleep>
  while (lk->locked) {
    80005012:	409c                	lw	a5,0(s1)
    80005014:	fbed                	bnez	a5,80005006 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005016:	4785                	li	a5,1
    80005018:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	9dc080e7          	jalr	-1572(ra) # 800019f6 <myproc>
    80005022:	515c                	lw	a5,36(a0)
    80005024:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005026:	854a                	mv	a0,s2
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	c60080e7          	jalr	-928(ra) # 80000c88 <release>
}
    80005030:	60e2                	ld	ra,24(sp)
    80005032:	6442                	ld	s0,16(sp)
    80005034:	64a2                	ld	s1,8(sp)
    80005036:	6902                	ld	s2,0(sp)
    80005038:	6105                	addi	sp,sp,32
    8000503a:	8082                	ret

000000008000503c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000503c:	1101                	addi	sp,sp,-32
    8000503e:	ec06                	sd	ra,24(sp)
    80005040:	e822                	sd	s0,16(sp)
    80005042:	e426                	sd	s1,8(sp)
    80005044:	e04a                	sd	s2,0(sp)
    80005046:	1000                	addi	s0,sp,32
    80005048:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000504a:	00850913          	addi	s2,a0,8
    8000504e:	854a                	mv	a0,s2
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	b72080e7          	jalr	-1166(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80005058:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000505c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005060:	8526                	mv	a0,s1
    80005062:	ffffd097          	auipc	ra,0xffffd
    80005066:	7c4080e7          	jalr	1988(ra) # 80002826 <wakeup>
  release(&lk->lk);
    8000506a:	854a                	mv	a0,s2
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	c1c080e7          	jalr	-996(ra) # 80000c88 <release>
}
    80005074:	60e2                	ld	ra,24(sp)
    80005076:	6442                	ld	s0,16(sp)
    80005078:	64a2                	ld	s1,8(sp)
    8000507a:	6902                	ld	s2,0(sp)
    8000507c:	6105                	addi	sp,sp,32
    8000507e:	8082                	ret

0000000080005080 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005080:	7179                	addi	sp,sp,-48
    80005082:	f406                	sd	ra,40(sp)
    80005084:	f022                	sd	s0,32(sp)
    80005086:	ec26                	sd	s1,24(sp)
    80005088:	e84a                	sd	s2,16(sp)
    8000508a:	e44e                	sd	s3,8(sp)
    8000508c:	1800                	addi	s0,sp,48
    8000508e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005090:	00850913          	addi	s2,a0,8
    80005094:	854a                	mv	a0,s2
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	b2c080e7          	jalr	-1236(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000509e:	409c                	lw	a5,0(s1)
    800050a0:	ef99                	bnez	a5,800050be <holdingsleep+0x3e>
    800050a2:	4481                	li	s1,0
  release(&lk->lk);
    800050a4:	854a                	mv	a0,s2
    800050a6:	ffffc097          	auipc	ra,0xffffc
    800050aa:	be2080e7          	jalr	-1054(ra) # 80000c88 <release>
  return r;
}
    800050ae:	8526                	mv	a0,s1
    800050b0:	70a2                	ld	ra,40(sp)
    800050b2:	7402                	ld	s0,32(sp)
    800050b4:	64e2                	ld	s1,24(sp)
    800050b6:	6942                	ld	s2,16(sp)
    800050b8:	69a2                	ld	s3,8(sp)
    800050ba:	6145                	addi	sp,sp,48
    800050bc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800050be:	0284a983          	lw	s3,40(s1)
    800050c2:	ffffd097          	auipc	ra,0xffffd
    800050c6:	934080e7          	jalr	-1740(ra) # 800019f6 <myproc>
    800050ca:	5144                	lw	s1,36(a0)
    800050cc:	413484b3          	sub	s1,s1,s3
    800050d0:	0014b493          	seqz	s1,s1
    800050d4:	bfc1                	j	800050a4 <holdingsleep+0x24>

00000000800050d6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800050d6:	1141                	addi	sp,sp,-16
    800050d8:	e406                	sd	ra,8(sp)
    800050da:	e022                	sd	s0,0(sp)
    800050dc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800050de:	00003597          	auipc	a1,0x3
    800050e2:	5da58593          	addi	a1,a1,1498 # 800086b8 <syscalls+0x270>
    800050e6:	00039517          	auipc	a0,0x39
    800050ea:	8ea50513          	addi	a0,a0,-1814 # 8003d9d0 <ftable>
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	a44080e7          	jalr	-1468(ra) # 80000b32 <initlock>
}
    800050f6:	60a2                	ld	ra,8(sp)
    800050f8:	6402                	ld	s0,0(sp)
    800050fa:	0141                	addi	sp,sp,16
    800050fc:	8082                	ret

00000000800050fe <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800050fe:	1101                	addi	sp,sp,-32
    80005100:	ec06                	sd	ra,24(sp)
    80005102:	e822                	sd	s0,16(sp)
    80005104:	e426                	sd	s1,8(sp)
    80005106:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005108:	00039517          	auipc	a0,0x39
    8000510c:	8c850513          	addi	a0,a0,-1848 # 8003d9d0 <ftable>
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	ab2080e7          	jalr	-1358(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005118:	00039497          	auipc	s1,0x39
    8000511c:	8d048493          	addi	s1,s1,-1840 # 8003d9e8 <ftable+0x18>
    80005120:	0003a717          	auipc	a4,0x3a
    80005124:	86870713          	addi	a4,a4,-1944 # 8003e988 <ftable+0xfb8>
    if(f->ref == 0){
    80005128:	40dc                	lw	a5,4(s1)
    8000512a:	cf99                	beqz	a5,80005148 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000512c:	02848493          	addi	s1,s1,40
    80005130:	fee49ce3          	bne	s1,a4,80005128 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005134:	00039517          	auipc	a0,0x39
    80005138:	89c50513          	addi	a0,a0,-1892 # 8003d9d0 <ftable>
    8000513c:	ffffc097          	auipc	ra,0xffffc
    80005140:	b4c080e7          	jalr	-1204(ra) # 80000c88 <release>
  return 0;
    80005144:	4481                	li	s1,0
    80005146:	a819                	j	8000515c <filealloc+0x5e>
      f->ref = 1;
    80005148:	4785                	li	a5,1
    8000514a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000514c:	00039517          	auipc	a0,0x39
    80005150:	88450513          	addi	a0,a0,-1916 # 8003d9d0 <ftable>
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	b34080e7          	jalr	-1228(ra) # 80000c88 <release>
}
    8000515c:	8526                	mv	a0,s1
    8000515e:	60e2                	ld	ra,24(sp)
    80005160:	6442                	ld	s0,16(sp)
    80005162:	64a2                	ld	s1,8(sp)
    80005164:	6105                	addi	sp,sp,32
    80005166:	8082                	ret

0000000080005168 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005168:	1101                	addi	sp,sp,-32
    8000516a:	ec06                	sd	ra,24(sp)
    8000516c:	e822                	sd	s0,16(sp)
    8000516e:	e426                	sd	s1,8(sp)
    80005170:	1000                	addi	s0,sp,32
    80005172:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005174:	00039517          	auipc	a0,0x39
    80005178:	85c50513          	addi	a0,a0,-1956 # 8003d9d0 <ftable>
    8000517c:	ffffc097          	auipc	ra,0xffffc
    80005180:	a46080e7          	jalr	-1466(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005184:	40dc                	lw	a5,4(s1)
    80005186:	02f05263          	blez	a5,800051aa <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000518a:	2785                	addiw	a5,a5,1
    8000518c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000518e:	00039517          	auipc	a0,0x39
    80005192:	84250513          	addi	a0,a0,-1982 # 8003d9d0 <ftable>
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	af2080e7          	jalr	-1294(ra) # 80000c88 <release>
  return f;
}
    8000519e:	8526                	mv	a0,s1
    800051a0:	60e2                	ld	ra,24(sp)
    800051a2:	6442                	ld	s0,16(sp)
    800051a4:	64a2                	ld	s1,8(sp)
    800051a6:	6105                	addi	sp,sp,32
    800051a8:	8082                	ret
    panic("filedup");
    800051aa:	00003517          	auipc	a0,0x3
    800051ae:	51650513          	addi	a0,a0,1302 # 800086c0 <syscalls+0x278>
    800051b2:	ffffb097          	auipc	ra,0xffffb
    800051b6:	378080e7          	jalr	888(ra) # 8000052a <panic>

00000000800051ba <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800051ba:	7139                	addi	sp,sp,-64
    800051bc:	fc06                	sd	ra,56(sp)
    800051be:	f822                	sd	s0,48(sp)
    800051c0:	f426                	sd	s1,40(sp)
    800051c2:	f04a                	sd	s2,32(sp)
    800051c4:	ec4e                	sd	s3,24(sp)
    800051c6:	e852                	sd	s4,16(sp)
    800051c8:	e456                	sd	s5,8(sp)
    800051ca:	0080                	addi	s0,sp,64
    800051cc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800051ce:	00039517          	auipc	a0,0x39
    800051d2:	80250513          	addi	a0,a0,-2046 # 8003d9d0 <ftable>
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	9ec080e7          	jalr	-1556(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800051de:	40dc                	lw	a5,4(s1)
    800051e0:	06f05163          	blez	a5,80005242 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800051e4:	37fd                	addiw	a5,a5,-1
    800051e6:	0007871b          	sext.w	a4,a5
    800051ea:	c0dc                	sw	a5,4(s1)
    800051ec:	06e04363          	bgtz	a4,80005252 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800051f0:	0004a903          	lw	s2,0(s1)
    800051f4:	0094ca83          	lbu	s5,9(s1)
    800051f8:	0104ba03          	ld	s4,16(s1)
    800051fc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005200:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005204:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005208:	00038517          	auipc	a0,0x38
    8000520c:	7c850513          	addi	a0,a0,1992 # 8003d9d0 <ftable>
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	a78080e7          	jalr	-1416(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    80005218:	4785                	li	a5,1
    8000521a:	04f90d63          	beq	s2,a5,80005274 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000521e:	3979                	addiw	s2,s2,-2
    80005220:	4785                	li	a5,1
    80005222:	0527e063          	bltu	a5,s2,80005262 <fileclose+0xa8>
    begin_op();
    80005226:	00000097          	auipc	ra,0x0
    8000522a:	ac8080e7          	jalr	-1336(ra) # 80004cee <begin_op>
    iput(ff.ip);
    8000522e:	854e                	mv	a0,s3
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	2a2080e7          	jalr	674(ra) # 800044d2 <iput>
    end_op();
    80005238:	00000097          	auipc	ra,0x0
    8000523c:	b36080e7          	jalr	-1226(ra) # 80004d6e <end_op>
    80005240:	a00d                	j	80005262 <fileclose+0xa8>
    panic("fileclose");
    80005242:	00003517          	auipc	a0,0x3
    80005246:	48650513          	addi	a0,a0,1158 # 800086c8 <syscalls+0x280>
    8000524a:	ffffb097          	auipc	ra,0xffffb
    8000524e:	2e0080e7          	jalr	736(ra) # 8000052a <panic>
    release(&ftable.lock);
    80005252:	00038517          	auipc	a0,0x38
    80005256:	77e50513          	addi	a0,a0,1918 # 8003d9d0 <ftable>
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	a2e080e7          	jalr	-1490(ra) # 80000c88 <release>
  }
}
    80005262:	70e2                	ld	ra,56(sp)
    80005264:	7442                	ld	s0,48(sp)
    80005266:	74a2                	ld	s1,40(sp)
    80005268:	7902                	ld	s2,32(sp)
    8000526a:	69e2                	ld	s3,24(sp)
    8000526c:	6a42                	ld	s4,16(sp)
    8000526e:	6aa2                	ld	s5,8(sp)
    80005270:	6121                	addi	sp,sp,64
    80005272:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005274:	85d6                	mv	a1,s5
    80005276:	8552                	mv	a0,s4
    80005278:	00000097          	auipc	ra,0x0
    8000527c:	34c080e7          	jalr	844(ra) # 800055c4 <pipeclose>
    80005280:	b7cd                	j	80005262 <fileclose+0xa8>

0000000080005282 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005282:	715d                	addi	sp,sp,-80
    80005284:	e486                	sd	ra,72(sp)
    80005286:	e0a2                	sd	s0,64(sp)
    80005288:	fc26                	sd	s1,56(sp)
    8000528a:	f84a                	sd	s2,48(sp)
    8000528c:	f44e                	sd	s3,40(sp)
    8000528e:	0880                	addi	s0,sp,80
    80005290:	84aa                	mv	s1,a0
    80005292:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	762080e7          	jalr	1890(ra) # 800019f6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000529c:	409c                	lw	a5,0(s1)
    8000529e:	37f9                	addiw	a5,a5,-2
    800052a0:	4705                	li	a4,1
    800052a2:	04f76763          	bltu	a4,a5,800052f0 <filestat+0x6e>
    800052a6:	892a                	mv	s2,a0
    ilock(f->ip);
    800052a8:	6c88                	ld	a0,24(s1)
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	06e080e7          	jalr	110(ra) # 80004318 <ilock>
    stati(f->ip, &st);
    800052b2:	fb840593          	addi	a1,s0,-72
    800052b6:	6c88                	ld	a0,24(s1)
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	2ea080e7          	jalr	746(ra) # 800045a2 <stati>
    iunlock(f->ip);
    800052c0:	6c88                	ld	a0,24(s1)
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	118080e7          	jalr	280(ra) # 800043da <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800052ca:	46e1                	li	a3,24
    800052cc:	fb840613          	addi	a2,s0,-72
    800052d0:	85ce                	mv	a1,s3
    800052d2:	1d893503          	ld	a0,472(s2)
    800052d6:	ffffc097          	auipc	ra,0xffffc
    800052da:	38c080e7          	jalr	908(ra) # 80001662 <copyout>
    800052de:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800052e2:	60a6                	ld	ra,72(sp)
    800052e4:	6406                	ld	s0,64(sp)
    800052e6:	74e2                	ld	s1,56(sp)
    800052e8:	7942                	ld	s2,48(sp)
    800052ea:	79a2                	ld	s3,40(sp)
    800052ec:	6161                	addi	sp,sp,80
    800052ee:	8082                	ret
  return -1;
    800052f0:	557d                	li	a0,-1
    800052f2:	bfc5                	j	800052e2 <filestat+0x60>

00000000800052f4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800052f4:	7179                	addi	sp,sp,-48
    800052f6:	f406                	sd	ra,40(sp)
    800052f8:	f022                	sd	s0,32(sp)
    800052fa:	ec26                	sd	s1,24(sp)
    800052fc:	e84a                	sd	s2,16(sp)
    800052fe:	e44e                	sd	s3,8(sp)
    80005300:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005302:	00854783          	lbu	a5,8(a0)
    80005306:	c3d5                	beqz	a5,800053aa <fileread+0xb6>
    80005308:	84aa                	mv	s1,a0
    8000530a:	89ae                	mv	s3,a1
    8000530c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000530e:	411c                	lw	a5,0(a0)
    80005310:	4705                	li	a4,1
    80005312:	04e78963          	beq	a5,a4,80005364 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005316:	470d                	li	a4,3
    80005318:	04e78d63          	beq	a5,a4,80005372 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000531c:	4709                	li	a4,2
    8000531e:	06e79e63          	bne	a5,a4,8000539a <fileread+0xa6>
    ilock(f->ip);
    80005322:	6d08                	ld	a0,24(a0)
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	ff4080e7          	jalr	-12(ra) # 80004318 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000532c:	874a                	mv	a4,s2
    8000532e:	5094                	lw	a3,32(s1)
    80005330:	864e                	mv	a2,s3
    80005332:	4585                	li	a1,1
    80005334:	6c88                	ld	a0,24(s1)
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	296080e7          	jalr	662(ra) # 800045cc <readi>
    8000533e:	892a                	mv	s2,a0
    80005340:	00a05563          	blez	a0,8000534a <fileread+0x56>
      f->off += r;
    80005344:	509c                	lw	a5,32(s1)
    80005346:	9fa9                	addw	a5,a5,a0
    80005348:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000534a:	6c88                	ld	a0,24(s1)
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	08e080e7          	jalr	142(ra) # 800043da <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005354:	854a                	mv	a0,s2
    80005356:	70a2                	ld	ra,40(sp)
    80005358:	7402                	ld	s0,32(sp)
    8000535a:	64e2                	ld	s1,24(sp)
    8000535c:	6942                	ld	s2,16(sp)
    8000535e:	69a2                	ld	s3,8(sp)
    80005360:	6145                	addi	sp,sp,48
    80005362:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005364:	6908                	ld	a0,16(a0)
    80005366:	00000097          	auipc	ra,0x0
    8000536a:	3c0080e7          	jalr	960(ra) # 80005726 <piperead>
    8000536e:	892a                	mv	s2,a0
    80005370:	b7d5                	j	80005354 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005372:	02451783          	lh	a5,36(a0)
    80005376:	03079693          	slli	a3,a5,0x30
    8000537a:	92c1                	srli	a3,a3,0x30
    8000537c:	4725                	li	a4,9
    8000537e:	02d76863          	bltu	a4,a3,800053ae <fileread+0xba>
    80005382:	0792                	slli	a5,a5,0x4
    80005384:	00038717          	auipc	a4,0x38
    80005388:	5ac70713          	addi	a4,a4,1452 # 8003d930 <devsw>
    8000538c:	97ba                	add	a5,a5,a4
    8000538e:	639c                	ld	a5,0(a5)
    80005390:	c38d                	beqz	a5,800053b2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005392:	4505                	li	a0,1
    80005394:	9782                	jalr	a5
    80005396:	892a                	mv	s2,a0
    80005398:	bf75                	j	80005354 <fileread+0x60>
    panic("fileread");
    8000539a:	00003517          	auipc	a0,0x3
    8000539e:	33e50513          	addi	a0,a0,830 # 800086d8 <syscalls+0x290>
    800053a2:	ffffb097          	auipc	ra,0xffffb
    800053a6:	188080e7          	jalr	392(ra) # 8000052a <panic>
    return -1;
    800053aa:	597d                	li	s2,-1
    800053ac:	b765                	j	80005354 <fileread+0x60>
      return -1;
    800053ae:	597d                	li	s2,-1
    800053b0:	b755                	j	80005354 <fileread+0x60>
    800053b2:	597d                	li	s2,-1
    800053b4:	b745                	j	80005354 <fileread+0x60>

00000000800053b6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800053b6:	715d                	addi	sp,sp,-80
    800053b8:	e486                	sd	ra,72(sp)
    800053ba:	e0a2                	sd	s0,64(sp)
    800053bc:	fc26                	sd	s1,56(sp)
    800053be:	f84a                	sd	s2,48(sp)
    800053c0:	f44e                	sd	s3,40(sp)
    800053c2:	f052                	sd	s4,32(sp)
    800053c4:	ec56                	sd	s5,24(sp)
    800053c6:	e85a                	sd	s6,16(sp)
    800053c8:	e45e                	sd	s7,8(sp)
    800053ca:	e062                	sd	s8,0(sp)
    800053cc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800053ce:	00954783          	lbu	a5,9(a0)
    800053d2:	10078663          	beqz	a5,800054de <filewrite+0x128>
    800053d6:	892a                	mv	s2,a0
    800053d8:	8aae                	mv	s5,a1
    800053da:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800053dc:	411c                	lw	a5,0(a0)
    800053de:	4705                	li	a4,1
    800053e0:	02e78263          	beq	a5,a4,80005404 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053e4:	470d                	li	a4,3
    800053e6:	02e78663          	beq	a5,a4,80005412 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800053ea:	4709                	li	a4,2
    800053ec:	0ee79163          	bne	a5,a4,800054ce <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800053f0:	0ac05d63          	blez	a2,800054aa <filewrite+0xf4>
    int i = 0;
    800053f4:	4981                	li	s3,0
    800053f6:	6b05                	lui	s6,0x1
    800053f8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800053fc:	6b85                	lui	s7,0x1
    800053fe:	c00b8b9b          	addiw	s7,s7,-1024
    80005402:	a861                	j	8000549a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005404:	6908                	ld	a0,16(a0)
    80005406:	00000097          	auipc	ra,0x0
    8000540a:	22e080e7          	jalr	558(ra) # 80005634 <pipewrite>
    8000540e:	8a2a                	mv	s4,a0
    80005410:	a045                	j	800054b0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005412:	02451783          	lh	a5,36(a0)
    80005416:	03079693          	slli	a3,a5,0x30
    8000541a:	92c1                	srli	a3,a3,0x30
    8000541c:	4725                	li	a4,9
    8000541e:	0cd76263          	bltu	a4,a3,800054e2 <filewrite+0x12c>
    80005422:	0792                	slli	a5,a5,0x4
    80005424:	00038717          	auipc	a4,0x38
    80005428:	50c70713          	addi	a4,a4,1292 # 8003d930 <devsw>
    8000542c:	97ba                	add	a5,a5,a4
    8000542e:	679c                	ld	a5,8(a5)
    80005430:	cbdd                	beqz	a5,800054e6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005432:	4505                	li	a0,1
    80005434:	9782                	jalr	a5
    80005436:	8a2a                	mv	s4,a0
    80005438:	a8a5                	j	800054b0 <filewrite+0xfa>
    8000543a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000543e:	00000097          	auipc	ra,0x0
    80005442:	8b0080e7          	jalr	-1872(ra) # 80004cee <begin_op>
      ilock(f->ip);
    80005446:	01893503          	ld	a0,24(s2)
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	ece080e7          	jalr	-306(ra) # 80004318 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005452:	8762                	mv	a4,s8
    80005454:	02092683          	lw	a3,32(s2)
    80005458:	01598633          	add	a2,s3,s5
    8000545c:	4585                	li	a1,1
    8000545e:	01893503          	ld	a0,24(s2)
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	262080e7          	jalr	610(ra) # 800046c4 <writei>
    8000546a:	84aa                	mv	s1,a0
    8000546c:	00a05763          	blez	a0,8000547a <filewrite+0xc4>
        f->off += r;
    80005470:	02092783          	lw	a5,32(s2)
    80005474:	9fa9                	addw	a5,a5,a0
    80005476:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000547a:	01893503          	ld	a0,24(s2)
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	f5c080e7          	jalr	-164(ra) # 800043da <iunlock>
      end_op();
    80005486:	00000097          	auipc	ra,0x0
    8000548a:	8e8080e7          	jalr	-1816(ra) # 80004d6e <end_op>

      if(r != n1){
    8000548e:	009c1f63          	bne	s8,s1,800054ac <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005492:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005496:	0149db63          	bge	s3,s4,800054ac <filewrite+0xf6>
      int n1 = n - i;
    8000549a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000549e:	84be                	mv	s1,a5
    800054a0:	2781                	sext.w	a5,a5
    800054a2:	f8fb5ce3          	bge	s6,a5,8000543a <filewrite+0x84>
    800054a6:	84de                	mv	s1,s7
    800054a8:	bf49                	j	8000543a <filewrite+0x84>
    int i = 0;
    800054aa:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800054ac:	013a1f63          	bne	s4,s3,800054ca <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800054b0:	8552                	mv	a0,s4
    800054b2:	60a6                	ld	ra,72(sp)
    800054b4:	6406                	ld	s0,64(sp)
    800054b6:	74e2                	ld	s1,56(sp)
    800054b8:	7942                	ld	s2,48(sp)
    800054ba:	79a2                	ld	s3,40(sp)
    800054bc:	7a02                	ld	s4,32(sp)
    800054be:	6ae2                	ld	s5,24(sp)
    800054c0:	6b42                	ld	s6,16(sp)
    800054c2:	6ba2                	ld	s7,8(sp)
    800054c4:	6c02                	ld	s8,0(sp)
    800054c6:	6161                	addi	sp,sp,80
    800054c8:	8082                	ret
    ret = (i == n ? n : -1);
    800054ca:	5a7d                	li	s4,-1
    800054cc:	b7d5                	j	800054b0 <filewrite+0xfa>
    panic("filewrite");
    800054ce:	00003517          	auipc	a0,0x3
    800054d2:	21a50513          	addi	a0,a0,538 # 800086e8 <syscalls+0x2a0>
    800054d6:	ffffb097          	auipc	ra,0xffffb
    800054da:	054080e7          	jalr	84(ra) # 8000052a <panic>
    return -1;
    800054de:	5a7d                	li	s4,-1
    800054e0:	bfc1                	j	800054b0 <filewrite+0xfa>
      return -1;
    800054e2:	5a7d                	li	s4,-1
    800054e4:	b7f1                	j	800054b0 <filewrite+0xfa>
    800054e6:	5a7d                	li	s4,-1
    800054e8:	b7e1                	j	800054b0 <filewrite+0xfa>

00000000800054ea <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800054ea:	7179                	addi	sp,sp,-48
    800054ec:	f406                	sd	ra,40(sp)
    800054ee:	f022                	sd	s0,32(sp)
    800054f0:	ec26                	sd	s1,24(sp)
    800054f2:	e84a                	sd	s2,16(sp)
    800054f4:	e44e                	sd	s3,8(sp)
    800054f6:	e052                	sd	s4,0(sp)
    800054f8:	1800                	addi	s0,sp,48
    800054fa:	84aa                	mv	s1,a0
    800054fc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800054fe:	0005b023          	sd	zero,0(a1)
    80005502:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005506:	00000097          	auipc	ra,0x0
    8000550a:	bf8080e7          	jalr	-1032(ra) # 800050fe <filealloc>
    8000550e:	e088                	sd	a0,0(s1)
    80005510:	c551                	beqz	a0,8000559c <pipealloc+0xb2>
    80005512:	00000097          	auipc	ra,0x0
    80005516:	bec080e7          	jalr	-1044(ra) # 800050fe <filealloc>
    8000551a:	00aa3023          	sd	a0,0(s4)
    8000551e:	c92d                	beqz	a0,80005590 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005520:	ffffb097          	auipc	ra,0xffffb
    80005524:	5b2080e7          	jalr	1458(ra) # 80000ad2 <kalloc>
    80005528:	892a                	mv	s2,a0
    8000552a:	c125                	beqz	a0,8000558a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000552c:	4985                	li	s3,1
    8000552e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005532:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005536:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000553a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000553e:	00003597          	auipc	a1,0x3
    80005542:	1ba58593          	addi	a1,a1,442 # 800086f8 <syscalls+0x2b0>
    80005546:	ffffb097          	auipc	ra,0xffffb
    8000554a:	5ec080e7          	jalr	1516(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    8000554e:	609c                	ld	a5,0(s1)
    80005550:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005554:	609c                	ld	a5,0(s1)
    80005556:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000555a:	609c                	ld	a5,0(s1)
    8000555c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005560:	609c                	ld	a5,0(s1)
    80005562:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005566:	000a3783          	ld	a5,0(s4)
    8000556a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000556e:	000a3783          	ld	a5,0(s4)
    80005572:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005576:	000a3783          	ld	a5,0(s4)
    8000557a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000557e:	000a3783          	ld	a5,0(s4)
    80005582:	0127b823          	sd	s2,16(a5)
  return 0;
    80005586:	4501                	li	a0,0
    80005588:	a025                	j	800055b0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000558a:	6088                	ld	a0,0(s1)
    8000558c:	e501                	bnez	a0,80005594 <pipealloc+0xaa>
    8000558e:	a039                	j	8000559c <pipealloc+0xb2>
    80005590:	6088                	ld	a0,0(s1)
    80005592:	c51d                	beqz	a0,800055c0 <pipealloc+0xd6>
    fileclose(*f0);
    80005594:	00000097          	auipc	ra,0x0
    80005598:	c26080e7          	jalr	-986(ra) # 800051ba <fileclose>
  if(*f1)
    8000559c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800055a0:	557d                	li	a0,-1
  if(*f1)
    800055a2:	c799                	beqz	a5,800055b0 <pipealloc+0xc6>
    fileclose(*f1);
    800055a4:	853e                	mv	a0,a5
    800055a6:	00000097          	auipc	ra,0x0
    800055aa:	c14080e7          	jalr	-1004(ra) # 800051ba <fileclose>
  return -1;
    800055ae:	557d                	li	a0,-1
}
    800055b0:	70a2                	ld	ra,40(sp)
    800055b2:	7402                	ld	s0,32(sp)
    800055b4:	64e2                	ld	s1,24(sp)
    800055b6:	6942                	ld	s2,16(sp)
    800055b8:	69a2                	ld	s3,8(sp)
    800055ba:	6a02                	ld	s4,0(sp)
    800055bc:	6145                	addi	sp,sp,48
    800055be:	8082                	ret
  return -1;
    800055c0:	557d                	li	a0,-1
    800055c2:	b7fd                	j	800055b0 <pipealloc+0xc6>

00000000800055c4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800055c4:	1101                	addi	sp,sp,-32
    800055c6:	ec06                	sd	ra,24(sp)
    800055c8:	e822                	sd	s0,16(sp)
    800055ca:	e426                	sd	s1,8(sp)
    800055cc:	e04a                	sd	s2,0(sp)
    800055ce:	1000                	addi	s0,sp,32
    800055d0:	84aa                	mv	s1,a0
    800055d2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800055d4:	ffffb097          	auipc	ra,0xffffb
    800055d8:	5ee080e7          	jalr	1518(ra) # 80000bc2 <acquire>
  if(writable){
    800055dc:	02090d63          	beqz	s2,80005616 <pipeclose+0x52>
    pi->writeopen = 0;
    800055e0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800055e4:	21848513          	addi	a0,s1,536
    800055e8:	ffffd097          	auipc	ra,0xffffd
    800055ec:	23e080e7          	jalr	574(ra) # 80002826 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800055f0:	2204b783          	ld	a5,544(s1)
    800055f4:	eb95                	bnez	a5,80005628 <pipeclose+0x64>
    release(&pi->lock);
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffb097          	auipc	ra,0xffffb
    800055fc:	690080e7          	jalr	1680(ra) # 80000c88 <release>
    kfree((char*)pi);
    80005600:	8526                	mv	a0,s1
    80005602:	ffffb097          	auipc	ra,0xffffb
    80005606:	3d4080e7          	jalr	980(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    8000560a:	60e2                	ld	ra,24(sp)
    8000560c:	6442                	ld	s0,16(sp)
    8000560e:	64a2                	ld	s1,8(sp)
    80005610:	6902                	ld	s2,0(sp)
    80005612:	6105                	addi	sp,sp,32
    80005614:	8082                	ret
    pi->readopen = 0;
    80005616:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000561a:	21c48513          	addi	a0,s1,540
    8000561e:	ffffd097          	auipc	ra,0xffffd
    80005622:	208080e7          	jalr	520(ra) # 80002826 <wakeup>
    80005626:	b7e9                	j	800055f0 <pipeclose+0x2c>
    release(&pi->lock);
    80005628:	8526                	mv	a0,s1
    8000562a:	ffffb097          	auipc	ra,0xffffb
    8000562e:	65e080e7          	jalr	1630(ra) # 80000c88 <release>
}
    80005632:	bfe1                	j	8000560a <pipeclose+0x46>

0000000080005634 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005634:	711d                	addi	sp,sp,-96
    80005636:	ec86                	sd	ra,88(sp)
    80005638:	e8a2                	sd	s0,80(sp)
    8000563a:	e4a6                	sd	s1,72(sp)
    8000563c:	e0ca                	sd	s2,64(sp)
    8000563e:	fc4e                	sd	s3,56(sp)
    80005640:	f852                	sd	s4,48(sp)
    80005642:	f456                	sd	s5,40(sp)
    80005644:	f05a                	sd	s6,32(sp)
    80005646:	ec5e                	sd	s7,24(sp)
    80005648:	e862                	sd	s8,16(sp)
    8000564a:	1080                	addi	s0,sp,96
    8000564c:	84aa                	mv	s1,a0
    8000564e:	8aae                	mv	s5,a1
    80005650:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005652:	ffffc097          	auipc	ra,0xffffc
    80005656:	3a4080e7          	jalr	932(ra) # 800019f6 <myproc>
    8000565a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000565c:	8526                	mv	a0,s1
    8000565e:	ffffb097          	auipc	ra,0xffffb
    80005662:	564080e7          	jalr	1380(ra) # 80000bc2 <acquire>
  while(i < n){
    80005666:	0b405363          	blez	s4,8000570c <pipewrite+0xd8>
  int i = 0;
    8000566a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000566c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000566e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005672:	21c48b93          	addi	s7,s1,540
    80005676:	a089                	j	800056b8 <pipewrite+0x84>
      release(&pi->lock);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffb097          	auipc	ra,0xffffb
    8000567e:	60e080e7          	jalr	1550(ra) # 80000c88 <release>
      return -1;
    80005682:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005684:	854a                	mv	a0,s2
    80005686:	60e6                	ld	ra,88(sp)
    80005688:	6446                	ld	s0,80(sp)
    8000568a:	64a6                	ld	s1,72(sp)
    8000568c:	6906                	ld	s2,64(sp)
    8000568e:	79e2                	ld	s3,56(sp)
    80005690:	7a42                	ld	s4,48(sp)
    80005692:	7aa2                	ld	s5,40(sp)
    80005694:	7b02                	ld	s6,32(sp)
    80005696:	6be2                	ld	s7,24(sp)
    80005698:	6c42                	ld	s8,16(sp)
    8000569a:	6125                	addi	sp,sp,96
    8000569c:	8082                	ret
      wakeup(&pi->nread);
    8000569e:	8562                	mv	a0,s8
    800056a0:	ffffd097          	auipc	ra,0xffffd
    800056a4:	186080e7          	jalr	390(ra) # 80002826 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800056a8:	85a6                	mv	a1,s1
    800056aa:	855e                	mv	a0,s7
    800056ac:	ffffd097          	auipc	ra,0xffffd
    800056b0:	ff0080e7          	jalr	-16(ra) # 8000269c <sleep>
  while(i < n){
    800056b4:	05495d63          	bge	s2,s4,8000570e <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800056b8:	2204a783          	lw	a5,544(s1)
    800056bc:	dfd5                	beqz	a5,80005678 <pipewrite+0x44>
    800056be:	01c9a783          	lw	a5,28(s3)
    800056c2:	fbdd                	bnez	a5,80005678 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800056c4:	2184a783          	lw	a5,536(s1)
    800056c8:	21c4a703          	lw	a4,540(s1)
    800056cc:	2007879b          	addiw	a5,a5,512
    800056d0:	fcf707e3          	beq	a4,a5,8000569e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056d4:	4685                	li	a3,1
    800056d6:	01590633          	add	a2,s2,s5
    800056da:	faf40593          	addi	a1,s0,-81
    800056de:	1d89b503          	ld	a0,472(s3)
    800056e2:	ffffc097          	auipc	ra,0xffffc
    800056e6:	00c080e7          	jalr	12(ra) # 800016ee <copyin>
    800056ea:	03650263          	beq	a0,s6,8000570e <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800056ee:	21c4a783          	lw	a5,540(s1)
    800056f2:	0017871b          	addiw	a4,a5,1
    800056f6:	20e4ae23          	sw	a4,540(s1)
    800056fa:	1ff7f793          	andi	a5,a5,511
    800056fe:	97a6                	add	a5,a5,s1
    80005700:	faf44703          	lbu	a4,-81(s0)
    80005704:	00e78c23          	sb	a4,24(a5)
      i++;
    80005708:	2905                	addiw	s2,s2,1
    8000570a:	b76d                	j	800056b4 <pipewrite+0x80>
  int i = 0;
    8000570c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000570e:	21848513          	addi	a0,s1,536
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	114080e7          	jalr	276(ra) # 80002826 <wakeup>
  release(&pi->lock);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	56c080e7          	jalr	1388(ra) # 80000c88 <release>
  return i;
    80005724:	b785                	j	80005684 <pipewrite+0x50>

0000000080005726 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005726:	715d                	addi	sp,sp,-80
    80005728:	e486                	sd	ra,72(sp)
    8000572a:	e0a2                	sd	s0,64(sp)
    8000572c:	fc26                	sd	s1,56(sp)
    8000572e:	f84a                	sd	s2,48(sp)
    80005730:	f44e                	sd	s3,40(sp)
    80005732:	f052                	sd	s4,32(sp)
    80005734:	ec56                	sd	s5,24(sp)
    80005736:	e85a                	sd	s6,16(sp)
    80005738:	0880                	addi	s0,sp,80
    8000573a:	84aa                	mv	s1,a0
    8000573c:	892e                	mv	s2,a1
    8000573e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005740:	ffffc097          	auipc	ra,0xffffc
    80005744:	2b6080e7          	jalr	694(ra) # 800019f6 <myproc>
    80005748:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffb097          	auipc	ra,0xffffb
    80005750:	476080e7          	jalr	1142(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005754:	2184a703          	lw	a4,536(s1)
    80005758:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000575c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005760:	02f71463          	bne	a4,a5,80005788 <piperead+0x62>
    80005764:	2244a783          	lw	a5,548(s1)
    80005768:	c385                	beqz	a5,80005788 <piperead+0x62>
    if(pr->killed){
    8000576a:	01ca2783          	lw	a5,28(s4)
    8000576e:	ebc1                	bnez	a5,800057fe <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005770:	85a6                	mv	a1,s1
    80005772:	854e                	mv	a0,s3
    80005774:	ffffd097          	auipc	ra,0xffffd
    80005778:	f28080e7          	jalr	-216(ra) # 8000269c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000577c:	2184a703          	lw	a4,536(s1)
    80005780:	21c4a783          	lw	a5,540(s1)
    80005784:	fef700e3          	beq	a4,a5,80005764 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005788:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000578a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000578c:	05505363          	blez	s5,800057d2 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005790:	2184a783          	lw	a5,536(s1)
    80005794:	21c4a703          	lw	a4,540(s1)
    80005798:	02f70d63          	beq	a4,a5,800057d2 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000579c:	0017871b          	addiw	a4,a5,1
    800057a0:	20e4ac23          	sw	a4,536(s1)
    800057a4:	1ff7f793          	andi	a5,a5,511
    800057a8:	97a6                	add	a5,a5,s1
    800057aa:	0187c783          	lbu	a5,24(a5)
    800057ae:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057b2:	4685                	li	a3,1
    800057b4:	fbf40613          	addi	a2,s0,-65
    800057b8:	85ca                	mv	a1,s2
    800057ba:	1d8a3503          	ld	a0,472(s4)
    800057be:	ffffc097          	auipc	ra,0xffffc
    800057c2:	ea4080e7          	jalr	-348(ra) # 80001662 <copyout>
    800057c6:	01650663          	beq	a0,s6,800057d2 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057ca:	2985                	addiw	s3,s3,1
    800057cc:	0905                	addi	s2,s2,1
    800057ce:	fd3a91e3          	bne	s5,s3,80005790 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800057d2:	21c48513          	addi	a0,s1,540
    800057d6:	ffffd097          	auipc	ra,0xffffd
    800057da:	050080e7          	jalr	80(ra) # 80002826 <wakeup>
  release(&pi->lock);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffb097          	auipc	ra,0xffffb
    800057e4:	4a8080e7          	jalr	1192(ra) # 80000c88 <release>
  return i;
}
    800057e8:	854e                	mv	a0,s3
    800057ea:	60a6                	ld	ra,72(sp)
    800057ec:	6406                	ld	s0,64(sp)
    800057ee:	74e2                	ld	s1,56(sp)
    800057f0:	7942                	ld	s2,48(sp)
    800057f2:	79a2                	ld	s3,40(sp)
    800057f4:	7a02                	ld	s4,32(sp)
    800057f6:	6ae2                	ld	s5,24(sp)
    800057f8:	6b42                	ld	s6,16(sp)
    800057fa:	6161                	addi	sp,sp,80
    800057fc:	8082                	ret
      release(&pi->lock);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffb097          	auipc	ra,0xffffb
    80005804:	488080e7          	jalr	1160(ra) # 80000c88 <release>
      return -1;
    80005808:	59fd                	li	s3,-1
    8000580a:	bff9                	j	800057e8 <piperead+0xc2>

000000008000580c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000580c:	dd010113          	addi	sp,sp,-560
    80005810:	22113423          	sd	ra,552(sp)
    80005814:	22813023          	sd	s0,544(sp)
    80005818:	20913c23          	sd	s1,536(sp)
    8000581c:	21213823          	sd	s2,528(sp)
    80005820:	21313423          	sd	s3,520(sp)
    80005824:	21413023          	sd	s4,512(sp)
    80005828:	ffd6                	sd	s5,504(sp)
    8000582a:	fbda                	sd	s6,496(sp)
    8000582c:	f7de                	sd	s7,488(sp)
    8000582e:	f3e2                	sd	s8,480(sp)
    80005830:	efe6                	sd	s9,472(sp)
    80005832:	ebea                	sd	s10,464(sp)
    80005834:	e7ee                	sd	s11,456(sp)
    80005836:	1c00                	addi	s0,sp,560
    80005838:	dea43823          	sd	a0,-528(s0)
    8000583c:	deb43023          	sd	a1,-544(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005840:	ffffc097          	auipc	ra,0xffffc
    80005844:	1b6080e7          	jalr	438(ra) # 800019f6 <myproc>
    80005848:	89aa                	mv	s3,a0
  struct thread *t = mythread();
    8000584a:	ffffc097          	auipc	ra,0xffffc
    8000584e:	1e6080e7          	jalr	486(ra) # 80001a30 <mythread>
    80005852:	e0a43423          	sd	a0,-504(s0)

  // ADDED Q3
  for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    80005856:	27898493          	addi	s1,s3,632
    8000585a:	6905                	lui	s2,0x1
    8000585c:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    80005860:	994e                	add	s2,s2,s3
    if(t_temp->tid != t->tid){
      acquire(&t_temp->lock);
      t_temp->terminated = 1;
    80005862:	4a85                	li	s5,1
      if(t_temp->state == SLEEPING){
    80005864:	4a09                	li	s4,2
        t_temp->state = RUNNABLE;
    80005866:	4b0d                	li	s6,3
    80005868:	a015                	j	8000588c <exec+0x80>
    8000586a:	0164ac23          	sw	s6,24(s1)
      }
      release(&t_temp->lock);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffb097          	auipc	ra,0xffffb
    80005874:	418080e7          	jalr	1048(ra) # 80000c88 <release>
      kthread_join(t_temp->tid, 0);
    80005878:	4581                	li	a1,0
    8000587a:	5888                	lw	a0,48(s1)
    8000587c:	ffffd097          	auipc	ra,0xffffd
    80005880:	592080e7          	jalr	1426(ra) # 80002e0e <kthread_join>
  for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    80005884:	0c048493          	addi	s1,s1,192
    80005888:	03248363          	beq	s1,s2,800058ae <exec+0xa2>
    if(t_temp->tid != t->tid){
    8000588c:	5898                	lw	a4,48(s1)
    8000588e:	e0843783          	ld	a5,-504(s0)
    80005892:	5b9c                	lw	a5,48(a5)
    80005894:	fef708e3          	beq	a4,a5,80005884 <exec+0x78>
      acquire(&t_temp->lock);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffb097          	auipc	ra,0xffffb
    8000589e:	328080e7          	jalr	808(ra) # 80000bc2 <acquire>
      t_temp->terminated = 1;
    800058a2:	0354a423          	sw	s5,40(s1)
      if(t_temp->state == SLEEPING){
    800058a6:	4c9c                	lw	a5,24(s1)
    800058a8:	fd4793e3          	bne	a5,s4,8000586e <exec+0x62>
    800058ac:	bf7d                	j	8000586a <exec+0x5e>
    }
  }

  begin_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	440080e7          	jalr	1088(ra) # 80004cee <begin_op>

  if((ip = namei(path)) == 0){
    800058b6:	df043503          	ld	a0,-528(s0)
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	214080e7          	jalr	532(ra) # 80004ace <namei>
    800058c2:	8aaa                	mv	s5,a0
    800058c4:	cd25                	beqz	a0,8000593c <exec+0x130>
    end_op();
    return -1;
  }
  ilock(ip);
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	a52080e7          	jalr	-1454(ra) # 80004318 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800058ce:	04000713          	li	a4,64
    800058d2:	4681                	li	a3,0
    800058d4:	e4840613          	addi	a2,s0,-440
    800058d8:	4581                	li	a1,0
    800058da:	8556                	mv	a0,s5
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	cf0080e7          	jalr	-784(ra) # 800045cc <readi>
    800058e4:	04000793          	li	a5,64
    800058e8:	00f51a63          	bne	a0,a5,800058fc <exec+0xf0>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800058ec:	e4842703          	lw	a4,-440(s0)
    800058f0:	464c47b7          	lui	a5,0x464c4
    800058f4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058f8:	04f70863          	beq	a4,a5,80005948 <exec+0x13c>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800058fc:	8556                	mv	a0,s5
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	c7c080e7          	jalr	-900(ra) # 8000457a <iunlockput>
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	468080e7          	jalr	1128(ra) # 80004d6e <end_op>
  }
  return -1;
    8000590e:	557d                	li	a0,-1
}
    80005910:	22813083          	ld	ra,552(sp)
    80005914:	22013403          	ld	s0,544(sp)
    80005918:	21813483          	ld	s1,536(sp)
    8000591c:	21013903          	ld	s2,528(sp)
    80005920:	20813983          	ld	s3,520(sp)
    80005924:	20013a03          	ld	s4,512(sp)
    80005928:	7afe                	ld	s5,504(sp)
    8000592a:	7b5e                	ld	s6,496(sp)
    8000592c:	7bbe                	ld	s7,488(sp)
    8000592e:	7c1e                	ld	s8,480(sp)
    80005930:	6cfe                	ld	s9,472(sp)
    80005932:	6d5e                	ld	s10,464(sp)
    80005934:	6dbe                	ld	s11,456(sp)
    80005936:	23010113          	addi	sp,sp,560
    8000593a:	8082                	ret
    end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	432080e7          	jalr	1074(ra) # 80004d6e <end_op>
    return -1;
    80005944:	557d                	li	a0,-1
    80005946:	b7e9                	j	80005910 <exec+0x104>
  if((pagetable = proc_pagetable(p)) == 0)
    80005948:	854e                	mv	a0,s3
    8000594a:	ffffc097          	auipc	ra,0xffffc
    8000594e:	2ce080e7          	jalr	718(ra) # 80001c18 <proc_pagetable>
    80005952:	8b2a                	mv	s6,a0
    80005954:	d545                	beqz	a0,800058fc <exec+0xf0>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005956:	e6842783          	lw	a5,-408(s0)
    8000595a:	e8045703          	lhu	a4,-384(s0)
    8000595e:	c735                	beqz	a4,800059ca <exec+0x1be>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005960:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005962:	e0043023          	sd	zero,-512(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005966:	6a05                	lui	s4,0x1
    80005968:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000596c:	dce43c23          	sd	a4,-552(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005970:	6d85                	lui	s11,0x1
    80005972:	7d7d                	lui	s10,0xfffff
    80005974:	a485                	j	80005bd4 <exec+0x3c8>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005976:	00003517          	auipc	a0,0x3
    8000597a:	d8a50513          	addi	a0,a0,-630 # 80008700 <syscalls+0x2b8>
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	bac080e7          	jalr	-1108(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005986:	874a                	mv	a4,s2
    80005988:	009c86bb          	addw	a3,s9,s1
    8000598c:	4581                	li	a1,0
    8000598e:	8556                	mv	a0,s5
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	c3c080e7          	jalr	-964(ra) # 800045cc <readi>
    80005998:	2501                	sext.w	a0,a0
    8000599a:	1ca91d63          	bne	s2,a0,80005b74 <exec+0x368>
  for(i = 0; i < sz; i += PGSIZE){
    8000599e:	009d84bb          	addw	s1,s11,s1
    800059a2:	013d09bb          	addw	s3,s10,s3
    800059a6:	2174f763          	bgeu	s1,s7,80005bb4 <exec+0x3a8>
    pa = walkaddr(pagetable, va + i);
    800059aa:	02049593          	slli	a1,s1,0x20
    800059ae:	9181                	srli	a1,a1,0x20
    800059b0:	95e2                	add	a1,a1,s8
    800059b2:	855a                	mv	a0,s6
    800059b4:	ffffb097          	auipc	ra,0xffffb
    800059b8:	6bc080e7          	jalr	1724(ra) # 80001070 <walkaddr>
    800059bc:	862a                	mv	a2,a0
    if(pa == 0)
    800059be:	dd45                	beqz	a0,80005976 <exec+0x16a>
      n = PGSIZE;
    800059c0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800059c2:	fd49f2e3          	bgeu	s3,s4,80005986 <exec+0x17a>
      n = sz - i;
    800059c6:	894e                	mv	s2,s3
    800059c8:	bf7d                	j	80005986 <exec+0x17a>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800059ca:	4481                	li	s1,0
  iunlockput(ip);
    800059cc:	8556                	mv	a0,s5
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	bac080e7          	jalr	-1108(ra) # 8000457a <iunlockput>
  end_op();
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	398080e7          	jalr	920(ra) # 80004d6e <end_op>
  p = myproc();
    800059de:	ffffc097          	auipc	ra,0xffffc
    800059e2:	018080e7          	jalr	24(ra) # 800019f6 <myproc>
    800059e6:	8a2a                	mv	s4,a0
  uint64 oldsz = p->sz;
    800059e8:	1d053d03          	ld	s10,464(a0)
  sz = PGROUNDUP(sz);
    800059ec:	6785                	lui	a5,0x1
    800059ee:	17fd                	addi	a5,a5,-1
    800059f0:	94be                	add	s1,s1,a5
    800059f2:	77fd                	lui	a5,0xfffff
    800059f4:	8fe5                	and	a5,a5,s1
    800059f6:	def43423          	sd	a5,-536(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800059fa:	6609                	lui	a2,0x2
    800059fc:	963e                	add	a2,a2,a5
    800059fe:	85be                	mv	a1,a5
    80005a00:	855a                	mv	a0,s6
    80005a02:	ffffc097          	auipc	ra,0xffffc
    80005a06:	a10080e7          	jalr	-1520(ra) # 80001412 <uvmalloc>
    80005a0a:	8caa                	mv	s9,a0
  ip = 0;
    80005a0c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a0e:	16050363          	beqz	a0,80005b74 <exec+0x368>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005a12:	75f9                	lui	a1,0xffffe
    80005a14:	95aa                	add	a1,a1,a0
    80005a16:	855a                	mv	a0,s6
    80005a18:	ffffc097          	auipc	ra,0xffffc
    80005a1c:	c18080e7          	jalr	-1000(ra) # 80001630 <uvmclear>
  stackbase = sp - PGSIZE;
    80005a20:	7bfd                	lui	s7,0xfffff
    80005a22:	9be6                	add	s7,s7,s9
  for(argc = 0; argv[argc]; argc++) {
    80005a24:	de043783          	ld	a5,-544(s0)
    80005a28:	6388                	ld	a0,0(a5)
    80005a2a:	c925                	beqz	a0,80005a9a <exec+0x28e>
    80005a2c:	e8840993          	addi	s3,s0,-376
    80005a30:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005a34:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005a36:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005a38:	ffffb097          	auipc	ra,0xffffb
    80005a3c:	42e080e7          	jalr	1070(ra) # 80000e66 <strlen>
    80005a40:	0015079b          	addiw	a5,a0,1
    80005a44:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a48:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a4c:	15796863          	bltu	s2,s7,80005b9c <exec+0x390>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005a50:	de043d83          	ld	s11,-544(s0)
    80005a54:	000dba83          	ld	s5,0(s11) # 1000 <_entry-0x7ffff000>
    80005a58:	8556                	mv	a0,s5
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	40c080e7          	jalr	1036(ra) # 80000e66 <strlen>
    80005a62:	0015069b          	addiw	a3,a0,1
    80005a66:	8656                	mv	a2,s5
    80005a68:	85ca                	mv	a1,s2
    80005a6a:	855a                	mv	a0,s6
    80005a6c:	ffffc097          	auipc	ra,0xffffc
    80005a70:	bf6080e7          	jalr	-1034(ra) # 80001662 <copyout>
    80005a74:	12054863          	bltz	a0,80005ba4 <exec+0x398>
    ustack[argc] = sp;
    80005a78:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005a7c:	0485                	addi	s1,s1,1
    80005a7e:	008d8793          	addi	a5,s11,8
    80005a82:	def43023          	sd	a5,-544(s0)
    80005a86:	008db503          	ld	a0,8(s11)
    80005a8a:	c911                	beqz	a0,80005a9e <exec+0x292>
    if(argc >= MAXARG)
    80005a8c:	09a1                	addi	s3,s3,8
    80005a8e:	fb3c15e3          	bne	s8,s3,80005a38 <exec+0x22c>
  sz = sz1;
    80005a92:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005a96:	4a81                	li	s5,0
    80005a98:	a8f1                	j	80005b74 <exec+0x368>
  sp = sz;
    80005a9a:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005a9c:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a9e:	00349793          	slli	a5,s1,0x3
    80005aa2:	f9040713          	addi	a4,s0,-112
    80005aa6:	97ba                	add	a5,a5,a4
    80005aa8:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffbcef8>
  sp -= (argc+1) * sizeof(uint64);
    80005aac:	00148693          	addi	a3,s1,1
    80005ab0:	068e                	slli	a3,a3,0x3
    80005ab2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005ab6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005aba:	01797663          	bgeu	s2,s7,80005ac6 <exec+0x2ba>
  sz = sz1;
    80005abe:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005ac2:	4a81                	li	s5,0
    80005ac4:	a845                	j	80005b74 <exec+0x368>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005ac6:	e8840613          	addi	a2,s0,-376
    80005aca:	85ca                	mv	a1,s2
    80005acc:	855a                	mv	a0,s6
    80005ace:	ffffc097          	auipc	ra,0xffffc
    80005ad2:	b94080e7          	jalr	-1132(ra) # 80001662 <copyout>
    80005ad6:	0c054b63          	bltz	a0,80005bac <exec+0x3a0>
  t->trapframe->a1 = sp;
    80005ada:	e0843783          	ld	a5,-504(s0)
    80005ade:	67bc                	ld	a5,72(a5)
    80005ae0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005ae4:	df043783          	ld	a5,-528(s0)
    80005ae8:	0007c703          	lbu	a4,0(a5)
    80005aec:	cf11                	beqz	a4,80005b08 <exec+0x2fc>
    80005aee:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005af0:	02f00693          	li	a3,47
    80005af4:	a039                	j	80005b02 <exec+0x2f6>
      last = s+1;
    80005af6:	def43823          	sd	a5,-528(s0)
  for(last=s=path; *s; s++)
    80005afa:	0785                	addi	a5,a5,1
    80005afc:	fff7c703          	lbu	a4,-1(a5)
    80005b00:	c701                	beqz	a4,80005b08 <exec+0x2fc>
    if(*s == '/')
    80005b02:	fed71ce3          	bne	a4,a3,80005afa <exec+0x2ee>
    80005b06:	bfc5                	j	80005af6 <exec+0x2ea>
  safestrcpy(p->name, last, sizeof(p->name));
    80005b08:	4641                	li	a2,16
    80005b0a:	df043583          	ld	a1,-528(s0)
    80005b0e:	268a0513          	addi	a0,s4,616
    80005b12:	ffffb097          	auipc	ra,0xffffb
    80005b16:	322080e7          	jalr	802(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    80005b1a:	1d8a3503          	ld	a0,472(s4)
  p->pagetable = pagetable;
    80005b1e:	1d6a3c23          	sd	s6,472(s4)
  p->sz = sz;
    80005b22:	1d9a3823          	sd	s9,464(s4)
  t->trapframe->epc = elf.entry;  // initial program counter = main
    80005b26:	e0843683          	ld	a3,-504(s0)
    80005b2a:	66bc                	ld	a5,72(a3)
    80005b2c:	e6043703          	ld	a4,-416(s0)
    80005b30:	ef98                	sd	a4,24(a5)
  t->trapframe->sp = sp; // initial stack pointer
    80005b32:	66bc                	ld	a5,72(a3)
    80005b34:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b38:	85ea                	mv	a1,s10
    80005b3a:	ffffc097          	auipc	ra,0xffffc
    80005b3e:	17e080e7          	jalr	382(ra) # 80001cb8 <proc_freepagetable>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005b42:	138a0793          	addi	a5,s4,312
    80005b46:	038a0a13          	addi	s4,s4,56
    80005b4a:	863e                	mv	a2,a5
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005b4c:	4685                	li	a3,1
    80005b4e:	a029                	j	80005b58 <exec+0x34c>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005b50:	0791                	addi	a5,a5,4
    80005b52:	0a21                	addi	s4,s4,8
    80005b54:	00ca0b63          	beq	s4,a2,80005b6a <exec+0x35e>
    p->signal_handlers_masks[signum] = 0;
    80005b58:	0007a023          	sw	zero,0(a5)
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005b5c:	000a3703          	ld	a4,0(s4)
    80005b60:	fed708e3          	beq	a4,a3,80005b50 <exec+0x344>
      p->signal_handlers[signum] = SIG_DFL;
    80005b64:	000a3023          	sd	zero,0(s4)
    80005b68:	b7e5                	j	80005b50 <exec+0x344>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b6a:	0004851b          	sext.w	a0,s1
    80005b6e:	b34d                	j	80005910 <exec+0x104>
    80005b70:	de943423          	sd	s1,-536(s0)
    proc_freepagetable(pagetable, sz);
    80005b74:	de843583          	ld	a1,-536(s0)
    80005b78:	855a                	mv	a0,s6
    80005b7a:	ffffc097          	auipc	ra,0xffffc
    80005b7e:	13e080e7          	jalr	318(ra) # 80001cb8 <proc_freepagetable>
  if(ip){
    80005b82:	d60a9de3          	bnez	s5,800058fc <exec+0xf0>
  return -1;
    80005b86:	557d                	li	a0,-1
    80005b88:	b361                	j	80005910 <exec+0x104>
    80005b8a:	de943423          	sd	s1,-536(s0)
    80005b8e:	b7dd                	j	80005b74 <exec+0x368>
    80005b90:	de943423          	sd	s1,-536(s0)
    80005b94:	b7c5                	j	80005b74 <exec+0x368>
    80005b96:	de943423          	sd	s1,-536(s0)
    80005b9a:	bfe9                	j	80005b74 <exec+0x368>
  sz = sz1;
    80005b9c:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005ba0:	4a81                	li	s5,0
    80005ba2:	bfc9                	j	80005b74 <exec+0x368>
  sz = sz1;
    80005ba4:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005ba8:	4a81                	li	s5,0
    80005baa:	b7e9                	j	80005b74 <exec+0x368>
  sz = sz1;
    80005bac:	df943423          	sd	s9,-536(s0)
  ip = 0;
    80005bb0:	4a81                	li	s5,0
    80005bb2:	b7c9                	j	80005b74 <exec+0x368>
    sz = sz1;
    80005bb4:	de843483          	ld	s1,-536(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005bb8:	e0043783          	ld	a5,-512(s0)
    80005bbc:	0017869b          	addiw	a3,a5,1
    80005bc0:	e0d43023          	sd	a3,-512(s0)
    80005bc4:	df843783          	ld	a5,-520(s0)
    80005bc8:	0387879b          	addiw	a5,a5,56
    80005bcc:	e8045703          	lhu	a4,-384(s0)
    80005bd0:	dee6dee3          	bge	a3,a4,800059cc <exec+0x1c0>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005bd4:	2781                	sext.w	a5,a5
    80005bd6:	def43c23          	sd	a5,-520(s0)
    80005bda:	03800713          	li	a4,56
    80005bde:	86be                	mv	a3,a5
    80005be0:	e1040613          	addi	a2,s0,-496
    80005be4:	4581                	li	a1,0
    80005be6:	8556                	mv	a0,s5
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	9e4080e7          	jalr	-1564(ra) # 800045cc <readi>
    80005bf0:	03800793          	li	a5,56
    80005bf4:	f6f51ee3          	bne	a0,a5,80005b70 <exec+0x364>
    if(ph.type != ELF_PROG_LOAD)
    80005bf8:	e1042783          	lw	a5,-496(s0)
    80005bfc:	4705                	li	a4,1
    80005bfe:	fae79de3          	bne	a5,a4,80005bb8 <exec+0x3ac>
    if(ph.memsz < ph.filesz)
    80005c02:	e3843603          	ld	a2,-456(s0)
    80005c06:	e3043783          	ld	a5,-464(s0)
    80005c0a:	f8f660e3          	bltu	a2,a5,80005b8a <exec+0x37e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005c0e:	e2043783          	ld	a5,-480(s0)
    80005c12:	963e                	add	a2,a2,a5
    80005c14:	f6f66ee3          	bltu	a2,a5,80005b90 <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005c18:	85a6                	mv	a1,s1
    80005c1a:	855a                	mv	a0,s6
    80005c1c:	ffffb097          	auipc	ra,0xffffb
    80005c20:	7f6080e7          	jalr	2038(ra) # 80001412 <uvmalloc>
    80005c24:	dea43423          	sd	a0,-536(s0)
    80005c28:	d53d                	beqz	a0,80005b96 <exec+0x38a>
    if(ph.vaddr % PGSIZE != 0)
    80005c2a:	e2043c03          	ld	s8,-480(s0)
    80005c2e:	dd843783          	ld	a5,-552(s0)
    80005c32:	00fc77b3          	and	a5,s8,a5
    80005c36:	ff9d                	bnez	a5,80005b74 <exec+0x368>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005c38:	e1842c83          	lw	s9,-488(s0)
    80005c3c:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005c40:	f60b8ae3          	beqz	s7,80005bb4 <exec+0x3a8>
    80005c44:	89de                	mv	s3,s7
    80005c46:	4481                	li	s1,0
    80005c48:	b38d                	j	800059aa <exec+0x19e>

0000000080005c4a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c4a:	7179                	addi	sp,sp,-48
    80005c4c:	f406                	sd	ra,40(sp)
    80005c4e:	f022                	sd	s0,32(sp)
    80005c50:	ec26                	sd	s1,24(sp)
    80005c52:	e84a                	sd	s2,16(sp)
    80005c54:	1800                	addi	s0,sp,48
    80005c56:	892e                	mv	s2,a1
    80005c58:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005c5a:	fdc40593          	addi	a1,s0,-36
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	996080e7          	jalr	-1642(ra) # 800035f4 <argint>
    80005c66:	04054063          	bltz	a0,80005ca6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c6a:	fdc42703          	lw	a4,-36(s0)
    80005c6e:	47bd                	li	a5,15
    80005c70:	02e7ed63          	bltu	a5,a4,80005caa <argfd+0x60>
    80005c74:	ffffc097          	auipc	ra,0xffffc
    80005c78:	d82080e7          	jalr	-638(ra) # 800019f6 <myproc>
    80005c7c:	fdc42703          	lw	a4,-36(s0)
    80005c80:	03c70793          	addi	a5,a4,60
    80005c84:	078e                	slli	a5,a5,0x3
    80005c86:	953e                	add	a0,a0,a5
    80005c88:	611c                	ld	a5,0(a0)
    80005c8a:	c395                	beqz	a5,80005cae <argfd+0x64>
    return -1;
  if(pfd)
    80005c8c:	00090463          	beqz	s2,80005c94 <argfd+0x4a>
    *pfd = fd;
    80005c90:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c94:	4501                	li	a0,0
  if(pf)
    80005c96:	c091                	beqz	s1,80005c9a <argfd+0x50>
    *pf = f;
    80005c98:	e09c                	sd	a5,0(s1)
}
    80005c9a:	70a2                	ld	ra,40(sp)
    80005c9c:	7402                	ld	s0,32(sp)
    80005c9e:	64e2                	ld	s1,24(sp)
    80005ca0:	6942                	ld	s2,16(sp)
    80005ca2:	6145                	addi	sp,sp,48
    80005ca4:	8082                	ret
    return -1;
    80005ca6:	557d                	li	a0,-1
    80005ca8:	bfcd                	j	80005c9a <argfd+0x50>
    return -1;
    80005caa:	557d                	li	a0,-1
    80005cac:	b7fd                	j	80005c9a <argfd+0x50>
    80005cae:	557d                	li	a0,-1
    80005cb0:	b7ed                	j	80005c9a <argfd+0x50>

0000000080005cb2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005cb2:	1101                	addi	sp,sp,-32
    80005cb4:	ec06                	sd	ra,24(sp)
    80005cb6:	e822                	sd	s0,16(sp)
    80005cb8:	e426                	sd	s1,8(sp)
    80005cba:	1000                	addi	s0,sp,32
    80005cbc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005cbe:	ffffc097          	auipc	ra,0xffffc
    80005cc2:	d38080e7          	jalr	-712(ra) # 800019f6 <myproc>
    80005cc6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005cc8:	1e050793          	addi	a5,a0,480
    80005ccc:	4501                	li	a0,0
    80005cce:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005cd0:	6398                	ld	a4,0(a5)
    80005cd2:	cb19                	beqz	a4,80005ce8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005cd4:	2505                	addiw	a0,a0,1
    80005cd6:	07a1                	addi	a5,a5,8
    80005cd8:	fed51ce3          	bne	a0,a3,80005cd0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005cdc:	557d                	li	a0,-1
}
    80005cde:	60e2                	ld	ra,24(sp)
    80005ce0:	6442                	ld	s0,16(sp)
    80005ce2:	64a2                	ld	s1,8(sp)
    80005ce4:	6105                	addi	sp,sp,32
    80005ce6:	8082                	ret
      p->ofile[fd] = f;
    80005ce8:	03c50793          	addi	a5,a0,60
    80005cec:	078e                	slli	a5,a5,0x3
    80005cee:	963e                	add	a2,a2,a5
    80005cf0:	e204                	sd	s1,0(a2)
      return fd;
    80005cf2:	b7f5                	j	80005cde <fdalloc+0x2c>

0000000080005cf4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005cf4:	715d                	addi	sp,sp,-80
    80005cf6:	e486                	sd	ra,72(sp)
    80005cf8:	e0a2                	sd	s0,64(sp)
    80005cfa:	fc26                	sd	s1,56(sp)
    80005cfc:	f84a                	sd	s2,48(sp)
    80005cfe:	f44e                	sd	s3,40(sp)
    80005d00:	f052                	sd	s4,32(sp)
    80005d02:	ec56                	sd	s5,24(sp)
    80005d04:	0880                	addi	s0,sp,80
    80005d06:	89ae                	mv	s3,a1
    80005d08:	8ab2                	mv	s5,a2
    80005d0a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005d0c:	fb040593          	addi	a1,s0,-80
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	ddc080e7          	jalr	-548(ra) # 80004aec <nameiparent>
    80005d18:	892a                	mv	s2,a0
    80005d1a:	12050e63          	beqz	a0,80005e56 <create+0x162>
    return 0;

  ilock(dp);
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	5fa080e7          	jalr	1530(ra) # 80004318 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005d26:	4601                	li	a2,0
    80005d28:	fb040593          	addi	a1,s0,-80
    80005d2c:	854a                	mv	a0,s2
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	ace080e7          	jalr	-1330(ra) # 800047fc <dirlookup>
    80005d36:	84aa                	mv	s1,a0
    80005d38:	c921                	beqz	a0,80005d88 <create+0x94>
    iunlockput(dp);
    80005d3a:	854a                	mv	a0,s2
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	83e080e7          	jalr	-1986(ra) # 8000457a <iunlockput>
    ilock(ip);
    80005d44:	8526                	mv	a0,s1
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	5d2080e7          	jalr	1490(ra) # 80004318 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005d4e:	2981                	sext.w	s3,s3
    80005d50:	4789                	li	a5,2
    80005d52:	02f99463          	bne	s3,a5,80005d7a <create+0x86>
    80005d56:	0444d783          	lhu	a5,68(s1)
    80005d5a:	37f9                	addiw	a5,a5,-2
    80005d5c:	17c2                	slli	a5,a5,0x30
    80005d5e:	93c1                	srli	a5,a5,0x30
    80005d60:	4705                	li	a4,1
    80005d62:	00f76c63          	bltu	a4,a5,80005d7a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005d66:	8526                	mv	a0,s1
    80005d68:	60a6                	ld	ra,72(sp)
    80005d6a:	6406                	ld	s0,64(sp)
    80005d6c:	74e2                	ld	s1,56(sp)
    80005d6e:	7942                	ld	s2,48(sp)
    80005d70:	79a2                	ld	s3,40(sp)
    80005d72:	7a02                	ld	s4,32(sp)
    80005d74:	6ae2                	ld	s5,24(sp)
    80005d76:	6161                	addi	sp,sp,80
    80005d78:	8082                	ret
    iunlockput(ip);
    80005d7a:	8526                	mv	a0,s1
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	7fe080e7          	jalr	2046(ra) # 8000457a <iunlockput>
    return 0;
    80005d84:	4481                	li	s1,0
    80005d86:	b7c5                	j	80005d66 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005d88:	85ce                	mv	a1,s3
    80005d8a:	00092503          	lw	a0,0(s2)
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	3f2080e7          	jalr	1010(ra) # 80004180 <ialloc>
    80005d96:	84aa                	mv	s1,a0
    80005d98:	c521                	beqz	a0,80005de0 <create+0xec>
  ilock(ip);
    80005d9a:	ffffe097          	auipc	ra,0xffffe
    80005d9e:	57e080e7          	jalr	1406(ra) # 80004318 <ilock>
  ip->major = major;
    80005da2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005da6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005daa:	4a05                	li	s4,1
    80005dac:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005db0:	8526                	mv	a0,s1
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	49c080e7          	jalr	1180(ra) # 8000424e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005dba:	2981                	sext.w	s3,s3
    80005dbc:	03498a63          	beq	s3,s4,80005df0 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005dc0:	40d0                	lw	a2,4(s1)
    80005dc2:	fb040593          	addi	a1,s0,-80
    80005dc6:	854a                	mv	a0,s2
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	c44080e7          	jalr	-956(ra) # 80004a0c <dirlink>
    80005dd0:	06054b63          	bltz	a0,80005e46 <create+0x152>
  iunlockput(dp);
    80005dd4:	854a                	mv	a0,s2
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	7a4080e7          	jalr	1956(ra) # 8000457a <iunlockput>
  return ip;
    80005dde:	b761                	j	80005d66 <create+0x72>
    panic("create: ialloc");
    80005de0:	00003517          	auipc	a0,0x3
    80005de4:	94050513          	addi	a0,a0,-1728 # 80008720 <syscalls+0x2d8>
    80005de8:	ffffa097          	auipc	ra,0xffffa
    80005dec:	742080e7          	jalr	1858(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005df0:	04a95783          	lhu	a5,74(s2)
    80005df4:	2785                	addiw	a5,a5,1
    80005df6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005dfa:	854a                	mv	a0,s2
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	452080e7          	jalr	1106(ra) # 8000424e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005e04:	40d0                	lw	a2,4(s1)
    80005e06:	00003597          	auipc	a1,0x3
    80005e0a:	92a58593          	addi	a1,a1,-1750 # 80008730 <syscalls+0x2e8>
    80005e0e:	8526                	mv	a0,s1
    80005e10:	fffff097          	auipc	ra,0xfffff
    80005e14:	bfc080e7          	jalr	-1028(ra) # 80004a0c <dirlink>
    80005e18:	00054f63          	bltz	a0,80005e36 <create+0x142>
    80005e1c:	00492603          	lw	a2,4(s2)
    80005e20:	00003597          	auipc	a1,0x3
    80005e24:	91858593          	addi	a1,a1,-1768 # 80008738 <syscalls+0x2f0>
    80005e28:	8526                	mv	a0,s1
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	be2080e7          	jalr	-1054(ra) # 80004a0c <dirlink>
    80005e32:	f80557e3          	bgez	a0,80005dc0 <create+0xcc>
      panic("create dots");
    80005e36:	00003517          	auipc	a0,0x3
    80005e3a:	90a50513          	addi	a0,a0,-1782 # 80008740 <syscalls+0x2f8>
    80005e3e:	ffffa097          	auipc	ra,0xffffa
    80005e42:	6ec080e7          	jalr	1772(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005e46:	00003517          	auipc	a0,0x3
    80005e4a:	90a50513          	addi	a0,a0,-1782 # 80008750 <syscalls+0x308>
    80005e4e:	ffffa097          	auipc	ra,0xffffa
    80005e52:	6dc080e7          	jalr	1756(ra) # 8000052a <panic>
    return 0;
    80005e56:	84aa                	mv	s1,a0
    80005e58:	b739                	j	80005d66 <create+0x72>

0000000080005e5a <sys_dup>:
{
    80005e5a:	7179                	addi	sp,sp,-48
    80005e5c:	f406                	sd	ra,40(sp)
    80005e5e:	f022                	sd	s0,32(sp)
    80005e60:	ec26                	sd	s1,24(sp)
    80005e62:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e64:	fd840613          	addi	a2,s0,-40
    80005e68:	4581                	li	a1,0
    80005e6a:	4501                	li	a0,0
    80005e6c:	00000097          	auipc	ra,0x0
    80005e70:	dde080e7          	jalr	-546(ra) # 80005c4a <argfd>
    return -1;
    80005e74:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e76:	02054363          	bltz	a0,80005e9c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e7a:	fd843503          	ld	a0,-40(s0)
    80005e7e:	00000097          	auipc	ra,0x0
    80005e82:	e34080e7          	jalr	-460(ra) # 80005cb2 <fdalloc>
    80005e86:	84aa                	mv	s1,a0
    return -1;
    80005e88:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e8a:	00054963          	bltz	a0,80005e9c <sys_dup+0x42>
  filedup(f);
    80005e8e:	fd843503          	ld	a0,-40(s0)
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	2d6080e7          	jalr	726(ra) # 80005168 <filedup>
  return fd;
    80005e9a:	87a6                	mv	a5,s1
}
    80005e9c:	853e                	mv	a0,a5
    80005e9e:	70a2                	ld	ra,40(sp)
    80005ea0:	7402                	ld	s0,32(sp)
    80005ea2:	64e2                	ld	s1,24(sp)
    80005ea4:	6145                	addi	sp,sp,48
    80005ea6:	8082                	ret

0000000080005ea8 <sys_read>:
{
    80005ea8:	7179                	addi	sp,sp,-48
    80005eaa:	f406                	sd	ra,40(sp)
    80005eac:	f022                	sd	s0,32(sp)
    80005eae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eb0:	fe840613          	addi	a2,s0,-24
    80005eb4:	4581                	li	a1,0
    80005eb6:	4501                	li	a0,0
    80005eb8:	00000097          	auipc	ra,0x0
    80005ebc:	d92080e7          	jalr	-622(ra) # 80005c4a <argfd>
    return -1;
    80005ec0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ec2:	04054163          	bltz	a0,80005f04 <sys_read+0x5c>
    80005ec6:	fe440593          	addi	a1,s0,-28
    80005eca:	4509                	li	a0,2
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	728080e7          	jalr	1832(ra) # 800035f4 <argint>
    return -1;
    80005ed4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ed6:	02054763          	bltz	a0,80005f04 <sys_read+0x5c>
    80005eda:	fd840593          	addi	a1,s0,-40
    80005ede:	4505                	li	a0,1
    80005ee0:	ffffd097          	auipc	ra,0xffffd
    80005ee4:	736080e7          	jalr	1846(ra) # 80003616 <argaddr>
    return -1;
    80005ee8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eea:	00054d63          	bltz	a0,80005f04 <sys_read+0x5c>
  return fileread(f, p, n);
    80005eee:	fe442603          	lw	a2,-28(s0)
    80005ef2:	fd843583          	ld	a1,-40(s0)
    80005ef6:	fe843503          	ld	a0,-24(s0)
    80005efa:	fffff097          	auipc	ra,0xfffff
    80005efe:	3fa080e7          	jalr	1018(ra) # 800052f4 <fileread>
    80005f02:	87aa                	mv	a5,a0
}
    80005f04:	853e                	mv	a0,a5
    80005f06:	70a2                	ld	ra,40(sp)
    80005f08:	7402                	ld	s0,32(sp)
    80005f0a:	6145                	addi	sp,sp,48
    80005f0c:	8082                	ret

0000000080005f0e <sys_write>:
{
    80005f0e:	7179                	addi	sp,sp,-48
    80005f10:	f406                	sd	ra,40(sp)
    80005f12:	f022                	sd	s0,32(sp)
    80005f14:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f16:	fe840613          	addi	a2,s0,-24
    80005f1a:	4581                	li	a1,0
    80005f1c:	4501                	li	a0,0
    80005f1e:	00000097          	auipc	ra,0x0
    80005f22:	d2c080e7          	jalr	-724(ra) # 80005c4a <argfd>
    return -1;
    80005f26:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f28:	04054163          	bltz	a0,80005f6a <sys_write+0x5c>
    80005f2c:	fe440593          	addi	a1,s0,-28
    80005f30:	4509                	li	a0,2
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	6c2080e7          	jalr	1730(ra) # 800035f4 <argint>
    return -1;
    80005f3a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f3c:	02054763          	bltz	a0,80005f6a <sys_write+0x5c>
    80005f40:	fd840593          	addi	a1,s0,-40
    80005f44:	4505                	li	a0,1
    80005f46:	ffffd097          	auipc	ra,0xffffd
    80005f4a:	6d0080e7          	jalr	1744(ra) # 80003616 <argaddr>
    return -1;
    80005f4e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f50:	00054d63          	bltz	a0,80005f6a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005f54:	fe442603          	lw	a2,-28(s0)
    80005f58:	fd843583          	ld	a1,-40(s0)
    80005f5c:	fe843503          	ld	a0,-24(s0)
    80005f60:	fffff097          	auipc	ra,0xfffff
    80005f64:	456080e7          	jalr	1110(ra) # 800053b6 <filewrite>
    80005f68:	87aa                	mv	a5,a0
}
    80005f6a:	853e                	mv	a0,a5
    80005f6c:	70a2                	ld	ra,40(sp)
    80005f6e:	7402                	ld	s0,32(sp)
    80005f70:	6145                	addi	sp,sp,48
    80005f72:	8082                	ret

0000000080005f74 <sys_close>:
{
    80005f74:	1101                	addi	sp,sp,-32
    80005f76:	ec06                	sd	ra,24(sp)
    80005f78:	e822                	sd	s0,16(sp)
    80005f7a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f7c:	fe040613          	addi	a2,s0,-32
    80005f80:	fec40593          	addi	a1,s0,-20
    80005f84:	4501                	li	a0,0
    80005f86:	00000097          	auipc	ra,0x0
    80005f8a:	cc4080e7          	jalr	-828(ra) # 80005c4a <argfd>
    return -1;
    80005f8e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f90:	02054563          	bltz	a0,80005fba <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005f94:	ffffc097          	auipc	ra,0xffffc
    80005f98:	a62080e7          	jalr	-1438(ra) # 800019f6 <myproc>
    80005f9c:	fec42783          	lw	a5,-20(s0)
    80005fa0:	03c78793          	addi	a5,a5,60
    80005fa4:	078e                	slli	a5,a5,0x3
    80005fa6:	97aa                	add	a5,a5,a0
    80005fa8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005fac:	fe043503          	ld	a0,-32(s0)
    80005fb0:	fffff097          	auipc	ra,0xfffff
    80005fb4:	20a080e7          	jalr	522(ra) # 800051ba <fileclose>
  return 0;
    80005fb8:	4781                	li	a5,0
}
    80005fba:	853e                	mv	a0,a5
    80005fbc:	60e2                	ld	ra,24(sp)
    80005fbe:	6442                	ld	s0,16(sp)
    80005fc0:	6105                	addi	sp,sp,32
    80005fc2:	8082                	ret

0000000080005fc4 <sys_fstat>:
{
    80005fc4:	1101                	addi	sp,sp,-32
    80005fc6:	ec06                	sd	ra,24(sp)
    80005fc8:	e822                	sd	s0,16(sp)
    80005fca:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fcc:	fe840613          	addi	a2,s0,-24
    80005fd0:	4581                	li	a1,0
    80005fd2:	4501                	li	a0,0
    80005fd4:	00000097          	auipc	ra,0x0
    80005fd8:	c76080e7          	jalr	-906(ra) # 80005c4a <argfd>
    return -1;
    80005fdc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fde:	02054563          	bltz	a0,80006008 <sys_fstat+0x44>
    80005fe2:	fe040593          	addi	a1,s0,-32
    80005fe6:	4505                	li	a0,1
    80005fe8:	ffffd097          	auipc	ra,0xffffd
    80005fec:	62e080e7          	jalr	1582(ra) # 80003616 <argaddr>
    return -1;
    80005ff0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ff2:	00054b63          	bltz	a0,80006008 <sys_fstat+0x44>
  return filestat(f, st);
    80005ff6:	fe043583          	ld	a1,-32(s0)
    80005ffa:	fe843503          	ld	a0,-24(s0)
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	284080e7          	jalr	644(ra) # 80005282 <filestat>
    80006006:	87aa                	mv	a5,a0
}
    80006008:	853e                	mv	a0,a5
    8000600a:	60e2                	ld	ra,24(sp)
    8000600c:	6442                	ld	s0,16(sp)
    8000600e:	6105                	addi	sp,sp,32
    80006010:	8082                	ret

0000000080006012 <sys_link>:
{
    80006012:	7169                	addi	sp,sp,-304
    80006014:	f606                	sd	ra,296(sp)
    80006016:	f222                	sd	s0,288(sp)
    80006018:	ee26                	sd	s1,280(sp)
    8000601a:	ea4a                	sd	s2,272(sp)
    8000601c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000601e:	08000613          	li	a2,128
    80006022:	ed040593          	addi	a1,s0,-304
    80006026:	4501                	li	a0,0
    80006028:	ffffd097          	auipc	ra,0xffffd
    8000602c:	610080e7          	jalr	1552(ra) # 80003638 <argstr>
    return -1;
    80006030:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006032:	10054e63          	bltz	a0,8000614e <sys_link+0x13c>
    80006036:	08000613          	li	a2,128
    8000603a:	f5040593          	addi	a1,s0,-176
    8000603e:	4505                	li	a0,1
    80006040:	ffffd097          	auipc	ra,0xffffd
    80006044:	5f8080e7          	jalr	1528(ra) # 80003638 <argstr>
    return -1;
    80006048:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000604a:	10054263          	bltz	a0,8000614e <sys_link+0x13c>
  begin_op();
    8000604e:	fffff097          	auipc	ra,0xfffff
    80006052:	ca0080e7          	jalr	-864(ra) # 80004cee <begin_op>
  if((ip = namei(old)) == 0){
    80006056:	ed040513          	addi	a0,s0,-304
    8000605a:	fffff097          	auipc	ra,0xfffff
    8000605e:	a74080e7          	jalr	-1420(ra) # 80004ace <namei>
    80006062:	84aa                	mv	s1,a0
    80006064:	c551                	beqz	a0,800060f0 <sys_link+0xde>
  ilock(ip);
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	2b2080e7          	jalr	690(ra) # 80004318 <ilock>
  if(ip->type == T_DIR){
    8000606e:	04449703          	lh	a4,68(s1)
    80006072:	4785                	li	a5,1
    80006074:	08f70463          	beq	a4,a5,800060fc <sys_link+0xea>
  ip->nlink++;
    80006078:	04a4d783          	lhu	a5,74(s1)
    8000607c:	2785                	addiw	a5,a5,1
    8000607e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006082:	8526                	mv	a0,s1
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	1ca080e7          	jalr	458(ra) # 8000424e <iupdate>
  iunlock(ip);
    8000608c:	8526                	mv	a0,s1
    8000608e:	ffffe097          	auipc	ra,0xffffe
    80006092:	34c080e7          	jalr	844(ra) # 800043da <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006096:	fd040593          	addi	a1,s0,-48
    8000609a:	f5040513          	addi	a0,s0,-176
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	a4e080e7          	jalr	-1458(ra) # 80004aec <nameiparent>
    800060a6:	892a                	mv	s2,a0
    800060a8:	c935                	beqz	a0,8000611c <sys_link+0x10a>
  ilock(dp);
    800060aa:	ffffe097          	auipc	ra,0xffffe
    800060ae:	26e080e7          	jalr	622(ra) # 80004318 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800060b2:	00092703          	lw	a4,0(s2)
    800060b6:	409c                	lw	a5,0(s1)
    800060b8:	04f71d63          	bne	a4,a5,80006112 <sys_link+0x100>
    800060bc:	40d0                	lw	a2,4(s1)
    800060be:	fd040593          	addi	a1,s0,-48
    800060c2:	854a                	mv	a0,s2
    800060c4:	fffff097          	auipc	ra,0xfffff
    800060c8:	948080e7          	jalr	-1720(ra) # 80004a0c <dirlink>
    800060cc:	04054363          	bltz	a0,80006112 <sys_link+0x100>
  iunlockput(dp);
    800060d0:	854a                	mv	a0,s2
    800060d2:	ffffe097          	auipc	ra,0xffffe
    800060d6:	4a8080e7          	jalr	1192(ra) # 8000457a <iunlockput>
  iput(ip);
    800060da:	8526                	mv	a0,s1
    800060dc:	ffffe097          	auipc	ra,0xffffe
    800060e0:	3f6080e7          	jalr	1014(ra) # 800044d2 <iput>
  end_op();
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	c8a080e7          	jalr	-886(ra) # 80004d6e <end_op>
  return 0;
    800060ec:	4781                	li	a5,0
    800060ee:	a085                	j	8000614e <sys_link+0x13c>
    end_op();
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	c7e080e7          	jalr	-898(ra) # 80004d6e <end_op>
    return -1;
    800060f8:	57fd                	li	a5,-1
    800060fa:	a891                	j	8000614e <sys_link+0x13c>
    iunlockput(ip);
    800060fc:	8526                	mv	a0,s1
    800060fe:	ffffe097          	auipc	ra,0xffffe
    80006102:	47c080e7          	jalr	1148(ra) # 8000457a <iunlockput>
    end_op();
    80006106:	fffff097          	auipc	ra,0xfffff
    8000610a:	c68080e7          	jalr	-920(ra) # 80004d6e <end_op>
    return -1;
    8000610e:	57fd                	li	a5,-1
    80006110:	a83d                	j	8000614e <sys_link+0x13c>
    iunlockput(dp);
    80006112:	854a                	mv	a0,s2
    80006114:	ffffe097          	auipc	ra,0xffffe
    80006118:	466080e7          	jalr	1126(ra) # 8000457a <iunlockput>
  ilock(ip);
    8000611c:	8526                	mv	a0,s1
    8000611e:	ffffe097          	auipc	ra,0xffffe
    80006122:	1fa080e7          	jalr	506(ra) # 80004318 <ilock>
  ip->nlink--;
    80006126:	04a4d783          	lhu	a5,74(s1)
    8000612a:	37fd                	addiw	a5,a5,-1
    8000612c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006130:	8526                	mv	a0,s1
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	11c080e7          	jalr	284(ra) # 8000424e <iupdate>
  iunlockput(ip);
    8000613a:	8526                	mv	a0,s1
    8000613c:	ffffe097          	auipc	ra,0xffffe
    80006140:	43e080e7          	jalr	1086(ra) # 8000457a <iunlockput>
  end_op();
    80006144:	fffff097          	auipc	ra,0xfffff
    80006148:	c2a080e7          	jalr	-982(ra) # 80004d6e <end_op>
  return -1;
    8000614c:	57fd                	li	a5,-1
}
    8000614e:	853e                	mv	a0,a5
    80006150:	70b2                	ld	ra,296(sp)
    80006152:	7412                	ld	s0,288(sp)
    80006154:	64f2                	ld	s1,280(sp)
    80006156:	6952                	ld	s2,272(sp)
    80006158:	6155                	addi	sp,sp,304
    8000615a:	8082                	ret

000000008000615c <sys_unlink>:
{
    8000615c:	7151                	addi	sp,sp,-240
    8000615e:	f586                	sd	ra,232(sp)
    80006160:	f1a2                	sd	s0,224(sp)
    80006162:	eda6                	sd	s1,216(sp)
    80006164:	e9ca                	sd	s2,208(sp)
    80006166:	e5ce                	sd	s3,200(sp)
    80006168:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000616a:	08000613          	li	a2,128
    8000616e:	f3040593          	addi	a1,s0,-208
    80006172:	4501                	li	a0,0
    80006174:	ffffd097          	auipc	ra,0xffffd
    80006178:	4c4080e7          	jalr	1220(ra) # 80003638 <argstr>
    8000617c:	18054163          	bltz	a0,800062fe <sys_unlink+0x1a2>
  begin_op();
    80006180:	fffff097          	auipc	ra,0xfffff
    80006184:	b6e080e7          	jalr	-1170(ra) # 80004cee <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006188:	fb040593          	addi	a1,s0,-80
    8000618c:	f3040513          	addi	a0,s0,-208
    80006190:	fffff097          	auipc	ra,0xfffff
    80006194:	95c080e7          	jalr	-1700(ra) # 80004aec <nameiparent>
    80006198:	84aa                	mv	s1,a0
    8000619a:	c979                	beqz	a0,80006270 <sys_unlink+0x114>
  ilock(dp);
    8000619c:	ffffe097          	auipc	ra,0xffffe
    800061a0:	17c080e7          	jalr	380(ra) # 80004318 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800061a4:	00002597          	auipc	a1,0x2
    800061a8:	58c58593          	addi	a1,a1,1420 # 80008730 <syscalls+0x2e8>
    800061ac:	fb040513          	addi	a0,s0,-80
    800061b0:	ffffe097          	auipc	ra,0xffffe
    800061b4:	632080e7          	jalr	1586(ra) # 800047e2 <namecmp>
    800061b8:	14050a63          	beqz	a0,8000630c <sys_unlink+0x1b0>
    800061bc:	00002597          	auipc	a1,0x2
    800061c0:	57c58593          	addi	a1,a1,1404 # 80008738 <syscalls+0x2f0>
    800061c4:	fb040513          	addi	a0,s0,-80
    800061c8:	ffffe097          	auipc	ra,0xffffe
    800061cc:	61a080e7          	jalr	1562(ra) # 800047e2 <namecmp>
    800061d0:	12050e63          	beqz	a0,8000630c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800061d4:	f2c40613          	addi	a2,s0,-212
    800061d8:	fb040593          	addi	a1,s0,-80
    800061dc:	8526                	mv	a0,s1
    800061de:	ffffe097          	auipc	ra,0xffffe
    800061e2:	61e080e7          	jalr	1566(ra) # 800047fc <dirlookup>
    800061e6:	892a                	mv	s2,a0
    800061e8:	12050263          	beqz	a0,8000630c <sys_unlink+0x1b0>
  ilock(ip);
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	12c080e7          	jalr	300(ra) # 80004318 <ilock>
  if(ip->nlink < 1)
    800061f4:	04a91783          	lh	a5,74(s2)
    800061f8:	08f05263          	blez	a5,8000627c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800061fc:	04491703          	lh	a4,68(s2)
    80006200:	4785                	li	a5,1
    80006202:	08f70563          	beq	a4,a5,8000628c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006206:	4641                	li	a2,16
    80006208:	4581                	li	a1,0
    8000620a:	fc040513          	addi	a0,s0,-64
    8000620e:	ffffb097          	auipc	ra,0xffffb
    80006212:	ad4080e7          	jalr	-1324(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006216:	4741                	li	a4,16
    80006218:	f2c42683          	lw	a3,-212(s0)
    8000621c:	fc040613          	addi	a2,s0,-64
    80006220:	4581                	li	a1,0
    80006222:	8526                	mv	a0,s1
    80006224:	ffffe097          	auipc	ra,0xffffe
    80006228:	4a0080e7          	jalr	1184(ra) # 800046c4 <writei>
    8000622c:	47c1                	li	a5,16
    8000622e:	0af51563          	bne	a0,a5,800062d8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006232:	04491703          	lh	a4,68(s2)
    80006236:	4785                	li	a5,1
    80006238:	0af70863          	beq	a4,a5,800062e8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000623c:	8526                	mv	a0,s1
    8000623e:	ffffe097          	auipc	ra,0xffffe
    80006242:	33c080e7          	jalr	828(ra) # 8000457a <iunlockput>
  ip->nlink--;
    80006246:	04a95783          	lhu	a5,74(s2)
    8000624a:	37fd                	addiw	a5,a5,-1
    8000624c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006250:	854a                	mv	a0,s2
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	ffc080e7          	jalr	-4(ra) # 8000424e <iupdate>
  iunlockput(ip);
    8000625a:	854a                	mv	a0,s2
    8000625c:	ffffe097          	auipc	ra,0xffffe
    80006260:	31e080e7          	jalr	798(ra) # 8000457a <iunlockput>
  end_op();
    80006264:	fffff097          	auipc	ra,0xfffff
    80006268:	b0a080e7          	jalr	-1270(ra) # 80004d6e <end_op>
  return 0;
    8000626c:	4501                	li	a0,0
    8000626e:	a84d                	j	80006320 <sys_unlink+0x1c4>
    end_op();
    80006270:	fffff097          	auipc	ra,0xfffff
    80006274:	afe080e7          	jalr	-1282(ra) # 80004d6e <end_op>
    return -1;
    80006278:	557d                	li	a0,-1
    8000627a:	a05d                	j	80006320 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000627c:	00002517          	auipc	a0,0x2
    80006280:	4e450513          	addi	a0,a0,1252 # 80008760 <syscalls+0x318>
    80006284:	ffffa097          	auipc	ra,0xffffa
    80006288:	2a6080e7          	jalr	678(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000628c:	04c92703          	lw	a4,76(s2)
    80006290:	02000793          	li	a5,32
    80006294:	f6e7f9e3          	bgeu	a5,a4,80006206 <sys_unlink+0xaa>
    80006298:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000629c:	4741                	li	a4,16
    8000629e:	86ce                	mv	a3,s3
    800062a0:	f1840613          	addi	a2,s0,-232
    800062a4:	4581                	li	a1,0
    800062a6:	854a                	mv	a0,s2
    800062a8:	ffffe097          	auipc	ra,0xffffe
    800062ac:	324080e7          	jalr	804(ra) # 800045cc <readi>
    800062b0:	47c1                	li	a5,16
    800062b2:	00f51b63          	bne	a0,a5,800062c8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800062b6:	f1845783          	lhu	a5,-232(s0)
    800062ba:	e7a1                	bnez	a5,80006302 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062bc:	29c1                	addiw	s3,s3,16
    800062be:	04c92783          	lw	a5,76(s2)
    800062c2:	fcf9ede3          	bltu	s3,a5,8000629c <sys_unlink+0x140>
    800062c6:	b781                	j	80006206 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800062c8:	00002517          	auipc	a0,0x2
    800062cc:	4b050513          	addi	a0,a0,1200 # 80008778 <syscalls+0x330>
    800062d0:	ffffa097          	auipc	ra,0xffffa
    800062d4:	25a080e7          	jalr	602(ra) # 8000052a <panic>
    panic("unlink: writei");
    800062d8:	00002517          	auipc	a0,0x2
    800062dc:	4b850513          	addi	a0,a0,1208 # 80008790 <syscalls+0x348>
    800062e0:	ffffa097          	auipc	ra,0xffffa
    800062e4:	24a080e7          	jalr	586(ra) # 8000052a <panic>
    dp->nlink--;
    800062e8:	04a4d783          	lhu	a5,74(s1)
    800062ec:	37fd                	addiw	a5,a5,-1
    800062ee:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800062f2:	8526                	mv	a0,s1
    800062f4:	ffffe097          	auipc	ra,0xffffe
    800062f8:	f5a080e7          	jalr	-166(ra) # 8000424e <iupdate>
    800062fc:	b781                	j	8000623c <sys_unlink+0xe0>
    return -1;
    800062fe:	557d                	li	a0,-1
    80006300:	a005                	j	80006320 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006302:	854a                	mv	a0,s2
    80006304:	ffffe097          	auipc	ra,0xffffe
    80006308:	276080e7          	jalr	630(ra) # 8000457a <iunlockput>
  iunlockput(dp);
    8000630c:	8526                	mv	a0,s1
    8000630e:	ffffe097          	auipc	ra,0xffffe
    80006312:	26c080e7          	jalr	620(ra) # 8000457a <iunlockput>
  end_op();
    80006316:	fffff097          	auipc	ra,0xfffff
    8000631a:	a58080e7          	jalr	-1448(ra) # 80004d6e <end_op>
  return -1;
    8000631e:	557d                	li	a0,-1
}
    80006320:	70ae                	ld	ra,232(sp)
    80006322:	740e                	ld	s0,224(sp)
    80006324:	64ee                	ld	s1,216(sp)
    80006326:	694e                	ld	s2,208(sp)
    80006328:	69ae                	ld	s3,200(sp)
    8000632a:	616d                	addi	sp,sp,240
    8000632c:	8082                	ret

000000008000632e <sys_open>:

uint64
sys_open(void)
{
    8000632e:	7131                	addi	sp,sp,-192
    80006330:	fd06                	sd	ra,184(sp)
    80006332:	f922                	sd	s0,176(sp)
    80006334:	f526                	sd	s1,168(sp)
    80006336:	f14a                	sd	s2,160(sp)
    80006338:	ed4e                	sd	s3,152(sp)
    8000633a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000633c:	08000613          	li	a2,128
    80006340:	f5040593          	addi	a1,s0,-176
    80006344:	4501                	li	a0,0
    80006346:	ffffd097          	auipc	ra,0xffffd
    8000634a:	2f2080e7          	jalr	754(ra) # 80003638 <argstr>
    return -1;
    8000634e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006350:	0c054163          	bltz	a0,80006412 <sys_open+0xe4>
    80006354:	f4c40593          	addi	a1,s0,-180
    80006358:	4505                	li	a0,1
    8000635a:	ffffd097          	auipc	ra,0xffffd
    8000635e:	29a080e7          	jalr	666(ra) # 800035f4 <argint>
    80006362:	0a054863          	bltz	a0,80006412 <sys_open+0xe4>

  begin_op();
    80006366:	fffff097          	auipc	ra,0xfffff
    8000636a:	988080e7          	jalr	-1656(ra) # 80004cee <begin_op>

  if(omode & O_CREATE){
    8000636e:	f4c42783          	lw	a5,-180(s0)
    80006372:	2007f793          	andi	a5,a5,512
    80006376:	cbdd                	beqz	a5,8000642c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006378:	4681                	li	a3,0
    8000637a:	4601                	li	a2,0
    8000637c:	4589                	li	a1,2
    8000637e:	f5040513          	addi	a0,s0,-176
    80006382:	00000097          	auipc	ra,0x0
    80006386:	972080e7          	jalr	-1678(ra) # 80005cf4 <create>
    8000638a:	892a                	mv	s2,a0
    if(ip == 0){
    8000638c:	c959                	beqz	a0,80006422 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000638e:	04491703          	lh	a4,68(s2)
    80006392:	478d                	li	a5,3
    80006394:	00f71763          	bne	a4,a5,800063a2 <sys_open+0x74>
    80006398:	04695703          	lhu	a4,70(s2)
    8000639c:	47a5                	li	a5,9
    8000639e:	0ce7ec63          	bltu	a5,a4,80006476 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800063a2:	fffff097          	auipc	ra,0xfffff
    800063a6:	d5c080e7          	jalr	-676(ra) # 800050fe <filealloc>
    800063aa:	89aa                	mv	s3,a0
    800063ac:	10050263          	beqz	a0,800064b0 <sys_open+0x182>
    800063b0:	00000097          	auipc	ra,0x0
    800063b4:	902080e7          	jalr	-1790(ra) # 80005cb2 <fdalloc>
    800063b8:	84aa                	mv	s1,a0
    800063ba:	0e054663          	bltz	a0,800064a6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800063be:	04491703          	lh	a4,68(s2)
    800063c2:	478d                	li	a5,3
    800063c4:	0cf70463          	beq	a4,a5,8000648c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800063c8:	4789                	li	a5,2
    800063ca:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800063ce:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800063d2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800063d6:	f4c42783          	lw	a5,-180(s0)
    800063da:	0017c713          	xori	a4,a5,1
    800063de:	8b05                	andi	a4,a4,1
    800063e0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800063e4:	0037f713          	andi	a4,a5,3
    800063e8:	00e03733          	snez	a4,a4
    800063ec:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800063f0:	4007f793          	andi	a5,a5,1024
    800063f4:	c791                	beqz	a5,80006400 <sys_open+0xd2>
    800063f6:	04491703          	lh	a4,68(s2)
    800063fa:	4789                	li	a5,2
    800063fc:	08f70f63          	beq	a4,a5,8000649a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006400:	854a                	mv	a0,s2
    80006402:	ffffe097          	auipc	ra,0xffffe
    80006406:	fd8080e7          	jalr	-40(ra) # 800043da <iunlock>
  end_op();
    8000640a:	fffff097          	auipc	ra,0xfffff
    8000640e:	964080e7          	jalr	-1692(ra) # 80004d6e <end_op>

  return fd;
}
    80006412:	8526                	mv	a0,s1
    80006414:	70ea                	ld	ra,184(sp)
    80006416:	744a                	ld	s0,176(sp)
    80006418:	74aa                	ld	s1,168(sp)
    8000641a:	790a                	ld	s2,160(sp)
    8000641c:	69ea                	ld	s3,152(sp)
    8000641e:	6129                	addi	sp,sp,192
    80006420:	8082                	ret
      end_op();
    80006422:	fffff097          	auipc	ra,0xfffff
    80006426:	94c080e7          	jalr	-1716(ra) # 80004d6e <end_op>
      return -1;
    8000642a:	b7e5                	j	80006412 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000642c:	f5040513          	addi	a0,s0,-176
    80006430:	ffffe097          	auipc	ra,0xffffe
    80006434:	69e080e7          	jalr	1694(ra) # 80004ace <namei>
    80006438:	892a                	mv	s2,a0
    8000643a:	c905                	beqz	a0,8000646a <sys_open+0x13c>
    ilock(ip);
    8000643c:	ffffe097          	auipc	ra,0xffffe
    80006440:	edc080e7          	jalr	-292(ra) # 80004318 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006444:	04491703          	lh	a4,68(s2)
    80006448:	4785                	li	a5,1
    8000644a:	f4f712e3          	bne	a4,a5,8000638e <sys_open+0x60>
    8000644e:	f4c42783          	lw	a5,-180(s0)
    80006452:	dba1                	beqz	a5,800063a2 <sys_open+0x74>
      iunlockput(ip);
    80006454:	854a                	mv	a0,s2
    80006456:	ffffe097          	auipc	ra,0xffffe
    8000645a:	124080e7          	jalr	292(ra) # 8000457a <iunlockput>
      end_op();
    8000645e:	fffff097          	auipc	ra,0xfffff
    80006462:	910080e7          	jalr	-1776(ra) # 80004d6e <end_op>
      return -1;
    80006466:	54fd                	li	s1,-1
    80006468:	b76d                	j	80006412 <sys_open+0xe4>
      end_op();
    8000646a:	fffff097          	auipc	ra,0xfffff
    8000646e:	904080e7          	jalr	-1788(ra) # 80004d6e <end_op>
      return -1;
    80006472:	54fd                	li	s1,-1
    80006474:	bf79                	j	80006412 <sys_open+0xe4>
    iunlockput(ip);
    80006476:	854a                	mv	a0,s2
    80006478:	ffffe097          	auipc	ra,0xffffe
    8000647c:	102080e7          	jalr	258(ra) # 8000457a <iunlockput>
    end_op();
    80006480:	fffff097          	auipc	ra,0xfffff
    80006484:	8ee080e7          	jalr	-1810(ra) # 80004d6e <end_op>
    return -1;
    80006488:	54fd                	li	s1,-1
    8000648a:	b761                	j	80006412 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000648c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006490:	04691783          	lh	a5,70(s2)
    80006494:	02f99223          	sh	a5,36(s3)
    80006498:	bf2d                	j	800063d2 <sys_open+0xa4>
    itrunc(ip);
    8000649a:	854a                	mv	a0,s2
    8000649c:	ffffe097          	auipc	ra,0xffffe
    800064a0:	f8a080e7          	jalr	-118(ra) # 80004426 <itrunc>
    800064a4:	bfb1                	j	80006400 <sys_open+0xd2>
      fileclose(f);
    800064a6:	854e                	mv	a0,s3
    800064a8:	fffff097          	auipc	ra,0xfffff
    800064ac:	d12080e7          	jalr	-750(ra) # 800051ba <fileclose>
    iunlockput(ip);
    800064b0:	854a                	mv	a0,s2
    800064b2:	ffffe097          	auipc	ra,0xffffe
    800064b6:	0c8080e7          	jalr	200(ra) # 8000457a <iunlockput>
    end_op();
    800064ba:	fffff097          	auipc	ra,0xfffff
    800064be:	8b4080e7          	jalr	-1868(ra) # 80004d6e <end_op>
    return -1;
    800064c2:	54fd                	li	s1,-1
    800064c4:	b7b9                	j	80006412 <sys_open+0xe4>

00000000800064c6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800064c6:	7175                	addi	sp,sp,-144
    800064c8:	e506                	sd	ra,136(sp)
    800064ca:	e122                	sd	s0,128(sp)
    800064cc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800064ce:	fffff097          	auipc	ra,0xfffff
    800064d2:	820080e7          	jalr	-2016(ra) # 80004cee <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800064d6:	08000613          	li	a2,128
    800064da:	f7040593          	addi	a1,s0,-144
    800064de:	4501                	li	a0,0
    800064e0:	ffffd097          	auipc	ra,0xffffd
    800064e4:	158080e7          	jalr	344(ra) # 80003638 <argstr>
    800064e8:	02054963          	bltz	a0,8000651a <sys_mkdir+0x54>
    800064ec:	4681                	li	a3,0
    800064ee:	4601                	li	a2,0
    800064f0:	4585                	li	a1,1
    800064f2:	f7040513          	addi	a0,s0,-144
    800064f6:	fffff097          	auipc	ra,0xfffff
    800064fa:	7fe080e7          	jalr	2046(ra) # 80005cf4 <create>
    800064fe:	cd11                	beqz	a0,8000651a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006500:	ffffe097          	auipc	ra,0xffffe
    80006504:	07a080e7          	jalr	122(ra) # 8000457a <iunlockput>
  end_op();
    80006508:	fffff097          	auipc	ra,0xfffff
    8000650c:	866080e7          	jalr	-1946(ra) # 80004d6e <end_op>
  return 0;
    80006510:	4501                	li	a0,0
}
    80006512:	60aa                	ld	ra,136(sp)
    80006514:	640a                	ld	s0,128(sp)
    80006516:	6149                	addi	sp,sp,144
    80006518:	8082                	ret
    end_op();
    8000651a:	fffff097          	auipc	ra,0xfffff
    8000651e:	854080e7          	jalr	-1964(ra) # 80004d6e <end_op>
    return -1;
    80006522:	557d                	li	a0,-1
    80006524:	b7fd                	j	80006512 <sys_mkdir+0x4c>

0000000080006526 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006526:	7135                	addi	sp,sp,-160
    80006528:	ed06                	sd	ra,152(sp)
    8000652a:	e922                	sd	s0,144(sp)
    8000652c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000652e:	ffffe097          	auipc	ra,0xffffe
    80006532:	7c0080e7          	jalr	1984(ra) # 80004cee <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006536:	08000613          	li	a2,128
    8000653a:	f7040593          	addi	a1,s0,-144
    8000653e:	4501                	li	a0,0
    80006540:	ffffd097          	auipc	ra,0xffffd
    80006544:	0f8080e7          	jalr	248(ra) # 80003638 <argstr>
    80006548:	04054a63          	bltz	a0,8000659c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000654c:	f6c40593          	addi	a1,s0,-148
    80006550:	4505                	li	a0,1
    80006552:	ffffd097          	auipc	ra,0xffffd
    80006556:	0a2080e7          	jalr	162(ra) # 800035f4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000655a:	04054163          	bltz	a0,8000659c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000655e:	f6840593          	addi	a1,s0,-152
    80006562:	4509                	li	a0,2
    80006564:	ffffd097          	auipc	ra,0xffffd
    80006568:	090080e7          	jalr	144(ra) # 800035f4 <argint>
     argint(1, &major) < 0 ||
    8000656c:	02054863          	bltz	a0,8000659c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006570:	f6841683          	lh	a3,-152(s0)
    80006574:	f6c41603          	lh	a2,-148(s0)
    80006578:	458d                	li	a1,3
    8000657a:	f7040513          	addi	a0,s0,-144
    8000657e:	fffff097          	auipc	ra,0xfffff
    80006582:	776080e7          	jalr	1910(ra) # 80005cf4 <create>
     argint(2, &minor) < 0 ||
    80006586:	c919                	beqz	a0,8000659c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006588:	ffffe097          	auipc	ra,0xffffe
    8000658c:	ff2080e7          	jalr	-14(ra) # 8000457a <iunlockput>
  end_op();
    80006590:	ffffe097          	auipc	ra,0xffffe
    80006594:	7de080e7          	jalr	2014(ra) # 80004d6e <end_op>
  return 0;
    80006598:	4501                	li	a0,0
    8000659a:	a031                	j	800065a6 <sys_mknod+0x80>
    end_op();
    8000659c:	ffffe097          	auipc	ra,0xffffe
    800065a0:	7d2080e7          	jalr	2002(ra) # 80004d6e <end_op>
    return -1;
    800065a4:	557d                	li	a0,-1
}
    800065a6:	60ea                	ld	ra,152(sp)
    800065a8:	644a                	ld	s0,144(sp)
    800065aa:	610d                	addi	sp,sp,160
    800065ac:	8082                	ret

00000000800065ae <sys_chdir>:

uint64
sys_chdir(void)
{
    800065ae:	7135                	addi	sp,sp,-160
    800065b0:	ed06                	sd	ra,152(sp)
    800065b2:	e922                	sd	s0,144(sp)
    800065b4:	e526                	sd	s1,136(sp)
    800065b6:	e14a                	sd	s2,128(sp)
    800065b8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800065ba:	ffffb097          	auipc	ra,0xffffb
    800065be:	43c080e7          	jalr	1084(ra) # 800019f6 <myproc>
    800065c2:	892a                	mv	s2,a0
  
  begin_op();
    800065c4:	ffffe097          	auipc	ra,0xffffe
    800065c8:	72a080e7          	jalr	1834(ra) # 80004cee <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800065cc:	08000613          	li	a2,128
    800065d0:	f6040593          	addi	a1,s0,-160
    800065d4:	4501                	li	a0,0
    800065d6:	ffffd097          	auipc	ra,0xffffd
    800065da:	062080e7          	jalr	98(ra) # 80003638 <argstr>
    800065de:	04054b63          	bltz	a0,80006634 <sys_chdir+0x86>
    800065e2:	f6040513          	addi	a0,s0,-160
    800065e6:	ffffe097          	auipc	ra,0xffffe
    800065ea:	4e8080e7          	jalr	1256(ra) # 80004ace <namei>
    800065ee:	84aa                	mv	s1,a0
    800065f0:	c131                	beqz	a0,80006634 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800065f2:	ffffe097          	auipc	ra,0xffffe
    800065f6:	d26080e7          	jalr	-730(ra) # 80004318 <ilock>
  if(ip->type != T_DIR){
    800065fa:	04449703          	lh	a4,68(s1)
    800065fe:	4785                	li	a5,1
    80006600:	04f71063          	bne	a4,a5,80006640 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006604:	8526                	mv	a0,s1
    80006606:	ffffe097          	auipc	ra,0xffffe
    8000660a:	dd4080e7          	jalr	-556(ra) # 800043da <iunlock>
  iput(p->cwd);
    8000660e:	26093503          	ld	a0,608(s2)
    80006612:	ffffe097          	auipc	ra,0xffffe
    80006616:	ec0080e7          	jalr	-320(ra) # 800044d2 <iput>
  end_op();
    8000661a:	ffffe097          	auipc	ra,0xffffe
    8000661e:	754080e7          	jalr	1876(ra) # 80004d6e <end_op>
  p->cwd = ip;
    80006622:	26993023          	sd	s1,608(s2)
  return 0;
    80006626:	4501                	li	a0,0
}
    80006628:	60ea                	ld	ra,152(sp)
    8000662a:	644a                	ld	s0,144(sp)
    8000662c:	64aa                	ld	s1,136(sp)
    8000662e:	690a                	ld	s2,128(sp)
    80006630:	610d                	addi	sp,sp,160
    80006632:	8082                	ret
    end_op();
    80006634:	ffffe097          	auipc	ra,0xffffe
    80006638:	73a080e7          	jalr	1850(ra) # 80004d6e <end_op>
    return -1;
    8000663c:	557d                	li	a0,-1
    8000663e:	b7ed                	j	80006628 <sys_chdir+0x7a>
    iunlockput(ip);
    80006640:	8526                	mv	a0,s1
    80006642:	ffffe097          	auipc	ra,0xffffe
    80006646:	f38080e7          	jalr	-200(ra) # 8000457a <iunlockput>
    end_op();
    8000664a:	ffffe097          	auipc	ra,0xffffe
    8000664e:	724080e7          	jalr	1828(ra) # 80004d6e <end_op>
    return -1;
    80006652:	557d                	li	a0,-1
    80006654:	bfd1                	j	80006628 <sys_chdir+0x7a>

0000000080006656 <sys_exec>:

uint64
sys_exec(void)
{
    80006656:	7145                	addi	sp,sp,-464
    80006658:	e786                	sd	ra,456(sp)
    8000665a:	e3a2                	sd	s0,448(sp)
    8000665c:	ff26                	sd	s1,440(sp)
    8000665e:	fb4a                	sd	s2,432(sp)
    80006660:	f74e                	sd	s3,424(sp)
    80006662:	f352                	sd	s4,416(sp)
    80006664:	ef56                	sd	s5,408(sp)
    80006666:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006668:	08000613          	li	a2,128
    8000666c:	f4040593          	addi	a1,s0,-192
    80006670:	4501                	li	a0,0
    80006672:	ffffd097          	auipc	ra,0xffffd
    80006676:	fc6080e7          	jalr	-58(ra) # 80003638 <argstr>
    return -1;
    8000667a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000667c:	0c054a63          	bltz	a0,80006750 <sys_exec+0xfa>
    80006680:	e3840593          	addi	a1,s0,-456
    80006684:	4505                	li	a0,1
    80006686:	ffffd097          	auipc	ra,0xffffd
    8000668a:	f90080e7          	jalr	-112(ra) # 80003616 <argaddr>
    8000668e:	0c054163          	bltz	a0,80006750 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006692:	10000613          	li	a2,256
    80006696:	4581                	li	a1,0
    80006698:	e4040513          	addi	a0,s0,-448
    8000669c:	ffffa097          	auipc	ra,0xffffa
    800066a0:	646080e7          	jalr	1606(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800066a4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800066a8:	89a6                	mv	s3,s1
    800066aa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800066ac:	02000a13          	li	s4,32
    800066b0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800066b4:	00391793          	slli	a5,s2,0x3
    800066b8:	e3040593          	addi	a1,s0,-464
    800066bc:	e3843503          	ld	a0,-456(s0)
    800066c0:	953e                	add	a0,a0,a5
    800066c2:	ffffd097          	auipc	ra,0xffffd
    800066c6:	e92080e7          	jalr	-366(ra) # 80003554 <fetchaddr>
    800066ca:	02054a63          	bltz	a0,800066fe <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800066ce:	e3043783          	ld	a5,-464(s0)
    800066d2:	c3b9                	beqz	a5,80006718 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800066d4:	ffffa097          	auipc	ra,0xffffa
    800066d8:	3fe080e7          	jalr	1022(ra) # 80000ad2 <kalloc>
    800066dc:	85aa                	mv	a1,a0
    800066de:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800066e2:	cd11                	beqz	a0,800066fe <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800066e4:	6605                	lui	a2,0x1
    800066e6:	e3043503          	ld	a0,-464(s0)
    800066ea:	ffffd097          	auipc	ra,0xffffd
    800066ee:	ec0080e7          	jalr	-320(ra) # 800035aa <fetchstr>
    800066f2:	00054663          	bltz	a0,800066fe <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800066f6:	0905                	addi	s2,s2,1
    800066f8:	09a1                	addi	s3,s3,8
    800066fa:	fb491be3          	bne	s2,s4,800066b0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066fe:	10048913          	addi	s2,s1,256
    80006702:	6088                	ld	a0,0(s1)
    80006704:	c529                	beqz	a0,8000674e <sys_exec+0xf8>
    kfree(argv[i]);
    80006706:	ffffa097          	auipc	ra,0xffffa
    8000670a:	2d0080e7          	jalr	720(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000670e:	04a1                	addi	s1,s1,8
    80006710:	ff2499e3          	bne	s1,s2,80006702 <sys_exec+0xac>
  return -1;
    80006714:	597d                	li	s2,-1
    80006716:	a82d                	j	80006750 <sys_exec+0xfa>
      argv[i] = 0;
    80006718:	0a8e                	slli	s5,s5,0x3
    8000671a:	fc040793          	addi	a5,s0,-64
    8000671e:	9abe                	add	s5,s5,a5
    80006720:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006724:	e4040593          	addi	a1,s0,-448
    80006728:	f4040513          	addi	a0,s0,-192
    8000672c:	fffff097          	auipc	ra,0xfffff
    80006730:	0e0080e7          	jalr	224(ra) # 8000580c <exec>
    80006734:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006736:	10048993          	addi	s3,s1,256
    8000673a:	6088                	ld	a0,0(s1)
    8000673c:	c911                	beqz	a0,80006750 <sys_exec+0xfa>
    kfree(argv[i]);
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	298080e7          	jalr	664(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006746:	04a1                	addi	s1,s1,8
    80006748:	ff3499e3          	bne	s1,s3,8000673a <sys_exec+0xe4>
    8000674c:	a011                	j	80006750 <sys_exec+0xfa>
  return -1;
    8000674e:	597d                	li	s2,-1
}
    80006750:	854a                	mv	a0,s2
    80006752:	60be                	ld	ra,456(sp)
    80006754:	641e                	ld	s0,448(sp)
    80006756:	74fa                	ld	s1,440(sp)
    80006758:	795a                	ld	s2,432(sp)
    8000675a:	79ba                	ld	s3,424(sp)
    8000675c:	7a1a                	ld	s4,416(sp)
    8000675e:	6afa                	ld	s5,408(sp)
    80006760:	6179                	addi	sp,sp,464
    80006762:	8082                	ret

0000000080006764 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006764:	7139                	addi	sp,sp,-64
    80006766:	fc06                	sd	ra,56(sp)
    80006768:	f822                	sd	s0,48(sp)
    8000676a:	f426                	sd	s1,40(sp)
    8000676c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000676e:	ffffb097          	auipc	ra,0xffffb
    80006772:	288080e7          	jalr	648(ra) # 800019f6 <myproc>
    80006776:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006778:	fd840593          	addi	a1,s0,-40
    8000677c:	4501                	li	a0,0
    8000677e:	ffffd097          	auipc	ra,0xffffd
    80006782:	e98080e7          	jalr	-360(ra) # 80003616 <argaddr>
    return -1;
    80006786:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006788:	0e054463          	bltz	a0,80006870 <sys_pipe+0x10c>
  if(pipealloc(&rf, &wf) < 0)
    8000678c:	fc840593          	addi	a1,s0,-56
    80006790:	fd040513          	addi	a0,s0,-48
    80006794:	fffff097          	auipc	ra,0xfffff
    80006798:	d56080e7          	jalr	-682(ra) # 800054ea <pipealloc>
    return -1;
    8000679c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000679e:	0c054963          	bltz	a0,80006870 <sys_pipe+0x10c>
  fd0 = -1;
    800067a2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800067a6:	fd043503          	ld	a0,-48(s0)
    800067aa:	fffff097          	auipc	ra,0xfffff
    800067ae:	508080e7          	jalr	1288(ra) # 80005cb2 <fdalloc>
    800067b2:	fca42223          	sw	a0,-60(s0)
    800067b6:	0a054063          	bltz	a0,80006856 <sys_pipe+0xf2>
    800067ba:	fc843503          	ld	a0,-56(s0)
    800067be:	fffff097          	auipc	ra,0xfffff
    800067c2:	4f4080e7          	jalr	1268(ra) # 80005cb2 <fdalloc>
    800067c6:	fca42023          	sw	a0,-64(s0)
    800067ca:	06054c63          	bltz	a0,80006842 <sys_pipe+0xde>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067ce:	4691                	li	a3,4
    800067d0:	fc440613          	addi	a2,s0,-60
    800067d4:	fd843583          	ld	a1,-40(s0)
    800067d8:	1d84b503          	ld	a0,472(s1)
    800067dc:	ffffb097          	auipc	ra,0xffffb
    800067e0:	e86080e7          	jalr	-378(ra) # 80001662 <copyout>
    800067e4:	02054163          	bltz	a0,80006806 <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800067e8:	4691                	li	a3,4
    800067ea:	fc040613          	addi	a2,s0,-64
    800067ee:	fd843583          	ld	a1,-40(s0)
    800067f2:	0591                	addi	a1,a1,4
    800067f4:	1d84b503          	ld	a0,472(s1)
    800067f8:	ffffb097          	auipc	ra,0xffffb
    800067fc:	e6a080e7          	jalr	-406(ra) # 80001662 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006800:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006802:	06055763          	bgez	a0,80006870 <sys_pipe+0x10c>
    p->ofile[fd0] = 0;
    80006806:	fc442783          	lw	a5,-60(s0)
    8000680a:	03c78793          	addi	a5,a5,60
    8000680e:	078e                	slli	a5,a5,0x3
    80006810:	97a6                	add	a5,a5,s1
    80006812:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006816:	fc042503          	lw	a0,-64(s0)
    8000681a:	03c50513          	addi	a0,a0,60
    8000681e:	050e                	slli	a0,a0,0x3
    80006820:	9526                	add	a0,a0,s1
    80006822:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006826:	fd043503          	ld	a0,-48(s0)
    8000682a:	fffff097          	auipc	ra,0xfffff
    8000682e:	990080e7          	jalr	-1648(ra) # 800051ba <fileclose>
    fileclose(wf);
    80006832:	fc843503          	ld	a0,-56(s0)
    80006836:	fffff097          	auipc	ra,0xfffff
    8000683a:	984080e7          	jalr	-1660(ra) # 800051ba <fileclose>
    return -1;
    8000683e:	57fd                	li	a5,-1
    80006840:	a805                	j	80006870 <sys_pipe+0x10c>
    if(fd0 >= 0)
    80006842:	fc442783          	lw	a5,-60(s0)
    80006846:	0007c863          	bltz	a5,80006856 <sys_pipe+0xf2>
      p->ofile[fd0] = 0;
    8000684a:	03c78513          	addi	a0,a5,60
    8000684e:	050e                	slli	a0,a0,0x3
    80006850:	9526                	add	a0,a0,s1
    80006852:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006856:	fd043503          	ld	a0,-48(s0)
    8000685a:	fffff097          	auipc	ra,0xfffff
    8000685e:	960080e7          	jalr	-1696(ra) # 800051ba <fileclose>
    fileclose(wf);
    80006862:	fc843503          	ld	a0,-56(s0)
    80006866:	fffff097          	auipc	ra,0xfffff
    8000686a:	954080e7          	jalr	-1708(ra) # 800051ba <fileclose>
    return -1;
    8000686e:	57fd                	li	a5,-1
}
    80006870:	853e                	mv	a0,a5
    80006872:	70e2                	ld	ra,56(sp)
    80006874:	7442                	ld	s0,48(sp)
    80006876:	74a2                	ld	s1,40(sp)
    80006878:	6121                	addi	sp,sp,64
    8000687a:	8082                	ret
    8000687c:	0000                	unimp
	...

0000000080006880 <kernelvec>:
    80006880:	7111                	addi	sp,sp,-256
    80006882:	e006                	sd	ra,0(sp)
    80006884:	e40a                	sd	sp,8(sp)
    80006886:	e80e                	sd	gp,16(sp)
    80006888:	ec12                	sd	tp,24(sp)
    8000688a:	f016                	sd	t0,32(sp)
    8000688c:	f41a                	sd	t1,40(sp)
    8000688e:	f81e                	sd	t2,48(sp)
    80006890:	fc22                	sd	s0,56(sp)
    80006892:	e0a6                	sd	s1,64(sp)
    80006894:	e4aa                	sd	a0,72(sp)
    80006896:	e8ae                	sd	a1,80(sp)
    80006898:	ecb2                	sd	a2,88(sp)
    8000689a:	f0b6                	sd	a3,96(sp)
    8000689c:	f4ba                	sd	a4,104(sp)
    8000689e:	f8be                	sd	a5,112(sp)
    800068a0:	fcc2                	sd	a6,120(sp)
    800068a2:	e146                	sd	a7,128(sp)
    800068a4:	e54a                	sd	s2,136(sp)
    800068a6:	e94e                	sd	s3,144(sp)
    800068a8:	ed52                	sd	s4,152(sp)
    800068aa:	f156                	sd	s5,160(sp)
    800068ac:	f55a                	sd	s6,168(sp)
    800068ae:	f95e                	sd	s7,176(sp)
    800068b0:	fd62                	sd	s8,184(sp)
    800068b2:	e1e6                	sd	s9,192(sp)
    800068b4:	e5ea                	sd	s10,200(sp)
    800068b6:	e9ee                	sd	s11,208(sp)
    800068b8:	edf2                	sd	t3,216(sp)
    800068ba:	f1f6                	sd	t4,224(sp)
    800068bc:	f5fa                	sd	t5,232(sp)
    800068be:	f9fe                	sd	t6,240(sp)
    800068c0:	b63fc0ef          	jal	ra,80003422 <kerneltrap>
    800068c4:	6082                	ld	ra,0(sp)
    800068c6:	6122                	ld	sp,8(sp)
    800068c8:	61c2                	ld	gp,16(sp)
    800068ca:	7282                	ld	t0,32(sp)
    800068cc:	7322                	ld	t1,40(sp)
    800068ce:	73c2                	ld	t2,48(sp)
    800068d0:	7462                	ld	s0,56(sp)
    800068d2:	6486                	ld	s1,64(sp)
    800068d4:	6526                	ld	a0,72(sp)
    800068d6:	65c6                	ld	a1,80(sp)
    800068d8:	6666                	ld	a2,88(sp)
    800068da:	7686                	ld	a3,96(sp)
    800068dc:	7726                	ld	a4,104(sp)
    800068de:	77c6                	ld	a5,112(sp)
    800068e0:	7866                	ld	a6,120(sp)
    800068e2:	688a                	ld	a7,128(sp)
    800068e4:	692a                	ld	s2,136(sp)
    800068e6:	69ca                	ld	s3,144(sp)
    800068e8:	6a6a                	ld	s4,152(sp)
    800068ea:	7a8a                	ld	s5,160(sp)
    800068ec:	7b2a                	ld	s6,168(sp)
    800068ee:	7bca                	ld	s7,176(sp)
    800068f0:	7c6a                	ld	s8,184(sp)
    800068f2:	6c8e                	ld	s9,192(sp)
    800068f4:	6d2e                	ld	s10,200(sp)
    800068f6:	6dce                	ld	s11,208(sp)
    800068f8:	6e6e                	ld	t3,216(sp)
    800068fa:	7e8e                	ld	t4,224(sp)
    800068fc:	7f2e                	ld	t5,232(sp)
    800068fe:	7fce                	ld	t6,240(sp)
    80006900:	6111                	addi	sp,sp,256
    80006902:	10200073          	sret
    80006906:	00000013          	nop
    8000690a:	00000013          	nop
    8000690e:	0001                	nop

0000000080006910 <timervec>:
    80006910:	34051573          	csrrw	a0,mscratch,a0
    80006914:	e10c                	sd	a1,0(a0)
    80006916:	e510                	sd	a2,8(a0)
    80006918:	e914                	sd	a3,16(a0)
    8000691a:	6d0c                	ld	a1,24(a0)
    8000691c:	7110                	ld	a2,32(a0)
    8000691e:	6194                	ld	a3,0(a1)
    80006920:	96b2                	add	a3,a3,a2
    80006922:	e194                	sd	a3,0(a1)
    80006924:	4589                	li	a1,2
    80006926:	14459073          	csrw	sip,a1
    8000692a:	6914                	ld	a3,16(a0)
    8000692c:	6510                	ld	a2,8(a0)
    8000692e:	610c                	ld	a1,0(a0)
    80006930:	34051573          	csrrw	a0,mscratch,a0
    80006934:	30200073          	mret
	...

000000008000693a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000693a:	1141                	addi	sp,sp,-16
    8000693c:	e422                	sd	s0,8(sp)
    8000693e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006940:	0c0007b7          	lui	a5,0xc000
    80006944:	4705                	li	a4,1
    80006946:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006948:	c3d8                	sw	a4,4(a5)
}
    8000694a:	6422                	ld	s0,8(sp)
    8000694c:	0141                	addi	sp,sp,16
    8000694e:	8082                	ret

0000000080006950 <plicinithart>:

void
plicinithart(void)
{
    80006950:	1141                	addi	sp,sp,-16
    80006952:	e406                	sd	ra,8(sp)
    80006954:	e022                	sd	s0,0(sp)
    80006956:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006958:	ffffb097          	auipc	ra,0xffffb
    8000695c:	072080e7          	jalr	114(ra) # 800019ca <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006960:	0085171b          	slliw	a4,a0,0x8
    80006964:	0c0027b7          	lui	a5,0xc002
    80006968:	97ba                	add	a5,a5,a4
    8000696a:	40200713          	li	a4,1026
    8000696e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006972:	00d5151b          	slliw	a0,a0,0xd
    80006976:	0c2017b7          	lui	a5,0xc201
    8000697a:	953e                	add	a0,a0,a5
    8000697c:	00052023          	sw	zero,0(a0)
}
    80006980:	60a2                	ld	ra,8(sp)
    80006982:	6402                	ld	s0,0(sp)
    80006984:	0141                	addi	sp,sp,16
    80006986:	8082                	ret

0000000080006988 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006988:	1141                	addi	sp,sp,-16
    8000698a:	e406                	sd	ra,8(sp)
    8000698c:	e022                	sd	s0,0(sp)
    8000698e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006990:	ffffb097          	auipc	ra,0xffffb
    80006994:	03a080e7          	jalr	58(ra) # 800019ca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006998:	00d5179b          	slliw	a5,a0,0xd
    8000699c:	0c201537          	lui	a0,0xc201
    800069a0:	953e                	add	a0,a0,a5
  return irq;
}
    800069a2:	4148                	lw	a0,4(a0)
    800069a4:	60a2                	ld	ra,8(sp)
    800069a6:	6402                	ld	s0,0(sp)
    800069a8:	0141                	addi	sp,sp,16
    800069aa:	8082                	ret

00000000800069ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800069ac:	1101                	addi	sp,sp,-32
    800069ae:	ec06                	sd	ra,24(sp)
    800069b0:	e822                	sd	s0,16(sp)
    800069b2:	e426                	sd	s1,8(sp)
    800069b4:	1000                	addi	s0,sp,32
    800069b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800069b8:	ffffb097          	auipc	ra,0xffffb
    800069bc:	012080e7          	jalr	18(ra) # 800019ca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800069c0:	00d5151b          	slliw	a0,a0,0xd
    800069c4:	0c2017b7          	lui	a5,0xc201
    800069c8:	97aa                	add	a5,a5,a0
    800069ca:	c3c4                	sw	s1,4(a5)
}
    800069cc:	60e2                	ld	ra,24(sp)
    800069ce:	6442                	ld	s0,16(sp)
    800069d0:	64a2                	ld	s1,8(sp)
    800069d2:	6105                	addi	sp,sp,32
    800069d4:	8082                	ret

00000000800069d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800069d6:	1141                	addi	sp,sp,-16
    800069d8:	e406                	sd	ra,8(sp)
    800069da:	e022                	sd	s0,0(sp)
    800069dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800069de:	479d                	li	a5,7
    800069e0:	06a7c963          	blt	a5,a0,80006a52 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800069e4:	00038797          	auipc	a5,0x38
    800069e8:	61c78793          	addi	a5,a5,1564 # 8003f000 <disk>
    800069ec:	00a78733          	add	a4,a5,a0
    800069f0:	6789                	lui	a5,0x2
    800069f2:	97ba                	add	a5,a5,a4
    800069f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800069f8:	e7ad                	bnez	a5,80006a62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800069fa:	00451793          	slli	a5,a0,0x4
    800069fe:	0003a717          	auipc	a4,0x3a
    80006a02:	60270713          	addi	a4,a4,1538 # 80041000 <disk+0x2000>
    80006a06:	6314                	ld	a3,0(a4)
    80006a08:	96be                	add	a3,a3,a5
    80006a0a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006a0e:	6314                	ld	a3,0(a4)
    80006a10:	96be                	add	a3,a3,a5
    80006a12:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006a16:	6314                	ld	a3,0(a4)
    80006a18:	96be                	add	a3,a3,a5
    80006a1a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006a1e:	6318                	ld	a4,0(a4)
    80006a20:	97ba                	add	a5,a5,a4
    80006a22:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006a26:	00038797          	auipc	a5,0x38
    80006a2a:	5da78793          	addi	a5,a5,1498 # 8003f000 <disk>
    80006a2e:	97aa                	add	a5,a5,a0
    80006a30:	6509                	lui	a0,0x2
    80006a32:	953e                	add	a0,a0,a5
    80006a34:	4785                	li	a5,1
    80006a36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006a3a:	0003a517          	auipc	a0,0x3a
    80006a3e:	5de50513          	addi	a0,a0,1502 # 80041018 <disk+0x2018>
    80006a42:	ffffc097          	auipc	ra,0xffffc
    80006a46:	de4080e7          	jalr	-540(ra) # 80002826 <wakeup>
}
    80006a4a:	60a2                	ld	ra,8(sp)
    80006a4c:	6402                	ld	s0,0(sp)
    80006a4e:	0141                	addi	sp,sp,16
    80006a50:	8082                	ret
    panic("free_desc 1");
    80006a52:	00002517          	auipc	a0,0x2
    80006a56:	d4e50513          	addi	a0,a0,-690 # 800087a0 <syscalls+0x358>
    80006a5a:	ffffa097          	auipc	ra,0xffffa
    80006a5e:	ad0080e7          	jalr	-1328(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006a62:	00002517          	auipc	a0,0x2
    80006a66:	d4e50513          	addi	a0,a0,-690 # 800087b0 <syscalls+0x368>
    80006a6a:	ffffa097          	auipc	ra,0xffffa
    80006a6e:	ac0080e7          	jalr	-1344(ra) # 8000052a <panic>

0000000080006a72 <virtio_disk_init>:
{
    80006a72:	1101                	addi	sp,sp,-32
    80006a74:	ec06                	sd	ra,24(sp)
    80006a76:	e822                	sd	s0,16(sp)
    80006a78:	e426                	sd	s1,8(sp)
    80006a7a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a7c:	00002597          	auipc	a1,0x2
    80006a80:	d4458593          	addi	a1,a1,-700 # 800087c0 <syscalls+0x378>
    80006a84:	0003a517          	auipc	a0,0x3a
    80006a88:	6a450513          	addi	a0,a0,1700 # 80041128 <disk+0x2128>
    80006a8c:	ffffa097          	auipc	ra,0xffffa
    80006a90:	0a6080e7          	jalr	166(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a94:	100017b7          	lui	a5,0x10001
    80006a98:	4398                	lw	a4,0(a5)
    80006a9a:	2701                	sext.w	a4,a4
    80006a9c:	747277b7          	lui	a5,0x74727
    80006aa0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006aa4:	0ef71163          	bne	a4,a5,80006b86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006aa8:	100017b7          	lui	a5,0x10001
    80006aac:	43dc                	lw	a5,4(a5)
    80006aae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006ab0:	4705                	li	a4,1
    80006ab2:	0ce79a63          	bne	a5,a4,80006b86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006ab6:	100017b7          	lui	a5,0x10001
    80006aba:	479c                	lw	a5,8(a5)
    80006abc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006abe:	4709                	li	a4,2
    80006ac0:	0ce79363          	bne	a5,a4,80006b86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006ac4:	100017b7          	lui	a5,0x10001
    80006ac8:	47d8                	lw	a4,12(a5)
    80006aca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006acc:	554d47b7          	lui	a5,0x554d4
    80006ad0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006ad4:	0af71963          	bne	a4,a5,80006b86 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ad8:	100017b7          	lui	a5,0x10001
    80006adc:	4705                	li	a4,1
    80006ade:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ae0:	470d                	li	a4,3
    80006ae2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006ae4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006ae6:	c7ffe737          	lui	a4,0xc7ffe
    80006aea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fbc75f>
    80006aee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006af0:	2701                	sext.w	a4,a4
    80006af2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006af4:	472d                	li	a4,11
    80006af6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006af8:	473d                	li	a4,15
    80006afa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006afc:	6705                	lui	a4,0x1
    80006afe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006b00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006b04:	5bdc                	lw	a5,52(a5)
    80006b06:	2781                	sext.w	a5,a5
  if(max == 0)
    80006b08:	c7d9                	beqz	a5,80006b96 <virtio_disk_init+0x124>
  if(max < NUM)
    80006b0a:	471d                	li	a4,7
    80006b0c:	08f77d63          	bgeu	a4,a5,80006ba6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b10:	100014b7          	lui	s1,0x10001
    80006b14:	47a1                	li	a5,8
    80006b16:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006b18:	6609                	lui	a2,0x2
    80006b1a:	4581                	li	a1,0
    80006b1c:	00038517          	auipc	a0,0x38
    80006b20:	4e450513          	addi	a0,a0,1252 # 8003f000 <disk>
    80006b24:	ffffa097          	auipc	ra,0xffffa
    80006b28:	1be080e7          	jalr	446(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006b2c:	00038717          	auipc	a4,0x38
    80006b30:	4d470713          	addi	a4,a4,1236 # 8003f000 <disk>
    80006b34:	00c75793          	srli	a5,a4,0xc
    80006b38:	2781                	sext.w	a5,a5
    80006b3a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006b3c:	0003a797          	auipc	a5,0x3a
    80006b40:	4c478793          	addi	a5,a5,1220 # 80041000 <disk+0x2000>
    80006b44:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006b46:	00038717          	auipc	a4,0x38
    80006b4a:	53a70713          	addi	a4,a4,1338 # 8003f080 <disk+0x80>
    80006b4e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006b50:	00039717          	auipc	a4,0x39
    80006b54:	4b070713          	addi	a4,a4,1200 # 80040000 <disk+0x1000>
    80006b58:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006b5a:	4705                	li	a4,1
    80006b5c:	00e78c23          	sb	a4,24(a5)
    80006b60:	00e78ca3          	sb	a4,25(a5)
    80006b64:	00e78d23          	sb	a4,26(a5)
    80006b68:	00e78da3          	sb	a4,27(a5)
    80006b6c:	00e78e23          	sb	a4,28(a5)
    80006b70:	00e78ea3          	sb	a4,29(a5)
    80006b74:	00e78f23          	sb	a4,30(a5)
    80006b78:	00e78fa3          	sb	a4,31(a5)
}
    80006b7c:	60e2                	ld	ra,24(sp)
    80006b7e:	6442                	ld	s0,16(sp)
    80006b80:	64a2                	ld	s1,8(sp)
    80006b82:	6105                	addi	sp,sp,32
    80006b84:	8082                	ret
    panic("could not find virtio disk");
    80006b86:	00002517          	auipc	a0,0x2
    80006b8a:	c4a50513          	addi	a0,a0,-950 # 800087d0 <syscalls+0x388>
    80006b8e:	ffffa097          	auipc	ra,0xffffa
    80006b92:	99c080e7          	jalr	-1636(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006b96:	00002517          	auipc	a0,0x2
    80006b9a:	c5a50513          	addi	a0,a0,-934 # 800087f0 <syscalls+0x3a8>
    80006b9e:	ffffa097          	auipc	ra,0xffffa
    80006ba2:	98c080e7          	jalr	-1652(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006ba6:	00002517          	auipc	a0,0x2
    80006baa:	c6a50513          	addi	a0,a0,-918 # 80008810 <syscalls+0x3c8>
    80006bae:	ffffa097          	auipc	ra,0xffffa
    80006bb2:	97c080e7          	jalr	-1668(ra) # 8000052a <panic>

0000000080006bb6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006bb6:	7119                	addi	sp,sp,-128
    80006bb8:	fc86                	sd	ra,120(sp)
    80006bba:	f8a2                	sd	s0,112(sp)
    80006bbc:	f4a6                	sd	s1,104(sp)
    80006bbe:	f0ca                	sd	s2,96(sp)
    80006bc0:	ecce                	sd	s3,88(sp)
    80006bc2:	e8d2                	sd	s4,80(sp)
    80006bc4:	e4d6                	sd	s5,72(sp)
    80006bc6:	e0da                	sd	s6,64(sp)
    80006bc8:	fc5e                	sd	s7,56(sp)
    80006bca:	f862                	sd	s8,48(sp)
    80006bcc:	f466                	sd	s9,40(sp)
    80006bce:	f06a                	sd	s10,32(sp)
    80006bd0:	ec6e                	sd	s11,24(sp)
    80006bd2:	0100                	addi	s0,sp,128
    80006bd4:	8aaa                	mv	s5,a0
    80006bd6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006bd8:	00c52c83          	lw	s9,12(a0)
    80006bdc:	001c9c9b          	slliw	s9,s9,0x1
    80006be0:	1c82                	slli	s9,s9,0x20
    80006be2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006be6:	0003a517          	auipc	a0,0x3a
    80006bea:	54250513          	addi	a0,a0,1346 # 80041128 <disk+0x2128>
    80006bee:	ffffa097          	auipc	ra,0xffffa
    80006bf2:	fd4080e7          	jalr	-44(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006bf6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006bf8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006bfa:	00038c17          	auipc	s8,0x38
    80006bfe:	406c0c13          	addi	s8,s8,1030 # 8003f000 <disk>
    80006c02:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006c04:	4b0d                	li	s6,3
    80006c06:	a0ad                	j	80006c70 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006c08:	00fc0733          	add	a4,s8,a5
    80006c0c:	975e                	add	a4,a4,s7
    80006c0e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006c12:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006c14:	0207c563          	bltz	a5,80006c3e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006c18:	2905                	addiw	s2,s2,1
    80006c1a:	0611                	addi	a2,a2,4
    80006c1c:	19690d63          	beq	s2,s6,80006db6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006c20:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006c22:	0003a717          	auipc	a4,0x3a
    80006c26:	3f670713          	addi	a4,a4,1014 # 80041018 <disk+0x2018>
    80006c2a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006c2c:	00074683          	lbu	a3,0(a4)
    80006c30:	fee1                	bnez	a3,80006c08 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006c32:	2785                	addiw	a5,a5,1
    80006c34:	0705                	addi	a4,a4,1
    80006c36:	fe979be3          	bne	a5,s1,80006c2c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006c3a:	57fd                	li	a5,-1
    80006c3c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006c3e:	01205d63          	blez	s2,80006c58 <virtio_disk_rw+0xa2>
    80006c42:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006c44:	000a2503          	lw	a0,0(s4)
    80006c48:	00000097          	auipc	ra,0x0
    80006c4c:	d8e080e7          	jalr	-626(ra) # 800069d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006c50:	2d85                	addiw	s11,s11,1
    80006c52:	0a11                	addi	s4,s4,4
    80006c54:	ffb918e3          	bne	s2,s11,80006c44 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c58:	0003a597          	auipc	a1,0x3a
    80006c5c:	4d058593          	addi	a1,a1,1232 # 80041128 <disk+0x2128>
    80006c60:	0003a517          	auipc	a0,0x3a
    80006c64:	3b850513          	addi	a0,a0,952 # 80041018 <disk+0x2018>
    80006c68:	ffffc097          	auipc	ra,0xffffc
    80006c6c:	a34080e7          	jalr	-1484(ra) # 8000269c <sleep>
  for(int i = 0; i < 3; i++){
    80006c70:	f8040a13          	addi	s4,s0,-128
{
    80006c74:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006c76:	894e                	mv	s2,s3
    80006c78:	b765                	j	80006c20 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006c7a:	0003a697          	auipc	a3,0x3a
    80006c7e:	3866b683          	ld	a3,902(a3) # 80041000 <disk+0x2000>
    80006c82:	96ba                	add	a3,a3,a4
    80006c84:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c88:	00038817          	auipc	a6,0x38
    80006c8c:	37880813          	addi	a6,a6,888 # 8003f000 <disk>
    80006c90:	0003a697          	auipc	a3,0x3a
    80006c94:	37068693          	addi	a3,a3,880 # 80041000 <disk+0x2000>
    80006c98:	6290                	ld	a2,0(a3)
    80006c9a:	963a                	add	a2,a2,a4
    80006c9c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006ca0:	0015e593          	ori	a1,a1,1
    80006ca4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006ca8:	f8842603          	lw	a2,-120(s0)
    80006cac:	628c                	ld	a1,0(a3)
    80006cae:	972e                	add	a4,a4,a1
    80006cb0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006cb4:	20050593          	addi	a1,a0,512
    80006cb8:	0592                	slli	a1,a1,0x4
    80006cba:	95c2                	add	a1,a1,a6
    80006cbc:	577d                	li	a4,-1
    80006cbe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006cc2:	00461713          	slli	a4,a2,0x4
    80006cc6:	6290                	ld	a2,0(a3)
    80006cc8:	963a                	add	a2,a2,a4
    80006cca:	03078793          	addi	a5,a5,48
    80006cce:	97c2                	add	a5,a5,a6
    80006cd0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006cd2:	629c                	ld	a5,0(a3)
    80006cd4:	97ba                	add	a5,a5,a4
    80006cd6:	4605                	li	a2,1
    80006cd8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006cda:	629c                	ld	a5,0(a3)
    80006cdc:	97ba                	add	a5,a5,a4
    80006cde:	4809                	li	a6,2
    80006ce0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006ce4:	629c                	ld	a5,0(a3)
    80006ce6:	973e                	add	a4,a4,a5
    80006ce8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006cec:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006cf0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006cf4:	6698                	ld	a4,8(a3)
    80006cf6:	00275783          	lhu	a5,2(a4)
    80006cfa:	8b9d                	andi	a5,a5,7
    80006cfc:	0786                	slli	a5,a5,0x1
    80006cfe:	97ba                	add	a5,a5,a4
    80006d00:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006d04:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d08:	6698                	ld	a4,8(a3)
    80006d0a:	00275783          	lhu	a5,2(a4)
    80006d0e:	2785                	addiw	a5,a5,1
    80006d10:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d14:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d18:	100017b7          	lui	a5,0x10001
    80006d1c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006d20:	004aa783          	lw	a5,4(s5)
    80006d24:	02c79163          	bne	a5,a2,80006d46 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006d28:	0003a917          	auipc	s2,0x3a
    80006d2c:	40090913          	addi	s2,s2,1024 # 80041128 <disk+0x2128>
  while(b->disk == 1) {
    80006d30:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006d32:	85ca                	mv	a1,s2
    80006d34:	8556                	mv	a0,s5
    80006d36:	ffffc097          	auipc	ra,0xffffc
    80006d3a:	966080e7          	jalr	-1690(ra) # 8000269c <sleep>
  while(b->disk == 1) {
    80006d3e:	004aa783          	lw	a5,4(s5)
    80006d42:	fe9788e3          	beq	a5,s1,80006d32 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006d46:	f8042903          	lw	s2,-128(s0)
    80006d4a:	20090793          	addi	a5,s2,512
    80006d4e:	00479713          	slli	a4,a5,0x4
    80006d52:	00038797          	auipc	a5,0x38
    80006d56:	2ae78793          	addi	a5,a5,686 # 8003f000 <disk>
    80006d5a:	97ba                	add	a5,a5,a4
    80006d5c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006d60:	0003a997          	auipc	s3,0x3a
    80006d64:	2a098993          	addi	s3,s3,672 # 80041000 <disk+0x2000>
    80006d68:	00491713          	slli	a4,s2,0x4
    80006d6c:	0009b783          	ld	a5,0(s3)
    80006d70:	97ba                	add	a5,a5,a4
    80006d72:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d76:	854a                	mv	a0,s2
    80006d78:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d7c:	00000097          	auipc	ra,0x0
    80006d80:	c5a080e7          	jalr	-934(ra) # 800069d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d84:	8885                	andi	s1,s1,1
    80006d86:	f0ed                	bnez	s1,80006d68 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d88:	0003a517          	auipc	a0,0x3a
    80006d8c:	3a050513          	addi	a0,a0,928 # 80041128 <disk+0x2128>
    80006d90:	ffffa097          	auipc	ra,0xffffa
    80006d94:	ef8080e7          	jalr	-264(ra) # 80000c88 <release>
}
    80006d98:	70e6                	ld	ra,120(sp)
    80006d9a:	7446                	ld	s0,112(sp)
    80006d9c:	74a6                	ld	s1,104(sp)
    80006d9e:	7906                	ld	s2,96(sp)
    80006da0:	69e6                	ld	s3,88(sp)
    80006da2:	6a46                	ld	s4,80(sp)
    80006da4:	6aa6                	ld	s5,72(sp)
    80006da6:	6b06                	ld	s6,64(sp)
    80006da8:	7be2                	ld	s7,56(sp)
    80006daa:	7c42                	ld	s8,48(sp)
    80006dac:	7ca2                	ld	s9,40(sp)
    80006dae:	7d02                	ld	s10,32(sp)
    80006db0:	6de2                	ld	s11,24(sp)
    80006db2:	6109                	addi	sp,sp,128
    80006db4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006db6:	f8042503          	lw	a0,-128(s0)
    80006dba:	20050793          	addi	a5,a0,512
    80006dbe:	0792                	slli	a5,a5,0x4
  if(write)
    80006dc0:	00038817          	auipc	a6,0x38
    80006dc4:	24080813          	addi	a6,a6,576 # 8003f000 <disk>
    80006dc8:	00f80733          	add	a4,a6,a5
    80006dcc:	01a036b3          	snez	a3,s10
    80006dd0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006dd4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006dd8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006ddc:	7679                	lui	a2,0xffffe
    80006dde:	963e                	add	a2,a2,a5
    80006de0:	0003a697          	auipc	a3,0x3a
    80006de4:	22068693          	addi	a3,a3,544 # 80041000 <disk+0x2000>
    80006de8:	6298                	ld	a4,0(a3)
    80006dea:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006dec:	0a878593          	addi	a1,a5,168
    80006df0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006df2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006df4:	6298                	ld	a4,0(a3)
    80006df6:	9732                	add	a4,a4,a2
    80006df8:	45c1                	li	a1,16
    80006dfa:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006dfc:	6298                	ld	a4,0(a3)
    80006dfe:	9732                	add	a4,a4,a2
    80006e00:	4585                	li	a1,1
    80006e02:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006e06:	f8442703          	lw	a4,-124(s0)
    80006e0a:	628c                	ld	a1,0(a3)
    80006e0c:	962e                	add	a2,a2,a1
    80006e0e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffbc00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006e12:	0712                	slli	a4,a4,0x4
    80006e14:	6290                	ld	a2,0(a3)
    80006e16:	963a                	add	a2,a2,a4
    80006e18:	058a8593          	addi	a1,s5,88
    80006e1c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006e1e:	6294                	ld	a3,0(a3)
    80006e20:	96ba                	add	a3,a3,a4
    80006e22:	40000613          	li	a2,1024
    80006e26:	c690                	sw	a2,8(a3)
  if(write)
    80006e28:	e40d19e3          	bnez	s10,80006c7a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e2c:	0003a697          	auipc	a3,0x3a
    80006e30:	1d46b683          	ld	a3,468(a3) # 80041000 <disk+0x2000>
    80006e34:	96ba                	add	a3,a3,a4
    80006e36:	4609                	li	a2,2
    80006e38:	00c69623          	sh	a2,12(a3)
    80006e3c:	b5b1                	j	80006c88 <virtio_disk_rw+0xd2>

0000000080006e3e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006e3e:	1101                	addi	sp,sp,-32
    80006e40:	ec06                	sd	ra,24(sp)
    80006e42:	e822                	sd	s0,16(sp)
    80006e44:	e426                	sd	s1,8(sp)
    80006e46:	e04a                	sd	s2,0(sp)
    80006e48:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e4a:	0003a517          	auipc	a0,0x3a
    80006e4e:	2de50513          	addi	a0,a0,734 # 80041128 <disk+0x2128>
    80006e52:	ffffa097          	auipc	ra,0xffffa
    80006e56:	d70080e7          	jalr	-656(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e5a:	10001737          	lui	a4,0x10001
    80006e5e:	533c                	lw	a5,96(a4)
    80006e60:	8b8d                	andi	a5,a5,3
    80006e62:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006e64:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006e68:	0003a797          	auipc	a5,0x3a
    80006e6c:	19878793          	addi	a5,a5,408 # 80041000 <disk+0x2000>
    80006e70:	6b94                	ld	a3,16(a5)
    80006e72:	0207d703          	lhu	a4,32(a5)
    80006e76:	0026d783          	lhu	a5,2(a3)
    80006e7a:	06f70163          	beq	a4,a5,80006edc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e7e:	00038917          	auipc	s2,0x38
    80006e82:	18290913          	addi	s2,s2,386 # 8003f000 <disk>
    80006e86:	0003a497          	auipc	s1,0x3a
    80006e8a:	17a48493          	addi	s1,s1,378 # 80041000 <disk+0x2000>
    __sync_synchronize();
    80006e8e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e92:	6898                	ld	a4,16(s1)
    80006e94:	0204d783          	lhu	a5,32(s1)
    80006e98:	8b9d                	andi	a5,a5,7
    80006e9a:	078e                	slli	a5,a5,0x3
    80006e9c:	97ba                	add	a5,a5,a4
    80006e9e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ea0:	20078713          	addi	a4,a5,512
    80006ea4:	0712                	slli	a4,a4,0x4
    80006ea6:	974a                	add	a4,a4,s2
    80006ea8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006eac:	e731                	bnez	a4,80006ef8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006eae:	20078793          	addi	a5,a5,512
    80006eb2:	0792                	slli	a5,a5,0x4
    80006eb4:	97ca                	add	a5,a5,s2
    80006eb6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006eb8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006ebc:	ffffc097          	auipc	ra,0xffffc
    80006ec0:	96a080e7          	jalr	-1686(ra) # 80002826 <wakeup>

    disk.used_idx += 1;
    80006ec4:	0204d783          	lhu	a5,32(s1)
    80006ec8:	2785                	addiw	a5,a5,1
    80006eca:	17c2                	slli	a5,a5,0x30
    80006ecc:	93c1                	srli	a5,a5,0x30
    80006ece:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ed2:	6898                	ld	a4,16(s1)
    80006ed4:	00275703          	lhu	a4,2(a4)
    80006ed8:	faf71be3          	bne	a4,a5,80006e8e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006edc:	0003a517          	auipc	a0,0x3a
    80006ee0:	24c50513          	addi	a0,a0,588 # 80041128 <disk+0x2128>
    80006ee4:	ffffa097          	auipc	ra,0xffffa
    80006ee8:	da4080e7          	jalr	-604(ra) # 80000c88 <release>
}
    80006eec:	60e2                	ld	ra,24(sp)
    80006eee:	6442                	ld	s0,16(sp)
    80006ef0:	64a2                	ld	s1,8(sp)
    80006ef2:	6902                	ld	s2,0(sp)
    80006ef4:	6105                	addi	sp,sp,32
    80006ef6:	8082                	ret
      panic("virtio_disk_intr status");
    80006ef8:	00002517          	auipc	a0,0x2
    80006efc:	93850513          	addi	a0,a0,-1736 # 80008830 <syscalls+0x3e8>
    80006f00:	ffff9097          	auipc	ra,0xffff9
    80006f04:	62a080e7          	jalr	1578(ra) # 8000052a <panic>
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
