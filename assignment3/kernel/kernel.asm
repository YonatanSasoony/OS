
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
    80000068:	a9c78793          	addi	a5,a5,-1380 # 80006b00 <timervec>
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
    80000122:	148080e7          	jalr	328(ra) # 80002266 <either_copyin>
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
    800001c6:	ea8080e7          	jalr	-344(ra) # 8000206a <sleep>
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
    80000202:	012080e7          	jalr	18(ra) # 80002210 <either_copyout>
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
    800002e2:	fde080e7          	jalr	-34(ra) # 800022bc <procdump>
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
    80000436:	c9c080e7          	jalr	-868(ra) # 800020ce <wakeup>
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
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	850080e7          	jalr	-1968(ra) # 800020ce <wakeup>
    
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
    8000090e:	760080e7          	jalr	1888(ra) # 8000206a <sleep>
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
    80000eb6:	0ee080e7          	jalr	238(ra) # 80002fa0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	c86080e7          	jalr	-890(ra) # 80006b40 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	ff6080e7          	jalr	-10(ra) # 80001eb8 <scheduler>
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
    80000f2e:	04e080e7          	jalr	78(ra) # 80002f78 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	06e080e7          	jalr	110(ra) # 80002fa0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	bf0080e7          	jalr	-1040(ra) # 80006b2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	bfe080e7          	jalr	-1026(ra) # 80006b40 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	7ce080e7          	jalr	1998(ra) # 80003718 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	e60080e7          	jalr	-416(ra) # 80003db2 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	120080e7          	jalr	288(ra) # 8000507a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	d00080e7          	jalr	-768(ra) # 80006c62 <virtio_disk_init>
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
    80001428:	724080e7          	jalr	1828(ra) # 80002b48 <remove_page_from_ram>
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
    80001492:	8b0080e7          	jalr	-1872(ra) # 80002d3e <insert_page_to_ram>
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
  char *mem = 0;

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
  char *mem = 0;
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
    80001a32:	58a080e7          	jalr	1418(ra) # 80002fb8 <usertrapret>
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
    80001a4c:	2ea080e7          	jalr	746(ra) # 80003d32 <fsinit>
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
    80001d0e:	a56080e7          	jalr	-1450(ra) # 80004760 <namei>
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

0000000080001da2 <relevant_metadata_proc>:
int relevant_metadata_proc(struct proc *p) {
    80001da2:	1141                	addi	sp,sp,-16
    80001da4:	e422                	sd	s0,8(sp)
    80001da6:	0800                	addi	s0,sp,16
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80001da8:	591c                	lw	a5,48(a0)
    80001daa:	37fd                	addiw	a5,a5,-1
}
    80001dac:	4505                	li	a0,1
    80001dae:	00f53533          	sltu	a0,a0,a5
    80001db2:	6422                	ld	s0,8(sp)
    80001db4:	0141                	addi	sp,sp,16
    80001db6:	8082                	ret

0000000080001db8 <fill_swapFile>:
{
    80001db8:	7179                	addi	sp,sp,-48
    80001dba:	f406                	sd	ra,40(sp)
    80001dbc:	f022                	sd	s0,32(sp)
    80001dbe:	ec26                	sd	s1,24(sp)
    80001dc0:	e84a                	sd	s2,16(sp)
    80001dc2:	e44e                	sd	s3,8(sp)
    80001dc4:	e052                	sd	s4,0(sp)
    80001dc6:	1800                	addi	s0,sp,48
    80001dc8:	892a                	mv	s2,a0
  char *page = kalloc();
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	d08080e7          	jalr	-760(ra) # 80000ad2 <kalloc>
    80001dd2:	89aa                	mv	s3,a0
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001dd4:	27090493          	addi	s1,s2,624
    80001dd8:	37090a13          	addi	s4,s2,880
    if (writeToSwapFile(p, page, disk_pg->offset, PGSIZE) < 0) {
    80001ddc:	6685                	lui	a3,0x1
    80001dde:	4490                	lw	a2,8(s1)
    80001de0:	85ce                	mv	a1,s3
    80001de2:	854a                	mv	a0,s2
    80001de4:	00003097          	auipc	ra,0x3
    80001de8:	c80080e7          	jalr	-896(ra) # 80004a64 <writeToSwapFile>
    80001dec:	02054363          	bltz	a0,80001e12 <fill_swapFile+0x5a>
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001df0:	04c1                	addi	s1,s1,16
    80001df2:	fe9a15e3          	bne	s4,s1,80001ddc <fill_swapFile+0x24>
  kfree(page);
    80001df6:	854e                	mv	a0,s3
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	bde080e7          	jalr	-1058(ra) # 800009d6 <kfree>
  return 0;
    80001e00:	4501                	li	a0,0
}
    80001e02:	70a2                	ld	ra,40(sp)
    80001e04:	7402                	ld	s0,32(sp)
    80001e06:	64e2                	ld	s1,24(sp)
    80001e08:	6942                	ld	s2,16(sp)
    80001e0a:	69a2                	ld	s3,8(sp)
    80001e0c:	6a02                	ld	s4,0(sp)
    80001e0e:	6145                	addi	sp,sp,48
    80001e10:	8082                	ret
      return -1;
    80001e12:	557d                	li	a0,-1
    80001e14:	b7fd                	j	80001e02 <fill_swapFile+0x4a>

0000000080001e16 <copy_swapFile>:
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001e16:	c559                	beqz	a0,80001ea4 <copy_swapFile+0x8e>
int copy_swapFile(struct proc *src, struct proc *dst) {
    80001e18:	7139                	addi	sp,sp,-64
    80001e1a:	fc06                	sd	ra,56(sp)
    80001e1c:	f822                	sd	s0,48(sp)
    80001e1e:	f426                	sd	s1,40(sp)
    80001e20:	f04a                	sd	s2,32(sp)
    80001e22:	ec4e                	sd	s3,24(sp)
    80001e24:	e852                	sd	s4,16(sp)
    80001e26:	e456                	sd	s5,8(sp)
    80001e28:	0080                	addi	s0,sp,64
    80001e2a:	8a2a                	mv	s4,a0
    80001e2c:	8aae                	mv	s5,a1
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001e2e:	16853783          	ld	a5,360(a0)
    80001e32:	cbbd                	beqz	a5,80001ea8 <copy_swapFile+0x92>
    80001e34:	cda5                	beqz	a1,80001eac <copy_swapFile+0x96>
    80001e36:	1685b783          	ld	a5,360(a1)
    80001e3a:	cbbd                	beqz	a5,80001eb0 <copy_swapFile+0x9a>
  char *buffer = (char *)kalloc();
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	c96080e7          	jalr	-874(ra) # 80000ad2 <kalloc>
    80001e44:	89aa                	mv	s3,a0
  for (struct disk_page *disk_pg = src->disk_pages; disk_pg < &src->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001e46:	270a0493          	addi	s1,s4,624
    80001e4a:	370a0913          	addi	s2,s4,880
    80001e4e:	a021                	j	80001e56 <copy_swapFile+0x40>
    80001e50:	04c1                	addi	s1,s1,16
    80001e52:	02990a63          	beq	s2,s1,80001e86 <copy_swapFile+0x70>
    if(disk_pg->used) {
    80001e56:	44dc                	lw	a5,12(s1)
    80001e58:	dfe5                	beqz	a5,80001e50 <copy_swapFile+0x3a>
      if (readFromSwapFile(src, buffer, disk_pg->offset, PGSIZE) < 0) {
    80001e5a:	6685                	lui	a3,0x1
    80001e5c:	4490                	lw	a2,8(s1)
    80001e5e:	85ce                	mv	a1,s3
    80001e60:	8552                	mv	a0,s4
    80001e62:	00003097          	auipc	ra,0x3
    80001e66:	c26080e7          	jalr	-986(ra) # 80004a88 <readFromSwapFile>
    80001e6a:	04054563          	bltz	a0,80001eb4 <copy_swapFile+0x9e>
      if (writeToSwapFile(dst, buffer, disk_pg->offset, PGSIZE) < 0) {
    80001e6e:	6685                	lui	a3,0x1
    80001e70:	4490                	lw	a2,8(s1)
    80001e72:	85ce                	mv	a1,s3
    80001e74:	8556                	mv	a0,s5
    80001e76:	00003097          	auipc	ra,0x3
    80001e7a:	bee080e7          	jalr	-1042(ra) # 80004a64 <writeToSwapFile>
    80001e7e:	fc0559e3          	bgez	a0,80001e50 <copy_swapFile+0x3a>
        return -1;
    80001e82:	557d                	li	a0,-1
    80001e84:	a039                	j	80001e92 <copy_swapFile+0x7c>
  kfree((void *)buffer);
    80001e86:	854e                	mv	a0,s3
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	b4e080e7          	jalr	-1202(ra) # 800009d6 <kfree>
  return 0;
    80001e90:	4501                	li	a0,0
}
    80001e92:	70e2                	ld	ra,56(sp)
    80001e94:	7442                	ld	s0,48(sp)
    80001e96:	74a2                	ld	s1,40(sp)
    80001e98:	7902                	ld	s2,32(sp)
    80001e9a:	69e2                	ld	s3,24(sp)
    80001e9c:	6a42                	ld	s4,16(sp)
    80001e9e:	6aa2                	ld	s5,8(sp)
    80001ea0:	6121                	addi	sp,sp,64
    80001ea2:	8082                	ret
    return -1;
    80001ea4:	557d                	li	a0,-1
}
    80001ea6:	8082                	ret
    return -1;
    80001ea8:	557d                	li	a0,-1
    80001eaa:	b7e5                	j	80001e92 <copy_swapFile+0x7c>
    80001eac:	557d                	li	a0,-1
    80001eae:	b7d5                	j	80001e92 <copy_swapFile+0x7c>
    80001eb0:	557d                	li	a0,-1
    80001eb2:	b7c5                	j	80001e92 <copy_swapFile+0x7c>
        return -1;
    80001eb4:	557d                	li	a0,-1
    80001eb6:	bff1                	j	80001e92 <copy_swapFile+0x7c>

0000000080001eb8 <scheduler>:
{
    80001eb8:	7139                	addi	sp,sp,-64
    80001eba:	fc06                	sd	ra,56(sp)
    80001ebc:	f822                	sd	s0,48(sp)
    80001ebe:	f426                	sd	s1,40(sp)
    80001ec0:	f04a                	sd	s2,32(sp)
    80001ec2:	ec4e                	sd	s3,24(sp)
    80001ec4:	e852                	sd	s4,16(sp)
    80001ec6:	e456                	sd	s5,8(sp)
    80001ec8:	e05a                	sd	s6,0(sp)
    80001eca:	0080                	addi	s0,sp,64
    80001ecc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ece:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed0:	00779a93          	slli	s5,a5,0x7
    80001ed4:	00010717          	auipc	a4,0x10
    80001ed8:	3cc70713          	addi	a4,a4,972 # 800122a0 <pid_lock>
    80001edc:	9756                	add	a4,a4,s5
    80001ede:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee2:	00010717          	auipc	a4,0x10
    80001ee6:	3f670713          	addi	a4,a4,1014 # 800122d8 <cpus+0x8>
    80001eea:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eec:	498d                	li	s3,3
        p->state = RUNNING;
    80001eee:	4b11                	li	s6,4
        c->proc = p;
    80001ef0:	079e                	slli	a5,a5,0x7
    80001ef2:	00010a17          	auipc	s4,0x10
    80001ef6:	3aea0a13          	addi	s4,s4,942 # 800122a0 <pid_lock>
    80001efa:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001efc:	0001e917          	auipc	s2,0x1e
    80001f00:	5d490913          	addi	s2,s2,1492 # 800204d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0c:	10079073          	csrw	sstatus,a5
    80001f10:	00010497          	auipc	s1,0x10
    80001f14:	7c048493          	addi	s1,s1,1984 # 800126d0 <proc>
    80001f18:	a811                	j	80001f2c <scheduler+0x74>
      release(&p->lock);
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	d5a080e7          	jalr	-678(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f24:	37848493          	addi	s1,s1,888
    80001f28:	fd248ee3          	beq	s1,s2,80001f04 <scheduler+0x4c>
      acquire(&p->lock);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	c94080e7          	jalr	-876(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f36:	4c9c                	lw	a5,24(s1)
    80001f38:	ff3791e3          	bne	a5,s3,80001f1a <scheduler+0x62>
        p->state = RUNNING;
    80001f3c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f40:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f44:	06048593          	addi	a1,s1,96
    80001f48:	8556                	mv	a0,s5
    80001f4a:	00001097          	auipc	ra,0x1
    80001f4e:	fc4080e7          	jalr	-60(ra) # 80002f0e <swtch>
        c->proc = 0;
    80001f52:	020a3823          	sd	zero,48(s4)
    80001f56:	b7d1                	j	80001f1a <scheduler+0x62>

0000000080001f58 <sched>:
{
    80001f58:	7179                	addi	sp,sp,-48
    80001f5a:	f406                	sd	ra,40(sp)
    80001f5c:	f022                	sd	s0,32(sp)
    80001f5e:	ec26                	sd	s1,24(sp)
    80001f60:	e84a                	sd	s2,16(sp)
    80001f62:	e44e                	sd	s3,8(sp)
    80001f64:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	a6e080e7          	jalr	-1426(ra) # 800019d4 <myproc>
    80001f6e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	bd8080e7          	jalr	-1064(ra) # 80000b48 <holding>
    80001f78:	c93d                	beqz	a0,80001fee <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f7a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f7c:	2781                	sext.w	a5,a5
    80001f7e:	079e                	slli	a5,a5,0x7
    80001f80:	00010717          	auipc	a4,0x10
    80001f84:	32070713          	addi	a4,a4,800 # 800122a0 <pid_lock>
    80001f88:	97ba                	add	a5,a5,a4
    80001f8a:	0a87a703          	lw	a4,168(a5) # 10a8 <_entry-0x7fffef58>
    80001f8e:	4785                	li	a5,1
    80001f90:	06f71763          	bne	a4,a5,80001ffe <sched+0xa6>
  if(p->state == RUNNING)
    80001f94:	4c98                	lw	a4,24(s1)
    80001f96:	4791                	li	a5,4
    80001f98:	06f70b63          	beq	a4,a5,8000200e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fa0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fa2:	efb5                	bnez	a5,8000201e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa6:	00010917          	auipc	s2,0x10
    80001faa:	2fa90913          	addi	s2,s2,762 # 800122a0 <pid_lock>
    80001fae:	2781                	sext.w	a5,a5
    80001fb0:	079e                	slli	a5,a5,0x7
    80001fb2:	97ca                	add	a5,a5,s2
    80001fb4:	0ac7a983          	lw	s3,172(a5)
    80001fb8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	00010597          	auipc	a1,0x10
    80001fc2:	31a58593          	addi	a1,a1,794 # 800122d8 <cpus+0x8>
    80001fc6:	95be                	add	a1,a1,a5
    80001fc8:	06048513          	addi	a0,s1,96
    80001fcc:	00001097          	auipc	ra,0x1
    80001fd0:	f42080e7          	jalr	-190(ra) # 80002f0e <swtch>
    80001fd4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd6:	2781                	sext.w	a5,a5
    80001fd8:	079e                	slli	a5,a5,0x7
    80001fda:	97ca                	add	a5,a5,s2
    80001fdc:	0b37a623          	sw	s3,172(a5)
}
    80001fe0:	70a2                	ld	ra,40(sp)
    80001fe2:	7402                	ld	s0,32(sp)
    80001fe4:	64e2                	ld	s1,24(sp)
    80001fe6:	6942                	ld	s2,16(sp)
    80001fe8:	69a2                	ld	s3,8(sp)
    80001fea:	6145                	addi	sp,sp,48
    80001fec:	8082                	ret
    panic("sched p->lock");
    80001fee:	00007517          	auipc	a0,0x7
    80001ff2:	21250513          	addi	a0,a0,530 # 80009200 <digits+0x1c0>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	534080e7          	jalr	1332(ra) # 8000052a <panic>
    panic("sched locks");
    80001ffe:	00007517          	auipc	a0,0x7
    80002002:	21250513          	addi	a0,a0,530 # 80009210 <digits+0x1d0>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	524080e7          	jalr	1316(ra) # 8000052a <panic>
    panic("sched running");
    8000200e:	00007517          	auipc	a0,0x7
    80002012:	21250513          	addi	a0,a0,530 # 80009220 <digits+0x1e0>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	514080e7          	jalr	1300(ra) # 8000052a <panic>
    panic("sched interruptible");
    8000201e:	00007517          	auipc	a0,0x7
    80002022:	21250513          	addi	a0,a0,530 # 80009230 <digits+0x1f0>
    80002026:	ffffe097          	auipc	ra,0xffffe
    8000202a:	504080e7          	jalr	1284(ra) # 8000052a <panic>

000000008000202e <yield>:
{
    8000202e:	1101                	addi	sp,sp,-32
    80002030:	ec06                	sd	ra,24(sp)
    80002032:	e822                	sd	s0,16(sp)
    80002034:	e426                	sd	s1,8(sp)
    80002036:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	99c080e7          	jalr	-1636(ra) # 800019d4 <myproc>
    80002040:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	b80080e7          	jalr	-1152(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000204a:	478d                	li	a5,3
    8000204c:	cc9c                	sw	a5,24(s1)
  sched();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	f0a080e7          	jalr	-246(ra) # 80001f58 <sched>
  release(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c1e080e7          	jalr	-994(ra) # 80000c76 <release>
}
    80002060:	60e2                	ld	ra,24(sp)
    80002062:	6442                	ld	s0,16(sp)
    80002064:	64a2                	ld	s1,8(sp)
    80002066:	6105                	addi	sp,sp,32
    80002068:	8082                	ret

000000008000206a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000206a:	7179                	addi	sp,sp,-48
    8000206c:	f406                	sd	ra,40(sp)
    8000206e:	f022                	sd	s0,32(sp)
    80002070:	ec26                	sd	s1,24(sp)
    80002072:	e84a                	sd	s2,16(sp)
    80002074:	e44e                	sd	s3,8(sp)
    80002076:	1800                	addi	s0,sp,48
    80002078:	89aa                	mv	s3,a0
    8000207a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	958080e7          	jalr	-1704(ra) # 800019d4 <myproc>
    80002084:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b3c080e7          	jalr	-1220(ra) # 80000bc2 <acquire>
  release(lk);
    8000208e:	854a                	mv	a0,s2
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	be6080e7          	jalr	-1050(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002098:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209c:	4789                	li	a5,2
    8000209e:	cc9c                	sw	a5,24(s1)

  sched();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	eb8080e7          	jalr	-328(ra) # 80001f58 <sched>

  // Tidy up.
  p->chan = 0;
    800020a8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bc8080e7          	jalr	-1080(ra) # 80000c76 <release>
  acquire(lk);
    800020b6:	854a                	mv	a0,s2
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	b0a080e7          	jalr	-1270(ra) # 80000bc2 <acquire>
}
    800020c0:	70a2                	ld	ra,40(sp)
    800020c2:	7402                	ld	s0,32(sp)
    800020c4:	64e2                	ld	s1,24(sp)
    800020c6:	6942                	ld	s2,16(sp)
    800020c8:	69a2                	ld	s3,8(sp)
    800020ca:	6145                	addi	sp,sp,48
    800020cc:	8082                	ret

00000000800020ce <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020ce:	7139                	addi	sp,sp,-64
    800020d0:	fc06                	sd	ra,56(sp)
    800020d2:	f822                	sd	s0,48(sp)
    800020d4:	f426                	sd	s1,40(sp)
    800020d6:	f04a                	sd	s2,32(sp)
    800020d8:	ec4e                	sd	s3,24(sp)
    800020da:	e852                	sd	s4,16(sp)
    800020dc:	e456                	sd	s5,8(sp)
    800020de:	0080                	addi	s0,sp,64
    800020e0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020e2:	00010497          	auipc	s1,0x10
    800020e6:	5ee48493          	addi	s1,s1,1518 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020ea:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020ec:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ee:	0001e917          	auipc	s2,0x1e
    800020f2:	3e290913          	addi	s2,s2,994 # 800204d0 <tickslock>
    800020f6:	a811                	j	8000210a <wakeup+0x3c>
      }
      release(&p->lock);
    800020f8:	8526                	mv	a0,s1
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	b7c080e7          	jalr	-1156(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002102:	37848493          	addi	s1,s1,888
    80002106:	03248663          	beq	s1,s2,80002132 <wakeup+0x64>
    if(p != myproc()){
    8000210a:	00000097          	auipc	ra,0x0
    8000210e:	8ca080e7          	jalr	-1846(ra) # 800019d4 <myproc>
    80002112:	fea488e3          	beq	s1,a0,80002102 <wakeup+0x34>
      acquire(&p->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	aaa080e7          	jalr	-1366(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002120:	4c9c                	lw	a5,24(s1)
    80002122:	fd379be3          	bne	a5,s3,800020f8 <wakeup+0x2a>
    80002126:	709c                	ld	a5,32(s1)
    80002128:	fd4798e3          	bne	a5,s4,800020f8 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000212c:	0154ac23          	sw	s5,24(s1)
    80002130:	b7e1                	j	800020f8 <wakeup+0x2a>
    }
  }
}
    80002132:	70e2                	ld	ra,56(sp)
    80002134:	7442                	ld	s0,48(sp)
    80002136:	74a2                	ld	s1,40(sp)
    80002138:	7902                	ld	s2,32(sp)
    8000213a:	69e2                	ld	s3,24(sp)
    8000213c:	6a42                	ld	s4,16(sp)
    8000213e:	6aa2                	ld	s5,8(sp)
    80002140:	6121                	addi	sp,sp,64
    80002142:	8082                	ret

0000000080002144 <reparent>:
{
    80002144:	7179                	addi	sp,sp,-48
    80002146:	f406                	sd	ra,40(sp)
    80002148:	f022                	sd	s0,32(sp)
    8000214a:	ec26                	sd	s1,24(sp)
    8000214c:	e84a                	sd	s2,16(sp)
    8000214e:	e44e                	sd	s3,8(sp)
    80002150:	e052                	sd	s4,0(sp)
    80002152:	1800                	addi	s0,sp,48
    80002154:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002156:	00010497          	auipc	s1,0x10
    8000215a:	57a48493          	addi	s1,s1,1402 # 800126d0 <proc>
      pp->parent = initproc;
    8000215e:	00008a17          	auipc	s4,0x8
    80002162:	ecaa0a13          	addi	s4,s4,-310 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002166:	0001e997          	auipc	s3,0x1e
    8000216a:	36a98993          	addi	s3,s3,874 # 800204d0 <tickslock>
    8000216e:	a029                	j	80002178 <reparent+0x34>
    80002170:	37848493          	addi	s1,s1,888
    80002174:	01348d63          	beq	s1,s3,8000218e <reparent+0x4a>
    if(pp->parent == p){
    80002178:	7c9c                	ld	a5,56(s1)
    8000217a:	ff279be3          	bne	a5,s2,80002170 <reparent+0x2c>
      pp->parent = initproc;
    8000217e:	000a3503          	ld	a0,0(s4)
    80002182:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002184:	00000097          	auipc	ra,0x0
    80002188:	f4a080e7          	jalr	-182(ra) # 800020ce <wakeup>
    8000218c:	b7d5                	j	80002170 <reparent+0x2c>
}
    8000218e:	70a2                	ld	ra,40(sp)
    80002190:	7402                	ld	s0,32(sp)
    80002192:	64e2                	ld	s1,24(sp)
    80002194:	6942                	ld	s2,16(sp)
    80002196:	69a2                	ld	s3,8(sp)
    80002198:	6a02                	ld	s4,0(sp)
    8000219a:	6145                	addi	sp,sp,48
    8000219c:	8082                	ret

000000008000219e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800021ae:	00010497          	auipc	s1,0x10
    800021b2:	52248493          	addi	s1,s1,1314 # 800126d0 <proc>
    800021b6:	0001e997          	auipc	s3,0x1e
    800021ba:	31a98993          	addi	s3,s3,794 # 800204d0 <tickslock>
    acquire(&p->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a02080e7          	jalr	-1534(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800021c8:	589c                	lw	a5,48(s1)
    800021ca:	01278d63          	beq	a5,s2,800021e4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	aa6080e7          	jalr	-1370(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800021d8:	37848493          	addi	s1,s1,888
    800021dc:	ff3491e3          	bne	s1,s3,800021be <kill+0x20>
  }
  return -1;
    800021e0:	557d                	li	a0,-1
    800021e2:	a829                	j	800021fc <kill+0x5e>
      p->killed = 1;
    800021e4:	4785                	li	a5,1
    800021e6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800021e8:	4c98                	lw	a4,24(s1)
    800021ea:	4789                	li	a5,2
    800021ec:	00f70f63          	beq	a4,a5,8000220a <kill+0x6c>
      release(&p->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	a84080e7          	jalr	-1404(ra) # 80000c76 <release>
      return 0;
    800021fa:	4501                	li	a0,0
}
    800021fc:	70a2                	ld	ra,40(sp)
    800021fe:	7402                	ld	s0,32(sp)
    80002200:	64e2                	ld	s1,24(sp)
    80002202:	6942                	ld	s2,16(sp)
    80002204:	69a2                	ld	s3,8(sp)
    80002206:	6145                	addi	sp,sp,48
    80002208:	8082                	ret
        p->state = RUNNABLE;
    8000220a:	478d                	li	a5,3
    8000220c:	cc9c                	sw	a5,24(s1)
    8000220e:	b7cd                	j	800021f0 <kill+0x52>

0000000080002210 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002210:	7179                	addi	sp,sp,-48
    80002212:	f406                	sd	ra,40(sp)
    80002214:	f022                	sd	s0,32(sp)
    80002216:	ec26                	sd	s1,24(sp)
    80002218:	e84a                	sd	s2,16(sp)
    8000221a:	e44e                	sd	s3,8(sp)
    8000221c:	e052                	sd	s4,0(sp)
    8000221e:	1800                	addi	s0,sp,48
    80002220:	84aa                	mv	s1,a0
    80002222:	892e                	mv	s2,a1
    80002224:	89b2                	mv	s3,a2
    80002226:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	7ac080e7          	jalr	1964(ra) # 800019d4 <myproc>
  if(user_dst){
    80002230:	c08d                	beqz	s1,80002252 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002232:	86d2                	mv	a3,s4
    80002234:	864e                	mv	a2,s3
    80002236:	85ca                	mv	a1,s2
    80002238:	6928                	ld	a0,80(a0)
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	45a080e7          	jalr	1114(ra) # 80001694 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002242:	70a2                	ld	ra,40(sp)
    80002244:	7402                	ld	s0,32(sp)
    80002246:	64e2                	ld	s1,24(sp)
    80002248:	6942                	ld	s2,16(sp)
    8000224a:	69a2                	ld	s3,8(sp)
    8000224c:	6a02                	ld	s4,0(sp)
    8000224e:	6145                	addi	sp,sp,48
    80002250:	8082                	ret
    memmove((char *)dst, src, len);
    80002252:	000a061b          	sext.w	a2,s4
    80002256:	85ce                	mv	a1,s3
    80002258:	854a                	mv	a0,s2
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	ac0080e7          	jalr	-1344(ra) # 80000d1a <memmove>
    return 0;
    80002262:	8526                	mv	a0,s1
    80002264:	bff9                	j	80002242 <either_copyout+0x32>

0000000080002266 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002266:	7179                	addi	sp,sp,-48
    80002268:	f406                	sd	ra,40(sp)
    8000226a:	f022                	sd	s0,32(sp)
    8000226c:	ec26                	sd	s1,24(sp)
    8000226e:	e84a                	sd	s2,16(sp)
    80002270:	e44e                	sd	s3,8(sp)
    80002272:	e052                	sd	s4,0(sp)
    80002274:	1800                	addi	s0,sp,48
    80002276:	892a                	mv	s2,a0
    80002278:	84ae                	mv	s1,a1
    8000227a:	89b2                	mv	s3,a2
    8000227c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	756080e7          	jalr	1878(ra) # 800019d4 <myproc>
  if(user_src){
    80002286:	c08d                	beqz	s1,800022a8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002288:	86d2                	mv	a3,s4
    8000228a:	864e                	mv	a2,s3
    8000228c:	85ca                	mv	a1,s2
    8000228e:	6928                	ld	a0,80(a0)
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	490080e7          	jalr	1168(ra) # 80001720 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002298:	70a2                	ld	ra,40(sp)
    8000229a:	7402                	ld	s0,32(sp)
    8000229c:	64e2                	ld	s1,24(sp)
    8000229e:	6942                	ld	s2,16(sp)
    800022a0:	69a2                	ld	s3,8(sp)
    800022a2:	6a02                	ld	s4,0(sp)
    800022a4:	6145                	addi	sp,sp,48
    800022a6:	8082                	ret
    memmove(dst, (char*)src, len);
    800022a8:	000a061b          	sext.w	a2,s4
    800022ac:	85ce                	mv	a1,s3
    800022ae:	854a                	mv	a0,s2
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	a6a080e7          	jalr	-1430(ra) # 80000d1a <memmove>
    return 0;
    800022b8:	8526                	mv	a0,s1
    800022ba:	bff9                	j	80002298 <either_copyin+0x32>

00000000800022bc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800022bc:	715d                	addi	sp,sp,-80
    800022be:	e486                	sd	ra,72(sp)
    800022c0:	e0a2                	sd	s0,64(sp)
    800022c2:	fc26                	sd	s1,56(sp)
    800022c4:	f84a                	sd	s2,48(sp)
    800022c6:	f44e                	sd	s3,40(sp)
    800022c8:	f052                	sd	s4,32(sp)
    800022ca:	ec56                	sd	s5,24(sp)
    800022cc:	e85a                	sd	s6,16(sp)
    800022ce:	e45e                	sd	s7,8(sp)
    800022d0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800022d2:	00007517          	auipc	a0,0x7
    800022d6:	df650513          	addi	a0,a0,-522 # 800090c8 <digits+0x88>
    800022da:	ffffe097          	auipc	ra,0xffffe
    800022de:	29a080e7          	jalr	666(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022e2:	00010497          	auipc	s1,0x10
    800022e6:	54648493          	addi	s1,s1,1350 # 80012828 <proc+0x158>
    800022ea:	0001e917          	auipc	s2,0x1e
    800022ee:	33e90913          	addi	s2,s2,830 # 80020628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022f2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800022f4:	00007997          	auipc	s3,0x7
    800022f8:	f5498993          	addi	s3,s3,-172 # 80009248 <digits+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    800022fc:	00007a97          	auipc	s5,0x7
    80002300:	f54a8a93          	addi	s5,s5,-172 # 80009250 <digits+0x210>
    printf("\n");
    80002304:	00007a17          	auipc	s4,0x7
    80002308:	dc4a0a13          	addi	s4,s4,-572 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000230c:	00007b97          	auipc	s7,0x7
    80002310:	284b8b93          	addi	s7,s7,644 # 80009590 <states.0>
    80002314:	a00d                	j	80002336 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002316:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    8000231a:	8556                	mv	a0,s5
    8000231c:	ffffe097          	auipc	ra,0xffffe
    80002320:	258080e7          	jalr	600(ra) # 80000574 <printf>
    printf("\n");
    80002324:	8552                	mv	a0,s4
    80002326:	ffffe097          	auipc	ra,0xffffe
    8000232a:	24e080e7          	jalr	590(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000232e:	37848493          	addi	s1,s1,888
    80002332:	03248263          	beq	s1,s2,80002356 <procdump+0x9a>
    if(p->state == UNUSED)
    80002336:	86a6                	mv	a3,s1
    80002338:	ec04a783          	lw	a5,-320(s1)
    8000233c:	dbed                	beqz	a5,8000232e <procdump+0x72>
      state = "???";
    8000233e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002340:	fcfb6be3          	bltu	s6,a5,80002316 <procdump+0x5a>
    80002344:	02079713          	slli	a4,a5,0x20
    80002348:	01d75793          	srli	a5,a4,0x1d
    8000234c:	97de                	add	a5,a5,s7
    8000234e:	6390                	ld	a2,0(a5)
    80002350:	f279                	bnez	a2,80002316 <procdump+0x5a>
      state = "???";
    80002352:	864e                	mv	a2,s3
    80002354:	b7c9                	j	80002316 <procdump+0x5a>
  }
}
    80002356:	60a6                	ld	ra,72(sp)
    80002358:	6406                	ld	s0,64(sp)
    8000235a:	74e2                	ld	s1,56(sp)
    8000235c:	7942                	ld	s2,48(sp)
    8000235e:	79a2                	ld	s3,40(sp)
    80002360:	7a02                	ld	s4,32(sp)
    80002362:	6ae2                	ld	s5,24(sp)
    80002364:	6b42                	ld	s6,16(sp)
    80002366:	6ba2                	ld	s7,8(sp)
    80002368:	6161                	addi	sp,sp,80
    8000236a:	8082                	ret

000000008000236c <init_metadata>:

// ADDED Q1 - p->lock must not be held because of createSwapFile!
int init_metadata(struct proc *p)
{
    8000236c:	1101                	addi	sp,sp,-32
    8000236e:	ec06                	sd	ra,24(sp)
    80002370:	e822                	sd	s0,16(sp)
    80002372:	e426                	sd	s1,8(sp)
    80002374:	1000                	addi	s0,sp,32
    80002376:	84aa                	mv	s1,a0
  if (!p->swapFile && createSwapFile(p) < 0) {
    80002378:	16853783          	ld	a5,360(a0)
    8000237c:	c7a1                	beqz	a5,800023c4 <init_metadata+0x58>
    return -1;
  }

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000237e:	17048793          	addi	a5,s1,368
    80002382:	27048713          	addi	a4,s1,624
    p->ram_pages[i].va = 0;
    80002386:	0007b023          	sd	zero,0(a5)
    p->ram_pages[i].age = 0; // ADDED Q2
    8000238a:	0007a423          	sw	zero,8(a5)
    p->ram_pages[i].used = 0;
    8000238e:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002392:	07c1                	addi	a5,a5,16
    80002394:	fee799e3          	bne	a5,a4,80002386 <init_metadata+0x1a>
    80002398:	27048793          	addi	a5,s1,624
    8000239c:	4701                	li	a4,0
  }
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    8000239e:	6605                	lui	a2,0x1
    800023a0:	66c1                	lui	a3,0x10
    p->disk_pages[i].va = 0;
    800023a2:	0007b023          	sd	zero,0(a5)
    p->disk_pages[i].offset = i * PGSIZE;
    800023a6:	c798                	sw	a4,8(a5)
    p->disk_pages[i].used = 0;
    800023a8:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    800023ac:	07c1                	addi	a5,a5,16
    800023ae:	9f31                	addw	a4,a4,a2
    800023b0:	fed719e3          	bne	a4,a3,800023a2 <init_metadata+0x36>
  }
  p->scfifo_index = 0; // ADDED Q2
    800023b4:	3604a823          	sw	zero,880(s1)
  return 0;
    800023b8:	4501                	li	a0,0
}
    800023ba:	60e2                	ld	ra,24(sp)
    800023bc:	6442                	ld	s0,16(sp)
    800023be:	64a2                	ld	s1,8(sp)
    800023c0:	6105                	addi	sp,sp,32
    800023c2:	8082                	ret
  if (!p->swapFile && createSwapFile(p) < 0) {
    800023c4:	00002097          	auipc	ra,0x2
    800023c8:	5f0080e7          	jalr	1520(ra) # 800049b4 <createSwapFile>
    800023cc:	fa0559e3          	bgez	a0,8000237e <init_metadata+0x12>
    return -1;
    800023d0:	557d                	li	a0,-1
    800023d2:	b7e5                	j	800023ba <init_metadata+0x4e>

00000000800023d4 <free_metadata>:

// p->lock must not be held because of removeSwapFile!
void free_metadata(struct proc *p)
{
    800023d4:	1101                	addi	sp,sp,-32
    800023d6:	ec06                	sd	ra,24(sp)
    800023d8:	e822                	sd	s0,16(sp)
    800023da:	e426                	sd	s1,8(sp)
    800023dc:	1000                	addi	s0,sp,32
    800023de:	84aa                	mv	s1,a0
    if (p->swapFile && removeSwapFile(p) < 0) {
    800023e0:	16853783          	ld	a5,360(a0)
    800023e4:	c799                	beqz	a5,800023f2 <free_metadata+0x1e>
    800023e6:	00002097          	auipc	ra,0x2
    800023ea:	426080e7          	jalr	1062(ra) # 8000480c <removeSwapFile>
    800023ee:	04054563          	bltz	a0,80002438 <free_metadata+0x64>
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;
    800023f2:	1604b423          	sd	zero,360(s1)

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800023f6:	17048793          	addi	a5,s1,368
    800023fa:	27048713          	addi	a4,s1,624
      p->ram_pages[i].va = 0;
    800023fe:	0007b023          	sd	zero,0(a5)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002402:	0007a423          	sw	zero,8(a5)
      p->ram_pages[i].used = 0;
    80002406:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000240a:	07c1                	addi	a5,a5,16
    8000240c:	fee799e3          	bne	a5,a4,800023fe <free_metadata+0x2a>
    80002410:	27048793          	addi	a5,s1,624
    80002414:	37048713          	addi	a4,s1,880
    }
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
      p->disk_pages[i].va = 0;
    80002418:	0007b023          	sd	zero,0(a5)
      p->disk_pages[i].offset = 0;
    8000241c:	0007a423          	sw	zero,8(a5)
      p->disk_pages[i].used = 0;
    80002420:	0007a623          	sw	zero,12(a5)
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002424:	07c1                	addi	a5,a5,16
    80002426:	fee799e3          	bne	a5,a4,80002418 <free_metadata+0x44>
    }
    p->scfifo_index = 0; // ADDED Q2
    8000242a:	3604a823          	sw	zero,880(s1)
}
    8000242e:	60e2                	ld	ra,24(sp)
    80002430:	6442                	ld	s0,16(sp)
    80002432:	64a2                	ld	s1,8(sp)
    80002434:	6105                	addi	sp,sp,32
    80002436:	8082                	ret
      panic("free_metadata: removeSwapFile failed");
    80002438:	00007517          	auipc	a0,0x7
    8000243c:	e2850513          	addi	a0,a0,-472 # 80009260 <digits+0x220>
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	0ea080e7          	jalr	234(ra) # 8000052a <panic>

0000000080002448 <fork>:
{
    80002448:	7139                	addi	sp,sp,-64
    8000244a:	fc06                	sd	ra,56(sp)
    8000244c:	f822                	sd	s0,48(sp)
    8000244e:	f426                	sd	s1,40(sp)
    80002450:	f04a                	sd	s2,32(sp)
    80002452:	ec4e                	sd	s3,24(sp)
    80002454:	e852                	sd	s4,16(sp)
    80002456:	e456                	sd	s5,8(sp)
    80002458:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	57a080e7          	jalr	1402(ra) # 800019d4 <myproc>
    80002462:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	77a080e7          	jalr	1914(ra) # 80001bde <allocproc>
    8000246c:	1c050063          	beqz	a0,8000262c <fork+0x1e4>
    80002470:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002472:	048ab603          	ld	a2,72(s5)
    80002476:	692c                	ld	a1,80(a0)
    80002478:	050ab503          	ld	a0,80(s5)
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	10e080e7          	jalr	270(ra) # 8000158a <uvmcopy>
    80002484:	04054863          	bltz	a0,800024d4 <fork+0x8c>
  np->sz = p->sz;
    80002488:	048ab783          	ld	a5,72(s5)
    8000248c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002490:	058ab683          	ld	a3,88(s5)
    80002494:	87b6                	mv	a5,a3
    80002496:	0589b703          	ld	a4,88(s3)
    8000249a:	12068693          	addi	a3,a3,288 # 10120 <_entry-0x7ffefee0>
    8000249e:	0007b803          	ld	a6,0(a5)
    800024a2:	6788                	ld	a0,8(a5)
    800024a4:	6b8c                	ld	a1,16(a5)
    800024a6:	6f90                	ld	a2,24(a5)
    800024a8:	01073023          	sd	a6,0(a4)
    800024ac:	e708                	sd	a0,8(a4)
    800024ae:	eb0c                	sd	a1,16(a4)
    800024b0:	ef10                	sd	a2,24(a4)
    800024b2:	02078793          	addi	a5,a5,32
    800024b6:	02070713          	addi	a4,a4,32
    800024ba:	fed792e3          	bne	a5,a3,8000249e <fork+0x56>
  np->trapframe->a0 = 0;
    800024be:	0589b783          	ld	a5,88(s3)
    800024c2:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800024c6:	0d0a8493          	addi	s1,s5,208
    800024ca:	0d098913          	addi	s2,s3,208
    800024ce:	150a8a13          	addi	s4,s5,336
    800024d2:	a00d                	j	800024f4 <fork+0xac>
    freeproc(np);
    800024d4:	854e                	mv	a0,s3
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	6b0080e7          	jalr	1712(ra) # 80001b86 <freeproc>
    release(&np->lock);
    800024de:	854e                	mv	a0,s3
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	796080e7          	jalr	1942(ra) # 80000c76 <release>
    return -1;
    800024e8:	597d                	li	s2,-1
    800024ea:	a8f9                	j	800025c8 <fork+0x180>
  for(i = 0; i < NOFILE; i++)
    800024ec:	04a1                	addi	s1,s1,8
    800024ee:	0921                	addi	s2,s2,8
    800024f0:	01448b63          	beq	s1,s4,80002506 <fork+0xbe>
    if(p->ofile[i])
    800024f4:	6088                	ld	a0,0(s1)
    800024f6:	d97d                	beqz	a0,800024ec <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800024f8:	00003097          	auipc	ra,0x3
    800024fc:	c14080e7          	jalr	-1004(ra) # 8000510c <filedup>
    80002500:	00a93023          	sd	a0,0(s2)
    80002504:	b7e5                	j	800024ec <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002506:	150ab503          	ld	a0,336(s5)
    8000250a:	00002097          	auipc	ra,0x2
    8000250e:	a62080e7          	jalr	-1438(ra) # 80003f6c <idup>
    80002512:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002516:	4641                	li	a2,16
    80002518:	158a8593          	addi	a1,s5,344
    8000251c:	15898513          	addi	a0,s3,344
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	8f0080e7          	jalr	-1808(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002528:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    8000252c:	854e                	mv	a0,s3
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	748080e7          	jalr	1864(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80002536:	00010497          	auipc	s1,0x10
    8000253a:	d8248493          	addi	s1,s1,-638 # 800122b8 <wait_lock>
    8000253e:	8526                	mv	a0,s1
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	682080e7          	jalr	1666(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002548:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	728080e7          	jalr	1832(ra) # 80000c76 <release>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002556:	0309a783          	lw	a5,48(s3)
  if (relevant_metadata_proc(np)) {
    8000255a:	37fd                	addiw	a5,a5,-1
    8000255c:	4705                	li	a4,1
    8000255e:	06f76f63          	bltu	a4,a5,800025dc <fork+0x194>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002562:	030aa783          	lw	a5,48(s5)
  if (relevant_metadata_proc(p)) {
    80002566:	37fd                	addiw	a5,a5,-1
    80002568:	4705                	li	a4,1
    8000256a:	04f77263          	bgeu	a4,a5,800025ae <fork+0x166>
    if (copy_swapFile(p, np) < 0) {
    8000256e:	85ce                	mv	a1,s3
    80002570:	8556                	mv	a0,s5
    80002572:	00000097          	auipc	ra,0x0
    80002576:	8a4080e7          	jalr	-1884(ra) # 80001e16 <copy_swapFile>
    8000257a:	08054d63          	bltz	a0,80002614 <fork+0x1cc>
    memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
    8000257e:	10000613          	li	a2,256
    80002582:	170a8593          	addi	a1,s5,368
    80002586:	17098513          	addi	a0,s3,368
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	790080e7          	jalr	1936(ra) # 80000d1a <memmove>
    memmove(np->disk_pages, p->disk_pages, sizeof(p->disk_pages));
    80002592:	10000613          	li	a2,256
    80002596:	270a8593          	addi	a1,s5,624
    8000259a:	27098513          	addi	a0,s3,624
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	77c080e7          	jalr	1916(ra) # 80000d1a <memmove>
    np->scfifo_index = p->scfifo_index; // ADDED Q2
    800025a6:	370aa783          	lw	a5,880(s5)
    800025aa:	36f9a823          	sw	a5,880(s3)
  acquire(&np->lock);
    800025ae:	854e                	mv	a0,s3
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	612080e7          	jalr	1554(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    800025b8:	478d                	li	a5,3
    800025ba:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800025be:	854e                	mv	a0,s3
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	6b6080e7          	jalr	1718(ra) # 80000c76 <release>
}
    800025c8:	854a                	mv	a0,s2
    800025ca:	70e2                	ld	ra,56(sp)
    800025cc:	7442                	ld	s0,48(sp)
    800025ce:	74a2                	ld	s1,40(sp)
    800025d0:	7902                	ld	s2,32(sp)
    800025d2:	69e2                	ld	s3,24(sp)
    800025d4:	6a42                	ld	s4,16(sp)
    800025d6:	6aa2                	ld	s5,8(sp)
    800025d8:	6121                	addi	sp,sp,64
    800025da:	8082                	ret
    if (init_metadata(np) < 0) {
    800025dc:	854e                	mv	a0,s3
    800025de:	00000097          	auipc	ra,0x0
    800025e2:	d8e080e7          	jalr	-626(ra) # 8000236c <init_metadata>
    800025e6:	02054063          	bltz	a0,80002606 <fork+0x1be>
    if (fill_swapFile(np) < 0) {
    800025ea:	854e                	mv	a0,s3
    800025ec:	fffff097          	auipc	ra,0xfffff
    800025f0:	7cc080e7          	jalr	1996(ra) # 80001db8 <fill_swapFile>
    800025f4:	f60557e3          	bgez	a0,80002562 <fork+0x11a>
      freeproc(np);
    800025f8:	854e                	mv	a0,s3
    800025fa:	fffff097          	auipc	ra,0xfffff
    800025fe:	58c080e7          	jalr	1420(ra) # 80001b86 <freeproc>
      return -1;
    80002602:	597d                	li	s2,-1
    80002604:	b7d1                	j	800025c8 <fork+0x180>
      freeproc(np);
    80002606:	854e                	mv	a0,s3
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	57e080e7          	jalr	1406(ra) # 80001b86 <freeproc>
      return -1;
    80002610:	597d                	li	s2,-1
    80002612:	bf5d                	j	800025c8 <fork+0x180>
      freeproc(np);
    80002614:	854e                	mv	a0,s3
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	570080e7          	jalr	1392(ra) # 80001b86 <freeproc>
      free_metadata(np);
    8000261e:	854e                	mv	a0,s3
    80002620:	00000097          	auipc	ra,0x0
    80002624:	db4080e7          	jalr	-588(ra) # 800023d4 <free_metadata>
      return -1;
    80002628:	597d                	li	s2,-1
    8000262a:	bf79                	j	800025c8 <fork+0x180>
    return -1;
    8000262c:	597d                	li	s2,-1
    8000262e:	bf69                	j	800025c8 <fork+0x180>

0000000080002630 <exit>:
{
    80002630:	7179                	addi	sp,sp,-48
    80002632:	f406                	sd	ra,40(sp)
    80002634:	f022                	sd	s0,32(sp)
    80002636:	ec26                	sd	s1,24(sp)
    80002638:	e84a                	sd	s2,16(sp)
    8000263a:	e44e                	sd	s3,8(sp)
    8000263c:	e052                	sd	s4,0(sp)
    8000263e:	1800                	addi	s0,sp,48
    80002640:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002642:	fffff097          	auipc	ra,0xfffff
    80002646:	392080e7          	jalr	914(ra) # 800019d4 <myproc>
    8000264a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000264c:	00008797          	auipc	a5,0x8
    80002650:	9dc7b783          	ld	a5,-1572(a5) # 8000a028 <initproc>
    80002654:	0d050493          	addi	s1,a0,208
    80002658:	15050913          	addi	s2,a0,336
    8000265c:	02a79363          	bne	a5,a0,80002682 <exit+0x52>
    panic("init exiting");
    80002660:	00007517          	auipc	a0,0x7
    80002664:	c2850513          	addi	a0,a0,-984 # 80009288 <digits+0x248>
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	ec2080e7          	jalr	-318(ra) # 8000052a <panic>
      fileclose(f);
    80002670:	00003097          	auipc	ra,0x3
    80002674:	aee080e7          	jalr	-1298(ra) # 8000515e <fileclose>
      p->ofile[fd] = 0;
    80002678:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000267c:	04a1                	addi	s1,s1,8
    8000267e:	01248563          	beq	s1,s2,80002688 <exit+0x58>
    if(p->ofile[fd]){
    80002682:	6088                	ld	a0,0(s1)
    80002684:	f575                	bnez	a0,80002670 <exit+0x40>
    80002686:	bfdd                	j	8000267c <exit+0x4c>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002688:	0309a783          	lw	a5,48(s3)
  if (relevant_metadata_proc(p)) {
    8000268c:	37fd                	addiw	a5,a5,-1
    8000268e:	4705                	li	a4,1
    80002690:	08f76163          	bltu	a4,a5,80002712 <exit+0xe2>
  begin_op();
    80002694:	00002097          	auipc	ra,0x2
    80002698:	5fe080e7          	jalr	1534(ra) # 80004c92 <begin_op>
  iput(p->cwd);
    8000269c:	1509b503          	ld	a0,336(s3)
    800026a0:	00002097          	auipc	ra,0x2
    800026a4:	ac4080e7          	jalr	-1340(ra) # 80004164 <iput>
  end_op();
    800026a8:	00002097          	auipc	ra,0x2
    800026ac:	66a080e7          	jalr	1642(ra) # 80004d12 <end_op>
  p->cwd = 0;
    800026b0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800026b4:	00010497          	auipc	s1,0x10
    800026b8:	c0448493          	addi	s1,s1,-1020 # 800122b8 <wait_lock>
    800026bc:	8526                	mv	a0,s1
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	504080e7          	jalr	1284(ra) # 80000bc2 <acquire>
  reparent(p);
    800026c6:	854e                	mv	a0,s3
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	a7c080e7          	jalr	-1412(ra) # 80002144 <reparent>
  wakeup(p->parent);
    800026d0:	0389b503          	ld	a0,56(s3)
    800026d4:	00000097          	auipc	ra,0x0
    800026d8:	9fa080e7          	jalr	-1542(ra) # 800020ce <wakeup>
  acquire(&p->lock);
    800026dc:	854e                	mv	a0,s3
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	4e4080e7          	jalr	1252(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800026e6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026ea:	4795                	li	a5,5
    800026ec:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800026f0:	8526                	mv	a0,s1
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	584080e7          	jalr	1412(ra) # 80000c76 <release>
  sched();
    800026fa:	00000097          	auipc	ra,0x0
    800026fe:	85e080e7          	jalr	-1954(ra) # 80001f58 <sched>
  panic("zombie exit");
    80002702:	00007517          	auipc	a0,0x7
    80002706:	b9650513          	addi	a0,a0,-1130 # 80009298 <digits+0x258>
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	e20080e7          	jalr	-480(ra) # 8000052a <panic>
    free_metadata(p);
    80002712:	854e                	mv	a0,s3
    80002714:	00000097          	auipc	ra,0x0
    80002718:	cc0080e7          	jalr	-832(ra) # 800023d4 <free_metadata>
    8000271c:	bfa5                	j	80002694 <exit+0x64>

000000008000271e <wait>:
{
    8000271e:	715d                	addi	sp,sp,-80
    80002720:	e486                	sd	ra,72(sp)
    80002722:	e0a2                	sd	s0,64(sp)
    80002724:	fc26                	sd	s1,56(sp)
    80002726:	f84a                	sd	s2,48(sp)
    80002728:	f44e                	sd	s3,40(sp)
    8000272a:	f052                	sd	s4,32(sp)
    8000272c:	ec56                	sd	s5,24(sp)
    8000272e:	e85a                	sd	s6,16(sp)
    80002730:	e45e                	sd	s7,8(sp)
    80002732:	e062                	sd	s8,0(sp)
    80002734:	0880                	addi	s0,sp,80
    80002736:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002738:	fffff097          	auipc	ra,0xfffff
    8000273c:	29c080e7          	jalr	668(ra) # 800019d4 <myproc>
    80002740:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002742:	00010517          	auipc	a0,0x10
    80002746:	b7650513          	addi	a0,a0,-1162 # 800122b8 <wait_lock>
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	478080e7          	jalr	1144(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002752:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002754:	4a15                	li	s4,5
        havekids = 1;
    80002756:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002758:	0001e997          	auipc	s3,0x1e
    8000275c:	d7898993          	addi	s3,s3,-648 # 800204d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002760:	00010c17          	auipc	s8,0x10
    80002764:	b58c0c13          	addi	s8,s8,-1192 # 800122b8 <wait_lock>
    havekids = 0;
    80002768:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000276a:	00010497          	auipc	s1,0x10
    8000276e:	f6648493          	addi	s1,s1,-154 # 800126d0 <proc>
    80002772:	a059                	j	800027f8 <wait+0xda>
          pid = np->pid;
    80002774:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002778:	000b0e63          	beqz	s6,80002794 <wait+0x76>
    8000277c:	4691                	li	a3,4
    8000277e:	02c48613          	addi	a2,s1,44
    80002782:	85da                	mv	a1,s6
    80002784:	05093503          	ld	a0,80(s2)
    80002788:	fffff097          	auipc	ra,0xfffff
    8000278c:	f0c080e7          	jalr	-244(ra) # 80001694 <copyout>
    80002790:	02054b63          	bltz	a0,800027c6 <wait+0xa8>
          freeproc(np);
    80002794:	8526                	mv	a0,s1
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	3f0080e7          	jalr	1008(ra) # 80001b86 <freeproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    8000279e:	03092783          	lw	a5,48(s2)
         if (relevant_metadata_proc(p)) {
    800027a2:	37fd                	addiw	a5,a5,-1
    800027a4:	4705                	li	a4,1
    800027a6:	02f76f63          	bltu	a4,a5,800027e4 <wait+0xc6>
          release(&np->lock);
    800027aa:	8526                	mv	a0,s1
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	4ca080e7          	jalr	1226(ra) # 80000c76 <release>
          release(&wait_lock);
    800027b4:	00010517          	auipc	a0,0x10
    800027b8:	b0450513          	addi	a0,a0,-1276 # 800122b8 <wait_lock>
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	4ba080e7          	jalr	1210(ra) # 80000c76 <release>
          return pid;
    800027c4:	a88d                	j	80002836 <wait+0x118>
            release(&np->lock);
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	4ae080e7          	jalr	1198(ra) # 80000c76 <release>
            release(&wait_lock);
    800027d0:	00010517          	auipc	a0,0x10
    800027d4:	ae850513          	addi	a0,a0,-1304 # 800122b8 <wait_lock>
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	49e080e7          	jalr	1182(ra) # 80000c76 <release>
            return -1;
    800027e0:	59fd                	li	s3,-1
    800027e2:	a891                	j	80002836 <wait+0x118>
           free_metadata(np);
    800027e4:	8526                	mv	a0,s1
    800027e6:	00000097          	auipc	ra,0x0
    800027ea:	bee080e7          	jalr	-1042(ra) # 800023d4 <free_metadata>
    800027ee:	bf75                	j	800027aa <wait+0x8c>
    for(np = proc; np < &proc[NPROC]; np++){
    800027f0:	37848493          	addi	s1,s1,888
    800027f4:	03348463          	beq	s1,s3,8000281c <wait+0xfe>
      if(np->parent == p){
    800027f8:	7c9c                	ld	a5,56(s1)
    800027fa:	ff279be3          	bne	a5,s2,800027f0 <wait+0xd2>
        acquire(&np->lock);
    800027fe:	8526                	mv	a0,s1
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	3c2080e7          	jalr	962(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002808:	4c9c                	lw	a5,24(s1)
    8000280a:	f74785e3          	beq	a5,s4,80002774 <wait+0x56>
        release(&np->lock);
    8000280e:	8526                	mv	a0,s1
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	466080e7          	jalr	1126(ra) # 80000c76 <release>
        havekids = 1;
    80002818:	8756                	mv	a4,s5
    8000281a:	bfd9                	j	800027f0 <wait+0xd2>
    if(!havekids || p->killed){
    8000281c:	c701                	beqz	a4,80002824 <wait+0x106>
    8000281e:	02892783          	lw	a5,40(s2)
    80002822:	c79d                	beqz	a5,80002850 <wait+0x132>
      release(&wait_lock);
    80002824:	00010517          	auipc	a0,0x10
    80002828:	a9450513          	addi	a0,a0,-1388 # 800122b8 <wait_lock>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	44a080e7          	jalr	1098(ra) # 80000c76 <release>
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
    8000284a:	6c02                	ld	s8,0(sp)
    8000284c:	6161                	addi	sp,sp,80
    8000284e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002850:	85e2                	mv	a1,s8
    80002852:	854a                	mv	a0,s2
    80002854:	00000097          	auipc	ra,0x0
    80002858:	816080e7          	jalr	-2026(ra) # 8000206a <sleep>
    havekids = 0;
    8000285c:	b731                	j	80002768 <wait+0x4a>

000000008000285e <get_free_page_in_disk>:
// ADDED Q1
int get_free_page_in_disk()
{
    8000285e:	1141                	addi	sp,sp,-16
    80002860:	e406                	sd	ra,8(sp)
    80002862:	e022                	sd	s0,0(sp)
    80002864:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	16e080e7          	jalr	366(ra) # 800019d4 <myproc>
  int i = 0;
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    8000286e:	27050793          	addi	a5,a0,624
  int i = 0;
    80002872:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    80002874:	46c1                	li	a3,16
    if (!disk_pg->used) {
    80002876:	47d8                	lw	a4,12(a5)
    80002878:	c711                	beqz	a4,80002884 <get_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    8000287a:	07c1                	addi	a5,a5,16
    8000287c:	2505                	addiw	a0,a0,1
    8000287e:	fed51ce3          	bne	a0,a3,80002876 <get_free_page_in_disk+0x18>
      return i;
    }
  }
  return -1;
    80002882:	557d                	li	a0,-1
}
    80002884:	60a2                	ld	ra,8(sp)
    80002886:	6402                	ld	s0,0(sp)
    80002888:	0141                	addi	sp,sp,16
    8000288a:	8082                	ret

000000008000288c <swapout>:

void swapout(int ram_pg_index)
{
    8000288c:	7139                	addi	sp,sp,-64
    8000288e:	fc06                	sd	ra,56(sp)
    80002890:	f822                	sd	s0,48(sp)
    80002892:	f426                	sd	s1,40(sp)
    80002894:	f04a                	sd	s2,32(sp)
    80002896:	ec4e                	sd	s3,24(sp)
    80002898:	e852                	sd	s4,16(sp)
    8000289a:	e456                	sd	s5,8(sp)
    8000289c:	0080                	addi	s0,sp,64
    8000289e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800028a0:	fffff097          	auipc	ra,0xfffff
    800028a4:	134080e7          	jalr	308(ra) # 800019d4 <myproc>
  if (ram_pg_index < 0 || ram_pg_index >= MAX_PSYC_PAGES) {
    800028a8:	0004871b          	sext.w	a4,s1
    800028ac:	47bd                	li	a5,15
    800028ae:	0ae7e363          	bltu	a5,a4,80002954 <swapout+0xc8>
    800028b2:	8a2a                	mv	s4,a0
    panic("swapout: ram page index out of bounds");
  }
  struct ram_page *ram_pg_to_swap = &p->ram_pages[ram_pg_index];

  if (!ram_pg_to_swap->used) {
    800028b4:	0492                	slli	s1,s1,0x4
    800028b6:	94aa                	add	s1,s1,a0
    800028b8:	17c4a783          	lw	a5,380(s1)
    800028bc:	c7c5                	beqz	a5,80002964 <swapout+0xd8>
    panic("swapout: page unused");
  }

  pte_t *pte;
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    800028be:	4601                	li	a2,0
    800028c0:	1704b583          	ld	a1,368(s1)
    800028c4:	6928                	ld	a0,80(a0)
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	6e0080e7          	jalr	1760(ra) # 80000fa6 <walk>
    800028ce:	89aa                	mv	s3,a0
    800028d0:	c155                	beqz	a0,80002974 <swapout+0xe8>
    panic("swapout: walk failed");
  }

  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    800028d2:	611c                	ld	a5,0(a0)
    800028d4:	2017f793          	andi	a5,a5,513
    800028d8:	4705                	li	a4,1
    800028da:	0ae79563          	bne	a5,a4,80002984 <swapout+0xf8>
    panic("swapout: page is not in ram");
  }

  int unused_disk_pg_index;
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	f80080e7          	jalr	-128(ra) # 8000285e <get_free_page_in_disk>
    800028e6:	0a054763          	bltz	a0,80002994 <swapout+0x108>
    panic("swapout: disk overflow");
  }

  struct disk_page *disk_pg_to_store = &p->disk_pages[unused_disk_pg_index];
  uint64 pa = PTE2PA(*pte);
    800028ea:	0009ba83          	ld	s5,0(s3)
    800028ee:	00aada93          	srli	s5,s5,0xa
    800028f2:	0ab2                	slli	s5,s5,0xc
    800028f4:	00451913          	slli	s2,a0,0x4
    800028f8:	9952                	add	s2,s2,s4
  if (writeToSwapFile(p, (char *)pa, disk_pg_to_store->offset, PGSIZE) < 0) {
    800028fa:	6685                	lui	a3,0x1
    800028fc:	27892603          	lw	a2,632(s2)
    80002900:	85d6                	mv	a1,s5
    80002902:	8552                	mv	a0,s4
    80002904:	00002097          	auipc	ra,0x2
    80002908:	160080e7          	jalr	352(ra) # 80004a64 <writeToSwapFile>
    8000290c:	08054c63          	bltz	a0,800029a4 <swapout+0x118>
    panic("swapout: failed to write to swapFile");
  }
  disk_pg_to_store->used = 1;
    80002910:	4785                	li	a5,1
    80002912:	26f92e23          	sw	a5,636(s2)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    80002916:	1704b783          	ld	a5,368(s1)
    8000291a:	26f93823          	sd	a5,624(s2)
  kfree((void *)pa);
    8000291e:	8556                	mv	a0,s5
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	0b6080e7          	jalr	182(ra) # 800009d6 <kfree>

  ram_pg_to_swap->va = 0;
    80002928:	1604b823          	sd	zero,368(s1)
  ram_pg_to_swap->used = 0;
    8000292c:	1604ae23          	sw	zero,380(s1)

  *pte = *pte & ~PTE_V;
    80002930:	0009b783          	ld	a5,0(s3)
    80002934:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    80002936:	2007e793          	ori	a5,a5,512
    8000293a:	00f9b023          	sd	a5,0(s3)
  asm volatile("sfence.vma zero, zero");
    8000293e:	12000073          	sfence.vma
  sfence_vma();   // clear TLB
}
    80002942:	70e2                	ld	ra,56(sp)
    80002944:	7442                	ld	s0,48(sp)
    80002946:	74a2                	ld	s1,40(sp)
    80002948:	7902                	ld	s2,32(sp)
    8000294a:	69e2                	ld	s3,24(sp)
    8000294c:	6a42                	ld	s4,16(sp)
    8000294e:	6aa2                	ld	s5,8(sp)
    80002950:	6121                	addi	sp,sp,64
    80002952:	8082                	ret
    panic("swapout: ram page index out of bounds");
    80002954:	00007517          	auipc	a0,0x7
    80002958:	95450513          	addi	a0,a0,-1708 # 800092a8 <digits+0x268>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	bce080e7          	jalr	-1074(ra) # 8000052a <panic>
    panic("swapout: page unused");
    80002964:	00007517          	auipc	a0,0x7
    80002968:	96c50513          	addi	a0,a0,-1684 # 800092d0 <digits+0x290>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	bbe080e7          	jalr	-1090(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    80002974:	00007517          	auipc	a0,0x7
    80002978:	97450513          	addi	a0,a0,-1676 # 800092e8 <digits+0x2a8>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	bae080e7          	jalr	-1106(ra) # 8000052a <panic>
    panic("swapout: page is not in ram");
    80002984:	00007517          	auipc	a0,0x7
    80002988:	97c50513          	addi	a0,a0,-1668 # 80009300 <digits+0x2c0>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	b9e080e7          	jalr	-1122(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    80002994:	00007517          	auipc	a0,0x7
    80002998:	98c50513          	addi	a0,a0,-1652 # 80009320 <digits+0x2e0>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	b8e080e7          	jalr	-1138(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    800029a4:	00007517          	auipc	a0,0x7
    800029a8:	99450513          	addi	a0,a0,-1644 # 80009338 <digits+0x2f8>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	b7e080e7          	jalr	-1154(ra) # 8000052a <panic>

00000000800029b4 <swapin>:

void swapin(int disk_index, int ram_index)
{
    800029b4:	7139                	addi	sp,sp,-64
    800029b6:	fc06                	sd	ra,56(sp)
    800029b8:	f822                	sd	s0,48(sp)
    800029ba:	f426                	sd	s1,40(sp)
    800029bc:	f04a                	sd	s2,32(sp)
    800029be:	ec4e                	sd	s3,24(sp)
    800029c0:	e852                	sd	s4,16(sp)
    800029c2:	e456                	sd	s5,8(sp)
    800029c4:	0080                	addi	s0,sp,64
  if (disk_index < 0 || disk_index >= MAX_DISK_PAGES) {
    800029c6:	47bd                	li	a5,15
    800029c8:	0aa7ed63          	bltu	a5,a0,80002a82 <swapin+0xce>
    800029cc:	89ae                	mv	s3,a1
    800029ce:	892a                	mv	s2,a0
    panic("swapin: disk index out of bounds");
  }

  if (ram_index < 0 || ram_index >= MAX_PSYC_PAGES) {
    800029d0:	0005879b          	sext.w	a5,a1
    800029d4:	473d                	li	a4,15
    800029d6:	0af76e63          	bltu	a4,a5,80002a92 <swapin+0xde>
    panic("swapin: ram index out of bounds");
  }
  struct proc *p = myproc();
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	ffa080e7          	jalr	-6(ra) # 800019d4 <myproc>
    800029e2:	8aaa                	mv	s5,a0
  struct disk_page *disk_pg = &p->disk_pages[disk_index]; 

  if (!disk_pg->used) {
    800029e4:	0912                	slli	s2,s2,0x4
    800029e6:	992a                	add	s2,s2,a0
    800029e8:	27c92783          	lw	a5,636(s2)
    800029ec:	cbdd                	beqz	a5,80002aa2 <swapin+0xee>
    panic("swapin: page unused");
  }

  pte_t *pte;
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    800029ee:	4601                	li	a2,0
    800029f0:	27093583          	ld	a1,624(s2)
    800029f4:	6928                	ld	a0,80(a0)
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	5b0080e7          	jalr	1456(ra) # 80000fa6 <walk>
    800029fe:	8a2a                	mv	s4,a0
    80002a00:	c94d                	beqz	a0,80002ab2 <swapin+0xfe>
    panic("swapin: unallocated pte");
  }

  if ((*pte & PTE_V) || !(*pte & PTE_PG))
    80002a02:	611c                	ld	a5,0(a0)
    80002a04:	2017f793          	andi	a5,a5,513
    80002a08:	20000713          	li	a4,512
    80002a0c:	0ae79b63          	bne	a5,a4,80002ac2 <swapin+0x10e>
      panic("swapin: page is not in disk");

  struct ram_page *ram_pg = &p->ram_pages[ram_index];
  if (ram_pg->used) {
    80002a10:	0992                	slli	s3,s3,0x4
    80002a12:	99d6                	add	s3,s3,s5
    80002a14:	17c9a783          	lw	a5,380(s3)
    80002a18:	efcd                	bnez	a5,80002ad2 <swapin+0x11e>
    panic("swapin: ram page used");
  }

  uint64 npa;
  if ( (npa = (uint64)kalloc()) == 0 ) {
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	0b8080e7          	jalr	184(ra) # 80000ad2 <kalloc>
    80002a22:	84aa                	mv	s1,a0
    80002a24:	cd5d                	beqz	a0,80002ae2 <swapin+0x12e>
    panic("swapin: failed alocate physical address");
  }

  if (readFromSwapFile(p, (char *)npa, disk_pg->offset, PGSIZE) < 0) {
    80002a26:	6685                	lui	a3,0x1
    80002a28:	27892603          	lw	a2,632(s2)
    80002a2c:	85aa                	mv	a1,a0
    80002a2e:	8556                	mv	a0,s5
    80002a30:	00002097          	auipc	ra,0x2
    80002a34:	058080e7          	jalr	88(ra) # 80004a88 <readFromSwapFile>
    80002a38:	0a054d63          	bltz	a0,80002af2 <swapin+0x13e>
    panic("swapin: read from disk failed");
  }

  ram_pg->used = 1;
    80002a3c:	4785                	li	a5,1
    80002a3e:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    80002a42:	27093783          	ld	a5,624(s2)
    80002a46:	16f9b823          	sd	a5,368(s3)
  // ADDED Q2
  #ifdef LAPA
    ram_pg->age = 0xFFFFFFFF;
  #endif
  #ifndef LAPA 
    ram_pg->age = 0;
    80002a4a:	1609ac23          	sw	zero,376(s3)
  #endif

  disk_pg->va = 0;
    80002a4e:	26093823          	sd	zero,624(s2)
  disk_pg->used = 0;
    80002a52:	26092e23          	sw	zero,636(s2)

  *pte = *pte | PTE_V;                           
  *pte = *pte & ~PTE_PG;                         
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    80002a56:	80b1                	srli	s1,s1,0xc
    80002a58:	04aa                	slli	s1,s1,0xa
    80002a5a:	000a3783          	ld	a5,0(s4)
    80002a5e:	1ff7f793          	andi	a5,a5,511
    80002a62:	8cdd                	or	s1,s1,a5
    80002a64:	0014e493          	ori	s1,s1,1
    80002a68:	009a3023          	sd	s1,0(s4)
    80002a6c:	12000073          	sfence.vma
  sfence_vma(); // clear TLB
}
    80002a70:	70e2                	ld	ra,56(sp)
    80002a72:	7442                	ld	s0,48(sp)
    80002a74:	74a2                	ld	s1,40(sp)
    80002a76:	7902                	ld	s2,32(sp)
    80002a78:	69e2                	ld	s3,24(sp)
    80002a7a:	6a42                	ld	s4,16(sp)
    80002a7c:	6aa2                	ld	s5,8(sp)
    80002a7e:	6121                	addi	sp,sp,64
    80002a80:	8082                	ret
    panic("swapin: disk index out of bounds");
    80002a82:	00007517          	auipc	a0,0x7
    80002a86:	8de50513          	addi	a0,a0,-1826 # 80009360 <digits+0x320>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	aa0080e7          	jalr	-1376(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    80002a92:	00007517          	auipc	a0,0x7
    80002a96:	8f650513          	addi	a0,a0,-1802 # 80009388 <digits+0x348>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	a90080e7          	jalr	-1392(ra) # 8000052a <panic>
    panic("swapin: page unused");
    80002aa2:	00007517          	auipc	a0,0x7
    80002aa6:	90650513          	addi	a0,a0,-1786 # 800093a8 <digits+0x368>
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	a80080e7          	jalr	-1408(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    80002ab2:	00007517          	auipc	a0,0x7
    80002ab6:	90e50513          	addi	a0,a0,-1778 # 800093c0 <digits+0x380>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	a70080e7          	jalr	-1424(ra) # 8000052a <panic>
      panic("swapin: page is not in disk");
    80002ac2:	00007517          	auipc	a0,0x7
    80002ac6:	91650513          	addi	a0,a0,-1770 # 800093d8 <digits+0x398>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	a60080e7          	jalr	-1440(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    80002ad2:	00007517          	auipc	a0,0x7
    80002ad6:	92650513          	addi	a0,a0,-1754 # 800093f8 <digits+0x3b8>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	a50080e7          	jalr	-1456(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    80002ae2:	00007517          	auipc	a0,0x7
    80002ae6:	92e50513          	addi	a0,a0,-1746 # 80009410 <digits+0x3d0>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	a40080e7          	jalr	-1472(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002af2:	00007517          	auipc	a0,0x7
    80002af6:	94650513          	addi	a0,a0,-1722 # 80009438 <digits+0x3f8>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a30080e7          	jalr	-1488(ra) # 8000052a <panic>

0000000080002b02 <get_unused_ram_index>:

int get_unused_ram_index(struct proc* p)
{
    80002b02:	1141                	addi	sp,sp,-16
    80002b04:	e422                	sd	s0,8(sp)
    80002b06:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002b08:	17c50793          	addi	a5,a0,380
    80002b0c:	4501                	li	a0,0
    80002b0e:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    80002b10:	4398                	lw	a4,0(a5)
    80002b12:	c711                	beqz	a4,80002b1e <get_unused_ram_index+0x1c>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002b14:	2505                	addiw	a0,a0,1
    80002b16:	07c1                	addi	a5,a5,16
    80002b18:	fed51ce3          	bne	a0,a3,80002b10 <get_unused_ram_index+0xe>
      return i;
    }
  }
  return -1;
    80002b1c:	557d                	li	a0,-1
}
    80002b1e:	6422                	ld	s0,8(sp)
    80002b20:	0141                	addi	sp,sp,16
    80002b22:	8082                	ret

0000000080002b24 <get_disk_page_index>:

int get_disk_page_index(struct proc *p, uint64 va)
{
    80002b24:	1141                	addi	sp,sp,-16
    80002b26:	e422                	sd	s0,8(sp)
    80002b28:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002b2a:	27050793          	addi	a5,a0,624
    80002b2e:	4501                	li	a0,0
    80002b30:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    80002b32:	6398                	ld	a4,0(a5)
    80002b34:	00b70763          	beq	a4,a1,80002b42 <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002b38:	2505                	addiw	a0,a0,1
    80002b3a:	07c1                	addi	a5,a5,16
    80002b3c:	fed51be3          	bne	a0,a3,80002b32 <get_disk_page_index+0xe>
      return i;
    }
  }
  return -1;
    80002b40:	557d                	li	a0,-1
}
    80002b42:	6422                	ld	s0,8(sp)
    80002b44:	0141                	addi	sp,sp,16
    80002b46:	8082                	ret

0000000080002b48 <remove_page_from_ram>:
    ram_pg->age = 0;
  #endif
}

void remove_page_from_ram(uint64 va)
{
    80002b48:	1101                	addi	sp,sp,-32
    80002b4a:	ec06                	sd	ra,24(sp)
    80002b4c:	e822                	sd	s0,16(sp)
    80002b4e:	e426                	sd	s1,8(sp)
    80002b50:	1000                	addi	s0,sp,32
    80002b52:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	e80080e7          	jalr	-384(ra) # 800019d4 <myproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002b5c:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002b5e:	37fd                	addiw	a5,a5,-1
    80002b60:	4705                	li	a4,1
    80002b62:	02f77863          	bgeu	a4,a5,80002b92 <remove_page_from_ram+0x4a>
    80002b66:	17050793          	addi	a5,a0,368
    return;
  }
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002b6a:	4701                	li	a4,0
    80002b6c:	4641                	li	a2,16
    80002b6e:	a029                	j	80002b78 <remove_page_from_ram+0x30>
    80002b70:	2705                	addiw	a4,a4,1
    80002b72:	07c1                	addi	a5,a5,16
    80002b74:	02c70463          	beq	a4,a2,80002b9c <remove_page_from_ram+0x54>
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
    80002b78:	6394                	ld	a3,0(a5)
    80002b7a:	fe969be3          	bne	a3,s1,80002b70 <remove_page_from_ram+0x28>
    80002b7e:	47d4                	lw	a3,12(a5)
    80002b80:	dae5                	beqz	a3,80002b70 <remove_page_from_ram+0x28>
      p->ram_pages[i].va = 0;
    80002b82:	0712                	slli	a4,a4,0x4
    80002b84:	972a                	add	a4,a4,a0
    80002b86:	16073823          	sd	zero,368(a4)
      p->ram_pages[i].used = 0;
    80002b8a:	16072e23          	sw	zero,380(a4)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002b8e:	16072c23          	sw	zero,376(a4)
      p->disk_pages[i].used = 0;
      return;
    }
  }
  panic("remove_page_from_ram failed");
}
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret
    80002b9c:	27050793          	addi	a5,a0,624
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002ba0:	4701                	li	a4,0
    80002ba2:	4641                	li	a2,16
    80002ba4:	a029                	j	80002bae <remove_page_from_ram+0x66>
    80002ba6:	2705                	addiw	a4,a4,1
    80002ba8:	07c1                	addi	a5,a5,16
    80002baa:	00c70e63          	beq	a4,a2,80002bc6 <remove_page_from_ram+0x7e>
    if (p->disk_pages[i].va == va && p->disk_pages[i].used) {
    80002bae:	6394                	ld	a3,0(a5)
    80002bb0:	fe969be3          	bne	a3,s1,80002ba6 <remove_page_from_ram+0x5e>
    80002bb4:	47d4                	lw	a3,12(a5)
    80002bb6:	dae5                	beqz	a3,80002ba6 <remove_page_from_ram+0x5e>
      p->disk_pages[i].va = 0;
    80002bb8:	0712                	slli	a4,a4,0x4
    80002bba:	972a                	add	a4,a4,a0
    80002bbc:	26073823          	sd	zero,624(a4)
      p->disk_pages[i].used = 0;
    80002bc0:	26072e23          	sw	zero,636(a4)
      return;
    80002bc4:	b7f9                	j	80002b92 <remove_page_from_ram+0x4a>
  panic("remove_page_from_ram failed");
    80002bc6:	00007517          	auipc	a0,0x7
    80002bca:	89250513          	addi	a0,a0,-1902 # 80009458 <digits+0x418>
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	95c080e7          	jalr	-1700(ra) # 8000052a <panic>

0000000080002bd6 <nfua>:

// ADDED Q2
int nfua()
{
    80002bd6:	1141                	addi	sp,sp,-16
    80002bd8:	e406                	sd	ra,8(sp)
    80002bda:	e022                	sd	s0,0(sp)
    80002bdc:	0800                	addi	s0,sp,16
  int i = 0;
  int min_index = 0;
  uint min_age = 0xFFFFFFFF;
  struct proc *p = myproc();
    80002bde:	fffff097          	auipc	ra,0xfffff
    80002be2:	df6080e7          	jalr	-522(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002be6:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002bea:	567d                	li	a2,-1
  int min_index = 0;
    80002bec:	4501                	li	a0,0
  int i = 0;
    80002bee:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bf0:	45c1                	li	a1,16
    80002bf2:	a029                	j	80002bfc <nfua+0x26>
    80002bf4:	0741                	addi	a4,a4,16
    80002bf6:	2785                	addiw	a5,a5,1
    80002bf8:	00b78863          	beq	a5,a1,80002c08 <nfua+0x32>
    if(ram_pg->age <= min_age){
    80002bfc:	4714                	lw	a3,8(a4)
    80002bfe:	fed66be3          	bltu	a2,a3,80002bf4 <nfua+0x1e>
      min_index = i;
      min_age = ram_pg->age;
    80002c02:	8636                	mv	a2,a3
    if(ram_pg->age <= min_age){
    80002c04:	853e                	mv	a0,a5
    80002c06:	b7fd                	j	80002bf4 <nfua+0x1e>
    }
  }
  return min_index;
}
    80002c08:	60a2                	ld	ra,8(sp)
    80002c0a:	6402                	ld	s0,0(sp)
    80002c0c:	0141                	addi	sp,sp,16
    80002c0e:	8082                	ret

0000000080002c10 <count_ones>:

int count_ones(uint num) 
{
    80002c10:	1141                	addi	sp,sp,-16
    80002c12:	e422                	sd	s0,8(sp)
    80002c14:	0800                	addi	s0,sp,16
  int count = 0;
  while(num > 0){
    80002c16:	c105                	beqz	a0,80002c36 <count_ones+0x26>
    80002c18:	87aa                	mv	a5,a0
  int count = 0;
    80002c1a:	4501                	li	a0,0
  while(num > 0){
    80002c1c:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002c1e:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002c22:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002c24:	0007871b          	sext.w	a4,a5
    80002c28:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002c2c:	fee6e9e3          	bltu	a3,a4,80002c1e <count_ones+0xe>
  }
  return count;
}
    80002c30:	6422                	ld	s0,8(sp)
    80002c32:	0141                	addi	sp,sp,16
    80002c34:	8082                	ret
  int count = 0;
    80002c36:	4501                	li	a0,0
    80002c38:	bfe5                	j	80002c30 <count_ones+0x20>

0000000080002c3a <lapa>:

int lapa()
{
    80002c3a:	715d                	addi	sp,sp,-80
    80002c3c:	e486                	sd	ra,72(sp)
    80002c3e:	e0a2                	sd	s0,64(sp)
    80002c40:	fc26                	sd	s1,56(sp)
    80002c42:	f84a                	sd	s2,48(sp)
    80002c44:	f44e                	sd	s3,40(sp)
    80002c46:	f052                	sd	s4,32(sp)
    80002c48:	ec56                	sd	s5,24(sp)
    80002c4a:	e85a                	sd	s6,16(sp)
    80002c4c:	e45e                	sd	s7,8(sp)
    80002c4e:	0880                	addi	s0,sp,80
  int i = 0;
  int min_index = 0;
  uint min_age = 0xFFFFFFFF;
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	d84080e7          	jalr	-636(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c58:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002c5c:	5afd                	li	s5,-1
  int min_index = 0;
    80002c5e:	4b81                	li	s7,0
  int i = 0;
    80002c60:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c62:	4b41                	li	s6,16
    80002c64:	a039                	j	80002c72 <lapa+0x38>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    int min_age_ones = count_ones(min_age);
    if (ram_pg_age_ones < min_age_ones) {
      min_index = i;
      min_age = ram_pg->age;
    80002c66:	8ad2                	mv	s5,s4
    80002c68:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c6a:	09c1                	addi	s3,s3,16
    80002c6c:	2905                	addiw	s2,s2,1
    80002c6e:	03690863          	beq	s2,s6,80002c9e <lapa+0x64>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002c72:	0089aa03          	lw	s4,8(s3)
    80002c76:	8552                	mv	a0,s4
    80002c78:	00000097          	auipc	ra,0x0
    80002c7c:	f98080e7          	jalr	-104(ra) # 80002c10 <count_ones>
    80002c80:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002c82:	8556                	mv	a0,s5
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	f8c080e7          	jalr	-116(ra) # 80002c10 <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002c8c:	fca4cde3          	blt	s1,a0,80002c66 <lapa+0x2c>
    }
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c90:	fca49de3          	bne	s1,a0,80002c6a <lapa+0x30>
    80002c94:	fd5a7be3          	bgeu	s4,s5,80002c6a <lapa+0x30>
      min_index = i;
      min_age = ram_pg->age;
    80002c98:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c9a:	8bca                	mv	s7,s2
    80002c9c:	b7f9                	j	80002c6a <lapa+0x30>
    }
  }
  return min_index;
}
    80002c9e:	855e                	mv	a0,s7
    80002ca0:	60a6                	ld	ra,72(sp)
    80002ca2:	6406                	ld	s0,64(sp)
    80002ca4:	74e2                	ld	s1,56(sp)
    80002ca6:	7942                	ld	s2,48(sp)
    80002ca8:	79a2                	ld	s3,40(sp)
    80002caa:	7a02                	ld	s4,32(sp)
    80002cac:	6ae2                	ld	s5,24(sp)
    80002cae:	6b42                	ld	s6,16(sp)
    80002cb0:	6ba2                	ld	s7,8(sp)
    80002cb2:	6161                	addi	sp,sp,80
    80002cb4:	8082                	ret

0000000080002cb6 <scfifo>:

int scfifo()
{
    80002cb6:	1101                	addi	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	e426                	sd	s1,8(sp)
    80002cbe:	e04a                	sd	s2,0(sp)
    80002cc0:	1000                	addi	s0,sp,32
  struct ram_page *cur_ram_pg;
  struct proc *p = myproc();
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	d12080e7          	jalr	-750(ra) # 800019d4 <myproc>
    80002cca:	892a                	mv	s2,a0
  int index = p->scfifo_index;
    80002ccc:	37052483          	lw	s1,880(a0)
  while(1){
    cur_ram_pg = &p->ram_pages[index];

    pte_t *pte;
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
    80002cd0:	01748793          	addi	a5,s1,23
    80002cd4:	0792                	slli	a5,a5,0x4
    80002cd6:	97ca                	add	a5,a5,s2
    80002cd8:	4601                	li	a2,0
    80002cda:	638c                	ld	a1,0(a5)
    80002cdc:	05093503          	ld	a0,80(s2)
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	2c6080e7          	jalr	710(ra) # 80000fa6 <walk>
    80002ce8:	c10d                	beqz	a0,80002d0a <scfifo+0x54>
      panic("scfifo: walk failed");
    }
    
    if(*pte & PTE_A){
    80002cea:	611c                	ld	a5,0(a0)
    80002cec:	0407f713          	andi	a4,a5,64
    80002cf0:	c70d                	beqz	a4,80002d1a <scfifo+0x64>
      *pte = *pte & ~PTE_A;
    80002cf2:	fbf7f793          	andi	a5,a5,-65
    80002cf6:	e11c                	sd	a5,0(a0)
      index = (index + 1) % MAX_PSYC_PAGES;
    80002cf8:	2485                	addiw	s1,s1,1
    80002cfa:	41f4d79b          	sraiw	a5,s1,0x1f
    80002cfe:	01c7d79b          	srliw	a5,a5,0x1c
    80002d02:	9cbd                	addw	s1,s1,a5
    80002d04:	88bd                	andi	s1,s1,15
    80002d06:	9c9d                	subw	s1,s1,a5
  while(1){
    80002d08:	b7e1                	j	80002cd0 <scfifo+0x1a>
      panic("scfifo: walk failed");
    80002d0a:	00006517          	auipc	a0,0x6
    80002d0e:	76e50513          	addi	a0,a0,1902 # 80009478 <digits+0x438>
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	818080e7          	jalr	-2024(ra) # 8000052a <panic>
    }
    else{
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
    80002d1a:	0014879b          	addiw	a5,s1,1
    80002d1e:	41f7d71b          	sraiw	a4,a5,0x1f
    80002d22:	01c7571b          	srliw	a4,a4,0x1c
    80002d26:	9fb9                	addw	a5,a5,a4
    80002d28:	8bbd                	andi	a5,a5,15
    80002d2a:	9f99                	subw	a5,a5,a4
    80002d2c:	36f92823          	sw	a5,880(s2)
      return index;
    }
  }
}
    80002d30:	8526                	mv	a0,s1
    80002d32:	60e2                	ld	ra,24(sp)
    80002d34:	6442                	ld	s0,16(sp)
    80002d36:	64a2                	ld	s1,8(sp)
    80002d38:	6902                	ld	s2,0(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <insert_page_to_ram>:
{
    80002d3e:	7179                	addi	sp,sp,-48
    80002d40:	f406                	sd	ra,40(sp)
    80002d42:	f022                	sd	s0,32(sp)
    80002d44:	ec26                	sd	s1,24(sp)
    80002d46:	e84a                	sd	s2,16(sp)
    80002d48:	e44e                	sd	s3,8(sp)
    80002d4a:	1800                	addi	s0,sp,48
    80002d4c:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	c86080e7          	jalr	-890(ra) # 800019d4 <myproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002d56:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002d58:	37fd                	addiw	a5,a5,-1
    80002d5a:	4705                	li	a4,1
    80002d5c:	02f77363          	bgeu	a4,a5,80002d82 <insert_page_to_ram+0x44>
    80002d60:	84aa                	mv	s1,a0
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	da0080e7          	jalr	-608(ra) # 80002b02 <get_unused_ram_index>
    80002d6a:	892a                	mv	s2,a0
    80002d6c:	02054263          	bltz	a0,80002d90 <insert_page_to_ram+0x52>
  ram_pg->va = va;
    80002d70:	0912                	slli	s2,s2,0x4
    80002d72:	94ca                	add	s1,s1,s2
    80002d74:	1734b823          	sd	s3,368(s1)
  ram_pg->used = 1;
    80002d78:	4785                	li	a5,1
    80002d7a:	16f4ae23          	sw	a5,380(s1)
    ram_pg->age = 0;
    80002d7e:	1604ac23          	sw	zero,376(s1)
}
    80002d82:	70a2                	ld	ra,40(sp)
    80002d84:	7402                	ld	s0,32(sp)
    80002d86:	64e2                	ld	s1,24(sp)
    80002d88:	6942                	ld	s2,16(sp)
    80002d8a:	69a2                	ld	s3,8(sp)
    80002d8c:	6145                	addi	sp,sp,48
    80002d8e:	8082                	ret
  #ifdef LAPA
    return lapa();
  #endif

  #ifdef SCFIFO
    return scfifo();
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	f26080e7          	jalr	-218(ra) # 80002cb6 <scfifo>
    80002d98:	892a                	mv	s2,a0
    swapout(ram_pg_index_to_swap);
    80002d9a:	00000097          	auipc	ra,0x0
    80002d9e:	af2080e7          	jalr	-1294(ra) # 8000288c <swapout>
    unused_ram_pg_index = ram_pg_index_to_swap;
    80002da2:	b7f9                	j	80002d70 <insert_page_to_ram+0x32>

0000000080002da4 <handle_page_fault>:
{
    80002da4:	7179                	addi	sp,sp,-48
    80002da6:	f406                	sd	ra,40(sp)
    80002da8:	f022                	sd	s0,32(sp)
    80002daa:	ec26                	sd	s1,24(sp)
    80002dac:	e84a                	sd	s2,16(sp)
    80002dae:	e44e                	sd	s3,8(sp)
    80002db0:	1800                	addi	s0,sp,48
    80002db2:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	c20080e7          	jalr	-992(ra) # 800019d4 <myproc>
    80002dbc:	892a                	mv	s2,a0
  if (!(pte = walk(p->pagetable, va, 0))) {
    80002dbe:	4601                	li	a2,0
    80002dc0:	85ce                	mv	a1,s3
    80002dc2:	6928                	ld	a0,80(a0)
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	1e2080e7          	jalr	482(ra) # 80000fa6 <walk>
    80002dcc:	c531                	beqz	a0,80002e18 <handle_page_fault+0x74>
  if(*pte & PTE_V){
    80002dce:	611c                	ld	a5,0(a0)
    80002dd0:	0017f713          	andi	a4,a5,1
    80002dd4:	eb31                	bnez	a4,80002e28 <handle_page_fault+0x84>
  if(!(*pte & PTE_PG)) {
    80002dd6:	2007f793          	andi	a5,a5,512
    80002dda:	cfb9                	beqz	a5,80002e38 <handle_page_fault+0x94>
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {   
    80002ddc:	854a                	mv	a0,s2
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	d24080e7          	jalr	-732(ra) # 80002b02 <get_unused_ram_index>
    80002de6:	84aa                	mv	s1,a0
    80002de8:	06054063          	bltz	a0,80002e48 <handle_page_fault+0xa4>
  if( (target_index = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002dec:	75fd                	lui	a1,0xfffff
    80002dee:	00b9f5b3          	and	a1,s3,a1
    80002df2:	854a                	mv	a0,s2
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	d30080e7          	jalr	-720(ra) # 80002b24 <get_disk_page_index>
    80002dfc:	06054963          	bltz	a0,80002e6e <handle_page_fault+0xca>
  swapin(target_index, unused_ram_pg_index);
    80002e00:	85a6                	mv	a1,s1
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	bb2080e7          	jalr	-1102(ra) # 800029b4 <swapin>
}
    80002e0a:	70a2                	ld	ra,40(sp)
    80002e0c:	7402                	ld	s0,32(sp)
    80002e0e:	64e2                	ld	s1,24(sp)
    80002e10:	6942                	ld	s2,16(sp)
    80002e12:	69a2                	ld	s3,8(sp)
    80002e14:	6145                	addi	sp,sp,48
    80002e16:	8082                	ret
    panic("handle_page_fault: walk failed");
    80002e18:	00006517          	auipc	a0,0x6
    80002e1c:	67850513          	addi	a0,a0,1656 # 80009490 <digits+0x450>
    80002e20:	ffffd097          	auipc	ra,0xffffd
    80002e24:	70a080e7          	jalr	1802(ra) # 8000052a <panic>
    panic("handle_page_fault: invalid pte");
    80002e28:	00006517          	auipc	a0,0x6
    80002e2c:	68850513          	addi	a0,a0,1672 # 800094b0 <digits+0x470>
    80002e30:	ffffd097          	auipc	ra,0xffffd
    80002e34:	6fa080e7          	jalr	1786(ra) # 8000052a <panic>
    panic("handle_page_fault: PTE_PG off");
    80002e38:	00006517          	auipc	a0,0x6
    80002e3c:	69850513          	addi	a0,a0,1688 # 800094d0 <digits+0x490>
    80002e40:	ffffd097          	auipc	ra,0xffffd
    80002e44:	6ea080e7          	jalr	1770(ra) # 8000052a <panic>
    return scfifo();
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	e6e080e7          	jalr	-402(ra) # 80002cb6 <scfifo>
    80002e50:	84aa                	mv	s1,a0
      swapout(ram_pg_index_to_swap);
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	a3a080e7          	jalr	-1478(ra) # 8000288c <swapout>
      printf("handle_page_fault: replace index %d\n", unused_ram_pg_index); // ADDED Q3
    80002e5a:	85a6                	mv	a1,s1
    80002e5c:	00006517          	auipc	a0,0x6
    80002e60:	69450513          	addi	a0,a0,1684 # 800094f0 <digits+0x4b0>
    80002e64:	ffffd097          	auipc	ra,0xffffd
    80002e68:	710080e7          	jalr	1808(ra) # 80000574 <printf>
    80002e6c:	b741                	j	80002dec <handle_page_fault+0x48>
    panic("handle_page_fault: get_disk_page_index failed");
    80002e6e:	00006517          	auipc	a0,0x6
    80002e72:	6aa50513          	addi	a0,a0,1706 # 80009518 <digits+0x4d8>
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	6b4080e7          	jalr	1716(ra) # 8000052a <panic>

0000000080002e7e <index_page_to_swap>:
{
    80002e7e:	1141                	addi	sp,sp,-16
    80002e80:	e406                	sd	ra,8(sp)
    80002e82:	e022                	sd	s0,0(sp)
    80002e84:	0800                	addi	s0,sp,16
    return scfifo();
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	e30080e7          	jalr	-464(ra) # 80002cb6 <scfifo>

  #ifdef NONE
    return -1;
  #endif
  return -1;
}
    80002e8e:	60a2                	ld	ra,8(sp)
    80002e90:	6402                	ld	s0,0(sp)
    80002e92:	0141                	addi	sp,sp,16
    80002e94:	8082                	ret

0000000080002e96 <maintain_age>:

void maintain_age(struct proc *p){
    80002e96:	7179                	addi	sp,sp,-48
    80002e98:	f406                	sd	ra,40(sp)
    80002e9a:	f022                	sd	s0,32(sp)
    80002e9c:	ec26                	sd	s1,24(sp)
    80002e9e:	e84a                	sd	s2,16(sp)
    80002ea0:	e44e                	sd	s3,8(sp)
    80002ea2:	e052                	sd	s4,0(sp)
    80002ea4:	1800                	addi	s0,sp,48
    80002ea6:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002ea8:	17050493          	addi	s1,a0,368
    80002eac:	27050993          	addi	s3,a0,624
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
      panic("maintain_age: walk failed");
    }
    ram_pg->age = (ram_pg->age >> 1);
    if (*pte & PTE_A){
      ram_pg->age = ram_pg->age | (1 << 31);
    80002eb0:	80000a37          	lui	s4,0x80000
    80002eb4:	a821                	j	80002ecc <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002eb6:	00006517          	auipc	a0,0x6
    80002eba:	69250513          	addi	a0,a0,1682 # 80009548 <digits+0x508>
    80002ebe:	ffffd097          	auipc	ra,0xffffd
    80002ec2:	66c080e7          	jalr	1644(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002ec6:	04c1                	addi	s1,s1,16
    80002ec8:	02998b63          	beq	s3,s1,80002efe <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002ecc:	4601                	li	a2,0
    80002ece:	608c                	ld	a1,0(s1)
    80002ed0:	05093503          	ld	a0,80(s2)
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	0d2080e7          	jalr	210(ra) # 80000fa6 <walk>
    80002edc:	dd69                	beqz	a0,80002eb6 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002ede:	449c                	lw	a5,8(s1)
    80002ee0:	0017d79b          	srliw	a5,a5,0x1
    80002ee4:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002ee6:	6118                	ld	a4,0(a0)
    80002ee8:	04077713          	andi	a4,a4,64
    80002eec:	df69                	beqz	a4,80002ec6 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002eee:	0147e7b3          	or	a5,a5,s4
    80002ef2:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002ef4:	611c                	ld	a5,0(a0)
    80002ef6:	fbf7f793          	andi	a5,a5,-65
    80002efa:	e11c                	sd	a5,0(a0)
    80002efc:	b7e9                	j	80002ec6 <maintain_age+0x30>
    }
  }
    80002efe:	70a2                	ld	ra,40(sp)
    80002f00:	7402                	ld	s0,32(sp)
    80002f02:	64e2                	ld	s1,24(sp)
    80002f04:	6942                	ld	s2,16(sp)
    80002f06:	69a2                	ld	s3,8(sp)
    80002f08:	6a02                	ld	s4,0(sp)
    80002f0a:	6145                	addi	sp,sp,48
    80002f0c:	8082                	ret

0000000080002f0e <swtch>:
    80002f0e:	00153023          	sd	ra,0(a0)
    80002f12:	00253423          	sd	sp,8(a0)
    80002f16:	e900                	sd	s0,16(a0)
    80002f18:	ed04                	sd	s1,24(a0)
    80002f1a:	03253023          	sd	s2,32(a0)
    80002f1e:	03353423          	sd	s3,40(a0)
    80002f22:	03453823          	sd	s4,48(a0)
    80002f26:	03553c23          	sd	s5,56(a0)
    80002f2a:	05653023          	sd	s6,64(a0)
    80002f2e:	05753423          	sd	s7,72(a0)
    80002f32:	05853823          	sd	s8,80(a0)
    80002f36:	05953c23          	sd	s9,88(a0)
    80002f3a:	07a53023          	sd	s10,96(a0)
    80002f3e:	07b53423          	sd	s11,104(a0)
    80002f42:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80002f46:	0085b103          	ld	sp,8(a1)
    80002f4a:	6980                	ld	s0,16(a1)
    80002f4c:	6d84                	ld	s1,24(a1)
    80002f4e:	0205b903          	ld	s2,32(a1)
    80002f52:	0285b983          	ld	s3,40(a1)
    80002f56:	0305ba03          	ld	s4,48(a1)
    80002f5a:	0385ba83          	ld	s5,56(a1)
    80002f5e:	0405bb03          	ld	s6,64(a1)
    80002f62:	0485bb83          	ld	s7,72(a1)
    80002f66:	0505bc03          	ld	s8,80(a1)
    80002f6a:	0585bc83          	ld	s9,88(a1)
    80002f6e:	0605bd03          	ld	s10,96(a1)
    80002f72:	0685bd83          	ld	s11,104(a1)
    80002f76:	8082                	ret

0000000080002f78 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f78:	1141                	addi	sp,sp,-16
    80002f7a:	e406                	sd	ra,8(sp)
    80002f7c:	e022                	sd	s0,0(sp)
    80002f7e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f80:	00006597          	auipc	a1,0x6
    80002f84:	64058593          	addi	a1,a1,1600 # 800095c0 <states.0+0x30>
    80002f88:	0001d517          	auipc	a0,0x1d
    80002f8c:	54850513          	addi	a0,a0,1352 # 800204d0 <tickslock>
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	ba2080e7          	jalr	-1118(ra) # 80000b32 <initlock>
}
    80002f98:	60a2                	ld	ra,8(sp)
    80002f9a:	6402                	ld	s0,0(sp)
    80002f9c:	0141                	addi	sp,sp,16
    80002f9e:	8082                	ret

0000000080002fa0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002fa0:	1141                	addi	sp,sp,-16
    80002fa2:	e422                	sd	s0,8(sp)
    80002fa4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fa6:	00004797          	auipc	a5,0x4
    80002faa:	aca78793          	addi	a5,a5,-1334 # 80006a70 <kernelvec>
    80002fae:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002fb2:	6422                	ld	s0,8(sp)
    80002fb4:	0141                	addi	sp,sp,16
    80002fb6:	8082                	ret

0000000080002fb8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002fb8:	1141                	addi	sp,sp,-16
    80002fba:	e406                	sd	ra,8(sp)
    80002fbc:	e022                	sd	s0,0(sp)
    80002fbe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	a14080e7          	jalr	-1516(ra) # 800019d4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fcc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fce:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002fd2:	00005617          	auipc	a2,0x5
    80002fd6:	02e60613          	addi	a2,a2,46 # 80008000 <_trampoline>
    80002fda:	00005697          	auipc	a3,0x5
    80002fde:	02668693          	addi	a3,a3,38 # 80008000 <_trampoline>
    80002fe2:	8e91                	sub	a3,a3,a2
    80002fe4:	040007b7          	lui	a5,0x4000
    80002fe8:	17fd                	addi	a5,a5,-1
    80002fea:	07b2                	slli	a5,a5,0xc
    80002fec:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fee:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ff2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ff4:	180026f3          	csrr	a3,satp
    80002ff8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ffa:	6d38                	ld	a4,88(a0)
    80002ffc:	6134                	ld	a3,64(a0)
    80002ffe:	6585                	lui	a1,0x1
    80003000:	96ae                	add	a3,a3,a1
    80003002:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003004:	6d38                	ld	a4,88(a0)
    80003006:	00000697          	auipc	a3,0x0
    8000300a:	13868693          	addi	a3,a3,312 # 8000313e <usertrap>
    8000300e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003010:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003012:	8692                	mv	a3,tp
    80003014:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003016:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000301a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000301e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003022:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003026:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003028:	6f18                	ld	a4,24(a4)
    8000302a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000302e:	692c                	ld	a1,80(a0)
    80003030:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003032:	00005717          	auipc	a4,0x5
    80003036:	05e70713          	addi	a4,a4,94 # 80008090 <userret>
    8000303a:	8f11                	sub	a4,a4,a2
    8000303c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000303e:	577d                	li	a4,-1
    80003040:	177e                	slli	a4,a4,0x3f
    80003042:	8dd9                	or	a1,a1,a4
    80003044:	02000537          	lui	a0,0x2000
    80003048:	157d                	addi	a0,a0,-1
    8000304a:	0536                	slli	a0,a0,0xd
    8000304c:	9782                	jalr	a5
}
    8000304e:	60a2                	ld	ra,8(sp)
    80003050:	6402                	ld	s0,0(sp)
    80003052:	0141                	addi	sp,sp,16
    80003054:	8082                	ret

0000000080003056 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	e426                	sd	s1,8(sp)
    8000305e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003060:	0001d497          	auipc	s1,0x1d
    80003064:	47048493          	addi	s1,s1,1136 # 800204d0 <tickslock>
    80003068:	8526                	mv	a0,s1
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	b58080e7          	jalr	-1192(ra) # 80000bc2 <acquire>
  ticks++;
    80003072:	00007517          	auipc	a0,0x7
    80003076:	fbe50513          	addi	a0,a0,-66 # 8000a030 <ticks>
    8000307a:	411c                	lw	a5,0(a0)
    8000307c:	2785                	addiw	a5,a5,1
    8000307e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	04e080e7          	jalr	78(ra) # 800020ce <wakeup>
  release(&tickslock);
    80003088:	8526                	mv	a0,s1
    8000308a:	ffffe097          	auipc	ra,0xffffe
    8000308e:	bec080e7          	jalr	-1044(ra) # 80000c76 <release>
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	64a2                	ld	s1,8(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000309c:	1101                	addi	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	e426                	sd	s1,8(sp)
    800030a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030a6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800030aa:	00074d63          	bltz	a4,800030c4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800030ae:	57fd                	li	a5,-1
    800030b0:	17fe                	slli	a5,a5,0x3f
    800030b2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800030b4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800030b6:	06f70363          	beq	a4,a5,8000311c <devintr+0x80>
  }
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6105                	addi	sp,sp,32
    800030c2:	8082                	ret
     (scause & 0xff) == 9){
    800030c4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800030c8:	46a5                	li	a3,9
    800030ca:	fed792e3          	bne	a5,a3,800030ae <devintr+0x12>
    int irq = plic_claim();
    800030ce:	00004097          	auipc	ra,0x4
    800030d2:	aaa080e7          	jalr	-1366(ra) # 80006b78 <plic_claim>
    800030d6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800030d8:	47a9                	li	a5,10
    800030da:	02f50763          	beq	a0,a5,80003108 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800030de:	4785                	li	a5,1
    800030e0:	02f50963          	beq	a0,a5,80003112 <devintr+0x76>
    return 1;
    800030e4:	4505                	li	a0,1
    } else if(irq){
    800030e6:	d8f1                	beqz	s1,800030ba <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800030e8:	85a6                	mv	a1,s1
    800030ea:	00006517          	auipc	a0,0x6
    800030ee:	4de50513          	addi	a0,a0,1246 # 800095c8 <states.0+0x38>
    800030f2:	ffffd097          	auipc	ra,0xffffd
    800030f6:	482080e7          	jalr	1154(ra) # 80000574 <printf>
      plic_complete(irq);
    800030fa:	8526                	mv	a0,s1
    800030fc:	00004097          	auipc	ra,0x4
    80003100:	aa0080e7          	jalr	-1376(ra) # 80006b9c <plic_complete>
    return 1;
    80003104:	4505                	li	a0,1
    80003106:	bf55                	j	800030ba <devintr+0x1e>
      uartintr();
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	87e080e7          	jalr	-1922(ra) # 80000986 <uartintr>
    80003110:	b7ed                	j	800030fa <devintr+0x5e>
      virtio_disk_intr();
    80003112:	00004097          	auipc	ra,0x4
    80003116:	f1c080e7          	jalr	-228(ra) # 8000702e <virtio_disk_intr>
    8000311a:	b7c5                	j	800030fa <devintr+0x5e>
    if(cpuid() == 0){
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	88c080e7          	jalr	-1908(ra) # 800019a8 <cpuid>
    80003124:	c901                	beqz	a0,80003134 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003126:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000312a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000312c:	14479073          	csrw	sip,a5
    return 2;
    80003130:	4509                	li	a0,2
    80003132:	b761                	j	800030ba <devintr+0x1e>
      clockintr();
    80003134:	00000097          	auipc	ra,0x0
    80003138:	f22080e7          	jalr	-222(ra) # 80003056 <clockintr>
    8000313c:	b7ed                	j	80003126 <devintr+0x8a>

000000008000313e <usertrap>:
{
    8000313e:	1101                	addi	sp,sp,-32
    80003140:	ec06                	sd	ra,24(sp)
    80003142:	e822                	sd	s0,16(sp)
    80003144:	e426                	sd	s1,8(sp)
    80003146:	e04a                	sd	s2,0(sp)
    80003148:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000314a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000314e:	1007f793          	andi	a5,a5,256
    80003152:	e3ad                	bnez	a5,800031b4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003154:	00004797          	auipc	a5,0x4
    80003158:	91c78793          	addi	a5,a5,-1764 # 80006a70 <kernelvec>
    8000315c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003160:	fffff097          	auipc	ra,0xfffff
    80003164:	874080e7          	jalr	-1932(ra) # 800019d4 <myproc>
    80003168:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000316a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000316c:	14102773          	csrr	a4,sepc
    80003170:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003172:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003176:	47a1                	li	a5,8
    80003178:	04f71c63          	bne	a4,a5,800031d0 <usertrap+0x92>
    if(p->killed)
    8000317c:	551c                	lw	a5,40(a0)
    8000317e:	e3b9                	bnez	a5,800031c4 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003180:	6cb8                	ld	a4,88(s1)
    80003182:	6f1c                	ld	a5,24(a4)
    80003184:	0791                	addi	a5,a5,4
    80003186:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003188:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000318c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003190:	10079073          	csrw	sstatus,a5
    syscall();
    80003194:	00000097          	auipc	ra,0x0
    80003198:	318080e7          	jalr	792(ra) # 800034ac <syscall>
  if(p->killed)
    8000319c:	549c                	lw	a5,40(s1)
    8000319e:	ebc5                	bnez	a5,8000324e <usertrap+0x110>
  usertrapret();
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	e18080e7          	jalr	-488(ra) # 80002fb8 <usertrapret>
}
    800031a8:	60e2                	ld	ra,24(sp)
    800031aa:	6442                	ld	s0,16(sp)
    800031ac:	64a2                	ld	s1,8(sp)
    800031ae:	6902                	ld	s2,0(sp)
    800031b0:	6105                	addi	sp,sp,32
    800031b2:	8082                	ret
    panic("usertrap: not from user mode");
    800031b4:	00006517          	auipc	a0,0x6
    800031b8:	43450513          	addi	a0,a0,1076 # 800095e8 <states.0+0x58>
    800031bc:	ffffd097          	auipc	ra,0xffffd
    800031c0:	36e080e7          	jalr	878(ra) # 8000052a <panic>
      exit(-1);
    800031c4:	557d                	li	a0,-1
    800031c6:	fffff097          	auipc	ra,0xfffff
    800031ca:	46a080e7          	jalr	1130(ra) # 80002630 <exit>
    800031ce:	bf4d                	j	80003180 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	ecc080e7          	jalr	-308(ra) # 8000309c <devintr>
    800031d8:	892a                	mv	s2,a0
    800031da:	c501                	beqz	a0,800031e2 <usertrap+0xa4>
  if(p->killed)
    800031dc:	549c                	lw	a5,40(s1)
    800031de:	cfb5                	beqz	a5,8000325a <usertrap+0x11c>
    800031e0:	a885                	j	80003250 <usertrap+0x112>
  } else if (relevant_metadata_proc(p) && 
    800031e2:	8526                	mv	a0,s1
    800031e4:	fffff097          	auipc	ra,0xfffff
    800031e8:	bbe080e7          	jalr	-1090(ra) # 80001da2 <relevant_metadata_proc>
    800031ec:	c105                	beqz	a0,8000320c <usertrap+0xce>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031ee:	14202773          	csrr	a4,scause
    800031f2:	47b1                	li	a5,12
    800031f4:	04f70663          	beq	a4,a5,80003240 <usertrap+0x102>
    800031f8:	14202773          	csrr	a4,scause
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    800031fc:	47b5                	li	a5,13
    800031fe:	04f70163          	beq	a4,a5,80003240 <usertrap+0x102>
    80003202:	14202773          	csrr	a4,scause
    80003206:	47bd                	li	a5,15
    80003208:	02f70c63          	beq	a4,a5,80003240 <usertrap+0x102>
    8000320c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003210:	5890                	lw	a2,48(s1)
    80003212:	00006517          	auipc	a0,0x6
    80003216:	3f650513          	addi	a0,a0,1014 # 80009608 <states.0+0x78>
    8000321a:	ffffd097          	auipc	ra,0xffffd
    8000321e:	35a080e7          	jalr	858(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003222:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003226:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000322a:	00006517          	auipc	a0,0x6
    8000322e:	40e50513          	addi	a0,a0,1038 # 80009638 <states.0+0xa8>
    80003232:	ffffd097          	auipc	ra,0xffffd
    80003236:	342080e7          	jalr	834(ra) # 80000574 <printf>
    p->killed = 1;
    8000323a:	4785                	li	a5,1
    8000323c:	d49c                	sw	a5,40(s1)
  if(p->killed)
    8000323e:	a809                	j	80003250 <usertrap+0x112>
    80003240:	14302573          	csrr	a0,stval
      handle_page_fault(va);  
    80003244:	00000097          	auipc	ra,0x0
    80003248:	b60080e7          	jalr	-1184(ra) # 80002da4 <handle_page_fault>
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    8000324c:	bf81                	j	8000319c <usertrap+0x5e>
  if(p->killed)
    8000324e:	4901                	li	s2,0
    exit(-1);
    80003250:	557d                	li	a0,-1
    80003252:	fffff097          	auipc	ra,0xfffff
    80003256:	3de080e7          	jalr	990(ra) # 80002630 <exit>
  if(which_dev == 2)
    8000325a:	4789                	li	a5,2
    8000325c:	f4f912e3          	bne	s2,a5,800031a0 <usertrap+0x62>
    yield();
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	dce080e7          	jalr	-562(ra) # 8000202e <yield>
    80003268:	bf25                	j	800031a0 <usertrap+0x62>

000000008000326a <kerneltrap>:
{
    8000326a:	7179                	addi	sp,sp,-48
    8000326c:	f406                	sd	ra,40(sp)
    8000326e:	f022                	sd	s0,32(sp)
    80003270:	ec26                	sd	s1,24(sp)
    80003272:	e84a                	sd	s2,16(sp)
    80003274:	e44e                	sd	s3,8(sp)
    80003276:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003278:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000327c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003280:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003284:	1004f793          	andi	a5,s1,256
    80003288:	cb85                	beqz	a5,800032b8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000328a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000328e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003290:	ef85                	bnez	a5,800032c8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003292:	00000097          	auipc	ra,0x0
    80003296:	e0a080e7          	jalr	-502(ra) # 8000309c <devintr>
    8000329a:	cd1d                	beqz	a0,800032d8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000329c:	4789                	li	a5,2
    8000329e:	06f50a63          	beq	a0,a5,80003312 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032a2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032a6:	10049073          	csrw	sstatus,s1
}
    800032aa:	70a2                	ld	ra,40(sp)
    800032ac:	7402                	ld	s0,32(sp)
    800032ae:	64e2                	ld	s1,24(sp)
    800032b0:	6942                	ld	s2,16(sp)
    800032b2:	69a2                	ld	s3,8(sp)
    800032b4:	6145                	addi	sp,sp,48
    800032b6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032b8:	00006517          	auipc	a0,0x6
    800032bc:	3a050513          	addi	a0,a0,928 # 80009658 <states.0+0xc8>
    800032c0:	ffffd097          	auipc	ra,0xffffd
    800032c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800032c8:	00006517          	auipc	a0,0x6
    800032cc:	3b850513          	addi	a0,a0,952 # 80009680 <states.0+0xf0>
    800032d0:	ffffd097          	auipc	ra,0xffffd
    800032d4:	25a080e7          	jalr	602(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800032d8:	85ce                	mv	a1,s3
    800032da:	00006517          	auipc	a0,0x6
    800032de:	3c650513          	addi	a0,a0,966 # 800096a0 <states.0+0x110>
    800032e2:	ffffd097          	auipc	ra,0xffffd
    800032e6:	292080e7          	jalr	658(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032ea:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032ee:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032f2:	00006517          	auipc	a0,0x6
    800032f6:	3be50513          	addi	a0,a0,958 # 800096b0 <states.0+0x120>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	27a080e7          	jalr	634(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003302:	00006517          	auipc	a0,0x6
    80003306:	3c650513          	addi	a0,a0,966 # 800096c8 <states.0+0x138>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	220080e7          	jalr	544(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	6c2080e7          	jalr	1730(ra) # 800019d4 <myproc>
    8000331a:	d541                	beqz	a0,800032a2 <kerneltrap+0x38>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	6b8080e7          	jalr	1720(ra) # 800019d4 <myproc>
    80003324:	4d18                	lw	a4,24(a0)
    80003326:	4791                	li	a5,4
    80003328:	f6f71de3          	bne	a4,a5,800032a2 <kerneltrap+0x38>
    yield();
    8000332c:	fffff097          	auipc	ra,0xfffff
    80003330:	d02080e7          	jalr	-766(ra) # 8000202e <yield>
    80003334:	b7bd                	j	800032a2 <kerneltrap+0x38>

0000000080003336 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	e426                	sd	s1,8(sp)
    8000333e:	1000                	addi	s0,sp,32
    80003340:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	692080e7          	jalr	1682(ra) # 800019d4 <myproc>
  switch (n) {
    8000334a:	4795                	li	a5,5
    8000334c:	0497e163          	bltu	a5,s1,8000338e <argraw+0x58>
    80003350:	048a                	slli	s1,s1,0x2
    80003352:	00006717          	auipc	a4,0x6
    80003356:	3ae70713          	addi	a4,a4,942 # 80009700 <states.0+0x170>
    8000335a:	94ba                	add	s1,s1,a4
    8000335c:	409c                	lw	a5,0(s1)
    8000335e:	97ba                	add	a5,a5,a4
    80003360:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003362:	6d3c                	ld	a5,88(a0)
    80003364:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	64a2                	ld	s1,8(sp)
    8000336c:	6105                	addi	sp,sp,32
    8000336e:	8082                	ret
    return p->trapframe->a1;
    80003370:	6d3c                	ld	a5,88(a0)
    80003372:	7fa8                	ld	a0,120(a5)
    80003374:	bfcd                	j	80003366 <argraw+0x30>
    return p->trapframe->a2;
    80003376:	6d3c                	ld	a5,88(a0)
    80003378:	63c8                	ld	a0,128(a5)
    8000337a:	b7f5                	j	80003366 <argraw+0x30>
    return p->trapframe->a3;
    8000337c:	6d3c                	ld	a5,88(a0)
    8000337e:	67c8                	ld	a0,136(a5)
    80003380:	b7dd                	j	80003366 <argraw+0x30>
    return p->trapframe->a4;
    80003382:	6d3c                	ld	a5,88(a0)
    80003384:	6bc8                	ld	a0,144(a5)
    80003386:	b7c5                	j	80003366 <argraw+0x30>
    return p->trapframe->a5;
    80003388:	6d3c                	ld	a5,88(a0)
    8000338a:	6fc8                	ld	a0,152(a5)
    8000338c:	bfe9                	j	80003366 <argraw+0x30>
  panic("argraw");
    8000338e:	00006517          	auipc	a0,0x6
    80003392:	34a50513          	addi	a0,a0,842 # 800096d8 <states.0+0x148>
    80003396:	ffffd097          	auipc	ra,0xffffd
    8000339a:	194080e7          	jalr	404(ra) # 8000052a <panic>

000000008000339e <fetchaddr>:
{
    8000339e:	1101                	addi	sp,sp,-32
    800033a0:	ec06                	sd	ra,24(sp)
    800033a2:	e822                	sd	s0,16(sp)
    800033a4:	e426                	sd	s1,8(sp)
    800033a6:	e04a                	sd	s2,0(sp)
    800033a8:	1000                	addi	s0,sp,32
    800033aa:	84aa                	mv	s1,a0
    800033ac:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033ae:	ffffe097          	auipc	ra,0xffffe
    800033b2:	626080e7          	jalr	1574(ra) # 800019d4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033b6:	653c                	ld	a5,72(a0)
    800033b8:	02f4f863          	bgeu	s1,a5,800033e8 <fetchaddr+0x4a>
    800033bc:	00848713          	addi	a4,s1,8
    800033c0:	02e7e663          	bltu	a5,a4,800033ec <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033c4:	46a1                	li	a3,8
    800033c6:	8626                	mv	a2,s1
    800033c8:	85ca                	mv	a1,s2
    800033ca:	6928                	ld	a0,80(a0)
    800033cc:	ffffe097          	auipc	ra,0xffffe
    800033d0:	354080e7          	jalr	852(ra) # 80001720 <copyin>
    800033d4:	00a03533          	snez	a0,a0
    800033d8:	40a00533          	neg	a0,a0
}
    800033dc:	60e2                	ld	ra,24(sp)
    800033de:	6442                	ld	s0,16(sp)
    800033e0:	64a2                	ld	s1,8(sp)
    800033e2:	6902                	ld	s2,0(sp)
    800033e4:	6105                	addi	sp,sp,32
    800033e6:	8082                	ret
    return -1;
    800033e8:	557d                	li	a0,-1
    800033ea:	bfcd                	j	800033dc <fetchaddr+0x3e>
    800033ec:	557d                	li	a0,-1
    800033ee:	b7fd                	j	800033dc <fetchaddr+0x3e>

00000000800033f0 <fetchstr>:
{
    800033f0:	7179                	addi	sp,sp,-48
    800033f2:	f406                	sd	ra,40(sp)
    800033f4:	f022                	sd	s0,32(sp)
    800033f6:	ec26                	sd	s1,24(sp)
    800033f8:	e84a                	sd	s2,16(sp)
    800033fa:	e44e                	sd	s3,8(sp)
    800033fc:	1800                	addi	s0,sp,48
    800033fe:	892a                	mv	s2,a0
    80003400:	84ae                	mv	s1,a1
    80003402:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	5d0080e7          	jalr	1488(ra) # 800019d4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000340c:	86ce                	mv	a3,s3
    8000340e:	864a                	mv	a2,s2
    80003410:	85a6                	mv	a1,s1
    80003412:	6928                	ld	a0,80(a0)
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	39a080e7          	jalr	922(ra) # 800017ae <copyinstr>
  if(err < 0)
    8000341c:	00054763          	bltz	a0,8000342a <fetchstr+0x3a>
  return strlen(buf);
    80003420:	8526                	mv	a0,s1
    80003422:	ffffe097          	auipc	ra,0xffffe
    80003426:	a20080e7          	jalr	-1504(ra) # 80000e42 <strlen>
}
    8000342a:	70a2                	ld	ra,40(sp)
    8000342c:	7402                	ld	s0,32(sp)
    8000342e:	64e2                	ld	s1,24(sp)
    80003430:	6942                	ld	s2,16(sp)
    80003432:	69a2                	ld	s3,8(sp)
    80003434:	6145                	addi	sp,sp,48
    80003436:	8082                	ret

0000000080003438 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003438:	1101                	addi	sp,sp,-32
    8000343a:	ec06                	sd	ra,24(sp)
    8000343c:	e822                	sd	s0,16(sp)
    8000343e:	e426                	sd	s1,8(sp)
    80003440:	1000                	addi	s0,sp,32
    80003442:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003444:	00000097          	auipc	ra,0x0
    80003448:	ef2080e7          	jalr	-270(ra) # 80003336 <argraw>
    8000344c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000344e:	4501                	li	a0,0
    80003450:	60e2                	ld	ra,24(sp)
    80003452:	6442                	ld	s0,16(sp)
    80003454:	64a2                	ld	s1,8(sp)
    80003456:	6105                	addi	sp,sp,32
    80003458:	8082                	ret

000000008000345a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000345a:	1101                	addi	sp,sp,-32
    8000345c:	ec06                	sd	ra,24(sp)
    8000345e:	e822                	sd	s0,16(sp)
    80003460:	e426                	sd	s1,8(sp)
    80003462:	1000                	addi	s0,sp,32
    80003464:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	ed0080e7          	jalr	-304(ra) # 80003336 <argraw>
    8000346e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003470:	4501                	li	a0,0
    80003472:	60e2                	ld	ra,24(sp)
    80003474:	6442                	ld	s0,16(sp)
    80003476:	64a2                	ld	s1,8(sp)
    80003478:	6105                	addi	sp,sp,32
    8000347a:	8082                	ret

000000008000347c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000347c:	1101                	addi	sp,sp,-32
    8000347e:	ec06                	sd	ra,24(sp)
    80003480:	e822                	sd	s0,16(sp)
    80003482:	e426                	sd	s1,8(sp)
    80003484:	e04a                	sd	s2,0(sp)
    80003486:	1000                	addi	s0,sp,32
    80003488:	84ae                	mv	s1,a1
    8000348a:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	eaa080e7          	jalr	-342(ra) # 80003336 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003494:	864a                	mv	a2,s2
    80003496:	85a6                	mv	a1,s1
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	f58080e7          	jalr	-168(ra) # 800033f0 <fetchstr>
}
    800034a0:	60e2                	ld	ra,24(sp)
    800034a2:	6442                	ld	s0,16(sp)
    800034a4:	64a2                	ld	s1,8(sp)
    800034a6:	6902                	ld	s2,0(sp)
    800034a8:	6105                	addi	sp,sp,32
    800034aa:	8082                	ret

00000000800034ac <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800034ac:	1101                	addi	sp,sp,-32
    800034ae:	ec06                	sd	ra,24(sp)
    800034b0:	e822                	sd	s0,16(sp)
    800034b2:	e426                	sd	s1,8(sp)
    800034b4:	e04a                	sd	s2,0(sp)
    800034b6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034b8:	ffffe097          	auipc	ra,0xffffe
    800034bc:	51c080e7          	jalr	1308(ra) # 800019d4 <myproc>
    800034c0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034c2:	05853903          	ld	s2,88(a0)
    800034c6:	0a893783          	ld	a5,168(s2)
    800034ca:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800034ce:	37fd                	addiw	a5,a5,-1
    800034d0:	4751                	li	a4,20
    800034d2:	00f76f63          	bltu	a4,a5,800034f0 <syscall+0x44>
    800034d6:	00369713          	slli	a4,a3,0x3
    800034da:	00006797          	auipc	a5,0x6
    800034de:	23e78793          	addi	a5,a5,574 # 80009718 <syscalls>
    800034e2:	97ba                	add	a5,a5,a4
    800034e4:	639c                	ld	a5,0(a5)
    800034e6:	c789                	beqz	a5,800034f0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800034e8:	9782                	jalr	a5
    800034ea:	06a93823          	sd	a0,112(s2)
    800034ee:	a839                	j	8000350c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800034f0:	15848613          	addi	a2,s1,344
    800034f4:	588c                	lw	a1,48(s1)
    800034f6:	00006517          	auipc	a0,0x6
    800034fa:	1ea50513          	addi	a0,a0,490 # 800096e0 <states.0+0x150>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	076080e7          	jalr	118(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003506:	6cbc                	ld	a5,88(s1)
    80003508:	577d                	li	a4,-1
    8000350a:	fbb8                	sd	a4,112(a5)
  }
}
    8000350c:	60e2                	ld	ra,24(sp)
    8000350e:	6442                	ld	s0,16(sp)
    80003510:	64a2                	ld	s1,8(sp)
    80003512:	6902                	ld	s2,0(sp)
    80003514:	6105                	addi	sp,sp,32
    80003516:	8082                	ret

0000000080003518 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003518:	1101                	addi	sp,sp,-32
    8000351a:	ec06                	sd	ra,24(sp)
    8000351c:	e822                	sd	s0,16(sp)
    8000351e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003520:	fec40593          	addi	a1,s0,-20
    80003524:	4501                	li	a0,0
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	f12080e7          	jalr	-238(ra) # 80003438 <argint>
    return -1;
    8000352e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003530:	00054963          	bltz	a0,80003542 <sys_exit+0x2a>
  exit(n);
    80003534:	fec42503          	lw	a0,-20(s0)
    80003538:	fffff097          	auipc	ra,0xfffff
    8000353c:	0f8080e7          	jalr	248(ra) # 80002630 <exit>
  return 0;  // not reached
    80003540:	4781                	li	a5,0
}
    80003542:	853e                	mv	a0,a5
    80003544:	60e2                	ld	ra,24(sp)
    80003546:	6442                	ld	s0,16(sp)
    80003548:	6105                	addi	sp,sp,32
    8000354a:	8082                	ret

000000008000354c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000354c:	1141                	addi	sp,sp,-16
    8000354e:	e406                	sd	ra,8(sp)
    80003550:	e022                	sd	s0,0(sp)
    80003552:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003554:	ffffe097          	auipc	ra,0xffffe
    80003558:	480080e7          	jalr	1152(ra) # 800019d4 <myproc>
}
    8000355c:	5908                	lw	a0,48(a0)
    8000355e:	60a2                	ld	ra,8(sp)
    80003560:	6402                	ld	s0,0(sp)
    80003562:	0141                	addi	sp,sp,16
    80003564:	8082                	ret

0000000080003566 <sys_fork>:

uint64
sys_fork(void)
{
    80003566:	1141                	addi	sp,sp,-16
    80003568:	e406                	sd	ra,8(sp)
    8000356a:	e022                	sd	s0,0(sp)
    8000356c:	0800                	addi	s0,sp,16
  return fork();
    8000356e:	fffff097          	auipc	ra,0xfffff
    80003572:	eda080e7          	jalr	-294(ra) # 80002448 <fork>
}
    80003576:	60a2                	ld	ra,8(sp)
    80003578:	6402                	ld	s0,0(sp)
    8000357a:	0141                	addi	sp,sp,16
    8000357c:	8082                	ret

000000008000357e <sys_wait>:

uint64
sys_wait(void)
{
    8000357e:	1101                	addi	sp,sp,-32
    80003580:	ec06                	sd	ra,24(sp)
    80003582:	e822                	sd	s0,16(sp)
    80003584:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003586:	fe840593          	addi	a1,s0,-24
    8000358a:	4501                	li	a0,0
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	ece080e7          	jalr	-306(ra) # 8000345a <argaddr>
    80003594:	87aa                	mv	a5,a0
    return -1;
    80003596:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003598:	0007c863          	bltz	a5,800035a8 <sys_wait+0x2a>
  return wait(p);
    8000359c:	fe843503          	ld	a0,-24(s0)
    800035a0:	fffff097          	auipc	ra,0xfffff
    800035a4:	17e080e7          	jalr	382(ra) # 8000271e <wait>
}
    800035a8:	60e2                	ld	ra,24(sp)
    800035aa:	6442                	ld	s0,16(sp)
    800035ac:	6105                	addi	sp,sp,32
    800035ae:	8082                	ret

00000000800035b0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035b0:	7179                	addi	sp,sp,-48
    800035b2:	f406                	sd	ra,40(sp)
    800035b4:	f022                	sd	s0,32(sp)
    800035b6:	ec26                	sd	s1,24(sp)
    800035b8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800035ba:	fdc40593          	addi	a1,s0,-36
    800035be:	4501                	li	a0,0
    800035c0:	00000097          	auipc	ra,0x0
    800035c4:	e78080e7          	jalr	-392(ra) # 80003438 <argint>
    return -1;
    800035c8:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800035ca:	00054f63          	bltz	a0,800035e8 <sys_sbrk+0x38>
  addr = myproc()->sz;
    800035ce:	ffffe097          	auipc	ra,0xffffe
    800035d2:	406080e7          	jalr	1030(ra) # 800019d4 <myproc>
    800035d6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800035d8:	fdc42503          	lw	a0,-36(s0)
    800035dc:	ffffe097          	auipc	ra,0xffffe
    800035e0:	752080e7          	jalr	1874(ra) # 80001d2e <growproc>
    800035e4:	00054863          	bltz	a0,800035f4 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800035e8:	8526                	mv	a0,s1
    800035ea:	70a2                	ld	ra,40(sp)
    800035ec:	7402                	ld	s0,32(sp)
    800035ee:	64e2                	ld	s1,24(sp)
    800035f0:	6145                	addi	sp,sp,48
    800035f2:	8082                	ret
    return -1;
    800035f4:	54fd                	li	s1,-1
    800035f6:	bfcd                	j	800035e8 <sys_sbrk+0x38>

00000000800035f8 <sys_sleep>:

uint64
sys_sleep(void)
{
    800035f8:	7139                	addi	sp,sp,-64
    800035fa:	fc06                	sd	ra,56(sp)
    800035fc:	f822                	sd	s0,48(sp)
    800035fe:	f426                	sd	s1,40(sp)
    80003600:	f04a                	sd	s2,32(sp)
    80003602:	ec4e                	sd	s3,24(sp)
    80003604:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003606:	fcc40593          	addi	a1,s0,-52
    8000360a:	4501                	li	a0,0
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	e2c080e7          	jalr	-468(ra) # 80003438 <argint>
    return -1;
    80003614:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003616:	06054563          	bltz	a0,80003680 <sys_sleep+0x88>
  acquire(&tickslock);
    8000361a:	0001d517          	auipc	a0,0x1d
    8000361e:	eb650513          	addi	a0,a0,-330 # 800204d0 <tickslock>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	5a0080e7          	jalr	1440(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000362a:	00007917          	auipc	s2,0x7
    8000362e:	a0692903          	lw	s2,-1530(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    80003632:	fcc42783          	lw	a5,-52(s0)
    80003636:	cf85                	beqz	a5,8000366e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003638:	0001d997          	auipc	s3,0x1d
    8000363c:	e9898993          	addi	s3,s3,-360 # 800204d0 <tickslock>
    80003640:	00007497          	auipc	s1,0x7
    80003644:	9f048493          	addi	s1,s1,-1552 # 8000a030 <ticks>
    if(myproc()->killed){
    80003648:	ffffe097          	auipc	ra,0xffffe
    8000364c:	38c080e7          	jalr	908(ra) # 800019d4 <myproc>
    80003650:	551c                	lw	a5,40(a0)
    80003652:	ef9d                	bnez	a5,80003690 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003654:	85ce                	mv	a1,s3
    80003656:	8526                	mv	a0,s1
    80003658:	fffff097          	auipc	ra,0xfffff
    8000365c:	a12080e7          	jalr	-1518(ra) # 8000206a <sleep>
  while(ticks - ticks0 < n){
    80003660:	409c                	lw	a5,0(s1)
    80003662:	412787bb          	subw	a5,a5,s2
    80003666:	fcc42703          	lw	a4,-52(s0)
    8000366a:	fce7efe3          	bltu	a5,a4,80003648 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000366e:	0001d517          	auipc	a0,0x1d
    80003672:	e6250513          	addi	a0,a0,-414 # 800204d0 <tickslock>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	600080e7          	jalr	1536(ra) # 80000c76 <release>
  return 0;
    8000367e:	4781                	li	a5,0
}
    80003680:	853e                	mv	a0,a5
    80003682:	70e2                	ld	ra,56(sp)
    80003684:	7442                	ld	s0,48(sp)
    80003686:	74a2                	ld	s1,40(sp)
    80003688:	7902                	ld	s2,32(sp)
    8000368a:	69e2                	ld	s3,24(sp)
    8000368c:	6121                	addi	sp,sp,64
    8000368e:	8082                	ret
      release(&tickslock);
    80003690:	0001d517          	auipc	a0,0x1d
    80003694:	e4050513          	addi	a0,a0,-448 # 800204d0 <tickslock>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	5de080e7          	jalr	1502(ra) # 80000c76 <release>
      return -1;
    800036a0:	57fd                	li	a5,-1
    800036a2:	bff9                	j	80003680 <sys_sleep+0x88>

00000000800036a4 <sys_kill>:

uint64
sys_kill(void)
{
    800036a4:	1101                	addi	sp,sp,-32
    800036a6:	ec06                	sd	ra,24(sp)
    800036a8:	e822                	sd	s0,16(sp)
    800036aa:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800036ac:	fec40593          	addi	a1,s0,-20
    800036b0:	4501                	li	a0,0
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	d86080e7          	jalr	-634(ra) # 80003438 <argint>
    800036ba:	87aa                	mv	a5,a0
    return -1;
    800036bc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800036be:	0007c863          	bltz	a5,800036ce <sys_kill+0x2a>
  return kill(pid);
    800036c2:	fec42503          	lw	a0,-20(s0)
    800036c6:	fffff097          	auipc	ra,0xfffff
    800036ca:	ad8080e7          	jalr	-1320(ra) # 8000219e <kill>
}
    800036ce:	60e2                	ld	ra,24(sp)
    800036d0:	6442                	ld	s0,16(sp)
    800036d2:	6105                	addi	sp,sp,32
    800036d4:	8082                	ret

00000000800036d6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036d6:	1101                	addi	sp,sp,-32
    800036d8:	ec06                	sd	ra,24(sp)
    800036da:	e822                	sd	s0,16(sp)
    800036dc:	e426                	sd	s1,8(sp)
    800036de:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036e0:	0001d517          	auipc	a0,0x1d
    800036e4:	df050513          	addi	a0,a0,-528 # 800204d0 <tickslock>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	4da080e7          	jalr	1242(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800036f0:	00007497          	auipc	s1,0x7
    800036f4:	9404a483          	lw	s1,-1728(s1) # 8000a030 <ticks>
  release(&tickslock);
    800036f8:	0001d517          	auipc	a0,0x1d
    800036fc:	dd850513          	addi	a0,a0,-552 # 800204d0 <tickslock>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	576080e7          	jalr	1398(ra) # 80000c76 <release>
  return xticks;
}
    80003708:	02049513          	slli	a0,s1,0x20
    8000370c:	9101                	srli	a0,a0,0x20
    8000370e:	60e2                	ld	ra,24(sp)
    80003710:	6442                	ld	s0,16(sp)
    80003712:	64a2                	ld	s1,8(sp)
    80003714:	6105                	addi	sp,sp,32
    80003716:	8082                	ret

0000000080003718 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003718:	7179                	addi	sp,sp,-48
    8000371a:	f406                	sd	ra,40(sp)
    8000371c:	f022                	sd	s0,32(sp)
    8000371e:	ec26                	sd	s1,24(sp)
    80003720:	e84a                	sd	s2,16(sp)
    80003722:	e44e                	sd	s3,8(sp)
    80003724:	e052                	sd	s4,0(sp)
    80003726:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003728:	00006597          	auipc	a1,0x6
    8000372c:	0a058593          	addi	a1,a1,160 # 800097c8 <syscalls+0xb0>
    80003730:	0001d517          	auipc	a0,0x1d
    80003734:	db850513          	addi	a0,a0,-584 # 800204e8 <bcache>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	3fa080e7          	jalr	1018(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003740:	00025797          	auipc	a5,0x25
    80003744:	da878793          	addi	a5,a5,-600 # 800284e8 <bcache+0x8000>
    80003748:	00025717          	auipc	a4,0x25
    8000374c:	00870713          	addi	a4,a4,8 # 80028750 <bcache+0x8268>
    80003750:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003754:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003758:	0001d497          	auipc	s1,0x1d
    8000375c:	da848493          	addi	s1,s1,-600 # 80020500 <bcache+0x18>
    b->next = bcache.head.next;
    80003760:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003762:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003764:	00006a17          	auipc	s4,0x6
    80003768:	06ca0a13          	addi	s4,s4,108 # 800097d0 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000376c:	2b893783          	ld	a5,696(s2)
    80003770:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003772:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003776:	85d2                	mv	a1,s4
    80003778:	01048513          	addi	a0,s1,16
    8000377c:	00001097          	auipc	ra,0x1
    80003780:	7d4080e7          	jalr	2004(ra) # 80004f50 <initsleeplock>
    bcache.head.next->prev = b;
    80003784:	2b893783          	ld	a5,696(s2)
    80003788:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000378a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000378e:	45848493          	addi	s1,s1,1112
    80003792:	fd349de3          	bne	s1,s3,8000376c <binit+0x54>
  }
}
    80003796:	70a2                	ld	ra,40(sp)
    80003798:	7402                	ld	s0,32(sp)
    8000379a:	64e2                	ld	s1,24(sp)
    8000379c:	6942                	ld	s2,16(sp)
    8000379e:	69a2                	ld	s3,8(sp)
    800037a0:	6a02                	ld	s4,0(sp)
    800037a2:	6145                	addi	sp,sp,48
    800037a4:	8082                	ret

00000000800037a6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800037a6:	7179                	addi	sp,sp,-48
    800037a8:	f406                	sd	ra,40(sp)
    800037aa:	f022                	sd	s0,32(sp)
    800037ac:	ec26                	sd	s1,24(sp)
    800037ae:	e84a                	sd	s2,16(sp)
    800037b0:	e44e                	sd	s3,8(sp)
    800037b2:	1800                	addi	s0,sp,48
    800037b4:	892a                	mv	s2,a0
    800037b6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800037b8:	0001d517          	auipc	a0,0x1d
    800037bc:	d3050513          	addi	a0,a0,-720 # 800204e8 <bcache>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	402080e7          	jalr	1026(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037c8:	00025497          	auipc	s1,0x25
    800037cc:	fd84b483          	ld	s1,-40(s1) # 800287a0 <bcache+0x82b8>
    800037d0:	00025797          	auipc	a5,0x25
    800037d4:	f8078793          	addi	a5,a5,-128 # 80028750 <bcache+0x8268>
    800037d8:	02f48f63          	beq	s1,a5,80003816 <bread+0x70>
    800037dc:	873e                	mv	a4,a5
    800037de:	a021                	j	800037e6 <bread+0x40>
    800037e0:	68a4                	ld	s1,80(s1)
    800037e2:	02e48a63          	beq	s1,a4,80003816 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800037e6:	449c                	lw	a5,8(s1)
    800037e8:	ff279ce3          	bne	a5,s2,800037e0 <bread+0x3a>
    800037ec:	44dc                	lw	a5,12(s1)
    800037ee:	ff3799e3          	bne	a5,s3,800037e0 <bread+0x3a>
      b->refcnt++;
    800037f2:	40bc                	lw	a5,64(s1)
    800037f4:	2785                	addiw	a5,a5,1
    800037f6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037f8:	0001d517          	auipc	a0,0x1d
    800037fc:	cf050513          	addi	a0,a0,-784 # 800204e8 <bcache>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	476080e7          	jalr	1142(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003808:	01048513          	addi	a0,s1,16
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	77e080e7          	jalr	1918(ra) # 80004f8a <acquiresleep>
      return b;
    80003814:	a8b9                	j	80003872 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003816:	00025497          	auipc	s1,0x25
    8000381a:	f824b483          	ld	s1,-126(s1) # 80028798 <bcache+0x82b0>
    8000381e:	00025797          	auipc	a5,0x25
    80003822:	f3278793          	addi	a5,a5,-206 # 80028750 <bcache+0x8268>
    80003826:	00f48863          	beq	s1,a5,80003836 <bread+0x90>
    8000382a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000382c:	40bc                	lw	a5,64(s1)
    8000382e:	cf81                	beqz	a5,80003846 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003830:	64a4                	ld	s1,72(s1)
    80003832:	fee49de3          	bne	s1,a4,8000382c <bread+0x86>
  panic("bget: no buffers");
    80003836:	00006517          	auipc	a0,0x6
    8000383a:	fa250513          	addi	a0,a0,-94 # 800097d8 <syscalls+0xc0>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	cec080e7          	jalr	-788(ra) # 8000052a <panic>
      b->dev = dev;
    80003846:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000384a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000384e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003852:	4785                	li	a5,1
    80003854:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003856:	0001d517          	auipc	a0,0x1d
    8000385a:	c9250513          	addi	a0,a0,-878 # 800204e8 <bcache>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	418080e7          	jalr	1048(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003866:	01048513          	addi	a0,s1,16
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	720080e7          	jalr	1824(ra) # 80004f8a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003872:	409c                	lw	a5,0(s1)
    80003874:	cb89                	beqz	a5,80003886 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003876:	8526                	mv	a0,s1
    80003878:	70a2                	ld	ra,40(sp)
    8000387a:	7402                	ld	s0,32(sp)
    8000387c:	64e2                	ld	s1,24(sp)
    8000387e:	6942                	ld	s2,16(sp)
    80003880:	69a2                	ld	s3,8(sp)
    80003882:	6145                	addi	sp,sp,48
    80003884:	8082                	ret
    virtio_disk_rw(b, 0);
    80003886:	4581                	li	a1,0
    80003888:	8526                	mv	a0,s1
    8000388a:	00003097          	auipc	ra,0x3
    8000388e:	51c080e7          	jalr	1308(ra) # 80006da6 <virtio_disk_rw>
    b->valid = 1;
    80003892:	4785                	li	a5,1
    80003894:	c09c                	sw	a5,0(s1)
  return b;
    80003896:	b7c5                	j	80003876 <bread+0xd0>

0000000080003898 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003898:	1101                	addi	sp,sp,-32
    8000389a:	ec06                	sd	ra,24(sp)
    8000389c:	e822                	sd	s0,16(sp)
    8000389e:	e426                	sd	s1,8(sp)
    800038a0:	1000                	addi	s0,sp,32
    800038a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038a4:	0541                	addi	a0,a0,16
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	77e080e7          	jalr	1918(ra) # 80005024 <holdingsleep>
    800038ae:	cd01                	beqz	a0,800038c6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800038b0:	4585                	li	a1,1
    800038b2:	8526                	mv	a0,s1
    800038b4:	00003097          	auipc	ra,0x3
    800038b8:	4f2080e7          	jalr	1266(ra) # 80006da6 <virtio_disk_rw>
}
    800038bc:	60e2                	ld	ra,24(sp)
    800038be:	6442                	ld	s0,16(sp)
    800038c0:	64a2                	ld	s1,8(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret
    panic("bwrite");
    800038c6:	00006517          	auipc	a0,0x6
    800038ca:	f2a50513          	addi	a0,a0,-214 # 800097f0 <syscalls+0xd8>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	c5c080e7          	jalr	-932(ra) # 8000052a <panic>

00000000800038d6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038d6:	1101                	addi	sp,sp,-32
    800038d8:	ec06                	sd	ra,24(sp)
    800038da:	e822                	sd	s0,16(sp)
    800038dc:	e426                	sd	s1,8(sp)
    800038de:	e04a                	sd	s2,0(sp)
    800038e0:	1000                	addi	s0,sp,32
    800038e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038e4:	01050913          	addi	s2,a0,16
    800038e8:	854a                	mv	a0,s2
    800038ea:	00001097          	auipc	ra,0x1
    800038ee:	73a080e7          	jalr	1850(ra) # 80005024 <holdingsleep>
    800038f2:	c92d                	beqz	a0,80003964 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800038f4:	854a                	mv	a0,s2
    800038f6:	00001097          	auipc	ra,0x1
    800038fa:	6ea080e7          	jalr	1770(ra) # 80004fe0 <releasesleep>

  acquire(&bcache.lock);
    800038fe:	0001d517          	auipc	a0,0x1d
    80003902:	bea50513          	addi	a0,a0,-1046 # 800204e8 <bcache>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	2bc080e7          	jalr	700(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000390e:	40bc                	lw	a5,64(s1)
    80003910:	37fd                	addiw	a5,a5,-1
    80003912:	0007871b          	sext.w	a4,a5
    80003916:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003918:	eb05                	bnez	a4,80003948 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000391a:	68bc                	ld	a5,80(s1)
    8000391c:	64b8                	ld	a4,72(s1)
    8000391e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003920:	64bc                	ld	a5,72(s1)
    80003922:	68b8                	ld	a4,80(s1)
    80003924:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003926:	00025797          	auipc	a5,0x25
    8000392a:	bc278793          	addi	a5,a5,-1086 # 800284e8 <bcache+0x8000>
    8000392e:	2b87b703          	ld	a4,696(a5)
    80003932:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003934:	00025717          	auipc	a4,0x25
    80003938:	e1c70713          	addi	a4,a4,-484 # 80028750 <bcache+0x8268>
    8000393c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000393e:	2b87b703          	ld	a4,696(a5)
    80003942:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003944:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003948:	0001d517          	auipc	a0,0x1d
    8000394c:	ba050513          	addi	a0,a0,-1120 # 800204e8 <bcache>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	326080e7          	jalr	806(ra) # 80000c76 <release>
}
    80003958:	60e2                	ld	ra,24(sp)
    8000395a:	6442                	ld	s0,16(sp)
    8000395c:	64a2                	ld	s1,8(sp)
    8000395e:	6902                	ld	s2,0(sp)
    80003960:	6105                	addi	sp,sp,32
    80003962:	8082                	ret
    panic("brelse");
    80003964:	00006517          	auipc	a0,0x6
    80003968:	e9450513          	addi	a0,a0,-364 # 800097f8 <syscalls+0xe0>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	bbe080e7          	jalr	-1090(ra) # 8000052a <panic>

0000000080003974 <bpin>:

void
bpin(struct buf *b) {
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	1000                	addi	s0,sp,32
    8000397e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003980:	0001d517          	auipc	a0,0x1d
    80003984:	b6850513          	addi	a0,a0,-1176 # 800204e8 <bcache>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	23a080e7          	jalr	570(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003990:	40bc                	lw	a5,64(s1)
    80003992:	2785                	addiw	a5,a5,1
    80003994:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003996:	0001d517          	auipc	a0,0x1d
    8000399a:	b5250513          	addi	a0,a0,-1198 # 800204e8 <bcache>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	2d8080e7          	jalr	728(ra) # 80000c76 <release>
}
    800039a6:	60e2                	ld	ra,24(sp)
    800039a8:	6442                	ld	s0,16(sp)
    800039aa:	64a2                	ld	s1,8(sp)
    800039ac:	6105                	addi	sp,sp,32
    800039ae:	8082                	ret

00000000800039b0 <bunpin>:

void
bunpin(struct buf *b) {
    800039b0:	1101                	addi	sp,sp,-32
    800039b2:	ec06                	sd	ra,24(sp)
    800039b4:	e822                	sd	s0,16(sp)
    800039b6:	e426                	sd	s1,8(sp)
    800039b8:	1000                	addi	s0,sp,32
    800039ba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039bc:	0001d517          	auipc	a0,0x1d
    800039c0:	b2c50513          	addi	a0,a0,-1236 # 800204e8 <bcache>
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	1fe080e7          	jalr	510(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800039cc:	40bc                	lw	a5,64(s1)
    800039ce:	37fd                	addiw	a5,a5,-1
    800039d0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039d2:	0001d517          	auipc	a0,0x1d
    800039d6:	b1650513          	addi	a0,a0,-1258 # 800204e8 <bcache>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	29c080e7          	jalr	668(ra) # 80000c76 <release>
}
    800039e2:	60e2                	ld	ra,24(sp)
    800039e4:	6442                	ld	s0,16(sp)
    800039e6:	64a2                	ld	s1,8(sp)
    800039e8:	6105                	addi	sp,sp,32
    800039ea:	8082                	ret

00000000800039ec <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800039ec:	1101                	addi	sp,sp,-32
    800039ee:	ec06                	sd	ra,24(sp)
    800039f0:	e822                	sd	s0,16(sp)
    800039f2:	e426                	sd	s1,8(sp)
    800039f4:	e04a                	sd	s2,0(sp)
    800039f6:	1000                	addi	s0,sp,32
    800039f8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800039fa:	00d5d59b          	srliw	a1,a1,0xd
    800039fe:	00025797          	auipc	a5,0x25
    80003a02:	1c67a783          	lw	a5,454(a5) # 80028bc4 <sb+0x1c>
    80003a06:	9dbd                	addw	a1,a1,a5
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	d9e080e7          	jalr	-610(ra) # 800037a6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a10:	0074f713          	andi	a4,s1,7
    80003a14:	4785                	li	a5,1
    80003a16:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a1a:	14ce                	slli	s1,s1,0x33
    80003a1c:	90d9                	srli	s1,s1,0x36
    80003a1e:	00950733          	add	a4,a0,s1
    80003a22:	05874703          	lbu	a4,88(a4)
    80003a26:	00e7f6b3          	and	a3,a5,a4
    80003a2a:	c69d                	beqz	a3,80003a58 <bfree+0x6c>
    80003a2c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a2e:	94aa                	add	s1,s1,a0
    80003a30:	fff7c793          	not	a5,a5
    80003a34:	8ff9                	and	a5,a5,a4
    80003a36:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a3a:	00001097          	auipc	ra,0x1
    80003a3e:	430080e7          	jalr	1072(ra) # 80004e6a <log_write>
  brelse(bp);
    80003a42:	854a                	mv	a0,s2
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	e92080e7          	jalr	-366(ra) # 800038d6 <brelse>
}
    80003a4c:	60e2                	ld	ra,24(sp)
    80003a4e:	6442                	ld	s0,16(sp)
    80003a50:	64a2                	ld	s1,8(sp)
    80003a52:	6902                	ld	s2,0(sp)
    80003a54:	6105                	addi	sp,sp,32
    80003a56:	8082                	ret
    panic("freeing free block");
    80003a58:	00006517          	auipc	a0,0x6
    80003a5c:	da850513          	addi	a0,a0,-600 # 80009800 <syscalls+0xe8>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	aca080e7          	jalr	-1334(ra) # 8000052a <panic>

0000000080003a68 <balloc>:
{
    80003a68:	711d                	addi	sp,sp,-96
    80003a6a:	ec86                	sd	ra,88(sp)
    80003a6c:	e8a2                	sd	s0,80(sp)
    80003a6e:	e4a6                	sd	s1,72(sp)
    80003a70:	e0ca                	sd	s2,64(sp)
    80003a72:	fc4e                	sd	s3,56(sp)
    80003a74:	f852                	sd	s4,48(sp)
    80003a76:	f456                	sd	s5,40(sp)
    80003a78:	f05a                	sd	s6,32(sp)
    80003a7a:	ec5e                	sd	s7,24(sp)
    80003a7c:	e862                	sd	s8,16(sp)
    80003a7e:	e466                	sd	s9,8(sp)
    80003a80:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a82:	00025797          	auipc	a5,0x25
    80003a86:	12a7a783          	lw	a5,298(a5) # 80028bac <sb+0x4>
    80003a8a:	cbd1                	beqz	a5,80003b1e <balloc+0xb6>
    80003a8c:	8baa                	mv	s7,a0
    80003a8e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a90:	00025b17          	auipc	s6,0x25
    80003a94:	118b0b13          	addi	s6,s6,280 # 80028ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a98:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a9a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a9c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a9e:	6c89                	lui	s9,0x2
    80003aa0:	a831                	j	80003abc <balloc+0x54>
    brelse(bp);
    80003aa2:	854a                	mv	a0,s2
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	e32080e7          	jalr	-462(ra) # 800038d6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003aac:	015c87bb          	addw	a5,s9,s5
    80003ab0:	00078a9b          	sext.w	s5,a5
    80003ab4:	004b2703          	lw	a4,4(s6)
    80003ab8:	06eaf363          	bgeu	s5,a4,80003b1e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003abc:	41fad79b          	sraiw	a5,s5,0x1f
    80003ac0:	0137d79b          	srliw	a5,a5,0x13
    80003ac4:	015787bb          	addw	a5,a5,s5
    80003ac8:	40d7d79b          	sraiw	a5,a5,0xd
    80003acc:	01cb2583          	lw	a1,28(s6)
    80003ad0:	9dbd                	addw	a1,a1,a5
    80003ad2:	855e                	mv	a0,s7
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	cd2080e7          	jalr	-814(ra) # 800037a6 <bread>
    80003adc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ade:	004b2503          	lw	a0,4(s6)
    80003ae2:	000a849b          	sext.w	s1,s5
    80003ae6:	8662                	mv	a2,s8
    80003ae8:	faa4fde3          	bgeu	s1,a0,80003aa2 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003aec:	41f6579b          	sraiw	a5,a2,0x1f
    80003af0:	01d7d69b          	srliw	a3,a5,0x1d
    80003af4:	00c6873b          	addw	a4,a3,a2
    80003af8:	00777793          	andi	a5,a4,7
    80003afc:	9f95                	subw	a5,a5,a3
    80003afe:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b02:	4037571b          	sraiw	a4,a4,0x3
    80003b06:	00e906b3          	add	a3,s2,a4
    80003b0a:	0586c683          	lbu	a3,88(a3)
    80003b0e:	00d7f5b3          	and	a1,a5,a3
    80003b12:	cd91                	beqz	a1,80003b2e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b14:	2605                	addiw	a2,a2,1
    80003b16:	2485                	addiw	s1,s1,1
    80003b18:	fd4618e3          	bne	a2,s4,80003ae8 <balloc+0x80>
    80003b1c:	b759                	j	80003aa2 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003b1e:	00006517          	auipc	a0,0x6
    80003b22:	cfa50513          	addi	a0,a0,-774 # 80009818 <syscalls+0x100>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	a04080e7          	jalr	-1532(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b2e:	974a                	add	a4,a4,s2
    80003b30:	8fd5                	or	a5,a5,a3
    80003b32:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003b36:	854a                	mv	a0,s2
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	332080e7          	jalr	818(ra) # 80004e6a <log_write>
        brelse(bp);
    80003b40:	854a                	mv	a0,s2
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	d94080e7          	jalr	-620(ra) # 800038d6 <brelse>
  bp = bread(dev, bno);
    80003b4a:	85a6                	mv	a1,s1
    80003b4c:	855e                	mv	a0,s7
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	c58080e7          	jalr	-936(ra) # 800037a6 <bread>
    80003b56:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b58:	40000613          	li	a2,1024
    80003b5c:	4581                	li	a1,0
    80003b5e:	05850513          	addi	a0,a0,88
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	15c080e7          	jalr	348(ra) # 80000cbe <memset>
  log_write(bp);
    80003b6a:	854a                	mv	a0,s2
    80003b6c:	00001097          	auipc	ra,0x1
    80003b70:	2fe080e7          	jalr	766(ra) # 80004e6a <log_write>
  brelse(bp);
    80003b74:	854a                	mv	a0,s2
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	d60080e7          	jalr	-672(ra) # 800038d6 <brelse>
}
    80003b7e:	8526                	mv	a0,s1
    80003b80:	60e6                	ld	ra,88(sp)
    80003b82:	6446                	ld	s0,80(sp)
    80003b84:	64a6                	ld	s1,72(sp)
    80003b86:	6906                	ld	s2,64(sp)
    80003b88:	79e2                	ld	s3,56(sp)
    80003b8a:	7a42                	ld	s4,48(sp)
    80003b8c:	7aa2                	ld	s5,40(sp)
    80003b8e:	7b02                	ld	s6,32(sp)
    80003b90:	6be2                	ld	s7,24(sp)
    80003b92:	6c42                	ld	s8,16(sp)
    80003b94:	6ca2                	ld	s9,8(sp)
    80003b96:	6125                	addi	sp,sp,96
    80003b98:	8082                	ret

0000000080003b9a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b9a:	7179                	addi	sp,sp,-48
    80003b9c:	f406                	sd	ra,40(sp)
    80003b9e:	f022                	sd	s0,32(sp)
    80003ba0:	ec26                	sd	s1,24(sp)
    80003ba2:	e84a                	sd	s2,16(sp)
    80003ba4:	e44e                	sd	s3,8(sp)
    80003ba6:	e052                	sd	s4,0(sp)
    80003ba8:	1800                	addi	s0,sp,48
    80003baa:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003bac:	47ad                	li	a5,11
    80003bae:	04b7fe63          	bgeu	a5,a1,80003c0a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003bb2:	ff45849b          	addiw	s1,a1,-12
    80003bb6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003bba:	0ff00793          	li	a5,255
    80003bbe:	0ae7e463          	bltu	a5,a4,80003c66 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003bc2:	08052583          	lw	a1,128(a0)
    80003bc6:	c5b5                	beqz	a1,80003c32 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003bc8:	00092503          	lw	a0,0(s2)
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	bda080e7          	jalr	-1062(ra) # 800037a6 <bread>
    80003bd4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003bd6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003bda:	02049713          	slli	a4,s1,0x20
    80003bde:	01e75593          	srli	a1,a4,0x1e
    80003be2:	00b784b3          	add	s1,a5,a1
    80003be6:	0004a983          	lw	s3,0(s1)
    80003bea:	04098e63          	beqz	s3,80003c46 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003bee:	8552                	mv	a0,s4
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	ce6080e7          	jalr	-794(ra) # 800038d6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003bf8:	854e                	mv	a0,s3
    80003bfa:	70a2                	ld	ra,40(sp)
    80003bfc:	7402                	ld	s0,32(sp)
    80003bfe:	64e2                	ld	s1,24(sp)
    80003c00:	6942                	ld	s2,16(sp)
    80003c02:	69a2                	ld	s3,8(sp)
    80003c04:	6a02                	ld	s4,0(sp)
    80003c06:	6145                	addi	sp,sp,48
    80003c08:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003c0a:	02059793          	slli	a5,a1,0x20
    80003c0e:	01e7d593          	srli	a1,a5,0x1e
    80003c12:	00b504b3          	add	s1,a0,a1
    80003c16:	0504a983          	lw	s3,80(s1)
    80003c1a:	fc099fe3          	bnez	s3,80003bf8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003c1e:	4108                	lw	a0,0(a0)
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	e48080e7          	jalr	-440(ra) # 80003a68 <balloc>
    80003c28:	0005099b          	sext.w	s3,a0
    80003c2c:	0534a823          	sw	s3,80(s1)
    80003c30:	b7e1                	j	80003bf8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003c32:	4108                	lw	a0,0(a0)
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	e34080e7          	jalr	-460(ra) # 80003a68 <balloc>
    80003c3c:	0005059b          	sext.w	a1,a0
    80003c40:	08b92023          	sw	a1,128(s2)
    80003c44:	b751                	j	80003bc8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c46:	00092503          	lw	a0,0(s2)
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	e1e080e7          	jalr	-482(ra) # 80003a68 <balloc>
    80003c52:	0005099b          	sext.w	s3,a0
    80003c56:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c5a:	8552                	mv	a0,s4
    80003c5c:	00001097          	auipc	ra,0x1
    80003c60:	20e080e7          	jalr	526(ra) # 80004e6a <log_write>
    80003c64:	b769                	j	80003bee <bmap+0x54>
  panic("bmap: out of range");
    80003c66:	00006517          	auipc	a0,0x6
    80003c6a:	bca50513          	addi	a0,a0,-1078 # 80009830 <syscalls+0x118>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080003c76 <iget>:
{
    80003c76:	7179                	addi	sp,sp,-48
    80003c78:	f406                	sd	ra,40(sp)
    80003c7a:	f022                	sd	s0,32(sp)
    80003c7c:	ec26                	sd	s1,24(sp)
    80003c7e:	e84a                	sd	s2,16(sp)
    80003c80:	e44e                	sd	s3,8(sp)
    80003c82:	e052                	sd	s4,0(sp)
    80003c84:	1800                	addi	s0,sp,48
    80003c86:	89aa                	mv	s3,a0
    80003c88:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c8a:	00025517          	auipc	a0,0x25
    80003c8e:	f3e50513          	addi	a0,a0,-194 # 80028bc8 <itable>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	f30080e7          	jalr	-208(ra) # 80000bc2 <acquire>
  empty = 0;
    80003c9a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c9c:	00025497          	auipc	s1,0x25
    80003ca0:	f4448493          	addi	s1,s1,-188 # 80028be0 <itable+0x18>
    80003ca4:	00027697          	auipc	a3,0x27
    80003ca8:	9cc68693          	addi	a3,a3,-1588 # 8002a670 <log>
    80003cac:	a039                	j	80003cba <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cae:	02090b63          	beqz	s2,80003ce4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003cb2:	08848493          	addi	s1,s1,136
    80003cb6:	02d48a63          	beq	s1,a3,80003cea <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003cba:	449c                	lw	a5,8(s1)
    80003cbc:	fef059e3          	blez	a5,80003cae <iget+0x38>
    80003cc0:	4098                	lw	a4,0(s1)
    80003cc2:	ff3716e3          	bne	a4,s3,80003cae <iget+0x38>
    80003cc6:	40d8                	lw	a4,4(s1)
    80003cc8:	ff4713e3          	bne	a4,s4,80003cae <iget+0x38>
      ip->ref++;
    80003ccc:	2785                	addiw	a5,a5,1
    80003cce:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003cd0:	00025517          	auipc	a0,0x25
    80003cd4:	ef850513          	addi	a0,a0,-264 # 80028bc8 <itable>
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	f9e080e7          	jalr	-98(ra) # 80000c76 <release>
      return ip;
    80003ce0:	8926                	mv	s2,s1
    80003ce2:	a03d                	j	80003d10 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ce4:	f7f9                	bnez	a5,80003cb2 <iget+0x3c>
    80003ce6:	8926                	mv	s2,s1
    80003ce8:	b7e9                	j	80003cb2 <iget+0x3c>
  if(empty == 0)
    80003cea:	02090c63          	beqz	s2,80003d22 <iget+0xac>
  ip->dev = dev;
    80003cee:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003cf2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003cf6:	4785                	li	a5,1
    80003cf8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003cfc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d00:	00025517          	auipc	a0,0x25
    80003d04:	ec850513          	addi	a0,a0,-312 # 80028bc8 <itable>
    80003d08:	ffffd097          	auipc	ra,0xffffd
    80003d0c:	f6e080e7          	jalr	-146(ra) # 80000c76 <release>
}
    80003d10:	854a                	mv	a0,s2
    80003d12:	70a2                	ld	ra,40(sp)
    80003d14:	7402                	ld	s0,32(sp)
    80003d16:	64e2                	ld	s1,24(sp)
    80003d18:	6942                	ld	s2,16(sp)
    80003d1a:	69a2                	ld	s3,8(sp)
    80003d1c:	6a02                	ld	s4,0(sp)
    80003d1e:	6145                	addi	sp,sp,48
    80003d20:	8082                	ret
    panic("iget: no inodes");
    80003d22:	00006517          	auipc	a0,0x6
    80003d26:	b2650513          	addi	a0,a0,-1242 # 80009848 <syscalls+0x130>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	800080e7          	jalr	-2048(ra) # 8000052a <panic>

0000000080003d32 <fsinit>:
fsinit(int dev) {
    80003d32:	7179                	addi	sp,sp,-48
    80003d34:	f406                	sd	ra,40(sp)
    80003d36:	f022                	sd	s0,32(sp)
    80003d38:	ec26                	sd	s1,24(sp)
    80003d3a:	e84a                	sd	s2,16(sp)
    80003d3c:	e44e                	sd	s3,8(sp)
    80003d3e:	1800                	addi	s0,sp,48
    80003d40:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d42:	4585                	li	a1,1
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	a62080e7          	jalr	-1438(ra) # 800037a6 <bread>
    80003d4c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d4e:	00025997          	auipc	s3,0x25
    80003d52:	e5a98993          	addi	s3,s3,-422 # 80028ba8 <sb>
    80003d56:	02000613          	li	a2,32
    80003d5a:	05850593          	addi	a1,a0,88
    80003d5e:	854e                	mv	a0,s3
    80003d60:	ffffd097          	auipc	ra,0xffffd
    80003d64:	fba080e7          	jalr	-70(ra) # 80000d1a <memmove>
  brelse(bp);
    80003d68:	8526                	mv	a0,s1
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	b6c080e7          	jalr	-1172(ra) # 800038d6 <brelse>
  if(sb.magic != FSMAGIC)
    80003d72:	0009a703          	lw	a4,0(s3)
    80003d76:	102037b7          	lui	a5,0x10203
    80003d7a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d7e:	02f71263          	bne	a4,a5,80003da2 <fsinit+0x70>
  initlog(dev, &sb);
    80003d82:	00025597          	auipc	a1,0x25
    80003d86:	e2658593          	addi	a1,a1,-474 # 80028ba8 <sb>
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	00001097          	auipc	ra,0x1
    80003d90:	e60080e7          	jalr	-416(ra) # 80004bec <initlog>
}
    80003d94:	70a2                	ld	ra,40(sp)
    80003d96:	7402                	ld	s0,32(sp)
    80003d98:	64e2                	ld	s1,24(sp)
    80003d9a:	6942                	ld	s2,16(sp)
    80003d9c:	69a2                	ld	s3,8(sp)
    80003d9e:	6145                	addi	sp,sp,48
    80003da0:	8082                	ret
    panic("invalid file system");
    80003da2:	00006517          	auipc	a0,0x6
    80003da6:	ab650513          	addi	a0,a0,-1354 # 80009858 <syscalls+0x140>
    80003daa:	ffffc097          	auipc	ra,0xffffc
    80003dae:	780080e7          	jalr	1920(ra) # 8000052a <panic>

0000000080003db2 <iinit>:
{
    80003db2:	7179                	addi	sp,sp,-48
    80003db4:	f406                	sd	ra,40(sp)
    80003db6:	f022                	sd	s0,32(sp)
    80003db8:	ec26                	sd	s1,24(sp)
    80003dba:	e84a                	sd	s2,16(sp)
    80003dbc:	e44e                	sd	s3,8(sp)
    80003dbe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003dc0:	00006597          	auipc	a1,0x6
    80003dc4:	ab058593          	addi	a1,a1,-1360 # 80009870 <syscalls+0x158>
    80003dc8:	00025517          	auipc	a0,0x25
    80003dcc:	e0050513          	addi	a0,a0,-512 # 80028bc8 <itable>
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	d62080e7          	jalr	-670(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003dd8:	00025497          	auipc	s1,0x25
    80003ddc:	e1848493          	addi	s1,s1,-488 # 80028bf0 <itable+0x28>
    80003de0:	00027997          	auipc	s3,0x27
    80003de4:	8a098993          	addi	s3,s3,-1888 # 8002a680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003de8:	00006917          	auipc	s2,0x6
    80003dec:	a9090913          	addi	s2,s2,-1392 # 80009878 <syscalls+0x160>
    80003df0:	85ca                	mv	a1,s2
    80003df2:	8526                	mv	a0,s1
    80003df4:	00001097          	auipc	ra,0x1
    80003df8:	15c080e7          	jalr	348(ra) # 80004f50 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003dfc:	08848493          	addi	s1,s1,136
    80003e00:	ff3498e3          	bne	s1,s3,80003df0 <iinit+0x3e>
}
    80003e04:	70a2                	ld	ra,40(sp)
    80003e06:	7402                	ld	s0,32(sp)
    80003e08:	64e2                	ld	s1,24(sp)
    80003e0a:	6942                	ld	s2,16(sp)
    80003e0c:	69a2                	ld	s3,8(sp)
    80003e0e:	6145                	addi	sp,sp,48
    80003e10:	8082                	ret

0000000080003e12 <ialloc>:
{
    80003e12:	715d                	addi	sp,sp,-80
    80003e14:	e486                	sd	ra,72(sp)
    80003e16:	e0a2                	sd	s0,64(sp)
    80003e18:	fc26                	sd	s1,56(sp)
    80003e1a:	f84a                	sd	s2,48(sp)
    80003e1c:	f44e                	sd	s3,40(sp)
    80003e1e:	f052                	sd	s4,32(sp)
    80003e20:	ec56                	sd	s5,24(sp)
    80003e22:	e85a                	sd	s6,16(sp)
    80003e24:	e45e                	sd	s7,8(sp)
    80003e26:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e28:	00025717          	auipc	a4,0x25
    80003e2c:	d8c72703          	lw	a4,-628(a4) # 80028bb4 <sb+0xc>
    80003e30:	4785                	li	a5,1
    80003e32:	04e7fa63          	bgeu	a5,a4,80003e86 <ialloc+0x74>
    80003e36:	8aaa                	mv	s5,a0
    80003e38:	8bae                	mv	s7,a1
    80003e3a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e3c:	00025a17          	auipc	s4,0x25
    80003e40:	d6ca0a13          	addi	s4,s4,-660 # 80028ba8 <sb>
    80003e44:	00048b1b          	sext.w	s6,s1
    80003e48:	0044d793          	srli	a5,s1,0x4
    80003e4c:	018a2583          	lw	a1,24(s4)
    80003e50:	9dbd                	addw	a1,a1,a5
    80003e52:	8556                	mv	a0,s5
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	952080e7          	jalr	-1710(ra) # 800037a6 <bread>
    80003e5c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e5e:	05850993          	addi	s3,a0,88
    80003e62:	00f4f793          	andi	a5,s1,15
    80003e66:	079a                	slli	a5,a5,0x6
    80003e68:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e6a:	00099783          	lh	a5,0(s3)
    80003e6e:	c785                	beqz	a5,80003e96 <ialloc+0x84>
    brelse(bp);
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	a66080e7          	jalr	-1434(ra) # 800038d6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e78:	0485                	addi	s1,s1,1
    80003e7a:	00ca2703          	lw	a4,12(s4)
    80003e7e:	0004879b          	sext.w	a5,s1
    80003e82:	fce7e1e3          	bltu	a5,a4,80003e44 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e86:	00006517          	auipc	a0,0x6
    80003e8a:	9fa50513          	addi	a0,a0,-1542 # 80009880 <syscalls+0x168>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	69c080e7          	jalr	1692(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003e96:	04000613          	li	a2,64
    80003e9a:	4581                	li	a1,0
    80003e9c:	854e                	mv	a0,s3
    80003e9e:	ffffd097          	auipc	ra,0xffffd
    80003ea2:	e20080e7          	jalr	-480(ra) # 80000cbe <memset>
      dip->type = type;
    80003ea6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00001097          	auipc	ra,0x1
    80003eb0:	fbe080e7          	jalr	-66(ra) # 80004e6a <log_write>
      brelse(bp);
    80003eb4:	854a                	mv	a0,s2
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	a20080e7          	jalr	-1504(ra) # 800038d6 <brelse>
      return iget(dev, inum);
    80003ebe:	85da                	mv	a1,s6
    80003ec0:	8556                	mv	a0,s5
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	db4080e7          	jalr	-588(ra) # 80003c76 <iget>
}
    80003eca:	60a6                	ld	ra,72(sp)
    80003ecc:	6406                	ld	s0,64(sp)
    80003ece:	74e2                	ld	s1,56(sp)
    80003ed0:	7942                	ld	s2,48(sp)
    80003ed2:	79a2                	ld	s3,40(sp)
    80003ed4:	7a02                	ld	s4,32(sp)
    80003ed6:	6ae2                	ld	s5,24(sp)
    80003ed8:	6b42                	ld	s6,16(sp)
    80003eda:	6ba2                	ld	s7,8(sp)
    80003edc:	6161                	addi	sp,sp,80
    80003ede:	8082                	ret

0000000080003ee0 <iupdate>:
{
    80003ee0:	1101                	addi	sp,sp,-32
    80003ee2:	ec06                	sd	ra,24(sp)
    80003ee4:	e822                	sd	s0,16(sp)
    80003ee6:	e426                	sd	s1,8(sp)
    80003ee8:	e04a                	sd	s2,0(sp)
    80003eea:	1000                	addi	s0,sp,32
    80003eec:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003eee:	415c                	lw	a5,4(a0)
    80003ef0:	0047d79b          	srliw	a5,a5,0x4
    80003ef4:	00025597          	auipc	a1,0x25
    80003ef8:	ccc5a583          	lw	a1,-820(a1) # 80028bc0 <sb+0x18>
    80003efc:	9dbd                	addw	a1,a1,a5
    80003efe:	4108                	lw	a0,0(a0)
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	8a6080e7          	jalr	-1882(ra) # 800037a6 <bread>
    80003f08:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f0a:	05850793          	addi	a5,a0,88
    80003f0e:	40c8                	lw	a0,4(s1)
    80003f10:	893d                	andi	a0,a0,15
    80003f12:	051a                	slli	a0,a0,0x6
    80003f14:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f16:	04449703          	lh	a4,68(s1)
    80003f1a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f1e:	04649703          	lh	a4,70(s1)
    80003f22:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f26:	04849703          	lh	a4,72(s1)
    80003f2a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f2e:	04a49703          	lh	a4,74(s1)
    80003f32:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f36:	44f8                	lw	a4,76(s1)
    80003f38:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f3a:	03400613          	li	a2,52
    80003f3e:	05048593          	addi	a1,s1,80
    80003f42:	0531                	addi	a0,a0,12
    80003f44:	ffffd097          	auipc	ra,0xffffd
    80003f48:	dd6080e7          	jalr	-554(ra) # 80000d1a <memmove>
  log_write(bp);
    80003f4c:	854a                	mv	a0,s2
    80003f4e:	00001097          	auipc	ra,0x1
    80003f52:	f1c080e7          	jalr	-228(ra) # 80004e6a <log_write>
  brelse(bp);
    80003f56:	854a                	mv	a0,s2
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	97e080e7          	jalr	-1666(ra) # 800038d6 <brelse>
}
    80003f60:	60e2                	ld	ra,24(sp)
    80003f62:	6442                	ld	s0,16(sp)
    80003f64:	64a2                	ld	s1,8(sp)
    80003f66:	6902                	ld	s2,0(sp)
    80003f68:	6105                	addi	sp,sp,32
    80003f6a:	8082                	ret

0000000080003f6c <idup>:
{
    80003f6c:	1101                	addi	sp,sp,-32
    80003f6e:	ec06                	sd	ra,24(sp)
    80003f70:	e822                	sd	s0,16(sp)
    80003f72:	e426                	sd	s1,8(sp)
    80003f74:	1000                	addi	s0,sp,32
    80003f76:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f78:	00025517          	auipc	a0,0x25
    80003f7c:	c5050513          	addi	a0,a0,-944 # 80028bc8 <itable>
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	c42080e7          	jalr	-958(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003f88:	449c                	lw	a5,8(s1)
    80003f8a:	2785                	addiw	a5,a5,1
    80003f8c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f8e:	00025517          	auipc	a0,0x25
    80003f92:	c3a50513          	addi	a0,a0,-966 # 80028bc8 <itable>
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	ce0080e7          	jalr	-800(ra) # 80000c76 <release>
}
    80003f9e:	8526                	mv	a0,s1
    80003fa0:	60e2                	ld	ra,24(sp)
    80003fa2:	6442                	ld	s0,16(sp)
    80003fa4:	64a2                	ld	s1,8(sp)
    80003fa6:	6105                	addi	sp,sp,32
    80003fa8:	8082                	ret

0000000080003faa <ilock>:
{
    80003faa:	1101                	addi	sp,sp,-32
    80003fac:	ec06                	sd	ra,24(sp)
    80003fae:	e822                	sd	s0,16(sp)
    80003fb0:	e426                	sd	s1,8(sp)
    80003fb2:	e04a                	sd	s2,0(sp)
    80003fb4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003fb6:	c115                	beqz	a0,80003fda <ilock+0x30>
    80003fb8:	84aa                	mv	s1,a0
    80003fba:	451c                	lw	a5,8(a0)
    80003fbc:	00f05f63          	blez	a5,80003fda <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fc0:	0541                	addi	a0,a0,16
    80003fc2:	00001097          	auipc	ra,0x1
    80003fc6:	fc8080e7          	jalr	-56(ra) # 80004f8a <acquiresleep>
  if(ip->valid == 0){
    80003fca:	40bc                	lw	a5,64(s1)
    80003fcc:	cf99                	beqz	a5,80003fea <ilock+0x40>
}
    80003fce:	60e2                	ld	ra,24(sp)
    80003fd0:	6442                	ld	s0,16(sp)
    80003fd2:	64a2                	ld	s1,8(sp)
    80003fd4:	6902                	ld	s2,0(sp)
    80003fd6:	6105                	addi	sp,sp,32
    80003fd8:	8082                	ret
    panic("ilock");
    80003fda:	00006517          	auipc	a0,0x6
    80003fde:	8be50513          	addi	a0,a0,-1858 # 80009898 <syscalls+0x180>
    80003fe2:	ffffc097          	auipc	ra,0xffffc
    80003fe6:	548080e7          	jalr	1352(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003fea:	40dc                	lw	a5,4(s1)
    80003fec:	0047d79b          	srliw	a5,a5,0x4
    80003ff0:	00025597          	auipc	a1,0x25
    80003ff4:	bd05a583          	lw	a1,-1072(a1) # 80028bc0 <sb+0x18>
    80003ff8:	9dbd                	addw	a1,a1,a5
    80003ffa:	4088                	lw	a0,0(s1)
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	7aa080e7          	jalr	1962(ra) # 800037a6 <bread>
    80004004:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004006:	05850593          	addi	a1,a0,88
    8000400a:	40dc                	lw	a5,4(s1)
    8000400c:	8bbd                	andi	a5,a5,15
    8000400e:	079a                	slli	a5,a5,0x6
    80004010:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004012:	00059783          	lh	a5,0(a1)
    80004016:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000401a:	00259783          	lh	a5,2(a1)
    8000401e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004022:	00459783          	lh	a5,4(a1)
    80004026:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000402a:	00659783          	lh	a5,6(a1)
    8000402e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004032:	459c                	lw	a5,8(a1)
    80004034:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004036:	03400613          	li	a2,52
    8000403a:	05b1                	addi	a1,a1,12
    8000403c:	05048513          	addi	a0,s1,80
    80004040:	ffffd097          	auipc	ra,0xffffd
    80004044:	cda080e7          	jalr	-806(ra) # 80000d1a <memmove>
    brelse(bp);
    80004048:	854a                	mv	a0,s2
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	88c080e7          	jalr	-1908(ra) # 800038d6 <brelse>
    ip->valid = 1;
    80004052:	4785                	li	a5,1
    80004054:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004056:	04449783          	lh	a5,68(s1)
    8000405a:	fbb5                	bnez	a5,80003fce <ilock+0x24>
      panic("ilock: no type");
    8000405c:	00006517          	auipc	a0,0x6
    80004060:	84450513          	addi	a0,a0,-1980 # 800098a0 <syscalls+0x188>
    80004064:	ffffc097          	auipc	ra,0xffffc
    80004068:	4c6080e7          	jalr	1222(ra) # 8000052a <panic>

000000008000406c <iunlock>:
{
    8000406c:	1101                	addi	sp,sp,-32
    8000406e:	ec06                	sd	ra,24(sp)
    80004070:	e822                	sd	s0,16(sp)
    80004072:	e426                	sd	s1,8(sp)
    80004074:	e04a                	sd	s2,0(sp)
    80004076:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004078:	c905                	beqz	a0,800040a8 <iunlock+0x3c>
    8000407a:	84aa                	mv	s1,a0
    8000407c:	01050913          	addi	s2,a0,16
    80004080:	854a                	mv	a0,s2
    80004082:	00001097          	auipc	ra,0x1
    80004086:	fa2080e7          	jalr	-94(ra) # 80005024 <holdingsleep>
    8000408a:	cd19                	beqz	a0,800040a8 <iunlock+0x3c>
    8000408c:	449c                	lw	a5,8(s1)
    8000408e:	00f05d63          	blez	a5,800040a8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004092:	854a                	mv	a0,s2
    80004094:	00001097          	auipc	ra,0x1
    80004098:	f4c080e7          	jalr	-180(ra) # 80004fe0 <releasesleep>
}
    8000409c:	60e2                	ld	ra,24(sp)
    8000409e:	6442                	ld	s0,16(sp)
    800040a0:	64a2                	ld	s1,8(sp)
    800040a2:	6902                	ld	s2,0(sp)
    800040a4:	6105                	addi	sp,sp,32
    800040a6:	8082                	ret
    panic("iunlock");
    800040a8:	00006517          	auipc	a0,0x6
    800040ac:	80850513          	addi	a0,a0,-2040 # 800098b0 <syscalls+0x198>
    800040b0:	ffffc097          	auipc	ra,0xffffc
    800040b4:	47a080e7          	jalr	1146(ra) # 8000052a <panic>

00000000800040b8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040b8:	7179                	addi	sp,sp,-48
    800040ba:	f406                	sd	ra,40(sp)
    800040bc:	f022                	sd	s0,32(sp)
    800040be:	ec26                	sd	s1,24(sp)
    800040c0:	e84a                	sd	s2,16(sp)
    800040c2:	e44e                	sd	s3,8(sp)
    800040c4:	e052                	sd	s4,0(sp)
    800040c6:	1800                	addi	s0,sp,48
    800040c8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040ca:	05050493          	addi	s1,a0,80
    800040ce:	08050913          	addi	s2,a0,128
    800040d2:	a021                	j	800040da <itrunc+0x22>
    800040d4:	0491                	addi	s1,s1,4
    800040d6:	01248d63          	beq	s1,s2,800040f0 <itrunc+0x38>
    if(ip->addrs[i]){
    800040da:	408c                	lw	a1,0(s1)
    800040dc:	dde5                	beqz	a1,800040d4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040de:	0009a503          	lw	a0,0(s3)
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	90a080e7          	jalr	-1782(ra) # 800039ec <bfree>
      ip->addrs[i] = 0;
    800040ea:	0004a023          	sw	zero,0(s1)
    800040ee:	b7dd                	j	800040d4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800040f0:	0809a583          	lw	a1,128(s3)
    800040f4:	e185                	bnez	a1,80004114 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800040f6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800040fa:	854e                	mv	a0,s3
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	de4080e7          	jalr	-540(ra) # 80003ee0 <iupdate>
}
    80004104:	70a2                	ld	ra,40(sp)
    80004106:	7402                	ld	s0,32(sp)
    80004108:	64e2                	ld	s1,24(sp)
    8000410a:	6942                	ld	s2,16(sp)
    8000410c:	69a2                	ld	s3,8(sp)
    8000410e:	6a02                	ld	s4,0(sp)
    80004110:	6145                	addi	sp,sp,48
    80004112:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004114:	0009a503          	lw	a0,0(s3)
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	68e080e7          	jalr	1678(ra) # 800037a6 <bread>
    80004120:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004122:	05850493          	addi	s1,a0,88
    80004126:	45850913          	addi	s2,a0,1112
    8000412a:	a021                	j	80004132 <itrunc+0x7a>
    8000412c:	0491                	addi	s1,s1,4
    8000412e:	01248b63          	beq	s1,s2,80004144 <itrunc+0x8c>
      if(a[j])
    80004132:	408c                	lw	a1,0(s1)
    80004134:	dde5                	beqz	a1,8000412c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004136:	0009a503          	lw	a0,0(s3)
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	8b2080e7          	jalr	-1870(ra) # 800039ec <bfree>
    80004142:	b7ed                	j	8000412c <itrunc+0x74>
    brelse(bp);
    80004144:	8552                	mv	a0,s4
    80004146:	fffff097          	auipc	ra,0xfffff
    8000414a:	790080e7          	jalr	1936(ra) # 800038d6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000414e:	0809a583          	lw	a1,128(s3)
    80004152:	0009a503          	lw	a0,0(s3)
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	896080e7          	jalr	-1898(ra) # 800039ec <bfree>
    ip->addrs[NDIRECT] = 0;
    8000415e:	0809a023          	sw	zero,128(s3)
    80004162:	bf51                	j	800040f6 <itrunc+0x3e>

0000000080004164 <iput>:
{
    80004164:	1101                	addi	sp,sp,-32
    80004166:	ec06                	sd	ra,24(sp)
    80004168:	e822                	sd	s0,16(sp)
    8000416a:	e426                	sd	s1,8(sp)
    8000416c:	e04a                	sd	s2,0(sp)
    8000416e:	1000                	addi	s0,sp,32
    80004170:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004172:	00025517          	auipc	a0,0x25
    80004176:	a5650513          	addi	a0,a0,-1450 # 80028bc8 <itable>
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	a48080e7          	jalr	-1464(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004182:	4498                	lw	a4,8(s1)
    80004184:	4785                	li	a5,1
    80004186:	02f70363          	beq	a4,a5,800041ac <iput+0x48>
  ip->ref--;
    8000418a:	449c                	lw	a5,8(s1)
    8000418c:	37fd                	addiw	a5,a5,-1
    8000418e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004190:	00025517          	auipc	a0,0x25
    80004194:	a3850513          	addi	a0,a0,-1480 # 80028bc8 <itable>
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	ade080e7          	jalr	-1314(ra) # 80000c76 <release>
}
    800041a0:	60e2                	ld	ra,24(sp)
    800041a2:	6442                	ld	s0,16(sp)
    800041a4:	64a2                	ld	s1,8(sp)
    800041a6:	6902                	ld	s2,0(sp)
    800041a8:	6105                	addi	sp,sp,32
    800041aa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041ac:	40bc                	lw	a5,64(s1)
    800041ae:	dff1                	beqz	a5,8000418a <iput+0x26>
    800041b0:	04a49783          	lh	a5,74(s1)
    800041b4:	fbf9                	bnez	a5,8000418a <iput+0x26>
    acquiresleep(&ip->lock);
    800041b6:	01048913          	addi	s2,s1,16
    800041ba:	854a                	mv	a0,s2
    800041bc:	00001097          	auipc	ra,0x1
    800041c0:	dce080e7          	jalr	-562(ra) # 80004f8a <acquiresleep>
    release(&itable.lock);
    800041c4:	00025517          	auipc	a0,0x25
    800041c8:	a0450513          	addi	a0,a0,-1532 # 80028bc8 <itable>
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	aaa080e7          	jalr	-1366(ra) # 80000c76 <release>
    itrunc(ip);
    800041d4:	8526                	mv	a0,s1
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	ee2080e7          	jalr	-286(ra) # 800040b8 <itrunc>
    ip->type = 0;
    800041de:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041e2:	8526                	mv	a0,s1
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	cfc080e7          	jalr	-772(ra) # 80003ee0 <iupdate>
    ip->valid = 0;
    800041ec:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800041f0:	854a                	mv	a0,s2
    800041f2:	00001097          	auipc	ra,0x1
    800041f6:	dee080e7          	jalr	-530(ra) # 80004fe0 <releasesleep>
    acquire(&itable.lock);
    800041fa:	00025517          	auipc	a0,0x25
    800041fe:	9ce50513          	addi	a0,a0,-1586 # 80028bc8 <itable>
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	9c0080e7          	jalr	-1600(ra) # 80000bc2 <acquire>
    8000420a:	b741                	j	8000418a <iput+0x26>

000000008000420c <iunlockput>:
{
    8000420c:	1101                	addi	sp,sp,-32
    8000420e:	ec06                	sd	ra,24(sp)
    80004210:	e822                	sd	s0,16(sp)
    80004212:	e426                	sd	s1,8(sp)
    80004214:	1000                	addi	s0,sp,32
    80004216:	84aa                	mv	s1,a0
  iunlock(ip);
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	e54080e7          	jalr	-428(ra) # 8000406c <iunlock>
  iput(ip);
    80004220:	8526                	mv	a0,s1
    80004222:	00000097          	auipc	ra,0x0
    80004226:	f42080e7          	jalr	-190(ra) # 80004164 <iput>
}
    8000422a:	60e2                	ld	ra,24(sp)
    8000422c:	6442                	ld	s0,16(sp)
    8000422e:	64a2                	ld	s1,8(sp)
    80004230:	6105                	addi	sp,sp,32
    80004232:	8082                	ret

0000000080004234 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004234:	1141                	addi	sp,sp,-16
    80004236:	e422                	sd	s0,8(sp)
    80004238:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000423a:	411c                	lw	a5,0(a0)
    8000423c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000423e:	415c                	lw	a5,4(a0)
    80004240:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004242:	04451783          	lh	a5,68(a0)
    80004246:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000424a:	04a51783          	lh	a5,74(a0)
    8000424e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004252:	04c56783          	lwu	a5,76(a0)
    80004256:	e99c                	sd	a5,16(a1)
}
    80004258:	6422                	ld	s0,8(sp)
    8000425a:	0141                	addi	sp,sp,16
    8000425c:	8082                	ret

000000008000425e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000425e:	457c                	lw	a5,76(a0)
    80004260:	0ed7e963          	bltu	a5,a3,80004352 <readi+0xf4>
{
    80004264:	7159                	addi	sp,sp,-112
    80004266:	f486                	sd	ra,104(sp)
    80004268:	f0a2                	sd	s0,96(sp)
    8000426a:	eca6                	sd	s1,88(sp)
    8000426c:	e8ca                	sd	s2,80(sp)
    8000426e:	e4ce                	sd	s3,72(sp)
    80004270:	e0d2                	sd	s4,64(sp)
    80004272:	fc56                	sd	s5,56(sp)
    80004274:	f85a                	sd	s6,48(sp)
    80004276:	f45e                	sd	s7,40(sp)
    80004278:	f062                	sd	s8,32(sp)
    8000427a:	ec66                	sd	s9,24(sp)
    8000427c:	e86a                	sd	s10,16(sp)
    8000427e:	e46e                	sd	s11,8(sp)
    80004280:	1880                	addi	s0,sp,112
    80004282:	8baa                	mv	s7,a0
    80004284:	8c2e                	mv	s8,a1
    80004286:	8ab2                	mv	s5,a2
    80004288:	84b6                	mv	s1,a3
    8000428a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000428c:	9f35                	addw	a4,a4,a3
    return 0;
    8000428e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004290:	0ad76063          	bltu	a4,a3,80004330 <readi+0xd2>
  if(off + n > ip->size)
    80004294:	00e7f463          	bgeu	a5,a4,8000429c <readi+0x3e>
    n = ip->size - off;
    80004298:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000429c:	0a0b0963          	beqz	s6,8000434e <readi+0xf0>
    800042a0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042a2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800042a6:	5cfd                	li	s9,-1
    800042a8:	a82d                	j	800042e2 <readi+0x84>
    800042aa:	020a1d93          	slli	s11,s4,0x20
    800042ae:	020ddd93          	srli	s11,s11,0x20
    800042b2:	05890793          	addi	a5,s2,88
    800042b6:	86ee                	mv	a3,s11
    800042b8:	963e                	add	a2,a2,a5
    800042ba:	85d6                	mv	a1,s5
    800042bc:	8562                	mv	a0,s8
    800042be:	ffffe097          	auipc	ra,0xffffe
    800042c2:	f52080e7          	jalr	-174(ra) # 80002210 <either_copyout>
    800042c6:	05950d63          	beq	a0,s9,80004320 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042ca:	854a                	mv	a0,s2
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	60a080e7          	jalr	1546(ra) # 800038d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042d4:	013a09bb          	addw	s3,s4,s3
    800042d8:	009a04bb          	addw	s1,s4,s1
    800042dc:	9aee                	add	s5,s5,s11
    800042de:	0569f763          	bgeu	s3,s6,8000432c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042e2:	000ba903          	lw	s2,0(s7)
    800042e6:	00a4d59b          	srliw	a1,s1,0xa
    800042ea:	855e                	mv	a0,s7
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	8ae080e7          	jalr	-1874(ra) # 80003b9a <bmap>
    800042f4:	0005059b          	sext.w	a1,a0
    800042f8:	854a                	mv	a0,s2
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	4ac080e7          	jalr	1196(ra) # 800037a6 <bread>
    80004302:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004304:	3ff4f613          	andi	a2,s1,1023
    80004308:	40cd07bb          	subw	a5,s10,a2
    8000430c:	413b073b          	subw	a4,s6,s3
    80004310:	8a3e                	mv	s4,a5
    80004312:	2781                	sext.w	a5,a5
    80004314:	0007069b          	sext.w	a3,a4
    80004318:	f8f6f9e3          	bgeu	a3,a5,800042aa <readi+0x4c>
    8000431c:	8a3a                	mv	s4,a4
    8000431e:	b771                	j	800042aa <readi+0x4c>
      brelse(bp);
    80004320:	854a                	mv	a0,s2
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	5b4080e7          	jalr	1460(ra) # 800038d6 <brelse>
      tot = -1;
    8000432a:	59fd                	li	s3,-1
  }
  return tot;
    8000432c:	0009851b          	sext.w	a0,s3
}
    80004330:	70a6                	ld	ra,104(sp)
    80004332:	7406                	ld	s0,96(sp)
    80004334:	64e6                	ld	s1,88(sp)
    80004336:	6946                	ld	s2,80(sp)
    80004338:	69a6                	ld	s3,72(sp)
    8000433a:	6a06                	ld	s4,64(sp)
    8000433c:	7ae2                	ld	s5,56(sp)
    8000433e:	7b42                	ld	s6,48(sp)
    80004340:	7ba2                	ld	s7,40(sp)
    80004342:	7c02                	ld	s8,32(sp)
    80004344:	6ce2                	ld	s9,24(sp)
    80004346:	6d42                	ld	s10,16(sp)
    80004348:	6da2                	ld	s11,8(sp)
    8000434a:	6165                	addi	sp,sp,112
    8000434c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000434e:	89da                	mv	s3,s6
    80004350:	bff1                	j	8000432c <readi+0xce>
    return 0;
    80004352:	4501                	li	a0,0
}
    80004354:	8082                	ret

0000000080004356 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004356:	457c                	lw	a5,76(a0)
    80004358:	10d7e863          	bltu	a5,a3,80004468 <writei+0x112>
{
    8000435c:	7159                	addi	sp,sp,-112
    8000435e:	f486                	sd	ra,104(sp)
    80004360:	f0a2                	sd	s0,96(sp)
    80004362:	eca6                	sd	s1,88(sp)
    80004364:	e8ca                	sd	s2,80(sp)
    80004366:	e4ce                	sd	s3,72(sp)
    80004368:	e0d2                	sd	s4,64(sp)
    8000436a:	fc56                	sd	s5,56(sp)
    8000436c:	f85a                	sd	s6,48(sp)
    8000436e:	f45e                	sd	s7,40(sp)
    80004370:	f062                	sd	s8,32(sp)
    80004372:	ec66                	sd	s9,24(sp)
    80004374:	e86a                	sd	s10,16(sp)
    80004376:	e46e                	sd	s11,8(sp)
    80004378:	1880                	addi	s0,sp,112
    8000437a:	8b2a                	mv	s6,a0
    8000437c:	8c2e                	mv	s8,a1
    8000437e:	8ab2                	mv	s5,a2
    80004380:	8936                	mv	s2,a3
    80004382:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004384:	00e687bb          	addw	a5,a3,a4
    80004388:	0ed7e263          	bltu	a5,a3,8000446c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000438c:	00043737          	lui	a4,0x43
    80004390:	0ef76063          	bltu	a4,a5,80004470 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004394:	0c0b8863          	beqz	s7,80004464 <writei+0x10e>
    80004398:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000439a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000439e:	5cfd                	li	s9,-1
    800043a0:	a091                	j	800043e4 <writei+0x8e>
    800043a2:	02099d93          	slli	s11,s3,0x20
    800043a6:	020ddd93          	srli	s11,s11,0x20
    800043aa:	05848793          	addi	a5,s1,88
    800043ae:	86ee                	mv	a3,s11
    800043b0:	8656                	mv	a2,s5
    800043b2:	85e2                	mv	a1,s8
    800043b4:	953e                	add	a0,a0,a5
    800043b6:	ffffe097          	auipc	ra,0xffffe
    800043ba:	eb0080e7          	jalr	-336(ra) # 80002266 <either_copyin>
    800043be:	07950263          	beq	a0,s9,80004422 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043c2:	8526                	mv	a0,s1
    800043c4:	00001097          	auipc	ra,0x1
    800043c8:	aa6080e7          	jalr	-1370(ra) # 80004e6a <log_write>
    brelse(bp);
    800043cc:	8526                	mv	a0,s1
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	508080e7          	jalr	1288(ra) # 800038d6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043d6:	01498a3b          	addw	s4,s3,s4
    800043da:	0129893b          	addw	s2,s3,s2
    800043de:	9aee                	add	s5,s5,s11
    800043e0:	057a7663          	bgeu	s4,s7,8000442c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043e4:	000b2483          	lw	s1,0(s6)
    800043e8:	00a9559b          	srliw	a1,s2,0xa
    800043ec:	855a                	mv	a0,s6
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	7ac080e7          	jalr	1964(ra) # 80003b9a <bmap>
    800043f6:	0005059b          	sext.w	a1,a0
    800043fa:	8526                	mv	a0,s1
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	3aa080e7          	jalr	938(ra) # 800037a6 <bread>
    80004404:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004406:	3ff97513          	andi	a0,s2,1023
    8000440a:	40ad07bb          	subw	a5,s10,a0
    8000440e:	414b873b          	subw	a4,s7,s4
    80004412:	89be                	mv	s3,a5
    80004414:	2781                	sext.w	a5,a5
    80004416:	0007069b          	sext.w	a3,a4
    8000441a:	f8f6f4e3          	bgeu	a3,a5,800043a2 <writei+0x4c>
    8000441e:	89ba                	mv	s3,a4
    80004420:	b749                	j	800043a2 <writei+0x4c>
      brelse(bp);
    80004422:	8526                	mv	a0,s1
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	4b2080e7          	jalr	1202(ra) # 800038d6 <brelse>
  }

  if(off > ip->size)
    8000442c:	04cb2783          	lw	a5,76(s6)
    80004430:	0127f463          	bgeu	a5,s2,80004438 <writei+0xe2>
    ip->size = off;
    80004434:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004438:	855a                	mv	a0,s6
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	aa6080e7          	jalr	-1370(ra) # 80003ee0 <iupdate>

  return tot;
    80004442:	000a051b          	sext.w	a0,s4
}
    80004446:	70a6                	ld	ra,104(sp)
    80004448:	7406                	ld	s0,96(sp)
    8000444a:	64e6                	ld	s1,88(sp)
    8000444c:	6946                	ld	s2,80(sp)
    8000444e:	69a6                	ld	s3,72(sp)
    80004450:	6a06                	ld	s4,64(sp)
    80004452:	7ae2                	ld	s5,56(sp)
    80004454:	7b42                	ld	s6,48(sp)
    80004456:	7ba2                	ld	s7,40(sp)
    80004458:	7c02                	ld	s8,32(sp)
    8000445a:	6ce2                	ld	s9,24(sp)
    8000445c:	6d42                	ld	s10,16(sp)
    8000445e:	6da2                	ld	s11,8(sp)
    80004460:	6165                	addi	sp,sp,112
    80004462:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004464:	8a5e                	mv	s4,s7
    80004466:	bfc9                	j	80004438 <writei+0xe2>
    return -1;
    80004468:	557d                	li	a0,-1
}
    8000446a:	8082                	ret
    return -1;
    8000446c:	557d                	li	a0,-1
    8000446e:	bfe1                	j	80004446 <writei+0xf0>
    return -1;
    80004470:	557d                	li	a0,-1
    80004472:	bfd1                	j	80004446 <writei+0xf0>

0000000080004474 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004474:	1141                	addi	sp,sp,-16
    80004476:	e406                	sd	ra,8(sp)
    80004478:	e022                	sd	s0,0(sp)
    8000447a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000447c:	4639                	li	a2,14
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	918080e7          	jalr	-1768(ra) # 80000d96 <strncmp>
}
    80004486:	60a2                	ld	ra,8(sp)
    80004488:	6402                	ld	s0,0(sp)
    8000448a:	0141                	addi	sp,sp,16
    8000448c:	8082                	ret

000000008000448e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000448e:	7139                	addi	sp,sp,-64
    80004490:	fc06                	sd	ra,56(sp)
    80004492:	f822                	sd	s0,48(sp)
    80004494:	f426                	sd	s1,40(sp)
    80004496:	f04a                	sd	s2,32(sp)
    80004498:	ec4e                	sd	s3,24(sp)
    8000449a:	e852                	sd	s4,16(sp)
    8000449c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000449e:	04451703          	lh	a4,68(a0)
    800044a2:	4785                	li	a5,1
    800044a4:	00f71a63          	bne	a4,a5,800044b8 <dirlookup+0x2a>
    800044a8:	892a                	mv	s2,a0
    800044aa:	89ae                	mv	s3,a1
    800044ac:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ae:	457c                	lw	a5,76(a0)
    800044b0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044b2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044b4:	e79d                	bnez	a5,800044e2 <dirlookup+0x54>
    800044b6:	a8a5                	j	8000452e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044b8:	00005517          	auipc	a0,0x5
    800044bc:	40050513          	addi	a0,a0,1024 # 800098b8 <syscalls+0x1a0>
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	06a080e7          	jalr	106(ra) # 8000052a <panic>
      panic("dirlookup read");
    800044c8:	00005517          	auipc	a0,0x5
    800044cc:	40850513          	addi	a0,a0,1032 # 800098d0 <syscalls+0x1b8>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	05a080e7          	jalr	90(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044d8:	24c1                	addiw	s1,s1,16
    800044da:	04c92783          	lw	a5,76(s2)
    800044de:	04f4f763          	bgeu	s1,a5,8000452c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044e2:	4741                	li	a4,16
    800044e4:	86a6                	mv	a3,s1
    800044e6:	fc040613          	addi	a2,s0,-64
    800044ea:	4581                	li	a1,0
    800044ec:	854a                	mv	a0,s2
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	d70080e7          	jalr	-656(ra) # 8000425e <readi>
    800044f6:	47c1                	li	a5,16
    800044f8:	fcf518e3          	bne	a0,a5,800044c8 <dirlookup+0x3a>
    if(de.inum == 0)
    800044fc:	fc045783          	lhu	a5,-64(s0)
    80004500:	dfe1                	beqz	a5,800044d8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004502:	fc240593          	addi	a1,s0,-62
    80004506:	854e                	mv	a0,s3
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	f6c080e7          	jalr	-148(ra) # 80004474 <namecmp>
    80004510:	f561                	bnez	a0,800044d8 <dirlookup+0x4a>
      if(poff)
    80004512:	000a0463          	beqz	s4,8000451a <dirlookup+0x8c>
        *poff = off;
    80004516:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000451a:	fc045583          	lhu	a1,-64(s0)
    8000451e:	00092503          	lw	a0,0(s2)
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	754080e7          	jalr	1876(ra) # 80003c76 <iget>
    8000452a:	a011                	j	8000452e <dirlookup+0xa0>
  return 0;
    8000452c:	4501                	li	a0,0
}
    8000452e:	70e2                	ld	ra,56(sp)
    80004530:	7442                	ld	s0,48(sp)
    80004532:	74a2                	ld	s1,40(sp)
    80004534:	7902                	ld	s2,32(sp)
    80004536:	69e2                	ld	s3,24(sp)
    80004538:	6a42                	ld	s4,16(sp)
    8000453a:	6121                	addi	sp,sp,64
    8000453c:	8082                	ret

000000008000453e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000453e:	711d                	addi	sp,sp,-96
    80004540:	ec86                	sd	ra,88(sp)
    80004542:	e8a2                	sd	s0,80(sp)
    80004544:	e4a6                	sd	s1,72(sp)
    80004546:	e0ca                	sd	s2,64(sp)
    80004548:	fc4e                	sd	s3,56(sp)
    8000454a:	f852                	sd	s4,48(sp)
    8000454c:	f456                	sd	s5,40(sp)
    8000454e:	f05a                	sd	s6,32(sp)
    80004550:	ec5e                	sd	s7,24(sp)
    80004552:	e862                	sd	s8,16(sp)
    80004554:	e466                	sd	s9,8(sp)
    80004556:	1080                	addi	s0,sp,96
    80004558:	84aa                	mv	s1,a0
    8000455a:	8aae                	mv	s5,a1
    8000455c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000455e:	00054703          	lbu	a4,0(a0)
    80004562:	02f00793          	li	a5,47
    80004566:	02f70363          	beq	a4,a5,8000458c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000456a:	ffffd097          	auipc	ra,0xffffd
    8000456e:	46a080e7          	jalr	1130(ra) # 800019d4 <myproc>
    80004572:	15053503          	ld	a0,336(a0)
    80004576:	00000097          	auipc	ra,0x0
    8000457a:	9f6080e7          	jalr	-1546(ra) # 80003f6c <idup>
    8000457e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004580:	02f00913          	li	s2,47
  len = path - s;
    80004584:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004586:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004588:	4b85                	li	s7,1
    8000458a:	a865                	j	80004642 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000458c:	4585                	li	a1,1
    8000458e:	4505                	li	a0,1
    80004590:	fffff097          	auipc	ra,0xfffff
    80004594:	6e6080e7          	jalr	1766(ra) # 80003c76 <iget>
    80004598:	89aa                	mv	s3,a0
    8000459a:	b7dd                	j	80004580 <namex+0x42>
      iunlockput(ip);
    8000459c:	854e                	mv	a0,s3
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	c6e080e7          	jalr	-914(ra) # 8000420c <iunlockput>
      return 0;
    800045a6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800045a8:	854e                	mv	a0,s3
    800045aa:	60e6                	ld	ra,88(sp)
    800045ac:	6446                	ld	s0,80(sp)
    800045ae:	64a6                	ld	s1,72(sp)
    800045b0:	6906                	ld	s2,64(sp)
    800045b2:	79e2                	ld	s3,56(sp)
    800045b4:	7a42                	ld	s4,48(sp)
    800045b6:	7aa2                	ld	s5,40(sp)
    800045b8:	7b02                	ld	s6,32(sp)
    800045ba:	6be2                	ld	s7,24(sp)
    800045bc:	6c42                	ld	s8,16(sp)
    800045be:	6ca2                	ld	s9,8(sp)
    800045c0:	6125                	addi	sp,sp,96
    800045c2:	8082                	ret
      iunlock(ip);
    800045c4:	854e                	mv	a0,s3
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	aa6080e7          	jalr	-1370(ra) # 8000406c <iunlock>
      return ip;
    800045ce:	bfe9                	j	800045a8 <namex+0x6a>
      iunlockput(ip);
    800045d0:	854e                	mv	a0,s3
    800045d2:	00000097          	auipc	ra,0x0
    800045d6:	c3a080e7          	jalr	-966(ra) # 8000420c <iunlockput>
      return 0;
    800045da:	89e6                	mv	s3,s9
    800045dc:	b7f1                	j	800045a8 <namex+0x6a>
  len = path - s;
    800045de:	40b48633          	sub	a2,s1,a1
    800045e2:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800045e6:	099c5463          	bge	s8,s9,8000466e <namex+0x130>
    memmove(name, s, DIRSIZ);
    800045ea:	4639                	li	a2,14
    800045ec:	8552                	mv	a0,s4
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	72c080e7          	jalr	1836(ra) # 80000d1a <memmove>
  while(*path == '/')
    800045f6:	0004c783          	lbu	a5,0(s1)
    800045fa:	01279763          	bne	a5,s2,80004608 <namex+0xca>
    path++;
    800045fe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004600:	0004c783          	lbu	a5,0(s1)
    80004604:	ff278de3          	beq	a5,s2,800045fe <namex+0xc0>
    ilock(ip);
    80004608:	854e                	mv	a0,s3
    8000460a:	00000097          	auipc	ra,0x0
    8000460e:	9a0080e7          	jalr	-1632(ra) # 80003faa <ilock>
    if(ip->type != T_DIR){
    80004612:	04499783          	lh	a5,68(s3)
    80004616:	f97793e3          	bne	a5,s7,8000459c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000461a:	000a8563          	beqz	s5,80004624 <namex+0xe6>
    8000461e:	0004c783          	lbu	a5,0(s1)
    80004622:	d3cd                	beqz	a5,800045c4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004624:	865a                	mv	a2,s6
    80004626:	85d2                	mv	a1,s4
    80004628:	854e                	mv	a0,s3
    8000462a:	00000097          	auipc	ra,0x0
    8000462e:	e64080e7          	jalr	-412(ra) # 8000448e <dirlookup>
    80004632:	8caa                	mv	s9,a0
    80004634:	dd51                	beqz	a0,800045d0 <namex+0x92>
    iunlockput(ip);
    80004636:	854e                	mv	a0,s3
    80004638:	00000097          	auipc	ra,0x0
    8000463c:	bd4080e7          	jalr	-1068(ra) # 8000420c <iunlockput>
    ip = next;
    80004640:	89e6                	mv	s3,s9
  while(*path == '/')
    80004642:	0004c783          	lbu	a5,0(s1)
    80004646:	05279763          	bne	a5,s2,80004694 <namex+0x156>
    path++;
    8000464a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000464c:	0004c783          	lbu	a5,0(s1)
    80004650:	ff278de3          	beq	a5,s2,8000464a <namex+0x10c>
  if(*path == 0)
    80004654:	c79d                	beqz	a5,80004682 <namex+0x144>
    path++;
    80004656:	85a6                	mv	a1,s1
  len = path - s;
    80004658:	8cda                	mv	s9,s6
    8000465a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000465c:	01278963          	beq	a5,s2,8000466e <namex+0x130>
    80004660:	dfbd                	beqz	a5,800045de <namex+0xa0>
    path++;
    80004662:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004664:	0004c783          	lbu	a5,0(s1)
    80004668:	ff279ce3          	bne	a5,s2,80004660 <namex+0x122>
    8000466c:	bf8d                	j	800045de <namex+0xa0>
    memmove(name, s, len);
    8000466e:	2601                	sext.w	a2,a2
    80004670:	8552                	mv	a0,s4
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	6a8080e7          	jalr	1704(ra) # 80000d1a <memmove>
    name[len] = 0;
    8000467a:	9cd2                	add	s9,s9,s4
    8000467c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004680:	bf9d                	j	800045f6 <namex+0xb8>
  if(nameiparent){
    80004682:	f20a83e3          	beqz	s5,800045a8 <namex+0x6a>
    iput(ip);
    80004686:	854e                	mv	a0,s3
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	adc080e7          	jalr	-1316(ra) # 80004164 <iput>
    return 0;
    80004690:	4981                	li	s3,0
    80004692:	bf19                	j	800045a8 <namex+0x6a>
  if(*path == 0)
    80004694:	d7fd                	beqz	a5,80004682 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004696:	0004c783          	lbu	a5,0(s1)
    8000469a:	85a6                	mv	a1,s1
    8000469c:	b7d1                	j	80004660 <namex+0x122>

000000008000469e <dirlink>:
{
    8000469e:	7139                	addi	sp,sp,-64
    800046a0:	fc06                	sd	ra,56(sp)
    800046a2:	f822                	sd	s0,48(sp)
    800046a4:	f426                	sd	s1,40(sp)
    800046a6:	f04a                	sd	s2,32(sp)
    800046a8:	ec4e                	sd	s3,24(sp)
    800046aa:	e852                	sd	s4,16(sp)
    800046ac:	0080                	addi	s0,sp,64
    800046ae:	892a                	mv	s2,a0
    800046b0:	8a2e                	mv	s4,a1
    800046b2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046b4:	4601                	li	a2,0
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	dd8080e7          	jalr	-552(ra) # 8000448e <dirlookup>
    800046be:	e93d                	bnez	a0,80004734 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046c0:	04c92483          	lw	s1,76(s2)
    800046c4:	c49d                	beqz	s1,800046f2 <dirlink+0x54>
    800046c6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046c8:	4741                	li	a4,16
    800046ca:	86a6                	mv	a3,s1
    800046cc:	fc040613          	addi	a2,s0,-64
    800046d0:	4581                	li	a1,0
    800046d2:	854a                	mv	a0,s2
    800046d4:	00000097          	auipc	ra,0x0
    800046d8:	b8a080e7          	jalr	-1142(ra) # 8000425e <readi>
    800046dc:	47c1                	li	a5,16
    800046de:	06f51163          	bne	a0,a5,80004740 <dirlink+0xa2>
    if(de.inum == 0)
    800046e2:	fc045783          	lhu	a5,-64(s0)
    800046e6:	c791                	beqz	a5,800046f2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046e8:	24c1                	addiw	s1,s1,16
    800046ea:	04c92783          	lw	a5,76(s2)
    800046ee:	fcf4ede3          	bltu	s1,a5,800046c8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800046f2:	4639                	li	a2,14
    800046f4:	85d2                	mv	a1,s4
    800046f6:	fc240513          	addi	a0,s0,-62
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	6d8080e7          	jalr	1752(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004702:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004706:	4741                	li	a4,16
    80004708:	86a6                	mv	a3,s1
    8000470a:	fc040613          	addi	a2,s0,-64
    8000470e:	4581                	li	a1,0
    80004710:	854a                	mv	a0,s2
    80004712:	00000097          	auipc	ra,0x0
    80004716:	c44080e7          	jalr	-956(ra) # 80004356 <writei>
    8000471a:	872a                	mv	a4,a0
    8000471c:	47c1                	li	a5,16
  return 0;
    8000471e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004720:	02f71863          	bne	a4,a5,80004750 <dirlink+0xb2>
}
    80004724:	70e2                	ld	ra,56(sp)
    80004726:	7442                	ld	s0,48(sp)
    80004728:	74a2                	ld	s1,40(sp)
    8000472a:	7902                	ld	s2,32(sp)
    8000472c:	69e2                	ld	s3,24(sp)
    8000472e:	6a42                	ld	s4,16(sp)
    80004730:	6121                	addi	sp,sp,64
    80004732:	8082                	ret
    iput(ip);
    80004734:	00000097          	auipc	ra,0x0
    80004738:	a30080e7          	jalr	-1488(ra) # 80004164 <iput>
    return -1;
    8000473c:	557d                	li	a0,-1
    8000473e:	b7dd                	j	80004724 <dirlink+0x86>
      panic("dirlink read");
    80004740:	00005517          	auipc	a0,0x5
    80004744:	1a050513          	addi	a0,a0,416 # 800098e0 <syscalls+0x1c8>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	de2080e7          	jalr	-542(ra) # 8000052a <panic>
    panic("dirlink");
    80004750:	00005517          	auipc	a0,0x5
    80004754:	31850513          	addi	a0,a0,792 # 80009a68 <syscalls+0x350>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	dd2080e7          	jalr	-558(ra) # 8000052a <panic>

0000000080004760 <namei>:

struct inode*
namei(char *path)
{
    80004760:	1101                	addi	sp,sp,-32
    80004762:	ec06                	sd	ra,24(sp)
    80004764:	e822                	sd	s0,16(sp)
    80004766:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004768:	fe040613          	addi	a2,s0,-32
    8000476c:	4581                	li	a1,0
    8000476e:	00000097          	auipc	ra,0x0
    80004772:	dd0080e7          	jalr	-560(ra) # 8000453e <namex>
}
    80004776:	60e2                	ld	ra,24(sp)
    80004778:	6442                	ld	s0,16(sp)
    8000477a:	6105                	addi	sp,sp,32
    8000477c:	8082                	ret

000000008000477e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000477e:	1141                	addi	sp,sp,-16
    80004780:	e406                	sd	ra,8(sp)
    80004782:	e022                	sd	s0,0(sp)
    80004784:	0800                	addi	s0,sp,16
    80004786:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004788:	4585                	li	a1,1
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	db4080e7          	jalr	-588(ra) # 8000453e <namex>
}
    80004792:	60a2                	ld	ra,8(sp)
    80004794:	6402                	ld	s0,0(sp)
    80004796:	0141                	addi	sp,sp,16
    80004798:	8082                	ret

000000008000479a <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    8000479a:	1101                	addi	sp,sp,-32
    8000479c:	ec22                	sd	s0,24(sp)
    8000479e:	1000                	addi	s0,sp,32
    800047a0:	872a                	mv	a4,a0
    800047a2:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800047a4:	00005797          	auipc	a5,0x5
    800047a8:	14c78793          	addi	a5,a5,332 # 800098f0 <syscalls+0x1d8>
    800047ac:	6394                	ld	a3,0(a5)
    800047ae:	fed43023          	sd	a3,-32(s0)
    800047b2:	0087d683          	lhu	a3,8(a5)
    800047b6:	fed41423          	sh	a3,-24(s0)
    800047ba:	00a7c783          	lbu	a5,10(a5)
    800047be:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800047c2:	87ae                	mv	a5,a1
    if(i<0){
    800047c4:	02074b63          	bltz	a4,800047fa <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800047c8:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800047ca:	4629                	li	a2,10
        ++p;
    800047cc:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800047ce:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800047d2:	feed                	bnez	a3,800047cc <itoa+0x32>
    *p = '\0';
    800047d4:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800047d8:	4629                	li	a2,10
    800047da:	17fd                	addi	a5,a5,-1
    800047dc:	02c766bb          	remw	a3,a4,a2
    800047e0:	ff040593          	addi	a1,s0,-16
    800047e4:	96ae                	add	a3,a3,a1
    800047e6:	ff06c683          	lbu	a3,-16(a3)
    800047ea:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800047ee:	02c7473b          	divw	a4,a4,a2
    }while(i);
    800047f2:	f765                	bnez	a4,800047da <itoa+0x40>
    return b;
}
    800047f4:	6462                	ld	s0,24(sp)
    800047f6:	6105                	addi	sp,sp,32
    800047f8:	8082                	ret
        *p++ = '-';
    800047fa:	00158793          	addi	a5,a1,1
    800047fe:	02d00693          	li	a3,45
    80004802:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004806:	40e0073b          	negw	a4,a4
    8000480a:	bf7d                	j	800047c8 <itoa+0x2e>

000000008000480c <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    8000480c:	711d                	addi	sp,sp,-96
    8000480e:	ec86                	sd	ra,88(sp)
    80004810:	e8a2                	sd	s0,80(sp)
    80004812:	e4a6                	sd	s1,72(sp)
    80004814:	e0ca                	sd	s2,64(sp)
    80004816:	1080                	addi	s0,sp,96
    80004818:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000481a:	4619                	li	a2,6
    8000481c:	00005597          	auipc	a1,0x5
    80004820:	0e458593          	addi	a1,a1,228 # 80009900 <syscalls+0x1e8>
    80004824:	fd040513          	addi	a0,s0,-48
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	4f2080e7          	jalr	1266(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004830:	fd640593          	addi	a1,s0,-42
    80004834:	5888                	lw	a0,48(s1)
    80004836:	00000097          	auipc	ra,0x0
    8000483a:	f64080e7          	jalr	-156(ra) # 8000479a <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    8000483e:	1684b503          	ld	a0,360(s1)
    80004842:	16050763          	beqz	a0,800049b0 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004846:	00001097          	auipc	ra,0x1
    8000484a:	918080e7          	jalr	-1768(ra) # 8000515e <fileclose>

  begin_op();
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	444080e7          	jalr	1092(ra) # 80004c92 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    80004856:	fb040593          	addi	a1,s0,-80
    8000485a:	fd040513          	addi	a0,s0,-48
    8000485e:	00000097          	auipc	ra,0x0
    80004862:	f20080e7          	jalr	-224(ra) # 8000477e <nameiparent>
    80004866:	892a                	mv	s2,a0
    80004868:	cd69                	beqz	a0,80004942 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	740080e7          	jalr	1856(ra) # 80003faa <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004872:	00005597          	auipc	a1,0x5
    80004876:	09658593          	addi	a1,a1,150 # 80009908 <syscalls+0x1f0>
    8000487a:	fb040513          	addi	a0,s0,-80
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	bf6080e7          	jalr	-1034(ra) # 80004474 <namecmp>
    80004886:	c57d                	beqz	a0,80004974 <removeSwapFile+0x168>
    80004888:	00005597          	auipc	a1,0x5
    8000488c:	08858593          	addi	a1,a1,136 # 80009910 <syscalls+0x1f8>
    80004890:	fb040513          	addi	a0,s0,-80
    80004894:	00000097          	auipc	ra,0x0
    80004898:	be0080e7          	jalr	-1056(ra) # 80004474 <namecmp>
    8000489c:	cd61                	beqz	a0,80004974 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    8000489e:	fac40613          	addi	a2,s0,-84
    800048a2:	fb040593          	addi	a1,s0,-80
    800048a6:	854a                	mv	a0,s2
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	be6080e7          	jalr	-1050(ra) # 8000448e <dirlookup>
    800048b0:	84aa                	mv	s1,a0
    800048b2:	c169                	beqz	a0,80004974 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	6f6080e7          	jalr	1782(ra) # 80003faa <ilock>

  if(ip->nlink < 1)
    800048bc:	04a49783          	lh	a5,74(s1)
    800048c0:	08f05763          	blez	a5,8000494e <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800048c4:	04449703          	lh	a4,68(s1)
    800048c8:	4785                	li	a5,1
    800048ca:	08f70a63          	beq	a4,a5,8000495e <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800048ce:	4641                	li	a2,16
    800048d0:	4581                	li	a1,0
    800048d2:	fc040513          	addi	a0,s0,-64
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	3e8080e7          	jalr	1000(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048de:	4741                	li	a4,16
    800048e0:	fac42683          	lw	a3,-84(s0)
    800048e4:	fc040613          	addi	a2,s0,-64
    800048e8:	4581                	li	a1,0
    800048ea:	854a                	mv	a0,s2
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	a6a080e7          	jalr	-1430(ra) # 80004356 <writei>
    800048f4:	47c1                	li	a5,16
    800048f6:	08f51a63          	bne	a0,a5,8000498a <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800048fa:	04449703          	lh	a4,68(s1)
    800048fe:	4785                	li	a5,1
    80004900:	08f70d63          	beq	a4,a5,8000499a <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004904:	854a                	mv	a0,s2
    80004906:	00000097          	auipc	ra,0x0
    8000490a:	906080e7          	jalr	-1786(ra) # 8000420c <iunlockput>

  ip->nlink--;
    8000490e:	04a4d783          	lhu	a5,74(s1)
    80004912:	37fd                	addiw	a5,a5,-1
    80004914:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004918:	8526                	mv	a0,s1
    8000491a:	fffff097          	auipc	ra,0xfffff
    8000491e:	5c6080e7          	jalr	1478(ra) # 80003ee0 <iupdate>
  iunlockput(ip);
    80004922:	8526                	mv	a0,s1
    80004924:	00000097          	auipc	ra,0x0
    80004928:	8e8080e7          	jalr	-1816(ra) # 8000420c <iunlockput>

  end_op();
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	3e6080e7          	jalr	998(ra) # 80004d12 <end_op>

  return 0;
    80004934:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004936:	60e6                	ld	ra,88(sp)
    80004938:	6446                	ld	s0,80(sp)
    8000493a:	64a6                	ld	s1,72(sp)
    8000493c:	6906                	ld	s2,64(sp)
    8000493e:	6125                	addi	sp,sp,96
    80004940:	8082                	ret
    end_op();
    80004942:	00000097          	auipc	ra,0x0
    80004946:	3d0080e7          	jalr	976(ra) # 80004d12 <end_op>
    return -1;
    8000494a:	557d                	li	a0,-1
    8000494c:	b7ed                	j	80004936 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    8000494e:	00005517          	auipc	a0,0x5
    80004952:	fca50513          	addi	a0,a0,-54 # 80009918 <syscalls+0x200>
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	bd4080e7          	jalr	-1068(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000495e:	8526                	mv	a0,s1
    80004960:	00002097          	auipc	ra,0x2
    80004964:	866080e7          	jalr	-1946(ra) # 800061c6 <isdirempty>
    80004968:	f13d                	bnez	a0,800048ce <removeSwapFile+0xc2>
    iunlockput(ip);
    8000496a:	8526                	mv	a0,s1
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	8a0080e7          	jalr	-1888(ra) # 8000420c <iunlockput>
    iunlockput(dp);
    80004974:	854a                	mv	a0,s2
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	896080e7          	jalr	-1898(ra) # 8000420c <iunlockput>
    end_op();
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	394080e7          	jalr	916(ra) # 80004d12 <end_op>
    return -1;
    80004986:	557d                	li	a0,-1
    80004988:	b77d                	j	80004936 <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000498a:	00005517          	auipc	a0,0x5
    8000498e:	fa650513          	addi	a0,a0,-90 # 80009930 <syscalls+0x218>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	b98080e7          	jalr	-1128(ra) # 8000052a <panic>
    dp->nlink--;
    8000499a:	04a95783          	lhu	a5,74(s2)
    8000499e:	37fd                	addiw	a5,a5,-1
    800049a0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800049a4:	854a                	mv	a0,s2
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	53a080e7          	jalr	1338(ra) # 80003ee0 <iupdate>
    800049ae:	bf99                	j	80004904 <removeSwapFile+0xf8>
    return -1;
    800049b0:	557d                	li	a0,-1
    800049b2:	b751                	j	80004936 <removeSwapFile+0x12a>

00000000800049b4 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800049b4:	7179                	addi	sp,sp,-48
    800049b6:	f406                	sd	ra,40(sp)
    800049b8:	f022                	sd	s0,32(sp)
    800049ba:	ec26                	sd	s1,24(sp)
    800049bc:	e84a                	sd	s2,16(sp)
    800049be:	1800                	addi	s0,sp,48
    800049c0:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800049c2:	4619                	li	a2,6
    800049c4:	00005597          	auipc	a1,0x5
    800049c8:	f3c58593          	addi	a1,a1,-196 # 80009900 <syscalls+0x1e8>
    800049cc:	fd040513          	addi	a0,s0,-48
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	34a080e7          	jalr	842(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800049d8:	fd640593          	addi	a1,s0,-42
    800049dc:	5888                	lw	a0,48(s1)
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	dbc080e7          	jalr	-580(ra) # 8000479a <itoa>

  begin_op();
    800049e6:	00000097          	auipc	ra,0x0
    800049ea:	2ac080e7          	jalr	684(ra) # 80004c92 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    800049ee:	4681                	li	a3,0
    800049f0:	4601                	li	a2,0
    800049f2:	4589                	li	a1,2
    800049f4:	fd040513          	addi	a0,s0,-48
    800049f8:	00002097          	auipc	ra,0x2
    800049fc:	9c2080e7          	jalr	-1598(ra) # 800063ba <create>
    80004a00:	892a                	mv	s2,a0
  iunlock(in);
    80004a02:	fffff097          	auipc	ra,0xfffff
    80004a06:	66a080e7          	jalr	1642(ra) # 8000406c <iunlock>
  p->swapFile = filealloc();
    80004a0a:	00000097          	auipc	ra,0x0
    80004a0e:	698080e7          	jalr	1688(ra) # 800050a2 <filealloc>
    80004a12:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004a16:	cd1d                	beqz	a0,80004a54 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    80004a18:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004a1c:	1684b703          	ld	a4,360(s1)
    80004a20:	4789                	li	a5,2
    80004a22:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004a24:	1684b703          	ld	a4,360(s1)
    80004a28:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004a2c:	1684b703          	ld	a4,360(s1)
    80004a30:	4685                	li	a3,1
    80004a32:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004a36:	1684b703          	ld	a4,360(s1)
    80004a3a:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	2d4080e7          	jalr	724(ra) # 80004d12 <end_op>

    return 0;
}
    80004a46:	4501                	li	a0,0
    80004a48:	70a2                	ld	ra,40(sp)
    80004a4a:	7402                	ld	s0,32(sp)
    80004a4c:	64e2                	ld	s1,24(sp)
    80004a4e:	6942                	ld	s2,16(sp)
    80004a50:	6145                	addi	sp,sp,48
    80004a52:	8082                	ret
    panic("no slot for files on /store");
    80004a54:	00005517          	auipc	a0,0x5
    80004a58:	eec50513          	addi	a0,a0,-276 # 80009940 <syscalls+0x228>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	ace080e7          	jalr	-1330(ra) # 8000052a <panic>

0000000080004a64 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a64:	1141                	addi	sp,sp,-16
    80004a66:	e406                	sd	ra,8(sp)
    80004a68:	e022                	sd	s0,0(sp)
    80004a6a:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a6c:	16853783          	ld	a5,360(a0)
    80004a70:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004a72:	8636                	mv	a2,a3
    80004a74:	16853503          	ld	a0,360(a0)
    80004a78:	00001097          	auipc	ra,0x1
    80004a7c:	ad8080e7          	jalr	-1320(ra) # 80005550 <kfilewrite>
}
    80004a80:	60a2                	ld	ra,8(sp)
    80004a82:	6402                	ld	s0,0(sp)
    80004a84:	0141                	addi	sp,sp,16
    80004a86:	8082                	ret

0000000080004a88 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a88:	1141                	addi	sp,sp,-16
    80004a8a:	e406                	sd	ra,8(sp)
    80004a8c:	e022                	sd	s0,0(sp)
    80004a8e:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a90:	16853783          	ld	a5,360(a0)
    80004a94:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004a96:	8636                	mv	a2,a3
    80004a98:	16853503          	ld	a0,360(a0)
    80004a9c:	00001097          	auipc	ra,0x1
    80004aa0:	9f2080e7          	jalr	-1550(ra) # 8000548e <kfileread>
    80004aa4:	60a2                	ld	ra,8(sp)
    80004aa6:	6402                	ld	s0,0(sp)
    80004aa8:	0141                	addi	sp,sp,16
    80004aaa:	8082                	ret

0000000080004aac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004aac:	1101                	addi	sp,sp,-32
    80004aae:	ec06                	sd	ra,24(sp)
    80004ab0:	e822                	sd	s0,16(sp)
    80004ab2:	e426                	sd	s1,8(sp)
    80004ab4:	e04a                	sd	s2,0(sp)
    80004ab6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004ab8:	00026917          	auipc	s2,0x26
    80004abc:	bb890913          	addi	s2,s2,-1096 # 8002a670 <log>
    80004ac0:	01892583          	lw	a1,24(s2)
    80004ac4:	02892503          	lw	a0,40(s2)
    80004ac8:	fffff097          	auipc	ra,0xfffff
    80004acc:	cde080e7          	jalr	-802(ra) # 800037a6 <bread>
    80004ad0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004ad2:	02c92683          	lw	a3,44(s2)
    80004ad6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004ad8:	02d05863          	blez	a3,80004b08 <write_head+0x5c>
    80004adc:	00026797          	auipc	a5,0x26
    80004ae0:	bc478793          	addi	a5,a5,-1084 # 8002a6a0 <log+0x30>
    80004ae4:	05c50713          	addi	a4,a0,92
    80004ae8:	36fd                	addiw	a3,a3,-1
    80004aea:	02069613          	slli	a2,a3,0x20
    80004aee:	01e65693          	srli	a3,a2,0x1e
    80004af2:	00026617          	auipc	a2,0x26
    80004af6:	bb260613          	addi	a2,a2,-1102 # 8002a6a4 <log+0x34>
    80004afa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004afc:	4390                	lw	a2,0(a5)
    80004afe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b00:	0791                	addi	a5,a5,4
    80004b02:	0711                	addi	a4,a4,4
    80004b04:	fed79ce3          	bne	a5,a3,80004afc <write_head+0x50>
  }
  bwrite(buf);
    80004b08:	8526                	mv	a0,s1
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	d8e080e7          	jalr	-626(ra) # 80003898 <bwrite>
  brelse(buf);
    80004b12:	8526                	mv	a0,s1
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	dc2080e7          	jalr	-574(ra) # 800038d6 <brelse>
}
    80004b1c:	60e2                	ld	ra,24(sp)
    80004b1e:	6442                	ld	s0,16(sp)
    80004b20:	64a2                	ld	s1,8(sp)
    80004b22:	6902                	ld	s2,0(sp)
    80004b24:	6105                	addi	sp,sp,32
    80004b26:	8082                	ret

0000000080004b28 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b28:	00026797          	auipc	a5,0x26
    80004b2c:	b747a783          	lw	a5,-1164(a5) # 8002a69c <log+0x2c>
    80004b30:	0af05d63          	blez	a5,80004bea <install_trans+0xc2>
{
    80004b34:	7139                	addi	sp,sp,-64
    80004b36:	fc06                	sd	ra,56(sp)
    80004b38:	f822                	sd	s0,48(sp)
    80004b3a:	f426                	sd	s1,40(sp)
    80004b3c:	f04a                	sd	s2,32(sp)
    80004b3e:	ec4e                	sd	s3,24(sp)
    80004b40:	e852                	sd	s4,16(sp)
    80004b42:	e456                	sd	s5,8(sp)
    80004b44:	e05a                	sd	s6,0(sp)
    80004b46:	0080                	addi	s0,sp,64
    80004b48:	8b2a                	mv	s6,a0
    80004b4a:	00026a97          	auipc	s5,0x26
    80004b4e:	b56a8a93          	addi	s5,s5,-1194 # 8002a6a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b52:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b54:	00026997          	auipc	s3,0x26
    80004b58:	b1c98993          	addi	s3,s3,-1252 # 8002a670 <log>
    80004b5c:	a00d                	j	80004b7e <install_trans+0x56>
    brelse(lbuf);
    80004b5e:	854a                	mv	a0,s2
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	d76080e7          	jalr	-650(ra) # 800038d6 <brelse>
    brelse(dbuf);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	fffff097          	auipc	ra,0xfffff
    80004b6e:	d6c080e7          	jalr	-660(ra) # 800038d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b72:	2a05                	addiw	s4,s4,1
    80004b74:	0a91                	addi	s5,s5,4
    80004b76:	02c9a783          	lw	a5,44(s3)
    80004b7a:	04fa5e63          	bge	s4,a5,80004bd6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b7e:	0189a583          	lw	a1,24(s3)
    80004b82:	014585bb          	addw	a1,a1,s4
    80004b86:	2585                	addiw	a1,a1,1
    80004b88:	0289a503          	lw	a0,40(s3)
    80004b8c:	fffff097          	auipc	ra,0xfffff
    80004b90:	c1a080e7          	jalr	-998(ra) # 800037a6 <bread>
    80004b94:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b96:	000aa583          	lw	a1,0(s5)
    80004b9a:	0289a503          	lw	a0,40(s3)
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	c08080e7          	jalr	-1016(ra) # 800037a6 <bread>
    80004ba6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004ba8:	40000613          	li	a2,1024
    80004bac:	05890593          	addi	a1,s2,88
    80004bb0:	05850513          	addi	a0,a0,88
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	166080e7          	jalr	358(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	fffff097          	auipc	ra,0xfffff
    80004bc2:	cda080e7          	jalr	-806(ra) # 80003898 <bwrite>
    if(recovering == 0)
    80004bc6:	f80b1ce3          	bnez	s6,80004b5e <install_trans+0x36>
      bunpin(dbuf);
    80004bca:	8526                	mv	a0,s1
    80004bcc:	fffff097          	auipc	ra,0xfffff
    80004bd0:	de4080e7          	jalr	-540(ra) # 800039b0 <bunpin>
    80004bd4:	b769                	j	80004b5e <install_trans+0x36>
}
    80004bd6:	70e2                	ld	ra,56(sp)
    80004bd8:	7442                	ld	s0,48(sp)
    80004bda:	74a2                	ld	s1,40(sp)
    80004bdc:	7902                	ld	s2,32(sp)
    80004bde:	69e2                	ld	s3,24(sp)
    80004be0:	6a42                	ld	s4,16(sp)
    80004be2:	6aa2                	ld	s5,8(sp)
    80004be4:	6b02                	ld	s6,0(sp)
    80004be6:	6121                	addi	sp,sp,64
    80004be8:	8082                	ret
    80004bea:	8082                	ret

0000000080004bec <initlog>:
{
    80004bec:	7179                	addi	sp,sp,-48
    80004bee:	f406                	sd	ra,40(sp)
    80004bf0:	f022                	sd	s0,32(sp)
    80004bf2:	ec26                	sd	s1,24(sp)
    80004bf4:	e84a                	sd	s2,16(sp)
    80004bf6:	e44e                	sd	s3,8(sp)
    80004bf8:	1800                	addi	s0,sp,48
    80004bfa:	892a                	mv	s2,a0
    80004bfc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004bfe:	00026497          	auipc	s1,0x26
    80004c02:	a7248493          	addi	s1,s1,-1422 # 8002a670 <log>
    80004c06:	00005597          	auipc	a1,0x5
    80004c0a:	d5a58593          	addi	a1,a1,-678 # 80009960 <syscalls+0x248>
    80004c0e:	8526                	mv	a0,s1
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	f22080e7          	jalr	-222(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004c18:	0149a583          	lw	a1,20(s3)
    80004c1c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c1e:	0109a783          	lw	a5,16(s3)
    80004c22:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c24:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c28:	854a                	mv	a0,s2
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	b7c080e7          	jalr	-1156(ra) # 800037a6 <bread>
  log.lh.n = lh->n;
    80004c32:	4d34                	lw	a3,88(a0)
    80004c34:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c36:	02d05663          	blez	a3,80004c62 <initlog+0x76>
    80004c3a:	05c50793          	addi	a5,a0,92
    80004c3e:	00026717          	auipc	a4,0x26
    80004c42:	a6270713          	addi	a4,a4,-1438 # 8002a6a0 <log+0x30>
    80004c46:	36fd                	addiw	a3,a3,-1
    80004c48:	02069613          	slli	a2,a3,0x20
    80004c4c:	01e65693          	srli	a3,a2,0x1e
    80004c50:	06050613          	addi	a2,a0,96
    80004c54:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004c56:	4390                	lw	a2,0(a5)
    80004c58:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004c5a:	0791                	addi	a5,a5,4
    80004c5c:	0711                	addi	a4,a4,4
    80004c5e:	fed79ce3          	bne	a5,a3,80004c56 <initlog+0x6a>
  brelse(buf);
    80004c62:	fffff097          	auipc	ra,0xfffff
    80004c66:	c74080e7          	jalr	-908(ra) # 800038d6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c6a:	4505                	li	a0,1
    80004c6c:	00000097          	auipc	ra,0x0
    80004c70:	ebc080e7          	jalr	-324(ra) # 80004b28 <install_trans>
  log.lh.n = 0;
    80004c74:	00026797          	auipc	a5,0x26
    80004c78:	a207a423          	sw	zero,-1496(a5) # 8002a69c <log+0x2c>
  write_head(); // clear the log
    80004c7c:	00000097          	auipc	ra,0x0
    80004c80:	e30080e7          	jalr	-464(ra) # 80004aac <write_head>
}
    80004c84:	70a2                	ld	ra,40(sp)
    80004c86:	7402                	ld	s0,32(sp)
    80004c88:	64e2                	ld	s1,24(sp)
    80004c8a:	6942                	ld	s2,16(sp)
    80004c8c:	69a2                	ld	s3,8(sp)
    80004c8e:	6145                	addi	sp,sp,48
    80004c90:	8082                	ret

0000000080004c92 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c92:	1101                	addi	sp,sp,-32
    80004c94:	ec06                	sd	ra,24(sp)
    80004c96:	e822                	sd	s0,16(sp)
    80004c98:	e426                	sd	s1,8(sp)
    80004c9a:	e04a                	sd	s2,0(sp)
    80004c9c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c9e:	00026517          	auipc	a0,0x26
    80004ca2:	9d250513          	addi	a0,a0,-1582 # 8002a670 <log>
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	f1c080e7          	jalr	-228(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004cae:	00026497          	auipc	s1,0x26
    80004cb2:	9c248493          	addi	s1,s1,-1598 # 8002a670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cb6:	4979                	li	s2,30
    80004cb8:	a039                	j	80004cc6 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004cba:	85a6                	mv	a1,s1
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	3ac080e7          	jalr	940(ra) # 8000206a <sleep>
    if(log.committing){
    80004cc6:	50dc                	lw	a5,36(s1)
    80004cc8:	fbed                	bnez	a5,80004cba <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cca:	509c                	lw	a5,32(s1)
    80004ccc:	0017871b          	addiw	a4,a5,1
    80004cd0:	0007069b          	sext.w	a3,a4
    80004cd4:	0027179b          	slliw	a5,a4,0x2
    80004cd8:	9fb9                	addw	a5,a5,a4
    80004cda:	0017979b          	slliw	a5,a5,0x1
    80004cde:	54d8                	lw	a4,44(s1)
    80004ce0:	9fb9                	addw	a5,a5,a4
    80004ce2:	00f95963          	bge	s2,a5,80004cf4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004ce6:	85a6                	mv	a1,s1
    80004ce8:	8526                	mv	a0,s1
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	380080e7          	jalr	896(ra) # 8000206a <sleep>
    80004cf2:	bfd1                	j	80004cc6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004cf4:	00026517          	auipc	a0,0x26
    80004cf8:	97c50513          	addi	a0,a0,-1668 # 8002a670 <log>
    80004cfc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	f78080e7          	jalr	-136(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004d06:	60e2                	ld	ra,24(sp)
    80004d08:	6442                	ld	s0,16(sp)
    80004d0a:	64a2                	ld	s1,8(sp)
    80004d0c:	6902                	ld	s2,0(sp)
    80004d0e:	6105                	addi	sp,sp,32
    80004d10:	8082                	ret

0000000080004d12 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d12:	7139                	addi	sp,sp,-64
    80004d14:	fc06                	sd	ra,56(sp)
    80004d16:	f822                	sd	s0,48(sp)
    80004d18:	f426                	sd	s1,40(sp)
    80004d1a:	f04a                	sd	s2,32(sp)
    80004d1c:	ec4e                	sd	s3,24(sp)
    80004d1e:	e852                	sd	s4,16(sp)
    80004d20:	e456                	sd	s5,8(sp)
    80004d22:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d24:	00026497          	auipc	s1,0x26
    80004d28:	94c48493          	addi	s1,s1,-1716 # 8002a670 <log>
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	e94080e7          	jalr	-364(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004d36:	509c                	lw	a5,32(s1)
    80004d38:	37fd                	addiw	a5,a5,-1
    80004d3a:	0007891b          	sext.w	s2,a5
    80004d3e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d40:	50dc                	lw	a5,36(s1)
    80004d42:	e7b9                	bnez	a5,80004d90 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d44:	04091e63          	bnez	s2,80004da0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004d48:	00026497          	auipc	s1,0x26
    80004d4c:	92848493          	addi	s1,s1,-1752 # 8002a670 <log>
    80004d50:	4785                	li	a5,1
    80004d52:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d54:	8526                	mv	a0,s1
    80004d56:	ffffc097          	auipc	ra,0xffffc
    80004d5a:	f20080e7          	jalr	-224(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d5e:	54dc                	lw	a5,44(s1)
    80004d60:	06f04763          	bgtz	a5,80004dce <end_op+0xbc>
    acquire(&log.lock);
    80004d64:	00026497          	auipc	s1,0x26
    80004d68:	90c48493          	addi	s1,s1,-1780 # 8002a670 <log>
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	e54080e7          	jalr	-428(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004d76:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d7a:	8526                	mv	a0,s1
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	352080e7          	jalr	850(ra) # 800020ce <wakeup>
    release(&log.lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	ef0080e7          	jalr	-272(ra) # 80000c76 <release>
}
    80004d8e:	a03d                	j	80004dbc <end_op+0xaa>
    panic("log.committing");
    80004d90:	00005517          	auipc	a0,0x5
    80004d94:	bd850513          	addi	a0,a0,-1064 # 80009968 <syscalls+0x250>
    80004d98:	ffffb097          	auipc	ra,0xffffb
    80004d9c:	792080e7          	jalr	1938(ra) # 8000052a <panic>
    wakeup(&log);
    80004da0:	00026497          	auipc	s1,0x26
    80004da4:	8d048493          	addi	s1,s1,-1840 # 8002a670 <log>
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	324080e7          	jalr	804(ra) # 800020ce <wakeup>
  release(&log.lock);
    80004db2:	8526                	mv	a0,s1
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	ec2080e7          	jalr	-318(ra) # 80000c76 <release>
}
    80004dbc:	70e2                	ld	ra,56(sp)
    80004dbe:	7442                	ld	s0,48(sp)
    80004dc0:	74a2                	ld	s1,40(sp)
    80004dc2:	7902                	ld	s2,32(sp)
    80004dc4:	69e2                	ld	s3,24(sp)
    80004dc6:	6a42                	ld	s4,16(sp)
    80004dc8:	6aa2                	ld	s5,8(sp)
    80004dca:	6121                	addi	sp,sp,64
    80004dcc:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dce:	00026a97          	auipc	s5,0x26
    80004dd2:	8d2a8a93          	addi	s5,s5,-1838 # 8002a6a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dd6:	00026a17          	auipc	s4,0x26
    80004dda:	89aa0a13          	addi	s4,s4,-1894 # 8002a670 <log>
    80004dde:	018a2583          	lw	a1,24(s4)
    80004de2:	012585bb          	addw	a1,a1,s2
    80004de6:	2585                	addiw	a1,a1,1
    80004de8:	028a2503          	lw	a0,40(s4)
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	9ba080e7          	jalr	-1606(ra) # 800037a6 <bread>
    80004df4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004df6:	000aa583          	lw	a1,0(s5)
    80004dfa:	028a2503          	lw	a0,40(s4)
    80004dfe:	fffff097          	auipc	ra,0xfffff
    80004e02:	9a8080e7          	jalr	-1624(ra) # 800037a6 <bread>
    80004e06:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e08:	40000613          	li	a2,1024
    80004e0c:	05850593          	addi	a1,a0,88
    80004e10:	05848513          	addi	a0,s1,88
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	f06080e7          	jalr	-250(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	fffff097          	auipc	ra,0xfffff
    80004e22:	a7a080e7          	jalr	-1414(ra) # 80003898 <bwrite>
    brelse(from);
    80004e26:	854e                	mv	a0,s3
    80004e28:	fffff097          	auipc	ra,0xfffff
    80004e2c:	aae080e7          	jalr	-1362(ra) # 800038d6 <brelse>
    brelse(to);
    80004e30:	8526                	mv	a0,s1
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	aa4080e7          	jalr	-1372(ra) # 800038d6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e3a:	2905                	addiw	s2,s2,1
    80004e3c:	0a91                	addi	s5,s5,4
    80004e3e:	02ca2783          	lw	a5,44(s4)
    80004e42:	f8f94ee3          	blt	s2,a5,80004dde <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e46:	00000097          	auipc	ra,0x0
    80004e4a:	c66080e7          	jalr	-922(ra) # 80004aac <write_head>
    install_trans(0); // Now install writes to home locations
    80004e4e:	4501                	li	a0,0
    80004e50:	00000097          	auipc	ra,0x0
    80004e54:	cd8080e7          	jalr	-808(ra) # 80004b28 <install_trans>
    log.lh.n = 0;
    80004e58:	00026797          	auipc	a5,0x26
    80004e5c:	8407a223          	sw	zero,-1980(a5) # 8002a69c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e60:	00000097          	auipc	ra,0x0
    80004e64:	c4c080e7          	jalr	-948(ra) # 80004aac <write_head>
    80004e68:	bdf5                	j	80004d64 <end_op+0x52>

0000000080004e6a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e6a:	1101                	addi	sp,sp,-32
    80004e6c:	ec06                	sd	ra,24(sp)
    80004e6e:	e822                	sd	s0,16(sp)
    80004e70:	e426                	sd	s1,8(sp)
    80004e72:	e04a                	sd	s2,0(sp)
    80004e74:	1000                	addi	s0,sp,32
    80004e76:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e78:	00025917          	auipc	s2,0x25
    80004e7c:	7f890913          	addi	s2,s2,2040 # 8002a670 <log>
    80004e80:	854a                	mv	a0,s2
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	d40080e7          	jalr	-704(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e8a:	02c92603          	lw	a2,44(s2)
    80004e8e:	47f5                	li	a5,29
    80004e90:	06c7c563          	blt	a5,a2,80004efa <log_write+0x90>
    80004e94:	00025797          	auipc	a5,0x25
    80004e98:	7f87a783          	lw	a5,2040(a5) # 8002a68c <log+0x1c>
    80004e9c:	37fd                	addiw	a5,a5,-1
    80004e9e:	04f65e63          	bge	a2,a5,80004efa <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ea2:	00025797          	auipc	a5,0x25
    80004ea6:	7ee7a783          	lw	a5,2030(a5) # 8002a690 <log+0x20>
    80004eaa:	06f05063          	blez	a5,80004f0a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004eae:	4781                	li	a5,0
    80004eb0:	06c05563          	blez	a2,80004f1a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004eb4:	44cc                	lw	a1,12(s1)
    80004eb6:	00025717          	auipc	a4,0x25
    80004eba:	7ea70713          	addi	a4,a4,2026 # 8002a6a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ebe:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004ec0:	4314                	lw	a3,0(a4)
    80004ec2:	04b68c63          	beq	a3,a1,80004f1a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004ec6:	2785                	addiw	a5,a5,1
    80004ec8:	0711                	addi	a4,a4,4
    80004eca:	fef61be3          	bne	a2,a5,80004ec0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ece:	0621                	addi	a2,a2,8
    80004ed0:	060a                	slli	a2,a2,0x2
    80004ed2:	00025797          	auipc	a5,0x25
    80004ed6:	79e78793          	addi	a5,a5,1950 # 8002a670 <log>
    80004eda:	963e                	add	a2,a2,a5
    80004edc:	44dc                	lw	a5,12(s1)
    80004ede:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	a92080e7          	jalr	-1390(ra) # 80003974 <bpin>
    log.lh.n++;
    80004eea:	00025717          	auipc	a4,0x25
    80004eee:	78670713          	addi	a4,a4,1926 # 8002a670 <log>
    80004ef2:	575c                	lw	a5,44(a4)
    80004ef4:	2785                	addiw	a5,a5,1
    80004ef6:	d75c                	sw	a5,44(a4)
    80004ef8:	a835                	j	80004f34 <log_write+0xca>
    panic("too big a transaction");
    80004efa:	00005517          	auipc	a0,0x5
    80004efe:	a7e50513          	addi	a0,a0,-1410 # 80009978 <syscalls+0x260>
    80004f02:	ffffb097          	auipc	ra,0xffffb
    80004f06:	628080e7          	jalr	1576(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004f0a:	00005517          	auipc	a0,0x5
    80004f0e:	a8650513          	addi	a0,a0,-1402 # 80009990 <syscalls+0x278>
    80004f12:	ffffb097          	auipc	ra,0xffffb
    80004f16:	618080e7          	jalr	1560(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004f1a:	00878713          	addi	a4,a5,8
    80004f1e:	00271693          	slli	a3,a4,0x2
    80004f22:	00025717          	auipc	a4,0x25
    80004f26:	74e70713          	addi	a4,a4,1870 # 8002a670 <log>
    80004f2a:	9736                	add	a4,a4,a3
    80004f2c:	44d4                	lw	a3,12(s1)
    80004f2e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f30:	faf608e3          	beq	a2,a5,80004ee0 <log_write+0x76>
  }
  release(&log.lock);
    80004f34:	00025517          	auipc	a0,0x25
    80004f38:	73c50513          	addi	a0,a0,1852 # 8002a670 <log>
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	d3a080e7          	jalr	-710(ra) # 80000c76 <release>
}
    80004f44:	60e2                	ld	ra,24(sp)
    80004f46:	6442                	ld	s0,16(sp)
    80004f48:	64a2                	ld	s1,8(sp)
    80004f4a:	6902                	ld	s2,0(sp)
    80004f4c:	6105                	addi	sp,sp,32
    80004f4e:	8082                	ret

0000000080004f50 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f50:	1101                	addi	sp,sp,-32
    80004f52:	ec06                	sd	ra,24(sp)
    80004f54:	e822                	sd	s0,16(sp)
    80004f56:	e426                	sd	s1,8(sp)
    80004f58:	e04a                	sd	s2,0(sp)
    80004f5a:	1000                	addi	s0,sp,32
    80004f5c:	84aa                	mv	s1,a0
    80004f5e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f60:	00005597          	auipc	a1,0x5
    80004f64:	a5058593          	addi	a1,a1,-1456 # 800099b0 <syscalls+0x298>
    80004f68:	0521                	addi	a0,a0,8
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	bc8080e7          	jalr	-1080(ra) # 80000b32 <initlock>
  lk->name = name;
    80004f72:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f76:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f7a:	0204a423          	sw	zero,40(s1)
}
    80004f7e:	60e2                	ld	ra,24(sp)
    80004f80:	6442                	ld	s0,16(sp)
    80004f82:	64a2                	ld	s1,8(sp)
    80004f84:	6902                	ld	s2,0(sp)
    80004f86:	6105                	addi	sp,sp,32
    80004f88:	8082                	ret

0000000080004f8a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f8a:	1101                	addi	sp,sp,-32
    80004f8c:	ec06                	sd	ra,24(sp)
    80004f8e:	e822                	sd	s0,16(sp)
    80004f90:	e426                	sd	s1,8(sp)
    80004f92:	e04a                	sd	s2,0(sp)
    80004f94:	1000                	addi	s0,sp,32
    80004f96:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f98:	00850913          	addi	s2,a0,8
    80004f9c:	854a                	mv	a0,s2
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	c24080e7          	jalr	-988(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004fa6:	409c                	lw	a5,0(s1)
    80004fa8:	cb89                	beqz	a5,80004fba <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004faa:	85ca                	mv	a1,s2
    80004fac:	8526                	mv	a0,s1
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	0bc080e7          	jalr	188(ra) # 8000206a <sleep>
  while (lk->locked) {
    80004fb6:	409c                	lw	a5,0(s1)
    80004fb8:	fbed                	bnez	a5,80004faa <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fba:	4785                	li	a5,1
    80004fbc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	a16080e7          	jalr	-1514(ra) # 800019d4 <myproc>
    80004fc6:	591c                	lw	a5,48(a0)
    80004fc8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fca:	854a                	mv	a0,s2
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	caa080e7          	jalr	-854(ra) # 80000c76 <release>
}
    80004fd4:	60e2                	ld	ra,24(sp)
    80004fd6:	6442                	ld	s0,16(sp)
    80004fd8:	64a2                	ld	s1,8(sp)
    80004fda:	6902                	ld	s2,0(sp)
    80004fdc:	6105                	addi	sp,sp,32
    80004fde:	8082                	ret

0000000080004fe0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004fe0:	1101                	addi	sp,sp,-32
    80004fe2:	ec06                	sd	ra,24(sp)
    80004fe4:	e822                	sd	s0,16(sp)
    80004fe6:	e426                	sd	s1,8(sp)
    80004fe8:	e04a                	sd	s2,0(sp)
    80004fea:	1000                	addi	s0,sp,32
    80004fec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fee:	00850913          	addi	s2,a0,8
    80004ff2:	854a                	mv	a0,s2
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	bce080e7          	jalr	-1074(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004ffc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005000:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005004:	8526                	mv	a0,s1
    80005006:	ffffd097          	auipc	ra,0xffffd
    8000500a:	0c8080e7          	jalr	200(ra) # 800020ce <wakeup>
  release(&lk->lk);
    8000500e:	854a                	mv	a0,s2
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	c66080e7          	jalr	-922(ra) # 80000c76 <release>
}
    80005018:	60e2                	ld	ra,24(sp)
    8000501a:	6442                	ld	s0,16(sp)
    8000501c:	64a2                	ld	s1,8(sp)
    8000501e:	6902                	ld	s2,0(sp)
    80005020:	6105                	addi	sp,sp,32
    80005022:	8082                	ret

0000000080005024 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005024:	7179                	addi	sp,sp,-48
    80005026:	f406                	sd	ra,40(sp)
    80005028:	f022                	sd	s0,32(sp)
    8000502a:	ec26                	sd	s1,24(sp)
    8000502c:	e84a                	sd	s2,16(sp)
    8000502e:	e44e                	sd	s3,8(sp)
    80005030:	1800                	addi	s0,sp,48
    80005032:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005034:	00850913          	addi	s2,a0,8
    80005038:	854a                	mv	a0,s2
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	b88080e7          	jalr	-1144(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005042:	409c                	lw	a5,0(s1)
    80005044:	ef99                	bnez	a5,80005062 <holdingsleep+0x3e>
    80005046:	4481                	li	s1,0
  release(&lk->lk);
    80005048:	854a                	mv	a0,s2
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	c2c080e7          	jalr	-980(ra) # 80000c76 <release>
  return r;
}
    80005052:	8526                	mv	a0,s1
    80005054:	70a2                	ld	ra,40(sp)
    80005056:	7402                	ld	s0,32(sp)
    80005058:	64e2                	ld	s1,24(sp)
    8000505a:	6942                	ld	s2,16(sp)
    8000505c:	69a2                	ld	s3,8(sp)
    8000505e:	6145                	addi	sp,sp,48
    80005060:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005062:	0284a983          	lw	s3,40(s1)
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	96e080e7          	jalr	-1682(ra) # 800019d4 <myproc>
    8000506e:	5904                	lw	s1,48(a0)
    80005070:	413484b3          	sub	s1,s1,s3
    80005074:	0014b493          	seqz	s1,s1
    80005078:	bfc1                	j	80005048 <holdingsleep+0x24>

000000008000507a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000507a:	1141                	addi	sp,sp,-16
    8000507c:	e406                	sd	ra,8(sp)
    8000507e:	e022                	sd	s0,0(sp)
    80005080:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005082:	00005597          	auipc	a1,0x5
    80005086:	93e58593          	addi	a1,a1,-1730 # 800099c0 <syscalls+0x2a8>
    8000508a:	00025517          	auipc	a0,0x25
    8000508e:	72e50513          	addi	a0,a0,1838 # 8002a7b8 <ftable>
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	aa0080e7          	jalr	-1376(ra) # 80000b32 <initlock>
}
    8000509a:	60a2                	ld	ra,8(sp)
    8000509c:	6402                	ld	s0,0(sp)
    8000509e:	0141                	addi	sp,sp,16
    800050a0:	8082                	ret

00000000800050a2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800050a2:	1101                	addi	sp,sp,-32
    800050a4:	ec06                	sd	ra,24(sp)
    800050a6:	e822                	sd	s0,16(sp)
    800050a8:	e426                	sd	s1,8(sp)
    800050aa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800050ac:	00025517          	auipc	a0,0x25
    800050b0:	70c50513          	addi	a0,a0,1804 # 8002a7b8 <ftable>
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	b0e080e7          	jalr	-1266(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050bc:	00025497          	auipc	s1,0x25
    800050c0:	71448493          	addi	s1,s1,1812 # 8002a7d0 <ftable+0x18>
    800050c4:	00026717          	auipc	a4,0x26
    800050c8:	6ac70713          	addi	a4,a4,1708 # 8002b770 <ftable+0xfb8>
    if(f->ref == 0){
    800050cc:	40dc                	lw	a5,4(s1)
    800050ce:	cf99                	beqz	a5,800050ec <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050d0:	02848493          	addi	s1,s1,40
    800050d4:	fee49ce3          	bne	s1,a4,800050cc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050d8:	00025517          	auipc	a0,0x25
    800050dc:	6e050513          	addi	a0,a0,1760 # 8002a7b8 <ftable>
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	b96080e7          	jalr	-1130(ra) # 80000c76 <release>
  return 0;
    800050e8:	4481                	li	s1,0
    800050ea:	a819                	j	80005100 <filealloc+0x5e>
      f->ref = 1;
    800050ec:	4785                	li	a5,1
    800050ee:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050f0:	00025517          	auipc	a0,0x25
    800050f4:	6c850513          	addi	a0,a0,1736 # 8002a7b8 <ftable>
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	b7e080e7          	jalr	-1154(ra) # 80000c76 <release>
}
    80005100:	8526                	mv	a0,s1
    80005102:	60e2                	ld	ra,24(sp)
    80005104:	6442                	ld	s0,16(sp)
    80005106:	64a2                	ld	s1,8(sp)
    80005108:	6105                	addi	sp,sp,32
    8000510a:	8082                	ret

000000008000510c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000510c:	1101                	addi	sp,sp,-32
    8000510e:	ec06                	sd	ra,24(sp)
    80005110:	e822                	sd	s0,16(sp)
    80005112:	e426                	sd	s1,8(sp)
    80005114:	1000                	addi	s0,sp,32
    80005116:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005118:	00025517          	auipc	a0,0x25
    8000511c:	6a050513          	addi	a0,a0,1696 # 8002a7b8 <ftable>
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	aa2080e7          	jalr	-1374(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005128:	40dc                	lw	a5,4(s1)
    8000512a:	02f05263          	blez	a5,8000514e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000512e:	2785                	addiw	a5,a5,1
    80005130:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005132:	00025517          	auipc	a0,0x25
    80005136:	68650513          	addi	a0,a0,1670 # 8002a7b8 <ftable>
    8000513a:	ffffc097          	auipc	ra,0xffffc
    8000513e:	b3c080e7          	jalr	-1220(ra) # 80000c76 <release>
  return f;
}
    80005142:	8526                	mv	a0,s1
    80005144:	60e2                	ld	ra,24(sp)
    80005146:	6442                	ld	s0,16(sp)
    80005148:	64a2                	ld	s1,8(sp)
    8000514a:	6105                	addi	sp,sp,32
    8000514c:	8082                	ret
    panic("filedup");
    8000514e:	00005517          	auipc	a0,0x5
    80005152:	87a50513          	addi	a0,a0,-1926 # 800099c8 <syscalls+0x2b0>
    80005156:	ffffb097          	auipc	ra,0xffffb
    8000515a:	3d4080e7          	jalr	980(ra) # 8000052a <panic>

000000008000515e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000515e:	7139                	addi	sp,sp,-64
    80005160:	fc06                	sd	ra,56(sp)
    80005162:	f822                	sd	s0,48(sp)
    80005164:	f426                	sd	s1,40(sp)
    80005166:	f04a                	sd	s2,32(sp)
    80005168:	ec4e                	sd	s3,24(sp)
    8000516a:	e852                	sd	s4,16(sp)
    8000516c:	e456                	sd	s5,8(sp)
    8000516e:	0080                	addi	s0,sp,64
    80005170:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005172:	00025517          	auipc	a0,0x25
    80005176:	64650513          	addi	a0,a0,1606 # 8002a7b8 <ftable>
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	a48080e7          	jalr	-1464(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005182:	40dc                	lw	a5,4(s1)
    80005184:	06f05163          	blez	a5,800051e6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005188:	37fd                	addiw	a5,a5,-1
    8000518a:	0007871b          	sext.w	a4,a5
    8000518e:	c0dc                	sw	a5,4(s1)
    80005190:	06e04363          	bgtz	a4,800051f6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005194:	0004a903          	lw	s2,0(s1)
    80005198:	0094ca83          	lbu	s5,9(s1)
    8000519c:	0104ba03          	ld	s4,16(s1)
    800051a0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800051a4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800051a8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800051ac:	00025517          	auipc	a0,0x25
    800051b0:	60c50513          	addi	a0,a0,1548 # 8002a7b8 <ftable>
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	ac2080e7          	jalr	-1342(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800051bc:	4785                	li	a5,1
    800051be:	04f90d63          	beq	s2,a5,80005218 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051c2:	3979                	addiw	s2,s2,-2
    800051c4:	4785                	li	a5,1
    800051c6:	0527e063          	bltu	a5,s2,80005206 <fileclose+0xa8>
    begin_op();
    800051ca:	00000097          	auipc	ra,0x0
    800051ce:	ac8080e7          	jalr	-1336(ra) # 80004c92 <begin_op>
    iput(ff.ip);
    800051d2:	854e                	mv	a0,s3
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	f90080e7          	jalr	-112(ra) # 80004164 <iput>
    end_op();
    800051dc:	00000097          	auipc	ra,0x0
    800051e0:	b36080e7          	jalr	-1226(ra) # 80004d12 <end_op>
    800051e4:	a00d                	j	80005206 <fileclose+0xa8>
    panic("fileclose");
    800051e6:	00004517          	auipc	a0,0x4
    800051ea:	7ea50513          	addi	a0,a0,2026 # 800099d0 <syscalls+0x2b8>
    800051ee:	ffffb097          	auipc	ra,0xffffb
    800051f2:	33c080e7          	jalr	828(ra) # 8000052a <panic>
    release(&ftable.lock);
    800051f6:	00025517          	auipc	a0,0x25
    800051fa:	5c250513          	addi	a0,a0,1474 # 8002a7b8 <ftable>
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	a78080e7          	jalr	-1416(ra) # 80000c76 <release>
  }
}
    80005206:	70e2                	ld	ra,56(sp)
    80005208:	7442                	ld	s0,48(sp)
    8000520a:	74a2                	ld	s1,40(sp)
    8000520c:	7902                	ld	s2,32(sp)
    8000520e:	69e2                	ld	s3,24(sp)
    80005210:	6a42                	ld	s4,16(sp)
    80005212:	6aa2                	ld	s5,8(sp)
    80005214:	6121                	addi	sp,sp,64
    80005216:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005218:	85d6                	mv	a1,s5
    8000521a:	8552                	mv	a0,s4
    8000521c:	00000097          	auipc	ra,0x0
    80005220:	542080e7          	jalr	1346(ra) # 8000575e <pipeclose>
    80005224:	b7cd                	j	80005206 <fileclose+0xa8>

0000000080005226 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005226:	715d                	addi	sp,sp,-80
    80005228:	e486                	sd	ra,72(sp)
    8000522a:	e0a2                	sd	s0,64(sp)
    8000522c:	fc26                	sd	s1,56(sp)
    8000522e:	f84a                	sd	s2,48(sp)
    80005230:	f44e                	sd	s3,40(sp)
    80005232:	0880                	addi	s0,sp,80
    80005234:	84aa                	mv	s1,a0
    80005236:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	79c080e7          	jalr	1948(ra) # 800019d4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005240:	409c                	lw	a5,0(s1)
    80005242:	37f9                	addiw	a5,a5,-2
    80005244:	4705                	li	a4,1
    80005246:	04f76763          	bltu	a4,a5,80005294 <filestat+0x6e>
    8000524a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000524c:	6c88                	ld	a0,24(s1)
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	d5c080e7          	jalr	-676(ra) # 80003faa <ilock>
    stati(f->ip, &st);
    80005256:	fb840593          	addi	a1,s0,-72
    8000525a:	6c88                	ld	a0,24(s1)
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	fd8080e7          	jalr	-40(ra) # 80004234 <stati>
    iunlock(f->ip);
    80005264:	6c88                	ld	a0,24(s1)
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	e06080e7          	jalr	-506(ra) # 8000406c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000526e:	46e1                	li	a3,24
    80005270:	fb840613          	addi	a2,s0,-72
    80005274:	85ce                	mv	a1,s3
    80005276:	05093503          	ld	a0,80(s2)
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	41a080e7          	jalr	1050(ra) # 80001694 <copyout>
    80005282:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005286:	60a6                	ld	ra,72(sp)
    80005288:	6406                	ld	s0,64(sp)
    8000528a:	74e2                	ld	s1,56(sp)
    8000528c:	7942                	ld	s2,48(sp)
    8000528e:	79a2                	ld	s3,40(sp)
    80005290:	6161                	addi	sp,sp,80
    80005292:	8082                	ret
  return -1;
    80005294:	557d                	li	a0,-1
    80005296:	bfc5                	j	80005286 <filestat+0x60>

0000000080005298 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005298:	7179                	addi	sp,sp,-48
    8000529a:	f406                	sd	ra,40(sp)
    8000529c:	f022                	sd	s0,32(sp)
    8000529e:	ec26                	sd	s1,24(sp)
    800052a0:	e84a                	sd	s2,16(sp)
    800052a2:	e44e                	sd	s3,8(sp)
    800052a4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800052a6:	00854783          	lbu	a5,8(a0)
    800052aa:	c3d5                	beqz	a5,8000534e <fileread+0xb6>
    800052ac:	84aa                	mv	s1,a0
    800052ae:	89ae                	mv	s3,a1
    800052b0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052b2:	411c                	lw	a5,0(a0)
    800052b4:	4705                	li	a4,1
    800052b6:	04e78963          	beq	a5,a4,80005308 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052ba:	470d                	li	a4,3
    800052bc:	04e78d63          	beq	a5,a4,80005316 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052c0:	4709                	li	a4,2
    800052c2:	06e79e63          	bne	a5,a4,8000533e <fileread+0xa6>
    ilock(f->ip);
    800052c6:	6d08                	ld	a0,24(a0)
    800052c8:	fffff097          	auipc	ra,0xfffff
    800052cc:	ce2080e7          	jalr	-798(ra) # 80003faa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052d0:	874a                	mv	a4,s2
    800052d2:	5094                	lw	a3,32(s1)
    800052d4:	864e                	mv	a2,s3
    800052d6:	4585                	li	a1,1
    800052d8:	6c88                	ld	a0,24(s1)
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	f84080e7          	jalr	-124(ra) # 8000425e <readi>
    800052e2:	892a                	mv	s2,a0
    800052e4:	00a05563          	blez	a0,800052ee <fileread+0x56>
      f->off += r;
    800052e8:	509c                	lw	a5,32(s1)
    800052ea:	9fa9                	addw	a5,a5,a0
    800052ec:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052ee:	6c88                	ld	a0,24(s1)
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	d7c080e7          	jalr	-644(ra) # 8000406c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052f8:	854a                	mv	a0,s2
    800052fa:	70a2                	ld	ra,40(sp)
    800052fc:	7402                	ld	s0,32(sp)
    800052fe:	64e2                	ld	s1,24(sp)
    80005300:	6942                	ld	s2,16(sp)
    80005302:	69a2                	ld	s3,8(sp)
    80005304:	6145                	addi	sp,sp,48
    80005306:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005308:	6908                	ld	a0,16(a0)
    8000530a:	00000097          	auipc	ra,0x0
    8000530e:	5b6080e7          	jalr	1462(ra) # 800058c0 <piperead>
    80005312:	892a                	mv	s2,a0
    80005314:	b7d5                	j	800052f8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005316:	02451783          	lh	a5,36(a0)
    8000531a:	03079693          	slli	a3,a5,0x30
    8000531e:	92c1                	srli	a3,a3,0x30
    80005320:	4725                	li	a4,9
    80005322:	02d76863          	bltu	a4,a3,80005352 <fileread+0xba>
    80005326:	0792                	slli	a5,a5,0x4
    80005328:	00025717          	auipc	a4,0x25
    8000532c:	3f070713          	addi	a4,a4,1008 # 8002a718 <devsw>
    80005330:	97ba                	add	a5,a5,a4
    80005332:	639c                	ld	a5,0(a5)
    80005334:	c38d                	beqz	a5,80005356 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005336:	4505                	li	a0,1
    80005338:	9782                	jalr	a5
    8000533a:	892a                	mv	s2,a0
    8000533c:	bf75                	j	800052f8 <fileread+0x60>
    panic("fileread");
    8000533e:	00004517          	auipc	a0,0x4
    80005342:	6a250513          	addi	a0,a0,1698 # 800099e0 <syscalls+0x2c8>
    80005346:	ffffb097          	auipc	ra,0xffffb
    8000534a:	1e4080e7          	jalr	484(ra) # 8000052a <panic>
    return -1;
    8000534e:	597d                	li	s2,-1
    80005350:	b765                	j	800052f8 <fileread+0x60>
      return -1;
    80005352:	597d                	li	s2,-1
    80005354:	b755                	j	800052f8 <fileread+0x60>
    80005356:	597d                	li	s2,-1
    80005358:	b745                	j	800052f8 <fileread+0x60>

000000008000535a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000535a:	715d                	addi	sp,sp,-80
    8000535c:	e486                	sd	ra,72(sp)
    8000535e:	e0a2                	sd	s0,64(sp)
    80005360:	fc26                	sd	s1,56(sp)
    80005362:	f84a                	sd	s2,48(sp)
    80005364:	f44e                	sd	s3,40(sp)
    80005366:	f052                	sd	s4,32(sp)
    80005368:	ec56                	sd	s5,24(sp)
    8000536a:	e85a                	sd	s6,16(sp)
    8000536c:	e45e                	sd	s7,8(sp)
    8000536e:	e062                	sd	s8,0(sp)
    80005370:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005372:	00954783          	lbu	a5,9(a0)
    80005376:	10078663          	beqz	a5,80005482 <filewrite+0x128>
    8000537a:	892a                	mv	s2,a0
    8000537c:	8aae                	mv	s5,a1
    8000537e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005380:	411c                	lw	a5,0(a0)
    80005382:	4705                	li	a4,1
    80005384:	02e78263          	beq	a5,a4,800053a8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005388:	470d                	li	a4,3
    8000538a:	02e78663          	beq	a5,a4,800053b6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000538e:	4709                	li	a4,2
    80005390:	0ee79163          	bne	a5,a4,80005472 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005394:	0ac05d63          	blez	a2,8000544e <filewrite+0xf4>
    int i = 0;
    80005398:	4981                	li	s3,0
    8000539a:	6b05                	lui	s6,0x1
    8000539c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800053a0:	6b85                	lui	s7,0x1
    800053a2:	c00b8b9b          	addiw	s7,s7,-1024
    800053a6:	a861                	j	8000543e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800053a8:	6908                	ld	a0,16(a0)
    800053aa:	00000097          	auipc	ra,0x0
    800053ae:	424080e7          	jalr	1060(ra) # 800057ce <pipewrite>
    800053b2:	8a2a                	mv	s4,a0
    800053b4:	a045                	j	80005454 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053b6:	02451783          	lh	a5,36(a0)
    800053ba:	03079693          	slli	a3,a5,0x30
    800053be:	92c1                	srli	a3,a3,0x30
    800053c0:	4725                	li	a4,9
    800053c2:	0cd76263          	bltu	a4,a3,80005486 <filewrite+0x12c>
    800053c6:	0792                	slli	a5,a5,0x4
    800053c8:	00025717          	auipc	a4,0x25
    800053cc:	35070713          	addi	a4,a4,848 # 8002a718 <devsw>
    800053d0:	97ba                	add	a5,a5,a4
    800053d2:	679c                	ld	a5,8(a5)
    800053d4:	cbdd                	beqz	a5,8000548a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053d6:	4505                	li	a0,1
    800053d8:	9782                	jalr	a5
    800053da:	8a2a                	mv	s4,a0
    800053dc:	a8a5                	j	80005454 <filewrite+0xfa>
    800053de:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	8b0080e7          	jalr	-1872(ra) # 80004c92 <begin_op>
      ilock(f->ip);
    800053ea:	01893503          	ld	a0,24(s2)
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	bbc080e7          	jalr	-1092(ra) # 80003faa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053f6:	8762                	mv	a4,s8
    800053f8:	02092683          	lw	a3,32(s2)
    800053fc:	01598633          	add	a2,s3,s5
    80005400:	4585                	li	a1,1
    80005402:	01893503          	ld	a0,24(s2)
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	f50080e7          	jalr	-176(ra) # 80004356 <writei>
    8000540e:	84aa                	mv	s1,a0
    80005410:	00a05763          	blez	a0,8000541e <filewrite+0xc4>
        f->off += r;
    80005414:	02092783          	lw	a5,32(s2)
    80005418:	9fa9                	addw	a5,a5,a0
    8000541a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000541e:	01893503          	ld	a0,24(s2)
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	c4a080e7          	jalr	-950(ra) # 8000406c <iunlock>
      end_op();
    8000542a:	00000097          	auipc	ra,0x0
    8000542e:	8e8080e7          	jalr	-1816(ra) # 80004d12 <end_op>

      if(r != n1){
    80005432:	009c1f63          	bne	s8,s1,80005450 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005436:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000543a:	0149db63          	bge	s3,s4,80005450 <filewrite+0xf6>
      int n1 = n - i;
    8000543e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005442:	84be                	mv	s1,a5
    80005444:	2781                	sext.w	a5,a5
    80005446:	f8fb5ce3          	bge	s6,a5,800053de <filewrite+0x84>
    8000544a:	84de                	mv	s1,s7
    8000544c:	bf49                	j	800053de <filewrite+0x84>
    int i = 0;
    8000544e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005450:	013a1f63          	bne	s4,s3,8000546e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005454:	8552                	mv	a0,s4
    80005456:	60a6                	ld	ra,72(sp)
    80005458:	6406                	ld	s0,64(sp)
    8000545a:	74e2                	ld	s1,56(sp)
    8000545c:	7942                	ld	s2,48(sp)
    8000545e:	79a2                	ld	s3,40(sp)
    80005460:	7a02                	ld	s4,32(sp)
    80005462:	6ae2                	ld	s5,24(sp)
    80005464:	6b42                	ld	s6,16(sp)
    80005466:	6ba2                	ld	s7,8(sp)
    80005468:	6c02                	ld	s8,0(sp)
    8000546a:	6161                	addi	sp,sp,80
    8000546c:	8082                	ret
    ret = (i == n ? n : -1);
    8000546e:	5a7d                	li	s4,-1
    80005470:	b7d5                	j	80005454 <filewrite+0xfa>
    panic("filewrite");
    80005472:	00004517          	auipc	a0,0x4
    80005476:	57e50513          	addi	a0,a0,1406 # 800099f0 <syscalls+0x2d8>
    8000547a:	ffffb097          	auipc	ra,0xffffb
    8000547e:	0b0080e7          	jalr	176(ra) # 8000052a <panic>
    return -1;
    80005482:	5a7d                	li	s4,-1
    80005484:	bfc1                	j	80005454 <filewrite+0xfa>
      return -1;
    80005486:	5a7d                	li	s4,-1
    80005488:	b7f1                	j	80005454 <filewrite+0xfa>
    8000548a:	5a7d                	li	s4,-1
    8000548c:	b7e1                	j	80005454 <filewrite+0xfa>

000000008000548e <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    8000548e:	7179                	addi	sp,sp,-48
    80005490:	f406                	sd	ra,40(sp)
    80005492:	f022                	sd	s0,32(sp)
    80005494:	ec26                	sd	s1,24(sp)
    80005496:	e84a                	sd	s2,16(sp)
    80005498:	e44e                	sd	s3,8(sp)
    8000549a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000549c:	00854783          	lbu	a5,8(a0)
    800054a0:	c3d5                	beqz	a5,80005544 <kfileread+0xb6>
    800054a2:	84aa                	mv	s1,a0
    800054a4:	89ae                	mv	s3,a1
    800054a6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800054a8:	411c                	lw	a5,0(a0)
    800054aa:	4705                	li	a4,1
    800054ac:	04e78963          	beq	a5,a4,800054fe <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054b0:	470d                	li	a4,3
    800054b2:	04e78d63          	beq	a5,a4,8000550c <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800054b6:	4709                	li	a4,2
    800054b8:	06e79e63          	bne	a5,a4,80005534 <kfileread+0xa6>
    ilock(f->ip);
    800054bc:	6d08                	ld	a0,24(a0)
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	aec080e7          	jalr	-1300(ra) # 80003faa <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800054c6:	874a                	mv	a4,s2
    800054c8:	5094                	lw	a3,32(s1)
    800054ca:	864e                	mv	a2,s3
    800054cc:	4581                	li	a1,0
    800054ce:	6c88                	ld	a0,24(s1)
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	d8e080e7          	jalr	-626(ra) # 8000425e <readi>
    800054d8:	892a                	mv	s2,a0
    800054da:	00a05563          	blez	a0,800054e4 <kfileread+0x56>
      f->off += r;
    800054de:	509c                	lw	a5,32(s1)
    800054e0:	9fa9                	addw	a5,a5,a0
    800054e2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800054e4:	6c88                	ld	a0,24(s1)
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	b86080e7          	jalr	-1146(ra) # 8000406c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800054ee:	854a                	mv	a0,s2
    800054f0:	70a2                	ld	ra,40(sp)
    800054f2:	7402                	ld	s0,32(sp)
    800054f4:	64e2                	ld	s1,24(sp)
    800054f6:	6942                	ld	s2,16(sp)
    800054f8:	69a2                	ld	s3,8(sp)
    800054fa:	6145                	addi	sp,sp,48
    800054fc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800054fe:	6908                	ld	a0,16(a0)
    80005500:	00000097          	auipc	ra,0x0
    80005504:	3c0080e7          	jalr	960(ra) # 800058c0 <piperead>
    80005508:	892a                	mv	s2,a0
    8000550a:	b7d5                	j	800054ee <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000550c:	02451783          	lh	a5,36(a0)
    80005510:	03079693          	slli	a3,a5,0x30
    80005514:	92c1                	srli	a3,a3,0x30
    80005516:	4725                	li	a4,9
    80005518:	02d76863          	bltu	a4,a3,80005548 <kfileread+0xba>
    8000551c:	0792                	slli	a5,a5,0x4
    8000551e:	00025717          	auipc	a4,0x25
    80005522:	1fa70713          	addi	a4,a4,506 # 8002a718 <devsw>
    80005526:	97ba                	add	a5,a5,a4
    80005528:	639c                	ld	a5,0(a5)
    8000552a:	c38d                	beqz	a5,8000554c <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000552c:	4505                	li	a0,1
    8000552e:	9782                	jalr	a5
    80005530:	892a                	mv	s2,a0
    80005532:	bf75                	j	800054ee <kfileread+0x60>
    panic("fileread");
    80005534:	00004517          	auipc	a0,0x4
    80005538:	4ac50513          	addi	a0,a0,1196 # 800099e0 <syscalls+0x2c8>
    8000553c:	ffffb097          	auipc	ra,0xffffb
    80005540:	fee080e7          	jalr	-18(ra) # 8000052a <panic>
    return -1;
    80005544:	597d                	li	s2,-1
    80005546:	b765                	j	800054ee <kfileread+0x60>
      return -1;
    80005548:	597d                	li	s2,-1
    8000554a:	b755                	j	800054ee <kfileread+0x60>
    8000554c:	597d                	li	s2,-1
    8000554e:	b745                	j	800054ee <kfileread+0x60>

0000000080005550 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005550:	715d                	addi	sp,sp,-80
    80005552:	e486                	sd	ra,72(sp)
    80005554:	e0a2                	sd	s0,64(sp)
    80005556:	fc26                	sd	s1,56(sp)
    80005558:	f84a                	sd	s2,48(sp)
    8000555a:	f44e                	sd	s3,40(sp)
    8000555c:	f052                	sd	s4,32(sp)
    8000555e:	ec56                	sd	s5,24(sp)
    80005560:	e85a                	sd	s6,16(sp)
    80005562:	e45e                	sd	s7,8(sp)
    80005564:	e062                	sd	s8,0(sp)
    80005566:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005568:	00954783          	lbu	a5,9(a0)
    8000556c:	10078663          	beqz	a5,80005678 <kfilewrite+0x128>
    80005570:	892a                	mv	s2,a0
    80005572:	8aae                	mv	s5,a1
    80005574:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005576:	411c                	lw	a5,0(a0)
    80005578:	4705                	li	a4,1
    8000557a:	02e78263          	beq	a5,a4,8000559e <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000557e:	470d                	li	a4,3
    80005580:	02e78663          	beq	a5,a4,800055ac <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005584:	4709                	li	a4,2
    80005586:	0ee79163          	bne	a5,a4,80005668 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000558a:	0ac05d63          	blez	a2,80005644 <kfilewrite+0xf4>
    int i = 0;
    8000558e:	4981                	li	s3,0
    80005590:	6b05                	lui	s6,0x1
    80005592:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005596:	6b85                	lui	s7,0x1
    80005598:	c00b8b9b          	addiw	s7,s7,-1024
    8000559c:	a861                	j	80005634 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000559e:	6908                	ld	a0,16(a0)
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	22e080e7          	jalr	558(ra) # 800057ce <pipewrite>
    800055a8:	8a2a                	mv	s4,a0
    800055aa:	a045                	j	8000564a <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800055ac:	02451783          	lh	a5,36(a0)
    800055b0:	03079693          	slli	a3,a5,0x30
    800055b4:	92c1                	srli	a3,a3,0x30
    800055b6:	4725                	li	a4,9
    800055b8:	0cd76263          	bltu	a4,a3,8000567c <kfilewrite+0x12c>
    800055bc:	0792                	slli	a5,a5,0x4
    800055be:	00025717          	auipc	a4,0x25
    800055c2:	15a70713          	addi	a4,a4,346 # 8002a718 <devsw>
    800055c6:	97ba                	add	a5,a5,a4
    800055c8:	679c                	ld	a5,8(a5)
    800055ca:	cbdd                	beqz	a5,80005680 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800055cc:	4505                	li	a0,1
    800055ce:	9782                	jalr	a5
    800055d0:	8a2a                	mv	s4,a0
    800055d2:	a8a5                	j	8000564a <kfilewrite+0xfa>
    800055d4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	6ba080e7          	jalr	1722(ra) # 80004c92 <begin_op>
      ilock(f->ip);
    800055e0:	01893503          	ld	a0,24(s2)
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	9c6080e7          	jalr	-1594(ra) # 80003faa <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800055ec:	8762                	mv	a4,s8
    800055ee:	02092683          	lw	a3,32(s2)
    800055f2:	01598633          	add	a2,s3,s5
    800055f6:	4581                	li	a1,0
    800055f8:	01893503          	ld	a0,24(s2)
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	d5a080e7          	jalr	-678(ra) # 80004356 <writei>
    80005604:	84aa                	mv	s1,a0
    80005606:	00a05763          	blez	a0,80005614 <kfilewrite+0xc4>
        f->off += r;
    8000560a:	02092783          	lw	a5,32(s2)
    8000560e:	9fa9                	addw	a5,a5,a0
    80005610:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005614:	01893503          	ld	a0,24(s2)
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	a54080e7          	jalr	-1452(ra) # 8000406c <iunlock>
      end_op();
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	6f2080e7          	jalr	1778(ra) # 80004d12 <end_op>

      if(r != n1){
    80005628:	009c1f63          	bne	s8,s1,80005646 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000562c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005630:	0149db63          	bge	s3,s4,80005646 <kfilewrite+0xf6>
      int n1 = n - i;
    80005634:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005638:	84be                	mv	s1,a5
    8000563a:	2781                	sext.w	a5,a5
    8000563c:	f8fb5ce3          	bge	s6,a5,800055d4 <kfilewrite+0x84>
    80005640:	84de                	mv	s1,s7
    80005642:	bf49                	j	800055d4 <kfilewrite+0x84>
    int i = 0;
    80005644:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005646:	013a1f63          	bne	s4,s3,80005664 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    8000564a:	8552                	mv	a0,s4
    8000564c:	60a6                	ld	ra,72(sp)
    8000564e:	6406                	ld	s0,64(sp)
    80005650:	74e2                	ld	s1,56(sp)
    80005652:	7942                	ld	s2,48(sp)
    80005654:	79a2                	ld	s3,40(sp)
    80005656:	7a02                	ld	s4,32(sp)
    80005658:	6ae2                	ld	s5,24(sp)
    8000565a:	6b42                	ld	s6,16(sp)
    8000565c:	6ba2                	ld	s7,8(sp)
    8000565e:	6c02                	ld	s8,0(sp)
    80005660:	6161                	addi	sp,sp,80
    80005662:	8082                	ret
    ret = (i == n ? n : -1);
    80005664:	5a7d                	li	s4,-1
    80005666:	b7d5                	j	8000564a <kfilewrite+0xfa>
    panic("filewrite");
    80005668:	00004517          	auipc	a0,0x4
    8000566c:	38850513          	addi	a0,a0,904 # 800099f0 <syscalls+0x2d8>
    80005670:	ffffb097          	auipc	ra,0xffffb
    80005674:	eba080e7          	jalr	-326(ra) # 8000052a <panic>
    return -1;
    80005678:	5a7d                	li	s4,-1
    8000567a:	bfc1                	j	8000564a <kfilewrite+0xfa>
      return -1;
    8000567c:	5a7d                	li	s4,-1
    8000567e:	b7f1                	j	8000564a <kfilewrite+0xfa>
    80005680:	5a7d                	li	s4,-1
    80005682:	b7e1                	j	8000564a <kfilewrite+0xfa>

0000000080005684 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005684:	7179                	addi	sp,sp,-48
    80005686:	f406                	sd	ra,40(sp)
    80005688:	f022                	sd	s0,32(sp)
    8000568a:	ec26                	sd	s1,24(sp)
    8000568c:	e84a                	sd	s2,16(sp)
    8000568e:	e44e                	sd	s3,8(sp)
    80005690:	e052                	sd	s4,0(sp)
    80005692:	1800                	addi	s0,sp,48
    80005694:	84aa                	mv	s1,a0
    80005696:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005698:	0005b023          	sd	zero,0(a1)
    8000569c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800056a0:	00000097          	auipc	ra,0x0
    800056a4:	a02080e7          	jalr	-1534(ra) # 800050a2 <filealloc>
    800056a8:	e088                	sd	a0,0(s1)
    800056aa:	c551                	beqz	a0,80005736 <pipealloc+0xb2>
    800056ac:	00000097          	auipc	ra,0x0
    800056b0:	9f6080e7          	jalr	-1546(ra) # 800050a2 <filealloc>
    800056b4:	00aa3023          	sd	a0,0(s4)
    800056b8:	c92d                	beqz	a0,8000572a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800056ba:	ffffb097          	auipc	ra,0xffffb
    800056be:	418080e7          	jalr	1048(ra) # 80000ad2 <kalloc>
    800056c2:	892a                	mv	s2,a0
    800056c4:	c125                	beqz	a0,80005724 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800056c6:	4985                	li	s3,1
    800056c8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800056cc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800056d0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800056d4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800056d8:	00004597          	auipc	a1,0x4
    800056dc:	32858593          	addi	a1,a1,808 # 80009a00 <syscalls+0x2e8>
    800056e0:	ffffb097          	auipc	ra,0xffffb
    800056e4:	452080e7          	jalr	1106(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800056e8:	609c                	ld	a5,0(s1)
    800056ea:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800056ee:	609c                	ld	a5,0(s1)
    800056f0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800056f4:	609c                	ld	a5,0(s1)
    800056f6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800056fa:	609c                	ld	a5,0(s1)
    800056fc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005700:	000a3783          	ld	a5,0(s4)
    80005704:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005708:	000a3783          	ld	a5,0(s4)
    8000570c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005710:	000a3783          	ld	a5,0(s4)
    80005714:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005718:	000a3783          	ld	a5,0(s4)
    8000571c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005720:	4501                	li	a0,0
    80005722:	a025                	j	8000574a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005724:	6088                	ld	a0,0(s1)
    80005726:	e501                	bnez	a0,8000572e <pipealloc+0xaa>
    80005728:	a039                	j	80005736 <pipealloc+0xb2>
    8000572a:	6088                	ld	a0,0(s1)
    8000572c:	c51d                	beqz	a0,8000575a <pipealloc+0xd6>
    fileclose(*f0);
    8000572e:	00000097          	auipc	ra,0x0
    80005732:	a30080e7          	jalr	-1488(ra) # 8000515e <fileclose>
  if(*f1)
    80005736:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000573a:	557d                	li	a0,-1
  if(*f1)
    8000573c:	c799                	beqz	a5,8000574a <pipealloc+0xc6>
    fileclose(*f1);
    8000573e:	853e                	mv	a0,a5
    80005740:	00000097          	auipc	ra,0x0
    80005744:	a1e080e7          	jalr	-1506(ra) # 8000515e <fileclose>
  return -1;
    80005748:	557d                	li	a0,-1
}
    8000574a:	70a2                	ld	ra,40(sp)
    8000574c:	7402                	ld	s0,32(sp)
    8000574e:	64e2                	ld	s1,24(sp)
    80005750:	6942                	ld	s2,16(sp)
    80005752:	69a2                	ld	s3,8(sp)
    80005754:	6a02                	ld	s4,0(sp)
    80005756:	6145                	addi	sp,sp,48
    80005758:	8082                	ret
  return -1;
    8000575a:	557d                	li	a0,-1
    8000575c:	b7fd                	j	8000574a <pipealloc+0xc6>

000000008000575e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000575e:	1101                	addi	sp,sp,-32
    80005760:	ec06                	sd	ra,24(sp)
    80005762:	e822                	sd	s0,16(sp)
    80005764:	e426                	sd	s1,8(sp)
    80005766:	e04a                	sd	s2,0(sp)
    80005768:	1000                	addi	s0,sp,32
    8000576a:	84aa                	mv	s1,a0
    8000576c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000576e:	ffffb097          	auipc	ra,0xffffb
    80005772:	454080e7          	jalr	1108(ra) # 80000bc2 <acquire>
  if(writable){
    80005776:	02090d63          	beqz	s2,800057b0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000577a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000577e:	21848513          	addi	a0,s1,536
    80005782:	ffffd097          	auipc	ra,0xffffd
    80005786:	94c080e7          	jalr	-1716(ra) # 800020ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000578a:	2204b783          	ld	a5,544(s1)
    8000578e:	eb95                	bnez	a5,800057c2 <pipeclose+0x64>
    release(&pi->lock);
    80005790:	8526                	mv	a0,s1
    80005792:	ffffb097          	auipc	ra,0xffffb
    80005796:	4e4080e7          	jalr	1252(ra) # 80000c76 <release>
    kfree((char*)pi);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffb097          	auipc	ra,0xffffb
    800057a0:	23a080e7          	jalr	570(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800057a4:	60e2                	ld	ra,24(sp)
    800057a6:	6442                	ld	s0,16(sp)
    800057a8:	64a2                	ld	s1,8(sp)
    800057aa:	6902                	ld	s2,0(sp)
    800057ac:	6105                	addi	sp,sp,32
    800057ae:	8082                	ret
    pi->readopen = 0;
    800057b0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800057b4:	21c48513          	addi	a0,s1,540
    800057b8:	ffffd097          	auipc	ra,0xffffd
    800057bc:	916080e7          	jalr	-1770(ra) # 800020ce <wakeup>
    800057c0:	b7e9                	j	8000578a <pipeclose+0x2c>
    release(&pi->lock);
    800057c2:	8526                	mv	a0,s1
    800057c4:	ffffb097          	auipc	ra,0xffffb
    800057c8:	4b2080e7          	jalr	1202(ra) # 80000c76 <release>
}
    800057cc:	bfe1                	j	800057a4 <pipeclose+0x46>

00000000800057ce <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800057ce:	711d                	addi	sp,sp,-96
    800057d0:	ec86                	sd	ra,88(sp)
    800057d2:	e8a2                	sd	s0,80(sp)
    800057d4:	e4a6                	sd	s1,72(sp)
    800057d6:	e0ca                	sd	s2,64(sp)
    800057d8:	fc4e                	sd	s3,56(sp)
    800057da:	f852                	sd	s4,48(sp)
    800057dc:	f456                	sd	s5,40(sp)
    800057de:	f05a                	sd	s6,32(sp)
    800057e0:	ec5e                	sd	s7,24(sp)
    800057e2:	e862                	sd	s8,16(sp)
    800057e4:	1080                	addi	s0,sp,96
    800057e6:	84aa                	mv	s1,a0
    800057e8:	8aae                	mv	s5,a1
    800057ea:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800057ec:	ffffc097          	auipc	ra,0xffffc
    800057f0:	1e8080e7          	jalr	488(ra) # 800019d4 <myproc>
    800057f4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800057f6:	8526                	mv	a0,s1
    800057f8:	ffffb097          	auipc	ra,0xffffb
    800057fc:	3ca080e7          	jalr	970(ra) # 80000bc2 <acquire>
  while(i < n){
    80005800:	0b405363          	blez	s4,800058a6 <pipewrite+0xd8>
  int i = 0;
    80005804:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005806:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005808:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000580c:	21c48b93          	addi	s7,s1,540
    80005810:	a089                	j	80005852 <pipewrite+0x84>
      release(&pi->lock);
    80005812:	8526                	mv	a0,s1
    80005814:	ffffb097          	auipc	ra,0xffffb
    80005818:	462080e7          	jalr	1122(ra) # 80000c76 <release>
      return -1;
    8000581c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000581e:	854a                	mv	a0,s2
    80005820:	60e6                	ld	ra,88(sp)
    80005822:	6446                	ld	s0,80(sp)
    80005824:	64a6                	ld	s1,72(sp)
    80005826:	6906                	ld	s2,64(sp)
    80005828:	79e2                	ld	s3,56(sp)
    8000582a:	7a42                	ld	s4,48(sp)
    8000582c:	7aa2                	ld	s5,40(sp)
    8000582e:	7b02                	ld	s6,32(sp)
    80005830:	6be2                	ld	s7,24(sp)
    80005832:	6c42                	ld	s8,16(sp)
    80005834:	6125                	addi	sp,sp,96
    80005836:	8082                	ret
      wakeup(&pi->nread);
    80005838:	8562                	mv	a0,s8
    8000583a:	ffffd097          	auipc	ra,0xffffd
    8000583e:	894080e7          	jalr	-1900(ra) # 800020ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005842:	85a6                	mv	a1,s1
    80005844:	855e                	mv	a0,s7
    80005846:	ffffd097          	auipc	ra,0xffffd
    8000584a:	824080e7          	jalr	-2012(ra) # 8000206a <sleep>
  while(i < n){
    8000584e:	05495d63          	bge	s2,s4,800058a8 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005852:	2204a783          	lw	a5,544(s1)
    80005856:	dfd5                	beqz	a5,80005812 <pipewrite+0x44>
    80005858:	0289a783          	lw	a5,40(s3)
    8000585c:	fbdd                	bnez	a5,80005812 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000585e:	2184a783          	lw	a5,536(s1)
    80005862:	21c4a703          	lw	a4,540(s1)
    80005866:	2007879b          	addiw	a5,a5,512
    8000586a:	fcf707e3          	beq	a4,a5,80005838 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000586e:	4685                	li	a3,1
    80005870:	01590633          	add	a2,s2,s5
    80005874:	faf40593          	addi	a1,s0,-81
    80005878:	0509b503          	ld	a0,80(s3)
    8000587c:	ffffc097          	auipc	ra,0xffffc
    80005880:	ea4080e7          	jalr	-348(ra) # 80001720 <copyin>
    80005884:	03650263          	beq	a0,s6,800058a8 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005888:	21c4a783          	lw	a5,540(s1)
    8000588c:	0017871b          	addiw	a4,a5,1
    80005890:	20e4ae23          	sw	a4,540(s1)
    80005894:	1ff7f793          	andi	a5,a5,511
    80005898:	97a6                	add	a5,a5,s1
    8000589a:	faf44703          	lbu	a4,-81(s0)
    8000589e:	00e78c23          	sb	a4,24(a5)
      i++;
    800058a2:	2905                	addiw	s2,s2,1
    800058a4:	b76d                	j	8000584e <pipewrite+0x80>
  int i = 0;
    800058a6:	4901                	li	s2,0
  wakeup(&pi->nread);
    800058a8:	21848513          	addi	a0,s1,536
    800058ac:	ffffd097          	auipc	ra,0xffffd
    800058b0:	822080e7          	jalr	-2014(ra) # 800020ce <wakeup>
  release(&pi->lock);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffb097          	auipc	ra,0xffffb
    800058ba:	3c0080e7          	jalr	960(ra) # 80000c76 <release>
  return i;
    800058be:	b785                	j	8000581e <pipewrite+0x50>

00000000800058c0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800058c0:	715d                	addi	sp,sp,-80
    800058c2:	e486                	sd	ra,72(sp)
    800058c4:	e0a2                	sd	s0,64(sp)
    800058c6:	fc26                	sd	s1,56(sp)
    800058c8:	f84a                	sd	s2,48(sp)
    800058ca:	f44e                	sd	s3,40(sp)
    800058cc:	f052                	sd	s4,32(sp)
    800058ce:	ec56                	sd	s5,24(sp)
    800058d0:	e85a                	sd	s6,16(sp)
    800058d2:	0880                	addi	s0,sp,80
    800058d4:	84aa                	mv	s1,a0
    800058d6:	892e                	mv	s2,a1
    800058d8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800058da:	ffffc097          	auipc	ra,0xffffc
    800058de:	0fa080e7          	jalr	250(ra) # 800019d4 <myproc>
    800058e2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800058e4:	8526                	mv	a0,s1
    800058e6:	ffffb097          	auipc	ra,0xffffb
    800058ea:	2dc080e7          	jalr	732(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058ee:	2184a703          	lw	a4,536(s1)
    800058f2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800058f6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058fa:	02f71463          	bne	a4,a5,80005922 <piperead+0x62>
    800058fe:	2244a783          	lw	a5,548(s1)
    80005902:	c385                	beqz	a5,80005922 <piperead+0x62>
    if(pr->killed){
    80005904:	028a2783          	lw	a5,40(s4)
    80005908:	ebc1                	bnez	a5,80005998 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000590a:	85a6                	mv	a1,s1
    8000590c:	854e                	mv	a0,s3
    8000590e:	ffffc097          	auipc	ra,0xffffc
    80005912:	75c080e7          	jalr	1884(ra) # 8000206a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005916:	2184a703          	lw	a4,536(s1)
    8000591a:	21c4a783          	lw	a5,540(s1)
    8000591e:	fef700e3          	beq	a4,a5,800058fe <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005922:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005924:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005926:	05505363          	blez	s5,8000596c <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000592a:	2184a783          	lw	a5,536(s1)
    8000592e:	21c4a703          	lw	a4,540(s1)
    80005932:	02f70d63          	beq	a4,a5,8000596c <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005936:	0017871b          	addiw	a4,a5,1
    8000593a:	20e4ac23          	sw	a4,536(s1)
    8000593e:	1ff7f793          	andi	a5,a5,511
    80005942:	97a6                	add	a5,a5,s1
    80005944:	0187c783          	lbu	a5,24(a5)
    80005948:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000594c:	4685                	li	a3,1
    8000594e:	fbf40613          	addi	a2,s0,-65
    80005952:	85ca                	mv	a1,s2
    80005954:	050a3503          	ld	a0,80(s4)
    80005958:	ffffc097          	auipc	ra,0xffffc
    8000595c:	d3c080e7          	jalr	-708(ra) # 80001694 <copyout>
    80005960:	01650663          	beq	a0,s6,8000596c <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005964:	2985                	addiw	s3,s3,1
    80005966:	0905                	addi	s2,s2,1
    80005968:	fd3a91e3          	bne	s5,s3,8000592a <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000596c:	21c48513          	addi	a0,s1,540
    80005970:	ffffc097          	auipc	ra,0xffffc
    80005974:	75e080e7          	jalr	1886(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80005978:	8526                	mv	a0,s1
    8000597a:	ffffb097          	auipc	ra,0xffffb
    8000597e:	2fc080e7          	jalr	764(ra) # 80000c76 <release>
  return i;
}
    80005982:	854e                	mv	a0,s3
    80005984:	60a6                	ld	ra,72(sp)
    80005986:	6406                	ld	s0,64(sp)
    80005988:	74e2                	ld	s1,56(sp)
    8000598a:	7942                	ld	s2,48(sp)
    8000598c:	79a2                	ld	s3,40(sp)
    8000598e:	7a02                	ld	s4,32(sp)
    80005990:	6ae2                	ld	s5,24(sp)
    80005992:	6b42                	ld	s6,16(sp)
    80005994:	6161                	addi	sp,sp,80
    80005996:	8082                	ret
      release(&pi->lock);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffb097          	auipc	ra,0xffffb
    8000599e:	2dc080e7          	jalr	732(ra) # 80000c76 <release>
      return -1;
    800059a2:	59fd                	li	s3,-1
    800059a4:	bff9                	j	80005982 <piperead+0xc2>

00000000800059a6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800059a6:	bd010113          	addi	sp,sp,-1072
    800059aa:	42113423          	sd	ra,1064(sp)
    800059ae:	42813023          	sd	s0,1056(sp)
    800059b2:	40913c23          	sd	s1,1048(sp)
    800059b6:	41213823          	sd	s2,1040(sp)
    800059ba:	41313423          	sd	s3,1032(sp)
    800059be:	41413023          	sd	s4,1024(sp)
    800059c2:	3f513c23          	sd	s5,1016(sp)
    800059c6:	3f613823          	sd	s6,1008(sp)
    800059ca:	3f713423          	sd	s7,1000(sp)
    800059ce:	3f813023          	sd	s8,992(sp)
    800059d2:	3d913c23          	sd	s9,984(sp)
    800059d6:	3da13823          	sd	s10,976(sp)
    800059da:	3db13423          	sd	s11,968(sp)
    800059de:	43010413          	addi	s0,sp,1072
    800059e2:	89aa                	mv	s3,a0
    800059e4:	bea43023          	sd	a0,-1056(s0)
    800059e8:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800059ec:	ffffc097          	auipc	ra,0xffffc
    800059f0:	fe8080e7          	jalr	-24(ra) # 800019d4 <myproc>
    800059f4:	84aa                	mv	s1,a0
    800059f6:	c0a43423          	sd	a0,-1016(s0)

  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_DISK_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    800059fa:	17050913          	addi	s2,a0,368
    800059fe:	10000613          	li	a2,256
    80005a02:	85ca                	mv	a1,s2
    80005a04:	d1040513          	addi	a0,s0,-752
    80005a08:	ffffb097          	auipc	ra,0xffffb
    80005a0c:	312080e7          	jalr	786(ra) # 80000d1a <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    80005a10:	27048493          	addi	s1,s1,624
    80005a14:	10000613          	li	a2,256
    80005a18:	85a6                	mv	a1,s1
    80005a1a:	c1040513          	addi	a0,s0,-1008
    80005a1e:	ffffb097          	auipc	ra,0xffffb
    80005a22:	2fc080e7          	jalr	764(ra) # 80000d1a <memmove>

  begin_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	26c080e7          	jalr	620(ra) # 80004c92 <begin_op>

  if((ip = namei(path)) == 0){
    80005a2e:	854e                	mv	a0,s3
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	d30080e7          	jalr	-720(ra) # 80004760 <namei>
    80005a38:	c569                	beqz	a0,80005b02 <exec+0x15c>
    80005a3a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	56e080e7          	jalr	1390(ra) # 80003faa <ilock>

  // ADDED Q1
  if(relevant_metadata_proc(p) && init_metadata(p) < 0) {
    80005a44:	c0843983          	ld	s3,-1016(s0)
    80005a48:	854e                	mv	a0,s3
    80005a4a:	ffffc097          	auipc	ra,0xffffc
    80005a4e:	358080e7          	jalr	856(ra) # 80001da2 <relevant_metadata_proc>
    80005a52:	c901                	beqz	a0,80005a62 <exec+0xbc>
    80005a54:	854e                	mv	a0,s3
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	916080e7          	jalr	-1770(ra) # 8000236c <init_metadata>
    80005a5e:	02054963          	bltz	a0,80005a90 <exec+0xea>
    goto bad;
  } 

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005a62:	04000713          	li	a4,64
    80005a66:	4681                	li	a3,0
    80005a68:	e4840613          	addi	a2,s0,-440
    80005a6c:	4581                	li	a1,0
    80005a6e:	8552                	mv	a0,s4
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	7ee080e7          	jalr	2030(ra) # 8000425e <readi>
    80005a78:	04000793          	li	a5,64
    80005a7c:	00f51a63          	bne	a0,a5,80005a90 <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005a80:	e4842703          	lw	a4,-440(s0)
    80005a84:	464c47b7          	lui	a5,0x464c4
    80005a88:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005a8c:	08f70163          	beq	a4,a5,80005b0e <exec+0x168>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005a90:	10000613          	li	a2,256
    80005a94:	d1040593          	addi	a1,s0,-752
    80005a98:	854a                	mv	a0,s2
    80005a9a:	ffffb097          	auipc	ra,0xffffb
    80005a9e:	280080e7          	jalr	640(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005aa2:	10000613          	li	a2,256
    80005aa6:	c1040593          	addi	a1,s0,-1008
    80005aaa:	8526                	mv	a0,s1
    80005aac:	ffffb097          	auipc	ra,0xffffb
    80005ab0:	26e080e7          	jalr	622(ra) # 80000d1a <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005ab4:	8552                	mv	a0,s4
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	756080e7          	jalr	1878(ra) # 8000420c <iunlockput>
    end_op();
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	254080e7          	jalr	596(ra) # 80004d12 <end_op>
  }
  return -1;
    80005ac6:	557d                	li	a0,-1
}
    80005ac8:	42813083          	ld	ra,1064(sp)
    80005acc:	42013403          	ld	s0,1056(sp)
    80005ad0:	41813483          	ld	s1,1048(sp)
    80005ad4:	41013903          	ld	s2,1040(sp)
    80005ad8:	40813983          	ld	s3,1032(sp)
    80005adc:	40013a03          	ld	s4,1024(sp)
    80005ae0:	3f813a83          	ld	s5,1016(sp)
    80005ae4:	3f013b03          	ld	s6,1008(sp)
    80005ae8:	3e813b83          	ld	s7,1000(sp)
    80005aec:	3e013c03          	ld	s8,992(sp)
    80005af0:	3d813c83          	ld	s9,984(sp)
    80005af4:	3d013d03          	ld	s10,976(sp)
    80005af8:	3c813d83          	ld	s11,968(sp)
    80005afc:	43010113          	addi	sp,sp,1072
    80005b00:	8082                	ret
    end_op();
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	210080e7          	jalr	528(ra) # 80004d12 <end_op>
    return -1;
    80005b0a:	557d                	li	a0,-1
    80005b0c:	bf75                	j	80005ac8 <exec+0x122>
  if((pagetable = proc_pagetable(p)) == 0)
    80005b0e:	c0843503          	ld	a0,-1016(s0)
    80005b12:	ffffc097          	auipc	ra,0xffffc
    80005b16:	f86080e7          	jalr	-122(ra) # 80001a98 <proc_pagetable>
    80005b1a:	8b2a                	mv	s6,a0
    80005b1c:	d935                	beqz	a0,80005a90 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b1e:	e6842783          	lw	a5,-408(s0)
    80005b22:	e8045703          	lhu	a4,-384(s0)
    80005b26:	c735                	beqz	a4,80005b92 <exec+0x1ec>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b28:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b2a:	c0043023          	sd	zero,-1024(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005b2e:	6a85                	lui	s5,0x1
    80005b30:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80005b34:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005b38:	6d85                	lui	s11,0x1
    80005b3a:	7d7d                	lui	s10,0xfffff
    80005b3c:	a4ad                	j	80005da6 <exec+0x400>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005b3e:	00004517          	auipc	a0,0x4
    80005b42:	eca50513          	addi	a0,a0,-310 # 80009a08 <syscalls+0x2f0>
    80005b46:	ffffb097          	auipc	ra,0xffffb
    80005b4a:	9e4080e7          	jalr	-1564(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005b4e:	874a                	mv	a4,s2
    80005b50:	009c86bb          	addw	a3,s9,s1
    80005b54:	4581                	li	a1,0
    80005b56:	8552                	mv	a0,s4
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	706080e7          	jalr	1798(ra) # 8000425e <readi>
    80005b60:	2501                	sext.w	a0,a0
    80005b62:	1aa91c63          	bne	s2,a0,80005d1a <exec+0x374>
  for(i = 0; i < sz; i += PGSIZE){
    80005b66:	009d84bb          	addw	s1,s11,s1
    80005b6a:	013d09bb          	addw	s3,s10,s3
    80005b6e:	2174fc63          	bgeu	s1,s7,80005d86 <exec+0x3e0>
    pa = walkaddr(pagetable, va + i);
    80005b72:	02049593          	slli	a1,s1,0x20
    80005b76:	9181                	srli	a1,a1,0x20
    80005b78:	95e2                	add	a1,a1,s8
    80005b7a:	855a                	mv	a0,s6
    80005b7c:	ffffb097          	auipc	ra,0xffffb
    80005b80:	4d0080e7          	jalr	1232(ra) # 8000104c <walkaddr>
    80005b84:	862a                	mv	a2,a0
    if(pa == 0)
    80005b86:	dd45                	beqz	a0,80005b3e <exec+0x198>
      n = PGSIZE;
    80005b88:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    80005b8a:	fd59f2e3          	bgeu	s3,s5,80005b4e <exec+0x1a8>
      n = sz - i;
    80005b8e:	894e                	mv	s2,s3
    80005b90:	bf7d                	j	80005b4e <exec+0x1a8>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b92:	4481                	li	s1,0
  iunlockput(ip);
    80005b94:	8552                	mv	a0,s4
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	676080e7          	jalr	1654(ra) # 8000420c <iunlockput>
  end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	174080e7          	jalr	372(ra) # 80004d12 <end_op>
  p = myproc();
    80005ba6:	ffffc097          	auipc	ra,0xffffc
    80005baa:	e2e080e7          	jalr	-466(ra) # 800019d4 <myproc>
    80005bae:	c0a43423          	sd	a0,-1016(s0)
  uint64 oldsz = p->sz;
    80005bb2:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005bb6:	6785                	lui	a5,0x1
    80005bb8:	17fd                	addi	a5,a5,-1
    80005bba:	94be                	add	s1,s1,a5
    80005bbc:	77fd                	lui	a5,0xfffff
    80005bbe:	8fe5                	and	a5,a5,s1
    80005bc0:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005bc4:	6609                	lui	a2,0x2
    80005bc6:	963e                	add	a2,a2,a5
    80005bc8:	85be                	mv	a1,a5
    80005bca:	855a                	mv	a0,s6
    80005bcc:	ffffc097          	auipc	ra,0xffffc
    80005bd0:	868080e7          	jalr	-1944(ra) # 80001434 <uvmalloc>
    80005bd4:	8aaa                	mv	s5,a0
  ip = 0;
    80005bd6:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005bd8:	14050163          	beqz	a0,80005d1a <exec+0x374>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005bdc:	75f9                	lui	a1,0xffffe
    80005bde:	95aa                	add	a1,a1,a0
    80005be0:	855a                	mv	a0,s6
    80005be2:	ffffc097          	auipc	ra,0xffffc
    80005be6:	a80080e7          	jalr	-1408(ra) # 80001662 <uvmclear>
  stackbase = sp - PGSIZE;
    80005bea:	7bfd                	lui	s7,0xfffff
    80005bec:	9bd6                	add	s7,s7,s5
  for(argc = 0; argv[argc]; argc++) {
    80005bee:	be843783          	ld	a5,-1048(s0)
    80005bf2:	6388                	ld	a0,0(a5)
    80005bf4:	c925                	beqz	a0,80005c64 <exec+0x2be>
    80005bf6:	e8840993          	addi	s3,s0,-376
    80005bfa:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005bfe:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005c00:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005c02:	ffffb097          	auipc	ra,0xffffb
    80005c06:	240080e7          	jalr	576(ra) # 80000e42 <strlen>
    80005c0a:	0015079b          	addiw	a5,a0,1
    80005c0e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005c12:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005c16:	15796c63          	bltu	s2,s7,80005d6e <exec+0x3c8>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005c1a:	be843d03          	ld	s10,-1048(s0)
    80005c1e:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80005c22:	8552                	mv	a0,s4
    80005c24:	ffffb097          	auipc	ra,0xffffb
    80005c28:	21e080e7          	jalr	542(ra) # 80000e42 <strlen>
    80005c2c:	0015069b          	addiw	a3,a0,1
    80005c30:	8652                	mv	a2,s4
    80005c32:	85ca                	mv	a1,s2
    80005c34:	855a                	mv	a0,s6
    80005c36:	ffffc097          	auipc	ra,0xffffc
    80005c3a:	a5e080e7          	jalr	-1442(ra) # 80001694 <copyout>
    80005c3e:	12054c63          	bltz	a0,80005d76 <exec+0x3d0>
    ustack[argc] = sp;
    80005c42:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005c46:	0485                	addi	s1,s1,1
    80005c48:	008d0793          	addi	a5,s10,8
    80005c4c:	bef43423          	sd	a5,-1048(s0)
    80005c50:	008d3503          	ld	a0,8(s10)
    80005c54:	c911                	beqz	a0,80005c68 <exec+0x2c2>
    if(argc >= MAXARG)
    80005c56:	09a1                	addi	s3,s3,8
    80005c58:	fb8995e3          	bne	s3,s8,80005c02 <exec+0x25c>
  sz = sz1;
    80005c5c:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005c60:	4a01                	li	s4,0
    80005c62:	a865                	j	80005d1a <exec+0x374>
  sp = sz;
    80005c64:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005c66:	4481                	li	s1,0
  ustack[argc] = 0;
    80005c68:	00349793          	slli	a5,s1,0x3
    80005c6c:	f9040713          	addi	a4,s0,-112
    80005c70:	97ba                	add	a5,a5,a4
    80005c72:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005c76:	00148693          	addi	a3,s1,1
    80005c7a:	068e                	slli	a3,a3,0x3
    80005c7c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c80:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005c84:	01797663          	bgeu	s2,s7,80005c90 <exec+0x2ea>
  sz = sz1;
    80005c88:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005c8c:	4a01                	li	s4,0
    80005c8e:	a071                	j	80005d1a <exec+0x374>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c90:	e8840613          	addi	a2,s0,-376
    80005c94:	85ca                	mv	a1,s2
    80005c96:	855a                	mv	a0,s6
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	9fc080e7          	jalr	-1540(ra) # 80001694 <copyout>
    80005ca0:	0c054f63          	bltz	a0,80005d7e <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005ca4:	c0843783          	ld	a5,-1016(s0)
    80005ca8:	6fbc                	ld	a5,88(a5)
    80005caa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005cae:	be043783          	ld	a5,-1056(s0)
    80005cb2:	0007c703          	lbu	a4,0(a5)
    80005cb6:	cf11                	beqz	a4,80005cd2 <exec+0x32c>
    80005cb8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005cba:	02f00693          	li	a3,47
    80005cbe:	a039                	j	80005ccc <exec+0x326>
      last = s+1;
    80005cc0:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005cc4:	0785                	addi	a5,a5,1
    80005cc6:	fff7c703          	lbu	a4,-1(a5)
    80005cca:	c701                	beqz	a4,80005cd2 <exec+0x32c>
    if(*s == '/')
    80005ccc:	fed71ce3          	bne	a4,a3,80005cc4 <exec+0x31e>
    80005cd0:	bfc5                	j	80005cc0 <exec+0x31a>
  safestrcpy(p->name, last, sizeof(p->name));
    80005cd2:	4641                	li	a2,16
    80005cd4:	be043583          	ld	a1,-1056(s0)
    80005cd8:	c0843983          	ld	s3,-1016(s0)
    80005cdc:	15898513          	addi	a0,s3,344
    80005ce0:	ffffb097          	auipc	ra,0xffffb
    80005ce4:	130080e7          	jalr	304(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005ce8:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005cec:	0569b823          	sd	s6,80(s3)
  p->sz = sz;
    80005cf0:	0559b423          	sd	s5,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005cf4:	0589b783          	ld	a5,88(s3)
    80005cf8:	e6043703          	ld	a4,-416(s0)
    80005cfc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005cfe:	0589b783          	ld	a5,88(s3)
    80005d02:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005d06:	85e6                	mv	a1,s9
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	e2c080e7          	jalr	-468(ra) # 80001b34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005d10:	0004851b          	sext.w	a0,s1
    80005d14:	bb55                	j	80005ac8 <exec+0x122>
    80005d16:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005d1a:	10000613          	li	a2,256
    80005d1e:	d1040593          	addi	a1,s0,-752
    80005d22:	c0843483          	ld	s1,-1016(s0)
    80005d26:	17048513          	addi	a0,s1,368
    80005d2a:	ffffb097          	auipc	ra,0xffffb
    80005d2e:	ff0080e7          	jalr	-16(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005d32:	10000613          	li	a2,256
    80005d36:	c1040593          	addi	a1,s0,-1008
    80005d3a:	27048513          	addi	a0,s1,624
    80005d3e:	ffffb097          	auipc	ra,0xffffb
    80005d42:	fdc080e7          	jalr	-36(ra) # 80000d1a <memmove>
    proc_freepagetable(pagetable, sz);
    80005d46:	bf043583          	ld	a1,-1040(s0)
    80005d4a:	855a                	mv	a0,s6
    80005d4c:	ffffc097          	auipc	ra,0xffffc
    80005d50:	de8080e7          	jalr	-536(ra) # 80001b34 <proc_freepagetable>
  if(ip){
    80005d54:	d60a10e3          	bnez	s4,80005ab4 <exec+0x10e>
  return -1;
    80005d58:	557d                	li	a0,-1
    80005d5a:	b3bd                	j	80005ac8 <exec+0x122>
    80005d5c:	be943823          	sd	s1,-1040(s0)
    80005d60:	bf6d                	j	80005d1a <exec+0x374>
    80005d62:	be943823          	sd	s1,-1040(s0)
    80005d66:	bf55                	j	80005d1a <exec+0x374>
    80005d68:	be943823          	sd	s1,-1040(s0)
    80005d6c:	b77d                	j	80005d1a <exec+0x374>
  sz = sz1;
    80005d6e:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d72:	4a01                	li	s4,0
    80005d74:	b75d                	j	80005d1a <exec+0x374>
  sz = sz1;
    80005d76:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d7a:	4a01                	li	s4,0
    80005d7c:	bf79                	j	80005d1a <exec+0x374>
  sz = sz1;
    80005d7e:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d82:	4a01                	li	s4,0
    80005d84:	bf59                	j	80005d1a <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d86:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d8a:	c0043783          	ld	a5,-1024(s0)
    80005d8e:	0017869b          	addiw	a3,a5,1
    80005d92:	c0d43023          	sd	a3,-1024(s0)
    80005d96:	bf843783          	ld	a5,-1032(s0)
    80005d9a:	0387879b          	addiw	a5,a5,56
    80005d9e:	e8045703          	lhu	a4,-384(s0)
    80005da2:	dee6d9e3          	bge	a3,a4,80005b94 <exec+0x1ee>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005da6:	2781                	sext.w	a5,a5
    80005da8:	bef43c23          	sd	a5,-1032(s0)
    80005dac:	03800713          	li	a4,56
    80005db0:	86be                	mv	a3,a5
    80005db2:	e1040613          	addi	a2,s0,-496
    80005db6:	4581                	li	a1,0
    80005db8:	8552                	mv	a0,s4
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	4a4080e7          	jalr	1188(ra) # 8000425e <readi>
    80005dc2:	03800793          	li	a5,56
    80005dc6:	f4f518e3          	bne	a0,a5,80005d16 <exec+0x370>
    if(ph.type != ELF_PROG_LOAD)
    80005dca:	e1042783          	lw	a5,-496(s0)
    80005dce:	4705                	li	a4,1
    80005dd0:	fae79de3          	bne	a5,a4,80005d8a <exec+0x3e4>
    if(ph.memsz < ph.filesz)
    80005dd4:	e3843603          	ld	a2,-456(s0)
    80005dd8:	e3043783          	ld	a5,-464(s0)
    80005ddc:	f8f660e3          	bltu	a2,a5,80005d5c <exec+0x3b6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005de0:	e2043783          	ld	a5,-480(s0)
    80005de4:	963e                	add	a2,a2,a5
    80005de6:	f6f66ee3          	bltu	a2,a5,80005d62 <exec+0x3bc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005dea:	85a6                	mv	a1,s1
    80005dec:	855a                	mv	a0,s6
    80005dee:	ffffb097          	auipc	ra,0xffffb
    80005df2:	646080e7          	jalr	1606(ra) # 80001434 <uvmalloc>
    80005df6:	bea43823          	sd	a0,-1040(s0)
    80005dfa:	d53d                	beqz	a0,80005d68 <exec+0x3c2>
    if(ph.vaddr % PGSIZE != 0)
    80005dfc:	e2043c03          	ld	s8,-480(s0)
    80005e00:	bd843783          	ld	a5,-1064(s0)
    80005e04:	00fc77b3          	and	a5,s8,a5
    80005e08:	fb89                	bnez	a5,80005d1a <exec+0x374>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005e0a:	e1842c83          	lw	s9,-488(s0)
    80005e0e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005e12:	f60b8ae3          	beqz	s7,80005d86 <exec+0x3e0>
    80005e16:	89de                	mv	s3,s7
    80005e18:	4481                	li	s1,0
    80005e1a:	bba1                	j	80005b72 <exec+0x1cc>

0000000080005e1c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005e1c:	7179                	addi	sp,sp,-48
    80005e1e:	f406                	sd	ra,40(sp)
    80005e20:	f022                	sd	s0,32(sp)
    80005e22:	ec26                	sd	s1,24(sp)
    80005e24:	e84a                	sd	s2,16(sp)
    80005e26:	1800                	addi	s0,sp,48
    80005e28:	892e                	mv	s2,a1
    80005e2a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005e2c:	fdc40593          	addi	a1,s0,-36
    80005e30:	ffffd097          	auipc	ra,0xffffd
    80005e34:	608080e7          	jalr	1544(ra) # 80003438 <argint>
    80005e38:	04054063          	bltz	a0,80005e78 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005e3c:	fdc42703          	lw	a4,-36(s0)
    80005e40:	47bd                	li	a5,15
    80005e42:	02e7ed63          	bltu	a5,a4,80005e7c <argfd+0x60>
    80005e46:	ffffc097          	auipc	ra,0xffffc
    80005e4a:	b8e080e7          	jalr	-1138(ra) # 800019d4 <myproc>
    80005e4e:	fdc42703          	lw	a4,-36(s0)
    80005e52:	01a70793          	addi	a5,a4,26
    80005e56:	078e                	slli	a5,a5,0x3
    80005e58:	953e                	add	a0,a0,a5
    80005e5a:	611c                	ld	a5,0(a0)
    80005e5c:	c395                	beqz	a5,80005e80 <argfd+0x64>
    return -1;
  if(pfd)
    80005e5e:	00090463          	beqz	s2,80005e66 <argfd+0x4a>
    *pfd = fd;
    80005e62:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005e66:	4501                	li	a0,0
  if(pf)
    80005e68:	c091                	beqz	s1,80005e6c <argfd+0x50>
    *pf = f;
    80005e6a:	e09c                	sd	a5,0(s1)
}
    80005e6c:	70a2                	ld	ra,40(sp)
    80005e6e:	7402                	ld	s0,32(sp)
    80005e70:	64e2                	ld	s1,24(sp)
    80005e72:	6942                	ld	s2,16(sp)
    80005e74:	6145                	addi	sp,sp,48
    80005e76:	8082                	ret
    return -1;
    80005e78:	557d                	li	a0,-1
    80005e7a:	bfcd                	j	80005e6c <argfd+0x50>
    return -1;
    80005e7c:	557d                	li	a0,-1
    80005e7e:	b7fd                	j	80005e6c <argfd+0x50>
    80005e80:	557d                	li	a0,-1
    80005e82:	b7ed                	j	80005e6c <argfd+0x50>

0000000080005e84 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005e84:	1101                	addi	sp,sp,-32
    80005e86:	ec06                	sd	ra,24(sp)
    80005e88:	e822                	sd	s0,16(sp)
    80005e8a:	e426                	sd	s1,8(sp)
    80005e8c:	1000                	addi	s0,sp,32
    80005e8e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	b44080e7          	jalr	-1212(ra) # 800019d4 <myproc>
    80005e98:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005e9a:	0d050793          	addi	a5,a0,208
    80005e9e:	4501                	li	a0,0
    80005ea0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005ea2:	6398                	ld	a4,0(a5)
    80005ea4:	cb19                	beqz	a4,80005eba <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005ea6:	2505                	addiw	a0,a0,1
    80005ea8:	07a1                	addi	a5,a5,8
    80005eaa:	fed51ce3          	bne	a0,a3,80005ea2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005eae:	557d                	li	a0,-1
}
    80005eb0:	60e2                	ld	ra,24(sp)
    80005eb2:	6442                	ld	s0,16(sp)
    80005eb4:	64a2                	ld	s1,8(sp)
    80005eb6:	6105                	addi	sp,sp,32
    80005eb8:	8082                	ret
      p->ofile[fd] = f;
    80005eba:	01a50793          	addi	a5,a0,26
    80005ebe:	078e                	slli	a5,a5,0x3
    80005ec0:	963e                	add	a2,a2,a5
    80005ec2:	e204                	sd	s1,0(a2)
      return fd;
    80005ec4:	b7f5                	j	80005eb0 <fdalloc+0x2c>

0000000080005ec6 <sys_dup>:

uint64
sys_dup(void)
{
    80005ec6:	7179                	addi	sp,sp,-48
    80005ec8:	f406                	sd	ra,40(sp)
    80005eca:	f022                	sd	s0,32(sp)
    80005ecc:	ec26                	sd	s1,24(sp)
    80005ece:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005ed0:	fd840613          	addi	a2,s0,-40
    80005ed4:	4581                	li	a1,0
    80005ed6:	4501                	li	a0,0
    80005ed8:	00000097          	auipc	ra,0x0
    80005edc:	f44080e7          	jalr	-188(ra) # 80005e1c <argfd>
    return -1;
    80005ee0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005ee2:	02054363          	bltz	a0,80005f08 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005ee6:	fd843503          	ld	a0,-40(s0)
    80005eea:	00000097          	auipc	ra,0x0
    80005eee:	f9a080e7          	jalr	-102(ra) # 80005e84 <fdalloc>
    80005ef2:	84aa                	mv	s1,a0
    return -1;
    80005ef4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005ef6:	00054963          	bltz	a0,80005f08 <sys_dup+0x42>
  filedup(f);
    80005efa:	fd843503          	ld	a0,-40(s0)
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	20e080e7          	jalr	526(ra) # 8000510c <filedup>
  return fd;
    80005f06:	87a6                	mv	a5,s1
}
    80005f08:	853e                	mv	a0,a5
    80005f0a:	70a2                	ld	ra,40(sp)
    80005f0c:	7402                	ld	s0,32(sp)
    80005f0e:	64e2                	ld	s1,24(sp)
    80005f10:	6145                	addi	sp,sp,48
    80005f12:	8082                	ret

0000000080005f14 <sys_read>:

uint64
sys_read(void)
{
    80005f14:	7179                	addi	sp,sp,-48
    80005f16:	f406                	sd	ra,40(sp)
    80005f18:	f022                	sd	s0,32(sp)
    80005f1a:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f1c:	fe840613          	addi	a2,s0,-24
    80005f20:	4581                	li	a1,0
    80005f22:	4501                	li	a0,0
    80005f24:	00000097          	auipc	ra,0x0
    80005f28:	ef8080e7          	jalr	-264(ra) # 80005e1c <argfd>
    return -1;
    80005f2c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f2e:	04054163          	bltz	a0,80005f70 <sys_read+0x5c>
    80005f32:	fe440593          	addi	a1,s0,-28
    80005f36:	4509                	li	a0,2
    80005f38:	ffffd097          	auipc	ra,0xffffd
    80005f3c:	500080e7          	jalr	1280(ra) # 80003438 <argint>
    return -1;
    80005f40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f42:	02054763          	bltz	a0,80005f70 <sys_read+0x5c>
    80005f46:	fd840593          	addi	a1,s0,-40
    80005f4a:	4505                	li	a0,1
    80005f4c:	ffffd097          	auipc	ra,0xffffd
    80005f50:	50e080e7          	jalr	1294(ra) # 8000345a <argaddr>
    return -1;
    80005f54:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f56:	00054d63          	bltz	a0,80005f70 <sys_read+0x5c>
  return fileread(f, p, n);
    80005f5a:	fe442603          	lw	a2,-28(s0)
    80005f5e:	fd843583          	ld	a1,-40(s0)
    80005f62:	fe843503          	ld	a0,-24(s0)
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	332080e7          	jalr	818(ra) # 80005298 <fileread>
    80005f6e:	87aa                	mv	a5,a0
}
    80005f70:	853e                	mv	a0,a5
    80005f72:	70a2                	ld	ra,40(sp)
    80005f74:	7402                	ld	s0,32(sp)
    80005f76:	6145                	addi	sp,sp,48
    80005f78:	8082                	ret

0000000080005f7a <sys_write>:

uint64
sys_write(void)
{
    80005f7a:	7179                	addi	sp,sp,-48
    80005f7c:	f406                	sd	ra,40(sp)
    80005f7e:	f022                	sd	s0,32(sp)
    80005f80:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f82:	fe840613          	addi	a2,s0,-24
    80005f86:	4581                	li	a1,0
    80005f88:	4501                	li	a0,0
    80005f8a:	00000097          	auipc	ra,0x0
    80005f8e:	e92080e7          	jalr	-366(ra) # 80005e1c <argfd>
    return -1;
    80005f92:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f94:	04054163          	bltz	a0,80005fd6 <sys_write+0x5c>
    80005f98:	fe440593          	addi	a1,s0,-28
    80005f9c:	4509                	li	a0,2
    80005f9e:	ffffd097          	auipc	ra,0xffffd
    80005fa2:	49a080e7          	jalr	1178(ra) # 80003438 <argint>
    return -1;
    80005fa6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fa8:	02054763          	bltz	a0,80005fd6 <sys_write+0x5c>
    80005fac:	fd840593          	addi	a1,s0,-40
    80005fb0:	4505                	li	a0,1
    80005fb2:	ffffd097          	auipc	ra,0xffffd
    80005fb6:	4a8080e7          	jalr	1192(ra) # 8000345a <argaddr>
    return -1;
    80005fba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fbc:	00054d63          	bltz	a0,80005fd6 <sys_write+0x5c>

  return filewrite(f, p, n);
    80005fc0:	fe442603          	lw	a2,-28(s0)
    80005fc4:	fd843583          	ld	a1,-40(s0)
    80005fc8:	fe843503          	ld	a0,-24(s0)
    80005fcc:	fffff097          	auipc	ra,0xfffff
    80005fd0:	38e080e7          	jalr	910(ra) # 8000535a <filewrite>
    80005fd4:	87aa                	mv	a5,a0
}
    80005fd6:	853e                	mv	a0,a5
    80005fd8:	70a2                	ld	ra,40(sp)
    80005fda:	7402                	ld	s0,32(sp)
    80005fdc:	6145                	addi	sp,sp,48
    80005fde:	8082                	ret

0000000080005fe0 <sys_close>:

uint64
sys_close(void)
{
    80005fe0:	1101                	addi	sp,sp,-32
    80005fe2:	ec06                	sd	ra,24(sp)
    80005fe4:	e822                	sd	s0,16(sp)
    80005fe6:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005fe8:	fe040613          	addi	a2,s0,-32
    80005fec:	fec40593          	addi	a1,s0,-20
    80005ff0:	4501                	li	a0,0
    80005ff2:	00000097          	auipc	ra,0x0
    80005ff6:	e2a080e7          	jalr	-470(ra) # 80005e1c <argfd>
    return -1;
    80005ffa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ffc:	02054463          	bltz	a0,80006024 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80006000:	ffffc097          	auipc	ra,0xffffc
    80006004:	9d4080e7          	jalr	-1580(ra) # 800019d4 <myproc>
    80006008:	fec42783          	lw	a5,-20(s0)
    8000600c:	07e9                	addi	a5,a5,26
    8000600e:	078e                	slli	a5,a5,0x3
    80006010:	97aa                	add	a5,a5,a0
    80006012:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80006016:	fe043503          	ld	a0,-32(s0)
    8000601a:	fffff097          	auipc	ra,0xfffff
    8000601e:	144080e7          	jalr	324(ra) # 8000515e <fileclose>
  return 0;
    80006022:	4781                	li	a5,0
}
    80006024:	853e                	mv	a0,a5
    80006026:	60e2                	ld	ra,24(sp)
    80006028:	6442                	ld	s0,16(sp)
    8000602a:	6105                	addi	sp,sp,32
    8000602c:	8082                	ret

000000008000602e <sys_fstat>:

uint64
sys_fstat(void)
{
    8000602e:	1101                	addi	sp,sp,-32
    80006030:	ec06                	sd	ra,24(sp)
    80006032:	e822                	sd	s0,16(sp)
    80006034:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006036:	fe840613          	addi	a2,s0,-24
    8000603a:	4581                	li	a1,0
    8000603c:	4501                	li	a0,0
    8000603e:	00000097          	auipc	ra,0x0
    80006042:	dde080e7          	jalr	-546(ra) # 80005e1c <argfd>
    return -1;
    80006046:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006048:	02054563          	bltz	a0,80006072 <sys_fstat+0x44>
    8000604c:	fe040593          	addi	a1,s0,-32
    80006050:	4505                	li	a0,1
    80006052:	ffffd097          	auipc	ra,0xffffd
    80006056:	408080e7          	jalr	1032(ra) # 8000345a <argaddr>
    return -1;
    8000605a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000605c:	00054b63          	bltz	a0,80006072 <sys_fstat+0x44>
  return filestat(f, st);
    80006060:	fe043583          	ld	a1,-32(s0)
    80006064:	fe843503          	ld	a0,-24(s0)
    80006068:	fffff097          	auipc	ra,0xfffff
    8000606c:	1be080e7          	jalr	446(ra) # 80005226 <filestat>
    80006070:	87aa                	mv	a5,a0
}
    80006072:	853e                	mv	a0,a5
    80006074:	60e2                	ld	ra,24(sp)
    80006076:	6442                	ld	s0,16(sp)
    80006078:	6105                	addi	sp,sp,32
    8000607a:	8082                	ret

000000008000607c <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    8000607c:	7169                	addi	sp,sp,-304
    8000607e:	f606                	sd	ra,296(sp)
    80006080:	f222                	sd	s0,288(sp)
    80006082:	ee26                	sd	s1,280(sp)
    80006084:	ea4a                	sd	s2,272(sp)
    80006086:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006088:	08000613          	li	a2,128
    8000608c:	ed040593          	addi	a1,s0,-304
    80006090:	4501                	li	a0,0
    80006092:	ffffd097          	auipc	ra,0xffffd
    80006096:	3ea080e7          	jalr	1002(ra) # 8000347c <argstr>
    return -1;
    8000609a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000609c:	10054e63          	bltz	a0,800061b8 <sys_link+0x13c>
    800060a0:	08000613          	li	a2,128
    800060a4:	f5040593          	addi	a1,s0,-176
    800060a8:	4505                	li	a0,1
    800060aa:	ffffd097          	auipc	ra,0xffffd
    800060ae:	3d2080e7          	jalr	978(ra) # 8000347c <argstr>
    return -1;
    800060b2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060b4:	10054263          	bltz	a0,800061b8 <sys_link+0x13c>

  begin_op();
    800060b8:	fffff097          	auipc	ra,0xfffff
    800060bc:	bda080e7          	jalr	-1062(ra) # 80004c92 <begin_op>
  if((ip = namei(old)) == 0){
    800060c0:	ed040513          	addi	a0,s0,-304
    800060c4:	ffffe097          	auipc	ra,0xffffe
    800060c8:	69c080e7          	jalr	1692(ra) # 80004760 <namei>
    800060cc:	84aa                	mv	s1,a0
    800060ce:	c551                	beqz	a0,8000615a <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	eda080e7          	jalr	-294(ra) # 80003faa <ilock>
  if(ip->type == T_DIR){
    800060d8:	04449703          	lh	a4,68(s1)
    800060dc:	4785                	li	a5,1
    800060de:	08f70463          	beq	a4,a5,80006166 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    800060e2:	04a4d783          	lhu	a5,74(s1)
    800060e6:	2785                	addiw	a5,a5,1
    800060e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060ec:	8526                	mv	a0,s1
    800060ee:	ffffe097          	auipc	ra,0xffffe
    800060f2:	df2080e7          	jalr	-526(ra) # 80003ee0 <iupdate>
  iunlock(ip);
    800060f6:	8526                	mv	a0,s1
    800060f8:	ffffe097          	auipc	ra,0xffffe
    800060fc:	f74080e7          	jalr	-140(ra) # 8000406c <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80006100:	fd040593          	addi	a1,s0,-48
    80006104:	f5040513          	addi	a0,s0,-176
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	676080e7          	jalr	1654(ra) # 8000477e <nameiparent>
    80006110:	892a                	mv	s2,a0
    80006112:	c935                	beqz	a0,80006186 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80006114:	ffffe097          	auipc	ra,0xffffe
    80006118:	e96080e7          	jalr	-362(ra) # 80003faa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000611c:	00092703          	lw	a4,0(s2)
    80006120:	409c                	lw	a5,0(s1)
    80006122:	04f71d63          	bne	a4,a5,8000617c <sys_link+0x100>
    80006126:	40d0                	lw	a2,4(s1)
    80006128:	fd040593          	addi	a1,s0,-48
    8000612c:	854a                	mv	a0,s2
    8000612e:	ffffe097          	auipc	ra,0xffffe
    80006132:	570080e7          	jalr	1392(ra) # 8000469e <dirlink>
    80006136:	04054363          	bltz	a0,8000617c <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    8000613a:	854a                	mv	a0,s2
    8000613c:	ffffe097          	auipc	ra,0xffffe
    80006140:	0d0080e7          	jalr	208(ra) # 8000420c <iunlockput>
  iput(ip);
    80006144:	8526                	mv	a0,s1
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	01e080e7          	jalr	30(ra) # 80004164 <iput>

  end_op();
    8000614e:	fffff097          	auipc	ra,0xfffff
    80006152:	bc4080e7          	jalr	-1084(ra) # 80004d12 <end_op>

  return 0;
    80006156:	4781                	li	a5,0
    80006158:	a085                	j	800061b8 <sys_link+0x13c>
    end_op();
    8000615a:	fffff097          	auipc	ra,0xfffff
    8000615e:	bb8080e7          	jalr	-1096(ra) # 80004d12 <end_op>
    return -1;
    80006162:	57fd                	li	a5,-1
    80006164:	a891                	j	800061b8 <sys_link+0x13c>
    iunlockput(ip);
    80006166:	8526                	mv	a0,s1
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	0a4080e7          	jalr	164(ra) # 8000420c <iunlockput>
    end_op();
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	ba2080e7          	jalr	-1118(ra) # 80004d12 <end_op>
    return -1;
    80006178:	57fd                	li	a5,-1
    8000617a:	a83d                	j	800061b8 <sys_link+0x13c>
    iunlockput(dp);
    8000617c:	854a                	mv	a0,s2
    8000617e:	ffffe097          	auipc	ra,0xffffe
    80006182:	08e080e7          	jalr	142(ra) # 8000420c <iunlockput>

bad:
  ilock(ip);
    80006186:	8526                	mv	a0,s1
    80006188:	ffffe097          	auipc	ra,0xffffe
    8000618c:	e22080e7          	jalr	-478(ra) # 80003faa <ilock>
  ip->nlink--;
    80006190:	04a4d783          	lhu	a5,74(s1)
    80006194:	37fd                	addiw	a5,a5,-1
    80006196:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000619a:	8526                	mv	a0,s1
    8000619c:	ffffe097          	auipc	ra,0xffffe
    800061a0:	d44080e7          	jalr	-700(ra) # 80003ee0 <iupdate>
  iunlockput(ip);
    800061a4:	8526                	mv	a0,s1
    800061a6:	ffffe097          	auipc	ra,0xffffe
    800061aa:	066080e7          	jalr	102(ra) # 8000420c <iunlockput>
  end_op();
    800061ae:	fffff097          	auipc	ra,0xfffff
    800061b2:	b64080e7          	jalr	-1180(ra) # 80004d12 <end_op>
  return -1;
    800061b6:	57fd                	li	a5,-1
}
    800061b8:	853e                	mv	a0,a5
    800061ba:	70b2                	ld	ra,296(sp)
    800061bc:	7412                	ld	s0,288(sp)
    800061be:	64f2                	ld	s1,280(sp)
    800061c0:	6952                	ld	s2,272(sp)
    800061c2:	6155                	addi	sp,sp,304
    800061c4:	8082                	ret

00000000800061c6 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061c6:	4578                	lw	a4,76(a0)
    800061c8:	02000793          	li	a5,32
    800061cc:	04e7fa63          	bgeu	a5,a4,80006220 <isdirempty+0x5a>
{
    800061d0:	7179                	addi	sp,sp,-48
    800061d2:	f406                	sd	ra,40(sp)
    800061d4:	f022                	sd	s0,32(sp)
    800061d6:	ec26                	sd	s1,24(sp)
    800061d8:	e84a                	sd	s2,16(sp)
    800061da:	1800                	addi	s0,sp,48
    800061dc:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061de:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061e2:	4741                	li	a4,16
    800061e4:	86a6                	mv	a3,s1
    800061e6:	fd040613          	addi	a2,s0,-48
    800061ea:	4581                	li	a1,0
    800061ec:	854a                	mv	a0,s2
    800061ee:	ffffe097          	auipc	ra,0xffffe
    800061f2:	070080e7          	jalr	112(ra) # 8000425e <readi>
    800061f6:	47c1                	li	a5,16
    800061f8:	00f51c63          	bne	a0,a5,80006210 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    800061fc:	fd045783          	lhu	a5,-48(s0)
    80006200:	e395                	bnez	a5,80006224 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006202:	24c1                	addiw	s1,s1,16
    80006204:	04c92783          	lw	a5,76(s2)
    80006208:	fcf4ede3          	bltu	s1,a5,800061e2 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    8000620c:	4505                	li	a0,1
    8000620e:	a821                	j	80006226 <isdirempty+0x60>
      panic("isdirempty: readi");
    80006210:	00004517          	auipc	a0,0x4
    80006214:	81850513          	addi	a0,a0,-2024 # 80009a28 <syscalls+0x310>
    80006218:	ffffa097          	auipc	ra,0xffffa
    8000621c:	312080e7          	jalr	786(ra) # 8000052a <panic>
  return 1;
    80006220:	4505                	li	a0,1
}
    80006222:	8082                	ret
      return 0;
    80006224:	4501                	li	a0,0
}
    80006226:	70a2                	ld	ra,40(sp)
    80006228:	7402                	ld	s0,32(sp)
    8000622a:	64e2                	ld	s1,24(sp)
    8000622c:	6942                	ld	s2,16(sp)
    8000622e:	6145                	addi	sp,sp,48
    80006230:	8082                	ret

0000000080006232 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006232:	7155                	addi	sp,sp,-208
    80006234:	e586                	sd	ra,200(sp)
    80006236:	e1a2                	sd	s0,192(sp)
    80006238:	fd26                	sd	s1,184(sp)
    8000623a:	f94a                	sd	s2,176(sp)
    8000623c:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    8000623e:	08000613          	li	a2,128
    80006242:	f4040593          	addi	a1,s0,-192
    80006246:	4501                	li	a0,0
    80006248:	ffffd097          	auipc	ra,0xffffd
    8000624c:	234080e7          	jalr	564(ra) # 8000347c <argstr>
    80006250:	16054363          	bltz	a0,800063b6 <sys_unlink+0x184>
    return -1;

  begin_op();
    80006254:	fffff097          	auipc	ra,0xfffff
    80006258:	a3e080e7          	jalr	-1474(ra) # 80004c92 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000625c:	fc040593          	addi	a1,s0,-64
    80006260:	f4040513          	addi	a0,s0,-192
    80006264:	ffffe097          	auipc	ra,0xffffe
    80006268:	51a080e7          	jalr	1306(ra) # 8000477e <nameiparent>
    8000626c:	84aa                	mv	s1,a0
    8000626e:	c961                	beqz	a0,8000633e <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80006270:	ffffe097          	auipc	ra,0xffffe
    80006274:	d3a080e7          	jalr	-710(ra) # 80003faa <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006278:	00003597          	auipc	a1,0x3
    8000627c:	69058593          	addi	a1,a1,1680 # 80009908 <syscalls+0x1f0>
    80006280:	fc040513          	addi	a0,s0,-64
    80006284:	ffffe097          	auipc	ra,0xffffe
    80006288:	1f0080e7          	jalr	496(ra) # 80004474 <namecmp>
    8000628c:	c175                	beqz	a0,80006370 <sys_unlink+0x13e>
    8000628e:	00003597          	auipc	a1,0x3
    80006292:	68258593          	addi	a1,a1,1666 # 80009910 <syscalls+0x1f8>
    80006296:	fc040513          	addi	a0,s0,-64
    8000629a:	ffffe097          	auipc	ra,0xffffe
    8000629e:	1da080e7          	jalr	474(ra) # 80004474 <namecmp>
    800062a2:	c579                	beqz	a0,80006370 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800062a4:	f3c40613          	addi	a2,s0,-196
    800062a8:	fc040593          	addi	a1,s0,-64
    800062ac:	8526                	mv	a0,s1
    800062ae:	ffffe097          	auipc	ra,0xffffe
    800062b2:	1e0080e7          	jalr	480(ra) # 8000448e <dirlookup>
    800062b6:	892a                	mv	s2,a0
    800062b8:	cd45                	beqz	a0,80006370 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    800062ba:	ffffe097          	auipc	ra,0xffffe
    800062be:	cf0080e7          	jalr	-784(ra) # 80003faa <ilock>

  if(ip->nlink < 1)
    800062c2:	04a91783          	lh	a5,74(s2)
    800062c6:	08f05263          	blez	a5,8000634a <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800062ca:	04491703          	lh	a4,68(s2)
    800062ce:	4785                	li	a5,1
    800062d0:	08f70563          	beq	a4,a5,8000635a <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800062d4:	4641                	li	a2,16
    800062d6:	4581                	li	a1,0
    800062d8:	fd040513          	addi	a0,s0,-48
    800062dc:	ffffb097          	auipc	ra,0xffffb
    800062e0:	9e2080e7          	jalr	-1566(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800062e4:	4741                	li	a4,16
    800062e6:	f3c42683          	lw	a3,-196(s0)
    800062ea:	fd040613          	addi	a2,s0,-48
    800062ee:	4581                	li	a1,0
    800062f0:	8526                	mv	a0,s1
    800062f2:	ffffe097          	auipc	ra,0xffffe
    800062f6:	064080e7          	jalr	100(ra) # 80004356 <writei>
    800062fa:	47c1                	li	a5,16
    800062fc:	08f51a63          	bne	a0,a5,80006390 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80006300:	04491703          	lh	a4,68(s2)
    80006304:	4785                	li	a5,1
    80006306:	08f70d63          	beq	a4,a5,800063a0 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000630a:	8526                	mv	a0,s1
    8000630c:	ffffe097          	auipc	ra,0xffffe
    80006310:	f00080e7          	jalr	-256(ra) # 8000420c <iunlockput>

  ip->nlink--;
    80006314:	04a95783          	lhu	a5,74(s2)
    80006318:	37fd                	addiw	a5,a5,-1
    8000631a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000631e:	854a                	mv	a0,s2
    80006320:	ffffe097          	auipc	ra,0xffffe
    80006324:	bc0080e7          	jalr	-1088(ra) # 80003ee0 <iupdate>
  iunlockput(ip);
    80006328:	854a                	mv	a0,s2
    8000632a:	ffffe097          	auipc	ra,0xffffe
    8000632e:	ee2080e7          	jalr	-286(ra) # 8000420c <iunlockput>

  end_op();
    80006332:	fffff097          	auipc	ra,0xfffff
    80006336:	9e0080e7          	jalr	-1568(ra) # 80004d12 <end_op>

  return 0;
    8000633a:	4501                	li	a0,0
    8000633c:	a0a1                	j	80006384 <sys_unlink+0x152>
    end_op();
    8000633e:	fffff097          	auipc	ra,0xfffff
    80006342:	9d4080e7          	jalr	-1580(ra) # 80004d12 <end_op>
    return -1;
    80006346:	557d                	li	a0,-1
    80006348:	a835                	j	80006384 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    8000634a:	00003517          	auipc	a0,0x3
    8000634e:	5ce50513          	addi	a0,a0,1486 # 80009918 <syscalls+0x200>
    80006352:	ffffa097          	auipc	ra,0xffffa
    80006356:	1d8080e7          	jalr	472(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000635a:	854a                	mv	a0,s2
    8000635c:	00000097          	auipc	ra,0x0
    80006360:	e6a080e7          	jalr	-406(ra) # 800061c6 <isdirempty>
    80006364:	f925                	bnez	a0,800062d4 <sys_unlink+0xa2>
    iunlockput(ip);
    80006366:	854a                	mv	a0,s2
    80006368:	ffffe097          	auipc	ra,0xffffe
    8000636c:	ea4080e7          	jalr	-348(ra) # 8000420c <iunlockput>

bad:
  iunlockput(dp);
    80006370:	8526                	mv	a0,s1
    80006372:	ffffe097          	auipc	ra,0xffffe
    80006376:	e9a080e7          	jalr	-358(ra) # 8000420c <iunlockput>
  end_op();
    8000637a:	fffff097          	auipc	ra,0xfffff
    8000637e:	998080e7          	jalr	-1640(ra) # 80004d12 <end_op>
  return -1;
    80006382:	557d                	li	a0,-1
}
    80006384:	60ae                	ld	ra,200(sp)
    80006386:	640e                	ld	s0,192(sp)
    80006388:	74ea                	ld	s1,184(sp)
    8000638a:	794a                	ld	s2,176(sp)
    8000638c:	6169                	addi	sp,sp,208
    8000638e:	8082                	ret
    panic("unlink: writei");
    80006390:	00003517          	auipc	a0,0x3
    80006394:	5a050513          	addi	a0,a0,1440 # 80009930 <syscalls+0x218>
    80006398:	ffffa097          	auipc	ra,0xffffa
    8000639c:	192080e7          	jalr	402(ra) # 8000052a <panic>
    dp->nlink--;
    800063a0:	04a4d783          	lhu	a5,74(s1)
    800063a4:	37fd                	addiw	a5,a5,-1
    800063a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800063aa:	8526                	mv	a0,s1
    800063ac:	ffffe097          	auipc	ra,0xffffe
    800063b0:	b34080e7          	jalr	-1228(ra) # 80003ee0 <iupdate>
    800063b4:	bf99                	j	8000630a <sys_unlink+0xd8>
    return -1;
    800063b6:	557d                	li	a0,-1
    800063b8:	b7f1                	j	80006384 <sys_unlink+0x152>

00000000800063ba <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    800063ba:	715d                	addi	sp,sp,-80
    800063bc:	e486                	sd	ra,72(sp)
    800063be:	e0a2                	sd	s0,64(sp)
    800063c0:	fc26                	sd	s1,56(sp)
    800063c2:	f84a                	sd	s2,48(sp)
    800063c4:	f44e                	sd	s3,40(sp)
    800063c6:	f052                	sd	s4,32(sp)
    800063c8:	ec56                	sd	s5,24(sp)
    800063ca:	0880                	addi	s0,sp,80
    800063cc:	89ae                	mv	s3,a1
    800063ce:	8ab2                	mv	s5,a2
    800063d0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800063d2:	fb040593          	addi	a1,s0,-80
    800063d6:	ffffe097          	auipc	ra,0xffffe
    800063da:	3a8080e7          	jalr	936(ra) # 8000477e <nameiparent>
    800063de:	892a                	mv	s2,a0
    800063e0:	12050e63          	beqz	a0,8000651c <create+0x162>
    return 0;

  ilock(dp);
    800063e4:	ffffe097          	auipc	ra,0xffffe
    800063e8:	bc6080e7          	jalr	-1082(ra) # 80003faa <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    800063ec:	4601                	li	a2,0
    800063ee:	fb040593          	addi	a1,s0,-80
    800063f2:	854a                	mv	a0,s2
    800063f4:	ffffe097          	auipc	ra,0xffffe
    800063f8:	09a080e7          	jalr	154(ra) # 8000448e <dirlookup>
    800063fc:	84aa                	mv	s1,a0
    800063fe:	c921                	beqz	a0,8000644e <create+0x94>
    iunlockput(dp);
    80006400:	854a                	mv	a0,s2
    80006402:	ffffe097          	auipc	ra,0xffffe
    80006406:	e0a080e7          	jalr	-502(ra) # 8000420c <iunlockput>
    ilock(ip);
    8000640a:	8526                	mv	a0,s1
    8000640c:	ffffe097          	auipc	ra,0xffffe
    80006410:	b9e080e7          	jalr	-1122(ra) # 80003faa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006414:	2981                	sext.w	s3,s3
    80006416:	4789                	li	a5,2
    80006418:	02f99463          	bne	s3,a5,80006440 <create+0x86>
    8000641c:	0444d783          	lhu	a5,68(s1)
    80006420:	37f9                	addiw	a5,a5,-2
    80006422:	17c2                	slli	a5,a5,0x30
    80006424:	93c1                	srli	a5,a5,0x30
    80006426:	4705                	li	a4,1
    80006428:	00f76c63          	bltu	a4,a5,80006440 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000642c:	8526                	mv	a0,s1
    8000642e:	60a6                	ld	ra,72(sp)
    80006430:	6406                	ld	s0,64(sp)
    80006432:	74e2                	ld	s1,56(sp)
    80006434:	7942                	ld	s2,48(sp)
    80006436:	79a2                	ld	s3,40(sp)
    80006438:	7a02                	ld	s4,32(sp)
    8000643a:	6ae2                	ld	s5,24(sp)
    8000643c:	6161                	addi	sp,sp,80
    8000643e:	8082                	ret
    iunlockput(ip);
    80006440:	8526                	mv	a0,s1
    80006442:	ffffe097          	auipc	ra,0xffffe
    80006446:	dca080e7          	jalr	-566(ra) # 8000420c <iunlockput>
    return 0;
    8000644a:	4481                	li	s1,0
    8000644c:	b7c5                	j	8000642c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000644e:	85ce                	mv	a1,s3
    80006450:	00092503          	lw	a0,0(s2)
    80006454:	ffffe097          	auipc	ra,0xffffe
    80006458:	9be080e7          	jalr	-1602(ra) # 80003e12 <ialloc>
    8000645c:	84aa                	mv	s1,a0
    8000645e:	c521                	beqz	a0,800064a6 <create+0xec>
  ilock(ip);
    80006460:	ffffe097          	auipc	ra,0xffffe
    80006464:	b4a080e7          	jalr	-1206(ra) # 80003faa <ilock>
  ip->major = major;
    80006468:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000646c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006470:	4a05                	li	s4,1
    80006472:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80006476:	8526                	mv	a0,s1
    80006478:	ffffe097          	auipc	ra,0xffffe
    8000647c:	a68080e7          	jalr	-1432(ra) # 80003ee0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006480:	2981                	sext.w	s3,s3
    80006482:	03498a63          	beq	s3,s4,800064b6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80006486:	40d0                	lw	a2,4(s1)
    80006488:	fb040593          	addi	a1,s0,-80
    8000648c:	854a                	mv	a0,s2
    8000648e:	ffffe097          	auipc	ra,0xffffe
    80006492:	210080e7          	jalr	528(ra) # 8000469e <dirlink>
    80006496:	06054b63          	bltz	a0,8000650c <create+0x152>
  iunlockput(dp);
    8000649a:	854a                	mv	a0,s2
    8000649c:	ffffe097          	auipc	ra,0xffffe
    800064a0:	d70080e7          	jalr	-656(ra) # 8000420c <iunlockput>
  return ip;
    800064a4:	b761                	j	8000642c <create+0x72>
    panic("create: ialloc");
    800064a6:	00003517          	auipc	a0,0x3
    800064aa:	59a50513          	addi	a0,a0,1434 # 80009a40 <syscalls+0x328>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	07c080e7          	jalr	124(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800064b6:	04a95783          	lhu	a5,74(s2)
    800064ba:	2785                	addiw	a5,a5,1
    800064bc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800064c0:	854a                	mv	a0,s2
    800064c2:	ffffe097          	auipc	ra,0xffffe
    800064c6:	a1e080e7          	jalr	-1506(ra) # 80003ee0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800064ca:	40d0                	lw	a2,4(s1)
    800064cc:	00003597          	auipc	a1,0x3
    800064d0:	43c58593          	addi	a1,a1,1084 # 80009908 <syscalls+0x1f0>
    800064d4:	8526                	mv	a0,s1
    800064d6:	ffffe097          	auipc	ra,0xffffe
    800064da:	1c8080e7          	jalr	456(ra) # 8000469e <dirlink>
    800064de:	00054f63          	bltz	a0,800064fc <create+0x142>
    800064e2:	00492603          	lw	a2,4(s2)
    800064e6:	00003597          	auipc	a1,0x3
    800064ea:	42a58593          	addi	a1,a1,1066 # 80009910 <syscalls+0x1f8>
    800064ee:	8526                	mv	a0,s1
    800064f0:	ffffe097          	auipc	ra,0xffffe
    800064f4:	1ae080e7          	jalr	430(ra) # 8000469e <dirlink>
    800064f8:	f80557e3          	bgez	a0,80006486 <create+0xcc>
      panic("create dots");
    800064fc:	00003517          	auipc	a0,0x3
    80006500:	55450513          	addi	a0,a0,1364 # 80009a50 <syscalls+0x338>
    80006504:	ffffa097          	auipc	ra,0xffffa
    80006508:	026080e7          	jalr	38(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000650c:	00003517          	auipc	a0,0x3
    80006510:	55450513          	addi	a0,a0,1364 # 80009a60 <syscalls+0x348>
    80006514:	ffffa097          	auipc	ra,0xffffa
    80006518:	016080e7          	jalr	22(ra) # 8000052a <panic>
    return 0;
    8000651c:	84aa                	mv	s1,a0
    8000651e:	b739                	j	8000642c <create+0x72>

0000000080006520 <sys_open>:

uint64
sys_open(void)
{
    80006520:	7131                	addi	sp,sp,-192
    80006522:	fd06                	sd	ra,184(sp)
    80006524:	f922                	sd	s0,176(sp)
    80006526:	f526                	sd	s1,168(sp)
    80006528:	f14a                	sd	s2,160(sp)
    8000652a:	ed4e                	sd	s3,152(sp)
    8000652c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000652e:	08000613          	li	a2,128
    80006532:	f5040593          	addi	a1,s0,-176
    80006536:	4501                	li	a0,0
    80006538:	ffffd097          	auipc	ra,0xffffd
    8000653c:	f44080e7          	jalr	-188(ra) # 8000347c <argstr>
    return -1;
    80006540:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006542:	0c054163          	bltz	a0,80006604 <sys_open+0xe4>
    80006546:	f4c40593          	addi	a1,s0,-180
    8000654a:	4505                	li	a0,1
    8000654c:	ffffd097          	auipc	ra,0xffffd
    80006550:	eec080e7          	jalr	-276(ra) # 80003438 <argint>
    80006554:	0a054863          	bltz	a0,80006604 <sys_open+0xe4>

  begin_op();
    80006558:	ffffe097          	auipc	ra,0xffffe
    8000655c:	73a080e7          	jalr	1850(ra) # 80004c92 <begin_op>

  if(omode & O_CREATE){
    80006560:	f4c42783          	lw	a5,-180(s0)
    80006564:	2007f793          	andi	a5,a5,512
    80006568:	cbdd                	beqz	a5,8000661e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000656a:	4681                	li	a3,0
    8000656c:	4601                	li	a2,0
    8000656e:	4589                	li	a1,2
    80006570:	f5040513          	addi	a0,s0,-176
    80006574:	00000097          	auipc	ra,0x0
    80006578:	e46080e7          	jalr	-442(ra) # 800063ba <create>
    8000657c:	892a                	mv	s2,a0
    if(ip == 0){
    8000657e:	c959                	beqz	a0,80006614 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006580:	04491703          	lh	a4,68(s2)
    80006584:	478d                	li	a5,3
    80006586:	00f71763          	bne	a4,a5,80006594 <sys_open+0x74>
    8000658a:	04695703          	lhu	a4,70(s2)
    8000658e:	47a5                	li	a5,9
    80006590:	0ce7ec63          	bltu	a5,a4,80006668 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006594:	fffff097          	auipc	ra,0xfffff
    80006598:	b0e080e7          	jalr	-1266(ra) # 800050a2 <filealloc>
    8000659c:	89aa                	mv	s3,a0
    8000659e:	10050263          	beqz	a0,800066a2 <sys_open+0x182>
    800065a2:	00000097          	auipc	ra,0x0
    800065a6:	8e2080e7          	jalr	-1822(ra) # 80005e84 <fdalloc>
    800065aa:	84aa                	mv	s1,a0
    800065ac:	0e054663          	bltz	a0,80006698 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800065b0:	04491703          	lh	a4,68(s2)
    800065b4:	478d                	li	a5,3
    800065b6:	0cf70463          	beq	a4,a5,8000667e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800065ba:	4789                	li	a5,2
    800065bc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800065c0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800065c4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800065c8:	f4c42783          	lw	a5,-180(s0)
    800065cc:	0017c713          	xori	a4,a5,1
    800065d0:	8b05                	andi	a4,a4,1
    800065d2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800065d6:	0037f713          	andi	a4,a5,3
    800065da:	00e03733          	snez	a4,a4
    800065de:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800065e2:	4007f793          	andi	a5,a5,1024
    800065e6:	c791                	beqz	a5,800065f2 <sys_open+0xd2>
    800065e8:	04491703          	lh	a4,68(s2)
    800065ec:	4789                	li	a5,2
    800065ee:	08f70f63          	beq	a4,a5,8000668c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800065f2:	854a                	mv	a0,s2
    800065f4:	ffffe097          	auipc	ra,0xffffe
    800065f8:	a78080e7          	jalr	-1416(ra) # 8000406c <iunlock>
  end_op();
    800065fc:	ffffe097          	auipc	ra,0xffffe
    80006600:	716080e7          	jalr	1814(ra) # 80004d12 <end_op>

  return fd;
}
    80006604:	8526                	mv	a0,s1
    80006606:	70ea                	ld	ra,184(sp)
    80006608:	744a                	ld	s0,176(sp)
    8000660a:	74aa                	ld	s1,168(sp)
    8000660c:	790a                	ld	s2,160(sp)
    8000660e:	69ea                	ld	s3,152(sp)
    80006610:	6129                	addi	sp,sp,192
    80006612:	8082                	ret
      end_op();
    80006614:	ffffe097          	auipc	ra,0xffffe
    80006618:	6fe080e7          	jalr	1790(ra) # 80004d12 <end_op>
      return -1;
    8000661c:	b7e5                	j	80006604 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000661e:	f5040513          	addi	a0,s0,-176
    80006622:	ffffe097          	auipc	ra,0xffffe
    80006626:	13e080e7          	jalr	318(ra) # 80004760 <namei>
    8000662a:	892a                	mv	s2,a0
    8000662c:	c905                	beqz	a0,8000665c <sys_open+0x13c>
    ilock(ip);
    8000662e:	ffffe097          	auipc	ra,0xffffe
    80006632:	97c080e7          	jalr	-1668(ra) # 80003faa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006636:	04491703          	lh	a4,68(s2)
    8000663a:	4785                	li	a5,1
    8000663c:	f4f712e3          	bne	a4,a5,80006580 <sys_open+0x60>
    80006640:	f4c42783          	lw	a5,-180(s0)
    80006644:	dba1                	beqz	a5,80006594 <sys_open+0x74>
      iunlockput(ip);
    80006646:	854a                	mv	a0,s2
    80006648:	ffffe097          	auipc	ra,0xffffe
    8000664c:	bc4080e7          	jalr	-1084(ra) # 8000420c <iunlockput>
      end_op();
    80006650:	ffffe097          	auipc	ra,0xffffe
    80006654:	6c2080e7          	jalr	1730(ra) # 80004d12 <end_op>
      return -1;
    80006658:	54fd                	li	s1,-1
    8000665a:	b76d                	j	80006604 <sys_open+0xe4>
      end_op();
    8000665c:	ffffe097          	auipc	ra,0xffffe
    80006660:	6b6080e7          	jalr	1718(ra) # 80004d12 <end_op>
      return -1;
    80006664:	54fd                	li	s1,-1
    80006666:	bf79                	j	80006604 <sys_open+0xe4>
    iunlockput(ip);
    80006668:	854a                	mv	a0,s2
    8000666a:	ffffe097          	auipc	ra,0xffffe
    8000666e:	ba2080e7          	jalr	-1118(ra) # 8000420c <iunlockput>
    end_op();
    80006672:	ffffe097          	auipc	ra,0xffffe
    80006676:	6a0080e7          	jalr	1696(ra) # 80004d12 <end_op>
    return -1;
    8000667a:	54fd                	li	s1,-1
    8000667c:	b761                	j	80006604 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000667e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006682:	04691783          	lh	a5,70(s2)
    80006686:	02f99223          	sh	a5,36(s3)
    8000668a:	bf2d                	j	800065c4 <sys_open+0xa4>
    itrunc(ip);
    8000668c:	854a                	mv	a0,s2
    8000668e:	ffffe097          	auipc	ra,0xffffe
    80006692:	a2a080e7          	jalr	-1494(ra) # 800040b8 <itrunc>
    80006696:	bfb1                	j	800065f2 <sys_open+0xd2>
      fileclose(f);
    80006698:	854e                	mv	a0,s3
    8000669a:	fffff097          	auipc	ra,0xfffff
    8000669e:	ac4080e7          	jalr	-1340(ra) # 8000515e <fileclose>
    iunlockput(ip);
    800066a2:	854a                	mv	a0,s2
    800066a4:	ffffe097          	auipc	ra,0xffffe
    800066a8:	b68080e7          	jalr	-1176(ra) # 8000420c <iunlockput>
    end_op();
    800066ac:	ffffe097          	auipc	ra,0xffffe
    800066b0:	666080e7          	jalr	1638(ra) # 80004d12 <end_op>
    return -1;
    800066b4:	54fd                	li	s1,-1
    800066b6:	b7b9                	j	80006604 <sys_open+0xe4>

00000000800066b8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800066b8:	7175                	addi	sp,sp,-144
    800066ba:	e506                	sd	ra,136(sp)
    800066bc:	e122                	sd	s0,128(sp)
    800066be:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800066c0:	ffffe097          	auipc	ra,0xffffe
    800066c4:	5d2080e7          	jalr	1490(ra) # 80004c92 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800066c8:	08000613          	li	a2,128
    800066cc:	f7040593          	addi	a1,s0,-144
    800066d0:	4501                	li	a0,0
    800066d2:	ffffd097          	auipc	ra,0xffffd
    800066d6:	daa080e7          	jalr	-598(ra) # 8000347c <argstr>
    800066da:	02054963          	bltz	a0,8000670c <sys_mkdir+0x54>
    800066de:	4681                	li	a3,0
    800066e0:	4601                	li	a2,0
    800066e2:	4585                	li	a1,1
    800066e4:	f7040513          	addi	a0,s0,-144
    800066e8:	00000097          	auipc	ra,0x0
    800066ec:	cd2080e7          	jalr	-814(ra) # 800063ba <create>
    800066f0:	cd11                	beqz	a0,8000670c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066f2:	ffffe097          	auipc	ra,0xffffe
    800066f6:	b1a080e7          	jalr	-1254(ra) # 8000420c <iunlockput>
  end_op();
    800066fa:	ffffe097          	auipc	ra,0xffffe
    800066fe:	618080e7          	jalr	1560(ra) # 80004d12 <end_op>
  return 0;
    80006702:	4501                	li	a0,0
}
    80006704:	60aa                	ld	ra,136(sp)
    80006706:	640a                	ld	s0,128(sp)
    80006708:	6149                	addi	sp,sp,144
    8000670a:	8082                	ret
    end_op();
    8000670c:	ffffe097          	auipc	ra,0xffffe
    80006710:	606080e7          	jalr	1542(ra) # 80004d12 <end_op>
    return -1;
    80006714:	557d                	li	a0,-1
    80006716:	b7fd                	j	80006704 <sys_mkdir+0x4c>

0000000080006718 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006718:	7135                	addi	sp,sp,-160
    8000671a:	ed06                	sd	ra,152(sp)
    8000671c:	e922                	sd	s0,144(sp)
    8000671e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006720:	ffffe097          	auipc	ra,0xffffe
    80006724:	572080e7          	jalr	1394(ra) # 80004c92 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006728:	08000613          	li	a2,128
    8000672c:	f7040593          	addi	a1,s0,-144
    80006730:	4501                	li	a0,0
    80006732:	ffffd097          	auipc	ra,0xffffd
    80006736:	d4a080e7          	jalr	-694(ra) # 8000347c <argstr>
    8000673a:	04054a63          	bltz	a0,8000678e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000673e:	f6c40593          	addi	a1,s0,-148
    80006742:	4505                	li	a0,1
    80006744:	ffffd097          	auipc	ra,0xffffd
    80006748:	cf4080e7          	jalr	-780(ra) # 80003438 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000674c:	04054163          	bltz	a0,8000678e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006750:	f6840593          	addi	a1,s0,-152
    80006754:	4509                	li	a0,2
    80006756:	ffffd097          	auipc	ra,0xffffd
    8000675a:	ce2080e7          	jalr	-798(ra) # 80003438 <argint>
     argint(1, &major) < 0 ||
    8000675e:	02054863          	bltz	a0,8000678e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006762:	f6841683          	lh	a3,-152(s0)
    80006766:	f6c41603          	lh	a2,-148(s0)
    8000676a:	458d                	li	a1,3
    8000676c:	f7040513          	addi	a0,s0,-144
    80006770:	00000097          	auipc	ra,0x0
    80006774:	c4a080e7          	jalr	-950(ra) # 800063ba <create>
     argint(2, &minor) < 0 ||
    80006778:	c919                	beqz	a0,8000678e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000677a:	ffffe097          	auipc	ra,0xffffe
    8000677e:	a92080e7          	jalr	-1390(ra) # 8000420c <iunlockput>
  end_op();
    80006782:	ffffe097          	auipc	ra,0xffffe
    80006786:	590080e7          	jalr	1424(ra) # 80004d12 <end_op>
  return 0;
    8000678a:	4501                	li	a0,0
    8000678c:	a031                	j	80006798 <sys_mknod+0x80>
    end_op();
    8000678e:	ffffe097          	auipc	ra,0xffffe
    80006792:	584080e7          	jalr	1412(ra) # 80004d12 <end_op>
    return -1;
    80006796:	557d                	li	a0,-1
}
    80006798:	60ea                	ld	ra,152(sp)
    8000679a:	644a                	ld	s0,144(sp)
    8000679c:	610d                	addi	sp,sp,160
    8000679e:	8082                	ret

00000000800067a0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800067a0:	7135                	addi	sp,sp,-160
    800067a2:	ed06                	sd	ra,152(sp)
    800067a4:	e922                	sd	s0,144(sp)
    800067a6:	e526                	sd	s1,136(sp)
    800067a8:	e14a                	sd	s2,128(sp)
    800067aa:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800067ac:	ffffb097          	auipc	ra,0xffffb
    800067b0:	228080e7          	jalr	552(ra) # 800019d4 <myproc>
    800067b4:	892a                	mv	s2,a0
  
  begin_op();
    800067b6:	ffffe097          	auipc	ra,0xffffe
    800067ba:	4dc080e7          	jalr	1244(ra) # 80004c92 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800067be:	08000613          	li	a2,128
    800067c2:	f6040593          	addi	a1,s0,-160
    800067c6:	4501                	li	a0,0
    800067c8:	ffffd097          	auipc	ra,0xffffd
    800067cc:	cb4080e7          	jalr	-844(ra) # 8000347c <argstr>
    800067d0:	04054b63          	bltz	a0,80006826 <sys_chdir+0x86>
    800067d4:	f6040513          	addi	a0,s0,-160
    800067d8:	ffffe097          	auipc	ra,0xffffe
    800067dc:	f88080e7          	jalr	-120(ra) # 80004760 <namei>
    800067e0:	84aa                	mv	s1,a0
    800067e2:	c131                	beqz	a0,80006826 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800067e4:	ffffd097          	auipc	ra,0xffffd
    800067e8:	7c6080e7          	jalr	1990(ra) # 80003faa <ilock>
  if(ip->type != T_DIR){
    800067ec:	04449703          	lh	a4,68(s1)
    800067f0:	4785                	li	a5,1
    800067f2:	04f71063          	bne	a4,a5,80006832 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800067f6:	8526                	mv	a0,s1
    800067f8:	ffffe097          	auipc	ra,0xffffe
    800067fc:	874080e7          	jalr	-1932(ra) # 8000406c <iunlock>
  iput(p->cwd);
    80006800:	15093503          	ld	a0,336(s2)
    80006804:	ffffe097          	auipc	ra,0xffffe
    80006808:	960080e7          	jalr	-1696(ra) # 80004164 <iput>
  end_op();
    8000680c:	ffffe097          	auipc	ra,0xffffe
    80006810:	506080e7          	jalr	1286(ra) # 80004d12 <end_op>
  p->cwd = ip;
    80006814:	14993823          	sd	s1,336(s2)
  return 0;
    80006818:	4501                	li	a0,0
}
    8000681a:	60ea                	ld	ra,152(sp)
    8000681c:	644a                	ld	s0,144(sp)
    8000681e:	64aa                	ld	s1,136(sp)
    80006820:	690a                	ld	s2,128(sp)
    80006822:	610d                	addi	sp,sp,160
    80006824:	8082                	ret
    end_op();
    80006826:	ffffe097          	auipc	ra,0xffffe
    8000682a:	4ec080e7          	jalr	1260(ra) # 80004d12 <end_op>
    return -1;
    8000682e:	557d                	li	a0,-1
    80006830:	b7ed                	j	8000681a <sys_chdir+0x7a>
    iunlockput(ip);
    80006832:	8526                	mv	a0,s1
    80006834:	ffffe097          	auipc	ra,0xffffe
    80006838:	9d8080e7          	jalr	-1576(ra) # 8000420c <iunlockput>
    end_op();
    8000683c:	ffffe097          	auipc	ra,0xffffe
    80006840:	4d6080e7          	jalr	1238(ra) # 80004d12 <end_op>
    return -1;
    80006844:	557d                	li	a0,-1
    80006846:	bfd1                	j	8000681a <sys_chdir+0x7a>

0000000080006848 <sys_exec>:

uint64
sys_exec(void)
{
    80006848:	7145                	addi	sp,sp,-464
    8000684a:	e786                	sd	ra,456(sp)
    8000684c:	e3a2                	sd	s0,448(sp)
    8000684e:	ff26                	sd	s1,440(sp)
    80006850:	fb4a                	sd	s2,432(sp)
    80006852:	f74e                	sd	s3,424(sp)
    80006854:	f352                	sd	s4,416(sp)
    80006856:	ef56                	sd	s5,408(sp)
    80006858:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000685a:	08000613          	li	a2,128
    8000685e:	f4040593          	addi	a1,s0,-192
    80006862:	4501                	li	a0,0
    80006864:	ffffd097          	auipc	ra,0xffffd
    80006868:	c18080e7          	jalr	-1000(ra) # 8000347c <argstr>
    return -1;
    8000686c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000686e:	0c054a63          	bltz	a0,80006942 <sys_exec+0xfa>
    80006872:	e3840593          	addi	a1,s0,-456
    80006876:	4505                	li	a0,1
    80006878:	ffffd097          	auipc	ra,0xffffd
    8000687c:	be2080e7          	jalr	-1054(ra) # 8000345a <argaddr>
    80006880:	0c054163          	bltz	a0,80006942 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006884:	10000613          	li	a2,256
    80006888:	4581                	li	a1,0
    8000688a:	e4040513          	addi	a0,s0,-448
    8000688e:	ffffa097          	auipc	ra,0xffffa
    80006892:	430080e7          	jalr	1072(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006896:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000689a:	89a6                	mv	s3,s1
    8000689c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000689e:	02000a13          	li	s4,32
    800068a2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800068a6:	00391793          	slli	a5,s2,0x3
    800068aa:	e3040593          	addi	a1,s0,-464
    800068ae:	e3843503          	ld	a0,-456(s0)
    800068b2:	953e                	add	a0,a0,a5
    800068b4:	ffffd097          	auipc	ra,0xffffd
    800068b8:	aea080e7          	jalr	-1302(ra) # 8000339e <fetchaddr>
    800068bc:	02054a63          	bltz	a0,800068f0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800068c0:	e3043783          	ld	a5,-464(s0)
    800068c4:	c3b9                	beqz	a5,8000690a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800068c6:	ffffa097          	auipc	ra,0xffffa
    800068ca:	20c080e7          	jalr	524(ra) # 80000ad2 <kalloc>
    800068ce:	85aa                	mv	a1,a0
    800068d0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800068d4:	cd11                	beqz	a0,800068f0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800068d6:	6605                	lui	a2,0x1
    800068d8:	e3043503          	ld	a0,-464(s0)
    800068dc:	ffffd097          	auipc	ra,0xffffd
    800068e0:	b14080e7          	jalr	-1260(ra) # 800033f0 <fetchstr>
    800068e4:	00054663          	bltz	a0,800068f0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800068e8:	0905                	addi	s2,s2,1
    800068ea:	09a1                	addi	s3,s3,8
    800068ec:	fb491be3          	bne	s2,s4,800068a2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068f0:	10048913          	addi	s2,s1,256
    800068f4:	6088                	ld	a0,0(s1)
    800068f6:	c529                	beqz	a0,80006940 <sys_exec+0xf8>
    kfree(argv[i]);
    800068f8:	ffffa097          	auipc	ra,0xffffa
    800068fc:	0de080e7          	jalr	222(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006900:	04a1                	addi	s1,s1,8
    80006902:	ff2499e3          	bne	s1,s2,800068f4 <sys_exec+0xac>
  return -1;
    80006906:	597d                	li	s2,-1
    80006908:	a82d                	j	80006942 <sys_exec+0xfa>
      argv[i] = 0;
    8000690a:	0a8e                	slli	s5,s5,0x3
    8000690c:	fc040793          	addi	a5,s0,-64
    80006910:	9abe                	add	s5,s5,a5
    80006912:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006916:	e4040593          	addi	a1,s0,-448
    8000691a:	f4040513          	addi	a0,s0,-192
    8000691e:	fffff097          	auipc	ra,0xfffff
    80006922:	088080e7          	jalr	136(ra) # 800059a6 <exec>
    80006926:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006928:	10048993          	addi	s3,s1,256
    8000692c:	6088                	ld	a0,0(s1)
    8000692e:	c911                	beqz	a0,80006942 <sys_exec+0xfa>
    kfree(argv[i]);
    80006930:	ffffa097          	auipc	ra,0xffffa
    80006934:	0a6080e7          	jalr	166(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006938:	04a1                	addi	s1,s1,8
    8000693a:	ff3499e3          	bne	s1,s3,8000692c <sys_exec+0xe4>
    8000693e:	a011                	j	80006942 <sys_exec+0xfa>
  return -1;
    80006940:	597d                	li	s2,-1
}
    80006942:	854a                	mv	a0,s2
    80006944:	60be                	ld	ra,456(sp)
    80006946:	641e                	ld	s0,448(sp)
    80006948:	74fa                	ld	s1,440(sp)
    8000694a:	795a                	ld	s2,432(sp)
    8000694c:	79ba                	ld	s3,424(sp)
    8000694e:	7a1a                	ld	s4,416(sp)
    80006950:	6afa                	ld	s5,408(sp)
    80006952:	6179                	addi	sp,sp,464
    80006954:	8082                	ret

0000000080006956 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006956:	7139                	addi	sp,sp,-64
    80006958:	fc06                	sd	ra,56(sp)
    8000695a:	f822                	sd	s0,48(sp)
    8000695c:	f426                	sd	s1,40(sp)
    8000695e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006960:	ffffb097          	auipc	ra,0xffffb
    80006964:	074080e7          	jalr	116(ra) # 800019d4 <myproc>
    80006968:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000696a:	fd840593          	addi	a1,s0,-40
    8000696e:	4501                	li	a0,0
    80006970:	ffffd097          	auipc	ra,0xffffd
    80006974:	aea080e7          	jalr	-1302(ra) # 8000345a <argaddr>
    return -1;
    80006978:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000697a:	0e054063          	bltz	a0,80006a5a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000697e:	fc840593          	addi	a1,s0,-56
    80006982:	fd040513          	addi	a0,s0,-48
    80006986:	fffff097          	auipc	ra,0xfffff
    8000698a:	cfe080e7          	jalr	-770(ra) # 80005684 <pipealloc>
    return -1;
    8000698e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006990:	0c054563          	bltz	a0,80006a5a <sys_pipe+0x104>
  fd0 = -1;
    80006994:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006998:	fd043503          	ld	a0,-48(s0)
    8000699c:	fffff097          	auipc	ra,0xfffff
    800069a0:	4e8080e7          	jalr	1256(ra) # 80005e84 <fdalloc>
    800069a4:	fca42223          	sw	a0,-60(s0)
    800069a8:	08054c63          	bltz	a0,80006a40 <sys_pipe+0xea>
    800069ac:	fc843503          	ld	a0,-56(s0)
    800069b0:	fffff097          	auipc	ra,0xfffff
    800069b4:	4d4080e7          	jalr	1236(ra) # 80005e84 <fdalloc>
    800069b8:	fca42023          	sw	a0,-64(s0)
    800069bc:	06054863          	bltz	a0,80006a2c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800069c0:	4691                	li	a3,4
    800069c2:	fc440613          	addi	a2,s0,-60
    800069c6:	fd843583          	ld	a1,-40(s0)
    800069ca:	68a8                	ld	a0,80(s1)
    800069cc:	ffffb097          	auipc	ra,0xffffb
    800069d0:	cc8080e7          	jalr	-824(ra) # 80001694 <copyout>
    800069d4:	02054063          	bltz	a0,800069f4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800069d8:	4691                	li	a3,4
    800069da:	fc040613          	addi	a2,s0,-64
    800069de:	fd843583          	ld	a1,-40(s0)
    800069e2:	0591                	addi	a1,a1,4
    800069e4:	68a8                	ld	a0,80(s1)
    800069e6:	ffffb097          	auipc	ra,0xffffb
    800069ea:	cae080e7          	jalr	-850(ra) # 80001694 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800069ee:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800069f0:	06055563          	bgez	a0,80006a5a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800069f4:	fc442783          	lw	a5,-60(s0)
    800069f8:	07e9                	addi	a5,a5,26
    800069fa:	078e                	slli	a5,a5,0x3
    800069fc:	97a6                	add	a5,a5,s1
    800069fe:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006a02:	fc042503          	lw	a0,-64(s0)
    80006a06:	0569                	addi	a0,a0,26
    80006a08:	050e                	slli	a0,a0,0x3
    80006a0a:	9526                	add	a0,a0,s1
    80006a0c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006a10:	fd043503          	ld	a0,-48(s0)
    80006a14:	ffffe097          	auipc	ra,0xffffe
    80006a18:	74a080e7          	jalr	1866(ra) # 8000515e <fileclose>
    fileclose(wf);
    80006a1c:	fc843503          	ld	a0,-56(s0)
    80006a20:	ffffe097          	auipc	ra,0xffffe
    80006a24:	73e080e7          	jalr	1854(ra) # 8000515e <fileclose>
    return -1;
    80006a28:	57fd                	li	a5,-1
    80006a2a:	a805                	j	80006a5a <sys_pipe+0x104>
    if(fd0 >= 0)
    80006a2c:	fc442783          	lw	a5,-60(s0)
    80006a30:	0007c863          	bltz	a5,80006a40 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006a34:	01a78513          	addi	a0,a5,26
    80006a38:	050e                	slli	a0,a0,0x3
    80006a3a:	9526                	add	a0,a0,s1
    80006a3c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006a40:	fd043503          	ld	a0,-48(s0)
    80006a44:	ffffe097          	auipc	ra,0xffffe
    80006a48:	71a080e7          	jalr	1818(ra) # 8000515e <fileclose>
    fileclose(wf);
    80006a4c:	fc843503          	ld	a0,-56(s0)
    80006a50:	ffffe097          	auipc	ra,0xffffe
    80006a54:	70e080e7          	jalr	1806(ra) # 8000515e <fileclose>
    return -1;
    80006a58:	57fd                	li	a5,-1
}
    80006a5a:	853e                	mv	a0,a5
    80006a5c:	70e2                	ld	ra,56(sp)
    80006a5e:	7442                	ld	s0,48(sp)
    80006a60:	74a2                	ld	s1,40(sp)
    80006a62:	6121                	addi	sp,sp,64
    80006a64:	8082                	ret
	...

0000000080006a70 <kernelvec>:
    80006a70:	7111                	addi	sp,sp,-256
    80006a72:	e006                	sd	ra,0(sp)
    80006a74:	e40a                	sd	sp,8(sp)
    80006a76:	e80e                	sd	gp,16(sp)
    80006a78:	ec12                	sd	tp,24(sp)
    80006a7a:	f016                	sd	t0,32(sp)
    80006a7c:	f41a                	sd	t1,40(sp)
    80006a7e:	f81e                	sd	t2,48(sp)
    80006a80:	fc22                	sd	s0,56(sp)
    80006a82:	e0a6                	sd	s1,64(sp)
    80006a84:	e4aa                	sd	a0,72(sp)
    80006a86:	e8ae                	sd	a1,80(sp)
    80006a88:	ecb2                	sd	a2,88(sp)
    80006a8a:	f0b6                	sd	a3,96(sp)
    80006a8c:	f4ba                	sd	a4,104(sp)
    80006a8e:	f8be                	sd	a5,112(sp)
    80006a90:	fcc2                	sd	a6,120(sp)
    80006a92:	e146                	sd	a7,128(sp)
    80006a94:	e54a                	sd	s2,136(sp)
    80006a96:	e94e                	sd	s3,144(sp)
    80006a98:	ed52                	sd	s4,152(sp)
    80006a9a:	f156                	sd	s5,160(sp)
    80006a9c:	f55a                	sd	s6,168(sp)
    80006a9e:	f95e                	sd	s7,176(sp)
    80006aa0:	fd62                	sd	s8,184(sp)
    80006aa2:	e1e6                	sd	s9,192(sp)
    80006aa4:	e5ea                	sd	s10,200(sp)
    80006aa6:	e9ee                	sd	s11,208(sp)
    80006aa8:	edf2                	sd	t3,216(sp)
    80006aaa:	f1f6                	sd	t4,224(sp)
    80006aac:	f5fa                	sd	t5,232(sp)
    80006aae:	f9fe                	sd	t6,240(sp)
    80006ab0:	fbafc0ef          	jal	ra,8000326a <kerneltrap>
    80006ab4:	6082                	ld	ra,0(sp)
    80006ab6:	6122                	ld	sp,8(sp)
    80006ab8:	61c2                	ld	gp,16(sp)
    80006aba:	7282                	ld	t0,32(sp)
    80006abc:	7322                	ld	t1,40(sp)
    80006abe:	73c2                	ld	t2,48(sp)
    80006ac0:	7462                	ld	s0,56(sp)
    80006ac2:	6486                	ld	s1,64(sp)
    80006ac4:	6526                	ld	a0,72(sp)
    80006ac6:	65c6                	ld	a1,80(sp)
    80006ac8:	6666                	ld	a2,88(sp)
    80006aca:	7686                	ld	a3,96(sp)
    80006acc:	7726                	ld	a4,104(sp)
    80006ace:	77c6                	ld	a5,112(sp)
    80006ad0:	7866                	ld	a6,120(sp)
    80006ad2:	688a                	ld	a7,128(sp)
    80006ad4:	692a                	ld	s2,136(sp)
    80006ad6:	69ca                	ld	s3,144(sp)
    80006ad8:	6a6a                	ld	s4,152(sp)
    80006ada:	7a8a                	ld	s5,160(sp)
    80006adc:	7b2a                	ld	s6,168(sp)
    80006ade:	7bca                	ld	s7,176(sp)
    80006ae0:	7c6a                	ld	s8,184(sp)
    80006ae2:	6c8e                	ld	s9,192(sp)
    80006ae4:	6d2e                	ld	s10,200(sp)
    80006ae6:	6dce                	ld	s11,208(sp)
    80006ae8:	6e6e                	ld	t3,216(sp)
    80006aea:	7e8e                	ld	t4,224(sp)
    80006aec:	7f2e                	ld	t5,232(sp)
    80006aee:	7fce                	ld	t6,240(sp)
    80006af0:	6111                	addi	sp,sp,256
    80006af2:	10200073          	sret
    80006af6:	00000013          	nop
    80006afa:	00000013          	nop
    80006afe:	0001                	nop

0000000080006b00 <timervec>:
    80006b00:	34051573          	csrrw	a0,mscratch,a0
    80006b04:	e10c                	sd	a1,0(a0)
    80006b06:	e510                	sd	a2,8(a0)
    80006b08:	e914                	sd	a3,16(a0)
    80006b0a:	6d0c                	ld	a1,24(a0)
    80006b0c:	7110                	ld	a2,32(a0)
    80006b0e:	6194                	ld	a3,0(a1)
    80006b10:	96b2                	add	a3,a3,a2
    80006b12:	e194                	sd	a3,0(a1)
    80006b14:	4589                	li	a1,2
    80006b16:	14459073          	csrw	sip,a1
    80006b1a:	6914                	ld	a3,16(a0)
    80006b1c:	6510                	ld	a2,8(a0)
    80006b1e:	610c                	ld	a1,0(a0)
    80006b20:	34051573          	csrrw	a0,mscratch,a0
    80006b24:	30200073          	mret
	...

0000000080006b2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006b2a:	1141                	addi	sp,sp,-16
    80006b2c:	e422                	sd	s0,8(sp)
    80006b2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006b30:	0c0007b7          	lui	a5,0xc000
    80006b34:	4705                	li	a4,1
    80006b36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006b38:	c3d8                	sw	a4,4(a5)
}
    80006b3a:	6422                	ld	s0,8(sp)
    80006b3c:	0141                	addi	sp,sp,16
    80006b3e:	8082                	ret

0000000080006b40 <plicinithart>:

void
plicinithart(void)
{
    80006b40:	1141                	addi	sp,sp,-16
    80006b42:	e406                	sd	ra,8(sp)
    80006b44:	e022                	sd	s0,0(sp)
    80006b46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b48:	ffffb097          	auipc	ra,0xffffb
    80006b4c:	e60080e7          	jalr	-416(ra) # 800019a8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006b50:	0085171b          	slliw	a4,a0,0x8
    80006b54:	0c0027b7          	lui	a5,0xc002
    80006b58:	97ba                	add	a5,a5,a4
    80006b5a:	40200713          	li	a4,1026
    80006b5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006b62:	00d5151b          	slliw	a0,a0,0xd
    80006b66:	0c2017b7          	lui	a5,0xc201
    80006b6a:	953e                	add	a0,a0,a5
    80006b6c:	00052023          	sw	zero,0(a0)
}
    80006b70:	60a2                	ld	ra,8(sp)
    80006b72:	6402                	ld	s0,0(sp)
    80006b74:	0141                	addi	sp,sp,16
    80006b76:	8082                	ret

0000000080006b78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006b78:	1141                	addi	sp,sp,-16
    80006b7a:	e406                	sd	ra,8(sp)
    80006b7c:	e022                	sd	s0,0(sp)
    80006b7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b80:	ffffb097          	auipc	ra,0xffffb
    80006b84:	e28080e7          	jalr	-472(ra) # 800019a8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006b88:	00d5179b          	slliw	a5,a0,0xd
    80006b8c:	0c201537          	lui	a0,0xc201
    80006b90:	953e                	add	a0,a0,a5
  return irq;
}
    80006b92:	4148                	lw	a0,4(a0)
    80006b94:	60a2                	ld	ra,8(sp)
    80006b96:	6402                	ld	s0,0(sp)
    80006b98:	0141                	addi	sp,sp,16
    80006b9a:	8082                	ret

0000000080006b9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006b9c:	1101                	addi	sp,sp,-32
    80006b9e:	ec06                	sd	ra,24(sp)
    80006ba0:	e822                	sd	s0,16(sp)
    80006ba2:	e426                	sd	s1,8(sp)
    80006ba4:	1000                	addi	s0,sp,32
    80006ba6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006ba8:	ffffb097          	auipc	ra,0xffffb
    80006bac:	e00080e7          	jalr	-512(ra) # 800019a8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006bb0:	00d5151b          	slliw	a0,a0,0xd
    80006bb4:	0c2017b7          	lui	a5,0xc201
    80006bb8:	97aa                	add	a5,a5,a0
    80006bba:	c3c4                	sw	s1,4(a5)
}
    80006bbc:	60e2                	ld	ra,24(sp)
    80006bbe:	6442                	ld	s0,16(sp)
    80006bc0:	64a2                	ld	s1,8(sp)
    80006bc2:	6105                	addi	sp,sp,32
    80006bc4:	8082                	ret

0000000080006bc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006bc6:	1141                	addi	sp,sp,-16
    80006bc8:	e406                	sd	ra,8(sp)
    80006bca:	e022                	sd	s0,0(sp)
    80006bcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006bce:	479d                	li	a5,7
    80006bd0:	06a7c963          	blt	a5,a0,80006c42 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006bd4:	00025797          	auipc	a5,0x25
    80006bd8:	42c78793          	addi	a5,a5,1068 # 8002c000 <disk>
    80006bdc:	00a78733          	add	a4,a5,a0
    80006be0:	6789                	lui	a5,0x2
    80006be2:	97ba                	add	a5,a5,a4
    80006be4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006be8:	e7ad                	bnez	a5,80006c52 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006bea:	00451793          	slli	a5,a0,0x4
    80006bee:	00027717          	auipc	a4,0x27
    80006bf2:	41270713          	addi	a4,a4,1042 # 8002e000 <disk+0x2000>
    80006bf6:	6314                	ld	a3,0(a4)
    80006bf8:	96be                	add	a3,a3,a5
    80006bfa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006bfe:	6314                	ld	a3,0(a4)
    80006c00:	96be                	add	a3,a3,a5
    80006c02:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006c06:	6314                	ld	a3,0(a4)
    80006c08:	96be                	add	a3,a3,a5
    80006c0a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006c0e:	6318                	ld	a4,0(a4)
    80006c10:	97ba                	add	a5,a5,a4
    80006c12:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006c16:	00025797          	auipc	a5,0x25
    80006c1a:	3ea78793          	addi	a5,a5,1002 # 8002c000 <disk>
    80006c1e:	97aa                	add	a5,a5,a0
    80006c20:	6509                	lui	a0,0x2
    80006c22:	953e                	add	a0,a0,a5
    80006c24:	4785                	li	a5,1
    80006c26:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006c2a:	00027517          	auipc	a0,0x27
    80006c2e:	3ee50513          	addi	a0,a0,1006 # 8002e018 <disk+0x2018>
    80006c32:	ffffb097          	auipc	ra,0xffffb
    80006c36:	49c080e7          	jalr	1180(ra) # 800020ce <wakeup>
}
    80006c3a:	60a2                	ld	ra,8(sp)
    80006c3c:	6402                	ld	s0,0(sp)
    80006c3e:	0141                	addi	sp,sp,16
    80006c40:	8082                	ret
    panic("free_desc 1");
    80006c42:	00003517          	auipc	a0,0x3
    80006c46:	e2e50513          	addi	a0,a0,-466 # 80009a70 <syscalls+0x358>
    80006c4a:	ffffa097          	auipc	ra,0xffffa
    80006c4e:	8e0080e7          	jalr	-1824(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006c52:	00003517          	auipc	a0,0x3
    80006c56:	e2e50513          	addi	a0,a0,-466 # 80009a80 <syscalls+0x368>
    80006c5a:	ffffa097          	auipc	ra,0xffffa
    80006c5e:	8d0080e7          	jalr	-1840(ra) # 8000052a <panic>

0000000080006c62 <virtio_disk_init>:
{
    80006c62:	1101                	addi	sp,sp,-32
    80006c64:	ec06                	sd	ra,24(sp)
    80006c66:	e822                	sd	s0,16(sp)
    80006c68:	e426                	sd	s1,8(sp)
    80006c6a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006c6c:	00003597          	auipc	a1,0x3
    80006c70:	e2458593          	addi	a1,a1,-476 # 80009a90 <syscalls+0x378>
    80006c74:	00027517          	auipc	a0,0x27
    80006c78:	4b450513          	addi	a0,a0,1204 # 8002e128 <disk+0x2128>
    80006c7c:	ffffa097          	auipc	ra,0xffffa
    80006c80:	eb6080e7          	jalr	-330(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c84:	100017b7          	lui	a5,0x10001
    80006c88:	4398                	lw	a4,0(a5)
    80006c8a:	2701                	sext.w	a4,a4
    80006c8c:	747277b7          	lui	a5,0x74727
    80006c90:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006c94:	0ef71163          	bne	a4,a5,80006d76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c98:	100017b7          	lui	a5,0x10001
    80006c9c:	43dc                	lw	a5,4(a5)
    80006c9e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006ca0:	4705                	li	a4,1
    80006ca2:	0ce79a63          	bne	a5,a4,80006d76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006ca6:	100017b7          	lui	a5,0x10001
    80006caa:	479c                	lw	a5,8(a5)
    80006cac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006cae:	4709                	li	a4,2
    80006cb0:	0ce79363          	bne	a5,a4,80006d76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006cb4:	100017b7          	lui	a5,0x10001
    80006cb8:	47d8                	lw	a4,12(a5)
    80006cba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006cbc:	554d47b7          	lui	a5,0x554d4
    80006cc0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006cc4:	0af71963          	bne	a4,a5,80006d76 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cc8:	100017b7          	lui	a5,0x10001
    80006ccc:	4705                	li	a4,1
    80006cce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cd0:	470d                	li	a4,3
    80006cd2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006cd4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006cd6:	c7ffe737          	lui	a4,0xc7ffe
    80006cda:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf75f>
    80006cde:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006ce0:	2701                	sext.w	a4,a4
    80006ce2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ce4:	472d                	li	a4,11
    80006ce6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ce8:	473d                	li	a4,15
    80006cea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006cec:	6705                	lui	a4,0x1
    80006cee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006cf0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006cf4:	5bdc                	lw	a5,52(a5)
    80006cf6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006cf8:	c7d9                	beqz	a5,80006d86 <virtio_disk_init+0x124>
  if(max < NUM)
    80006cfa:	471d                	li	a4,7
    80006cfc:	08f77d63          	bgeu	a4,a5,80006d96 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006d00:	100014b7          	lui	s1,0x10001
    80006d04:	47a1                	li	a5,8
    80006d06:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006d08:	6609                	lui	a2,0x2
    80006d0a:	4581                	li	a1,0
    80006d0c:	00025517          	auipc	a0,0x25
    80006d10:	2f450513          	addi	a0,a0,756 # 8002c000 <disk>
    80006d14:	ffffa097          	auipc	ra,0xffffa
    80006d18:	faa080e7          	jalr	-86(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006d1c:	00025717          	auipc	a4,0x25
    80006d20:	2e470713          	addi	a4,a4,740 # 8002c000 <disk>
    80006d24:	00c75793          	srli	a5,a4,0xc
    80006d28:	2781                	sext.w	a5,a5
    80006d2a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006d2c:	00027797          	auipc	a5,0x27
    80006d30:	2d478793          	addi	a5,a5,724 # 8002e000 <disk+0x2000>
    80006d34:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006d36:	00025717          	auipc	a4,0x25
    80006d3a:	34a70713          	addi	a4,a4,842 # 8002c080 <disk+0x80>
    80006d3e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006d40:	00026717          	auipc	a4,0x26
    80006d44:	2c070713          	addi	a4,a4,704 # 8002d000 <disk+0x1000>
    80006d48:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006d4a:	4705                	li	a4,1
    80006d4c:	00e78c23          	sb	a4,24(a5)
    80006d50:	00e78ca3          	sb	a4,25(a5)
    80006d54:	00e78d23          	sb	a4,26(a5)
    80006d58:	00e78da3          	sb	a4,27(a5)
    80006d5c:	00e78e23          	sb	a4,28(a5)
    80006d60:	00e78ea3          	sb	a4,29(a5)
    80006d64:	00e78f23          	sb	a4,30(a5)
    80006d68:	00e78fa3          	sb	a4,31(a5)
}
    80006d6c:	60e2                	ld	ra,24(sp)
    80006d6e:	6442                	ld	s0,16(sp)
    80006d70:	64a2                	ld	s1,8(sp)
    80006d72:	6105                	addi	sp,sp,32
    80006d74:	8082                	ret
    panic("could not find virtio disk");
    80006d76:	00003517          	auipc	a0,0x3
    80006d7a:	d2a50513          	addi	a0,a0,-726 # 80009aa0 <syscalls+0x388>
    80006d7e:	ffff9097          	auipc	ra,0xffff9
    80006d82:	7ac080e7          	jalr	1964(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006d86:	00003517          	auipc	a0,0x3
    80006d8a:	d3a50513          	addi	a0,a0,-710 # 80009ac0 <syscalls+0x3a8>
    80006d8e:	ffff9097          	auipc	ra,0xffff9
    80006d92:	79c080e7          	jalr	1948(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006d96:	00003517          	auipc	a0,0x3
    80006d9a:	d4a50513          	addi	a0,a0,-694 # 80009ae0 <syscalls+0x3c8>
    80006d9e:	ffff9097          	auipc	ra,0xffff9
    80006da2:	78c080e7          	jalr	1932(ra) # 8000052a <panic>

0000000080006da6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006da6:	7119                	addi	sp,sp,-128
    80006da8:	fc86                	sd	ra,120(sp)
    80006daa:	f8a2                	sd	s0,112(sp)
    80006dac:	f4a6                	sd	s1,104(sp)
    80006dae:	f0ca                	sd	s2,96(sp)
    80006db0:	ecce                	sd	s3,88(sp)
    80006db2:	e8d2                	sd	s4,80(sp)
    80006db4:	e4d6                	sd	s5,72(sp)
    80006db6:	e0da                	sd	s6,64(sp)
    80006db8:	fc5e                	sd	s7,56(sp)
    80006dba:	f862                	sd	s8,48(sp)
    80006dbc:	f466                	sd	s9,40(sp)
    80006dbe:	f06a                	sd	s10,32(sp)
    80006dc0:	ec6e                	sd	s11,24(sp)
    80006dc2:	0100                	addi	s0,sp,128
    80006dc4:	8aaa                	mv	s5,a0
    80006dc6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006dc8:	00c52c83          	lw	s9,12(a0)
    80006dcc:	001c9c9b          	slliw	s9,s9,0x1
    80006dd0:	1c82                	slli	s9,s9,0x20
    80006dd2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006dd6:	00027517          	auipc	a0,0x27
    80006dda:	35250513          	addi	a0,a0,850 # 8002e128 <disk+0x2128>
    80006dde:	ffffa097          	auipc	ra,0xffffa
    80006de2:	de4080e7          	jalr	-540(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006de6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006de8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006dea:	00025c17          	auipc	s8,0x25
    80006dee:	216c0c13          	addi	s8,s8,534 # 8002c000 <disk>
    80006df2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006df4:	4b0d                	li	s6,3
    80006df6:	a0ad                	j	80006e60 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006df8:	00fc0733          	add	a4,s8,a5
    80006dfc:	975e                	add	a4,a4,s7
    80006dfe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006e02:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006e04:	0207c563          	bltz	a5,80006e2e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006e08:	2905                	addiw	s2,s2,1
    80006e0a:	0611                	addi	a2,a2,4
    80006e0c:	19690d63          	beq	s2,s6,80006fa6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006e10:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006e12:	00027717          	auipc	a4,0x27
    80006e16:	20670713          	addi	a4,a4,518 # 8002e018 <disk+0x2018>
    80006e1a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006e1c:	00074683          	lbu	a3,0(a4)
    80006e20:	fee1                	bnez	a3,80006df8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006e22:	2785                	addiw	a5,a5,1
    80006e24:	0705                	addi	a4,a4,1
    80006e26:	fe979be3          	bne	a5,s1,80006e1c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006e2a:	57fd                	li	a5,-1
    80006e2c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006e2e:	01205d63          	blez	s2,80006e48 <virtio_disk_rw+0xa2>
    80006e32:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006e34:	000a2503          	lw	a0,0(s4)
    80006e38:	00000097          	auipc	ra,0x0
    80006e3c:	d8e080e7          	jalr	-626(ra) # 80006bc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006e40:	2d85                	addiw	s11,s11,1
    80006e42:	0a11                	addi	s4,s4,4
    80006e44:	ffb918e3          	bne	s2,s11,80006e34 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006e48:	00027597          	auipc	a1,0x27
    80006e4c:	2e058593          	addi	a1,a1,736 # 8002e128 <disk+0x2128>
    80006e50:	00027517          	auipc	a0,0x27
    80006e54:	1c850513          	addi	a0,a0,456 # 8002e018 <disk+0x2018>
    80006e58:	ffffb097          	auipc	ra,0xffffb
    80006e5c:	212080e7          	jalr	530(ra) # 8000206a <sleep>
  for(int i = 0; i < 3; i++){
    80006e60:	f8040a13          	addi	s4,s0,-128
{
    80006e64:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006e66:	894e                	mv	s2,s3
    80006e68:	b765                	j	80006e10 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006e6a:	00027697          	auipc	a3,0x27
    80006e6e:	1966b683          	ld	a3,406(a3) # 8002e000 <disk+0x2000>
    80006e72:	96ba                	add	a3,a3,a4
    80006e74:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006e78:	00025817          	auipc	a6,0x25
    80006e7c:	18880813          	addi	a6,a6,392 # 8002c000 <disk>
    80006e80:	00027697          	auipc	a3,0x27
    80006e84:	18068693          	addi	a3,a3,384 # 8002e000 <disk+0x2000>
    80006e88:	6290                	ld	a2,0(a3)
    80006e8a:	963a                	add	a2,a2,a4
    80006e8c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006e90:	0015e593          	ori	a1,a1,1
    80006e94:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006e98:	f8842603          	lw	a2,-120(s0)
    80006e9c:	628c                	ld	a1,0(a3)
    80006e9e:	972e                	add	a4,a4,a1
    80006ea0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006ea4:	20050593          	addi	a1,a0,512
    80006ea8:	0592                	slli	a1,a1,0x4
    80006eaa:	95c2                	add	a1,a1,a6
    80006eac:	577d                	li	a4,-1
    80006eae:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006eb2:	00461713          	slli	a4,a2,0x4
    80006eb6:	6290                	ld	a2,0(a3)
    80006eb8:	963a                	add	a2,a2,a4
    80006eba:	03078793          	addi	a5,a5,48
    80006ebe:	97c2                	add	a5,a5,a6
    80006ec0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006ec2:	629c                	ld	a5,0(a3)
    80006ec4:	97ba                	add	a5,a5,a4
    80006ec6:	4605                	li	a2,1
    80006ec8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006eca:	629c                	ld	a5,0(a3)
    80006ecc:	97ba                	add	a5,a5,a4
    80006ece:	4809                	li	a6,2
    80006ed0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006ed4:	629c                	ld	a5,0(a3)
    80006ed6:	973e                	add	a4,a4,a5
    80006ed8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006edc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006ee0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ee4:	6698                	ld	a4,8(a3)
    80006ee6:	00275783          	lhu	a5,2(a4)
    80006eea:	8b9d                	andi	a5,a5,7
    80006eec:	0786                	slli	a5,a5,0x1
    80006eee:	97ba                	add	a5,a5,a4
    80006ef0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006ef4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006ef8:	6698                	ld	a4,8(a3)
    80006efa:	00275783          	lhu	a5,2(a4)
    80006efe:	2785                	addiw	a5,a5,1
    80006f00:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006f04:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006f08:	100017b7          	lui	a5,0x10001
    80006f0c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006f10:	004aa783          	lw	a5,4(s5)
    80006f14:	02c79163          	bne	a5,a2,80006f36 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006f18:	00027917          	auipc	s2,0x27
    80006f1c:	21090913          	addi	s2,s2,528 # 8002e128 <disk+0x2128>
  while(b->disk == 1) {
    80006f20:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006f22:	85ca                	mv	a1,s2
    80006f24:	8556                	mv	a0,s5
    80006f26:	ffffb097          	auipc	ra,0xffffb
    80006f2a:	144080e7          	jalr	324(ra) # 8000206a <sleep>
  while(b->disk == 1) {
    80006f2e:	004aa783          	lw	a5,4(s5)
    80006f32:	fe9788e3          	beq	a5,s1,80006f22 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006f36:	f8042903          	lw	s2,-128(s0)
    80006f3a:	20090793          	addi	a5,s2,512
    80006f3e:	00479713          	slli	a4,a5,0x4
    80006f42:	00025797          	auipc	a5,0x25
    80006f46:	0be78793          	addi	a5,a5,190 # 8002c000 <disk>
    80006f4a:	97ba                	add	a5,a5,a4
    80006f4c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006f50:	00027997          	auipc	s3,0x27
    80006f54:	0b098993          	addi	s3,s3,176 # 8002e000 <disk+0x2000>
    80006f58:	00491713          	slli	a4,s2,0x4
    80006f5c:	0009b783          	ld	a5,0(s3)
    80006f60:	97ba                	add	a5,a5,a4
    80006f62:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006f66:	854a                	mv	a0,s2
    80006f68:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006f6c:	00000097          	auipc	ra,0x0
    80006f70:	c5a080e7          	jalr	-934(ra) # 80006bc6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006f74:	8885                	andi	s1,s1,1
    80006f76:	f0ed                	bnez	s1,80006f58 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006f78:	00027517          	auipc	a0,0x27
    80006f7c:	1b050513          	addi	a0,a0,432 # 8002e128 <disk+0x2128>
    80006f80:	ffffa097          	auipc	ra,0xffffa
    80006f84:	cf6080e7          	jalr	-778(ra) # 80000c76 <release>
}
    80006f88:	70e6                	ld	ra,120(sp)
    80006f8a:	7446                	ld	s0,112(sp)
    80006f8c:	74a6                	ld	s1,104(sp)
    80006f8e:	7906                	ld	s2,96(sp)
    80006f90:	69e6                	ld	s3,88(sp)
    80006f92:	6a46                	ld	s4,80(sp)
    80006f94:	6aa6                	ld	s5,72(sp)
    80006f96:	6b06                	ld	s6,64(sp)
    80006f98:	7be2                	ld	s7,56(sp)
    80006f9a:	7c42                	ld	s8,48(sp)
    80006f9c:	7ca2                	ld	s9,40(sp)
    80006f9e:	7d02                	ld	s10,32(sp)
    80006fa0:	6de2                	ld	s11,24(sp)
    80006fa2:	6109                	addi	sp,sp,128
    80006fa4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006fa6:	f8042503          	lw	a0,-128(s0)
    80006faa:	20050793          	addi	a5,a0,512
    80006fae:	0792                	slli	a5,a5,0x4
  if(write)
    80006fb0:	00025817          	auipc	a6,0x25
    80006fb4:	05080813          	addi	a6,a6,80 # 8002c000 <disk>
    80006fb8:	00f80733          	add	a4,a6,a5
    80006fbc:	01a036b3          	snez	a3,s10
    80006fc0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006fc4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006fc8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fcc:	7679                	lui	a2,0xffffe
    80006fce:	963e                	add	a2,a2,a5
    80006fd0:	00027697          	auipc	a3,0x27
    80006fd4:	03068693          	addi	a3,a3,48 # 8002e000 <disk+0x2000>
    80006fd8:	6298                	ld	a4,0(a3)
    80006fda:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006fdc:	0a878593          	addi	a1,a5,168
    80006fe0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fe2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006fe4:	6298                	ld	a4,0(a3)
    80006fe6:	9732                	add	a4,a4,a2
    80006fe8:	45c1                	li	a1,16
    80006fea:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006fec:	6298                	ld	a4,0(a3)
    80006fee:	9732                	add	a4,a4,a2
    80006ff0:	4585                	li	a1,1
    80006ff2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006ff6:	f8442703          	lw	a4,-124(s0)
    80006ffa:	628c                	ld	a1,0(a3)
    80006ffc:	962e                	add	a2,a2,a1
    80006ffe:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcf00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80007002:	0712                	slli	a4,a4,0x4
    80007004:	6290                	ld	a2,0(a3)
    80007006:	963a                	add	a2,a2,a4
    80007008:	058a8593          	addi	a1,s5,88
    8000700c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000700e:	6294                	ld	a3,0(a3)
    80007010:	96ba                	add	a3,a3,a4
    80007012:	40000613          	li	a2,1024
    80007016:	c690                	sw	a2,8(a3)
  if(write)
    80007018:	e40d19e3          	bnez	s10,80006e6a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000701c:	00027697          	auipc	a3,0x27
    80007020:	fe46b683          	ld	a3,-28(a3) # 8002e000 <disk+0x2000>
    80007024:	96ba                	add	a3,a3,a4
    80007026:	4609                	li	a2,2
    80007028:	00c69623          	sh	a2,12(a3)
    8000702c:	b5b1                	j	80006e78 <virtio_disk_rw+0xd2>

000000008000702e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000702e:	1101                	addi	sp,sp,-32
    80007030:	ec06                	sd	ra,24(sp)
    80007032:	e822                	sd	s0,16(sp)
    80007034:	e426                	sd	s1,8(sp)
    80007036:	e04a                	sd	s2,0(sp)
    80007038:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000703a:	00027517          	auipc	a0,0x27
    8000703e:	0ee50513          	addi	a0,a0,238 # 8002e128 <disk+0x2128>
    80007042:	ffffa097          	auipc	ra,0xffffa
    80007046:	b80080e7          	jalr	-1152(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000704a:	10001737          	lui	a4,0x10001
    8000704e:	533c                	lw	a5,96(a4)
    80007050:	8b8d                	andi	a5,a5,3
    80007052:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007054:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007058:	00027797          	auipc	a5,0x27
    8000705c:	fa878793          	addi	a5,a5,-88 # 8002e000 <disk+0x2000>
    80007060:	6b94                	ld	a3,16(a5)
    80007062:	0207d703          	lhu	a4,32(a5)
    80007066:	0026d783          	lhu	a5,2(a3)
    8000706a:	06f70163          	beq	a4,a5,800070cc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000706e:	00025917          	auipc	s2,0x25
    80007072:	f9290913          	addi	s2,s2,-110 # 8002c000 <disk>
    80007076:	00027497          	auipc	s1,0x27
    8000707a:	f8a48493          	addi	s1,s1,-118 # 8002e000 <disk+0x2000>
    __sync_synchronize();
    8000707e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007082:	6898                	ld	a4,16(s1)
    80007084:	0204d783          	lhu	a5,32(s1)
    80007088:	8b9d                	andi	a5,a5,7
    8000708a:	078e                	slli	a5,a5,0x3
    8000708c:	97ba                	add	a5,a5,a4
    8000708e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007090:	20078713          	addi	a4,a5,512
    80007094:	0712                	slli	a4,a4,0x4
    80007096:	974a                	add	a4,a4,s2
    80007098:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000709c:	e731                	bnez	a4,800070e8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000709e:	20078793          	addi	a5,a5,512
    800070a2:	0792                	slli	a5,a5,0x4
    800070a4:	97ca                	add	a5,a5,s2
    800070a6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800070a8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800070ac:	ffffb097          	auipc	ra,0xffffb
    800070b0:	022080e7          	jalr	34(ra) # 800020ce <wakeup>

    disk.used_idx += 1;
    800070b4:	0204d783          	lhu	a5,32(s1)
    800070b8:	2785                	addiw	a5,a5,1
    800070ba:	17c2                	slli	a5,a5,0x30
    800070bc:	93c1                	srli	a5,a5,0x30
    800070be:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800070c2:	6898                	ld	a4,16(s1)
    800070c4:	00275703          	lhu	a4,2(a4)
    800070c8:	faf71be3          	bne	a4,a5,8000707e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800070cc:	00027517          	auipc	a0,0x27
    800070d0:	05c50513          	addi	a0,a0,92 # 8002e128 <disk+0x2128>
    800070d4:	ffffa097          	auipc	ra,0xffffa
    800070d8:	ba2080e7          	jalr	-1118(ra) # 80000c76 <release>
}
    800070dc:	60e2                	ld	ra,24(sp)
    800070de:	6442                	ld	s0,16(sp)
    800070e0:	64a2                	ld	s1,8(sp)
    800070e2:	6902                	ld	s2,0(sp)
    800070e4:	6105                	addi	sp,sp,32
    800070e6:	8082                	ret
      panic("virtio_disk_intr status");
    800070e8:	00003517          	auipc	a0,0x3
    800070ec:	a1850513          	addi	a0,a0,-1512 # 80009b00 <syscalls+0x3e8>
    800070f0:	ffff9097          	auipc	ra,0xffff9
    800070f4:	43a080e7          	jalr	1082(ra) # 8000052a <panic>
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
