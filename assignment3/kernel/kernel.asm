
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
    80000068:	a7c78793          	addi	a5,a5,-1412 # 80006ae0 <timervec>
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
    80000122:	132080e7          	jalr	306(ra) # 80002250 <either_copyin>
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
    800001c6:	e92080e7          	jalr	-366(ra) # 80002054 <sleep>
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
    80000202:	ffc080e7          	jalr	-4(ra) # 800021fa <either_copyout>
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
    800002e2:	fc8080e7          	jalr	-56(ra) # 800022a6 <procdump>
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
    80000436:	c86080e7          	jalr	-890(ra) # 800020b8 <wakeup>
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
    80000882:	83a080e7          	jalr	-1990(ra) # 800020b8 <wakeup>
    
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
    8000090e:	74a080e7          	jalr	1866(ra) # 80002054 <sleep>
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
    80000eb6:	0d4080e7          	jalr	212(ra) # 80002f86 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	c66080e7          	jalr	-922(ra) # 80006b20 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fe0080e7          	jalr	-32(ra) # 80001ea2 <scheduler>
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
    80000f2e:	034080e7          	jalr	52(ra) # 80002f5e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	054080e7          	jalr	84(ra) # 80002f86 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	bd0080e7          	jalr	-1072(ra) # 80006b0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	bde080e7          	jalr	-1058(ra) # 80006b20 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	7b4080e7          	jalr	1972(ra) # 800036fe <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	e46080e7          	jalr	-442(ra) # 80003d98 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	106080e7          	jalr	262(ra) # 80005060 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	ce0080e7          	jalr	-800(ra) # 80006c42 <virtio_disk_init>
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
    80001428:	70e080e7          	jalr	1806(ra) # 80002b32 <remove_page_from_ram>
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
    80001492:	870080e7          	jalr	-1936(ra) # 80002cfe <insert_page_to_ram>
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
  char *mem =0;

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
  char *mem =0;
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
    80001a32:	570080e7          	jalr	1392(ra) # 80002f9e <usertrapret>
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
    80001a4c:	2d0080e7          	jalr	720(ra) # 80003d18 <fsinit>
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
    80001d0e:	a3c080e7          	jalr	-1476(ra) # 80004746 <namei>
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

0000000080001da2 <fill_swapFile>:
{
    80001da2:	7179                	addi	sp,sp,-48
    80001da4:	f406                	sd	ra,40(sp)
    80001da6:	f022                	sd	s0,32(sp)
    80001da8:	ec26                	sd	s1,24(sp)
    80001daa:	e84a                	sd	s2,16(sp)
    80001dac:	e44e                	sd	s3,8(sp)
    80001dae:	e052                	sd	s4,0(sp)
    80001db0:	1800                	addi	s0,sp,48
    80001db2:	892a                	mv	s2,a0
  char *page = kalloc();
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	d1e080e7          	jalr	-738(ra) # 80000ad2 <kalloc>
    80001dbc:	89aa                	mv	s3,a0
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001dbe:	27090493          	addi	s1,s2,624
    80001dc2:	37090a13          	addi	s4,s2,880
    if (writeToSwapFile(p, page, disk_pg->offset, PGSIZE) < 0) {
    80001dc6:	6685                	lui	a3,0x1
    80001dc8:	4490                	lw	a2,8(s1)
    80001dca:	85ce                	mv	a1,s3
    80001dcc:	854a                	mv	a0,s2
    80001dce:	00003097          	auipc	ra,0x3
    80001dd2:	c7c080e7          	jalr	-900(ra) # 80004a4a <writeToSwapFile>
    80001dd6:	02054363          	bltz	a0,80001dfc <fill_swapFile+0x5a>
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001dda:	04c1                	addi	s1,s1,16
    80001ddc:	fe9a15e3          	bne	s4,s1,80001dc6 <fill_swapFile+0x24>
  kfree(page);
    80001de0:	854e                	mv	a0,s3
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	bf4080e7          	jalr	-1036(ra) # 800009d6 <kfree>
  return 0;
    80001dea:	4501                	li	a0,0
}
    80001dec:	70a2                	ld	ra,40(sp)
    80001dee:	7402                	ld	s0,32(sp)
    80001df0:	64e2                	ld	s1,24(sp)
    80001df2:	6942                	ld	s2,16(sp)
    80001df4:	69a2                	ld	s3,8(sp)
    80001df6:	6a02                	ld	s4,0(sp)
    80001df8:	6145                	addi	sp,sp,48
    80001dfa:	8082                	ret
      return -1;
    80001dfc:	557d                	li	a0,-1
    80001dfe:	b7fd                	j	80001dec <fill_swapFile+0x4a>

0000000080001e00 <copy_swapFile>:
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001e00:	c559                	beqz	a0,80001e8e <copy_swapFile+0x8e>
int copy_swapFile(struct proc *src, struct proc *dst) {
    80001e02:	7139                	addi	sp,sp,-64
    80001e04:	fc06                	sd	ra,56(sp)
    80001e06:	f822                	sd	s0,48(sp)
    80001e08:	f426                	sd	s1,40(sp)
    80001e0a:	f04a                	sd	s2,32(sp)
    80001e0c:	ec4e                	sd	s3,24(sp)
    80001e0e:	e852                	sd	s4,16(sp)
    80001e10:	e456                	sd	s5,8(sp)
    80001e12:	0080                	addi	s0,sp,64
    80001e14:	8a2a                	mv	s4,a0
    80001e16:	8aae                	mv	s5,a1
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001e18:	16853783          	ld	a5,360(a0)
    80001e1c:	cbbd                	beqz	a5,80001e92 <copy_swapFile+0x92>
    80001e1e:	cda5                	beqz	a1,80001e96 <copy_swapFile+0x96>
    80001e20:	1685b783          	ld	a5,360(a1)
    80001e24:	cbbd                	beqz	a5,80001e9a <copy_swapFile+0x9a>
  char *buffer = (char *)kalloc();
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	cac080e7          	jalr	-852(ra) # 80000ad2 <kalloc>
    80001e2e:	89aa                	mv	s3,a0
  for (struct disk_page *disk_pg = src->disk_pages; disk_pg < &src->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001e30:	270a0493          	addi	s1,s4,624
    80001e34:	370a0913          	addi	s2,s4,880
    80001e38:	a021                	j	80001e40 <copy_swapFile+0x40>
    80001e3a:	04c1                	addi	s1,s1,16
    80001e3c:	02990a63          	beq	s2,s1,80001e70 <copy_swapFile+0x70>
    if(disk_pg->used) {
    80001e40:	44dc                	lw	a5,12(s1)
    80001e42:	dfe5                	beqz	a5,80001e3a <copy_swapFile+0x3a>
      if (readFromSwapFile(src, buffer, disk_pg->offset, PGSIZE) < 0) {
    80001e44:	6685                	lui	a3,0x1
    80001e46:	4490                	lw	a2,8(s1)
    80001e48:	85ce                	mv	a1,s3
    80001e4a:	8552                	mv	a0,s4
    80001e4c:	00003097          	auipc	ra,0x3
    80001e50:	c22080e7          	jalr	-990(ra) # 80004a6e <readFromSwapFile>
    80001e54:	04054563          	bltz	a0,80001e9e <copy_swapFile+0x9e>
      if (writeToSwapFile(dst, buffer, disk_pg->offset, PGSIZE) < 0) {
    80001e58:	6685                	lui	a3,0x1
    80001e5a:	4490                	lw	a2,8(s1)
    80001e5c:	85ce                	mv	a1,s3
    80001e5e:	8556                	mv	a0,s5
    80001e60:	00003097          	auipc	ra,0x3
    80001e64:	bea080e7          	jalr	-1046(ra) # 80004a4a <writeToSwapFile>
    80001e68:	fc0559e3          	bgez	a0,80001e3a <copy_swapFile+0x3a>
        return -1;
    80001e6c:	557d                	li	a0,-1
    80001e6e:	a039                	j	80001e7c <copy_swapFile+0x7c>
  kfree((void *)buffer);
    80001e70:	854e                	mv	a0,s3
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	b64080e7          	jalr	-1180(ra) # 800009d6 <kfree>
  return 0;
    80001e7a:	4501                	li	a0,0
}
    80001e7c:	70e2                	ld	ra,56(sp)
    80001e7e:	7442                	ld	s0,48(sp)
    80001e80:	74a2                	ld	s1,40(sp)
    80001e82:	7902                	ld	s2,32(sp)
    80001e84:	69e2                	ld	s3,24(sp)
    80001e86:	6a42                	ld	s4,16(sp)
    80001e88:	6aa2                	ld	s5,8(sp)
    80001e8a:	6121                	addi	sp,sp,64
    80001e8c:	8082                	ret
    return -1;
    80001e8e:	557d                	li	a0,-1
}
    80001e90:	8082                	ret
    return -1;
    80001e92:	557d                	li	a0,-1
    80001e94:	b7e5                	j	80001e7c <copy_swapFile+0x7c>
    80001e96:	557d                	li	a0,-1
    80001e98:	b7d5                	j	80001e7c <copy_swapFile+0x7c>
    80001e9a:	557d                	li	a0,-1
    80001e9c:	b7c5                	j	80001e7c <copy_swapFile+0x7c>
        return -1;
    80001e9e:	557d                	li	a0,-1
    80001ea0:	bff1                	j	80001e7c <copy_swapFile+0x7c>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	00010717          	auipc	a4,0x10
    80001ec2:	3e270713          	addi	a4,a4,994 # 800122a0 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	00010717          	auipc	a4,0x10
    80001ed0:	40c70713          	addi	a4,a4,1036 # 800122d8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	00010a17          	auipc	s4,0x10
    80001ee0:	3c4a0a13          	addi	s4,s4,964 # 800122a0 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	0001e917          	auipc	s2,0x1e
    80001eea:	5ea90913          	addi	s2,s2,1514 # 800204d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	00010497          	auipc	s1,0x10
    80001efe:	7d648493          	addi	s1,s1,2006 # 800126d0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d70080e7          	jalr	-656(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	37848493          	addi	s1,s1,888
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	caa080e7          	jalr	-854(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00001097          	auipc	ra,0x1
    80001f38:	fc0080e7          	jalr	-64(ra) # 80002ef4 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a84080e7          	jalr	-1404(ra) # 800019d4 <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	bee080e7          	jalr	-1042(ra) # 80000b48 <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	00010717          	auipc	a4,0x10
    80001f6e:	33670713          	addi	a4,a4,822 # 800122a0 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5) # 10a8 <_entry-0x7fffef58>
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	00010917          	auipc	s2,0x10
    80001f94:	31090913          	addi	s2,s2,784 # 800122a0 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	00010597          	auipc	a1,0x10
    80001fac:	33058593          	addi	a1,a1,816 # 800122d8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00001097          	auipc	ra,0x1
    80001fba:	f3e080e7          	jalr	-194(ra) # 80002ef4 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	97ca                	add	a5,a5,s2
    80001fc6:	0b37a623          	sw	s3,172(a5)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00007517          	auipc	a0,0x7
    80001fdc:	22850513          	addi	a0,a0,552 # 80009200 <digits+0x1c0>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	54a080e7          	jalr	1354(ra) # 8000052a <panic>
    panic("sched locks");
    80001fe8:	00007517          	auipc	a0,0x7
    80001fec:	22850513          	addi	a0,a0,552 # 80009210 <digits+0x1d0>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	53a080e7          	jalr	1338(ra) # 8000052a <panic>
    panic("sched running");
    80001ff8:	00007517          	auipc	a0,0x7
    80001ffc:	22850513          	addi	a0,a0,552 # 80009220 <digits+0x1e0>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	52a080e7          	jalr	1322(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002008:	00007517          	auipc	a0,0x7
    8000200c:	22850513          	addi	a0,a0,552 # 80009230 <digits+0x1f0>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	51a080e7          	jalr	1306(ra) # 8000052a <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	9b2080e7          	jalr	-1614(ra) # 800019d4 <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	b96080e7          	jalr	-1130(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c34080e7          	jalr	-972(ra) # 80000c76 <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	96e080e7          	jalr	-1682(ra) # 800019d4 <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b52080e7          	jalr	-1198(ra) # 80000bc2 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	bfc080e7          	jalr	-1028(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bde080e7          	jalr	-1058(ra) # 80000c76 <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b20080e7          	jalr	-1248(ra) # 80000bc2 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	00010497          	auipc	s1,0x10
    800020d0:	60448493          	addi	s1,s1,1540 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	0001e917          	auipc	s2,0x1e
    800020dc:	3f890913          	addi	s2,s2,1016 # 800204d0 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	b92080e7          	jalr	-1134(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	37848493          	addi	s1,s1,888
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8e0080e7          	jalr	-1824(ra) # 800019d4 <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ac0080e7          	jalr	-1344(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	00010497          	auipc	s1,0x10
    80002144:	59048493          	addi	s1,s1,1424 # 800126d0 <proc>
      pp->parent = initproc;
    80002148:	00008a17          	auipc	s4,0x8
    8000214c:	ee0a0a13          	addi	s4,s4,-288 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	0001e997          	auipc	s3,0x1e
    80002154:	38098993          	addi	s3,s3,896 # 800204d0 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	37848493          	addi	s1,s1,888
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	1800                	addi	s0,sp,48
    80002196:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002198:	00010497          	auipc	s1,0x10
    8000219c:	53848493          	addi	s1,s1,1336 # 800126d0 <proc>
    800021a0:	0001e997          	auipc	s3,0x1e
    800021a4:	33098993          	addi	s3,s3,816 # 800204d0 <tickslock>
    acquire(&p->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	a18080e7          	jalr	-1512(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800021b2:	589c                	lw	a5,48(s1)
    800021b4:	01278d63          	beq	a5,s2,800021ce <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800021b8:	8526                	mv	a0,s1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	abc080e7          	jalr	-1348(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800021c2:	37848493          	addi	s1,s1,888
    800021c6:	ff3491e3          	bne	s1,s3,800021a8 <kill+0x20>
  }
  return -1;
    800021ca:	557d                	li	a0,-1
    800021cc:	a829                	j	800021e6 <kill+0x5e>
      p->killed = 1;
    800021ce:	4785                	li	a5,1
    800021d0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800021d2:	4c98                	lw	a4,24(s1)
    800021d4:	4789                	li	a5,2
    800021d6:	00f70f63          	beq	a4,a5,800021f4 <kill+0x6c>
      release(&p->lock);
    800021da:	8526                	mv	a0,s1
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	a9a080e7          	jalr	-1382(ra) # 80000c76 <release>
      return 0;
    800021e4:	4501                	li	a0,0
}
    800021e6:	70a2                	ld	ra,40(sp)
    800021e8:	7402                	ld	s0,32(sp)
    800021ea:	64e2                	ld	s1,24(sp)
    800021ec:	6942                	ld	s2,16(sp)
    800021ee:	69a2                	ld	s3,8(sp)
    800021f0:	6145                	addi	sp,sp,48
    800021f2:	8082                	ret
        p->state = RUNNABLE;
    800021f4:	478d                	li	a5,3
    800021f6:	cc9c                	sw	a5,24(s1)
    800021f8:	b7cd                	j	800021da <kill+0x52>

00000000800021fa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800021fa:	7179                	addi	sp,sp,-48
    800021fc:	f406                	sd	ra,40(sp)
    800021fe:	f022                	sd	s0,32(sp)
    80002200:	ec26                	sd	s1,24(sp)
    80002202:	e84a                	sd	s2,16(sp)
    80002204:	e44e                	sd	s3,8(sp)
    80002206:	e052                	sd	s4,0(sp)
    80002208:	1800                	addi	s0,sp,48
    8000220a:	84aa                	mv	s1,a0
    8000220c:	892e                	mv	s2,a1
    8000220e:	89b2                	mv	s3,a2
    80002210:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	7c2080e7          	jalr	1986(ra) # 800019d4 <myproc>
  if(user_dst){
    8000221a:	c08d                	beqz	s1,8000223c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000221c:	86d2                	mv	a3,s4
    8000221e:	864e                	mv	a2,s3
    80002220:	85ca                	mv	a1,s2
    80002222:	6928                	ld	a0,80(a0)
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	470080e7          	jalr	1136(ra) # 80001694 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000222c:	70a2                	ld	ra,40(sp)
    8000222e:	7402                	ld	s0,32(sp)
    80002230:	64e2                	ld	s1,24(sp)
    80002232:	6942                	ld	s2,16(sp)
    80002234:	69a2                	ld	s3,8(sp)
    80002236:	6a02                	ld	s4,0(sp)
    80002238:	6145                	addi	sp,sp,48
    8000223a:	8082                	ret
    memmove((char *)dst, src, len);
    8000223c:	000a061b          	sext.w	a2,s4
    80002240:	85ce                	mv	a1,s3
    80002242:	854a                	mv	a0,s2
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	ad6080e7          	jalr	-1322(ra) # 80000d1a <memmove>
    return 0;
    8000224c:	8526                	mv	a0,s1
    8000224e:	bff9                	j	8000222c <either_copyout+0x32>

0000000080002250 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002250:	7179                	addi	sp,sp,-48
    80002252:	f406                	sd	ra,40(sp)
    80002254:	f022                	sd	s0,32(sp)
    80002256:	ec26                	sd	s1,24(sp)
    80002258:	e84a                	sd	s2,16(sp)
    8000225a:	e44e                	sd	s3,8(sp)
    8000225c:	e052                	sd	s4,0(sp)
    8000225e:	1800                	addi	s0,sp,48
    80002260:	892a                	mv	s2,a0
    80002262:	84ae                	mv	s1,a1
    80002264:	89b2                	mv	s3,a2
    80002266:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	76c080e7          	jalr	1900(ra) # 800019d4 <myproc>
  if(user_src){
    80002270:	c08d                	beqz	s1,80002292 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002272:	86d2                	mv	a3,s4
    80002274:	864e                	mv	a2,s3
    80002276:	85ca                	mv	a1,s2
    80002278:	6928                	ld	a0,80(a0)
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	4a6080e7          	jalr	1190(ra) # 80001720 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002282:	70a2                	ld	ra,40(sp)
    80002284:	7402                	ld	s0,32(sp)
    80002286:	64e2                	ld	s1,24(sp)
    80002288:	6942                	ld	s2,16(sp)
    8000228a:	69a2                	ld	s3,8(sp)
    8000228c:	6a02                	ld	s4,0(sp)
    8000228e:	6145                	addi	sp,sp,48
    80002290:	8082                	ret
    memmove(dst, (char*)src, len);
    80002292:	000a061b          	sext.w	a2,s4
    80002296:	85ce                	mv	a1,s3
    80002298:	854a                	mv	a0,s2
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	a80080e7          	jalr	-1408(ra) # 80000d1a <memmove>
    return 0;
    800022a2:	8526                	mv	a0,s1
    800022a4:	bff9                	j	80002282 <either_copyin+0x32>

00000000800022a6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800022a6:	715d                	addi	sp,sp,-80
    800022a8:	e486                	sd	ra,72(sp)
    800022aa:	e0a2                	sd	s0,64(sp)
    800022ac:	fc26                	sd	s1,56(sp)
    800022ae:	f84a                	sd	s2,48(sp)
    800022b0:	f44e                	sd	s3,40(sp)
    800022b2:	f052                	sd	s4,32(sp)
    800022b4:	ec56                	sd	s5,24(sp)
    800022b6:	e85a                	sd	s6,16(sp)
    800022b8:	e45e                	sd	s7,8(sp)
    800022ba:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800022bc:	00007517          	auipc	a0,0x7
    800022c0:	e0c50513          	addi	a0,a0,-500 # 800090c8 <digits+0x88>
    800022c4:	ffffe097          	auipc	ra,0xffffe
    800022c8:	2b0080e7          	jalr	688(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022cc:	00010497          	auipc	s1,0x10
    800022d0:	55c48493          	addi	s1,s1,1372 # 80012828 <proc+0x158>
    800022d4:	0001e917          	auipc	s2,0x1e
    800022d8:	35490913          	addi	s2,s2,852 # 80020628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022dc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800022de:	00007997          	auipc	s3,0x7
    800022e2:	f6a98993          	addi	s3,s3,-150 # 80009248 <digits+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    800022e6:	00007a97          	auipc	s5,0x7
    800022ea:	f6aa8a93          	addi	s5,s5,-150 # 80009250 <digits+0x210>
    printf("\n");
    800022ee:	00007a17          	auipc	s4,0x7
    800022f2:	ddaa0a13          	addi	s4,s4,-550 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022f6:	00007b97          	auipc	s7,0x7
    800022fa:	2a2b8b93          	addi	s7,s7,674 # 80009598 <states.0>
    800022fe:	a00d                	j	80002320 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002300:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    80002304:	8556                	mv	a0,s5
    80002306:	ffffe097          	auipc	ra,0xffffe
    8000230a:	26e080e7          	jalr	622(ra) # 80000574 <printf>
    printf("\n");
    8000230e:	8552                	mv	a0,s4
    80002310:	ffffe097          	auipc	ra,0xffffe
    80002314:	264080e7          	jalr	612(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002318:	37848493          	addi	s1,s1,888
    8000231c:	03248263          	beq	s1,s2,80002340 <procdump+0x9a>
    if(p->state == UNUSED)
    80002320:	86a6                	mv	a3,s1
    80002322:	ec04a783          	lw	a5,-320(s1)
    80002326:	dbed                	beqz	a5,80002318 <procdump+0x72>
      state = "???";
    80002328:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000232a:	fcfb6be3          	bltu	s6,a5,80002300 <procdump+0x5a>
    8000232e:	02079713          	slli	a4,a5,0x20
    80002332:	01d75793          	srli	a5,a4,0x1d
    80002336:	97de                	add	a5,a5,s7
    80002338:	6390                	ld	a2,0(a5)
    8000233a:	f279                	bnez	a2,80002300 <procdump+0x5a>
      state = "???";
    8000233c:	864e                	mv	a2,s3
    8000233e:	b7c9                	j	80002300 <procdump+0x5a>
  }
}
    80002340:	60a6                	ld	ra,72(sp)
    80002342:	6406                	ld	s0,64(sp)
    80002344:	74e2                	ld	s1,56(sp)
    80002346:	7942                	ld	s2,48(sp)
    80002348:	79a2                	ld	s3,40(sp)
    8000234a:	7a02                	ld	s4,32(sp)
    8000234c:	6ae2                	ld	s5,24(sp)
    8000234e:	6b42                	ld	s6,16(sp)
    80002350:	6ba2                	ld	s7,8(sp)
    80002352:	6161                	addi	sp,sp,80
    80002354:	8082                	ret

0000000080002356 <init_metadata>:

// ADDED Q1 - p->lock must not be held because of createSwapFile!
int init_metadata(struct proc *p)
{
    80002356:	1101                	addi	sp,sp,-32
    80002358:	ec06                	sd	ra,24(sp)
    8000235a:	e822                	sd	s0,16(sp)
    8000235c:	e426                	sd	s1,8(sp)
    8000235e:	1000                	addi	s0,sp,32
    80002360:	84aa                	mv	s1,a0
  if (!p->swapFile && createSwapFile(p) < 0) {
    80002362:	16853783          	ld	a5,360(a0)
    80002366:	c7a1                	beqz	a5,800023ae <init_metadata+0x58>
    return -1;
  }

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002368:	17048793          	addi	a5,s1,368
    8000236c:	27048713          	addi	a4,s1,624
    p->ram_pages[i].va = 0;
    80002370:	0007b023          	sd	zero,0(a5)
    p->ram_pages[i].age = 0; // ADDED Q2
    80002374:	0007a423          	sw	zero,8(a5)
    p->ram_pages[i].used = 0;
    80002378:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000237c:	07c1                	addi	a5,a5,16
    8000237e:	fee799e3          	bne	a5,a4,80002370 <init_metadata+0x1a>
    80002382:	27048793          	addi	a5,s1,624
    80002386:	4701                	li	a4,0
  }
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002388:	6605                	lui	a2,0x1
    8000238a:	66c1                	lui	a3,0x10
    p->disk_pages[i].va = 0;
    8000238c:	0007b023          	sd	zero,0(a5)
    p->disk_pages[i].offset = i * PGSIZE;
    80002390:	c798                	sw	a4,8(a5)
    p->disk_pages[i].used = 0;
    80002392:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002396:	07c1                	addi	a5,a5,16
    80002398:	9f31                	addw	a4,a4,a2
    8000239a:	fed719e3          	bne	a4,a3,8000238c <init_metadata+0x36>
  }
  p->scfifo_index = 0; // ADDED Q2
    8000239e:	3604a823          	sw	zero,880(s1)
  return 0;
    800023a2:	4501                	li	a0,0
}
    800023a4:	60e2                	ld	ra,24(sp)
    800023a6:	6442                	ld	s0,16(sp)
    800023a8:	64a2                	ld	s1,8(sp)
    800023aa:	6105                	addi	sp,sp,32
    800023ac:	8082                	ret
  if (!p->swapFile && createSwapFile(p) < 0) {
    800023ae:	00002097          	auipc	ra,0x2
    800023b2:	5ec080e7          	jalr	1516(ra) # 8000499a <createSwapFile>
    800023b6:	fa0559e3          	bgez	a0,80002368 <init_metadata+0x12>
    return -1;
    800023ba:	557d                	li	a0,-1
    800023bc:	b7e5                	j	800023a4 <init_metadata+0x4e>

00000000800023be <free_metadata>:

// p->lock must not be held because of removeSwapFile!
void free_metadata(struct proc *p)
{
    800023be:	1101                	addi	sp,sp,-32
    800023c0:	ec06                	sd	ra,24(sp)
    800023c2:	e822                	sd	s0,16(sp)
    800023c4:	e426                	sd	s1,8(sp)
    800023c6:	1000                	addi	s0,sp,32
    800023c8:	84aa                	mv	s1,a0
    if (p->swapFile && removeSwapFile(p) < 0) {
    800023ca:	16853783          	ld	a5,360(a0)
    800023ce:	c799                	beqz	a5,800023dc <free_metadata+0x1e>
    800023d0:	00002097          	auipc	ra,0x2
    800023d4:	422080e7          	jalr	1058(ra) # 800047f2 <removeSwapFile>
    800023d8:	04054563          	bltz	a0,80002422 <free_metadata+0x64>
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;
    800023dc:	1604b423          	sd	zero,360(s1)

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800023e0:	17048793          	addi	a5,s1,368
    800023e4:	27048713          	addi	a4,s1,624
      p->ram_pages[i].va = 0;
    800023e8:	0007b023          	sd	zero,0(a5)
      p->ram_pages[i].age = 0; // ADDED Q2
    800023ec:	0007a423          	sw	zero,8(a5)
      p->ram_pages[i].used = 0;
    800023f0:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800023f4:	07c1                	addi	a5,a5,16
    800023f6:	fee799e3          	bne	a5,a4,800023e8 <free_metadata+0x2a>
    800023fa:	27048793          	addi	a5,s1,624
    800023fe:	37048713          	addi	a4,s1,880
    }
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
      p->disk_pages[i].va = 0;
    80002402:	0007b023          	sd	zero,0(a5)
      p->disk_pages[i].offset = 0;
    80002406:	0007a423          	sw	zero,8(a5)
      p->disk_pages[i].used = 0;
    8000240a:	0007a623          	sw	zero,12(a5)
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
    8000240e:	07c1                	addi	a5,a5,16
    80002410:	fee799e3          	bne	a5,a4,80002402 <free_metadata+0x44>
    }
    p->scfifo_index = 0; // ADDED Q2
    80002414:	3604a823          	sw	zero,880(s1)
}
    80002418:	60e2                	ld	ra,24(sp)
    8000241a:	6442                	ld	s0,16(sp)
    8000241c:	64a2                	ld	s1,8(sp)
    8000241e:	6105                	addi	sp,sp,32
    80002420:	8082                	ret
      panic("free_metadata: removeSwapFile failed");
    80002422:	00007517          	auipc	a0,0x7
    80002426:	e3e50513          	addi	a0,a0,-450 # 80009260 <digits+0x220>
    8000242a:	ffffe097          	auipc	ra,0xffffe
    8000242e:	100080e7          	jalr	256(ra) # 8000052a <panic>

0000000080002432 <fork>:
{
    80002432:	7139                	addi	sp,sp,-64
    80002434:	fc06                	sd	ra,56(sp)
    80002436:	f822                	sd	s0,48(sp)
    80002438:	f426                	sd	s1,40(sp)
    8000243a:	f04a                	sd	s2,32(sp)
    8000243c:	ec4e                	sd	s3,24(sp)
    8000243e:	e852                	sd	s4,16(sp)
    80002440:	e456                	sd	s5,8(sp)
    80002442:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	590080e7          	jalr	1424(ra) # 800019d4 <myproc>
    8000244c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	790080e7          	jalr	1936(ra) # 80001bde <allocproc>
    80002456:	1c050063          	beqz	a0,80002616 <fork+0x1e4>
    8000245a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000245c:	048ab603          	ld	a2,72(s5)
    80002460:	692c                	ld	a1,80(a0)
    80002462:	050ab503          	ld	a0,80(s5)
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	124080e7          	jalr	292(ra) # 8000158a <uvmcopy>
    8000246e:	04054863          	bltz	a0,800024be <fork+0x8c>
  np->sz = p->sz;
    80002472:	048ab783          	ld	a5,72(s5)
    80002476:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    8000247a:	058ab683          	ld	a3,88(s5)
    8000247e:	87b6                	mv	a5,a3
    80002480:	0589b703          	ld	a4,88(s3)
    80002484:	12068693          	addi	a3,a3,288 # 10120 <_entry-0x7ffefee0>
    80002488:	0007b803          	ld	a6,0(a5)
    8000248c:	6788                	ld	a0,8(a5)
    8000248e:	6b8c                	ld	a1,16(a5)
    80002490:	6f90                	ld	a2,24(a5)
    80002492:	01073023          	sd	a6,0(a4)
    80002496:	e708                	sd	a0,8(a4)
    80002498:	eb0c                	sd	a1,16(a4)
    8000249a:	ef10                	sd	a2,24(a4)
    8000249c:	02078793          	addi	a5,a5,32
    800024a0:	02070713          	addi	a4,a4,32
    800024a4:	fed792e3          	bne	a5,a3,80002488 <fork+0x56>
  np->trapframe->a0 = 0;
    800024a8:	0589b783          	ld	a5,88(s3)
    800024ac:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800024b0:	0d0a8493          	addi	s1,s5,208
    800024b4:	0d098913          	addi	s2,s3,208
    800024b8:	150a8a13          	addi	s4,s5,336
    800024bc:	a00d                	j	800024de <fork+0xac>
    freeproc(np);
    800024be:	854e                	mv	a0,s3
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	6c6080e7          	jalr	1734(ra) # 80001b86 <freeproc>
    release(&np->lock);
    800024c8:	854e                	mv	a0,s3
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	7ac080e7          	jalr	1964(ra) # 80000c76 <release>
    return -1;
    800024d2:	597d                	li	s2,-1
    800024d4:	a8f9                	j	800025b2 <fork+0x180>
  for(i = 0; i < NOFILE; i++)
    800024d6:	04a1                	addi	s1,s1,8
    800024d8:	0921                	addi	s2,s2,8
    800024da:	01448b63          	beq	s1,s4,800024f0 <fork+0xbe>
    if(p->ofile[i])
    800024de:	6088                	ld	a0,0(s1)
    800024e0:	d97d                	beqz	a0,800024d6 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800024e2:	00003097          	auipc	ra,0x3
    800024e6:	c10080e7          	jalr	-1008(ra) # 800050f2 <filedup>
    800024ea:	00a93023          	sd	a0,0(s2)
    800024ee:	b7e5                	j	800024d6 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800024f0:	150ab503          	ld	a0,336(s5)
    800024f4:	00002097          	auipc	ra,0x2
    800024f8:	a5e080e7          	jalr	-1442(ra) # 80003f52 <idup>
    800024fc:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002500:	4641                	li	a2,16
    80002502:	158a8593          	addi	a1,s5,344
    80002506:	15898513          	addi	a0,s3,344
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	906080e7          	jalr	-1786(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002512:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002516:	854e                	mv	a0,s3
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	75e080e7          	jalr	1886(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80002520:	00010497          	auipc	s1,0x10
    80002524:	d9848493          	addi	s1,s1,-616 # 800122b8 <wait_lock>
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	698080e7          	jalr	1688(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002532:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002536:	8526                	mv	a0,s1
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	73e080e7          	jalr	1854(ra) # 80000c76 <release>
    }
  }
}

int relevant_metadata_proc(struct proc *p) {
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002540:	0309a783          	lw	a5,48(s3)
  if (relevant_metadata_proc(np)) {
    80002544:	37fd                	addiw	a5,a5,-1
    80002546:	4705                	li	a4,1
    80002548:	06f76f63          	bltu	a4,a5,800025c6 <fork+0x194>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    8000254c:	030aa783          	lw	a5,48(s5)
  if (relevant_metadata_proc(p)) {
    80002550:	37fd                	addiw	a5,a5,-1
    80002552:	4705                	li	a4,1
    80002554:	04f77263          	bgeu	a4,a5,80002598 <fork+0x166>
    if (copy_swapFile(p, np) < 0) {
    80002558:	85ce                	mv	a1,s3
    8000255a:	8556                	mv	a0,s5
    8000255c:	00000097          	auipc	ra,0x0
    80002560:	8a4080e7          	jalr	-1884(ra) # 80001e00 <copy_swapFile>
    80002564:	08054d63          	bltz	a0,800025fe <fork+0x1cc>
    memmove(np->ram_pages, p->ram_pages, sizeof(p->ram_pages));
    80002568:	10000613          	li	a2,256
    8000256c:	170a8593          	addi	a1,s5,368
    80002570:	17098513          	addi	a0,s3,368
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	7a6080e7          	jalr	1958(ra) # 80000d1a <memmove>
    memmove(np->disk_pages, p->disk_pages, sizeof(p->disk_pages));
    8000257c:	10000613          	li	a2,256
    80002580:	270a8593          	addi	a1,s5,624
    80002584:	27098513          	addi	a0,s3,624
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	792080e7          	jalr	1938(ra) # 80000d1a <memmove>
    np->scfifo_index = p->scfifo_index; // ADDED Q2
    80002590:	370aa783          	lw	a5,880(s5)
    80002594:	36f9a823          	sw	a5,880(s3)
  acquire(&np->lock);
    80002598:	854e                	mv	a0,s3
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	628080e7          	jalr	1576(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    800025a2:	478d                	li	a5,3
    800025a4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800025a8:	854e                	mv	a0,s3
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	6cc080e7          	jalr	1740(ra) # 80000c76 <release>
}
    800025b2:	854a                	mv	a0,s2
    800025b4:	70e2                	ld	ra,56(sp)
    800025b6:	7442                	ld	s0,48(sp)
    800025b8:	74a2                	ld	s1,40(sp)
    800025ba:	7902                	ld	s2,32(sp)
    800025bc:	69e2                	ld	s3,24(sp)
    800025be:	6a42                	ld	s4,16(sp)
    800025c0:	6aa2                	ld	s5,8(sp)
    800025c2:	6121                	addi	sp,sp,64
    800025c4:	8082                	ret
    if (init_metadata(np) < 0) {
    800025c6:	854e                	mv	a0,s3
    800025c8:	00000097          	auipc	ra,0x0
    800025cc:	d8e080e7          	jalr	-626(ra) # 80002356 <init_metadata>
    800025d0:	02054063          	bltz	a0,800025f0 <fork+0x1be>
    if (fill_swapFile(np) < 0) {
    800025d4:	854e                	mv	a0,s3
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	7cc080e7          	jalr	1996(ra) # 80001da2 <fill_swapFile>
    800025de:	f60557e3          	bgez	a0,8000254c <fork+0x11a>
      freeproc(np);
    800025e2:	854e                	mv	a0,s3
    800025e4:	fffff097          	auipc	ra,0xfffff
    800025e8:	5a2080e7          	jalr	1442(ra) # 80001b86 <freeproc>
      return -1;
    800025ec:	597d                	li	s2,-1
    800025ee:	b7d1                	j	800025b2 <fork+0x180>
      freeproc(np);
    800025f0:	854e                	mv	a0,s3
    800025f2:	fffff097          	auipc	ra,0xfffff
    800025f6:	594080e7          	jalr	1428(ra) # 80001b86 <freeproc>
      return -1;
    800025fa:	597d                	li	s2,-1
    800025fc:	bf5d                	j	800025b2 <fork+0x180>
      freeproc(np);
    800025fe:	854e                	mv	a0,s3
    80002600:	fffff097          	auipc	ra,0xfffff
    80002604:	586080e7          	jalr	1414(ra) # 80001b86 <freeproc>
      free_metadata(np);
    80002608:	854e                	mv	a0,s3
    8000260a:	00000097          	auipc	ra,0x0
    8000260e:	db4080e7          	jalr	-588(ra) # 800023be <free_metadata>
      return -1;
    80002612:	597d                	li	s2,-1
    80002614:	bf79                	j	800025b2 <fork+0x180>
    return -1;
    80002616:	597d                	li	s2,-1
    80002618:	bf69                	j	800025b2 <fork+0x180>

000000008000261a <exit>:
{
    8000261a:	7179                	addi	sp,sp,-48
    8000261c:	f406                	sd	ra,40(sp)
    8000261e:	f022                	sd	s0,32(sp)
    80002620:	ec26                	sd	s1,24(sp)
    80002622:	e84a                	sd	s2,16(sp)
    80002624:	e44e                	sd	s3,8(sp)
    80002626:	e052                	sd	s4,0(sp)
    80002628:	1800                	addi	s0,sp,48
    8000262a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	3a8080e7          	jalr	936(ra) # 800019d4 <myproc>
    80002634:	89aa                	mv	s3,a0
  if(p == initproc)
    80002636:	00008797          	auipc	a5,0x8
    8000263a:	9f27b783          	ld	a5,-1550(a5) # 8000a028 <initproc>
    8000263e:	0d050493          	addi	s1,a0,208
    80002642:	15050913          	addi	s2,a0,336
    80002646:	02a79363          	bne	a5,a0,8000266c <exit+0x52>
    panic("init exiting");
    8000264a:	00007517          	auipc	a0,0x7
    8000264e:	c3e50513          	addi	a0,a0,-962 # 80009288 <digits+0x248>
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	ed8080e7          	jalr	-296(ra) # 8000052a <panic>
      fileclose(f);
    8000265a:	00003097          	auipc	ra,0x3
    8000265e:	aea080e7          	jalr	-1302(ra) # 80005144 <fileclose>
      p->ofile[fd] = 0;
    80002662:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002666:	04a1                	addi	s1,s1,8
    80002668:	01248563          	beq	s1,s2,80002672 <exit+0x58>
    if(p->ofile[fd]){
    8000266c:	6088                	ld	a0,0(s1)
    8000266e:	f575                	bnez	a0,8000265a <exit+0x40>
    80002670:	bfdd                	j	80002666 <exit+0x4c>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002672:	0309a783          	lw	a5,48(s3)
  if (relevant_metadata_proc(p)) {
    80002676:	37fd                	addiw	a5,a5,-1
    80002678:	4705                	li	a4,1
    8000267a:	08f76163          	bltu	a4,a5,800026fc <exit+0xe2>
  begin_op();
    8000267e:	00002097          	auipc	ra,0x2
    80002682:	5fa080e7          	jalr	1530(ra) # 80004c78 <begin_op>
  iput(p->cwd);
    80002686:	1509b503          	ld	a0,336(s3)
    8000268a:	00002097          	auipc	ra,0x2
    8000268e:	ac0080e7          	jalr	-1344(ra) # 8000414a <iput>
  end_op();
    80002692:	00002097          	auipc	ra,0x2
    80002696:	666080e7          	jalr	1638(ra) # 80004cf8 <end_op>
  p->cwd = 0;
    8000269a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000269e:	00010497          	auipc	s1,0x10
    800026a2:	c1a48493          	addi	s1,s1,-998 # 800122b8 <wait_lock>
    800026a6:	8526                	mv	a0,s1
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	51a080e7          	jalr	1306(ra) # 80000bc2 <acquire>
  reparent(p);
    800026b0:	854e                	mv	a0,s3
    800026b2:	00000097          	auipc	ra,0x0
    800026b6:	a7c080e7          	jalr	-1412(ra) # 8000212e <reparent>
  wakeup(p->parent);
    800026ba:	0389b503          	ld	a0,56(s3)
    800026be:	00000097          	auipc	ra,0x0
    800026c2:	9fa080e7          	jalr	-1542(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    800026c6:	854e                	mv	a0,s3
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	4fa080e7          	jalr	1274(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800026d0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026d4:	4795                	li	a5,5
    800026d6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800026da:	8526                	mv	a0,s1
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	59a080e7          	jalr	1434(ra) # 80000c76 <release>
  sched();
    800026e4:	00000097          	auipc	ra,0x0
    800026e8:	85e080e7          	jalr	-1954(ra) # 80001f42 <sched>
  panic("zombie exit");
    800026ec:	00007517          	auipc	a0,0x7
    800026f0:	bac50513          	addi	a0,a0,-1108 # 80009298 <digits+0x258>
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	e36080e7          	jalr	-458(ra) # 8000052a <panic>
    free_metadata(p);
    800026fc:	854e                	mv	a0,s3
    800026fe:	00000097          	auipc	ra,0x0
    80002702:	cc0080e7          	jalr	-832(ra) # 800023be <free_metadata>
    80002706:	bfa5                	j	8000267e <exit+0x64>

0000000080002708 <wait>:
{
    80002708:	715d                	addi	sp,sp,-80
    8000270a:	e486                	sd	ra,72(sp)
    8000270c:	e0a2                	sd	s0,64(sp)
    8000270e:	fc26                	sd	s1,56(sp)
    80002710:	f84a                	sd	s2,48(sp)
    80002712:	f44e                	sd	s3,40(sp)
    80002714:	f052                	sd	s4,32(sp)
    80002716:	ec56                	sd	s5,24(sp)
    80002718:	e85a                	sd	s6,16(sp)
    8000271a:	e45e                	sd	s7,8(sp)
    8000271c:	e062                	sd	s8,0(sp)
    8000271e:	0880                	addi	s0,sp,80
    80002720:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	2b2080e7          	jalr	690(ra) # 800019d4 <myproc>
    8000272a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000272c:	00010517          	auipc	a0,0x10
    80002730:	b8c50513          	addi	a0,a0,-1140 # 800122b8 <wait_lock>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	48e080e7          	jalr	1166(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000273c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000273e:	4a15                	li	s4,5
        havekids = 1;
    80002740:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002742:	0001e997          	auipc	s3,0x1e
    80002746:	d8e98993          	addi	s3,s3,-626 # 800204d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000274a:	00010c17          	auipc	s8,0x10
    8000274e:	b6ec0c13          	addi	s8,s8,-1170 # 800122b8 <wait_lock>
    havekids = 0;
    80002752:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002754:	00010497          	auipc	s1,0x10
    80002758:	f7c48493          	addi	s1,s1,-132 # 800126d0 <proc>
    8000275c:	a059                	j	800027e2 <wait+0xda>
          pid = np->pid;
    8000275e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002762:	000b0e63          	beqz	s6,8000277e <wait+0x76>
    80002766:	4691                	li	a3,4
    80002768:	02c48613          	addi	a2,s1,44
    8000276c:	85da                	mv	a1,s6
    8000276e:	05093503          	ld	a0,80(s2)
    80002772:	fffff097          	auipc	ra,0xfffff
    80002776:	f22080e7          	jalr	-222(ra) # 80001694 <copyout>
    8000277a:	02054b63          	bltz	a0,800027b0 <wait+0xa8>
          freeproc(np);
    8000277e:	8526                	mv	a0,s1
    80002780:	fffff097          	auipc	ra,0xfffff
    80002784:	406080e7          	jalr	1030(ra) # 80001b86 <freeproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002788:	03092783          	lw	a5,48(s2)
         if (relevant_metadata_proc(p)) {
    8000278c:	37fd                	addiw	a5,a5,-1
    8000278e:	4705                	li	a4,1
    80002790:	02f76f63          	bltu	a4,a5,800027ce <wait+0xc6>
          release(&np->lock);
    80002794:	8526                	mv	a0,s1
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	4e0080e7          	jalr	1248(ra) # 80000c76 <release>
          release(&wait_lock);
    8000279e:	00010517          	auipc	a0,0x10
    800027a2:	b1a50513          	addi	a0,a0,-1254 # 800122b8 <wait_lock>
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	4d0080e7          	jalr	1232(ra) # 80000c76 <release>
          return pid;
    800027ae:	a88d                	j	80002820 <wait+0x118>
            release(&np->lock);
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	4c4080e7          	jalr	1220(ra) # 80000c76 <release>
            release(&wait_lock);
    800027ba:	00010517          	auipc	a0,0x10
    800027be:	afe50513          	addi	a0,a0,-1282 # 800122b8 <wait_lock>
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	4b4080e7          	jalr	1204(ra) # 80000c76 <release>
            return -1;
    800027ca:	59fd                	li	s3,-1
    800027cc:	a891                	j	80002820 <wait+0x118>
           free_metadata(np);
    800027ce:	8526                	mv	a0,s1
    800027d0:	00000097          	auipc	ra,0x0
    800027d4:	bee080e7          	jalr	-1042(ra) # 800023be <free_metadata>
    800027d8:	bf75                	j	80002794 <wait+0x8c>
    for(np = proc; np < &proc[NPROC]; np++){
    800027da:	37848493          	addi	s1,s1,888
    800027de:	03348463          	beq	s1,s3,80002806 <wait+0xfe>
      if(np->parent == p){
    800027e2:	7c9c                	ld	a5,56(s1)
    800027e4:	ff279be3          	bne	a5,s2,800027da <wait+0xd2>
        acquire(&np->lock);
    800027e8:	8526                	mv	a0,s1
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	3d8080e7          	jalr	984(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800027f2:	4c9c                	lw	a5,24(s1)
    800027f4:	f74785e3          	beq	a5,s4,8000275e <wait+0x56>
        release(&np->lock);
    800027f8:	8526                	mv	a0,s1
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	47c080e7          	jalr	1148(ra) # 80000c76 <release>
        havekids = 1;
    80002802:	8756                	mv	a4,s5
    80002804:	bfd9                	j	800027da <wait+0xd2>
    if(!havekids || p->killed){
    80002806:	c701                	beqz	a4,8000280e <wait+0x106>
    80002808:	02892783          	lw	a5,40(s2)
    8000280c:	c79d                	beqz	a5,8000283a <wait+0x132>
      release(&wait_lock);
    8000280e:	00010517          	auipc	a0,0x10
    80002812:	aaa50513          	addi	a0,a0,-1366 # 800122b8 <wait_lock>
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	460080e7          	jalr	1120(ra) # 80000c76 <release>
      return -1;
    8000281e:	59fd                	li	s3,-1
}
    80002820:	854e                	mv	a0,s3
    80002822:	60a6                	ld	ra,72(sp)
    80002824:	6406                	ld	s0,64(sp)
    80002826:	74e2                	ld	s1,56(sp)
    80002828:	7942                	ld	s2,48(sp)
    8000282a:	79a2                	ld	s3,40(sp)
    8000282c:	7a02                	ld	s4,32(sp)
    8000282e:	6ae2                	ld	s5,24(sp)
    80002830:	6b42                	ld	s6,16(sp)
    80002832:	6ba2                	ld	s7,8(sp)
    80002834:	6c02                	ld	s8,0(sp)
    80002836:	6161                	addi	sp,sp,80
    80002838:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000283a:	85e2                	mv	a1,s8
    8000283c:	854a                	mv	a0,s2
    8000283e:	00000097          	auipc	ra,0x0
    80002842:	816080e7          	jalr	-2026(ra) # 80002054 <sleep>
    havekids = 0;
    80002846:	b731                	j	80002752 <wait+0x4a>

0000000080002848 <get_free_page_in_disk>:
{
    80002848:	1141                	addi	sp,sp,-16
    8000284a:	e406                	sd	ra,8(sp)
    8000284c:	e022                	sd	s0,0(sp)
    8000284e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002850:	fffff097          	auipc	ra,0xfffff
    80002854:	184080e7          	jalr	388(ra) # 800019d4 <myproc>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    80002858:	27050793          	addi	a5,a0,624
  int i = 0;
    8000285c:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    8000285e:	46c1                	li	a3,16
    if (!disk_pg->used) {
    80002860:	47d8                	lw	a4,12(a5)
    80002862:	c711                	beqz	a4,8000286e <get_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    80002864:	07c1                	addi	a5,a5,16
    80002866:	2505                	addiw	a0,a0,1
    80002868:	fed51ce3          	bne	a0,a3,80002860 <get_free_page_in_disk+0x18>
  return -1;
    8000286c:	557d                	li	a0,-1
}
    8000286e:	60a2                	ld	ra,8(sp)
    80002870:	6402                	ld	s0,0(sp)
    80002872:	0141                	addi	sp,sp,16
    80002874:	8082                	ret

0000000080002876 <swapout>:
{
    80002876:	7139                	addi	sp,sp,-64
    80002878:	fc06                	sd	ra,56(sp)
    8000287a:	f822                	sd	s0,48(sp)
    8000287c:	f426                	sd	s1,40(sp)
    8000287e:	f04a                	sd	s2,32(sp)
    80002880:	ec4e                	sd	s3,24(sp)
    80002882:	e852                	sd	s4,16(sp)
    80002884:	e456                	sd	s5,8(sp)
    80002886:	0080                	addi	s0,sp,64
    80002888:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	14a080e7          	jalr	330(ra) # 800019d4 <myproc>
  if (ram_pg_index < 0 || ram_pg_index >= MAX_PSYC_PAGES) {
    80002892:	0004871b          	sext.w	a4,s1
    80002896:	47bd                	li	a5,15
    80002898:	0ae7e363          	bltu	a5,a4,8000293e <swapout+0xc8>
    8000289c:	8a2a                	mv	s4,a0
  if (!ram_pg_to_swap->used) {
    8000289e:	0492                	slli	s1,s1,0x4
    800028a0:	94aa                	add	s1,s1,a0
    800028a2:	17c4a783          	lw	a5,380(s1)
    800028a6:	c7c5                	beqz	a5,8000294e <swapout+0xd8>
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    800028a8:	4601                	li	a2,0
    800028aa:	1704b583          	ld	a1,368(s1)
    800028ae:	6928                	ld	a0,80(a0)
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	6f6080e7          	jalr	1782(ra) # 80000fa6 <walk>
    800028b8:	89aa                	mv	s3,a0
    800028ba:	c155                	beqz	a0,8000295e <swapout+0xe8>
  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    800028bc:	611c                	ld	a5,0(a0)
    800028be:	2017f793          	andi	a5,a5,513
    800028c2:	4705                	li	a4,1
    800028c4:	0ae79563          	bne	a5,a4,8000296e <swapout+0xf8>
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	f80080e7          	jalr	-128(ra) # 80002848 <get_free_page_in_disk>
    800028d0:	0a054763          	bltz	a0,8000297e <swapout+0x108>
  uint64 pa = PTE2PA(*pte);
    800028d4:	0009ba83          	ld	s5,0(s3)
    800028d8:	00aada93          	srli	s5,s5,0xa
    800028dc:	0ab2                	slli	s5,s5,0xc
    800028de:	00451913          	slli	s2,a0,0x4
    800028e2:	9952                	add	s2,s2,s4
  if (writeToSwapFile(p, (char *)pa, disk_pg_to_store->offset, PGSIZE) < 0) {
    800028e4:	6685                	lui	a3,0x1
    800028e6:	27892603          	lw	a2,632(s2)
    800028ea:	85d6                	mv	a1,s5
    800028ec:	8552                	mv	a0,s4
    800028ee:	00002097          	auipc	ra,0x2
    800028f2:	15c080e7          	jalr	348(ra) # 80004a4a <writeToSwapFile>
    800028f6:	08054c63          	bltz	a0,8000298e <swapout+0x118>
  disk_pg_to_store->used = 1;
    800028fa:	4785                	li	a5,1
    800028fc:	26f92e23          	sw	a5,636(s2)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    80002900:	1704b783          	ld	a5,368(s1)
    80002904:	26f93823          	sd	a5,624(s2)
  kfree((void *)pa);
    80002908:	8556                	mv	a0,s5
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	0cc080e7          	jalr	204(ra) # 800009d6 <kfree>
  ram_pg_to_swap->va = 0;
    80002912:	1604b823          	sd	zero,368(s1)
  ram_pg_to_swap->used = 0;
    80002916:	1604ae23          	sw	zero,380(s1)
  *pte = *pte & ~PTE_V;
    8000291a:	0009b783          	ld	a5,0(s3)
    8000291e:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    80002920:	2007e793          	ori	a5,a5,512
    80002924:	00f9b023          	sd	a5,0(s3)
  asm volatile("sfence.vma zero, zero");
    80002928:	12000073          	sfence.vma
}
    8000292c:	70e2                	ld	ra,56(sp)
    8000292e:	7442                	ld	s0,48(sp)
    80002930:	74a2                	ld	s1,40(sp)
    80002932:	7902                	ld	s2,32(sp)
    80002934:	69e2                	ld	s3,24(sp)
    80002936:	6a42                	ld	s4,16(sp)
    80002938:	6aa2                	ld	s5,8(sp)
    8000293a:	6121                	addi	sp,sp,64
    8000293c:	8082                	ret
    panic("swapout: ram page index out of bounds");
    8000293e:	00007517          	auipc	a0,0x7
    80002942:	96a50513          	addi	a0,a0,-1686 # 800092a8 <digits+0x268>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	be4080e7          	jalr	-1052(ra) # 8000052a <panic>
    panic("swapout: page unused");
    8000294e:	00007517          	auipc	a0,0x7
    80002952:	98250513          	addi	a0,a0,-1662 # 800092d0 <digits+0x290>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	bd4080e7          	jalr	-1068(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    8000295e:	00007517          	auipc	a0,0x7
    80002962:	98a50513          	addi	a0,a0,-1654 # 800092e8 <digits+0x2a8>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	bc4080e7          	jalr	-1084(ra) # 8000052a <panic>
    panic("swapout: page is not in ram");
    8000296e:	00007517          	auipc	a0,0x7
    80002972:	99250513          	addi	a0,a0,-1646 # 80009300 <digits+0x2c0>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	bb4080e7          	jalr	-1100(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    8000297e:	00007517          	auipc	a0,0x7
    80002982:	9a250513          	addi	a0,a0,-1630 # 80009320 <digits+0x2e0>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	ba4080e7          	jalr	-1116(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    8000298e:	00007517          	auipc	a0,0x7
    80002992:	9aa50513          	addi	a0,a0,-1622 # 80009338 <digits+0x2f8>
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	b94080e7          	jalr	-1132(ra) # 8000052a <panic>

000000008000299e <swapin>:
{
    8000299e:	7139                	addi	sp,sp,-64
    800029a0:	fc06                	sd	ra,56(sp)
    800029a2:	f822                	sd	s0,48(sp)
    800029a4:	f426                	sd	s1,40(sp)
    800029a6:	f04a                	sd	s2,32(sp)
    800029a8:	ec4e                	sd	s3,24(sp)
    800029aa:	e852                	sd	s4,16(sp)
    800029ac:	e456                	sd	s5,8(sp)
    800029ae:	0080                	addi	s0,sp,64
  if (disk_index < 0 || disk_index >= MAX_DISK_PAGES) {
    800029b0:	47bd                	li	a5,15
    800029b2:	0aa7ed63          	bltu	a5,a0,80002a6c <swapin+0xce>
    800029b6:	89ae                	mv	s3,a1
    800029b8:	892a                	mv	s2,a0
  if (ram_index < 0 || ram_index >= MAX_PSYC_PAGES) {
    800029ba:	0005879b          	sext.w	a5,a1
    800029be:	473d                	li	a4,15
    800029c0:	0af76e63          	bltu	a4,a5,80002a7c <swapin+0xde>
  struct proc *p = myproc();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	010080e7          	jalr	16(ra) # 800019d4 <myproc>
    800029cc:	8aaa                	mv	s5,a0
  if (!disk_pg->used) {
    800029ce:	0912                	slli	s2,s2,0x4
    800029d0:	992a                	add	s2,s2,a0
    800029d2:	27c92783          	lw	a5,636(s2)
    800029d6:	cbdd                	beqz	a5,80002a8c <swapin+0xee>
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    800029d8:	4601                	li	a2,0
    800029da:	27093583          	ld	a1,624(s2)
    800029de:	6928                	ld	a0,80(a0)
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	5c6080e7          	jalr	1478(ra) # 80000fa6 <walk>
    800029e8:	8a2a                	mv	s4,a0
    800029ea:	c94d                	beqz	a0,80002a9c <swapin+0xfe>
  if ((*pte & PTE_V) || !(*pte & PTE_PG))
    800029ec:	611c                	ld	a5,0(a0)
    800029ee:	2017f793          	andi	a5,a5,513
    800029f2:	20000713          	li	a4,512
    800029f6:	0ae79b63          	bne	a5,a4,80002aac <swapin+0x10e>
  if (ram_pg->used) {
    800029fa:	0992                	slli	s3,s3,0x4
    800029fc:	99d6                	add	s3,s3,s5
    800029fe:	17c9a783          	lw	a5,380(s3)
    80002a02:	efcd                	bnez	a5,80002abc <swapin+0x11e>
  if ( (npa = (uint64)kalloc()) == 0 ) {
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	0ce080e7          	jalr	206(ra) # 80000ad2 <kalloc>
    80002a0c:	84aa                	mv	s1,a0
    80002a0e:	cd5d                	beqz	a0,80002acc <swapin+0x12e>
  if (readFromSwapFile(p, (char *)npa, disk_pg->offset, PGSIZE) < 0) {
    80002a10:	6685                	lui	a3,0x1
    80002a12:	27892603          	lw	a2,632(s2)
    80002a16:	85aa                	mv	a1,a0
    80002a18:	8556                	mv	a0,s5
    80002a1a:	00002097          	auipc	ra,0x2
    80002a1e:	054080e7          	jalr	84(ra) # 80004a6e <readFromSwapFile>
    80002a22:	0a054d63          	bltz	a0,80002adc <swapin+0x13e>
  ram_pg->used = 1;
    80002a26:	4785                	li	a5,1
    80002a28:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    80002a2c:	27093783          	ld	a5,624(s2)
    80002a30:	16f9b823          	sd	a5,368(s3)
    ram_pg->age = 0;
    80002a34:	1609ac23          	sw	zero,376(s3)
  disk_pg->va = 0;
    80002a38:	26093823          	sd	zero,624(s2)
  disk_pg->used = 0;
    80002a3c:	26092e23          	sw	zero,636(s2)
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    80002a40:	80b1                	srli	s1,s1,0xc
    80002a42:	04aa                	slli	s1,s1,0xa
    80002a44:	000a3783          	ld	a5,0(s4)
    80002a48:	1ff7f793          	andi	a5,a5,511
    80002a4c:	8cdd                	or	s1,s1,a5
    80002a4e:	0014e493          	ori	s1,s1,1
    80002a52:	009a3023          	sd	s1,0(s4)
    80002a56:	12000073          	sfence.vma
}
    80002a5a:	70e2                	ld	ra,56(sp)
    80002a5c:	7442                	ld	s0,48(sp)
    80002a5e:	74a2                	ld	s1,40(sp)
    80002a60:	7902                	ld	s2,32(sp)
    80002a62:	69e2                	ld	s3,24(sp)
    80002a64:	6a42                	ld	s4,16(sp)
    80002a66:	6aa2                	ld	s5,8(sp)
    80002a68:	6121                	addi	sp,sp,64
    80002a6a:	8082                	ret
    panic("swapin: disk index out of bounds");
    80002a6c:	00007517          	auipc	a0,0x7
    80002a70:	8f450513          	addi	a0,a0,-1804 # 80009360 <digits+0x320>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	ab6080e7          	jalr	-1354(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    80002a7c:	00007517          	auipc	a0,0x7
    80002a80:	90c50513          	addi	a0,a0,-1780 # 80009388 <digits+0x348>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	aa6080e7          	jalr	-1370(ra) # 8000052a <panic>
    panic("swapin: page unused");
    80002a8c:	00007517          	auipc	a0,0x7
    80002a90:	91c50513          	addi	a0,a0,-1764 # 800093a8 <digits+0x368>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	a96080e7          	jalr	-1386(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    80002a9c:	00007517          	auipc	a0,0x7
    80002aa0:	92450513          	addi	a0,a0,-1756 # 800093c0 <digits+0x380>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	a86080e7          	jalr	-1402(ra) # 8000052a <panic>
      panic("swapin: page is not in disk");
    80002aac:	00007517          	auipc	a0,0x7
    80002ab0:	92c50513          	addi	a0,a0,-1748 # 800093d8 <digits+0x398>
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	a76080e7          	jalr	-1418(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    80002abc:	00007517          	auipc	a0,0x7
    80002ac0:	93c50513          	addi	a0,a0,-1732 # 800093f8 <digits+0x3b8>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	a66080e7          	jalr	-1434(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    80002acc:	00007517          	auipc	a0,0x7
    80002ad0:	94450513          	addi	a0,a0,-1724 # 80009410 <digits+0x3d0>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	a56080e7          	jalr	-1450(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002adc:	00007517          	auipc	a0,0x7
    80002ae0:	95c50513          	addi	a0,a0,-1700 # 80009438 <digits+0x3f8>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	a46080e7          	jalr	-1466(ra) # 8000052a <panic>

0000000080002aec <get_unused_ram_index>:
{
    80002aec:	1141                	addi	sp,sp,-16
    80002aee:	e422                	sd	s0,8(sp)
    80002af0:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002af2:	17c50793          	addi	a5,a0,380
    80002af6:	4501                	li	a0,0
    80002af8:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    80002afa:	4398                	lw	a4,0(a5)
    80002afc:	c711                	beqz	a4,80002b08 <get_unused_ram_index+0x1c>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002afe:	2505                	addiw	a0,a0,1
    80002b00:	07c1                	addi	a5,a5,16
    80002b02:	fed51ce3          	bne	a0,a3,80002afa <get_unused_ram_index+0xe>
  return -1;
    80002b06:	557d                	li	a0,-1
}
    80002b08:	6422                	ld	s0,8(sp)
    80002b0a:	0141                	addi	sp,sp,16
    80002b0c:	8082                	ret

0000000080002b0e <get_disk_page_index>:
{
    80002b0e:	1141                	addi	sp,sp,-16
    80002b10:	e422                	sd	s0,8(sp)
    80002b12:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002b14:	27050793          	addi	a5,a0,624
    80002b18:	4501                	li	a0,0
    80002b1a:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    80002b1c:	6398                	ld	a4,0(a5)
    80002b1e:	00b70763          	beq	a4,a1,80002b2c <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002b22:	2505                	addiw	a0,a0,1
    80002b24:	07c1                	addi	a5,a5,16
    80002b26:	fed51be3          	bne	a0,a3,80002b1c <get_disk_page_index+0xe>
  return -1;
    80002b2a:	557d                	li	a0,-1
}
    80002b2c:	6422                	ld	s0,8(sp)
    80002b2e:	0141                	addi	sp,sp,16
    80002b30:	8082                	ret

0000000080002b32 <remove_page_from_ram>:
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	e426                	sd	s1,8(sp)
    80002b3a:	1000                	addi	s0,sp,32
    80002b3c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	e96080e7          	jalr	-362(ra) # 800019d4 <myproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002b46:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002b48:	37fd                	addiw	a5,a5,-1
    80002b4a:	4705                	li	a4,1
    80002b4c:	02f77863          	bgeu	a4,a5,80002b7c <remove_page_from_ram+0x4a>
    80002b50:	17050793          	addi	a5,a0,368
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002b54:	4701                	li	a4,0
    80002b56:	4641                	li	a2,16
    80002b58:	a029                	j	80002b62 <remove_page_from_ram+0x30>
    80002b5a:	2705                	addiw	a4,a4,1
    80002b5c:	07c1                	addi	a5,a5,16
    80002b5e:	02c70463          	beq	a4,a2,80002b86 <remove_page_from_ram+0x54>
    if (p->ram_pages[i].va == va && p->ram_pages[i].used) {
    80002b62:	6394                	ld	a3,0(a5)
    80002b64:	fe969be3          	bne	a3,s1,80002b5a <remove_page_from_ram+0x28>
    80002b68:	47d4                	lw	a3,12(a5)
    80002b6a:	dae5                	beqz	a3,80002b5a <remove_page_from_ram+0x28>
      p->ram_pages[i].va = 0;
    80002b6c:	0712                	slli	a4,a4,0x4
    80002b6e:	972a                	add	a4,a4,a0
    80002b70:	16073823          	sd	zero,368(a4)
      p->ram_pages[i].used = 0;
    80002b74:	16072e23          	sw	zero,380(a4)
      p->ram_pages[i].age = 0; // ADDED Q2
    80002b78:	16072c23          	sw	zero,376(a4)
}
    80002b7c:	60e2                	ld	ra,24(sp)
    80002b7e:	6442                	ld	s0,16(sp)
    80002b80:	64a2                	ld	s1,8(sp)
    80002b82:	6105                	addi	sp,sp,32
    80002b84:	8082                	ret
  panic("remove_page_from_ram failed");
    80002b86:	00007517          	auipc	a0,0x7
    80002b8a:	8d250513          	addi	a0,a0,-1838 # 80009458 <digits+0x418>
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	99c080e7          	jalr	-1636(ra) # 8000052a <panic>

0000000080002b96 <nfua>:
{
    80002b96:	1141                	addi	sp,sp,-16
    80002b98:	e406                	sd	ra,8(sp)
    80002b9a:	e022                	sd	s0,0(sp)
    80002b9c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	e36080e7          	jalr	-458(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002ba6:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002baa:	567d                	li	a2,-1
  int min_index = 0;
    80002bac:	4501                	li	a0,0
  int i = 0;
    80002bae:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bb0:	45c1                	li	a1,16
    80002bb2:	a029                	j	80002bbc <nfua+0x26>
    80002bb4:	0741                	addi	a4,a4,16
    80002bb6:	2785                	addiw	a5,a5,1
    80002bb8:	00b78863          	beq	a5,a1,80002bc8 <nfua+0x32>
    if(ram_pg->age <= min_age){
    80002bbc:	4714                	lw	a3,8(a4)
    80002bbe:	fed66be3          	bltu	a2,a3,80002bb4 <nfua+0x1e>
      min_age = ram_pg->age;
    80002bc2:	8636                	mv	a2,a3
    if(ram_pg->age <= min_age){
    80002bc4:	853e                	mv	a0,a5
    80002bc6:	b7fd                	j	80002bb4 <nfua+0x1e>
}
    80002bc8:	60a2                	ld	ra,8(sp)
    80002bca:	6402                	ld	s0,0(sp)
    80002bcc:	0141                	addi	sp,sp,16
    80002bce:	8082                	ret

0000000080002bd0 <count_ones>:
{
    80002bd0:	1141                	addi	sp,sp,-16
    80002bd2:	e422                	sd	s0,8(sp)
    80002bd4:	0800                	addi	s0,sp,16
  while(num > 0){
    80002bd6:	c105                	beqz	a0,80002bf6 <count_ones+0x26>
    80002bd8:	87aa                	mv	a5,a0
  int count = 0;
    80002bda:	4501                	li	a0,0
  while(num > 0){
    80002bdc:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002bde:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002be2:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002be4:	0007871b          	sext.w	a4,a5
    80002be8:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002bec:	fee6e9e3          	bltu	a3,a4,80002bde <count_ones+0xe>
}
    80002bf0:	6422                	ld	s0,8(sp)
    80002bf2:	0141                	addi	sp,sp,16
    80002bf4:	8082                	ret
  int count = 0;
    80002bf6:	4501                	li	a0,0
    80002bf8:	bfe5                	j	80002bf0 <count_ones+0x20>

0000000080002bfa <lapa>:
{
    80002bfa:	715d                	addi	sp,sp,-80
    80002bfc:	e486                	sd	ra,72(sp)
    80002bfe:	e0a2                	sd	s0,64(sp)
    80002c00:	fc26                	sd	s1,56(sp)
    80002c02:	f84a                	sd	s2,48(sp)
    80002c04:	f44e                	sd	s3,40(sp)
    80002c06:	f052                	sd	s4,32(sp)
    80002c08:	ec56                	sd	s5,24(sp)
    80002c0a:	e85a                	sd	s6,16(sp)
    80002c0c:	e45e                	sd	s7,8(sp)
    80002c0e:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	dc4080e7          	jalr	-572(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c18:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002c1c:	5afd                	li	s5,-1
  int min_index = 0;
    80002c1e:	4b81                	li	s7,0
  int i = 0;
    80002c20:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c22:	4b41                	li	s6,16
    80002c24:	a039                	j	80002c32 <lapa+0x38>
      min_age = ram_pg->age;
    80002c26:	8ad2                	mv	s5,s4
    80002c28:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c2a:	09c1                	addi	s3,s3,16
    80002c2c:	2905                	addiw	s2,s2,1
    80002c2e:	03690863          	beq	s2,s6,80002c5e <lapa+0x64>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002c32:	0089aa03          	lw	s4,8(s3)
    80002c36:	8552                	mv	a0,s4
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	f98080e7          	jalr	-104(ra) # 80002bd0 <count_ones>
    80002c40:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002c42:	8556                	mv	a0,s5
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	f8c080e7          	jalr	-116(ra) # 80002bd0 <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002c4c:	fca4cde3          	blt	s1,a0,80002c26 <lapa+0x2c>
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c50:	fca49de3          	bne	s1,a0,80002c2a <lapa+0x30>
    80002c54:	fd5a7be3          	bgeu	s4,s5,80002c2a <lapa+0x30>
      min_age = ram_pg->age;
    80002c58:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c5a:	8bca                	mv	s7,s2
    80002c5c:	b7f9                	j	80002c2a <lapa+0x30>
}
    80002c5e:	855e                	mv	a0,s7
    80002c60:	60a6                	ld	ra,72(sp)
    80002c62:	6406                	ld	s0,64(sp)
    80002c64:	74e2                	ld	s1,56(sp)
    80002c66:	7942                	ld	s2,48(sp)
    80002c68:	79a2                	ld	s3,40(sp)
    80002c6a:	7a02                	ld	s4,32(sp)
    80002c6c:	6ae2                	ld	s5,24(sp)
    80002c6e:	6b42                	ld	s6,16(sp)
    80002c70:	6ba2                	ld	s7,8(sp)
    80002c72:	6161                	addi	sp,sp,80
    80002c74:	8082                	ret

0000000080002c76 <scfifo>:
{
    80002c76:	1101                	addi	sp,sp,-32
    80002c78:	ec06                	sd	ra,24(sp)
    80002c7a:	e822                	sd	s0,16(sp)
    80002c7c:	e426                	sd	s1,8(sp)
    80002c7e:	e04a                	sd	s2,0(sp)
    80002c80:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	d52080e7          	jalr	-686(ra) # 800019d4 <myproc>
    80002c8a:	892a                	mv	s2,a0
  int index = p->scfifo_index;
    80002c8c:	37052483          	lw	s1,880(a0)
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
    80002c90:	01748793          	addi	a5,s1,23
    80002c94:	0792                	slli	a5,a5,0x4
    80002c96:	97ca                	add	a5,a5,s2
    80002c98:	4601                	li	a2,0
    80002c9a:	638c                	ld	a1,0(a5)
    80002c9c:	05093503          	ld	a0,80(s2)
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	306080e7          	jalr	774(ra) # 80000fa6 <walk>
    80002ca8:	c10d                	beqz	a0,80002cca <scfifo+0x54>
    if(*pte & PTE_A){
    80002caa:	611c                	ld	a5,0(a0)
    80002cac:	0407f713          	andi	a4,a5,64
    80002cb0:	c70d                	beqz	a4,80002cda <scfifo+0x64>
      *pte = *pte & ~PTE_A;
    80002cb2:	fbf7f793          	andi	a5,a5,-65
    80002cb6:	e11c                	sd	a5,0(a0)
      index = (index + 1) % MAX_PSYC_PAGES;
    80002cb8:	2485                	addiw	s1,s1,1
    80002cba:	41f4d79b          	sraiw	a5,s1,0x1f
    80002cbe:	01c7d79b          	srliw	a5,a5,0x1c
    80002cc2:	9cbd                	addw	s1,s1,a5
    80002cc4:	88bd                	andi	s1,s1,15
    80002cc6:	9c9d                	subw	s1,s1,a5
  while(1){
    80002cc8:	b7e1                	j	80002c90 <scfifo+0x1a>
      panic("scfifo: walk failed");
    80002cca:	00006517          	auipc	a0,0x6
    80002cce:	7ae50513          	addi	a0,a0,1966 # 80009478 <digits+0x438>
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	858080e7          	jalr	-1960(ra) # 8000052a <panic>
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
    80002cda:	0014879b          	addiw	a5,s1,1
    80002cde:	41f7d71b          	sraiw	a4,a5,0x1f
    80002ce2:	01c7571b          	srliw	a4,a4,0x1c
    80002ce6:	9fb9                	addw	a5,a5,a4
    80002ce8:	8bbd                	andi	a5,a5,15
    80002cea:	9f99                	subw	a5,a5,a4
    80002cec:	36f92823          	sw	a5,880(s2)
}
    80002cf0:	8526                	mv	a0,s1
    80002cf2:	60e2                	ld	ra,24(sp)
    80002cf4:	6442                	ld	s0,16(sp)
    80002cf6:	64a2                	ld	s1,8(sp)
    80002cf8:	6902                	ld	s2,0(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret

0000000080002cfe <insert_page_to_ram>:
{
    80002cfe:	7179                	addi	sp,sp,-48
    80002d00:	f406                	sd	ra,40(sp)
    80002d02:	f022                	sd	s0,32(sp)
    80002d04:	ec26                	sd	s1,24(sp)
    80002d06:	e84a                	sd	s2,16(sp)
    80002d08:	e44e                	sd	s3,8(sp)
    80002d0a:	1800                	addi	s0,sp,48
    80002d0c:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	cc6080e7          	jalr	-826(ra) # 800019d4 <myproc>
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002d16:	591c                	lw	a5,48(a0)
  if (!relevant_metadata_proc(p)) {
    80002d18:	37fd                	addiw	a5,a5,-1
    80002d1a:	4705                	li	a4,1
    80002d1c:	02f77363          	bgeu	a4,a5,80002d42 <insert_page_to_ram+0x44>
    80002d20:	84aa                	mv	s1,a0
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0)
    80002d22:	00000097          	auipc	ra,0x0
    80002d26:	dca080e7          	jalr	-566(ra) # 80002aec <get_unused_ram_index>
    80002d2a:	892a                	mv	s2,a0
    80002d2c:	02054263          	bltz	a0,80002d50 <insert_page_to_ram+0x52>
  ram_pg->va = va;
    80002d30:	0912                	slli	s2,s2,0x4
    80002d32:	94ca                	add	s1,s1,s2
    80002d34:	1734b823          	sd	s3,368(s1)
  ram_pg->used = 1;
    80002d38:	4785                	li	a5,1
    80002d3a:	16f4ae23          	sw	a5,380(s1)
    ram_pg->age = 0;
    80002d3e:	1604ac23          	sw	zero,376(s1)
}
    80002d42:	70a2                	ld	ra,40(sp)
    80002d44:	7402                	ld	s0,32(sp)
    80002d46:	64e2                	ld	s1,24(sp)
    80002d48:	6942                	ld	s2,16(sp)
    80002d4a:	69a2                	ld	s3,8(sp)
    80002d4c:	6145                	addi	sp,sp,48
    80002d4e:	8082                	ret
    return scfifo();
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	f26080e7          	jalr	-218(ra) # 80002c76 <scfifo>
    80002d58:	892a                	mv	s2,a0
    swapout(ram_pg_index_to_swap);
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	b1c080e7          	jalr	-1252(ra) # 80002876 <swapout>
    unused_ram_pg_index = ram_pg_index_to_swap;
    80002d62:	b7f9                	j	80002d30 <insert_page_to_ram+0x32>

0000000080002d64 <handle_page_fault>:
{
    80002d64:	7179                	addi	sp,sp,-48
    80002d66:	f406                	sd	ra,40(sp)
    80002d68:	f022                	sd	s0,32(sp)
    80002d6a:	ec26                	sd	s1,24(sp)
    80002d6c:	e84a                	sd	s2,16(sp)
    80002d6e:	e44e                	sd	s3,8(sp)
    80002d70:	1800                	addi	s0,sp,48
    80002d72:	89aa                	mv	s3,a0
  printf("@@@@@\n");
    80002d74:	00006517          	auipc	a0,0x6
    80002d78:	71c50513          	addi	a0,a0,1820 # 80009490 <digits+0x450>
    80002d7c:	ffffd097          	auipc	ra,0xffffd
    80002d80:	7f8080e7          	jalr	2040(ra) # 80000574 <printf>
  struct proc *p = myproc();
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	c50080e7          	jalr	-944(ra) # 800019d4 <myproc>
    80002d8c:	892a                	mv	s2,a0
  if (!(pte = walk(p->pagetable, va, 0))) {
    80002d8e:	4601                	li	a2,0
    80002d90:	85ce                	mv	a1,s3
    80002d92:	6928                	ld	a0,80(a0)
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	212080e7          	jalr	530(ra) # 80000fa6 <walk>
    80002d9c:	c531                	beqz	a0,80002de8 <handle_page_fault+0x84>
  if(*pte & PTE_V){
    80002d9e:	611c                	ld	a5,0(a0)
    80002da0:	0017f713          	andi	a4,a5,1
    80002da4:	eb31                	bnez	a4,80002df8 <handle_page_fault+0x94>
  if(!(*pte & PTE_PG)) { //TODO why?
    80002da6:	2007f793          	andi	a5,a5,512
    80002daa:	cfb9                	beqz	a5,80002e08 <handle_page_fault+0xa4>
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
    80002dac:	854a                	mv	a0,s2
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	d3e080e7          	jalr	-706(ra) # 80002aec <get_unused_ram_index>
    80002db6:	84aa                	mv	s1,a0
    80002db8:	06054063          	bltz	a0,80002e18 <handle_page_fault+0xb4>
  if( (target_idx = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002dbc:	75fd                	lui	a1,0xfffff
    80002dbe:	00b9f5b3          	and	a1,s3,a1
    80002dc2:	854a                	mv	a0,s2
    80002dc4:	00000097          	auipc	ra,0x0
    80002dc8:	d4a080e7          	jalr	-694(ra) # 80002b0e <get_disk_page_index>
    80002dcc:	06054963          	bltz	a0,80002e3e <handle_page_fault+0xda>
  swapin(target_idx, unused_ram_pg_index);
    80002dd0:	85a6                	mv	a1,s1
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	bcc080e7          	jalr	-1076(ra) # 8000299e <swapin>
}
    80002dda:	70a2                	ld	ra,40(sp)
    80002ddc:	7402                	ld	s0,32(sp)
    80002dde:	64e2                	ld	s1,24(sp)
    80002de0:	6942                	ld	s2,16(sp)
    80002de2:	69a2                	ld	s3,8(sp)
    80002de4:	6145                	addi	sp,sp,48
    80002de6:	8082                	ret
    panic("handle_page_fault: walk failed");
    80002de8:	00006517          	auipc	a0,0x6
    80002dec:	6b050513          	addi	a0,a0,1712 # 80009498 <digits+0x458>
    80002df0:	ffffd097          	auipc	ra,0xffffd
    80002df4:	73a080e7          	jalr	1850(ra) # 8000052a <panic>
    panic("handle_page_fault: invalid pte");
    80002df8:	00006517          	auipc	a0,0x6
    80002dfc:	6c050513          	addi	a0,a0,1728 # 800094b8 <digits+0x478>
    80002e00:	ffffd097          	auipc	ra,0xffffd
    80002e04:	72a080e7          	jalr	1834(ra) # 8000052a <panic>
    panic("handle_page_fault: PTE_PG off");
    80002e08:	00006517          	auipc	a0,0x6
    80002e0c:	6d050513          	addi	a0,a0,1744 # 800094d8 <digits+0x498>
    80002e10:	ffffd097          	auipc	ra,0xffffd
    80002e14:	71a080e7          	jalr	1818(ra) # 8000052a <panic>
    return scfifo();
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	e5e080e7          	jalr	-418(ra) # 80002c76 <scfifo>
    80002e20:	84aa                	mv	s1,a0
      swapout(ram_pg_index_to_swap); 
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	a54080e7          	jalr	-1452(ra) # 80002876 <swapout>
      printf("handle_page_fault: replace index %d\n", unused_ram_pg_index); // ADDED Q3
    80002e2a:	85a6                	mv	a1,s1
    80002e2c:	00006517          	auipc	a0,0x6
    80002e30:	6cc50513          	addi	a0,a0,1740 # 800094f8 <digits+0x4b8>
    80002e34:	ffffd097          	auipc	ra,0xffffd
    80002e38:	740080e7          	jalr	1856(ra) # 80000574 <printf>
    80002e3c:	b741                	j	80002dbc <handle_page_fault+0x58>
    panic("handle_page_fault: get_disk_page_index failed");
    80002e3e:	00006517          	auipc	a0,0x6
    80002e42:	6e250513          	addi	a0,a0,1762 # 80009520 <digits+0x4e0>
    80002e46:	ffffd097          	auipc	ra,0xffffd
    80002e4a:	6e4080e7          	jalr	1764(ra) # 8000052a <panic>

0000000080002e4e <index_page_to_swap>:
{
    80002e4e:	1141                	addi	sp,sp,-16
    80002e50:	e406                	sd	ra,8(sp)
    80002e52:	e022                	sd	s0,0(sp)
    80002e54:	0800                	addi	s0,sp,16
    return scfifo();
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	e20080e7          	jalr	-480(ra) # 80002c76 <scfifo>
}
    80002e5e:	60a2                	ld	ra,8(sp)
    80002e60:	6402                	ld	s0,0(sp)
    80002e62:	0141                	addi	sp,sp,16
    80002e64:	8082                	ret

0000000080002e66 <maintain_age>:
void maintain_age(struct proc *p){
    80002e66:	7179                	addi	sp,sp,-48
    80002e68:	f406                	sd	ra,40(sp)
    80002e6a:	f022                	sd	s0,32(sp)
    80002e6c:	ec26                	sd	s1,24(sp)
    80002e6e:	e84a                	sd	s2,16(sp)
    80002e70:	e44e                	sd	s3,8(sp)
    80002e72:	e052                	sd	s4,0(sp)
    80002e74:	1800                	addi	s0,sp,48
    80002e76:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002e78:	17050493          	addi	s1,a0,368
    80002e7c:	27050993          	addi	s3,a0,624
      ram_pg->age = ram_pg->age | (1 << 31);
    80002e80:	80000a37          	lui	s4,0x80000
    80002e84:	a821                	j	80002e9c <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002e86:	00006517          	auipc	a0,0x6
    80002e8a:	6ca50513          	addi	a0,a0,1738 # 80009550 <digits+0x510>
    80002e8e:	ffffd097          	auipc	ra,0xffffd
    80002e92:	69c080e7          	jalr	1692(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002e96:	04c1                	addi	s1,s1,16
    80002e98:	02998b63          	beq	s3,s1,80002ece <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002e9c:	4601                	li	a2,0
    80002e9e:	608c                	ld	a1,0(s1)
    80002ea0:	05093503          	ld	a0,80(s2)
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	102080e7          	jalr	258(ra) # 80000fa6 <walk>
    80002eac:	dd69                	beqz	a0,80002e86 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002eae:	449c                	lw	a5,8(s1)
    80002eb0:	0017d79b          	srliw	a5,a5,0x1
    80002eb4:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002eb6:	6118                	ld	a4,0(a0)
    80002eb8:	04077713          	andi	a4,a4,64
    80002ebc:	df69                	beqz	a4,80002e96 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002ebe:	0147e7b3          	or	a5,a5,s4
    80002ec2:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002ec4:	611c                	ld	a5,0(a0)
    80002ec6:	fbf7f793          	andi	a5,a5,-65
    80002eca:	e11c                	sd	a5,0(a0)
    80002ecc:	b7e9                	j	80002e96 <maintain_age+0x30>
}
    80002ece:	70a2                	ld	ra,40(sp)
    80002ed0:	7402                	ld	s0,32(sp)
    80002ed2:	64e2                	ld	s1,24(sp)
    80002ed4:	6942                	ld	s2,16(sp)
    80002ed6:	69a2                	ld	s3,8(sp)
    80002ed8:	6a02                	ld	s4,0(sp)
    80002eda:	6145                	addi	sp,sp,48
    80002edc:	8082                	ret

0000000080002ede <relevant_metadata_proc>:
int relevant_metadata_proc(struct proc *p) {
    80002ede:	1141                	addi	sp,sp,-16
    80002ee0:	e422                	sd	s0,8(sp)
    80002ee2:	0800                	addi	s0,sp,16
  return p->pid != INIT_PID && p->pid != SHELL_PID;
    80002ee4:	591c                	lw	a5,48(a0)
    80002ee6:	37fd                	addiw	a5,a5,-1
    80002ee8:	4505                	li	a0,1
    80002eea:	00f53533          	sltu	a0,a0,a5
    80002eee:	6422                	ld	s0,8(sp)
    80002ef0:	0141                	addi	sp,sp,16
    80002ef2:	8082                	ret

0000000080002ef4 <swtch>:
    80002ef4:	00153023          	sd	ra,0(a0)
    80002ef8:	00253423          	sd	sp,8(a0)
    80002efc:	e900                	sd	s0,16(a0)
    80002efe:	ed04                	sd	s1,24(a0)
    80002f00:	03253023          	sd	s2,32(a0)
    80002f04:	03353423          	sd	s3,40(a0)
    80002f08:	03453823          	sd	s4,48(a0)
    80002f0c:	03553c23          	sd	s5,56(a0)
    80002f10:	05653023          	sd	s6,64(a0)
    80002f14:	05753423          	sd	s7,72(a0)
    80002f18:	05853823          	sd	s8,80(a0)
    80002f1c:	05953c23          	sd	s9,88(a0)
    80002f20:	07a53023          	sd	s10,96(a0)
    80002f24:	07b53423          	sd	s11,104(a0)
    80002f28:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80002f2c:	0085b103          	ld	sp,8(a1)
    80002f30:	6980                	ld	s0,16(a1)
    80002f32:	6d84                	ld	s1,24(a1)
    80002f34:	0205b903          	ld	s2,32(a1)
    80002f38:	0285b983          	ld	s3,40(a1)
    80002f3c:	0305ba03          	ld	s4,48(a1)
    80002f40:	0385ba83          	ld	s5,56(a1)
    80002f44:	0405bb03          	ld	s6,64(a1)
    80002f48:	0485bb83          	ld	s7,72(a1)
    80002f4c:	0505bc03          	ld	s8,80(a1)
    80002f50:	0585bc83          	ld	s9,88(a1)
    80002f54:	0605bd03          	ld	s10,96(a1)
    80002f58:	0685bd83          	ld	s11,104(a1)
    80002f5c:	8082                	ret

0000000080002f5e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f5e:	1141                	addi	sp,sp,-16
    80002f60:	e406                	sd	ra,8(sp)
    80002f62:	e022                	sd	s0,0(sp)
    80002f64:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f66:	00006597          	auipc	a1,0x6
    80002f6a:	66258593          	addi	a1,a1,1634 # 800095c8 <states.0+0x30>
    80002f6e:	0001d517          	auipc	a0,0x1d
    80002f72:	56250513          	addi	a0,a0,1378 # 800204d0 <tickslock>
    80002f76:	ffffe097          	auipc	ra,0xffffe
    80002f7a:	bbc080e7          	jalr	-1092(ra) # 80000b32 <initlock>
}
    80002f7e:	60a2                	ld	ra,8(sp)
    80002f80:	6402                	ld	s0,0(sp)
    80002f82:	0141                	addi	sp,sp,16
    80002f84:	8082                	ret

0000000080002f86 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002f86:	1141                	addi	sp,sp,-16
    80002f88:	e422                	sd	s0,8(sp)
    80002f8a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f8c:	00004797          	auipc	a5,0x4
    80002f90:	ac478793          	addi	a5,a5,-1340 # 80006a50 <kernelvec>
    80002f94:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f98:	6422                	ld	s0,8(sp)
    80002f9a:	0141                	addi	sp,sp,16
    80002f9c:	8082                	ret

0000000080002f9e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f9e:	1141                	addi	sp,sp,-16
    80002fa0:	e406                	sd	ra,8(sp)
    80002fa2:	e022                	sd	s0,0(sp)
    80002fa4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	a2e080e7          	jalr	-1490(ra) # 800019d4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fb2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fb4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002fb8:	00005617          	auipc	a2,0x5
    80002fbc:	04860613          	addi	a2,a2,72 # 80008000 <_trampoline>
    80002fc0:	00005697          	auipc	a3,0x5
    80002fc4:	04068693          	addi	a3,a3,64 # 80008000 <_trampoline>
    80002fc8:	8e91                	sub	a3,a3,a2
    80002fca:	040007b7          	lui	a5,0x4000
    80002fce:	17fd                	addi	a5,a5,-1
    80002fd0:	07b2                	slli	a5,a5,0xc
    80002fd2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fd4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002fd8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002fda:	180026f3          	csrr	a3,satp
    80002fde:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002fe0:	6d38                	ld	a4,88(a0)
    80002fe2:	6134                	ld	a3,64(a0)
    80002fe4:	6585                	lui	a1,0x1
    80002fe6:	96ae                	add	a3,a3,a1
    80002fe8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002fea:	6d38                	ld	a4,88(a0)
    80002fec:	00000697          	auipc	a3,0x0
    80002ff0:	13868693          	addi	a3,a3,312 # 80003124 <usertrap>
    80002ff4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ff6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ff8:	8692                	mv	a3,tp
    80002ffa:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ffc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003000:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003004:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003008:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000300c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000300e:	6f18                	ld	a4,24(a4)
    80003010:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003014:	692c                	ld	a1,80(a0)
    80003016:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003018:	00005717          	auipc	a4,0x5
    8000301c:	07870713          	addi	a4,a4,120 # 80008090 <userret>
    80003020:	8f11                	sub	a4,a4,a2
    80003022:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003024:	577d                	li	a4,-1
    80003026:	177e                	slli	a4,a4,0x3f
    80003028:	8dd9                	or	a1,a1,a4
    8000302a:	02000537          	lui	a0,0x2000
    8000302e:	157d                	addi	a0,a0,-1
    80003030:	0536                	slli	a0,a0,0xd
    80003032:	9782                	jalr	a5
}
    80003034:	60a2                	ld	ra,8(sp)
    80003036:	6402                	ld	s0,0(sp)
    80003038:	0141                	addi	sp,sp,16
    8000303a:	8082                	ret

000000008000303c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000303c:	1101                	addi	sp,sp,-32
    8000303e:	ec06                	sd	ra,24(sp)
    80003040:	e822                	sd	s0,16(sp)
    80003042:	e426                	sd	s1,8(sp)
    80003044:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003046:	0001d497          	auipc	s1,0x1d
    8000304a:	48a48493          	addi	s1,s1,1162 # 800204d0 <tickslock>
    8000304e:	8526                	mv	a0,s1
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	b72080e7          	jalr	-1166(ra) # 80000bc2 <acquire>
  ticks++;
    80003058:	00007517          	auipc	a0,0x7
    8000305c:	fd850513          	addi	a0,a0,-40 # 8000a030 <ticks>
    80003060:	411c                	lw	a5,0(a0)
    80003062:	2785                	addiw	a5,a5,1
    80003064:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	052080e7          	jalr	82(ra) # 800020b8 <wakeup>
  release(&tickslock);
    8000306e:	8526                	mv	a0,s1
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	c06080e7          	jalr	-1018(ra) # 80000c76 <release>
}
    80003078:	60e2                	ld	ra,24(sp)
    8000307a:	6442                	ld	s0,16(sp)
    8000307c:	64a2                	ld	s1,8(sp)
    8000307e:	6105                	addi	sp,sp,32
    80003080:	8082                	ret

0000000080003082 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000308c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003090:	00074d63          	bltz	a4,800030aa <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003094:	57fd                	li	a5,-1
    80003096:	17fe                	slli	a5,a5,0x3f
    80003098:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000309a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000309c:	06f70363          	beq	a4,a5,80003102 <devintr+0x80>
  }
}
    800030a0:	60e2                	ld	ra,24(sp)
    800030a2:	6442                	ld	s0,16(sp)
    800030a4:	64a2                	ld	s1,8(sp)
    800030a6:	6105                	addi	sp,sp,32
    800030a8:	8082                	ret
     (scause & 0xff) == 9){
    800030aa:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800030ae:	46a5                	li	a3,9
    800030b0:	fed792e3          	bne	a5,a3,80003094 <devintr+0x12>
    int irq = plic_claim();
    800030b4:	00004097          	auipc	ra,0x4
    800030b8:	aa4080e7          	jalr	-1372(ra) # 80006b58 <plic_claim>
    800030bc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800030be:	47a9                	li	a5,10
    800030c0:	02f50763          	beq	a0,a5,800030ee <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800030c4:	4785                	li	a5,1
    800030c6:	02f50963          	beq	a0,a5,800030f8 <devintr+0x76>
    return 1;
    800030ca:	4505                	li	a0,1
    } else if(irq){
    800030cc:	d8f1                	beqz	s1,800030a0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800030ce:	85a6                	mv	a1,s1
    800030d0:	00006517          	auipc	a0,0x6
    800030d4:	50050513          	addi	a0,a0,1280 # 800095d0 <states.0+0x38>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	49c080e7          	jalr	1180(ra) # 80000574 <printf>
      plic_complete(irq);
    800030e0:	8526                	mv	a0,s1
    800030e2:	00004097          	auipc	ra,0x4
    800030e6:	a9a080e7          	jalr	-1382(ra) # 80006b7c <plic_complete>
    return 1;
    800030ea:	4505                	li	a0,1
    800030ec:	bf55                	j	800030a0 <devintr+0x1e>
      uartintr();
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	898080e7          	jalr	-1896(ra) # 80000986 <uartintr>
    800030f6:	b7ed                	j	800030e0 <devintr+0x5e>
      virtio_disk_intr();
    800030f8:	00004097          	auipc	ra,0x4
    800030fc:	f16080e7          	jalr	-234(ra) # 8000700e <virtio_disk_intr>
    80003100:	b7c5                	j	800030e0 <devintr+0x5e>
    if(cpuid() == 0){
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	8a6080e7          	jalr	-1882(ra) # 800019a8 <cpuid>
    8000310a:	c901                	beqz	a0,8000311a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000310c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003110:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003112:	14479073          	csrw	sip,a5
    return 2;
    80003116:	4509                	li	a0,2
    80003118:	b761                	j	800030a0 <devintr+0x1e>
      clockintr();
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	f22080e7          	jalr	-222(ra) # 8000303c <clockintr>
    80003122:	b7ed                	j	8000310c <devintr+0x8a>

0000000080003124 <usertrap>:
{
    80003124:	1101                	addi	sp,sp,-32
    80003126:	ec06                	sd	ra,24(sp)
    80003128:	e822                	sd	s0,16(sp)
    8000312a:	e426                	sd	s1,8(sp)
    8000312c:	e04a                	sd	s2,0(sp)
    8000312e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003130:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003134:	1007f793          	andi	a5,a5,256
    80003138:	e3ad                	bnez	a5,8000319a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000313a:	00004797          	auipc	a5,0x4
    8000313e:	91678793          	addi	a5,a5,-1770 # 80006a50 <kernelvec>
    80003142:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	88e080e7          	jalr	-1906(ra) # 800019d4 <myproc>
    8000314e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003150:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003152:	14102773          	csrr	a4,sepc
    80003156:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003158:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000315c:	47a1                	li	a5,8
    8000315e:	04f71c63          	bne	a4,a5,800031b6 <usertrap+0x92>
    if(p->killed)
    80003162:	551c                	lw	a5,40(a0)
    80003164:	e3b9                	bnez	a5,800031aa <usertrap+0x86>
    p->trapframe->epc += 4;
    80003166:	6cb8                	ld	a4,88(s1)
    80003168:	6f1c                	ld	a5,24(a4)
    8000316a:	0791                	addi	a5,a5,4
    8000316c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000316e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003172:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003176:	10079073          	csrw	sstatus,a5
    syscall();
    8000317a:	00000097          	auipc	ra,0x0
    8000317e:	318080e7          	jalr	792(ra) # 80003492 <syscall>
  if(p->killed)
    80003182:	549c                	lw	a5,40(s1)
    80003184:	ebc5                	bnez	a5,80003234 <usertrap+0x110>
  usertrapret();
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	e18080e7          	jalr	-488(ra) # 80002f9e <usertrapret>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6902                	ld	s2,0(sp)
    80003196:	6105                	addi	sp,sp,32
    80003198:	8082                	ret
    panic("usertrap: not from user mode");
    8000319a:	00006517          	auipc	a0,0x6
    8000319e:	45650513          	addi	a0,a0,1110 # 800095f0 <states.0+0x58>
    800031a2:	ffffd097          	auipc	ra,0xffffd
    800031a6:	388080e7          	jalr	904(ra) # 8000052a <panic>
      exit(-1);
    800031aa:	557d                	li	a0,-1
    800031ac:	fffff097          	auipc	ra,0xfffff
    800031b0:	46e080e7          	jalr	1134(ra) # 8000261a <exit>
    800031b4:	bf4d                	j	80003166 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800031b6:	00000097          	auipc	ra,0x0
    800031ba:	ecc080e7          	jalr	-308(ra) # 80003082 <devintr>
    800031be:	892a                	mv	s2,a0
    800031c0:	c501                	beqz	a0,800031c8 <usertrap+0xa4>
  if(p->killed)
    800031c2:	549c                	lw	a5,40(s1)
    800031c4:	cfb5                	beqz	a5,80003240 <usertrap+0x11c>
    800031c6:	a885                	j	80003236 <usertrap+0x112>
  } else if (relevant_metadata_proc(p) && 
    800031c8:	8526                	mv	a0,s1
    800031ca:	00000097          	auipc	ra,0x0
    800031ce:	d14080e7          	jalr	-748(ra) # 80002ede <relevant_metadata_proc>
    800031d2:	c105                	beqz	a0,800031f2 <usertrap+0xce>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031d4:	14202773          	csrr	a4,scause
    800031d8:	47b1                	li	a5,12
    800031da:	04f70663          	beq	a4,a5,80003226 <usertrap+0x102>
    800031de:	14202773          	csrr	a4,scause
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    800031e2:	47b5                	li	a5,13
    800031e4:	04f70163          	beq	a4,a5,80003226 <usertrap+0x102>
    800031e8:	14202773          	csrr	a4,scause
    800031ec:	47bd                	li	a5,15
    800031ee:	02f70c63          	beq	a4,a5,80003226 <usertrap+0x102>
    800031f2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800031f6:	5890                	lw	a2,48(s1)
    800031f8:	00006517          	auipc	a0,0x6
    800031fc:	41850513          	addi	a0,a0,1048 # 80009610 <states.0+0x78>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	374080e7          	jalr	884(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003208:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000320c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003210:	00006517          	auipc	a0,0x6
    80003214:	43050513          	addi	a0,a0,1072 # 80009640 <states.0+0xa8>
    80003218:	ffffd097          	auipc	ra,0xffffd
    8000321c:	35c080e7          	jalr	860(ra) # 80000574 <printf>
    p->killed = 1;
    80003220:	4785                	li	a5,1
    80003222:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80003224:	a809                	j	80003236 <usertrap+0x112>
    80003226:	14302573          	csrr	a0,stval
      handle_page_fault(va);  
    8000322a:	00000097          	auipc	ra,0x0
    8000322e:	b3a080e7          	jalr	-1222(ra) # 80002d64 <handle_page_fault>
              (r_scause() == INSTRUCTION_PAGE_FAULT || r_scause() == LOAD_PAGE_FAULT || r_scause() == STORE_PAGE_FAULT))  {
    80003232:	bf81                	j	80003182 <usertrap+0x5e>
  if(p->killed)
    80003234:	4901                	li	s2,0
    exit(-1);
    80003236:	557d                	li	a0,-1
    80003238:	fffff097          	auipc	ra,0xfffff
    8000323c:	3e2080e7          	jalr	994(ra) # 8000261a <exit>
  if(which_dev == 2)
    80003240:	4789                	li	a5,2
    80003242:	f4f912e3          	bne	s2,a5,80003186 <usertrap+0x62>
    yield();
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	dd2080e7          	jalr	-558(ra) # 80002018 <yield>
    8000324e:	bf25                	j	80003186 <usertrap+0x62>

0000000080003250 <kerneltrap>:
{
    80003250:	7179                	addi	sp,sp,-48
    80003252:	f406                	sd	ra,40(sp)
    80003254:	f022                	sd	s0,32(sp)
    80003256:	ec26                	sd	s1,24(sp)
    80003258:	e84a                	sd	s2,16(sp)
    8000325a:	e44e                	sd	s3,8(sp)
    8000325c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000325e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003262:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003266:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000326a:	1004f793          	andi	a5,s1,256
    8000326e:	cb85                	beqz	a5,8000329e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003270:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003274:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003276:	ef85                	bnez	a5,800032ae <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	e0a080e7          	jalr	-502(ra) # 80003082 <devintr>
    80003280:	cd1d                	beqz	a0,800032be <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003282:	4789                	li	a5,2
    80003284:	06f50a63          	beq	a0,a5,800032f8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003288:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000328c:	10049073          	csrw	sstatus,s1
}
    80003290:	70a2                	ld	ra,40(sp)
    80003292:	7402                	ld	s0,32(sp)
    80003294:	64e2                	ld	s1,24(sp)
    80003296:	6942                	ld	s2,16(sp)
    80003298:	69a2                	ld	s3,8(sp)
    8000329a:	6145                	addi	sp,sp,48
    8000329c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000329e:	00006517          	auipc	a0,0x6
    800032a2:	3c250513          	addi	a0,a0,962 # 80009660 <states.0+0xc8>
    800032a6:	ffffd097          	auipc	ra,0xffffd
    800032aa:	284080e7          	jalr	644(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800032ae:	00006517          	auipc	a0,0x6
    800032b2:	3da50513          	addi	a0,a0,986 # 80009688 <states.0+0xf0>
    800032b6:	ffffd097          	auipc	ra,0xffffd
    800032ba:	274080e7          	jalr	628(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800032be:	85ce                	mv	a1,s3
    800032c0:	00006517          	auipc	a0,0x6
    800032c4:	3e850513          	addi	a0,a0,1000 # 800096a8 <states.0+0x110>
    800032c8:	ffffd097          	auipc	ra,0xffffd
    800032cc:	2ac080e7          	jalr	684(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032d0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032d4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032d8:	00006517          	auipc	a0,0x6
    800032dc:	3e050513          	addi	a0,a0,992 # 800096b8 <states.0+0x120>
    800032e0:	ffffd097          	auipc	ra,0xffffd
    800032e4:	294080e7          	jalr	660(ra) # 80000574 <printf>
    panic("kerneltrap");
    800032e8:	00006517          	auipc	a0,0x6
    800032ec:	3e850513          	addi	a0,a0,1000 # 800096d0 <states.0+0x138>
    800032f0:	ffffd097          	auipc	ra,0xffffd
    800032f4:	23a080e7          	jalr	570(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	6dc080e7          	jalr	1756(ra) # 800019d4 <myproc>
    80003300:	d541                	beqz	a0,80003288 <kerneltrap+0x38>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	6d2080e7          	jalr	1746(ra) # 800019d4 <myproc>
    8000330a:	4d18                	lw	a4,24(a0)
    8000330c:	4791                	li	a5,4
    8000330e:	f6f71de3          	bne	a4,a5,80003288 <kerneltrap+0x38>
    yield();
    80003312:	fffff097          	auipc	ra,0xfffff
    80003316:	d06080e7          	jalr	-762(ra) # 80002018 <yield>
    8000331a:	b7bd                	j	80003288 <kerneltrap+0x38>

000000008000331c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000331c:	1101                	addi	sp,sp,-32
    8000331e:	ec06                	sd	ra,24(sp)
    80003320:	e822                	sd	s0,16(sp)
    80003322:	e426                	sd	s1,8(sp)
    80003324:	1000                	addi	s0,sp,32
    80003326:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	6ac080e7          	jalr	1708(ra) # 800019d4 <myproc>
  switch (n) {
    80003330:	4795                	li	a5,5
    80003332:	0497e163          	bltu	a5,s1,80003374 <argraw+0x58>
    80003336:	048a                	slli	s1,s1,0x2
    80003338:	00006717          	auipc	a4,0x6
    8000333c:	3d070713          	addi	a4,a4,976 # 80009708 <states.0+0x170>
    80003340:	94ba                	add	s1,s1,a4
    80003342:	409c                	lw	a5,0(s1)
    80003344:	97ba                	add	a5,a5,a4
    80003346:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003348:	6d3c                	ld	a5,88(a0)
    8000334a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000334c:	60e2                	ld	ra,24(sp)
    8000334e:	6442                	ld	s0,16(sp)
    80003350:	64a2                	ld	s1,8(sp)
    80003352:	6105                	addi	sp,sp,32
    80003354:	8082                	ret
    return p->trapframe->a1;
    80003356:	6d3c                	ld	a5,88(a0)
    80003358:	7fa8                	ld	a0,120(a5)
    8000335a:	bfcd                	j	8000334c <argraw+0x30>
    return p->trapframe->a2;
    8000335c:	6d3c                	ld	a5,88(a0)
    8000335e:	63c8                	ld	a0,128(a5)
    80003360:	b7f5                	j	8000334c <argraw+0x30>
    return p->trapframe->a3;
    80003362:	6d3c                	ld	a5,88(a0)
    80003364:	67c8                	ld	a0,136(a5)
    80003366:	b7dd                	j	8000334c <argraw+0x30>
    return p->trapframe->a4;
    80003368:	6d3c                	ld	a5,88(a0)
    8000336a:	6bc8                	ld	a0,144(a5)
    8000336c:	b7c5                	j	8000334c <argraw+0x30>
    return p->trapframe->a5;
    8000336e:	6d3c                	ld	a5,88(a0)
    80003370:	6fc8                	ld	a0,152(a5)
    80003372:	bfe9                	j	8000334c <argraw+0x30>
  panic("argraw");
    80003374:	00006517          	auipc	a0,0x6
    80003378:	36c50513          	addi	a0,a0,876 # 800096e0 <states.0+0x148>
    8000337c:	ffffd097          	auipc	ra,0xffffd
    80003380:	1ae080e7          	jalr	430(ra) # 8000052a <panic>

0000000080003384 <fetchaddr>:
{
    80003384:	1101                	addi	sp,sp,-32
    80003386:	ec06                	sd	ra,24(sp)
    80003388:	e822                	sd	s0,16(sp)
    8000338a:	e426                	sd	s1,8(sp)
    8000338c:	e04a                	sd	s2,0(sp)
    8000338e:	1000                	addi	s0,sp,32
    80003390:	84aa                	mv	s1,a0
    80003392:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	640080e7          	jalr	1600(ra) # 800019d4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000339c:	653c                	ld	a5,72(a0)
    8000339e:	02f4f863          	bgeu	s1,a5,800033ce <fetchaddr+0x4a>
    800033a2:	00848713          	addi	a4,s1,8
    800033a6:	02e7e663          	bltu	a5,a4,800033d2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033aa:	46a1                	li	a3,8
    800033ac:	8626                	mv	a2,s1
    800033ae:	85ca                	mv	a1,s2
    800033b0:	6928                	ld	a0,80(a0)
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	36e080e7          	jalr	878(ra) # 80001720 <copyin>
    800033ba:	00a03533          	snez	a0,a0
    800033be:	40a00533          	neg	a0,a0
}
    800033c2:	60e2                	ld	ra,24(sp)
    800033c4:	6442                	ld	s0,16(sp)
    800033c6:	64a2                	ld	s1,8(sp)
    800033c8:	6902                	ld	s2,0(sp)
    800033ca:	6105                	addi	sp,sp,32
    800033cc:	8082                	ret
    return -1;
    800033ce:	557d                	li	a0,-1
    800033d0:	bfcd                	j	800033c2 <fetchaddr+0x3e>
    800033d2:	557d                	li	a0,-1
    800033d4:	b7fd                	j	800033c2 <fetchaddr+0x3e>

00000000800033d6 <fetchstr>:
{
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	e84a                	sd	s2,16(sp)
    800033e0:	e44e                	sd	s3,8(sp)
    800033e2:	1800                	addi	s0,sp,48
    800033e4:	892a                	mv	s2,a0
    800033e6:	84ae                	mv	s1,a1
    800033e8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800033ea:	ffffe097          	auipc	ra,0xffffe
    800033ee:	5ea080e7          	jalr	1514(ra) # 800019d4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800033f2:	86ce                	mv	a3,s3
    800033f4:	864a                	mv	a2,s2
    800033f6:	85a6                	mv	a1,s1
    800033f8:	6928                	ld	a0,80(a0)
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	3b4080e7          	jalr	948(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003402:	00054763          	bltz	a0,80003410 <fetchstr+0x3a>
  return strlen(buf);
    80003406:	8526                	mv	a0,s1
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	a3a080e7          	jalr	-1478(ra) # 80000e42 <strlen>
}
    80003410:	70a2                	ld	ra,40(sp)
    80003412:	7402                	ld	s0,32(sp)
    80003414:	64e2                	ld	s1,24(sp)
    80003416:	6942                	ld	s2,16(sp)
    80003418:	69a2                	ld	s3,8(sp)
    8000341a:	6145                	addi	sp,sp,48
    8000341c:	8082                	ret

000000008000341e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000341e:	1101                	addi	sp,sp,-32
    80003420:	ec06                	sd	ra,24(sp)
    80003422:	e822                	sd	s0,16(sp)
    80003424:	e426                	sd	s1,8(sp)
    80003426:	1000                	addi	s0,sp,32
    80003428:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	ef2080e7          	jalr	-270(ra) # 8000331c <argraw>
    80003432:	c088                	sw	a0,0(s1)
  return 0;
}
    80003434:	4501                	li	a0,0
    80003436:	60e2                	ld	ra,24(sp)
    80003438:	6442                	ld	s0,16(sp)
    8000343a:	64a2                	ld	s1,8(sp)
    8000343c:	6105                	addi	sp,sp,32
    8000343e:	8082                	ret

0000000080003440 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003440:	1101                	addi	sp,sp,-32
    80003442:	ec06                	sd	ra,24(sp)
    80003444:	e822                	sd	s0,16(sp)
    80003446:	e426                	sd	s1,8(sp)
    80003448:	1000                	addi	s0,sp,32
    8000344a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	ed0080e7          	jalr	-304(ra) # 8000331c <argraw>
    80003454:	e088                	sd	a0,0(s1)
  return 0;
}
    80003456:	4501                	li	a0,0
    80003458:	60e2                	ld	ra,24(sp)
    8000345a:	6442                	ld	s0,16(sp)
    8000345c:	64a2                	ld	s1,8(sp)
    8000345e:	6105                	addi	sp,sp,32
    80003460:	8082                	ret

0000000080003462 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003462:	1101                	addi	sp,sp,-32
    80003464:	ec06                	sd	ra,24(sp)
    80003466:	e822                	sd	s0,16(sp)
    80003468:	e426                	sd	s1,8(sp)
    8000346a:	e04a                	sd	s2,0(sp)
    8000346c:	1000                	addi	s0,sp,32
    8000346e:	84ae                	mv	s1,a1
    80003470:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003472:	00000097          	auipc	ra,0x0
    80003476:	eaa080e7          	jalr	-342(ra) # 8000331c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000347a:	864a                	mv	a2,s2
    8000347c:	85a6                	mv	a1,s1
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	f58080e7          	jalr	-168(ra) # 800033d6 <fetchstr>
}
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	64a2                	ld	s1,8(sp)
    8000348c:	6902                	ld	s2,0(sp)
    8000348e:	6105                	addi	sp,sp,32
    80003490:	8082                	ret

0000000080003492 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003492:	1101                	addi	sp,sp,-32
    80003494:	ec06                	sd	ra,24(sp)
    80003496:	e822                	sd	s0,16(sp)
    80003498:	e426                	sd	s1,8(sp)
    8000349a:	e04a                	sd	s2,0(sp)
    8000349c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000349e:	ffffe097          	auipc	ra,0xffffe
    800034a2:	536080e7          	jalr	1334(ra) # 800019d4 <myproc>
    800034a6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034a8:	05853903          	ld	s2,88(a0)
    800034ac:	0a893783          	ld	a5,168(s2)
    800034b0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800034b4:	37fd                	addiw	a5,a5,-1
    800034b6:	4751                	li	a4,20
    800034b8:	00f76f63          	bltu	a4,a5,800034d6 <syscall+0x44>
    800034bc:	00369713          	slli	a4,a3,0x3
    800034c0:	00006797          	auipc	a5,0x6
    800034c4:	26078793          	addi	a5,a5,608 # 80009720 <syscalls>
    800034c8:	97ba                	add	a5,a5,a4
    800034ca:	639c                	ld	a5,0(a5)
    800034cc:	c789                	beqz	a5,800034d6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800034ce:	9782                	jalr	a5
    800034d0:	06a93823          	sd	a0,112(s2)
    800034d4:	a839                	j	800034f2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800034d6:	15848613          	addi	a2,s1,344
    800034da:	588c                	lw	a1,48(s1)
    800034dc:	00006517          	auipc	a0,0x6
    800034e0:	20c50513          	addi	a0,a0,524 # 800096e8 <states.0+0x150>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	090080e7          	jalr	144(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800034ec:	6cbc                	ld	a5,88(s1)
    800034ee:	577d                	li	a4,-1
    800034f0:	fbb8                	sd	a4,112(a5)
  }
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6902                	ld	s2,0(sp)
    800034fa:	6105                	addi	sp,sp,32
    800034fc:	8082                	ret

00000000800034fe <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800034fe:	1101                	addi	sp,sp,-32
    80003500:	ec06                	sd	ra,24(sp)
    80003502:	e822                	sd	s0,16(sp)
    80003504:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003506:	fec40593          	addi	a1,s0,-20
    8000350a:	4501                	li	a0,0
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	f12080e7          	jalr	-238(ra) # 8000341e <argint>
    return -1;
    80003514:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003516:	00054963          	bltz	a0,80003528 <sys_exit+0x2a>
  exit(n);
    8000351a:	fec42503          	lw	a0,-20(s0)
    8000351e:	fffff097          	auipc	ra,0xfffff
    80003522:	0fc080e7          	jalr	252(ra) # 8000261a <exit>
  return 0;  // not reached
    80003526:	4781                	li	a5,0
}
    80003528:	853e                	mv	a0,a5
    8000352a:	60e2                	ld	ra,24(sp)
    8000352c:	6442                	ld	s0,16(sp)
    8000352e:	6105                	addi	sp,sp,32
    80003530:	8082                	ret

0000000080003532 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003532:	1141                	addi	sp,sp,-16
    80003534:	e406                	sd	ra,8(sp)
    80003536:	e022                	sd	s0,0(sp)
    80003538:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000353a:	ffffe097          	auipc	ra,0xffffe
    8000353e:	49a080e7          	jalr	1178(ra) # 800019d4 <myproc>
}
    80003542:	5908                	lw	a0,48(a0)
    80003544:	60a2                	ld	ra,8(sp)
    80003546:	6402                	ld	s0,0(sp)
    80003548:	0141                	addi	sp,sp,16
    8000354a:	8082                	ret

000000008000354c <sys_fork>:

uint64
sys_fork(void)
{
    8000354c:	1141                	addi	sp,sp,-16
    8000354e:	e406                	sd	ra,8(sp)
    80003550:	e022                	sd	s0,0(sp)
    80003552:	0800                	addi	s0,sp,16
  return fork();
    80003554:	fffff097          	auipc	ra,0xfffff
    80003558:	ede080e7          	jalr	-290(ra) # 80002432 <fork>
}
    8000355c:	60a2                	ld	ra,8(sp)
    8000355e:	6402                	ld	s0,0(sp)
    80003560:	0141                	addi	sp,sp,16
    80003562:	8082                	ret

0000000080003564 <sys_wait>:

uint64
sys_wait(void)
{
    80003564:	1101                	addi	sp,sp,-32
    80003566:	ec06                	sd	ra,24(sp)
    80003568:	e822                	sd	s0,16(sp)
    8000356a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000356c:	fe840593          	addi	a1,s0,-24
    80003570:	4501                	li	a0,0
    80003572:	00000097          	auipc	ra,0x0
    80003576:	ece080e7          	jalr	-306(ra) # 80003440 <argaddr>
    8000357a:	87aa                	mv	a5,a0
    return -1;
    8000357c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000357e:	0007c863          	bltz	a5,8000358e <sys_wait+0x2a>
  return wait(p);
    80003582:	fe843503          	ld	a0,-24(s0)
    80003586:	fffff097          	auipc	ra,0xfffff
    8000358a:	182080e7          	jalr	386(ra) # 80002708 <wait>
}
    8000358e:	60e2                	ld	ra,24(sp)
    80003590:	6442                	ld	s0,16(sp)
    80003592:	6105                	addi	sp,sp,32
    80003594:	8082                	ret

0000000080003596 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003596:	7179                	addi	sp,sp,-48
    80003598:	f406                	sd	ra,40(sp)
    8000359a:	f022                	sd	s0,32(sp)
    8000359c:	ec26                	sd	s1,24(sp)
    8000359e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800035a0:	fdc40593          	addi	a1,s0,-36
    800035a4:	4501                	li	a0,0
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	e78080e7          	jalr	-392(ra) # 8000341e <argint>
    return -1;
    800035ae:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800035b0:	00054f63          	bltz	a0,800035ce <sys_sbrk+0x38>
  addr = myproc()->sz;
    800035b4:	ffffe097          	auipc	ra,0xffffe
    800035b8:	420080e7          	jalr	1056(ra) # 800019d4 <myproc>
    800035bc:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800035be:	fdc42503          	lw	a0,-36(s0)
    800035c2:	ffffe097          	auipc	ra,0xffffe
    800035c6:	76c080e7          	jalr	1900(ra) # 80001d2e <growproc>
    800035ca:	00054863          	bltz	a0,800035da <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800035ce:	8526                	mv	a0,s1
    800035d0:	70a2                	ld	ra,40(sp)
    800035d2:	7402                	ld	s0,32(sp)
    800035d4:	64e2                	ld	s1,24(sp)
    800035d6:	6145                	addi	sp,sp,48
    800035d8:	8082                	ret
    return -1;
    800035da:	54fd                	li	s1,-1
    800035dc:	bfcd                	j	800035ce <sys_sbrk+0x38>

00000000800035de <sys_sleep>:

uint64
sys_sleep(void)
{
    800035de:	7139                	addi	sp,sp,-64
    800035e0:	fc06                	sd	ra,56(sp)
    800035e2:	f822                	sd	s0,48(sp)
    800035e4:	f426                	sd	s1,40(sp)
    800035e6:	f04a                	sd	s2,32(sp)
    800035e8:	ec4e                	sd	s3,24(sp)
    800035ea:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800035ec:	fcc40593          	addi	a1,s0,-52
    800035f0:	4501                	li	a0,0
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	e2c080e7          	jalr	-468(ra) # 8000341e <argint>
    return -1;
    800035fa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800035fc:	06054563          	bltz	a0,80003666 <sys_sleep+0x88>
  acquire(&tickslock);
    80003600:	0001d517          	auipc	a0,0x1d
    80003604:	ed050513          	addi	a0,a0,-304 # 800204d0 <tickslock>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	5ba080e7          	jalr	1466(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003610:	00007917          	auipc	s2,0x7
    80003614:	a2092903          	lw	s2,-1504(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    80003618:	fcc42783          	lw	a5,-52(s0)
    8000361c:	cf85                	beqz	a5,80003654 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000361e:	0001d997          	auipc	s3,0x1d
    80003622:	eb298993          	addi	s3,s3,-334 # 800204d0 <tickslock>
    80003626:	00007497          	auipc	s1,0x7
    8000362a:	a0a48493          	addi	s1,s1,-1526 # 8000a030 <ticks>
    if(myproc()->killed){
    8000362e:	ffffe097          	auipc	ra,0xffffe
    80003632:	3a6080e7          	jalr	934(ra) # 800019d4 <myproc>
    80003636:	551c                	lw	a5,40(a0)
    80003638:	ef9d                	bnez	a5,80003676 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000363a:	85ce                	mv	a1,s3
    8000363c:	8526                	mv	a0,s1
    8000363e:	fffff097          	auipc	ra,0xfffff
    80003642:	a16080e7          	jalr	-1514(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80003646:	409c                	lw	a5,0(s1)
    80003648:	412787bb          	subw	a5,a5,s2
    8000364c:	fcc42703          	lw	a4,-52(s0)
    80003650:	fce7efe3          	bltu	a5,a4,8000362e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003654:	0001d517          	auipc	a0,0x1d
    80003658:	e7c50513          	addi	a0,a0,-388 # 800204d0 <tickslock>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	61a080e7          	jalr	1562(ra) # 80000c76 <release>
  return 0;
    80003664:	4781                	li	a5,0
}
    80003666:	853e                	mv	a0,a5
    80003668:	70e2                	ld	ra,56(sp)
    8000366a:	7442                	ld	s0,48(sp)
    8000366c:	74a2                	ld	s1,40(sp)
    8000366e:	7902                	ld	s2,32(sp)
    80003670:	69e2                	ld	s3,24(sp)
    80003672:	6121                	addi	sp,sp,64
    80003674:	8082                	ret
      release(&tickslock);
    80003676:	0001d517          	auipc	a0,0x1d
    8000367a:	e5a50513          	addi	a0,a0,-422 # 800204d0 <tickslock>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	5f8080e7          	jalr	1528(ra) # 80000c76 <release>
      return -1;
    80003686:	57fd                	li	a5,-1
    80003688:	bff9                	j	80003666 <sys_sleep+0x88>

000000008000368a <sys_kill>:

uint64
sys_kill(void)
{
    8000368a:	1101                	addi	sp,sp,-32
    8000368c:	ec06                	sd	ra,24(sp)
    8000368e:	e822                	sd	s0,16(sp)
    80003690:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003692:	fec40593          	addi	a1,s0,-20
    80003696:	4501                	li	a0,0
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	d86080e7          	jalr	-634(ra) # 8000341e <argint>
    800036a0:	87aa                	mv	a5,a0
    return -1;
    800036a2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800036a4:	0007c863          	bltz	a5,800036b4 <sys_kill+0x2a>
  return kill(pid);
    800036a8:	fec42503          	lw	a0,-20(s0)
    800036ac:	fffff097          	auipc	ra,0xfffff
    800036b0:	adc080e7          	jalr	-1316(ra) # 80002188 <kill>
}
    800036b4:	60e2                	ld	ra,24(sp)
    800036b6:	6442                	ld	s0,16(sp)
    800036b8:	6105                	addi	sp,sp,32
    800036ba:	8082                	ret

00000000800036bc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036bc:	1101                	addi	sp,sp,-32
    800036be:	ec06                	sd	ra,24(sp)
    800036c0:	e822                	sd	s0,16(sp)
    800036c2:	e426                	sd	s1,8(sp)
    800036c4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036c6:	0001d517          	auipc	a0,0x1d
    800036ca:	e0a50513          	addi	a0,a0,-502 # 800204d0 <tickslock>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	4f4080e7          	jalr	1268(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800036d6:	00007497          	auipc	s1,0x7
    800036da:	95a4a483          	lw	s1,-1702(s1) # 8000a030 <ticks>
  release(&tickslock);
    800036de:	0001d517          	auipc	a0,0x1d
    800036e2:	df250513          	addi	a0,a0,-526 # 800204d0 <tickslock>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	590080e7          	jalr	1424(ra) # 80000c76 <release>
  return xticks;
}
    800036ee:	02049513          	slli	a0,s1,0x20
    800036f2:	9101                	srli	a0,a0,0x20
    800036f4:	60e2                	ld	ra,24(sp)
    800036f6:	6442                	ld	s0,16(sp)
    800036f8:	64a2                	ld	s1,8(sp)
    800036fa:	6105                	addi	sp,sp,32
    800036fc:	8082                	ret

00000000800036fe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800036fe:	7179                	addi	sp,sp,-48
    80003700:	f406                	sd	ra,40(sp)
    80003702:	f022                	sd	s0,32(sp)
    80003704:	ec26                	sd	s1,24(sp)
    80003706:	e84a                	sd	s2,16(sp)
    80003708:	e44e                	sd	s3,8(sp)
    8000370a:	e052                	sd	s4,0(sp)
    8000370c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000370e:	00006597          	auipc	a1,0x6
    80003712:	0c258593          	addi	a1,a1,194 # 800097d0 <syscalls+0xb0>
    80003716:	0001d517          	auipc	a0,0x1d
    8000371a:	dd250513          	addi	a0,a0,-558 # 800204e8 <bcache>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	414080e7          	jalr	1044(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003726:	00025797          	auipc	a5,0x25
    8000372a:	dc278793          	addi	a5,a5,-574 # 800284e8 <bcache+0x8000>
    8000372e:	00025717          	auipc	a4,0x25
    80003732:	02270713          	addi	a4,a4,34 # 80028750 <bcache+0x8268>
    80003736:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000373a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000373e:	0001d497          	auipc	s1,0x1d
    80003742:	dc248493          	addi	s1,s1,-574 # 80020500 <bcache+0x18>
    b->next = bcache.head.next;
    80003746:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003748:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000374a:	00006a17          	auipc	s4,0x6
    8000374e:	08ea0a13          	addi	s4,s4,142 # 800097d8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003752:	2b893783          	ld	a5,696(s2)
    80003756:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003758:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000375c:	85d2                	mv	a1,s4
    8000375e:	01048513          	addi	a0,s1,16
    80003762:	00001097          	auipc	ra,0x1
    80003766:	7d4080e7          	jalr	2004(ra) # 80004f36 <initsleeplock>
    bcache.head.next->prev = b;
    8000376a:	2b893783          	ld	a5,696(s2)
    8000376e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003770:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003774:	45848493          	addi	s1,s1,1112
    80003778:	fd349de3          	bne	s1,s3,80003752 <binit+0x54>
  }
}
    8000377c:	70a2                	ld	ra,40(sp)
    8000377e:	7402                	ld	s0,32(sp)
    80003780:	64e2                	ld	s1,24(sp)
    80003782:	6942                	ld	s2,16(sp)
    80003784:	69a2                	ld	s3,8(sp)
    80003786:	6a02                	ld	s4,0(sp)
    80003788:	6145                	addi	sp,sp,48
    8000378a:	8082                	ret

000000008000378c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000378c:	7179                	addi	sp,sp,-48
    8000378e:	f406                	sd	ra,40(sp)
    80003790:	f022                	sd	s0,32(sp)
    80003792:	ec26                	sd	s1,24(sp)
    80003794:	e84a                	sd	s2,16(sp)
    80003796:	e44e                	sd	s3,8(sp)
    80003798:	1800                	addi	s0,sp,48
    8000379a:	892a                	mv	s2,a0
    8000379c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000379e:	0001d517          	auipc	a0,0x1d
    800037a2:	d4a50513          	addi	a0,a0,-694 # 800204e8 <bcache>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	41c080e7          	jalr	1052(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037ae:	00025497          	auipc	s1,0x25
    800037b2:	ff24b483          	ld	s1,-14(s1) # 800287a0 <bcache+0x82b8>
    800037b6:	00025797          	auipc	a5,0x25
    800037ba:	f9a78793          	addi	a5,a5,-102 # 80028750 <bcache+0x8268>
    800037be:	02f48f63          	beq	s1,a5,800037fc <bread+0x70>
    800037c2:	873e                	mv	a4,a5
    800037c4:	a021                	j	800037cc <bread+0x40>
    800037c6:	68a4                	ld	s1,80(s1)
    800037c8:	02e48a63          	beq	s1,a4,800037fc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800037cc:	449c                	lw	a5,8(s1)
    800037ce:	ff279ce3          	bne	a5,s2,800037c6 <bread+0x3a>
    800037d2:	44dc                	lw	a5,12(s1)
    800037d4:	ff3799e3          	bne	a5,s3,800037c6 <bread+0x3a>
      b->refcnt++;
    800037d8:	40bc                	lw	a5,64(s1)
    800037da:	2785                	addiw	a5,a5,1
    800037dc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037de:	0001d517          	auipc	a0,0x1d
    800037e2:	d0a50513          	addi	a0,a0,-758 # 800204e8 <bcache>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	490080e7          	jalr	1168(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800037ee:	01048513          	addi	a0,s1,16
    800037f2:	00001097          	auipc	ra,0x1
    800037f6:	77e080e7          	jalr	1918(ra) # 80004f70 <acquiresleep>
      return b;
    800037fa:	a8b9                	j	80003858 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037fc:	00025497          	auipc	s1,0x25
    80003800:	f9c4b483          	ld	s1,-100(s1) # 80028798 <bcache+0x82b0>
    80003804:	00025797          	auipc	a5,0x25
    80003808:	f4c78793          	addi	a5,a5,-180 # 80028750 <bcache+0x8268>
    8000380c:	00f48863          	beq	s1,a5,8000381c <bread+0x90>
    80003810:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003812:	40bc                	lw	a5,64(s1)
    80003814:	cf81                	beqz	a5,8000382c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003816:	64a4                	ld	s1,72(s1)
    80003818:	fee49de3          	bne	s1,a4,80003812 <bread+0x86>
  panic("bget: no buffers");
    8000381c:	00006517          	auipc	a0,0x6
    80003820:	fc450513          	addi	a0,a0,-60 # 800097e0 <syscalls+0xc0>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	d06080e7          	jalr	-762(ra) # 8000052a <panic>
      b->dev = dev;
    8000382c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003830:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003834:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003838:	4785                	li	a5,1
    8000383a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000383c:	0001d517          	auipc	a0,0x1d
    80003840:	cac50513          	addi	a0,a0,-852 # 800204e8 <bcache>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	432080e7          	jalr	1074(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000384c:	01048513          	addi	a0,s1,16
    80003850:	00001097          	auipc	ra,0x1
    80003854:	720080e7          	jalr	1824(ra) # 80004f70 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003858:	409c                	lw	a5,0(s1)
    8000385a:	cb89                	beqz	a5,8000386c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000385c:	8526                	mv	a0,s1
    8000385e:	70a2                	ld	ra,40(sp)
    80003860:	7402                	ld	s0,32(sp)
    80003862:	64e2                	ld	s1,24(sp)
    80003864:	6942                	ld	s2,16(sp)
    80003866:	69a2                	ld	s3,8(sp)
    80003868:	6145                	addi	sp,sp,48
    8000386a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000386c:	4581                	li	a1,0
    8000386e:	8526                	mv	a0,s1
    80003870:	00003097          	auipc	ra,0x3
    80003874:	516080e7          	jalr	1302(ra) # 80006d86 <virtio_disk_rw>
    b->valid = 1;
    80003878:	4785                	li	a5,1
    8000387a:	c09c                	sw	a5,0(s1)
  return b;
    8000387c:	b7c5                	j	8000385c <bread+0xd0>

000000008000387e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	e426                	sd	s1,8(sp)
    80003886:	1000                	addi	s0,sp,32
    80003888:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000388a:	0541                	addi	a0,a0,16
    8000388c:	00001097          	auipc	ra,0x1
    80003890:	77e080e7          	jalr	1918(ra) # 8000500a <holdingsleep>
    80003894:	cd01                	beqz	a0,800038ac <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003896:	4585                	li	a1,1
    80003898:	8526                	mv	a0,s1
    8000389a:	00003097          	auipc	ra,0x3
    8000389e:	4ec080e7          	jalr	1260(ra) # 80006d86 <virtio_disk_rw>
}
    800038a2:	60e2                	ld	ra,24(sp)
    800038a4:	6442                	ld	s0,16(sp)
    800038a6:	64a2                	ld	s1,8(sp)
    800038a8:	6105                	addi	sp,sp,32
    800038aa:	8082                	ret
    panic("bwrite");
    800038ac:	00006517          	auipc	a0,0x6
    800038b0:	f4c50513          	addi	a0,a0,-180 # 800097f8 <syscalls+0xd8>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	c76080e7          	jalr	-906(ra) # 8000052a <panic>

00000000800038bc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	e426                	sd	s1,8(sp)
    800038c4:	e04a                	sd	s2,0(sp)
    800038c6:	1000                	addi	s0,sp,32
    800038c8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038ca:	01050913          	addi	s2,a0,16
    800038ce:	854a                	mv	a0,s2
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	73a080e7          	jalr	1850(ra) # 8000500a <holdingsleep>
    800038d8:	c92d                	beqz	a0,8000394a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800038da:	854a                	mv	a0,s2
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	6ea080e7          	jalr	1770(ra) # 80004fc6 <releasesleep>

  acquire(&bcache.lock);
    800038e4:	0001d517          	auipc	a0,0x1d
    800038e8:	c0450513          	addi	a0,a0,-1020 # 800204e8 <bcache>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	2d6080e7          	jalr	726(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800038f4:	40bc                	lw	a5,64(s1)
    800038f6:	37fd                	addiw	a5,a5,-1
    800038f8:	0007871b          	sext.w	a4,a5
    800038fc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800038fe:	eb05                	bnez	a4,8000392e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003900:	68bc                	ld	a5,80(s1)
    80003902:	64b8                	ld	a4,72(s1)
    80003904:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003906:	64bc                	ld	a5,72(s1)
    80003908:	68b8                	ld	a4,80(s1)
    8000390a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000390c:	00025797          	auipc	a5,0x25
    80003910:	bdc78793          	addi	a5,a5,-1060 # 800284e8 <bcache+0x8000>
    80003914:	2b87b703          	ld	a4,696(a5)
    80003918:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000391a:	00025717          	auipc	a4,0x25
    8000391e:	e3670713          	addi	a4,a4,-458 # 80028750 <bcache+0x8268>
    80003922:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003924:	2b87b703          	ld	a4,696(a5)
    80003928:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000392a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000392e:	0001d517          	auipc	a0,0x1d
    80003932:	bba50513          	addi	a0,a0,-1094 # 800204e8 <bcache>
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	340080e7          	jalr	832(ra) # 80000c76 <release>
}
    8000393e:	60e2                	ld	ra,24(sp)
    80003940:	6442                	ld	s0,16(sp)
    80003942:	64a2                	ld	s1,8(sp)
    80003944:	6902                	ld	s2,0(sp)
    80003946:	6105                	addi	sp,sp,32
    80003948:	8082                	ret
    panic("brelse");
    8000394a:	00006517          	auipc	a0,0x6
    8000394e:	eb650513          	addi	a0,a0,-330 # 80009800 <syscalls+0xe0>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	bd8080e7          	jalr	-1064(ra) # 8000052a <panic>

000000008000395a <bpin>:

void
bpin(struct buf *b) {
    8000395a:	1101                	addi	sp,sp,-32
    8000395c:	ec06                	sd	ra,24(sp)
    8000395e:	e822                	sd	s0,16(sp)
    80003960:	e426                	sd	s1,8(sp)
    80003962:	1000                	addi	s0,sp,32
    80003964:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003966:	0001d517          	auipc	a0,0x1d
    8000396a:	b8250513          	addi	a0,a0,-1150 # 800204e8 <bcache>
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	254080e7          	jalr	596(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003976:	40bc                	lw	a5,64(s1)
    80003978:	2785                	addiw	a5,a5,1
    8000397a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000397c:	0001d517          	auipc	a0,0x1d
    80003980:	b6c50513          	addi	a0,a0,-1172 # 800204e8 <bcache>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	2f2080e7          	jalr	754(ra) # 80000c76 <release>
}
    8000398c:	60e2                	ld	ra,24(sp)
    8000398e:	6442                	ld	s0,16(sp)
    80003990:	64a2                	ld	s1,8(sp)
    80003992:	6105                	addi	sp,sp,32
    80003994:	8082                	ret

0000000080003996 <bunpin>:

void
bunpin(struct buf *b) {
    80003996:	1101                	addi	sp,sp,-32
    80003998:	ec06                	sd	ra,24(sp)
    8000399a:	e822                	sd	s0,16(sp)
    8000399c:	e426                	sd	s1,8(sp)
    8000399e:	1000                	addi	s0,sp,32
    800039a0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039a2:	0001d517          	auipc	a0,0x1d
    800039a6:	b4650513          	addi	a0,a0,-1210 # 800204e8 <bcache>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	218080e7          	jalr	536(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800039b2:	40bc                	lw	a5,64(s1)
    800039b4:	37fd                	addiw	a5,a5,-1
    800039b6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039b8:	0001d517          	auipc	a0,0x1d
    800039bc:	b3050513          	addi	a0,a0,-1232 # 800204e8 <bcache>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	2b6080e7          	jalr	694(ra) # 80000c76 <release>
}
    800039c8:	60e2                	ld	ra,24(sp)
    800039ca:	6442                	ld	s0,16(sp)
    800039cc:	64a2                	ld	s1,8(sp)
    800039ce:	6105                	addi	sp,sp,32
    800039d0:	8082                	ret

00000000800039d2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800039d2:	1101                	addi	sp,sp,-32
    800039d4:	ec06                	sd	ra,24(sp)
    800039d6:	e822                	sd	s0,16(sp)
    800039d8:	e426                	sd	s1,8(sp)
    800039da:	e04a                	sd	s2,0(sp)
    800039dc:	1000                	addi	s0,sp,32
    800039de:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800039e0:	00d5d59b          	srliw	a1,a1,0xd
    800039e4:	00025797          	auipc	a5,0x25
    800039e8:	1e07a783          	lw	a5,480(a5) # 80028bc4 <sb+0x1c>
    800039ec:	9dbd                	addw	a1,a1,a5
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	d9e080e7          	jalr	-610(ra) # 8000378c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800039f6:	0074f713          	andi	a4,s1,7
    800039fa:	4785                	li	a5,1
    800039fc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a00:	14ce                	slli	s1,s1,0x33
    80003a02:	90d9                	srli	s1,s1,0x36
    80003a04:	00950733          	add	a4,a0,s1
    80003a08:	05874703          	lbu	a4,88(a4)
    80003a0c:	00e7f6b3          	and	a3,a5,a4
    80003a10:	c69d                	beqz	a3,80003a3e <bfree+0x6c>
    80003a12:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a14:	94aa                	add	s1,s1,a0
    80003a16:	fff7c793          	not	a5,a5
    80003a1a:	8ff9                	and	a5,a5,a4
    80003a1c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a20:	00001097          	auipc	ra,0x1
    80003a24:	430080e7          	jalr	1072(ra) # 80004e50 <log_write>
  brelse(bp);
    80003a28:	854a                	mv	a0,s2
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	e92080e7          	jalr	-366(ra) # 800038bc <brelse>
}
    80003a32:	60e2                	ld	ra,24(sp)
    80003a34:	6442                	ld	s0,16(sp)
    80003a36:	64a2                	ld	s1,8(sp)
    80003a38:	6902                	ld	s2,0(sp)
    80003a3a:	6105                	addi	sp,sp,32
    80003a3c:	8082                	ret
    panic("freeing free block");
    80003a3e:	00006517          	auipc	a0,0x6
    80003a42:	dca50513          	addi	a0,a0,-566 # 80009808 <syscalls+0xe8>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	ae4080e7          	jalr	-1308(ra) # 8000052a <panic>

0000000080003a4e <balloc>:
{
    80003a4e:	711d                	addi	sp,sp,-96
    80003a50:	ec86                	sd	ra,88(sp)
    80003a52:	e8a2                	sd	s0,80(sp)
    80003a54:	e4a6                	sd	s1,72(sp)
    80003a56:	e0ca                	sd	s2,64(sp)
    80003a58:	fc4e                	sd	s3,56(sp)
    80003a5a:	f852                	sd	s4,48(sp)
    80003a5c:	f456                	sd	s5,40(sp)
    80003a5e:	f05a                	sd	s6,32(sp)
    80003a60:	ec5e                	sd	s7,24(sp)
    80003a62:	e862                	sd	s8,16(sp)
    80003a64:	e466                	sd	s9,8(sp)
    80003a66:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a68:	00025797          	auipc	a5,0x25
    80003a6c:	1447a783          	lw	a5,324(a5) # 80028bac <sb+0x4>
    80003a70:	cbd1                	beqz	a5,80003b04 <balloc+0xb6>
    80003a72:	8baa                	mv	s7,a0
    80003a74:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a76:	00025b17          	auipc	s6,0x25
    80003a7a:	132b0b13          	addi	s6,s6,306 # 80028ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a7e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a80:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a82:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a84:	6c89                	lui	s9,0x2
    80003a86:	a831                	j	80003aa2 <balloc+0x54>
    brelse(bp);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	e32080e7          	jalr	-462(ra) # 800038bc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a92:	015c87bb          	addw	a5,s9,s5
    80003a96:	00078a9b          	sext.w	s5,a5
    80003a9a:	004b2703          	lw	a4,4(s6)
    80003a9e:	06eaf363          	bgeu	s5,a4,80003b04 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003aa2:	41fad79b          	sraiw	a5,s5,0x1f
    80003aa6:	0137d79b          	srliw	a5,a5,0x13
    80003aaa:	015787bb          	addw	a5,a5,s5
    80003aae:	40d7d79b          	sraiw	a5,a5,0xd
    80003ab2:	01cb2583          	lw	a1,28(s6)
    80003ab6:	9dbd                	addw	a1,a1,a5
    80003ab8:	855e                	mv	a0,s7
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	cd2080e7          	jalr	-814(ra) # 8000378c <bread>
    80003ac2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ac4:	004b2503          	lw	a0,4(s6)
    80003ac8:	000a849b          	sext.w	s1,s5
    80003acc:	8662                	mv	a2,s8
    80003ace:	faa4fde3          	bgeu	s1,a0,80003a88 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003ad2:	41f6579b          	sraiw	a5,a2,0x1f
    80003ad6:	01d7d69b          	srliw	a3,a5,0x1d
    80003ada:	00c6873b          	addw	a4,a3,a2
    80003ade:	00777793          	andi	a5,a4,7
    80003ae2:	9f95                	subw	a5,a5,a3
    80003ae4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003ae8:	4037571b          	sraiw	a4,a4,0x3
    80003aec:	00e906b3          	add	a3,s2,a4
    80003af0:	0586c683          	lbu	a3,88(a3)
    80003af4:	00d7f5b3          	and	a1,a5,a3
    80003af8:	cd91                	beqz	a1,80003b14 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003afa:	2605                	addiw	a2,a2,1
    80003afc:	2485                	addiw	s1,s1,1
    80003afe:	fd4618e3          	bne	a2,s4,80003ace <balloc+0x80>
    80003b02:	b759                	j	80003a88 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003b04:	00006517          	auipc	a0,0x6
    80003b08:	d1c50513          	addi	a0,a0,-740 # 80009820 <syscalls+0x100>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	a1e080e7          	jalr	-1506(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b14:	974a                	add	a4,a4,s2
    80003b16:	8fd5                	or	a5,a5,a3
    80003b18:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003b1c:	854a                	mv	a0,s2
    80003b1e:	00001097          	auipc	ra,0x1
    80003b22:	332080e7          	jalr	818(ra) # 80004e50 <log_write>
        brelse(bp);
    80003b26:	854a                	mv	a0,s2
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	d94080e7          	jalr	-620(ra) # 800038bc <brelse>
  bp = bread(dev, bno);
    80003b30:	85a6                	mv	a1,s1
    80003b32:	855e                	mv	a0,s7
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	c58080e7          	jalr	-936(ra) # 8000378c <bread>
    80003b3c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b3e:	40000613          	li	a2,1024
    80003b42:	4581                	li	a1,0
    80003b44:	05850513          	addi	a0,a0,88
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	176080e7          	jalr	374(ra) # 80000cbe <memset>
  log_write(bp);
    80003b50:	854a                	mv	a0,s2
    80003b52:	00001097          	auipc	ra,0x1
    80003b56:	2fe080e7          	jalr	766(ra) # 80004e50 <log_write>
  brelse(bp);
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	d60080e7          	jalr	-672(ra) # 800038bc <brelse>
}
    80003b64:	8526                	mv	a0,s1
    80003b66:	60e6                	ld	ra,88(sp)
    80003b68:	6446                	ld	s0,80(sp)
    80003b6a:	64a6                	ld	s1,72(sp)
    80003b6c:	6906                	ld	s2,64(sp)
    80003b6e:	79e2                	ld	s3,56(sp)
    80003b70:	7a42                	ld	s4,48(sp)
    80003b72:	7aa2                	ld	s5,40(sp)
    80003b74:	7b02                	ld	s6,32(sp)
    80003b76:	6be2                	ld	s7,24(sp)
    80003b78:	6c42                	ld	s8,16(sp)
    80003b7a:	6ca2                	ld	s9,8(sp)
    80003b7c:	6125                	addi	sp,sp,96
    80003b7e:	8082                	ret

0000000080003b80 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b80:	7179                	addi	sp,sp,-48
    80003b82:	f406                	sd	ra,40(sp)
    80003b84:	f022                	sd	s0,32(sp)
    80003b86:	ec26                	sd	s1,24(sp)
    80003b88:	e84a                	sd	s2,16(sp)
    80003b8a:	e44e                	sd	s3,8(sp)
    80003b8c:	e052                	sd	s4,0(sp)
    80003b8e:	1800                	addi	s0,sp,48
    80003b90:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b92:	47ad                	li	a5,11
    80003b94:	04b7fe63          	bgeu	a5,a1,80003bf0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b98:	ff45849b          	addiw	s1,a1,-12
    80003b9c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ba0:	0ff00793          	li	a5,255
    80003ba4:	0ae7e463          	bltu	a5,a4,80003c4c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ba8:	08052583          	lw	a1,128(a0)
    80003bac:	c5b5                	beqz	a1,80003c18 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003bae:	00092503          	lw	a0,0(s2)
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	bda080e7          	jalr	-1062(ra) # 8000378c <bread>
    80003bba:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003bbc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003bc0:	02049713          	slli	a4,s1,0x20
    80003bc4:	01e75593          	srli	a1,a4,0x1e
    80003bc8:	00b784b3          	add	s1,a5,a1
    80003bcc:	0004a983          	lw	s3,0(s1)
    80003bd0:	04098e63          	beqz	s3,80003c2c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003bd4:	8552                	mv	a0,s4
    80003bd6:	00000097          	auipc	ra,0x0
    80003bda:	ce6080e7          	jalr	-794(ra) # 800038bc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003bde:	854e                	mv	a0,s3
    80003be0:	70a2                	ld	ra,40(sp)
    80003be2:	7402                	ld	s0,32(sp)
    80003be4:	64e2                	ld	s1,24(sp)
    80003be6:	6942                	ld	s2,16(sp)
    80003be8:	69a2                	ld	s3,8(sp)
    80003bea:	6a02                	ld	s4,0(sp)
    80003bec:	6145                	addi	sp,sp,48
    80003bee:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003bf0:	02059793          	slli	a5,a1,0x20
    80003bf4:	01e7d593          	srli	a1,a5,0x1e
    80003bf8:	00b504b3          	add	s1,a0,a1
    80003bfc:	0504a983          	lw	s3,80(s1)
    80003c00:	fc099fe3          	bnez	s3,80003bde <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003c04:	4108                	lw	a0,0(a0)
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	e48080e7          	jalr	-440(ra) # 80003a4e <balloc>
    80003c0e:	0005099b          	sext.w	s3,a0
    80003c12:	0534a823          	sw	s3,80(s1)
    80003c16:	b7e1                	j	80003bde <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003c18:	4108                	lw	a0,0(a0)
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	e34080e7          	jalr	-460(ra) # 80003a4e <balloc>
    80003c22:	0005059b          	sext.w	a1,a0
    80003c26:	08b92023          	sw	a1,128(s2)
    80003c2a:	b751                	j	80003bae <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c2c:	00092503          	lw	a0,0(s2)
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	e1e080e7          	jalr	-482(ra) # 80003a4e <balloc>
    80003c38:	0005099b          	sext.w	s3,a0
    80003c3c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c40:	8552                	mv	a0,s4
    80003c42:	00001097          	auipc	ra,0x1
    80003c46:	20e080e7          	jalr	526(ra) # 80004e50 <log_write>
    80003c4a:	b769                	j	80003bd4 <bmap+0x54>
  panic("bmap: out of range");
    80003c4c:	00006517          	auipc	a0,0x6
    80003c50:	bec50513          	addi	a0,a0,-1044 # 80009838 <syscalls+0x118>
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	8d6080e7          	jalr	-1834(ra) # 8000052a <panic>

0000000080003c5c <iget>:
{
    80003c5c:	7179                	addi	sp,sp,-48
    80003c5e:	f406                	sd	ra,40(sp)
    80003c60:	f022                	sd	s0,32(sp)
    80003c62:	ec26                	sd	s1,24(sp)
    80003c64:	e84a                	sd	s2,16(sp)
    80003c66:	e44e                	sd	s3,8(sp)
    80003c68:	e052                	sd	s4,0(sp)
    80003c6a:	1800                	addi	s0,sp,48
    80003c6c:	89aa                	mv	s3,a0
    80003c6e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c70:	00025517          	auipc	a0,0x25
    80003c74:	f5850513          	addi	a0,a0,-168 # 80028bc8 <itable>
    80003c78:	ffffd097          	auipc	ra,0xffffd
    80003c7c:	f4a080e7          	jalr	-182(ra) # 80000bc2 <acquire>
  empty = 0;
    80003c80:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c82:	00025497          	auipc	s1,0x25
    80003c86:	f5e48493          	addi	s1,s1,-162 # 80028be0 <itable+0x18>
    80003c8a:	00027697          	auipc	a3,0x27
    80003c8e:	9e668693          	addi	a3,a3,-1562 # 8002a670 <log>
    80003c92:	a039                	j	80003ca0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c94:	02090b63          	beqz	s2,80003cca <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c98:	08848493          	addi	s1,s1,136
    80003c9c:	02d48a63          	beq	s1,a3,80003cd0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ca0:	449c                	lw	a5,8(s1)
    80003ca2:	fef059e3          	blez	a5,80003c94 <iget+0x38>
    80003ca6:	4098                	lw	a4,0(s1)
    80003ca8:	ff3716e3          	bne	a4,s3,80003c94 <iget+0x38>
    80003cac:	40d8                	lw	a4,4(s1)
    80003cae:	ff4713e3          	bne	a4,s4,80003c94 <iget+0x38>
      ip->ref++;
    80003cb2:	2785                	addiw	a5,a5,1
    80003cb4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003cb6:	00025517          	auipc	a0,0x25
    80003cba:	f1250513          	addi	a0,a0,-238 # 80028bc8 <itable>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	fb8080e7          	jalr	-72(ra) # 80000c76 <release>
      return ip;
    80003cc6:	8926                	mv	s2,s1
    80003cc8:	a03d                	j	80003cf6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cca:	f7f9                	bnez	a5,80003c98 <iget+0x3c>
    80003ccc:	8926                	mv	s2,s1
    80003cce:	b7e9                	j	80003c98 <iget+0x3c>
  if(empty == 0)
    80003cd0:	02090c63          	beqz	s2,80003d08 <iget+0xac>
  ip->dev = dev;
    80003cd4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003cd8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003cdc:	4785                	li	a5,1
    80003cde:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ce2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ce6:	00025517          	auipc	a0,0x25
    80003cea:	ee250513          	addi	a0,a0,-286 # 80028bc8 <itable>
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	f88080e7          	jalr	-120(ra) # 80000c76 <release>
}
    80003cf6:	854a                	mv	a0,s2
    80003cf8:	70a2                	ld	ra,40(sp)
    80003cfa:	7402                	ld	s0,32(sp)
    80003cfc:	64e2                	ld	s1,24(sp)
    80003cfe:	6942                	ld	s2,16(sp)
    80003d00:	69a2                	ld	s3,8(sp)
    80003d02:	6a02                	ld	s4,0(sp)
    80003d04:	6145                	addi	sp,sp,48
    80003d06:	8082                	ret
    panic("iget: no inodes");
    80003d08:	00006517          	auipc	a0,0x6
    80003d0c:	b4850513          	addi	a0,a0,-1208 # 80009850 <syscalls+0x130>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	81a080e7          	jalr	-2022(ra) # 8000052a <panic>

0000000080003d18 <fsinit>:
fsinit(int dev) {
    80003d18:	7179                	addi	sp,sp,-48
    80003d1a:	f406                	sd	ra,40(sp)
    80003d1c:	f022                	sd	s0,32(sp)
    80003d1e:	ec26                	sd	s1,24(sp)
    80003d20:	e84a                	sd	s2,16(sp)
    80003d22:	e44e                	sd	s3,8(sp)
    80003d24:	1800                	addi	s0,sp,48
    80003d26:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d28:	4585                	li	a1,1
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	a62080e7          	jalr	-1438(ra) # 8000378c <bread>
    80003d32:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d34:	00025997          	auipc	s3,0x25
    80003d38:	e7498993          	addi	s3,s3,-396 # 80028ba8 <sb>
    80003d3c:	02000613          	li	a2,32
    80003d40:	05850593          	addi	a1,a0,88
    80003d44:	854e                	mv	a0,s3
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	fd4080e7          	jalr	-44(ra) # 80000d1a <memmove>
  brelse(bp);
    80003d4e:	8526                	mv	a0,s1
    80003d50:	00000097          	auipc	ra,0x0
    80003d54:	b6c080e7          	jalr	-1172(ra) # 800038bc <brelse>
  if(sb.magic != FSMAGIC)
    80003d58:	0009a703          	lw	a4,0(s3)
    80003d5c:	102037b7          	lui	a5,0x10203
    80003d60:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d64:	02f71263          	bne	a4,a5,80003d88 <fsinit+0x70>
  initlog(dev, &sb);
    80003d68:	00025597          	auipc	a1,0x25
    80003d6c:	e4058593          	addi	a1,a1,-448 # 80028ba8 <sb>
    80003d70:	854a                	mv	a0,s2
    80003d72:	00001097          	auipc	ra,0x1
    80003d76:	e60080e7          	jalr	-416(ra) # 80004bd2 <initlog>
}
    80003d7a:	70a2                	ld	ra,40(sp)
    80003d7c:	7402                	ld	s0,32(sp)
    80003d7e:	64e2                	ld	s1,24(sp)
    80003d80:	6942                	ld	s2,16(sp)
    80003d82:	69a2                	ld	s3,8(sp)
    80003d84:	6145                	addi	sp,sp,48
    80003d86:	8082                	ret
    panic("invalid file system");
    80003d88:	00006517          	auipc	a0,0x6
    80003d8c:	ad850513          	addi	a0,a0,-1320 # 80009860 <syscalls+0x140>
    80003d90:	ffffc097          	auipc	ra,0xffffc
    80003d94:	79a080e7          	jalr	1946(ra) # 8000052a <panic>

0000000080003d98 <iinit>:
{
    80003d98:	7179                	addi	sp,sp,-48
    80003d9a:	f406                	sd	ra,40(sp)
    80003d9c:	f022                	sd	s0,32(sp)
    80003d9e:	ec26                	sd	s1,24(sp)
    80003da0:	e84a                	sd	s2,16(sp)
    80003da2:	e44e                	sd	s3,8(sp)
    80003da4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003da6:	00006597          	auipc	a1,0x6
    80003daa:	ad258593          	addi	a1,a1,-1326 # 80009878 <syscalls+0x158>
    80003dae:	00025517          	auipc	a0,0x25
    80003db2:	e1a50513          	addi	a0,a0,-486 # 80028bc8 <itable>
    80003db6:	ffffd097          	auipc	ra,0xffffd
    80003dba:	d7c080e7          	jalr	-644(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003dbe:	00025497          	auipc	s1,0x25
    80003dc2:	e3248493          	addi	s1,s1,-462 # 80028bf0 <itable+0x28>
    80003dc6:	00027997          	auipc	s3,0x27
    80003dca:	8ba98993          	addi	s3,s3,-1862 # 8002a680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003dce:	00006917          	auipc	s2,0x6
    80003dd2:	ab290913          	addi	s2,s2,-1358 # 80009880 <syscalls+0x160>
    80003dd6:	85ca                	mv	a1,s2
    80003dd8:	8526                	mv	a0,s1
    80003dda:	00001097          	auipc	ra,0x1
    80003dde:	15c080e7          	jalr	348(ra) # 80004f36 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003de2:	08848493          	addi	s1,s1,136
    80003de6:	ff3498e3          	bne	s1,s3,80003dd6 <iinit+0x3e>
}
    80003dea:	70a2                	ld	ra,40(sp)
    80003dec:	7402                	ld	s0,32(sp)
    80003dee:	64e2                	ld	s1,24(sp)
    80003df0:	6942                	ld	s2,16(sp)
    80003df2:	69a2                	ld	s3,8(sp)
    80003df4:	6145                	addi	sp,sp,48
    80003df6:	8082                	ret

0000000080003df8 <ialloc>:
{
    80003df8:	715d                	addi	sp,sp,-80
    80003dfa:	e486                	sd	ra,72(sp)
    80003dfc:	e0a2                	sd	s0,64(sp)
    80003dfe:	fc26                	sd	s1,56(sp)
    80003e00:	f84a                	sd	s2,48(sp)
    80003e02:	f44e                	sd	s3,40(sp)
    80003e04:	f052                	sd	s4,32(sp)
    80003e06:	ec56                	sd	s5,24(sp)
    80003e08:	e85a                	sd	s6,16(sp)
    80003e0a:	e45e                	sd	s7,8(sp)
    80003e0c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e0e:	00025717          	auipc	a4,0x25
    80003e12:	da672703          	lw	a4,-602(a4) # 80028bb4 <sb+0xc>
    80003e16:	4785                	li	a5,1
    80003e18:	04e7fa63          	bgeu	a5,a4,80003e6c <ialloc+0x74>
    80003e1c:	8aaa                	mv	s5,a0
    80003e1e:	8bae                	mv	s7,a1
    80003e20:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e22:	00025a17          	auipc	s4,0x25
    80003e26:	d86a0a13          	addi	s4,s4,-634 # 80028ba8 <sb>
    80003e2a:	00048b1b          	sext.w	s6,s1
    80003e2e:	0044d793          	srli	a5,s1,0x4
    80003e32:	018a2583          	lw	a1,24(s4)
    80003e36:	9dbd                	addw	a1,a1,a5
    80003e38:	8556                	mv	a0,s5
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	952080e7          	jalr	-1710(ra) # 8000378c <bread>
    80003e42:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e44:	05850993          	addi	s3,a0,88
    80003e48:	00f4f793          	andi	a5,s1,15
    80003e4c:	079a                	slli	a5,a5,0x6
    80003e4e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e50:	00099783          	lh	a5,0(s3)
    80003e54:	c785                	beqz	a5,80003e7c <ialloc+0x84>
    brelse(bp);
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	a66080e7          	jalr	-1434(ra) # 800038bc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e5e:	0485                	addi	s1,s1,1
    80003e60:	00ca2703          	lw	a4,12(s4)
    80003e64:	0004879b          	sext.w	a5,s1
    80003e68:	fce7e1e3          	bltu	a5,a4,80003e2a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e6c:	00006517          	auipc	a0,0x6
    80003e70:	a1c50513          	addi	a0,a0,-1508 # 80009888 <syscalls+0x168>
    80003e74:	ffffc097          	auipc	ra,0xffffc
    80003e78:	6b6080e7          	jalr	1718(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003e7c:	04000613          	li	a2,64
    80003e80:	4581                	li	a1,0
    80003e82:	854e                	mv	a0,s3
    80003e84:	ffffd097          	auipc	ra,0xffffd
    80003e88:	e3a080e7          	jalr	-454(ra) # 80000cbe <memset>
      dip->type = type;
    80003e8c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e90:	854a                	mv	a0,s2
    80003e92:	00001097          	auipc	ra,0x1
    80003e96:	fbe080e7          	jalr	-66(ra) # 80004e50 <log_write>
      brelse(bp);
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	a20080e7          	jalr	-1504(ra) # 800038bc <brelse>
      return iget(dev, inum);
    80003ea4:	85da                	mv	a1,s6
    80003ea6:	8556                	mv	a0,s5
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	db4080e7          	jalr	-588(ra) # 80003c5c <iget>
}
    80003eb0:	60a6                	ld	ra,72(sp)
    80003eb2:	6406                	ld	s0,64(sp)
    80003eb4:	74e2                	ld	s1,56(sp)
    80003eb6:	7942                	ld	s2,48(sp)
    80003eb8:	79a2                	ld	s3,40(sp)
    80003eba:	7a02                	ld	s4,32(sp)
    80003ebc:	6ae2                	ld	s5,24(sp)
    80003ebe:	6b42                	ld	s6,16(sp)
    80003ec0:	6ba2                	ld	s7,8(sp)
    80003ec2:	6161                	addi	sp,sp,80
    80003ec4:	8082                	ret

0000000080003ec6 <iupdate>:
{
    80003ec6:	1101                	addi	sp,sp,-32
    80003ec8:	ec06                	sd	ra,24(sp)
    80003eca:	e822                	sd	s0,16(sp)
    80003ecc:	e426                	sd	s1,8(sp)
    80003ece:	e04a                	sd	s2,0(sp)
    80003ed0:	1000                	addi	s0,sp,32
    80003ed2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ed4:	415c                	lw	a5,4(a0)
    80003ed6:	0047d79b          	srliw	a5,a5,0x4
    80003eda:	00025597          	auipc	a1,0x25
    80003ede:	ce65a583          	lw	a1,-794(a1) # 80028bc0 <sb+0x18>
    80003ee2:	9dbd                	addw	a1,a1,a5
    80003ee4:	4108                	lw	a0,0(a0)
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	8a6080e7          	jalr	-1882(ra) # 8000378c <bread>
    80003eee:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ef0:	05850793          	addi	a5,a0,88
    80003ef4:	40c8                	lw	a0,4(s1)
    80003ef6:	893d                	andi	a0,a0,15
    80003ef8:	051a                	slli	a0,a0,0x6
    80003efa:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003efc:	04449703          	lh	a4,68(s1)
    80003f00:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f04:	04649703          	lh	a4,70(s1)
    80003f08:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f0c:	04849703          	lh	a4,72(s1)
    80003f10:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f14:	04a49703          	lh	a4,74(s1)
    80003f18:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f1c:	44f8                	lw	a4,76(s1)
    80003f1e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f20:	03400613          	li	a2,52
    80003f24:	05048593          	addi	a1,s1,80
    80003f28:	0531                	addi	a0,a0,12
    80003f2a:	ffffd097          	auipc	ra,0xffffd
    80003f2e:	df0080e7          	jalr	-528(ra) # 80000d1a <memmove>
  log_write(bp);
    80003f32:	854a                	mv	a0,s2
    80003f34:	00001097          	auipc	ra,0x1
    80003f38:	f1c080e7          	jalr	-228(ra) # 80004e50 <log_write>
  brelse(bp);
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	97e080e7          	jalr	-1666(ra) # 800038bc <brelse>
}
    80003f46:	60e2                	ld	ra,24(sp)
    80003f48:	6442                	ld	s0,16(sp)
    80003f4a:	64a2                	ld	s1,8(sp)
    80003f4c:	6902                	ld	s2,0(sp)
    80003f4e:	6105                	addi	sp,sp,32
    80003f50:	8082                	ret

0000000080003f52 <idup>:
{
    80003f52:	1101                	addi	sp,sp,-32
    80003f54:	ec06                	sd	ra,24(sp)
    80003f56:	e822                	sd	s0,16(sp)
    80003f58:	e426                	sd	s1,8(sp)
    80003f5a:	1000                	addi	s0,sp,32
    80003f5c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f5e:	00025517          	auipc	a0,0x25
    80003f62:	c6a50513          	addi	a0,a0,-918 # 80028bc8 <itable>
    80003f66:	ffffd097          	auipc	ra,0xffffd
    80003f6a:	c5c080e7          	jalr	-932(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003f6e:	449c                	lw	a5,8(s1)
    80003f70:	2785                	addiw	a5,a5,1
    80003f72:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f74:	00025517          	auipc	a0,0x25
    80003f78:	c5450513          	addi	a0,a0,-940 # 80028bc8 <itable>
    80003f7c:	ffffd097          	auipc	ra,0xffffd
    80003f80:	cfa080e7          	jalr	-774(ra) # 80000c76 <release>
}
    80003f84:	8526                	mv	a0,s1
    80003f86:	60e2                	ld	ra,24(sp)
    80003f88:	6442                	ld	s0,16(sp)
    80003f8a:	64a2                	ld	s1,8(sp)
    80003f8c:	6105                	addi	sp,sp,32
    80003f8e:	8082                	ret

0000000080003f90 <ilock>:
{
    80003f90:	1101                	addi	sp,sp,-32
    80003f92:	ec06                	sd	ra,24(sp)
    80003f94:	e822                	sd	s0,16(sp)
    80003f96:	e426                	sd	s1,8(sp)
    80003f98:	e04a                	sd	s2,0(sp)
    80003f9a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f9c:	c115                	beqz	a0,80003fc0 <ilock+0x30>
    80003f9e:	84aa                	mv	s1,a0
    80003fa0:	451c                	lw	a5,8(a0)
    80003fa2:	00f05f63          	blez	a5,80003fc0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fa6:	0541                	addi	a0,a0,16
    80003fa8:	00001097          	auipc	ra,0x1
    80003fac:	fc8080e7          	jalr	-56(ra) # 80004f70 <acquiresleep>
  if(ip->valid == 0){
    80003fb0:	40bc                	lw	a5,64(s1)
    80003fb2:	cf99                	beqz	a5,80003fd0 <ilock+0x40>
}
    80003fb4:	60e2                	ld	ra,24(sp)
    80003fb6:	6442                	ld	s0,16(sp)
    80003fb8:	64a2                	ld	s1,8(sp)
    80003fba:	6902                	ld	s2,0(sp)
    80003fbc:	6105                	addi	sp,sp,32
    80003fbe:	8082                	ret
    panic("ilock");
    80003fc0:	00006517          	auipc	a0,0x6
    80003fc4:	8e050513          	addi	a0,a0,-1824 # 800098a0 <syscalls+0x180>
    80003fc8:	ffffc097          	auipc	ra,0xffffc
    80003fcc:	562080e7          	jalr	1378(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003fd0:	40dc                	lw	a5,4(s1)
    80003fd2:	0047d79b          	srliw	a5,a5,0x4
    80003fd6:	00025597          	auipc	a1,0x25
    80003fda:	bea5a583          	lw	a1,-1046(a1) # 80028bc0 <sb+0x18>
    80003fde:	9dbd                	addw	a1,a1,a5
    80003fe0:	4088                	lw	a0,0(s1)
    80003fe2:	fffff097          	auipc	ra,0xfffff
    80003fe6:	7aa080e7          	jalr	1962(ra) # 8000378c <bread>
    80003fea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fec:	05850593          	addi	a1,a0,88
    80003ff0:	40dc                	lw	a5,4(s1)
    80003ff2:	8bbd                	andi	a5,a5,15
    80003ff4:	079a                	slli	a5,a5,0x6
    80003ff6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ff8:	00059783          	lh	a5,0(a1)
    80003ffc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004000:	00259783          	lh	a5,2(a1)
    80004004:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004008:	00459783          	lh	a5,4(a1)
    8000400c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004010:	00659783          	lh	a5,6(a1)
    80004014:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004018:	459c                	lw	a5,8(a1)
    8000401a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000401c:	03400613          	li	a2,52
    80004020:	05b1                	addi	a1,a1,12
    80004022:	05048513          	addi	a0,s1,80
    80004026:	ffffd097          	auipc	ra,0xffffd
    8000402a:	cf4080e7          	jalr	-780(ra) # 80000d1a <memmove>
    brelse(bp);
    8000402e:	854a                	mv	a0,s2
    80004030:	00000097          	auipc	ra,0x0
    80004034:	88c080e7          	jalr	-1908(ra) # 800038bc <brelse>
    ip->valid = 1;
    80004038:	4785                	li	a5,1
    8000403a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000403c:	04449783          	lh	a5,68(s1)
    80004040:	fbb5                	bnez	a5,80003fb4 <ilock+0x24>
      panic("ilock: no type");
    80004042:	00006517          	auipc	a0,0x6
    80004046:	86650513          	addi	a0,a0,-1946 # 800098a8 <syscalls+0x188>
    8000404a:	ffffc097          	auipc	ra,0xffffc
    8000404e:	4e0080e7          	jalr	1248(ra) # 8000052a <panic>

0000000080004052 <iunlock>:
{
    80004052:	1101                	addi	sp,sp,-32
    80004054:	ec06                	sd	ra,24(sp)
    80004056:	e822                	sd	s0,16(sp)
    80004058:	e426                	sd	s1,8(sp)
    8000405a:	e04a                	sd	s2,0(sp)
    8000405c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000405e:	c905                	beqz	a0,8000408e <iunlock+0x3c>
    80004060:	84aa                	mv	s1,a0
    80004062:	01050913          	addi	s2,a0,16
    80004066:	854a                	mv	a0,s2
    80004068:	00001097          	auipc	ra,0x1
    8000406c:	fa2080e7          	jalr	-94(ra) # 8000500a <holdingsleep>
    80004070:	cd19                	beqz	a0,8000408e <iunlock+0x3c>
    80004072:	449c                	lw	a5,8(s1)
    80004074:	00f05d63          	blez	a5,8000408e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004078:	854a                	mv	a0,s2
    8000407a:	00001097          	auipc	ra,0x1
    8000407e:	f4c080e7          	jalr	-180(ra) # 80004fc6 <releasesleep>
}
    80004082:	60e2                	ld	ra,24(sp)
    80004084:	6442                	ld	s0,16(sp)
    80004086:	64a2                	ld	s1,8(sp)
    80004088:	6902                	ld	s2,0(sp)
    8000408a:	6105                	addi	sp,sp,32
    8000408c:	8082                	ret
    panic("iunlock");
    8000408e:	00006517          	auipc	a0,0x6
    80004092:	82a50513          	addi	a0,a0,-2006 # 800098b8 <syscalls+0x198>
    80004096:	ffffc097          	auipc	ra,0xffffc
    8000409a:	494080e7          	jalr	1172(ra) # 8000052a <panic>

000000008000409e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000409e:	7179                	addi	sp,sp,-48
    800040a0:	f406                	sd	ra,40(sp)
    800040a2:	f022                	sd	s0,32(sp)
    800040a4:	ec26                	sd	s1,24(sp)
    800040a6:	e84a                	sd	s2,16(sp)
    800040a8:	e44e                	sd	s3,8(sp)
    800040aa:	e052                	sd	s4,0(sp)
    800040ac:	1800                	addi	s0,sp,48
    800040ae:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040b0:	05050493          	addi	s1,a0,80
    800040b4:	08050913          	addi	s2,a0,128
    800040b8:	a021                	j	800040c0 <itrunc+0x22>
    800040ba:	0491                	addi	s1,s1,4
    800040bc:	01248d63          	beq	s1,s2,800040d6 <itrunc+0x38>
    if(ip->addrs[i]){
    800040c0:	408c                	lw	a1,0(s1)
    800040c2:	dde5                	beqz	a1,800040ba <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040c4:	0009a503          	lw	a0,0(s3)
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	90a080e7          	jalr	-1782(ra) # 800039d2 <bfree>
      ip->addrs[i] = 0;
    800040d0:	0004a023          	sw	zero,0(s1)
    800040d4:	b7dd                	j	800040ba <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800040d6:	0809a583          	lw	a1,128(s3)
    800040da:	e185                	bnez	a1,800040fa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800040dc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800040e0:	854e                	mv	a0,s3
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	de4080e7          	jalr	-540(ra) # 80003ec6 <iupdate>
}
    800040ea:	70a2                	ld	ra,40(sp)
    800040ec:	7402                	ld	s0,32(sp)
    800040ee:	64e2                	ld	s1,24(sp)
    800040f0:	6942                	ld	s2,16(sp)
    800040f2:	69a2                	ld	s3,8(sp)
    800040f4:	6a02                	ld	s4,0(sp)
    800040f6:	6145                	addi	sp,sp,48
    800040f8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800040fa:	0009a503          	lw	a0,0(s3)
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	68e080e7          	jalr	1678(ra) # 8000378c <bread>
    80004106:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004108:	05850493          	addi	s1,a0,88
    8000410c:	45850913          	addi	s2,a0,1112
    80004110:	a021                	j	80004118 <itrunc+0x7a>
    80004112:	0491                	addi	s1,s1,4
    80004114:	01248b63          	beq	s1,s2,8000412a <itrunc+0x8c>
      if(a[j])
    80004118:	408c                	lw	a1,0(s1)
    8000411a:	dde5                	beqz	a1,80004112 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000411c:	0009a503          	lw	a0,0(s3)
    80004120:	00000097          	auipc	ra,0x0
    80004124:	8b2080e7          	jalr	-1870(ra) # 800039d2 <bfree>
    80004128:	b7ed                	j	80004112 <itrunc+0x74>
    brelse(bp);
    8000412a:	8552                	mv	a0,s4
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	790080e7          	jalr	1936(ra) # 800038bc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004134:	0809a583          	lw	a1,128(s3)
    80004138:	0009a503          	lw	a0,0(s3)
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	896080e7          	jalr	-1898(ra) # 800039d2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004144:	0809a023          	sw	zero,128(s3)
    80004148:	bf51                	j	800040dc <itrunc+0x3e>

000000008000414a <iput>:
{
    8000414a:	1101                	addi	sp,sp,-32
    8000414c:	ec06                	sd	ra,24(sp)
    8000414e:	e822                	sd	s0,16(sp)
    80004150:	e426                	sd	s1,8(sp)
    80004152:	e04a                	sd	s2,0(sp)
    80004154:	1000                	addi	s0,sp,32
    80004156:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004158:	00025517          	auipc	a0,0x25
    8000415c:	a7050513          	addi	a0,a0,-1424 # 80028bc8 <itable>
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	a62080e7          	jalr	-1438(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004168:	4498                	lw	a4,8(s1)
    8000416a:	4785                	li	a5,1
    8000416c:	02f70363          	beq	a4,a5,80004192 <iput+0x48>
  ip->ref--;
    80004170:	449c                	lw	a5,8(s1)
    80004172:	37fd                	addiw	a5,a5,-1
    80004174:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004176:	00025517          	auipc	a0,0x25
    8000417a:	a5250513          	addi	a0,a0,-1454 # 80028bc8 <itable>
    8000417e:	ffffd097          	auipc	ra,0xffffd
    80004182:	af8080e7          	jalr	-1288(ra) # 80000c76 <release>
}
    80004186:	60e2                	ld	ra,24(sp)
    80004188:	6442                	ld	s0,16(sp)
    8000418a:	64a2                	ld	s1,8(sp)
    8000418c:	6902                	ld	s2,0(sp)
    8000418e:	6105                	addi	sp,sp,32
    80004190:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004192:	40bc                	lw	a5,64(s1)
    80004194:	dff1                	beqz	a5,80004170 <iput+0x26>
    80004196:	04a49783          	lh	a5,74(s1)
    8000419a:	fbf9                	bnez	a5,80004170 <iput+0x26>
    acquiresleep(&ip->lock);
    8000419c:	01048913          	addi	s2,s1,16
    800041a0:	854a                	mv	a0,s2
    800041a2:	00001097          	auipc	ra,0x1
    800041a6:	dce080e7          	jalr	-562(ra) # 80004f70 <acquiresleep>
    release(&itable.lock);
    800041aa:	00025517          	auipc	a0,0x25
    800041ae:	a1e50513          	addi	a0,a0,-1506 # 80028bc8 <itable>
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	ac4080e7          	jalr	-1340(ra) # 80000c76 <release>
    itrunc(ip);
    800041ba:	8526                	mv	a0,s1
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	ee2080e7          	jalr	-286(ra) # 8000409e <itrunc>
    ip->type = 0;
    800041c4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041c8:	8526                	mv	a0,s1
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	cfc080e7          	jalr	-772(ra) # 80003ec6 <iupdate>
    ip->valid = 0;
    800041d2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800041d6:	854a                	mv	a0,s2
    800041d8:	00001097          	auipc	ra,0x1
    800041dc:	dee080e7          	jalr	-530(ra) # 80004fc6 <releasesleep>
    acquire(&itable.lock);
    800041e0:	00025517          	auipc	a0,0x25
    800041e4:	9e850513          	addi	a0,a0,-1560 # 80028bc8 <itable>
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	9da080e7          	jalr	-1574(ra) # 80000bc2 <acquire>
    800041f0:	b741                	j	80004170 <iput+0x26>

00000000800041f2 <iunlockput>:
{
    800041f2:	1101                	addi	sp,sp,-32
    800041f4:	ec06                	sd	ra,24(sp)
    800041f6:	e822                	sd	s0,16(sp)
    800041f8:	e426                	sd	s1,8(sp)
    800041fa:	1000                	addi	s0,sp,32
    800041fc:	84aa                	mv	s1,a0
  iunlock(ip);
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	e54080e7          	jalr	-428(ra) # 80004052 <iunlock>
  iput(ip);
    80004206:	8526                	mv	a0,s1
    80004208:	00000097          	auipc	ra,0x0
    8000420c:	f42080e7          	jalr	-190(ra) # 8000414a <iput>
}
    80004210:	60e2                	ld	ra,24(sp)
    80004212:	6442                	ld	s0,16(sp)
    80004214:	64a2                	ld	s1,8(sp)
    80004216:	6105                	addi	sp,sp,32
    80004218:	8082                	ret

000000008000421a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000421a:	1141                	addi	sp,sp,-16
    8000421c:	e422                	sd	s0,8(sp)
    8000421e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004220:	411c                	lw	a5,0(a0)
    80004222:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004224:	415c                	lw	a5,4(a0)
    80004226:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004228:	04451783          	lh	a5,68(a0)
    8000422c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004230:	04a51783          	lh	a5,74(a0)
    80004234:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004238:	04c56783          	lwu	a5,76(a0)
    8000423c:	e99c                	sd	a5,16(a1)
}
    8000423e:	6422                	ld	s0,8(sp)
    80004240:	0141                	addi	sp,sp,16
    80004242:	8082                	ret

0000000080004244 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004244:	457c                	lw	a5,76(a0)
    80004246:	0ed7e963          	bltu	a5,a3,80004338 <readi+0xf4>
{
    8000424a:	7159                	addi	sp,sp,-112
    8000424c:	f486                	sd	ra,104(sp)
    8000424e:	f0a2                	sd	s0,96(sp)
    80004250:	eca6                	sd	s1,88(sp)
    80004252:	e8ca                	sd	s2,80(sp)
    80004254:	e4ce                	sd	s3,72(sp)
    80004256:	e0d2                	sd	s4,64(sp)
    80004258:	fc56                	sd	s5,56(sp)
    8000425a:	f85a                	sd	s6,48(sp)
    8000425c:	f45e                	sd	s7,40(sp)
    8000425e:	f062                	sd	s8,32(sp)
    80004260:	ec66                	sd	s9,24(sp)
    80004262:	e86a                	sd	s10,16(sp)
    80004264:	e46e                	sd	s11,8(sp)
    80004266:	1880                	addi	s0,sp,112
    80004268:	8baa                	mv	s7,a0
    8000426a:	8c2e                	mv	s8,a1
    8000426c:	8ab2                	mv	s5,a2
    8000426e:	84b6                	mv	s1,a3
    80004270:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004272:	9f35                	addw	a4,a4,a3
    return 0;
    80004274:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004276:	0ad76063          	bltu	a4,a3,80004316 <readi+0xd2>
  if(off + n > ip->size)
    8000427a:	00e7f463          	bgeu	a5,a4,80004282 <readi+0x3e>
    n = ip->size - off;
    8000427e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004282:	0a0b0963          	beqz	s6,80004334 <readi+0xf0>
    80004286:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004288:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000428c:	5cfd                	li	s9,-1
    8000428e:	a82d                	j	800042c8 <readi+0x84>
    80004290:	020a1d93          	slli	s11,s4,0x20
    80004294:	020ddd93          	srli	s11,s11,0x20
    80004298:	05890793          	addi	a5,s2,88
    8000429c:	86ee                	mv	a3,s11
    8000429e:	963e                	add	a2,a2,a5
    800042a0:	85d6                	mv	a1,s5
    800042a2:	8562                	mv	a0,s8
    800042a4:	ffffe097          	auipc	ra,0xffffe
    800042a8:	f56080e7          	jalr	-170(ra) # 800021fa <either_copyout>
    800042ac:	05950d63          	beq	a0,s9,80004306 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042b0:	854a                	mv	a0,s2
    800042b2:	fffff097          	auipc	ra,0xfffff
    800042b6:	60a080e7          	jalr	1546(ra) # 800038bc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042ba:	013a09bb          	addw	s3,s4,s3
    800042be:	009a04bb          	addw	s1,s4,s1
    800042c2:	9aee                	add	s5,s5,s11
    800042c4:	0569f763          	bgeu	s3,s6,80004312 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042c8:	000ba903          	lw	s2,0(s7)
    800042cc:	00a4d59b          	srliw	a1,s1,0xa
    800042d0:	855e                	mv	a0,s7
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	8ae080e7          	jalr	-1874(ra) # 80003b80 <bmap>
    800042da:	0005059b          	sext.w	a1,a0
    800042de:	854a                	mv	a0,s2
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	4ac080e7          	jalr	1196(ra) # 8000378c <bread>
    800042e8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042ea:	3ff4f613          	andi	a2,s1,1023
    800042ee:	40cd07bb          	subw	a5,s10,a2
    800042f2:	413b073b          	subw	a4,s6,s3
    800042f6:	8a3e                	mv	s4,a5
    800042f8:	2781                	sext.w	a5,a5
    800042fa:	0007069b          	sext.w	a3,a4
    800042fe:	f8f6f9e3          	bgeu	a3,a5,80004290 <readi+0x4c>
    80004302:	8a3a                	mv	s4,a4
    80004304:	b771                	j	80004290 <readi+0x4c>
      brelse(bp);
    80004306:	854a                	mv	a0,s2
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	5b4080e7          	jalr	1460(ra) # 800038bc <brelse>
      tot = -1;
    80004310:	59fd                	li	s3,-1
  }
  return tot;
    80004312:	0009851b          	sext.w	a0,s3
}
    80004316:	70a6                	ld	ra,104(sp)
    80004318:	7406                	ld	s0,96(sp)
    8000431a:	64e6                	ld	s1,88(sp)
    8000431c:	6946                	ld	s2,80(sp)
    8000431e:	69a6                	ld	s3,72(sp)
    80004320:	6a06                	ld	s4,64(sp)
    80004322:	7ae2                	ld	s5,56(sp)
    80004324:	7b42                	ld	s6,48(sp)
    80004326:	7ba2                	ld	s7,40(sp)
    80004328:	7c02                	ld	s8,32(sp)
    8000432a:	6ce2                	ld	s9,24(sp)
    8000432c:	6d42                	ld	s10,16(sp)
    8000432e:	6da2                	ld	s11,8(sp)
    80004330:	6165                	addi	sp,sp,112
    80004332:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004334:	89da                	mv	s3,s6
    80004336:	bff1                	j	80004312 <readi+0xce>
    return 0;
    80004338:	4501                	li	a0,0
}
    8000433a:	8082                	ret

000000008000433c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000433c:	457c                	lw	a5,76(a0)
    8000433e:	10d7e863          	bltu	a5,a3,8000444e <writei+0x112>
{
    80004342:	7159                	addi	sp,sp,-112
    80004344:	f486                	sd	ra,104(sp)
    80004346:	f0a2                	sd	s0,96(sp)
    80004348:	eca6                	sd	s1,88(sp)
    8000434a:	e8ca                	sd	s2,80(sp)
    8000434c:	e4ce                	sd	s3,72(sp)
    8000434e:	e0d2                	sd	s4,64(sp)
    80004350:	fc56                	sd	s5,56(sp)
    80004352:	f85a                	sd	s6,48(sp)
    80004354:	f45e                	sd	s7,40(sp)
    80004356:	f062                	sd	s8,32(sp)
    80004358:	ec66                	sd	s9,24(sp)
    8000435a:	e86a                	sd	s10,16(sp)
    8000435c:	e46e                	sd	s11,8(sp)
    8000435e:	1880                	addi	s0,sp,112
    80004360:	8b2a                	mv	s6,a0
    80004362:	8c2e                	mv	s8,a1
    80004364:	8ab2                	mv	s5,a2
    80004366:	8936                	mv	s2,a3
    80004368:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000436a:	00e687bb          	addw	a5,a3,a4
    8000436e:	0ed7e263          	bltu	a5,a3,80004452 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004372:	00043737          	lui	a4,0x43
    80004376:	0ef76063          	bltu	a4,a5,80004456 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000437a:	0c0b8863          	beqz	s7,8000444a <writei+0x10e>
    8000437e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004380:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004384:	5cfd                	li	s9,-1
    80004386:	a091                	j	800043ca <writei+0x8e>
    80004388:	02099d93          	slli	s11,s3,0x20
    8000438c:	020ddd93          	srli	s11,s11,0x20
    80004390:	05848793          	addi	a5,s1,88
    80004394:	86ee                	mv	a3,s11
    80004396:	8656                	mv	a2,s5
    80004398:	85e2                	mv	a1,s8
    8000439a:	953e                	add	a0,a0,a5
    8000439c:	ffffe097          	auipc	ra,0xffffe
    800043a0:	eb4080e7          	jalr	-332(ra) # 80002250 <either_copyin>
    800043a4:	07950263          	beq	a0,s9,80004408 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043a8:	8526                	mv	a0,s1
    800043aa:	00001097          	auipc	ra,0x1
    800043ae:	aa6080e7          	jalr	-1370(ra) # 80004e50 <log_write>
    brelse(bp);
    800043b2:	8526                	mv	a0,s1
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	508080e7          	jalr	1288(ra) # 800038bc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043bc:	01498a3b          	addw	s4,s3,s4
    800043c0:	0129893b          	addw	s2,s3,s2
    800043c4:	9aee                	add	s5,s5,s11
    800043c6:	057a7663          	bgeu	s4,s7,80004412 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043ca:	000b2483          	lw	s1,0(s6)
    800043ce:	00a9559b          	srliw	a1,s2,0xa
    800043d2:	855a                	mv	a0,s6
    800043d4:	fffff097          	auipc	ra,0xfffff
    800043d8:	7ac080e7          	jalr	1964(ra) # 80003b80 <bmap>
    800043dc:	0005059b          	sext.w	a1,a0
    800043e0:	8526                	mv	a0,s1
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	3aa080e7          	jalr	938(ra) # 8000378c <bread>
    800043ea:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043ec:	3ff97513          	andi	a0,s2,1023
    800043f0:	40ad07bb          	subw	a5,s10,a0
    800043f4:	414b873b          	subw	a4,s7,s4
    800043f8:	89be                	mv	s3,a5
    800043fa:	2781                	sext.w	a5,a5
    800043fc:	0007069b          	sext.w	a3,a4
    80004400:	f8f6f4e3          	bgeu	a3,a5,80004388 <writei+0x4c>
    80004404:	89ba                	mv	s3,a4
    80004406:	b749                	j	80004388 <writei+0x4c>
      brelse(bp);
    80004408:	8526                	mv	a0,s1
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	4b2080e7          	jalr	1202(ra) # 800038bc <brelse>
  }

  if(off > ip->size)
    80004412:	04cb2783          	lw	a5,76(s6)
    80004416:	0127f463          	bgeu	a5,s2,8000441e <writei+0xe2>
    ip->size = off;
    8000441a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000441e:	855a                	mv	a0,s6
    80004420:	00000097          	auipc	ra,0x0
    80004424:	aa6080e7          	jalr	-1370(ra) # 80003ec6 <iupdate>

  return tot;
    80004428:	000a051b          	sext.w	a0,s4
}
    8000442c:	70a6                	ld	ra,104(sp)
    8000442e:	7406                	ld	s0,96(sp)
    80004430:	64e6                	ld	s1,88(sp)
    80004432:	6946                	ld	s2,80(sp)
    80004434:	69a6                	ld	s3,72(sp)
    80004436:	6a06                	ld	s4,64(sp)
    80004438:	7ae2                	ld	s5,56(sp)
    8000443a:	7b42                	ld	s6,48(sp)
    8000443c:	7ba2                	ld	s7,40(sp)
    8000443e:	7c02                	ld	s8,32(sp)
    80004440:	6ce2                	ld	s9,24(sp)
    80004442:	6d42                	ld	s10,16(sp)
    80004444:	6da2                	ld	s11,8(sp)
    80004446:	6165                	addi	sp,sp,112
    80004448:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000444a:	8a5e                	mv	s4,s7
    8000444c:	bfc9                	j	8000441e <writei+0xe2>
    return -1;
    8000444e:	557d                	li	a0,-1
}
    80004450:	8082                	ret
    return -1;
    80004452:	557d                	li	a0,-1
    80004454:	bfe1                	j	8000442c <writei+0xf0>
    return -1;
    80004456:	557d                	li	a0,-1
    80004458:	bfd1                	j	8000442c <writei+0xf0>

000000008000445a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000445a:	1141                	addi	sp,sp,-16
    8000445c:	e406                	sd	ra,8(sp)
    8000445e:	e022                	sd	s0,0(sp)
    80004460:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004462:	4639                	li	a2,14
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	932080e7          	jalr	-1742(ra) # 80000d96 <strncmp>
}
    8000446c:	60a2                	ld	ra,8(sp)
    8000446e:	6402                	ld	s0,0(sp)
    80004470:	0141                	addi	sp,sp,16
    80004472:	8082                	ret

0000000080004474 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004474:	7139                	addi	sp,sp,-64
    80004476:	fc06                	sd	ra,56(sp)
    80004478:	f822                	sd	s0,48(sp)
    8000447a:	f426                	sd	s1,40(sp)
    8000447c:	f04a                	sd	s2,32(sp)
    8000447e:	ec4e                	sd	s3,24(sp)
    80004480:	e852                	sd	s4,16(sp)
    80004482:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004484:	04451703          	lh	a4,68(a0)
    80004488:	4785                	li	a5,1
    8000448a:	00f71a63          	bne	a4,a5,8000449e <dirlookup+0x2a>
    8000448e:	892a                	mv	s2,a0
    80004490:	89ae                	mv	s3,a1
    80004492:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004494:	457c                	lw	a5,76(a0)
    80004496:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004498:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000449a:	e79d                	bnez	a5,800044c8 <dirlookup+0x54>
    8000449c:	a8a5                	j	80004514 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000449e:	00005517          	auipc	a0,0x5
    800044a2:	42250513          	addi	a0,a0,1058 # 800098c0 <syscalls+0x1a0>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	084080e7          	jalr	132(ra) # 8000052a <panic>
      panic("dirlookup read");
    800044ae:	00005517          	auipc	a0,0x5
    800044b2:	42a50513          	addi	a0,a0,1066 # 800098d8 <syscalls+0x1b8>
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	074080e7          	jalr	116(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044be:	24c1                	addiw	s1,s1,16
    800044c0:	04c92783          	lw	a5,76(s2)
    800044c4:	04f4f763          	bgeu	s1,a5,80004512 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044c8:	4741                	li	a4,16
    800044ca:	86a6                	mv	a3,s1
    800044cc:	fc040613          	addi	a2,s0,-64
    800044d0:	4581                	li	a1,0
    800044d2:	854a                	mv	a0,s2
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	d70080e7          	jalr	-656(ra) # 80004244 <readi>
    800044dc:	47c1                	li	a5,16
    800044de:	fcf518e3          	bne	a0,a5,800044ae <dirlookup+0x3a>
    if(de.inum == 0)
    800044e2:	fc045783          	lhu	a5,-64(s0)
    800044e6:	dfe1                	beqz	a5,800044be <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800044e8:	fc240593          	addi	a1,s0,-62
    800044ec:	854e                	mv	a0,s3
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	f6c080e7          	jalr	-148(ra) # 8000445a <namecmp>
    800044f6:	f561                	bnez	a0,800044be <dirlookup+0x4a>
      if(poff)
    800044f8:	000a0463          	beqz	s4,80004500 <dirlookup+0x8c>
        *poff = off;
    800044fc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004500:	fc045583          	lhu	a1,-64(s0)
    80004504:	00092503          	lw	a0,0(s2)
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	754080e7          	jalr	1876(ra) # 80003c5c <iget>
    80004510:	a011                	j	80004514 <dirlookup+0xa0>
  return 0;
    80004512:	4501                	li	a0,0
}
    80004514:	70e2                	ld	ra,56(sp)
    80004516:	7442                	ld	s0,48(sp)
    80004518:	74a2                	ld	s1,40(sp)
    8000451a:	7902                	ld	s2,32(sp)
    8000451c:	69e2                	ld	s3,24(sp)
    8000451e:	6a42                	ld	s4,16(sp)
    80004520:	6121                	addi	sp,sp,64
    80004522:	8082                	ret

0000000080004524 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004524:	711d                	addi	sp,sp,-96
    80004526:	ec86                	sd	ra,88(sp)
    80004528:	e8a2                	sd	s0,80(sp)
    8000452a:	e4a6                	sd	s1,72(sp)
    8000452c:	e0ca                	sd	s2,64(sp)
    8000452e:	fc4e                	sd	s3,56(sp)
    80004530:	f852                	sd	s4,48(sp)
    80004532:	f456                	sd	s5,40(sp)
    80004534:	f05a                	sd	s6,32(sp)
    80004536:	ec5e                	sd	s7,24(sp)
    80004538:	e862                	sd	s8,16(sp)
    8000453a:	e466                	sd	s9,8(sp)
    8000453c:	1080                	addi	s0,sp,96
    8000453e:	84aa                	mv	s1,a0
    80004540:	8aae                	mv	s5,a1
    80004542:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004544:	00054703          	lbu	a4,0(a0)
    80004548:	02f00793          	li	a5,47
    8000454c:	02f70363          	beq	a4,a5,80004572 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004550:	ffffd097          	auipc	ra,0xffffd
    80004554:	484080e7          	jalr	1156(ra) # 800019d4 <myproc>
    80004558:	15053503          	ld	a0,336(a0)
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	9f6080e7          	jalr	-1546(ra) # 80003f52 <idup>
    80004564:	89aa                	mv	s3,a0
  while(*path == '/')
    80004566:	02f00913          	li	s2,47
  len = path - s;
    8000456a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000456c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000456e:	4b85                	li	s7,1
    80004570:	a865                	j	80004628 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004572:	4585                	li	a1,1
    80004574:	4505                	li	a0,1
    80004576:	fffff097          	auipc	ra,0xfffff
    8000457a:	6e6080e7          	jalr	1766(ra) # 80003c5c <iget>
    8000457e:	89aa                	mv	s3,a0
    80004580:	b7dd                	j	80004566 <namex+0x42>
      iunlockput(ip);
    80004582:	854e                	mv	a0,s3
    80004584:	00000097          	auipc	ra,0x0
    80004588:	c6e080e7          	jalr	-914(ra) # 800041f2 <iunlockput>
      return 0;
    8000458c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000458e:	854e                	mv	a0,s3
    80004590:	60e6                	ld	ra,88(sp)
    80004592:	6446                	ld	s0,80(sp)
    80004594:	64a6                	ld	s1,72(sp)
    80004596:	6906                	ld	s2,64(sp)
    80004598:	79e2                	ld	s3,56(sp)
    8000459a:	7a42                	ld	s4,48(sp)
    8000459c:	7aa2                	ld	s5,40(sp)
    8000459e:	7b02                	ld	s6,32(sp)
    800045a0:	6be2                	ld	s7,24(sp)
    800045a2:	6c42                	ld	s8,16(sp)
    800045a4:	6ca2                	ld	s9,8(sp)
    800045a6:	6125                	addi	sp,sp,96
    800045a8:	8082                	ret
      iunlock(ip);
    800045aa:	854e                	mv	a0,s3
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	aa6080e7          	jalr	-1370(ra) # 80004052 <iunlock>
      return ip;
    800045b4:	bfe9                	j	8000458e <namex+0x6a>
      iunlockput(ip);
    800045b6:	854e                	mv	a0,s3
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	c3a080e7          	jalr	-966(ra) # 800041f2 <iunlockput>
      return 0;
    800045c0:	89e6                	mv	s3,s9
    800045c2:	b7f1                	j	8000458e <namex+0x6a>
  len = path - s;
    800045c4:	40b48633          	sub	a2,s1,a1
    800045c8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800045cc:	099c5463          	bge	s8,s9,80004654 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800045d0:	4639                	li	a2,14
    800045d2:	8552                	mv	a0,s4
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	746080e7          	jalr	1862(ra) # 80000d1a <memmove>
  while(*path == '/')
    800045dc:	0004c783          	lbu	a5,0(s1)
    800045e0:	01279763          	bne	a5,s2,800045ee <namex+0xca>
    path++;
    800045e4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045e6:	0004c783          	lbu	a5,0(s1)
    800045ea:	ff278de3          	beq	a5,s2,800045e4 <namex+0xc0>
    ilock(ip);
    800045ee:	854e                	mv	a0,s3
    800045f0:	00000097          	auipc	ra,0x0
    800045f4:	9a0080e7          	jalr	-1632(ra) # 80003f90 <ilock>
    if(ip->type != T_DIR){
    800045f8:	04499783          	lh	a5,68(s3)
    800045fc:	f97793e3          	bne	a5,s7,80004582 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004600:	000a8563          	beqz	s5,8000460a <namex+0xe6>
    80004604:	0004c783          	lbu	a5,0(s1)
    80004608:	d3cd                	beqz	a5,800045aa <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000460a:	865a                	mv	a2,s6
    8000460c:	85d2                	mv	a1,s4
    8000460e:	854e                	mv	a0,s3
    80004610:	00000097          	auipc	ra,0x0
    80004614:	e64080e7          	jalr	-412(ra) # 80004474 <dirlookup>
    80004618:	8caa                	mv	s9,a0
    8000461a:	dd51                	beqz	a0,800045b6 <namex+0x92>
    iunlockput(ip);
    8000461c:	854e                	mv	a0,s3
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	bd4080e7          	jalr	-1068(ra) # 800041f2 <iunlockput>
    ip = next;
    80004626:	89e6                	mv	s3,s9
  while(*path == '/')
    80004628:	0004c783          	lbu	a5,0(s1)
    8000462c:	05279763          	bne	a5,s2,8000467a <namex+0x156>
    path++;
    80004630:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004632:	0004c783          	lbu	a5,0(s1)
    80004636:	ff278de3          	beq	a5,s2,80004630 <namex+0x10c>
  if(*path == 0)
    8000463a:	c79d                	beqz	a5,80004668 <namex+0x144>
    path++;
    8000463c:	85a6                	mv	a1,s1
  len = path - s;
    8000463e:	8cda                	mv	s9,s6
    80004640:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004642:	01278963          	beq	a5,s2,80004654 <namex+0x130>
    80004646:	dfbd                	beqz	a5,800045c4 <namex+0xa0>
    path++;
    80004648:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000464a:	0004c783          	lbu	a5,0(s1)
    8000464e:	ff279ce3          	bne	a5,s2,80004646 <namex+0x122>
    80004652:	bf8d                	j	800045c4 <namex+0xa0>
    memmove(name, s, len);
    80004654:	2601                	sext.w	a2,a2
    80004656:	8552                	mv	a0,s4
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	6c2080e7          	jalr	1730(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004660:	9cd2                	add	s9,s9,s4
    80004662:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004666:	bf9d                	j	800045dc <namex+0xb8>
  if(nameiparent){
    80004668:	f20a83e3          	beqz	s5,8000458e <namex+0x6a>
    iput(ip);
    8000466c:	854e                	mv	a0,s3
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	adc080e7          	jalr	-1316(ra) # 8000414a <iput>
    return 0;
    80004676:	4981                	li	s3,0
    80004678:	bf19                	j	8000458e <namex+0x6a>
  if(*path == 0)
    8000467a:	d7fd                	beqz	a5,80004668 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000467c:	0004c783          	lbu	a5,0(s1)
    80004680:	85a6                	mv	a1,s1
    80004682:	b7d1                	j	80004646 <namex+0x122>

0000000080004684 <dirlink>:
{
    80004684:	7139                	addi	sp,sp,-64
    80004686:	fc06                	sd	ra,56(sp)
    80004688:	f822                	sd	s0,48(sp)
    8000468a:	f426                	sd	s1,40(sp)
    8000468c:	f04a                	sd	s2,32(sp)
    8000468e:	ec4e                	sd	s3,24(sp)
    80004690:	e852                	sd	s4,16(sp)
    80004692:	0080                	addi	s0,sp,64
    80004694:	892a                	mv	s2,a0
    80004696:	8a2e                	mv	s4,a1
    80004698:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000469a:	4601                	li	a2,0
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	dd8080e7          	jalr	-552(ra) # 80004474 <dirlookup>
    800046a4:	e93d                	bnez	a0,8000471a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046a6:	04c92483          	lw	s1,76(s2)
    800046aa:	c49d                	beqz	s1,800046d8 <dirlink+0x54>
    800046ac:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046ae:	4741                	li	a4,16
    800046b0:	86a6                	mv	a3,s1
    800046b2:	fc040613          	addi	a2,s0,-64
    800046b6:	4581                	li	a1,0
    800046b8:	854a                	mv	a0,s2
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	b8a080e7          	jalr	-1142(ra) # 80004244 <readi>
    800046c2:	47c1                	li	a5,16
    800046c4:	06f51163          	bne	a0,a5,80004726 <dirlink+0xa2>
    if(de.inum == 0)
    800046c8:	fc045783          	lhu	a5,-64(s0)
    800046cc:	c791                	beqz	a5,800046d8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046ce:	24c1                	addiw	s1,s1,16
    800046d0:	04c92783          	lw	a5,76(s2)
    800046d4:	fcf4ede3          	bltu	s1,a5,800046ae <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800046d8:	4639                	li	a2,14
    800046da:	85d2                	mv	a1,s4
    800046dc:	fc240513          	addi	a0,s0,-62
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	6f2080e7          	jalr	1778(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    800046e8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046ec:	4741                	li	a4,16
    800046ee:	86a6                	mv	a3,s1
    800046f0:	fc040613          	addi	a2,s0,-64
    800046f4:	4581                	li	a1,0
    800046f6:	854a                	mv	a0,s2
    800046f8:	00000097          	auipc	ra,0x0
    800046fc:	c44080e7          	jalr	-956(ra) # 8000433c <writei>
    80004700:	872a                	mv	a4,a0
    80004702:	47c1                	li	a5,16
  return 0;
    80004704:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004706:	02f71863          	bne	a4,a5,80004736 <dirlink+0xb2>
}
    8000470a:	70e2                	ld	ra,56(sp)
    8000470c:	7442                	ld	s0,48(sp)
    8000470e:	74a2                	ld	s1,40(sp)
    80004710:	7902                	ld	s2,32(sp)
    80004712:	69e2                	ld	s3,24(sp)
    80004714:	6a42                	ld	s4,16(sp)
    80004716:	6121                	addi	sp,sp,64
    80004718:	8082                	ret
    iput(ip);
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	a30080e7          	jalr	-1488(ra) # 8000414a <iput>
    return -1;
    80004722:	557d                	li	a0,-1
    80004724:	b7dd                	j	8000470a <dirlink+0x86>
      panic("dirlink read");
    80004726:	00005517          	auipc	a0,0x5
    8000472a:	1c250513          	addi	a0,a0,450 # 800098e8 <syscalls+0x1c8>
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	dfc080e7          	jalr	-516(ra) # 8000052a <panic>
    panic("dirlink");
    80004736:	00005517          	auipc	a0,0x5
    8000473a:	33a50513          	addi	a0,a0,826 # 80009a70 <syscalls+0x350>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	dec080e7          	jalr	-532(ra) # 8000052a <panic>

0000000080004746 <namei>:

struct inode*
namei(char *path)
{
    80004746:	1101                	addi	sp,sp,-32
    80004748:	ec06                	sd	ra,24(sp)
    8000474a:	e822                	sd	s0,16(sp)
    8000474c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000474e:	fe040613          	addi	a2,s0,-32
    80004752:	4581                	li	a1,0
    80004754:	00000097          	auipc	ra,0x0
    80004758:	dd0080e7          	jalr	-560(ra) # 80004524 <namex>
}
    8000475c:	60e2                	ld	ra,24(sp)
    8000475e:	6442                	ld	s0,16(sp)
    80004760:	6105                	addi	sp,sp,32
    80004762:	8082                	ret

0000000080004764 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004764:	1141                	addi	sp,sp,-16
    80004766:	e406                	sd	ra,8(sp)
    80004768:	e022                	sd	s0,0(sp)
    8000476a:	0800                	addi	s0,sp,16
    8000476c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000476e:	4585                	li	a1,1
    80004770:	00000097          	auipc	ra,0x0
    80004774:	db4080e7          	jalr	-588(ra) # 80004524 <namex>
}
    80004778:	60a2                	ld	ra,8(sp)
    8000477a:	6402                	ld	s0,0(sp)
    8000477c:	0141                	addi	sp,sp,16
    8000477e:	8082                	ret

0000000080004780 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    80004780:	1101                	addi	sp,sp,-32
    80004782:	ec22                	sd	s0,24(sp)
    80004784:	1000                	addi	s0,sp,32
    80004786:	872a                	mv	a4,a0
    80004788:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    8000478a:	00005797          	auipc	a5,0x5
    8000478e:	16e78793          	addi	a5,a5,366 # 800098f8 <syscalls+0x1d8>
    80004792:	6394                	ld	a3,0(a5)
    80004794:	fed43023          	sd	a3,-32(s0)
    80004798:	0087d683          	lhu	a3,8(a5)
    8000479c:	fed41423          	sh	a3,-24(s0)
    800047a0:	00a7c783          	lbu	a5,10(a5)
    800047a4:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800047a8:	87ae                	mv	a5,a1
    if(i<0){
    800047aa:	02074b63          	bltz	a4,800047e0 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800047ae:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800047b0:	4629                	li	a2,10
        ++p;
    800047b2:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800047b4:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800047b8:	feed                	bnez	a3,800047b2 <itoa+0x32>
    *p = '\0';
    800047ba:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800047be:	4629                	li	a2,10
    800047c0:	17fd                	addi	a5,a5,-1
    800047c2:	02c766bb          	remw	a3,a4,a2
    800047c6:	ff040593          	addi	a1,s0,-16
    800047ca:	96ae                	add	a3,a3,a1
    800047cc:	ff06c683          	lbu	a3,-16(a3)
    800047d0:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800047d4:	02c7473b          	divw	a4,a4,a2
    }while(i);
    800047d8:	f765                	bnez	a4,800047c0 <itoa+0x40>
    return b;
}
    800047da:	6462                	ld	s0,24(sp)
    800047dc:	6105                	addi	sp,sp,32
    800047de:	8082                	ret
        *p++ = '-';
    800047e0:	00158793          	addi	a5,a1,1
    800047e4:	02d00693          	li	a3,45
    800047e8:	00d58023          	sb	a3,0(a1)
        i *= -1;
    800047ec:	40e0073b          	negw	a4,a4
    800047f0:	bf7d                	j	800047ae <itoa+0x2e>

00000000800047f2 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    800047f2:	711d                	addi	sp,sp,-96
    800047f4:	ec86                	sd	ra,88(sp)
    800047f6:	e8a2                	sd	s0,80(sp)
    800047f8:	e4a6                	sd	s1,72(sp)
    800047fa:	e0ca                	sd	s2,64(sp)
    800047fc:	1080                	addi	s0,sp,96
    800047fe:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004800:	4619                	li	a2,6
    80004802:	00005597          	auipc	a1,0x5
    80004806:	10658593          	addi	a1,a1,262 # 80009908 <syscalls+0x1e8>
    8000480a:	fd040513          	addi	a0,s0,-48
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	50c080e7          	jalr	1292(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004816:	fd640593          	addi	a1,s0,-42
    8000481a:	5888                	lw	a0,48(s1)
    8000481c:	00000097          	auipc	ra,0x0
    80004820:	f64080e7          	jalr	-156(ra) # 80004780 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004824:	1684b503          	ld	a0,360(s1)
    80004828:	16050763          	beqz	a0,80004996 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000482c:	00001097          	auipc	ra,0x1
    80004830:	918080e7          	jalr	-1768(ra) # 80005144 <fileclose>

  begin_op();
    80004834:	00000097          	auipc	ra,0x0
    80004838:	444080e7          	jalr	1092(ra) # 80004c78 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000483c:	fb040593          	addi	a1,s0,-80
    80004840:	fd040513          	addi	a0,s0,-48
    80004844:	00000097          	auipc	ra,0x0
    80004848:	f20080e7          	jalr	-224(ra) # 80004764 <nameiparent>
    8000484c:	892a                	mv	s2,a0
    8000484e:	cd69                	beqz	a0,80004928 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	740080e7          	jalr	1856(ra) # 80003f90 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004858:	00005597          	auipc	a1,0x5
    8000485c:	0b858593          	addi	a1,a1,184 # 80009910 <syscalls+0x1f0>
    80004860:	fb040513          	addi	a0,s0,-80
    80004864:	00000097          	auipc	ra,0x0
    80004868:	bf6080e7          	jalr	-1034(ra) # 8000445a <namecmp>
    8000486c:	c57d                	beqz	a0,8000495a <removeSwapFile+0x168>
    8000486e:	00005597          	auipc	a1,0x5
    80004872:	0aa58593          	addi	a1,a1,170 # 80009918 <syscalls+0x1f8>
    80004876:	fb040513          	addi	a0,s0,-80
    8000487a:	00000097          	auipc	ra,0x0
    8000487e:	be0080e7          	jalr	-1056(ra) # 8000445a <namecmp>
    80004882:	cd61                	beqz	a0,8000495a <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80004884:	fac40613          	addi	a2,s0,-84
    80004888:	fb040593          	addi	a1,s0,-80
    8000488c:	854a                	mv	a0,s2
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	be6080e7          	jalr	-1050(ra) # 80004474 <dirlookup>
    80004896:	84aa                	mv	s1,a0
    80004898:	c169                	beqz	a0,8000495a <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	6f6080e7          	jalr	1782(ra) # 80003f90 <ilock>

  if(ip->nlink < 1)
    800048a2:	04a49783          	lh	a5,74(s1)
    800048a6:	08f05763          	blez	a5,80004934 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800048aa:	04449703          	lh	a4,68(s1)
    800048ae:	4785                	li	a5,1
    800048b0:	08f70a63          	beq	a4,a5,80004944 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800048b4:	4641                	li	a2,16
    800048b6:	4581                	li	a1,0
    800048b8:	fc040513          	addi	a0,s0,-64
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	402080e7          	jalr	1026(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048c4:	4741                	li	a4,16
    800048c6:	fac42683          	lw	a3,-84(s0)
    800048ca:	fc040613          	addi	a2,s0,-64
    800048ce:	4581                	li	a1,0
    800048d0:	854a                	mv	a0,s2
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	a6a080e7          	jalr	-1430(ra) # 8000433c <writei>
    800048da:	47c1                	li	a5,16
    800048dc:	08f51a63          	bne	a0,a5,80004970 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800048e0:	04449703          	lh	a4,68(s1)
    800048e4:	4785                	li	a5,1
    800048e6:	08f70d63          	beq	a4,a5,80004980 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800048ea:	854a                	mv	a0,s2
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	906080e7          	jalr	-1786(ra) # 800041f2 <iunlockput>

  ip->nlink--;
    800048f4:	04a4d783          	lhu	a5,74(s1)
    800048f8:	37fd                	addiw	a5,a5,-1
    800048fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800048fe:	8526                	mv	a0,s1
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	5c6080e7          	jalr	1478(ra) # 80003ec6 <iupdate>
  iunlockput(ip);
    80004908:	8526                	mv	a0,s1
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	8e8080e7          	jalr	-1816(ra) # 800041f2 <iunlockput>

  end_op();
    80004912:	00000097          	auipc	ra,0x0
    80004916:	3e6080e7          	jalr	998(ra) # 80004cf8 <end_op>

  return 0;
    8000491a:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    8000491c:	60e6                	ld	ra,88(sp)
    8000491e:	6446                	ld	s0,80(sp)
    80004920:	64a6                	ld	s1,72(sp)
    80004922:	6906                	ld	s2,64(sp)
    80004924:	6125                	addi	sp,sp,96
    80004926:	8082                	ret
    end_op();
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	3d0080e7          	jalr	976(ra) # 80004cf8 <end_op>
    return -1;
    80004930:	557d                	li	a0,-1
    80004932:	b7ed                	j	8000491c <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004934:	00005517          	auipc	a0,0x5
    80004938:	fec50513          	addi	a0,a0,-20 # 80009920 <syscalls+0x200>
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	bee080e7          	jalr	-1042(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004944:	8526                	mv	a0,s1
    80004946:	00002097          	auipc	ra,0x2
    8000494a:	866080e7          	jalr	-1946(ra) # 800061ac <isdirempty>
    8000494e:	f13d                	bnez	a0,800048b4 <removeSwapFile+0xc2>
    iunlockput(ip);
    80004950:	8526                	mv	a0,s1
    80004952:	00000097          	auipc	ra,0x0
    80004956:	8a0080e7          	jalr	-1888(ra) # 800041f2 <iunlockput>
    iunlockput(dp);
    8000495a:	854a                	mv	a0,s2
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	896080e7          	jalr	-1898(ra) # 800041f2 <iunlockput>
    end_op();
    80004964:	00000097          	auipc	ra,0x0
    80004968:	394080e7          	jalr	916(ra) # 80004cf8 <end_op>
    return -1;
    8000496c:	557d                	li	a0,-1
    8000496e:	b77d                	j	8000491c <removeSwapFile+0x12a>
    panic("unlink: writei");
    80004970:	00005517          	auipc	a0,0x5
    80004974:	fc850513          	addi	a0,a0,-56 # 80009938 <syscalls+0x218>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	bb2080e7          	jalr	-1102(ra) # 8000052a <panic>
    dp->nlink--;
    80004980:	04a95783          	lhu	a5,74(s2)
    80004984:	37fd                	addiw	a5,a5,-1
    80004986:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000498a:	854a                	mv	a0,s2
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	53a080e7          	jalr	1338(ra) # 80003ec6 <iupdate>
    80004994:	bf99                	j	800048ea <removeSwapFile+0xf8>
    return -1;
    80004996:	557d                	li	a0,-1
    80004998:	b751                	j	8000491c <removeSwapFile+0x12a>

000000008000499a <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    8000499a:	7179                	addi	sp,sp,-48
    8000499c:	f406                	sd	ra,40(sp)
    8000499e:	f022                	sd	s0,32(sp)
    800049a0:	ec26                	sd	s1,24(sp)
    800049a2:	e84a                	sd	s2,16(sp)
    800049a4:	1800                	addi	s0,sp,48
    800049a6:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800049a8:	4619                	li	a2,6
    800049aa:	00005597          	auipc	a1,0x5
    800049ae:	f5e58593          	addi	a1,a1,-162 # 80009908 <syscalls+0x1e8>
    800049b2:	fd040513          	addi	a0,s0,-48
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	364080e7          	jalr	868(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800049be:	fd640593          	addi	a1,s0,-42
    800049c2:	5888                	lw	a0,48(s1)
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	dbc080e7          	jalr	-580(ra) # 80004780 <itoa>

  begin_op();
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	2ac080e7          	jalr	684(ra) # 80004c78 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    800049d4:	4681                	li	a3,0
    800049d6:	4601                	li	a2,0
    800049d8:	4589                	li	a1,2
    800049da:	fd040513          	addi	a0,s0,-48
    800049de:	00002097          	auipc	ra,0x2
    800049e2:	9c2080e7          	jalr	-1598(ra) # 800063a0 <create>
    800049e6:	892a                	mv	s2,a0
  iunlock(in);
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	66a080e7          	jalr	1642(ra) # 80004052 <iunlock>
  p->swapFile = filealloc();
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	698080e7          	jalr	1688(ra) # 80005088 <filealloc>
    800049f8:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    800049fc:	cd1d                	beqz	a0,80004a3a <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    800049fe:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004a02:	1684b703          	ld	a4,360(s1)
    80004a06:	4789                	li	a5,2
    80004a08:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004a0a:	1684b703          	ld	a4,360(s1)
    80004a0e:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004a12:	1684b703          	ld	a4,360(s1)
    80004a16:	4685                	li	a3,1
    80004a18:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004a1c:	1684b703          	ld	a4,360(s1)
    80004a20:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	2d4080e7          	jalr	724(ra) # 80004cf8 <end_op>

    return 0;
}
    80004a2c:	4501                	li	a0,0
    80004a2e:	70a2                	ld	ra,40(sp)
    80004a30:	7402                	ld	s0,32(sp)
    80004a32:	64e2                	ld	s1,24(sp)
    80004a34:	6942                	ld	s2,16(sp)
    80004a36:	6145                	addi	sp,sp,48
    80004a38:	8082                	ret
    panic("no slot for files on /store");
    80004a3a:	00005517          	auipc	a0,0x5
    80004a3e:	f0e50513          	addi	a0,a0,-242 # 80009948 <syscalls+0x228>
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	ae8080e7          	jalr	-1304(ra) # 8000052a <panic>

0000000080004a4a <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a4a:	1141                	addi	sp,sp,-16
    80004a4c:	e406                	sd	ra,8(sp)
    80004a4e:	e022                	sd	s0,0(sp)
    80004a50:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a52:	16853783          	ld	a5,360(a0)
    80004a56:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004a58:	8636                	mv	a2,a3
    80004a5a:	16853503          	ld	a0,360(a0)
    80004a5e:	00001097          	auipc	ra,0x1
    80004a62:	ad8080e7          	jalr	-1320(ra) # 80005536 <kfilewrite>
}
    80004a66:	60a2                	ld	ra,8(sp)
    80004a68:	6402                	ld	s0,0(sp)
    80004a6a:	0141                	addi	sp,sp,16
    80004a6c:	8082                	ret

0000000080004a6e <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004a6e:	1141                	addi	sp,sp,-16
    80004a70:	e406                	sd	ra,8(sp)
    80004a72:	e022                	sd	s0,0(sp)
    80004a74:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004a76:	16853783          	ld	a5,360(a0)
    80004a7a:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004a7c:	8636                	mv	a2,a3
    80004a7e:	16853503          	ld	a0,360(a0)
    80004a82:	00001097          	auipc	ra,0x1
    80004a86:	9f2080e7          	jalr	-1550(ra) # 80005474 <kfileread>
    80004a8a:	60a2                	ld	ra,8(sp)
    80004a8c:	6402                	ld	s0,0(sp)
    80004a8e:	0141                	addi	sp,sp,16
    80004a90:	8082                	ret

0000000080004a92 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a92:	1101                	addi	sp,sp,-32
    80004a94:	ec06                	sd	ra,24(sp)
    80004a96:	e822                	sd	s0,16(sp)
    80004a98:	e426                	sd	s1,8(sp)
    80004a9a:	e04a                	sd	s2,0(sp)
    80004a9c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004a9e:	00026917          	auipc	s2,0x26
    80004aa2:	bd290913          	addi	s2,s2,-1070 # 8002a670 <log>
    80004aa6:	01892583          	lw	a1,24(s2)
    80004aaa:	02892503          	lw	a0,40(s2)
    80004aae:	fffff097          	auipc	ra,0xfffff
    80004ab2:	cde080e7          	jalr	-802(ra) # 8000378c <bread>
    80004ab6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004ab8:	02c92683          	lw	a3,44(s2)
    80004abc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004abe:	02d05863          	blez	a3,80004aee <write_head+0x5c>
    80004ac2:	00026797          	auipc	a5,0x26
    80004ac6:	bde78793          	addi	a5,a5,-1058 # 8002a6a0 <log+0x30>
    80004aca:	05c50713          	addi	a4,a0,92
    80004ace:	36fd                	addiw	a3,a3,-1
    80004ad0:	02069613          	slli	a2,a3,0x20
    80004ad4:	01e65693          	srli	a3,a2,0x1e
    80004ad8:	00026617          	auipc	a2,0x26
    80004adc:	bcc60613          	addi	a2,a2,-1076 # 8002a6a4 <log+0x34>
    80004ae0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004ae2:	4390                	lw	a2,0(a5)
    80004ae4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004ae6:	0791                	addi	a5,a5,4
    80004ae8:	0711                	addi	a4,a4,4
    80004aea:	fed79ce3          	bne	a5,a3,80004ae2 <write_head+0x50>
  }
  bwrite(buf);
    80004aee:	8526                	mv	a0,s1
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	d8e080e7          	jalr	-626(ra) # 8000387e <bwrite>
  brelse(buf);
    80004af8:	8526                	mv	a0,s1
    80004afa:	fffff097          	auipc	ra,0xfffff
    80004afe:	dc2080e7          	jalr	-574(ra) # 800038bc <brelse>
}
    80004b02:	60e2                	ld	ra,24(sp)
    80004b04:	6442                	ld	s0,16(sp)
    80004b06:	64a2                	ld	s1,8(sp)
    80004b08:	6902                	ld	s2,0(sp)
    80004b0a:	6105                	addi	sp,sp,32
    80004b0c:	8082                	ret

0000000080004b0e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b0e:	00026797          	auipc	a5,0x26
    80004b12:	b8e7a783          	lw	a5,-1138(a5) # 8002a69c <log+0x2c>
    80004b16:	0af05d63          	blez	a5,80004bd0 <install_trans+0xc2>
{
    80004b1a:	7139                	addi	sp,sp,-64
    80004b1c:	fc06                	sd	ra,56(sp)
    80004b1e:	f822                	sd	s0,48(sp)
    80004b20:	f426                	sd	s1,40(sp)
    80004b22:	f04a                	sd	s2,32(sp)
    80004b24:	ec4e                	sd	s3,24(sp)
    80004b26:	e852                	sd	s4,16(sp)
    80004b28:	e456                	sd	s5,8(sp)
    80004b2a:	e05a                	sd	s6,0(sp)
    80004b2c:	0080                	addi	s0,sp,64
    80004b2e:	8b2a                	mv	s6,a0
    80004b30:	00026a97          	auipc	s5,0x26
    80004b34:	b70a8a93          	addi	s5,s5,-1168 # 8002a6a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b38:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b3a:	00026997          	auipc	s3,0x26
    80004b3e:	b3698993          	addi	s3,s3,-1226 # 8002a670 <log>
    80004b42:	a00d                	j	80004b64 <install_trans+0x56>
    brelse(lbuf);
    80004b44:	854a                	mv	a0,s2
    80004b46:	fffff097          	auipc	ra,0xfffff
    80004b4a:	d76080e7          	jalr	-650(ra) # 800038bc <brelse>
    brelse(dbuf);
    80004b4e:	8526                	mv	a0,s1
    80004b50:	fffff097          	auipc	ra,0xfffff
    80004b54:	d6c080e7          	jalr	-660(ra) # 800038bc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b58:	2a05                	addiw	s4,s4,1
    80004b5a:	0a91                	addi	s5,s5,4
    80004b5c:	02c9a783          	lw	a5,44(s3)
    80004b60:	04fa5e63          	bge	s4,a5,80004bbc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b64:	0189a583          	lw	a1,24(s3)
    80004b68:	014585bb          	addw	a1,a1,s4
    80004b6c:	2585                	addiw	a1,a1,1
    80004b6e:	0289a503          	lw	a0,40(s3)
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	c1a080e7          	jalr	-998(ra) # 8000378c <bread>
    80004b7a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b7c:	000aa583          	lw	a1,0(s5)
    80004b80:	0289a503          	lw	a0,40(s3)
    80004b84:	fffff097          	auipc	ra,0xfffff
    80004b88:	c08080e7          	jalr	-1016(ra) # 8000378c <bread>
    80004b8c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b8e:	40000613          	li	a2,1024
    80004b92:	05890593          	addi	a1,s2,88
    80004b96:	05850513          	addi	a0,a0,88
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	180080e7          	jalr	384(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	cda080e7          	jalr	-806(ra) # 8000387e <bwrite>
    if(recovering == 0)
    80004bac:	f80b1ce3          	bnez	s6,80004b44 <install_trans+0x36>
      bunpin(dbuf);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	fffff097          	auipc	ra,0xfffff
    80004bb6:	de4080e7          	jalr	-540(ra) # 80003996 <bunpin>
    80004bba:	b769                	j	80004b44 <install_trans+0x36>
}
    80004bbc:	70e2                	ld	ra,56(sp)
    80004bbe:	7442                	ld	s0,48(sp)
    80004bc0:	74a2                	ld	s1,40(sp)
    80004bc2:	7902                	ld	s2,32(sp)
    80004bc4:	69e2                	ld	s3,24(sp)
    80004bc6:	6a42                	ld	s4,16(sp)
    80004bc8:	6aa2                	ld	s5,8(sp)
    80004bca:	6b02                	ld	s6,0(sp)
    80004bcc:	6121                	addi	sp,sp,64
    80004bce:	8082                	ret
    80004bd0:	8082                	ret

0000000080004bd2 <initlog>:
{
    80004bd2:	7179                	addi	sp,sp,-48
    80004bd4:	f406                	sd	ra,40(sp)
    80004bd6:	f022                	sd	s0,32(sp)
    80004bd8:	ec26                	sd	s1,24(sp)
    80004bda:	e84a                	sd	s2,16(sp)
    80004bdc:	e44e                	sd	s3,8(sp)
    80004bde:	1800                	addi	s0,sp,48
    80004be0:	892a                	mv	s2,a0
    80004be2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004be4:	00026497          	auipc	s1,0x26
    80004be8:	a8c48493          	addi	s1,s1,-1396 # 8002a670 <log>
    80004bec:	00005597          	auipc	a1,0x5
    80004bf0:	d7c58593          	addi	a1,a1,-644 # 80009968 <syscalls+0x248>
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	f3c080e7          	jalr	-196(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004bfe:	0149a583          	lw	a1,20(s3)
    80004c02:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c04:	0109a783          	lw	a5,16(s3)
    80004c08:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c0a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c0e:	854a                	mv	a0,s2
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	b7c080e7          	jalr	-1156(ra) # 8000378c <bread>
  log.lh.n = lh->n;
    80004c18:	4d34                	lw	a3,88(a0)
    80004c1a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c1c:	02d05663          	blez	a3,80004c48 <initlog+0x76>
    80004c20:	05c50793          	addi	a5,a0,92
    80004c24:	00026717          	auipc	a4,0x26
    80004c28:	a7c70713          	addi	a4,a4,-1412 # 8002a6a0 <log+0x30>
    80004c2c:	36fd                	addiw	a3,a3,-1
    80004c2e:	02069613          	slli	a2,a3,0x20
    80004c32:	01e65693          	srli	a3,a2,0x1e
    80004c36:	06050613          	addi	a2,a0,96
    80004c3a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004c3c:	4390                	lw	a2,0(a5)
    80004c3e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004c40:	0791                	addi	a5,a5,4
    80004c42:	0711                	addi	a4,a4,4
    80004c44:	fed79ce3          	bne	a5,a3,80004c3c <initlog+0x6a>
  brelse(buf);
    80004c48:	fffff097          	auipc	ra,0xfffff
    80004c4c:	c74080e7          	jalr	-908(ra) # 800038bc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c50:	4505                	li	a0,1
    80004c52:	00000097          	auipc	ra,0x0
    80004c56:	ebc080e7          	jalr	-324(ra) # 80004b0e <install_trans>
  log.lh.n = 0;
    80004c5a:	00026797          	auipc	a5,0x26
    80004c5e:	a407a123          	sw	zero,-1470(a5) # 8002a69c <log+0x2c>
  write_head(); // clear the log
    80004c62:	00000097          	auipc	ra,0x0
    80004c66:	e30080e7          	jalr	-464(ra) # 80004a92 <write_head>
}
    80004c6a:	70a2                	ld	ra,40(sp)
    80004c6c:	7402                	ld	s0,32(sp)
    80004c6e:	64e2                	ld	s1,24(sp)
    80004c70:	6942                	ld	s2,16(sp)
    80004c72:	69a2                	ld	s3,8(sp)
    80004c74:	6145                	addi	sp,sp,48
    80004c76:	8082                	ret

0000000080004c78 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c78:	1101                	addi	sp,sp,-32
    80004c7a:	ec06                	sd	ra,24(sp)
    80004c7c:	e822                	sd	s0,16(sp)
    80004c7e:	e426                	sd	s1,8(sp)
    80004c80:	e04a                	sd	s2,0(sp)
    80004c82:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c84:	00026517          	auipc	a0,0x26
    80004c88:	9ec50513          	addi	a0,a0,-1556 # 8002a670 <log>
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	f36080e7          	jalr	-202(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004c94:	00026497          	auipc	s1,0x26
    80004c98:	9dc48493          	addi	s1,s1,-1572 # 8002a670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c9c:	4979                	li	s2,30
    80004c9e:	a039                	j	80004cac <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ca0:	85a6                	mv	a1,s1
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	3b0080e7          	jalr	944(ra) # 80002054 <sleep>
    if(log.committing){
    80004cac:	50dc                	lw	a5,36(s1)
    80004cae:	fbed                	bnez	a5,80004ca0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cb0:	509c                	lw	a5,32(s1)
    80004cb2:	0017871b          	addiw	a4,a5,1
    80004cb6:	0007069b          	sext.w	a3,a4
    80004cba:	0027179b          	slliw	a5,a4,0x2
    80004cbe:	9fb9                	addw	a5,a5,a4
    80004cc0:	0017979b          	slliw	a5,a5,0x1
    80004cc4:	54d8                	lw	a4,44(s1)
    80004cc6:	9fb9                	addw	a5,a5,a4
    80004cc8:	00f95963          	bge	s2,a5,80004cda <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004ccc:	85a6                	mv	a1,s1
    80004cce:	8526                	mv	a0,s1
    80004cd0:	ffffd097          	auipc	ra,0xffffd
    80004cd4:	384080e7          	jalr	900(ra) # 80002054 <sleep>
    80004cd8:	bfd1                	j	80004cac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004cda:	00026517          	auipc	a0,0x26
    80004cde:	99650513          	addi	a0,a0,-1642 # 8002a670 <log>
    80004ce2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	f92080e7          	jalr	-110(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004cec:	60e2                	ld	ra,24(sp)
    80004cee:	6442                	ld	s0,16(sp)
    80004cf0:	64a2                	ld	s1,8(sp)
    80004cf2:	6902                	ld	s2,0(sp)
    80004cf4:	6105                	addi	sp,sp,32
    80004cf6:	8082                	ret

0000000080004cf8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004cf8:	7139                	addi	sp,sp,-64
    80004cfa:	fc06                	sd	ra,56(sp)
    80004cfc:	f822                	sd	s0,48(sp)
    80004cfe:	f426                	sd	s1,40(sp)
    80004d00:	f04a                	sd	s2,32(sp)
    80004d02:	ec4e                	sd	s3,24(sp)
    80004d04:	e852                	sd	s4,16(sp)
    80004d06:	e456                	sd	s5,8(sp)
    80004d08:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d0a:	00026497          	auipc	s1,0x26
    80004d0e:	96648493          	addi	s1,s1,-1690 # 8002a670 <log>
    80004d12:	8526                	mv	a0,s1
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	eae080e7          	jalr	-338(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004d1c:	509c                	lw	a5,32(s1)
    80004d1e:	37fd                	addiw	a5,a5,-1
    80004d20:	0007891b          	sext.w	s2,a5
    80004d24:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d26:	50dc                	lw	a5,36(s1)
    80004d28:	e7b9                	bnez	a5,80004d76 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d2a:	04091e63          	bnez	s2,80004d86 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004d2e:	00026497          	auipc	s1,0x26
    80004d32:	94248493          	addi	s1,s1,-1726 # 8002a670 <log>
    80004d36:	4785                	li	a5,1
    80004d38:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	f3a080e7          	jalr	-198(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d44:	54dc                	lw	a5,44(s1)
    80004d46:	06f04763          	bgtz	a5,80004db4 <end_op+0xbc>
    acquire(&log.lock);
    80004d4a:	00026497          	auipc	s1,0x26
    80004d4e:	92648493          	addi	s1,s1,-1754 # 8002a670 <log>
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	e6e080e7          	jalr	-402(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004d5c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffd097          	auipc	ra,0xffffd
    80004d66:	356080e7          	jalr	854(ra) # 800020b8 <wakeup>
    release(&log.lock);
    80004d6a:	8526                	mv	a0,s1
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	f0a080e7          	jalr	-246(ra) # 80000c76 <release>
}
    80004d74:	a03d                	j	80004da2 <end_op+0xaa>
    panic("log.committing");
    80004d76:	00005517          	auipc	a0,0x5
    80004d7a:	bfa50513          	addi	a0,a0,-1030 # 80009970 <syscalls+0x250>
    80004d7e:	ffffb097          	auipc	ra,0xffffb
    80004d82:	7ac080e7          	jalr	1964(ra) # 8000052a <panic>
    wakeup(&log);
    80004d86:	00026497          	auipc	s1,0x26
    80004d8a:	8ea48493          	addi	s1,s1,-1814 # 8002a670 <log>
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	328080e7          	jalr	808(ra) # 800020b8 <wakeup>
  release(&log.lock);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	edc080e7          	jalr	-292(ra) # 80000c76 <release>
}
    80004da2:	70e2                	ld	ra,56(sp)
    80004da4:	7442                	ld	s0,48(sp)
    80004da6:	74a2                	ld	s1,40(sp)
    80004da8:	7902                	ld	s2,32(sp)
    80004daa:	69e2                	ld	s3,24(sp)
    80004dac:	6a42                	ld	s4,16(sp)
    80004dae:	6aa2                	ld	s5,8(sp)
    80004db0:	6121                	addi	sp,sp,64
    80004db2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004db4:	00026a97          	auipc	s5,0x26
    80004db8:	8eca8a93          	addi	s5,s5,-1812 # 8002a6a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dbc:	00026a17          	auipc	s4,0x26
    80004dc0:	8b4a0a13          	addi	s4,s4,-1868 # 8002a670 <log>
    80004dc4:	018a2583          	lw	a1,24(s4)
    80004dc8:	012585bb          	addw	a1,a1,s2
    80004dcc:	2585                	addiw	a1,a1,1
    80004dce:	028a2503          	lw	a0,40(s4)
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	9ba080e7          	jalr	-1606(ra) # 8000378c <bread>
    80004dda:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004ddc:	000aa583          	lw	a1,0(s5)
    80004de0:	028a2503          	lw	a0,40(s4)
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	9a8080e7          	jalr	-1624(ra) # 8000378c <bread>
    80004dec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004dee:	40000613          	li	a2,1024
    80004df2:	05850593          	addi	a1,a0,88
    80004df6:	05848513          	addi	a0,s1,88
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	f20080e7          	jalr	-224(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004e02:	8526                	mv	a0,s1
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	a7a080e7          	jalr	-1414(ra) # 8000387e <bwrite>
    brelse(from);
    80004e0c:	854e                	mv	a0,s3
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	aae080e7          	jalr	-1362(ra) # 800038bc <brelse>
    brelse(to);
    80004e16:	8526                	mv	a0,s1
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	aa4080e7          	jalr	-1372(ra) # 800038bc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e20:	2905                	addiw	s2,s2,1
    80004e22:	0a91                	addi	s5,s5,4
    80004e24:	02ca2783          	lw	a5,44(s4)
    80004e28:	f8f94ee3          	blt	s2,a5,80004dc4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e2c:	00000097          	auipc	ra,0x0
    80004e30:	c66080e7          	jalr	-922(ra) # 80004a92 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e34:	4501                	li	a0,0
    80004e36:	00000097          	auipc	ra,0x0
    80004e3a:	cd8080e7          	jalr	-808(ra) # 80004b0e <install_trans>
    log.lh.n = 0;
    80004e3e:	00026797          	auipc	a5,0x26
    80004e42:	8407af23          	sw	zero,-1954(a5) # 8002a69c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e46:	00000097          	auipc	ra,0x0
    80004e4a:	c4c080e7          	jalr	-948(ra) # 80004a92 <write_head>
    80004e4e:	bdf5                	j	80004d4a <end_op+0x52>

0000000080004e50 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e50:	1101                	addi	sp,sp,-32
    80004e52:	ec06                	sd	ra,24(sp)
    80004e54:	e822                	sd	s0,16(sp)
    80004e56:	e426                	sd	s1,8(sp)
    80004e58:	e04a                	sd	s2,0(sp)
    80004e5a:	1000                	addi	s0,sp,32
    80004e5c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e5e:	00026917          	auipc	s2,0x26
    80004e62:	81290913          	addi	s2,s2,-2030 # 8002a670 <log>
    80004e66:	854a                	mv	a0,s2
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	d5a080e7          	jalr	-678(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e70:	02c92603          	lw	a2,44(s2)
    80004e74:	47f5                	li	a5,29
    80004e76:	06c7c563          	blt	a5,a2,80004ee0 <log_write+0x90>
    80004e7a:	00026797          	auipc	a5,0x26
    80004e7e:	8127a783          	lw	a5,-2030(a5) # 8002a68c <log+0x1c>
    80004e82:	37fd                	addiw	a5,a5,-1
    80004e84:	04f65e63          	bge	a2,a5,80004ee0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e88:	00026797          	auipc	a5,0x26
    80004e8c:	8087a783          	lw	a5,-2040(a5) # 8002a690 <log+0x20>
    80004e90:	06f05063          	blez	a5,80004ef0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e94:	4781                	li	a5,0
    80004e96:	06c05563          	blez	a2,80004f00 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004e9a:	44cc                	lw	a1,12(s1)
    80004e9c:	00026717          	auipc	a4,0x26
    80004ea0:	80470713          	addi	a4,a4,-2044 # 8002a6a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ea4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004ea6:	4314                	lw	a3,0(a4)
    80004ea8:	04b68c63          	beq	a3,a1,80004f00 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004eac:	2785                	addiw	a5,a5,1
    80004eae:	0711                	addi	a4,a4,4
    80004eb0:	fef61be3          	bne	a2,a5,80004ea6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004eb4:	0621                	addi	a2,a2,8
    80004eb6:	060a                	slli	a2,a2,0x2
    80004eb8:	00025797          	auipc	a5,0x25
    80004ebc:	7b878793          	addi	a5,a5,1976 # 8002a670 <log>
    80004ec0:	963e                	add	a2,a2,a5
    80004ec2:	44dc                	lw	a5,12(s1)
    80004ec4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	a92080e7          	jalr	-1390(ra) # 8000395a <bpin>
    log.lh.n++;
    80004ed0:	00025717          	auipc	a4,0x25
    80004ed4:	7a070713          	addi	a4,a4,1952 # 8002a670 <log>
    80004ed8:	575c                	lw	a5,44(a4)
    80004eda:	2785                	addiw	a5,a5,1
    80004edc:	d75c                	sw	a5,44(a4)
    80004ede:	a835                	j	80004f1a <log_write+0xca>
    panic("too big a transaction");
    80004ee0:	00005517          	auipc	a0,0x5
    80004ee4:	aa050513          	addi	a0,a0,-1376 # 80009980 <syscalls+0x260>
    80004ee8:	ffffb097          	auipc	ra,0xffffb
    80004eec:	642080e7          	jalr	1602(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004ef0:	00005517          	auipc	a0,0x5
    80004ef4:	aa850513          	addi	a0,a0,-1368 # 80009998 <syscalls+0x278>
    80004ef8:	ffffb097          	auipc	ra,0xffffb
    80004efc:	632080e7          	jalr	1586(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004f00:	00878713          	addi	a4,a5,8
    80004f04:	00271693          	slli	a3,a4,0x2
    80004f08:	00025717          	auipc	a4,0x25
    80004f0c:	76870713          	addi	a4,a4,1896 # 8002a670 <log>
    80004f10:	9736                	add	a4,a4,a3
    80004f12:	44d4                	lw	a3,12(s1)
    80004f14:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f16:	faf608e3          	beq	a2,a5,80004ec6 <log_write+0x76>
  }
  release(&log.lock);
    80004f1a:	00025517          	auipc	a0,0x25
    80004f1e:	75650513          	addi	a0,a0,1878 # 8002a670 <log>
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	d54080e7          	jalr	-684(ra) # 80000c76 <release>
}
    80004f2a:	60e2                	ld	ra,24(sp)
    80004f2c:	6442                	ld	s0,16(sp)
    80004f2e:	64a2                	ld	s1,8(sp)
    80004f30:	6902                	ld	s2,0(sp)
    80004f32:	6105                	addi	sp,sp,32
    80004f34:	8082                	ret

0000000080004f36 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f36:	1101                	addi	sp,sp,-32
    80004f38:	ec06                	sd	ra,24(sp)
    80004f3a:	e822                	sd	s0,16(sp)
    80004f3c:	e426                	sd	s1,8(sp)
    80004f3e:	e04a                	sd	s2,0(sp)
    80004f40:	1000                	addi	s0,sp,32
    80004f42:	84aa                	mv	s1,a0
    80004f44:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f46:	00005597          	auipc	a1,0x5
    80004f4a:	a7258593          	addi	a1,a1,-1422 # 800099b8 <syscalls+0x298>
    80004f4e:	0521                	addi	a0,a0,8
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	be2080e7          	jalr	-1054(ra) # 80000b32 <initlock>
  lk->name = name;
    80004f58:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f5c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f60:	0204a423          	sw	zero,40(s1)
}
    80004f64:	60e2                	ld	ra,24(sp)
    80004f66:	6442                	ld	s0,16(sp)
    80004f68:	64a2                	ld	s1,8(sp)
    80004f6a:	6902                	ld	s2,0(sp)
    80004f6c:	6105                	addi	sp,sp,32
    80004f6e:	8082                	ret

0000000080004f70 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f70:	1101                	addi	sp,sp,-32
    80004f72:	ec06                	sd	ra,24(sp)
    80004f74:	e822                	sd	s0,16(sp)
    80004f76:	e426                	sd	s1,8(sp)
    80004f78:	e04a                	sd	s2,0(sp)
    80004f7a:	1000                	addi	s0,sp,32
    80004f7c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f7e:	00850913          	addi	s2,a0,8
    80004f82:	854a                	mv	a0,s2
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	c3e080e7          	jalr	-962(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004f8c:	409c                	lw	a5,0(s1)
    80004f8e:	cb89                	beqz	a5,80004fa0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f90:	85ca                	mv	a1,s2
    80004f92:	8526                	mv	a0,s1
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	0c0080e7          	jalr	192(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004f9c:	409c                	lw	a5,0(s1)
    80004f9e:	fbed                	bnez	a5,80004f90 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fa0:	4785                	li	a5,1
    80004fa2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fa4:	ffffd097          	auipc	ra,0xffffd
    80004fa8:	a30080e7          	jalr	-1488(ra) # 800019d4 <myproc>
    80004fac:	591c                	lw	a5,48(a0)
    80004fae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fb0:	854a                	mv	a0,s2
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	cc4080e7          	jalr	-828(ra) # 80000c76 <release>
}
    80004fba:	60e2                	ld	ra,24(sp)
    80004fbc:	6442                	ld	s0,16(sp)
    80004fbe:	64a2                	ld	s1,8(sp)
    80004fc0:	6902                	ld	s2,0(sp)
    80004fc2:	6105                	addi	sp,sp,32
    80004fc4:	8082                	ret

0000000080004fc6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004fc6:	1101                	addi	sp,sp,-32
    80004fc8:	ec06                	sd	ra,24(sp)
    80004fca:	e822                	sd	s0,16(sp)
    80004fcc:	e426                	sd	s1,8(sp)
    80004fce:	e04a                	sd	s2,0(sp)
    80004fd0:	1000                	addi	s0,sp,32
    80004fd2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fd4:	00850913          	addi	s2,a0,8
    80004fd8:	854a                	mv	a0,s2
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	be8080e7          	jalr	-1048(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004fe2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fe6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004fea:	8526                	mv	a0,s1
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	0cc080e7          	jalr	204(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    80004ff4:	854a                	mv	a0,s2
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	c80080e7          	jalr	-896(ra) # 80000c76 <release>
}
    80004ffe:	60e2                	ld	ra,24(sp)
    80005000:	6442                	ld	s0,16(sp)
    80005002:	64a2                	ld	s1,8(sp)
    80005004:	6902                	ld	s2,0(sp)
    80005006:	6105                	addi	sp,sp,32
    80005008:	8082                	ret

000000008000500a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000500a:	7179                	addi	sp,sp,-48
    8000500c:	f406                	sd	ra,40(sp)
    8000500e:	f022                	sd	s0,32(sp)
    80005010:	ec26                	sd	s1,24(sp)
    80005012:	e84a                	sd	s2,16(sp)
    80005014:	e44e                	sd	s3,8(sp)
    80005016:	1800                	addi	s0,sp,48
    80005018:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000501a:	00850913          	addi	s2,a0,8
    8000501e:	854a                	mv	a0,s2
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	ba2080e7          	jalr	-1118(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005028:	409c                	lw	a5,0(s1)
    8000502a:	ef99                	bnez	a5,80005048 <holdingsleep+0x3e>
    8000502c:	4481                	li	s1,0
  release(&lk->lk);
    8000502e:	854a                	mv	a0,s2
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	c46080e7          	jalr	-954(ra) # 80000c76 <release>
  return r;
}
    80005038:	8526                	mv	a0,s1
    8000503a:	70a2                	ld	ra,40(sp)
    8000503c:	7402                	ld	s0,32(sp)
    8000503e:	64e2                	ld	s1,24(sp)
    80005040:	6942                	ld	s2,16(sp)
    80005042:	69a2                	ld	s3,8(sp)
    80005044:	6145                	addi	sp,sp,48
    80005046:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005048:	0284a983          	lw	s3,40(s1)
    8000504c:	ffffd097          	auipc	ra,0xffffd
    80005050:	988080e7          	jalr	-1656(ra) # 800019d4 <myproc>
    80005054:	5904                	lw	s1,48(a0)
    80005056:	413484b3          	sub	s1,s1,s3
    8000505a:	0014b493          	seqz	s1,s1
    8000505e:	bfc1                	j	8000502e <holdingsleep+0x24>

0000000080005060 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005060:	1141                	addi	sp,sp,-16
    80005062:	e406                	sd	ra,8(sp)
    80005064:	e022                	sd	s0,0(sp)
    80005066:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005068:	00005597          	auipc	a1,0x5
    8000506c:	96058593          	addi	a1,a1,-1696 # 800099c8 <syscalls+0x2a8>
    80005070:	00025517          	auipc	a0,0x25
    80005074:	74850513          	addi	a0,a0,1864 # 8002a7b8 <ftable>
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	aba080e7          	jalr	-1350(ra) # 80000b32 <initlock>
}
    80005080:	60a2                	ld	ra,8(sp)
    80005082:	6402                	ld	s0,0(sp)
    80005084:	0141                	addi	sp,sp,16
    80005086:	8082                	ret

0000000080005088 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005088:	1101                	addi	sp,sp,-32
    8000508a:	ec06                	sd	ra,24(sp)
    8000508c:	e822                	sd	s0,16(sp)
    8000508e:	e426                	sd	s1,8(sp)
    80005090:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005092:	00025517          	auipc	a0,0x25
    80005096:	72650513          	addi	a0,a0,1830 # 8002a7b8 <ftable>
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	b28080e7          	jalr	-1240(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050a2:	00025497          	auipc	s1,0x25
    800050a6:	72e48493          	addi	s1,s1,1838 # 8002a7d0 <ftable+0x18>
    800050aa:	00026717          	auipc	a4,0x26
    800050ae:	6c670713          	addi	a4,a4,1734 # 8002b770 <ftable+0xfb8>
    if(f->ref == 0){
    800050b2:	40dc                	lw	a5,4(s1)
    800050b4:	cf99                	beqz	a5,800050d2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050b6:	02848493          	addi	s1,s1,40
    800050ba:	fee49ce3          	bne	s1,a4,800050b2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050be:	00025517          	auipc	a0,0x25
    800050c2:	6fa50513          	addi	a0,a0,1786 # 8002a7b8 <ftable>
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	bb0080e7          	jalr	-1104(ra) # 80000c76 <release>
  return 0;
    800050ce:	4481                	li	s1,0
    800050d0:	a819                	j	800050e6 <filealloc+0x5e>
      f->ref = 1;
    800050d2:	4785                	li	a5,1
    800050d4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050d6:	00025517          	auipc	a0,0x25
    800050da:	6e250513          	addi	a0,a0,1762 # 8002a7b8 <ftable>
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	b98080e7          	jalr	-1128(ra) # 80000c76 <release>
}
    800050e6:	8526                	mv	a0,s1
    800050e8:	60e2                	ld	ra,24(sp)
    800050ea:	6442                	ld	s0,16(sp)
    800050ec:	64a2                	ld	s1,8(sp)
    800050ee:	6105                	addi	sp,sp,32
    800050f0:	8082                	ret

00000000800050f2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800050f2:	1101                	addi	sp,sp,-32
    800050f4:	ec06                	sd	ra,24(sp)
    800050f6:	e822                	sd	s0,16(sp)
    800050f8:	e426                	sd	s1,8(sp)
    800050fa:	1000                	addi	s0,sp,32
    800050fc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800050fe:	00025517          	auipc	a0,0x25
    80005102:	6ba50513          	addi	a0,a0,1722 # 8002a7b8 <ftable>
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	abc080e7          	jalr	-1348(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000510e:	40dc                	lw	a5,4(s1)
    80005110:	02f05263          	blez	a5,80005134 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005114:	2785                	addiw	a5,a5,1
    80005116:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005118:	00025517          	auipc	a0,0x25
    8000511c:	6a050513          	addi	a0,a0,1696 # 8002a7b8 <ftable>
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	b56080e7          	jalr	-1194(ra) # 80000c76 <release>
  return f;
}
    80005128:	8526                	mv	a0,s1
    8000512a:	60e2                	ld	ra,24(sp)
    8000512c:	6442                	ld	s0,16(sp)
    8000512e:	64a2                	ld	s1,8(sp)
    80005130:	6105                	addi	sp,sp,32
    80005132:	8082                	ret
    panic("filedup");
    80005134:	00005517          	auipc	a0,0x5
    80005138:	89c50513          	addi	a0,a0,-1892 # 800099d0 <syscalls+0x2b0>
    8000513c:	ffffb097          	auipc	ra,0xffffb
    80005140:	3ee080e7          	jalr	1006(ra) # 8000052a <panic>

0000000080005144 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005144:	7139                	addi	sp,sp,-64
    80005146:	fc06                	sd	ra,56(sp)
    80005148:	f822                	sd	s0,48(sp)
    8000514a:	f426                	sd	s1,40(sp)
    8000514c:	f04a                	sd	s2,32(sp)
    8000514e:	ec4e                	sd	s3,24(sp)
    80005150:	e852                	sd	s4,16(sp)
    80005152:	e456                	sd	s5,8(sp)
    80005154:	0080                	addi	s0,sp,64
    80005156:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005158:	00025517          	auipc	a0,0x25
    8000515c:	66050513          	addi	a0,a0,1632 # 8002a7b8 <ftable>
    80005160:	ffffc097          	auipc	ra,0xffffc
    80005164:	a62080e7          	jalr	-1438(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005168:	40dc                	lw	a5,4(s1)
    8000516a:	06f05163          	blez	a5,800051cc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000516e:	37fd                	addiw	a5,a5,-1
    80005170:	0007871b          	sext.w	a4,a5
    80005174:	c0dc                	sw	a5,4(s1)
    80005176:	06e04363          	bgtz	a4,800051dc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000517a:	0004a903          	lw	s2,0(s1)
    8000517e:	0094ca83          	lbu	s5,9(s1)
    80005182:	0104ba03          	ld	s4,16(s1)
    80005186:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000518a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000518e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005192:	00025517          	auipc	a0,0x25
    80005196:	62650513          	addi	a0,a0,1574 # 8002a7b8 <ftable>
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	adc080e7          	jalr	-1316(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800051a2:	4785                	li	a5,1
    800051a4:	04f90d63          	beq	s2,a5,800051fe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051a8:	3979                	addiw	s2,s2,-2
    800051aa:	4785                	li	a5,1
    800051ac:	0527e063          	bltu	a5,s2,800051ec <fileclose+0xa8>
    begin_op();
    800051b0:	00000097          	auipc	ra,0x0
    800051b4:	ac8080e7          	jalr	-1336(ra) # 80004c78 <begin_op>
    iput(ff.ip);
    800051b8:	854e                	mv	a0,s3
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	f90080e7          	jalr	-112(ra) # 8000414a <iput>
    end_op();
    800051c2:	00000097          	auipc	ra,0x0
    800051c6:	b36080e7          	jalr	-1226(ra) # 80004cf8 <end_op>
    800051ca:	a00d                	j	800051ec <fileclose+0xa8>
    panic("fileclose");
    800051cc:	00005517          	auipc	a0,0x5
    800051d0:	80c50513          	addi	a0,a0,-2036 # 800099d8 <syscalls+0x2b8>
    800051d4:	ffffb097          	auipc	ra,0xffffb
    800051d8:	356080e7          	jalr	854(ra) # 8000052a <panic>
    release(&ftable.lock);
    800051dc:	00025517          	auipc	a0,0x25
    800051e0:	5dc50513          	addi	a0,a0,1500 # 8002a7b8 <ftable>
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	a92080e7          	jalr	-1390(ra) # 80000c76 <release>
  }
}
    800051ec:	70e2                	ld	ra,56(sp)
    800051ee:	7442                	ld	s0,48(sp)
    800051f0:	74a2                	ld	s1,40(sp)
    800051f2:	7902                	ld	s2,32(sp)
    800051f4:	69e2                	ld	s3,24(sp)
    800051f6:	6a42                	ld	s4,16(sp)
    800051f8:	6aa2                	ld	s5,8(sp)
    800051fa:	6121                	addi	sp,sp,64
    800051fc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800051fe:	85d6                	mv	a1,s5
    80005200:	8552                	mv	a0,s4
    80005202:	00000097          	auipc	ra,0x0
    80005206:	542080e7          	jalr	1346(ra) # 80005744 <pipeclose>
    8000520a:	b7cd                	j	800051ec <fileclose+0xa8>

000000008000520c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000520c:	715d                	addi	sp,sp,-80
    8000520e:	e486                	sd	ra,72(sp)
    80005210:	e0a2                	sd	s0,64(sp)
    80005212:	fc26                	sd	s1,56(sp)
    80005214:	f84a                	sd	s2,48(sp)
    80005216:	f44e                	sd	s3,40(sp)
    80005218:	0880                	addi	s0,sp,80
    8000521a:	84aa                	mv	s1,a0
    8000521c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	7b6080e7          	jalr	1974(ra) # 800019d4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005226:	409c                	lw	a5,0(s1)
    80005228:	37f9                	addiw	a5,a5,-2
    8000522a:	4705                	li	a4,1
    8000522c:	04f76763          	bltu	a4,a5,8000527a <filestat+0x6e>
    80005230:	892a                	mv	s2,a0
    ilock(f->ip);
    80005232:	6c88                	ld	a0,24(s1)
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	d5c080e7          	jalr	-676(ra) # 80003f90 <ilock>
    stati(f->ip, &st);
    8000523c:	fb840593          	addi	a1,s0,-72
    80005240:	6c88                	ld	a0,24(s1)
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	fd8080e7          	jalr	-40(ra) # 8000421a <stati>
    iunlock(f->ip);
    8000524a:	6c88                	ld	a0,24(s1)
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	e06080e7          	jalr	-506(ra) # 80004052 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005254:	46e1                	li	a3,24
    80005256:	fb840613          	addi	a2,s0,-72
    8000525a:	85ce                	mv	a1,s3
    8000525c:	05093503          	ld	a0,80(s2)
    80005260:	ffffc097          	auipc	ra,0xffffc
    80005264:	434080e7          	jalr	1076(ra) # 80001694 <copyout>
    80005268:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000526c:	60a6                	ld	ra,72(sp)
    8000526e:	6406                	ld	s0,64(sp)
    80005270:	74e2                	ld	s1,56(sp)
    80005272:	7942                	ld	s2,48(sp)
    80005274:	79a2                	ld	s3,40(sp)
    80005276:	6161                	addi	sp,sp,80
    80005278:	8082                	ret
  return -1;
    8000527a:	557d                	li	a0,-1
    8000527c:	bfc5                	j	8000526c <filestat+0x60>

000000008000527e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000527e:	7179                	addi	sp,sp,-48
    80005280:	f406                	sd	ra,40(sp)
    80005282:	f022                	sd	s0,32(sp)
    80005284:	ec26                	sd	s1,24(sp)
    80005286:	e84a                	sd	s2,16(sp)
    80005288:	e44e                	sd	s3,8(sp)
    8000528a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000528c:	00854783          	lbu	a5,8(a0)
    80005290:	c3d5                	beqz	a5,80005334 <fileread+0xb6>
    80005292:	84aa                	mv	s1,a0
    80005294:	89ae                	mv	s3,a1
    80005296:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005298:	411c                	lw	a5,0(a0)
    8000529a:	4705                	li	a4,1
    8000529c:	04e78963          	beq	a5,a4,800052ee <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052a0:	470d                	li	a4,3
    800052a2:	04e78d63          	beq	a5,a4,800052fc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052a6:	4709                	li	a4,2
    800052a8:	06e79e63          	bne	a5,a4,80005324 <fileread+0xa6>
    ilock(f->ip);
    800052ac:	6d08                	ld	a0,24(a0)
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	ce2080e7          	jalr	-798(ra) # 80003f90 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052b6:	874a                	mv	a4,s2
    800052b8:	5094                	lw	a3,32(s1)
    800052ba:	864e                	mv	a2,s3
    800052bc:	4585                	li	a1,1
    800052be:	6c88                	ld	a0,24(s1)
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	f84080e7          	jalr	-124(ra) # 80004244 <readi>
    800052c8:	892a                	mv	s2,a0
    800052ca:	00a05563          	blez	a0,800052d4 <fileread+0x56>
      f->off += r;
    800052ce:	509c                	lw	a5,32(s1)
    800052d0:	9fa9                	addw	a5,a5,a0
    800052d2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052d4:	6c88                	ld	a0,24(s1)
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	d7c080e7          	jalr	-644(ra) # 80004052 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052de:	854a                	mv	a0,s2
    800052e0:	70a2                	ld	ra,40(sp)
    800052e2:	7402                	ld	s0,32(sp)
    800052e4:	64e2                	ld	s1,24(sp)
    800052e6:	6942                	ld	s2,16(sp)
    800052e8:	69a2                	ld	s3,8(sp)
    800052ea:	6145                	addi	sp,sp,48
    800052ec:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800052ee:	6908                	ld	a0,16(a0)
    800052f0:	00000097          	auipc	ra,0x0
    800052f4:	5b6080e7          	jalr	1462(ra) # 800058a6 <piperead>
    800052f8:	892a                	mv	s2,a0
    800052fa:	b7d5                	j	800052de <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800052fc:	02451783          	lh	a5,36(a0)
    80005300:	03079693          	slli	a3,a5,0x30
    80005304:	92c1                	srli	a3,a3,0x30
    80005306:	4725                	li	a4,9
    80005308:	02d76863          	bltu	a4,a3,80005338 <fileread+0xba>
    8000530c:	0792                	slli	a5,a5,0x4
    8000530e:	00025717          	auipc	a4,0x25
    80005312:	40a70713          	addi	a4,a4,1034 # 8002a718 <devsw>
    80005316:	97ba                	add	a5,a5,a4
    80005318:	639c                	ld	a5,0(a5)
    8000531a:	c38d                	beqz	a5,8000533c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000531c:	4505                	li	a0,1
    8000531e:	9782                	jalr	a5
    80005320:	892a                	mv	s2,a0
    80005322:	bf75                	j	800052de <fileread+0x60>
    panic("fileread");
    80005324:	00004517          	auipc	a0,0x4
    80005328:	6c450513          	addi	a0,a0,1732 # 800099e8 <syscalls+0x2c8>
    8000532c:	ffffb097          	auipc	ra,0xffffb
    80005330:	1fe080e7          	jalr	510(ra) # 8000052a <panic>
    return -1;
    80005334:	597d                	li	s2,-1
    80005336:	b765                	j	800052de <fileread+0x60>
      return -1;
    80005338:	597d                	li	s2,-1
    8000533a:	b755                	j	800052de <fileread+0x60>
    8000533c:	597d                	li	s2,-1
    8000533e:	b745                	j	800052de <fileread+0x60>

0000000080005340 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005340:	715d                	addi	sp,sp,-80
    80005342:	e486                	sd	ra,72(sp)
    80005344:	e0a2                	sd	s0,64(sp)
    80005346:	fc26                	sd	s1,56(sp)
    80005348:	f84a                	sd	s2,48(sp)
    8000534a:	f44e                	sd	s3,40(sp)
    8000534c:	f052                	sd	s4,32(sp)
    8000534e:	ec56                	sd	s5,24(sp)
    80005350:	e85a                	sd	s6,16(sp)
    80005352:	e45e                	sd	s7,8(sp)
    80005354:	e062                	sd	s8,0(sp)
    80005356:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005358:	00954783          	lbu	a5,9(a0)
    8000535c:	10078663          	beqz	a5,80005468 <filewrite+0x128>
    80005360:	892a                	mv	s2,a0
    80005362:	8aae                	mv	s5,a1
    80005364:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005366:	411c                	lw	a5,0(a0)
    80005368:	4705                	li	a4,1
    8000536a:	02e78263          	beq	a5,a4,8000538e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000536e:	470d                	li	a4,3
    80005370:	02e78663          	beq	a5,a4,8000539c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005374:	4709                	li	a4,2
    80005376:	0ee79163          	bne	a5,a4,80005458 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000537a:	0ac05d63          	blez	a2,80005434 <filewrite+0xf4>
    int i = 0;
    8000537e:	4981                	li	s3,0
    80005380:	6b05                	lui	s6,0x1
    80005382:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005386:	6b85                	lui	s7,0x1
    80005388:	c00b8b9b          	addiw	s7,s7,-1024
    8000538c:	a861                	j	80005424 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000538e:	6908                	ld	a0,16(a0)
    80005390:	00000097          	auipc	ra,0x0
    80005394:	424080e7          	jalr	1060(ra) # 800057b4 <pipewrite>
    80005398:	8a2a                	mv	s4,a0
    8000539a:	a045                	j	8000543a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000539c:	02451783          	lh	a5,36(a0)
    800053a0:	03079693          	slli	a3,a5,0x30
    800053a4:	92c1                	srli	a3,a3,0x30
    800053a6:	4725                	li	a4,9
    800053a8:	0cd76263          	bltu	a4,a3,8000546c <filewrite+0x12c>
    800053ac:	0792                	slli	a5,a5,0x4
    800053ae:	00025717          	auipc	a4,0x25
    800053b2:	36a70713          	addi	a4,a4,874 # 8002a718 <devsw>
    800053b6:	97ba                	add	a5,a5,a4
    800053b8:	679c                	ld	a5,8(a5)
    800053ba:	cbdd                	beqz	a5,80005470 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053bc:	4505                	li	a0,1
    800053be:	9782                	jalr	a5
    800053c0:	8a2a                	mv	s4,a0
    800053c2:	a8a5                	j	8000543a <filewrite+0xfa>
    800053c4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	8b0080e7          	jalr	-1872(ra) # 80004c78 <begin_op>
      ilock(f->ip);
    800053d0:	01893503          	ld	a0,24(s2)
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	bbc080e7          	jalr	-1092(ra) # 80003f90 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053dc:	8762                	mv	a4,s8
    800053de:	02092683          	lw	a3,32(s2)
    800053e2:	01598633          	add	a2,s3,s5
    800053e6:	4585                	li	a1,1
    800053e8:	01893503          	ld	a0,24(s2)
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	f50080e7          	jalr	-176(ra) # 8000433c <writei>
    800053f4:	84aa                	mv	s1,a0
    800053f6:	00a05763          	blez	a0,80005404 <filewrite+0xc4>
        f->off += r;
    800053fa:	02092783          	lw	a5,32(s2)
    800053fe:	9fa9                	addw	a5,a5,a0
    80005400:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005404:	01893503          	ld	a0,24(s2)
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	c4a080e7          	jalr	-950(ra) # 80004052 <iunlock>
      end_op();
    80005410:	00000097          	auipc	ra,0x0
    80005414:	8e8080e7          	jalr	-1816(ra) # 80004cf8 <end_op>

      if(r != n1){
    80005418:	009c1f63          	bne	s8,s1,80005436 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000541c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005420:	0149db63          	bge	s3,s4,80005436 <filewrite+0xf6>
      int n1 = n - i;
    80005424:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005428:	84be                	mv	s1,a5
    8000542a:	2781                	sext.w	a5,a5
    8000542c:	f8fb5ce3          	bge	s6,a5,800053c4 <filewrite+0x84>
    80005430:	84de                	mv	s1,s7
    80005432:	bf49                	j	800053c4 <filewrite+0x84>
    int i = 0;
    80005434:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005436:	013a1f63          	bne	s4,s3,80005454 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000543a:	8552                	mv	a0,s4
    8000543c:	60a6                	ld	ra,72(sp)
    8000543e:	6406                	ld	s0,64(sp)
    80005440:	74e2                	ld	s1,56(sp)
    80005442:	7942                	ld	s2,48(sp)
    80005444:	79a2                	ld	s3,40(sp)
    80005446:	7a02                	ld	s4,32(sp)
    80005448:	6ae2                	ld	s5,24(sp)
    8000544a:	6b42                	ld	s6,16(sp)
    8000544c:	6ba2                	ld	s7,8(sp)
    8000544e:	6c02                	ld	s8,0(sp)
    80005450:	6161                	addi	sp,sp,80
    80005452:	8082                	ret
    ret = (i == n ? n : -1);
    80005454:	5a7d                	li	s4,-1
    80005456:	b7d5                	j	8000543a <filewrite+0xfa>
    panic("filewrite");
    80005458:	00004517          	auipc	a0,0x4
    8000545c:	5a050513          	addi	a0,a0,1440 # 800099f8 <syscalls+0x2d8>
    80005460:	ffffb097          	auipc	ra,0xffffb
    80005464:	0ca080e7          	jalr	202(ra) # 8000052a <panic>
    return -1;
    80005468:	5a7d                	li	s4,-1
    8000546a:	bfc1                	j	8000543a <filewrite+0xfa>
      return -1;
    8000546c:	5a7d                	li	s4,-1
    8000546e:	b7f1                	j	8000543a <filewrite+0xfa>
    80005470:	5a7d                	li	s4,-1
    80005472:	b7e1                	j	8000543a <filewrite+0xfa>

0000000080005474 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80005474:	7179                	addi	sp,sp,-48
    80005476:	f406                	sd	ra,40(sp)
    80005478:	f022                	sd	s0,32(sp)
    8000547a:	ec26                	sd	s1,24(sp)
    8000547c:	e84a                	sd	s2,16(sp)
    8000547e:	e44e                	sd	s3,8(sp)
    80005480:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005482:	00854783          	lbu	a5,8(a0)
    80005486:	c3d5                	beqz	a5,8000552a <kfileread+0xb6>
    80005488:	84aa                	mv	s1,a0
    8000548a:	89ae                	mv	s3,a1
    8000548c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000548e:	411c                	lw	a5,0(a0)
    80005490:	4705                	li	a4,1
    80005492:	04e78963          	beq	a5,a4,800054e4 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005496:	470d                	li	a4,3
    80005498:	04e78d63          	beq	a5,a4,800054f2 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000549c:	4709                	li	a4,2
    8000549e:	06e79e63          	bne	a5,a4,8000551a <kfileread+0xa6>
    ilock(f->ip);
    800054a2:	6d08                	ld	a0,24(a0)
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	aec080e7          	jalr	-1300(ra) # 80003f90 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800054ac:	874a                	mv	a4,s2
    800054ae:	5094                	lw	a3,32(s1)
    800054b0:	864e                	mv	a2,s3
    800054b2:	4581                	li	a1,0
    800054b4:	6c88                	ld	a0,24(s1)
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	d8e080e7          	jalr	-626(ra) # 80004244 <readi>
    800054be:	892a                	mv	s2,a0
    800054c0:	00a05563          	blez	a0,800054ca <kfileread+0x56>
      f->off += r;
    800054c4:	509c                	lw	a5,32(s1)
    800054c6:	9fa9                	addw	a5,a5,a0
    800054c8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800054ca:	6c88                	ld	a0,24(s1)
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	b86080e7          	jalr	-1146(ra) # 80004052 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800054d4:	854a                	mv	a0,s2
    800054d6:	70a2                	ld	ra,40(sp)
    800054d8:	7402                	ld	s0,32(sp)
    800054da:	64e2                	ld	s1,24(sp)
    800054dc:	6942                	ld	s2,16(sp)
    800054de:	69a2                	ld	s3,8(sp)
    800054e0:	6145                	addi	sp,sp,48
    800054e2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800054e4:	6908                	ld	a0,16(a0)
    800054e6:	00000097          	auipc	ra,0x0
    800054ea:	3c0080e7          	jalr	960(ra) # 800058a6 <piperead>
    800054ee:	892a                	mv	s2,a0
    800054f0:	b7d5                	j	800054d4 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800054f2:	02451783          	lh	a5,36(a0)
    800054f6:	03079693          	slli	a3,a5,0x30
    800054fa:	92c1                	srli	a3,a3,0x30
    800054fc:	4725                	li	a4,9
    800054fe:	02d76863          	bltu	a4,a3,8000552e <kfileread+0xba>
    80005502:	0792                	slli	a5,a5,0x4
    80005504:	00025717          	auipc	a4,0x25
    80005508:	21470713          	addi	a4,a4,532 # 8002a718 <devsw>
    8000550c:	97ba                	add	a5,a5,a4
    8000550e:	639c                	ld	a5,0(a5)
    80005510:	c38d                	beqz	a5,80005532 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005512:	4505                	li	a0,1
    80005514:	9782                	jalr	a5
    80005516:	892a                	mv	s2,a0
    80005518:	bf75                	j	800054d4 <kfileread+0x60>
    panic("fileread");
    8000551a:	00004517          	auipc	a0,0x4
    8000551e:	4ce50513          	addi	a0,a0,1230 # 800099e8 <syscalls+0x2c8>
    80005522:	ffffb097          	auipc	ra,0xffffb
    80005526:	008080e7          	jalr	8(ra) # 8000052a <panic>
    return -1;
    8000552a:	597d                	li	s2,-1
    8000552c:	b765                	j	800054d4 <kfileread+0x60>
      return -1;
    8000552e:	597d                	li	s2,-1
    80005530:	b755                	j	800054d4 <kfileread+0x60>
    80005532:	597d                	li	s2,-1
    80005534:	b745                	j	800054d4 <kfileread+0x60>

0000000080005536 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005536:	715d                	addi	sp,sp,-80
    80005538:	e486                	sd	ra,72(sp)
    8000553a:	e0a2                	sd	s0,64(sp)
    8000553c:	fc26                	sd	s1,56(sp)
    8000553e:	f84a                	sd	s2,48(sp)
    80005540:	f44e                	sd	s3,40(sp)
    80005542:	f052                	sd	s4,32(sp)
    80005544:	ec56                	sd	s5,24(sp)
    80005546:	e85a                	sd	s6,16(sp)
    80005548:	e45e                	sd	s7,8(sp)
    8000554a:	e062                	sd	s8,0(sp)
    8000554c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000554e:	00954783          	lbu	a5,9(a0)
    80005552:	10078663          	beqz	a5,8000565e <kfilewrite+0x128>
    80005556:	892a                	mv	s2,a0
    80005558:	8aae                	mv	s5,a1
    8000555a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000555c:	411c                	lw	a5,0(a0)
    8000555e:	4705                	li	a4,1
    80005560:	02e78263          	beq	a5,a4,80005584 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005564:	470d                	li	a4,3
    80005566:	02e78663          	beq	a5,a4,80005592 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000556a:	4709                	li	a4,2
    8000556c:	0ee79163          	bne	a5,a4,8000564e <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005570:	0ac05d63          	blez	a2,8000562a <kfilewrite+0xf4>
    int i = 0;
    80005574:	4981                	li	s3,0
    80005576:	6b05                	lui	s6,0x1
    80005578:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000557c:	6b85                	lui	s7,0x1
    8000557e:	c00b8b9b          	addiw	s7,s7,-1024
    80005582:	a861                	j	8000561a <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005584:	6908                	ld	a0,16(a0)
    80005586:	00000097          	auipc	ra,0x0
    8000558a:	22e080e7          	jalr	558(ra) # 800057b4 <pipewrite>
    8000558e:	8a2a                	mv	s4,a0
    80005590:	a045                	j	80005630 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005592:	02451783          	lh	a5,36(a0)
    80005596:	03079693          	slli	a3,a5,0x30
    8000559a:	92c1                	srli	a3,a3,0x30
    8000559c:	4725                	li	a4,9
    8000559e:	0cd76263          	bltu	a4,a3,80005662 <kfilewrite+0x12c>
    800055a2:	0792                	slli	a5,a5,0x4
    800055a4:	00025717          	auipc	a4,0x25
    800055a8:	17470713          	addi	a4,a4,372 # 8002a718 <devsw>
    800055ac:	97ba                	add	a5,a5,a4
    800055ae:	679c                	ld	a5,8(a5)
    800055b0:	cbdd                	beqz	a5,80005666 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800055b2:	4505                	li	a0,1
    800055b4:	9782                	jalr	a5
    800055b6:	8a2a                	mv	s4,a0
    800055b8:	a8a5                	j	80005630 <kfilewrite+0xfa>
    800055ba:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	6ba080e7          	jalr	1722(ra) # 80004c78 <begin_op>
      ilock(f->ip);
    800055c6:	01893503          	ld	a0,24(s2)
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	9c6080e7          	jalr	-1594(ra) # 80003f90 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800055d2:	8762                	mv	a4,s8
    800055d4:	02092683          	lw	a3,32(s2)
    800055d8:	01598633          	add	a2,s3,s5
    800055dc:	4581                	li	a1,0
    800055de:	01893503          	ld	a0,24(s2)
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	d5a080e7          	jalr	-678(ra) # 8000433c <writei>
    800055ea:	84aa                	mv	s1,a0
    800055ec:	00a05763          	blez	a0,800055fa <kfilewrite+0xc4>
        f->off += r;
    800055f0:	02092783          	lw	a5,32(s2)
    800055f4:	9fa9                	addw	a5,a5,a0
    800055f6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800055fa:	01893503          	ld	a0,24(s2)
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	a54080e7          	jalr	-1452(ra) # 80004052 <iunlock>
      end_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	6f2080e7          	jalr	1778(ra) # 80004cf8 <end_op>

      if(r != n1){
    8000560e:	009c1f63          	bne	s8,s1,8000562c <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005612:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005616:	0149db63          	bge	s3,s4,8000562c <kfilewrite+0xf6>
      int n1 = n - i;
    8000561a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000561e:	84be                	mv	s1,a5
    80005620:	2781                	sext.w	a5,a5
    80005622:	f8fb5ce3          	bge	s6,a5,800055ba <kfilewrite+0x84>
    80005626:	84de                	mv	s1,s7
    80005628:	bf49                	j	800055ba <kfilewrite+0x84>
    int i = 0;
    8000562a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000562c:	013a1f63          	bne	s4,s3,8000564a <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80005630:	8552                	mv	a0,s4
    80005632:	60a6                	ld	ra,72(sp)
    80005634:	6406                	ld	s0,64(sp)
    80005636:	74e2                	ld	s1,56(sp)
    80005638:	7942                	ld	s2,48(sp)
    8000563a:	79a2                	ld	s3,40(sp)
    8000563c:	7a02                	ld	s4,32(sp)
    8000563e:	6ae2                	ld	s5,24(sp)
    80005640:	6b42                	ld	s6,16(sp)
    80005642:	6ba2                	ld	s7,8(sp)
    80005644:	6c02                	ld	s8,0(sp)
    80005646:	6161                	addi	sp,sp,80
    80005648:	8082                	ret
    ret = (i == n ? n : -1);
    8000564a:	5a7d                	li	s4,-1
    8000564c:	b7d5                	j	80005630 <kfilewrite+0xfa>
    panic("filewrite");
    8000564e:	00004517          	auipc	a0,0x4
    80005652:	3aa50513          	addi	a0,a0,938 # 800099f8 <syscalls+0x2d8>
    80005656:	ffffb097          	auipc	ra,0xffffb
    8000565a:	ed4080e7          	jalr	-300(ra) # 8000052a <panic>
    return -1;
    8000565e:	5a7d                	li	s4,-1
    80005660:	bfc1                	j	80005630 <kfilewrite+0xfa>
      return -1;
    80005662:	5a7d                	li	s4,-1
    80005664:	b7f1                	j	80005630 <kfilewrite+0xfa>
    80005666:	5a7d                	li	s4,-1
    80005668:	b7e1                	j	80005630 <kfilewrite+0xfa>

000000008000566a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000566a:	7179                	addi	sp,sp,-48
    8000566c:	f406                	sd	ra,40(sp)
    8000566e:	f022                	sd	s0,32(sp)
    80005670:	ec26                	sd	s1,24(sp)
    80005672:	e84a                	sd	s2,16(sp)
    80005674:	e44e                	sd	s3,8(sp)
    80005676:	e052                	sd	s4,0(sp)
    80005678:	1800                	addi	s0,sp,48
    8000567a:	84aa                	mv	s1,a0
    8000567c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000567e:	0005b023          	sd	zero,0(a1)
    80005682:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005686:	00000097          	auipc	ra,0x0
    8000568a:	a02080e7          	jalr	-1534(ra) # 80005088 <filealloc>
    8000568e:	e088                	sd	a0,0(s1)
    80005690:	c551                	beqz	a0,8000571c <pipealloc+0xb2>
    80005692:	00000097          	auipc	ra,0x0
    80005696:	9f6080e7          	jalr	-1546(ra) # 80005088 <filealloc>
    8000569a:	00aa3023          	sd	a0,0(s4)
    8000569e:	c92d                	beqz	a0,80005710 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800056a0:	ffffb097          	auipc	ra,0xffffb
    800056a4:	432080e7          	jalr	1074(ra) # 80000ad2 <kalloc>
    800056a8:	892a                	mv	s2,a0
    800056aa:	c125                	beqz	a0,8000570a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800056ac:	4985                	li	s3,1
    800056ae:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800056b2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800056b6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800056ba:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800056be:	00004597          	auipc	a1,0x4
    800056c2:	34a58593          	addi	a1,a1,842 # 80009a08 <syscalls+0x2e8>
    800056c6:	ffffb097          	auipc	ra,0xffffb
    800056ca:	46c080e7          	jalr	1132(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800056ce:	609c                	ld	a5,0(s1)
    800056d0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800056d4:	609c                	ld	a5,0(s1)
    800056d6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800056da:	609c                	ld	a5,0(s1)
    800056dc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800056e0:	609c                	ld	a5,0(s1)
    800056e2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800056e6:	000a3783          	ld	a5,0(s4)
    800056ea:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800056ee:	000a3783          	ld	a5,0(s4)
    800056f2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800056f6:	000a3783          	ld	a5,0(s4)
    800056fa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800056fe:	000a3783          	ld	a5,0(s4)
    80005702:	0127b823          	sd	s2,16(a5)
  return 0;
    80005706:	4501                	li	a0,0
    80005708:	a025                	j	80005730 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000570a:	6088                	ld	a0,0(s1)
    8000570c:	e501                	bnez	a0,80005714 <pipealloc+0xaa>
    8000570e:	a039                	j	8000571c <pipealloc+0xb2>
    80005710:	6088                	ld	a0,0(s1)
    80005712:	c51d                	beqz	a0,80005740 <pipealloc+0xd6>
    fileclose(*f0);
    80005714:	00000097          	auipc	ra,0x0
    80005718:	a30080e7          	jalr	-1488(ra) # 80005144 <fileclose>
  if(*f1)
    8000571c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005720:	557d                	li	a0,-1
  if(*f1)
    80005722:	c799                	beqz	a5,80005730 <pipealloc+0xc6>
    fileclose(*f1);
    80005724:	853e                	mv	a0,a5
    80005726:	00000097          	auipc	ra,0x0
    8000572a:	a1e080e7          	jalr	-1506(ra) # 80005144 <fileclose>
  return -1;
    8000572e:	557d                	li	a0,-1
}
    80005730:	70a2                	ld	ra,40(sp)
    80005732:	7402                	ld	s0,32(sp)
    80005734:	64e2                	ld	s1,24(sp)
    80005736:	6942                	ld	s2,16(sp)
    80005738:	69a2                	ld	s3,8(sp)
    8000573a:	6a02                	ld	s4,0(sp)
    8000573c:	6145                	addi	sp,sp,48
    8000573e:	8082                	ret
  return -1;
    80005740:	557d                	li	a0,-1
    80005742:	b7fd                	j	80005730 <pipealloc+0xc6>

0000000080005744 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005744:	1101                	addi	sp,sp,-32
    80005746:	ec06                	sd	ra,24(sp)
    80005748:	e822                	sd	s0,16(sp)
    8000574a:	e426                	sd	s1,8(sp)
    8000574c:	e04a                	sd	s2,0(sp)
    8000574e:	1000                	addi	s0,sp,32
    80005750:	84aa                	mv	s1,a0
    80005752:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005754:	ffffb097          	auipc	ra,0xffffb
    80005758:	46e080e7          	jalr	1134(ra) # 80000bc2 <acquire>
  if(writable){
    8000575c:	02090d63          	beqz	s2,80005796 <pipeclose+0x52>
    pi->writeopen = 0;
    80005760:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005764:	21848513          	addi	a0,s1,536
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	950080e7          	jalr	-1712(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005770:	2204b783          	ld	a5,544(s1)
    80005774:	eb95                	bnez	a5,800057a8 <pipeclose+0x64>
    release(&pi->lock);
    80005776:	8526                	mv	a0,s1
    80005778:	ffffb097          	auipc	ra,0xffffb
    8000577c:	4fe080e7          	jalr	1278(ra) # 80000c76 <release>
    kfree((char*)pi);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffb097          	auipc	ra,0xffffb
    80005786:	254080e7          	jalr	596(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    8000578a:	60e2                	ld	ra,24(sp)
    8000578c:	6442                	ld	s0,16(sp)
    8000578e:	64a2                	ld	s1,8(sp)
    80005790:	6902                	ld	s2,0(sp)
    80005792:	6105                	addi	sp,sp,32
    80005794:	8082                	ret
    pi->readopen = 0;
    80005796:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000579a:	21c48513          	addi	a0,s1,540
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	91a080e7          	jalr	-1766(ra) # 800020b8 <wakeup>
    800057a6:	b7e9                	j	80005770 <pipeclose+0x2c>
    release(&pi->lock);
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffb097          	auipc	ra,0xffffb
    800057ae:	4cc080e7          	jalr	1228(ra) # 80000c76 <release>
}
    800057b2:	bfe1                	j	8000578a <pipeclose+0x46>

00000000800057b4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800057b4:	711d                	addi	sp,sp,-96
    800057b6:	ec86                	sd	ra,88(sp)
    800057b8:	e8a2                	sd	s0,80(sp)
    800057ba:	e4a6                	sd	s1,72(sp)
    800057bc:	e0ca                	sd	s2,64(sp)
    800057be:	fc4e                	sd	s3,56(sp)
    800057c0:	f852                	sd	s4,48(sp)
    800057c2:	f456                	sd	s5,40(sp)
    800057c4:	f05a                	sd	s6,32(sp)
    800057c6:	ec5e                	sd	s7,24(sp)
    800057c8:	e862                	sd	s8,16(sp)
    800057ca:	1080                	addi	s0,sp,96
    800057cc:	84aa                	mv	s1,a0
    800057ce:	8aae                	mv	s5,a1
    800057d0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800057d2:	ffffc097          	auipc	ra,0xffffc
    800057d6:	202080e7          	jalr	514(ra) # 800019d4 <myproc>
    800057da:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800057dc:	8526                	mv	a0,s1
    800057de:	ffffb097          	auipc	ra,0xffffb
    800057e2:	3e4080e7          	jalr	996(ra) # 80000bc2 <acquire>
  while(i < n){
    800057e6:	0b405363          	blez	s4,8000588c <pipewrite+0xd8>
  int i = 0;
    800057ea:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800057ec:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800057ee:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800057f2:	21c48b93          	addi	s7,s1,540
    800057f6:	a089                	j	80005838 <pipewrite+0x84>
      release(&pi->lock);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffb097          	auipc	ra,0xffffb
    800057fe:	47c080e7          	jalr	1148(ra) # 80000c76 <release>
      return -1;
    80005802:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005804:	854a                	mv	a0,s2
    80005806:	60e6                	ld	ra,88(sp)
    80005808:	6446                	ld	s0,80(sp)
    8000580a:	64a6                	ld	s1,72(sp)
    8000580c:	6906                	ld	s2,64(sp)
    8000580e:	79e2                	ld	s3,56(sp)
    80005810:	7a42                	ld	s4,48(sp)
    80005812:	7aa2                	ld	s5,40(sp)
    80005814:	7b02                	ld	s6,32(sp)
    80005816:	6be2                	ld	s7,24(sp)
    80005818:	6c42                	ld	s8,16(sp)
    8000581a:	6125                	addi	sp,sp,96
    8000581c:	8082                	ret
      wakeup(&pi->nread);
    8000581e:	8562                	mv	a0,s8
    80005820:	ffffd097          	auipc	ra,0xffffd
    80005824:	898080e7          	jalr	-1896(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005828:	85a6                	mv	a1,s1
    8000582a:	855e                	mv	a0,s7
    8000582c:	ffffd097          	auipc	ra,0xffffd
    80005830:	828080e7          	jalr	-2008(ra) # 80002054 <sleep>
  while(i < n){
    80005834:	05495d63          	bge	s2,s4,8000588e <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005838:	2204a783          	lw	a5,544(s1)
    8000583c:	dfd5                	beqz	a5,800057f8 <pipewrite+0x44>
    8000583e:	0289a783          	lw	a5,40(s3)
    80005842:	fbdd                	bnez	a5,800057f8 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005844:	2184a783          	lw	a5,536(s1)
    80005848:	21c4a703          	lw	a4,540(s1)
    8000584c:	2007879b          	addiw	a5,a5,512
    80005850:	fcf707e3          	beq	a4,a5,8000581e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005854:	4685                	li	a3,1
    80005856:	01590633          	add	a2,s2,s5
    8000585a:	faf40593          	addi	a1,s0,-81
    8000585e:	0509b503          	ld	a0,80(s3)
    80005862:	ffffc097          	auipc	ra,0xffffc
    80005866:	ebe080e7          	jalr	-322(ra) # 80001720 <copyin>
    8000586a:	03650263          	beq	a0,s6,8000588e <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000586e:	21c4a783          	lw	a5,540(s1)
    80005872:	0017871b          	addiw	a4,a5,1
    80005876:	20e4ae23          	sw	a4,540(s1)
    8000587a:	1ff7f793          	andi	a5,a5,511
    8000587e:	97a6                	add	a5,a5,s1
    80005880:	faf44703          	lbu	a4,-81(s0)
    80005884:	00e78c23          	sb	a4,24(a5)
      i++;
    80005888:	2905                	addiw	s2,s2,1
    8000588a:	b76d                	j	80005834 <pipewrite+0x80>
  int i = 0;
    8000588c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000588e:	21848513          	addi	a0,s1,536
    80005892:	ffffd097          	auipc	ra,0xffffd
    80005896:	826080e7          	jalr	-2010(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	3da080e7          	jalr	986(ra) # 80000c76 <release>
  return i;
    800058a4:	b785                	j	80005804 <pipewrite+0x50>

00000000800058a6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800058a6:	715d                	addi	sp,sp,-80
    800058a8:	e486                	sd	ra,72(sp)
    800058aa:	e0a2                	sd	s0,64(sp)
    800058ac:	fc26                	sd	s1,56(sp)
    800058ae:	f84a                	sd	s2,48(sp)
    800058b0:	f44e                	sd	s3,40(sp)
    800058b2:	f052                	sd	s4,32(sp)
    800058b4:	ec56                	sd	s5,24(sp)
    800058b6:	e85a                	sd	s6,16(sp)
    800058b8:	0880                	addi	s0,sp,80
    800058ba:	84aa                	mv	s1,a0
    800058bc:	892e                	mv	s2,a1
    800058be:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800058c0:	ffffc097          	auipc	ra,0xffffc
    800058c4:	114080e7          	jalr	276(ra) # 800019d4 <myproc>
    800058c8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800058ca:	8526                	mv	a0,s1
    800058cc:	ffffb097          	auipc	ra,0xffffb
    800058d0:	2f6080e7          	jalr	758(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058d4:	2184a703          	lw	a4,536(s1)
    800058d8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800058dc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058e0:	02f71463          	bne	a4,a5,80005908 <piperead+0x62>
    800058e4:	2244a783          	lw	a5,548(s1)
    800058e8:	c385                	beqz	a5,80005908 <piperead+0x62>
    if(pr->killed){
    800058ea:	028a2783          	lw	a5,40(s4)
    800058ee:	ebc1                	bnez	a5,8000597e <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800058f0:	85a6                	mv	a1,s1
    800058f2:	854e                	mv	a0,s3
    800058f4:	ffffc097          	auipc	ra,0xffffc
    800058f8:	760080e7          	jalr	1888(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800058fc:	2184a703          	lw	a4,536(s1)
    80005900:	21c4a783          	lw	a5,540(s1)
    80005904:	fef700e3          	beq	a4,a5,800058e4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005908:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000590a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000590c:	05505363          	blez	s5,80005952 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005910:	2184a783          	lw	a5,536(s1)
    80005914:	21c4a703          	lw	a4,540(s1)
    80005918:	02f70d63          	beq	a4,a5,80005952 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000591c:	0017871b          	addiw	a4,a5,1
    80005920:	20e4ac23          	sw	a4,536(s1)
    80005924:	1ff7f793          	andi	a5,a5,511
    80005928:	97a6                	add	a5,a5,s1
    8000592a:	0187c783          	lbu	a5,24(a5)
    8000592e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005932:	4685                	li	a3,1
    80005934:	fbf40613          	addi	a2,s0,-65
    80005938:	85ca                	mv	a1,s2
    8000593a:	050a3503          	ld	a0,80(s4)
    8000593e:	ffffc097          	auipc	ra,0xffffc
    80005942:	d56080e7          	jalr	-682(ra) # 80001694 <copyout>
    80005946:	01650663          	beq	a0,s6,80005952 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000594a:	2985                	addiw	s3,s3,1
    8000594c:	0905                	addi	s2,s2,1
    8000594e:	fd3a91e3          	bne	s5,s3,80005910 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005952:	21c48513          	addi	a0,s1,540
    80005956:	ffffc097          	auipc	ra,0xffffc
    8000595a:	762080e7          	jalr	1890(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    8000595e:	8526                	mv	a0,s1
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	316080e7          	jalr	790(ra) # 80000c76 <release>
  return i;
}
    80005968:	854e                	mv	a0,s3
    8000596a:	60a6                	ld	ra,72(sp)
    8000596c:	6406                	ld	s0,64(sp)
    8000596e:	74e2                	ld	s1,56(sp)
    80005970:	7942                	ld	s2,48(sp)
    80005972:	79a2                	ld	s3,40(sp)
    80005974:	7a02                	ld	s4,32(sp)
    80005976:	6ae2                	ld	s5,24(sp)
    80005978:	6b42                	ld	s6,16(sp)
    8000597a:	6161                	addi	sp,sp,80
    8000597c:	8082                	ret
      release(&pi->lock);
    8000597e:	8526                	mv	a0,s1
    80005980:	ffffb097          	auipc	ra,0xffffb
    80005984:	2f6080e7          	jalr	758(ra) # 80000c76 <release>
      return -1;
    80005988:	59fd                	li	s3,-1
    8000598a:	bff9                	j	80005968 <piperead+0xc2>

000000008000598c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000598c:	bd010113          	addi	sp,sp,-1072
    80005990:	42113423          	sd	ra,1064(sp)
    80005994:	42813023          	sd	s0,1056(sp)
    80005998:	40913c23          	sd	s1,1048(sp)
    8000599c:	41213823          	sd	s2,1040(sp)
    800059a0:	41313423          	sd	s3,1032(sp)
    800059a4:	41413023          	sd	s4,1024(sp)
    800059a8:	3f513c23          	sd	s5,1016(sp)
    800059ac:	3f613823          	sd	s6,1008(sp)
    800059b0:	3f713423          	sd	s7,1000(sp)
    800059b4:	3f813023          	sd	s8,992(sp)
    800059b8:	3d913c23          	sd	s9,984(sp)
    800059bc:	3da13823          	sd	s10,976(sp)
    800059c0:	3db13423          	sd	s11,968(sp)
    800059c4:	43010413          	addi	s0,sp,1072
    800059c8:	89aa                	mv	s3,a0
    800059ca:	bea43023          	sd	a0,-1056(s0)
    800059ce:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800059d2:	ffffc097          	auipc	ra,0xffffc
    800059d6:	002080e7          	jalr	2(ra) # 800019d4 <myproc>
    800059da:	84aa                	mv	s1,a0
    800059dc:	c0a43423          	sd	a0,-1016(s0)
  
  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_DISK_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    800059e0:	17050913          	addi	s2,a0,368
    800059e4:	10000613          	li	a2,256
    800059e8:	85ca                	mv	a1,s2
    800059ea:	d1040513          	addi	a0,s0,-752
    800059ee:	ffffb097          	auipc	ra,0xffffb
    800059f2:	32c080e7          	jalr	812(ra) # 80000d1a <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    800059f6:	27048493          	addi	s1,s1,624
    800059fa:	10000613          	li	a2,256
    800059fe:	85a6                	mv	a1,s1
    80005a00:	c1040513          	addi	a0,s0,-1008
    80005a04:	ffffb097          	auipc	ra,0xffffb
    80005a08:	316080e7          	jalr	790(ra) # 80000d1a <memmove>

  begin_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	26c080e7          	jalr	620(ra) # 80004c78 <begin_op>

  if((ip = namei(path)) == 0){
    80005a14:	854e                	mv	a0,s3
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	d30080e7          	jalr	-720(ra) # 80004746 <namei>
    80005a1e:	c569                	beqz	a0,80005ae8 <exec+0x15c>
    80005a20:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	56e080e7          	jalr	1390(ra) # 80003f90 <ilock>

  // ADDED Q1
  if(relevant_metadata_proc(p) && init_metadata(p) < 0) {
    80005a2a:	c0843983          	ld	s3,-1016(s0)
    80005a2e:	854e                	mv	a0,s3
    80005a30:	ffffd097          	auipc	ra,0xffffd
    80005a34:	4ae080e7          	jalr	1198(ra) # 80002ede <relevant_metadata_proc>
    80005a38:	c901                	beqz	a0,80005a48 <exec+0xbc>
    80005a3a:	854e                	mv	a0,s3
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	91a080e7          	jalr	-1766(ra) # 80002356 <init_metadata>
    80005a44:	02054963          	bltz	a0,80005a76 <exec+0xea>
    goto bad;
  } 

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005a48:	04000713          	li	a4,64
    80005a4c:	4681                	li	a3,0
    80005a4e:	e4840613          	addi	a2,s0,-440
    80005a52:	4581                	li	a1,0
    80005a54:	8552                	mv	a0,s4
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	7ee080e7          	jalr	2030(ra) # 80004244 <readi>
    80005a5e:	04000793          	li	a5,64
    80005a62:	00f51a63          	bne	a0,a5,80005a76 <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005a66:	e4842703          	lw	a4,-440(s0)
    80005a6a:	464c47b7          	lui	a5,0x464c4
    80005a6e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005a72:	08f70163          	beq	a4,a5,80005af4 <exec+0x168>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005a76:	10000613          	li	a2,256
    80005a7a:	d1040593          	addi	a1,s0,-752
    80005a7e:	854a                	mv	a0,s2
    80005a80:	ffffb097          	auipc	ra,0xffffb
    80005a84:	29a080e7          	jalr	666(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005a88:	10000613          	li	a2,256
    80005a8c:	c1040593          	addi	a1,s0,-1008
    80005a90:	8526                	mv	a0,s1
    80005a92:	ffffb097          	auipc	ra,0xffffb
    80005a96:	288080e7          	jalr	648(ra) # 80000d1a <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005a9a:	8552                	mv	a0,s4
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	756080e7          	jalr	1878(ra) # 800041f2 <iunlockput>
    end_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	254080e7          	jalr	596(ra) # 80004cf8 <end_op>
  }
  return -1;
    80005aac:	557d                	li	a0,-1
}
    80005aae:	42813083          	ld	ra,1064(sp)
    80005ab2:	42013403          	ld	s0,1056(sp)
    80005ab6:	41813483          	ld	s1,1048(sp)
    80005aba:	41013903          	ld	s2,1040(sp)
    80005abe:	40813983          	ld	s3,1032(sp)
    80005ac2:	40013a03          	ld	s4,1024(sp)
    80005ac6:	3f813a83          	ld	s5,1016(sp)
    80005aca:	3f013b03          	ld	s6,1008(sp)
    80005ace:	3e813b83          	ld	s7,1000(sp)
    80005ad2:	3e013c03          	ld	s8,992(sp)
    80005ad6:	3d813c83          	ld	s9,984(sp)
    80005ada:	3d013d03          	ld	s10,976(sp)
    80005ade:	3c813d83          	ld	s11,968(sp)
    80005ae2:	43010113          	addi	sp,sp,1072
    80005ae6:	8082                	ret
    end_op();
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	210080e7          	jalr	528(ra) # 80004cf8 <end_op>
    return -1;
    80005af0:	557d                	li	a0,-1
    80005af2:	bf75                	j	80005aae <exec+0x122>
  if((pagetable = proc_pagetable(p)) == 0)
    80005af4:	c0843503          	ld	a0,-1016(s0)
    80005af8:	ffffc097          	auipc	ra,0xffffc
    80005afc:	fa0080e7          	jalr	-96(ra) # 80001a98 <proc_pagetable>
    80005b00:	8b2a                	mv	s6,a0
    80005b02:	d935                	beqz	a0,80005a76 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b04:	e6842783          	lw	a5,-408(s0)
    80005b08:	e8045703          	lhu	a4,-384(s0)
    80005b0c:	c735                	beqz	a4,80005b78 <exec+0x1ec>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b0e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b10:	c0043023          	sd	zero,-1024(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005b14:	6a85                	lui	s5,0x1
    80005b16:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80005b1a:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005b1e:	6d85                	lui	s11,0x1
    80005b20:	7d7d                	lui	s10,0xfffff
    80005b22:	a4ad                	j	80005d8c <exec+0x400>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005b24:	00004517          	auipc	a0,0x4
    80005b28:	eec50513          	addi	a0,a0,-276 # 80009a10 <syscalls+0x2f0>
    80005b2c:	ffffb097          	auipc	ra,0xffffb
    80005b30:	9fe080e7          	jalr	-1538(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005b34:	874a                	mv	a4,s2
    80005b36:	009c86bb          	addw	a3,s9,s1
    80005b3a:	4581                	li	a1,0
    80005b3c:	8552                	mv	a0,s4
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	706080e7          	jalr	1798(ra) # 80004244 <readi>
    80005b46:	2501                	sext.w	a0,a0
    80005b48:	1aa91c63          	bne	s2,a0,80005d00 <exec+0x374>
  for(i = 0; i < sz; i += PGSIZE){
    80005b4c:	009d84bb          	addw	s1,s11,s1
    80005b50:	013d09bb          	addw	s3,s10,s3
    80005b54:	2174fc63          	bgeu	s1,s7,80005d6c <exec+0x3e0>
    pa = walkaddr(pagetable, va + i);
    80005b58:	02049593          	slli	a1,s1,0x20
    80005b5c:	9181                	srli	a1,a1,0x20
    80005b5e:	95e2                	add	a1,a1,s8
    80005b60:	855a                	mv	a0,s6
    80005b62:	ffffb097          	auipc	ra,0xffffb
    80005b66:	4ea080e7          	jalr	1258(ra) # 8000104c <walkaddr>
    80005b6a:	862a                	mv	a2,a0
    if(pa == 0)
    80005b6c:	dd45                	beqz	a0,80005b24 <exec+0x198>
      n = PGSIZE;
    80005b6e:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    80005b70:	fd59f2e3          	bgeu	s3,s5,80005b34 <exec+0x1a8>
      n = sz - i;
    80005b74:	894e                	mv	s2,s3
    80005b76:	bf7d                	j	80005b34 <exec+0x1a8>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005b78:	4481                	li	s1,0
  iunlockput(ip);
    80005b7a:	8552                	mv	a0,s4
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	676080e7          	jalr	1654(ra) # 800041f2 <iunlockput>
  end_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	174080e7          	jalr	372(ra) # 80004cf8 <end_op>
  p = myproc();
    80005b8c:	ffffc097          	auipc	ra,0xffffc
    80005b90:	e48080e7          	jalr	-440(ra) # 800019d4 <myproc>
    80005b94:	c0a43423          	sd	a0,-1016(s0)
  uint64 oldsz = p->sz;
    80005b98:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005b9c:	6785                	lui	a5,0x1
    80005b9e:	17fd                	addi	a5,a5,-1
    80005ba0:	94be                	add	s1,s1,a5
    80005ba2:	77fd                	lui	a5,0xfffff
    80005ba4:	8fe5                	and	a5,a5,s1
    80005ba6:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005baa:	6609                	lui	a2,0x2
    80005bac:	963e                	add	a2,a2,a5
    80005bae:	85be                	mv	a1,a5
    80005bb0:	855a                	mv	a0,s6
    80005bb2:	ffffc097          	auipc	ra,0xffffc
    80005bb6:	882080e7          	jalr	-1918(ra) # 80001434 <uvmalloc>
    80005bba:	8aaa                	mv	s5,a0
  ip = 0;
    80005bbc:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005bbe:	14050163          	beqz	a0,80005d00 <exec+0x374>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005bc2:	75f9                	lui	a1,0xffffe
    80005bc4:	95aa                	add	a1,a1,a0
    80005bc6:	855a                	mv	a0,s6
    80005bc8:	ffffc097          	auipc	ra,0xffffc
    80005bcc:	a9a080e7          	jalr	-1382(ra) # 80001662 <uvmclear>
  stackbase = sp - PGSIZE;
    80005bd0:	7bfd                	lui	s7,0xfffff
    80005bd2:	9bd6                	add	s7,s7,s5
  for(argc = 0; argv[argc]; argc++) {
    80005bd4:	be843783          	ld	a5,-1048(s0)
    80005bd8:	6388                	ld	a0,0(a5)
    80005bda:	c925                	beqz	a0,80005c4a <exec+0x2be>
    80005bdc:	e8840993          	addi	s3,s0,-376
    80005be0:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005be4:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005be6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005be8:	ffffb097          	auipc	ra,0xffffb
    80005bec:	25a080e7          	jalr	602(ra) # 80000e42 <strlen>
    80005bf0:	0015079b          	addiw	a5,a0,1
    80005bf4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005bf8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005bfc:	15796c63          	bltu	s2,s7,80005d54 <exec+0x3c8>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005c00:	be843d03          	ld	s10,-1048(s0)
    80005c04:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80005c08:	8552                	mv	a0,s4
    80005c0a:	ffffb097          	auipc	ra,0xffffb
    80005c0e:	238080e7          	jalr	568(ra) # 80000e42 <strlen>
    80005c12:	0015069b          	addiw	a3,a0,1
    80005c16:	8652                	mv	a2,s4
    80005c18:	85ca                	mv	a1,s2
    80005c1a:	855a                	mv	a0,s6
    80005c1c:	ffffc097          	auipc	ra,0xffffc
    80005c20:	a78080e7          	jalr	-1416(ra) # 80001694 <copyout>
    80005c24:	12054c63          	bltz	a0,80005d5c <exec+0x3d0>
    ustack[argc] = sp;
    80005c28:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005c2c:	0485                	addi	s1,s1,1
    80005c2e:	008d0793          	addi	a5,s10,8
    80005c32:	bef43423          	sd	a5,-1048(s0)
    80005c36:	008d3503          	ld	a0,8(s10)
    80005c3a:	c911                	beqz	a0,80005c4e <exec+0x2c2>
    if(argc >= MAXARG)
    80005c3c:	09a1                	addi	s3,s3,8
    80005c3e:	fb8995e3          	bne	s3,s8,80005be8 <exec+0x25c>
  sz = sz1;
    80005c42:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005c46:	4a01                	li	s4,0
    80005c48:	a865                	j	80005d00 <exec+0x374>
  sp = sz;
    80005c4a:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005c4c:	4481                	li	s1,0
  ustack[argc] = 0;
    80005c4e:	00349793          	slli	a5,s1,0x3
    80005c52:	f9040713          	addi	a4,s0,-112
    80005c56:	97ba                	add	a5,a5,a4
    80005c58:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005c5c:	00148693          	addi	a3,s1,1
    80005c60:	068e                	slli	a3,a3,0x3
    80005c62:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c66:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005c6a:	01797663          	bgeu	s2,s7,80005c76 <exec+0x2ea>
  sz = sz1;
    80005c6e:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005c72:	4a01                	li	s4,0
    80005c74:	a071                	j	80005d00 <exec+0x374>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c76:	e8840613          	addi	a2,s0,-376
    80005c7a:	85ca                	mv	a1,s2
    80005c7c:	855a                	mv	a0,s6
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	a16080e7          	jalr	-1514(ra) # 80001694 <copyout>
    80005c86:	0c054f63          	bltz	a0,80005d64 <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005c8a:	c0843783          	ld	a5,-1016(s0)
    80005c8e:	6fbc                	ld	a5,88(a5)
    80005c90:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c94:	be043783          	ld	a5,-1056(s0)
    80005c98:	0007c703          	lbu	a4,0(a5)
    80005c9c:	cf11                	beqz	a4,80005cb8 <exec+0x32c>
    80005c9e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005ca0:	02f00693          	li	a3,47
    80005ca4:	a039                	j	80005cb2 <exec+0x326>
      last = s+1;
    80005ca6:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005caa:	0785                	addi	a5,a5,1
    80005cac:	fff7c703          	lbu	a4,-1(a5)
    80005cb0:	c701                	beqz	a4,80005cb8 <exec+0x32c>
    if(*s == '/')
    80005cb2:	fed71ce3          	bne	a4,a3,80005caa <exec+0x31e>
    80005cb6:	bfc5                	j	80005ca6 <exec+0x31a>
  safestrcpy(p->name, last, sizeof(p->name));
    80005cb8:	4641                	li	a2,16
    80005cba:	be043583          	ld	a1,-1056(s0)
    80005cbe:	c0843983          	ld	s3,-1016(s0)
    80005cc2:	15898513          	addi	a0,s3,344
    80005cc6:	ffffb097          	auipc	ra,0xffffb
    80005cca:	14a080e7          	jalr	330(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005cce:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005cd2:	0569b823          	sd	s6,80(s3)
  p->sz = sz;
    80005cd6:	0559b423          	sd	s5,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005cda:	0589b783          	ld	a5,88(s3)
    80005cde:	e6043703          	ld	a4,-416(s0)
    80005ce2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005ce4:	0589b783          	ld	a5,88(s3)
    80005ce8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005cec:	85e6                	mv	a1,s9
    80005cee:	ffffc097          	auipc	ra,0xffffc
    80005cf2:	e46080e7          	jalr	-442(ra) # 80001b34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005cf6:	0004851b          	sext.w	a0,s1
    80005cfa:	bb55                	j	80005aae <exec+0x122>
    80005cfc:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005d00:	10000613          	li	a2,256
    80005d04:	d1040593          	addi	a1,s0,-752
    80005d08:	c0843483          	ld	s1,-1016(s0)
    80005d0c:	17048513          	addi	a0,s1,368
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	00a080e7          	jalr	10(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005d18:	10000613          	li	a2,256
    80005d1c:	c1040593          	addi	a1,s0,-1008
    80005d20:	27048513          	addi	a0,s1,624
    80005d24:	ffffb097          	auipc	ra,0xffffb
    80005d28:	ff6080e7          	jalr	-10(ra) # 80000d1a <memmove>
    proc_freepagetable(pagetable, sz);
    80005d2c:	bf043583          	ld	a1,-1040(s0)
    80005d30:	855a                	mv	a0,s6
    80005d32:	ffffc097          	auipc	ra,0xffffc
    80005d36:	e02080e7          	jalr	-510(ra) # 80001b34 <proc_freepagetable>
  if(ip){
    80005d3a:	d60a10e3          	bnez	s4,80005a9a <exec+0x10e>
  return -1;
    80005d3e:	557d                	li	a0,-1
    80005d40:	b3bd                	j	80005aae <exec+0x122>
    80005d42:	be943823          	sd	s1,-1040(s0)
    80005d46:	bf6d                	j	80005d00 <exec+0x374>
    80005d48:	be943823          	sd	s1,-1040(s0)
    80005d4c:	bf55                	j	80005d00 <exec+0x374>
    80005d4e:	be943823          	sd	s1,-1040(s0)
    80005d52:	b77d                	j	80005d00 <exec+0x374>
  sz = sz1;
    80005d54:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d58:	4a01                	li	s4,0
    80005d5a:	b75d                	j	80005d00 <exec+0x374>
  sz = sz1;
    80005d5c:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d60:	4a01                	li	s4,0
    80005d62:	bf79                	j	80005d00 <exec+0x374>
  sz = sz1;
    80005d64:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005d68:	4a01                	li	s4,0
    80005d6a:	bf59                	j	80005d00 <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d6c:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d70:	c0043783          	ld	a5,-1024(s0)
    80005d74:	0017869b          	addiw	a3,a5,1
    80005d78:	c0d43023          	sd	a3,-1024(s0)
    80005d7c:	bf843783          	ld	a5,-1032(s0)
    80005d80:	0387879b          	addiw	a5,a5,56
    80005d84:	e8045703          	lhu	a4,-384(s0)
    80005d88:	dee6d9e3          	bge	a3,a4,80005b7a <exec+0x1ee>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005d8c:	2781                	sext.w	a5,a5
    80005d8e:	bef43c23          	sd	a5,-1032(s0)
    80005d92:	03800713          	li	a4,56
    80005d96:	86be                	mv	a3,a5
    80005d98:	e1040613          	addi	a2,s0,-496
    80005d9c:	4581                	li	a1,0
    80005d9e:	8552                	mv	a0,s4
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	4a4080e7          	jalr	1188(ra) # 80004244 <readi>
    80005da8:	03800793          	li	a5,56
    80005dac:	f4f518e3          	bne	a0,a5,80005cfc <exec+0x370>
    if(ph.type != ELF_PROG_LOAD)
    80005db0:	e1042783          	lw	a5,-496(s0)
    80005db4:	4705                	li	a4,1
    80005db6:	fae79de3          	bne	a5,a4,80005d70 <exec+0x3e4>
    if(ph.memsz < ph.filesz)
    80005dba:	e3843603          	ld	a2,-456(s0)
    80005dbe:	e3043783          	ld	a5,-464(s0)
    80005dc2:	f8f660e3          	bltu	a2,a5,80005d42 <exec+0x3b6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005dc6:	e2043783          	ld	a5,-480(s0)
    80005dca:	963e                	add	a2,a2,a5
    80005dcc:	f6f66ee3          	bltu	a2,a5,80005d48 <exec+0x3bc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005dd0:	85a6                	mv	a1,s1
    80005dd2:	855a                	mv	a0,s6
    80005dd4:	ffffb097          	auipc	ra,0xffffb
    80005dd8:	660080e7          	jalr	1632(ra) # 80001434 <uvmalloc>
    80005ddc:	bea43823          	sd	a0,-1040(s0)
    80005de0:	d53d                	beqz	a0,80005d4e <exec+0x3c2>
    if(ph.vaddr % PGSIZE != 0)
    80005de2:	e2043c03          	ld	s8,-480(s0)
    80005de6:	bd843783          	ld	a5,-1064(s0)
    80005dea:	00fc77b3          	and	a5,s8,a5
    80005dee:	fb89                	bnez	a5,80005d00 <exec+0x374>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005df0:	e1842c83          	lw	s9,-488(s0)
    80005df4:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005df8:	f60b8ae3          	beqz	s7,80005d6c <exec+0x3e0>
    80005dfc:	89de                	mv	s3,s7
    80005dfe:	4481                	li	s1,0
    80005e00:	bba1                	j	80005b58 <exec+0x1cc>

0000000080005e02 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005e02:	7179                	addi	sp,sp,-48
    80005e04:	f406                	sd	ra,40(sp)
    80005e06:	f022                	sd	s0,32(sp)
    80005e08:	ec26                	sd	s1,24(sp)
    80005e0a:	e84a                	sd	s2,16(sp)
    80005e0c:	1800                	addi	s0,sp,48
    80005e0e:	892e                	mv	s2,a1
    80005e10:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005e12:	fdc40593          	addi	a1,s0,-36
    80005e16:	ffffd097          	auipc	ra,0xffffd
    80005e1a:	608080e7          	jalr	1544(ra) # 8000341e <argint>
    80005e1e:	04054063          	bltz	a0,80005e5e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005e22:	fdc42703          	lw	a4,-36(s0)
    80005e26:	47bd                	li	a5,15
    80005e28:	02e7ed63          	bltu	a5,a4,80005e62 <argfd+0x60>
    80005e2c:	ffffc097          	auipc	ra,0xffffc
    80005e30:	ba8080e7          	jalr	-1112(ra) # 800019d4 <myproc>
    80005e34:	fdc42703          	lw	a4,-36(s0)
    80005e38:	01a70793          	addi	a5,a4,26
    80005e3c:	078e                	slli	a5,a5,0x3
    80005e3e:	953e                	add	a0,a0,a5
    80005e40:	611c                	ld	a5,0(a0)
    80005e42:	c395                	beqz	a5,80005e66 <argfd+0x64>
    return -1;
  if(pfd)
    80005e44:	00090463          	beqz	s2,80005e4c <argfd+0x4a>
    *pfd = fd;
    80005e48:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005e4c:	4501                	li	a0,0
  if(pf)
    80005e4e:	c091                	beqz	s1,80005e52 <argfd+0x50>
    *pf = f;
    80005e50:	e09c                	sd	a5,0(s1)
}
    80005e52:	70a2                	ld	ra,40(sp)
    80005e54:	7402                	ld	s0,32(sp)
    80005e56:	64e2                	ld	s1,24(sp)
    80005e58:	6942                	ld	s2,16(sp)
    80005e5a:	6145                	addi	sp,sp,48
    80005e5c:	8082                	ret
    return -1;
    80005e5e:	557d                	li	a0,-1
    80005e60:	bfcd                	j	80005e52 <argfd+0x50>
    return -1;
    80005e62:	557d                	li	a0,-1
    80005e64:	b7fd                	j	80005e52 <argfd+0x50>
    80005e66:	557d                	li	a0,-1
    80005e68:	b7ed                	j	80005e52 <argfd+0x50>

0000000080005e6a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005e6a:	1101                	addi	sp,sp,-32
    80005e6c:	ec06                	sd	ra,24(sp)
    80005e6e:	e822                	sd	s0,16(sp)
    80005e70:	e426                	sd	s1,8(sp)
    80005e72:	1000                	addi	s0,sp,32
    80005e74:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005e76:	ffffc097          	auipc	ra,0xffffc
    80005e7a:	b5e080e7          	jalr	-1186(ra) # 800019d4 <myproc>
    80005e7e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005e80:	0d050793          	addi	a5,a0,208
    80005e84:	4501                	li	a0,0
    80005e86:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005e88:	6398                	ld	a4,0(a5)
    80005e8a:	cb19                	beqz	a4,80005ea0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005e8c:	2505                	addiw	a0,a0,1
    80005e8e:	07a1                	addi	a5,a5,8
    80005e90:	fed51ce3          	bne	a0,a3,80005e88 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005e94:	557d                	li	a0,-1
}
    80005e96:	60e2                	ld	ra,24(sp)
    80005e98:	6442                	ld	s0,16(sp)
    80005e9a:	64a2                	ld	s1,8(sp)
    80005e9c:	6105                	addi	sp,sp,32
    80005e9e:	8082                	ret
      p->ofile[fd] = f;
    80005ea0:	01a50793          	addi	a5,a0,26
    80005ea4:	078e                	slli	a5,a5,0x3
    80005ea6:	963e                	add	a2,a2,a5
    80005ea8:	e204                	sd	s1,0(a2)
      return fd;
    80005eaa:	b7f5                	j	80005e96 <fdalloc+0x2c>

0000000080005eac <sys_dup>:

uint64
sys_dup(void)
{
    80005eac:	7179                	addi	sp,sp,-48
    80005eae:	f406                	sd	ra,40(sp)
    80005eb0:	f022                	sd	s0,32(sp)
    80005eb2:	ec26                	sd	s1,24(sp)
    80005eb4:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005eb6:	fd840613          	addi	a2,s0,-40
    80005eba:	4581                	li	a1,0
    80005ebc:	4501                	li	a0,0
    80005ebe:	00000097          	auipc	ra,0x0
    80005ec2:	f44080e7          	jalr	-188(ra) # 80005e02 <argfd>
    return -1;
    80005ec6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005ec8:	02054363          	bltz	a0,80005eee <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005ecc:	fd843503          	ld	a0,-40(s0)
    80005ed0:	00000097          	auipc	ra,0x0
    80005ed4:	f9a080e7          	jalr	-102(ra) # 80005e6a <fdalloc>
    80005ed8:	84aa                	mv	s1,a0
    return -1;
    80005eda:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005edc:	00054963          	bltz	a0,80005eee <sys_dup+0x42>
  filedup(f);
    80005ee0:	fd843503          	ld	a0,-40(s0)
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	20e080e7          	jalr	526(ra) # 800050f2 <filedup>
  return fd;
    80005eec:	87a6                	mv	a5,s1
}
    80005eee:	853e                	mv	a0,a5
    80005ef0:	70a2                	ld	ra,40(sp)
    80005ef2:	7402                	ld	s0,32(sp)
    80005ef4:	64e2                	ld	s1,24(sp)
    80005ef6:	6145                	addi	sp,sp,48
    80005ef8:	8082                	ret

0000000080005efa <sys_read>:

uint64
sys_read(void)
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
    80005f0e:	ef8080e7          	jalr	-264(ra) # 80005e02 <argfd>
    return -1;
    80005f12:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f14:	04054163          	bltz	a0,80005f56 <sys_read+0x5c>
    80005f18:	fe440593          	addi	a1,s0,-28
    80005f1c:	4509                	li	a0,2
    80005f1e:	ffffd097          	auipc	ra,0xffffd
    80005f22:	500080e7          	jalr	1280(ra) # 8000341e <argint>
    return -1;
    80005f26:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f28:	02054763          	bltz	a0,80005f56 <sys_read+0x5c>
    80005f2c:	fd840593          	addi	a1,s0,-40
    80005f30:	4505                	li	a0,1
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	50e080e7          	jalr	1294(ra) # 80003440 <argaddr>
    return -1;
    80005f3a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f3c:	00054d63          	bltz	a0,80005f56 <sys_read+0x5c>
  return fileread(f, p, n);
    80005f40:	fe442603          	lw	a2,-28(s0)
    80005f44:	fd843583          	ld	a1,-40(s0)
    80005f48:	fe843503          	ld	a0,-24(s0)
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	332080e7          	jalr	818(ra) # 8000527e <fileread>
    80005f54:	87aa                	mv	a5,a0
}
    80005f56:	853e                	mv	a0,a5
    80005f58:	70a2                	ld	ra,40(sp)
    80005f5a:	7402                	ld	s0,32(sp)
    80005f5c:	6145                	addi	sp,sp,48
    80005f5e:	8082                	ret

0000000080005f60 <sys_write>:

uint64
sys_write(void)
{
    80005f60:	7179                	addi	sp,sp,-48
    80005f62:	f406                	sd	ra,40(sp)
    80005f64:	f022                	sd	s0,32(sp)
    80005f66:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f68:	fe840613          	addi	a2,s0,-24
    80005f6c:	4581                	li	a1,0
    80005f6e:	4501                	li	a0,0
    80005f70:	00000097          	auipc	ra,0x0
    80005f74:	e92080e7          	jalr	-366(ra) # 80005e02 <argfd>
    return -1;
    80005f78:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f7a:	04054163          	bltz	a0,80005fbc <sys_write+0x5c>
    80005f7e:	fe440593          	addi	a1,s0,-28
    80005f82:	4509                	li	a0,2
    80005f84:	ffffd097          	auipc	ra,0xffffd
    80005f88:	49a080e7          	jalr	1178(ra) # 8000341e <argint>
    return -1;
    80005f8c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f8e:	02054763          	bltz	a0,80005fbc <sys_write+0x5c>
    80005f92:	fd840593          	addi	a1,s0,-40
    80005f96:	4505                	li	a0,1
    80005f98:	ffffd097          	auipc	ra,0xffffd
    80005f9c:	4a8080e7          	jalr	1192(ra) # 80003440 <argaddr>
    return -1;
    80005fa0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fa2:	00054d63          	bltz	a0,80005fbc <sys_write+0x5c>

  return filewrite(f, p, n);
    80005fa6:	fe442603          	lw	a2,-28(s0)
    80005faa:	fd843583          	ld	a1,-40(s0)
    80005fae:	fe843503          	ld	a0,-24(s0)
    80005fb2:	fffff097          	auipc	ra,0xfffff
    80005fb6:	38e080e7          	jalr	910(ra) # 80005340 <filewrite>
    80005fba:	87aa                	mv	a5,a0
}
    80005fbc:	853e                	mv	a0,a5
    80005fbe:	70a2                	ld	ra,40(sp)
    80005fc0:	7402                	ld	s0,32(sp)
    80005fc2:	6145                	addi	sp,sp,48
    80005fc4:	8082                	ret

0000000080005fc6 <sys_close>:

uint64
sys_close(void)
{
    80005fc6:	1101                	addi	sp,sp,-32
    80005fc8:	ec06                	sd	ra,24(sp)
    80005fca:	e822                	sd	s0,16(sp)
    80005fcc:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005fce:	fe040613          	addi	a2,s0,-32
    80005fd2:	fec40593          	addi	a1,s0,-20
    80005fd6:	4501                	li	a0,0
    80005fd8:	00000097          	auipc	ra,0x0
    80005fdc:	e2a080e7          	jalr	-470(ra) # 80005e02 <argfd>
    return -1;
    80005fe0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005fe2:	02054463          	bltz	a0,8000600a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005fe6:	ffffc097          	auipc	ra,0xffffc
    80005fea:	9ee080e7          	jalr	-1554(ra) # 800019d4 <myproc>
    80005fee:	fec42783          	lw	a5,-20(s0)
    80005ff2:	07e9                	addi	a5,a5,26
    80005ff4:	078e                	slli	a5,a5,0x3
    80005ff6:	97aa                	add	a5,a5,a0
    80005ff8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005ffc:	fe043503          	ld	a0,-32(s0)
    80006000:	fffff097          	auipc	ra,0xfffff
    80006004:	144080e7          	jalr	324(ra) # 80005144 <fileclose>
  return 0;
    80006008:	4781                	li	a5,0
}
    8000600a:	853e                	mv	a0,a5
    8000600c:	60e2                	ld	ra,24(sp)
    8000600e:	6442                	ld	s0,16(sp)
    80006010:	6105                	addi	sp,sp,32
    80006012:	8082                	ret

0000000080006014 <sys_fstat>:

uint64
sys_fstat(void)
{
    80006014:	1101                	addi	sp,sp,-32
    80006016:	ec06                	sd	ra,24(sp)
    80006018:	e822                	sd	s0,16(sp)
    8000601a:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000601c:	fe840613          	addi	a2,s0,-24
    80006020:	4581                	li	a1,0
    80006022:	4501                	li	a0,0
    80006024:	00000097          	auipc	ra,0x0
    80006028:	dde080e7          	jalr	-546(ra) # 80005e02 <argfd>
    return -1;
    8000602c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000602e:	02054563          	bltz	a0,80006058 <sys_fstat+0x44>
    80006032:	fe040593          	addi	a1,s0,-32
    80006036:	4505                	li	a0,1
    80006038:	ffffd097          	auipc	ra,0xffffd
    8000603c:	408080e7          	jalr	1032(ra) # 80003440 <argaddr>
    return -1;
    80006040:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006042:	00054b63          	bltz	a0,80006058 <sys_fstat+0x44>
  return filestat(f, st);
    80006046:	fe043583          	ld	a1,-32(s0)
    8000604a:	fe843503          	ld	a0,-24(s0)
    8000604e:	fffff097          	auipc	ra,0xfffff
    80006052:	1be080e7          	jalr	446(ra) # 8000520c <filestat>
    80006056:	87aa                	mv	a5,a0
}
    80006058:	853e                	mv	a0,a5
    8000605a:	60e2                	ld	ra,24(sp)
    8000605c:	6442                	ld	s0,16(sp)
    8000605e:	6105                	addi	sp,sp,32
    80006060:	8082                	ret

0000000080006062 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80006062:	7169                	addi	sp,sp,-304
    80006064:	f606                	sd	ra,296(sp)
    80006066:	f222                	sd	s0,288(sp)
    80006068:	ee26                	sd	s1,280(sp)
    8000606a:	ea4a                	sd	s2,272(sp)
    8000606c:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000606e:	08000613          	li	a2,128
    80006072:	ed040593          	addi	a1,s0,-304
    80006076:	4501                	li	a0,0
    80006078:	ffffd097          	auipc	ra,0xffffd
    8000607c:	3ea080e7          	jalr	1002(ra) # 80003462 <argstr>
    return -1;
    80006080:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006082:	10054e63          	bltz	a0,8000619e <sys_link+0x13c>
    80006086:	08000613          	li	a2,128
    8000608a:	f5040593          	addi	a1,s0,-176
    8000608e:	4505                	li	a0,1
    80006090:	ffffd097          	auipc	ra,0xffffd
    80006094:	3d2080e7          	jalr	978(ra) # 80003462 <argstr>
    return -1;
    80006098:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000609a:	10054263          	bltz	a0,8000619e <sys_link+0x13c>

  begin_op();
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	bda080e7          	jalr	-1062(ra) # 80004c78 <begin_op>
  if((ip = namei(old)) == 0){
    800060a6:	ed040513          	addi	a0,s0,-304
    800060aa:	ffffe097          	auipc	ra,0xffffe
    800060ae:	69c080e7          	jalr	1692(ra) # 80004746 <namei>
    800060b2:	84aa                	mv	s1,a0
    800060b4:	c551                	beqz	a0,80006140 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    800060b6:	ffffe097          	auipc	ra,0xffffe
    800060ba:	eda080e7          	jalr	-294(ra) # 80003f90 <ilock>
  if(ip->type == T_DIR){
    800060be:	04449703          	lh	a4,68(s1)
    800060c2:	4785                	li	a5,1
    800060c4:	08f70463          	beq	a4,a5,8000614c <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    800060c8:	04a4d783          	lhu	a5,74(s1)
    800060cc:	2785                	addiw	a5,a5,1
    800060ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060d2:	8526                	mv	a0,s1
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	df2080e7          	jalr	-526(ra) # 80003ec6 <iupdate>
  iunlock(ip);
    800060dc:	8526                	mv	a0,s1
    800060de:	ffffe097          	auipc	ra,0xffffe
    800060e2:	f74080e7          	jalr	-140(ra) # 80004052 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    800060e6:	fd040593          	addi	a1,s0,-48
    800060ea:	f5040513          	addi	a0,s0,-176
    800060ee:	ffffe097          	auipc	ra,0xffffe
    800060f2:	676080e7          	jalr	1654(ra) # 80004764 <nameiparent>
    800060f6:	892a                	mv	s2,a0
    800060f8:	c935                	beqz	a0,8000616c <sys_link+0x10a>
    goto bad;
  ilock(dp);
    800060fa:	ffffe097          	auipc	ra,0xffffe
    800060fe:	e96080e7          	jalr	-362(ra) # 80003f90 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006102:	00092703          	lw	a4,0(s2)
    80006106:	409c                	lw	a5,0(s1)
    80006108:	04f71d63          	bne	a4,a5,80006162 <sys_link+0x100>
    8000610c:	40d0                	lw	a2,4(s1)
    8000610e:	fd040593          	addi	a1,s0,-48
    80006112:	854a                	mv	a0,s2
    80006114:	ffffe097          	auipc	ra,0xffffe
    80006118:	570080e7          	jalr	1392(ra) # 80004684 <dirlink>
    8000611c:	04054363          	bltz	a0,80006162 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80006120:	854a                	mv	a0,s2
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	0d0080e7          	jalr	208(ra) # 800041f2 <iunlockput>
  iput(ip);
    8000612a:	8526                	mv	a0,s1
    8000612c:	ffffe097          	auipc	ra,0xffffe
    80006130:	01e080e7          	jalr	30(ra) # 8000414a <iput>

  end_op();
    80006134:	fffff097          	auipc	ra,0xfffff
    80006138:	bc4080e7          	jalr	-1084(ra) # 80004cf8 <end_op>

  return 0;
    8000613c:	4781                	li	a5,0
    8000613e:	a085                	j	8000619e <sys_link+0x13c>
    end_op();
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	bb8080e7          	jalr	-1096(ra) # 80004cf8 <end_op>
    return -1;
    80006148:	57fd                	li	a5,-1
    8000614a:	a891                	j	8000619e <sys_link+0x13c>
    iunlockput(ip);
    8000614c:	8526                	mv	a0,s1
    8000614e:	ffffe097          	auipc	ra,0xffffe
    80006152:	0a4080e7          	jalr	164(ra) # 800041f2 <iunlockput>
    end_op();
    80006156:	fffff097          	auipc	ra,0xfffff
    8000615a:	ba2080e7          	jalr	-1118(ra) # 80004cf8 <end_op>
    return -1;
    8000615e:	57fd                	li	a5,-1
    80006160:	a83d                	j	8000619e <sys_link+0x13c>
    iunlockput(dp);
    80006162:	854a                	mv	a0,s2
    80006164:	ffffe097          	auipc	ra,0xffffe
    80006168:	08e080e7          	jalr	142(ra) # 800041f2 <iunlockput>

bad:
  ilock(ip);
    8000616c:	8526                	mv	a0,s1
    8000616e:	ffffe097          	auipc	ra,0xffffe
    80006172:	e22080e7          	jalr	-478(ra) # 80003f90 <ilock>
  ip->nlink--;
    80006176:	04a4d783          	lhu	a5,74(s1)
    8000617a:	37fd                	addiw	a5,a5,-1
    8000617c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006180:	8526                	mv	a0,s1
    80006182:	ffffe097          	auipc	ra,0xffffe
    80006186:	d44080e7          	jalr	-700(ra) # 80003ec6 <iupdate>
  iunlockput(ip);
    8000618a:	8526                	mv	a0,s1
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	066080e7          	jalr	102(ra) # 800041f2 <iunlockput>
  end_op();
    80006194:	fffff097          	auipc	ra,0xfffff
    80006198:	b64080e7          	jalr	-1180(ra) # 80004cf8 <end_op>
  return -1;
    8000619c:	57fd                	li	a5,-1
}
    8000619e:	853e                	mv	a0,a5
    800061a0:	70b2                	ld	ra,296(sp)
    800061a2:	7412                	ld	s0,288(sp)
    800061a4:	64f2                	ld	s1,280(sp)
    800061a6:	6952                	ld	s2,272(sp)
    800061a8:	6155                	addi	sp,sp,304
    800061aa:	8082                	ret

00000000800061ac <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061ac:	4578                	lw	a4,76(a0)
    800061ae:	02000793          	li	a5,32
    800061b2:	04e7fa63          	bgeu	a5,a4,80006206 <isdirempty+0x5a>
{
    800061b6:	7179                	addi	sp,sp,-48
    800061b8:	f406                	sd	ra,40(sp)
    800061ba:	f022                	sd	s0,32(sp)
    800061bc:	ec26                	sd	s1,24(sp)
    800061be:	e84a                	sd	s2,16(sp)
    800061c0:	1800                	addi	s0,sp,48
    800061c2:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061c4:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061c8:	4741                	li	a4,16
    800061ca:	86a6                	mv	a3,s1
    800061cc:	fd040613          	addi	a2,s0,-48
    800061d0:	4581                	li	a1,0
    800061d2:	854a                	mv	a0,s2
    800061d4:	ffffe097          	auipc	ra,0xffffe
    800061d8:	070080e7          	jalr	112(ra) # 80004244 <readi>
    800061dc:	47c1                	li	a5,16
    800061de:	00f51c63          	bne	a0,a5,800061f6 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    800061e2:	fd045783          	lhu	a5,-48(s0)
    800061e6:	e395                	bnez	a5,8000620a <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061e8:	24c1                	addiw	s1,s1,16
    800061ea:	04c92783          	lw	a5,76(s2)
    800061ee:	fcf4ede3          	bltu	s1,a5,800061c8 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    800061f2:	4505                	li	a0,1
    800061f4:	a821                	j	8000620c <isdirempty+0x60>
      panic("isdirempty: readi");
    800061f6:	00004517          	auipc	a0,0x4
    800061fa:	83a50513          	addi	a0,a0,-1990 # 80009a30 <syscalls+0x310>
    800061fe:	ffffa097          	auipc	ra,0xffffa
    80006202:	32c080e7          	jalr	812(ra) # 8000052a <panic>
  return 1;
    80006206:	4505                	li	a0,1
}
    80006208:	8082                	ret
      return 0;
    8000620a:	4501                	li	a0,0
}
    8000620c:	70a2                	ld	ra,40(sp)
    8000620e:	7402                	ld	s0,32(sp)
    80006210:	64e2                	ld	s1,24(sp)
    80006212:	6942                	ld	s2,16(sp)
    80006214:	6145                	addi	sp,sp,48
    80006216:	8082                	ret

0000000080006218 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006218:	7155                	addi	sp,sp,-208
    8000621a:	e586                	sd	ra,200(sp)
    8000621c:	e1a2                	sd	s0,192(sp)
    8000621e:	fd26                	sd	s1,184(sp)
    80006220:	f94a                	sd	s2,176(sp)
    80006222:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006224:	08000613          	li	a2,128
    80006228:	f4040593          	addi	a1,s0,-192
    8000622c:	4501                	li	a0,0
    8000622e:	ffffd097          	auipc	ra,0xffffd
    80006232:	234080e7          	jalr	564(ra) # 80003462 <argstr>
    80006236:	16054363          	bltz	a0,8000639c <sys_unlink+0x184>
    return -1;

  begin_op();
    8000623a:	fffff097          	auipc	ra,0xfffff
    8000623e:	a3e080e7          	jalr	-1474(ra) # 80004c78 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006242:	fc040593          	addi	a1,s0,-64
    80006246:	f4040513          	addi	a0,s0,-192
    8000624a:	ffffe097          	auipc	ra,0xffffe
    8000624e:	51a080e7          	jalr	1306(ra) # 80004764 <nameiparent>
    80006252:	84aa                	mv	s1,a0
    80006254:	c961                	beqz	a0,80006324 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80006256:	ffffe097          	auipc	ra,0xffffe
    8000625a:	d3a080e7          	jalr	-710(ra) # 80003f90 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000625e:	00003597          	auipc	a1,0x3
    80006262:	6b258593          	addi	a1,a1,1714 # 80009910 <syscalls+0x1f0>
    80006266:	fc040513          	addi	a0,s0,-64
    8000626a:	ffffe097          	auipc	ra,0xffffe
    8000626e:	1f0080e7          	jalr	496(ra) # 8000445a <namecmp>
    80006272:	c175                	beqz	a0,80006356 <sys_unlink+0x13e>
    80006274:	00003597          	auipc	a1,0x3
    80006278:	6a458593          	addi	a1,a1,1700 # 80009918 <syscalls+0x1f8>
    8000627c:	fc040513          	addi	a0,s0,-64
    80006280:	ffffe097          	auipc	ra,0xffffe
    80006284:	1da080e7          	jalr	474(ra) # 8000445a <namecmp>
    80006288:	c579                	beqz	a0,80006356 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    8000628a:	f3c40613          	addi	a2,s0,-196
    8000628e:	fc040593          	addi	a1,s0,-64
    80006292:	8526                	mv	a0,s1
    80006294:	ffffe097          	auipc	ra,0xffffe
    80006298:	1e0080e7          	jalr	480(ra) # 80004474 <dirlookup>
    8000629c:	892a                	mv	s2,a0
    8000629e:	cd45                	beqz	a0,80006356 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    800062a0:	ffffe097          	auipc	ra,0xffffe
    800062a4:	cf0080e7          	jalr	-784(ra) # 80003f90 <ilock>

  if(ip->nlink < 1)
    800062a8:	04a91783          	lh	a5,74(s2)
    800062ac:	08f05263          	blez	a5,80006330 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800062b0:	04491703          	lh	a4,68(s2)
    800062b4:	4785                	li	a5,1
    800062b6:	08f70563          	beq	a4,a5,80006340 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800062ba:	4641                	li	a2,16
    800062bc:	4581                	li	a1,0
    800062be:	fd040513          	addi	a0,s0,-48
    800062c2:	ffffb097          	auipc	ra,0xffffb
    800062c6:	9fc080e7          	jalr	-1540(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800062ca:	4741                	li	a4,16
    800062cc:	f3c42683          	lw	a3,-196(s0)
    800062d0:	fd040613          	addi	a2,s0,-48
    800062d4:	4581                	li	a1,0
    800062d6:	8526                	mv	a0,s1
    800062d8:	ffffe097          	auipc	ra,0xffffe
    800062dc:	064080e7          	jalr	100(ra) # 8000433c <writei>
    800062e0:	47c1                	li	a5,16
    800062e2:	08f51a63          	bne	a0,a5,80006376 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800062e6:	04491703          	lh	a4,68(s2)
    800062ea:	4785                	li	a5,1
    800062ec:	08f70d63          	beq	a4,a5,80006386 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800062f0:	8526                	mv	a0,s1
    800062f2:	ffffe097          	auipc	ra,0xffffe
    800062f6:	f00080e7          	jalr	-256(ra) # 800041f2 <iunlockput>

  ip->nlink--;
    800062fa:	04a95783          	lhu	a5,74(s2)
    800062fe:	37fd                	addiw	a5,a5,-1
    80006300:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006304:	854a                	mv	a0,s2
    80006306:	ffffe097          	auipc	ra,0xffffe
    8000630a:	bc0080e7          	jalr	-1088(ra) # 80003ec6 <iupdate>
  iunlockput(ip);
    8000630e:	854a                	mv	a0,s2
    80006310:	ffffe097          	auipc	ra,0xffffe
    80006314:	ee2080e7          	jalr	-286(ra) # 800041f2 <iunlockput>

  end_op();
    80006318:	fffff097          	auipc	ra,0xfffff
    8000631c:	9e0080e7          	jalr	-1568(ra) # 80004cf8 <end_op>

  return 0;
    80006320:	4501                	li	a0,0
    80006322:	a0a1                	j	8000636a <sys_unlink+0x152>
    end_op();
    80006324:	fffff097          	auipc	ra,0xfffff
    80006328:	9d4080e7          	jalr	-1580(ra) # 80004cf8 <end_op>
    return -1;
    8000632c:	557d                	li	a0,-1
    8000632e:	a835                	j	8000636a <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80006330:	00003517          	auipc	a0,0x3
    80006334:	5f050513          	addi	a0,a0,1520 # 80009920 <syscalls+0x200>
    80006338:	ffffa097          	auipc	ra,0xffffa
    8000633c:	1f2080e7          	jalr	498(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006340:	854a                	mv	a0,s2
    80006342:	00000097          	auipc	ra,0x0
    80006346:	e6a080e7          	jalr	-406(ra) # 800061ac <isdirempty>
    8000634a:	f925                	bnez	a0,800062ba <sys_unlink+0xa2>
    iunlockput(ip);
    8000634c:	854a                	mv	a0,s2
    8000634e:	ffffe097          	auipc	ra,0xffffe
    80006352:	ea4080e7          	jalr	-348(ra) # 800041f2 <iunlockput>

bad:
  iunlockput(dp);
    80006356:	8526                	mv	a0,s1
    80006358:	ffffe097          	auipc	ra,0xffffe
    8000635c:	e9a080e7          	jalr	-358(ra) # 800041f2 <iunlockput>
  end_op();
    80006360:	fffff097          	auipc	ra,0xfffff
    80006364:	998080e7          	jalr	-1640(ra) # 80004cf8 <end_op>
  return -1;
    80006368:	557d                	li	a0,-1
}
    8000636a:	60ae                	ld	ra,200(sp)
    8000636c:	640e                	ld	s0,192(sp)
    8000636e:	74ea                	ld	s1,184(sp)
    80006370:	794a                	ld	s2,176(sp)
    80006372:	6169                	addi	sp,sp,208
    80006374:	8082                	ret
    panic("unlink: writei");
    80006376:	00003517          	auipc	a0,0x3
    8000637a:	5c250513          	addi	a0,a0,1474 # 80009938 <syscalls+0x218>
    8000637e:	ffffa097          	auipc	ra,0xffffa
    80006382:	1ac080e7          	jalr	428(ra) # 8000052a <panic>
    dp->nlink--;
    80006386:	04a4d783          	lhu	a5,74(s1)
    8000638a:	37fd                	addiw	a5,a5,-1
    8000638c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006390:	8526                	mv	a0,s1
    80006392:	ffffe097          	auipc	ra,0xffffe
    80006396:	b34080e7          	jalr	-1228(ra) # 80003ec6 <iupdate>
    8000639a:	bf99                	j	800062f0 <sys_unlink+0xd8>
    return -1;
    8000639c:	557d                	li	a0,-1
    8000639e:	b7f1                	j	8000636a <sys_unlink+0x152>

00000000800063a0 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    800063a0:	715d                	addi	sp,sp,-80
    800063a2:	e486                	sd	ra,72(sp)
    800063a4:	e0a2                	sd	s0,64(sp)
    800063a6:	fc26                	sd	s1,56(sp)
    800063a8:	f84a                	sd	s2,48(sp)
    800063aa:	f44e                	sd	s3,40(sp)
    800063ac:	f052                	sd	s4,32(sp)
    800063ae:	ec56                	sd	s5,24(sp)
    800063b0:	0880                	addi	s0,sp,80
    800063b2:	89ae                	mv	s3,a1
    800063b4:	8ab2                	mv	s5,a2
    800063b6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800063b8:	fb040593          	addi	a1,s0,-80
    800063bc:	ffffe097          	auipc	ra,0xffffe
    800063c0:	3a8080e7          	jalr	936(ra) # 80004764 <nameiparent>
    800063c4:	892a                	mv	s2,a0
    800063c6:	12050e63          	beqz	a0,80006502 <create+0x162>
    return 0;

  ilock(dp);
    800063ca:	ffffe097          	auipc	ra,0xffffe
    800063ce:	bc6080e7          	jalr	-1082(ra) # 80003f90 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    800063d2:	4601                	li	a2,0
    800063d4:	fb040593          	addi	a1,s0,-80
    800063d8:	854a                	mv	a0,s2
    800063da:	ffffe097          	auipc	ra,0xffffe
    800063de:	09a080e7          	jalr	154(ra) # 80004474 <dirlookup>
    800063e2:	84aa                	mv	s1,a0
    800063e4:	c921                	beqz	a0,80006434 <create+0x94>
    iunlockput(dp);
    800063e6:	854a                	mv	a0,s2
    800063e8:	ffffe097          	auipc	ra,0xffffe
    800063ec:	e0a080e7          	jalr	-502(ra) # 800041f2 <iunlockput>
    ilock(ip);
    800063f0:	8526                	mv	a0,s1
    800063f2:	ffffe097          	auipc	ra,0xffffe
    800063f6:	b9e080e7          	jalr	-1122(ra) # 80003f90 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800063fa:	2981                	sext.w	s3,s3
    800063fc:	4789                	li	a5,2
    800063fe:	02f99463          	bne	s3,a5,80006426 <create+0x86>
    80006402:	0444d783          	lhu	a5,68(s1)
    80006406:	37f9                	addiw	a5,a5,-2
    80006408:	17c2                	slli	a5,a5,0x30
    8000640a:	93c1                	srli	a5,a5,0x30
    8000640c:	4705                	li	a4,1
    8000640e:	00f76c63          	bltu	a4,a5,80006426 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006412:	8526                	mv	a0,s1
    80006414:	60a6                	ld	ra,72(sp)
    80006416:	6406                	ld	s0,64(sp)
    80006418:	74e2                	ld	s1,56(sp)
    8000641a:	7942                	ld	s2,48(sp)
    8000641c:	79a2                	ld	s3,40(sp)
    8000641e:	7a02                	ld	s4,32(sp)
    80006420:	6ae2                	ld	s5,24(sp)
    80006422:	6161                	addi	sp,sp,80
    80006424:	8082                	ret
    iunlockput(ip);
    80006426:	8526                	mv	a0,s1
    80006428:	ffffe097          	auipc	ra,0xffffe
    8000642c:	dca080e7          	jalr	-566(ra) # 800041f2 <iunlockput>
    return 0;
    80006430:	4481                	li	s1,0
    80006432:	b7c5                	j	80006412 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80006434:	85ce                	mv	a1,s3
    80006436:	00092503          	lw	a0,0(s2)
    8000643a:	ffffe097          	auipc	ra,0xffffe
    8000643e:	9be080e7          	jalr	-1602(ra) # 80003df8 <ialloc>
    80006442:	84aa                	mv	s1,a0
    80006444:	c521                	beqz	a0,8000648c <create+0xec>
  ilock(ip);
    80006446:	ffffe097          	auipc	ra,0xffffe
    8000644a:	b4a080e7          	jalr	-1206(ra) # 80003f90 <ilock>
  ip->major = major;
    8000644e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006452:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006456:	4a05                	li	s4,1
    80006458:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000645c:	8526                	mv	a0,s1
    8000645e:	ffffe097          	auipc	ra,0xffffe
    80006462:	a68080e7          	jalr	-1432(ra) # 80003ec6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006466:	2981                	sext.w	s3,s3
    80006468:	03498a63          	beq	s3,s4,8000649c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000646c:	40d0                	lw	a2,4(s1)
    8000646e:	fb040593          	addi	a1,s0,-80
    80006472:	854a                	mv	a0,s2
    80006474:	ffffe097          	auipc	ra,0xffffe
    80006478:	210080e7          	jalr	528(ra) # 80004684 <dirlink>
    8000647c:	06054b63          	bltz	a0,800064f2 <create+0x152>
  iunlockput(dp);
    80006480:	854a                	mv	a0,s2
    80006482:	ffffe097          	auipc	ra,0xffffe
    80006486:	d70080e7          	jalr	-656(ra) # 800041f2 <iunlockput>
  return ip;
    8000648a:	b761                	j	80006412 <create+0x72>
    panic("create: ialloc");
    8000648c:	00003517          	auipc	a0,0x3
    80006490:	5bc50513          	addi	a0,a0,1468 # 80009a48 <syscalls+0x328>
    80006494:	ffffa097          	auipc	ra,0xffffa
    80006498:	096080e7          	jalr	150(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000649c:	04a95783          	lhu	a5,74(s2)
    800064a0:	2785                	addiw	a5,a5,1
    800064a2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800064a6:	854a                	mv	a0,s2
    800064a8:	ffffe097          	auipc	ra,0xffffe
    800064ac:	a1e080e7          	jalr	-1506(ra) # 80003ec6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800064b0:	40d0                	lw	a2,4(s1)
    800064b2:	00003597          	auipc	a1,0x3
    800064b6:	45e58593          	addi	a1,a1,1118 # 80009910 <syscalls+0x1f0>
    800064ba:	8526                	mv	a0,s1
    800064bc:	ffffe097          	auipc	ra,0xffffe
    800064c0:	1c8080e7          	jalr	456(ra) # 80004684 <dirlink>
    800064c4:	00054f63          	bltz	a0,800064e2 <create+0x142>
    800064c8:	00492603          	lw	a2,4(s2)
    800064cc:	00003597          	auipc	a1,0x3
    800064d0:	44c58593          	addi	a1,a1,1100 # 80009918 <syscalls+0x1f8>
    800064d4:	8526                	mv	a0,s1
    800064d6:	ffffe097          	auipc	ra,0xffffe
    800064da:	1ae080e7          	jalr	430(ra) # 80004684 <dirlink>
    800064de:	f80557e3          	bgez	a0,8000646c <create+0xcc>
      panic("create dots");
    800064e2:	00003517          	auipc	a0,0x3
    800064e6:	57650513          	addi	a0,a0,1398 # 80009a58 <syscalls+0x338>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	040080e7          	jalr	64(ra) # 8000052a <panic>
    panic("create: dirlink");
    800064f2:	00003517          	auipc	a0,0x3
    800064f6:	57650513          	addi	a0,a0,1398 # 80009a68 <syscalls+0x348>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	030080e7          	jalr	48(ra) # 8000052a <panic>
    return 0;
    80006502:	84aa                	mv	s1,a0
    80006504:	b739                	j	80006412 <create+0x72>

0000000080006506 <sys_open>:

uint64
sys_open(void)
{
    80006506:	7131                	addi	sp,sp,-192
    80006508:	fd06                	sd	ra,184(sp)
    8000650a:	f922                	sd	s0,176(sp)
    8000650c:	f526                	sd	s1,168(sp)
    8000650e:	f14a                	sd	s2,160(sp)
    80006510:	ed4e                	sd	s3,152(sp)
    80006512:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006514:	08000613          	li	a2,128
    80006518:	f5040593          	addi	a1,s0,-176
    8000651c:	4501                	li	a0,0
    8000651e:	ffffd097          	auipc	ra,0xffffd
    80006522:	f44080e7          	jalr	-188(ra) # 80003462 <argstr>
    return -1;
    80006526:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006528:	0c054163          	bltz	a0,800065ea <sys_open+0xe4>
    8000652c:	f4c40593          	addi	a1,s0,-180
    80006530:	4505                	li	a0,1
    80006532:	ffffd097          	auipc	ra,0xffffd
    80006536:	eec080e7          	jalr	-276(ra) # 8000341e <argint>
    8000653a:	0a054863          	bltz	a0,800065ea <sys_open+0xe4>

  begin_op();
    8000653e:	ffffe097          	auipc	ra,0xffffe
    80006542:	73a080e7          	jalr	1850(ra) # 80004c78 <begin_op>

  if(omode & O_CREATE){
    80006546:	f4c42783          	lw	a5,-180(s0)
    8000654a:	2007f793          	andi	a5,a5,512
    8000654e:	cbdd                	beqz	a5,80006604 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006550:	4681                	li	a3,0
    80006552:	4601                	li	a2,0
    80006554:	4589                	li	a1,2
    80006556:	f5040513          	addi	a0,s0,-176
    8000655a:	00000097          	auipc	ra,0x0
    8000655e:	e46080e7          	jalr	-442(ra) # 800063a0 <create>
    80006562:	892a                	mv	s2,a0
    if(ip == 0){
    80006564:	c959                	beqz	a0,800065fa <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006566:	04491703          	lh	a4,68(s2)
    8000656a:	478d                	li	a5,3
    8000656c:	00f71763          	bne	a4,a5,8000657a <sys_open+0x74>
    80006570:	04695703          	lhu	a4,70(s2)
    80006574:	47a5                	li	a5,9
    80006576:	0ce7ec63          	bltu	a5,a4,8000664e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000657a:	fffff097          	auipc	ra,0xfffff
    8000657e:	b0e080e7          	jalr	-1266(ra) # 80005088 <filealloc>
    80006582:	89aa                	mv	s3,a0
    80006584:	10050263          	beqz	a0,80006688 <sys_open+0x182>
    80006588:	00000097          	auipc	ra,0x0
    8000658c:	8e2080e7          	jalr	-1822(ra) # 80005e6a <fdalloc>
    80006590:	84aa                	mv	s1,a0
    80006592:	0e054663          	bltz	a0,8000667e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006596:	04491703          	lh	a4,68(s2)
    8000659a:	478d                	li	a5,3
    8000659c:	0cf70463          	beq	a4,a5,80006664 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800065a0:	4789                	li	a5,2
    800065a2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800065a6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800065aa:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800065ae:	f4c42783          	lw	a5,-180(s0)
    800065b2:	0017c713          	xori	a4,a5,1
    800065b6:	8b05                	andi	a4,a4,1
    800065b8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800065bc:	0037f713          	andi	a4,a5,3
    800065c0:	00e03733          	snez	a4,a4
    800065c4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800065c8:	4007f793          	andi	a5,a5,1024
    800065cc:	c791                	beqz	a5,800065d8 <sys_open+0xd2>
    800065ce:	04491703          	lh	a4,68(s2)
    800065d2:	4789                	li	a5,2
    800065d4:	08f70f63          	beq	a4,a5,80006672 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800065d8:	854a                	mv	a0,s2
    800065da:	ffffe097          	auipc	ra,0xffffe
    800065de:	a78080e7          	jalr	-1416(ra) # 80004052 <iunlock>
  end_op();
    800065e2:	ffffe097          	auipc	ra,0xffffe
    800065e6:	716080e7          	jalr	1814(ra) # 80004cf8 <end_op>

  return fd;
}
    800065ea:	8526                	mv	a0,s1
    800065ec:	70ea                	ld	ra,184(sp)
    800065ee:	744a                	ld	s0,176(sp)
    800065f0:	74aa                	ld	s1,168(sp)
    800065f2:	790a                	ld	s2,160(sp)
    800065f4:	69ea                	ld	s3,152(sp)
    800065f6:	6129                	addi	sp,sp,192
    800065f8:	8082                	ret
      end_op();
    800065fa:	ffffe097          	auipc	ra,0xffffe
    800065fe:	6fe080e7          	jalr	1790(ra) # 80004cf8 <end_op>
      return -1;
    80006602:	b7e5                	j	800065ea <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006604:	f5040513          	addi	a0,s0,-176
    80006608:	ffffe097          	auipc	ra,0xffffe
    8000660c:	13e080e7          	jalr	318(ra) # 80004746 <namei>
    80006610:	892a                	mv	s2,a0
    80006612:	c905                	beqz	a0,80006642 <sys_open+0x13c>
    ilock(ip);
    80006614:	ffffe097          	auipc	ra,0xffffe
    80006618:	97c080e7          	jalr	-1668(ra) # 80003f90 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000661c:	04491703          	lh	a4,68(s2)
    80006620:	4785                	li	a5,1
    80006622:	f4f712e3          	bne	a4,a5,80006566 <sys_open+0x60>
    80006626:	f4c42783          	lw	a5,-180(s0)
    8000662a:	dba1                	beqz	a5,8000657a <sys_open+0x74>
      iunlockput(ip);
    8000662c:	854a                	mv	a0,s2
    8000662e:	ffffe097          	auipc	ra,0xffffe
    80006632:	bc4080e7          	jalr	-1084(ra) # 800041f2 <iunlockput>
      end_op();
    80006636:	ffffe097          	auipc	ra,0xffffe
    8000663a:	6c2080e7          	jalr	1730(ra) # 80004cf8 <end_op>
      return -1;
    8000663e:	54fd                	li	s1,-1
    80006640:	b76d                	j	800065ea <sys_open+0xe4>
      end_op();
    80006642:	ffffe097          	auipc	ra,0xffffe
    80006646:	6b6080e7          	jalr	1718(ra) # 80004cf8 <end_op>
      return -1;
    8000664a:	54fd                	li	s1,-1
    8000664c:	bf79                	j	800065ea <sys_open+0xe4>
    iunlockput(ip);
    8000664e:	854a                	mv	a0,s2
    80006650:	ffffe097          	auipc	ra,0xffffe
    80006654:	ba2080e7          	jalr	-1118(ra) # 800041f2 <iunlockput>
    end_op();
    80006658:	ffffe097          	auipc	ra,0xffffe
    8000665c:	6a0080e7          	jalr	1696(ra) # 80004cf8 <end_op>
    return -1;
    80006660:	54fd                	li	s1,-1
    80006662:	b761                	j	800065ea <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006664:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006668:	04691783          	lh	a5,70(s2)
    8000666c:	02f99223          	sh	a5,36(s3)
    80006670:	bf2d                	j	800065aa <sys_open+0xa4>
    itrunc(ip);
    80006672:	854a                	mv	a0,s2
    80006674:	ffffe097          	auipc	ra,0xffffe
    80006678:	a2a080e7          	jalr	-1494(ra) # 8000409e <itrunc>
    8000667c:	bfb1                	j	800065d8 <sys_open+0xd2>
      fileclose(f);
    8000667e:	854e                	mv	a0,s3
    80006680:	fffff097          	auipc	ra,0xfffff
    80006684:	ac4080e7          	jalr	-1340(ra) # 80005144 <fileclose>
    iunlockput(ip);
    80006688:	854a                	mv	a0,s2
    8000668a:	ffffe097          	auipc	ra,0xffffe
    8000668e:	b68080e7          	jalr	-1176(ra) # 800041f2 <iunlockput>
    end_op();
    80006692:	ffffe097          	auipc	ra,0xffffe
    80006696:	666080e7          	jalr	1638(ra) # 80004cf8 <end_op>
    return -1;
    8000669a:	54fd                	li	s1,-1
    8000669c:	b7b9                	j	800065ea <sys_open+0xe4>

000000008000669e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000669e:	7175                	addi	sp,sp,-144
    800066a0:	e506                	sd	ra,136(sp)
    800066a2:	e122                	sd	s0,128(sp)
    800066a4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800066a6:	ffffe097          	auipc	ra,0xffffe
    800066aa:	5d2080e7          	jalr	1490(ra) # 80004c78 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800066ae:	08000613          	li	a2,128
    800066b2:	f7040593          	addi	a1,s0,-144
    800066b6:	4501                	li	a0,0
    800066b8:	ffffd097          	auipc	ra,0xffffd
    800066bc:	daa080e7          	jalr	-598(ra) # 80003462 <argstr>
    800066c0:	02054963          	bltz	a0,800066f2 <sys_mkdir+0x54>
    800066c4:	4681                	li	a3,0
    800066c6:	4601                	li	a2,0
    800066c8:	4585                	li	a1,1
    800066ca:	f7040513          	addi	a0,s0,-144
    800066ce:	00000097          	auipc	ra,0x0
    800066d2:	cd2080e7          	jalr	-814(ra) # 800063a0 <create>
    800066d6:	cd11                	beqz	a0,800066f2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066d8:	ffffe097          	auipc	ra,0xffffe
    800066dc:	b1a080e7          	jalr	-1254(ra) # 800041f2 <iunlockput>
  end_op();
    800066e0:	ffffe097          	auipc	ra,0xffffe
    800066e4:	618080e7          	jalr	1560(ra) # 80004cf8 <end_op>
  return 0;
    800066e8:	4501                	li	a0,0
}
    800066ea:	60aa                	ld	ra,136(sp)
    800066ec:	640a                	ld	s0,128(sp)
    800066ee:	6149                	addi	sp,sp,144
    800066f0:	8082                	ret
    end_op();
    800066f2:	ffffe097          	auipc	ra,0xffffe
    800066f6:	606080e7          	jalr	1542(ra) # 80004cf8 <end_op>
    return -1;
    800066fa:	557d                	li	a0,-1
    800066fc:	b7fd                	j	800066ea <sys_mkdir+0x4c>

00000000800066fe <sys_mknod>:

uint64
sys_mknod(void)
{
    800066fe:	7135                	addi	sp,sp,-160
    80006700:	ed06                	sd	ra,152(sp)
    80006702:	e922                	sd	s0,144(sp)
    80006704:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006706:	ffffe097          	auipc	ra,0xffffe
    8000670a:	572080e7          	jalr	1394(ra) # 80004c78 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000670e:	08000613          	li	a2,128
    80006712:	f7040593          	addi	a1,s0,-144
    80006716:	4501                	li	a0,0
    80006718:	ffffd097          	auipc	ra,0xffffd
    8000671c:	d4a080e7          	jalr	-694(ra) # 80003462 <argstr>
    80006720:	04054a63          	bltz	a0,80006774 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006724:	f6c40593          	addi	a1,s0,-148
    80006728:	4505                	li	a0,1
    8000672a:	ffffd097          	auipc	ra,0xffffd
    8000672e:	cf4080e7          	jalr	-780(ra) # 8000341e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006732:	04054163          	bltz	a0,80006774 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006736:	f6840593          	addi	a1,s0,-152
    8000673a:	4509                	li	a0,2
    8000673c:	ffffd097          	auipc	ra,0xffffd
    80006740:	ce2080e7          	jalr	-798(ra) # 8000341e <argint>
     argint(1, &major) < 0 ||
    80006744:	02054863          	bltz	a0,80006774 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006748:	f6841683          	lh	a3,-152(s0)
    8000674c:	f6c41603          	lh	a2,-148(s0)
    80006750:	458d                	li	a1,3
    80006752:	f7040513          	addi	a0,s0,-144
    80006756:	00000097          	auipc	ra,0x0
    8000675a:	c4a080e7          	jalr	-950(ra) # 800063a0 <create>
     argint(2, &minor) < 0 ||
    8000675e:	c919                	beqz	a0,80006774 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006760:	ffffe097          	auipc	ra,0xffffe
    80006764:	a92080e7          	jalr	-1390(ra) # 800041f2 <iunlockput>
  end_op();
    80006768:	ffffe097          	auipc	ra,0xffffe
    8000676c:	590080e7          	jalr	1424(ra) # 80004cf8 <end_op>
  return 0;
    80006770:	4501                	li	a0,0
    80006772:	a031                	j	8000677e <sys_mknod+0x80>
    end_op();
    80006774:	ffffe097          	auipc	ra,0xffffe
    80006778:	584080e7          	jalr	1412(ra) # 80004cf8 <end_op>
    return -1;
    8000677c:	557d                	li	a0,-1
}
    8000677e:	60ea                	ld	ra,152(sp)
    80006780:	644a                	ld	s0,144(sp)
    80006782:	610d                	addi	sp,sp,160
    80006784:	8082                	ret

0000000080006786 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006786:	7135                	addi	sp,sp,-160
    80006788:	ed06                	sd	ra,152(sp)
    8000678a:	e922                	sd	s0,144(sp)
    8000678c:	e526                	sd	s1,136(sp)
    8000678e:	e14a                	sd	s2,128(sp)
    80006790:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006792:	ffffb097          	auipc	ra,0xffffb
    80006796:	242080e7          	jalr	578(ra) # 800019d4 <myproc>
    8000679a:	892a                	mv	s2,a0
  
  begin_op();
    8000679c:	ffffe097          	auipc	ra,0xffffe
    800067a0:	4dc080e7          	jalr	1244(ra) # 80004c78 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800067a4:	08000613          	li	a2,128
    800067a8:	f6040593          	addi	a1,s0,-160
    800067ac:	4501                	li	a0,0
    800067ae:	ffffd097          	auipc	ra,0xffffd
    800067b2:	cb4080e7          	jalr	-844(ra) # 80003462 <argstr>
    800067b6:	04054b63          	bltz	a0,8000680c <sys_chdir+0x86>
    800067ba:	f6040513          	addi	a0,s0,-160
    800067be:	ffffe097          	auipc	ra,0xffffe
    800067c2:	f88080e7          	jalr	-120(ra) # 80004746 <namei>
    800067c6:	84aa                	mv	s1,a0
    800067c8:	c131                	beqz	a0,8000680c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800067ca:	ffffd097          	auipc	ra,0xffffd
    800067ce:	7c6080e7          	jalr	1990(ra) # 80003f90 <ilock>
  if(ip->type != T_DIR){
    800067d2:	04449703          	lh	a4,68(s1)
    800067d6:	4785                	li	a5,1
    800067d8:	04f71063          	bne	a4,a5,80006818 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800067dc:	8526                	mv	a0,s1
    800067de:	ffffe097          	auipc	ra,0xffffe
    800067e2:	874080e7          	jalr	-1932(ra) # 80004052 <iunlock>
  iput(p->cwd);
    800067e6:	15093503          	ld	a0,336(s2)
    800067ea:	ffffe097          	auipc	ra,0xffffe
    800067ee:	960080e7          	jalr	-1696(ra) # 8000414a <iput>
  end_op();
    800067f2:	ffffe097          	auipc	ra,0xffffe
    800067f6:	506080e7          	jalr	1286(ra) # 80004cf8 <end_op>
  p->cwd = ip;
    800067fa:	14993823          	sd	s1,336(s2)
  return 0;
    800067fe:	4501                	li	a0,0
}
    80006800:	60ea                	ld	ra,152(sp)
    80006802:	644a                	ld	s0,144(sp)
    80006804:	64aa                	ld	s1,136(sp)
    80006806:	690a                	ld	s2,128(sp)
    80006808:	610d                	addi	sp,sp,160
    8000680a:	8082                	ret
    end_op();
    8000680c:	ffffe097          	auipc	ra,0xffffe
    80006810:	4ec080e7          	jalr	1260(ra) # 80004cf8 <end_op>
    return -1;
    80006814:	557d                	li	a0,-1
    80006816:	b7ed                	j	80006800 <sys_chdir+0x7a>
    iunlockput(ip);
    80006818:	8526                	mv	a0,s1
    8000681a:	ffffe097          	auipc	ra,0xffffe
    8000681e:	9d8080e7          	jalr	-1576(ra) # 800041f2 <iunlockput>
    end_op();
    80006822:	ffffe097          	auipc	ra,0xffffe
    80006826:	4d6080e7          	jalr	1238(ra) # 80004cf8 <end_op>
    return -1;
    8000682a:	557d                	li	a0,-1
    8000682c:	bfd1                	j	80006800 <sys_chdir+0x7a>

000000008000682e <sys_exec>:

uint64
sys_exec(void)
{
    8000682e:	7145                	addi	sp,sp,-464
    80006830:	e786                	sd	ra,456(sp)
    80006832:	e3a2                	sd	s0,448(sp)
    80006834:	ff26                	sd	s1,440(sp)
    80006836:	fb4a                	sd	s2,432(sp)
    80006838:	f74e                	sd	s3,424(sp)
    8000683a:	f352                	sd	s4,416(sp)
    8000683c:	ef56                	sd	s5,408(sp)
    8000683e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006840:	08000613          	li	a2,128
    80006844:	f4040593          	addi	a1,s0,-192
    80006848:	4501                	li	a0,0
    8000684a:	ffffd097          	auipc	ra,0xffffd
    8000684e:	c18080e7          	jalr	-1000(ra) # 80003462 <argstr>
    return -1;
    80006852:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006854:	0c054a63          	bltz	a0,80006928 <sys_exec+0xfa>
    80006858:	e3840593          	addi	a1,s0,-456
    8000685c:	4505                	li	a0,1
    8000685e:	ffffd097          	auipc	ra,0xffffd
    80006862:	be2080e7          	jalr	-1054(ra) # 80003440 <argaddr>
    80006866:	0c054163          	bltz	a0,80006928 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000686a:	10000613          	li	a2,256
    8000686e:	4581                	li	a1,0
    80006870:	e4040513          	addi	a0,s0,-448
    80006874:	ffffa097          	auipc	ra,0xffffa
    80006878:	44a080e7          	jalr	1098(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000687c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006880:	89a6                	mv	s3,s1
    80006882:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006884:	02000a13          	li	s4,32
    80006888:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000688c:	00391793          	slli	a5,s2,0x3
    80006890:	e3040593          	addi	a1,s0,-464
    80006894:	e3843503          	ld	a0,-456(s0)
    80006898:	953e                	add	a0,a0,a5
    8000689a:	ffffd097          	auipc	ra,0xffffd
    8000689e:	aea080e7          	jalr	-1302(ra) # 80003384 <fetchaddr>
    800068a2:	02054a63          	bltz	a0,800068d6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800068a6:	e3043783          	ld	a5,-464(s0)
    800068aa:	c3b9                	beqz	a5,800068f0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800068ac:	ffffa097          	auipc	ra,0xffffa
    800068b0:	226080e7          	jalr	550(ra) # 80000ad2 <kalloc>
    800068b4:	85aa                	mv	a1,a0
    800068b6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800068ba:	cd11                	beqz	a0,800068d6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800068bc:	6605                	lui	a2,0x1
    800068be:	e3043503          	ld	a0,-464(s0)
    800068c2:	ffffd097          	auipc	ra,0xffffd
    800068c6:	b14080e7          	jalr	-1260(ra) # 800033d6 <fetchstr>
    800068ca:	00054663          	bltz	a0,800068d6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800068ce:	0905                	addi	s2,s2,1
    800068d0:	09a1                	addi	s3,s3,8
    800068d2:	fb491be3          	bne	s2,s4,80006888 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068d6:	10048913          	addi	s2,s1,256
    800068da:	6088                	ld	a0,0(s1)
    800068dc:	c529                	beqz	a0,80006926 <sys_exec+0xf8>
    kfree(argv[i]);
    800068de:	ffffa097          	auipc	ra,0xffffa
    800068e2:	0f8080e7          	jalr	248(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800068e6:	04a1                	addi	s1,s1,8
    800068e8:	ff2499e3          	bne	s1,s2,800068da <sys_exec+0xac>
  return -1;
    800068ec:	597d                	li	s2,-1
    800068ee:	a82d                	j	80006928 <sys_exec+0xfa>
      argv[i] = 0;
    800068f0:	0a8e                	slli	s5,s5,0x3
    800068f2:	fc040793          	addi	a5,s0,-64
    800068f6:	9abe                	add	s5,s5,a5
    800068f8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800068fc:	e4040593          	addi	a1,s0,-448
    80006900:	f4040513          	addi	a0,s0,-192
    80006904:	fffff097          	auipc	ra,0xfffff
    80006908:	088080e7          	jalr	136(ra) # 8000598c <exec>
    8000690c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000690e:	10048993          	addi	s3,s1,256
    80006912:	6088                	ld	a0,0(s1)
    80006914:	c911                	beqz	a0,80006928 <sys_exec+0xfa>
    kfree(argv[i]);
    80006916:	ffffa097          	auipc	ra,0xffffa
    8000691a:	0c0080e7          	jalr	192(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000691e:	04a1                	addi	s1,s1,8
    80006920:	ff3499e3          	bne	s1,s3,80006912 <sys_exec+0xe4>
    80006924:	a011                	j	80006928 <sys_exec+0xfa>
  return -1;
    80006926:	597d                	li	s2,-1
}
    80006928:	854a                	mv	a0,s2
    8000692a:	60be                	ld	ra,456(sp)
    8000692c:	641e                	ld	s0,448(sp)
    8000692e:	74fa                	ld	s1,440(sp)
    80006930:	795a                	ld	s2,432(sp)
    80006932:	79ba                	ld	s3,424(sp)
    80006934:	7a1a                	ld	s4,416(sp)
    80006936:	6afa                	ld	s5,408(sp)
    80006938:	6179                	addi	sp,sp,464
    8000693a:	8082                	ret

000000008000693c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000693c:	7139                	addi	sp,sp,-64
    8000693e:	fc06                	sd	ra,56(sp)
    80006940:	f822                	sd	s0,48(sp)
    80006942:	f426                	sd	s1,40(sp)
    80006944:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006946:	ffffb097          	auipc	ra,0xffffb
    8000694a:	08e080e7          	jalr	142(ra) # 800019d4 <myproc>
    8000694e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006950:	fd840593          	addi	a1,s0,-40
    80006954:	4501                	li	a0,0
    80006956:	ffffd097          	auipc	ra,0xffffd
    8000695a:	aea080e7          	jalr	-1302(ra) # 80003440 <argaddr>
    return -1;
    8000695e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006960:	0e054063          	bltz	a0,80006a40 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006964:	fc840593          	addi	a1,s0,-56
    80006968:	fd040513          	addi	a0,s0,-48
    8000696c:	fffff097          	auipc	ra,0xfffff
    80006970:	cfe080e7          	jalr	-770(ra) # 8000566a <pipealloc>
    return -1;
    80006974:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006976:	0c054563          	bltz	a0,80006a40 <sys_pipe+0x104>
  fd0 = -1;
    8000697a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000697e:	fd043503          	ld	a0,-48(s0)
    80006982:	fffff097          	auipc	ra,0xfffff
    80006986:	4e8080e7          	jalr	1256(ra) # 80005e6a <fdalloc>
    8000698a:	fca42223          	sw	a0,-60(s0)
    8000698e:	08054c63          	bltz	a0,80006a26 <sys_pipe+0xea>
    80006992:	fc843503          	ld	a0,-56(s0)
    80006996:	fffff097          	auipc	ra,0xfffff
    8000699a:	4d4080e7          	jalr	1236(ra) # 80005e6a <fdalloc>
    8000699e:	fca42023          	sw	a0,-64(s0)
    800069a2:	06054863          	bltz	a0,80006a12 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800069a6:	4691                	li	a3,4
    800069a8:	fc440613          	addi	a2,s0,-60
    800069ac:	fd843583          	ld	a1,-40(s0)
    800069b0:	68a8                	ld	a0,80(s1)
    800069b2:	ffffb097          	auipc	ra,0xffffb
    800069b6:	ce2080e7          	jalr	-798(ra) # 80001694 <copyout>
    800069ba:	02054063          	bltz	a0,800069da <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800069be:	4691                	li	a3,4
    800069c0:	fc040613          	addi	a2,s0,-64
    800069c4:	fd843583          	ld	a1,-40(s0)
    800069c8:	0591                	addi	a1,a1,4
    800069ca:	68a8                	ld	a0,80(s1)
    800069cc:	ffffb097          	auipc	ra,0xffffb
    800069d0:	cc8080e7          	jalr	-824(ra) # 80001694 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800069d4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800069d6:	06055563          	bgez	a0,80006a40 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800069da:	fc442783          	lw	a5,-60(s0)
    800069de:	07e9                	addi	a5,a5,26
    800069e0:	078e                	slli	a5,a5,0x3
    800069e2:	97a6                	add	a5,a5,s1
    800069e4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800069e8:	fc042503          	lw	a0,-64(s0)
    800069ec:	0569                	addi	a0,a0,26
    800069ee:	050e                	slli	a0,a0,0x3
    800069f0:	9526                	add	a0,a0,s1
    800069f2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800069f6:	fd043503          	ld	a0,-48(s0)
    800069fa:	ffffe097          	auipc	ra,0xffffe
    800069fe:	74a080e7          	jalr	1866(ra) # 80005144 <fileclose>
    fileclose(wf);
    80006a02:	fc843503          	ld	a0,-56(s0)
    80006a06:	ffffe097          	auipc	ra,0xffffe
    80006a0a:	73e080e7          	jalr	1854(ra) # 80005144 <fileclose>
    return -1;
    80006a0e:	57fd                	li	a5,-1
    80006a10:	a805                	j	80006a40 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006a12:	fc442783          	lw	a5,-60(s0)
    80006a16:	0007c863          	bltz	a5,80006a26 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006a1a:	01a78513          	addi	a0,a5,26
    80006a1e:	050e                	slli	a0,a0,0x3
    80006a20:	9526                	add	a0,a0,s1
    80006a22:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006a26:	fd043503          	ld	a0,-48(s0)
    80006a2a:	ffffe097          	auipc	ra,0xffffe
    80006a2e:	71a080e7          	jalr	1818(ra) # 80005144 <fileclose>
    fileclose(wf);
    80006a32:	fc843503          	ld	a0,-56(s0)
    80006a36:	ffffe097          	auipc	ra,0xffffe
    80006a3a:	70e080e7          	jalr	1806(ra) # 80005144 <fileclose>
    return -1;
    80006a3e:	57fd                	li	a5,-1
}
    80006a40:	853e                	mv	a0,a5
    80006a42:	70e2                	ld	ra,56(sp)
    80006a44:	7442                	ld	s0,48(sp)
    80006a46:	74a2                	ld	s1,40(sp)
    80006a48:	6121                	addi	sp,sp,64
    80006a4a:	8082                	ret
    80006a4c:	0000                	unimp
	...

0000000080006a50 <kernelvec>:
    80006a50:	7111                	addi	sp,sp,-256
    80006a52:	e006                	sd	ra,0(sp)
    80006a54:	e40a                	sd	sp,8(sp)
    80006a56:	e80e                	sd	gp,16(sp)
    80006a58:	ec12                	sd	tp,24(sp)
    80006a5a:	f016                	sd	t0,32(sp)
    80006a5c:	f41a                	sd	t1,40(sp)
    80006a5e:	f81e                	sd	t2,48(sp)
    80006a60:	fc22                	sd	s0,56(sp)
    80006a62:	e0a6                	sd	s1,64(sp)
    80006a64:	e4aa                	sd	a0,72(sp)
    80006a66:	e8ae                	sd	a1,80(sp)
    80006a68:	ecb2                	sd	a2,88(sp)
    80006a6a:	f0b6                	sd	a3,96(sp)
    80006a6c:	f4ba                	sd	a4,104(sp)
    80006a6e:	f8be                	sd	a5,112(sp)
    80006a70:	fcc2                	sd	a6,120(sp)
    80006a72:	e146                	sd	a7,128(sp)
    80006a74:	e54a                	sd	s2,136(sp)
    80006a76:	e94e                	sd	s3,144(sp)
    80006a78:	ed52                	sd	s4,152(sp)
    80006a7a:	f156                	sd	s5,160(sp)
    80006a7c:	f55a                	sd	s6,168(sp)
    80006a7e:	f95e                	sd	s7,176(sp)
    80006a80:	fd62                	sd	s8,184(sp)
    80006a82:	e1e6                	sd	s9,192(sp)
    80006a84:	e5ea                	sd	s10,200(sp)
    80006a86:	e9ee                	sd	s11,208(sp)
    80006a88:	edf2                	sd	t3,216(sp)
    80006a8a:	f1f6                	sd	t4,224(sp)
    80006a8c:	f5fa                	sd	t5,232(sp)
    80006a8e:	f9fe                	sd	t6,240(sp)
    80006a90:	fc0fc0ef          	jal	ra,80003250 <kerneltrap>
    80006a94:	6082                	ld	ra,0(sp)
    80006a96:	6122                	ld	sp,8(sp)
    80006a98:	61c2                	ld	gp,16(sp)
    80006a9a:	7282                	ld	t0,32(sp)
    80006a9c:	7322                	ld	t1,40(sp)
    80006a9e:	73c2                	ld	t2,48(sp)
    80006aa0:	7462                	ld	s0,56(sp)
    80006aa2:	6486                	ld	s1,64(sp)
    80006aa4:	6526                	ld	a0,72(sp)
    80006aa6:	65c6                	ld	a1,80(sp)
    80006aa8:	6666                	ld	a2,88(sp)
    80006aaa:	7686                	ld	a3,96(sp)
    80006aac:	7726                	ld	a4,104(sp)
    80006aae:	77c6                	ld	a5,112(sp)
    80006ab0:	7866                	ld	a6,120(sp)
    80006ab2:	688a                	ld	a7,128(sp)
    80006ab4:	692a                	ld	s2,136(sp)
    80006ab6:	69ca                	ld	s3,144(sp)
    80006ab8:	6a6a                	ld	s4,152(sp)
    80006aba:	7a8a                	ld	s5,160(sp)
    80006abc:	7b2a                	ld	s6,168(sp)
    80006abe:	7bca                	ld	s7,176(sp)
    80006ac0:	7c6a                	ld	s8,184(sp)
    80006ac2:	6c8e                	ld	s9,192(sp)
    80006ac4:	6d2e                	ld	s10,200(sp)
    80006ac6:	6dce                	ld	s11,208(sp)
    80006ac8:	6e6e                	ld	t3,216(sp)
    80006aca:	7e8e                	ld	t4,224(sp)
    80006acc:	7f2e                	ld	t5,232(sp)
    80006ace:	7fce                	ld	t6,240(sp)
    80006ad0:	6111                	addi	sp,sp,256
    80006ad2:	10200073          	sret
    80006ad6:	00000013          	nop
    80006ada:	00000013          	nop
    80006ade:	0001                	nop

0000000080006ae0 <timervec>:
    80006ae0:	34051573          	csrrw	a0,mscratch,a0
    80006ae4:	e10c                	sd	a1,0(a0)
    80006ae6:	e510                	sd	a2,8(a0)
    80006ae8:	e914                	sd	a3,16(a0)
    80006aea:	6d0c                	ld	a1,24(a0)
    80006aec:	7110                	ld	a2,32(a0)
    80006aee:	6194                	ld	a3,0(a1)
    80006af0:	96b2                	add	a3,a3,a2
    80006af2:	e194                	sd	a3,0(a1)
    80006af4:	4589                	li	a1,2
    80006af6:	14459073          	csrw	sip,a1
    80006afa:	6914                	ld	a3,16(a0)
    80006afc:	6510                	ld	a2,8(a0)
    80006afe:	610c                	ld	a1,0(a0)
    80006b00:	34051573          	csrrw	a0,mscratch,a0
    80006b04:	30200073          	mret
	...

0000000080006b0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006b0a:	1141                	addi	sp,sp,-16
    80006b0c:	e422                	sd	s0,8(sp)
    80006b0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006b10:	0c0007b7          	lui	a5,0xc000
    80006b14:	4705                	li	a4,1
    80006b16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006b18:	c3d8                	sw	a4,4(a5)
}
    80006b1a:	6422                	ld	s0,8(sp)
    80006b1c:	0141                	addi	sp,sp,16
    80006b1e:	8082                	ret

0000000080006b20 <plicinithart>:

void
plicinithart(void)
{
    80006b20:	1141                	addi	sp,sp,-16
    80006b22:	e406                	sd	ra,8(sp)
    80006b24:	e022                	sd	s0,0(sp)
    80006b26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b28:	ffffb097          	auipc	ra,0xffffb
    80006b2c:	e80080e7          	jalr	-384(ra) # 800019a8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006b30:	0085171b          	slliw	a4,a0,0x8
    80006b34:	0c0027b7          	lui	a5,0xc002
    80006b38:	97ba                	add	a5,a5,a4
    80006b3a:	40200713          	li	a4,1026
    80006b3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006b42:	00d5151b          	slliw	a0,a0,0xd
    80006b46:	0c2017b7          	lui	a5,0xc201
    80006b4a:	953e                	add	a0,a0,a5
    80006b4c:	00052023          	sw	zero,0(a0)
}
    80006b50:	60a2                	ld	ra,8(sp)
    80006b52:	6402                	ld	s0,0(sp)
    80006b54:	0141                	addi	sp,sp,16
    80006b56:	8082                	ret

0000000080006b58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006b58:	1141                	addi	sp,sp,-16
    80006b5a:	e406                	sd	ra,8(sp)
    80006b5c:	e022                	sd	s0,0(sp)
    80006b5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006b60:	ffffb097          	auipc	ra,0xffffb
    80006b64:	e48080e7          	jalr	-440(ra) # 800019a8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006b68:	00d5179b          	slliw	a5,a0,0xd
    80006b6c:	0c201537          	lui	a0,0xc201
    80006b70:	953e                	add	a0,a0,a5
  return irq;
}
    80006b72:	4148                	lw	a0,4(a0)
    80006b74:	60a2                	ld	ra,8(sp)
    80006b76:	6402                	ld	s0,0(sp)
    80006b78:	0141                	addi	sp,sp,16
    80006b7a:	8082                	ret

0000000080006b7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006b7c:	1101                	addi	sp,sp,-32
    80006b7e:	ec06                	sd	ra,24(sp)
    80006b80:	e822                	sd	s0,16(sp)
    80006b82:	e426                	sd	s1,8(sp)
    80006b84:	1000                	addi	s0,sp,32
    80006b86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006b88:	ffffb097          	auipc	ra,0xffffb
    80006b8c:	e20080e7          	jalr	-480(ra) # 800019a8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006b90:	00d5151b          	slliw	a0,a0,0xd
    80006b94:	0c2017b7          	lui	a5,0xc201
    80006b98:	97aa                	add	a5,a5,a0
    80006b9a:	c3c4                	sw	s1,4(a5)
}
    80006b9c:	60e2                	ld	ra,24(sp)
    80006b9e:	6442                	ld	s0,16(sp)
    80006ba0:	64a2                	ld	s1,8(sp)
    80006ba2:	6105                	addi	sp,sp,32
    80006ba4:	8082                	ret

0000000080006ba6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006ba6:	1141                	addi	sp,sp,-16
    80006ba8:	e406                	sd	ra,8(sp)
    80006baa:	e022                	sd	s0,0(sp)
    80006bac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006bae:	479d                	li	a5,7
    80006bb0:	06a7c963          	blt	a5,a0,80006c22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006bb4:	00025797          	auipc	a5,0x25
    80006bb8:	44c78793          	addi	a5,a5,1100 # 8002c000 <disk>
    80006bbc:	00a78733          	add	a4,a5,a0
    80006bc0:	6789                	lui	a5,0x2
    80006bc2:	97ba                	add	a5,a5,a4
    80006bc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006bc8:	e7ad                	bnez	a5,80006c32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006bca:	00451793          	slli	a5,a0,0x4
    80006bce:	00027717          	auipc	a4,0x27
    80006bd2:	43270713          	addi	a4,a4,1074 # 8002e000 <disk+0x2000>
    80006bd6:	6314                	ld	a3,0(a4)
    80006bd8:	96be                	add	a3,a3,a5
    80006bda:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006bde:	6314                	ld	a3,0(a4)
    80006be0:	96be                	add	a3,a3,a5
    80006be2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006be6:	6314                	ld	a3,0(a4)
    80006be8:	96be                	add	a3,a3,a5
    80006bea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006bee:	6318                	ld	a4,0(a4)
    80006bf0:	97ba                	add	a5,a5,a4
    80006bf2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006bf6:	00025797          	auipc	a5,0x25
    80006bfa:	40a78793          	addi	a5,a5,1034 # 8002c000 <disk>
    80006bfe:	97aa                	add	a5,a5,a0
    80006c00:	6509                	lui	a0,0x2
    80006c02:	953e                	add	a0,a0,a5
    80006c04:	4785                	li	a5,1
    80006c06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006c0a:	00027517          	auipc	a0,0x27
    80006c0e:	40e50513          	addi	a0,a0,1038 # 8002e018 <disk+0x2018>
    80006c12:	ffffb097          	auipc	ra,0xffffb
    80006c16:	4a6080e7          	jalr	1190(ra) # 800020b8 <wakeup>
}
    80006c1a:	60a2                	ld	ra,8(sp)
    80006c1c:	6402                	ld	s0,0(sp)
    80006c1e:	0141                	addi	sp,sp,16
    80006c20:	8082                	ret
    panic("free_desc 1");
    80006c22:	00003517          	auipc	a0,0x3
    80006c26:	e5650513          	addi	a0,a0,-426 # 80009a78 <syscalls+0x358>
    80006c2a:	ffffa097          	auipc	ra,0xffffa
    80006c2e:	900080e7          	jalr	-1792(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006c32:	00003517          	auipc	a0,0x3
    80006c36:	e5650513          	addi	a0,a0,-426 # 80009a88 <syscalls+0x368>
    80006c3a:	ffffa097          	auipc	ra,0xffffa
    80006c3e:	8f0080e7          	jalr	-1808(ra) # 8000052a <panic>

0000000080006c42 <virtio_disk_init>:
{
    80006c42:	1101                	addi	sp,sp,-32
    80006c44:	ec06                	sd	ra,24(sp)
    80006c46:	e822                	sd	s0,16(sp)
    80006c48:	e426                	sd	s1,8(sp)
    80006c4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006c4c:	00003597          	auipc	a1,0x3
    80006c50:	e4c58593          	addi	a1,a1,-436 # 80009a98 <syscalls+0x378>
    80006c54:	00027517          	auipc	a0,0x27
    80006c58:	4d450513          	addi	a0,a0,1236 # 8002e128 <disk+0x2128>
    80006c5c:	ffffa097          	auipc	ra,0xffffa
    80006c60:	ed6080e7          	jalr	-298(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c64:	100017b7          	lui	a5,0x10001
    80006c68:	4398                	lw	a4,0(a5)
    80006c6a:	2701                	sext.w	a4,a4
    80006c6c:	747277b7          	lui	a5,0x74727
    80006c70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006c74:	0ef71163          	bne	a4,a5,80006d56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c78:	100017b7          	lui	a5,0x10001
    80006c7c:	43dc                	lw	a5,4(a5)
    80006c7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006c80:	4705                	li	a4,1
    80006c82:	0ce79a63          	bne	a5,a4,80006d56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c86:	100017b7          	lui	a5,0x10001
    80006c8a:	479c                	lw	a5,8(a5)
    80006c8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006c8e:	4709                	li	a4,2
    80006c90:	0ce79363          	bne	a5,a4,80006d56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006c94:	100017b7          	lui	a5,0x10001
    80006c98:	47d8                	lw	a4,12(a5)
    80006c9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006c9c:	554d47b7          	lui	a5,0x554d4
    80006ca0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006ca4:	0af71963          	bne	a4,a5,80006d56 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ca8:	100017b7          	lui	a5,0x10001
    80006cac:	4705                	li	a4,1
    80006cae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cb0:	470d                	li	a4,3
    80006cb2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006cb4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006cb6:	c7ffe737          	lui	a4,0xc7ffe
    80006cba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf75f>
    80006cbe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006cc0:	2701                	sext.w	a4,a4
    80006cc2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cc4:	472d                	li	a4,11
    80006cc6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006cc8:	473d                	li	a4,15
    80006cca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006ccc:	6705                	lui	a4,0x1
    80006cce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006cd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006cd4:	5bdc                	lw	a5,52(a5)
    80006cd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006cd8:	c7d9                	beqz	a5,80006d66 <virtio_disk_init+0x124>
  if(max < NUM)
    80006cda:	471d                	li	a4,7
    80006cdc:	08f77d63          	bgeu	a4,a5,80006d76 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006ce0:	100014b7          	lui	s1,0x10001
    80006ce4:	47a1                	li	a5,8
    80006ce6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006ce8:	6609                	lui	a2,0x2
    80006cea:	4581                	li	a1,0
    80006cec:	00025517          	auipc	a0,0x25
    80006cf0:	31450513          	addi	a0,a0,788 # 8002c000 <disk>
    80006cf4:	ffffa097          	auipc	ra,0xffffa
    80006cf8:	fca080e7          	jalr	-54(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006cfc:	00025717          	auipc	a4,0x25
    80006d00:	30470713          	addi	a4,a4,772 # 8002c000 <disk>
    80006d04:	00c75793          	srli	a5,a4,0xc
    80006d08:	2781                	sext.w	a5,a5
    80006d0a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006d0c:	00027797          	auipc	a5,0x27
    80006d10:	2f478793          	addi	a5,a5,756 # 8002e000 <disk+0x2000>
    80006d14:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006d16:	00025717          	auipc	a4,0x25
    80006d1a:	36a70713          	addi	a4,a4,874 # 8002c080 <disk+0x80>
    80006d1e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006d20:	00026717          	auipc	a4,0x26
    80006d24:	2e070713          	addi	a4,a4,736 # 8002d000 <disk+0x1000>
    80006d28:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006d2a:	4705                	li	a4,1
    80006d2c:	00e78c23          	sb	a4,24(a5)
    80006d30:	00e78ca3          	sb	a4,25(a5)
    80006d34:	00e78d23          	sb	a4,26(a5)
    80006d38:	00e78da3          	sb	a4,27(a5)
    80006d3c:	00e78e23          	sb	a4,28(a5)
    80006d40:	00e78ea3          	sb	a4,29(a5)
    80006d44:	00e78f23          	sb	a4,30(a5)
    80006d48:	00e78fa3          	sb	a4,31(a5)
}
    80006d4c:	60e2                	ld	ra,24(sp)
    80006d4e:	6442                	ld	s0,16(sp)
    80006d50:	64a2                	ld	s1,8(sp)
    80006d52:	6105                	addi	sp,sp,32
    80006d54:	8082                	ret
    panic("could not find virtio disk");
    80006d56:	00003517          	auipc	a0,0x3
    80006d5a:	d5250513          	addi	a0,a0,-686 # 80009aa8 <syscalls+0x388>
    80006d5e:	ffff9097          	auipc	ra,0xffff9
    80006d62:	7cc080e7          	jalr	1996(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006d66:	00003517          	auipc	a0,0x3
    80006d6a:	d6250513          	addi	a0,a0,-670 # 80009ac8 <syscalls+0x3a8>
    80006d6e:	ffff9097          	auipc	ra,0xffff9
    80006d72:	7bc080e7          	jalr	1980(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006d76:	00003517          	auipc	a0,0x3
    80006d7a:	d7250513          	addi	a0,a0,-654 # 80009ae8 <syscalls+0x3c8>
    80006d7e:	ffff9097          	auipc	ra,0xffff9
    80006d82:	7ac080e7          	jalr	1964(ra) # 8000052a <panic>

0000000080006d86 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006d86:	7119                	addi	sp,sp,-128
    80006d88:	fc86                	sd	ra,120(sp)
    80006d8a:	f8a2                	sd	s0,112(sp)
    80006d8c:	f4a6                	sd	s1,104(sp)
    80006d8e:	f0ca                	sd	s2,96(sp)
    80006d90:	ecce                	sd	s3,88(sp)
    80006d92:	e8d2                	sd	s4,80(sp)
    80006d94:	e4d6                	sd	s5,72(sp)
    80006d96:	e0da                	sd	s6,64(sp)
    80006d98:	fc5e                	sd	s7,56(sp)
    80006d9a:	f862                	sd	s8,48(sp)
    80006d9c:	f466                	sd	s9,40(sp)
    80006d9e:	f06a                	sd	s10,32(sp)
    80006da0:	ec6e                	sd	s11,24(sp)
    80006da2:	0100                	addi	s0,sp,128
    80006da4:	8aaa                	mv	s5,a0
    80006da6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006da8:	00c52c83          	lw	s9,12(a0)
    80006dac:	001c9c9b          	slliw	s9,s9,0x1
    80006db0:	1c82                	slli	s9,s9,0x20
    80006db2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006db6:	00027517          	auipc	a0,0x27
    80006dba:	37250513          	addi	a0,a0,882 # 8002e128 <disk+0x2128>
    80006dbe:	ffffa097          	auipc	ra,0xffffa
    80006dc2:	e04080e7          	jalr	-508(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006dc6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006dc8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006dca:	00025c17          	auipc	s8,0x25
    80006dce:	236c0c13          	addi	s8,s8,566 # 8002c000 <disk>
    80006dd2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006dd4:	4b0d                	li	s6,3
    80006dd6:	a0ad                	j	80006e40 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006dd8:	00fc0733          	add	a4,s8,a5
    80006ddc:	975e                	add	a4,a4,s7
    80006dde:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006de2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006de4:	0207c563          	bltz	a5,80006e0e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006de8:	2905                	addiw	s2,s2,1
    80006dea:	0611                	addi	a2,a2,4
    80006dec:	19690d63          	beq	s2,s6,80006f86 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006df0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006df2:	00027717          	auipc	a4,0x27
    80006df6:	22670713          	addi	a4,a4,550 # 8002e018 <disk+0x2018>
    80006dfa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006dfc:	00074683          	lbu	a3,0(a4)
    80006e00:	fee1                	bnez	a3,80006dd8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006e02:	2785                	addiw	a5,a5,1
    80006e04:	0705                	addi	a4,a4,1
    80006e06:	fe979be3          	bne	a5,s1,80006dfc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006e0a:	57fd                	li	a5,-1
    80006e0c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006e0e:	01205d63          	blez	s2,80006e28 <virtio_disk_rw+0xa2>
    80006e12:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006e14:	000a2503          	lw	a0,0(s4)
    80006e18:	00000097          	auipc	ra,0x0
    80006e1c:	d8e080e7          	jalr	-626(ra) # 80006ba6 <free_desc>
      for(int j = 0; j < i; j++)
    80006e20:	2d85                	addiw	s11,s11,1
    80006e22:	0a11                	addi	s4,s4,4
    80006e24:	ffb918e3          	bne	s2,s11,80006e14 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006e28:	00027597          	auipc	a1,0x27
    80006e2c:	30058593          	addi	a1,a1,768 # 8002e128 <disk+0x2128>
    80006e30:	00027517          	auipc	a0,0x27
    80006e34:	1e850513          	addi	a0,a0,488 # 8002e018 <disk+0x2018>
    80006e38:	ffffb097          	auipc	ra,0xffffb
    80006e3c:	21c080e7          	jalr	540(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    80006e40:	f8040a13          	addi	s4,s0,-128
{
    80006e44:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006e46:	894e                	mv	s2,s3
    80006e48:	b765                	j	80006df0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006e4a:	00027697          	auipc	a3,0x27
    80006e4e:	1b66b683          	ld	a3,438(a3) # 8002e000 <disk+0x2000>
    80006e52:	96ba                	add	a3,a3,a4
    80006e54:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006e58:	00025817          	auipc	a6,0x25
    80006e5c:	1a880813          	addi	a6,a6,424 # 8002c000 <disk>
    80006e60:	00027697          	auipc	a3,0x27
    80006e64:	1a068693          	addi	a3,a3,416 # 8002e000 <disk+0x2000>
    80006e68:	6290                	ld	a2,0(a3)
    80006e6a:	963a                	add	a2,a2,a4
    80006e6c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006e70:	0015e593          	ori	a1,a1,1
    80006e74:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006e78:	f8842603          	lw	a2,-120(s0)
    80006e7c:	628c                	ld	a1,0(a3)
    80006e7e:	972e                	add	a4,a4,a1
    80006e80:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006e84:	20050593          	addi	a1,a0,512
    80006e88:	0592                	slli	a1,a1,0x4
    80006e8a:	95c2                	add	a1,a1,a6
    80006e8c:	577d                	li	a4,-1
    80006e8e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006e92:	00461713          	slli	a4,a2,0x4
    80006e96:	6290                	ld	a2,0(a3)
    80006e98:	963a                	add	a2,a2,a4
    80006e9a:	03078793          	addi	a5,a5,48
    80006e9e:	97c2                	add	a5,a5,a6
    80006ea0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006ea2:	629c                	ld	a5,0(a3)
    80006ea4:	97ba                	add	a5,a5,a4
    80006ea6:	4605                	li	a2,1
    80006ea8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006eaa:	629c                	ld	a5,0(a3)
    80006eac:	97ba                	add	a5,a5,a4
    80006eae:	4809                	li	a6,2
    80006eb0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006eb4:	629c                	ld	a5,0(a3)
    80006eb6:	973e                	add	a4,a4,a5
    80006eb8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ebc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006ec0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ec4:	6698                	ld	a4,8(a3)
    80006ec6:	00275783          	lhu	a5,2(a4)
    80006eca:	8b9d                	andi	a5,a5,7
    80006ecc:	0786                	slli	a5,a5,0x1
    80006ece:	97ba                	add	a5,a5,a4
    80006ed0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006ed4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006ed8:	6698                	ld	a4,8(a3)
    80006eda:	00275783          	lhu	a5,2(a4)
    80006ede:	2785                	addiw	a5,a5,1
    80006ee0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ee4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ee8:	100017b7          	lui	a5,0x10001
    80006eec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006ef0:	004aa783          	lw	a5,4(s5)
    80006ef4:	02c79163          	bne	a5,a2,80006f16 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006ef8:	00027917          	auipc	s2,0x27
    80006efc:	23090913          	addi	s2,s2,560 # 8002e128 <disk+0x2128>
  while(b->disk == 1) {
    80006f00:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006f02:	85ca                	mv	a1,s2
    80006f04:	8556                	mv	a0,s5
    80006f06:	ffffb097          	auipc	ra,0xffffb
    80006f0a:	14e080e7          	jalr	334(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    80006f0e:	004aa783          	lw	a5,4(s5)
    80006f12:	fe9788e3          	beq	a5,s1,80006f02 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006f16:	f8042903          	lw	s2,-128(s0)
    80006f1a:	20090793          	addi	a5,s2,512
    80006f1e:	00479713          	slli	a4,a5,0x4
    80006f22:	00025797          	auipc	a5,0x25
    80006f26:	0de78793          	addi	a5,a5,222 # 8002c000 <disk>
    80006f2a:	97ba                	add	a5,a5,a4
    80006f2c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006f30:	00027997          	auipc	s3,0x27
    80006f34:	0d098993          	addi	s3,s3,208 # 8002e000 <disk+0x2000>
    80006f38:	00491713          	slli	a4,s2,0x4
    80006f3c:	0009b783          	ld	a5,0(s3)
    80006f40:	97ba                	add	a5,a5,a4
    80006f42:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006f46:	854a                	mv	a0,s2
    80006f48:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006f4c:	00000097          	auipc	ra,0x0
    80006f50:	c5a080e7          	jalr	-934(ra) # 80006ba6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006f54:	8885                	andi	s1,s1,1
    80006f56:	f0ed                	bnez	s1,80006f38 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006f58:	00027517          	auipc	a0,0x27
    80006f5c:	1d050513          	addi	a0,a0,464 # 8002e128 <disk+0x2128>
    80006f60:	ffffa097          	auipc	ra,0xffffa
    80006f64:	d16080e7          	jalr	-746(ra) # 80000c76 <release>
}
    80006f68:	70e6                	ld	ra,120(sp)
    80006f6a:	7446                	ld	s0,112(sp)
    80006f6c:	74a6                	ld	s1,104(sp)
    80006f6e:	7906                	ld	s2,96(sp)
    80006f70:	69e6                	ld	s3,88(sp)
    80006f72:	6a46                	ld	s4,80(sp)
    80006f74:	6aa6                	ld	s5,72(sp)
    80006f76:	6b06                	ld	s6,64(sp)
    80006f78:	7be2                	ld	s7,56(sp)
    80006f7a:	7c42                	ld	s8,48(sp)
    80006f7c:	7ca2                	ld	s9,40(sp)
    80006f7e:	7d02                	ld	s10,32(sp)
    80006f80:	6de2                	ld	s11,24(sp)
    80006f82:	6109                	addi	sp,sp,128
    80006f84:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f86:	f8042503          	lw	a0,-128(s0)
    80006f8a:	20050793          	addi	a5,a0,512
    80006f8e:	0792                	slli	a5,a5,0x4
  if(write)
    80006f90:	00025817          	auipc	a6,0x25
    80006f94:	07080813          	addi	a6,a6,112 # 8002c000 <disk>
    80006f98:	00f80733          	add	a4,a6,a5
    80006f9c:	01a036b3          	snez	a3,s10
    80006fa0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006fa4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006fa8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fac:	7679                	lui	a2,0xffffe
    80006fae:	963e                	add	a2,a2,a5
    80006fb0:	00027697          	auipc	a3,0x27
    80006fb4:	05068693          	addi	a3,a3,80 # 8002e000 <disk+0x2000>
    80006fb8:	6298                	ld	a4,0(a3)
    80006fba:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006fbc:	0a878593          	addi	a1,a5,168
    80006fc0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fc2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006fc4:	6298                	ld	a4,0(a3)
    80006fc6:	9732                	add	a4,a4,a2
    80006fc8:	45c1                	li	a1,16
    80006fca:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006fcc:	6298                	ld	a4,0(a3)
    80006fce:	9732                	add	a4,a4,a2
    80006fd0:	4585                	li	a1,1
    80006fd2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006fd6:	f8442703          	lw	a4,-124(s0)
    80006fda:	628c                	ld	a1,0(a3)
    80006fdc:	962e                	add	a2,a2,a1
    80006fde:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcf00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006fe2:	0712                	slli	a4,a4,0x4
    80006fe4:	6290                	ld	a2,0(a3)
    80006fe6:	963a                	add	a2,a2,a4
    80006fe8:	058a8593          	addi	a1,s5,88
    80006fec:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006fee:	6294                	ld	a3,0(a3)
    80006ff0:	96ba                	add	a3,a3,a4
    80006ff2:	40000613          	li	a2,1024
    80006ff6:	c690                	sw	a2,8(a3)
  if(write)
    80006ff8:	e40d19e3          	bnez	s10,80006e4a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006ffc:	00027697          	auipc	a3,0x27
    80007000:	0046b683          	ld	a3,4(a3) # 8002e000 <disk+0x2000>
    80007004:	96ba                	add	a3,a3,a4
    80007006:	4609                	li	a2,2
    80007008:	00c69623          	sh	a2,12(a3)
    8000700c:	b5b1                	j	80006e58 <virtio_disk_rw+0xd2>

000000008000700e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000700e:	1101                	addi	sp,sp,-32
    80007010:	ec06                	sd	ra,24(sp)
    80007012:	e822                	sd	s0,16(sp)
    80007014:	e426                	sd	s1,8(sp)
    80007016:	e04a                	sd	s2,0(sp)
    80007018:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000701a:	00027517          	auipc	a0,0x27
    8000701e:	10e50513          	addi	a0,a0,270 # 8002e128 <disk+0x2128>
    80007022:	ffffa097          	auipc	ra,0xffffa
    80007026:	ba0080e7          	jalr	-1120(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000702a:	10001737          	lui	a4,0x10001
    8000702e:	533c                	lw	a5,96(a4)
    80007030:	8b8d                	andi	a5,a5,3
    80007032:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007034:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007038:	00027797          	auipc	a5,0x27
    8000703c:	fc878793          	addi	a5,a5,-56 # 8002e000 <disk+0x2000>
    80007040:	6b94                	ld	a3,16(a5)
    80007042:	0207d703          	lhu	a4,32(a5)
    80007046:	0026d783          	lhu	a5,2(a3)
    8000704a:	06f70163          	beq	a4,a5,800070ac <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000704e:	00025917          	auipc	s2,0x25
    80007052:	fb290913          	addi	s2,s2,-78 # 8002c000 <disk>
    80007056:	00027497          	auipc	s1,0x27
    8000705a:	faa48493          	addi	s1,s1,-86 # 8002e000 <disk+0x2000>
    __sync_synchronize();
    8000705e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007062:	6898                	ld	a4,16(s1)
    80007064:	0204d783          	lhu	a5,32(s1)
    80007068:	8b9d                	andi	a5,a5,7
    8000706a:	078e                	slli	a5,a5,0x3
    8000706c:	97ba                	add	a5,a5,a4
    8000706e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007070:	20078713          	addi	a4,a5,512
    80007074:	0712                	slli	a4,a4,0x4
    80007076:	974a                	add	a4,a4,s2
    80007078:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000707c:	e731                	bnez	a4,800070c8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000707e:	20078793          	addi	a5,a5,512
    80007082:	0792                	slli	a5,a5,0x4
    80007084:	97ca                	add	a5,a5,s2
    80007086:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007088:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000708c:	ffffb097          	auipc	ra,0xffffb
    80007090:	02c080e7          	jalr	44(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    80007094:	0204d783          	lhu	a5,32(s1)
    80007098:	2785                	addiw	a5,a5,1
    8000709a:	17c2                	slli	a5,a5,0x30
    8000709c:	93c1                	srli	a5,a5,0x30
    8000709e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800070a2:	6898                	ld	a4,16(s1)
    800070a4:	00275703          	lhu	a4,2(a4)
    800070a8:	faf71be3          	bne	a4,a5,8000705e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800070ac:	00027517          	auipc	a0,0x27
    800070b0:	07c50513          	addi	a0,a0,124 # 8002e128 <disk+0x2128>
    800070b4:	ffffa097          	auipc	ra,0xffffa
    800070b8:	bc2080e7          	jalr	-1086(ra) # 80000c76 <release>
}
    800070bc:	60e2                	ld	ra,24(sp)
    800070be:	6442                	ld	s0,16(sp)
    800070c0:	64a2                	ld	s1,8(sp)
    800070c2:	6902                	ld	s2,0(sp)
    800070c4:	6105                	addi	sp,sp,32
    800070c6:	8082                	ret
      panic("virtio_disk_intr status");
    800070c8:	00003517          	auipc	a0,0x3
    800070cc:	a4050513          	addi	a0,a0,-1472 # 80009b08 <syscalls+0x3e8>
    800070d0:	ffff9097          	auipc	ra,0xffff9
    800070d4:	45a080e7          	jalr	1114(ra) # 8000052a <panic>
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
