
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
    80000122:	140080e7          	jalr	320(ra) # 8000225e <either_copyin>
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
    800001b6:	822080e7          	jalr	-2014(ra) # 800019d4 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	ea0080e7          	jalr	-352(ra) # 80002062 <sleep>
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
    80000202:	00a080e7          	jalr	10(ra) # 80002208 <either_copyout>
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
    800002e2:	fd6080e7          	jalr	-42(ra) # 800022b4 <procdump>
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
    80000436:	c94080e7          	jalr	-876(ra) # 800020c6 <wakeup>
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
    80000882:	848080e7          	jalr	-1976(ra) # 800020c6 <wakeup>
    
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
    8000090e:	758080e7          	jalr	1880(ra) # 80002062 <sleep>
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
    80000e78:	b34080e7          	jalr	-1228(ra) # 800019a8 <cpuid>
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
    80000e94:	b18080e7          	jalr	-1256(ra) # 800019a8 <cpuid>
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
    80000eb6:	f3a080e7          	jalr	-198(ra) # 80002dec <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00006097          	auipc	ra,0x6
    80000ebe:	a96080e7          	jalr	-1386(ra) # 80006950 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fee080e7          	jalr	-18(ra) # 80001eb0 <scheduler>
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
    80000f16:	320080e7          	jalr	800(ra) # 80001232 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	9d6080e7          	jalr	-1578(ra) # 800018f8 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	e9a080e7          	jalr	-358(ra) # 80002dc4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	eba080e7          	jalr	-326(ra) # 80002dec <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00006097          	auipc	ra,0x6
    80000f3e:	a00080e7          	jalr	-1536(ra) # 8000693a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00006097          	auipc	ra,0x6
    80000f46:	a0e080e7          	jalr	-1522(ra) # 80006950 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	5e2080e7          	jalr	1506(ra) # 8000352c <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	c74080e7          	jalr	-908(ra) # 80003bc6 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	f34080e7          	jalr	-204(ra) # 80004e8e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00006097          	auipc	ra,0x6
    80000f66:	b10080e7          	jalr	-1264(ra) # 80006a72 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d42080e7          	jalr	-702(ra) # 80001cac <userinit>
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
    800010c8:	00007517          	auipc	a0,0x7
    800010cc:	01050513          	addi	a0,a0,16 # 800080d8 <digits+0x98>
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
    8000114c:	00007517          	auipc	a0,0x7
    80001150:	f9450513          	addi	a0,a0,-108 # 800080e0 <digits+0xa0>
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
    800011c2:	00007917          	auipc	s2,0x7
    800011c6:	e3e90913          	addi	s2,s2,-450 # 80008000 <etext>
    800011ca:	4729                	li	a4,10
    800011cc:	80007697          	auipc	a3,0x80007
    800011d0:	e3468693          	addi	a3,a3,-460 # 8000 <_entry-0x7fff8000>
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
    80001200:	00006617          	auipc	a2,0x6
    80001204:	e0060613          	addi	a2,a2,-512 # 80007000 <_trampoline>
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
    80001242:	00008797          	auipc	a5,0x8
    80001246:	dca7bf23          	sd	a0,-546(a5) # 80009020 <kernel_pagetable>
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
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e5050513          	addi	a0,a0,-432 # 800080e8 <digits+0xa8>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e5850513          	addi	a0,a0,-424 # 80008100 <digits+0xc0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e5850513          	addi	a0,a0,-424 # 80008110 <digits+0xd0>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012c8:	00007517          	auipc	a0,0x7
    800012cc:	e6050513          	addi	a0,a0,-416 # 80008128 <digits+0xe8>
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
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	d9250513          	addi	a0,a0,-622 # 80008140 <digits+0x100>
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
      //          panic("uvmdealloc: couldn't remove page");
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
    80001428:	730080e7          	jalr	1840(ra) # 80002b54 <remove_page_from_ram>
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
    8000148e:	00001097          	auipc	ra,0x1
    80001492:	6ae080e7          	jalr	1710(ra) # 80002b3c <insert_page_to_ram>
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
    80001528:	00007517          	auipc	a0,0x7
    8000152c:	c3850513          	addi	a0,a0,-968 # 80008160 <digits+0x120>
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
    800015ae:	00007517          	auipc	a0,0x7
    800015b2:	bc250513          	addi	a0,a0,-1086 # 80008170 <digits+0x130>
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	f74080e7          	jalr	-140(ra) # 8000052a <panic>
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0) // ADDED Q1
      panic("uvmcopy: page not present");
    800015be:	00007517          	auipc	a0,0x7
    800015c2:	bd250513          	addi	a0,a0,-1070 # 80008190 <digits+0x150>
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
    80001684:	00007517          	auipc	a0,0x7
    80001688:	b2c50513          	addi	a0,a0,-1236 # 800081b0 <digits+0x170>
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
    80001836:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd1000>
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
    80001878:	00010497          	auipc	s1,0x10
    8000187c:	e5848493          	addi	s1,s1,-424 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001880:	8b26                	mv	s6,s1
    80001882:	00006a97          	auipc	s5,0x6
    80001886:	77ea8a93          	addi	s5,s5,1918 # 80008000 <etext>
    8000188a:	04000937          	lui	s2,0x4000
    8000188e:	197d                	addi	s2,s2,-1
    80001890:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001892:	0001ea17          	auipc	s4,0x1e
    80001896:	c3ea0a13          	addi	s4,s4,-962 # 8001f4d0 <tickslock>
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
    800018e8:	00007517          	auipc	a0,0x7
    800018ec:	8d850513          	addi	a0,a0,-1832 # 800081c0 <digits+0x180>
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
    8000190c:	00007597          	auipc	a1,0x7
    80001910:	8bc58593          	addi	a1,a1,-1860 # 800081c8 <digits+0x188>
    80001914:	00010517          	auipc	a0,0x10
    80001918:	98c50513          	addi	a0,a0,-1652 # 800112a0 <pid_lock>
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	216080e7          	jalr	534(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001924:	00007597          	auipc	a1,0x7
    80001928:	8ac58593          	addi	a1,a1,-1876 # 800081d0 <digits+0x190>
    8000192c:	00010517          	auipc	a0,0x10
    80001930:	98c50513          	addi	a0,a0,-1652 # 800112b8 <wait_lock>
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	1fe080e7          	jalr	510(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193c:	00010497          	auipc	s1,0x10
    80001940:	d9448493          	addi	s1,s1,-620 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001944:	00007b17          	auipc	s6,0x7
    80001948:	89cb0b13          	addi	s6,s6,-1892 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    8000194c:	8aa6                	mv	s5,s1
    8000194e:	00006a17          	auipc	s4,0x6
    80001952:	6b2a0a13          	addi	s4,s4,1714 # 80008000 <etext>
    80001956:	04000937          	lui	s2,0x4000
    8000195a:	197d                	addi	s2,s2,-1
    8000195c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195e:	0001e997          	auipc	s3,0x1e
    80001962:	b7298993          	addi	s3,s3,-1166 # 8001f4d0 <tickslock>
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
    800019c4:	00010517          	auipc	a0,0x10
    800019c8:	90c50513          	addi	a0,a0,-1780 # 800112d0 <cpus>
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
    800019ec:	00010717          	auipc	a4,0x10
    800019f0:	8b470713          	addi	a4,a4,-1868 # 800112a0 <pid_lock>
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
    80001a24:	00007797          	auipc	a5,0x7
    80001a28:	0dc7a783          	lw	a5,220(a5) # 80008b00 <first.1>
    80001a2c:	eb89                	bnez	a5,80001a3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2e:	00001097          	auipc	ra,0x1
    80001a32:	3d6080e7          	jalr	982(ra) # 80002e04 <usertrapret>
}
    80001a36:	60a2                	ld	ra,8(sp)
    80001a38:	6402                	ld	s0,0(sp)
    80001a3a:	0141                	addi	sp,sp,16
    80001a3c:	8082                	ret
    first = 0;
    80001a3e:	00007797          	auipc	a5,0x7
    80001a42:	0c07a123          	sw	zero,194(a5) # 80008b00 <first.1>
    fsinit(ROOTDEV);
    80001a46:	4505                	li	a0,1
    80001a48:	00002097          	auipc	ra,0x2
    80001a4c:	0fe080e7          	jalr	254(ra) # 80003b46 <fsinit>
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
    80001a5e:	00010917          	auipc	s2,0x10
    80001a62:	84290913          	addi	s2,s2,-1982 # 800112a0 <pid_lock>
    80001a66:	854a                	mv	a0,s2
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	15a080e7          	jalr	346(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a70:	00007797          	auipc	a5,0x7
    80001a74:	09478793          	addi	a5,a5,148 # 80008b04 <nextpid>
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
    80001ab4:	00005697          	auipc	a3,0x5
    80001ab8:	54c68693          	addi	a3,a3,1356 # 80007000 <_trampoline>
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
    80001bea:	00010497          	auipc	s1,0x10
    80001bee:	ae648493          	addi	s1,s1,-1306 # 800116d0 <proc>
    80001bf2:	0001e917          	auipc	s2,0x1e
    80001bf6:	8de90913          	addi	s2,s2,-1826 # 8001f4d0 <tickslock>
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
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	36a7b423          	sd	a0,872(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc8:	03400613          	li	a2,52
    80001ccc:	00007597          	auipc	a1,0x7
    80001cd0:	e4458593          	addi	a1,a1,-444 # 80008b10 <initcode>
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
    80001cee:	00006597          	auipc	a1,0x6
    80001cf2:	4fa58593          	addi	a1,a1,1274 # 800081e8 <digits+0x1a8>
    80001cf6:	15848513          	addi	a0,s1,344
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	116080e7          	jalr	278(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001d02:	00006517          	auipc	a0,0x6
    80001d06:	4f650513          	addi	a0,a0,1270 # 800081f8 <digits+0x1b8>
    80001d0a:	00003097          	auipc	ra,0x3
    80001d0e:	86a080e7          	jalr	-1942(ra) # 80004574 <namei>
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
}
    80001da8:	4501                	li	a0,0
    80001daa:	6422                	ld	s0,8(sp)
    80001dac:	0141                	addi	sp,sp,16
    80001dae:	8082                	ret

0000000080001db0 <fill_swapFile>:
{
    80001db0:	7179                	addi	sp,sp,-48
    80001db2:	f406                	sd	ra,40(sp)
    80001db4:	f022                	sd	s0,32(sp)
    80001db6:	ec26                	sd	s1,24(sp)
    80001db8:	e84a                	sd	s2,16(sp)
    80001dba:	e44e                	sd	s3,8(sp)
    80001dbc:	e052                	sd	s4,0(sp)
    80001dbe:	1800                	addi	s0,sp,48
    80001dc0:	892a                	mv	s2,a0
  char *page = kalloc();
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	d10080e7          	jalr	-752(ra) # 80000ad2 <kalloc>
    80001dca:	89aa                	mv	s3,a0
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001dcc:	27090493          	addi	s1,s2,624
    80001dd0:	37090a13          	addi	s4,s2,880
    if (writeToSwapFile(p, page, disk_pg->offset, PGSIZE) < 0) {
    80001dd4:	6685                	lui	a3,0x1
    80001dd6:	4490                	lw	a2,8(s1)
    80001dd8:	85ce                	mv	a1,s3
    80001dda:	854a                	mv	a0,s2
    80001ddc:	00003097          	auipc	ra,0x3
    80001de0:	a9c080e7          	jalr	-1380(ra) # 80004878 <writeToSwapFile>
    80001de4:	02054363          	bltz	a0,80001e0a <fill_swapFile+0x5a>
  for (struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001de8:	04c1                	addi	s1,s1,16
    80001dea:	fe9a15e3          	bne	s4,s1,80001dd4 <fill_swapFile+0x24>
  kfree(page);
    80001dee:	854e                	mv	a0,s3
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	be6080e7          	jalr	-1050(ra) # 800009d6 <kfree>
  return 0;
    80001df8:	4501                	li	a0,0
}
    80001dfa:	70a2                	ld	ra,40(sp)
    80001dfc:	7402                	ld	s0,32(sp)
    80001dfe:	64e2                	ld	s1,24(sp)
    80001e00:	6942                	ld	s2,16(sp)
    80001e02:	69a2                	ld	s3,8(sp)
    80001e04:	6a02                	ld	s4,0(sp)
    80001e06:	6145                	addi	sp,sp,48
    80001e08:	8082                	ret
      return -1;
    80001e0a:	557d                	li	a0,-1
    80001e0c:	b7fd                	j	80001dfa <fill_swapFile+0x4a>

0000000080001e0e <copy_swapFile>:
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001e0e:	c559                	beqz	a0,80001e9c <copy_swapFile+0x8e>
int copy_swapFile(struct proc *src, struct proc *dst) {
    80001e10:	7139                	addi	sp,sp,-64
    80001e12:	fc06                	sd	ra,56(sp)
    80001e14:	f822                	sd	s0,48(sp)
    80001e16:	f426                	sd	s1,40(sp)
    80001e18:	f04a                	sd	s2,32(sp)
    80001e1a:	ec4e                	sd	s3,24(sp)
    80001e1c:	e852                	sd	s4,16(sp)
    80001e1e:	e456                	sd	s5,8(sp)
    80001e20:	0080                	addi	s0,sp,64
    80001e22:	8a2a                	mv	s4,a0
    80001e24:	8aae                	mv	s5,a1
  if(!src || !src->swapFile || !dst || !dst->swapFile) {
    80001e26:	16853783          	ld	a5,360(a0)
    80001e2a:	cbbd                	beqz	a5,80001ea0 <copy_swapFile+0x92>
    80001e2c:	cda5                	beqz	a1,80001ea4 <copy_swapFile+0x96>
    80001e2e:	1685b783          	ld	a5,360(a1)
    80001e32:	cbbd                	beqz	a5,80001ea8 <copy_swapFile+0x9a>
  char *buffer = (char *)kalloc();
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	c9e080e7          	jalr	-866(ra) # 80000ad2 <kalloc>
    80001e3c:	89aa                	mv	s3,a0
  for (struct disk_page *disk_pg = src->disk_pages; disk_pg < &src->disk_pages[MAX_DISK_PAGES]; disk_pg++) {
    80001e3e:	270a0493          	addi	s1,s4,624
    80001e42:	370a0913          	addi	s2,s4,880
    80001e46:	a021                	j	80001e4e <copy_swapFile+0x40>
    80001e48:	04c1                	addi	s1,s1,16
    80001e4a:	02990a63          	beq	s2,s1,80001e7e <copy_swapFile+0x70>
    if(disk_pg->used) {
    80001e4e:	44dc                	lw	a5,12(s1)
    80001e50:	dfe5                	beqz	a5,80001e48 <copy_swapFile+0x3a>
      if (readFromSwapFile(src, buffer, disk_pg->offset, PGSIZE) < 0) {
    80001e52:	6685                	lui	a3,0x1
    80001e54:	4490                	lw	a2,8(s1)
    80001e56:	85ce                	mv	a1,s3
    80001e58:	8552                	mv	a0,s4
    80001e5a:	00003097          	auipc	ra,0x3
    80001e5e:	a42080e7          	jalr	-1470(ra) # 8000489c <readFromSwapFile>
    80001e62:	04054563          	bltz	a0,80001eac <copy_swapFile+0x9e>
      if (writeToSwapFile(dst, buffer, disk_pg->offset, PGSIZE) < 0) {
    80001e66:	6685                	lui	a3,0x1
    80001e68:	4490                	lw	a2,8(s1)
    80001e6a:	85ce                	mv	a1,s3
    80001e6c:	8556                	mv	a0,s5
    80001e6e:	00003097          	auipc	ra,0x3
    80001e72:	a0a080e7          	jalr	-1526(ra) # 80004878 <writeToSwapFile>
    80001e76:	fc0559e3          	bgez	a0,80001e48 <copy_swapFile+0x3a>
        return -1;
    80001e7a:	557d                	li	a0,-1
    80001e7c:	a039                	j	80001e8a <copy_swapFile+0x7c>
  kfree((void *)buffer);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	b56080e7          	jalr	-1194(ra) # 800009d6 <kfree>
  return 0;
    80001e88:	4501                	li	a0,0
}
    80001e8a:	70e2                	ld	ra,56(sp)
    80001e8c:	7442                	ld	s0,48(sp)
    80001e8e:	74a2                	ld	s1,40(sp)
    80001e90:	7902                	ld	s2,32(sp)
    80001e92:	69e2                	ld	s3,24(sp)
    80001e94:	6a42                	ld	s4,16(sp)
    80001e96:	6aa2                	ld	s5,8(sp)
    80001e98:	6121                	addi	sp,sp,64
    80001e9a:	8082                	ret
    return -1;
    80001e9c:	557d                	li	a0,-1
}
    80001e9e:	8082                	ret
    return -1;
    80001ea0:	557d                	li	a0,-1
    80001ea2:	b7e5                	j	80001e8a <copy_swapFile+0x7c>
    80001ea4:	557d                	li	a0,-1
    80001ea6:	b7d5                	j	80001e8a <copy_swapFile+0x7c>
    80001ea8:	557d                	li	a0,-1
    80001eaa:	b7c5                	j	80001e8a <copy_swapFile+0x7c>
        return -1;
    80001eac:	557d                	li	a0,-1
    80001eae:	bff1                	j	80001e8a <copy_swapFile+0x7c>

0000000080001eb0 <scheduler>:
{
    80001eb0:	7139                	addi	sp,sp,-64
    80001eb2:	fc06                	sd	ra,56(sp)
    80001eb4:	f822                	sd	s0,48(sp)
    80001eb6:	f426                	sd	s1,40(sp)
    80001eb8:	f04a                	sd	s2,32(sp)
    80001eba:	ec4e                	sd	s3,24(sp)
    80001ebc:	e852                	sd	s4,16(sp)
    80001ebe:	e456                	sd	s5,8(sp)
    80001ec0:	e05a                	sd	s6,0(sp)
    80001ec2:	0080                	addi	s0,sp,64
    80001ec4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ec6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec8:	00779a93          	slli	s5,a5,0x7
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	3d470713          	addi	a4,a4,980 # 800112a0 <pid_lock>
    80001ed4:	9756                	add	a4,a4,s5
    80001ed6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eda:	0000f717          	auipc	a4,0xf
    80001ede:	3fe70713          	addi	a4,a4,1022 # 800112d8 <cpus+0x8>
    80001ee2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ee4:	498d                	li	s3,3
        p->state = RUNNING;
    80001ee6:	4b11                	li	s6,4
        c->proc = p;
    80001ee8:	079e                	slli	a5,a5,0x7
    80001eea:	0000fa17          	auipc	s4,0xf
    80001eee:	3b6a0a13          	addi	s4,s4,950 # 800112a0 <pid_lock>
    80001ef2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef4:	0001d917          	auipc	s2,0x1d
    80001ef8:	5dc90913          	addi	s2,s2,1500 # 8001f4d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001efc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f00:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f04:	10079073          	csrw	sstatus,a5
    80001f08:	0000f497          	auipc	s1,0xf
    80001f0c:	7c848493          	addi	s1,s1,1992 # 800116d0 <proc>
    80001f10:	a811                	j	80001f24 <scheduler+0x74>
      release(&p->lock);
    80001f12:	8526                	mv	a0,s1
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	d62080e7          	jalr	-670(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f1c:	37848493          	addi	s1,s1,888
    80001f20:	fd248ee3          	beq	s1,s2,80001efc <scheduler+0x4c>
      acquire(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	c9c080e7          	jalr	-868(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f2e:	4c9c                	lw	a5,24(s1)
    80001f30:	ff3791e3          	bne	a5,s3,80001f12 <scheduler+0x62>
        p->state = RUNNING;
    80001f34:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f38:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f3c:	06048593          	addi	a1,s1,96
    80001f40:	8556                	mv	a0,s5
    80001f42:	00001097          	auipc	ra,0x1
    80001f46:	e18080e7          	jalr	-488(ra) # 80002d5a <swtch>
        c->proc = 0;
    80001f4a:	020a3823          	sd	zero,48(s4)
    80001f4e:	b7d1                	j	80001f12 <scheduler+0x62>

0000000080001f50 <sched>:
{
    80001f50:	7179                	addi	sp,sp,-48
    80001f52:	f406                	sd	ra,40(sp)
    80001f54:	f022                	sd	s0,32(sp)
    80001f56:	ec26                	sd	s1,24(sp)
    80001f58:	e84a                	sd	s2,16(sp)
    80001f5a:	e44e                	sd	s3,8(sp)
    80001f5c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f5e:	00000097          	auipc	ra,0x0
    80001f62:	a76080e7          	jalr	-1418(ra) # 800019d4 <myproc>
    80001f66:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	be0080e7          	jalr	-1056(ra) # 80000b48 <holding>
    80001f70:	c93d                	beqz	a0,80001fe6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f72:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f74:	2781                	sext.w	a5,a5
    80001f76:	079e                	slli	a5,a5,0x7
    80001f78:	0000f717          	auipc	a4,0xf
    80001f7c:	32870713          	addi	a4,a4,808 # 800112a0 <pid_lock>
    80001f80:	97ba                	add	a5,a5,a4
    80001f82:	0a87a703          	lw	a4,168(a5) # 10a8 <_entry-0x7fffef58>
    80001f86:	4785                	li	a5,1
    80001f88:	06f71763          	bne	a4,a5,80001ff6 <sched+0xa6>
  if(p->state == RUNNING)
    80001f8c:	4c98                	lw	a4,24(s1)
    80001f8e:	4791                	li	a5,4
    80001f90:	06f70b63          	beq	a4,a5,80002006 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f98:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f9a:	efb5                	bnez	a5,80002016 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f9c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f9e:	0000f917          	auipc	s2,0xf
    80001fa2:	30290913          	addi	s2,s2,770 # 800112a0 <pid_lock>
    80001fa6:	2781                	sext.w	a5,a5
    80001fa8:	079e                	slli	a5,a5,0x7
    80001faa:	97ca                	add	a5,a5,s2
    80001fac:	0ac7a983          	lw	s3,172(a5)
    80001fb0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb2:	2781                	sext.w	a5,a5
    80001fb4:	079e                	slli	a5,a5,0x7
    80001fb6:	0000f597          	auipc	a1,0xf
    80001fba:	32258593          	addi	a1,a1,802 # 800112d8 <cpus+0x8>
    80001fbe:	95be                	add	a1,a1,a5
    80001fc0:	06048513          	addi	a0,s1,96
    80001fc4:	00001097          	auipc	ra,0x1
    80001fc8:	d96080e7          	jalr	-618(ra) # 80002d5a <swtch>
    80001fcc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	slli	a5,a5,0x7
    80001fd2:	97ca                	add	a5,a5,s2
    80001fd4:	0b37a623          	sw	s3,172(a5)
}
    80001fd8:	70a2                	ld	ra,40(sp)
    80001fda:	7402                	ld	s0,32(sp)
    80001fdc:	64e2                	ld	s1,24(sp)
    80001fde:	6942                	ld	s2,16(sp)
    80001fe0:	69a2                	ld	s3,8(sp)
    80001fe2:	6145                	addi	sp,sp,48
    80001fe4:	8082                	ret
    panic("sched p->lock");
    80001fe6:	00006517          	auipc	a0,0x6
    80001fea:	21a50513          	addi	a0,a0,538 # 80008200 <digits+0x1c0>
    80001fee:	ffffe097          	auipc	ra,0xffffe
    80001ff2:	53c080e7          	jalr	1340(ra) # 8000052a <panic>
    panic("sched locks");
    80001ff6:	00006517          	auipc	a0,0x6
    80001ffa:	21a50513          	addi	a0,a0,538 # 80008210 <digits+0x1d0>
    80001ffe:	ffffe097          	auipc	ra,0xffffe
    80002002:	52c080e7          	jalr	1324(ra) # 8000052a <panic>
    panic("sched running");
    80002006:	00006517          	auipc	a0,0x6
    8000200a:	21a50513          	addi	a0,a0,538 # 80008220 <digits+0x1e0>
    8000200e:	ffffe097          	auipc	ra,0xffffe
    80002012:	51c080e7          	jalr	1308(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002016:	00006517          	auipc	a0,0x6
    8000201a:	21a50513          	addi	a0,a0,538 # 80008230 <digits+0x1f0>
    8000201e:	ffffe097          	auipc	ra,0xffffe
    80002022:	50c080e7          	jalr	1292(ra) # 8000052a <panic>

0000000080002026 <yield>:
{
    80002026:	1101                	addi	sp,sp,-32
    80002028:	ec06                	sd	ra,24(sp)
    8000202a:	e822                	sd	s0,16(sp)
    8000202c:	e426                	sd	s1,8(sp)
    8000202e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002030:	00000097          	auipc	ra,0x0
    80002034:	9a4080e7          	jalr	-1628(ra) # 800019d4 <myproc>
    80002038:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	b88080e7          	jalr	-1144(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002042:	478d                	li	a5,3
    80002044:	cc9c                	sw	a5,24(s1)
  sched();
    80002046:	00000097          	auipc	ra,0x0
    8000204a:	f0a080e7          	jalr	-246(ra) # 80001f50 <sched>
  release(&p->lock);
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	c26080e7          	jalr	-986(ra) # 80000c76 <release>
}
    80002058:	60e2                	ld	ra,24(sp)
    8000205a:	6442                	ld	s0,16(sp)
    8000205c:	64a2                	ld	s1,8(sp)
    8000205e:	6105                	addi	sp,sp,32
    80002060:	8082                	ret

0000000080002062 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002062:	7179                	addi	sp,sp,-48
    80002064:	f406                	sd	ra,40(sp)
    80002066:	f022                	sd	s0,32(sp)
    80002068:	ec26                	sd	s1,24(sp)
    8000206a:	e84a                	sd	s2,16(sp)
    8000206c:	e44e                	sd	s3,8(sp)
    8000206e:	1800                	addi	s0,sp,48
    80002070:	89aa                	mv	s3,a0
    80002072:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	960080e7          	jalr	-1696(ra) # 800019d4 <myproc>
    8000207c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	b44080e7          	jalr	-1212(ra) # 80000bc2 <acquire>
  release(lk);
    80002086:	854a                	mv	a0,s2
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	bee080e7          	jalr	-1042(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002090:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002094:	4789                	li	a5,2
    80002096:	cc9c                	sw	a5,24(s1)

  sched();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	eb8080e7          	jalr	-328(ra) # 80001f50 <sched>

  // Tidy up.
  p->chan = 0;
    800020a0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a4:	8526                	mv	a0,s1
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	bd0080e7          	jalr	-1072(ra) # 80000c76 <release>
  acquire(lk);
    800020ae:	854a                	mv	a0,s2
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	b12080e7          	jalr	-1262(ra) # 80000bc2 <acquire>
}
    800020b8:	70a2                	ld	ra,40(sp)
    800020ba:	7402                	ld	s0,32(sp)
    800020bc:	64e2                	ld	s1,24(sp)
    800020be:	6942                	ld	s2,16(sp)
    800020c0:	69a2                	ld	s3,8(sp)
    800020c2:	6145                	addi	sp,sp,48
    800020c4:	8082                	ret

00000000800020c6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020c6:	7139                	addi	sp,sp,-64
    800020c8:	fc06                	sd	ra,56(sp)
    800020ca:	f822                	sd	s0,48(sp)
    800020cc:	f426                	sd	s1,40(sp)
    800020ce:	f04a                	sd	s2,32(sp)
    800020d0:	ec4e                	sd	s3,24(sp)
    800020d2:	e852                	sd	s4,16(sp)
    800020d4:	e456                	sd	s5,8(sp)
    800020d6:	0080                	addi	s0,sp,64
    800020d8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020da:	0000f497          	auipc	s1,0xf
    800020de:	5f648493          	addi	s1,s1,1526 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020e2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020e4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	0001d917          	auipc	s2,0x1d
    800020ea:	3ea90913          	addi	s2,s2,1002 # 8001f4d0 <tickslock>
    800020ee:	a811                	j	80002102 <wakeup+0x3c>
      }
      release(&p->lock);
    800020f0:	8526                	mv	a0,s1
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	b84080e7          	jalr	-1148(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020fa:	37848493          	addi	s1,s1,888
    800020fe:	03248663          	beq	s1,s2,8000212a <wakeup+0x64>
    if(p != myproc()){
    80002102:	00000097          	auipc	ra,0x0
    80002106:	8d2080e7          	jalr	-1838(ra) # 800019d4 <myproc>
    8000210a:	fea488e3          	beq	s1,a0,800020fa <wakeup+0x34>
      acquire(&p->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ab2080e7          	jalr	-1358(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002118:	4c9c                	lw	a5,24(s1)
    8000211a:	fd379be3          	bne	a5,s3,800020f0 <wakeup+0x2a>
    8000211e:	709c                	ld	a5,32(s1)
    80002120:	fd4798e3          	bne	a5,s4,800020f0 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002124:	0154ac23          	sw	s5,24(s1)
    80002128:	b7e1                	j	800020f0 <wakeup+0x2a>
    }
  }
}
    8000212a:	70e2                	ld	ra,56(sp)
    8000212c:	7442                	ld	s0,48(sp)
    8000212e:	74a2                	ld	s1,40(sp)
    80002130:	7902                	ld	s2,32(sp)
    80002132:	69e2                	ld	s3,24(sp)
    80002134:	6a42                	ld	s4,16(sp)
    80002136:	6aa2                	ld	s5,8(sp)
    80002138:	6121                	addi	sp,sp,64
    8000213a:	8082                	ret

000000008000213c <reparent>:
{
    8000213c:	7179                	addi	sp,sp,-48
    8000213e:	f406                	sd	ra,40(sp)
    80002140:	f022                	sd	s0,32(sp)
    80002142:	ec26                	sd	s1,24(sp)
    80002144:	e84a                	sd	s2,16(sp)
    80002146:	e44e                	sd	s3,8(sp)
    80002148:	e052                	sd	s4,0(sp)
    8000214a:	1800                	addi	s0,sp,48
    8000214c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000214e:	0000f497          	auipc	s1,0xf
    80002152:	58248493          	addi	s1,s1,1410 # 800116d0 <proc>
      pp->parent = initproc;
    80002156:	00007a17          	auipc	s4,0x7
    8000215a:	ed2a0a13          	addi	s4,s4,-302 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000215e:	0001d997          	auipc	s3,0x1d
    80002162:	37298993          	addi	s3,s3,882 # 8001f4d0 <tickslock>
    80002166:	a029                	j	80002170 <reparent+0x34>
    80002168:	37848493          	addi	s1,s1,888
    8000216c:	01348d63          	beq	s1,s3,80002186 <reparent+0x4a>
    if(pp->parent == p){
    80002170:	7c9c                	ld	a5,56(s1)
    80002172:	ff279be3          	bne	a5,s2,80002168 <reparent+0x2c>
      pp->parent = initproc;
    80002176:	000a3503          	ld	a0,0(s4)
    8000217a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	f4a080e7          	jalr	-182(ra) # 800020c6 <wakeup>
    80002184:	b7d5                	j	80002168 <reparent+0x2c>
}
    80002186:	70a2                	ld	ra,40(sp)
    80002188:	7402                	ld	s0,32(sp)
    8000218a:	64e2                	ld	s1,24(sp)
    8000218c:	6942                	ld	s2,16(sp)
    8000218e:	69a2                	ld	s3,8(sp)
    80002190:	6a02                	ld	s4,0(sp)
    80002192:	6145                	addi	sp,sp,48
    80002194:	8082                	ret

0000000080002196 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002196:	7179                	addi	sp,sp,-48
    80002198:	f406                	sd	ra,40(sp)
    8000219a:	f022                	sd	s0,32(sp)
    8000219c:	ec26                	sd	s1,24(sp)
    8000219e:	e84a                	sd	s2,16(sp)
    800021a0:	e44e                	sd	s3,8(sp)
    800021a2:	1800                	addi	s0,sp,48
    800021a4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800021a6:	0000f497          	auipc	s1,0xf
    800021aa:	52a48493          	addi	s1,s1,1322 # 800116d0 <proc>
    800021ae:	0001d997          	auipc	s3,0x1d
    800021b2:	32298993          	addi	s3,s3,802 # 8001f4d0 <tickslock>
    acquire(&p->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	a0a080e7          	jalr	-1526(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800021c0:	589c                	lw	a5,48(s1)
    800021c2:	01278d63          	beq	a5,s2,800021dc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800021c6:	8526                	mv	a0,s1
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	aae080e7          	jalr	-1362(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800021d0:	37848493          	addi	s1,s1,888
    800021d4:	ff3491e3          	bne	s1,s3,800021b6 <kill+0x20>
  }
  return -1;
    800021d8:	557d                	li	a0,-1
    800021da:	a829                	j	800021f4 <kill+0x5e>
      p->killed = 1;
    800021dc:	4785                	li	a5,1
    800021de:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800021e0:	4c98                	lw	a4,24(s1)
    800021e2:	4789                	li	a5,2
    800021e4:	00f70f63          	beq	a4,a5,80002202 <kill+0x6c>
      release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	a8c080e7          	jalr	-1396(ra) # 80000c76 <release>
      return 0;
    800021f2:	4501                	li	a0,0
}
    800021f4:	70a2                	ld	ra,40(sp)
    800021f6:	7402                	ld	s0,32(sp)
    800021f8:	64e2                	ld	s1,24(sp)
    800021fa:	6942                	ld	s2,16(sp)
    800021fc:	69a2                	ld	s3,8(sp)
    800021fe:	6145                	addi	sp,sp,48
    80002200:	8082                	ret
        p->state = RUNNABLE;
    80002202:	478d                	li	a5,3
    80002204:	cc9c                	sw	a5,24(s1)
    80002206:	b7cd                	j	800021e8 <kill+0x52>

0000000080002208 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002208:	7179                	addi	sp,sp,-48
    8000220a:	f406                	sd	ra,40(sp)
    8000220c:	f022                	sd	s0,32(sp)
    8000220e:	ec26                	sd	s1,24(sp)
    80002210:	e84a                	sd	s2,16(sp)
    80002212:	e44e                	sd	s3,8(sp)
    80002214:	e052                	sd	s4,0(sp)
    80002216:	1800                	addi	s0,sp,48
    80002218:	84aa                	mv	s1,a0
    8000221a:	892e                	mv	s2,a1
    8000221c:	89b2                	mv	s3,a2
    8000221e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	7b4080e7          	jalr	1972(ra) # 800019d4 <myproc>
  if(user_dst){
    80002228:	c08d                	beqz	s1,8000224a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000222a:	86d2                	mv	a3,s4
    8000222c:	864e                	mv	a2,s3
    8000222e:	85ca                	mv	a1,s2
    80002230:	6928                	ld	a0,80(a0)
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	462080e7          	jalr	1122(ra) # 80001694 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000223a:	70a2                	ld	ra,40(sp)
    8000223c:	7402                	ld	s0,32(sp)
    8000223e:	64e2                	ld	s1,24(sp)
    80002240:	6942                	ld	s2,16(sp)
    80002242:	69a2                	ld	s3,8(sp)
    80002244:	6a02                	ld	s4,0(sp)
    80002246:	6145                	addi	sp,sp,48
    80002248:	8082                	ret
    memmove((char *)dst, src, len);
    8000224a:	000a061b          	sext.w	a2,s4
    8000224e:	85ce                	mv	a1,s3
    80002250:	854a                	mv	a0,s2
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	ac8080e7          	jalr	-1336(ra) # 80000d1a <memmove>
    return 0;
    8000225a:	8526                	mv	a0,s1
    8000225c:	bff9                	j	8000223a <either_copyout+0x32>

000000008000225e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	e052                	sd	s4,0(sp)
    8000226c:	1800                	addi	s0,sp,48
    8000226e:	892a                	mv	s2,a0
    80002270:	84ae                	mv	s1,a1
    80002272:	89b2                	mv	s3,a2
    80002274:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	75e080e7          	jalr	1886(ra) # 800019d4 <myproc>
  if(user_src){
    8000227e:	c08d                	beqz	s1,800022a0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002280:	86d2                	mv	a3,s4
    80002282:	864e                	mv	a2,s3
    80002284:	85ca                	mv	a1,s2
    80002286:	6928                	ld	a0,80(a0)
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	498080e7          	jalr	1176(ra) # 80001720 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002290:	70a2                	ld	ra,40(sp)
    80002292:	7402                	ld	s0,32(sp)
    80002294:	64e2                	ld	s1,24(sp)
    80002296:	6942                	ld	s2,16(sp)
    80002298:	69a2                	ld	s3,8(sp)
    8000229a:	6a02                	ld	s4,0(sp)
    8000229c:	6145                	addi	sp,sp,48
    8000229e:	8082                	ret
    memmove(dst, (char*)src, len);
    800022a0:	000a061b          	sext.w	a2,s4
    800022a4:	85ce                	mv	a1,s3
    800022a6:	854a                	mv	a0,s2
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	a72080e7          	jalr	-1422(ra) # 80000d1a <memmove>
    return 0;
    800022b0:	8526                	mv	a0,s1
    800022b2:	bff9                	j	80002290 <either_copyin+0x32>

00000000800022b4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800022b4:	715d                	addi	sp,sp,-80
    800022b6:	e486                	sd	ra,72(sp)
    800022b8:	e0a2                	sd	s0,64(sp)
    800022ba:	fc26                	sd	s1,56(sp)
    800022bc:	f84a                	sd	s2,48(sp)
    800022be:	f44e                	sd	s3,40(sp)
    800022c0:	f052                	sd	s4,32(sp)
    800022c2:	ec56                	sd	s5,24(sp)
    800022c4:	e85a                	sd	s6,16(sp)
    800022c6:	e45e                	sd	s7,8(sp)
    800022c8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800022ca:	00006517          	auipc	a0,0x6
    800022ce:	dfe50513          	addi	a0,a0,-514 # 800080c8 <digits+0x88>
    800022d2:	ffffe097          	auipc	ra,0xffffe
    800022d6:	2a2080e7          	jalr	674(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022da:	0000f497          	auipc	s1,0xf
    800022de:	54e48493          	addi	s1,s1,1358 # 80011828 <proc+0x158>
    800022e2:	0001d917          	auipc	s2,0x1d
    800022e6:	34690913          	addi	s2,s2,838 # 8001f628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022ea:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800022ec:	00006997          	auipc	s3,0x6
    800022f0:	f5c98993          	addi	s3,s3,-164 # 80008248 <digits+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    800022f4:	00006a97          	auipc	s5,0x6
    800022f8:	f5ca8a93          	addi	s5,s5,-164 # 80008250 <digits+0x210>
    printf("\n");
    800022fc:	00006a17          	auipc	s4,0x6
    80002300:	dcca0a13          	addi	s4,s4,-564 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002304:	00006b97          	auipc	s7,0x6
    80002308:	26cb8b93          	addi	s7,s7,620 # 80008570 <states.0>
    8000230c:	a00d                	j	8000232e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000230e:	ed86a583          	lw	a1,-296(a3) # ed8 <_entry-0x7ffff128>
    80002312:	8556                	mv	a0,s5
    80002314:	ffffe097          	auipc	ra,0xffffe
    80002318:	260080e7          	jalr	608(ra) # 80000574 <printf>
    printf("\n");
    8000231c:	8552                	mv	a0,s4
    8000231e:	ffffe097          	auipc	ra,0xffffe
    80002322:	256080e7          	jalr	598(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002326:	37848493          	addi	s1,s1,888
    8000232a:	03248263          	beq	s1,s2,8000234e <procdump+0x9a>
    if(p->state == UNUSED)
    8000232e:	86a6                	mv	a3,s1
    80002330:	ec04a783          	lw	a5,-320(s1)
    80002334:	dbed                	beqz	a5,80002326 <procdump+0x72>
      state = "???";
    80002336:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002338:	fcfb6be3          	bltu	s6,a5,8000230e <procdump+0x5a>
    8000233c:	02079713          	slli	a4,a5,0x20
    80002340:	01d75793          	srli	a5,a4,0x1d
    80002344:	97de                	add	a5,a5,s7
    80002346:	6390                	ld	a2,0(a5)
    80002348:	f279                	bnez	a2,8000230e <procdump+0x5a>
      state = "???";
    8000234a:	864e                	mv	a2,s3
    8000234c:	b7c9                	j	8000230e <procdump+0x5a>
  }
}
    8000234e:	60a6                	ld	ra,72(sp)
    80002350:	6406                	ld	s0,64(sp)
    80002352:	74e2                	ld	s1,56(sp)
    80002354:	7942                	ld	s2,48(sp)
    80002356:	79a2                	ld	s3,40(sp)
    80002358:	7a02                	ld	s4,32(sp)
    8000235a:	6ae2                	ld	s5,24(sp)
    8000235c:	6b42                	ld	s6,16(sp)
    8000235e:	6ba2                	ld	s7,8(sp)
    80002360:	6161                	addi	sp,sp,80
    80002362:	8082                	ret

0000000080002364 <init_metadata>:

// ADDED Q1 - p->lock must not be held because of createSwapFile!
int init_metadata(struct proc *p)
{
    80002364:	1101                	addi	sp,sp,-32
    80002366:	ec06                	sd	ra,24(sp)
    80002368:	e822                	sd	s0,16(sp)
    8000236a:	e426                	sd	s1,8(sp)
    8000236c:	1000                	addi	s0,sp,32
    8000236e:	84aa                	mv	s1,a0
  if (!p->swapFile && createSwapFile(p) < 0) {
    80002370:	16853783          	ld	a5,360(a0)
    80002374:	c7a1                	beqz	a5,800023bc <init_metadata+0x58>
    return -1;
  }

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002376:	17048793          	addi	a5,s1,368
    8000237a:	27048713          	addi	a4,s1,624
    p->ram_pages[i].va = 0;
    8000237e:	0007b023          	sd	zero,0(a5)
    p->ram_pages[i].age = 0; // ADDED Q2
    80002382:	0007a423          	sw	zero,8(a5)
    p->ram_pages[i].used = 0;
    80002386:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    8000238a:	07c1                	addi	a5,a5,16
    8000238c:	fee799e3          	bne	a5,a4,8000237e <init_metadata+0x1a>
    80002390:	27048793          	addi	a5,s1,624
    80002394:	4701                	li	a4,0
  }
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002396:	6605                	lui	a2,0x1
    80002398:	66c1                	lui	a3,0x10
    p->disk_pages[i].va = 0;
    8000239a:	0007b023          	sd	zero,0(a5)
    p->disk_pages[i].offset = i * PGSIZE;
    8000239e:	c798                	sw	a4,8(a5)
    p->disk_pages[i].used = 0;
    800023a0:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    800023a4:	07c1                	addi	a5,a5,16
    800023a6:	9f31                	addw	a4,a4,a2
    800023a8:	fed719e3          	bne	a4,a3,8000239a <init_metadata+0x36>
  }
  p->scfifo_index = 0; // ADDED Q2
    800023ac:	3604a823          	sw	zero,880(s1)
  return 0;
    800023b0:	4501                	li	a0,0
}
    800023b2:	60e2                	ld	ra,24(sp)
    800023b4:	6442                	ld	s0,16(sp)
    800023b6:	64a2                	ld	s1,8(sp)
    800023b8:	6105                	addi	sp,sp,32
    800023ba:	8082                	ret
  if (!p->swapFile && createSwapFile(p) < 0) {
    800023bc:	00002097          	auipc	ra,0x2
    800023c0:	40c080e7          	jalr	1036(ra) # 800047c8 <createSwapFile>
    800023c4:	fa0559e3          	bgez	a0,80002376 <init_metadata+0x12>
    return -1;
    800023c8:	557d                	li	a0,-1
    800023ca:	b7e5                	j	800023b2 <init_metadata+0x4e>

00000000800023cc <free_metadata>:

// p->lock must not be held because of removeSwapFile!
void free_metadata(struct proc *p)
{
    800023cc:	1101                	addi	sp,sp,-32
    800023ce:	ec06                	sd	ra,24(sp)
    800023d0:	e822                	sd	s0,16(sp)
    800023d2:	e426                	sd	s1,8(sp)
    800023d4:	1000                	addi	s0,sp,32
    800023d6:	84aa                	mv	s1,a0
    if (p->swapFile && removeSwapFile(p) < 0) {
    800023d8:	16853783          	ld	a5,360(a0)
    800023dc:	c799                	beqz	a5,800023ea <free_metadata+0x1e>
    800023de:	00002097          	auipc	ra,0x2
    800023e2:	242080e7          	jalr	578(ra) # 80004620 <removeSwapFile>
    800023e6:	04054563          	bltz	a0,80002430 <free_metadata+0x64>
      panic("free_metadata: removeSwapFile failed");
    }
    p->swapFile = 0;
    800023ea:	1604b423          	sd	zero,360(s1)

  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    800023ee:	17048793          	addi	a5,s1,368
    800023f2:	27048713          	addi	a4,s1,624
      p->ram_pages[i].va = 0;
    800023f6:	0007b023          	sd	zero,0(a5)
      p->ram_pages[i].age = 0; // ADDED Q2
    800023fa:	0007a423          	sw	zero,8(a5)
      p->ram_pages[i].used = 0;
    800023fe:	0007a623          	sw	zero,12(a5)
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002402:	07c1                	addi	a5,a5,16
    80002404:	fee799e3          	bne	a5,a4,800023f6 <free_metadata+0x2a>
    80002408:	27048793          	addi	a5,s1,624
    8000240c:	37048713          	addi	a4,s1,880
    }
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
      p->disk_pages[i].va = 0;
    80002410:	0007b023          	sd	zero,0(a5)
      p->disk_pages[i].offset = 0;
    80002414:	0007a423          	sw	zero,8(a5)
      p->disk_pages[i].used = 0;
    80002418:	0007a623          	sw	zero,12(a5)
    for (int i = 0; i < MAX_DISK_PAGES; i++) {
    8000241c:	07c1                	addi	a5,a5,16
    8000241e:	fee799e3          	bne	a5,a4,80002410 <free_metadata+0x44>
    }
    p->scfifo_index = 0; // ADDED Q2
    80002422:	3604a823          	sw	zero,880(s1)
}
    80002426:	60e2                	ld	ra,24(sp)
    80002428:	6442                	ld	s0,16(sp)
    8000242a:	64a2                	ld	s1,8(sp)
    8000242c:	6105                	addi	sp,sp,32
    8000242e:	8082                	ret
      panic("free_metadata: removeSwapFile failed");
    80002430:	00006517          	auipc	a0,0x6
    80002434:	e3050513          	addi	a0,a0,-464 # 80008260 <digits+0x220>
    80002438:	ffffe097          	auipc	ra,0xffffe
    8000243c:	0f2080e7          	jalr	242(ra) # 8000052a <panic>

0000000080002440 <fork>:
{
    80002440:	7139                	addi	sp,sp,-64
    80002442:	fc06                	sd	ra,56(sp)
    80002444:	f822                	sd	s0,48(sp)
    80002446:	f426                	sd	s1,40(sp)
    80002448:	f04a                	sd	s2,32(sp)
    8000244a:	ec4e                	sd	s3,24(sp)
    8000244c:	e852                	sd	s4,16(sp)
    8000244e:	e456                	sd	s5,8(sp)
    80002450:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	582080e7          	jalr	1410(ra) # 800019d4 <myproc>
    8000245a:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	782080e7          	jalr	1922(ra) # 80001bde <allocproc>
    80002464:	10050c63          	beqz	a0,8000257c <fork+0x13c>
    80002468:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000246a:	048ab603          	ld	a2,72(s5)
    8000246e:	692c                	ld	a1,80(a0)
    80002470:	050ab503          	ld	a0,80(s5)
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	116080e7          	jalr	278(ra) # 8000158a <uvmcopy>
    8000247c:	04054863          	bltz	a0,800024cc <fork+0x8c>
  np->sz = p->sz;
    80002480:	048ab783          	ld	a5,72(s5)
    80002484:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002488:	058ab683          	ld	a3,88(s5)
    8000248c:	87b6                	mv	a5,a3
    8000248e:	058a3703          	ld	a4,88(s4)
    80002492:	12068693          	addi	a3,a3,288 # 10120 <_entry-0x7ffefee0>
    80002496:	0007b803          	ld	a6,0(a5)
    8000249a:	6788                	ld	a0,8(a5)
    8000249c:	6b8c                	ld	a1,16(a5)
    8000249e:	6f90                	ld	a2,24(a5)
    800024a0:	01073023          	sd	a6,0(a4)
    800024a4:	e708                	sd	a0,8(a4)
    800024a6:	eb0c                	sd	a1,16(a4)
    800024a8:	ef10                	sd	a2,24(a4)
    800024aa:	02078793          	addi	a5,a5,32
    800024ae:	02070713          	addi	a4,a4,32
    800024b2:	fed792e3          	bne	a5,a3,80002496 <fork+0x56>
  np->trapframe->a0 = 0;
    800024b6:	058a3783          	ld	a5,88(s4)
    800024ba:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800024be:	0d0a8493          	addi	s1,s5,208
    800024c2:	0d0a0913          	addi	s2,s4,208
    800024c6:	150a8993          	addi	s3,s5,336
    800024ca:	a00d                	j	800024ec <fork+0xac>
    freeproc(np);
    800024cc:	8552                	mv	a0,s4
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	6b8080e7          	jalr	1720(ra) # 80001b86 <freeproc>
    release(&np->lock);
    800024d6:	8552                	mv	a0,s4
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	79e080e7          	jalr	1950(ra) # 80000c76 <release>
    return -1;
    800024e0:	597d                	li	s2,-1
    800024e2:	a059                	j	80002568 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    800024e4:	04a1                	addi	s1,s1,8
    800024e6:	0921                	addi	s2,s2,8
    800024e8:	00998b63          	beq	s3,s1,800024fe <fork+0xbe>
    if(p->ofile[i])
    800024ec:	6088                	ld	a0,0(s1)
    800024ee:	d97d                	beqz	a0,800024e4 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800024f0:	00003097          	auipc	ra,0x3
    800024f4:	a30080e7          	jalr	-1488(ra) # 80004f20 <filedup>
    800024f8:	00a93023          	sd	a0,0(s2)
    800024fc:	b7e5                	j	800024e4 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800024fe:	150ab503          	ld	a0,336(s5)
    80002502:	00002097          	auipc	ra,0x2
    80002506:	87e080e7          	jalr	-1922(ra) # 80003d80 <idup>
    8000250a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000250e:	4641                	li	a2,16
    80002510:	158a8593          	addi	a1,s5,344
    80002514:	158a0513          	addi	a0,s4,344
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	8f8080e7          	jalr	-1800(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002520:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002524:	8552                	mv	a0,s4
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	750080e7          	jalr	1872(ra) # 80000c76 <release>
  acquire(&wait_lock);
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	d8a48493          	addi	s1,s1,-630 # 800112b8 <wait_lock>
    80002536:	8526                	mv	a0,s1
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	68a080e7          	jalr	1674(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002540:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	730080e7          	jalr	1840(ra) # 80000c76 <release>
  acquire(&np->lock);
    8000254e:	8552                	mv	a0,s4
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	672080e7          	jalr	1650(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80002558:	478d                	li	a5,3
    8000255a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    8000255e:	8552                	mv	a0,s4
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	716080e7          	jalr	1814(ra) # 80000c76 <release>
}
    80002568:	854a                	mv	a0,s2
    8000256a:	70e2                	ld	ra,56(sp)
    8000256c:	7442                	ld	s0,48(sp)
    8000256e:	74a2                	ld	s1,40(sp)
    80002570:	7902                	ld	s2,32(sp)
    80002572:	69e2                	ld	s3,24(sp)
    80002574:	6a42                	ld	s4,16(sp)
    80002576:	6aa2                	ld	s5,8(sp)
    80002578:	6121                	addi	sp,sp,64
    8000257a:	8082                	ret
    return -1;
    8000257c:	597d                	li	s2,-1
    8000257e:	b7ed                	j	80002568 <fork+0x128>

0000000080002580 <exit>:
{
    80002580:	7179                	addi	sp,sp,-48
    80002582:	f406                	sd	ra,40(sp)
    80002584:	f022                	sd	s0,32(sp)
    80002586:	ec26                	sd	s1,24(sp)
    80002588:	e84a                	sd	s2,16(sp)
    8000258a:	e44e                	sd	s3,8(sp)
    8000258c:	e052                	sd	s4,0(sp)
    8000258e:	1800                	addi	s0,sp,48
    80002590:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	442080e7          	jalr	1090(ra) # 800019d4 <myproc>
    8000259a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000259c:	00007797          	auipc	a5,0x7
    800025a0:	a8c7b783          	ld	a5,-1396(a5) # 80009028 <initproc>
    800025a4:	0d050493          	addi	s1,a0,208
    800025a8:	15050913          	addi	s2,a0,336
    800025ac:	02a79363          	bne	a5,a0,800025d2 <exit+0x52>
    panic("init exiting");
    800025b0:	00006517          	auipc	a0,0x6
    800025b4:	cd850513          	addi	a0,a0,-808 # 80008288 <digits+0x248>
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	f72080e7          	jalr	-142(ra) # 8000052a <panic>
      fileclose(f);
    800025c0:	00003097          	auipc	ra,0x3
    800025c4:	9b2080e7          	jalr	-1614(ra) # 80004f72 <fileclose>
      p->ofile[fd] = 0;
    800025c8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025cc:	04a1                	addi	s1,s1,8
    800025ce:	01248563          	beq	s1,s2,800025d8 <exit+0x58>
    if(p->ofile[fd]){
    800025d2:	6088                	ld	a0,0(s1)
    800025d4:	f575                	bnez	a0,800025c0 <exit+0x40>
    800025d6:	bfdd                	j	800025cc <exit+0x4c>
  begin_op();
    800025d8:	00002097          	auipc	ra,0x2
    800025dc:	4ce080e7          	jalr	1230(ra) # 80004aa6 <begin_op>
  iput(p->cwd);
    800025e0:	1509b503          	ld	a0,336(s3)
    800025e4:	00002097          	auipc	ra,0x2
    800025e8:	994080e7          	jalr	-1644(ra) # 80003f78 <iput>
  end_op();
    800025ec:	00002097          	auipc	ra,0x2
    800025f0:	53a080e7          	jalr	1338(ra) # 80004b26 <end_op>
  p->cwd = 0;
    800025f4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800025f8:	0000f497          	auipc	s1,0xf
    800025fc:	cc048493          	addi	s1,s1,-832 # 800112b8 <wait_lock>
    80002600:	8526                	mv	a0,s1
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	5c0080e7          	jalr	1472(ra) # 80000bc2 <acquire>
  reparent(p);
    8000260a:	854e                	mv	a0,s3
    8000260c:	00000097          	auipc	ra,0x0
    80002610:	b30080e7          	jalr	-1232(ra) # 8000213c <reparent>
  wakeup(p->parent);
    80002614:	0389b503          	ld	a0,56(s3)
    80002618:	00000097          	auipc	ra,0x0
    8000261c:	aae080e7          	jalr	-1362(ra) # 800020c6 <wakeup>
  acquire(&p->lock);
    80002620:	854e                	mv	a0,s3
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	5a0080e7          	jalr	1440(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000262a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000262e:	4795                	li	a5,5
    80002630:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002634:	8526                	mv	a0,s1
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	640080e7          	jalr	1600(ra) # 80000c76 <release>
  sched();
    8000263e:	00000097          	auipc	ra,0x0
    80002642:	912080e7          	jalr	-1774(ra) # 80001f50 <sched>
  panic("zombie exit");
    80002646:	00006517          	auipc	a0,0x6
    8000264a:	c5250513          	addi	a0,a0,-942 # 80008298 <digits+0x258>
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	edc080e7          	jalr	-292(ra) # 8000052a <panic>

0000000080002656 <wait>:
{
    80002656:	715d                	addi	sp,sp,-80
    80002658:	e486                	sd	ra,72(sp)
    8000265a:	e0a2                	sd	s0,64(sp)
    8000265c:	fc26                	sd	s1,56(sp)
    8000265e:	f84a                	sd	s2,48(sp)
    80002660:	f44e                	sd	s3,40(sp)
    80002662:	f052                	sd	s4,32(sp)
    80002664:	ec56                	sd	s5,24(sp)
    80002666:	e85a                	sd	s6,16(sp)
    80002668:	e45e                	sd	s7,8(sp)
    8000266a:	e062                	sd	s8,0(sp)
    8000266c:	0880                	addi	s0,sp,80
    8000266e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002670:	fffff097          	auipc	ra,0xfffff
    80002674:	364080e7          	jalr	868(ra) # 800019d4 <myproc>
    80002678:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000267a:	0000f517          	auipc	a0,0xf
    8000267e:	c3e50513          	addi	a0,a0,-962 # 800112b8 <wait_lock>
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	540080e7          	jalr	1344(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000268a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000268c:	4a15                	li	s4,5
        havekids = 1;
    8000268e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002690:	0001d997          	auipc	s3,0x1d
    80002694:	e4098993          	addi	s3,s3,-448 # 8001f4d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002698:	0000fc17          	auipc	s8,0xf
    8000269c:	c20c0c13          	addi	s8,s8,-992 # 800112b8 <wait_lock>
    havekids = 0;
    800026a0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800026a2:	0000f497          	auipc	s1,0xf
    800026a6:	02e48493          	addi	s1,s1,46 # 800116d0 <proc>
    800026aa:	a0bd                	j	80002718 <wait+0xc2>
          pid = np->pid;
    800026ac:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026b0:	000b0e63          	beqz	s6,800026cc <wait+0x76>
    800026b4:	4691                	li	a3,4
    800026b6:	02c48613          	addi	a2,s1,44
    800026ba:	85da                	mv	a1,s6
    800026bc:	05093503          	ld	a0,80(s2)
    800026c0:	fffff097          	auipc	ra,0xfffff
    800026c4:	fd4080e7          	jalr	-44(ra) # 80001694 <copyout>
    800026c8:	02054563          	bltz	a0,800026f2 <wait+0x9c>
          freeproc(np);
    800026cc:	8526                	mv	a0,s1
    800026ce:	fffff097          	auipc	ra,0xfffff
    800026d2:	4b8080e7          	jalr	1208(ra) # 80001b86 <freeproc>
          release(&np->lock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	59e080e7          	jalr	1438(ra) # 80000c76 <release>
          release(&wait_lock);
    800026e0:	0000f517          	auipc	a0,0xf
    800026e4:	bd850513          	addi	a0,a0,-1064 # 800112b8 <wait_lock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	58e080e7          	jalr	1422(ra) # 80000c76 <release>
          return pid;
    800026f0:	a09d                	j	80002756 <wait+0x100>
            release(&np->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	582080e7          	jalr	1410(ra) # 80000c76 <release>
            release(&wait_lock);
    800026fc:	0000f517          	auipc	a0,0xf
    80002700:	bbc50513          	addi	a0,a0,-1092 # 800112b8 <wait_lock>
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	572080e7          	jalr	1394(ra) # 80000c76 <release>
            return -1;
    8000270c:	59fd                	li	s3,-1
    8000270e:	a0a1                	j	80002756 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002710:	37848493          	addi	s1,s1,888
    80002714:	03348463          	beq	s1,s3,8000273c <wait+0xe6>
      if(np->parent == p){
    80002718:	7c9c                	ld	a5,56(s1)
    8000271a:	ff279be3          	bne	a5,s2,80002710 <wait+0xba>
        acquire(&np->lock);
    8000271e:	8526                	mv	a0,s1
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	4a2080e7          	jalr	1186(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002728:	4c9c                	lw	a5,24(s1)
    8000272a:	f94781e3          	beq	a5,s4,800026ac <wait+0x56>
        release(&np->lock);
    8000272e:	8526                	mv	a0,s1
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	546080e7          	jalr	1350(ra) # 80000c76 <release>
        havekids = 1;
    80002738:	8756                	mv	a4,s5
    8000273a:	bfd9                	j	80002710 <wait+0xba>
    if(!havekids || p->killed){
    8000273c:	c701                	beqz	a4,80002744 <wait+0xee>
    8000273e:	02892783          	lw	a5,40(s2)
    80002742:	c79d                	beqz	a5,80002770 <wait+0x11a>
      release(&wait_lock);
    80002744:	0000f517          	auipc	a0,0xf
    80002748:	b7450513          	addi	a0,a0,-1164 # 800112b8 <wait_lock>
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	52a080e7          	jalr	1322(ra) # 80000c76 <release>
      return -1;
    80002754:	59fd                	li	s3,-1
}
    80002756:	854e                	mv	a0,s3
    80002758:	60a6                	ld	ra,72(sp)
    8000275a:	6406                	ld	s0,64(sp)
    8000275c:	74e2                	ld	s1,56(sp)
    8000275e:	7942                	ld	s2,48(sp)
    80002760:	79a2                	ld	s3,40(sp)
    80002762:	7a02                	ld	s4,32(sp)
    80002764:	6ae2                	ld	s5,24(sp)
    80002766:	6b42                	ld	s6,16(sp)
    80002768:	6ba2                	ld	s7,8(sp)
    8000276a:	6c02                	ld	s8,0(sp)
    8000276c:	6161                	addi	sp,sp,80
    8000276e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002770:	85e2                	mv	a1,s8
    80002772:	854a                	mv	a0,s2
    80002774:	00000097          	auipc	ra,0x0
    80002778:	8ee080e7          	jalr	-1810(ra) # 80002062 <sleep>
    havekids = 0;
    8000277c:	b715                	j	800026a0 <wait+0x4a>

000000008000277e <get_free_page_in_disk>:
// ADDED Q1
int get_free_page_in_disk()
{
    8000277e:	1141                	addi	sp,sp,-16
    80002780:	e406                	sd	ra,8(sp)
    80002782:	e022                	sd	s0,0(sp)
    80002784:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002786:	fffff097          	auipc	ra,0xfffff
    8000278a:	24e080e7          	jalr	590(ra) # 800019d4 <myproc>
  int i = 0;
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    8000278e:	27050793          	addi	a5,a0,624
  int i = 0;
    80002792:	4501                	li	a0,0
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    80002794:	46c1                	li	a3,16
    if (!disk_pg->used) {
    80002796:	47d8                	lw	a4,12(a5)
    80002798:	c711                	beqz	a4,800027a4 <get_free_page_in_disk+0x26>
  for(struct disk_page *disk_pg = p->disk_pages; disk_pg < &p->disk_pages[MAX_DISK_PAGES]; disk_pg++, i++){
    8000279a:	07c1                	addi	a5,a5,16
    8000279c:	2505                	addiw	a0,a0,1
    8000279e:	fed51ce3          	bne	a0,a3,80002796 <get_free_page_in_disk+0x18>
      return i;
    }
  }
  return -1;
    800027a2:	557d                	li	a0,-1
}
    800027a4:	60a2                	ld	ra,8(sp)
    800027a6:	6402                	ld	s0,0(sp)
    800027a8:	0141                	addi	sp,sp,16
    800027aa:	8082                	ret

00000000800027ac <swapout>:

void swapout(int ram_pg_index)
{
    800027ac:	7139                	addi	sp,sp,-64
    800027ae:	fc06                	sd	ra,56(sp)
    800027b0:	f822                	sd	s0,48(sp)
    800027b2:	f426                	sd	s1,40(sp)
    800027b4:	f04a                	sd	s2,32(sp)
    800027b6:	ec4e                	sd	s3,24(sp)
    800027b8:	e852                	sd	s4,16(sp)
    800027ba:	e456                	sd	s5,8(sp)
    800027bc:	0080                	addi	s0,sp,64
    800027be:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800027c0:	fffff097          	auipc	ra,0xfffff
    800027c4:	214080e7          	jalr	532(ra) # 800019d4 <myproc>
  if (ram_pg_index < 0 || ram_pg_index >= MAX_PSYC_PAGES) {
    800027c8:	0004871b          	sext.w	a4,s1
    800027cc:	47bd                	li	a5,15
    800027ce:	0ae7e363          	bltu	a5,a4,80002874 <swapout+0xc8>
    800027d2:	8a2a                	mv	s4,a0
    panic("swapout: ram page index out of bounds");
  }
  struct ram_page *ram_pg_to_swap = &p->ram_pages[ram_pg_index];

  if (!ram_pg_to_swap->used) {
    800027d4:	0492                	slli	s1,s1,0x4
    800027d6:	94aa                	add	s1,s1,a0
    800027d8:	17c4a783          	lw	a5,380(s1)
    800027dc:	c7c5                	beqz	a5,80002884 <swapout+0xd8>
    panic("swapout: page unused");
  }

  pte_t *pte;
  if ((pte = walk(p->pagetable, ram_pg_to_swap->va, 0)) == 0) {
    800027de:	4601                	li	a2,0
    800027e0:	1704b583          	ld	a1,368(s1)
    800027e4:	6928                	ld	a0,80(a0)
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	7c0080e7          	jalr	1984(ra) # 80000fa6 <walk>
    800027ee:	89aa                	mv	s3,a0
    800027f0:	c155                	beqz	a0,80002894 <swapout+0xe8>
    panic("swapout: walk failed");
  }

  if (!(*pte & PTE_V) || (*pte & PTE_PG)) {
    800027f2:	611c                	ld	a5,0(a0)
    800027f4:	2017f793          	andi	a5,a5,513
    800027f8:	4705                	li	a4,1
    800027fa:	0ae79563          	bne	a5,a4,800028a4 <swapout+0xf8>
    panic("swapout: page is not in ram");
  }

  int unused_disk_pg_index;
  if ((unused_disk_pg_index = get_free_page_in_disk()) < 0) {
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	f80080e7          	jalr	-128(ra) # 8000277e <get_free_page_in_disk>
    80002806:	0a054763          	bltz	a0,800028b4 <swapout+0x108>
    panic("swapout: disk overflow");
  }

  struct disk_page *disk_pg_to_store = &p->disk_pages[unused_disk_pg_index];
  uint64 pa = PTE2PA(*pte);
    8000280a:	0009ba83          	ld	s5,0(s3)
    8000280e:	00aada93          	srli	s5,s5,0xa
    80002812:	0ab2                	slli	s5,s5,0xc
    80002814:	00451913          	slli	s2,a0,0x4
    80002818:	9952                	add	s2,s2,s4
  if (writeToSwapFile(p, (char *)pa, disk_pg_to_store->offset, PGSIZE) < 0) {
    8000281a:	6685                	lui	a3,0x1
    8000281c:	27892603          	lw	a2,632(s2)
    80002820:	85d6                	mv	a1,s5
    80002822:	8552                	mv	a0,s4
    80002824:	00002097          	auipc	ra,0x2
    80002828:	054080e7          	jalr	84(ra) # 80004878 <writeToSwapFile>
    8000282c:	08054c63          	bltz	a0,800028c4 <swapout+0x118>
    panic("swapout: failed to write to swapFile");
  }
  disk_pg_to_store->used = 1;
    80002830:	4785                	li	a5,1
    80002832:	26f92e23          	sw	a5,636(s2)
  disk_pg_to_store->va = ram_pg_to_swap->va;
    80002836:	1704b783          	ld	a5,368(s1)
    8000283a:	26f93823          	sd	a5,624(s2)
  kfree((void *)pa);
    8000283e:	8556                	mv	a0,s5
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	196080e7          	jalr	406(ra) # 800009d6 <kfree>

  ram_pg_to_swap->va = 0;
    80002848:	1604b823          	sd	zero,368(s1)
  ram_pg_to_swap->used = 0;
    8000284c:	1604ae23          	sw	zero,380(s1)

  *pte = *pte & ~PTE_V;
    80002850:	0009b783          	ld	a5,0(s3)
    80002854:	9bf9                	andi	a5,a5,-2
  *pte = *pte | PTE_PG; // Paged out to secondary storage
    80002856:	2007e793          	ori	a5,a5,512
    8000285a:	00f9b023          	sd	a5,0(s3)
  asm volatile("sfence.vma zero, zero");
    8000285e:	12000073          	sfence.vma
  sfence_vma();   // clear TLB
}
    80002862:	70e2                	ld	ra,56(sp)
    80002864:	7442                	ld	s0,48(sp)
    80002866:	74a2                	ld	s1,40(sp)
    80002868:	7902                	ld	s2,32(sp)
    8000286a:	69e2                	ld	s3,24(sp)
    8000286c:	6a42                	ld	s4,16(sp)
    8000286e:	6aa2                	ld	s5,8(sp)
    80002870:	6121                	addi	sp,sp,64
    80002872:	8082                	ret
    panic("swapout: ram page index out of bounds");
    80002874:	00006517          	auipc	a0,0x6
    80002878:	a3450513          	addi	a0,a0,-1484 # 800082a8 <digits+0x268>
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	cae080e7          	jalr	-850(ra) # 8000052a <panic>
    panic("swapout: page unused");
    80002884:	00006517          	auipc	a0,0x6
    80002888:	a4c50513          	addi	a0,a0,-1460 # 800082d0 <digits+0x290>
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	c9e080e7          	jalr	-866(ra) # 8000052a <panic>
    panic("swapout: walk failed");
    80002894:	00006517          	auipc	a0,0x6
    80002898:	a5450513          	addi	a0,a0,-1452 # 800082e8 <digits+0x2a8>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	c8e080e7          	jalr	-882(ra) # 8000052a <panic>
    panic("swapout: page is not in ram");
    800028a4:	00006517          	auipc	a0,0x6
    800028a8:	a5c50513          	addi	a0,a0,-1444 # 80008300 <digits+0x2c0>
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	c7e080e7          	jalr	-898(ra) # 8000052a <panic>
    panic("swapout: disk overflow");
    800028b4:	00006517          	auipc	a0,0x6
    800028b8:	a6c50513          	addi	a0,a0,-1428 # 80008320 <digits+0x2e0>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	c6e080e7          	jalr	-914(ra) # 8000052a <panic>
    panic("swapout: failed to write to swapFile");
    800028c4:	00006517          	auipc	a0,0x6
    800028c8:	a7450513          	addi	a0,a0,-1420 # 80008338 <digits+0x2f8>
    800028cc:	ffffe097          	auipc	ra,0xffffe
    800028d0:	c5e080e7          	jalr	-930(ra) # 8000052a <panic>

00000000800028d4 <swapin>:

void swapin(int disk_index, int ram_index)
{
    800028d4:	7139                	addi	sp,sp,-64
    800028d6:	fc06                	sd	ra,56(sp)
    800028d8:	f822                	sd	s0,48(sp)
    800028da:	f426                	sd	s1,40(sp)
    800028dc:	f04a                	sd	s2,32(sp)
    800028de:	ec4e                	sd	s3,24(sp)
    800028e0:	e852                	sd	s4,16(sp)
    800028e2:	e456                	sd	s5,8(sp)
    800028e4:	0080                	addi	s0,sp,64
  if (disk_index < 0 || disk_index >= MAX_DISK_PAGES) {
    800028e6:	47bd                	li	a5,15
    800028e8:	0aa7ed63          	bltu	a5,a0,800029a2 <swapin+0xce>
    800028ec:	89ae                	mv	s3,a1
    800028ee:	892a                	mv	s2,a0
    panic("swapin: disk index out of bounds");
  }

  if (ram_index < 0 || ram_index >= MAX_PSYC_PAGES) {
    800028f0:	0005879b          	sext.w	a5,a1
    800028f4:	473d                	li	a4,15
    800028f6:	0af76e63          	bltu	a4,a5,800029b2 <swapin+0xde>
    panic("swapin: ram index out of bounds");
  }
  struct proc *p = myproc();
    800028fa:	fffff097          	auipc	ra,0xfffff
    800028fe:	0da080e7          	jalr	218(ra) # 800019d4 <myproc>
    80002902:	8aaa                	mv	s5,a0
  struct disk_page *disk_pg = &p->disk_pages[disk_index]; 

  if (!disk_pg->used) {
    80002904:	0912                	slli	s2,s2,0x4
    80002906:	992a                	add	s2,s2,a0
    80002908:	27c92783          	lw	a5,636(s2)
    8000290c:	cbdd                	beqz	a5,800029c2 <swapin+0xee>
    panic("swapin: page unused");
  }

  pte_t *pte;
  if ((pte = walk(p->pagetable, disk_pg->va, 0)) == 0) {
    8000290e:	4601                	li	a2,0
    80002910:	27093583          	ld	a1,624(s2)
    80002914:	6928                	ld	a0,80(a0)
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	690080e7          	jalr	1680(ra) # 80000fa6 <walk>
    8000291e:	8a2a                	mv	s4,a0
    80002920:	c94d                	beqz	a0,800029d2 <swapin+0xfe>
    panic("swapin: unallocated pte");
  }

  if ((*pte & PTE_V) || !(*pte & PTE_PG))
    80002922:	611c                	ld	a5,0(a0)
    80002924:	2017f793          	andi	a5,a5,513
    80002928:	20000713          	li	a4,512
    8000292c:	0ae79b63          	bne	a5,a4,800029e2 <swapin+0x10e>
      panic("swapin: page is not in disk");

  struct ram_page *ram_pg = &p->ram_pages[ram_index];
  if (ram_pg->used) {
    80002930:	0992                	slli	s3,s3,0x4
    80002932:	99d6                	add	s3,s3,s5
    80002934:	17c9a783          	lw	a5,380(s3)
    80002938:	efcd                	bnez	a5,800029f2 <swapin+0x11e>
    panic("swapin: ram page used");
  }

  uint64 npa;
  if ( (npa = (uint64)kalloc()) == 0 ) {
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	198080e7          	jalr	408(ra) # 80000ad2 <kalloc>
    80002942:	84aa                	mv	s1,a0
    80002944:	cd5d                	beqz	a0,80002a02 <swapin+0x12e>
    panic("swapin: failed alocate physical address");
  }

  if (readFromSwapFile(p, (char *)npa, disk_pg->offset, PGSIZE) < 0) {
    80002946:	6685                	lui	a3,0x1
    80002948:	27892603          	lw	a2,632(s2)
    8000294c:	85aa                	mv	a1,a0
    8000294e:	8556                	mv	a0,s5
    80002950:	00002097          	auipc	ra,0x2
    80002954:	f4c080e7          	jalr	-180(ra) # 8000489c <readFromSwapFile>
    80002958:	0a054d63          	bltz	a0,80002a12 <swapin+0x13e>
    panic("swapin: read from disk failed");
  }

  ram_pg->used = 1;
    8000295c:	4785                	li	a5,1
    8000295e:	16f9ae23          	sw	a5,380(s3)
  ram_pg->va = disk_pg->va;
    80002962:	27093783          	ld	a5,624(s2)
    80002966:	16f9b823          	sd	a5,368(s3)
  // ADDED Q2
  #ifdef LAPA
    ram_pg->age = 0xFFFFFFFF;
  #endif
  #ifndef LAPA 
    ram_pg->age = 0;
    8000296a:	1609ac23          	sw	zero,376(s3)
  #endif

  disk_pg->va = 0;
    8000296e:	26093823          	sd	zero,624(s2)
  disk_pg->used = 0;
    80002972:	26092e23          	sw	zero,636(s2)

  *pte = *pte | PTE_V;                           
  *pte = *pte & ~PTE_PG;                         
  *pte = PA2PTE(npa) | PTE_FLAGS(*pte); // update pte using the npa
    80002976:	80b1                	srli	s1,s1,0xc
    80002978:	04aa                	slli	s1,s1,0xa
    8000297a:	000a3783          	ld	a5,0(s4)
    8000297e:	1ff7f793          	andi	a5,a5,511
    80002982:	8cdd                	or	s1,s1,a5
    80002984:	0014e493          	ori	s1,s1,1
    80002988:	009a3023          	sd	s1,0(s4)
    8000298c:	12000073          	sfence.vma
  sfence_vma(); // clear TLB
}
    80002990:	70e2                	ld	ra,56(sp)
    80002992:	7442                	ld	s0,48(sp)
    80002994:	74a2                	ld	s1,40(sp)
    80002996:	7902                	ld	s2,32(sp)
    80002998:	69e2                	ld	s3,24(sp)
    8000299a:	6a42                	ld	s4,16(sp)
    8000299c:	6aa2                	ld	s5,8(sp)
    8000299e:	6121                	addi	sp,sp,64
    800029a0:	8082                	ret
    panic("swapin: disk index out of bounds");
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	9be50513          	addi	a0,a0,-1602 # 80008360 <digits+0x320>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	b80080e7          	jalr	-1152(ra) # 8000052a <panic>
    panic("swapin: ram index out of bounds");
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	9d650513          	addi	a0,a0,-1578 # 80008388 <digits+0x348>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	b70080e7          	jalr	-1168(ra) # 8000052a <panic>
    panic("swapin: page unused");
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	9e650513          	addi	a0,a0,-1562 # 800083a8 <digits+0x368>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	b60080e7          	jalr	-1184(ra) # 8000052a <panic>
    panic("swapin: unallocated pte");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	9ee50513          	addi	a0,a0,-1554 # 800083c0 <digits+0x380>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	b50080e7          	jalr	-1200(ra) # 8000052a <panic>
      panic("swapin: page is not in disk");
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	9f650513          	addi	a0,a0,-1546 # 800083d8 <digits+0x398>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	b40080e7          	jalr	-1216(ra) # 8000052a <panic>
    panic("swapin: ram page used");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	a0650513          	addi	a0,a0,-1530 # 800083f8 <digits+0x3b8>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b30080e7          	jalr	-1232(ra) # 8000052a <panic>
    panic("swapin: failed alocate physical address");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	a0e50513          	addi	a0,a0,-1522 # 80008410 <digits+0x3d0>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b20080e7          	jalr	-1248(ra) # 8000052a <panic>
    panic("swapin: read from disk failed");
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	a2650513          	addi	a0,a0,-1498 # 80008438 <digits+0x3f8>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b10080e7          	jalr	-1264(ra) # 8000052a <panic>

0000000080002a22 <get_unused_ram_index>:

int get_unused_ram_index(struct proc* p)
{
    80002a22:	1141                	addi	sp,sp,-16
    80002a24:	e422                	sd	s0,8(sp)
    80002a26:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002a28:	17c50793          	addi	a5,a0,380
    80002a2c:	4501                	li	a0,0
    80002a2e:	46c1                	li	a3,16
    if (!p->ram_pages[i].used) {
    80002a30:	4398                	lw	a4,0(a5)
    80002a32:	c711                	beqz	a4,80002a3e <get_unused_ram_index+0x1c>
  for (int i = 0; i < MAX_PSYC_PAGES; i++) {
    80002a34:	2505                	addiw	a0,a0,1
    80002a36:	07c1                	addi	a5,a5,16
    80002a38:	fed51ce3          	bne	a0,a3,80002a30 <get_unused_ram_index+0xe>
      return i;
    }
  }
  return -1;
    80002a3c:	557d                	li	a0,-1
}
    80002a3e:	6422                	ld	s0,8(sp)
    80002a40:	0141                	addi	sp,sp,16
    80002a42:	8082                	ret

0000000080002a44 <get_disk_page_index>:

int get_disk_page_index(struct proc *p, uint64 va)
{
    80002a44:	1141                	addi	sp,sp,-16
    80002a46:	e422                	sd	s0,8(sp)
    80002a48:	0800                	addi	s0,sp,16
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002a4a:	27050793          	addi	a5,a0,624
    80002a4e:	4501                	li	a0,0
    80002a50:	46c1                	li	a3,16
    if (p->disk_pages[i].va == va) {
    80002a52:	6398                	ld	a4,0(a5)
    80002a54:	00b70763          	beq	a4,a1,80002a62 <get_disk_page_index+0x1e>
  for (int i = 0; i < MAX_DISK_PAGES; i++) {
    80002a58:	2505                	addiw	a0,a0,1
    80002a5a:	07c1                	addi	a5,a5,16
    80002a5c:	fed51be3          	bne	a0,a3,80002a52 <get_disk_page_index+0xe>
      return i;
    }
  }
  return -1;
    80002a60:	557d                	li	a0,-1
}
    80002a62:	6422                	ld	s0,8(sp)
    80002a64:	0141                	addi	sp,sp,16
    80002a66:	8082                	ret

0000000080002a68 <handle_page_fault>:

void handle_page_fault(uint64 va)
{
    80002a68:	7179                	addi	sp,sp,-48
    80002a6a:	f406                	sd	ra,40(sp)
    80002a6c:	f022                	sd	s0,32(sp)
    80002a6e:	ec26                	sd	s1,24(sp)
    80002a70:	e84a                	sd	s2,16(sp)
    80002a72:	e44e                	sd	s3,8(sp)
    80002a74:	1800                	addi	s0,sp,48
    80002a76:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	f5c080e7          	jalr	-164(ra) # 800019d4 <myproc>
    80002a80:	84aa                	mv	s1,a0
  pte_t *pte;
  if (!(pte = walk(p->pagetable, va, 0))) {
    80002a82:	4601                	li	a2,0
    80002a84:	85ce                	mv	a1,s3
    80002a86:	6928                	ld	a0,80(a0)
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	51e080e7          	jalr	1310(ra) # 80000fa6 <walk>
    80002a90:	c531                	beqz	a0,80002adc <handle_page_fault+0x74>
    panic("handle_page_fault: walk failed");
  }

  if(*pte & PTE_V){
    80002a92:	611c                	ld	a5,0(a0)
    80002a94:	0017f713          	andi	a4,a5,1
    80002a98:	eb31                	bnez	a4,80002aec <handle_page_fault+0x84>
    panic("handle_page_fault: invalid pte");
  }
  
  if(!(*pte & PTE_PG)) {
    80002a9a:	2007f793          	andi	a5,a5,512
    80002a9e:	cfb9                	beqz	a5,80002afc <handle_page_fault+0x94>
    panic("handle_page_fault: PTE_PG off");
  }
  
  int unused_ram_pg_index;
  if ((unused_ram_pg_index = get_unused_ram_index(p)) < 0) {    
    80002aa0:	8526                	mv	a0,s1
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	f80080e7          	jalr	-128(ra) # 80002a22 <get_unused_ram_index>
    80002aaa:	892a                	mv	s2,a0
    80002aac:	06054063          	bltz	a0,80002b0c <handle_page_fault+0xa4>
      swapout(ram_pg_index_to_swap); 
      unused_ram_pg_index = ram_pg_index_to_swap;
      printf("handle_page_fault: replace index %d\n", unused_ram_pg_index); // ADDED Q3
  }
  int target_index;
  if( (target_index = get_disk_page_index(p, PGROUNDDOWN(va))) < 0) {
    80002ab0:	75fd                	lui	a1,0xfffff
    80002ab2:	00b9f5b3          	and	a1,s3,a1
    80002ab6:	8526                	mv	a0,s1
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	f8c080e7          	jalr	-116(ra) # 80002a44 <get_disk_page_index>
    80002ac0:	06054663          	bltz	a0,80002b2c <handle_page_fault+0xc4>
    panic("handle_page_fault: get_disk_page_index failed");
  }
  swapin(target_index, unused_ram_pg_index);
    80002ac4:	85ca                	mv	a1,s2
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	e0e080e7          	jalr	-498(ra) # 800028d4 <swapin>
}
    80002ace:	70a2                	ld	ra,40(sp)
    80002ad0:	7402                	ld	s0,32(sp)
    80002ad2:	64e2                	ld	s1,24(sp)
    80002ad4:	6942                	ld	s2,16(sp)
    80002ad6:	69a2                	ld	s3,8(sp)
    80002ad8:	6145                	addi	sp,sp,48
    80002ada:	8082                	ret
    panic("handle_page_fault: walk failed");
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	97c50513          	addi	a0,a0,-1668 # 80008458 <digits+0x418>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	a46080e7          	jalr	-1466(ra) # 8000052a <panic>
    panic("handle_page_fault: invalid pte");
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	98c50513          	addi	a0,a0,-1652 # 80008478 <digits+0x438>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a36080e7          	jalr	-1482(ra) # 8000052a <panic>
    panic("handle_page_fault: PTE_PG off");
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	99c50513          	addi	a0,a0,-1636 # 80008498 <digits+0x458>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a26080e7          	jalr	-1498(ra) # 8000052a <panic>
      swapout(ram_pg_index_to_swap); 
    80002b0c:	557d                	li	a0,-1
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	c9e080e7          	jalr	-866(ra) # 800027ac <swapout>
      printf("handle_page_fault: replace index %d\n", unused_ram_pg_index); // ADDED Q3
    80002b16:	55fd                	li	a1,-1
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	9a050513          	addi	a0,a0,-1632 # 800084b8 <digits+0x478>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a54080e7          	jalr	-1452(ra) # 80000574 <printf>
      unused_ram_pg_index = ram_pg_index_to_swap;
    80002b28:	597d                	li	s2,-1
    80002b2a:	b759                	j	80002ab0 <handle_page_fault+0x48>
    panic("handle_page_fault: get_disk_page_index failed");
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	9b450513          	addi	a0,a0,-1612 # 800084e0 <digits+0x4a0>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	9f6080e7          	jalr	-1546(ra) # 8000052a <panic>

0000000080002b3c <insert_page_to_ram>:

void insert_page_to_ram(uint64 va)
{
    80002b3c:	1141                	addi	sp,sp,-16
    80002b3e:	e406                	sd	ra,8(sp)
    80002b40:	e022                	sd	s0,0(sp)
    80002b42:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	e90080e7          	jalr	-368(ra) # 800019d4 <myproc>
    ram_pg->age = 0xFFFFFFFF;
  #endif
  #ifndef LAPA 
    ram_pg->age = 0;
  #endif
}
    80002b4c:	60a2                	ld	ra,8(sp)
    80002b4e:	6402                	ld	s0,0(sp)
    80002b50:	0141                	addi	sp,sp,16
    80002b52:	8082                	ret

0000000080002b54 <remove_page_from_ram>:

void remove_page_from_ram(uint64 va)
{
    80002b54:	1141                	addi	sp,sp,-16
    80002b56:	e406                	sd	ra,8(sp)
    80002b58:	e022                	sd	s0,0(sp)
    80002b5a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	e78080e7          	jalr	-392(ra) # 800019d4 <myproc>
      p->disk_pages[i].used = 0;
      return;
    }
  }
  panic("remove_page_from_ram failed");
}
    80002b64:	60a2                	ld	ra,8(sp)
    80002b66:	6402                	ld	s0,0(sp)
    80002b68:	0141                	addi	sp,sp,16
    80002b6a:	8082                	ret

0000000080002b6c <nfua>:

// ADDED Q2
int nfua()
{
    80002b6c:	1141                	addi	sp,sp,-16
    80002b6e:	e406                	sd	ra,8(sp)
    80002b70:	e022                	sd	s0,0(sp)
    80002b72:	0800                	addi	s0,sp,16
  int i = 0;
  int min_index = 0;
  uint min_age = 0xFFFFFFFF;
  struct proc *p = myproc();
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	e60080e7          	jalr	-416(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b7c:	17050713          	addi	a4,a0,368
  uint min_age = 0xFFFFFFFF;
    80002b80:	567d                	li	a2,-1
  int min_index = 0;
    80002b82:	4501                	li	a0,0
  int i = 0;
    80002b84:	4781                	li	a5,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002b86:	45c1                	li	a1,16
    80002b88:	a029                	j	80002b92 <nfua+0x26>
    80002b8a:	0741                	addi	a4,a4,16
    80002b8c:	2785                	addiw	a5,a5,1
    80002b8e:	00b78863          	beq	a5,a1,80002b9e <nfua+0x32>
    if(ram_pg->age <= min_age){
    80002b92:	4714                	lw	a3,8(a4)
    80002b94:	fed66be3          	bltu	a2,a3,80002b8a <nfua+0x1e>
      min_index = i;
      min_age = ram_pg->age;
    80002b98:	8636                	mv	a2,a3
    if(ram_pg->age <= min_age){
    80002b9a:	853e                	mv	a0,a5
    80002b9c:	b7fd                	j	80002b8a <nfua+0x1e>
    }
  }
  return min_index;
}
    80002b9e:	60a2                	ld	ra,8(sp)
    80002ba0:	6402                	ld	s0,0(sp)
    80002ba2:	0141                	addi	sp,sp,16
    80002ba4:	8082                	ret

0000000080002ba6 <count_ones>:

int count_ones(uint num) 
{
    80002ba6:	1141                	addi	sp,sp,-16
    80002ba8:	e422                	sd	s0,8(sp)
    80002baa:	0800                	addi	s0,sp,16
  int count = 0;
  while(num > 0){
    80002bac:	c105                	beqz	a0,80002bcc <count_ones+0x26>
    80002bae:	87aa                	mv	a5,a0
  int count = 0;
    80002bb0:	4501                	li	a0,0
  while(num > 0){
    80002bb2:	4685                	li	a3,1
    int cur_lsb = num % 2;
    80002bb4:	0017f713          	andi	a4,a5,1
    count += cur_lsb;
    80002bb8:	9d39                	addw	a0,a0,a4
    num = num / 2; 
    80002bba:	0007871b          	sext.w	a4,a5
    80002bbe:	0017d79b          	srliw	a5,a5,0x1
  while(num > 0){
    80002bc2:	fee6e9e3          	bltu	a3,a4,80002bb4 <count_ones+0xe>
  }
  return count;
}
    80002bc6:	6422                	ld	s0,8(sp)
    80002bc8:	0141                	addi	sp,sp,16
    80002bca:	8082                	ret
  int count = 0;
    80002bcc:	4501                	li	a0,0
    80002bce:	bfe5                	j	80002bc6 <count_ones+0x20>

0000000080002bd0 <lapa>:

int lapa()
{
    80002bd0:	715d                	addi	sp,sp,-80
    80002bd2:	e486                	sd	ra,72(sp)
    80002bd4:	e0a2                	sd	s0,64(sp)
    80002bd6:	fc26                	sd	s1,56(sp)
    80002bd8:	f84a                	sd	s2,48(sp)
    80002bda:	f44e                	sd	s3,40(sp)
    80002bdc:	f052                	sd	s4,32(sp)
    80002bde:	ec56                	sd	s5,24(sp)
    80002be0:	e85a                	sd	s6,16(sp)
    80002be2:	e45e                	sd	s7,8(sp)
    80002be4:	0880                	addi	s0,sp,80
  int i = 0;
  int min_index = 0;
  uint min_age = 0xFFFFFFFF;
  struct proc *p = myproc();
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	dee080e7          	jalr	-530(ra) # 800019d4 <myproc>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bee:	17050993          	addi	s3,a0,368
  uint min_age = 0xFFFFFFFF;
    80002bf2:	5afd                	li	s5,-1
  int min_index = 0;
    80002bf4:	4b81                	li	s7,0
  int i = 0;
    80002bf6:	4901                	li	s2,0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002bf8:	4b41                	li	s6,16
    80002bfa:	a039                	j	80002c08 <lapa+0x38>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    int min_age_ones = count_ones(min_age);
    if (ram_pg_age_ones < min_age_ones) {
      min_index = i;
      min_age = ram_pg->age;
    80002bfc:	8ad2                	mv	s5,s4
    80002bfe:	8bca                	mv	s7,s2
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++, i++){
    80002c00:	09c1                	addi	s3,s3,16
    80002c02:	2905                	addiw	s2,s2,1
    80002c04:	03690863          	beq	s2,s6,80002c34 <lapa+0x64>
    int ram_pg_age_ones = count_ones(ram_pg->age);
    80002c08:	0089aa03          	lw	s4,8(s3)
    80002c0c:	8552                	mv	a0,s4
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	f98080e7          	jalr	-104(ra) # 80002ba6 <count_ones>
    80002c16:	84aa                	mv	s1,a0
    int min_age_ones = count_ones(min_age);
    80002c18:	8556                	mv	a0,s5
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	f8c080e7          	jalr	-116(ra) # 80002ba6 <count_ones>
    if (ram_pg_age_ones < min_age_ones) {
    80002c22:	fca4cde3          	blt	s1,a0,80002bfc <lapa+0x2c>
    }
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c26:	fca49de3          	bne	s1,a0,80002c00 <lapa+0x30>
    80002c2a:	fd5a7be3          	bgeu	s4,s5,80002c00 <lapa+0x30>
      min_index = i;
      min_age = ram_pg->age;
    80002c2e:	8ad2                	mv	s5,s4
    if (ram_pg_age_ones == min_age_ones && ram_pg->age < min_age) {
    80002c30:	8bca                	mv	s7,s2
    80002c32:	b7f9                	j	80002c00 <lapa+0x30>
    }
  }
  return min_index;
}
    80002c34:	855e                	mv	a0,s7
    80002c36:	60a6                	ld	ra,72(sp)
    80002c38:	6406                	ld	s0,64(sp)
    80002c3a:	74e2                	ld	s1,56(sp)
    80002c3c:	7942                	ld	s2,48(sp)
    80002c3e:	79a2                	ld	s3,40(sp)
    80002c40:	7a02                	ld	s4,32(sp)
    80002c42:	6ae2                	ld	s5,24(sp)
    80002c44:	6b42                	ld	s6,16(sp)
    80002c46:	6ba2                	ld	s7,8(sp)
    80002c48:	6161                	addi	sp,sp,80
    80002c4a:	8082                	ret

0000000080002c4c <scfifo>:

int scfifo()
{
    80002c4c:	1101                	addi	sp,sp,-32
    80002c4e:	ec06                	sd	ra,24(sp)
    80002c50:	e822                	sd	s0,16(sp)
    80002c52:	e426                	sd	s1,8(sp)
    80002c54:	e04a                	sd	s2,0(sp)
    80002c56:	1000                	addi	s0,sp,32
  struct ram_page *cur_ram_pg;
  struct proc *p = myproc();
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	d7c080e7          	jalr	-644(ra) # 800019d4 <myproc>
    80002c60:	892a                	mv	s2,a0
  int index = p->scfifo_index;
    80002c62:	37052483          	lw	s1,880(a0)
  while(1){
    cur_ram_pg = &p->ram_pages[index];

    pte_t *pte;
    if ((pte = walk(p->pagetable, cur_ram_pg->va, 0)) == 0) {
    80002c66:	01748793          	addi	a5,s1,23
    80002c6a:	0792                	slli	a5,a5,0x4
    80002c6c:	97ca                	add	a5,a5,s2
    80002c6e:	4601                	li	a2,0
    80002c70:	638c                	ld	a1,0(a5)
    80002c72:	05093503          	ld	a0,80(s2)
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	330080e7          	jalr	816(ra) # 80000fa6 <walk>
    80002c7e:	c10d                	beqz	a0,80002ca0 <scfifo+0x54>
      panic("scfifo: walk failed");
    }
    
    if(*pte & PTE_A){
    80002c80:	611c                	ld	a5,0(a0)
    80002c82:	0407f713          	andi	a4,a5,64
    80002c86:	c70d                	beqz	a4,80002cb0 <scfifo+0x64>
      *pte = *pte & ~PTE_A;
    80002c88:	fbf7f793          	andi	a5,a5,-65
    80002c8c:	e11c                	sd	a5,0(a0)
      index = (index + 1) % MAX_PSYC_PAGES;
    80002c8e:	2485                	addiw	s1,s1,1
    80002c90:	41f4d79b          	sraiw	a5,s1,0x1f
    80002c94:	01c7d79b          	srliw	a5,a5,0x1c
    80002c98:	9cbd                	addw	s1,s1,a5
    80002c9a:	88bd                	andi	s1,s1,15
    80002c9c:	9c9d                	subw	s1,s1,a5
  while(1){
    80002c9e:	b7e1                	j	80002c66 <scfifo+0x1a>
      panic("scfifo: walk failed");
    80002ca0:	00006517          	auipc	a0,0x6
    80002ca4:	87050513          	addi	a0,a0,-1936 # 80008510 <digits+0x4d0>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	882080e7          	jalr	-1918(ra) # 8000052a <panic>
    }
    else{
      p->scfifo_index = (index + 1) % MAX_PSYC_PAGES;
    80002cb0:	0014879b          	addiw	a5,s1,1
    80002cb4:	41f7d71b          	sraiw	a4,a5,0x1f
    80002cb8:	01c7571b          	srliw	a4,a4,0x1c
    80002cbc:	9fb9                	addw	a5,a5,a4
    80002cbe:	8bbd                	andi	a5,a5,15
    80002cc0:	9f99                	subw	a5,a5,a4
    80002cc2:	36f92823          	sw	a5,880(s2)
      return index;
    }
  }
}
    80002cc6:	8526                	mv	a0,s1
    80002cc8:	60e2                	ld	ra,24(sp)
    80002cca:	6442                	ld	s0,16(sp)
    80002ccc:	64a2                	ld	s1,8(sp)
    80002cce:	6902                	ld	s2,0(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret

0000000080002cd4 <index_page_to_swap>:

int index_page_to_swap()
{
    80002cd4:	1141                	addi	sp,sp,-16
    80002cd6:	e422                	sd	s0,8(sp)
    80002cd8:	0800                	addi	s0,sp,16

  #ifdef NONE
    return -1;
  #endif
  return -1;
}
    80002cda:	557d                	li	a0,-1
    80002cdc:	6422                	ld	s0,8(sp)
    80002cde:	0141                	addi	sp,sp,16
    80002ce0:	8082                	ret

0000000080002ce2 <maintain_age>:

void maintain_age(struct proc *p){
    80002ce2:	7179                	addi	sp,sp,-48
    80002ce4:	f406                	sd	ra,40(sp)
    80002ce6:	f022                	sd	s0,32(sp)
    80002ce8:	ec26                	sd	s1,24(sp)
    80002cea:	e84a                	sd	s2,16(sp)
    80002cec:	e44e                	sd	s3,8(sp)
    80002cee:	e052                	sd	s4,0(sp)
    80002cf0:	1800                	addi	s0,sp,48
    80002cf2:	892a                	mv	s2,a0
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002cf4:	17050493          	addi	s1,a0,368
    80002cf8:	27050993          	addi	s3,a0,624
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
      panic("maintain_age: walk failed");
    }
    ram_pg->age = (ram_pg->age >> 1);
    if (*pte & PTE_A){
      ram_pg->age = ram_pg->age | (1 << 31);
    80002cfc:	80000a37          	lui	s4,0x80000
    80002d00:	a821                	j	80002d18 <maintain_age+0x36>
      panic("maintain_age: walk failed");
    80002d02:	00006517          	auipc	a0,0x6
    80002d06:	82650513          	addi	a0,a0,-2010 # 80008528 <digits+0x4e8>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	820080e7          	jalr	-2016(ra) # 8000052a <panic>
  for(struct ram_page *ram_pg = p->ram_pages; ram_pg < &p->ram_pages[MAX_PSYC_PAGES]; ram_pg++){
    80002d12:	04c1                	addi	s1,s1,16
    80002d14:	02998b63          	beq	s3,s1,80002d4a <maintain_age+0x68>
    if ((pte = walk(p->pagetable, ram_pg->va, 0)) == 0) {
    80002d18:	4601                	li	a2,0
    80002d1a:	608c                	ld	a1,0(s1)
    80002d1c:	05093503          	ld	a0,80(s2)
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	286080e7          	jalr	646(ra) # 80000fa6 <walk>
    80002d28:	dd69                	beqz	a0,80002d02 <maintain_age+0x20>
    ram_pg->age = (ram_pg->age >> 1);
    80002d2a:	449c                	lw	a5,8(s1)
    80002d2c:	0017d79b          	srliw	a5,a5,0x1
    80002d30:	c49c                	sw	a5,8(s1)
    if (*pte & PTE_A){
    80002d32:	6118                	ld	a4,0(a0)
    80002d34:	04077713          	andi	a4,a4,64
    80002d38:	df69                	beqz	a4,80002d12 <maintain_age+0x30>
      ram_pg->age = ram_pg->age | (1 << 31);
    80002d3a:	0147e7b3          	or	a5,a5,s4
    80002d3e:	c49c                	sw	a5,8(s1)
      *pte = *pte & ~PTE_A;
    80002d40:	611c                	ld	a5,0(a0)
    80002d42:	fbf7f793          	andi	a5,a5,-65
    80002d46:	e11c                	sd	a5,0(a0)
    80002d48:	b7e9                	j	80002d12 <maintain_age+0x30>
    }
  }
    80002d4a:	70a2                	ld	ra,40(sp)
    80002d4c:	7402                	ld	s0,32(sp)
    80002d4e:	64e2                	ld	s1,24(sp)
    80002d50:	6942                	ld	s2,16(sp)
    80002d52:	69a2                	ld	s3,8(sp)
    80002d54:	6a02                	ld	s4,0(sp)
    80002d56:	6145                	addi	sp,sp,48
    80002d58:	8082                	ret

0000000080002d5a <swtch>:
    80002d5a:	00153023          	sd	ra,0(a0)
    80002d5e:	00253423          	sd	sp,8(a0)
    80002d62:	e900                	sd	s0,16(a0)
    80002d64:	ed04                	sd	s1,24(a0)
    80002d66:	03253023          	sd	s2,32(a0)
    80002d6a:	03353423          	sd	s3,40(a0)
    80002d6e:	03453823          	sd	s4,48(a0)
    80002d72:	03553c23          	sd	s5,56(a0)
    80002d76:	05653023          	sd	s6,64(a0)
    80002d7a:	05753423          	sd	s7,72(a0)
    80002d7e:	05853823          	sd	s8,80(a0)
    80002d82:	05953c23          	sd	s9,88(a0)
    80002d86:	07a53023          	sd	s10,96(a0)
    80002d8a:	07b53423          	sd	s11,104(a0)
    80002d8e:	0005b083          	ld	ra,0(a1) # fffffffffffff000 <end+0xffffffff7ffd1000>
    80002d92:	0085b103          	ld	sp,8(a1)
    80002d96:	6980                	ld	s0,16(a1)
    80002d98:	6d84                	ld	s1,24(a1)
    80002d9a:	0205b903          	ld	s2,32(a1)
    80002d9e:	0285b983          	ld	s3,40(a1)
    80002da2:	0305ba03          	ld	s4,48(a1)
    80002da6:	0385ba83          	ld	s5,56(a1)
    80002daa:	0405bb03          	ld	s6,64(a1)
    80002dae:	0485bb83          	ld	s7,72(a1)
    80002db2:	0505bc03          	ld	s8,80(a1)
    80002db6:	0585bc83          	ld	s9,88(a1)
    80002dba:	0605bd03          	ld	s10,96(a1)
    80002dbe:	0685bd83          	ld	s11,104(a1)
    80002dc2:	8082                	ret

0000000080002dc4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002dc4:	1141                	addi	sp,sp,-16
    80002dc6:	e406                	sd	ra,8(sp)
    80002dc8:	e022                	sd	s0,0(sp)
    80002dca:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002dcc:	00005597          	auipc	a1,0x5
    80002dd0:	7d458593          	addi	a1,a1,2004 # 800085a0 <states.0+0x30>
    80002dd4:	0001c517          	auipc	a0,0x1c
    80002dd8:	6fc50513          	addi	a0,a0,1788 # 8001f4d0 <tickslock>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	d56080e7          	jalr	-682(ra) # 80000b32 <initlock>
}
    80002de4:	60a2                	ld	ra,8(sp)
    80002de6:	6402                	ld	s0,0(sp)
    80002de8:	0141                	addi	sp,sp,16
    80002dea:	8082                	ret

0000000080002dec <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002dec:	1141                	addi	sp,sp,-16
    80002dee:	e422                	sd	s0,8(sp)
    80002df0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002df2:	00004797          	auipc	a5,0x4
    80002df6:	a8e78793          	addi	a5,a5,-1394 # 80006880 <kernelvec>
    80002dfa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002dfe:	6422                	ld	s0,8(sp)
    80002e00:	0141                	addi	sp,sp,16
    80002e02:	8082                	ret

0000000080002e04 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e04:	1141                	addi	sp,sp,-16
    80002e06:	e406                	sd	ra,8(sp)
    80002e08:	e022                	sd	s0,0(sp)
    80002e0a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	bc8080e7          	jalr	-1080(ra) # 800019d4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e14:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e18:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e1a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e1e:	00004617          	auipc	a2,0x4
    80002e22:	1e260613          	addi	a2,a2,482 # 80007000 <_trampoline>
    80002e26:	00004697          	auipc	a3,0x4
    80002e2a:	1da68693          	addi	a3,a3,474 # 80007000 <_trampoline>
    80002e2e:	8e91                	sub	a3,a3,a2
    80002e30:	040007b7          	lui	a5,0x4000
    80002e34:	17fd                	addi	a5,a5,-1
    80002e36:	07b2                	slli	a5,a5,0xc
    80002e38:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e3a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e3e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e40:	180026f3          	csrr	a3,satp
    80002e44:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e46:	6d38                	ld	a4,88(a0)
    80002e48:	6134                	ld	a3,64(a0)
    80002e4a:	6585                	lui	a1,0x1
    80002e4c:	96ae                	add	a3,a3,a1
    80002e4e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e50:	6d38                	ld	a4,88(a0)
    80002e52:	00000697          	auipc	a3,0x0
    80002e56:	13868693          	addi	a3,a3,312 # 80002f8a <usertrap>
    80002e5a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e5c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e5e:	8692                	mv	a3,tp
    80002e60:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e62:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e66:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e6a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e6e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e72:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e74:	6f18                	ld	a4,24(a4)
    80002e76:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e7a:	692c                	ld	a1,80(a0)
    80002e7c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002e7e:	00004717          	auipc	a4,0x4
    80002e82:	21270713          	addi	a4,a4,530 # 80007090 <userret>
    80002e86:	8f11                	sub	a4,a4,a2
    80002e88:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002e8a:	577d                	li	a4,-1
    80002e8c:	177e                	slli	a4,a4,0x3f
    80002e8e:	8dd9                	or	a1,a1,a4
    80002e90:	02000537          	lui	a0,0x2000
    80002e94:	157d                	addi	a0,a0,-1
    80002e96:	0536                	slli	a0,a0,0xd
    80002e98:	9782                	jalr	a5
}
    80002e9a:	60a2                	ld	ra,8(sp)
    80002e9c:	6402                	ld	s0,0(sp)
    80002e9e:	0141                	addi	sp,sp,16
    80002ea0:	8082                	ret

0000000080002ea2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ea2:	1101                	addi	sp,sp,-32
    80002ea4:	ec06                	sd	ra,24(sp)
    80002ea6:	e822                	sd	s0,16(sp)
    80002ea8:	e426                	sd	s1,8(sp)
    80002eaa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002eac:	0001c497          	auipc	s1,0x1c
    80002eb0:	62448493          	addi	s1,s1,1572 # 8001f4d0 <tickslock>
    80002eb4:	8526                	mv	a0,s1
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	d0c080e7          	jalr	-756(ra) # 80000bc2 <acquire>
  ticks++;
    80002ebe:	00006517          	auipc	a0,0x6
    80002ec2:	17250513          	addi	a0,a0,370 # 80009030 <ticks>
    80002ec6:	411c                	lw	a5,0(a0)
    80002ec8:	2785                	addiw	a5,a5,1
    80002eca:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	1fa080e7          	jalr	506(ra) # 800020c6 <wakeup>
  release(&tickslock);
    80002ed4:	8526                	mv	a0,s1
    80002ed6:	ffffe097          	auipc	ra,0xffffe
    80002eda:	da0080e7          	jalr	-608(ra) # 80000c76 <release>
}
    80002ede:	60e2                	ld	ra,24(sp)
    80002ee0:	6442                	ld	s0,16(sp)
    80002ee2:	64a2                	ld	s1,8(sp)
    80002ee4:	6105                	addi	sp,sp,32
    80002ee6:	8082                	ret

0000000080002ee8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ee8:	1101                	addi	sp,sp,-32
    80002eea:	ec06                	sd	ra,24(sp)
    80002eec:	e822                	sd	s0,16(sp)
    80002eee:	e426                	sd	s1,8(sp)
    80002ef0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ef2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ef6:	00074d63          	bltz	a4,80002f10 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002efa:	57fd                	li	a5,-1
    80002efc:	17fe                	slli	a5,a5,0x3f
    80002efe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f00:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f02:	06f70363          	beq	a4,a5,80002f68 <devintr+0x80>
  }
}
    80002f06:	60e2                	ld	ra,24(sp)
    80002f08:	6442                	ld	s0,16(sp)
    80002f0a:	64a2                	ld	s1,8(sp)
    80002f0c:	6105                	addi	sp,sp,32
    80002f0e:	8082                	ret
     (scause & 0xff) == 9){
    80002f10:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f14:	46a5                	li	a3,9
    80002f16:	fed792e3          	bne	a5,a3,80002efa <devintr+0x12>
    int irq = plic_claim();
    80002f1a:	00004097          	auipc	ra,0x4
    80002f1e:	a6e080e7          	jalr	-1426(ra) # 80006988 <plic_claim>
    80002f22:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f24:	47a9                	li	a5,10
    80002f26:	02f50763          	beq	a0,a5,80002f54 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f2a:	4785                	li	a5,1
    80002f2c:	02f50963          	beq	a0,a5,80002f5e <devintr+0x76>
    return 1;
    80002f30:	4505                	li	a0,1
    } else if(irq){
    80002f32:	d8f1                	beqz	s1,80002f06 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f34:	85a6                	mv	a1,s1
    80002f36:	00005517          	auipc	a0,0x5
    80002f3a:	67250513          	addi	a0,a0,1650 # 800085a8 <states.0+0x38>
    80002f3e:	ffffd097          	auipc	ra,0xffffd
    80002f42:	636080e7          	jalr	1590(ra) # 80000574 <printf>
      plic_complete(irq);
    80002f46:	8526                	mv	a0,s1
    80002f48:	00004097          	auipc	ra,0x4
    80002f4c:	a64080e7          	jalr	-1436(ra) # 800069ac <plic_complete>
    return 1;
    80002f50:	4505                	li	a0,1
    80002f52:	bf55                	j	80002f06 <devintr+0x1e>
      uartintr();
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	a32080e7          	jalr	-1486(ra) # 80000986 <uartintr>
    80002f5c:	b7ed                	j	80002f46 <devintr+0x5e>
      virtio_disk_intr();
    80002f5e:	00004097          	auipc	ra,0x4
    80002f62:	ee0080e7          	jalr	-288(ra) # 80006e3e <virtio_disk_intr>
    80002f66:	b7c5                	j	80002f46 <devintr+0x5e>
    if(cpuid() == 0){
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	a40080e7          	jalr	-1472(ra) # 800019a8 <cpuid>
    80002f70:	c901                	beqz	a0,80002f80 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f72:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f76:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f78:	14479073          	csrw	sip,a5
    return 2;
    80002f7c:	4509                	li	a0,2
    80002f7e:	b761                	j	80002f06 <devintr+0x1e>
      clockintr();
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	f22080e7          	jalr	-222(ra) # 80002ea2 <clockintr>
    80002f88:	b7ed                	j	80002f72 <devintr+0x8a>

0000000080002f8a <usertrap>:
{
    80002f8a:	1101                	addi	sp,sp,-32
    80002f8c:	ec06                	sd	ra,24(sp)
    80002f8e:	e822                	sd	s0,16(sp)
    80002f90:	e426                	sd	s1,8(sp)
    80002f92:	e04a                	sd	s2,0(sp)
    80002f94:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f96:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002f9a:	1007f793          	andi	a5,a5,256
    80002f9e:	e3ad                	bnez	a5,80003000 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fa0:	00004797          	auipc	a5,0x4
    80002fa4:	8e078793          	addi	a5,a5,-1824 # 80006880 <kernelvec>
    80002fa8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	a28080e7          	jalr	-1496(ra) # 800019d4 <myproc>
    80002fb4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002fb6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fb8:	14102773          	csrr	a4,sepc
    80002fbc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fbe:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002fc2:	47a1                	li	a5,8
    80002fc4:	04f71c63          	bne	a4,a5,8000301c <usertrap+0x92>
    if(p->killed)
    80002fc8:	551c                	lw	a5,40(a0)
    80002fca:	e3b9                	bnez	a5,80003010 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002fcc:	6cb8                	ld	a4,88(s1)
    80002fce:	6f1c                	ld	a5,24(a4)
    80002fd0:	0791                	addi	a5,a5,4
    80002fd2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fd8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fdc:	10079073          	csrw	sstatus,a5
    syscall();
    80002fe0:	00000097          	auipc	ra,0x0
    80002fe4:	2e0080e7          	jalr	736(ra) # 800032c0 <syscall>
  if(p->killed)
    80002fe8:	549c                	lw	a5,40(s1)
    80002fea:	ebc1                	bnez	a5,8000307a <usertrap+0xf0>
  usertrapret();
    80002fec:	00000097          	auipc	ra,0x0
    80002ff0:	e18080e7          	jalr	-488(ra) # 80002e04 <usertrapret>
}
    80002ff4:	60e2                	ld	ra,24(sp)
    80002ff6:	6442                	ld	s0,16(sp)
    80002ff8:	64a2                	ld	s1,8(sp)
    80002ffa:	6902                	ld	s2,0(sp)
    80002ffc:	6105                	addi	sp,sp,32
    80002ffe:	8082                	ret
    panic("usertrap: not from user mode");
    80003000:	00005517          	auipc	a0,0x5
    80003004:	5c850513          	addi	a0,a0,1480 # 800085c8 <states.0+0x58>
    80003008:	ffffd097          	auipc	ra,0xffffd
    8000300c:	522080e7          	jalr	1314(ra) # 8000052a <panic>
      exit(-1);
    80003010:	557d                	li	a0,-1
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	56e080e7          	jalr	1390(ra) # 80002580 <exit>
    8000301a:	bf4d                	j	80002fcc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000301c:	00000097          	auipc	ra,0x0
    80003020:	ecc080e7          	jalr	-308(ra) # 80002ee8 <devintr>
    80003024:	892a                	mv	s2,a0
    80003026:	c501                	beqz	a0,8000302e <usertrap+0xa4>
  if(p->killed)
    80003028:	549c                	lw	a5,40(s1)
    8000302a:	c3a1                	beqz	a5,8000306a <usertrap+0xe0>
    8000302c:	a815                	j	80003060 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000302e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003032:	5890                	lw	a2,48(s1)
    80003034:	00005517          	auipc	a0,0x5
    80003038:	5b450513          	addi	a0,a0,1460 # 800085e8 <states.0+0x78>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	538080e7          	jalr	1336(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003044:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003048:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000304c:	00005517          	auipc	a0,0x5
    80003050:	5cc50513          	addi	a0,a0,1484 # 80008618 <states.0+0xa8>
    80003054:	ffffd097          	auipc	ra,0xffffd
    80003058:	520080e7          	jalr	1312(ra) # 80000574 <printf>
    p->killed = 1;
    8000305c:	4785                	li	a5,1
    8000305e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003060:	557d                	li	a0,-1
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	51e080e7          	jalr	1310(ra) # 80002580 <exit>
  if(which_dev == 2)
    8000306a:	4789                	li	a5,2
    8000306c:	f8f910e3          	bne	s2,a5,80002fec <usertrap+0x62>
    yield();
    80003070:	fffff097          	auipc	ra,0xfffff
    80003074:	fb6080e7          	jalr	-74(ra) # 80002026 <yield>
    80003078:	bf95                	j	80002fec <usertrap+0x62>
  int which_dev = 0;
    8000307a:	4901                	li	s2,0
    8000307c:	b7d5                	j	80003060 <usertrap+0xd6>

000000008000307e <kerneltrap>:
{
    8000307e:	7179                	addi	sp,sp,-48
    80003080:	f406                	sd	ra,40(sp)
    80003082:	f022                	sd	s0,32(sp)
    80003084:	ec26                	sd	s1,24(sp)
    80003086:	e84a                	sd	s2,16(sp)
    80003088:	e44e                	sd	s3,8(sp)
    8000308a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000308c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003090:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003094:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003098:	1004f793          	andi	a5,s1,256
    8000309c:	cb85                	beqz	a5,800030cc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000309e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030a2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800030a4:	ef85                	bnez	a5,800030dc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800030a6:	00000097          	auipc	ra,0x0
    800030aa:	e42080e7          	jalr	-446(ra) # 80002ee8 <devintr>
    800030ae:	cd1d                	beqz	a0,800030ec <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030b0:	4789                	li	a5,2
    800030b2:	06f50a63          	beq	a0,a5,80003126 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030b6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030ba:	10049073          	csrw	sstatus,s1
}
    800030be:	70a2                	ld	ra,40(sp)
    800030c0:	7402                	ld	s0,32(sp)
    800030c2:	64e2                	ld	s1,24(sp)
    800030c4:	6942                	ld	s2,16(sp)
    800030c6:	69a2                	ld	s3,8(sp)
    800030c8:	6145                	addi	sp,sp,48
    800030ca:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030cc:	00005517          	auipc	a0,0x5
    800030d0:	56c50513          	addi	a0,a0,1388 # 80008638 <states.0+0xc8>
    800030d4:	ffffd097          	auipc	ra,0xffffd
    800030d8:	456080e7          	jalr	1110(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800030dc:	00005517          	auipc	a0,0x5
    800030e0:	58450513          	addi	a0,a0,1412 # 80008660 <states.0+0xf0>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	446080e7          	jalr	1094(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800030ec:	85ce                	mv	a1,s3
    800030ee:	00005517          	auipc	a0,0x5
    800030f2:	59250513          	addi	a0,a0,1426 # 80008680 <states.0+0x110>
    800030f6:	ffffd097          	auipc	ra,0xffffd
    800030fa:	47e080e7          	jalr	1150(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030fe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003102:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003106:	00005517          	auipc	a0,0x5
    8000310a:	58a50513          	addi	a0,a0,1418 # 80008690 <states.0+0x120>
    8000310e:	ffffd097          	auipc	ra,0xffffd
    80003112:	466080e7          	jalr	1126(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003116:	00005517          	auipc	a0,0x5
    8000311a:	59250513          	addi	a0,a0,1426 # 800086a8 <states.0+0x138>
    8000311e:	ffffd097          	auipc	ra,0xffffd
    80003122:	40c080e7          	jalr	1036(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003126:	fffff097          	auipc	ra,0xfffff
    8000312a:	8ae080e7          	jalr	-1874(ra) # 800019d4 <myproc>
    8000312e:	d541                	beqz	a0,800030b6 <kerneltrap+0x38>
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	8a4080e7          	jalr	-1884(ra) # 800019d4 <myproc>
    80003138:	4d18                	lw	a4,24(a0)
    8000313a:	4791                	li	a5,4
    8000313c:	f6f71de3          	bne	a4,a5,800030b6 <kerneltrap+0x38>
    yield();
    80003140:	fffff097          	auipc	ra,0xfffff
    80003144:	ee6080e7          	jalr	-282(ra) # 80002026 <yield>
    80003148:	b7bd                	j	800030b6 <kerneltrap+0x38>

000000008000314a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000314a:	1101                	addi	sp,sp,-32
    8000314c:	ec06                	sd	ra,24(sp)
    8000314e:	e822                	sd	s0,16(sp)
    80003150:	e426                	sd	s1,8(sp)
    80003152:	1000                	addi	s0,sp,32
    80003154:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	87e080e7          	jalr	-1922(ra) # 800019d4 <myproc>
  switch (n) {
    8000315e:	4795                	li	a5,5
    80003160:	0497e163          	bltu	a5,s1,800031a2 <argraw+0x58>
    80003164:	048a                	slli	s1,s1,0x2
    80003166:	00005717          	auipc	a4,0x5
    8000316a:	57a70713          	addi	a4,a4,1402 # 800086e0 <states.0+0x170>
    8000316e:	94ba                	add	s1,s1,a4
    80003170:	409c                	lw	a5,0(s1)
    80003172:	97ba                	add	a5,a5,a4
    80003174:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003176:	6d3c                	ld	a5,88(a0)
    80003178:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret
    return p->trapframe->a1;
    80003184:	6d3c                	ld	a5,88(a0)
    80003186:	7fa8                	ld	a0,120(a5)
    80003188:	bfcd                	j	8000317a <argraw+0x30>
    return p->trapframe->a2;
    8000318a:	6d3c                	ld	a5,88(a0)
    8000318c:	63c8                	ld	a0,128(a5)
    8000318e:	b7f5                	j	8000317a <argraw+0x30>
    return p->trapframe->a3;
    80003190:	6d3c                	ld	a5,88(a0)
    80003192:	67c8                	ld	a0,136(a5)
    80003194:	b7dd                	j	8000317a <argraw+0x30>
    return p->trapframe->a4;
    80003196:	6d3c                	ld	a5,88(a0)
    80003198:	6bc8                	ld	a0,144(a5)
    8000319a:	b7c5                	j	8000317a <argraw+0x30>
    return p->trapframe->a5;
    8000319c:	6d3c                	ld	a5,88(a0)
    8000319e:	6fc8                	ld	a0,152(a5)
    800031a0:	bfe9                	j	8000317a <argraw+0x30>
  panic("argraw");
    800031a2:	00005517          	auipc	a0,0x5
    800031a6:	51650513          	addi	a0,a0,1302 # 800086b8 <states.0+0x148>
    800031aa:	ffffd097          	auipc	ra,0xffffd
    800031ae:	380080e7          	jalr	896(ra) # 8000052a <panic>

00000000800031b2 <fetchaddr>:
{
    800031b2:	1101                	addi	sp,sp,-32
    800031b4:	ec06                	sd	ra,24(sp)
    800031b6:	e822                	sd	s0,16(sp)
    800031b8:	e426                	sd	s1,8(sp)
    800031ba:	e04a                	sd	s2,0(sp)
    800031bc:	1000                	addi	s0,sp,32
    800031be:	84aa                	mv	s1,a0
    800031c0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031c2:	fffff097          	auipc	ra,0xfffff
    800031c6:	812080e7          	jalr	-2030(ra) # 800019d4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031ca:	653c                	ld	a5,72(a0)
    800031cc:	02f4f863          	bgeu	s1,a5,800031fc <fetchaddr+0x4a>
    800031d0:	00848713          	addi	a4,s1,8
    800031d4:	02e7e663          	bltu	a5,a4,80003200 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031d8:	46a1                	li	a3,8
    800031da:	8626                	mv	a2,s1
    800031dc:	85ca                	mv	a1,s2
    800031de:	6928                	ld	a0,80(a0)
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	540080e7          	jalr	1344(ra) # 80001720 <copyin>
    800031e8:	00a03533          	snez	a0,a0
    800031ec:	40a00533          	neg	a0,a0
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6902                	ld	s2,0(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret
    return -1;
    800031fc:	557d                	li	a0,-1
    800031fe:	bfcd                	j	800031f0 <fetchaddr+0x3e>
    80003200:	557d                	li	a0,-1
    80003202:	b7fd                	j	800031f0 <fetchaddr+0x3e>

0000000080003204 <fetchstr>:
{
    80003204:	7179                	addi	sp,sp,-48
    80003206:	f406                	sd	ra,40(sp)
    80003208:	f022                	sd	s0,32(sp)
    8000320a:	ec26                	sd	s1,24(sp)
    8000320c:	e84a                	sd	s2,16(sp)
    8000320e:	e44e                	sd	s3,8(sp)
    80003210:	1800                	addi	s0,sp,48
    80003212:	892a                	mv	s2,a0
    80003214:	84ae                	mv	s1,a1
    80003216:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	7bc080e7          	jalr	1980(ra) # 800019d4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003220:	86ce                	mv	a3,s3
    80003222:	864a                	mv	a2,s2
    80003224:	85a6                	mv	a1,s1
    80003226:	6928                	ld	a0,80(a0)
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	586080e7          	jalr	1414(ra) # 800017ae <copyinstr>
  if(err < 0)
    80003230:	00054763          	bltz	a0,8000323e <fetchstr+0x3a>
  return strlen(buf);
    80003234:	8526                	mv	a0,s1
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	c0c080e7          	jalr	-1012(ra) # 80000e42 <strlen>
}
    8000323e:	70a2                	ld	ra,40(sp)
    80003240:	7402                	ld	s0,32(sp)
    80003242:	64e2                	ld	s1,24(sp)
    80003244:	6942                	ld	s2,16(sp)
    80003246:	69a2                	ld	s3,8(sp)
    80003248:	6145                	addi	sp,sp,48
    8000324a:	8082                	ret

000000008000324c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000324c:	1101                	addi	sp,sp,-32
    8000324e:	ec06                	sd	ra,24(sp)
    80003250:	e822                	sd	s0,16(sp)
    80003252:	e426                	sd	s1,8(sp)
    80003254:	1000                	addi	s0,sp,32
    80003256:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	ef2080e7          	jalr	-270(ra) # 8000314a <argraw>
    80003260:	c088                	sw	a0,0(s1)
  return 0;
}
    80003262:	4501                	li	a0,0
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	64a2                	ld	s1,8(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret

000000008000326e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	e426                	sd	s1,8(sp)
    80003276:	1000                	addi	s0,sp,32
    80003278:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	ed0080e7          	jalr	-304(ra) # 8000314a <argraw>
    80003282:	e088                	sd	a0,0(s1)
  return 0;
}
    80003284:	4501                	li	a0,0
    80003286:	60e2                	ld	ra,24(sp)
    80003288:	6442                	ld	s0,16(sp)
    8000328a:	64a2                	ld	s1,8(sp)
    8000328c:	6105                	addi	sp,sp,32
    8000328e:	8082                	ret

0000000080003290 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003290:	1101                	addi	sp,sp,-32
    80003292:	ec06                	sd	ra,24(sp)
    80003294:	e822                	sd	s0,16(sp)
    80003296:	e426                	sd	s1,8(sp)
    80003298:	e04a                	sd	s2,0(sp)
    8000329a:	1000                	addi	s0,sp,32
    8000329c:	84ae                	mv	s1,a1
    8000329e:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	eaa080e7          	jalr	-342(ra) # 8000314a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032a8:	864a                	mv	a2,s2
    800032aa:	85a6                	mv	a1,s1
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	f58080e7          	jalr	-168(ra) # 80003204 <fetchstr>
}
    800032b4:	60e2                	ld	ra,24(sp)
    800032b6:	6442                	ld	s0,16(sp)
    800032b8:	64a2                	ld	s1,8(sp)
    800032ba:	6902                	ld	s2,0(sp)
    800032bc:	6105                	addi	sp,sp,32
    800032be:	8082                	ret

00000000800032c0 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800032c0:	1101                	addi	sp,sp,-32
    800032c2:	ec06                	sd	ra,24(sp)
    800032c4:	e822                	sd	s0,16(sp)
    800032c6:	e426                	sd	s1,8(sp)
    800032c8:	e04a                	sd	s2,0(sp)
    800032ca:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	708080e7          	jalr	1800(ra) # 800019d4 <myproc>
    800032d4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032d6:	05853903          	ld	s2,88(a0)
    800032da:	0a893783          	ld	a5,168(s2)
    800032de:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032e2:	37fd                	addiw	a5,a5,-1
    800032e4:	4751                	li	a4,20
    800032e6:	00f76f63          	bltu	a4,a5,80003304 <syscall+0x44>
    800032ea:	00369713          	slli	a4,a3,0x3
    800032ee:	00005797          	auipc	a5,0x5
    800032f2:	40a78793          	addi	a5,a5,1034 # 800086f8 <syscalls>
    800032f6:	97ba                	add	a5,a5,a4
    800032f8:	639c                	ld	a5,0(a5)
    800032fa:	c789                	beqz	a5,80003304 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800032fc:	9782                	jalr	a5
    800032fe:	06a93823          	sd	a0,112(s2)
    80003302:	a839                	j	80003320 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003304:	15848613          	addi	a2,s1,344
    80003308:	588c                	lw	a1,48(s1)
    8000330a:	00005517          	auipc	a0,0x5
    8000330e:	3b650513          	addi	a0,a0,950 # 800086c0 <states.0+0x150>
    80003312:	ffffd097          	auipc	ra,0xffffd
    80003316:	262080e7          	jalr	610(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000331a:	6cbc                	ld	a5,88(s1)
    8000331c:	577d                	li	a4,-1
    8000331e:	fbb8                	sd	a4,112(a5)
  }
}
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	64a2                	ld	s1,8(sp)
    80003326:	6902                	ld	s2,0(sp)
    80003328:	6105                	addi	sp,sp,32
    8000332a:	8082                	ret

000000008000332c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000332c:	1101                	addi	sp,sp,-32
    8000332e:	ec06                	sd	ra,24(sp)
    80003330:	e822                	sd	s0,16(sp)
    80003332:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003334:	fec40593          	addi	a1,s0,-20
    80003338:	4501                	li	a0,0
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	f12080e7          	jalr	-238(ra) # 8000324c <argint>
    return -1;
    80003342:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003344:	00054963          	bltz	a0,80003356 <sys_exit+0x2a>
  exit(n);
    80003348:	fec42503          	lw	a0,-20(s0)
    8000334c:	fffff097          	auipc	ra,0xfffff
    80003350:	234080e7          	jalr	564(ra) # 80002580 <exit>
  return 0;  // not reached
    80003354:	4781                	li	a5,0
}
    80003356:	853e                	mv	a0,a5
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret

0000000080003360 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003360:	1141                	addi	sp,sp,-16
    80003362:	e406                	sd	ra,8(sp)
    80003364:	e022                	sd	s0,0(sp)
    80003366:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	66c080e7          	jalr	1644(ra) # 800019d4 <myproc>
}
    80003370:	5908                	lw	a0,48(a0)
    80003372:	60a2                	ld	ra,8(sp)
    80003374:	6402                	ld	s0,0(sp)
    80003376:	0141                	addi	sp,sp,16
    80003378:	8082                	ret

000000008000337a <sys_fork>:

uint64
sys_fork(void)
{
    8000337a:	1141                	addi	sp,sp,-16
    8000337c:	e406                	sd	ra,8(sp)
    8000337e:	e022                	sd	s0,0(sp)
    80003380:	0800                	addi	s0,sp,16
  return fork();
    80003382:	fffff097          	auipc	ra,0xfffff
    80003386:	0be080e7          	jalr	190(ra) # 80002440 <fork>
}
    8000338a:	60a2                	ld	ra,8(sp)
    8000338c:	6402                	ld	s0,0(sp)
    8000338e:	0141                	addi	sp,sp,16
    80003390:	8082                	ret

0000000080003392 <sys_wait>:

uint64
sys_wait(void)
{
    80003392:	1101                	addi	sp,sp,-32
    80003394:	ec06                	sd	ra,24(sp)
    80003396:	e822                	sd	s0,16(sp)
    80003398:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000339a:	fe840593          	addi	a1,s0,-24
    8000339e:	4501                	li	a0,0
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	ece080e7          	jalr	-306(ra) # 8000326e <argaddr>
    800033a8:	87aa                	mv	a5,a0
    return -1;
    800033aa:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800033ac:	0007c863          	bltz	a5,800033bc <sys_wait+0x2a>
  return wait(p);
    800033b0:	fe843503          	ld	a0,-24(s0)
    800033b4:	fffff097          	auipc	ra,0xfffff
    800033b8:	2a2080e7          	jalr	674(ra) # 80002656 <wait>
}
    800033bc:	60e2                	ld	ra,24(sp)
    800033be:	6442                	ld	s0,16(sp)
    800033c0:	6105                	addi	sp,sp,32
    800033c2:	8082                	ret

00000000800033c4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033c4:	7179                	addi	sp,sp,-48
    800033c6:	f406                	sd	ra,40(sp)
    800033c8:	f022                	sd	s0,32(sp)
    800033ca:	ec26                	sd	s1,24(sp)
    800033cc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800033ce:	fdc40593          	addi	a1,s0,-36
    800033d2:	4501                	li	a0,0
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	e78080e7          	jalr	-392(ra) # 8000324c <argint>
    return -1;
    800033dc:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800033de:	00054f63          	bltz	a0,800033fc <sys_sbrk+0x38>
  addr = myproc()->sz;
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	5f2080e7          	jalr	1522(ra) # 800019d4 <myproc>
    800033ea:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800033ec:	fdc42503          	lw	a0,-36(s0)
    800033f0:	fffff097          	auipc	ra,0xfffff
    800033f4:	93e080e7          	jalr	-1730(ra) # 80001d2e <growproc>
    800033f8:	00054863          	bltz	a0,80003408 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800033fc:	8526                	mv	a0,s1
    800033fe:	70a2                	ld	ra,40(sp)
    80003400:	7402                	ld	s0,32(sp)
    80003402:	64e2                	ld	s1,24(sp)
    80003404:	6145                	addi	sp,sp,48
    80003406:	8082                	ret
    return -1;
    80003408:	54fd                	li	s1,-1
    8000340a:	bfcd                	j	800033fc <sys_sbrk+0x38>

000000008000340c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000340c:	7139                	addi	sp,sp,-64
    8000340e:	fc06                	sd	ra,56(sp)
    80003410:	f822                	sd	s0,48(sp)
    80003412:	f426                	sd	s1,40(sp)
    80003414:	f04a                	sd	s2,32(sp)
    80003416:	ec4e                	sd	s3,24(sp)
    80003418:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000341a:	fcc40593          	addi	a1,s0,-52
    8000341e:	4501                	li	a0,0
    80003420:	00000097          	auipc	ra,0x0
    80003424:	e2c080e7          	jalr	-468(ra) # 8000324c <argint>
    return -1;
    80003428:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000342a:	06054563          	bltz	a0,80003494 <sys_sleep+0x88>
  acquire(&tickslock);
    8000342e:	0001c517          	auipc	a0,0x1c
    80003432:	0a250513          	addi	a0,a0,162 # 8001f4d0 <tickslock>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	78c080e7          	jalr	1932(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000343e:	00006917          	auipc	s2,0x6
    80003442:	bf292903          	lw	s2,-1038(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003446:	fcc42783          	lw	a5,-52(s0)
    8000344a:	cf85                	beqz	a5,80003482 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000344c:	0001c997          	auipc	s3,0x1c
    80003450:	08498993          	addi	s3,s3,132 # 8001f4d0 <tickslock>
    80003454:	00006497          	auipc	s1,0x6
    80003458:	bdc48493          	addi	s1,s1,-1060 # 80009030 <ticks>
    if(myproc()->killed){
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	578080e7          	jalr	1400(ra) # 800019d4 <myproc>
    80003464:	551c                	lw	a5,40(a0)
    80003466:	ef9d                	bnez	a5,800034a4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003468:	85ce                	mv	a1,s3
    8000346a:	8526                	mv	a0,s1
    8000346c:	fffff097          	auipc	ra,0xfffff
    80003470:	bf6080e7          	jalr	-1034(ra) # 80002062 <sleep>
  while(ticks - ticks0 < n){
    80003474:	409c                	lw	a5,0(s1)
    80003476:	412787bb          	subw	a5,a5,s2
    8000347a:	fcc42703          	lw	a4,-52(s0)
    8000347e:	fce7efe3          	bltu	a5,a4,8000345c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003482:	0001c517          	auipc	a0,0x1c
    80003486:	04e50513          	addi	a0,a0,78 # 8001f4d0 <tickslock>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	7ec080e7          	jalr	2028(ra) # 80000c76 <release>
  return 0;
    80003492:	4781                	li	a5,0
}
    80003494:	853e                	mv	a0,a5
    80003496:	70e2                	ld	ra,56(sp)
    80003498:	7442                	ld	s0,48(sp)
    8000349a:	74a2                	ld	s1,40(sp)
    8000349c:	7902                	ld	s2,32(sp)
    8000349e:	69e2                	ld	s3,24(sp)
    800034a0:	6121                	addi	sp,sp,64
    800034a2:	8082                	ret
      release(&tickslock);
    800034a4:	0001c517          	auipc	a0,0x1c
    800034a8:	02c50513          	addi	a0,a0,44 # 8001f4d0 <tickslock>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	7ca080e7          	jalr	1994(ra) # 80000c76 <release>
      return -1;
    800034b4:	57fd                	li	a5,-1
    800034b6:	bff9                	j	80003494 <sys_sleep+0x88>

00000000800034b8 <sys_kill>:

uint64
sys_kill(void)
{
    800034b8:	1101                	addi	sp,sp,-32
    800034ba:	ec06                	sd	ra,24(sp)
    800034bc:	e822                	sd	s0,16(sp)
    800034be:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800034c0:	fec40593          	addi	a1,s0,-20
    800034c4:	4501                	li	a0,0
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	d86080e7          	jalr	-634(ra) # 8000324c <argint>
    800034ce:	87aa                	mv	a5,a0
    return -1;
    800034d0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800034d2:	0007c863          	bltz	a5,800034e2 <sys_kill+0x2a>
  return kill(pid);
    800034d6:	fec42503          	lw	a0,-20(s0)
    800034da:	fffff097          	auipc	ra,0xfffff
    800034de:	cbc080e7          	jalr	-836(ra) # 80002196 <kill>
}
    800034e2:	60e2                	ld	ra,24(sp)
    800034e4:	6442                	ld	s0,16(sp)
    800034e6:	6105                	addi	sp,sp,32
    800034e8:	8082                	ret

00000000800034ea <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034ea:	1101                	addi	sp,sp,-32
    800034ec:	ec06                	sd	ra,24(sp)
    800034ee:	e822                	sd	s0,16(sp)
    800034f0:	e426                	sd	s1,8(sp)
    800034f2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034f4:	0001c517          	auipc	a0,0x1c
    800034f8:	fdc50513          	addi	a0,a0,-36 # 8001f4d0 <tickslock>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	6c6080e7          	jalr	1734(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003504:	00006497          	auipc	s1,0x6
    80003508:	b2c4a483          	lw	s1,-1236(s1) # 80009030 <ticks>
  release(&tickslock);
    8000350c:	0001c517          	auipc	a0,0x1c
    80003510:	fc450513          	addi	a0,a0,-60 # 8001f4d0 <tickslock>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	762080e7          	jalr	1890(ra) # 80000c76 <release>
  return xticks;
}
    8000351c:	02049513          	slli	a0,s1,0x20
    80003520:	9101                	srli	a0,a0,0x20
    80003522:	60e2                	ld	ra,24(sp)
    80003524:	6442                	ld	s0,16(sp)
    80003526:	64a2                	ld	s1,8(sp)
    80003528:	6105                	addi	sp,sp,32
    8000352a:	8082                	ret

000000008000352c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000352c:	7179                	addi	sp,sp,-48
    8000352e:	f406                	sd	ra,40(sp)
    80003530:	f022                	sd	s0,32(sp)
    80003532:	ec26                	sd	s1,24(sp)
    80003534:	e84a                	sd	s2,16(sp)
    80003536:	e44e                	sd	s3,8(sp)
    80003538:	e052                	sd	s4,0(sp)
    8000353a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000353c:	00005597          	auipc	a1,0x5
    80003540:	26c58593          	addi	a1,a1,620 # 800087a8 <syscalls+0xb0>
    80003544:	0001c517          	auipc	a0,0x1c
    80003548:	fa450513          	addi	a0,a0,-92 # 8001f4e8 <bcache>
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	5e6080e7          	jalr	1510(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003554:	00024797          	auipc	a5,0x24
    80003558:	f9478793          	addi	a5,a5,-108 # 800274e8 <bcache+0x8000>
    8000355c:	00024717          	auipc	a4,0x24
    80003560:	1f470713          	addi	a4,a4,500 # 80027750 <bcache+0x8268>
    80003564:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003568:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000356c:	0001c497          	auipc	s1,0x1c
    80003570:	f9448493          	addi	s1,s1,-108 # 8001f500 <bcache+0x18>
    b->next = bcache.head.next;
    80003574:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003576:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003578:	00005a17          	auipc	s4,0x5
    8000357c:	238a0a13          	addi	s4,s4,568 # 800087b0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003580:	2b893783          	ld	a5,696(s2)
    80003584:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003586:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000358a:	85d2                	mv	a1,s4
    8000358c:	01048513          	addi	a0,s1,16
    80003590:	00001097          	auipc	ra,0x1
    80003594:	7d4080e7          	jalr	2004(ra) # 80004d64 <initsleeplock>
    bcache.head.next->prev = b;
    80003598:	2b893783          	ld	a5,696(s2)
    8000359c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000359e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035a2:	45848493          	addi	s1,s1,1112
    800035a6:	fd349de3          	bne	s1,s3,80003580 <binit+0x54>
  }
}
    800035aa:	70a2                	ld	ra,40(sp)
    800035ac:	7402                	ld	s0,32(sp)
    800035ae:	64e2                	ld	s1,24(sp)
    800035b0:	6942                	ld	s2,16(sp)
    800035b2:	69a2                	ld	s3,8(sp)
    800035b4:	6a02                	ld	s4,0(sp)
    800035b6:	6145                	addi	sp,sp,48
    800035b8:	8082                	ret

00000000800035ba <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035ba:	7179                	addi	sp,sp,-48
    800035bc:	f406                	sd	ra,40(sp)
    800035be:	f022                	sd	s0,32(sp)
    800035c0:	ec26                	sd	s1,24(sp)
    800035c2:	e84a                	sd	s2,16(sp)
    800035c4:	e44e                	sd	s3,8(sp)
    800035c6:	1800                	addi	s0,sp,48
    800035c8:	892a                	mv	s2,a0
    800035ca:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800035cc:	0001c517          	auipc	a0,0x1c
    800035d0:	f1c50513          	addi	a0,a0,-228 # 8001f4e8 <bcache>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	5ee080e7          	jalr	1518(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035dc:	00024497          	auipc	s1,0x24
    800035e0:	1c44b483          	ld	s1,452(s1) # 800277a0 <bcache+0x82b8>
    800035e4:	00024797          	auipc	a5,0x24
    800035e8:	16c78793          	addi	a5,a5,364 # 80027750 <bcache+0x8268>
    800035ec:	02f48f63          	beq	s1,a5,8000362a <bread+0x70>
    800035f0:	873e                	mv	a4,a5
    800035f2:	a021                	j	800035fa <bread+0x40>
    800035f4:	68a4                	ld	s1,80(s1)
    800035f6:	02e48a63          	beq	s1,a4,8000362a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035fa:	449c                	lw	a5,8(s1)
    800035fc:	ff279ce3          	bne	a5,s2,800035f4 <bread+0x3a>
    80003600:	44dc                	lw	a5,12(s1)
    80003602:	ff3799e3          	bne	a5,s3,800035f4 <bread+0x3a>
      b->refcnt++;
    80003606:	40bc                	lw	a5,64(s1)
    80003608:	2785                	addiw	a5,a5,1
    8000360a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000360c:	0001c517          	auipc	a0,0x1c
    80003610:	edc50513          	addi	a0,a0,-292 # 8001f4e8 <bcache>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	662080e7          	jalr	1634(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000361c:	01048513          	addi	a0,s1,16
    80003620:	00001097          	auipc	ra,0x1
    80003624:	77e080e7          	jalr	1918(ra) # 80004d9e <acquiresleep>
      return b;
    80003628:	a8b9                	j	80003686 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000362a:	00024497          	auipc	s1,0x24
    8000362e:	16e4b483          	ld	s1,366(s1) # 80027798 <bcache+0x82b0>
    80003632:	00024797          	auipc	a5,0x24
    80003636:	11e78793          	addi	a5,a5,286 # 80027750 <bcache+0x8268>
    8000363a:	00f48863          	beq	s1,a5,8000364a <bread+0x90>
    8000363e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003640:	40bc                	lw	a5,64(s1)
    80003642:	cf81                	beqz	a5,8000365a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003644:	64a4                	ld	s1,72(s1)
    80003646:	fee49de3          	bne	s1,a4,80003640 <bread+0x86>
  panic("bget: no buffers");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	16e50513          	addi	a0,a0,366 # 800087b8 <syscalls+0xc0>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	ed8080e7          	jalr	-296(ra) # 8000052a <panic>
      b->dev = dev;
    8000365a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000365e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003662:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003666:	4785                	li	a5,1
    80003668:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000366a:	0001c517          	auipc	a0,0x1c
    8000366e:	e7e50513          	addi	a0,a0,-386 # 8001f4e8 <bcache>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	604080e7          	jalr	1540(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000367a:	01048513          	addi	a0,s1,16
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	720080e7          	jalr	1824(ra) # 80004d9e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003686:	409c                	lw	a5,0(s1)
    80003688:	cb89                	beqz	a5,8000369a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000368a:	8526                	mv	a0,s1
    8000368c:	70a2                	ld	ra,40(sp)
    8000368e:	7402                	ld	s0,32(sp)
    80003690:	64e2                	ld	s1,24(sp)
    80003692:	6942                	ld	s2,16(sp)
    80003694:	69a2                	ld	s3,8(sp)
    80003696:	6145                	addi	sp,sp,48
    80003698:	8082                	ret
    virtio_disk_rw(b, 0);
    8000369a:	4581                	li	a1,0
    8000369c:	8526                	mv	a0,s1
    8000369e:	00003097          	auipc	ra,0x3
    800036a2:	518080e7          	jalr	1304(ra) # 80006bb6 <virtio_disk_rw>
    b->valid = 1;
    800036a6:	4785                	li	a5,1
    800036a8:	c09c                	sw	a5,0(s1)
  return b;
    800036aa:	b7c5                	j	8000368a <bread+0xd0>

00000000800036ac <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036ac:	1101                	addi	sp,sp,-32
    800036ae:	ec06                	sd	ra,24(sp)
    800036b0:	e822                	sd	s0,16(sp)
    800036b2:	e426                	sd	s1,8(sp)
    800036b4:	1000                	addi	s0,sp,32
    800036b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036b8:	0541                	addi	a0,a0,16
    800036ba:	00001097          	auipc	ra,0x1
    800036be:	77e080e7          	jalr	1918(ra) # 80004e38 <holdingsleep>
    800036c2:	cd01                	beqz	a0,800036da <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036c4:	4585                	li	a1,1
    800036c6:	8526                	mv	a0,s1
    800036c8:	00003097          	auipc	ra,0x3
    800036cc:	4ee080e7          	jalr	1262(ra) # 80006bb6 <virtio_disk_rw>
}
    800036d0:	60e2                	ld	ra,24(sp)
    800036d2:	6442                	ld	s0,16(sp)
    800036d4:	64a2                	ld	s1,8(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret
    panic("bwrite");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	0f650513          	addi	a0,a0,246 # 800087d0 <syscalls+0xd8>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e48080e7          	jalr	-440(ra) # 8000052a <panic>

00000000800036ea <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036ea:	1101                	addi	sp,sp,-32
    800036ec:	ec06                	sd	ra,24(sp)
    800036ee:	e822                	sd	s0,16(sp)
    800036f0:	e426                	sd	s1,8(sp)
    800036f2:	e04a                	sd	s2,0(sp)
    800036f4:	1000                	addi	s0,sp,32
    800036f6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036f8:	01050913          	addi	s2,a0,16
    800036fc:	854a                	mv	a0,s2
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	73a080e7          	jalr	1850(ra) # 80004e38 <holdingsleep>
    80003706:	c92d                	beqz	a0,80003778 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003708:	854a                	mv	a0,s2
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	6ea080e7          	jalr	1770(ra) # 80004df4 <releasesleep>

  acquire(&bcache.lock);
    80003712:	0001c517          	auipc	a0,0x1c
    80003716:	dd650513          	addi	a0,a0,-554 # 8001f4e8 <bcache>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	4a8080e7          	jalr	1192(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003722:	40bc                	lw	a5,64(s1)
    80003724:	37fd                	addiw	a5,a5,-1
    80003726:	0007871b          	sext.w	a4,a5
    8000372a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000372c:	eb05                	bnez	a4,8000375c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000372e:	68bc                	ld	a5,80(s1)
    80003730:	64b8                	ld	a4,72(s1)
    80003732:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003734:	64bc                	ld	a5,72(s1)
    80003736:	68b8                	ld	a4,80(s1)
    80003738:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000373a:	00024797          	auipc	a5,0x24
    8000373e:	dae78793          	addi	a5,a5,-594 # 800274e8 <bcache+0x8000>
    80003742:	2b87b703          	ld	a4,696(a5)
    80003746:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003748:	00024717          	auipc	a4,0x24
    8000374c:	00870713          	addi	a4,a4,8 # 80027750 <bcache+0x8268>
    80003750:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003752:	2b87b703          	ld	a4,696(a5)
    80003756:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003758:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000375c:	0001c517          	auipc	a0,0x1c
    80003760:	d8c50513          	addi	a0,a0,-628 # 8001f4e8 <bcache>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	512080e7          	jalr	1298(ra) # 80000c76 <release>
}
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6902                	ld	s2,0(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret
    panic("brelse");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	06050513          	addi	a0,a0,96 # 800087d8 <syscalls+0xe0>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	daa080e7          	jalr	-598(ra) # 8000052a <panic>

0000000080003788 <bpin>:

void
bpin(struct buf *b) {
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	e426                	sd	s1,8(sp)
    80003790:	1000                	addi	s0,sp,32
    80003792:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003794:	0001c517          	auipc	a0,0x1c
    80003798:	d5450513          	addi	a0,a0,-684 # 8001f4e8 <bcache>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	426080e7          	jalr	1062(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800037a4:	40bc                	lw	a5,64(s1)
    800037a6:	2785                	addiw	a5,a5,1
    800037a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037aa:	0001c517          	auipc	a0,0x1c
    800037ae:	d3e50513          	addi	a0,a0,-706 # 8001f4e8 <bcache>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	4c4080e7          	jalr	1220(ra) # 80000c76 <release>
}
    800037ba:	60e2                	ld	ra,24(sp)
    800037bc:	6442                	ld	s0,16(sp)
    800037be:	64a2                	ld	s1,8(sp)
    800037c0:	6105                	addi	sp,sp,32
    800037c2:	8082                	ret

00000000800037c4 <bunpin>:

void
bunpin(struct buf *b) {
    800037c4:	1101                	addi	sp,sp,-32
    800037c6:	ec06                	sd	ra,24(sp)
    800037c8:	e822                	sd	s0,16(sp)
    800037ca:	e426                	sd	s1,8(sp)
    800037cc:	1000                	addi	s0,sp,32
    800037ce:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037d0:	0001c517          	auipc	a0,0x1c
    800037d4:	d1850513          	addi	a0,a0,-744 # 8001f4e8 <bcache>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	3ea080e7          	jalr	1002(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800037e0:	40bc                	lw	a5,64(s1)
    800037e2:	37fd                	addiw	a5,a5,-1
    800037e4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037e6:	0001c517          	auipc	a0,0x1c
    800037ea:	d0250513          	addi	a0,a0,-766 # 8001f4e8 <bcache>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	488080e7          	jalr	1160(ra) # 80000c76 <release>
}
    800037f6:	60e2                	ld	ra,24(sp)
    800037f8:	6442                	ld	s0,16(sp)
    800037fa:	64a2                	ld	s1,8(sp)
    800037fc:	6105                	addi	sp,sp,32
    800037fe:	8082                	ret

0000000080003800 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003800:	1101                	addi	sp,sp,-32
    80003802:	ec06                	sd	ra,24(sp)
    80003804:	e822                	sd	s0,16(sp)
    80003806:	e426                	sd	s1,8(sp)
    80003808:	e04a                	sd	s2,0(sp)
    8000380a:	1000                	addi	s0,sp,32
    8000380c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000380e:	00d5d59b          	srliw	a1,a1,0xd
    80003812:	00024797          	auipc	a5,0x24
    80003816:	3b27a783          	lw	a5,946(a5) # 80027bc4 <sb+0x1c>
    8000381a:	9dbd                	addw	a1,a1,a5
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	d9e080e7          	jalr	-610(ra) # 800035ba <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003824:	0074f713          	andi	a4,s1,7
    80003828:	4785                	li	a5,1
    8000382a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000382e:	14ce                	slli	s1,s1,0x33
    80003830:	90d9                	srli	s1,s1,0x36
    80003832:	00950733          	add	a4,a0,s1
    80003836:	05874703          	lbu	a4,88(a4)
    8000383a:	00e7f6b3          	and	a3,a5,a4
    8000383e:	c69d                	beqz	a3,8000386c <bfree+0x6c>
    80003840:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003842:	94aa                	add	s1,s1,a0
    80003844:	fff7c793          	not	a5,a5
    80003848:	8ff9                	and	a5,a5,a4
    8000384a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	430080e7          	jalr	1072(ra) # 80004c7e <log_write>
  brelse(bp);
    80003856:	854a                	mv	a0,s2
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	e92080e7          	jalr	-366(ra) # 800036ea <brelse>
}
    80003860:	60e2                	ld	ra,24(sp)
    80003862:	6442                	ld	s0,16(sp)
    80003864:	64a2                	ld	s1,8(sp)
    80003866:	6902                	ld	s2,0(sp)
    80003868:	6105                	addi	sp,sp,32
    8000386a:	8082                	ret
    panic("freeing free block");
    8000386c:	00005517          	auipc	a0,0x5
    80003870:	f7450513          	addi	a0,a0,-140 # 800087e0 <syscalls+0xe8>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	cb6080e7          	jalr	-842(ra) # 8000052a <panic>

000000008000387c <balloc>:
{
    8000387c:	711d                	addi	sp,sp,-96
    8000387e:	ec86                	sd	ra,88(sp)
    80003880:	e8a2                	sd	s0,80(sp)
    80003882:	e4a6                	sd	s1,72(sp)
    80003884:	e0ca                	sd	s2,64(sp)
    80003886:	fc4e                	sd	s3,56(sp)
    80003888:	f852                	sd	s4,48(sp)
    8000388a:	f456                	sd	s5,40(sp)
    8000388c:	f05a                	sd	s6,32(sp)
    8000388e:	ec5e                	sd	s7,24(sp)
    80003890:	e862                	sd	s8,16(sp)
    80003892:	e466                	sd	s9,8(sp)
    80003894:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003896:	00024797          	auipc	a5,0x24
    8000389a:	3167a783          	lw	a5,790(a5) # 80027bac <sb+0x4>
    8000389e:	cbd1                	beqz	a5,80003932 <balloc+0xb6>
    800038a0:	8baa                	mv	s7,a0
    800038a2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038a4:	00024b17          	auipc	s6,0x24
    800038a8:	304b0b13          	addi	s6,s6,772 # 80027ba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ac:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038ae:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038b0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038b2:	6c89                	lui	s9,0x2
    800038b4:	a831                	j	800038d0 <balloc+0x54>
    brelse(bp);
    800038b6:	854a                	mv	a0,s2
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	e32080e7          	jalr	-462(ra) # 800036ea <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038c0:	015c87bb          	addw	a5,s9,s5
    800038c4:	00078a9b          	sext.w	s5,a5
    800038c8:	004b2703          	lw	a4,4(s6)
    800038cc:	06eaf363          	bgeu	s5,a4,80003932 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038d0:	41fad79b          	sraiw	a5,s5,0x1f
    800038d4:	0137d79b          	srliw	a5,a5,0x13
    800038d8:	015787bb          	addw	a5,a5,s5
    800038dc:	40d7d79b          	sraiw	a5,a5,0xd
    800038e0:	01cb2583          	lw	a1,28(s6)
    800038e4:	9dbd                	addw	a1,a1,a5
    800038e6:	855e                	mv	a0,s7
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	cd2080e7          	jalr	-814(ra) # 800035ba <bread>
    800038f0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038f2:	004b2503          	lw	a0,4(s6)
    800038f6:	000a849b          	sext.w	s1,s5
    800038fa:	8662                	mv	a2,s8
    800038fc:	faa4fde3          	bgeu	s1,a0,800038b6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003900:	41f6579b          	sraiw	a5,a2,0x1f
    80003904:	01d7d69b          	srliw	a3,a5,0x1d
    80003908:	00c6873b          	addw	a4,a3,a2
    8000390c:	00777793          	andi	a5,a4,7
    80003910:	9f95                	subw	a5,a5,a3
    80003912:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003916:	4037571b          	sraiw	a4,a4,0x3
    8000391a:	00e906b3          	add	a3,s2,a4
    8000391e:	0586c683          	lbu	a3,88(a3)
    80003922:	00d7f5b3          	and	a1,a5,a3
    80003926:	cd91                	beqz	a1,80003942 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003928:	2605                	addiw	a2,a2,1
    8000392a:	2485                	addiw	s1,s1,1
    8000392c:	fd4618e3          	bne	a2,s4,800038fc <balloc+0x80>
    80003930:	b759                	j	800038b6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003932:	00005517          	auipc	a0,0x5
    80003936:	ec650513          	addi	a0,a0,-314 # 800087f8 <syscalls+0x100>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	bf0080e7          	jalr	-1040(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003942:	974a                	add	a4,a4,s2
    80003944:	8fd5                	or	a5,a5,a3
    80003946:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000394a:	854a                	mv	a0,s2
    8000394c:	00001097          	auipc	ra,0x1
    80003950:	332080e7          	jalr	818(ra) # 80004c7e <log_write>
        brelse(bp);
    80003954:	854a                	mv	a0,s2
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	d94080e7          	jalr	-620(ra) # 800036ea <brelse>
  bp = bread(dev, bno);
    8000395e:	85a6                	mv	a1,s1
    80003960:	855e                	mv	a0,s7
    80003962:	00000097          	auipc	ra,0x0
    80003966:	c58080e7          	jalr	-936(ra) # 800035ba <bread>
    8000396a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000396c:	40000613          	li	a2,1024
    80003970:	4581                	li	a1,0
    80003972:	05850513          	addi	a0,a0,88
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	348080e7          	jalr	840(ra) # 80000cbe <memset>
  log_write(bp);
    8000397e:	854a                	mv	a0,s2
    80003980:	00001097          	auipc	ra,0x1
    80003984:	2fe080e7          	jalr	766(ra) # 80004c7e <log_write>
  brelse(bp);
    80003988:	854a                	mv	a0,s2
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	d60080e7          	jalr	-672(ra) # 800036ea <brelse>
}
    80003992:	8526                	mv	a0,s1
    80003994:	60e6                	ld	ra,88(sp)
    80003996:	6446                	ld	s0,80(sp)
    80003998:	64a6                	ld	s1,72(sp)
    8000399a:	6906                	ld	s2,64(sp)
    8000399c:	79e2                	ld	s3,56(sp)
    8000399e:	7a42                	ld	s4,48(sp)
    800039a0:	7aa2                	ld	s5,40(sp)
    800039a2:	7b02                	ld	s6,32(sp)
    800039a4:	6be2                	ld	s7,24(sp)
    800039a6:	6c42                	ld	s8,16(sp)
    800039a8:	6ca2                	ld	s9,8(sp)
    800039aa:	6125                	addi	sp,sp,96
    800039ac:	8082                	ret

00000000800039ae <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039ae:	7179                	addi	sp,sp,-48
    800039b0:	f406                	sd	ra,40(sp)
    800039b2:	f022                	sd	s0,32(sp)
    800039b4:	ec26                	sd	s1,24(sp)
    800039b6:	e84a                	sd	s2,16(sp)
    800039b8:	e44e                	sd	s3,8(sp)
    800039ba:	e052                	sd	s4,0(sp)
    800039bc:	1800                	addi	s0,sp,48
    800039be:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039c0:	47ad                	li	a5,11
    800039c2:	04b7fe63          	bgeu	a5,a1,80003a1e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039c6:	ff45849b          	addiw	s1,a1,-12
    800039ca:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039ce:	0ff00793          	li	a5,255
    800039d2:	0ae7e463          	bltu	a5,a4,80003a7a <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800039d6:	08052583          	lw	a1,128(a0)
    800039da:	c5b5                	beqz	a1,80003a46 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800039dc:	00092503          	lw	a0,0(s2)
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	bda080e7          	jalr	-1062(ra) # 800035ba <bread>
    800039e8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039ea:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039ee:	02049713          	slli	a4,s1,0x20
    800039f2:	01e75593          	srli	a1,a4,0x1e
    800039f6:	00b784b3          	add	s1,a5,a1
    800039fa:	0004a983          	lw	s3,0(s1)
    800039fe:	04098e63          	beqz	s3,80003a5a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a02:	8552                	mv	a0,s4
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	ce6080e7          	jalr	-794(ra) # 800036ea <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a0c:	854e                	mv	a0,s3
    80003a0e:	70a2                	ld	ra,40(sp)
    80003a10:	7402                	ld	s0,32(sp)
    80003a12:	64e2                	ld	s1,24(sp)
    80003a14:	6942                	ld	s2,16(sp)
    80003a16:	69a2                	ld	s3,8(sp)
    80003a18:	6a02                	ld	s4,0(sp)
    80003a1a:	6145                	addi	sp,sp,48
    80003a1c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a1e:	02059793          	slli	a5,a1,0x20
    80003a22:	01e7d593          	srli	a1,a5,0x1e
    80003a26:	00b504b3          	add	s1,a0,a1
    80003a2a:	0504a983          	lw	s3,80(s1)
    80003a2e:	fc099fe3          	bnez	s3,80003a0c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a32:	4108                	lw	a0,0(a0)
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	e48080e7          	jalr	-440(ra) # 8000387c <balloc>
    80003a3c:	0005099b          	sext.w	s3,a0
    80003a40:	0534a823          	sw	s3,80(s1)
    80003a44:	b7e1                	j	80003a0c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a46:	4108                	lw	a0,0(a0)
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	e34080e7          	jalr	-460(ra) # 8000387c <balloc>
    80003a50:	0005059b          	sext.w	a1,a0
    80003a54:	08b92023          	sw	a1,128(s2)
    80003a58:	b751                	j	800039dc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a5a:	00092503          	lw	a0,0(s2)
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	e1e080e7          	jalr	-482(ra) # 8000387c <balloc>
    80003a66:	0005099b          	sext.w	s3,a0
    80003a6a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a6e:	8552                	mv	a0,s4
    80003a70:	00001097          	auipc	ra,0x1
    80003a74:	20e080e7          	jalr	526(ra) # 80004c7e <log_write>
    80003a78:	b769                	j	80003a02 <bmap+0x54>
  panic("bmap: out of range");
    80003a7a:	00005517          	auipc	a0,0x5
    80003a7e:	d9650513          	addi	a0,a0,-618 # 80008810 <syscalls+0x118>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	aa8080e7          	jalr	-1368(ra) # 8000052a <panic>

0000000080003a8a <iget>:
{
    80003a8a:	7179                	addi	sp,sp,-48
    80003a8c:	f406                	sd	ra,40(sp)
    80003a8e:	f022                	sd	s0,32(sp)
    80003a90:	ec26                	sd	s1,24(sp)
    80003a92:	e84a                	sd	s2,16(sp)
    80003a94:	e44e                	sd	s3,8(sp)
    80003a96:	e052                	sd	s4,0(sp)
    80003a98:	1800                	addi	s0,sp,48
    80003a9a:	89aa                	mv	s3,a0
    80003a9c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a9e:	00024517          	auipc	a0,0x24
    80003aa2:	12a50513          	addi	a0,a0,298 # 80027bc8 <itable>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	11c080e7          	jalr	284(ra) # 80000bc2 <acquire>
  empty = 0;
    80003aae:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ab0:	00024497          	auipc	s1,0x24
    80003ab4:	13048493          	addi	s1,s1,304 # 80027be0 <itable+0x18>
    80003ab8:	00026697          	auipc	a3,0x26
    80003abc:	bb868693          	addi	a3,a3,-1096 # 80029670 <log>
    80003ac0:	a039                	j	80003ace <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ac2:	02090b63          	beqz	s2,80003af8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ac6:	08848493          	addi	s1,s1,136
    80003aca:	02d48a63          	beq	s1,a3,80003afe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ace:	449c                	lw	a5,8(s1)
    80003ad0:	fef059e3          	blez	a5,80003ac2 <iget+0x38>
    80003ad4:	4098                	lw	a4,0(s1)
    80003ad6:	ff3716e3          	bne	a4,s3,80003ac2 <iget+0x38>
    80003ada:	40d8                	lw	a4,4(s1)
    80003adc:	ff4713e3          	bne	a4,s4,80003ac2 <iget+0x38>
      ip->ref++;
    80003ae0:	2785                	addiw	a5,a5,1
    80003ae2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ae4:	00024517          	auipc	a0,0x24
    80003ae8:	0e450513          	addi	a0,a0,228 # 80027bc8 <itable>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	18a080e7          	jalr	394(ra) # 80000c76 <release>
      return ip;
    80003af4:	8926                	mv	s2,s1
    80003af6:	a03d                	j	80003b24 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003af8:	f7f9                	bnez	a5,80003ac6 <iget+0x3c>
    80003afa:	8926                	mv	s2,s1
    80003afc:	b7e9                	j	80003ac6 <iget+0x3c>
  if(empty == 0)
    80003afe:	02090c63          	beqz	s2,80003b36 <iget+0xac>
  ip->dev = dev;
    80003b02:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b06:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b0a:	4785                	li	a5,1
    80003b0c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b10:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b14:	00024517          	auipc	a0,0x24
    80003b18:	0b450513          	addi	a0,a0,180 # 80027bc8 <itable>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	15a080e7          	jalr	346(ra) # 80000c76 <release>
}
    80003b24:	854a                	mv	a0,s2
    80003b26:	70a2                	ld	ra,40(sp)
    80003b28:	7402                	ld	s0,32(sp)
    80003b2a:	64e2                	ld	s1,24(sp)
    80003b2c:	6942                	ld	s2,16(sp)
    80003b2e:	69a2                	ld	s3,8(sp)
    80003b30:	6a02                	ld	s4,0(sp)
    80003b32:	6145                	addi	sp,sp,48
    80003b34:	8082                	ret
    panic("iget: no inodes");
    80003b36:	00005517          	auipc	a0,0x5
    80003b3a:	cf250513          	addi	a0,a0,-782 # 80008828 <syscalls+0x130>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	9ec080e7          	jalr	-1556(ra) # 8000052a <panic>

0000000080003b46 <fsinit>:
fsinit(int dev) {
    80003b46:	7179                	addi	sp,sp,-48
    80003b48:	f406                	sd	ra,40(sp)
    80003b4a:	f022                	sd	s0,32(sp)
    80003b4c:	ec26                	sd	s1,24(sp)
    80003b4e:	e84a                	sd	s2,16(sp)
    80003b50:	e44e                	sd	s3,8(sp)
    80003b52:	1800                	addi	s0,sp,48
    80003b54:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b56:	4585                	li	a1,1
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	a62080e7          	jalr	-1438(ra) # 800035ba <bread>
    80003b60:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b62:	00024997          	auipc	s3,0x24
    80003b66:	04698993          	addi	s3,s3,70 # 80027ba8 <sb>
    80003b6a:	02000613          	li	a2,32
    80003b6e:	05850593          	addi	a1,a0,88
    80003b72:	854e                	mv	a0,s3
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	1a6080e7          	jalr	422(ra) # 80000d1a <memmove>
  brelse(bp);
    80003b7c:	8526                	mv	a0,s1
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	b6c080e7          	jalr	-1172(ra) # 800036ea <brelse>
  if(sb.magic != FSMAGIC)
    80003b86:	0009a703          	lw	a4,0(s3)
    80003b8a:	102037b7          	lui	a5,0x10203
    80003b8e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b92:	02f71263          	bne	a4,a5,80003bb6 <fsinit+0x70>
  initlog(dev, &sb);
    80003b96:	00024597          	auipc	a1,0x24
    80003b9a:	01258593          	addi	a1,a1,18 # 80027ba8 <sb>
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00001097          	auipc	ra,0x1
    80003ba4:	e60080e7          	jalr	-416(ra) # 80004a00 <initlog>
}
    80003ba8:	70a2                	ld	ra,40(sp)
    80003baa:	7402                	ld	s0,32(sp)
    80003bac:	64e2                	ld	s1,24(sp)
    80003bae:	6942                	ld	s2,16(sp)
    80003bb0:	69a2                	ld	s3,8(sp)
    80003bb2:	6145                	addi	sp,sp,48
    80003bb4:	8082                	ret
    panic("invalid file system");
    80003bb6:	00005517          	auipc	a0,0x5
    80003bba:	c8250513          	addi	a0,a0,-894 # 80008838 <syscalls+0x140>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	96c080e7          	jalr	-1684(ra) # 8000052a <panic>

0000000080003bc6 <iinit>:
{
    80003bc6:	7179                	addi	sp,sp,-48
    80003bc8:	f406                	sd	ra,40(sp)
    80003bca:	f022                	sd	s0,32(sp)
    80003bcc:	ec26                	sd	s1,24(sp)
    80003bce:	e84a                	sd	s2,16(sp)
    80003bd0:	e44e                	sd	s3,8(sp)
    80003bd2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bd4:	00005597          	auipc	a1,0x5
    80003bd8:	c7c58593          	addi	a1,a1,-900 # 80008850 <syscalls+0x158>
    80003bdc:	00024517          	auipc	a0,0x24
    80003be0:	fec50513          	addi	a0,a0,-20 # 80027bc8 <itable>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	f4e080e7          	jalr	-178(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bec:	00024497          	auipc	s1,0x24
    80003bf0:	00448493          	addi	s1,s1,4 # 80027bf0 <itable+0x28>
    80003bf4:	00026997          	auipc	s3,0x26
    80003bf8:	a8c98993          	addi	s3,s3,-1396 # 80029680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bfc:	00005917          	auipc	s2,0x5
    80003c00:	c5c90913          	addi	s2,s2,-932 # 80008858 <syscalls+0x160>
    80003c04:	85ca                	mv	a1,s2
    80003c06:	8526                	mv	a0,s1
    80003c08:	00001097          	auipc	ra,0x1
    80003c0c:	15c080e7          	jalr	348(ra) # 80004d64 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c10:	08848493          	addi	s1,s1,136
    80003c14:	ff3498e3          	bne	s1,s3,80003c04 <iinit+0x3e>
}
    80003c18:	70a2                	ld	ra,40(sp)
    80003c1a:	7402                	ld	s0,32(sp)
    80003c1c:	64e2                	ld	s1,24(sp)
    80003c1e:	6942                	ld	s2,16(sp)
    80003c20:	69a2                	ld	s3,8(sp)
    80003c22:	6145                	addi	sp,sp,48
    80003c24:	8082                	ret

0000000080003c26 <ialloc>:
{
    80003c26:	715d                	addi	sp,sp,-80
    80003c28:	e486                	sd	ra,72(sp)
    80003c2a:	e0a2                	sd	s0,64(sp)
    80003c2c:	fc26                	sd	s1,56(sp)
    80003c2e:	f84a                	sd	s2,48(sp)
    80003c30:	f44e                	sd	s3,40(sp)
    80003c32:	f052                	sd	s4,32(sp)
    80003c34:	ec56                	sd	s5,24(sp)
    80003c36:	e85a                	sd	s6,16(sp)
    80003c38:	e45e                	sd	s7,8(sp)
    80003c3a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c3c:	00024717          	auipc	a4,0x24
    80003c40:	f7872703          	lw	a4,-136(a4) # 80027bb4 <sb+0xc>
    80003c44:	4785                	li	a5,1
    80003c46:	04e7fa63          	bgeu	a5,a4,80003c9a <ialloc+0x74>
    80003c4a:	8aaa                	mv	s5,a0
    80003c4c:	8bae                	mv	s7,a1
    80003c4e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c50:	00024a17          	auipc	s4,0x24
    80003c54:	f58a0a13          	addi	s4,s4,-168 # 80027ba8 <sb>
    80003c58:	00048b1b          	sext.w	s6,s1
    80003c5c:	0044d793          	srli	a5,s1,0x4
    80003c60:	018a2583          	lw	a1,24(s4)
    80003c64:	9dbd                	addw	a1,a1,a5
    80003c66:	8556                	mv	a0,s5
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	952080e7          	jalr	-1710(ra) # 800035ba <bread>
    80003c70:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c72:	05850993          	addi	s3,a0,88
    80003c76:	00f4f793          	andi	a5,s1,15
    80003c7a:	079a                	slli	a5,a5,0x6
    80003c7c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c7e:	00099783          	lh	a5,0(s3)
    80003c82:	c785                	beqz	a5,80003caa <ialloc+0x84>
    brelse(bp);
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	a66080e7          	jalr	-1434(ra) # 800036ea <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c8c:	0485                	addi	s1,s1,1
    80003c8e:	00ca2703          	lw	a4,12(s4)
    80003c92:	0004879b          	sext.w	a5,s1
    80003c96:	fce7e1e3          	bltu	a5,a4,80003c58 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003c9a:	00005517          	auipc	a0,0x5
    80003c9e:	bc650513          	addi	a0,a0,-1082 # 80008860 <syscalls+0x168>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	888080e7          	jalr	-1912(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003caa:	04000613          	li	a2,64
    80003cae:	4581                	li	a1,0
    80003cb0:	854e                	mv	a0,s3
    80003cb2:	ffffd097          	auipc	ra,0xffffd
    80003cb6:	00c080e7          	jalr	12(ra) # 80000cbe <memset>
      dip->type = type;
    80003cba:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cbe:	854a                	mv	a0,s2
    80003cc0:	00001097          	auipc	ra,0x1
    80003cc4:	fbe080e7          	jalr	-66(ra) # 80004c7e <log_write>
      brelse(bp);
    80003cc8:	854a                	mv	a0,s2
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	a20080e7          	jalr	-1504(ra) # 800036ea <brelse>
      return iget(dev, inum);
    80003cd2:	85da                	mv	a1,s6
    80003cd4:	8556                	mv	a0,s5
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	db4080e7          	jalr	-588(ra) # 80003a8a <iget>
}
    80003cde:	60a6                	ld	ra,72(sp)
    80003ce0:	6406                	ld	s0,64(sp)
    80003ce2:	74e2                	ld	s1,56(sp)
    80003ce4:	7942                	ld	s2,48(sp)
    80003ce6:	79a2                	ld	s3,40(sp)
    80003ce8:	7a02                	ld	s4,32(sp)
    80003cea:	6ae2                	ld	s5,24(sp)
    80003cec:	6b42                	ld	s6,16(sp)
    80003cee:	6ba2                	ld	s7,8(sp)
    80003cf0:	6161                	addi	sp,sp,80
    80003cf2:	8082                	ret

0000000080003cf4 <iupdate>:
{
    80003cf4:	1101                	addi	sp,sp,-32
    80003cf6:	ec06                	sd	ra,24(sp)
    80003cf8:	e822                	sd	s0,16(sp)
    80003cfa:	e426                	sd	s1,8(sp)
    80003cfc:	e04a                	sd	s2,0(sp)
    80003cfe:	1000                	addi	s0,sp,32
    80003d00:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d02:	415c                	lw	a5,4(a0)
    80003d04:	0047d79b          	srliw	a5,a5,0x4
    80003d08:	00024597          	auipc	a1,0x24
    80003d0c:	eb85a583          	lw	a1,-328(a1) # 80027bc0 <sb+0x18>
    80003d10:	9dbd                	addw	a1,a1,a5
    80003d12:	4108                	lw	a0,0(a0)
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	8a6080e7          	jalr	-1882(ra) # 800035ba <bread>
    80003d1c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d1e:	05850793          	addi	a5,a0,88
    80003d22:	40c8                	lw	a0,4(s1)
    80003d24:	893d                	andi	a0,a0,15
    80003d26:	051a                	slli	a0,a0,0x6
    80003d28:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d2a:	04449703          	lh	a4,68(s1)
    80003d2e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d32:	04649703          	lh	a4,70(s1)
    80003d36:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d3a:	04849703          	lh	a4,72(s1)
    80003d3e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d42:	04a49703          	lh	a4,74(s1)
    80003d46:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d4a:	44f8                	lw	a4,76(s1)
    80003d4c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d4e:	03400613          	li	a2,52
    80003d52:	05048593          	addi	a1,s1,80
    80003d56:	0531                	addi	a0,a0,12
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	fc2080e7          	jalr	-62(ra) # 80000d1a <memmove>
  log_write(bp);
    80003d60:	854a                	mv	a0,s2
    80003d62:	00001097          	auipc	ra,0x1
    80003d66:	f1c080e7          	jalr	-228(ra) # 80004c7e <log_write>
  brelse(bp);
    80003d6a:	854a                	mv	a0,s2
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	97e080e7          	jalr	-1666(ra) # 800036ea <brelse>
}
    80003d74:	60e2                	ld	ra,24(sp)
    80003d76:	6442                	ld	s0,16(sp)
    80003d78:	64a2                	ld	s1,8(sp)
    80003d7a:	6902                	ld	s2,0(sp)
    80003d7c:	6105                	addi	sp,sp,32
    80003d7e:	8082                	ret

0000000080003d80 <idup>:
{
    80003d80:	1101                	addi	sp,sp,-32
    80003d82:	ec06                	sd	ra,24(sp)
    80003d84:	e822                	sd	s0,16(sp)
    80003d86:	e426                	sd	s1,8(sp)
    80003d88:	1000                	addi	s0,sp,32
    80003d8a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d8c:	00024517          	auipc	a0,0x24
    80003d90:	e3c50513          	addi	a0,a0,-452 # 80027bc8 <itable>
    80003d94:	ffffd097          	auipc	ra,0xffffd
    80003d98:	e2e080e7          	jalr	-466(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003d9c:	449c                	lw	a5,8(s1)
    80003d9e:	2785                	addiw	a5,a5,1
    80003da0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003da2:	00024517          	auipc	a0,0x24
    80003da6:	e2650513          	addi	a0,a0,-474 # 80027bc8 <itable>
    80003daa:	ffffd097          	auipc	ra,0xffffd
    80003dae:	ecc080e7          	jalr	-308(ra) # 80000c76 <release>
}
    80003db2:	8526                	mv	a0,s1
    80003db4:	60e2                	ld	ra,24(sp)
    80003db6:	6442                	ld	s0,16(sp)
    80003db8:	64a2                	ld	s1,8(sp)
    80003dba:	6105                	addi	sp,sp,32
    80003dbc:	8082                	ret

0000000080003dbe <ilock>:
{
    80003dbe:	1101                	addi	sp,sp,-32
    80003dc0:	ec06                	sd	ra,24(sp)
    80003dc2:	e822                	sd	s0,16(sp)
    80003dc4:	e426                	sd	s1,8(sp)
    80003dc6:	e04a                	sd	s2,0(sp)
    80003dc8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003dca:	c115                	beqz	a0,80003dee <ilock+0x30>
    80003dcc:	84aa                	mv	s1,a0
    80003dce:	451c                	lw	a5,8(a0)
    80003dd0:	00f05f63          	blez	a5,80003dee <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dd4:	0541                	addi	a0,a0,16
    80003dd6:	00001097          	auipc	ra,0x1
    80003dda:	fc8080e7          	jalr	-56(ra) # 80004d9e <acquiresleep>
  if(ip->valid == 0){
    80003dde:	40bc                	lw	a5,64(s1)
    80003de0:	cf99                	beqz	a5,80003dfe <ilock+0x40>
}
    80003de2:	60e2                	ld	ra,24(sp)
    80003de4:	6442                	ld	s0,16(sp)
    80003de6:	64a2                	ld	s1,8(sp)
    80003de8:	6902                	ld	s2,0(sp)
    80003dea:	6105                	addi	sp,sp,32
    80003dec:	8082                	ret
    panic("ilock");
    80003dee:	00005517          	auipc	a0,0x5
    80003df2:	a8a50513          	addi	a0,a0,-1398 # 80008878 <syscalls+0x180>
    80003df6:	ffffc097          	auipc	ra,0xffffc
    80003dfa:	734080e7          	jalr	1844(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dfe:	40dc                	lw	a5,4(s1)
    80003e00:	0047d79b          	srliw	a5,a5,0x4
    80003e04:	00024597          	auipc	a1,0x24
    80003e08:	dbc5a583          	lw	a1,-580(a1) # 80027bc0 <sb+0x18>
    80003e0c:	9dbd                	addw	a1,a1,a5
    80003e0e:	4088                	lw	a0,0(s1)
    80003e10:	fffff097          	auipc	ra,0xfffff
    80003e14:	7aa080e7          	jalr	1962(ra) # 800035ba <bread>
    80003e18:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e1a:	05850593          	addi	a1,a0,88
    80003e1e:	40dc                	lw	a5,4(s1)
    80003e20:	8bbd                	andi	a5,a5,15
    80003e22:	079a                	slli	a5,a5,0x6
    80003e24:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e26:	00059783          	lh	a5,0(a1)
    80003e2a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e2e:	00259783          	lh	a5,2(a1)
    80003e32:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e36:	00459783          	lh	a5,4(a1)
    80003e3a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e3e:	00659783          	lh	a5,6(a1)
    80003e42:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e46:	459c                	lw	a5,8(a1)
    80003e48:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e4a:	03400613          	li	a2,52
    80003e4e:	05b1                	addi	a1,a1,12
    80003e50:	05048513          	addi	a0,s1,80
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	ec6080e7          	jalr	-314(ra) # 80000d1a <memmove>
    brelse(bp);
    80003e5c:	854a                	mv	a0,s2
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	88c080e7          	jalr	-1908(ra) # 800036ea <brelse>
    ip->valid = 1;
    80003e66:	4785                	li	a5,1
    80003e68:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e6a:	04449783          	lh	a5,68(s1)
    80003e6e:	fbb5                	bnez	a5,80003de2 <ilock+0x24>
      panic("ilock: no type");
    80003e70:	00005517          	auipc	a0,0x5
    80003e74:	a1050513          	addi	a0,a0,-1520 # 80008880 <syscalls+0x188>
    80003e78:	ffffc097          	auipc	ra,0xffffc
    80003e7c:	6b2080e7          	jalr	1714(ra) # 8000052a <panic>

0000000080003e80 <iunlock>:
{
    80003e80:	1101                	addi	sp,sp,-32
    80003e82:	ec06                	sd	ra,24(sp)
    80003e84:	e822                	sd	s0,16(sp)
    80003e86:	e426                	sd	s1,8(sp)
    80003e88:	e04a                	sd	s2,0(sp)
    80003e8a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e8c:	c905                	beqz	a0,80003ebc <iunlock+0x3c>
    80003e8e:	84aa                	mv	s1,a0
    80003e90:	01050913          	addi	s2,a0,16
    80003e94:	854a                	mv	a0,s2
    80003e96:	00001097          	auipc	ra,0x1
    80003e9a:	fa2080e7          	jalr	-94(ra) # 80004e38 <holdingsleep>
    80003e9e:	cd19                	beqz	a0,80003ebc <iunlock+0x3c>
    80003ea0:	449c                	lw	a5,8(s1)
    80003ea2:	00f05d63          	blez	a5,80003ebc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ea6:	854a                	mv	a0,s2
    80003ea8:	00001097          	auipc	ra,0x1
    80003eac:	f4c080e7          	jalr	-180(ra) # 80004df4 <releasesleep>
}
    80003eb0:	60e2                	ld	ra,24(sp)
    80003eb2:	6442                	ld	s0,16(sp)
    80003eb4:	64a2                	ld	s1,8(sp)
    80003eb6:	6902                	ld	s2,0(sp)
    80003eb8:	6105                	addi	sp,sp,32
    80003eba:	8082                	ret
    panic("iunlock");
    80003ebc:	00005517          	auipc	a0,0x5
    80003ec0:	9d450513          	addi	a0,a0,-1580 # 80008890 <syscalls+0x198>
    80003ec4:	ffffc097          	auipc	ra,0xffffc
    80003ec8:	666080e7          	jalr	1638(ra) # 8000052a <panic>

0000000080003ecc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ecc:	7179                	addi	sp,sp,-48
    80003ece:	f406                	sd	ra,40(sp)
    80003ed0:	f022                	sd	s0,32(sp)
    80003ed2:	ec26                	sd	s1,24(sp)
    80003ed4:	e84a                	sd	s2,16(sp)
    80003ed6:	e44e                	sd	s3,8(sp)
    80003ed8:	e052                	sd	s4,0(sp)
    80003eda:	1800                	addi	s0,sp,48
    80003edc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ede:	05050493          	addi	s1,a0,80
    80003ee2:	08050913          	addi	s2,a0,128
    80003ee6:	a021                	j	80003eee <itrunc+0x22>
    80003ee8:	0491                	addi	s1,s1,4
    80003eea:	01248d63          	beq	s1,s2,80003f04 <itrunc+0x38>
    if(ip->addrs[i]){
    80003eee:	408c                	lw	a1,0(s1)
    80003ef0:	dde5                	beqz	a1,80003ee8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ef2:	0009a503          	lw	a0,0(s3)
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	90a080e7          	jalr	-1782(ra) # 80003800 <bfree>
      ip->addrs[i] = 0;
    80003efe:	0004a023          	sw	zero,0(s1)
    80003f02:	b7dd                	j	80003ee8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f04:	0809a583          	lw	a1,128(s3)
    80003f08:	e185                	bnez	a1,80003f28 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f0a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f0e:	854e                	mv	a0,s3
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	de4080e7          	jalr	-540(ra) # 80003cf4 <iupdate>
}
    80003f18:	70a2                	ld	ra,40(sp)
    80003f1a:	7402                	ld	s0,32(sp)
    80003f1c:	64e2                	ld	s1,24(sp)
    80003f1e:	6942                	ld	s2,16(sp)
    80003f20:	69a2                	ld	s3,8(sp)
    80003f22:	6a02                	ld	s4,0(sp)
    80003f24:	6145                	addi	sp,sp,48
    80003f26:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f28:	0009a503          	lw	a0,0(s3)
    80003f2c:	fffff097          	auipc	ra,0xfffff
    80003f30:	68e080e7          	jalr	1678(ra) # 800035ba <bread>
    80003f34:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f36:	05850493          	addi	s1,a0,88
    80003f3a:	45850913          	addi	s2,a0,1112
    80003f3e:	a021                	j	80003f46 <itrunc+0x7a>
    80003f40:	0491                	addi	s1,s1,4
    80003f42:	01248b63          	beq	s1,s2,80003f58 <itrunc+0x8c>
      if(a[j])
    80003f46:	408c                	lw	a1,0(s1)
    80003f48:	dde5                	beqz	a1,80003f40 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f4a:	0009a503          	lw	a0,0(s3)
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	8b2080e7          	jalr	-1870(ra) # 80003800 <bfree>
    80003f56:	b7ed                	j	80003f40 <itrunc+0x74>
    brelse(bp);
    80003f58:	8552                	mv	a0,s4
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	790080e7          	jalr	1936(ra) # 800036ea <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f62:	0809a583          	lw	a1,128(s3)
    80003f66:	0009a503          	lw	a0,0(s3)
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	896080e7          	jalr	-1898(ra) # 80003800 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f72:	0809a023          	sw	zero,128(s3)
    80003f76:	bf51                	j	80003f0a <itrunc+0x3e>

0000000080003f78 <iput>:
{
    80003f78:	1101                	addi	sp,sp,-32
    80003f7a:	ec06                	sd	ra,24(sp)
    80003f7c:	e822                	sd	s0,16(sp)
    80003f7e:	e426                	sd	s1,8(sp)
    80003f80:	e04a                	sd	s2,0(sp)
    80003f82:	1000                	addi	s0,sp,32
    80003f84:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f86:	00024517          	auipc	a0,0x24
    80003f8a:	c4250513          	addi	a0,a0,-958 # 80027bc8 <itable>
    80003f8e:	ffffd097          	auipc	ra,0xffffd
    80003f92:	c34080e7          	jalr	-972(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f96:	4498                	lw	a4,8(s1)
    80003f98:	4785                	li	a5,1
    80003f9a:	02f70363          	beq	a4,a5,80003fc0 <iput+0x48>
  ip->ref--;
    80003f9e:	449c                	lw	a5,8(s1)
    80003fa0:	37fd                	addiw	a5,a5,-1
    80003fa2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fa4:	00024517          	auipc	a0,0x24
    80003fa8:	c2450513          	addi	a0,a0,-988 # 80027bc8 <itable>
    80003fac:	ffffd097          	auipc	ra,0xffffd
    80003fb0:	cca080e7          	jalr	-822(ra) # 80000c76 <release>
}
    80003fb4:	60e2                	ld	ra,24(sp)
    80003fb6:	6442                	ld	s0,16(sp)
    80003fb8:	64a2                	ld	s1,8(sp)
    80003fba:	6902                	ld	s2,0(sp)
    80003fbc:	6105                	addi	sp,sp,32
    80003fbe:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fc0:	40bc                	lw	a5,64(s1)
    80003fc2:	dff1                	beqz	a5,80003f9e <iput+0x26>
    80003fc4:	04a49783          	lh	a5,74(s1)
    80003fc8:	fbf9                	bnez	a5,80003f9e <iput+0x26>
    acquiresleep(&ip->lock);
    80003fca:	01048913          	addi	s2,s1,16
    80003fce:	854a                	mv	a0,s2
    80003fd0:	00001097          	auipc	ra,0x1
    80003fd4:	dce080e7          	jalr	-562(ra) # 80004d9e <acquiresleep>
    release(&itable.lock);
    80003fd8:	00024517          	auipc	a0,0x24
    80003fdc:	bf050513          	addi	a0,a0,-1040 # 80027bc8 <itable>
    80003fe0:	ffffd097          	auipc	ra,0xffffd
    80003fe4:	c96080e7          	jalr	-874(ra) # 80000c76 <release>
    itrunc(ip);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	ee2080e7          	jalr	-286(ra) # 80003ecc <itrunc>
    ip->type = 0;
    80003ff2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	cfc080e7          	jalr	-772(ra) # 80003cf4 <iupdate>
    ip->valid = 0;
    80004000:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004004:	854a                	mv	a0,s2
    80004006:	00001097          	auipc	ra,0x1
    8000400a:	dee080e7          	jalr	-530(ra) # 80004df4 <releasesleep>
    acquire(&itable.lock);
    8000400e:	00024517          	auipc	a0,0x24
    80004012:	bba50513          	addi	a0,a0,-1094 # 80027bc8 <itable>
    80004016:	ffffd097          	auipc	ra,0xffffd
    8000401a:	bac080e7          	jalr	-1108(ra) # 80000bc2 <acquire>
    8000401e:	b741                	j	80003f9e <iput+0x26>

0000000080004020 <iunlockput>:
{
    80004020:	1101                	addi	sp,sp,-32
    80004022:	ec06                	sd	ra,24(sp)
    80004024:	e822                	sd	s0,16(sp)
    80004026:	e426                	sd	s1,8(sp)
    80004028:	1000                	addi	s0,sp,32
    8000402a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	e54080e7          	jalr	-428(ra) # 80003e80 <iunlock>
  iput(ip);
    80004034:	8526                	mv	a0,s1
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	f42080e7          	jalr	-190(ra) # 80003f78 <iput>
}
    8000403e:	60e2                	ld	ra,24(sp)
    80004040:	6442                	ld	s0,16(sp)
    80004042:	64a2                	ld	s1,8(sp)
    80004044:	6105                	addi	sp,sp,32
    80004046:	8082                	ret

0000000080004048 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004048:	1141                	addi	sp,sp,-16
    8000404a:	e422                	sd	s0,8(sp)
    8000404c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000404e:	411c                	lw	a5,0(a0)
    80004050:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004052:	415c                	lw	a5,4(a0)
    80004054:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004056:	04451783          	lh	a5,68(a0)
    8000405a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000405e:	04a51783          	lh	a5,74(a0)
    80004062:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004066:	04c56783          	lwu	a5,76(a0)
    8000406a:	e99c                	sd	a5,16(a1)
}
    8000406c:	6422                	ld	s0,8(sp)
    8000406e:	0141                	addi	sp,sp,16
    80004070:	8082                	ret

0000000080004072 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004072:	457c                	lw	a5,76(a0)
    80004074:	0ed7e963          	bltu	a5,a3,80004166 <readi+0xf4>
{
    80004078:	7159                	addi	sp,sp,-112
    8000407a:	f486                	sd	ra,104(sp)
    8000407c:	f0a2                	sd	s0,96(sp)
    8000407e:	eca6                	sd	s1,88(sp)
    80004080:	e8ca                	sd	s2,80(sp)
    80004082:	e4ce                	sd	s3,72(sp)
    80004084:	e0d2                	sd	s4,64(sp)
    80004086:	fc56                	sd	s5,56(sp)
    80004088:	f85a                	sd	s6,48(sp)
    8000408a:	f45e                	sd	s7,40(sp)
    8000408c:	f062                	sd	s8,32(sp)
    8000408e:	ec66                	sd	s9,24(sp)
    80004090:	e86a                	sd	s10,16(sp)
    80004092:	e46e                	sd	s11,8(sp)
    80004094:	1880                	addi	s0,sp,112
    80004096:	8baa                	mv	s7,a0
    80004098:	8c2e                	mv	s8,a1
    8000409a:	8ab2                	mv	s5,a2
    8000409c:	84b6                	mv	s1,a3
    8000409e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040a0:	9f35                	addw	a4,a4,a3
    return 0;
    800040a2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040a4:	0ad76063          	bltu	a4,a3,80004144 <readi+0xd2>
  if(off + n > ip->size)
    800040a8:	00e7f463          	bgeu	a5,a4,800040b0 <readi+0x3e>
    n = ip->size - off;
    800040ac:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040b0:	0a0b0963          	beqz	s6,80004162 <readi+0xf0>
    800040b4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040b6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040ba:	5cfd                	li	s9,-1
    800040bc:	a82d                	j	800040f6 <readi+0x84>
    800040be:	020a1d93          	slli	s11,s4,0x20
    800040c2:	020ddd93          	srli	s11,s11,0x20
    800040c6:	05890793          	addi	a5,s2,88
    800040ca:	86ee                	mv	a3,s11
    800040cc:	963e                	add	a2,a2,a5
    800040ce:	85d6                	mv	a1,s5
    800040d0:	8562                	mv	a0,s8
    800040d2:	ffffe097          	auipc	ra,0xffffe
    800040d6:	136080e7          	jalr	310(ra) # 80002208 <either_copyout>
    800040da:	05950d63          	beq	a0,s9,80004134 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040de:	854a                	mv	a0,s2
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	60a080e7          	jalr	1546(ra) # 800036ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040e8:	013a09bb          	addw	s3,s4,s3
    800040ec:	009a04bb          	addw	s1,s4,s1
    800040f0:	9aee                	add	s5,s5,s11
    800040f2:	0569f763          	bgeu	s3,s6,80004140 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040f6:	000ba903          	lw	s2,0(s7)
    800040fa:	00a4d59b          	srliw	a1,s1,0xa
    800040fe:	855e                	mv	a0,s7
    80004100:	00000097          	auipc	ra,0x0
    80004104:	8ae080e7          	jalr	-1874(ra) # 800039ae <bmap>
    80004108:	0005059b          	sext.w	a1,a0
    8000410c:	854a                	mv	a0,s2
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	4ac080e7          	jalr	1196(ra) # 800035ba <bread>
    80004116:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004118:	3ff4f613          	andi	a2,s1,1023
    8000411c:	40cd07bb          	subw	a5,s10,a2
    80004120:	413b073b          	subw	a4,s6,s3
    80004124:	8a3e                	mv	s4,a5
    80004126:	2781                	sext.w	a5,a5
    80004128:	0007069b          	sext.w	a3,a4
    8000412c:	f8f6f9e3          	bgeu	a3,a5,800040be <readi+0x4c>
    80004130:	8a3a                	mv	s4,a4
    80004132:	b771                	j	800040be <readi+0x4c>
      brelse(bp);
    80004134:	854a                	mv	a0,s2
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	5b4080e7          	jalr	1460(ra) # 800036ea <brelse>
      tot = -1;
    8000413e:	59fd                	li	s3,-1
  }
  return tot;
    80004140:	0009851b          	sext.w	a0,s3
}
    80004144:	70a6                	ld	ra,104(sp)
    80004146:	7406                	ld	s0,96(sp)
    80004148:	64e6                	ld	s1,88(sp)
    8000414a:	6946                	ld	s2,80(sp)
    8000414c:	69a6                	ld	s3,72(sp)
    8000414e:	6a06                	ld	s4,64(sp)
    80004150:	7ae2                	ld	s5,56(sp)
    80004152:	7b42                	ld	s6,48(sp)
    80004154:	7ba2                	ld	s7,40(sp)
    80004156:	7c02                	ld	s8,32(sp)
    80004158:	6ce2                	ld	s9,24(sp)
    8000415a:	6d42                	ld	s10,16(sp)
    8000415c:	6da2                	ld	s11,8(sp)
    8000415e:	6165                	addi	sp,sp,112
    80004160:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004162:	89da                	mv	s3,s6
    80004164:	bff1                	j	80004140 <readi+0xce>
    return 0;
    80004166:	4501                	li	a0,0
}
    80004168:	8082                	ret

000000008000416a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000416a:	457c                	lw	a5,76(a0)
    8000416c:	10d7e863          	bltu	a5,a3,8000427c <writei+0x112>
{
    80004170:	7159                	addi	sp,sp,-112
    80004172:	f486                	sd	ra,104(sp)
    80004174:	f0a2                	sd	s0,96(sp)
    80004176:	eca6                	sd	s1,88(sp)
    80004178:	e8ca                	sd	s2,80(sp)
    8000417a:	e4ce                	sd	s3,72(sp)
    8000417c:	e0d2                	sd	s4,64(sp)
    8000417e:	fc56                	sd	s5,56(sp)
    80004180:	f85a                	sd	s6,48(sp)
    80004182:	f45e                	sd	s7,40(sp)
    80004184:	f062                	sd	s8,32(sp)
    80004186:	ec66                	sd	s9,24(sp)
    80004188:	e86a                	sd	s10,16(sp)
    8000418a:	e46e                	sd	s11,8(sp)
    8000418c:	1880                	addi	s0,sp,112
    8000418e:	8b2a                	mv	s6,a0
    80004190:	8c2e                	mv	s8,a1
    80004192:	8ab2                	mv	s5,a2
    80004194:	8936                	mv	s2,a3
    80004196:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004198:	00e687bb          	addw	a5,a3,a4
    8000419c:	0ed7e263          	bltu	a5,a3,80004280 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041a0:	00043737          	lui	a4,0x43
    800041a4:	0ef76063          	bltu	a4,a5,80004284 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a8:	0c0b8863          	beqz	s7,80004278 <writei+0x10e>
    800041ac:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ae:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041b2:	5cfd                	li	s9,-1
    800041b4:	a091                	j	800041f8 <writei+0x8e>
    800041b6:	02099d93          	slli	s11,s3,0x20
    800041ba:	020ddd93          	srli	s11,s11,0x20
    800041be:	05848793          	addi	a5,s1,88
    800041c2:	86ee                	mv	a3,s11
    800041c4:	8656                	mv	a2,s5
    800041c6:	85e2                	mv	a1,s8
    800041c8:	953e                	add	a0,a0,a5
    800041ca:	ffffe097          	auipc	ra,0xffffe
    800041ce:	094080e7          	jalr	148(ra) # 8000225e <either_copyin>
    800041d2:	07950263          	beq	a0,s9,80004236 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041d6:	8526                	mv	a0,s1
    800041d8:	00001097          	auipc	ra,0x1
    800041dc:	aa6080e7          	jalr	-1370(ra) # 80004c7e <log_write>
    brelse(bp);
    800041e0:	8526                	mv	a0,s1
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	508080e7          	jalr	1288(ra) # 800036ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041ea:	01498a3b          	addw	s4,s3,s4
    800041ee:	0129893b          	addw	s2,s3,s2
    800041f2:	9aee                	add	s5,s5,s11
    800041f4:	057a7663          	bgeu	s4,s7,80004240 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800041f8:	000b2483          	lw	s1,0(s6)
    800041fc:	00a9559b          	srliw	a1,s2,0xa
    80004200:	855a                	mv	a0,s6
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	7ac080e7          	jalr	1964(ra) # 800039ae <bmap>
    8000420a:	0005059b          	sext.w	a1,a0
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	3aa080e7          	jalr	938(ra) # 800035ba <bread>
    80004218:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000421a:	3ff97513          	andi	a0,s2,1023
    8000421e:	40ad07bb          	subw	a5,s10,a0
    80004222:	414b873b          	subw	a4,s7,s4
    80004226:	89be                	mv	s3,a5
    80004228:	2781                	sext.w	a5,a5
    8000422a:	0007069b          	sext.w	a3,a4
    8000422e:	f8f6f4e3          	bgeu	a3,a5,800041b6 <writei+0x4c>
    80004232:	89ba                	mv	s3,a4
    80004234:	b749                	j	800041b6 <writei+0x4c>
      brelse(bp);
    80004236:	8526                	mv	a0,s1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	4b2080e7          	jalr	1202(ra) # 800036ea <brelse>
  }

  if(off > ip->size)
    80004240:	04cb2783          	lw	a5,76(s6)
    80004244:	0127f463          	bgeu	a5,s2,8000424c <writei+0xe2>
    ip->size = off;
    80004248:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000424c:	855a                	mv	a0,s6
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	aa6080e7          	jalr	-1370(ra) # 80003cf4 <iupdate>

  return tot;
    80004256:	000a051b          	sext.w	a0,s4
}
    8000425a:	70a6                	ld	ra,104(sp)
    8000425c:	7406                	ld	s0,96(sp)
    8000425e:	64e6                	ld	s1,88(sp)
    80004260:	6946                	ld	s2,80(sp)
    80004262:	69a6                	ld	s3,72(sp)
    80004264:	6a06                	ld	s4,64(sp)
    80004266:	7ae2                	ld	s5,56(sp)
    80004268:	7b42                	ld	s6,48(sp)
    8000426a:	7ba2                	ld	s7,40(sp)
    8000426c:	7c02                	ld	s8,32(sp)
    8000426e:	6ce2                	ld	s9,24(sp)
    80004270:	6d42                	ld	s10,16(sp)
    80004272:	6da2                	ld	s11,8(sp)
    80004274:	6165                	addi	sp,sp,112
    80004276:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004278:	8a5e                	mv	s4,s7
    8000427a:	bfc9                	j	8000424c <writei+0xe2>
    return -1;
    8000427c:	557d                	li	a0,-1
}
    8000427e:	8082                	ret
    return -1;
    80004280:	557d                	li	a0,-1
    80004282:	bfe1                	j	8000425a <writei+0xf0>
    return -1;
    80004284:	557d                	li	a0,-1
    80004286:	bfd1                	j	8000425a <writei+0xf0>

0000000080004288 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004288:	1141                	addi	sp,sp,-16
    8000428a:	e406                	sd	ra,8(sp)
    8000428c:	e022                	sd	s0,0(sp)
    8000428e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004290:	4639                	li	a2,14
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	b04080e7          	jalr	-1276(ra) # 80000d96 <strncmp>
}
    8000429a:	60a2                	ld	ra,8(sp)
    8000429c:	6402                	ld	s0,0(sp)
    8000429e:	0141                	addi	sp,sp,16
    800042a0:	8082                	ret

00000000800042a2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042a2:	7139                	addi	sp,sp,-64
    800042a4:	fc06                	sd	ra,56(sp)
    800042a6:	f822                	sd	s0,48(sp)
    800042a8:	f426                	sd	s1,40(sp)
    800042aa:	f04a                	sd	s2,32(sp)
    800042ac:	ec4e                	sd	s3,24(sp)
    800042ae:	e852                	sd	s4,16(sp)
    800042b0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042b2:	04451703          	lh	a4,68(a0)
    800042b6:	4785                	li	a5,1
    800042b8:	00f71a63          	bne	a4,a5,800042cc <dirlookup+0x2a>
    800042bc:	892a                	mv	s2,a0
    800042be:	89ae                	mv	s3,a1
    800042c0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c2:	457c                	lw	a5,76(a0)
    800042c4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042c6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c8:	e79d                	bnez	a5,800042f6 <dirlookup+0x54>
    800042ca:	a8a5                	j	80004342 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042cc:	00004517          	auipc	a0,0x4
    800042d0:	5cc50513          	addi	a0,a0,1484 # 80008898 <syscalls+0x1a0>
    800042d4:	ffffc097          	auipc	ra,0xffffc
    800042d8:	256080e7          	jalr	598(ra) # 8000052a <panic>
      panic("dirlookup read");
    800042dc:	00004517          	auipc	a0,0x4
    800042e0:	5d450513          	addi	a0,a0,1492 # 800088b0 <syscalls+0x1b8>
    800042e4:	ffffc097          	auipc	ra,0xffffc
    800042e8:	246080e7          	jalr	582(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ec:	24c1                	addiw	s1,s1,16
    800042ee:	04c92783          	lw	a5,76(s2)
    800042f2:	04f4f763          	bgeu	s1,a5,80004340 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f6:	4741                	li	a4,16
    800042f8:	86a6                	mv	a3,s1
    800042fa:	fc040613          	addi	a2,s0,-64
    800042fe:	4581                	li	a1,0
    80004300:	854a                	mv	a0,s2
    80004302:	00000097          	auipc	ra,0x0
    80004306:	d70080e7          	jalr	-656(ra) # 80004072 <readi>
    8000430a:	47c1                	li	a5,16
    8000430c:	fcf518e3          	bne	a0,a5,800042dc <dirlookup+0x3a>
    if(de.inum == 0)
    80004310:	fc045783          	lhu	a5,-64(s0)
    80004314:	dfe1                	beqz	a5,800042ec <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004316:	fc240593          	addi	a1,s0,-62
    8000431a:	854e                	mv	a0,s3
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	f6c080e7          	jalr	-148(ra) # 80004288 <namecmp>
    80004324:	f561                	bnez	a0,800042ec <dirlookup+0x4a>
      if(poff)
    80004326:	000a0463          	beqz	s4,8000432e <dirlookup+0x8c>
        *poff = off;
    8000432a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000432e:	fc045583          	lhu	a1,-64(s0)
    80004332:	00092503          	lw	a0,0(s2)
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	754080e7          	jalr	1876(ra) # 80003a8a <iget>
    8000433e:	a011                	j	80004342 <dirlookup+0xa0>
  return 0;
    80004340:	4501                	li	a0,0
}
    80004342:	70e2                	ld	ra,56(sp)
    80004344:	7442                	ld	s0,48(sp)
    80004346:	74a2                	ld	s1,40(sp)
    80004348:	7902                	ld	s2,32(sp)
    8000434a:	69e2                	ld	s3,24(sp)
    8000434c:	6a42                	ld	s4,16(sp)
    8000434e:	6121                	addi	sp,sp,64
    80004350:	8082                	ret

0000000080004352 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004352:	711d                	addi	sp,sp,-96
    80004354:	ec86                	sd	ra,88(sp)
    80004356:	e8a2                	sd	s0,80(sp)
    80004358:	e4a6                	sd	s1,72(sp)
    8000435a:	e0ca                	sd	s2,64(sp)
    8000435c:	fc4e                	sd	s3,56(sp)
    8000435e:	f852                	sd	s4,48(sp)
    80004360:	f456                	sd	s5,40(sp)
    80004362:	f05a                	sd	s6,32(sp)
    80004364:	ec5e                	sd	s7,24(sp)
    80004366:	e862                	sd	s8,16(sp)
    80004368:	e466                	sd	s9,8(sp)
    8000436a:	1080                	addi	s0,sp,96
    8000436c:	84aa                	mv	s1,a0
    8000436e:	8aae                	mv	s5,a1
    80004370:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004372:	00054703          	lbu	a4,0(a0)
    80004376:	02f00793          	li	a5,47
    8000437a:	02f70363          	beq	a4,a5,800043a0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	656080e7          	jalr	1622(ra) # 800019d4 <myproc>
    80004386:	15053503          	ld	a0,336(a0)
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	9f6080e7          	jalr	-1546(ra) # 80003d80 <idup>
    80004392:	89aa                	mv	s3,a0
  while(*path == '/')
    80004394:	02f00913          	li	s2,47
  len = path - s;
    80004398:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000439a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000439c:	4b85                	li	s7,1
    8000439e:	a865                	j	80004456 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043a0:	4585                	li	a1,1
    800043a2:	4505                	li	a0,1
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	6e6080e7          	jalr	1766(ra) # 80003a8a <iget>
    800043ac:	89aa                	mv	s3,a0
    800043ae:	b7dd                	j	80004394 <namex+0x42>
      iunlockput(ip);
    800043b0:	854e                	mv	a0,s3
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	c6e080e7          	jalr	-914(ra) # 80004020 <iunlockput>
      return 0;
    800043ba:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043bc:	854e                	mv	a0,s3
    800043be:	60e6                	ld	ra,88(sp)
    800043c0:	6446                	ld	s0,80(sp)
    800043c2:	64a6                	ld	s1,72(sp)
    800043c4:	6906                	ld	s2,64(sp)
    800043c6:	79e2                	ld	s3,56(sp)
    800043c8:	7a42                	ld	s4,48(sp)
    800043ca:	7aa2                	ld	s5,40(sp)
    800043cc:	7b02                	ld	s6,32(sp)
    800043ce:	6be2                	ld	s7,24(sp)
    800043d0:	6c42                	ld	s8,16(sp)
    800043d2:	6ca2                	ld	s9,8(sp)
    800043d4:	6125                	addi	sp,sp,96
    800043d6:	8082                	ret
      iunlock(ip);
    800043d8:	854e                	mv	a0,s3
    800043da:	00000097          	auipc	ra,0x0
    800043de:	aa6080e7          	jalr	-1370(ra) # 80003e80 <iunlock>
      return ip;
    800043e2:	bfe9                	j	800043bc <namex+0x6a>
      iunlockput(ip);
    800043e4:	854e                	mv	a0,s3
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	c3a080e7          	jalr	-966(ra) # 80004020 <iunlockput>
      return 0;
    800043ee:	89e6                	mv	s3,s9
    800043f0:	b7f1                	j	800043bc <namex+0x6a>
  len = path - s;
    800043f2:	40b48633          	sub	a2,s1,a1
    800043f6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800043fa:	099c5463          	bge	s8,s9,80004482 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800043fe:	4639                	li	a2,14
    80004400:	8552                	mv	a0,s4
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	918080e7          	jalr	-1768(ra) # 80000d1a <memmove>
  while(*path == '/')
    8000440a:	0004c783          	lbu	a5,0(s1)
    8000440e:	01279763          	bne	a5,s2,8000441c <namex+0xca>
    path++;
    80004412:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004414:	0004c783          	lbu	a5,0(s1)
    80004418:	ff278de3          	beq	a5,s2,80004412 <namex+0xc0>
    ilock(ip);
    8000441c:	854e                	mv	a0,s3
    8000441e:	00000097          	auipc	ra,0x0
    80004422:	9a0080e7          	jalr	-1632(ra) # 80003dbe <ilock>
    if(ip->type != T_DIR){
    80004426:	04499783          	lh	a5,68(s3)
    8000442a:	f97793e3          	bne	a5,s7,800043b0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000442e:	000a8563          	beqz	s5,80004438 <namex+0xe6>
    80004432:	0004c783          	lbu	a5,0(s1)
    80004436:	d3cd                	beqz	a5,800043d8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004438:	865a                	mv	a2,s6
    8000443a:	85d2                	mv	a1,s4
    8000443c:	854e                	mv	a0,s3
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	e64080e7          	jalr	-412(ra) # 800042a2 <dirlookup>
    80004446:	8caa                	mv	s9,a0
    80004448:	dd51                	beqz	a0,800043e4 <namex+0x92>
    iunlockput(ip);
    8000444a:	854e                	mv	a0,s3
    8000444c:	00000097          	auipc	ra,0x0
    80004450:	bd4080e7          	jalr	-1068(ra) # 80004020 <iunlockput>
    ip = next;
    80004454:	89e6                	mv	s3,s9
  while(*path == '/')
    80004456:	0004c783          	lbu	a5,0(s1)
    8000445a:	05279763          	bne	a5,s2,800044a8 <namex+0x156>
    path++;
    8000445e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004460:	0004c783          	lbu	a5,0(s1)
    80004464:	ff278de3          	beq	a5,s2,8000445e <namex+0x10c>
  if(*path == 0)
    80004468:	c79d                	beqz	a5,80004496 <namex+0x144>
    path++;
    8000446a:	85a6                	mv	a1,s1
  len = path - s;
    8000446c:	8cda                	mv	s9,s6
    8000446e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004470:	01278963          	beq	a5,s2,80004482 <namex+0x130>
    80004474:	dfbd                	beqz	a5,800043f2 <namex+0xa0>
    path++;
    80004476:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004478:	0004c783          	lbu	a5,0(s1)
    8000447c:	ff279ce3          	bne	a5,s2,80004474 <namex+0x122>
    80004480:	bf8d                	j	800043f2 <namex+0xa0>
    memmove(name, s, len);
    80004482:	2601                	sext.w	a2,a2
    80004484:	8552                	mv	a0,s4
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	894080e7          	jalr	-1900(ra) # 80000d1a <memmove>
    name[len] = 0;
    8000448e:	9cd2                	add	s9,s9,s4
    80004490:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004494:	bf9d                	j	8000440a <namex+0xb8>
  if(nameiparent){
    80004496:	f20a83e3          	beqz	s5,800043bc <namex+0x6a>
    iput(ip);
    8000449a:	854e                	mv	a0,s3
    8000449c:	00000097          	auipc	ra,0x0
    800044a0:	adc080e7          	jalr	-1316(ra) # 80003f78 <iput>
    return 0;
    800044a4:	4981                	li	s3,0
    800044a6:	bf19                	j	800043bc <namex+0x6a>
  if(*path == 0)
    800044a8:	d7fd                	beqz	a5,80004496 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044aa:	0004c783          	lbu	a5,0(s1)
    800044ae:	85a6                	mv	a1,s1
    800044b0:	b7d1                	j	80004474 <namex+0x122>

00000000800044b2 <dirlink>:
{
    800044b2:	7139                	addi	sp,sp,-64
    800044b4:	fc06                	sd	ra,56(sp)
    800044b6:	f822                	sd	s0,48(sp)
    800044b8:	f426                	sd	s1,40(sp)
    800044ba:	f04a                	sd	s2,32(sp)
    800044bc:	ec4e                	sd	s3,24(sp)
    800044be:	e852                	sd	s4,16(sp)
    800044c0:	0080                	addi	s0,sp,64
    800044c2:	892a                	mv	s2,a0
    800044c4:	8a2e                	mv	s4,a1
    800044c6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044c8:	4601                	li	a2,0
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	dd8080e7          	jalr	-552(ra) # 800042a2 <dirlookup>
    800044d2:	e93d                	bnez	a0,80004548 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044d4:	04c92483          	lw	s1,76(s2)
    800044d8:	c49d                	beqz	s1,80004506 <dirlink+0x54>
    800044da:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044dc:	4741                	li	a4,16
    800044de:	86a6                	mv	a3,s1
    800044e0:	fc040613          	addi	a2,s0,-64
    800044e4:	4581                	li	a1,0
    800044e6:	854a                	mv	a0,s2
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	b8a080e7          	jalr	-1142(ra) # 80004072 <readi>
    800044f0:	47c1                	li	a5,16
    800044f2:	06f51163          	bne	a0,a5,80004554 <dirlink+0xa2>
    if(de.inum == 0)
    800044f6:	fc045783          	lhu	a5,-64(s0)
    800044fa:	c791                	beqz	a5,80004506 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044fc:	24c1                	addiw	s1,s1,16
    800044fe:	04c92783          	lw	a5,76(s2)
    80004502:	fcf4ede3          	bltu	s1,a5,800044dc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004506:	4639                	li	a2,14
    80004508:	85d2                	mv	a1,s4
    8000450a:	fc240513          	addi	a0,s0,-62
    8000450e:	ffffd097          	auipc	ra,0xffffd
    80004512:	8c4080e7          	jalr	-1852(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004516:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000451a:	4741                	li	a4,16
    8000451c:	86a6                	mv	a3,s1
    8000451e:	fc040613          	addi	a2,s0,-64
    80004522:	4581                	li	a1,0
    80004524:	854a                	mv	a0,s2
    80004526:	00000097          	auipc	ra,0x0
    8000452a:	c44080e7          	jalr	-956(ra) # 8000416a <writei>
    8000452e:	872a                	mv	a4,a0
    80004530:	47c1                	li	a5,16
  return 0;
    80004532:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004534:	02f71863          	bne	a4,a5,80004564 <dirlink+0xb2>
}
    80004538:	70e2                	ld	ra,56(sp)
    8000453a:	7442                	ld	s0,48(sp)
    8000453c:	74a2                	ld	s1,40(sp)
    8000453e:	7902                	ld	s2,32(sp)
    80004540:	69e2                	ld	s3,24(sp)
    80004542:	6a42                	ld	s4,16(sp)
    80004544:	6121                	addi	sp,sp,64
    80004546:	8082                	ret
    iput(ip);
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	a30080e7          	jalr	-1488(ra) # 80003f78 <iput>
    return -1;
    80004550:	557d                	li	a0,-1
    80004552:	b7dd                	j	80004538 <dirlink+0x86>
      panic("dirlink read");
    80004554:	00004517          	auipc	a0,0x4
    80004558:	36c50513          	addi	a0,a0,876 # 800088c0 <syscalls+0x1c8>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	fce080e7          	jalr	-50(ra) # 8000052a <panic>
    panic("dirlink");
    80004564:	00004517          	auipc	a0,0x4
    80004568:	4e450513          	addi	a0,a0,1252 # 80008a48 <syscalls+0x350>
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	fbe080e7          	jalr	-66(ra) # 8000052a <panic>

0000000080004574 <namei>:

struct inode*
namei(char *path)
{
    80004574:	1101                	addi	sp,sp,-32
    80004576:	ec06                	sd	ra,24(sp)
    80004578:	e822                	sd	s0,16(sp)
    8000457a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000457c:	fe040613          	addi	a2,s0,-32
    80004580:	4581                	li	a1,0
    80004582:	00000097          	auipc	ra,0x0
    80004586:	dd0080e7          	jalr	-560(ra) # 80004352 <namex>
}
    8000458a:	60e2                	ld	ra,24(sp)
    8000458c:	6442                	ld	s0,16(sp)
    8000458e:	6105                	addi	sp,sp,32
    80004590:	8082                	ret

0000000080004592 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004592:	1141                	addi	sp,sp,-16
    80004594:	e406                	sd	ra,8(sp)
    80004596:	e022                	sd	s0,0(sp)
    80004598:	0800                	addi	s0,sp,16
    8000459a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000459c:	4585                	li	a1,1
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	db4080e7          	jalr	-588(ra) # 80004352 <namex>
}
    800045a6:	60a2                	ld	ra,8(sp)
    800045a8:	6402                	ld	s0,0(sp)
    800045aa:	0141                	addi	sp,sp,16
    800045ac:	8082                	ret

00000000800045ae <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800045ae:	1101                	addi	sp,sp,-32
    800045b0:	ec22                	sd	s0,24(sp)
    800045b2:	1000                	addi	s0,sp,32
    800045b4:	872a                	mv	a4,a0
    800045b6:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800045b8:	00004797          	auipc	a5,0x4
    800045bc:	31878793          	addi	a5,a5,792 # 800088d0 <syscalls+0x1d8>
    800045c0:	6394                	ld	a3,0(a5)
    800045c2:	fed43023          	sd	a3,-32(s0)
    800045c6:	0087d683          	lhu	a3,8(a5)
    800045ca:	fed41423          	sh	a3,-24(s0)
    800045ce:	00a7c783          	lbu	a5,10(a5)
    800045d2:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800045d6:	87ae                	mv	a5,a1
    if(i<0){
    800045d8:	02074b63          	bltz	a4,8000460e <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800045dc:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800045de:	4629                	li	a2,10
        ++p;
    800045e0:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800045e2:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800045e6:	feed                	bnez	a3,800045e0 <itoa+0x32>
    *p = '\0';
    800045e8:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800045ec:	4629                	li	a2,10
    800045ee:	17fd                	addi	a5,a5,-1
    800045f0:	02c766bb          	remw	a3,a4,a2
    800045f4:	ff040593          	addi	a1,s0,-16
    800045f8:	96ae                	add	a3,a3,a1
    800045fa:	ff06c683          	lbu	a3,-16(a3)
    800045fe:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004602:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004606:	f765                	bnez	a4,800045ee <itoa+0x40>
    return b;
}
    80004608:	6462                	ld	s0,24(sp)
    8000460a:	6105                	addi	sp,sp,32
    8000460c:	8082                	ret
        *p++ = '-';
    8000460e:	00158793          	addi	a5,a1,1
    80004612:	02d00693          	li	a3,45
    80004616:	00d58023          	sb	a3,0(a1)
        i *= -1;
    8000461a:	40e0073b          	negw	a4,a4
    8000461e:	bf7d                	j	800045dc <itoa+0x2e>

0000000080004620 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004620:	711d                	addi	sp,sp,-96
    80004622:	ec86                	sd	ra,88(sp)
    80004624:	e8a2                	sd	s0,80(sp)
    80004626:	e4a6                	sd	s1,72(sp)
    80004628:	e0ca                	sd	s2,64(sp)
    8000462a:	1080                	addi	s0,sp,96
    8000462c:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000462e:	4619                	li	a2,6
    80004630:	00004597          	auipc	a1,0x4
    80004634:	2b058593          	addi	a1,a1,688 # 800088e0 <syscalls+0x1e8>
    80004638:	fd040513          	addi	a0,s0,-48
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	6de080e7          	jalr	1758(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004644:	fd640593          	addi	a1,s0,-42
    80004648:	5888                	lw	a0,48(s1)
    8000464a:	00000097          	auipc	ra,0x0
    8000464e:	f64080e7          	jalr	-156(ra) # 800045ae <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004652:	1684b503          	ld	a0,360(s1)
    80004656:	16050763          	beqz	a0,800047c4 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000465a:	00001097          	auipc	ra,0x1
    8000465e:	918080e7          	jalr	-1768(ra) # 80004f72 <fileclose>

  begin_op();
    80004662:	00000097          	auipc	ra,0x0
    80004666:	444080e7          	jalr	1092(ra) # 80004aa6 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000466a:	fb040593          	addi	a1,s0,-80
    8000466e:	fd040513          	addi	a0,s0,-48
    80004672:	00000097          	auipc	ra,0x0
    80004676:	f20080e7          	jalr	-224(ra) # 80004592 <nameiparent>
    8000467a:	892a                	mv	s2,a0
    8000467c:	cd69                	beqz	a0,80004756 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	740080e7          	jalr	1856(ra) # 80003dbe <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004686:	00004597          	auipc	a1,0x4
    8000468a:	26258593          	addi	a1,a1,610 # 800088e8 <syscalls+0x1f0>
    8000468e:	fb040513          	addi	a0,s0,-80
    80004692:	00000097          	auipc	ra,0x0
    80004696:	bf6080e7          	jalr	-1034(ra) # 80004288 <namecmp>
    8000469a:	c57d                	beqz	a0,80004788 <removeSwapFile+0x168>
    8000469c:	00004597          	auipc	a1,0x4
    800046a0:	25458593          	addi	a1,a1,596 # 800088f0 <syscalls+0x1f8>
    800046a4:	fb040513          	addi	a0,s0,-80
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	be0080e7          	jalr	-1056(ra) # 80004288 <namecmp>
    800046b0:	cd61                	beqz	a0,80004788 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800046b2:	fac40613          	addi	a2,s0,-84
    800046b6:	fb040593          	addi	a1,s0,-80
    800046ba:	854a                	mv	a0,s2
    800046bc:	00000097          	auipc	ra,0x0
    800046c0:	be6080e7          	jalr	-1050(ra) # 800042a2 <dirlookup>
    800046c4:	84aa                	mv	s1,a0
    800046c6:	c169                	beqz	a0,80004788 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	6f6080e7          	jalr	1782(ra) # 80003dbe <ilock>

  if(ip->nlink < 1)
    800046d0:	04a49783          	lh	a5,74(s1)
    800046d4:	08f05763          	blez	a5,80004762 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800046d8:	04449703          	lh	a4,68(s1)
    800046dc:	4785                	li	a5,1
    800046de:	08f70a63          	beq	a4,a5,80004772 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800046e2:	4641                	li	a2,16
    800046e4:	4581                	li	a1,0
    800046e6:	fc040513          	addi	a0,s0,-64
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	5d4080e7          	jalr	1492(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046f2:	4741                	li	a4,16
    800046f4:	fac42683          	lw	a3,-84(s0)
    800046f8:	fc040613          	addi	a2,s0,-64
    800046fc:	4581                	li	a1,0
    800046fe:	854a                	mv	a0,s2
    80004700:	00000097          	auipc	ra,0x0
    80004704:	a6a080e7          	jalr	-1430(ra) # 8000416a <writei>
    80004708:	47c1                	li	a5,16
    8000470a:	08f51a63          	bne	a0,a5,8000479e <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    8000470e:	04449703          	lh	a4,68(s1)
    80004712:	4785                	li	a5,1
    80004714:	08f70d63          	beq	a4,a5,800047ae <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004718:	854a                	mv	a0,s2
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	906080e7          	jalr	-1786(ra) # 80004020 <iunlockput>

  ip->nlink--;
    80004722:	04a4d783          	lhu	a5,74(s1)
    80004726:	37fd                	addiw	a5,a5,-1
    80004728:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000472c:	8526                	mv	a0,s1
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	5c6080e7          	jalr	1478(ra) # 80003cf4 <iupdate>
  iunlockput(ip);
    80004736:	8526                	mv	a0,s1
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	8e8080e7          	jalr	-1816(ra) # 80004020 <iunlockput>

  end_op();
    80004740:	00000097          	auipc	ra,0x0
    80004744:	3e6080e7          	jalr	998(ra) # 80004b26 <end_op>

  return 0;
    80004748:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    8000474a:	60e6                	ld	ra,88(sp)
    8000474c:	6446                	ld	s0,80(sp)
    8000474e:	64a6                	ld	s1,72(sp)
    80004750:	6906                	ld	s2,64(sp)
    80004752:	6125                	addi	sp,sp,96
    80004754:	8082                	ret
    end_op();
    80004756:	00000097          	auipc	ra,0x0
    8000475a:	3d0080e7          	jalr	976(ra) # 80004b26 <end_op>
    return -1;
    8000475e:	557d                	li	a0,-1
    80004760:	b7ed                	j	8000474a <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004762:	00004517          	auipc	a0,0x4
    80004766:	19650513          	addi	a0,a0,406 # 800088f8 <syscalls+0x200>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	dc0080e7          	jalr	-576(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004772:	8526                	mv	a0,s1
    80004774:	00002097          	auipc	ra,0x2
    80004778:	866080e7          	jalr	-1946(ra) # 80005fda <isdirempty>
    8000477c:	f13d                	bnez	a0,800046e2 <removeSwapFile+0xc2>
    iunlockput(ip);
    8000477e:	8526                	mv	a0,s1
    80004780:	00000097          	auipc	ra,0x0
    80004784:	8a0080e7          	jalr	-1888(ra) # 80004020 <iunlockput>
    iunlockput(dp);
    80004788:	854a                	mv	a0,s2
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	896080e7          	jalr	-1898(ra) # 80004020 <iunlockput>
    end_op();
    80004792:	00000097          	auipc	ra,0x0
    80004796:	394080e7          	jalr	916(ra) # 80004b26 <end_op>
    return -1;
    8000479a:	557d                	li	a0,-1
    8000479c:	b77d                	j	8000474a <removeSwapFile+0x12a>
    panic("unlink: writei");
    8000479e:	00004517          	auipc	a0,0x4
    800047a2:	17250513          	addi	a0,a0,370 # 80008910 <syscalls+0x218>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	d84080e7          	jalr	-636(ra) # 8000052a <panic>
    dp->nlink--;
    800047ae:	04a95783          	lhu	a5,74(s2)
    800047b2:	37fd                	addiw	a5,a5,-1
    800047b4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800047b8:	854a                	mv	a0,s2
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	53a080e7          	jalr	1338(ra) # 80003cf4 <iupdate>
    800047c2:	bf99                	j	80004718 <removeSwapFile+0xf8>
    return -1;
    800047c4:	557d                	li	a0,-1
    800047c6:	b751                	j	8000474a <removeSwapFile+0x12a>

00000000800047c8 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800047c8:	7179                	addi	sp,sp,-48
    800047ca:	f406                	sd	ra,40(sp)
    800047cc:	f022                	sd	s0,32(sp)
    800047ce:	ec26                	sd	s1,24(sp)
    800047d0:	e84a                	sd	s2,16(sp)
    800047d2:	1800                	addi	s0,sp,48
    800047d4:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800047d6:	4619                	li	a2,6
    800047d8:	00004597          	auipc	a1,0x4
    800047dc:	10858593          	addi	a1,a1,264 # 800088e0 <syscalls+0x1e8>
    800047e0:	fd040513          	addi	a0,s0,-48
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	536080e7          	jalr	1334(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800047ec:	fd640593          	addi	a1,s0,-42
    800047f0:	5888                	lw	a0,48(s1)
    800047f2:	00000097          	auipc	ra,0x0
    800047f6:	dbc080e7          	jalr	-580(ra) # 800045ae <itoa>

  begin_op();
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	2ac080e7          	jalr	684(ra) # 80004aa6 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004802:	4681                	li	a3,0
    80004804:	4601                	li	a2,0
    80004806:	4589                	li	a1,2
    80004808:	fd040513          	addi	a0,s0,-48
    8000480c:	00002097          	auipc	ra,0x2
    80004810:	9c2080e7          	jalr	-1598(ra) # 800061ce <create>
    80004814:	892a                	mv	s2,a0
  iunlock(in);
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	66a080e7          	jalr	1642(ra) # 80003e80 <iunlock>
  p->swapFile = filealloc();
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	698080e7          	jalr	1688(ra) # 80004eb6 <filealloc>
    80004826:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    8000482a:	cd1d                	beqz	a0,80004868 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000482c:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004830:	1684b703          	ld	a4,360(s1)
    80004834:	4789                	li	a5,2
    80004836:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004838:	1684b703          	ld	a4,360(s1)
    8000483c:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004840:	1684b703          	ld	a4,360(s1)
    80004844:	4685                	li	a3,1
    80004846:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    8000484a:	1684b703          	ld	a4,360(s1)
    8000484e:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004852:	00000097          	auipc	ra,0x0
    80004856:	2d4080e7          	jalr	724(ra) # 80004b26 <end_op>

    return 0;
}
    8000485a:	4501                	li	a0,0
    8000485c:	70a2                	ld	ra,40(sp)
    8000485e:	7402                	ld	s0,32(sp)
    80004860:	64e2                	ld	s1,24(sp)
    80004862:	6942                	ld	s2,16(sp)
    80004864:	6145                	addi	sp,sp,48
    80004866:	8082                	ret
    panic("no slot for files on /store");
    80004868:	00004517          	auipc	a0,0x4
    8000486c:	0b850513          	addi	a0,a0,184 # 80008920 <syscalls+0x228>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	cba080e7          	jalr	-838(ra) # 8000052a <panic>

0000000080004878 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004878:	1141                	addi	sp,sp,-16
    8000487a:	e406                	sd	ra,8(sp)
    8000487c:	e022                	sd	s0,0(sp)
    8000487e:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004880:	16853783          	ld	a5,360(a0)
    80004884:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004886:	8636                	mv	a2,a3
    80004888:	16853503          	ld	a0,360(a0)
    8000488c:	00001097          	auipc	ra,0x1
    80004890:	ad8080e7          	jalr	-1320(ra) # 80005364 <kfilewrite>
}
    80004894:	60a2                	ld	ra,8(sp)
    80004896:	6402                	ld	s0,0(sp)
    80004898:	0141                	addi	sp,sp,16
    8000489a:	8082                	ret

000000008000489c <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    8000489c:	1141                	addi	sp,sp,-16
    8000489e:	e406                	sd	ra,8(sp)
    800048a0:	e022                	sd	s0,0(sp)
    800048a2:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800048a4:	16853783          	ld	a5,360(a0)
    800048a8:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    800048aa:	8636                	mv	a2,a3
    800048ac:	16853503          	ld	a0,360(a0)
    800048b0:	00001097          	auipc	ra,0x1
    800048b4:	9f2080e7          	jalr	-1550(ra) # 800052a2 <kfileread>
    800048b8:	60a2                	ld	ra,8(sp)
    800048ba:	6402                	ld	s0,0(sp)
    800048bc:	0141                	addi	sp,sp,16
    800048be:	8082                	ret

00000000800048c0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800048c0:	1101                	addi	sp,sp,-32
    800048c2:	ec06                	sd	ra,24(sp)
    800048c4:	e822                	sd	s0,16(sp)
    800048c6:	e426                	sd	s1,8(sp)
    800048c8:	e04a                	sd	s2,0(sp)
    800048ca:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800048cc:	00025917          	auipc	s2,0x25
    800048d0:	da490913          	addi	s2,s2,-604 # 80029670 <log>
    800048d4:	01892583          	lw	a1,24(s2)
    800048d8:	02892503          	lw	a0,40(s2)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	cde080e7          	jalr	-802(ra) # 800035ba <bread>
    800048e4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800048e6:	02c92683          	lw	a3,44(s2)
    800048ea:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800048ec:	02d05863          	blez	a3,8000491c <write_head+0x5c>
    800048f0:	00025797          	auipc	a5,0x25
    800048f4:	db078793          	addi	a5,a5,-592 # 800296a0 <log+0x30>
    800048f8:	05c50713          	addi	a4,a0,92
    800048fc:	36fd                	addiw	a3,a3,-1
    800048fe:	02069613          	slli	a2,a3,0x20
    80004902:	01e65693          	srli	a3,a2,0x1e
    80004906:	00025617          	auipc	a2,0x25
    8000490a:	d9e60613          	addi	a2,a2,-610 # 800296a4 <log+0x34>
    8000490e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004910:	4390                	lw	a2,0(a5)
    80004912:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004914:	0791                	addi	a5,a5,4
    80004916:	0711                	addi	a4,a4,4
    80004918:	fed79ce3          	bne	a5,a3,80004910 <write_head+0x50>
  }
  bwrite(buf);
    8000491c:	8526                	mv	a0,s1
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	d8e080e7          	jalr	-626(ra) # 800036ac <bwrite>
  brelse(buf);
    80004926:	8526                	mv	a0,s1
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	dc2080e7          	jalr	-574(ra) # 800036ea <brelse>
}
    80004930:	60e2                	ld	ra,24(sp)
    80004932:	6442                	ld	s0,16(sp)
    80004934:	64a2                	ld	s1,8(sp)
    80004936:	6902                	ld	s2,0(sp)
    80004938:	6105                	addi	sp,sp,32
    8000493a:	8082                	ret

000000008000493c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000493c:	00025797          	auipc	a5,0x25
    80004940:	d607a783          	lw	a5,-672(a5) # 8002969c <log+0x2c>
    80004944:	0af05d63          	blez	a5,800049fe <install_trans+0xc2>
{
    80004948:	7139                	addi	sp,sp,-64
    8000494a:	fc06                	sd	ra,56(sp)
    8000494c:	f822                	sd	s0,48(sp)
    8000494e:	f426                	sd	s1,40(sp)
    80004950:	f04a                	sd	s2,32(sp)
    80004952:	ec4e                	sd	s3,24(sp)
    80004954:	e852                	sd	s4,16(sp)
    80004956:	e456                	sd	s5,8(sp)
    80004958:	e05a                	sd	s6,0(sp)
    8000495a:	0080                	addi	s0,sp,64
    8000495c:	8b2a                	mv	s6,a0
    8000495e:	00025a97          	auipc	s5,0x25
    80004962:	d42a8a93          	addi	s5,s5,-702 # 800296a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004966:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004968:	00025997          	auipc	s3,0x25
    8000496c:	d0898993          	addi	s3,s3,-760 # 80029670 <log>
    80004970:	a00d                	j	80004992 <install_trans+0x56>
    brelse(lbuf);
    80004972:	854a                	mv	a0,s2
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	d76080e7          	jalr	-650(ra) # 800036ea <brelse>
    brelse(dbuf);
    8000497c:	8526                	mv	a0,s1
    8000497e:	fffff097          	auipc	ra,0xfffff
    80004982:	d6c080e7          	jalr	-660(ra) # 800036ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004986:	2a05                	addiw	s4,s4,1
    80004988:	0a91                	addi	s5,s5,4
    8000498a:	02c9a783          	lw	a5,44(s3)
    8000498e:	04fa5e63          	bge	s4,a5,800049ea <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004992:	0189a583          	lw	a1,24(s3)
    80004996:	014585bb          	addw	a1,a1,s4
    8000499a:	2585                	addiw	a1,a1,1
    8000499c:	0289a503          	lw	a0,40(s3)
    800049a0:	fffff097          	auipc	ra,0xfffff
    800049a4:	c1a080e7          	jalr	-998(ra) # 800035ba <bread>
    800049a8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800049aa:	000aa583          	lw	a1,0(s5)
    800049ae:	0289a503          	lw	a0,40(s3)
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	c08080e7          	jalr	-1016(ra) # 800035ba <bread>
    800049ba:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800049bc:	40000613          	li	a2,1024
    800049c0:	05890593          	addi	a1,s2,88
    800049c4:	05850513          	addi	a0,a0,88
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	352080e7          	jalr	850(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800049d0:	8526                	mv	a0,s1
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	cda080e7          	jalr	-806(ra) # 800036ac <bwrite>
    if(recovering == 0)
    800049da:	f80b1ce3          	bnez	s6,80004972 <install_trans+0x36>
      bunpin(dbuf);
    800049de:	8526                	mv	a0,s1
    800049e0:	fffff097          	auipc	ra,0xfffff
    800049e4:	de4080e7          	jalr	-540(ra) # 800037c4 <bunpin>
    800049e8:	b769                	j	80004972 <install_trans+0x36>
}
    800049ea:	70e2                	ld	ra,56(sp)
    800049ec:	7442                	ld	s0,48(sp)
    800049ee:	74a2                	ld	s1,40(sp)
    800049f0:	7902                	ld	s2,32(sp)
    800049f2:	69e2                	ld	s3,24(sp)
    800049f4:	6a42                	ld	s4,16(sp)
    800049f6:	6aa2                	ld	s5,8(sp)
    800049f8:	6b02                	ld	s6,0(sp)
    800049fa:	6121                	addi	sp,sp,64
    800049fc:	8082                	ret
    800049fe:	8082                	ret

0000000080004a00 <initlog>:
{
    80004a00:	7179                	addi	sp,sp,-48
    80004a02:	f406                	sd	ra,40(sp)
    80004a04:	f022                	sd	s0,32(sp)
    80004a06:	ec26                	sd	s1,24(sp)
    80004a08:	e84a                	sd	s2,16(sp)
    80004a0a:	e44e                	sd	s3,8(sp)
    80004a0c:	1800                	addi	s0,sp,48
    80004a0e:	892a                	mv	s2,a0
    80004a10:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004a12:	00025497          	auipc	s1,0x25
    80004a16:	c5e48493          	addi	s1,s1,-930 # 80029670 <log>
    80004a1a:	00004597          	auipc	a1,0x4
    80004a1e:	f2658593          	addi	a1,a1,-218 # 80008940 <syscalls+0x248>
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	10e080e7          	jalr	270(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004a2c:	0149a583          	lw	a1,20(s3)
    80004a30:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004a32:	0109a783          	lw	a5,16(s3)
    80004a36:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004a38:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004a3c:	854a                	mv	a0,s2
    80004a3e:	fffff097          	auipc	ra,0xfffff
    80004a42:	b7c080e7          	jalr	-1156(ra) # 800035ba <bread>
  log.lh.n = lh->n;
    80004a46:	4d34                	lw	a3,88(a0)
    80004a48:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004a4a:	02d05663          	blez	a3,80004a76 <initlog+0x76>
    80004a4e:	05c50793          	addi	a5,a0,92
    80004a52:	00025717          	auipc	a4,0x25
    80004a56:	c4e70713          	addi	a4,a4,-946 # 800296a0 <log+0x30>
    80004a5a:	36fd                	addiw	a3,a3,-1
    80004a5c:	02069613          	slli	a2,a3,0x20
    80004a60:	01e65693          	srli	a3,a2,0x1e
    80004a64:	06050613          	addi	a2,a0,96
    80004a68:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004a6a:	4390                	lw	a2,0(a5)
    80004a6c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a6e:	0791                	addi	a5,a5,4
    80004a70:	0711                	addi	a4,a4,4
    80004a72:	fed79ce3          	bne	a5,a3,80004a6a <initlog+0x6a>
  brelse(buf);
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	c74080e7          	jalr	-908(ra) # 800036ea <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004a7e:	4505                	li	a0,1
    80004a80:	00000097          	auipc	ra,0x0
    80004a84:	ebc080e7          	jalr	-324(ra) # 8000493c <install_trans>
  log.lh.n = 0;
    80004a88:	00025797          	auipc	a5,0x25
    80004a8c:	c007aa23          	sw	zero,-1004(a5) # 8002969c <log+0x2c>
  write_head(); // clear the log
    80004a90:	00000097          	auipc	ra,0x0
    80004a94:	e30080e7          	jalr	-464(ra) # 800048c0 <write_head>
}
    80004a98:	70a2                	ld	ra,40(sp)
    80004a9a:	7402                	ld	s0,32(sp)
    80004a9c:	64e2                	ld	s1,24(sp)
    80004a9e:	6942                	ld	s2,16(sp)
    80004aa0:	69a2                	ld	s3,8(sp)
    80004aa2:	6145                	addi	sp,sp,48
    80004aa4:	8082                	ret

0000000080004aa6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004aa6:	1101                	addi	sp,sp,-32
    80004aa8:	ec06                	sd	ra,24(sp)
    80004aaa:	e822                	sd	s0,16(sp)
    80004aac:	e426                	sd	s1,8(sp)
    80004aae:	e04a                	sd	s2,0(sp)
    80004ab0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ab2:	00025517          	auipc	a0,0x25
    80004ab6:	bbe50513          	addi	a0,a0,-1090 # 80029670 <log>
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	108080e7          	jalr	264(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004ac2:	00025497          	auipc	s1,0x25
    80004ac6:	bae48493          	addi	s1,s1,-1106 # 80029670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004aca:	4979                	li	s2,30
    80004acc:	a039                	j	80004ada <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ace:	85a6                	mv	a1,s1
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	ffffd097          	auipc	ra,0xffffd
    80004ad6:	590080e7          	jalr	1424(ra) # 80002062 <sleep>
    if(log.committing){
    80004ada:	50dc                	lw	a5,36(s1)
    80004adc:	fbed                	bnez	a5,80004ace <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ade:	509c                	lw	a5,32(s1)
    80004ae0:	0017871b          	addiw	a4,a5,1
    80004ae4:	0007069b          	sext.w	a3,a4
    80004ae8:	0027179b          	slliw	a5,a4,0x2
    80004aec:	9fb9                	addw	a5,a5,a4
    80004aee:	0017979b          	slliw	a5,a5,0x1
    80004af2:	54d8                	lw	a4,44(s1)
    80004af4:	9fb9                	addw	a5,a5,a4
    80004af6:	00f95963          	bge	s2,a5,80004b08 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004afa:	85a6                	mv	a1,s1
    80004afc:	8526                	mv	a0,s1
    80004afe:	ffffd097          	auipc	ra,0xffffd
    80004b02:	564080e7          	jalr	1380(ra) # 80002062 <sleep>
    80004b06:	bfd1                	j	80004ada <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004b08:	00025517          	auipc	a0,0x25
    80004b0c:	b6850513          	addi	a0,a0,-1176 # 80029670 <log>
    80004b10:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	164080e7          	jalr	356(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004b1a:	60e2                	ld	ra,24(sp)
    80004b1c:	6442                	ld	s0,16(sp)
    80004b1e:	64a2                	ld	s1,8(sp)
    80004b20:	6902                	ld	s2,0(sp)
    80004b22:	6105                	addi	sp,sp,32
    80004b24:	8082                	ret

0000000080004b26 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004b26:	7139                	addi	sp,sp,-64
    80004b28:	fc06                	sd	ra,56(sp)
    80004b2a:	f822                	sd	s0,48(sp)
    80004b2c:	f426                	sd	s1,40(sp)
    80004b2e:	f04a                	sd	s2,32(sp)
    80004b30:	ec4e                	sd	s3,24(sp)
    80004b32:	e852                	sd	s4,16(sp)
    80004b34:	e456                	sd	s5,8(sp)
    80004b36:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004b38:	00025497          	auipc	s1,0x25
    80004b3c:	b3848493          	addi	s1,s1,-1224 # 80029670 <log>
    80004b40:	8526                	mv	a0,s1
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	080080e7          	jalr	128(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004b4a:	509c                	lw	a5,32(s1)
    80004b4c:	37fd                	addiw	a5,a5,-1
    80004b4e:	0007891b          	sext.w	s2,a5
    80004b52:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004b54:	50dc                	lw	a5,36(s1)
    80004b56:	e7b9                	bnez	a5,80004ba4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004b58:	04091e63          	bnez	s2,80004bb4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004b5c:	00025497          	auipc	s1,0x25
    80004b60:	b1448493          	addi	s1,s1,-1260 # 80029670 <log>
    80004b64:	4785                	li	a5,1
    80004b66:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	10c080e7          	jalr	268(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004b72:	54dc                	lw	a5,44(s1)
    80004b74:	06f04763          	bgtz	a5,80004be2 <end_op+0xbc>
    acquire(&log.lock);
    80004b78:	00025497          	auipc	s1,0x25
    80004b7c:	af848493          	addi	s1,s1,-1288 # 80029670 <log>
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	040080e7          	jalr	64(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004b8a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004b8e:	8526                	mv	a0,s1
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	536080e7          	jalr	1334(ra) # 800020c6 <wakeup>
    release(&log.lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	0dc080e7          	jalr	220(ra) # 80000c76 <release>
}
    80004ba2:	a03d                	j	80004bd0 <end_op+0xaa>
    panic("log.committing");
    80004ba4:	00004517          	auipc	a0,0x4
    80004ba8:	da450513          	addi	a0,a0,-604 # 80008948 <syscalls+0x250>
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	97e080e7          	jalr	-1666(ra) # 8000052a <panic>
    wakeup(&log);
    80004bb4:	00025497          	auipc	s1,0x25
    80004bb8:	abc48493          	addi	s1,s1,-1348 # 80029670 <log>
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	508080e7          	jalr	1288(ra) # 800020c6 <wakeup>
  release(&log.lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0ae080e7          	jalr	174(ra) # 80000c76 <release>
}
    80004bd0:	70e2                	ld	ra,56(sp)
    80004bd2:	7442                	ld	s0,48(sp)
    80004bd4:	74a2                	ld	s1,40(sp)
    80004bd6:	7902                	ld	s2,32(sp)
    80004bd8:	69e2                	ld	s3,24(sp)
    80004bda:	6a42                	ld	s4,16(sp)
    80004bdc:	6aa2                	ld	s5,8(sp)
    80004bde:	6121                	addi	sp,sp,64
    80004be0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004be2:	00025a97          	auipc	s5,0x25
    80004be6:	abea8a93          	addi	s5,s5,-1346 # 800296a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004bea:	00025a17          	auipc	s4,0x25
    80004bee:	a86a0a13          	addi	s4,s4,-1402 # 80029670 <log>
    80004bf2:	018a2583          	lw	a1,24(s4)
    80004bf6:	012585bb          	addw	a1,a1,s2
    80004bfa:	2585                	addiw	a1,a1,1
    80004bfc:	028a2503          	lw	a0,40(s4)
    80004c00:	fffff097          	auipc	ra,0xfffff
    80004c04:	9ba080e7          	jalr	-1606(ra) # 800035ba <bread>
    80004c08:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004c0a:	000aa583          	lw	a1,0(s5)
    80004c0e:	028a2503          	lw	a0,40(s4)
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	9a8080e7          	jalr	-1624(ra) # 800035ba <bread>
    80004c1a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004c1c:	40000613          	li	a2,1024
    80004c20:	05850593          	addi	a1,a0,88
    80004c24:	05848513          	addi	a0,s1,88
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	0f2080e7          	jalr	242(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004c30:	8526                	mv	a0,s1
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	a7a080e7          	jalr	-1414(ra) # 800036ac <bwrite>
    brelse(from);
    80004c3a:	854e                	mv	a0,s3
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	aae080e7          	jalr	-1362(ra) # 800036ea <brelse>
    brelse(to);
    80004c44:	8526                	mv	a0,s1
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	aa4080e7          	jalr	-1372(ra) # 800036ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c4e:	2905                	addiw	s2,s2,1
    80004c50:	0a91                	addi	s5,s5,4
    80004c52:	02ca2783          	lw	a5,44(s4)
    80004c56:	f8f94ee3          	blt	s2,a5,80004bf2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004c5a:	00000097          	auipc	ra,0x0
    80004c5e:	c66080e7          	jalr	-922(ra) # 800048c0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004c62:	4501                	li	a0,0
    80004c64:	00000097          	auipc	ra,0x0
    80004c68:	cd8080e7          	jalr	-808(ra) # 8000493c <install_trans>
    log.lh.n = 0;
    80004c6c:	00025797          	auipc	a5,0x25
    80004c70:	a207a823          	sw	zero,-1488(a5) # 8002969c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004c74:	00000097          	auipc	ra,0x0
    80004c78:	c4c080e7          	jalr	-948(ra) # 800048c0 <write_head>
    80004c7c:	bdf5                	j	80004b78 <end_op+0x52>

0000000080004c7e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004c7e:	1101                	addi	sp,sp,-32
    80004c80:	ec06                	sd	ra,24(sp)
    80004c82:	e822                	sd	s0,16(sp)
    80004c84:	e426                	sd	s1,8(sp)
    80004c86:	e04a                	sd	s2,0(sp)
    80004c88:	1000                	addi	s0,sp,32
    80004c8a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004c8c:	00025917          	auipc	s2,0x25
    80004c90:	9e490913          	addi	s2,s2,-1564 # 80029670 <log>
    80004c94:	854a                	mv	a0,s2
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	f2c080e7          	jalr	-212(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c9e:	02c92603          	lw	a2,44(s2)
    80004ca2:	47f5                	li	a5,29
    80004ca4:	06c7c563          	blt	a5,a2,80004d0e <log_write+0x90>
    80004ca8:	00025797          	auipc	a5,0x25
    80004cac:	9e47a783          	lw	a5,-1564(a5) # 8002968c <log+0x1c>
    80004cb0:	37fd                	addiw	a5,a5,-1
    80004cb2:	04f65e63          	bge	a2,a5,80004d0e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004cb6:	00025797          	auipc	a5,0x25
    80004cba:	9da7a783          	lw	a5,-1574(a5) # 80029690 <log+0x20>
    80004cbe:	06f05063          	blez	a5,80004d1e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004cc2:	4781                	li	a5,0
    80004cc4:	06c05563          	blez	a2,80004d2e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004cc8:	44cc                	lw	a1,12(s1)
    80004cca:	00025717          	auipc	a4,0x25
    80004cce:	9d670713          	addi	a4,a4,-1578 # 800296a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004cd2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004cd4:	4314                	lw	a3,0(a4)
    80004cd6:	04b68c63          	beq	a3,a1,80004d2e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004cda:	2785                	addiw	a5,a5,1
    80004cdc:	0711                	addi	a4,a4,4
    80004cde:	fef61be3          	bne	a2,a5,80004cd4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ce2:	0621                	addi	a2,a2,8
    80004ce4:	060a                	slli	a2,a2,0x2
    80004ce6:	00025797          	auipc	a5,0x25
    80004cea:	98a78793          	addi	a5,a5,-1654 # 80029670 <log>
    80004cee:	963e                	add	a2,a2,a5
    80004cf0:	44dc                	lw	a5,12(s1)
    80004cf2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	a92080e7          	jalr	-1390(ra) # 80003788 <bpin>
    log.lh.n++;
    80004cfe:	00025717          	auipc	a4,0x25
    80004d02:	97270713          	addi	a4,a4,-1678 # 80029670 <log>
    80004d06:	575c                	lw	a5,44(a4)
    80004d08:	2785                	addiw	a5,a5,1
    80004d0a:	d75c                	sw	a5,44(a4)
    80004d0c:	a835                	j	80004d48 <log_write+0xca>
    panic("too big a transaction");
    80004d0e:	00004517          	auipc	a0,0x4
    80004d12:	c4a50513          	addi	a0,a0,-950 # 80008958 <syscalls+0x260>
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	814080e7          	jalr	-2028(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004d1e:	00004517          	auipc	a0,0x4
    80004d22:	c5250513          	addi	a0,a0,-942 # 80008970 <syscalls+0x278>
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	804080e7          	jalr	-2044(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004d2e:	00878713          	addi	a4,a5,8
    80004d32:	00271693          	slli	a3,a4,0x2
    80004d36:	00025717          	auipc	a4,0x25
    80004d3a:	93a70713          	addi	a4,a4,-1734 # 80029670 <log>
    80004d3e:	9736                	add	a4,a4,a3
    80004d40:	44d4                	lw	a3,12(s1)
    80004d42:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004d44:	faf608e3          	beq	a2,a5,80004cf4 <log_write+0x76>
  }
  release(&log.lock);
    80004d48:	00025517          	auipc	a0,0x25
    80004d4c:	92850513          	addi	a0,a0,-1752 # 80029670 <log>
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	f26080e7          	jalr	-218(ra) # 80000c76 <release>
}
    80004d58:	60e2                	ld	ra,24(sp)
    80004d5a:	6442                	ld	s0,16(sp)
    80004d5c:	64a2                	ld	s1,8(sp)
    80004d5e:	6902                	ld	s2,0(sp)
    80004d60:	6105                	addi	sp,sp,32
    80004d62:	8082                	ret

0000000080004d64 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004d64:	1101                	addi	sp,sp,-32
    80004d66:	ec06                	sd	ra,24(sp)
    80004d68:	e822                	sd	s0,16(sp)
    80004d6a:	e426                	sd	s1,8(sp)
    80004d6c:	e04a                	sd	s2,0(sp)
    80004d6e:	1000                	addi	s0,sp,32
    80004d70:	84aa                	mv	s1,a0
    80004d72:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004d74:	00004597          	auipc	a1,0x4
    80004d78:	c1c58593          	addi	a1,a1,-996 # 80008990 <syscalls+0x298>
    80004d7c:	0521                	addi	a0,a0,8
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	db4080e7          	jalr	-588(ra) # 80000b32 <initlock>
  lk->name = name;
    80004d86:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004d8a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d8e:	0204a423          	sw	zero,40(s1)
}
    80004d92:	60e2                	ld	ra,24(sp)
    80004d94:	6442                	ld	s0,16(sp)
    80004d96:	64a2                	ld	s1,8(sp)
    80004d98:	6902                	ld	s2,0(sp)
    80004d9a:	6105                	addi	sp,sp,32
    80004d9c:	8082                	ret

0000000080004d9e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004d9e:	1101                	addi	sp,sp,-32
    80004da0:	ec06                	sd	ra,24(sp)
    80004da2:	e822                	sd	s0,16(sp)
    80004da4:	e426                	sd	s1,8(sp)
    80004da6:	e04a                	sd	s2,0(sp)
    80004da8:	1000                	addi	s0,sp,32
    80004daa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004dac:	00850913          	addi	s2,a0,8
    80004db0:	854a                	mv	a0,s2
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	e10080e7          	jalr	-496(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004dba:	409c                	lw	a5,0(s1)
    80004dbc:	cb89                	beqz	a5,80004dce <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004dbe:	85ca                	mv	a1,s2
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	2a0080e7          	jalr	672(ra) # 80002062 <sleep>
  while (lk->locked) {
    80004dca:	409c                	lw	a5,0(s1)
    80004dcc:	fbed                	bnez	a5,80004dbe <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004dce:	4785                	li	a5,1
    80004dd0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	c02080e7          	jalr	-1022(ra) # 800019d4 <myproc>
    80004dda:	591c                	lw	a5,48(a0)
    80004ddc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004dde:	854a                	mv	a0,s2
    80004de0:	ffffc097          	auipc	ra,0xffffc
    80004de4:	e96080e7          	jalr	-362(ra) # 80000c76 <release>
}
    80004de8:	60e2                	ld	ra,24(sp)
    80004dea:	6442                	ld	s0,16(sp)
    80004dec:	64a2                	ld	s1,8(sp)
    80004dee:	6902                	ld	s2,0(sp)
    80004df0:	6105                	addi	sp,sp,32
    80004df2:	8082                	ret

0000000080004df4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004df4:	1101                	addi	sp,sp,-32
    80004df6:	ec06                	sd	ra,24(sp)
    80004df8:	e822                	sd	s0,16(sp)
    80004dfa:	e426                	sd	s1,8(sp)
    80004dfc:	e04a                	sd	s2,0(sp)
    80004dfe:	1000                	addi	s0,sp,32
    80004e00:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e02:	00850913          	addi	s2,a0,8
    80004e06:	854a                	mv	a0,s2
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	dba080e7          	jalr	-582(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004e10:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e14:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	ffffd097          	auipc	ra,0xffffd
    80004e1e:	2ac080e7          	jalr	684(ra) # 800020c6 <wakeup>
  release(&lk->lk);
    80004e22:	854a                	mv	a0,s2
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	e52080e7          	jalr	-430(ra) # 80000c76 <release>
}
    80004e2c:	60e2                	ld	ra,24(sp)
    80004e2e:	6442                	ld	s0,16(sp)
    80004e30:	64a2                	ld	s1,8(sp)
    80004e32:	6902                	ld	s2,0(sp)
    80004e34:	6105                	addi	sp,sp,32
    80004e36:	8082                	ret

0000000080004e38 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004e38:	7179                	addi	sp,sp,-48
    80004e3a:	f406                	sd	ra,40(sp)
    80004e3c:	f022                	sd	s0,32(sp)
    80004e3e:	ec26                	sd	s1,24(sp)
    80004e40:	e84a                	sd	s2,16(sp)
    80004e42:	e44e                	sd	s3,8(sp)
    80004e44:	1800                	addi	s0,sp,48
    80004e46:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004e48:	00850913          	addi	s2,a0,8
    80004e4c:	854a                	mv	a0,s2
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	d74080e7          	jalr	-652(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e56:	409c                	lw	a5,0(s1)
    80004e58:	ef99                	bnez	a5,80004e76 <holdingsleep+0x3e>
    80004e5a:	4481                	li	s1,0
  release(&lk->lk);
    80004e5c:	854a                	mv	a0,s2
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	e18080e7          	jalr	-488(ra) # 80000c76 <release>
  return r;
}
    80004e66:	8526                	mv	a0,s1
    80004e68:	70a2                	ld	ra,40(sp)
    80004e6a:	7402                	ld	s0,32(sp)
    80004e6c:	64e2                	ld	s1,24(sp)
    80004e6e:	6942                	ld	s2,16(sp)
    80004e70:	69a2                	ld	s3,8(sp)
    80004e72:	6145                	addi	sp,sp,48
    80004e74:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e76:	0284a983          	lw	s3,40(s1)
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	b5a080e7          	jalr	-1190(ra) # 800019d4 <myproc>
    80004e82:	5904                	lw	s1,48(a0)
    80004e84:	413484b3          	sub	s1,s1,s3
    80004e88:	0014b493          	seqz	s1,s1
    80004e8c:	bfc1                	j	80004e5c <holdingsleep+0x24>

0000000080004e8e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004e8e:	1141                	addi	sp,sp,-16
    80004e90:	e406                	sd	ra,8(sp)
    80004e92:	e022                	sd	s0,0(sp)
    80004e94:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004e96:	00004597          	auipc	a1,0x4
    80004e9a:	b0a58593          	addi	a1,a1,-1270 # 800089a0 <syscalls+0x2a8>
    80004e9e:	00025517          	auipc	a0,0x25
    80004ea2:	91a50513          	addi	a0,a0,-1766 # 800297b8 <ftable>
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	c8c080e7          	jalr	-884(ra) # 80000b32 <initlock>
}
    80004eae:	60a2                	ld	ra,8(sp)
    80004eb0:	6402                	ld	s0,0(sp)
    80004eb2:	0141                	addi	sp,sp,16
    80004eb4:	8082                	ret

0000000080004eb6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004eb6:	1101                	addi	sp,sp,-32
    80004eb8:	ec06                	sd	ra,24(sp)
    80004eba:	e822                	sd	s0,16(sp)
    80004ebc:	e426                	sd	s1,8(sp)
    80004ebe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ec0:	00025517          	auipc	a0,0x25
    80004ec4:	8f850513          	addi	a0,a0,-1800 # 800297b8 <ftable>
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	cfa080e7          	jalr	-774(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ed0:	00025497          	auipc	s1,0x25
    80004ed4:	90048493          	addi	s1,s1,-1792 # 800297d0 <ftable+0x18>
    80004ed8:	00026717          	auipc	a4,0x26
    80004edc:	89870713          	addi	a4,a4,-1896 # 8002a770 <ftable+0xfb8>
    if(f->ref == 0){
    80004ee0:	40dc                	lw	a5,4(s1)
    80004ee2:	cf99                	beqz	a5,80004f00 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ee4:	02848493          	addi	s1,s1,40
    80004ee8:	fee49ce3          	bne	s1,a4,80004ee0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004eec:	00025517          	auipc	a0,0x25
    80004ef0:	8cc50513          	addi	a0,a0,-1844 # 800297b8 <ftable>
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	d82080e7          	jalr	-638(ra) # 80000c76 <release>
  return 0;
    80004efc:	4481                	li	s1,0
    80004efe:	a819                	j	80004f14 <filealloc+0x5e>
      f->ref = 1;
    80004f00:	4785                	li	a5,1
    80004f02:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004f04:	00025517          	auipc	a0,0x25
    80004f08:	8b450513          	addi	a0,a0,-1868 # 800297b8 <ftable>
    80004f0c:	ffffc097          	auipc	ra,0xffffc
    80004f10:	d6a080e7          	jalr	-662(ra) # 80000c76 <release>
}
    80004f14:	8526                	mv	a0,s1
    80004f16:	60e2                	ld	ra,24(sp)
    80004f18:	6442                	ld	s0,16(sp)
    80004f1a:	64a2                	ld	s1,8(sp)
    80004f1c:	6105                	addi	sp,sp,32
    80004f1e:	8082                	ret

0000000080004f20 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004f20:	1101                	addi	sp,sp,-32
    80004f22:	ec06                	sd	ra,24(sp)
    80004f24:	e822                	sd	s0,16(sp)
    80004f26:	e426                	sd	s1,8(sp)
    80004f28:	1000                	addi	s0,sp,32
    80004f2a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004f2c:	00025517          	auipc	a0,0x25
    80004f30:	88c50513          	addi	a0,a0,-1908 # 800297b8 <ftable>
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	c8e080e7          	jalr	-882(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004f3c:	40dc                	lw	a5,4(s1)
    80004f3e:	02f05263          	blez	a5,80004f62 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004f42:	2785                	addiw	a5,a5,1
    80004f44:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004f46:	00025517          	auipc	a0,0x25
    80004f4a:	87250513          	addi	a0,a0,-1934 # 800297b8 <ftable>
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	d28080e7          	jalr	-728(ra) # 80000c76 <release>
  return f;
}
    80004f56:	8526                	mv	a0,s1
    80004f58:	60e2                	ld	ra,24(sp)
    80004f5a:	6442                	ld	s0,16(sp)
    80004f5c:	64a2                	ld	s1,8(sp)
    80004f5e:	6105                	addi	sp,sp,32
    80004f60:	8082                	ret
    panic("filedup");
    80004f62:	00004517          	auipc	a0,0x4
    80004f66:	a4650513          	addi	a0,a0,-1466 # 800089a8 <syscalls+0x2b0>
    80004f6a:	ffffb097          	auipc	ra,0xffffb
    80004f6e:	5c0080e7          	jalr	1472(ra) # 8000052a <panic>

0000000080004f72 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004f72:	7139                	addi	sp,sp,-64
    80004f74:	fc06                	sd	ra,56(sp)
    80004f76:	f822                	sd	s0,48(sp)
    80004f78:	f426                	sd	s1,40(sp)
    80004f7a:	f04a                	sd	s2,32(sp)
    80004f7c:	ec4e                	sd	s3,24(sp)
    80004f7e:	e852                	sd	s4,16(sp)
    80004f80:	e456                	sd	s5,8(sp)
    80004f82:	0080                	addi	s0,sp,64
    80004f84:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004f86:	00025517          	auipc	a0,0x25
    80004f8a:	83250513          	addi	a0,a0,-1998 # 800297b8 <ftable>
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	c34080e7          	jalr	-972(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004f96:	40dc                	lw	a5,4(s1)
    80004f98:	06f05163          	blez	a5,80004ffa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004f9c:	37fd                	addiw	a5,a5,-1
    80004f9e:	0007871b          	sext.w	a4,a5
    80004fa2:	c0dc                	sw	a5,4(s1)
    80004fa4:	06e04363          	bgtz	a4,8000500a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004fa8:	0004a903          	lw	s2,0(s1)
    80004fac:	0094ca83          	lbu	s5,9(s1)
    80004fb0:	0104ba03          	ld	s4,16(s1)
    80004fb4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004fb8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004fbc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004fc0:	00024517          	auipc	a0,0x24
    80004fc4:	7f850513          	addi	a0,a0,2040 # 800297b8 <ftable>
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	cae080e7          	jalr	-850(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004fd0:	4785                	li	a5,1
    80004fd2:	04f90d63          	beq	s2,a5,8000502c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004fd6:	3979                	addiw	s2,s2,-2
    80004fd8:	4785                	li	a5,1
    80004fda:	0527e063          	bltu	a5,s2,8000501a <fileclose+0xa8>
    begin_op();
    80004fde:	00000097          	auipc	ra,0x0
    80004fe2:	ac8080e7          	jalr	-1336(ra) # 80004aa6 <begin_op>
    iput(ff.ip);
    80004fe6:	854e                	mv	a0,s3
    80004fe8:	fffff097          	auipc	ra,0xfffff
    80004fec:	f90080e7          	jalr	-112(ra) # 80003f78 <iput>
    end_op();
    80004ff0:	00000097          	auipc	ra,0x0
    80004ff4:	b36080e7          	jalr	-1226(ra) # 80004b26 <end_op>
    80004ff8:	a00d                	j	8000501a <fileclose+0xa8>
    panic("fileclose");
    80004ffa:	00004517          	auipc	a0,0x4
    80004ffe:	9b650513          	addi	a0,a0,-1610 # 800089b0 <syscalls+0x2b8>
    80005002:	ffffb097          	auipc	ra,0xffffb
    80005006:	528080e7          	jalr	1320(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000500a:	00024517          	auipc	a0,0x24
    8000500e:	7ae50513          	addi	a0,a0,1966 # 800297b8 <ftable>
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	c64080e7          	jalr	-924(ra) # 80000c76 <release>
  }
}
    8000501a:	70e2                	ld	ra,56(sp)
    8000501c:	7442                	ld	s0,48(sp)
    8000501e:	74a2                	ld	s1,40(sp)
    80005020:	7902                	ld	s2,32(sp)
    80005022:	69e2                	ld	s3,24(sp)
    80005024:	6a42                	ld	s4,16(sp)
    80005026:	6aa2                	ld	s5,8(sp)
    80005028:	6121                	addi	sp,sp,64
    8000502a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000502c:	85d6                	mv	a1,s5
    8000502e:	8552                	mv	a0,s4
    80005030:	00000097          	auipc	ra,0x0
    80005034:	542080e7          	jalr	1346(ra) # 80005572 <pipeclose>
    80005038:	b7cd                	j	8000501a <fileclose+0xa8>

000000008000503a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000503a:	715d                	addi	sp,sp,-80
    8000503c:	e486                	sd	ra,72(sp)
    8000503e:	e0a2                	sd	s0,64(sp)
    80005040:	fc26                	sd	s1,56(sp)
    80005042:	f84a                	sd	s2,48(sp)
    80005044:	f44e                	sd	s3,40(sp)
    80005046:	0880                	addi	s0,sp,80
    80005048:	84aa                	mv	s1,a0
    8000504a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000504c:	ffffd097          	auipc	ra,0xffffd
    80005050:	988080e7          	jalr	-1656(ra) # 800019d4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005054:	409c                	lw	a5,0(s1)
    80005056:	37f9                	addiw	a5,a5,-2
    80005058:	4705                	li	a4,1
    8000505a:	04f76763          	bltu	a4,a5,800050a8 <filestat+0x6e>
    8000505e:	892a                	mv	s2,a0
    ilock(f->ip);
    80005060:	6c88                	ld	a0,24(s1)
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	d5c080e7          	jalr	-676(ra) # 80003dbe <ilock>
    stati(f->ip, &st);
    8000506a:	fb840593          	addi	a1,s0,-72
    8000506e:	6c88                	ld	a0,24(s1)
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	fd8080e7          	jalr	-40(ra) # 80004048 <stati>
    iunlock(f->ip);
    80005078:	6c88                	ld	a0,24(s1)
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	e06080e7          	jalr	-506(ra) # 80003e80 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005082:	46e1                	li	a3,24
    80005084:	fb840613          	addi	a2,s0,-72
    80005088:	85ce                	mv	a1,s3
    8000508a:	05093503          	ld	a0,80(s2)
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	606080e7          	jalr	1542(ra) # 80001694 <copyout>
    80005096:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000509a:	60a6                	ld	ra,72(sp)
    8000509c:	6406                	ld	s0,64(sp)
    8000509e:	74e2                	ld	s1,56(sp)
    800050a0:	7942                	ld	s2,48(sp)
    800050a2:	79a2                	ld	s3,40(sp)
    800050a4:	6161                	addi	sp,sp,80
    800050a6:	8082                	ret
  return -1;
    800050a8:	557d                	li	a0,-1
    800050aa:	bfc5                	j	8000509a <filestat+0x60>

00000000800050ac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800050ac:	7179                	addi	sp,sp,-48
    800050ae:	f406                	sd	ra,40(sp)
    800050b0:	f022                	sd	s0,32(sp)
    800050b2:	ec26                	sd	s1,24(sp)
    800050b4:	e84a                	sd	s2,16(sp)
    800050b6:	e44e                	sd	s3,8(sp)
    800050b8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800050ba:	00854783          	lbu	a5,8(a0)
    800050be:	c3d5                	beqz	a5,80005162 <fileread+0xb6>
    800050c0:	84aa                	mv	s1,a0
    800050c2:	89ae                	mv	s3,a1
    800050c4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800050c6:	411c                	lw	a5,0(a0)
    800050c8:	4705                	li	a4,1
    800050ca:	04e78963          	beq	a5,a4,8000511c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050ce:	470d                	li	a4,3
    800050d0:	04e78d63          	beq	a5,a4,8000512a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800050d4:	4709                	li	a4,2
    800050d6:	06e79e63          	bne	a5,a4,80005152 <fileread+0xa6>
    ilock(f->ip);
    800050da:	6d08                	ld	a0,24(a0)
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	ce2080e7          	jalr	-798(ra) # 80003dbe <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800050e4:	874a                	mv	a4,s2
    800050e6:	5094                	lw	a3,32(s1)
    800050e8:	864e                	mv	a2,s3
    800050ea:	4585                	li	a1,1
    800050ec:	6c88                	ld	a0,24(s1)
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	f84080e7          	jalr	-124(ra) # 80004072 <readi>
    800050f6:	892a                	mv	s2,a0
    800050f8:	00a05563          	blez	a0,80005102 <fileread+0x56>
      f->off += r;
    800050fc:	509c                	lw	a5,32(s1)
    800050fe:	9fa9                	addw	a5,a5,a0
    80005100:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005102:	6c88                	ld	a0,24(s1)
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	d7c080e7          	jalr	-644(ra) # 80003e80 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000510c:	854a                	mv	a0,s2
    8000510e:	70a2                	ld	ra,40(sp)
    80005110:	7402                	ld	s0,32(sp)
    80005112:	64e2                	ld	s1,24(sp)
    80005114:	6942                	ld	s2,16(sp)
    80005116:	69a2                	ld	s3,8(sp)
    80005118:	6145                	addi	sp,sp,48
    8000511a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000511c:	6908                	ld	a0,16(a0)
    8000511e:	00000097          	auipc	ra,0x0
    80005122:	5b6080e7          	jalr	1462(ra) # 800056d4 <piperead>
    80005126:	892a                	mv	s2,a0
    80005128:	b7d5                	j	8000510c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000512a:	02451783          	lh	a5,36(a0)
    8000512e:	03079693          	slli	a3,a5,0x30
    80005132:	92c1                	srli	a3,a3,0x30
    80005134:	4725                	li	a4,9
    80005136:	02d76863          	bltu	a4,a3,80005166 <fileread+0xba>
    8000513a:	0792                	slli	a5,a5,0x4
    8000513c:	00024717          	auipc	a4,0x24
    80005140:	5dc70713          	addi	a4,a4,1500 # 80029718 <devsw>
    80005144:	97ba                	add	a5,a5,a4
    80005146:	639c                	ld	a5,0(a5)
    80005148:	c38d                	beqz	a5,8000516a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000514a:	4505                	li	a0,1
    8000514c:	9782                	jalr	a5
    8000514e:	892a                	mv	s2,a0
    80005150:	bf75                	j	8000510c <fileread+0x60>
    panic("fileread");
    80005152:	00004517          	auipc	a0,0x4
    80005156:	86e50513          	addi	a0,a0,-1938 # 800089c0 <syscalls+0x2c8>
    8000515a:	ffffb097          	auipc	ra,0xffffb
    8000515e:	3d0080e7          	jalr	976(ra) # 8000052a <panic>
    return -1;
    80005162:	597d                	li	s2,-1
    80005164:	b765                	j	8000510c <fileread+0x60>
      return -1;
    80005166:	597d                	li	s2,-1
    80005168:	b755                	j	8000510c <fileread+0x60>
    8000516a:	597d                	li	s2,-1
    8000516c:	b745                	j	8000510c <fileread+0x60>

000000008000516e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000516e:	715d                	addi	sp,sp,-80
    80005170:	e486                	sd	ra,72(sp)
    80005172:	e0a2                	sd	s0,64(sp)
    80005174:	fc26                	sd	s1,56(sp)
    80005176:	f84a                	sd	s2,48(sp)
    80005178:	f44e                	sd	s3,40(sp)
    8000517a:	f052                	sd	s4,32(sp)
    8000517c:	ec56                	sd	s5,24(sp)
    8000517e:	e85a                	sd	s6,16(sp)
    80005180:	e45e                	sd	s7,8(sp)
    80005182:	e062                	sd	s8,0(sp)
    80005184:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005186:	00954783          	lbu	a5,9(a0)
    8000518a:	10078663          	beqz	a5,80005296 <filewrite+0x128>
    8000518e:	892a                	mv	s2,a0
    80005190:	8aae                	mv	s5,a1
    80005192:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005194:	411c                	lw	a5,0(a0)
    80005196:	4705                	li	a4,1
    80005198:	02e78263          	beq	a5,a4,800051bc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000519c:	470d                	li	a4,3
    8000519e:	02e78663          	beq	a5,a4,800051ca <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800051a2:	4709                	li	a4,2
    800051a4:	0ee79163          	bne	a5,a4,80005286 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800051a8:	0ac05d63          	blez	a2,80005262 <filewrite+0xf4>
    int i = 0;
    800051ac:	4981                	li	s3,0
    800051ae:	6b05                	lui	s6,0x1
    800051b0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800051b4:	6b85                	lui	s7,0x1
    800051b6:	c00b8b9b          	addiw	s7,s7,-1024
    800051ba:	a861                	j	80005252 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800051bc:	6908                	ld	a0,16(a0)
    800051be:	00000097          	auipc	ra,0x0
    800051c2:	424080e7          	jalr	1060(ra) # 800055e2 <pipewrite>
    800051c6:	8a2a                	mv	s4,a0
    800051c8:	a045                	j	80005268 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800051ca:	02451783          	lh	a5,36(a0)
    800051ce:	03079693          	slli	a3,a5,0x30
    800051d2:	92c1                	srli	a3,a3,0x30
    800051d4:	4725                	li	a4,9
    800051d6:	0cd76263          	bltu	a4,a3,8000529a <filewrite+0x12c>
    800051da:	0792                	slli	a5,a5,0x4
    800051dc:	00024717          	auipc	a4,0x24
    800051e0:	53c70713          	addi	a4,a4,1340 # 80029718 <devsw>
    800051e4:	97ba                	add	a5,a5,a4
    800051e6:	679c                	ld	a5,8(a5)
    800051e8:	cbdd                	beqz	a5,8000529e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800051ea:	4505                	li	a0,1
    800051ec:	9782                	jalr	a5
    800051ee:	8a2a                	mv	s4,a0
    800051f0:	a8a5                	j	80005268 <filewrite+0xfa>
    800051f2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800051f6:	00000097          	auipc	ra,0x0
    800051fa:	8b0080e7          	jalr	-1872(ra) # 80004aa6 <begin_op>
      ilock(f->ip);
    800051fe:	01893503          	ld	a0,24(s2)
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	bbc080e7          	jalr	-1092(ra) # 80003dbe <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000520a:	8762                	mv	a4,s8
    8000520c:	02092683          	lw	a3,32(s2)
    80005210:	01598633          	add	a2,s3,s5
    80005214:	4585                	li	a1,1
    80005216:	01893503          	ld	a0,24(s2)
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	f50080e7          	jalr	-176(ra) # 8000416a <writei>
    80005222:	84aa                	mv	s1,a0
    80005224:	00a05763          	blez	a0,80005232 <filewrite+0xc4>
        f->off += r;
    80005228:	02092783          	lw	a5,32(s2)
    8000522c:	9fa9                	addw	a5,a5,a0
    8000522e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005232:	01893503          	ld	a0,24(s2)
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	c4a080e7          	jalr	-950(ra) # 80003e80 <iunlock>
      end_op();
    8000523e:	00000097          	auipc	ra,0x0
    80005242:	8e8080e7          	jalr	-1816(ra) # 80004b26 <end_op>

      if(r != n1){
    80005246:	009c1f63          	bne	s8,s1,80005264 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000524a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000524e:	0149db63          	bge	s3,s4,80005264 <filewrite+0xf6>
      int n1 = n - i;
    80005252:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005256:	84be                	mv	s1,a5
    80005258:	2781                	sext.w	a5,a5
    8000525a:	f8fb5ce3          	bge	s6,a5,800051f2 <filewrite+0x84>
    8000525e:	84de                	mv	s1,s7
    80005260:	bf49                	j	800051f2 <filewrite+0x84>
    int i = 0;
    80005262:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005264:	013a1f63          	bne	s4,s3,80005282 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005268:	8552                	mv	a0,s4
    8000526a:	60a6                	ld	ra,72(sp)
    8000526c:	6406                	ld	s0,64(sp)
    8000526e:	74e2                	ld	s1,56(sp)
    80005270:	7942                	ld	s2,48(sp)
    80005272:	79a2                	ld	s3,40(sp)
    80005274:	7a02                	ld	s4,32(sp)
    80005276:	6ae2                	ld	s5,24(sp)
    80005278:	6b42                	ld	s6,16(sp)
    8000527a:	6ba2                	ld	s7,8(sp)
    8000527c:	6c02                	ld	s8,0(sp)
    8000527e:	6161                	addi	sp,sp,80
    80005280:	8082                	ret
    ret = (i == n ? n : -1);
    80005282:	5a7d                	li	s4,-1
    80005284:	b7d5                	j	80005268 <filewrite+0xfa>
    panic("filewrite");
    80005286:	00003517          	auipc	a0,0x3
    8000528a:	74a50513          	addi	a0,a0,1866 # 800089d0 <syscalls+0x2d8>
    8000528e:	ffffb097          	auipc	ra,0xffffb
    80005292:	29c080e7          	jalr	668(ra) # 8000052a <panic>
    return -1;
    80005296:	5a7d                	li	s4,-1
    80005298:	bfc1                	j	80005268 <filewrite+0xfa>
      return -1;
    8000529a:	5a7d                	li	s4,-1
    8000529c:	b7f1                	j	80005268 <filewrite+0xfa>
    8000529e:	5a7d                	li	s4,-1
    800052a0:	b7e1                	j	80005268 <filewrite+0xfa>

00000000800052a2 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    800052a2:	7179                	addi	sp,sp,-48
    800052a4:	f406                	sd	ra,40(sp)
    800052a6:	f022                	sd	s0,32(sp)
    800052a8:	ec26                	sd	s1,24(sp)
    800052aa:	e84a                	sd	s2,16(sp)
    800052ac:	e44e                	sd	s3,8(sp)
    800052ae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800052b0:	00854783          	lbu	a5,8(a0)
    800052b4:	c3d5                	beqz	a5,80005358 <kfileread+0xb6>
    800052b6:	84aa                	mv	s1,a0
    800052b8:	89ae                	mv	s3,a1
    800052ba:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052bc:	411c                	lw	a5,0(a0)
    800052be:	4705                	li	a4,1
    800052c0:	04e78963          	beq	a5,a4,80005312 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052c4:	470d                	li	a4,3
    800052c6:	04e78d63          	beq	a5,a4,80005320 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052ca:	4709                	li	a4,2
    800052cc:	06e79e63          	bne	a5,a4,80005348 <kfileread+0xa6>
    ilock(f->ip);
    800052d0:	6d08                	ld	a0,24(a0)
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	aec080e7          	jalr	-1300(ra) # 80003dbe <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800052da:	874a                	mv	a4,s2
    800052dc:	5094                	lw	a3,32(s1)
    800052de:	864e                	mv	a2,s3
    800052e0:	4581                	li	a1,0
    800052e2:	6c88                	ld	a0,24(s1)
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	d8e080e7          	jalr	-626(ra) # 80004072 <readi>
    800052ec:	892a                	mv	s2,a0
    800052ee:	00a05563          	blez	a0,800052f8 <kfileread+0x56>
      f->off += r;
    800052f2:	509c                	lw	a5,32(s1)
    800052f4:	9fa9                	addw	a5,a5,a0
    800052f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052f8:	6c88                	ld	a0,24(s1)
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	b86080e7          	jalr	-1146(ra) # 80003e80 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005302:	854a                	mv	a0,s2
    80005304:	70a2                	ld	ra,40(sp)
    80005306:	7402                	ld	s0,32(sp)
    80005308:	64e2                	ld	s1,24(sp)
    8000530a:	6942                	ld	s2,16(sp)
    8000530c:	69a2                	ld	s3,8(sp)
    8000530e:	6145                	addi	sp,sp,48
    80005310:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005312:	6908                	ld	a0,16(a0)
    80005314:	00000097          	auipc	ra,0x0
    80005318:	3c0080e7          	jalr	960(ra) # 800056d4 <piperead>
    8000531c:	892a                	mv	s2,a0
    8000531e:	b7d5                	j	80005302 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005320:	02451783          	lh	a5,36(a0)
    80005324:	03079693          	slli	a3,a5,0x30
    80005328:	92c1                	srli	a3,a3,0x30
    8000532a:	4725                	li	a4,9
    8000532c:	02d76863          	bltu	a4,a3,8000535c <kfileread+0xba>
    80005330:	0792                	slli	a5,a5,0x4
    80005332:	00024717          	auipc	a4,0x24
    80005336:	3e670713          	addi	a4,a4,998 # 80029718 <devsw>
    8000533a:	97ba                	add	a5,a5,a4
    8000533c:	639c                	ld	a5,0(a5)
    8000533e:	c38d                	beqz	a5,80005360 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005340:	4505                	li	a0,1
    80005342:	9782                	jalr	a5
    80005344:	892a                	mv	s2,a0
    80005346:	bf75                	j	80005302 <kfileread+0x60>
    panic("fileread");
    80005348:	00003517          	auipc	a0,0x3
    8000534c:	67850513          	addi	a0,a0,1656 # 800089c0 <syscalls+0x2c8>
    80005350:	ffffb097          	auipc	ra,0xffffb
    80005354:	1da080e7          	jalr	474(ra) # 8000052a <panic>
    return -1;
    80005358:	597d                	li	s2,-1
    8000535a:	b765                	j	80005302 <kfileread+0x60>
      return -1;
    8000535c:	597d                	li	s2,-1
    8000535e:	b755                	j	80005302 <kfileread+0x60>
    80005360:	597d                	li	s2,-1
    80005362:	b745                	j	80005302 <kfileread+0x60>

0000000080005364 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005364:	715d                	addi	sp,sp,-80
    80005366:	e486                	sd	ra,72(sp)
    80005368:	e0a2                	sd	s0,64(sp)
    8000536a:	fc26                	sd	s1,56(sp)
    8000536c:	f84a                	sd	s2,48(sp)
    8000536e:	f44e                	sd	s3,40(sp)
    80005370:	f052                	sd	s4,32(sp)
    80005372:	ec56                	sd	s5,24(sp)
    80005374:	e85a                	sd	s6,16(sp)
    80005376:	e45e                	sd	s7,8(sp)
    80005378:	e062                	sd	s8,0(sp)
    8000537a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000537c:	00954783          	lbu	a5,9(a0)
    80005380:	10078663          	beqz	a5,8000548c <kfilewrite+0x128>
    80005384:	892a                	mv	s2,a0
    80005386:	8aae                	mv	s5,a1
    80005388:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000538a:	411c                	lw	a5,0(a0)
    8000538c:	4705                	li	a4,1
    8000538e:	02e78263          	beq	a5,a4,800053b2 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005392:	470d                	li	a4,3
    80005394:	02e78663          	beq	a5,a4,800053c0 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005398:	4709                	li	a4,2
    8000539a:	0ee79163          	bne	a5,a4,8000547c <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000539e:	0ac05d63          	blez	a2,80005458 <kfilewrite+0xf4>
    int i = 0;
    800053a2:	4981                	li	s3,0
    800053a4:	6b05                	lui	s6,0x1
    800053a6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800053aa:	6b85                	lui	s7,0x1
    800053ac:	c00b8b9b          	addiw	s7,s7,-1024
    800053b0:	a861                	j	80005448 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800053b2:	6908                	ld	a0,16(a0)
    800053b4:	00000097          	auipc	ra,0x0
    800053b8:	22e080e7          	jalr	558(ra) # 800055e2 <pipewrite>
    800053bc:	8a2a                	mv	s4,a0
    800053be:	a045                	j	8000545e <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053c0:	02451783          	lh	a5,36(a0)
    800053c4:	03079693          	slli	a3,a5,0x30
    800053c8:	92c1                	srli	a3,a3,0x30
    800053ca:	4725                	li	a4,9
    800053cc:	0cd76263          	bltu	a4,a3,80005490 <kfilewrite+0x12c>
    800053d0:	0792                	slli	a5,a5,0x4
    800053d2:	00024717          	auipc	a4,0x24
    800053d6:	34670713          	addi	a4,a4,838 # 80029718 <devsw>
    800053da:	97ba                	add	a5,a5,a4
    800053dc:	679c                	ld	a5,8(a5)
    800053de:	cbdd                	beqz	a5,80005494 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053e0:	4505                	li	a0,1
    800053e2:	9782                	jalr	a5
    800053e4:	8a2a                	mv	s4,a0
    800053e6:	a8a5                	j	8000545e <kfilewrite+0xfa>
    800053e8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	6ba080e7          	jalr	1722(ra) # 80004aa6 <begin_op>
      ilock(f->ip);
    800053f4:	01893503          	ld	a0,24(s2)
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	9c6080e7          	jalr	-1594(ra) # 80003dbe <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80005400:	8762                	mv	a4,s8
    80005402:	02092683          	lw	a3,32(s2)
    80005406:	01598633          	add	a2,s3,s5
    8000540a:	4581                	li	a1,0
    8000540c:	01893503          	ld	a0,24(s2)
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	d5a080e7          	jalr	-678(ra) # 8000416a <writei>
    80005418:	84aa                	mv	s1,a0
    8000541a:	00a05763          	blez	a0,80005428 <kfilewrite+0xc4>
        f->off += r;
    8000541e:	02092783          	lw	a5,32(s2)
    80005422:	9fa9                	addw	a5,a5,a0
    80005424:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005428:	01893503          	ld	a0,24(s2)
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	a54080e7          	jalr	-1452(ra) # 80003e80 <iunlock>
      end_op();
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	6f2080e7          	jalr	1778(ra) # 80004b26 <end_op>

      if(r != n1){
    8000543c:	009c1f63          	bne	s8,s1,8000545a <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005440:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005444:	0149db63          	bge	s3,s4,8000545a <kfilewrite+0xf6>
      int n1 = n - i;
    80005448:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000544c:	84be                	mv	s1,a5
    8000544e:	2781                	sext.w	a5,a5
    80005450:	f8fb5ce3          	bge	s6,a5,800053e8 <kfilewrite+0x84>
    80005454:	84de                	mv	s1,s7
    80005456:	bf49                	j	800053e8 <kfilewrite+0x84>
    int i = 0;
    80005458:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000545a:	013a1f63          	bne	s4,s3,80005478 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    8000545e:	8552                	mv	a0,s4
    80005460:	60a6                	ld	ra,72(sp)
    80005462:	6406                	ld	s0,64(sp)
    80005464:	74e2                	ld	s1,56(sp)
    80005466:	7942                	ld	s2,48(sp)
    80005468:	79a2                	ld	s3,40(sp)
    8000546a:	7a02                	ld	s4,32(sp)
    8000546c:	6ae2                	ld	s5,24(sp)
    8000546e:	6b42                	ld	s6,16(sp)
    80005470:	6ba2                	ld	s7,8(sp)
    80005472:	6c02                	ld	s8,0(sp)
    80005474:	6161                	addi	sp,sp,80
    80005476:	8082                	ret
    ret = (i == n ? n : -1);
    80005478:	5a7d                	li	s4,-1
    8000547a:	b7d5                	j	8000545e <kfilewrite+0xfa>
    panic("filewrite");
    8000547c:	00003517          	auipc	a0,0x3
    80005480:	55450513          	addi	a0,a0,1364 # 800089d0 <syscalls+0x2d8>
    80005484:	ffffb097          	auipc	ra,0xffffb
    80005488:	0a6080e7          	jalr	166(ra) # 8000052a <panic>
    return -1;
    8000548c:	5a7d                	li	s4,-1
    8000548e:	bfc1                	j	8000545e <kfilewrite+0xfa>
      return -1;
    80005490:	5a7d                	li	s4,-1
    80005492:	b7f1                	j	8000545e <kfilewrite+0xfa>
    80005494:	5a7d                	li	s4,-1
    80005496:	b7e1                	j	8000545e <kfilewrite+0xfa>

0000000080005498 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005498:	7179                	addi	sp,sp,-48
    8000549a:	f406                	sd	ra,40(sp)
    8000549c:	f022                	sd	s0,32(sp)
    8000549e:	ec26                	sd	s1,24(sp)
    800054a0:	e84a                	sd	s2,16(sp)
    800054a2:	e44e                	sd	s3,8(sp)
    800054a4:	e052                	sd	s4,0(sp)
    800054a6:	1800                	addi	s0,sp,48
    800054a8:	84aa                	mv	s1,a0
    800054aa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800054ac:	0005b023          	sd	zero,0(a1)
    800054b0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800054b4:	00000097          	auipc	ra,0x0
    800054b8:	a02080e7          	jalr	-1534(ra) # 80004eb6 <filealloc>
    800054bc:	e088                	sd	a0,0(s1)
    800054be:	c551                	beqz	a0,8000554a <pipealloc+0xb2>
    800054c0:	00000097          	auipc	ra,0x0
    800054c4:	9f6080e7          	jalr	-1546(ra) # 80004eb6 <filealloc>
    800054c8:	00aa3023          	sd	a0,0(s4)
    800054cc:	c92d                	beqz	a0,8000553e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800054ce:	ffffb097          	auipc	ra,0xffffb
    800054d2:	604080e7          	jalr	1540(ra) # 80000ad2 <kalloc>
    800054d6:	892a                	mv	s2,a0
    800054d8:	c125                	beqz	a0,80005538 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800054da:	4985                	li	s3,1
    800054dc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800054e0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800054e4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800054e8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800054ec:	00003597          	auipc	a1,0x3
    800054f0:	4f458593          	addi	a1,a1,1268 # 800089e0 <syscalls+0x2e8>
    800054f4:	ffffb097          	auipc	ra,0xffffb
    800054f8:	63e080e7          	jalr	1598(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800054fc:	609c                	ld	a5,0(s1)
    800054fe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005502:	609c                	ld	a5,0(s1)
    80005504:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005508:	609c                	ld	a5,0(s1)
    8000550a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000550e:	609c                	ld	a5,0(s1)
    80005510:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005514:	000a3783          	ld	a5,0(s4)
    80005518:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000551c:	000a3783          	ld	a5,0(s4)
    80005520:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005524:	000a3783          	ld	a5,0(s4)
    80005528:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000552c:	000a3783          	ld	a5,0(s4)
    80005530:	0127b823          	sd	s2,16(a5)
  return 0;
    80005534:	4501                	li	a0,0
    80005536:	a025                	j	8000555e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005538:	6088                	ld	a0,0(s1)
    8000553a:	e501                	bnez	a0,80005542 <pipealloc+0xaa>
    8000553c:	a039                	j	8000554a <pipealloc+0xb2>
    8000553e:	6088                	ld	a0,0(s1)
    80005540:	c51d                	beqz	a0,8000556e <pipealloc+0xd6>
    fileclose(*f0);
    80005542:	00000097          	auipc	ra,0x0
    80005546:	a30080e7          	jalr	-1488(ra) # 80004f72 <fileclose>
  if(*f1)
    8000554a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000554e:	557d                	li	a0,-1
  if(*f1)
    80005550:	c799                	beqz	a5,8000555e <pipealloc+0xc6>
    fileclose(*f1);
    80005552:	853e                	mv	a0,a5
    80005554:	00000097          	auipc	ra,0x0
    80005558:	a1e080e7          	jalr	-1506(ra) # 80004f72 <fileclose>
  return -1;
    8000555c:	557d                	li	a0,-1
}
    8000555e:	70a2                	ld	ra,40(sp)
    80005560:	7402                	ld	s0,32(sp)
    80005562:	64e2                	ld	s1,24(sp)
    80005564:	6942                	ld	s2,16(sp)
    80005566:	69a2                	ld	s3,8(sp)
    80005568:	6a02                	ld	s4,0(sp)
    8000556a:	6145                	addi	sp,sp,48
    8000556c:	8082                	ret
  return -1;
    8000556e:	557d                	li	a0,-1
    80005570:	b7fd                	j	8000555e <pipealloc+0xc6>

0000000080005572 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005572:	1101                	addi	sp,sp,-32
    80005574:	ec06                	sd	ra,24(sp)
    80005576:	e822                	sd	s0,16(sp)
    80005578:	e426                	sd	s1,8(sp)
    8000557a:	e04a                	sd	s2,0(sp)
    8000557c:	1000                	addi	s0,sp,32
    8000557e:	84aa                	mv	s1,a0
    80005580:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005582:	ffffb097          	auipc	ra,0xffffb
    80005586:	640080e7          	jalr	1600(ra) # 80000bc2 <acquire>
  if(writable){
    8000558a:	02090d63          	beqz	s2,800055c4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000558e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005592:	21848513          	addi	a0,s1,536
    80005596:	ffffd097          	auipc	ra,0xffffd
    8000559a:	b30080e7          	jalr	-1232(ra) # 800020c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000559e:	2204b783          	ld	a5,544(s1)
    800055a2:	eb95                	bnez	a5,800055d6 <pipeclose+0x64>
    release(&pi->lock);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffb097          	auipc	ra,0xffffb
    800055aa:	6d0080e7          	jalr	1744(ra) # 80000c76 <release>
    kfree((char*)pi);
    800055ae:	8526                	mv	a0,s1
    800055b0:	ffffb097          	auipc	ra,0xffffb
    800055b4:	426080e7          	jalr	1062(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800055b8:	60e2                	ld	ra,24(sp)
    800055ba:	6442                	ld	s0,16(sp)
    800055bc:	64a2                	ld	s1,8(sp)
    800055be:	6902                	ld	s2,0(sp)
    800055c0:	6105                	addi	sp,sp,32
    800055c2:	8082                	ret
    pi->readopen = 0;
    800055c4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800055c8:	21c48513          	addi	a0,s1,540
    800055cc:	ffffd097          	auipc	ra,0xffffd
    800055d0:	afa080e7          	jalr	-1286(ra) # 800020c6 <wakeup>
    800055d4:	b7e9                	j	8000559e <pipeclose+0x2c>
    release(&pi->lock);
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffb097          	auipc	ra,0xffffb
    800055dc:	69e080e7          	jalr	1694(ra) # 80000c76 <release>
}
    800055e0:	bfe1                	j	800055b8 <pipeclose+0x46>

00000000800055e2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800055e2:	711d                	addi	sp,sp,-96
    800055e4:	ec86                	sd	ra,88(sp)
    800055e6:	e8a2                	sd	s0,80(sp)
    800055e8:	e4a6                	sd	s1,72(sp)
    800055ea:	e0ca                	sd	s2,64(sp)
    800055ec:	fc4e                	sd	s3,56(sp)
    800055ee:	f852                	sd	s4,48(sp)
    800055f0:	f456                	sd	s5,40(sp)
    800055f2:	f05a                	sd	s6,32(sp)
    800055f4:	ec5e                	sd	s7,24(sp)
    800055f6:	e862                	sd	s8,16(sp)
    800055f8:	1080                	addi	s0,sp,96
    800055fa:	84aa                	mv	s1,a0
    800055fc:	8aae                	mv	s5,a1
    800055fe:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005600:	ffffc097          	auipc	ra,0xffffc
    80005604:	3d4080e7          	jalr	980(ra) # 800019d4 <myproc>
    80005608:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffb097          	auipc	ra,0xffffb
    80005610:	5b6080e7          	jalr	1462(ra) # 80000bc2 <acquire>
  while(i < n){
    80005614:	0b405363          	blez	s4,800056ba <pipewrite+0xd8>
  int i = 0;
    80005618:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000561a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000561c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005620:	21c48b93          	addi	s7,s1,540
    80005624:	a089                	j	80005666 <pipewrite+0x84>
      release(&pi->lock);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffb097          	auipc	ra,0xffffb
    8000562c:	64e080e7          	jalr	1614(ra) # 80000c76 <release>
      return -1;
    80005630:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005632:	854a                	mv	a0,s2
    80005634:	60e6                	ld	ra,88(sp)
    80005636:	6446                	ld	s0,80(sp)
    80005638:	64a6                	ld	s1,72(sp)
    8000563a:	6906                	ld	s2,64(sp)
    8000563c:	79e2                	ld	s3,56(sp)
    8000563e:	7a42                	ld	s4,48(sp)
    80005640:	7aa2                	ld	s5,40(sp)
    80005642:	7b02                	ld	s6,32(sp)
    80005644:	6be2                	ld	s7,24(sp)
    80005646:	6c42                	ld	s8,16(sp)
    80005648:	6125                	addi	sp,sp,96
    8000564a:	8082                	ret
      wakeup(&pi->nread);
    8000564c:	8562                	mv	a0,s8
    8000564e:	ffffd097          	auipc	ra,0xffffd
    80005652:	a78080e7          	jalr	-1416(ra) # 800020c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005656:	85a6                	mv	a1,s1
    80005658:	855e                	mv	a0,s7
    8000565a:	ffffd097          	auipc	ra,0xffffd
    8000565e:	a08080e7          	jalr	-1528(ra) # 80002062 <sleep>
  while(i < n){
    80005662:	05495d63          	bge	s2,s4,800056bc <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005666:	2204a783          	lw	a5,544(s1)
    8000566a:	dfd5                	beqz	a5,80005626 <pipewrite+0x44>
    8000566c:	0289a783          	lw	a5,40(s3)
    80005670:	fbdd                	bnez	a5,80005626 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005672:	2184a783          	lw	a5,536(s1)
    80005676:	21c4a703          	lw	a4,540(s1)
    8000567a:	2007879b          	addiw	a5,a5,512
    8000567e:	fcf707e3          	beq	a4,a5,8000564c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005682:	4685                	li	a3,1
    80005684:	01590633          	add	a2,s2,s5
    80005688:	faf40593          	addi	a1,s0,-81
    8000568c:	0509b503          	ld	a0,80(s3)
    80005690:	ffffc097          	auipc	ra,0xffffc
    80005694:	090080e7          	jalr	144(ra) # 80001720 <copyin>
    80005698:	03650263          	beq	a0,s6,800056bc <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000569c:	21c4a783          	lw	a5,540(s1)
    800056a0:	0017871b          	addiw	a4,a5,1
    800056a4:	20e4ae23          	sw	a4,540(s1)
    800056a8:	1ff7f793          	andi	a5,a5,511
    800056ac:	97a6                	add	a5,a5,s1
    800056ae:	faf44703          	lbu	a4,-81(s0)
    800056b2:	00e78c23          	sb	a4,24(a5)
      i++;
    800056b6:	2905                	addiw	s2,s2,1
    800056b8:	b76d                	j	80005662 <pipewrite+0x80>
  int i = 0;
    800056ba:	4901                	li	s2,0
  wakeup(&pi->nread);
    800056bc:	21848513          	addi	a0,s1,536
    800056c0:	ffffd097          	auipc	ra,0xffffd
    800056c4:	a06080e7          	jalr	-1530(ra) # 800020c6 <wakeup>
  release(&pi->lock);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffb097          	auipc	ra,0xffffb
    800056ce:	5ac080e7          	jalr	1452(ra) # 80000c76 <release>
  return i;
    800056d2:	b785                	j	80005632 <pipewrite+0x50>

00000000800056d4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800056d4:	715d                	addi	sp,sp,-80
    800056d6:	e486                	sd	ra,72(sp)
    800056d8:	e0a2                	sd	s0,64(sp)
    800056da:	fc26                	sd	s1,56(sp)
    800056dc:	f84a                	sd	s2,48(sp)
    800056de:	f44e                	sd	s3,40(sp)
    800056e0:	f052                	sd	s4,32(sp)
    800056e2:	ec56                	sd	s5,24(sp)
    800056e4:	e85a                	sd	s6,16(sp)
    800056e6:	0880                	addi	s0,sp,80
    800056e8:	84aa                	mv	s1,a0
    800056ea:	892e                	mv	s2,a1
    800056ec:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056ee:	ffffc097          	auipc	ra,0xffffc
    800056f2:	2e6080e7          	jalr	742(ra) # 800019d4 <myproc>
    800056f6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffb097          	auipc	ra,0xffffb
    800056fe:	4c8080e7          	jalr	1224(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005702:	2184a703          	lw	a4,536(s1)
    80005706:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000570a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000570e:	02f71463          	bne	a4,a5,80005736 <piperead+0x62>
    80005712:	2244a783          	lw	a5,548(s1)
    80005716:	c385                	beqz	a5,80005736 <piperead+0x62>
    if(pr->killed){
    80005718:	028a2783          	lw	a5,40(s4)
    8000571c:	ebc1                	bnez	a5,800057ac <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000571e:	85a6                	mv	a1,s1
    80005720:	854e                	mv	a0,s3
    80005722:	ffffd097          	auipc	ra,0xffffd
    80005726:	940080e7          	jalr	-1728(ra) # 80002062 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000572a:	2184a703          	lw	a4,536(s1)
    8000572e:	21c4a783          	lw	a5,540(s1)
    80005732:	fef700e3          	beq	a4,a5,80005712 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005736:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005738:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000573a:	05505363          	blez	s5,80005780 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000573e:	2184a783          	lw	a5,536(s1)
    80005742:	21c4a703          	lw	a4,540(s1)
    80005746:	02f70d63          	beq	a4,a5,80005780 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000574a:	0017871b          	addiw	a4,a5,1
    8000574e:	20e4ac23          	sw	a4,536(s1)
    80005752:	1ff7f793          	andi	a5,a5,511
    80005756:	97a6                	add	a5,a5,s1
    80005758:	0187c783          	lbu	a5,24(a5)
    8000575c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005760:	4685                	li	a3,1
    80005762:	fbf40613          	addi	a2,s0,-65
    80005766:	85ca                	mv	a1,s2
    80005768:	050a3503          	ld	a0,80(s4)
    8000576c:	ffffc097          	auipc	ra,0xffffc
    80005770:	f28080e7          	jalr	-216(ra) # 80001694 <copyout>
    80005774:	01650663          	beq	a0,s6,80005780 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005778:	2985                	addiw	s3,s3,1
    8000577a:	0905                	addi	s2,s2,1
    8000577c:	fd3a91e3          	bne	s5,s3,8000573e <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005780:	21c48513          	addi	a0,s1,540
    80005784:	ffffd097          	auipc	ra,0xffffd
    80005788:	942080e7          	jalr	-1726(ra) # 800020c6 <wakeup>
  release(&pi->lock);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffb097          	auipc	ra,0xffffb
    80005792:	4e8080e7          	jalr	1256(ra) # 80000c76 <release>
  return i;
}
    80005796:	854e                	mv	a0,s3
    80005798:	60a6                	ld	ra,72(sp)
    8000579a:	6406                	ld	s0,64(sp)
    8000579c:	74e2                	ld	s1,56(sp)
    8000579e:	7942                	ld	s2,48(sp)
    800057a0:	79a2                	ld	s3,40(sp)
    800057a2:	7a02                	ld	s4,32(sp)
    800057a4:	6ae2                	ld	s5,24(sp)
    800057a6:	6b42                	ld	s6,16(sp)
    800057a8:	6161                	addi	sp,sp,80
    800057aa:	8082                	ret
      release(&pi->lock);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffb097          	auipc	ra,0xffffb
    800057b2:	4c8080e7          	jalr	1224(ra) # 80000c76 <release>
      return -1;
    800057b6:	59fd                	li	s3,-1
    800057b8:	bff9                	j	80005796 <piperead+0xc2>

00000000800057ba <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800057ba:	bd010113          	addi	sp,sp,-1072
    800057be:	42113423          	sd	ra,1064(sp)
    800057c2:	42813023          	sd	s0,1056(sp)
    800057c6:	40913c23          	sd	s1,1048(sp)
    800057ca:	41213823          	sd	s2,1040(sp)
    800057ce:	41313423          	sd	s3,1032(sp)
    800057d2:	41413023          	sd	s4,1024(sp)
    800057d6:	3f513c23          	sd	s5,1016(sp)
    800057da:	3f613823          	sd	s6,1008(sp)
    800057de:	3f713423          	sd	s7,1000(sp)
    800057e2:	3f813023          	sd	s8,992(sp)
    800057e6:	3d913c23          	sd	s9,984(sp)
    800057ea:	3da13823          	sd	s10,976(sp)
    800057ee:	3db13423          	sd	s11,968(sp)
    800057f2:	43010413          	addi	s0,sp,1072
    800057f6:	89aa                	mv	s3,a0
    800057f8:	bea43023          	sd	a0,-1056(s0)
    800057fc:	beb43423          	sd	a1,-1048(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005800:	ffffc097          	auipc	ra,0xffffc
    80005804:	1d4080e7          	jalr	468(ra) # 800019d4 <myproc>
    80005808:	84aa                	mv	s1,a0
    8000580a:	c0a43423          	sd	a0,-1016(s0)

  // ADDED Q1
  struct ram_page ram_pages_backup[MAX_PSYC_PAGES];
  struct disk_page disk_pages_backup[MAX_DISK_PAGES];
  memmove(ram_pages_backup, p->ram_pages, sizeof(p->ram_pages));
    8000580e:	17050913          	addi	s2,a0,368
    80005812:	10000613          	li	a2,256
    80005816:	85ca                	mv	a1,s2
    80005818:	d1040513          	addi	a0,s0,-752
    8000581c:	ffffb097          	auipc	ra,0xffffb
    80005820:	4fe080e7          	jalr	1278(ra) # 80000d1a <memmove>
  memmove(disk_pages_backup, p->disk_pages, sizeof(p->disk_pages));
    80005824:	27048493          	addi	s1,s1,624
    80005828:	10000613          	li	a2,256
    8000582c:	85a6                	mv	a1,s1
    8000582e:	c1040513          	addi	a0,s0,-1008
    80005832:	ffffb097          	auipc	ra,0xffffb
    80005836:	4e8080e7          	jalr	1256(ra) # 80000d1a <memmove>

  begin_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	26c080e7          	jalr	620(ra) # 80004aa6 <begin_op>

  if((ip = namei(path)) == 0){
    80005842:	854e                	mv	a0,s3
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	d30080e7          	jalr	-720(ra) # 80004574 <namei>
    8000584c:	c569                	beqz	a0,80005916 <exec+0x15c>
    8000584e:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	56e080e7          	jalr	1390(ra) # 80003dbe <ilock>

  // ADDED Q1
  if(relevant_metadata_proc(p) && init_metadata(p) < 0) {
    80005858:	c0843983          	ld	s3,-1016(s0)
    8000585c:	854e                	mv	a0,s3
    8000585e:	ffffc097          	auipc	ra,0xffffc
    80005862:	544080e7          	jalr	1348(ra) # 80001da2 <relevant_metadata_proc>
    80005866:	c901                	beqz	a0,80005876 <exec+0xbc>
    80005868:	854e                	mv	a0,s3
    8000586a:	ffffd097          	auipc	ra,0xffffd
    8000586e:	afa080e7          	jalr	-1286(ra) # 80002364 <init_metadata>
    80005872:	02054963          	bltz	a0,800058a4 <exec+0xea>
    goto bad;
  } 

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005876:	04000713          	li	a4,64
    8000587a:	4681                	li	a3,0
    8000587c:	e4840613          	addi	a2,s0,-440
    80005880:	4581                	li	a1,0
    80005882:	8552                	mv	a0,s4
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	7ee080e7          	jalr	2030(ra) # 80004072 <readi>
    8000588c:	04000793          	li	a5,64
    80005890:	00f51a63          	bne	a0,a5,800058a4 <exec+0xea>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005894:	e4842703          	lw	a4,-440(s0)
    80005898:	464c47b7          	lui	a5,0x464c4
    8000589c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058a0:	08f70163          	beq	a4,a5,80005922 <exec+0x168>

  return argc; // this ends up in a0, the first argument to main(argc, argv)

 bad:
  // ADDED Q1
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    800058a4:	10000613          	li	a2,256
    800058a8:	d1040593          	addi	a1,s0,-752
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffb097          	auipc	ra,0xffffb
    800058b2:	46c080e7          	jalr	1132(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    800058b6:	10000613          	li	a2,256
    800058ba:	c1040593          	addi	a1,s0,-1008
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffb097          	auipc	ra,0xffffb
    800058c4:	45a080e7          	jalr	1114(ra) # 80000d1a <memmove>
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800058c8:	8552                	mv	a0,s4
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	756080e7          	jalr	1878(ra) # 80004020 <iunlockput>
    end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	254080e7          	jalr	596(ra) # 80004b26 <end_op>
  }
  return -1;
    800058da:	557d                	li	a0,-1
}
    800058dc:	42813083          	ld	ra,1064(sp)
    800058e0:	42013403          	ld	s0,1056(sp)
    800058e4:	41813483          	ld	s1,1048(sp)
    800058e8:	41013903          	ld	s2,1040(sp)
    800058ec:	40813983          	ld	s3,1032(sp)
    800058f0:	40013a03          	ld	s4,1024(sp)
    800058f4:	3f813a83          	ld	s5,1016(sp)
    800058f8:	3f013b03          	ld	s6,1008(sp)
    800058fc:	3e813b83          	ld	s7,1000(sp)
    80005900:	3e013c03          	ld	s8,992(sp)
    80005904:	3d813c83          	ld	s9,984(sp)
    80005908:	3d013d03          	ld	s10,976(sp)
    8000590c:	3c813d83          	ld	s11,968(sp)
    80005910:	43010113          	addi	sp,sp,1072
    80005914:	8082                	ret
    end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	210080e7          	jalr	528(ra) # 80004b26 <end_op>
    return -1;
    8000591e:	557d                	li	a0,-1
    80005920:	bf75                	j	800058dc <exec+0x122>
  if((pagetable = proc_pagetable(p)) == 0)
    80005922:	c0843503          	ld	a0,-1016(s0)
    80005926:	ffffc097          	auipc	ra,0xffffc
    8000592a:	172080e7          	jalr	370(ra) # 80001a98 <proc_pagetable>
    8000592e:	8b2a                	mv	s6,a0
    80005930:	d935                	beqz	a0,800058a4 <exec+0xea>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005932:	e6842783          	lw	a5,-408(s0)
    80005936:	e8045703          	lhu	a4,-384(s0)
    8000593a:	c735                	beqz	a4,800059a6 <exec+0x1ec>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000593c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000593e:	c0043023          	sd	zero,-1024(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005942:	6a85                	lui	s5,0x1
    80005944:	fffa8713          	addi	a4,s5,-1 # fff <_entry-0x7ffff001>
    80005948:	bce43c23          	sd	a4,-1064(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    8000594c:	6d85                	lui	s11,0x1
    8000594e:	7d7d                	lui	s10,0xfffff
    80005950:	a4ad                	j	80005bba <exec+0x400>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005952:	00003517          	auipc	a0,0x3
    80005956:	09650513          	addi	a0,a0,150 # 800089e8 <syscalls+0x2f0>
    8000595a:	ffffb097          	auipc	ra,0xffffb
    8000595e:	bd0080e7          	jalr	-1072(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005962:	874a                	mv	a4,s2
    80005964:	009c86bb          	addw	a3,s9,s1
    80005968:	4581                	li	a1,0
    8000596a:	8552                	mv	a0,s4
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	706080e7          	jalr	1798(ra) # 80004072 <readi>
    80005974:	2501                	sext.w	a0,a0
    80005976:	1aa91c63          	bne	s2,a0,80005b2e <exec+0x374>
  for(i = 0; i < sz; i += PGSIZE){
    8000597a:	009d84bb          	addw	s1,s11,s1
    8000597e:	013d09bb          	addw	s3,s10,s3
    80005982:	2174fc63          	bgeu	s1,s7,80005b9a <exec+0x3e0>
    pa = walkaddr(pagetable, va + i);
    80005986:	02049593          	slli	a1,s1,0x20
    8000598a:	9181                	srli	a1,a1,0x20
    8000598c:	95e2                	add	a1,a1,s8
    8000598e:	855a                	mv	a0,s6
    80005990:	ffffb097          	auipc	ra,0xffffb
    80005994:	6bc080e7          	jalr	1724(ra) # 8000104c <walkaddr>
    80005998:	862a                	mv	a2,a0
    if(pa == 0)
    8000599a:	dd45                	beqz	a0,80005952 <exec+0x198>
      n = PGSIZE;
    8000599c:	8956                	mv	s2,s5
    if(sz - i < PGSIZE)
    8000599e:	fd59f2e3          	bgeu	s3,s5,80005962 <exec+0x1a8>
      n = sz - i;
    800059a2:	894e                	mv	s2,s3
    800059a4:	bf7d                	j	80005962 <exec+0x1a8>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800059a6:	4481                	li	s1,0
  iunlockput(ip);
    800059a8:	8552                	mv	a0,s4
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	676080e7          	jalr	1654(ra) # 80004020 <iunlockput>
  end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	174080e7          	jalr	372(ra) # 80004b26 <end_op>
  p = myproc();
    800059ba:	ffffc097          	auipc	ra,0xffffc
    800059be:	01a080e7          	jalr	26(ra) # 800019d4 <myproc>
    800059c2:	c0a43423          	sd	a0,-1016(s0)
  uint64 oldsz = p->sz;
    800059c6:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800059ca:	6785                	lui	a5,0x1
    800059cc:	17fd                	addi	a5,a5,-1
    800059ce:	94be                	add	s1,s1,a5
    800059d0:	77fd                	lui	a5,0xfffff
    800059d2:	8fe5                	and	a5,a5,s1
    800059d4:	bef43823          	sd	a5,-1040(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800059d8:	6609                	lui	a2,0x2
    800059da:	963e                	add	a2,a2,a5
    800059dc:	85be                	mv	a1,a5
    800059de:	855a                	mv	a0,s6
    800059e0:	ffffc097          	auipc	ra,0xffffc
    800059e4:	a54080e7          	jalr	-1452(ra) # 80001434 <uvmalloc>
    800059e8:	8aaa                	mv	s5,a0
  ip = 0;
    800059ea:	4a01                	li	s4,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800059ec:	14050163          	beqz	a0,80005b2e <exec+0x374>
  uvmclear(pagetable, sz-2*PGSIZE);
    800059f0:	75f9                	lui	a1,0xffffe
    800059f2:	95aa                	add	a1,a1,a0
    800059f4:	855a                	mv	a0,s6
    800059f6:	ffffc097          	auipc	ra,0xffffc
    800059fa:	c6c080e7          	jalr	-916(ra) # 80001662 <uvmclear>
  stackbase = sp - PGSIZE;
    800059fe:	7bfd                	lui	s7,0xfffff
    80005a00:	9bd6                	add	s7,s7,s5
  for(argc = 0; argv[argc]; argc++) {
    80005a02:	be843783          	ld	a5,-1048(s0)
    80005a06:	6388                	ld	a0,0(a5)
    80005a08:	c925                	beqz	a0,80005a78 <exec+0x2be>
    80005a0a:	e8840993          	addi	s3,s0,-376
    80005a0e:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005a12:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005a14:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005a16:	ffffb097          	auipc	ra,0xffffb
    80005a1a:	42c080e7          	jalr	1068(ra) # 80000e42 <strlen>
    80005a1e:	0015079b          	addiw	a5,a0,1
    80005a22:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a26:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a2a:	15796c63          	bltu	s2,s7,80005b82 <exec+0x3c8>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005a2e:	be843d03          	ld	s10,-1048(s0)
    80005a32:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd1000>
    80005a36:	8552                	mv	a0,s4
    80005a38:	ffffb097          	auipc	ra,0xffffb
    80005a3c:	40a080e7          	jalr	1034(ra) # 80000e42 <strlen>
    80005a40:	0015069b          	addiw	a3,a0,1
    80005a44:	8652                	mv	a2,s4
    80005a46:	85ca                	mv	a1,s2
    80005a48:	855a                	mv	a0,s6
    80005a4a:	ffffc097          	auipc	ra,0xffffc
    80005a4e:	c4a080e7          	jalr	-950(ra) # 80001694 <copyout>
    80005a52:	12054c63          	bltz	a0,80005b8a <exec+0x3d0>
    ustack[argc] = sp;
    80005a56:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005a5a:	0485                	addi	s1,s1,1
    80005a5c:	008d0793          	addi	a5,s10,8
    80005a60:	bef43423          	sd	a5,-1048(s0)
    80005a64:	008d3503          	ld	a0,8(s10)
    80005a68:	c911                	beqz	a0,80005a7c <exec+0x2c2>
    if(argc >= MAXARG)
    80005a6a:	09a1                	addi	s3,s3,8
    80005a6c:	fb8995e3          	bne	s3,s8,80005a16 <exec+0x25c>
  sz = sz1;
    80005a70:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005a74:	4a01                	li	s4,0
    80005a76:	a865                	j	80005b2e <exec+0x374>
  sp = sz;
    80005a78:	8956                	mv	s2,s5
  for(argc = 0; argv[argc]; argc++) {
    80005a7a:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a7c:	00349793          	slli	a5,s1,0x3
    80005a80:	f9040713          	addi	a4,s0,-112
    80005a84:	97ba                	add	a5,a5,a4
    80005a86:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd0ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005a8a:	00148693          	addi	a3,s1,1
    80005a8e:	068e                	slli	a3,a3,0x3
    80005a90:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a94:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a98:	01797663          	bgeu	s2,s7,80005aa4 <exec+0x2ea>
  sz = sz1;
    80005a9c:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005aa0:	4a01                	li	s4,0
    80005aa2:	a071                	j	80005b2e <exec+0x374>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005aa4:	e8840613          	addi	a2,s0,-376
    80005aa8:	85ca                	mv	a1,s2
    80005aaa:	855a                	mv	a0,s6
    80005aac:	ffffc097          	auipc	ra,0xffffc
    80005ab0:	be8080e7          	jalr	-1048(ra) # 80001694 <copyout>
    80005ab4:	0c054f63          	bltz	a0,80005b92 <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005ab8:	c0843783          	ld	a5,-1016(s0)
    80005abc:	6fbc                	ld	a5,88(a5)
    80005abe:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005ac2:	be043783          	ld	a5,-1056(s0)
    80005ac6:	0007c703          	lbu	a4,0(a5)
    80005aca:	cf11                	beqz	a4,80005ae6 <exec+0x32c>
    80005acc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005ace:	02f00693          	li	a3,47
    80005ad2:	a039                	j	80005ae0 <exec+0x326>
      last = s+1;
    80005ad4:	bef43023          	sd	a5,-1056(s0)
  for(last=s=path; *s; s++)
    80005ad8:	0785                	addi	a5,a5,1
    80005ada:	fff7c703          	lbu	a4,-1(a5)
    80005ade:	c701                	beqz	a4,80005ae6 <exec+0x32c>
    if(*s == '/')
    80005ae0:	fed71ce3          	bne	a4,a3,80005ad8 <exec+0x31e>
    80005ae4:	bfc5                	j	80005ad4 <exec+0x31a>
  safestrcpy(p->name, last, sizeof(p->name));
    80005ae6:	4641                	li	a2,16
    80005ae8:	be043583          	ld	a1,-1056(s0)
    80005aec:	c0843983          	ld	s3,-1016(s0)
    80005af0:	15898513          	addi	a0,s3,344
    80005af4:	ffffb097          	auipc	ra,0xffffb
    80005af8:	31c080e7          	jalr	796(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005afc:	0509b503          	ld	a0,80(s3)
  p->pagetable = pagetable;
    80005b00:	0569b823          	sd	s6,80(s3)
  p->sz = sz;
    80005b04:	0559b423          	sd	s5,72(s3)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005b08:	0589b783          	ld	a5,88(s3)
    80005b0c:	e6043703          	ld	a4,-416(s0)
    80005b10:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b12:	0589b783          	ld	a5,88(s3)
    80005b16:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b1a:	85e6                	mv	a1,s9
    80005b1c:	ffffc097          	auipc	ra,0xffffc
    80005b20:	018080e7          	jalr	24(ra) # 80001b34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b24:	0004851b          	sext.w	a0,s1
    80005b28:	bb55                	j	800058dc <exec+0x122>
    80005b2a:	be943823          	sd	s1,-1040(s0)
  memmove(p->ram_pages, ram_pages_backup, sizeof(ram_pages_backup));
    80005b2e:	10000613          	li	a2,256
    80005b32:	d1040593          	addi	a1,s0,-752
    80005b36:	c0843483          	ld	s1,-1016(s0)
    80005b3a:	17048513          	addi	a0,s1,368
    80005b3e:	ffffb097          	auipc	ra,0xffffb
    80005b42:	1dc080e7          	jalr	476(ra) # 80000d1a <memmove>
  memmove(p->disk_pages, disk_pages_backup, sizeof(disk_pages_backup));
    80005b46:	10000613          	li	a2,256
    80005b4a:	c1040593          	addi	a1,s0,-1008
    80005b4e:	27048513          	addi	a0,s1,624
    80005b52:	ffffb097          	auipc	ra,0xffffb
    80005b56:	1c8080e7          	jalr	456(ra) # 80000d1a <memmove>
    proc_freepagetable(pagetable, sz);
    80005b5a:	bf043583          	ld	a1,-1040(s0)
    80005b5e:	855a                	mv	a0,s6
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	fd4080e7          	jalr	-44(ra) # 80001b34 <proc_freepagetable>
  if(ip){
    80005b68:	d60a10e3          	bnez	s4,800058c8 <exec+0x10e>
  return -1;
    80005b6c:	557d                	li	a0,-1
    80005b6e:	b3bd                	j	800058dc <exec+0x122>
    80005b70:	be943823          	sd	s1,-1040(s0)
    80005b74:	bf6d                	j	80005b2e <exec+0x374>
    80005b76:	be943823          	sd	s1,-1040(s0)
    80005b7a:	bf55                	j	80005b2e <exec+0x374>
    80005b7c:	be943823          	sd	s1,-1040(s0)
    80005b80:	b77d                	j	80005b2e <exec+0x374>
  sz = sz1;
    80005b82:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005b86:	4a01                	li	s4,0
    80005b88:	b75d                	j	80005b2e <exec+0x374>
  sz = sz1;
    80005b8a:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005b8e:	4a01                	li	s4,0
    80005b90:	bf79                	j	80005b2e <exec+0x374>
  sz = sz1;
    80005b92:	bf543823          	sd	s5,-1040(s0)
  ip = 0;
    80005b96:	4a01                	li	s4,0
    80005b98:	bf59                	j	80005b2e <exec+0x374>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b9a:	bf043483          	ld	s1,-1040(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b9e:	c0043783          	ld	a5,-1024(s0)
    80005ba2:	0017869b          	addiw	a3,a5,1
    80005ba6:	c0d43023          	sd	a3,-1024(s0)
    80005baa:	bf843783          	ld	a5,-1032(s0)
    80005bae:	0387879b          	addiw	a5,a5,56
    80005bb2:	e8045703          	lhu	a4,-384(s0)
    80005bb6:	dee6d9e3          	bge	a3,a4,800059a8 <exec+0x1ee>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005bba:	2781                	sext.w	a5,a5
    80005bbc:	bef43c23          	sd	a5,-1032(s0)
    80005bc0:	03800713          	li	a4,56
    80005bc4:	86be                	mv	a3,a5
    80005bc6:	e1040613          	addi	a2,s0,-496
    80005bca:	4581                	li	a1,0
    80005bcc:	8552                	mv	a0,s4
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	4a4080e7          	jalr	1188(ra) # 80004072 <readi>
    80005bd6:	03800793          	li	a5,56
    80005bda:	f4f518e3          	bne	a0,a5,80005b2a <exec+0x370>
    if(ph.type != ELF_PROG_LOAD)
    80005bde:	e1042783          	lw	a5,-496(s0)
    80005be2:	4705                	li	a4,1
    80005be4:	fae79de3          	bne	a5,a4,80005b9e <exec+0x3e4>
    if(ph.memsz < ph.filesz)
    80005be8:	e3843603          	ld	a2,-456(s0)
    80005bec:	e3043783          	ld	a5,-464(s0)
    80005bf0:	f8f660e3          	bltu	a2,a5,80005b70 <exec+0x3b6>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005bf4:	e2043783          	ld	a5,-480(s0)
    80005bf8:	963e                	add	a2,a2,a5
    80005bfa:	f6f66ee3          	bltu	a2,a5,80005b76 <exec+0x3bc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005bfe:	85a6                	mv	a1,s1
    80005c00:	855a                	mv	a0,s6
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	832080e7          	jalr	-1998(ra) # 80001434 <uvmalloc>
    80005c0a:	bea43823          	sd	a0,-1040(s0)
    80005c0e:	d53d                	beqz	a0,80005b7c <exec+0x3c2>
    if(ph.vaddr % PGSIZE != 0)
    80005c10:	e2043c03          	ld	s8,-480(s0)
    80005c14:	bd843783          	ld	a5,-1064(s0)
    80005c18:	00fc77b3          	and	a5,s8,a5
    80005c1c:	fb89                	bnez	a5,80005b2e <exec+0x374>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005c1e:	e1842c83          	lw	s9,-488(s0)
    80005c22:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005c26:	f60b8ae3          	beqz	s7,80005b9a <exec+0x3e0>
    80005c2a:	89de                	mv	s3,s7
    80005c2c:	4481                	li	s1,0
    80005c2e:	bba1                	j	80005986 <exec+0x1cc>

0000000080005c30 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c30:	7179                	addi	sp,sp,-48
    80005c32:	f406                	sd	ra,40(sp)
    80005c34:	f022                	sd	s0,32(sp)
    80005c36:	ec26                	sd	s1,24(sp)
    80005c38:	e84a                	sd	s2,16(sp)
    80005c3a:	1800                	addi	s0,sp,48
    80005c3c:	892e                	mv	s2,a1
    80005c3e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005c40:	fdc40593          	addi	a1,s0,-36
    80005c44:	ffffd097          	auipc	ra,0xffffd
    80005c48:	608080e7          	jalr	1544(ra) # 8000324c <argint>
    80005c4c:	04054063          	bltz	a0,80005c8c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c50:	fdc42703          	lw	a4,-36(s0)
    80005c54:	47bd                	li	a5,15
    80005c56:	02e7ed63          	bltu	a5,a4,80005c90 <argfd+0x60>
    80005c5a:	ffffc097          	auipc	ra,0xffffc
    80005c5e:	d7a080e7          	jalr	-646(ra) # 800019d4 <myproc>
    80005c62:	fdc42703          	lw	a4,-36(s0)
    80005c66:	01a70793          	addi	a5,a4,26
    80005c6a:	078e                	slli	a5,a5,0x3
    80005c6c:	953e                	add	a0,a0,a5
    80005c6e:	611c                	ld	a5,0(a0)
    80005c70:	c395                	beqz	a5,80005c94 <argfd+0x64>
    return -1;
  if(pfd)
    80005c72:	00090463          	beqz	s2,80005c7a <argfd+0x4a>
    *pfd = fd;
    80005c76:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c7a:	4501                	li	a0,0
  if(pf)
    80005c7c:	c091                	beqz	s1,80005c80 <argfd+0x50>
    *pf = f;
    80005c7e:	e09c                	sd	a5,0(s1)
}
    80005c80:	70a2                	ld	ra,40(sp)
    80005c82:	7402                	ld	s0,32(sp)
    80005c84:	64e2                	ld	s1,24(sp)
    80005c86:	6942                	ld	s2,16(sp)
    80005c88:	6145                	addi	sp,sp,48
    80005c8a:	8082                	ret
    return -1;
    80005c8c:	557d                	li	a0,-1
    80005c8e:	bfcd                	j	80005c80 <argfd+0x50>
    return -1;
    80005c90:	557d                	li	a0,-1
    80005c92:	b7fd                	j	80005c80 <argfd+0x50>
    80005c94:	557d                	li	a0,-1
    80005c96:	b7ed                	j	80005c80 <argfd+0x50>

0000000080005c98 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005c98:	1101                	addi	sp,sp,-32
    80005c9a:	ec06                	sd	ra,24(sp)
    80005c9c:	e822                	sd	s0,16(sp)
    80005c9e:	e426                	sd	s1,8(sp)
    80005ca0:	1000                	addi	s0,sp,32
    80005ca2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005ca4:	ffffc097          	auipc	ra,0xffffc
    80005ca8:	d30080e7          	jalr	-720(ra) # 800019d4 <myproc>
    80005cac:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005cae:	0d050793          	addi	a5,a0,208
    80005cb2:	4501                	li	a0,0
    80005cb4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005cb6:	6398                	ld	a4,0(a5)
    80005cb8:	cb19                	beqz	a4,80005cce <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005cba:	2505                	addiw	a0,a0,1
    80005cbc:	07a1                	addi	a5,a5,8
    80005cbe:	fed51ce3          	bne	a0,a3,80005cb6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005cc2:	557d                	li	a0,-1
}
    80005cc4:	60e2                	ld	ra,24(sp)
    80005cc6:	6442                	ld	s0,16(sp)
    80005cc8:	64a2                	ld	s1,8(sp)
    80005cca:	6105                	addi	sp,sp,32
    80005ccc:	8082                	ret
      p->ofile[fd] = f;
    80005cce:	01a50793          	addi	a5,a0,26
    80005cd2:	078e                	slli	a5,a5,0x3
    80005cd4:	963e                	add	a2,a2,a5
    80005cd6:	e204                	sd	s1,0(a2)
      return fd;
    80005cd8:	b7f5                	j	80005cc4 <fdalloc+0x2c>

0000000080005cda <sys_dup>:

uint64
sys_dup(void)
{
    80005cda:	7179                	addi	sp,sp,-48
    80005cdc:	f406                	sd	ra,40(sp)
    80005cde:	f022                	sd	s0,32(sp)
    80005ce0:	ec26                	sd	s1,24(sp)
    80005ce2:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005ce4:	fd840613          	addi	a2,s0,-40
    80005ce8:	4581                	li	a1,0
    80005cea:	4501                	li	a0,0
    80005cec:	00000097          	auipc	ra,0x0
    80005cf0:	f44080e7          	jalr	-188(ra) # 80005c30 <argfd>
    return -1;
    80005cf4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005cf6:	02054363          	bltz	a0,80005d1c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005cfa:	fd843503          	ld	a0,-40(s0)
    80005cfe:	00000097          	auipc	ra,0x0
    80005d02:	f9a080e7          	jalr	-102(ra) # 80005c98 <fdalloc>
    80005d06:	84aa                	mv	s1,a0
    return -1;
    80005d08:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d0a:	00054963          	bltz	a0,80005d1c <sys_dup+0x42>
  filedup(f);
    80005d0e:	fd843503          	ld	a0,-40(s0)
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	20e080e7          	jalr	526(ra) # 80004f20 <filedup>
  return fd;
    80005d1a:	87a6                	mv	a5,s1
}
    80005d1c:	853e                	mv	a0,a5
    80005d1e:	70a2                	ld	ra,40(sp)
    80005d20:	7402                	ld	s0,32(sp)
    80005d22:	64e2                	ld	s1,24(sp)
    80005d24:	6145                	addi	sp,sp,48
    80005d26:	8082                	ret

0000000080005d28 <sys_read>:

uint64
sys_read(void)
{
    80005d28:	7179                	addi	sp,sp,-48
    80005d2a:	f406                	sd	ra,40(sp)
    80005d2c:	f022                	sd	s0,32(sp)
    80005d2e:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d30:	fe840613          	addi	a2,s0,-24
    80005d34:	4581                	li	a1,0
    80005d36:	4501                	li	a0,0
    80005d38:	00000097          	auipc	ra,0x0
    80005d3c:	ef8080e7          	jalr	-264(ra) # 80005c30 <argfd>
    return -1;
    80005d40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d42:	04054163          	bltz	a0,80005d84 <sys_read+0x5c>
    80005d46:	fe440593          	addi	a1,s0,-28
    80005d4a:	4509                	li	a0,2
    80005d4c:	ffffd097          	auipc	ra,0xffffd
    80005d50:	500080e7          	jalr	1280(ra) # 8000324c <argint>
    return -1;
    80005d54:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d56:	02054763          	bltz	a0,80005d84 <sys_read+0x5c>
    80005d5a:	fd840593          	addi	a1,s0,-40
    80005d5e:	4505                	li	a0,1
    80005d60:	ffffd097          	auipc	ra,0xffffd
    80005d64:	50e080e7          	jalr	1294(ra) # 8000326e <argaddr>
    return -1;
    80005d68:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d6a:	00054d63          	bltz	a0,80005d84 <sys_read+0x5c>
  return fileread(f, p, n);
    80005d6e:	fe442603          	lw	a2,-28(s0)
    80005d72:	fd843583          	ld	a1,-40(s0)
    80005d76:	fe843503          	ld	a0,-24(s0)
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	332080e7          	jalr	818(ra) # 800050ac <fileread>
    80005d82:	87aa                	mv	a5,a0
}
    80005d84:	853e                	mv	a0,a5
    80005d86:	70a2                	ld	ra,40(sp)
    80005d88:	7402                	ld	s0,32(sp)
    80005d8a:	6145                	addi	sp,sp,48
    80005d8c:	8082                	ret

0000000080005d8e <sys_write>:

uint64
sys_write(void)
{
    80005d8e:	7179                	addi	sp,sp,-48
    80005d90:	f406                	sd	ra,40(sp)
    80005d92:	f022                	sd	s0,32(sp)
    80005d94:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d96:	fe840613          	addi	a2,s0,-24
    80005d9a:	4581                	li	a1,0
    80005d9c:	4501                	li	a0,0
    80005d9e:	00000097          	auipc	ra,0x0
    80005da2:	e92080e7          	jalr	-366(ra) # 80005c30 <argfd>
    return -1;
    80005da6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005da8:	04054163          	bltz	a0,80005dea <sys_write+0x5c>
    80005dac:	fe440593          	addi	a1,s0,-28
    80005db0:	4509                	li	a0,2
    80005db2:	ffffd097          	auipc	ra,0xffffd
    80005db6:	49a080e7          	jalr	1178(ra) # 8000324c <argint>
    return -1;
    80005dba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dbc:	02054763          	bltz	a0,80005dea <sys_write+0x5c>
    80005dc0:	fd840593          	addi	a1,s0,-40
    80005dc4:	4505                	li	a0,1
    80005dc6:	ffffd097          	auipc	ra,0xffffd
    80005dca:	4a8080e7          	jalr	1192(ra) # 8000326e <argaddr>
    return -1;
    80005dce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dd0:	00054d63          	bltz	a0,80005dea <sys_write+0x5c>

  return filewrite(f, p, n);
    80005dd4:	fe442603          	lw	a2,-28(s0)
    80005dd8:	fd843583          	ld	a1,-40(s0)
    80005ddc:	fe843503          	ld	a0,-24(s0)
    80005de0:	fffff097          	auipc	ra,0xfffff
    80005de4:	38e080e7          	jalr	910(ra) # 8000516e <filewrite>
    80005de8:	87aa                	mv	a5,a0
}
    80005dea:	853e                	mv	a0,a5
    80005dec:	70a2                	ld	ra,40(sp)
    80005dee:	7402                	ld	s0,32(sp)
    80005df0:	6145                	addi	sp,sp,48
    80005df2:	8082                	ret

0000000080005df4 <sys_close>:

uint64
sys_close(void)
{
    80005df4:	1101                	addi	sp,sp,-32
    80005df6:	ec06                	sd	ra,24(sp)
    80005df8:	e822                	sd	s0,16(sp)
    80005dfa:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005dfc:	fe040613          	addi	a2,s0,-32
    80005e00:	fec40593          	addi	a1,s0,-20
    80005e04:	4501                	li	a0,0
    80005e06:	00000097          	auipc	ra,0x0
    80005e0a:	e2a080e7          	jalr	-470(ra) # 80005c30 <argfd>
    return -1;
    80005e0e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e10:	02054463          	bltz	a0,80005e38 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e14:	ffffc097          	auipc	ra,0xffffc
    80005e18:	bc0080e7          	jalr	-1088(ra) # 800019d4 <myproc>
    80005e1c:	fec42783          	lw	a5,-20(s0)
    80005e20:	07e9                	addi	a5,a5,26
    80005e22:	078e                	slli	a5,a5,0x3
    80005e24:	97aa                	add	a5,a5,a0
    80005e26:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005e2a:	fe043503          	ld	a0,-32(s0)
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	144080e7          	jalr	324(ra) # 80004f72 <fileclose>
  return 0;
    80005e36:	4781                	li	a5,0
}
    80005e38:	853e                	mv	a0,a5
    80005e3a:	60e2                	ld	ra,24(sp)
    80005e3c:	6442                	ld	s0,16(sp)
    80005e3e:	6105                	addi	sp,sp,32
    80005e40:	8082                	ret

0000000080005e42 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005e42:	1101                	addi	sp,sp,-32
    80005e44:	ec06                	sd	ra,24(sp)
    80005e46:	e822                	sd	s0,16(sp)
    80005e48:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005e4a:	fe840613          	addi	a2,s0,-24
    80005e4e:	4581                	li	a1,0
    80005e50:	4501                	li	a0,0
    80005e52:	00000097          	auipc	ra,0x0
    80005e56:	dde080e7          	jalr	-546(ra) # 80005c30 <argfd>
    return -1;
    80005e5a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005e5c:	02054563          	bltz	a0,80005e86 <sys_fstat+0x44>
    80005e60:	fe040593          	addi	a1,s0,-32
    80005e64:	4505                	li	a0,1
    80005e66:	ffffd097          	auipc	ra,0xffffd
    80005e6a:	408080e7          	jalr	1032(ra) # 8000326e <argaddr>
    return -1;
    80005e6e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005e70:	00054b63          	bltz	a0,80005e86 <sys_fstat+0x44>
  return filestat(f, st);
    80005e74:	fe043583          	ld	a1,-32(s0)
    80005e78:	fe843503          	ld	a0,-24(s0)
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	1be080e7          	jalr	446(ra) # 8000503a <filestat>
    80005e84:	87aa                	mv	a5,a0
}
    80005e86:	853e                	mv	a0,a5
    80005e88:	60e2                	ld	ra,24(sp)
    80005e8a:	6442                	ld	s0,16(sp)
    80005e8c:	6105                	addi	sp,sp,32
    80005e8e:	8082                	ret

0000000080005e90 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005e90:	7169                	addi	sp,sp,-304
    80005e92:	f606                	sd	ra,296(sp)
    80005e94:	f222                	sd	s0,288(sp)
    80005e96:	ee26                	sd	s1,280(sp)
    80005e98:	ea4a                	sd	s2,272(sp)
    80005e9a:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e9c:	08000613          	li	a2,128
    80005ea0:	ed040593          	addi	a1,s0,-304
    80005ea4:	4501                	li	a0,0
    80005ea6:	ffffd097          	auipc	ra,0xffffd
    80005eaa:	3ea080e7          	jalr	1002(ra) # 80003290 <argstr>
    return -1;
    80005eae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005eb0:	10054e63          	bltz	a0,80005fcc <sys_link+0x13c>
    80005eb4:	08000613          	li	a2,128
    80005eb8:	f5040593          	addi	a1,s0,-176
    80005ebc:	4505                	li	a0,1
    80005ebe:	ffffd097          	auipc	ra,0xffffd
    80005ec2:	3d2080e7          	jalr	978(ra) # 80003290 <argstr>
    return -1;
    80005ec6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ec8:	10054263          	bltz	a0,80005fcc <sys_link+0x13c>

  begin_op();
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	bda080e7          	jalr	-1062(ra) # 80004aa6 <begin_op>
  if((ip = namei(old)) == 0){
    80005ed4:	ed040513          	addi	a0,s0,-304
    80005ed8:	ffffe097          	auipc	ra,0xffffe
    80005edc:	69c080e7          	jalr	1692(ra) # 80004574 <namei>
    80005ee0:	84aa                	mv	s1,a0
    80005ee2:	c551                	beqz	a0,80005f6e <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005ee4:	ffffe097          	auipc	ra,0xffffe
    80005ee8:	eda080e7          	jalr	-294(ra) # 80003dbe <ilock>
  if(ip->type == T_DIR){
    80005eec:	04449703          	lh	a4,68(s1)
    80005ef0:	4785                	li	a5,1
    80005ef2:	08f70463          	beq	a4,a5,80005f7a <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005ef6:	04a4d783          	lhu	a5,74(s1)
    80005efa:	2785                	addiw	a5,a5,1
    80005efc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f00:	8526                	mv	a0,s1
    80005f02:	ffffe097          	auipc	ra,0xffffe
    80005f06:	df2080e7          	jalr	-526(ra) # 80003cf4 <iupdate>
  iunlock(ip);
    80005f0a:	8526                	mv	a0,s1
    80005f0c:	ffffe097          	auipc	ra,0xffffe
    80005f10:	f74080e7          	jalr	-140(ra) # 80003e80 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005f14:	fd040593          	addi	a1,s0,-48
    80005f18:	f5040513          	addi	a0,s0,-176
    80005f1c:	ffffe097          	auipc	ra,0xffffe
    80005f20:	676080e7          	jalr	1654(ra) # 80004592 <nameiparent>
    80005f24:	892a                	mv	s2,a0
    80005f26:	c935                	beqz	a0,80005f9a <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	e96080e7          	jalr	-362(ra) # 80003dbe <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005f30:	00092703          	lw	a4,0(s2)
    80005f34:	409c                	lw	a5,0(s1)
    80005f36:	04f71d63          	bne	a4,a5,80005f90 <sys_link+0x100>
    80005f3a:	40d0                	lw	a2,4(s1)
    80005f3c:	fd040593          	addi	a1,s0,-48
    80005f40:	854a                	mv	a0,s2
    80005f42:	ffffe097          	auipc	ra,0xffffe
    80005f46:	570080e7          	jalr	1392(ra) # 800044b2 <dirlink>
    80005f4a:	04054363          	bltz	a0,80005f90 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005f4e:	854a                	mv	a0,s2
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	0d0080e7          	jalr	208(ra) # 80004020 <iunlockput>
  iput(ip);
    80005f58:	8526                	mv	a0,s1
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	01e080e7          	jalr	30(ra) # 80003f78 <iput>

  end_op();
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	bc4080e7          	jalr	-1084(ra) # 80004b26 <end_op>

  return 0;
    80005f6a:	4781                	li	a5,0
    80005f6c:	a085                	j	80005fcc <sys_link+0x13c>
    end_op();
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	bb8080e7          	jalr	-1096(ra) # 80004b26 <end_op>
    return -1;
    80005f76:	57fd                	li	a5,-1
    80005f78:	a891                	j	80005fcc <sys_link+0x13c>
    iunlockput(ip);
    80005f7a:	8526                	mv	a0,s1
    80005f7c:	ffffe097          	auipc	ra,0xffffe
    80005f80:	0a4080e7          	jalr	164(ra) # 80004020 <iunlockput>
    end_op();
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	ba2080e7          	jalr	-1118(ra) # 80004b26 <end_op>
    return -1;
    80005f8c:	57fd                	li	a5,-1
    80005f8e:	a83d                	j	80005fcc <sys_link+0x13c>
    iunlockput(dp);
    80005f90:	854a                	mv	a0,s2
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	08e080e7          	jalr	142(ra) # 80004020 <iunlockput>

bad:
  ilock(ip);
    80005f9a:	8526                	mv	a0,s1
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	e22080e7          	jalr	-478(ra) # 80003dbe <ilock>
  ip->nlink--;
    80005fa4:	04a4d783          	lhu	a5,74(s1)
    80005fa8:	37fd                	addiw	a5,a5,-1
    80005faa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005fae:	8526                	mv	a0,s1
    80005fb0:	ffffe097          	auipc	ra,0xffffe
    80005fb4:	d44080e7          	jalr	-700(ra) # 80003cf4 <iupdate>
  iunlockput(ip);
    80005fb8:	8526                	mv	a0,s1
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	066080e7          	jalr	102(ra) # 80004020 <iunlockput>
  end_op();
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	b64080e7          	jalr	-1180(ra) # 80004b26 <end_op>
  return -1;
    80005fca:	57fd                	li	a5,-1
}
    80005fcc:	853e                	mv	a0,a5
    80005fce:	70b2                	ld	ra,296(sp)
    80005fd0:	7412                	ld	s0,288(sp)
    80005fd2:	64f2                	ld	s1,280(sp)
    80005fd4:	6952                	ld	s2,272(sp)
    80005fd6:	6155                	addi	sp,sp,304
    80005fd8:	8082                	ret

0000000080005fda <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005fda:	4578                	lw	a4,76(a0)
    80005fdc:	02000793          	li	a5,32
    80005fe0:	04e7fa63          	bgeu	a5,a4,80006034 <isdirempty+0x5a>
{
    80005fe4:	7179                	addi	sp,sp,-48
    80005fe6:	f406                	sd	ra,40(sp)
    80005fe8:	f022                	sd	s0,32(sp)
    80005fea:	ec26                	sd	s1,24(sp)
    80005fec:	e84a                	sd	s2,16(sp)
    80005fee:	1800                	addi	s0,sp,48
    80005ff0:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ff2:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ff6:	4741                	li	a4,16
    80005ff8:	86a6                	mv	a3,s1
    80005ffa:	fd040613          	addi	a2,s0,-48
    80005ffe:	4581                	li	a1,0
    80006000:	854a                	mv	a0,s2
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	070080e7          	jalr	112(ra) # 80004072 <readi>
    8000600a:	47c1                	li	a5,16
    8000600c:	00f51c63          	bne	a0,a5,80006024 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80006010:	fd045783          	lhu	a5,-48(s0)
    80006014:	e395                	bnez	a5,80006038 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006016:	24c1                	addiw	s1,s1,16
    80006018:	04c92783          	lw	a5,76(s2)
    8000601c:	fcf4ede3          	bltu	s1,a5,80005ff6 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80006020:	4505                	li	a0,1
    80006022:	a821                	j	8000603a <isdirempty+0x60>
      panic("isdirempty: readi");
    80006024:	00003517          	auipc	a0,0x3
    80006028:	9e450513          	addi	a0,a0,-1564 # 80008a08 <syscalls+0x310>
    8000602c:	ffffa097          	auipc	ra,0xffffa
    80006030:	4fe080e7          	jalr	1278(ra) # 8000052a <panic>
  return 1;
    80006034:	4505                	li	a0,1
}
    80006036:	8082                	ret
      return 0;
    80006038:	4501                	li	a0,0
}
    8000603a:	70a2                	ld	ra,40(sp)
    8000603c:	7402                	ld	s0,32(sp)
    8000603e:	64e2                	ld	s1,24(sp)
    80006040:	6942                	ld	s2,16(sp)
    80006042:	6145                	addi	sp,sp,48
    80006044:	8082                	ret

0000000080006046 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006046:	7155                	addi	sp,sp,-208
    80006048:	e586                	sd	ra,200(sp)
    8000604a:	e1a2                	sd	s0,192(sp)
    8000604c:	fd26                	sd	s1,184(sp)
    8000604e:	f94a                	sd	s2,176(sp)
    80006050:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006052:	08000613          	li	a2,128
    80006056:	f4040593          	addi	a1,s0,-192
    8000605a:	4501                	li	a0,0
    8000605c:	ffffd097          	auipc	ra,0xffffd
    80006060:	234080e7          	jalr	564(ra) # 80003290 <argstr>
    80006064:	16054363          	bltz	a0,800061ca <sys_unlink+0x184>
    return -1;

  begin_op();
    80006068:	fffff097          	auipc	ra,0xfffff
    8000606c:	a3e080e7          	jalr	-1474(ra) # 80004aa6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006070:	fc040593          	addi	a1,s0,-64
    80006074:	f4040513          	addi	a0,s0,-192
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	51a080e7          	jalr	1306(ra) # 80004592 <nameiparent>
    80006080:	84aa                	mv	s1,a0
    80006082:	c961                	beqz	a0,80006152 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	d3a080e7          	jalr	-710(ra) # 80003dbe <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000608c:	00003597          	auipc	a1,0x3
    80006090:	85c58593          	addi	a1,a1,-1956 # 800088e8 <syscalls+0x1f0>
    80006094:	fc040513          	addi	a0,s0,-64
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	1f0080e7          	jalr	496(ra) # 80004288 <namecmp>
    800060a0:	c175                	beqz	a0,80006184 <sys_unlink+0x13e>
    800060a2:	00003597          	auipc	a1,0x3
    800060a6:	84e58593          	addi	a1,a1,-1970 # 800088f0 <syscalls+0x1f8>
    800060aa:	fc040513          	addi	a0,s0,-64
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	1da080e7          	jalr	474(ra) # 80004288 <namecmp>
    800060b6:	c579                	beqz	a0,80006184 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800060b8:	f3c40613          	addi	a2,s0,-196
    800060bc:	fc040593          	addi	a1,s0,-64
    800060c0:	8526                	mv	a0,s1
    800060c2:	ffffe097          	auipc	ra,0xffffe
    800060c6:	1e0080e7          	jalr	480(ra) # 800042a2 <dirlookup>
    800060ca:	892a                	mv	s2,a0
    800060cc:	cd45                	beqz	a0,80006184 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    800060ce:	ffffe097          	auipc	ra,0xffffe
    800060d2:	cf0080e7          	jalr	-784(ra) # 80003dbe <ilock>

  if(ip->nlink < 1)
    800060d6:	04a91783          	lh	a5,74(s2)
    800060da:	08f05263          	blez	a5,8000615e <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800060de:	04491703          	lh	a4,68(s2)
    800060e2:	4785                	li	a5,1
    800060e4:	08f70563          	beq	a4,a5,8000616e <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800060e8:	4641                	li	a2,16
    800060ea:	4581                	li	a1,0
    800060ec:	fd040513          	addi	a0,s0,-48
    800060f0:	ffffb097          	auipc	ra,0xffffb
    800060f4:	bce080e7          	jalr	-1074(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060f8:	4741                	li	a4,16
    800060fa:	f3c42683          	lw	a3,-196(s0)
    800060fe:	fd040613          	addi	a2,s0,-48
    80006102:	4581                	li	a1,0
    80006104:	8526                	mv	a0,s1
    80006106:	ffffe097          	auipc	ra,0xffffe
    8000610a:	064080e7          	jalr	100(ra) # 8000416a <writei>
    8000610e:	47c1                	li	a5,16
    80006110:	08f51a63          	bne	a0,a5,800061a4 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80006114:	04491703          	lh	a4,68(s2)
    80006118:	4785                	li	a5,1
    8000611a:	08f70d63          	beq	a4,a5,800061b4 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000611e:	8526                	mv	a0,s1
    80006120:	ffffe097          	auipc	ra,0xffffe
    80006124:	f00080e7          	jalr	-256(ra) # 80004020 <iunlockput>

  ip->nlink--;
    80006128:	04a95783          	lhu	a5,74(s2)
    8000612c:	37fd                	addiw	a5,a5,-1
    8000612e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006132:	854a                	mv	a0,s2
    80006134:	ffffe097          	auipc	ra,0xffffe
    80006138:	bc0080e7          	jalr	-1088(ra) # 80003cf4 <iupdate>
  iunlockput(ip);
    8000613c:	854a                	mv	a0,s2
    8000613e:	ffffe097          	auipc	ra,0xffffe
    80006142:	ee2080e7          	jalr	-286(ra) # 80004020 <iunlockput>

  end_op();
    80006146:	fffff097          	auipc	ra,0xfffff
    8000614a:	9e0080e7          	jalr	-1568(ra) # 80004b26 <end_op>

  return 0;
    8000614e:	4501                	li	a0,0
    80006150:	a0a1                	j	80006198 <sys_unlink+0x152>
    end_op();
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	9d4080e7          	jalr	-1580(ra) # 80004b26 <end_op>
    return -1;
    8000615a:	557d                	li	a0,-1
    8000615c:	a835                	j	80006198 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    8000615e:	00002517          	auipc	a0,0x2
    80006162:	79a50513          	addi	a0,a0,1946 # 800088f8 <syscalls+0x200>
    80006166:	ffffa097          	auipc	ra,0xffffa
    8000616a:	3c4080e7          	jalr	964(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000616e:	854a                	mv	a0,s2
    80006170:	00000097          	auipc	ra,0x0
    80006174:	e6a080e7          	jalr	-406(ra) # 80005fda <isdirempty>
    80006178:	f925                	bnez	a0,800060e8 <sys_unlink+0xa2>
    iunlockput(ip);
    8000617a:	854a                	mv	a0,s2
    8000617c:	ffffe097          	auipc	ra,0xffffe
    80006180:	ea4080e7          	jalr	-348(ra) # 80004020 <iunlockput>

bad:
  iunlockput(dp);
    80006184:	8526                	mv	a0,s1
    80006186:	ffffe097          	auipc	ra,0xffffe
    8000618a:	e9a080e7          	jalr	-358(ra) # 80004020 <iunlockput>
  end_op();
    8000618e:	fffff097          	auipc	ra,0xfffff
    80006192:	998080e7          	jalr	-1640(ra) # 80004b26 <end_op>
  return -1;
    80006196:	557d                	li	a0,-1
}
    80006198:	60ae                	ld	ra,200(sp)
    8000619a:	640e                	ld	s0,192(sp)
    8000619c:	74ea                	ld	s1,184(sp)
    8000619e:	794a                	ld	s2,176(sp)
    800061a0:	6169                	addi	sp,sp,208
    800061a2:	8082                	ret
    panic("unlink: writei");
    800061a4:	00002517          	auipc	a0,0x2
    800061a8:	76c50513          	addi	a0,a0,1900 # 80008910 <syscalls+0x218>
    800061ac:	ffffa097          	auipc	ra,0xffffa
    800061b0:	37e080e7          	jalr	894(ra) # 8000052a <panic>
    dp->nlink--;
    800061b4:	04a4d783          	lhu	a5,74(s1)
    800061b8:	37fd                	addiw	a5,a5,-1
    800061ba:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800061be:	8526                	mv	a0,s1
    800061c0:	ffffe097          	auipc	ra,0xffffe
    800061c4:	b34080e7          	jalr	-1228(ra) # 80003cf4 <iupdate>
    800061c8:	bf99                	j	8000611e <sys_unlink+0xd8>
    return -1;
    800061ca:	557d                	li	a0,-1
    800061cc:	b7f1                	j	80006198 <sys_unlink+0x152>

00000000800061ce <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    800061ce:	715d                	addi	sp,sp,-80
    800061d0:	e486                	sd	ra,72(sp)
    800061d2:	e0a2                	sd	s0,64(sp)
    800061d4:	fc26                	sd	s1,56(sp)
    800061d6:	f84a                	sd	s2,48(sp)
    800061d8:	f44e                	sd	s3,40(sp)
    800061da:	f052                	sd	s4,32(sp)
    800061dc:	ec56                	sd	s5,24(sp)
    800061de:	0880                	addi	s0,sp,80
    800061e0:	89ae                	mv	s3,a1
    800061e2:	8ab2                	mv	s5,a2
    800061e4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800061e6:	fb040593          	addi	a1,s0,-80
    800061ea:	ffffe097          	auipc	ra,0xffffe
    800061ee:	3a8080e7          	jalr	936(ra) # 80004592 <nameiparent>
    800061f2:	892a                	mv	s2,a0
    800061f4:	12050e63          	beqz	a0,80006330 <create+0x162>
    return 0;

  ilock(dp);
    800061f8:	ffffe097          	auipc	ra,0xffffe
    800061fc:	bc6080e7          	jalr	-1082(ra) # 80003dbe <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80006200:	4601                	li	a2,0
    80006202:	fb040593          	addi	a1,s0,-80
    80006206:	854a                	mv	a0,s2
    80006208:	ffffe097          	auipc	ra,0xffffe
    8000620c:	09a080e7          	jalr	154(ra) # 800042a2 <dirlookup>
    80006210:	84aa                	mv	s1,a0
    80006212:	c921                	beqz	a0,80006262 <create+0x94>
    iunlockput(dp);
    80006214:	854a                	mv	a0,s2
    80006216:	ffffe097          	auipc	ra,0xffffe
    8000621a:	e0a080e7          	jalr	-502(ra) # 80004020 <iunlockput>
    ilock(ip);
    8000621e:	8526                	mv	a0,s1
    80006220:	ffffe097          	auipc	ra,0xffffe
    80006224:	b9e080e7          	jalr	-1122(ra) # 80003dbe <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006228:	2981                	sext.w	s3,s3
    8000622a:	4789                	li	a5,2
    8000622c:	02f99463          	bne	s3,a5,80006254 <create+0x86>
    80006230:	0444d783          	lhu	a5,68(s1)
    80006234:	37f9                	addiw	a5,a5,-2
    80006236:	17c2                	slli	a5,a5,0x30
    80006238:	93c1                	srli	a5,a5,0x30
    8000623a:	4705                	li	a4,1
    8000623c:	00f76c63          	bltu	a4,a5,80006254 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006240:	8526                	mv	a0,s1
    80006242:	60a6                	ld	ra,72(sp)
    80006244:	6406                	ld	s0,64(sp)
    80006246:	74e2                	ld	s1,56(sp)
    80006248:	7942                	ld	s2,48(sp)
    8000624a:	79a2                	ld	s3,40(sp)
    8000624c:	7a02                	ld	s4,32(sp)
    8000624e:	6ae2                	ld	s5,24(sp)
    80006250:	6161                	addi	sp,sp,80
    80006252:	8082                	ret
    iunlockput(ip);
    80006254:	8526                	mv	a0,s1
    80006256:	ffffe097          	auipc	ra,0xffffe
    8000625a:	dca080e7          	jalr	-566(ra) # 80004020 <iunlockput>
    return 0;
    8000625e:	4481                	li	s1,0
    80006260:	b7c5                	j	80006240 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80006262:	85ce                	mv	a1,s3
    80006264:	00092503          	lw	a0,0(s2)
    80006268:	ffffe097          	auipc	ra,0xffffe
    8000626c:	9be080e7          	jalr	-1602(ra) # 80003c26 <ialloc>
    80006270:	84aa                	mv	s1,a0
    80006272:	c521                	beqz	a0,800062ba <create+0xec>
  ilock(ip);
    80006274:	ffffe097          	auipc	ra,0xffffe
    80006278:	b4a080e7          	jalr	-1206(ra) # 80003dbe <ilock>
  ip->major = major;
    8000627c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006280:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006284:	4a05                	li	s4,1
    80006286:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000628a:	8526                	mv	a0,s1
    8000628c:	ffffe097          	auipc	ra,0xffffe
    80006290:	a68080e7          	jalr	-1432(ra) # 80003cf4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006294:	2981                	sext.w	s3,s3
    80006296:	03498a63          	beq	s3,s4,800062ca <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000629a:	40d0                	lw	a2,4(s1)
    8000629c:	fb040593          	addi	a1,s0,-80
    800062a0:	854a                	mv	a0,s2
    800062a2:	ffffe097          	auipc	ra,0xffffe
    800062a6:	210080e7          	jalr	528(ra) # 800044b2 <dirlink>
    800062aa:	06054b63          	bltz	a0,80006320 <create+0x152>
  iunlockput(dp);
    800062ae:	854a                	mv	a0,s2
    800062b0:	ffffe097          	auipc	ra,0xffffe
    800062b4:	d70080e7          	jalr	-656(ra) # 80004020 <iunlockput>
  return ip;
    800062b8:	b761                	j	80006240 <create+0x72>
    panic("create: ialloc");
    800062ba:	00002517          	auipc	a0,0x2
    800062be:	76650513          	addi	a0,a0,1894 # 80008a20 <syscalls+0x328>
    800062c2:	ffffa097          	auipc	ra,0xffffa
    800062c6:	268080e7          	jalr	616(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800062ca:	04a95783          	lhu	a5,74(s2)
    800062ce:	2785                	addiw	a5,a5,1
    800062d0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800062d4:	854a                	mv	a0,s2
    800062d6:	ffffe097          	auipc	ra,0xffffe
    800062da:	a1e080e7          	jalr	-1506(ra) # 80003cf4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800062de:	40d0                	lw	a2,4(s1)
    800062e0:	00002597          	auipc	a1,0x2
    800062e4:	60858593          	addi	a1,a1,1544 # 800088e8 <syscalls+0x1f0>
    800062e8:	8526                	mv	a0,s1
    800062ea:	ffffe097          	auipc	ra,0xffffe
    800062ee:	1c8080e7          	jalr	456(ra) # 800044b2 <dirlink>
    800062f2:	00054f63          	bltz	a0,80006310 <create+0x142>
    800062f6:	00492603          	lw	a2,4(s2)
    800062fa:	00002597          	auipc	a1,0x2
    800062fe:	5f658593          	addi	a1,a1,1526 # 800088f0 <syscalls+0x1f8>
    80006302:	8526                	mv	a0,s1
    80006304:	ffffe097          	auipc	ra,0xffffe
    80006308:	1ae080e7          	jalr	430(ra) # 800044b2 <dirlink>
    8000630c:	f80557e3          	bgez	a0,8000629a <create+0xcc>
      panic("create dots");
    80006310:	00002517          	auipc	a0,0x2
    80006314:	72050513          	addi	a0,a0,1824 # 80008a30 <syscalls+0x338>
    80006318:	ffffa097          	auipc	ra,0xffffa
    8000631c:	212080e7          	jalr	530(ra) # 8000052a <panic>
    panic("create: dirlink");
    80006320:	00002517          	auipc	a0,0x2
    80006324:	72050513          	addi	a0,a0,1824 # 80008a40 <syscalls+0x348>
    80006328:	ffffa097          	auipc	ra,0xffffa
    8000632c:	202080e7          	jalr	514(ra) # 8000052a <panic>
    return 0;
    80006330:	84aa                	mv	s1,a0
    80006332:	b739                	j	80006240 <create+0x72>

0000000080006334 <sys_open>:

uint64
sys_open(void)
{
    80006334:	7131                	addi	sp,sp,-192
    80006336:	fd06                	sd	ra,184(sp)
    80006338:	f922                	sd	s0,176(sp)
    8000633a:	f526                	sd	s1,168(sp)
    8000633c:	f14a                	sd	s2,160(sp)
    8000633e:	ed4e                	sd	s3,152(sp)
    80006340:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006342:	08000613          	li	a2,128
    80006346:	f5040593          	addi	a1,s0,-176
    8000634a:	4501                	li	a0,0
    8000634c:	ffffd097          	auipc	ra,0xffffd
    80006350:	f44080e7          	jalr	-188(ra) # 80003290 <argstr>
    return -1;
    80006354:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006356:	0c054163          	bltz	a0,80006418 <sys_open+0xe4>
    8000635a:	f4c40593          	addi	a1,s0,-180
    8000635e:	4505                	li	a0,1
    80006360:	ffffd097          	auipc	ra,0xffffd
    80006364:	eec080e7          	jalr	-276(ra) # 8000324c <argint>
    80006368:	0a054863          	bltz	a0,80006418 <sys_open+0xe4>

  begin_op();
    8000636c:	ffffe097          	auipc	ra,0xffffe
    80006370:	73a080e7          	jalr	1850(ra) # 80004aa6 <begin_op>

  if(omode & O_CREATE){
    80006374:	f4c42783          	lw	a5,-180(s0)
    80006378:	2007f793          	andi	a5,a5,512
    8000637c:	cbdd                	beqz	a5,80006432 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000637e:	4681                	li	a3,0
    80006380:	4601                	li	a2,0
    80006382:	4589                	li	a1,2
    80006384:	f5040513          	addi	a0,s0,-176
    80006388:	00000097          	auipc	ra,0x0
    8000638c:	e46080e7          	jalr	-442(ra) # 800061ce <create>
    80006390:	892a                	mv	s2,a0
    if(ip == 0){
    80006392:	c959                	beqz	a0,80006428 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006394:	04491703          	lh	a4,68(s2)
    80006398:	478d                	li	a5,3
    8000639a:	00f71763          	bne	a4,a5,800063a8 <sys_open+0x74>
    8000639e:	04695703          	lhu	a4,70(s2)
    800063a2:	47a5                	li	a5,9
    800063a4:	0ce7ec63          	bltu	a5,a4,8000647c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800063a8:	fffff097          	auipc	ra,0xfffff
    800063ac:	b0e080e7          	jalr	-1266(ra) # 80004eb6 <filealloc>
    800063b0:	89aa                	mv	s3,a0
    800063b2:	10050263          	beqz	a0,800064b6 <sys_open+0x182>
    800063b6:	00000097          	auipc	ra,0x0
    800063ba:	8e2080e7          	jalr	-1822(ra) # 80005c98 <fdalloc>
    800063be:	84aa                	mv	s1,a0
    800063c0:	0e054663          	bltz	a0,800064ac <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800063c4:	04491703          	lh	a4,68(s2)
    800063c8:	478d                	li	a5,3
    800063ca:	0cf70463          	beq	a4,a5,80006492 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800063ce:	4789                	li	a5,2
    800063d0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800063d4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800063d8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800063dc:	f4c42783          	lw	a5,-180(s0)
    800063e0:	0017c713          	xori	a4,a5,1
    800063e4:	8b05                	andi	a4,a4,1
    800063e6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800063ea:	0037f713          	andi	a4,a5,3
    800063ee:	00e03733          	snez	a4,a4
    800063f2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800063f6:	4007f793          	andi	a5,a5,1024
    800063fa:	c791                	beqz	a5,80006406 <sys_open+0xd2>
    800063fc:	04491703          	lh	a4,68(s2)
    80006400:	4789                	li	a5,2
    80006402:	08f70f63          	beq	a4,a5,800064a0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006406:	854a                	mv	a0,s2
    80006408:	ffffe097          	auipc	ra,0xffffe
    8000640c:	a78080e7          	jalr	-1416(ra) # 80003e80 <iunlock>
  end_op();
    80006410:	ffffe097          	auipc	ra,0xffffe
    80006414:	716080e7          	jalr	1814(ra) # 80004b26 <end_op>

  return fd;
}
    80006418:	8526                	mv	a0,s1
    8000641a:	70ea                	ld	ra,184(sp)
    8000641c:	744a                	ld	s0,176(sp)
    8000641e:	74aa                	ld	s1,168(sp)
    80006420:	790a                	ld	s2,160(sp)
    80006422:	69ea                	ld	s3,152(sp)
    80006424:	6129                	addi	sp,sp,192
    80006426:	8082                	ret
      end_op();
    80006428:	ffffe097          	auipc	ra,0xffffe
    8000642c:	6fe080e7          	jalr	1790(ra) # 80004b26 <end_op>
      return -1;
    80006430:	b7e5                	j	80006418 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006432:	f5040513          	addi	a0,s0,-176
    80006436:	ffffe097          	auipc	ra,0xffffe
    8000643a:	13e080e7          	jalr	318(ra) # 80004574 <namei>
    8000643e:	892a                	mv	s2,a0
    80006440:	c905                	beqz	a0,80006470 <sys_open+0x13c>
    ilock(ip);
    80006442:	ffffe097          	auipc	ra,0xffffe
    80006446:	97c080e7          	jalr	-1668(ra) # 80003dbe <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000644a:	04491703          	lh	a4,68(s2)
    8000644e:	4785                	li	a5,1
    80006450:	f4f712e3          	bne	a4,a5,80006394 <sys_open+0x60>
    80006454:	f4c42783          	lw	a5,-180(s0)
    80006458:	dba1                	beqz	a5,800063a8 <sys_open+0x74>
      iunlockput(ip);
    8000645a:	854a                	mv	a0,s2
    8000645c:	ffffe097          	auipc	ra,0xffffe
    80006460:	bc4080e7          	jalr	-1084(ra) # 80004020 <iunlockput>
      end_op();
    80006464:	ffffe097          	auipc	ra,0xffffe
    80006468:	6c2080e7          	jalr	1730(ra) # 80004b26 <end_op>
      return -1;
    8000646c:	54fd                	li	s1,-1
    8000646e:	b76d                	j	80006418 <sys_open+0xe4>
      end_op();
    80006470:	ffffe097          	auipc	ra,0xffffe
    80006474:	6b6080e7          	jalr	1718(ra) # 80004b26 <end_op>
      return -1;
    80006478:	54fd                	li	s1,-1
    8000647a:	bf79                	j	80006418 <sys_open+0xe4>
    iunlockput(ip);
    8000647c:	854a                	mv	a0,s2
    8000647e:	ffffe097          	auipc	ra,0xffffe
    80006482:	ba2080e7          	jalr	-1118(ra) # 80004020 <iunlockput>
    end_op();
    80006486:	ffffe097          	auipc	ra,0xffffe
    8000648a:	6a0080e7          	jalr	1696(ra) # 80004b26 <end_op>
    return -1;
    8000648e:	54fd                	li	s1,-1
    80006490:	b761                	j	80006418 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006492:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006496:	04691783          	lh	a5,70(s2)
    8000649a:	02f99223          	sh	a5,36(s3)
    8000649e:	bf2d                	j	800063d8 <sys_open+0xa4>
    itrunc(ip);
    800064a0:	854a                	mv	a0,s2
    800064a2:	ffffe097          	auipc	ra,0xffffe
    800064a6:	a2a080e7          	jalr	-1494(ra) # 80003ecc <itrunc>
    800064aa:	bfb1                	j	80006406 <sys_open+0xd2>
      fileclose(f);
    800064ac:	854e                	mv	a0,s3
    800064ae:	fffff097          	auipc	ra,0xfffff
    800064b2:	ac4080e7          	jalr	-1340(ra) # 80004f72 <fileclose>
    iunlockput(ip);
    800064b6:	854a                	mv	a0,s2
    800064b8:	ffffe097          	auipc	ra,0xffffe
    800064bc:	b68080e7          	jalr	-1176(ra) # 80004020 <iunlockput>
    end_op();
    800064c0:	ffffe097          	auipc	ra,0xffffe
    800064c4:	666080e7          	jalr	1638(ra) # 80004b26 <end_op>
    return -1;
    800064c8:	54fd                	li	s1,-1
    800064ca:	b7b9                	j	80006418 <sys_open+0xe4>

00000000800064cc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800064cc:	7175                	addi	sp,sp,-144
    800064ce:	e506                	sd	ra,136(sp)
    800064d0:	e122                	sd	s0,128(sp)
    800064d2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800064d4:	ffffe097          	auipc	ra,0xffffe
    800064d8:	5d2080e7          	jalr	1490(ra) # 80004aa6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800064dc:	08000613          	li	a2,128
    800064e0:	f7040593          	addi	a1,s0,-144
    800064e4:	4501                	li	a0,0
    800064e6:	ffffd097          	auipc	ra,0xffffd
    800064ea:	daa080e7          	jalr	-598(ra) # 80003290 <argstr>
    800064ee:	02054963          	bltz	a0,80006520 <sys_mkdir+0x54>
    800064f2:	4681                	li	a3,0
    800064f4:	4601                	li	a2,0
    800064f6:	4585                	li	a1,1
    800064f8:	f7040513          	addi	a0,s0,-144
    800064fc:	00000097          	auipc	ra,0x0
    80006500:	cd2080e7          	jalr	-814(ra) # 800061ce <create>
    80006504:	cd11                	beqz	a0,80006520 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006506:	ffffe097          	auipc	ra,0xffffe
    8000650a:	b1a080e7          	jalr	-1254(ra) # 80004020 <iunlockput>
  end_op();
    8000650e:	ffffe097          	auipc	ra,0xffffe
    80006512:	618080e7          	jalr	1560(ra) # 80004b26 <end_op>
  return 0;
    80006516:	4501                	li	a0,0
}
    80006518:	60aa                	ld	ra,136(sp)
    8000651a:	640a                	ld	s0,128(sp)
    8000651c:	6149                	addi	sp,sp,144
    8000651e:	8082                	ret
    end_op();
    80006520:	ffffe097          	auipc	ra,0xffffe
    80006524:	606080e7          	jalr	1542(ra) # 80004b26 <end_op>
    return -1;
    80006528:	557d                	li	a0,-1
    8000652a:	b7fd                	j	80006518 <sys_mkdir+0x4c>

000000008000652c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000652c:	7135                	addi	sp,sp,-160
    8000652e:	ed06                	sd	ra,152(sp)
    80006530:	e922                	sd	s0,144(sp)
    80006532:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006534:	ffffe097          	auipc	ra,0xffffe
    80006538:	572080e7          	jalr	1394(ra) # 80004aa6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000653c:	08000613          	li	a2,128
    80006540:	f7040593          	addi	a1,s0,-144
    80006544:	4501                	li	a0,0
    80006546:	ffffd097          	auipc	ra,0xffffd
    8000654a:	d4a080e7          	jalr	-694(ra) # 80003290 <argstr>
    8000654e:	04054a63          	bltz	a0,800065a2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006552:	f6c40593          	addi	a1,s0,-148
    80006556:	4505                	li	a0,1
    80006558:	ffffd097          	auipc	ra,0xffffd
    8000655c:	cf4080e7          	jalr	-780(ra) # 8000324c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006560:	04054163          	bltz	a0,800065a2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006564:	f6840593          	addi	a1,s0,-152
    80006568:	4509                	li	a0,2
    8000656a:	ffffd097          	auipc	ra,0xffffd
    8000656e:	ce2080e7          	jalr	-798(ra) # 8000324c <argint>
     argint(1, &major) < 0 ||
    80006572:	02054863          	bltz	a0,800065a2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006576:	f6841683          	lh	a3,-152(s0)
    8000657a:	f6c41603          	lh	a2,-148(s0)
    8000657e:	458d                	li	a1,3
    80006580:	f7040513          	addi	a0,s0,-144
    80006584:	00000097          	auipc	ra,0x0
    80006588:	c4a080e7          	jalr	-950(ra) # 800061ce <create>
     argint(2, &minor) < 0 ||
    8000658c:	c919                	beqz	a0,800065a2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000658e:	ffffe097          	auipc	ra,0xffffe
    80006592:	a92080e7          	jalr	-1390(ra) # 80004020 <iunlockput>
  end_op();
    80006596:	ffffe097          	auipc	ra,0xffffe
    8000659a:	590080e7          	jalr	1424(ra) # 80004b26 <end_op>
  return 0;
    8000659e:	4501                	li	a0,0
    800065a0:	a031                	j	800065ac <sys_mknod+0x80>
    end_op();
    800065a2:	ffffe097          	auipc	ra,0xffffe
    800065a6:	584080e7          	jalr	1412(ra) # 80004b26 <end_op>
    return -1;
    800065aa:	557d                	li	a0,-1
}
    800065ac:	60ea                	ld	ra,152(sp)
    800065ae:	644a                	ld	s0,144(sp)
    800065b0:	610d                	addi	sp,sp,160
    800065b2:	8082                	ret

00000000800065b4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800065b4:	7135                	addi	sp,sp,-160
    800065b6:	ed06                	sd	ra,152(sp)
    800065b8:	e922                	sd	s0,144(sp)
    800065ba:	e526                	sd	s1,136(sp)
    800065bc:	e14a                	sd	s2,128(sp)
    800065be:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800065c0:	ffffb097          	auipc	ra,0xffffb
    800065c4:	414080e7          	jalr	1044(ra) # 800019d4 <myproc>
    800065c8:	892a                	mv	s2,a0
  
  begin_op();
    800065ca:	ffffe097          	auipc	ra,0xffffe
    800065ce:	4dc080e7          	jalr	1244(ra) # 80004aa6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800065d2:	08000613          	li	a2,128
    800065d6:	f6040593          	addi	a1,s0,-160
    800065da:	4501                	li	a0,0
    800065dc:	ffffd097          	auipc	ra,0xffffd
    800065e0:	cb4080e7          	jalr	-844(ra) # 80003290 <argstr>
    800065e4:	04054b63          	bltz	a0,8000663a <sys_chdir+0x86>
    800065e8:	f6040513          	addi	a0,s0,-160
    800065ec:	ffffe097          	auipc	ra,0xffffe
    800065f0:	f88080e7          	jalr	-120(ra) # 80004574 <namei>
    800065f4:	84aa                	mv	s1,a0
    800065f6:	c131                	beqz	a0,8000663a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800065f8:	ffffd097          	auipc	ra,0xffffd
    800065fc:	7c6080e7          	jalr	1990(ra) # 80003dbe <ilock>
  if(ip->type != T_DIR){
    80006600:	04449703          	lh	a4,68(s1)
    80006604:	4785                	li	a5,1
    80006606:	04f71063          	bne	a4,a5,80006646 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000660a:	8526                	mv	a0,s1
    8000660c:	ffffe097          	auipc	ra,0xffffe
    80006610:	874080e7          	jalr	-1932(ra) # 80003e80 <iunlock>
  iput(p->cwd);
    80006614:	15093503          	ld	a0,336(s2)
    80006618:	ffffe097          	auipc	ra,0xffffe
    8000661c:	960080e7          	jalr	-1696(ra) # 80003f78 <iput>
  end_op();
    80006620:	ffffe097          	auipc	ra,0xffffe
    80006624:	506080e7          	jalr	1286(ra) # 80004b26 <end_op>
  p->cwd = ip;
    80006628:	14993823          	sd	s1,336(s2)
  return 0;
    8000662c:	4501                	li	a0,0
}
    8000662e:	60ea                	ld	ra,152(sp)
    80006630:	644a                	ld	s0,144(sp)
    80006632:	64aa                	ld	s1,136(sp)
    80006634:	690a                	ld	s2,128(sp)
    80006636:	610d                	addi	sp,sp,160
    80006638:	8082                	ret
    end_op();
    8000663a:	ffffe097          	auipc	ra,0xffffe
    8000663e:	4ec080e7          	jalr	1260(ra) # 80004b26 <end_op>
    return -1;
    80006642:	557d                	li	a0,-1
    80006644:	b7ed                	j	8000662e <sys_chdir+0x7a>
    iunlockput(ip);
    80006646:	8526                	mv	a0,s1
    80006648:	ffffe097          	auipc	ra,0xffffe
    8000664c:	9d8080e7          	jalr	-1576(ra) # 80004020 <iunlockput>
    end_op();
    80006650:	ffffe097          	auipc	ra,0xffffe
    80006654:	4d6080e7          	jalr	1238(ra) # 80004b26 <end_op>
    return -1;
    80006658:	557d                	li	a0,-1
    8000665a:	bfd1                	j	8000662e <sys_chdir+0x7a>

000000008000665c <sys_exec>:

uint64
sys_exec(void)
{
    8000665c:	7145                	addi	sp,sp,-464
    8000665e:	e786                	sd	ra,456(sp)
    80006660:	e3a2                	sd	s0,448(sp)
    80006662:	ff26                	sd	s1,440(sp)
    80006664:	fb4a                	sd	s2,432(sp)
    80006666:	f74e                	sd	s3,424(sp)
    80006668:	f352                	sd	s4,416(sp)
    8000666a:	ef56                	sd	s5,408(sp)
    8000666c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000666e:	08000613          	li	a2,128
    80006672:	f4040593          	addi	a1,s0,-192
    80006676:	4501                	li	a0,0
    80006678:	ffffd097          	auipc	ra,0xffffd
    8000667c:	c18080e7          	jalr	-1000(ra) # 80003290 <argstr>
    return -1;
    80006680:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006682:	0c054a63          	bltz	a0,80006756 <sys_exec+0xfa>
    80006686:	e3840593          	addi	a1,s0,-456
    8000668a:	4505                	li	a0,1
    8000668c:	ffffd097          	auipc	ra,0xffffd
    80006690:	be2080e7          	jalr	-1054(ra) # 8000326e <argaddr>
    80006694:	0c054163          	bltz	a0,80006756 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006698:	10000613          	li	a2,256
    8000669c:	4581                	li	a1,0
    8000669e:	e4040513          	addi	a0,s0,-448
    800066a2:	ffffa097          	auipc	ra,0xffffa
    800066a6:	61c080e7          	jalr	1564(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800066aa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800066ae:	89a6                	mv	s3,s1
    800066b0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800066b2:	02000a13          	li	s4,32
    800066b6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800066ba:	00391793          	slli	a5,s2,0x3
    800066be:	e3040593          	addi	a1,s0,-464
    800066c2:	e3843503          	ld	a0,-456(s0)
    800066c6:	953e                	add	a0,a0,a5
    800066c8:	ffffd097          	auipc	ra,0xffffd
    800066cc:	aea080e7          	jalr	-1302(ra) # 800031b2 <fetchaddr>
    800066d0:	02054a63          	bltz	a0,80006704 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800066d4:	e3043783          	ld	a5,-464(s0)
    800066d8:	c3b9                	beqz	a5,8000671e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800066da:	ffffa097          	auipc	ra,0xffffa
    800066de:	3f8080e7          	jalr	1016(ra) # 80000ad2 <kalloc>
    800066e2:	85aa                	mv	a1,a0
    800066e4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800066e8:	cd11                	beqz	a0,80006704 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800066ea:	6605                	lui	a2,0x1
    800066ec:	e3043503          	ld	a0,-464(s0)
    800066f0:	ffffd097          	auipc	ra,0xffffd
    800066f4:	b14080e7          	jalr	-1260(ra) # 80003204 <fetchstr>
    800066f8:	00054663          	bltz	a0,80006704 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800066fc:	0905                	addi	s2,s2,1
    800066fe:	09a1                	addi	s3,s3,8
    80006700:	fb491be3          	bne	s2,s4,800066b6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006704:	10048913          	addi	s2,s1,256
    80006708:	6088                	ld	a0,0(s1)
    8000670a:	c529                	beqz	a0,80006754 <sys_exec+0xf8>
    kfree(argv[i]);
    8000670c:	ffffa097          	auipc	ra,0xffffa
    80006710:	2ca080e7          	jalr	714(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006714:	04a1                	addi	s1,s1,8
    80006716:	ff2499e3          	bne	s1,s2,80006708 <sys_exec+0xac>
  return -1;
    8000671a:	597d                	li	s2,-1
    8000671c:	a82d                	j	80006756 <sys_exec+0xfa>
      argv[i] = 0;
    8000671e:	0a8e                	slli	s5,s5,0x3
    80006720:	fc040793          	addi	a5,s0,-64
    80006724:	9abe                	add	s5,s5,a5
    80006726:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000672a:	e4040593          	addi	a1,s0,-448
    8000672e:	f4040513          	addi	a0,s0,-192
    80006732:	fffff097          	auipc	ra,0xfffff
    80006736:	088080e7          	jalr	136(ra) # 800057ba <exec>
    8000673a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000673c:	10048993          	addi	s3,s1,256
    80006740:	6088                	ld	a0,0(s1)
    80006742:	c911                	beqz	a0,80006756 <sys_exec+0xfa>
    kfree(argv[i]);
    80006744:	ffffa097          	auipc	ra,0xffffa
    80006748:	292080e7          	jalr	658(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000674c:	04a1                	addi	s1,s1,8
    8000674e:	ff3499e3          	bne	s1,s3,80006740 <sys_exec+0xe4>
    80006752:	a011                	j	80006756 <sys_exec+0xfa>
  return -1;
    80006754:	597d                	li	s2,-1
}
    80006756:	854a                	mv	a0,s2
    80006758:	60be                	ld	ra,456(sp)
    8000675a:	641e                	ld	s0,448(sp)
    8000675c:	74fa                	ld	s1,440(sp)
    8000675e:	795a                	ld	s2,432(sp)
    80006760:	79ba                	ld	s3,424(sp)
    80006762:	7a1a                	ld	s4,416(sp)
    80006764:	6afa                	ld	s5,408(sp)
    80006766:	6179                	addi	sp,sp,464
    80006768:	8082                	ret

000000008000676a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000676a:	7139                	addi	sp,sp,-64
    8000676c:	fc06                	sd	ra,56(sp)
    8000676e:	f822                	sd	s0,48(sp)
    80006770:	f426                	sd	s1,40(sp)
    80006772:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006774:	ffffb097          	auipc	ra,0xffffb
    80006778:	260080e7          	jalr	608(ra) # 800019d4 <myproc>
    8000677c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000677e:	fd840593          	addi	a1,s0,-40
    80006782:	4501                	li	a0,0
    80006784:	ffffd097          	auipc	ra,0xffffd
    80006788:	aea080e7          	jalr	-1302(ra) # 8000326e <argaddr>
    return -1;
    8000678c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000678e:	0e054063          	bltz	a0,8000686e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006792:	fc840593          	addi	a1,s0,-56
    80006796:	fd040513          	addi	a0,s0,-48
    8000679a:	fffff097          	auipc	ra,0xfffff
    8000679e:	cfe080e7          	jalr	-770(ra) # 80005498 <pipealloc>
    return -1;
    800067a2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800067a4:	0c054563          	bltz	a0,8000686e <sys_pipe+0x104>
  fd0 = -1;
    800067a8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800067ac:	fd043503          	ld	a0,-48(s0)
    800067b0:	fffff097          	auipc	ra,0xfffff
    800067b4:	4e8080e7          	jalr	1256(ra) # 80005c98 <fdalloc>
    800067b8:	fca42223          	sw	a0,-60(s0)
    800067bc:	08054c63          	bltz	a0,80006854 <sys_pipe+0xea>
    800067c0:	fc843503          	ld	a0,-56(s0)
    800067c4:	fffff097          	auipc	ra,0xfffff
    800067c8:	4d4080e7          	jalr	1236(ra) # 80005c98 <fdalloc>
    800067cc:	fca42023          	sw	a0,-64(s0)
    800067d0:	06054863          	bltz	a0,80006840 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067d4:	4691                	li	a3,4
    800067d6:	fc440613          	addi	a2,s0,-60
    800067da:	fd843583          	ld	a1,-40(s0)
    800067de:	68a8                	ld	a0,80(s1)
    800067e0:	ffffb097          	auipc	ra,0xffffb
    800067e4:	eb4080e7          	jalr	-332(ra) # 80001694 <copyout>
    800067e8:	02054063          	bltz	a0,80006808 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800067ec:	4691                	li	a3,4
    800067ee:	fc040613          	addi	a2,s0,-64
    800067f2:	fd843583          	ld	a1,-40(s0)
    800067f6:	0591                	addi	a1,a1,4
    800067f8:	68a8                	ld	a0,80(s1)
    800067fa:	ffffb097          	auipc	ra,0xffffb
    800067fe:	e9a080e7          	jalr	-358(ra) # 80001694 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006802:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006804:	06055563          	bgez	a0,8000686e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006808:	fc442783          	lw	a5,-60(s0)
    8000680c:	07e9                	addi	a5,a5,26
    8000680e:	078e                	slli	a5,a5,0x3
    80006810:	97a6                	add	a5,a5,s1
    80006812:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006816:	fc042503          	lw	a0,-64(s0)
    8000681a:	0569                	addi	a0,a0,26
    8000681c:	050e                	slli	a0,a0,0x3
    8000681e:	9526                	add	a0,a0,s1
    80006820:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006824:	fd043503          	ld	a0,-48(s0)
    80006828:	ffffe097          	auipc	ra,0xffffe
    8000682c:	74a080e7          	jalr	1866(ra) # 80004f72 <fileclose>
    fileclose(wf);
    80006830:	fc843503          	ld	a0,-56(s0)
    80006834:	ffffe097          	auipc	ra,0xffffe
    80006838:	73e080e7          	jalr	1854(ra) # 80004f72 <fileclose>
    return -1;
    8000683c:	57fd                	li	a5,-1
    8000683e:	a805                	j	8000686e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006840:	fc442783          	lw	a5,-60(s0)
    80006844:	0007c863          	bltz	a5,80006854 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006848:	01a78513          	addi	a0,a5,26
    8000684c:	050e                	slli	a0,a0,0x3
    8000684e:	9526                	add	a0,a0,s1
    80006850:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006854:	fd043503          	ld	a0,-48(s0)
    80006858:	ffffe097          	auipc	ra,0xffffe
    8000685c:	71a080e7          	jalr	1818(ra) # 80004f72 <fileclose>
    fileclose(wf);
    80006860:	fc843503          	ld	a0,-56(s0)
    80006864:	ffffe097          	auipc	ra,0xffffe
    80006868:	70e080e7          	jalr	1806(ra) # 80004f72 <fileclose>
    return -1;
    8000686c:	57fd                	li	a5,-1
}
    8000686e:	853e                	mv	a0,a5
    80006870:	70e2                	ld	ra,56(sp)
    80006872:	7442                	ld	s0,48(sp)
    80006874:	74a2                	ld	s1,40(sp)
    80006876:	6121                	addi	sp,sp,64
    80006878:	8082                	ret
    8000687a:	0000                	unimp
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
    800068c0:	fbefc0ef          	jal	ra,8000307e <kerneltrap>
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
    8000695c:	050080e7          	jalr	80(ra) # 800019a8 <cpuid>
  
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
    80006994:	018080e7          	jalr	24(ra) # 800019a8 <cpuid>
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
    800069bc:	ff0080e7          	jalr	-16(ra) # 800019a8 <cpuid>
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
    800069e4:	00024797          	auipc	a5,0x24
    800069e8:	61c78793          	addi	a5,a5,1564 # 8002b000 <disk>
    800069ec:	00a78733          	add	a4,a5,a0
    800069f0:	6789                	lui	a5,0x2
    800069f2:	97ba                	add	a5,a5,a4
    800069f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800069f8:	e7ad                	bnez	a5,80006a62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800069fa:	00451793          	slli	a5,a0,0x4
    800069fe:	00026717          	auipc	a4,0x26
    80006a02:	60270713          	addi	a4,a4,1538 # 8002d000 <disk+0x2000>
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
    80006a26:	00024797          	auipc	a5,0x24
    80006a2a:	5da78793          	addi	a5,a5,1498 # 8002b000 <disk>
    80006a2e:	97aa                	add	a5,a5,a0
    80006a30:	6509                	lui	a0,0x2
    80006a32:	953e                	add	a0,a0,a5
    80006a34:	4785                	li	a5,1
    80006a36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006a3a:	00026517          	auipc	a0,0x26
    80006a3e:	5de50513          	addi	a0,a0,1502 # 8002d018 <disk+0x2018>
    80006a42:	ffffb097          	auipc	ra,0xffffb
    80006a46:	684080e7          	jalr	1668(ra) # 800020c6 <wakeup>
}
    80006a4a:	60a2                	ld	ra,8(sp)
    80006a4c:	6402                	ld	s0,0(sp)
    80006a4e:	0141                	addi	sp,sp,16
    80006a50:	8082                	ret
    panic("free_desc 1");
    80006a52:	00002517          	auipc	a0,0x2
    80006a56:	ffe50513          	addi	a0,a0,-2 # 80008a50 <syscalls+0x358>
    80006a5a:	ffffa097          	auipc	ra,0xffffa
    80006a5e:	ad0080e7          	jalr	-1328(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006a62:	00002517          	auipc	a0,0x2
    80006a66:	ffe50513          	addi	a0,a0,-2 # 80008a60 <syscalls+0x368>
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
    80006a80:	ff458593          	addi	a1,a1,-12 # 80008a70 <syscalls+0x378>
    80006a84:	00026517          	auipc	a0,0x26
    80006a88:	6a450513          	addi	a0,a0,1700 # 8002d128 <disk+0x2128>
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
    80006aea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd075f>
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
    80006b1c:	00024517          	auipc	a0,0x24
    80006b20:	4e450513          	addi	a0,a0,1252 # 8002b000 <disk>
    80006b24:	ffffa097          	auipc	ra,0xffffa
    80006b28:	19a080e7          	jalr	410(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006b2c:	00024717          	auipc	a4,0x24
    80006b30:	4d470713          	addi	a4,a4,1236 # 8002b000 <disk>
    80006b34:	00c75793          	srli	a5,a4,0xc
    80006b38:	2781                	sext.w	a5,a5
    80006b3a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006b3c:	00026797          	auipc	a5,0x26
    80006b40:	4c478793          	addi	a5,a5,1220 # 8002d000 <disk+0x2000>
    80006b44:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006b46:	00024717          	auipc	a4,0x24
    80006b4a:	53a70713          	addi	a4,a4,1338 # 8002b080 <disk+0x80>
    80006b4e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006b50:	00025717          	auipc	a4,0x25
    80006b54:	4b070713          	addi	a4,a4,1200 # 8002c000 <disk+0x1000>
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
    80006b8a:	efa50513          	addi	a0,a0,-262 # 80008a80 <syscalls+0x388>
    80006b8e:	ffffa097          	auipc	ra,0xffffa
    80006b92:	99c080e7          	jalr	-1636(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006b96:	00002517          	auipc	a0,0x2
    80006b9a:	f0a50513          	addi	a0,a0,-246 # 80008aa0 <syscalls+0x3a8>
    80006b9e:	ffffa097          	auipc	ra,0xffffa
    80006ba2:	98c080e7          	jalr	-1652(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006ba6:	00002517          	auipc	a0,0x2
    80006baa:	f1a50513          	addi	a0,a0,-230 # 80008ac0 <syscalls+0x3c8>
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
    80006be6:	00026517          	auipc	a0,0x26
    80006bea:	54250513          	addi	a0,a0,1346 # 8002d128 <disk+0x2128>
    80006bee:	ffffa097          	auipc	ra,0xffffa
    80006bf2:	fd4080e7          	jalr	-44(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006bf6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006bf8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006bfa:	00024c17          	auipc	s8,0x24
    80006bfe:	406c0c13          	addi	s8,s8,1030 # 8002b000 <disk>
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
    80006c22:	00026717          	auipc	a4,0x26
    80006c26:	3f670713          	addi	a4,a4,1014 # 8002d018 <disk+0x2018>
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
    80006c58:	00026597          	auipc	a1,0x26
    80006c5c:	4d058593          	addi	a1,a1,1232 # 8002d128 <disk+0x2128>
    80006c60:	00026517          	auipc	a0,0x26
    80006c64:	3b850513          	addi	a0,a0,952 # 8002d018 <disk+0x2018>
    80006c68:	ffffb097          	auipc	ra,0xffffb
    80006c6c:	3fa080e7          	jalr	1018(ra) # 80002062 <sleep>
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
    80006c7a:	00026697          	auipc	a3,0x26
    80006c7e:	3866b683          	ld	a3,902(a3) # 8002d000 <disk+0x2000>
    80006c82:	96ba                	add	a3,a3,a4
    80006c84:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c88:	00024817          	auipc	a6,0x24
    80006c8c:	37880813          	addi	a6,a6,888 # 8002b000 <disk>
    80006c90:	00026697          	auipc	a3,0x26
    80006c94:	37068693          	addi	a3,a3,880 # 8002d000 <disk+0x2000>
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
    80006d28:	00026917          	auipc	s2,0x26
    80006d2c:	40090913          	addi	s2,s2,1024 # 8002d128 <disk+0x2128>
  while(b->disk == 1) {
    80006d30:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006d32:	85ca                	mv	a1,s2
    80006d34:	8556                	mv	a0,s5
    80006d36:	ffffb097          	auipc	ra,0xffffb
    80006d3a:	32c080e7          	jalr	812(ra) # 80002062 <sleep>
  while(b->disk == 1) {
    80006d3e:	004aa783          	lw	a5,4(s5)
    80006d42:	fe9788e3          	beq	a5,s1,80006d32 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006d46:	f8042903          	lw	s2,-128(s0)
    80006d4a:	20090793          	addi	a5,s2,512
    80006d4e:	00479713          	slli	a4,a5,0x4
    80006d52:	00024797          	auipc	a5,0x24
    80006d56:	2ae78793          	addi	a5,a5,686 # 8002b000 <disk>
    80006d5a:	97ba                	add	a5,a5,a4
    80006d5c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006d60:	00026997          	auipc	s3,0x26
    80006d64:	2a098993          	addi	s3,s3,672 # 8002d000 <disk+0x2000>
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
    80006d88:	00026517          	auipc	a0,0x26
    80006d8c:	3a050513          	addi	a0,a0,928 # 8002d128 <disk+0x2128>
    80006d90:	ffffa097          	auipc	ra,0xffffa
    80006d94:	ee6080e7          	jalr	-282(ra) # 80000c76 <release>
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
    80006dc0:	00024817          	auipc	a6,0x24
    80006dc4:	24080813          	addi	a6,a6,576 # 8002b000 <disk>
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
    80006de0:	00026697          	auipc	a3,0x26
    80006de4:	22068693          	addi	a3,a3,544 # 8002d000 <disk+0x2000>
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
    80006e0e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd000e>
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
    80006e2c:	00026697          	auipc	a3,0x26
    80006e30:	1d46b683          	ld	a3,468(a3) # 8002d000 <disk+0x2000>
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
    80006e4a:	00026517          	auipc	a0,0x26
    80006e4e:	2de50513          	addi	a0,a0,734 # 8002d128 <disk+0x2128>
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
    80006e68:	00026797          	auipc	a5,0x26
    80006e6c:	19878793          	addi	a5,a5,408 # 8002d000 <disk+0x2000>
    80006e70:	6b94                	ld	a3,16(a5)
    80006e72:	0207d703          	lhu	a4,32(a5)
    80006e76:	0026d783          	lhu	a5,2(a3)
    80006e7a:	06f70163          	beq	a4,a5,80006edc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e7e:	00024917          	auipc	s2,0x24
    80006e82:	18290913          	addi	s2,s2,386 # 8002b000 <disk>
    80006e86:	00026497          	auipc	s1,0x26
    80006e8a:	17a48493          	addi	s1,s1,378 # 8002d000 <disk+0x2000>
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
    80006ebc:	ffffb097          	auipc	ra,0xffffb
    80006ec0:	20a080e7          	jalr	522(ra) # 800020c6 <wakeup>

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
    80006edc:	00026517          	auipc	a0,0x26
    80006ee0:	24c50513          	addi	a0,a0,588 # 8002d128 <disk+0x2128>
    80006ee4:	ffffa097          	auipc	ra,0xffffa
    80006ee8:	d92080e7          	jalr	-622(ra) # 80000c76 <release>
}
    80006eec:	60e2                	ld	ra,24(sp)
    80006eee:	6442                	ld	s0,16(sp)
    80006ef0:	64a2                	ld	s1,8(sp)
    80006ef2:	6902                	ld	s2,0(sp)
    80006ef4:	6105                	addi	sp,sp,32
    80006ef6:	8082                	ret
      panic("virtio_disk_intr status");
    80006ef8:	00002517          	auipc	a0,0x2
    80006efc:	be850513          	addi	a0,a0,-1048 # 80008ae0 <syscalls+0x3e8>
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
	...
