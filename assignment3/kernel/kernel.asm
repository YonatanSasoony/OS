
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
    80000068:	9ec78793          	addi	a5,a5,-1556 # 80006a50 <timervec>
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
    80000122:	22c080e7          	jalr	556(ra) # 8000234a <either_copyin>
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
    800001b6:	852080e7          	jalr	-1966(ra) # 80001a04 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	e64080e7          	jalr	-412(ra) # 80002026 <sleep>
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
    80000202:	0f6080e7          	jalr	246(ra) # 800022f4 <either_copyout>
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
    800002e2:	0c2080e7          	jalr	194(ra) # 800023a0 <procdump>
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
    80000436:	d80080e7          	jalr	-640(ra) # 800021b2 <wakeup>
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
    8000055c:	f5050513          	addi	a0,a0,-176 # 800094a8 <digits+0x468>
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
    80000882:	934080e7          	jalr	-1740(ra) # 800021b2 <wakeup>
    
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
    8000090e:	71c080e7          	jalr	1820(ra) # 80002026 <sleep>
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
    80000b60:	e8c080e7          	jalr	-372(ra) # 800019e8 <mycpu>
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
    80000b92:	e5a080e7          	jalr	-422(ra) # 800019e8 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e4e080e7          	jalr	-434(ra) # 800019e8 <mycpu>
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
    80000bb6:	e36080e7          	jalr	-458(ra) # 800019e8 <mycpu>
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
    80000bf6:	df6080e7          	jalr	-522(ra) # 800019e8 <mycpu>
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
    80000c22:	dca080e7          	jalr	-566(ra) # 800019e8 <mycpu>
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
    80000e78:	b64080e7          	jalr	-1180(ra) # 800019d8 <cpuid>
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
    80000e94:	b48080e7          	jalr	-1208(ra) # 800019d8 <cpuid>
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
    80000eb6:	044080e7          	jalr	68(ra) # 80002ef6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	bd6080e7          	jalr	-1066(ra) # 80006a90 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fb2080e7          	jalr	-78(ra) # 80001e74 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00008517          	auipc	a0,0x8
    80000ede:	5ce50513          	addi	a0,a0,1486 # 800094a8 <digits+0x468>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00008517          	auipc	a0,0x8
    80000eee:	1b650513          	addi	a0,a0,438 # 800090a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00008517          	auipc	a0,0x8
    80000efe:	5ae50513          	addi	a0,a0,1454 # 800094a8 <digits+0x468>
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
    80000f26:	a06080e7          	jalr	-1530(ra) # 80001928 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	fa4080e7          	jalr	-92(ra) # 80002ece <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	fc4080e7          	jalr	-60(ra) # 80002ef6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	b40080e7          	jalr	-1216(ra) # 80006a7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	b4e080e7          	jalr	-1202(ra) # 80006a90 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	724080e7          	jalr	1828(ra) # 8000366e <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	db6080e7          	jalr	-586(ra) # 80003d08 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	076080e7          	jalr	118(ra) # 80004fd0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	c50080e7          	jalr	-944(ra) # 80006bb2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d72080e7          	jalr	-654(ra) # 80001cdc <userinit>
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
    80001220:	676080e7          	jalr	1654(ra) # 80001892 <proc_mapstacks>
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
    800013be:	7139                	addi	sp,sp,-64
    800013c0:	fc06                	sd	ra,56(sp)
    800013c2:	f822                	sd	s0,48(sp)
    800013c4:	f426                	sd	s1,40(sp)
    800013c6:	f04a                	sd	s2,32(sp)
    800013c8:	ec4e                	sd	s3,24(sp)
    800013ca:	e852                	sd	s4,16(sp)
    800013cc:	e456                	sd	s5,8(sp)
    800013ce:	0080                	addi	s0,sp,64
    800013d0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d2:	00b66c63          	bltu	a2,a1,800013ea <uvmdealloc+0x2c>
      remove_page_from_ram(p, a);
    }
  }

  return newsz;
}
    800013d6:	8526                	mv	a0,s1
    800013d8:	70e2                	ld	ra,56(sp)
    800013da:	7442                	ld	s0,48(sp)
    800013dc:	74a2                	ld	s1,40(sp)
    800013de:	7902                	ld	s2,32(sp)
    800013e0:	69e2                	ld	s3,24(sp)
    800013e2:	6a42                	ld	s4,16(sp)
    800013e4:	6aa2                	ld	s5,8(sp)
    800013e6:	6121                	addi	sp,sp,64
    800013e8:	8082                	ret
    800013ea:	8a2a                	mv	s4,a0
    800013ec:	8932                	mv	s2,a2
  struct proc *p = myproc();
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	616080e7          	jalr	1558(ra) # 80001a04 <myproc>
    800013f6:	89aa                	mv	s3,a0
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f8:	6785                	lui	a5,0x1
    800013fa:	17fd                	addi	a5,a5,-1
    800013fc:	00f905b3          	add	a1,s2,a5
    80001400:	767d                	lui	a2,0xfffff
    80001402:	8df1                	and	a1,a1,a2
    80001404:	97a6                	add	a5,a5,s1
    80001406:	8ff1                	and	a5,a5,a2
    80001408:	00f5e463          	bltu	a1,a5,80001410 <uvmdealloc+0x52>
  return newsz;
    8000140c:	84ca                	mv	s1,s2
    8000140e:	b7e1                	j	800013d6 <uvmdealloc+0x18>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001410:	8f8d                	sub	a5,a5,a1
    80001412:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001414:	4685                	li	a3,1
    80001416:	0007861b          	sext.w	a2,a5
    8000141a:	8552                	mv	a0,s4
    8000141c:	00000097          	auipc	ra,0x0
    80001420:	e36080e7          	jalr	-458(ra) # 80001252 <uvmunmap>
    for (int a = PGROUNDDOWN(oldsz); a > PGROUNDDOWN(newsz); a -= PGSIZE) {
    80001424:	77fd                	lui	a5,0xfffff
    80001426:	00f4f5b3          	and	a1,s1,a5
    8000142a:	0005849b          	sext.w	s1,a1
    8000142e:	7a7d                	lui	s4,0xfffff
    80001430:	01497a33          	and	s4,s2,s4
    80001434:	009a7e63          	bgeu	s4,s1,80001450 <uvmdealloc+0x92>
    80001438:	7afd                	lui	s5,0xfffff
      remove_page_from_ram(p, a);
    8000143a:	85a6                	mv	a1,s1
    8000143c:	854e                	mv	a0,s3
    8000143e:	00001097          	auipc	ra,0x1
    80001442:	686080e7          	jalr	1670(ra) # 80002ac4 <remove_page_from_ram>
    for (int a = PGROUNDDOWN(oldsz); a > PGROUNDDOWN(newsz); a -= PGSIZE) {
    80001446:	94d6                	add	s1,s1,s5
    80001448:	fe9a69e3          	bltu	s4,s1,8000143a <uvmdealloc+0x7c>
  return newsz;
    8000144c:	84ca                	mv	s1,s2
    8000144e:	b761                	j	800013d6 <uvmdealloc+0x18>
    80001450:	84ca                	mv	s1,s2
    80001452:	b751                	j	800013d6 <uvmdealloc+0x18>

0000000080001454 <uvmalloc>:
{
    80001454:	7139                	addi	sp,sp,-64
    80001456:	fc06                	sd	ra,56(sp)
    80001458:	f822                	sd	s0,48(sp)
    8000145a:	f426                	sd	s1,40(sp)
    8000145c:	f04a                	sd	s2,32(sp)
    8000145e:	ec4e                	sd	s3,24(sp)
    80001460:	e852                	sd	s4,16(sp)
    80001462:	e456                	sd	s5,8(sp)
    80001464:	e05a                	sd	s6,0(sp)
    80001466:	0080                	addi	s0,sp,64
    80001468:	84ae                	mv	s1,a1
  if(newsz < oldsz)
    8000146a:	00b67d63          	bgeu	a2,a1,80001484 <uvmalloc+0x30>
}
    8000146e:	8526                	mv	a0,s1
    80001470:	70e2                	ld	ra,56(sp)
    80001472:	7442                	ld	s0,48(sp)
    80001474:	74a2                	ld	s1,40(sp)
    80001476:	7902                	ld	s2,32(sp)
    80001478:	69e2                	ld	s3,24(sp)
    8000147a:	6a42                	ld	s4,16(sp)
    8000147c:	6aa2                	ld	s5,8(sp)
    8000147e:	6b02                	ld	s6,0(sp)
    80001480:	6121                	addi	sp,sp,64
    80001482:	8082                	ret
    80001484:	8aaa                	mv	s5,a0
    80001486:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	57c080e7          	jalr	1404(ra) # 80001a04 <myproc>
    80001490:	8b2a                	mv	s6,a0
  oldsz = PGROUNDUP(oldsz);
    80001492:	6a05                	lui	s4,0x1
    80001494:	1a7d                	addi	s4,s4,-1
    80001496:	94d2                	add	s1,s1,s4
    80001498:	7a7d                	lui	s4,0xfffff
    8000149a:	0144fa33          	and	s4,s1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149e:	073a7b63          	bgeu	s4,s3,80001514 <uvmalloc+0xc0>
    800014a2:	8952                	mv	s2,s4
    mem = kalloc();
    800014a4:	fffff097          	auipc	ra,0xfffff
    800014a8:	62e080e7          	jalr	1582(ra) # 80000ad2 <kalloc>
    800014ac:	84aa                	mv	s1,a0
    if(mem == 0){
    800014ae:	cd0d                	beqz	a0,800014e8 <uvmalloc+0x94>
    memset(mem, 0, PGSIZE);
    800014b0:	6605                	lui	a2,0x1
    800014b2:	4581                	li	a1,0
    800014b4:	00000097          	auipc	ra,0x0
    800014b8:	80a080e7          	jalr	-2038(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014bc:	4779                	li	a4,30
    800014be:	86a6                	mv	a3,s1
    800014c0:	6605                	lui	a2,0x1
    800014c2:	85ca                	mv	a1,s2
    800014c4:	8556                	mv	a0,s5
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	bc8080e7          	jalr	-1080(ra) # 8000108e <mappages>
    800014ce:	e50d                	bnez	a0,800014f8 <uvmalloc+0xa4>
    insert_page_to_ram(p, a);
    800014d0:	85ca                	mv	a1,s2
    800014d2:	855a                	mv	a0,s6
    800014d4:	00001097          	auipc	ra,0x1
    800014d8:	78e080e7          	jalr	1934(ra) # 80002c62 <insert_page_to_ram>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014dc:	6785                	lui	a5,0x1
    800014de:	993e                	add	s2,s2,a5
    800014e0:	fd3962e3          	bltu	s2,s3,800014a4 <uvmalloc+0x50>
  return newsz;
    800014e4:	84ce                	mv	s1,s3
    800014e6:	b761                	j	8000146e <uvmalloc+0x1a>
      uvmdealloc(pagetable, a, oldsz);
    800014e8:	8652                	mv	a2,s4
    800014ea:	85ca                	mv	a1,s2
    800014ec:	8556                	mv	a0,s5
    800014ee:	00000097          	auipc	ra,0x0
    800014f2:	ed0080e7          	jalr	-304(ra) # 800013be <uvmdealloc>
      return 0;
    800014f6:	bfa5                	j	8000146e <uvmalloc+0x1a>
      kfree(mem);
    800014f8:	8526                	mv	a0,s1
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	4dc080e7          	jalr	1244(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001502:	8652                	mv	a2,s4
    80001504:	85ca                	mv	a1,s2
    80001506:	8556                	mv	a0,s5
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	eb6080e7          	jalr	-330(ra) # 800013be <uvmdealloc>
      return 0;
    80001510:	4481                	li	s1,0
    80001512:	bfb1                	j	8000146e <uvmalloc+0x1a>
  return newsz;
    80001514:	84ce                	mv	s1,s3
    80001516:	bfa1                	j	8000146e <uvmalloc+0x1a>

0000000080001518 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001518:	7179                	addi	sp,sp,-48
    8000151a:	f406                	sd	ra,40(sp)
    8000151c:	f022                	sd	s0,32(sp)
    8000151e:	ec26                	sd	s1,24(sp)
    80001520:	e84a                	sd	s2,16(sp)
    80001522:	e44e                	sd	s3,8(sp)
    80001524:	e052                	sd	s4,0(sp)
    80001526:	1800                	addi	s0,sp,48
    80001528:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000152a:	84aa                	mv	s1,a0
    8000152c:	6905                	lui	s2,0x1
    8000152e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001530:	4985                	li	s3,1
    80001532:	a821                	j	8000154a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001534:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001536:	0532                	slli	a0,a0,0xc
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	fe0080e7          	jalr	-32(ra) # 80001518 <freewalk>
      pagetable[i] = 0;
    80001540:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001544:	04a1                	addi	s1,s1,8
    80001546:	03248163          	beq	s1,s2,80001568 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000154a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000154c:	00f57793          	andi	a5,a0,15
    80001550:	ff3782e3          	beq	a5,s3,80001534 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001554:	8905                	andi	a0,a0,1
    80001556:	d57d                	beqz	a0,80001544 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001558:	00008517          	auipc	a0,0x8
    8000155c:	c0850513          	addi	a0,a0,-1016 # 80009160 <digits+0x120>
    80001560:	fffff097          	auipc	ra,0xfffff
    80001564:	fca080e7          	jalr	-54(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    80001568:	8552                	mv	a0,s4
    8000156a:	fffff097          	auipc	ra,0xfffff
    8000156e:	46c080e7          	jalr	1132(ra) # 800009d6 <kfree>
}
    80001572:	70a2                	ld	ra,40(sp)
    80001574:	7402                	ld	s0,32(sp)
    80001576:	64e2                	ld	s1,24(sp)
    80001578:	6942                	ld	s2,16(sp)
    8000157a:	69a2                	ld	s3,8(sp)
    8000157c:	6a02                	ld	s4,0(sp)
    8000157e:	6145                	addi	sp,sp,48
    80001580:	8082                	ret

0000000080001582 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001582:	1101                	addi	sp,sp,-32
    80001584:	ec06                	sd	ra,24(sp)
    80001586:	e822                	sd	s0,16(sp)
    80001588:	e426                	sd	s1,8(sp)
    8000158a:	1000                	addi	s0,sp,32
    8000158c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000158e:	e999                	bnez	a1,800015a4 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001590:	8526                	mv	a0,s1
    80001592:	00000097          	auipc	ra,0x0
    80001596:	f86080e7          	jalr	-122(ra) # 80001518 <freewalk>
}
    8000159a:	60e2                	ld	ra,24(sp)
    8000159c:	6442                	ld	s0,16(sp)
    8000159e:	64a2                	ld	s1,8(sp)
    800015a0:	6105                	addi	sp,sp,32
    800015a2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015a4:	6605                	lui	a2,0x1
    800015a6:	167d                	addi	a2,a2,-1
    800015a8:	962e                	add	a2,a2,a1
    800015aa:	4685                	li	a3,1
    800015ac:	8231                	srli	a2,a2,0xc
    800015ae:	4581                	li	a1,0
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	ca2080e7          	jalr	-862(ra) # 80001252 <uvmunmap>
    800015b8:	bfe1                	j	80001590 <uvmfree+0xe>

00000000800015ba <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015ba:	ca71                	beqz	a2,8000168e <uvmcopy+0xd4>
{
    800015bc:	715d                	addi	sp,sp,-80
    800015be:	e486                	sd	ra,72(sp)
    800015c0:	e0a2                	sd	s0,64(sp)
    800015c2:	fc26                	sd	s1,56(sp)
    800015c4:	f84a                	sd	s2,48(sp)
    800015c6:	f44e                	sd	s3,40(sp)
    800015c8:	f052                	sd	s4,32(sp)
    800015ca:	ec56                	sd	s5,24(sp)
    800015cc:	e85a                	sd	s6,16(sp)
    800015ce:	e45e                	sd	s7,8(sp)
    800015d0:	0880                	addi	s0,sp,80
    800015d2:	8b2a                	mv	s6,a0
    800015d4:	8aae                	mv	s5,a1
    800015d6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	4901                	li	s2,0
    800015da:	a081                	j	8000161a <uvmcopy+0x60>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015dc:	00008517          	auipc	a0,0x8
    800015e0:	b9450513          	addi	a0,a0,-1132 # 80009170 <digits+0x130>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f46080e7          	jalr	-186(ra) # 8000052a <panic>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
      panic("uvmcopy: page not present");
    800015ec:	00008517          	auipc	a0,0x8
    800015f0:	ba450513          	addi	a0,a0,-1116 # 80009190 <digits+0x150>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f36080e7          	jalr	-202(ra) # 8000052a <panic>
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if (flags & PTE_PG){// ADDED Q1 - do not copy pages from disk (we are doing that in fork() system call)
      mem = 0;
    800015fc:	4981                	li	s3,0
    } else {
      if((mem = kalloc()) == 0)
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
    }
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015fe:	875e                	mv	a4,s7
    80001600:	86ce                	mv	a3,s3
    80001602:	6605                	lui	a2,0x1
    80001604:	85ca                	mv	a1,s2
    80001606:	8556                	mv	a0,s5
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	a86080e7          	jalr	-1402(ra) # 8000108e <mappages>
    80001610:	e529                	bnez	a0,8000165a <uvmcopy+0xa0>
  for(i = 0; i < sz; i += PGSIZE){
    80001612:	6785                	lui	a5,0x1
    80001614:	993e                	add	s2,s2,a5
    80001616:	07497163          	bgeu	s2,s4,80001678 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    8000161a:	4601                	li	a2,0
    8000161c:	85ca                	mv	a1,s2
    8000161e:	855a                	mv	a0,s6
    80001620:	00000097          	auipc	ra,0x0
    80001624:	986080e7          	jalr	-1658(ra) # 80000fa6 <walk>
    80001628:	d955                	beqz	a0,800015dc <uvmcopy+0x22>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
    8000162a:	6104                	ld	s1,0(a0)
    8000162c:	2014f793          	andi	a5,s1,513
    80001630:	dfd5                	beqz	a5,800015ec <uvmcopy+0x32>
    flags = PTE_FLAGS(*pte);
    80001632:	3ff4fb93          	andi	s7,s1,1023
    if (flags & PTE_PG){// ADDED Q1 - do not copy pages from disk (we are doing that in fork() system call)
    80001636:	2004f793          	andi	a5,s1,512
    8000163a:	f3e9                	bnez	a5,800015fc <uvmcopy+0x42>
      if((mem = kalloc()) == 0)
    8000163c:	fffff097          	auipc	ra,0xfffff
    80001640:	496080e7          	jalr	1174(ra) # 80000ad2 <kalloc>
    80001644:	89aa                	mv	s3,a0
    80001646:	cd19                	beqz	a0,80001664 <uvmcopy+0xaa>
    pa = PTE2PA(*pte);
    80001648:	00a4d593          	srli	a1,s1,0xa
      memmove(mem, (char*)pa, PGSIZE);
    8000164c:	6605                	lui	a2,0x1
    8000164e:	05b2                	slli	a1,a1,0xc
    80001650:	fffff097          	auipc	ra,0xfffff
    80001654:	6ca080e7          	jalr	1738(ra) # 80000d1a <memmove>
    80001658:	b75d                	j	800015fe <uvmcopy+0x44>
      kfree(mem);
    8000165a:	854e                	mv	a0,s3
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	37a080e7          	jalr	890(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001664:	4685                	li	a3,1
    80001666:	00c95613          	srli	a2,s2,0xc
    8000166a:	4581                	li	a1,0
    8000166c:	8556                	mv	a0,s5
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	be4080e7          	jalr	-1052(ra) # 80001252 <uvmunmap>
  return -1;
    80001676:	557d                	li	a0,-1
}
    80001678:	60a6                	ld	ra,72(sp)
    8000167a:	6406                	ld	s0,64(sp)
    8000167c:	74e2                	ld	s1,56(sp)
    8000167e:	7942                	ld	s2,48(sp)
    80001680:	79a2                	ld	s3,40(sp)
    80001682:	7a02                	ld	s4,32(sp)
    80001684:	6ae2                	ld	s5,24(sp)
    80001686:	6b42                	ld	s6,16(sp)
    80001688:	6ba2                	ld	s7,8(sp)
    8000168a:	6161                	addi	sp,sp,80
    8000168c:	8082                	ret
  return 0;
    8000168e:	4501                	li	a0,0
}
    80001690:	8082                	ret

0000000080001692 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001692:	1141                	addi	sp,sp,-16
    80001694:	e406                	sd	ra,8(sp)
    80001696:	e022                	sd	s0,0(sp)
    80001698:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000169a:	4601                	li	a2,0
    8000169c:	00000097          	auipc	ra,0x0
    800016a0:	90a080e7          	jalr	-1782(ra) # 80000fa6 <walk>
  if(pte == 0)
    800016a4:	c901                	beqz	a0,800016b4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016a6:	611c                	ld	a5,0(a0)
    800016a8:	9bbd                	andi	a5,a5,-17
    800016aa:	e11c                	sd	a5,0(a0)
}
    800016ac:	60a2                	ld	ra,8(sp)
    800016ae:	6402                	ld	s0,0(sp)
    800016b0:	0141                	addi	sp,sp,16
    800016b2:	8082                	ret
    panic("uvmclear");
    800016b4:	00008517          	auipc	a0,0x8
    800016b8:	afc50513          	addi	a0,a0,-1284 # 800091b0 <digits+0x170>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e6e080e7          	jalr	-402(ra) # 8000052a <panic>

00000000800016c4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c4:	c6bd                	beqz	a3,80001732 <copyout+0x6e>
{
    800016c6:	715d                	addi	sp,sp,-80
    800016c8:	e486                	sd	ra,72(sp)
    800016ca:	e0a2                	sd	s0,64(sp)
    800016cc:	fc26                	sd	s1,56(sp)
    800016ce:	f84a                	sd	s2,48(sp)
    800016d0:	f44e                	sd	s3,40(sp)
    800016d2:	f052                	sd	s4,32(sp)
    800016d4:	ec56                	sd	s5,24(sp)
    800016d6:	e85a                	sd	s6,16(sp)
    800016d8:	e45e                	sd	s7,8(sp)
    800016da:	e062                	sd	s8,0(sp)
    800016dc:	0880                	addi	s0,sp,80
    800016de:	8b2a                	mv	s6,a0
    800016e0:	8c2e                	mv	s8,a1
    800016e2:	8a32                	mv	s4,a2
    800016e4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016e6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016e8:	6a85                	lui	s5,0x1
    800016ea:	a015                	j	8000170e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ec:	9562                	add	a0,a0,s8
    800016ee:	0004861b          	sext.w	a2,s1
    800016f2:	85d2                	mv	a1,s4
    800016f4:	41250533          	sub	a0,a0,s2
    800016f8:	fffff097          	auipc	ra,0xfffff
    800016fc:	622080e7          	jalr	1570(ra) # 80000d1a <memmove>

    len -= n;
    80001700:	409989b3          	sub	s3,s3,s1
    src += n;
    80001704:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001706:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000170a:	02098263          	beqz	s3,8000172e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000170e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001712:	85ca                	mv	a1,s2
    80001714:	855a                	mv	a0,s6
    80001716:	00000097          	auipc	ra,0x0
    8000171a:	936080e7          	jalr	-1738(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    8000171e:	cd01                	beqz	a0,80001736 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001720:	418904b3          	sub	s1,s2,s8
    80001724:	94d6                	add	s1,s1,s5
    if(n > len)
    80001726:	fc99f3e3          	bgeu	s3,s1,800016ec <copyout+0x28>
    8000172a:	84ce                	mv	s1,s3
    8000172c:	b7c1                	j	800016ec <copyout+0x28>
  }
  return 0;
    8000172e:	4501                	li	a0,0
    80001730:	a021                	j	80001738 <copyout+0x74>
    80001732:	4501                	li	a0,0
}
    80001734:	8082                	ret
      return -1;
    80001736:	557d                	li	a0,-1
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6c02                	ld	s8,0(sp)
    8000174c:	6161                	addi	sp,sp,80
    8000174e:	8082                	ret

0000000080001750 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001750:	caa5                	beqz	a3,800017c0 <copyin+0x70>
{
    80001752:	715d                	addi	sp,sp,-80
    80001754:	e486                	sd	ra,72(sp)
    80001756:	e0a2                	sd	s0,64(sp)
    80001758:	fc26                	sd	s1,56(sp)
    8000175a:	f84a                	sd	s2,48(sp)
    8000175c:	f44e                	sd	s3,40(sp)
    8000175e:	f052                	sd	s4,32(sp)
    80001760:	ec56                	sd	s5,24(sp)
    80001762:	e85a                	sd	s6,16(sp)
    80001764:	e45e                	sd	s7,8(sp)
    80001766:	e062                	sd	s8,0(sp)
    80001768:	0880                	addi	s0,sp,80
    8000176a:	8b2a                	mv	s6,a0
    8000176c:	8a2e                	mv	s4,a1
    8000176e:	8c32                	mv	s8,a2
    80001770:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001772:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001774:	6a85                	lui	s5,0x1
    80001776:	a01d                	j	8000179c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001778:	018505b3          	add	a1,a0,s8
    8000177c:	0004861b          	sext.w	a2,s1
    80001780:	412585b3          	sub	a1,a1,s2
    80001784:	8552                	mv	a0,s4
    80001786:	fffff097          	auipc	ra,0xfffff
    8000178a:	594080e7          	jalr	1428(ra) # 80000d1a <memmove>

    len -= n;
    8000178e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001792:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001794:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001798:	02098263          	beqz	s3,800017bc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000179c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a0:	85ca                	mv	a1,s2
    800017a2:	855a                	mv	a0,s6
    800017a4:	00000097          	auipc	ra,0x0
    800017a8:	8a8080e7          	jalr	-1880(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017ac:	cd01                	beqz	a0,800017c4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ae:	418904b3          	sub	s1,s2,s8
    800017b2:	94d6                	add	s1,s1,s5
    if(n > len)
    800017b4:	fc99f2e3          	bgeu	s3,s1,80001778 <copyin+0x28>
    800017b8:	84ce                	mv	s1,s3
    800017ba:	bf7d                	j	80001778 <copyin+0x28>
  }
  return 0;
    800017bc:	4501                	li	a0,0
    800017be:	a021                	j	800017c6 <copyin+0x76>
    800017c0:	4501                	li	a0,0
}
    800017c2:	8082                	ret
      return -1;
    800017c4:	557d                	li	a0,-1
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6c02                	ld	s8,0(sp)
    800017da:	6161                	addi	sp,sp,80
    800017dc:	8082                	ret

00000000800017de <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017de:	c6c5                	beqz	a3,80001886 <copyinstr+0xa8>
{
    800017e0:	715d                	addi	sp,sp,-80
    800017e2:	e486                	sd	ra,72(sp)
    800017e4:	e0a2                	sd	s0,64(sp)
    800017e6:	fc26                	sd	s1,56(sp)
    800017e8:	f84a                	sd	s2,48(sp)
    800017ea:	f44e                	sd	s3,40(sp)
    800017ec:	f052                	sd	s4,32(sp)
    800017ee:	ec56                	sd	s5,24(sp)
    800017f0:	e85a                	sd	s6,16(sp)
    800017f2:	e45e                	sd	s7,8(sp)
    800017f4:	0880                	addi	s0,sp,80
    800017f6:	8a2a                	mv	s4,a0
    800017f8:	8b2e                	mv	s6,a1
    800017fa:	8bb2                	mv	s7,a2
    800017fc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017fe:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001800:	6985                	lui	s3,0x1
    80001802:	a035                	j	8000182e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001804:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001808:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000180a:	0017b793          	seqz	a5,a5
    8000180e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001812:	60a6                	ld	ra,72(sp)
    80001814:	6406                	ld	s0,64(sp)
    80001816:	74e2                	ld	s1,56(sp)
    80001818:	7942                	ld	s2,48(sp)
    8000181a:	79a2                	ld	s3,40(sp)
    8000181c:	7a02                	ld	s4,32(sp)
    8000181e:	6ae2                	ld	s5,24(sp)
    80001820:	6b42                	ld	s6,16(sp)
    80001822:	6ba2                	ld	s7,8(sp)
    80001824:	6161                	addi	sp,sp,80
    80001826:	8082                	ret
    srcva = va0 + PGSIZE;
    80001828:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000182c:	c8a9                	beqz	s1,8000187e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000182e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001832:	85ca                	mv	a1,s2
    80001834:	8552                	mv	a0,s4
    80001836:	00000097          	auipc	ra,0x0
    8000183a:	816080e7          	jalr	-2026(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    8000183e:	c131                	beqz	a0,80001882 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001840:	41790833          	sub	a6,s2,s7
    80001844:	984e                	add	a6,a6,s3
    if(n > max)
    80001846:	0104f363          	bgeu	s1,a6,8000184c <copyinstr+0x6e>
    8000184a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000184c:	955e                	add	a0,a0,s7
    8000184e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001852:	fc080be3          	beqz	a6,80001828 <copyinstr+0x4a>
    80001856:	985a                	add	a6,a6,s6
    80001858:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000185a:	41650633          	sub	a2,a0,s6
    8000185e:	14fd                	addi	s1,s1,-1
    80001860:	9b26                	add	s6,s6,s1
    80001862:	00f60733          	add	a4,a2,a5
    80001866:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd0000>
    8000186a:	df49                	beqz	a4,80001804 <copyinstr+0x26>
        *dst = *p;
    8000186c:	00e78023          	sb	a4,0(a5)
      --max;
    80001870:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001874:	0785                	addi	a5,a5,1
    while(n > 0){
    80001876:	ff0796e3          	bne	a5,a6,80001862 <copyinstr+0x84>
      dst++;
    8000187a:	8b42                	mv	s6,a6
    8000187c:	b775                	j	80001828 <copyinstr+0x4a>
    8000187e:	4781                	li	a5,0
    80001880:	b769                	j	8000180a <copyinstr+0x2c>
      return -1;
    80001882:	557d                	li	a0,-1
    80001884:	b779                	j	80001812 <copyinstr+0x34>
  int got_null = 0;
    80001886:	4781                	li	a5,0
  if(got_null){
    80001888:	0017b793          	seqz	a5,a5
    8000188c:	40f00533          	neg	a0,a5
}
    80001890:	8082                	ret

0000000080001892 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001892:	7139                	addi	sp,sp,-64
    80001894:	fc06                	sd	ra,56(sp)
    80001896:	f822                	sd	s0,48(sp)
    80001898:	f426                	sd	s1,40(sp)
    8000189a:	f04a                	sd	s2,32(sp)
    8000189c:	ec4e                	sd	s3,24(sp)
    8000189e:	e852                	sd	s4,16(sp)
    800018a0:	e456                	sd	s5,8(sp)
    800018a2:	e05a                	sd	s6,0(sp)
    800018a4:	0080                	addi	s0,sp,64
    800018a6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	00011497          	auipc	s1,0x11
    800018ac:	e2848493          	addi	s1,s1,-472 # 800126d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018b0:	8b26                	mv	s6,s1
    800018b2:	00007a97          	auipc	s5,0x7
    800018b6:	74ea8a93          	addi	s5,s5,1870 # 80009000 <etext>
    800018ba:	04000937          	lui	s2,0x4000
    800018be:	197d                	addi	s2,s2,-1
    800018c0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c2:	0001fa17          	auipc	s4,0x1f
    800018c6:	c0ea0a13          	addi	s4,s4,-1010 # 800204d0 <tickslock>
    char *pa = kalloc();
    800018ca:	fffff097          	auipc	ra,0xfffff
    800018ce:	208080e7          	jalr	520(ra) # 80000ad2 <kalloc>
    800018d2:	862a                	mv	a2,a0
    if(pa == 0)
    800018d4:	c131                	beqz	a0,80001918 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018d6:	416485b3          	sub	a1,s1,s6
    800018da:	858d                	srai	a1,a1,0x3
    800018dc:	000ab783          	ld	a5,0(s5)
    800018e0:	02f585b3          	mul	a1,a1,a5
    800018e4:	2585                	addiw	a1,a1,1
    800018e6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018ea:	4719                	li	a4,6
    800018ec:	6685                	lui	a3,0x1
    800018ee:	40b905b3          	sub	a1,s2,a1
    800018f2:	854e                	mv	a0,s3
    800018f4:	00000097          	auipc	ra,0x0
    800018f8:	838080e7          	jalr	-1992(ra) # 8000112c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fc:	37848493          	addi	s1,s1,888
    80001900:	fd4495e3          	bne	s1,s4,800018ca <proc_mapstacks+0x38>
  }
}
    80001904:	70e2                	ld	ra,56(sp)
    80001906:	7442                	ld	s0,48(sp)
    80001908:	74a2                	ld	s1,40(sp)
    8000190a:	7902                	ld	s2,32(sp)
    8000190c:	69e2                	ld	s3,24(sp)
    8000190e:	6a42                	ld	s4,16(sp)
    80001910:	6aa2                	ld	s5,8(sp)
    80001912:	6b02                	ld	s6,0(sp)
    80001914:	6121                	addi	sp,sp,64
    80001916:	8082                	ret
      panic("kalloc");
    80001918:	00008517          	auipc	a0,0x8
    8000191c:	8a850513          	addi	a0,a0,-1880 # 800091c0 <digits+0x180>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	c0a080e7          	jalr	-1014(ra) # 8000052a <panic>

0000000080001928 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001928:	7139                	addi	sp,sp,-64
    8000192a:	fc06                	sd	ra,56(sp)
    8000192c:	f822                	sd	s0,48(sp)
    8000192e:	f426                	sd	s1,40(sp)
    80001930:	f04a                	sd	s2,32(sp)
    80001932:	ec4e                	sd	s3,24(sp)
    80001934:	e852                	sd	s4,16(sp)
    80001936:	e456                	sd	s5,8(sp)
    80001938:	e05a                	sd	s6,0(sp)
    8000193a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000193c:	00008597          	auipc	a1,0x8
    80001940:	88c58593          	addi	a1,a1,-1908 # 800091c8 <digits+0x188>
    80001944:	00011517          	auipc	a0,0x11
    80001948:	95c50513          	addi	a0,a0,-1700 # 800122a0 <pid_lock>
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	1e6080e7          	jalr	486(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001954:	00008597          	auipc	a1,0x8
    80001958:	87c58593          	addi	a1,a1,-1924 # 800091d0 <digits+0x190>
    8000195c:	00011517          	auipc	a0,0x11
    80001960:	95c50513          	addi	a0,a0,-1700 # 800122b8 <wait_lock>
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	1ce080e7          	jalr	462(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	00011497          	auipc	s1,0x11
    80001970:	d6448493          	addi	s1,s1,-668 # 800126d0 <proc>
      initlock(&p->lock, "proc");
    80001974:	00008b17          	auipc	s6,0x8
    80001978:	86cb0b13          	addi	s6,s6,-1940 # 800091e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    8000197c:	8aa6                	mv	s5,s1
    8000197e:	00007a17          	auipc	s4,0x7
    80001982:	682a0a13          	addi	s4,s4,1666 # 80009000 <etext>
    80001986:	04000937          	lui	s2,0x4000
    8000198a:	197d                	addi	s2,s2,-1
    8000198c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198e:	0001f997          	auipc	s3,0x1f
    80001992:	b4298993          	addi	s3,s3,-1214 # 800204d0 <tickslock>
      initlock(&p->lock, "proc");
    80001996:	85da                	mv	a1,s6
    80001998:	8526                	mv	a0,s1
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	198080e7          	jalr	408(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019a2:	415487b3          	sub	a5,s1,s5
    800019a6:	878d                	srai	a5,a5,0x3
    800019a8:	000a3703          	ld	a4,0(s4)
    800019ac:	02e787b3          	mul	a5,a5,a4
    800019b0:	2785                	addiw	a5,a5,1
    800019b2:	00d7979b          	slliw	a5,a5,0xd
    800019b6:	40f907b3          	sub	a5,s2,a5
    800019ba:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019bc:	37848493          	addi	s1,s1,888
    800019c0:	fd349be3          	bne	s1,s3,80001996 <procinit+0x6e>
  }
}
    800019c4:	70e2                	ld	ra,56(sp)
    800019c6:	7442                	ld	s0,48(sp)
    800019c8:	74a2                	ld	s1,40(sp)
    800019ca:	7902                	ld	s2,32(sp)
    800019cc:	69e2                	ld	s3,24(sp)
    800019ce:	6a42                	ld	s4,16(sp)
    800019d0:	6aa2                	ld	s5,8(sp)
    800019d2:	6b02                	ld	s6,0(sp)
    800019d4:	6121                	addi	sp,sp,64
    800019d6:	8082                	ret

00000000800019d8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019d8:	1141                	addi	sp,sp,-16
    800019da:	e422                	sd	s0,8(sp)
    800019dc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019de:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019e0:	2501                	sext.w	a0,a0
    800019e2:	6422                	ld	s0,8(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret

00000000800019e8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e422                	sd	s0,8(sp)
    800019ec:	0800                	addi	s0,sp,16
    800019ee:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019f0:	2781                	sext.w	a5,a5
    800019f2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019f4:	00011517          	auipc	a0,0x11
    800019f8:	8dc50513          	addi	a0,a0,-1828 # 800122d0 <cpus>
    800019fc:	953e                	add	a0,a0,a5
    800019fe:	6422                	ld	s0,8(sp)
    80001a00:	0141                	addi	sp,sp,16
    80001a02:	8082                	ret

0000000080001a04 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a04:	1101                	addi	sp,sp,-32
    80001a06:	ec06                	sd	ra,24(sp)
    80001a08:	e822                	sd	s0,16(sp)
    80001a0a:	e426                	sd	s1,8(sp)
    80001a0c:	1000                	addi	s0,sp,32
  push_off();
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	168080e7          	jalr	360(ra) # 80000b76 <push_off>
    80001a16:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a18:	2781                	sext.w	a5,a5
    80001a1a:	079e                	slli	a5,a5,0x7
    80001a1c:	00011717          	auipc	a4,0x11
    80001a20:	88470713          	addi	a4,a4,-1916 # 800122a0 <pid_lock>
    80001a24:	97ba                	add	a5,a5,a4
    80001a26:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	1ee080e7          	jalr	494(ra) # 80000c16 <pop_off>
  return p;
}
    80001a30:	8526                	mv	a0,s1
    80001a32:	60e2                	ld	ra,24(sp)
    80001a34:	6442                	ld	s0,16(sp)
    80001a36:	64a2                	ld	s1,8(sp)
    80001a38:	6105                	addi	sp,sp,32
    80001a3a:	8082                	ret

0000000080001a3c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a3c:	1141                	addi	sp,sp,-16
    80001a3e:	e406                	sd	ra,8(sp)
    80001a40:	e022                	sd	s0,0(sp)
    80001a42:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a44:	00000097          	auipc	ra,0x0
    80001a48:	fc0080e7          	jalr	-64(ra) # 80001a04 <myproc>
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	22a080e7          	jalr	554(ra) # 80000c76 <release>

  if (first) {
    80001a54:	00008797          	auipc	a5,0x8
    80001a58:	0cc7a783          	lw	a5,204(a5) # 80009b20 <first.1>
    80001a5c:	eb89                	bnez	a5,80001a6e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a5e:	00001097          	auipc	ra,0x1
    80001a62:	4b0080e7          	jalr	1200(ra) # 80002f0e <usertrapret>
}
    80001a66:	60a2                	ld	ra,8(sp)
    80001a68:	6402                	ld	s0,0(sp)
    80001a6a:	0141                	addi	sp,sp,16
    80001a6c:	8082                	ret
    first = 0;
    80001a6e:	00008797          	auipc	a5,0x8
    80001a72:	0a07a923          	sw	zero,178(a5) # 80009b20 <first.1>
    fsinit(ROOTDEV);
    80001a76:	4505                	li	a0,1
    80001a78:	00002097          	auipc	ra,0x2
    80001a7c:	210080e7          	jalr	528(ra) # 80003c88 <fsinit>
    80001a80:	bff9                	j	80001a5e <forkret+0x22>

0000000080001a82 <allocpid>:
allocpid() {
    80001a82:	1101                	addi	sp,sp,-32
    80001a84:	ec06                	sd	ra,24(sp)
    80001a86:	e822                	sd	s0,16(sp)
    80001a88:	e426                	sd	s1,8(sp)
    80001a8a:	e04a                	sd	s2,0(sp)
    80001a8c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a8e:	00011917          	auipc	s2,0x11
    80001a92:	81290913          	addi	s2,s2,-2030 # 800122a0 <pid_lock>
    80001a96:	854a                	mv	a0,s2
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	12a080e7          	jalr	298(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001aa0:	00008797          	auipc	a5,0x8
    80001aa4:	08478793          	addi	a5,a5,132 # 80009b24 <nextpid>
    80001aa8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aaa:	0014871b          	addiw	a4,s1,1
    80001aae:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ab0:	854a                	mv	a0,s2
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	1c4080e7          	jalr	452(ra) # 80000c76 <release>
}
    80001aba:	8526                	mv	a0,s1
    80001abc:	60e2                	ld	ra,24(sp)
    80001abe:	6442                	ld	s0,16(sp)
    80001ac0:	64a2                	ld	s1,8(sp)
    80001ac2:	6902                	ld	s2,0(sp)
    80001ac4:	6105                	addi	sp,sp,32
    80001ac6:	8082                	ret

0000000080001ac8 <proc_pagetable>:
{
    80001ac8:	1101                	addi	sp,sp,-32
    80001aca:	ec06                	sd	ra,24(sp)
    80001acc:	e822                	sd	s0,16(sp)
    80001ace:	e426                	sd	s1,8(sp)
    80001ad0:	e04a                	sd	s2,0(sp)
    80001ad2:	1000                	addi	s0,sp,32
    80001ad4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ad6:	00000097          	auipc	ra,0x0
    80001ada:	848080e7          	jalr	-1976(ra) # 8000131e <uvmcreate>
    80001ade:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ae0:	c121                	beqz	a0,80001b20 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ae2:	4729                	li	a4,10
    80001ae4:	00006697          	auipc	a3,0x6
    80001ae8:	51c68693          	addi	a3,a3,1308 # 80008000 <_trampoline>
    80001aec:	6605                	lui	a2,0x1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	fffff097          	auipc	ra,0xfffff
    80001afa:	598080e7          	jalr	1432(ra) # 8000108e <mappages>
    80001afe:	02054863          	bltz	a0,80001b2e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b02:	4719                	li	a4,6
    80001b04:	05893683          	ld	a3,88(s2)
    80001b08:	6605                	lui	a2,0x1
    80001b0a:	020005b7          	lui	a1,0x2000
    80001b0e:	15fd                	addi	a1,a1,-1
    80001b10:	05b6                	slli	a1,a1,0xd
    80001b12:	8526                	mv	a0,s1
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	57a080e7          	jalr	1402(ra) # 8000108e <mappages>
    80001b1c:	02054163          	bltz	a0,80001b3e <proc_pagetable+0x76>
}
    80001b20:	8526                	mv	a0,s1
    80001b22:	60e2                	ld	ra,24(sp)
    80001b24:	6442                	ld	s0,16(sp)
    80001b26:	64a2                	ld	s1,8(sp)
    80001b28:	6902                	ld	s2,0(sp)
    80001b2a:	6105                	addi	sp,sp,32
    80001b2c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b2e:	4581                	li	a1,0
    80001b30:	8526                	mv	a0,s1
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	a50080e7          	jalr	-1456(ra) # 80001582 <uvmfree>
    return 0;
    80001b3a:	4481                	li	s1,0
    80001b3c:	b7d5                	j	80001b20 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3e:	4681                	li	a3,0
    80001b40:	4605                	li	a2,1
    80001b42:	040005b7          	lui	a1,0x4000
    80001b46:	15fd                	addi	a1,a1,-1
    80001b48:	05b2                	slli	a1,a1,0xc
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	706080e7          	jalr	1798(ra) # 80001252 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b54:	4581                	li	a1,0
    80001b56:	8526                	mv	a0,s1
    80001b58:	00000097          	auipc	ra,0x0
    80001b5c:	a2a080e7          	jalr	-1494(ra) # 80001582 <uvmfree>
    return 0;
    80001b60:	4481                	li	s1,0
    80001b62:	bf7d                	j	80001b20 <proc_pagetable+0x58>

0000000080001b64 <proc_freepagetable>:
{
    80001b64:	1101                	addi	sp,sp,-32
    80001b66:	ec06                	sd	ra,24(sp)
    80001b68:	e822                	sd	s0,16(sp)
    80001b6a:	e426                	sd	s1,8(sp)
    80001b6c:	e04a                	sd	s2,0(sp)
    80001b6e:	1000                	addi	s0,sp,32
    80001b70:	84aa                	mv	s1,a0
    80001b72:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b74:	4681                	li	a3,0
    80001b76:	4605                	li	a2,1
    80001b78:	040005b7          	lui	a1,0x4000
    80001b7c:	15fd                	addi	a1,a1,-1
    80001b7e:	05b2                	slli	a1,a1,0xc
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	6d2080e7          	jalr	1746(ra) # 80001252 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b88:	4681                	li	a3,0
    80001b8a:	4605                	li	a2,1
    80001b8c:	020005b7          	lui	a1,0x2000
    80001b90:	15fd                	addi	a1,a1,-1
    80001b92:	05b6                	slli	a1,a1,0xd
    80001b94:	8526                	mv	a0,s1
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	6bc080e7          	jalr	1724(ra) # 80001252 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b9e:	85ca                	mv	a1,s2
    80001ba0:	8526                	mv	a0,s1
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	9e0080e7          	jalr	-1568(ra) # 80001582 <uvmfree>
}
    80001baa:	60e2                	ld	ra,24(sp)
    80001bac:	6442                	ld	s0,16(sp)
    80001bae:	64a2                	ld	s1,8(sp)
    80001bb0:	6902                	ld	s2,0(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <freeproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	1000                	addi	s0,sp,32
    80001bc0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bc2:	6d28                	ld	a0,88(a0)
    80001bc4:	c509                	beqz	a0,80001bce <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	e10080e7          	jalr	-496(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001bce:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bd2:	68a8                	ld	a0,80(s1)
    80001bd4:	c511                	beqz	a0,80001be0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bd6:	64ac                	ld	a1,72(s1)
    80001bd8:	00000097          	auipc	ra,0x0
    80001bdc:	f8c080e7          	jalr	-116(ra) # 80001b64 <proc_freepagetable>
  p->pagetable = 0;
    80001be0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001be4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001be8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bec:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bf0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bf4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bf8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bfc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c00:	0004ac23          	sw	zero,24(s1)
}
    80001c04:	60e2                	ld	ra,24(sp)
    80001c06:	6442                	ld	s0,16(sp)
    80001c08:	64a2                	ld	s1,8(sp)
    80001c0a:	6105                	addi	sp,sp,32
    80001c0c:	8082                	ret

0000000080001c0e <allocproc>:
{
    80001c0e:	1101                	addi	sp,sp,-32
    80001c10:	ec06                	sd	ra,24(sp)
    80001c12:	e822                	sd	s0,16(sp)
    80001c14:	e426                	sd	s1,8(sp)
    80001c16:	e04a                	sd	s2,0(sp)
    80001c18:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1a:	00011497          	auipc	s1,0x11
    80001c1e:	ab648493          	addi	s1,s1,-1354 # 800126d0 <proc>
    80001c22:	0001f917          	auipc	s2,0x1f
    80001c26:	8ae90913          	addi	s2,s2,-1874 # 800204d0 <tickslock>
    acquire(&p->lock);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	f96080e7          	jalr	-106(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001c34:	4c9c                	lw	a5,24(s1)
    80001c36:	cf81                	beqz	a5,80001c4e <allocproc+0x40>
      release(&p->lock);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	03c080e7          	jalr	60(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c42:	37848493          	addi	s1,s1,888
    80001c46:	ff2492e3          	bne	s1,s2,80001c2a <allocproc+0x1c>
  return 0;
    80001c4a:	4481                	li	s1,0
    80001c4c:	a889                	j	80001c9e <allocproc+0x90>
  p->pid = allocpid();
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	e34080e7          	jalr	-460(ra) # 80001a82 <allocpid>
    80001c56:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c58:	4785                	li	a5,1
    80001c5a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	e76080e7          	jalr	-394(ra) # 80000ad2 <kalloc>
    80001c64:	892a                	mv	s2,a0
    80001c66:	eca8                	sd	a0,88(s1)
    80001c68:	c131                	beqz	a0,80001cac <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	00000097          	auipc	ra,0x0
    80001c70:	e5c080e7          	jalr	-420(ra) # 80001ac8 <proc_pagetable>
    80001c74:	892a                	mv	s2,a0
    80001c76:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c78:	c531                	beqz	a0,80001cc4 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c7a:	07000613          	li	a2,112
    80001c7e:	4581                	li	a1,0
    80001c80:	06048513          	addi	a0,s1,96
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	03a080e7          	jalr	58(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c8c:	00000797          	auipc	a5,0x0
    80001c90:	db078793          	addi	a5,a5,-592 # 80001a3c <forkret>
    80001c94:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c96:	60bc                	ld	a5,64(s1)
    80001c98:	6705                	lui	a4,0x1
    80001c9a:	97ba                	add	a5,a5,a4
    80001c9c:	f4bc                	sd	a5,104(s1)
}
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	60e2                	ld	ra,24(sp)
    80001ca2:	6442                	ld	s0,16(sp)
    80001ca4:	64a2                	ld	s1,8(sp)
    80001ca6:	6902                	ld	s2,0(sp)
    80001ca8:	6105                	addi	sp,sp,32
    80001caa:	8082                	ret
    freeproc(p);
    80001cac:	8526                	mv	a0,s1
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	f08080e7          	jalr	-248(ra) # 80001bb6 <freeproc>
    release(&p->lock);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	fbe080e7          	jalr	-66(ra) # 80000c76 <release>
    return 0;
    80001cc0:	84ca                	mv	s1,s2
    80001cc2:	bff1                	j	80001c9e <allocproc+0x90>
    freeproc(p);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	ef0080e7          	jalr	-272(ra) # 80001bb6 <freeproc>
    release(&p->lock);
    80001cce:	8526                	mv	a0,s1
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	fa6080e7          	jalr	-90(ra) # 80000c76 <release>
    return 0;
    80001cd8:	84ca                	mv	s1,s2
    80001cda:	b7d1                	j	80001c9e <allocproc+0x90>

0000000080001cdc <userinit>:
{
    80001cdc:	1101                	addi	sp,sp,-32
    80001cde:	ec06                	sd	ra,24(sp)
    80001ce0:	e822                	sd	s0,16(sp)
    80001ce2:	e426                	sd	s1,8(sp)
    80001ce4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	f28080e7          	jalr	-216(ra) # 80001c0e <allocproc>
    80001cee:	84aa                	mv	s1,a0
  initproc = p;
    80001cf0:	00008797          	auipc	a5,0x8
    80001cf4:	32a7bc23          	sd	a0,824(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf8:	03400613          	li	a2,52
    80001cfc:	00008597          	auipc	a1,0x8
    80001d00:	e3458593          	addi	a1,a1,-460 # 80009b30 <initcode>
    80001d04:	6928                	ld	a0,80(a0)
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	646080e7          	jalr	1606(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001d0e:	6785                	lui	a5,0x1
    80001d10:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d12:	6cb8                	ld	a4,88(s1)
    80001d14:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d18:	6cb8                	ld	a4,88(s1)
    80001d1a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d1c:	4641                	li	a2,16
    80001d1e:	00007597          	auipc	a1,0x7
    80001d22:	4ca58593          	addi	a1,a1,1226 # 800091e8 <digits+0x1a8>
    80001d26:	15848513          	addi	a0,s1,344
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	0e6080e7          	jalr	230(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001d32:	00007517          	auipc	a0,0x7
    80001d36:	4c650513          	addi	a0,a0,1222 # 800091f8 <digits+0x1b8>
    80001d3a:	00003097          	auipc	ra,0x3
    80001d3e:	97c080e7          	jalr	-1668(ra) # 800046b6 <namei>
    80001d42:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d46:	478d                	li	a5,3
    80001d48:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	f2a080e7          	jalr	-214(ra) # 80000c76 <release>
}
    80001d54:	60e2                	ld	ra,24(sp)
    80001d56:	6442                	ld	s0,16(sp)
    80001d58:	64a2                	ld	s1,8(sp)
    80001d5a:	6105                	addi	sp,sp,32
    80001d5c:	8082                	ret

0000000080001d5e <growproc>:
{
    80001d5e:	1101                	addi	sp,sp,-32
    80001d60:	ec06                	sd	ra,24(sp)
    80001d62:	e822                	sd	s0,16(sp)
    80001d64:	e426                	sd	s1,8(sp)
    80001d66:	e04a                	sd	s2,0(sp)
    80001d68:	1000                	addi	s0,sp,32
    80001d6a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	c98080e7          	jalr	-872(ra) # 80001a04 <myproc>
    80001d74:	892a                	mv	s2,a0
  sz = p->sz;
    80001d76:	652c                	ld	a1,72(a0)
    80001d78:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d7c:	00904f63          	bgtz	s1,80001d9a <growproc+0x3c>
  } else if(n < 0){
    80001d80:	0204cc63          	bltz	s1,80001db8 <growproc+0x5a>
  p->sz = sz;
    80001d84:	1602                	slli	a2,a2,0x20
    80001d86:	9201                	srli	a2,a2,0x20
    80001d88:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d8c:	4501                	li	a0,0
}
    80001d8e:	60e2                	ld	ra,24(sp)
    80001d90:	6442                	ld	s0,16(sp)
    80001d92:	64a2                	ld	s1,8(sp)
    80001d94:	6902                	ld	s2,0(sp)
    80001d96:	6105                	addi	sp,sp,32
    80001d98:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d9a:	9e25                	addw	a2,a2,s1
    80001d9c:	1602                	slli	a2,a2,0x20
    80001d9e:	9201                	srli	a2,a2,0x20
    80001da0:	1582                	slli	a1,a1,0x20
    80001da2:	9181                	srli	a1,a1,0x20
    80001da4:	6928                	ld	a0,80(a0)
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	6ae080e7          	jalr	1710(ra) # 80001454 <uvmalloc>
    80001dae:	0005061b          	sext.w	a2,a0
    80001db2:	fa69                	bnez	a2,80001d84 <growproc+0x26>
      return -1;
    80001db4:	557d                	li	a0,-1
    80001db6:	bfe1                	j	80001d8e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db8:	9e25                	addw	a2,a2,s1
    80001dba:	1602                	slli	a2,a2,0x20
    80001dbc:	9201                	srli	a2,a2,0x20
    80001dbe:	1582                	slli	a1,a1,0x20
    80001dc0:	9181                	srli	a1,a1,0x20
    80001dc2:	6928                	ld	a0,80(a0)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	5fa080e7          	jalr	1530(ra) # 800013be <uvmdealloc>
    80001dcc:	0005061b          	sext.w	a2,a0
    80001dd0:	bf55                	j	80001d84 <growproc+0x26>

0000000080001dd2 <copy_swapFile>:
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001dd2:	c559                	beqz	a0,80001e60 <copy_swapFile+0x8e>
int copy_swapFile(struct proc *src, struct proc *dst) {
    80001dd4:	7139                	addi	sp,sp,-64
    80001dd6:	fc06                	sd	ra,56(sp)
    80001dd8:	f822                	sd	s0,48(sp)
    80001dda:	f426                	sd	s1,40(sp)
    80001ddc:	f04a                	sd	s2,32(sp)
    80001dde:	ec4e                	sd	s3,24(sp)
    80001de0:	e852                	sd	s4,16(sp)
    80001de2:	e456                	sd	s5,8(sp)
    80001de4:	0080                	addi	s0,sp,64
    80001de6:	89aa                	mv	s3,a0
    80001de8:	8aae                	mv	s5,a1
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001dea:	16853783          	ld	a5,360(a0)
    80001dee:	cbbd                	beqz	a5,80001e64 <copy_swapFile+0x92>
    80001df0:	cda5                	beqz	a1,80001e68 <copy_swapFile+0x96>
    80001df2:	1685b783          	ld	a5,360(a1)
    80001df6:	cbbd                	beqz	a5,80001e6c <copy_swapFile+0x9a>
  char *buffer = (char *)kalloc();
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	cda080e7          	jalr	-806(ra) # 80000ad2 <kalloc>
    80001e00:	892a                	mv	s2,a0
  for (struct disk_page *disk_pg = src->disk_pages; disk_pg < &src->disk_pages[MAX_PSYC_PAGES]; disk_pg++) {
    80001e02:	27098493          	addi	s1,s3,624
    80001e06:	37098a13          	addi	s4,s3,880
    80001e0a:	a021                	j	80001e12 <copy_swapFile+0x40>
    80001e0c:	04c1                	addi	s1,s1,16
    80001e0e:	029a0a63          	beq	s4,s1,80001e42 <copy_swapFile+0x70>
    if(!disk_pg->used) {
    80001e12:	44dc                	lw	a5,12(s1)
    80001e14:	dfe5                	beqz	a5,80001e0c <copy_swapFile+0x3a>
    if (readFromSwapFile(src, buffer, disk_pg->offset, total_size) < 0) {
    80001e16:	66c1                	lui	a3,0x10
    80001e18:	4490                	lw	a2,8(s1)
    80001e1a:	85ca                	mv	a1,s2
    80001e1c:	854e                	mv	a0,s3
    80001e1e:	00003097          	auipc	ra,0x3
    80001e22:	bc0080e7          	jalr	-1088(ra) # 800049de <readFromSwapFile>
    80001e26:	04054563          	bltz	a0,80001e70 <copy_swapFile+0x9e>
    if (writeToSwapFile(dst, buffer, disk_pg->offset, total_size) < 0) {
    80001e2a:	66c1                	lui	a3,0x10
    80001e2c:	4490                	lw	a2,8(s1)
    80001e2e:	85ca                	mv	a1,s2
    80001e30:	8556                	mv	a0,s5
    80001e32:	00003097          	auipc	ra,0x3
    80001e36:	b88080e7          	jalr	-1144(ra) # 800049ba <writeToSwapFile>
    80001e3a:	fc0559e3          	bgez	a0,80001e0c <copy_swapFile+0x3a>
      return -1;
    80001e3e:	557d                	li	a0,-1
    80001e40:	a039                	j	80001e4e <copy_swapFile+0x7c>
  kfree(buffer);
    80001e42:	854a                	mv	a0,s2
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	b92080e7          	jalr	-1134(ra) # 800009d6 <kfree>
  return 0;
    80001e4c:	4501                	li	a0,0
}
    80001e4e:	70e2                	ld	ra,56(sp)
    80001e50:	7442                	ld	s0,48(sp)
    80001e52:	74a2                	ld	s1,40(sp)
    80001e54:	7902                	ld	s2,32(sp)
    80001e56:	69e2                	ld	s3,24(sp)
    80001e58:	6a42                	ld	s4,16(sp)
    80001e5a:	6aa2                	ld	s5,8(sp)
    80001e5c:	6121                	addi	sp,sp,64
    80001e5e:	8082                	ret
    return -1;
    80001e60:	557d                	li	a0,-1
}
    80001e62:	8082                	ret
    return -1;
    80001e64:	557d                	li	a0,-1
    80001e66:	b7e5                	j	80001e4e <copy_swapFile+0x7c>
    80001e68:	557d                	li	a0,-1
    80001e6a:	b7d5                	j	80001e4e <copy_swapFile+0x7c>
    80001e6c:	557d                	li	a0,-1
    80001e6e:	b7c5                	j	80001e4e <copy_swapFile+0x7c>
      return -1;
    80001e70:	557d                	li	a0,-1
    80001e72:	bff1                	j	80001e4e <copy_swapFile+0x7c>

0000000080001e74 <scheduler>:
{
    80001e74:	7139                	addi	sp,sp,-64
    80001e76:	fc06                	sd	ra,56(sp)
    80001e78:	f822                	sd	s0,48(sp)
    80001e7a:	f426                	sd	s1,40(sp)
    80001e7c:	f04a                	sd	s2,32(sp)
    80001e7e:	ec4e                	sd	s3,24(sp)
    80001e80:	e852                	sd	s4,16(sp)
    80001e82:	e456                	sd	s5,8(sp)
    80001e84:	e05a                	sd	s6,0(sp)
    80001e86:	0080                	addi	s0,sp,64
    80001e88:	8792                	mv	a5,tp
  int id = r_tp();
    80001e8a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e8c:	00779a93          	slli	s5,a5,0x7
    80001e90:	00010717          	auipc	a4,0x10
    80001e94:	41070713          	addi	a4,a4,1040 # 800122a0 <pid_lock>
    80001e98:	9756                	add	a4,a4,s5
    80001e9a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001e9e:	00010717          	auipc	a4,0x10
    80001ea2:	43a70713          	addi	a4,a4,1082 # 800122d8 <cpus+0x8>
    80001ea6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ea8:	498d                	li	s3,3
        p->state = RUNNING;
    80001eaa:	4b11                	li	s6,4
        c->proc = p;
    80001eac:	079e                	slli	a5,a5,0x7
    80001eae:	00010a17          	auipc	s4,0x10
    80001eb2:	3f2a0a13          	addi	s4,s4,1010 # 800122a0 <pid_lock>
    80001eb6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eb8:	0001e917          	auipc	s2,0x1e
    80001ebc:	61890913          	addi	s2,s2,1560 # 800204d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ec0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ec4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ec8:	10079073          	csrw	sstatus,a5
    80001ecc:	00011497          	auipc	s1,0x11
    80001ed0:	80448493          	addi	s1,s1,-2044 # 800126d0 <proc>
    80001ed4:	a811                	j	80001ee8 <scheduler+0x74>
      release(&p->lock);
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	d9e080e7          	jalr	-610(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee0:	37848493          	addi	s1,s1,888
    80001ee4:	fd248ee3          	beq	s1,s2,80001ec0 <scheduler+0x4c>
      acquire(&p->lock);
    80001ee8:	8526                	mv	a0,s1
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	cd8080e7          	jalr	-808(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001ef2:	4c9c                	lw	a5,24(s1)
    80001ef4:	ff3791e3          	bne	a5,s3,80001ed6 <scheduler+0x62>
        p->state = RUNNING;
    80001ef8:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001efc:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f00:	06048593          	addi	a1,s1,96
    80001f04:	8556                	mv	a0,s5
    80001f06:	00001097          	auipc	ra,0x1
    80001f0a:	f5e080e7          	jalr	-162(ra) # 80002e64 <swtch>
        c->proc = 0;
    80001f0e:	020a3823          	sd	zero,48(s4)
    80001f12:	b7d1                	j	80001ed6 <scheduler+0x62>

0000000080001f14 <sched>:
{
    80001f14:	7179                	addi	sp,sp,-48
    80001f16:	f406                	sd	ra,40(sp)
    80001f18:	f022                	sd	s0,32(sp)
    80001f1a:	ec26                	sd	s1,24(sp)
    80001f1c:	e84a                	sd	s2,16(sp)
    80001f1e:	e44e                	sd	s3,8(sp)
    80001f20:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f22:	00000097          	auipc	ra,0x0
    80001f26:	ae2080e7          	jalr	-1310(ra) # 80001a04 <myproc>
    80001f2a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	c1c080e7          	jalr	-996(ra) # 80000b48 <holding>
    80001f34:	c93d                	beqz	a0,80001faa <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f36:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f38:	2781                	sext.w	a5,a5
    80001f3a:	079e                	slli	a5,a5,0x7
    80001f3c:	00010717          	auipc	a4,0x10
    80001f40:	36470713          	addi	a4,a4,868 # 800122a0 <pid_lock>
    80001f44:	97ba                	add	a5,a5,a4
    80001f46:	0a87a703          	lw	a4,168(a5) # 10a8 <_entry-0x7fffef58>
    80001f4a:	4785                	li	a5,1
    80001f4c:	06f71763          	bne	a4,a5,80001fba <sched+0xa6>
  if(p->state == RUNNING)
    80001f50:	4c98                	lw	a4,24(s1)
    80001f52:	4791                	li	a5,4
    80001f54:	06f70b63          	beq	a4,a5,80001fca <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f58:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f5c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f5e:	efb5                	bnez	a5,80001fda <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f60:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f62:	00010917          	auipc	s2,0x10
    80001f66:	33e90913          	addi	s2,s2,830 # 800122a0 <pid_lock>
    80001f6a:	2781                	sext.w	a5,a5
    80001f6c:	079e                	slli	a5,a5,0x7
    80001f6e:	97ca                	add	a5,a5,s2
    80001f70:	0ac7a983          	lw	s3,172(a5)
    80001f74:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f76:	2781                	sext.w	a5,a5
    80001f78:	079e                	slli	a5,a5,0x7
    80001f7a:	00010597          	auipc	a1,0x10
    80001f7e:	35e58593          	addi	a1,a1,862 # 800122d8 <cpus+0x8>
    80001f82:	95be                	add	a1,a1,a5
    80001f84:	06048513          	addi	a0,s1,96
    80001f88:	00001097          	auipc	ra,0x1
    80001f8c:	edc080e7          	jalr	-292(ra) # 80002e64 <swtch>
    80001f90:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f92:	2781                	sext.w	a5,a5
    80001f94:	079e                	slli	a5,a5,0x7
    80001f96:	97ca                	add	a5,a5,s2
    80001f98:	0b37a623          	sw	s3,172(a5)
}
    80001f9c:	70a2                	ld	ra,40(sp)
    80001f9e:	7402                	ld	s0,32(sp)
    80001fa0:	64e2                	ld	s1,24(sp)
    80001fa2:	6942                	ld	s2,16(sp)
    80001fa4:	69a2                	ld	s3,8(sp)
    80001fa6:	6145                	addi	sp,sp,48
    80001fa8:	8082                	ret
    panic("sched p->lock");
    80001faa:	00007517          	auipc	a0,0x7
    80001fae:	25650513          	addi	a0,a0,598 # 80009200 <digits+0x1c0>
    80001fb2:	ffffe097          	auipc	ra,0xffffe
    80001fb6:	578080e7          	jalr	1400(ra) # 8000052a <panic>
    panic("sched locks");
    80001fba:	00007517          	auipc	a0,0x7
    80001fbe:	25650513          	addi	a0,a0,598 # 80009210 <digits+0x1d0>
    80001fc2:	ffffe097          	auipc	ra,0xffffe
    80001fc6:	568080e7          	jalr	1384(ra) # 8000052a <panic>
    panic("sched running");
    80001fca:	00007517          	auipc	a0,0x7
    80001fce:	25650513          	addi	a0,a0,598 # 80009220 <digits+0x1e0>
    80001fd2:	ffffe097          	auipc	ra,0xffffe
    80001fd6:	558080e7          	jalr	1368(ra) # 8000052a <panic>
    panic("sched interruptible");
    80001fda:	00007517          	auipc	a0,0x7
    80001fde:	25650513          	addi	a0,a0,598 # 80009230 <digits+0x1f0>
    80001fe2:	ffffe097          	auipc	ra,0xffffe
    80001fe6:	548080e7          	jalr	1352(ra) # 8000052a <panic>

0000000080001fea <yield>:
{
    80001fea:	1101                	addi	sp,sp,-32
    80001fec:	ec06                	sd	ra,24(sp)
    80001fee:	e822                	sd	s0,16(sp)
    80001ff0:	e426                	sd	s1,8(sp)
    80001ff2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	a10080e7          	jalr	-1520(ra) # 80001a04 <myproc>
    80001ffc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	bc4080e7          	jalr	-1084(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002006:	478d                	li	a5,3
    80002008:	cc9c                	sw	a5,24(s1)
  sched();
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	f0a080e7          	jalr	-246(ra) # 80001f14 <sched>
  release(&p->lock);
    80002012:	8526                	mv	a0,s1
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	c62080e7          	jalr	-926(ra) # 80000c76 <release>
}
    8000201c:	60e2                	ld	ra,24(sp)
    8000201e:	6442                	ld	s0,16(sp)
    80002020:	64a2                	ld	s1,8(sp)
    80002022:	6105                	addi	sp,sp,32
    80002024:	8082                	ret

0000000080002026 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002026:	7179                	addi	sp,sp,-48
    80002028:	f406                	sd	ra,40(sp)
    8000202a:	f022                	sd	s0,32(sp)
    8000202c:	ec26                	sd	s1,24(sp)
    8000202e:	e84a                	sd	s2,16(sp)
    80002030:	e44e                	sd	s3,8(sp)
    80002032:	1800                	addi	s0,sp,48
    80002034:	89aa                	mv	s3,a0
    80002036:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	9cc080e7          	jalr	-1588(ra) # 80001a04 <myproc>
    80002040:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	b80080e7          	jalr	-1152(ra) # 80000bc2 <acquire>
  release(lk);
    8000204a:	854a                	mv	a0,s2
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c2a080e7          	jalr	-982(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002054:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002058:	4789                	li	a5,2
    8000205a:	cc9c                	sw	a5,24(s1)

  sched();
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	eb8080e7          	jalr	-328(ra) # 80001f14 <sched>

  // Tidy up.
  p->chan = 0;
    80002064:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	c0c080e7          	jalr	-1012(ra) # 80000c76 <release>
  acquire(lk);
    80002072:	854a                	mv	a0,s2
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	b4e080e7          	jalr	-1202(ra) # 80000bc2 <acquire>
}
    8000207c:	70a2                	ld	ra,40(sp)
    8000207e:	7402                	ld	s0,32(sp)
    80002080:	64e2                	ld	s1,24(sp)
    80002082:	6942                	ld	s2,16(sp)
    80002084:	69a2                	ld	s3,8(sp)
    80002086:	6145                	addi	sp,sp,48
    80002088:	8082                	ret

000000008000208a <wait>:
{
    8000208a:	715d                	addi	sp,sp,-80
    8000208c:	e486                	sd	ra,72(sp)
    8000208e:	e0a2                	sd	s0,64(sp)
    80002090:	fc26                	sd	s1,56(sp)
    80002092:	f84a                	sd	s2,48(sp)
    80002094:	f44e                	sd	s3,40(sp)
    80002096:	f052                	sd	s4,32(sp)
    80002098:	ec56                	sd	s5,24(sp)
    8000209a:	e85a                	sd	s6,16(sp)
    8000209c:	e45e                	sd	s7,8(sp)
    8000209e:	e062                	sd	s8,0(sp)
    800020a0:	0880                	addi	s0,sp,80
    800020a2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020a4:	00000097          	auipc	ra,0x0
    800020a8:	960080e7          	jalr	-1696(ra) # 80001a04 <myproc>
    800020ac:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020ae:	00010517          	auipc	a0,0x10
    800020b2:	20a50513          	addi	a0,a0,522 # 800122b8 <wait_lock>
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	b0c080e7          	jalr	-1268(ra) # 80000bc2 <acquire>
    havekids = 0;
    800020be:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020c0:	4a15                	li	s4,5
        havekids = 1;
    800020c2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800020c4:	0001e997          	auipc	s3,0x1e
    800020c8:	40c98993          	addi	s3,s3,1036 # 800204d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020cc:	00010c17          	auipc	s8,0x10
    800020d0:	1ecc0c13          	addi	s8,s8,492 # 800122b8 <wait_lock>
    havekids = 0;
    800020d4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020d6:	00010497          	auipc	s1,0x10
    800020da:	5fa48493          	addi	s1,s1,1530 # 800126d0 <proc>
    800020de:	a0bd                	j	8000214c <wait+0xc2>
          pid = np->pid;
    800020e0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800020e4:	000b0e63          	beqz	s6,80002100 <wait+0x76>
    800020e8:	4691                	li	a3,4
    800020ea:	02c48613          	addi	a2,s1,44
    800020ee:	85da                	mv	a1,s6
    800020f0:	05093503          	ld	a0,80(s2)
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	5d0080e7          	jalr	1488(ra) # 800016c4 <copyout>
    800020fc:	02054563          	bltz	a0,80002126 <wait+0x9c>
          freeproc(np);
    80002100:	8526                	mv	a0,s1
    80002102:	00000097          	auipc	ra,0x0
    80002106:	ab4080e7          	jalr	-1356(ra) # 80001bb6 <freeproc>
          release(&np->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b6a080e7          	jalr	-1174(ra) # 80000c76 <release>
          release(&wait_lock);
    80002114:	00010517          	auipc	a0,0x10
    80002118:	1a450513          	addi	a0,a0,420 # 800122b8 <wait_lock>
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	b5a080e7          	jalr	-1190(ra) # 80000c76 <release>
          return pid;
    80002124:	a09d                	j	8000218a <wait+0x100>
            release(&np->lock);
    80002126:	8526                	mv	a0,s1
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b4e080e7          	jalr	-1202(ra) # 80000c76 <release>
            release(&wait_lock);
    80002130:	00010517          	auipc	a0,0x10
    80002134:	18850513          	addi	a0,a0,392 # 800122b8 <wait_lock>
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b3e080e7          	jalr	-1218(ra) # 80000c76 <release>
            return -1;
    80002140:	59fd                	li	s3,-1
    80002142:	a0a1                	j	8000218a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002144:	37848493          	addi	s1,s1,888
    80002148:	03348463          	beq	s1,s3,80002170 <wait+0xe6>
      if(np->parent == p){
    8000214c:	7c9c                	ld	a5,56(s1)
    8000214e:	ff279be3          	bne	a5,s2,80002144 <wait+0xba>
        acquire(&np->lock);
    80002152:	8526                	mv	a0,s1
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	a6e080e7          	jalr	-1426(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000215c:	4c9c                	lw	a5,24(s1)
    8000215e:	f94781e3          	beq	a5,s4,800020e0 <wait+0x56>
        release(&np->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	b12080e7          	jalr	-1262(ra) # 80000c76 <release>
        havekids = 1;
    8000216c:	8756                	mv	a4,s5
    8000216e:	bfd9                	j	80002144 <wait+0xba>
    if(!havekids || p->killed){
    80002170:	c701                	beqz	a4,80002178 <wait+0xee>
    80002172:	02892783          	lw	a5,40(s2)
    80002176:	c79d                	beqz	a5,800021a4 <wait+0x11a>
      release(&wait_lock);
    80002178:	00010517          	auipc	a0,0x10
    8000217c:	14050513          	addi	a0,a0,320 # 800122b8 <wait_lock>
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	af6080e7          	jalr	-1290(ra) # 80000c76 <release>
      return -1;
    80002188:	59fd                	li	s3,-1
}
    8000218a:	854e                	mv	a0,s3
    8000218c:	60a6                	ld	ra,72(sp)
    8000218e:	6406                	ld	s0,64(sp)
    80002190:	74e2                	ld	s1,56(sp)
    80002192:	7942                	ld	s2,48(sp)
    80002194:	79a2                	ld	s3,40(sp)
    80002196:	7a02                	ld	s4,32(sp)
    80002198:	6ae2                	ld	s5,24(sp)
    8000219a:	6b42                	ld	s6,16(sp)
    8000219c:	6ba2                	ld	s7,8(sp)
    8000219e:	6c02                	ld	s8,0(sp)
    800021a0:	6161                	addi	sp,sp,80
    800021a2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021a4:	85e2                	mv	a1,s8
    800021a6:	854a                	mv	a0,s2
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	e7e080e7          	jalr	-386(ra) # 80002026 <sleep>
    havekids = 0;
    800021b0:	b715                	j	800020d4 <wait+0x4a>

00000000800021b2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021b2:	7139                	addi	sp,sp,-64
    800021b4:	fc06                	sd	ra,56(sp)
    800021b6:	f822                	sd	s0,48(sp)
    800021b8:	f426                	sd	s1,40(sp)
    800021ba:	f04a                	sd	s2,32(sp)
    800021bc:	ec4e                	sd	s3,24(sp)
    800021be:	e852                	sd	s4,16(sp)
    800021c0:	e456                	sd	s5,8(sp)
    800021c2:	0080                	addi	s0,sp,64
    800021c4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021c6:	00010497          	auipc	s1,0x10
    800021ca:	50a48493          	addi	s1,s1,1290 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021ce:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021d0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021d2:	0001e917          	auipc	s2,0x1e
    800021d6:	2fe90913          	addi	s2,s2,766 # 800204d0 <tickslock>
    800021da:	a811                	j	800021ee <wakeup+0x3c>
      }
      release(&p->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	a98080e7          	jalr	-1384(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021e6:	37848493          	addi	s1,s1,888
    800021ea:	03248663          	beq	s1,s2,80002216 <wakeup+0x64>
    if(p != myproc()){
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	816080e7          	jalr	-2026(ra) # 80001a04 <myproc>
    800021f6:	fea488e3          	beq	s1,a0,800021e6 <wakeup+0x34>
      acquire(&p->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	9c6080e7          	jalr	-1594(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002204:	4c9c                	lw	a5,24(s1)
    80002206:	fd379be3          	bne	a5,s3,800021dc <wakeup+0x2a>
    8000220a:	709c                	ld	a5,32(s1)
    8000220c:	fd4798e3          	bne	a5,s4,800021dc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002210:	0154ac23          	sw	s5,24(s1)
    80002214:	b7e1                	j	800021dc <wakeup+0x2a>
    }
  }
}
    80002216:	70e2                	ld	ra,56(sp)
    80002218:	7442                	ld	s0,48(sp)
    8000221a:	74a2                	ld	s1,40(sp)
    8000221c:	7902                	ld	s2,32(sp)
    8000221e:	69e2                	ld	s3,24(sp)
    80002220:	6a42                	ld	s4,16(sp)
    80002222:	6aa2                	ld	s5,8(sp)
    80002224:	6121                	addi	sp,sp,64
    80002226:	8082                	ret

0000000080002228 <reparent>:
{
    80002228:	7179                	addi	sp,sp,-48
    8000222a:	f406                	sd	ra,40(sp)
    8000222c:	f022                	sd	s0,32(sp)
    8000222e:	ec26                	sd	s1,24(sp)
    80002230:	e84a                	sd	s2,16(sp)
    80002232:	e44e                	sd	s3,8(sp)
    80002234:	e052                	sd	s4,0(sp)
    80002236:	1800                	addi	s0,sp,48
    80002238:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000223a:	00010497          	auipc	s1,0x10
    8000223e:	49648493          	addi	s1,s1,1174 # 800126d0 <proc>
      pp->parent = initproc;
    80002242:	00008a17          	auipc	s4,0x8
    80002246:	de6a0a13          	addi	s4,s4,-538 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000224a:	0001e997          	auipc	s3,0x1e
    8000224e:	28698993          	addi	s3,s3,646 # 800204d0 <tickslock>
    80002252:	a029                	j	8000225c <reparent+0x34>
    80002254:	37848493          	addi	s1,s1,888
    80002258:	01348d63          	beq	s1,s3,80002272 <reparent+0x4a>
    if(pp->parent == p){
    8000225c:	7c9c                	ld	a5,56(s1)
    8000225e:	ff279be3          	bne	a5,s2,80002254 <reparent+0x2c>
      pp->parent = initproc;
    80002262:	000a3503          	ld	a0,0(s4)
    80002266:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	f4a080e7          	jalr	-182(ra) # 800021b2 <wakeup>
    80002270:	b7d5                	j	80002254 <reparent+0x2c>
}
    80002272:	70a2                	ld	ra,40(sp)
    80002274:	7402                	ld	s0,32(sp)
    80002276:	64e2                	ld	s1,24(sp)
    80002278:	6942                	ld	s2,16(sp)
    8000227a:	69a2                	ld	s3,8(sp)
    8000227c:	6a02                	ld	s4,0(sp)
    8000227e:	6145                	addi	sp,sp,48
    80002280:	8082                	ret

0000000080002282 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002282:	7179                	addi	sp,sp,-48
    80002284:	f406                	sd	ra,40(sp)
    80002286:	f022                	sd	s0,32(sp)
    80002288:	ec26                	sd	s1,24(sp)
    8000228a:	e84a                	sd	s2,16(sp)
    8000228c:	e44e                	sd	s3,8(sp)
    8000228e:	1800                	addi	s0,sp,48
    80002290:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002292:	00010497          	auipc	s1,0x10
    80002296:	43e48493          	addi	s1,s1,1086 # 800126d0 <proc>
    8000229a:	0001e997          	auipc	s3,0x1e
    8000229e:	23698993          	addi	s3,s3,566 # 800204d0 <tickslock>
    acquire(&p->lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	91e080e7          	jalr	-1762(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800022ac:	589c                	lw	a5,48(s1)
    800022ae:	01278d63          	beq	a5,s2,800022c8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022b2:	8526                	mv	a0,s1
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	9c2080e7          	jalr	-1598(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022bc:	37848493          	addi	s1,s1,888
    800022c0:	ff3491e3          	bne	s1,s3,800022a2 <kill+0x20>
  }
  return -1;
    800022c4:	557d                	li	a0,-1
    800022c6:	a829                	j	800022e0 <kill+0x5e>
      p->killed = 1;
    800022c8:	4785                	li	a5,1
    800022ca:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022cc:	4c98                	lw	a4,24(s1)
    800022ce:	4789                	li	a5,2
    800022d0:	00f70f63          	beq	a4,a5,800022ee <kill+0x6c>
      release(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	9a0080e7          	jalr	-1632(ra) # 80000c76 <release>
      return 0;
    800022de:	4501                	li	a0,0
}
    800022e0:	70a2                	ld	ra,40(sp)
    800022e2:	7402                	ld	s0,32(sp)
    800022e4:	64e2                	ld	s1,24(sp)
    800022e6:	6942                	ld	s2,16(sp)
    800022e8:	69a2                	ld	s3,8(sp)
    800022ea:	6145                	addi	sp,sp,48
    800022ec:	8082                	ret
        p->state = RUNNABLE;
    800022ee:	478d                	li	a5,3
    800022f0:	cc9c                	sw	a5,24(s1)
    800022f2:	b7cd                	j	800022d4 <kill+0x52>

00000000800022f4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800022f4:	7179                	addi	sp,sp,-48
    800022f6:	f406                	sd	ra,40(sp)
    800022f8:	f022                	sd	s0,32(sp)
    800022fa:	ec26                	sd	s1,24(sp)
    800022fc:	e84a                	sd	s2,16(sp)
    800022fe:	e44e                	sd	s3,8(sp)
    80002300:	e052                	sd	s4,0(sp)
    80002302:	1800                	addi	s0,sp,48
    80002304:	84aa                	mv	s1,a0
    80002306:	892e                	mv	s2,a1
    80002308:	89b2                	mv	s3,a2
    8000230a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	6f8080e7          	jalr	1784(ra) # 80001a04 <myproc>
  if(user_dst){
    80002314:	c08d                	beqz	s1,80002336 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002316:	86d2                	mv	a3,s4
    80002318:	864e                	mv	a2,s3
    8000231a:	85ca                	mv	a1,s2
    8000231c:	6928                	ld	a0,80(a0)
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	3a6080e7          	jalr	934(ra) # 800016c4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002326:	70a2                	ld	ra,40(sp)
    80002328:	7402                	ld	s0,32(sp)
    8000232a:	64e2                	ld	s1,24(sp)
    8000232c:	6942                	ld	s2,16(sp)
    8000232e:	69a2                	ld	s3,8(sp)
    80002330:	6a02                	ld	s4,0(sp)
    80002332:	6145                	addi	sp,sp,48
    80002334:	8082                	ret
    memmove((char *)dst, src, len);
    80002336:	000a061b          	sext.w	a2,s4
    8000233a:	85ce                	mv	a1,s3
    8000233c:	854a                	mv	a0,s2
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	9dc080e7          	jalr	-1572(ra) # 80000d1a <memmove>
    return 0;
    80002346:	8526                	mv	a0,s1
    80002348:	bff9                	j	80002326 <either_copyout+0x32>

000000008000234a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000234a:	7179                	addi	sp,sp,-48
    8000234c:	f406                	sd	ra,40(sp)
    8000234e:	f022                	sd	s0,32(sp)
    80002350:	ec26                	sd	s1,24(sp)
    80002352:	e84a                	sd	s2,16(sp)
    80002354:	e44e                	sd	s3,8(sp)
    80002356:	e052                	sd	s4,0(sp)
    80002358:	1800                	addi	s0,sp,48
    8000235a:	892a                	mv	s2,a0
    8000235c:	84ae                	mv	s1,a1
    8000235e:	89b2                	mv	s3,a2
    80002360:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	6a2080e7          	jalr	1698(ra) # 80001a04 <myproc>
  if(user_src){
    8000236a:	c08d                	beqz	s1,8000238c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000236c:	86d2                	mv	a3,s4
    8000236e:	864e                	mv	a2,s3
    80002370:	85ca                	mv	a1,s2
    80002372:	6928                	ld	a0,80(a0)
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	3dc080e7          	jalr	988(ra) # 80001750 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000237c:	70a2                	ld	ra,40(sp)
    8000237e:	7402                	ld	s0,32(sp)
    80002380:	64e2                	ld	s1,24(sp)
    80002382:	6942                	ld	s2,16(sp)
    80002384:	69a2                	ld	s3,8(sp)
    80002386:	6a02                	ld	s4,0(sp)
    80002388:	6145                	addi	sp,sp,48
    8000238a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000238c:	000a061b          	sext.w	a2,s4
    80002390:	85ce                	mv	a1,s3
    80002392:	854a                	mv	a0,s2
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	986080e7          	jalr	-1658(ra) # 80000d1a <memmove>
    return 0;
    8000239c:	8526                	mv	a0,s1
    8000239e:	bff9                	j	8000237c <either_copyin+0x32>

00000000800023a0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800023a0:	715d                	addi	sp,sp,-80
    800023a2:	e486                	sd	ra,72(sp)
    800023a4:	e0a2                	sd	s0,64(sp)
    800023a6:	fc26                	sd	s1,56(sp)
    800023a8:	f84a                	sd	s2,48(sp)
    800023aa:	f44e                	sd	s3,40(sp)
    800023ac:	f052                	sd	s4,32(sp)
    800023ae:	ec56                	sd	s5,24(sp)
    800023b0:	e85a                	sd	s6,16(sp)
    800023b2:	e45e                	sd	s7,8(sp)
    800023b4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800023b6:	00007517          	auipc	a0,0x7
    800023ba:	0f250513          	addi	a0,a0,242 # 800094a8 <digits+0x468>
    800023be:	ffffe097          	auipc	ra,0xffffe
    800023c2:	1b6080e7          	jalr	438(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c6:	00010497          	auipc	s1,0x10
    800023ca:	46248493          	addi	s1,s1,1122 # 80012828 <proc+0x158>
    800023ce:	0001e917          	auipc	s2,0x1e
    800023d2:	25a90913          	addi	s2,s2,602 # 80020628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023d6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800023d8:	00007997          	auipc	s3,0x7
    800023dc:	e7098993          	addi	s3,s3,-400 # 80009248 <digits+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    800023e0:	00007a97          	auipc	s5,0x7
    800023e4:	e70a8a93          	addi	s5,s5,-400 # 80009250 <digits+0x210>
    printf("\n");
    800023e8:	00007a17          	auipc	s4,0x7
    800023ec:	0c0a0a13          	addi	s4,s4,192 # 800094a8 <digits+0x468>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023f0:	00007b97          	auipc	s7,0x7
    800023f4:	1a8b8b93          	addi	s7,s7,424 # 80009598 <states.0>
    800023f8:	a00d                	j	8000241a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800023fa:	ed86a583          	lw	a1,-296(a3) # fed8 <_entry-0x7fff0128>
    800023fe:	8556                	mv	a0,s5
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	174080e7          	jalr	372(ra) # 80000574 <printf>
    printf("\n");
    80002408:	8552                	mv	a0,s4
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	16a080e7          	jalr	362(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002412:	37848493          	addi	s1,s1,888
    80002416:	03248263          	beq	s1,s2,8000243a <procdump+0x9a>
    if(p->state == UNUSED)
    8000241a:	86a6                	mv	a3,s1
    8000241c:	ec04a783          	lw	a5,-320(s1)
    80002420:	dbed                	beqz	a5,80002412 <procdump+0x72>
      state = "???";
    80002422:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002424:	fcfb6be3          	bltu	s6,a5,800023fa <procdump+0x5a>
    80002428:	02079713          	slli	a4,a5,0x20
    8000242c:	01d75793          	srli	a5,a4,0x1d
    80002430:	97de                	add	a5,a5,s7
    80002432:	6390                	ld	a2,0(a5)
    80002434:	f279                	bnez	a2,800023fa <procdump+0x5a>
      state = "???";
    80002436:	864e                	mv	a2,s3
    80002438:	b7c9                	j	800023fa <procdump+0x5a>
  }
}
    8000243a:	60a6                	ld	ra,72(sp)
    8000243c:	6406                	ld	s0,64(sp)
    8000243e:	74e2                	ld	s1,56(sp)
    80002440:	7942                	ld	s2,48(sp)
    80002442:	79a2                	ld	s3,40(sp)
    80002444:	7a02                	ld	s4,32(sp)
    80002446:	6ae2                	ld	s5,24(sp)
    80002448:	6b42                	ld	s6,16(sp)
    8000244a:	6ba2                	ld	s7,8(sp)
    8000244c:	6161                	addi	sp,sp,80
    8000244e:	8082                	ret

0000000080002450 <init_metadata>:

// ADDED Q1 - p->lock must bot be held because of createSwapFile!
int init_metadata(struct proc *p)
{
    80002450:	1101                	addi	sp,sp,-32
    80002452:	ec06                	sd	ra,24(sp)
    80002454:	e822                	sd	s0,16(sp)
    80002456:	e426                	sd	s1,8(sp)
    80002458:	1000                	addi	s0,sp,32
    8000245a:	84aa                	mv	s1,a0
  if (!p->swapFile && createSwapFile(p) < 0) {
    8000245c:	16853783          	ld	a5,360(a0)
    80002460:	cf95                	beqz	a5,8000249c <init_metadata+0x4c>
    return -1;
  }

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002462:	17048793          	addi	a5,s1,368
{
    80002466:	4701                	li	a4,0
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002468:	6605                	lui	a2,0x1
    8000246a:	66c1                	lui	a3,0x10
    p->ram_pages[i].va = 0;
    8000246c:	0007b023          	sd	zero,0(a5)
    p->ram_pages[i].age = 0; // ADDED Q2
    80002470:	0007a423          	sw	zero,8(a5)
    p->ram_pages[i].used = 0;
    80002474:	0007a623          	sw	zero,12(a5)
    
    p->disk_pages[i].va = 0;
    80002478:	1007b023          	sd	zero,256(a5)
    p->disk_pages[i].offset = i * PGSIZE;
    8000247c:	10e7a423          	sw	a4,264(a5)
    p->disk_pages[i].used = 0;
    80002480:	1007a623          	sw	zero,268(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002484:	07c1                	addi	a5,a5,16
    80002486:	9f31                	addw	a4,a4,a2
    80002488:	fed712e3          	bne	a4,a3,8000246c <init_metadata+0x1c>
  }
  p->scfifo_index = 0; // ADDED Q2
    8000248c:	3604a823          	sw	zero,880(s1)
  return 0;
    80002490:	4501                	li	a0,0
}
    80002492:	60e2                	ld	ra,24(sp)
    80002494:	6442                	ld	s0,16(sp)
    80002496:	64a2                	ld	s1,8(sp)
    80002498:	6105                	addi	sp,sp,32
    8000249a:	8082                	ret
  if (!p->swapFile && createSwapFile(p) < 0) {
    8000249c:	00002097          	auipc	ra,0x2
    800024a0:	46e080e7          	jalr	1134(ra) # 8000490a <createSwapFile>
    800024a4:	fa055fe3          	bgez	a0,80002462 <init_metadata+0x12>
    return -1;
    800024a8:	557d                	li	a0,-1
    800024aa:	b7e5                	j	80002492 <init_metadata+0x42>

00000000800024ac <free_metadata>:

// p->lock must not be held because of removeSwapFile!
void free_metadata(struct proc *p)
{
    800024ac:	1101                	addi	sp,sp,-32
    800024ae:	ec06                	sd	ra,24(sp)
    800024b0:	e822                	sd	s0,16(sp)
    800024b2:	e426                	sd	s1,8(sp)
    800024b4:	1000                	addi	s0,sp,32
    800024b6:	84aa                	mv	s1,a0
    if (removeSwapFile(p) < 0) {
    800024b8:	00002097          	auipc	ra,0x2
    800024bc:	2aa080e7          	jalr	682(ra) # 80004762 <removeSwapFile>
    800024c0:	02054e63          	bltz	a0,800024fc <free_metadata+0x50>
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;
    800024c4:	1604b423          	sd	zero,360(s1)

    for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800024c8:	17048793          	addi	a5,s1,368
    800024cc:	27048713          	addi	a4,s1,624
      p->ram_pages[i].va = 0;
    800024d0:	0007b023          	sd	zero,0(a5)
      p->ram_pages[i].age = 0; // ADDED Q2
    800024d4:	0007a423          	sw	zero,8(a5)
      p->ram_pages[i].used = 0;
    800024d8:	0007a623          	sw	zero,12(a5)

      p->disk_pages[i].va = 0;
    800024dc:	1007b023          	sd	zero,256(a5)
      p->disk_pages[i].offset = 0;
    800024e0:	1007a423          	sw	zero,264(a5)
      p->disk_pages[i].used = 0;
    800024e4:	1007a623          	sw	zero,268(a5)
    for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800024e8:	07c1                	addi	a5,a5,16
    800024ea:	fee793e3          	bne	a5,a4,800024d0 <free_metadata+0x24>
    }
    p->scfifo_index = 0; // ADDED Q2
    800024ee:	3604a823          	sw	zero,880(s1)
}
    800024f2:	60e2                	ld	ra,24(sp)
    800024f4:	6442                	ld	s0,16(sp)
    800024f6:	64a2                	ld	s1,8(sp)
    800024f8:	6105                	addi	sp,sp,32
    800024fa:	8082                	ret
      panic("free_metadata: removeSwapFile failed");
    800024fc:	00007517          	auipc	a0,0x7
    80002500:	d6450513          	addi	a0,a0,-668 # 80009260 <digits+0x220>
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	026080e7          	jalr	38(ra) # 8000052a <panic>

000000008000250c <fork>:
{
    8000250c:	7139                	addi	sp,sp,-64
    8000250e:	fc06                	sd	ra,56(sp)
    80002510:	f822                	sd	s0,48(sp)
    80002512:	f426                	sd	s1,40(sp)
    80002514:	f04a                	sd	s2,32(sp)
    80002516:	ec4e                	sd	s3,24(sp)
    80002518:	e852                	sd	s4,16(sp)
    8000251a:	e456                	sd	s5,8(sp)
    8000251c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	4e6080e7          	jalr	1254(ra) # 80001a04 <myproc>
    80002526:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	6e6080e7          	jalr	1766(ra) # 80001c0e <allocproc>
    80002530:	1c050663          	beqz	a0,800026fc <fork+0x1f0>
    80002534:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002536:	048ab603          	ld	a2,72(s5)
    8000253a:	692c                	ld	a1,80(a0)
    8000253c:	050ab503          	ld	a0,80(s5)
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	07a080e7          	jalr	122(ra) # 800015ba <uvmcopy>
    80002548:	04054863          	bltz	a0,80002598 <fork+0x8c>
  np->sz = p->sz;
    8000254c:	048ab783          	ld	a5,72(s5)
    80002550:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002554:	058ab683          	ld	a3,88(s5)
    80002558:	87b6                	mv	a5,a3
    8000255a:	0589b703          	ld	a4,88(s3)
    8000255e:	12068693          	addi	a3,a3,288 # 10120 <_entry-0x7ffefee0>
    80002562:	0007b803          	ld	a6,0(a5)
    80002566:	6788                	ld	a0,8(a5)
    80002568:	6b8c                	ld	a1,16(a5)
    8000256a:	6f90                	ld	a2,24(a5)
    8000256c:	01073023          	sd	a6,0(a4)
    80002570:	e708                	sd	a0,8(a4)
    80002572:	eb0c                	sd	a1,16(a4)
    80002574:	ef10                	sd	a2,24(a4)
    80002576:	02078793          	addi	a5,a5,32
    8000257a:	02070713          	addi	a4,a4,32
    8000257e:	fed792e3          	bne	a5,a3,80002562 <fork+0x56>
  np->trapframe->a0 = 0;
    80002582:	0589b783          	ld	a5,88(s3)
    80002586:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000258a:	0d0a8493          	addi	s1,s5,208
    8000258e:	0d098913          	addi	s2,s3,208
    80002592:	150a8a13          	addi	s4,s5,336
    80002596:	a00d                	j	800025b8 <fork+0xac>
    freeproc(np);
    80002598:	854e                	mv	a0,s3
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	61c080e7          	jalr	1564(ra) # 80001bb6 <freeproc>
    release(&np->lock);
    800025a2:	854e                	mv	a0,s3
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6d2080e7          	jalr	1746(ra) # 80000c76 <release>
    return -1;
    800025ac:	54fd                	li	s1,-1
    800025ae:	a8f1                	j	8000268a <fork+0x17e>
  for(i = 0; i < NOFILE; i++)
    800025b0:	04a1                	addi	s1,s1,8
    800025b2:	0921                	addi	s2,s2,8
    800025b4:	01448b63          	beq	s1,s4,800025ca <fork+0xbe>
    if(p->ofile[i])
    800025b8:	6088                	ld	a0,0(s1)
    800025ba:	d97d                	beqz	a0,800025b0 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800025bc:	00003097          	auipc	ra,0x3
    800025c0:	aa6080e7          	jalr	-1370(ra) # 80005062 <filedup>
    800025c4:	00a93023          	sd	a0,0(s2)
    800025c8:	b7e5                	j	800025b0 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800025ca:	150ab503          	ld	a0,336(s5)
    800025ce:	00002097          	auipc	ra,0x2
    800025d2:	8f4080e7          	jalr	-1804(ra) # 80003ec2 <idup>
    800025d6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800025da:	4641                	li	a2,16
    800025dc:	158a8593          	addi	a1,s5,344
    800025e0:	15898513          	addi	a0,s3,344
    800025e4:	fffff097          	auipc	ra,0xfffff
    800025e8:	82c080e7          	jalr	-2004(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    800025ec:	0309a483          	lw	s1,48(s3)
  if (relevant_metadata_proc(np)) {
    800025f0:	fff4871b          	addiw	a4,s1,-1
    800025f4:	4785                	li	a5,1
    800025f6:	0ae7e463          	bltu	a5,a4,8000269e <fork+0x192>
    }
  }
}

int relevant_metadata_proc(struct proc *p) {
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    800025fa:	030aa783          	lw	a5,48(s5)
  if (relevant_metadata_proc(p)) {
    800025fe:	37fd                	addiw	a5,a5,-1
    80002600:	4705                	li	a4,1
    80002602:	04f77263          	bgeu	a4,a5,80002646 <fork+0x13a>
    if (copy_swapFile(p, np) < 0) {
    80002606:	85ce                	mv	a1,s3
    80002608:	8556                	mv	a0,s5
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	7c8080e7          	jalr	1992(ra) # 80001dd2 <copy_swapFile>
    80002612:	0c054463          	bltz	a0,800026da <fork+0x1ce>
    memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
    80002616:	10000613          	li	a2,256
    8000261a:	170a8593          	addi	a1,s5,368
    8000261e:	17098513          	addi	a0,s3,368
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	6f8080e7          	jalr	1784(ra) # 80000d1a <memmove>
    memmove(np->disk_pages, p->disk_pages, sizeof(p->disk_pages));
    8000262a:	10000613          	li	a2,256
    8000262e:	270a8593          	addi	a1,s5,624
    80002632:	27098513          	addi	a0,s3,624
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	6e4080e7          	jalr	1764(ra) # 80000d1a <memmove>
    np->scfifo_index = p->scfifo_index; // ADDED Q2
    8000263e:	370aa783          	lw	a5,880(s5)
    80002642:	36f9a823          	sw	a5,880(s3)
  release(&np->lock);
    80002646:	854e                	mv	a0,s3
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	62e080e7          	jalr	1582(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80002650:	00010917          	auipc	s2,0x10
    80002654:	c6890913          	addi	s2,s2,-920 # 800122b8 <wait_lock>
    80002658:	854a                	mv	a0,s2
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	568080e7          	jalr	1384(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002662:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002666:	854a                	mv	a0,s2
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	60e080e7          	jalr	1550(ra) # 80000c76 <release>
  acquire(&np->lock);
    80002670:	854e                	mv	a0,s3
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	550080e7          	jalr	1360(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    8000267a:	478d                	li	a5,3
    8000267c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002680:	854e                	mv	a0,s3
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	5f4080e7          	jalr	1524(ra) # 80000c76 <release>
}
    8000268a:	8526                	mv	a0,s1
    8000268c:	70e2                	ld	ra,56(sp)
    8000268e:	7442                	ld	s0,48(sp)
    80002690:	74a2                	ld	s1,40(sp)
    80002692:	7902                	ld	s2,32(sp)
    80002694:	69e2                	ld	s3,24(sp)
    80002696:	6a42                	ld	s4,16(sp)
    80002698:	6aa2                	ld	s5,8(sp)
    8000269a:	6121                	addi	sp,sp,64
    8000269c:	8082                	ret
    release(&np->lock);
    8000269e:	854e                	mv	a0,s3
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	5d6080e7          	jalr	1494(ra) # 80000c76 <release>
    if (init_metadata(np) < 0) {
    800026a8:	854e                	mv	a0,s3
    800026aa:	00000097          	auipc	ra,0x0
    800026ae:	da6080e7          	jalr	-602(ra) # 80002450 <init_metadata>
    800026b2:	00054863          	bltz	a0,800026c2 <fork+0x1b6>
    acquire(&np->lock);
    800026b6:	854e                	mv	a0,s3
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	50a080e7          	jalr	1290(ra) # 80000bc2 <acquire>
    800026c0:	bf2d                	j	800025fa <fork+0xee>
      freeproc(np);
    800026c2:	854e                	mv	a0,s3
    800026c4:	fffff097          	auipc	ra,0xfffff
    800026c8:	4f2080e7          	jalr	1266(ra) # 80001bb6 <freeproc>
      release(&np->lock);
    800026cc:	854e                	mv	a0,s3
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	5a8080e7          	jalr	1448(ra) # 80000c76 <release>
      return -1;
    800026d6:	54fd                	li	s1,-1
    800026d8:	bf4d                	j	8000268a <fork+0x17e>
      freeproc(np);
    800026da:	854e                	mv	a0,s3
    800026dc:	fffff097          	auipc	ra,0xfffff
    800026e0:	4da080e7          	jalr	1242(ra) # 80001bb6 <freeproc>
      release(&np->lock);
    800026e4:	854e                	mv	a0,s3
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	590080e7          	jalr	1424(ra) # 80000c76 <release>
      free_metadata(np);
    800026ee:	854e                	mv	a0,s3
    800026f0:	00000097          	auipc	ra,0x0
    800026f4:	dbc080e7          	jalr	-580(ra) # 800024ac <free_metadata>
      return -1;
    800026f8:	54fd                	li	s1,-1
    800026fa:	bf41                	j	8000268a <fork+0x17e>
    return -1;
    800026fc:	54fd                	li	s1,-1
    800026fe:	b771                	j	8000268a <fork+0x17e>

0000000080002700 <exit>:
{
    80002700:	7179                	addi	sp,sp,-48
    80002702:	f406                	sd	ra,40(sp)
    80002704:	f022                	sd	s0,32(sp)
    80002706:	ec26                	sd	s1,24(sp)
    80002708:	e84a                	sd	s2,16(sp)
    8000270a:	e44e                	sd	s3,8(sp)
    8000270c:	e052                	sd	s4,0(sp)
    8000270e:	1800                	addi	s0,sp,48
    80002710:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002712:	fffff097          	auipc	ra,0xfffff
    80002716:	2f2080e7          	jalr	754(ra) # 80001a04 <myproc>
    8000271a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000271c:	00008797          	auipc	a5,0x8
    80002720:	90c7b783          	ld	a5,-1780(a5) # 8000a028 <initproc>
    80002724:	0d050493          	addi	s1,a0,208
    80002728:	15050913          	addi	s2,a0,336
    8000272c:	02a79363          	bne	a5,a0,80002752 <exit+0x52>
    panic("init exiting");
    80002730:	00007517          	auipc	a0,0x7
    80002734:	b5850513          	addi	a0,a0,-1192 # 80009288 <digits+0x248>
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	df2080e7          	jalr	-526(ra) # 8000052a <panic>
      fileclose(f);
    80002740:	00003097          	auipc	ra,0x3
    80002744:	974080e7          	jalr	-1676(ra) # 800050b4 <fileclose>
      p->ofile[fd] = 0;
    80002748:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000274c:	04a1                	addi	s1,s1,8
    8000274e:	01248563          	beq	s1,s2,80002758 <exit+0x58>
    if(p->ofile[fd]){
    80002752:	6088                	ld	a0,0(s1)
    80002754:	f575                	bnez	a0,80002740 <exit+0x40>
    80002756:	bfdd                	j	8000274c <exit+0x4c>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002758:	0309a783          	lw	a5,48(s3)
  if (relevant_metadata_proc(p)) {
    8000275c:	37fd                	addiw	a5,a5,-1
    8000275e:	4705                	li	a4,1
    80002760:	08f76163          	bltu	a4,a5,800027e2 <exit+0xe2>
  begin_op();
    80002764:	00002097          	auipc	ra,0x2
    80002768:	484080e7          	jalr	1156(ra) # 80004be8 <begin_op>
  iput(p->cwd);
    8000276c:	1509b503          	ld	a0,336(s3)
    80002770:	00002097          	auipc	ra,0x2
    80002774:	94a080e7          	jalr	-1718(ra) # 800040ba <iput>
  end_op();
    80002778:	00002097          	auipc	ra,0x2
    8000277c:	4f0080e7          	jalr	1264(ra) # 80004c68 <end_op>
  p->cwd = 0;
    80002780:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002784:	00010497          	auipc	s1,0x10
    80002788:	b3448493          	addi	s1,s1,-1228 # 800122b8 <wait_lock>
    8000278c:	8526                	mv	a0,s1
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	434080e7          	jalr	1076(ra) # 80000bc2 <acquire>
  reparent(p);
    80002796:	854e                	mv	a0,s3
    80002798:	00000097          	auipc	ra,0x0
    8000279c:	a90080e7          	jalr	-1392(ra) # 80002228 <reparent>
  wakeup(p->parent);
    800027a0:	0389b503          	ld	a0,56(s3)
    800027a4:	00000097          	auipc	ra,0x0
    800027a8:	a0e080e7          	jalr	-1522(ra) # 800021b2 <wakeup>
  acquire(&p->lock);
    800027ac:	854e                	mv	a0,s3
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	414080e7          	jalr	1044(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800027b6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027ba:	4795                	li	a5,5
    800027bc:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	4b4080e7          	jalr	1204(ra) # 80000c76 <release>
  sched();
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	74a080e7          	jalr	1866(ra) # 80001f14 <sched>
  panic("zombie exit");
    800027d2:	00007517          	auipc	a0,0x7
    800027d6:	ac650513          	addi	a0,a0,-1338 # 80009298 <digits+0x258>
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	d50080e7          	jalr	-688(ra) # 8000052a <panic>
    free_metadata(p);
    800027e2:	854e                	mv	a0,s3
    800027e4:	00000097          	auipc	ra,0x0
    800027e8:	cc8080e7          	jalr	-824(ra) # 800024ac <free_metadata>
    800027ec:	bfa5                	j	80002764 <exit+0x64>

00000000800027ee <get_free_page_in_disk>:
{
    800027ee:	1141                	addi	sp,sp,-16
    800027f0:	e406                	sd	ra,8(sp)
    800027f2:	e022                	sd	s0,0(sp)
    800027f4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027f6:	fffff097          	auipc	ra,0xfffff
    800027fa:	20e080e7          	jalr	526(ra) # 80001a04 <myproc>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    800027fe:	27050793          	addi	a5,a0,624
  int index = 0;
    80002802:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    80002804:	46c1                	li	a3,16
    if (!disk_pg->used) {
    80002806:	47d8                	lw	a4,12(a5)
    80002808:	c711                	beqz	a4,80002814 <get_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_PSYC_PAGES]; disk_pg++, index++){
    8000280a:	07c1                	addi	a5,a5,16
    8000280c:	2505                	addiw	a0,a0,1
    8000280e:	fed51ce3          	bne	a0,a3,80002806 <get_free_page_in_disk+0x18>
  return -1;
    80002812:	557d                	li	a0,-1
}
    80002814:	60a2                	ld	ra,8(sp)
    80002816:	6402                	ld	s0,0(sp)
    80002818:	0141                	addi	sp,sp,16
    8000281a:	8082                	ret

000000008000281c <swapout>:
{
    8000281c:	7139                	addi	sp,sp,-64
    8000281e:	fc06                	sd	ra,56(sp)
    80002820:	f822                	sd	s0,48(sp)
    80002822:	f426                	sd	s1,40(sp)
    80002824:	f04a                	sd	s2,32(sp)
    80002826:	ec4e                	sd	s3,24(sp)
    80002828:	e852                	sd	s4,16(sp)
    8000282a:	e456                	sd	s5,8(sp)
    8000282c:	0080                	addi	s0,sp,64
  if (ram_pg_index < 0 || ram_pg_index > MAX_PSYC_PAGES) {
    8000282e:	47c1                	li	a5,16
    80002830:	0ab7e463          	bltu	a5,a1,800028d8 <swapout+0xbc>
    80002834:	8aaa                	mv	s5,a0
  if (!ram_pg_to_swap->used) {
    80002836:	00459913          	slli	s2,a1,0x4
    8000283a:	992a                	add	s2,s2,a0
    8000283c:	17c92783          	lw	a5,380(s2)
    80002840:	c7c5                	beqz	a5,800028e8 <swapout+0xcc>
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    80002842:	4601                	li	a2,0
    80002844:	17093583          	ld	a1,368(s2)
    80002848:	6928                	ld	a0,80(a0)
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	75c080e7          	jalr	1884(ra) # 80000fa6 <walk>
    80002852:	89aa                	mv	s3,a0
    80002854:	c155                	beqz	a0,800028f8 <swapout+0xdc>
  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    80002856:	611c                	ld	a5,0(a0)
    80002858:	2017f793          	andi	a5,a5,513
    8000285c:	4705                	li	a4,1
    8000285e:	0ae79563          	bne	a5,a4,80002908 <swapout+0xec>
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    80002862:	00000097          	auipc	ra,0x0
    80002866:	f8c080e7          	jalr	-116(ra) # 800027ee <get_free_page_in_disk>
    8000286a:	0a054763          	bltz	a0,80002918 <swapout+0xfc>
  uint64 pa = PTE2PA(*pte);
    8000286e:	0009ba03          	ld	s4,0(s3)
    80002872:	00aa5a13          	srli	s4,s4,0xa
    80002876:	0a32                	slli	s4,s4,0xc
    80002878:	00451493          	slli	s1,a0,0x4
    8000287c:	94d6                	add	s1,s1,s5
  if (writeToSwapFile(p, (char *)pa, disk_pg_to_store->offset, PGSIZE) < 0) {
    8000287e:	6685                	lui	a3,0x1
    80002880:	2784a603          	lw	a2,632(s1)
    80002884:	85d2                	mv	a1,s4
    80002886:	8556                	mv	a0,s5
    80002888:	00002097          	auipc	ra,0x2
    8000288c:	132080e7          	jalr	306(ra) # 800049ba <writeToSwapFile>
    80002890:	08054c63          	bltz	a0,80002928 <swapout+0x10c>
  disk_pg_to_store->used = 1;
    80002894:	4785                	li	a5,1
    80002896:	26f4ae23          	sw	a5,636(s1)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    8000289a:	17093783          	ld	a5,368(s2)
    8000289e:	26f4b823          	sd	a5,624(s1)
  kfree((void *)pa);
    800028a2:	8552                	mv	a0,s4
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	132080e7          	jalr	306(ra) # 800009d6 <kfree>
  ram_pg_to_swap->va = 0;
    800028ac:	16093823          	sd	zero,368(s2)
  ram_pg_to_swap->used = 0;
    800028b0:	16092e23          	sw	zero,380(s2)
  *pte = *pte & ~PTE_V;
    800028b4:	0009b783          	ld	a5,0(s3)
    800028b8:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    800028ba:	2007e793          	ori	a5,a5,512
    800028be:	00f9b023          	sd	a5,0(s3)
  asm volatile("sfence.vma zero, zero");
    800028c2:	12000073          	sfence.vma
}
    800028c6:	70e2                	ld	ra,56(sp)
    800028c8:	7442                	ld	s0,48(sp)
    800028ca:	74a2                	ld	s1,40(sp)
    800028cc:	7902                	ld	s2,32(sp)
    800028ce:	69e2                	ld	s3,24(sp)
    800028d0:	6a42                	ld	s4,16(sp)
    800028d2:	6aa2                	ld	s5,8(sp)
    800028d4:	6121                	addi	sp,sp,64
    800028d6:	8082                	ret
    panic("swapout: ram page index out of bounds");
    800028d8:	00007517          	auipc	a0,0x7
    800028dc:	9d050513          	addi	a0,a0,-1584 # 800092a8 <digits+0x268>
    800028e0:	ffffe097          	auipc	ra,0xffffe
    800028e4:	c4a080e7          	jalr	-950(ra) # 8000052a <panic>
    panic("swapout: page unused");
    800028e8:	00007517          	auipc	a0,0x7
    800028ec:	9e850513          	addi	a0,a0,-1560 # 800092d0 <digits+0x290>
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	c3a080e7          	jalr	-966(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    800028f8:	00007517          	auipc	a0,0x7
    800028fc:	9f050513          	addi	a0,a0,-1552 # 800092e8 <digits+0x2a8>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c2a080e7          	jalr	-982(ra) # 8000052a <panic>
    panic("swapout: page is not in ram");
    80002908:	00007517          	auipc	a0,0x7
    8000290c:	9f850513          	addi	a0,a0,-1544 # 80009300 <digits+0x2c0>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	c1a080e7          	jalr	-998(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    80002918:	00007517          	auipc	a0,0x7
    8000291c:	a0850513          	addi	a0,a0,-1528 # 80009320 <digits+0x2e0>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	c0a080e7          	jalr	-1014(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    80002928:	00007517          	auipc	a0,0x7
    8000292c:	a1050513          	addi	a0,a0,-1520 # 80009338 <digits+0x2f8>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	bfa080e7          	jalr	-1030(ra) # 8000052a <panic>

0000000080002938 <swapin>:
{
    80002938:	7139                	addi	sp,sp,-64
    8000293a:	fc06                	sd	ra,56(sp)
    8000293c:	f822                	sd	s0,48(sp)
    8000293e:	f426                	sd	s1,40(sp)
    80002940:	f04a                	sd	s2,32(sp)
    80002942:	ec4e                	sd	s3,24(sp)
    80002944:	e852                	sd	s4,16(sp)
    80002946:	e456                	sd	s5,8(sp)
    80002948:	0080                	addi	s0,sp,64
  if (disk_index < 0 || disk_index > MAX_PSYC_PAGES) {
    8000294a:	47c1                	li	a5,16
    8000294c:	0ab7e963          	bltu	a5,a1,800029fe <swapin+0xc6>
    80002950:	8aaa                	mv	s5,a0
    80002952:	89b2                	mv	s3,a2
  if (ram_index < 0 || ram_index > MAX_PSYC_PAGES) {
    80002954:	0006079b          	sext.w	a5,a2
    80002958:	4741                	li	a4,16
    8000295a:	0af76a63          	bltu	a4,a5,80002a0e <swapin+0xd6>
  if (!disk_pg->used) {
    8000295e:	00459913          	slli	s2,a1,0x4
    80002962:	992a                	add	s2,s2,a0
    80002964:	27c92783          	lw	a5,636(s2)
    80002968:	cbdd                	beqz	a5,80002a1e <swapin+0xe6>
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    8000296a:	4601                	li	a2,0
    8000296c:	27093583          	ld	a1,624(s2)
    80002970:	6928                	ld	a0,80(a0)
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	634080e7          	jalr	1588(ra) # 80000fa6 <walk>
    8000297a:	8a2a                	mv	s4,a0
    8000297c:	c94d                	beqz	a0,80002a2e <swapin+0xf6>
  if ((*pte & PTE_V) || !(*pte & PTE_PG))
    8000297e:	611c                	ld	a5,0(a0)
    80002980:	2017f793          	andi	a5,a5,513
    80002984:	20000713          	li	a4,512
    80002988:	0ae79b63          	bne	a5,a4,80002a3e <swapin+0x106>
  if (ram_pg->used) {
    8000298c:	0992                	slli	s3,s3,0x4
    8000298e:	99d6                	add	s3,s3,s5
    80002990:	17c9a783          	lw	a5,380(s3)
    80002994:	efcd                	bnez	a5,80002a4e <swapin+0x116>
  if ( (npa = (uint64)kalloc()) == 0 ) {
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	13c080e7          	jalr	316(ra) # 80000ad2 <kalloc>
    8000299e:	84aa                	mv	s1,a0
    800029a0:	cd5d                	beqz	a0,80002a5e <swapin+0x126>
  if (readFromSwapFile(p, (char *)npa, disk_pg->offset, PGSIZE) < 0) {
    800029a2:	6685                	lui	a3,0x1
    800029a4:	27892603          	lw	a2,632(s2)
    800029a8:	85aa                	mv	a1,a0
    800029aa:	8556                	mv	a0,s5
    800029ac:	00002097          	auipc	ra,0x2
    800029b0:	032080e7          	jalr	50(ra) # 800049de <readFromSwapFile>
    800029b4:	0a054d63          	bltz	a0,80002a6e <swapin+0x136>
  ram_pg->used = 1;
    800029b8:	4785                	li	a5,1
    800029ba:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    800029be:	27093783          	ld	a5,624(s2)
    800029c2:	16f9b823          	sd	a5,368(s3)
    ram_pg->age = 0;
    800029c6:	1609ac23          	sw	zero,376(s3)
  disk_pg->va = 0;
    800029ca:	26093823          	sd	zero,624(s2)
  disk_pg->used = 0;
    800029ce:	26092e23          	sw	zero,636(s2)
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    800029d2:	80b1                	srli	s1,s1,0xc
    800029d4:	04aa                	slli	s1,s1,0xa
    800029d6:	000a3783          	ld	a5,0(s4)
    800029da:	1ff7f793          	andi	a5,a5,511
    800029de:	8cdd                	or	s1,s1,a5
    800029e0:	0014e493          	ori	s1,s1,1
    800029e4:	009a3023          	sd	s1,0(s4)
    800029e8:	12000073          	sfence.vma
}
    800029ec:	70e2                	ld	ra,56(sp)
    800029ee:	7442                	ld	s0,48(sp)
    800029f0:	74a2                	ld	s1,40(sp)
    800029f2:	7902                	ld	s2,32(sp)
    800029f4:	69e2                	ld	s3,24(sp)
    800029f6:	6a42                	ld	s4,16(sp)
    800029f8:	6aa2                	ld	s5,8(sp)
    800029fa:	6121                	addi	sp,sp,64
    800029fc:	8082                	ret
    panic("swapin: disk index out of bounds");
    800029fe:	00007517          	auipc	a0,0x7
    80002a02:	96250513          	addi	a0,a0,-1694 # 80009360 <digits+0x320>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b24080e7          	jalr	-1244(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    80002a0e:	00007517          	auipc	a0,0x7
    80002a12:	97a50513          	addi	a0,a0,-1670 # 80009388 <digits+0x348>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b14080e7          	jalr	-1260(ra) # 8000052a <panic>
    panic("swapin: page unused");
    80002a1e:	00007517          	auipc	a0,0x7
    80002a22:	98a50513          	addi	a0,a0,-1654 # 800093a8 <digits+0x368>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	b04080e7          	jalr	-1276(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    80002a2e:	00007517          	auipc	a0,0x7
    80002a32:	99250513          	addi	a0,a0,-1646 # 800093c0 <digits+0x380>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	af4080e7          	jalr	-1292(ra) # 8000052a <panic>
      panic("swapin: page is not in disk");
    80002a3e:	00007517          	auipc	a0,0x7
    80002a42:	99a50513          	addi	a0,a0,-1638 # 800093d8 <digits+0x398>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	ae4080e7          	jalr	-1308(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    80002a4e:	00007517          	auipc	a0,0x7
    80002a52:	9aa50513          	addi	a0,a0,-1622 # 800093f8 <digits+0x3b8>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	ad4080e7          	jalr	-1324(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    80002a5e:	00007517          	auipc	a0,0x7
    80002a62:	9b250513          	addi	a0,a0,-1614 # 80009410 <digits+0x3d0>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	ac4080e7          	jalr	-1340(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002a6e:	00007517          	auipc	a0,0x7
    80002a72:	9ca50513          	addi	a0,a0,-1590 # 80009438 <digits+0x3f8>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	ab4080e7          	jalr	-1356(ra) # 8000052a <panic>

0000000080002a7e <get_unused_ram_index>:
{
    80002a7e:	1141                	addi	sp,sp,-16
    80002a80:	e422                	sd	s0,8(sp)
    80002a82:	0800                	addi	s0,sp,16
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    80002a84:	17c50793          	addi	a5,a0,380
    80002a88:	4501                	li	a0,0
    80002a8a:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    80002a8c:	4398                	lw	a4,0(a5)
    80002a8e:	c711                	beqz	a4,80002a9a <get_unused_ram_index+0x1c>
  for (int i=0; i<MAX_PSYC_PAGES; i++) {
    80002a90:	2505                	addiw	a0,a0,1
    80002a92:	07c1                	addi	a5,a5,16
    80002a94:	fed51ce3          	bne	a0,a3,80002a8c <get_unused_ram_index+0xe>
  return -1;
    80002a98:	557d                	li	a0,-1
}
    80002a9a:	6422                	ld	s0,8(sp)
    80002a9c:	0141                	addi	sp,sp,16
    80002a9e:	8082                	ret

0000000080002aa0 <get_disk_page_index>:
{
    80002aa0:	1141                	addi	sp,sp,-16
    80002aa2:	e422                	sd	s0,8(sp)
    80002aa4:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002aa6:	27050793          	addi	a5,a0,624
    80002aaa:	4501                	li	a0,0
    80002aac:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    80002aae:	6398                	ld	a4,0(a5)
    80002ab0:	00b70763          	beq	a4,a1,80002abe <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002ab4:	2505                	addiw	a0,a0,1
    80002ab6:	07c1                	addi	a5,a5,16
    80002ab8:	fed51be3          	bne	a0,a3,80002aae <get_disk_page_index+0xe>
  return -1;
    80002abc:	557d                	li	a0,-1
}
    80002abe:	6422                	ld	s0,8(sp)
    80002ac0:	0141                	addi	sp,sp,16
    80002ac2:	8082                	ret

0000000080002ac4 <remove_page_from_ram>:
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002ac4:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002ac6:	37fd                	addiw	a5,a5,-1
    80002ac8:	4705                	li	a4,1
    80002aca:	04f77563          	bgeu	a4,a5,80002b14 <remove_page_from_ram+0x50>
    80002ace:	17050793          	addi	a5,a0,368
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002ad2:	4701                	li	a4,0
    80002ad4:	4641                	li	a2,16
    80002ad6:	a029                	j	80002ae0 <remove_page_from_ram+0x1c>
    80002ad8:	2705                	addiw	a4,a4,1
    80002ada:	07c1                	addi	a5,a5,16
    80002adc:	02c70063          	beq	a4,a2,80002afc <remove_page_from_ram+0x38>
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
    80002ae0:	6394                	ld	a3,0(a5)
    80002ae2:	feb69be3          	bne	a3,a1,80002ad8 <remove_page_from_ram+0x14>
    80002ae6:	47d4                	lw	a3,12(a5)
    80002ae8:	dae5                	beqz	a3,80002ad8 <remove_page_from_ram+0x14>
      p->ram_pages[i].va = 0;
    80002aea:	0712                	slli	a4,a4,0x4
    80002aec:	972a                	add	a4,a4,a0
    80002aee:	16073823          	sd	zero,368(a4)
      p->ram_pages[i].used = 0;
    80002af2:	16072e23          	sw	zero,380(a4)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002af6:	16072c23          	sw	zero,376(a4)
      return;
    80002afa:	8082                	ret
{
    80002afc:	1141                	addi	sp,sp,-16
    80002afe:	e406                	sd	ra,8(sp)
    80002b00:	e022                	sd	s0,0(sp)
    80002b02:	0800                	addi	s0,sp,16
  panic("remove_page_from_ram failed");
    80002b04:	00007517          	auipc	a0,0x7
    80002b08:	95450513          	addi	a0,a0,-1708 # 80009458 <digits+0x418>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a1e080e7          	jalr	-1506(ra) # 8000052a <panic>
    80002b14:	8082                	ret

0000000080002b16 <nfua>:
{
    80002b16:	1141                	addi	sp,sp,-16
    80002b18:	e422                	sd	s0,8(sp)
    80002b1a:	0800                	addi	s0,sp,16
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b1c:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002b20:	567d                	li	a2,-1
  int min_index = 0;
    80002b22:	4501                	li	a0,0
  int i = 0;
    80002b24:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b26:	45c1                	li	a1,16
    80002b28:	a029                	j	80002b32 <nfua+0x1c>
    80002b2a:	0741                	addi	a4,a4,16
    80002b2c:	2785                	addiw	a5,a5,1
    80002b2e:	00b78863          	beq	a5,a1,80002b3e <nfua+0x28>
    if(ram_pg->age < min_age){
    80002b32:	4714                	lw	a3,8(a4)
    80002b34:	fec6fbe3          	bgeu	a3,a2,80002b2a <nfua+0x14>
      min_age = ram_pg->age;
    80002b38:	8636                	mv	a2,a3
    if(ram_pg->age < min_age){
    80002b3a:	853e                	mv	a0,a5
    80002b3c:	b7fd                	j	80002b2a <nfua+0x14>
}
    80002b3e:	6422                	ld	s0,8(sp)
    80002b40:	0141                	addi	sp,sp,16
    80002b42:	8082                	ret

0000000080002b44 <count_ones>:
{
    80002b44:	1141                	addi	sp,sp,-16
    80002b46:	e422                	sd	s0,8(sp)
    80002b48:	0800                	addi	s0,sp,16
  while(num > 0){
    80002b4a:	c105                	beqz	a0,80002b6a <count_ones+0x26>
    80002b4c:	87aa                	mv	a5,a0
  int count = 0;
    80002b4e:	4501                	li	a0,0
  while(num > 0){
    80002b50:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002b52:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002b56:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002b58:	0007871b          	sext.w	a4,a5
    80002b5c:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002b60:	fee6e9e3          	bltu	a3,a4,80002b52 <count_ones+0xe>
}
    80002b64:	6422                	ld	s0,8(sp)
    80002b66:	0141                	addi	sp,sp,16
    80002b68:	8082                	ret
  int count = 0;
    80002b6a:	4501                	li	a0,0
    80002b6c:	bfe5                	j	80002b64 <count_ones+0x20>

0000000080002b6e <lapa>:
{
    80002b6e:	715d                	addi	sp,sp,-80
    80002b70:	e486                	sd	ra,72(sp)
    80002b72:	e0a2                	sd	s0,64(sp)
    80002b74:	fc26                	sd	s1,56(sp)
    80002b76:	f84a                	sd	s2,48(sp)
    80002b78:	f44e                	sd	s3,40(sp)
    80002b7a:	f052                	sd	s4,32(sp)
    80002b7c:	ec56                	sd	s5,24(sp)
    80002b7e:	e85a                	sd	s6,16(sp)
    80002b80:	e45e                	sd	s7,8(sp)
    80002b82:	0880                	addi	s0,sp,80
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b84:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002b88:	5afd                	li	s5,-1
  int min_index = 0;
    80002b8a:	4b81                	li	s7,0
  int i = 0;
    80002b8c:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b8e:	4b41                	li	s6,16
    80002b90:	a039                	j	80002b9e <lapa+0x30>
      min_age = ram_pg->age;
    80002b92:	8ad2                	mv	s5,s4
    80002b94:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b96:	09c1                	addi	s3,s3,16
    80002b98:	2905                	addiw	s2,s2,1
    80002b9a:	03690863          	beq	s2,s6,80002bca <lapa+0x5c>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002b9e:	0089aa03          	lw	s4,8(s3)
    80002ba2:	8552                	mv	a0,s4
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	fa0080e7          	jalr	-96(ra) # 80002b44 <count_ones>
    80002bac:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002bae:	8556                	mv	a0,s5
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	f94080e7          	jalr	-108(ra) # 80002b44 <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002bb8:	fca4cde3          	blt	s1,a0,80002b92 <lapa+0x24>
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002bbc:	fca49de3          	bne	s1,a0,80002b96 <lapa+0x28>
    80002bc0:	fd5a7be3          	bgeu	s4,s5,80002b96 <lapa+0x28>
      min_age = ram_pg->age;
    80002bc4:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002bc6:	8bca                	mv	s7,s2
    80002bc8:	b7f9                	j	80002b96 <lapa+0x28>
}
    80002bca:	855e                	mv	a0,s7
    80002bcc:	60a6                	ld	ra,72(sp)
    80002bce:	6406                	ld	s0,64(sp)
    80002bd0:	74e2                	ld	s1,56(sp)
    80002bd2:	7942                	ld	s2,48(sp)
    80002bd4:	79a2                	ld	s3,40(sp)
    80002bd6:	7a02                	ld	s4,32(sp)
    80002bd8:	6ae2                	ld	s5,24(sp)
    80002bda:	6b42                	ld	s6,16(sp)
    80002bdc:	6ba2                	ld	s7,8(sp)
    80002bde:	6161                	addi	sp,sp,80
    80002be0:	8082                	ret

0000000080002be2 <scfifo>:
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	e426                	sd	s1,8(sp)
    80002bea:	e04a                	sd	s2,0(sp)
    80002bec:	1000                	addi	s0,sp,32
    80002bee:	892a                	mv	s2,a0
  int index = p->scfifo_index;
    80002bf0:	37052483          	lw	s1,880(a0)
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
    80002bf4:	01748793          	addi	a5,s1,23
    80002bf8:	0792                	slli	a5,a5,0x4
    80002bfa:	97ca                	add	a5,a5,s2
    80002bfc:	4601                	li	a2,0
    80002bfe:	638c                	ld	a1,0(a5)
    80002c00:	05093503          	ld	a0,80(s2)
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	3a2080e7          	jalr	930(ra) # 80000fa6 <walk>
    80002c0c:	c10d                	beqz	a0,80002c2e <scfifo+0x4c>
    if(*pte & PTE_A){
    80002c0e:	611c                	ld	a5,0(a0)
    80002c10:	0407f713          	andi	a4,a5,64
    80002c14:	c70d                	beqz	a4,80002c3e <scfifo+0x5c>
      *pte = *pte & ~PTE_A;
    80002c16:	fbf7f793          	andi	a5,a5,-65
    80002c1a:	e11c                	sd	a5,0(a0)
      index = (index + 1) % MAX_PSYC_PAGES;
    80002c1c:	2485                	addiw	s1,s1,1
    80002c1e:	41f4d79b          	sraiw	a5,s1,0x1f
    80002c22:	01c7d79b          	srliw	a5,a5,0x1c
    80002c26:	9cbd                	addw	s1,s1,a5
    80002c28:	88bd                	andi	s1,s1,15
    80002c2a:	9c9d                	subw	s1,s1,a5
  while(1){
    80002c2c:	b7e1                	j	80002bf4 <scfifo+0x12>
      panic("scfifo: walk failed");
    80002c2e:	00007517          	auipc	a0,0x7
    80002c32:	84a50513          	addi	a0,a0,-1974 # 80009478 <digits+0x438>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	8f4080e7          	jalr	-1804(ra) # 8000052a <panic>
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
    80002c3e:	0014879b          	addiw	a5,s1,1
    80002c42:	41f7d71b          	sraiw	a4,a5,0x1f
    80002c46:	01c7571b          	srliw	a4,a4,0x1c
    80002c4a:	9fb9                	addw	a5,a5,a4
    80002c4c:	8bbd                	andi	a5,a5,15
    80002c4e:	9f99                	subw	a5,a5,a4
    80002c50:	36f92823          	sw	a5,880(s2)
}
    80002c54:	8526                	mv	a0,s1
    80002c56:	60e2                	ld	ra,24(sp)
    80002c58:	6442                	ld	s0,16(sp)
    80002c5a:	64a2                	ld	s1,8(sp)
    80002c5c:	6902                	ld	s2,0(sp)
    80002c5e:	6105                	addi	sp,sp,32
    80002c60:	8082                	ret

0000000080002c62 <insert_page_to_ram>:
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002c62:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002c64:	37fd                	addiw	a5,a5,-1
    80002c66:	4705                	li	a4,1
    80002c68:	08f77163          	bgeu	a4,a5,80002cea <insert_page_to_ram+0x88>
{
    80002c6c:	7179                	addi	sp,sp,-48
    80002c6e:	f406                	sd	ra,40(sp)
    80002c70:	f022                	sd	s0,32(sp)
    80002c72:	ec26                	sd	s1,24(sp)
    80002c74:	e84a                	sd	s2,16(sp)
    80002c76:	e44e                	sd	s3,8(sp)
    80002c78:	1800                	addi	s0,sp,48
    80002c7a:	84aa                	mv	s1,a0
    80002c7c:	89ae                	mv	s3,a1
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0)
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	e00080e7          	jalr	-512(ra) # 80002a7e <get_unused_ram_index>
    80002c86:	892a                	mv	s2,a0
    80002c88:	02054263          	bltz	a0,80002cac <insert_page_to_ram+0x4a>
  ram_pg->va = va;
    80002c8c:	0912                	slli	s2,s2,0x4
    80002c8e:	94ca                	add	s1,s1,s2
    80002c90:	1734b823          	sd	s3,368(s1)
  ram_pg->used = 1;
    80002c94:	4785                	li	a5,1
    80002c96:	16f4ae23          	sw	a5,380(s1)
    ram_pg->age = 0;
    80002c9a:	1604ac23          	sw	zero,376(s1)
}
    80002c9e:	70a2                	ld	ra,40(sp)
    80002ca0:	7402                	ld	s0,32(sp)
    80002ca2:	64e2                	ld	s1,24(sp)
    80002ca4:	6942                	ld	s2,16(sp)
    80002ca6:	69a2                	ld	s3,8(sp)
    80002ca8:	6145                	addi	sp,sp,48
    80002caa:	8082                	ret
    return scfifo(p);
    80002cac:	8526                	mv	a0,s1
    80002cae:	00000097          	auipc	ra,0x0
    80002cb2:	f34080e7          	jalr	-204(ra) # 80002be2 <scfifo>
    80002cb6:	892a                	mv	s2,a0
    printf("ram_pg_index_to_swap: %d\n",ram_pg_index_to_swap);//REMOVE
    80002cb8:	85aa                	mv	a1,a0
    80002cba:	00006517          	auipc	a0,0x6
    80002cbe:	7d650513          	addi	a0,a0,2006 # 80009490 <digits+0x450>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8b2080e7          	jalr	-1870(ra) # 80000574 <printf>
    printf("pid: %d\n",p->pid);//REMOVE
    80002cca:	588c                	lw	a1,48(s1)
    80002ccc:	00006517          	auipc	a0,0x6
    80002cd0:	7e450513          	addi	a0,a0,2020 # 800094b0 <digits+0x470>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	8a0080e7          	jalr	-1888(ra) # 80000574 <printf>
    swapout(p, ram_pg_index_to_swap);
    80002cdc:	85ca                	mv	a1,s2
    80002cde:	8526                	mv	a0,s1
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	b3c080e7          	jalr	-1220(ra) # 8000281c <swapout>
    unused_ram_pg_index = ram_pg_index_to_swap;
    80002ce8:	b755                	j	80002c8c <insert_page_to_ram+0x2a>
    80002cea:	8082                	ret

0000000080002cec <handle_page_fault>:
{
    80002cec:	7179                	addi	sp,sp,-48
    80002cee:	f406                	sd	ra,40(sp)
    80002cf0:	f022                	sd	s0,32(sp)
    80002cf2:	ec26                	sd	s1,24(sp)
    80002cf4:	e84a                	sd	s2,16(sp)
    80002cf6:	e44e                	sd	s3,8(sp)
    80002cf8:	1800                	addi	s0,sp,48
    80002cfa:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	d08080e7          	jalr	-760(ra) # 80001a04 <myproc>
    80002d04:	84aa                	mv	s1,a0
  if (!(pte = walk(p->pagetable, va, 0))) {
    80002d06:	4601                	li	a2,0
    80002d08:	85ce                	mv	a1,s3
    80002d0a:	6928                	ld	a0,80(a0)
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	29a080e7          	jalr	666(ra) # 80000fa6 <walk>
    80002d14:	c921                	beqz	a0,80002d64 <handle_page_fault+0x78>
  if(*pte & PTE_V){
    80002d16:	611c                	ld	a5,0(a0)
    80002d18:	0017f713          	andi	a4,a5,1
    80002d1c:	ef21                	bnez	a4,80002d74 <handle_page_fault+0x88>
  if(!(*pte & PTE_PG)) {
    80002d1e:	2007f793          	andi	a5,a5,512
    80002d22:	c3ad                	beqz	a5,80002d84 <handle_page_fault+0x98>
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
    80002d24:	8526                	mv	a0,s1
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	d58080e7          	jalr	-680(ra) # 80002a7e <get_unused_ram_index>
    80002d2e:	892a                	mv	s2,a0
    80002d30:	06054263          	bltz	a0,80002d94 <handle_page_fault+0xa8>
  if( (target_idx = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002d34:	75fd                	lui	a1,0xfffff
    80002d36:	00b9f5b3          	and	a1,s3,a1
    80002d3a:	8526                	mv	a0,s1
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	d64080e7          	jalr	-668(ra) # 80002aa0 <get_disk_page_index>
    80002d44:	85aa                	mv	a1,a0
    80002d46:	06054463          	bltz	a0,80002dae <handle_page_fault+0xc2>
  swapin(p, target_idx, unused_ram_pg_index);
    80002d4a:	864a                	mv	a2,s2
    80002d4c:	8526                	mv	a0,s1
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	bea080e7          	jalr	-1046(ra) # 80002938 <swapin>
}
    80002d56:	70a2                	ld	ra,40(sp)
    80002d58:	7402                	ld	s0,32(sp)
    80002d5a:	64e2                	ld	s1,24(sp)
    80002d5c:	6942                	ld	s2,16(sp)
    80002d5e:	69a2                	ld	s3,8(sp)
    80002d60:	6145                	addi	sp,sp,48
    80002d62:	8082                	ret
    panic("handle_page_fault: walk failed");
    80002d64:	00006517          	auipc	a0,0x6
    80002d68:	75c50513          	addi	a0,a0,1884 # 800094c0 <digits+0x480>
    80002d6c:	ffffd097          	auipc	ra,0xffffd
    80002d70:	7be080e7          	jalr	1982(ra) # 8000052a <panic>
    panic("handle_page_fault: invalid pte");
    80002d74:	00006517          	auipc	a0,0x6
    80002d78:	76c50513          	addi	a0,a0,1900 # 800094e0 <digits+0x4a0>
    80002d7c:	ffffd097          	auipc	ra,0xffffd
    80002d80:	7ae080e7          	jalr	1966(ra) # 8000052a <panic>
    panic("handle_page_fault: PTE_PG off");
    80002d84:	00006517          	auipc	a0,0x6
    80002d88:	77c50513          	addi	a0,a0,1916 # 80009500 <digits+0x4c0>
    80002d8c:	ffffd097          	auipc	ra,0xffffd
    80002d90:	79e080e7          	jalr	1950(ra) # 8000052a <panic>
    return scfifo(p);
    80002d94:	8526                	mv	a0,s1
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	e4c080e7          	jalr	-436(ra) # 80002be2 <scfifo>
    80002d9e:	892a                	mv	s2,a0
      swapout(p, ram_pg_index_to_swap); 
    80002da0:	85aa                	mv	a1,a0
    80002da2:	8526                	mv	a0,s1
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	a78080e7          	jalr	-1416(ra) # 8000281c <swapout>
      unused_ram_pg_index = ram_pg_index_to_swap;
    80002dac:	b761                	j	80002d34 <handle_page_fault+0x48>
    panic("handle_page_fault: get_disk_page_index failed");
    80002dae:	00006517          	auipc	a0,0x6
    80002db2:	77250513          	addi	a0,a0,1906 # 80009520 <digits+0x4e0>
    80002db6:	ffffd097          	auipc	ra,0xffffd
    80002dba:	774080e7          	jalr	1908(ra) # 8000052a <panic>

0000000080002dbe <index_page_to_swap>:
{
    80002dbe:	1141                	addi	sp,sp,-16
    80002dc0:	e406                	sd	ra,8(sp)
    80002dc2:	e022                	sd	s0,0(sp)
    80002dc4:	0800                	addi	s0,sp,16
    return scfifo(p);
    80002dc6:	00000097          	auipc	ra,0x0
    80002dca:	e1c080e7          	jalr	-484(ra) # 80002be2 <scfifo>
}
    80002dce:	60a2                	ld	ra,8(sp)
    80002dd0:	6402                	ld	s0,0(sp)
    80002dd2:	0141                	addi	sp,sp,16
    80002dd4:	8082                	ret

0000000080002dd6 <maintain_age>:
void maintain_age(struct proc *p){
    80002dd6:	7179                	addi	sp,sp,-48
    80002dd8:	f406                	sd	ra,40(sp)
    80002dda:	f022                	sd	s0,32(sp)
    80002ddc:	ec26                	sd	s1,24(sp)
    80002dde:	e84a                	sd	s2,16(sp)
    80002de0:	e44e                	sd	s3,8(sp)
    80002de2:	e052                	sd	s4,0(sp)
    80002de4:	1800                	addi	s0,sp,48
    80002de6:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002de8:	17050493          	addi	s1,a0,368
    80002dec:	27050993          	addi	s3,a0,624
      ram_pg->age = ram_pg->age | (1 << 31);
    80002df0:	80000a37          	lui	s4,0x80000
    80002df4:	a821                	j	80002e0c <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002df6:	00006517          	auipc	a0,0x6
    80002dfa:	75a50513          	addi	a0,a0,1882 # 80009550 <digits+0x510>
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	72c080e7          	jalr	1836(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002e06:	04c1                	addi	s1,s1,16
    80002e08:	02998b63          	beq	s3,s1,80002e3e <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002e0c:	4601                	li	a2,0
    80002e0e:	608c                	ld	a1,0(s1)
    80002e10:	05093503          	ld	a0,80(s2)
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	192080e7          	jalr	402(ra) # 80000fa6 <walk>
    80002e1c:	dd69                	beqz	a0,80002df6 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002e1e:	449c                	lw	a5,8(s1)
    80002e20:	0017d79b          	srliw	a5,a5,0x1
    80002e24:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002e26:	6118                	ld	a4,0(a0)
    80002e28:	04077713          	andi	a4,a4,64
    80002e2c:	df69                	beqz	a4,80002e06 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002e2e:	0147e7b3          	or	a5,a5,s4
    80002e32:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002e34:	611c                	ld	a5,0(a0)
    80002e36:	fbf7f793          	andi	a5,a5,-65
    80002e3a:	e11c                	sd	a5,0(a0)
    80002e3c:	b7e9                	j	80002e06 <maintain_age+0x30>
}
    80002e3e:	70a2                	ld	ra,40(sp)
    80002e40:	7402                	ld	s0,32(sp)
    80002e42:	64e2                	ld	s1,24(sp)
    80002e44:	6942                	ld	s2,16(sp)
    80002e46:	69a2                	ld	s3,8(sp)
    80002e48:	6a02                	ld	s4,0(sp)
    80002e4a:	6145                	addi	sp,sp,48
    80002e4c:	8082                	ret

0000000080002e4e <relevant_metadata_proc>:
int relevant_metadata_proc(struct proc *p) {
    80002e4e:	1141                	addi	sp,sp,-16
    80002e50:	e422                	sd	s0,8(sp)
    80002e52:	0800                	addi	s0,sp,16
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002e54:	591c                	lw	a5,48(a0)
    80002e56:	37fd                	addiw	a5,a5,-1
    80002e58:	4505                	li	a0,1
    80002e5a:	00f53533          	sltu	a0,a0,a5
    80002e5e:	6422                	ld	s0,8(sp)
    80002e60:	0141                	addi	sp,sp,16
    80002e62:	8082                	ret

0000000080002e64 <swtch>:
    80002e64:	00153023          	sd	ra,0(a0)
    80002e68:	00253423          	sd	sp,8(a0)
    80002e6c:	e900                	sd	s0,16(a0)
    80002e6e:	ed04                	sd	s1,24(a0)
    80002e70:	03253023          	sd	s2,32(a0)
    80002e74:	03353423          	sd	s3,40(a0)
    80002e78:	03453823          	sd	s4,48(a0)
    80002e7c:	03553c23          	sd	s5,56(a0)
    80002e80:	05653023          	sd	s6,64(a0)
    80002e84:	05753423          	sd	s7,72(a0)
    80002e88:	05853823          	sd	s8,80(a0)
    80002e8c:	05953c23          	sd	s9,88(a0)
    80002e90:	07a53023          	sd	s10,96(a0)
    80002e94:	07b53423          	sd	s11,104(a0)
    80002e98:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80002e9c:	0085b103          	ld	sp,8(a1)
    80002ea0:	6980                	ld	s0,16(a1)
    80002ea2:	6d84                	ld	s1,24(a1)
    80002ea4:	0205b903          	ld	s2,32(a1)
    80002ea8:	0285b983          	ld	s3,40(a1)
    80002eac:	0305ba03          	ld	s4,48(a1)
    80002eb0:	0385ba83          	ld	s5,56(a1)
    80002eb4:	0405bb03          	ld	s6,64(a1)
    80002eb8:	0485bb83          	ld	s7,72(a1)
    80002ebc:	0505bc03          	ld	s8,80(a1)
    80002ec0:	0585bc83          	ld	s9,88(a1)
    80002ec4:	0605bd03          	ld	s10,96(a1)
    80002ec8:	0685bd83          	ld	s11,104(a1)
    80002ecc:	8082                	ret

0000000080002ece <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ece:	1141                	addi	sp,sp,-16
    80002ed0:	e406                	sd	ra,8(sp)
    80002ed2:	e022                	sd	s0,0(sp)
    80002ed4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ed6:	00006597          	auipc	a1,0x6
    80002eda:	6f258593          	addi	a1,a1,1778 # 800095c8 <states.0+0x30>
    80002ede:	0001d517          	auipc	a0,0x1d
    80002ee2:	5f250513          	addi	a0,a0,1522 # 800204d0 <tickslock>
    80002ee6:	ffffe097          	auipc	ra,0xffffe
    80002eea:	c4c080e7          	jalr	-948(ra) # 80000b32 <initlock>
}
    80002eee:	60a2                	ld	ra,8(sp)
    80002ef0:	6402                	ld	s0,0(sp)
    80002ef2:	0141                	addi	sp,sp,16
    80002ef4:	8082                	ret

0000000080002ef6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ef6:	1141                	addi	sp,sp,-16
    80002ef8:	e422                	sd	s0,8(sp)
    80002efa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002efc:	00004797          	auipc	a5,0x4
    80002f00:	ac478793          	addi	a5,a5,-1340 # 800069c0 <kernelvec>
    80002f04:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f08:	6422                	ld	s0,8(sp)
    80002f0a:	0141                	addi	sp,sp,16
    80002f0c:	8082                	ret

0000000080002f0e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f0e:	1141                	addi	sp,sp,-16
    80002f10:	e406                	sd	ra,8(sp)
    80002f12:	e022                	sd	s0,0(sp)
    80002f14:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	aee080e7          	jalr	-1298(ra) # 80001a04 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f24:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002f28:	00005617          	auipc	a2,0x5
    80002f2c:	0d860613          	addi	a2,a2,216 # 80008000 <_trampoline>
    80002f30:	00005697          	auipc	a3,0x5
    80002f34:	0d068693          	addi	a3,a3,208 # 80008000 <_trampoline>
    80002f38:	8e91                	sub	a3,a3,a2
    80002f3a:	040007b7          	lui	a5,0x4000
    80002f3e:	17fd                	addi	a5,a5,-1
    80002f40:	07b2                	slli	a5,a5,0xc
    80002f42:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f44:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f48:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f4a:	180026f3          	csrr	a3,satp
    80002f4e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002f50:	6d38                	ld	a4,88(a0)
    80002f52:	6134                	ld	a3,64(a0)
    80002f54:	6585                	lui	a1,0x1
    80002f56:	96ae                	add	a3,a3,a1
    80002f58:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002f5a:	6d38                	ld	a4,88(a0)
    80002f5c:	00000697          	auipc	a3,0x0
    80002f60:	13868693          	addi	a3,a3,312 # 80003094 <usertrap>
    80002f64:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002f66:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f68:	8692                	mv	a3,tp
    80002f6a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f6c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002f70:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002f74:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f78:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002f7c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f7e:	6f18                	ld	a4,24(a4)
    80002f80:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f84:	692c                	ld	a1,80(a0)
    80002f86:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002f88:	00005717          	auipc	a4,0x5
    80002f8c:	10870713          	addi	a4,a4,264 # 80008090 <userret>
    80002f90:	8f11                	sub	a4,a4,a2
    80002f92:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f94:	577d                	li	a4,-1
    80002f96:	177e                	slli	a4,a4,0x3f
    80002f98:	8dd9                	or	a1,a1,a4
    80002f9a:	02000537          	lui	a0,0x2000
    80002f9e:	157d                	addi	a0,a0,-1
    80002fa0:	0536                	slli	a0,a0,0xd
    80002fa2:	9782                	jalr	a5
}
    80002fa4:	60a2                	ld	ra,8(sp)
    80002fa6:	6402                	ld	s0,0(sp)
    80002fa8:	0141                	addi	sp,sp,16
    80002faa:	8082                	ret

0000000080002fac <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002fac:	1101                	addi	sp,sp,-32
    80002fae:	ec06                	sd	ra,24(sp)
    80002fb0:	e822                	sd	s0,16(sp)
    80002fb2:	e426                	sd	s1,8(sp)
    80002fb4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002fb6:	0001d497          	auipc	s1,0x1d
    80002fba:	51a48493          	addi	s1,s1,1306 # 800204d0 <tickslock>
    80002fbe:	8526                	mv	a0,s1
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	c02080e7          	jalr	-1022(ra) # 80000bc2 <acquire>
  ticks++;
    80002fc8:	00007517          	auipc	a0,0x7
    80002fcc:	06850513          	addi	a0,a0,104 # 8000a030 <ticks>
    80002fd0:	411c                	lw	a5,0(a0)
    80002fd2:	2785                	addiw	a5,a5,1
    80002fd4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	1dc080e7          	jalr	476(ra) # 800021b2 <wakeup>
  release(&tickslock);
    80002fde:	8526                	mv	a0,s1
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	c96080e7          	jalr	-874(ra) # 80000c76 <release>
}
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	64a2                	ld	s1,8(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret

0000000080002ff2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ff2:	1101                	addi	sp,sp,-32
    80002ff4:	ec06                	sd	ra,24(sp)
    80002ff6:	e822                	sd	s0,16(sp)
    80002ff8:	e426                	sd	s1,8(sp)
    80002ffa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ffc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003000:	00074d63          	bltz	a4,8000301a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003004:	57fd                	li	a5,-1
    80003006:	17fe                	slli	a5,a5,0x3f
    80003008:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000300a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000300c:	06f70363          	beq	a4,a5,80003072 <devintr+0x80>
  }
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6105                	addi	sp,sp,32
    80003018:	8082                	ret
     (scause & 0xff) == 9){
    8000301a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000301e:	46a5                	li	a3,9
    80003020:	fed792e3          	bne	a5,a3,80003004 <devintr+0x12>
    int irq = plic_claim();
    80003024:	00004097          	auipc	ra,0x4
    80003028:	aa4080e7          	jalr	-1372(ra) # 80006ac8 <plic_claim>
    8000302c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000302e:	47a9                	li	a5,10
    80003030:	02f50763          	beq	a0,a5,8000305e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003034:	4785                	li	a5,1
    80003036:	02f50963          	beq	a0,a5,80003068 <devintr+0x76>
    return 1;
    8000303a:	4505                	li	a0,1
    } else if(irq){
    8000303c:	d8f1                	beqz	s1,80003010 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000303e:	85a6                	mv	a1,s1
    80003040:	00006517          	auipc	a0,0x6
    80003044:	59050513          	addi	a0,a0,1424 # 800095d0 <states.0+0x38>
    80003048:	ffffd097          	auipc	ra,0xffffd
    8000304c:	52c080e7          	jalr	1324(ra) # 80000574 <printf>
      plic_complete(irq);
    80003050:	8526                	mv	a0,s1
    80003052:	00004097          	auipc	ra,0x4
    80003056:	a9a080e7          	jalr	-1382(ra) # 80006aec <plic_complete>
    return 1;
    8000305a:	4505                	li	a0,1
    8000305c:	bf55                	j	80003010 <devintr+0x1e>
      uartintr();
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	928080e7          	jalr	-1752(ra) # 80000986 <uartintr>
    80003066:	b7ed                	j	80003050 <devintr+0x5e>
      virtio_disk_intr();
    80003068:	00004097          	auipc	ra,0x4
    8000306c:	f16080e7          	jalr	-234(ra) # 80006f7e <virtio_disk_intr>
    80003070:	b7c5                	j	80003050 <devintr+0x5e>
    if(cpuid() == 0){
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	966080e7          	jalr	-1690(ra) # 800019d8 <cpuid>
    8000307a:	c901                	beqz	a0,8000308a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000307c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003080:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003082:	14479073          	csrw	sip,a5
    return 2;
    80003086:	4509                	li	a0,2
    80003088:	b761                	j	80003010 <devintr+0x1e>
      clockintr();
    8000308a:	00000097          	auipc	ra,0x0
    8000308e:	f22080e7          	jalr	-222(ra) # 80002fac <clockintr>
    80003092:	b7ed                	j	8000307c <devintr+0x8a>

0000000080003094 <usertrap>:
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	e426                	sd	s1,8(sp)
    8000309c:	e04a                	sd	s2,0(sp)
    8000309e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030a0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800030a4:	1007f793          	andi	a5,a5,256
    800030a8:	e3ad                	bnez	a5,8000310a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030aa:	00004797          	auipc	a5,0x4
    800030ae:	91678793          	addi	a5,a5,-1770 # 800069c0 <kernelvec>
    800030b2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800030b6:	fffff097          	auipc	ra,0xfffff
    800030ba:	94e080e7          	jalr	-1714(ra) # 80001a04 <myproc>
    800030be:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800030c0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030c2:	14102773          	csrr	a4,sepc
    800030c6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030c8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800030cc:	47a1                	li	a5,8
    800030ce:	04f71c63          	bne	a4,a5,80003126 <usertrap+0x92>
    if(p->killed)
    800030d2:	551c                	lw	a5,40(a0)
    800030d4:	e3b9                	bnez	a5,8000311a <usertrap+0x86>
    p->trapframe->epc += 4;
    800030d6:	6cb8                	ld	a4,88(s1)
    800030d8:	6f1c                	ld	a5,24(a4)
    800030da:	0791                	addi	a5,a5,4
    800030dc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030de:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800030e2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030e6:	10079073          	csrw	sstatus,a5
    syscall();
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	318080e7          	jalr	792(ra) # 80003402 <syscall>
  if(p->killed)
    800030f2:	549c                	lw	a5,40(s1)
    800030f4:	ebc5                	bnez	a5,800031a4 <usertrap+0x110>
  usertrapret();
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	e18080e7          	jalr	-488(ra) # 80002f0e <usertrapret>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6902                	ld	s2,0(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret
    panic("usertrap: not from user mode");
    8000310a:	00006517          	auipc	a0,0x6
    8000310e:	4e650513          	addi	a0,a0,1254 # 800095f0 <states.0+0x58>
    80003112:	ffffd097          	auipc	ra,0xffffd
    80003116:	418080e7          	jalr	1048(ra) # 8000052a <panic>
      exit(-1);
    8000311a:	557d                	li	a0,-1
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	5e4080e7          	jalr	1508(ra) # 80002700 <exit>
    80003124:	bf4d                	j	800030d6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003126:	00000097          	auipc	ra,0x0
    8000312a:	ecc080e7          	jalr	-308(ra) # 80002ff2 <devintr>
    8000312e:	892a                	mv	s2,a0
    80003130:	c501                	beqz	a0,80003138 <usertrap+0xa4>
  if(p->killed)
    80003132:	549c                	lw	a5,40(s1)
    80003134:	cfb5                	beqz	a5,800031b0 <usertrap+0x11c>
    80003136:	a885                	j	800031a6 <usertrap+0x112>
  } else if (relevant_metadata_proc(p) && 
    80003138:	8526                	mv	a0,s1
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	d14080e7          	jalr	-748(ra) # 80002e4e <relevant_metadata_proc>
    80003142:	c105                	beqz	a0,80003162 <usertrap+0xce>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003144:	14202773          	csrr	a4,scause
    80003148:	47b1                	li	a5,12
    8000314a:	04f70663          	beq	a4,a5,80003196 <usertrap+0x102>
    8000314e:	14202773          	csrr	a4,scause
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    80003152:	47b5                	li	a5,13
    80003154:	04f70163          	beq	a4,a5,80003196 <usertrap+0x102>
    80003158:	14202773          	csrr	a4,scause
    8000315c:	47bd                	li	a5,15
    8000315e:	02f70c63          	beq	a4,a5,80003196 <usertrap+0x102>
    80003162:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003166:	5890                	lw	a2,48(s1)
    80003168:	00006517          	auipc	a0,0x6
    8000316c:	4a850513          	addi	a0,a0,1192 # 80009610 <states.0+0x78>
    80003170:	ffffd097          	auipc	ra,0xffffd
    80003174:	404080e7          	jalr	1028(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003178:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000317c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003180:	00006517          	auipc	a0,0x6
    80003184:	4c050513          	addi	a0,a0,1216 # 80009640 <states.0+0xa8>
    80003188:	ffffd097          	auipc	ra,0xffffd
    8000318c:	3ec080e7          	jalr	1004(ra) # 80000574 <printf>
    p->killed = 1;
    80003190:	4785                	li	a5,1
    80003192:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80003194:	a809                	j	800031a6 <usertrap+0x112>
    80003196:	14302573          	csrr	a0,stval
      handle_page_fault(va);    
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	b52080e7          	jalr	-1198(ra) # 80002cec <handle_page_fault>
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    800031a2:	bf81                	j	800030f2 <usertrap+0x5e>
  if(p->killed)
    800031a4:	4901                	li	s2,0
    exit(-1);
    800031a6:	557d                	li	a0,-1
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	558080e7          	jalr	1368(ra) # 80002700 <exit>
  if(which_dev == 2)
    800031b0:	4789                	li	a5,2
    800031b2:	f4f912e3          	bne	s2,a5,800030f6 <usertrap+0x62>
    yield();
    800031b6:	fffff097          	auipc	ra,0xfffff
    800031ba:	e34080e7          	jalr	-460(ra) # 80001fea <yield>
    800031be:	bf25                	j	800030f6 <usertrap+0x62>

00000000800031c0 <kerneltrap>:
{
    800031c0:	7179                	addi	sp,sp,-48
    800031c2:	f406                	sd	ra,40(sp)
    800031c4:	f022                	sd	s0,32(sp)
    800031c6:	ec26                	sd	s1,24(sp)
    800031c8:	e84a                	sd	s2,16(sp)
    800031ca:	e44e                	sd	s3,8(sp)
    800031cc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031ce:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031d2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031d6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800031da:	1004f793          	andi	a5,s1,256
    800031de:	cb85                	beqz	a5,8000320e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031e0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031e4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800031e6:	ef85                	bnez	a5,8000321e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	e0a080e7          	jalr	-502(ra) # 80002ff2 <devintr>
    800031f0:	cd1d                	beqz	a0,8000322e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031f2:	4789                	li	a5,2
    800031f4:	06f50a63          	beq	a0,a5,80003268 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031f8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031fc:	10049073          	csrw	sstatus,s1
}
    80003200:	70a2                	ld	ra,40(sp)
    80003202:	7402                	ld	s0,32(sp)
    80003204:	64e2                	ld	s1,24(sp)
    80003206:	6942                	ld	s2,16(sp)
    80003208:	69a2                	ld	s3,8(sp)
    8000320a:	6145                	addi	sp,sp,48
    8000320c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000320e:	00006517          	auipc	a0,0x6
    80003212:	45250513          	addi	a0,a0,1106 # 80009660 <states.0+0xc8>
    80003216:	ffffd097          	auipc	ra,0xffffd
    8000321a:	314080e7          	jalr	788(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    8000321e:	00006517          	auipc	a0,0x6
    80003222:	46a50513          	addi	a0,a0,1130 # 80009688 <states.0+0xf0>
    80003226:	ffffd097          	auipc	ra,0xffffd
    8000322a:	304080e7          	jalr	772(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    8000322e:	85ce                	mv	a1,s3
    80003230:	00006517          	auipc	a0,0x6
    80003234:	47850513          	addi	a0,a0,1144 # 800096a8 <states.0+0x110>
    80003238:	ffffd097          	auipc	ra,0xffffd
    8000323c:	33c080e7          	jalr	828(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003240:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003244:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003248:	00006517          	auipc	a0,0x6
    8000324c:	47050513          	addi	a0,a0,1136 # 800096b8 <states.0+0x120>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	324080e7          	jalr	804(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003258:	00006517          	auipc	a0,0x6
    8000325c:	47850513          	addi	a0,a0,1144 # 800096d0 <states.0+0x138>
    80003260:	ffffd097          	auipc	ra,0xffffd
    80003264:	2ca080e7          	jalr	714(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	79c080e7          	jalr	1948(ra) # 80001a04 <myproc>
    80003270:	d541                	beqz	a0,800031f8 <kerneltrap+0x38>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	792080e7          	jalr	1938(ra) # 80001a04 <myproc>
    8000327a:	4d18                	lw	a4,24(a0)
    8000327c:	4791                	li	a5,4
    8000327e:	f6f71de3          	bne	a4,a5,800031f8 <kerneltrap+0x38>
    yield();
    80003282:	fffff097          	auipc	ra,0xfffff
    80003286:	d68080e7          	jalr	-664(ra) # 80001fea <yield>
    8000328a:	b7bd                	j	800031f8 <kerneltrap+0x38>

000000008000328c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000328c:	1101                	addi	sp,sp,-32
    8000328e:	ec06                	sd	ra,24(sp)
    80003290:	e822                	sd	s0,16(sp)
    80003292:	e426                	sd	s1,8(sp)
    80003294:	1000                	addi	s0,sp,32
    80003296:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	76c080e7          	jalr	1900(ra) # 80001a04 <myproc>
  switch (n) {
    800032a0:	4795                	li	a5,5
    800032a2:	0497e163          	bltu	a5,s1,800032e4 <argraw+0x58>
    800032a6:	048a                	slli	s1,s1,0x2
    800032a8:	00006717          	auipc	a4,0x6
    800032ac:	46070713          	addi	a4,a4,1120 # 80009708 <states.0+0x170>
    800032b0:	94ba                	add	s1,s1,a4
    800032b2:	409c                	lw	a5,0(s1)
    800032b4:	97ba                	add	a5,a5,a4
    800032b6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800032b8:	6d3c                	ld	a5,88(a0)
    800032ba:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	64a2                	ld	s1,8(sp)
    800032c2:	6105                	addi	sp,sp,32
    800032c4:	8082                	ret
    return p->trapframe->a1;
    800032c6:	6d3c                	ld	a5,88(a0)
    800032c8:	7fa8                	ld	a0,120(a5)
    800032ca:	bfcd                	j	800032bc <argraw+0x30>
    return p->trapframe->a2;
    800032cc:	6d3c                	ld	a5,88(a0)
    800032ce:	63c8                	ld	a0,128(a5)
    800032d0:	b7f5                	j	800032bc <argraw+0x30>
    return p->trapframe->a3;
    800032d2:	6d3c                	ld	a5,88(a0)
    800032d4:	67c8                	ld	a0,136(a5)
    800032d6:	b7dd                	j	800032bc <argraw+0x30>
    return p->trapframe->a4;
    800032d8:	6d3c                	ld	a5,88(a0)
    800032da:	6bc8                	ld	a0,144(a5)
    800032dc:	b7c5                	j	800032bc <argraw+0x30>
    return p->trapframe->a5;
    800032de:	6d3c                	ld	a5,88(a0)
    800032e0:	6fc8                	ld	a0,152(a5)
    800032e2:	bfe9                	j	800032bc <argraw+0x30>
  panic("argraw");
    800032e4:	00006517          	auipc	a0,0x6
    800032e8:	3fc50513          	addi	a0,a0,1020 # 800096e0 <states.0+0x148>
    800032ec:	ffffd097          	auipc	ra,0xffffd
    800032f0:	23e080e7          	jalr	574(ra) # 8000052a <panic>

00000000800032f4 <fetchaddr>:
{
    800032f4:	1101                	addi	sp,sp,-32
    800032f6:	ec06                	sd	ra,24(sp)
    800032f8:	e822                	sd	s0,16(sp)
    800032fa:	e426                	sd	s1,8(sp)
    800032fc:	e04a                	sd	s2,0(sp)
    800032fe:	1000                	addi	s0,sp,32
    80003300:	84aa                	mv	s1,a0
    80003302:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	700080e7          	jalr	1792(ra) # 80001a04 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000330c:	653c                	ld	a5,72(a0)
    8000330e:	02f4f863          	bgeu	s1,a5,8000333e <fetchaddr+0x4a>
    80003312:	00848713          	addi	a4,s1,8
    80003316:	02e7e663          	bltu	a5,a4,80003342 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000331a:	46a1                	li	a3,8
    8000331c:	8626                	mv	a2,s1
    8000331e:	85ca                	mv	a1,s2
    80003320:	6928                	ld	a0,80(a0)
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	42e080e7          	jalr	1070(ra) # 80001750 <copyin>
    8000332a:	00a03533          	snez	a0,a0
    8000332e:	40a00533          	neg	a0,a0
}
    80003332:	60e2                	ld	ra,24(sp)
    80003334:	6442                	ld	s0,16(sp)
    80003336:	64a2                	ld	s1,8(sp)
    80003338:	6902                	ld	s2,0(sp)
    8000333a:	6105                	addi	sp,sp,32
    8000333c:	8082                	ret
    return -1;
    8000333e:	557d                	li	a0,-1
    80003340:	bfcd                	j	80003332 <fetchaddr+0x3e>
    80003342:	557d                	li	a0,-1
    80003344:	b7fd                	j	80003332 <fetchaddr+0x3e>

0000000080003346 <fetchstr>:
{
    80003346:	7179                	addi	sp,sp,-48
    80003348:	f406                	sd	ra,40(sp)
    8000334a:	f022                	sd	s0,32(sp)
    8000334c:	ec26                	sd	s1,24(sp)
    8000334e:	e84a                	sd	s2,16(sp)
    80003350:	e44e                	sd	s3,8(sp)
    80003352:	1800                	addi	s0,sp,48
    80003354:	892a                	mv	s2,a0
    80003356:	84ae                	mv	s1,a1
    80003358:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	6aa080e7          	jalr	1706(ra) # 80001a04 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003362:	86ce                	mv	a3,s3
    80003364:	864a                	mv	a2,s2
    80003366:	85a6                	mv	a1,s1
    80003368:	6928                	ld	a0,80(a0)
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	474080e7          	jalr	1140(ra) # 800017de <copyinstr>
  if(err < 0)
    80003372:	00054763          	bltz	a0,80003380 <fetchstr+0x3a>
  return strlen(buf);
    80003376:	8526                	mv	a0,s1
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	aca080e7          	jalr	-1334(ra) # 80000e42 <strlen>
}
    80003380:	70a2                	ld	ra,40(sp)
    80003382:	7402                	ld	s0,32(sp)
    80003384:	64e2                	ld	s1,24(sp)
    80003386:	6942                	ld	s2,16(sp)
    80003388:	69a2                	ld	s3,8(sp)
    8000338a:	6145                	addi	sp,sp,48
    8000338c:	8082                	ret

000000008000338e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000338e:	1101                	addi	sp,sp,-32
    80003390:	ec06                	sd	ra,24(sp)
    80003392:	e822                	sd	s0,16(sp)
    80003394:	e426                	sd	s1,8(sp)
    80003396:	1000                	addi	s0,sp,32
    80003398:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	ef2080e7          	jalr	-270(ra) # 8000328c <argraw>
    800033a2:	c088                	sw	a0,0(s1)
  return 0;
}
    800033a4:	4501                	li	a0,0
    800033a6:	60e2                	ld	ra,24(sp)
    800033a8:	6442                	ld	s0,16(sp)
    800033aa:	64a2                	ld	s1,8(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret

00000000800033b0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800033b0:	1101                	addi	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	e426                	sd	s1,8(sp)
    800033b8:	1000                	addi	s0,sp,32
    800033ba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	ed0080e7          	jalr	-304(ra) # 8000328c <argraw>
    800033c4:	e088                	sd	a0,0(s1)
  return 0;
}
    800033c6:	4501                	li	a0,0
    800033c8:	60e2                	ld	ra,24(sp)
    800033ca:	6442                	ld	s0,16(sp)
    800033cc:	64a2                	ld	s1,8(sp)
    800033ce:	6105                	addi	sp,sp,32
    800033d0:	8082                	ret

00000000800033d2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033d2:	1101                	addi	sp,sp,-32
    800033d4:	ec06                	sd	ra,24(sp)
    800033d6:	e822                	sd	s0,16(sp)
    800033d8:	e426                	sd	s1,8(sp)
    800033da:	e04a                	sd	s2,0(sp)
    800033dc:	1000                	addi	s0,sp,32
    800033de:	84ae                	mv	s1,a1
    800033e0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	eaa080e7          	jalr	-342(ra) # 8000328c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800033ea:	864a                	mv	a2,s2
    800033ec:	85a6                	mv	a1,s1
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	f58080e7          	jalr	-168(ra) # 80003346 <fetchstr>
}
    800033f6:	60e2                	ld	ra,24(sp)
    800033f8:	6442                	ld	s0,16(sp)
    800033fa:	64a2                	ld	s1,8(sp)
    800033fc:	6902                	ld	s2,0(sp)
    800033fe:	6105                	addi	sp,sp,32
    80003400:	8082                	ret

0000000080003402 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003402:	1101                	addi	sp,sp,-32
    80003404:	ec06                	sd	ra,24(sp)
    80003406:	e822                	sd	s0,16(sp)
    80003408:	e426                	sd	s1,8(sp)
    8000340a:	e04a                	sd	s2,0(sp)
    8000340c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000340e:	ffffe097          	auipc	ra,0xffffe
    80003412:	5f6080e7          	jalr	1526(ra) # 80001a04 <myproc>
    80003416:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003418:	05853903          	ld	s2,88(a0)
    8000341c:	0a893783          	ld	a5,168(s2)
    80003420:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003424:	37fd                	addiw	a5,a5,-1
    80003426:	4751                	li	a4,20
    80003428:	00f76f63          	bltu	a4,a5,80003446 <syscall+0x44>
    8000342c:	00369713          	slli	a4,a3,0x3
    80003430:	00006797          	auipc	a5,0x6
    80003434:	2f078793          	addi	a5,a5,752 # 80009720 <syscalls>
    80003438:	97ba                	add	a5,a5,a4
    8000343a:	639c                	ld	a5,0(a5)
    8000343c:	c789                	beqz	a5,80003446 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000343e:	9782                	jalr	a5
    80003440:	06a93823          	sd	a0,112(s2)
    80003444:	a839                	j	80003462 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003446:	15848613          	addi	a2,s1,344
    8000344a:	588c                	lw	a1,48(s1)
    8000344c:	00006517          	auipc	a0,0x6
    80003450:	29c50513          	addi	a0,a0,668 # 800096e8 <states.0+0x150>
    80003454:	ffffd097          	auipc	ra,0xffffd
    80003458:	120080e7          	jalr	288(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000345c:	6cbc                	ld	a5,88(s1)
    8000345e:	577d                	li	a4,-1
    80003460:	fbb8                	sd	a4,112(a5)
  }
}
    80003462:	60e2                	ld	ra,24(sp)
    80003464:	6442                	ld	s0,16(sp)
    80003466:	64a2                	ld	s1,8(sp)
    80003468:	6902                	ld	s2,0(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret

000000008000346e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000346e:	1101                	addi	sp,sp,-32
    80003470:	ec06                	sd	ra,24(sp)
    80003472:	e822                	sd	s0,16(sp)
    80003474:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003476:	fec40593          	addi	a1,s0,-20
    8000347a:	4501                	li	a0,0
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	f12080e7          	jalr	-238(ra) # 8000338e <argint>
    return -1;
    80003484:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003486:	00054963          	bltz	a0,80003498 <sys_exit+0x2a>
  exit(n);
    8000348a:	fec42503          	lw	a0,-20(s0)
    8000348e:	fffff097          	auipc	ra,0xfffff
    80003492:	272080e7          	jalr	626(ra) # 80002700 <exit>
  return 0;  // not reached
    80003496:	4781                	li	a5,0
}
    80003498:	853e                	mv	a0,a5
    8000349a:	60e2                	ld	ra,24(sp)
    8000349c:	6442                	ld	s0,16(sp)
    8000349e:	6105                	addi	sp,sp,32
    800034a0:	8082                	ret

00000000800034a2 <sys_getpid>:

uint64
sys_getpid(void)
{
    800034a2:	1141                	addi	sp,sp,-16
    800034a4:	e406                	sd	ra,8(sp)
    800034a6:	e022                	sd	s0,0(sp)
    800034a8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034aa:	ffffe097          	auipc	ra,0xffffe
    800034ae:	55a080e7          	jalr	1370(ra) # 80001a04 <myproc>
}
    800034b2:	5908                	lw	a0,48(a0)
    800034b4:	60a2                	ld	ra,8(sp)
    800034b6:	6402                	ld	s0,0(sp)
    800034b8:	0141                	addi	sp,sp,16
    800034ba:	8082                	ret

00000000800034bc <sys_fork>:

uint64
sys_fork(void)
{
    800034bc:	1141                	addi	sp,sp,-16
    800034be:	e406                	sd	ra,8(sp)
    800034c0:	e022                	sd	s0,0(sp)
    800034c2:	0800                	addi	s0,sp,16
  return fork();
    800034c4:	fffff097          	auipc	ra,0xfffff
    800034c8:	048080e7          	jalr	72(ra) # 8000250c <fork>
}
    800034cc:	60a2                	ld	ra,8(sp)
    800034ce:	6402                	ld	s0,0(sp)
    800034d0:	0141                	addi	sp,sp,16
    800034d2:	8082                	ret

00000000800034d4 <sys_wait>:

uint64
sys_wait(void)
{
    800034d4:	1101                	addi	sp,sp,-32
    800034d6:	ec06                	sd	ra,24(sp)
    800034d8:	e822                	sd	s0,16(sp)
    800034da:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800034dc:	fe840593          	addi	a1,s0,-24
    800034e0:	4501                	li	a0,0
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	ece080e7          	jalr	-306(ra) # 800033b0 <argaddr>
    800034ea:	87aa                	mv	a5,a0
    return -1;
    800034ec:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800034ee:	0007c863          	bltz	a5,800034fe <sys_wait+0x2a>
  return wait(p);
    800034f2:	fe843503          	ld	a0,-24(s0)
    800034f6:	fffff097          	auipc	ra,0xfffff
    800034fa:	b94080e7          	jalr	-1132(ra) # 8000208a <wait>
}
    800034fe:	60e2                	ld	ra,24(sp)
    80003500:	6442                	ld	s0,16(sp)
    80003502:	6105                	addi	sp,sp,32
    80003504:	8082                	ret

0000000080003506 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003506:	7179                	addi	sp,sp,-48
    80003508:	f406                	sd	ra,40(sp)
    8000350a:	f022                	sd	s0,32(sp)
    8000350c:	ec26                	sd	s1,24(sp)
    8000350e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003510:	fdc40593          	addi	a1,s0,-36
    80003514:	4501                	li	a0,0
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	e78080e7          	jalr	-392(ra) # 8000338e <argint>
    return -1;
    8000351e:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003520:	00054f63          	bltz	a0,8000353e <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003524:	ffffe097          	auipc	ra,0xffffe
    80003528:	4e0080e7          	jalr	1248(ra) # 80001a04 <myproc>
    8000352c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000352e:	fdc42503          	lw	a0,-36(s0)
    80003532:	fffff097          	auipc	ra,0xfffff
    80003536:	82c080e7          	jalr	-2004(ra) # 80001d5e <growproc>
    8000353a:	00054863          	bltz	a0,8000354a <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000353e:	8526                	mv	a0,s1
    80003540:	70a2                	ld	ra,40(sp)
    80003542:	7402                	ld	s0,32(sp)
    80003544:	64e2                	ld	s1,24(sp)
    80003546:	6145                	addi	sp,sp,48
    80003548:	8082                	ret
    return -1;
    8000354a:	54fd                	li	s1,-1
    8000354c:	bfcd                	j	8000353e <sys_sbrk+0x38>

000000008000354e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000354e:	7139                	addi	sp,sp,-64
    80003550:	fc06                	sd	ra,56(sp)
    80003552:	f822                	sd	s0,48(sp)
    80003554:	f426                	sd	s1,40(sp)
    80003556:	f04a                	sd	s2,32(sp)
    80003558:	ec4e                	sd	s3,24(sp)
    8000355a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000355c:	fcc40593          	addi	a1,s0,-52
    80003560:	4501                	li	a0,0
    80003562:	00000097          	auipc	ra,0x0
    80003566:	e2c080e7          	jalr	-468(ra) # 8000338e <argint>
    return -1;
    8000356a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000356c:	06054563          	bltz	a0,800035d6 <sys_sleep+0x88>
  acquire(&tickslock);
    80003570:	0001d517          	auipc	a0,0x1d
    80003574:	f6050513          	addi	a0,a0,-160 # 800204d0 <tickslock>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	64a080e7          	jalr	1610(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003580:	00007917          	auipc	s2,0x7
    80003584:	ab092903          	lw	s2,-1360(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    80003588:	fcc42783          	lw	a5,-52(s0)
    8000358c:	cf85                	beqz	a5,800035c4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000358e:	0001d997          	auipc	s3,0x1d
    80003592:	f4298993          	addi	s3,s3,-190 # 800204d0 <tickslock>
    80003596:	00007497          	auipc	s1,0x7
    8000359a:	a9a48493          	addi	s1,s1,-1382 # 8000a030 <ticks>
    if(myproc()->killed){
    8000359e:	ffffe097          	auipc	ra,0xffffe
    800035a2:	466080e7          	jalr	1126(ra) # 80001a04 <myproc>
    800035a6:	551c                	lw	a5,40(a0)
    800035a8:	ef9d                	bnez	a5,800035e6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800035aa:	85ce                	mv	a1,s3
    800035ac:	8526                	mv	a0,s1
    800035ae:	fffff097          	auipc	ra,0xfffff
    800035b2:	a78080e7          	jalr	-1416(ra) # 80002026 <sleep>
  while(ticks - ticks0 < n){
    800035b6:	409c                	lw	a5,0(s1)
    800035b8:	412787bb          	subw	a5,a5,s2
    800035bc:	fcc42703          	lw	a4,-52(s0)
    800035c0:	fce7efe3          	bltu	a5,a4,8000359e <sys_sleep+0x50>
  }
  release(&tickslock);
    800035c4:	0001d517          	auipc	a0,0x1d
    800035c8:	f0c50513          	addi	a0,a0,-244 # 800204d0 <tickslock>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	6aa080e7          	jalr	1706(ra) # 80000c76 <release>
  return 0;
    800035d4:	4781                	li	a5,0
}
    800035d6:	853e                	mv	a0,a5
    800035d8:	70e2                	ld	ra,56(sp)
    800035da:	7442                	ld	s0,48(sp)
    800035dc:	74a2                	ld	s1,40(sp)
    800035de:	7902                	ld	s2,32(sp)
    800035e0:	69e2                	ld	s3,24(sp)
    800035e2:	6121                	addi	sp,sp,64
    800035e4:	8082                	ret
      release(&tickslock);
    800035e6:	0001d517          	auipc	a0,0x1d
    800035ea:	eea50513          	addi	a0,a0,-278 # 800204d0 <tickslock>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	688080e7          	jalr	1672(ra) # 80000c76 <release>
      return -1;
    800035f6:	57fd                	li	a5,-1
    800035f8:	bff9                	j	800035d6 <sys_sleep+0x88>

00000000800035fa <sys_kill>:

uint64
sys_kill(void)
{
    800035fa:	1101                	addi	sp,sp,-32
    800035fc:	ec06                	sd	ra,24(sp)
    800035fe:	e822                	sd	s0,16(sp)
    80003600:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003602:	fec40593          	addi	a1,s0,-20
    80003606:	4501                	li	a0,0
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	d86080e7          	jalr	-634(ra) # 8000338e <argint>
    80003610:	87aa                	mv	a5,a0
    return -1;
    80003612:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003614:	0007c863          	bltz	a5,80003624 <sys_kill+0x2a>
  return kill(pid);
    80003618:	fec42503          	lw	a0,-20(s0)
    8000361c:	fffff097          	auipc	ra,0xfffff
    80003620:	c66080e7          	jalr	-922(ra) # 80002282 <kill>
}
    80003624:	60e2                	ld	ra,24(sp)
    80003626:	6442                	ld	s0,16(sp)
    80003628:	6105                	addi	sp,sp,32
    8000362a:	8082                	ret

000000008000362c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000362c:	1101                	addi	sp,sp,-32
    8000362e:	ec06                	sd	ra,24(sp)
    80003630:	e822                	sd	s0,16(sp)
    80003632:	e426                	sd	s1,8(sp)
    80003634:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003636:	0001d517          	auipc	a0,0x1d
    8000363a:	e9a50513          	addi	a0,a0,-358 # 800204d0 <tickslock>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	584080e7          	jalr	1412(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003646:	00007497          	auipc	s1,0x7
    8000364a:	9ea4a483          	lw	s1,-1558(s1) # 8000a030 <ticks>
  release(&tickslock);
    8000364e:	0001d517          	auipc	a0,0x1d
    80003652:	e8250513          	addi	a0,a0,-382 # 800204d0 <tickslock>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	620080e7          	jalr	1568(ra) # 80000c76 <release>
  return xticks;
}
    8000365e:	02049513          	slli	a0,s1,0x20
    80003662:	9101                	srli	a0,a0,0x20
    80003664:	60e2                	ld	ra,24(sp)
    80003666:	6442                	ld	s0,16(sp)
    80003668:	64a2                	ld	s1,8(sp)
    8000366a:	6105                	addi	sp,sp,32
    8000366c:	8082                	ret

000000008000366e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000366e:	7179                	addi	sp,sp,-48
    80003670:	f406                	sd	ra,40(sp)
    80003672:	f022                	sd	s0,32(sp)
    80003674:	ec26                	sd	s1,24(sp)
    80003676:	e84a                	sd	s2,16(sp)
    80003678:	e44e                	sd	s3,8(sp)
    8000367a:	e052                	sd	s4,0(sp)
    8000367c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000367e:	00006597          	auipc	a1,0x6
    80003682:	15258593          	addi	a1,a1,338 # 800097d0 <syscalls+0xb0>
    80003686:	0001d517          	auipc	a0,0x1d
    8000368a:	e6250513          	addi	a0,a0,-414 # 800204e8 <bcache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	4a4080e7          	jalr	1188(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003696:	00025797          	auipc	a5,0x25
    8000369a:	e5278793          	addi	a5,a5,-430 # 800284e8 <bcache+0x8000>
    8000369e:	00025717          	auipc	a4,0x25
    800036a2:	0b270713          	addi	a4,a4,178 # 80028750 <bcache+0x8268>
    800036a6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800036aa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036ae:	0001d497          	auipc	s1,0x1d
    800036b2:	e5248493          	addi	s1,s1,-430 # 80020500 <bcache+0x18>
    b->next = bcache.head.next;
    800036b6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036b8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800036ba:	00006a17          	auipc	s4,0x6
    800036be:	11ea0a13          	addi	s4,s4,286 # 800097d8 <syscalls+0xb8>
    b->next = bcache.head.next;
    800036c2:	2b893783          	ld	a5,696(s2)
    800036c6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036c8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036cc:	85d2                	mv	a1,s4
    800036ce:	01048513          	addi	a0,s1,16
    800036d2:	00001097          	auipc	ra,0x1
    800036d6:	7d4080e7          	jalr	2004(ra) # 80004ea6 <initsleeplock>
    bcache.head.next->prev = b;
    800036da:	2b893783          	ld	a5,696(s2)
    800036de:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036e0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036e4:	45848493          	addi	s1,s1,1112
    800036e8:	fd349de3          	bne	s1,s3,800036c2 <binit+0x54>
  }
}
    800036ec:	70a2                	ld	ra,40(sp)
    800036ee:	7402                	ld	s0,32(sp)
    800036f0:	64e2                	ld	s1,24(sp)
    800036f2:	6942                	ld	s2,16(sp)
    800036f4:	69a2                	ld	s3,8(sp)
    800036f6:	6a02                	ld	s4,0(sp)
    800036f8:	6145                	addi	sp,sp,48
    800036fa:	8082                	ret

00000000800036fc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036fc:	7179                	addi	sp,sp,-48
    800036fe:	f406                	sd	ra,40(sp)
    80003700:	f022                	sd	s0,32(sp)
    80003702:	ec26                	sd	s1,24(sp)
    80003704:	e84a                	sd	s2,16(sp)
    80003706:	e44e                	sd	s3,8(sp)
    80003708:	1800                	addi	s0,sp,48
    8000370a:	892a                	mv	s2,a0
    8000370c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000370e:	0001d517          	auipc	a0,0x1d
    80003712:	dda50513          	addi	a0,a0,-550 # 800204e8 <bcache>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	4ac080e7          	jalr	1196(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000371e:	00025497          	auipc	s1,0x25
    80003722:	0824b483          	ld	s1,130(s1) # 800287a0 <bcache+0x82b8>
    80003726:	00025797          	auipc	a5,0x25
    8000372a:	02a78793          	addi	a5,a5,42 # 80028750 <bcache+0x8268>
    8000372e:	02f48f63          	beq	s1,a5,8000376c <bread+0x70>
    80003732:	873e                	mv	a4,a5
    80003734:	a021                	j	8000373c <bread+0x40>
    80003736:	68a4                	ld	s1,80(s1)
    80003738:	02e48a63          	beq	s1,a4,8000376c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000373c:	449c                	lw	a5,8(s1)
    8000373e:	ff279ce3          	bne	a5,s2,80003736 <bread+0x3a>
    80003742:	44dc                	lw	a5,12(s1)
    80003744:	ff3799e3          	bne	a5,s3,80003736 <bread+0x3a>
      b->refcnt++;
    80003748:	40bc                	lw	a5,64(s1)
    8000374a:	2785                	addiw	a5,a5,1
    8000374c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000374e:	0001d517          	auipc	a0,0x1d
    80003752:	d9a50513          	addi	a0,a0,-614 # 800204e8 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	520080e7          	jalr	1312(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000375e:	01048513          	addi	a0,s1,16
    80003762:	00001097          	auipc	ra,0x1
    80003766:	77e080e7          	jalr	1918(ra) # 80004ee0 <acquiresleep>
      return b;
    8000376a:	a8b9                	j	800037c8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000376c:	00025497          	auipc	s1,0x25
    80003770:	02c4b483          	ld	s1,44(s1) # 80028798 <bcache+0x82b0>
    80003774:	00025797          	auipc	a5,0x25
    80003778:	fdc78793          	addi	a5,a5,-36 # 80028750 <bcache+0x8268>
    8000377c:	00f48863          	beq	s1,a5,8000378c <bread+0x90>
    80003780:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003782:	40bc                	lw	a5,64(s1)
    80003784:	cf81                	beqz	a5,8000379c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003786:	64a4                	ld	s1,72(s1)
    80003788:	fee49de3          	bne	s1,a4,80003782 <bread+0x86>
  panic("bget: no buffers");
    8000378c:	00006517          	auipc	a0,0x6
    80003790:	05450513          	addi	a0,a0,84 # 800097e0 <syscalls+0xc0>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	d96080e7          	jalr	-618(ra) # 8000052a <panic>
      b->dev = dev;
    8000379c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800037a0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800037a4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800037a8:	4785                	li	a5,1
    800037aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037ac:	0001d517          	auipc	a0,0x1d
    800037b0:	d3c50513          	addi	a0,a0,-708 # 800204e8 <bcache>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	4c2080e7          	jalr	1218(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800037bc:	01048513          	addi	a0,s1,16
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	720080e7          	jalr	1824(ra) # 80004ee0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037c8:	409c                	lw	a5,0(s1)
    800037ca:	cb89                	beqz	a5,800037dc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037cc:	8526                	mv	a0,s1
    800037ce:	70a2                	ld	ra,40(sp)
    800037d0:	7402                	ld	s0,32(sp)
    800037d2:	64e2                	ld	s1,24(sp)
    800037d4:	6942                	ld	s2,16(sp)
    800037d6:	69a2                	ld	s3,8(sp)
    800037d8:	6145                	addi	sp,sp,48
    800037da:	8082                	ret
    virtio_disk_rw(b, 0);
    800037dc:	4581                	li	a1,0
    800037de:	8526                	mv	a0,s1
    800037e0:	00003097          	auipc	ra,0x3
    800037e4:	516080e7          	jalr	1302(ra) # 80006cf6 <virtio_disk_rw>
    b->valid = 1;
    800037e8:	4785                	li	a5,1
    800037ea:	c09c                	sw	a5,0(s1)
  return b;
    800037ec:	b7c5                	j	800037cc <bread+0xd0>

00000000800037ee <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	1000                	addi	s0,sp,32
    800037f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037fa:	0541                	addi	a0,a0,16
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	77e080e7          	jalr	1918(ra) # 80004f7a <holdingsleep>
    80003804:	cd01                	beqz	a0,8000381c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003806:	4585                	li	a1,1
    80003808:	8526                	mv	a0,s1
    8000380a:	00003097          	auipc	ra,0x3
    8000380e:	4ec080e7          	jalr	1260(ra) # 80006cf6 <virtio_disk_rw>
}
    80003812:	60e2                	ld	ra,24(sp)
    80003814:	6442                	ld	s0,16(sp)
    80003816:	64a2                	ld	s1,8(sp)
    80003818:	6105                	addi	sp,sp,32
    8000381a:	8082                	ret
    panic("bwrite");
    8000381c:	00006517          	auipc	a0,0x6
    80003820:	fdc50513          	addi	a0,a0,-36 # 800097f8 <syscalls+0xd8>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	d06080e7          	jalr	-762(ra) # 8000052a <panic>

000000008000382c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000382c:	1101                	addi	sp,sp,-32
    8000382e:	ec06                	sd	ra,24(sp)
    80003830:	e822                	sd	s0,16(sp)
    80003832:	e426                	sd	s1,8(sp)
    80003834:	e04a                	sd	s2,0(sp)
    80003836:	1000                	addi	s0,sp,32
    80003838:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000383a:	01050913          	addi	s2,a0,16
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	73a080e7          	jalr	1850(ra) # 80004f7a <holdingsleep>
    80003848:	c92d                	beqz	a0,800038ba <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000384a:	854a                	mv	a0,s2
    8000384c:	00001097          	auipc	ra,0x1
    80003850:	6ea080e7          	jalr	1770(ra) # 80004f36 <releasesleep>

  acquire(&bcache.lock);
    80003854:	0001d517          	auipc	a0,0x1d
    80003858:	c9450513          	addi	a0,a0,-876 # 800204e8 <bcache>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	366080e7          	jalr	870(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003864:	40bc                	lw	a5,64(s1)
    80003866:	37fd                	addiw	a5,a5,-1
    80003868:	0007871b          	sext.w	a4,a5
    8000386c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000386e:	eb05                	bnez	a4,8000389e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003870:	68bc                	ld	a5,80(s1)
    80003872:	64b8                	ld	a4,72(s1)
    80003874:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003876:	64bc                	ld	a5,72(s1)
    80003878:	68b8                	ld	a4,80(s1)
    8000387a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000387c:	00025797          	auipc	a5,0x25
    80003880:	c6c78793          	addi	a5,a5,-916 # 800284e8 <bcache+0x8000>
    80003884:	2b87b703          	ld	a4,696(a5)
    80003888:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000388a:	00025717          	auipc	a4,0x25
    8000388e:	ec670713          	addi	a4,a4,-314 # 80028750 <bcache+0x8268>
    80003892:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003894:	2b87b703          	ld	a4,696(a5)
    80003898:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000389a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000389e:	0001d517          	auipc	a0,0x1d
    800038a2:	c4a50513          	addi	a0,a0,-950 # 800204e8 <bcache>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	3d0080e7          	jalr	976(ra) # 80000c76 <release>
}
    800038ae:	60e2                	ld	ra,24(sp)
    800038b0:	6442                	ld	s0,16(sp)
    800038b2:	64a2                	ld	s1,8(sp)
    800038b4:	6902                	ld	s2,0(sp)
    800038b6:	6105                	addi	sp,sp,32
    800038b8:	8082                	ret
    panic("brelse");
    800038ba:	00006517          	auipc	a0,0x6
    800038be:	f4650513          	addi	a0,a0,-186 # 80009800 <syscalls+0xe0>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	c68080e7          	jalr	-920(ra) # 8000052a <panic>

00000000800038ca <bpin>:

void
bpin(struct buf *b) {
    800038ca:	1101                	addi	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	e426                	sd	s1,8(sp)
    800038d2:	1000                	addi	s0,sp,32
    800038d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038d6:	0001d517          	auipc	a0,0x1d
    800038da:	c1250513          	addi	a0,a0,-1006 # 800204e8 <bcache>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	2e4080e7          	jalr	740(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800038e6:	40bc                	lw	a5,64(s1)
    800038e8:	2785                	addiw	a5,a5,1
    800038ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ec:	0001d517          	auipc	a0,0x1d
    800038f0:	bfc50513          	addi	a0,a0,-1028 # 800204e8 <bcache>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	382080e7          	jalr	898(ra) # 80000c76 <release>
}
    800038fc:	60e2                	ld	ra,24(sp)
    800038fe:	6442                	ld	s0,16(sp)
    80003900:	64a2                	ld	s1,8(sp)
    80003902:	6105                	addi	sp,sp,32
    80003904:	8082                	ret

0000000080003906 <bunpin>:

void
bunpin(struct buf *b) {
    80003906:	1101                	addi	sp,sp,-32
    80003908:	ec06                	sd	ra,24(sp)
    8000390a:	e822                	sd	s0,16(sp)
    8000390c:	e426                	sd	s1,8(sp)
    8000390e:	1000                	addi	s0,sp,32
    80003910:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003912:	0001d517          	auipc	a0,0x1d
    80003916:	bd650513          	addi	a0,a0,-1066 # 800204e8 <bcache>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	2a8080e7          	jalr	680(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003922:	40bc                	lw	a5,64(s1)
    80003924:	37fd                	addiw	a5,a5,-1
    80003926:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003928:	0001d517          	auipc	a0,0x1d
    8000392c:	bc050513          	addi	a0,a0,-1088 # 800204e8 <bcache>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	346080e7          	jalr	838(ra) # 80000c76 <release>
}
    80003938:	60e2                	ld	ra,24(sp)
    8000393a:	6442                	ld	s0,16(sp)
    8000393c:	64a2                	ld	s1,8(sp)
    8000393e:	6105                	addi	sp,sp,32
    80003940:	8082                	ret

0000000080003942 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003942:	1101                	addi	sp,sp,-32
    80003944:	ec06                	sd	ra,24(sp)
    80003946:	e822                	sd	s0,16(sp)
    80003948:	e426                	sd	s1,8(sp)
    8000394a:	e04a                	sd	s2,0(sp)
    8000394c:	1000                	addi	s0,sp,32
    8000394e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003950:	00d5d59b          	srliw	a1,a1,0xd
    80003954:	00025797          	auipc	a5,0x25
    80003958:	2707a783          	lw	a5,624(a5) # 80028bc4 <sb+0x1c>
    8000395c:	9dbd                	addw	a1,a1,a5
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	d9e080e7          	jalr	-610(ra) # 800036fc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003966:	0074f713          	andi	a4,s1,7
    8000396a:	4785                	li	a5,1
    8000396c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003970:	14ce                	slli	s1,s1,0x33
    80003972:	90d9                	srli	s1,s1,0x36
    80003974:	00950733          	add	a4,a0,s1
    80003978:	05874703          	lbu	a4,88(a4)
    8000397c:	00e7f6b3          	and	a3,a5,a4
    80003980:	c69d                	beqz	a3,800039ae <bfree+0x6c>
    80003982:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003984:	94aa                	add	s1,s1,a0
    80003986:	fff7c793          	not	a5,a5
    8000398a:	8ff9                	and	a5,a5,a4
    8000398c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003990:	00001097          	auipc	ra,0x1
    80003994:	430080e7          	jalr	1072(ra) # 80004dc0 <log_write>
  brelse(bp);
    80003998:	854a                	mv	a0,s2
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	e92080e7          	jalr	-366(ra) # 8000382c <brelse>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6902                	ld	s2,0(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret
    panic("freeing free block");
    800039ae:	00006517          	auipc	a0,0x6
    800039b2:	e5a50513          	addi	a0,a0,-422 # 80009808 <syscalls+0xe8>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	b74080e7          	jalr	-1164(ra) # 8000052a <panic>

00000000800039be <balloc>:
{
    800039be:	711d                	addi	sp,sp,-96
    800039c0:	ec86                	sd	ra,88(sp)
    800039c2:	e8a2                	sd	s0,80(sp)
    800039c4:	e4a6                	sd	s1,72(sp)
    800039c6:	e0ca                	sd	s2,64(sp)
    800039c8:	fc4e                	sd	s3,56(sp)
    800039ca:	f852                	sd	s4,48(sp)
    800039cc:	f456                	sd	s5,40(sp)
    800039ce:	f05a                	sd	s6,32(sp)
    800039d0:	ec5e                	sd	s7,24(sp)
    800039d2:	e862                	sd	s8,16(sp)
    800039d4:	e466                	sd	s9,8(sp)
    800039d6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039d8:	00025797          	auipc	a5,0x25
    800039dc:	1d47a783          	lw	a5,468(a5) # 80028bac <sb+0x4>
    800039e0:	cbd1                	beqz	a5,80003a74 <balloc+0xb6>
    800039e2:	8baa                	mv	s7,a0
    800039e4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039e6:	00025b17          	auipc	s6,0x25
    800039ea:	1c2b0b13          	addi	s6,s6,450 # 80028ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ee:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039f0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039f2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039f4:	6c89                	lui	s9,0x2
    800039f6:	a831                	j	80003a12 <balloc+0x54>
    brelse(bp);
    800039f8:	854a                	mv	a0,s2
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	e32080e7          	jalr	-462(ra) # 8000382c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a02:	015c87bb          	addw	a5,s9,s5
    80003a06:	00078a9b          	sext.w	s5,a5
    80003a0a:	004b2703          	lw	a4,4(s6)
    80003a0e:	06eaf363          	bgeu	s5,a4,80003a74 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003a12:	41fad79b          	sraiw	a5,s5,0x1f
    80003a16:	0137d79b          	srliw	a5,a5,0x13
    80003a1a:	015787bb          	addw	a5,a5,s5
    80003a1e:	40d7d79b          	sraiw	a5,a5,0xd
    80003a22:	01cb2583          	lw	a1,28(s6)
    80003a26:	9dbd                	addw	a1,a1,a5
    80003a28:	855e                	mv	a0,s7
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	cd2080e7          	jalr	-814(ra) # 800036fc <bread>
    80003a32:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a34:	004b2503          	lw	a0,4(s6)
    80003a38:	000a849b          	sext.w	s1,s5
    80003a3c:	8662                	mv	a2,s8
    80003a3e:	faa4fde3          	bgeu	s1,a0,800039f8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a42:	41f6579b          	sraiw	a5,a2,0x1f
    80003a46:	01d7d69b          	srliw	a3,a5,0x1d
    80003a4a:	00c6873b          	addw	a4,a3,a2
    80003a4e:	00777793          	andi	a5,a4,7
    80003a52:	9f95                	subw	a5,a5,a3
    80003a54:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a58:	4037571b          	sraiw	a4,a4,0x3
    80003a5c:	00e906b3          	add	a3,s2,a4
    80003a60:	0586c683          	lbu	a3,88(a3)
    80003a64:	00d7f5b3          	and	a1,a5,a3
    80003a68:	cd91                	beqz	a1,80003a84 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a6a:	2605                	addiw	a2,a2,1
    80003a6c:	2485                	addiw	s1,s1,1
    80003a6e:	fd4618e3          	bne	a2,s4,80003a3e <balloc+0x80>
    80003a72:	b759                	j	800039f8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a74:	00006517          	auipc	a0,0x6
    80003a78:	dac50513          	addi	a0,a0,-596 # 80009820 <syscalls+0x100>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	aae080e7          	jalr	-1362(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a84:	974a                	add	a4,a4,s2
    80003a86:	8fd5                	or	a5,a5,a3
    80003a88:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	332080e7          	jalr	818(ra) # 80004dc0 <log_write>
        brelse(bp);
    80003a96:	854a                	mv	a0,s2
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	d94080e7          	jalr	-620(ra) # 8000382c <brelse>
  bp = bread(dev, bno);
    80003aa0:	85a6                	mv	a1,s1
    80003aa2:	855e                	mv	a0,s7
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	c58080e7          	jalr	-936(ra) # 800036fc <bread>
    80003aac:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003aae:	40000613          	li	a2,1024
    80003ab2:	4581                	li	a1,0
    80003ab4:	05850513          	addi	a0,a0,88
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	206080e7          	jalr	518(ra) # 80000cbe <memset>
  log_write(bp);
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	00001097          	auipc	ra,0x1
    80003ac6:	2fe080e7          	jalr	766(ra) # 80004dc0 <log_write>
  brelse(bp);
    80003aca:	854a                	mv	a0,s2
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	d60080e7          	jalr	-672(ra) # 8000382c <brelse>
}
    80003ad4:	8526                	mv	a0,s1
    80003ad6:	60e6                	ld	ra,88(sp)
    80003ad8:	6446                	ld	s0,80(sp)
    80003ada:	64a6                	ld	s1,72(sp)
    80003adc:	6906                	ld	s2,64(sp)
    80003ade:	79e2                	ld	s3,56(sp)
    80003ae0:	7a42                	ld	s4,48(sp)
    80003ae2:	7aa2                	ld	s5,40(sp)
    80003ae4:	7b02                	ld	s6,32(sp)
    80003ae6:	6be2                	ld	s7,24(sp)
    80003ae8:	6c42                	ld	s8,16(sp)
    80003aea:	6ca2                	ld	s9,8(sp)
    80003aec:	6125                	addi	sp,sp,96
    80003aee:	8082                	ret

0000000080003af0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003af0:	7179                	addi	sp,sp,-48
    80003af2:	f406                	sd	ra,40(sp)
    80003af4:	f022                	sd	s0,32(sp)
    80003af6:	ec26                	sd	s1,24(sp)
    80003af8:	e84a                	sd	s2,16(sp)
    80003afa:	e44e                	sd	s3,8(sp)
    80003afc:	e052                	sd	s4,0(sp)
    80003afe:	1800                	addi	s0,sp,48
    80003b00:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b02:	47ad                	li	a5,11
    80003b04:	04b7fe63          	bgeu	a5,a1,80003b60 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b08:	ff45849b          	addiw	s1,a1,-12
    80003b0c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b10:	0ff00793          	li	a5,255
    80003b14:	0ae7e463          	bltu	a5,a4,80003bbc <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b18:	08052583          	lw	a1,128(a0)
    80003b1c:	c5b5                	beqz	a1,80003b88 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b1e:	00092503          	lw	a0,0(s2)
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	bda080e7          	jalr	-1062(ra) # 800036fc <bread>
    80003b2a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b2c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b30:	02049713          	slli	a4,s1,0x20
    80003b34:	01e75593          	srli	a1,a4,0x1e
    80003b38:	00b784b3          	add	s1,a5,a1
    80003b3c:	0004a983          	lw	s3,0(s1)
    80003b40:	04098e63          	beqz	s3,80003b9c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b44:	8552                	mv	a0,s4
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	ce6080e7          	jalr	-794(ra) # 8000382c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b4e:	854e                	mv	a0,s3
    80003b50:	70a2                	ld	ra,40(sp)
    80003b52:	7402                	ld	s0,32(sp)
    80003b54:	64e2                	ld	s1,24(sp)
    80003b56:	6942                	ld	s2,16(sp)
    80003b58:	69a2                	ld	s3,8(sp)
    80003b5a:	6a02                	ld	s4,0(sp)
    80003b5c:	6145                	addi	sp,sp,48
    80003b5e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b60:	02059793          	slli	a5,a1,0x20
    80003b64:	01e7d593          	srli	a1,a5,0x1e
    80003b68:	00b504b3          	add	s1,a0,a1
    80003b6c:	0504a983          	lw	s3,80(s1)
    80003b70:	fc099fe3          	bnez	s3,80003b4e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b74:	4108                	lw	a0,0(a0)
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	e48080e7          	jalr	-440(ra) # 800039be <balloc>
    80003b7e:	0005099b          	sext.w	s3,a0
    80003b82:	0534a823          	sw	s3,80(s1)
    80003b86:	b7e1                	j	80003b4e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b88:	4108                	lw	a0,0(a0)
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	e34080e7          	jalr	-460(ra) # 800039be <balloc>
    80003b92:	0005059b          	sext.w	a1,a0
    80003b96:	08b92023          	sw	a1,128(s2)
    80003b9a:	b751                	j	80003b1e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b9c:	00092503          	lw	a0,0(s2)
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	e1e080e7          	jalr	-482(ra) # 800039be <balloc>
    80003ba8:	0005099b          	sext.w	s3,a0
    80003bac:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003bb0:	8552                	mv	a0,s4
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	20e080e7          	jalr	526(ra) # 80004dc0 <log_write>
    80003bba:	b769                	j	80003b44 <bmap+0x54>
  panic("bmap: out of range");
    80003bbc:	00006517          	auipc	a0,0x6
    80003bc0:	c7c50513          	addi	a0,a0,-900 # 80009838 <syscalls+0x118>
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	966080e7          	jalr	-1690(ra) # 8000052a <panic>

0000000080003bcc <iget>:
{
    80003bcc:	7179                	addi	sp,sp,-48
    80003bce:	f406                	sd	ra,40(sp)
    80003bd0:	f022                	sd	s0,32(sp)
    80003bd2:	ec26                	sd	s1,24(sp)
    80003bd4:	e84a                	sd	s2,16(sp)
    80003bd6:	e44e                	sd	s3,8(sp)
    80003bd8:	e052                	sd	s4,0(sp)
    80003bda:	1800                	addi	s0,sp,48
    80003bdc:	89aa                	mv	s3,a0
    80003bde:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003be0:	00025517          	auipc	a0,0x25
    80003be4:	fe850513          	addi	a0,a0,-24 # 80028bc8 <itable>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	fda080e7          	jalr	-38(ra) # 80000bc2 <acquire>
  empty = 0;
    80003bf0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bf2:	00025497          	auipc	s1,0x25
    80003bf6:	fee48493          	addi	s1,s1,-18 # 80028be0 <itable+0x18>
    80003bfa:	00027697          	auipc	a3,0x27
    80003bfe:	a7668693          	addi	a3,a3,-1418 # 8002a670 <log>
    80003c02:	a039                	j	80003c10 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c04:	02090b63          	beqz	s2,80003c3a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c08:	08848493          	addi	s1,s1,136
    80003c0c:	02d48a63          	beq	s1,a3,80003c40 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c10:	449c                	lw	a5,8(s1)
    80003c12:	fef059e3          	blez	a5,80003c04 <iget+0x38>
    80003c16:	4098                	lw	a4,0(s1)
    80003c18:	ff3716e3          	bne	a4,s3,80003c04 <iget+0x38>
    80003c1c:	40d8                	lw	a4,4(s1)
    80003c1e:	ff4713e3          	bne	a4,s4,80003c04 <iget+0x38>
      ip->ref++;
    80003c22:	2785                	addiw	a5,a5,1
    80003c24:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c26:	00025517          	auipc	a0,0x25
    80003c2a:	fa250513          	addi	a0,a0,-94 # 80028bc8 <itable>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	048080e7          	jalr	72(ra) # 80000c76 <release>
      return ip;
    80003c36:	8926                	mv	s2,s1
    80003c38:	a03d                	j	80003c66 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c3a:	f7f9                	bnez	a5,80003c08 <iget+0x3c>
    80003c3c:	8926                	mv	s2,s1
    80003c3e:	b7e9                	j	80003c08 <iget+0x3c>
  if(empty == 0)
    80003c40:	02090c63          	beqz	s2,80003c78 <iget+0xac>
  ip->dev = dev;
    80003c44:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c48:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c4c:	4785                	li	a5,1
    80003c4e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c52:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c56:	00025517          	auipc	a0,0x25
    80003c5a:	f7250513          	addi	a0,a0,-142 # 80028bc8 <itable>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	018080e7          	jalr	24(ra) # 80000c76 <release>
}
    80003c66:	854a                	mv	a0,s2
    80003c68:	70a2                	ld	ra,40(sp)
    80003c6a:	7402                	ld	s0,32(sp)
    80003c6c:	64e2                	ld	s1,24(sp)
    80003c6e:	6942                	ld	s2,16(sp)
    80003c70:	69a2                	ld	s3,8(sp)
    80003c72:	6a02                	ld	s4,0(sp)
    80003c74:	6145                	addi	sp,sp,48
    80003c76:	8082                	ret
    panic("iget: no inodes");
    80003c78:	00006517          	auipc	a0,0x6
    80003c7c:	bd850513          	addi	a0,a0,-1064 # 80009850 <syscalls+0x130>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	8aa080e7          	jalr	-1878(ra) # 8000052a <panic>

0000000080003c88 <fsinit>:
fsinit(int dev) {
    80003c88:	7179                	addi	sp,sp,-48
    80003c8a:	f406                	sd	ra,40(sp)
    80003c8c:	f022                	sd	s0,32(sp)
    80003c8e:	ec26                	sd	s1,24(sp)
    80003c90:	e84a                	sd	s2,16(sp)
    80003c92:	e44e                	sd	s3,8(sp)
    80003c94:	1800                	addi	s0,sp,48
    80003c96:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c98:	4585                	li	a1,1
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	a62080e7          	jalr	-1438(ra) # 800036fc <bread>
    80003ca2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ca4:	00025997          	auipc	s3,0x25
    80003ca8:	f0498993          	addi	s3,s3,-252 # 80028ba8 <sb>
    80003cac:	02000613          	li	a2,32
    80003cb0:	05850593          	addi	a1,a0,88
    80003cb4:	854e                	mv	a0,s3
    80003cb6:	ffffd097          	auipc	ra,0xffffd
    80003cba:	064080e7          	jalr	100(ra) # 80000d1a <memmove>
  brelse(bp);
    80003cbe:	8526                	mv	a0,s1
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	b6c080e7          	jalr	-1172(ra) # 8000382c <brelse>
  if(sb.magic != FSMAGIC)
    80003cc8:	0009a703          	lw	a4,0(s3)
    80003ccc:	102037b7          	lui	a5,0x10203
    80003cd0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cd4:	02f71263          	bne	a4,a5,80003cf8 <fsinit+0x70>
  initlog(dev, &sb);
    80003cd8:	00025597          	auipc	a1,0x25
    80003cdc:	ed058593          	addi	a1,a1,-304 # 80028ba8 <sb>
    80003ce0:	854a                	mv	a0,s2
    80003ce2:	00001097          	auipc	ra,0x1
    80003ce6:	e60080e7          	jalr	-416(ra) # 80004b42 <initlog>
}
    80003cea:	70a2                	ld	ra,40(sp)
    80003cec:	7402                	ld	s0,32(sp)
    80003cee:	64e2                	ld	s1,24(sp)
    80003cf0:	6942                	ld	s2,16(sp)
    80003cf2:	69a2                	ld	s3,8(sp)
    80003cf4:	6145                	addi	sp,sp,48
    80003cf6:	8082                	ret
    panic("invalid file system");
    80003cf8:	00006517          	auipc	a0,0x6
    80003cfc:	b6850513          	addi	a0,a0,-1176 # 80009860 <syscalls+0x140>
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	82a080e7          	jalr	-2006(ra) # 8000052a <panic>

0000000080003d08 <iinit>:
{
    80003d08:	7179                	addi	sp,sp,-48
    80003d0a:	f406                	sd	ra,40(sp)
    80003d0c:	f022                	sd	s0,32(sp)
    80003d0e:	ec26                	sd	s1,24(sp)
    80003d10:	e84a                	sd	s2,16(sp)
    80003d12:	e44e                	sd	s3,8(sp)
    80003d14:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d16:	00006597          	auipc	a1,0x6
    80003d1a:	b6258593          	addi	a1,a1,-1182 # 80009878 <syscalls+0x158>
    80003d1e:	00025517          	auipc	a0,0x25
    80003d22:	eaa50513          	addi	a0,a0,-342 # 80028bc8 <itable>
    80003d26:	ffffd097          	auipc	ra,0xffffd
    80003d2a:	e0c080e7          	jalr	-500(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d2e:	00025497          	auipc	s1,0x25
    80003d32:	ec248493          	addi	s1,s1,-318 # 80028bf0 <itable+0x28>
    80003d36:	00027997          	auipc	s3,0x27
    80003d3a:	94a98993          	addi	s3,s3,-1718 # 8002a680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d3e:	00006917          	auipc	s2,0x6
    80003d42:	b4290913          	addi	s2,s2,-1214 # 80009880 <syscalls+0x160>
    80003d46:	85ca                	mv	a1,s2
    80003d48:	8526                	mv	a0,s1
    80003d4a:	00001097          	auipc	ra,0x1
    80003d4e:	15c080e7          	jalr	348(ra) # 80004ea6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d52:	08848493          	addi	s1,s1,136
    80003d56:	ff3498e3          	bne	s1,s3,80003d46 <iinit+0x3e>
}
    80003d5a:	70a2                	ld	ra,40(sp)
    80003d5c:	7402                	ld	s0,32(sp)
    80003d5e:	64e2                	ld	s1,24(sp)
    80003d60:	6942                	ld	s2,16(sp)
    80003d62:	69a2                	ld	s3,8(sp)
    80003d64:	6145                	addi	sp,sp,48
    80003d66:	8082                	ret

0000000080003d68 <ialloc>:
{
    80003d68:	715d                	addi	sp,sp,-80
    80003d6a:	e486                	sd	ra,72(sp)
    80003d6c:	e0a2                	sd	s0,64(sp)
    80003d6e:	fc26                	sd	s1,56(sp)
    80003d70:	f84a                	sd	s2,48(sp)
    80003d72:	f44e                	sd	s3,40(sp)
    80003d74:	f052                	sd	s4,32(sp)
    80003d76:	ec56                	sd	s5,24(sp)
    80003d78:	e85a                	sd	s6,16(sp)
    80003d7a:	e45e                	sd	s7,8(sp)
    80003d7c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d7e:	00025717          	auipc	a4,0x25
    80003d82:	e3672703          	lw	a4,-458(a4) # 80028bb4 <sb+0xc>
    80003d86:	4785                	li	a5,1
    80003d88:	04e7fa63          	bgeu	a5,a4,80003ddc <ialloc+0x74>
    80003d8c:	8aaa                	mv	s5,a0
    80003d8e:	8bae                	mv	s7,a1
    80003d90:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d92:	00025a17          	auipc	s4,0x25
    80003d96:	e16a0a13          	addi	s4,s4,-490 # 80028ba8 <sb>
    80003d9a:	00048b1b          	sext.w	s6,s1
    80003d9e:	0044d793          	srli	a5,s1,0x4
    80003da2:	018a2583          	lw	a1,24(s4)
    80003da6:	9dbd                	addw	a1,a1,a5
    80003da8:	8556                	mv	a0,s5
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	952080e7          	jalr	-1710(ra) # 800036fc <bread>
    80003db2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003db4:	05850993          	addi	s3,a0,88
    80003db8:	00f4f793          	andi	a5,s1,15
    80003dbc:	079a                	slli	a5,a5,0x6
    80003dbe:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003dc0:	00099783          	lh	a5,0(s3)
    80003dc4:	c785                	beqz	a5,80003dec <ialloc+0x84>
    brelse(bp);
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	a66080e7          	jalr	-1434(ra) # 8000382c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dce:	0485                	addi	s1,s1,1
    80003dd0:	00ca2703          	lw	a4,12(s4)
    80003dd4:	0004879b          	sext.w	a5,s1
    80003dd8:	fce7e1e3          	bltu	a5,a4,80003d9a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ddc:	00006517          	auipc	a0,0x6
    80003de0:	aac50513          	addi	a0,a0,-1364 # 80009888 <syscalls+0x168>
    80003de4:	ffffc097          	auipc	ra,0xffffc
    80003de8:	746080e7          	jalr	1862(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003dec:	04000613          	li	a2,64
    80003df0:	4581                	li	a1,0
    80003df2:	854e                	mv	a0,s3
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	eca080e7          	jalr	-310(ra) # 80000cbe <memset>
      dip->type = type;
    80003dfc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e00:	854a                	mv	a0,s2
    80003e02:	00001097          	auipc	ra,0x1
    80003e06:	fbe080e7          	jalr	-66(ra) # 80004dc0 <log_write>
      brelse(bp);
    80003e0a:	854a                	mv	a0,s2
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	a20080e7          	jalr	-1504(ra) # 8000382c <brelse>
      return iget(dev, inum);
    80003e14:	85da                	mv	a1,s6
    80003e16:	8556                	mv	a0,s5
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	db4080e7          	jalr	-588(ra) # 80003bcc <iget>
}
    80003e20:	60a6                	ld	ra,72(sp)
    80003e22:	6406                	ld	s0,64(sp)
    80003e24:	74e2                	ld	s1,56(sp)
    80003e26:	7942                	ld	s2,48(sp)
    80003e28:	79a2                	ld	s3,40(sp)
    80003e2a:	7a02                	ld	s4,32(sp)
    80003e2c:	6ae2                	ld	s5,24(sp)
    80003e2e:	6b42                	ld	s6,16(sp)
    80003e30:	6ba2                	ld	s7,8(sp)
    80003e32:	6161                	addi	sp,sp,80
    80003e34:	8082                	ret

0000000080003e36 <iupdate>:
{
    80003e36:	1101                	addi	sp,sp,-32
    80003e38:	ec06                	sd	ra,24(sp)
    80003e3a:	e822                	sd	s0,16(sp)
    80003e3c:	e426                	sd	s1,8(sp)
    80003e3e:	e04a                	sd	s2,0(sp)
    80003e40:	1000                	addi	s0,sp,32
    80003e42:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e44:	415c                	lw	a5,4(a0)
    80003e46:	0047d79b          	srliw	a5,a5,0x4
    80003e4a:	00025597          	auipc	a1,0x25
    80003e4e:	d765a583          	lw	a1,-650(a1) # 80028bc0 <sb+0x18>
    80003e52:	9dbd                	addw	a1,a1,a5
    80003e54:	4108                	lw	a0,0(a0)
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	8a6080e7          	jalr	-1882(ra) # 800036fc <bread>
    80003e5e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e60:	05850793          	addi	a5,a0,88
    80003e64:	40c8                	lw	a0,4(s1)
    80003e66:	893d                	andi	a0,a0,15
    80003e68:	051a                	slli	a0,a0,0x6
    80003e6a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e6c:	04449703          	lh	a4,68(s1)
    80003e70:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e74:	04649703          	lh	a4,70(s1)
    80003e78:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e7c:	04849703          	lh	a4,72(s1)
    80003e80:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e84:	04a49703          	lh	a4,74(s1)
    80003e88:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e8c:	44f8                	lw	a4,76(s1)
    80003e8e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e90:	03400613          	li	a2,52
    80003e94:	05048593          	addi	a1,s1,80
    80003e98:	0531                	addi	a0,a0,12
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	e80080e7          	jalr	-384(ra) # 80000d1a <memmove>
  log_write(bp);
    80003ea2:	854a                	mv	a0,s2
    80003ea4:	00001097          	auipc	ra,0x1
    80003ea8:	f1c080e7          	jalr	-228(ra) # 80004dc0 <log_write>
  brelse(bp);
    80003eac:	854a                	mv	a0,s2
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	97e080e7          	jalr	-1666(ra) # 8000382c <brelse>
}
    80003eb6:	60e2                	ld	ra,24(sp)
    80003eb8:	6442                	ld	s0,16(sp)
    80003eba:	64a2                	ld	s1,8(sp)
    80003ebc:	6902                	ld	s2,0(sp)
    80003ebe:	6105                	addi	sp,sp,32
    80003ec0:	8082                	ret

0000000080003ec2 <idup>:
{
    80003ec2:	1101                	addi	sp,sp,-32
    80003ec4:	ec06                	sd	ra,24(sp)
    80003ec6:	e822                	sd	s0,16(sp)
    80003ec8:	e426                	sd	s1,8(sp)
    80003eca:	1000                	addi	s0,sp,32
    80003ecc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ece:	00025517          	auipc	a0,0x25
    80003ed2:	cfa50513          	addi	a0,a0,-774 # 80028bc8 <itable>
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	cec080e7          	jalr	-788(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003ede:	449c                	lw	a5,8(s1)
    80003ee0:	2785                	addiw	a5,a5,1
    80003ee2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ee4:	00025517          	auipc	a0,0x25
    80003ee8:	ce450513          	addi	a0,a0,-796 # 80028bc8 <itable>
    80003eec:	ffffd097          	auipc	ra,0xffffd
    80003ef0:	d8a080e7          	jalr	-630(ra) # 80000c76 <release>
}
    80003ef4:	8526                	mv	a0,s1
    80003ef6:	60e2                	ld	ra,24(sp)
    80003ef8:	6442                	ld	s0,16(sp)
    80003efa:	64a2                	ld	s1,8(sp)
    80003efc:	6105                	addi	sp,sp,32
    80003efe:	8082                	ret

0000000080003f00 <ilock>:
{
    80003f00:	1101                	addi	sp,sp,-32
    80003f02:	ec06                	sd	ra,24(sp)
    80003f04:	e822                	sd	s0,16(sp)
    80003f06:	e426                	sd	s1,8(sp)
    80003f08:	e04a                	sd	s2,0(sp)
    80003f0a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f0c:	c115                	beqz	a0,80003f30 <ilock+0x30>
    80003f0e:	84aa                	mv	s1,a0
    80003f10:	451c                	lw	a5,8(a0)
    80003f12:	00f05f63          	blez	a5,80003f30 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f16:	0541                	addi	a0,a0,16
    80003f18:	00001097          	auipc	ra,0x1
    80003f1c:	fc8080e7          	jalr	-56(ra) # 80004ee0 <acquiresleep>
  if(ip->valid == 0){
    80003f20:	40bc                	lw	a5,64(s1)
    80003f22:	cf99                	beqz	a5,80003f40 <ilock+0x40>
}
    80003f24:	60e2                	ld	ra,24(sp)
    80003f26:	6442                	ld	s0,16(sp)
    80003f28:	64a2                	ld	s1,8(sp)
    80003f2a:	6902                	ld	s2,0(sp)
    80003f2c:	6105                	addi	sp,sp,32
    80003f2e:	8082                	ret
    panic("ilock");
    80003f30:	00006517          	auipc	a0,0x6
    80003f34:	97050513          	addi	a0,a0,-1680 # 800098a0 <syscalls+0x180>
    80003f38:	ffffc097          	auipc	ra,0xffffc
    80003f3c:	5f2080e7          	jalr	1522(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f40:	40dc                	lw	a5,4(s1)
    80003f42:	0047d79b          	srliw	a5,a5,0x4
    80003f46:	00025597          	auipc	a1,0x25
    80003f4a:	c7a5a583          	lw	a1,-902(a1) # 80028bc0 <sb+0x18>
    80003f4e:	9dbd                	addw	a1,a1,a5
    80003f50:	4088                	lw	a0,0(s1)
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	7aa080e7          	jalr	1962(ra) # 800036fc <bread>
    80003f5a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f5c:	05850593          	addi	a1,a0,88
    80003f60:	40dc                	lw	a5,4(s1)
    80003f62:	8bbd                	andi	a5,a5,15
    80003f64:	079a                	slli	a5,a5,0x6
    80003f66:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f68:	00059783          	lh	a5,0(a1)
    80003f6c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f70:	00259783          	lh	a5,2(a1)
    80003f74:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f78:	00459783          	lh	a5,4(a1)
    80003f7c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f80:	00659783          	lh	a5,6(a1)
    80003f84:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f88:	459c                	lw	a5,8(a1)
    80003f8a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f8c:	03400613          	li	a2,52
    80003f90:	05b1                	addi	a1,a1,12
    80003f92:	05048513          	addi	a0,s1,80
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	d84080e7          	jalr	-636(ra) # 80000d1a <memmove>
    brelse(bp);
    80003f9e:	854a                	mv	a0,s2
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	88c080e7          	jalr	-1908(ra) # 8000382c <brelse>
    ip->valid = 1;
    80003fa8:	4785                	li	a5,1
    80003faa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003fac:	04449783          	lh	a5,68(s1)
    80003fb0:	fbb5                	bnez	a5,80003f24 <ilock+0x24>
      panic("ilock: no type");
    80003fb2:	00006517          	auipc	a0,0x6
    80003fb6:	8f650513          	addi	a0,a0,-1802 # 800098a8 <syscalls+0x188>
    80003fba:	ffffc097          	auipc	ra,0xffffc
    80003fbe:	570080e7          	jalr	1392(ra) # 8000052a <panic>

0000000080003fc2 <iunlock>:
{
    80003fc2:	1101                	addi	sp,sp,-32
    80003fc4:	ec06                	sd	ra,24(sp)
    80003fc6:	e822                	sd	s0,16(sp)
    80003fc8:	e426                	sd	s1,8(sp)
    80003fca:	e04a                	sd	s2,0(sp)
    80003fcc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fce:	c905                	beqz	a0,80003ffe <iunlock+0x3c>
    80003fd0:	84aa                	mv	s1,a0
    80003fd2:	01050913          	addi	s2,a0,16
    80003fd6:	854a                	mv	a0,s2
    80003fd8:	00001097          	auipc	ra,0x1
    80003fdc:	fa2080e7          	jalr	-94(ra) # 80004f7a <holdingsleep>
    80003fe0:	cd19                	beqz	a0,80003ffe <iunlock+0x3c>
    80003fe2:	449c                	lw	a5,8(s1)
    80003fe4:	00f05d63          	blez	a5,80003ffe <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fe8:	854a                	mv	a0,s2
    80003fea:	00001097          	auipc	ra,0x1
    80003fee:	f4c080e7          	jalr	-180(ra) # 80004f36 <releasesleep>
}
    80003ff2:	60e2                	ld	ra,24(sp)
    80003ff4:	6442                	ld	s0,16(sp)
    80003ff6:	64a2                	ld	s1,8(sp)
    80003ff8:	6902                	ld	s2,0(sp)
    80003ffa:	6105                	addi	sp,sp,32
    80003ffc:	8082                	ret
    panic("iunlock");
    80003ffe:	00006517          	auipc	a0,0x6
    80004002:	8ba50513          	addi	a0,a0,-1862 # 800098b8 <syscalls+0x198>
    80004006:	ffffc097          	auipc	ra,0xffffc
    8000400a:	524080e7          	jalr	1316(ra) # 8000052a <panic>

000000008000400e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000400e:	7179                	addi	sp,sp,-48
    80004010:	f406                	sd	ra,40(sp)
    80004012:	f022                	sd	s0,32(sp)
    80004014:	ec26                	sd	s1,24(sp)
    80004016:	e84a                	sd	s2,16(sp)
    80004018:	e44e                	sd	s3,8(sp)
    8000401a:	e052                	sd	s4,0(sp)
    8000401c:	1800                	addi	s0,sp,48
    8000401e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004020:	05050493          	addi	s1,a0,80
    80004024:	08050913          	addi	s2,a0,128
    80004028:	a021                	j	80004030 <itrunc+0x22>
    8000402a:	0491                	addi	s1,s1,4
    8000402c:	01248d63          	beq	s1,s2,80004046 <itrunc+0x38>
    if(ip->addrs[i]){
    80004030:	408c                	lw	a1,0(s1)
    80004032:	dde5                	beqz	a1,8000402a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004034:	0009a503          	lw	a0,0(s3)
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	90a080e7          	jalr	-1782(ra) # 80003942 <bfree>
      ip->addrs[i] = 0;
    80004040:	0004a023          	sw	zero,0(s1)
    80004044:	b7dd                	j	8000402a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004046:	0809a583          	lw	a1,128(s3)
    8000404a:	e185                	bnez	a1,8000406a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000404c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004050:	854e                	mv	a0,s3
    80004052:	00000097          	auipc	ra,0x0
    80004056:	de4080e7          	jalr	-540(ra) # 80003e36 <iupdate>
}
    8000405a:	70a2                	ld	ra,40(sp)
    8000405c:	7402                	ld	s0,32(sp)
    8000405e:	64e2                	ld	s1,24(sp)
    80004060:	6942                	ld	s2,16(sp)
    80004062:	69a2                	ld	s3,8(sp)
    80004064:	6a02                	ld	s4,0(sp)
    80004066:	6145                	addi	sp,sp,48
    80004068:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000406a:	0009a503          	lw	a0,0(s3)
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	68e080e7          	jalr	1678(ra) # 800036fc <bread>
    80004076:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004078:	05850493          	addi	s1,a0,88
    8000407c:	45850913          	addi	s2,a0,1112
    80004080:	a021                	j	80004088 <itrunc+0x7a>
    80004082:	0491                	addi	s1,s1,4
    80004084:	01248b63          	beq	s1,s2,8000409a <itrunc+0x8c>
      if(a[j])
    80004088:	408c                	lw	a1,0(s1)
    8000408a:	dde5                	beqz	a1,80004082 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000408c:	0009a503          	lw	a0,0(s3)
    80004090:	00000097          	auipc	ra,0x0
    80004094:	8b2080e7          	jalr	-1870(ra) # 80003942 <bfree>
    80004098:	b7ed                	j	80004082 <itrunc+0x74>
    brelse(bp);
    8000409a:	8552                	mv	a0,s4
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	790080e7          	jalr	1936(ra) # 8000382c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800040a4:	0809a583          	lw	a1,128(s3)
    800040a8:	0009a503          	lw	a0,0(s3)
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	896080e7          	jalr	-1898(ra) # 80003942 <bfree>
    ip->addrs[NDIRECT] = 0;
    800040b4:	0809a023          	sw	zero,128(s3)
    800040b8:	bf51                	j	8000404c <itrunc+0x3e>

00000000800040ba <iput>:
{
    800040ba:	1101                	addi	sp,sp,-32
    800040bc:	ec06                	sd	ra,24(sp)
    800040be:	e822                	sd	s0,16(sp)
    800040c0:	e426                	sd	s1,8(sp)
    800040c2:	e04a                	sd	s2,0(sp)
    800040c4:	1000                	addi	s0,sp,32
    800040c6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040c8:	00025517          	auipc	a0,0x25
    800040cc:	b0050513          	addi	a0,a0,-1280 # 80028bc8 <itable>
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	af2080e7          	jalr	-1294(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040d8:	4498                	lw	a4,8(s1)
    800040da:	4785                	li	a5,1
    800040dc:	02f70363          	beq	a4,a5,80004102 <iput+0x48>
  ip->ref--;
    800040e0:	449c                	lw	a5,8(s1)
    800040e2:	37fd                	addiw	a5,a5,-1
    800040e4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040e6:	00025517          	auipc	a0,0x25
    800040ea:	ae250513          	addi	a0,a0,-1310 # 80028bc8 <itable>
    800040ee:	ffffd097          	auipc	ra,0xffffd
    800040f2:	b88080e7          	jalr	-1144(ra) # 80000c76 <release>
}
    800040f6:	60e2                	ld	ra,24(sp)
    800040f8:	6442                	ld	s0,16(sp)
    800040fa:	64a2                	ld	s1,8(sp)
    800040fc:	6902                	ld	s2,0(sp)
    800040fe:	6105                	addi	sp,sp,32
    80004100:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004102:	40bc                	lw	a5,64(s1)
    80004104:	dff1                	beqz	a5,800040e0 <iput+0x26>
    80004106:	04a49783          	lh	a5,74(s1)
    8000410a:	fbf9                	bnez	a5,800040e0 <iput+0x26>
    acquiresleep(&ip->lock);
    8000410c:	01048913          	addi	s2,s1,16
    80004110:	854a                	mv	a0,s2
    80004112:	00001097          	auipc	ra,0x1
    80004116:	dce080e7          	jalr	-562(ra) # 80004ee0 <acquiresleep>
    release(&itable.lock);
    8000411a:	00025517          	auipc	a0,0x25
    8000411e:	aae50513          	addi	a0,a0,-1362 # 80028bc8 <itable>
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	b54080e7          	jalr	-1196(ra) # 80000c76 <release>
    itrunc(ip);
    8000412a:	8526                	mv	a0,s1
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	ee2080e7          	jalr	-286(ra) # 8000400e <itrunc>
    ip->type = 0;
    80004134:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004138:	8526                	mv	a0,s1
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	cfc080e7          	jalr	-772(ra) # 80003e36 <iupdate>
    ip->valid = 0;
    80004142:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004146:	854a                	mv	a0,s2
    80004148:	00001097          	auipc	ra,0x1
    8000414c:	dee080e7          	jalr	-530(ra) # 80004f36 <releasesleep>
    acquire(&itable.lock);
    80004150:	00025517          	auipc	a0,0x25
    80004154:	a7850513          	addi	a0,a0,-1416 # 80028bc8 <itable>
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	a6a080e7          	jalr	-1430(ra) # 80000bc2 <acquire>
    80004160:	b741                	j	800040e0 <iput+0x26>

0000000080004162 <iunlockput>:
{
    80004162:	1101                	addi	sp,sp,-32
    80004164:	ec06                	sd	ra,24(sp)
    80004166:	e822                	sd	s0,16(sp)
    80004168:	e426                	sd	s1,8(sp)
    8000416a:	1000                	addi	s0,sp,32
    8000416c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	e54080e7          	jalr	-428(ra) # 80003fc2 <iunlock>
  iput(ip);
    80004176:	8526                	mv	a0,s1
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	f42080e7          	jalr	-190(ra) # 800040ba <iput>
}
    80004180:	60e2                	ld	ra,24(sp)
    80004182:	6442                	ld	s0,16(sp)
    80004184:	64a2                	ld	s1,8(sp)
    80004186:	6105                	addi	sp,sp,32
    80004188:	8082                	ret

000000008000418a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000418a:	1141                	addi	sp,sp,-16
    8000418c:	e422                	sd	s0,8(sp)
    8000418e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004190:	411c                	lw	a5,0(a0)
    80004192:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004194:	415c                	lw	a5,4(a0)
    80004196:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004198:	04451783          	lh	a5,68(a0)
    8000419c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800041a0:	04a51783          	lh	a5,74(a0)
    800041a4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041a8:	04c56783          	lwu	a5,76(a0)
    800041ac:	e99c                	sd	a5,16(a1)
}
    800041ae:	6422                	ld	s0,8(sp)
    800041b0:	0141                	addi	sp,sp,16
    800041b2:	8082                	ret

00000000800041b4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041b4:	457c                	lw	a5,76(a0)
    800041b6:	0ed7e963          	bltu	a5,a3,800042a8 <readi+0xf4>
{
    800041ba:	7159                	addi	sp,sp,-112
    800041bc:	f486                	sd	ra,104(sp)
    800041be:	f0a2                	sd	s0,96(sp)
    800041c0:	eca6                	sd	s1,88(sp)
    800041c2:	e8ca                	sd	s2,80(sp)
    800041c4:	e4ce                	sd	s3,72(sp)
    800041c6:	e0d2                	sd	s4,64(sp)
    800041c8:	fc56                	sd	s5,56(sp)
    800041ca:	f85a                	sd	s6,48(sp)
    800041cc:	f45e                	sd	s7,40(sp)
    800041ce:	f062                	sd	s8,32(sp)
    800041d0:	ec66                	sd	s9,24(sp)
    800041d2:	e86a                	sd	s10,16(sp)
    800041d4:	e46e                	sd	s11,8(sp)
    800041d6:	1880                	addi	s0,sp,112
    800041d8:	8baa                	mv	s7,a0
    800041da:	8c2e                	mv	s8,a1
    800041dc:	8ab2                	mv	s5,a2
    800041de:	84b6                	mv	s1,a3
    800041e0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041e2:	9f35                	addw	a4,a4,a3
    return 0;
    800041e4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041e6:	0ad76063          	bltu	a4,a3,80004286 <readi+0xd2>
  if(off + n > ip->size)
    800041ea:	00e7f463          	bgeu	a5,a4,800041f2 <readi+0x3e>
    n = ip->size - off;
    800041ee:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041f2:	0a0b0963          	beqz	s6,800042a4 <readi+0xf0>
    800041f6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041f8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041fc:	5cfd                	li	s9,-1
    800041fe:	a82d                	j	80004238 <readi+0x84>
    80004200:	020a1d93          	slli	s11,s4,0x20
    80004204:	020ddd93          	srli	s11,s11,0x20
    80004208:	05890793          	addi	a5,s2,88
    8000420c:	86ee                	mv	a3,s11
    8000420e:	963e                	add	a2,a2,a5
    80004210:	85d6                	mv	a1,s5
    80004212:	8562                	mv	a0,s8
    80004214:	ffffe097          	auipc	ra,0xffffe
    80004218:	0e0080e7          	jalr	224(ra) # 800022f4 <either_copyout>
    8000421c:	05950d63          	beq	a0,s9,80004276 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004220:	854a                	mv	a0,s2
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	60a080e7          	jalr	1546(ra) # 8000382c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000422a:	013a09bb          	addw	s3,s4,s3
    8000422e:	009a04bb          	addw	s1,s4,s1
    80004232:	9aee                	add	s5,s5,s11
    80004234:	0569f763          	bgeu	s3,s6,80004282 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004238:	000ba903          	lw	s2,0(s7)
    8000423c:	00a4d59b          	srliw	a1,s1,0xa
    80004240:	855e                	mv	a0,s7
    80004242:	00000097          	auipc	ra,0x0
    80004246:	8ae080e7          	jalr	-1874(ra) # 80003af0 <bmap>
    8000424a:	0005059b          	sext.w	a1,a0
    8000424e:	854a                	mv	a0,s2
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	4ac080e7          	jalr	1196(ra) # 800036fc <bread>
    80004258:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000425a:	3ff4f613          	andi	a2,s1,1023
    8000425e:	40cd07bb          	subw	a5,s10,a2
    80004262:	413b073b          	subw	a4,s6,s3
    80004266:	8a3e                	mv	s4,a5
    80004268:	2781                	sext.w	a5,a5
    8000426a:	0007069b          	sext.w	a3,a4
    8000426e:	f8f6f9e3          	bgeu	a3,a5,80004200 <readi+0x4c>
    80004272:	8a3a                	mv	s4,a4
    80004274:	b771                	j	80004200 <readi+0x4c>
      brelse(bp);
    80004276:	854a                	mv	a0,s2
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	5b4080e7          	jalr	1460(ra) # 8000382c <brelse>
      tot = -1;
    80004280:	59fd                	li	s3,-1
  }
  return tot;
    80004282:	0009851b          	sext.w	a0,s3
}
    80004286:	70a6                	ld	ra,104(sp)
    80004288:	7406                	ld	s0,96(sp)
    8000428a:	64e6                	ld	s1,88(sp)
    8000428c:	6946                	ld	s2,80(sp)
    8000428e:	69a6                	ld	s3,72(sp)
    80004290:	6a06                	ld	s4,64(sp)
    80004292:	7ae2                	ld	s5,56(sp)
    80004294:	7b42                	ld	s6,48(sp)
    80004296:	7ba2                	ld	s7,40(sp)
    80004298:	7c02                	ld	s8,32(sp)
    8000429a:	6ce2                	ld	s9,24(sp)
    8000429c:	6d42                	ld	s10,16(sp)
    8000429e:	6da2                	ld	s11,8(sp)
    800042a0:	6165                	addi	sp,sp,112
    800042a2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042a4:	89da                	mv	s3,s6
    800042a6:	bff1                	j	80004282 <readi+0xce>
    return 0;
    800042a8:	4501                	li	a0,0
}
    800042aa:	8082                	ret

00000000800042ac <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042ac:	457c                	lw	a5,76(a0)
    800042ae:	10d7e863          	bltu	a5,a3,800043be <writei+0x112>
{
    800042b2:	7159                	addi	sp,sp,-112
    800042b4:	f486                	sd	ra,104(sp)
    800042b6:	f0a2                	sd	s0,96(sp)
    800042b8:	eca6                	sd	s1,88(sp)
    800042ba:	e8ca                	sd	s2,80(sp)
    800042bc:	e4ce                	sd	s3,72(sp)
    800042be:	e0d2                	sd	s4,64(sp)
    800042c0:	fc56                	sd	s5,56(sp)
    800042c2:	f85a                	sd	s6,48(sp)
    800042c4:	f45e                	sd	s7,40(sp)
    800042c6:	f062                	sd	s8,32(sp)
    800042c8:	ec66                	sd	s9,24(sp)
    800042ca:	e86a                	sd	s10,16(sp)
    800042cc:	e46e                	sd	s11,8(sp)
    800042ce:	1880                	addi	s0,sp,112
    800042d0:	8b2a                	mv	s6,a0
    800042d2:	8c2e                	mv	s8,a1
    800042d4:	8ab2                	mv	s5,a2
    800042d6:	8936                	mv	s2,a3
    800042d8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800042da:	00e687bb          	addw	a5,a3,a4
    800042de:	0ed7e263          	bltu	a5,a3,800043c2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042e2:	00043737          	lui	a4,0x43
    800042e6:	0ef76063          	bltu	a4,a5,800043c6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042ea:	0c0b8863          	beqz	s7,800043ba <writei+0x10e>
    800042ee:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042f0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042f4:	5cfd                	li	s9,-1
    800042f6:	a091                	j	8000433a <writei+0x8e>
    800042f8:	02099d93          	slli	s11,s3,0x20
    800042fc:	020ddd93          	srli	s11,s11,0x20
    80004300:	05848793          	addi	a5,s1,88
    80004304:	86ee                	mv	a3,s11
    80004306:	8656                	mv	a2,s5
    80004308:	85e2                	mv	a1,s8
    8000430a:	953e                	add	a0,a0,a5
    8000430c:	ffffe097          	auipc	ra,0xffffe
    80004310:	03e080e7          	jalr	62(ra) # 8000234a <either_copyin>
    80004314:	07950263          	beq	a0,s9,80004378 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004318:	8526                	mv	a0,s1
    8000431a:	00001097          	auipc	ra,0x1
    8000431e:	aa6080e7          	jalr	-1370(ra) # 80004dc0 <log_write>
    brelse(bp);
    80004322:	8526                	mv	a0,s1
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	508080e7          	jalr	1288(ra) # 8000382c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000432c:	01498a3b          	addw	s4,s3,s4
    80004330:	0129893b          	addw	s2,s3,s2
    80004334:	9aee                	add	s5,s5,s11
    80004336:	057a7663          	bgeu	s4,s7,80004382 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000433a:	000b2483          	lw	s1,0(s6)
    8000433e:	00a9559b          	srliw	a1,s2,0xa
    80004342:	855a                	mv	a0,s6
    80004344:	fffff097          	auipc	ra,0xfffff
    80004348:	7ac080e7          	jalr	1964(ra) # 80003af0 <bmap>
    8000434c:	0005059b          	sext.w	a1,a0
    80004350:	8526                	mv	a0,s1
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	3aa080e7          	jalr	938(ra) # 800036fc <bread>
    8000435a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000435c:	3ff97513          	andi	a0,s2,1023
    80004360:	40ad07bb          	subw	a5,s10,a0
    80004364:	414b873b          	subw	a4,s7,s4
    80004368:	89be                	mv	s3,a5
    8000436a:	2781                	sext.w	a5,a5
    8000436c:	0007069b          	sext.w	a3,a4
    80004370:	f8f6f4e3          	bgeu	a3,a5,800042f8 <writei+0x4c>
    80004374:	89ba                	mv	s3,a4
    80004376:	b749                	j	800042f8 <writei+0x4c>
      brelse(bp);
    80004378:	8526                	mv	a0,s1
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	4b2080e7          	jalr	1202(ra) # 8000382c <brelse>
  }

  if(off > ip->size)
    80004382:	04cb2783          	lw	a5,76(s6)
    80004386:	0127f463          	bgeu	a5,s2,8000438e <writei+0xe2>
    ip->size = off;
    8000438a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000438e:	855a                	mv	a0,s6
    80004390:	00000097          	auipc	ra,0x0
    80004394:	aa6080e7          	jalr	-1370(ra) # 80003e36 <iupdate>

  return tot;
    80004398:	000a051b          	sext.w	a0,s4
}
    8000439c:	70a6                	ld	ra,104(sp)
    8000439e:	7406                	ld	s0,96(sp)
    800043a0:	64e6                	ld	s1,88(sp)
    800043a2:	6946                	ld	s2,80(sp)
    800043a4:	69a6                	ld	s3,72(sp)
    800043a6:	6a06                	ld	s4,64(sp)
    800043a8:	7ae2                	ld	s5,56(sp)
    800043aa:	7b42                	ld	s6,48(sp)
    800043ac:	7ba2                	ld	s7,40(sp)
    800043ae:	7c02                	ld	s8,32(sp)
    800043b0:	6ce2                	ld	s9,24(sp)
    800043b2:	6d42                	ld	s10,16(sp)
    800043b4:	6da2                	ld	s11,8(sp)
    800043b6:	6165                	addi	sp,sp,112
    800043b8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043ba:	8a5e                	mv	s4,s7
    800043bc:	bfc9                	j	8000438e <writei+0xe2>
    return -1;
    800043be:	557d                	li	a0,-1
}
    800043c0:	8082                	ret
    return -1;
    800043c2:	557d                	li	a0,-1
    800043c4:	bfe1                	j	8000439c <writei+0xf0>
    return -1;
    800043c6:	557d                	li	a0,-1
    800043c8:	bfd1                	j	8000439c <writei+0xf0>

00000000800043ca <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043ca:	1141                	addi	sp,sp,-16
    800043cc:	e406                	sd	ra,8(sp)
    800043ce:	e022                	sd	s0,0(sp)
    800043d0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043d2:	4639                	li	a2,14
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	9c2080e7          	jalr	-1598(ra) # 80000d96 <strncmp>
}
    800043dc:	60a2                	ld	ra,8(sp)
    800043de:	6402                	ld	s0,0(sp)
    800043e0:	0141                	addi	sp,sp,16
    800043e2:	8082                	ret

00000000800043e4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043e4:	7139                	addi	sp,sp,-64
    800043e6:	fc06                	sd	ra,56(sp)
    800043e8:	f822                	sd	s0,48(sp)
    800043ea:	f426                	sd	s1,40(sp)
    800043ec:	f04a                	sd	s2,32(sp)
    800043ee:	ec4e                	sd	s3,24(sp)
    800043f0:	e852                	sd	s4,16(sp)
    800043f2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043f4:	04451703          	lh	a4,68(a0)
    800043f8:	4785                	li	a5,1
    800043fa:	00f71a63          	bne	a4,a5,8000440e <dirlookup+0x2a>
    800043fe:	892a                	mv	s2,a0
    80004400:	89ae                	mv	s3,a1
    80004402:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004404:	457c                	lw	a5,76(a0)
    80004406:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004408:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000440a:	e79d                	bnez	a5,80004438 <dirlookup+0x54>
    8000440c:	a8a5                	j	80004484 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000440e:	00005517          	auipc	a0,0x5
    80004412:	4b250513          	addi	a0,a0,1202 # 800098c0 <syscalls+0x1a0>
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	114080e7          	jalr	276(ra) # 8000052a <panic>
      panic("dirlookup read");
    8000441e:	00005517          	auipc	a0,0x5
    80004422:	4ba50513          	addi	a0,a0,1210 # 800098d8 <syscalls+0x1b8>
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	104080e7          	jalr	260(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442e:	24c1                	addiw	s1,s1,16
    80004430:	04c92783          	lw	a5,76(s2)
    80004434:	04f4f763          	bgeu	s1,a5,80004482 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004438:	4741                	li	a4,16
    8000443a:	86a6                	mv	a3,s1
    8000443c:	fc040613          	addi	a2,s0,-64
    80004440:	4581                	li	a1,0
    80004442:	854a                	mv	a0,s2
    80004444:	00000097          	auipc	ra,0x0
    80004448:	d70080e7          	jalr	-656(ra) # 800041b4 <readi>
    8000444c:	47c1                	li	a5,16
    8000444e:	fcf518e3          	bne	a0,a5,8000441e <dirlookup+0x3a>
    if(de.inum == 0)
    80004452:	fc045783          	lhu	a5,-64(s0)
    80004456:	dfe1                	beqz	a5,8000442e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004458:	fc240593          	addi	a1,s0,-62
    8000445c:	854e                	mv	a0,s3
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	f6c080e7          	jalr	-148(ra) # 800043ca <namecmp>
    80004466:	f561                	bnez	a0,8000442e <dirlookup+0x4a>
      if(poff)
    80004468:	000a0463          	beqz	s4,80004470 <dirlookup+0x8c>
        *poff = off;
    8000446c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004470:	fc045583          	lhu	a1,-64(s0)
    80004474:	00092503          	lw	a0,0(s2)
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	754080e7          	jalr	1876(ra) # 80003bcc <iget>
    80004480:	a011                	j	80004484 <dirlookup+0xa0>
  return 0;
    80004482:	4501                	li	a0,0
}
    80004484:	70e2                	ld	ra,56(sp)
    80004486:	7442                	ld	s0,48(sp)
    80004488:	74a2                	ld	s1,40(sp)
    8000448a:	7902                	ld	s2,32(sp)
    8000448c:	69e2                	ld	s3,24(sp)
    8000448e:	6a42                	ld	s4,16(sp)
    80004490:	6121                	addi	sp,sp,64
    80004492:	8082                	ret

0000000080004494 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004494:	711d                	addi	sp,sp,-96
    80004496:	ec86                	sd	ra,88(sp)
    80004498:	e8a2                	sd	s0,80(sp)
    8000449a:	e4a6                	sd	s1,72(sp)
    8000449c:	e0ca                	sd	s2,64(sp)
    8000449e:	fc4e                	sd	s3,56(sp)
    800044a0:	f852                	sd	s4,48(sp)
    800044a2:	f456                	sd	s5,40(sp)
    800044a4:	f05a                	sd	s6,32(sp)
    800044a6:	ec5e                	sd	s7,24(sp)
    800044a8:	e862                	sd	s8,16(sp)
    800044aa:	e466                	sd	s9,8(sp)
    800044ac:	1080                	addi	s0,sp,96
    800044ae:	84aa                	mv	s1,a0
    800044b0:	8aae                	mv	s5,a1
    800044b2:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044b4:	00054703          	lbu	a4,0(a0)
    800044b8:	02f00793          	li	a5,47
    800044bc:	02f70363          	beq	a4,a5,800044e2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044c0:	ffffd097          	auipc	ra,0xffffd
    800044c4:	544080e7          	jalr	1348(ra) # 80001a04 <myproc>
    800044c8:	15053503          	ld	a0,336(a0)
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	9f6080e7          	jalr	-1546(ra) # 80003ec2 <idup>
    800044d4:	89aa                	mv	s3,a0
  while(*path == '/')
    800044d6:	02f00913          	li	s2,47
  len = path - s;
    800044da:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800044dc:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044de:	4b85                	li	s7,1
    800044e0:	a865                	j	80004598 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044e2:	4585                	li	a1,1
    800044e4:	4505                	li	a0,1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	6e6080e7          	jalr	1766(ra) # 80003bcc <iget>
    800044ee:	89aa                	mv	s3,a0
    800044f0:	b7dd                	j	800044d6 <namex+0x42>
      iunlockput(ip);
    800044f2:	854e                	mv	a0,s3
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	c6e080e7          	jalr	-914(ra) # 80004162 <iunlockput>
      return 0;
    800044fc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044fe:	854e                	mv	a0,s3
    80004500:	60e6                	ld	ra,88(sp)
    80004502:	6446                	ld	s0,80(sp)
    80004504:	64a6                	ld	s1,72(sp)
    80004506:	6906                	ld	s2,64(sp)
    80004508:	79e2                	ld	s3,56(sp)
    8000450a:	7a42                	ld	s4,48(sp)
    8000450c:	7aa2                	ld	s5,40(sp)
    8000450e:	7b02                	ld	s6,32(sp)
    80004510:	6be2                	ld	s7,24(sp)
    80004512:	6c42                	ld	s8,16(sp)
    80004514:	6ca2                	ld	s9,8(sp)
    80004516:	6125                	addi	sp,sp,96
    80004518:	8082                	ret
      iunlock(ip);
    8000451a:	854e                	mv	a0,s3
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	aa6080e7          	jalr	-1370(ra) # 80003fc2 <iunlock>
      return ip;
    80004524:	bfe9                	j	800044fe <namex+0x6a>
      iunlockput(ip);
    80004526:	854e                	mv	a0,s3
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	c3a080e7          	jalr	-966(ra) # 80004162 <iunlockput>
      return 0;
    80004530:	89e6                	mv	s3,s9
    80004532:	b7f1                	j	800044fe <namex+0x6a>
  len = path - s;
    80004534:	40b48633          	sub	a2,s1,a1
    80004538:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000453c:	099c5463          	bge	s8,s9,800045c4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004540:	4639                	li	a2,14
    80004542:	8552                	mv	a0,s4
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	7d6080e7          	jalr	2006(ra) # 80000d1a <memmove>
  while(*path == '/')
    8000454c:	0004c783          	lbu	a5,0(s1)
    80004550:	01279763          	bne	a5,s2,8000455e <namex+0xca>
    path++;
    80004554:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004556:	0004c783          	lbu	a5,0(s1)
    8000455a:	ff278de3          	beq	a5,s2,80004554 <namex+0xc0>
    ilock(ip);
    8000455e:	854e                	mv	a0,s3
    80004560:	00000097          	auipc	ra,0x0
    80004564:	9a0080e7          	jalr	-1632(ra) # 80003f00 <ilock>
    if(ip->type != T_DIR){
    80004568:	04499783          	lh	a5,68(s3)
    8000456c:	f97793e3          	bne	a5,s7,800044f2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004570:	000a8563          	beqz	s5,8000457a <namex+0xe6>
    80004574:	0004c783          	lbu	a5,0(s1)
    80004578:	d3cd                	beqz	a5,8000451a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000457a:	865a                	mv	a2,s6
    8000457c:	85d2                	mv	a1,s4
    8000457e:	854e                	mv	a0,s3
    80004580:	00000097          	auipc	ra,0x0
    80004584:	e64080e7          	jalr	-412(ra) # 800043e4 <dirlookup>
    80004588:	8caa                	mv	s9,a0
    8000458a:	dd51                	beqz	a0,80004526 <namex+0x92>
    iunlockput(ip);
    8000458c:	854e                	mv	a0,s3
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	bd4080e7          	jalr	-1068(ra) # 80004162 <iunlockput>
    ip = next;
    80004596:	89e6                	mv	s3,s9
  while(*path == '/')
    80004598:	0004c783          	lbu	a5,0(s1)
    8000459c:	05279763          	bne	a5,s2,800045ea <namex+0x156>
    path++;
    800045a0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045a2:	0004c783          	lbu	a5,0(s1)
    800045a6:	ff278de3          	beq	a5,s2,800045a0 <namex+0x10c>
  if(*path == 0)
    800045aa:	c79d                	beqz	a5,800045d8 <namex+0x144>
    path++;
    800045ac:	85a6                	mv	a1,s1
  len = path - s;
    800045ae:	8cda                	mv	s9,s6
    800045b0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800045b2:	01278963          	beq	a5,s2,800045c4 <namex+0x130>
    800045b6:	dfbd                	beqz	a5,80004534 <namex+0xa0>
    path++;
    800045b8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800045ba:	0004c783          	lbu	a5,0(s1)
    800045be:	ff279ce3          	bne	a5,s2,800045b6 <namex+0x122>
    800045c2:	bf8d                	j	80004534 <namex+0xa0>
    memmove(name, s, len);
    800045c4:	2601                	sext.w	a2,a2
    800045c6:	8552                	mv	a0,s4
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	752080e7          	jalr	1874(ra) # 80000d1a <memmove>
    name[len] = 0;
    800045d0:	9cd2                	add	s9,s9,s4
    800045d2:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045d6:	bf9d                	j	8000454c <namex+0xb8>
  if(nameiparent){
    800045d8:	f20a83e3          	beqz	s5,800044fe <namex+0x6a>
    iput(ip);
    800045dc:	854e                	mv	a0,s3
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	adc080e7          	jalr	-1316(ra) # 800040ba <iput>
    return 0;
    800045e6:	4981                	li	s3,0
    800045e8:	bf19                	j	800044fe <namex+0x6a>
  if(*path == 0)
    800045ea:	d7fd                	beqz	a5,800045d8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800045ec:	0004c783          	lbu	a5,0(s1)
    800045f0:	85a6                	mv	a1,s1
    800045f2:	b7d1                	j	800045b6 <namex+0x122>

00000000800045f4 <dirlink>:
{
    800045f4:	7139                	addi	sp,sp,-64
    800045f6:	fc06                	sd	ra,56(sp)
    800045f8:	f822                	sd	s0,48(sp)
    800045fa:	f426                	sd	s1,40(sp)
    800045fc:	f04a                	sd	s2,32(sp)
    800045fe:	ec4e                	sd	s3,24(sp)
    80004600:	e852                	sd	s4,16(sp)
    80004602:	0080                	addi	s0,sp,64
    80004604:	892a                	mv	s2,a0
    80004606:	8a2e                	mv	s4,a1
    80004608:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000460a:	4601                	li	a2,0
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	dd8080e7          	jalr	-552(ra) # 800043e4 <dirlookup>
    80004614:	e93d                	bnez	a0,8000468a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004616:	04c92483          	lw	s1,76(s2)
    8000461a:	c49d                	beqz	s1,80004648 <dirlink+0x54>
    8000461c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000461e:	4741                	li	a4,16
    80004620:	86a6                	mv	a3,s1
    80004622:	fc040613          	addi	a2,s0,-64
    80004626:	4581                	li	a1,0
    80004628:	854a                	mv	a0,s2
    8000462a:	00000097          	auipc	ra,0x0
    8000462e:	b8a080e7          	jalr	-1142(ra) # 800041b4 <readi>
    80004632:	47c1                	li	a5,16
    80004634:	06f51163          	bne	a0,a5,80004696 <dirlink+0xa2>
    if(de.inum == 0)
    80004638:	fc045783          	lhu	a5,-64(s0)
    8000463c:	c791                	beqz	a5,80004648 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000463e:	24c1                	addiw	s1,s1,16
    80004640:	04c92783          	lw	a5,76(s2)
    80004644:	fcf4ede3          	bltu	s1,a5,8000461e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004648:	4639                	li	a2,14
    8000464a:	85d2                	mv	a1,s4
    8000464c:	fc240513          	addi	a0,s0,-62
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	782080e7          	jalr	1922(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004658:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000465c:	4741                	li	a4,16
    8000465e:	86a6                	mv	a3,s1
    80004660:	fc040613          	addi	a2,s0,-64
    80004664:	4581                	li	a1,0
    80004666:	854a                	mv	a0,s2
    80004668:	00000097          	auipc	ra,0x0
    8000466c:	c44080e7          	jalr	-956(ra) # 800042ac <writei>
    80004670:	872a                	mv	a4,a0
    80004672:	47c1                	li	a5,16
  return 0;
    80004674:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004676:	02f71863          	bne	a4,a5,800046a6 <dirlink+0xb2>
}
    8000467a:	70e2                	ld	ra,56(sp)
    8000467c:	7442                	ld	s0,48(sp)
    8000467e:	74a2                	ld	s1,40(sp)
    80004680:	7902                	ld	s2,32(sp)
    80004682:	69e2                	ld	s3,24(sp)
    80004684:	6a42                	ld	s4,16(sp)
    80004686:	6121                	addi	sp,sp,64
    80004688:	8082                	ret
    iput(ip);
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	a30080e7          	jalr	-1488(ra) # 800040ba <iput>
    return -1;
    80004692:	557d                	li	a0,-1
    80004694:	b7dd                	j	8000467a <dirlink+0x86>
      panic("dirlink read");
    80004696:	00005517          	auipc	a0,0x5
    8000469a:	25250513          	addi	a0,a0,594 # 800098e8 <syscalls+0x1c8>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	e8c080e7          	jalr	-372(ra) # 8000052a <panic>
    panic("dirlink");
    800046a6:	00005517          	auipc	a0,0x5
    800046aa:	3ca50513          	addi	a0,a0,970 # 80009a70 <syscalls+0x350>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	e7c080e7          	jalr	-388(ra) # 8000052a <panic>

00000000800046b6 <namei>:

struct inode*
namei(char *path)
{
    800046b6:	1101                	addi	sp,sp,-32
    800046b8:	ec06                	sd	ra,24(sp)
    800046ba:	e822                	sd	s0,16(sp)
    800046bc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046be:	fe040613          	addi	a2,s0,-32
    800046c2:	4581                	li	a1,0
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	dd0080e7          	jalr	-560(ra) # 80004494 <namex>
}
    800046cc:	60e2                	ld	ra,24(sp)
    800046ce:	6442                	ld	s0,16(sp)
    800046d0:	6105                	addi	sp,sp,32
    800046d2:	8082                	ret

00000000800046d4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046d4:	1141                	addi	sp,sp,-16
    800046d6:	e406                	sd	ra,8(sp)
    800046d8:	e022                	sd	s0,0(sp)
    800046da:	0800                	addi	s0,sp,16
    800046dc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046de:	4585                	li	a1,1
    800046e0:	00000097          	auipc	ra,0x0
    800046e4:	db4080e7          	jalr	-588(ra) # 80004494 <namex>
}
    800046e8:	60a2                	ld	ra,8(sp)
    800046ea:	6402                	ld	s0,0(sp)
    800046ec:	0141                	addi	sp,sp,16
    800046ee:	8082                	ret

00000000800046f0 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800046f0:	1101                	addi	sp,sp,-32
    800046f2:	ec22                	sd	s0,24(sp)
    800046f4:	1000                	addi	s0,sp,32
    800046f6:	872a                	mv	a4,a0
    800046f8:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800046fa:	00005797          	auipc	a5,0x5
    800046fe:	1fe78793          	addi	a5,a5,510 # 800098f8 <syscalls+0x1d8>
    80004702:	6394                	ld	a3,0(a5)
    80004704:	fed43023          	sd	a3,-32(s0)
    80004708:	0087d683          	lhu	a3,8(a5)
    8000470c:	fed41423          	sh	a3,-24(s0)
    80004710:	00a7c783          	lbu	a5,10(a5)
    80004714:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    80004718:	87ae                	mv	a5,a1
    if(i<0){
    8000471a:	02074b63          	bltz	a4,80004750 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    8000471e:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    80004720:	4629                	li	a2,10
        ++p;
    80004722:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004724:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    80004728:	feed                	bnez	a3,80004722 <itoa+0x32>
    *p = '\0';
    8000472a:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    8000472e:	4629                	li	a2,10
    80004730:	17fd                	addi	a5,a5,-1
    80004732:	02c766bb          	remw	a3,a4,a2
    80004736:	ff040593          	addi	a1,s0,-16
    8000473a:	96ae                	add	a3,a3,a1
    8000473c:	ff06c683          	lbu	a3,-16(a3)
    80004740:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004744:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004748:	f765                	bnez	a4,80004730 <itoa+0x40>
    return b;
}
    8000474a:	6462                	ld	s0,24(sp)
    8000474c:	6105                	addi	sp,sp,32
    8000474e:	8082                	ret
        *p++ = '-';
    80004750:	00158793          	addi	a5,a1,1
    80004754:	02d00693          	li	a3,45
    80004758:	00d58023          	sb	a3,0(a1)
        i *= -1;
    8000475c:	40e0073b          	negw	a4,a4
    80004760:	bf7d                	j	8000471e <itoa+0x2e>

0000000080004762 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004762:	711d                	addi	sp,sp,-96
    80004764:	ec86                	sd	ra,88(sp)
    80004766:	e8a2                	sd	s0,80(sp)
    80004768:	e4a6                	sd	s1,72(sp)
    8000476a:	e0ca                	sd	s2,64(sp)
    8000476c:	1080                	addi	s0,sp,96
    8000476e:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004770:	4619                	li	a2,6
    80004772:	00005597          	auipc	a1,0x5
    80004776:	19658593          	addi	a1,a1,406 # 80009908 <syscalls+0x1e8>
    8000477a:	fd040513          	addi	a0,s0,-48
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	59c080e7          	jalr	1436(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004786:	fd640593          	addi	a1,s0,-42
    8000478a:	5888                	lw	a0,48(s1)
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	f64080e7          	jalr	-156(ra) # 800046f0 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004794:	1684b503          	ld	a0,360(s1)
    80004798:	16050763          	beqz	a0,80004906 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000479c:	00001097          	auipc	ra,0x1
    800047a0:	918080e7          	jalr	-1768(ra) # 800050b4 <fileclose>

  begin_op();
    800047a4:	00000097          	auipc	ra,0x0
    800047a8:	444080e7          	jalr	1092(ra) # 80004be8 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    800047ac:	fb040593          	addi	a1,s0,-80
    800047b0:	fd040513          	addi	a0,s0,-48
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	f20080e7          	jalr	-224(ra) # 800046d4 <nameiparent>
    800047bc:	892a                	mv	s2,a0
    800047be:	cd69                	beqz	a0,80004898 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	740080e7          	jalr	1856(ra) # 80003f00 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800047c8:	00005597          	auipc	a1,0x5
    800047cc:	14858593          	addi	a1,a1,328 # 80009910 <syscalls+0x1f0>
    800047d0:	fb040513          	addi	a0,s0,-80
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	bf6080e7          	jalr	-1034(ra) # 800043ca <namecmp>
    800047dc:	c57d                	beqz	a0,800048ca <removeSwapFile+0x168>
    800047de:	00005597          	auipc	a1,0x5
    800047e2:	13a58593          	addi	a1,a1,314 # 80009918 <syscalls+0x1f8>
    800047e6:	fb040513          	addi	a0,s0,-80
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	be0080e7          	jalr	-1056(ra) # 800043ca <namecmp>
    800047f2:	cd61                	beqz	a0,800048ca <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800047f4:	fac40613          	addi	a2,s0,-84
    800047f8:	fb040593          	addi	a1,s0,-80
    800047fc:	854a                	mv	a0,s2
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	be6080e7          	jalr	-1050(ra) # 800043e4 <dirlookup>
    80004806:	84aa                	mv	s1,a0
    80004808:	c169                	beqz	a0,800048ca <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	6f6080e7          	jalr	1782(ra) # 80003f00 <ilock>

  if(ip->nlink < 1)
    80004812:	04a49783          	lh	a5,74(s1)
    80004816:	08f05763          	blez	a5,800048a4 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000481a:	04449703          	lh	a4,68(s1)
    8000481e:	4785                	li	a5,1
    80004820:	08f70a63          	beq	a4,a5,800048b4 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004824:	4641                	li	a2,16
    80004826:	4581                	li	a1,0
    80004828:	fc040513          	addi	a0,s0,-64
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	492080e7          	jalr	1170(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004834:	4741                	li	a4,16
    80004836:	fac42683          	lw	a3,-84(s0)
    8000483a:	fc040613          	addi	a2,s0,-64
    8000483e:	4581                	li	a1,0
    80004840:	854a                	mv	a0,s2
    80004842:	00000097          	auipc	ra,0x0
    80004846:	a6a080e7          	jalr	-1430(ra) # 800042ac <writei>
    8000484a:	47c1                	li	a5,16
    8000484c:	08f51a63          	bne	a0,a5,800048e0 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80004850:	04449703          	lh	a4,68(s1)
    80004854:	4785                	li	a5,1
    80004856:	08f70d63          	beq	a4,a5,800048f0 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000485a:	854a                	mv	a0,s2
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	906080e7          	jalr	-1786(ra) # 80004162 <iunlockput>

  ip->nlink--;
    80004864:	04a4d783          	lhu	a5,74(s1)
    80004868:	37fd                	addiw	a5,a5,-1
    8000486a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000486e:	8526                	mv	a0,s1
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	5c6080e7          	jalr	1478(ra) # 80003e36 <iupdate>
  iunlockput(ip);
    80004878:	8526                	mv	a0,s1
    8000487a:	00000097          	auipc	ra,0x0
    8000487e:	8e8080e7          	jalr	-1816(ra) # 80004162 <iunlockput>

  end_op();
    80004882:	00000097          	auipc	ra,0x0
    80004886:	3e6080e7          	jalr	998(ra) # 80004c68 <end_op>

  return 0;
    8000488a:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    8000488c:	60e6                	ld	ra,88(sp)
    8000488e:	6446                	ld	s0,80(sp)
    80004890:	64a6                	ld	s1,72(sp)
    80004892:	6906                	ld	s2,64(sp)
    80004894:	6125                	addi	sp,sp,96
    80004896:	8082                	ret
    end_op();
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	3d0080e7          	jalr	976(ra) # 80004c68 <end_op>
    return -1;
    800048a0:	557d                	li	a0,-1
    800048a2:	b7ed                	j	8000488c <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    800048a4:	00005517          	auipc	a0,0x5
    800048a8:	07c50513          	addi	a0,a0,124 # 80009920 <syscalls+0x200>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	c7e080e7          	jalr	-898(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800048b4:	8526                	mv	a0,s1
    800048b6:	00002097          	auipc	ra,0x2
    800048ba:	866080e7          	jalr	-1946(ra) # 8000611c <isdirempty>
    800048be:	f13d                	bnez	a0,80004824 <removeSwapFile+0xc2>
    iunlockput(ip);
    800048c0:	8526                	mv	a0,s1
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	8a0080e7          	jalr	-1888(ra) # 80004162 <iunlockput>
    iunlockput(dp);
    800048ca:	854a                	mv	a0,s2
    800048cc:	00000097          	auipc	ra,0x0
    800048d0:	896080e7          	jalr	-1898(ra) # 80004162 <iunlockput>
    end_op();
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	394080e7          	jalr	916(ra) # 80004c68 <end_op>
    return -1;
    800048dc:	557d                	li	a0,-1
    800048de:	b77d                	j	8000488c <removeSwapFile+0x12a>
    panic("unlink: writei");
    800048e0:	00005517          	auipc	a0,0x5
    800048e4:	05850513          	addi	a0,a0,88 # 80009938 <syscalls+0x218>
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	c42080e7          	jalr	-958(ra) # 8000052a <panic>
    dp->nlink--;
    800048f0:	04a95783          	lhu	a5,74(s2)
    800048f4:	37fd                	addiw	a5,a5,-1
    800048f6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800048fa:	854a                	mv	a0,s2
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	53a080e7          	jalr	1338(ra) # 80003e36 <iupdate>
    80004904:	bf99                	j	8000485a <removeSwapFile+0xf8>
    return -1;
    80004906:	557d                	li	a0,-1
    80004908:	b751                	j	8000488c <removeSwapFile+0x12a>

000000008000490a <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    8000490a:	7179                	addi	sp,sp,-48
    8000490c:	f406                	sd	ra,40(sp)
    8000490e:	f022                	sd	s0,32(sp)
    80004910:	ec26                	sd	s1,24(sp)
    80004912:	e84a                	sd	s2,16(sp)
    80004914:	1800                	addi	s0,sp,48
    80004916:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004918:	4619                	li	a2,6
    8000491a:	00005597          	auipc	a1,0x5
    8000491e:	fee58593          	addi	a1,a1,-18 # 80009908 <syscalls+0x1e8>
    80004922:	fd040513          	addi	a0,s0,-48
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	3f4080e7          	jalr	1012(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    8000492e:	fd640593          	addi	a1,s0,-42
    80004932:	5888                	lw	a0,48(s1)
    80004934:	00000097          	auipc	ra,0x0
    80004938:	dbc080e7          	jalr	-580(ra) # 800046f0 <itoa>

  begin_op();
    8000493c:	00000097          	auipc	ra,0x0
    80004940:	2ac080e7          	jalr	684(ra) # 80004be8 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004944:	4681                	li	a3,0
    80004946:	4601                	li	a2,0
    80004948:	4589                	li	a1,2
    8000494a:	fd040513          	addi	a0,s0,-48
    8000494e:	00002097          	auipc	ra,0x2
    80004952:	9c2080e7          	jalr	-1598(ra) # 80006310 <create>
    80004956:	892a                	mv	s2,a0
  iunlock(in);
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	66a080e7          	jalr	1642(ra) # 80003fc2 <iunlock>
  p->swapFile = filealloc();
    80004960:	00000097          	auipc	ra,0x0
    80004964:	698080e7          	jalr	1688(ra) # 80004ff8 <filealloc>
    80004968:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    8000496c:	cd1d                	beqz	a0,800049aa <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000496e:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004972:	1684b703          	ld	a4,360(s1)
    80004976:	4789                	li	a5,2
    80004978:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    8000497a:	1684b703          	ld	a4,360(s1)
    8000497e:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004982:	1684b703          	ld	a4,360(s1)
    80004986:	4685                	li	a3,1
    80004988:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    8000498c:	1684b703          	ld	a4,360(s1)
    80004990:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004994:	00000097          	auipc	ra,0x0
    80004998:	2d4080e7          	jalr	724(ra) # 80004c68 <end_op>

    return 0;
}
    8000499c:	4501                	li	a0,0
    8000499e:	70a2                	ld	ra,40(sp)
    800049a0:	7402                	ld	s0,32(sp)
    800049a2:	64e2                	ld	s1,24(sp)
    800049a4:	6942                	ld	s2,16(sp)
    800049a6:	6145                	addi	sp,sp,48
    800049a8:	8082                	ret
    panic("no slot for files on /store");
    800049aa:	00005517          	auipc	a0,0x5
    800049ae:	f9e50513          	addi	a0,a0,-98 # 80009948 <syscalls+0x228>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	b78080e7          	jalr	-1160(ra) # 8000052a <panic>

00000000800049ba <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800049ba:	1141                	addi	sp,sp,-16
    800049bc:	e406                	sd	ra,8(sp)
    800049be:	e022                	sd	s0,0(sp)
    800049c0:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800049c2:	16853783          	ld	a5,360(a0)
    800049c6:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    800049c8:	8636                	mv	a2,a3
    800049ca:	16853503          	ld	a0,360(a0)
    800049ce:	00001097          	auipc	ra,0x1
    800049d2:	ad8080e7          	jalr	-1320(ra) # 800054a6 <kfilewrite>
}
    800049d6:	60a2                	ld	ra,8(sp)
    800049d8:	6402                	ld	s0,0(sp)
    800049da:	0141                	addi	sp,sp,16
    800049dc:	8082                	ret

00000000800049de <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800049de:	1141                	addi	sp,sp,-16
    800049e0:	e406                	sd	ra,8(sp)
    800049e2:	e022                	sd	s0,0(sp)
    800049e4:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800049e6:	16853783          	ld	a5,360(a0)
    800049ea:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    800049ec:	8636                	mv	a2,a3
    800049ee:	16853503          	ld	a0,360(a0)
    800049f2:	00001097          	auipc	ra,0x1
    800049f6:	9f2080e7          	jalr	-1550(ra) # 800053e4 <kfileread>
    800049fa:	60a2                	ld	ra,8(sp)
    800049fc:	6402                	ld	s0,0(sp)
    800049fe:	0141                	addi	sp,sp,16
    80004a00:	8082                	ret

0000000080004a02 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a02:	1101                	addi	sp,sp,-32
    80004a04:	ec06                	sd	ra,24(sp)
    80004a06:	e822                	sd	s0,16(sp)
    80004a08:	e426                	sd	s1,8(sp)
    80004a0a:	e04a                	sd	s2,0(sp)
    80004a0c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004a0e:	00026917          	auipc	s2,0x26
    80004a12:	c6290913          	addi	s2,s2,-926 # 8002a670 <log>
    80004a16:	01892583          	lw	a1,24(s2)
    80004a1a:	02892503          	lw	a0,40(s2)
    80004a1e:	fffff097          	auipc	ra,0xfffff
    80004a22:	cde080e7          	jalr	-802(ra) # 800036fc <bread>
    80004a26:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004a28:	02c92683          	lw	a3,44(s2)
    80004a2c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004a2e:	02d05863          	blez	a3,80004a5e <write_head+0x5c>
    80004a32:	00026797          	auipc	a5,0x26
    80004a36:	c6e78793          	addi	a5,a5,-914 # 8002a6a0 <log+0x30>
    80004a3a:	05c50713          	addi	a4,a0,92
    80004a3e:	36fd                	addiw	a3,a3,-1
    80004a40:	02069613          	slli	a2,a3,0x20
    80004a44:	01e65693          	srli	a3,a2,0x1e
    80004a48:	00026617          	auipc	a2,0x26
    80004a4c:	c5c60613          	addi	a2,a2,-932 # 8002a6a4 <log+0x34>
    80004a50:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004a52:	4390                	lw	a2,0(a5)
    80004a54:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a56:	0791                	addi	a5,a5,4
    80004a58:	0711                	addi	a4,a4,4
    80004a5a:	fed79ce3          	bne	a5,a3,80004a52 <write_head+0x50>
  }
  bwrite(buf);
    80004a5e:	8526                	mv	a0,s1
    80004a60:	fffff097          	auipc	ra,0xfffff
    80004a64:	d8e080e7          	jalr	-626(ra) # 800037ee <bwrite>
  brelse(buf);
    80004a68:	8526                	mv	a0,s1
    80004a6a:	fffff097          	auipc	ra,0xfffff
    80004a6e:	dc2080e7          	jalr	-574(ra) # 8000382c <brelse>
}
    80004a72:	60e2                	ld	ra,24(sp)
    80004a74:	6442                	ld	s0,16(sp)
    80004a76:	64a2                	ld	s1,8(sp)
    80004a78:	6902                	ld	s2,0(sp)
    80004a7a:	6105                	addi	sp,sp,32
    80004a7c:	8082                	ret

0000000080004a7e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a7e:	00026797          	auipc	a5,0x26
    80004a82:	c1e7a783          	lw	a5,-994(a5) # 8002a69c <log+0x2c>
    80004a86:	0af05d63          	blez	a5,80004b40 <install_trans+0xc2>
{
    80004a8a:	7139                	addi	sp,sp,-64
    80004a8c:	fc06                	sd	ra,56(sp)
    80004a8e:	f822                	sd	s0,48(sp)
    80004a90:	f426                	sd	s1,40(sp)
    80004a92:	f04a                	sd	s2,32(sp)
    80004a94:	ec4e                	sd	s3,24(sp)
    80004a96:	e852                	sd	s4,16(sp)
    80004a98:	e456                	sd	s5,8(sp)
    80004a9a:	e05a                	sd	s6,0(sp)
    80004a9c:	0080                	addi	s0,sp,64
    80004a9e:	8b2a                	mv	s6,a0
    80004aa0:	00026a97          	auipc	s5,0x26
    80004aa4:	c00a8a93          	addi	s5,s5,-1024 # 8002a6a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004aa8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004aaa:	00026997          	auipc	s3,0x26
    80004aae:	bc698993          	addi	s3,s3,-1082 # 8002a670 <log>
    80004ab2:	a00d                	j	80004ad4 <install_trans+0x56>
    brelse(lbuf);
    80004ab4:	854a                	mv	a0,s2
    80004ab6:	fffff097          	auipc	ra,0xfffff
    80004aba:	d76080e7          	jalr	-650(ra) # 8000382c <brelse>
    brelse(dbuf);
    80004abe:	8526                	mv	a0,s1
    80004ac0:	fffff097          	auipc	ra,0xfffff
    80004ac4:	d6c080e7          	jalr	-660(ra) # 8000382c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ac8:	2a05                	addiw	s4,s4,1
    80004aca:	0a91                	addi	s5,s5,4
    80004acc:	02c9a783          	lw	a5,44(s3)
    80004ad0:	04fa5e63          	bge	s4,a5,80004b2c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004ad4:	0189a583          	lw	a1,24(s3)
    80004ad8:	014585bb          	addw	a1,a1,s4
    80004adc:	2585                	addiw	a1,a1,1
    80004ade:	0289a503          	lw	a0,40(s3)
    80004ae2:	fffff097          	auipc	ra,0xfffff
    80004ae6:	c1a080e7          	jalr	-998(ra) # 800036fc <bread>
    80004aea:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004aec:	000aa583          	lw	a1,0(s5)
    80004af0:	0289a503          	lw	a0,40(s3)
    80004af4:	fffff097          	auipc	ra,0xfffff
    80004af8:	c08080e7          	jalr	-1016(ra) # 800036fc <bread>
    80004afc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004afe:	40000613          	li	a2,1024
    80004b02:	05890593          	addi	a1,s2,88
    80004b06:	05850513          	addi	a0,a0,88
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	210080e7          	jalr	528(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004b12:	8526                	mv	a0,s1
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	cda080e7          	jalr	-806(ra) # 800037ee <bwrite>
    if(recovering == 0)
    80004b1c:	f80b1ce3          	bnez	s6,80004ab4 <install_trans+0x36>
      bunpin(dbuf);
    80004b20:	8526                	mv	a0,s1
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	de4080e7          	jalr	-540(ra) # 80003906 <bunpin>
    80004b2a:	b769                	j	80004ab4 <install_trans+0x36>
}
    80004b2c:	70e2                	ld	ra,56(sp)
    80004b2e:	7442                	ld	s0,48(sp)
    80004b30:	74a2                	ld	s1,40(sp)
    80004b32:	7902                	ld	s2,32(sp)
    80004b34:	69e2                	ld	s3,24(sp)
    80004b36:	6a42                	ld	s4,16(sp)
    80004b38:	6aa2                	ld	s5,8(sp)
    80004b3a:	6b02                	ld	s6,0(sp)
    80004b3c:	6121                	addi	sp,sp,64
    80004b3e:	8082                	ret
    80004b40:	8082                	ret

0000000080004b42 <initlog>:
{
    80004b42:	7179                	addi	sp,sp,-48
    80004b44:	f406                	sd	ra,40(sp)
    80004b46:	f022                	sd	s0,32(sp)
    80004b48:	ec26                	sd	s1,24(sp)
    80004b4a:	e84a                	sd	s2,16(sp)
    80004b4c:	e44e                	sd	s3,8(sp)
    80004b4e:	1800                	addi	s0,sp,48
    80004b50:	892a                	mv	s2,a0
    80004b52:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004b54:	00026497          	auipc	s1,0x26
    80004b58:	b1c48493          	addi	s1,s1,-1252 # 8002a670 <log>
    80004b5c:	00005597          	auipc	a1,0x5
    80004b60:	e0c58593          	addi	a1,a1,-500 # 80009968 <syscalls+0x248>
    80004b64:	8526                	mv	a0,s1
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	fcc080e7          	jalr	-52(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004b6e:	0149a583          	lw	a1,20(s3)
    80004b72:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004b74:	0109a783          	lw	a5,16(s3)
    80004b78:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004b7a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004b7e:	854a                	mv	a0,s2
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	b7c080e7          	jalr	-1156(ra) # 800036fc <bread>
  log.lh.n = lh->n;
    80004b88:	4d34                	lw	a3,88(a0)
    80004b8a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004b8c:	02d05663          	blez	a3,80004bb8 <initlog+0x76>
    80004b90:	05c50793          	addi	a5,a0,92
    80004b94:	00026717          	auipc	a4,0x26
    80004b98:	b0c70713          	addi	a4,a4,-1268 # 8002a6a0 <log+0x30>
    80004b9c:	36fd                	addiw	a3,a3,-1
    80004b9e:	02069613          	slli	a2,a3,0x20
    80004ba2:	01e65693          	srli	a3,a2,0x1e
    80004ba6:	06050613          	addi	a2,a0,96
    80004baa:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004bac:	4390                	lw	a2,0(a5)
    80004bae:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004bb0:	0791                	addi	a5,a5,4
    80004bb2:	0711                	addi	a4,a4,4
    80004bb4:	fed79ce3          	bne	a5,a3,80004bac <initlog+0x6a>
  brelse(buf);
    80004bb8:	fffff097          	auipc	ra,0xfffff
    80004bbc:	c74080e7          	jalr	-908(ra) # 8000382c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004bc0:	4505                	li	a0,1
    80004bc2:	00000097          	auipc	ra,0x0
    80004bc6:	ebc080e7          	jalr	-324(ra) # 80004a7e <install_trans>
  log.lh.n = 0;
    80004bca:	00026797          	auipc	a5,0x26
    80004bce:	ac07a923          	sw	zero,-1326(a5) # 8002a69c <log+0x2c>
  write_head(); // clear the log
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	e30080e7          	jalr	-464(ra) # 80004a02 <write_head>
}
    80004bda:	70a2                	ld	ra,40(sp)
    80004bdc:	7402                	ld	s0,32(sp)
    80004bde:	64e2                	ld	s1,24(sp)
    80004be0:	6942                	ld	s2,16(sp)
    80004be2:	69a2                	ld	s3,8(sp)
    80004be4:	6145                	addi	sp,sp,48
    80004be6:	8082                	ret

0000000080004be8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004be8:	1101                	addi	sp,sp,-32
    80004bea:	ec06                	sd	ra,24(sp)
    80004bec:	e822                	sd	s0,16(sp)
    80004bee:	e426                	sd	s1,8(sp)
    80004bf0:	e04a                	sd	s2,0(sp)
    80004bf2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004bf4:	00026517          	auipc	a0,0x26
    80004bf8:	a7c50513          	addi	a0,a0,-1412 # 8002a670 <log>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fc6080e7          	jalr	-58(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004c04:	00026497          	auipc	s1,0x26
    80004c08:	a6c48493          	addi	s1,s1,-1428 # 8002a670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c0c:	4979                	li	s2,30
    80004c0e:	a039                	j	80004c1c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004c10:	85a6                	mv	a1,s1
    80004c12:	8526                	mv	a0,s1
    80004c14:	ffffd097          	auipc	ra,0xffffd
    80004c18:	412080e7          	jalr	1042(ra) # 80002026 <sleep>
    if(log.committing){
    80004c1c:	50dc                	lw	a5,36(s1)
    80004c1e:	fbed                	bnez	a5,80004c10 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c20:	509c                	lw	a5,32(s1)
    80004c22:	0017871b          	addiw	a4,a5,1
    80004c26:	0007069b          	sext.w	a3,a4
    80004c2a:	0027179b          	slliw	a5,a4,0x2
    80004c2e:	9fb9                	addw	a5,a5,a4
    80004c30:	0017979b          	slliw	a5,a5,0x1
    80004c34:	54d8                	lw	a4,44(s1)
    80004c36:	9fb9                	addw	a5,a5,a4
    80004c38:	00f95963          	bge	s2,a5,80004c4a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004c3c:	85a6                	mv	a1,s1
    80004c3e:	8526                	mv	a0,s1
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	3e6080e7          	jalr	998(ra) # 80002026 <sleep>
    80004c48:	bfd1                	j	80004c1c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004c4a:	00026517          	auipc	a0,0x26
    80004c4e:	a2650513          	addi	a0,a0,-1498 # 8002a670 <log>
    80004c52:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	022080e7          	jalr	34(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004c5c:	60e2                	ld	ra,24(sp)
    80004c5e:	6442                	ld	s0,16(sp)
    80004c60:	64a2                	ld	s1,8(sp)
    80004c62:	6902                	ld	s2,0(sp)
    80004c64:	6105                	addi	sp,sp,32
    80004c66:	8082                	ret

0000000080004c68 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004c68:	7139                	addi	sp,sp,-64
    80004c6a:	fc06                	sd	ra,56(sp)
    80004c6c:	f822                	sd	s0,48(sp)
    80004c6e:	f426                	sd	s1,40(sp)
    80004c70:	f04a                	sd	s2,32(sp)
    80004c72:	ec4e                	sd	s3,24(sp)
    80004c74:	e852                	sd	s4,16(sp)
    80004c76:	e456                	sd	s5,8(sp)
    80004c78:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004c7a:	00026497          	auipc	s1,0x26
    80004c7e:	9f648493          	addi	s1,s1,-1546 # 8002a670 <log>
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	f3e080e7          	jalr	-194(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004c8c:	509c                	lw	a5,32(s1)
    80004c8e:	37fd                	addiw	a5,a5,-1
    80004c90:	0007891b          	sext.w	s2,a5
    80004c94:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004c96:	50dc                	lw	a5,36(s1)
    80004c98:	e7b9                	bnez	a5,80004ce6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004c9a:	04091e63          	bnez	s2,80004cf6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004c9e:	00026497          	auipc	s1,0x26
    80004ca2:	9d248493          	addi	s1,s1,-1582 # 8002a670 <log>
    80004ca6:	4785                	li	a5,1
    80004ca8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	fca080e7          	jalr	-54(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004cb4:	54dc                	lw	a5,44(s1)
    80004cb6:	06f04763          	bgtz	a5,80004d24 <end_op+0xbc>
    acquire(&log.lock);
    80004cba:	00026497          	auipc	s1,0x26
    80004cbe:	9b648493          	addi	s1,s1,-1610 # 8002a670 <log>
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	efe080e7          	jalr	-258(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004ccc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	4e0080e7          	jalr	1248(ra) # 800021b2 <wakeup>
    release(&log.lock);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	f9a080e7          	jalr	-102(ra) # 80000c76 <release>
}
    80004ce4:	a03d                	j	80004d12 <end_op+0xaa>
    panic("log.committing");
    80004ce6:	00005517          	auipc	a0,0x5
    80004cea:	c8a50513          	addi	a0,a0,-886 # 80009970 <syscalls+0x250>
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	83c080e7          	jalr	-1988(ra) # 8000052a <panic>
    wakeup(&log);
    80004cf6:	00026497          	auipc	s1,0x26
    80004cfa:	97a48493          	addi	s1,s1,-1670 # 8002a670 <log>
    80004cfe:	8526                	mv	a0,s1
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	4b2080e7          	jalr	1202(ra) # 800021b2 <wakeup>
  release(&log.lock);
    80004d08:	8526                	mv	a0,s1
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	f6c080e7          	jalr	-148(ra) # 80000c76 <release>
}
    80004d12:	70e2                	ld	ra,56(sp)
    80004d14:	7442                	ld	s0,48(sp)
    80004d16:	74a2                	ld	s1,40(sp)
    80004d18:	7902                	ld	s2,32(sp)
    80004d1a:	69e2                	ld	s3,24(sp)
    80004d1c:	6a42                	ld	s4,16(sp)
    80004d1e:	6aa2                	ld	s5,8(sp)
    80004d20:	6121                	addi	sp,sp,64
    80004d22:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d24:	00026a97          	auipc	s5,0x26
    80004d28:	97ca8a93          	addi	s5,s5,-1668 # 8002a6a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004d2c:	00026a17          	auipc	s4,0x26
    80004d30:	944a0a13          	addi	s4,s4,-1724 # 8002a670 <log>
    80004d34:	018a2583          	lw	a1,24(s4)
    80004d38:	012585bb          	addw	a1,a1,s2
    80004d3c:	2585                	addiw	a1,a1,1
    80004d3e:	028a2503          	lw	a0,40(s4)
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	9ba080e7          	jalr	-1606(ra) # 800036fc <bread>
    80004d4a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004d4c:	000aa583          	lw	a1,0(s5)
    80004d50:	028a2503          	lw	a0,40(s4)
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	9a8080e7          	jalr	-1624(ra) # 800036fc <bread>
    80004d5c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004d5e:	40000613          	li	a2,1024
    80004d62:	05850593          	addi	a1,a0,88
    80004d66:	05848513          	addi	a0,s1,88
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	fb0080e7          	jalr	-80(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004d72:	8526                	mv	a0,s1
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	a7a080e7          	jalr	-1414(ra) # 800037ee <bwrite>
    brelse(from);
    80004d7c:	854e                	mv	a0,s3
    80004d7e:	fffff097          	auipc	ra,0xfffff
    80004d82:	aae080e7          	jalr	-1362(ra) # 8000382c <brelse>
    brelse(to);
    80004d86:	8526                	mv	a0,s1
    80004d88:	fffff097          	auipc	ra,0xfffff
    80004d8c:	aa4080e7          	jalr	-1372(ra) # 8000382c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d90:	2905                	addiw	s2,s2,1
    80004d92:	0a91                	addi	s5,s5,4
    80004d94:	02ca2783          	lw	a5,44(s4)
    80004d98:	f8f94ee3          	blt	s2,a5,80004d34 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	c66080e7          	jalr	-922(ra) # 80004a02 <write_head>
    install_trans(0); // Now install writes to home locations
    80004da4:	4501                	li	a0,0
    80004da6:	00000097          	auipc	ra,0x0
    80004daa:	cd8080e7          	jalr	-808(ra) # 80004a7e <install_trans>
    log.lh.n = 0;
    80004dae:	00026797          	auipc	a5,0x26
    80004db2:	8e07a723          	sw	zero,-1810(a5) # 8002a69c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004db6:	00000097          	auipc	ra,0x0
    80004dba:	c4c080e7          	jalr	-948(ra) # 80004a02 <write_head>
    80004dbe:	bdf5                	j	80004cba <end_op+0x52>

0000000080004dc0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004dc0:	1101                	addi	sp,sp,-32
    80004dc2:	ec06                	sd	ra,24(sp)
    80004dc4:	e822                	sd	s0,16(sp)
    80004dc6:	e426                	sd	s1,8(sp)
    80004dc8:	e04a                	sd	s2,0(sp)
    80004dca:	1000                	addi	s0,sp,32
    80004dcc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004dce:	00026917          	auipc	s2,0x26
    80004dd2:	8a290913          	addi	s2,s2,-1886 # 8002a670 <log>
    80004dd6:	854a                	mv	a0,s2
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	dea080e7          	jalr	-534(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004de0:	02c92603          	lw	a2,44(s2)
    80004de4:	47f5                	li	a5,29
    80004de6:	06c7c563          	blt	a5,a2,80004e50 <log_write+0x90>
    80004dea:	00026797          	auipc	a5,0x26
    80004dee:	8a27a783          	lw	a5,-1886(a5) # 8002a68c <log+0x1c>
    80004df2:	37fd                	addiw	a5,a5,-1
    80004df4:	04f65e63          	bge	a2,a5,80004e50 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004df8:	00026797          	auipc	a5,0x26
    80004dfc:	8987a783          	lw	a5,-1896(a5) # 8002a690 <log+0x20>
    80004e00:	06f05063          	blez	a5,80004e60 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e04:	4781                	li	a5,0
    80004e06:	06c05563          	blez	a2,80004e70 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004e0a:	44cc                	lw	a1,12(s1)
    80004e0c:	00026717          	auipc	a4,0x26
    80004e10:	89470713          	addi	a4,a4,-1900 # 8002a6a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004e14:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004e16:	4314                	lw	a3,0(a4)
    80004e18:	04b68c63          	beq	a3,a1,80004e70 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004e1c:	2785                	addiw	a5,a5,1
    80004e1e:	0711                	addi	a4,a4,4
    80004e20:	fef61be3          	bne	a2,a5,80004e16 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004e24:	0621                	addi	a2,a2,8
    80004e26:	060a                	slli	a2,a2,0x2
    80004e28:	00026797          	auipc	a5,0x26
    80004e2c:	84878793          	addi	a5,a5,-1976 # 8002a670 <log>
    80004e30:	963e                	add	a2,a2,a5
    80004e32:	44dc                	lw	a5,12(s1)
    80004e34:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004e36:	8526                	mv	a0,s1
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	a92080e7          	jalr	-1390(ra) # 800038ca <bpin>
    log.lh.n++;
    80004e40:	00026717          	auipc	a4,0x26
    80004e44:	83070713          	addi	a4,a4,-2000 # 8002a670 <log>
    80004e48:	575c                	lw	a5,44(a4)
    80004e4a:	2785                	addiw	a5,a5,1
    80004e4c:	d75c                	sw	a5,44(a4)
    80004e4e:	a835                	j	80004e8a <log_write+0xca>
    panic("too big a transaction");
    80004e50:	00005517          	auipc	a0,0x5
    80004e54:	b3050513          	addi	a0,a0,-1232 # 80009980 <syscalls+0x260>
    80004e58:	ffffb097          	auipc	ra,0xffffb
    80004e5c:	6d2080e7          	jalr	1746(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004e60:	00005517          	auipc	a0,0x5
    80004e64:	b3850513          	addi	a0,a0,-1224 # 80009998 <syscalls+0x278>
    80004e68:	ffffb097          	auipc	ra,0xffffb
    80004e6c:	6c2080e7          	jalr	1730(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004e70:	00878713          	addi	a4,a5,8
    80004e74:	00271693          	slli	a3,a4,0x2
    80004e78:	00025717          	auipc	a4,0x25
    80004e7c:	7f870713          	addi	a4,a4,2040 # 8002a670 <log>
    80004e80:	9736                	add	a4,a4,a3
    80004e82:	44d4                	lw	a3,12(s1)
    80004e84:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004e86:	faf608e3          	beq	a2,a5,80004e36 <log_write+0x76>
  }
  release(&log.lock);
    80004e8a:	00025517          	auipc	a0,0x25
    80004e8e:	7e650513          	addi	a0,a0,2022 # 8002a670 <log>
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	de4080e7          	jalr	-540(ra) # 80000c76 <release>
}
    80004e9a:	60e2                	ld	ra,24(sp)
    80004e9c:	6442                	ld	s0,16(sp)
    80004e9e:	64a2                	ld	s1,8(sp)
    80004ea0:	6902                	ld	s2,0(sp)
    80004ea2:	6105                	addi	sp,sp,32
    80004ea4:	8082                	ret

0000000080004ea6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ea6:	1101                	addi	sp,sp,-32
    80004ea8:	ec06                	sd	ra,24(sp)
    80004eaa:	e822                	sd	s0,16(sp)
    80004eac:	e426                	sd	s1,8(sp)
    80004eae:	e04a                	sd	s2,0(sp)
    80004eb0:	1000                	addi	s0,sp,32
    80004eb2:	84aa                	mv	s1,a0
    80004eb4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004eb6:	00005597          	auipc	a1,0x5
    80004eba:	b0258593          	addi	a1,a1,-1278 # 800099b8 <syscalls+0x298>
    80004ebe:	0521                	addi	a0,a0,8
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	c72080e7          	jalr	-910(ra) # 80000b32 <initlock>
  lk->name = name;
    80004ec8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ecc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ed0:	0204a423          	sw	zero,40(s1)
}
    80004ed4:	60e2                	ld	ra,24(sp)
    80004ed6:	6442                	ld	s0,16(sp)
    80004ed8:	64a2                	ld	s1,8(sp)
    80004eda:	6902                	ld	s2,0(sp)
    80004edc:	6105                	addi	sp,sp,32
    80004ede:	8082                	ret

0000000080004ee0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ee0:	1101                	addi	sp,sp,-32
    80004ee2:	ec06                	sd	ra,24(sp)
    80004ee4:	e822                	sd	s0,16(sp)
    80004ee6:	e426                	sd	s1,8(sp)
    80004ee8:	e04a                	sd	s2,0(sp)
    80004eea:	1000                	addi	s0,sp,32
    80004eec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004eee:	00850913          	addi	s2,a0,8
    80004ef2:	854a                	mv	a0,s2
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	cce080e7          	jalr	-818(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004efc:	409c                	lw	a5,0(s1)
    80004efe:	cb89                	beqz	a5,80004f10 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f00:	85ca                	mv	a1,s2
    80004f02:	8526                	mv	a0,s1
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	122080e7          	jalr	290(ra) # 80002026 <sleep>
  while (lk->locked) {
    80004f0c:	409c                	lw	a5,0(s1)
    80004f0e:	fbed                	bnez	a5,80004f00 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004f10:	4785                	li	a5,1
    80004f12:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004f14:	ffffd097          	auipc	ra,0xffffd
    80004f18:	af0080e7          	jalr	-1296(ra) # 80001a04 <myproc>
    80004f1c:	591c                	lw	a5,48(a0)
    80004f1e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004f20:	854a                	mv	a0,s2
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	d54080e7          	jalr	-684(ra) # 80000c76 <release>
}
    80004f2a:	60e2                	ld	ra,24(sp)
    80004f2c:	6442                	ld	s0,16(sp)
    80004f2e:	64a2                	ld	s1,8(sp)
    80004f30:	6902                	ld	s2,0(sp)
    80004f32:	6105                	addi	sp,sp,32
    80004f34:	8082                	ret

0000000080004f36 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004f36:	1101                	addi	sp,sp,-32
    80004f38:	ec06                	sd	ra,24(sp)
    80004f3a:	e822                	sd	s0,16(sp)
    80004f3c:	e426                	sd	s1,8(sp)
    80004f3e:	e04a                	sd	s2,0(sp)
    80004f40:	1000                	addi	s0,sp,32
    80004f42:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f44:	00850913          	addi	s2,a0,8
    80004f48:	854a                	mv	a0,s2
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	c78080e7          	jalr	-904(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004f52:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f56:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004f5a:	8526                	mv	a0,s1
    80004f5c:	ffffd097          	auipc	ra,0xffffd
    80004f60:	256080e7          	jalr	598(ra) # 800021b2 <wakeup>
  release(&lk->lk);
    80004f64:	854a                	mv	a0,s2
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	d10080e7          	jalr	-752(ra) # 80000c76 <release>
}
    80004f6e:	60e2                	ld	ra,24(sp)
    80004f70:	6442                	ld	s0,16(sp)
    80004f72:	64a2                	ld	s1,8(sp)
    80004f74:	6902                	ld	s2,0(sp)
    80004f76:	6105                	addi	sp,sp,32
    80004f78:	8082                	ret

0000000080004f7a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004f7a:	7179                	addi	sp,sp,-48
    80004f7c:	f406                	sd	ra,40(sp)
    80004f7e:	f022                	sd	s0,32(sp)
    80004f80:	ec26                	sd	s1,24(sp)
    80004f82:	e84a                	sd	s2,16(sp)
    80004f84:	e44e                	sd	s3,8(sp)
    80004f86:	1800                	addi	s0,sp,48
    80004f88:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004f8a:	00850913          	addi	s2,a0,8
    80004f8e:	854a                	mv	a0,s2
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	c32080e7          	jalr	-974(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f98:	409c                	lw	a5,0(s1)
    80004f9a:	ef99                	bnez	a5,80004fb8 <holdingsleep+0x3e>
    80004f9c:	4481                	li	s1,0
  release(&lk->lk);
    80004f9e:	854a                	mv	a0,s2
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	cd6080e7          	jalr	-810(ra) # 80000c76 <release>
  return r;
}
    80004fa8:	8526                	mv	a0,s1
    80004faa:	70a2                	ld	ra,40(sp)
    80004fac:	7402                	ld	s0,32(sp)
    80004fae:	64e2                	ld	s1,24(sp)
    80004fb0:	6942                	ld	s2,16(sp)
    80004fb2:	69a2                	ld	s3,8(sp)
    80004fb4:	6145                	addi	sp,sp,48
    80004fb6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004fb8:	0284a983          	lw	s3,40(s1)
    80004fbc:	ffffd097          	auipc	ra,0xffffd
    80004fc0:	a48080e7          	jalr	-1464(ra) # 80001a04 <myproc>
    80004fc4:	5904                	lw	s1,48(a0)
    80004fc6:	413484b3          	sub	s1,s1,s3
    80004fca:	0014b493          	seqz	s1,s1
    80004fce:	bfc1                	j	80004f9e <holdingsleep+0x24>

0000000080004fd0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004fd0:	1141                	addi	sp,sp,-16
    80004fd2:	e406                	sd	ra,8(sp)
    80004fd4:	e022                	sd	s0,0(sp)
    80004fd6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004fd8:	00005597          	auipc	a1,0x5
    80004fdc:	9f058593          	addi	a1,a1,-1552 # 800099c8 <syscalls+0x2a8>
    80004fe0:	00025517          	auipc	a0,0x25
    80004fe4:	7d850513          	addi	a0,a0,2008 # 8002a7b8 <ftable>
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	b4a080e7          	jalr	-1206(ra) # 80000b32 <initlock>
}
    80004ff0:	60a2                	ld	ra,8(sp)
    80004ff2:	6402                	ld	s0,0(sp)
    80004ff4:	0141                	addi	sp,sp,16
    80004ff6:	8082                	ret

0000000080004ff8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ff8:	1101                	addi	sp,sp,-32
    80004ffa:	ec06                	sd	ra,24(sp)
    80004ffc:	e822                	sd	s0,16(sp)
    80004ffe:	e426                	sd	s1,8(sp)
    80005000:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005002:	00025517          	auipc	a0,0x25
    80005006:	7b650513          	addi	a0,a0,1974 # 8002a7b8 <ftable>
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	bb8080e7          	jalr	-1096(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005012:	00025497          	auipc	s1,0x25
    80005016:	7be48493          	addi	s1,s1,1982 # 8002a7d0 <ftable+0x18>
    8000501a:	00026717          	auipc	a4,0x26
    8000501e:	75670713          	addi	a4,a4,1878 # 8002b770 <ftable+0xfb8>
    if(f->ref == 0){
    80005022:	40dc                	lw	a5,4(s1)
    80005024:	cf99                	beqz	a5,80005042 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005026:	02848493          	addi	s1,s1,40
    8000502a:	fee49ce3          	bne	s1,a4,80005022 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000502e:	00025517          	auipc	a0,0x25
    80005032:	78a50513          	addi	a0,a0,1930 # 8002a7b8 <ftable>
    80005036:	ffffc097          	auipc	ra,0xffffc
    8000503a:	c40080e7          	jalr	-960(ra) # 80000c76 <release>
  return 0;
    8000503e:	4481                	li	s1,0
    80005040:	a819                	j	80005056 <filealloc+0x5e>
      f->ref = 1;
    80005042:	4785                	li	a5,1
    80005044:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005046:	00025517          	auipc	a0,0x25
    8000504a:	77250513          	addi	a0,a0,1906 # 8002a7b8 <ftable>
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	c28080e7          	jalr	-984(ra) # 80000c76 <release>
}
    80005056:	8526                	mv	a0,s1
    80005058:	60e2                	ld	ra,24(sp)
    8000505a:	6442                	ld	s0,16(sp)
    8000505c:	64a2                	ld	s1,8(sp)
    8000505e:	6105                	addi	sp,sp,32
    80005060:	8082                	ret

0000000080005062 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005062:	1101                	addi	sp,sp,-32
    80005064:	ec06                	sd	ra,24(sp)
    80005066:	e822                	sd	s0,16(sp)
    80005068:	e426                	sd	s1,8(sp)
    8000506a:	1000                	addi	s0,sp,32
    8000506c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000506e:	00025517          	auipc	a0,0x25
    80005072:	74a50513          	addi	a0,a0,1866 # 8002a7b8 <ftable>
    80005076:	ffffc097          	auipc	ra,0xffffc
    8000507a:	b4c080e7          	jalr	-1204(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000507e:	40dc                	lw	a5,4(s1)
    80005080:	02f05263          	blez	a5,800050a4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005084:	2785                	addiw	a5,a5,1
    80005086:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005088:	00025517          	auipc	a0,0x25
    8000508c:	73050513          	addi	a0,a0,1840 # 8002a7b8 <ftable>
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	be6080e7          	jalr	-1050(ra) # 80000c76 <release>
  return f;
}
    80005098:	8526                	mv	a0,s1
    8000509a:	60e2                	ld	ra,24(sp)
    8000509c:	6442                	ld	s0,16(sp)
    8000509e:	64a2                	ld	s1,8(sp)
    800050a0:	6105                	addi	sp,sp,32
    800050a2:	8082                	ret
    panic("filedup");
    800050a4:	00005517          	auipc	a0,0x5
    800050a8:	92c50513          	addi	a0,a0,-1748 # 800099d0 <syscalls+0x2b0>
    800050ac:	ffffb097          	auipc	ra,0xffffb
    800050b0:	47e080e7          	jalr	1150(ra) # 8000052a <panic>

00000000800050b4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800050b4:	7139                	addi	sp,sp,-64
    800050b6:	fc06                	sd	ra,56(sp)
    800050b8:	f822                	sd	s0,48(sp)
    800050ba:	f426                	sd	s1,40(sp)
    800050bc:	f04a                	sd	s2,32(sp)
    800050be:	ec4e                	sd	s3,24(sp)
    800050c0:	e852                	sd	s4,16(sp)
    800050c2:	e456                	sd	s5,8(sp)
    800050c4:	0080                	addi	s0,sp,64
    800050c6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800050c8:	00025517          	auipc	a0,0x25
    800050cc:	6f050513          	addi	a0,a0,1776 # 8002a7b8 <ftable>
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	af2080e7          	jalr	-1294(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800050d8:	40dc                	lw	a5,4(s1)
    800050da:	06f05163          	blez	a5,8000513c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800050de:	37fd                	addiw	a5,a5,-1
    800050e0:	0007871b          	sext.w	a4,a5
    800050e4:	c0dc                	sw	a5,4(s1)
    800050e6:	06e04363          	bgtz	a4,8000514c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800050ea:	0004a903          	lw	s2,0(s1)
    800050ee:	0094ca83          	lbu	s5,9(s1)
    800050f2:	0104ba03          	ld	s4,16(s1)
    800050f6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800050fa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800050fe:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005102:	00025517          	auipc	a0,0x25
    80005106:	6b650513          	addi	a0,a0,1718 # 8002a7b8 <ftable>
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	b6c080e7          	jalr	-1172(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80005112:	4785                	li	a5,1
    80005114:	04f90d63          	beq	s2,a5,8000516e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005118:	3979                	addiw	s2,s2,-2
    8000511a:	4785                	li	a5,1
    8000511c:	0527e063          	bltu	a5,s2,8000515c <fileclose+0xa8>
    begin_op();
    80005120:	00000097          	auipc	ra,0x0
    80005124:	ac8080e7          	jalr	-1336(ra) # 80004be8 <begin_op>
    iput(ff.ip);
    80005128:	854e                	mv	a0,s3
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	f90080e7          	jalr	-112(ra) # 800040ba <iput>
    end_op();
    80005132:	00000097          	auipc	ra,0x0
    80005136:	b36080e7          	jalr	-1226(ra) # 80004c68 <end_op>
    8000513a:	a00d                	j	8000515c <fileclose+0xa8>
    panic("fileclose");
    8000513c:	00005517          	auipc	a0,0x5
    80005140:	89c50513          	addi	a0,a0,-1892 # 800099d8 <syscalls+0x2b8>
    80005144:	ffffb097          	auipc	ra,0xffffb
    80005148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000514c:	00025517          	auipc	a0,0x25
    80005150:	66c50513          	addi	a0,a0,1644 # 8002a7b8 <ftable>
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	b22080e7          	jalr	-1246(ra) # 80000c76 <release>
  }
}
    8000515c:	70e2                	ld	ra,56(sp)
    8000515e:	7442                	ld	s0,48(sp)
    80005160:	74a2                	ld	s1,40(sp)
    80005162:	7902                	ld	s2,32(sp)
    80005164:	69e2                	ld	s3,24(sp)
    80005166:	6a42                	ld	s4,16(sp)
    80005168:	6aa2                	ld	s5,8(sp)
    8000516a:	6121                	addi	sp,sp,64
    8000516c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000516e:	85d6                	mv	a1,s5
    80005170:	8552                	mv	a0,s4
    80005172:	00000097          	auipc	ra,0x0
    80005176:	542080e7          	jalr	1346(ra) # 800056b4 <pipeclose>
    8000517a:	b7cd                	j	8000515c <fileclose+0xa8>

000000008000517c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000517c:	715d                	addi	sp,sp,-80
    8000517e:	e486                	sd	ra,72(sp)
    80005180:	e0a2                	sd	s0,64(sp)
    80005182:	fc26                	sd	s1,56(sp)
    80005184:	f84a                	sd	s2,48(sp)
    80005186:	f44e                	sd	s3,40(sp)
    80005188:	0880                	addi	s0,sp,80
    8000518a:	84aa                	mv	s1,a0
    8000518c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000518e:	ffffd097          	auipc	ra,0xffffd
    80005192:	876080e7          	jalr	-1930(ra) # 80001a04 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005196:	409c                	lw	a5,0(s1)
    80005198:	37f9                	addiw	a5,a5,-2
    8000519a:	4705                	li	a4,1
    8000519c:	04f76763          	bltu	a4,a5,800051ea <filestat+0x6e>
    800051a0:	892a                	mv	s2,a0
    ilock(f->ip);
    800051a2:	6c88                	ld	a0,24(s1)
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	d5c080e7          	jalr	-676(ra) # 80003f00 <ilock>
    stati(f->ip, &st);
    800051ac:	fb840593          	addi	a1,s0,-72
    800051b0:	6c88                	ld	a0,24(s1)
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	fd8080e7          	jalr	-40(ra) # 8000418a <stati>
    iunlock(f->ip);
    800051ba:	6c88                	ld	a0,24(s1)
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	e06080e7          	jalr	-506(ra) # 80003fc2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800051c4:	46e1                	li	a3,24
    800051c6:	fb840613          	addi	a2,s0,-72
    800051ca:	85ce                	mv	a1,s3
    800051cc:	05093503          	ld	a0,80(s2)
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	4f4080e7          	jalr	1268(ra) # 800016c4 <copyout>
    800051d8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800051dc:	60a6                	ld	ra,72(sp)
    800051de:	6406                	ld	s0,64(sp)
    800051e0:	74e2                	ld	s1,56(sp)
    800051e2:	7942                	ld	s2,48(sp)
    800051e4:	79a2                	ld	s3,40(sp)
    800051e6:	6161                	addi	sp,sp,80
    800051e8:	8082                	ret
  return -1;
    800051ea:	557d                	li	a0,-1
    800051ec:	bfc5                	j	800051dc <filestat+0x60>

00000000800051ee <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800051ee:	7179                	addi	sp,sp,-48
    800051f0:	f406                	sd	ra,40(sp)
    800051f2:	f022                	sd	s0,32(sp)
    800051f4:	ec26                	sd	s1,24(sp)
    800051f6:	e84a                	sd	s2,16(sp)
    800051f8:	e44e                	sd	s3,8(sp)
    800051fa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800051fc:	00854783          	lbu	a5,8(a0)
    80005200:	c3d5                	beqz	a5,800052a4 <fileread+0xb6>
    80005202:	84aa                	mv	s1,a0
    80005204:	89ae                	mv	s3,a1
    80005206:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005208:	411c                	lw	a5,0(a0)
    8000520a:	4705                	li	a4,1
    8000520c:	04e78963          	beq	a5,a4,8000525e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005210:	470d                	li	a4,3
    80005212:	04e78d63          	beq	a5,a4,8000526c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005216:	4709                	li	a4,2
    80005218:	06e79e63          	bne	a5,a4,80005294 <fileread+0xa6>
    ilock(f->ip);
    8000521c:	6d08                	ld	a0,24(a0)
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	ce2080e7          	jalr	-798(ra) # 80003f00 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005226:	874a                	mv	a4,s2
    80005228:	5094                	lw	a3,32(s1)
    8000522a:	864e                	mv	a2,s3
    8000522c:	4585                	li	a1,1
    8000522e:	6c88                	ld	a0,24(s1)
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	f84080e7          	jalr	-124(ra) # 800041b4 <readi>
    80005238:	892a                	mv	s2,a0
    8000523a:	00a05563          	blez	a0,80005244 <fileread+0x56>
      f->off += r;
    8000523e:	509c                	lw	a5,32(s1)
    80005240:	9fa9                	addw	a5,a5,a0
    80005242:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005244:	6c88                	ld	a0,24(s1)
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	d7c080e7          	jalr	-644(ra) # 80003fc2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000524e:	854a                	mv	a0,s2
    80005250:	70a2                	ld	ra,40(sp)
    80005252:	7402                	ld	s0,32(sp)
    80005254:	64e2                	ld	s1,24(sp)
    80005256:	6942                	ld	s2,16(sp)
    80005258:	69a2                	ld	s3,8(sp)
    8000525a:	6145                	addi	sp,sp,48
    8000525c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000525e:	6908                	ld	a0,16(a0)
    80005260:	00000097          	auipc	ra,0x0
    80005264:	5b6080e7          	jalr	1462(ra) # 80005816 <piperead>
    80005268:	892a                	mv	s2,a0
    8000526a:	b7d5                	j	8000524e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000526c:	02451783          	lh	a5,36(a0)
    80005270:	03079693          	slli	a3,a5,0x30
    80005274:	92c1                	srli	a3,a3,0x30
    80005276:	4725                	li	a4,9
    80005278:	02d76863          	bltu	a4,a3,800052a8 <fileread+0xba>
    8000527c:	0792                	slli	a5,a5,0x4
    8000527e:	00025717          	auipc	a4,0x25
    80005282:	49a70713          	addi	a4,a4,1178 # 8002a718 <devsw>
    80005286:	97ba                	add	a5,a5,a4
    80005288:	639c                	ld	a5,0(a5)
    8000528a:	c38d                	beqz	a5,800052ac <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000528c:	4505                	li	a0,1
    8000528e:	9782                	jalr	a5
    80005290:	892a                	mv	s2,a0
    80005292:	bf75                	j	8000524e <fileread+0x60>
    panic("fileread");
    80005294:	00004517          	auipc	a0,0x4
    80005298:	75450513          	addi	a0,a0,1876 # 800099e8 <syscalls+0x2c8>
    8000529c:	ffffb097          	auipc	ra,0xffffb
    800052a0:	28e080e7          	jalr	654(ra) # 8000052a <panic>
    return -1;
    800052a4:	597d                	li	s2,-1
    800052a6:	b765                	j	8000524e <fileread+0x60>
      return -1;
    800052a8:	597d                	li	s2,-1
    800052aa:	b755                	j	8000524e <fileread+0x60>
    800052ac:	597d                	li	s2,-1
    800052ae:	b745                	j	8000524e <fileread+0x60>

00000000800052b0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800052b0:	715d                	addi	sp,sp,-80
    800052b2:	e486                	sd	ra,72(sp)
    800052b4:	e0a2                	sd	s0,64(sp)
    800052b6:	fc26                	sd	s1,56(sp)
    800052b8:	f84a                	sd	s2,48(sp)
    800052ba:	f44e                	sd	s3,40(sp)
    800052bc:	f052                	sd	s4,32(sp)
    800052be:	ec56                	sd	s5,24(sp)
    800052c0:	e85a                	sd	s6,16(sp)
    800052c2:	e45e                	sd	s7,8(sp)
    800052c4:	e062                	sd	s8,0(sp)
    800052c6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800052c8:	00954783          	lbu	a5,9(a0)
    800052cc:	10078663          	beqz	a5,800053d8 <filewrite+0x128>
    800052d0:	892a                	mv	s2,a0
    800052d2:	8aae                	mv	s5,a1
    800052d4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800052d6:	411c                	lw	a5,0(a0)
    800052d8:	4705                	li	a4,1
    800052da:	02e78263          	beq	a5,a4,800052fe <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052de:	470d                	li	a4,3
    800052e0:	02e78663          	beq	a5,a4,8000530c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800052e4:	4709                	li	a4,2
    800052e6:	0ee79163          	bne	a5,a4,800053c8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800052ea:	0ac05d63          	blez	a2,800053a4 <filewrite+0xf4>
    int i = 0;
    800052ee:	4981                	li	s3,0
    800052f0:	6b05                	lui	s6,0x1
    800052f2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800052f6:	6b85                	lui	s7,0x1
    800052f8:	c00b8b9b          	addiw	s7,s7,-1024
    800052fc:	a861                	j	80005394 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800052fe:	6908                	ld	a0,16(a0)
    80005300:	00000097          	auipc	ra,0x0
    80005304:	424080e7          	jalr	1060(ra) # 80005724 <pipewrite>
    80005308:	8a2a                	mv	s4,a0
    8000530a:	a045                	j	800053aa <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000530c:	02451783          	lh	a5,36(a0)
    80005310:	03079693          	slli	a3,a5,0x30
    80005314:	92c1                	srli	a3,a3,0x30
    80005316:	4725                	li	a4,9
    80005318:	0cd76263          	bltu	a4,a3,800053dc <filewrite+0x12c>
    8000531c:	0792                	slli	a5,a5,0x4
    8000531e:	00025717          	auipc	a4,0x25
    80005322:	3fa70713          	addi	a4,a4,1018 # 8002a718 <devsw>
    80005326:	97ba                	add	a5,a5,a4
    80005328:	679c                	ld	a5,8(a5)
    8000532a:	cbdd                	beqz	a5,800053e0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000532c:	4505                	li	a0,1
    8000532e:	9782                	jalr	a5
    80005330:	8a2a                	mv	s4,a0
    80005332:	a8a5                	j	800053aa <filewrite+0xfa>
    80005334:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005338:	00000097          	auipc	ra,0x0
    8000533c:	8b0080e7          	jalr	-1872(ra) # 80004be8 <begin_op>
      ilock(f->ip);
    80005340:	01893503          	ld	a0,24(s2)
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	bbc080e7          	jalr	-1092(ra) # 80003f00 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000534c:	8762                	mv	a4,s8
    8000534e:	02092683          	lw	a3,32(s2)
    80005352:	01598633          	add	a2,s3,s5
    80005356:	4585                	li	a1,1
    80005358:	01893503          	ld	a0,24(s2)
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	f50080e7          	jalr	-176(ra) # 800042ac <writei>
    80005364:	84aa                	mv	s1,a0
    80005366:	00a05763          	blez	a0,80005374 <filewrite+0xc4>
        f->off += r;
    8000536a:	02092783          	lw	a5,32(s2)
    8000536e:	9fa9                	addw	a5,a5,a0
    80005370:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005374:	01893503          	ld	a0,24(s2)
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	c4a080e7          	jalr	-950(ra) # 80003fc2 <iunlock>
      end_op();
    80005380:	00000097          	auipc	ra,0x0
    80005384:	8e8080e7          	jalr	-1816(ra) # 80004c68 <end_op>

      if(r != n1){
    80005388:	009c1f63          	bne	s8,s1,800053a6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000538c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005390:	0149db63          	bge	s3,s4,800053a6 <filewrite+0xf6>
      int n1 = n - i;
    80005394:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005398:	84be                	mv	s1,a5
    8000539a:	2781                	sext.w	a5,a5
    8000539c:	f8fb5ce3          	bge	s6,a5,80005334 <filewrite+0x84>
    800053a0:	84de                	mv	s1,s7
    800053a2:	bf49                	j	80005334 <filewrite+0x84>
    int i = 0;
    800053a4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800053a6:	013a1f63          	bne	s4,s3,800053c4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800053aa:	8552                	mv	a0,s4
    800053ac:	60a6                	ld	ra,72(sp)
    800053ae:	6406                	ld	s0,64(sp)
    800053b0:	74e2                	ld	s1,56(sp)
    800053b2:	7942                	ld	s2,48(sp)
    800053b4:	79a2                	ld	s3,40(sp)
    800053b6:	7a02                	ld	s4,32(sp)
    800053b8:	6ae2                	ld	s5,24(sp)
    800053ba:	6b42                	ld	s6,16(sp)
    800053bc:	6ba2                	ld	s7,8(sp)
    800053be:	6c02                	ld	s8,0(sp)
    800053c0:	6161                	addi	sp,sp,80
    800053c2:	8082                	ret
    ret = (i == n ? n : -1);
    800053c4:	5a7d                	li	s4,-1
    800053c6:	b7d5                	j	800053aa <filewrite+0xfa>
    panic("filewrite");
    800053c8:	00004517          	auipc	a0,0x4
    800053cc:	63050513          	addi	a0,a0,1584 # 800099f8 <syscalls+0x2d8>
    800053d0:	ffffb097          	auipc	ra,0xffffb
    800053d4:	15a080e7          	jalr	346(ra) # 8000052a <panic>
    return -1;
    800053d8:	5a7d                	li	s4,-1
    800053da:	bfc1                	j	800053aa <filewrite+0xfa>
      return -1;
    800053dc:	5a7d                	li	s4,-1
    800053de:	b7f1                	j	800053aa <filewrite+0xfa>
    800053e0:	5a7d                	li	s4,-1
    800053e2:	b7e1                	j	800053aa <filewrite+0xfa>

00000000800053e4 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    800053e4:	7179                	addi	sp,sp,-48
    800053e6:	f406                	sd	ra,40(sp)
    800053e8:	f022                	sd	s0,32(sp)
    800053ea:	ec26                	sd	s1,24(sp)
    800053ec:	e84a                	sd	s2,16(sp)
    800053ee:	e44e                	sd	s3,8(sp)
    800053f0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800053f2:	00854783          	lbu	a5,8(a0)
    800053f6:	c3d5                	beqz	a5,8000549a <kfileread+0xb6>
    800053f8:	84aa                	mv	s1,a0
    800053fa:	89ae                	mv	s3,a1
    800053fc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800053fe:	411c                	lw	a5,0(a0)
    80005400:	4705                	li	a4,1
    80005402:	04e78963          	beq	a5,a4,80005454 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005406:	470d                	li	a4,3
    80005408:	04e78d63          	beq	a5,a4,80005462 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000540c:	4709                	li	a4,2
    8000540e:	06e79e63          	bne	a5,a4,8000548a <kfileread+0xa6>
    ilock(f->ip);
    80005412:	6d08                	ld	a0,24(a0)
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	aec080e7          	jalr	-1300(ra) # 80003f00 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    8000541c:	874a                	mv	a4,s2
    8000541e:	5094                	lw	a3,32(s1)
    80005420:	864e                	mv	a2,s3
    80005422:	4581                	li	a1,0
    80005424:	6c88                	ld	a0,24(s1)
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	d8e080e7          	jalr	-626(ra) # 800041b4 <readi>
    8000542e:	892a                	mv	s2,a0
    80005430:	00a05563          	blez	a0,8000543a <kfileread+0x56>
      f->off += r;
    80005434:	509c                	lw	a5,32(s1)
    80005436:	9fa9                	addw	a5,a5,a0
    80005438:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000543a:	6c88                	ld	a0,24(s1)
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	b86080e7          	jalr	-1146(ra) # 80003fc2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005444:	854a                	mv	a0,s2
    80005446:	70a2                	ld	ra,40(sp)
    80005448:	7402                	ld	s0,32(sp)
    8000544a:	64e2                	ld	s1,24(sp)
    8000544c:	6942                	ld	s2,16(sp)
    8000544e:	69a2                	ld	s3,8(sp)
    80005450:	6145                	addi	sp,sp,48
    80005452:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005454:	6908                	ld	a0,16(a0)
    80005456:	00000097          	auipc	ra,0x0
    8000545a:	3c0080e7          	jalr	960(ra) # 80005816 <piperead>
    8000545e:	892a                	mv	s2,a0
    80005460:	b7d5                	j	80005444 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005462:	02451783          	lh	a5,36(a0)
    80005466:	03079693          	slli	a3,a5,0x30
    8000546a:	92c1                	srli	a3,a3,0x30
    8000546c:	4725                	li	a4,9
    8000546e:	02d76863          	bltu	a4,a3,8000549e <kfileread+0xba>
    80005472:	0792                	slli	a5,a5,0x4
    80005474:	00025717          	auipc	a4,0x25
    80005478:	2a470713          	addi	a4,a4,676 # 8002a718 <devsw>
    8000547c:	97ba                	add	a5,a5,a4
    8000547e:	639c                	ld	a5,0(a5)
    80005480:	c38d                	beqz	a5,800054a2 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005482:	4505                	li	a0,1
    80005484:	9782                	jalr	a5
    80005486:	892a                	mv	s2,a0
    80005488:	bf75                	j	80005444 <kfileread+0x60>
    panic("fileread");
    8000548a:	00004517          	auipc	a0,0x4
    8000548e:	55e50513          	addi	a0,a0,1374 # 800099e8 <syscalls+0x2c8>
    80005492:	ffffb097          	auipc	ra,0xffffb
    80005496:	098080e7          	jalr	152(ra) # 8000052a <panic>
    return -1;
    8000549a:	597d                	li	s2,-1
    8000549c:	b765                	j	80005444 <kfileread+0x60>
      return -1;
    8000549e:	597d                	li	s2,-1
    800054a0:	b755                	j	80005444 <kfileread+0x60>
    800054a2:	597d                	li	s2,-1
    800054a4:	b745                	j	80005444 <kfileread+0x60>

00000000800054a6 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    800054a6:	715d                	addi	sp,sp,-80
    800054a8:	e486                	sd	ra,72(sp)
    800054aa:	e0a2                	sd	s0,64(sp)
    800054ac:	fc26                	sd	s1,56(sp)
    800054ae:	f84a                	sd	s2,48(sp)
    800054b0:	f44e                	sd	s3,40(sp)
    800054b2:	f052                	sd	s4,32(sp)
    800054b4:	ec56                	sd	s5,24(sp)
    800054b6:	e85a                	sd	s6,16(sp)
    800054b8:	e45e                	sd	s7,8(sp)
    800054ba:	e062                	sd	s8,0(sp)
    800054bc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800054be:	00954783          	lbu	a5,9(a0)
    800054c2:	10078663          	beqz	a5,800055ce <kfilewrite+0x128>
    800054c6:	892a                	mv	s2,a0
    800054c8:	8aae                	mv	s5,a1
    800054ca:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800054cc:	411c                	lw	a5,0(a0)
    800054ce:	4705                	li	a4,1
    800054d0:	02e78263          	beq	a5,a4,800054f4 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054d4:	470d                	li	a4,3
    800054d6:	02e78663          	beq	a5,a4,80005502 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800054da:	4709                	li	a4,2
    800054dc:	0ee79163          	bne	a5,a4,800055be <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800054e0:	0ac05d63          	blez	a2,8000559a <kfilewrite+0xf4>
    int i = 0;
    800054e4:	4981                	li	s3,0
    800054e6:	6b05                	lui	s6,0x1
    800054e8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800054ec:	6b85                	lui	s7,0x1
    800054ee:	c00b8b9b          	addiw	s7,s7,-1024
    800054f2:	a861                	j	8000558a <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800054f4:	6908                	ld	a0,16(a0)
    800054f6:	00000097          	auipc	ra,0x0
    800054fa:	22e080e7          	jalr	558(ra) # 80005724 <pipewrite>
    800054fe:	8a2a                	mv	s4,a0
    80005500:	a045                	j	800055a0 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005502:	02451783          	lh	a5,36(a0)
    80005506:	03079693          	slli	a3,a5,0x30
    8000550a:	92c1                	srli	a3,a3,0x30
    8000550c:	4725                	li	a4,9
    8000550e:	0cd76263          	bltu	a4,a3,800055d2 <kfilewrite+0x12c>
    80005512:	0792                	slli	a5,a5,0x4
    80005514:	00025717          	auipc	a4,0x25
    80005518:	20470713          	addi	a4,a4,516 # 8002a718 <devsw>
    8000551c:	97ba                	add	a5,a5,a4
    8000551e:	679c                	ld	a5,8(a5)
    80005520:	cbdd                	beqz	a5,800055d6 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005522:	4505                	li	a0,1
    80005524:	9782                	jalr	a5
    80005526:	8a2a                	mv	s4,a0
    80005528:	a8a5                	j	800055a0 <kfilewrite+0xfa>
    8000552a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	6ba080e7          	jalr	1722(ra) # 80004be8 <begin_op>
      ilock(f->ip);
    80005536:	01893503          	ld	a0,24(s2)
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	9c6080e7          	jalr	-1594(ra) # 80003f00 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80005542:	8762                	mv	a4,s8
    80005544:	02092683          	lw	a3,32(s2)
    80005548:	01598633          	add	a2,s3,s5
    8000554c:	4581                	li	a1,0
    8000554e:	01893503          	ld	a0,24(s2)
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	d5a080e7          	jalr	-678(ra) # 800042ac <writei>
    8000555a:	84aa                	mv	s1,a0
    8000555c:	00a05763          	blez	a0,8000556a <kfilewrite+0xc4>
        f->off += r;
    80005560:	02092783          	lw	a5,32(s2)
    80005564:	9fa9                	addw	a5,a5,a0
    80005566:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000556a:	01893503          	ld	a0,24(s2)
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	a54080e7          	jalr	-1452(ra) # 80003fc2 <iunlock>
      end_op();
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	6f2080e7          	jalr	1778(ra) # 80004c68 <end_op>

      if(r != n1){
    8000557e:	009c1f63          	bne	s8,s1,8000559c <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005582:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005586:	0149db63          	bge	s3,s4,8000559c <kfilewrite+0xf6>
      int n1 = n - i;
    8000558a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000558e:	84be                	mv	s1,a5
    80005590:	2781                	sext.w	a5,a5
    80005592:	f8fb5ce3          	bge	s6,a5,8000552a <kfilewrite+0x84>
    80005596:	84de                	mv	s1,s7
    80005598:	bf49                	j	8000552a <kfilewrite+0x84>
    int i = 0;
    8000559a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000559c:	013a1f63          	bne	s4,s3,800055ba <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    800055a0:	8552                	mv	a0,s4
    800055a2:	60a6                	ld	ra,72(sp)
    800055a4:	6406                	ld	s0,64(sp)
    800055a6:	74e2                	ld	s1,56(sp)
    800055a8:	7942                	ld	s2,48(sp)
    800055aa:	79a2                	ld	s3,40(sp)
    800055ac:	7a02                	ld	s4,32(sp)
    800055ae:	6ae2                	ld	s5,24(sp)
    800055b0:	6b42                	ld	s6,16(sp)
    800055b2:	6ba2                	ld	s7,8(sp)
    800055b4:	6c02                	ld	s8,0(sp)
    800055b6:	6161                	addi	sp,sp,80
    800055b8:	8082                	ret
    ret = (i == n ? n : -1);
    800055ba:	5a7d                	li	s4,-1
    800055bc:	b7d5                	j	800055a0 <kfilewrite+0xfa>
    panic("filewrite");
    800055be:	00004517          	auipc	a0,0x4
    800055c2:	43a50513          	addi	a0,a0,1082 # 800099f8 <syscalls+0x2d8>
    800055c6:	ffffb097          	auipc	ra,0xffffb
    800055ca:	f64080e7          	jalr	-156(ra) # 8000052a <panic>
    return -1;
    800055ce:	5a7d                	li	s4,-1
    800055d0:	bfc1                	j	800055a0 <kfilewrite+0xfa>
      return -1;
    800055d2:	5a7d                	li	s4,-1
    800055d4:	b7f1                	j	800055a0 <kfilewrite+0xfa>
    800055d6:	5a7d                	li	s4,-1
    800055d8:	b7e1                	j	800055a0 <kfilewrite+0xfa>

00000000800055da <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800055da:	7179                	addi	sp,sp,-48
    800055dc:	f406                	sd	ra,40(sp)
    800055de:	f022                	sd	s0,32(sp)
    800055e0:	ec26                	sd	s1,24(sp)
    800055e2:	e84a                	sd	s2,16(sp)
    800055e4:	e44e                	sd	s3,8(sp)
    800055e6:	e052                	sd	s4,0(sp)
    800055e8:	1800                	addi	s0,sp,48
    800055ea:	84aa                	mv	s1,a0
    800055ec:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800055ee:	0005b023          	sd	zero,0(a1)
    800055f2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800055f6:	00000097          	auipc	ra,0x0
    800055fa:	a02080e7          	jalr	-1534(ra) # 80004ff8 <filealloc>
    800055fe:	e088                	sd	a0,0(s1)
    80005600:	c551                	beqz	a0,8000568c <pipealloc+0xb2>
    80005602:	00000097          	auipc	ra,0x0
    80005606:	9f6080e7          	jalr	-1546(ra) # 80004ff8 <filealloc>
    8000560a:	00aa3023          	sd	a0,0(s4)
    8000560e:	c92d                	beqz	a0,80005680 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005610:	ffffb097          	auipc	ra,0xffffb
    80005614:	4c2080e7          	jalr	1218(ra) # 80000ad2 <kalloc>
    80005618:	892a                	mv	s2,a0
    8000561a:	c125                	beqz	a0,8000567a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000561c:	4985                	li	s3,1
    8000561e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005622:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005626:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000562a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000562e:	00004597          	auipc	a1,0x4
    80005632:	3da58593          	addi	a1,a1,986 # 80009a08 <syscalls+0x2e8>
    80005636:	ffffb097          	auipc	ra,0xffffb
    8000563a:	4fc080e7          	jalr	1276(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    8000563e:	609c                	ld	a5,0(s1)
    80005640:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005644:	609c                	ld	a5,0(s1)
    80005646:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000564a:	609c                	ld	a5,0(s1)
    8000564c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005650:	609c                	ld	a5,0(s1)
    80005652:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005656:	000a3783          	ld	a5,0(s4)
    8000565a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000565e:	000a3783          	ld	a5,0(s4)
    80005662:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005666:	000a3783          	ld	a5,0(s4)
    8000566a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000566e:	000a3783          	ld	a5,0(s4)
    80005672:	0127b823          	sd	s2,16(a5)
  return 0;
    80005676:	4501                	li	a0,0
    80005678:	a025                	j	800056a0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000567a:	6088                	ld	a0,0(s1)
    8000567c:	e501                	bnez	a0,80005684 <pipealloc+0xaa>
    8000567e:	a039                	j	8000568c <pipealloc+0xb2>
    80005680:	6088                	ld	a0,0(s1)
    80005682:	c51d                	beqz	a0,800056b0 <pipealloc+0xd6>
    fileclose(*f0);
    80005684:	00000097          	auipc	ra,0x0
    80005688:	a30080e7          	jalr	-1488(ra) # 800050b4 <fileclose>
  if(*f1)
    8000568c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005690:	557d                	li	a0,-1
  if(*f1)
    80005692:	c799                	beqz	a5,800056a0 <pipealloc+0xc6>
    fileclose(*f1);
    80005694:	853e                	mv	a0,a5
    80005696:	00000097          	auipc	ra,0x0
    8000569a:	a1e080e7          	jalr	-1506(ra) # 800050b4 <fileclose>
  return -1;
    8000569e:	557d                	li	a0,-1
}
    800056a0:	70a2                	ld	ra,40(sp)
    800056a2:	7402                	ld	s0,32(sp)
    800056a4:	64e2                	ld	s1,24(sp)
    800056a6:	6942                	ld	s2,16(sp)
    800056a8:	69a2                	ld	s3,8(sp)
    800056aa:	6a02                	ld	s4,0(sp)
    800056ac:	6145                	addi	sp,sp,48
    800056ae:	8082                	ret
  return -1;
    800056b0:	557d                	li	a0,-1
    800056b2:	b7fd                	j	800056a0 <pipealloc+0xc6>

00000000800056b4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800056b4:	1101                	addi	sp,sp,-32
    800056b6:	ec06                	sd	ra,24(sp)
    800056b8:	e822                	sd	s0,16(sp)
    800056ba:	e426                	sd	s1,8(sp)
    800056bc:	e04a                	sd	s2,0(sp)
    800056be:	1000                	addi	s0,sp,32
    800056c0:	84aa                	mv	s1,a0
    800056c2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800056c4:	ffffb097          	auipc	ra,0xffffb
    800056c8:	4fe080e7          	jalr	1278(ra) # 80000bc2 <acquire>
  if(writable){
    800056cc:	02090d63          	beqz	s2,80005706 <pipeclose+0x52>
    pi->writeopen = 0;
    800056d0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800056d4:	21848513          	addi	a0,s1,536
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	ada080e7          	jalr	-1318(ra) # 800021b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800056e0:	2204b783          	ld	a5,544(s1)
    800056e4:	eb95                	bnez	a5,80005718 <pipeclose+0x64>
    release(&pi->lock);
    800056e6:	8526                	mv	a0,s1
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	58e080e7          	jalr	1422(ra) # 80000c76 <release>
    kfree((char*)pi);
    800056f0:	8526                	mv	a0,s1
    800056f2:	ffffb097          	auipc	ra,0xffffb
    800056f6:	2e4080e7          	jalr	740(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800056fa:	60e2                	ld	ra,24(sp)
    800056fc:	6442                	ld	s0,16(sp)
    800056fe:	64a2                	ld	s1,8(sp)
    80005700:	6902                	ld	s2,0(sp)
    80005702:	6105                	addi	sp,sp,32
    80005704:	8082                	ret
    pi->readopen = 0;
    80005706:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000570a:	21c48513          	addi	a0,s1,540
    8000570e:	ffffd097          	auipc	ra,0xffffd
    80005712:	aa4080e7          	jalr	-1372(ra) # 800021b2 <wakeup>
    80005716:	b7e9                	j	800056e0 <pipeclose+0x2c>
    release(&pi->lock);
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffb097          	auipc	ra,0xffffb
    8000571e:	55c080e7          	jalr	1372(ra) # 80000c76 <release>
}
    80005722:	bfe1                	j	800056fa <pipeclose+0x46>

0000000080005724 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005724:	711d                	addi	sp,sp,-96
    80005726:	ec86                	sd	ra,88(sp)
    80005728:	e8a2                	sd	s0,80(sp)
    8000572a:	e4a6                	sd	s1,72(sp)
    8000572c:	e0ca                	sd	s2,64(sp)
    8000572e:	fc4e                	sd	s3,56(sp)
    80005730:	f852                	sd	s4,48(sp)
    80005732:	f456                	sd	s5,40(sp)
    80005734:	f05a                	sd	s6,32(sp)
    80005736:	ec5e                	sd	s7,24(sp)
    80005738:	e862                	sd	s8,16(sp)
    8000573a:	1080                	addi	s0,sp,96
    8000573c:	84aa                	mv	s1,a0
    8000573e:	8aae                	mv	s5,a1
    80005740:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005742:	ffffc097          	auipc	ra,0xffffc
    80005746:	2c2080e7          	jalr	706(ra) # 80001a04 <myproc>
    8000574a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffb097          	auipc	ra,0xffffb
    80005752:	474080e7          	jalr	1140(ra) # 80000bc2 <acquire>
  while(i < n){
    80005756:	0b405363          	blez	s4,800057fc <pipewrite+0xd8>
  int i = 0;
    8000575a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000575c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000575e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005762:	21c48b93          	addi	s7,s1,540
    80005766:	a089                	j	800057a8 <pipewrite+0x84>
      release(&pi->lock);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffb097          	auipc	ra,0xffffb
    8000576e:	50c080e7          	jalr	1292(ra) # 80000c76 <release>
      return -1;
    80005772:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005774:	854a                	mv	a0,s2
    80005776:	60e6                	ld	ra,88(sp)
    80005778:	6446                	ld	s0,80(sp)
    8000577a:	64a6                	ld	s1,72(sp)
    8000577c:	6906                	ld	s2,64(sp)
    8000577e:	79e2                	ld	s3,56(sp)
    80005780:	7a42                	ld	s4,48(sp)
    80005782:	7aa2                	ld	s5,40(sp)
    80005784:	7b02                	ld	s6,32(sp)
    80005786:	6be2                	ld	s7,24(sp)
    80005788:	6c42                	ld	s8,16(sp)
    8000578a:	6125                	addi	sp,sp,96
    8000578c:	8082                	ret
      wakeup(&pi->nread);
    8000578e:	8562                	mv	a0,s8
    80005790:	ffffd097          	auipc	ra,0xffffd
    80005794:	a22080e7          	jalr	-1502(ra) # 800021b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005798:	85a6                	mv	a1,s1
    8000579a:	855e                	mv	a0,s7
    8000579c:	ffffd097          	auipc	ra,0xffffd
    800057a0:	88a080e7          	jalr	-1910(ra) # 80002026 <sleep>
  while(i < n){
    800057a4:	05495d63          	bge	s2,s4,800057fe <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800057a8:	2204a783          	lw	a5,544(s1)
    800057ac:	dfd5                	beqz	a5,80005768 <pipewrite+0x44>
    800057ae:	0289a783          	lw	a5,40(s3)
    800057b2:	fbdd                	bnez	a5,80005768 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800057b4:	2184a783          	lw	a5,536(s1)
    800057b8:	21c4a703          	lw	a4,540(s1)
    800057bc:	2007879b          	addiw	a5,a5,512
    800057c0:	fcf707e3          	beq	a4,a5,8000578e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800057c4:	4685                	li	a3,1
    800057c6:	01590633          	add	a2,s2,s5
    800057ca:	faf40593          	addi	a1,s0,-81
    800057ce:	0509b503          	ld	a0,80(s3)
    800057d2:	ffffc097          	auipc	ra,0xffffc
    800057d6:	f7e080e7          	jalr	-130(ra) # 80001750 <copyin>
    800057da:	03650263          	beq	a0,s6,800057fe <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800057de:	21c4a783          	lw	a5,540(s1)
    800057e2:	0017871b          	addiw	a4,a5,1
    800057e6:	20e4ae23          	sw	a4,540(s1)
    800057ea:	1ff7f793          	andi	a5,a5,511
    800057ee:	97a6                	add	a5,a5,s1
    800057f0:	faf44703          	lbu	a4,-81(s0)
    800057f4:	00e78c23          	sb	a4,24(a5)
      i++;
    800057f8:	2905                	addiw	s2,s2,1
    800057fa:	b76d                	j	800057a4 <pipewrite+0x80>
  int i = 0;
    800057fc:	4901                	li	s2,0
  wakeup(&pi->nread);
    800057fe:	21848513          	addi	a0,s1,536
    80005802:	ffffd097          	auipc	ra,0xffffd
    80005806:	9b0080e7          	jalr	-1616(ra) # 800021b2 <wakeup>
  release(&pi->lock);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffb097          	auipc	ra,0xffffb
    80005810:	46a080e7          	jalr	1130(ra) # 80000c76 <release>
  return i;
    80005814:	b785                	j	80005774 <pipewrite+0x50>

0000000080005816 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005816:	715d                	addi	sp,sp,-80
    80005818:	e486                	sd	ra,72(sp)
    8000581a:	e0a2                	sd	s0,64(sp)
    8000581c:	fc26                	sd	s1,56(sp)
    8000581e:	f84a                	sd	s2,48(sp)
    80005820:	f44e                	sd	s3,40(sp)
    80005822:	f052                	sd	s4,32(sp)
    80005824:	ec56                	sd	s5,24(sp)
    80005826:	e85a                	sd	s6,16(sp)
    80005828:	0880                	addi	s0,sp,80
    8000582a:	84aa                	mv	s1,a0
    8000582c:	892e                	mv	s2,a1
    8000582e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005830:	ffffc097          	auipc	ra,0xffffc
    80005834:	1d4080e7          	jalr	468(ra) # 80001a04 <myproc>
    80005838:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000583a:	8526                	mv	a0,s1
    8000583c:	ffffb097          	auipc	ra,0xffffb
    80005840:	386080e7          	jalr	902(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005844:	2184a703          	lw	a4,536(s1)
    80005848:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000584c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005850:	02f71463          	bne	a4,a5,80005878 <piperead+0x62>
    80005854:	2244a783          	lw	a5,548(s1)
    80005858:	c385                	beqz	a5,80005878 <piperead+0x62>
    if(pr->killed){
    8000585a:	028a2783          	lw	a5,40(s4)
    8000585e:	ebc1                	bnez	a5,800058ee <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005860:	85a6                	mv	a1,s1
    80005862:	854e                	mv	a0,s3
    80005864:	ffffc097          	auipc	ra,0xffffc
    80005868:	7c2080e7          	jalr	1986(ra) # 80002026 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000586c:	2184a703          	lw	a4,536(s1)
    80005870:	21c4a783          	lw	a5,540(s1)
    80005874:	fef700e3          	beq	a4,a5,80005854 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005878:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000587a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000587c:	05505363          	blez	s5,800058c2 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005880:	2184a783          	lw	a5,536(s1)
    80005884:	21c4a703          	lw	a4,540(s1)
    80005888:	02f70d63          	beq	a4,a5,800058c2 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000588c:	0017871b          	addiw	a4,a5,1
    80005890:	20e4ac23          	sw	a4,536(s1)
    80005894:	1ff7f793          	andi	a5,a5,511
    80005898:	97a6                	add	a5,a5,s1
    8000589a:	0187c783          	lbu	a5,24(a5)
    8000589e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800058a2:	4685                	li	a3,1
    800058a4:	fbf40613          	addi	a2,s0,-65
    800058a8:	85ca                	mv	a1,s2
    800058aa:	050a3503          	ld	a0,80(s4)
    800058ae:	ffffc097          	auipc	ra,0xffffc
    800058b2:	e16080e7          	jalr	-490(ra) # 800016c4 <copyout>
    800058b6:	01650663          	beq	a0,s6,800058c2 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058ba:	2985                	addiw	s3,s3,1
    800058bc:	0905                	addi	s2,s2,1
    800058be:	fd3a91e3          	bne	s5,s3,80005880 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800058c2:	21c48513          	addi	a0,s1,540
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	8ec080e7          	jalr	-1812(ra) # 800021b2 <wakeup>
  release(&pi->lock);
    800058ce:	8526                	mv	a0,s1
    800058d0:	ffffb097          	auipc	ra,0xffffb
    800058d4:	3a6080e7          	jalr	934(ra) # 80000c76 <release>
  return i;
}
    800058d8:	854e                	mv	a0,s3
    800058da:	60a6                	ld	ra,72(sp)
    800058dc:	6406                	ld	s0,64(sp)
    800058de:	74e2                	ld	s1,56(sp)
    800058e0:	7942                	ld	s2,48(sp)
    800058e2:	79a2                	ld	s3,40(sp)
    800058e4:	7a02                	ld	s4,32(sp)
    800058e6:	6ae2                	ld	s5,24(sp)
    800058e8:	6b42                	ld	s6,16(sp)
    800058ea:	6161                	addi	sp,sp,80
    800058ec:	8082                	ret
      release(&pi->lock);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffb097          	auipc	ra,0xffffb
    800058f4:	386080e7          	jalr	902(ra) # 80000c76 <release>
      return -1;
    800058f8:	59fd                	li	s3,-1
    800058fa:	bff9                	j	800058d8 <piperead+0xc2>

00000000800058fc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800058fc:	bd010113          	addi	sp,sp,-1072
    80005900:	42113423          	sd	ra,1064(sp)
    80005904:	42813023          	sd	s0,1056(sp)
    80005908:	40913c23          	sd	s1,1048(sp)
    8000590c:	41213823          	sd	s2,1040(sp)
    80005910:	41313423          	sd	s3,1032(sp)
    80005914:	41413023          	sd	s4,1024(sp)
    80005918:	3f513c23          	sd	s5,1016(sp)
    8000591c:	3f613823          	sd	s6,1008(sp)
    80005920:	3f713423          	sd	s7,1000(sp)
    80005924:	3f813023          	sd	s8,992(sp)
    80005928:	3d913c23          	sd	s9,984(sp)
    8000592c:	3da13823          	sd	s10,976(sp)
    80005930:	3db13423          	sd	s11,968(sp)
    80005934:	43010413          	addi	s0,sp,1072
    80005938:	89aa                	mv	s3,a0
    8000593a:	bea43023          	sd	a0,-1056(s0)
    8000593e:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005942:	ffffc097          	auipc	ra,0xffffc
    80005946:	0c2080e7          	jalr	194(ra) # 80001a04 <myproc>
    8000594a:	84aa                	mv	s1,a0
    8000594c:	c0a43423          	sd	a0,-1016(s0)
  
  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_PSYC_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    80005950:	17050913          	addi	s2,a0,368
    80005954:	10000613          	li	a2,256
    80005958:	85ca                	mv	a1,s2
    8000595a:	d1040513          	addi	a0,s0,-752
    8000595e:	ffffb097          	auipc	ra,0xffffb
    80005962:	3bc080e7          	jalr	956(ra) # 80000d1a <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    80005966:	27048493          	addi	s1,s1,624
    8000596a:	10000613          	li	a2,256
    8000596e:	85a6                	mv	a1,s1
    80005970:	c1040513          	addi	a0,s0,-1008
    80005974:	ffffb097          	auipc	ra,0xffffb
    80005978:	3a6080e7          	jalr	934(ra) # 80000d1a <memmove>

  begin_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	26c080e7          	jalr	620(ra) # 80004be8 <begin_op>

  if((ip = namei(path)) == 0){
    80005984:	854e                	mv	a0,s3
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	d30080e7          	jalr	-720(ra) # 800046b6 <namei>
    8000598e:	c569                	beqz	a0,80005a58 <exec+0x15c>
    80005990:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	56e080e7          	jalr	1390(ra) # 80003f00 <ilock>
  //ADDED Q1
  // TODO isSwapProc... is it equal to (p->pid != INIT_PID && p->pid != SHELL_PID)?
  // if(isSwapProc(p) && init_metadata(p) < 0){
  //   goto bad;
  // }
  if(relevant_metadata_proc(p)) {
    8000599a:	c0843983          	ld	s3,-1016(s0)
    8000599e:	854e                	mv	a0,s3
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	4ae080e7          	jalr	1198(ra) # 80002e4e <relevant_metadata_proc>
    800059a8:	c901                	beqz	a0,800059b8 <exec+0xbc>
    if (init_metadata(p) < 0) {
    800059aa:	854e                	mv	a0,s3
    800059ac:	ffffd097          	auipc	ra,0xffffd
    800059b0:	aa4080e7          	jalr	-1372(ra) # 80002450 <init_metadata>
    800059b4:	02054963          	bltz	a0,800059e6 <exec+0xea>
    goto bad;
    }
  } 

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800059b8:	04000713          	li	a4,64
    800059bc:	4681                	li	a3,0
    800059be:	e4840613          	addi	a2,s0,-440
    800059c2:	4581                	li	a1,0
    800059c4:	8552                	mv	a0,s4
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	7ee080e7          	jalr	2030(ra) # 800041b4 <readi>
    800059ce:	04000793          	li	a5,64
    800059d2:	00f51a63          	bne	a0,a5,800059e6 <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800059d6:	e4842703          	lw	a4,-440(s0)
    800059da:	464c47b7          	lui	a5,0x464c4
    800059de:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800059e2:	08f70163          	beq	a4,a5,80005a64 <exec+0x168>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    800059e6:	10000613          	li	a2,256
    800059ea:	d1040593          	addi	a1,s0,-752
    800059ee:	854a                	mv	a0,s2
    800059f0:	ffffb097          	auipc	ra,0xffffb
    800059f4:	32a080e7          	jalr	810(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    800059f8:	10000613          	li	a2,256
    800059fc:	c1040593          	addi	a1,s0,-1008
    80005a00:	8526                	mv	a0,s1
    80005a02:	ffffb097          	auipc	ra,0xffffb
    80005a06:	318080e7          	jalr	792(ra) # 80000d1a <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005a0a:	8552                	mv	a0,s4
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	756080e7          	jalr	1878(ra) # 80004162 <iunlockput>
    end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	254080e7          	jalr	596(ra) # 80004c68 <end_op>
  }
  return -1;
    80005a1c:	557d                	li	a0,-1
}
    80005a1e:	42813083          	ld	ra,1064(sp)
    80005a22:	42013403          	ld	s0,1056(sp)
    80005a26:	41813483          	ld	s1,1048(sp)
    80005a2a:	41013903          	ld	s2,1040(sp)
    80005a2e:	40813983          	ld	s3,1032(sp)
    80005a32:	40013a03          	ld	s4,1024(sp)
    80005a36:	3f813a83          	ld	s5,1016(sp)
    80005a3a:	3f013b03          	ld	s6,1008(sp)
    80005a3e:	3e813b83          	ld	s7,1000(sp)
    80005a42:	3e013c03          	ld	s8,992(sp)
    80005a46:	3d813c83          	ld	s9,984(sp)
    80005a4a:	3d013d03          	ld	s10,976(sp)
    80005a4e:	3c813d83          	ld	s11,968(sp)
    80005a52:	43010113          	addi	sp,sp,1072
    80005a56:	8082                	ret
    end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	210080e7          	jalr	528(ra) # 80004c68 <end_op>
    return -1;
    80005a60:	557d                	li	a0,-1
    80005a62:	bf75                	j	80005a1e <exec+0x122>
  if((pagetable = proc_pagetable(p)) == 0)
    80005a64:	c0843503          	ld	a0,-1016(s0)
    80005a68:	ffffc097          	auipc	ra,0xffffc
    80005a6c:	060080e7          	jalr	96(ra) # 80001ac8 <proc_pagetable>
    80005a70:	8b2a                	mv	s6,a0
    80005a72:	d935                	beqz	a0,800059e6 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a74:	e6842783          	lw	a5,-408(s0)
    80005a78:	e8045703          	lhu	a4,-384(s0)
    80005a7c:	c735                	beqz	a4,80005ae8 <exec+0x1ec>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005a7e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a80:	c0043023          	sd	zero,-1024(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005a84:	6a85                	lui	s5,0x1
    80005a86:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80005a8a:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005a8e:	6d85                	lui	s11,0x1
    80005a90:	7d7d                	lui	s10,0xfffff
    80005a92:	a4ad                	j	80005cfc <exec+0x400>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005a94:	00004517          	auipc	a0,0x4
    80005a98:	f7c50513          	addi	a0,a0,-132 # 80009a10 <syscalls+0x2f0>
    80005a9c:	ffffb097          	auipc	ra,0xffffb
    80005aa0:	a8e080e7          	jalr	-1394(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005aa4:	874a                	mv	a4,s2
    80005aa6:	009c86bb          	addw	a3,s9,s1
    80005aaa:	4581                	li	a1,0
    80005aac:	8552                	mv	a0,s4
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	706080e7          	jalr	1798(ra) # 800041b4 <readi>
    80005ab6:	2501                	sext.w	a0,a0
    80005ab8:	1aa91c63          	bne	s2,a0,80005c70 <exec+0x374>
  for(i = 0; i < sz; i += PGSIZE){
    80005abc:	009d84bb          	addw	s1,s11,s1
    80005ac0:	013d09bb          	addw	s3,s10,s3
    80005ac4:	2174fc63          	bgeu	s1,s7,80005cdc <exec+0x3e0>
    pa = walkaddr(pagetable, va + i);
    80005ac8:	02049593          	slli	a1,s1,0x20
    80005acc:	9181                	srli	a1,a1,0x20
    80005ace:	95e2                	add	a1,a1,s8
    80005ad0:	855a                	mv	a0,s6
    80005ad2:	ffffb097          	auipc	ra,0xffffb
    80005ad6:	57a080e7          	jalr	1402(ra) # 8000104c <walkaddr>
    80005ada:	862a                	mv	a2,a0
    if(pa == 0)
    80005adc:	dd45                	beqz	a0,80005a94 <exec+0x198>
      n = PGSIZE;
    80005ade:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    80005ae0:	fd59f2e3          	bgeu	s3,s5,80005aa4 <exec+0x1a8>
      n = sz - i;
    80005ae4:	894e                	mv	s2,s3
    80005ae6:	bf7d                	j	80005aa4 <exec+0x1a8>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005ae8:	4481                	li	s1,0
  iunlockput(ip);
    80005aea:	8552                	mv	a0,s4
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	676080e7          	jalr	1654(ra) # 80004162 <iunlockput>
  end_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	174080e7          	jalr	372(ra) # 80004c68 <end_op>
  p = myproc();
    80005afc:	ffffc097          	auipc	ra,0xffffc
    80005b00:	f08080e7          	jalr	-248(ra) # 80001a04 <myproc>
    80005b04:	c0a43423          	sd	a0,-1016(s0)
  uint64 oldsz = p->sz;
    80005b08:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005b0c:	6785                	lui	a5,0x1
    80005b0e:	17fd                	addi	a5,a5,-1
    80005b10:	94be                	add	s1,s1,a5
    80005b12:	77fd                	lui	a5,0xfffff
    80005b14:	8fe5                	and	a5,a5,s1
    80005b16:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b1a:	6609                	lui	a2,0x2
    80005b1c:	963e                	add	a2,a2,a5
    80005b1e:	85be                	mv	a1,a5
    80005b20:	855a                	mv	a0,s6
    80005b22:	ffffc097          	auipc	ra,0xffffc
    80005b26:	932080e7          	jalr	-1742(ra) # 80001454 <uvmalloc>
    80005b2a:	8aaa                	mv	s5,a0
  ip = 0;
    80005b2c:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b2e:	14050163          	beqz	a0,80005c70 <exec+0x374>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005b32:	75f9                	lui	a1,0xffffe
    80005b34:	95aa                	add	a1,a1,a0
    80005b36:	855a                	mv	a0,s6
    80005b38:	ffffc097          	auipc	ra,0xffffc
    80005b3c:	b5a080e7          	jalr	-1190(ra) # 80001692 <uvmclear>
  stackbase = sp - PGSIZE;
    80005b40:	7bfd                	lui	s7,0xfffff
    80005b42:	9bd6                	add	s7,s7,s5
  for(argc = 0; argv[argc]; argc++) {
    80005b44:	be843783          	ld	a5,-1048(s0)
    80005b48:	6388                	ld	a0,0(a5)
    80005b4a:	c925                	beqz	a0,80005bba <exec+0x2be>
    80005b4c:	e8840993          	addi	s3,s0,-376
    80005b50:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005b54:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005b56:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005b58:	ffffb097          	auipc	ra,0xffffb
    80005b5c:	2ea080e7          	jalr	746(ra) # 80000e42 <strlen>
    80005b60:	0015079b          	addiw	a5,a0,1
    80005b64:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005b68:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005b6c:	15796c63          	bltu	s2,s7,80005cc4 <exec+0x3c8>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005b70:	be843d03          	ld	s10,-1048(s0)
    80005b74:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80005b78:	8552                	mv	a0,s4
    80005b7a:	ffffb097          	auipc	ra,0xffffb
    80005b7e:	2c8080e7          	jalr	712(ra) # 80000e42 <strlen>
    80005b82:	0015069b          	addiw	a3,a0,1
    80005b86:	8652                	mv	a2,s4
    80005b88:	85ca                	mv	a1,s2
    80005b8a:	855a                	mv	a0,s6
    80005b8c:	ffffc097          	auipc	ra,0xffffc
    80005b90:	b38080e7          	jalr	-1224(ra) # 800016c4 <copyout>
    80005b94:	12054c63          	bltz	a0,80005ccc <exec+0x3d0>
    ustack[argc] = sp;
    80005b98:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005b9c:	0485                	addi	s1,s1,1
    80005b9e:	008d0793          	addi	a5,s10,8
    80005ba2:	bef43423          	sd	a5,-1048(s0)
    80005ba6:	008d3503          	ld	a0,8(s10)
    80005baa:	c911                	beqz	a0,80005bbe <exec+0x2c2>
    if(argc >= MAXARG)
    80005bac:	09a1                	addi	s3,s3,8
    80005bae:	fb8995e3          	bne	s3,s8,80005b58 <exec+0x25c>
  sz = sz1;
    80005bb2:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005bb6:	4a01                	li	s4,0
    80005bb8:	a865                	j	80005c70 <exec+0x374>
  sp = sz;
    80005bba:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005bbc:	4481                	li	s1,0
  ustack[argc] = 0;
    80005bbe:	00349793          	slli	a5,s1,0x3
    80005bc2:	f9040713          	addi	a4,s0,-112
    80005bc6:	97ba                	add	a5,a5,a4
    80005bc8:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005bcc:	00148693          	addi	a3,s1,1
    80005bd0:	068e                	slli	a3,a3,0x3
    80005bd2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005bd6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005bda:	01797663          	bgeu	s2,s7,80005be6 <exec+0x2ea>
  sz = sz1;
    80005bde:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005be2:	4a01                	li	s4,0
    80005be4:	a071                	j	80005c70 <exec+0x374>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005be6:	e8840613          	addi	a2,s0,-376
    80005bea:	85ca                	mv	a1,s2
    80005bec:	855a                	mv	a0,s6
    80005bee:	ffffc097          	auipc	ra,0xffffc
    80005bf2:	ad6080e7          	jalr	-1322(ra) # 800016c4 <copyout>
    80005bf6:	0c054f63          	bltz	a0,80005cd4 <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005bfa:	c0843783          	ld	a5,-1016(s0)
    80005bfe:	6fbc                	ld	a5,88(a5)
    80005c00:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c04:	be043783          	ld	a5,-1056(s0)
    80005c08:	0007c703          	lbu	a4,0(a5)
    80005c0c:	cf11                	beqz	a4,80005c28 <exec+0x32c>
    80005c0e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005c10:	02f00693          	li	a3,47
    80005c14:	a039                	j	80005c22 <exec+0x326>
      last = s+1;
    80005c16:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005c1a:	0785                	addi	a5,a5,1
    80005c1c:	fff7c703          	lbu	a4,-1(a5)
    80005c20:	c701                	beqz	a4,80005c28 <exec+0x32c>
    if(*s == '/')
    80005c22:	fed71ce3          	bne	a4,a3,80005c1a <exec+0x31e>
    80005c26:	bfc5                	j	80005c16 <exec+0x31a>
  safestrcpy(p->name, last, sizeof(p->name));
    80005c28:	4641                	li	a2,16
    80005c2a:	be043583          	ld	a1,-1056(s0)
    80005c2e:	c0843983          	ld	s3,-1016(s0)
    80005c32:	15898513          	addi	a0,s3,344
    80005c36:	ffffb097          	auipc	ra,0xffffb
    80005c3a:	1da080e7          	jalr	474(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005c3e:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005c42:	0569b823          	sd	s6,80(s3)
  p->sz = sz;
    80005c46:	0559b423          	sd	s5,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005c4a:	0589b783          	ld	a5,88(s3)
    80005c4e:	e6043703          	ld	a4,-416(s0)
    80005c52:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005c54:	0589b783          	ld	a5,88(s3)
    80005c58:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005c5c:	85e6                	mv	a1,s9
    80005c5e:	ffffc097          	auipc	ra,0xffffc
    80005c62:	f06080e7          	jalr	-250(ra) # 80001b64 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005c66:	0004851b          	sext.w	a0,s1
    80005c6a:	bb55                	j	80005a1e <exec+0x122>
    80005c6c:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005c70:	10000613          	li	a2,256
    80005c74:	d1040593          	addi	a1,s0,-752
    80005c78:	c0843483          	ld	s1,-1016(s0)
    80005c7c:	17048513          	addi	a0,s1,368
    80005c80:	ffffb097          	auipc	ra,0xffffb
    80005c84:	09a080e7          	jalr	154(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005c88:	10000613          	li	a2,256
    80005c8c:	c1040593          	addi	a1,s0,-1008
    80005c90:	27048513          	addi	a0,s1,624
    80005c94:	ffffb097          	auipc	ra,0xffffb
    80005c98:	086080e7          	jalr	134(ra) # 80000d1a <memmove>
    proc_freepagetable(pagetable, sz);
    80005c9c:	bf043583          	ld	a1,-1040(s0)
    80005ca0:	855a                	mv	a0,s6
    80005ca2:	ffffc097          	auipc	ra,0xffffc
    80005ca6:	ec2080e7          	jalr	-318(ra) # 80001b64 <proc_freepagetable>
  if(ip){
    80005caa:	d60a10e3          	bnez	s4,80005a0a <exec+0x10e>
  return -1;
    80005cae:	557d                	li	a0,-1
    80005cb0:	b3bd                	j	80005a1e <exec+0x122>
    80005cb2:	be943823          	sd	s1,-1040(s0)
    80005cb6:	bf6d                	j	80005c70 <exec+0x374>
    80005cb8:	be943823          	sd	s1,-1040(s0)
    80005cbc:	bf55                	j	80005c70 <exec+0x374>
    80005cbe:	be943823          	sd	s1,-1040(s0)
    80005cc2:	b77d                	j	80005c70 <exec+0x374>
  sz = sz1;
    80005cc4:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005cc8:	4a01                	li	s4,0
    80005cca:	b75d                	j	80005c70 <exec+0x374>
  sz = sz1;
    80005ccc:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005cd0:	4a01                	li	s4,0
    80005cd2:	bf79                	j	80005c70 <exec+0x374>
  sz = sz1;
    80005cd4:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005cd8:	4a01                	li	s4,0
    80005cda:	bf59                	j	80005c70 <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005cdc:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005ce0:	c0043783          	ld	a5,-1024(s0)
    80005ce4:	0017869b          	addiw	a3,a5,1
    80005ce8:	c0d43023          	sd	a3,-1024(s0)
    80005cec:	bf843783          	ld	a5,-1032(s0)
    80005cf0:	0387879b          	addiw	a5,a5,56
    80005cf4:	e8045703          	lhu	a4,-384(s0)
    80005cf8:	dee6d9e3          	bge	a3,a4,80005aea <exec+0x1ee>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005cfc:	2781                	sext.w	a5,a5
    80005cfe:	bef43c23          	sd	a5,-1032(s0)
    80005d02:	03800713          	li	a4,56
    80005d06:	86be                	mv	a3,a5
    80005d08:	e1040613          	addi	a2,s0,-496
    80005d0c:	4581                	li	a1,0
    80005d0e:	8552                	mv	a0,s4
    80005d10:	ffffe097          	auipc	ra,0xffffe
    80005d14:	4a4080e7          	jalr	1188(ra) # 800041b4 <readi>
    80005d18:	03800793          	li	a5,56
    80005d1c:	f4f518e3          	bne	a0,a5,80005c6c <exec+0x370>
    if(ph.type != ELF_PROG_LOAD)
    80005d20:	e1042783          	lw	a5,-496(s0)
    80005d24:	4705                	li	a4,1
    80005d26:	fae79de3          	bne	a5,a4,80005ce0 <exec+0x3e4>
    if(ph.memsz < ph.filesz)
    80005d2a:	e3843603          	ld	a2,-456(s0)
    80005d2e:	e3043783          	ld	a5,-464(s0)
    80005d32:	f8f660e3          	bltu	a2,a5,80005cb2 <exec+0x3b6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005d36:	e2043783          	ld	a5,-480(s0)
    80005d3a:	963e                	add	a2,a2,a5
    80005d3c:	f6f66ee3          	bltu	a2,a5,80005cb8 <exec+0x3bc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d40:	85a6                	mv	a1,s1
    80005d42:	855a                	mv	a0,s6
    80005d44:	ffffb097          	auipc	ra,0xffffb
    80005d48:	710080e7          	jalr	1808(ra) # 80001454 <uvmalloc>
    80005d4c:	bea43823          	sd	a0,-1040(s0)
    80005d50:	d53d                	beqz	a0,80005cbe <exec+0x3c2>
    if(ph.vaddr % PGSIZE != 0)
    80005d52:	e2043c03          	ld	s8,-480(s0)
    80005d56:	bd843783          	ld	a5,-1064(s0)
    80005d5a:	00fc77b3          	and	a5,s8,a5
    80005d5e:	fb89                	bnez	a5,80005c70 <exec+0x374>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005d60:	e1842c83          	lw	s9,-488(s0)
    80005d64:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005d68:	f60b8ae3          	beqz	s7,80005cdc <exec+0x3e0>
    80005d6c:	89de                	mv	s3,s7
    80005d6e:	4481                	li	s1,0
    80005d70:	bba1                	j	80005ac8 <exec+0x1cc>

0000000080005d72 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005d72:	7179                	addi	sp,sp,-48
    80005d74:	f406                	sd	ra,40(sp)
    80005d76:	f022                	sd	s0,32(sp)
    80005d78:	ec26                	sd	s1,24(sp)
    80005d7a:	e84a                	sd	s2,16(sp)
    80005d7c:	1800                	addi	s0,sp,48
    80005d7e:	892e                	mv	s2,a1
    80005d80:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005d82:	fdc40593          	addi	a1,s0,-36
    80005d86:	ffffd097          	auipc	ra,0xffffd
    80005d8a:	608080e7          	jalr	1544(ra) # 8000338e <argint>
    80005d8e:	04054063          	bltz	a0,80005dce <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005d92:	fdc42703          	lw	a4,-36(s0)
    80005d96:	47bd                	li	a5,15
    80005d98:	02e7ed63          	bltu	a5,a4,80005dd2 <argfd+0x60>
    80005d9c:	ffffc097          	auipc	ra,0xffffc
    80005da0:	c68080e7          	jalr	-920(ra) # 80001a04 <myproc>
    80005da4:	fdc42703          	lw	a4,-36(s0)
    80005da8:	01a70793          	addi	a5,a4,26
    80005dac:	078e                	slli	a5,a5,0x3
    80005dae:	953e                	add	a0,a0,a5
    80005db0:	611c                	ld	a5,0(a0)
    80005db2:	c395                	beqz	a5,80005dd6 <argfd+0x64>
    return -1;
  if(pfd)
    80005db4:	00090463          	beqz	s2,80005dbc <argfd+0x4a>
    *pfd = fd;
    80005db8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005dbc:	4501                	li	a0,0
  if(pf)
    80005dbe:	c091                	beqz	s1,80005dc2 <argfd+0x50>
    *pf = f;
    80005dc0:	e09c                	sd	a5,0(s1)
}
    80005dc2:	70a2                	ld	ra,40(sp)
    80005dc4:	7402                	ld	s0,32(sp)
    80005dc6:	64e2                	ld	s1,24(sp)
    80005dc8:	6942                	ld	s2,16(sp)
    80005dca:	6145                	addi	sp,sp,48
    80005dcc:	8082                	ret
    return -1;
    80005dce:	557d                	li	a0,-1
    80005dd0:	bfcd                	j	80005dc2 <argfd+0x50>
    return -1;
    80005dd2:	557d                	li	a0,-1
    80005dd4:	b7fd                	j	80005dc2 <argfd+0x50>
    80005dd6:	557d                	li	a0,-1
    80005dd8:	b7ed                	j	80005dc2 <argfd+0x50>

0000000080005dda <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005dda:	1101                	addi	sp,sp,-32
    80005ddc:	ec06                	sd	ra,24(sp)
    80005dde:	e822                	sd	s0,16(sp)
    80005de0:	e426                	sd	s1,8(sp)
    80005de2:	1000                	addi	s0,sp,32
    80005de4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005de6:	ffffc097          	auipc	ra,0xffffc
    80005dea:	c1e080e7          	jalr	-994(ra) # 80001a04 <myproc>
    80005dee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005df0:	0d050793          	addi	a5,a0,208
    80005df4:	4501                	li	a0,0
    80005df6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005df8:	6398                	ld	a4,0(a5)
    80005dfa:	cb19                	beqz	a4,80005e10 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005dfc:	2505                	addiw	a0,a0,1
    80005dfe:	07a1                	addi	a5,a5,8
    80005e00:	fed51ce3          	bne	a0,a3,80005df8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005e04:	557d                	li	a0,-1
}
    80005e06:	60e2                	ld	ra,24(sp)
    80005e08:	6442                	ld	s0,16(sp)
    80005e0a:	64a2                	ld	s1,8(sp)
    80005e0c:	6105                	addi	sp,sp,32
    80005e0e:	8082                	ret
      p->ofile[fd] = f;
    80005e10:	01a50793          	addi	a5,a0,26
    80005e14:	078e                	slli	a5,a5,0x3
    80005e16:	963e                	add	a2,a2,a5
    80005e18:	e204                	sd	s1,0(a2)
      return fd;
    80005e1a:	b7f5                	j	80005e06 <fdalloc+0x2c>

0000000080005e1c <sys_dup>:

uint64
sys_dup(void)
{
    80005e1c:	7179                	addi	sp,sp,-48
    80005e1e:	f406                	sd	ra,40(sp)
    80005e20:	f022                	sd	s0,32(sp)
    80005e22:	ec26                	sd	s1,24(sp)
    80005e24:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005e26:	fd840613          	addi	a2,s0,-40
    80005e2a:	4581                	li	a1,0
    80005e2c:	4501                	li	a0,0
    80005e2e:	00000097          	auipc	ra,0x0
    80005e32:	f44080e7          	jalr	-188(ra) # 80005d72 <argfd>
    return -1;
    80005e36:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e38:	02054363          	bltz	a0,80005e5e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e3c:	fd843503          	ld	a0,-40(s0)
    80005e40:	00000097          	auipc	ra,0x0
    80005e44:	f9a080e7          	jalr	-102(ra) # 80005dda <fdalloc>
    80005e48:	84aa                	mv	s1,a0
    return -1;
    80005e4a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e4c:	00054963          	bltz	a0,80005e5e <sys_dup+0x42>
  filedup(f);
    80005e50:	fd843503          	ld	a0,-40(s0)
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	20e080e7          	jalr	526(ra) # 80005062 <filedup>
  return fd;
    80005e5c:	87a6                	mv	a5,s1
}
    80005e5e:	853e                	mv	a0,a5
    80005e60:	70a2                	ld	ra,40(sp)
    80005e62:	7402                	ld	s0,32(sp)
    80005e64:	64e2                	ld	s1,24(sp)
    80005e66:	6145                	addi	sp,sp,48
    80005e68:	8082                	ret

0000000080005e6a <sys_read>:

uint64
sys_read(void)
{
    80005e6a:	7179                	addi	sp,sp,-48
    80005e6c:	f406                	sd	ra,40(sp)
    80005e6e:	f022                	sd	s0,32(sp)
    80005e70:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e72:	fe840613          	addi	a2,s0,-24
    80005e76:	4581                	li	a1,0
    80005e78:	4501                	li	a0,0
    80005e7a:	00000097          	auipc	ra,0x0
    80005e7e:	ef8080e7          	jalr	-264(ra) # 80005d72 <argfd>
    return -1;
    80005e82:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e84:	04054163          	bltz	a0,80005ec6 <sys_read+0x5c>
    80005e88:	fe440593          	addi	a1,s0,-28
    80005e8c:	4509                	li	a0,2
    80005e8e:	ffffd097          	auipc	ra,0xffffd
    80005e92:	500080e7          	jalr	1280(ra) # 8000338e <argint>
    return -1;
    80005e96:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e98:	02054763          	bltz	a0,80005ec6 <sys_read+0x5c>
    80005e9c:	fd840593          	addi	a1,s0,-40
    80005ea0:	4505                	li	a0,1
    80005ea2:	ffffd097          	auipc	ra,0xffffd
    80005ea6:	50e080e7          	jalr	1294(ra) # 800033b0 <argaddr>
    return -1;
    80005eaa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eac:	00054d63          	bltz	a0,80005ec6 <sys_read+0x5c>
  return fileread(f, p, n);
    80005eb0:	fe442603          	lw	a2,-28(s0)
    80005eb4:	fd843583          	ld	a1,-40(s0)
    80005eb8:	fe843503          	ld	a0,-24(s0)
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	332080e7          	jalr	818(ra) # 800051ee <fileread>
    80005ec4:	87aa                	mv	a5,a0
}
    80005ec6:	853e                	mv	a0,a5
    80005ec8:	70a2                	ld	ra,40(sp)
    80005eca:	7402                	ld	s0,32(sp)
    80005ecc:	6145                	addi	sp,sp,48
    80005ece:	8082                	ret

0000000080005ed0 <sys_write>:

uint64
sys_write(void)
{
    80005ed0:	7179                	addi	sp,sp,-48
    80005ed2:	f406                	sd	ra,40(sp)
    80005ed4:	f022                	sd	s0,32(sp)
    80005ed6:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ed8:	fe840613          	addi	a2,s0,-24
    80005edc:	4581                	li	a1,0
    80005ede:	4501                	li	a0,0
    80005ee0:	00000097          	auipc	ra,0x0
    80005ee4:	e92080e7          	jalr	-366(ra) # 80005d72 <argfd>
    return -1;
    80005ee8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eea:	04054163          	bltz	a0,80005f2c <sys_write+0x5c>
    80005eee:	fe440593          	addi	a1,s0,-28
    80005ef2:	4509                	li	a0,2
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	49a080e7          	jalr	1178(ra) # 8000338e <argint>
    return -1;
    80005efc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005efe:	02054763          	bltz	a0,80005f2c <sys_write+0x5c>
    80005f02:	fd840593          	addi	a1,s0,-40
    80005f06:	4505                	li	a0,1
    80005f08:	ffffd097          	auipc	ra,0xffffd
    80005f0c:	4a8080e7          	jalr	1192(ra) # 800033b0 <argaddr>
    return -1;
    80005f10:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f12:	00054d63          	bltz	a0,80005f2c <sys_write+0x5c>

  return filewrite(f, p, n);
    80005f16:	fe442603          	lw	a2,-28(s0)
    80005f1a:	fd843583          	ld	a1,-40(s0)
    80005f1e:	fe843503          	ld	a0,-24(s0)
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	38e080e7          	jalr	910(ra) # 800052b0 <filewrite>
    80005f2a:	87aa                	mv	a5,a0
}
    80005f2c:	853e                	mv	a0,a5
    80005f2e:	70a2                	ld	ra,40(sp)
    80005f30:	7402                	ld	s0,32(sp)
    80005f32:	6145                	addi	sp,sp,48
    80005f34:	8082                	ret

0000000080005f36 <sys_close>:

uint64
sys_close(void)
{
    80005f36:	1101                	addi	sp,sp,-32
    80005f38:	ec06                	sd	ra,24(sp)
    80005f3a:	e822                	sd	s0,16(sp)
    80005f3c:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005f3e:	fe040613          	addi	a2,s0,-32
    80005f42:	fec40593          	addi	a1,s0,-20
    80005f46:	4501                	li	a0,0
    80005f48:	00000097          	auipc	ra,0x0
    80005f4c:	e2a080e7          	jalr	-470(ra) # 80005d72 <argfd>
    return -1;
    80005f50:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f52:	02054463          	bltz	a0,80005f7a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f56:	ffffc097          	auipc	ra,0xffffc
    80005f5a:	aae080e7          	jalr	-1362(ra) # 80001a04 <myproc>
    80005f5e:	fec42783          	lw	a5,-20(s0)
    80005f62:	07e9                	addi	a5,a5,26
    80005f64:	078e                	slli	a5,a5,0x3
    80005f66:	97aa                	add	a5,a5,a0
    80005f68:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005f6c:	fe043503          	ld	a0,-32(s0)
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	144080e7          	jalr	324(ra) # 800050b4 <fileclose>
  return 0;
    80005f78:	4781                	li	a5,0
}
    80005f7a:	853e                	mv	a0,a5
    80005f7c:	60e2                	ld	ra,24(sp)
    80005f7e:	6442                	ld	s0,16(sp)
    80005f80:	6105                	addi	sp,sp,32
    80005f82:	8082                	ret

0000000080005f84 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005f84:	1101                	addi	sp,sp,-32
    80005f86:	ec06                	sd	ra,24(sp)
    80005f88:	e822                	sd	s0,16(sp)
    80005f8a:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f8c:	fe840613          	addi	a2,s0,-24
    80005f90:	4581                	li	a1,0
    80005f92:	4501                	li	a0,0
    80005f94:	00000097          	auipc	ra,0x0
    80005f98:	dde080e7          	jalr	-546(ra) # 80005d72 <argfd>
    return -1;
    80005f9c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f9e:	02054563          	bltz	a0,80005fc8 <sys_fstat+0x44>
    80005fa2:	fe040593          	addi	a1,s0,-32
    80005fa6:	4505                	li	a0,1
    80005fa8:	ffffd097          	auipc	ra,0xffffd
    80005fac:	408080e7          	jalr	1032(ra) # 800033b0 <argaddr>
    return -1;
    80005fb0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fb2:	00054b63          	bltz	a0,80005fc8 <sys_fstat+0x44>
  return filestat(f, st);
    80005fb6:	fe043583          	ld	a1,-32(s0)
    80005fba:	fe843503          	ld	a0,-24(s0)
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	1be080e7          	jalr	446(ra) # 8000517c <filestat>
    80005fc6:	87aa                	mv	a5,a0
}
    80005fc8:	853e                	mv	a0,a5
    80005fca:	60e2                	ld	ra,24(sp)
    80005fcc:	6442                	ld	s0,16(sp)
    80005fce:	6105                	addi	sp,sp,32
    80005fd0:	8082                	ret

0000000080005fd2 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005fd2:	7169                	addi	sp,sp,-304
    80005fd4:	f606                	sd	ra,296(sp)
    80005fd6:	f222                	sd	s0,288(sp)
    80005fd8:	ee26                	sd	s1,280(sp)
    80005fda:	ea4a                	sd	s2,272(sp)
    80005fdc:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fde:	08000613          	li	a2,128
    80005fe2:	ed040593          	addi	a1,s0,-304
    80005fe6:	4501                	li	a0,0
    80005fe8:	ffffd097          	auipc	ra,0xffffd
    80005fec:	3ea080e7          	jalr	1002(ra) # 800033d2 <argstr>
    return -1;
    80005ff0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ff2:	10054e63          	bltz	a0,8000610e <sys_link+0x13c>
    80005ff6:	08000613          	li	a2,128
    80005ffa:	f5040593          	addi	a1,s0,-176
    80005ffe:	4505                	li	a0,1
    80006000:	ffffd097          	auipc	ra,0xffffd
    80006004:	3d2080e7          	jalr	978(ra) # 800033d2 <argstr>
    return -1;
    80006008:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000600a:	10054263          	bltz	a0,8000610e <sys_link+0x13c>

  begin_op();
    8000600e:	fffff097          	auipc	ra,0xfffff
    80006012:	bda080e7          	jalr	-1062(ra) # 80004be8 <begin_op>
  if((ip = namei(old)) == 0){
    80006016:	ed040513          	addi	a0,s0,-304
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	69c080e7          	jalr	1692(ra) # 800046b6 <namei>
    80006022:	84aa                	mv	s1,a0
    80006024:	c551                	beqz	a0,800060b0 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80006026:	ffffe097          	auipc	ra,0xffffe
    8000602a:	eda080e7          	jalr	-294(ra) # 80003f00 <ilock>
  if(ip->type == T_DIR){
    8000602e:	04449703          	lh	a4,68(s1)
    80006032:	4785                	li	a5,1
    80006034:	08f70463          	beq	a4,a5,800060bc <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80006038:	04a4d783          	lhu	a5,74(s1)
    8000603c:	2785                	addiw	a5,a5,1
    8000603e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006042:	8526                	mv	a0,s1
    80006044:	ffffe097          	auipc	ra,0xffffe
    80006048:	df2080e7          	jalr	-526(ra) # 80003e36 <iupdate>
  iunlock(ip);
    8000604c:	8526                	mv	a0,s1
    8000604e:	ffffe097          	auipc	ra,0xffffe
    80006052:	f74080e7          	jalr	-140(ra) # 80003fc2 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80006056:	fd040593          	addi	a1,s0,-48
    8000605a:	f5040513          	addi	a0,s0,-176
    8000605e:	ffffe097          	auipc	ra,0xffffe
    80006062:	676080e7          	jalr	1654(ra) # 800046d4 <nameiparent>
    80006066:	892a                	mv	s2,a0
    80006068:	c935                	beqz	a0,800060dc <sys_link+0x10a>
    goto bad;
  ilock(dp);
    8000606a:	ffffe097          	auipc	ra,0xffffe
    8000606e:	e96080e7          	jalr	-362(ra) # 80003f00 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006072:	00092703          	lw	a4,0(s2)
    80006076:	409c                	lw	a5,0(s1)
    80006078:	04f71d63          	bne	a4,a5,800060d2 <sys_link+0x100>
    8000607c:	40d0                	lw	a2,4(s1)
    8000607e:	fd040593          	addi	a1,s0,-48
    80006082:	854a                	mv	a0,s2
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	570080e7          	jalr	1392(ra) # 800045f4 <dirlink>
    8000608c:	04054363          	bltz	a0,800060d2 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80006090:	854a                	mv	a0,s2
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	0d0080e7          	jalr	208(ra) # 80004162 <iunlockput>
  iput(ip);
    8000609a:	8526                	mv	a0,s1
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	01e080e7          	jalr	30(ra) # 800040ba <iput>

  end_op();
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	bc4080e7          	jalr	-1084(ra) # 80004c68 <end_op>

  return 0;
    800060ac:	4781                	li	a5,0
    800060ae:	a085                	j	8000610e <sys_link+0x13c>
    end_op();
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	bb8080e7          	jalr	-1096(ra) # 80004c68 <end_op>
    return -1;
    800060b8:	57fd                	li	a5,-1
    800060ba:	a891                	j	8000610e <sys_link+0x13c>
    iunlockput(ip);
    800060bc:	8526                	mv	a0,s1
    800060be:	ffffe097          	auipc	ra,0xffffe
    800060c2:	0a4080e7          	jalr	164(ra) # 80004162 <iunlockput>
    end_op();
    800060c6:	fffff097          	auipc	ra,0xfffff
    800060ca:	ba2080e7          	jalr	-1118(ra) # 80004c68 <end_op>
    return -1;
    800060ce:	57fd                	li	a5,-1
    800060d0:	a83d                	j	8000610e <sys_link+0x13c>
    iunlockput(dp);
    800060d2:	854a                	mv	a0,s2
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	08e080e7          	jalr	142(ra) # 80004162 <iunlockput>

bad:
  ilock(ip);
    800060dc:	8526                	mv	a0,s1
    800060de:	ffffe097          	auipc	ra,0xffffe
    800060e2:	e22080e7          	jalr	-478(ra) # 80003f00 <ilock>
  ip->nlink--;
    800060e6:	04a4d783          	lhu	a5,74(s1)
    800060ea:	37fd                	addiw	a5,a5,-1
    800060ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060f0:	8526                	mv	a0,s1
    800060f2:	ffffe097          	auipc	ra,0xffffe
    800060f6:	d44080e7          	jalr	-700(ra) # 80003e36 <iupdate>
  iunlockput(ip);
    800060fa:	8526                	mv	a0,s1
    800060fc:	ffffe097          	auipc	ra,0xffffe
    80006100:	066080e7          	jalr	102(ra) # 80004162 <iunlockput>
  end_op();
    80006104:	fffff097          	auipc	ra,0xfffff
    80006108:	b64080e7          	jalr	-1180(ra) # 80004c68 <end_op>
  return -1;
    8000610c:	57fd                	li	a5,-1
}
    8000610e:	853e                	mv	a0,a5
    80006110:	70b2                	ld	ra,296(sp)
    80006112:	7412                	ld	s0,288(sp)
    80006114:	64f2                	ld	s1,280(sp)
    80006116:	6952                	ld	s2,272(sp)
    80006118:	6155                	addi	sp,sp,304
    8000611a:	8082                	ret

000000008000611c <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000611c:	4578                	lw	a4,76(a0)
    8000611e:	02000793          	li	a5,32
    80006122:	04e7fa63          	bgeu	a5,a4,80006176 <isdirempty+0x5a>
{
    80006126:	7179                	addi	sp,sp,-48
    80006128:	f406                	sd	ra,40(sp)
    8000612a:	f022                	sd	s0,32(sp)
    8000612c:	ec26                	sd	s1,24(sp)
    8000612e:	e84a                	sd	s2,16(sp)
    80006130:	1800                	addi	s0,sp,48
    80006132:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006134:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006138:	4741                	li	a4,16
    8000613a:	86a6                	mv	a3,s1
    8000613c:	fd040613          	addi	a2,s0,-48
    80006140:	4581                	li	a1,0
    80006142:	854a                	mv	a0,s2
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	070080e7          	jalr	112(ra) # 800041b4 <readi>
    8000614c:	47c1                	li	a5,16
    8000614e:	00f51c63          	bne	a0,a5,80006166 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80006152:	fd045783          	lhu	a5,-48(s0)
    80006156:	e395                	bnez	a5,8000617a <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006158:	24c1                	addiw	s1,s1,16
    8000615a:	04c92783          	lw	a5,76(s2)
    8000615e:	fcf4ede3          	bltu	s1,a5,80006138 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80006162:	4505                	li	a0,1
    80006164:	a821                	j	8000617c <isdirempty+0x60>
      panic("isdirempty: readi");
    80006166:	00004517          	auipc	a0,0x4
    8000616a:	8ca50513          	addi	a0,a0,-1846 # 80009a30 <syscalls+0x310>
    8000616e:	ffffa097          	auipc	ra,0xffffa
    80006172:	3bc080e7          	jalr	956(ra) # 8000052a <panic>
  return 1;
    80006176:	4505                	li	a0,1
}
    80006178:	8082                	ret
      return 0;
    8000617a:	4501                	li	a0,0
}
    8000617c:	70a2                	ld	ra,40(sp)
    8000617e:	7402                	ld	s0,32(sp)
    80006180:	64e2                	ld	s1,24(sp)
    80006182:	6942                	ld	s2,16(sp)
    80006184:	6145                	addi	sp,sp,48
    80006186:	8082                	ret

0000000080006188 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006188:	7155                	addi	sp,sp,-208
    8000618a:	e586                	sd	ra,200(sp)
    8000618c:	e1a2                	sd	s0,192(sp)
    8000618e:	fd26                	sd	s1,184(sp)
    80006190:	f94a                	sd	s2,176(sp)
    80006192:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006194:	08000613          	li	a2,128
    80006198:	f4040593          	addi	a1,s0,-192
    8000619c:	4501                	li	a0,0
    8000619e:	ffffd097          	auipc	ra,0xffffd
    800061a2:	234080e7          	jalr	564(ra) # 800033d2 <argstr>
    800061a6:	16054363          	bltz	a0,8000630c <sys_unlink+0x184>
    return -1;

  begin_op();
    800061aa:	fffff097          	auipc	ra,0xfffff
    800061ae:	a3e080e7          	jalr	-1474(ra) # 80004be8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800061b2:	fc040593          	addi	a1,s0,-64
    800061b6:	f4040513          	addi	a0,s0,-192
    800061ba:	ffffe097          	auipc	ra,0xffffe
    800061be:	51a080e7          	jalr	1306(ra) # 800046d4 <nameiparent>
    800061c2:	84aa                	mv	s1,a0
    800061c4:	c961                	beqz	a0,80006294 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    800061c6:	ffffe097          	auipc	ra,0xffffe
    800061ca:	d3a080e7          	jalr	-710(ra) # 80003f00 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800061ce:	00003597          	auipc	a1,0x3
    800061d2:	74258593          	addi	a1,a1,1858 # 80009910 <syscalls+0x1f0>
    800061d6:	fc040513          	addi	a0,s0,-64
    800061da:	ffffe097          	auipc	ra,0xffffe
    800061de:	1f0080e7          	jalr	496(ra) # 800043ca <namecmp>
    800061e2:	c175                	beqz	a0,800062c6 <sys_unlink+0x13e>
    800061e4:	00003597          	auipc	a1,0x3
    800061e8:	73458593          	addi	a1,a1,1844 # 80009918 <syscalls+0x1f8>
    800061ec:	fc040513          	addi	a0,s0,-64
    800061f0:	ffffe097          	auipc	ra,0xffffe
    800061f4:	1da080e7          	jalr	474(ra) # 800043ca <namecmp>
    800061f8:	c579                	beqz	a0,800062c6 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800061fa:	f3c40613          	addi	a2,s0,-196
    800061fe:	fc040593          	addi	a1,s0,-64
    80006202:	8526                	mv	a0,s1
    80006204:	ffffe097          	auipc	ra,0xffffe
    80006208:	1e0080e7          	jalr	480(ra) # 800043e4 <dirlookup>
    8000620c:	892a                	mv	s2,a0
    8000620e:	cd45                	beqz	a0,800062c6 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80006210:	ffffe097          	auipc	ra,0xffffe
    80006214:	cf0080e7          	jalr	-784(ra) # 80003f00 <ilock>

  if(ip->nlink < 1)
    80006218:	04a91783          	lh	a5,74(s2)
    8000621c:	08f05263          	blez	a5,800062a0 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006220:	04491703          	lh	a4,68(s2)
    80006224:	4785                	li	a5,1
    80006226:	08f70563          	beq	a4,a5,800062b0 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    8000622a:	4641                	li	a2,16
    8000622c:	4581                	li	a1,0
    8000622e:	fd040513          	addi	a0,s0,-48
    80006232:	ffffb097          	auipc	ra,0xffffb
    80006236:	a8c080e7          	jalr	-1396(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000623a:	4741                	li	a4,16
    8000623c:	f3c42683          	lw	a3,-196(s0)
    80006240:	fd040613          	addi	a2,s0,-48
    80006244:	4581                	li	a1,0
    80006246:	8526                	mv	a0,s1
    80006248:	ffffe097          	auipc	ra,0xffffe
    8000624c:	064080e7          	jalr	100(ra) # 800042ac <writei>
    80006250:	47c1                	li	a5,16
    80006252:	08f51a63          	bne	a0,a5,800062e6 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80006256:	04491703          	lh	a4,68(s2)
    8000625a:	4785                	li	a5,1
    8000625c:	08f70d63          	beq	a4,a5,800062f6 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80006260:	8526                	mv	a0,s1
    80006262:	ffffe097          	auipc	ra,0xffffe
    80006266:	f00080e7          	jalr	-256(ra) # 80004162 <iunlockput>

  ip->nlink--;
    8000626a:	04a95783          	lhu	a5,74(s2)
    8000626e:	37fd                	addiw	a5,a5,-1
    80006270:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006274:	854a                	mv	a0,s2
    80006276:	ffffe097          	auipc	ra,0xffffe
    8000627a:	bc0080e7          	jalr	-1088(ra) # 80003e36 <iupdate>
  iunlockput(ip);
    8000627e:	854a                	mv	a0,s2
    80006280:	ffffe097          	auipc	ra,0xffffe
    80006284:	ee2080e7          	jalr	-286(ra) # 80004162 <iunlockput>

  end_op();
    80006288:	fffff097          	auipc	ra,0xfffff
    8000628c:	9e0080e7          	jalr	-1568(ra) # 80004c68 <end_op>

  return 0;
    80006290:	4501                	li	a0,0
    80006292:	a0a1                	j	800062da <sys_unlink+0x152>
    end_op();
    80006294:	fffff097          	auipc	ra,0xfffff
    80006298:	9d4080e7          	jalr	-1580(ra) # 80004c68 <end_op>
    return -1;
    8000629c:	557d                	li	a0,-1
    8000629e:	a835                	j	800062da <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    800062a0:	00003517          	auipc	a0,0x3
    800062a4:	68050513          	addi	a0,a0,1664 # 80009920 <syscalls+0x200>
    800062a8:	ffffa097          	auipc	ra,0xffffa
    800062ac:	282080e7          	jalr	642(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800062b0:	854a                	mv	a0,s2
    800062b2:	00000097          	auipc	ra,0x0
    800062b6:	e6a080e7          	jalr	-406(ra) # 8000611c <isdirempty>
    800062ba:	f925                	bnez	a0,8000622a <sys_unlink+0xa2>
    iunlockput(ip);
    800062bc:	854a                	mv	a0,s2
    800062be:	ffffe097          	auipc	ra,0xffffe
    800062c2:	ea4080e7          	jalr	-348(ra) # 80004162 <iunlockput>

bad:
  iunlockput(dp);
    800062c6:	8526                	mv	a0,s1
    800062c8:	ffffe097          	auipc	ra,0xffffe
    800062cc:	e9a080e7          	jalr	-358(ra) # 80004162 <iunlockput>
  end_op();
    800062d0:	fffff097          	auipc	ra,0xfffff
    800062d4:	998080e7          	jalr	-1640(ra) # 80004c68 <end_op>
  return -1;
    800062d8:	557d                	li	a0,-1
}
    800062da:	60ae                	ld	ra,200(sp)
    800062dc:	640e                	ld	s0,192(sp)
    800062de:	74ea                	ld	s1,184(sp)
    800062e0:	794a                	ld	s2,176(sp)
    800062e2:	6169                	addi	sp,sp,208
    800062e4:	8082                	ret
    panic("unlink: writei");
    800062e6:	00003517          	auipc	a0,0x3
    800062ea:	65250513          	addi	a0,a0,1618 # 80009938 <syscalls+0x218>
    800062ee:	ffffa097          	auipc	ra,0xffffa
    800062f2:	23c080e7          	jalr	572(ra) # 8000052a <panic>
    dp->nlink--;
    800062f6:	04a4d783          	lhu	a5,74(s1)
    800062fa:	37fd                	addiw	a5,a5,-1
    800062fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006300:	8526                	mv	a0,s1
    80006302:	ffffe097          	auipc	ra,0xffffe
    80006306:	b34080e7          	jalr	-1228(ra) # 80003e36 <iupdate>
    8000630a:	bf99                	j	80006260 <sys_unlink+0xd8>
    return -1;
    8000630c:	557d                	li	a0,-1
    8000630e:	b7f1                	j	800062da <sys_unlink+0x152>

0000000080006310 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80006310:	715d                	addi	sp,sp,-80
    80006312:	e486                	sd	ra,72(sp)
    80006314:	e0a2                	sd	s0,64(sp)
    80006316:	fc26                	sd	s1,56(sp)
    80006318:	f84a                	sd	s2,48(sp)
    8000631a:	f44e                	sd	s3,40(sp)
    8000631c:	f052                	sd	s4,32(sp)
    8000631e:	ec56                	sd	s5,24(sp)
    80006320:	0880                	addi	s0,sp,80
    80006322:	89ae                	mv	s3,a1
    80006324:	8ab2                	mv	s5,a2
    80006326:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006328:	fb040593          	addi	a1,s0,-80
    8000632c:	ffffe097          	auipc	ra,0xffffe
    80006330:	3a8080e7          	jalr	936(ra) # 800046d4 <nameiparent>
    80006334:	892a                	mv	s2,a0
    80006336:	12050e63          	beqz	a0,80006472 <create+0x162>
    return 0;

  ilock(dp);
    8000633a:	ffffe097          	auipc	ra,0xffffe
    8000633e:	bc6080e7          	jalr	-1082(ra) # 80003f00 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80006342:	4601                	li	a2,0
    80006344:	fb040593          	addi	a1,s0,-80
    80006348:	854a                	mv	a0,s2
    8000634a:	ffffe097          	auipc	ra,0xffffe
    8000634e:	09a080e7          	jalr	154(ra) # 800043e4 <dirlookup>
    80006352:	84aa                	mv	s1,a0
    80006354:	c921                	beqz	a0,800063a4 <create+0x94>
    iunlockput(dp);
    80006356:	854a                	mv	a0,s2
    80006358:	ffffe097          	auipc	ra,0xffffe
    8000635c:	e0a080e7          	jalr	-502(ra) # 80004162 <iunlockput>
    ilock(ip);
    80006360:	8526                	mv	a0,s1
    80006362:	ffffe097          	auipc	ra,0xffffe
    80006366:	b9e080e7          	jalr	-1122(ra) # 80003f00 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000636a:	2981                	sext.w	s3,s3
    8000636c:	4789                	li	a5,2
    8000636e:	02f99463          	bne	s3,a5,80006396 <create+0x86>
    80006372:	0444d783          	lhu	a5,68(s1)
    80006376:	37f9                	addiw	a5,a5,-2
    80006378:	17c2                	slli	a5,a5,0x30
    8000637a:	93c1                	srli	a5,a5,0x30
    8000637c:	4705                	li	a4,1
    8000637e:	00f76c63          	bltu	a4,a5,80006396 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006382:	8526                	mv	a0,s1
    80006384:	60a6                	ld	ra,72(sp)
    80006386:	6406                	ld	s0,64(sp)
    80006388:	74e2                	ld	s1,56(sp)
    8000638a:	7942                	ld	s2,48(sp)
    8000638c:	79a2                	ld	s3,40(sp)
    8000638e:	7a02                	ld	s4,32(sp)
    80006390:	6ae2                	ld	s5,24(sp)
    80006392:	6161                	addi	sp,sp,80
    80006394:	8082                	ret
    iunlockput(ip);
    80006396:	8526                	mv	a0,s1
    80006398:	ffffe097          	auipc	ra,0xffffe
    8000639c:	dca080e7          	jalr	-566(ra) # 80004162 <iunlockput>
    return 0;
    800063a0:	4481                	li	s1,0
    800063a2:	b7c5                	j	80006382 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800063a4:	85ce                	mv	a1,s3
    800063a6:	00092503          	lw	a0,0(s2)
    800063aa:	ffffe097          	auipc	ra,0xffffe
    800063ae:	9be080e7          	jalr	-1602(ra) # 80003d68 <ialloc>
    800063b2:	84aa                	mv	s1,a0
    800063b4:	c521                	beqz	a0,800063fc <create+0xec>
  ilock(ip);
    800063b6:	ffffe097          	auipc	ra,0xffffe
    800063ba:	b4a080e7          	jalr	-1206(ra) # 80003f00 <ilock>
  ip->major = major;
    800063be:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800063c2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800063c6:	4a05                	li	s4,1
    800063c8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800063cc:	8526                	mv	a0,s1
    800063ce:	ffffe097          	auipc	ra,0xffffe
    800063d2:	a68080e7          	jalr	-1432(ra) # 80003e36 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800063d6:	2981                	sext.w	s3,s3
    800063d8:	03498a63          	beq	s3,s4,8000640c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800063dc:	40d0                	lw	a2,4(s1)
    800063de:	fb040593          	addi	a1,s0,-80
    800063e2:	854a                	mv	a0,s2
    800063e4:	ffffe097          	auipc	ra,0xffffe
    800063e8:	210080e7          	jalr	528(ra) # 800045f4 <dirlink>
    800063ec:	06054b63          	bltz	a0,80006462 <create+0x152>
  iunlockput(dp);
    800063f0:	854a                	mv	a0,s2
    800063f2:	ffffe097          	auipc	ra,0xffffe
    800063f6:	d70080e7          	jalr	-656(ra) # 80004162 <iunlockput>
  return ip;
    800063fa:	b761                	j	80006382 <create+0x72>
    panic("create: ialloc");
    800063fc:	00003517          	auipc	a0,0x3
    80006400:	64c50513          	addi	a0,a0,1612 # 80009a48 <syscalls+0x328>
    80006404:	ffffa097          	auipc	ra,0xffffa
    80006408:	126080e7          	jalr	294(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000640c:	04a95783          	lhu	a5,74(s2)
    80006410:	2785                	addiw	a5,a5,1
    80006412:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006416:	854a                	mv	a0,s2
    80006418:	ffffe097          	auipc	ra,0xffffe
    8000641c:	a1e080e7          	jalr	-1506(ra) # 80003e36 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006420:	40d0                	lw	a2,4(s1)
    80006422:	00003597          	auipc	a1,0x3
    80006426:	4ee58593          	addi	a1,a1,1262 # 80009910 <syscalls+0x1f0>
    8000642a:	8526                	mv	a0,s1
    8000642c:	ffffe097          	auipc	ra,0xffffe
    80006430:	1c8080e7          	jalr	456(ra) # 800045f4 <dirlink>
    80006434:	00054f63          	bltz	a0,80006452 <create+0x142>
    80006438:	00492603          	lw	a2,4(s2)
    8000643c:	00003597          	auipc	a1,0x3
    80006440:	4dc58593          	addi	a1,a1,1244 # 80009918 <syscalls+0x1f8>
    80006444:	8526                	mv	a0,s1
    80006446:	ffffe097          	auipc	ra,0xffffe
    8000644a:	1ae080e7          	jalr	430(ra) # 800045f4 <dirlink>
    8000644e:	f80557e3          	bgez	a0,800063dc <create+0xcc>
      panic("create dots");
    80006452:	00003517          	auipc	a0,0x3
    80006456:	60650513          	addi	a0,a0,1542 # 80009a58 <syscalls+0x338>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0d0080e7          	jalr	208(ra) # 8000052a <panic>
    panic("create: dirlink");
    80006462:	00003517          	auipc	a0,0x3
    80006466:	60650513          	addi	a0,a0,1542 # 80009a68 <syscalls+0x348>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	0c0080e7          	jalr	192(ra) # 8000052a <panic>
    return 0;
    80006472:	84aa                	mv	s1,a0
    80006474:	b739                	j	80006382 <create+0x72>

0000000080006476 <sys_open>:

uint64
sys_open(void)
{
    80006476:	7131                	addi	sp,sp,-192
    80006478:	fd06                	sd	ra,184(sp)
    8000647a:	f922                	sd	s0,176(sp)
    8000647c:	f526                	sd	s1,168(sp)
    8000647e:	f14a                	sd	s2,160(sp)
    80006480:	ed4e                	sd	s3,152(sp)
    80006482:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006484:	08000613          	li	a2,128
    80006488:	f5040593          	addi	a1,s0,-176
    8000648c:	4501                	li	a0,0
    8000648e:	ffffd097          	auipc	ra,0xffffd
    80006492:	f44080e7          	jalr	-188(ra) # 800033d2 <argstr>
    return -1;
    80006496:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006498:	0c054163          	bltz	a0,8000655a <sys_open+0xe4>
    8000649c:	f4c40593          	addi	a1,s0,-180
    800064a0:	4505                	li	a0,1
    800064a2:	ffffd097          	auipc	ra,0xffffd
    800064a6:	eec080e7          	jalr	-276(ra) # 8000338e <argint>
    800064aa:	0a054863          	bltz	a0,8000655a <sys_open+0xe4>

  begin_op();
    800064ae:	ffffe097          	auipc	ra,0xffffe
    800064b2:	73a080e7          	jalr	1850(ra) # 80004be8 <begin_op>

  if(omode & O_CREATE){
    800064b6:	f4c42783          	lw	a5,-180(s0)
    800064ba:	2007f793          	andi	a5,a5,512
    800064be:	cbdd                	beqz	a5,80006574 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800064c0:	4681                	li	a3,0
    800064c2:	4601                	li	a2,0
    800064c4:	4589                	li	a1,2
    800064c6:	f5040513          	addi	a0,s0,-176
    800064ca:	00000097          	auipc	ra,0x0
    800064ce:	e46080e7          	jalr	-442(ra) # 80006310 <create>
    800064d2:	892a                	mv	s2,a0
    if(ip == 0){
    800064d4:	c959                	beqz	a0,8000656a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800064d6:	04491703          	lh	a4,68(s2)
    800064da:	478d                	li	a5,3
    800064dc:	00f71763          	bne	a4,a5,800064ea <sys_open+0x74>
    800064e0:	04695703          	lhu	a4,70(s2)
    800064e4:	47a5                	li	a5,9
    800064e6:	0ce7ec63          	bltu	a5,a4,800065be <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800064ea:	fffff097          	auipc	ra,0xfffff
    800064ee:	b0e080e7          	jalr	-1266(ra) # 80004ff8 <filealloc>
    800064f2:	89aa                	mv	s3,a0
    800064f4:	10050263          	beqz	a0,800065f8 <sys_open+0x182>
    800064f8:	00000097          	auipc	ra,0x0
    800064fc:	8e2080e7          	jalr	-1822(ra) # 80005dda <fdalloc>
    80006500:	84aa                	mv	s1,a0
    80006502:	0e054663          	bltz	a0,800065ee <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006506:	04491703          	lh	a4,68(s2)
    8000650a:	478d                	li	a5,3
    8000650c:	0cf70463          	beq	a4,a5,800065d4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006510:	4789                	li	a5,2
    80006512:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006516:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000651a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000651e:	f4c42783          	lw	a5,-180(s0)
    80006522:	0017c713          	xori	a4,a5,1
    80006526:	8b05                	andi	a4,a4,1
    80006528:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000652c:	0037f713          	andi	a4,a5,3
    80006530:	00e03733          	snez	a4,a4
    80006534:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006538:	4007f793          	andi	a5,a5,1024
    8000653c:	c791                	beqz	a5,80006548 <sys_open+0xd2>
    8000653e:	04491703          	lh	a4,68(s2)
    80006542:	4789                	li	a5,2
    80006544:	08f70f63          	beq	a4,a5,800065e2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006548:	854a                	mv	a0,s2
    8000654a:	ffffe097          	auipc	ra,0xffffe
    8000654e:	a78080e7          	jalr	-1416(ra) # 80003fc2 <iunlock>
  end_op();
    80006552:	ffffe097          	auipc	ra,0xffffe
    80006556:	716080e7          	jalr	1814(ra) # 80004c68 <end_op>

  return fd;
}
    8000655a:	8526                	mv	a0,s1
    8000655c:	70ea                	ld	ra,184(sp)
    8000655e:	744a                	ld	s0,176(sp)
    80006560:	74aa                	ld	s1,168(sp)
    80006562:	790a                	ld	s2,160(sp)
    80006564:	69ea                	ld	s3,152(sp)
    80006566:	6129                	addi	sp,sp,192
    80006568:	8082                	ret
      end_op();
    8000656a:	ffffe097          	auipc	ra,0xffffe
    8000656e:	6fe080e7          	jalr	1790(ra) # 80004c68 <end_op>
      return -1;
    80006572:	b7e5                	j	8000655a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006574:	f5040513          	addi	a0,s0,-176
    80006578:	ffffe097          	auipc	ra,0xffffe
    8000657c:	13e080e7          	jalr	318(ra) # 800046b6 <namei>
    80006580:	892a                	mv	s2,a0
    80006582:	c905                	beqz	a0,800065b2 <sys_open+0x13c>
    ilock(ip);
    80006584:	ffffe097          	auipc	ra,0xffffe
    80006588:	97c080e7          	jalr	-1668(ra) # 80003f00 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000658c:	04491703          	lh	a4,68(s2)
    80006590:	4785                	li	a5,1
    80006592:	f4f712e3          	bne	a4,a5,800064d6 <sys_open+0x60>
    80006596:	f4c42783          	lw	a5,-180(s0)
    8000659a:	dba1                	beqz	a5,800064ea <sys_open+0x74>
      iunlockput(ip);
    8000659c:	854a                	mv	a0,s2
    8000659e:	ffffe097          	auipc	ra,0xffffe
    800065a2:	bc4080e7          	jalr	-1084(ra) # 80004162 <iunlockput>
      end_op();
    800065a6:	ffffe097          	auipc	ra,0xffffe
    800065aa:	6c2080e7          	jalr	1730(ra) # 80004c68 <end_op>
      return -1;
    800065ae:	54fd                	li	s1,-1
    800065b0:	b76d                	j	8000655a <sys_open+0xe4>
      end_op();
    800065b2:	ffffe097          	auipc	ra,0xffffe
    800065b6:	6b6080e7          	jalr	1718(ra) # 80004c68 <end_op>
      return -1;
    800065ba:	54fd                	li	s1,-1
    800065bc:	bf79                	j	8000655a <sys_open+0xe4>
    iunlockput(ip);
    800065be:	854a                	mv	a0,s2
    800065c0:	ffffe097          	auipc	ra,0xffffe
    800065c4:	ba2080e7          	jalr	-1118(ra) # 80004162 <iunlockput>
    end_op();
    800065c8:	ffffe097          	auipc	ra,0xffffe
    800065cc:	6a0080e7          	jalr	1696(ra) # 80004c68 <end_op>
    return -1;
    800065d0:	54fd                	li	s1,-1
    800065d2:	b761                	j	8000655a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800065d4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800065d8:	04691783          	lh	a5,70(s2)
    800065dc:	02f99223          	sh	a5,36(s3)
    800065e0:	bf2d                	j	8000651a <sys_open+0xa4>
    itrunc(ip);
    800065e2:	854a                	mv	a0,s2
    800065e4:	ffffe097          	auipc	ra,0xffffe
    800065e8:	a2a080e7          	jalr	-1494(ra) # 8000400e <itrunc>
    800065ec:	bfb1                	j	80006548 <sys_open+0xd2>
      fileclose(f);
    800065ee:	854e                	mv	a0,s3
    800065f0:	fffff097          	auipc	ra,0xfffff
    800065f4:	ac4080e7          	jalr	-1340(ra) # 800050b4 <fileclose>
    iunlockput(ip);
    800065f8:	854a                	mv	a0,s2
    800065fa:	ffffe097          	auipc	ra,0xffffe
    800065fe:	b68080e7          	jalr	-1176(ra) # 80004162 <iunlockput>
    end_op();
    80006602:	ffffe097          	auipc	ra,0xffffe
    80006606:	666080e7          	jalr	1638(ra) # 80004c68 <end_op>
    return -1;
    8000660a:	54fd                	li	s1,-1
    8000660c:	b7b9                	j	8000655a <sys_open+0xe4>

000000008000660e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000660e:	7175                	addi	sp,sp,-144
    80006610:	e506                	sd	ra,136(sp)
    80006612:	e122                	sd	s0,128(sp)
    80006614:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006616:	ffffe097          	auipc	ra,0xffffe
    8000661a:	5d2080e7          	jalr	1490(ra) # 80004be8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000661e:	08000613          	li	a2,128
    80006622:	f7040593          	addi	a1,s0,-144
    80006626:	4501                	li	a0,0
    80006628:	ffffd097          	auipc	ra,0xffffd
    8000662c:	daa080e7          	jalr	-598(ra) # 800033d2 <argstr>
    80006630:	02054963          	bltz	a0,80006662 <sys_mkdir+0x54>
    80006634:	4681                	li	a3,0
    80006636:	4601                	li	a2,0
    80006638:	4585                	li	a1,1
    8000663a:	f7040513          	addi	a0,s0,-144
    8000663e:	00000097          	auipc	ra,0x0
    80006642:	cd2080e7          	jalr	-814(ra) # 80006310 <create>
    80006646:	cd11                	beqz	a0,80006662 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006648:	ffffe097          	auipc	ra,0xffffe
    8000664c:	b1a080e7          	jalr	-1254(ra) # 80004162 <iunlockput>
  end_op();
    80006650:	ffffe097          	auipc	ra,0xffffe
    80006654:	618080e7          	jalr	1560(ra) # 80004c68 <end_op>
  return 0;
    80006658:	4501                	li	a0,0
}
    8000665a:	60aa                	ld	ra,136(sp)
    8000665c:	640a                	ld	s0,128(sp)
    8000665e:	6149                	addi	sp,sp,144
    80006660:	8082                	ret
    end_op();
    80006662:	ffffe097          	auipc	ra,0xffffe
    80006666:	606080e7          	jalr	1542(ra) # 80004c68 <end_op>
    return -1;
    8000666a:	557d                	li	a0,-1
    8000666c:	b7fd                	j	8000665a <sys_mkdir+0x4c>

000000008000666e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000666e:	7135                	addi	sp,sp,-160
    80006670:	ed06                	sd	ra,152(sp)
    80006672:	e922                	sd	s0,144(sp)
    80006674:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006676:	ffffe097          	auipc	ra,0xffffe
    8000667a:	572080e7          	jalr	1394(ra) # 80004be8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000667e:	08000613          	li	a2,128
    80006682:	f7040593          	addi	a1,s0,-144
    80006686:	4501                	li	a0,0
    80006688:	ffffd097          	auipc	ra,0xffffd
    8000668c:	d4a080e7          	jalr	-694(ra) # 800033d2 <argstr>
    80006690:	04054a63          	bltz	a0,800066e4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006694:	f6c40593          	addi	a1,s0,-148
    80006698:	4505                	li	a0,1
    8000669a:	ffffd097          	auipc	ra,0xffffd
    8000669e:	cf4080e7          	jalr	-780(ra) # 8000338e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800066a2:	04054163          	bltz	a0,800066e4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800066a6:	f6840593          	addi	a1,s0,-152
    800066aa:	4509                	li	a0,2
    800066ac:	ffffd097          	auipc	ra,0xffffd
    800066b0:	ce2080e7          	jalr	-798(ra) # 8000338e <argint>
     argint(1, &major) < 0 ||
    800066b4:	02054863          	bltz	a0,800066e4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800066b8:	f6841683          	lh	a3,-152(s0)
    800066bc:	f6c41603          	lh	a2,-148(s0)
    800066c0:	458d                	li	a1,3
    800066c2:	f7040513          	addi	a0,s0,-144
    800066c6:	00000097          	auipc	ra,0x0
    800066ca:	c4a080e7          	jalr	-950(ra) # 80006310 <create>
     argint(2, &minor) < 0 ||
    800066ce:	c919                	beqz	a0,800066e4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066d0:	ffffe097          	auipc	ra,0xffffe
    800066d4:	a92080e7          	jalr	-1390(ra) # 80004162 <iunlockput>
  end_op();
    800066d8:	ffffe097          	auipc	ra,0xffffe
    800066dc:	590080e7          	jalr	1424(ra) # 80004c68 <end_op>
  return 0;
    800066e0:	4501                	li	a0,0
    800066e2:	a031                	j	800066ee <sys_mknod+0x80>
    end_op();
    800066e4:	ffffe097          	auipc	ra,0xffffe
    800066e8:	584080e7          	jalr	1412(ra) # 80004c68 <end_op>
    return -1;
    800066ec:	557d                	li	a0,-1
}
    800066ee:	60ea                	ld	ra,152(sp)
    800066f0:	644a                	ld	s0,144(sp)
    800066f2:	610d                	addi	sp,sp,160
    800066f4:	8082                	ret

00000000800066f6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800066f6:	7135                	addi	sp,sp,-160
    800066f8:	ed06                	sd	ra,152(sp)
    800066fa:	e922                	sd	s0,144(sp)
    800066fc:	e526                	sd	s1,136(sp)
    800066fe:	e14a                	sd	s2,128(sp)
    80006700:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006702:	ffffb097          	auipc	ra,0xffffb
    80006706:	302080e7          	jalr	770(ra) # 80001a04 <myproc>
    8000670a:	892a                	mv	s2,a0
  
  begin_op();
    8000670c:	ffffe097          	auipc	ra,0xffffe
    80006710:	4dc080e7          	jalr	1244(ra) # 80004be8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006714:	08000613          	li	a2,128
    80006718:	f6040593          	addi	a1,s0,-160
    8000671c:	4501                	li	a0,0
    8000671e:	ffffd097          	auipc	ra,0xffffd
    80006722:	cb4080e7          	jalr	-844(ra) # 800033d2 <argstr>
    80006726:	04054b63          	bltz	a0,8000677c <sys_chdir+0x86>
    8000672a:	f6040513          	addi	a0,s0,-160
    8000672e:	ffffe097          	auipc	ra,0xffffe
    80006732:	f88080e7          	jalr	-120(ra) # 800046b6 <namei>
    80006736:	84aa                	mv	s1,a0
    80006738:	c131                	beqz	a0,8000677c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000673a:	ffffd097          	auipc	ra,0xffffd
    8000673e:	7c6080e7          	jalr	1990(ra) # 80003f00 <ilock>
  if(ip->type != T_DIR){
    80006742:	04449703          	lh	a4,68(s1)
    80006746:	4785                	li	a5,1
    80006748:	04f71063          	bne	a4,a5,80006788 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000674c:	8526                	mv	a0,s1
    8000674e:	ffffe097          	auipc	ra,0xffffe
    80006752:	874080e7          	jalr	-1932(ra) # 80003fc2 <iunlock>
  iput(p->cwd);
    80006756:	15093503          	ld	a0,336(s2)
    8000675a:	ffffe097          	auipc	ra,0xffffe
    8000675e:	960080e7          	jalr	-1696(ra) # 800040ba <iput>
  end_op();
    80006762:	ffffe097          	auipc	ra,0xffffe
    80006766:	506080e7          	jalr	1286(ra) # 80004c68 <end_op>
  p->cwd = ip;
    8000676a:	14993823          	sd	s1,336(s2)
  return 0;
    8000676e:	4501                	li	a0,0
}
    80006770:	60ea                	ld	ra,152(sp)
    80006772:	644a                	ld	s0,144(sp)
    80006774:	64aa                	ld	s1,136(sp)
    80006776:	690a                	ld	s2,128(sp)
    80006778:	610d                	addi	sp,sp,160
    8000677a:	8082                	ret
    end_op();
    8000677c:	ffffe097          	auipc	ra,0xffffe
    80006780:	4ec080e7          	jalr	1260(ra) # 80004c68 <end_op>
    return -1;
    80006784:	557d                	li	a0,-1
    80006786:	b7ed                	j	80006770 <sys_chdir+0x7a>
    iunlockput(ip);
    80006788:	8526                	mv	a0,s1
    8000678a:	ffffe097          	auipc	ra,0xffffe
    8000678e:	9d8080e7          	jalr	-1576(ra) # 80004162 <iunlockput>
    end_op();
    80006792:	ffffe097          	auipc	ra,0xffffe
    80006796:	4d6080e7          	jalr	1238(ra) # 80004c68 <end_op>
    return -1;
    8000679a:	557d                	li	a0,-1
    8000679c:	bfd1                	j	80006770 <sys_chdir+0x7a>

000000008000679e <sys_exec>:

uint64
sys_exec(void)
{
    8000679e:	7145                	addi	sp,sp,-464
    800067a0:	e786                	sd	ra,456(sp)
    800067a2:	e3a2                	sd	s0,448(sp)
    800067a4:	ff26                	sd	s1,440(sp)
    800067a6:	fb4a                	sd	s2,432(sp)
    800067a8:	f74e                	sd	s3,424(sp)
    800067aa:	f352                	sd	s4,416(sp)
    800067ac:	ef56                	sd	s5,408(sp)
    800067ae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067b0:	08000613          	li	a2,128
    800067b4:	f4040593          	addi	a1,s0,-192
    800067b8:	4501                	li	a0,0
    800067ba:	ffffd097          	auipc	ra,0xffffd
    800067be:	c18080e7          	jalr	-1000(ra) # 800033d2 <argstr>
    return -1;
    800067c2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067c4:	0c054a63          	bltz	a0,80006898 <sys_exec+0xfa>
    800067c8:	e3840593          	addi	a1,s0,-456
    800067cc:	4505                	li	a0,1
    800067ce:	ffffd097          	auipc	ra,0xffffd
    800067d2:	be2080e7          	jalr	-1054(ra) # 800033b0 <argaddr>
    800067d6:	0c054163          	bltz	a0,80006898 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800067da:	10000613          	li	a2,256
    800067de:	4581                	li	a1,0
    800067e0:	e4040513          	addi	a0,s0,-448
    800067e4:	ffffa097          	auipc	ra,0xffffa
    800067e8:	4da080e7          	jalr	1242(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800067ec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800067f0:	89a6                	mv	s3,s1
    800067f2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800067f4:	02000a13          	li	s4,32
    800067f8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800067fc:	00391793          	slli	a5,s2,0x3
    80006800:	e3040593          	addi	a1,s0,-464
    80006804:	e3843503          	ld	a0,-456(s0)
    80006808:	953e                	add	a0,a0,a5
    8000680a:	ffffd097          	auipc	ra,0xffffd
    8000680e:	aea080e7          	jalr	-1302(ra) # 800032f4 <fetchaddr>
    80006812:	02054a63          	bltz	a0,80006846 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006816:	e3043783          	ld	a5,-464(s0)
    8000681a:	c3b9                	beqz	a5,80006860 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000681c:	ffffa097          	auipc	ra,0xffffa
    80006820:	2b6080e7          	jalr	694(ra) # 80000ad2 <kalloc>
    80006824:	85aa                	mv	a1,a0
    80006826:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000682a:	cd11                	beqz	a0,80006846 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000682c:	6605                	lui	a2,0x1
    8000682e:	e3043503          	ld	a0,-464(s0)
    80006832:	ffffd097          	auipc	ra,0xffffd
    80006836:	b14080e7          	jalr	-1260(ra) # 80003346 <fetchstr>
    8000683a:	00054663          	bltz	a0,80006846 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000683e:	0905                	addi	s2,s2,1
    80006840:	09a1                	addi	s3,s3,8
    80006842:	fb491be3          	bne	s2,s4,800067f8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006846:	10048913          	addi	s2,s1,256
    8000684a:	6088                	ld	a0,0(s1)
    8000684c:	c529                	beqz	a0,80006896 <sys_exec+0xf8>
    kfree(argv[i]);
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	188080e7          	jalr	392(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006856:	04a1                	addi	s1,s1,8
    80006858:	ff2499e3          	bne	s1,s2,8000684a <sys_exec+0xac>
  return -1;
    8000685c:	597d                	li	s2,-1
    8000685e:	a82d                	j	80006898 <sys_exec+0xfa>
      argv[i] = 0;
    80006860:	0a8e                	slli	s5,s5,0x3
    80006862:	fc040793          	addi	a5,s0,-64
    80006866:	9abe                	add	s5,s5,a5
    80006868:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000686c:	e4040593          	addi	a1,s0,-448
    80006870:	f4040513          	addi	a0,s0,-192
    80006874:	fffff097          	auipc	ra,0xfffff
    80006878:	088080e7          	jalr	136(ra) # 800058fc <exec>
    8000687c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000687e:	10048993          	addi	s3,s1,256
    80006882:	6088                	ld	a0,0(s1)
    80006884:	c911                	beqz	a0,80006898 <sys_exec+0xfa>
    kfree(argv[i]);
    80006886:	ffffa097          	auipc	ra,0xffffa
    8000688a:	150080e7          	jalr	336(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000688e:	04a1                	addi	s1,s1,8
    80006890:	ff3499e3          	bne	s1,s3,80006882 <sys_exec+0xe4>
    80006894:	a011                	j	80006898 <sys_exec+0xfa>
  return -1;
    80006896:	597d                	li	s2,-1
}
    80006898:	854a                	mv	a0,s2
    8000689a:	60be                	ld	ra,456(sp)
    8000689c:	641e                	ld	s0,448(sp)
    8000689e:	74fa                	ld	s1,440(sp)
    800068a0:	795a                	ld	s2,432(sp)
    800068a2:	79ba                	ld	s3,424(sp)
    800068a4:	7a1a                	ld	s4,416(sp)
    800068a6:	6afa                	ld	s5,408(sp)
    800068a8:	6179                	addi	sp,sp,464
    800068aa:	8082                	ret

00000000800068ac <sys_pipe>:

uint64
sys_pipe(void)
{
    800068ac:	7139                	addi	sp,sp,-64
    800068ae:	fc06                	sd	ra,56(sp)
    800068b0:	f822                	sd	s0,48(sp)
    800068b2:	f426                	sd	s1,40(sp)
    800068b4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800068b6:	ffffb097          	auipc	ra,0xffffb
    800068ba:	14e080e7          	jalr	334(ra) # 80001a04 <myproc>
    800068be:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800068c0:	fd840593          	addi	a1,s0,-40
    800068c4:	4501                	li	a0,0
    800068c6:	ffffd097          	auipc	ra,0xffffd
    800068ca:	aea080e7          	jalr	-1302(ra) # 800033b0 <argaddr>
    return -1;
    800068ce:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800068d0:	0e054063          	bltz	a0,800069b0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800068d4:	fc840593          	addi	a1,s0,-56
    800068d8:	fd040513          	addi	a0,s0,-48
    800068dc:	fffff097          	auipc	ra,0xfffff
    800068e0:	cfe080e7          	jalr	-770(ra) # 800055da <pipealloc>
    return -1;
    800068e4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800068e6:	0c054563          	bltz	a0,800069b0 <sys_pipe+0x104>
  fd0 = -1;
    800068ea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800068ee:	fd043503          	ld	a0,-48(s0)
    800068f2:	fffff097          	auipc	ra,0xfffff
    800068f6:	4e8080e7          	jalr	1256(ra) # 80005dda <fdalloc>
    800068fa:	fca42223          	sw	a0,-60(s0)
    800068fe:	08054c63          	bltz	a0,80006996 <sys_pipe+0xea>
    80006902:	fc843503          	ld	a0,-56(s0)
    80006906:	fffff097          	auipc	ra,0xfffff
    8000690a:	4d4080e7          	jalr	1236(ra) # 80005dda <fdalloc>
    8000690e:	fca42023          	sw	a0,-64(s0)
    80006912:	06054863          	bltz	a0,80006982 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006916:	4691                	li	a3,4
    80006918:	fc440613          	addi	a2,s0,-60
    8000691c:	fd843583          	ld	a1,-40(s0)
    80006920:	68a8                	ld	a0,80(s1)
    80006922:	ffffb097          	auipc	ra,0xffffb
    80006926:	da2080e7          	jalr	-606(ra) # 800016c4 <copyout>
    8000692a:	02054063          	bltz	a0,8000694a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000692e:	4691                	li	a3,4
    80006930:	fc040613          	addi	a2,s0,-64
    80006934:	fd843583          	ld	a1,-40(s0)
    80006938:	0591                	addi	a1,a1,4
    8000693a:	68a8                	ld	a0,80(s1)
    8000693c:	ffffb097          	auipc	ra,0xffffb
    80006940:	d88080e7          	jalr	-632(ra) # 800016c4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006944:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006946:	06055563          	bgez	a0,800069b0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000694a:	fc442783          	lw	a5,-60(s0)
    8000694e:	07e9                	addi	a5,a5,26
    80006950:	078e                	slli	a5,a5,0x3
    80006952:	97a6                	add	a5,a5,s1
    80006954:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006958:	fc042503          	lw	a0,-64(s0)
    8000695c:	0569                	addi	a0,a0,26
    8000695e:	050e                	slli	a0,a0,0x3
    80006960:	9526                	add	a0,a0,s1
    80006962:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006966:	fd043503          	ld	a0,-48(s0)
    8000696a:	ffffe097          	auipc	ra,0xffffe
    8000696e:	74a080e7          	jalr	1866(ra) # 800050b4 <fileclose>
    fileclose(wf);
    80006972:	fc843503          	ld	a0,-56(s0)
    80006976:	ffffe097          	auipc	ra,0xffffe
    8000697a:	73e080e7          	jalr	1854(ra) # 800050b4 <fileclose>
    return -1;
    8000697e:	57fd                	li	a5,-1
    80006980:	a805                	j	800069b0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006982:	fc442783          	lw	a5,-60(s0)
    80006986:	0007c863          	bltz	a5,80006996 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000698a:	01a78513          	addi	a0,a5,26
    8000698e:	050e                	slli	a0,a0,0x3
    80006990:	9526                	add	a0,a0,s1
    80006992:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006996:	fd043503          	ld	a0,-48(s0)
    8000699a:	ffffe097          	auipc	ra,0xffffe
    8000699e:	71a080e7          	jalr	1818(ra) # 800050b4 <fileclose>
    fileclose(wf);
    800069a2:	fc843503          	ld	a0,-56(s0)
    800069a6:	ffffe097          	auipc	ra,0xffffe
    800069aa:	70e080e7          	jalr	1806(ra) # 800050b4 <fileclose>
    return -1;
    800069ae:	57fd                	li	a5,-1
}
    800069b0:	853e                	mv	a0,a5
    800069b2:	70e2                	ld	ra,56(sp)
    800069b4:	7442                	ld	s0,48(sp)
    800069b6:	74a2                	ld	s1,40(sp)
    800069b8:	6121                	addi	sp,sp,64
    800069ba:	8082                	ret
    800069bc:	0000                	unimp
	...

00000000800069c0 <kernelvec>:
    800069c0:	7111                	addi	sp,sp,-256
    800069c2:	e006                	sd	ra,0(sp)
    800069c4:	e40a                	sd	sp,8(sp)
    800069c6:	e80e                	sd	gp,16(sp)
    800069c8:	ec12                	sd	tp,24(sp)
    800069ca:	f016                	sd	t0,32(sp)
    800069cc:	f41a                	sd	t1,40(sp)
    800069ce:	f81e                	sd	t2,48(sp)
    800069d0:	fc22                	sd	s0,56(sp)
    800069d2:	e0a6                	sd	s1,64(sp)
    800069d4:	e4aa                	sd	a0,72(sp)
    800069d6:	e8ae                	sd	a1,80(sp)
    800069d8:	ecb2                	sd	a2,88(sp)
    800069da:	f0b6                	sd	a3,96(sp)
    800069dc:	f4ba                	sd	a4,104(sp)
    800069de:	f8be                	sd	a5,112(sp)
    800069e0:	fcc2                	sd	a6,120(sp)
    800069e2:	e146                	sd	a7,128(sp)
    800069e4:	e54a                	sd	s2,136(sp)
    800069e6:	e94e                	sd	s3,144(sp)
    800069e8:	ed52                	sd	s4,152(sp)
    800069ea:	f156                	sd	s5,160(sp)
    800069ec:	f55a                	sd	s6,168(sp)
    800069ee:	f95e                	sd	s7,176(sp)
    800069f0:	fd62                	sd	s8,184(sp)
    800069f2:	e1e6                	sd	s9,192(sp)
    800069f4:	e5ea                	sd	s10,200(sp)
    800069f6:	e9ee                	sd	s11,208(sp)
    800069f8:	edf2                	sd	t3,216(sp)
    800069fa:	f1f6                	sd	t4,224(sp)
    800069fc:	f5fa                	sd	t5,232(sp)
    800069fe:	f9fe                	sd	t6,240(sp)
    80006a00:	fc0fc0ef          	jal	ra,800031c0 <kerneltrap>
    80006a04:	6082                	ld	ra,0(sp)
    80006a06:	6122                	ld	sp,8(sp)
    80006a08:	61c2                	ld	gp,16(sp)
    80006a0a:	7282                	ld	t0,32(sp)
    80006a0c:	7322                	ld	t1,40(sp)
    80006a0e:	73c2                	ld	t2,48(sp)
    80006a10:	7462                	ld	s0,56(sp)
    80006a12:	6486                	ld	s1,64(sp)
    80006a14:	6526                	ld	a0,72(sp)
    80006a16:	65c6                	ld	a1,80(sp)
    80006a18:	6666                	ld	a2,88(sp)
    80006a1a:	7686                	ld	a3,96(sp)
    80006a1c:	7726                	ld	a4,104(sp)
    80006a1e:	77c6                	ld	a5,112(sp)
    80006a20:	7866                	ld	a6,120(sp)
    80006a22:	688a                	ld	a7,128(sp)
    80006a24:	692a                	ld	s2,136(sp)
    80006a26:	69ca                	ld	s3,144(sp)
    80006a28:	6a6a                	ld	s4,152(sp)
    80006a2a:	7a8a                	ld	s5,160(sp)
    80006a2c:	7b2a                	ld	s6,168(sp)
    80006a2e:	7bca                	ld	s7,176(sp)
    80006a30:	7c6a                	ld	s8,184(sp)
    80006a32:	6c8e                	ld	s9,192(sp)
    80006a34:	6d2e                	ld	s10,200(sp)
    80006a36:	6dce                	ld	s11,208(sp)
    80006a38:	6e6e                	ld	t3,216(sp)
    80006a3a:	7e8e                	ld	t4,224(sp)
    80006a3c:	7f2e                	ld	t5,232(sp)
    80006a3e:	7fce                	ld	t6,240(sp)
    80006a40:	6111                	addi	sp,sp,256
    80006a42:	10200073          	sret
    80006a46:	00000013          	nop
    80006a4a:	00000013          	nop
    80006a4e:	0001                	nop

0000000080006a50 <timervec>:
    80006a50:	34051573          	csrrw	a0,mscratch,a0
    80006a54:	e10c                	sd	a1,0(a0)
    80006a56:	e510                	sd	a2,8(a0)
    80006a58:	e914                	sd	a3,16(a0)
    80006a5a:	6d0c                	ld	a1,24(a0)
    80006a5c:	7110                	ld	a2,32(a0)
    80006a5e:	6194                	ld	a3,0(a1)
    80006a60:	96b2                	add	a3,a3,a2
    80006a62:	e194                	sd	a3,0(a1)
    80006a64:	4589                	li	a1,2
    80006a66:	14459073          	csrw	sip,a1
    80006a6a:	6914                	ld	a3,16(a0)
    80006a6c:	6510                	ld	a2,8(a0)
    80006a6e:	610c                	ld	a1,0(a0)
    80006a70:	34051573          	csrrw	a0,mscratch,a0
    80006a74:	30200073          	mret
	...

0000000080006a7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006a7a:	1141                	addi	sp,sp,-16
    80006a7c:	e422                	sd	s0,8(sp)
    80006a7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006a80:	0c0007b7          	lui	a5,0xc000
    80006a84:	4705                	li	a4,1
    80006a86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006a88:	c3d8                	sw	a4,4(a5)
}
    80006a8a:	6422                	ld	s0,8(sp)
    80006a8c:	0141                	addi	sp,sp,16
    80006a8e:	8082                	ret

0000000080006a90 <plicinithart>:

void
plicinithart(void)
{
    80006a90:	1141                	addi	sp,sp,-16
    80006a92:	e406                	sd	ra,8(sp)
    80006a94:	e022                	sd	s0,0(sp)
    80006a96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006a98:	ffffb097          	auipc	ra,0xffffb
    80006a9c:	f40080e7          	jalr	-192(ra) # 800019d8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006aa0:	0085171b          	slliw	a4,a0,0x8
    80006aa4:	0c0027b7          	lui	a5,0xc002
    80006aa8:	97ba                	add	a5,a5,a4
    80006aaa:	40200713          	li	a4,1026
    80006aae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006ab2:	00d5151b          	slliw	a0,a0,0xd
    80006ab6:	0c2017b7          	lui	a5,0xc201
    80006aba:	953e                	add	a0,a0,a5
    80006abc:	00052023          	sw	zero,0(a0)
}
    80006ac0:	60a2                	ld	ra,8(sp)
    80006ac2:	6402                	ld	s0,0(sp)
    80006ac4:	0141                	addi	sp,sp,16
    80006ac6:	8082                	ret

0000000080006ac8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006ac8:	1141                	addi	sp,sp,-16
    80006aca:	e406                	sd	ra,8(sp)
    80006acc:	e022                	sd	s0,0(sp)
    80006ace:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006ad0:	ffffb097          	auipc	ra,0xffffb
    80006ad4:	f08080e7          	jalr	-248(ra) # 800019d8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006ad8:	00d5179b          	slliw	a5,a0,0xd
    80006adc:	0c201537          	lui	a0,0xc201
    80006ae0:	953e                	add	a0,a0,a5
  return irq;
}
    80006ae2:	4148                	lw	a0,4(a0)
    80006ae4:	60a2                	ld	ra,8(sp)
    80006ae6:	6402                	ld	s0,0(sp)
    80006ae8:	0141                	addi	sp,sp,16
    80006aea:	8082                	ret

0000000080006aec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006aec:	1101                	addi	sp,sp,-32
    80006aee:	ec06                	sd	ra,24(sp)
    80006af0:	e822                	sd	s0,16(sp)
    80006af2:	e426                	sd	s1,8(sp)
    80006af4:	1000                	addi	s0,sp,32
    80006af6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006af8:	ffffb097          	auipc	ra,0xffffb
    80006afc:	ee0080e7          	jalr	-288(ra) # 800019d8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006b00:	00d5151b          	slliw	a0,a0,0xd
    80006b04:	0c2017b7          	lui	a5,0xc201
    80006b08:	97aa                	add	a5,a5,a0
    80006b0a:	c3c4                	sw	s1,4(a5)
}
    80006b0c:	60e2                	ld	ra,24(sp)
    80006b0e:	6442                	ld	s0,16(sp)
    80006b10:	64a2                	ld	s1,8(sp)
    80006b12:	6105                	addi	sp,sp,32
    80006b14:	8082                	ret

0000000080006b16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006b16:	1141                	addi	sp,sp,-16
    80006b18:	e406                	sd	ra,8(sp)
    80006b1a:	e022                	sd	s0,0(sp)
    80006b1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006b1e:	479d                	li	a5,7
    80006b20:	06a7c963          	blt	a5,a0,80006b92 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006b24:	00025797          	auipc	a5,0x25
    80006b28:	4dc78793          	addi	a5,a5,1244 # 8002c000 <disk>
    80006b2c:	00a78733          	add	a4,a5,a0
    80006b30:	6789                	lui	a5,0x2
    80006b32:	97ba                	add	a5,a5,a4
    80006b34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006b38:	e7ad                	bnez	a5,80006ba2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006b3a:	00451793          	slli	a5,a0,0x4
    80006b3e:	00027717          	auipc	a4,0x27
    80006b42:	4c270713          	addi	a4,a4,1218 # 8002e000 <disk+0x2000>
    80006b46:	6314                	ld	a3,0(a4)
    80006b48:	96be                	add	a3,a3,a5
    80006b4a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006b4e:	6314                	ld	a3,0(a4)
    80006b50:	96be                	add	a3,a3,a5
    80006b52:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006b56:	6314                	ld	a3,0(a4)
    80006b58:	96be                	add	a3,a3,a5
    80006b5a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006b5e:	6318                	ld	a4,0(a4)
    80006b60:	97ba                	add	a5,a5,a4
    80006b62:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006b66:	00025797          	auipc	a5,0x25
    80006b6a:	49a78793          	addi	a5,a5,1178 # 8002c000 <disk>
    80006b6e:	97aa                	add	a5,a5,a0
    80006b70:	6509                	lui	a0,0x2
    80006b72:	953e                	add	a0,a0,a5
    80006b74:	4785                	li	a5,1
    80006b76:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006b7a:	00027517          	auipc	a0,0x27
    80006b7e:	49e50513          	addi	a0,a0,1182 # 8002e018 <disk+0x2018>
    80006b82:	ffffb097          	auipc	ra,0xffffb
    80006b86:	630080e7          	jalr	1584(ra) # 800021b2 <wakeup>
}
    80006b8a:	60a2                	ld	ra,8(sp)
    80006b8c:	6402                	ld	s0,0(sp)
    80006b8e:	0141                	addi	sp,sp,16
    80006b90:	8082                	ret
    panic("free_desc 1");
    80006b92:	00003517          	auipc	a0,0x3
    80006b96:	ee650513          	addi	a0,a0,-282 # 80009a78 <syscalls+0x358>
    80006b9a:	ffffa097          	auipc	ra,0xffffa
    80006b9e:	990080e7          	jalr	-1648(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006ba2:	00003517          	auipc	a0,0x3
    80006ba6:	ee650513          	addi	a0,a0,-282 # 80009a88 <syscalls+0x368>
    80006baa:	ffffa097          	auipc	ra,0xffffa
    80006bae:	980080e7          	jalr	-1664(ra) # 8000052a <panic>

0000000080006bb2 <virtio_disk_init>:
{
    80006bb2:	1101                	addi	sp,sp,-32
    80006bb4:	ec06                	sd	ra,24(sp)
    80006bb6:	e822                	sd	s0,16(sp)
    80006bb8:	e426                	sd	s1,8(sp)
    80006bba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006bbc:	00003597          	auipc	a1,0x3
    80006bc0:	edc58593          	addi	a1,a1,-292 # 80009a98 <syscalls+0x378>
    80006bc4:	00027517          	auipc	a0,0x27
    80006bc8:	56450513          	addi	a0,a0,1380 # 8002e128 <disk+0x2128>
    80006bcc:	ffffa097          	auipc	ra,0xffffa
    80006bd0:	f66080e7          	jalr	-154(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006bd4:	100017b7          	lui	a5,0x10001
    80006bd8:	4398                	lw	a4,0(a5)
    80006bda:	2701                	sext.w	a4,a4
    80006bdc:	747277b7          	lui	a5,0x74727
    80006be0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006be4:	0ef71163          	bne	a4,a5,80006cc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006be8:	100017b7          	lui	a5,0x10001
    80006bec:	43dc                	lw	a5,4(a5)
    80006bee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006bf0:	4705                	li	a4,1
    80006bf2:	0ce79a63          	bne	a5,a4,80006cc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006bf6:	100017b7          	lui	a5,0x10001
    80006bfa:	479c                	lw	a5,8(a5)
    80006bfc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006bfe:	4709                	li	a4,2
    80006c00:	0ce79363          	bne	a5,a4,80006cc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006c04:	100017b7          	lui	a5,0x10001
    80006c08:	47d8                	lw	a4,12(a5)
    80006c0a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c0c:	554d47b7          	lui	a5,0x554d4
    80006c10:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006c14:	0af71963          	bne	a4,a5,80006cc6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c18:	100017b7          	lui	a5,0x10001
    80006c1c:	4705                	li	a4,1
    80006c1e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c20:	470d                	li	a4,3
    80006c22:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006c24:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006c26:	c7ffe737          	lui	a4,0xc7ffe
    80006c2a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf75f>
    80006c2e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006c30:	2701                	sext.w	a4,a4
    80006c32:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c34:	472d                	li	a4,11
    80006c36:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c38:	473d                	li	a4,15
    80006c3a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006c3c:	6705                	lui	a4,0x1
    80006c3e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006c40:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006c44:	5bdc                	lw	a5,52(a5)
    80006c46:	2781                	sext.w	a5,a5
  if(max == 0)
    80006c48:	c7d9                	beqz	a5,80006cd6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006c4a:	471d                	li	a4,7
    80006c4c:	08f77d63          	bgeu	a4,a5,80006ce6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006c50:	100014b7          	lui	s1,0x10001
    80006c54:	47a1                	li	a5,8
    80006c56:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006c58:	6609                	lui	a2,0x2
    80006c5a:	4581                	li	a1,0
    80006c5c:	00025517          	auipc	a0,0x25
    80006c60:	3a450513          	addi	a0,a0,932 # 8002c000 <disk>
    80006c64:	ffffa097          	auipc	ra,0xffffa
    80006c68:	05a080e7          	jalr	90(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006c6c:	00025717          	auipc	a4,0x25
    80006c70:	39470713          	addi	a4,a4,916 # 8002c000 <disk>
    80006c74:	00c75793          	srli	a5,a4,0xc
    80006c78:	2781                	sext.w	a5,a5
    80006c7a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006c7c:	00027797          	auipc	a5,0x27
    80006c80:	38478793          	addi	a5,a5,900 # 8002e000 <disk+0x2000>
    80006c84:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006c86:	00025717          	auipc	a4,0x25
    80006c8a:	3fa70713          	addi	a4,a4,1018 # 8002c080 <disk+0x80>
    80006c8e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006c90:	00026717          	auipc	a4,0x26
    80006c94:	37070713          	addi	a4,a4,880 # 8002d000 <disk+0x1000>
    80006c98:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006c9a:	4705                	li	a4,1
    80006c9c:	00e78c23          	sb	a4,24(a5)
    80006ca0:	00e78ca3          	sb	a4,25(a5)
    80006ca4:	00e78d23          	sb	a4,26(a5)
    80006ca8:	00e78da3          	sb	a4,27(a5)
    80006cac:	00e78e23          	sb	a4,28(a5)
    80006cb0:	00e78ea3          	sb	a4,29(a5)
    80006cb4:	00e78f23          	sb	a4,30(a5)
    80006cb8:	00e78fa3          	sb	a4,31(a5)
}
    80006cbc:	60e2                	ld	ra,24(sp)
    80006cbe:	6442                	ld	s0,16(sp)
    80006cc0:	64a2                	ld	s1,8(sp)
    80006cc2:	6105                	addi	sp,sp,32
    80006cc4:	8082                	ret
    panic("could not find virtio disk");
    80006cc6:	00003517          	auipc	a0,0x3
    80006cca:	de250513          	addi	a0,a0,-542 # 80009aa8 <syscalls+0x388>
    80006cce:	ffffa097          	auipc	ra,0xffffa
    80006cd2:	85c080e7          	jalr	-1956(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006cd6:	00003517          	auipc	a0,0x3
    80006cda:	df250513          	addi	a0,a0,-526 # 80009ac8 <syscalls+0x3a8>
    80006cde:	ffffa097          	auipc	ra,0xffffa
    80006ce2:	84c080e7          	jalr	-1972(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006ce6:	00003517          	auipc	a0,0x3
    80006cea:	e0250513          	addi	a0,a0,-510 # 80009ae8 <syscalls+0x3c8>
    80006cee:	ffffa097          	auipc	ra,0xffffa
    80006cf2:	83c080e7          	jalr	-1988(ra) # 8000052a <panic>

0000000080006cf6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006cf6:	7119                	addi	sp,sp,-128
    80006cf8:	fc86                	sd	ra,120(sp)
    80006cfa:	f8a2                	sd	s0,112(sp)
    80006cfc:	f4a6                	sd	s1,104(sp)
    80006cfe:	f0ca                	sd	s2,96(sp)
    80006d00:	ecce                	sd	s3,88(sp)
    80006d02:	e8d2                	sd	s4,80(sp)
    80006d04:	e4d6                	sd	s5,72(sp)
    80006d06:	e0da                	sd	s6,64(sp)
    80006d08:	fc5e                	sd	s7,56(sp)
    80006d0a:	f862                	sd	s8,48(sp)
    80006d0c:	f466                	sd	s9,40(sp)
    80006d0e:	f06a                	sd	s10,32(sp)
    80006d10:	ec6e                	sd	s11,24(sp)
    80006d12:	0100                	addi	s0,sp,128
    80006d14:	8aaa                	mv	s5,a0
    80006d16:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006d18:	00c52c83          	lw	s9,12(a0)
    80006d1c:	001c9c9b          	slliw	s9,s9,0x1
    80006d20:	1c82                	slli	s9,s9,0x20
    80006d22:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006d26:	00027517          	auipc	a0,0x27
    80006d2a:	40250513          	addi	a0,a0,1026 # 8002e128 <disk+0x2128>
    80006d2e:	ffffa097          	auipc	ra,0xffffa
    80006d32:	e94080e7          	jalr	-364(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006d36:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006d38:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006d3a:	00025c17          	auipc	s8,0x25
    80006d3e:	2c6c0c13          	addi	s8,s8,710 # 8002c000 <disk>
    80006d42:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006d44:	4b0d                	li	s6,3
    80006d46:	a0ad                	j	80006db0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006d48:	00fc0733          	add	a4,s8,a5
    80006d4c:	975e                	add	a4,a4,s7
    80006d4e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006d52:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006d54:	0207c563          	bltz	a5,80006d7e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006d58:	2905                	addiw	s2,s2,1
    80006d5a:	0611                	addi	a2,a2,4
    80006d5c:	19690d63          	beq	s2,s6,80006ef6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006d60:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006d62:	00027717          	auipc	a4,0x27
    80006d66:	2b670713          	addi	a4,a4,694 # 8002e018 <disk+0x2018>
    80006d6a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006d6c:	00074683          	lbu	a3,0(a4)
    80006d70:	fee1                	bnez	a3,80006d48 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006d72:	2785                	addiw	a5,a5,1
    80006d74:	0705                	addi	a4,a4,1
    80006d76:	fe979be3          	bne	a5,s1,80006d6c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006d7a:	57fd                	li	a5,-1
    80006d7c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006d7e:	01205d63          	blez	s2,80006d98 <virtio_disk_rw+0xa2>
    80006d82:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006d84:	000a2503          	lw	a0,0(s4)
    80006d88:	00000097          	auipc	ra,0x0
    80006d8c:	d8e080e7          	jalr	-626(ra) # 80006b16 <free_desc>
      for(int j = 0; j < i; j++)
    80006d90:	2d85                	addiw	s11,s11,1
    80006d92:	0a11                	addi	s4,s4,4
    80006d94:	ffb918e3          	bne	s2,s11,80006d84 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006d98:	00027597          	auipc	a1,0x27
    80006d9c:	39058593          	addi	a1,a1,912 # 8002e128 <disk+0x2128>
    80006da0:	00027517          	auipc	a0,0x27
    80006da4:	27850513          	addi	a0,a0,632 # 8002e018 <disk+0x2018>
    80006da8:	ffffb097          	auipc	ra,0xffffb
    80006dac:	27e080e7          	jalr	638(ra) # 80002026 <sleep>
  for(int i = 0; i < 3; i++){
    80006db0:	f8040a13          	addi	s4,s0,-128
{
    80006db4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006db6:	894e                	mv	s2,s3
    80006db8:	b765                	j	80006d60 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006dba:	00027697          	auipc	a3,0x27
    80006dbe:	2466b683          	ld	a3,582(a3) # 8002e000 <disk+0x2000>
    80006dc2:	96ba                	add	a3,a3,a4
    80006dc4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006dc8:	00025817          	auipc	a6,0x25
    80006dcc:	23880813          	addi	a6,a6,568 # 8002c000 <disk>
    80006dd0:	00027697          	auipc	a3,0x27
    80006dd4:	23068693          	addi	a3,a3,560 # 8002e000 <disk+0x2000>
    80006dd8:	6290                	ld	a2,0(a3)
    80006dda:	963a                	add	a2,a2,a4
    80006ddc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006de0:	0015e593          	ori	a1,a1,1
    80006de4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006de8:	f8842603          	lw	a2,-120(s0)
    80006dec:	628c                	ld	a1,0(a3)
    80006dee:	972e                	add	a4,a4,a1
    80006df0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006df4:	20050593          	addi	a1,a0,512
    80006df8:	0592                	slli	a1,a1,0x4
    80006dfa:	95c2                	add	a1,a1,a6
    80006dfc:	577d                	li	a4,-1
    80006dfe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006e02:	00461713          	slli	a4,a2,0x4
    80006e06:	6290                	ld	a2,0(a3)
    80006e08:	963a                	add	a2,a2,a4
    80006e0a:	03078793          	addi	a5,a5,48
    80006e0e:	97c2                	add	a5,a5,a6
    80006e10:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006e12:	629c                	ld	a5,0(a3)
    80006e14:	97ba                	add	a5,a5,a4
    80006e16:	4605                	li	a2,1
    80006e18:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006e1a:	629c                	ld	a5,0(a3)
    80006e1c:	97ba                	add	a5,a5,a4
    80006e1e:	4809                	li	a6,2
    80006e20:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006e24:	629c                	ld	a5,0(a3)
    80006e26:	973e                	add	a4,a4,a5
    80006e28:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006e2c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006e30:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006e34:	6698                	ld	a4,8(a3)
    80006e36:	00275783          	lhu	a5,2(a4)
    80006e3a:	8b9d                	andi	a5,a5,7
    80006e3c:	0786                	slli	a5,a5,0x1
    80006e3e:	97ba                	add	a5,a5,a4
    80006e40:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006e44:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006e48:	6698                	ld	a4,8(a3)
    80006e4a:	00275783          	lhu	a5,2(a4)
    80006e4e:	2785                	addiw	a5,a5,1
    80006e50:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006e54:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006e58:	100017b7          	lui	a5,0x10001
    80006e5c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006e60:	004aa783          	lw	a5,4(s5)
    80006e64:	02c79163          	bne	a5,a2,80006e86 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006e68:	00027917          	auipc	s2,0x27
    80006e6c:	2c090913          	addi	s2,s2,704 # 8002e128 <disk+0x2128>
  while(b->disk == 1) {
    80006e70:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006e72:	85ca                	mv	a1,s2
    80006e74:	8556                	mv	a0,s5
    80006e76:	ffffb097          	auipc	ra,0xffffb
    80006e7a:	1b0080e7          	jalr	432(ra) # 80002026 <sleep>
  while(b->disk == 1) {
    80006e7e:	004aa783          	lw	a5,4(s5)
    80006e82:	fe9788e3          	beq	a5,s1,80006e72 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006e86:	f8042903          	lw	s2,-128(s0)
    80006e8a:	20090793          	addi	a5,s2,512
    80006e8e:	00479713          	slli	a4,a5,0x4
    80006e92:	00025797          	auipc	a5,0x25
    80006e96:	16e78793          	addi	a5,a5,366 # 8002c000 <disk>
    80006e9a:	97ba                	add	a5,a5,a4
    80006e9c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006ea0:	00027997          	auipc	s3,0x27
    80006ea4:	16098993          	addi	s3,s3,352 # 8002e000 <disk+0x2000>
    80006ea8:	00491713          	slli	a4,s2,0x4
    80006eac:	0009b783          	ld	a5,0(s3)
    80006eb0:	97ba                	add	a5,a5,a4
    80006eb2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006eb6:	854a                	mv	a0,s2
    80006eb8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006ebc:	00000097          	auipc	ra,0x0
    80006ec0:	c5a080e7          	jalr	-934(ra) # 80006b16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006ec4:	8885                	andi	s1,s1,1
    80006ec6:	f0ed                	bnez	s1,80006ea8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006ec8:	00027517          	auipc	a0,0x27
    80006ecc:	26050513          	addi	a0,a0,608 # 8002e128 <disk+0x2128>
    80006ed0:	ffffa097          	auipc	ra,0xffffa
    80006ed4:	da6080e7          	jalr	-602(ra) # 80000c76 <release>
}
    80006ed8:	70e6                	ld	ra,120(sp)
    80006eda:	7446                	ld	s0,112(sp)
    80006edc:	74a6                	ld	s1,104(sp)
    80006ede:	7906                	ld	s2,96(sp)
    80006ee0:	69e6                	ld	s3,88(sp)
    80006ee2:	6a46                	ld	s4,80(sp)
    80006ee4:	6aa6                	ld	s5,72(sp)
    80006ee6:	6b06                	ld	s6,64(sp)
    80006ee8:	7be2                	ld	s7,56(sp)
    80006eea:	7c42                	ld	s8,48(sp)
    80006eec:	7ca2                	ld	s9,40(sp)
    80006eee:	7d02                	ld	s10,32(sp)
    80006ef0:	6de2                	ld	s11,24(sp)
    80006ef2:	6109                	addi	sp,sp,128
    80006ef4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006ef6:	f8042503          	lw	a0,-128(s0)
    80006efa:	20050793          	addi	a5,a0,512
    80006efe:	0792                	slli	a5,a5,0x4
  if(write)
    80006f00:	00025817          	auipc	a6,0x25
    80006f04:	10080813          	addi	a6,a6,256 # 8002c000 <disk>
    80006f08:	00f80733          	add	a4,a6,a5
    80006f0c:	01a036b3          	snez	a3,s10
    80006f10:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006f14:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006f18:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006f1c:	7679                	lui	a2,0xffffe
    80006f1e:	963e                	add	a2,a2,a5
    80006f20:	00027697          	auipc	a3,0x27
    80006f24:	0e068693          	addi	a3,a3,224 # 8002e000 <disk+0x2000>
    80006f28:	6298                	ld	a4,0(a3)
    80006f2a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f2c:	0a878593          	addi	a1,a5,168
    80006f30:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006f32:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006f34:	6298                	ld	a4,0(a3)
    80006f36:	9732                	add	a4,a4,a2
    80006f38:	45c1                	li	a1,16
    80006f3a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006f3c:	6298                	ld	a4,0(a3)
    80006f3e:	9732                	add	a4,a4,a2
    80006f40:	4585                	li	a1,1
    80006f42:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006f46:	f8442703          	lw	a4,-124(s0)
    80006f4a:	628c                	ld	a1,0(a3)
    80006f4c:	962e                	add	a2,a2,a1
    80006f4e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcf00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006f52:	0712                	slli	a4,a4,0x4
    80006f54:	6290                	ld	a2,0(a3)
    80006f56:	963a                	add	a2,a2,a4
    80006f58:	058a8593          	addi	a1,s5,88
    80006f5c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006f5e:	6294                	ld	a3,0(a3)
    80006f60:	96ba                	add	a3,a3,a4
    80006f62:	40000613          	li	a2,1024
    80006f66:	c690                	sw	a2,8(a3)
  if(write)
    80006f68:	e40d19e3          	bnez	s10,80006dba <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006f6c:	00027697          	auipc	a3,0x27
    80006f70:	0946b683          	ld	a3,148(a3) # 8002e000 <disk+0x2000>
    80006f74:	96ba                	add	a3,a3,a4
    80006f76:	4609                	li	a2,2
    80006f78:	00c69623          	sh	a2,12(a3)
    80006f7c:	b5b1                	j	80006dc8 <virtio_disk_rw+0xd2>

0000000080006f7e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006f7e:	1101                	addi	sp,sp,-32
    80006f80:	ec06                	sd	ra,24(sp)
    80006f82:	e822                	sd	s0,16(sp)
    80006f84:	e426                	sd	s1,8(sp)
    80006f86:	e04a                	sd	s2,0(sp)
    80006f88:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006f8a:	00027517          	auipc	a0,0x27
    80006f8e:	19e50513          	addi	a0,a0,414 # 8002e128 <disk+0x2128>
    80006f92:	ffffa097          	auipc	ra,0xffffa
    80006f96:	c30080e7          	jalr	-976(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006f9a:	10001737          	lui	a4,0x10001
    80006f9e:	533c                	lw	a5,96(a4)
    80006fa0:	8b8d                	andi	a5,a5,3
    80006fa2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006fa4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006fa8:	00027797          	auipc	a5,0x27
    80006fac:	05878793          	addi	a5,a5,88 # 8002e000 <disk+0x2000>
    80006fb0:	6b94                	ld	a3,16(a5)
    80006fb2:	0207d703          	lhu	a4,32(a5)
    80006fb6:	0026d783          	lhu	a5,2(a3)
    80006fba:	06f70163          	beq	a4,a5,8000701c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006fbe:	00025917          	auipc	s2,0x25
    80006fc2:	04290913          	addi	s2,s2,66 # 8002c000 <disk>
    80006fc6:	00027497          	auipc	s1,0x27
    80006fca:	03a48493          	addi	s1,s1,58 # 8002e000 <disk+0x2000>
    __sync_synchronize();
    80006fce:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006fd2:	6898                	ld	a4,16(s1)
    80006fd4:	0204d783          	lhu	a5,32(s1)
    80006fd8:	8b9d                	andi	a5,a5,7
    80006fda:	078e                	slli	a5,a5,0x3
    80006fdc:	97ba                	add	a5,a5,a4
    80006fde:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006fe0:	20078713          	addi	a4,a5,512
    80006fe4:	0712                	slli	a4,a4,0x4
    80006fe6:	974a                	add	a4,a4,s2
    80006fe8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006fec:	e731                	bnez	a4,80007038 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006fee:	20078793          	addi	a5,a5,512
    80006ff2:	0792                	slli	a5,a5,0x4
    80006ff4:	97ca                	add	a5,a5,s2
    80006ff6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006ff8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006ffc:	ffffb097          	auipc	ra,0xffffb
    80007000:	1b6080e7          	jalr	438(ra) # 800021b2 <wakeup>

    disk.used_idx += 1;
    80007004:	0204d783          	lhu	a5,32(s1)
    80007008:	2785                	addiw	a5,a5,1
    8000700a:	17c2                	slli	a5,a5,0x30
    8000700c:	93c1                	srli	a5,a5,0x30
    8000700e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007012:	6898                	ld	a4,16(s1)
    80007014:	00275703          	lhu	a4,2(a4)
    80007018:	faf71be3          	bne	a4,a5,80006fce <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000701c:	00027517          	auipc	a0,0x27
    80007020:	10c50513          	addi	a0,a0,268 # 8002e128 <disk+0x2128>
    80007024:	ffffa097          	auipc	ra,0xffffa
    80007028:	c52080e7          	jalr	-942(ra) # 80000c76 <release>
}
    8000702c:	60e2                	ld	ra,24(sp)
    8000702e:	6442                	ld	s0,16(sp)
    80007030:	64a2                	ld	s1,8(sp)
    80007032:	6902                	ld	s2,0(sp)
    80007034:	6105                	addi	sp,sp,32
    80007036:	8082                	ret
      panic("virtio_disk_intr status");
    80007038:	00003517          	auipc	a0,0x3
    8000703c:	ad050513          	addi	a0,a0,-1328 # 80009b08 <syscalls+0x3e8>
    80007040:	ffff9097          	auipc	ra,0xffff9
    80007044:	4ea080e7          	jalr	1258(ra) # 8000052a <panic>
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
