
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
    80000068:	a1c78793          	addi	a5,a5,-1508 # 80006a80 <timervec>
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
    800002e2:	ea8080e7          	jalr	-344(ra) # 80002186 <procdump>
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
    8000055c:	b9050513          	addi	a0,a0,-1136 # 800090e8 <digits+0xa8>
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
    8000090e:	62a080e7          	jalr	1578(ra) # 80001f34 <sleep>
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
    80000a06:	2ce080e7          	jalr	718(ra) # 80000cd0 <memset>

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
    80000c08:	00008517          	auipc	a0,0x8
    80000c0c:	46850513          	addi	a0,a0,1128 # 80009070 <digits+0x30>
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	964080e7          	jalr	-1692(ra) # 80000574 <printf>
    panic("acquire");
    80000c18:	00008517          	auipc	a0,0x8
    80000c1c:	47850513          	addi	a0,a0,1144 # 80009090 <digits+0x50>
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
    80000c68:	00008517          	auipc	a0,0x8
    80000c6c:	43050513          	addi	a0,a0,1072 # 80009098 <digits+0x58>
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	8ba080e7          	jalr	-1862(ra) # 8000052a <panic>
    panic("pop_off");
    80000c78:	00008517          	auipc	a0,0x8
    80000c7c:	43850513          	addi	a0,a0,1080 # 800090b0 <digits+0x70>
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
    80000cc0:	00008517          	auipc	a0,0x8
    80000cc4:	3f850513          	addi	a0,a0,1016 # 800090b8 <digits+0x78>
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
    80000e8e:	00009717          	auipc	a4,0x9
    80000e92:	18a70713          	addi	a4,a4,394 # 8000a018 <started>
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
    80000eac:	00008517          	auipc	a0,0x8
    80000eb0:	22c50513          	addi	a0,a0,556 # 800090d8 <digits+0x98>
    80000eb4:	fffff097          	auipc	ra,0xfffff
    80000eb8:	6c0080e7          	jalr	1728(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000ebc:	00000097          	auipc	ra,0x0
    80000ec0:	0d8080e7          	jalr	216(ra) # 80000f94 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ec4:	00002097          	auipc	ra,0x2
    80000ec8:	060080e7          	jalr	96(ra) # 80002f24 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ecc:	00006097          	auipc	ra,0x6
    80000ed0:	bf4080e7          	jalr	-1036(ra) # 80006ac0 <plicinithart>
  }

  scheduler();        
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	f14080e7          	jalr	-236(ra) # 80002de8 <scheduler>
    consoleinit();
    80000edc:	fffff097          	auipc	ra,0xfffff
    80000ee0:	560080e7          	jalr	1376(ra) # 8000043c <consoleinit>
    printfinit();
    80000ee4:	00000097          	auipc	ra,0x0
    80000ee8:	870080e7          	jalr	-1936(ra) # 80000754 <printfinit>
    printf("\n");
    80000eec:	00008517          	auipc	a0,0x8
    80000ef0:	1fc50513          	addi	a0,a0,508 # 800090e8 <digits+0xa8>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	680080e7          	jalr	1664(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000efc:	00008517          	auipc	a0,0x8
    80000f00:	1c450513          	addi	a0,a0,452 # 800090c0 <digits+0x80>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	670080e7          	jalr	1648(ra) # 80000574 <printf>
    printf("\n");
    80000f0c:	00008517          	auipc	a0,0x8
    80000f10:	1dc50513          	addi	a0,a0,476 # 800090e8 <digits+0xa8>
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
    80000f40:	fc0080e7          	jalr	-64(ra) # 80002efc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f44:	00002097          	auipc	ra,0x2
    80000f48:	fe0080e7          	jalr	-32(ra) # 80002f24 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4c:	00006097          	auipc	ra,0x6
    80000f50:	b5e080e7          	jalr	-1186(ra) # 80006aaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f54:	00006097          	auipc	ra,0x6
    80000f58:	b6c080e7          	jalr	-1172(ra) # 80006ac0 <plicinithart>
    binit();         // buffer cache
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	73e080e7          	jalr	1854(ra) # 8000369a <binit>
    iinit();         // inode cache
    80000f64:	00003097          	auipc	ra,0x3
    80000f68:	dd0080e7          	jalr	-560(ra) # 80003d34 <iinit>
    fileinit();      // file table
    80000f6c:	00004097          	auipc	ra,0x4
    80000f70:	090080e7          	jalr	144(ra) # 80004ffc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f74:	00006097          	auipc	ra,0x6
    80000f78:	c6e080e7          	jalr	-914(ra) # 80006be2 <virtio_disk_init>
    userinit();      // first user process
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	d42080e7          	jalr	-702(ra) # 80001cbe <userinit>
    __sync_synchronize();
    80000f84:	0ff0000f          	fence
    started = 1;
    80000f88:	4785                	li	a5,1
    80000f8a:	00009717          	auipc	a4,0x9
    80000f8e:	08f72723          	sw	a5,142(a4) # 8000a018 <started>
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
    80000f9a:	00009797          	auipc	a5,0x9
    80000f9e:	0867b783          	ld	a5,134(a5) # 8000a020 <kernel_pagetable>
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
    80000fde:	00008517          	auipc	a0,0x8
    80000fe2:	11250513          	addi	a0,a0,274 # 800090f0 <digits+0xb0>
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
    800010da:	00008517          	auipc	a0,0x8
    800010de:	01e50513          	addi	a0,a0,30 # 800090f8 <digits+0xb8>
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
    8000115e:	00008517          	auipc	a0,0x8
    80001162:	fa250513          	addi	a0,a0,-94 # 80009100 <digits+0xc0>
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
    800011d4:	00008917          	auipc	s2,0x8
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80009000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80008697          	auipc	a3,0x80008
    800011e2:	e2268693          	addi	a3,a3,-478 # 9000 <_entry-0x7fff7000>
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
    80001212:	00007617          	auipc	a2,0x7
    80001216:	dee60613          	addi	a2,a2,-530 # 80008000 <_trampoline>
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
    80001254:	00009797          	auipc	a5,0x9
    80001258:	dca7b623          	sd	a0,-564(a5) # 8000a020 <kernel_pagetable>
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
    800012aa:	00008517          	auipc	a0,0x8
    800012ae:	e5e50513          	addi	a0,a0,-418 # 80009108 <digits+0xc8>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	278080e7          	jalr	632(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012ba:	00008517          	auipc	a0,0x8
    800012be:	e6650513          	addi	a0,a0,-410 # 80009120 <digits+0xe0>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	268080e7          	jalr	616(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00008517          	auipc	a0,0x8
    800012ce:	e6650513          	addi	a0,a0,-410 # 80009130 <digits+0xf0>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	258080e7          	jalr	600(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00008517          	auipc	a0,0x8
    800012de:	e6e50513          	addi	a0,a0,-402 # 80009148 <digits+0x108>
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
    800013c0:	00008517          	auipc	a0,0x8
    800013c4:	da050513          	addi	a0,a0,-608 # 80009160 <digits+0x120>
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
    8000143a:	626080e7          	jalr	1574(ra) # 80002a5c <remove_page_from_ram>
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
    800014a4:	65a080e7          	jalr	1626(ra) # 80002afa <insert_page_to_ram>
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
    8000153a:	00008517          	auipc	a0,0x8
    8000153e:	c4650513          	addi	a0,a0,-954 # 80009180 <digits+0x140>
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
    800015c0:	00008517          	auipc	a0,0x8
    800015c4:	bd050513          	addi	a0,a0,-1072 # 80009190 <digits+0x150>
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	f62080e7          	jalr	-158(ra) # 8000052a <panic>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
      panic("uvmcopy: page not present");
    800015d0:	00008517          	auipc	a0,0x8
    800015d4:	be050513          	addi	a0,a0,-1056 # 800091b0 <digits+0x170>
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
    80001696:	00008517          	auipc	a0,0x8
    8000169a:	b3a50513          	addi	a0,a0,-1222 # 800091d0 <digits+0x190>
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
    80001848:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd0000>
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
    8000188a:	00011497          	auipc	s1,0x11
    8000188e:	e4648493          	addi	s1,s1,-442 # 800126d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001892:	8b26                	mv	s6,s1
    80001894:	00007a97          	auipc	s5,0x7
    80001898:	76ca8a93          	addi	s5,s5,1900 # 80009000 <etext>
    8000189c:	04000937          	lui	s2,0x4000
    800018a0:	197d                	addi	s2,s2,-1
    800018a2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a4:	0001fa17          	auipc	s4,0x1f
    800018a8:	c2ca0a13          	addi	s4,s4,-980 # 800204d0 <tickslock>
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
    800018fa:	00008517          	auipc	a0,0x8
    800018fe:	8e650513          	addi	a0,a0,-1818 # 800091e0 <digits+0x1a0>
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
    8000191e:	00008597          	auipc	a1,0x8
    80001922:	8ca58593          	addi	a1,a1,-1846 # 800091e8 <digits+0x1a8>
    80001926:	00011517          	auipc	a0,0x11
    8000192a:	97a50513          	addi	a0,a0,-1670 # 800122a0 <pid_lock>
    8000192e:	fffff097          	auipc	ra,0xfffff
    80001932:	204080e7          	jalr	516(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001936:	00008597          	auipc	a1,0x8
    8000193a:	8ba58593          	addi	a1,a1,-1862 # 800091f0 <digits+0x1b0>
    8000193e:	00011517          	auipc	a0,0x11
    80001942:	97a50513          	addi	a0,a0,-1670 # 800122b8 <wait_lock>
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	1ec080e7          	jalr	492(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	00011497          	auipc	s1,0x11
    80001952:	d8248493          	addi	s1,s1,-638 # 800126d0 <proc>
      initlock(&p->lock, "proc");
    80001956:	00008b17          	auipc	s6,0x8
    8000195a:	8aab0b13          	addi	s6,s6,-1878 # 80009200 <digits+0x1c0>
      p->kstack = KSTACK((int) (p - proc));
    8000195e:	8aa6                	mv	s5,s1
    80001960:	00007a17          	auipc	s4,0x7
    80001964:	6a0a0a13          	addi	s4,s4,1696 # 80009000 <etext>
    80001968:	04000937          	lui	s2,0x4000
    8000196c:	197d                	addi	s2,s2,-1
    8000196e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	0001f997          	auipc	s3,0x1f
    80001974:	b6098993          	addi	s3,s3,-1184 # 800204d0 <tickslock>
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
    800019d6:	00011517          	auipc	a0,0x11
    800019da:	8fa50513          	addi	a0,a0,-1798 # 800122d0 <cpus>
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
    800019fe:	00011717          	auipc	a4,0x11
    80001a02:	8a270713          	addi	a4,a4,-1886 # 800122a0 <pid_lock>
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
    80001a36:	00008797          	auipc	a5,0x8
    80001a3a:	0da7a783          	lw	a5,218(a5) # 80009b10 <first.1>
    80001a3e:	eb89                	bnez	a5,80001a50 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a40:	00001097          	auipc	ra,0x1
    80001a44:	4fc080e7          	jalr	1276(ra) # 80002f3c <usertrapret>
}
    80001a48:	60a2                	ld	ra,8(sp)
    80001a4a:	6402                	ld	s0,0(sp)
    80001a4c:	0141                	addi	sp,sp,16
    80001a4e:	8082                	ret
    first = 0;
    80001a50:	00008797          	auipc	a5,0x8
    80001a54:	0c07a023          	sw	zero,192(a5) # 80009b10 <first.1>
    fsinit(ROOTDEV);
    80001a58:	4505                	li	a0,1
    80001a5a:	00002097          	auipc	ra,0x2
    80001a5e:	25a080e7          	jalr	602(ra) # 80003cb4 <fsinit>
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
    80001a70:	00011917          	auipc	s2,0x11
    80001a74:	83090913          	addi	s2,s2,-2000 # 800122a0 <pid_lock>
    80001a78:	854a                	mv	a0,s2
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	148080e7          	jalr	328(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a82:	00008797          	auipc	a5,0x8
    80001a86:	09278793          	addi	a5,a5,146 # 80009b14 <nextpid>
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
    80001ac6:	00006697          	auipc	a3,0x6
    80001aca:	53a68693          	addi	a3,a3,1338 # 80008000 <_trampoline>
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
    80001bfc:	00011497          	auipc	s1,0x11
    80001c00:	ad448493          	addi	s1,s1,-1324 # 800126d0 <proc>
    80001c04:	0001f917          	auipc	s2,0x1f
    80001c08:	8cc90913          	addi	s2,s2,-1844 # 800204d0 <tickslock>
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
    80001cd2:	00008797          	auipc	a5,0x8
    80001cd6:	34a7bb23          	sd	a0,854(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cda:	03400613          	li	a2,52
    80001cde:	00008597          	auipc	a1,0x8
    80001ce2:	e4258593          	addi	a1,a1,-446 # 80009b20 <initcode>
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
    80001d00:	00007597          	auipc	a1,0x7
    80001d04:	50858593          	addi	a1,a1,1288 # 80009208 <digits+0x1c8>
    80001d08:	15848513          	addi	a0,s1,344
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	116080e7          	jalr	278(ra) # 80000e22 <safestrcpy>
  p->cwd = namei("/");
    80001d14:	00007517          	auipc	a0,0x7
    80001d18:	50450513          	addi	a0,a0,1284 # 80009218 <digits+0x1d8>
    80001d1c:	00003097          	auipc	ra,0x3
    80001d20:	9c6080e7          	jalr	-1594(ra) # 800046e2 <namei>
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
    80001de2:	c2c080e7          	jalr	-980(ra) # 80004a0a <readFromSwapFile>
    80001de6:	02054c63          	bltz	a0,80001e1e <copy_swapFile+0x6a>
    if(writeToSwapFile(dst, buffer, 0, total_size) < 0) {
    80001dea:	66c1                	lui	a3,0x10
    80001dec:	4601                	li	a2,0
    80001dee:	85ca                	mv	a1,s2
    80001df0:	8526                	mv	a0,s1
    80001df2:	00003097          	auipc	ra,0x3
    80001df6:	bf4080e7          	jalr	-1036(ra) # 800049e6 <writeToSwapFile>
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
    80001e4a:	00010717          	auipc	a4,0x10
    80001e4e:	45670713          	addi	a4,a4,1110 # 800122a0 <pid_lock>
    80001e52:	97ba                	add	a5,a5,a4
    80001e54:	0a87a703          	lw	a4,168(a5) # ffffffffffff00a8 <end+0xffffffff7ffc10a8>
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
    80001e70:	00010917          	auipc	s2,0x10
    80001e74:	43090913          	addi	s2,s2,1072 # 800122a0 <pid_lock>
    80001e78:	2781                	sext.w	a5,a5
    80001e7a:	079e                	slli	a5,a5,0x7
    80001e7c:	97ca                	add	a5,a5,s2
    80001e7e:	0ac7a983          	lw	s3,172(a5)
    80001e82:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e84:	2781                	sext.w	a5,a5
    80001e86:	079e                	slli	a5,a5,0x7
    80001e88:	00010597          	auipc	a1,0x10
    80001e8c:	45058593          	addi	a1,a1,1104 # 800122d8 <cpus+0x8>
    80001e90:	95be                	add	a1,a1,a5
    80001e92:	06048513          	addi	a0,s1,96
    80001e96:	00001097          	auipc	ra,0x1
    80001e9a:	ffc080e7          	jalr	-4(ra) # 80002e92 <swtch>
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
    80001eb8:	00007517          	auipc	a0,0x7
    80001ebc:	36850513          	addi	a0,a0,872 # 80009220 <digits+0x1e0>
    80001ec0:	ffffe097          	auipc	ra,0xffffe
    80001ec4:	66a080e7          	jalr	1642(ra) # 8000052a <panic>
    panic("sched locks");
    80001ec8:	00007517          	auipc	a0,0x7
    80001ecc:	36850513          	addi	a0,a0,872 # 80009230 <digits+0x1f0>
    80001ed0:	ffffe097          	auipc	ra,0xffffe
    80001ed4:	65a080e7          	jalr	1626(ra) # 8000052a <panic>
    panic("sched running");
    80001ed8:	00007517          	auipc	a0,0x7
    80001edc:	36850513          	addi	a0,a0,872 # 80009240 <digits+0x200>
    80001ee0:	ffffe097          	auipc	ra,0xffffe
    80001ee4:	64a080e7          	jalr	1610(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001ee8:	00007517          	auipc	a0,0x7
    80001eec:	36850513          	addi	a0,a0,872 # 80009250 <digits+0x210>
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
    80001fac:	00010497          	auipc	s1,0x10
    80001fb0:	72448493          	addi	s1,s1,1828 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001fb4:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001fb6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fb8:	0001e917          	auipc	s2,0x1e
    80001fbc:	51890913          	addi	s2,s2,1304 # 800204d0 <tickslock>
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
    80002020:	00010497          	auipc	s1,0x10
    80002024:	6b048493          	addi	s1,s1,1712 # 800126d0 <proc>
      pp->parent = initproc;
    80002028:	00008a17          	auipc	s4,0x8
    8000202c:	000a0a13          	mv	s4,s4
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002030:	0001e997          	auipc	s3,0x1e
    80002034:	4a098993          	addi	s3,s3,1184 # 800204d0 <tickslock>
    80002038:	a029                	j	80002042 <reparent+0x34>
    8000203a:	37848493          	addi	s1,s1,888
    8000203e:	01348d63          	beq	s1,s3,80002058 <reparent+0x4a>
    if(pp->parent == p){
    80002042:	7c9c                	ld	a5,56(s1)
    80002044:	ff279be3          	bne	a5,s2,8000203a <reparent+0x2c>
      pp->parent = initproc;
    80002048:	000a3503          	ld	a0,0(s4) # 8000a028 <initproc>
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
    80002078:	00010497          	auipc	s1,0x10
    8000207c:	65848493          	addi	s1,s1,1624 # 800126d0 <proc>
    80002080:	0001e997          	auipc	s3,0x1e
    80002084:	45098993          	addi	s3,s3,1104 # 800204d0 <tickslock>
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
    8000219c:	00007517          	auipc	a0,0x7
    800021a0:	f4c50513          	addi	a0,a0,-180 # 800090e8 <digits+0xa8>
    800021a4:	ffffe097          	auipc	ra,0xffffe
    800021a8:	3d0080e7          	jalr	976(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800021ac:	00010497          	auipc	s1,0x10
    800021b0:	67c48493          	addi	s1,s1,1660 # 80012828 <proc+0x158>
    800021b4:	0001e917          	auipc	s2,0x1e
    800021b8:	47490913          	addi	s2,s2,1140 # 80020628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800021bc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800021be:	00007997          	auipc	s3,0x7
    800021c2:	0aa98993          	addi	s3,s3,170 # 80009268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800021c6:	00007a97          	auipc	s5,0x7
    800021ca:	0aaa8a93          	addi	s5,s5,170 # 80009270 <digits+0x230>
    printf("\n");
    800021ce:	00007a17          	auipc	s4,0x7
    800021d2:	f1aa0a13          	addi	s4,s4,-230 # 800090e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800021d6:	00007b97          	auipc	s7,0x7
    800021da:	3b2b8b93          	addi	s7,s7,946 # 80009588 <states.0>
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

// ADDED Q1 - p->lock must bot be held because of createSwapFile!
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
    80002286:	6b4080e7          	jalr	1716(ra) # 80004936 <createSwapFile>
    8000228a:	fa055fe3          	bgez	a0,80002248 <init_metadata+0x12>
    return -1;
    8000228e:	557d                	li	a0,-1
    80002290:	b7e5                	j	80002278 <init_metadata+0x42>

0000000080002292 <free_metadata>:

// p->lock must not be held because of removeSwapFile!
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
    800022a2:	4f0080e7          	jalr	1264(ra) # 8000478e <removeSwapFile>
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
    800022de:	00007517          	auipc	a0,0x7
    800022e2:	fa250513          	addi	a0,a0,-94 # 80009280 <digits+0x240>
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
    80002312:	1c050663          	beqz	a0,800024de <fork+0x1f0>
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
    800023a2:	cf0080e7          	jalr	-784(ra) # 8000508e <filedup>
    800023a6:	00a93023          	sd	a0,0(s2)
    800023aa:	b7e5                	j	80002392 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800023ac:	150ab503          	ld	a0,336(s5)
    800023b0:	00002097          	auipc	ra,0x2
    800023b4:	b3e080e7          	jalr	-1218(ra) # 80003eee <idup>
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
    800023f4:	0c054463          	bltz	a0,800024bc <fork+0x1ce>
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
    np->scfifo_index = p->scfifo_index; // ADDED Q2
    80002420:	370aa783          	lw	a5,880(s5)
    80002424:	36f9a823          	sw	a5,880(s3)
  release(&np->lock);
    80002428:	854e                	mv	a0,s3
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	85e080e7          	jalr	-1954(ra) # 80000c88 <release>
  acquire(&wait_lock);
    80002432:	00010917          	auipc	s2,0x10
    80002436:	e8690913          	addi	s2,s2,-378 # 800122b8 <wait_lock>
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
    release(&np->lock);
    80002480:	854e                	mv	a0,s3
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	806080e7          	jalr	-2042(ra) # 80000c88 <release>
    if (init_metadata(np) < 0) {
    8000248a:	854e                	mv	a0,s3
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	daa080e7          	jalr	-598(ra) # 80002236 <init_metadata>
    80002494:	00054863          	bltz	a0,800024a4 <fork+0x1b6>
    acquire(&np->lock);
    80002498:	854e                	mv	a0,s3
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	728080e7          	jalr	1832(ra) # 80000bc2 <acquire>
    800024a2:	bf2d                	j	800023dc <fork+0xee>
      freeproc(np);
    800024a4:	854e                	mv	a0,s3
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	6f2080e7          	jalr	1778(ra) # 80001b98 <freeproc>
      release(&np->lock);
    800024ae:	854e                	mv	a0,s3
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7d8080e7          	jalr	2008(ra) # 80000c88 <release>
      return -1;
    800024b8:	54fd                	li	s1,-1
    800024ba:	bf4d                	j	8000246c <fork+0x17e>
      freeproc(np);
    800024bc:	854e                	mv	a0,s3
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	6da080e7          	jalr	1754(ra) # 80001b98 <freeproc>
      release(&np->lock);
    800024c6:	854e                	mv	a0,s3
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7c0080e7          	jalr	1984(ra) # 80000c88 <release>
      free_metadata(np);
    800024d0:	854e                	mv	a0,s3
    800024d2:	00000097          	auipc	ra,0x0
    800024d6:	dc0080e7          	jalr	-576(ra) # 80002292 <free_metadata>
      return -1;
    800024da:	54fd                	li	s1,-1
    800024dc:	bf41                	j	8000246c <fork+0x17e>
    return -1;
    800024de:	54fd                	li	s1,-1
    800024e0:	b771                	j	8000246c <fork+0x17e>

00000000800024e2 <exit>:
{
    800024e2:	7179                	addi	sp,sp,-48
    800024e4:	f406                	sd	ra,40(sp)
    800024e6:	f022                	sd	s0,32(sp)
    800024e8:	ec26                	sd	s1,24(sp)
    800024ea:	e84a                	sd	s2,16(sp)
    800024ec:	e44e                	sd	s3,8(sp)
    800024ee:	e052                	sd	s4,0(sp)
    800024f0:	1800                	addi	s0,sp,48
    800024f2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	4f2080e7          	jalr	1266(ra) # 800019e6 <myproc>
    800024fc:	89aa                	mv	s3,a0
  if(p == initproc)
    800024fe:	00008797          	auipc	a5,0x8
    80002502:	b2a7b783          	ld	a5,-1238(a5) # 8000a028 <initproc>
    80002506:	0d050493          	addi	s1,a0,208
    8000250a:	15050913          	addi	s2,a0,336
    8000250e:	02a79363          	bne	a5,a0,80002534 <exit+0x52>
    panic("init exiting");
    80002512:	00007517          	auipc	a0,0x7
    80002516:	d9650513          	addi	a0,a0,-618 # 800092a8 <digits+0x268>
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	010080e7          	jalr	16(ra) # 8000052a <panic>
      fileclose(f);
    80002522:	00003097          	auipc	ra,0x3
    80002526:	bbe080e7          	jalr	-1090(ra) # 800050e0 <fileclose>
      p->ofile[fd] = 0;
    8000252a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000252e:	04a1                	addi	s1,s1,8
    80002530:	01248563          	beq	s1,s2,8000253a <exit+0x58>
    if(p->ofile[fd]){
    80002534:	6088                	ld	a0,0(s1)
    80002536:	f575                	bnez	a0,80002522 <exit+0x40>
    80002538:	bfdd                	j	8000252e <exit+0x4c>
  if (p->pid != INIT_PID && p->pid != SHELL_PID) {
    8000253a:	0309a783          	lw	a5,48(s3)
    8000253e:	37fd                	addiw	a5,a5,-1
    80002540:	4705                	li	a4,1
    80002542:	08f76163          	bltu	a4,a5,800025c4 <exit+0xe2>
  begin_op();
    80002546:	00002097          	auipc	ra,0x2
    8000254a:	6ce080e7          	jalr	1742(ra) # 80004c14 <begin_op>
  iput(p->cwd);
    8000254e:	1509b503          	ld	a0,336(s3)
    80002552:	00002097          	auipc	ra,0x2
    80002556:	b94080e7          	jalr	-1132(ra) # 800040e6 <iput>
  end_op();
    8000255a:	00002097          	auipc	ra,0x2
    8000255e:	73a080e7          	jalr	1850(ra) # 80004c94 <end_op>
  p->cwd = 0;
    80002562:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002566:	00010497          	auipc	s1,0x10
    8000256a:	d5248493          	addi	s1,s1,-686 # 800122b8 <wait_lock>
    8000256e:	8526                	mv	a0,s1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	652080e7          	jalr	1618(ra) # 80000bc2 <acquire>
  reparent(p);
    80002578:	854e                	mv	a0,s3
    8000257a:	00000097          	auipc	ra,0x0
    8000257e:	a94080e7          	jalr	-1388(ra) # 8000200e <reparent>
  wakeup(p->parent);
    80002582:	0389b503          	ld	a0,56(s3)
    80002586:	00000097          	auipc	ra,0x0
    8000258a:	a12080e7          	jalr	-1518(ra) # 80001f98 <wakeup>
  acquire(&p->lock);
    8000258e:	854e                	mv	a0,s3
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	632080e7          	jalr	1586(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002598:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000259c:	4795                	li	a5,5
    8000259e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6e4080e7          	jalr	1764(ra) # 80000c88 <release>
  sched();
    800025ac:	00000097          	auipc	ra,0x0
    800025b0:	876080e7          	jalr	-1930(ra) # 80001e22 <sched>
  panic("zombie exit");
    800025b4:	00007517          	auipc	a0,0x7
    800025b8:	d0450513          	addi	a0,a0,-764 # 800092b8 <digits+0x278>
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
    free_metadata(p);
    800025c4:	854e                	mv	a0,s3
    800025c6:	00000097          	auipc	ra,0x0
    800025ca:	ccc080e7          	jalr	-820(ra) # 80002292 <free_metadata>
    800025ce:	bfa5                	j	80002546 <exit+0x64>

00000000800025d0 <wait>:
{
    800025d0:	715d                	addi	sp,sp,-80
    800025d2:	e486                	sd	ra,72(sp)
    800025d4:	e0a2                	sd	s0,64(sp)
    800025d6:	fc26                	sd	s1,56(sp)
    800025d8:	f84a                	sd	s2,48(sp)
    800025da:	f44e                	sd	s3,40(sp)
    800025dc:	f052                	sd	s4,32(sp)
    800025de:	ec56                	sd	s5,24(sp)
    800025e0:	e85a                	sd	s6,16(sp)
    800025e2:	e45e                	sd	s7,8(sp)
    800025e4:	e062                	sd	s8,0(sp)
    800025e6:	0880                	addi	s0,sp,80
    800025e8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	3fc080e7          	jalr	1020(ra) # 800019e6 <myproc>
    800025f2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025f4:	00010517          	auipc	a0,0x10
    800025f8:	cc450513          	addi	a0,a0,-828 # 800122b8 <wait_lock>
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	5c6080e7          	jalr	1478(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002604:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002606:	4a15                	li	s4,5
        havekids = 1;
    80002608:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000260a:	0001e997          	auipc	s3,0x1e
    8000260e:	ec698993          	addi	s3,s3,-314 # 800204d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002612:	00010c17          	auipc	s8,0x10
    80002616:	ca6c0c13          	addi	s8,s8,-858 # 800122b8 <wait_lock>
    havekids = 0;
    8000261a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000261c:	00010497          	auipc	s1,0x10
    80002620:	0b448493          	addi	s1,s1,180 # 800126d0 <proc>
    80002624:	a059                	j	800026aa <wait+0xda>
          pid = np->pid;
    80002626:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000262a:	000b0e63          	beqz	s6,80002646 <wait+0x76>
    8000262e:	4691                	li	a3,4
    80002630:	02c48613          	addi	a2,s1,44
    80002634:	85da                	mv	a1,s6
    80002636:	05093503          	ld	a0,80(s2)
    8000263a:	fffff097          	auipc	ra,0xfffff
    8000263e:	06c080e7          	jalr	108(ra) # 800016a6 <copyout>
    80002642:	02054b63          	bltz	a0,80002678 <wait+0xa8>
          freeproc(np);
    80002646:	8526                	mv	a0,s1
    80002648:	fffff097          	auipc	ra,0xfffff
    8000264c:	550080e7          	jalr	1360(ra) # 80001b98 <freeproc>
          if (p->pid != INIT_PID && p->pid != SHELL_PID) {
    80002650:	03092783          	lw	a5,48(s2)
    80002654:	37fd                	addiw	a5,a5,-1
    80002656:	4705                	li	a4,1
    80002658:	02f76f63          	bltu	a4,a5,80002696 <wait+0xc6>
          release(&np->lock);
    8000265c:	8526                	mv	a0,s1
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	62a080e7          	jalr	1578(ra) # 80000c88 <release>
          release(&wait_lock);
    80002666:	00010517          	auipc	a0,0x10
    8000266a:	c5250513          	addi	a0,a0,-942 # 800122b8 <wait_lock>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	61a080e7          	jalr	1562(ra) # 80000c88 <release>
          return pid;
    80002676:	a88d                	j	800026e8 <wait+0x118>
            release(&np->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	60e080e7          	jalr	1550(ra) # 80000c88 <release>
            release(&wait_lock);
    80002682:	00010517          	auipc	a0,0x10
    80002686:	c3650513          	addi	a0,a0,-970 # 800122b8 <wait_lock>
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	5fe080e7          	jalr	1534(ra) # 80000c88 <release>
            return -1;
    80002692:	59fd                	li	s3,-1
    80002694:	a891                	j	800026e8 <wait+0x118>
            free_metadata(p);
    80002696:	854a                	mv	a0,s2
    80002698:	00000097          	auipc	ra,0x0
    8000269c:	bfa080e7          	jalr	-1030(ra) # 80002292 <free_metadata>
    800026a0:	bf75                	j	8000265c <wait+0x8c>
    for(np = proc; np < &proc[NPROC]; np++){
    800026a2:	37848493          	addi	s1,s1,888
    800026a6:	03348463          	beq	s1,s3,800026ce <wait+0xfe>
      if(np->parent == p){
    800026aa:	7c9c                	ld	a5,56(s1)
    800026ac:	ff279be3          	bne	a5,s2,800026a2 <wait+0xd2>
        acquire(&np->lock);
    800026b0:	8526                	mv	a0,s1
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	510080e7          	jalr	1296(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800026ba:	4c9c                	lw	a5,24(s1)
    800026bc:	f74785e3          	beq	a5,s4,80002626 <wait+0x56>
        release(&np->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5c6080e7          	jalr	1478(ra) # 80000c88 <release>
        havekids = 1;
    800026ca:	8756                	mv	a4,s5
    800026cc:	bfd9                	j	800026a2 <wait+0xd2>
    if(!havekids || p->killed){
    800026ce:	c701                	beqz	a4,800026d6 <wait+0x106>
    800026d0:	02892783          	lw	a5,40(s2)
    800026d4:	c79d                	beqz	a5,80002702 <wait+0x132>
      release(&wait_lock);
    800026d6:	00010517          	auipc	a0,0x10
    800026da:	be250513          	addi	a0,a0,-1054 # 800122b8 <wait_lock>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	5aa080e7          	jalr	1450(ra) # 80000c88 <release>
      return -1;
    800026e6:	59fd                	li	s3,-1
}
    800026e8:	854e                	mv	a0,s3
    800026ea:	60a6                	ld	ra,72(sp)
    800026ec:	6406                	ld	s0,64(sp)
    800026ee:	74e2                	ld	s1,56(sp)
    800026f0:	7942                	ld	s2,48(sp)
    800026f2:	79a2                	ld	s3,40(sp)
    800026f4:	7a02                	ld	s4,32(sp)
    800026f6:	6ae2                	ld	s5,24(sp)
    800026f8:	6b42                	ld	s6,16(sp)
    800026fa:	6ba2                	ld	s7,8(sp)
    800026fc:	6c02                	ld	s8,0(sp)
    800026fe:	6161                	addi	sp,sp,80
    80002700:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002702:	85e2                	mv	a1,s8
    80002704:	854a                	mv	a0,s2
    80002706:	00000097          	auipc	ra,0x0
    8000270a:	82e080e7          	jalr	-2002(ra) # 80001f34 <sleep>
    havekids = 0;
    8000270e:	b731                	j	8000261a <wait+0x4a>

0000000080002710 <get_free_page_in_disk>:
// ADDED Q1
int get_free_page_in_disk()
{
    80002710:	1141                	addi	sp,sp,-16
    80002712:	e406                	sd	ra,8(sp)
    80002714:	e022                	sd	s0,0(sp)
    80002716:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	2ce080e7          	jalr	718(ra) # 800019e6 <myproc>
  int index = 0;
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    80002720:	27050793          	addi	a5,a0,624
  int index = 0;
    80002724:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    80002726:	46c1                	li	a3,16
    if (!disk_pg->used) {
    80002728:	47d8                	lw	a4,12(a5)
    8000272a:	c711                	beqz	a4,80002736 <get_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    8000272c:	07c1                	addi	a5,a5,16
    8000272e:	2505                	addiw	a0,a0,1
    80002730:	fed51ce3          	bne	a0,a3,80002728 <get_free_page_in_disk+0x18>
      return index;
    }
  }
  return -1;
    80002734:	557d                	li	a0,-1
}
    80002736:	60a2                	ld	ra,8(sp)
    80002738:	6402                	ld	s0,0(sp)
    8000273a:	0141                	addi	sp,sp,16
    8000273c:	8082                	ret

000000008000273e <swapout>:

void swapout(int ram_pg_index)
{
    8000273e:	715d                	addi	sp,sp,-80
    80002740:	e486                	sd	ra,72(sp)
    80002742:	e0a2                	sd	s0,64(sp)
    80002744:	fc26                	sd	s1,56(sp)
    80002746:	f84a                	sd	s2,48(sp)
    80002748:	f44e                	sd	s3,40(sp)
    8000274a:	f052                	sd	s4,32(sp)
    8000274c:	ec56                	sd	s5,24(sp)
    8000274e:	e85a                	sd	s6,16(sp)
    80002750:	0880                	addi	s0,sp,80
    80002752:	737d                	lui	t1,0xfffff
    80002754:	911a                	add	sp,sp,t1
    80002756:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	28e080e7          	jalr	654(ra) # 800019e6 <myproc>
  if (ram_pg_index < 0 || ram_pg_index > MAX_PSYC_PAGES) {
    80002760:	0004871b          	sext.w	a4,s1
    80002764:	47c1                	li	a5,16
    80002766:	0ce7e963          	bltu	a5,a4,80002838 <swapout+0xfa>
    8000276a:	8a2a                	mv	s4,a0
    panic("swapout: ram page index out of bounds");
  }
  struct ram_page *ram_pg_to_swap = &p->ram_pages[ram_pg_index];

  if (!ram_pg_to_swap->used) {
    8000276c:	0492                	slli	s1,s1,0x4
    8000276e:	94aa                	add	s1,s1,a0
    80002770:	17c4a783          	lw	a5,380(s1)
    80002774:	cbf1                	beqz	a5,80002848 <swapout+0x10a>
    panic("swapout: page unused");
  }

  pte_t *pte;
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    80002776:	4601                	li	a2,0
    80002778:	1704b583          	ld	a1,368(s1)
    8000277c:	6928                	ld	a0,80(a0)
    8000277e:	fffff097          	auipc	ra,0xfffff
    80002782:	83a080e7          	jalr	-1990(ra) # 80000fb8 <walk>
    80002786:	89aa                	mv	s3,a0
    80002788:	c961                	beqz	a0,80002858 <swapout+0x11a>
    panic("swapout: walk failed");
  }

  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    8000278a:	611c                	ld	a5,0(a0)
    8000278c:	2017f793          	andi	a5,a5,513
    80002790:	4705                	li	a4,1
    80002792:	0ce79b63          	bne	a5,a4,80002868 <swapout+0x12a>
    panic("swapout: page is not in ram");
  }

  int unused_disk_pg_index;
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    80002796:	00000097          	auipc	ra,0x0
    8000279a:	f7a080e7          	jalr	-134(ra) # 80002710 <get_free_page_in_disk>
    8000279e:	892a                	mv	s2,a0
    800027a0:	0c054c63          	bltz	a0,80002878 <swapout+0x13a>
    panic("swapout: disk overflow");
  }
  struct disk_page *disk_pg_to_store = &p->disk_pages[unused_disk_pg_index];
  uint64 pa = PTE2PA(*pte);
    800027a4:	0009ba83          	ld	s5,0(s3)
    800027a8:	00aada93          	srli	s5,s5,0xa
    800027ac:	0ab2                	slli	s5,s5,0xc
  char buffer[PGSIZE];
  memmove(buffer, (void *)pa, PGSIZE); // TODO: Check va as opposed to pa.
    800027ae:	77fd                	lui	a5,0xfffff
    800027b0:	fc040713          	addi	a4,s0,-64
    800027b4:	97ba                	add	a5,a5,a4
    800027b6:	7b7d                	lui	s6,0xfffff
    800027b8:	fb8b0713          	addi	a4,s6,-72 # ffffffffffffefb8 <end+0xffffffff7ffcffb8>
    800027bc:	9722                	add	a4,a4,s0
    800027be:	e31c                	sd	a5,0(a4)
    800027c0:	6605                	lui	a2,0x1
    800027c2:	85d6                	mv	a1,s5
    800027c4:	6308                	ld	a0,0(a4)
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	566080e7          	jalr	1382(ra) # 80000d2c <memmove>
  if (writeToSwapFile(p, buffer, disk_pg_to_store->offset, PGSIZE) < 0) {
    800027ce:	0912                	slli	s2,s2,0x4
    800027d0:	9952                	add	s2,s2,s4
    800027d2:	6685                	lui	a3,0x1
    800027d4:	27892603          	lw	a2,632(s2)
    800027d8:	fb8b0793          	addi	a5,s6,-72
    800027dc:	97a2                	add	a5,a5,s0
    800027de:	638c                	ld	a1,0(a5)
    800027e0:	8552                	mv	a0,s4
    800027e2:	00002097          	auipc	ra,0x2
    800027e6:	204080e7          	jalr	516(ra) # 800049e6 <writeToSwapFile>
    800027ea:	08054f63          	bltz	a0,80002888 <swapout+0x14a>
    panic("swapout: failed to write to swapFile");
  }
  disk_pg_to_store->used = 1;
    800027ee:	4785                	li	a5,1
    800027f0:	26f92e23          	sw	a5,636(s2)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    800027f4:	1704b783          	ld	a5,368(s1)
    800027f8:	26f93823          	sd	a5,624(s2)
  kfree((void *)pa);
    800027fc:	8556                	mv	a0,s5
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	1d8080e7          	jalr	472(ra) # 800009d6 <kfree>

  ram_pg_to_swap->va = 0;
    80002806:	1604b823          	sd	zero,368(s1)
  ram_pg_to_swap->used = 0;
    8000280a:	1604ae23          	sw	zero,380(s1)

  *pte = *pte & ~PTE_V;
    8000280e:	0009b783          	ld	a5,0(s3)
    80002812:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    80002814:	2007e793          	ori	a5,a5,512
    80002818:	00f9b023          	sd	a5,0(s3)
  asm volatile("sfence.vma zero, zero");
    8000281c:	12000073          	sfence.vma
  sfence_vma();   // clear TLB
}
    80002820:	6305                	lui	t1,0x1
    80002822:	911a                	add	sp,sp,t1
    80002824:	60a6                	ld	ra,72(sp)
    80002826:	6406                	ld	s0,64(sp)
    80002828:	74e2                	ld	s1,56(sp)
    8000282a:	7942                	ld	s2,48(sp)
    8000282c:	79a2                	ld	s3,40(sp)
    8000282e:	7a02                	ld	s4,32(sp)
    80002830:	6ae2                	ld	s5,24(sp)
    80002832:	6b42                	ld	s6,16(sp)
    80002834:	6161                	addi	sp,sp,80
    80002836:	8082                	ret
    panic("swapout: ram page index out of bounds");
    80002838:	00007517          	auipc	a0,0x7
    8000283c:	a9050513          	addi	a0,a0,-1392 # 800092c8 <digits+0x288>
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	cea080e7          	jalr	-790(ra) # 8000052a <panic>
    panic("swapout: page unused");
    80002848:	00007517          	auipc	a0,0x7
    8000284c:	aa850513          	addi	a0,a0,-1368 # 800092f0 <digits+0x2b0>
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	cda080e7          	jalr	-806(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    80002858:	00007517          	auipc	a0,0x7
    8000285c:	ab050513          	addi	a0,a0,-1360 # 80009308 <digits+0x2c8>
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	cca080e7          	jalr	-822(ra) # 8000052a <panic>
    panic("swapout: page is not in ram");
    80002868:	00007517          	auipc	a0,0x7
    8000286c:	ab850513          	addi	a0,a0,-1352 # 80009320 <digits+0x2e0>
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	cba080e7          	jalr	-838(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    80002878:	00007517          	auipc	a0,0x7
    8000287c:	ac850513          	addi	a0,a0,-1336 # 80009340 <digits+0x300>
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	caa080e7          	jalr	-854(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    80002888:	00007517          	auipc	a0,0x7
    8000288c:	ad050513          	addi	a0,a0,-1328 # 80009358 <digits+0x318>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	c9a080e7          	jalr	-870(ra) # 8000052a <panic>

0000000080002898 <swapin>:

void swapin(int disk_index, int ram_index)
{
    80002898:	715d                	addi	sp,sp,-80
    8000289a:	e486                	sd	ra,72(sp)
    8000289c:	e0a2                	sd	s0,64(sp)
    8000289e:	fc26                	sd	s1,56(sp)
    800028a0:	f84a                	sd	s2,48(sp)
    800028a2:	f44e                	sd	s3,40(sp)
    800028a4:	f052                	sd	s4,32(sp)
    800028a6:	ec56                	sd	s5,24(sp)
    800028a8:	0880                	addi	s0,sp,80
    800028aa:	737d                	lui	t1,0xfffff
    800028ac:	0341                	addi	t1,t1,16
    800028ae:	911a                	add	sp,sp,t1
    800028b0:	84aa                	mv	s1,a0
    800028b2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	132080e7          	jalr	306(ra) # 800019e6 <myproc>
  if (disk_index < 0 || disk_index > MAX_PSYC_PAGES) {
    800028bc:	0004871b          	sext.w	a4,s1
    800028c0:	47c1                	li	a5,16
    800028c2:	0ce7ea63          	bltu	a5,a4,80002996 <swapin+0xfe>
    800028c6:	8aaa                	mv	s5,a0
    panic("swapin: disk index out of bounds");
  }

  if (ram_index < 0 || ram_index > MAX_PSYC_PAGES) {
    800028c8:	0009879b          	sext.w	a5,s3
    800028cc:	4741                	li	a4,16
    800028ce:	0cf76c63          	bltu	a4,a5,800029a6 <swapin+0x10e>
    panic("swapin: ram index out of bounds");
  }
  struct disk_page *disk_pg = &p->disk_pages[disk_index]; 

  if (!disk_pg->used) {
    800028d2:	0492                	slli	s1,s1,0x4
    800028d4:	94aa                	add	s1,s1,a0
    800028d6:	27c4a783          	lw	a5,636(s1)
    800028da:	cff1                	beqz	a5,800029b6 <swapin+0x11e>
    panic("swapin: page unused");
  }

  pte_t *pte;
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    800028dc:	4601                	li	a2,0
    800028de:	2704b583          	ld	a1,624(s1)
    800028e2:	6928                	ld	a0,80(a0)
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	6d4080e7          	jalr	1748(ra) # 80000fb8 <walk>
    800028ec:	8a2a                	mv	s4,a0
    800028ee:	cd61                	beqz	a0,800029c6 <swapin+0x12e>
    panic("swapin: unallocated pte");
  }

  if ((*pte & PTE_V) || !(*pte & PTE_PG))
    800028f0:	611c                	ld	a5,0(a0)
    800028f2:	2017f793          	andi	a5,a5,513
    800028f6:	20000713          	li	a4,512
    800028fa:	0ce79e63          	bne	a5,a4,800029d6 <swapin+0x13e>
      panic("swapin: page is not in disk");

  struct ram_page *ram_pg = &p->ram_pages[ram_index];
  if (ram_pg->used) {
    800028fe:	0992                	slli	s3,s3,0x4
    80002900:	99d6                	add	s3,s3,s5
    80002902:	17c9a783          	lw	a5,380(s3)
    80002906:	e3e5                	bnez	a5,800029e6 <swapin+0x14e>
    panic("swapin: ram page used");
  }

  uint64 npa;
  if ( (npa = (uint64)kalloc()) == 0 ) {
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	1ca080e7          	jalr	458(ra) # 80000ad2 <kalloc>
    80002910:	892a                	mv	s2,a0
    80002912:	c175                	beqz	a0,800029f6 <swapin+0x15e>
    panic("swapin: failed alocate physical address");
  }
  char buffer[PGSIZE];
  if (readFromSwapFile(p, buffer, disk_pg->offset, PGSIZE) < 0) {
    80002914:	6685                	lui	a3,0x1
    80002916:	2784a603          	lw	a2,632(s1)
    8000291a:	75fd                	lui	a1,0xfffff
    8000291c:	fc040793          	addi	a5,s0,-64
    80002920:	95be                	add	a1,a1,a5
    80002922:	8556                	mv	a0,s5
    80002924:	00002097          	auipc	ra,0x2
    80002928:	0e6080e7          	jalr	230(ra) # 80004a0a <readFromSwapFile>
    8000292c:	0c054d63          	bltz	a0,80002a06 <swapin+0x16e>
    panic("swapin: read from disk failed");
  }

  memmove((void *)npa, buffer, PGSIZE); 
    80002930:	6605                	lui	a2,0x1
    80002932:	75fd                	lui	a1,0xfffff
    80002934:	fc040793          	addi	a5,s0,-64
    80002938:	95be                	add	a1,a1,a5
    8000293a:	854a                	mv	a0,s2
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	3f0080e7          	jalr	1008(ra) # 80000d2c <memmove>

  ram_pg->used = 1;
    80002944:	4785                	li	a5,1
    80002946:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    8000294a:	2704b783          	ld	a5,624(s1)
    8000294e:	16f9b823          	sd	a5,368(s3)
  // ADDED Q2
  #if SELECTION == LAPA
    ram_pg->age = 0xFFFFFFFF;
    80002952:	57fd                	li	a5,-1
    80002954:	16f9ac23          	sw	a5,376(s3)
  #endif
  #if SELECTION != LAPA 
    ram_pg->age = 0;
  #endif

  disk_pg->va = 0;
    80002958:	2604b823          	sd	zero,624(s1)
  disk_pg->used = 0;
    8000295c:	2604ae23          	sw	zero,636(s1)

  *pte = *pte | PTE_V;                           
  *pte = *pte & ~PTE_PG;                         
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    80002960:	00c95913          	srli	s2,s2,0xc
    80002964:	092a                	slli	s2,s2,0xa
    80002966:	000a3783          	ld	a5,0(s4)
    8000296a:	1ff7f793          	andi	a5,a5,511
    8000296e:	00f96933          	or	s2,s2,a5
    80002972:	00196913          	ori	s2,s2,1
    80002976:	012a3023          	sd	s2,0(s4)
    8000297a:	12000073          	sfence.vma
  sfence_vma(); // clear TLB
}
    8000297e:	6305                	lui	t1,0x1
    80002980:	1341                	addi	t1,t1,-16
    80002982:	911a                	add	sp,sp,t1
    80002984:	60a6                	ld	ra,72(sp)
    80002986:	6406                	ld	s0,64(sp)
    80002988:	74e2                	ld	s1,56(sp)
    8000298a:	7942                	ld	s2,48(sp)
    8000298c:	79a2                	ld	s3,40(sp)
    8000298e:	7a02                	ld	s4,32(sp)
    80002990:	6ae2                	ld	s5,24(sp)
    80002992:	6161                	addi	sp,sp,80
    80002994:	8082                	ret
    panic("swapin: disk index out of bounds");
    80002996:	00007517          	auipc	a0,0x7
    8000299a:	9ea50513          	addi	a0,a0,-1558 # 80009380 <digits+0x340>
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	b8c080e7          	jalr	-1140(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    800029a6:	00007517          	auipc	a0,0x7
    800029aa:	a0250513          	addi	a0,a0,-1534 # 800093a8 <digits+0x368>
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	b7c080e7          	jalr	-1156(ra) # 8000052a <panic>
    panic("swapin: page unused");
    800029b6:	00007517          	auipc	a0,0x7
    800029ba:	a1250513          	addi	a0,a0,-1518 # 800093c8 <digits+0x388>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	b6c080e7          	jalr	-1172(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    800029c6:	00007517          	auipc	a0,0x7
    800029ca:	a1a50513          	addi	a0,a0,-1510 # 800093e0 <digits+0x3a0>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	b5c080e7          	jalr	-1188(ra) # 8000052a <panic>
      panic("swapin: page is not in disk");
    800029d6:	00007517          	auipc	a0,0x7
    800029da:	a2250513          	addi	a0,a0,-1502 # 800093f8 <digits+0x3b8>
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	b4c080e7          	jalr	-1204(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    800029e6:	00007517          	auipc	a0,0x7
    800029ea:	a3250513          	addi	a0,a0,-1486 # 80009418 <digits+0x3d8>
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	b3c080e7          	jalr	-1220(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    800029f6:	00007517          	auipc	a0,0x7
    800029fa:	a3a50513          	addi	a0,a0,-1478 # 80009430 <digits+0x3f0>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b2c080e7          	jalr	-1236(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002a06:	00007517          	auipc	a0,0x7
    80002a0a:	a5250513          	addi	a0,a0,-1454 # 80009458 <digits+0x418>
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	b1c080e7          	jalr	-1252(ra) # 8000052a <panic>

0000000080002a16 <get_unused_ram_index>:

int get_unused_ram_index(struct proc* p)
{
    80002a16:	1141                	addi	sp,sp,-16
    80002a18:	e422                	sd	s0,8(sp)
    80002a1a:	0800                	addi	s0,sp,16
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    80002a1c:	17c50793          	addi	a5,a0,380
    80002a20:	4501                	li	a0,0
    80002a22:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    80002a24:	4398                	lw	a4,0(a5)
    80002a26:	c711                	beqz	a4,80002a32 <get_unused_ram_index+0x1c>
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    80002a28:	2505                	addiw	a0,a0,1
    80002a2a:	07c1                	addi	a5,a5,16
    80002a2c:	fed51ce3          	bne	a0,a3,80002a24 <get_unused_ram_index+0xe>
      return i;
    }
  }
  return -1;
    80002a30:	557d                	li	a0,-1
}
    80002a32:	6422                	ld	s0,8(sp)
    80002a34:	0141                	addi	sp,sp,16
    80002a36:	8082                	ret

0000000080002a38 <get_disk_page_index>:

int get_disk_page_index(struct proc *p, uint64 va)
{
    80002a38:	1141                	addi	sp,sp,-16
    80002a3a:	e422                	sd	s0,8(sp)
    80002a3c:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002a3e:	27050793          	addi	a5,a0,624
    80002a42:	4501                	li	a0,0
    80002a44:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    80002a46:	6398                	ld	a4,0(a5)
    80002a48:	00b70763          	beq	a4,a1,80002a56 <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002a4c:	2505                	addiw	a0,a0,1
    80002a4e:	07c1                	addi	a5,a5,16
    80002a50:	fed51be3          	bne	a0,a3,80002a46 <get_disk_page_index+0xe>
      return i;
    }
  }
  return -1;
    80002a54:	557d                	li	a0,-1
}
    80002a56:	6422                	ld	s0,8(sp)
    80002a58:	0141                	addi	sp,sp,16
    80002a5a:	8082                	ret

0000000080002a5c <remove_page_from_ram>:
    #endif
}

// TODO assume remove page only located in ram?? or we should also iterate over the disk pages?
void remove_page_from_ram(uint64 va)
{
    80002a5c:	1101                	addi	sp,sp,-32
    80002a5e:	ec06                	sd	ra,24(sp)
    80002a60:	e822                	sd	s0,16(sp)
    80002a62:	e426                	sd	s1,8(sp)
    80002a64:	1000                	addi	s0,sp,32
    80002a66:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	f7e080e7          	jalr	-130(ra) # 800019e6 <myproc>
  if (p->pid == INIT_PID || p->pid == SHELL_PID) {
    80002a70:	591c                	lw	a5,48(a0)
    80002a72:	37fd                	addiw	a5,a5,-1
    80002a74:	4705                	li	a4,1
    80002a76:	02f77863          	bgeu	a4,a5,80002aa6 <remove_page_from_ram+0x4a>
    80002a7a:	17050793          	addi	a5,a0,368
    return;
  }
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002a7e:	4701                	li	a4,0
    80002a80:	4641                	li	a2,16
    80002a82:	a029                	j	80002a8c <remove_page_from_ram+0x30>
    80002a84:	2705                	addiw	a4,a4,1
    80002a86:	07c1                	addi	a5,a5,16
    80002a88:	02c70463          	beq	a4,a2,80002ab0 <remove_page_from_ram+0x54>
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
    80002a8c:	6394                	ld	a3,0(a5)
    80002a8e:	fe969be3          	bne	a3,s1,80002a84 <remove_page_from_ram+0x28>
    80002a92:	47d4                	lw	a3,12(a5)
    80002a94:	dae5                	beqz	a3,80002a84 <remove_page_from_ram+0x28>
      p->ram_pages[i].va = 0;
    80002a96:	0712                	slli	a4,a4,0x4
    80002a98:	972a                	add	a4,a4,a0
    80002a9a:	16073823          	sd	zero,368(a4)
      p->ram_pages[i].used = 0;
    80002a9e:	16072e23          	sw	zero,380(a4)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002aa2:	16072c23          	sw	zero,376(a4)
      return;
    }
  }
  panic("remove_page_from_ram failed");
}
    80002aa6:	60e2                	ld	ra,24(sp)
    80002aa8:	6442                	ld	s0,16(sp)
    80002aaa:	64a2                	ld	s1,8(sp)
    80002aac:	6105                	addi	sp,sp,32
    80002aae:	8082                	ret
  panic("remove_page_from_ram failed");
    80002ab0:	00007517          	auipc	a0,0x7
    80002ab4:	9c850513          	addi	a0,a0,-1592 # 80009478 <digits+0x438>
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	a72080e7          	jalr	-1422(ra) # 8000052a <panic>

0000000080002ac0 <nfua>:

int nfua()
{
    80002ac0:	1141                	addi	sp,sp,-16
    80002ac2:	e406                	sd	ra,8(sp)
    80002ac4:	e022                	sd	s0,0(sp)
    80002ac6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	f1e080e7          	jalr	-226(ra) # 800019e6 <myproc>
  int i = 0;
  int min_index = 0;
  uint min_age = 0xFFFFFFFF;
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002ad0:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002ad4:	567d                	li	a2,-1
  int min_index = 0;
    80002ad6:	4501                	li	a0,0
  int i = 0;
    80002ad8:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002ada:	45c1                	li	a1,16
    80002adc:	a029                	j	80002ae6 <nfua+0x26>
    80002ade:	0741                	addi	a4,a4,16
    80002ae0:	2785                	addiw	a5,a5,1
    80002ae2:	00b78863          	beq	a5,a1,80002af2 <nfua+0x32>
    if(ram_pg->age < min_age){
    80002ae6:	4714                	lw	a3,8(a4)
    80002ae8:	fec6fbe3          	bgeu	a3,a2,80002ade <nfua+0x1e>
      min_index = i;
      min_age = ram_pg->age;
    80002aec:	8636                	mv	a2,a3
    if(ram_pg->age < min_age){
    80002aee:	853e                	mv	a0,a5
    80002af0:	b7fd                	j	80002ade <nfua+0x1e>
    }
  }
  return min_index;
}
    80002af2:	60a2                	ld	ra,8(sp)
    80002af4:	6402                	ld	s0,0(sp)
    80002af6:	0141                	addi	sp,sp,16
    80002af8:	8082                	ret

0000000080002afa <insert_page_to_ram>:
{
    80002afa:	7179                	addi	sp,sp,-48
    80002afc:	f406                	sd	ra,40(sp)
    80002afe:	f022                	sd	s0,32(sp)
    80002b00:	ec26                	sd	s1,24(sp)
    80002b02:	e84a                	sd	s2,16(sp)
    80002b04:	e44e                	sd	s3,8(sp)
    80002b06:	1800                	addi	s0,sp,48
    80002b08:	89aa                	mv	s3,a0
    struct proc *p = myproc();
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	edc080e7          	jalr	-292(ra) # 800019e6 <myproc>
    if (p->pid == INIT_PID || p->pid == SHELL_PID) {
    80002b12:	591c                	lw	a5,48(a0)
    80002b14:	37fd                	addiw	a5,a5,-1
    80002b16:	4705                	li	a4,1
    80002b18:	02f77463          	bgeu	a4,a5,80002b40 <insert_page_to_ram+0x46>
    80002b1c:	84aa                	mv	s1,a0
    if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0)
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	ef8080e7          	jalr	-264(ra) # 80002a16 <get_unused_ram_index>
    80002b26:	892a                	mv	s2,a0
    80002b28:	02054363          	bltz	a0,80002b4e <insert_page_to_ram+0x54>
    ram_pg->va = va;
    80002b2c:	0912                	slli	s2,s2,0x4
    80002b2e:	94ca                	add	s1,s1,s2
    80002b30:	1734b823          	sd	s3,368(s1)
    ram_pg->used = 1;
    80002b34:	4785                	li	a5,1
    80002b36:	16f4ae23          	sw	a5,380(s1)
      ram_pg->age = 0xFFFFFFFF;
    80002b3a:	57fd                	li	a5,-1
    80002b3c:	16f4ac23          	sw	a5,376(s1)
}
    80002b40:	70a2                	ld	ra,40(sp)
    80002b42:	7402                	ld	s0,32(sp)
    80002b44:	64e2                	ld	s1,24(sp)
    80002b46:	6942                	ld	s2,16(sp)
    80002b48:	69a2                	ld	s3,8(sp)
    80002b4a:	6145                	addi	sp,sp,48
    80002b4c:	8082                	ret
}

int index_page_to_swap()
{
  #if SELECTION == NFUA
    return nfua();
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	f72080e7          	jalr	-142(ra) # 80002ac0 <nfua>
    80002b56:	892a                	mv	s2,a0
        swapout(ram_pg_index_to_swap);
    80002b58:	00000097          	auipc	ra,0x0
    80002b5c:	be6080e7          	jalr	-1050(ra) # 8000273e <swapout>
        unused_ram_pg_index = ram_pg_index_to_swap;
    80002b60:	b7f1                	j	80002b2c <insert_page_to_ram+0x32>

0000000080002b62 <handle_page_fault>:
{
    80002b62:	7179                	addi	sp,sp,-48
    80002b64:	f406                	sd	ra,40(sp)
    80002b66:	f022                	sd	s0,32(sp)
    80002b68:	ec26                	sd	s1,24(sp)
    80002b6a:	e84a                	sd	s2,16(sp)
    80002b6c:	e44e                	sd	s3,8(sp)
    80002b6e:	1800                	addi	s0,sp,48
    80002b70:	89aa                	mv	s3,a0
    struct proc *p = myproc();
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	e74080e7          	jalr	-396(ra) # 800019e6 <myproc>
    80002b7a:	84aa                	mv	s1,a0
    if (!(pte = walk(p->pagetable, va, 0))) {
    80002b7c:	4601                	li	a2,0
    80002b7e:	85ce                	mv	a1,s3
    80002b80:	6928                	ld	a0,80(a0)
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	436080e7          	jalr	1078(ra) # 80000fb8 <walk>
    80002b8a:	c531                	beqz	a0,80002bd6 <handle_page_fault+0x74>
    if(*pte & PTE_V){
    80002b8c:	611c                	ld	a5,0(a0)
    80002b8e:	0017f713          	andi	a4,a5,1
    80002b92:	eb31                	bnez	a4,80002be6 <handle_page_fault+0x84>
    if(!(*pte & PTE_PG)) {
    80002b94:	2007f793          	andi	a5,a5,512
    80002b98:	cfb9                	beqz	a5,80002bf6 <handle_page_fault+0x94>
    if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
    80002b9a:	8526                	mv	a0,s1
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	e7a080e7          	jalr	-390(ra) # 80002a16 <get_unused_ram_index>
    80002ba4:	892a                	mv	s2,a0
    80002ba6:	06054063          	bltz	a0,80002c06 <handle_page_fault+0xa4>
    if( (target_idx = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002baa:	75fd                	lui	a1,0xfffff
    80002bac:	00b9f5b3          	and	a1,s3,a1
    80002bb0:	8526                	mv	a0,s1
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	e86080e7          	jalr	-378(ra) # 80002a38 <get_disk_page_index>
    80002bba:	06054063          	bltz	a0,80002c1a <handle_page_fault+0xb8>
    swapin(target_idx, unused_ram_pg_index);
    80002bbe:	85ca                	mv	a1,s2
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	cd8080e7          	jalr	-808(ra) # 80002898 <swapin>
}
    80002bc8:	70a2                	ld	ra,40(sp)
    80002bca:	7402                	ld	s0,32(sp)
    80002bcc:	64e2                	ld	s1,24(sp)
    80002bce:	6942                	ld	s2,16(sp)
    80002bd0:	69a2                	ld	s3,8(sp)
    80002bd2:	6145                	addi	sp,sp,48
    80002bd4:	8082                	ret
      panic("handle_page_fault: walk failed");
    80002bd6:	00007517          	auipc	a0,0x7
    80002bda:	8c250513          	addi	a0,a0,-1854 # 80009498 <digits+0x458>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	94c080e7          	jalr	-1716(ra) # 8000052a <panic>
      panic("handle_page_fault: invalid pte");
    80002be6:	00007517          	auipc	a0,0x7
    80002bea:	8d250513          	addi	a0,a0,-1838 # 800094b8 <digits+0x478>
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	93c080e7          	jalr	-1732(ra) # 8000052a <panic>
      panic("handle_page_fault: PTE_PG off");
    80002bf6:	00007517          	auipc	a0,0x7
    80002bfa:	8e250513          	addi	a0,a0,-1822 # 800094d8 <digits+0x498>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	92c080e7          	jalr	-1748(ra) # 8000052a <panic>
    return nfua();
    80002c06:	00000097          	auipc	ra,0x0
    80002c0a:	eba080e7          	jalr	-326(ra) # 80002ac0 <nfua>
    80002c0e:	892a                	mv	s2,a0
        swapout(ram_pg_index_to_swap); 
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	b2e080e7          	jalr	-1234(ra) # 8000273e <swapout>
        unused_ram_pg_index = ram_pg_index_to_swap;
    80002c18:	bf49                	j	80002baa <handle_page_fault+0x48>
      panic("handle_page_fault: get_disk_page_index failed");
    80002c1a:	00007517          	auipc	a0,0x7
    80002c1e:	8de50513          	addi	a0,a0,-1826 # 800094f8 <digits+0x4b8>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	908080e7          	jalr	-1784(ra) # 8000052a <panic>

0000000080002c2a <count_ones>:
{
    80002c2a:	1141                	addi	sp,sp,-16
    80002c2c:	e422                	sd	s0,8(sp)
    80002c2e:	0800                	addi	s0,sp,16
  while(num > 0){
    80002c30:	c105                	beqz	a0,80002c50 <count_ones+0x26>
    80002c32:	87aa                	mv	a5,a0
  int count = 0;
    80002c34:	4501                	li	a0,0
  while(num > 0){
    80002c36:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002c38:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002c3c:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002c3e:	0007871b          	sext.w	a4,a5
    80002c42:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002c46:	fee6e9e3          	bltu	a3,a4,80002c38 <count_ones+0xe>
}
    80002c4a:	6422                	ld	s0,8(sp)
    80002c4c:	0141                	addi	sp,sp,16
    80002c4e:	8082                	ret
  int count = 0;
    80002c50:	4501                	li	a0,0
    80002c52:	bfe5                	j	80002c4a <count_ones+0x20>

0000000080002c54 <lapa>:
{
    80002c54:	715d                	addi	sp,sp,-80
    80002c56:	e486                	sd	ra,72(sp)
    80002c58:	e0a2                	sd	s0,64(sp)
    80002c5a:	fc26                	sd	s1,56(sp)
    80002c5c:	f84a                	sd	s2,48(sp)
    80002c5e:	f44e                	sd	s3,40(sp)
    80002c60:	f052                	sd	s4,32(sp)
    80002c62:	ec56                	sd	s5,24(sp)
    80002c64:	e85a                	sd	s6,16(sp)
    80002c66:	e45e                	sd	s7,8(sp)
    80002c68:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	d7c080e7          	jalr	-644(ra) # 800019e6 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c72:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002c76:	5afd                	li	s5,-1
  int min_index = 0;
    80002c78:	4b81                	li	s7,0
  int i = 0;
    80002c7a:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c7c:	4b41                	li	s6,16
    80002c7e:	a039                	j	80002c8c <lapa+0x38>
      min_age = ram_pg->age;
    80002c80:	8ad2                	mv	s5,s4
    80002c82:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c84:	09c1                	addi	s3,s3,16
    80002c86:	2905                	addiw	s2,s2,1
    80002c88:	03690863          	beq	s2,s6,80002cb8 <lapa+0x64>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002c8c:	0089aa03          	lw	s4,8(s3)
    80002c90:	8552                	mv	a0,s4
    80002c92:	00000097          	auipc	ra,0x0
    80002c96:	f98080e7          	jalr	-104(ra) # 80002c2a <count_ones>
    80002c9a:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002c9c:	8556                	mv	a0,s5
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	f8c080e7          	jalr	-116(ra) # 80002c2a <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002ca6:	fca4cde3          	blt	s1,a0,80002c80 <lapa+0x2c>
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002caa:	fca49de3          	bne	s1,a0,80002c84 <lapa+0x30>
    80002cae:	fd5a7be3          	bgeu	s4,s5,80002c84 <lapa+0x30>
      min_age = ram_pg->age;
    80002cb2:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002cb4:	8bca                	mv	s7,s2
    80002cb6:	b7f9                	j	80002c84 <lapa+0x30>
}
    80002cb8:	855e                	mv	a0,s7
    80002cba:	60a6                	ld	ra,72(sp)
    80002cbc:	6406                	ld	s0,64(sp)
    80002cbe:	74e2                	ld	s1,56(sp)
    80002cc0:	7942                	ld	s2,48(sp)
    80002cc2:	79a2                	ld	s3,40(sp)
    80002cc4:	7a02                	ld	s4,32(sp)
    80002cc6:	6ae2                	ld	s5,24(sp)
    80002cc8:	6b42                	ld	s6,16(sp)
    80002cca:	6ba2                	ld	s7,8(sp)
    80002ccc:	6161                	addi	sp,sp,80
    80002cce:	8082                	ret

0000000080002cd0 <scfifo>:
{
    80002cd0:	1101                	addi	sp,sp,-32
    80002cd2:	ec06                	sd	ra,24(sp)
    80002cd4:	e822                	sd	s0,16(sp)
    80002cd6:	e426                	sd	s1,8(sp)
    80002cd8:	e04a                	sd	s2,0(sp)
    80002cda:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	d0a080e7          	jalr	-758(ra) # 800019e6 <myproc>
    80002ce4:	892a                	mv	s2,a0
  int index = p->scfifo_index;
    80002ce6:	37052483          	lw	s1,880(a0)
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
    80002cea:	01748793          	addi	a5,s1,23
    80002cee:	0792                	slli	a5,a5,0x4
    80002cf0:	97ca                	add	a5,a5,s2
    80002cf2:	4601                	li	a2,0
    80002cf4:	638c                	ld	a1,0(a5)
    80002cf6:	05093503          	ld	a0,80(s2)
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	2be080e7          	jalr	702(ra) # 80000fb8 <walk>
    80002d02:	c10d                	beqz	a0,80002d24 <scfifo+0x54>
    if(*pte & PTE_A){
    80002d04:	611c                	ld	a5,0(a0)
    80002d06:	0407f713          	andi	a4,a5,64
    80002d0a:	c70d                	beqz	a4,80002d34 <scfifo+0x64>
      *pte = *pte & ~PTE_A;
    80002d0c:	fbf7f793          	andi	a5,a5,-65
    80002d10:	e11c                	sd	a5,0(a0)
      index = (index + 1) % MAX_PSYC_PAGES;
    80002d12:	2485                	addiw	s1,s1,1
    80002d14:	41f4d79b          	sraiw	a5,s1,0x1f
    80002d18:	01c7d79b          	srliw	a5,a5,0x1c
    80002d1c:	9cbd                	addw	s1,s1,a5
    80002d1e:	88bd                	andi	s1,s1,15
    80002d20:	9c9d                	subw	s1,s1,a5
  while(1){
    80002d22:	b7e1                	j	80002cea <scfifo+0x1a>
      panic("scfifo: walk failed");
    80002d24:	00007517          	auipc	a0,0x7
    80002d28:	80450513          	addi	a0,a0,-2044 # 80009528 <digits+0x4e8>
    80002d2c:	ffffd097          	auipc	ra,0xffffd
    80002d30:	7fe080e7          	jalr	2046(ra) # 8000052a <panic>
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
    80002d34:	0014879b          	addiw	a5,s1,1
    80002d38:	41f7d71b          	sraiw	a4,a5,0x1f
    80002d3c:	01c7571b          	srliw	a4,a4,0x1c
    80002d40:	9fb9                	addw	a5,a5,a4
    80002d42:	8bbd                	andi	a5,a5,15
    80002d44:	9f99                	subw	a5,a5,a4
    80002d46:	36f92823          	sw	a5,880(s2)
}
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	60e2                	ld	ra,24(sp)
    80002d4e:	6442                	ld	s0,16(sp)
    80002d50:	64a2                	ld	s1,8(sp)
    80002d52:	6902                	ld	s2,0(sp)
    80002d54:	6105                	addi	sp,sp,32
    80002d56:	8082                	ret

0000000080002d58 <index_page_to_swap>:
{
    80002d58:	1141                	addi	sp,sp,-16
    80002d5a:	e406                	sd	ra,8(sp)
    80002d5c:	e022                	sd	s0,0(sp)
    80002d5e:	0800                	addi	s0,sp,16
    return nfua();
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	d60080e7          	jalr	-672(ra) # 80002ac0 <nfua>
  #if SELECTION == NONE
    return -1;
  #endif

  return -1;
}
    80002d68:	60a2                	ld	ra,8(sp)
    80002d6a:	6402                	ld	s0,0(sp)
    80002d6c:	0141                	addi	sp,sp,16
    80002d6e:	8082                	ret

0000000080002d70 <maintain_age>:

void maintain_age(struct proc *p){
    80002d70:	7179                	addi	sp,sp,-48
    80002d72:	f406                	sd	ra,40(sp)
    80002d74:	f022                	sd	s0,32(sp)
    80002d76:	ec26                	sd	s1,24(sp)
    80002d78:	e84a                	sd	s2,16(sp)
    80002d7a:	e44e                	sd	s3,8(sp)
    80002d7c:	e052                	sd	s4,0(sp)
    80002d7e:	1800                	addi	s0,sp,48
    80002d80:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002d82:	17050493          	addi	s1,a0,368
    80002d86:	27050993          	addi	s3,a0,624
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
      panic("maintain_age: walk failed");
    }
    ram_pg->age = (ram_pg->age >> 1);
    if (*pte & PTE_A){
      ram_pg->age = ram_pg->age | (1 << 31);
    80002d8a:	80000a37          	lui	s4,0x80000
    80002d8e:	a821                	j	80002da6 <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002d90:	00006517          	auipc	a0,0x6
    80002d94:	7b050513          	addi	a0,a0,1968 # 80009540 <digits+0x500>
    80002d98:	ffffd097          	auipc	ra,0xffffd
    80002d9c:	792080e7          	jalr	1938(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002da0:	04c1                	addi	s1,s1,16
    80002da2:	02998b63          	beq	s3,s1,80002dd8 <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002da6:	4601                	li	a2,0
    80002da8:	608c                	ld	a1,0(s1)
    80002daa:	05093503          	ld	a0,80(s2)
    80002dae:	ffffe097          	auipc	ra,0xffffe
    80002db2:	20a080e7          	jalr	522(ra) # 80000fb8 <walk>
    80002db6:	dd69                	beqz	a0,80002d90 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002db8:	449c                	lw	a5,8(s1)
    80002dba:	0017d79b          	srliw	a5,a5,0x1
    80002dbe:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002dc0:	6118                	ld	a4,0(a0)
    80002dc2:	04077713          	andi	a4,a4,64
    80002dc6:	df69                	beqz	a4,80002da0 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002dc8:	0147e7b3          	or	a5,a5,s4
    80002dcc:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002dce:	611c                	ld	a5,0(a0)
    80002dd0:	fbf7f793          	andi	a5,a5,-65
    80002dd4:	e11c                	sd	a5,0(a0)
    80002dd6:	b7e9                	j	80002da0 <maintain_age+0x30>
    }
  }
}
    80002dd8:	70a2                	ld	ra,40(sp)
    80002dda:	7402                	ld	s0,32(sp)
    80002ddc:	64e2                	ld	s1,24(sp)
    80002dde:	6942                	ld	s2,16(sp)
    80002de0:	69a2                	ld	s3,8(sp)
    80002de2:	6a02                	ld	s4,0(sp)
    80002de4:	6145                	addi	sp,sp,48
    80002de6:	8082                	ret

0000000080002de8 <scheduler>:
{
    80002de8:	7139                	addi	sp,sp,-64
    80002dea:	fc06                	sd	ra,56(sp)
    80002dec:	f822                	sd	s0,48(sp)
    80002dee:	f426                	sd	s1,40(sp)
    80002df0:	f04a                	sd	s2,32(sp)
    80002df2:	ec4e                	sd	s3,24(sp)
    80002df4:	e852                	sd	s4,16(sp)
    80002df6:	e456                	sd	s5,8(sp)
    80002df8:	e05a                	sd	s6,0(sp)
    80002dfa:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80002dfc:	8792                	mv	a5,tp
  int id = r_tp();
    80002dfe:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002e00:	00779a93          	slli	s5,a5,0x7
    80002e04:	0000f717          	auipc	a4,0xf
    80002e08:	49c70713          	addi	a4,a4,1180 # 800122a0 <pid_lock>
    80002e0c:	9756                	add	a4,a4,s5
    80002e0e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002e12:	0000f717          	auipc	a4,0xf
    80002e16:	4c670713          	addi	a4,a4,1222 # 800122d8 <cpus+0x8>
    80002e1a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002e1c:	498d                	li	s3,3
        p->state = RUNNING;
    80002e1e:	4b11                	li	s6,4
        c->proc = p;
    80002e20:	079e                	slli	a5,a5,0x7
    80002e22:	0000fa17          	auipc	s4,0xf
    80002e26:	47ea0a13          	addi	s4,s4,1150 # 800122a0 <pid_lock>
    80002e2a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002e2c:	0001d917          	auipc	s2,0x1d
    80002e30:	6a490913          	addi	s2,s2,1700 # 800204d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e38:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e3c:	10079073          	csrw	sstatus,a5
    80002e40:	00010497          	auipc	s1,0x10
    80002e44:	89048493          	addi	s1,s1,-1904 # 800126d0 <proc>
    80002e48:	a811                	j	80002e5c <scheduler+0x74>
      release(&p->lock);
    80002e4a:	8526                	mv	a0,s1
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	e3c080e7          	jalr	-452(ra) # 80000c88 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002e54:	37848493          	addi	s1,s1,888
    80002e58:	fd248ee3          	beq	s1,s2,80002e34 <scheduler+0x4c>
      acquire(&p->lock);
    80002e5c:	8526                	mv	a0,s1
    80002e5e:	ffffe097          	auipc	ra,0xffffe
    80002e62:	d64080e7          	jalr	-668(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80002e66:	4c9c                	lw	a5,24(s1)
    80002e68:	ff3791e3          	bne	a5,s3,80002e4a <scheduler+0x62>
        p->state = RUNNING;
    80002e6c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002e70:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002e74:	06048593          	addi	a1,s1,96
    80002e78:	8556                	mv	a0,s5
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	018080e7          	jalr	24(ra) # 80002e92 <swtch>
          maintain_age(p);
    80002e82:	8526                	mv	a0,s1
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	eec080e7          	jalr	-276(ra) # 80002d70 <maintain_age>
        c->proc = 0;
    80002e8c:	020a3823          	sd	zero,48(s4)
    80002e90:	bf6d                	j	80002e4a <scheduler+0x62>

0000000080002e92 <swtch>:
    80002e92:	00153023          	sd	ra,0(a0)
    80002e96:	00253423          	sd	sp,8(a0)
    80002e9a:	e900                	sd	s0,16(a0)
    80002e9c:	ed04                	sd	s1,24(a0)
    80002e9e:	03253023          	sd	s2,32(a0)
    80002ea2:	03353423          	sd	s3,40(a0)
    80002ea6:	03453823          	sd	s4,48(a0)
    80002eaa:	03553c23          	sd	s5,56(a0)
    80002eae:	05653023          	sd	s6,64(a0)
    80002eb2:	05753423          	sd	s7,72(a0)
    80002eb6:	05853823          	sd	s8,80(a0)
    80002eba:	05953c23          	sd	s9,88(a0)
    80002ebe:	07a53023          	sd	s10,96(a0)
    80002ec2:	07b53423          	sd	s11,104(a0)
    80002ec6:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80002eca:	0085b103          	ld	sp,8(a1)
    80002ece:	6980                	ld	s0,16(a1)
    80002ed0:	6d84                	ld	s1,24(a1)
    80002ed2:	0205b903          	ld	s2,32(a1)
    80002ed6:	0285b983          	ld	s3,40(a1)
    80002eda:	0305ba03          	ld	s4,48(a1)
    80002ede:	0385ba83          	ld	s5,56(a1)
    80002ee2:	0405bb03          	ld	s6,64(a1)
    80002ee6:	0485bb83          	ld	s7,72(a1)
    80002eea:	0505bc03          	ld	s8,80(a1)
    80002eee:	0585bc83          	ld	s9,88(a1)
    80002ef2:	0605bd03          	ld	s10,96(a1)
    80002ef6:	0685bd83          	ld	s11,104(a1)
    80002efa:	8082                	ret

0000000080002efc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002efc:	1141                	addi	sp,sp,-16
    80002efe:	e406                	sd	ra,8(sp)
    80002f00:	e022                	sd	s0,0(sp)
    80002f02:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f04:	00006597          	auipc	a1,0x6
    80002f08:	6b458593          	addi	a1,a1,1716 # 800095b8 <states.0+0x30>
    80002f0c:	0001d517          	auipc	a0,0x1d
    80002f10:	5c450513          	addi	a0,a0,1476 # 800204d0 <tickslock>
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	c1e080e7          	jalr	-994(ra) # 80000b32 <initlock>
}
    80002f1c:	60a2                	ld	ra,8(sp)
    80002f1e:	6402                	ld	s0,0(sp)
    80002f20:	0141                	addi	sp,sp,16
    80002f22:	8082                	ret

0000000080002f24 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002f24:	1141                	addi	sp,sp,-16
    80002f26:	e422                	sd	s0,8(sp)
    80002f28:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f2a:	00004797          	auipc	a5,0x4
    80002f2e:	ac678793          	addi	a5,a5,-1338 # 800069f0 <kernelvec>
    80002f32:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f36:	6422                	ld	s0,8(sp)
    80002f38:	0141                	addi	sp,sp,16
    80002f3a:	8082                	ret

0000000080002f3c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f3c:	1141                	addi	sp,sp,-16
    80002f3e:	e406                	sd	ra,8(sp)
    80002f40:	e022                	sd	s0,0(sp)
    80002f42:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	aa2080e7          	jalr	-1374(ra) # 800019e6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f4c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f50:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f52:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002f56:	00005617          	auipc	a2,0x5
    80002f5a:	0aa60613          	addi	a2,a2,170 # 80008000 <_trampoline>
    80002f5e:	00005697          	auipc	a3,0x5
    80002f62:	0a268693          	addi	a3,a3,162 # 80008000 <_trampoline>
    80002f66:	8e91                	sub	a3,a3,a2
    80002f68:	040007b7          	lui	a5,0x4000
    80002f6c:	17fd                	addi	a5,a5,-1
    80002f6e:	07b2                	slli	a5,a5,0xc
    80002f70:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f72:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f76:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f78:	180026f3          	csrr	a3,satp
    80002f7c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002f7e:	6d38                	ld	a4,88(a0)
    80002f80:	6134                	ld	a3,64(a0)
    80002f82:	6585                	lui	a1,0x1
    80002f84:	96ae                	add	a3,a3,a1
    80002f86:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002f88:	6d38                	ld	a4,88(a0)
    80002f8a:	00000697          	auipc	a3,0x0
    80002f8e:	13868693          	addi	a3,a3,312 # 800030c2 <usertrap>
    80002f92:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002f94:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f96:	8692                	mv	a3,tp
    80002f98:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f9a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002f9e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002fa2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fa6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002faa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fac:	6f18                	ld	a4,24(a4)
    80002fae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002fb2:	692c                	ld	a1,80(a0)
    80002fb4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002fb6:	00005717          	auipc	a4,0x5
    80002fba:	0da70713          	addi	a4,a4,218 # 80008090 <userret>
    80002fbe:	8f11                	sub	a4,a4,a2
    80002fc0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002fc2:	577d                	li	a4,-1
    80002fc4:	177e                	slli	a4,a4,0x3f
    80002fc6:	8dd9                	or	a1,a1,a4
    80002fc8:	02000537          	lui	a0,0x2000
    80002fcc:	157d                	addi	a0,a0,-1
    80002fce:	0536                	slli	a0,a0,0xd
    80002fd0:	9782                	jalr	a5
}
    80002fd2:	60a2                	ld	ra,8(sp)
    80002fd4:	6402                	ld	s0,0(sp)
    80002fd6:	0141                	addi	sp,sp,16
    80002fd8:	8082                	ret

0000000080002fda <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	e426                	sd	s1,8(sp)
    80002fe2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002fe4:	0001d497          	auipc	s1,0x1d
    80002fe8:	4ec48493          	addi	s1,s1,1260 # 800204d0 <tickslock>
    80002fec:	8526                	mv	a0,s1
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	bd4080e7          	jalr	-1068(ra) # 80000bc2 <acquire>
  ticks++;
    80002ff6:	00007517          	auipc	a0,0x7
    80002ffa:	03a50513          	addi	a0,a0,58 # 8000a030 <ticks>
    80002ffe:	411c                	lw	a5,0(a0)
    80003000:	2785                	addiw	a5,a5,1
    80003002:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	f94080e7          	jalr	-108(ra) # 80001f98 <wakeup>
  release(&tickslock);
    8000300c:	8526                	mv	a0,s1
    8000300e:	ffffe097          	auipc	ra,0xffffe
    80003012:	c7a080e7          	jalr	-902(ra) # 80000c88 <release>
}
    80003016:	60e2                	ld	ra,24(sp)
    80003018:	6442                	ld	s0,16(sp)
    8000301a:	64a2                	ld	s1,8(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret

0000000080003020 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	e426                	sd	s1,8(sp)
    80003028:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000302a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000302e:	00074d63          	bltz	a4,80003048 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003032:	57fd                	li	a5,-1
    80003034:	17fe                	slli	a5,a5,0x3f
    80003036:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003038:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000303a:	06f70363          	beq	a4,a5,800030a0 <devintr+0x80>
  }
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret
     (scause & 0xff) == 9){
    80003048:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000304c:	46a5                	li	a3,9
    8000304e:	fed792e3          	bne	a5,a3,80003032 <devintr+0x12>
    int irq = plic_claim();
    80003052:	00004097          	auipc	ra,0x4
    80003056:	aa6080e7          	jalr	-1370(ra) # 80006af8 <plic_claim>
    8000305a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000305c:	47a9                	li	a5,10
    8000305e:	02f50763          	beq	a0,a5,8000308c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003062:	4785                	li	a5,1
    80003064:	02f50963          	beq	a0,a5,80003096 <devintr+0x76>
    return 1;
    80003068:	4505                	li	a0,1
    } else if(irq){
    8000306a:	d8f1                	beqz	s1,8000303e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000306c:	85a6                	mv	a1,s1
    8000306e:	00006517          	auipc	a0,0x6
    80003072:	55250513          	addi	a0,a0,1362 # 800095c0 <states.0+0x38>
    80003076:	ffffd097          	auipc	ra,0xffffd
    8000307a:	4fe080e7          	jalr	1278(ra) # 80000574 <printf>
      plic_complete(irq);
    8000307e:	8526                	mv	a0,s1
    80003080:	00004097          	auipc	ra,0x4
    80003084:	a9c080e7          	jalr	-1380(ra) # 80006b1c <plic_complete>
    return 1;
    80003088:	4505                	li	a0,1
    8000308a:	bf55                	j	8000303e <devintr+0x1e>
      uartintr();
    8000308c:	ffffe097          	auipc	ra,0xffffe
    80003090:	8fa080e7          	jalr	-1798(ra) # 80000986 <uartintr>
    80003094:	b7ed                	j	8000307e <devintr+0x5e>
      virtio_disk_intr();
    80003096:	00004097          	auipc	ra,0x4
    8000309a:	f18080e7          	jalr	-232(ra) # 80006fae <virtio_disk_intr>
    8000309e:	b7c5                	j	8000307e <devintr+0x5e>
    if(cpuid() == 0){
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	91a080e7          	jalr	-1766(ra) # 800019ba <cpuid>
    800030a8:	c901                	beqz	a0,800030b8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800030aa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800030ae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800030b0:	14479073          	csrw	sip,a5
    return 2;
    800030b4:	4509                	li	a0,2
    800030b6:	b761                	j	8000303e <devintr+0x1e>
      clockintr();
    800030b8:	00000097          	auipc	ra,0x0
    800030bc:	f22080e7          	jalr	-222(ra) # 80002fda <clockintr>
    800030c0:	b7ed                	j	800030aa <devintr+0x8a>

00000000800030c2 <usertrap>:
{
    800030c2:	1101                	addi	sp,sp,-32
    800030c4:	ec06                	sd	ra,24(sp)
    800030c6:	e822                	sd	s0,16(sp)
    800030c8:	e426                	sd	s1,8(sp)
    800030ca:	e04a                	sd	s2,0(sp)
    800030cc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030ce:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800030d2:	1007f793          	andi	a5,a5,256
    800030d6:	e3ad                	bnez	a5,80003138 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030d8:	00004797          	auipc	a5,0x4
    800030dc:	91878793          	addi	a5,a5,-1768 # 800069f0 <kernelvec>
    800030e0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800030e4:	fffff097          	auipc	ra,0xfffff
    800030e8:	902080e7          	jalr	-1790(ra) # 800019e6 <myproc>
    800030ec:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800030ee:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030f0:	14102773          	csrr	a4,sepc
    800030f4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030f6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800030fa:	47a1                	li	a5,8
    800030fc:	04f71c63          	bne	a4,a5,80003154 <usertrap+0x92>
    if(p->killed)
    80003100:	551c                	lw	a5,40(a0)
    80003102:	e3b9                	bnez	a5,80003148 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003104:	6cb8                	ld	a4,88(s1)
    80003106:	6f1c                	ld	a5,24(a4)
    80003108:	0791                	addi	a5,a5,4
    8000310a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000310c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003110:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003114:	10079073          	csrw	sstatus,a5
    syscall();
    80003118:	00000097          	auipc	ra,0x0
    8000311c:	316080e7          	jalr	790(ra) # 8000342e <syscall>
  if(p->killed)
    80003120:	549c                	lw	a5,40(s1)
    80003122:	e7dd                	bnez	a5,800031d0 <usertrap+0x10e>
  usertrapret();
    80003124:	00000097          	auipc	ra,0x0
    80003128:	e18080e7          	jalr	-488(ra) # 80002f3c <usertrapret>
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	64a2                	ld	s1,8(sp)
    80003132:	6902                	ld	s2,0(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret
    panic("usertrap: not from user mode");
    80003138:	00006517          	auipc	a0,0x6
    8000313c:	4a850513          	addi	a0,a0,1192 # 800095e0 <states.0+0x58>
    80003140:	ffffd097          	auipc	ra,0xffffd
    80003144:	3ea080e7          	jalr	1002(ra) # 8000052a <panic>
      exit(-1);
    80003148:	557d                	li	a0,-1
    8000314a:	fffff097          	auipc	ra,0xfffff
    8000314e:	398080e7          	jalr	920(ra) # 800024e2 <exit>
    80003152:	bf4d                	j	80003104 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003154:	00000097          	auipc	ra,0x0
    80003158:	ecc080e7          	jalr	-308(ra) # 80003020 <devintr>
    8000315c:	892a                	mv	s2,a0
    8000315e:	e535                	bnez	a0,800031ca <usertrap+0x108>
  } else if ((p->pid != INIT_PID && p->pid != SHELL_PID) && 
    80003160:	5890                	lw	a2,48(s1)
    80003162:	fff6071b          	addiw	a4,a2,-1
    80003166:	4785                	li	a5,1
    80003168:	02e7f163          	bgeu	a5,a4,8000318a <usertrap+0xc8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000316c:	14202773          	csrr	a4,scause
    80003170:	47b1                	li	a5,12
    80003172:	04f70563          	beq	a4,a5,800031bc <usertrap+0xfa>
    80003176:	14202773          	csrr	a4,scause
             (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    8000317a:	47b5                	li	a5,13
    8000317c:	04f70063          	beq	a4,a5,800031bc <usertrap+0xfa>
    80003180:	14202773          	csrr	a4,scause
    80003184:	47bd                	li	a5,15
    80003186:	02f70b63          	beq	a4,a5,800031bc <usertrap+0xfa>
    8000318a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000318e:	00006517          	auipc	a0,0x6
    80003192:	47250513          	addi	a0,a0,1138 # 80009600 <states.0+0x78>
    80003196:	ffffd097          	auipc	ra,0xffffd
    8000319a:	3de080e7          	jalr	990(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000319e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800031a2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031a6:	00006517          	auipc	a0,0x6
    800031aa:	48a50513          	addi	a0,a0,1162 # 80009630 <states.0+0xa8>
    800031ae:	ffffd097          	auipc	ra,0xffffd
    800031b2:	3c6080e7          	jalr	966(ra) # 80000574 <printf>
    p->killed = 1;
    800031b6:	4785                	li	a5,1
    800031b8:	d49c                	sw	a5,40(s1)
  if(p->killed)
    800031ba:	a821                	j	800031d2 <usertrap+0x110>
    800031bc:	14302573          	csrr	a0,stval
    handle_page_fault(va);    
    800031c0:	00000097          	auipc	ra,0x0
    800031c4:	9a2080e7          	jalr	-1630(ra) # 80002b62 <handle_page_fault>
             (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    800031c8:	bfa1                	j	80003120 <usertrap+0x5e>
  if(p->killed)
    800031ca:	549c                	lw	a5,40(s1)
    800031cc:	cb81                	beqz	a5,800031dc <usertrap+0x11a>
    800031ce:	a011                	j	800031d2 <usertrap+0x110>
    800031d0:	4901                	li	s2,0
    exit(-1);
    800031d2:	557d                	li	a0,-1
    800031d4:	fffff097          	auipc	ra,0xfffff
    800031d8:	30e080e7          	jalr	782(ra) # 800024e2 <exit>
  if(which_dev == 2)
    800031dc:	4789                	li	a5,2
    800031de:	f4f913e3          	bne	s2,a5,80003124 <usertrap+0x62>
    yield();
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	d16080e7          	jalr	-746(ra) # 80001ef8 <yield>
    800031ea:	bf2d                	j	80003124 <usertrap+0x62>

00000000800031ec <kerneltrap>:
{
    800031ec:	7179                	addi	sp,sp,-48
    800031ee:	f406                	sd	ra,40(sp)
    800031f0:	f022                	sd	s0,32(sp)
    800031f2:	ec26                	sd	s1,24(sp)
    800031f4:	e84a                	sd	s2,16(sp)
    800031f6:	e44e                	sd	s3,8(sp)
    800031f8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031fa:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031fe:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003202:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003206:	1004f793          	andi	a5,s1,256
    8000320a:	cb85                	beqz	a5,8000323a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000320c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003210:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003212:	ef85                	bnez	a5,8000324a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003214:	00000097          	auipc	ra,0x0
    80003218:	e0c080e7          	jalr	-500(ra) # 80003020 <devintr>
    8000321c:	cd1d                	beqz	a0,8000325a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000321e:	4789                	li	a5,2
    80003220:	06f50a63          	beq	a0,a5,80003294 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003224:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003228:	10049073          	csrw	sstatus,s1
}
    8000322c:	70a2                	ld	ra,40(sp)
    8000322e:	7402                	ld	s0,32(sp)
    80003230:	64e2                	ld	s1,24(sp)
    80003232:	6942                	ld	s2,16(sp)
    80003234:	69a2                	ld	s3,8(sp)
    80003236:	6145                	addi	sp,sp,48
    80003238:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000323a:	00006517          	auipc	a0,0x6
    8000323e:	41650513          	addi	a0,a0,1046 # 80009650 <states.0+0xc8>
    80003242:	ffffd097          	auipc	ra,0xffffd
    80003246:	2e8080e7          	jalr	744(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000324a:	00006517          	auipc	a0,0x6
    8000324e:	42e50513          	addi	a0,a0,1070 # 80009678 <states.0+0xf0>
    80003252:	ffffd097          	auipc	ra,0xffffd
    80003256:	2d8080e7          	jalr	728(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000325a:	85ce                	mv	a1,s3
    8000325c:	00006517          	auipc	a0,0x6
    80003260:	43c50513          	addi	a0,a0,1084 # 80009698 <states.0+0x110>
    80003264:	ffffd097          	auipc	ra,0xffffd
    80003268:	310080e7          	jalr	784(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000326c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003270:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003274:	00006517          	auipc	a0,0x6
    80003278:	43450513          	addi	a0,a0,1076 # 800096a8 <states.0+0x120>
    8000327c:	ffffd097          	auipc	ra,0xffffd
    80003280:	2f8080e7          	jalr	760(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003284:	00006517          	auipc	a0,0x6
    80003288:	43c50513          	addi	a0,a0,1084 # 800096c0 <states.0+0x138>
    8000328c:	ffffd097          	auipc	ra,0xffffd
    80003290:	29e080e7          	jalr	670(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	752080e7          	jalr	1874(ra) # 800019e6 <myproc>
    8000329c:	d541                	beqz	a0,80003224 <kerneltrap+0x38>
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	748080e7          	jalr	1864(ra) # 800019e6 <myproc>
    800032a6:	4d18                	lw	a4,24(a0)
    800032a8:	4791                	li	a5,4
    800032aa:	f6f71de3          	bne	a4,a5,80003224 <kerneltrap+0x38>
    yield();
    800032ae:	fffff097          	auipc	ra,0xfffff
    800032b2:	c4a080e7          	jalr	-950(ra) # 80001ef8 <yield>
    800032b6:	b7bd                	j	80003224 <kerneltrap+0x38>

00000000800032b8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	e426                	sd	s1,8(sp)
    800032c0:	1000                	addi	s0,sp,32
    800032c2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	722080e7          	jalr	1826(ra) # 800019e6 <myproc>
  switch (n) {
    800032cc:	4795                	li	a5,5
    800032ce:	0497e163          	bltu	a5,s1,80003310 <argraw+0x58>
    800032d2:	048a                	slli	s1,s1,0x2
    800032d4:	00006717          	auipc	a4,0x6
    800032d8:	42470713          	addi	a4,a4,1060 # 800096f8 <states.0+0x170>
    800032dc:	94ba                	add	s1,s1,a4
    800032de:	409c                	lw	a5,0(s1)
    800032e0:	97ba                	add	a5,a5,a4
    800032e2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800032e4:	6d3c                	ld	a5,88(a0)
    800032e6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret
    return p->trapframe->a1;
    800032f2:	6d3c                	ld	a5,88(a0)
    800032f4:	7fa8                	ld	a0,120(a5)
    800032f6:	bfcd                	j	800032e8 <argraw+0x30>
    return p->trapframe->a2;
    800032f8:	6d3c                	ld	a5,88(a0)
    800032fa:	63c8                	ld	a0,128(a5)
    800032fc:	b7f5                	j	800032e8 <argraw+0x30>
    return p->trapframe->a3;
    800032fe:	6d3c                	ld	a5,88(a0)
    80003300:	67c8                	ld	a0,136(a5)
    80003302:	b7dd                	j	800032e8 <argraw+0x30>
    return p->trapframe->a4;
    80003304:	6d3c                	ld	a5,88(a0)
    80003306:	6bc8                	ld	a0,144(a5)
    80003308:	b7c5                	j	800032e8 <argraw+0x30>
    return p->trapframe->a5;
    8000330a:	6d3c                	ld	a5,88(a0)
    8000330c:	6fc8                	ld	a0,152(a5)
    8000330e:	bfe9                	j	800032e8 <argraw+0x30>
  panic("argraw");
    80003310:	00006517          	auipc	a0,0x6
    80003314:	3c050513          	addi	a0,a0,960 # 800096d0 <states.0+0x148>
    80003318:	ffffd097          	auipc	ra,0xffffd
    8000331c:	212080e7          	jalr	530(ra) # 8000052a <panic>

0000000080003320 <fetchaddr>:
{
    80003320:	1101                	addi	sp,sp,-32
    80003322:	ec06                	sd	ra,24(sp)
    80003324:	e822                	sd	s0,16(sp)
    80003326:	e426                	sd	s1,8(sp)
    80003328:	e04a                	sd	s2,0(sp)
    8000332a:	1000                	addi	s0,sp,32
    8000332c:	84aa                	mv	s1,a0
    8000332e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	6b6080e7          	jalr	1718(ra) # 800019e6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003338:	653c                	ld	a5,72(a0)
    8000333a:	02f4f863          	bgeu	s1,a5,8000336a <fetchaddr+0x4a>
    8000333e:	00848713          	addi	a4,s1,8
    80003342:	02e7e663          	bltu	a5,a4,8000336e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003346:	46a1                	li	a3,8
    80003348:	8626                	mv	a2,s1
    8000334a:	85ca                	mv	a1,s2
    8000334c:	6928                	ld	a0,80(a0)
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	3e4080e7          	jalr	996(ra) # 80001732 <copyin>
    80003356:	00a03533          	snez	a0,a0
    8000335a:	40a00533          	neg	a0,a0
}
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	64a2                	ld	s1,8(sp)
    80003364:	6902                	ld	s2,0(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret
    return -1;
    8000336a:	557d                	li	a0,-1
    8000336c:	bfcd                	j	8000335e <fetchaddr+0x3e>
    8000336e:	557d                	li	a0,-1
    80003370:	b7fd                	j	8000335e <fetchaddr+0x3e>

0000000080003372 <fetchstr>:
{
    80003372:	7179                	addi	sp,sp,-48
    80003374:	f406                	sd	ra,40(sp)
    80003376:	f022                	sd	s0,32(sp)
    80003378:	ec26                	sd	s1,24(sp)
    8000337a:	e84a                	sd	s2,16(sp)
    8000337c:	e44e                	sd	s3,8(sp)
    8000337e:	1800                	addi	s0,sp,48
    80003380:	892a                	mv	s2,a0
    80003382:	84ae                	mv	s1,a1
    80003384:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	660080e7          	jalr	1632(ra) # 800019e6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000338e:	86ce                	mv	a3,s3
    80003390:	864a                	mv	a2,s2
    80003392:	85a6                	mv	a1,s1
    80003394:	6928                	ld	a0,80(a0)
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	42a080e7          	jalr	1066(ra) # 800017c0 <copyinstr>
  if(err < 0)
    8000339e:	00054763          	bltz	a0,800033ac <fetchstr+0x3a>
  return strlen(buf);
    800033a2:	8526                	mv	a0,s1
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	ab0080e7          	jalr	-1360(ra) # 80000e54 <strlen>
}
    800033ac:	70a2                	ld	ra,40(sp)
    800033ae:	7402                	ld	s0,32(sp)
    800033b0:	64e2                	ld	s1,24(sp)
    800033b2:	6942                	ld	s2,16(sp)
    800033b4:	69a2                	ld	s3,8(sp)
    800033b6:	6145                	addi	sp,sp,48
    800033b8:	8082                	ret

00000000800033ba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800033ba:	1101                	addi	sp,sp,-32
    800033bc:	ec06                	sd	ra,24(sp)
    800033be:	e822                	sd	s0,16(sp)
    800033c0:	e426                	sd	s1,8(sp)
    800033c2:	1000                	addi	s0,sp,32
    800033c4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	ef2080e7          	jalr	-270(ra) # 800032b8 <argraw>
    800033ce:	c088                	sw	a0,0(s1)
  return 0;
}
    800033d0:	4501                	li	a0,0
    800033d2:	60e2                	ld	ra,24(sp)
    800033d4:	6442                	ld	s0,16(sp)
    800033d6:	64a2                	ld	s1,8(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret

00000000800033dc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800033dc:	1101                	addi	sp,sp,-32
    800033de:	ec06                	sd	ra,24(sp)
    800033e0:	e822                	sd	s0,16(sp)
    800033e2:	e426                	sd	s1,8(sp)
    800033e4:	1000                	addi	s0,sp,32
    800033e6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	ed0080e7          	jalr	-304(ra) # 800032b8 <argraw>
    800033f0:	e088                	sd	a0,0(s1)
  return 0;
}
    800033f2:	4501                	li	a0,0
    800033f4:	60e2                	ld	ra,24(sp)
    800033f6:	6442                	ld	s0,16(sp)
    800033f8:	64a2                	ld	s1,8(sp)
    800033fa:	6105                	addi	sp,sp,32
    800033fc:	8082                	ret

00000000800033fe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033fe:	1101                	addi	sp,sp,-32
    80003400:	ec06                	sd	ra,24(sp)
    80003402:	e822                	sd	s0,16(sp)
    80003404:	e426                	sd	s1,8(sp)
    80003406:	e04a                	sd	s2,0(sp)
    80003408:	1000                	addi	s0,sp,32
    8000340a:	84ae                	mv	s1,a1
    8000340c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	eaa080e7          	jalr	-342(ra) # 800032b8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003416:	864a                	mv	a2,s2
    80003418:	85a6                	mv	a1,s1
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	f58080e7          	jalr	-168(ra) # 80003372 <fetchstr>
}
    80003422:	60e2                	ld	ra,24(sp)
    80003424:	6442                	ld	s0,16(sp)
    80003426:	64a2                	ld	s1,8(sp)
    80003428:	6902                	ld	s2,0(sp)
    8000342a:	6105                	addi	sp,sp,32
    8000342c:	8082                	ret

000000008000342e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000342e:	1101                	addi	sp,sp,-32
    80003430:	ec06                	sd	ra,24(sp)
    80003432:	e822                	sd	s0,16(sp)
    80003434:	e426                	sd	s1,8(sp)
    80003436:	e04a                	sd	s2,0(sp)
    80003438:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000343a:	ffffe097          	auipc	ra,0xffffe
    8000343e:	5ac080e7          	jalr	1452(ra) # 800019e6 <myproc>
    80003442:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003444:	05853903          	ld	s2,88(a0)
    80003448:	0a893783          	ld	a5,168(s2)
    8000344c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003450:	37fd                	addiw	a5,a5,-1
    80003452:	4751                	li	a4,20
    80003454:	00f76f63          	bltu	a4,a5,80003472 <syscall+0x44>
    80003458:	00369713          	slli	a4,a3,0x3
    8000345c:	00006797          	auipc	a5,0x6
    80003460:	2b478793          	addi	a5,a5,692 # 80009710 <syscalls>
    80003464:	97ba                	add	a5,a5,a4
    80003466:	639c                	ld	a5,0(a5)
    80003468:	c789                	beqz	a5,80003472 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000346a:	9782                	jalr	a5
    8000346c:	06a93823          	sd	a0,112(s2)
    80003470:	a839                	j	8000348e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003472:	15848613          	addi	a2,s1,344
    80003476:	588c                	lw	a1,48(s1)
    80003478:	00006517          	auipc	a0,0x6
    8000347c:	26050513          	addi	a0,a0,608 # 800096d8 <states.0+0x150>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	0f4080e7          	jalr	244(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003488:	6cbc                	ld	a5,88(s1)
    8000348a:	577d                	li	a4,-1
    8000348c:	fbb8                	sd	a4,112(a5)
  }
}
    8000348e:	60e2                	ld	ra,24(sp)
    80003490:	6442                	ld	s0,16(sp)
    80003492:	64a2                	ld	s1,8(sp)
    80003494:	6902                	ld	s2,0(sp)
    80003496:	6105                	addi	sp,sp,32
    80003498:	8082                	ret

000000008000349a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000349a:	1101                	addi	sp,sp,-32
    8000349c:	ec06                	sd	ra,24(sp)
    8000349e:	e822                	sd	s0,16(sp)
    800034a0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800034a2:	fec40593          	addi	a1,s0,-20
    800034a6:	4501                	li	a0,0
    800034a8:	00000097          	auipc	ra,0x0
    800034ac:	f12080e7          	jalr	-238(ra) # 800033ba <argint>
    return -1;
    800034b0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034b2:	00054963          	bltz	a0,800034c4 <sys_exit+0x2a>
  exit(n);
    800034b6:	fec42503          	lw	a0,-20(s0)
    800034ba:	fffff097          	auipc	ra,0xfffff
    800034be:	028080e7          	jalr	40(ra) # 800024e2 <exit>
  return 0;  // not reached
    800034c2:	4781                	li	a5,0
}
    800034c4:	853e                	mv	a0,a5
    800034c6:	60e2                	ld	ra,24(sp)
    800034c8:	6442                	ld	s0,16(sp)
    800034ca:	6105                	addi	sp,sp,32
    800034cc:	8082                	ret

00000000800034ce <sys_getpid>:

uint64
sys_getpid(void)
{
    800034ce:	1141                	addi	sp,sp,-16
    800034d0:	e406                	sd	ra,8(sp)
    800034d2:	e022                	sd	s0,0(sp)
    800034d4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034d6:	ffffe097          	auipc	ra,0xffffe
    800034da:	510080e7          	jalr	1296(ra) # 800019e6 <myproc>
}
    800034de:	5908                	lw	a0,48(a0)
    800034e0:	60a2                	ld	ra,8(sp)
    800034e2:	6402                	ld	s0,0(sp)
    800034e4:	0141                	addi	sp,sp,16
    800034e6:	8082                	ret

00000000800034e8 <sys_fork>:

uint64
sys_fork(void)
{
    800034e8:	1141                	addi	sp,sp,-16
    800034ea:	e406                	sd	ra,8(sp)
    800034ec:	e022                	sd	s0,0(sp)
    800034ee:	0800                	addi	s0,sp,16
  return fork();
    800034f0:	fffff097          	auipc	ra,0xfffff
    800034f4:	dfe080e7          	jalr	-514(ra) # 800022ee <fork>
}
    800034f8:	60a2                	ld	ra,8(sp)
    800034fa:	6402                	ld	s0,0(sp)
    800034fc:	0141                	addi	sp,sp,16
    800034fe:	8082                	ret

0000000080003500 <sys_wait>:

uint64
sys_wait(void)
{
    80003500:	1101                	addi	sp,sp,-32
    80003502:	ec06                	sd	ra,24(sp)
    80003504:	e822                	sd	s0,16(sp)
    80003506:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003508:	fe840593          	addi	a1,s0,-24
    8000350c:	4501                	li	a0,0
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	ece080e7          	jalr	-306(ra) # 800033dc <argaddr>
    80003516:	87aa                	mv	a5,a0
    return -1;
    80003518:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000351a:	0007c863          	bltz	a5,8000352a <sys_wait+0x2a>
  return wait(p);
    8000351e:	fe843503          	ld	a0,-24(s0)
    80003522:	fffff097          	auipc	ra,0xfffff
    80003526:	0ae080e7          	jalr	174(ra) # 800025d0 <wait>
}
    8000352a:	60e2                	ld	ra,24(sp)
    8000352c:	6442                	ld	s0,16(sp)
    8000352e:	6105                	addi	sp,sp,32
    80003530:	8082                	ret

0000000080003532 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003532:	7179                	addi	sp,sp,-48
    80003534:	f406                	sd	ra,40(sp)
    80003536:	f022                	sd	s0,32(sp)
    80003538:	ec26                	sd	s1,24(sp)
    8000353a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000353c:	fdc40593          	addi	a1,s0,-36
    80003540:	4501                	li	a0,0
    80003542:	00000097          	auipc	ra,0x0
    80003546:	e78080e7          	jalr	-392(ra) # 800033ba <argint>
    return -1;
    8000354a:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000354c:	00054f63          	bltz	a0,8000356a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003550:	ffffe097          	auipc	ra,0xffffe
    80003554:	496080e7          	jalr	1174(ra) # 800019e6 <myproc>
    80003558:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000355a:	fdc42503          	lw	a0,-36(s0)
    8000355e:	ffffe097          	auipc	ra,0xffffe
    80003562:	7e2080e7          	jalr	2018(ra) # 80001d40 <growproc>
    80003566:	00054863          	bltz	a0,80003576 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000356a:	8526                	mv	a0,s1
    8000356c:	70a2                	ld	ra,40(sp)
    8000356e:	7402                	ld	s0,32(sp)
    80003570:	64e2                	ld	s1,24(sp)
    80003572:	6145                	addi	sp,sp,48
    80003574:	8082                	ret
    return -1;
    80003576:	54fd                	li	s1,-1
    80003578:	bfcd                	j	8000356a <sys_sbrk+0x38>

000000008000357a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000357a:	7139                	addi	sp,sp,-64
    8000357c:	fc06                	sd	ra,56(sp)
    8000357e:	f822                	sd	s0,48(sp)
    80003580:	f426                	sd	s1,40(sp)
    80003582:	f04a                	sd	s2,32(sp)
    80003584:	ec4e                	sd	s3,24(sp)
    80003586:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003588:	fcc40593          	addi	a1,s0,-52
    8000358c:	4501                	li	a0,0
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	e2c080e7          	jalr	-468(ra) # 800033ba <argint>
    return -1;
    80003596:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003598:	06054563          	bltz	a0,80003602 <sys_sleep+0x88>
  acquire(&tickslock);
    8000359c:	0001d517          	auipc	a0,0x1d
    800035a0:	f3450513          	addi	a0,a0,-204 # 800204d0 <tickslock>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	61e080e7          	jalr	1566(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    800035ac:	00007917          	auipc	s2,0x7
    800035b0:	a8492903          	lw	s2,-1404(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    800035b4:	fcc42783          	lw	a5,-52(s0)
    800035b8:	cf85                	beqz	a5,800035f0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800035ba:	0001d997          	auipc	s3,0x1d
    800035be:	f1698993          	addi	s3,s3,-234 # 800204d0 <tickslock>
    800035c2:	00007497          	auipc	s1,0x7
    800035c6:	a6e48493          	addi	s1,s1,-1426 # 8000a030 <ticks>
    if(myproc()->killed){
    800035ca:	ffffe097          	auipc	ra,0xffffe
    800035ce:	41c080e7          	jalr	1052(ra) # 800019e6 <myproc>
    800035d2:	551c                	lw	a5,40(a0)
    800035d4:	ef9d                	bnez	a5,80003612 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800035d6:	85ce                	mv	a1,s3
    800035d8:	8526                	mv	a0,s1
    800035da:	fffff097          	auipc	ra,0xfffff
    800035de:	95a080e7          	jalr	-1702(ra) # 80001f34 <sleep>
  while(ticks - ticks0 < n){
    800035e2:	409c                	lw	a5,0(s1)
    800035e4:	412787bb          	subw	a5,a5,s2
    800035e8:	fcc42703          	lw	a4,-52(s0)
    800035ec:	fce7efe3          	bltu	a5,a4,800035ca <sys_sleep+0x50>
  }
  release(&tickslock);
    800035f0:	0001d517          	auipc	a0,0x1d
    800035f4:	ee050513          	addi	a0,a0,-288 # 800204d0 <tickslock>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	690080e7          	jalr	1680(ra) # 80000c88 <release>
  return 0;
    80003600:	4781                	li	a5,0
}
    80003602:	853e                	mv	a0,a5
    80003604:	70e2                	ld	ra,56(sp)
    80003606:	7442                	ld	s0,48(sp)
    80003608:	74a2                	ld	s1,40(sp)
    8000360a:	7902                	ld	s2,32(sp)
    8000360c:	69e2                	ld	s3,24(sp)
    8000360e:	6121                	addi	sp,sp,64
    80003610:	8082                	ret
      release(&tickslock);
    80003612:	0001d517          	auipc	a0,0x1d
    80003616:	ebe50513          	addi	a0,a0,-322 # 800204d0 <tickslock>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	66e080e7          	jalr	1646(ra) # 80000c88 <release>
      return -1;
    80003622:	57fd                	li	a5,-1
    80003624:	bff9                	j	80003602 <sys_sleep+0x88>

0000000080003626 <sys_kill>:

uint64
sys_kill(void)
{
    80003626:	1101                	addi	sp,sp,-32
    80003628:	ec06                	sd	ra,24(sp)
    8000362a:	e822                	sd	s0,16(sp)
    8000362c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000362e:	fec40593          	addi	a1,s0,-20
    80003632:	4501                	li	a0,0
    80003634:	00000097          	auipc	ra,0x0
    80003638:	d86080e7          	jalr	-634(ra) # 800033ba <argint>
    8000363c:	87aa                	mv	a5,a0
    return -1;
    8000363e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003640:	0007c863          	bltz	a5,80003650 <sys_kill+0x2a>
  return kill(pid);
    80003644:	fec42503          	lw	a0,-20(s0)
    80003648:	fffff097          	auipc	ra,0xfffff
    8000364c:	a20080e7          	jalr	-1504(ra) # 80002068 <kill>
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	6105                	addi	sp,sp,32
    80003656:	8082                	ret

0000000080003658 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003658:	1101                	addi	sp,sp,-32
    8000365a:	ec06                	sd	ra,24(sp)
    8000365c:	e822                	sd	s0,16(sp)
    8000365e:	e426                	sd	s1,8(sp)
    80003660:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003662:	0001d517          	auipc	a0,0x1d
    80003666:	e6e50513          	addi	a0,a0,-402 # 800204d0 <tickslock>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	558080e7          	jalr	1368(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003672:	00007497          	auipc	s1,0x7
    80003676:	9be4a483          	lw	s1,-1602(s1) # 8000a030 <ticks>
  release(&tickslock);
    8000367a:	0001d517          	auipc	a0,0x1d
    8000367e:	e5650513          	addi	a0,a0,-426 # 800204d0 <tickslock>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	606080e7          	jalr	1542(ra) # 80000c88 <release>
  return xticks;
}
    8000368a:	02049513          	slli	a0,s1,0x20
    8000368e:	9101                	srli	a0,a0,0x20
    80003690:	60e2                	ld	ra,24(sp)
    80003692:	6442                	ld	s0,16(sp)
    80003694:	64a2                	ld	s1,8(sp)
    80003696:	6105                	addi	sp,sp,32
    80003698:	8082                	ret

000000008000369a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000369a:	7179                	addi	sp,sp,-48
    8000369c:	f406                	sd	ra,40(sp)
    8000369e:	f022                	sd	s0,32(sp)
    800036a0:	ec26                	sd	s1,24(sp)
    800036a2:	e84a                	sd	s2,16(sp)
    800036a4:	e44e                	sd	s3,8(sp)
    800036a6:	e052                	sd	s4,0(sp)
    800036a8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800036aa:	00006597          	auipc	a1,0x6
    800036ae:	11658593          	addi	a1,a1,278 # 800097c0 <syscalls+0xb0>
    800036b2:	0001d517          	auipc	a0,0x1d
    800036b6:	e3650513          	addi	a0,a0,-458 # 800204e8 <bcache>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	478080e7          	jalr	1144(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800036c2:	00025797          	auipc	a5,0x25
    800036c6:	e2678793          	addi	a5,a5,-474 # 800284e8 <bcache+0x8000>
    800036ca:	00025717          	auipc	a4,0x25
    800036ce:	08670713          	addi	a4,a4,134 # 80028750 <bcache+0x8268>
    800036d2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800036d6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036da:	0001d497          	auipc	s1,0x1d
    800036de:	e2648493          	addi	s1,s1,-474 # 80020500 <bcache+0x18>
    b->next = bcache.head.next;
    800036e2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036e4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800036e6:	00006a17          	auipc	s4,0x6
    800036ea:	0e2a0a13          	addi	s4,s4,226 # 800097c8 <syscalls+0xb8>
    b->next = bcache.head.next;
    800036ee:	2b893783          	ld	a5,696(s2)
    800036f2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036f4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036f8:	85d2                	mv	a1,s4
    800036fa:	01048513          	addi	a0,s1,16
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	7d4080e7          	jalr	2004(ra) # 80004ed2 <initsleeplock>
    bcache.head.next->prev = b;
    80003706:	2b893783          	ld	a5,696(s2)
    8000370a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000370c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003710:	45848493          	addi	s1,s1,1112
    80003714:	fd349de3          	bne	s1,s3,800036ee <binit+0x54>
  }
}
    80003718:	70a2                	ld	ra,40(sp)
    8000371a:	7402                	ld	s0,32(sp)
    8000371c:	64e2                	ld	s1,24(sp)
    8000371e:	6942                	ld	s2,16(sp)
    80003720:	69a2                	ld	s3,8(sp)
    80003722:	6a02                	ld	s4,0(sp)
    80003724:	6145                	addi	sp,sp,48
    80003726:	8082                	ret

0000000080003728 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003728:	7179                	addi	sp,sp,-48
    8000372a:	f406                	sd	ra,40(sp)
    8000372c:	f022                	sd	s0,32(sp)
    8000372e:	ec26                	sd	s1,24(sp)
    80003730:	e84a                	sd	s2,16(sp)
    80003732:	e44e                	sd	s3,8(sp)
    80003734:	1800                	addi	s0,sp,48
    80003736:	892a                	mv	s2,a0
    80003738:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000373a:	0001d517          	auipc	a0,0x1d
    8000373e:	dae50513          	addi	a0,a0,-594 # 800204e8 <bcache>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	480080e7          	jalr	1152(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000374a:	00025497          	auipc	s1,0x25
    8000374e:	0564b483          	ld	s1,86(s1) # 800287a0 <bcache+0x82b8>
    80003752:	00025797          	auipc	a5,0x25
    80003756:	ffe78793          	addi	a5,a5,-2 # 80028750 <bcache+0x8268>
    8000375a:	02f48f63          	beq	s1,a5,80003798 <bread+0x70>
    8000375e:	873e                	mv	a4,a5
    80003760:	a021                	j	80003768 <bread+0x40>
    80003762:	68a4                	ld	s1,80(s1)
    80003764:	02e48a63          	beq	s1,a4,80003798 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003768:	449c                	lw	a5,8(s1)
    8000376a:	ff279ce3          	bne	a5,s2,80003762 <bread+0x3a>
    8000376e:	44dc                	lw	a5,12(s1)
    80003770:	ff3799e3          	bne	a5,s3,80003762 <bread+0x3a>
      b->refcnt++;
    80003774:	40bc                	lw	a5,64(s1)
    80003776:	2785                	addiw	a5,a5,1
    80003778:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000377a:	0001d517          	auipc	a0,0x1d
    8000377e:	d6e50513          	addi	a0,a0,-658 # 800204e8 <bcache>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	506080e7          	jalr	1286(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    8000378a:	01048513          	addi	a0,s1,16
    8000378e:	00001097          	auipc	ra,0x1
    80003792:	77e080e7          	jalr	1918(ra) # 80004f0c <acquiresleep>
      return b;
    80003796:	a8b9                	j	800037f4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003798:	00025497          	auipc	s1,0x25
    8000379c:	0004b483          	ld	s1,0(s1) # 80028798 <bcache+0x82b0>
    800037a0:	00025797          	auipc	a5,0x25
    800037a4:	fb078793          	addi	a5,a5,-80 # 80028750 <bcache+0x8268>
    800037a8:	00f48863          	beq	s1,a5,800037b8 <bread+0x90>
    800037ac:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800037ae:	40bc                	lw	a5,64(s1)
    800037b0:	cf81                	beqz	a5,800037c8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037b2:	64a4                	ld	s1,72(s1)
    800037b4:	fee49de3          	bne	s1,a4,800037ae <bread+0x86>
  panic("bget: no buffers");
    800037b8:	00006517          	auipc	a0,0x6
    800037bc:	01850513          	addi	a0,a0,24 # 800097d0 <syscalls+0xc0>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	d6a080e7          	jalr	-662(ra) # 8000052a <panic>
      b->dev = dev;
    800037c8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800037cc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800037d0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800037d4:	4785                	li	a5,1
    800037d6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037d8:	0001d517          	auipc	a0,0x1d
    800037dc:	d1050513          	addi	a0,a0,-752 # 800204e8 <bcache>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	4a8080e7          	jalr	1192(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    800037e8:	01048513          	addi	a0,s1,16
    800037ec:	00001097          	auipc	ra,0x1
    800037f0:	720080e7          	jalr	1824(ra) # 80004f0c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037f4:	409c                	lw	a5,0(s1)
    800037f6:	cb89                	beqz	a5,80003808 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037f8:	8526                	mv	a0,s1
    800037fa:	70a2                	ld	ra,40(sp)
    800037fc:	7402                	ld	s0,32(sp)
    800037fe:	64e2                	ld	s1,24(sp)
    80003800:	6942                	ld	s2,16(sp)
    80003802:	69a2                	ld	s3,8(sp)
    80003804:	6145                	addi	sp,sp,48
    80003806:	8082                	ret
    virtio_disk_rw(b, 0);
    80003808:	4581                	li	a1,0
    8000380a:	8526                	mv	a0,s1
    8000380c:	00003097          	auipc	ra,0x3
    80003810:	51a080e7          	jalr	1306(ra) # 80006d26 <virtio_disk_rw>
    b->valid = 1;
    80003814:	4785                	li	a5,1
    80003816:	c09c                	sw	a5,0(s1)
  return b;
    80003818:	b7c5                	j	800037f8 <bread+0xd0>

000000008000381a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000381a:	1101                	addi	sp,sp,-32
    8000381c:	ec06                	sd	ra,24(sp)
    8000381e:	e822                	sd	s0,16(sp)
    80003820:	e426                	sd	s1,8(sp)
    80003822:	1000                	addi	s0,sp,32
    80003824:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003826:	0541                	addi	a0,a0,16
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	77e080e7          	jalr	1918(ra) # 80004fa6 <holdingsleep>
    80003830:	cd01                	beqz	a0,80003848 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003832:	4585                	li	a1,1
    80003834:	8526                	mv	a0,s1
    80003836:	00003097          	auipc	ra,0x3
    8000383a:	4f0080e7          	jalr	1264(ra) # 80006d26 <virtio_disk_rw>
}
    8000383e:	60e2                	ld	ra,24(sp)
    80003840:	6442                	ld	s0,16(sp)
    80003842:	64a2                	ld	s1,8(sp)
    80003844:	6105                	addi	sp,sp,32
    80003846:	8082                	ret
    panic("bwrite");
    80003848:	00006517          	auipc	a0,0x6
    8000384c:	fa050513          	addi	a0,a0,-96 # 800097e8 <syscalls+0xd8>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	cda080e7          	jalr	-806(ra) # 8000052a <panic>

0000000080003858 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003858:	1101                	addi	sp,sp,-32
    8000385a:	ec06                	sd	ra,24(sp)
    8000385c:	e822                	sd	s0,16(sp)
    8000385e:	e426                	sd	s1,8(sp)
    80003860:	e04a                	sd	s2,0(sp)
    80003862:	1000                	addi	s0,sp,32
    80003864:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003866:	01050913          	addi	s2,a0,16
    8000386a:	854a                	mv	a0,s2
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	73a080e7          	jalr	1850(ra) # 80004fa6 <holdingsleep>
    80003874:	c92d                	beqz	a0,800038e6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003876:	854a                	mv	a0,s2
    80003878:	00001097          	auipc	ra,0x1
    8000387c:	6ea080e7          	jalr	1770(ra) # 80004f62 <releasesleep>

  acquire(&bcache.lock);
    80003880:	0001d517          	auipc	a0,0x1d
    80003884:	c6850513          	addi	a0,a0,-920 # 800204e8 <bcache>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	33a080e7          	jalr	826(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003890:	40bc                	lw	a5,64(s1)
    80003892:	37fd                	addiw	a5,a5,-1
    80003894:	0007871b          	sext.w	a4,a5
    80003898:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000389a:	eb05                	bnez	a4,800038ca <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000389c:	68bc                	ld	a5,80(s1)
    8000389e:	64b8                	ld	a4,72(s1)
    800038a0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800038a2:	64bc                	ld	a5,72(s1)
    800038a4:	68b8                	ld	a4,80(s1)
    800038a6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800038a8:	00025797          	auipc	a5,0x25
    800038ac:	c4078793          	addi	a5,a5,-960 # 800284e8 <bcache+0x8000>
    800038b0:	2b87b703          	ld	a4,696(a5)
    800038b4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800038b6:	00025717          	auipc	a4,0x25
    800038ba:	e9a70713          	addi	a4,a4,-358 # 80028750 <bcache+0x8268>
    800038be:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800038c0:	2b87b703          	ld	a4,696(a5)
    800038c4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800038c6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800038ca:	0001d517          	auipc	a0,0x1d
    800038ce:	c1e50513          	addi	a0,a0,-994 # 800204e8 <bcache>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	3b6080e7          	jalr	950(ra) # 80000c88 <release>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6902                	ld	s2,0(sp)
    800038e2:	6105                	addi	sp,sp,32
    800038e4:	8082                	ret
    panic("brelse");
    800038e6:	00006517          	auipc	a0,0x6
    800038ea:	f0a50513          	addi	a0,a0,-246 # 800097f0 <syscalls+0xe0>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	c3c080e7          	jalr	-964(ra) # 8000052a <panic>

00000000800038f6 <bpin>:

void
bpin(struct buf *b) {
    800038f6:	1101                	addi	sp,sp,-32
    800038f8:	ec06                	sd	ra,24(sp)
    800038fa:	e822                	sd	s0,16(sp)
    800038fc:	e426                	sd	s1,8(sp)
    800038fe:	1000                	addi	s0,sp,32
    80003900:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003902:	0001d517          	auipc	a0,0x1d
    80003906:	be650513          	addi	a0,a0,-1050 # 800204e8 <bcache>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	2b8080e7          	jalr	696(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003912:	40bc                	lw	a5,64(s1)
    80003914:	2785                	addiw	a5,a5,1
    80003916:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003918:	0001d517          	auipc	a0,0x1d
    8000391c:	bd050513          	addi	a0,a0,-1072 # 800204e8 <bcache>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	368080e7          	jalr	872(ra) # 80000c88 <release>
}
    80003928:	60e2                	ld	ra,24(sp)
    8000392a:	6442                	ld	s0,16(sp)
    8000392c:	64a2                	ld	s1,8(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret

0000000080003932 <bunpin>:

void
bunpin(struct buf *b) {
    80003932:	1101                	addi	sp,sp,-32
    80003934:	ec06                	sd	ra,24(sp)
    80003936:	e822                	sd	s0,16(sp)
    80003938:	e426                	sd	s1,8(sp)
    8000393a:	1000                	addi	s0,sp,32
    8000393c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000393e:	0001d517          	auipc	a0,0x1d
    80003942:	baa50513          	addi	a0,a0,-1110 # 800204e8 <bcache>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	27c080e7          	jalr	636(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000394e:	40bc                	lw	a5,64(s1)
    80003950:	37fd                	addiw	a5,a5,-1
    80003952:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003954:	0001d517          	auipc	a0,0x1d
    80003958:	b9450513          	addi	a0,a0,-1132 # 800204e8 <bcache>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	32c080e7          	jalr	812(ra) # 80000c88 <release>
}
    80003964:	60e2                	ld	ra,24(sp)
    80003966:	6442                	ld	s0,16(sp)
    80003968:	64a2                	ld	s1,8(sp)
    8000396a:	6105                	addi	sp,sp,32
    8000396c:	8082                	ret

000000008000396e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000396e:	1101                	addi	sp,sp,-32
    80003970:	ec06                	sd	ra,24(sp)
    80003972:	e822                	sd	s0,16(sp)
    80003974:	e426                	sd	s1,8(sp)
    80003976:	e04a                	sd	s2,0(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000397c:	00d5d59b          	srliw	a1,a1,0xd
    80003980:	00025797          	auipc	a5,0x25
    80003984:	2447a783          	lw	a5,580(a5) # 80028bc4 <sb+0x1c>
    80003988:	9dbd                	addw	a1,a1,a5
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	d9e080e7          	jalr	-610(ra) # 80003728 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003992:	0074f713          	andi	a4,s1,7
    80003996:	4785                	li	a5,1
    80003998:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000399c:	14ce                	slli	s1,s1,0x33
    8000399e:	90d9                	srli	s1,s1,0x36
    800039a0:	00950733          	add	a4,a0,s1
    800039a4:	05874703          	lbu	a4,88(a4)
    800039a8:	00e7f6b3          	and	a3,a5,a4
    800039ac:	c69d                	beqz	a3,800039da <bfree+0x6c>
    800039ae:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800039b0:	94aa                	add	s1,s1,a0
    800039b2:	fff7c793          	not	a5,a5
    800039b6:	8ff9                	and	a5,a5,a4
    800039b8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	430080e7          	jalr	1072(ra) # 80004dec <log_write>
  brelse(bp);
    800039c4:	854a                	mv	a0,s2
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	e92080e7          	jalr	-366(ra) # 80003858 <brelse>
}
    800039ce:	60e2                	ld	ra,24(sp)
    800039d0:	6442                	ld	s0,16(sp)
    800039d2:	64a2                	ld	s1,8(sp)
    800039d4:	6902                	ld	s2,0(sp)
    800039d6:	6105                	addi	sp,sp,32
    800039d8:	8082                	ret
    panic("freeing free block");
    800039da:	00006517          	auipc	a0,0x6
    800039de:	e1e50513          	addi	a0,a0,-482 # 800097f8 <syscalls+0xe8>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	b48080e7          	jalr	-1208(ra) # 8000052a <panic>

00000000800039ea <balloc>:
{
    800039ea:	711d                	addi	sp,sp,-96
    800039ec:	ec86                	sd	ra,88(sp)
    800039ee:	e8a2                	sd	s0,80(sp)
    800039f0:	e4a6                	sd	s1,72(sp)
    800039f2:	e0ca                	sd	s2,64(sp)
    800039f4:	fc4e                	sd	s3,56(sp)
    800039f6:	f852                	sd	s4,48(sp)
    800039f8:	f456                	sd	s5,40(sp)
    800039fa:	f05a                	sd	s6,32(sp)
    800039fc:	ec5e                	sd	s7,24(sp)
    800039fe:	e862                	sd	s8,16(sp)
    80003a00:	e466                	sd	s9,8(sp)
    80003a02:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a04:	00025797          	auipc	a5,0x25
    80003a08:	1a87a783          	lw	a5,424(a5) # 80028bac <sb+0x4>
    80003a0c:	cbd1                	beqz	a5,80003aa0 <balloc+0xb6>
    80003a0e:	8baa                	mv	s7,a0
    80003a10:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a12:	00025b17          	auipc	s6,0x25
    80003a16:	196b0b13          	addi	s6,s6,406 # 80028ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a1a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a1c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a1e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a20:	6c89                	lui	s9,0x2
    80003a22:	a831                	j	80003a3e <balloc+0x54>
    brelse(bp);
    80003a24:	854a                	mv	a0,s2
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	e32080e7          	jalr	-462(ra) # 80003858 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a2e:	015c87bb          	addw	a5,s9,s5
    80003a32:	00078a9b          	sext.w	s5,a5
    80003a36:	004b2703          	lw	a4,4(s6)
    80003a3a:	06eaf363          	bgeu	s5,a4,80003aa0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003a3e:	41fad79b          	sraiw	a5,s5,0x1f
    80003a42:	0137d79b          	srliw	a5,a5,0x13
    80003a46:	015787bb          	addw	a5,a5,s5
    80003a4a:	40d7d79b          	sraiw	a5,a5,0xd
    80003a4e:	01cb2583          	lw	a1,28(s6)
    80003a52:	9dbd                	addw	a1,a1,a5
    80003a54:	855e                	mv	a0,s7
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	cd2080e7          	jalr	-814(ra) # 80003728 <bread>
    80003a5e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a60:	004b2503          	lw	a0,4(s6)
    80003a64:	000a849b          	sext.w	s1,s5
    80003a68:	8662                	mv	a2,s8
    80003a6a:	faa4fde3          	bgeu	s1,a0,80003a24 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a6e:	41f6579b          	sraiw	a5,a2,0x1f
    80003a72:	01d7d69b          	srliw	a3,a5,0x1d
    80003a76:	00c6873b          	addw	a4,a3,a2
    80003a7a:	00777793          	andi	a5,a4,7
    80003a7e:	9f95                	subw	a5,a5,a3
    80003a80:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a84:	4037571b          	sraiw	a4,a4,0x3
    80003a88:	00e906b3          	add	a3,s2,a4
    80003a8c:	0586c683          	lbu	a3,88(a3)
    80003a90:	00d7f5b3          	and	a1,a5,a3
    80003a94:	cd91                	beqz	a1,80003ab0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a96:	2605                	addiw	a2,a2,1
    80003a98:	2485                	addiw	s1,s1,1
    80003a9a:	fd4618e3          	bne	a2,s4,80003a6a <balloc+0x80>
    80003a9e:	b759                	j	80003a24 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003aa0:	00006517          	auipc	a0,0x6
    80003aa4:	d7050513          	addi	a0,a0,-656 # 80009810 <syscalls+0x100>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	a82080e7          	jalr	-1406(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003ab0:	974a                	add	a4,a4,s2
    80003ab2:	8fd5                	or	a5,a5,a3
    80003ab4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003ab8:	854a                	mv	a0,s2
    80003aba:	00001097          	auipc	ra,0x1
    80003abe:	332080e7          	jalr	818(ra) # 80004dec <log_write>
        brelse(bp);
    80003ac2:	854a                	mv	a0,s2
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	d94080e7          	jalr	-620(ra) # 80003858 <brelse>
  bp = bread(dev, bno);
    80003acc:	85a6                	mv	a1,s1
    80003ace:	855e                	mv	a0,s7
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	c58080e7          	jalr	-936(ra) # 80003728 <bread>
    80003ad8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003ada:	40000613          	li	a2,1024
    80003ade:	4581                	li	a1,0
    80003ae0:	05850513          	addi	a0,a0,88
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	1ec080e7          	jalr	492(ra) # 80000cd0 <memset>
  log_write(bp);
    80003aec:	854a                	mv	a0,s2
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	2fe080e7          	jalr	766(ra) # 80004dec <log_write>
  brelse(bp);
    80003af6:	854a                	mv	a0,s2
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	d60080e7          	jalr	-672(ra) # 80003858 <brelse>
}
    80003b00:	8526                	mv	a0,s1
    80003b02:	60e6                	ld	ra,88(sp)
    80003b04:	6446                	ld	s0,80(sp)
    80003b06:	64a6                	ld	s1,72(sp)
    80003b08:	6906                	ld	s2,64(sp)
    80003b0a:	79e2                	ld	s3,56(sp)
    80003b0c:	7a42                	ld	s4,48(sp)
    80003b0e:	7aa2                	ld	s5,40(sp)
    80003b10:	7b02                	ld	s6,32(sp)
    80003b12:	6be2                	ld	s7,24(sp)
    80003b14:	6c42                	ld	s8,16(sp)
    80003b16:	6ca2                	ld	s9,8(sp)
    80003b18:	6125                	addi	sp,sp,96
    80003b1a:	8082                	ret

0000000080003b1c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b1c:	7179                	addi	sp,sp,-48
    80003b1e:	f406                	sd	ra,40(sp)
    80003b20:	f022                	sd	s0,32(sp)
    80003b22:	ec26                	sd	s1,24(sp)
    80003b24:	e84a                	sd	s2,16(sp)
    80003b26:	e44e                	sd	s3,8(sp)
    80003b28:	e052                	sd	s4,0(sp)
    80003b2a:	1800                	addi	s0,sp,48
    80003b2c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b2e:	47ad                	li	a5,11
    80003b30:	04b7fe63          	bgeu	a5,a1,80003b8c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b34:	ff45849b          	addiw	s1,a1,-12
    80003b38:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b3c:	0ff00793          	li	a5,255
    80003b40:	0ae7e463          	bltu	a5,a4,80003be8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b44:	08052583          	lw	a1,128(a0)
    80003b48:	c5b5                	beqz	a1,80003bb4 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b4a:	00092503          	lw	a0,0(s2)
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	bda080e7          	jalr	-1062(ra) # 80003728 <bread>
    80003b56:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b58:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b5c:	02049713          	slli	a4,s1,0x20
    80003b60:	01e75593          	srli	a1,a4,0x1e
    80003b64:	00b784b3          	add	s1,a5,a1
    80003b68:	0004a983          	lw	s3,0(s1)
    80003b6c:	04098e63          	beqz	s3,80003bc8 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b70:	8552                	mv	a0,s4
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	ce6080e7          	jalr	-794(ra) # 80003858 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b7a:	854e                	mv	a0,s3
    80003b7c:	70a2                	ld	ra,40(sp)
    80003b7e:	7402                	ld	s0,32(sp)
    80003b80:	64e2                	ld	s1,24(sp)
    80003b82:	6942                	ld	s2,16(sp)
    80003b84:	69a2                	ld	s3,8(sp)
    80003b86:	6a02                	ld	s4,0(sp)
    80003b88:	6145                	addi	sp,sp,48
    80003b8a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b8c:	02059793          	slli	a5,a1,0x20
    80003b90:	01e7d593          	srli	a1,a5,0x1e
    80003b94:	00b504b3          	add	s1,a0,a1
    80003b98:	0504a983          	lw	s3,80(s1)
    80003b9c:	fc099fe3          	bnez	s3,80003b7a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003ba0:	4108                	lw	a0,0(a0)
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	e48080e7          	jalr	-440(ra) # 800039ea <balloc>
    80003baa:	0005099b          	sext.w	s3,a0
    80003bae:	0534a823          	sw	s3,80(s1)
    80003bb2:	b7e1                	j	80003b7a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003bb4:	4108                	lw	a0,0(a0)
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	e34080e7          	jalr	-460(ra) # 800039ea <balloc>
    80003bbe:	0005059b          	sext.w	a1,a0
    80003bc2:	08b92023          	sw	a1,128(s2)
    80003bc6:	b751                	j	80003b4a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003bc8:	00092503          	lw	a0,0(s2)
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	e1e080e7          	jalr	-482(ra) # 800039ea <balloc>
    80003bd4:	0005099b          	sext.w	s3,a0
    80003bd8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003bdc:	8552                	mv	a0,s4
    80003bde:	00001097          	auipc	ra,0x1
    80003be2:	20e080e7          	jalr	526(ra) # 80004dec <log_write>
    80003be6:	b769                	j	80003b70 <bmap+0x54>
  panic("bmap: out of range");
    80003be8:	00006517          	auipc	a0,0x6
    80003bec:	c4050513          	addi	a0,a0,-960 # 80009828 <syscalls+0x118>
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	93a080e7          	jalr	-1734(ra) # 8000052a <panic>

0000000080003bf8 <iget>:
{
    80003bf8:	7179                	addi	sp,sp,-48
    80003bfa:	f406                	sd	ra,40(sp)
    80003bfc:	f022                	sd	s0,32(sp)
    80003bfe:	ec26                	sd	s1,24(sp)
    80003c00:	e84a                	sd	s2,16(sp)
    80003c02:	e44e                	sd	s3,8(sp)
    80003c04:	e052                	sd	s4,0(sp)
    80003c06:	1800                	addi	s0,sp,48
    80003c08:	89aa                	mv	s3,a0
    80003c0a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c0c:	00025517          	auipc	a0,0x25
    80003c10:	fbc50513          	addi	a0,a0,-68 # 80028bc8 <itable>
    80003c14:	ffffd097          	auipc	ra,0xffffd
    80003c18:	fae080e7          	jalr	-82(ra) # 80000bc2 <acquire>
  empty = 0;
    80003c1c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c1e:	00025497          	auipc	s1,0x25
    80003c22:	fc248493          	addi	s1,s1,-62 # 80028be0 <itable+0x18>
    80003c26:	00027697          	auipc	a3,0x27
    80003c2a:	a4a68693          	addi	a3,a3,-1462 # 8002a670 <log>
    80003c2e:	a039                	j	80003c3c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c30:	02090b63          	beqz	s2,80003c66 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c34:	08848493          	addi	s1,s1,136
    80003c38:	02d48a63          	beq	s1,a3,80003c6c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c3c:	449c                	lw	a5,8(s1)
    80003c3e:	fef059e3          	blez	a5,80003c30 <iget+0x38>
    80003c42:	4098                	lw	a4,0(s1)
    80003c44:	ff3716e3          	bne	a4,s3,80003c30 <iget+0x38>
    80003c48:	40d8                	lw	a4,4(s1)
    80003c4a:	ff4713e3          	bne	a4,s4,80003c30 <iget+0x38>
      ip->ref++;
    80003c4e:	2785                	addiw	a5,a5,1
    80003c50:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c52:	00025517          	auipc	a0,0x25
    80003c56:	f7650513          	addi	a0,a0,-138 # 80028bc8 <itable>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	02e080e7          	jalr	46(ra) # 80000c88 <release>
      return ip;
    80003c62:	8926                	mv	s2,s1
    80003c64:	a03d                	j	80003c92 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c66:	f7f9                	bnez	a5,80003c34 <iget+0x3c>
    80003c68:	8926                	mv	s2,s1
    80003c6a:	b7e9                	j	80003c34 <iget+0x3c>
  if(empty == 0)
    80003c6c:	02090c63          	beqz	s2,80003ca4 <iget+0xac>
  ip->dev = dev;
    80003c70:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c74:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c78:	4785                	li	a5,1
    80003c7a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c7e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c82:	00025517          	auipc	a0,0x25
    80003c86:	f4650513          	addi	a0,a0,-186 # 80028bc8 <itable>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	ffe080e7          	jalr	-2(ra) # 80000c88 <release>
}
    80003c92:	854a                	mv	a0,s2
    80003c94:	70a2                	ld	ra,40(sp)
    80003c96:	7402                	ld	s0,32(sp)
    80003c98:	64e2                	ld	s1,24(sp)
    80003c9a:	6942                	ld	s2,16(sp)
    80003c9c:	69a2                	ld	s3,8(sp)
    80003c9e:	6a02                	ld	s4,0(sp)
    80003ca0:	6145                	addi	sp,sp,48
    80003ca2:	8082                	ret
    panic("iget: no inodes");
    80003ca4:	00006517          	auipc	a0,0x6
    80003ca8:	b9c50513          	addi	a0,a0,-1124 # 80009840 <syscalls+0x130>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	87e080e7          	jalr	-1922(ra) # 8000052a <panic>

0000000080003cb4 <fsinit>:
fsinit(int dev) {
    80003cb4:	7179                	addi	sp,sp,-48
    80003cb6:	f406                	sd	ra,40(sp)
    80003cb8:	f022                	sd	s0,32(sp)
    80003cba:	ec26                	sd	s1,24(sp)
    80003cbc:	e84a                	sd	s2,16(sp)
    80003cbe:	e44e                	sd	s3,8(sp)
    80003cc0:	1800                	addi	s0,sp,48
    80003cc2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003cc4:	4585                	li	a1,1
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	a62080e7          	jalr	-1438(ra) # 80003728 <bread>
    80003cce:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003cd0:	00025997          	auipc	s3,0x25
    80003cd4:	ed898993          	addi	s3,s3,-296 # 80028ba8 <sb>
    80003cd8:	02000613          	li	a2,32
    80003cdc:	05850593          	addi	a1,a0,88
    80003ce0:	854e                	mv	a0,s3
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	04a080e7          	jalr	74(ra) # 80000d2c <memmove>
  brelse(bp);
    80003cea:	8526                	mv	a0,s1
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	b6c080e7          	jalr	-1172(ra) # 80003858 <brelse>
  if(sb.magic != FSMAGIC)
    80003cf4:	0009a703          	lw	a4,0(s3)
    80003cf8:	102037b7          	lui	a5,0x10203
    80003cfc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d00:	02f71263          	bne	a4,a5,80003d24 <fsinit+0x70>
  initlog(dev, &sb);
    80003d04:	00025597          	auipc	a1,0x25
    80003d08:	ea458593          	addi	a1,a1,-348 # 80028ba8 <sb>
    80003d0c:	854a                	mv	a0,s2
    80003d0e:	00001097          	auipc	ra,0x1
    80003d12:	e60080e7          	jalr	-416(ra) # 80004b6e <initlog>
}
    80003d16:	70a2                	ld	ra,40(sp)
    80003d18:	7402                	ld	s0,32(sp)
    80003d1a:	64e2                	ld	s1,24(sp)
    80003d1c:	6942                	ld	s2,16(sp)
    80003d1e:	69a2                	ld	s3,8(sp)
    80003d20:	6145                	addi	sp,sp,48
    80003d22:	8082                	ret
    panic("invalid file system");
    80003d24:	00006517          	auipc	a0,0x6
    80003d28:	b2c50513          	addi	a0,a0,-1236 # 80009850 <syscalls+0x140>
    80003d2c:	ffffc097          	auipc	ra,0xffffc
    80003d30:	7fe080e7          	jalr	2046(ra) # 8000052a <panic>

0000000080003d34 <iinit>:
{
    80003d34:	7179                	addi	sp,sp,-48
    80003d36:	f406                	sd	ra,40(sp)
    80003d38:	f022                	sd	s0,32(sp)
    80003d3a:	ec26                	sd	s1,24(sp)
    80003d3c:	e84a                	sd	s2,16(sp)
    80003d3e:	e44e                	sd	s3,8(sp)
    80003d40:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d42:	00006597          	auipc	a1,0x6
    80003d46:	b2658593          	addi	a1,a1,-1242 # 80009868 <syscalls+0x158>
    80003d4a:	00025517          	auipc	a0,0x25
    80003d4e:	e7e50513          	addi	a0,a0,-386 # 80028bc8 <itable>
    80003d52:	ffffd097          	auipc	ra,0xffffd
    80003d56:	de0080e7          	jalr	-544(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d5a:	00025497          	auipc	s1,0x25
    80003d5e:	e9648493          	addi	s1,s1,-362 # 80028bf0 <itable+0x28>
    80003d62:	00027997          	auipc	s3,0x27
    80003d66:	91e98993          	addi	s3,s3,-1762 # 8002a680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d6a:	00006917          	auipc	s2,0x6
    80003d6e:	b0690913          	addi	s2,s2,-1274 # 80009870 <syscalls+0x160>
    80003d72:	85ca                	mv	a1,s2
    80003d74:	8526                	mv	a0,s1
    80003d76:	00001097          	auipc	ra,0x1
    80003d7a:	15c080e7          	jalr	348(ra) # 80004ed2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d7e:	08848493          	addi	s1,s1,136
    80003d82:	ff3498e3          	bne	s1,s3,80003d72 <iinit+0x3e>
}
    80003d86:	70a2                	ld	ra,40(sp)
    80003d88:	7402                	ld	s0,32(sp)
    80003d8a:	64e2                	ld	s1,24(sp)
    80003d8c:	6942                	ld	s2,16(sp)
    80003d8e:	69a2                	ld	s3,8(sp)
    80003d90:	6145                	addi	sp,sp,48
    80003d92:	8082                	ret

0000000080003d94 <ialloc>:
{
    80003d94:	715d                	addi	sp,sp,-80
    80003d96:	e486                	sd	ra,72(sp)
    80003d98:	e0a2                	sd	s0,64(sp)
    80003d9a:	fc26                	sd	s1,56(sp)
    80003d9c:	f84a                	sd	s2,48(sp)
    80003d9e:	f44e                	sd	s3,40(sp)
    80003da0:	f052                	sd	s4,32(sp)
    80003da2:	ec56                	sd	s5,24(sp)
    80003da4:	e85a                	sd	s6,16(sp)
    80003da6:	e45e                	sd	s7,8(sp)
    80003da8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003daa:	00025717          	auipc	a4,0x25
    80003dae:	e0a72703          	lw	a4,-502(a4) # 80028bb4 <sb+0xc>
    80003db2:	4785                	li	a5,1
    80003db4:	04e7fa63          	bgeu	a5,a4,80003e08 <ialloc+0x74>
    80003db8:	8aaa                	mv	s5,a0
    80003dba:	8bae                	mv	s7,a1
    80003dbc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003dbe:	00025a17          	auipc	s4,0x25
    80003dc2:	deaa0a13          	addi	s4,s4,-534 # 80028ba8 <sb>
    80003dc6:	00048b1b          	sext.w	s6,s1
    80003dca:	0044d793          	srli	a5,s1,0x4
    80003dce:	018a2583          	lw	a1,24(s4)
    80003dd2:	9dbd                	addw	a1,a1,a5
    80003dd4:	8556                	mv	a0,s5
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	952080e7          	jalr	-1710(ra) # 80003728 <bread>
    80003dde:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003de0:	05850993          	addi	s3,a0,88
    80003de4:	00f4f793          	andi	a5,s1,15
    80003de8:	079a                	slli	a5,a5,0x6
    80003dea:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003dec:	00099783          	lh	a5,0(s3)
    80003df0:	c785                	beqz	a5,80003e18 <ialloc+0x84>
    brelse(bp);
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	a66080e7          	jalr	-1434(ra) # 80003858 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dfa:	0485                	addi	s1,s1,1
    80003dfc:	00ca2703          	lw	a4,12(s4)
    80003e00:	0004879b          	sext.w	a5,s1
    80003e04:	fce7e1e3          	bltu	a5,a4,80003dc6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e08:	00006517          	auipc	a0,0x6
    80003e0c:	a7050513          	addi	a0,a0,-1424 # 80009878 <syscalls+0x168>
    80003e10:	ffffc097          	auipc	ra,0xffffc
    80003e14:	71a080e7          	jalr	1818(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003e18:	04000613          	li	a2,64
    80003e1c:	4581                	li	a1,0
    80003e1e:	854e                	mv	a0,s3
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	eb0080e7          	jalr	-336(ra) # 80000cd0 <memset>
      dip->type = type;
    80003e28:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e2c:	854a                	mv	a0,s2
    80003e2e:	00001097          	auipc	ra,0x1
    80003e32:	fbe080e7          	jalr	-66(ra) # 80004dec <log_write>
      brelse(bp);
    80003e36:	854a                	mv	a0,s2
    80003e38:	00000097          	auipc	ra,0x0
    80003e3c:	a20080e7          	jalr	-1504(ra) # 80003858 <brelse>
      return iget(dev, inum);
    80003e40:	85da                	mv	a1,s6
    80003e42:	8556                	mv	a0,s5
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	db4080e7          	jalr	-588(ra) # 80003bf8 <iget>
}
    80003e4c:	60a6                	ld	ra,72(sp)
    80003e4e:	6406                	ld	s0,64(sp)
    80003e50:	74e2                	ld	s1,56(sp)
    80003e52:	7942                	ld	s2,48(sp)
    80003e54:	79a2                	ld	s3,40(sp)
    80003e56:	7a02                	ld	s4,32(sp)
    80003e58:	6ae2                	ld	s5,24(sp)
    80003e5a:	6b42                	ld	s6,16(sp)
    80003e5c:	6ba2                	ld	s7,8(sp)
    80003e5e:	6161                	addi	sp,sp,80
    80003e60:	8082                	ret

0000000080003e62 <iupdate>:
{
    80003e62:	1101                	addi	sp,sp,-32
    80003e64:	ec06                	sd	ra,24(sp)
    80003e66:	e822                	sd	s0,16(sp)
    80003e68:	e426                	sd	s1,8(sp)
    80003e6a:	e04a                	sd	s2,0(sp)
    80003e6c:	1000                	addi	s0,sp,32
    80003e6e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e70:	415c                	lw	a5,4(a0)
    80003e72:	0047d79b          	srliw	a5,a5,0x4
    80003e76:	00025597          	auipc	a1,0x25
    80003e7a:	d4a5a583          	lw	a1,-694(a1) # 80028bc0 <sb+0x18>
    80003e7e:	9dbd                	addw	a1,a1,a5
    80003e80:	4108                	lw	a0,0(a0)
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	8a6080e7          	jalr	-1882(ra) # 80003728 <bread>
    80003e8a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e8c:	05850793          	addi	a5,a0,88
    80003e90:	40c8                	lw	a0,4(s1)
    80003e92:	893d                	andi	a0,a0,15
    80003e94:	051a                	slli	a0,a0,0x6
    80003e96:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e98:	04449703          	lh	a4,68(s1)
    80003e9c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ea0:	04649703          	lh	a4,70(s1)
    80003ea4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ea8:	04849703          	lh	a4,72(s1)
    80003eac:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003eb0:	04a49703          	lh	a4,74(s1)
    80003eb4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003eb8:	44f8                	lw	a4,76(s1)
    80003eba:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ebc:	03400613          	li	a2,52
    80003ec0:	05048593          	addi	a1,s1,80
    80003ec4:	0531                	addi	a0,a0,12
    80003ec6:	ffffd097          	auipc	ra,0xffffd
    80003eca:	e66080e7          	jalr	-410(ra) # 80000d2c <memmove>
  log_write(bp);
    80003ece:	854a                	mv	a0,s2
    80003ed0:	00001097          	auipc	ra,0x1
    80003ed4:	f1c080e7          	jalr	-228(ra) # 80004dec <log_write>
  brelse(bp);
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	97e080e7          	jalr	-1666(ra) # 80003858 <brelse>
}
    80003ee2:	60e2                	ld	ra,24(sp)
    80003ee4:	6442                	ld	s0,16(sp)
    80003ee6:	64a2                	ld	s1,8(sp)
    80003ee8:	6902                	ld	s2,0(sp)
    80003eea:	6105                	addi	sp,sp,32
    80003eec:	8082                	ret

0000000080003eee <idup>:
{
    80003eee:	1101                	addi	sp,sp,-32
    80003ef0:	ec06                	sd	ra,24(sp)
    80003ef2:	e822                	sd	s0,16(sp)
    80003ef4:	e426                	sd	s1,8(sp)
    80003ef6:	1000                	addi	s0,sp,32
    80003ef8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003efa:	00025517          	auipc	a0,0x25
    80003efe:	cce50513          	addi	a0,a0,-818 # 80028bc8 <itable>
    80003f02:	ffffd097          	auipc	ra,0xffffd
    80003f06:	cc0080e7          	jalr	-832(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003f0a:	449c                	lw	a5,8(s1)
    80003f0c:	2785                	addiw	a5,a5,1
    80003f0e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f10:	00025517          	auipc	a0,0x25
    80003f14:	cb850513          	addi	a0,a0,-840 # 80028bc8 <itable>
    80003f18:	ffffd097          	auipc	ra,0xffffd
    80003f1c:	d70080e7          	jalr	-656(ra) # 80000c88 <release>
}
    80003f20:	8526                	mv	a0,s1
    80003f22:	60e2                	ld	ra,24(sp)
    80003f24:	6442                	ld	s0,16(sp)
    80003f26:	64a2                	ld	s1,8(sp)
    80003f28:	6105                	addi	sp,sp,32
    80003f2a:	8082                	ret

0000000080003f2c <ilock>:
{
    80003f2c:	1101                	addi	sp,sp,-32
    80003f2e:	ec06                	sd	ra,24(sp)
    80003f30:	e822                	sd	s0,16(sp)
    80003f32:	e426                	sd	s1,8(sp)
    80003f34:	e04a                	sd	s2,0(sp)
    80003f36:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f38:	c115                	beqz	a0,80003f5c <ilock+0x30>
    80003f3a:	84aa                	mv	s1,a0
    80003f3c:	451c                	lw	a5,8(a0)
    80003f3e:	00f05f63          	blez	a5,80003f5c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f42:	0541                	addi	a0,a0,16
    80003f44:	00001097          	auipc	ra,0x1
    80003f48:	fc8080e7          	jalr	-56(ra) # 80004f0c <acquiresleep>
  if(ip->valid == 0){
    80003f4c:	40bc                	lw	a5,64(s1)
    80003f4e:	cf99                	beqz	a5,80003f6c <ilock+0x40>
}
    80003f50:	60e2                	ld	ra,24(sp)
    80003f52:	6442                	ld	s0,16(sp)
    80003f54:	64a2                	ld	s1,8(sp)
    80003f56:	6902                	ld	s2,0(sp)
    80003f58:	6105                	addi	sp,sp,32
    80003f5a:	8082                	ret
    panic("ilock");
    80003f5c:	00006517          	auipc	a0,0x6
    80003f60:	93450513          	addi	a0,a0,-1740 # 80009890 <syscalls+0x180>
    80003f64:	ffffc097          	auipc	ra,0xffffc
    80003f68:	5c6080e7          	jalr	1478(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f6c:	40dc                	lw	a5,4(s1)
    80003f6e:	0047d79b          	srliw	a5,a5,0x4
    80003f72:	00025597          	auipc	a1,0x25
    80003f76:	c4e5a583          	lw	a1,-946(a1) # 80028bc0 <sb+0x18>
    80003f7a:	9dbd                	addw	a1,a1,a5
    80003f7c:	4088                	lw	a0,0(s1)
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	7aa080e7          	jalr	1962(ra) # 80003728 <bread>
    80003f86:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f88:	05850593          	addi	a1,a0,88
    80003f8c:	40dc                	lw	a5,4(s1)
    80003f8e:	8bbd                	andi	a5,a5,15
    80003f90:	079a                	slli	a5,a5,0x6
    80003f92:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f94:	00059783          	lh	a5,0(a1)
    80003f98:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f9c:	00259783          	lh	a5,2(a1)
    80003fa0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003fa4:	00459783          	lh	a5,4(a1)
    80003fa8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003fac:	00659783          	lh	a5,6(a1)
    80003fb0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003fb4:	459c                	lw	a5,8(a1)
    80003fb6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003fb8:	03400613          	li	a2,52
    80003fbc:	05b1                	addi	a1,a1,12
    80003fbe:	05048513          	addi	a0,s1,80
    80003fc2:	ffffd097          	auipc	ra,0xffffd
    80003fc6:	d6a080e7          	jalr	-662(ra) # 80000d2c <memmove>
    brelse(bp);
    80003fca:	854a                	mv	a0,s2
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	88c080e7          	jalr	-1908(ra) # 80003858 <brelse>
    ip->valid = 1;
    80003fd4:	4785                	li	a5,1
    80003fd6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003fd8:	04449783          	lh	a5,68(s1)
    80003fdc:	fbb5                	bnez	a5,80003f50 <ilock+0x24>
      panic("ilock: no type");
    80003fde:	00006517          	auipc	a0,0x6
    80003fe2:	8ba50513          	addi	a0,a0,-1862 # 80009898 <syscalls+0x188>
    80003fe6:	ffffc097          	auipc	ra,0xffffc
    80003fea:	544080e7          	jalr	1348(ra) # 8000052a <panic>

0000000080003fee <iunlock>:
{
    80003fee:	1101                	addi	sp,sp,-32
    80003ff0:	ec06                	sd	ra,24(sp)
    80003ff2:	e822                	sd	s0,16(sp)
    80003ff4:	e426                	sd	s1,8(sp)
    80003ff6:	e04a                	sd	s2,0(sp)
    80003ff8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ffa:	c905                	beqz	a0,8000402a <iunlock+0x3c>
    80003ffc:	84aa                	mv	s1,a0
    80003ffe:	01050913          	addi	s2,a0,16
    80004002:	854a                	mv	a0,s2
    80004004:	00001097          	auipc	ra,0x1
    80004008:	fa2080e7          	jalr	-94(ra) # 80004fa6 <holdingsleep>
    8000400c:	cd19                	beqz	a0,8000402a <iunlock+0x3c>
    8000400e:	449c                	lw	a5,8(s1)
    80004010:	00f05d63          	blez	a5,8000402a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004014:	854a                	mv	a0,s2
    80004016:	00001097          	auipc	ra,0x1
    8000401a:	f4c080e7          	jalr	-180(ra) # 80004f62 <releasesleep>
}
    8000401e:	60e2                	ld	ra,24(sp)
    80004020:	6442                	ld	s0,16(sp)
    80004022:	64a2                	ld	s1,8(sp)
    80004024:	6902                	ld	s2,0(sp)
    80004026:	6105                	addi	sp,sp,32
    80004028:	8082                	ret
    panic("iunlock");
    8000402a:	00006517          	auipc	a0,0x6
    8000402e:	87e50513          	addi	a0,a0,-1922 # 800098a8 <syscalls+0x198>
    80004032:	ffffc097          	auipc	ra,0xffffc
    80004036:	4f8080e7          	jalr	1272(ra) # 8000052a <panic>

000000008000403a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000403a:	7179                	addi	sp,sp,-48
    8000403c:	f406                	sd	ra,40(sp)
    8000403e:	f022                	sd	s0,32(sp)
    80004040:	ec26                	sd	s1,24(sp)
    80004042:	e84a                	sd	s2,16(sp)
    80004044:	e44e                	sd	s3,8(sp)
    80004046:	e052                	sd	s4,0(sp)
    80004048:	1800                	addi	s0,sp,48
    8000404a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000404c:	05050493          	addi	s1,a0,80
    80004050:	08050913          	addi	s2,a0,128
    80004054:	a021                	j	8000405c <itrunc+0x22>
    80004056:	0491                	addi	s1,s1,4
    80004058:	01248d63          	beq	s1,s2,80004072 <itrunc+0x38>
    if(ip->addrs[i]){
    8000405c:	408c                	lw	a1,0(s1)
    8000405e:	dde5                	beqz	a1,80004056 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004060:	0009a503          	lw	a0,0(s3)
    80004064:	00000097          	auipc	ra,0x0
    80004068:	90a080e7          	jalr	-1782(ra) # 8000396e <bfree>
      ip->addrs[i] = 0;
    8000406c:	0004a023          	sw	zero,0(s1)
    80004070:	b7dd                	j	80004056 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004072:	0809a583          	lw	a1,128(s3)
    80004076:	e185                	bnez	a1,80004096 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004078:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000407c:	854e                	mv	a0,s3
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	de4080e7          	jalr	-540(ra) # 80003e62 <iupdate>
}
    80004086:	70a2                	ld	ra,40(sp)
    80004088:	7402                	ld	s0,32(sp)
    8000408a:	64e2                	ld	s1,24(sp)
    8000408c:	6942                	ld	s2,16(sp)
    8000408e:	69a2                	ld	s3,8(sp)
    80004090:	6a02                	ld	s4,0(sp)
    80004092:	6145                	addi	sp,sp,48
    80004094:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004096:	0009a503          	lw	a0,0(s3)
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	68e080e7          	jalr	1678(ra) # 80003728 <bread>
    800040a2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800040a4:	05850493          	addi	s1,a0,88
    800040a8:	45850913          	addi	s2,a0,1112
    800040ac:	a021                	j	800040b4 <itrunc+0x7a>
    800040ae:	0491                	addi	s1,s1,4
    800040b0:	01248b63          	beq	s1,s2,800040c6 <itrunc+0x8c>
      if(a[j])
    800040b4:	408c                	lw	a1,0(s1)
    800040b6:	dde5                	beqz	a1,800040ae <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800040b8:	0009a503          	lw	a0,0(s3)
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	8b2080e7          	jalr	-1870(ra) # 8000396e <bfree>
    800040c4:	b7ed                	j	800040ae <itrunc+0x74>
    brelse(bp);
    800040c6:	8552                	mv	a0,s4
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	790080e7          	jalr	1936(ra) # 80003858 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800040d0:	0809a583          	lw	a1,128(s3)
    800040d4:	0009a503          	lw	a0,0(s3)
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	896080e7          	jalr	-1898(ra) # 8000396e <bfree>
    ip->addrs[NDIRECT] = 0;
    800040e0:	0809a023          	sw	zero,128(s3)
    800040e4:	bf51                	j	80004078 <itrunc+0x3e>

00000000800040e6 <iput>:
{
    800040e6:	1101                	addi	sp,sp,-32
    800040e8:	ec06                	sd	ra,24(sp)
    800040ea:	e822                	sd	s0,16(sp)
    800040ec:	e426                	sd	s1,8(sp)
    800040ee:	e04a                	sd	s2,0(sp)
    800040f0:	1000                	addi	s0,sp,32
    800040f2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040f4:	00025517          	auipc	a0,0x25
    800040f8:	ad450513          	addi	a0,a0,-1324 # 80028bc8 <itable>
    800040fc:	ffffd097          	auipc	ra,0xffffd
    80004100:	ac6080e7          	jalr	-1338(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004104:	4498                	lw	a4,8(s1)
    80004106:	4785                	li	a5,1
    80004108:	02f70363          	beq	a4,a5,8000412e <iput+0x48>
  ip->ref--;
    8000410c:	449c                	lw	a5,8(s1)
    8000410e:	37fd                	addiw	a5,a5,-1
    80004110:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004112:	00025517          	auipc	a0,0x25
    80004116:	ab650513          	addi	a0,a0,-1354 # 80028bc8 <itable>
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	b6e080e7          	jalr	-1170(ra) # 80000c88 <release>
}
    80004122:	60e2                	ld	ra,24(sp)
    80004124:	6442                	ld	s0,16(sp)
    80004126:	64a2                	ld	s1,8(sp)
    80004128:	6902                	ld	s2,0(sp)
    8000412a:	6105                	addi	sp,sp,32
    8000412c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000412e:	40bc                	lw	a5,64(s1)
    80004130:	dff1                	beqz	a5,8000410c <iput+0x26>
    80004132:	04a49783          	lh	a5,74(s1)
    80004136:	fbf9                	bnez	a5,8000410c <iput+0x26>
    acquiresleep(&ip->lock);
    80004138:	01048913          	addi	s2,s1,16
    8000413c:	854a                	mv	a0,s2
    8000413e:	00001097          	auipc	ra,0x1
    80004142:	dce080e7          	jalr	-562(ra) # 80004f0c <acquiresleep>
    release(&itable.lock);
    80004146:	00025517          	auipc	a0,0x25
    8000414a:	a8250513          	addi	a0,a0,-1406 # 80028bc8 <itable>
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	b3a080e7          	jalr	-1222(ra) # 80000c88 <release>
    itrunc(ip);
    80004156:	8526                	mv	a0,s1
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	ee2080e7          	jalr	-286(ra) # 8000403a <itrunc>
    ip->type = 0;
    80004160:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004164:	8526                	mv	a0,s1
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	cfc080e7          	jalr	-772(ra) # 80003e62 <iupdate>
    ip->valid = 0;
    8000416e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004172:	854a                	mv	a0,s2
    80004174:	00001097          	auipc	ra,0x1
    80004178:	dee080e7          	jalr	-530(ra) # 80004f62 <releasesleep>
    acquire(&itable.lock);
    8000417c:	00025517          	auipc	a0,0x25
    80004180:	a4c50513          	addi	a0,a0,-1460 # 80028bc8 <itable>
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
    8000418c:	b741                	j	8000410c <iput+0x26>

000000008000418e <iunlockput>:
{
    8000418e:	1101                	addi	sp,sp,-32
    80004190:	ec06                	sd	ra,24(sp)
    80004192:	e822                	sd	s0,16(sp)
    80004194:	e426                	sd	s1,8(sp)
    80004196:	1000                	addi	s0,sp,32
    80004198:	84aa                	mv	s1,a0
  iunlock(ip);
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	e54080e7          	jalr	-428(ra) # 80003fee <iunlock>
  iput(ip);
    800041a2:	8526                	mv	a0,s1
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	f42080e7          	jalr	-190(ra) # 800040e6 <iput>
}
    800041ac:	60e2                	ld	ra,24(sp)
    800041ae:	6442                	ld	s0,16(sp)
    800041b0:	64a2                	ld	s1,8(sp)
    800041b2:	6105                	addi	sp,sp,32
    800041b4:	8082                	ret

00000000800041b6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800041b6:	1141                	addi	sp,sp,-16
    800041b8:	e422                	sd	s0,8(sp)
    800041ba:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800041bc:	411c                	lw	a5,0(a0)
    800041be:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800041c0:	415c                	lw	a5,4(a0)
    800041c2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800041c4:	04451783          	lh	a5,68(a0)
    800041c8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800041cc:	04a51783          	lh	a5,74(a0)
    800041d0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041d4:	04c56783          	lwu	a5,76(a0)
    800041d8:	e99c                	sd	a5,16(a1)
}
    800041da:	6422                	ld	s0,8(sp)
    800041dc:	0141                	addi	sp,sp,16
    800041de:	8082                	ret

00000000800041e0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041e0:	457c                	lw	a5,76(a0)
    800041e2:	0ed7e963          	bltu	a5,a3,800042d4 <readi+0xf4>
{
    800041e6:	7159                	addi	sp,sp,-112
    800041e8:	f486                	sd	ra,104(sp)
    800041ea:	f0a2                	sd	s0,96(sp)
    800041ec:	eca6                	sd	s1,88(sp)
    800041ee:	e8ca                	sd	s2,80(sp)
    800041f0:	e4ce                	sd	s3,72(sp)
    800041f2:	e0d2                	sd	s4,64(sp)
    800041f4:	fc56                	sd	s5,56(sp)
    800041f6:	f85a                	sd	s6,48(sp)
    800041f8:	f45e                	sd	s7,40(sp)
    800041fa:	f062                	sd	s8,32(sp)
    800041fc:	ec66                	sd	s9,24(sp)
    800041fe:	e86a                	sd	s10,16(sp)
    80004200:	e46e                	sd	s11,8(sp)
    80004202:	1880                	addi	s0,sp,112
    80004204:	8baa                	mv	s7,a0
    80004206:	8c2e                	mv	s8,a1
    80004208:	8ab2                	mv	s5,a2
    8000420a:	84b6                	mv	s1,a3
    8000420c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000420e:	9f35                	addw	a4,a4,a3
    return 0;
    80004210:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004212:	0ad76063          	bltu	a4,a3,800042b2 <readi+0xd2>
  if(off + n > ip->size)
    80004216:	00e7f463          	bgeu	a5,a4,8000421e <readi+0x3e>
    n = ip->size - off;
    8000421a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000421e:	0a0b0963          	beqz	s6,800042d0 <readi+0xf0>
    80004222:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004224:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004228:	5cfd                	li	s9,-1
    8000422a:	a82d                	j	80004264 <readi+0x84>
    8000422c:	020a1d93          	slli	s11,s4,0x20
    80004230:	020ddd93          	srli	s11,s11,0x20
    80004234:	05890793          	addi	a5,s2,88
    80004238:	86ee                	mv	a3,s11
    8000423a:	963e                	add	a2,a2,a5
    8000423c:	85d6                	mv	a1,s5
    8000423e:	8562                	mv	a0,s8
    80004240:	ffffe097          	auipc	ra,0xffffe
    80004244:	e9a080e7          	jalr	-358(ra) # 800020da <either_copyout>
    80004248:	05950d63          	beq	a0,s9,800042a2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000424c:	854a                	mv	a0,s2
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	60a080e7          	jalr	1546(ra) # 80003858 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004256:	013a09bb          	addw	s3,s4,s3
    8000425a:	009a04bb          	addw	s1,s4,s1
    8000425e:	9aee                	add	s5,s5,s11
    80004260:	0569f763          	bgeu	s3,s6,800042ae <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004264:	000ba903          	lw	s2,0(s7)
    80004268:	00a4d59b          	srliw	a1,s1,0xa
    8000426c:	855e                	mv	a0,s7
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	8ae080e7          	jalr	-1874(ra) # 80003b1c <bmap>
    80004276:	0005059b          	sext.w	a1,a0
    8000427a:	854a                	mv	a0,s2
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	4ac080e7          	jalr	1196(ra) # 80003728 <bread>
    80004284:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004286:	3ff4f613          	andi	a2,s1,1023
    8000428a:	40cd07bb          	subw	a5,s10,a2
    8000428e:	413b073b          	subw	a4,s6,s3
    80004292:	8a3e                	mv	s4,a5
    80004294:	2781                	sext.w	a5,a5
    80004296:	0007069b          	sext.w	a3,a4
    8000429a:	f8f6f9e3          	bgeu	a3,a5,8000422c <readi+0x4c>
    8000429e:	8a3a                	mv	s4,a4
    800042a0:	b771                	j	8000422c <readi+0x4c>
      brelse(bp);
    800042a2:	854a                	mv	a0,s2
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	5b4080e7          	jalr	1460(ra) # 80003858 <brelse>
      tot = -1;
    800042ac:	59fd                	li	s3,-1
  }
  return tot;
    800042ae:	0009851b          	sext.w	a0,s3
}
    800042b2:	70a6                	ld	ra,104(sp)
    800042b4:	7406                	ld	s0,96(sp)
    800042b6:	64e6                	ld	s1,88(sp)
    800042b8:	6946                	ld	s2,80(sp)
    800042ba:	69a6                	ld	s3,72(sp)
    800042bc:	6a06                	ld	s4,64(sp)
    800042be:	7ae2                	ld	s5,56(sp)
    800042c0:	7b42                	ld	s6,48(sp)
    800042c2:	7ba2                	ld	s7,40(sp)
    800042c4:	7c02                	ld	s8,32(sp)
    800042c6:	6ce2                	ld	s9,24(sp)
    800042c8:	6d42                	ld	s10,16(sp)
    800042ca:	6da2                	ld	s11,8(sp)
    800042cc:	6165                	addi	sp,sp,112
    800042ce:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042d0:	89da                	mv	s3,s6
    800042d2:	bff1                	j	800042ae <readi+0xce>
    return 0;
    800042d4:	4501                	li	a0,0
}
    800042d6:	8082                	ret

00000000800042d8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042d8:	457c                	lw	a5,76(a0)
    800042da:	10d7e863          	bltu	a5,a3,800043ea <writei+0x112>
{
    800042de:	7159                	addi	sp,sp,-112
    800042e0:	f486                	sd	ra,104(sp)
    800042e2:	f0a2                	sd	s0,96(sp)
    800042e4:	eca6                	sd	s1,88(sp)
    800042e6:	e8ca                	sd	s2,80(sp)
    800042e8:	e4ce                	sd	s3,72(sp)
    800042ea:	e0d2                	sd	s4,64(sp)
    800042ec:	fc56                	sd	s5,56(sp)
    800042ee:	f85a                	sd	s6,48(sp)
    800042f0:	f45e                	sd	s7,40(sp)
    800042f2:	f062                	sd	s8,32(sp)
    800042f4:	ec66                	sd	s9,24(sp)
    800042f6:	e86a                	sd	s10,16(sp)
    800042f8:	e46e                	sd	s11,8(sp)
    800042fa:	1880                	addi	s0,sp,112
    800042fc:	8b2a                	mv	s6,a0
    800042fe:	8c2e                	mv	s8,a1
    80004300:	8ab2                	mv	s5,a2
    80004302:	8936                	mv	s2,a3
    80004304:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004306:	00e687bb          	addw	a5,a3,a4
    8000430a:	0ed7e263          	bltu	a5,a3,800043ee <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000430e:	00043737          	lui	a4,0x43
    80004312:	0ef76063          	bltu	a4,a5,800043f2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004316:	0c0b8863          	beqz	s7,800043e6 <writei+0x10e>
    8000431a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000431c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004320:	5cfd                	li	s9,-1
    80004322:	a091                	j	80004366 <writei+0x8e>
    80004324:	02099d93          	slli	s11,s3,0x20
    80004328:	020ddd93          	srli	s11,s11,0x20
    8000432c:	05848793          	addi	a5,s1,88
    80004330:	86ee                	mv	a3,s11
    80004332:	8656                	mv	a2,s5
    80004334:	85e2                	mv	a1,s8
    80004336:	953e                	add	a0,a0,a5
    80004338:	ffffe097          	auipc	ra,0xffffe
    8000433c:	df8080e7          	jalr	-520(ra) # 80002130 <either_copyin>
    80004340:	07950263          	beq	a0,s9,800043a4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004344:	8526                	mv	a0,s1
    80004346:	00001097          	auipc	ra,0x1
    8000434a:	aa6080e7          	jalr	-1370(ra) # 80004dec <log_write>
    brelse(bp);
    8000434e:	8526                	mv	a0,s1
    80004350:	fffff097          	auipc	ra,0xfffff
    80004354:	508080e7          	jalr	1288(ra) # 80003858 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004358:	01498a3b          	addw	s4,s3,s4
    8000435c:	0129893b          	addw	s2,s3,s2
    80004360:	9aee                	add	s5,s5,s11
    80004362:	057a7663          	bgeu	s4,s7,800043ae <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004366:	000b2483          	lw	s1,0(s6)
    8000436a:	00a9559b          	srliw	a1,s2,0xa
    8000436e:	855a                	mv	a0,s6
    80004370:	fffff097          	auipc	ra,0xfffff
    80004374:	7ac080e7          	jalr	1964(ra) # 80003b1c <bmap>
    80004378:	0005059b          	sext.w	a1,a0
    8000437c:	8526                	mv	a0,s1
    8000437e:	fffff097          	auipc	ra,0xfffff
    80004382:	3aa080e7          	jalr	938(ra) # 80003728 <bread>
    80004386:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004388:	3ff97513          	andi	a0,s2,1023
    8000438c:	40ad07bb          	subw	a5,s10,a0
    80004390:	414b873b          	subw	a4,s7,s4
    80004394:	89be                	mv	s3,a5
    80004396:	2781                	sext.w	a5,a5
    80004398:	0007069b          	sext.w	a3,a4
    8000439c:	f8f6f4e3          	bgeu	a3,a5,80004324 <writei+0x4c>
    800043a0:	89ba                	mv	s3,a4
    800043a2:	b749                	j	80004324 <writei+0x4c>
      brelse(bp);
    800043a4:	8526                	mv	a0,s1
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	4b2080e7          	jalr	1202(ra) # 80003858 <brelse>
  }

  if(off > ip->size)
    800043ae:	04cb2783          	lw	a5,76(s6)
    800043b2:	0127f463          	bgeu	a5,s2,800043ba <writei+0xe2>
    ip->size = off;
    800043b6:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043ba:	855a                	mv	a0,s6
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	aa6080e7          	jalr	-1370(ra) # 80003e62 <iupdate>

  return tot;
    800043c4:	000a051b          	sext.w	a0,s4
}
    800043c8:	70a6                	ld	ra,104(sp)
    800043ca:	7406                	ld	s0,96(sp)
    800043cc:	64e6                	ld	s1,88(sp)
    800043ce:	6946                	ld	s2,80(sp)
    800043d0:	69a6                	ld	s3,72(sp)
    800043d2:	6a06                	ld	s4,64(sp)
    800043d4:	7ae2                	ld	s5,56(sp)
    800043d6:	7b42                	ld	s6,48(sp)
    800043d8:	7ba2                	ld	s7,40(sp)
    800043da:	7c02                	ld	s8,32(sp)
    800043dc:	6ce2                	ld	s9,24(sp)
    800043de:	6d42                	ld	s10,16(sp)
    800043e0:	6da2                	ld	s11,8(sp)
    800043e2:	6165                	addi	sp,sp,112
    800043e4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043e6:	8a5e                	mv	s4,s7
    800043e8:	bfc9                	j	800043ba <writei+0xe2>
    return -1;
    800043ea:	557d                	li	a0,-1
}
    800043ec:	8082                	ret
    return -1;
    800043ee:	557d                	li	a0,-1
    800043f0:	bfe1                	j	800043c8 <writei+0xf0>
    return -1;
    800043f2:	557d                	li	a0,-1
    800043f4:	bfd1                	j	800043c8 <writei+0xf0>

00000000800043f6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043f6:	1141                	addi	sp,sp,-16
    800043f8:	e406                	sd	ra,8(sp)
    800043fa:	e022                	sd	s0,0(sp)
    800043fc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043fe:	4639                	li	a2,14
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	9a8080e7          	jalr	-1624(ra) # 80000da8 <strncmp>
}
    80004408:	60a2                	ld	ra,8(sp)
    8000440a:	6402                	ld	s0,0(sp)
    8000440c:	0141                	addi	sp,sp,16
    8000440e:	8082                	ret

0000000080004410 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004410:	7139                	addi	sp,sp,-64
    80004412:	fc06                	sd	ra,56(sp)
    80004414:	f822                	sd	s0,48(sp)
    80004416:	f426                	sd	s1,40(sp)
    80004418:	f04a                	sd	s2,32(sp)
    8000441a:	ec4e                	sd	s3,24(sp)
    8000441c:	e852                	sd	s4,16(sp)
    8000441e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004420:	04451703          	lh	a4,68(a0)
    80004424:	4785                	li	a5,1
    80004426:	00f71a63          	bne	a4,a5,8000443a <dirlookup+0x2a>
    8000442a:	892a                	mv	s2,a0
    8000442c:	89ae                	mv	s3,a1
    8000442e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004430:	457c                	lw	a5,76(a0)
    80004432:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004434:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004436:	e79d                	bnez	a5,80004464 <dirlookup+0x54>
    80004438:	a8a5                	j	800044b0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000443a:	00005517          	auipc	a0,0x5
    8000443e:	47650513          	addi	a0,a0,1142 # 800098b0 <syscalls+0x1a0>
    80004442:	ffffc097          	auipc	ra,0xffffc
    80004446:	0e8080e7          	jalr	232(ra) # 8000052a <panic>
      panic("dirlookup read");
    8000444a:	00005517          	auipc	a0,0x5
    8000444e:	47e50513          	addi	a0,a0,1150 # 800098c8 <syscalls+0x1b8>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	0d8080e7          	jalr	216(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000445a:	24c1                	addiw	s1,s1,16
    8000445c:	04c92783          	lw	a5,76(s2)
    80004460:	04f4f763          	bgeu	s1,a5,800044ae <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004464:	4741                	li	a4,16
    80004466:	86a6                	mv	a3,s1
    80004468:	fc040613          	addi	a2,s0,-64
    8000446c:	4581                	li	a1,0
    8000446e:	854a                	mv	a0,s2
    80004470:	00000097          	auipc	ra,0x0
    80004474:	d70080e7          	jalr	-656(ra) # 800041e0 <readi>
    80004478:	47c1                	li	a5,16
    8000447a:	fcf518e3          	bne	a0,a5,8000444a <dirlookup+0x3a>
    if(de.inum == 0)
    8000447e:	fc045783          	lhu	a5,-64(s0)
    80004482:	dfe1                	beqz	a5,8000445a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004484:	fc240593          	addi	a1,s0,-62
    80004488:	854e                	mv	a0,s3
    8000448a:	00000097          	auipc	ra,0x0
    8000448e:	f6c080e7          	jalr	-148(ra) # 800043f6 <namecmp>
    80004492:	f561                	bnez	a0,8000445a <dirlookup+0x4a>
      if(poff)
    80004494:	000a0463          	beqz	s4,8000449c <dirlookup+0x8c>
        *poff = off;
    80004498:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000449c:	fc045583          	lhu	a1,-64(s0)
    800044a0:	00092503          	lw	a0,0(s2)
    800044a4:	fffff097          	auipc	ra,0xfffff
    800044a8:	754080e7          	jalr	1876(ra) # 80003bf8 <iget>
    800044ac:	a011                	j	800044b0 <dirlookup+0xa0>
  return 0;
    800044ae:	4501                	li	a0,0
}
    800044b0:	70e2                	ld	ra,56(sp)
    800044b2:	7442                	ld	s0,48(sp)
    800044b4:	74a2                	ld	s1,40(sp)
    800044b6:	7902                	ld	s2,32(sp)
    800044b8:	69e2                	ld	s3,24(sp)
    800044ba:	6a42                	ld	s4,16(sp)
    800044bc:	6121                	addi	sp,sp,64
    800044be:	8082                	ret

00000000800044c0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044c0:	711d                	addi	sp,sp,-96
    800044c2:	ec86                	sd	ra,88(sp)
    800044c4:	e8a2                	sd	s0,80(sp)
    800044c6:	e4a6                	sd	s1,72(sp)
    800044c8:	e0ca                	sd	s2,64(sp)
    800044ca:	fc4e                	sd	s3,56(sp)
    800044cc:	f852                	sd	s4,48(sp)
    800044ce:	f456                	sd	s5,40(sp)
    800044d0:	f05a                	sd	s6,32(sp)
    800044d2:	ec5e                	sd	s7,24(sp)
    800044d4:	e862                	sd	s8,16(sp)
    800044d6:	e466                	sd	s9,8(sp)
    800044d8:	1080                	addi	s0,sp,96
    800044da:	84aa                	mv	s1,a0
    800044dc:	8aae                	mv	s5,a1
    800044de:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044e0:	00054703          	lbu	a4,0(a0)
    800044e4:	02f00793          	li	a5,47
    800044e8:	02f70363          	beq	a4,a5,8000450e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044ec:	ffffd097          	auipc	ra,0xffffd
    800044f0:	4fa080e7          	jalr	1274(ra) # 800019e6 <myproc>
    800044f4:	15053503          	ld	a0,336(a0)
    800044f8:	00000097          	auipc	ra,0x0
    800044fc:	9f6080e7          	jalr	-1546(ra) # 80003eee <idup>
    80004500:	89aa                	mv	s3,a0
  while(*path == '/')
    80004502:	02f00913          	li	s2,47
  len = path - s;
    80004506:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004508:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000450a:	4b85                	li	s7,1
    8000450c:	a865                	j	800045c4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000450e:	4585                	li	a1,1
    80004510:	4505                	li	a0,1
    80004512:	fffff097          	auipc	ra,0xfffff
    80004516:	6e6080e7          	jalr	1766(ra) # 80003bf8 <iget>
    8000451a:	89aa                	mv	s3,a0
    8000451c:	b7dd                	j	80004502 <namex+0x42>
      iunlockput(ip);
    8000451e:	854e                	mv	a0,s3
    80004520:	00000097          	auipc	ra,0x0
    80004524:	c6e080e7          	jalr	-914(ra) # 8000418e <iunlockput>
      return 0;
    80004528:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000452a:	854e                	mv	a0,s3
    8000452c:	60e6                	ld	ra,88(sp)
    8000452e:	6446                	ld	s0,80(sp)
    80004530:	64a6                	ld	s1,72(sp)
    80004532:	6906                	ld	s2,64(sp)
    80004534:	79e2                	ld	s3,56(sp)
    80004536:	7a42                	ld	s4,48(sp)
    80004538:	7aa2                	ld	s5,40(sp)
    8000453a:	7b02                	ld	s6,32(sp)
    8000453c:	6be2                	ld	s7,24(sp)
    8000453e:	6c42                	ld	s8,16(sp)
    80004540:	6ca2                	ld	s9,8(sp)
    80004542:	6125                	addi	sp,sp,96
    80004544:	8082                	ret
      iunlock(ip);
    80004546:	854e                	mv	a0,s3
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	aa6080e7          	jalr	-1370(ra) # 80003fee <iunlock>
      return ip;
    80004550:	bfe9                	j	8000452a <namex+0x6a>
      iunlockput(ip);
    80004552:	854e                	mv	a0,s3
    80004554:	00000097          	auipc	ra,0x0
    80004558:	c3a080e7          	jalr	-966(ra) # 8000418e <iunlockput>
      return 0;
    8000455c:	89e6                	mv	s3,s9
    8000455e:	b7f1                	j	8000452a <namex+0x6a>
  len = path - s;
    80004560:	40b48633          	sub	a2,s1,a1
    80004564:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004568:	099c5463          	bge	s8,s9,800045f0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000456c:	4639                	li	a2,14
    8000456e:	8552                	mv	a0,s4
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	7bc080e7          	jalr	1980(ra) # 80000d2c <memmove>
  while(*path == '/')
    80004578:	0004c783          	lbu	a5,0(s1)
    8000457c:	01279763          	bne	a5,s2,8000458a <namex+0xca>
    path++;
    80004580:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004582:	0004c783          	lbu	a5,0(s1)
    80004586:	ff278de3          	beq	a5,s2,80004580 <namex+0xc0>
    ilock(ip);
    8000458a:	854e                	mv	a0,s3
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	9a0080e7          	jalr	-1632(ra) # 80003f2c <ilock>
    if(ip->type != T_DIR){
    80004594:	04499783          	lh	a5,68(s3)
    80004598:	f97793e3          	bne	a5,s7,8000451e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000459c:	000a8563          	beqz	s5,800045a6 <namex+0xe6>
    800045a0:	0004c783          	lbu	a5,0(s1)
    800045a4:	d3cd                	beqz	a5,80004546 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800045a6:	865a                	mv	a2,s6
    800045a8:	85d2                	mv	a1,s4
    800045aa:	854e                	mv	a0,s3
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	e64080e7          	jalr	-412(ra) # 80004410 <dirlookup>
    800045b4:	8caa                	mv	s9,a0
    800045b6:	dd51                	beqz	a0,80004552 <namex+0x92>
    iunlockput(ip);
    800045b8:	854e                	mv	a0,s3
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	bd4080e7          	jalr	-1068(ra) # 8000418e <iunlockput>
    ip = next;
    800045c2:	89e6                	mv	s3,s9
  while(*path == '/')
    800045c4:	0004c783          	lbu	a5,0(s1)
    800045c8:	05279763          	bne	a5,s2,80004616 <namex+0x156>
    path++;
    800045cc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045ce:	0004c783          	lbu	a5,0(s1)
    800045d2:	ff278de3          	beq	a5,s2,800045cc <namex+0x10c>
  if(*path == 0)
    800045d6:	c79d                	beqz	a5,80004604 <namex+0x144>
    path++;
    800045d8:	85a6                	mv	a1,s1
  len = path - s;
    800045da:	8cda                	mv	s9,s6
    800045dc:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800045de:	01278963          	beq	a5,s2,800045f0 <namex+0x130>
    800045e2:	dfbd                	beqz	a5,80004560 <namex+0xa0>
    path++;
    800045e4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800045e6:	0004c783          	lbu	a5,0(s1)
    800045ea:	ff279ce3          	bne	a5,s2,800045e2 <namex+0x122>
    800045ee:	bf8d                	j	80004560 <namex+0xa0>
    memmove(name, s, len);
    800045f0:	2601                	sext.w	a2,a2
    800045f2:	8552                	mv	a0,s4
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	738080e7          	jalr	1848(ra) # 80000d2c <memmove>
    name[len] = 0;
    800045fc:	9cd2                	add	s9,s9,s4
    800045fe:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004602:	bf9d                	j	80004578 <namex+0xb8>
  if(nameiparent){
    80004604:	f20a83e3          	beqz	s5,8000452a <namex+0x6a>
    iput(ip);
    80004608:	854e                	mv	a0,s3
    8000460a:	00000097          	auipc	ra,0x0
    8000460e:	adc080e7          	jalr	-1316(ra) # 800040e6 <iput>
    return 0;
    80004612:	4981                	li	s3,0
    80004614:	bf19                	j	8000452a <namex+0x6a>
  if(*path == 0)
    80004616:	d7fd                	beqz	a5,80004604 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004618:	0004c783          	lbu	a5,0(s1)
    8000461c:	85a6                	mv	a1,s1
    8000461e:	b7d1                	j	800045e2 <namex+0x122>

0000000080004620 <dirlink>:
{
    80004620:	7139                	addi	sp,sp,-64
    80004622:	fc06                	sd	ra,56(sp)
    80004624:	f822                	sd	s0,48(sp)
    80004626:	f426                	sd	s1,40(sp)
    80004628:	f04a                	sd	s2,32(sp)
    8000462a:	ec4e                	sd	s3,24(sp)
    8000462c:	e852                	sd	s4,16(sp)
    8000462e:	0080                	addi	s0,sp,64
    80004630:	892a                	mv	s2,a0
    80004632:	8a2e                	mv	s4,a1
    80004634:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004636:	4601                	li	a2,0
    80004638:	00000097          	auipc	ra,0x0
    8000463c:	dd8080e7          	jalr	-552(ra) # 80004410 <dirlookup>
    80004640:	e93d                	bnez	a0,800046b6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004642:	04c92483          	lw	s1,76(s2)
    80004646:	c49d                	beqz	s1,80004674 <dirlink+0x54>
    80004648:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000464a:	4741                	li	a4,16
    8000464c:	86a6                	mv	a3,s1
    8000464e:	fc040613          	addi	a2,s0,-64
    80004652:	4581                	li	a1,0
    80004654:	854a                	mv	a0,s2
    80004656:	00000097          	auipc	ra,0x0
    8000465a:	b8a080e7          	jalr	-1142(ra) # 800041e0 <readi>
    8000465e:	47c1                	li	a5,16
    80004660:	06f51163          	bne	a0,a5,800046c2 <dirlink+0xa2>
    if(de.inum == 0)
    80004664:	fc045783          	lhu	a5,-64(s0)
    80004668:	c791                	beqz	a5,80004674 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000466a:	24c1                	addiw	s1,s1,16
    8000466c:	04c92783          	lw	a5,76(s2)
    80004670:	fcf4ede3          	bltu	s1,a5,8000464a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004674:	4639                	li	a2,14
    80004676:	85d2                	mv	a1,s4
    80004678:	fc240513          	addi	a0,s0,-62
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	768080e7          	jalr	1896(ra) # 80000de4 <strncpy>
  de.inum = inum;
    80004684:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004688:	4741                	li	a4,16
    8000468a:	86a6                	mv	a3,s1
    8000468c:	fc040613          	addi	a2,s0,-64
    80004690:	4581                	li	a1,0
    80004692:	854a                	mv	a0,s2
    80004694:	00000097          	auipc	ra,0x0
    80004698:	c44080e7          	jalr	-956(ra) # 800042d8 <writei>
    8000469c:	872a                	mv	a4,a0
    8000469e:	47c1                	li	a5,16
  return 0;
    800046a0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046a2:	02f71863          	bne	a4,a5,800046d2 <dirlink+0xb2>
}
    800046a6:	70e2                	ld	ra,56(sp)
    800046a8:	7442                	ld	s0,48(sp)
    800046aa:	74a2                	ld	s1,40(sp)
    800046ac:	7902                	ld	s2,32(sp)
    800046ae:	69e2                	ld	s3,24(sp)
    800046b0:	6a42                	ld	s4,16(sp)
    800046b2:	6121                	addi	sp,sp,64
    800046b4:	8082                	ret
    iput(ip);
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	a30080e7          	jalr	-1488(ra) # 800040e6 <iput>
    return -1;
    800046be:	557d                	li	a0,-1
    800046c0:	b7dd                	j	800046a6 <dirlink+0x86>
      panic("dirlink read");
    800046c2:	00005517          	auipc	a0,0x5
    800046c6:	21650513          	addi	a0,a0,534 # 800098d8 <syscalls+0x1c8>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	e60080e7          	jalr	-416(ra) # 8000052a <panic>
    panic("dirlink");
    800046d2:	00005517          	auipc	a0,0x5
    800046d6:	38e50513          	addi	a0,a0,910 # 80009a60 <syscalls+0x350>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e50080e7          	jalr	-432(ra) # 8000052a <panic>

00000000800046e2 <namei>:

struct inode*
namei(char *path)
{
    800046e2:	1101                	addi	sp,sp,-32
    800046e4:	ec06                	sd	ra,24(sp)
    800046e6:	e822                	sd	s0,16(sp)
    800046e8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046ea:	fe040613          	addi	a2,s0,-32
    800046ee:	4581                	li	a1,0
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	dd0080e7          	jalr	-560(ra) # 800044c0 <namex>
}
    800046f8:	60e2                	ld	ra,24(sp)
    800046fa:	6442                	ld	s0,16(sp)
    800046fc:	6105                	addi	sp,sp,32
    800046fe:	8082                	ret

0000000080004700 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004700:	1141                	addi	sp,sp,-16
    80004702:	e406                	sd	ra,8(sp)
    80004704:	e022                	sd	s0,0(sp)
    80004706:	0800                	addi	s0,sp,16
    80004708:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000470a:	4585                	li	a1,1
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	db4080e7          	jalr	-588(ra) # 800044c0 <namex>
}
    80004714:	60a2                	ld	ra,8(sp)
    80004716:	6402                	ld	s0,0(sp)
    80004718:	0141                	addi	sp,sp,16
    8000471a:	8082                	ret

000000008000471c <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    8000471c:	1101                	addi	sp,sp,-32
    8000471e:	ec22                	sd	s0,24(sp)
    80004720:	1000                	addi	s0,sp,32
    80004722:	872a                	mv	a4,a0
    80004724:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    80004726:	00005797          	auipc	a5,0x5
    8000472a:	1c278793          	addi	a5,a5,450 # 800098e8 <syscalls+0x1d8>
    8000472e:	6394                	ld	a3,0(a5)
    80004730:	fed43023          	sd	a3,-32(s0)
    80004734:	0087d683          	lhu	a3,8(a5)
    80004738:	fed41423          	sh	a3,-24(s0)
    8000473c:	00a7c783          	lbu	a5,10(a5)
    80004740:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    80004744:	87ae                	mv	a5,a1
    if(i<0){
    80004746:	02074b63          	bltz	a4,8000477c <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    8000474a:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    8000474c:	4629                	li	a2,10
        ++p;
    8000474e:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004750:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    80004754:	feed                	bnez	a3,8000474e <itoa+0x32>
    *p = '\0';
    80004756:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    8000475a:	4629                	li	a2,10
    8000475c:	17fd                	addi	a5,a5,-1
    8000475e:	02c766bb          	remw	a3,a4,a2
    80004762:	ff040593          	addi	a1,s0,-16
    80004766:	96ae                	add	a3,a3,a1
    80004768:	ff06c683          	lbu	a3,-16(a3)
    8000476c:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004770:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004774:	f765                	bnez	a4,8000475c <itoa+0x40>
    return b;
}
    80004776:	6462                	ld	s0,24(sp)
    80004778:	6105                	addi	sp,sp,32
    8000477a:	8082                	ret
        *p++ = '-';
    8000477c:	00158793          	addi	a5,a1,1
    80004780:	02d00693          	li	a3,45
    80004784:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004788:	40e0073b          	negw	a4,a4
    8000478c:	bf7d                	j	8000474a <itoa+0x2e>

000000008000478e <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    8000478e:	711d                	addi	sp,sp,-96
    80004790:	ec86                	sd	ra,88(sp)
    80004792:	e8a2                	sd	s0,80(sp)
    80004794:	e4a6                	sd	s1,72(sp)
    80004796:	e0ca                	sd	s2,64(sp)
    80004798:	1080                	addi	s0,sp,96
    8000479a:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000479c:	4619                	li	a2,6
    8000479e:	00005597          	auipc	a1,0x5
    800047a2:	15a58593          	addi	a1,a1,346 # 800098f8 <syscalls+0x1e8>
    800047a6:	fd040513          	addi	a0,s0,-48
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	582080e7          	jalr	1410(ra) # 80000d2c <memmove>
  itoa(p->pid, path+ 6);
    800047b2:	fd640593          	addi	a1,s0,-42
    800047b6:	5888                	lw	a0,48(s1)
    800047b8:	00000097          	auipc	ra,0x0
    800047bc:	f64080e7          	jalr	-156(ra) # 8000471c <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    800047c0:	1684b503          	ld	a0,360(s1)
    800047c4:	16050763          	beqz	a0,80004932 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    800047c8:	00001097          	auipc	ra,0x1
    800047cc:	918080e7          	jalr	-1768(ra) # 800050e0 <fileclose>

  begin_op();
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	444080e7          	jalr	1092(ra) # 80004c14 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    800047d8:	fb040593          	addi	a1,s0,-80
    800047dc:	fd040513          	addi	a0,s0,-48
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	f20080e7          	jalr	-224(ra) # 80004700 <nameiparent>
    800047e8:	892a                	mv	s2,a0
    800047ea:	cd69                	beqz	a0,800048c4 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	740080e7          	jalr	1856(ra) # 80003f2c <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800047f4:	00005597          	auipc	a1,0x5
    800047f8:	10c58593          	addi	a1,a1,268 # 80009900 <syscalls+0x1f0>
    800047fc:	fb040513          	addi	a0,s0,-80
    80004800:	00000097          	auipc	ra,0x0
    80004804:	bf6080e7          	jalr	-1034(ra) # 800043f6 <namecmp>
    80004808:	c57d                	beqz	a0,800048f6 <removeSwapFile+0x168>
    8000480a:	00005597          	auipc	a1,0x5
    8000480e:	0fe58593          	addi	a1,a1,254 # 80009908 <syscalls+0x1f8>
    80004812:	fb040513          	addi	a0,s0,-80
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	be0080e7          	jalr	-1056(ra) # 800043f6 <namecmp>
    8000481e:	cd61                	beqz	a0,800048f6 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80004820:	fac40613          	addi	a2,s0,-84
    80004824:	fb040593          	addi	a1,s0,-80
    80004828:	854a                	mv	a0,s2
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	be6080e7          	jalr	-1050(ra) # 80004410 <dirlookup>
    80004832:	84aa                	mv	s1,a0
    80004834:	c169                	beqz	a0,800048f6 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	6f6080e7          	jalr	1782(ra) # 80003f2c <ilock>

  if(ip->nlink < 1)
    8000483e:	04a49783          	lh	a5,74(s1)
    80004842:	08f05763          	blez	a5,800048d0 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004846:	04449703          	lh	a4,68(s1)
    8000484a:	4785                	li	a5,1
    8000484c:	08f70a63          	beq	a4,a5,800048e0 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004850:	4641                	li	a2,16
    80004852:	4581                	li	a1,0
    80004854:	fc040513          	addi	a0,s0,-64
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	478080e7          	jalr	1144(ra) # 80000cd0 <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004860:	4741                	li	a4,16
    80004862:	fac42683          	lw	a3,-84(s0)
    80004866:	fc040613          	addi	a2,s0,-64
    8000486a:	4581                	li	a1,0
    8000486c:	854a                	mv	a0,s2
    8000486e:	00000097          	auipc	ra,0x0
    80004872:	a6a080e7          	jalr	-1430(ra) # 800042d8 <writei>
    80004876:	47c1                	li	a5,16
    80004878:	08f51a63          	bne	a0,a5,8000490c <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    8000487c:	04449703          	lh	a4,68(s1)
    80004880:	4785                	li	a5,1
    80004882:	08f70d63          	beq	a4,a5,8000491c <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004886:	854a                	mv	a0,s2
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	906080e7          	jalr	-1786(ra) # 8000418e <iunlockput>

  ip->nlink--;
    80004890:	04a4d783          	lhu	a5,74(s1)
    80004894:	37fd                	addiw	a5,a5,-1
    80004896:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000489a:	8526                	mv	a0,s1
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	5c6080e7          	jalr	1478(ra) # 80003e62 <iupdate>
  iunlockput(ip);
    800048a4:	8526                	mv	a0,s1
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	8e8080e7          	jalr	-1816(ra) # 8000418e <iunlockput>

  end_op();
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	3e6080e7          	jalr	998(ra) # 80004c94 <end_op>

  return 0;
    800048b6:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    800048b8:	60e6                	ld	ra,88(sp)
    800048ba:	6446                	ld	s0,80(sp)
    800048bc:	64a6                	ld	s1,72(sp)
    800048be:	6906                	ld	s2,64(sp)
    800048c0:	6125                	addi	sp,sp,96
    800048c2:	8082                	ret
    end_op();
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	3d0080e7          	jalr	976(ra) # 80004c94 <end_op>
    return -1;
    800048cc:	557d                	li	a0,-1
    800048ce:	b7ed                	j	800048b8 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    800048d0:	00005517          	auipc	a0,0x5
    800048d4:	04050513          	addi	a0,a0,64 # 80009910 <syscalls+0x200>
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	c52080e7          	jalr	-942(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800048e0:	8526                	mv	a0,s1
    800048e2:	00002097          	auipc	ra,0x2
    800048e6:	864080e7          	jalr	-1948(ra) # 80006146 <isdirempty>
    800048ea:	f13d                	bnez	a0,80004850 <removeSwapFile+0xc2>
    iunlockput(ip);
    800048ec:	8526                	mv	a0,s1
    800048ee:	00000097          	auipc	ra,0x0
    800048f2:	8a0080e7          	jalr	-1888(ra) # 8000418e <iunlockput>
    iunlockput(dp);
    800048f6:	854a                	mv	a0,s2
    800048f8:	00000097          	auipc	ra,0x0
    800048fc:	896080e7          	jalr	-1898(ra) # 8000418e <iunlockput>
    end_op();
    80004900:	00000097          	auipc	ra,0x0
    80004904:	394080e7          	jalr	916(ra) # 80004c94 <end_op>
    return -1;
    80004908:	557d                	li	a0,-1
    8000490a:	b77d                	j	800048b8 <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000490c:	00005517          	auipc	a0,0x5
    80004910:	01c50513          	addi	a0,a0,28 # 80009928 <syscalls+0x218>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	c16080e7          	jalr	-1002(ra) # 8000052a <panic>
    dp->nlink--;
    8000491c:	04a95783          	lhu	a5,74(s2)
    80004920:	37fd                	addiw	a5,a5,-1
    80004922:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004926:	854a                	mv	a0,s2
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	53a080e7          	jalr	1338(ra) # 80003e62 <iupdate>
    80004930:	bf99                	j	80004886 <removeSwapFile+0xf8>
    return -1;
    80004932:	557d                	li	a0,-1
    80004934:	b751                	j	800048b8 <removeSwapFile+0x12a>

0000000080004936 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    80004936:	7179                	addi	sp,sp,-48
    80004938:	f406                	sd	ra,40(sp)
    8000493a:	f022                	sd	s0,32(sp)
    8000493c:	ec26                	sd	s1,24(sp)
    8000493e:	e84a                	sd	s2,16(sp)
    80004940:	1800                	addi	s0,sp,48
    80004942:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004944:	4619                	li	a2,6
    80004946:	00005597          	auipc	a1,0x5
    8000494a:	fb258593          	addi	a1,a1,-78 # 800098f8 <syscalls+0x1e8>
    8000494e:	fd040513          	addi	a0,s0,-48
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	3da080e7          	jalr	986(ra) # 80000d2c <memmove>
  itoa(p->pid, path+ 6);
    8000495a:	fd640593          	addi	a1,s0,-42
    8000495e:	5888                	lw	a0,48(s1)
    80004960:	00000097          	auipc	ra,0x0
    80004964:	dbc080e7          	jalr	-580(ra) # 8000471c <itoa>

  begin_op();
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	2ac080e7          	jalr	684(ra) # 80004c14 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004970:	4681                	li	a3,0
    80004972:	4601                	li	a2,0
    80004974:	4589                	li	a1,2
    80004976:	fd040513          	addi	a0,s0,-48
    8000497a:	00002097          	auipc	ra,0x2
    8000497e:	9c0080e7          	jalr	-1600(ra) # 8000633a <create>
    80004982:	892a                	mv	s2,a0
  iunlock(in);
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	66a080e7          	jalr	1642(ra) # 80003fee <iunlock>
  p->swapFile = filealloc();
    8000498c:	00000097          	auipc	ra,0x0
    80004990:	698080e7          	jalr	1688(ra) # 80005024 <filealloc>
    80004994:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004998:	cd1d                	beqz	a0,800049d6 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000499a:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    8000499e:	1684b703          	ld	a4,360(s1)
    800049a2:	4789                	li	a5,2
    800049a4:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    800049a6:	1684b703          	ld	a4,360(s1)
    800049aa:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    800049ae:	1684b703          	ld	a4,360(s1)
    800049b2:	4685                	li	a3,1
    800049b4:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    800049b8:	1684b703          	ld	a4,360(s1)
    800049bc:	00f704a3          	sb	a5,9(a4)
    end_op();
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	2d4080e7          	jalr	724(ra) # 80004c94 <end_op>

    return 0;
}
    800049c8:	4501                	li	a0,0
    800049ca:	70a2                	ld	ra,40(sp)
    800049cc:	7402                	ld	s0,32(sp)
    800049ce:	64e2                	ld	s1,24(sp)
    800049d0:	6942                	ld	s2,16(sp)
    800049d2:	6145                	addi	sp,sp,48
    800049d4:	8082                	ret
    panic("no slot for files on /store");
    800049d6:	00005517          	auipc	a0,0x5
    800049da:	f6250513          	addi	a0,a0,-158 # 80009938 <syscalls+0x228>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	b4c080e7          	jalr	-1204(ra) # 8000052a <panic>

00000000800049e6 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800049e6:	1141                	addi	sp,sp,-16
    800049e8:	e406                	sd	ra,8(sp)
    800049ea:	e022                	sd	s0,0(sp)
    800049ec:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800049ee:	16853783          	ld	a5,360(a0)
    800049f2:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    800049f4:	8636                	mv	a2,a3
    800049f6:	16853503          	ld	a0,360(a0)
    800049fa:	00001097          	auipc	ra,0x1
    800049fe:	ad8080e7          	jalr	-1320(ra) # 800054d2 <kfilewrite>
}
    80004a02:	60a2                	ld	ra,8(sp)
    80004a04:	6402                	ld	s0,0(sp)
    80004a06:	0141                	addi	sp,sp,16
    80004a08:	8082                	ret

0000000080004a0a <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a0a:	1141                	addi	sp,sp,-16
    80004a0c:	e406                	sd	ra,8(sp)
    80004a0e:	e022                	sd	s0,0(sp)
    80004a10:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a12:	16853783          	ld	a5,360(a0)
    80004a16:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004a18:	8636                	mv	a2,a3
    80004a1a:	16853503          	ld	a0,360(a0)
    80004a1e:	00001097          	auipc	ra,0x1
    80004a22:	9f2080e7          	jalr	-1550(ra) # 80005410 <kfileread>
    80004a26:	60a2                	ld	ra,8(sp)
    80004a28:	6402                	ld	s0,0(sp)
    80004a2a:	0141                	addi	sp,sp,16
    80004a2c:	8082                	ret

0000000080004a2e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a2e:	1101                	addi	sp,sp,-32
    80004a30:	ec06                	sd	ra,24(sp)
    80004a32:	e822                	sd	s0,16(sp)
    80004a34:	e426                	sd	s1,8(sp)
    80004a36:	e04a                	sd	s2,0(sp)
    80004a38:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004a3a:	00026917          	auipc	s2,0x26
    80004a3e:	c3690913          	addi	s2,s2,-970 # 8002a670 <log>
    80004a42:	01892583          	lw	a1,24(s2)
    80004a46:	02892503          	lw	a0,40(s2)
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	cde080e7          	jalr	-802(ra) # 80003728 <bread>
    80004a52:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004a54:	02c92683          	lw	a3,44(s2)
    80004a58:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004a5a:	02d05863          	blez	a3,80004a8a <write_head+0x5c>
    80004a5e:	00026797          	auipc	a5,0x26
    80004a62:	c4278793          	addi	a5,a5,-958 # 8002a6a0 <log+0x30>
    80004a66:	05c50713          	addi	a4,a0,92
    80004a6a:	36fd                	addiw	a3,a3,-1
    80004a6c:	02069613          	slli	a2,a3,0x20
    80004a70:	01e65693          	srli	a3,a2,0x1e
    80004a74:	00026617          	auipc	a2,0x26
    80004a78:	c3060613          	addi	a2,a2,-976 # 8002a6a4 <log+0x34>
    80004a7c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004a7e:	4390                	lw	a2,0(a5)
    80004a80:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a82:	0791                	addi	a5,a5,4
    80004a84:	0711                	addi	a4,a4,4
    80004a86:	fed79ce3          	bne	a5,a3,80004a7e <write_head+0x50>
  }
  bwrite(buf);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	fffff097          	auipc	ra,0xfffff
    80004a90:	d8e080e7          	jalr	-626(ra) # 8000381a <bwrite>
  brelse(buf);
    80004a94:	8526                	mv	a0,s1
    80004a96:	fffff097          	auipc	ra,0xfffff
    80004a9a:	dc2080e7          	jalr	-574(ra) # 80003858 <brelse>
}
    80004a9e:	60e2                	ld	ra,24(sp)
    80004aa0:	6442                	ld	s0,16(sp)
    80004aa2:	64a2                	ld	s1,8(sp)
    80004aa4:	6902                	ld	s2,0(sp)
    80004aa6:	6105                	addi	sp,sp,32
    80004aa8:	8082                	ret

0000000080004aaa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004aaa:	00026797          	auipc	a5,0x26
    80004aae:	bf27a783          	lw	a5,-1038(a5) # 8002a69c <log+0x2c>
    80004ab2:	0af05d63          	blez	a5,80004b6c <install_trans+0xc2>
{
    80004ab6:	7139                	addi	sp,sp,-64
    80004ab8:	fc06                	sd	ra,56(sp)
    80004aba:	f822                	sd	s0,48(sp)
    80004abc:	f426                	sd	s1,40(sp)
    80004abe:	f04a                	sd	s2,32(sp)
    80004ac0:	ec4e                	sd	s3,24(sp)
    80004ac2:	e852                	sd	s4,16(sp)
    80004ac4:	e456                	sd	s5,8(sp)
    80004ac6:	e05a                	sd	s6,0(sp)
    80004ac8:	0080                	addi	s0,sp,64
    80004aca:	8b2a                	mv	s6,a0
    80004acc:	00026a97          	auipc	s5,0x26
    80004ad0:	bd4a8a93          	addi	s5,s5,-1068 # 8002a6a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ad4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004ad6:	00026997          	auipc	s3,0x26
    80004ada:	b9a98993          	addi	s3,s3,-1126 # 8002a670 <log>
    80004ade:	a00d                	j	80004b00 <install_trans+0x56>
    brelse(lbuf);
    80004ae0:	854a                	mv	a0,s2
    80004ae2:	fffff097          	auipc	ra,0xfffff
    80004ae6:	d76080e7          	jalr	-650(ra) # 80003858 <brelse>
    brelse(dbuf);
    80004aea:	8526                	mv	a0,s1
    80004aec:	fffff097          	auipc	ra,0xfffff
    80004af0:	d6c080e7          	jalr	-660(ra) # 80003858 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004af4:	2a05                	addiw	s4,s4,1
    80004af6:	0a91                	addi	s5,s5,4
    80004af8:	02c9a783          	lw	a5,44(s3)
    80004afc:	04fa5e63          	bge	s4,a5,80004b58 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b00:	0189a583          	lw	a1,24(s3)
    80004b04:	014585bb          	addw	a1,a1,s4
    80004b08:	2585                	addiw	a1,a1,1
    80004b0a:	0289a503          	lw	a0,40(s3)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	c1a080e7          	jalr	-998(ra) # 80003728 <bread>
    80004b16:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b18:	000aa583          	lw	a1,0(s5)
    80004b1c:	0289a503          	lw	a0,40(s3)
    80004b20:	fffff097          	auipc	ra,0xfffff
    80004b24:	c08080e7          	jalr	-1016(ra) # 80003728 <bread>
    80004b28:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b2a:	40000613          	li	a2,1024
    80004b2e:	05890593          	addi	a1,s2,88
    80004b32:	05850513          	addi	a0,a0,88
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	1f6080e7          	jalr	502(ra) # 80000d2c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004b3e:	8526                	mv	a0,s1
    80004b40:	fffff097          	auipc	ra,0xfffff
    80004b44:	cda080e7          	jalr	-806(ra) # 8000381a <bwrite>
    if(recovering == 0)
    80004b48:	f80b1ce3          	bnez	s6,80004ae0 <install_trans+0x36>
      bunpin(dbuf);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	de4080e7          	jalr	-540(ra) # 80003932 <bunpin>
    80004b56:	b769                	j	80004ae0 <install_trans+0x36>
}
    80004b58:	70e2                	ld	ra,56(sp)
    80004b5a:	7442                	ld	s0,48(sp)
    80004b5c:	74a2                	ld	s1,40(sp)
    80004b5e:	7902                	ld	s2,32(sp)
    80004b60:	69e2                	ld	s3,24(sp)
    80004b62:	6a42                	ld	s4,16(sp)
    80004b64:	6aa2                	ld	s5,8(sp)
    80004b66:	6b02                	ld	s6,0(sp)
    80004b68:	6121                	addi	sp,sp,64
    80004b6a:	8082                	ret
    80004b6c:	8082                	ret

0000000080004b6e <initlog>:
{
    80004b6e:	7179                	addi	sp,sp,-48
    80004b70:	f406                	sd	ra,40(sp)
    80004b72:	f022                	sd	s0,32(sp)
    80004b74:	ec26                	sd	s1,24(sp)
    80004b76:	e84a                	sd	s2,16(sp)
    80004b78:	e44e                	sd	s3,8(sp)
    80004b7a:	1800                	addi	s0,sp,48
    80004b7c:	892a                	mv	s2,a0
    80004b7e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004b80:	00026497          	auipc	s1,0x26
    80004b84:	af048493          	addi	s1,s1,-1296 # 8002a670 <log>
    80004b88:	00005597          	auipc	a1,0x5
    80004b8c:	dd058593          	addi	a1,a1,-560 # 80009958 <syscalls+0x248>
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	fa0080e7          	jalr	-96(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004b9a:	0149a583          	lw	a1,20(s3)
    80004b9e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004ba0:	0109a783          	lw	a5,16(s3)
    80004ba4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004ba6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004baa:	854a                	mv	a0,s2
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	b7c080e7          	jalr	-1156(ra) # 80003728 <bread>
  log.lh.n = lh->n;
    80004bb4:	4d34                	lw	a3,88(a0)
    80004bb6:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004bb8:	02d05663          	blez	a3,80004be4 <initlog+0x76>
    80004bbc:	05c50793          	addi	a5,a0,92
    80004bc0:	00026717          	auipc	a4,0x26
    80004bc4:	ae070713          	addi	a4,a4,-1312 # 8002a6a0 <log+0x30>
    80004bc8:	36fd                	addiw	a3,a3,-1
    80004bca:	02069613          	slli	a2,a3,0x20
    80004bce:	01e65693          	srli	a3,a2,0x1e
    80004bd2:	06050613          	addi	a2,a0,96
    80004bd6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004bd8:	4390                	lw	a2,0(a5)
    80004bda:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004bdc:	0791                	addi	a5,a5,4
    80004bde:	0711                	addi	a4,a4,4
    80004be0:	fed79ce3          	bne	a5,a3,80004bd8 <initlog+0x6a>
  brelse(buf);
    80004be4:	fffff097          	auipc	ra,0xfffff
    80004be8:	c74080e7          	jalr	-908(ra) # 80003858 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004bec:	4505                	li	a0,1
    80004bee:	00000097          	auipc	ra,0x0
    80004bf2:	ebc080e7          	jalr	-324(ra) # 80004aaa <install_trans>
  log.lh.n = 0;
    80004bf6:	00026797          	auipc	a5,0x26
    80004bfa:	aa07a323          	sw	zero,-1370(a5) # 8002a69c <log+0x2c>
  write_head(); // clear the log
    80004bfe:	00000097          	auipc	ra,0x0
    80004c02:	e30080e7          	jalr	-464(ra) # 80004a2e <write_head>
}
    80004c06:	70a2                	ld	ra,40(sp)
    80004c08:	7402                	ld	s0,32(sp)
    80004c0a:	64e2                	ld	s1,24(sp)
    80004c0c:	6942                	ld	s2,16(sp)
    80004c0e:	69a2                	ld	s3,8(sp)
    80004c10:	6145                	addi	sp,sp,48
    80004c12:	8082                	ret

0000000080004c14 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c14:	1101                	addi	sp,sp,-32
    80004c16:	ec06                	sd	ra,24(sp)
    80004c18:	e822                	sd	s0,16(sp)
    80004c1a:	e426                	sd	s1,8(sp)
    80004c1c:	e04a                	sd	s2,0(sp)
    80004c1e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c20:	00026517          	auipc	a0,0x26
    80004c24:	a5050513          	addi	a0,a0,-1456 # 8002a670 <log>
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	f9a080e7          	jalr	-102(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004c30:	00026497          	auipc	s1,0x26
    80004c34:	a4048493          	addi	s1,s1,-1472 # 8002a670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c38:	4979                	li	s2,30
    80004c3a:	a039                	j	80004c48 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004c3c:	85a6                	mv	a1,s1
    80004c3e:	8526                	mv	a0,s1
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	2f4080e7          	jalr	756(ra) # 80001f34 <sleep>
    if(log.committing){
    80004c48:	50dc                	lw	a5,36(s1)
    80004c4a:	fbed                	bnez	a5,80004c3c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c4c:	509c                	lw	a5,32(s1)
    80004c4e:	0017871b          	addiw	a4,a5,1
    80004c52:	0007069b          	sext.w	a3,a4
    80004c56:	0027179b          	slliw	a5,a4,0x2
    80004c5a:	9fb9                	addw	a5,a5,a4
    80004c5c:	0017979b          	slliw	a5,a5,0x1
    80004c60:	54d8                	lw	a4,44(s1)
    80004c62:	9fb9                	addw	a5,a5,a4
    80004c64:	00f95963          	bge	s2,a5,80004c76 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004c68:	85a6                	mv	a1,s1
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	2c8080e7          	jalr	712(ra) # 80001f34 <sleep>
    80004c74:	bfd1                	j	80004c48 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004c76:	00026517          	auipc	a0,0x26
    80004c7a:	9fa50513          	addi	a0,a0,-1542 # 8002a670 <log>
    80004c7e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	008080e7          	jalr	8(ra) # 80000c88 <release>
      break;
    }
  }
}
    80004c88:	60e2                	ld	ra,24(sp)
    80004c8a:	6442                	ld	s0,16(sp)
    80004c8c:	64a2                	ld	s1,8(sp)
    80004c8e:	6902                	ld	s2,0(sp)
    80004c90:	6105                	addi	sp,sp,32
    80004c92:	8082                	ret

0000000080004c94 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004c94:	7139                	addi	sp,sp,-64
    80004c96:	fc06                	sd	ra,56(sp)
    80004c98:	f822                	sd	s0,48(sp)
    80004c9a:	f426                	sd	s1,40(sp)
    80004c9c:	f04a                	sd	s2,32(sp)
    80004c9e:	ec4e                	sd	s3,24(sp)
    80004ca0:	e852                	sd	s4,16(sp)
    80004ca2:	e456                	sd	s5,8(sp)
    80004ca4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004ca6:	00026497          	auipc	s1,0x26
    80004caa:	9ca48493          	addi	s1,s1,-1590 # 8002a670 <log>
    80004cae:	8526                	mv	a0,s1
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	f12080e7          	jalr	-238(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004cb8:	509c                	lw	a5,32(s1)
    80004cba:	37fd                	addiw	a5,a5,-1
    80004cbc:	0007891b          	sext.w	s2,a5
    80004cc0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004cc2:	50dc                	lw	a5,36(s1)
    80004cc4:	e7b9                	bnez	a5,80004d12 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004cc6:	04091e63          	bnez	s2,80004d22 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004cca:	00026497          	auipc	s1,0x26
    80004cce:	9a648493          	addi	s1,s1,-1626 # 8002a670 <log>
    80004cd2:	4785                	li	a5,1
    80004cd4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	fb0080e7          	jalr	-80(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004ce0:	54dc                	lw	a5,44(s1)
    80004ce2:	06f04763          	bgtz	a5,80004d50 <end_op+0xbc>
    acquire(&log.lock);
    80004ce6:	00026497          	auipc	s1,0x26
    80004cea:	98a48493          	addi	s1,s1,-1654 # 8002a670 <log>
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	ed2080e7          	jalr	-302(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004cf8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	29a080e7          	jalr	666(ra) # 80001f98 <wakeup>
    release(&log.lock);
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	f80080e7          	jalr	-128(ra) # 80000c88 <release>
}
    80004d10:	a03d                	j	80004d3e <end_op+0xaa>
    panic("log.committing");
    80004d12:	00005517          	auipc	a0,0x5
    80004d16:	c4e50513          	addi	a0,a0,-946 # 80009960 <syscalls+0x250>
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	810080e7          	jalr	-2032(ra) # 8000052a <panic>
    wakeup(&log);
    80004d22:	00026497          	auipc	s1,0x26
    80004d26:	94e48493          	addi	s1,s1,-1714 # 8002a670 <log>
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	ffffd097          	auipc	ra,0xffffd
    80004d30:	26c080e7          	jalr	620(ra) # 80001f98 <wakeup>
  release(&log.lock);
    80004d34:	8526                	mv	a0,s1
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	f52080e7          	jalr	-174(ra) # 80000c88 <release>
}
    80004d3e:	70e2                	ld	ra,56(sp)
    80004d40:	7442                	ld	s0,48(sp)
    80004d42:	74a2                	ld	s1,40(sp)
    80004d44:	7902                	ld	s2,32(sp)
    80004d46:	69e2                	ld	s3,24(sp)
    80004d48:	6a42                	ld	s4,16(sp)
    80004d4a:	6aa2                	ld	s5,8(sp)
    80004d4c:	6121                	addi	sp,sp,64
    80004d4e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d50:	00026a97          	auipc	s5,0x26
    80004d54:	950a8a93          	addi	s5,s5,-1712 # 8002a6a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004d58:	00026a17          	auipc	s4,0x26
    80004d5c:	918a0a13          	addi	s4,s4,-1768 # 8002a670 <log>
    80004d60:	018a2583          	lw	a1,24(s4)
    80004d64:	012585bb          	addw	a1,a1,s2
    80004d68:	2585                	addiw	a1,a1,1
    80004d6a:	028a2503          	lw	a0,40(s4)
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	9ba080e7          	jalr	-1606(ra) # 80003728 <bread>
    80004d76:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004d78:	000aa583          	lw	a1,0(s5)
    80004d7c:	028a2503          	lw	a0,40(s4)
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	9a8080e7          	jalr	-1624(ra) # 80003728 <bread>
    80004d88:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004d8a:	40000613          	li	a2,1024
    80004d8e:	05850593          	addi	a1,a0,88
    80004d92:	05848513          	addi	a0,s1,88
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	f96080e7          	jalr	-106(ra) # 80000d2c <memmove>
    bwrite(to);  // write the log
    80004d9e:	8526                	mv	a0,s1
    80004da0:	fffff097          	auipc	ra,0xfffff
    80004da4:	a7a080e7          	jalr	-1414(ra) # 8000381a <bwrite>
    brelse(from);
    80004da8:	854e                	mv	a0,s3
    80004daa:	fffff097          	auipc	ra,0xfffff
    80004dae:	aae080e7          	jalr	-1362(ra) # 80003858 <brelse>
    brelse(to);
    80004db2:	8526                	mv	a0,s1
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	aa4080e7          	jalr	-1372(ra) # 80003858 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dbc:	2905                	addiw	s2,s2,1
    80004dbe:	0a91                	addi	s5,s5,4
    80004dc0:	02ca2783          	lw	a5,44(s4)
    80004dc4:	f8f94ee3          	blt	s2,a5,80004d60 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004dc8:	00000097          	auipc	ra,0x0
    80004dcc:	c66080e7          	jalr	-922(ra) # 80004a2e <write_head>
    install_trans(0); // Now install writes to home locations
    80004dd0:	4501                	li	a0,0
    80004dd2:	00000097          	auipc	ra,0x0
    80004dd6:	cd8080e7          	jalr	-808(ra) # 80004aaa <install_trans>
    log.lh.n = 0;
    80004dda:	00026797          	auipc	a5,0x26
    80004dde:	8c07a123          	sw	zero,-1854(a5) # 8002a69c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004de2:	00000097          	auipc	ra,0x0
    80004de6:	c4c080e7          	jalr	-948(ra) # 80004a2e <write_head>
    80004dea:	bdf5                	j	80004ce6 <end_op+0x52>

0000000080004dec <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004dec:	1101                	addi	sp,sp,-32
    80004dee:	ec06                	sd	ra,24(sp)
    80004df0:	e822                	sd	s0,16(sp)
    80004df2:	e426                	sd	s1,8(sp)
    80004df4:	e04a                	sd	s2,0(sp)
    80004df6:	1000                	addi	s0,sp,32
    80004df8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004dfa:	00026917          	auipc	s2,0x26
    80004dfe:	87690913          	addi	s2,s2,-1930 # 8002a670 <log>
    80004e02:	854a                	mv	a0,s2
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	dbe080e7          	jalr	-578(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e0c:	02c92603          	lw	a2,44(s2)
    80004e10:	47f5                	li	a5,29
    80004e12:	06c7c563          	blt	a5,a2,80004e7c <log_write+0x90>
    80004e16:	00026797          	auipc	a5,0x26
    80004e1a:	8767a783          	lw	a5,-1930(a5) # 8002a68c <log+0x1c>
    80004e1e:	37fd                	addiw	a5,a5,-1
    80004e20:	04f65e63          	bge	a2,a5,80004e7c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e24:	00026797          	auipc	a5,0x26
    80004e28:	86c7a783          	lw	a5,-1940(a5) # 8002a690 <log+0x20>
    80004e2c:	06f05063          	blez	a5,80004e8c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e30:	4781                	li	a5,0
    80004e32:	06c05563          	blez	a2,80004e9c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004e36:	44cc                	lw	a1,12(s1)
    80004e38:	00026717          	auipc	a4,0x26
    80004e3c:	86870713          	addi	a4,a4,-1944 # 8002a6a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004e40:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004e42:	4314                	lw	a3,0(a4)
    80004e44:	04b68c63          	beq	a3,a1,80004e9c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004e48:	2785                	addiw	a5,a5,1
    80004e4a:	0711                	addi	a4,a4,4
    80004e4c:	fef61be3          	bne	a2,a5,80004e42 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004e50:	0621                	addi	a2,a2,8
    80004e52:	060a                	slli	a2,a2,0x2
    80004e54:	00026797          	auipc	a5,0x26
    80004e58:	81c78793          	addi	a5,a5,-2020 # 8002a670 <log>
    80004e5c:	963e                	add	a2,a2,a5
    80004e5e:	44dc                	lw	a5,12(s1)
    80004e60:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004e62:	8526                	mv	a0,s1
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	a92080e7          	jalr	-1390(ra) # 800038f6 <bpin>
    log.lh.n++;
    80004e6c:	00026717          	auipc	a4,0x26
    80004e70:	80470713          	addi	a4,a4,-2044 # 8002a670 <log>
    80004e74:	575c                	lw	a5,44(a4)
    80004e76:	2785                	addiw	a5,a5,1
    80004e78:	d75c                	sw	a5,44(a4)
    80004e7a:	a835                	j	80004eb6 <log_write+0xca>
    panic("too big a transaction");
    80004e7c:	00005517          	auipc	a0,0x5
    80004e80:	af450513          	addi	a0,a0,-1292 # 80009970 <syscalls+0x260>
    80004e84:	ffffb097          	auipc	ra,0xffffb
    80004e88:	6a6080e7          	jalr	1702(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004e8c:	00005517          	auipc	a0,0x5
    80004e90:	afc50513          	addi	a0,a0,-1284 # 80009988 <syscalls+0x278>
    80004e94:	ffffb097          	auipc	ra,0xffffb
    80004e98:	696080e7          	jalr	1686(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004e9c:	00878713          	addi	a4,a5,8
    80004ea0:	00271693          	slli	a3,a4,0x2
    80004ea4:	00025717          	auipc	a4,0x25
    80004ea8:	7cc70713          	addi	a4,a4,1996 # 8002a670 <log>
    80004eac:	9736                	add	a4,a4,a3
    80004eae:	44d4                	lw	a3,12(s1)
    80004eb0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004eb2:	faf608e3          	beq	a2,a5,80004e62 <log_write+0x76>
  }
  release(&log.lock);
    80004eb6:	00025517          	auipc	a0,0x25
    80004eba:	7ba50513          	addi	a0,a0,1978 # 8002a670 <log>
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	dca080e7          	jalr	-566(ra) # 80000c88 <release>
}
    80004ec6:	60e2                	ld	ra,24(sp)
    80004ec8:	6442                	ld	s0,16(sp)
    80004eca:	64a2                	ld	s1,8(sp)
    80004ecc:	6902                	ld	s2,0(sp)
    80004ece:	6105                	addi	sp,sp,32
    80004ed0:	8082                	ret

0000000080004ed2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ed2:	1101                	addi	sp,sp,-32
    80004ed4:	ec06                	sd	ra,24(sp)
    80004ed6:	e822                	sd	s0,16(sp)
    80004ed8:	e426                	sd	s1,8(sp)
    80004eda:	e04a                	sd	s2,0(sp)
    80004edc:	1000                	addi	s0,sp,32
    80004ede:	84aa                	mv	s1,a0
    80004ee0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ee2:	00005597          	auipc	a1,0x5
    80004ee6:	ac658593          	addi	a1,a1,-1338 # 800099a8 <syscalls+0x298>
    80004eea:	0521                	addi	a0,a0,8
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	c46080e7          	jalr	-954(ra) # 80000b32 <initlock>
  lk->name = name;
    80004ef4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ef8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004efc:	0204a423          	sw	zero,40(s1)
}
    80004f00:	60e2                	ld	ra,24(sp)
    80004f02:	6442                	ld	s0,16(sp)
    80004f04:	64a2                	ld	s1,8(sp)
    80004f06:	6902                	ld	s2,0(sp)
    80004f08:	6105                	addi	sp,sp,32
    80004f0a:	8082                	ret

0000000080004f0c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f0c:	1101                	addi	sp,sp,-32
    80004f0e:	ec06                	sd	ra,24(sp)
    80004f10:	e822                	sd	s0,16(sp)
    80004f12:	e426                	sd	s1,8(sp)
    80004f14:	e04a                	sd	s2,0(sp)
    80004f16:	1000                	addi	s0,sp,32
    80004f18:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f1a:	00850913          	addi	s2,a0,8
    80004f1e:	854a                	mv	a0,s2
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	ca2080e7          	jalr	-862(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004f28:	409c                	lw	a5,0(s1)
    80004f2a:	cb89                	beqz	a5,80004f3c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f2c:	85ca                	mv	a1,s2
    80004f2e:	8526                	mv	a0,s1
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	004080e7          	jalr	4(ra) # 80001f34 <sleep>
  while (lk->locked) {
    80004f38:	409c                	lw	a5,0(s1)
    80004f3a:	fbed                	bnez	a5,80004f2c <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004f3c:	4785                	li	a5,1
    80004f3e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004f40:	ffffd097          	auipc	ra,0xffffd
    80004f44:	aa6080e7          	jalr	-1370(ra) # 800019e6 <myproc>
    80004f48:	591c                	lw	a5,48(a0)
    80004f4a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004f4c:	854a                	mv	a0,s2
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	d3a080e7          	jalr	-710(ra) # 80000c88 <release>
}
    80004f56:	60e2                	ld	ra,24(sp)
    80004f58:	6442                	ld	s0,16(sp)
    80004f5a:	64a2                	ld	s1,8(sp)
    80004f5c:	6902                	ld	s2,0(sp)
    80004f5e:	6105                	addi	sp,sp,32
    80004f60:	8082                	ret

0000000080004f62 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004f62:	1101                	addi	sp,sp,-32
    80004f64:	ec06                	sd	ra,24(sp)
    80004f66:	e822                	sd	s0,16(sp)
    80004f68:	e426                	sd	s1,8(sp)
    80004f6a:	e04a                	sd	s2,0(sp)
    80004f6c:	1000                	addi	s0,sp,32
    80004f6e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f70:	00850913          	addi	s2,a0,8
    80004f74:	854a                	mv	a0,s2
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	c4c080e7          	jalr	-948(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004f7e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f82:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004f86:	8526                	mv	a0,s1
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	010080e7          	jalr	16(ra) # 80001f98 <wakeup>
  release(&lk->lk);
    80004f90:	854a                	mv	a0,s2
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	cf6080e7          	jalr	-778(ra) # 80000c88 <release>
}
    80004f9a:	60e2                	ld	ra,24(sp)
    80004f9c:	6442                	ld	s0,16(sp)
    80004f9e:	64a2                	ld	s1,8(sp)
    80004fa0:	6902                	ld	s2,0(sp)
    80004fa2:	6105                	addi	sp,sp,32
    80004fa4:	8082                	ret

0000000080004fa6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004fa6:	7179                	addi	sp,sp,-48
    80004fa8:	f406                	sd	ra,40(sp)
    80004faa:	f022                	sd	s0,32(sp)
    80004fac:	ec26                	sd	s1,24(sp)
    80004fae:	e84a                	sd	s2,16(sp)
    80004fb0:	e44e                	sd	s3,8(sp)
    80004fb2:	1800                	addi	s0,sp,48
    80004fb4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004fb6:	00850913          	addi	s2,a0,8
    80004fba:	854a                	mv	a0,s2
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	c06080e7          	jalr	-1018(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004fc4:	409c                	lw	a5,0(s1)
    80004fc6:	ef99                	bnez	a5,80004fe4 <holdingsleep+0x3e>
    80004fc8:	4481                	li	s1,0
  release(&lk->lk);
    80004fca:	854a                	mv	a0,s2
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	cbc080e7          	jalr	-836(ra) # 80000c88 <release>
  return r;
}
    80004fd4:	8526                	mv	a0,s1
    80004fd6:	70a2                	ld	ra,40(sp)
    80004fd8:	7402                	ld	s0,32(sp)
    80004fda:	64e2                	ld	s1,24(sp)
    80004fdc:	6942                	ld	s2,16(sp)
    80004fde:	69a2                	ld	s3,8(sp)
    80004fe0:	6145                	addi	sp,sp,48
    80004fe2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004fe4:	0284a983          	lw	s3,40(s1)
    80004fe8:	ffffd097          	auipc	ra,0xffffd
    80004fec:	9fe080e7          	jalr	-1538(ra) # 800019e6 <myproc>
    80004ff0:	5904                	lw	s1,48(a0)
    80004ff2:	413484b3          	sub	s1,s1,s3
    80004ff6:	0014b493          	seqz	s1,s1
    80004ffa:	bfc1                	j	80004fca <holdingsleep+0x24>

0000000080004ffc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ffc:	1141                	addi	sp,sp,-16
    80004ffe:	e406                	sd	ra,8(sp)
    80005000:	e022                	sd	s0,0(sp)
    80005002:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005004:	00005597          	auipc	a1,0x5
    80005008:	9b458593          	addi	a1,a1,-1612 # 800099b8 <syscalls+0x2a8>
    8000500c:	00025517          	auipc	a0,0x25
    80005010:	7ac50513          	addi	a0,a0,1964 # 8002a7b8 <ftable>
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	b1e080e7          	jalr	-1250(ra) # 80000b32 <initlock>
}
    8000501c:	60a2                	ld	ra,8(sp)
    8000501e:	6402                	ld	s0,0(sp)
    80005020:	0141                	addi	sp,sp,16
    80005022:	8082                	ret

0000000080005024 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005024:	1101                	addi	sp,sp,-32
    80005026:	ec06                	sd	ra,24(sp)
    80005028:	e822                	sd	s0,16(sp)
    8000502a:	e426                	sd	s1,8(sp)
    8000502c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000502e:	00025517          	auipc	a0,0x25
    80005032:	78a50513          	addi	a0,a0,1930 # 8002a7b8 <ftable>
    80005036:	ffffc097          	auipc	ra,0xffffc
    8000503a:	b8c080e7          	jalr	-1140(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000503e:	00025497          	auipc	s1,0x25
    80005042:	79248493          	addi	s1,s1,1938 # 8002a7d0 <ftable+0x18>
    80005046:	00026717          	auipc	a4,0x26
    8000504a:	72a70713          	addi	a4,a4,1834 # 8002b770 <ftable+0xfb8>
    if(f->ref == 0){
    8000504e:	40dc                	lw	a5,4(s1)
    80005050:	cf99                	beqz	a5,8000506e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005052:	02848493          	addi	s1,s1,40
    80005056:	fee49ce3          	bne	s1,a4,8000504e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000505a:	00025517          	auipc	a0,0x25
    8000505e:	75e50513          	addi	a0,a0,1886 # 8002a7b8 <ftable>
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	c26080e7          	jalr	-986(ra) # 80000c88 <release>
  return 0;
    8000506a:	4481                	li	s1,0
    8000506c:	a819                	j	80005082 <filealloc+0x5e>
      f->ref = 1;
    8000506e:	4785                	li	a5,1
    80005070:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005072:	00025517          	auipc	a0,0x25
    80005076:	74650513          	addi	a0,a0,1862 # 8002a7b8 <ftable>
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	c0e080e7          	jalr	-1010(ra) # 80000c88 <release>
}
    80005082:	8526                	mv	a0,s1
    80005084:	60e2                	ld	ra,24(sp)
    80005086:	6442                	ld	s0,16(sp)
    80005088:	64a2                	ld	s1,8(sp)
    8000508a:	6105                	addi	sp,sp,32
    8000508c:	8082                	ret

000000008000508e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000508e:	1101                	addi	sp,sp,-32
    80005090:	ec06                	sd	ra,24(sp)
    80005092:	e822                	sd	s0,16(sp)
    80005094:	e426                	sd	s1,8(sp)
    80005096:	1000                	addi	s0,sp,32
    80005098:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000509a:	00025517          	auipc	a0,0x25
    8000509e:	71e50513          	addi	a0,a0,1822 # 8002a7b8 <ftable>
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	b20080e7          	jalr	-1248(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800050aa:	40dc                	lw	a5,4(s1)
    800050ac:	02f05263          	blez	a5,800050d0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800050b0:	2785                	addiw	a5,a5,1
    800050b2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800050b4:	00025517          	auipc	a0,0x25
    800050b8:	70450513          	addi	a0,a0,1796 # 8002a7b8 <ftable>
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	bcc080e7          	jalr	-1076(ra) # 80000c88 <release>
  return f;
}
    800050c4:	8526                	mv	a0,s1
    800050c6:	60e2                	ld	ra,24(sp)
    800050c8:	6442                	ld	s0,16(sp)
    800050ca:	64a2                	ld	s1,8(sp)
    800050cc:	6105                	addi	sp,sp,32
    800050ce:	8082                	ret
    panic("filedup");
    800050d0:	00005517          	auipc	a0,0x5
    800050d4:	8f050513          	addi	a0,a0,-1808 # 800099c0 <syscalls+0x2b0>
    800050d8:	ffffb097          	auipc	ra,0xffffb
    800050dc:	452080e7          	jalr	1106(ra) # 8000052a <panic>

00000000800050e0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800050e0:	7139                	addi	sp,sp,-64
    800050e2:	fc06                	sd	ra,56(sp)
    800050e4:	f822                	sd	s0,48(sp)
    800050e6:	f426                	sd	s1,40(sp)
    800050e8:	f04a                	sd	s2,32(sp)
    800050ea:	ec4e                	sd	s3,24(sp)
    800050ec:	e852                	sd	s4,16(sp)
    800050ee:	e456                	sd	s5,8(sp)
    800050f0:	0080                	addi	s0,sp,64
    800050f2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800050f4:	00025517          	auipc	a0,0x25
    800050f8:	6c450513          	addi	a0,a0,1732 # 8002a7b8 <ftable>
    800050fc:	ffffc097          	auipc	ra,0xffffc
    80005100:	ac6080e7          	jalr	-1338(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005104:	40dc                	lw	a5,4(s1)
    80005106:	06f05163          	blez	a5,80005168 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000510a:	37fd                	addiw	a5,a5,-1
    8000510c:	0007871b          	sext.w	a4,a5
    80005110:	c0dc                	sw	a5,4(s1)
    80005112:	06e04363          	bgtz	a4,80005178 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005116:	0004a903          	lw	s2,0(s1)
    8000511a:	0094ca83          	lbu	s5,9(s1)
    8000511e:	0104ba03          	ld	s4,16(s1)
    80005122:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005126:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000512a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000512e:	00025517          	auipc	a0,0x25
    80005132:	68a50513          	addi	a0,a0,1674 # 8002a7b8 <ftable>
    80005136:	ffffc097          	auipc	ra,0xffffc
    8000513a:	b52080e7          	jalr	-1198(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    8000513e:	4785                	li	a5,1
    80005140:	04f90d63          	beq	s2,a5,8000519a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005144:	3979                	addiw	s2,s2,-2
    80005146:	4785                	li	a5,1
    80005148:	0527e063          	bltu	a5,s2,80005188 <fileclose+0xa8>
    begin_op();
    8000514c:	00000097          	auipc	ra,0x0
    80005150:	ac8080e7          	jalr	-1336(ra) # 80004c14 <begin_op>
    iput(ff.ip);
    80005154:	854e                	mv	a0,s3
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	f90080e7          	jalr	-112(ra) # 800040e6 <iput>
    end_op();
    8000515e:	00000097          	auipc	ra,0x0
    80005162:	b36080e7          	jalr	-1226(ra) # 80004c94 <end_op>
    80005166:	a00d                	j	80005188 <fileclose+0xa8>
    panic("fileclose");
    80005168:	00005517          	auipc	a0,0x5
    8000516c:	86050513          	addi	a0,a0,-1952 # 800099c8 <syscalls+0x2b8>
    80005170:	ffffb097          	auipc	ra,0xffffb
    80005174:	3ba080e7          	jalr	954(ra) # 8000052a <panic>
    release(&ftable.lock);
    80005178:	00025517          	auipc	a0,0x25
    8000517c:	64050513          	addi	a0,a0,1600 # 8002a7b8 <ftable>
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	b08080e7          	jalr	-1272(ra) # 80000c88 <release>
  }
}
    80005188:	70e2                	ld	ra,56(sp)
    8000518a:	7442                	ld	s0,48(sp)
    8000518c:	74a2                	ld	s1,40(sp)
    8000518e:	7902                	ld	s2,32(sp)
    80005190:	69e2                	ld	s3,24(sp)
    80005192:	6a42                	ld	s4,16(sp)
    80005194:	6aa2                	ld	s5,8(sp)
    80005196:	6121                	addi	sp,sp,64
    80005198:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000519a:	85d6                	mv	a1,s5
    8000519c:	8552                	mv	a0,s4
    8000519e:	00000097          	auipc	ra,0x0
    800051a2:	542080e7          	jalr	1346(ra) # 800056e0 <pipeclose>
    800051a6:	b7cd                	j	80005188 <fileclose+0xa8>

00000000800051a8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800051a8:	715d                	addi	sp,sp,-80
    800051aa:	e486                	sd	ra,72(sp)
    800051ac:	e0a2                	sd	s0,64(sp)
    800051ae:	fc26                	sd	s1,56(sp)
    800051b0:	f84a                	sd	s2,48(sp)
    800051b2:	f44e                	sd	s3,40(sp)
    800051b4:	0880                	addi	s0,sp,80
    800051b6:	84aa                	mv	s1,a0
    800051b8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800051ba:	ffffd097          	auipc	ra,0xffffd
    800051be:	82c080e7          	jalr	-2004(ra) # 800019e6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800051c2:	409c                	lw	a5,0(s1)
    800051c4:	37f9                	addiw	a5,a5,-2
    800051c6:	4705                	li	a4,1
    800051c8:	04f76763          	bltu	a4,a5,80005216 <filestat+0x6e>
    800051cc:	892a                	mv	s2,a0
    ilock(f->ip);
    800051ce:	6c88                	ld	a0,24(s1)
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	d5c080e7          	jalr	-676(ra) # 80003f2c <ilock>
    stati(f->ip, &st);
    800051d8:	fb840593          	addi	a1,s0,-72
    800051dc:	6c88                	ld	a0,24(s1)
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	fd8080e7          	jalr	-40(ra) # 800041b6 <stati>
    iunlock(f->ip);
    800051e6:	6c88                	ld	a0,24(s1)
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	e06080e7          	jalr	-506(ra) # 80003fee <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800051f0:	46e1                	li	a3,24
    800051f2:	fb840613          	addi	a2,s0,-72
    800051f6:	85ce                	mv	a1,s3
    800051f8:	05093503          	ld	a0,80(s2)
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	4aa080e7          	jalr	1194(ra) # 800016a6 <copyout>
    80005204:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005208:	60a6                	ld	ra,72(sp)
    8000520a:	6406                	ld	s0,64(sp)
    8000520c:	74e2                	ld	s1,56(sp)
    8000520e:	7942                	ld	s2,48(sp)
    80005210:	79a2                	ld	s3,40(sp)
    80005212:	6161                	addi	sp,sp,80
    80005214:	8082                	ret
  return -1;
    80005216:	557d                	li	a0,-1
    80005218:	bfc5                	j	80005208 <filestat+0x60>

000000008000521a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000521a:	7179                	addi	sp,sp,-48
    8000521c:	f406                	sd	ra,40(sp)
    8000521e:	f022                	sd	s0,32(sp)
    80005220:	ec26                	sd	s1,24(sp)
    80005222:	e84a                	sd	s2,16(sp)
    80005224:	e44e                	sd	s3,8(sp)
    80005226:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005228:	00854783          	lbu	a5,8(a0)
    8000522c:	c3d5                	beqz	a5,800052d0 <fileread+0xb6>
    8000522e:	84aa                	mv	s1,a0
    80005230:	89ae                	mv	s3,a1
    80005232:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005234:	411c                	lw	a5,0(a0)
    80005236:	4705                	li	a4,1
    80005238:	04e78963          	beq	a5,a4,8000528a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000523c:	470d                	li	a4,3
    8000523e:	04e78d63          	beq	a5,a4,80005298 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005242:	4709                	li	a4,2
    80005244:	06e79e63          	bne	a5,a4,800052c0 <fileread+0xa6>
    ilock(f->ip);
    80005248:	6d08                	ld	a0,24(a0)
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	ce2080e7          	jalr	-798(ra) # 80003f2c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005252:	874a                	mv	a4,s2
    80005254:	5094                	lw	a3,32(s1)
    80005256:	864e                	mv	a2,s3
    80005258:	4585                	li	a1,1
    8000525a:	6c88                	ld	a0,24(s1)
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	f84080e7          	jalr	-124(ra) # 800041e0 <readi>
    80005264:	892a                	mv	s2,a0
    80005266:	00a05563          	blez	a0,80005270 <fileread+0x56>
      f->off += r;
    8000526a:	509c                	lw	a5,32(s1)
    8000526c:	9fa9                	addw	a5,a5,a0
    8000526e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005270:	6c88                	ld	a0,24(s1)
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	d7c080e7          	jalr	-644(ra) # 80003fee <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000527a:	854a                	mv	a0,s2
    8000527c:	70a2                	ld	ra,40(sp)
    8000527e:	7402                	ld	s0,32(sp)
    80005280:	64e2                	ld	s1,24(sp)
    80005282:	6942                	ld	s2,16(sp)
    80005284:	69a2                	ld	s3,8(sp)
    80005286:	6145                	addi	sp,sp,48
    80005288:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000528a:	6908                	ld	a0,16(a0)
    8000528c:	00000097          	auipc	ra,0x0
    80005290:	5b6080e7          	jalr	1462(ra) # 80005842 <piperead>
    80005294:	892a                	mv	s2,a0
    80005296:	b7d5                	j	8000527a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005298:	02451783          	lh	a5,36(a0)
    8000529c:	03079693          	slli	a3,a5,0x30
    800052a0:	92c1                	srli	a3,a3,0x30
    800052a2:	4725                	li	a4,9
    800052a4:	02d76863          	bltu	a4,a3,800052d4 <fileread+0xba>
    800052a8:	0792                	slli	a5,a5,0x4
    800052aa:	00025717          	auipc	a4,0x25
    800052ae:	46e70713          	addi	a4,a4,1134 # 8002a718 <devsw>
    800052b2:	97ba                	add	a5,a5,a4
    800052b4:	639c                	ld	a5,0(a5)
    800052b6:	c38d                	beqz	a5,800052d8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800052b8:	4505                	li	a0,1
    800052ba:	9782                	jalr	a5
    800052bc:	892a                	mv	s2,a0
    800052be:	bf75                	j	8000527a <fileread+0x60>
    panic("fileread");
    800052c0:	00004517          	auipc	a0,0x4
    800052c4:	71850513          	addi	a0,a0,1816 # 800099d8 <syscalls+0x2c8>
    800052c8:	ffffb097          	auipc	ra,0xffffb
    800052cc:	262080e7          	jalr	610(ra) # 8000052a <panic>
    return -1;
    800052d0:	597d                	li	s2,-1
    800052d2:	b765                	j	8000527a <fileread+0x60>
      return -1;
    800052d4:	597d                	li	s2,-1
    800052d6:	b755                	j	8000527a <fileread+0x60>
    800052d8:	597d                	li	s2,-1
    800052da:	b745                	j	8000527a <fileread+0x60>

00000000800052dc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800052dc:	715d                	addi	sp,sp,-80
    800052de:	e486                	sd	ra,72(sp)
    800052e0:	e0a2                	sd	s0,64(sp)
    800052e2:	fc26                	sd	s1,56(sp)
    800052e4:	f84a                	sd	s2,48(sp)
    800052e6:	f44e                	sd	s3,40(sp)
    800052e8:	f052                	sd	s4,32(sp)
    800052ea:	ec56                	sd	s5,24(sp)
    800052ec:	e85a                	sd	s6,16(sp)
    800052ee:	e45e                	sd	s7,8(sp)
    800052f0:	e062                	sd	s8,0(sp)
    800052f2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800052f4:	00954783          	lbu	a5,9(a0)
    800052f8:	10078663          	beqz	a5,80005404 <filewrite+0x128>
    800052fc:	892a                	mv	s2,a0
    800052fe:	8aae                	mv	s5,a1
    80005300:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005302:	411c                	lw	a5,0(a0)
    80005304:	4705                	li	a4,1
    80005306:	02e78263          	beq	a5,a4,8000532a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000530a:	470d                	li	a4,3
    8000530c:	02e78663          	beq	a5,a4,80005338 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005310:	4709                	li	a4,2
    80005312:	0ee79163          	bne	a5,a4,800053f4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005316:	0ac05d63          	blez	a2,800053d0 <filewrite+0xf4>
    int i = 0;
    8000531a:	4981                	li	s3,0
    8000531c:	6b05                	lui	s6,0x1
    8000531e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005322:	6b85                	lui	s7,0x1
    80005324:	c00b8b9b          	addiw	s7,s7,-1024
    80005328:	a861                	j	800053c0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000532a:	6908                	ld	a0,16(a0)
    8000532c:	00000097          	auipc	ra,0x0
    80005330:	424080e7          	jalr	1060(ra) # 80005750 <pipewrite>
    80005334:	8a2a                	mv	s4,a0
    80005336:	a045                	j	800053d6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005338:	02451783          	lh	a5,36(a0)
    8000533c:	03079693          	slli	a3,a5,0x30
    80005340:	92c1                	srli	a3,a3,0x30
    80005342:	4725                	li	a4,9
    80005344:	0cd76263          	bltu	a4,a3,80005408 <filewrite+0x12c>
    80005348:	0792                	slli	a5,a5,0x4
    8000534a:	00025717          	auipc	a4,0x25
    8000534e:	3ce70713          	addi	a4,a4,974 # 8002a718 <devsw>
    80005352:	97ba                	add	a5,a5,a4
    80005354:	679c                	ld	a5,8(a5)
    80005356:	cbdd                	beqz	a5,8000540c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005358:	4505                	li	a0,1
    8000535a:	9782                	jalr	a5
    8000535c:	8a2a                	mv	s4,a0
    8000535e:	a8a5                	j	800053d6 <filewrite+0xfa>
    80005360:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005364:	00000097          	auipc	ra,0x0
    80005368:	8b0080e7          	jalr	-1872(ra) # 80004c14 <begin_op>
      ilock(f->ip);
    8000536c:	01893503          	ld	a0,24(s2)
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	bbc080e7          	jalr	-1092(ra) # 80003f2c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005378:	8762                	mv	a4,s8
    8000537a:	02092683          	lw	a3,32(s2)
    8000537e:	01598633          	add	a2,s3,s5
    80005382:	4585                	li	a1,1
    80005384:	01893503          	ld	a0,24(s2)
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	f50080e7          	jalr	-176(ra) # 800042d8 <writei>
    80005390:	84aa                	mv	s1,a0
    80005392:	00a05763          	blez	a0,800053a0 <filewrite+0xc4>
        f->off += r;
    80005396:	02092783          	lw	a5,32(s2)
    8000539a:	9fa9                	addw	a5,a5,a0
    8000539c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800053a0:	01893503          	ld	a0,24(s2)
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	c4a080e7          	jalr	-950(ra) # 80003fee <iunlock>
      end_op();
    800053ac:	00000097          	auipc	ra,0x0
    800053b0:	8e8080e7          	jalr	-1816(ra) # 80004c94 <end_op>

      if(r != n1){
    800053b4:	009c1f63          	bne	s8,s1,800053d2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800053b8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800053bc:	0149db63          	bge	s3,s4,800053d2 <filewrite+0xf6>
      int n1 = n - i;
    800053c0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800053c4:	84be                	mv	s1,a5
    800053c6:	2781                	sext.w	a5,a5
    800053c8:	f8fb5ce3          	bge	s6,a5,80005360 <filewrite+0x84>
    800053cc:	84de                	mv	s1,s7
    800053ce:	bf49                	j	80005360 <filewrite+0x84>
    int i = 0;
    800053d0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800053d2:	013a1f63          	bne	s4,s3,800053f0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800053d6:	8552                	mv	a0,s4
    800053d8:	60a6                	ld	ra,72(sp)
    800053da:	6406                	ld	s0,64(sp)
    800053dc:	74e2                	ld	s1,56(sp)
    800053de:	7942                	ld	s2,48(sp)
    800053e0:	79a2                	ld	s3,40(sp)
    800053e2:	7a02                	ld	s4,32(sp)
    800053e4:	6ae2                	ld	s5,24(sp)
    800053e6:	6b42                	ld	s6,16(sp)
    800053e8:	6ba2                	ld	s7,8(sp)
    800053ea:	6c02                	ld	s8,0(sp)
    800053ec:	6161                	addi	sp,sp,80
    800053ee:	8082                	ret
    ret = (i == n ? n : -1);
    800053f0:	5a7d                	li	s4,-1
    800053f2:	b7d5                	j	800053d6 <filewrite+0xfa>
    panic("filewrite");
    800053f4:	00004517          	auipc	a0,0x4
    800053f8:	5f450513          	addi	a0,a0,1524 # 800099e8 <syscalls+0x2d8>
    800053fc:	ffffb097          	auipc	ra,0xffffb
    80005400:	12e080e7          	jalr	302(ra) # 8000052a <panic>
    return -1;
    80005404:	5a7d                	li	s4,-1
    80005406:	bfc1                	j	800053d6 <filewrite+0xfa>
      return -1;
    80005408:	5a7d                	li	s4,-1
    8000540a:	b7f1                	j	800053d6 <filewrite+0xfa>
    8000540c:	5a7d                	li	s4,-1
    8000540e:	b7e1                	j	800053d6 <filewrite+0xfa>

0000000080005410 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80005410:	7179                	addi	sp,sp,-48
    80005412:	f406                	sd	ra,40(sp)
    80005414:	f022                	sd	s0,32(sp)
    80005416:	ec26                	sd	s1,24(sp)
    80005418:	e84a                	sd	s2,16(sp)
    8000541a:	e44e                	sd	s3,8(sp)
    8000541c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000541e:	00854783          	lbu	a5,8(a0)
    80005422:	c3d5                	beqz	a5,800054c6 <kfileread+0xb6>
    80005424:	84aa                	mv	s1,a0
    80005426:	89ae                	mv	s3,a1
    80005428:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000542a:	411c                	lw	a5,0(a0)
    8000542c:	4705                	li	a4,1
    8000542e:	04e78963          	beq	a5,a4,80005480 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005432:	470d                	li	a4,3
    80005434:	04e78d63          	beq	a5,a4,8000548e <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005438:	4709                	li	a4,2
    8000543a:	06e79e63          	bne	a5,a4,800054b6 <kfileread+0xa6>
    ilock(f->ip);
    8000543e:	6d08                	ld	a0,24(a0)
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	aec080e7          	jalr	-1300(ra) # 80003f2c <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80005448:	874a                	mv	a4,s2
    8000544a:	5094                	lw	a3,32(s1)
    8000544c:	864e                	mv	a2,s3
    8000544e:	4581                	li	a1,0
    80005450:	6c88                	ld	a0,24(s1)
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	d8e080e7          	jalr	-626(ra) # 800041e0 <readi>
    8000545a:	892a                	mv	s2,a0
    8000545c:	00a05563          	blez	a0,80005466 <kfileread+0x56>
      f->off += r;
    80005460:	509c                	lw	a5,32(s1)
    80005462:	9fa9                	addw	a5,a5,a0
    80005464:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005466:	6c88                	ld	a0,24(s1)
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	b86080e7          	jalr	-1146(ra) # 80003fee <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005470:	854a                	mv	a0,s2
    80005472:	70a2                	ld	ra,40(sp)
    80005474:	7402                	ld	s0,32(sp)
    80005476:	64e2                	ld	s1,24(sp)
    80005478:	6942                	ld	s2,16(sp)
    8000547a:	69a2                	ld	s3,8(sp)
    8000547c:	6145                	addi	sp,sp,48
    8000547e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005480:	6908                	ld	a0,16(a0)
    80005482:	00000097          	auipc	ra,0x0
    80005486:	3c0080e7          	jalr	960(ra) # 80005842 <piperead>
    8000548a:	892a                	mv	s2,a0
    8000548c:	b7d5                	j	80005470 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000548e:	02451783          	lh	a5,36(a0)
    80005492:	03079693          	slli	a3,a5,0x30
    80005496:	92c1                	srli	a3,a3,0x30
    80005498:	4725                	li	a4,9
    8000549a:	02d76863          	bltu	a4,a3,800054ca <kfileread+0xba>
    8000549e:	0792                	slli	a5,a5,0x4
    800054a0:	00025717          	auipc	a4,0x25
    800054a4:	27870713          	addi	a4,a4,632 # 8002a718 <devsw>
    800054a8:	97ba                	add	a5,a5,a4
    800054aa:	639c                	ld	a5,0(a5)
    800054ac:	c38d                	beqz	a5,800054ce <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800054ae:	4505                	li	a0,1
    800054b0:	9782                	jalr	a5
    800054b2:	892a                	mv	s2,a0
    800054b4:	bf75                	j	80005470 <kfileread+0x60>
    panic("fileread");
    800054b6:	00004517          	auipc	a0,0x4
    800054ba:	52250513          	addi	a0,a0,1314 # 800099d8 <syscalls+0x2c8>
    800054be:	ffffb097          	auipc	ra,0xffffb
    800054c2:	06c080e7          	jalr	108(ra) # 8000052a <panic>
    return -1;
    800054c6:	597d                	li	s2,-1
    800054c8:	b765                	j	80005470 <kfileread+0x60>
      return -1;
    800054ca:	597d                	li	s2,-1
    800054cc:	b755                	j	80005470 <kfileread+0x60>
    800054ce:	597d                	li	s2,-1
    800054d0:	b745                	j	80005470 <kfileread+0x60>

00000000800054d2 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    800054d2:	715d                	addi	sp,sp,-80
    800054d4:	e486                	sd	ra,72(sp)
    800054d6:	e0a2                	sd	s0,64(sp)
    800054d8:	fc26                	sd	s1,56(sp)
    800054da:	f84a                	sd	s2,48(sp)
    800054dc:	f44e                	sd	s3,40(sp)
    800054de:	f052                	sd	s4,32(sp)
    800054e0:	ec56                	sd	s5,24(sp)
    800054e2:	e85a                	sd	s6,16(sp)
    800054e4:	e45e                	sd	s7,8(sp)
    800054e6:	e062                	sd	s8,0(sp)
    800054e8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800054ea:	00954783          	lbu	a5,9(a0)
    800054ee:	10078663          	beqz	a5,800055fa <kfilewrite+0x128>
    800054f2:	892a                	mv	s2,a0
    800054f4:	8aae                	mv	s5,a1
    800054f6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800054f8:	411c                	lw	a5,0(a0)
    800054fa:	4705                	li	a4,1
    800054fc:	02e78263          	beq	a5,a4,80005520 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005500:	470d                	li	a4,3
    80005502:	02e78663          	beq	a5,a4,8000552e <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005506:	4709                	li	a4,2
    80005508:	0ee79163          	bne	a5,a4,800055ea <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000550c:	0ac05d63          	blez	a2,800055c6 <kfilewrite+0xf4>
    int i = 0;
    80005510:	4981                	li	s3,0
    80005512:	6b05                	lui	s6,0x1
    80005514:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005518:	6b85                	lui	s7,0x1
    8000551a:	c00b8b9b          	addiw	s7,s7,-1024
    8000551e:	a861                	j	800055b6 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005520:	6908                	ld	a0,16(a0)
    80005522:	00000097          	auipc	ra,0x0
    80005526:	22e080e7          	jalr	558(ra) # 80005750 <pipewrite>
    8000552a:	8a2a                	mv	s4,a0
    8000552c:	a045                	j	800055cc <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000552e:	02451783          	lh	a5,36(a0)
    80005532:	03079693          	slli	a3,a5,0x30
    80005536:	92c1                	srli	a3,a3,0x30
    80005538:	4725                	li	a4,9
    8000553a:	0cd76263          	bltu	a4,a3,800055fe <kfilewrite+0x12c>
    8000553e:	0792                	slli	a5,a5,0x4
    80005540:	00025717          	auipc	a4,0x25
    80005544:	1d870713          	addi	a4,a4,472 # 8002a718 <devsw>
    80005548:	97ba                	add	a5,a5,a4
    8000554a:	679c                	ld	a5,8(a5)
    8000554c:	cbdd                	beqz	a5,80005602 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000554e:	4505                	li	a0,1
    80005550:	9782                	jalr	a5
    80005552:	8a2a                	mv	s4,a0
    80005554:	a8a5                	j	800055cc <kfilewrite+0xfa>
    80005556:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	6ba080e7          	jalr	1722(ra) # 80004c14 <begin_op>
      ilock(f->ip);
    80005562:	01893503          	ld	a0,24(s2)
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	9c6080e7          	jalr	-1594(ra) # 80003f2c <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    8000556e:	8762                	mv	a4,s8
    80005570:	02092683          	lw	a3,32(s2)
    80005574:	01598633          	add	a2,s3,s5
    80005578:	4581                	li	a1,0
    8000557a:	01893503          	ld	a0,24(s2)
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	d5a080e7          	jalr	-678(ra) # 800042d8 <writei>
    80005586:	84aa                	mv	s1,a0
    80005588:	00a05763          	blez	a0,80005596 <kfilewrite+0xc4>
        f->off += r;
    8000558c:	02092783          	lw	a5,32(s2)
    80005590:	9fa9                	addw	a5,a5,a0
    80005592:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005596:	01893503          	ld	a0,24(s2)
    8000559a:	fffff097          	auipc	ra,0xfffff
    8000559e:	a54080e7          	jalr	-1452(ra) # 80003fee <iunlock>
      end_op();
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	6f2080e7          	jalr	1778(ra) # 80004c94 <end_op>

      if(r != n1){
    800055aa:	009c1f63          	bne	s8,s1,800055c8 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800055ae:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800055b2:	0149db63          	bge	s3,s4,800055c8 <kfilewrite+0xf6>
      int n1 = n - i;
    800055b6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800055ba:	84be                	mv	s1,a5
    800055bc:	2781                	sext.w	a5,a5
    800055be:	f8fb5ce3          	bge	s6,a5,80005556 <kfilewrite+0x84>
    800055c2:	84de                	mv	s1,s7
    800055c4:	bf49                	j	80005556 <kfilewrite+0x84>
    int i = 0;
    800055c6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800055c8:	013a1f63          	bne	s4,s3,800055e6 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    800055cc:	8552                	mv	a0,s4
    800055ce:	60a6                	ld	ra,72(sp)
    800055d0:	6406                	ld	s0,64(sp)
    800055d2:	74e2                	ld	s1,56(sp)
    800055d4:	7942                	ld	s2,48(sp)
    800055d6:	79a2                	ld	s3,40(sp)
    800055d8:	7a02                	ld	s4,32(sp)
    800055da:	6ae2                	ld	s5,24(sp)
    800055dc:	6b42                	ld	s6,16(sp)
    800055de:	6ba2                	ld	s7,8(sp)
    800055e0:	6c02                	ld	s8,0(sp)
    800055e2:	6161                	addi	sp,sp,80
    800055e4:	8082                	ret
    ret = (i == n ? n : -1);
    800055e6:	5a7d                	li	s4,-1
    800055e8:	b7d5                	j	800055cc <kfilewrite+0xfa>
    panic("filewrite");
    800055ea:	00004517          	auipc	a0,0x4
    800055ee:	3fe50513          	addi	a0,a0,1022 # 800099e8 <syscalls+0x2d8>
    800055f2:	ffffb097          	auipc	ra,0xffffb
    800055f6:	f38080e7          	jalr	-200(ra) # 8000052a <panic>
    return -1;
    800055fa:	5a7d                	li	s4,-1
    800055fc:	bfc1                	j	800055cc <kfilewrite+0xfa>
      return -1;
    800055fe:	5a7d                	li	s4,-1
    80005600:	b7f1                	j	800055cc <kfilewrite+0xfa>
    80005602:	5a7d                	li	s4,-1
    80005604:	b7e1                	j	800055cc <kfilewrite+0xfa>

0000000080005606 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005606:	7179                	addi	sp,sp,-48
    80005608:	f406                	sd	ra,40(sp)
    8000560a:	f022                	sd	s0,32(sp)
    8000560c:	ec26                	sd	s1,24(sp)
    8000560e:	e84a                	sd	s2,16(sp)
    80005610:	e44e                	sd	s3,8(sp)
    80005612:	e052                	sd	s4,0(sp)
    80005614:	1800                	addi	s0,sp,48
    80005616:	84aa                	mv	s1,a0
    80005618:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000561a:	0005b023          	sd	zero,0(a1)
    8000561e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005622:	00000097          	auipc	ra,0x0
    80005626:	a02080e7          	jalr	-1534(ra) # 80005024 <filealloc>
    8000562a:	e088                	sd	a0,0(s1)
    8000562c:	c551                	beqz	a0,800056b8 <pipealloc+0xb2>
    8000562e:	00000097          	auipc	ra,0x0
    80005632:	9f6080e7          	jalr	-1546(ra) # 80005024 <filealloc>
    80005636:	00aa3023          	sd	a0,0(s4)
    8000563a:	c92d                	beqz	a0,800056ac <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000563c:	ffffb097          	auipc	ra,0xffffb
    80005640:	496080e7          	jalr	1174(ra) # 80000ad2 <kalloc>
    80005644:	892a                	mv	s2,a0
    80005646:	c125                	beqz	a0,800056a6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005648:	4985                	li	s3,1
    8000564a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000564e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005652:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005656:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000565a:	00004597          	auipc	a1,0x4
    8000565e:	39e58593          	addi	a1,a1,926 # 800099f8 <syscalls+0x2e8>
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	4d0080e7          	jalr	1232(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    8000566a:	609c                	ld	a5,0(s1)
    8000566c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005670:	609c                	ld	a5,0(s1)
    80005672:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005676:	609c                	ld	a5,0(s1)
    80005678:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000567c:	609c                	ld	a5,0(s1)
    8000567e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005682:	000a3783          	ld	a5,0(s4)
    80005686:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000568a:	000a3783          	ld	a5,0(s4)
    8000568e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005692:	000a3783          	ld	a5,0(s4)
    80005696:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000569a:	000a3783          	ld	a5,0(s4)
    8000569e:	0127b823          	sd	s2,16(a5)
  return 0;
    800056a2:	4501                	li	a0,0
    800056a4:	a025                	j	800056cc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800056a6:	6088                	ld	a0,0(s1)
    800056a8:	e501                	bnez	a0,800056b0 <pipealloc+0xaa>
    800056aa:	a039                	j	800056b8 <pipealloc+0xb2>
    800056ac:	6088                	ld	a0,0(s1)
    800056ae:	c51d                	beqz	a0,800056dc <pipealloc+0xd6>
    fileclose(*f0);
    800056b0:	00000097          	auipc	ra,0x0
    800056b4:	a30080e7          	jalr	-1488(ra) # 800050e0 <fileclose>
  if(*f1)
    800056b8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800056bc:	557d                	li	a0,-1
  if(*f1)
    800056be:	c799                	beqz	a5,800056cc <pipealloc+0xc6>
    fileclose(*f1);
    800056c0:	853e                	mv	a0,a5
    800056c2:	00000097          	auipc	ra,0x0
    800056c6:	a1e080e7          	jalr	-1506(ra) # 800050e0 <fileclose>
  return -1;
    800056ca:	557d                	li	a0,-1
}
    800056cc:	70a2                	ld	ra,40(sp)
    800056ce:	7402                	ld	s0,32(sp)
    800056d0:	64e2                	ld	s1,24(sp)
    800056d2:	6942                	ld	s2,16(sp)
    800056d4:	69a2                	ld	s3,8(sp)
    800056d6:	6a02                	ld	s4,0(sp)
    800056d8:	6145                	addi	sp,sp,48
    800056da:	8082                	ret
  return -1;
    800056dc:	557d                	li	a0,-1
    800056de:	b7fd                	j	800056cc <pipealloc+0xc6>

00000000800056e0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800056e0:	1101                	addi	sp,sp,-32
    800056e2:	ec06                	sd	ra,24(sp)
    800056e4:	e822                	sd	s0,16(sp)
    800056e6:	e426                	sd	s1,8(sp)
    800056e8:	e04a                	sd	s2,0(sp)
    800056ea:	1000                	addi	s0,sp,32
    800056ec:	84aa                	mv	s1,a0
    800056ee:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800056f0:	ffffb097          	auipc	ra,0xffffb
    800056f4:	4d2080e7          	jalr	1234(ra) # 80000bc2 <acquire>
  if(writable){
    800056f8:	02090d63          	beqz	s2,80005732 <pipeclose+0x52>
    pi->writeopen = 0;
    800056fc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005700:	21848513          	addi	a0,s1,536
    80005704:	ffffd097          	auipc	ra,0xffffd
    80005708:	894080e7          	jalr	-1900(ra) # 80001f98 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000570c:	2204b783          	ld	a5,544(s1)
    80005710:	eb95                	bnez	a5,80005744 <pipeclose+0x64>
    release(&pi->lock);
    80005712:	8526                	mv	a0,s1
    80005714:	ffffb097          	auipc	ra,0xffffb
    80005718:	574080e7          	jalr	1396(ra) # 80000c88 <release>
    kfree((char*)pi);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffb097          	auipc	ra,0xffffb
    80005722:	2b8080e7          	jalr	696(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005726:	60e2                	ld	ra,24(sp)
    80005728:	6442                	ld	s0,16(sp)
    8000572a:	64a2                	ld	s1,8(sp)
    8000572c:	6902                	ld	s2,0(sp)
    8000572e:	6105                	addi	sp,sp,32
    80005730:	8082                	ret
    pi->readopen = 0;
    80005732:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005736:	21c48513          	addi	a0,s1,540
    8000573a:	ffffd097          	auipc	ra,0xffffd
    8000573e:	85e080e7          	jalr	-1954(ra) # 80001f98 <wakeup>
    80005742:	b7e9                	j	8000570c <pipeclose+0x2c>
    release(&pi->lock);
    80005744:	8526                	mv	a0,s1
    80005746:	ffffb097          	auipc	ra,0xffffb
    8000574a:	542080e7          	jalr	1346(ra) # 80000c88 <release>
}
    8000574e:	bfe1                	j	80005726 <pipeclose+0x46>

0000000080005750 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005750:	711d                	addi	sp,sp,-96
    80005752:	ec86                	sd	ra,88(sp)
    80005754:	e8a2                	sd	s0,80(sp)
    80005756:	e4a6                	sd	s1,72(sp)
    80005758:	e0ca                	sd	s2,64(sp)
    8000575a:	fc4e                	sd	s3,56(sp)
    8000575c:	f852                	sd	s4,48(sp)
    8000575e:	f456                	sd	s5,40(sp)
    80005760:	f05a                	sd	s6,32(sp)
    80005762:	ec5e                	sd	s7,24(sp)
    80005764:	e862                	sd	s8,16(sp)
    80005766:	1080                	addi	s0,sp,96
    80005768:	84aa                	mv	s1,a0
    8000576a:	8aae                	mv	s5,a1
    8000576c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000576e:	ffffc097          	auipc	ra,0xffffc
    80005772:	278080e7          	jalr	632(ra) # 800019e6 <myproc>
    80005776:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffb097          	auipc	ra,0xffffb
    8000577e:	448080e7          	jalr	1096(ra) # 80000bc2 <acquire>
  while(i < n){
    80005782:	0b405363          	blez	s4,80005828 <pipewrite+0xd8>
  int i = 0;
    80005786:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005788:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000578a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000578e:	21c48b93          	addi	s7,s1,540
    80005792:	a089                	j	800057d4 <pipewrite+0x84>
      release(&pi->lock);
    80005794:	8526                	mv	a0,s1
    80005796:	ffffb097          	auipc	ra,0xffffb
    8000579a:	4f2080e7          	jalr	1266(ra) # 80000c88 <release>
      return -1;
    8000579e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800057a0:	854a                	mv	a0,s2
    800057a2:	60e6                	ld	ra,88(sp)
    800057a4:	6446                	ld	s0,80(sp)
    800057a6:	64a6                	ld	s1,72(sp)
    800057a8:	6906                	ld	s2,64(sp)
    800057aa:	79e2                	ld	s3,56(sp)
    800057ac:	7a42                	ld	s4,48(sp)
    800057ae:	7aa2                	ld	s5,40(sp)
    800057b0:	7b02                	ld	s6,32(sp)
    800057b2:	6be2                	ld	s7,24(sp)
    800057b4:	6c42                	ld	s8,16(sp)
    800057b6:	6125                	addi	sp,sp,96
    800057b8:	8082                	ret
      wakeup(&pi->nread);
    800057ba:	8562                	mv	a0,s8
    800057bc:	ffffc097          	auipc	ra,0xffffc
    800057c0:	7dc080e7          	jalr	2012(ra) # 80001f98 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800057c4:	85a6                	mv	a1,s1
    800057c6:	855e                	mv	a0,s7
    800057c8:	ffffc097          	auipc	ra,0xffffc
    800057cc:	76c080e7          	jalr	1900(ra) # 80001f34 <sleep>
  while(i < n){
    800057d0:	05495d63          	bge	s2,s4,8000582a <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800057d4:	2204a783          	lw	a5,544(s1)
    800057d8:	dfd5                	beqz	a5,80005794 <pipewrite+0x44>
    800057da:	0289a783          	lw	a5,40(s3)
    800057de:	fbdd                	bnez	a5,80005794 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800057e0:	2184a783          	lw	a5,536(s1)
    800057e4:	21c4a703          	lw	a4,540(s1)
    800057e8:	2007879b          	addiw	a5,a5,512
    800057ec:	fcf707e3          	beq	a4,a5,800057ba <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800057f0:	4685                	li	a3,1
    800057f2:	01590633          	add	a2,s2,s5
    800057f6:	faf40593          	addi	a1,s0,-81
    800057fa:	0509b503          	ld	a0,80(s3)
    800057fe:	ffffc097          	auipc	ra,0xffffc
    80005802:	f34080e7          	jalr	-204(ra) # 80001732 <copyin>
    80005806:	03650263          	beq	a0,s6,8000582a <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000580a:	21c4a783          	lw	a5,540(s1)
    8000580e:	0017871b          	addiw	a4,a5,1
    80005812:	20e4ae23          	sw	a4,540(s1)
    80005816:	1ff7f793          	andi	a5,a5,511
    8000581a:	97a6                	add	a5,a5,s1
    8000581c:	faf44703          	lbu	a4,-81(s0)
    80005820:	00e78c23          	sb	a4,24(a5)
      i++;
    80005824:	2905                	addiw	s2,s2,1
    80005826:	b76d                	j	800057d0 <pipewrite+0x80>
  int i = 0;
    80005828:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000582a:	21848513          	addi	a0,s1,536
    8000582e:	ffffc097          	auipc	ra,0xffffc
    80005832:	76a080e7          	jalr	1898(ra) # 80001f98 <wakeup>
  release(&pi->lock);
    80005836:	8526                	mv	a0,s1
    80005838:	ffffb097          	auipc	ra,0xffffb
    8000583c:	450080e7          	jalr	1104(ra) # 80000c88 <release>
  return i;
    80005840:	b785                	j	800057a0 <pipewrite+0x50>

0000000080005842 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005842:	715d                	addi	sp,sp,-80
    80005844:	e486                	sd	ra,72(sp)
    80005846:	e0a2                	sd	s0,64(sp)
    80005848:	fc26                	sd	s1,56(sp)
    8000584a:	f84a                	sd	s2,48(sp)
    8000584c:	f44e                	sd	s3,40(sp)
    8000584e:	f052                	sd	s4,32(sp)
    80005850:	ec56                	sd	s5,24(sp)
    80005852:	e85a                	sd	s6,16(sp)
    80005854:	0880                	addi	s0,sp,80
    80005856:	84aa                	mv	s1,a0
    80005858:	892e                	mv	s2,a1
    8000585a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000585c:	ffffc097          	auipc	ra,0xffffc
    80005860:	18a080e7          	jalr	394(ra) # 800019e6 <myproc>
    80005864:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffb097          	auipc	ra,0xffffb
    8000586c:	35a080e7          	jalr	858(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005870:	2184a703          	lw	a4,536(s1)
    80005874:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005878:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000587c:	02f71463          	bne	a4,a5,800058a4 <piperead+0x62>
    80005880:	2244a783          	lw	a5,548(s1)
    80005884:	c385                	beqz	a5,800058a4 <piperead+0x62>
    if(pr->killed){
    80005886:	028a2783          	lw	a5,40(s4)
    8000588a:	ebc1                	bnez	a5,8000591a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000588c:	85a6                	mv	a1,s1
    8000588e:	854e                	mv	a0,s3
    80005890:	ffffc097          	auipc	ra,0xffffc
    80005894:	6a4080e7          	jalr	1700(ra) # 80001f34 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005898:	2184a703          	lw	a4,536(s1)
    8000589c:	21c4a783          	lw	a5,540(s1)
    800058a0:	fef700e3          	beq	a4,a5,80005880 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058a4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800058a6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058a8:	05505363          	blez	s5,800058ee <piperead+0xac>
    if(pi->nread == pi->nwrite)
    800058ac:	2184a783          	lw	a5,536(s1)
    800058b0:	21c4a703          	lw	a4,540(s1)
    800058b4:	02f70d63          	beq	a4,a5,800058ee <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800058b8:	0017871b          	addiw	a4,a5,1
    800058bc:	20e4ac23          	sw	a4,536(s1)
    800058c0:	1ff7f793          	andi	a5,a5,511
    800058c4:	97a6                	add	a5,a5,s1
    800058c6:	0187c783          	lbu	a5,24(a5)
    800058ca:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800058ce:	4685                	li	a3,1
    800058d0:	fbf40613          	addi	a2,s0,-65
    800058d4:	85ca                	mv	a1,s2
    800058d6:	050a3503          	ld	a0,80(s4)
    800058da:	ffffc097          	auipc	ra,0xffffc
    800058de:	dcc080e7          	jalr	-564(ra) # 800016a6 <copyout>
    800058e2:	01650663          	beq	a0,s6,800058ee <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058e6:	2985                	addiw	s3,s3,1
    800058e8:	0905                	addi	s2,s2,1
    800058ea:	fd3a91e3          	bne	s5,s3,800058ac <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800058ee:	21c48513          	addi	a0,s1,540
    800058f2:	ffffc097          	auipc	ra,0xffffc
    800058f6:	6a6080e7          	jalr	1702(ra) # 80001f98 <wakeup>
  release(&pi->lock);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffb097          	auipc	ra,0xffffb
    80005900:	38c080e7          	jalr	908(ra) # 80000c88 <release>
  return i;
}
    80005904:	854e                	mv	a0,s3
    80005906:	60a6                	ld	ra,72(sp)
    80005908:	6406                	ld	s0,64(sp)
    8000590a:	74e2                	ld	s1,56(sp)
    8000590c:	7942                	ld	s2,48(sp)
    8000590e:	79a2                	ld	s3,40(sp)
    80005910:	7a02                	ld	s4,32(sp)
    80005912:	6ae2                	ld	s5,24(sp)
    80005914:	6b42                	ld	s6,16(sp)
    80005916:	6161                	addi	sp,sp,80
    80005918:	8082                	ret
      release(&pi->lock);
    8000591a:	8526                	mv	a0,s1
    8000591c:	ffffb097          	auipc	ra,0xffffb
    80005920:	36c080e7          	jalr	876(ra) # 80000c88 <release>
      return -1;
    80005924:	59fd                	li	s3,-1
    80005926:	bff9                	j	80005904 <piperead+0xc2>

0000000080005928 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005928:	bd010113          	addi	sp,sp,-1072
    8000592c:	42113423          	sd	ra,1064(sp)
    80005930:	42813023          	sd	s0,1056(sp)
    80005934:	40913c23          	sd	s1,1048(sp)
    80005938:	41213823          	sd	s2,1040(sp)
    8000593c:	41313423          	sd	s3,1032(sp)
    80005940:	41413023          	sd	s4,1024(sp)
    80005944:	3f513c23          	sd	s5,1016(sp)
    80005948:	3f613823          	sd	s6,1008(sp)
    8000594c:	3f713423          	sd	s7,1000(sp)
    80005950:	3f813023          	sd	s8,992(sp)
    80005954:	3d913c23          	sd	s9,984(sp)
    80005958:	3da13823          	sd	s10,976(sp)
    8000595c:	3db13423          	sd	s11,968(sp)
    80005960:	43010413          	addi	s0,sp,1072
    80005964:	89aa                	mv	s3,a0
    80005966:	bea43023          	sd	a0,-1056(s0)
    8000596a:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000596e:	ffffc097          	auipc	ra,0xffffc
    80005972:	078080e7          	jalr	120(ra) # 800019e6 <myproc>
    80005976:	8b2a                	mv	s6,a0
  
  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_PSYC_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    80005978:	17050913          	addi	s2,a0,368
    8000597c:	10000613          	li	a2,256
    80005980:	85ca                	mv	a1,s2
    80005982:	d1040513          	addi	a0,s0,-752
    80005986:	ffffb097          	auipc	ra,0xffffb
    8000598a:	3a6080e7          	jalr	934(ra) # 80000d2c <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    8000598e:	270b0493          	addi	s1,s6,624
    80005992:	10000613          	li	a2,256
    80005996:	85a6                	mv	a1,s1
    80005998:	c1040513          	addi	a0,s0,-1008
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	390080e7          	jalr	912(ra) # 80000d2c <memmove>

  begin_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	270080e7          	jalr	624(ra) # 80004c14 <begin_op>

  if((ip = namei(path)) == 0){
    800059ac:	854e                	mv	a0,s3
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	d34080e7          	jalr	-716(ra) # 800046e2 <namei>
    800059b6:	c179                	beqz	a0,80005a7c <exec+0x154>
    800059b8:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	572080e7          	jalr	1394(ra) # 80003f2c <ilock>
  //ADDED Q1
  // TODO isSwapProc... is it equal to (p->pid != INIT_PID && p->pid != SHELL_PID)?
  // if(isSwapProc(p) && init_metadata(p) < 0){
  //   goto bad;
  // }
  if(p->pid != INIT_PID && p->pid != SHELL_PID && init_metadata(p) < 0){
    800059c2:	030b2783          	lw	a5,48(s6)
    800059c6:	37fd                	addiw	a5,a5,-1
    800059c8:	4705                	li	a4,1
    800059ca:	00f77963          	bgeu	a4,a5,800059dc <exec+0xb4>
    800059ce:	855a                	mv	a0,s6
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	866080e7          	jalr	-1946(ra) # 80002236 <init_metadata>
    800059d8:	02054963          	bltz	a0,80005a0a <exec+0xe2>
    goto bad;
  }

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800059dc:	04000713          	li	a4,64
    800059e0:	4681                	li	a3,0
    800059e2:	e4840613          	addi	a2,s0,-440
    800059e6:	4581                	li	a1,0
    800059e8:	8552                	mv	a0,s4
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	7f6080e7          	jalr	2038(ra) # 800041e0 <readi>
    800059f2:	04000793          	li	a5,64
    800059f6:	00f51a63          	bne	a0,a5,80005a0a <exec+0xe2>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800059fa:	e4842703          	lw	a4,-440(s0)
    800059fe:	464c47b7          	lui	a5,0x464c4
    80005a02:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005a06:	08f70163          	beq	a4,a5,80005a88 <exec+0x160>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005a0a:	10000613          	li	a2,256
    80005a0e:	d1040593          	addi	a1,s0,-752
    80005a12:	854a                	mv	a0,s2
    80005a14:	ffffb097          	auipc	ra,0xffffb
    80005a18:	318080e7          	jalr	792(ra) # 80000d2c <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005a1c:	10000613          	li	a2,256
    80005a20:	c1040593          	addi	a1,s0,-1008
    80005a24:	8526                	mv	a0,s1
    80005a26:	ffffb097          	auipc	ra,0xffffb
    80005a2a:	306080e7          	jalr	774(ra) # 80000d2c <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005a2e:	8552                	mv	a0,s4
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	75e080e7          	jalr	1886(ra) # 8000418e <iunlockput>
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	25c080e7          	jalr	604(ra) # 80004c94 <end_op>
  }
  return -1;
    80005a40:	557d                	li	a0,-1
}
    80005a42:	42813083          	ld	ra,1064(sp)
    80005a46:	42013403          	ld	s0,1056(sp)
    80005a4a:	41813483          	ld	s1,1048(sp)
    80005a4e:	41013903          	ld	s2,1040(sp)
    80005a52:	40813983          	ld	s3,1032(sp)
    80005a56:	40013a03          	ld	s4,1024(sp)
    80005a5a:	3f813a83          	ld	s5,1016(sp)
    80005a5e:	3f013b03          	ld	s6,1008(sp)
    80005a62:	3e813b83          	ld	s7,1000(sp)
    80005a66:	3e013c03          	ld	s8,992(sp)
    80005a6a:	3d813c83          	ld	s9,984(sp)
    80005a6e:	3d013d03          	ld	s10,976(sp)
    80005a72:	3c813d83          	ld	s11,968(sp)
    80005a76:	43010113          	addi	sp,sp,1072
    80005a7a:	8082                	ret
    end_op();
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	218080e7          	jalr	536(ra) # 80004c94 <end_op>
    return -1;
    80005a84:	557d                	li	a0,-1
    80005a86:	bf75                	j	80005a42 <exec+0x11a>
  if((pagetable = proc_pagetable(p)) == 0)
    80005a88:	855a                	mv	a0,s6
    80005a8a:	ffffc097          	auipc	ra,0xffffc
    80005a8e:	020080e7          	jalr	32(ra) # 80001aaa <proc_pagetable>
    80005a92:	c0a43423          	sd	a0,-1016(s0)
    80005a96:	d935                	beqz	a0,80005a0a <exec+0xe2>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a98:	e6842783          	lw	a5,-408(s0)
    80005a9c:	e8045703          	lhu	a4,-384(s0)
    80005aa0:	c73d                	beqz	a4,80005b0e <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005aa2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005aa4:	c0043023          	sd	zero,-1024(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005aa8:	6a85                	lui	s5,0x1
    80005aaa:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80005aae:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005ab2:	6d85                	lui	s11,0x1
    80005ab4:	7d7d                	lui	s10,0xfffff
    80005ab6:	a4bd                	j	80005d24 <exec+0x3fc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005ab8:	00004517          	auipc	a0,0x4
    80005abc:	f4850513          	addi	a0,a0,-184 # 80009a00 <syscalls+0x2f0>
    80005ac0:	ffffb097          	auipc	ra,0xffffb
    80005ac4:	a6a080e7          	jalr	-1430(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005ac8:	874a                	mv	a4,s2
    80005aca:	009c86bb          	addw	a3,s9,s1
    80005ace:	4581                	li	a1,0
    80005ad0:	8552                	mv	a0,s4
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	70e080e7          	jalr	1806(ra) # 800041e0 <readi>
    80005ada:	2501                	sext.w	a0,a0
    80005adc:	1aa91f63          	bne	s2,a0,80005c9a <exec+0x372>
  for(i = 0; i < sz; i += PGSIZE){
    80005ae0:	009d84bb          	addw	s1,s11,s1
    80005ae4:	013d09bb          	addw	s3,s10,s3
    80005ae8:	2174fe63          	bgeu	s1,s7,80005d04 <exec+0x3dc>
    pa = walkaddr(pagetable, va + i);
    80005aec:	02049593          	slli	a1,s1,0x20
    80005af0:	9181                	srli	a1,a1,0x20
    80005af2:	95e2                	add	a1,a1,s8
    80005af4:	c0843503          	ld	a0,-1016(s0)
    80005af8:	ffffb097          	auipc	ra,0xffffb
    80005afc:	566080e7          	jalr	1382(ra) # 8000105e <walkaddr>
    80005b00:	862a                	mv	a2,a0
    if(pa == 0)
    80005b02:	d95d                	beqz	a0,80005ab8 <exec+0x190>
      n = PGSIZE;
    80005b04:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    80005b06:	fd59f1e3          	bgeu	s3,s5,80005ac8 <exec+0x1a0>
      n = sz - i;
    80005b0a:	894e                	mv	s2,s3
    80005b0c:	bf75                	j	80005ac8 <exec+0x1a0>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b0e:	4481                	li	s1,0
  iunlockput(ip);
    80005b10:	8552                	mv	a0,s4
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	67c080e7          	jalr	1660(ra) # 8000418e <iunlockput>
  end_op();
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	17a080e7          	jalr	378(ra) # 80004c94 <end_op>
  p = myproc();
    80005b22:	ffffc097          	auipc	ra,0xffffc
    80005b26:	ec4080e7          	jalr	-316(ra) # 800019e6 <myproc>
    80005b2a:	8b2a                	mv	s6,a0
  uint64 oldsz = p->sz;
    80005b2c:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005b30:	6785                	lui	a5,0x1
    80005b32:	17fd                	addi	a5,a5,-1
    80005b34:	94be                	add	s1,s1,a5
    80005b36:	77fd                	lui	a5,0xfffff
    80005b38:	8fe5                	and	a5,a5,s1
    80005b3a:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b3e:	6609                	lui	a2,0x2
    80005b40:	963e                	add	a2,a2,a5
    80005b42:	85be                	mv	a1,a5
    80005b44:	c0843483          	ld	s1,-1016(s0)
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffc097          	auipc	ra,0xffffc
    80005b4e:	8fc080e7          	jalr	-1796(ra) # 80001446 <uvmalloc>
    80005b52:	8aaa                	mv	s5,a0
  ip = 0;
    80005b54:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b56:	14050263          	beqz	a0,80005c9a <exec+0x372>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005b5a:	75f9                	lui	a1,0xffffe
    80005b5c:	95aa                	add	a1,a1,a0
    80005b5e:	8526                	mv	a0,s1
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	b14080e7          	jalr	-1260(ra) # 80001674 <uvmclear>
  stackbase = sp - PGSIZE;
    80005b68:	7bfd                	lui	s7,0xfffff
    80005b6a:	9bd6                	add	s7,s7,s5
  for(argc = 0; argv[argc]; argc++) {
    80005b6c:	be843783          	ld	a5,-1048(s0)
    80005b70:	6388                	ld	a0,0(a5)
    80005b72:	c92d                	beqz	a0,80005be4 <exec+0x2bc>
    80005b74:	e8840993          	addi	s3,s0,-376
    80005b78:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005b7c:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005b7e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005b80:	ffffb097          	auipc	ra,0xffffb
    80005b84:	2d4080e7          	jalr	724(ra) # 80000e54 <strlen>
    80005b88:	0015079b          	addiw	a5,a0,1
    80005b8c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005b90:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005b94:	15796c63          	bltu	s2,s7,80005cec <exec+0x3c4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005b98:	be843d03          	ld	s10,-1048(s0)
    80005b9c:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80005ba0:	8552                	mv	a0,s4
    80005ba2:	ffffb097          	auipc	ra,0xffffb
    80005ba6:	2b2080e7          	jalr	690(ra) # 80000e54 <strlen>
    80005baa:	0015069b          	addiw	a3,a0,1
    80005bae:	8652                	mv	a2,s4
    80005bb0:	85ca                	mv	a1,s2
    80005bb2:	c0843503          	ld	a0,-1016(s0)
    80005bb6:	ffffc097          	auipc	ra,0xffffc
    80005bba:	af0080e7          	jalr	-1296(ra) # 800016a6 <copyout>
    80005bbe:	12054b63          	bltz	a0,80005cf4 <exec+0x3cc>
    ustack[argc] = sp;
    80005bc2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005bc6:	0485                	addi	s1,s1,1
    80005bc8:	008d0793          	addi	a5,s10,8
    80005bcc:	bef43423          	sd	a5,-1048(s0)
    80005bd0:	008d3503          	ld	a0,8(s10)
    80005bd4:	c911                	beqz	a0,80005be8 <exec+0x2c0>
    if(argc >= MAXARG)
    80005bd6:	09a1                	addi	s3,s3,8
    80005bd8:	fb8994e3          	bne	s3,s8,80005b80 <exec+0x258>
  sz = sz1;
    80005bdc:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005be0:	4a01                	li	s4,0
    80005be2:	a865                	j	80005c9a <exec+0x372>
  sp = sz;
    80005be4:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005be6:	4481                	li	s1,0
  ustack[argc] = 0;
    80005be8:	00349793          	slli	a5,s1,0x3
    80005bec:	f9040713          	addi	a4,s0,-112
    80005bf0:	97ba                	add	a5,a5,a4
    80005bf2:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005bf6:	00148693          	addi	a3,s1,1
    80005bfa:	068e                	slli	a3,a3,0x3
    80005bfc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c00:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005c04:	01797663          	bgeu	s2,s7,80005c10 <exec+0x2e8>
  sz = sz1;
    80005c08:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005c0c:	4a01                	li	s4,0
    80005c0e:	a071                	j	80005c9a <exec+0x372>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c10:	e8840613          	addi	a2,s0,-376
    80005c14:	85ca                	mv	a1,s2
    80005c16:	c0843503          	ld	a0,-1016(s0)
    80005c1a:	ffffc097          	auipc	ra,0xffffc
    80005c1e:	a8c080e7          	jalr	-1396(ra) # 800016a6 <copyout>
    80005c22:	0c054d63          	bltz	a0,80005cfc <exec+0x3d4>
  p->trapframe->a1 = sp;
    80005c26:	058b3783          	ld	a5,88(s6)
    80005c2a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c2e:	be043783          	ld	a5,-1056(s0)
    80005c32:	0007c703          	lbu	a4,0(a5)
    80005c36:	cf11                	beqz	a4,80005c52 <exec+0x32a>
    80005c38:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005c3a:	02f00693          	li	a3,47
    80005c3e:	a039                	j	80005c4c <exec+0x324>
      last = s+1;
    80005c40:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005c44:	0785                	addi	a5,a5,1
    80005c46:	fff7c703          	lbu	a4,-1(a5)
    80005c4a:	c701                	beqz	a4,80005c52 <exec+0x32a>
    if(*s == '/')
    80005c4c:	fed71ce3          	bne	a4,a3,80005c44 <exec+0x31c>
    80005c50:	bfc5                	j	80005c40 <exec+0x318>
  safestrcpy(p->name, last, sizeof(p->name));
    80005c52:	4641                	li	a2,16
    80005c54:	be043583          	ld	a1,-1056(s0)
    80005c58:	158b0513          	addi	a0,s6,344
    80005c5c:	ffffb097          	auipc	ra,0xffffb
    80005c60:	1c6080e7          	jalr	454(ra) # 80000e22 <safestrcpy>
  oldpagetable = p->pagetable;
    80005c64:	050b3503          	ld	a0,80(s6)
  p->pagetable = pagetable;
    80005c68:	c0843783          	ld	a5,-1016(s0)
    80005c6c:	04fb3823          	sd	a5,80(s6)
  p->sz = sz;
    80005c70:	055b3423          	sd	s5,72(s6)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005c74:	058b3783          	ld	a5,88(s6)
    80005c78:	e6043703          	ld	a4,-416(s0)
    80005c7c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005c7e:	058b3783          	ld	a5,88(s6)
    80005c82:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005c86:	85e6                	mv	a1,s9
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	ebe080e7          	jalr	-322(ra) # 80001b46 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005c90:	0004851b          	sext.w	a0,s1
    80005c94:	b37d                	j	80005a42 <exec+0x11a>
    80005c96:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005c9a:	10000613          	li	a2,256
    80005c9e:	d1040593          	addi	a1,s0,-752
    80005ca2:	170b0513          	addi	a0,s6,368
    80005ca6:	ffffb097          	auipc	ra,0xffffb
    80005caa:	086080e7          	jalr	134(ra) # 80000d2c <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005cae:	10000613          	li	a2,256
    80005cb2:	c1040593          	addi	a1,s0,-1008
    80005cb6:	270b0513          	addi	a0,s6,624
    80005cba:	ffffb097          	auipc	ra,0xffffb
    80005cbe:	072080e7          	jalr	114(ra) # 80000d2c <memmove>
    proc_freepagetable(pagetable, sz);
    80005cc2:	bf043583          	ld	a1,-1040(s0)
    80005cc6:	c0843503          	ld	a0,-1016(s0)
    80005cca:	ffffc097          	auipc	ra,0xffffc
    80005cce:	e7c080e7          	jalr	-388(ra) # 80001b46 <proc_freepagetable>
  if(ip){
    80005cd2:	d40a1ee3          	bnez	s4,80005a2e <exec+0x106>
  return -1;
    80005cd6:	557d                	li	a0,-1
    80005cd8:	b3ad                	j	80005a42 <exec+0x11a>
    80005cda:	be943823          	sd	s1,-1040(s0)
    80005cde:	bf75                	j	80005c9a <exec+0x372>
    80005ce0:	be943823          	sd	s1,-1040(s0)
    80005ce4:	bf5d                	j	80005c9a <exec+0x372>
    80005ce6:	be943823          	sd	s1,-1040(s0)
    80005cea:	bf45                	j	80005c9a <exec+0x372>
  sz = sz1;
    80005cec:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005cf0:	4a01                	li	s4,0
    80005cf2:	b765                	j	80005c9a <exec+0x372>
  sz = sz1;
    80005cf4:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005cf8:	4a01                	li	s4,0
    80005cfa:	b745                	j	80005c9a <exec+0x372>
  sz = sz1;
    80005cfc:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d00:	4a01                	li	s4,0
    80005d02:	bf61                	j	80005c9a <exec+0x372>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d04:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d08:	c0043783          	ld	a5,-1024(s0)
    80005d0c:	0017869b          	addiw	a3,a5,1
    80005d10:	c0d43023          	sd	a3,-1024(s0)
    80005d14:	bf843783          	ld	a5,-1032(s0)
    80005d18:	0387879b          	addiw	a5,a5,56
    80005d1c:	e8045703          	lhu	a4,-384(s0)
    80005d20:	dee6d8e3          	bge	a3,a4,80005b10 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005d24:	2781                	sext.w	a5,a5
    80005d26:	bef43c23          	sd	a5,-1032(s0)
    80005d2a:	03800713          	li	a4,56
    80005d2e:	86be                	mv	a3,a5
    80005d30:	e1040613          	addi	a2,s0,-496
    80005d34:	4581                	li	a1,0
    80005d36:	8552                	mv	a0,s4
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	4a8080e7          	jalr	1192(ra) # 800041e0 <readi>
    80005d40:	03800793          	li	a5,56
    80005d44:	f4f519e3          	bne	a0,a5,80005c96 <exec+0x36e>
    if(ph.type != ELF_PROG_LOAD)
    80005d48:	e1042783          	lw	a5,-496(s0)
    80005d4c:	4705                	li	a4,1
    80005d4e:	fae79de3          	bne	a5,a4,80005d08 <exec+0x3e0>
    if(ph.memsz < ph.filesz)
    80005d52:	e3843603          	ld	a2,-456(s0)
    80005d56:	e3043783          	ld	a5,-464(s0)
    80005d5a:	f8f660e3          	bltu	a2,a5,80005cda <exec+0x3b2>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005d5e:	e2043783          	ld	a5,-480(s0)
    80005d62:	963e                	add	a2,a2,a5
    80005d64:	f6f66ee3          	bltu	a2,a5,80005ce0 <exec+0x3b8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d68:	85a6                	mv	a1,s1
    80005d6a:	c0843503          	ld	a0,-1016(s0)
    80005d6e:	ffffb097          	auipc	ra,0xffffb
    80005d72:	6d8080e7          	jalr	1752(ra) # 80001446 <uvmalloc>
    80005d76:	bea43823          	sd	a0,-1040(s0)
    80005d7a:	d535                	beqz	a0,80005ce6 <exec+0x3be>
    if(ph.vaddr % PGSIZE != 0)
    80005d7c:	e2043c03          	ld	s8,-480(s0)
    80005d80:	bd843783          	ld	a5,-1064(s0)
    80005d84:	00fc77b3          	and	a5,s8,a5
    80005d88:	fb89                	bnez	a5,80005c9a <exec+0x372>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005d8a:	e1842c83          	lw	s9,-488(s0)
    80005d8e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005d92:	f60b89e3          	beqz	s7,80005d04 <exec+0x3dc>
    80005d96:	89de                	mv	s3,s7
    80005d98:	4481                	li	s1,0
    80005d9a:	bb89                	j	80005aec <exec+0x1c4>

0000000080005d9c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005d9c:	7179                	addi	sp,sp,-48
    80005d9e:	f406                	sd	ra,40(sp)
    80005da0:	f022                	sd	s0,32(sp)
    80005da2:	ec26                	sd	s1,24(sp)
    80005da4:	e84a                	sd	s2,16(sp)
    80005da6:	1800                	addi	s0,sp,48
    80005da8:	892e                	mv	s2,a1
    80005daa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005dac:	fdc40593          	addi	a1,s0,-36
    80005db0:	ffffd097          	auipc	ra,0xffffd
    80005db4:	60a080e7          	jalr	1546(ra) # 800033ba <argint>
    80005db8:	04054063          	bltz	a0,80005df8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005dbc:	fdc42703          	lw	a4,-36(s0)
    80005dc0:	47bd                	li	a5,15
    80005dc2:	02e7ed63          	bltu	a5,a4,80005dfc <argfd+0x60>
    80005dc6:	ffffc097          	auipc	ra,0xffffc
    80005dca:	c20080e7          	jalr	-992(ra) # 800019e6 <myproc>
    80005dce:	fdc42703          	lw	a4,-36(s0)
    80005dd2:	01a70793          	addi	a5,a4,26
    80005dd6:	078e                	slli	a5,a5,0x3
    80005dd8:	953e                	add	a0,a0,a5
    80005dda:	611c                	ld	a5,0(a0)
    80005ddc:	c395                	beqz	a5,80005e00 <argfd+0x64>
    return -1;
  if(pfd)
    80005dde:	00090463          	beqz	s2,80005de6 <argfd+0x4a>
    *pfd = fd;
    80005de2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005de6:	4501                	li	a0,0
  if(pf)
    80005de8:	c091                	beqz	s1,80005dec <argfd+0x50>
    *pf = f;
    80005dea:	e09c                	sd	a5,0(s1)
}
    80005dec:	70a2                	ld	ra,40(sp)
    80005dee:	7402                	ld	s0,32(sp)
    80005df0:	64e2                	ld	s1,24(sp)
    80005df2:	6942                	ld	s2,16(sp)
    80005df4:	6145                	addi	sp,sp,48
    80005df6:	8082                	ret
    return -1;
    80005df8:	557d                	li	a0,-1
    80005dfa:	bfcd                	j	80005dec <argfd+0x50>
    return -1;
    80005dfc:	557d                	li	a0,-1
    80005dfe:	b7fd                	j	80005dec <argfd+0x50>
    80005e00:	557d                	li	a0,-1
    80005e02:	b7ed                	j	80005dec <argfd+0x50>

0000000080005e04 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005e04:	1101                	addi	sp,sp,-32
    80005e06:	ec06                	sd	ra,24(sp)
    80005e08:	e822                	sd	s0,16(sp)
    80005e0a:	e426                	sd	s1,8(sp)
    80005e0c:	1000                	addi	s0,sp,32
    80005e0e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	bd6080e7          	jalr	-1066(ra) # 800019e6 <myproc>
    80005e18:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005e1a:	0d050793          	addi	a5,a0,208
    80005e1e:	4501                	li	a0,0
    80005e20:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005e22:	6398                	ld	a4,0(a5)
    80005e24:	cb19                	beqz	a4,80005e3a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005e26:	2505                	addiw	a0,a0,1
    80005e28:	07a1                	addi	a5,a5,8
    80005e2a:	fed51ce3          	bne	a0,a3,80005e22 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005e2e:	557d                	li	a0,-1
}
    80005e30:	60e2                	ld	ra,24(sp)
    80005e32:	6442                	ld	s0,16(sp)
    80005e34:	64a2                	ld	s1,8(sp)
    80005e36:	6105                	addi	sp,sp,32
    80005e38:	8082                	ret
      p->ofile[fd] = f;
    80005e3a:	01a50793          	addi	a5,a0,26
    80005e3e:	078e                	slli	a5,a5,0x3
    80005e40:	963e                	add	a2,a2,a5
    80005e42:	e204                	sd	s1,0(a2)
      return fd;
    80005e44:	b7f5                	j	80005e30 <fdalloc+0x2c>

0000000080005e46 <sys_dup>:

uint64
sys_dup(void)
{
    80005e46:	7179                	addi	sp,sp,-48
    80005e48:	f406                	sd	ra,40(sp)
    80005e4a:	f022                	sd	s0,32(sp)
    80005e4c:	ec26                	sd	s1,24(sp)
    80005e4e:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005e50:	fd840613          	addi	a2,s0,-40
    80005e54:	4581                	li	a1,0
    80005e56:	4501                	li	a0,0
    80005e58:	00000097          	auipc	ra,0x0
    80005e5c:	f44080e7          	jalr	-188(ra) # 80005d9c <argfd>
    return -1;
    80005e60:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e62:	02054363          	bltz	a0,80005e88 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e66:	fd843503          	ld	a0,-40(s0)
    80005e6a:	00000097          	auipc	ra,0x0
    80005e6e:	f9a080e7          	jalr	-102(ra) # 80005e04 <fdalloc>
    80005e72:	84aa                	mv	s1,a0
    return -1;
    80005e74:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e76:	00054963          	bltz	a0,80005e88 <sys_dup+0x42>
  filedup(f);
    80005e7a:	fd843503          	ld	a0,-40(s0)
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	210080e7          	jalr	528(ra) # 8000508e <filedup>
  return fd;
    80005e86:	87a6                	mv	a5,s1
}
    80005e88:	853e                	mv	a0,a5
    80005e8a:	70a2                	ld	ra,40(sp)
    80005e8c:	7402                	ld	s0,32(sp)
    80005e8e:	64e2                	ld	s1,24(sp)
    80005e90:	6145                	addi	sp,sp,48
    80005e92:	8082                	ret

0000000080005e94 <sys_read>:

uint64
sys_read(void)
{
    80005e94:	7179                	addi	sp,sp,-48
    80005e96:	f406                	sd	ra,40(sp)
    80005e98:	f022                	sd	s0,32(sp)
    80005e9a:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e9c:	fe840613          	addi	a2,s0,-24
    80005ea0:	4581                	li	a1,0
    80005ea2:	4501                	li	a0,0
    80005ea4:	00000097          	auipc	ra,0x0
    80005ea8:	ef8080e7          	jalr	-264(ra) # 80005d9c <argfd>
    return -1;
    80005eac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eae:	04054163          	bltz	a0,80005ef0 <sys_read+0x5c>
    80005eb2:	fe440593          	addi	a1,s0,-28
    80005eb6:	4509                	li	a0,2
    80005eb8:	ffffd097          	auipc	ra,0xffffd
    80005ebc:	502080e7          	jalr	1282(ra) # 800033ba <argint>
    return -1;
    80005ec0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ec2:	02054763          	bltz	a0,80005ef0 <sys_read+0x5c>
    80005ec6:	fd840593          	addi	a1,s0,-40
    80005eca:	4505                	li	a0,1
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	510080e7          	jalr	1296(ra) # 800033dc <argaddr>
    return -1;
    80005ed4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ed6:	00054d63          	bltz	a0,80005ef0 <sys_read+0x5c>
  return fileread(f, p, n);
    80005eda:	fe442603          	lw	a2,-28(s0)
    80005ede:	fd843583          	ld	a1,-40(s0)
    80005ee2:	fe843503          	ld	a0,-24(s0)
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	334080e7          	jalr	820(ra) # 8000521a <fileread>
    80005eee:	87aa                	mv	a5,a0
}
    80005ef0:	853e                	mv	a0,a5
    80005ef2:	70a2                	ld	ra,40(sp)
    80005ef4:	7402                	ld	s0,32(sp)
    80005ef6:	6145                	addi	sp,sp,48
    80005ef8:	8082                	ret

0000000080005efa <sys_write>:

uint64
sys_write(void)
{
    80005efa:	7179                	addi	sp,sp,-48
    80005efc:	f406                	sd	ra,40(sp)
    80005efe:	f022                	sd	s0,32(sp)
    80005f00:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f02:	fe840613          	addi	a2,s0,-24
    80005f06:	4581                	li	a1,0
    80005f08:	4501                	li	a0,0
    80005f0a:	00000097          	auipc	ra,0x0
    80005f0e:	e92080e7          	jalr	-366(ra) # 80005d9c <argfd>
    return -1;
    80005f12:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f14:	04054163          	bltz	a0,80005f56 <sys_write+0x5c>
    80005f18:	fe440593          	addi	a1,s0,-28
    80005f1c:	4509                	li	a0,2
    80005f1e:	ffffd097          	auipc	ra,0xffffd
    80005f22:	49c080e7          	jalr	1180(ra) # 800033ba <argint>
    return -1;
    80005f26:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f28:	02054763          	bltz	a0,80005f56 <sys_write+0x5c>
    80005f2c:	fd840593          	addi	a1,s0,-40
    80005f30:	4505                	li	a0,1
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	4aa080e7          	jalr	1194(ra) # 800033dc <argaddr>
    return -1;
    80005f3a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f3c:	00054d63          	bltz	a0,80005f56 <sys_write+0x5c>

  return filewrite(f, p, n);
    80005f40:	fe442603          	lw	a2,-28(s0)
    80005f44:	fd843583          	ld	a1,-40(s0)
    80005f48:	fe843503          	ld	a0,-24(s0)
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	390080e7          	jalr	912(ra) # 800052dc <filewrite>
    80005f54:	87aa                	mv	a5,a0
}
    80005f56:	853e                	mv	a0,a5
    80005f58:	70a2                	ld	ra,40(sp)
    80005f5a:	7402                	ld	s0,32(sp)
    80005f5c:	6145                	addi	sp,sp,48
    80005f5e:	8082                	ret

0000000080005f60 <sys_close>:

uint64
sys_close(void)
{
    80005f60:	1101                	addi	sp,sp,-32
    80005f62:	ec06                	sd	ra,24(sp)
    80005f64:	e822                	sd	s0,16(sp)
    80005f66:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005f68:	fe040613          	addi	a2,s0,-32
    80005f6c:	fec40593          	addi	a1,s0,-20
    80005f70:	4501                	li	a0,0
    80005f72:	00000097          	auipc	ra,0x0
    80005f76:	e2a080e7          	jalr	-470(ra) # 80005d9c <argfd>
    return -1;
    80005f7a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f7c:	02054463          	bltz	a0,80005fa4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f80:	ffffc097          	auipc	ra,0xffffc
    80005f84:	a66080e7          	jalr	-1434(ra) # 800019e6 <myproc>
    80005f88:	fec42783          	lw	a5,-20(s0)
    80005f8c:	07e9                	addi	a5,a5,26
    80005f8e:	078e                	slli	a5,a5,0x3
    80005f90:	97aa                	add	a5,a5,a0
    80005f92:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005f96:	fe043503          	ld	a0,-32(s0)
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	146080e7          	jalr	326(ra) # 800050e0 <fileclose>
  return 0;
    80005fa2:	4781                	li	a5,0
}
    80005fa4:	853e                	mv	a0,a5
    80005fa6:	60e2                	ld	ra,24(sp)
    80005fa8:	6442                	ld	s0,16(sp)
    80005faa:	6105                	addi	sp,sp,32
    80005fac:	8082                	ret

0000000080005fae <sys_fstat>:

uint64
sys_fstat(void)
{
    80005fae:	1101                	addi	sp,sp,-32
    80005fb0:	ec06                	sd	ra,24(sp)
    80005fb2:	e822                	sd	s0,16(sp)
    80005fb4:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fb6:	fe840613          	addi	a2,s0,-24
    80005fba:	4581                	li	a1,0
    80005fbc:	4501                	li	a0,0
    80005fbe:	00000097          	auipc	ra,0x0
    80005fc2:	dde080e7          	jalr	-546(ra) # 80005d9c <argfd>
    return -1;
    80005fc6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fc8:	02054563          	bltz	a0,80005ff2 <sys_fstat+0x44>
    80005fcc:	fe040593          	addi	a1,s0,-32
    80005fd0:	4505                	li	a0,1
    80005fd2:	ffffd097          	auipc	ra,0xffffd
    80005fd6:	40a080e7          	jalr	1034(ra) # 800033dc <argaddr>
    return -1;
    80005fda:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fdc:	00054b63          	bltz	a0,80005ff2 <sys_fstat+0x44>
  return filestat(f, st);
    80005fe0:	fe043583          	ld	a1,-32(s0)
    80005fe4:	fe843503          	ld	a0,-24(s0)
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	1c0080e7          	jalr	448(ra) # 800051a8 <filestat>
    80005ff0:	87aa                	mv	a5,a0
}
    80005ff2:	853e                	mv	a0,a5
    80005ff4:	60e2                	ld	ra,24(sp)
    80005ff6:	6442                	ld	s0,16(sp)
    80005ff8:	6105                	addi	sp,sp,32
    80005ffa:	8082                	ret

0000000080005ffc <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005ffc:	7169                	addi	sp,sp,-304
    80005ffe:	f606                	sd	ra,296(sp)
    80006000:	f222                	sd	s0,288(sp)
    80006002:	ee26                	sd	s1,280(sp)
    80006004:	ea4a                	sd	s2,272(sp)
    80006006:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006008:	08000613          	li	a2,128
    8000600c:	ed040593          	addi	a1,s0,-304
    80006010:	4501                	li	a0,0
    80006012:	ffffd097          	auipc	ra,0xffffd
    80006016:	3ec080e7          	jalr	1004(ra) # 800033fe <argstr>
    return -1;
    8000601a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000601c:	10054e63          	bltz	a0,80006138 <sys_link+0x13c>
    80006020:	08000613          	li	a2,128
    80006024:	f5040593          	addi	a1,s0,-176
    80006028:	4505                	li	a0,1
    8000602a:	ffffd097          	auipc	ra,0xffffd
    8000602e:	3d4080e7          	jalr	980(ra) # 800033fe <argstr>
    return -1;
    80006032:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006034:	10054263          	bltz	a0,80006138 <sys_link+0x13c>

  begin_op();
    80006038:	fffff097          	auipc	ra,0xfffff
    8000603c:	bdc080e7          	jalr	-1060(ra) # 80004c14 <begin_op>
  if((ip = namei(old)) == 0){
    80006040:	ed040513          	addi	a0,s0,-304
    80006044:	ffffe097          	auipc	ra,0xffffe
    80006048:	69e080e7          	jalr	1694(ra) # 800046e2 <namei>
    8000604c:	84aa                	mv	s1,a0
    8000604e:	c551                	beqz	a0,800060da <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80006050:	ffffe097          	auipc	ra,0xffffe
    80006054:	edc080e7          	jalr	-292(ra) # 80003f2c <ilock>
  if(ip->type == T_DIR){
    80006058:	04449703          	lh	a4,68(s1)
    8000605c:	4785                	li	a5,1
    8000605e:	08f70463          	beq	a4,a5,800060e6 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80006062:	04a4d783          	lhu	a5,74(s1)
    80006066:	2785                	addiw	a5,a5,1
    80006068:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000606c:	8526                	mv	a0,s1
    8000606e:	ffffe097          	auipc	ra,0xffffe
    80006072:	df4080e7          	jalr	-524(ra) # 80003e62 <iupdate>
  iunlock(ip);
    80006076:	8526                	mv	a0,s1
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	f76080e7          	jalr	-138(ra) # 80003fee <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80006080:	fd040593          	addi	a1,s0,-48
    80006084:	f5040513          	addi	a0,s0,-176
    80006088:	ffffe097          	auipc	ra,0xffffe
    8000608c:	678080e7          	jalr	1656(ra) # 80004700 <nameiparent>
    80006090:	892a                	mv	s2,a0
    80006092:	c935                	beqz	a0,80006106 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80006094:	ffffe097          	auipc	ra,0xffffe
    80006098:	e98080e7          	jalr	-360(ra) # 80003f2c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000609c:	00092703          	lw	a4,0(s2)
    800060a0:	409c                	lw	a5,0(s1)
    800060a2:	04f71d63          	bne	a4,a5,800060fc <sys_link+0x100>
    800060a6:	40d0                	lw	a2,4(s1)
    800060a8:	fd040593          	addi	a1,s0,-48
    800060ac:	854a                	mv	a0,s2
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	572080e7          	jalr	1394(ra) # 80004620 <dirlink>
    800060b6:	04054363          	bltz	a0,800060fc <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    800060ba:	854a                	mv	a0,s2
    800060bc:	ffffe097          	auipc	ra,0xffffe
    800060c0:	0d2080e7          	jalr	210(ra) # 8000418e <iunlockput>
  iput(ip);
    800060c4:	8526                	mv	a0,s1
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	020080e7          	jalr	32(ra) # 800040e6 <iput>

  end_op();
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	bc6080e7          	jalr	-1082(ra) # 80004c94 <end_op>

  return 0;
    800060d6:	4781                	li	a5,0
    800060d8:	a085                	j	80006138 <sys_link+0x13c>
    end_op();
    800060da:	fffff097          	auipc	ra,0xfffff
    800060de:	bba080e7          	jalr	-1094(ra) # 80004c94 <end_op>
    return -1;
    800060e2:	57fd                	li	a5,-1
    800060e4:	a891                	j	80006138 <sys_link+0x13c>
    iunlockput(ip);
    800060e6:	8526                	mv	a0,s1
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	0a6080e7          	jalr	166(ra) # 8000418e <iunlockput>
    end_op();
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	ba4080e7          	jalr	-1116(ra) # 80004c94 <end_op>
    return -1;
    800060f8:	57fd                	li	a5,-1
    800060fa:	a83d                	j	80006138 <sys_link+0x13c>
    iunlockput(dp);
    800060fc:	854a                	mv	a0,s2
    800060fe:	ffffe097          	auipc	ra,0xffffe
    80006102:	090080e7          	jalr	144(ra) # 8000418e <iunlockput>

bad:
  ilock(ip);
    80006106:	8526                	mv	a0,s1
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	e24080e7          	jalr	-476(ra) # 80003f2c <ilock>
  ip->nlink--;
    80006110:	04a4d783          	lhu	a5,74(s1)
    80006114:	37fd                	addiw	a5,a5,-1
    80006116:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000611a:	8526                	mv	a0,s1
    8000611c:	ffffe097          	auipc	ra,0xffffe
    80006120:	d46080e7          	jalr	-698(ra) # 80003e62 <iupdate>
  iunlockput(ip);
    80006124:	8526                	mv	a0,s1
    80006126:	ffffe097          	auipc	ra,0xffffe
    8000612a:	068080e7          	jalr	104(ra) # 8000418e <iunlockput>
  end_op();
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	b66080e7          	jalr	-1178(ra) # 80004c94 <end_op>
  return -1;
    80006136:	57fd                	li	a5,-1
}
    80006138:	853e                	mv	a0,a5
    8000613a:	70b2                	ld	ra,296(sp)
    8000613c:	7412                	ld	s0,288(sp)
    8000613e:	64f2                	ld	s1,280(sp)
    80006140:	6952                	ld	s2,272(sp)
    80006142:	6155                	addi	sp,sp,304
    80006144:	8082                	ret

0000000080006146 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006146:	4578                	lw	a4,76(a0)
    80006148:	02000793          	li	a5,32
    8000614c:	04e7fa63          	bgeu	a5,a4,800061a0 <isdirempty+0x5a>
{
    80006150:	7179                	addi	sp,sp,-48
    80006152:	f406                	sd	ra,40(sp)
    80006154:	f022                	sd	s0,32(sp)
    80006156:	ec26                	sd	s1,24(sp)
    80006158:	e84a                	sd	s2,16(sp)
    8000615a:	1800                	addi	s0,sp,48
    8000615c:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000615e:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006162:	4741                	li	a4,16
    80006164:	86a6                	mv	a3,s1
    80006166:	fd040613          	addi	a2,s0,-48
    8000616a:	4581                	li	a1,0
    8000616c:	854a                	mv	a0,s2
    8000616e:	ffffe097          	auipc	ra,0xffffe
    80006172:	072080e7          	jalr	114(ra) # 800041e0 <readi>
    80006176:	47c1                	li	a5,16
    80006178:	00f51c63          	bne	a0,a5,80006190 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    8000617c:	fd045783          	lhu	a5,-48(s0)
    80006180:	e395                	bnez	a5,800061a4 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006182:	24c1                	addiw	s1,s1,16
    80006184:	04c92783          	lw	a5,76(s2)
    80006188:	fcf4ede3          	bltu	s1,a5,80006162 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    8000618c:	4505                	li	a0,1
    8000618e:	a821                	j	800061a6 <isdirempty+0x60>
      panic("isdirempty: readi");
    80006190:	00004517          	auipc	a0,0x4
    80006194:	89050513          	addi	a0,a0,-1904 # 80009a20 <syscalls+0x310>
    80006198:	ffffa097          	auipc	ra,0xffffa
    8000619c:	392080e7          	jalr	914(ra) # 8000052a <panic>
  return 1;
    800061a0:	4505                	li	a0,1
}
    800061a2:	8082                	ret
      return 0;
    800061a4:	4501                	li	a0,0
}
    800061a6:	70a2                	ld	ra,40(sp)
    800061a8:	7402                	ld	s0,32(sp)
    800061aa:	64e2                	ld	s1,24(sp)
    800061ac:	6942                	ld	s2,16(sp)
    800061ae:	6145                	addi	sp,sp,48
    800061b0:	8082                	ret

00000000800061b2 <sys_unlink>:

uint64
sys_unlink(void)
{
    800061b2:	7155                	addi	sp,sp,-208
    800061b4:	e586                	sd	ra,200(sp)
    800061b6:	e1a2                	sd	s0,192(sp)
    800061b8:	fd26                	sd	s1,184(sp)
    800061ba:	f94a                	sd	s2,176(sp)
    800061bc:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    800061be:	08000613          	li	a2,128
    800061c2:	f4040593          	addi	a1,s0,-192
    800061c6:	4501                	li	a0,0
    800061c8:	ffffd097          	auipc	ra,0xffffd
    800061cc:	236080e7          	jalr	566(ra) # 800033fe <argstr>
    800061d0:	16054363          	bltz	a0,80006336 <sys_unlink+0x184>
    return -1;

  begin_op();
    800061d4:	fffff097          	auipc	ra,0xfffff
    800061d8:	a40080e7          	jalr	-1472(ra) # 80004c14 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800061dc:	fc040593          	addi	a1,s0,-64
    800061e0:	f4040513          	addi	a0,s0,-192
    800061e4:	ffffe097          	auipc	ra,0xffffe
    800061e8:	51c080e7          	jalr	1308(ra) # 80004700 <nameiparent>
    800061ec:	84aa                	mv	s1,a0
    800061ee:	c961                	beqz	a0,800062be <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    800061f0:	ffffe097          	auipc	ra,0xffffe
    800061f4:	d3c080e7          	jalr	-708(ra) # 80003f2c <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800061f8:	00003597          	auipc	a1,0x3
    800061fc:	70858593          	addi	a1,a1,1800 # 80009900 <syscalls+0x1f0>
    80006200:	fc040513          	addi	a0,s0,-64
    80006204:	ffffe097          	auipc	ra,0xffffe
    80006208:	1f2080e7          	jalr	498(ra) # 800043f6 <namecmp>
    8000620c:	c175                	beqz	a0,800062f0 <sys_unlink+0x13e>
    8000620e:	00003597          	auipc	a1,0x3
    80006212:	6fa58593          	addi	a1,a1,1786 # 80009908 <syscalls+0x1f8>
    80006216:	fc040513          	addi	a0,s0,-64
    8000621a:	ffffe097          	auipc	ra,0xffffe
    8000621e:	1dc080e7          	jalr	476(ra) # 800043f6 <namecmp>
    80006222:	c579                	beqz	a0,800062f0 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80006224:	f3c40613          	addi	a2,s0,-196
    80006228:	fc040593          	addi	a1,s0,-64
    8000622c:	8526                	mv	a0,s1
    8000622e:	ffffe097          	auipc	ra,0xffffe
    80006232:	1e2080e7          	jalr	482(ra) # 80004410 <dirlookup>
    80006236:	892a                	mv	s2,a0
    80006238:	cd45                	beqz	a0,800062f0 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    8000623a:	ffffe097          	auipc	ra,0xffffe
    8000623e:	cf2080e7          	jalr	-782(ra) # 80003f2c <ilock>

  if(ip->nlink < 1)
    80006242:	04a91783          	lh	a5,74(s2)
    80006246:	08f05263          	blez	a5,800062ca <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000624a:	04491703          	lh	a4,68(s2)
    8000624e:	4785                	li	a5,1
    80006250:	08f70563          	beq	a4,a5,800062da <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80006254:	4641                	li	a2,16
    80006256:	4581                	li	a1,0
    80006258:	fd040513          	addi	a0,s0,-48
    8000625c:	ffffb097          	auipc	ra,0xffffb
    80006260:	a74080e7          	jalr	-1420(ra) # 80000cd0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006264:	4741                	li	a4,16
    80006266:	f3c42683          	lw	a3,-196(s0)
    8000626a:	fd040613          	addi	a2,s0,-48
    8000626e:	4581                	li	a1,0
    80006270:	8526                	mv	a0,s1
    80006272:	ffffe097          	auipc	ra,0xffffe
    80006276:	066080e7          	jalr	102(ra) # 800042d8 <writei>
    8000627a:	47c1                	li	a5,16
    8000627c:	08f51a63          	bne	a0,a5,80006310 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80006280:	04491703          	lh	a4,68(s2)
    80006284:	4785                	li	a5,1
    80006286:	08f70d63          	beq	a4,a5,80006320 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000628a:	8526                	mv	a0,s1
    8000628c:	ffffe097          	auipc	ra,0xffffe
    80006290:	f02080e7          	jalr	-254(ra) # 8000418e <iunlockput>

  ip->nlink--;
    80006294:	04a95783          	lhu	a5,74(s2)
    80006298:	37fd                	addiw	a5,a5,-1
    8000629a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000629e:	854a                	mv	a0,s2
    800062a0:	ffffe097          	auipc	ra,0xffffe
    800062a4:	bc2080e7          	jalr	-1086(ra) # 80003e62 <iupdate>
  iunlockput(ip);
    800062a8:	854a                	mv	a0,s2
    800062aa:	ffffe097          	auipc	ra,0xffffe
    800062ae:	ee4080e7          	jalr	-284(ra) # 8000418e <iunlockput>

  end_op();
    800062b2:	fffff097          	auipc	ra,0xfffff
    800062b6:	9e2080e7          	jalr	-1566(ra) # 80004c94 <end_op>

  return 0;
    800062ba:	4501                	li	a0,0
    800062bc:	a0a1                	j	80006304 <sys_unlink+0x152>
    end_op();
    800062be:	fffff097          	auipc	ra,0xfffff
    800062c2:	9d6080e7          	jalr	-1578(ra) # 80004c94 <end_op>
    return -1;
    800062c6:	557d                	li	a0,-1
    800062c8:	a835                	j	80006304 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    800062ca:	00003517          	auipc	a0,0x3
    800062ce:	64650513          	addi	a0,a0,1606 # 80009910 <syscalls+0x200>
    800062d2:	ffffa097          	auipc	ra,0xffffa
    800062d6:	258080e7          	jalr	600(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800062da:	854a                	mv	a0,s2
    800062dc:	00000097          	auipc	ra,0x0
    800062e0:	e6a080e7          	jalr	-406(ra) # 80006146 <isdirempty>
    800062e4:	f925                	bnez	a0,80006254 <sys_unlink+0xa2>
    iunlockput(ip);
    800062e6:	854a                	mv	a0,s2
    800062e8:	ffffe097          	auipc	ra,0xffffe
    800062ec:	ea6080e7          	jalr	-346(ra) # 8000418e <iunlockput>

bad:
  iunlockput(dp);
    800062f0:	8526                	mv	a0,s1
    800062f2:	ffffe097          	auipc	ra,0xffffe
    800062f6:	e9c080e7          	jalr	-356(ra) # 8000418e <iunlockput>
  end_op();
    800062fa:	fffff097          	auipc	ra,0xfffff
    800062fe:	99a080e7          	jalr	-1638(ra) # 80004c94 <end_op>
  return -1;
    80006302:	557d                	li	a0,-1
}
    80006304:	60ae                	ld	ra,200(sp)
    80006306:	640e                	ld	s0,192(sp)
    80006308:	74ea                	ld	s1,184(sp)
    8000630a:	794a                	ld	s2,176(sp)
    8000630c:	6169                	addi	sp,sp,208
    8000630e:	8082                	ret
    panic("unlink: writei");
    80006310:	00003517          	auipc	a0,0x3
    80006314:	61850513          	addi	a0,a0,1560 # 80009928 <syscalls+0x218>
    80006318:	ffffa097          	auipc	ra,0xffffa
    8000631c:	212080e7          	jalr	530(ra) # 8000052a <panic>
    dp->nlink--;
    80006320:	04a4d783          	lhu	a5,74(s1)
    80006324:	37fd                	addiw	a5,a5,-1
    80006326:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000632a:	8526                	mv	a0,s1
    8000632c:	ffffe097          	auipc	ra,0xffffe
    80006330:	b36080e7          	jalr	-1226(ra) # 80003e62 <iupdate>
    80006334:	bf99                	j	8000628a <sys_unlink+0xd8>
    return -1;
    80006336:	557d                	li	a0,-1
    80006338:	b7f1                	j	80006304 <sys_unlink+0x152>

000000008000633a <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000633a:	715d                	addi	sp,sp,-80
    8000633c:	e486                	sd	ra,72(sp)
    8000633e:	e0a2                	sd	s0,64(sp)
    80006340:	fc26                	sd	s1,56(sp)
    80006342:	f84a                	sd	s2,48(sp)
    80006344:	f44e                	sd	s3,40(sp)
    80006346:	f052                	sd	s4,32(sp)
    80006348:	ec56                	sd	s5,24(sp)
    8000634a:	0880                	addi	s0,sp,80
    8000634c:	89ae                	mv	s3,a1
    8000634e:	8ab2                	mv	s5,a2
    80006350:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006352:	fb040593          	addi	a1,s0,-80
    80006356:	ffffe097          	auipc	ra,0xffffe
    8000635a:	3aa080e7          	jalr	938(ra) # 80004700 <nameiparent>
    8000635e:	892a                	mv	s2,a0
    80006360:	12050e63          	beqz	a0,8000649c <create+0x162>
    return 0;

  ilock(dp);
    80006364:	ffffe097          	auipc	ra,0xffffe
    80006368:	bc8080e7          	jalr	-1080(ra) # 80003f2c <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000636c:	4601                	li	a2,0
    8000636e:	fb040593          	addi	a1,s0,-80
    80006372:	854a                	mv	a0,s2
    80006374:	ffffe097          	auipc	ra,0xffffe
    80006378:	09c080e7          	jalr	156(ra) # 80004410 <dirlookup>
    8000637c:	84aa                	mv	s1,a0
    8000637e:	c921                	beqz	a0,800063ce <create+0x94>
    iunlockput(dp);
    80006380:	854a                	mv	a0,s2
    80006382:	ffffe097          	auipc	ra,0xffffe
    80006386:	e0c080e7          	jalr	-500(ra) # 8000418e <iunlockput>
    ilock(ip);
    8000638a:	8526                	mv	a0,s1
    8000638c:	ffffe097          	auipc	ra,0xffffe
    80006390:	ba0080e7          	jalr	-1120(ra) # 80003f2c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006394:	2981                	sext.w	s3,s3
    80006396:	4789                	li	a5,2
    80006398:	02f99463          	bne	s3,a5,800063c0 <create+0x86>
    8000639c:	0444d783          	lhu	a5,68(s1)
    800063a0:	37f9                	addiw	a5,a5,-2
    800063a2:	17c2                	slli	a5,a5,0x30
    800063a4:	93c1                	srli	a5,a5,0x30
    800063a6:	4705                	li	a4,1
    800063a8:	00f76c63          	bltu	a4,a5,800063c0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800063ac:	8526                	mv	a0,s1
    800063ae:	60a6                	ld	ra,72(sp)
    800063b0:	6406                	ld	s0,64(sp)
    800063b2:	74e2                	ld	s1,56(sp)
    800063b4:	7942                	ld	s2,48(sp)
    800063b6:	79a2                	ld	s3,40(sp)
    800063b8:	7a02                	ld	s4,32(sp)
    800063ba:	6ae2                	ld	s5,24(sp)
    800063bc:	6161                	addi	sp,sp,80
    800063be:	8082                	ret
    iunlockput(ip);
    800063c0:	8526                	mv	a0,s1
    800063c2:	ffffe097          	auipc	ra,0xffffe
    800063c6:	dcc080e7          	jalr	-564(ra) # 8000418e <iunlockput>
    return 0;
    800063ca:	4481                	li	s1,0
    800063cc:	b7c5                	j	800063ac <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800063ce:	85ce                	mv	a1,s3
    800063d0:	00092503          	lw	a0,0(s2)
    800063d4:	ffffe097          	auipc	ra,0xffffe
    800063d8:	9c0080e7          	jalr	-1600(ra) # 80003d94 <ialloc>
    800063dc:	84aa                	mv	s1,a0
    800063de:	c521                	beqz	a0,80006426 <create+0xec>
  ilock(ip);
    800063e0:	ffffe097          	auipc	ra,0xffffe
    800063e4:	b4c080e7          	jalr	-1204(ra) # 80003f2c <ilock>
  ip->major = major;
    800063e8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800063ec:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800063f0:	4a05                	li	s4,1
    800063f2:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800063f6:	8526                	mv	a0,s1
    800063f8:	ffffe097          	auipc	ra,0xffffe
    800063fc:	a6a080e7          	jalr	-1430(ra) # 80003e62 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006400:	2981                	sext.w	s3,s3
    80006402:	03498a63          	beq	s3,s4,80006436 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80006406:	40d0                	lw	a2,4(s1)
    80006408:	fb040593          	addi	a1,s0,-80
    8000640c:	854a                	mv	a0,s2
    8000640e:	ffffe097          	auipc	ra,0xffffe
    80006412:	212080e7          	jalr	530(ra) # 80004620 <dirlink>
    80006416:	06054b63          	bltz	a0,8000648c <create+0x152>
  iunlockput(dp);
    8000641a:	854a                	mv	a0,s2
    8000641c:	ffffe097          	auipc	ra,0xffffe
    80006420:	d72080e7          	jalr	-654(ra) # 8000418e <iunlockput>
  return ip;
    80006424:	b761                	j	800063ac <create+0x72>
    panic("create: ialloc");
    80006426:	00003517          	auipc	a0,0x3
    8000642a:	61250513          	addi	a0,a0,1554 # 80009a38 <syscalls+0x328>
    8000642e:	ffffa097          	auipc	ra,0xffffa
    80006432:	0fc080e7          	jalr	252(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80006436:	04a95783          	lhu	a5,74(s2)
    8000643a:	2785                	addiw	a5,a5,1
    8000643c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006440:	854a                	mv	a0,s2
    80006442:	ffffe097          	auipc	ra,0xffffe
    80006446:	a20080e7          	jalr	-1504(ra) # 80003e62 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000644a:	40d0                	lw	a2,4(s1)
    8000644c:	00003597          	auipc	a1,0x3
    80006450:	4b458593          	addi	a1,a1,1204 # 80009900 <syscalls+0x1f0>
    80006454:	8526                	mv	a0,s1
    80006456:	ffffe097          	auipc	ra,0xffffe
    8000645a:	1ca080e7          	jalr	458(ra) # 80004620 <dirlink>
    8000645e:	00054f63          	bltz	a0,8000647c <create+0x142>
    80006462:	00492603          	lw	a2,4(s2)
    80006466:	00003597          	auipc	a1,0x3
    8000646a:	4a258593          	addi	a1,a1,1186 # 80009908 <syscalls+0x1f8>
    8000646e:	8526                	mv	a0,s1
    80006470:	ffffe097          	auipc	ra,0xffffe
    80006474:	1b0080e7          	jalr	432(ra) # 80004620 <dirlink>
    80006478:	f80557e3          	bgez	a0,80006406 <create+0xcc>
      panic("create dots");
    8000647c:	00003517          	auipc	a0,0x3
    80006480:	5cc50513          	addi	a0,a0,1484 # 80009a48 <syscalls+0x338>
    80006484:	ffffa097          	auipc	ra,0xffffa
    80006488:	0a6080e7          	jalr	166(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000648c:	00003517          	auipc	a0,0x3
    80006490:	5cc50513          	addi	a0,a0,1484 # 80009a58 <syscalls+0x348>
    80006494:	ffffa097          	auipc	ra,0xffffa
    80006498:	096080e7          	jalr	150(ra) # 8000052a <panic>
    return 0;
    8000649c:	84aa                	mv	s1,a0
    8000649e:	b739                	j	800063ac <create+0x72>

00000000800064a0 <sys_open>:

uint64
sys_open(void)
{
    800064a0:	7131                	addi	sp,sp,-192
    800064a2:	fd06                	sd	ra,184(sp)
    800064a4:	f922                	sd	s0,176(sp)
    800064a6:	f526                	sd	s1,168(sp)
    800064a8:	f14a                	sd	s2,160(sp)
    800064aa:	ed4e                	sd	s3,152(sp)
    800064ac:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800064ae:	08000613          	li	a2,128
    800064b2:	f5040593          	addi	a1,s0,-176
    800064b6:	4501                	li	a0,0
    800064b8:	ffffd097          	auipc	ra,0xffffd
    800064bc:	f46080e7          	jalr	-186(ra) # 800033fe <argstr>
    return -1;
    800064c0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800064c2:	0c054163          	bltz	a0,80006584 <sys_open+0xe4>
    800064c6:	f4c40593          	addi	a1,s0,-180
    800064ca:	4505                	li	a0,1
    800064cc:	ffffd097          	auipc	ra,0xffffd
    800064d0:	eee080e7          	jalr	-274(ra) # 800033ba <argint>
    800064d4:	0a054863          	bltz	a0,80006584 <sys_open+0xe4>

  begin_op();
    800064d8:	ffffe097          	auipc	ra,0xffffe
    800064dc:	73c080e7          	jalr	1852(ra) # 80004c14 <begin_op>

  if(omode & O_CREATE){
    800064e0:	f4c42783          	lw	a5,-180(s0)
    800064e4:	2007f793          	andi	a5,a5,512
    800064e8:	cbdd                	beqz	a5,8000659e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800064ea:	4681                	li	a3,0
    800064ec:	4601                	li	a2,0
    800064ee:	4589                	li	a1,2
    800064f0:	f5040513          	addi	a0,s0,-176
    800064f4:	00000097          	auipc	ra,0x0
    800064f8:	e46080e7          	jalr	-442(ra) # 8000633a <create>
    800064fc:	892a                	mv	s2,a0
    if(ip == 0){
    800064fe:	c959                	beqz	a0,80006594 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006500:	04491703          	lh	a4,68(s2)
    80006504:	478d                	li	a5,3
    80006506:	00f71763          	bne	a4,a5,80006514 <sys_open+0x74>
    8000650a:	04695703          	lhu	a4,70(s2)
    8000650e:	47a5                	li	a5,9
    80006510:	0ce7ec63          	bltu	a5,a4,800065e8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006514:	fffff097          	auipc	ra,0xfffff
    80006518:	b10080e7          	jalr	-1264(ra) # 80005024 <filealloc>
    8000651c:	89aa                	mv	s3,a0
    8000651e:	10050263          	beqz	a0,80006622 <sys_open+0x182>
    80006522:	00000097          	auipc	ra,0x0
    80006526:	8e2080e7          	jalr	-1822(ra) # 80005e04 <fdalloc>
    8000652a:	84aa                	mv	s1,a0
    8000652c:	0e054663          	bltz	a0,80006618 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006530:	04491703          	lh	a4,68(s2)
    80006534:	478d                	li	a5,3
    80006536:	0cf70463          	beq	a4,a5,800065fe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000653a:	4789                	li	a5,2
    8000653c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006540:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006544:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006548:	f4c42783          	lw	a5,-180(s0)
    8000654c:	0017c713          	xori	a4,a5,1
    80006550:	8b05                	andi	a4,a4,1
    80006552:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006556:	0037f713          	andi	a4,a5,3
    8000655a:	00e03733          	snez	a4,a4
    8000655e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006562:	4007f793          	andi	a5,a5,1024
    80006566:	c791                	beqz	a5,80006572 <sys_open+0xd2>
    80006568:	04491703          	lh	a4,68(s2)
    8000656c:	4789                	li	a5,2
    8000656e:	08f70f63          	beq	a4,a5,8000660c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006572:	854a                	mv	a0,s2
    80006574:	ffffe097          	auipc	ra,0xffffe
    80006578:	a7a080e7          	jalr	-1414(ra) # 80003fee <iunlock>
  end_op();
    8000657c:	ffffe097          	auipc	ra,0xffffe
    80006580:	718080e7          	jalr	1816(ra) # 80004c94 <end_op>

  return fd;
}
    80006584:	8526                	mv	a0,s1
    80006586:	70ea                	ld	ra,184(sp)
    80006588:	744a                	ld	s0,176(sp)
    8000658a:	74aa                	ld	s1,168(sp)
    8000658c:	790a                	ld	s2,160(sp)
    8000658e:	69ea                	ld	s3,152(sp)
    80006590:	6129                	addi	sp,sp,192
    80006592:	8082                	ret
      end_op();
    80006594:	ffffe097          	auipc	ra,0xffffe
    80006598:	700080e7          	jalr	1792(ra) # 80004c94 <end_op>
      return -1;
    8000659c:	b7e5                	j	80006584 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000659e:	f5040513          	addi	a0,s0,-176
    800065a2:	ffffe097          	auipc	ra,0xffffe
    800065a6:	140080e7          	jalr	320(ra) # 800046e2 <namei>
    800065aa:	892a                	mv	s2,a0
    800065ac:	c905                	beqz	a0,800065dc <sys_open+0x13c>
    ilock(ip);
    800065ae:	ffffe097          	auipc	ra,0xffffe
    800065b2:	97e080e7          	jalr	-1666(ra) # 80003f2c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800065b6:	04491703          	lh	a4,68(s2)
    800065ba:	4785                	li	a5,1
    800065bc:	f4f712e3          	bne	a4,a5,80006500 <sys_open+0x60>
    800065c0:	f4c42783          	lw	a5,-180(s0)
    800065c4:	dba1                	beqz	a5,80006514 <sys_open+0x74>
      iunlockput(ip);
    800065c6:	854a                	mv	a0,s2
    800065c8:	ffffe097          	auipc	ra,0xffffe
    800065cc:	bc6080e7          	jalr	-1082(ra) # 8000418e <iunlockput>
      end_op();
    800065d0:	ffffe097          	auipc	ra,0xffffe
    800065d4:	6c4080e7          	jalr	1732(ra) # 80004c94 <end_op>
      return -1;
    800065d8:	54fd                	li	s1,-1
    800065da:	b76d                	j	80006584 <sys_open+0xe4>
      end_op();
    800065dc:	ffffe097          	auipc	ra,0xffffe
    800065e0:	6b8080e7          	jalr	1720(ra) # 80004c94 <end_op>
      return -1;
    800065e4:	54fd                	li	s1,-1
    800065e6:	bf79                	j	80006584 <sys_open+0xe4>
    iunlockput(ip);
    800065e8:	854a                	mv	a0,s2
    800065ea:	ffffe097          	auipc	ra,0xffffe
    800065ee:	ba4080e7          	jalr	-1116(ra) # 8000418e <iunlockput>
    end_op();
    800065f2:	ffffe097          	auipc	ra,0xffffe
    800065f6:	6a2080e7          	jalr	1698(ra) # 80004c94 <end_op>
    return -1;
    800065fa:	54fd                	li	s1,-1
    800065fc:	b761                	j	80006584 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800065fe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006602:	04691783          	lh	a5,70(s2)
    80006606:	02f99223          	sh	a5,36(s3)
    8000660a:	bf2d                	j	80006544 <sys_open+0xa4>
    itrunc(ip);
    8000660c:	854a                	mv	a0,s2
    8000660e:	ffffe097          	auipc	ra,0xffffe
    80006612:	a2c080e7          	jalr	-1492(ra) # 8000403a <itrunc>
    80006616:	bfb1                	j	80006572 <sys_open+0xd2>
      fileclose(f);
    80006618:	854e                	mv	a0,s3
    8000661a:	fffff097          	auipc	ra,0xfffff
    8000661e:	ac6080e7          	jalr	-1338(ra) # 800050e0 <fileclose>
    iunlockput(ip);
    80006622:	854a                	mv	a0,s2
    80006624:	ffffe097          	auipc	ra,0xffffe
    80006628:	b6a080e7          	jalr	-1174(ra) # 8000418e <iunlockput>
    end_op();
    8000662c:	ffffe097          	auipc	ra,0xffffe
    80006630:	668080e7          	jalr	1640(ra) # 80004c94 <end_op>
    return -1;
    80006634:	54fd                	li	s1,-1
    80006636:	b7b9                	j	80006584 <sys_open+0xe4>

0000000080006638 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006638:	7175                	addi	sp,sp,-144
    8000663a:	e506                	sd	ra,136(sp)
    8000663c:	e122                	sd	s0,128(sp)
    8000663e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006640:	ffffe097          	auipc	ra,0xffffe
    80006644:	5d4080e7          	jalr	1492(ra) # 80004c14 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006648:	08000613          	li	a2,128
    8000664c:	f7040593          	addi	a1,s0,-144
    80006650:	4501                	li	a0,0
    80006652:	ffffd097          	auipc	ra,0xffffd
    80006656:	dac080e7          	jalr	-596(ra) # 800033fe <argstr>
    8000665a:	02054963          	bltz	a0,8000668c <sys_mkdir+0x54>
    8000665e:	4681                	li	a3,0
    80006660:	4601                	li	a2,0
    80006662:	4585                	li	a1,1
    80006664:	f7040513          	addi	a0,s0,-144
    80006668:	00000097          	auipc	ra,0x0
    8000666c:	cd2080e7          	jalr	-814(ra) # 8000633a <create>
    80006670:	cd11                	beqz	a0,8000668c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006672:	ffffe097          	auipc	ra,0xffffe
    80006676:	b1c080e7          	jalr	-1252(ra) # 8000418e <iunlockput>
  end_op();
    8000667a:	ffffe097          	auipc	ra,0xffffe
    8000667e:	61a080e7          	jalr	1562(ra) # 80004c94 <end_op>
  return 0;
    80006682:	4501                	li	a0,0
}
    80006684:	60aa                	ld	ra,136(sp)
    80006686:	640a                	ld	s0,128(sp)
    80006688:	6149                	addi	sp,sp,144
    8000668a:	8082                	ret
    end_op();
    8000668c:	ffffe097          	auipc	ra,0xffffe
    80006690:	608080e7          	jalr	1544(ra) # 80004c94 <end_op>
    return -1;
    80006694:	557d                	li	a0,-1
    80006696:	b7fd                	j	80006684 <sys_mkdir+0x4c>

0000000080006698 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006698:	7135                	addi	sp,sp,-160
    8000669a:	ed06                	sd	ra,152(sp)
    8000669c:	e922                	sd	s0,144(sp)
    8000669e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800066a0:	ffffe097          	auipc	ra,0xffffe
    800066a4:	574080e7          	jalr	1396(ra) # 80004c14 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800066a8:	08000613          	li	a2,128
    800066ac:	f7040593          	addi	a1,s0,-144
    800066b0:	4501                	li	a0,0
    800066b2:	ffffd097          	auipc	ra,0xffffd
    800066b6:	d4c080e7          	jalr	-692(ra) # 800033fe <argstr>
    800066ba:	04054a63          	bltz	a0,8000670e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800066be:	f6c40593          	addi	a1,s0,-148
    800066c2:	4505                	li	a0,1
    800066c4:	ffffd097          	auipc	ra,0xffffd
    800066c8:	cf6080e7          	jalr	-778(ra) # 800033ba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800066cc:	04054163          	bltz	a0,8000670e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800066d0:	f6840593          	addi	a1,s0,-152
    800066d4:	4509                	li	a0,2
    800066d6:	ffffd097          	auipc	ra,0xffffd
    800066da:	ce4080e7          	jalr	-796(ra) # 800033ba <argint>
     argint(1, &major) < 0 ||
    800066de:	02054863          	bltz	a0,8000670e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800066e2:	f6841683          	lh	a3,-152(s0)
    800066e6:	f6c41603          	lh	a2,-148(s0)
    800066ea:	458d                	li	a1,3
    800066ec:	f7040513          	addi	a0,s0,-144
    800066f0:	00000097          	auipc	ra,0x0
    800066f4:	c4a080e7          	jalr	-950(ra) # 8000633a <create>
     argint(2, &minor) < 0 ||
    800066f8:	c919                	beqz	a0,8000670e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066fa:	ffffe097          	auipc	ra,0xffffe
    800066fe:	a94080e7          	jalr	-1388(ra) # 8000418e <iunlockput>
  end_op();
    80006702:	ffffe097          	auipc	ra,0xffffe
    80006706:	592080e7          	jalr	1426(ra) # 80004c94 <end_op>
  return 0;
    8000670a:	4501                	li	a0,0
    8000670c:	a031                	j	80006718 <sys_mknod+0x80>
    end_op();
    8000670e:	ffffe097          	auipc	ra,0xffffe
    80006712:	586080e7          	jalr	1414(ra) # 80004c94 <end_op>
    return -1;
    80006716:	557d                	li	a0,-1
}
    80006718:	60ea                	ld	ra,152(sp)
    8000671a:	644a                	ld	s0,144(sp)
    8000671c:	610d                	addi	sp,sp,160
    8000671e:	8082                	ret

0000000080006720 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006720:	7135                	addi	sp,sp,-160
    80006722:	ed06                	sd	ra,152(sp)
    80006724:	e922                	sd	s0,144(sp)
    80006726:	e526                	sd	s1,136(sp)
    80006728:	e14a                	sd	s2,128(sp)
    8000672a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000672c:	ffffb097          	auipc	ra,0xffffb
    80006730:	2ba080e7          	jalr	698(ra) # 800019e6 <myproc>
    80006734:	892a                	mv	s2,a0
  
  begin_op();
    80006736:	ffffe097          	auipc	ra,0xffffe
    8000673a:	4de080e7          	jalr	1246(ra) # 80004c14 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000673e:	08000613          	li	a2,128
    80006742:	f6040593          	addi	a1,s0,-160
    80006746:	4501                	li	a0,0
    80006748:	ffffd097          	auipc	ra,0xffffd
    8000674c:	cb6080e7          	jalr	-842(ra) # 800033fe <argstr>
    80006750:	04054b63          	bltz	a0,800067a6 <sys_chdir+0x86>
    80006754:	f6040513          	addi	a0,s0,-160
    80006758:	ffffe097          	auipc	ra,0xffffe
    8000675c:	f8a080e7          	jalr	-118(ra) # 800046e2 <namei>
    80006760:	84aa                	mv	s1,a0
    80006762:	c131                	beqz	a0,800067a6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006764:	ffffd097          	auipc	ra,0xffffd
    80006768:	7c8080e7          	jalr	1992(ra) # 80003f2c <ilock>
  if(ip->type != T_DIR){
    8000676c:	04449703          	lh	a4,68(s1)
    80006770:	4785                	li	a5,1
    80006772:	04f71063          	bne	a4,a5,800067b2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006776:	8526                	mv	a0,s1
    80006778:	ffffe097          	auipc	ra,0xffffe
    8000677c:	876080e7          	jalr	-1930(ra) # 80003fee <iunlock>
  iput(p->cwd);
    80006780:	15093503          	ld	a0,336(s2)
    80006784:	ffffe097          	auipc	ra,0xffffe
    80006788:	962080e7          	jalr	-1694(ra) # 800040e6 <iput>
  end_op();
    8000678c:	ffffe097          	auipc	ra,0xffffe
    80006790:	508080e7          	jalr	1288(ra) # 80004c94 <end_op>
  p->cwd = ip;
    80006794:	14993823          	sd	s1,336(s2)
  return 0;
    80006798:	4501                	li	a0,0
}
    8000679a:	60ea                	ld	ra,152(sp)
    8000679c:	644a                	ld	s0,144(sp)
    8000679e:	64aa                	ld	s1,136(sp)
    800067a0:	690a                	ld	s2,128(sp)
    800067a2:	610d                	addi	sp,sp,160
    800067a4:	8082                	ret
    end_op();
    800067a6:	ffffe097          	auipc	ra,0xffffe
    800067aa:	4ee080e7          	jalr	1262(ra) # 80004c94 <end_op>
    return -1;
    800067ae:	557d                	li	a0,-1
    800067b0:	b7ed                	j	8000679a <sys_chdir+0x7a>
    iunlockput(ip);
    800067b2:	8526                	mv	a0,s1
    800067b4:	ffffe097          	auipc	ra,0xffffe
    800067b8:	9da080e7          	jalr	-1574(ra) # 8000418e <iunlockput>
    end_op();
    800067bc:	ffffe097          	auipc	ra,0xffffe
    800067c0:	4d8080e7          	jalr	1240(ra) # 80004c94 <end_op>
    return -1;
    800067c4:	557d                	li	a0,-1
    800067c6:	bfd1                	j	8000679a <sys_chdir+0x7a>

00000000800067c8 <sys_exec>:

uint64
sys_exec(void)
{
    800067c8:	7145                	addi	sp,sp,-464
    800067ca:	e786                	sd	ra,456(sp)
    800067cc:	e3a2                	sd	s0,448(sp)
    800067ce:	ff26                	sd	s1,440(sp)
    800067d0:	fb4a                	sd	s2,432(sp)
    800067d2:	f74e                	sd	s3,424(sp)
    800067d4:	f352                	sd	s4,416(sp)
    800067d6:	ef56                	sd	s5,408(sp)
    800067d8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067da:	08000613          	li	a2,128
    800067de:	f4040593          	addi	a1,s0,-192
    800067e2:	4501                	li	a0,0
    800067e4:	ffffd097          	auipc	ra,0xffffd
    800067e8:	c1a080e7          	jalr	-998(ra) # 800033fe <argstr>
    return -1;
    800067ec:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067ee:	0c054a63          	bltz	a0,800068c2 <sys_exec+0xfa>
    800067f2:	e3840593          	addi	a1,s0,-456
    800067f6:	4505                	li	a0,1
    800067f8:	ffffd097          	auipc	ra,0xffffd
    800067fc:	be4080e7          	jalr	-1052(ra) # 800033dc <argaddr>
    80006800:	0c054163          	bltz	a0,800068c2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006804:	10000613          	li	a2,256
    80006808:	4581                	li	a1,0
    8000680a:	e4040513          	addi	a0,s0,-448
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	4c2080e7          	jalr	1218(ra) # 80000cd0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006816:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000681a:	89a6                	mv	s3,s1
    8000681c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000681e:	02000a13          	li	s4,32
    80006822:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006826:	00391793          	slli	a5,s2,0x3
    8000682a:	e3040593          	addi	a1,s0,-464
    8000682e:	e3843503          	ld	a0,-456(s0)
    80006832:	953e                	add	a0,a0,a5
    80006834:	ffffd097          	auipc	ra,0xffffd
    80006838:	aec080e7          	jalr	-1300(ra) # 80003320 <fetchaddr>
    8000683c:	02054a63          	bltz	a0,80006870 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006840:	e3043783          	ld	a5,-464(s0)
    80006844:	c3b9                	beqz	a5,8000688a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	28c080e7          	jalr	652(ra) # 80000ad2 <kalloc>
    8000684e:	85aa                	mv	a1,a0
    80006850:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006854:	cd11                	beqz	a0,80006870 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006856:	6605                	lui	a2,0x1
    80006858:	e3043503          	ld	a0,-464(s0)
    8000685c:	ffffd097          	auipc	ra,0xffffd
    80006860:	b16080e7          	jalr	-1258(ra) # 80003372 <fetchstr>
    80006864:	00054663          	bltz	a0,80006870 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006868:	0905                	addi	s2,s2,1
    8000686a:	09a1                	addi	s3,s3,8
    8000686c:	fb491be3          	bne	s2,s4,80006822 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006870:	10048913          	addi	s2,s1,256
    80006874:	6088                	ld	a0,0(s1)
    80006876:	c529                	beqz	a0,800068c0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006878:	ffffa097          	auipc	ra,0xffffa
    8000687c:	15e080e7          	jalr	350(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006880:	04a1                	addi	s1,s1,8
    80006882:	ff2499e3          	bne	s1,s2,80006874 <sys_exec+0xac>
  return -1;
    80006886:	597d                	li	s2,-1
    80006888:	a82d                	j	800068c2 <sys_exec+0xfa>
      argv[i] = 0;
    8000688a:	0a8e                	slli	s5,s5,0x3
    8000688c:	fc040793          	addi	a5,s0,-64
    80006890:	9abe                	add	s5,s5,a5
    80006892:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006896:	e4040593          	addi	a1,s0,-448
    8000689a:	f4040513          	addi	a0,s0,-192
    8000689e:	fffff097          	auipc	ra,0xfffff
    800068a2:	08a080e7          	jalr	138(ra) # 80005928 <exec>
    800068a6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068a8:	10048993          	addi	s3,s1,256
    800068ac:	6088                	ld	a0,0(s1)
    800068ae:	c911                	beqz	a0,800068c2 <sys_exec+0xfa>
    kfree(argv[i]);
    800068b0:	ffffa097          	auipc	ra,0xffffa
    800068b4:	126080e7          	jalr	294(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068b8:	04a1                	addi	s1,s1,8
    800068ba:	ff3499e3          	bne	s1,s3,800068ac <sys_exec+0xe4>
    800068be:	a011                	j	800068c2 <sys_exec+0xfa>
  return -1;
    800068c0:	597d                	li	s2,-1
}
    800068c2:	854a                	mv	a0,s2
    800068c4:	60be                	ld	ra,456(sp)
    800068c6:	641e                	ld	s0,448(sp)
    800068c8:	74fa                	ld	s1,440(sp)
    800068ca:	795a                	ld	s2,432(sp)
    800068cc:	79ba                	ld	s3,424(sp)
    800068ce:	7a1a                	ld	s4,416(sp)
    800068d0:	6afa                	ld	s5,408(sp)
    800068d2:	6179                	addi	sp,sp,464
    800068d4:	8082                	ret

00000000800068d6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800068d6:	7139                	addi	sp,sp,-64
    800068d8:	fc06                	sd	ra,56(sp)
    800068da:	f822                	sd	s0,48(sp)
    800068dc:	f426                	sd	s1,40(sp)
    800068de:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800068e0:	ffffb097          	auipc	ra,0xffffb
    800068e4:	106080e7          	jalr	262(ra) # 800019e6 <myproc>
    800068e8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800068ea:	fd840593          	addi	a1,s0,-40
    800068ee:	4501                	li	a0,0
    800068f0:	ffffd097          	auipc	ra,0xffffd
    800068f4:	aec080e7          	jalr	-1300(ra) # 800033dc <argaddr>
    return -1;
    800068f8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800068fa:	0e054063          	bltz	a0,800069da <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800068fe:	fc840593          	addi	a1,s0,-56
    80006902:	fd040513          	addi	a0,s0,-48
    80006906:	fffff097          	auipc	ra,0xfffff
    8000690a:	d00080e7          	jalr	-768(ra) # 80005606 <pipealloc>
    return -1;
    8000690e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006910:	0c054563          	bltz	a0,800069da <sys_pipe+0x104>
  fd0 = -1;
    80006914:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006918:	fd043503          	ld	a0,-48(s0)
    8000691c:	fffff097          	auipc	ra,0xfffff
    80006920:	4e8080e7          	jalr	1256(ra) # 80005e04 <fdalloc>
    80006924:	fca42223          	sw	a0,-60(s0)
    80006928:	08054c63          	bltz	a0,800069c0 <sys_pipe+0xea>
    8000692c:	fc843503          	ld	a0,-56(s0)
    80006930:	fffff097          	auipc	ra,0xfffff
    80006934:	4d4080e7          	jalr	1236(ra) # 80005e04 <fdalloc>
    80006938:	fca42023          	sw	a0,-64(s0)
    8000693c:	06054863          	bltz	a0,800069ac <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006940:	4691                	li	a3,4
    80006942:	fc440613          	addi	a2,s0,-60
    80006946:	fd843583          	ld	a1,-40(s0)
    8000694a:	68a8                	ld	a0,80(s1)
    8000694c:	ffffb097          	auipc	ra,0xffffb
    80006950:	d5a080e7          	jalr	-678(ra) # 800016a6 <copyout>
    80006954:	02054063          	bltz	a0,80006974 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006958:	4691                	li	a3,4
    8000695a:	fc040613          	addi	a2,s0,-64
    8000695e:	fd843583          	ld	a1,-40(s0)
    80006962:	0591                	addi	a1,a1,4
    80006964:	68a8                	ld	a0,80(s1)
    80006966:	ffffb097          	auipc	ra,0xffffb
    8000696a:	d40080e7          	jalr	-704(ra) # 800016a6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000696e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006970:	06055563          	bgez	a0,800069da <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006974:	fc442783          	lw	a5,-60(s0)
    80006978:	07e9                	addi	a5,a5,26
    8000697a:	078e                	slli	a5,a5,0x3
    8000697c:	97a6                	add	a5,a5,s1
    8000697e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006982:	fc042503          	lw	a0,-64(s0)
    80006986:	0569                	addi	a0,a0,26
    80006988:	050e                	slli	a0,a0,0x3
    8000698a:	9526                	add	a0,a0,s1
    8000698c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006990:	fd043503          	ld	a0,-48(s0)
    80006994:	ffffe097          	auipc	ra,0xffffe
    80006998:	74c080e7          	jalr	1868(ra) # 800050e0 <fileclose>
    fileclose(wf);
    8000699c:	fc843503          	ld	a0,-56(s0)
    800069a0:	ffffe097          	auipc	ra,0xffffe
    800069a4:	740080e7          	jalr	1856(ra) # 800050e0 <fileclose>
    return -1;
    800069a8:	57fd                	li	a5,-1
    800069aa:	a805                	j	800069da <sys_pipe+0x104>
    if(fd0 >= 0)
    800069ac:	fc442783          	lw	a5,-60(s0)
    800069b0:	0007c863          	bltz	a5,800069c0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800069b4:	01a78513          	addi	a0,a5,26
    800069b8:	050e                	slli	a0,a0,0x3
    800069ba:	9526                	add	a0,a0,s1
    800069bc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800069c0:	fd043503          	ld	a0,-48(s0)
    800069c4:	ffffe097          	auipc	ra,0xffffe
    800069c8:	71c080e7          	jalr	1820(ra) # 800050e0 <fileclose>
    fileclose(wf);
    800069cc:	fc843503          	ld	a0,-56(s0)
    800069d0:	ffffe097          	auipc	ra,0xffffe
    800069d4:	710080e7          	jalr	1808(ra) # 800050e0 <fileclose>
    return -1;
    800069d8:	57fd                	li	a5,-1
}
    800069da:	853e                	mv	a0,a5
    800069dc:	70e2                	ld	ra,56(sp)
    800069de:	7442                	ld	s0,48(sp)
    800069e0:	74a2                	ld	s1,40(sp)
    800069e2:	6121                	addi	sp,sp,64
    800069e4:	8082                	ret
	...

00000000800069f0 <kernelvec>:
    800069f0:	7111                	addi	sp,sp,-256
    800069f2:	e006                	sd	ra,0(sp)
    800069f4:	e40a                	sd	sp,8(sp)
    800069f6:	e80e                	sd	gp,16(sp)
    800069f8:	ec12                	sd	tp,24(sp)
    800069fa:	f016                	sd	t0,32(sp)
    800069fc:	f41a                	sd	t1,40(sp)
    800069fe:	f81e                	sd	t2,48(sp)
    80006a00:	fc22                	sd	s0,56(sp)
    80006a02:	e0a6                	sd	s1,64(sp)
    80006a04:	e4aa                	sd	a0,72(sp)
    80006a06:	e8ae                	sd	a1,80(sp)
    80006a08:	ecb2                	sd	a2,88(sp)
    80006a0a:	f0b6                	sd	a3,96(sp)
    80006a0c:	f4ba                	sd	a4,104(sp)
    80006a0e:	f8be                	sd	a5,112(sp)
    80006a10:	fcc2                	sd	a6,120(sp)
    80006a12:	e146                	sd	a7,128(sp)
    80006a14:	e54a                	sd	s2,136(sp)
    80006a16:	e94e                	sd	s3,144(sp)
    80006a18:	ed52                	sd	s4,152(sp)
    80006a1a:	f156                	sd	s5,160(sp)
    80006a1c:	f55a                	sd	s6,168(sp)
    80006a1e:	f95e                	sd	s7,176(sp)
    80006a20:	fd62                	sd	s8,184(sp)
    80006a22:	e1e6                	sd	s9,192(sp)
    80006a24:	e5ea                	sd	s10,200(sp)
    80006a26:	e9ee                	sd	s11,208(sp)
    80006a28:	edf2                	sd	t3,216(sp)
    80006a2a:	f1f6                	sd	t4,224(sp)
    80006a2c:	f5fa                	sd	t5,232(sp)
    80006a2e:	f9fe                	sd	t6,240(sp)
    80006a30:	fbcfc0ef          	jal	ra,800031ec <kerneltrap>
    80006a34:	6082                	ld	ra,0(sp)
    80006a36:	6122                	ld	sp,8(sp)
    80006a38:	61c2                	ld	gp,16(sp)
    80006a3a:	7282                	ld	t0,32(sp)
    80006a3c:	7322                	ld	t1,40(sp)
    80006a3e:	73c2                	ld	t2,48(sp)
    80006a40:	7462                	ld	s0,56(sp)
    80006a42:	6486                	ld	s1,64(sp)
    80006a44:	6526                	ld	a0,72(sp)
    80006a46:	65c6                	ld	a1,80(sp)
    80006a48:	6666                	ld	a2,88(sp)
    80006a4a:	7686                	ld	a3,96(sp)
    80006a4c:	7726                	ld	a4,104(sp)
    80006a4e:	77c6                	ld	a5,112(sp)
    80006a50:	7866                	ld	a6,120(sp)
    80006a52:	688a                	ld	a7,128(sp)
    80006a54:	692a                	ld	s2,136(sp)
    80006a56:	69ca                	ld	s3,144(sp)
    80006a58:	6a6a                	ld	s4,152(sp)
    80006a5a:	7a8a                	ld	s5,160(sp)
    80006a5c:	7b2a                	ld	s6,168(sp)
    80006a5e:	7bca                	ld	s7,176(sp)
    80006a60:	7c6a                	ld	s8,184(sp)
    80006a62:	6c8e                	ld	s9,192(sp)
    80006a64:	6d2e                	ld	s10,200(sp)
    80006a66:	6dce                	ld	s11,208(sp)
    80006a68:	6e6e                	ld	t3,216(sp)
    80006a6a:	7e8e                	ld	t4,224(sp)
    80006a6c:	7f2e                	ld	t5,232(sp)
    80006a6e:	7fce                	ld	t6,240(sp)
    80006a70:	6111                	addi	sp,sp,256
    80006a72:	10200073          	sret
    80006a76:	00000013          	nop
    80006a7a:	00000013          	nop
    80006a7e:	0001                	nop

0000000080006a80 <timervec>:
    80006a80:	34051573          	csrrw	a0,mscratch,a0
    80006a84:	e10c                	sd	a1,0(a0)
    80006a86:	e510                	sd	a2,8(a0)
    80006a88:	e914                	sd	a3,16(a0)
    80006a8a:	6d0c                	ld	a1,24(a0)
    80006a8c:	7110                	ld	a2,32(a0)
    80006a8e:	6194                	ld	a3,0(a1)
    80006a90:	96b2                	add	a3,a3,a2
    80006a92:	e194                	sd	a3,0(a1)
    80006a94:	4589                	li	a1,2
    80006a96:	14459073          	csrw	sip,a1
    80006a9a:	6914                	ld	a3,16(a0)
    80006a9c:	6510                	ld	a2,8(a0)
    80006a9e:	610c                	ld	a1,0(a0)
    80006aa0:	34051573          	csrrw	a0,mscratch,a0
    80006aa4:	30200073          	mret
	...

0000000080006aaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006aaa:	1141                	addi	sp,sp,-16
    80006aac:	e422                	sd	s0,8(sp)
    80006aae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006ab0:	0c0007b7          	lui	a5,0xc000
    80006ab4:	4705                	li	a4,1
    80006ab6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006ab8:	c3d8                	sw	a4,4(a5)
}
    80006aba:	6422                	ld	s0,8(sp)
    80006abc:	0141                	addi	sp,sp,16
    80006abe:	8082                	ret

0000000080006ac0 <plicinithart>:

void
plicinithart(void)
{
    80006ac0:	1141                	addi	sp,sp,-16
    80006ac2:	e406                	sd	ra,8(sp)
    80006ac4:	e022                	sd	s0,0(sp)
    80006ac6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006ac8:	ffffb097          	auipc	ra,0xffffb
    80006acc:	ef2080e7          	jalr	-270(ra) # 800019ba <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006ad0:	0085171b          	slliw	a4,a0,0x8
    80006ad4:	0c0027b7          	lui	a5,0xc002
    80006ad8:	97ba                	add	a5,a5,a4
    80006ada:	40200713          	li	a4,1026
    80006ade:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006ae2:	00d5151b          	slliw	a0,a0,0xd
    80006ae6:	0c2017b7          	lui	a5,0xc201
    80006aea:	953e                	add	a0,a0,a5
    80006aec:	00052023          	sw	zero,0(a0)
}
    80006af0:	60a2                	ld	ra,8(sp)
    80006af2:	6402                	ld	s0,0(sp)
    80006af4:	0141                	addi	sp,sp,16
    80006af6:	8082                	ret

0000000080006af8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006af8:	1141                	addi	sp,sp,-16
    80006afa:	e406                	sd	ra,8(sp)
    80006afc:	e022                	sd	s0,0(sp)
    80006afe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b00:	ffffb097          	auipc	ra,0xffffb
    80006b04:	eba080e7          	jalr	-326(ra) # 800019ba <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006b08:	00d5179b          	slliw	a5,a0,0xd
    80006b0c:	0c201537          	lui	a0,0xc201
    80006b10:	953e                	add	a0,a0,a5
  return irq;
}
    80006b12:	4148                	lw	a0,4(a0)
    80006b14:	60a2                	ld	ra,8(sp)
    80006b16:	6402                	ld	s0,0(sp)
    80006b18:	0141                	addi	sp,sp,16
    80006b1a:	8082                	ret

0000000080006b1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006b1c:	1101                	addi	sp,sp,-32
    80006b1e:	ec06                	sd	ra,24(sp)
    80006b20:	e822                	sd	s0,16(sp)
    80006b22:	e426                	sd	s1,8(sp)
    80006b24:	1000                	addi	s0,sp,32
    80006b26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006b28:	ffffb097          	auipc	ra,0xffffb
    80006b2c:	e92080e7          	jalr	-366(ra) # 800019ba <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006b30:	00d5151b          	slliw	a0,a0,0xd
    80006b34:	0c2017b7          	lui	a5,0xc201
    80006b38:	97aa                	add	a5,a5,a0
    80006b3a:	c3c4                	sw	s1,4(a5)
}
    80006b3c:	60e2                	ld	ra,24(sp)
    80006b3e:	6442                	ld	s0,16(sp)
    80006b40:	64a2                	ld	s1,8(sp)
    80006b42:	6105                	addi	sp,sp,32
    80006b44:	8082                	ret

0000000080006b46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006b46:	1141                	addi	sp,sp,-16
    80006b48:	e406                	sd	ra,8(sp)
    80006b4a:	e022                	sd	s0,0(sp)
    80006b4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006b4e:	479d                	li	a5,7
    80006b50:	06a7c963          	blt	a5,a0,80006bc2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006b54:	00025797          	auipc	a5,0x25
    80006b58:	4ac78793          	addi	a5,a5,1196 # 8002c000 <disk>
    80006b5c:	00a78733          	add	a4,a5,a0
    80006b60:	6789                	lui	a5,0x2
    80006b62:	97ba                	add	a5,a5,a4
    80006b64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006b68:	e7ad                	bnez	a5,80006bd2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006b6a:	00451793          	slli	a5,a0,0x4
    80006b6e:	00027717          	auipc	a4,0x27
    80006b72:	49270713          	addi	a4,a4,1170 # 8002e000 <disk+0x2000>
    80006b76:	6314                	ld	a3,0(a4)
    80006b78:	96be                	add	a3,a3,a5
    80006b7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006b7e:	6314                	ld	a3,0(a4)
    80006b80:	96be                	add	a3,a3,a5
    80006b82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006b86:	6314                	ld	a3,0(a4)
    80006b88:	96be                	add	a3,a3,a5
    80006b8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006b8e:	6318                	ld	a4,0(a4)
    80006b90:	97ba                	add	a5,a5,a4
    80006b92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006b96:	00025797          	auipc	a5,0x25
    80006b9a:	46a78793          	addi	a5,a5,1130 # 8002c000 <disk>
    80006b9e:	97aa                	add	a5,a5,a0
    80006ba0:	6509                	lui	a0,0x2
    80006ba2:	953e                	add	a0,a0,a5
    80006ba4:	4785                	li	a5,1
    80006ba6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006baa:	00027517          	auipc	a0,0x27
    80006bae:	46e50513          	addi	a0,a0,1134 # 8002e018 <disk+0x2018>
    80006bb2:	ffffb097          	auipc	ra,0xffffb
    80006bb6:	3e6080e7          	jalr	998(ra) # 80001f98 <wakeup>
}
    80006bba:	60a2                	ld	ra,8(sp)
    80006bbc:	6402                	ld	s0,0(sp)
    80006bbe:	0141                	addi	sp,sp,16
    80006bc0:	8082                	ret
    panic("free_desc 1");
    80006bc2:	00003517          	auipc	a0,0x3
    80006bc6:	ea650513          	addi	a0,a0,-346 # 80009a68 <syscalls+0x358>
    80006bca:	ffffa097          	auipc	ra,0xffffa
    80006bce:	960080e7          	jalr	-1696(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006bd2:	00003517          	auipc	a0,0x3
    80006bd6:	ea650513          	addi	a0,a0,-346 # 80009a78 <syscalls+0x368>
    80006bda:	ffffa097          	auipc	ra,0xffffa
    80006bde:	950080e7          	jalr	-1712(ra) # 8000052a <panic>

0000000080006be2 <virtio_disk_init>:
{
    80006be2:	1101                	addi	sp,sp,-32
    80006be4:	ec06                	sd	ra,24(sp)
    80006be6:	e822                	sd	s0,16(sp)
    80006be8:	e426                	sd	s1,8(sp)
    80006bea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006bec:	00003597          	auipc	a1,0x3
    80006bf0:	e9c58593          	addi	a1,a1,-356 # 80009a88 <syscalls+0x378>
    80006bf4:	00027517          	auipc	a0,0x27
    80006bf8:	53450513          	addi	a0,a0,1332 # 8002e128 <disk+0x2128>
    80006bfc:	ffffa097          	auipc	ra,0xffffa
    80006c00:	f36080e7          	jalr	-202(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c04:	100017b7          	lui	a5,0x10001
    80006c08:	4398                	lw	a4,0(a5)
    80006c0a:	2701                	sext.w	a4,a4
    80006c0c:	747277b7          	lui	a5,0x74727
    80006c10:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006c14:	0ef71163          	bne	a4,a5,80006cf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c18:	100017b7          	lui	a5,0x10001
    80006c1c:	43dc                	lw	a5,4(a5)
    80006c1e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c20:	4705                	li	a4,1
    80006c22:	0ce79a63          	bne	a5,a4,80006cf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c26:	100017b7          	lui	a5,0x10001
    80006c2a:	479c                	lw	a5,8(a5)
    80006c2c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c2e:	4709                	li	a4,2
    80006c30:	0ce79363          	bne	a5,a4,80006cf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006c34:	100017b7          	lui	a5,0x10001
    80006c38:	47d8                	lw	a4,12(a5)
    80006c3a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c3c:	554d47b7          	lui	a5,0x554d4
    80006c40:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006c44:	0af71963          	bne	a4,a5,80006cf6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c48:	100017b7          	lui	a5,0x10001
    80006c4c:	4705                	li	a4,1
    80006c4e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c50:	470d                	li	a4,3
    80006c52:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006c54:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006c56:	c7ffe737          	lui	a4,0xc7ffe
    80006c5a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf75f>
    80006c5e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006c60:	2701                	sext.w	a4,a4
    80006c62:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c64:	472d                	li	a4,11
    80006c66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c68:	473d                	li	a4,15
    80006c6a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006c6c:	6705                	lui	a4,0x1
    80006c6e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006c70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006c74:	5bdc                	lw	a5,52(a5)
    80006c76:	2781                	sext.w	a5,a5
  if(max == 0)
    80006c78:	c7d9                	beqz	a5,80006d06 <virtio_disk_init+0x124>
  if(max < NUM)
    80006c7a:	471d                	li	a4,7
    80006c7c:	08f77d63          	bgeu	a4,a5,80006d16 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006c80:	100014b7          	lui	s1,0x10001
    80006c84:	47a1                	li	a5,8
    80006c86:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006c88:	6609                	lui	a2,0x2
    80006c8a:	4581                	li	a1,0
    80006c8c:	00025517          	auipc	a0,0x25
    80006c90:	37450513          	addi	a0,a0,884 # 8002c000 <disk>
    80006c94:	ffffa097          	auipc	ra,0xffffa
    80006c98:	03c080e7          	jalr	60(ra) # 80000cd0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006c9c:	00025717          	auipc	a4,0x25
    80006ca0:	36470713          	addi	a4,a4,868 # 8002c000 <disk>
    80006ca4:	00c75793          	srli	a5,a4,0xc
    80006ca8:	2781                	sext.w	a5,a5
    80006caa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006cac:	00027797          	auipc	a5,0x27
    80006cb0:	35478793          	addi	a5,a5,852 # 8002e000 <disk+0x2000>
    80006cb4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006cb6:	00025717          	auipc	a4,0x25
    80006cba:	3ca70713          	addi	a4,a4,970 # 8002c080 <disk+0x80>
    80006cbe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006cc0:	00026717          	auipc	a4,0x26
    80006cc4:	34070713          	addi	a4,a4,832 # 8002d000 <disk+0x1000>
    80006cc8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006cca:	4705                	li	a4,1
    80006ccc:	00e78c23          	sb	a4,24(a5)
    80006cd0:	00e78ca3          	sb	a4,25(a5)
    80006cd4:	00e78d23          	sb	a4,26(a5)
    80006cd8:	00e78da3          	sb	a4,27(a5)
    80006cdc:	00e78e23          	sb	a4,28(a5)
    80006ce0:	00e78ea3          	sb	a4,29(a5)
    80006ce4:	00e78f23          	sb	a4,30(a5)
    80006ce8:	00e78fa3          	sb	a4,31(a5)
}
    80006cec:	60e2                	ld	ra,24(sp)
    80006cee:	6442                	ld	s0,16(sp)
    80006cf0:	64a2                	ld	s1,8(sp)
    80006cf2:	6105                	addi	sp,sp,32
    80006cf4:	8082                	ret
    panic("could not find virtio disk");
    80006cf6:	00003517          	auipc	a0,0x3
    80006cfa:	da250513          	addi	a0,a0,-606 # 80009a98 <syscalls+0x388>
    80006cfe:	ffffa097          	auipc	ra,0xffffa
    80006d02:	82c080e7          	jalr	-2004(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006d06:	00003517          	auipc	a0,0x3
    80006d0a:	db250513          	addi	a0,a0,-590 # 80009ab8 <syscalls+0x3a8>
    80006d0e:	ffffa097          	auipc	ra,0xffffa
    80006d12:	81c080e7          	jalr	-2020(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006d16:	00003517          	auipc	a0,0x3
    80006d1a:	dc250513          	addi	a0,a0,-574 # 80009ad8 <syscalls+0x3c8>
    80006d1e:	ffffa097          	auipc	ra,0xffffa
    80006d22:	80c080e7          	jalr	-2036(ra) # 8000052a <panic>

0000000080006d26 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006d26:	7119                	addi	sp,sp,-128
    80006d28:	fc86                	sd	ra,120(sp)
    80006d2a:	f8a2                	sd	s0,112(sp)
    80006d2c:	f4a6                	sd	s1,104(sp)
    80006d2e:	f0ca                	sd	s2,96(sp)
    80006d30:	ecce                	sd	s3,88(sp)
    80006d32:	e8d2                	sd	s4,80(sp)
    80006d34:	e4d6                	sd	s5,72(sp)
    80006d36:	e0da                	sd	s6,64(sp)
    80006d38:	fc5e                	sd	s7,56(sp)
    80006d3a:	f862                	sd	s8,48(sp)
    80006d3c:	f466                	sd	s9,40(sp)
    80006d3e:	f06a                	sd	s10,32(sp)
    80006d40:	ec6e                	sd	s11,24(sp)
    80006d42:	0100                	addi	s0,sp,128
    80006d44:	8aaa                	mv	s5,a0
    80006d46:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006d48:	00c52c83          	lw	s9,12(a0)
    80006d4c:	001c9c9b          	slliw	s9,s9,0x1
    80006d50:	1c82                	slli	s9,s9,0x20
    80006d52:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006d56:	00027517          	auipc	a0,0x27
    80006d5a:	3d250513          	addi	a0,a0,978 # 8002e128 <disk+0x2128>
    80006d5e:	ffffa097          	auipc	ra,0xffffa
    80006d62:	e64080e7          	jalr	-412(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006d66:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006d68:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006d6a:	00025c17          	auipc	s8,0x25
    80006d6e:	296c0c13          	addi	s8,s8,662 # 8002c000 <disk>
    80006d72:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006d74:	4b0d                	li	s6,3
    80006d76:	a0ad                	j	80006de0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006d78:	00fc0733          	add	a4,s8,a5
    80006d7c:	975e                	add	a4,a4,s7
    80006d7e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006d82:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006d84:	0207c563          	bltz	a5,80006dae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006d88:	2905                	addiw	s2,s2,1
    80006d8a:	0611                	addi	a2,a2,4
    80006d8c:	19690d63          	beq	s2,s6,80006f26 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006d90:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006d92:	00027717          	auipc	a4,0x27
    80006d96:	28670713          	addi	a4,a4,646 # 8002e018 <disk+0x2018>
    80006d9a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006d9c:	00074683          	lbu	a3,0(a4)
    80006da0:	fee1                	bnez	a3,80006d78 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006da2:	2785                	addiw	a5,a5,1
    80006da4:	0705                	addi	a4,a4,1
    80006da6:	fe979be3          	bne	a5,s1,80006d9c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006daa:	57fd                	li	a5,-1
    80006dac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006dae:	01205d63          	blez	s2,80006dc8 <virtio_disk_rw+0xa2>
    80006db2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006db4:	000a2503          	lw	a0,0(s4)
    80006db8:	00000097          	auipc	ra,0x0
    80006dbc:	d8e080e7          	jalr	-626(ra) # 80006b46 <free_desc>
      for(int j = 0; j < i; j++)
    80006dc0:	2d85                	addiw	s11,s11,1
    80006dc2:	0a11                	addi	s4,s4,4
    80006dc4:	ffb918e3          	bne	s2,s11,80006db4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006dc8:	00027597          	auipc	a1,0x27
    80006dcc:	36058593          	addi	a1,a1,864 # 8002e128 <disk+0x2128>
    80006dd0:	00027517          	auipc	a0,0x27
    80006dd4:	24850513          	addi	a0,a0,584 # 8002e018 <disk+0x2018>
    80006dd8:	ffffb097          	auipc	ra,0xffffb
    80006ddc:	15c080e7          	jalr	348(ra) # 80001f34 <sleep>
  for(int i = 0; i < 3; i++){
    80006de0:	f8040a13          	addi	s4,s0,-128
{
    80006de4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006de6:	894e                	mv	s2,s3
    80006de8:	b765                	j	80006d90 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006dea:	00027697          	auipc	a3,0x27
    80006dee:	2166b683          	ld	a3,534(a3) # 8002e000 <disk+0x2000>
    80006df2:	96ba                	add	a3,a3,a4
    80006df4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006df8:	00025817          	auipc	a6,0x25
    80006dfc:	20880813          	addi	a6,a6,520 # 8002c000 <disk>
    80006e00:	00027697          	auipc	a3,0x27
    80006e04:	20068693          	addi	a3,a3,512 # 8002e000 <disk+0x2000>
    80006e08:	6290                	ld	a2,0(a3)
    80006e0a:	963a                	add	a2,a2,a4
    80006e0c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006e10:	0015e593          	ori	a1,a1,1
    80006e14:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006e18:	f8842603          	lw	a2,-120(s0)
    80006e1c:	628c                	ld	a1,0(a3)
    80006e1e:	972e                	add	a4,a4,a1
    80006e20:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006e24:	20050593          	addi	a1,a0,512
    80006e28:	0592                	slli	a1,a1,0x4
    80006e2a:	95c2                	add	a1,a1,a6
    80006e2c:	577d                	li	a4,-1
    80006e2e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006e32:	00461713          	slli	a4,a2,0x4
    80006e36:	6290                	ld	a2,0(a3)
    80006e38:	963a                	add	a2,a2,a4
    80006e3a:	03078793          	addi	a5,a5,48
    80006e3e:	97c2                	add	a5,a5,a6
    80006e40:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006e42:	629c                	ld	a5,0(a3)
    80006e44:	97ba                	add	a5,a5,a4
    80006e46:	4605                	li	a2,1
    80006e48:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006e4a:	629c                	ld	a5,0(a3)
    80006e4c:	97ba                	add	a5,a5,a4
    80006e4e:	4809                	li	a6,2
    80006e50:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006e54:	629c                	ld	a5,0(a3)
    80006e56:	973e                	add	a4,a4,a5
    80006e58:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006e5c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006e60:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006e64:	6698                	ld	a4,8(a3)
    80006e66:	00275783          	lhu	a5,2(a4)
    80006e6a:	8b9d                	andi	a5,a5,7
    80006e6c:	0786                	slli	a5,a5,0x1
    80006e6e:	97ba                	add	a5,a5,a4
    80006e70:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006e74:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006e78:	6698                	ld	a4,8(a3)
    80006e7a:	00275783          	lhu	a5,2(a4)
    80006e7e:	2785                	addiw	a5,a5,1
    80006e80:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006e84:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006e88:	100017b7          	lui	a5,0x10001
    80006e8c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006e90:	004aa783          	lw	a5,4(s5)
    80006e94:	02c79163          	bne	a5,a2,80006eb6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006e98:	00027917          	auipc	s2,0x27
    80006e9c:	29090913          	addi	s2,s2,656 # 8002e128 <disk+0x2128>
  while(b->disk == 1) {
    80006ea0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006ea2:	85ca                	mv	a1,s2
    80006ea4:	8556                	mv	a0,s5
    80006ea6:	ffffb097          	auipc	ra,0xffffb
    80006eaa:	08e080e7          	jalr	142(ra) # 80001f34 <sleep>
  while(b->disk == 1) {
    80006eae:	004aa783          	lw	a5,4(s5)
    80006eb2:	fe9788e3          	beq	a5,s1,80006ea2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006eb6:	f8042903          	lw	s2,-128(s0)
    80006eba:	20090793          	addi	a5,s2,512
    80006ebe:	00479713          	slli	a4,a5,0x4
    80006ec2:	00025797          	auipc	a5,0x25
    80006ec6:	13e78793          	addi	a5,a5,318 # 8002c000 <disk>
    80006eca:	97ba                	add	a5,a5,a4
    80006ecc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006ed0:	00027997          	auipc	s3,0x27
    80006ed4:	13098993          	addi	s3,s3,304 # 8002e000 <disk+0x2000>
    80006ed8:	00491713          	slli	a4,s2,0x4
    80006edc:	0009b783          	ld	a5,0(s3)
    80006ee0:	97ba                	add	a5,a5,a4
    80006ee2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006ee6:	854a                	mv	a0,s2
    80006ee8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006eec:	00000097          	auipc	ra,0x0
    80006ef0:	c5a080e7          	jalr	-934(ra) # 80006b46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006ef4:	8885                	andi	s1,s1,1
    80006ef6:	f0ed                	bnez	s1,80006ed8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006ef8:	00027517          	auipc	a0,0x27
    80006efc:	23050513          	addi	a0,a0,560 # 8002e128 <disk+0x2128>
    80006f00:	ffffa097          	auipc	ra,0xffffa
    80006f04:	d88080e7          	jalr	-632(ra) # 80000c88 <release>
}
    80006f08:	70e6                	ld	ra,120(sp)
    80006f0a:	7446                	ld	s0,112(sp)
    80006f0c:	74a6                	ld	s1,104(sp)
    80006f0e:	7906                	ld	s2,96(sp)
    80006f10:	69e6                	ld	s3,88(sp)
    80006f12:	6a46                	ld	s4,80(sp)
    80006f14:	6aa6                	ld	s5,72(sp)
    80006f16:	6b06                	ld	s6,64(sp)
    80006f18:	7be2                	ld	s7,56(sp)
    80006f1a:	7c42                	ld	s8,48(sp)
    80006f1c:	7ca2                	ld	s9,40(sp)
    80006f1e:	7d02                	ld	s10,32(sp)
    80006f20:	6de2                	ld	s11,24(sp)
    80006f22:	6109                	addi	sp,sp,128
    80006f24:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f26:	f8042503          	lw	a0,-128(s0)
    80006f2a:	20050793          	addi	a5,a0,512
    80006f2e:	0792                	slli	a5,a5,0x4
  if(write)
    80006f30:	00025817          	auipc	a6,0x25
    80006f34:	0d080813          	addi	a6,a6,208 # 8002c000 <disk>
    80006f38:	00f80733          	add	a4,a6,a5
    80006f3c:	01a036b3          	snez	a3,s10
    80006f40:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006f44:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006f48:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006f4c:	7679                	lui	a2,0xffffe
    80006f4e:	963e                	add	a2,a2,a5
    80006f50:	00027697          	auipc	a3,0x27
    80006f54:	0b068693          	addi	a3,a3,176 # 8002e000 <disk+0x2000>
    80006f58:	6298                	ld	a4,0(a3)
    80006f5a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f5c:	0a878593          	addi	a1,a5,168
    80006f60:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006f62:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006f64:	6298                	ld	a4,0(a3)
    80006f66:	9732                	add	a4,a4,a2
    80006f68:	45c1                	li	a1,16
    80006f6a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006f6c:	6298                	ld	a4,0(a3)
    80006f6e:	9732                	add	a4,a4,a2
    80006f70:	4585                	li	a1,1
    80006f72:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006f76:	f8442703          	lw	a4,-124(s0)
    80006f7a:	628c                	ld	a1,0(a3)
    80006f7c:	962e                	add	a2,a2,a1
    80006f7e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcf00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006f82:	0712                	slli	a4,a4,0x4
    80006f84:	6290                	ld	a2,0(a3)
    80006f86:	963a                	add	a2,a2,a4
    80006f88:	058a8593          	addi	a1,s5,88
    80006f8c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006f8e:	6294                	ld	a3,0(a3)
    80006f90:	96ba                	add	a3,a3,a4
    80006f92:	40000613          	li	a2,1024
    80006f96:	c690                	sw	a2,8(a3)
  if(write)
    80006f98:	e40d19e3          	bnez	s10,80006dea <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006f9c:	00027697          	auipc	a3,0x27
    80006fa0:	0646b683          	ld	a3,100(a3) # 8002e000 <disk+0x2000>
    80006fa4:	96ba                	add	a3,a3,a4
    80006fa6:	4609                	li	a2,2
    80006fa8:	00c69623          	sh	a2,12(a3)
    80006fac:	b5b1                	j	80006df8 <virtio_disk_rw+0xd2>

0000000080006fae <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006fae:	1101                	addi	sp,sp,-32
    80006fb0:	ec06                	sd	ra,24(sp)
    80006fb2:	e822                	sd	s0,16(sp)
    80006fb4:	e426                	sd	s1,8(sp)
    80006fb6:	e04a                	sd	s2,0(sp)
    80006fb8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006fba:	00027517          	auipc	a0,0x27
    80006fbe:	16e50513          	addi	a0,a0,366 # 8002e128 <disk+0x2128>
    80006fc2:	ffffa097          	auipc	ra,0xffffa
    80006fc6:	c00080e7          	jalr	-1024(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006fca:	10001737          	lui	a4,0x10001
    80006fce:	533c                	lw	a5,96(a4)
    80006fd0:	8b8d                	andi	a5,a5,3
    80006fd2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006fd4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006fd8:	00027797          	auipc	a5,0x27
    80006fdc:	02878793          	addi	a5,a5,40 # 8002e000 <disk+0x2000>
    80006fe0:	6b94                	ld	a3,16(a5)
    80006fe2:	0207d703          	lhu	a4,32(a5)
    80006fe6:	0026d783          	lhu	a5,2(a3)
    80006fea:	06f70163          	beq	a4,a5,8000704c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006fee:	00025917          	auipc	s2,0x25
    80006ff2:	01290913          	addi	s2,s2,18 # 8002c000 <disk>
    80006ff6:	00027497          	auipc	s1,0x27
    80006ffa:	00a48493          	addi	s1,s1,10 # 8002e000 <disk+0x2000>
    __sync_synchronize();
    80006ffe:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007002:	6898                	ld	a4,16(s1)
    80007004:	0204d783          	lhu	a5,32(s1)
    80007008:	8b9d                	andi	a5,a5,7
    8000700a:	078e                	slli	a5,a5,0x3
    8000700c:	97ba                	add	a5,a5,a4
    8000700e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007010:	20078713          	addi	a4,a5,512
    80007014:	0712                	slli	a4,a4,0x4
    80007016:	974a                	add	a4,a4,s2
    80007018:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000701c:	e731                	bnez	a4,80007068 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000701e:	20078793          	addi	a5,a5,512
    80007022:	0792                	slli	a5,a5,0x4
    80007024:	97ca                	add	a5,a5,s2
    80007026:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007028:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000702c:	ffffb097          	auipc	ra,0xffffb
    80007030:	f6c080e7          	jalr	-148(ra) # 80001f98 <wakeup>

    disk.used_idx += 1;
    80007034:	0204d783          	lhu	a5,32(s1)
    80007038:	2785                	addiw	a5,a5,1
    8000703a:	17c2                	slli	a5,a5,0x30
    8000703c:	93c1                	srli	a5,a5,0x30
    8000703e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007042:	6898                	ld	a4,16(s1)
    80007044:	00275703          	lhu	a4,2(a4)
    80007048:	faf71be3          	bne	a4,a5,80006ffe <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000704c:	00027517          	auipc	a0,0x27
    80007050:	0dc50513          	addi	a0,a0,220 # 8002e128 <disk+0x2128>
    80007054:	ffffa097          	auipc	ra,0xffffa
    80007058:	c34080e7          	jalr	-972(ra) # 80000c88 <release>
}
    8000705c:	60e2                	ld	ra,24(sp)
    8000705e:	6442                	ld	s0,16(sp)
    80007060:	64a2                	ld	s1,8(sp)
    80007062:	6902                	ld	s2,0(sp)
    80007064:	6105                	addi	sp,sp,32
    80007066:	8082                	ret
      panic("virtio_disk_intr status");
    80007068:	00003517          	auipc	a0,0x3
    8000706c:	a9050513          	addi	a0,a0,-1392 # 80009af8 <syscalls+0x3e8>
    80007070:	ffff9097          	auipc	ra,0xffff9
    80007074:	4ba080e7          	jalr	1210(ra) # 8000052a <panic>
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
