
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
    80000068:	84c78793          	addi	a5,a5,-1972 # 800068b0 <timervec>
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
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	792080e7          	jalr	1938(ra) # 800028b0 <either_copyin>
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
    800001b6:	850080e7          	jalr	-1968(ra) # 80001a02 <myproc>
    800001ba:	4d5c                	lw	a5,28(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	392080e7          	jalr	914(ra) # 80002554 <sleep>
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
    80000202:	65a080e7          	jalr	1626(ra) # 80002858 <either_copyout>
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
    800002e2:	62a080e7          	jalr	1578(ra) # 80002908 <procdump>
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
    80000436:	2ac080e7          	jalr	684(ra) # 800026de <wakeup>
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
    80000468:	4e478793          	addi	a5,a5,1252 # 8003d948 <devsw>
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
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	e60080e7          	jalr	-416(ra) # 800026de <wakeup>
    
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
    8000090e:	c4a080e7          	jalr	-950(ra) # 80002554 <sleep>
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
    80000b60:	e8a080e7          	jalr	-374(ra) # 800019e6 <mycpu>
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
    80000b92:	e58080e7          	jalr	-424(ra) # 800019e6 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e4c080e7          	jalr	-436(ra) # 800019e6 <mycpu>
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
    80000bb6:	e34080e7          	jalr	-460(ra) # 800019e6 <mycpu>
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
    80000bf6:	df4080e7          	jalr	-524(ra) # 800019e6 <mycpu>
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
    80000c34:	db6080e7          	jalr	-586(ra) # 800019e6 <mycpu>
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
    printf("PANIC-%s\n",lk->name);
    80000cc0:	648c                	ld	a1,8(s1)
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3e650513          	addi	a0,a0,998 # 800080a8 <digits+0x68>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	8aa080e7          	jalr	-1878(ra) # 80000574 <printf>
    panic("release");
    80000cd2:	00007517          	auipc	a0,0x7
    80000cd6:	3e650513          	addi	a0,a0,998 # 800080b8 <digits+0x78>
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
    80000e9c:	b3e080e7          	jalr	-1218(ra) # 800019d6 <cpuid>
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
    80000eb8:	b22080e7          	jalr	-1246(ra) # 800019d6 <cpuid>
    80000ebc:	85aa                	mv	a1,a0
    80000ebe:	00007517          	auipc	a0,0x7
    80000ec2:	21a50513          	addi	a0,a0,538 # 800080d8 <digits+0x98>
    80000ec6:	fffff097          	auipc	ra,0xfffff
    80000eca:	6ae080e7          	jalr	1710(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000ece:	00000097          	auipc	ra,0x0
    80000ed2:	0d8080e7          	jalr	216(ra) # 80000fa6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed6:	00002097          	auipc	ra,0x2
    80000eda:	1ec080e7          	jalr	492(ra) # 800030c2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00006097          	auipc	ra,0x6
    80000ee2:	a12080e7          	jalr	-1518(ra) # 800068f0 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	326080e7          	jalr	806(ra) # 8000220c <scheduler>
    consoleinit();
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	54e080e7          	jalr	1358(ra) # 8000043c <consoleinit>
    printfinit();
    80000ef6:	00000097          	auipc	ra,0x0
    80000efa:	85e080e7          	jalr	-1954(ra) # 80000754 <printfinit>
    printf("\n");
    80000efe:	00007517          	auipc	a0,0x7
    80000f02:	1ea50513          	addi	a0,a0,490 # 800080e8 <digits+0xa8>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	66e080e7          	jalr	1646(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	1b250513          	addi	a0,a0,434 # 800080c0 <digits+0x80>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	65e080e7          	jalr	1630(ra) # 80000574 <printf>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	1ca50513          	addi	a0,a0,458 # 800080e8 <digits+0xa8>
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
    80000f52:	14c080e7          	jalr	332(ra) # 8000309a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	16c080e7          	jalr	364(ra) # 800030c2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00006097          	auipc	ra,0x6
    80000f62:	97c080e7          	jalr	-1668(ra) # 800068da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00006097          	auipc	ra,0x6
    80000f6a:	98a080e7          	jalr	-1654(ra) # 800068f0 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00003097          	auipc	ra,0x3
    80000f72:	aa4080e7          	jalr	-1372(ra) # 80003a12 <binit>
    iinit();         // inode cache
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	136080e7          	jalr	310(ra) # 800040ac <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	0e4080e7          	jalr	228(ra) # 80005062 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00006097          	auipc	ra,0x6
    80000f8a:	a8c080e7          	jalr	-1396(ra) # 80006a12 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	e76080e7          	jalr	-394(ra) # 80001e04 <userinit>
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
    80000ff4:	10050513          	addi	a0,a0,256 # 800080f0 <digits+0xb0>
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
    80001118:	fe450513          	addi	a0,a0,-28 # 800080f8 <digits+0xb8>
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
    80001164:	fa050513          	addi	a0,a0,-96 # 80008100 <digits+0xc0>
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
    80001234:	64c080e7          	jalr	1612(ra) # 8000187c <proc_mapstacks>
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
    800012b0:	e5c50513          	addi	a0,a0,-420 # 80008108 <digits+0xc8>
    800012b4:	fffff097          	auipc	ra,0xfffff
    800012b8:	276080e7          	jalr	630(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e6450513          	addi	a0,a0,-412 # 80008120 <digits+0xe0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	266080e7          	jalr	614(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e6450513          	addi	a0,a0,-412 # 80008130 <digits+0xf0>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	256080e7          	jalr	598(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e6c50513          	addi	a0,a0,-404 # 80008148 <digits+0x108>
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
    800013be:	da650513          	addi	a0,a0,-602 # 80008160 <digits+0x120>
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
    80001500:	c8450513          	addi	a0,a0,-892 # 80008180 <digits+0x140>
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
    800015dc:	bb850513          	addi	a0,a0,-1096 # 80008190 <digits+0x150>
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	f4a080e7          	jalr	-182(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	bc850513          	addi	a0,a0,-1080 # 800081b0 <digits+0x170>
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
    80001656:	b7e50513          	addi	a0,a0,-1154 # 800081d0 <digits+0x190>
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
// TODO: allocthread, etc

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
    8000183e:	e915                	bnez	a0,80001872 <freethread+0x42>
        kfree((void *)t->kstack);
    t->kstack = 0;
    80001840:	0404b023          	sd	zero,64(s1)
    if(t->trapframe)
    80001844:	64a8                	ld	a0,72(s1)
    80001846:	c509                	beqz	a0,80001850 <freethread+0x20>
      kfree((void*)t->trapframe);
    80001848:	fffff097          	auipc	ra,0xfffff
    8000184c:	18e080e7          	jalr	398(ra) # 800009d6 <kfree>
    t->trapframe = 0;
    80001850:	0404b423          	sd	zero,72(s1)
    t->tid = 0;
    80001854:	0204a823          	sw	zero,48(s1)
    t->proc = 0;
    80001858:	0204bc23          	sd	zero,56(s1)
    t->chan = 0;
    8000185c:	0204b023          	sd	zero,32(s1)
    t->terminated = 0;
    80001860:	0204a423          	sw	zero,40(s1)
    t->state = UNUSED_T;
    80001864:	0004ac23          	sw	zero,24(s1)
}
    80001868:	60e2                	ld	ra,24(sp)
    8000186a:	6442                	ld	s0,16(sp)
    8000186c:	64a2                	ld	s1,8(sp)
    8000186e:	6105                	addi	sp,sp,32
    80001870:	8082                	ret
        kfree((void *)t->kstack);
    80001872:	fffff097          	auipc	ra,0xfffff
    80001876:	164080e7          	jalr	356(ra) # 800009d6 <kfree>
    8000187a:	b7d9                	j	80001840 <freethread+0x10>

000000008000187c <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000187c:	715d                	addi	sp,sp,-80
    8000187e:	e486                	sd	ra,72(sp)
    80001880:	e0a2                	sd	s0,64(sp)
    80001882:	fc26                	sd	s1,56(sp)
    80001884:	f84a                	sd	s2,48(sp)
    80001886:	f44e                	sd	s3,40(sp)
    80001888:	f052                	sd	s4,32(sp)
    8000188a:	ec56                	sd	s5,24(sp)
    8000188c:	e85a                	sd	s6,16(sp)
    8000188e:	e45e                	sd	s7,8(sp)
    80001890:	e062                	sd	s8,0(sp)
    80001892:	0880                	addi	s0,sp,80
    80001894:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001896:	00010497          	auipc	s1,0x10
    8000189a:	e6a48493          	addi	s1,s1,-406 # 80011700 <proc>
    uint64 va = KSTACK((int) (p - proc));
    8000189e:	8c26                	mv	s8,s1
    800018a0:	00006b97          	auipc	s7,0x6
    800018a4:	760b8b93          	addi	s7,s7,1888 # 80008000 <etext>
    800018a8:	04000937          	lui	s2,0x4000
    800018ac:	197d                	addi	s2,s2,-1
    800018ae:	0932                	slli	s2,s2,0xc
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b0:	6a05                	lui	s4,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b2:	880a0b13          	addi	s6,s4,-1920 # 880 <_entry-0x7ffff780>
    800018b6:	00032a97          	auipc	s5,0x32
    800018ba:	e4aa8a93          	addi	s5,s5,-438 # 80033700 <tickslock>
    char *pa = kalloc();
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	214080e7          	jalr	532(ra) # 80000ad2 <kalloc>
    800018c6:	862a                	mv	a2,a0
    if(pa == 0)
    800018c8:	c139                	beqz	a0,8000190e <proc_mapstacks+0x92>
    uint64 va = KSTACK((int) (p - proc));
    800018ca:	418485b3          	sub	a1,s1,s8
    800018ce:	859d                	srai	a1,a1,0x7
    800018d0:	000bb783          	ld	a5,0(s7)
    800018d4:	02f585b3          	mul	a1,a1,a5
    800018d8:	2585                	addiw	a1,a1,1
    800018da:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018de:	4719                	li	a4,6
    800018e0:	86d2                	mv	a3,s4
    800018e2:	40b905b3          	sub	a1,s2,a1
    800018e6:	854e                	mv	a0,s3
    800018e8:	00000097          	auipc	ra,0x0
    800018ec:	858080e7          	jalr	-1960(ra) # 80001140 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018f0:	94da                	add	s1,s1,s6
    800018f2:	fd5496e3          	bne	s1,s5,800018be <proc_mapstacks+0x42>
}
    800018f6:	60a6                	ld	ra,72(sp)
    800018f8:	6406                	ld	s0,64(sp)
    800018fa:	74e2                	ld	s1,56(sp)
    800018fc:	7942                	ld	s2,48(sp)
    800018fe:	79a2                	ld	s3,40(sp)
    80001900:	7a02                	ld	s4,32(sp)
    80001902:	6ae2                	ld	s5,24(sp)
    80001904:	6b42                	ld	s6,16(sp)
    80001906:	6ba2                	ld	s7,8(sp)
    80001908:	6c02                	ld	s8,0(sp)
    8000190a:	6161                	addi	sp,sp,80
    8000190c:	8082                	ret
      panic("kalloc");
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	8d250513          	addi	a0,a0,-1838 # 800081e0 <digits+0x1a0>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	c14080e7          	jalr	-1004(ra) # 8000052a <panic>

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
    80001934:	00007597          	auipc	a1,0x7
    80001938:	8b458593          	addi	a1,a1,-1868 # 800081e8 <digits+0x1a8>
    8000193c:	00010517          	auipc	a0,0x10
    80001940:	96450513          	addi	a0,a0,-1692 # 800112a0 <pid_lock>
    80001944:	fffff097          	auipc	ra,0xfffff
    80001948:	1ee080e7          	jalr	494(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000194c:	00007597          	auipc	a1,0x7
    80001950:	8a458593          	addi	a1,a1,-1884 # 800081f0 <digits+0x1b0>
    80001954:	00010517          	auipc	a0,0x10
    80001958:	96450513          	addi	a0,a0,-1692 # 800112b8 <wait_lock>
    8000195c:	fffff097          	auipc	ra,0xfffff
    80001960:	1d6080e7          	jalr	470(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	00010917          	auipc	s2,0x10
    80001968:	61490913          	addi	s2,s2,1556 # 80011f78 <proc+0x878>
    8000196c:	00032b97          	auipc	s7,0x32
    80001970:	60cb8b93          	addi	s7,s7,1548 # 80033f78 <bcache+0x860>
    initlock(&p->lock, "proc");
    80001974:	7afd                	lui	s5,0xfffff
    80001976:	788a8a93          	addi	s5,s5,1928 # fffffffffffff788 <end+0xffffffff7ffbd788>
    8000197a:	00007b17          	auipc	s6,0x7
    8000197e:	886b0b13          	addi	s6,s6,-1914 # 80008200 <digits+0x1c0>
      initlock(&t->lock, "thread");
    80001982:	00007997          	auipc	s3,0x7
    80001986:	88698993          	addi	s3,s3,-1914 # 80008208 <digits+0x1c8>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198a:	6a05                	lui	s4,0x1
    8000198c:	880a0a13          	addi	s4,s4,-1920 # 880 <_entry-0x7ffff780>
    80001990:	a021                	j	80001998 <procinit+0x7a>
    80001992:	9952                	add	s2,s2,s4
    80001994:	03790663          	beq	s2,s7,800019c0 <procinit+0xa2>
    initlock(&p->lock, "proc");
    80001998:	85da                	mv	a1,s6
    8000199a:	01590533          	add	a0,s2,s5
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	194080e7          	jalr	404(ra) # 80000b32 <initlock>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800019a6:	a0090493          	addi	s1,s2,-1536
      initlock(&t->lock, "thread");
    800019aa:	85ce                	mv	a1,s3
    800019ac:	8526                	mv	a0,s1
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	184080e7          	jalr	388(ra) # 80000b32 <initlock>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800019b6:	0c048493          	addi	s1,s1,192
    800019ba:	ff2498e3          	bne	s1,s2,800019aa <procinit+0x8c>
    800019be:	bfd1                	j	80001992 <procinit+0x74>
}
    800019c0:	60a6                	ld	ra,72(sp)
    800019c2:	6406                	ld	s0,64(sp)
    800019c4:	74e2                	ld	s1,56(sp)
    800019c6:	7942                	ld	s2,48(sp)
    800019c8:	79a2                	ld	s3,40(sp)
    800019ca:	7a02                	ld	s4,32(sp)
    800019cc:	6ae2                	ld	s5,24(sp)
    800019ce:	6b42                	ld	s6,16(sp)
    800019d0:	6ba2                	ld	s7,8(sp)
    800019d2:	6161                	addi	sp,sp,80
    800019d4:	8082                	ret

00000000800019d6 <cpuid>:
{
    800019d6:	1141                	addi	sp,sp,-16
    800019d8:	e422                	sd	s0,8(sp)
    800019da:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019dc:	8512                	mv	a0,tp
}
    800019de:	2501                	sext.w	a0,a0
    800019e0:	6422                	ld	s0,8(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret

00000000800019e6 <mycpu>:
mycpu(void) {
    800019e6:	1141                	addi	sp,sp,-16
    800019e8:	e422                	sd	s0,8(sp)
    800019ea:	0800                	addi	s0,sp,16
    800019ec:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019ee:	2781                	sext.w	a5,a5
    800019f0:	079e                	slli	a5,a5,0x7
}
    800019f2:	00010517          	auipc	a0,0x10
    800019f6:	8de50513          	addi	a0,a0,-1826 # 800112d0 <cpus>
    800019fa:	953e                	add	a0,a0,a5
    800019fc:	6422                	ld	s0,8(sp)
    800019fe:	0141                	addi	sp,sp,16
    80001a00:	8082                	ret

0000000080001a02 <myproc>:
myproc(void) {
    80001a02:	1101                	addi	sp,sp,-32
    80001a04:	ec06                	sd	ra,24(sp)
    80001a06:	e822                	sd	s0,16(sp)
    80001a08:	e426                	sd	s1,8(sp)
    80001a0a:	1000                	addi	s0,sp,32
  push_off();
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	16a080e7          	jalr	362(ra) # 80000b76 <push_off>
    80001a14:	8792                	mv	a5,tp
  struct proc *p = c->thread->proc; //ADDED Q3
    80001a16:	2781                	sext.w	a5,a5
    80001a18:	079e                	slli	a5,a5,0x7
    80001a1a:	00010717          	auipc	a4,0x10
    80001a1e:	88670713          	addi	a4,a4,-1914 # 800112a0 <pid_lock>
    80001a22:	97ba                	add	a5,a5,a4
    80001a24:	7b9c                	ld	a5,48(a5)
    80001a26:	7f84                	ld	s1,56(a5)
  pop_off();
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	200080e7          	jalr	512(ra) # 80000c28 <pop_off>
}
    80001a30:	8526                	mv	a0,s1
    80001a32:	60e2                	ld	ra,24(sp)
    80001a34:	6442                	ld	s0,16(sp)
    80001a36:	64a2                	ld	s1,8(sp)
    80001a38:	6105                	addi	sp,sp,32
    80001a3a:	8082                	ret

0000000080001a3c <mythread>:
mythread(void) {
    80001a3c:	1101                	addi	sp,sp,-32
    80001a3e:	ec06                	sd	ra,24(sp)
    80001a40:	e822                	sd	s0,16(sp)
    80001a42:	e426                	sd	s1,8(sp)
    80001a44:	1000                	addi	s0,sp,32
  push_off();
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	130080e7          	jalr	304(ra) # 80000b76 <push_off>
    80001a4e:	8792                	mv	a5,tp
  struct thread *t = c->thread;
    80001a50:	2781                	sext.w	a5,a5
    80001a52:	079e                	slli	a5,a5,0x7
    80001a54:	00010717          	auipc	a4,0x10
    80001a58:	84c70713          	addi	a4,a4,-1972 # 800112a0 <pid_lock>
    80001a5c:	97ba                	add	a5,a5,a4
    80001a5e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	1c8080e7          	jalr	456(ra) # 80000c28 <pop_off>
}
    80001a68:	8526                	mv	a0,s1
    80001a6a:	60e2                	ld	ra,24(sp)
    80001a6c:	6442                	ld	s0,16(sp)
    80001a6e:	64a2                	ld	s1,8(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a74:	1141                	addi	sp,sp,-16
    80001a76:	e406                	sd	ra,8(sp)
    80001a78:	e022                	sd	s0,0(sp)
    80001a7a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding t->lock from scheduler.
  release(&mythread()->lock); // ADDED Q3
    80001a7c:	00000097          	auipc	ra,0x0
    80001a80:	fc0080e7          	jalr	-64(ra) # 80001a3c <mythread>
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	204080e7          	jalr	516(ra) # 80000c88 <release>

  if (first) {
    80001a8c:	00007797          	auipc	a5,0x7
    80001a90:	da47a783          	lw	a5,-604(a5) # 80008830 <first.1>
    80001a94:	eb89                	bnez	a5,80001aa6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a96:	00001097          	auipc	ra,0x1
    80001a9a:	644080e7          	jalr	1604(ra) # 800030da <usertrapret>
}
    80001a9e:	60a2                	ld	ra,8(sp)
    80001aa0:	6402                	ld	s0,0(sp)
    80001aa2:	0141                	addi	sp,sp,16
    80001aa4:	8082                	ret
    first = 0;
    80001aa6:	00007797          	auipc	a5,0x7
    80001aaa:	d807a523          	sw	zero,-630(a5) # 80008830 <first.1>
    fsinit(ROOTDEV);
    80001aae:	4505                	li	a0,1
    80001ab0:	00002097          	auipc	ra,0x2
    80001ab4:	57c080e7          	jalr	1404(ra) # 8000402c <fsinit>
    80001ab8:	bff9                	j	80001a96 <forkret+0x22>

0000000080001aba <allocpid>:
allocpid() {
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	e04a                	sd	s2,0(sp)
    80001ac4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ac6:	0000f917          	auipc	s2,0xf
    80001aca:	7da90913          	addi	s2,s2,2010 # 800112a0 <pid_lock>
    80001ace:	854a                	mv	a0,s2
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	0f2080e7          	jalr	242(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001ad8:	00007797          	auipc	a5,0x7
    80001adc:	d6078793          	addi	a5,a5,-672 # 80008838 <nextpid>
    80001ae0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae2:	0014871b          	addiw	a4,s1,1
    80001ae6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ae8:	854a                	mv	a0,s2
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	19e080e7          	jalr	414(ra) # 80000c88 <release>
}
    80001af2:	8526                	mv	a0,s1
    80001af4:	60e2                	ld	ra,24(sp)
    80001af6:	6442                	ld	s0,16(sp)
    80001af8:	64a2                	ld	s1,8(sp)
    80001afa:	6902                	ld	s2,0(sp)
    80001afc:	6105                	addi	sp,sp,32
    80001afe:	8082                	ret

0000000080001b00 <alloctid>:
alloctid() {
    80001b00:	1101                	addi	sp,sp,-32
    80001b02:	ec06                	sd	ra,24(sp)
    80001b04:	e822                	sd	s0,16(sp)
    80001b06:	e426                	sd	s1,8(sp)
    80001b08:	e04a                	sd	s2,0(sp)
    80001b0a:	1000                	addi	s0,sp,32
  acquire(&tid_lock);
    80001b0c:	00010917          	auipc	s2,0x10
    80001b10:	bc490913          	addi	s2,s2,-1084 # 800116d0 <tid_lock>
    80001b14:	854a                	mv	a0,s2
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	0ac080e7          	jalr	172(ra) # 80000bc2 <acquire>
  tid = nexttid;
    80001b1e:	00007797          	auipc	a5,0x7
    80001b22:	d1678793          	addi	a5,a5,-746 # 80008834 <nexttid>
    80001b26:	4384                	lw	s1,0(a5)
  nexttid = nexttid + 1;
    80001b28:	0014871b          	addiw	a4,s1,1
    80001b2c:	c398                	sw	a4,0(a5)
  release(&tid_lock);
    80001b2e:	854a                	mv	a0,s2
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	158080e7          	jalr	344(ra) # 80000c88 <release>
}
    80001b38:	8526                	mv	a0,s1
    80001b3a:	60e2                	ld	ra,24(sp)
    80001b3c:	6442                	ld	s0,16(sp)
    80001b3e:	64a2                	ld	s1,8(sp)
    80001b40:	6902                	ld	s2,0(sp)
    80001b42:	6105                	addi	sp,sp,32
    80001b44:	8082                	ret

0000000080001b46 <proc_pagetable>:
{
    80001b46:	1101                	addi	sp,sp,-32
    80001b48:	ec06                	sd	ra,24(sp)
    80001b4a:	e822                	sd	s0,16(sp)
    80001b4c:	e426                	sd	s1,8(sp)
    80001b4e:	e04a                	sd	s2,0(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	7d6080e7          	jalr	2006(ra) # 8000132a <uvmcreate>
    80001b5c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b5e:	c121                	beqz	a0,80001b9e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b60:	4729                	li	a4,10
    80001b62:	00005697          	auipc	a3,0x5
    80001b66:	49e68693          	addi	a3,a3,1182 # 80007000 <_trampoline>
    80001b6a:	6605                	lui	a2,0x1
    80001b6c:	040005b7          	lui	a1,0x4000
    80001b70:	15fd                	addi	a1,a1,-1
    80001b72:	05b2                	slli	a1,a1,0xc
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	53e080e7          	jalr	1342(ra) # 800010b2 <mappages>
    80001b7c:	02054863          	bltz	a0,80001bac <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME(0), PGSIZE,
    80001b80:	4719                	li	a4,6
    80001b82:	2c093683          	ld	a3,704(s2)
    80001b86:	6605                	lui	a2,0x1
    80001b88:	020005b7          	lui	a1,0x2000
    80001b8c:	15fd                	addi	a1,a1,-1
    80001b8e:	05b6                	slli	a1,a1,0xd
    80001b90:	8526                	mv	a0,s1
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	520080e7          	jalr	1312(ra) # 800010b2 <mappages>
    80001b9a:	02054163          	bltz	a0,80001bbc <proc_pagetable+0x76>
}
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	60e2                	ld	ra,24(sp)
    80001ba2:	6442                	ld	s0,16(sp)
    80001ba4:	64a2                	ld	s1,8(sp)
    80001ba6:	6902                	ld	s2,0(sp)
    80001ba8:	6105                	addi	sp,sp,32
    80001baa:	8082                	ret
    uvmfree(pagetable, 0);
    80001bac:	4581                	li	a1,0
    80001bae:	8526                	mv	a0,s1
    80001bb0:	00000097          	auipc	ra,0x0
    80001bb4:	976080e7          	jalr	-1674(ra) # 80001526 <uvmfree>
    return 0;
    80001bb8:	4481                	li	s1,0
    80001bba:	b7d5                	j	80001b9e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bbc:	4681                	li	a3,0
    80001bbe:	4605                	li	a2,1
    80001bc0:	040005b7          	lui	a1,0x4000
    80001bc4:	15fd                	addi	a1,a1,-1
    80001bc6:	05b2                	slli	a1,a1,0xc
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	69c080e7          	jalr	1692(ra) # 80001266 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bd2:	4581                	li	a1,0
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	950080e7          	jalr	-1712(ra) # 80001526 <uvmfree>
    return 0;
    80001bde:	4481                	li	s1,0
    80001be0:	bf7d                	j	80001b9e <proc_pagetable+0x58>

0000000080001be2 <proc_freepagetable>:
{
    80001be2:	1101                	addi	sp,sp,-32
    80001be4:	ec06                	sd	ra,24(sp)
    80001be6:	e822                	sd	s0,16(sp)
    80001be8:	e426                	sd	s1,8(sp)
    80001bea:	e04a                	sd	s2,0(sp)
    80001bec:	1000                	addi	s0,sp,32
    80001bee:	84aa                	mv	s1,a0
    80001bf0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bf2:	4681                	li	a3,0
    80001bf4:	4605                	li	a2,1
    80001bf6:	040005b7          	lui	a1,0x4000
    80001bfa:	15fd                	addi	a1,a1,-1
    80001bfc:	05b2                	slli	a1,a1,0xc
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	668080e7          	jalr	1640(ra) # 80001266 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME(0), 1, 0);
    80001c06:	4681                	li	a3,0
    80001c08:	4605                	li	a2,1
    80001c0a:	020005b7          	lui	a1,0x2000
    80001c0e:	15fd                	addi	a1,a1,-1
    80001c10:	05b6                	slli	a1,a1,0xd
    80001c12:	8526                	mv	a0,s1
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	652080e7          	jalr	1618(ra) # 80001266 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c1c:	85ca                	mv	a1,s2
    80001c1e:	8526                	mv	a0,s1
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	906080e7          	jalr	-1786(ra) # 80001526 <uvmfree>
}
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6902                	ld	s2,0(sp)
    80001c30:	6105                	addi	sp,sp,32
    80001c32:	8082                	ret

0000000080001c34 <freeproc>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
    80001c40:	892a                	mv	s2,a0
  if(p->trapframe_backup)
    80001c42:	1b853503          	ld	a0,440(a0)
    80001c46:	c509                	beqz	a0,80001c50 <freeproc+0x1c>
    kfree((void*)p->trapframe_backup);
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	d8e080e7          	jalr	-626(ra) # 800009d6 <kfree>
  p->trapframe_backup = 0;
    80001c50:	1a093c23          	sd	zero,440(s2)
  if(p->pagetable)
    80001c54:	1d893503          	ld	a0,472(s2)
    80001c58:	c519                	beqz	a0,80001c66 <freeproc+0x32>
    proc_freepagetable(p->pagetable, p->sz);
    80001c5a:	1d093583          	ld	a1,464(s2)
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	f84080e7          	jalr	-124(ra) # 80001be2 <proc_freepagetable>
  p->pagetable = 0;
    80001c66:	1c093c23          	sd	zero,472(s2)
  p->sz = 0;
    80001c6a:	1c093823          	sd	zero,464(s2)
  p->pid = 0;
    80001c6e:	02092223          	sw	zero,36(s2)
  p->parent = 0;
    80001c72:	1c093423          	sd	zero,456(s2)
  p->name[0] = 0;
    80001c76:	26090423          	sb	zero,616(s2)
  p->killed = 0;
    80001c7a:	00092e23          	sw	zero,28(s2)
  p->stopped = 0;
    80001c7e:	1c092023          	sw	zero,448(s2)
  p->xstate = 0;
    80001c82:	02092023          	sw	zero,32(s2)
  p->state = UNUSED;
    80001c86:	00092c23          	sw	zero,24(s2)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001c8a:	27890493          	addi	s1,s2,632
    80001c8e:	6505                	lui	a0,0x1
    80001c90:	87850513          	addi	a0,a0,-1928 # 878 <_entry-0x7ffff788>
    80001c94:	992a                	add	s2,s2,a0
    freethread(t);
    80001c96:	8526                	mv	a0,s1
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	b98080e7          	jalr	-1128(ra) # 80001830 <freethread>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001ca0:	0c048493          	addi	s1,s1,192
    80001ca4:	fe9919e3          	bne	s2,s1,80001c96 <freeproc+0x62>
}
    80001ca8:	60e2                	ld	ra,24(sp)
    80001caa:	6442                	ld	s0,16(sp)
    80001cac:	64a2                	ld	s1,8(sp)
    80001cae:	6902                	ld	s2,0(sp)
    80001cb0:	6105                	addi	sp,sp,32
    80001cb2:	8082                	ret

0000000080001cb4 <allocproc>:
{
    80001cb4:	7179                	addi	sp,sp,-48
    80001cb6:	f406                	sd	ra,40(sp)
    80001cb8:	f022                	sd	s0,32(sp)
    80001cba:	ec26                	sd	s1,24(sp)
    80001cbc:	e84a                	sd	s2,16(sp)
    80001cbe:	e44e                	sd	s3,8(sp)
    80001cc0:	e052                	sd	s4,0(sp)
    80001cc2:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc4:	00010497          	auipc	s1,0x10
    80001cc8:	a3c48493          	addi	s1,s1,-1476 # 80011700 <proc>
    80001ccc:	6985                	lui	s3,0x1
    80001cce:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80001cd2:	00032a17          	auipc	s4,0x32
    80001cd6:	a2ea0a13          	addi	s4,s4,-1490 # 80033700 <tickslock>
    acquire(&p->lock);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	ee6080e7          	jalr	-282(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001ce4:	4c9c                	lw	a5,24(s1)
    80001ce6:	cb99                	beqz	a5,80001cfc <allocproc+0x48>
      release(&p->lock);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	f9e080e7          	jalr	-98(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf2:	94ce                	add	s1,s1,s3
    80001cf4:	ff4493e3          	bne	s1,s4,80001cda <allocproc+0x26>
  return 0;
    80001cf8:	4481                	li	s1,0
    80001cfa:	a845                	j	80001daa <allocproc+0xf6>
  p->pid = allocpid();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	dbe080e7          	jalr	-578(ra) # 80001aba <allocpid>
    80001d04:	d0c8                	sw	a0,36(s1)
  p->state = USED;
    80001d06:	4785                	li	a5,1
    80001d08:	cc9c                	sw	a5,24(s1)
  p->pending_signals = 0;
    80001d0a:	0204a423          	sw	zero,40(s1)
  p->signal_mask = 0;
    80001d0e:	0204a623          	sw	zero,44(s1)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001d12:	03848793          	addi	a5,s1,56
    80001d16:	13848713          	addi	a4,s1,312
    p->signal_handlers[signum] = SIG_DFL;
    80001d1a:	0007b023          	sd	zero,0(a5)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001d1e:	07a1                	addi	a5,a5,8
    80001d20:	fee79de3          	bne	a5,a4,80001d1a <allocproc+0x66>
  if((p->trapframes = (struct trapframe *)kalloc()) == 0){
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	dae080e7          	jalr	-594(ra) # 80000ad2 <kalloc>
    80001d2c:	892a                	mv	s2,a0
    80001d2e:	6785                	lui	a5,0x1
    80001d30:	97a6                	add	a5,a5,s1
    80001d32:	86a7bc23          	sd	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001d36:	c159                	beqz	a0,80001dbc <allocproc+0x108>
  t->tid = alloctid();
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	dc8080e7          	jalr	-568(ra) # 80001b00 <alloctid>
    80001d40:	2aa4a423          	sw	a0,680(s1)
  t->index = 0;
    80001d44:	2a04a623          	sw	zero,684(s1)
  t->state = USED_T;
    80001d48:	4785                	li	a5,1
    80001d4a:	28f4a823          	sw	a5,656(s1)
  t->proc = p;
    80001d4e:	2a94b823          	sd	s1,688(s1)
  t->trapframe = &p->trapframes[t->index]; // TODO: put in alloc thread
    80001d52:	6785                	lui	a5,0x1
    80001d54:	97a6                	add	a5,a5,s1
    80001d56:	8787b783          	ld	a5,-1928(a5) # 878 <_entry-0x7ffff788>
    80001d5a:	2cf4b023          	sd	a5,704(s1)
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	d74080e7          	jalr	-652(ra) # 80000ad2 <kalloc>
    80001d66:	892a                	mv	s2,a0
    80001d68:	1aa4bc23          	sd	a0,440(s1)
    80001d6c:	c525                	beqz	a0,80001dd4 <allocproc+0x120>
  p->pagetable = proc_pagetable(p);
    80001d6e:	8526                	mv	a0,s1
    80001d70:	00000097          	auipc	ra,0x0
    80001d74:	dd6080e7          	jalr	-554(ra) # 80001b46 <proc_pagetable>
    80001d78:	892a                	mv	s2,a0
    80001d7a:	1ca4bc23          	sd	a0,472(s1)
  if(p->pagetable == 0){
    80001d7e:	c53d                	beqz	a0,80001dec <allocproc+0x138>
  memset(&t->context, 0, sizeof(t->context));
    80001d80:	07000613          	li	a2,112
    80001d84:	4581                	li	a1,0
    80001d86:	2c848513          	addi	a0,s1,712
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	f58080e7          	jalr	-168(ra) # 80000ce2 <memset>
  t->context.ra = (uint64)forkret;
    80001d92:	00000797          	auipc	a5,0x0
    80001d96:	ce278793          	addi	a5,a5,-798 # 80001a74 <forkret>
    80001d9a:	2cf4b423          	sd	a5,712(s1)
  t->context.sp = t->kstack + PGSIZE;
    80001d9e:	2b84b783          	ld	a5,696(s1)
    80001da2:	6705                	lui	a4,0x1
    80001da4:	97ba                	add	a5,a5,a4
    80001da6:	2cf4b823          	sd	a5,720(s1)
}
    80001daa:	8526                	mv	a0,s1
    80001dac:	70a2                	ld	ra,40(sp)
    80001dae:	7402                	ld	s0,32(sp)
    80001db0:	64e2                	ld	s1,24(sp)
    80001db2:	6942                	ld	s2,16(sp)
    80001db4:	69a2                	ld	s3,8(sp)
    80001db6:	6a02                	ld	s4,0(sp)
    80001db8:	6145                	addi	sp,sp,48
    80001dba:	8082                	ret
    freeproc(p);
    80001dbc:	8526                	mv	a0,s1
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	e76080e7          	jalr	-394(ra) # 80001c34 <freeproc>
    release(&p->lock);
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	ec0080e7          	jalr	-320(ra) # 80000c88 <release>
    return 0;
    80001dd0:	84ca                	mv	s1,s2
    80001dd2:	bfe1                	j	80001daa <allocproc+0xf6>
    freeproc(p);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	e5e080e7          	jalr	-418(ra) # 80001c34 <freeproc>
    release(&p->lock);
    80001dde:	8526                	mv	a0,s1
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	ea8080e7          	jalr	-344(ra) # 80000c88 <release>
    return 0;
    80001de8:	84ca                	mv	s1,s2
    80001dea:	b7c1                	j	80001daa <allocproc+0xf6>
    freeproc(p);
    80001dec:	8526                	mv	a0,s1
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	e46080e7          	jalr	-442(ra) # 80001c34 <freeproc>
    release(&p->lock);
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	e90080e7          	jalr	-368(ra) # 80000c88 <release>
    return 0;
    80001e00:	84ca                	mv	s1,s2
    80001e02:	b765                	j	80001daa <allocproc+0xf6>

0000000080001e04 <userinit>:
{
    80001e04:	1101                	addi	sp,sp,-32
    80001e06:	ec06                	sd	ra,24(sp)
    80001e08:	e822                	sd	s0,16(sp)
    80001e0a:	e426                	sd	s1,8(sp)
    80001e0c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	ea6080e7          	jalr	-346(ra) # 80001cb4 <allocproc>
    80001e16:	84aa                	mv	s1,a0
  initproc = p;
    80001e18:	00007797          	auipc	a5,0x7
    80001e1c:	20a7b823          	sd	a0,528(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e20:	03400613          	li	a2,52
    80001e24:	00007597          	auipc	a1,0x7
    80001e28:	a1c58593          	addi	a1,a1,-1508 # 80008840 <initcode>
    80001e2c:	1d853503          	ld	a0,472(a0)
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	528080e7          	jalr	1320(ra) # 80001358 <uvminit>
  p->sz = PGSIZE;
    80001e38:	6785                	lui	a5,0x1
    80001e3a:	1cf4b823          	sd	a5,464(s1)
  p->threads[0].trapframe->epc = 0;      // user program counter
    80001e3e:	2c04b703          	ld	a4,704(s1)
    80001e42:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->threads[0].trapframe->sp = PGSIZE;  // user stack pointer
    80001e46:	2c04b703          	ld	a4,704(s1)
    80001e4a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e4c:	4641                	li	a2,16
    80001e4e:	00006597          	auipc	a1,0x6
    80001e52:	3c258593          	addi	a1,a1,962 # 80008210 <digits+0x1d0>
    80001e56:	26848513          	addi	a0,s1,616
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	fda080e7          	jalr	-38(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001e62:	00006517          	auipc	a0,0x6
    80001e66:	3be50513          	addi	a0,a0,958 # 80008220 <digits+0x1e0>
    80001e6a:	00003097          	auipc	ra,0x3
    80001e6e:	bf0080e7          	jalr	-1040(ra) # 80004a5a <namei>
    80001e72:	26a4b023          	sd	a0,608(s1)
  p->threads[0].state = RUNNABLE;
    80001e76:	478d                	li	a5,3
    80001e78:	28f4a823          	sw	a5,656(s1)
  release(&p->lock);
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	e0a080e7          	jalr	-502(ra) # 80000c88 <release>
}
    80001e86:	60e2                	ld	ra,24(sp)
    80001e88:	6442                	ld	s0,16(sp)
    80001e8a:	64a2                	ld	s1,8(sp)
    80001e8c:	6105                	addi	sp,sp,32
    80001e8e:	8082                	ret

0000000080001e90 <growproc>:
{
    80001e90:	1101                	addi	sp,sp,-32
    80001e92:	ec06                	sd	ra,24(sp)
    80001e94:	e822                	sd	s0,16(sp)
    80001e96:	e426                	sd	s1,8(sp)
    80001e98:	e04a                	sd	s2,0(sp)
    80001e9a:	1000                	addi	s0,sp,32
    80001e9c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	b64080e7          	jalr	-1180(ra) # 80001a02 <myproc>
    80001ea6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	d1a080e7          	jalr	-742(ra) # 80000bc2 <acquire>
  sz = p->sz;
    80001eb0:	1d04b583          	ld	a1,464(s1)
    80001eb4:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001eb8:	03204463          	bgtz	s2,80001ee0 <growproc+0x50>
  } else if(n < 0){
    80001ebc:	04094863          	bltz	s2,80001f0c <growproc+0x7c>
  p->sz = sz;
    80001ec0:	1602                	slli	a2,a2,0x20
    80001ec2:	9201                	srli	a2,a2,0x20
    80001ec4:	1cc4b823          	sd	a2,464(s1)
  release(&p->lock);
    80001ec8:	8526                	mv	a0,s1
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dbe080e7          	jalr	-578(ra) # 80000c88 <release>
  return 0;
    80001ed2:	4501                	li	a0,0
}
    80001ed4:	60e2                	ld	ra,24(sp)
    80001ed6:	6442                	ld	s0,16(sp)
    80001ed8:	64a2                	ld	s1,8(sp)
    80001eda:	6902                	ld	s2,0(sp)
    80001edc:	6105                	addi	sp,sp,32
    80001ede:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ee0:	00c9063b          	addw	a2,s2,a2
    80001ee4:	1602                	slli	a2,a2,0x20
    80001ee6:	9201                	srli	a2,a2,0x20
    80001ee8:	1582                	slli	a1,a1,0x20
    80001eea:	9181                	srli	a1,a1,0x20
    80001eec:	1d84b503          	ld	a0,472(s1)
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	522080e7          	jalr	1314(ra) # 80001412 <uvmalloc>
    80001ef8:	0005061b          	sext.w	a2,a0
    80001efc:	f271                	bnez	a2,80001ec0 <growproc+0x30>
      release(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d88080e7          	jalr	-632(ra) # 80000c88 <release>
      return -1;
    80001f08:	557d                	li	a0,-1
    80001f0a:	b7e9                	j	80001ed4 <growproc+0x44>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f0c:	00c9063b          	addw	a2,s2,a2
    80001f10:	1602                	slli	a2,a2,0x20
    80001f12:	9201                	srli	a2,a2,0x20
    80001f14:	1582                	slli	a1,a1,0x20
    80001f16:	9181                	srli	a1,a1,0x20
    80001f18:	1d84b503          	ld	a0,472(s1)
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	4ae080e7          	jalr	1198(ra) # 800013ca <uvmdealloc>
    80001f24:	0005061b          	sext.w	a2,a0
    80001f28:	bf61                	j	80001ec0 <growproc+0x30>

0000000080001f2a <fork>:
{
    80001f2a:	7139                	addi	sp,sp,-64
    80001f2c:	fc06                	sd	ra,56(sp)
    80001f2e:	f822                	sd	s0,48(sp)
    80001f30:	f426                	sd	s1,40(sp)
    80001f32:	f04a                	sd	s2,32(sp)
    80001f34:	ec4e                	sd	s3,24(sp)
    80001f36:	e852                	sd	s4,16(sp)
    80001f38:	e456                	sd	s5,8(sp)
    80001f3a:	0080                	addi	s0,sp,64
  struct thread *t = mythread();
    80001f3c:	00000097          	auipc	ra,0x0
    80001f40:	b00080e7          	jalr	-1280(ra) # 80001a3c <mythread>
    80001f44:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	abc080e7          	jalr	-1348(ra) # 80001a02 <myproc>
    80001f4e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0) {
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	d64080e7          	jalr	-668(ra) # 80001cb4 <allocproc>
    80001f58:	14050a63          	beqz	a0,800020ac <fork+0x182>
    80001f5c:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f5e:	1d093603          	ld	a2,464(s2)
    80001f62:	1d853583          	ld	a1,472(a0)
    80001f66:	1d893503          	ld	a0,472(s2)
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	5f4080e7          	jalr	1524(ra) # 8000155e <uvmcopy>
    80001f72:	04054763          	bltz	a0,80001fc0 <fork+0x96>
  np->sz = p->sz;
    80001f76:	1d093783          	ld	a5,464(s2)
    80001f7a:	1cfa3823          	sd	a5,464(s4)
  *(nt->trapframe) = *(t->trapframe); 
    80001f7e:	64b4                	ld	a3,72(s1)
    80001f80:	87b6                	mv	a5,a3
    80001f82:	2c0a3703          	ld	a4,704(s4)
    80001f86:	12068693          	addi	a3,a3,288
    80001f8a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f8e:	6788                	ld	a0,8(a5)
    80001f90:	6b8c                	ld	a1,16(a5)
    80001f92:	6f90                	ld	a2,24(a5)
    80001f94:	01073023          	sd	a6,0(a4)
    80001f98:	e708                	sd	a0,8(a4)
    80001f9a:	eb0c                	sd	a1,16(a4)
    80001f9c:	ef10                	sd	a2,24(a4)
    80001f9e:	02078793          	addi	a5,a5,32
    80001fa2:	02070713          	addi	a4,a4,32
    80001fa6:	fed792e3          	bne	a5,a3,80001f8a <fork+0x60>
  nt->trapframe->a0 = 0;
    80001faa:	2c0a3783          	ld	a5,704(s4)
    80001fae:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001fb2:	1e090493          	addi	s1,s2,480
    80001fb6:	1e0a0993          	addi	s3,s4,480
    80001fba:	26090a93          	addi	s5,s2,608
    80001fbe:	a00d                	j	80001fe0 <fork+0xb6>
    freeproc(np);
    80001fc0:	8552                	mv	a0,s4
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	c72080e7          	jalr	-910(ra) # 80001c34 <freeproc>
    release(&np->lock);
    80001fca:	8552                	mv	a0,s4
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	cbc080e7          	jalr	-836(ra) # 80000c88 <release>
    return -1;
    80001fd4:	59fd                	li	s3,-1
    80001fd6:	a0c9                	j	80002098 <fork+0x16e>
  for(i = 0; i < NOFILE; i++)
    80001fd8:	04a1                	addi	s1,s1,8
    80001fda:	09a1                	addi	s3,s3,8
    80001fdc:	01548b63          	beq	s1,s5,80001ff2 <fork+0xc8>
    if(p->ofile[i])
    80001fe0:	6088                	ld	a0,0(s1)
    80001fe2:	d97d                	beqz	a0,80001fd8 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fe4:	00003097          	auipc	ra,0x3
    80001fe8:	110080e7          	jalr	272(ra) # 800050f4 <filedup>
    80001fec:	00a9b023          	sd	a0,0(s3)
    80001ff0:	b7e5                	j	80001fd8 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ff2:	26093503          	ld	a0,608(s2)
    80001ff6:	00002097          	auipc	ra,0x2
    80001ffa:	270080e7          	jalr	624(ra) # 80004266 <idup>
    80001ffe:	26aa3023          	sd	a0,608(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002002:	4641                	li	a2,16
    80002004:	26890593          	addi	a1,s2,616
    80002008:	268a0513          	addi	a0,s4,616
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	e28080e7          	jalr	-472(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    80002014:	024a2983          	lw	s3,36(s4)
  release(&np->lock);
    80002018:	8552                	mv	a0,s4
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	c6e080e7          	jalr	-914(ra) # 80000c88 <release>
  acquire(&wait_lock);
    80002022:	0000f497          	auipc	s1,0xf
    80002026:	29648493          	addi	s1,s1,662 # 800112b8 <wait_lock>
    8000202a:	8526                	mv	a0,s1
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	b96080e7          	jalr	-1130(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002034:	1d2a3423          	sd	s2,456(s4)
  release(&wait_lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c4e080e7          	jalr	-946(ra) # 80000c88 <release>
  acquire(&np->lock);
    80002042:	8552                	mv	a0,s4
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	b7e080e7          	jalr	-1154(ra) # 80000bc2 <acquire>
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
    8000204c:	02c92783          	lw	a5,44(s2)
    80002050:	02fa2623          	sw	a5,44(s4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80002054:	03890793          	addi	a5,s2,56
    80002058:	038a0713          	addi	a4,s4,56
    8000205c:	13890613          	addi	a2,s2,312
    np->signal_handlers[i] = p->signal_handlers[i];    
    80002060:	6394                	ld	a3,0(a5)
    80002062:	e314                	sd	a3,0(a4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    80002064:	07a1                	addi	a5,a5,8
    80002066:	0721                	addi	a4,a4,8
    80002068:	fec79ce3          	bne	a5,a2,80002060 <fork+0x136>
  np->pending_signals = 0; // ADDED Q2.1.2
    8000206c:	020a2423          	sw	zero,40(s4)
  release(&np->lock);
    80002070:	8552                	mv	a0,s4
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c16080e7          	jalr	-1002(ra) # 80000c88 <release>
  acquire(&nt->lock);
    8000207a:	278a0493          	addi	s1,s4,632
    8000207e:	8526                	mv	a0,s1
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	b42080e7          	jalr	-1214(ra) # 80000bc2 <acquire>
  nt->state = RUNNABLE;
    80002088:	478d                	li	a5,3
    8000208a:	28fa2823          	sw	a5,656(s4)
  release(&nt->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	bf8080e7          	jalr	-1032(ra) # 80000c88 <release>
}
    80002098:	854e                	mv	a0,s3
    8000209a:	70e2                	ld	ra,56(sp)
    8000209c:	7442                	ld	s0,48(sp)
    8000209e:	74a2                	ld	s1,40(sp)
    800020a0:	7902                	ld	s2,32(sp)
    800020a2:	69e2                	ld	s3,24(sp)
    800020a4:	6a42                	ld	s4,16(sp)
    800020a6:	6aa2                	ld	s5,8(sp)
    800020a8:	6121                	addi	sp,sp,64
    800020aa:	8082                	ret
    return -1;
    800020ac:	59fd                	li	s3,-1
    800020ae:	b7ed                	j	80002098 <fork+0x16e>

00000000800020b0 <kill_handler>:
{
    800020b0:	1141                	addi	sp,sp,-16
    800020b2:	e406                	sd	ra,8(sp)
    800020b4:	e022                	sd	s0,0(sp)
    800020b6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	94a080e7          	jalr	-1718(ra) # 80001a02 <myproc>
  p->killed = 1; 
    800020c0:	4785                	li	a5,1
    800020c2:	cd5c                	sw	a5,28(a0)
}
    800020c4:	60a2                	ld	ra,8(sp)
    800020c6:	6402                	ld	s0,0(sp)
    800020c8:	0141                	addi	sp,sp,16
    800020ca:	8082                	ret

00000000800020cc <received_continue>:
{
    800020cc:	1101                	addi	sp,sp,-32
    800020ce:	ec06                	sd	ra,24(sp)
    800020d0:	e822                	sd	s0,16(sp)
    800020d2:	e426                	sd	s1,8(sp)
    800020d4:	e04a                	sd	s2,0(sp)
    800020d6:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	92a080e7          	jalr	-1750(ra) # 80001a02 <myproc>
    800020e0:	892a                	mv	s2,a0
    acquire(&p->lock);
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	ae0080e7          	jalr	-1312(ra) # 80000bc2 <acquire>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    800020ea:	02c92683          	lw	a3,44(s2)
    800020ee:	fff6c693          	not	a3,a3
    800020f2:	02892783          	lw	a5,40(s2)
    800020f6:	8efd                	and	a3,a3,a5
    800020f8:	2681                	sext.w	a3,a3
    for (int signum = 0; signum < SIG_NUM; signum++) {
    800020fa:	03890713          	addi	a4,s2,56
    800020fe:	4781                	li	a5,0
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002100:	454d                	li	a0,19
    for (int signum = 0; signum < SIG_NUM; signum++) {
    80002102:	02000613          	li	a2,32
    80002106:	a801                	j	80002116 <received_continue+0x4a>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002108:	630c                	ld	a1,0(a4)
    8000210a:	00a58f63          	beq	a1,a0,80002128 <received_continue+0x5c>
    for (int signum = 0; signum < SIG_NUM; signum++) {
    8000210e:	2785                	addiw	a5,a5,1
    80002110:	0721                	addi	a4,a4,8
    80002112:	02c78163          	beq	a5,a2,80002134 <received_continue+0x68>
      if( (pending_and_not_blocked & (1 << signum)) &&
    80002116:	40f6d4bb          	sraw	s1,a3,a5
    8000211a:	8885                	andi	s1,s1,1
    8000211c:	d8ed                	beqz	s1,8000210e <received_continue+0x42>
    8000211e:	0d093583          	ld	a1,208(s2)
    80002122:	f1fd                	bnez	a1,80002108 <received_continue+0x3c>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002124:	fea792e3          	bne	a5,a0,80002108 <received_continue+0x3c>
            release(&p->lock);
    80002128:	854a                	mv	a0,s2
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	b5e080e7          	jalr	-1186(ra) # 80000c88 <release>
            return 1;
    80002132:	a039                	j	80002140 <received_continue+0x74>
    release(&p->lock);
    80002134:	854a                	mv	a0,s2
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b52080e7          	jalr	-1198(ra) # 80000c88 <release>
    return 0;
    8000213e:	4481                	li	s1,0
}
    80002140:	8526                	mv	a0,s1
    80002142:	60e2                	ld	ra,24(sp)
    80002144:	6442                	ld	s0,16(sp)
    80002146:	64a2                	ld	s1,8(sp)
    80002148:	6902                	ld	s2,0(sp)
    8000214a:	6105                	addi	sp,sp,32
    8000214c:	8082                	ret

000000008000214e <continue_handler>:
{
    8000214e:	1141                	addi	sp,sp,-16
    80002150:	e406                	sd	ra,8(sp)
    80002152:	e022                	sd	s0,0(sp)
    80002154:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	8ac080e7          	jalr	-1876(ra) # 80001a02 <myproc>
  p->stopped = 0;
    8000215e:	1c052023          	sw	zero,448(a0)
}
    80002162:	60a2                	ld	ra,8(sp)
    80002164:	6402                	ld	s0,0(sp)
    80002166:	0141                	addi	sp,sp,16
    80002168:	8082                	ret

000000008000216a <handle_user_signals>:
handle_user_signals(int signum) {
    8000216a:	7179                	addi	sp,sp,-48
    8000216c:	f406                	sd	ra,40(sp)
    8000216e:	f022                	sd	s0,32(sp)
    80002170:	ec26                	sd	s1,24(sp)
    80002172:	e84a                	sd	s2,16(sp)
    80002174:	e44e                	sd	s3,8(sp)
    80002176:	1800                	addi	s0,sp,48
    80002178:	892a                	mv	s2,a0
  struct thread *t = mythread();
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	8c2080e7          	jalr	-1854(ra) # 80001a3c <mythread>
    80002182:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	87e080e7          	jalr	-1922(ra) # 80001a02 <myproc>
    8000218c:	84aa                	mv	s1,a0
  p->signal_mask_backup = p->signal_mask;
    8000218e:	555c                	lw	a5,44(a0)
    80002190:	d91c                	sw	a5,48(a0)
  p->signal_mask = p->signal_handlers_masks[signum];  
    80002192:	04c90793          	addi	a5,s2,76
    80002196:	078a                	slli	a5,a5,0x2
    80002198:	97aa                	add	a5,a5,a0
    8000219a:	479c                	lw	a5,8(a5)
    8000219c:	d55c                	sw	a5,44(a0)
  memmove(p->trapframe_backup, t->trapframe, sizeof(struct trapframe));
    8000219e:	12000613          	li	a2,288
    800021a2:	0489b583          	ld	a1,72(s3)
    800021a6:	1b853503          	ld	a0,440(a0)
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	b94080e7          	jalr	-1132(ra) # 80000d3e <memmove>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    800021b2:	0489b703          	ld	a4,72(s3)
  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
    800021b6:	00005617          	auipc	a2,0x5
    800021ba:	f5c60613          	addi	a2,a2,-164 # 80007112 <start_inject_sigret>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    800021be:	00005697          	auipc	a3,0x5
    800021c2:	f5a68693          	addi	a3,a3,-166 # 80007118 <end_inject_sigret>
    800021c6:	9e91                	subw	a3,a3,a2
    800021c8:	7b1c                	ld	a5,48(a4)
    800021ca:	8f95                	sub	a5,a5,a3
    800021cc:	fb1c                	sd	a5,48(a4)
  copyout(p->pagetable, (uint64) (t->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);
    800021ce:	0489b783          	ld	a5,72(s3)
    800021d2:	7b8c                	ld	a1,48(a5)
    800021d4:	1d84b503          	ld	a0,472(s1)
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	48a080e7          	jalr	1162(ra) # 80001662 <copyout>
  t->trapframe->a0 = signum;
    800021e0:	0489b783          	ld	a5,72(s3)
    800021e4:	0727b823          	sd	s2,112(a5)
  t->trapframe->epc = (uint64)p->signal_handlers[signum];
    800021e8:	0489b783          	ld	a5,72(s3)
    800021ec:	0919                	addi	s2,s2,6
    800021ee:	090e                	slli	s2,s2,0x3
    800021f0:	94ca                	add	s1,s1,s2
    800021f2:	6498                	ld	a4,8(s1)
    800021f4:	ef98                	sd	a4,24(a5)
  t->trapframe->ra = t->trapframe->sp;
    800021f6:	0489b783          	ld	a5,72(s3)
    800021fa:	7b98                	ld	a4,48(a5)
    800021fc:	f798                	sd	a4,40(a5)
}
    800021fe:	70a2                	ld	ra,40(sp)
    80002200:	7402                	ld	s0,32(sp)
    80002202:	64e2                	ld	s1,24(sp)
    80002204:	6942                	ld	s2,16(sp)
    80002206:	69a2                	ld	s3,8(sp)
    80002208:	6145                	addi	sp,sp,48
    8000220a:	8082                	ret

000000008000220c <scheduler>:
{
    8000220c:	715d                	addi	sp,sp,-80
    8000220e:	e486                	sd	ra,72(sp)
    80002210:	e0a2                	sd	s0,64(sp)
    80002212:	fc26                	sd	s1,56(sp)
    80002214:	f84a                	sd	s2,48(sp)
    80002216:	f44e                	sd	s3,40(sp)
    80002218:	f052                	sd	s4,32(sp)
    8000221a:	ec56                	sd	s5,24(sp)
    8000221c:	e85a                	sd	s6,16(sp)
    8000221e:	e45e                	sd	s7,8(sp)
    80002220:	e062                	sd	s8,0(sp)
    80002222:	0880                	addi	s0,sp,80
    80002224:	8792                	mv	a5,tp
  int id = r_tp();
    80002226:	2781                	sext.w	a5,a5
  c->thread = 0;
    80002228:	00779a93          	slli	s5,a5,0x7
    8000222c:	0000f717          	auipc	a4,0xf
    80002230:	07470713          	addi	a4,a4,116 # 800112a0 <pid_lock>
    80002234:	9756                	add	a4,a4,s5
    80002236:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &t->context);
    8000223a:	0000f717          	auipc	a4,0xf
    8000223e:	09e70713          	addi	a4,a4,158 # 800112d8 <cpus+0x8>
    80002242:	9aba                	add	s5,s5,a4
    80002244:	00032c17          	auipc	s8,0x32
    80002248:	d34c0c13          	addi	s8,s8,-716 # 80033f78 <bcache+0x860>
          t->state = RUNNING;
    8000224c:	4b11                	li	s6,4
          c->thread = t;
    8000224e:	079e                	slli	a5,a5,0x7
    80002250:	0000fa17          	auipc	s4,0xf
    80002254:	050a0a13          	addi	s4,s4,80 # 800112a0 <pid_lock>
    80002258:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000225a:	6b85                	lui	s7,0x1
    8000225c:	880b8b93          	addi	s7,s7,-1920 # 880 <_entry-0x7ffff780>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002260:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002264:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002268:	10079073          	csrw	sstatus,a5
    8000226c:	00010917          	auipc	s2,0x10
    80002270:	d0c90913          	addi	s2,s2,-756 # 80011f78 <proc+0x878>
        if(t->state == RUNNABLE) {
    80002274:	498d                	li	s3,3
    80002276:	a099                	j	800022bc <scheduler+0xb0>
        release(&t->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	a0e080e7          	jalr	-1522(ra) # 80000c88 <release>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002282:	0c048493          	addi	s1,s1,192
    80002286:	03248863          	beq	s1,s2,800022b6 <scheduler+0xaa>
        acquire(&t->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	936080e7          	jalr	-1738(ra) # 80000bc2 <acquire>
        if(t->state == RUNNABLE) {
    80002294:	4c9c                	lw	a5,24(s1)
    80002296:	ff3791e3          	bne	a5,s3,80002278 <scheduler+0x6c>
          t->state = RUNNING;
    8000229a:	0164ac23          	sw	s6,24(s1)
          c->thread = t;
    8000229e:	029a3823          	sd	s1,48(s4)
          swtch(&c->context, &t->context);
    800022a2:	05048593          	addi	a1,s1,80
    800022a6:	8556                	mv	a0,s5
    800022a8:	00001097          	auipc	ra,0x1
    800022ac:	d88080e7          	jalr	-632(ra) # 80003030 <swtch>
          c->thread = 0;
    800022b0:	020a3823          	sd	zero,48(s4)
    800022b4:	b7d1                	j	80002278 <scheduler+0x6c>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022b6:	995e                	add	s2,s2,s7
    800022b8:	fb8904e3          	beq	s2,s8,80002260 <scheduler+0x54>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800022bc:	a0090493          	addi	s1,s2,-1536
    800022c0:	b7e9                	j	8000228a <scheduler+0x7e>

00000000800022c2 <sched>:
{
    800022c2:	7179                	addi	sp,sp,-48
    800022c4:	f406                	sd	ra,40(sp)
    800022c6:	f022                	sd	s0,32(sp)
    800022c8:	ec26                	sd	s1,24(sp)
    800022ca:	e84a                	sd	s2,16(sp)
    800022cc:	e44e                	sd	s3,8(sp)
    800022ce:	1800                	addi	s0,sp,48
  struct thread *t = mythread();
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	76c080e7          	jalr	1900(ra) # 80001a3c <mythread>
    800022d8:	84aa                	mv	s1,a0
  if(!holding(&t->lock))
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	86e080e7          	jalr	-1938(ra) # 80000b48 <holding>
    800022e2:	c93d                	beqz	a0,80002358 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022e4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800022e6:	2781                	sext.w	a5,a5
    800022e8:	079e                	slli	a5,a5,0x7
    800022ea:	0000f717          	auipc	a4,0xf
    800022ee:	fb670713          	addi	a4,a4,-74 # 800112a0 <pid_lock>
    800022f2:	97ba                	add	a5,a5,a4
    800022f4:	0a87a703          	lw	a4,168(a5)
    800022f8:	4785                	li	a5,1
    800022fa:	06f71763          	bne	a4,a5,80002368 <sched+0xa6>
  if(t->state == RUNNING)
    800022fe:	4c98                	lw	a4,24(s1)
    80002300:	4791                	li	a5,4
    80002302:	06f70b63          	beq	a4,a5,80002378 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002306:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000230a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000230c:	efb5                	bnez	a5,80002388 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000230e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002310:	0000f917          	auipc	s2,0xf
    80002314:	f9090913          	addi	s2,s2,-112 # 800112a0 <pid_lock>
    80002318:	2781                	sext.w	a5,a5
    8000231a:	079e                	slli	a5,a5,0x7
    8000231c:	97ca                	add	a5,a5,s2
    8000231e:	0ac7a983          	lw	s3,172(a5)
    80002322:	8792                	mv	a5,tp
  swtch(&t->context, &mycpu()->context);
    80002324:	2781                	sext.w	a5,a5
    80002326:	079e                	slli	a5,a5,0x7
    80002328:	0000f597          	auipc	a1,0xf
    8000232c:	fb058593          	addi	a1,a1,-80 # 800112d8 <cpus+0x8>
    80002330:	95be                	add	a1,a1,a5
    80002332:	05048513          	addi	a0,s1,80
    80002336:	00001097          	auipc	ra,0x1
    8000233a:	cfa080e7          	jalr	-774(ra) # 80003030 <swtch>
    8000233e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002340:	2781                	sext.w	a5,a5
    80002342:	079e                	slli	a5,a5,0x7
    80002344:	97ca                	add	a5,a5,s2
    80002346:	0b37a623          	sw	s3,172(a5)
}
    8000234a:	70a2                	ld	ra,40(sp)
    8000234c:	7402                	ld	s0,32(sp)
    8000234e:	64e2                	ld	s1,24(sp)
    80002350:	6942                	ld	s2,16(sp)
    80002352:	69a2                	ld	s3,8(sp)
    80002354:	6145                	addi	sp,sp,48
    80002356:	8082                	ret
    panic("sched t->lock");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	ed050513          	addi	a0,a0,-304 # 80008228 <digits+0x1e8>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1ca080e7          	jalr	458(ra) # 8000052a <panic>
    panic("sched locks");
    80002368:	00006517          	auipc	a0,0x6
    8000236c:	ed050513          	addi	a0,a0,-304 # 80008238 <digits+0x1f8>
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	1ba080e7          	jalr	442(ra) # 8000052a <panic>
    panic("sched running");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	ed050513          	addi	a0,a0,-304 # 80008248 <digits+0x208>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1aa080e7          	jalr	426(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002388:	00006517          	auipc	a0,0x6
    8000238c:	ed050513          	addi	a0,a0,-304 # 80008258 <digits+0x218>
    80002390:	ffffe097          	auipc	ra,0xffffe
    80002394:	19a080e7          	jalr	410(ra) # 8000052a <panic>

0000000080002398 <yield>:
{
    80002398:	1101                	addi	sp,sp,-32
    8000239a:	ec06                	sd	ra,24(sp)
    8000239c:	e822                	sd	s0,16(sp)
    8000239e:	e426                	sd	s1,8(sp)
    800023a0:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	69a080e7          	jalr	1690(ra) # 80001a3c <mythread>
    800023aa:	84aa                	mv	s1,a0
  acquire(&t->lock);
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	816080e7          	jalr	-2026(ra) # 80000bc2 <acquire>
  t->state = RUNNABLE;
    800023b4:	478d                	li	a5,3
    800023b6:	cc9c                	sw	a5,24(s1)
  sched();
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	f0a080e7          	jalr	-246(ra) # 800022c2 <sched>
  release(&t->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8c6080e7          	jalr	-1850(ra) # 80000c88 <release>
}
    800023ca:	60e2                	ld	ra,24(sp)
    800023cc:	6442                	ld	s0,16(sp)
    800023ce:	64a2                	ld	s1,8(sp)
    800023d0:	6105                	addi	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <stop_handler>:
{
    800023d4:	1101                	addi	sp,sp,-32
    800023d6:	ec06                	sd	ra,24(sp)
    800023d8:	e822                	sd	s0,16(sp)
    800023da:	e426                	sd	s1,8(sp)
    800023dc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	624080e7          	jalr	1572(ra) # 80001a02 <myproc>
    800023e6:	84aa                	mv	s1,a0
  p->stopped = 1;
    800023e8:	4785                	li	a5,1
    800023ea:	1cf52023          	sw	a5,448(a0)
  release(&p->lock);
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	89a080e7          	jalr	-1894(ra) # 80000c88 <release>
  while (p->stopped && !received_continue())
    800023f6:	1c04a783          	lw	a5,448(s1)
    800023fa:	cf89                	beqz	a5,80002414 <stop_handler+0x40>
    800023fc:	00000097          	auipc	ra,0x0
    80002400:	cd0080e7          	jalr	-816(ra) # 800020cc <received_continue>
    80002404:	e901                	bnez	a0,80002414 <stop_handler+0x40>
      yield();
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	f92080e7          	jalr	-110(ra) # 80002398 <yield>
  while (p->stopped && !received_continue())
    8000240e:	1c04a783          	lw	a5,448(s1)
    80002412:	f7ed                	bnez	a5,800023fc <stop_handler+0x28>
  acquire(&p->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	ffffe097          	auipc	ra,0xffffe
    8000241a:	7ac080e7          	jalr	1964(ra) # 80000bc2 <acquire>
}
    8000241e:	60e2                	ld	ra,24(sp)
    80002420:	6442                	ld	s0,16(sp)
    80002422:	64a2                	ld	s1,8(sp)
    80002424:	6105                	addi	sp,sp,32
    80002426:	8082                	ret

0000000080002428 <handle_signals>:
{
    80002428:	711d                	addi	sp,sp,-96
    8000242a:	ec86                	sd	ra,88(sp)
    8000242c:	e8a2                	sd	s0,80(sp)
    8000242e:	e4a6                	sd	s1,72(sp)
    80002430:	e0ca                	sd	s2,64(sp)
    80002432:	fc4e                	sd	s3,56(sp)
    80002434:	f852                	sd	s4,48(sp)
    80002436:	f456                	sd	s5,40(sp)
    80002438:	f05a                	sd	s6,32(sp)
    8000243a:	ec5e                	sd	s7,24(sp)
    8000243c:	e862                	sd	s8,16(sp)
    8000243e:	e466                	sd	s9,8(sp)
    80002440:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	5c0080e7          	jalr	1472(ra) # 80001a02 <myproc>
    8000244a:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	776080e7          	jalr	1910(ra) # 80000bc2 <acquire>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80002454:	03890993          	addi	s3,s2,56
    80002458:	4481                	li	s1,0
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000245a:	4b05                	li	s6,1
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    8000245c:	4ac5                	li	s5,17
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    8000245e:	4bcd                	li	s7,19
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    80002460:	4c25                	li	s8,9
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    80002462:	4c85                	li	s9,1
  for(int signum = 0; signum < SIG_NUM; signum++){
    80002464:	02000a13          	li	s4,32
    80002468:	a0a1                	j	800024b0 <handle_signals+0x88>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    8000246a:	03548263          	beq	s1,s5,8000248e <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    8000246e:	09748b63          	beq	s1,s7,80002504 <handle_signals+0xdc>
        kill_handler();
    80002472:	00000097          	auipc	ra,0x0
    80002476:	c3e080e7          	jalr	-962(ra) # 800020b0 <kill_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000247a:	009b17bb          	sllw	a5,s6,s1
    8000247e:	fff7c793          	not	a5,a5
    80002482:	02892703          	lw	a4,40(s2)
    80002486:	8ff9                	and	a5,a5,a4
    80002488:	02f92423          	sw	a5,40(s2)
    8000248c:	a831                	j	800024a8 <handle_signals+0x80>
        stop_handler();
    8000248e:	00000097          	auipc	ra,0x0
    80002492:	f46080e7          	jalr	-186(ra) # 800023d4 <stop_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002496:	009b17bb          	sllw	a5,s6,s1
    8000249a:	fff7c793          	not	a5,a5
    8000249e:	02892703          	lw	a4,40(s2)
    800024a2:	8ff9                	and	a5,a5,a4
    800024a4:	02f92423          	sw	a5,40(s2)
  for(int signum = 0; signum < SIG_NUM; signum++){
    800024a8:	2485                	addiw	s1,s1,1
    800024aa:	09a1                	addi	s3,s3,8
    800024ac:	09448263          	beq	s1,s4,80002530 <handle_signals+0x108>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    800024b0:	02892703          	lw	a4,40(s2)
    800024b4:	02c92783          	lw	a5,44(s2)
    800024b8:	fff7c793          	not	a5,a5
    800024bc:	8ff9                	and	a5,a5,a4
    if(pending_and_not_blocked & (1 << signum)){
    800024be:	4097d7bb          	sraw	a5,a5,s1
    800024c2:	8b85                	andi	a5,a5,1
    800024c4:	d3f5                	beqz	a5,800024a8 <handle_signals+0x80>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800024c6:	0009b783          	ld	a5,0(s3)
    800024ca:	d3c5                	beqz	a5,8000246a <handle_signals+0x42>
    800024cc:	fd5781e3          	beq	a5,s5,8000248e <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800024d0:	03778a63          	beq	a5,s7,80002504 <handle_signals+0xdc>
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    800024d4:	f9878fe3          	beq	a5,s8,80002472 <handle_signals+0x4a>
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    800024d8:	05978463          	beq	a5,s9,80002520 <handle_signals+0xf8>
      } else if (p->handling_user_level_signal == 0){
    800024dc:	1c492783          	lw	a5,452(s2)
    800024e0:	f7e1                	bnez	a5,800024a8 <handle_signals+0x80>
        p->handling_user_level_signal = 1;
    800024e2:	1d992223          	sw	s9,452(s2)
        handle_user_signals(signum);
    800024e6:	8526                	mv	a0,s1
    800024e8:	00000097          	auipc	ra,0x0
    800024ec:	c82080e7          	jalr	-894(ra) # 8000216a <handle_user_signals>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800024f0:	009b17bb          	sllw	a5,s6,s1
    800024f4:	fff7c793          	not	a5,a5
    800024f8:	02892703          	lw	a4,40(s2)
    800024fc:	8ff9                	and	a5,a5,a4
    800024fe:	02f92423          	sw	a5,40(s2)
    80002502:	b75d                	j	800024a8 <handle_signals+0x80>
        continue_handler();
    80002504:	00000097          	auipc	ra,0x0
    80002508:	c4a080e7          	jalr	-950(ra) # 8000214e <continue_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    8000250c:	009b17bb          	sllw	a5,s6,s1
    80002510:	fff7c793          	not	a5,a5
    80002514:	02892703          	lw	a4,40(s2)
    80002518:	8ff9                	and	a5,a5,a4
    8000251a:	02f92423          	sw	a5,40(s2)
    8000251e:	b769                	j	800024a8 <handle_signals+0x80>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002520:	009b17bb          	sllw	a5,s6,s1
    80002524:	fff7c793          	not	a5,a5
    80002528:	8f7d                	and	a4,a4,a5
    8000252a:	02e92423          	sw	a4,40(s2)
    8000252e:	bfad                	j	800024a8 <handle_signals+0x80>
  release(&p->lock);
    80002530:	854a                	mv	a0,s2
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	756080e7          	jalr	1878(ra) # 80000c88 <release>
}
    8000253a:	60e6                	ld	ra,88(sp)
    8000253c:	6446                	ld	s0,80(sp)
    8000253e:	64a6                	ld	s1,72(sp)
    80002540:	6906                	ld	s2,64(sp)
    80002542:	79e2                	ld	s3,56(sp)
    80002544:	7a42                	ld	s4,48(sp)
    80002546:	7aa2                	ld	s5,40(sp)
    80002548:	7b02                	ld	s6,32(sp)
    8000254a:	6be2                	ld	s7,24(sp)
    8000254c:	6c42                	ld	s8,16(sp)
    8000254e:	6ca2                	ld	s9,8(sp)
    80002550:	6125                	addi	sp,sp,96
    80002552:	8082                	ret

0000000080002554 <sleep>:
// ADDED Q3
// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002554:	7179                	addi	sp,sp,-48
    80002556:	f406                	sd	ra,40(sp)
    80002558:	f022                	sd	s0,32(sp)
    8000255a:	ec26                	sd	s1,24(sp)
    8000255c:	e84a                	sd	s2,16(sp)
    8000255e:	e44e                	sd	s3,8(sp)
    80002560:	1800                	addi	s0,sp,48
    80002562:	89aa                	mv	s3,a0
    80002564:	892e                	mv	s2,a1
  struct thread *t = mythread();
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	4d6080e7          	jalr	1238(ra) # 80001a3c <mythread>
    8000256e:	84aa                	mv	s1,a0
  // Once we hold t->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks t->lock),
  // so it's okay to release lk.

  acquire(&t->lock);  //DOC: sleeplock1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	652080e7          	jalr	1618(ra) # 80000bc2 <acquire>
  release(lk);
    80002578:	854a                	mv	a0,s2
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	70e080e7          	jalr	1806(ra) # 80000c88 <release>

  // Go to sleep.
  t->chan = chan;
    80002582:	0334b023          	sd	s3,32(s1)
  t->state = SLEEPING;
    80002586:	4789                	li	a5,2
    80002588:	cc9c                	sw	a5,24(s1)

  sched();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	d38080e7          	jalr	-712(ra) # 800022c2 <sched>

  // Tidy up.
  t->chan = 0;
    80002592:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&t->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	6f0080e7          	jalr	1776(ra) # 80000c88 <release>
  acquire(lk);
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	620080e7          	jalr	1568(ra) # 80000bc2 <acquire>
}
    800025aa:	70a2                	ld	ra,40(sp)
    800025ac:	7402                	ld	s0,32(sp)
    800025ae:	64e2                	ld	s1,24(sp)
    800025b0:	6942                	ld	s2,16(sp)
    800025b2:	69a2                	ld	s3,8(sp)
    800025b4:	6145                	addi	sp,sp,48
    800025b6:	8082                	ret

00000000800025b8 <wait>:
{
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	0880                	addi	s0,sp,80
    800025ce:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    800025d0:	fffff097          	auipc	ra,0xfffff
    800025d4:	432080e7          	jalr	1074(ra) # 80001a02 <myproc>
    800025d8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025da:	0000f517          	auipc	a0,0xf
    800025de:	cde50513          	addi	a0,a0,-802 # 800112b8 <wait_lock>
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	5e0080e7          	jalr	1504(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800025ea:	4a89                	li	s5,2
        havekids = 1;
    800025ec:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025ee:	6985                	lui	s3,0x1
    800025f0:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    800025f4:	00031a17          	auipc	s4,0x31
    800025f8:	10ca0a13          	addi	s4,s4,268 # 80033700 <tickslock>
    havekids = 0;
    800025fc:	4701                	li	a4,0
    for(np = proc; np < &proc[NPROC]; np++){
    800025fe:	0000f497          	auipc	s1,0xf
    80002602:	10248493          	addi	s1,s1,258 # 80011700 <proc>
    80002606:	a0b5                	j	80002672 <wait+0xba>
          pid = np->pid;
    80002608:	0244a983          	lw	s3,36(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000260c:	000b8e63          	beqz	s7,80002628 <wait+0x70>
    80002610:	4691                	li	a3,4
    80002612:	02048613          	addi	a2,s1,32
    80002616:	85de                	mv	a1,s7
    80002618:	1d893503          	ld	a0,472(s2)
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	046080e7          	jalr	70(ra) # 80001662 <copyout>
    80002624:	02054563          	bltz	a0,8000264e <wait+0x96>
          freeproc(np);
    80002628:	8526                	mv	a0,s1
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	60a080e7          	jalr	1546(ra) # 80001c34 <freeproc>
          release(&np->lock);
    80002632:	8526                	mv	a0,s1
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	654080e7          	jalr	1620(ra) # 80000c88 <release>
          release(&wait_lock);
    8000263c:	0000f517          	auipc	a0,0xf
    80002640:	c7c50513          	addi	a0,a0,-900 # 800112b8 <wait_lock>
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	644080e7          	jalr	1604(ra) # 80000c88 <release>
          return pid;
    8000264c:	a09d                	j	800026b2 <wait+0xfa>
            release(&np->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	638080e7          	jalr	1592(ra) # 80000c88 <release>
            release(&wait_lock);
    80002658:	0000f517          	auipc	a0,0xf
    8000265c:	c6050513          	addi	a0,a0,-928 # 800112b8 <wait_lock>
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	628080e7          	jalr	1576(ra) # 80000c88 <release>
            return -1;
    80002668:	59fd                	li	s3,-1
    8000266a:	a0a1                	j	800026b2 <wait+0xfa>
    for(np = proc; np < &proc[NPROC]; np++){
    8000266c:	94ce                	add	s1,s1,s3
    8000266e:	03448563          	beq	s1,s4,80002698 <wait+0xe0>
      if(np->parent == p){
    80002672:	1c84b783          	ld	a5,456(s1)
    80002676:	ff279be3          	bne	a5,s2,8000266c <wait+0xb4>
        acquire(&np->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	546080e7          	jalr	1350(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002684:	4c9c                	lw	a5,24(s1)
    80002686:	f95781e3          	beq	a5,s5,80002608 <wait+0x50>
        release(&np->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	5fc080e7          	jalr	1532(ra) # 80000c88 <release>
        havekids = 1;
    80002694:	875a                	mv	a4,s6
    80002696:	bfd9                	j	8000266c <wait+0xb4>
    if(!havekids || p->killed){
    80002698:	c701                	beqz	a4,800026a0 <wait+0xe8>
    8000269a:	01c92783          	lw	a5,28(s2)
    8000269e:	c795                	beqz	a5,800026ca <wait+0x112>
      release(&wait_lock);
    800026a0:	0000f517          	auipc	a0,0xf
    800026a4:	c1850513          	addi	a0,a0,-1000 # 800112b8 <wait_lock>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	5e0080e7          	jalr	1504(ra) # 80000c88 <release>
      return -1;
    800026b0:	59fd                	li	s3,-1
}
    800026b2:	854e                	mv	a0,s3
    800026b4:	60a6                	ld	ra,72(sp)
    800026b6:	6406                	ld	s0,64(sp)
    800026b8:	74e2                	ld	s1,56(sp)
    800026ba:	7942                	ld	s2,48(sp)
    800026bc:	79a2                	ld	s3,40(sp)
    800026be:	7a02                	ld	s4,32(sp)
    800026c0:	6ae2                	ld	s5,24(sp)
    800026c2:	6b42                	ld	s6,16(sp)
    800026c4:	6ba2                	ld	s7,8(sp)
    800026c6:	6161                	addi	sp,sp,80
    800026c8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026ca:	0000f597          	auipc	a1,0xf
    800026ce:	bee58593          	addi	a1,a1,-1042 # 800112b8 <wait_lock>
    800026d2:	854a                	mv	a0,s2
    800026d4:	00000097          	auipc	ra,0x0
    800026d8:	e80080e7          	jalr	-384(ra) # 80002554 <sleep>
    havekids = 0;
    800026dc:	b705                	j	800025fc <wait+0x44>

00000000800026de <wakeup>:
// Wake up all threads sleeping on chan.
// Must be called without any p->lock.
// ADDED Q3
void
wakeup(void *chan)
{
    800026de:	715d                	addi	sp,sp,-80
    800026e0:	e486                	sd	ra,72(sp)
    800026e2:	e0a2                	sd	s0,64(sp)
    800026e4:	fc26                	sd	s1,56(sp)
    800026e6:	f84a                	sd	s2,48(sp)
    800026e8:	f44e                	sd	s3,40(sp)
    800026ea:	f052                	sd	s4,32(sp)
    800026ec:	ec56                	sd	s5,24(sp)
    800026ee:	e85a                	sd	s6,16(sp)
    800026f0:	e45e                	sd	s7,8(sp)
    800026f2:	0880                	addi	s0,sp,80
    800026f4:	8a2a                	mv	s4,a0
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f6:	00010917          	auipc	s2,0x10
    800026fa:	88290913          	addi	s2,s2,-1918 # 80011f78 <proc+0x878>
    800026fe:	00032b17          	auipc	s6,0x32
    80002702:	87ab0b13          	addi	s6,s6,-1926 # 80033f78 <bcache+0x860>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
      if(t != mythread()){
        acquire(&t->lock);
        if (t->state == SLEEPING && t->chan == chan) {
    80002706:	4989                	li	s3,2
          t->state = RUNNABLE;
    80002708:	4b8d                	li	s7,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000270a:	6a85                	lui	s5,0x1
    8000270c:	880a8a93          	addi	s5,s5,-1920 # 880 <_entry-0x7ffff780>
    80002710:	a089                	j	80002752 <wakeup+0x74>
        }
        release(&t->lock);
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	574080e7          	jalr	1396(ra) # 80000c88 <release>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000271c:	0c048493          	addi	s1,s1,192
    80002720:	03248663          	beq	s1,s2,8000274c <wakeup+0x6e>
      if(t != mythread()){
    80002724:	fffff097          	auipc	ra,0xfffff
    80002728:	318080e7          	jalr	792(ra) # 80001a3c <mythread>
    8000272c:	fea488e3          	beq	s1,a0,8000271c <wakeup+0x3e>
        acquire(&t->lock);
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	490080e7          	jalr	1168(ra) # 80000bc2 <acquire>
        if (t->state == SLEEPING && t->chan == chan) {
    8000273a:	4c9c                	lw	a5,24(s1)
    8000273c:	fd379be3          	bne	a5,s3,80002712 <wakeup+0x34>
    80002740:	709c                	ld	a5,32(s1)
    80002742:	fd4798e3          	bne	a5,s4,80002712 <wakeup+0x34>
          t->state = RUNNABLE;
    80002746:	0174ac23          	sw	s7,24(s1)
    8000274a:	b7e1                	j	80002712 <wakeup+0x34>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000274c:	9956                	add	s2,s2,s5
    8000274e:	01690563          	beq	s2,s6,80002758 <wakeup+0x7a>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002752:	a0090493          	addi	s1,s2,-1536
    80002756:	b7f9                	j	80002724 <wakeup+0x46>
      }
    }
  }
}
    80002758:	60a6                	ld	ra,72(sp)
    8000275a:	6406                	ld	s0,64(sp)
    8000275c:	74e2                	ld	s1,56(sp)
    8000275e:	7942                	ld	s2,48(sp)
    80002760:	79a2                	ld	s3,40(sp)
    80002762:	7a02                	ld	s4,32(sp)
    80002764:	6ae2                	ld	s5,24(sp)
    80002766:	6b42                	ld	s6,16(sp)
    80002768:	6ba2                	ld	s7,8(sp)
    8000276a:	6161                	addi	sp,sp,80
    8000276c:	8082                	ret

000000008000276e <reparent>:
{
    8000276e:	7139                	addi	sp,sp,-64
    80002770:	fc06                	sd	ra,56(sp)
    80002772:	f822                	sd	s0,48(sp)
    80002774:	f426                	sd	s1,40(sp)
    80002776:	f04a                	sd	s2,32(sp)
    80002778:	ec4e                	sd	s3,24(sp)
    8000277a:	e852                	sd	s4,16(sp)
    8000277c:	e456                	sd	s5,8(sp)
    8000277e:	0080                	addi	s0,sp,64
    80002780:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002782:	0000f497          	auipc	s1,0xf
    80002786:	f7e48493          	addi	s1,s1,-130 # 80011700 <proc>
      pp->parent = initproc;
    8000278a:	00007a97          	auipc	s5,0x7
    8000278e:	89ea8a93          	addi	s5,s5,-1890 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002792:	6905                	lui	s2,0x1
    80002794:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    80002798:	00031a17          	auipc	s4,0x31
    8000279c:	f68a0a13          	addi	s4,s4,-152 # 80033700 <tickslock>
    800027a0:	a021                	j	800027a8 <reparent+0x3a>
    800027a2:	94ca                	add	s1,s1,s2
    800027a4:	01448f63          	beq	s1,s4,800027c2 <reparent+0x54>
    if(pp->parent == p){
    800027a8:	1c84b783          	ld	a5,456(s1)
    800027ac:	ff379be3          	bne	a5,s3,800027a2 <reparent+0x34>
      pp->parent = initproc;
    800027b0:	000ab503          	ld	a0,0(s5)
    800027b4:	1ca4b423          	sd	a0,456(s1)
      wakeup(initproc);
    800027b8:	00000097          	auipc	ra,0x0
    800027bc:	f26080e7          	jalr	-218(ra) # 800026de <wakeup>
    800027c0:	b7cd                	j	800027a2 <reparent+0x34>
}
    800027c2:	70e2                	ld	ra,56(sp)
    800027c4:	7442                	ld	s0,48(sp)
    800027c6:	74a2                	ld	s1,40(sp)
    800027c8:	7902                	ld	s2,32(sp)
    800027ca:	69e2                	ld	s3,24(sp)
    800027cc:	6a42                	ld	s4,16(sp)
    800027ce:	6aa2                	ld	s5,8(sp)
    800027d0:	6121                	addi	sp,sp,64
    800027d2:	8082                	ret

00000000800027d4 <kill>:
// ADDED Q2.2.1
int
kill(int pid, int signum)
{
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    800027d4:	47fd                	li	a5,31
    800027d6:	06b7ef63          	bltu	a5,a1,80002854 <kill+0x80>
{
    800027da:	7139                	addi	sp,sp,-64
    800027dc:	fc06                	sd	ra,56(sp)
    800027de:	f822                	sd	s0,48(sp)
    800027e0:	f426                	sd	s1,40(sp)
    800027e2:	f04a                	sd	s2,32(sp)
    800027e4:	ec4e                	sd	s3,24(sp)
    800027e6:	e852                	sd	s4,16(sp)
    800027e8:	e456                	sd	s5,8(sp)
    800027ea:	0080                	addi	s0,sp,64
    800027ec:	892a                	mv	s2,a0
    800027ee:	8aae                	mv	s5,a1
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    800027f0:	0000f497          	auipc	s1,0xf
    800027f4:	f1048493          	addi	s1,s1,-240 # 80011700 <proc>
    800027f8:	6985                	lui	s3,0x1
    800027fa:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    800027fe:	00031a17          	auipc	s4,0x31
    80002802:	f02a0a13          	addi	s4,s4,-254 # 80033700 <tickslock>
    acquire(&p->lock);
    80002806:	8526                	mv	a0,s1
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	3ba080e7          	jalr	954(ra) # 80000bc2 <acquire>
    if(p->pid == pid) {
    80002810:	50dc                	lw	a5,36(s1)
    80002812:	01278c63          	beq	a5,s2,8000282a <kill+0x56>
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002816:	8526                	mv	a0,s1
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	470080e7          	jalr	1136(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002820:	94ce                	add	s1,s1,s3
    80002822:	ff4492e3          	bne	s1,s4,80002806 <kill+0x32>
  }
  // no such pid
  return -1;
    80002826:	557d                	li	a0,-1
    80002828:	a829                	j	80002842 <kill+0x6e>
      p->pending_signals = p->pending_signals | (1 << signum);
    8000282a:	4785                	li	a5,1
    8000282c:	0157973b          	sllw	a4,a5,s5
    80002830:	549c                	lw	a5,40(s1)
    80002832:	8fd9                	or	a5,a5,a4
    80002834:	d49c                	sw	a5,40(s1)
      release(&p->lock);
    80002836:	8526                	mv	a0,s1
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	450080e7          	jalr	1104(ra) # 80000c88 <release>
      return 0;
    80002840:	4501                	li	a0,0
}
    80002842:	70e2                	ld	ra,56(sp)
    80002844:	7442                	ld	s0,48(sp)
    80002846:	74a2                	ld	s1,40(sp)
    80002848:	7902                	ld	s2,32(sp)
    8000284a:	69e2                	ld	s3,24(sp)
    8000284c:	6a42                	ld	s4,16(sp)
    8000284e:	6aa2                	ld	s5,8(sp)
    80002850:	6121                	addi	sp,sp,64
    80002852:	8082                	ret
    return -1;
    80002854:	557d                	li	a0,-1
}
    80002856:	8082                	ret

0000000080002858 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002858:	7179                	addi	sp,sp,-48
    8000285a:	f406                	sd	ra,40(sp)
    8000285c:	f022                	sd	s0,32(sp)
    8000285e:	ec26                	sd	s1,24(sp)
    80002860:	e84a                	sd	s2,16(sp)
    80002862:	e44e                	sd	s3,8(sp)
    80002864:	e052                	sd	s4,0(sp)
    80002866:	1800                	addi	s0,sp,48
    80002868:	84aa                	mv	s1,a0
    8000286a:	892e                	mv	s2,a1
    8000286c:	89b2                	mv	s3,a2
    8000286e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	192080e7          	jalr	402(ra) # 80001a02 <myproc>
  if(user_dst){
    80002878:	c095                	beqz	s1,8000289c <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    8000287a:	86d2                	mv	a3,s4
    8000287c:	864e                	mv	a2,s3
    8000287e:	85ca                	mv	a1,s2
    80002880:	1d853503          	ld	a0,472(a0)
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	dde080e7          	jalr	-546(ra) # 80001662 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000288c:	70a2                	ld	ra,40(sp)
    8000288e:	7402                	ld	s0,32(sp)
    80002890:	64e2                	ld	s1,24(sp)
    80002892:	6942                	ld	s2,16(sp)
    80002894:	69a2                	ld	s3,8(sp)
    80002896:	6a02                	ld	s4,0(sp)
    80002898:	6145                	addi	sp,sp,48
    8000289a:	8082                	ret
    memmove((char *)dst, src, len);
    8000289c:	000a061b          	sext.w	a2,s4
    800028a0:	85ce                	mv	a1,s3
    800028a2:	854a                	mv	a0,s2
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	49a080e7          	jalr	1178(ra) # 80000d3e <memmove>
    return 0;
    800028ac:	8526                	mv	a0,s1
    800028ae:	bff9                	j	8000288c <either_copyout+0x34>

00000000800028b0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028b0:	7179                	addi	sp,sp,-48
    800028b2:	f406                	sd	ra,40(sp)
    800028b4:	f022                	sd	s0,32(sp)
    800028b6:	ec26                	sd	s1,24(sp)
    800028b8:	e84a                	sd	s2,16(sp)
    800028ba:	e44e                	sd	s3,8(sp)
    800028bc:	e052                	sd	s4,0(sp)
    800028be:	1800                	addi	s0,sp,48
    800028c0:	892a                	mv	s2,a0
    800028c2:	84ae                	mv	s1,a1
    800028c4:	89b2                	mv	s3,a2
    800028c6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	13a080e7          	jalr	314(ra) # 80001a02 <myproc>
  if(user_src){
    800028d0:	c095                	beqz	s1,800028f4 <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    800028d2:	86d2                	mv	a3,s4
    800028d4:	864e                	mv	a2,s3
    800028d6:	85ca                	mv	a1,s2
    800028d8:	1d853503          	ld	a0,472(a0)
    800028dc:	fffff097          	auipc	ra,0xfffff
    800028e0:	e12080e7          	jalr	-494(ra) # 800016ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028e4:	70a2                	ld	ra,40(sp)
    800028e6:	7402                	ld	s0,32(sp)
    800028e8:	64e2                	ld	s1,24(sp)
    800028ea:	6942                	ld	s2,16(sp)
    800028ec:	69a2                	ld	s3,8(sp)
    800028ee:	6a02                	ld	s4,0(sp)
    800028f0:	6145                	addi	sp,sp,48
    800028f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800028f4:	000a061b          	sext.w	a2,s4
    800028f8:	85ce                	mv	a1,s3
    800028fa:	854a                	mv	a0,s2
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	442080e7          	jalr	1090(ra) # 80000d3e <memmove>
    return 0;
    80002904:	8526                	mv	a0,s1
    80002906:	bff9                	j	800028e4 <either_copyin+0x34>

0000000080002908 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002908:	715d                	addi	sp,sp,-80
    8000290a:	e486                	sd	ra,72(sp)
    8000290c:	e0a2                	sd	s0,64(sp)
    8000290e:	fc26                	sd	s1,56(sp)
    80002910:	f84a                	sd	s2,48(sp)
    80002912:	f44e                	sd	s3,40(sp)
    80002914:	f052                	sd	s4,32(sp)
    80002916:	ec56                	sd	s5,24(sp)
    80002918:	e85a                	sd	s6,16(sp)
    8000291a:	e45e                	sd	s7,8(sp)
    8000291c:	e062                	sd	s8,0(sp)
    8000291e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002920:	00005517          	auipc	a0,0x5
    80002924:	7c850513          	addi	a0,a0,1992 # 800080e8 <digits+0xa8>
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	c4c080e7          	jalr	-948(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002930:	0000f497          	auipc	s1,0xf
    80002934:	03848493          	addi	s1,s1,56 # 80011968 <proc+0x268>
    80002938:	00031997          	auipc	s3,0x31
    8000293c:	03098993          	addi	s3,s3,48 # 80033968 <bcache+0x250>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002940:	4b89                	li	s7,2
      state = states[p->state];
    else
      state = "???";
    80002942:	00006a17          	auipc	s4,0x6
    80002946:	92ea0a13          	addi	s4,s4,-1746 # 80008270 <digits+0x230>
    printf("%d %s %s", p->pid, state, p->name);
    8000294a:	00006b17          	auipc	s6,0x6
    8000294e:	92eb0b13          	addi	s6,s6,-1746 # 80008278 <digits+0x238>
    printf("\n");
    80002952:	00005a97          	auipc	s5,0x5
    80002956:	796a8a93          	addi	s5,s5,1942 # 800080e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000295a:	00006c17          	auipc	s8,0x6
    8000295e:	95ec0c13          	addi	s8,s8,-1698 # 800082b8 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    80002962:	6905                	lui	s2,0x1
    80002964:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    80002968:	a005                	j	80002988 <procdump+0x80>
    printf("%d %s %s", p->pid, state, p->name);
    8000296a:	dbc6a583          	lw	a1,-580(a3)
    8000296e:	855a                	mv	a0,s6
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	c04080e7          	jalr	-1020(ra) # 80000574 <printf>
    printf("\n");
    80002978:	8556                	mv	a0,s5
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	bfa080e7          	jalr	-1030(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002982:	94ca                	add	s1,s1,s2
    80002984:	03348263          	beq	s1,s3,800029a8 <procdump+0xa0>
    if(p->state == UNUSED)
    80002988:	86a6                	mv	a3,s1
    8000298a:	db04a783          	lw	a5,-592(s1)
    8000298e:	dbf5                	beqz	a5,80002982 <procdump+0x7a>
      state = "???";
    80002990:	8652                	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002992:	fcfbece3          	bltu	s7,a5,8000296a <procdump+0x62>
    80002996:	02079713          	slli	a4,a5,0x20
    8000299a:	01d75793          	srli	a5,a4,0x1d
    8000299e:	97e2                	add	a5,a5,s8
    800029a0:	6390                	ld	a2,0(a5)
    800029a2:	f661                	bnez	a2,8000296a <procdump+0x62>
      state = "???";
    800029a4:	8652                	mv	a2,s4
    800029a6:	b7d1                	j	8000296a <procdump+0x62>
  }
}
    800029a8:	60a6                	ld	ra,72(sp)
    800029aa:	6406                	ld	s0,64(sp)
    800029ac:	74e2                	ld	s1,56(sp)
    800029ae:	7942                	ld	s2,48(sp)
    800029b0:	79a2                	ld	s3,40(sp)
    800029b2:	7a02                	ld	s4,32(sp)
    800029b4:	6ae2                	ld	s5,24(sp)
    800029b6:	6b42                	ld	s6,16(sp)
    800029b8:	6ba2                	ld	s7,8(sp)
    800029ba:	6c02                	ld	s8,0(sp)
    800029bc:	6161                	addi	sp,sp,80
    800029be:	8082                	ret

00000000800029c0 <sigprocmask>:

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
    800029c0:	7179                	addi	sp,sp,-48
    800029c2:	f406                	sd	ra,40(sp)
    800029c4:	f022                	sd	s0,32(sp)
    800029c6:	ec26                	sd	s1,24(sp)
    800029c8:	e84a                	sd	s2,16(sp)
    800029ca:	e44e                	sd	s3,8(sp)
    800029cc:	1800                	addi	s0,sp,48
    800029ce:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	032080e7          	jalr	50(ra) # 80001a02 <myproc>
    800029d8:	84aa                	mv	s1,a0
  uint old_mask = p->signal_mask;
    800029da:	02c52983          	lw	s3,44(a0)
  acquire(&p->lock);
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	1e4080e7          	jalr	484(ra) # 80000bc2 <acquire>

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    800029e6:	000207b7          	lui	a5,0x20
    800029ea:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    800029ee:	00f977b3          	and	a5,s2,a5
    800029f2:	e385                	bnez	a5,80002a12 <sigprocmask+0x52>
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
    800029f4:	0324a623          	sw	s2,44(s1)
  release(&p->lock);
    800029f8:	8526                	mv	a0,s1
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	28e080e7          	jalr	654(ra) # 80000c88 <release>
  return old_mask;
}
    80002a02:	854e                	mv	a0,s3
    80002a04:	70a2                	ld	ra,40(sp)
    80002a06:	7402                	ld	s0,32(sp)
    80002a08:	64e2                	ld	s1,24(sp)
    80002a0a:	6942                	ld	s2,16(sp)
    80002a0c:	69a2                	ld	s3,8(sp)
    80002a0e:	6145                	addi	sp,sp,48
    80002a10:	8082                	ret
    release(&p->lock);
    80002a12:	8526                	mv	a0,s1
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	274080e7          	jalr	628(ra) # 80000c88 <release>
    return -1;
    80002a1c:	59fd                	li	s3,-1
    80002a1e:	b7d5                	j	80002a02 <sigprocmask+0x42>

0000000080002a20 <sigaction>:

// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
    80002a20:	715d                	addi	sp,sp,-80
    80002a22:	e486                	sd	ra,72(sp)
    80002a24:	e0a2                	sd	s0,64(sp)
    80002a26:	fc26                	sd	s1,56(sp)
    80002a28:	f84a                	sd	s2,48(sp)
    80002a2a:	f44e                	sd	s3,40(sp)
    80002a2c:	f052                	sd	s4,32(sp)
    80002a2e:	0880                	addi	s0,sp,80
    80002a30:	84aa                	mv	s1,a0
    80002a32:	89ae                	mv	s3,a1
    80002a34:	8a32                	mv	s4,a2
  struct proc *p = myproc();
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	fcc080e7          	jalr	-52(ra) # 80001a02 <myproc>
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;

  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    80002a3e:	0004879b          	sext.w	a5,s1
    80002a42:	477d                	li	a4,31
    80002a44:	0cf76763          	bltu	a4,a5,80002b12 <sigaction+0xf2>
    80002a48:	892a                	mv	s2,a0
    80002a4a:	37dd                	addiw	a5,a5,-9
    80002a4c:	9bdd                	andi	a5,a5,-9
    80002a4e:	2781                	sext.w	a5,a5
    80002a50:	c3f9                	beqz	a5,80002b16 <sigaction+0xf6>
    return -1;
  }

  acquire(&p->lock);
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	170080e7          	jalr	368(ra) # 80000bc2 <acquire>

  if(act && copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    80002a5a:	0c098063          	beqz	s3,80002b1a <sigaction+0xfa>
    80002a5e:	46c1                	li	a3,16
    80002a60:	864e                	mv	a2,s3
    80002a62:	fc040593          	addi	a1,s0,-64
    80002a66:	1d893503          	ld	a0,472(s2)
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	c84080e7          	jalr	-892(ra) # 800016ee <copyin>
    80002a72:	08054263          	bltz	a0,80002af6 <sigaction+0xd6>
    release(&p->lock);
    return -1;
  }
  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((kernel_act.sigmask & (1 << SIGKILL)) != 0) || ((kernel_act.sigmask & (1 << SIGSTOP)) != 0)) ) {
    80002a76:	fc843783          	ld	a5,-56(s0)
    80002a7a:	00020737          	lui	a4,0x20
    80002a7e:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    80002a82:	8ff9                	and	a5,a5,a4
    80002a84:	e3c1                	bnez	a5,80002b04 <sigaction+0xe4>
    return -1;
  }

  

  if (oldact) {
    80002a86:	020a0c63          	beqz	s4,80002abe <sigaction+0x9e>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002a8a:	00648793          	addi	a5,s1,6
    80002a8e:	078e                	slli	a5,a5,0x3
    80002a90:	97ca                	add	a5,a5,s2
    80002a92:	679c                	ld	a5,8(a5)
    80002a94:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002a98:	04c48793          	addi	a5,s1,76
    80002a9c:	078a                	slli	a5,a5,0x2
    80002a9e:	97ca                	add	a5,a5,s2
    80002aa0:	479c                	lw	a5,8(a5)
    80002aa2:	faf42c23          	sw	a5,-72(s0)

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002aa6:	46c1                	li	a3,16
    80002aa8:	fb040613          	addi	a2,s0,-80
    80002aac:	85d2                	mv	a1,s4
    80002aae:	1d893503          	ld	a0,472(s2)
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	bb0080e7          	jalr	-1104(ra) # 80001662 <copyout>
    80002aba:	08054c63          	bltz	a0,80002b52 <sigaction+0x132>
      return -1;
    }
  }

  if (act) {
    p->signal_handlers[signum] = kernel_act.sa_handler;
    80002abe:	00648793          	addi	a5,s1,6
    80002ac2:	078e                	slli	a5,a5,0x3
    80002ac4:	97ca                	add	a5,a5,s2
    80002ac6:	fc043703          	ld	a4,-64(s0)
    80002aca:	e798                	sd	a4,8(a5)
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
    80002acc:	04c48493          	addi	s1,s1,76
    80002ad0:	048a                	slli	s1,s1,0x2
    80002ad2:	94ca                	add	s1,s1,s2
    80002ad4:	fc842783          	lw	a5,-56(s0)
    80002ad8:	c49c                	sw	a5,8(s1)
  }

  release(&p->lock);
    80002ada:	854a                	mv	a0,s2
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	1ac080e7          	jalr	428(ra) # 80000c88 <release>
  return 0;
    80002ae4:	4501                	li	a0,0
}
    80002ae6:	60a6                	ld	ra,72(sp)
    80002ae8:	6406                	ld	s0,64(sp)
    80002aea:	74e2                	ld	s1,56(sp)
    80002aec:	7942                	ld	s2,48(sp)
    80002aee:	79a2                	ld	s3,40(sp)
    80002af0:	7a02                	ld	s4,32(sp)
    80002af2:	6161                	addi	sp,sp,80
    80002af4:	8082                	ret
    release(&p->lock);
    80002af6:	854a                	mv	a0,s2
    80002af8:	ffffe097          	auipc	ra,0xffffe
    80002afc:	190080e7          	jalr	400(ra) # 80000c88 <release>
    return -1;
    80002b00:	557d                	li	a0,-1
    80002b02:	b7d5                	j	80002ae6 <sigaction+0xc6>
    release(&p->lock);
    80002b04:	854a                	mv	a0,s2
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	182080e7          	jalr	386(ra) # 80000c88 <release>
    return -1;
    80002b0e:	557d                	li	a0,-1
    80002b10:	bfd9                	j	80002ae6 <sigaction+0xc6>
    return -1;
    80002b12:	557d                	li	a0,-1
    80002b14:	bfc9                	j	80002ae6 <sigaction+0xc6>
    80002b16:	557d                	li	a0,-1
    80002b18:	b7f9                	j	80002ae6 <sigaction+0xc6>
  if (oldact) {
    80002b1a:	fc0a00e3          	beqz	s4,80002ada <sigaction+0xba>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002b1e:	00648793          	addi	a5,s1,6
    80002b22:	078e                	slli	a5,a5,0x3
    80002b24:	97ca                	add	a5,a5,s2
    80002b26:	679c                	ld	a5,8(a5)
    80002b28:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002b2c:	04c48493          	addi	s1,s1,76
    80002b30:	048a                	slli	s1,s1,0x2
    80002b32:	94ca                	add	s1,s1,s2
    80002b34:	449c                	lw	a5,8(s1)
    80002b36:	faf42c23          	sw	a5,-72(s0)
    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002b3a:	46c1                	li	a3,16
    80002b3c:	fb040613          	addi	a2,s0,-80
    80002b40:	85d2                	mv	a1,s4
    80002b42:	1d893503          	ld	a0,472(s2)
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	b1c080e7          	jalr	-1252(ra) # 80001662 <copyout>
    80002b4e:	f80556e3          	bgez	a0,80002ada <sigaction+0xba>
      release(&p->lock);
    80002b52:	854a                	mv	a0,s2
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	134080e7          	jalr	308(ra) # 80000c88 <release>
      return -1;
    80002b5c:	557d                	li	a0,-1
    80002b5e:	b761                	j	80002ae6 <sigaction+0xc6>

0000000080002b60 <sigret>:

// ADDED Q2.1.5
// ADDED Q3
void
sigret(void)
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	e04a                	sd	s2,0(sp)
    80002b6a:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	ed0080e7          	jalr	-304(ra) # 80001a3c <mythread>
    80002b74:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	e8c080e7          	jalr	-372(ra) # 80001a02 <myproc>
    80002b7e:	84aa                	mv	s1,a0

  acquire(&p->lock);
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	042080e7          	jalr	66(ra) # 80000bc2 <acquire>
  acquire(&t->lock);
    80002b88:	854a                	mv	a0,s2
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	038080e7          	jalr	56(ra) # 80000bc2 <acquire>
  memmove(t->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    80002b92:	12000613          	li	a2,288
    80002b96:	1b84b583          	ld	a1,440(s1)
    80002b9a:	04893503          	ld	a0,72(s2)
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	1a0080e7          	jalr	416(ra) # 80000d3e <memmove>
  p->signal_mask = p->signal_mask_backup;
    80002ba6:	589c                	lw	a5,48(s1)
    80002ba8:	d4dc                	sw	a5,44(s1)
  p->handling_user_level_signal = 0;
    80002baa:	1c04a223          	sw	zero,452(s1)
  release(&t->lock);
    80002bae:	854a                	mv	a0,s2
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	0d8080e7          	jalr	216(ra) # 80000c88 <release>
  release(&p->lock);
    80002bb8:	8526                	mv	a0,s1
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	0ce080e7          	jalr	206(ra) # 80000c88 <release>
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6902                	ld	s2,0(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret

0000000080002bce <kthread_create>:
  return t;
}

int
kthread_create(void (*start_func)(), void* stack)
{
    80002bce:	715d                	addi	sp,sp,-80
    80002bd0:	e486                	sd	ra,72(sp)
    80002bd2:	e0a2                	sd	s0,64(sp)
    80002bd4:	fc26                	sd	s1,56(sp)
    80002bd6:	f84a                	sd	s2,48(sp)
    80002bd8:	f44e                	sd	s3,40(sp)
    80002bda:	f052                	sd	s4,32(sp)
    80002bdc:	ec56                	sd	s5,24(sp)
    80002bde:	e85a                	sd	s6,16(sp)
    80002be0:	e45e                	sd	s7,8(sp)
    80002be2:	0880                	addi	s0,sp,80
    80002be4:	8aaa                	mv	s5,a0
    80002be6:	8a2e                	mv	s4,a1
    struct thread* t = mythread();
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	e54080e7          	jalr	-428(ra) # 80001a3c <mythread>
    80002bf0:	8baa                	mv	s7,a0
    struct thread* nt;

    if((nt = allocthread(myproc())) == 0) {
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	e10080e7          	jalr	-496(ra) # 80001a02 <myproc>
    80002bfa:	8b2a                	mv	s6,a0
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80002bfc:	27850493          	addi	s1,a0,632
    int t_index = 0;
    80002c00:	4901                	li	s2,0
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80002c02:	49a1                	li	s3,8
    80002c04:	a819                	j	80002c1a <kthread_create+0x4c>
        release(&t->lock);
    80002c06:	8526                	mv	a0,s1
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	080080e7          	jalr	128(ra) # 80000c88 <release>
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80002c10:	0c048493          	addi	s1,s1,192
    80002c14:	2905                	addiw	s2,s2,1
    80002c16:	0f390363          	beq	s2,s3,80002cfc <kthread_create+0x12e>
      if (t != mythread()) {
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	e22080e7          	jalr	-478(ra) # 80001a3c <mythread>
    80002c22:	fea487e3          	beq	s1,a0,80002c10 <kthread_create+0x42>
        acquire(&t->lock);
    80002c26:	8526                	mv	a0,s1
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	f9a080e7          	jalr	-102(ra) # 80000bc2 <acquire>
        if (t->state == UNUSED_T) {
    80002c30:	4c9c                	lw	a5,24(s1)
    80002c32:	fbf1                	bnez	a5,80002c06 <kthread_create+0x38>
  t->tid = alloctid();
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	ecc080e7          	jalr	-308(ra) # 80001b00 <alloctid>
    80002c3c:	d888                	sw	a0,48(s1)
  t->index = t_index;
    80002c3e:	0324aa23          	sw	s2,52(s1)
  t->state = USED_T;
    80002c42:	4785                	li	a5,1
    80002c44:	cc9c                	sw	a5,24(s1)
  t->trapframe = &p->trapframes[t_index];
    80002c46:	6705                	lui	a4,0x1
    80002c48:	975a                	add	a4,a4,s6
    80002c4a:	00391793          	slli	a5,s2,0x3
    80002c4e:	993e                	add	s2,s2,a5
    80002c50:	0916                	slli	s2,s2,0x5
    80002c52:	87873783          	ld	a5,-1928(a4) # 878 <_entry-0x7ffff788>
    80002c56:	993e                	add	s2,s2,a5
    80002c58:	0524b423          	sd	s2,72(s1)
  t->proc = p;
    80002c5c:	0364bc23          	sd	s6,56(s1)
  memset(&t->context, 0, sizeof(t->context));
    80002c60:	07000613          	li	a2,112
    80002c64:	4581                	li	a1,0
    80002c66:	05048513          	addi	a0,s1,80
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	078080e7          	jalr	120(ra) # 80000ce2 <memset>
  if((t->kstack = (uint64) kalloc()) == 0) {
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	e60080e7          	jalr	-416(ra) # 80000ad2 <kalloc>
    80002c7a:	e0a8                	sd	a0,64(s1)
    80002c7c:	c535                	beqz	a0,80002ce8 <kthread_create+0x11a>
  t->context.sp = t->kstack + PGSIZE;
    80002c7e:	6785                	lui	a5,0x1
    80002c80:	953e                	add	a0,a0,a5
    80002c82:	eca8                	sd	a0,88(s1)
        return -1;
    }
    *nt->trapframe = *t->trapframe;
    80002c84:	048bb683          	ld	a3,72(s7)
    80002c88:	87b6                	mv	a5,a3
    80002c8a:	64b8                	ld	a4,72(s1)
    80002c8c:	12068693          	addi	a3,a3,288
    80002c90:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002c94:	6788                	ld	a0,8(a5)
    80002c96:	6b8c                	ld	a1,16(a5)
    80002c98:	6f90                	ld	a2,24(a5)
    80002c9a:	01073023          	sd	a6,0(a4)
    80002c9e:	e708                	sd	a0,8(a4)
    80002ca0:	eb0c                	sd	a1,16(a4)
    80002ca2:	ef10                	sd	a2,24(a4)
    80002ca4:	02078793          	addi	a5,a5,32
    80002ca8:	02070713          	addi	a4,a4,32
    80002cac:	fed792e3          	bne	a5,a3,80002c90 <kthread_create+0xc2>
    // *nt->context = *t->context; // TODO: check
    nt->trapframe->epc = (uint64)start_func;
    80002cb0:	64bc                	ld	a5,72(s1)
    80002cb2:	0157bc23          	sd	s5,24(a5)
    nt->trapframe->sp = (uint64)(stack + MAX_STACK_SIZE);
    80002cb6:	64b8                	ld	a4,72(s1)
    80002cb8:	6785                	lui	a5,0x1
    80002cba:	fa078793          	addi	a5,a5,-96 # fa0 <_entry-0x7ffff060>
    80002cbe:	97d2                	add	a5,a5,s4
    80002cc0:	fb1c                	sd	a5,48(a4)
    nt->state = RUNNABLE;
    80002cc2:	478d                	li	a5,3
    80002cc4:	cc9c                	sw	a5,24(s1)

    release(&nt->lock);
    80002cc6:	8526                	mv	a0,s1
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	fc0080e7          	jalr	-64(ra) # 80000c88 <release>
    return nt->tid;
    80002cd0:	5888                	lw	a0,48(s1)
}
    80002cd2:	60a6                	ld	ra,72(sp)
    80002cd4:	6406                	ld	s0,64(sp)
    80002cd6:	74e2                	ld	s1,56(sp)
    80002cd8:	7942                	ld	s2,48(sp)
    80002cda:	79a2                	ld	s3,40(sp)
    80002cdc:	7a02                	ld	s4,32(sp)
    80002cde:	6ae2                	ld	s5,24(sp)
    80002ce0:	6b42                	ld	s6,16(sp)
    80002ce2:	6ba2                	ld	s7,8(sp)
    80002ce4:	6161                	addi	sp,sp,80
    80002ce6:	8082                	ret
      freethread(t);
    80002ce8:	8526                	mv	a0,s1
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	b46080e7          	jalr	-1210(ra) # 80001830 <freethread>
      release(&t->lock);
    80002cf2:	8526                	mv	a0,s1
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	f94080e7          	jalr	-108(ra) # 80000c88 <release>
        return -1;
    80002cfc:	557d                	li	a0,-1
    80002cfe:	bfd1                	j	80002cd2 <kthread_create+0x104>

0000000080002d00 <exit_single_thread>:

void
exit_single_thread(int status) {
    80002d00:	7179                	addi	sp,sp,-48
    80002d02:	f406                	sd	ra,40(sp)
    80002d04:	f022                	sd	s0,32(sp)
    80002d06:	ec26                	sd	s1,24(sp)
    80002d08:	e84a                	sd	s2,16(sp)
    80002d0a:	e44e                	sd	s3,8(sp)
    80002d0c:	1800                	addi	s0,sp,48
    80002d0e:	89aa                	mv	s3,a0
  struct thread *t = mythread();
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	d2c080e7          	jalr	-724(ra) # 80001a3c <mythread>
    80002d18:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	ce8080e7          	jalr	-792(ra) # 80001a02 <myproc>
    80002d22:	892a                	mv	s2,a0

  acquire(&t->lock);
    80002d24:	8526                	mv	a0,s1
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	e9c080e7          	jalr	-356(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80002d2e:	0334a623          	sw	s3,44(s1)
  t->state = ZOMBIE_T;
    80002d32:	4795                	li	a5,5
    80002d34:	cc9c                	sw	a5,24(s1)

  release(&p->lock);
    80002d36:	854a                	mv	a0,s2
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	f50080e7          	jalr	-176(ra) # 80000c88 <release>
  wakeup(t);
    80002d40:	8526                	mv	a0,s1
    80002d42:	00000097          	auipc	ra,0x0
    80002d46:	99c080e7          	jalr	-1636(ra) # 800026de <wakeup>
  // Jump into the scheduler, never to return.
  sched();
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	578080e7          	jalr	1400(ra) # 800022c2 <sched>
  panic("zombie exit");
    80002d52:	00005517          	auipc	a0,0x5
    80002d56:	53650513          	addi	a0,a0,1334 # 80008288 <digits+0x248>
    80002d5a:	ffffd097          	auipc	ra,0xffffd
    80002d5e:	7d0080e7          	jalr	2000(ra) # 8000052a <panic>

0000000080002d62 <kthread_join>:
  exit_single_thread(status);
}

int
kthread_join(int thread_id, int *status)
{
    80002d62:	7139                	addi	sp,sp,-64
    80002d64:	fc06                	sd	ra,56(sp)
    80002d66:	f822                	sd	s0,48(sp)
    80002d68:	f426                	sd	s1,40(sp)
    80002d6a:	f04a                	sd	s2,32(sp)
    80002d6c:	ec4e                	sd	s3,24(sp)
    80002d6e:	e852                	sd	s4,16(sp)
    80002d70:	e456                	sd	s5,8(sp)
    80002d72:	e05a                	sd	s6,0(sp)
    80002d74:	0080                	addi	s0,sp,64
    80002d76:	84aa                	mv	s1,a0
    80002d78:	8a2e                	mv	s4,a1
  struct thread *jt  = 0;
  struct proc *p = myproc();  
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	c88080e7          	jalr	-888(ra) # 80001a02 <myproc>
    80002d82:	89aa                	mv	s3,a0

  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002d84:	27850793          	addi	a5,a0,632
    80002d88:	6685                	lui	a3,0x1
    80002d8a:	87868693          	addi	a3,a3,-1928 # 878 <_entry-0x7ffff788>
    80002d8e:	96aa                	add	a3,a3,a0
  struct thread *jt  = 0;
    80002d90:	4901                	li	s2,0
    80002d92:	a029                	j	80002d9c <kthread_join+0x3a>
  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002d94:	0c078793          	addi	a5,a5,192
    80002d98:	00d78763          	beq	a5,a3,80002da6 <kthread_join+0x44>
    if (thread_id == temp_t->tid) {
    80002d9c:	5b98                	lw	a4,48(a5)
    80002d9e:	fe971be3          	bne	a4,s1,80002d94 <kthread_join+0x32>
    80002da2:	893e                	mv	s2,a5
    80002da4:	bfc5                	j	80002d94 <kthread_join+0x32>
      jt = temp_t;
    }
  }  

  if (jt == 0) {
    80002da6:	0a090f63          	beqz	s2,80002e64 <kthread_join+0x102>
    return -1;
  }

  acquire(&join_lock);
    80002daa:	0000f517          	auipc	a0,0xf
    80002dae:	93e50513          	addi	a0,a0,-1730 # 800116e8 <join_lock>
    80002db2:	ffffe097          	auipc	ra,0xffffe
    80002db6:	e10080e7          	jalr	-496(ra) # 80000bc2 <acquire>

  // TODO: deadlock?
  while (1) {
    acquire(&jt->lock);
    80002dba:	84ca                	mv	s1,s2
    if (jt->state == ZOMBIE_T) {
    80002dbc:	4a95                	li	s5,5
      break;
    }
    release(&jt->lock);
    sleep(jt, &join_lock);
    80002dbe:	0000fb17          	auipc	s6,0xf
    80002dc2:	92ab0b13          	addi	s6,s6,-1750 # 800116e8 <join_lock>
    80002dc6:	a821                	j	80002dde <kthread_join+0x7c>
    release(&jt->lock);
    80002dc8:	8526                	mv	a0,s1
    80002dca:	ffffe097          	auipc	ra,0xffffe
    80002dce:	ebe080e7          	jalr	-322(ra) # 80000c88 <release>
    sleep(jt, &join_lock);
    80002dd2:	85da                	mv	a1,s6
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	77e080e7          	jalr	1918(ra) # 80002554 <sleep>
    acquire(&jt->lock);
    80002dde:	8526                	mv	a0,s1
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	de2080e7          	jalr	-542(ra) # 80000bc2 <acquire>
    if (jt->state == ZOMBIE_T) {
    80002de8:	01892783          	lw	a5,24(s2)
    80002dec:	fd579ee3          	bne	a5,s5,80002dc8 <kthread_join+0x66>
  }

  if(status != 0 && copyout(p->pagetable, (uint64)status, (char *)&jt->xstate, sizeof(jt->xstate)) < 0) {
    80002df0:	000a0e63          	beqz	s4,80002e0c <kthread_join+0xaa>
    80002df4:	4691                	li	a3,4
    80002df6:	02c90613          	addi	a2,s2,44
    80002dfa:	85d2                	mv	a1,s4
    80002dfc:	1d89b503          	ld	a0,472(s3)
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	862080e7          	jalr	-1950(ra) # 80001662 <copyout>
    80002e08:	02054f63          	bltz	a0,80002e46 <kthread_join+0xe4>
    release(&jt->lock);
    release(&join_lock);
    return -1;
  }

  freethread(jt);
    80002e0c:	854a                	mv	a0,s2
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	a22080e7          	jalr	-1502(ra) # 80001830 <freethread>
  release(&jt->lock);
    80002e16:	8526                	mv	a0,s1
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	e70080e7          	jalr	-400(ra) # 80000c88 <release>
  release(&join_lock);
    80002e20:	0000f517          	auipc	a0,0xf
    80002e24:	8c850513          	addi	a0,a0,-1848 # 800116e8 <join_lock>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	e60080e7          	jalr	-416(ra) # 80000c88 <release>
  return 0;
    80002e30:	4501                	li	a0,0
}
    80002e32:	70e2                	ld	ra,56(sp)
    80002e34:	7442                	ld	s0,48(sp)
    80002e36:	74a2                	ld	s1,40(sp)
    80002e38:	7902                	ld	s2,32(sp)
    80002e3a:	69e2                	ld	s3,24(sp)
    80002e3c:	6a42                	ld	s4,16(sp)
    80002e3e:	6aa2                	ld	s5,8(sp)
    80002e40:	6b02                	ld	s6,0(sp)
    80002e42:	6121                	addi	sp,sp,64
    80002e44:	8082                	ret
    release(&jt->lock);
    80002e46:	8526                	mv	a0,s1
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	e40080e7          	jalr	-448(ra) # 80000c88 <release>
    release(&join_lock);
    80002e50:	0000f517          	auipc	a0,0xf
    80002e54:	89850513          	addi	a0,a0,-1896 # 800116e8 <join_lock>
    80002e58:	ffffe097          	auipc	ra,0xffffe
    80002e5c:	e30080e7          	jalr	-464(ra) # 80000c88 <release>
    return -1;
    80002e60:	557d                	li	a0,-1
    80002e62:	bfc1                	j	80002e32 <kthread_join+0xd0>
    return -1;
    80002e64:	557d                	li	a0,-1
    80002e66:	b7f1                	j	80002e32 <kthread_join+0xd0>

0000000080002e68 <exit>:
{
    80002e68:	715d                	addi	sp,sp,-80
    80002e6a:	e486                	sd	ra,72(sp)
    80002e6c:	e0a2                	sd	s0,64(sp)
    80002e6e:	fc26                	sd	s1,56(sp)
    80002e70:	f84a                	sd	s2,48(sp)
    80002e72:	f44e                	sd	s3,40(sp)
    80002e74:	f052                	sd	s4,32(sp)
    80002e76:	ec56                	sd	s5,24(sp)
    80002e78:	e85a                	sd	s6,16(sp)
    80002e7a:	e45e                	sd	s7,8(sp)
    80002e7c:	e062                	sd	s8,0(sp)
    80002e7e:	0880                	addi	s0,sp,80
    80002e80:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	b80080e7          	jalr	-1152(ra) # 80001a02 <myproc>
    80002e8a:	89aa                	mv	s3,a0
  if(p == initproc)
    80002e8c:	00006797          	auipc	a5,0x6
    80002e90:	19c7b783          	ld	a5,412(a5) # 80009028 <initproc>
    80002e94:	1e050493          	addi	s1,a0,480
    80002e98:	26050913          	addi	s2,a0,608
    80002e9c:	02a79363          	bne	a5,a0,80002ec2 <exit+0x5a>
    panic("init exiting");
    80002ea0:	00005517          	auipc	a0,0x5
    80002ea4:	3f850513          	addi	a0,a0,1016 # 80008298 <digits+0x258>
    80002ea8:	ffffd097          	auipc	ra,0xffffd
    80002eac:	682080e7          	jalr	1666(ra) # 8000052a <panic>
      fileclose(f);
    80002eb0:	00002097          	auipc	ra,0x2
    80002eb4:	296080e7          	jalr	662(ra) # 80005146 <fileclose>
      p->ofile[fd] = 0;
    80002eb8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002ebc:	04a1                	addi	s1,s1,8
    80002ebe:	01248563          	beq	s1,s2,80002ec8 <exit+0x60>
    if(p->ofile[fd]){
    80002ec2:	6088                	ld	a0,0(s1)
    80002ec4:	f575                	bnez	a0,80002eb0 <exit+0x48>
    80002ec6:	bfdd                	j	80002ebc <exit+0x54>
  begin_op();
    80002ec8:	00002097          	auipc	ra,0x2
    80002ecc:	db2080e7          	jalr	-590(ra) # 80004c7a <begin_op>
  iput(p->cwd);
    80002ed0:	2609b503          	ld	a0,608(s3)
    80002ed4:	00001097          	auipc	ra,0x1
    80002ed8:	58a080e7          	jalr	1418(ra) # 8000445e <iput>
  end_op();
    80002edc:	00002097          	auipc	ra,0x2
    80002ee0:	e1e080e7          	jalr	-482(ra) # 80004cfa <end_op>
  p->cwd = 0;
    80002ee4:	2609b023          	sd	zero,608(s3)
  acquire(&wait_lock);
    80002ee8:	0000e517          	auipc	a0,0xe
    80002eec:	3d050513          	addi	a0,a0,976 # 800112b8 <wait_lock>
    80002ef0:	ffffe097          	auipc	ra,0xffffe
    80002ef4:	cd2080e7          	jalr	-814(ra) # 80000bc2 <acquire>
  reparent(p);
    80002ef8:	854e                	mv	a0,s3
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	874080e7          	jalr	-1932(ra) # 8000276e <reparent>
  wakeup(p->parent);
    80002f02:	1c89b503          	ld	a0,456(s3)
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	7d8080e7          	jalr	2008(ra) # 800026de <wakeup>
  acquire(&p->lock);
    80002f0e:	854e                	mv	a0,s3
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	cb2080e7          	jalr	-846(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002f18:	0359a023          	sw	s5,32(s3)
  p->state = ZOMBIE;
    80002f1c:	4789                	li	a5,2
    80002f1e:	00f9ac23          	sw	a5,24(s3)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002f22:	27898493          	addi	s1,s3,632
    80002f26:	6a05                	lui	s4,0x1
    80002f28:	878a0a13          	addi	s4,s4,-1928 # 878 <_entry-0x7ffff788>
    80002f2c:	9a4e                	add	s4,s4,s3
      t->terminated = 1;
    80002f2e:	4b85                	li	s7,1
      if (t->state == SLEEPING) {
    80002f30:	4b09                	li	s6,2
          t->state = RUNNABLE;
    80002f32:	4c0d                	li	s8,3
    80002f34:	a005                	j	80002f54 <exit+0xec>
      release(&t->lock);
    80002f36:	8526                	mv	a0,s1
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	d50080e7          	jalr	-688(ra) # 80000c88 <release>
      kthread_join(t->tid, 0);
    80002f40:	4581                	li	a1,0
    80002f42:	5888                	lw	a0,48(s1)
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	e1e080e7          	jalr	-482(ra) # 80002d62 <kthread_join>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002f4c:	0c048493          	addi	s1,s1,192
    80002f50:	029a0863          	beq	s4,s1,80002f80 <exit+0x118>
    if (t->tid != mythread()->tid) {
    80002f54:	0304a903          	lw	s2,48(s1)
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	ae4080e7          	jalr	-1308(ra) # 80001a3c <mythread>
    80002f60:	591c                	lw	a5,48(a0)
    80002f62:	ff2785e3          	beq	a5,s2,80002f4c <exit+0xe4>
      acquire(&t->lock);
    80002f66:	8526                	mv	a0,s1
    80002f68:	ffffe097          	auipc	ra,0xffffe
    80002f6c:	c5a080e7          	jalr	-934(ra) # 80000bc2 <acquire>
      t->terminated = 1;
    80002f70:	0374a423          	sw	s7,40(s1)
      if (t->state == SLEEPING) {
    80002f74:	4c9c                	lw	a5,24(s1)
    80002f76:	fd6790e3          	bne	a5,s6,80002f36 <exit+0xce>
          t->state = RUNNABLE;
    80002f7a:	0184ac23          	sw	s8,24(s1)
    80002f7e:	bf65                	j	80002f36 <exit+0xce>
  release(&p->lock);
    80002f80:	854e                	mv	a0,s3
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	d06080e7          	jalr	-762(ra) # 80000c88 <release>
  struct thread *t = mythread();
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	ab2080e7          	jalr	-1358(ra) # 80001a3c <mythread>
    80002f92:	84aa                	mv	s1,a0
  acquire(&t->lock);
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	c2e080e7          	jalr	-978(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80002f9c:	0354a623          	sw	s5,44(s1)
  t->state = ZOMBIE_T;
    80002fa0:	4795                	li	a5,5
    80002fa2:	cc9c                	sw	a5,24(s1)
  release(&wait_lock);
    80002fa4:	0000e517          	auipc	a0,0xe
    80002fa8:	31450513          	addi	a0,a0,788 # 800112b8 <wait_lock>
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	cdc080e7          	jalr	-804(ra) # 80000c88 <release>
  sched();
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	30e080e7          	jalr	782(ra) # 800022c2 <sched>
  panic("zombie exit");
    80002fbc:	00005517          	auipc	a0,0x5
    80002fc0:	2cc50513          	addi	a0,a0,716 # 80008288 <digits+0x248>
    80002fc4:	ffffd097          	auipc	ra,0xffffd
    80002fc8:	566080e7          	jalr	1382(ra) # 8000052a <panic>

0000000080002fcc <kthread_exit>:
{
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	e426                	sd	s1,8(sp)
    80002fd4:	e04a                	sd	s2,0(sp)
    80002fd6:	1000                	addi	s0,sp,32
    80002fd8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	a28080e7          	jalr	-1496(ra) # 80001a02 <myproc>
    80002fe2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	bde080e7          	jalr	-1058(ra) # 80000bc2 <acquire>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002fec:	27848793          	addi	a5,s1,632
    80002ff0:	6685                	lui	a3,0x1
    80002ff2:	87868693          	addi	a3,a3,-1928 # 878 <_entry-0x7ffff788>
    80002ff6:	96a6                	add	a3,a3,s1
  int used_threads = 0;
    80002ff8:	4601                	li	a2,0
    80002ffa:	a029                	j	80003004 <kthread_exit+0x38>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002ffc:	0c078793          	addi	a5,a5,192
    80003000:	00f68663          	beq	a3,a5,8000300c <kthread_exit+0x40>
    if (t->state != UNUSED_T) {
    80003004:	4f98                	lw	a4,24(a5)
    80003006:	db7d                	beqz	a4,80002ffc <kthread_exit+0x30>
      used_threads++;
    80003008:	2605                	addiw	a2,a2,1
    8000300a:	bfcd                	j	80002ffc <kthread_exit+0x30>
  if (used_threads <= 1) {
    8000300c:	4785                	li	a5,1
    8000300e:	00c7d763          	bge	a5,a2,8000301c <kthread_exit+0x50>
  exit_single_thread(status);
    80003012:	854a                	mv	a0,s2
    80003014:	00000097          	auipc	ra,0x0
    80003018:	cec080e7          	jalr	-788(ra) # 80002d00 <exit_single_thread>
    release(&p->lock);
    8000301c:	8526                	mv	a0,s1
    8000301e:	ffffe097          	auipc	ra,0xffffe
    80003022:	c6a080e7          	jalr	-918(ra) # 80000c88 <release>
    exit(status);
    80003026:	854a                	mv	a0,s2
    80003028:	00000097          	auipc	ra,0x0
    8000302c:	e40080e7          	jalr	-448(ra) # 80002e68 <exit>

0000000080003030 <swtch>:
    80003030:	00153023          	sd	ra,0(a0)
    80003034:	00253423          	sd	sp,8(a0)
    80003038:	e900                	sd	s0,16(a0)
    8000303a:	ed04                	sd	s1,24(a0)
    8000303c:	03253023          	sd	s2,32(a0)
    80003040:	03353423          	sd	s3,40(a0)
    80003044:	03453823          	sd	s4,48(a0)
    80003048:	03553c23          	sd	s5,56(a0)
    8000304c:	05653023          	sd	s6,64(a0)
    80003050:	05753423          	sd	s7,72(a0)
    80003054:	05853823          	sd	s8,80(a0)
    80003058:	05953c23          	sd	s9,88(a0)
    8000305c:	07a53023          	sd	s10,96(a0)
    80003060:	07b53423          	sd	s11,104(a0)
    80003064:	0005b083          	ld	ra,0(a1)
    80003068:	0085b103          	ld	sp,8(a1)
    8000306c:	6980                	ld	s0,16(a1)
    8000306e:	6d84                	ld	s1,24(a1)
    80003070:	0205b903          	ld	s2,32(a1)
    80003074:	0285b983          	ld	s3,40(a1)
    80003078:	0305ba03          	ld	s4,48(a1)
    8000307c:	0385ba83          	ld	s5,56(a1)
    80003080:	0405bb03          	ld	s6,64(a1)
    80003084:	0485bb83          	ld	s7,72(a1)
    80003088:	0505bc03          	ld	s8,80(a1)
    8000308c:	0585bc83          	ld	s9,88(a1)
    80003090:	0605bd03          	ld	s10,96(a1)
    80003094:	0685bd83          	ld	s11,104(a1)
    80003098:	8082                	ret

000000008000309a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000309a:	1141                	addi	sp,sp,-16
    8000309c:	e406                	sd	ra,8(sp)
    8000309e:	e022                	sd	s0,0(sp)
    800030a0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800030a2:	00005597          	auipc	a1,0x5
    800030a6:	22e58593          	addi	a1,a1,558 # 800082d0 <states.0+0x18>
    800030aa:	00030517          	auipc	a0,0x30
    800030ae:	65650513          	addi	a0,a0,1622 # 80033700 <tickslock>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	a80080e7          	jalr	-1408(ra) # 80000b32 <initlock>
}
    800030ba:	60a2                	ld	ra,8(sp)
    800030bc:	6402                	ld	s0,0(sp)
    800030be:	0141                	addi	sp,sp,16
    800030c0:	8082                	ret

00000000800030c2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800030c2:	1141                	addi	sp,sp,-16
    800030c4:	e422                	sd	s0,8(sp)
    800030c6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030c8:	00003797          	auipc	a5,0x3
    800030cc:	75878793          	addi	a5,a5,1880 # 80006820 <kernelvec>
    800030d0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800030d4:	6422                	ld	s0,8(sp)
    800030d6:	0141                	addi	sp,sp,16
    800030d8:	8082                	ret

00000000800030da <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800030da:	1101                	addi	sp,sp,-32
    800030dc:	ec06                	sd	ra,24(sp)
    800030de:	e822                	sd	s0,16(sp)
    800030e0:	e426                	sd	s1,8(sp)
    800030e2:	e04a                	sd	s2,0(sp)
    800030e4:	1000                	addi	s0,sp,32
  struct thread *t = mythread(); // ADDED Q3
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	956080e7          	jalr	-1706(ra) # 80001a3c <mythread>
    800030ee:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030f0:	fffff097          	auipc	ra,0xfffff
    800030f4:	912080e7          	jalr	-1774(ra) # 80001a02 <myproc>
    800030f8:	892a                	mv	s2,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800030fe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003100:	10079073          	csrw	sstatus,a5

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();
  handle_signals(); // ADDED Q2.4 
    80003104:	fffff097          	auipc	ra,0xfffff
    80003108:	324080e7          	jalr	804(ra) # 80002428 <handle_signals>
  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000310c:	00004617          	auipc	a2,0x4
    80003110:	ef460613          	addi	a2,a2,-268 # 80007000 <_trampoline>
    80003114:	00004697          	auipc	a3,0x4
    80003118:	eec68693          	addi	a3,a3,-276 # 80007000 <_trampoline>
    8000311c:	8e91                	sub	a3,a3,a2
    8000311e:	040007b7          	lui	a5,0x4000
    80003122:	17fd                	addi	a5,a5,-1
    80003124:	07b2                	slli	a5,a5,0xc
    80003126:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003128:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  t->trapframe->kernel_satp = r_satp();         // kernel page table
    8000312c:	64b8                	ld	a4,72(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000312e:	180026f3          	csrr	a3,satp
    80003132:	e314                	sd	a3,0(a4)
  t->trapframe->kernel_sp = t->kstack + PGSIZE; // thread's kernel stack
    80003134:	64b8                	ld	a4,72(s1)
    80003136:	60b4                	ld	a3,64(s1)
    80003138:	6585                	lui	a1,0x1
    8000313a:	96ae                	add	a3,a3,a1
    8000313c:	e714                	sd	a3,8(a4)
  t->trapframe->kernel_trap = (uint64)usertrap;
    8000313e:	64b8                	ld	a4,72(s1)
    80003140:	00000697          	auipc	a3,0x0
    80003144:	14a68693          	addi	a3,a3,330 # 8000328a <usertrap>
    80003148:	eb14                	sd	a3,16(a4)
  t->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000314a:	64b8                	ld	a4,72(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000314c:	8692                	mv	a3,tp
    8000314e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003150:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003154:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003158:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000315c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(t->trapframe->epc);
    80003160:	64b8                	ld	a4,72(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003162:	6f18                	ld	a4,24(a4)
    80003164:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003168:	1d893583          	ld	a1,472(s2)
    8000316c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    8000316e:	58d8                	lw	a4,52(s1)
    80003170:	00371513          	slli	a0,a4,0x3
    80003174:	953a                	add	a0,a0,a4
    80003176:	0516                	slli	a0,a0,0x5
    80003178:	020006b7          	lui	a3,0x2000
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000317c:	00004717          	auipc	a4,0x4
    80003180:	f1470713          	addi	a4,a4,-236 # 80007090 <userret>
    80003184:	8f11                	sub	a4,a4,a2
    80003186:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    80003188:	577d                	li	a4,-1
    8000318a:	177e                	slli	a4,a4,0x3f
    8000318c:	8dd9                	or	a1,a1,a4
    8000318e:	16fd                	addi	a3,a3,-1
    80003190:	06b6                	slli	a3,a3,0xd
    80003192:	9536                	add	a0,a0,a3
    80003194:	9782                	jalr	a5
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6902                	ld	s2,0(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret

00000000800031a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800031a2:	1101                	addi	sp,sp,-32
    800031a4:	ec06                	sd	ra,24(sp)
    800031a6:	e822                	sd	s0,16(sp)
    800031a8:	e426                	sd	s1,8(sp)
    800031aa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800031ac:	00030497          	auipc	s1,0x30
    800031b0:	55448493          	addi	s1,s1,1364 # 80033700 <tickslock>
    800031b4:	8526                	mv	a0,s1
    800031b6:	ffffe097          	auipc	ra,0xffffe
    800031ba:	a0c080e7          	jalr	-1524(ra) # 80000bc2 <acquire>
  ticks++;
    800031be:	00006517          	auipc	a0,0x6
    800031c2:	e7250513          	addi	a0,a0,-398 # 80009030 <ticks>
    800031c6:	411c                	lw	a5,0(a0)
    800031c8:	2785                	addiw	a5,a5,1
    800031ca:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800031cc:	fffff097          	auipc	ra,0xfffff
    800031d0:	512080e7          	jalr	1298(ra) # 800026de <wakeup>
  release(&tickslock);
    800031d4:	8526                	mv	a0,s1
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	ab2080e7          	jalr	-1358(ra) # 80000c88 <release>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	64a2                	ld	s1,8(sp)
    800031e4:	6105                	addi	sp,sp,32
    800031e6:	8082                	ret

00000000800031e8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800031e8:	1101                	addi	sp,sp,-32
    800031ea:	ec06                	sd	ra,24(sp)
    800031ec:	e822                	sd	s0,16(sp)
    800031ee:	e426                	sd	s1,8(sp)
    800031f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031f2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800031f6:	00074d63          	bltz	a4,80003210 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800031fa:	57fd                	li	a5,-1
    800031fc:	17fe                	slli	a5,a5,0x3f
    800031fe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003200:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003202:	06f70363          	beq	a4,a5,80003268 <devintr+0x80>
  }
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6105                	addi	sp,sp,32
    8000320e:	8082                	ret
     (scause & 0xff) == 9){
    80003210:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003214:	46a5                	li	a3,9
    80003216:	fed792e3          	bne	a5,a3,800031fa <devintr+0x12>
    int irq = plic_claim();
    8000321a:	00003097          	auipc	ra,0x3
    8000321e:	70e080e7          	jalr	1806(ra) # 80006928 <plic_claim>
    80003222:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003224:	47a9                	li	a5,10
    80003226:	02f50763          	beq	a0,a5,80003254 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000322a:	4785                	li	a5,1
    8000322c:	02f50963          	beq	a0,a5,8000325e <devintr+0x76>
    return 1;
    80003230:	4505                	li	a0,1
    } else if(irq){
    80003232:	d8f1                	beqz	s1,80003206 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003234:	85a6                	mv	a1,s1
    80003236:	00005517          	auipc	a0,0x5
    8000323a:	0a250513          	addi	a0,a0,162 # 800082d8 <states.0+0x20>
    8000323e:	ffffd097          	auipc	ra,0xffffd
    80003242:	336080e7          	jalr	822(ra) # 80000574 <printf>
      plic_complete(irq);
    80003246:	8526                	mv	a0,s1
    80003248:	00003097          	auipc	ra,0x3
    8000324c:	704080e7          	jalr	1796(ra) # 8000694c <plic_complete>
    return 1;
    80003250:	4505                	li	a0,1
    80003252:	bf55                	j	80003206 <devintr+0x1e>
      uartintr();
    80003254:	ffffd097          	auipc	ra,0xffffd
    80003258:	732080e7          	jalr	1842(ra) # 80000986 <uartintr>
    8000325c:	b7ed                	j	80003246 <devintr+0x5e>
      virtio_disk_intr();
    8000325e:	00004097          	auipc	ra,0x4
    80003262:	b80080e7          	jalr	-1152(ra) # 80006dde <virtio_disk_intr>
    80003266:	b7c5                	j	80003246 <devintr+0x5e>
    if(cpuid() == 0){
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	76e080e7          	jalr	1902(ra) # 800019d6 <cpuid>
    80003270:	c901                	beqz	a0,80003280 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003272:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003276:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003278:	14479073          	csrw	sip,a5
    return 2;
    8000327c:	4509                	li	a0,2
    8000327e:	b761                	j	80003206 <devintr+0x1e>
      clockintr();
    80003280:	00000097          	auipc	ra,0x0
    80003284:	f22080e7          	jalr	-222(ra) # 800031a2 <clockintr>
    80003288:	b7ed                	j	80003272 <devintr+0x8a>

000000008000328a <usertrap>:
{
    8000328a:	7179                	addi	sp,sp,-48
    8000328c:	f406                	sd	ra,40(sp)
    8000328e:	f022                	sd	s0,32(sp)
    80003290:	ec26                	sd	s1,24(sp)
    80003292:	e84a                	sd	s2,16(sp)
    80003294:	e44e                	sd	s3,8(sp)
    80003296:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003298:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000329c:	1007f793          	andi	a5,a5,256
    800032a0:	e3c9                	bnez	a5,80003322 <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032a2:	00003797          	auipc	a5,0x3
    800032a6:	57e78793          	addi	a5,a5,1406 # 80006820 <kernelvec>
    800032aa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	754080e7          	jalr	1876(ra) # 80001a02 <myproc>
    800032b6:	892a                	mv	s2,a0
  struct thread *t = mythread(); // ADDED Q3
    800032b8:	ffffe097          	auipc	ra,0xffffe
    800032bc:	784080e7          	jalr	1924(ra) # 80001a3c <mythread>
    800032c0:	84aa                	mv	s1,a0
  t->trapframe->epc = r_sepc();
    800032c2:	653c                	ld	a5,72(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032c4:	14102773          	csrr	a4,sepc
    800032c8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032ca:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800032ce:	47a1                	li	a5,8
    800032d0:	06f71d63          	bne	a4,a5,8000334a <usertrap+0xc0>
    if(p->killed)
    800032d4:	01c92783          	lw	a5,28(s2)
    800032d8:	efa9                	bnez	a5,80003332 <usertrap+0xa8>
    if (t->terminated) {
    800032da:	549c                	lw	a5,40(s1)
    800032dc:	e3ad                	bnez	a5,8000333e <usertrap+0xb4>
    t->trapframe->epc += 4;
    800032de:	64b8                	ld	a4,72(s1)
    800032e0:	6f1c                	ld	a5,24(a4)
    800032e2:	0791                	addi	a5,a5,4
    800032e4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800032ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032ee:	10079073          	csrw	sstatus,a5
    syscall();
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	302080e7          	jalr	770(ra) # 800035f4 <syscall>
  int which_dev = 0;
    800032fa:	4981                	li	s3,0
  if(p->killed)
    800032fc:	01c92783          	lw	a5,28(s2)
    80003300:	e7d1                	bnez	a5,8000338c <usertrap+0x102>
  if (t->terminated) {
    80003302:	549c                	lw	a5,40(s1)
    80003304:	ebd1                	bnez	a5,80003398 <usertrap+0x10e>
  if(which_dev == 2)
    80003306:	4789                	li	a5,2
    80003308:	08f98e63          	beq	s3,a5,800033a4 <usertrap+0x11a>
  usertrapret();
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	dce080e7          	jalr	-562(ra) # 800030da <usertrapret>
}
    80003314:	70a2                	ld	ra,40(sp)
    80003316:	7402                	ld	s0,32(sp)
    80003318:	64e2                	ld	s1,24(sp)
    8000331a:	6942                	ld	s2,16(sp)
    8000331c:	69a2                	ld	s3,8(sp)
    8000331e:	6145                	addi	sp,sp,48
    80003320:	8082                	ret
    panic("usertrap: not from user mode");
    80003322:	00005517          	auipc	a0,0x5
    80003326:	fd650513          	addi	a0,a0,-42 # 800082f8 <states.0+0x40>
    8000332a:	ffffd097          	auipc	ra,0xffffd
    8000332e:	200080e7          	jalr	512(ra) # 8000052a <panic>
      exit(-1);
    80003332:	557d                	li	a0,-1
    80003334:	00000097          	auipc	ra,0x0
    80003338:	b34080e7          	jalr	-1228(ra) # 80002e68 <exit>
    8000333c:	bf79                	j	800032da <usertrap+0x50>
      kthread_exit(-1);
    8000333e:	557d                	li	a0,-1
    80003340:	00000097          	auipc	ra,0x0
    80003344:	c8c080e7          	jalr	-884(ra) # 80002fcc <kthread_exit>
    80003348:	bf59                	j	800032de <usertrap+0x54>
  } else if((which_dev = devintr()) != 0){
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	e9e080e7          	jalr	-354(ra) # 800031e8 <devintr>
    80003352:	89aa                	mv	s3,a0
    80003354:	f545                	bnez	a0,800032fc <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003356:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000335a:	02492603          	lw	a2,36(s2)
    8000335e:	00005517          	auipc	a0,0x5
    80003362:	fba50513          	addi	a0,a0,-70 # 80008318 <states.0+0x60>
    80003366:	ffffd097          	auipc	ra,0xffffd
    8000336a:	20e080e7          	jalr	526(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000336e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003372:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003376:	00005517          	auipc	a0,0x5
    8000337a:	fd250513          	addi	a0,a0,-46 # 80008348 <states.0+0x90>
    8000337e:	ffffd097          	auipc	ra,0xffffd
    80003382:	1f6080e7          	jalr	502(ra) # 80000574 <printf>
    p->killed = 1;
    80003386:	4785                	li	a5,1
    80003388:	00f92e23          	sw	a5,28(s2)
    exit(-1);
    8000338c:	557d                	li	a0,-1
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	ada080e7          	jalr	-1318(ra) # 80002e68 <exit>
    80003396:	b7b5                	j	80003302 <usertrap+0x78>
    kthread_exit(-1);
    80003398:	557d                	li	a0,-1
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	c32080e7          	jalr	-974(ra) # 80002fcc <kthread_exit>
    800033a2:	b795                	j	80003306 <usertrap+0x7c>
    yield();
    800033a4:	fffff097          	auipc	ra,0xfffff
    800033a8:	ff4080e7          	jalr	-12(ra) # 80002398 <yield>
    800033ac:	b785                	j	8000330c <usertrap+0x82>

00000000800033ae <kerneltrap>:
{
    800033ae:	7179                	addi	sp,sp,-48
    800033b0:	f406                	sd	ra,40(sp)
    800033b2:	f022                	sd	s0,32(sp)
    800033b4:	ec26                	sd	s1,24(sp)
    800033b6:	e84a                	sd	s2,16(sp)
    800033b8:	e44e                	sd	s3,8(sp)
    800033ba:	e052                	sd	s4,0(sp)
    800033bc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033be:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033c2:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033c6:	14202a73          	csrr	s4,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800033ca:	10097793          	andi	a5,s2,256
    800033ce:	cf95                	beqz	a5,8000340a <kerneltrap+0x5c>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800033d4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800033d6:	e3b1                	bnez	a5,8000341a <kerneltrap+0x6c>
  if((which_dev = devintr()) == 0){
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	e10080e7          	jalr	-496(ra) # 800031e8 <devintr>
    800033e0:	84aa                	mv	s1,a0
    800033e2:	c521                	beqz	a0,8000342a <kerneltrap+0x7c>
  struct thread *t = mythread();
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	658080e7          	jalr	1624(ra) # 80001a3c <mythread>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    800033ec:	4789                	li	a5,2
    800033ee:	06f48b63          	beq	s1,a5,80003464 <kerneltrap+0xb6>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800033f2:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033f6:	10091073          	csrw	sstatus,s2
}
    800033fa:	70a2                	ld	ra,40(sp)
    800033fc:	7402                	ld	s0,32(sp)
    800033fe:	64e2                	ld	s1,24(sp)
    80003400:	6942                	ld	s2,16(sp)
    80003402:	69a2                	ld	s3,8(sp)
    80003404:	6a02                	ld	s4,0(sp)
    80003406:	6145                	addi	sp,sp,48
    80003408:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000340a:	00005517          	auipc	a0,0x5
    8000340e:	f5e50513          	addi	a0,a0,-162 # 80008368 <states.0+0xb0>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	118080e7          	jalr	280(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	f7650513          	addi	a0,a0,-138 # 80008390 <states.0+0xd8>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	108080e7          	jalr	264(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000342a:	85d2                	mv	a1,s4
    8000342c:	00005517          	auipc	a0,0x5
    80003430:	f8450513          	addi	a0,a0,-124 # 800083b0 <states.0+0xf8>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	140080e7          	jalr	320(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000343c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003440:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003444:	00005517          	auipc	a0,0x5
    80003448:	f7c50513          	addi	a0,a0,-132 # 800083c0 <states.0+0x108>
    8000344c:	ffffd097          	auipc	ra,0xffffd
    80003450:	128080e7          	jalr	296(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	f8450513          	addi	a0,a0,-124 # 800083d8 <states.0+0x120>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0ce080e7          	jalr	206(ra) # 8000052a <panic>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    80003464:	d559                	beqz	a0,800033f2 <kerneltrap+0x44>
    80003466:	4d18                	lw	a4,24(a0)
    80003468:	4791                	li	a5,4
    8000346a:	f8f714e3          	bne	a4,a5,800033f2 <kerneltrap+0x44>
    yield();
    8000346e:	fffff097          	auipc	ra,0xfffff
    80003472:	f2a080e7          	jalr	-214(ra) # 80002398 <yield>
    80003476:	bfb5                	j	800033f2 <kerneltrap+0x44>

0000000080003478 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003478:	1101                	addi	sp,sp,-32
    8000347a:	ec06                	sd	ra,24(sp)
    8000347c:	e822                	sd	s0,16(sp)
    8000347e:	e426                	sd	s1,8(sp)
    80003480:	1000                	addi	s0,sp,32
    80003482:	84aa                	mv	s1,a0
  struct thread *t = mythread();
    80003484:	ffffe097          	auipc	ra,0xffffe
    80003488:	5b8080e7          	jalr	1464(ra) # 80001a3c <mythread>
  switch (n) {
    8000348c:	4795                	li	a5,5
    8000348e:	0497e163          	bltu	a5,s1,800034d0 <argraw+0x58>
    80003492:	048a                	slli	s1,s1,0x2
    80003494:	00005717          	auipc	a4,0x5
    80003498:	f7c70713          	addi	a4,a4,-132 # 80008410 <states.0+0x158>
    8000349c:	94ba                	add	s1,s1,a4
    8000349e:	409c                	lw	a5,0(s1)
    800034a0:	97ba                	add	a5,a5,a4
    800034a2:	8782                	jr	a5
  case 0:
    return t->trapframe->a0;
    800034a4:	653c                	ld	a5,72(a0)
    800034a6:	7ba8                	ld	a0,112(a5)
  case 5:
    return t->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	64a2                	ld	s1,8(sp)
    800034ae:	6105                	addi	sp,sp,32
    800034b0:	8082                	ret
    return t->trapframe->a1;
    800034b2:	653c                	ld	a5,72(a0)
    800034b4:	7fa8                	ld	a0,120(a5)
    800034b6:	bfcd                	j	800034a8 <argraw+0x30>
    return t->trapframe->a2;
    800034b8:	653c                	ld	a5,72(a0)
    800034ba:	63c8                	ld	a0,128(a5)
    800034bc:	b7f5                	j	800034a8 <argraw+0x30>
    return t->trapframe->a3;
    800034be:	653c                	ld	a5,72(a0)
    800034c0:	67c8                	ld	a0,136(a5)
    800034c2:	b7dd                	j	800034a8 <argraw+0x30>
    return t->trapframe->a4;
    800034c4:	653c                	ld	a5,72(a0)
    800034c6:	6bc8                	ld	a0,144(a5)
    800034c8:	b7c5                	j	800034a8 <argraw+0x30>
    return t->trapframe->a5;
    800034ca:	653c                	ld	a5,72(a0)
    800034cc:	6fc8                	ld	a0,152(a5)
    800034ce:	bfe9                	j	800034a8 <argraw+0x30>
  panic("argraw");
    800034d0:	00005517          	auipc	a0,0x5
    800034d4:	f1850513          	addi	a0,a0,-232 # 800083e8 <states.0+0x130>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	052080e7          	jalr	82(ra) # 8000052a <panic>

00000000800034e0 <fetchaddr>:
{
    800034e0:	1101                	addi	sp,sp,-32
    800034e2:	ec06                	sd	ra,24(sp)
    800034e4:	e822                	sd	s0,16(sp)
    800034e6:	e426                	sd	s1,8(sp)
    800034e8:	e04a                	sd	s2,0(sp)
    800034ea:	1000                	addi	s0,sp,32
    800034ec:	84aa                	mv	s1,a0
    800034ee:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800034f0:	ffffe097          	auipc	ra,0xffffe
    800034f4:	512080e7          	jalr	1298(ra) # 80001a02 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800034f8:	1d053783          	ld	a5,464(a0)
    800034fc:	02f4f963          	bgeu	s1,a5,8000352e <fetchaddr+0x4e>
    80003500:	00848713          	addi	a4,s1,8
    80003504:	02e7e763          	bltu	a5,a4,80003532 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003508:	46a1                	li	a3,8
    8000350a:	8626                	mv	a2,s1
    8000350c:	85ca                	mv	a1,s2
    8000350e:	1d853503          	ld	a0,472(a0)
    80003512:	ffffe097          	auipc	ra,0xffffe
    80003516:	1dc080e7          	jalr	476(ra) # 800016ee <copyin>
    8000351a:	00a03533          	snez	a0,a0
    8000351e:	40a00533          	neg	a0,a0
}
    80003522:	60e2                	ld	ra,24(sp)
    80003524:	6442                	ld	s0,16(sp)
    80003526:	64a2                	ld	s1,8(sp)
    80003528:	6902                	ld	s2,0(sp)
    8000352a:	6105                	addi	sp,sp,32
    8000352c:	8082                	ret
    return -1;
    8000352e:	557d                	li	a0,-1
    80003530:	bfcd                	j	80003522 <fetchaddr+0x42>
    80003532:	557d                	li	a0,-1
    80003534:	b7fd                	j	80003522 <fetchaddr+0x42>

0000000080003536 <fetchstr>:
{
    80003536:	7179                	addi	sp,sp,-48
    80003538:	f406                	sd	ra,40(sp)
    8000353a:	f022                	sd	s0,32(sp)
    8000353c:	ec26                	sd	s1,24(sp)
    8000353e:	e84a                	sd	s2,16(sp)
    80003540:	e44e                	sd	s3,8(sp)
    80003542:	1800                	addi	s0,sp,48
    80003544:	892a                	mv	s2,a0
    80003546:	84ae                	mv	s1,a1
    80003548:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000354a:	ffffe097          	auipc	ra,0xffffe
    8000354e:	4b8080e7          	jalr	1208(ra) # 80001a02 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003552:	86ce                	mv	a3,s3
    80003554:	864a                	mv	a2,s2
    80003556:	85a6                	mv	a1,s1
    80003558:	1d853503          	ld	a0,472(a0)
    8000355c:	ffffe097          	auipc	ra,0xffffe
    80003560:	220080e7          	jalr	544(ra) # 8000177c <copyinstr>
  if(err < 0)
    80003564:	00054763          	bltz	a0,80003572 <fetchstr+0x3c>
  return strlen(buf);
    80003568:	8526                	mv	a0,s1
    8000356a:	ffffe097          	auipc	ra,0xffffe
    8000356e:	8fc080e7          	jalr	-1796(ra) # 80000e66 <strlen>
}
    80003572:	70a2                	ld	ra,40(sp)
    80003574:	7402                	ld	s0,32(sp)
    80003576:	64e2                	ld	s1,24(sp)
    80003578:	6942                	ld	s2,16(sp)
    8000357a:	69a2                	ld	s3,8(sp)
    8000357c:	6145                	addi	sp,sp,48
    8000357e:	8082                	ret

0000000080003580 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003580:	1101                	addi	sp,sp,-32
    80003582:	ec06                	sd	ra,24(sp)
    80003584:	e822                	sd	s0,16(sp)
    80003586:	e426                	sd	s1,8(sp)
    80003588:	1000                	addi	s0,sp,32
    8000358a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	eec080e7          	jalr	-276(ra) # 80003478 <argraw>
    80003594:	c088                	sw	a0,0(s1)
  return 0;
}
    80003596:	4501                	li	a0,0
    80003598:	60e2                	ld	ra,24(sp)
    8000359a:	6442                	ld	s0,16(sp)
    8000359c:	64a2                	ld	s1,8(sp)
    8000359e:	6105                	addi	sp,sp,32
    800035a0:	8082                	ret

00000000800035a2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800035a2:	1101                	addi	sp,sp,-32
    800035a4:	ec06                	sd	ra,24(sp)
    800035a6:	e822                	sd	s0,16(sp)
    800035a8:	e426                	sd	s1,8(sp)
    800035aa:	1000                	addi	s0,sp,32
    800035ac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	eca080e7          	jalr	-310(ra) # 80003478 <argraw>
    800035b6:	e088                	sd	a0,0(s1)
  return 0;
}
    800035b8:	4501                	li	a0,0
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6105                	addi	sp,sp,32
    800035c2:	8082                	ret

00000000800035c4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	e04a                	sd	s2,0(sp)
    800035ce:	1000                	addi	s0,sp,32
    800035d0:	84ae                	mv	s1,a1
    800035d2:	8932                	mv	s2,a2
  *ip = argraw(n);
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	ea4080e7          	jalr	-348(ra) # 80003478 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800035dc:	864a                	mv	a2,s2
    800035de:	85a6                	mv	a1,s1
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	f56080e7          	jalr	-170(ra) # 80003536 <fetchstr>
}
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	64a2                	ld	s1,8(sp)
    800035ee:	6902                	ld	s2,0(sp)
    800035f0:	6105                	addi	sp,sp,32
    800035f2:	8082                	ret

00000000800035f4 <syscall>:
[SYS_kthread_join]   sys_kthread_join,
};

void
syscall(void)
{
    800035f4:	1101                	addi	sp,sp,-32
    800035f6:	ec06                	sd	ra,24(sp)
    800035f8:	e822                	sd	s0,16(sp)
    800035fa:	e426                	sd	s1,8(sp)
    800035fc:	e04a                	sd	s2,0(sp)
    800035fe:	1000                	addi	s0,sp,32
  int num;
  struct thread *t = mythread();
    80003600:	ffffe097          	auipc	ra,0xffffe
    80003604:	43c080e7          	jalr	1084(ra) # 80001a3c <mythread>
    80003608:	84aa                	mv	s1,a0

  num = t->trapframe->a7;
    8000360a:	04853903          	ld	s2,72(a0)
    8000360e:	0a893783          	ld	a5,168(s2)
    80003612:	0007861b          	sext.w	a2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003616:	37fd                	addiw	a5,a5,-1
    80003618:	476d                	li	a4,27
    8000361a:	00f76f63          	bltu	a4,a5,80003638 <syscall+0x44>
    8000361e:	00361713          	slli	a4,a2,0x3
    80003622:	00005797          	auipc	a5,0x5
    80003626:	e0678793          	addi	a5,a5,-506 # 80008428 <syscalls>
    8000362a:	97ba                	add	a5,a5,a4
    8000362c:	639c                	ld	a5,0(a5)
    8000362e:	c789                	beqz	a5,80003638 <syscall+0x44>
    t->trapframe->a0 = syscalls[num]();
    80003630:	9782                	jalr	a5
    80003632:	06a93823          	sd	a0,112(s2)
    80003636:	a829                	j	80003650 <syscall+0x5c>
  } else {
    printf("thread %d: unknown sys call %d\n",
    80003638:	588c                	lw	a1,48(s1)
    8000363a:	00005517          	auipc	a0,0x5
    8000363e:	db650513          	addi	a0,a0,-586 # 800083f0 <states.0+0x138>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	f32080e7          	jalr	-206(ra) # 80000574 <printf>
            t->tid, num);
    t->trapframe->a0 = -1;
    8000364a:	64bc                	ld	a5,72(s1)
    8000364c:	577d                	li	a4,-1
    8000364e:	fbb8                	sd	a4,112(a5)
  }
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6902                	ld	s2,0(sp)
    80003658:	6105                	addi	sp,sp,32
    8000365a:	8082                	ret

000000008000365c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000365c:	1101                	addi	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003664:	fec40593          	addi	a1,s0,-20
    80003668:	4501                	li	a0,0
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	f16080e7          	jalr	-234(ra) # 80003580 <argint>
    return -1;
    80003672:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003674:	00054963          	bltz	a0,80003686 <sys_exit+0x2a>
  exit(n);
    80003678:	fec42503          	lw	a0,-20(s0)
    8000367c:	fffff097          	auipc	ra,0xfffff
    80003680:	7ec080e7          	jalr	2028(ra) # 80002e68 <exit>
  return 0;  // not reached
    80003684:	4781                	li	a5,0
}
    80003686:	853e                	mv	a0,a5
    80003688:	60e2                	ld	ra,24(sp)
    8000368a:	6442                	ld	s0,16(sp)
    8000368c:	6105                	addi	sp,sp,32
    8000368e:	8082                	ret

0000000080003690 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003690:	1141                	addi	sp,sp,-16
    80003692:	e406                	sd	ra,8(sp)
    80003694:	e022                	sd	s0,0(sp)
    80003696:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003698:	ffffe097          	auipc	ra,0xffffe
    8000369c:	36a080e7          	jalr	874(ra) # 80001a02 <myproc>
}
    800036a0:	5148                	lw	a0,36(a0)
    800036a2:	60a2                	ld	ra,8(sp)
    800036a4:	6402                	ld	s0,0(sp)
    800036a6:	0141                	addi	sp,sp,16
    800036a8:	8082                	ret

00000000800036aa <sys_fork>:

uint64
sys_fork(void)
{
    800036aa:	1141                	addi	sp,sp,-16
    800036ac:	e406                	sd	ra,8(sp)
    800036ae:	e022                	sd	s0,0(sp)
    800036b0:	0800                	addi	s0,sp,16
  return fork();
    800036b2:	fffff097          	auipc	ra,0xfffff
    800036b6:	878080e7          	jalr	-1928(ra) # 80001f2a <fork>
}
    800036ba:	60a2                	ld	ra,8(sp)
    800036bc:	6402                	ld	s0,0(sp)
    800036be:	0141                	addi	sp,sp,16
    800036c0:	8082                	ret

00000000800036c2 <sys_wait>:

uint64
sys_wait(void)
{
    800036c2:	1101                	addi	sp,sp,-32
    800036c4:	ec06                	sd	ra,24(sp)
    800036c6:	e822                	sd	s0,16(sp)
    800036c8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800036ca:	fe840593          	addi	a1,s0,-24
    800036ce:	4501                	li	a0,0
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	ed2080e7          	jalr	-302(ra) # 800035a2 <argaddr>
    800036d8:	87aa                	mv	a5,a0
    return -1;
    800036da:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800036dc:	0007c863          	bltz	a5,800036ec <sys_wait+0x2a>
  return wait(p);
    800036e0:	fe843503          	ld	a0,-24(s0)
    800036e4:	fffff097          	auipc	ra,0xfffff
    800036e8:	ed4080e7          	jalr	-300(ra) # 800025b8 <wait>
}
    800036ec:	60e2                	ld	ra,24(sp)
    800036ee:	6442                	ld	s0,16(sp)
    800036f0:	6105                	addi	sp,sp,32
    800036f2:	8082                	ret

00000000800036f4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800036f4:	7179                	addi	sp,sp,-48
    800036f6:	f406                	sd	ra,40(sp)
    800036f8:	f022                	sd	s0,32(sp)
    800036fa:	ec26                	sd	s1,24(sp)
    800036fc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800036fe:	fdc40593          	addi	a1,s0,-36
    80003702:	4501                	li	a0,0
    80003704:	00000097          	auipc	ra,0x0
    80003708:	e7c080e7          	jalr	-388(ra) # 80003580 <argint>
    return -1;
    8000370c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000370e:	02054063          	bltz	a0,8000372e <sys_sbrk+0x3a>
  addr = myproc()->sz;
    80003712:	ffffe097          	auipc	ra,0xffffe
    80003716:	2f0080e7          	jalr	752(ra) # 80001a02 <myproc>
    8000371a:	1d052483          	lw	s1,464(a0)
  if(growproc(n) < 0)
    8000371e:	fdc42503          	lw	a0,-36(s0)
    80003722:	ffffe097          	auipc	ra,0xffffe
    80003726:	76e080e7          	jalr	1902(ra) # 80001e90 <growproc>
    8000372a:	00054863          	bltz	a0,8000373a <sys_sbrk+0x46>
    return -1;
  return addr;
}
    8000372e:	8526                	mv	a0,s1
    80003730:	70a2                	ld	ra,40(sp)
    80003732:	7402                	ld	s0,32(sp)
    80003734:	64e2                	ld	s1,24(sp)
    80003736:	6145                	addi	sp,sp,48
    80003738:	8082                	ret
    return -1;
    8000373a:	54fd                	li	s1,-1
    8000373c:	bfcd                	j	8000372e <sys_sbrk+0x3a>

000000008000373e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000373e:	7139                	addi	sp,sp,-64
    80003740:	fc06                	sd	ra,56(sp)
    80003742:	f822                	sd	s0,48(sp)
    80003744:	f426                	sd	s1,40(sp)
    80003746:	f04a                	sd	s2,32(sp)
    80003748:	ec4e                	sd	s3,24(sp)
    8000374a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000374c:	fcc40593          	addi	a1,s0,-52
    80003750:	4501                	li	a0,0
    80003752:	00000097          	auipc	ra,0x0
    80003756:	e2e080e7          	jalr	-466(ra) # 80003580 <argint>
    return -1;
    8000375a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000375c:	06054563          	bltz	a0,800037c6 <sys_sleep+0x88>
  acquire(&tickslock);
    80003760:	00030517          	auipc	a0,0x30
    80003764:	fa050513          	addi	a0,a0,-96 # 80033700 <tickslock>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	45a080e7          	jalr	1114(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003770:	00006917          	auipc	s2,0x6
    80003774:	8c092903          	lw	s2,-1856(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003778:	fcc42783          	lw	a5,-52(s0)
    8000377c:	cf85                	beqz	a5,800037b4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000377e:	00030997          	auipc	s3,0x30
    80003782:	f8298993          	addi	s3,s3,-126 # 80033700 <tickslock>
    80003786:	00006497          	auipc	s1,0x6
    8000378a:	8aa48493          	addi	s1,s1,-1878 # 80009030 <ticks>
    if(myproc()->killed){
    8000378e:	ffffe097          	auipc	ra,0xffffe
    80003792:	274080e7          	jalr	628(ra) # 80001a02 <myproc>
    80003796:	4d5c                	lw	a5,28(a0)
    80003798:	ef9d                	bnez	a5,800037d6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000379a:	85ce                	mv	a1,s3
    8000379c:	8526                	mv	a0,s1
    8000379e:	fffff097          	auipc	ra,0xfffff
    800037a2:	db6080e7          	jalr	-586(ra) # 80002554 <sleep>
  while(ticks - ticks0 < n){
    800037a6:	409c                	lw	a5,0(s1)
    800037a8:	412787bb          	subw	a5,a5,s2
    800037ac:	fcc42703          	lw	a4,-52(s0)
    800037b0:	fce7efe3          	bltu	a5,a4,8000378e <sys_sleep+0x50>
  }
  release(&tickslock);
    800037b4:	00030517          	auipc	a0,0x30
    800037b8:	f4c50513          	addi	a0,a0,-180 # 80033700 <tickslock>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	4cc080e7          	jalr	1228(ra) # 80000c88 <release>
  return 0;
    800037c4:	4781                	li	a5,0
}
    800037c6:	853e                	mv	a0,a5
    800037c8:	70e2                	ld	ra,56(sp)
    800037ca:	7442                	ld	s0,48(sp)
    800037cc:	74a2                	ld	s1,40(sp)
    800037ce:	7902                	ld	s2,32(sp)
    800037d0:	69e2                	ld	s3,24(sp)
    800037d2:	6121                	addi	sp,sp,64
    800037d4:	8082                	ret
      release(&tickslock);
    800037d6:	00030517          	auipc	a0,0x30
    800037da:	f2a50513          	addi	a0,a0,-214 # 80033700 <tickslock>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	4aa080e7          	jalr	1194(ra) # 80000c88 <release>
      return -1;
    800037e6:	57fd                	li	a5,-1
    800037e8:	bff9                	j	800037c6 <sys_sleep+0x88>

00000000800037ea <sys_kill>:

// ADDED Q2.2.1
uint64
sys_kill(void)
{
    800037ea:	1101                	addi	sp,sp,-32
    800037ec:	ec06                	sd	ra,24(sp)
    800037ee:	e822                	sd	s0,16(sp)
    800037f0:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    800037f2:	fec40593          	addi	a1,s0,-20
    800037f6:	4501                	li	a0,0
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	d88080e7          	jalr	-632(ra) # 80003580 <argint>
    return -1;
    80003800:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80003802:	02054563          	bltz	a0,8000382c <sys_kill+0x42>

  if(argint(1, &signum) < 0)
    80003806:	fe840593          	addi	a1,s0,-24
    8000380a:	4505                	li	a0,1
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	d74080e7          	jalr	-652(ra) # 80003580 <argint>
    return -1;
    80003814:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    80003816:	00054b63          	bltz	a0,8000382c <sys_kill+0x42>

  return kill(pid, signum);
    8000381a:	fe842583          	lw	a1,-24(s0)
    8000381e:	fec42503          	lw	a0,-20(s0)
    80003822:	fffff097          	auipc	ra,0xfffff
    80003826:	fb2080e7          	jalr	-78(ra) # 800027d4 <kill>
    8000382a:	87aa                	mv	a5,a0
}
    8000382c:	853e                	mv	a0,a5
    8000382e:	60e2                	ld	ra,24(sp)
    80003830:	6442                	ld	s0,16(sp)
    80003832:	6105                	addi	sp,sp,32
    80003834:	8082                	ret

0000000080003836 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003836:	1101                	addi	sp,sp,-32
    80003838:	ec06                	sd	ra,24(sp)
    8000383a:	e822                	sd	s0,16(sp)
    8000383c:	e426                	sd	s1,8(sp)
    8000383e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003840:	00030517          	auipc	a0,0x30
    80003844:	ec050513          	addi	a0,a0,-320 # 80033700 <tickslock>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	37a080e7          	jalr	890(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003850:	00005497          	auipc	s1,0x5
    80003854:	7e04a483          	lw	s1,2016(s1) # 80009030 <ticks>
  release(&tickslock);
    80003858:	00030517          	auipc	a0,0x30
    8000385c:	ea850513          	addi	a0,a0,-344 # 80033700 <tickslock>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	428080e7          	jalr	1064(ra) # 80000c88 <release>
  return xticks;
}
    80003868:	02049513          	slli	a0,s1,0x20
    8000386c:	9101                	srli	a0,a0,0x20
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6105                	addi	sp,sp,32
    80003876:	8082                	ret

0000000080003878 <sys_sigprocmask>:

// ADDED Q2.1.3
uint64
sys_sigprocmask(void)
{
    80003878:	1101                	addi	sp,sp,-32
    8000387a:	ec06                	sd	ra,24(sp)
    8000387c:	e822                	sd	s0,16(sp)
    8000387e:	1000                	addi	s0,sp,32
  uint sigmask;

  if(argint(0, (int *)&sigmask) < 0) 
    80003880:	fec40593          	addi	a1,s0,-20
    80003884:	4501                	li	a0,0
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	cfa080e7          	jalr	-774(ra) # 80003580 <argint>
    8000388e:	87aa                	mv	a5,a0
    return -1;
    80003890:	557d                	li	a0,-1
  if(argint(0, (int *)&sigmask) < 0) 
    80003892:	0007ca63          	bltz	a5,800038a6 <sys_sigprocmask+0x2e>

  return sigprocmask(sigmask);
    80003896:	fec42503          	lw	a0,-20(s0)
    8000389a:	fffff097          	auipc	ra,0xfffff
    8000389e:	126080e7          	jalr	294(ra) # 800029c0 <sigprocmask>
    800038a2:	1502                	slli	a0,a0,0x20
    800038a4:	9101                	srli	a0,a0,0x20
}
    800038a6:	60e2                	ld	ra,24(sp)
    800038a8:	6442                	ld	s0,16(sp)
    800038aa:	6105                	addi	sp,sp,32
    800038ac:	8082                	ret

00000000800038ae <sys_sigaction>:

// ADDED Q2.1.4
uint64
sys_sigaction(void)
{
    800038ae:	7179                	addi	sp,sp,-48
    800038b0:	f406                	sd	ra,40(sp)
    800038b2:	f022                	sd	s0,32(sp)
    800038b4:	1800                	addi	s0,sp,48
  int signum;
  struct sigaction *act;
  struct sigaction *oldact;

  if(argint(0, &signum) < 0)
    800038b6:	fec40593          	addi	a1,s0,-20
    800038ba:	4501                	li	a0,0
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	cc4080e7          	jalr	-828(ra) # 80003580 <argint>
    return -1;
    800038c4:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    800038c6:	04054163          	bltz	a0,80003908 <sys_sigaction+0x5a>

  if(argaddr(1, (uint64 *)&act) < 0)
    800038ca:	fe040593          	addi	a1,s0,-32
    800038ce:	4505                	li	a0,1
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	cd2080e7          	jalr	-814(ra) # 800035a2 <argaddr>
    return -1;
    800038d8:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&act) < 0)
    800038da:	02054763          	bltz	a0,80003908 <sys_sigaction+0x5a>

  if(argaddr(2, (uint64 *)&oldact) < 0)
    800038de:	fd840593          	addi	a1,s0,-40
    800038e2:	4509                	li	a0,2
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	cbe080e7          	jalr	-834(ra) # 800035a2 <argaddr>
    return -1;
    800038ec:	57fd                	li	a5,-1
  if(argaddr(2, (uint64 *)&oldact) < 0)
    800038ee:	00054d63          	bltz	a0,80003908 <sys_sigaction+0x5a>

  return sigaction(signum, act, oldact);
    800038f2:	fd843603          	ld	a2,-40(s0)
    800038f6:	fe043583          	ld	a1,-32(s0)
    800038fa:	fec42503          	lw	a0,-20(s0)
    800038fe:	fffff097          	auipc	ra,0xfffff
    80003902:	122080e7          	jalr	290(ra) # 80002a20 <sigaction>
    80003906:	87aa                	mv	a5,a0
}
    80003908:	853e                	mv	a0,a5
    8000390a:	70a2                	ld	ra,40(sp)
    8000390c:	7402                	ld	s0,32(sp)
    8000390e:	6145                	addi	sp,sp,48
    80003910:	8082                	ret

0000000080003912 <sys_sigret>:

// ADDED Q2.1.5
uint64
sys_sigret(void)
{
    80003912:	1141                	addi	sp,sp,-16
    80003914:	e406                	sd	ra,8(sp)
    80003916:	e022                	sd	s0,0(sp)
    80003918:	0800                	addi	s0,sp,16
  sigret();
    8000391a:	fffff097          	auipc	ra,0xfffff
    8000391e:	246080e7          	jalr	582(ra) # 80002b60 <sigret>
  return 0;
}
    80003922:	4501                	li	a0,0
    80003924:	60a2                	ld	ra,8(sp)
    80003926:	6402                	ld	s0,0(sp)
    80003928:	0141                	addi	sp,sp,16
    8000392a:	8082                	ret

000000008000392c <sys_kthread_create>:

// ADDED Q3.2
uint64
sys_kthread_create(void)
{
    8000392c:	1101                	addi	sp,sp,-32
    8000392e:	ec06                	sd	ra,24(sp)
    80003930:	e822                	sd	s0,16(sp)
    80003932:	1000                	addi	s0,sp,32
  void (*start_func)();
  void *stack;

  if(argaddr(0, (uint64 *)&start_func) < 0)
    80003934:	fe840593          	addi	a1,s0,-24
    80003938:	4501                	li	a0,0
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	c68080e7          	jalr	-920(ra) # 800035a2 <argaddr>
    return -1;
    80003942:	57fd                	li	a5,-1
  if(argaddr(0, (uint64 *)&start_func) < 0)
    80003944:	02054563          	bltz	a0,8000396e <sys_kthread_create+0x42>

  if(argaddr(1, (uint64 *)&stack) < 0)
    80003948:	fe040593          	addi	a1,s0,-32
    8000394c:	4505                	li	a0,1
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	c54080e7          	jalr	-940(ra) # 800035a2 <argaddr>
    return -1;
    80003956:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&stack) < 0)
    80003958:	00054b63          	bltz	a0,8000396e <sys_kthread_create+0x42>

  return kthread_create(start_func, stack);
    8000395c:	fe043583          	ld	a1,-32(s0)
    80003960:	fe843503          	ld	a0,-24(s0)
    80003964:	fffff097          	auipc	ra,0xfffff
    80003968:	26a080e7          	jalr	618(ra) # 80002bce <kthread_create>
    8000396c:	87aa                	mv	a5,a0
}
    8000396e:	853e                	mv	a0,a5
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	6105                	addi	sp,sp,32
    80003976:	8082                	ret

0000000080003978 <sys_kthread_id>:

uint64
sys_kthread_id(void)
{
    80003978:	1141                	addi	sp,sp,-16
    8000397a:	e406                	sd	ra,8(sp)
    8000397c:	e022                	sd	s0,0(sp)
    8000397e:	0800                	addi	s0,sp,16
  return mythread()->tid;
    80003980:	ffffe097          	auipc	ra,0xffffe
    80003984:	0bc080e7          	jalr	188(ra) # 80001a3c <mythread>
}
    80003988:	5908                	lw	a0,48(a0)
    8000398a:	60a2                	ld	ra,8(sp)
    8000398c:	6402                	ld	s0,0(sp)
    8000398e:	0141                	addi	sp,sp,16
    80003990:	8082                	ret

0000000080003992 <sys_kthread_exit>:

uint64
sys_kthread_exit(void)
{
    80003992:	1101                	addi	sp,sp,-32
    80003994:	ec06                	sd	ra,24(sp)
    80003996:	e822                	sd	s0,16(sp)
    80003998:	1000                	addi	s0,sp,32
  int status;

  if(argint(0, &status) < 0)
    8000399a:	fec40593          	addi	a1,s0,-20
    8000399e:	4501                	li	a0,0
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	be0080e7          	jalr	-1056(ra) # 80003580 <argint>
    return -1;
    800039a8:	57fd                	li	a5,-1
  if(argint(0, &status) < 0)
    800039aa:	00054963          	bltz	a0,800039bc <sys_kthread_exit+0x2a>

  kthread_exit(status);
    800039ae:	fec42503          	lw	a0,-20(s0)
    800039b2:	fffff097          	auipc	ra,0xfffff
    800039b6:	61a080e7          	jalr	1562(ra) # 80002fcc <kthread_exit>
  return 0; //TODO: retval?
    800039ba:	4781                	li	a5,0
}
    800039bc:	853e                	mv	a0,a5
    800039be:	60e2                	ld	ra,24(sp)
    800039c0:	6442                	ld	s0,16(sp)
    800039c2:	6105                	addi	sp,sp,32
    800039c4:	8082                	ret

00000000800039c6 <sys_kthread_join>:

uint64
sys_kthread_join(void)
{
    800039c6:	1101                	addi	sp,sp,-32
    800039c8:	ec06                	sd	ra,24(sp)
    800039ca:	e822                	sd	s0,16(sp)
    800039cc:	1000                	addi	s0,sp,32
  int thread_id;
  int *status;

  if(argint(0, &thread_id) < 0)
    800039ce:	fec40593          	addi	a1,s0,-20
    800039d2:	4501                	li	a0,0
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	bac080e7          	jalr	-1108(ra) # 80003580 <argint>
    return -1;
    800039dc:	57fd                	li	a5,-1
  if(argint(0, &thread_id) < 0)
    800039de:	02054563          	bltz	a0,80003a08 <sys_kthread_join+0x42>

  if(argaddr(1, (uint64 *)&status) < 0)
    800039e2:	fe040593          	addi	a1,s0,-32
    800039e6:	4505                	li	a0,1
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	bba080e7          	jalr	-1094(ra) # 800035a2 <argaddr>
    return -1;
    800039f0:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&status) < 0)
    800039f2:	00054b63          	bltz	a0,80003a08 <sys_kthread_join+0x42>

  return kthread_join(thread_id, status);
    800039f6:	fe043583          	ld	a1,-32(s0)
    800039fa:	fec42503          	lw	a0,-20(s0)
    800039fe:	fffff097          	auipc	ra,0xfffff
    80003a02:	364080e7          	jalr	868(ra) # 80002d62 <kthread_join>
    80003a06:	87aa                	mv	a5,a0
    80003a08:	853e                	mv	a0,a5
    80003a0a:	60e2                	ld	ra,24(sp)
    80003a0c:	6442                	ld	s0,16(sp)
    80003a0e:	6105                	addi	sp,sp,32
    80003a10:	8082                	ret

0000000080003a12 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a12:	7179                	addi	sp,sp,-48
    80003a14:	f406                	sd	ra,40(sp)
    80003a16:	f022                	sd	s0,32(sp)
    80003a18:	ec26                	sd	s1,24(sp)
    80003a1a:	e84a                	sd	s2,16(sp)
    80003a1c:	e44e                	sd	s3,8(sp)
    80003a1e:	e052                	sd	s4,0(sp)
    80003a20:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a22:	00005597          	auipc	a1,0x5
    80003a26:	aee58593          	addi	a1,a1,-1298 # 80008510 <syscalls+0xe8>
    80003a2a:	00030517          	auipc	a0,0x30
    80003a2e:	cee50513          	addi	a0,a0,-786 # 80033718 <bcache>
    80003a32:	ffffd097          	auipc	ra,0xffffd
    80003a36:	100080e7          	jalr	256(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a3a:	00038797          	auipc	a5,0x38
    80003a3e:	cde78793          	addi	a5,a5,-802 # 8003b718 <bcache+0x8000>
    80003a42:	00038717          	auipc	a4,0x38
    80003a46:	f3e70713          	addi	a4,a4,-194 # 8003b980 <bcache+0x8268>
    80003a4a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a4e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a52:	00030497          	auipc	s1,0x30
    80003a56:	cde48493          	addi	s1,s1,-802 # 80033730 <bcache+0x18>
    b->next = bcache.head.next;
    80003a5a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a5c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a5e:	00005a17          	auipc	s4,0x5
    80003a62:	abaa0a13          	addi	s4,s4,-1350 # 80008518 <syscalls+0xf0>
    b->next = bcache.head.next;
    80003a66:	2b893783          	ld	a5,696(s2)
    80003a6a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a6c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a70:	85d2                	mv	a1,s4
    80003a72:	01048513          	addi	a0,s1,16
    80003a76:	00001097          	auipc	ra,0x1
    80003a7a:	4c2080e7          	jalr	1218(ra) # 80004f38 <initsleeplock>
    bcache.head.next->prev = b;
    80003a7e:	2b893783          	ld	a5,696(s2)
    80003a82:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003a84:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a88:	45848493          	addi	s1,s1,1112
    80003a8c:	fd349de3          	bne	s1,s3,80003a66 <binit+0x54>
  }
}
    80003a90:	70a2                	ld	ra,40(sp)
    80003a92:	7402                	ld	s0,32(sp)
    80003a94:	64e2                	ld	s1,24(sp)
    80003a96:	6942                	ld	s2,16(sp)
    80003a98:	69a2                	ld	s3,8(sp)
    80003a9a:	6a02                	ld	s4,0(sp)
    80003a9c:	6145                	addi	sp,sp,48
    80003a9e:	8082                	ret

0000000080003aa0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003aa0:	7179                	addi	sp,sp,-48
    80003aa2:	f406                	sd	ra,40(sp)
    80003aa4:	f022                	sd	s0,32(sp)
    80003aa6:	ec26                	sd	s1,24(sp)
    80003aa8:	e84a                	sd	s2,16(sp)
    80003aaa:	e44e                	sd	s3,8(sp)
    80003aac:	1800                	addi	s0,sp,48
    80003aae:	892a                	mv	s2,a0
    80003ab0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003ab2:	00030517          	auipc	a0,0x30
    80003ab6:	c6650513          	addi	a0,a0,-922 # 80033718 <bcache>
    80003aba:	ffffd097          	auipc	ra,0xffffd
    80003abe:	108080e7          	jalr	264(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003ac2:	00038497          	auipc	s1,0x38
    80003ac6:	f0e4b483          	ld	s1,-242(s1) # 8003b9d0 <bcache+0x82b8>
    80003aca:	00038797          	auipc	a5,0x38
    80003ace:	eb678793          	addi	a5,a5,-330 # 8003b980 <bcache+0x8268>
    80003ad2:	02f48f63          	beq	s1,a5,80003b10 <bread+0x70>
    80003ad6:	873e                	mv	a4,a5
    80003ad8:	a021                	j	80003ae0 <bread+0x40>
    80003ada:	68a4                	ld	s1,80(s1)
    80003adc:	02e48a63          	beq	s1,a4,80003b10 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003ae0:	449c                	lw	a5,8(s1)
    80003ae2:	ff279ce3          	bne	a5,s2,80003ada <bread+0x3a>
    80003ae6:	44dc                	lw	a5,12(s1)
    80003ae8:	ff3799e3          	bne	a5,s3,80003ada <bread+0x3a>
      b->refcnt++;
    80003aec:	40bc                	lw	a5,64(s1)
    80003aee:	2785                	addiw	a5,a5,1
    80003af0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003af2:	00030517          	auipc	a0,0x30
    80003af6:	c2650513          	addi	a0,a0,-986 # 80033718 <bcache>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	18e080e7          	jalr	398(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003b02:	01048513          	addi	a0,s1,16
    80003b06:	00001097          	auipc	ra,0x1
    80003b0a:	46c080e7          	jalr	1132(ra) # 80004f72 <acquiresleep>
      return b;
    80003b0e:	a8b9                	j	80003b6c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b10:	00038497          	auipc	s1,0x38
    80003b14:	eb84b483          	ld	s1,-328(s1) # 8003b9c8 <bcache+0x82b0>
    80003b18:	00038797          	auipc	a5,0x38
    80003b1c:	e6878793          	addi	a5,a5,-408 # 8003b980 <bcache+0x8268>
    80003b20:	00f48863          	beq	s1,a5,80003b30 <bread+0x90>
    80003b24:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b26:	40bc                	lw	a5,64(s1)
    80003b28:	cf81                	beqz	a5,80003b40 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b2a:	64a4                	ld	s1,72(s1)
    80003b2c:	fee49de3          	bne	s1,a4,80003b26 <bread+0x86>
  panic("bget: no buffers");
    80003b30:	00005517          	auipc	a0,0x5
    80003b34:	9f050513          	addi	a0,a0,-1552 # 80008520 <syscalls+0xf8>
    80003b38:	ffffd097          	auipc	ra,0xffffd
    80003b3c:	9f2080e7          	jalr	-1550(ra) # 8000052a <panic>
      b->dev = dev;
    80003b40:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003b44:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003b48:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b4c:	4785                	li	a5,1
    80003b4e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b50:	00030517          	auipc	a0,0x30
    80003b54:	bc850513          	addi	a0,a0,-1080 # 80033718 <bcache>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	130080e7          	jalr	304(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003b60:	01048513          	addi	a0,s1,16
    80003b64:	00001097          	auipc	ra,0x1
    80003b68:	40e080e7          	jalr	1038(ra) # 80004f72 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b6c:	409c                	lw	a5,0(s1)
    80003b6e:	cb89                	beqz	a5,80003b80 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b70:	8526                	mv	a0,s1
    80003b72:	70a2                	ld	ra,40(sp)
    80003b74:	7402                	ld	s0,32(sp)
    80003b76:	64e2                	ld	s1,24(sp)
    80003b78:	6942                	ld	s2,16(sp)
    80003b7a:	69a2                	ld	s3,8(sp)
    80003b7c:	6145                	addi	sp,sp,48
    80003b7e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b80:	4581                	li	a1,0
    80003b82:	8526                	mv	a0,s1
    80003b84:	00003097          	auipc	ra,0x3
    80003b88:	fd2080e7          	jalr	-46(ra) # 80006b56 <virtio_disk_rw>
    b->valid = 1;
    80003b8c:	4785                	li	a5,1
    80003b8e:	c09c                	sw	a5,0(s1)
  return b;
    80003b90:	b7c5                	j	80003b70 <bread+0xd0>

0000000080003b92 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003b92:	1101                	addi	sp,sp,-32
    80003b94:	ec06                	sd	ra,24(sp)
    80003b96:	e822                	sd	s0,16(sp)
    80003b98:	e426                	sd	s1,8(sp)
    80003b9a:	1000                	addi	s0,sp,32
    80003b9c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b9e:	0541                	addi	a0,a0,16
    80003ba0:	00001097          	auipc	ra,0x1
    80003ba4:	46c080e7          	jalr	1132(ra) # 8000500c <holdingsleep>
    80003ba8:	cd01                	beqz	a0,80003bc0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003baa:	4585                	li	a1,1
    80003bac:	8526                	mv	a0,s1
    80003bae:	00003097          	auipc	ra,0x3
    80003bb2:	fa8080e7          	jalr	-88(ra) # 80006b56 <virtio_disk_rw>
}
    80003bb6:	60e2                	ld	ra,24(sp)
    80003bb8:	6442                	ld	s0,16(sp)
    80003bba:	64a2                	ld	s1,8(sp)
    80003bbc:	6105                	addi	sp,sp,32
    80003bbe:	8082                	ret
    panic("bwrite");
    80003bc0:	00005517          	auipc	a0,0x5
    80003bc4:	97850513          	addi	a0,a0,-1672 # 80008538 <syscalls+0x110>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	962080e7          	jalr	-1694(ra) # 8000052a <panic>

0000000080003bd0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003bd0:	1101                	addi	sp,sp,-32
    80003bd2:	ec06                	sd	ra,24(sp)
    80003bd4:	e822                	sd	s0,16(sp)
    80003bd6:	e426                	sd	s1,8(sp)
    80003bd8:	e04a                	sd	s2,0(sp)
    80003bda:	1000                	addi	s0,sp,32
    80003bdc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bde:	01050913          	addi	s2,a0,16
    80003be2:	854a                	mv	a0,s2
    80003be4:	00001097          	auipc	ra,0x1
    80003be8:	428080e7          	jalr	1064(ra) # 8000500c <holdingsleep>
    80003bec:	c92d                	beqz	a0,80003c5e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003bee:	854a                	mv	a0,s2
    80003bf0:	00001097          	auipc	ra,0x1
    80003bf4:	3d8080e7          	jalr	984(ra) # 80004fc8 <releasesleep>

  acquire(&bcache.lock);
    80003bf8:	00030517          	auipc	a0,0x30
    80003bfc:	b2050513          	addi	a0,a0,-1248 # 80033718 <bcache>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	fc2080e7          	jalr	-62(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003c08:	40bc                	lw	a5,64(s1)
    80003c0a:	37fd                	addiw	a5,a5,-1
    80003c0c:	0007871b          	sext.w	a4,a5
    80003c10:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c12:	eb05                	bnez	a4,80003c42 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c14:	68bc                	ld	a5,80(s1)
    80003c16:	64b8                	ld	a4,72(s1)
    80003c18:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c1a:	64bc                	ld	a5,72(s1)
    80003c1c:	68b8                	ld	a4,80(s1)
    80003c1e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c20:	00038797          	auipc	a5,0x38
    80003c24:	af878793          	addi	a5,a5,-1288 # 8003b718 <bcache+0x8000>
    80003c28:	2b87b703          	ld	a4,696(a5)
    80003c2c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c2e:	00038717          	auipc	a4,0x38
    80003c32:	d5270713          	addi	a4,a4,-686 # 8003b980 <bcache+0x8268>
    80003c36:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c38:	2b87b703          	ld	a4,696(a5)
    80003c3c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c3e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c42:	00030517          	auipc	a0,0x30
    80003c46:	ad650513          	addi	a0,a0,-1322 # 80033718 <bcache>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	03e080e7          	jalr	62(ra) # 80000c88 <release>
}
    80003c52:	60e2                	ld	ra,24(sp)
    80003c54:	6442                	ld	s0,16(sp)
    80003c56:	64a2                	ld	s1,8(sp)
    80003c58:	6902                	ld	s2,0(sp)
    80003c5a:	6105                	addi	sp,sp,32
    80003c5c:	8082                	ret
    panic("brelse");
    80003c5e:	00005517          	auipc	a0,0x5
    80003c62:	8e250513          	addi	a0,a0,-1822 # 80008540 <syscalls+0x118>
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	8c4080e7          	jalr	-1852(ra) # 8000052a <panic>

0000000080003c6e <bpin>:

void
bpin(struct buf *b) {
    80003c6e:	1101                	addi	sp,sp,-32
    80003c70:	ec06                	sd	ra,24(sp)
    80003c72:	e822                	sd	s0,16(sp)
    80003c74:	e426                	sd	s1,8(sp)
    80003c76:	1000                	addi	s0,sp,32
    80003c78:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c7a:	00030517          	auipc	a0,0x30
    80003c7e:	a9e50513          	addi	a0,a0,-1378 # 80033718 <bcache>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	f40080e7          	jalr	-192(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003c8a:	40bc                	lw	a5,64(s1)
    80003c8c:	2785                	addiw	a5,a5,1
    80003c8e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c90:	00030517          	auipc	a0,0x30
    80003c94:	a8850513          	addi	a0,a0,-1400 # 80033718 <bcache>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	ff0080e7          	jalr	-16(ra) # 80000c88 <release>
}
    80003ca0:	60e2                	ld	ra,24(sp)
    80003ca2:	6442                	ld	s0,16(sp)
    80003ca4:	64a2                	ld	s1,8(sp)
    80003ca6:	6105                	addi	sp,sp,32
    80003ca8:	8082                	ret

0000000080003caa <bunpin>:

void
bunpin(struct buf *b) {
    80003caa:	1101                	addi	sp,sp,-32
    80003cac:	ec06                	sd	ra,24(sp)
    80003cae:	e822                	sd	s0,16(sp)
    80003cb0:	e426                	sd	s1,8(sp)
    80003cb2:	1000                	addi	s0,sp,32
    80003cb4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cb6:	00030517          	auipc	a0,0x30
    80003cba:	a6250513          	addi	a0,a0,-1438 # 80033718 <bcache>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	f04080e7          	jalr	-252(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003cc6:	40bc                	lw	a5,64(s1)
    80003cc8:	37fd                	addiw	a5,a5,-1
    80003cca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ccc:	00030517          	auipc	a0,0x30
    80003cd0:	a4c50513          	addi	a0,a0,-1460 # 80033718 <bcache>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	fb4080e7          	jalr	-76(ra) # 80000c88 <release>
}
    80003cdc:	60e2                	ld	ra,24(sp)
    80003cde:	6442                	ld	s0,16(sp)
    80003ce0:	64a2                	ld	s1,8(sp)
    80003ce2:	6105                	addi	sp,sp,32
    80003ce4:	8082                	ret

0000000080003ce6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003ce6:	1101                	addi	sp,sp,-32
    80003ce8:	ec06                	sd	ra,24(sp)
    80003cea:	e822                	sd	s0,16(sp)
    80003cec:	e426                	sd	s1,8(sp)
    80003cee:	e04a                	sd	s2,0(sp)
    80003cf0:	1000                	addi	s0,sp,32
    80003cf2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003cf4:	00d5d59b          	srliw	a1,a1,0xd
    80003cf8:	00038797          	auipc	a5,0x38
    80003cfc:	0fc7a783          	lw	a5,252(a5) # 8003bdf4 <sb+0x1c>
    80003d00:	9dbd                	addw	a1,a1,a5
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	d9e080e7          	jalr	-610(ra) # 80003aa0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d0a:	0074f713          	andi	a4,s1,7
    80003d0e:	4785                	li	a5,1
    80003d10:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d14:	14ce                	slli	s1,s1,0x33
    80003d16:	90d9                	srli	s1,s1,0x36
    80003d18:	00950733          	add	a4,a0,s1
    80003d1c:	05874703          	lbu	a4,88(a4)
    80003d20:	00e7f6b3          	and	a3,a5,a4
    80003d24:	c69d                	beqz	a3,80003d52 <bfree+0x6c>
    80003d26:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d28:	94aa                	add	s1,s1,a0
    80003d2a:	fff7c793          	not	a5,a5
    80003d2e:	8ff9                	and	a5,a5,a4
    80003d30:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d34:	00001097          	auipc	ra,0x1
    80003d38:	11e080e7          	jalr	286(ra) # 80004e52 <log_write>
  brelse(bp);
    80003d3c:	854a                	mv	a0,s2
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	e92080e7          	jalr	-366(ra) # 80003bd0 <brelse>
}
    80003d46:	60e2                	ld	ra,24(sp)
    80003d48:	6442                	ld	s0,16(sp)
    80003d4a:	64a2                	ld	s1,8(sp)
    80003d4c:	6902                	ld	s2,0(sp)
    80003d4e:	6105                	addi	sp,sp,32
    80003d50:	8082                	ret
    panic("freeing free block");
    80003d52:	00004517          	auipc	a0,0x4
    80003d56:	7f650513          	addi	a0,a0,2038 # 80008548 <syscalls+0x120>
    80003d5a:	ffffc097          	auipc	ra,0xffffc
    80003d5e:	7d0080e7          	jalr	2000(ra) # 8000052a <panic>

0000000080003d62 <balloc>:
{
    80003d62:	711d                	addi	sp,sp,-96
    80003d64:	ec86                	sd	ra,88(sp)
    80003d66:	e8a2                	sd	s0,80(sp)
    80003d68:	e4a6                	sd	s1,72(sp)
    80003d6a:	e0ca                	sd	s2,64(sp)
    80003d6c:	fc4e                	sd	s3,56(sp)
    80003d6e:	f852                	sd	s4,48(sp)
    80003d70:	f456                	sd	s5,40(sp)
    80003d72:	f05a                	sd	s6,32(sp)
    80003d74:	ec5e                	sd	s7,24(sp)
    80003d76:	e862                	sd	s8,16(sp)
    80003d78:	e466                	sd	s9,8(sp)
    80003d7a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d7c:	00038797          	auipc	a5,0x38
    80003d80:	0607a783          	lw	a5,96(a5) # 8003bddc <sb+0x4>
    80003d84:	cbd1                	beqz	a5,80003e18 <balloc+0xb6>
    80003d86:	8baa                	mv	s7,a0
    80003d88:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003d8a:	00038b17          	auipc	s6,0x38
    80003d8e:	04eb0b13          	addi	s6,s6,78 # 8003bdd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d92:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003d94:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d96:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003d98:	6c89                	lui	s9,0x2
    80003d9a:	a831                	j	80003db6 <balloc+0x54>
    brelse(bp);
    80003d9c:	854a                	mv	a0,s2
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	e32080e7          	jalr	-462(ra) # 80003bd0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003da6:	015c87bb          	addw	a5,s9,s5
    80003daa:	00078a9b          	sext.w	s5,a5
    80003dae:	004b2703          	lw	a4,4(s6)
    80003db2:	06eaf363          	bgeu	s5,a4,80003e18 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003db6:	41fad79b          	sraiw	a5,s5,0x1f
    80003dba:	0137d79b          	srliw	a5,a5,0x13
    80003dbe:	015787bb          	addw	a5,a5,s5
    80003dc2:	40d7d79b          	sraiw	a5,a5,0xd
    80003dc6:	01cb2583          	lw	a1,28(s6)
    80003dca:	9dbd                	addw	a1,a1,a5
    80003dcc:	855e                	mv	a0,s7
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	cd2080e7          	jalr	-814(ra) # 80003aa0 <bread>
    80003dd6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dd8:	004b2503          	lw	a0,4(s6)
    80003ddc:	000a849b          	sext.w	s1,s5
    80003de0:	8662                	mv	a2,s8
    80003de2:	faa4fde3          	bgeu	s1,a0,80003d9c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003de6:	41f6579b          	sraiw	a5,a2,0x1f
    80003dea:	01d7d69b          	srliw	a3,a5,0x1d
    80003dee:	00c6873b          	addw	a4,a3,a2
    80003df2:	00777793          	andi	a5,a4,7
    80003df6:	9f95                	subw	a5,a5,a3
    80003df8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003dfc:	4037571b          	sraiw	a4,a4,0x3
    80003e00:	00e906b3          	add	a3,s2,a4
    80003e04:	0586c683          	lbu	a3,88(a3) # 2000058 <_entry-0x7dffffa8>
    80003e08:	00d7f5b3          	and	a1,a5,a3
    80003e0c:	cd91                	beqz	a1,80003e28 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e0e:	2605                	addiw	a2,a2,1
    80003e10:	2485                	addiw	s1,s1,1
    80003e12:	fd4618e3          	bne	a2,s4,80003de2 <balloc+0x80>
    80003e16:	b759                	j	80003d9c <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e18:	00004517          	auipc	a0,0x4
    80003e1c:	74850513          	addi	a0,a0,1864 # 80008560 <syscalls+0x138>
    80003e20:	ffffc097          	auipc	ra,0xffffc
    80003e24:	70a080e7          	jalr	1802(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e28:	974a                	add	a4,a4,s2
    80003e2a:	8fd5                	or	a5,a5,a3
    80003e2c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e30:	854a                	mv	a0,s2
    80003e32:	00001097          	auipc	ra,0x1
    80003e36:	020080e7          	jalr	32(ra) # 80004e52 <log_write>
        brelse(bp);
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	d94080e7          	jalr	-620(ra) # 80003bd0 <brelse>
  bp = bread(dev, bno);
    80003e44:	85a6                	mv	a1,s1
    80003e46:	855e                	mv	a0,s7
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	c58080e7          	jalr	-936(ra) # 80003aa0 <bread>
    80003e50:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e52:	40000613          	li	a2,1024
    80003e56:	4581                	li	a1,0
    80003e58:	05850513          	addi	a0,a0,88
    80003e5c:	ffffd097          	auipc	ra,0xffffd
    80003e60:	e86080e7          	jalr	-378(ra) # 80000ce2 <memset>
  log_write(bp);
    80003e64:	854a                	mv	a0,s2
    80003e66:	00001097          	auipc	ra,0x1
    80003e6a:	fec080e7          	jalr	-20(ra) # 80004e52 <log_write>
  brelse(bp);
    80003e6e:	854a                	mv	a0,s2
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	d60080e7          	jalr	-672(ra) # 80003bd0 <brelse>
}
    80003e78:	8526                	mv	a0,s1
    80003e7a:	60e6                	ld	ra,88(sp)
    80003e7c:	6446                	ld	s0,80(sp)
    80003e7e:	64a6                	ld	s1,72(sp)
    80003e80:	6906                	ld	s2,64(sp)
    80003e82:	79e2                	ld	s3,56(sp)
    80003e84:	7a42                	ld	s4,48(sp)
    80003e86:	7aa2                	ld	s5,40(sp)
    80003e88:	7b02                	ld	s6,32(sp)
    80003e8a:	6be2                	ld	s7,24(sp)
    80003e8c:	6c42                	ld	s8,16(sp)
    80003e8e:	6ca2                	ld	s9,8(sp)
    80003e90:	6125                	addi	sp,sp,96
    80003e92:	8082                	ret

0000000080003e94 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003e94:	7179                	addi	sp,sp,-48
    80003e96:	f406                	sd	ra,40(sp)
    80003e98:	f022                	sd	s0,32(sp)
    80003e9a:	ec26                	sd	s1,24(sp)
    80003e9c:	e84a                	sd	s2,16(sp)
    80003e9e:	e44e                	sd	s3,8(sp)
    80003ea0:	e052                	sd	s4,0(sp)
    80003ea2:	1800                	addi	s0,sp,48
    80003ea4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ea6:	47ad                	li	a5,11
    80003ea8:	04b7fe63          	bgeu	a5,a1,80003f04 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003eac:	ff45849b          	addiw	s1,a1,-12
    80003eb0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003eb4:	0ff00793          	li	a5,255
    80003eb8:	0ae7e463          	bltu	a5,a4,80003f60 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ebc:	08052583          	lw	a1,128(a0)
    80003ec0:	c5b5                	beqz	a1,80003f2c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003ec2:	00092503          	lw	a0,0(s2)
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	bda080e7          	jalr	-1062(ra) # 80003aa0 <bread>
    80003ece:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ed0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ed4:	02049713          	slli	a4,s1,0x20
    80003ed8:	01e75593          	srli	a1,a4,0x1e
    80003edc:	00b784b3          	add	s1,a5,a1
    80003ee0:	0004a983          	lw	s3,0(s1)
    80003ee4:	04098e63          	beqz	s3,80003f40 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003ee8:	8552                	mv	a0,s4
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	ce6080e7          	jalr	-794(ra) # 80003bd0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ef2:	854e                	mv	a0,s3
    80003ef4:	70a2                	ld	ra,40(sp)
    80003ef6:	7402                	ld	s0,32(sp)
    80003ef8:	64e2                	ld	s1,24(sp)
    80003efa:	6942                	ld	s2,16(sp)
    80003efc:	69a2                	ld	s3,8(sp)
    80003efe:	6a02                	ld	s4,0(sp)
    80003f00:	6145                	addi	sp,sp,48
    80003f02:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f04:	02059793          	slli	a5,a1,0x20
    80003f08:	01e7d593          	srli	a1,a5,0x1e
    80003f0c:	00b504b3          	add	s1,a0,a1
    80003f10:	0504a983          	lw	s3,80(s1)
    80003f14:	fc099fe3          	bnez	s3,80003ef2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f18:	4108                	lw	a0,0(a0)
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	e48080e7          	jalr	-440(ra) # 80003d62 <balloc>
    80003f22:	0005099b          	sext.w	s3,a0
    80003f26:	0534a823          	sw	s3,80(s1)
    80003f2a:	b7e1                	j	80003ef2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003f2c:	4108                	lw	a0,0(a0)
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	e34080e7          	jalr	-460(ra) # 80003d62 <balloc>
    80003f36:	0005059b          	sext.w	a1,a0
    80003f3a:	08b92023          	sw	a1,128(s2)
    80003f3e:	b751                	j	80003ec2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003f40:	00092503          	lw	a0,0(s2)
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	e1e080e7          	jalr	-482(ra) # 80003d62 <balloc>
    80003f4c:	0005099b          	sext.w	s3,a0
    80003f50:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003f54:	8552                	mv	a0,s4
    80003f56:	00001097          	auipc	ra,0x1
    80003f5a:	efc080e7          	jalr	-260(ra) # 80004e52 <log_write>
    80003f5e:	b769                	j	80003ee8 <bmap+0x54>
  panic("bmap: out of range");
    80003f60:	00004517          	auipc	a0,0x4
    80003f64:	61850513          	addi	a0,a0,1560 # 80008578 <syscalls+0x150>
    80003f68:	ffffc097          	auipc	ra,0xffffc
    80003f6c:	5c2080e7          	jalr	1474(ra) # 8000052a <panic>

0000000080003f70 <iget>:
{
    80003f70:	7179                	addi	sp,sp,-48
    80003f72:	f406                	sd	ra,40(sp)
    80003f74:	f022                	sd	s0,32(sp)
    80003f76:	ec26                	sd	s1,24(sp)
    80003f78:	e84a                	sd	s2,16(sp)
    80003f7a:	e44e                	sd	s3,8(sp)
    80003f7c:	e052                	sd	s4,0(sp)
    80003f7e:	1800                	addi	s0,sp,48
    80003f80:	89aa                	mv	s3,a0
    80003f82:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003f84:	00038517          	auipc	a0,0x38
    80003f88:	e7450513          	addi	a0,a0,-396 # 8003bdf8 <itable>
    80003f8c:	ffffd097          	auipc	ra,0xffffd
    80003f90:	c36080e7          	jalr	-970(ra) # 80000bc2 <acquire>
  empty = 0;
    80003f94:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f96:	00038497          	auipc	s1,0x38
    80003f9a:	e7a48493          	addi	s1,s1,-390 # 8003be10 <itable+0x18>
    80003f9e:	0003a697          	auipc	a3,0x3a
    80003fa2:	90268693          	addi	a3,a3,-1790 # 8003d8a0 <log>
    80003fa6:	a039                	j	80003fb4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fa8:	02090b63          	beqz	s2,80003fde <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fac:	08848493          	addi	s1,s1,136
    80003fb0:	02d48a63          	beq	s1,a3,80003fe4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003fb4:	449c                	lw	a5,8(s1)
    80003fb6:	fef059e3          	blez	a5,80003fa8 <iget+0x38>
    80003fba:	4098                	lw	a4,0(s1)
    80003fbc:	ff3716e3          	bne	a4,s3,80003fa8 <iget+0x38>
    80003fc0:	40d8                	lw	a4,4(s1)
    80003fc2:	ff4713e3          	bne	a4,s4,80003fa8 <iget+0x38>
      ip->ref++;
    80003fc6:	2785                	addiw	a5,a5,1
    80003fc8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003fca:	00038517          	auipc	a0,0x38
    80003fce:	e2e50513          	addi	a0,a0,-466 # 8003bdf8 <itable>
    80003fd2:	ffffd097          	auipc	ra,0xffffd
    80003fd6:	cb6080e7          	jalr	-842(ra) # 80000c88 <release>
      return ip;
    80003fda:	8926                	mv	s2,s1
    80003fdc:	a03d                	j	8000400a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fde:	f7f9                	bnez	a5,80003fac <iget+0x3c>
    80003fe0:	8926                	mv	s2,s1
    80003fe2:	b7e9                	j	80003fac <iget+0x3c>
  if(empty == 0)
    80003fe4:	02090c63          	beqz	s2,8000401c <iget+0xac>
  ip->dev = dev;
    80003fe8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003fec:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ff0:	4785                	li	a5,1
    80003ff2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ff6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ffa:	00038517          	auipc	a0,0x38
    80003ffe:	dfe50513          	addi	a0,a0,-514 # 8003bdf8 <itable>
    80004002:	ffffd097          	auipc	ra,0xffffd
    80004006:	c86080e7          	jalr	-890(ra) # 80000c88 <release>
}
    8000400a:	854a                	mv	a0,s2
    8000400c:	70a2                	ld	ra,40(sp)
    8000400e:	7402                	ld	s0,32(sp)
    80004010:	64e2                	ld	s1,24(sp)
    80004012:	6942                	ld	s2,16(sp)
    80004014:	69a2                	ld	s3,8(sp)
    80004016:	6a02                	ld	s4,0(sp)
    80004018:	6145                	addi	sp,sp,48
    8000401a:	8082                	ret
    panic("iget: no inodes");
    8000401c:	00004517          	auipc	a0,0x4
    80004020:	57450513          	addi	a0,a0,1396 # 80008590 <syscalls+0x168>
    80004024:	ffffc097          	auipc	ra,0xffffc
    80004028:	506080e7          	jalr	1286(ra) # 8000052a <panic>

000000008000402c <fsinit>:
fsinit(int dev) {
    8000402c:	7179                	addi	sp,sp,-48
    8000402e:	f406                	sd	ra,40(sp)
    80004030:	f022                	sd	s0,32(sp)
    80004032:	ec26                	sd	s1,24(sp)
    80004034:	e84a                	sd	s2,16(sp)
    80004036:	e44e                	sd	s3,8(sp)
    80004038:	1800                	addi	s0,sp,48
    8000403a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000403c:	4585                	li	a1,1
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	a62080e7          	jalr	-1438(ra) # 80003aa0 <bread>
    80004046:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004048:	00038997          	auipc	s3,0x38
    8000404c:	d9098993          	addi	s3,s3,-624 # 8003bdd8 <sb>
    80004050:	02000613          	li	a2,32
    80004054:	05850593          	addi	a1,a0,88
    80004058:	854e                	mv	a0,s3
    8000405a:	ffffd097          	auipc	ra,0xffffd
    8000405e:	ce4080e7          	jalr	-796(ra) # 80000d3e <memmove>
  brelse(bp);
    80004062:	8526                	mv	a0,s1
    80004064:	00000097          	auipc	ra,0x0
    80004068:	b6c080e7          	jalr	-1172(ra) # 80003bd0 <brelse>
  if(sb.magic != FSMAGIC)
    8000406c:	0009a703          	lw	a4,0(s3)
    80004070:	102037b7          	lui	a5,0x10203
    80004074:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004078:	02f71263          	bne	a4,a5,8000409c <fsinit+0x70>
  initlog(dev, &sb);
    8000407c:	00038597          	auipc	a1,0x38
    80004080:	d5c58593          	addi	a1,a1,-676 # 8003bdd8 <sb>
    80004084:	854a                	mv	a0,s2
    80004086:	00001097          	auipc	ra,0x1
    8000408a:	b4e080e7          	jalr	-1202(ra) # 80004bd4 <initlog>
}
    8000408e:	70a2                	ld	ra,40(sp)
    80004090:	7402                	ld	s0,32(sp)
    80004092:	64e2                	ld	s1,24(sp)
    80004094:	6942                	ld	s2,16(sp)
    80004096:	69a2                	ld	s3,8(sp)
    80004098:	6145                	addi	sp,sp,48
    8000409a:	8082                	ret
    panic("invalid file system");
    8000409c:	00004517          	auipc	a0,0x4
    800040a0:	50450513          	addi	a0,a0,1284 # 800085a0 <syscalls+0x178>
    800040a4:	ffffc097          	auipc	ra,0xffffc
    800040a8:	486080e7          	jalr	1158(ra) # 8000052a <panic>

00000000800040ac <iinit>:
{
    800040ac:	7179                	addi	sp,sp,-48
    800040ae:	f406                	sd	ra,40(sp)
    800040b0:	f022                	sd	s0,32(sp)
    800040b2:	ec26                	sd	s1,24(sp)
    800040b4:	e84a                	sd	s2,16(sp)
    800040b6:	e44e                	sd	s3,8(sp)
    800040b8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800040ba:	00004597          	auipc	a1,0x4
    800040be:	4fe58593          	addi	a1,a1,1278 # 800085b8 <syscalls+0x190>
    800040c2:	00038517          	auipc	a0,0x38
    800040c6:	d3650513          	addi	a0,a0,-714 # 8003bdf8 <itable>
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	a68080e7          	jalr	-1432(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800040d2:	00038497          	auipc	s1,0x38
    800040d6:	d4e48493          	addi	s1,s1,-690 # 8003be20 <itable+0x28>
    800040da:	00039997          	auipc	s3,0x39
    800040de:	7d698993          	addi	s3,s3,2006 # 8003d8b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800040e2:	00004917          	auipc	s2,0x4
    800040e6:	4de90913          	addi	s2,s2,1246 # 800085c0 <syscalls+0x198>
    800040ea:	85ca                	mv	a1,s2
    800040ec:	8526                	mv	a0,s1
    800040ee:	00001097          	auipc	ra,0x1
    800040f2:	e4a080e7          	jalr	-438(ra) # 80004f38 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800040f6:	08848493          	addi	s1,s1,136
    800040fa:	ff3498e3          	bne	s1,s3,800040ea <iinit+0x3e>
}
    800040fe:	70a2                	ld	ra,40(sp)
    80004100:	7402                	ld	s0,32(sp)
    80004102:	64e2                	ld	s1,24(sp)
    80004104:	6942                	ld	s2,16(sp)
    80004106:	69a2                	ld	s3,8(sp)
    80004108:	6145                	addi	sp,sp,48
    8000410a:	8082                	ret

000000008000410c <ialloc>:
{
    8000410c:	715d                	addi	sp,sp,-80
    8000410e:	e486                	sd	ra,72(sp)
    80004110:	e0a2                	sd	s0,64(sp)
    80004112:	fc26                	sd	s1,56(sp)
    80004114:	f84a                	sd	s2,48(sp)
    80004116:	f44e                	sd	s3,40(sp)
    80004118:	f052                	sd	s4,32(sp)
    8000411a:	ec56                	sd	s5,24(sp)
    8000411c:	e85a                	sd	s6,16(sp)
    8000411e:	e45e                	sd	s7,8(sp)
    80004120:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004122:	00038717          	auipc	a4,0x38
    80004126:	cc272703          	lw	a4,-830(a4) # 8003bde4 <sb+0xc>
    8000412a:	4785                	li	a5,1
    8000412c:	04e7fa63          	bgeu	a5,a4,80004180 <ialloc+0x74>
    80004130:	8aaa                	mv	s5,a0
    80004132:	8bae                	mv	s7,a1
    80004134:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004136:	00038a17          	auipc	s4,0x38
    8000413a:	ca2a0a13          	addi	s4,s4,-862 # 8003bdd8 <sb>
    8000413e:	00048b1b          	sext.w	s6,s1
    80004142:	0044d793          	srli	a5,s1,0x4
    80004146:	018a2583          	lw	a1,24(s4)
    8000414a:	9dbd                	addw	a1,a1,a5
    8000414c:	8556                	mv	a0,s5
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	952080e7          	jalr	-1710(ra) # 80003aa0 <bread>
    80004156:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004158:	05850993          	addi	s3,a0,88
    8000415c:	00f4f793          	andi	a5,s1,15
    80004160:	079a                	slli	a5,a5,0x6
    80004162:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004164:	00099783          	lh	a5,0(s3)
    80004168:	c785                	beqz	a5,80004190 <ialloc+0x84>
    brelse(bp);
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	a66080e7          	jalr	-1434(ra) # 80003bd0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004172:	0485                	addi	s1,s1,1
    80004174:	00ca2703          	lw	a4,12(s4)
    80004178:	0004879b          	sext.w	a5,s1
    8000417c:	fce7e1e3          	bltu	a5,a4,8000413e <ialloc+0x32>
  panic("ialloc: no inodes");
    80004180:	00004517          	auipc	a0,0x4
    80004184:	44850513          	addi	a0,a0,1096 # 800085c8 <syscalls+0x1a0>
    80004188:	ffffc097          	auipc	ra,0xffffc
    8000418c:	3a2080e7          	jalr	930(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80004190:	04000613          	li	a2,64
    80004194:	4581                	li	a1,0
    80004196:	854e                	mv	a0,s3
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	b4a080e7          	jalr	-1206(ra) # 80000ce2 <memset>
      dip->type = type;
    800041a0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800041a4:	854a                	mv	a0,s2
    800041a6:	00001097          	auipc	ra,0x1
    800041aa:	cac080e7          	jalr	-852(ra) # 80004e52 <log_write>
      brelse(bp);
    800041ae:	854a                	mv	a0,s2
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	a20080e7          	jalr	-1504(ra) # 80003bd0 <brelse>
      return iget(dev, inum);
    800041b8:	85da                	mv	a1,s6
    800041ba:	8556                	mv	a0,s5
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	db4080e7          	jalr	-588(ra) # 80003f70 <iget>
}
    800041c4:	60a6                	ld	ra,72(sp)
    800041c6:	6406                	ld	s0,64(sp)
    800041c8:	74e2                	ld	s1,56(sp)
    800041ca:	7942                	ld	s2,48(sp)
    800041cc:	79a2                	ld	s3,40(sp)
    800041ce:	7a02                	ld	s4,32(sp)
    800041d0:	6ae2                	ld	s5,24(sp)
    800041d2:	6b42                	ld	s6,16(sp)
    800041d4:	6ba2                	ld	s7,8(sp)
    800041d6:	6161                	addi	sp,sp,80
    800041d8:	8082                	ret

00000000800041da <iupdate>:
{
    800041da:	1101                	addi	sp,sp,-32
    800041dc:	ec06                	sd	ra,24(sp)
    800041de:	e822                	sd	s0,16(sp)
    800041e0:	e426                	sd	s1,8(sp)
    800041e2:	e04a                	sd	s2,0(sp)
    800041e4:	1000                	addi	s0,sp,32
    800041e6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041e8:	415c                	lw	a5,4(a0)
    800041ea:	0047d79b          	srliw	a5,a5,0x4
    800041ee:	00038597          	auipc	a1,0x38
    800041f2:	c025a583          	lw	a1,-1022(a1) # 8003bdf0 <sb+0x18>
    800041f6:	9dbd                	addw	a1,a1,a5
    800041f8:	4108                	lw	a0,0(a0)
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	8a6080e7          	jalr	-1882(ra) # 80003aa0 <bread>
    80004202:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004204:	05850793          	addi	a5,a0,88
    80004208:	40c8                	lw	a0,4(s1)
    8000420a:	893d                	andi	a0,a0,15
    8000420c:	051a                	slli	a0,a0,0x6
    8000420e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004210:	04449703          	lh	a4,68(s1)
    80004214:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004218:	04649703          	lh	a4,70(s1)
    8000421c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004220:	04849703          	lh	a4,72(s1)
    80004224:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004228:	04a49703          	lh	a4,74(s1)
    8000422c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004230:	44f8                	lw	a4,76(s1)
    80004232:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004234:	03400613          	li	a2,52
    80004238:	05048593          	addi	a1,s1,80
    8000423c:	0531                	addi	a0,a0,12
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	b00080e7          	jalr	-1280(ra) # 80000d3e <memmove>
  log_write(bp);
    80004246:	854a                	mv	a0,s2
    80004248:	00001097          	auipc	ra,0x1
    8000424c:	c0a080e7          	jalr	-1014(ra) # 80004e52 <log_write>
  brelse(bp);
    80004250:	854a                	mv	a0,s2
    80004252:	00000097          	auipc	ra,0x0
    80004256:	97e080e7          	jalr	-1666(ra) # 80003bd0 <brelse>
}
    8000425a:	60e2                	ld	ra,24(sp)
    8000425c:	6442                	ld	s0,16(sp)
    8000425e:	64a2                	ld	s1,8(sp)
    80004260:	6902                	ld	s2,0(sp)
    80004262:	6105                	addi	sp,sp,32
    80004264:	8082                	ret

0000000080004266 <idup>:
{
    80004266:	1101                	addi	sp,sp,-32
    80004268:	ec06                	sd	ra,24(sp)
    8000426a:	e822                	sd	s0,16(sp)
    8000426c:	e426                	sd	s1,8(sp)
    8000426e:	1000                	addi	s0,sp,32
    80004270:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004272:	00038517          	auipc	a0,0x38
    80004276:	b8650513          	addi	a0,a0,-1146 # 8003bdf8 <itable>
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	948080e7          	jalr	-1720(ra) # 80000bc2 <acquire>
  ip->ref++;
    80004282:	449c                	lw	a5,8(s1)
    80004284:	2785                	addiw	a5,a5,1
    80004286:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004288:	00038517          	auipc	a0,0x38
    8000428c:	b7050513          	addi	a0,a0,-1168 # 8003bdf8 <itable>
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	9f8080e7          	jalr	-1544(ra) # 80000c88 <release>
}
    80004298:	8526                	mv	a0,s1
    8000429a:	60e2                	ld	ra,24(sp)
    8000429c:	6442                	ld	s0,16(sp)
    8000429e:	64a2                	ld	s1,8(sp)
    800042a0:	6105                	addi	sp,sp,32
    800042a2:	8082                	ret

00000000800042a4 <ilock>:
{
    800042a4:	1101                	addi	sp,sp,-32
    800042a6:	ec06                	sd	ra,24(sp)
    800042a8:	e822                	sd	s0,16(sp)
    800042aa:	e426                	sd	s1,8(sp)
    800042ac:	e04a                	sd	s2,0(sp)
    800042ae:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800042b0:	c115                	beqz	a0,800042d4 <ilock+0x30>
    800042b2:	84aa                	mv	s1,a0
    800042b4:	451c                	lw	a5,8(a0)
    800042b6:	00f05f63          	blez	a5,800042d4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800042ba:	0541                	addi	a0,a0,16
    800042bc:	00001097          	auipc	ra,0x1
    800042c0:	cb6080e7          	jalr	-842(ra) # 80004f72 <acquiresleep>
  if(ip->valid == 0){
    800042c4:	40bc                	lw	a5,64(s1)
    800042c6:	cf99                	beqz	a5,800042e4 <ilock+0x40>
}
    800042c8:	60e2                	ld	ra,24(sp)
    800042ca:	6442                	ld	s0,16(sp)
    800042cc:	64a2                	ld	s1,8(sp)
    800042ce:	6902                	ld	s2,0(sp)
    800042d0:	6105                	addi	sp,sp,32
    800042d2:	8082                	ret
    panic("ilock");
    800042d4:	00004517          	auipc	a0,0x4
    800042d8:	30c50513          	addi	a0,a0,780 # 800085e0 <syscalls+0x1b8>
    800042dc:	ffffc097          	auipc	ra,0xffffc
    800042e0:	24e080e7          	jalr	590(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042e4:	40dc                	lw	a5,4(s1)
    800042e6:	0047d79b          	srliw	a5,a5,0x4
    800042ea:	00038597          	auipc	a1,0x38
    800042ee:	b065a583          	lw	a1,-1274(a1) # 8003bdf0 <sb+0x18>
    800042f2:	9dbd                	addw	a1,a1,a5
    800042f4:	4088                	lw	a0,0(s1)
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	7aa080e7          	jalr	1962(ra) # 80003aa0 <bread>
    800042fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004300:	05850593          	addi	a1,a0,88
    80004304:	40dc                	lw	a5,4(s1)
    80004306:	8bbd                	andi	a5,a5,15
    80004308:	079a                	slli	a5,a5,0x6
    8000430a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000430c:	00059783          	lh	a5,0(a1)
    80004310:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004314:	00259783          	lh	a5,2(a1)
    80004318:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000431c:	00459783          	lh	a5,4(a1)
    80004320:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004324:	00659783          	lh	a5,6(a1)
    80004328:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000432c:	459c                	lw	a5,8(a1)
    8000432e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004330:	03400613          	li	a2,52
    80004334:	05b1                	addi	a1,a1,12
    80004336:	05048513          	addi	a0,s1,80
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	a04080e7          	jalr	-1532(ra) # 80000d3e <memmove>
    brelse(bp);
    80004342:	854a                	mv	a0,s2
    80004344:	00000097          	auipc	ra,0x0
    80004348:	88c080e7          	jalr	-1908(ra) # 80003bd0 <brelse>
    ip->valid = 1;
    8000434c:	4785                	li	a5,1
    8000434e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004350:	04449783          	lh	a5,68(s1)
    80004354:	fbb5                	bnez	a5,800042c8 <ilock+0x24>
      panic("ilock: no type");
    80004356:	00004517          	auipc	a0,0x4
    8000435a:	29250513          	addi	a0,a0,658 # 800085e8 <syscalls+0x1c0>
    8000435e:	ffffc097          	auipc	ra,0xffffc
    80004362:	1cc080e7          	jalr	460(ra) # 8000052a <panic>

0000000080004366 <iunlock>:
{
    80004366:	1101                	addi	sp,sp,-32
    80004368:	ec06                	sd	ra,24(sp)
    8000436a:	e822                	sd	s0,16(sp)
    8000436c:	e426                	sd	s1,8(sp)
    8000436e:	e04a                	sd	s2,0(sp)
    80004370:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004372:	c905                	beqz	a0,800043a2 <iunlock+0x3c>
    80004374:	84aa                	mv	s1,a0
    80004376:	01050913          	addi	s2,a0,16
    8000437a:	854a                	mv	a0,s2
    8000437c:	00001097          	auipc	ra,0x1
    80004380:	c90080e7          	jalr	-880(ra) # 8000500c <holdingsleep>
    80004384:	cd19                	beqz	a0,800043a2 <iunlock+0x3c>
    80004386:	449c                	lw	a5,8(s1)
    80004388:	00f05d63          	blez	a5,800043a2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000438c:	854a                	mv	a0,s2
    8000438e:	00001097          	auipc	ra,0x1
    80004392:	c3a080e7          	jalr	-966(ra) # 80004fc8 <releasesleep>
}
    80004396:	60e2                	ld	ra,24(sp)
    80004398:	6442                	ld	s0,16(sp)
    8000439a:	64a2                	ld	s1,8(sp)
    8000439c:	6902                	ld	s2,0(sp)
    8000439e:	6105                	addi	sp,sp,32
    800043a0:	8082                	ret
    panic("iunlock");
    800043a2:	00004517          	auipc	a0,0x4
    800043a6:	25650513          	addi	a0,a0,598 # 800085f8 <syscalls+0x1d0>
    800043aa:	ffffc097          	auipc	ra,0xffffc
    800043ae:	180080e7          	jalr	384(ra) # 8000052a <panic>

00000000800043b2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800043b2:	7179                	addi	sp,sp,-48
    800043b4:	f406                	sd	ra,40(sp)
    800043b6:	f022                	sd	s0,32(sp)
    800043b8:	ec26                	sd	s1,24(sp)
    800043ba:	e84a                	sd	s2,16(sp)
    800043bc:	e44e                	sd	s3,8(sp)
    800043be:	e052                	sd	s4,0(sp)
    800043c0:	1800                	addi	s0,sp,48
    800043c2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800043c4:	05050493          	addi	s1,a0,80
    800043c8:	08050913          	addi	s2,a0,128
    800043cc:	a021                	j	800043d4 <itrunc+0x22>
    800043ce:	0491                	addi	s1,s1,4
    800043d0:	01248d63          	beq	s1,s2,800043ea <itrunc+0x38>
    if(ip->addrs[i]){
    800043d4:	408c                	lw	a1,0(s1)
    800043d6:	dde5                	beqz	a1,800043ce <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800043d8:	0009a503          	lw	a0,0(s3)
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	90a080e7          	jalr	-1782(ra) # 80003ce6 <bfree>
      ip->addrs[i] = 0;
    800043e4:	0004a023          	sw	zero,0(s1)
    800043e8:	b7dd                	j	800043ce <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800043ea:	0809a583          	lw	a1,128(s3)
    800043ee:	e185                	bnez	a1,8000440e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800043f0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800043f4:	854e                	mv	a0,s3
    800043f6:	00000097          	auipc	ra,0x0
    800043fa:	de4080e7          	jalr	-540(ra) # 800041da <iupdate>
}
    800043fe:	70a2                	ld	ra,40(sp)
    80004400:	7402                	ld	s0,32(sp)
    80004402:	64e2                	ld	s1,24(sp)
    80004404:	6942                	ld	s2,16(sp)
    80004406:	69a2                	ld	s3,8(sp)
    80004408:	6a02                	ld	s4,0(sp)
    8000440a:	6145                	addi	sp,sp,48
    8000440c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000440e:	0009a503          	lw	a0,0(s3)
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	68e080e7          	jalr	1678(ra) # 80003aa0 <bread>
    8000441a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000441c:	05850493          	addi	s1,a0,88
    80004420:	45850913          	addi	s2,a0,1112
    80004424:	a021                	j	8000442c <itrunc+0x7a>
    80004426:	0491                	addi	s1,s1,4
    80004428:	01248b63          	beq	s1,s2,8000443e <itrunc+0x8c>
      if(a[j])
    8000442c:	408c                	lw	a1,0(s1)
    8000442e:	dde5                	beqz	a1,80004426 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004430:	0009a503          	lw	a0,0(s3)
    80004434:	00000097          	auipc	ra,0x0
    80004438:	8b2080e7          	jalr	-1870(ra) # 80003ce6 <bfree>
    8000443c:	b7ed                	j	80004426 <itrunc+0x74>
    brelse(bp);
    8000443e:	8552                	mv	a0,s4
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	790080e7          	jalr	1936(ra) # 80003bd0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004448:	0809a583          	lw	a1,128(s3)
    8000444c:	0009a503          	lw	a0,0(s3)
    80004450:	00000097          	auipc	ra,0x0
    80004454:	896080e7          	jalr	-1898(ra) # 80003ce6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004458:	0809a023          	sw	zero,128(s3)
    8000445c:	bf51                	j	800043f0 <itrunc+0x3e>

000000008000445e <iput>:
{
    8000445e:	1101                	addi	sp,sp,-32
    80004460:	ec06                	sd	ra,24(sp)
    80004462:	e822                	sd	s0,16(sp)
    80004464:	e426                	sd	s1,8(sp)
    80004466:	e04a                	sd	s2,0(sp)
    80004468:	1000                	addi	s0,sp,32
    8000446a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000446c:	00038517          	auipc	a0,0x38
    80004470:	98c50513          	addi	a0,a0,-1652 # 8003bdf8 <itable>
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	74e080e7          	jalr	1870(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000447c:	4498                	lw	a4,8(s1)
    8000447e:	4785                	li	a5,1
    80004480:	02f70363          	beq	a4,a5,800044a6 <iput+0x48>
  ip->ref--;
    80004484:	449c                	lw	a5,8(s1)
    80004486:	37fd                	addiw	a5,a5,-1
    80004488:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000448a:	00038517          	auipc	a0,0x38
    8000448e:	96e50513          	addi	a0,a0,-1682 # 8003bdf8 <itable>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	7f6080e7          	jalr	2038(ra) # 80000c88 <release>
}
    8000449a:	60e2                	ld	ra,24(sp)
    8000449c:	6442                	ld	s0,16(sp)
    8000449e:	64a2                	ld	s1,8(sp)
    800044a0:	6902                	ld	s2,0(sp)
    800044a2:	6105                	addi	sp,sp,32
    800044a4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044a6:	40bc                	lw	a5,64(s1)
    800044a8:	dff1                	beqz	a5,80004484 <iput+0x26>
    800044aa:	04a49783          	lh	a5,74(s1)
    800044ae:	fbf9                	bnez	a5,80004484 <iput+0x26>
    acquiresleep(&ip->lock);
    800044b0:	01048913          	addi	s2,s1,16
    800044b4:	854a                	mv	a0,s2
    800044b6:	00001097          	auipc	ra,0x1
    800044ba:	abc080e7          	jalr	-1348(ra) # 80004f72 <acquiresleep>
    release(&itable.lock);
    800044be:	00038517          	auipc	a0,0x38
    800044c2:	93a50513          	addi	a0,a0,-1734 # 8003bdf8 <itable>
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	7c2080e7          	jalr	1986(ra) # 80000c88 <release>
    itrunc(ip);
    800044ce:	8526                	mv	a0,s1
    800044d0:	00000097          	auipc	ra,0x0
    800044d4:	ee2080e7          	jalr	-286(ra) # 800043b2 <itrunc>
    ip->type = 0;
    800044d8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800044dc:	8526                	mv	a0,s1
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	cfc080e7          	jalr	-772(ra) # 800041da <iupdate>
    ip->valid = 0;
    800044e6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800044ea:	854a                	mv	a0,s2
    800044ec:	00001097          	auipc	ra,0x1
    800044f0:	adc080e7          	jalr	-1316(ra) # 80004fc8 <releasesleep>
    acquire(&itable.lock);
    800044f4:	00038517          	auipc	a0,0x38
    800044f8:	90450513          	addi	a0,a0,-1788 # 8003bdf8 <itable>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	6c6080e7          	jalr	1734(ra) # 80000bc2 <acquire>
    80004504:	b741                	j	80004484 <iput+0x26>

0000000080004506 <iunlockput>:
{
    80004506:	1101                	addi	sp,sp,-32
    80004508:	ec06                	sd	ra,24(sp)
    8000450a:	e822                	sd	s0,16(sp)
    8000450c:	e426                	sd	s1,8(sp)
    8000450e:	1000                	addi	s0,sp,32
    80004510:	84aa                	mv	s1,a0
  iunlock(ip);
    80004512:	00000097          	auipc	ra,0x0
    80004516:	e54080e7          	jalr	-428(ra) # 80004366 <iunlock>
  iput(ip);
    8000451a:	8526                	mv	a0,s1
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	f42080e7          	jalr	-190(ra) # 8000445e <iput>
}
    80004524:	60e2                	ld	ra,24(sp)
    80004526:	6442                	ld	s0,16(sp)
    80004528:	64a2                	ld	s1,8(sp)
    8000452a:	6105                	addi	sp,sp,32
    8000452c:	8082                	ret

000000008000452e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000452e:	1141                	addi	sp,sp,-16
    80004530:	e422                	sd	s0,8(sp)
    80004532:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004534:	411c                	lw	a5,0(a0)
    80004536:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004538:	415c                	lw	a5,4(a0)
    8000453a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000453c:	04451783          	lh	a5,68(a0)
    80004540:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004544:	04a51783          	lh	a5,74(a0)
    80004548:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000454c:	04c56783          	lwu	a5,76(a0)
    80004550:	e99c                	sd	a5,16(a1)
}
    80004552:	6422                	ld	s0,8(sp)
    80004554:	0141                	addi	sp,sp,16
    80004556:	8082                	ret

0000000080004558 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004558:	457c                	lw	a5,76(a0)
    8000455a:	0ed7e963          	bltu	a5,a3,8000464c <readi+0xf4>
{
    8000455e:	7159                	addi	sp,sp,-112
    80004560:	f486                	sd	ra,104(sp)
    80004562:	f0a2                	sd	s0,96(sp)
    80004564:	eca6                	sd	s1,88(sp)
    80004566:	e8ca                	sd	s2,80(sp)
    80004568:	e4ce                	sd	s3,72(sp)
    8000456a:	e0d2                	sd	s4,64(sp)
    8000456c:	fc56                	sd	s5,56(sp)
    8000456e:	f85a                	sd	s6,48(sp)
    80004570:	f45e                	sd	s7,40(sp)
    80004572:	f062                	sd	s8,32(sp)
    80004574:	ec66                	sd	s9,24(sp)
    80004576:	e86a                	sd	s10,16(sp)
    80004578:	e46e                	sd	s11,8(sp)
    8000457a:	1880                	addi	s0,sp,112
    8000457c:	8baa                	mv	s7,a0
    8000457e:	8c2e                	mv	s8,a1
    80004580:	8ab2                	mv	s5,a2
    80004582:	84b6                	mv	s1,a3
    80004584:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004586:	9f35                	addw	a4,a4,a3
    return 0;
    80004588:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000458a:	0ad76063          	bltu	a4,a3,8000462a <readi+0xd2>
  if(off + n > ip->size)
    8000458e:	00e7f463          	bgeu	a5,a4,80004596 <readi+0x3e>
    n = ip->size - off;
    80004592:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004596:	0a0b0963          	beqz	s6,80004648 <readi+0xf0>
    8000459a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000459c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800045a0:	5cfd                	li	s9,-1
    800045a2:	a82d                	j	800045dc <readi+0x84>
    800045a4:	020a1d93          	slli	s11,s4,0x20
    800045a8:	020ddd93          	srli	s11,s11,0x20
    800045ac:	05890793          	addi	a5,s2,88
    800045b0:	86ee                	mv	a3,s11
    800045b2:	963e                	add	a2,a2,a5
    800045b4:	85d6                	mv	a1,s5
    800045b6:	8562                	mv	a0,s8
    800045b8:	ffffe097          	auipc	ra,0xffffe
    800045bc:	2a0080e7          	jalr	672(ra) # 80002858 <either_copyout>
    800045c0:	05950d63          	beq	a0,s9,8000461a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800045c4:	854a                	mv	a0,s2
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	60a080e7          	jalr	1546(ra) # 80003bd0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045ce:	013a09bb          	addw	s3,s4,s3
    800045d2:	009a04bb          	addw	s1,s4,s1
    800045d6:	9aee                	add	s5,s5,s11
    800045d8:	0569f763          	bgeu	s3,s6,80004626 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800045dc:	000ba903          	lw	s2,0(s7)
    800045e0:	00a4d59b          	srliw	a1,s1,0xa
    800045e4:	855e                	mv	a0,s7
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	8ae080e7          	jalr	-1874(ra) # 80003e94 <bmap>
    800045ee:	0005059b          	sext.w	a1,a0
    800045f2:	854a                	mv	a0,s2
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	4ac080e7          	jalr	1196(ra) # 80003aa0 <bread>
    800045fc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800045fe:	3ff4f613          	andi	a2,s1,1023
    80004602:	40cd07bb          	subw	a5,s10,a2
    80004606:	413b073b          	subw	a4,s6,s3
    8000460a:	8a3e                	mv	s4,a5
    8000460c:	2781                	sext.w	a5,a5
    8000460e:	0007069b          	sext.w	a3,a4
    80004612:	f8f6f9e3          	bgeu	a3,a5,800045a4 <readi+0x4c>
    80004616:	8a3a                	mv	s4,a4
    80004618:	b771                	j	800045a4 <readi+0x4c>
      brelse(bp);
    8000461a:	854a                	mv	a0,s2
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	5b4080e7          	jalr	1460(ra) # 80003bd0 <brelse>
      tot = -1;
    80004624:	59fd                	li	s3,-1
  }
  return tot;
    80004626:	0009851b          	sext.w	a0,s3
}
    8000462a:	70a6                	ld	ra,104(sp)
    8000462c:	7406                	ld	s0,96(sp)
    8000462e:	64e6                	ld	s1,88(sp)
    80004630:	6946                	ld	s2,80(sp)
    80004632:	69a6                	ld	s3,72(sp)
    80004634:	6a06                	ld	s4,64(sp)
    80004636:	7ae2                	ld	s5,56(sp)
    80004638:	7b42                	ld	s6,48(sp)
    8000463a:	7ba2                	ld	s7,40(sp)
    8000463c:	7c02                	ld	s8,32(sp)
    8000463e:	6ce2                	ld	s9,24(sp)
    80004640:	6d42                	ld	s10,16(sp)
    80004642:	6da2                	ld	s11,8(sp)
    80004644:	6165                	addi	sp,sp,112
    80004646:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004648:	89da                	mv	s3,s6
    8000464a:	bff1                	j	80004626 <readi+0xce>
    return 0;
    8000464c:	4501                	li	a0,0
}
    8000464e:	8082                	ret

0000000080004650 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004650:	457c                	lw	a5,76(a0)
    80004652:	10d7e863          	bltu	a5,a3,80004762 <writei+0x112>
{
    80004656:	7159                	addi	sp,sp,-112
    80004658:	f486                	sd	ra,104(sp)
    8000465a:	f0a2                	sd	s0,96(sp)
    8000465c:	eca6                	sd	s1,88(sp)
    8000465e:	e8ca                	sd	s2,80(sp)
    80004660:	e4ce                	sd	s3,72(sp)
    80004662:	e0d2                	sd	s4,64(sp)
    80004664:	fc56                	sd	s5,56(sp)
    80004666:	f85a                	sd	s6,48(sp)
    80004668:	f45e                	sd	s7,40(sp)
    8000466a:	f062                	sd	s8,32(sp)
    8000466c:	ec66                	sd	s9,24(sp)
    8000466e:	e86a                	sd	s10,16(sp)
    80004670:	e46e                	sd	s11,8(sp)
    80004672:	1880                	addi	s0,sp,112
    80004674:	8b2a                	mv	s6,a0
    80004676:	8c2e                	mv	s8,a1
    80004678:	8ab2                	mv	s5,a2
    8000467a:	8936                	mv	s2,a3
    8000467c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000467e:	00e687bb          	addw	a5,a3,a4
    80004682:	0ed7e263          	bltu	a5,a3,80004766 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004686:	00043737          	lui	a4,0x43
    8000468a:	0ef76063          	bltu	a4,a5,8000476a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000468e:	0c0b8863          	beqz	s7,8000475e <writei+0x10e>
    80004692:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004694:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004698:	5cfd                	li	s9,-1
    8000469a:	a091                	j	800046de <writei+0x8e>
    8000469c:	02099d93          	slli	s11,s3,0x20
    800046a0:	020ddd93          	srli	s11,s11,0x20
    800046a4:	05848793          	addi	a5,s1,88
    800046a8:	86ee                	mv	a3,s11
    800046aa:	8656                	mv	a2,s5
    800046ac:	85e2                	mv	a1,s8
    800046ae:	953e                	add	a0,a0,a5
    800046b0:	ffffe097          	auipc	ra,0xffffe
    800046b4:	200080e7          	jalr	512(ra) # 800028b0 <either_copyin>
    800046b8:	07950263          	beq	a0,s9,8000471c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800046bc:	8526                	mv	a0,s1
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	794080e7          	jalr	1940(ra) # 80004e52 <log_write>
    brelse(bp);
    800046c6:	8526                	mv	a0,s1
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	508080e7          	jalr	1288(ra) # 80003bd0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046d0:	01498a3b          	addw	s4,s3,s4
    800046d4:	0129893b          	addw	s2,s3,s2
    800046d8:	9aee                	add	s5,s5,s11
    800046da:	057a7663          	bgeu	s4,s7,80004726 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800046de:	000b2483          	lw	s1,0(s6)
    800046e2:	00a9559b          	srliw	a1,s2,0xa
    800046e6:	855a                	mv	a0,s6
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	7ac080e7          	jalr	1964(ra) # 80003e94 <bmap>
    800046f0:	0005059b          	sext.w	a1,a0
    800046f4:	8526                	mv	a0,s1
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	3aa080e7          	jalr	938(ra) # 80003aa0 <bread>
    800046fe:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004700:	3ff97513          	andi	a0,s2,1023
    80004704:	40ad07bb          	subw	a5,s10,a0
    80004708:	414b873b          	subw	a4,s7,s4
    8000470c:	89be                	mv	s3,a5
    8000470e:	2781                	sext.w	a5,a5
    80004710:	0007069b          	sext.w	a3,a4
    80004714:	f8f6f4e3          	bgeu	a3,a5,8000469c <writei+0x4c>
    80004718:	89ba                	mv	s3,a4
    8000471a:	b749                	j	8000469c <writei+0x4c>
      brelse(bp);
    8000471c:	8526                	mv	a0,s1
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	4b2080e7          	jalr	1202(ra) # 80003bd0 <brelse>
  }

  if(off > ip->size)
    80004726:	04cb2783          	lw	a5,76(s6)
    8000472a:	0127f463          	bgeu	a5,s2,80004732 <writei+0xe2>
    ip->size = off;
    8000472e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004732:	855a                	mv	a0,s6
    80004734:	00000097          	auipc	ra,0x0
    80004738:	aa6080e7          	jalr	-1370(ra) # 800041da <iupdate>

  return tot;
    8000473c:	000a051b          	sext.w	a0,s4
}
    80004740:	70a6                	ld	ra,104(sp)
    80004742:	7406                	ld	s0,96(sp)
    80004744:	64e6                	ld	s1,88(sp)
    80004746:	6946                	ld	s2,80(sp)
    80004748:	69a6                	ld	s3,72(sp)
    8000474a:	6a06                	ld	s4,64(sp)
    8000474c:	7ae2                	ld	s5,56(sp)
    8000474e:	7b42                	ld	s6,48(sp)
    80004750:	7ba2                	ld	s7,40(sp)
    80004752:	7c02                	ld	s8,32(sp)
    80004754:	6ce2                	ld	s9,24(sp)
    80004756:	6d42                	ld	s10,16(sp)
    80004758:	6da2                	ld	s11,8(sp)
    8000475a:	6165                	addi	sp,sp,112
    8000475c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000475e:	8a5e                	mv	s4,s7
    80004760:	bfc9                	j	80004732 <writei+0xe2>
    return -1;
    80004762:	557d                	li	a0,-1
}
    80004764:	8082                	ret
    return -1;
    80004766:	557d                	li	a0,-1
    80004768:	bfe1                	j	80004740 <writei+0xf0>
    return -1;
    8000476a:	557d                	li	a0,-1
    8000476c:	bfd1                	j	80004740 <writei+0xf0>

000000008000476e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000476e:	1141                	addi	sp,sp,-16
    80004770:	e406                	sd	ra,8(sp)
    80004772:	e022                	sd	s0,0(sp)
    80004774:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004776:	4639                	li	a2,14
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	642080e7          	jalr	1602(ra) # 80000dba <strncmp>
}
    80004780:	60a2                	ld	ra,8(sp)
    80004782:	6402                	ld	s0,0(sp)
    80004784:	0141                	addi	sp,sp,16
    80004786:	8082                	ret

0000000080004788 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004788:	7139                	addi	sp,sp,-64
    8000478a:	fc06                	sd	ra,56(sp)
    8000478c:	f822                	sd	s0,48(sp)
    8000478e:	f426                	sd	s1,40(sp)
    80004790:	f04a                	sd	s2,32(sp)
    80004792:	ec4e                	sd	s3,24(sp)
    80004794:	e852                	sd	s4,16(sp)
    80004796:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004798:	04451703          	lh	a4,68(a0)
    8000479c:	4785                	li	a5,1
    8000479e:	00f71a63          	bne	a4,a5,800047b2 <dirlookup+0x2a>
    800047a2:	892a                	mv	s2,a0
    800047a4:	89ae                	mv	s3,a1
    800047a6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800047a8:	457c                	lw	a5,76(a0)
    800047aa:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800047ac:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047ae:	e79d                	bnez	a5,800047dc <dirlookup+0x54>
    800047b0:	a8a5                	j	80004828 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800047b2:	00004517          	auipc	a0,0x4
    800047b6:	e4e50513          	addi	a0,a0,-434 # 80008600 <syscalls+0x1d8>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	d70080e7          	jalr	-656(ra) # 8000052a <panic>
      panic("dirlookup read");
    800047c2:	00004517          	auipc	a0,0x4
    800047c6:	e5650513          	addi	a0,a0,-426 # 80008618 <syscalls+0x1f0>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	d60080e7          	jalr	-672(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047d2:	24c1                	addiw	s1,s1,16
    800047d4:	04c92783          	lw	a5,76(s2)
    800047d8:	04f4f763          	bgeu	s1,a5,80004826 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047dc:	4741                	li	a4,16
    800047de:	86a6                	mv	a3,s1
    800047e0:	fc040613          	addi	a2,s0,-64
    800047e4:	4581                	li	a1,0
    800047e6:	854a                	mv	a0,s2
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	d70080e7          	jalr	-656(ra) # 80004558 <readi>
    800047f0:	47c1                	li	a5,16
    800047f2:	fcf518e3          	bne	a0,a5,800047c2 <dirlookup+0x3a>
    if(de.inum == 0)
    800047f6:	fc045783          	lhu	a5,-64(s0)
    800047fa:	dfe1                	beqz	a5,800047d2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800047fc:	fc240593          	addi	a1,s0,-62
    80004800:	854e                	mv	a0,s3
    80004802:	00000097          	auipc	ra,0x0
    80004806:	f6c080e7          	jalr	-148(ra) # 8000476e <namecmp>
    8000480a:	f561                	bnez	a0,800047d2 <dirlookup+0x4a>
      if(poff)
    8000480c:	000a0463          	beqz	s4,80004814 <dirlookup+0x8c>
        *poff = off;
    80004810:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004814:	fc045583          	lhu	a1,-64(s0)
    80004818:	00092503          	lw	a0,0(s2)
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	754080e7          	jalr	1876(ra) # 80003f70 <iget>
    80004824:	a011                	j	80004828 <dirlookup+0xa0>
  return 0;
    80004826:	4501                	li	a0,0
}
    80004828:	70e2                	ld	ra,56(sp)
    8000482a:	7442                	ld	s0,48(sp)
    8000482c:	74a2                	ld	s1,40(sp)
    8000482e:	7902                	ld	s2,32(sp)
    80004830:	69e2                	ld	s3,24(sp)
    80004832:	6a42                	ld	s4,16(sp)
    80004834:	6121                	addi	sp,sp,64
    80004836:	8082                	ret

0000000080004838 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004838:	711d                	addi	sp,sp,-96
    8000483a:	ec86                	sd	ra,88(sp)
    8000483c:	e8a2                	sd	s0,80(sp)
    8000483e:	e4a6                	sd	s1,72(sp)
    80004840:	e0ca                	sd	s2,64(sp)
    80004842:	fc4e                	sd	s3,56(sp)
    80004844:	f852                	sd	s4,48(sp)
    80004846:	f456                	sd	s5,40(sp)
    80004848:	f05a                	sd	s6,32(sp)
    8000484a:	ec5e                	sd	s7,24(sp)
    8000484c:	e862                	sd	s8,16(sp)
    8000484e:	e466                	sd	s9,8(sp)
    80004850:	1080                	addi	s0,sp,96
    80004852:	84aa                	mv	s1,a0
    80004854:	8aae                	mv	s5,a1
    80004856:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004858:	00054703          	lbu	a4,0(a0)
    8000485c:	02f00793          	li	a5,47
    80004860:	02f70363          	beq	a4,a5,80004886 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004864:	ffffd097          	auipc	ra,0xffffd
    80004868:	19e080e7          	jalr	414(ra) # 80001a02 <myproc>
    8000486c:	26053503          	ld	a0,608(a0)
    80004870:	00000097          	auipc	ra,0x0
    80004874:	9f6080e7          	jalr	-1546(ra) # 80004266 <idup>
    80004878:	89aa                	mv	s3,a0
  while(*path == '/')
    8000487a:	02f00913          	li	s2,47
  len = path - s;
    8000487e:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004880:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004882:	4b85                	li	s7,1
    80004884:	a865                	j	8000493c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004886:	4585                	li	a1,1
    80004888:	4505                	li	a0,1
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	6e6080e7          	jalr	1766(ra) # 80003f70 <iget>
    80004892:	89aa                	mv	s3,a0
    80004894:	b7dd                	j	8000487a <namex+0x42>
      iunlockput(ip);
    80004896:	854e                	mv	a0,s3
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	c6e080e7          	jalr	-914(ra) # 80004506 <iunlockput>
      return 0;
    800048a0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800048a2:	854e                	mv	a0,s3
    800048a4:	60e6                	ld	ra,88(sp)
    800048a6:	6446                	ld	s0,80(sp)
    800048a8:	64a6                	ld	s1,72(sp)
    800048aa:	6906                	ld	s2,64(sp)
    800048ac:	79e2                	ld	s3,56(sp)
    800048ae:	7a42                	ld	s4,48(sp)
    800048b0:	7aa2                	ld	s5,40(sp)
    800048b2:	7b02                	ld	s6,32(sp)
    800048b4:	6be2                	ld	s7,24(sp)
    800048b6:	6c42                	ld	s8,16(sp)
    800048b8:	6ca2                	ld	s9,8(sp)
    800048ba:	6125                	addi	sp,sp,96
    800048bc:	8082                	ret
      iunlock(ip);
    800048be:	854e                	mv	a0,s3
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	aa6080e7          	jalr	-1370(ra) # 80004366 <iunlock>
      return ip;
    800048c8:	bfe9                	j	800048a2 <namex+0x6a>
      iunlockput(ip);
    800048ca:	854e                	mv	a0,s3
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	c3a080e7          	jalr	-966(ra) # 80004506 <iunlockput>
      return 0;
    800048d4:	89e6                	mv	s3,s9
    800048d6:	b7f1                	j	800048a2 <namex+0x6a>
  len = path - s;
    800048d8:	40b48633          	sub	a2,s1,a1
    800048dc:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800048e0:	099c5463          	bge	s8,s9,80004968 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800048e4:	4639                	li	a2,14
    800048e6:	8552                	mv	a0,s4
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	456080e7          	jalr	1110(ra) # 80000d3e <memmove>
  while(*path == '/')
    800048f0:	0004c783          	lbu	a5,0(s1)
    800048f4:	01279763          	bne	a5,s2,80004902 <namex+0xca>
    path++;
    800048f8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800048fa:	0004c783          	lbu	a5,0(s1)
    800048fe:	ff278de3          	beq	a5,s2,800048f8 <namex+0xc0>
    ilock(ip);
    80004902:	854e                	mv	a0,s3
    80004904:	00000097          	auipc	ra,0x0
    80004908:	9a0080e7          	jalr	-1632(ra) # 800042a4 <ilock>
    if(ip->type != T_DIR){
    8000490c:	04499783          	lh	a5,68(s3)
    80004910:	f97793e3          	bne	a5,s7,80004896 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004914:	000a8563          	beqz	s5,8000491e <namex+0xe6>
    80004918:	0004c783          	lbu	a5,0(s1)
    8000491c:	d3cd                	beqz	a5,800048be <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000491e:	865a                	mv	a2,s6
    80004920:	85d2                	mv	a1,s4
    80004922:	854e                	mv	a0,s3
    80004924:	00000097          	auipc	ra,0x0
    80004928:	e64080e7          	jalr	-412(ra) # 80004788 <dirlookup>
    8000492c:	8caa                	mv	s9,a0
    8000492e:	dd51                	beqz	a0,800048ca <namex+0x92>
    iunlockput(ip);
    80004930:	854e                	mv	a0,s3
    80004932:	00000097          	auipc	ra,0x0
    80004936:	bd4080e7          	jalr	-1068(ra) # 80004506 <iunlockput>
    ip = next;
    8000493a:	89e6                	mv	s3,s9
  while(*path == '/')
    8000493c:	0004c783          	lbu	a5,0(s1)
    80004940:	05279763          	bne	a5,s2,8000498e <namex+0x156>
    path++;
    80004944:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004946:	0004c783          	lbu	a5,0(s1)
    8000494a:	ff278de3          	beq	a5,s2,80004944 <namex+0x10c>
  if(*path == 0)
    8000494e:	c79d                	beqz	a5,8000497c <namex+0x144>
    path++;
    80004950:	85a6                	mv	a1,s1
  len = path - s;
    80004952:	8cda                	mv	s9,s6
    80004954:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004956:	01278963          	beq	a5,s2,80004968 <namex+0x130>
    8000495a:	dfbd                	beqz	a5,800048d8 <namex+0xa0>
    path++;
    8000495c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000495e:	0004c783          	lbu	a5,0(s1)
    80004962:	ff279ce3          	bne	a5,s2,8000495a <namex+0x122>
    80004966:	bf8d                	j	800048d8 <namex+0xa0>
    memmove(name, s, len);
    80004968:	2601                	sext.w	a2,a2
    8000496a:	8552                	mv	a0,s4
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	3d2080e7          	jalr	978(ra) # 80000d3e <memmove>
    name[len] = 0;
    80004974:	9cd2                	add	s9,s9,s4
    80004976:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000497a:	bf9d                	j	800048f0 <namex+0xb8>
  if(nameiparent){
    8000497c:	f20a83e3          	beqz	s5,800048a2 <namex+0x6a>
    iput(ip);
    80004980:	854e                	mv	a0,s3
    80004982:	00000097          	auipc	ra,0x0
    80004986:	adc080e7          	jalr	-1316(ra) # 8000445e <iput>
    return 0;
    8000498a:	4981                	li	s3,0
    8000498c:	bf19                	j	800048a2 <namex+0x6a>
  if(*path == 0)
    8000498e:	d7fd                	beqz	a5,8000497c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004990:	0004c783          	lbu	a5,0(s1)
    80004994:	85a6                	mv	a1,s1
    80004996:	b7d1                	j	8000495a <namex+0x122>

0000000080004998 <dirlink>:
{
    80004998:	7139                	addi	sp,sp,-64
    8000499a:	fc06                	sd	ra,56(sp)
    8000499c:	f822                	sd	s0,48(sp)
    8000499e:	f426                	sd	s1,40(sp)
    800049a0:	f04a                	sd	s2,32(sp)
    800049a2:	ec4e                	sd	s3,24(sp)
    800049a4:	e852                	sd	s4,16(sp)
    800049a6:	0080                	addi	s0,sp,64
    800049a8:	892a                	mv	s2,a0
    800049aa:	8a2e                	mv	s4,a1
    800049ac:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800049ae:	4601                	li	a2,0
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	dd8080e7          	jalr	-552(ra) # 80004788 <dirlookup>
    800049b8:	e93d                	bnez	a0,80004a2e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049ba:	04c92483          	lw	s1,76(s2)
    800049be:	c49d                	beqz	s1,800049ec <dirlink+0x54>
    800049c0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049c2:	4741                	li	a4,16
    800049c4:	86a6                	mv	a3,s1
    800049c6:	fc040613          	addi	a2,s0,-64
    800049ca:	4581                	li	a1,0
    800049cc:	854a                	mv	a0,s2
    800049ce:	00000097          	auipc	ra,0x0
    800049d2:	b8a080e7          	jalr	-1142(ra) # 80004558 <readi>
    800049d6:	47c1                	li	a5,16
    800049d8:	06f51163          	bne	a0,a5,80004a3a <dirlink+0xa2>
    if(de.inum == 0)
    800049dc:	fc045783          	lhu	a5,-64(s0)
    800049e0:	c791                	beqz	a5,800049ec <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049e2:	24c1                	addiw	s1,s1,16
    800049e4:	04c92783          	lw	a5,76(s2)
    800049e8:	fcf4ede3          	bltu	s1,a5,800049c2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800049ec:	4639                	li	a2,14
    800049ee:	85d2                	mv	a1,s4
    800049f0:	fc240513          	addi	a0,s0,-62
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	402080e7          	jalr	1026(ra) # 80000df6 <strncpy>
  de.inum = inum;
    800049fc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a00:	4741                	li	a4,16
    80004a02:	86a6                	mv	a3,s1
    80004a04:	fc040613          	addi	a2,s0,-64
    80004a08:	4581                	li	a1,0
    80004a0a:	854a                	mv	a0,s2
    80004a0c:	00000097          	auipc	ra,0x0
    80004a10:	c44080e7          	jalr	-956(ra) # 80004650 <writei>
    80004a14:	872a                	mv	a4,a0
    80004a16:	47c1                	li	a5,16
  return 0;
    80004a18:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a1a:	02f71863          	bne	a4,a5,80004a4a <dirlink+0xb2>
}
    80004a1e:	70e2                	ld	ra,56(sp)
    80004a20:	7442                	ld	s0,48(sp)
    80004a22:	74a2                	ld	s1,40(sp)
    80004a24:	7902                	ld	s2,32(sp)
    80004a26:	69e2                	ld	s3,24(sp)
    80004a28:	6a42                	ld	s4,16(sp)
    80004a2a:	6121                	addi	sp,sp,64
    80004a2c:	8082                	ret
    iput(ip);
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	a30080e7          	jalr	-1488(ra) # 8000445e <iput>
    return -1;
    80004a36:	557d                	li	a0,-1
    80004a38:	b7dd                	j	80004a1e <dirlink+0x86>
      panic("dirlink read");
    80004a3a:	00004517          	auipc	a0,0x4
    80004a3e:	bee50513          	addi	a0,a0,-1042 # 80008628 <syscalls+0x200>
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	ae8080e7          	jalr	-1304(ra) # 8000052a <panic>
    panic("dirlink");
    80004a4a:	00004517          	auipc	a0,0x4
    80004a4e:	cee50513          	addi	a0,a0,-786 # 80008738 <syscalls+0x310>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	ad8080e7          	jalr	-1320(ra) # 8000052a <panic>

0000000080004a5a <namei>:

struct inode*
namei(char *path)
{
    80004a5a:	1101                	addi	sp,sp,-32
    80004a5c:	ec06                	sd	ra,24(sp)
    80004a5e:	e822                	sd	s0,16(sp)
    80004a60:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a62:	fe040613          	addi	a2,s0,-32
    80004a66:	4581                	li	a1,0
    80004a68:	00000097          	auipc	ra,0x0
    80004a6c:	dd0080e7          	jalr	-560(ra) # 80004838 <namex>
}
    80004a70:	60e2                	ld	ra,24(sp)
    80004a72:	6442                	ld	s0,16(sp)
    80004a74:	6105                	addi	sp,sp,32
    80004a76:	8082                	ret

0000000080004a78 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a78:	1141                	addi	sp,sp,-16
    80004a7a:	e406                	sd	ra,8(sp)
    80004a7c:	e022                	sd	s0,0(sp)
    80004a7e:	0800                	addi	s0,sp,16
    80004a80:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a82:	4585                	li	a1,1
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	db4080e7          	jalr	-588(ra) # 80004838 <namex>
}
    80004a8c:	60a2                	ld	ra,8(sp)
    80004a8e:	6402                	ld	s0,0(sp)
    80004a90:	0141                	addi	sp,sp,16
    80004a92:	8082                	ret

0000000080004a94 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a94:	1101                	addi	sp,sp,-32
    80004a96:	ec06                	sd	ra,24(sp)
    80004a98:	e822                	sd	s0,16(sp)
    80004a9a:	e426                	sd	s1,8(sp)
    80004a9c:	e04a                	sd	s2,0(sp)
    80004a9e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004aa0:	00039917          	auipc	s2,0x39
    80004aa4:	e0090913          	addi	s2,s2,-512 # 8003d8a0 <log>
    80004aa8:	01892583          	lw	a1,24(s2)
    80004aac:	02892503          	lw	a0,40(s2)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	ff0080e7          	jalr	-16(ra) # 80003aa0 <bread>
    80004ab8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004aba:	02c92683          	lw	a3,44(s2)
    80004abe:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004ac0:	02d05863          	blez	a3,80004af0 <write_head+0x5c>
    80004ac4:	00039797          	auipc	a5,0x39
    80004ac8:	e0c78793          	addi	a5,a5,-500 # 8003d8d0 <log+0x30>
    80004acc:	05c50713          	addi	a4,a0,92
    80004ad0:	36fd                	addiw	a3,a3,-1
    80004ad2:	02069613          	slli	a2,a3,0x20
    80004ad6:	01e65693          	srli	a3,a2,0x1e
    80004ada:	00039617          	auipc	a2,0x39
    80004ade:	dfa60613          	addi	a2,a2,-518 # 8003d8d4 <log+0x34>
    80004ae2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004ae4:	4390                	lw	a2,0(a5)
    80004ae6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004ae8:	0791                	addi	a5,a5,4
    80004aea:	0711                	addi	a4,a4,4
    80004aec:	fed79ce3          	bne	a5,a3,80004ae4 <write_head+0x50>
  }
  bwrite(buf);
    80004af0:	8526                	mv	a0,s1
    80004af2:	fffff097          	auipc	ra,0xfffff
    80004af6:	0a0080e7          	jalr	160(ra) # 80003b92 <bwrite>
  brelse(buf);
    80004afa:	8526                	mv	a0,s1
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	0d4080e7          	jalr	212(ra) # 80003bd0 <brelse>
}
    80004b04:	60e2                	ld	ra,24(sp)
    80004b06:	6442                	ld	s0,16(sp)
    80004b08:	64a2                	ld	s1,8(sp)
    80004b0a:	6902                	ld	s2,0(sp)
    80004b0c:	6105                	addi	sp,sp,32
    80004b0e:	8082                	ret

0000000080004b10 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b10:	00039797          	auipc	a5,0x39
    80004b14:	dbc7a783          	lw	a5,-580(a5) # 8003d8cc <log+0x2c>
    80004b18:	0af05d63          	blez	a5,80004bd2 <install_trans+0xc2>
{
    80004b1c:	7139                	addi	sp,sp,-64
    80004b1e:	fc06                	sd	ra,56(sp)
    80004b20:	f822                	sd	s0,48(sp)
    80004b22:	f426                	sd	s1,40(sp)
    80004b24:	f04a                	sd	s2,32(sp)
    80004b26:	ec4e                	sd	s3,24(sp)
    80004b28:	e852                	sd	s4,16(sp)
    80004b2a:	e456                	sd	s5,8(sp)
    80004b2c:	e05a                	sd	s6,0(sp)
    80004b2e:	0080                	addi	s0,sp,64
    80004b30:	8b2a                	mv	s6,a0
    80004b32:	00039a97          	auipc	s5,0x39
    80004b36:	d9ea8a93          	addi	s5,s5,-610 # 8003d8d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b3a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b3c:	00039997          	auipc	s3,0x39
    80004b40:	d6498993          	addi	s3,s3,-668 # 8003d8a0 <log>
    80004b44:	a00d                	j	80004b66 <install_trans+0x56>
    brelse(lbuf);
    80004b46:	854a                	mv	a0,s2
    80004b48:	fffff097          	auipc	ra,0xfffff
    80004b4c:	088080e7          	jalr	136(ra) # 80003bd0 <brelse>
    brelse(dbuf);
    80004b50:	8526                	mv	a0,s1
    80004b52:	fffff097          	auipc	ra,0xfffff
    80004b56:	07e080e7          	jalr	126(ra) # 80003bd0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b5a:	2a05                	addiw	s4,s4,1
    80004b5c:	0a91                	addi	s5,s5,4
    80004b5e:	02c9a783          	lw	a5,44(s3)
    80004b62:	04fa5e63          	bge	s4,a5,80004bbe <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b66:	0189a583          	lw	a1,24(s3)
    80004b6a:	014585bb          	addw	a1,a1,s4
    80004b6e:	2585                	addiw	a1,a1,1
    80004b70:	0289a503          	lw	a0,40(s3)
    80004b74:	fffff097          	auipc	ra,0xfffff
    80004b78:	f2c080e7          	jalr	-212(ra) # 80003aa0 <bread>
    80004b7c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b7e:	000aa583          	lw	a1,0(s5)
    80004b82:	0289a503          	lw	a0,40(s3)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	f1a080e7          	jalr	-230(ra) # 80003aa0 <bread>
    80004b8e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b90:	40000613          	li	a2,1024
    80004b94:	05890593          	addi	a1,s2,88
    80004b98:	05850513          	addi	a0,a0,88
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	1a2080e7          	jalr	418(ra) # 80000d3e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004ba4:	8526                	mv	a0,s1
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	fec080e7          	jalr	-20(ra) # 80003b92 <bwrite>
    if(recovering == 0)
    80004bae:	f80b1ce3          	bnez	s6,80004b46 <install_trans+0x36>
      bunpin(dbuf);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	fffff097          	auipc	ra,0xfffff
    80004bb8:	0f6080e7          	jalr	246(ra) # 80003caa <bunpin>
    80004bbc:	b769                	j	80004b46 <install_trans+0x36>
}
    80004bbe:	70e2                	ld	ra,56(sp)
    80004bc0:	7442                	ld	s0,48(sp)
    80004bc2:	74a2                	ld	s1,40(sp)
    80004bc4:	7902                	ld	s2,32(sp)
    80004bc6:	69e2                	ld	s3,24(sp)
    80004bc8:	6a42                	ld	s4,16(sp)
    80004bca:	6aa2                	ld	s5,8(sp)
    80004bcc:	6b02                	ld	s6,0(sp)
    80004bce:	6121                	addi	sp,sp,64
    80004bd0:	8082                	ret
    80004bd2:	8082                	ret

0000000080004bd4 <initlog>:
{
    80004bd4:	7179                	addi	sp,sp,-48
    80004bd6:	f406                	sd	ra,40(sp)
    80004bd8:	f022                	sd	s0,32(sp)
    80004bda:	ec26                	sd	s1,24(sp)
    80004bdc:	e84a                	sd	s2,16(sp)
    80004bde:	e44e                	sd	s3,8(sp)
    80004be0:	1800                	addi	s0,sp,48
    80004be2:	892a                	mv	s2,a0
    80004be4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004be6:	00039497          	auipc	s1,0x39
    80004bea:	cba48493          	addi	s1,s1,-838 # 8003d8a0 <log>
    80004bee:	00004597          	auipc	a1,0x4
    80004bf2:	a4a58593          	addi	a1,a1,-1462 # 80008638 <syscalls+0x210>
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	f3a080e7          	jalr	-198(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004c00:	0149a583          	lw	a1,20(s3)
    80004c04:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c06:	0109a783          	lw	a5,16(s3)
    80004c0a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c0c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c10:	854a                	mv	a0,s2
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	e8e080e7          	jalr	-370(ra) # 80003aa0 <bread>
  log.lh.n = lh->n;
    80004c1a:	4d34                	lw	a3,88(a0)
    80004c1c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c1e:	02d05663          	blez	a3,80004c4a <initlog+0x76>
    80004c22:	05c50793          	addi	a5,a0,92
    80004c26:	00039717          	auipc	a4,0x39
    80004c2a:	caa70713          	addi	a4,a4,-854 # 8003d8d0 <log+0x30>
    80004c2e:	36fd                	addiw	a3,a3,-1
    80004c30:	02069613          	slli	a2,a3,0x20
    80004c34:	01e65693          	srli	a3,a2,0x1e
    80004c38:	06050613          	addi	a2,a0,96
    80004c3c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004c3e:	4390                	lw	a2,0(a5)
    80004c40:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004c42:	0791                	addi	a5,a5,4
    80004c44:	0711                	addi	a4,a4,4
    80004c46:	fed79ce3          	bne	a5,a3,80004c3e <initlog+0x6a>
  brelse(buf);
    80004c4a:	fffff097          	auipc	ra,0xfffff
    80004c4e:	f86080e7          	jalr	-122(ra) # 80003bd0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c52:	4505                	li	a0,1
    80004c54:	00000097          	auipc	ra,0x0
    80004c58:	ebc080e7          	jalr	-324(ra) # 80004b10 <install_trans>
  log.lh.n = 0;
    80004c5c:	00039797          	auipc	a5,0x39
    80004c60:	c607a823          	sw	zero,-912(a5) # 8003d8cc <log+0x2c>
  write_head(); // clear the log
    80004c64:	00000097          	auipc	ra,0x0
    80004c68:	e30080e7          	jalr	-464(ra) # 80004a94 <write_head>
}
    80004c6c:	70a2                	ld	ra,40(sp)
    80004c6e:	7402                	ld	s0,32(sp)
    80004c70:	64e2                	ld	s1,24(sp)
    80004c72:	6942                	ld	s2,16(sp)
    80004c74:	69a2                	ld	s3,8(sp)
    80004c76:	6145                	addi	sp,sp,48
    80004c78:	8082                	ret

0000000080004c7a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c7a:	1101                	addi	sp,sp,-32
    80004c7c:	ec06                	sd	ra,24(sp)
    80004c7e:	e822                	sd	s0,16(sp)
    80004c80:	e426                	sd	s1,8(sp)
    80004c82:	e04a                	sd	s2,0(sp)
    80004c84:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c86:	00039517          	auipc	a0,0x39
    80004c8a:	c1a50513          	addi	a0,a0,-998 # 8003d8a0 <log>
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	f34080e7          	jalr	-204(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004c96:	00039497          	auipc	s1,0x39
    80004c9a:	c0a48493          	addi	s1,s1,-1014 # 8003d8a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c9e:	4979                	li	s2,30
    80004ca0:	a039                	j	80004cae <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ca2:	85a6                	mv	a1,s1
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	ffffe097          	auipc	ra,0xffffe
    80004caa:	8ae080e7          	jalr	-1874(ra) # 80002554 <sleep>
    if(log.committing){
    80004cae:	50dc                	lw	a5,36(s1)
    80004cb0:	fbed                	bnez	a5,80004ca2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cb2:	509c                	lw	a5,32(s1)
    80004cb4:	0017871b          	addiw	a4,a5,1
    80004cb8:	0007069b          	sext.w	a3,a4
    80004cbc:	0027179b          	slliw	a5,a4,0x2
    80004cc0:	9fb9                	addw	a5,a5,a4
    80004cc2:	0017979b          	slliw	a5,a5,0x1
    80004cc6:	54d8                	lw	a4,44(s1)
    80004cc8:	9fb9                	addw	a5,a5,a4
    80004cca:	00f95963          	bge	s2,a5,80004cdc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004cce:	85a6                	mv	a1,s1
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffe097          	auipc	ra,0xffffe
    80004cd6:	882080e7          	jalr	-1918(ra) # 80002554 <sleep>
    80004cda:	bfd1                	j	80004cae <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004cdc:	00039517          	auipc	a0,0x39
    80004ce0:	bc450513          	addi	a0,a0,-1084 # 8003d8a0 <log>
    80004ce4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	fa2080e7          	jalr	-94(ra) # 80000c88 <release>
      break;
    }
  }
}
    80004cee:	60e2                	ld	ra,24(sp)
    80004cf0:	6442                	ld	s0,16(sp)
    80004cf2:	64a2                	ld	s1,8(sp)
    80004cf4:	6902                	ld	s2,0(sp)
    80004cf6:	6105                	addi	sp,sp,32
    80004cf8:	8082                	ret

0000000080004cfa <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004cfa:	7139                	addi	sp,sp,-64
    80004cfc:	fc06                	sd	ra,56(sp)
    80004cfe:	f822                	sd	s0,48(sp)
    80004d00:	f426                	sd	s1,40(sp)
    80004d02:	f04a                	sd	s2,32(sp)
    80004d04:	ec4e                	sd	s3,24(sp)
    80004d06:	e852                	sd	s4,16(sp)
    80004d08:	e456                	sd	s5,8(sp)
    80004d0a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d0c:	00039497          	auipc	s1,0x39
    80004d10:	b9448493          	addi	s1,s1,-1132 # 8003d8a0 <log>
    80004d14:	8526                	mv	a0,s1
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	eac080e7          	jalr	-340(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004d1e:	509c                	lw	a5,32(s1)
    80004d20:	37fd                	addiw	a5,a5,-1
    80004d22:	0007891b          	sext.w	s2,a5
    80004d26:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d28:	50dc                	lw	a5,36(s1)
    80004d2a:	e7b9                	bnez	a5,80004d78 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d2c:	04091e63          	bnez	s2,80004d88 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004d30:	00039497          	auipc	s1,0x39
    80004d34:	b7048493          	addi	s1,s1,-1168 # 8003d8a0 <log>
    80004d38:	4785                	li	a5,1
    80004d3a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	f4a080e7          	jalr	-182(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d46:	54dc                	lw	a5,44(s1)
    80004d48:	06f04763          	bgtz	a5,80004db6 <end_op+0xbc>
    acquire(&log.lock);
    80004d4c:	00039497          	auipc	s1,0x39
    80004d50:	b5448493          	addi	s1,s1,-1196 # 8003d8a0 <log>
    80004d54:	8526                	mv	a0,s1
    80004d56:	ffffc097          	auipc	ra,0xffffc
    80004d5a:	e6c080e7          	jalr	-404(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004d5e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d62:	8526                	mv	a0,s1
    80004d64:	ffffe097          	auipc	ra,0xffffe
    80004d68:	97a080e7          	jalr	-1670(ra) # 800026de <wakeup>
    release(&log.lock);
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	f1a080e7          	jalr	-230(ra) # 80000c88 <release>
}
    80004d76:	a03d                	j	80004da4 <end_op+0xaa>
    panic("log.committing");
    80004d78:	00004517          	auipc	a0,0x4
    80004d7c:	8c850513          	addi	a0,a0,-1848 # 80008640 <syscalls+0x218>
    80004d80:	ffffb097          	auipc	ra,0xffffb
    80004d84:	7aa080e7          	jalr	1962(ra) # 8000052a <panic>
    wakeup(&log);
    80004d88:	00039497          	auipc	s1,0x39
    80004d8c:	b1848493          	addi	s1,s1,-1256 # 8003d8a0 <log>
    80004d90:	8526                	mv	a0,s1
    80004d92:	ffffe097          	auipc	ra,0xffffe
    80004d96:	94c080e7          	jalr	-1716(ra) # 800026de <wakeup>
  release(&log.lock);
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	eec080e7          	jalr	-276(ra) # 80000c88 <release>
}
    80004da4:	70e2                	ld	ra,56(sp)
    80004da6:	7442                	ld	s0,48(sp)
    80004da8:	74a2                	ld	s1,40(sp)
    80004daa:	7902                	ld	s2,32(sp)
    80004dac:	69e2                	ld	s3,24(sp)
    80004dae:	6a42                	ld	s4,16(sp)
    80004db0:	6aa2                	ld	s5,8(sp)
    80004db2:	6121                	addi	sp,sp,64
    80004db4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004db6:	00039a97          	auipc	s5,0x39
    80004dba:	b1aa8a93          	addi	s5,s5,-1254 # 8003d8d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dbe:	00039a17          	auipc	s4,0x39
    80004dc2:	ae2a0a13          	addi	s4,s4,-1310 # 8003d8a0 <log>
    80004dc6:	018a2583          	lw	a1,24(s4)
    80004dca:	012585bb          	addw	a1,a1,s2
    80004dce:	2585                	addiw	a1,a1,1
    80004dd0:	028a2503          	lw	a0,40(s4)
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	ccc080e7          	jalr	-820(ra) # 80003aa0 <bread>
    80004ddc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004dde:	000aa583          	lw	a1,0(s5)
    80004de2:	028a2503          	lw	a0,40(s4)
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	cba080e7          	jalr	-838(ra) # 80003aa0 <bread>
    80004dee:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004df0:	40000613          	li	a2,1024
    80004df4:	05850593          	addi	a1,a0,88
    80004df8:	05848513          	addi	a0,s1,88
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	f42080e7          	jalr	-190(ra) # 80000d3e <memmove>
    bwrite(to);  // write the log
    80004e04:	8526                	mv	a0,s1
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	d8c080e7          	jalr	-628(ra) # 80003b92 <bwrite>
    brelse(from);
    80004e0e:	854e                	mv	a0,s3
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	dc0080e7          	jalr	-576(ra) # 80003bd0 <brelse>
    brelse(to);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	db6080e7          	jalr	-586(ra) # 80003bd0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e22:	2905                	addiw	s2,s2,1
    80004e24:	0a91                	addi	s5,s5,4
    80004e26:	02ca2783          	lw	a5,44(s4)
    80004e2a:	f8f94ee3          	blt	s2,a5,80004dc6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e2e:	00000097          	auipc	ra,0x0
    80004e32:	c66080e7          	jalr	-922(ra) # 80004a94 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e36:	4501                	li	a0,0
    80004e38:	00000097          	auipc	ra,0x0
    80004e3c:	cd8080e7          	jalr	-808(ra) # 80004b10 <install_trans>
    log.lh.n = 0;
    80004e40:	00039797          	auipc	a5,0x39
    80004e44:	a807a623          	sw	zero,-1396(a5) # 8003d8cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	c4c080e7          	jalr	-948(ra) # 80004a94 <write_head>
    80004e50:	bdf5                	j	80004d4c <end_op+0x52>

0000000080004e52 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e52:	1101                	addi	sp,sp,-32
    80004e54:	ec06                	sd	ra,24(sp)
    80004e56:	e822                	sd	s0,16(sp)
    80004e58:	e426                	sd	s1,8(sp)
    80004e5a:	e04a                	sd	s2,0(sp)
    80004e5c:	1000                	addi	s0,sp,32
    80004e5e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e60:	00039917          	auipc	s2,0x39
    80004e64:	a4090913          	addi	s2,s2,-1472 # 8003d8a0 <log>
    80004e68:	854a                	mv	a0,s2
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	d58080e7          	jalr	-680(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e72:	02c92603          	lw	a2,44(s2)
    80004e76:	47f5                	li	a5,29
    80004e78:	06c7c563          	blt	a5,a2,80004ee2 <log_write+0x90>
    80004e7c:	00039797          	auipc	a5,0x39
    80004e80:	a407a783          	lw	a5,-1472(a5) # 8003d8bc <log+0x1c>
    80004e84:	37fd                	addiw	a5,a5,-1
    80004e86:	04f65e63          	bge	a2,a5,80004ee2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e8a:	00039797          	auipc	a5,0x39
    80004e8e:	a367a783          	lw	a5,-1482(a5) # 8003d8c0 <log+0x20>
    80004e92:	06f05063          	blez	a5,80004ef2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e96:	4781                	li	a5,0
    80004e98:	06c05563          	blez	a2,80004f02 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004e9c:	44cc                	lw	a1,12(s1)
    80004e9e:	00039717          	auipc	a4,0x39
    80004ea2:	a3270713          	addi	a4,a4,-1486 # 8003d8d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ea6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004ea8:	4314                	lw	a3,0(a4)
    80004eaa:	04b68c63          	beq	a3,a1,80004f02 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004eae:	2785                	addiw	a5,a5,1
    80004eb0:	0711                	addi	a4,a4,4
    80004eb2:	fef61be3          	bne	a2,a5,80004ea8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004eb6:	0621                	addi	a2,a2,8
    80004eb8:	060a                	slli	a2,a2,0x2
    80004eba:	00039797          	auipc	a5,0x39
    80004ebe:	9e678793          	addi	a5,a5,-1562 # 8003d8a0 <log>
    80004ec2:	963e                	add	a2,a2,a5
    80004ec4:	44dc                	lw	a5,12(s1)
    80004ec6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ec8:	8526                	mv	a0,s1
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	da4080e7          	jalr	-604(ra) # 80003c6e <bpin>
    log.lh.n++;
    80004ed2:	00039717          	auipc	a4,0x39
    80004ed6:	9ce70713          	addi	a4,a4,-1586 # 8003d8a0 <log>
    80004eda:	575c                	lw	a5,44(a4)
    80004edc:	2785                	addiw	a5,a5,1
    80004ede:	d75c                	sw	a5,44(a4)
    80004ee0:	a835                	j	80004f1c <log_write+0xca>
    panic("too big a transaction");
    80004ee2:	00003517          	auipc	a0,0x3
    80004ee6:	76e50513          	addi	a0,a0,1902 # 80008650 <syscalls+0x228>
    80004eea:	ffffb097          	auipc	ra,0xffffb
    80004eee:	640080e7          	jalr	1600(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004ef2:	00003517          	auipc	a0,0x3
    80004ef6:	77650513          	addi	a0,a0,1910 # 80008668 <syscalls+0x240>
    80004efa:	ffffb097          	auipc	ra,0xffffb
    80004efe:	630080e7          	jalr	1584(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004f02:	00878713          	addi	a4,a5,8
    80004f06:	00271693          	slli	a3,a4,0x2
    80004f0a:	00039717          	auipc	a4,0x39
    80004f0e:	99670713          	addi	a4,a4,-1642 # 8003d8a0 <log>
    80004f12:	9736                	add	a4,a4,a3
    80004f14:	44d4                	lw	a3,12(s1)
    80004f16:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f18:	faf608e3          	beq	a2,a5,80004ec8 <log_write+0x76>
  }
  release(&log.lock);
    80004f1c:	00039517          	auipc	a0,0x39
    80004f20:	98450513          	addi	a0,a0,-1660 # 8003d8a0 <log>
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	d64080e7          	jalr	-668(ra) # 80000c88 <release>
}
    80004f2c:	60e2                	ld	ra,24(sp)
    80004f2e:	6442                	ld	s0,16(sp)
    80004f30:	64a2                	ld	s1,8(sp)
    80004f32:	6902                	ld	s2,0(sp)
    80004f34:	6105                	addi	sp,sp,32
    80004f36:	8082                	ret

0000000080004f38 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f38:	1101                	addi	sp,sp,-32
    80004f3a:	ec06                	sd	ra,24(sp)
    80004f3c:	e822                	sd	s0,16(sp)
    80004f3e:	e426                	sd	s1,8(sp)
    80004f40:	e04a                	sd	s2,0(sp)
    80004f42:	1000                	addi	s0,sp,32
    80004f44:	84aa                	mv	s1,a0
    80004f46:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f48:	00003597          	auipc	a1,0x3
    80004f4c:	74058593          	addi	a1,a1,1856 # 80008688 <syscalls+0x260>
    80004f50:	0521                	addi	a0,a0,8
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	be0080e7          	jalr	-1056(ra) # 80000b32 <initlock>
  lk->name = name;
    80004f5a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f5e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f62:	0204a423          	sw	zero,40(s1)
}
    80004f66:	60e2                	ld	ra,24(sp)
    80004f68:	6442                	ld	s0,16(sp)
    80004f6a:	64a2                	ld	s1,8(sp)
    80004f6c:	6902                	ld	s2,0(sp)
    80004f6e:	6105                	addi	sp,sp,32
    80004f70:	8082                	ret

0000000080004f72 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f72:	1101                	addi	sp,sp,-32
    80004f74:	ec06                	sd	ra,24(sp)
    80004f76:	e822                	sd	s0,16(sp)
    80004f78:	e426                	sd	s1,8(sp)
    80004f7a:	e04a                	sd	s2,0(sp)
    80004f7c:	1000                	addi	s0,sp,32
    80004f7e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f80:	00850913          	addi	s2,a0,8
    80004f84:	854a                	mv	a0,s2
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	c3c080e7          	jalr	-964(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004f8e:	409c                	lw	a5,0(s1)
    80004f90:	cb89                	beqz	a5,80004fa2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f92:	85ca                	mv	a1,s2
    80004f94:	8526                	mv	a0,s1
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	5be080e7          	jalr	1470(ra) # 80002554 <sleep>
  while (lk->locked) {
    80004f9e:	409c                	lw	a5,0(s1)
    80004fa0:	fbed                	bnez	a5,80004f92 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fa2:	4785                	li	a5,1
    80004fa4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fa6:	ffffd097          	auipc	ra,0xffffd
    80004faa:	a5c080e7          	jalr	-1444(ra) # 80001a02 <myproc>
    80004fae:	515c                	lw	a5,36(a0)
    80004fb0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fb2:	854a                	mv	a0,s2
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	cd4080e7          	jalr	-812(ra) # 80000c88 <release>
}
    80004fbc:	60e2                	ld	ra,24(sp)
    80004fbe:	6442                	ld	s0,16(sp)
    80004fc0:	64a2                	ld	s1,8(sp)
    80004fc2:	6902                	ld	s2,0(sp)
    80004fc4:	6105                	addi	sp,sp,32
    80004fc6:	8082                	ret

0000000080004fc8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004fc8:	1101                	addi	sp,sp,-32
    80004fca:	ec06                	sd	ra,24(sp)
    80004fcc:	e822                	sd	s0,16(sp)
    80004fce:	e426                	sd	s1,8(sp)
    80004fd0:	e04a                	sd	s2,0(sp)
    80004fd2:	1000                	addi	s0,sp,32
    80004fd4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fd6:	00850913          	addi	s2,a0,8
    80004fda:	854a                	mv	a0,s2
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	be6080e7          	jalr	-1050(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004fe4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fe8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004fec:	8526                	mv	a0,s1
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	6f0080e7          	jalr	1776(ra) # 800026de <wakeup>
  release(&lk->lk);
    80004ff6:	854a                	mv	a0,s2
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	c90080e7          	jalr	-880(ra) # 80000c88 <release>
}
    80005000:	60e2                	ld	ra,24(sp)
    80005002:	6442                	ld	s0,16(sp)
    80005004:	64a2                	ld	s1,8(sp)
    80005006:	6902                	ld	s2,0(sp)
    80005008:	6105                	addi	sp,sp,32
    8000500a:	8082                	ret

000000008000500c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000500c:	7179                	addi	sp,sp,-48
    8000500e:	f406                	sd	ra,40(sp)
    80005010:	f022                	sd	s0,32(sp)
    80005012:	ec26                	sd	s1,24(sp)
    80005014:	e84a                	sd	s2,16(sp)
    80005016:	e44e                	sd	s3,8(sp)
    80005018:	1800                	addi	s0,sp,48
    8000501a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000501c:	00850913          	addi	s2,a0,8
    80005020:	854a                	mv	a0,s2
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	ba0080e7          	jalr	-1120(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000502a:	409c                	lw	a5,0(s1)
    8000502c:	ef99                	bnez	a5,8000504a <holdingsleep+0x3e>
    8000502e:	4481                	li	s1,0
  release(&lk->lk);
    80005030:	854a                	mv	a0,s2
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	c56080e7          	jalr	-938(ra) # 80000c88 <release>
  return r;
}
    8000503a:	8526                	mv	a0,s1
    8000503c:	70a2                	ld	ra,40(sp)
    8000503e:	7402                	ld	s0,32(sp)
    80005040:	64e2                	ld	s1,24(sp)
    80005042:	6942                	ld	s2,16(sp)
    80005044:	69a2                	ld	s3,8(sp)
    80005046:	6145                	addi	sp,sp,48
    80005048:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000504a:	0284a983          	lw	s3,40(s1)
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	9b4080e7          	jalr	-1612(ra) # 80001a02 <myproc>
    80005056:	5144                	lw	s1,36(a0)
    80005058:	413484b3          	sub	s1,s1,s3
    8000505c:	0014b493          	seqz	s1,s1
    80005060:	bfc1                	j	80005030 <holdingsleep+0x24>

0000000080005062 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005062:	1141                	addi	sp,sp,-16
    80005064:	e406                	sd	ra,8(sp)
    80005066:	e022                	sd	s0,0(sp)
    80005068:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000506a:	00003597          	auipc	a1,0x3
    8000506e:	62e58593          	addi	a1,a1,1582 # 80008698 <syscalls+0x270>
    80005072:	00039517          	auipc	a0,0x39
    80005076:	97650513          	addi	a0,a0,-1674 # 8003d9e8 <ftable>
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	ab8080e7          	jalr	-1352(ra) # 80000b32 <initlock>
}
    80005082:	60a2                	ld	ra,8(sp)
    80005084:	6402                	ld	s0,0(sp)
    80005086:	0141                	addi	sp,sp,16
    80005088:	8082                	ret

000000008000508a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000508a:	1101                	addi	sp,sp,-32
    8000508c:	ec06                	sd	ra,24(sp)
    8000508e:	e822                	sd	s0,16(sp)
    80005090:	e426                	sd	s1,8(sp)
    80005092:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005094:	00039517          	auipc	a0,0x39
    80005098:	95450513          	addi	a0,a0,-1708 # 8003d9e8 <ftable>
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	b26080e7          	jalr	-1242(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050a4:	00039497          	auipc	s1,0x39
    800050a8:	95c48493          	addi	s1,s1,-1700 # 8003da00 <ftable+0x18>
    800050ac:	0003a717          	auipc	a4,0x3a
    800050b0:	8f470713          	addi	a4,a4,-1804 # 8003e9a0 <ftable+0xfb8>
    if(f->ref == 0){
    800050b4:	40dc                	lw	a5,4(s1)
    800050b6:	cf99                	beqz	a5,800050d4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050b8:	02848493          	addi	s1,s1,40
    800050bc:	fee49ce3          	bne	s1,a4,800050b4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050c0:	00039517          	auipc	a0,0x39
    800050c4:	92850513          	addi	a0,a0,-1752 # 8003d9e8 <ftable>
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	bc0080e7          	jalr	-1088(ra) # 80000c88 <release>
  return 0;
    800050d0:	4481                	li	s1,0
    800050d2:	a819                	j	800050e8 <filealloc+0x5e>
      f->ref = 1;
    800050d4:	4785                	li	a5,1
    800050d6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050d8:	00039517          	auipc	a0,0x39
    800050dc:	91050513          	addi	a0,a0,-1776 # 8003d9e8 <ftable>
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	ba8080e7          	jalr	-1112(ra) # 80000c88 <release>
}
    800050e8:	8526                	mv	a0,s1
    800050ea:	60e2                	ld	ra,24(sp)
    800050ec:	6442                	ld	s0,16(sp)
    800050ee:	64a2                	ld	s1,8(sp)
    800050f0:	6105                	addi	sp,sp,32
    800050f2:	8082                	ret

00000000800050f4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800050f4:	1101                	addi	sp,sp,-32
    800050f6:	ec06                	sd	ra,24(sp)
    800050f8:	e822                	sd	s0,16(sp)
    800050fa:	e426                	sd	s1,8(sp)
    800050fc:	1000                	addi	s0,sp,32
    800050fe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005100:	00039517          	auipc	a0,0x39
    80005104:	8e850513          	addi	a0,a0,-1816 # 8003d9e8 <ftable>
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	aba080e7          	jalr	-1350(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005110:	40dc                	lw	a5,4(s1)
    80005112:	02f05263          	blez	a5,80005136 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005116:	2785                	addiw	a5,a5,1
    80005118:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000511a:	00039517          	auipc	a0,0x39
    8000511e:	8ce50513          	addi	a0,a0,-1842 # 8003d9e8 <ftable>
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	b66080e7          	jalr	-1178(ra) # 80000c88 <release>
  return f;
}
    8000512a:	8526                	mv	a0,s1
    8000512c:	60e2                	ld	ra,24(sp)
    8000512e:	6442                	ld	s0,16(sp)
    80005130:	64a2                	ld	s1,8(sp)
    80005132:	6105                	addi	sp,sp,32
    80005134:	8082                	ret
    panic("filedup");
    80005136:	00003517          	auipc	a0,0x3
    8000513a:	56a50513          	addi	a0,a0,1386 # 800086a0 <syscalls+0x278>
    8000513e:	ffffb097          	auipc	ra,0xffffb
    80005142:	3ec080e7          	jalr	1004(ra) # 8000052a <panic>

0000000080005146 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005146:	7139                	addi	sp,sp,-64
    80005148:	fc06                	sd	ra,56(sp)
    8000514a:	f822                	sd	s0,48(sp)
    8000514c:	f426                	sd	s1,40(sp)
    8000514e:	f04a                	sd	s2,32(sp)
    80005150:	ec4e                	sd	s3,24(sp)
    80005152:	e852                	sd	s4,16(sp)
    80005154:	e456                	sd	s5,8(sp)
    80005156:	0080                	addi	s0,sp,64
    80005158:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000515a:	00039517          	auipc	a0,0x39
    8000515e:	88e50513          	addi	a0,a0,-1906 # 8003d9e8 <ftable>
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	a60080e7          	jalr	-1440(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000516a:	40dc                	lw	a5,4(s1)
    8000516c:	06f05163          	blez	a5,800051ce <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005170:	37fd                	addiw	a5,a5,-1
    80005172:	0007871b          	sext.w	a4,a5
    80005176:	c0dc                	sw	a5,4(s1)
    80005178:	06e04363          	bgtz	a4,800051de <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000517c:	0004a903          	lw	s2,0(s1)
    80005180:	0094ca83          	lbu	s5,9(s1)
    80005184:	0104ba03          	ld	s4,16(s1)
    80005188:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000518c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005190:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005194:	00039517          	auipc	a0,0x39
    80005198:	85450513          	addi	a0,a0,-1964 # 8003d9e8 <ftable>
    8000519c:	ffffc097          	auipc	ra,0xffffc
    800051a0:	aec080e7          	jalr	-1300(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    800051a4:	4785                	li	a5,1
    800051a6:	04f90d63          	beq	s2,a5,80005200 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051aa:	3979                	addiw	s2,s2,-2
    800051ac:	4785                	li	a5,1
    800051ae:	0527e063          	bltu	a5,s2,800051ee <fileclose+0xa8>
    begin_op();
    800051b2:	00000097          	auipc	ra,0x0
    800051b6:	ac8080e7          	jalr	-1336(ra) # 80004c7a <begin_op>
    iput(ff.ip);
    800051ba:	854e                	mv	a0,s3
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	2a2080e7          	jalr	674(ra) # 8000445e <iput>
    end_op();
    800051c4:	00000097          	auipc	ra,0x0
    800051c8:	b36080e7          	jalr	-1226(ra) # 80004cfa <end_op>
    800051cc:	a00d                	j	800051ee <fileclose+0xa8>
    panic("fileclose");
    800051ce:	00003517          	auipc	a0,0x3
    800051d2:	4da50513          	addi	a0,a0,1242 # 800086a8 <syscalls+0x280>
    800051d6:	ffffb097          	auipc	ra,0xffffb
    800051da:	354080e7          	jalr	852(ra) # 8000052a <panic>
    release(&ftable.lock);
    800051de:	00039517          	auipc	a0,0x39
    800051e2:	80a50513          	addi	a0,a0,-2038 # 8003d9e8 <ftable>
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	aa2080e7          	jalr	-1374(ra) # 80000c88 <release>
  }
}
    800051ee:	70e2                	ld	ra,56(sp)
    800051f0:	7442                	ld	s0,48(sp)
    800051f2:	74a2                	ld	s1,40(sp)
    800051f4:	7902                	ld	s2,32(sp)
    800051f6:	69e2                	ld	s3,24(sp)
    800051f8:	6a42                	ld	s4,16(sp)
    800051fa:	6aa2                	ld	s5,8(sp)
    800051fc:	6121                	addi	sp,sp,64
    800051fe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005200:	85d6                	mv	a1,s5
    80005202:	8552                	mv	a0,s4
    80005204:	00000097          	auipc	ra,0x0
    80005208:	34c080e7          	jalr	844(ra) # 80005550 <pipeclose>
    8000520c:	b7cd                	j	800051ee <fileclose+0xa8>

000000008000520e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000520e:	715d                	addi	sp,sp,-80
    80005210:	e486                	sd	ra,72(sp)
    80005212:	e0a2                	sd	s0,64(sp)
    80005214:	fc26                	sd	s1,56(sp)
    80005216:	f84a                	sd	s2,48(sp)
    80005218:	f44e                	sd	s3,40(sp)
    8000521a:	0880                	addi	s0,sp,80
    8000521c:	84aa                	mv	s1,a0
    8000521e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	7e2080e7          	jalr	2018(ra) # 80001a02 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005228:	409c                	lw	a5,0(s1)
    8000522a:	37f9                	addiw	a5,a5,-2
    8000522c:	4705                	li	a4,1
    8000522e:	04f76763          	bltu	a4,a5,8000527c <filestat+0x6e>
    80005232:	892a                	mv	s2,a0
    ilock(f->ip);
    80005234:	6c88                	ld	a0,24(s1)
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	06e080e7          	jalr	110(ra) # 800042a4 <ilock>
    stati(f->ip, &st);
    8000523e:	fb840593          	addi	a1,s0,-72
    80005242:	6c88                	ld	a0,24(s1)
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	2ea080e7          	jalr	746(ra) # 8000452e <stati>
    iunlock(f->ip);
    8000524c:	6c88                	ld	a0,24(s1)
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	118080e7          	jalr	280(ra) # 80004366 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005256:	46e1                	li	a3,24
    80005258:	fb840613          	addi	a2,s0,-72
    8000525c:	85ce                	mv	a1,s3
    8000525e:	1d893503          	ld	a0,472(s2)
    80005262:	ffffc097          	auipc	ra,0xffffc
    80005266:	400080e7          	jalr	1024(ra) # 80001662 <copyout>
    8000526a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000526e:	60a6                	ld	ra,72(sp)
    80005270:	6406                	ld	s0,64(sp)
    80005272:	74e2                	ld	s1,56(sp)
    80005274:	7942                	ld	s2,48(sp)
    80005276:	79a2                	ld	s3,40(sp)
    80005278:	6161                	addi	sp,sp,80
    8000527a:	8082                	ret
  return -1;
    8000527c:	557d                	li	a0,-1
    8000527e:	bfc5                	j	8000526e <filestat+0x60>

0000000080005280 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005280:	7179                	addi	sp,sp,-48
    80005282:	f406                	sd	ra,40(sp)
    80005284:	f022                	sd	s0,32(sp)
    80005286:	ec26                	sd	s1,24(sp)
    80005288:	e84a                	sd	s2,16(sp)
    8000528a:	e44e                	sd	s3,8(sp)
    8000528c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000528e:	00854783          	lbu	a5,8(a0)
    80005292:	c3d5                	beqz	a5,80005336 <fileread+0xb6>
    80005294:	84aa                	mv	s1,a0
    80005296:	89ae                	mv	s3,a1
    80005298:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000529a:	411c                	lw	a5,0(a0)
    8000529c:	4705                	li	a4,1
    8000529e:	04e78963          	beq	a5,a4,800052f0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052a2:	470d                	li	a4,3
    800052a4:	04e78d63          	beq	a5,a4,800052fe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052a8:	4709                	li	a4,2
    800052aa:	06e79e63          	bne	a5,a4,80005326 <fileread+0xa6>
    ilock(f->ip);
    800052ae:	6d08                	ld	a0,24(a0)
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	ff4080e7          	jalr	-12(ra) # 800042a4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052b8:	874a                	mv	a4,s2
    800052ba:	5094                	lw	a3,32(s1)
    800052bc:	864e                	mv	a2,s3
    800052be:	4585                	li	a1,1
    800052c0:	6c88                	ld	a0,24(s1)
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	296080e7          	jalr	662(ra) # 80004558 <readi>
    800052ca:	892a                	mv	s2,a0
    800052cc:	00a05563          	blez	a0,800052d6 <fileread+0x56>
      f->off += r;
    800052d0:	509c                	lw	a5,32(s1)
    800052d2:	9fa9                	addw	a5,a5,a0
    800052d4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052d6:	6c88                	ld	a0,24(s1)
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	08e080e7          	jalr	142(ra) # 80004366 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052e0:	854a                	mv	a0,s2
    800052e2:	70a2                	ld	ra,40(sp)
    800052e4:	7402                	ld	s0,32(sp)
    800052e6:	64e2                	ld	s1,24(sp)
    800052e8:	6942                	ld	s2,16(sp)
    800052ea:	69a2                	ld	s3,8(sp)
    800052ec:	6145                	addi	sp,sp,48
    800052ee:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800052f0:	6908                	ld	a0,16(a0)
    800052f2:	00000097          	auipc	ra,0x0
    800052f6:	3c0080e7          	jalr	960(ra) # 800056b2 <piperead>
    800052fa:	892a                	mv	s2,a0
    800052fc:	b7d5                	j	800052e0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800052fe:	02451783          	lh	a5,36(a0)
    80005302:	03079693          	slli	a3,a5,0x30
    80005306:	92c1                	srli	a3,a3,0x30
    80005308:	4725                	li	a4,9
    8000530a:	02d76863          	bltu	a4,a3,8000533a <fileread+0xba>
    8000530e:	0792                	slli	a5,a5,0x4
    80005310:	00038717          	auipc	a4,0x38
    80005314:	63870713          	addi	a4,a4,1592 # 8003d948 <devsw>
    80005318:	97ba                	add	a5,a5,a4
    8000531a:	639c                	ld	a5,0(a5)
    8000531c:	c38d                	beqz	a5,8000533e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000531e:	4505                	li	a0,1
    80005320:	9782                	jalr	a5
    80005322:	892a                	mv	s2,a0
    80005324:	bf75                	j	800052e0 <fileread+0x60>
    panic("fileread");
    80005326:	00003517          	auipc	a0,0x3
    8000532a:	39250513          	addi	a0,a0,914 # 800086b8 <syscalls+0x290>
    8000532e:	ffffb097          	auipc	ra,0xffffb
    80005332:	1fc080e7          	jalr	508(ra) # 8000052a <panic>
    return -1;
    80005336:	597d                	li	s2,-1
    80005338:	b765                	j	800052e0 <fileread+0x60>
      return -1;
    8000533a:	597d                	li	s2,-1
    8000533c:	b755                	j	800052e0 <fileread+0x60>
    8000533e:	597d                	li	s2,-1
    80005340:	b745                	j	800052e0 <fileread+0x60>

0000000080005342 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005342:	715d                	addi	sp,sp,-80
    80005344:	e486                	sd	ra,72(sp)
    80005346:	e0a2                	sd	s0,64(sp)
    80005348:	fc26                	sd	s1,56(sp)
    8000534a:	f84a                	sd	s2,48(sp)
    8000534c:	f44e                	sd	s3,40(sp)
    8000534e:	f052                	sd	s4,32(sp)
    80005350:	ec56                	sd	s5,24(sp)
    80005352:	e85a                	sd	s6,16(sp)
    80005354:	e45e                	sd	s7,8(sp)
    80005356:	e062                	sd	s8,0(sp)
    80005358:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000535a:	00954783          	lbu	a5,9(a0)
    8000535e:	10078663          	beqz	a5,8000546a <filewrite+0x128>
    80005362:	892a                	mv	s2,a0
    80005364:	8aae                	mv	s5,a1
    80005366:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005368:	411c                	lw	a5,0(a0)
    8000536a:	4705                	li	a4,1
    8000536c:	02e78263          	beq	a5,a4,80005390 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005370:	470d                	li	a4,3
    80005372:	02e78663          	beq	a5,a4,8000539e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005376:	4709                	li	a4,2
    80005378:	0ee79163          	bne	a5,a4,8000545a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000537c:	0ac05d63          	blez	a2,80005436 <filewrite+0xf4>
    int i = 0;
    80005380:	4981                	li	s3,0
    80005382:	6b05                	lui	s6,0x1
    80005384:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005388:	6b85                	lui	s7,0x1
    8000538a:	c00b8b9b          	addiw	s7,s7,-1024
    8000538e:	a861                	j	80005426 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005390:	6908                	ld	a0,16(a0)
    80005392:	00000097          	auipc	ra,0x0
    80005396:	22e080e7          	jalr	558(ra) # 800055c0 <pipewrite>
    8000539a:	8a2a                	mv	s4,a0
    8000539c:	a045                	j	8000543c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000539e:	02451783          	lh	a5,36(a0)
    800053a2:	03079693          	slli	a3,a5,0x30
    800053a6:	92c1                	srli	a3,a3,0x30
    800053a8:	4725                	li	a4,9
    800053aa:	0cd76263          	bltu	a4,a3,8000546e <filewrite+0x12c>
    800053ae:	0792                	slli	a5,a5,0x4
    800053b0:	00038717          	auipc	a4,0x38
    800053b4:	59870713          	addi	a4,a4,1432 # 8003d948 <devsw>
    800053b8:	97ba                	add	a5,a5,a4
    800053ba:	679c                	ld	a5,8(a5)
    800053bc:	cbdd                	beqz	a5,80005472 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053be:	4505                	li	a0,1
    800053c0:	9782                	jalr	a5
    800053c2:	8a2a                	mv	s4,a0
    800053c4:	a8a5                	j	8000543c <filewrite+0xfa>
    800053c6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053ca:	00000097          	auipc	ra,0x0
    800053ce:	8b0080e7          	jalr	-1872(ra) # 80004c7a <begin_op>
      ilock(f->ip);
    800053d2:	01893503          	ld	a0,24(s2)
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	ece080e7          	jalr	-306(ra) # 800042a4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053de:	8762                	mv	a4,s8
    800053e0:	02092683          	lw	a3,32(s2)
    800053e4:	01598633          	add	a2,s3,s5
    800053e8:	4585                	li	a1,1
    800053ea:	01893503          	ld	a0,24(s2)
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	262080e7          	jalr	610(ra) # 80004650 <writei>
    800053f6:	84aa                	mv	s1,a0
    800053f8:	00a05763          	blez	a0,80005406 <filewrite+0xc4>
        f->off += r;
    800053fc:	02092783          	lw	a5,32(s2)
    80005400:	9fa9                	addw	a5,a5,a0
    80005402:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005406:	01893503          	ld	a0,24(s2)
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	f5c080e7          	jalr	-164(ra) # 80004366 <iunlock>
      end_op();
    80005412:	00000097          	auipc	ra,0x0
    80005416:	8e8080e7          	jalr	-1816(ra) # 80004cfa <end_op>

      if(r != n1){
    8000541a:	009c1f63          	bne	s8,s1,80005438 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000541e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005422:	0149db63          	bge	s3,s4,80005438 <filewrite+0xf6>
      int n1 = n - i;
    80005426:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000542a:	84be                	mv	s1,a5
    8000542c:	2781                	sext.w	a5,a5
    8000542e:	f8fb5ce3          	bge	s6,a5,800053c6 <filewrite+0x84>
    80005432:	84de                	mv	s1,s7
    80005434:	bf49                	j	800053c6 <filewrite+0x84>
    int i = 0;
    80005436:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005438:	013a1f63          	bne	s4,s3,80005456 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000543c:	8552                	mv	a0,s4
    8000543e:	60a6                	ld	ra,72(sp)
    80005440:	6406                	ld	s0,64(sp)
    80005442:	74e2                	ld	s1,56(sp)
    80005444:	7942                	ld	s2,48(sp)
    80005446:	79a2                	ld	s3,40(sp)
    80005448:	7a02                	ld	s4,32(sp)
    8000544a:	6ae2                	ld	s5,24(sp)
    8000544c:	6b42                	ld	s6,16(sp)
    8000544e:	6ba2                	ld	s7,8(sp)
    80005450:	6c02                	ld	s8,0(sp)
    80005452:	6161                	addi	sp,sp,80
    80005454:	8082                	ret
    ret = (i == n ? n : -1);
    80005456:	5a7d                	li	s4,-1
    80005458:	b7d5                	j	8000543c <filewrite+0xfa>
    panic("filewrite");
    8000545a:	00003517          	auipc	a0,0x3
    8000545e:	26e50513          	addi	a0,a0,622 # 800086c8 <syscalls+0x2a0>
    80005462:	ffffb097          	auipc	ra,0xffffb
    80005466:	0c8080e7          	jalr	200(ra) # 8000052a <panic>
    return -1;
    8000546a:	5a7d                	li	s4,-1
    8000546c:	bfc1                	j	8000543c <filewrite+0xfa>
      return -1;
    8000546e:	5a7d                	li	s4,-1
    80005470:	b7f1                	j	8000543c <filewrite+0xfa>
    80005472:	5a7d                	li	s4,-1
    80005474:	b7e1                	j	8000543c <filewrite+0xfa>

0000000080005476 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005476:	7179                	addi	sp,sp,-48
    80005478:	f406                	sd	ra,40(sp)
    8000547a:	f022                	sd	s0,32(sp)
    8000547c:	ec26                	sd	s1,24(sp)
    8000547e:	e84a                	sd	s2,16(sp)
    80005480:	e44e                	sd	s3,8(sp)
    80005482:	e052                	sd	s4,0(sp)
    80005484:	1800                	addi	s0,sp,48
    80005486:	84aa                	mv	s1,a0
    80005488:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000548a:	0005b023          	sd	zero,0(a1)
    8000548e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005492:	00000097          	auipc	ra,0x0
    80005496:	bf8080e7          	jalr	-1032(ra) # 8000508a <filealloc>
    8000549a:	e088                	sd	a0,0(s1)
    8000549c:	c551                	beqz	a0,80005528 <pipealloc+0xb2>
    8000549e:	00000097          	auipc	ra,0x0
    800054a2:	bec080e7          	jalr	-1044(ra) # 8000508a <filealloc>
    800054a6:	00aa3023          	sd	a0,0(s4)
    800054aa:	c92d                	beqz	a0,8000551c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800054ac:	ffffb097          	auipc	ra,0xffffb
    800054b0:	626080e7          	jalr	1574(ra) # 80000ad2 <kalloc>
    800054b4:	892a                	mv	s2,a0
    800054b6:	c125                	beqz	a0,80005516 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800054b8:	4985                	li	s3,1
    800054ba:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800054be:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800054c2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800054c6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800054ca:	00003597          	auipc	a1,0x3
    800054ce:	20e58593          	addi	a1,a1,526 # 800086d8 <syscalls+0x2b0>
    800054d2:	ffffb097          	auipc	ra,0xffffb
    800054d6:	660080e7          	jalr	1632(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800054da:	609c                	ld	a5,0(s1)
    800054dc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800054e0:	609c                	ld	a5,0(s1)
    800054e2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800054e6:	609c                	ld	a5,0(s1)
    800054e8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800054ec:	609c                	ld	a5,0(s1)
    800054ee:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800054f2:	000a3783          	ld	a5,0(s4)
    800054f6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800054fa:	000a3783          	ld	a5,0(s4)
    800054fe:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005502:	000a3783          	ld	a5,0(s4)
    80005506:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000550a:	000a3783          	ld	a5,0(s4)
    8000550e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005512:	4501                	li	a0,0
    80005514:	a025                	j	8000553c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005516:	6088                	ld	a0,0(s1)
    80005518:	e501                	bnez	a0,80005520 <pipealloc+0xaa>
    8000551a:	a039                	j	80005528 <pipealloc+0xb2>
    8000551c:	6088                	ld	a0,0(s1)
    8000551e:	c51d                	beqz	a0,8000554c <pipealloc+0xd6>
    fileclose(*f0);
    80005520:	00000097          	auipc	ra,0x0
    80005524:	c26080e7          	jalr	-986(ra) # 80005146 <fileclose>
  if(*f1)
    80005528:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000552c:	557d                	li	a0,-1
  if(*f1)
    8000552e:	c799                	beqz	a5,8000553c <pipealloc+0xc6>
    fileclose(*f1);
    80005530:	853e                	mv	a0,a5
    80005532:	00000097          	auipc	ra,0x0
    80005536:	c14080e7          	jalr	-1004(ra) # 80005146 <fileclose>
  return -1;
    8000553a:	557d                	li	a0,-1
}
    8000553c:	70a2                	ld	ra,40(sp)
    8000553e:	7402                	ld	s0,32(sp)
    80005540:	64e2                	ld	s1,24(sp)
    80005542:	6942                	ld	s2,16(sp)
    80005544:	69a2                	ld	s3,8(sp)
    80005546:	6a02                	ld	s4,0(sp)
    80005548:	6145                	addi	sp,sp,48
    8000554a:	8082                	ret
  return -1;
    8000554c:	557d                	li	a0,-1
    8000554e:	b7fd                	j	8000553c <pipealloc+0xc6>

0000000080005550 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005550:	1101                	addi	sp,sp,-32
    80005552:	ec06                	sd	ra,24(sp)
    80005554:	e822                	sd	s0,16(sp)
    80005556:	e426                	sd	s1,8(sp)
    80005558:	e04a                	sd	s2,0(sp)
    8000555a:	1000                	addi	s0,sp,32
    8000555c:	84aa                	mv	s1,a0
    8000555e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005560:	ffffb097          	auipc	ra,0xffffb
    80005564:	662080e7          	jalr	1634(ra) # 80000bc2 <acquire>
  if(writable){
    80005568:	02090d63          	beqz	s2,800055a2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000556c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005570:	21848513          	addi	a0,s1,536
    80005574:	ffffd097          	auipc	ra,0xffffd
    80005578:	16a080e7          	jalr	362(ra) # 800026de <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000557c:	2204b783          	ld	a5,544(s1)
    80005580:	eb95                	bnez	a5,800055b4 <pipeclose+0x64>
    release(&pi->lock);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffb097          	auipc	ra,0xffffb
    80005588:	704080e7          	jalr	1796(ra) # 80000c88 <release>
    kfree((char*)pi);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffb097          	auipc	ra,0xffffb
    80005592:	448080e7          	jalr	1096(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005596:	60e2                	ld	ra,24(sp)
    80005598:	6442                	ld	s0,16(sp)
    8000559a:	64a2                	ld	s1,8(sp)
    8000559c:	6902                	ld	s2,0(sp)
    8000559e:	6105                	addi	sp,sp,32
    800055a0:	8082                	ret
    pi->readopen = 0;
    800055a2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800055a6:	21c48513          	addi	a0,s1,540
    800055aa:	ffffd097          	auipc	ra,0xffffd
    800055ae:	134080e7          	jalr	308(ra) # 800026de <wakeup>
    800055b2:	b7e9                	j	8000557c <pipeclose+0x2c>
    release(&pi->lock);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffb097          	auipc	ra,0xffffb
    800055ba:	6d2080e7          	jalr	1746(ra) # 80000c88 <release>
}
    800055be:	bfe1                	j	80005596 <pipeclose+0x46>

00000000800055c0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800055c0:	711d                	addi	sp,sp,-96
    800055c2:	ec86                	sd	ra,88(sp)
    800055c4:	e8a2                	sd	s0,80(sp)
    800055c6:	e4a6                	sd	s1,72(sp)
    800055c8:	e0ca                	sd	s2,64(sp)
    800055ca:	fc4e                	sd	s3,56(sp)
    800055cc:	f852                	sd	s4,48(sp)
    800055ce:	f456                	sd	s5,40(sp)
    800055d0:	f05a                	sd	s6,32(sp)
    800055d2:	ec5e                	sd	s7,24(sp)
    800055d4:	e862                	sd	s8,16(sp)
    800055d6:	1080                	addi	s0,sp,96
    800055d8:	84aa                	mv	s1,a0
    800055da:	8aae                	mv	s5,a1
    800055dc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800055de:	ffffc097          	auipc	ra,0xffffc
    800055e2:	424080e7          	jalr	1060(ra) # 80001a02 <myproc>
    800055e6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffb097          	auipc	ra,0xffffb
    800055ee:	5d8080e7          	jalr	1496(ra) # 80000bc2 <acquire>
  while(i < n){
    800055f2:	0b405363          	blez	s4,80005698 <pipewrite+0xd8>
  int i = 0;
    800055f6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800055f8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800055fa:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800055fe:	21c48b93          	addi	s7,s1,540
    80005602:	a089                	j	80005644 <pipewrite+0x84>
      release(&pi->lock);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffb097          	auipc	ra,0xffffb
    8000560a:	682080e7          	jalr	1666(ra) # 80000c88 <release>
      return -1;
    8000560e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005610:	854a                	mv	a0,s2
    80005612:	60e6                	ld	ra,88(sp)
    80005614:	6446                	ld	s0,80(sp)
    80005616:	64a6                	ld	s1,72(sp)
    80005618:	6906                	ld	s2,64(sp)
    8000561a:	79e2                	ld	s3,56(sp)
    8000561c:	7a42                	ld	s4,48(sp)
    8000561e:	7aa2                	ld	s5,40(sp)
    80005620:	7b02                	ld	s6,32(sp)
    80005622:	6be2                	ld	s7,24(sp)
    80005624:	6c42                	ld	s8,16(sp)
    80005626:	6125                	addi	sp,sp,96
    80005628:	8082                	ret
      wakeup(&pi->nread);
    8000562a:	8562                	mv	a0,s8
    8000562c:	ffffd097          	auipc	ra,0xffffd
    80005630:	0b2080e7          	jalr	178(ra) # 800026de <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005634:	85a6                	mv	a1,s1
    80005636:	855e                	mv	a0,s7
    80005638:	ffffd097          	auipc	ra,0xffffd
    8000563c:	f1c080e7          	jalr	-228(ra) # 80002554 <sleep>
  while(i < n){
    80005640:	05495d63          	bge	s2,s4,8000569a <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005644:	2204a783          	lw	a5,544(s1)
    80005648:	dfd5                	beqz	a5,80005604 <pipewrite+0x44>
    8000564a:	01c9a783          	lw	a5,28(s3)
    8000564e:	fbdd                	bnez	a5,80005604 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005650:	2184a783          	lw	a5,536(s1)
    80005654:	21c4a703          	lw	a4,540(s1)
    80005658:	2007879b          	addiw	a5,a5,512
    8000565c:	fcf707e3          	beq	a4,a5,8000562a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005660:	4685                	li	a3,1
    80005662:	01590633          	add	a2,s2,s5
    80005666:	faf40593          	addi	a1,s0,-81
    8000566a:	1d89b503          	ld	a0,472(s3)
    8000566e:	ffffc097          	auipc	ra,0xffffc
    80005672:	080080e7          	jalr	128(ra) # 800016ee <copyin>
    80005676:	03650263          	beq	a0,s6,8000569a <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000567a:	21c4a783          	lw	a5,540(s1)
    8000567e:	0017871b          	addiw	a4,a5,1
    80005682:	20e4ae23          	sw	a4,540(s1)
    80005686:	1ff7f793          	andi	a5,a5,511
    8000568a:	97a6                	add	a5,a5,s1
    8000568c:	faf44703          	lbu	a4,-81(s0)
    80005690:	00e78c23          	sb	a4,24(a5)
      i++;
    80005694:	2905                	addiw	s2,s2,1
    80005696:	b76d                	j	80005640 <pipewrite+0x80>
  int i = 0;
    80005698:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000569a:	21848513          	addi	a0,s1,536
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	040080e7          	jalr	64(ra) # 800026de <wakeup>
  release(&pi->lock);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffb097          	auipc	ra,0xffffb
    800056ac:	5e0080e7          	jalr	1504(ra) # 80000c88 <release>
  return i;
    800056b0:	b785                	j	80005610 <pipewrite+0x50>

00000000800056b2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800056b2:	715d                	addi	sp,sp,-80
    800056b4:	e486                	sd	ra,72(sp)
    800056b6:	e0a2                	sd	s0,64(sp)
    800056b8:	fc26                	sd	s1,56(sp)
    800056ba:	f84a                	sd	s2,48(sp)
    800056bc:	f44e                	sd	s3,40(sp)
    800056be:	f052                	sd	s4,32(sp)
    800056c0:	ec56                	sd	s5,24(sp)
    800056c2:	e85a                	sd	s6,16(sp)
    800056c4:	0880                	addi	s0,sp,80
    800056c6:	84aa                	mv	s1,a0
    800056c8:	892e                	mv	s2,a1
    800056ca:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056cc:	ffffc097          	auipc	ra,0xffffc
    800056d0:	336080e7          	jalr	822(ra) # 80001a02 <myproc>
    800056d4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffb097          	auipc	ra,0xffffb
    800056dc:	4ea080e7          	jalr	1258(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056e0:	2184a703          	lw	a4,536(s1)
    800056e4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056e8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056ec:	02f71463          	bne	a4,a5,80005714 <piperead+0x62>
    800056f0:	2244a783          	lw	a5,548(s1)
    800056f4:	c385                	beqz	a5,80005714 <piperead+0x62>
    if(pr->killed){
    800056f6:	01ca2783          	lw	a5,28(s4)
    800056fa:	ebc1                	bnez	a5,8000578a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056fc:	85a6                	mv	a1,s1
    800056fe:	854e                	mv	a0,s3
    80005700:	ffffd097          	auipc	ra,0xffffd
    80005704:	e54080e7          	jalr	-428(ra) # 80002554 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005708:	2184a703          	lw	a4,536(s1)
    8000570c:	21c4a783          	lw	a5,540(s1)
    80005710:	fef700e3          	beq	a4,a5,800056f0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005714:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005716:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005718:	05505363          	blez	s5,8000575e <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000571c:	2184a783          	lw	a5,536(s1)
    80005720:	21c4a703          	lw	a4,540(s1)
    80005724:	02f70d63          	beq	a4,a5,8000575e <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005728:	0017871b          	addiw	a4,a5,1
    8000572c:	20e4ac23          	sw	a4,536(s1)
    80005730:	1ff7f793          	andi	a5,a5,511
    80005734:	97a6                	add	a5,a5,s1
    80005736:	0187c783          	lbu	a5,24(a5)
    8000573a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000573e:	4685                	li	a3,1
    80005740:	fbf40613          	addi	a2,s0,-65
    80005744:	85ca                	mv	a1,s2
    80005746:	1d8a3503          	ld	a0,472(s4)
    8000574a:	ffffc097          	auipc	ra,0xffffc
    8000574e:	f18080e7          	jalr	-232(ra) # 80001662 <copyout>
    80005752:	01650663          	beq	a0,s6,8000575e <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005756:	2985                	addiw	s3,s3,1
    80005758:	0905                	addi	s2,s2,1
    8000575a:	fd3a91e3          	bne	s5,s3,8000571c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000575e:	21c48513          	addi	a0,s1,540
    80005762:	ffffd097          	auipc	ra,0xffffd
    80005766:	f7c080e7          	jalr	-132(ra) # 800026de <wakeup>
  release(&pi->lock);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffb097          	auipc	ra,0xffffb
    80005770:	51c080e7          	jalr	1308(ra) # 80000c88 <release>
  return i;
}
    80005774:	854e                	mv	a0,s3
    80005776:	60a6                	ld	ra,72(sp)
    80005778:	6406                	ld	s0,64(sp)
    8000577a:	74e2                	ld	s1,56(sp)
    8000577c:	7942                	ld	s2,48(sp)
    8000577e:	79a2                	ld	s3,40(sp)
    80005780:	7a02                	ld	s4,32(sp)
    80005782:	6ae2                	ld	s5,24(sp)
    80005784:	6b42                	ld	s6,16(sp)
    80005786:	6161                	addi	sp,sp,80
    80005788:	8082                	ret
      release(&pi->lock);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffb097          	auipc	ra,0xffffb
    80005790:	4fc080e7          	jalr	1276(ra) # 80000c88 <release>
      return -1;
    80005794:	59fd                	li	s3,-1
    80005796:	bff9                	j	80005774 <piperead+0xc2>

0000000080005798 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005798:	dd010113          	addi	sp,sp,-560
    8000579c:	22113423          	sd	ra,552(sp)
    800057a0:	22813023          	sd	s0,544(sp)
    800057a4:	20913c23          	sd	s1,536(sp)
    800057a8:	21213823          	sd	s2,528(sp)
    800057ac:	21313423          	sd	s3,520(sp)
    800057b0:	21413023          	sd	s4,512(sp)
    800057b4:	ffd6                	sd	s5,504(sp)
    800057b6:	fbda                	sd	s6,496(sp)
    800057b8:	f7de                	sd	s7,488(sp)
    800057ba:	f3e2                	sd	s8,480(sp)
    800057bc:	efe6                	sd	s9,472(sp)
    800057be:	ebea                	sd	s10,464(sp)
    800057c0:	e7ee                	sd	s11,456(sp)
    800057c2:	1c00                	addi	s0,sp,560
    800057c4:	84aa                	mv	s1,a0
    800057c6:	dea43023          	sd	a0,-544(s0)
    800057ca:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800057ce:	ffffc097          	auipc	ra,0xffffc
    800057d2:	234080e7          	jalr	564(ra) # 80001a02 <myproc>
    800057d6:	89aa                	mv	s3,a0
  struct thread *t = mythread();
    800057d8:	ffffc097          	auipc	ra,0xffffc
    800057dc:	264080e7          	jalr	612(ra) # 80001a3c <mythread>
    800057e0:	e0a43423          	sd	a0,-504(s0)
  begin_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	496080e7          	jalr	1174(ra) # 80004c7a <begin_op>

  if((ip = namei(path)) == 0){
    800057ec:	8526                	mv	a0,s1
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	26c080e7          	jalr	620(ra) # 80004a5a <namei>
    800057f6:	c50d                	beqz	a0,80005820 <exec+0x88>
    800057f8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	aaa080e7          	jalr	-1366(ra) # 800042a4 <ilock>

  // ADDED Q3
  acquire(&p->lock); //TOOD: decide where to put this block
    80005802:	854e                	mv	a0,s3
    80005804:	ffffb097          	auipc	ra,0xffffb
    80005808:	3be080e7          	jalr	958(ra) # 80000bc2 <acquire>
   for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    8000580c:	27898493          	addi	s1,s3,632
    80005810:	6905                	lui	s2,0x1
    80005812:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    80005816:	994e                	add	s2,s2,s3
    if(t_temp->tid != t->tid){
      acquire(&t_temp->lock);
      t_temp->terminated = 1;
    80005818:	4b05                	li	s6,1
      if(t_temp->state == SLEEPING){
    8000581a:	4a09                	li	s4,2
        t_temp->state = RUNNABLE;
    8000581c:	4b8d                	li	s7,3
    8000581e:	a035                	j	8000584a <exec+0xb2>
    end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	4da080e7          	jalr	1242(ra) # 80004cfa <end_op>
    return -1;
    80005828:	557d                	li	a0,-1
    8000582a:	a849                	j	800058bc <exec+0x124>
      }
      release(&t_temp->lock);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffb097          	auipc	ra,0xffffb
    80005832:	45a080e7          	jalr	1114(ra) # 80000c88 <release>
      kthread_join(t_temp->tid, 0);
    80005836:	4581                	li	a1,0
    80005838:	5888                	lw	a0,48(s1)
    8000583a:	ffffd097          	auipc	ra,0xffffd
    8000583e:	528080e7          	jalr	1320(ra) # 80002d62 <kthread_join>
   for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    80005842:	0c048493          	addi	s1,s1,192
    80005846:	03248563          	beq	s1,s2,80005870 <exec+0xd8>
    if(t_temp->tid != t->tid){
    8000584a:	5898                	lw	a4,48(s1)
    8000584c:	e0843783          	ld	a5,-504(s0)
    80005850:	5b9c                	lw	a5,48(a5)
    80005852:	fef708e3          	beq	a4,a5,80005842 <exec+0xaa>
      acquire(&t_temp->lock);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffb097          	auipc	ra,0xffffb
    8000585c:	36a080e7          	jalr	874(ra) # 80000bc2 <acquire>
      t_temp->terminated = 1;
    80005860:	0364a423          	sw	s6,40(s1)
      if(t_temp->state == SLEEPING){
    80005864:	4c9c                	lw	a5,24(s1)
    80005866:	fd4793e3          	bne	a5,s4,8000582c <exec+0x94>
        t_temp->state = RUNNABLE;
    8000586a:	0174ac23          	sw	s7,24(s1)
    8000586e:	bf7d                	j	8000582c <exec+0x94>
    }
  }
  release(&p->lock);
    80005870:	854e                	mv	a0,s3
    80005872:	ffffb097          	auipc	ra,0xffffb
    80005876:	416080e7          	jalr	1046(ra) # 80000c88 <release>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000587a:	04000713          	li	a4,64
    8000587e:	4681                	li	a3,0
    80005880:	e4840613          	addi	a2,s0,-440
    80005884:	4581                	li	a1,0
    80005886:	8556                	mv	a0,s5
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	cd0080e7          	jalr	-816(ra) # 80004558 <readi>
    80005890:	04000793          	li	a5,64
    80005894:	00f51a63          	bne	a0,a5,800058a8 <exec+0x110>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005898:	e4842703          	lw	a4,-440(s0)
    8000589c:	464c47b7          	lui	a5,0x464c4
    800058a0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058a4:	04f70263          	beq	a4,a5,800058e8 <exec+0x150>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800058a8:	8556                	mv	a0,s5
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	c5c080e7          	jalr	-932(ra) # 80004506 <iunlockput>
    end_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	448080e7          	jalr	1096(ra) # 80004cfa <end_op>
  }
  return -1;
    800058ba:	557d                	li	a0,-1
}
    800058bc:	22813083          	ld	ra,552(sp)
    800058c0:	22013403          	ld	s0,544(sp)
    800058c4:	21813483          	ld	s1,536(sp)
    800058c8:	21013903          	ld	s2,528(sp)
    800058cc:	20813983          	ld	s3,520(sp)
    800058d0:	20013a03          	ld	s4,512(sp)
    800058d4:	7afe                	ld	s5,504(sp)
    800058d6:	7b5e                	ld	s6,496(sp)
    800058d8:	7bbe                	ld	s7,488(sp)
    800058da:	7c1e                	ld	s8,480(sp)
    800058dc:	6cfe                	ld	s9,472(sp)
    800058de:	6d5e                	ld	s10,464(sp)
    800058e0:	6dbe                	ld	s11,456(sp)
    800058e2:	23010113          	addi	sp,sp,560
    800058e6:	8082                	ret
  if((pagetable = proc_pagetable(p)) == 0)
    800058e8:	854e                	mv	a0,s3
    800058ea:	ffffc097          	auipc	ra,0xffffc
    800058ee:	25c080e7          	jalr	604(ra) # 80001b46 <proc_pagetable>
    800058f2:	8b2a                	mv	s6,a0
    800058f4:	d955                	beqz	a0,800058a8 <exec+0x110>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058f6:	e6842783          	lw	a5,-408(s0)
    800058fa:	e8045703          	lhu	a4,-384(s0)
    800058fe:	c735                	beqz	a4,8000596a <exec+0x1d2>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005900:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005902:	e0043023          	sd	zero,-512(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005906:	6a05                	lui	s4,0x1
    80005908:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000590c:	dce43c23          	sd	a4,-552(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005910:	6d85                	lui	s11,0x1
    80005912:	7d7d                	lui	s10,0xfffff
    80005914:	a485                	j	80005b74 <exec+0x3dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005916:	00003517          	auipc	a0,0x3
    8000591a:	dca50513          	addi	a0,a0,-566 # 800086e0 <syscalls+0x2b8>
    8000591e:	ffffb097          	auipc	ra,0xffffb
    80005922:	c0c080e7          	jalr	-1012(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005926:	874a                	mv	a4,s2
    80005928:	009c86bb          	addw	a3,s9,s1
    8000592c:	4581                	li	a1,0
    8000592e:	8556                	mv	a0,s5
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	c28080e7          	jalr	-984(ra) # 80004558 <readi>
    80005938:	2501                	sext.w	a0,a0
    8000593a:	1ca91d63          	bne	s2,a0,80005b14 <exec+0x37c>
  for(i = 0; i < sz; i += PGSIZE){
    8000593e:	009d84bb          	addw	s1,s11,s1
    80005942:	013d09bb          	addw	s3,s10,s3
    80005946:	2174f763          	bgeu	s1,s7,80005b54 <exec+0x3bc>
    pa = walkaddr(pagetable, va + i);
    8000594a:	02049593          	slli	a1,s1,0x20
    8000594e:	9181                	srli	a1,a1,0x20
    80005950:	95e2                	add	a1,a1,s8
    80005952:	855a                	mv	a0,s6
    80005954:	ffffb097          	auipc	ra,0xffffb
    80005958:	71c080e7          	jalr	1820(ra) # 80001070 <walkaddr>
    8000595c:	862a                	mv	a2,a0
    if(pa == 0)
    8000595e:	dd45                	beqz	a0,80005916 <exec+0x17e>
      n = PGSIZE;
    80005960:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005962:	fd49f2e3          	bgeu	s3,s4,80005926 <exec+0x18e>
      n = sz - i;
    80005966:	894e                	mv	s2,s3
    80005968:	bf7d                	j	80005926 <exec+0x18e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000596a:	4481                	li	s1,0
  iunlockput(ip);
    8000596c:	8556                	mv	a0,s5
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	b98080e7          	jalr	-1128(ra) # 80004506 <iunlockput>
  end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	384080e7          	jalr	900(ra) # 80004cfa <end_op>
  p = myproc();
    8000597e:	ffffc097          	auipc	ra,0xffffc
    80005982:	084080e7          	jalr	132(ra) # 80001a02 <myproc>
    80005986:	8a2a                	mv	s4,a0
  uint64 oldsz = p->sz;
    80005988:	1d053d03          	ld	s10,464(a0)
  sz = PGROUNDUP(sz);
    8000598c:	6785                	lui	a5,0x1
    8000598e:	17fd                	addi	a5,a5,-1
    80005990:	94be                	add	s1,s1,a5
    80005992:	77fd                	lui	a5,0xfffff
    80005994:	8fe5                	and	a5,a5,s1
    80005996:	def43823          	sd	a5,-528(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000599a:	6609                	lui	a2,0x2
    8000599c:	963e                	add	a2,a2,a5
    8000599e:	85be                	mv	a1,a5
    800059a0:	855a                	mv	a0,s6
    800059a2:	ffffc097          	auipc	ra,0xffffc
    800059a6:	a70080e7          	jalr	-1424(ra) # 80001412 <uvmalloc>
    800059aa:	8caa                	mv	s9,a0
  ip = 0;
    800059ac:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800059ae:	16050363          	beqz	a0,80005b14 <exec+0x37c>
  uvmclear(pagetable, sz-2*PGSIZE);
    800059b2:	75f9                	lui	a1,0xffffe
    800059b4:	95aa                	add	a1,a1,a0
    800059b6:	855a                	mv	a0,s6
    800059b8:	ffffc097          	auipc	ra,0xffffc
    800059bc:	c78080e7          	jalr	-904(ra) # 80001630 <uvmclear>
  stackbase = sp - PGSIZE;
    800059c0:	7bfd                	lui	s7,0xfffff
    800059c2:	9be6                	add	s7,s7,s9
  for(argc = 0; argv[argc]; argc++) {
    800059c4:	de843783          	ld	a5,-536(s0)
    800059c8:	6388                	ld	a0,0(a5)
    800059ca:	c925                	beqz	a0,80005a3a <exec+0x2a2>
    800059cc:	e8840993          	addi	s3,s0,-376
    800059d0:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    800059d4:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    800059d6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800059d8:	ffffb097          	auipc	ra,0xffffb
    800059dc:	48e080e7          	jalr	1166(ra) # 80000e66 <strlen>
    800059e0:	0015079b          	addiw	a5,a0,1
    800059e4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800059e8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800059ec:	15796863          	bltu	s2,s7,80005b3c <exec+0x3a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800059f0:	de843d83          	ld	s11,-536(s0)
    800059f4:	000dba83          	ld	s5,0(s11) # 1000 <_entry-0x7ffff000>
    800059f8:	8556                	mv	a0,s5
    800059fa:	ffffb097          	auipc	ra,0xffffb
    800059fe:	46c080e7          	jalr	1132(ra) # 80000e66 <strlen>
    80005a02:	0015069b          	addiw	a3,a0,1
    80005a06:	8656                	mv	a2,s5
    80005a08:	85ca                	mv	a1,s2
    80005a0a:	855a                	mv	a0,s6
    80005a0c:	ffffc097          	auipc	ra,0xffffc
    80005a10:	c56080e7          	jalr	-938(ra) # 80001662 <copyout>
    80005a14:	12054863          	bltz	a0,80005b44 <exec+0x3ac>
    ustack[argc] = sp;
    80005a18:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005a1c:	0485                	addi	s1,s1,1
    80005a1e:	008d8793          	addi	a5,s11,8
    80005a22:	def43423          	sd	a5,-536(s0)
    80005a26:	008db503          	ld	a0,8(s11)
    80005a2a:	c911                	beqz	a0,80005a3e <exec+0x2a6>
    if(argc >= MAXARG)
    80005a2c:	09a1                	addi	s3,s3,8
    80005a2e:	fb3c15e3          	bne	s8,s3,800059d8 <exec+0x240>
  sz = sz1;
    80005a32:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005a36:	4a81                	li	s5,0
    80005a38:	a8f1                	j	80005b14 <exec+0x37c>
  sp = sz;
    80005a3a:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005a3c:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a3e:	00349793          	slli	a5,s1,0x3
    80005a42:	f9040713          	addi	a4,s0,-112
    80005a46:	97ba                	add	a5,a5,a4
    80005a48:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffbcef8>
  sp -= (argc+1) * sizeof(uint64);
    80005a4c:	00148693          	addi	a3,s1,1
    80005a50:	068e                	slli	a3,a3,0x3
    80005a52:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a56:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a5a:	01797663          	bgeu	s2,s7,80005a66 <exec+0x2ce>
  sz = sz1;
    80005a5e:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005a62:	4a81                	li	s5,0
    80005a64:	a845                	j	80005b14 <exec+0x37c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005a66:	e8840613          	addi	a2,s0,-376
    80005a6a:	85ca                	mv	a1,s2
    80005a6c:	855a                	mv	a0,s6
    80005a6e:	ffffc097          	auipc	ra,0xffffc
    80005a72:	bf4080e7          	jalr	-1036(ra) # 80001662 <copyout>
    80005a76:	0c054b63          	bltz	a0,80005b4c <exec+0x3b4>
  t->trapframe->a1 = sp;
    80005a7a:	e0843783          	ld	a5,-504(s0)
    80005a7e:	67bc                	ld	a5,72(a5)
    80005a80:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005a84:	de043783          	ld	a5,-544(s0)
    80005a88:	0007c703          	lbu	a4,0(a5)
    80005a8c:	cf11                	beqz	a4,80005aa8 <exec+0x310>
    80005a8e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a90:	02f00693          	li	a3,47
    80005a94:	a029                	j	80005a9e <exec+0x306>
  for(last=s=path; *s; s++)
    80005a96:	0785                	addi	a5,a5,1
    80005a98:	fff7c703          	lbu	a4,-1(a5)
    80005a9c:	c711                	beqz	a4,80005aa8 <exec+0x310>
    if(*s == '/')
    80005a9e:	fed71ce3          	bne	a4,a3,80005a96 <exec+0x2fe>
      last = s+1;
    80005aa2:	def43023          	sd	a5,-544(s0)
    80005aa6:	bfc5                	j	80005a96 <exec+0x2fe>
  safestrcpy(p->name, last, sizeof(p->name));
    80005aa8:	4641                	li	a2,16
    80005aaa:	de043583          	ld	a1,-544(s0)
    80005aae:	268a0513          	addi	a0,s4,616
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	382080e7          	jalr	898(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    80005aba:	1d8a3503          	ld	a0,472(s4)
  p->pagetable = pagetable;
    80005abe:	1d6a3c23          	sd	s6,472(s4)
  p->sz = sz;
    80005ac2:	1d9a3823          	sd	s9,464(s4)
  t->trapframe->epc = elf.entry;  // initial program counter = main
    80005ac6:	e0843683          	ld	a3,-504(s0)
    80005aca:	66bc                	ld	a5,72(a3)
    80005acc:	e6043703          	ld	a4,-416(s0)
    80005ad0:	ef98                	sd	a4,24(a5)
  t->trapframe->sp = sp; // initial stack pointer
    80005ad2:	66bc                	ld	a5,72(a3)
    80005ad4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005ad8:	85ea                	mv	a1,s10
    80005ada:	ffffc097          	auipc	ra,0xffffc
    80005ade:	108080e7          	jalr	264(ra) # 80001be2 <proc_freepagetable>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005ae2:	138a0793          	addi	a5,s4,312
    80005ae6:	038a0a13          	addi	s4,s4,56
    80005aea:	863e                	mv	a2,a5
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005aec:	4685                	li	a3,1
    80005aee:	a029                	j	80005af8 <exec+0x360>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005af0:	0791                	addi	a5,a5,4
    80005af2:	0a21                	addi	s4,s4,8
    80005af4:	00ca0b63          	beq	s4,a2,80005b0a <exec+0x372>
    p->signal_handlers_masks[signum] = 0;
    80005af8:	0007a023          	sw	zero,0(a5)
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005afc:	000a3703          	ld	a4,0(s4)
    80005b00:	fed708e3          	beq	a4,a3,80005af0 <exec+0x358>
      p->signal_handlers[signum] = SIG_DFL;
    80005b04:	000a3023          	sd	zero,0(s4)
    80005b08:	b7e5                	j	80005af0 <exec+0x358>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b0a:	0004851b          	sext.w	a0,s1
    80005b0e:	b37d                	j	800058bc <exec+0x124>
    80005b10:	de943823          	sd	s1,-528(s0)
    proc_freepagetable(pagetable, sz);
    80005b14:	df043583          	ld	a1,-528(s0)
    80005b18:	855a                	mv	a0,s6
    80005b1a:	ffffc097          	auipc	ra,0xffffc
    80005b1e:	0c8080e7          	jalr	200(ra) # 80001be2 <proc_freepagetable>
  if(ip){
    80005b22:	d80a93e3          	bnez	s5,800058a8 <exec+0x110>
  return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	bb51                	j	800058bc <exec+0x124>
    80005b2a:	de943823          	sd	s1,-528(s0)
    80005b2e:	b7dd                	j	80005b14 <exec+0x37c>
    80005b30:	de943823          	sd	s1,-528(s0)
    80005b34:	b7c5                	j	80005b14 <exec+0x37c>
    80005b36:	de943823          	sd	s1,-528(s0)
    80005b3a:	bfe9                	j	80005b14 <exec+0x37c>
  sz = sz1;
    80005b3c:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005b40:	4a81                	li	s5,0
    80005b42:	bfc9                	j	80005b14 <exec+0x37c>
  sz = sz1;
    80005b44:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005b48:	4a81                	li	s5,0
    80005b4a:	b7e9                	j	80005b14 <exec+0x37c>
  sz = sz1;
    80005b4c:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005b50:	4a81                	li	s5,0
    80005b52:	b7c9                	j	80005b14 <exec+0x37c>
    sz = sz1;
    80005b54:	df043483          	ld	s1,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b58:	e0043783          	ld	a5,-512(s0)
    80005b5c:	0017869b          	addiw	a3,a5,1
    80005b60:	e0d43023          	sd	a3,-512(s0)
    80005b64:	df843783          	ld	a5,-520(s0)
    80005b68:	0387879b          	addiw	a5,a5,56
    80005b6c:	e8045703          	lhu	a4,-384(s0)
    80005b70:	dee6dee3          	bge	a3,a4,8000596c <exec+0x1d4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005b74:	2781                	sext.w	a5,a5
    80005b76:	def43c23          	sd	a5,-520(s0)
    80005b7a:	03800713          	li	a4,56
    80005b7e:	86be                	mv	a3,a5
    80005b80:	e1040613          	addi	a2,s0,-496
    80005b84:	4581                	li	a1,0
    80005b86:	8556                	mv	a0,s5
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	9d0080e7          	jalr	-1584(ra) # 80004558 <readi>
    80005b90:	03800793          	li	a5,56
    80005b94:	f6f51ee3          	bne	a0,a5,80005b10 <exec+0x378>
    if(ph.type != ELF_PROG_LOAD)
    80005b98:	e1042783          	lw	a5,-496(s0)
    80005b9c:	4705                	li	a4,1
    80005b9e:	fae79de3          	bne	a5,a4,80005b58 <exec+0x3c0>
    if(ph.memsz < ph.filesz)
    80005ba2:	e3843603          	ld	a2,-456(s0)
    80005ba6:	e3043783          	ld	a5,-464(s0)
    80005baa:	f8f660e3          	bltu	a2,a5,80005b2a <exec+0x392>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005bae:	e2043783          	ld	a5,-480(s0)
    80005bb2:	963e                	add	a2,a2,a5
    80005bb4:	f6f66ee3          	bltu	a2,a5,80005b30 <exec+0x398>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005bb8:	85a6                	mv	a1,s1
    80005bba:	855a                	mv	a0,s6
    80005bbc:	ffffc097          	auipc	ra,0xffffc
    80005bc0:	856080e7          	jalr	-1962(ra) # 80001412 <uvmalloc>
    80005bc4:	dea43823          	sd	a0,-528(s0)
    80005bc8:	d53d                	beqz	a0,80005b36 <exec+0x39e>
    if(ph.vaddr % PGSIZE != 0)
    80005bca:	e2043c03          	ld	s8,-480(s0)
    80005bce:	dd843783          	ld	a5,-552(s0)
    80005bd2:	00fc77b3          	and	a5,s8,a5
    80005bd6:	ff9d                	bnez	a5,80005b14 <exec+0x37c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005bd8:	e1842c83          	lw	s9,-488(s0)
    80005bdc:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005be0:	f60b8ae3          	beqz	s7,80005b54 <exec+0x3bc>
    80005be4:	89de                	mv	s3,s7
    80005be6:	4481                	li	s1,0
    80005be8:	b38d                	j	8000594a <exec+0x1b2>

0000000080005bea <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005bea:	7179                	addi	sp,sp,-48
    80005bec:	f406                	sd	ra,40(sp)
    80005bee:	f022                	sd	s0,32(sp)
    80005bf0:	ec26                	sd	s1,24(sp)
    80005bf2:	e84a                	sd	s2,16(sp)
    80005bf4:	1800                	addi	s0,sp,48
    80005bf6:	892e                	mv	s2,a1
    80005bf8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005bfa:	fdc40593          	addi	a1,s0,-36
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	982080e7          	jalr	-1662(ra) # 80003580 <argint>
    80005c06:	04054063          	bltz	a0,80005c46 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c0a:	fdc42703          	lw	a4,-36(s0)
    80005c0e:	47bd                	li	a5,15
    80005c10:	02e7ed63          	bltu	a5,a4,80005c4a <argfd+0x60>
    80005c14:	ffffc097          	auipc	ra,0xffffc
    80005c18:	dee080e7          	jalr	-530(ra) # 80001a02 <myproc>
    80005c1c:	fdc42703          	lw	a4,-36(s0)
    80005c20:	03c70793          	addi	a5,a4,60
    80005c24:	078e                	slli	a5,a5,0x3
    80005c26:	953e                	add	a0,a0,a5
    80005c28:	611c                	ld	a5,0(a0)
    80005c2a:	c395                	beqz	a5,80005c4e <argfd+0x64>
    return -1;
  if(pfd)
    80005c2c:	00090463          	beqz	s2,80005c34 <argfd+0x4a>
    *pfd = fd;
    80005c30:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c34:	4501                	li	a0,0
  if(pf)
    80005c36:	c091                	beqz	s1,80005c3a <argfd+0x50>
    *pf = f;
    80005c38:	e09c                	sd	a5,0(s1)
}
    80005c3a:	70a2                	ld	ra,40(sp)
    80005c3c:	7402                	ld	s0,32(sp)
    80005c3e:	64e2                	ld	s1,24(sp)
    80005c40:	6942                	ld	s2,16(sp)
    80005c42:	6145                	addi	sp,sp,48
    80005c44:	8082                	ret
    return -1;
    80005c46:	557d                	li	a0,-1
    80005c48:	bfcd                	j	80005c3a <argfd+0x50>
    return -1;
    80005c4a:	557d                	li	a0,-1
    80005c4c:	b7fd                	j	80005c3a <argfd+0x50>
    80005c4e:	557d                	li	a0,-1
    80005c50:	b7ed                	j	80005c3a <argfd+0x50>

0000000080005c52 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005c52:	1101                	addi	sp,sp,-32
    80005c54:	ec06                	sd	ra,24(sp)
    80005c56:	e822                	sd	s0,16(sp)
    80005c58:	e426                	sd	s1,8(sp)
    80005c5a:	1000                	addi	s0,sp,32
    80005c5c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005c5e:	ffffc097          	auipc	ra,0xffffc
    80005c62:	da4080e7          	jalr	-604(ra) # 80001a02 <myproc>
    80005c66:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005c68:	1e050793          	addi	a5,a0,480
    80005c6c:	4501                	li	a0,0
    80005c6e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c70:	6398                	ld	a4,0(a5)
    80005c72:	cb19                	beqz	a4,80005c88 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005c74:	2505                	addiw	a0,a0,1
    80005c76:	07a1                	addi	a5,a5,8
    80005c78:	fed51ce3          	bne	a0,a3,80005c70 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c7c:	557d                	li	a0,-1
}
    80005c7e:	60e2                	ld	ra,24(sp)
    80005c80:	6442                	ld	s0,16(sp)
    80005c82:	64a2                	ld	s1,8(sp)
    80005c84:	6105                	addi	sp,sp,32
    80005c86:	8082                	ret
      p->ofile[fd] = f;
    80005c88:	03c50793          	addi	a5,a0,60
    80005c8c:	078e                	slli	a5,a5,0x3
    80005c8e:	963e                	add	a2,a2,a5
    80005c90:	e204                	sd	s1,0(a2)
      return fd;
    80005c92:	b7f5                	j	80005c7e <fdalloc+0x2c>

0000000080005c94 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005c94:	715d                	addi	sp,sp,-80
    80005c96:	e486                	sd	ra,72(sp)
    80005c98:	e0a2                	sd	s0,64(sp)
    80005c9a:	fc26                	sd	s1,56(sp)
    80005c9c:	f84a                	sd	s2,48(sp)
    80005c9e:	f44e                	sd	s3,40(sp)
    80005ca0:	f052                	sd	s4,32(sp)
    80005ca2:	ec56                	sd	s5,24(sp)
    80005ca4:	0880                	addi	s0,sp,80
    80005ca6:	89ae                	mv	s3,a1
    80005ca8:	8ab2                	mv	s5,a2
    80005caa:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005cac:	fb040593          	addi	a1,s0,-80
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	dc8080e7          	jalr	-568(ra) # 80004a78 <nameiparent>
    80005cb8:	892a                	mv	s2,a0
    80005cba:	12050e63          	beqz	a0,80005df6 <create+0x162>
    return 0;

  ilock(dp);
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	5e6080e7          	jalr	1510(ra) # 800042a4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005cc6:	4601                	li	a2,0
    80005cc8:	fb040593          	addi	a1,s0,-80
    80005ccc:	854a                	mv	a0,s2
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	aba080e7          	jalr	-1350(ra) # 80004788 <dirlookup>
    80005cd6:	84aa                	mv	s1,a0
    80005cd8:	c921                	beqz	a0,80005d28 <create+0x94>
    iunlockput(dp);
    80005cda:	854a                	mv	a0,s2
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	82a080e7          	jalr	-2006(ra) # 80004506 <iunlockput>
    ilock(ip);
    80005ce4:	8526                	mv	a0,s1
    80005ce6:	ffffe097          	auipc	ra,0xffffe
    80005cea:	5be080e7          	jalr	1470(ra) # 800042a4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005cee:	2981                	sext.w	s3,s3
    80005cf0:	4789                	li	a5,2
    80005cf2:	02f99463          	bne	s3,a5,80005d1a <create+0x86>
    80005cf6:	0444d783          	lhu	a5,68(s1)
    80005cfa:	37f9                	addiw	a5,a5,-2
    80005cfc:	17c2                	slli	a5,a5,0x30
    80005cfe:	93c1                	srli	a5,a5,0x30
    80005d00:	4705                	li	a4,1
    80005d02:	00f76c63          	bltu	a4,a5,80005d1a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005d06:	8526                	mv	a0,s1
    80005d08:	60a6                	ld	ra,72(sp)
    80005d0a:	6406                	ld	s0,64(sp)
    80005d0c:	74e2                	ld	s1,56(sp)
    80005d0e:	7942                	ld	s2,48(sp)
    80005d10:	79a2                	ld	s3,40(sp)
    80005d12:	7a02                	ld	s4,32(sp)
    80005d14:	6ae2                	ld	s5,24(sp)
    80005d16:	6161                	addi	sp,sp,80
    80005d18:	8082                	ret
    iunlockput(ip);
    80005d1a:	8526                	mv	a0,s1
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	7ea080e7          	jalr	2026(ra) # 80004506 <iunlockput>
    return 0;
    80005d24:	4481                	li	s1,0
    80005d26:	b7c5                	j	80005d06 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005d28:	85ce                	mv	a1,s3
    80005d2a:	00092503          	lw	a0,0(s2)
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	3de080e7          	jalr	990(ra) # 8000410c <ialloc>
    80005d36:	84aa                	mv	s1,a0
    80005d38:	c521                	beqz	a0,80005d80 <create+0xec>
  ilock(ip);
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	56a080e7          	jalr	1386(ra) # 800042a4 <ilock>
  ip->major = major;
    80005d42:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005d46:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005d4a:	4a05                	li	s4,1
    80005d4c:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005d50:	8526                	mv	a0,s1
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	488080e7          	jalr	1160(ra) # 800041da <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005d5a:	2981                	sext.w	s3,s3
    80005d5c:	03498a63          	beq	s3,s4,80005d90 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d60:	40d0                	lw	a2,4(s1)
    80005d62:	fb040593          	addi	a1,s0,-80
    80005d66:	854a                	mv	a0,s2
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	c30080e7          	jalr	-976(ra) # 80004998 <dirlink>
    80005d70:	06054b63          	bltz	a0,80005de6 <create+0x152>
  iunlockput(dp);
    80005d74:	854a                	mv	a0,s2
    80005d76:	ffffe097          	auipc	ra,0xffffe
    80005d7a:	790080e7          	jalr	1936(ra) # 80004506 <iunlockput>
  return ip;
    80005d7e:	b761                	j	80005d06 <create+0x72>
    panic("create: ialloc");
    80005d80:	00003517          	auipc	a0,0x3
    80005d84:	98050513          	addi	a0,a0,-1664 # 80008700 <syscalls+0x2d8>
    80005d88:	ffffa097          	auipc	ra,0xffffa
    80005d8c:	7a2080e7          	jalr	1954(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005d90:	04a95783          	lhu	a5,74(s2)
    80005d94:	2785                	addiw	a5,a5,1
    80005d96:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005d9a:	854a                	mv	a0,s2
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	43e080e7          	jalr	1086(ra) # 800041da <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005da4:	40d0                	lw	a2,4(s1)
    80005da6:	00003597          	auipc	a1,0x3
    80005daa:	96a58593          	addi	a1,a1,-1686 # 80008710 <syscalls+0x2e8>
    80005dae:	8526                	mv	a0,s1
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	be8080e7          	jalr	-1048(ra) # 80004998 <dirlink>
    80005db8:	00054f63          	bltz	a0,80005dd6 <create+0x142>
    80005dbc:	00492603          	lw	a2,4(s2)
    80005dc0:	00003597          	auipc	a1,0x3
    80005dc4:	95858593          	addi	a1,a1,-1704 # 80008718 <syscalls+0x2f0>
    80005dc8:	8526                	mv	a0,s1
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	bce080e7          	jalr	-1074(ra) # 80004998 <dirlink>
    80005dd2:	f80557e3          	bgez	a0,80005d60 <create+0xcc>
      panic("create dots");
    80005dd6:	00003517          	auipc	a0,0x3
    80005dda:	94a50513          	addi	a0,a0,-1718 # 80008720 <syscalls+0x2f8>
    80005dde:	ffffa097          	auipc	ra,0xffffa
    80005de2:	74c080e7          	jalr	1868(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005de6:	00003517          	auipc	a0,0x3
    80005dea:	94a50513          	addi	a0,a0,-1718 # 80008730 <syscalls+0x308>
    80005dee:	ffffa097          	auipc	ra,0xffffa
    80005df2:	73c080e7          	jalr	1852(ra) # 8000052a <panic>
    return 0;
    80005df6:	84aa                	mv	s1,a0
    80005df8:	b739                	j	80005d06 <create+0x72>

0000000080005dfa <sys_dup>:
{
    80005dfa:	7179                	addi	sp,sp,-48
    80005dfc:	f406                	sd	ra,40(sp)
    80005dfe:	f022                	sd	s0,32(sp)
    80005e00:	ec26                	sd	s1,24(sp)
    80005e02:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e04:	fd840613          	addi	a2,s0,-40
    80005e08:	4581                	li	a1,0
    80005e0a:	4501                	li	a0,0
    80005e0c:	00000097          	auipc	ra,0x0
    80005e10:	dde080e7          	jalr	-546(ra) # 80005bea <argfd>
    return -1;
    80005e14:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e16:	02054363          	bltz	a0,80005e3c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e1a:	fd843503          	ld	a0,-40(s0)
    80005e1e:	00000097          	auipc	ra,0x0
    80005e22:	e34080e7          	jalr	-460(ra) # 80005c52 <fdalloc>
    80005e26:	84aa                	mv	s1,a0
    return -1;
    80005e28:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e2a:	00054963          	bltz	a0,80005e3c <sys_dup+0x42>
  filedup(f);
    80005e2e:	fd843503          	ld	a0,-40(s0)
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	2c2080e7          	jalr	706(ra) # 800050f4 <filedup>
  return fd;
    80005e3a:	87a6                	mv	a5,s1
}
    80005e3c:	853e                	mv	a0,a5
    80005e3e:	70a2                	ld	ra,40(sp)
    80005e40:	7402                	ld	s0,32(sp)
    80005e42:	64e2                	ld	s1,24(sp)
    80005e44:	6145                	addi	sp,sp,48
    80005e46:	8082                	ret

0000000080005e48 <sys_read>:
{
    80005e48:	7179                	addi	sp,sp,-48
    80005e4a:	f406                	sd	ra,40(sp)
    80005e4c:	f022                	sd	s0,32(sp)
    80005e4e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e50:	fe840613          	addi	a2,s0,-24
    80005e54:	4581                	li	a1,0
    80005e56:	4501                	li	a0,0
    80005e58:	00000097          	auipc	ra,0x0
    80005e5c:	d92080e7          	jalr	-622(ra) # 80005bea <argfd>
    return -1;
    80005e60:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e62:	04054163          	bltz	a0,80005ea4 <sys_read+0x5c>
    80005e66:	fe440593          	addi	a1,s0,-28
    80005e6a:	4509                	li	a0,2
    80005e6c:	ffffd097          	auipc	ra,0xffffd
    80005e70:	714080e7          	jalr	1812(ra) # 80003580 <argint>
    return -1;
    80005e74:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e76:	02054763          	bltz	a0,80005ea4 <sys_read+0x5c>
    80005e7a:	fd840593          	addi	a1,s0,-40
    80005e7e:	4505                	li	a0,1
    80005e80:	ffffd097          	auipc	ra,0xffffd
    80005e84:	722080e7          	jalr	1826(ra) # 800035a2 <argaddr>
    return -1;
    80005e88:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e8a:	00054d63          	bltz	a0,80005ea4 <sys_read+0x5c>
  return fileread(f, p, n);
    80005e8e:	fe442603          	lw	a2,-28(s0)
    80005e92:	fd843583          	ld	a1,-40(s0)
    80005e96:	fe843503          	ld	a0,-24(s0)
    80005e9a:	fffff097          	auipc	ra,0xfffff
    80005e9e:	3e6080e7          	jalr	998(ra) # 80005280 <fileread>
    80005ea2:	87aa                	mv	a5,a0
}
    80005ea4:	853e                	mv	a0,a5
    80005ea6:	70a2                	ld	ra,40(sp)
    80005ea8:	7402                	ld	s0,32(sp)
    80005eaa:	6145                	addi	sp,sp,48
    80005eac:	8082                	ret

0000000080005eae <sys_write>:
{
    80005eae:	7179                	addi	sp,sp,-48
    80005eb0:	f406                	sd	ra,40(sp)
    80005eb2:	f022                	sd	s0,32(sp)
    80005eb4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eb6:	fe840613          	addi	a2,s0,-24
    80005eba:	4581                	li	a1,0
    80005ebc:	4501                	li	a0,0
    80005ebe:	00000097          	auipc	ra,0x0
    80005ec2:	d2c080e7          	jalr	-724(ra) # 80005bea <argfd>
    return -1;
    80005ec6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ec8:	04054163          	bltz	a0,80005f0a <sys_write+0x5c>
    80005ecc:	fe440593          	addi	a1,s0,-28
    80005ed0:	4509                	li	a0,2
    80005ed2:	ffffd097          	auipc	ra,0xffffd
    80005ed6:	6ae080e7          	jalr	1710(ra) # 80003580 <argint>
    return -1;
    80005eda:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005edc:	02054763          	bltz	a0,80005f0a <sys_write+0x5c>
    80005ee0:	fd840593          	addi	a1,s0,-40
    80005ee4:	4505                	li	a0,1
    80005ee6:	ffffd097          	auipc	ra,0xffffd
    80005eea:	6bc080e7          	jalr	1724(ra) # 800035a2 <argaddr>
    return -1;
    80005eee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ef0:	00054d63          	bltz	a0,80005f0a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005ef4:	fe442603          	lw	a2,-28(s0)
    80005ef8:	fd843583          	ld	a1,-40(s0)
    80005efc:	fe843503          	ld	a0,-24(s0)
    80005f00:	fffff097          	auipc	ra,0xfffff
    80005f04:	442080e7          	jalr	1090(ra) # 80005342 <filewrite>
    80005f08:	87aa                	mv	a5,a0
}
    80005f0a:	853e                	mv	a0,a5
    80005f0c:	70a2                	ld	ra,40(sp)
    80005f0e:	7402                	ld	s0,32(sp)
    80005f10:	6145                	addi	sp,sp,48
    80005f12:	8082                	ret

0000000080005f14 <sys_close>:
{
    80005f14:	1101                	addi	sp,sp,-32
    80005f16:	ec06                	sd	ra,24(sp)
    80005f18:	e822                	sd	s0,16(sp)
    80005f1a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f1c:	fe040613          	addi	a2,s0,-32
    80005f20:	fec40593          	addi	a1,s0,-20
    80005f24:	4501                	li	a0,0
    80005f26:	00000097          	auipc	ra,0x0
    80005f2a:	cc4080e7          	jalr	-828(ra) # 80005bea <argfd>
    return -1;
    80005f2e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f30:	02054563          	bltz	a0,80005f5a <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005f34:	ffffc097          	auipc	ra,0xffffc
    80005f38:	ace080e7          	jalr	-1330(ra) # 80001a02 <myproc>
    80005f3c:	fec42783          	lw	a5,-20(s0)
    80005f40:	03c78793          	addi	a5,a5,60
    80005f44:	078e                	slli	a5,a5,0x3
    80005f46:	97aa                	add	a5,a5,a0
    80005f48:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005f4c:	fe043503          	ld	a0,-32(s0)
    80005f50:	fffff097          	auipc	ra,0xfffff
    80005f54:	1f6080e7          	jalr	502(ra) # 80005146 <fileclose>
  return 0;
    80005f58:	4781                	li	a5,0
}
    80005f5a:	853e                	mv	a0,a5
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	6105                	addi	sp,sp,32
    80005f62:	8082                	ret

0000000080005f64 <sys_fstat>:
{
    80005f64:	1101                	addi	sp,sp,-32
    80005f66:	ec06                	sd	ra,24(sp)
    80005f68:	e822                	sd	s0,16(sp)
    80005f6a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f6c:	fe840613          	addi	a2,s0,-24
    80005f70:	4581                	li	a1,0
    80005f72:	4501                	li	a0,0
    80005f74:	00000097          	auipc	ra,0x0
    80005f78:	c76080e7          	jalr	-906(ra) # 80005bea <argfd>
    return -1;
    80005f7c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f7e:	02054563          	bltz	a0,80005fa8 <sys_fstat+0x44>
    80005f82:	fe040593          	addi	a1,s0,-32
    80005f86:	4505                	li	a0,1
    80005f88:	ffffd097          	auipc	ra,0xffffd
    80005f8c:	61a080e7          	jalr	1562(ra) # 800035a2 <argaddr>
    return -1;
    80005f90:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f92:	00054b63          	bltz	a0,80005fa8 <sys_fstat+0x44>
  return filestat(f, st);
    80005f96:	fe043583          	ld	a1,-32(s0)
    80005f9a:	fe843503          	ld	a0,-24(s0)
    80005f9e:	fffff097          	auipc	ra,0xfffff
    80005fa2:	270080e7          	jalr	624(ra) # 8000520e <filestat>
    80005fa6:	87aa                	mv	a5,a0
}
    80005fa8:	853e                	mv	a0,a5
    80005faa:	60e2                	ld	ra,24(sp)
    80005fac:	6442                	ld	s0,16(sp)
    80005fae:	6105                	addi	sp,sp,32
    80005fb0:	8082                	ret

0000000080005fb2 <sys_link>:
{
    80005fb2:	7169                	addi	sp,sp,-304
    80005fb4:	f606                	sd	ra,296(sp)
    80005fb6:	f222                	sd	s0,288(sp)
    80005fb8:	ee26                	sd	s1,280(sp)
    80005fba:	ea4a                	sd	s2,272(sp)
    80005fbc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fbe:	08000613          	li	a2,128
    80005fc2:	ed040593          	addi	a1,s0,-304
    80005fc6:	4501                	li	a0,0
    80005fc8:	ffffd097          	auipc	ra,0xffffd
    80005fcc:	5fc080e7          	jalr	1532(ra) # 800035c4 <argstr>
    return -1;
    80005fd0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fd2:	10054e63          	bltz	a0,800060ee <sys_link+0x13c>
    80005fd6:	08000613          	li	a2,128
    80005fda:	f5040593          	addi	a1,s0,-176
    80005fde:	4505                	li	a0,1
    80005fe0:	ffffd097          	auipc	ra,0xffffd
    80005fe4:	5e4080e7          	jalr	1508(ra) # 800035c4 <argstr>
    return -1;
    80005fe8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fea:	10054263          	bltz	a0,800060ee <sys_link+0x13c>
  begin_op();
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	c8c080e7          	jalr	-884(ra) # 80004c7a <begin_op>
  if((ip = namei(old)) == 0){
    80005ff6:	ed040513          	addi	a0,s0,-304
    80005ffa:	fffff097          	auipc	ra,0xfffff
    80005ffe:	a60080e7          	jalr	-1440(ra) # 80004a5a <namei>
    80006002:	84aa                	mv	s1,a0
    80006004:	c551                	beqz	a0,80006090 <sys_link+0xde>
  ilock(ip);
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	29e080e7          	jalr	670(ra) # 800042a4 <ilock>
  if(ip->type == T_DIR){
    8000600e:	04449703          	lh	a4,68(s1)
    80006012:	4785                	li	a5,1
    80006014:	08f70463          	beq	a4,a5,8000609c <sys_link+0xea>
  ip->nlink++;
    80006018:	04a4d783          	lhu	a5,74(s1)
    8000601c:	2785                	addiw	a5,a5,1
    8000601e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	1b6080e7          	jalr	438(ra) # 800041da <iupdate>
  iunlock(ip);
    8000602c:	8526                	mv	a0,s1
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	338080e7          	jalr	824(ra) # 80004366 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006036:	fd040593          	addi	a1,s0,-48
    8000603a:	f5040513          	addi	a0,s0,-176
    8000603e:	fffff097          	auipc	ra,0xfffff
    80006042:	a3a080e7          	jalr	-1478(ra) # 80004a78 <nameiparent>
    80006046:	892a                	mv	s2,a0
    80006048:	c935                	beqz	a0,800060bc <sys_link+0x10a>
  ilock(dp);
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	25a080e7          	jalr	602(ra) # 800042a4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006052:	00092703          	lw	a4,0(s2)
    80006056:	409c                	lw	a5,0(s1)
    80006058:	04f71d63          	bne	a4,a5,800060b2 <sys_link+0x100>
    8000605c:	40d0                	lw	a2,4(s1)
    8000605e:	fd040593          	addi	a1,s0,-48
    80006062:	854a                	mv	a0,s2
    80006064:	fffff097          	auipc	ra,0xfffff
    80006068:	934080e7          	jalr	-1740(ra) # 80004998 <dirlink>
    8000606c:	04054363          	bltz	a0,800060b2 <sys_link+0x100>
  iunlockput(dp);
    80006070:	854a                	mv	a0,s2
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	494080e7          	jalr	1172(ra) # 80004506 <iunlockput>
  iput(ip);
    8000607a:	8526                	mv	a0,s1
    8000607c:	ffffe097          	auipc	ra,0xffffe
    80006080:	3e2080e7          	jalr	994(ra) # 8000445e <iput>
  end_op();
    80006084:	fffff097          	auipc	ra,0xfffff
    80006088:	c76080e7          	jalr	-906(ra) # 80004cfa <end_op>
  return 0;
    8000608c:	4781                	li	a5,0
    8000608e:	a085                	j	800060ee <sys_link+0x13c>
    end_op();
    80006090:	fffff097          	auipc	ra,0xfffff
    80006094:	c6a080e7          	jalr	-918(ra) # 80004cfa <end_op>
    return -1;
    80006098:	57fd                	li	a5,-1
    8000609a:	a891                	j	800060ee <sys_link+0x13c>
    iunlockput(ip);
    8000609c:	8526                	mv	a0,s1
    8000609e:	ffffe097          	auipc	ra,0xffffe
    800060a2:	468080e7          	jalr	1128(ra) # 80004506 <iunlockput>
    end_op();
    800060a6:	fffff097          	auipc	ra,0xfffff
    800060aa:	c54080e7          	jalr	-940(ra) # 80004cfa <end_op>
    return -1;
    800060ae:	57fd                	li	a5,-1
    800060b0:	a83d                	j	800060ee <sys_link+0x13c>
    iunlockput(dp);
    800060b2:	854a                	mv	a0,s2
    800060b4:	ffffe097          	auipc	ra,0xffffe
    800060b8:	452080e7          	jalr	1106(ra) # 80004506 <iunlockput>
  ilock(ip);
    800060bc:	8526                	mv	a0,s1
    800060be:	ffffe097          	auipc	ra,0xffffe
    800060c2:	1e6080e7          	jalr	486(ra) # 800042a4 <ilock>
  ip->nlink--;
    800060c6:	04a4d783          	lhu	a5,74(s1)
    800060ca:	37fd                	addiw	a5,a5,-1
    800060cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060d0:	8526                	mv	a0,s1
    800060d2:	ffffe097          	auipc	ra,0xffffe
    800060d6:	108080e7          	jalr	264(ra) # 800041da <iupdate>
  iunlockput(ip);
    800060da:	8526                	mv	a0,s1
    800060dc:	ffffe097          	auipc	ra,0xffffe
    800060e0:	42a080e7          	jalr	1066(ra) # 80004506 <iunlockput>
  end_op();
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	c16080e7          	jalr	-1002(ra) # 80004cfa <end_op>
  return -1;
    800060ec:	57fd                	li	a5,-1
}
    800060ee:	853e                	mv	a0,a5
    800060f0:	70b2                	ld	ra,296(sp)
    800060f2:	7412                	ld	s0,288(sp)
    800060f4:	64f2                	ld	s1,280(sp)
    800060f6:	6952                	ld	s2,272(sp)
    800060f8:	6155                	addi	sp,sp,304
    800060fa:	8082                	ret

00000000800060fc <sys_unlink>:
{
    800060fc:	7151                	addi	sp,sp,-240
    800060fe:	f586                	sd	ra,232(sp)
    80006100:	f1a2                	sd	s0,224(sp)
    80006102:	eda6                	sd	s1,216(sp)
    80006104:	e9ca                	sd	s2,208(sp)
    80006106:	e5ce                	sd	s3,200(sp)
    80006108:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000610a:	08000613          	li	a2,128
    8000610e:	f3040593          	addi	a1,s0,-208
    80006112:	4501                	li	a0,0
    80006114:	ffffd097          	auipc	ra,0xffffd
    80006118:	4b0080e7          	jalr	1200(ra) # 800035c4 <argstr>
    8000611c:	18054163          	bltz	a0,8000629e <sys_unlink+0x1a2>
  begin_op();
    80006120:	fffff097          	auipc	ra,0xfffff
    80006124:	b5a080e7          	jalr	-1190(ra) # 80004c7a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006128:	fb040593          	addi	a1,s0,-80
    8000612c:	f3040513          	addi	a0,s0,-208
    80006130:	fffff097          	auipc	ra,0xfffff
    80006134:	948080e7          	jalr	-1720(ra) # 80004a78 <nameiparent>
    80006138:	84aa                	mv	s1,a0
    8000613a:	c979                	beqz	a0,80006210 <sys_unlink+0x114>
  ilock(dp);
    8000613c:	ffffe097          	auipc	ra,0xffffe
    80006140:	168080e7          	jalr	360(ra) # 800042a4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006144:	00002597          	auipc	a1,0x2
    80006148:	5cc58593          	addi	a1,a1,1484 # 80008710 <syscalls+0x2e8>
    8000614c:	fb040513          	addi	a0,s0,-80
    80006150:	ffffe097          	auipc	ra,0xffffe
    80006154:	61e080e7          	jalr	1566(ra) # 8000476e <namecmp>
    80006158:	14050a63          	beqz	a0,800062ac <sys_unlink+0x1b0>
    8000615c:	00002597          	auipc	a1,0x2
    80006160:	5bc58593          	addi	a1,a1,1468 # 80008718 <syscalls+0x2f0>
    80006164:	fb040513          	addi	a0,s0,-80
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	606080e7          	jalr	1542(ra) # 8000476e <namecmp>
    80006170:	12050e63          	beqz	a0,800062ac <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006174:	f2c40613          	addi	a2,s0,-212
    80006178:	fb040593          	addi	a1,s0,-80
    8000617c:	8526                	mv	a0,s1
    8000617e:	ffffe097          	auipc	ra,0xffffe
    80006182:	60a080e7          	jalr	1546(ra) # 80004788 <dirlookup>
    80006186:	892a                	mv	s2,a0
    80006188:	12050263          	beqz	a0,800062ac <sys_unlink+0x1b0>
  ilock(ip);
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	118080e7          	jalr	280(ra) # 800042a4 <ilock>
  if(ip->nlink < 1)
    80006194:	04a91783          	lh	a5,74(s2)
    80006198:	08f05263          	blez	a5,8000621c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000619c:	04491703          	lh	a4,68(s2)
    800061a0:	4785                	li	a5,1
    800061a2:	08f70563          	beq	a4,a5,8000622c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800061a6:	4641                	li	a2,16
    800061a8:	4581                	li	a1,0
    800061aa:	fc040513          	addi	a0,s0,-64
    800061ae:	ffffb097          	auipc	ra,0xffffb
    800061b2:	b34080e7          	jalr	-1228(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061b6:	4741                	li	a4,16
    800061b8:	f2c42683          	lw	a3,-212(s0)
    800061bc:	fc040613          	addi	a2,s0,-64
    800061c0:	4581                	li	a1,0
    800061c2:	8526                	mv	a0,s1
    800061c4:	ffffe097          	auipc	ra,0xffffe
    800061c8:	48c080e7          	jalr	1164(ra) # 80004650 <writei>
    800061cc:	47c1                	li	a5,16
    800061ce:	0af51563          	bne	a0,a5,80006278 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800061d2:	04491703          	lh	a4,68(s2)
    800061d6:	4785                	li	a5,1
    800061d8:	0af70863          	beq	a4,a5,80006288 <sys_unlink+0x18c>
  iunlockput(dp);
    800061dc:	8526                	mv	a0,s1
    800061de:	ffffe097          	auipc	ra,0xffffe
    800061e2:	328080e7          	jalr	808(ra) # 80004506 <iunlockput>
  ip->nlink--;
    800061e6:	04a95783          	lhu	a5,74(s2)
    800061ea:	37fd                	addiw	a5,a5,-1
    800061ec:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800061f0:	854a                	mv	a0,s2
    800061f2:	ffffe097          	auipc	ra,0xffffe
    800061f6:	fe8080e7          	jalr	-24(ra) # 800041da <iupdate>
  iunlockput(ip);
    800061fa:	854a                	mv	a0,s2
    800061fc:	ffffe097          	auipc	ra,0xffffe
    80006200:	30a080e7          	jalr	778(ra) # 80004506 <iunlockput>
  end_op();
    80006204:	fffff097          	auipc	ra,0xfffff
    80006208:	af6080e7          	jalr	-1290(ra) # 80004cfa <end_op>
  return 0;
    8000620c:	4501                	li	a0,0
    8000620e:	a84d                	j	800062c0 <sys_unlink+0x1c4>
    end_op();
    80006210:	fffff097          	auipc	ra,0xfffff
    80006214:	aea080e7          	jalr	-1302(ra) # 80004cfa <end_op>
    return -1;
    80006218:	557d                	li	a0,-1
    8000621a:	a05d                	j	800062c0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000621c:	00002517          	auipc	a0,0x2
    80006220:	52450513          	addi	a0,a0,1316 # 80008740 <syscalls+0x318>
    80006224:	ffffa097          	auipc	ra,0xffffa
    80006228:	306080e7          	jalr	774(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000622c:	04c92703          	lw	a4,76(s2)
    80006230:	02000793          	li	a5,32
    80006234:	f6e7f9e3          	bgeu	a5,a4,800061a6 <sys_unlink+0xaa>
    80006238:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000623c:	4741                	li	a4,16
    8000623e:	86ce                	mv	a3,s3
    80006240:	f1840613          	addi	a2,s0,-232
    80006244:	4581                	li	a1,0
    80006246:	854a                	mv	a0,s2
    80006248:	ffffe097          	auipc	ra,0xffffe
    8000624c:	310080e7          	jalr	784(ra) # 80004558 <readi>
    80006250:	47c1                	li	a5,16
    80006252:	00f51b63          	bne	a0,a5,80006268 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006256:	f1845783          	lhu	a5,-232(s0)
    8000625a:	e7a1                	bnez	a5,800062a2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000625c:	29c1                	addiw	s3,s3,16
    8000625e:	04c92783          	lw	a5,76(s2)
    80006262:	fcf9ede3          	bltu	s3,a5,8000623c <sys_unlink+0x140>
    80006266:	b781                	j	800061a6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006268:	00002517          	auipc	a0,0x2
    8000626c:	4f050513          	addi	a0,a0,1264 # 80008758 <syscalls+0x330>
    80006270:	ffffa097          	auipc	ra,0xffffa
    80006274:	2ba080e7          	jalr	698(ra) # 8000052a <panic>
    panic("unlink: writei");
    80006278:	00002517          	auipc	a0,0x2
    8000627c:	4f850513          	addi	a0,a0,1272 # 80008770 <syscalls+0x348>
    80006280:	ffffa097          	auipc	ra,0xffffa
    80006284:	2aa080e7          	jalr	682(ra) # 8000052a <panic>
    dp->nlink--;
    80006288:	04a4d783          	lhu	a5,74(s1)
    8000628c:	37fd                	addiw	a5,a5,-1
    8000628e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006292:	8526                	mv	a0,s1
    80006294:	ffffe097          	auipc	ra,0xffffe
    80006298:	f46080e7          	jalr	-186(ra) # 800041da <iupdate>
    8000629c:	b781                	j	800061dc <sys_unlink+0xe0>
    return -1;
    8000629e:	557d                	li	a0,-1
    800062a0:	a005                	j	800062c0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800062a2:	854a                	mv	a0,s2
    800062a4:	ffffe097          	auipc	ra,0xffffe
    800062a8:	262080e7          	jalr	610(ra) # 80004506 <iunlockput>
  iunlockput(dp);
    800062ac:	8526                	mv	a0,s1
    800062ae:	ffffe097          	auipc	ra,0xffffe
    800062b2:	258080e7          	jalr	600(ra) # 80004506 <iunlockput>
  end_op();
    800062b6:	fffff097          	auipc	ra,0xfffff
    800062ba:	a44080e7          	jalr	-1468(ra) # 80004cfa <end_op>
  return -1;
    800062be:	557d                	li	a0,-1
}
    800062c0:	70ae                	ld	ra,232(sp)
    800062c2:	740e                	ld	s0,224(sp)
    800062c4:	64ee                	ld	s1,216(sp)
    800062c6:	694e                	ld	s2,208(sp)
    800062c8:	69ae                	ld	s3,200(sp)
    800062ca:	616d                	addi	sp,sp,240
    800062cc:	8082                	ret

00000000800062ce <sys_open>:

uint64
sys_open(void)
{
    800062ce:	7131                	addi	sp,sp,-192
    800062d0:	fd06                	sd	ra,184(sp)
    800062d2:	f922                	sd	s0,176(sp)
    800062d4:	f526                	sd	s1,168(sp)
    800062d6:	f14a                	sd	s2,160(sp)
    800062d8:	ed4e                	sd	s3,152(sp)
    800062da:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800062dc:	08000613          	li	a2,128
    800062e0:	f5040593          	addi	a1,s0,-176
    800062e4:	4501                	li	a0,0
    800062e6:	ffffd097          	auipc	ra,0xffffd
    800062ea:	2de080e7          	jalr	734(ra) # 800035c4 <argstr>
    return -1;
    800062ee:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800062f0:	0c054163          	bltz	a0,800063b2 <sys_open+0xe4>
    800062f4:	f4c40593          	addi	a1,s0,-180
    800062f8:	4505                	li	a0,1
    800062fa:	ffffd097          	auipc	ra,0xffffd
    800062fe:	286080e7          	jalr	646(ra) # 80003580 <argint>
    80006302:	0a054863          	bltz	a0,800063b2 <sys_open+0xe4>

  begin_op();
    80006306:	fffff097          	auipc	ra,0xfffff
    8000630a:	974080e7          	jalr	-1676(ra) # 80004c7a <begin_op>

  if(omode & O_CREATE){
    8000630e:	f4c42783          	lw	a5,-180(s0)
    80006312:	2007f793          	andi	a5,a5,512
    80006316:	cbdd                	beqz	a5,800063cc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006318:	4681                	li	a3,0
    8000631a:	4601                	li	a2,0
    8000631c:	4589                	li	a1,2
    8000631e:	f5040513          	addi	a0,s0,-176
    80006322:	00000097          	auipc	ra,0x0
    80006326:	972080e7          	jalr	-1678(ra) # 80005c94 <create>
    8000632a:	892a                	mv	s2,a0
    if(ip == 0){
    8000632c:	c959                	beqz	a0,800063c2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000632e:	04491703          	lh	a4,68(s2)
    80006332:	478d                	li	a5,3
    80006334:	00f71763          	bne	a4,a5,80006342 <sys_open+0x74>
    80006338:	04695703          	lhu	a4,70(s2)
    8000633c:	47a5                	li	a5,9
    8000633e:	0ce7ec63          	bltu	a5,a4,80006416 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006342:	fffff097          	auipc	ra,0xfffff
    80006346:	d48080e7          	jalr	-696(ra) # 8000508a <filealloc>
    8000634a:	89aa                	mv	s3,a0
    8000634c:	10050263          	beqz	a0,80006450 <sys_open+0x182>
    80006350:	00000097          	auipc	ra,0x0
    80006354:	902080e7          	jalr	-1790(ra) # 80005c52 <fdalloc>
    80006358:	84aa                	mv	s1,a0
    8000635a:	0e054663          	bltz	a0,80006446 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000635e:	04491703          	lh	a4,68(s2)
    80006362:	478d                	li	a5,3
    80006364:	0cf70463          	beq	a4,a5,8000642c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006368:	4789                	li	a5,2
    8000636a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000636e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006372:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006376:	f4c42783          	lw	a5,-180(s0)
    8000637a:	0017c713          	xori	a4,a5,1
    8000637e:	8b05                	andi	a4,a4,1
    80006380:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006384:	0037f713          	andi	a4,a5,3
    80006388:	00e03733          	snez	a4,a4
    8000638c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006390:	4007f793          	andi	a5,a5,1024
    80006394:	c791                	beqz	a5,800063a0 <sys_open+0xd2>
    80006396:	04491703          	lh	a4,68(s2)
    8000639a:	4789                	li	a5,2
    8000639c:	08f70f63          	beq	a4,a5,8000643a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800063a0:	854a                	mv	a0,s2
    800063a2:	ffffe097          	auipc	ra,0xffffe
    800063a6:	fc4080e7          	jalr	-60(ra) # 80004366 <iunlock>
  end_op();
    800063aa:	fffff097          	auipc	ra,0xfffff
    800063ae:	950080e7          	jalr	-1712(ra) # 80004cfa <end_op>

  return fd;
}
    800063b2:	8526                	mv	a0,s1
    800063b4:	70ea                	ld	ra,184(sp)
    800063b6:	744a                	ld	s0,176(sp)
    800063b8:	74aa                	ld	s1,168(sp)
    800063ba:	790a                	ld	s2,160(sp)
    800063bc:	69ea                	ld	s3,152(sp)
    800063be:	6129                	addi	sp,sp,192
    800063c0:	8082                	ret
      end_op();
    800063c2:	fffff097          	auipc	ra,0xfffff
    800063c6:	938080e7          	jalr	-1736(ra) # 80004cfa <end_op>
      return -1;
    800063ca:	b7e5                	j	800063b2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800063cc:	f5040513          	addi	a0,s0,-176
    800063d0:	ffffe097          	auipc	ra,0xffffe
    800063d4:	68a080e7          	jalr	1674(ra) # 80004a5a <namei>
    800063d8:	892a                	mv	s2,a0
    800063da:	c905                	beqz	a0,8000640a <sys_open+0x13c>
    ilock(ip);
    800063dc:	ffffe097          	auipc	ra,0xffffe
    800063e0:	ec8080e7          	jalr	-312(ra) # 800042a4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800063e4:	04491703          	lh	a4,68(s2)
    800063e8:	4785                	li	a5,1
    800063ea:	f4f712e3          	bne	a4,a5,8000632e <sys_open+0x60>
    800063ee:	f4c42783          	lw	a5,-180(s0)
    800063f2:	dba1                	beqz	a5,80006342 <sys_open+0x74>
      iunlockput(ip);
    800063f4:	854a                	mv	a0,s2
    800063f6:	ffffe097          	auipc	ra,0xffffe
    800063fa:	110080e7          	jalr	272(ra) # 80004506 <iunlockput>
      end_op();
    800063fe:	fffff097          	auipc	ra,0xfffff
    80006402:	8fc080e7          	jalr	-1796(ra) # 80004cfa <end_op>
      return -1;
    80006406:	54fd                	li	s1,-1
    80006408:	b76d                	j	800063b2 <sys_open+0xe4>
      end_op();
    8000640a:	fffff097          	auipc	ra,0xfffff
    8000640e:	8f0080e7          	jalr	-1808(ra) # 80004cfa <end_op>
      return -1;
    80006412:	54fd                	li	s1,-1
    80006414:	bf79                	j	800063b2 <sys_open+0xe4>
    iunlockput(ip);
    80006416:	854a                	mv	a0,s2
    80006418:	ffffe097          	auipc	ra,0xffffe
    8000641c:	0ee080e7          	jalr	238(ra) # 80004506 <iunlockput>
    end_op();
    80006420:	fffff097          	auipc	ra,0xfffff
    80006424:	8da080e7          	jalr	-1830(ra) # 80004cfa <end_op>
    return -1;
    80006428:	54fd                	li	s1,-1
    8000642a:	b761                	j	800063b2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000642c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006430:	04691783          	lh	a5,70(s2)
    80006434:	02f99223          	sh	a5,36(s3)
    80006438:	bf2d                	j	80006372 <sys_open+0xa4>
    itrunc(ip);
    8000643a:	854a                	mv	a0,s2
    8000643c:	ffffe097          	auipc	ra,0xffffe
    80006440:	f76080e7          	jalr	-138(ra) # 800043b2 <itrunc>
    80006444:	bfb1                	j	800063a0 <sys_open+0xd2>
      fileclose(f);
    80006446:	854e                	mv	a0,s3
    80006448:	fffff097          	auipc	ra,0xfffff
    8000644c:	cfe080e7          	jalr	-770(ra) # 80005146 <fileclose>
    iunlockput(ip);
    80006450:	854a                	mv	a0,s2
    80006452:	ffffe097          	auipc	ra,0xffffe
    80006456:	0b4080e7          	jalr	180(ra) # 80004506 <iunlockput>
    end_op();
    8000645a:	fffff097          	auipc	ra,0xfffff
    8000645e:	8a0080e7          	jalr	-1888(ra) # 80004cfa <end_op>
    return -1;
    80006462:	54fd                	li	s1,-1
    80006464:	b7b9                	j	800063b2 <sys_open+0xe4>

0000000080006466 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006466:	7175                	addi	sp,sp,-144
    80006468:	e506                	sd	ra,136(sp)
    8000646a:	e122                	sd	s0,128(sp)
    8000646c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000646e:	fffff097          	auipc	ra,0xfffff
    80006472:	80c080e7          	jalr	-2036(ra) # 80004c7a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006476:	08000613          	li	a2,128
    8000647a:	f7040593          	addi	a1,s0,-144
    8000647e:	4501                	li	a0,0
    80006480:	ffffd097          	auipc	ra,0xffffd
    80006484:	144080e7          	jalr	324(ra) # 800035c4 <argstr>
    80006488:	02054963          	bltz	a0,800064ba <sys_mkdir+0x54>
    8000648c:	4681                	li	a3,0
    8000648e:	4601                	li	a2,0
    80006490:	4585                	li	a1,1
    80006492:	f7040513          	addi	a0,s0,-144
    80006496:	fffff097          	auipc	ra,0xfffff
    8000649a:	7fe080e7          	jalr	2046(ra) # 80005c94 <create>
    8000649e:	cd11                	beqz	a0,800064ba <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064a0:	ffffe097          	auipc	ra,0xffffe
    800064a4:	066080e7          	jalr	102(ra) # 80004506 <iunlockput>
  end_op();
    800064a8:	fffff097          	auipc	ra,0xfffff
    800064ac:	852080e7          	jalr	-1966(ra) # 80004cfa <end_op>
  return 0;
    800064b0:	4501                	li	a0,0
}
    800064b2:	60aa                	ld	ra,136(sp)
    800064b4:	640a                	ld	s0,128(sp)
    800064b6:	6149                	addi	sp,sp,144
    800064b8:	8082                	ret
    end_op();
    800064ba:	fffff097          	auipc	ra,0xfffff
    800064be:	840080e7          	jalr	-1984(ra) # 80004cfa <end_op>
    return -1;
    800064c2:	557d                	li	a0,-1
    800064c4:	b7fd                	j	800064b2 <sys_mkdir+0x4c>

00000000800064c6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800064c6:	7135                	addi	sp,sp,-160
    800064c8:	ed06                	sd	ra,152(sp)
    800064ca:	e922                	sd	s0,144(sp)
    800064cc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800064ce:	ffffe097          	auipc	ra,0xffffe
    800064d2:	7ac080e7          	jalr	1964(ra) # 80004c7a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800064d6:	08000613          	li	a2,128
    800064da:	f7040593          	addi	a1,s0,-144
    800064de:	4501                	li	a0,0
    800064e0:	ffffd097          	auipc	ra,0xffffd
    800064e4:	0e4080e7          	jalr	228(ra) # 800035c4 <argstr>
    800064e8:	04054a63          	bltz	a0,8000653c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800064ec:	f6c40593          	addi	a1,s0,-148
    800064f0:	4505                	li	a0,1
    800064f2:	ffffd097          	auipc	ra,0xffffd
    800064f6:	08e080e7          	jalr	142(ra) # 80003580 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800064fa:	04054163          	bltz	a0,8000653c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800064fe:	f6840593          	addi	a1,s0,-152
    80006502:	4509                	li	a0,2
    80006504:	ffffd097          	auipc	ra,0xffffd
    80006508:	07c080e7          	jalr	124(ra) # 80003580 <argint>
     argint(1, &major) < 0 ||
    8000650c:	02054863          	bltz	a0,8000653c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006510:	f6841683          	lh	a3,-152(s0)
    80006514:	f6c41603          	lh	a2,-148(s0)
    80006518:	458d                	li	a1,3
    8000651a:	f7040513          	addi	a0,s0,-144
    8000651e:	fffff097          	auipc	ra,0xfffff
    80006522:	776080e7          	jalr	1910(ra) # 80005c94 <create>
     argint(2, &minor) < 0 ||
    80006526:	c919                	beqz	a0,8000653c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006528:	ffffe097          	auipc	ra,0xffffe
    8000652c:	fde080e7          	jalr	-34(ra) # 80004506 <iunlockput>
  end_op();
    80006530:	ffffe097          	auipc	ra,0xffffe
    80006534:	7ca080e7          	jalr	1994(ra) # 80004cfa <end_op>
  return 0;
    80006538:	4501                	li	a0,0
    8000653a:	a031                	j	80006546 <sys_mknod+0x80>
    end_op();
    8000653c:	ffffe097          	auipc	ra,0xffffe
    80006540:	7be080e7          	jalr	1982(ra) # 80004cfa <end_op>
    return -1;
    80006544:	557d                	li	a0,-1
}
    80006546:	60ea                	ld	ra,152(sp)
    80006548:	644a                	ld	s0,144(sp)
    8000654a:	610d                	addi	sp,sp,160
    8000654c:	8082                	ret

000000008000654e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000654e:	7135                	addi	sp,sp,-160
    80006550:	ed06                	sd	ra,152(sp)
    80006552:	e922                	sd	s0,144(sp)
    80006554:	e526                	sd	s1,136(sp)
    80006556:	e14a                	sd	s2,128(sp)
    80006558:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000655a:	ffffb097          	auipc	ra,0xffffb
    8000655e:	4a8080e7          	jalr	1192(ra) # 80001a02 <myproc>
    80006562:	892a                	mv	s2,a0
  
  begin_op();
    80006564:	ffffe097          	auipc	ra,0xffffe
    80006568:	716080e7          	jalr	1814(ra) # 80004c7a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000656c:	08000613          	li	a2,128
    80006570:	f6040593          	addi	a1,s0,-160
    80006574:	4501                	li	a0,0
    80006576:	ffffd097          	auipc	ra,0xffffd
    8000657a:	04e080e7          	jalr	78(ra) # 800035c4 <argstr>
    8000657e:	04054b63          	bltz	a0,800065d4 <sys_chdir+0x86>
    80006582:	f6040513          	addi	a0,s0,-160
    80006586:	ffffe097          	auipc	ra,0xffffe
    8000658a:	4d4080e7          	jalr	1236(ra) # 80004a5a <namei>
    8000658e:	84aa                	mv	s1,a0
    80006590:	c131                	beqz	a0,800065d4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006592:	ffffe097          	auipc	ra,0xffffe
    80006596:	d12080e7          	jalr	-750(ra) # 800042a4 <ilock>
  if(ip->type != T_DIR){
    8000659a:	04449703          	lh	a4,68(s1)
    8000659e:	4785                	li	a5,1
    800065a0:	04f71063          	bne	a4,a5,800065e0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800065a4:	8526                	mv	a0,s1
    800065a6:	ffffe097          	auipc	ra,0xffffe
    800065aa:	dc0080e7          	jalr	-576(ra) # 80004366 <iunlock>
  iput(p->cwd);
    800065ae:	26093503          	ld	a0,608(s2)
    800065b2:	ffffe097          	auipc	ra,0xffffe
    800065b6:	eac080e7          	jalr	-340(ra) # 8000445e <iput>
  end_op();
    800065ba:	ffffe097          	auipc	ra,0xffffe
    800065be:	740080e7          	jalr	1856(ra) # 80004cfa <end_op>
  p->cwd = ip;
    800065c2:	26993023          	sd	s1,608(s2)
  return 0;
    800065c6:	4501                	li	a0,0
}
    800065c8:	60ea                	ld	ra,152(sp)
    800065ca:	644a                	ld	s0,144(sp)
    800065cc:	64aa                	ld	s1,136(sp)
    800065ce:	690a                	ld	s2,128(sp)
    800065d0:	610d                	addi	sp,sp,160
    800065d2:	8082                	ret
    end_op();
    800065d4:	ffffe097          	auipc	ra,0xffffe
    800065d8:	726080e7          	jalr	1830(ra) # 80004cfa <end_op>
    return -1;
    800065dc:	557d                	li	a0,-1
    800065de:	b7ed                	j	800065c8 <sys_chdir+0x7a>
    iunlockput(ip);
    800065e0:	8526                	mv	a0,s1
    800065e2:	ffffe097          	auipc	ra,0xffffe
    800065e6:	f24080e7          	jalr	-220(ra) # 80004506 <iunlockput>
    end_op();
    800065ea:	ffffe097          	auipc	ra,0xffffe
    800065ee:	710080e7          	jalr	1808(ra) # 80004cfa <end_op>
    return -1;
    800065f2:	557d                	li	a0,-1
    800065f4:	bfd1                	j	800065c8 <sys_chdir+0x7a>

00000000800065f6 <sys_exec>:

uint64
sys_exec(void)
{
    800065f6:	7145                	addi	sp,sp,-464
    800065f8:	e786                	sd	ra,456(sp)
    800065fa:	e3a2                	sd	s0,448(sp)
    800065fc:	ff26                	sd	s1,440(sp)
    800065fe:	fb4a                	sd	s2,432(sp)
    80006600:	f74e                	sd	s3,424(sp)
    80006602:	f352                	sd	s4,416(sp)
    80006604:	ef56                	sd	s5,408(sp)
    80006606:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006608:	08000613          	li	a2,128
    8000660c:	f4040593          	addi	a1,s0,-192
    80006610:	4501                	li	a0,0
    80006612:	ffffd097          	auipc	ra,0xffffd
    80006616:	fb2080e7          	jalr	-78(ra) # 800035c4 <argstr>
    return -1;
    8000661a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000661c:	0c054a63          	bltz	a0,800066f0 <sys_exec+0xfa>
    80006620:	e3840593          	addi	a1,s0,-456
    80006624:	4505                	li	a0,1
    80006626:	ffffd097          	auipc	ra,0xffffd
    8000662a:	f7c080e7          	jalr	-132(ra) # 800035a2 <argaddr>
    8000662e:	0c054163          	bltz	a0,800066f0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006632:	10000613          	li	a2,256
    80006636:	4581                	li	a1,0
    80006638:	e4040513          	addi	a0,s0,-448
    8000663c:	ffffa097          	auipc	ra,0xffffa
    80006640:	6a6080e7          	jalr	1702(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006644:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006648:	89a6                	mv	s3,s1
    8000664a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000664c:	02000a13          	li	s4,32
    80006650:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006654:	00391793          	slli	a5,s2,0x3
    80006658:	e3040593          	addi	a1,s0,-464
    8000665c:	e3843503          	ld	a0,-456(s0)
    80006660:	953e                	add	a0,a0,a5
    80006662:	ffffd097          	auipc	ra,0xffffd
    80006666:	e7e080e7          	jalr	-386(ra) # 800034e0 <fetchaddr>
    8000666a:	02054a63          	bltz	a0,8000669e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000666e:	e3043783          	ld	a5,-464(s0)
    80006672:	c3b9                	beqz	a5,800066b8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006674:	ffffa097          	auipc	ra,0xffffa
    80006678:	45e080e7          	jalr	1118(ra) # 80000ad2 <kalloc>
    8000667c:	85aa                	mv	a1,a0
    8000667e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006682:	cd11                	beqz	a0,8000669e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006684:	6605                	lui	a2,0x1
    80006686:	e3043503          	ld	a0,-464(s0)
    8000668a:	ffffd097          	auipc	ra,0xffffd
    8000668e:	eac080e7          	jalr	-340(ra) # 80003536 <fetchstr>
    80006692:	00054663          	bltz	a0,8000669e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006696:	0905                	addi	s2,s2,1
    80006698:	09a1                	addi	s3,s3,8
    8000669a:	fb491be3          	bne	s2,s4,80006650 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000669e:	10048913          	addi	s2,s1,256
    800066a2:	6088                	ld	a0,0(s1)
    800066a4:	c529                	beqz	a0,800066ee <sys_exec+0xf8>
    kfree(argv[i]);
    800066a6:	ffffa097          	auipc	ra,0xffffa
    800066aa:	330080e7          	jalr	816(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066ae:	04a1                	addi	s1,s1,8
    800066b0:	ff2499e3          	bne	s1,s2,800066a2 <sys_exec+0xac>
  return -1;
    800066b4:	597d                	li	s2,-1
    800066b6:	a82d                	j	800066f0 <sys_exec+0xfa>
      argv[i] = 0;
    800066b8:	0a8e                	slli	s5,s5,0x3
    800066ba:	fc040793          	addi	a5,s0,-64
    800066be:	9abe                	add	s5,s5,a5
    800066c0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800066c4:	e4040593          	addi	a1,s0,-448
    800066c8:	f4040513          	addi	a0,s0,-192
    800066cc:	fffff097          	auipc	ra,0xfffff
    800066d0:	0cc080e7          	jalr	204(ra) # 80005798 <exec>
    800066d4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066d6:	10048993          	addi	s3,s1,256
    800066da:	6088                	ld	a0,0(s1)
    800066dc:	c911                	beqz	a0,800066f0 <sys_exec+0xfa>
    kfree(argv[i]);
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	2f8080e7          	jalr	760(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066e6:	04a1                	addi	s1,s1,8
    800066e8:	ff3499e3          	bne	s1,s3,800066da <sys_exec+0xe4>
    800066ec:	a011                	j	800066f0 <sys_exec+0xfa>
  return -1;
    800066ee:	597d                	li	s2,-1
}
    800066f0:	854a                	mv	a0,s2
    800066f2:	60be                	ld	ra,456(sp)
    800066f4:	641e                	ld	s0,448(sp)
    800066f6:	74fa                	ld	s1,440(sp)
    800066f8:	795a                	ld	s2,432(sp)
    800066fa:	79ba                	ld	s3,424(sp)
    800066fc:	7a1a                	ld	s4,416(sp)
    800066fe:	6afa                	ld	s5,408(sp)
    80006700:	6179                	addi	sp,sp,464
    80006702:	8082                	ret

0000000080006704 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006704:	7139                	addi	sp,sp,-64
    80006706:	fc06                	sd	ra,56(sp)
    80006708:	f822                	sd	s0,48(sp)
    8000670a:	f426                	sd	s1,40(sp)
    8000670c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000670e:	ffffb097          	auipc	ra,0xffffb
    80006712:	2f4080e7          	jalr	756(ra) # 80001a02 <myproc>
    80006716:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006718:	fd840593          	addi	a1,s0,-40
    8000671c:	4501                	li	a0,0
    8000671e:	ffffd097          	auipc	ra,0xffffd
    80006722:	e84080e7          	jalr	-380(ra) # 800035a2 <argaddr>
    return -1;
    80006726:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006728:	0e054463          	bltz	a0,80006810 <sys_pipe+0x10c>
  if(pipealloc(&rf, &wf) < 0)
    8000672c:	fc840593          	addi	a1,s0,-56
    80006730:	fd040513          	addi	a0,s0,-48
    80006734:	fffff097          	auipc	ra,0xfffff
    80006738:	d42080e7          	jalr	-702(ra) # 80005476 <pipealloc>
    return -1;
    8000673c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000673e:	0c054963          	bltz	a0,80006810 <sys_pipe+0x10c>
  fd0 = -1;
    80006742:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006746:	fd043503          	ld	a0,-48(s0)
    8000674a:	fffff097          	auipc	ra,0xfffff
    8000674e:	508080e7          	jalr	1288(ra) # 80005c52 <fdalloc>
    80006752:	fca42223          	sw	a0,-60(s0)
    80006756:	0a054063          	bltz	a0,800067f6 <sys_pipe+0xf2>
    8000675a:	fc843503          	ld	a0,-56(s0)
    8000675e:	fffff097          	auipc	ra,0xfffff
    80006762:	4f4080e7          	jalr	1268(ra) # 80005c52 <fdalloc>
    80006766:	fca42023          	sw	a0,-64(s0)
    8000676a:	06054c63          	bltz	a0,800067e2 <sys_pipe+0xde>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000676e:	4691                	li	a3,4
    80006770:	fc440613          	addi	a2,s0,-60
    80006774:	fd843583          	ld	a1,-40(s0)
    80006778:	1d84b503          	ld	a0,472(s1)
    8000677c:	ffffb097          	auipc	ra,0xffffb
    80006780:	ee6080e7          	jalr	-282(ra) # 80001662 <copyout>
    80006784:	02054163          	bltz	a0,800067a6 <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006788:	4691                	li	a3,4
    8000678a:	fc040613          	addi	a2,s0,-64
    8000678e:	fd843583          	ld	a1,-40(s0)
    80006792:	0591                	addi	a1,a1,4
    80006794:	1d84b503          	ld	a0,472(s1)
    80006798:	ffffb097          	auipc	ra,0xffffb
    8000679c:	eca080e7          	jalr	-310(ra) # 80001662 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800067a0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067a2:	06055763          	bgez	a0,80006810 <sys_pipe+0x10c>
    p->ofile[fd0] = 0;
    800067a6:	fc442783          	lw	a5,-60(s0)
    800067aa:	03c78793          	addi	a5,a5,60
    800067ae:	078e                	slli	a5,a5,0x3
    800067b0:	97a6                	add	a5,a5,s1
    800067b2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800067b6:	fc042503          	lw	a0,-64(s0)
    800067ba:	03c50513          	addi	a0,a0,60
    800067be:	050e                	slli	a0,a0,0x3
    800067c0:	9526                	add	a0,a0,s1
    800067c2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800067c6:	fd043503          	ld	a0,-48(s0)
    800067ca:	fffff097          	auipc	ra,0xfffff
    800067ce:	97c080e7          	jalr	-1668(ra) # 80005146 <fileclose>
    fileclose(wf);
    800067d2:	fc843503          	ld	a0,-56(s0)
    800067d6:	fffff097          	auipc	ra,0xfffff
    800067da:	970080e7          	jalr	-1680(ra) # 80005146 <fileclose>
    return -1;
    800067de:	57fd                	li	a5,-1
    800067e0:	a805                	j	80006810 <sys_pipe+0x10c>
    if(fd0 >= 0)
    800067e2:	fc442783          	lw	a5,-60(s0)
    800067e6:	0007c863          	bltz	a5,800067f6 <sys_pipe+0xf2>
      p->ofile[fd0] = 0;
    800067ea:	03c78513          	addi	a0,a5,60
    800067ee:	050e                	slli	a0,a0,0x3
    800067f0:	9526                	add	a0,a0,s1
    800067f2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800067f6:	fd043503          	ld	a0,-48(s0)
    800067fa:	fffff097          	auipc	ra,0xfffff
    800067fe:	94c080e7          	jalr	-1716(ra) # 80005146 <fileclose>
    fileclose(wf);
    80006802:	fc843503          	ld	a0,-56(s0)
    80006806:	fffff097          	auipc	ra,0xfffff
    8000680a:	940080e7          	jalr	-1728(ra) # 80005146 <fileclose>
    return -1;
    8000680e:	57fd                	li	a5,-1
}
    80006810:	853e                	mv	a0,a5
    80006812:	70e2                	ld	ra,56(sp)
    80006814:	7442                	ld	s0,48(sp)
    80006816:	74a2                	ld	s1,40(sp)
    80006818:	6121                	addi	sp,sp,64
    8000681a:	8082                	ret
    8000681c:	0000                	unimp
	...

0000000080006820 <kernelvec>:
    80006820:	7111                	addi	sp,sp,-256
    80006822:	e006                	sd	ra,0(sp)
    80006824:	e40a                	sd	sp,8(sp)
    80006826:	e80e                	sd	gp,16(sp)
    80006828:	ec12                	sd	tp,24(sp)
    8000682a:	f016                	sd	t0,32(sp)
    8000682c:	f41a                	sd	t1,40(sp)
    8000682e:	f81e                	sd	t2,48(sp)
    80006830:	fc22                	sd	s0,56(sp)
    80006832:	e0a6                	sd	s1,64(sp)
    80006834:	e4aa                	sd	a0,72(sp)
    80006836:	e8ae                	sd	a1,80(sp)
    80006838:	ecb2                	sd	a2,88(sp)
    8000683a:	f0b6                	sd	a3,96(sp)
    8000683c:	f4ba                	sd	a4,104(sp)
    8000683e:	f8be                	sd	a5,112(sp)
    80006840:	fcc2                	sd	a6,120(sp)
    80006842:	e146                	sd	a7,128(sp)
    80006844:	e54a                	sd	s2,136(sp)
    80006846:	e94e                	sd	s3,144(sp)
    80006848:	ed52                	sd	s4,152(sp)
    8000684a:	f156                	sd	s5,160(sp)
    8000684c:	f55a                	sd	s6,168(sp)
    8000684e:	f95e                	sd	s7,176(sp)
    80006850:	fd62                	sd	s8,184(sp)
    80006852:	e1e6                	sd	s9,192(sp)
    80006854:	e5ea                	sd	s10,200(sp)
    80006856:	e9ee                	sd	s11,208(sp)
    80006858:	edf2                	sd	t3,216(sp)
    8000685a:	f1f6                	sd	t4,224(sp)
    8000685c:	f5fa                	sd	t5,232(sp)
    8000685e:	f9fe                	sd	t6,240(sp)
    80006860:	b4ffc0ef          	jal	ra,800033ae <kerneltrap>
    80006864:	6082                	ld	ra,0(sp)
    80006866:	6122                	ld	sp,8(sp)
    80006868:	61c2                	ld	gp,16(sp)
    8000686a:	7282                	ld	t0,32(sp)
    8000686c:	7322                	ld	t1,40(sp)
    8000686e:	73c2                	ld	t2,48(sp)
    80006870:	7462                	ld	s0,56(sp)
    80006872:	6486                	ld	s1,64(sp)
    80006874:	6526                	ld	a0,72(sp)
    80006876:	65c6                	ld	a1,80(sp)
    80006878:	6666                	ld	a2,88(sp)
    8000687a:	7686                	ld	a3,96(sp)
    8000687c:	7726                	ld	a4,104(sp)
    8000687e:	77c6                	ld	a5,112(sp)
    80006880:	7866                	ld	a6,120(sp)
    80006882:	688a                	ld	a7,128(sp)
    80006884:	692a                	ld	s2,136(sp)
    80006886:	69ca                	ld	s3,144(sp)
    80006888:	6a6a                	ld	s4,152(sp)
    8000688a:	7a8a                	ld	s5,160(sp)
    8000688c:	7b2a                	ld	s6,168(sp)
    8000688e:	7bca                	ld	s7,176(sp)
    80006890:	7c6a                	ld	s8,184(sp)
    80006892:	6c8e                	ld	s9,192(sp)
    80006894:	6d2e                	ld	s10,200(sp)
    80006896:	6dce                	ld	s11,208(sp)
    80006898:	6e6e                	ld	t3,216(sp)
    8000689a:	7e8e                	ld	t4,224(sp)
    8000689c:	7f2e                	ld	t5,232(sp)
    8000689e:	7fce                	ld	t6,240(sp)
    800068a0:	6111                	addi	sp,sp,256
    800068a2:	10200073          	sret
    800068a6:	00000013          	nop
    800068aa:	00000013          	nop
    800068ae:	0001                	nop

00000000800068b0 <timervec>:
    800068b0:	34051573          	csrrw	a0,mscratch,a0
    800068b4:	e10c                	sd	a1,0(a0)
    800068b6:	e510                	sd	a2,8(a0)
    800068b8:	e914                	sd	a3,16(a0)
    800068ba:	6d0c                	ld	a1,24(a0)
    800068bc:	7110                	ld	a2,32(a0)
    800068be:	6194                	ld	a3,0(a1)
    800068c0:	96b2                	add	a3,a3,a2
    800068c2:	e194                	sd	a3,0(a1)
    800068c4:	4589                	li	a1,2
    800068c6:	14459073          	csrw	sip,a1
    800068ca:	6914                	ld	a3,16(a0)
    800068cc:	6510                	ld	a2,8(a0)
    800068ce:	610c                	ld	a1,0(a0)
    800068d0:	34051573          	csrrw	a0,mscratch,a0
    800068d4:	30200073          	mret
	...

00000000800068da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800068da:	1141                	addi	sp,sp,-16
    800068dc:	e422                	sd	s0,8(sp)
    800068de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800068e0:	0c0007b7          	lui	a5,0xc000
    800068e4:	4705                	li	a4,1
    800068e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800068e8:	c3d8                	sw	a4,4(a5)
}
    800068ea:	6422                	ld	s0,8(sp)
    800068ec:	0141                	addi	sp,sp,16
    800068ee:	8082                	ret

00000000800068f0 <plicinithart>:

void
plicinithart(void)
{
    800068f0:	1141                	addi	sp,sp,-16
    800068f2:	e406                	sd	ra,8(sp)
    800068f4:	e022                	sd	s0,0(sp)
    800068f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068f8:	ffffb097          	auipc	ra,0xffffb
    800068fc:	0de080e7          	jalr	222(ra) # 800019d6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006900:	0085171b          	slliw	a4,a0,0x8
    80006904:	0c0027b7          	lui	a5,0xc002
    80006908:	97ba                	add	a5,a5,a4
    8000690a:	40200713          	li	a4,1026
    8000690e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006912:	00d5151b          	slliw	a0,a0,0xd
    80006916:	0c2017b7          	lui	a5,0xc201
    8000691a:	953e                	add	a0,a0,a5
    8000691c:	00052023          	sw	zero,0(a0)
}
    80006920:	60a2                	ld	ra,8(sp)
    80006922:	6402                	ld	s0,0(sp)
    80006924:	0141                	addi	sp,sp,16
    80006926:	8082                	ret

0000000080006928 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006928:	1141                	addi	sp,sp,-16
    8000692a:	e406                	sd	ra,8(sp)
    8000692c:	e022                	sd	s0,0(sp)
    8000692e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006930:	ffffb097          	auipc	ra,0xffffb
    80006934:	0a6080e7          	jalr	166(ra) # 800019d6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006938:	00d5179b          	slliw	a5,a0,0xd
    8000693c:	0c201537          	lui	a0,0xc201
    80006940:	953e                	add	a0,a0,a5
  return irq;
}
    80006942:	4148                	lw	a0,4(a0)
    80006944:	60a2                	ld	ra,8(sp)
    80006946:	6402                	ld	s0,0(sp)
    80006948:	0141                	addi	sp,sp,16
    8000694a:	8082                	ret

000000008000694c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000694c:	1101                	addi	sp,sp,-32
    8000694e:	ec06                	sd	ra,24(sp)
    80006950:	e822                	sd	s0,16(sp)
    80006952:	e426                	sd	s1,8(sp)
    80006954:	1000                	addi	s0,sp,32
    80006956:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006958:	ffffb097          	auipc	ra,0xffffb
    8000695c:	07e080e7          	jalr	126(ra) # 800019d6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006960:	00d5151b          	slliw	a0,a0,0xd
    80006964:	0c2017b7          	lui	a5,0xc201
    80006968:	97aa                	add	a5,a5,a0
    8000696a:	c3c4                	sw	s1,4(a5)
}
    8000696c:	60e2                	ld	ra,24(sp)
    8000696e:	6442                	ld	s0,16(sp)
    80006970:	64a2                	ld	s1,8(sp)
    80006972:	6105                	addi	sp,sp,32
    80006974:	8082                	ret

0000000080006976 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006976:	1141                	addi	sp,sp,-16
    80006978:	e406                	sd	ra,8(sp)
    8000697a:	e022                	sd	s0,0(sp)
    8000697c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000697e:	479d                	li	a5,7
    80006980:	06a7c963          	blt	a5,a0,800069f2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006984:	00038797          	auipc	a5,0x38
    80006988:	67c78793          	addi	a5,a5,1660 # 8003f000 <disk>
    8000698c:	00a78733          	add	a4,a5,a0
    80006990:	6789                	lui	a5,0x2
    80006992:	97ba                	add	a5,a5,a4
    80006994:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006998:	e7ad                	bnez	a5,80006a02 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000699a:	00451793          	slli	a5,a0,0x4
    8000699e:	0003a717          	auipc	a4,0x3a
    800069a2:	66270713          	addi	a4,a4,1634 # 80041000 <disk+0x2000>
    800069a6:	6314                	ld	a3,0(a4)
    800069a8:	96be                	add	a3,a3,a5
    800069aa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800069ae:	6314                	ld	a3,0(a4)
    800069b0:	96be                	add	a3,a3,a5
    800069b2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800069b6:	6314                	ld	a3,0(a4)
    800069b8:	96be                	add	a3,a3,a5
    800069ba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800069be:	6318                	ld	a4,0(a4)
    800069c0:	97ba                	add	a5,a5,a4
    800069c2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800069c6:	00038797          	auipc	a5,0x38
    800069ca:	63a78793          	addi	a5,a5,1594 # 8003f000 <disk>
    800069ce:	97aa                	add	a5,a5,a0
    800069d0:	6509                	lui	a0,0x2
    800069d2:	953e                	add	a0,a0,a5
    800069d4:	4785                	li	a5,1
    800069d6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800069da:	0003a517          	auipc	a0,0x3a
    800069de:	63e50513          	addi	a0,a0,1598 # 80041018 <disk+0x2018>
    800069e2:	ffffc097          	auipc	ra,0xffffc
    800069e6:	cfc080e7          	jalr	-772(ra) # 800026de <wakeup>
}
    800069ea:	60a2                	ld	ra,8(sp)
    800069ec:	6402                	ld	s0,0(sp)
    800069ee:	0141                	addi	sp,sp,16
    800069f0:	8082                	ret
    panic("free_desc 1");
    800069f2:	00002517          	auipc	a0,0x2
    800069f6:	d8e50513          	addi	a0,a0,-626 # 80008780 <syscalls+0x358>
    800069fa:	ffffa097          	auipc	ra,0xffffa
    800069fe:	b30080e7          	jalr	-1232(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006a02:	00002517          	auipc	a0,0x2
    80006a06:	d8e50513          	addi	a0,a0,-626 # 80008790 <syscalls+0x368>
    80006a0a:	ffffa097          	auipc	ra,0xffffa
    80006a0e:	b20080e7          	jalr	-1248(ra) # 8000052a <panic>

0000000080006a12 <virtio_disk_init>:
{
    80006a12:	1101                	addi	sp,sp,-32
    80006a14:	ec06                	sd	ra,24(sp)
    80006a16:	e822                	sd	s0,16(sp)
    80006a18:	e426                	sd	s1,8(sp)
    80006a1a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a1c:	00002597          	auipc	a1,0x2
    80006a20:	d8458593          	addi	a1,a1,-636 # 800087a0 <syscalls+0x378>
    80006a24:	0003a517          	auipc	a0,0x3a
    80006a28:	70450513          	addi	a0,a0,1796 # 80041128 <disk+0x2128>
    80006a2c:	ffffa097          	auipc	ra,0xffffa
    80006a30:	106080e7          	jalr	262(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a34:	100017b7          	lui	a5,0x10001
    80006a38:	4398                	lw	a4,0(a5)
    80006a3a:	2701                	sext.w	a4,a4
    80006a3c:	747277b7          	lui	a5,0x74727
    80006a40:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a44:	0ef71163          	bne	a4,a5,80006b26 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006a48:	100017b7          	lui	a5,0x10001
    80006a4c:	43dc                	lw	a5,4(a5)
    80006a4e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a50:	4705                	li	a4,1
    80006a52:	0ce79a63          	bne	a5,a4,80006b26 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a56:	100017b7          	lui	a5,0x10001
    80006a5a:	479c                	lw	a5,8(a5)
    80006a5c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006a5e:	4709                	li	a4,2
    80006a60:	0ce79363          	bne	a5,a4,80006b26 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a64:	100017b7          	lui	a5,0x10001
    80006a68:	47d8                	lw	a4,12(a5)
    80006a6a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a6c:	554d47b7          	lui	a5,0x554d4
    80006a70:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a74:	0af71963          	bne	a4,a5,80006b26 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a78:	100017b7          	lui	a5,0x10001
    80006a7c:	4705                	li	a4,1
    80006a7e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a80:	470d                	li	a4,3
    80006a82:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a84:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006a86:	c7ffe737          	lui	a4,0xc7ffe
    80006a8a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fbc75f>
    80006a8e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a90:	2701                	sext.w	a4,a4
    80006a92:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a94:	472d                	li	a4,11
    80006a96:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a98:	473d                	li	a4,15
    80006a9a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006a9c:	6705                	lui	a4,0x1
    80006a9e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006aa0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006aa4:	5bdc                	lw	a5,52(a5)
    80006aa6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006aa8:	c7d9                	beqz	a5,80006b36 <virtio_disk_init+0x124>
  if(max < NUM)
    80006aaa:	471d                	li	a4,7
    80006aac:	08f77d63          	bgeu	a4,a5,80006b46 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006ab0:	100014b7          	lui	s1,0x10001
    80006ab4:	47a1                	li	a5,8
    80006ab6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006ab8:	6609                	lui	a2,0x2
    80006aba:	4581                	li	a1,0
    80006abc:	00038517          	auipc	a0,0x38
    80006ac0:	54450513          	addi	a0,a0,1348 # 8003f000 <disk>
    80006ac4:	ffffa097          	auipc	ra,0xffffa
    80006ac8:	21e080e7          	jalr	542(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006acc:	00038717          	auipc	a4,0x38
    80006ad0:	53470713          	addi	a4,a4,1332 # 8003f000 <disk>
    80006ad4:	00c75793          	srli	a5,a4,0xc
    80006ad8:	2781                	sext.w	a5,a5
    80006ada:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006adc:	0003a797          	auipc	a5,0x3a
    80006ae0:	52478793          	addi	a5,a5,1316 # 80041000 <disk+0x2000>
    80006ae4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006ae6:	00038717          	auipc	a4,0x38
    80006aea:	59a70713          	addi	a4,a4,1434 # 8003f080 <disk+0x80>
    80006aee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006af0:	00039717          	auipc	a4,0x39
    80006af4:	51070713          	addi	a4,a4,1296 # 80040000 <disk+0x1000>
    80006af8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006afa:	4705                	li	a4,1
    80006afc:	00e78c23          	sb	a4,24(a5)
    80006b00:	00e78ca3          	sb	a4,25(a5)
    80006b04:	00e78d23          	sb	a4,26(a5)
    80006b08:	00e78da3          	sb	a4,27(a5)
    80006b0c:	00e78e23          	sb	a4,28(a5)
    80006b10:	00e78ea3          	sb	a4,29(a5)
    80006b14:	00e78f23          	sb	a4,30(a5)
    80006b18:	00e78fa3          	sb	a4,31(a5)
}
    80006b1c:	60e2                	ld	ra,24(sp)
    80006b1e:	6442                	ld	s0,16(sp)
    80006b20:	64a2                	ld	s1,8(sp)
    80006b22:	6105                	addi	sp,sp,32
    80006b24:	8082                	ret
    panic("could not find virtio disk");
    80006b26:	00002517          	auipc	a0,0x2
    80006b2a:	c8a50513          	addi	a0,a0,-886 # 800087b0 <syscalls+0x388>
    80006b2e:	ffffa097          	auipc	ra,0xffffa
    80006b32:	9fc080e7          	jalr	-1540(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006b36:	00002517          	auipc	a0,0x2
    80006b3a:	c9a50513          	addi	a0,a0,-870 # 800087d0 <syscalls+0x3a8>
    80006b3e:	ffffa097          	auipc	ra,0xffffa
    80006b42:	9ec080e7          	jalr	-1556(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006b46:	00002517          	auipc	a0,0x2
    80006b4a:	caa50513          	addi	a0,a0,-854 # 800087f0 <syscalls+0x3c8>
    80006b4e:	ffffa097          	auipc	ra,0xffffa
    80006b52:	9dc080e7          	jalr	-1572(ra) # 8000052a <panic>

0000000080006b56 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006b56:	7119                	addi	sp,sp,-128
    80006b58:	fc86                	sd	ra,120(sp)
    80006b5a:	f8a2                	sd	s0,112(sp)
    80006b5c:	f4a6                	sd	s1,104(sp)
    80006b5e:	f0ca                	sd	s2,96(sp)
    80006b60:	ecce                	sd	s3,88(sp)
    80006b62:	e8d2                	sd	s4,80(sp)
    80006b64:	e4d6                	sd	s5,72(sp)
    80006b66:	e0da                	sd	s6,64(sp)
    80006b68:	fc5e                	sd	s7,56(sp)
    80006b6a:	f862                	sd	s8,48(sp)
    80006b6c:	f466                	sd	s9,40(sp)
    80006b6e:	f06a                	sd	s10,32(sp)
    80006b70:	ec6e                	sd	s11,24(sp)
    80006b72:	0100                	addi	s0,sp,128
    80006b74:	8aaa                	mv	s5,a0
    80006b76:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b78:	00c52c83          	lw	s9,12(a0)
    80006b7c:	001c9c9b          	slliw	s9,s9,0x1
    80006b80:	1c82                	slli	s9,s9,0x20
    80006b82:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006b86:	0003a517          	auipc	a0,0x3a
    80006b8a:	5a250513          	addi	a0,a0,1442 # 80041128 <disk+0x2128>
    80006b8e:	ffffa097          	auipc	ra,0xffffa
    80006b92:	034080e7          	jalr	52(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006b96:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b98:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006b9a:	00038c17          	auipc	s8,0x38
    80006b9e:	466c0c13          	addi	s8,s8,1126 # 8003f000 <disk>
    80006ba2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006ba4:	4b0d                	li	s6,3
    80006ba6:	a0ad                	j	80006c10 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006ba8:	00fc0733          	add	a4,s8,a5
    80006bac:	975e                	add	a4,a4,s7
    80006bae:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006bb2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006bb4:	0207c563          	bltz	a5,80006bde <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006bb8:	2905                	addiw	s2,s2,1
    80006bba:	0611                	addi	a2,a2,4
    80006bbc:	19690d63          	beq	s2,s6,80006d56 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006bc0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006bc2:	0003a717          	auipc	a4,0x3a
    80006bc6:	45670713          	addi	a4,a4,1110 # 80041018 <disk+0x2018>
    80006bca:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006bcc:	00074683          	lbu	a3,0(a4)
    80006bd0:	fee1                	bnez	a3,80006ba8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006bd2:	2785                	addiw	a5,a5,1
    80006bd4:	0705                	addi	a4,a4,1
    80006bd6:	fe979be3          	bne	a5,s1,80006bcc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006bda:	57fd                	li	a5,-1
    80006bdc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006bde:	01205d63          	blez	s2,80006bf8 <virtio_disk_rw+0xa2>
    80006be2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006be4:	000a2503          	lw	a0,0(s4)
    80006be8:	00000097          	auipc	ra,0x0
    80006bec:	d8e080e7          	jalr	-626(ra) # 80006976 <free_desc>
      for(int j = 0; j < i; j++)
    80006bf0:	2d85                	addiw	s11,s11,1
    80006bf2:	0a11                	addi	s4,s4,4
    80006bf4:	ffb918e3          	bne	s2,s11,80006be4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006bf8:	0003a597          	auipc	a1,0x3a
    80006bfc:	53058593          	addi	a1,a1,1328 # 80041128 <disk+0x2128>
    80006c00:	0003a517          	auipc	a0,0x3a
    80006c04:	41850513          	addi	a0,a0,1048 # 80041018 <disk+0x2018>
    80006c08:	ffffc097          	auipc	ra,0xffffc
    80006c0c:	94c080e7          	jalr	-1716(ra) # 80002554 <sleep>
  for(int i = 0; i < 3; i++){
    80006c10:	f8040a13          	addi	s4,s0,-128
{
    80006c14:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006c16:	894e                	mv	s2,s3
    80006c18:	b765                	j	80006bc0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006c1a:	0003a697          	auipc	a3,0x3a
    80006c1e:	3e66b683          	ld	a3,998(a3) # 80041000 <disk+0x2000>
    80006c22:	96ba                	add	a3,a3,a4
    80006c24:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c28:	00038817          	auipc	a6,0x38
    80006c2c:	3d880813          	addi	a6,a6,984 # 8003f000 <disk>
    80006c30:	0003a697          	auipc	a3,0x3a
    80006c34:	3d068693          	addi	a3,a3,976 # 80041000 <disk+0x2000>
    80006c38:	6290                	ld	a2,0(a3)
    80006c3a:	963a                	add	a2,a2,a4
    80006c3c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006c40:	0015e593          	ori	a1,a1,1
    80006c44:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006c48:	f8842603          	lw	a2,-120(s0)
    80006c4c:	628c                	ld	a1,0(a3)
    80006c4e:	972e                	add	a4,a4,a1
    80006c50:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c54:	20050593          	addi	a1,a0,512
    80006c58:	0592                	slli	a1,a1,0x4
    80006c5a:	95c2                	add	a1,a1,a6
    80006c5c:	577d                	li	a4,-1
    80006c5e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c62:	00461713          	slli	a4,a2,0x4
    80006c66:	6290                	ld	a2,0(a3)
    80006c68:	963a                	add	a2,a2,a4
    80006c6a:	03078793          	addi	a5,a5,48
    80006c6e:	97c2                	add	a5,a5,a6
    80006c70:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006c72:	629c                	ld	a5,0(a3)
    80006c74:	97ba                	add	a5,a5,a4
    80006c76:	4605                	li	a2,1
    80006c78:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c7a:	629c                	ld	a5,0(a3)
    80006c7c:	97ba                	add	a5,a5,a4
    80006c7e:	4809                	li	a6,2
    80006c80:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006c84:	629c                	ld	a5,0(a3)
    80006c86:	973e                	add	a4,a4,a5
    80006c88:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c8c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006c90:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c94:	6698                	ld	a4,8(a3)
    80006c96:	00275783          	lhu	a5,2(a4)
    80006c9a:	8b9d                	andi	a5,a5,7
    80006c9c:	0786                	slli	a5,a5,0x1
    80006c9e:	97ba                	add	a5,a5,a4
    80006ca0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006ca4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006ca8:	6698                	ld	a4,8(a3)
    80006caa:	00275783          	lhu	a5,2(a4)
    80006cae:	2785                	addiw	a5,a5,1
    80006cb0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006cb4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006cb8:	100017b7          	lui	a5,0x10001
    80006cbc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cc0:	004aa783          	lw	a5,4(s5)
    80006cc4:	02c79163          	bne	a5,a2,80006ce6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006cc8:	0003a917          	auipc	s2,0x3a
    80006ccc:	46090913          	addi	s2,s2,1120 # 80041128 <disk+0x2128>
  while(b->disk == 1) {
    80006cd0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006cd2:	85ca                	mv	a1,s2
    80006cd4:	8556                	mv	a0,s5
    80006cd6:	ffffc097          	auipc	ra,0xffffc
    80006cda:	87e080e7          	jalr	-1922(ra) # 80002554 <sleep>
  while(b->disk == 1) {
    80006cde:	004aa783          	lw	a5,4(s5)
    80006ce2:	fe9788e3          	beq	a5,s1,80006cd2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006ce6:	f8042903          	lw	s2,-128(s0)
    80006cea:	20090793          	addi	a5,s2,512
    80006cee:	00479713          	slli	a4,a5,0x4
    80006cf2:	00038797          	auipc	a5,0x38
    80006cf6:	30e78793          	addi	a5,a5,782 # 8003f000 <disk>
    80006cfa:	97ba                	add	a5,a5,a4
    80006cfc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006d00:	0003a997          	auipc	s3,0x3a
    80006d04:	30098993          	addi	s3,s3,768 # 80041000 <disk+0x2000>
    80006d08:	00491713          	slli	a4,s2,0x4
    80006d0c:	0009b783          	ld	a5,0(s3)
    80006d10:	97ba                	add	a5,a5,a4
    80006d12:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d16:	854a                	mv	a0,s2
    80006d18:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d1c:	00000097          	auipc	ra,0x0
    80006d20:	c5a080e7          	jalr	-934(ra) # 80006976 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d24:	8885                	andi	s1,s1,1
    80006d26:	f0ed                	bnez	s1,80006d08 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d28:	0003a517          	auipc	a0,0x3a
    80006d2c:	40050513          	addi	a0,a0,1024 # 80041128 <disk+0x2128>
    80006d30:	ffffa097          	auipc	ra,0xffffa
    80006d34:	f58080e7          	jalr	-168(ra) # 80000c88 <release>
}
    80006d38:	70e6                	ld	ra,120(sp)
    80006d3a:	7446                	ld	s0,112(sp)
    80006d3c:	74a6                	ld	s1,104(sp)
    80006d3e:	7906                	ld	s2,96(sp)
    80006d40:	69e6                	ld	s3,88(sp)
    80006d42:	6a46                	ld	s4,80(sp)
    80006d44:	6aa6                	ld	s5,72(sp)
    80006d46:	6b06                	ld	s6,64(sp)
    80006d48:	7be2                	ld	s7,56(sp)
    80006d4a:	7c42                	ld	s8,48(sp)
    80006d4c:	7ca2                	ld	s9,40(sp)
    80006d4e:	7d02                	ld	s10,32(sp)
    80006d50:	6de2                	ld	s11,24(sp)
    80006d52:	6109                	addi	sp,sp,128
    80006d54:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d56:	f8042503          	lw	a0,-128(s0)
    80006d5a:	20050793          	addi	a5,a0,512
    80006d5e:	0792                	slli	a5,a5,0x4
  if(write)
    80006d60:	00038817          	auipc	a6,0x38
    80006d64:	2a080813          	addi	a6,a6,672 # 8003f000 <disk>
    80006d68:	00f80733          	add	a4,a6,a5
    80006d6c:	01a036b3          	snez	a3,s10
    80006d70:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006d74:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006d78:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006d7c:	7679                	lui	a2,0xffffe
    80006d7e:	963e                	add	a2,a2,a5
    80006d80:	0003a697          	auipc	a3,0x3a
    80006d84:	28068693          	addi	a3,a3,640 # 80041000 <disk+0x2000>
    80006d88:	6298                	ld	a4,0(a3)
    80006d8a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d8c:	0a878593          	addi	a1,a5,168
    80006d90:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006d92:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006d94:	6298                	ld	a4,0(a3)
    80006d96:	9732                	add	a4,a4,a2
    80006d98:	45c1                	li	a1,16
    80006d9a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006d9c:	6298                	ld	a4,0(a3)
    80006d9e:	9732                	add	a4,a4,a2
    80006da0:	4585                	li	a1,1
    80006da2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006da6:	f8442703          	lw	a4,-124(s0)
    80006daa:	628c                	ld	a1,0(a3)
    80006dac:	962e                	add	a2,a2,a1
    80006dae:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffbc00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006db2:	0712                	slli	a4,a4,0x4
    80006db4:	6290                	ld	a2,0(a3)
    80006db6:	963a                	add	a2,a2,a4
    80006db8:	058a8593          	addi	a1,s5,88
    80006dbc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006dbe:	6294                	ld	a3,0(a3)
    80006dc0:	96ba                	add	a3,a3,a4
    80006dc2:	40000613          	li	a2,1024
    80006dc6:	c690                	sw	a2,8(a3)
  if(write)
    80006dc8:	e40d19e3          	bnez	s10,80006c1a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006dcc:	0003a697          	auipc	a3,0x3a
    80006dd0:	2346b683          	ld	a3,564(a3) # 80041000 <disk+0x2000>
    80006dd4:	96ba                	add	a3,a3,a4
    80006dd6:	4609                	li	a2,2
    80006dd8:	00c69623          	sh	a2,12(a3)
    80006ddc:	b5b1                	j	80006c28 <virtio_disk_rw+0xd2>

0000000080006dde <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006dde:	1101                	addi	sp,sp,-32
    80006de0:	ec06                	sd	ra,24(sp)
    80006de2:	e822                	sd	s0,16(sp)
    80006de4:	e426                	sd	s1,8(sp)
    80006de6:	e04a                	sd	s2,0(sp)
    80006de8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006dea:	0003a517          	auipc	a0,0x3a
    80006dee:	33e50513          	addi	a0,a0,830 # 80041128 <disk+0x2128>
    80006df2:	ffffa097          	auipc	ra,0xffffa
    80006df6:	dd0080e7          	jalr	-560(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006dfa:	10001737          	lui	a4,0x10001
    80006dfe:	533c                	lw	a5,96(a4)
    80006e00:	8b8d                	andi	a5,a5,3
    80006e02:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006e04:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006e08:	0003a797          	auipc	a5,0x3a
    80006e0c:	1f878793          	addi	a5,a5,504 # 80041000 <disk+0x2000>
    80006e10:	6b94                	ld	a3,16(a5)
    80006e12:	0207d703          	lhu	a4,32(a5)
    80006e16:	0026d783          	lhu	a5,2(a3)
    80006e1a:	06f70163          	beq	a4,a5,80006e7c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e1e:	00038917          	auipc	s2,0x38
    80006e22:	1e290913          	addi	s2,s2,482 # 8003f000 <disk>
    80006e26:	0003a497          	auipc	s1,0x3a
    80006e2a:	1da48493          	addi	s1,s1,474 # 80041000 <disk+0x2000>
    __sync_synchronize();
    80006e2e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e32:	6898                	ld	a4,16(s1)
    80006e34:	0204d783          	lhu	a5,32(s1)
    80006e38:	8b9d                	andi	a5,a5,7
    80006e3a:	078e                	slli	a5,a5,0x3
    80006e3c:	97ba                	add	a5,a5,a4
    80006e3e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006e40:	20078713          	addi	a4,a5,512
    80006e44:	0712                	slli	a4,a4,0x4
    80006e46:	974a                	add	a4,a4,s2
    80006e48:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006e4c:	e731                	bnez	a4,80006e98 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e4e:	20078793          	addi	a5,a5,512
    80006e52:	0792                	slli	a5,a5,0x4
    80006e54:	97ca                	add	a5,a5,s2
    80006e56:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006e58:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e5c:	ffffc097          	auipc	ra,0xffffc
    80006e60:	882080e7          	jalr	-1918(ra) # 800026de <wakeup>

    disk.used_idx += 1;
    80006e64:	0204d783          	lhu	a5,32(s1)
    80006e68:	2785                	addiw	a5,a5,1
    80006e6a:	17c2                	slli	a5,a5,0x30
    80006e6c:	93c1                	srli	a5,a5,0x30
    80006e6e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e72:	6898                	ld	a4,16(s1)
    80006e74:	00275703          	lhu	a4,2(a4)
    80006e78:	faf71be3          	bne	a4,a5,80006e2e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006e7c:	0003a517          	auipc	a0,0x3a
    80006e80:	2ac50513          	addi	a0,a0,684 # 80041128 <disk+0x2128>
    80006e84:	ffffa097          	auipc	ra,0xffffa
    80006e88:	e04080e7          	jalr	-508(ra) # 80000c88 <release>
}
    80006e8c:	60e2                	ld	ra,24(sp)
    80006e8e:	6442                	ld	s0,16(sp)
    80006e90:	64a2                	ld	s1,8(sp)
    80006e92:	6902                	ld	s2,0(sp)
    80006e94:	6105                	addi	sp,sp,32
    80006e96:	8082                	ret
      panic("virtio_disk_intr status");
    80006e98:	00002517          	auipc	a0,0x2
    80006e9c:	97850513          	addi	a0,a0,-1672 # 80008810 <syscalls+0x3e8>
    80006ea0:	ffff9097          	auipc	ra,0xffff9
    80006ea4:	68a080e7          	jalr	1674(ra) # 8000052a <panic>
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
