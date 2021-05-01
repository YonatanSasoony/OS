
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
    80000068:	91c78793          	addi	a5,a5,-1764 # 80006980 <timervec>
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
    80000122:	8c8080e7          	jalr	-1848(ra) # 800029e6 <either_copyin>
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
    800001c6:	4c8080e7          	jalr	1224(ra) # 8000268a <sleep>
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
    80000202:	790080e7          	jalr	1936(ra) # 8000298e <either_copyout>
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
    800002e2:	760080e7          	jalr	1888(ra) # 80002a3e <procdump>
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
    80000436:	3e2080e7          	jalr	994(ra) # 80002814 <wakeup>
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
    8000055c:	d0050513          	addi	a0,a0,-768 # 80008258 <digits+0x218>
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
    80000882:	f96080e7          	jalr	-106(ra) # 80002814 <wakeup>
    
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
    8000090e:	d80080e7          	jalr	-640(ra) # 8000268a <sleep>
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
    printf("PANIC-%s\n",lk->name);
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
    printf("PANIC-%s\n",lk->name);
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
    80000eda:	286080e7          	jalr	646(ra) # 8000315c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00006097          	auipc	ra,0x6
    80000ee2:	ae2080e7          	jalr	-1310(ra) # 800069c0 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	422080e7          	jalr	1058(ra) # 80002308 <scheduler>
    consoleinit();
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	54e080e7          	jalr	1358(ra) # 8000043c <consoleinit>
    printfinit();
    80000ef6:	00000097          	auipc	ra,0x0
    80000efa:	85e080e7          	jalr	-1954(ra) # 80000754 <printfinit>
    printf("\n");
    80000efe:	00007517          	auipc	a0,0x7
    80000f02:	35a50513          	addi	a0,a0,858 # 80008258 <digits+0x218>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	66e080e7          	jalr	1646(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	1aa50513          	addi	a0,a0,426 # 800080b8 <digits+0x78>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	65e080e7          	jalr	1630(ra) # 80000574 <printf>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	33a50513          	addi	a0,a0,826 # 80008258 <digits+0x218>
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
    80000f52:	1e6080e7          	jalr	486(ra) # 80003134 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	206080e7          	jalr	518(ra) # 8000315c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00006097          	auipc	ra,0x6
    80000f62:	a4c080e7          	jalr	-1460(ra) # 800069aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00006097          	auipc	ra,0x6
    80000f6a:	a5a080e7          	jalr	-1446(ra) # 800069c0 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00003097          	auipc	ra,0x3
    80000f72:	b72080e7          	jalr	-1166(ra) # 80003ae0 <binit>
    iinit();         // inode cache
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	204080e7          	jalr	516(ra) # 8000417a <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	1b2080e7          	jalr	434(ra) # 80005130 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00006097          	auipc	ra,0x6
    80000f8a:	b5c080e7          	jalr	-1188(ra) # 80006ae2 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	f4a080e7          	jalr	-182(ra) # 80001ed8 <userinit>
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
    8000188e:	e7648493          	addi	s1,s1,-394 # 80011700 <proc>
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
    800018ae:	e56a8a93          	addi	s5,s5,-426 # 80033700 <tickslock>
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
    8000195c:	62090913          	addi	s2,s2,1568 # 80011f78 <proc+0x878>
    80001960:	00032b97          	auipc	s7,0x32
    80001964:	618b8b93          	addi	s7,s7,1560 # 80033f78 <bcache+0x860>
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
    80001a84:	df07a783          	lw	a5,-528(a5) # 80008870 <first.1>
    80001a88:	eb89                	bnez	a5,80001a9a <forkret+0x32>
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }
  usertrapret();
    80001a8a:	00001097          	auipc	ra,0x1
    80001a8e:	6ea080e7          	jalr	1770(ra) # 80003174 <usertrapret>
}
    80001a92:	60a2                	ld	ra,8(sp)
    80001a94:	6402                	ld	s0,0(sp)
    80001a96:	0141                	addi	sp,sp,16
    80001a98:	8082                	ret
    first = 0;
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	dc07ab23          	sw	zero,-554(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001aa2:	4505                	li	a0,1
    80001aa4:	00002097          	auipc	ra,0x2
    80001aa8:	656080e7          	jalr	1622(ra) # 800040fa <fsinit>
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
    80001ad0:	dac78793          	addi	a5,a5,-596 # 80008878 <nextpid>
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
    80001b16:	d6278793          	addi	a5,a5,-670 # 80008874 <nexttid>
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
    80001b54:	a0bd                	j	80001bc2 <allocthread+0x88>
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
  t->proc = p;
    80001b7e:	0344bc23          	sd	s4,56(s1)
  memset(&t->context, 0, sizeof(t->context));
    80001b82:	07000613          	li	a2,112
    80001b86:	4581                	li	a1,0
    80001b88:	05048513          	addi	a0,s1,80
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	156080e7          	jalr	342(ra) # 80000ce2 <memset>
  t->context.ra = (uint64)forkret;
    80001b94:	00000797          	auipc	a5,0x0
    80001b98:	ed478793          	addi	a5,a5,-300 # 80001a68 <forkret>
    80001b9c:	e8bc                	sd	a5,80(s1)
  if((t->kstack = (uint64)kalloc()) == 0) {
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	f34080e7          	jalr	-204(ra) # 80000ad2 <kalloc>
    80001ba6:	892a                	mv	s2,a0
    80001ba8:	e0a8                	sd	a0,64(s1)
    80001baa:	c929                	beqz	a0,80001bfc <allocthread+0xc2>
  t->context.sp = t->kstack + PGSIZE;
    80001bac:	6785                	lui	a5,0x1
    80001bae:	00f50933          	add	s2,a0,a5
    80001bb2:	0524bc23          	sd	s2,88(s1)
  return t;
    80001bb6:	a815                	j	80001bea <allocthread+0xb0>
    for (t = p->threads; t < &p->threads[NTHREAD]; t++, t_index++) {
    80001bb8:	0c048493          	addi	s1,s1,192
    80001bbc:	2905                	addiw	s2,s2,1
    80001bbe:	03390563          	beq	s2,s3,80001be8 <allocthread+0xae>
      if (t != mythread()) {
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	e6e080e7          	jalr	-402(ra) # 80001a30 <mythread>
    80001bca:	fea487e3          	beq	s1,a0,80001bb8 <allocthread+0x7e>
        acquire(&t->lock);
    80001bce:	8526                	mv	a0,s1
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	ff2080e7          	jalr	-14(ra) # 80000bc2 <acquire>
        if (t->state == UNUSED_T) {
    80001bd8:	4c9c                	lw	a5,24(s1)
    80001bda:	dfb5                	beqz	a5,80001b56 <allocthread+0x1c>
        release(&t->lock);
    80001bdc:	8526                	mv	a0,s1
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	0aa080e7          	jalr	170(ra) # 80000c88 <release>
    80001be6:	bfc9                	j	80001bb8 <allocthread+0x7e>
    return 0;
    80001be8:	4481                	li	s1,0
}
    80001bea:	8526                	mv	a0,s1
    80001bec:	70a2                	ld	ra,40(sp)
    80001bee:	7402                	ld	s0,32(sp)
    80001bf0:	64e2                	ld	s1,24(sp)
    80001bf2:	6942                	ld	s2,16(sp)
    80001bf4:	69a2                	ld	s3,8(sp)
    80001bf6:	6a02                	ld	s4,0(sp)
    80001bf8:	6145                	addi	sp,sp,48
    80001bfa:	8082                	ret
      freethread(t);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	c32080e7          	jalr	-974(ra) # 80001830 <freethread>
      release(&t->lock);
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	080080e7          	jalr	128(ra) # 80000c88 <release>
      return 0;
    80001c10:	84ca                	mv	s1,s2
    80001c12:	bfe1                	j	80001bea <allocthread+0xb0>

0000000080001c14 <proc_pagetable>:
{
    80001c14:	1101                	addi	sp,sp,-32
    80001c16:	ec06                	sd	ra,24(sp)
    80001c18:	e822                	sd	s0,16(sp)
    80001c1a:	e426                	sd	s1,8(sp)
    80001c1c:	e04a                	sd	s2,0(sp)
    80001c1e:	1000                	addi	s0,sp,32
    80001c20:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	708080e7          	jalr	1800(ra) # 8000132a <uvmcreate>
    80001c2a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c2c:	c131                	beqz	a0,80001c70 <proc_pagetable+0x5c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c2e:	4729                	li	a4,10
    80001c30:	00005697          	auipc	a3,0x5
    80001c34:	3d068693          	addi	a3,a3,976 # 80007000 <_trampoline>
    80001c38:	6605                	lui	a2,0x1
    80001c3a:	040005b7          	lui	a1,0x4000
    80001c3e:	15fd                	addi	a1,a1,-1
    80001c40:	05b2                	slli	a1,a1,0xc
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	470080e7          	jalr	1136(ra) # 800010b2 <mappages>
    80001c4a:	02054a63          	bltz	a0,80001c7e <proc_pagetable+0x6a>
              (uint64)(p->trapframes), PTE_R | PTE_W) < 0){
    80001c4e:	6505                	lui	a0,0x1
    80001c50:	954a                	add	a0,a0,s2
  if(mappages(pagetable, TRAPFRAME(0), PGSIZE,
    80001c52:	4719                	li	a4,6
    80001c54:	87853683          	ld	a3,-1928(a0) # 878 <_entry-0x7ffff788>
    80001c58:	6605                	lui	a2,0x1
    80001c5a:	020005b7          	lui	a1,0x2000
    80001c5e:	15fd                	addi	a1,a1,-1
    80001c60:	05b6                	slli	a1,a1,0xd
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	44e080e7          	jalr	1102(ra) # 800010b2 <mappages>
    80001c6c:	02054163          	bltz	a0,80001c8e <proc_pagetable+0x7a>
}
    80001c70:	8526                	mv	a0,s1
    80001c72:	60e2                	ld	ra,24(sp)
    80001c74:	6442                	ld	s0,16(sp)
    80001c76:	64a2                	ld	s1,8(sp)
    80001c78:	6902                	ld	s2,0(sp)
    80001c7a:	6105                	addi	sp,sp,32
    80001c7c:	8082                	ret
    uvmfree(pagetable, 0);
    80001c7e:	4581                	li	a1,0
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	8a4080e7          	jalr	-1884(ra) # 80001526 <uvmfree>
    return 0;
    80001c8a:	4481                	li	s1,0
    80001c8c:	b7d5                	j	80001c70 <proc_pagetable+0x5c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c8e:	4681                	li	a3,0
    80001c90:	4605                	li	a2,1
    80001c92:	040005b7          	lui	a1,0x4000
    80001c96:	15fd                	addi	a1,a1,-1
    80001c98:	05b2                	slli	a1,a1,0xc
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	5ca080e7          	jalr	1482(ra) # 80001266 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ca4:	4581                	li	a1,0
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	87e080e7          	jalr	-1922(ra) # 80001526 <uvmfree>
    return 0;
    80001cb0:	4481                	li	s1,0
    80001cb2:	bf7d                	j	80001c70 <proc_pagetable+0x5c>

0000000080001cb4 <proc_freepagetable>:
{
    80001cb4:	1101                	addi	sp,sp,-32
    80001cb6:	ec06                	sd	ra,24(sp)
    80001cb8:	e822                	sd	s0,16(sp)
    80001cba:	e426                	sd	s1,8(sp)
    80001cbc:	e04a                	sd	s2,0(sp)
    80001cbe:	1000                	addi	s0,sp,32
    80001cc0:	84aa                	mv	s1,a0
    80001cc2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc4:	4681                	li	a3,0
    80001cc6:	4605                	li	a2,1
    80001cc8:	040005b7          	lui	a1,0x4000
    80001ccc:	15fd                	addi	a1,a1,-1
    80001cce:	05b2                	slli	a1,a1,0xc
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	596080e7          	jalr	1430(ra) # 80001266 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME(0), 1, 0);
    80001cd8:	4681                	li	a3,0
    80001cda:	4605                	li	a2,1
    80001cdc:	020005b7          	lui	a1,0x2000
    80001ce0:	15fd                	addi	a1,a1,-1
    80001ce2:	05b6                	slli	a1,a1,0xd
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	580080e7          	jalr	1408(ra) # 80001266 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cee:	85ca                	mv	a1,s2
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	00000097          	auipc	ra,0x0
    80001cf6:	834080e7          	jalr	-1996(ra) # 80001526 <uvmfree>
}
    80001cfa:	60e2                	ld	ra,24(sp)
    80001cfc:	6442                	ld	s0,16(sp)
    80001cfe:	64a2                	ld	s1,8(sp)
    80001d00:	6902                	ld	s2,0(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <freeproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  if(p->trapframes)
    80001d14:	6785                	lui	a5,0x1
    80001d16:	97aa                	add	a5,a5,a0
    80001d18:	8787b503          	ld	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001d1c:	c509                	beqz	a0,80001d26 <freeproc+0x20>
    kfree((void*)p->trapframes);
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	cb8080e7          	jalr	-840(ra) # 800009d6 <kfree>
  p->trapframes = 0;
    80001d26:	6785                	lui	a5,0x1
    80001d28:	97ca                	add	a5,a5,s2
    80001d2a:	8607bc23          	sd	zero,-1928(a5) # 878 <_entry-0x7ffff788>
  if(p->trapframe_backup)
    80001d2e:	1b893503          	ld	a0,440(s2)
    80001d32:	c509                	beqz	a0,80001d3c <freeproc+0x36>
    kfree((void*)p->trapframe_backup);
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	ca2080e7          	jalr	-862(ra) # 800009d6 <kfree>
  p->trapframe_backup = 0;
    80001d3c:	1a093c23          	sd	zero,440(s2)
  if(p->pagetable)
    80001d40:	1d893503          	ld	a0,472(s2)
    80001d44:	c519                	beqz	a0,80001d52 <freeproc+0x4c>
    proc_freepagetable(p->pagetable, p->sz);
    80001d46:	1d093583          	ld	a1,464(s2)
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	f6a080e7          	jalr	-150(ra) # 80001cb4 <proc_freepagetable>
  p->pagetable = 0;
    80001d52:	1c093c23          	sd	zero,472(s2)
  p->sz = 0;
    80001d56:	1c093823          	sd	zero,464(s2)
  p->pid = 0;
    80001d5a:	02092223          	sw	zero,36(s2)
  p->parent = 0;
    80001d5e:	1c093423          	sd	zero,456(s2)
  p->name[0] = 0;
    80001d62:	26090423          	sb	zero,616(s2)
  p->killed = 0;
    80001d66:	00092e23          	sw	zero,28(s2)
  p->stopped = 0;
    80001d6a:	1c092023          	sw	zero,448(s2)
  p->xstate = 0;
    80001d6e:	02092023          	sw	zero,32(s2)
  p->state = UNUSED;
    80001d72:	00092c23          	sw	zero,24(s2)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001d76:	27890493          	addi	s1,s2,632
    80001d7a:	6505                	lui	a0,0x1
    80001d7c:	87850513          	addi	a0,a0,-1928 # 878 <_entry-0x7ffff788>
    80001d80:	992a                	add	s2,s2,a0
    freethread(t);
    80001d82:	8526                	mv	a0,s1
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	aac080e7          	jalr	-1364(ra) # 80001830 <freethread>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80001d8c:	0c048493          	addi	s1,s1,192
    80001d90:	fe9919e3          	bne	s2,s1,80001d82 <freeproc+0x7c>
}
    80001d94:	60e2                	ld	ra,24(sp)
    80001d96:	6442                	ld	s0,16(sp)
    80001d98:	64a2                	ld	s1,8(sp)
    80001d9a:	6902                	ld	s2,0(sp)
    80001d9c:	6105                	addi	sp,sp,32
    80001d9e:	8082                	ret

0000000080001da0 <allocproc>:
{
    80001da0:	7179                	addi	sp,sp,-48
    80001da2:	f406                	sd	ra,40(sp)
    80001da4:	f022                	sd	s0,32(sp)
    80001da6:	ec26                	sd	s1,24(sp)
    80001da8:	e84a                	sd	s2,16(sp)
    80001daa:	e44e                	sd	s3,8(sp)
    80001dac:	e052                	sd	s4,0(sp)
    80001dae:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001db0:	00010497          	auipc	s1,0x10
    80001db4:	95048493          	addi	s1,s1,-1712 # 80011700 <proc>
    80001db8:	6985                	lui	s3,0x1
    80001dba:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80001dbe:	00032a17          	auipc	s4,0x32
    80001dc2:	942a0a13          	addi	s4,s4,-1726 # 80033700 <tickslock>
    acquire(&p->lock);
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	dfa080e7          	jalr	-518(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001dd0:	4c9c                	lw	a5,24(s1)
    80001dd2:	cb99                	beqz	a5,80001de8 <allocproc+0x48>
      release(&p->lock);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	eb2080e7          	jalr	-334(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dde:	94ce                	add	s1,s1,s3
    80001de0:	ff4493e3          	bne	s1,s4,80001dc6 <allocproc+0x26>
  return 0;
    80001de4:	4481                	li	s1,0
    80001de6:	a89d                	j	80001e5c <allocproc+0xbc>
  p->pid = allocpid();
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	cc6080e7          	jalr	-826(ra) # 80001aae <allocpid>
    80001df0:	d0c8                	sw	a0,36(s1)
  p->state = USED;
    80001df2:	4785                	li	a5,1
    80001df4:	cc9c                	sw	a5,24(s1)
  p->pending_signals = 0;
    80001df6:	0204a423          	sw	zero,40(s1)
  p->signal_mask = 0;
    80001dfa:	0204a623          	sw	zero,44(s1)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001dfe:	03848793          	addi	a5,s1,56
    80001e02:	13848713          	addi	a4,s1,312
    p->signal_handlers[signum] = SIG_DFL;
    80001e06:	0007b023          	sd	zero,0(a5)
  for(int signum = 0; signum < SIG_NUM; signum++){
    80001e0a:	07a1                	addi	a5,a5,8
    80001e0c:	fee79de3          	bne	a5,a4,80001e06 <allocproc+0x66>
  if((p->trapframes = (struct trapframe *)kalloc()) == 0){
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	cc2080e7          	jalr	-830(ra) # 80000ad2 <kalloc>
    80001e18:	892a                	mv	s2,a0
    80001e1a:	6785                	lui	a5,0x1
    80001e1c:	97a6                	add	a5,a5,s1
    80001e1e:	86a7bc23          	sd	a0,-1928(a5) # 878 <_entry-0x7ffff788>
    80001e22:	c531                	beqz	a0,80001e6e <allocproc+0xce>
  if((p->trapframe_backup = (struct trapframe *)kalloc()) == 0){
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	cae080e7          	jalr	-850(ra) # 80000ad2 <kalloc>
    80001e2c:	892a                	mv	s2,a0
    80001e2e:	1aa4bc23          	sd	a0,440(s1)
    80001e32:	c931                	beqz	a0,80001e86 <allocproc+0xe6>
  p->pagetable = proc_pagetable(p);
    80001e34:	8526                	mv	a0,s1
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	dde080e7          	jalr	-546(ra) # 80001c14 <proc_pagetable>
    80001e3e:	892a                	mv	s2,a0
    80001e40:	1ca4bc23          	sd	a0,472(s1)
  if(p->pagetable == 0){
    80001e44:	cd29                	beqz	a0,80001e9e <allocproc+0xfe>
  if ((t = allocthread(p)) == 0) {
    80001e46:	8526                	mv	a0,s1
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	cf2080e7          	jalr	-782(ra) # 80001b3a <allocthread>
    80001e50:	892a                	mv	s2,a0
    80001e52:	c135                	beqz	a0,80001eb6 <allocproc+0x116>
  release(&t->lock);
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	e34080e7          	jalr	-460(ra) # 80000c88 <release>
}
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	70a2                	ld	ra,40(sp)
    80001e60:	7402                	ld	s0,32(sp)
    80001e62:	64e2                	ld	s1,24(sp)
    80001e64:	6942                	ld	s2,16(sp)
    80001e66:	69a2                	ld	s3,8(sp)
    80001e68:	6a02                	ld	s4,0(sp)
    80001e6a:	6145                	addi	sp,sp,48
    80001e6c:	8082                	ret
    freeproc(p);
    80001e6e:	8526                	mv	a0,s1
    80001e70:	00000097          	auipc	ra,0x0
    80001e74:	e96080e7          	jalr	-362(ra) # 80001d06 <freeproc>
    release(&p->lock);
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e0e080e7          	jalr	-498(ra) # 80000c88 <release>
    return 0;
    80001e82:	84ca                	mv	s1,s2
    80001e84:	bfe1                	j	80001e5c <allocproc+0xbc>
    freeproc(p);
    80001e86:	8526                	mv	a0,s1
    80001e88:	00000097          	auipc	ra,0x0
    80001e8c:	e7e080e7          	jalr	-386(ra) # 80001d06 <freeproc>
    release(&p->lock);
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	df6080e7          	jalr	-522(ra) # 80000c88 <release>
    return 0;
    80001e9a:	84ca                	mv	s1,s2
    80001e9c:	b7c1                	j	80001e5c <allocproc+0xbc>
    freeproc(p);
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	00000097          	auipc	ra,0x0
    80001ea4:	e66080e7          	jalr	-410(ra) # 80001d06 <freeproc>
    release(&p->lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dde080e7          	jalr	-546(ra) # 80000c88 <release>
    return 0;
    80001eb2:	84ca                	mv	s1,s2
    80001eb4:	b765                	j	80001e5c <allocproc+0xbc>
    release(&t->lock);
    80001eb6:	4501                	li	a0,0
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	dd0080e7          	jalr	-560(ra) # 80000c88 <release>
    release(&p->lock);
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dc6080e7          	jalr	-570(ra) # 80000c88 <release>
    freeproc(p);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	e3a080e7          	jalr	-454(ra) # 80001d06 <freeproc>
    return 0;
    80001ed4:	84ca                	mv	s1,s2
    80001ed6:	b759                	j	80001e5c <allocproc+0xbc>

0000000080001ed8 <userinit>:
{
    80001ed8:	1101                	addi	sp,sp,-32
    80001eda:	ec06                	sd	ra,24(sp)
    80001edc:	e822                	sd	s0,16(sp)
    80001ede:	e426                	sd	s1,8(sp)
    80001ee0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ee2:	00000097          	auipc	ra,0x0
    80001ee6:	ebe080e7          	jalr	-322(ra) # 80001da0 <allocproc>
    80001eea:	84aa                	mv	s1,a0
  initproc = p;
    80001eec:	00007797          	auipc	a5,0x7
    80001ef0:	12a7be23          	sd	a0,316(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ef4:	03400613          	li	a2,52
    80001ef8:	00007597          	auipc	a1,0x7
    80001efc:	98858593          	addi	a1,a1,-1656 # 80008880 <initcode>
    80001f00:	1d853503          	ld	a0,472(a0)
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	454080e7          	jalr	1108(ra) # 80001358 <uvminit>
  p->sz = PGSIZE;
    80001f0c:	6785                	lui	a5,0x1
    80001f0e:	1cf4b823          	sd	a5,464(s1)
  p->trapframes->epc = 0;      // user program counter
    80001f12:	00f48733          	add	a4,s1,a5
    80001f16:	87873683          	ld	a3,-1928(a4)
    80001f1a:	0006bc23          	sd	zero,24(a3)
  p->trapframes->sp = PGSIZE;  // user stack pointer
    80001f1e:	87873703          	ld	a4,-1928(a4)
    80001f22:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f24:	4641                	li	a2,16
    80001f26:	00006597          	auipc	a1,0x6
    80001f2a:	2e258593          	addi	a1,a1,738 # 80008208 <digits+0x1c8>
    80001f2e:	26848513          	addi	a0,s1,616
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	f02080e7          	jalr	-254(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001f3a:	00006517          	auipc	a0,0x6
    80001f3e:	2de50513          	addi	a0,a0,734 # 80008218 <digits+0x1d8>
    80001f42:	00003097          	auipc	ra,0x3
    80001f46:	be6080e7          	jalr	-1050(ra) # 80004b28 <namei>
    80001f4a:	26a4b023          	sd	a0,608(s1)
  p->threads[0].state = RUNNABLE;
    80001f4e:	478d                	li	a5,3
    80001f50:	28f4a823          	sw	a5,656(s1)
  release(&p->lock);
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	d32080e7          	jalr	-718(ra) # 80000c88 <release>
}
    80001f5e:	60e2                	ld	ra,24(sp)
    80001f60:	6442                	ld	s0,16(sp)
    80001f62:	64a2                	ld	s1,8(sp)
    80001f64:	6105                	addi	sp,sp,32
    80001f66:	8082                	ret

0000000080001f68 <growproc>:
{
    80001f68:	1101                	addi	sp,sp,-32
    80001f6a:	ec06                	sd	ra,24(sp)
    80001f6c:	e822                	sd	s0,16(sp)
    80001f6e:	e426                	sd	s1,8(sp)
    80001f70:	e04a                	sd	s2,0(sp)
    80001f72:	1000                	addi	s0,sp,32
    80001f74:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	a80080e7          	jalr	-1408(ra) # 800019f6 <myproc>
    80001f7e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	c42080e7          	jalr	-958(ra) # 80000bc2 <acquire>
  sz = p->sz;
    80001f88:	1d04b583          	ld	a1,464(s1)
    80001f8c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f90:	03204463          	bgtz	s2,80001fb8 <growproc+0x50>
  } else if(n < 0){
    80001f94:	04094863          	bltz	s2,80001fe4 <growproc+0x7c>
  p->sz = sz;
    80001f98:	1602                	slli	a2,a2,0x20
    80001f9a:	9201                	srli	a2,a2,0x20
    80001f9c:	1cc4b823          	sd	a2,464(s1)
  release(&p->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	ce6080e7          	jalr	-794(ra) # 80000c88 <release>
  return 0;
    80001faa:	4501                	li	a0,0
}
    80001fac:	60e2                	ld	ra,24(sp)
    80001fae:	6442                	ld	s0,16(sp)
    80001fb0:	64a2                	ld	s1,8(sp)
    80001fb2:	6902                	ld	s2,0(sp)
    80001fb4:	6105                	addi	sp,sp,32
    80001fb6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fb8:	00c9063b          	addw	a2,s2,a2
    80001fbc:	1602                	slli	a2,a2,0x20
    80001fbe:	9201                	srli	a2,a2,0x20
    80001fc0:	1582                	slli	a1,a1,0x20
    80001fc2:	9181                	srli	a1,a1,0x20
    80001fc4:	1d84b503          	ld	a0,472(s1)
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	44a080e7          	jalr	1098(ra) # 80001412 <uvmalloc>
    80001fd0:	0005061b          	sext.w	a2,a0
    80001fd4:	f271                	bnez	a2,80001f98 <growproc+0x30>
      release(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	cb0080e7          	jalr	-848(ra) # 80000c88 <release>
      return -1;
    80001fe0:	557d                	li	a0,-1
    80001fe2:	b7e9                	j	80001fac <growproc+0x44>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fe4:	00c9063b          	addw	a2,s2,a2
    80001fe8:	1602                	slli	a2,a2,0x20
    80001fea:	9201                	srli	a2,a2,0x20
    80001fec:	1582                	slli	a1,a1,0x20
    80001fee:	9181                	srli	a1,a1,0x20
    80001ff0:	1d84b503          	ld	a0,472(s1)
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	3d6080e7          	jalr	982(ra) # 800013ca <uvmdealloc>
    80001ffc:	0005061b          	sext.w	a2,a0
    80002000:	bf61                	j	80001f98 <growproc+0x30>

0000000080002002 <fork>:
{
    80002002:	7139                	addi	sp,sp,-64
    80002004:	fc06                	sd	ra,56(sp)
    80002006:	f822                	sd	s0,48(sp)
    80002008:	f426                	sd	s1,40(sp)
    8000200a:	f04a                	sd	s2,32(sp)
    8000200c:	ec4e                	sd	s3,24(sp)
    8000200e:	e852                	sd	s4,16(sp)
    80002010:	e456                	sd	s5,8(sp)
    80002012:	0080                	addi	s0,sp,64
  struct thread *t = mythread();
    80002014:	00000097          	auipc	ra,0x0
    80002018:	a1c080e7          	jalr	-1508(ra) # 80001a30 <mythread>
    8000201c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	9d8080e7          	jalr	-1576(ra) # 800019f6 <myproc>
    80002026:	892a                	mv	s2,a0
  if((np = allocproc()) == 0) {
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	d78080e7          	jalr	-648(ra) # 80001da0 <allocproc>
    80002030:	14050a63          	beqz	a0,80002184 <fork+0x182>
    80002034:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002036:	1d093603          	ld	a2,464(s2)
    8000203a:	1d853583          	ld	a1,472(a0)
    8000203e:	1d893503          	ld	a0,472(s2)
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	51c080e7          	jalr	1308(ra) # 8000155e <uvmcopy>
    8000204a:	04054763          	bltz	a0,80002098 <fork+0x96>
  np->sz = p->sz;
    8000204e:	1d093783          	ld	a5,464(s2)
    80002052:	1cfa3823          	sd	a5,464(s4)
  *(nt->trapframe) = *(t->trapframe); 
    80002056:	64b4                	ld	a3,72(s1)
    80002058:	87b6                	mv	a5,a3
    8000205a:	2c0a3703          	ld	a4,704(s4)
    8000205e:	12068693          	addi	a3,a3,288
    80002062:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002066:	6788                	ld	a0,8(a5)
    80002068:	6b8c                	ld	a1,16(a5)
    8000206a:	6f90                	ld	a2,24(a5)
    8000206c:	01073023          	sd	a6,0(a4)
    80002070:	e708                	sd	a0,8(a4)
    80002072:	eb0c                	sd	a1,16(a4)
    80002074:	ef10                	sd	a2,24(a4)
    80002076:	02078793          	addi	a5,a5,32
    8000207a:	02070713          	addi	a4,a4,32
    8000207e:	fed792e3          	bne	a5,a3,80002062 <fork+0x60>
  nt->trapframe->a0 = 0;
    80002082:	2c0a3783          	ld	a5,704(s4)
    80002086:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000208a:	1e090493          	addi	s1,s2,480
    8000208e:	1e0a0993          	addi	s3,s4,480
    80002092:	26090a93          	addi	s5,s2,608
    80002096:	a00d                	j	800020b8 <fork+0xb6>
    freeproc(np);
    80002098:	8552                	mv	a0,s4
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	c6c080e7          	jalr	-916(ra) # 80001d06 <freeproc>
    release(&np->lock);
    800020a2:	8552                	mv	a0,s4
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	be4080e7          	jalr	-1052(ra) # 80000c88 <release>
    return -1;
    800020ac:	59fd                	li	s3,-1
    800020ae:	a0c9                	j	80002170 <fork+0x16e>
  for(i = 0; i < NOFILE; i++)
    800020b0:	04a1                	addi	s1,s1,8
    800020b2:	09a1                	addi	s3,s3,8
    800020b4:	01548b63          	beq	s1,s5,800020ca <fork+0xc8>
    if(p->ofile[i])
    800020b8:	6088                	ld	a0,0(s1)
    800020ba:	d97d                	beqz	a0,800020b0 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    800020bc:	00003097          	auipc	ra,0x3
    800020c0:	106080e7          	jalr	262(ra) # 800051c2 <filedup>
    800020c4:	00a9b023          	sd	a0,0(s3)
    800020c8:	b7e5                	j	800020b0 <fork+0xae>
  np->cwd = idup(p->cwd);
    800020ca:	26093503          	ld	a0,608(s2)
    800020ce:	00002097          	auipc	ra,0x2
    800020d2:	266080e7          	jalr	614(ra) # 80004334 <idup>
    800020d6:	26aa3023          	sd	a0,608(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020da:	4641                	li	a2,16
    800020dc:	26890593          	addi	a1,s2,616
    800020e0:	268a0513          	addi	a0,s4,616
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	d50080e7          	jalr	-688(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    800020ec:	024a2983          	lw	s3,36(s4)
  release(&np->lock);
    800020f0:	8552                	mv	a0,s4
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	b96080e7          	jalr	-1130(ra) # 80000c88 <release>
  acquire(&wait_lock);
    800020fa:	0000f497          	auipc	s1,0xf
    800020fe:	1be48493          	addi	s1,s1,446 # 800112b8 <wait_lock>
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	abe080e7          	jalr	-1346(ra) # 80000bc2 <acquire>
  np->parent = p;
    8000210c:	1d2a3423          	sd	s2,456(s4)
  release(&wait_lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b76080e7          	jalr	-1162(ra) # 80000c88 <release>
  acquire(&np->lock);
    8000211a:	8552                	mv	a0,s4
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	aa6080e7          	jalr	-1370(ra) # 80000bc2 <acquire>
  np->signal_mask = p->signal_mask;  // ADDED Q2.1.2
    80002124:	02c92783          	lw	a5,44(s2)
    80002128:	02fa2623          	sw	a5,44(s4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    8000212c:	03890793          	addi	a5,s2,56
    80002130:	038a0713          	addi	a4,s4,56
    80002134:	13890613          	addi	a2,s2,312
    np->signal_handlers[i] = p->signal_handlers[i];    
    80002138:	6394                	ld	a3,0(a5)
    8000213a:	e314                	sd	a3,0(a4)
  for(int i=0; i<SIG_NUM; i++) {// ADDED Q2.1.2
    8000213c:	07a1                	addi	a5,a5,8
    8000213e:	0721                	addi	a4,a4,8
    80002140:	fec79ce3          	bne	a5,a2,80002138 <fork+0x136>
  np->pending_signals = 0; // ADDED Q2.1.2
    80002144:	020a2423          	sw	zero,40(s4)
  release(&np->lock);
    80002148:	8552                	mv	a0,s4
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b3e080e7          	jalr	-1218(ra) # 80000c88 <release>
  acquire(&nt->lock);
    80002152:	278a0493          	addi	s1,s4,632
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	a6a080e7          	jalr	-1430(ra) # 80000bc2 <acquire>
  nt->state = RUNNABLE;
    80002160:	478d                	li	a5,3
    80002162:	28fa2823          	sw	a5,656(s4)
  release(&nt->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b20080e7          	jalr	-1248(ra) # 80000c88 <release>
}
    80002170:	854e                	mv	a0,s3
    80002172:	70e2                	ld	ra,56(sp)
    80002174:	7442                	ld	s0,48(sp)
    80002176:	74a2                	ld	s1,40(sp)
    80002178:	7902                	ld	s2,32(sp)
    8000217a:	69e2                	ld	s3,24(sp)
    8000217c:	6a42                	ld	s4,16(sp)
    8000217e:	6aa2                	ld	s5,8(sp)
    80002180:	6121                	addi	sp,sp,64
    80002182:	8082                	ret
    return -1;
    80002184:	59fd                	li	s3,-1
    80002186:	b7ed                	j	80002170 <fork+0x16e>

0000000080002188 <kill_handler>:
{
    80002188:	1141                	addi	sp,sp,-16
    8000218a:	e406                	sd	ra,8(sp)
    8000218c:	e022                	sd	s0,0(sp)
    8000218e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002190:	00000097          	auipc	ra,0x0
    80002194:	866080e7          	jalr	-1946(ra) # 800019f6 <myproc>
  p->killed = 1; 
    80002198:	4785                	li	a5,1
    8000219a:	cd5c                	sw	a5,28(a0)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    8000219c:	27850793          	addi	a5,a0,632
    800021a0:	6705                	lui	a4,0x1
    800021a2:	87870713          	addi	a4,a4,-1928 # 878 <_entry-0x7ffff788>
    800021a6:	953a                	add	a0,a0,a4
    if (t->state == SLEEPING) {
    800021a8:	4689                	li	a3,2
      t->state = RUNNABLE;
    800021aa:	460d                	li	a2,3
    800021ac:	a029                	j	800021b6 <kill_handler+0x2e>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800021ae:	0c078793          	addi	a5,a5,192
    800021b2:	00f50763          	beq	a0,a5,800021c0 <kill_handler+0x38>
    if (t->state == SLEEPING) {
    800021b6:	4f98                	lw	a4,24(a5)
    800021b8:	fed71be3          	bne	a4,a3,800021ae <kill_handler+0x26>
      t->state = RUNNABLE;
    800021bc:	cf90                	sw	a2,24(a5)
    800021be:	bfc5                	j	800021ae <kill_handler+0x26>
}
    800021c0:	60a2                	ld	ra,8(sp)
    800021c2:	6402                	ld	s0,0(sp)
    800021c4:	0141                	addi	sp,sp,16
    800021c6:	8082                	ret

00000000800021c8 <received_continue>:
{
    800021c8:	1101                	addi	sp,sp,-32
    800021ca:	ec06                	sd	ra,24(sp)
    800021cc:	e822                	sd	s0,16(sp)
    800021ce:	e426                	sd	s1,8(sp)
    800021d0:	e04a                	sd	s2,0(sp)
    800021d2:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	822080e7          	jalr	-2014(ra) # 800019f6 <myproc>
    800021dc:	892a                	mv	s2,a0
    acquire(&p->lock);
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	9e4080e7          	jalr	-1564(ra) # 80000bc2 <acquire>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    800021e6:	02c92683          	lw	a3,44(s2)
    800021ea:	fff6c693          	not	a3,a3
    800021ee:	02892783          	lw	a5,40(s2)
    800021f2:	8efd                	and	a3,a3,a5
    800021f4:	2681                	sext.w	a3,a3
    for (int signum = 0; signum < SIG_NUM; signum++) {
    800021f6:	03890713          	addi	a4,s2,56
    800021fa:	4781                	li	a5,0
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    800021fc:	454d                	li	a0,19
    for (int signum = 0; signum < SIG_NUM; signum++) {
    800021fe:	02000613          	li	a2,32
    80002202:	a801                	j	80002212 <received_continue+0x4a>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002204:	630c                	ld	a1,0(a4)
    80002206:	00a58f63          	beq	a1,a0,80002224 <received_continue+0x5c>
    for (int signum = 0; signum < SIG_NUM; signum++) {
    8000220a:	2785                	addiw	a5,a5,1
    8000220c:	0721                	addi	a4,a4,8
    8000220e:	02c78163          	beq	a5,a2,80002230 <received_continue+0x68>
      if( (pending_and_not_blocked & (1 << signum)) &&
    80002212:	40f6d4bb          	sraw	s1,a3,a5
    80002216:	8885                	andi	s1,s1,1
    80002218:	d8ed                	beqz	s1,8000220a <received_continue+0x42>
    8000221a:	0d093583          	ld	a1,208(s2)
    8000221e:	f1fd                	bnez	a1,80002204 <received_continue+0x3c>
          ((p->signal_handlers[SIGCONT] == SIG_DFL && signum == SIGCONT) || (p->signal_handlers[signum] == (void *)SIGCONT)) ){
    80002220:	fea792e3          	bne	a5,a0,80002204 <received_continue+0x3c>
            release(&p->lock);
    80002224:	854a                	mv	a0,s2
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a62080e7          	jalr	-1438(ra) # 80000c88 <release>
            return 1;
    8000222e:	a039                	j	8000223c <received_continue+0x74>
    release(&p->lock);
    80002230:	854a                	mv	a0,s2
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a56080e7          	jalr	-1450(ra) # 80000c88 <release>
    return 0;
    8000223a:	4481                	li	s1,0
}
    8000223c:	8526                	mv	a0,s1
    8000223e:	60e2                	ld	ra,24(sp)
    80002240:	6442                	ld	s0,16(sp)
    80002242:	64a2                	ld	s1,8(sp)
    80002244:	6902                	ld	s2,0(sp)
    80002246:	6105                	addi	sp,sp,32
    80002248:	8082                	ret

000000008000224a <continue_handler>:
{
    8000224a:	1141                	addi	sp,sp,-16
    8000224c:	e406                	sd	ra,8(sp)
    8000224e:	e022                	sd	s0,0(sp)
    80002250:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	7a4080e7          	jalr	1956(ra) # 800019f6 <myproc>
  p->stopped = 0;
    8000225a:	1c052023          	sw	zero,448(a0)
}
    8000225e:	60a2                	ld	ra,8(sp)
    80002260:	6402                	ld	s0,0(sp)
    80002262:	0141                	addi	sp,sp,16
    80002264:	8082                	ret

0000000080002266 <handle_user_signals>:
handle_user_signals(int signum) {
    80002266:	7179                	addi	sp,sp,-48
    80002268:	f406                	sd	ra,40(sp)
    8000226a:	f022                	sd	s0,32(sp)
    8000226c:	ec26                	sd	s1,24(sp)
    8000226e:	e84a                	sd	s2,16(sp)
    80002270:	e44e                	sd	s3,8(sp)
    80002272:	1800                	addi	s0,sp,48
    80002274:	892a                	mv	s2,a0
  struct thread *t = mythread();
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	7ba080e7          	jalr	1978(ra) # 80001a30 <mythread>
    8000227e:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	776080e7          	jalr	1910(ra) # 800019f6 <myproc>
    80002288:	84aa                	mv	s1,a0
  p->signal_mask_backup = p->signal_mask;
    8000228a:	555c                	lw	a5,44(a0)
    8000228c:	d91c                	sw	a5,48(a0)
  p->signal_mask = p->signal_handlers_masks[signum];  
    8000228e:	04c90793          	addi	a5,s2,76
    80002292:	078a                	slli	a5,a5,0x2
    80002294:	97aa                	add	a5,a5,a0
    80002296:	479c                	lw	a5,8(a5)
    80002298:	d55c                	sw	a5,44(a0)
  memmove(p->trapframe_backup, t->trapframe, sizeof(struct trapframe));
    8000229a:	12000613          	li	a2,288
    8000229e:	0489b583          	ld	a1,72(s3)
    800022a2:	1b853503          	ld	a0,440(a0)
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	a98080e7          	jalr	-1384(ra) # 80000d3e <memmove>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    800022ae:	0489b703          	ld	a4,72(s3)
  int inject_sigret_size = (uint64)&end_inject_sigret - (uint64)&start_inject_sigret;
    800022b2:	00005617          	auipc	a2,0x5
    800022b6:	e6060613          	addi	a2,a2,-416 # 80007112 <start_inject_sigret>
  t->trapframe->sp = t->trapframe->sp - inject_sigret_size;
    800022ba:	00005697          	auipc	a3,0x5
    800022be:	e5e68693          	addi	a3,a3,-418 # 80007118 <end_inject_sigret>
    800022c2:	9e91                	subw	a3,a3,a2
    800022c4:	7b1c                	ld	a5,48(a4)
    800022c6:	8f95                	sub	a5,a5,a3
    800022c8:	fb1c                	sd	a5,48(a4)
  copyout(p->pagetable, (uint64) (t->trapframe->sp), (char *)&start_inject_sigret, inject_sigret_size);
    800022ca:	0489b783          	ld	a5,72(s3)
    800022ce:	7b8c                	ld	a1,48(a5)
    800022d0:	1d84b503          	ld	a0,472(s1)
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	38e080e7          	jalr	910(ra) # 80001662 <copyout>
  t->trapframe->a0 = signum;
    800022dc:	0489b783          	ld	a5,72(s3)
    800022e0:	0727b823          	sd	s2,112(a5)
  t->trapframe->epc = (uint64)p->signal_handlers[signum];
    800022e4:	0489b783          	ld	a5,72(s3)
    800022e8:	0919                	addi	s2,s2,6
    800022ea:	090e                	slli	s2,s2,0x3
    800022ec:	94ca                	add	s1,s1,s2
    800022ee:	6498                	ld	a4,8(s1)
    800022f0:	ef98                	sd	a4,24(a5)
  t->trapframe->ra = t->trapframe->sp;
    800022f2:	0489b783          	ld	a5,72(s3)
    800022f6:	7b98                	ld	a4,48(a5)
    800022f8:	f798                	sd	a4,40(a5)
}
    800022fa:	70a2                	ld	ra,40(sp)
    800022fc:	7402                	ld	s0,32(sp)
    800022fe:	64e2                	ld	s1,24(sp)
    80002300:	6942                	ld	s2,16(sp)
    80002302:	69a2                	ld	s3,8(sp)
    80002304:	6145                	addi	sp,sp,48
    80002306:	8082                	ret

0000000080002308 <scheduler>:
{
    80002308:	711d                	addi	sp,sp,-96
    8000230a:	ec86                	sd	ra,88(sp)
    8000230c:	e8a2                	sd	s0,80(sp)
    8000230e:	e4a6                	sd	s1,72(sp)
    80002310:	e0ca                	sd	s2,64(sp)
    80002312:	fc4e                	sd	s3,56(sp)
    80002314:	f852                	sd	s4,48(sp)
    80002316:	f456                	sd	s5,40(sp)
    80002318:	f05a                	sd	s6,32(sp)
    8000231a:	ec5e                	sd	s7,24(sp)
    8000231c:	e862                	sd	s8,16(sp)
    8000231e:	e466                	sd	s9,8(sp)
    80002320:	1080                	addi	s0,sp,96
    80002322:	8792                	mv	a5,tp
  int id = r_tp();
    80002324:	2781                	sext.w	a5,a5
  c->thread = 0;
    80002326:	00779a93          	slli	s5,a5,0x7
    8000232a:	0000f717          	auipc	a4,0xf
    8000232e:	f7670713          	addi	a4,a4,-138 # 800112a0 <pid_lock>
    80002332:	9756                	add	a4,a4,s5
    80002334:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &t->context);
    80002338:	0000f717          	auipc	a4,0xf
    8000233c:	fa070713          	addi	a4,a4,-96 # 800112d8 <cpus+0x8>
    80002340:	9aba                	add	s5,s5,a4
    80002342:	00032c97          	auipc	s9,0x32
    80002346:	c36c8c93          	addi	s9,s9,-970 # 80033f78 <bcache+0x860>
          t->state = RUNNING;
    8000234a:	4b11                	li	s6,4
          c->thread = t;
    8000234c:	079e                	slli	a5,a5,0x7
    8000234e:	0000fa17          	auipc	s4,0xf
    80002352:	f52a0a13          	addi	s4,s4,-174 # 800112a0 <pid_lock>
    80002356:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002358:	6c05                	lui	s8,0x1
    8000235a:	880c0c13          	addi	s8,s8,-1920 # 880 <_entry-0x7ffff780>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000235e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002362:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002366:	10079073          	csrw	sstatus,a5
    8000236a:	00010917          	auipc	s2,0x10
    8000236e:	c0e90913          	addi	s2,s2,-1010 # 80011f78 <proc+0x878>
          printf("scheduler found thread: %d\n",t->tid); //REMOVE
    80002372:	00006b97          	auipc	s7,0x6
    80002376:	eaeb8b93          	addi	s7,s7,-338 # 80008220 <digits+0x1e0>
    8000237a:	a889                	j	800023cc <scheduler+0xc4>
        release(&t->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	90a080e7          	jalr	-1782(ra) # 80000c88 <release>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002386:	0c048493          	addi	s1,s1,192
    8000238a:	03248e63          	beq	s1,s2,800023c6 <scheduler+0xbe>
        acquire(&t->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	832080e7          	jalr	-1998(ra) # 80000bc2 <acquire>
        if(t->state == RUNNABLE) {
    80002398:	4c9c                	lw	a5,24(s1)
    8000239a:	ff3791e3          	bne	a5,s3,8000237c <scheduler+0x74>
          printf("scheduler found thread: %d\n",t->tid); //REMOVE
    8000239e:	588c                	lw	a1,48(s1)
    800023a0:	855e                	mv	a0,s7
    800023a2:	ffffe097          	auipc	ra,0xffffe
    800023a6:	1d2080e7          	jalr	466(ra) # 80000574 <printf>
          t->state = RUNNING;
    800023aa:	0164ac23          	sw	s6,24(s1)
          c->thread = t;
    800023ae:	029a3823          	sd	s1,48(s4)
          swtch(&c->context, &t->context);
    800023b2:	05048593          	addi	a1,s1,80
    800023b6:	8556                	mv	a0,s5
    800023b8:	00001097          	auipc	ra,0x1
    800023bc:	d12080e7          	jalr	-750(ra) # 800030ca <swtch>
          c->thread = 0;
    800023c0:	020a3823          	sd	zero,48(s4)
    800023c4:	bf65                	j	8000237c <scheduler+0x74>
    for(p = proc; p < &proc[NPROC]; p++) {
    800023c6:	9962                	add	s2,s2,s8
    800023c8:	f9990be3          	beq	s2,s9,8000235e <scheduler+0x56>
      for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    800023cc:	a0090493          	addi	s1,s2,-1536
        if(t->state == RUNNABLE) {
    800023d0:	498d                	li	s3,3
    800023d2:	bf75                	j	8000238e <scheduler+0x86>

00000000800023d4 <sched>:
{
    800023d4:	7179                	addi	sp,sp,-48
    800023d6:	f406                	sd	ra,40(sp)
    800023d8:	f022                	sd	s0,32(sp)
    800023da:	ec26                	sd	s1,24(sp)
    800023dc:	e84a                	sd	s2,16(sp)
    800023de:	e44e                	sd	s3,8(sp)
    800023e0:	1800                	addi	s0,sp,48
  struct thread *t = mythread();
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	64e080e7          	jalr	1614(ra) # 80001a30 <mythread>
    800023ea:	84aa                	mv	s1,a0
  if(!holding(&t->lock))
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	75c080e7          	jalr	1884(ra) # 80000b48 <holding>
    800023f4:	c93d                	beqz	a0,8000246a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023f6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1) {
    800023f8:	2781                	sext.w	a5,a5
    800023fa:	079e                	slli	a5,a5,0x7
    800023fc:	0000f717          	auipc	a4,0xf
    80002400:	ea470713          	addi	a4,a4,-348 # 800112a0 <pid_lock>
    80002404:	97ba                	add	a5,a5,a4
    80002406:	0a87a703          	lw	a4,168(a5)
    8000240a:	4785                	li	a5,1
    8000240c:	06f71763          	bne	a4,a5,8000247a <sched+0xa6>
  if(t->state == RUNNING)
    80002410:	4c98                	lw	a4,24(s1)
    80002412:	4791                	li	a5,4
    80002414:	08f70d63          	beq	a4,a5,800024ae <sched+0xda>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002418:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000241c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000241e:	e3c5                	bnez	a5,800024be <sched+0xea>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002420:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002422:	0000f917          	auipc	s2,0xf
    80002426:	e7e90913          	addi	s2,s2,-386 # 800112a0 <pid_lock>
    8000242a:	2781                	sext.w	a5,a5
    8000242c:	079e                	slli	a5,a5,0x7
    8000242e:	97ca                	add	a5,a5,s2
    80002430:	0ac7a983          	lw	s3,172(a5)
    80002434:	8792                	mv	a5,tp
  swtch(&t->context, &mycpu()->context);
    80002436:	2781                	sext.w	a5,a5
    80002438:	079e                	slli	a5,a5,0x7
    8000243a:	0000f597          	auipc	a1,0xf
    8000243e:	e9e58593          	addi	a1,a1,-354 # 800112d8 <cpus+0x8>
    80002442:	95be                	add	a1,a1,a5
    80002444:	05048513          	addi	a0,s1,80
    80002448:	00001097          	auipc	ra,0x1
    8000244c:	c82080e7          	jalr	-894(ra) # 800030ca <swtch>
    80002450:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002452:	2781                	sext.w	a5,a5
    80002454:	079e                	slli	a5,a5,0x7
    80002456:	97ca                	add	a5,a5,s2
    80002458:	0b37a623          	sw	s3,172(a5)
}
    8000245c:	70a2                	ld	ra,40(sp)
    8000245e:	7402                	ld	s0,32(sp)
    80002460:	64e2                	ld	s1,24(sp)
    80002462:	6942                	ld	s2,16(sp)
    80002464:	69a2                	ld	s3,8(sp)
    80002466:	6145                	addi	sp,sp,48
    80002468:	8082                	ret
    panic("sched t->lock");
    8000246a:	00006517          	auipc	a0,0x6
    8000246e:	dd650513          	addi	a0,a0,-554 # 80008240 <digits+0x200>
    80002472:	ffffe097          	auipc	ra,0xffffe
    80002476:	0b8080e7          	jalr	184(ra) # 8000052a <panic>
    8000247a:	8792                	mv	a5,tp
    printf("noff: %d\n", mycpu()->noff); // REMOVE
    8000247c:	2781                	sext.w	a5,a5
    8000247e:	079e                	slli	a5,a5,0x7
    80002480:	0000f717          	auipc	a4,0xf
    80002484:	e2070713          	addi	a4,a4,-480 # 800112a0 <pid_lock>
    80002488:	97ba                	add	a5,a5,a4
    8000248a:	0a87a583          	lw	a1,168(a5)
    8000248e:	00006517          	auipc	a0,0x6
    80002492:	dc250513          	addi	a0,a0,-574 # 80008250 <digits+0x210>
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	0de080e7          	jalr	222(ra) # 80000574 <printf>
    panic("sched locks\n");
    8000249e:	00006517          	auipc	a0,0x6
    800024a2:	dc250513          	addi	a0,a0,-574 # 80008260 <digits+0x220>
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	084080e7          	jalr	132(ra) # 8000052a <panic>
    panic("sched running");
    800024ae:	00006517          	auipc	a0,0x6
    800024b2:	dc250513          	addi	a0,a0,-574 # 80008270 <digits+0x230>
    800024b6:	ffffe097          	auipc	ra,0xffffe
    800024ba:	074080e7          	jalr	116(ra) # 8000052a <panic>
    panic("sched interruptible");
    800024be:	00006517          	auipc	a0,0x6
    800024c2:	dc250513          	addi	a0,a0,-574 # 80008280 <digits+0x240>
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	064080e7          	jalr	100(ra) # 8000052a <panic>

00000000800024ce <yield>:
{
    800024ce:	1101                	addi	sp,sp,-32
    800024d0:	ec06                	sd	ra,24(sp)
    800024d2:	e822                	sd	s0,16(sp)
    800024d4:	e426                	sd	s1,8(sp)
    800024d6:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	558080e7          	jalr	1368(ra) # 80001a30 <mythread>
    800024e0:	84aa                	mv	s1,a0
  acquire(&t->lock);
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	6e0080e7          	jalr	1760(ra) # 80000bc2 <acquire>
  t->state = RUNNABLE;
    800024ea:	478d                	li	a5,3
    800024ec:	cc9c                	sw	a5,24(s1)
  sched();
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	ee6080e7          	jalr	-282(ra) # 800023d4 <sched>
  release(&t->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	790080e7          	jalr	1936(ra) # 80000c88 <release>
}
    80002500:	60e2                	ld	ra,24(sp)
    80002502:	6442                	ld	s0,16(sp)
    80002504:	64a2                	ld	s1,8(sp)
    80002506:	6105                	addi	sp,sp,32
    80002508:	8082                	ret

000000008000250a <stop_handler>:
{
    8000250a:	1101                	addi	sp,sp,-32
    8000250c:	ec06                	sd	ra,24(sp)
    8000250e:	e822                	sd	s0,16(sp)
    80002510:	e426                	sd	s1,8(sp)
    80002512:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	4e2080e7          	jalr	1250(ra) # 800019f6 <myproc>
    8000251c:	84aa                	mv	s1,a0
  p->stopped = 1;
    8000251e:	4785                	li	a5,1
    80002520:	1cf52023          	sw	a5,448(a0)
  release(&p->lock);
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	764080e7          	jalr	1892(ra) # 80000c88 <release>
  while (p->stopped && !received_continue())
    8000252c:	1c04a783          	lw	a5,448(s1)
    80002530:	cf89                	beqz	a5,8000254a <stop_handler+0x40>
    80002532:	00000097          	auipc	ra,0x0
    80002536:	c96080e7          	jalr	-874(ra) # 800021c8 <received_continue>
    8000253a:	e901                	bnez	a0,8000254a <stop_handler+0x40>
      yield();
    8000253c:	00000097          	auipc	ra,0x0
    80002540:	f92080e7          	jalr	-110(ra) # 800024ce <yield>
  while (p->stopped && !received_continue())
    80002544:	1c04a783          	lw	a5,448(s1)
    80002548:	f7ed                	bnez	a5,80002532 <stop_handler+0x28>
  acquire(&p->lock);
    8000254a:	8526                	mv	a0,s1
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	676080e7          	jalr	1654(ra) # 80000bc2 <acquire>
}
    80002554:	60e2                	ld	ra,24(sp)
    80002556:	6442                	ld	s0,16(sp)
    80002558:	64a2                	ld	s1,8(sp)
    8000255a:	6105                	addi	sp,sp,32
    8000255c:	8082                	ret

000000008000255e <handle_signals>:
{
    8000255e:	711d                	addi	sp,sp,-96
    80002560:	ec86                	sd	ra,88(sp)
    80002562:	e8a2                	sd	s0,80(sp)
    80002564:	e4a6                	sd	s1,72(sp)
    80002566:	e0ca                	sd	s2,64(sp)
    80002568:	fc4e                	sd	s3,56(sp)
    8000256a:	f852                	sd	s4,48(sp)
    8000256c:	f456                	sd	s5,40(sp)
    8000256e:	f05a                	sd	s6,32(sp)
    80002570:	ec5e                	sd	s7,24(sp)
    80002572:	e862                	sd	s8,16(sp)
    80002574:	e466                	sd	s9,8(sp)
    80002576:	1080                	addi	s0,sp,96
  struct proc *p = myproc();
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	47e080e7          	jalr	1150(ra) # 800019f6 <myproc>
    80002580:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	640080e7          	jalr	1600(ra) # 80000bc2 <acquire>
  for(int signum = 0; signum < SIG_NUM; signum++){
    8000258a:	03890993          	addi	s3,s2,56
    8000258e:	4481                	li	s1,0
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002590:	4b05                	li	s6,1
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    80002592:	4ac5                	li	s5,17
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    80002594:	4bcd                	li	s7,19
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    80002596:	4c25                	li	s8,9
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    80002598:	4c85                	li	s9,1
  for(int signum = 0; signum < SIG_NUM; signum++){
    8000259a:	02000a13          	li	s4,32
    8000259e:	a0a1                	j	800025e6 <handle_signals+0x88>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800025a0:	03548263          	beq	s1,s5,800025c4 <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    800025a4:	09748b63          	beq	s1,s7,8000263a <handle_signals+0xdc>
        kill_handler();
    800025a8:	00000097          	auipc	ra,0x0
    800025ac:	be0080e7          	jalr	-1056(ra) # 80002188 <kill_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025b0:	009b17bb          	sllw	a5,s6,s1
    800025b4:	fff7c793          	not	a5,a5
    800025b8:	02892703          	lw	a4,40(s2)
    800025bc:	8ff9                	and	a5,a5,a4
    800025be:	02f92423          	sw	a5,40(s2)
    800025c2:	a831                	j	800025de <handle_signals+0x80>
        stop_handler();
    800025c4:	00000097          	auipc	ra,0x0
    800025c8:	f46080e7          	jalr	-186(ra) # 8000250a <stop_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    800025cc:	009b17bb          	sllw	a5,s6,s1
    800025d0:	fff7c793          	not	a5,a5
    800025d4:	02892703          	lw	a4,40(s2)
    800025d8:	8ff9                	and	a5,a5,a4
    800025da:	02f92423          	sw	a5,40(s2)
  for(int signum = 0; signum < SIG_NUM; signum++){
    800025de:	2485                	addiw	s1,s1,1
    800025e0:	09a1                	addi	s3,s3,8
    800025e2:	09448263          	beq	s1,s4,80002666 <handle_signals+0x108>
    int pending_and_not_blocked = p->pending_signals & ~(p->signal_mask);
    800025e6:	02892703          	lw	a4,40(s2)
    800025ea:	02c92783          	lw	a5,44(s2)
    800025ee:	fff7c793          	not	a5,a5
    800025f2:	8ff9                	and	a5,a5,a4
    if(pending_and_not_blocked & (1 << signum)){
    800025f4:	4097d7bb          	sraw	a5,a5,s1
    800025f8:	8b85                	andi	a5,a5,1
    800025fa:	d3f5                	beqz	a5,800025de <handle_signals+0x80>
      if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGSTOP) || p->signal_handlers[signum] == (void *)SIGSTOP) {
    800025fc:	0009b783          	ld	a5,0(s3)
    80002600:	d3c5                	beqz	a5,800025a0 <handle_signals+0x42>
    80002602:	fd5781e3          	beq	a5,s5,800025c4 <handle_signals+0x66>
      } else if ((p->signal_handlers[signum] == (void *)SIG_DFL && signum == SIGCONT) || p->signal_handlers[signum] == (void *)SIGCONT) {
    80002606:	03778a63          	beq	a5,s7,8000263a <handle_signals+0xdc>
      } else if (p->signal_handlers[signum] == (void *)SIG_DFL || (p->signal_handlers[signum] == (void *)SIGKILL)) { 
    8000260a:	f9878fe3          	beq	a5,s8,800025a8 <handle_signals+0x4a>
      } else if(p->signal_handlers[signum] == (void *)SIG_IGN ){
    8000260e:	05978463          	beq	a5,s9,80002656 <handle_signals+0xf8>
      } else if (p->handling_user_level_signal == 0){
    80002612:	1c492783          	lw	a5,452(s2)
    80002616:	f7e1                	bnez	a5,800025de <handle_signals+0x80>
        p->handling_user_level_signal = 1;
    80002618:	1d992223          	sw	s9,452(s2)
        handle_user_signals(signum);
    8000261c:	8526                	mv	a0,s1
    8000261e:	00000097          	auipc	ra,0x0
    80002622:	c48080e7          	jalr	-952(ra) # 80002266 <handle_user_signals>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002626:	009b17bb          	sllw	a5,s6,s1
    8000262a:	fff7c793          	not	a5,a5
    8000262e:	02892703          	lw	a4,40(s2)
    80002632:	8ff9                	and	a5,a5,a4
    80002634:	02f92423          	sw	a5,40(s2)
    80002638:	b75d                	j	800025de <handle_signals+0x80>
        continue_handler();
    8000263a:	00000097          	auipc	ra,0x0
    8000263e:	c10080e7          	jalr	-1008(ra) # 8000224a <continue_handler>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002642:	009b17bb          	sllw	a5,s6,s1
    80002646:	fff7c793          	not	a5,a5
    8000264a:	02892703          	lw	a4,40(s2)
    8000264e:	8ff9                	and	a5,a5,a4
    80002650:	02f92423          	sw	a5,40(s2)
    80002654:	b769                	j	800025de <handle_signals+0x80>
        p->pending_signals = p->pending_signals & ~(1 << signum); // turn off pending bit of signal
    80002656:	009b17bb          	sllw	a5,s6,s1
    8000265a:	fff7c793          	not	a5,a5
    8000265e:	8f7d                	and	a4,a4,a5
    80002660:	02e92423          	sw	a4,40(s2)
    80002664:	bfad                	j	800025de <handle_signals+0x80>
  release(&p->lock);
    80002666:	854a                	mv	a0,s2
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	620080e7          	jalr	1568(ra) # 80000c88 <release>
}
    80002670:	60e6                	ld	ra,88(sp)
    80002672:	6446                	ld	s0,80(sp)
    80002674:	64a6                	ld	s1,72(sp)
    80002676:	6906                	ld	s2,64(sp)
    80002678:	79e2                	ld	s3,56(sp)
    8000267a:	7a42                	ld	s4,48(sp)
    8000267c:	7aa2                	ld	s5,40(sp)
    8000267e:	7b02                	ld	s6,32(sp)
    80002680:	6be2                	ld	s7,24(sp)
    80002682:	6c42                	ld	s8,16(sp)
    80002684:	6ca2                	ld	s9,8(sp)
    80002686:	6125                	addi	sp,sp,96
    80002688:	8082                	ret

000000008000268a <sleep>:
// ADDED Q3
// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000268a:	7179                	addi	sp,sp,-48
    8000268c:	f406                	sd	ra,40(sp)
    8000268e:	f022                	sd	s0,32(sp)
    80002690:	ec26                	sd	s1,24(sp)
    80002692:	e84a                	sd	s2,16(sp)
    80002694:	e44e                	sd	s3,8(sp)
    80002696:	1800                	addi	s0,sp,48
    80002698:	89aa                	mv	s3,a0
    8000269a:	892e                	mv	s2,a1
  struct thread *t = mythread();
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	394080e7          	jalr	916(ra) # 80001a30 <mythread>
    800026a4:	84aa                	mv	s1,a0
  // Once we hold t->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks t->lock),
  // so it's okay to release lk.

  acquire(&t->lock);  //DOC: sleeplock1
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	51c080e7          	jalr	1308(ra) # 80000bc2 <acquire>
  release(lk);
    800026ae:	854a                	mv	a0,s2
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	5d8080e7          	jalr	1496(ra) # 80000c88 <release>

  // Go to sleep.
  t->chan = chan;
    800026b8:	0334b023          	sd	s3,32(s1)
  t->state = SLEEPING;
    800026bc:	4789                	li	a5,2
    800026be:	cc9c                	sw	a5,24(s1)

  sched();
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	d14080e7          	jalr	-748(ra) # 800023d4 <sched>

  // Tidy up.
  t->chan = 0;
    800026c8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&t->lock);
    800026cc:	8526                	mv	a0,s1
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	5ba080e7          	jalr	1466(ra) # 80000c88 <release>
  acquire(lk);
    800026d6:	854a                	mv	a0,s2
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	4ea080e7          	jalr	1258(ra) # 80000bc2 <acquire>
}
    800026e0:	70a2                	ld	ra,40(sp)
    800026e2:	7402                	ld	s0,32(sp)
    800026e4:	64e2                	ld	s1,24(sp)
    800026e6:	6942                	ld	s2,16(sp)
    800026e8:	69a2                	ld	s3,8(sp)
    800026ea:	6145                	addi	sp,sp,48
    800026ec:	8082                	ret

00000000800026ee <wait>:
{
    800026ee:	715d                	addi	sp,sp,-80
    800026f0:	e486                	sd	ra,72(sp)
    800026f2:	e0a2                	sd	s0,64(sp)
    800026f4:	fc26                	sd	s1,56(sp)
    800026f6:	f84a                	sd	s2,48(sp)
    800026f8:	f44e                	sd	s3,40(sp)
    800026fa:	f052                	sd	s4,32(sp)
    800026fc:	ec56                	sd	s5,24(sp)
    800026fe:	e85a                	sd	s6,16(sp)
    80002700:	e45e                	sd	s7,8(sp)
    80002702:	0880                	addi	s0,sp,80
    80002704:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	2f0080e7          	jalr	752(ra) # 800019f6 <myproc>
    8000270e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002710:	0000f517          	auipc	a0,0xf
    80002714:	ba850513          	addi	a0,a0,-1112 # 800112b8 <wait_lock>
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	4aa080e7          	jalr	1194(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    80002720:	4a89                	li	s5,2
        havekids = 1;
    80002722:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002724:	6985                	lui	s3,0x1
    80002726:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    8000272a:	00031a17          	auipc	s4,0x31
    8000272e:	fd6a0a13          	addi	s4,s4,-42 # 80033700 <tickslock>
    havekids = 0;
    80002732:	4701                	li	a4,0
    for(np = proc; np < &proc[NPROC]; np++){
    80002734:	0000f497          	auipc	s1,0xf
    80002738:	fcc48493          	addi	s1,s1,-52 # 80011700 <proc>
    8000273c:	a0b5                	j	800027a8 <wait+0xba>
          pid = np->pid;
    8000273e:	0244a983          	lw	s3,36(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002742:	000b8e63          	beqz	s7,8000275e <wait+0x70>
    80002746:	4691                	li	a3,4
    80002748:	02048613          	addi	a2,s1,32
    8000274c:	85de                	mv	a1,s7
    8000274e:	1d893503          	ld	a0,472(s2)
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	f10080e7          	jalr	-240(ra) # 80001662 <copyout>
    8000275a:	02054563          	bltz	a0,80002784 <wait+0x96>
          freeproc(np);
    8000275e:	8526                	mv	a0,s1
    80002760:	fffff097          	auipc	ra,0xfffff
    80002764:	5a6080e7          	jalr	1446(ra) # 80001d06 <freeproc>
          release(&np->lock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	51e080e7          	jalr	1310(ra) # 80000c88 <release>
          release(&wait_lock);
    80002772:	0000f517          	auipc	a0,0xf
    80002776:	b4650513          	addi	a0,a0,-1210 # 800112b8 <wait_lock>
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	50e080e7          	jalr	1294(ra) # 80000c88 <release>
          return pid;
    80002782:	a09d                	j	800027e8 <wait+0xfa>
            release(&np->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	502080e7          	jalr	1282(ra) # 80000c88 <release>
            release(&wait_lock);
    8000278e:	0000f517          	auipc	a0,0xf
    80002792:	b2a50513          	addi	a0,a0,-1238 # 800112b8 <wait_lock>
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	4f2080e7          	jalr	1266(ra) # 80000c88 <release>
            return -1;
    8000279e:	59fd                	li	s3,-1
    800027a0:	a0a1                	j	800027e8 <wait+0xfa>
    for(np = proc; np < &proc[NPROC]; np++){
    800027a2:	94ce                	add	s1,s1,s3
    800027a4:	03448563          	beq	s1,s4,800027ce <wait+0xe0>
      if(np->parent == p){
    800027a8:	1c84b783          	ld	a5,456(s1)
    800027ac:	ff279be3          	bne	a5,s2,800027a2 <wait+0xb4>
        acquire(&np->lock);
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	410080e7          	jalr	1040(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800027ba:	4c9c                	lw	a5,24(s1)
    800027bc:	f95781e3          	beq	a5,s5,8000273e <wait+0x50>
        release(&np->lock);
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	4c6080e7          	jalr	1222(ra) # 80000c88 <release>
        havekids = 1;
    800027ca:	875a                	mv	a4,s6
    800027cc:	bfd9                	j	800027a2 <wait+0xb4>
    if(!havekids || p->killed){
    800027ce:	c701                	beqz	a4,800027d6 <wait+0xe8>
    800027d0:	01c92783          	lw	a5,28(s2)
    800027d4:	c795                	beqz	a5,80002800 <wait+0x112>
      release(&wait_lock);
    800027d6:	0000f517          	auipc	a0,0xf
    800027da:	ae250513          	addi	a0,a0,-1310 # 800112b8 <wait_lock>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	4aa080e7          	jalr	1194(ra) # 80000c88 <release>
      return -1;
    800027e6:	59fd                	li	s3,-1
}
    800027e8:	854e                	mv	a0,s3
    800027ea:	60a6                	ld	ra,72(sp)
    800027ec:	6406                	ld	s0,64(sp)
    800027ee:	74e2                	ld	s1,56(sp)
    800027f0:	7942                	ld	s2,48(sp)
    800027f2:	79a2                	ld	s3,40(sp)
    800027f4:	7a02                	ld	s4,32(sp)
    800027f6:	6ae2                	ld	s5,24(sp)
    800027f8:	6b42                	ld	s6,16(sp)
    800027fa:	6ba2                	ld	s7,8(sp)
    800027fc:	6161                	addi	sp,sp,80
    800027fe:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002800:	0000f597          	auipc	a1,0xf
    80002804:	ab858593          	addi	a1,a1,-1352 # 800112b8 <wait_lock>
    80002808:	854a                	mv	a0,s2
    8000280a:	00000097          	auipc	ra,0x0
    8000280e:	e80080e7          	jalr	-384(ra) # 8000268a <sleep>
    havekids = 0;
    80002812:	b705                	j	80002732 <wait+0x44>

0000000080002814 <wakeup>:
// Wake up all threads sleeping on chan.
// Must be called without any p->lock.
// ADDED Q3
void
wakeup(void *chan)
{
    80002814:	715d                	addi	sp,sp,-80
    80002816:	e486                	sd	ra,72(sp)
    80002818:	e0a2                	sd	s0,64(sp)
    8000281a:	fc26                	sd	s1,56(sp)
    8000281c:	f84a                	sd	s2,48(sp)
    8000281e:	f44e                	sd	s3,40(sp)
    80002820:	f052                	sd	s4,32(sp)
    80002822:	ec56                	sd	s5,24(sp)
    80002824:	e85a                	sd	s6,16(sp)
    80002826:	e45e                	sd	s7,8(sp)
    80002828:	0880                	addi	s0,sp,80
    8000282a:	8a2a                	mv	s4,a0
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++) {
    8000282c:	0000f917          	auipc	s2,0xf
    80002830:	74c90913          	addi	s2,s2,1868 # 80011f78 <proc+0x878>
    80002834:	00031b17          	auipc	s6,0x31
    80002838:	744b0b13          	addi	s6,s6,1860 # 80033f78 <bcache+0x860>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
      if(t != mythread()){
        acquire(&t->lock);
        if (t->state == SLEEPING && t->chan == chan) {
    8000283c:	4989                	li	s3,2
          t->state = RUNNABLE;
    8000283e:	4b8d                	li	s7,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002840:	6a85                	lui	s5,0x1
    80002842:	880a8a93          	addi	s5,s5,-1920 # 880 <_entry-0x7ffff780>
    80002846:	a089                	j	80002888 <wakeup+0x74>
        }
        release(&t->lock);
    80002848:	8526                	mv	a0,s1
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	43e080e7          	jalr	1086(ra) # 80000c88 <release>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002852:	0c048493          	addi	s1,s1,192
    80002856:	03248663          	beq	s1,s2,80002882 <wakeup+0x6e>
      if(t != mythread()){
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	1d6080e7          	jalr	470(ra) # 80001a30 <mythread>
    80002862:	fea488e3          	beq	s1,a0,80002852 <wakeup+0x3e>
        acquire(&t->lock);
    80002866:	8526                	mv	a0,s1
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	35a080e7          	jalr	858(ra) # 80000bc2 <acquire>
        if (t->state == SLEEPING && t->chan == chan) {
    80002870:	4c9c                	lw	a5,24(s1)
    80002872:	fd379be3          	bne	a5,s3,80002848 <wakeup+0x34>
    80002876:	709c                	ld	a5,32(s1)
    80002878:	fd4798e3          	bne	a5,s4,80002848 <wakeup+0x34>
          t->state = RUNNABLE;
    8000287c:	0174ac23          	sw	s7,24(s1)
    80002880:	b7e1                	j	80002848 <wakeup+0x34>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002882:	9956                	add	s2,s2,s5
    80002884:	01690563          	beq	s2,s6,8000288e <wakeup+0x7a>
    for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002888:	a0090493          	addi	s1,s2,-1536
    8000288c:	b7f9                	j	8000285a <wakeup+0x46>
      }
    }
  }
}
    8000288e:	60a6                	ld	ra,72(sp)
    80002890:	6406                	ld	s0,64(sp)
    80002892:	74e2                	ld	s1,56(sp)
    80002894:	7942                	ld	s2,48(sp)
    80002896:	79a2                	ld	s3,40(sp)
    80002898:	7a02                	ld	s4,32(sp)
    8000289a:	6ae2                	ld	s5,24(sp)
    8000289c:	6b42                	ld	s6,16(sp)
    8000289e:	6ba2                	ld	s7,8(sp)
    800028a0:	6161                	addi	sp,sp,80
    800028a2:	8082                	ret

00000000800028a4 <reparent>:
{
    800028a4:	7139                	addi	sp,sp,-64
    800028a6:	fc06                	sd	ra,56(sp)
    800028a8:	f822                	sd	s0,48(sp)
    800028aa:	f426                	sd	s1,40(sp)
    800028ac:	f04a                	sd	s2,32(sp)
    800028ae:	ec4e                	sd	s3,24(sp)
    800028b0:	e852                	sd	s4,16(sp)
    800028b2:	e456                	sd	s5,8(sp)
    800028b4:	0080                	addi	s0,sp,64
    800028b6:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028b8:	0000f497          	auipc	s1,0xf
    800028bc:	e4848493          	addi	s1,s1,-440 # 80011700 <proc>
      pp->parent = initproc;
    800028c0:	00006a97          	auipc	s5,0x6
    800028c4:	768a8a93          	addi	s5,s5,1896 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028c8:	6905                	lui	s2,0x1
    800028ca:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    800028ce:	00031a17          	auipc	s4,0x31
    800028d2:	e32a0a13          	addi	s4,s4,-462 # 80033700 <tickslock>
    800028d6:	a021                	j	800028de <reparent+0x3a>
    800028d8:	94ca                	add	s1,s1,s2
    800028da:	01448f63          	beq	s1,s4,800028f8 <reparent+0x54>
    if(pp->parent == p){
    800028de:	1c84b783          	ld	a5,456(s1)
    800028e2:	ff379be3          	bne	a5,s3,800028d8 <reparent+0x34>
      pp->parent = initproc;
    800028e6:	000ab503          	ld	a0,0(s5)
    800028ea:	1ca4b423          	sd	a0,456(s1)
      wakeup(initproc);
    800028ee:	00000097          	auipc	ra,0x0
    800028f2:	f26080e7          	jalr	-218(ra) # 80002814 <wakeup>
    800028f6:	b7cd                	j	800028d8 <reparent+0x34>
}
    800028f8:	70e2                	ld	ra,56(sp)
    800028fa:	7442                	ld	s0,48(sp)
    800028fc:	74a2                	ld	s1,40(sp)
    800028fe:	7902                	ld	s2,32(sp)
    80002900:	69e2                	ld	s3,24(sp)
    80002902:	6a42                	ld	s4,16(sp)
    80002904:	6aa2                	ld	s5,8(sp)
    80002906:	6121                	addi	sp,sp,64
    80002908:	8082                	ret

000000008000290a <kill>:
// ADDED Q2.2.1
int
kill(int pid, int signum)
{
  struct proc *p;
  if (signum < 0 || signum >= SIG_NUM) {
    8000290a:	47fd                	li	a5,31
    8000290c:	06b7ef63          	bltu	a5,a1,8000298a <kill+0x80>
{
    80002910:	7139                	addi	sp,sp,-64
    80002912:	fc06                	sd	ra,56(sp)
    80002914:	f822                	sd	s0,48(sp)
    80002916:	f426                	sd	s1,40(sp)
    80002918:	f04a                	sd	s2,32(sp)
    8000291a:	ec4e                	sd	s3,24(sp)
    8000291c:	e852                	sd	s4,16(sp)
    8000291e:	e456                	sd	s5,8(sp)
    80002920:	0080                	addi	s0,sp,64
    80002922:	892a                	mv	s2,a0
    80002924:	8aae                	mv	s5,a1
    return -1;
  }
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002926:	0000f497          	auipc	s1,0xf
    8000292a:	dda48493          	addi	s1,s1,-550 # 80011700 <proc>
    8000292e:	6985                	lui	s3,0x1
    80002930:	88098993          	addi	s3,s3,-1920 # 880 <_entry-0x7ffff780>
    80002934:	00031a17          	auipc	s4,0x31
    80002938:	dcca0a13          	addi	s4,s4,-564 # 80033700 <tickslock>
    acquire(&p->lock);
    8000293c:	8526                	mv	a0,s1
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	284080e7          	jalr	644(ra) # 80000bc2 <acquire>
    if(p->pid == pid) {
    80002946:	50dc                	lw	a5,36(s1)
    80002948:	01278c63          	beq	a5,s2,80002960 <kill+0x56>
      p->pending_signals = p->pending_signals | (1 << signum);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000294c:	8526                	mv	a0,s1
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	33a080e7          	jalr	826(ra) # 80000c88 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002956:	94ce                	add	s1,s1,s3
    80002958:	ff4492e3          	bne	s1,s4,8000293c <kill+0x32>
  }
  // no such pid
  return -1;
    8000295c:	557d                	li	a0,-1
    8000295e:	a829                	j	80002978 <kill+0x6e>
      p->pending_signals = p->pending_signals | (1 << signum);
    80002960:	4785                	li	a5,1
    80002962:	0157973b          	sllw	a4,a5,s5
    80002966:	549c                	lw	a5,40(s1)
    80002968:	8fd9                	or	a5,a5,a4
    8000296a:	d49c                	sw	a5,40(s1)
      release(&p->lock);
    8000296c:	8526                	mv	a0,s1
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	31a080e7          	jalr	794(ra) # 80000c88 <release>
      return 0;
    80002976:	4501                	li	a0,0
}
    80002978:	70e2                	ld	ra,56(sp)
    8000297a:	7442                	ld	s0,48(sp)
    8000297c:	74a2                	ld	s1,40(sp)
    8000297e:	7902                	ld	s2,32(sp)
    80002980:	69e2                	ld	s3,24(sp)
    80002982:	6a42                	ld	s4,16(sp)
    80002984:	6aa2                	ld	s5,8(sp)
    80002986:	6121                	addi	sp,sp,64
    80002988:	8082                	ret
    return -1;
    8000298a:	557d                	li	a0,-1
}
    8000298c:	8082                	ret

000000008000298e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000298e:	7179                	addi	sp,sp,-48
    80002990:	f406                	sd	ra,40(sp)
    80002992:	f022                	sd	s0,32(sp)
    80002994:	ec26                	sd	s1,24(sp)
    80002996:	e84a                	sd	s2,16(sp)
    80002998:	e44e                	sd	s3,8(sp)
    8000299a:	e052                	sd	s4,0(sp)
    8000299c:	1800                	addi	s0,sp,48
    8000299e:	84aa                	mv	s1,a0
    800029a0:	892e                	mv	s2,a1
    800029a2:	89b2                	mv	s3,a2
    800029a4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	050080e7          	jalr	80(ra) # 800019f6 <myproc>
  if(user_dst){
    800029ae:	c095                	beqz	s1,800029d2 <either_copyout+0x44>
    return copyout(p->pagetable, dst, src, len);
    800029b0:	86d2                	mv	a3,s4
    800029b2:	864e                	mv	a2,s3
    800029b4:	85ca                	mv	a1,s2
    800029b6:	1d853503          	ld	a0,472(a0)
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	ca8080e7          	jalr	-856(ra) # 80001662 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029c2:	70a2                	ld	ra,40(sp)
    800029c4:	7402                	ld	s0,32(sp)
    800029c6:	64e2                	ld	s1,24(sp)
    800029c8:	6942                	ld	s2,16(sp)
    800029ca:	69a2                	ld	s3,8(sp)
    800029cc:	6a02                	ld	s4,0(sp)
    800029ce:	6145                	addi	sp,sp,48
    800029d0:	8082                	ret
    memmove((char *)dst, src, len);
    800029d2:	000a061b          	sext.w	a2,s4
    800029d6:	85ce                	mv	a1,s3
    800029d8:	854a                	mv	a0,s2
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	364080e7          	jalr	868(ra) # 80000d3e <memmove>
    return 0;
    800029e2:	8526                	mv	a0,s1
    800029e4:	bff9                	j	800029c2 <either_copyout+0x34>

00000000800029e6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029e6:	7179                	addi	sp,sp,-48
    800029e8:	f406                	sd	ra,40(sp)
    800029ea:	f022                	sd	s0,32(sp)
    800029ec:	ec26                	sd	s1,24(sp)
    800029ee:	e84a                	sd	s2,16(sp)
    800029f0:	e44e                	sd	s3,8(sp)
    800029f2:	e052                	sd	s4,0(sp)
    800029f4:	1800                	addi	s0,sp,48
    800029f6:	892a                	mv	s2,a0
    800029f8:	84ae                	mv	s1,a1
    800029fa:	89b2                	mv	s3,a2
    800029fc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029fe:	fffff097          	auipc	ra,0xfffff
    80002a02:	ff8080e7          	jalr	-8(ra) # 800019f6 <myproc>
  if(user_src){
    80002a06:	c095                	beqz	s1,80002a2a <either_copyin+0x44>
    return copyin(p->pagetable, dst, src, len);
    80002a08:	86d2                	mv	a3,s4
    80002a0a:	864e                	mv	a2,s3
    80002a0c:	85ca                	mv	a1,s2
    80002a0e:	1d853503          	ld	a0,472(a0)
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	cdc080e7          	jalr	-804(ra) # 800016ee <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a1a:	70a2                	ld	ra,40(sp)
    80002a1c:	7402                	ld	s0,32(sp)
    80002a1e:	64e2                	ld	s1,24(sp)
    80002a20:	6942                	ld	s2,16(sp)
    80002a22:	69a2                	ld	s3,8(sp)
    80002a24:	6a02                	ld	s4,0(sp)
    80002a26:	6145                	addi	sp,sp,48
    80002a28:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a2a:	000a061b          	sext.w	a2,s4
    80002a2e:	85ce                	mv	a1,s3
    80002a30:	854a                	mv	a0,s2
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	30c080e7          	jalr	780(ra) # 80000d3e <memmove>
    return 0;
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	bff9                	j	80002a1a <either_copyin+0x34>

0000000080002a3e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a3e:	715d                	addi	sp,sp,-80
    80002a40:	e486                	sd	ra,72(sp)
    80002a42:	e0a2                	sd	s0,64(sp)
    80002a44:	fc26                	sd	s1,56(sp)
    80002a46:	f84a                	sd	s2,48(sp)
    80002a48:	f44e                	sd	s3,40(sp)
    80002a4a:	f052                	sd	s4,32(sp)
    80002a4c:	ec56                	sd	s5,24(sp)
    80002a4e:	e85a                	sd	s6,16(sp)
    80002a50:	e45e                	sd	s7,8(sp)
    80002a52:	e062                	sd	s8,0(sp)
    80002a54:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a56:	00006517          	auipc	a0,0x6
    80002a5a:	80250513          	addi	a0,a0,-2046 # 80008258 <digits+0x218>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	b16080e7          	jalr	-1258(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a66:	0000f497          	auipc	s1,0xf
    80002a6a:	f0248493          	addi	s1,s1,-254 # 80011968 <proc+0x268>
    80002a6e:	00031997          	auipc	s3,0x31
    80002a72:	efa98993          	addi	s3,s3,-262 # 80033968 <bcache+0x250>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a76:	4b89                	li	s7,2
      state = states[p->state];
    else
      state = "???";
    80002a78:	00006a17          	auipc	s4,0x6
    80002a7c:	820a0a13          	addi	s4,s4,-2016 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    80002a80:	00006b17          	auipc	s6,0x6
    80002a84:	820b0b13          	addi	s6,s6,-2016 # 800082a0 <digits+0x260>
    printf("\n");
    80002a88:	00005a97          	auipc	s5,0x5
    80002a8c:	7d0a8a93          	addi	s5,s5,2000 # 80008258 <digits+0x218>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a90:	00006c17          	auipc	s8,0x6
    80002a94:	850c0c13          	addi	s8,s8,-1968 # 800082e0 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a98:	6905                	lui	s2,0x1
    80002a9a:	88090913          	addi	s2,s2,-1920 # 880 <_entry-0x7ffff780>
    80002a9e:	a005                	j	80002abe <procdump+0x80>
    printf("%d %s %s", p->pid, state, p->name);
    80002aa0:	dbc6a583          	lw	a1,-580(a3)
    80002aa4:	855a                	mv	a0,s6
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	ace080e7          	jalr	-1330(ra) # 80000574 <printf>
    printf("\n");
    80002aae:	8556                	mv	a0,s5
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	ac4080e7          	jalr	-1340(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ab8:	94ca                	add	s1,s1,s2
    80002aba:	03348263          	beq	s1,s3,80002ade <procdump+0xa0>
    if(p->state == UNUSED)
    80002abe:	86a6                	mv	a3,s1
    80002ac0:	db04a783          	lw	a5,-592(s1)
    80002ac4:	dbf5                	beqz	a5,80002ab8 <procdump+0x7a>
      state = "???";
    80002ac6:	8652                	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ac8:	fcfbece3          	bltu	s7,a5,80002aa0 <procdump+0x62>
    80002acc:	02079713          	slli	a4,a5,0x20
    80002ad0:	01d75793          	srli	a5,a4,0x1d
    80002ad4:	97e2                	add	a5,a5,s8
    80002ad6:	6390                	ld	a2,0(a5)
    80002ad8:	f661                	bnez	a2,80002aa0 <procdump+0x62>
      state = "???";
    80002ada:	8652                	mv	a2,s4
    80002adc:	b7d1                	j	80002aa0 <procdump+0x62>
  }
}
    80002ade:	60a6                	ld	ra,72(sp)
    80002ae0:	6406                	ld	s0,64(sp)
    80002ae2:	74e2                	ld	s1,56(sp)
    80002ae4:	7942                	ld	s2,48(sp)
    80002ae6:	79a2                	ld	s3,40(sp)
    80002ae8:	7a02                	ld	s4,32(sp)
    80002aea:	6ae2                	ld	s5,24(sp)
    80002aec:	6b42                	ld	s6,16(sp)
    80002aee:	6ba2                	ld	s7,8(sp)
    80002af0:	6c02                	ld	s8,0(sp)
    80002af2:	6161                	addi	sp,sp,80
    80002af4:	8082                	ret

0000000080002af6 <sigprocmask>:

// ADDED Q2.1.3
uint
sigprocmask(uint sigmask)
{
    80002af6:	7179                	addi	sp,sp,-48
    80002af8:	f406                	sd	ra,40(sp)
    80002afa:	f022                	sd	s0,32(sp)
    80002afc:	ec26                	sd	s1,24(sp)
    80002afe:	e84a                	sd	s2,16(sp)
    80002b00:	e44e                	sd	s3,8(sp)
    80002b02:	1800                	addi	s0,sp,48
    80002b04:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	ef0080e7          	jalr	-272(ra) # 800019f6 <myproc>
    80002b0e:	84aa                	mv	s1,a0
  uint old_mask = p->signal_mask;
    80002b10:	02c52983          	lw	s3,44(a0)
  acquire(&p->lock);
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	0ae080e7          	jalr	174(ra) # 80000bc2 <acquire>

  //SIGKILL and SIGSTOP cannot be blocked
  if( ((sigmask & (1 << SIGKILL)) != 0) || ((sigmask & (1 << SIGSTOP)) != 0) ){
    80002b1c:	000207b7          	lui	a5,0x20
    80002b20:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    80002b24:	00f977b3          	and	a5,s2,a5
    80002b28:	e385                	bnez	a5,80002b48 <sigprocmask+0x52>
    release(&p->lock);
    return -1;
  }

  p->signal_mask = sigmask;
    80002b2a:	0324a623          	sw	s2,44(s1)
  release(&p->lock);
    80002b2e:	8526                	mv	a0,s1
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	158080e7          	jalr	344(ra) # 80000c88 <release>
  return old_mask;
}
    80002b38:	854e                	mv	a0,s3
    80002b3a:	70a2                	ld	ra,40(sp)
    80002b3c:	7402                	ld	s0,32(sp)
    80002b3e:	64e2                	ld	s1,24(sp)
    80002b40:	6942                	ld	s2,16(sp)
    80002b42:	69a2                	ld	s3,8(sp)
    80002b44:	6145                	addi	sp,sp,48
    80002b46:	8082                	ret
    release(&p->lock);
    80002b48:	8526                	mv	a0,s1
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	13e080e7          	jalr	318(ra) # 80000c88 <release>
    return -1;
    80002b52:	59fd                	li	s3,-1
    80002b54:	b7d5                	j	80002b38 <sigprocmask+0x42>

0000000080002b56 <sigaction>:

// ADDED Q2.1.4
int
sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
{
    80002b56:	715d                	addi	sp,sp,-80
    80002b58:	e486                	sd	ra,72(sp)
    80002b5a:	e0a2                	sd	s0,64(sp)
    80002b5c:	fc26                	sd	s1,56(sp)
    80002b5e:	f84a                	sd	s2,48(sp)
    80002b60:	f44e                	sd	s3,40(sp)
    80002b62:	f052                	sd	s4,32(sp)
    80002b64:	0880                	addi	s0,sp,80
    80002b66:	84aa                	mv	s1,a0
    80002b68:	89ae                	mv	s3,a1
    80002b6a:	8a32                	mv	s4,a2
  struct proc *p = myproc();
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	e8a080e7          	jalr	-374(ra) # 800019f6 <myproc>
  struct sigaction kernel_act;
  struct sigaction kernel_oldact;

  //SIGKILL and SIGSTOP cannot be modified
  if (signum < 0 || signum >= SIG_NUM || signum ==SIGKILL || signum ==SIGSTOP) {
    80002b74:	0004879b          	sext.w	a5,s1
    80002b78:	477d                	li	a4,31
    80002b7a:	0cf76763          	bltu	a4,a5,80002c48 <sigaction+0xf2>
    80002b7e:	892a                	mv	s2,a0
    80002b80:	37dd                	addiw	a5,a5,-9
    80002b82:	9bdd                	andi	a5,a5,-9
    80002b84:	2781                	sext.w	a5,a5
    80002b86:	c3f9                	beqz	a5,80002c4c <sigaction+0xf6>
    return -1;
  }

  acquire(&p->lock);
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	03a080e7          	jalr	58(ra) # 80000bc2 <acquire>

  if(act && copyin(p->pagetable, (char*)&kernel_act, (uint64)act, sizeof(struct sigaction)) < 0){
    80002b90:	0c098063          	beqz	s3,80002c50 <sigaction+0xfa>
    80002b94:	46c1                	li	a3,16
    80002b96:	864e                	mv	a2,s3
    80002b98:	fc040593          	addi	a1,s0,-64
    80002b9c:	1d893503          	ld	a0,472(s2)
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	b4e080e7          	jalr	-1202(ra) # 800016ee <copyin>
    80002ba8:	08054263          	bltz	a0,80002c2c <sigaction+0xd6>
    release(&p->lock);
    return -1;
  }
  //SIGKILL and SIGSTOP cannot be ignored
  if(act && ( ((kernel_act.sigmask & (1 << SIGKILL)) != 0) || ((kernel_act.sigmask & (1 << SIGSTOP)) != 0)) ) {
    80002bac:	fc843783          	ld	a5,-56(s0)
    80002bb0:	00020737          	lui	a4,0x20
    80002bb4:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    80002bb8:	8ff9                	and	a5,a5,a4
    80002bba:	e3c1                	bnez	a5,80002c3a <sigaction+0xe4>
    return -1;
  }

  

  if (oldact) {
    80002bbc:	020a0c63          	beqz	s4,80002bf4 <sigaction+0x9e>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002bc0:	00648793          	addi	a5,s1,6
    80002bc4:	078e                	slli	a5,a5,0x3
    80002bc6:	97ca                	add	a5,a5,s2
    80002bc8:	679c                	ld	a5,8(a5)
    80002bca:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002bce:	04c48793          	addi	a5,s1,76
    80002bd2:	078a                	slli	a5,a5,0x2
    80002bd4:	97ca                	add	a5,a5,s2
    80002bd6:	479c                	lw	a5,8(a5)
    80002bd8:	faf42c23          	sw	a5,-72(s0)

    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002bdc:	46c1                	li	a3,16
    80002bde:	fb040613          	addi	a2,s0,-80
    80002be2:	85d2                	mv	a1,s4
    80002be4:	1d893503          	ld	a0,472(s2)
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	a7a080e7          	jalr	-1414(ra) # 80001662 <copyout>
    80002bf0:	08054c63          	bltz	a0,80002c88 <sigaction+0x132>
      return -1;
    }
  }

  if (act) {
    p->signal_handlers[signum] = kernel_act.sa_handler;
    80002bf4:	00648793          	addi	a5,s1,6
    80002bf8:	078e                	slli	a5,a5,0x3
    80002bfa:	97ca                	add	a5,a5,s2
    80002bfc:	fc043703          	ld	a4,-64(s0)
    80002c00:	e798                	sd	a4,8(a5)
    p->signal_handlers_masks[signum] = kernel_act.sigmask;
    80002c02:	04c48493          	addi	s1,s1,76
    80002c06:	048a                	slli	s1,s1,0x2
    80002c08:	94ca                	add	s1,s1,s2
    80002c0a:	fc842783          	lw	a5,-56(s0)
    80002c0e:	c49c                	sw	a5,8(s1)
  }

  release(&p->lock);
    80002c10:	854a                	mv	a0,s2
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	076080e7          	jalr	118(ra) # 80000c88 <release>
  return 0;
    80002c1a:	4501                	li	a0,0
}
    80002c1c:	60a6                	ld	ra,72(sp)
    80002c1e:	6406                	ld	s0,64(sp)
    80002c20:	74e2                	ld	s1,56(sp)
    80002c22:	7942                	ld	s2,48(sp)
    80002c24:	79a2                	ld	s3,40(sp)
    80002c26:	7a02                	ld	s4,32(sp)
    80002c28:	6161                	addi	sp,sp,80
    80002c2a:	8082                	ret
    release(&p->lock);
    80002c2c:	854a                	mv	a0,s2
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	05a080e7          	jalr	90(ra) # 80000c88 <release>
    return -1;
    80002c36:	557d                	li	a0,-1
    80002c38:	b7d5                	j	80002c1c <sigaction+0xc6>
    release(&p->lock);
    80002c3a:	854a                	mv	a0,s2
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	04c080e7          	jalr	76(ra) # 80000c88 <release>
    return -1;
    80002c44:	557d                	li	a0,-1
    80002c46:	bfd9                	j	80002c1c <sigaction+0xc6>
    return -1;
    80002c48:	557d                	li	a0,-1
    80002c4a:	bfc9                	j	80002c1c <sigaction+0xc6>
    80002c4c:	557d                	li	a0,-1
    80002c4e:	b7f9                	j	80002c1c <sigaction+0xc6>
  if (oldact) {
    80002c50:	fc0a00e3          	beqz	s4,80002c10 <sigaction+0xba>
    kernel_oldact.sa_handler = p->signal_handlers[signum];
    80002c54:	00648793          	addi	a5,s1,6
    80002c58:	078e                	slli	a5,a5,0x3
    80002c5a:	97ca                	add	a5,a5,s2
    80002c5c:	679c                	ld	a5,8(a5)
    80002c5e:	faf43823          	sd	a5,-80(s0)
    kernel_oldact.sigmask = p->signal_handlers_masks[signum];
    80002c62:	04c48493          	addi	s1,s1,76
    80002c66:	048a                	slli	s1,s1,0x2
    80002c68:	94ca                	add	s1,s1,s2
    80002c6a:	449c                	lw	a5,8(s1)
    80002c6c:	faf42c23          	sw	a5,-72(s0)
    if(copyout(p->pagetable, (uint64)oldact, (char*)&kernel_oldact, sizeof(struct sigaction)) < 0){
    80002c70:	46c1                	li	a3,16
    80002c72:	fb040613          	addi	a2,s0,-80
    80002c76:	85d2                	mv	a1,s4
    80002c78:	1d893503          	ld	a0,472(s2)
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	9e6080e7          	jalr	-1562(ra) # 80001662 <copyout>
    80002c84:	f80556e3          	bgez	a0,80002c10 <sigaction+0xba>
      release(&p->lock);
    80002c88:	854a                	mv	a0,s2
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	ffe080e7          	jalr	-2(ra) # 80000c88 <release>
      return -1;
    80002c92:	557d                	li	a0,-1
    80002c94:	b761                	j	80002c1c <sigaction+0xc6>

0000000080002c96 <sigret>:

// ADDED Q2.1.5
// ADDED Q3
void
sigret(void)
{
    80002c96:	1101                	addi	sp,sp,-32
    80002c98:	ec06                	sd	ra,24(sp)
    80002c9a:	e822                	sd	s0,16(sp)
    80002c9c:	e426                	sd	s1,8(sp)
    80002c9e:	e04a                	sd	s2,0(sp)
    80002ca0:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	d8e080e7          	jalr	-626(ra) # 80001a30 <mythread>
    80002caa:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	d4a080e7          	jalr	-694(ra) # 800019f6 <myproc>
    80002cb4:	84aa                	mv	s1,a0

  acquire(&p->lock);
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	f0c080e7          	jalr	-244(ra) # 80000bc2 <acquire>
  acquire(&t->lock);
    80002cbe:	854a                	mv	a0,s2
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	f02080e7          	jalr	-254(ra) # 80000bc2 <acquire>
  memmove(t->trapframe, p->trapframe_backup, sizeof(struct trapframe));
    80002cc8:	12000613          	li	a2,288
    80002ccc:	1b84b583          	ld	a1,440(s1)
    80002cd0:	04893503          	ld	a0,72(s2)
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	06a080e7          	jalr	106(ra) # 80000d3e <memmove>
  p->signal_mask = p->signal_mask_backup;
    80002cdc:	589c                	lw	a5,48(s1)
    80002cde:	d4dc                	sw	a5,44(s1)
  p->handling_user_level_signal = 0;
    80002ce0:	1c04a223          	sw	zero,452(s1)
  release(&t->lock);
    80002ce4:	854a                	mv	a0,s2
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	fa2080e7          	jalr	-94(ra) # 80000c88 <release>
  release(&p->lock);
    80002cee:	8526                	mv	a0,s1
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	f98080e7          	jalr	-104(ra) # 80000c88 <release>
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6902                	ld	s2,0(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret

0000000080002d04 <kthread_create>:

int
kthread_create(void (*start_func)(), void* stack)
{
    80002d04:	7179                	addi	sp,sp,-48
    80002d06:	f406                	sd	ra,40(sp)
    80002d08:	f022                	sd	s0,32(sp)
    80002d0a:	ec26                	sd	s1,24(sp)
    80002d0c:	e84a                	sd	s2,16(sp)
    80002d0e:	e44e                	sd	s3,8(sp)
    80002d10:	e052                	sd	s4,0(sp)
    80002d12:	1800                	addi	s0,sp,48
    80002d14:	89aa                	mv	s3,a0
    80002d16:	892e                	mv	s2,a1
    struct thread* t = mythread();
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	d18080e7          	jalr	-744(ra) # 80001a30 <mythread>
    80002d20:	8a2a                	mv	s4,a0
    struct thread* nt;

    if((nt = allocthread(myproc())) == 0) {
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	cd4080e7          	jalr	-812(ra) # 800019f6 <myproc>
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	e10080e7          	jalr	-496(ra) # 80001b3a <allocthread>
    80002d32:	c135                	beqz	a0,80002d96 <kthread_create+0x92>
    80002d34:	84aa                	mv	s1,a0
        return -1;
    }
    *nt->trapframe = *t->trapframe;
    80002d36:	048a3683          	ld	a3,72(s4)
    80002d3a:	87b6                	mv	a5,a3
    80002d3c:	6538                	ld	a4,72(a0)
    80002d3e:	12068693          	addi	a3,a3,288
    80002d42:	0007b803          	ld	a6,0(a5)
    80002d46:	6788                	ld	a0,8(a5)
    80002d48:	6b8c                	ld	a1,16(a5)
    80002d4a:	6f90                	ld	a2,24(a5)
    80002d4c:	01073023          	sd	a6,0(a4)
    80002d50:	e708                	sd	a0,8(a4)
    80002d52:	eb0c                	sd	a1,16(a4)
    80002d54:	ef10                	sd	a2,24(a4)
    80002d56:	02078793          	addi	a5,a5,32
    80002d5a:	02070713          	addi	a4,a4,32
    80002d5e:	fed792e3          	bne	a5,a3,80002d42 <kthread_create+0x3e>
    // *nt->context = *t->context; // TODO: check
    nt->trapframe->epc = (uint64)start_func;
    80002d62:	64bc                	ld	a5,72(s1)
    80002d64:	0137bc23          	sd	s3,24(a5)
    nt->trapframe->sp = (uint64)(stack + MAX_STACK_SIZE);
    80002d68:	64bc                	ld	a5,72(s1)
    80002d6a:	6585                	lui	a1,0x1
    80002d6c:	fa058593          	addi	a1,a1,-96 # fa0 <_entry-0x7ffff060>
    80002d70:	992e                	add	s2,s2,a1
    80002d72:	0327b823          	sd	s2,48(a5)
    nt->state = RUNNABLE;
    80002d76:	478d                	li	a5,3
    80002d78:	cc9c                	sw	a5,24(s1)

    release(&nt->lock);
    80002d7a:	8526                	mv	a0,s1
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	f0c080e7          	jalr	-244(ra) # 80000c88 <release>
    return nt->tid;
    80002d84:	5888                	lw	a0,48(s1)
}
    80002d86:	70a2                	ld	ra,40(sp)
    80002d88:	7402                	ld	s0,32(sp)
    80002d8a:	64e2                	ld	s1,24(sp)
    80002d8c:	6942                	ld	s2,16(sp)
    80002d8e:	69a2                	ld	s3,8(sp)
    80002d90:	6a02                	ld	s4,0(sp)
    80002d92:	6145                	addi	sp,sp,48
    80002d94:	8082                	ret
        return -1;
    80002d96:	557d                	li	a0,-1
    80002d98:	b7fd                	j	80002d86 <kthread_create+0x82>

0000000080002d9a <exit_single_thread>:

void
exit_single_thread(int status) {
    80002d9a:	7179                	addi	sp,sp,-48
    80002d9c:	f406                	sd	ra,40(sp)
    80002d9e:	f022                	sd	s0,32(sp)
    80002da0:	ec26                	sd	s1,24(sp)
    80002da2:	e84a                	sd	s2,16(sp)
    80002da4:	e44e                	sd	s3,8(sp)
    80002da6:	1800                	addi	s0,sp,48
    80002da8:	89aa                	mv	s3,a0
  struct thread *t = mythread();
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	c86080e7          	jalr	-890(ra) # 80001a30 <mythread>
    80002db2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	c42080e7          	jalr	-958(ra) # 800019f6 <myproc>
    80002dbc:	892a                	mv	s2,a0

  acquire(&t->lock);
    80002dbe:	8526                	mv	a0,s1
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	e02080e7          	jalr	-510(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80002dc8:	0334a623          	sw	s3,44(s1)
  t->state = ZOMBIE_T;
    80002dcc:	4795                	li	a5,5
    80002dce:	cc9c                	sw	a5,24(s1)

  release(&p->lock);
    80002dd0:	854a                	mv	a0,s2
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	eb6080e7          	jalr	-330(ra) # 80000c88 <release>
  wakeup(t);
    80002dda:	8526                	mv	a0,s1
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	a38080e7          	jalr	-1480(ra) # 80002814 <wakeup>
  // Jump into the scheduler, never to return.
  sched();
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	5f0080e7          	jalr	1520(ra) # 800023d4 <sched>
  panic("zombie exit");
    80002dec:	00005517          	auipc	a0,0x5
    80002df0:	4c450513          	addi	a0,a0,1220 # 800082b0 <digits+0x270>
    80002df4:	ffffd097          	auipc	ra,0xffffd
    80002df8:	736080e7          	jalr	1846(ra) # 8000052a <panic>

0000000080002dfc <kthread_join>:
  exit_single_thread(status);
}

int
kthread_join(int thread_id, int *status)
{
    80002dfc:	7139                	addi	sp,sp,-64
    80002dfe:	fc06                	sd	ra,56(sp)
    80002e00:	f822                	sd	s0,48(sp)
    80002e02:	f426                	sd	s1,40(sp)
    80002e04:	f04a                	sd	s2,32(sp)
    80002e06:	ec4e                	sd	s3,24(sp)
    80002e08:	e852                	sd	s4,16(sp)
    80002e0a:	e456                	sd	s5,8(sp)
    80002e0c:	e05a                	sd	s6,0(sp)
    80002e0e:	0080                	addi	s0,sp,64
    80002e10:	84aa                	mv	s1,a0
    80002e12:	8a2e                	mv	s4,a1
  struct thread *jt  = 0;
  struct proc *p = myproc();  
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	be2080e7          	jalr	-1054(ra) # 800019f6 <myproc>
    80002e1c:	89aa                	mv	s3,a0

  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002e1e:	27850793          	addi	a5,a0,632
    80002e22:	6685                	lui	a3,0x1
    80002e24:	87868693          	addi	a3,a3,-1928 # 878 <_entry-0x7ffff788>
    80002e28:	96aa                	add	a3,a3,a0
  struct thread *jt  = 0;
    80002e2a:	4901                	li	s2,0
    80002e2c:	a029                	j	80002e36 <kthread_join+0x3a>
  for (struct thread *temp_t = p->threads; temp_t < &p->threads[NTHREAD]; temp_t++) {
    80002e2e:	0c078793          	addi	a5,a5,192
    80002e32:	00d78763          	beq	a5,a3,80002e40 <kthread_join+0x44>
    if (thread_id == temp_t->tid) {
    80002e36:	5b98                	lw	a4,48(a5)
    80002e38:	fe971be3          	bne	a4,s1,80002e2e <kthread_join+0x32>
    80002e3c:	893e                	mv	s2,a5
    80002e3e:	bfc5                	j	80002e2e <kthread_join+0x32>
      jt = temp_t;
    }
  }  

  if (jt == 0) {
    80002e40:	0a090f63          	beqz	s2,80002efe <kthread_join+0x102>
    return -1;
  }

  acquire(&join_lock);
    80002e44:	0000f517          	auipc	a0,0xf
    80002e48:	8a450513          	addi	a0,a0,-1884 # 800116e8 <join_lock>
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	d76080e7          	jalr	-650(ra) # 80000bc2 <acquire>

  // TODO: deadlock?
  while (1) {
    acquire(&jt->lock);
    80002e54:	84ca                	mv	s1,s2
    if (jt->state == ZOMBIE_T) {
    80002e56:	4a95                	li	s5,5
      break;
    }
    release(&jt->lock);
    sleep(jt, &join_lock);
    80002e58:	0000fb17          	auipc	s6,0xf
    80002e5c:	890b0b13          	addi	s6,s6,-1904 # 800116e8 <join_lock>
    80002e60:	a821                	j	80002e78 <kthread_join+0x7c>
    release(&jt->lock);
    80002e62:	8526                	mv	a0,s1
    80002e64:	ffffe097          	auipc	ra,0xffffe
    80002e68:	e24080e7          	jalr	-476(ra) # 80000c88 <release>
    sleep(jt, &join_lock);
    80002e6c:	85da                	mv	a1,s6
    80002e6e:	8526                	mv	a0,s1
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	81a080e7          	jalr	-2022(ra) # 8000268a <sleep>
    acquire(&jt->lock);
    80002e78:	8526                	mv	a0,s1
    80002e7a:	ffffe097          	auipc	ra,0xffffe
    80002e7e:	d48080e7          	jalr	-696(ra) # 80000bc2 <acquire>
    if (jt->state == ZOMBIE_T) {
    80002e82:	01892783          	lw	a5,24(s2)
    80002e86:	fd579ee3          	bne	a5,s5,80002e62 <kthread_join+0x66>
  }

  if(status != 0 && copyout(p->pagetable, (uint64)status, (char *)&jt->xstate, sizeof(jt->xstate)) < 0) {
    80002e8a:	000a0e63          	beqz	s4,80002ea6 <kthread_join+0xaa>
    80002e8e:	4691                	li	a3,4
    80002e90:	02c90613          	addi	a2,s2,44
    80002e94:	85d2                	mv	a1,s4
    80002e96:	1d89b503          	ld	a0,472(s3)
    80002e9a:	ffffe097          	auipc	ra,0xffffe
    80002e9e:	7c8080e7          	jalr	1992(ra) # 80001662 <copyout>
    80002ea2:	02054f63          	bltz	a0,80002ee0 <kthread_join+0xe4>
    release(&jt->lock);
    release(&join_lock);
    return -1;
  }

  freethread(jt);
    80002ea6:	854a                	mv	a0,s2
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	988080e7          	jalr	-1656(ra) # 80001830 <freethread>
  release(&jt->lock);
    80002eb0:	8526                	mv	a0,s1
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	dd6080e7          	jalr	-554(ra) # 80000c88 <release>
  release(&join_lock);
    80002eba:	0000f517          	auipc	a0,0xf
    80002ebe:	82e50513          	addi	a0,a0,-2002 # 800116e8 <join_lock>
    80002ec2:	ffffe097          	auipc	ra,0xffffe
    80002ec6:	dc6080e7          	jalr	-570(ra) # 80000c88 <release>
  return 0;
    80002eca:	4501                	li	a0,0
}
    80002ecc:	70e2                	ld	ra,56(sp)
    80002ece:	7442                	ld	s0,48(sp)
    80002ed0:	74a2                	ld	s1,40(sp)
    80002ed2:	7902                	ld	s2,32(sp)
    80002ed4:	69e2                	ld	s3,24(sp)
    80002ed6:	6a42                	ld	s4,16(sp)
    80002ed8:	6aa2                	ld	s5,8(sp)
    80002eda:	6b02                	ld	s6,0(sp)
    80002edc:	6121                	addi	sp,sp,64
    80002ede:	8082                	ret
    release(&jt->lock);
    80002ee0:	8526                	mv	a0,s1
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	da6080e7          	jalr	-602(ra) # 80000c88 <release>
    release(&join_lock);
    80002eea:	0000e517          	auipc	a0,0xe
    80002eee:	7fe50513          	addi	a0,a0,2046 # 800116e8 <join_lock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	d96080e7          	jalr	-618(ra) # 80000c88 <release>
    return -1;
    80002efa:	557d                	li	a0,-1
    80002efc:	bfc1                	j	80002ecc <kthread_join+0xd0>
    return -1;
    80002efe:	557d                	li	a0,-1
    80002f00:	b7f1                	j	80002ecc <kthread_join+0xd0>

0000000080002f02 <exit>:
{
    80002f02:	715d                	addi	sp,sp,-80
    80002f04:	e486                	sd	ra,72(sp)
    80002f06:	e0a2                	sd	s0,64(sp)
    80002f08:	fc26                	sd	s1,56(sp)
    80002f0a:	f84a                	sd	s2,48(sp)
    80002f0c:	f44e                	sd	s3,40(sp)
    80002f0e:	f052                	sd	s4,32(sp)
    80002f10:	ec56                	sd	s5,24(sp)
    80002f12:	e85a                	sd	s6,16(sp)
    80002f14:	e45e                	sd	s7,8(sp)
    80002f16:	e062                	sd	s8,0(sp)
    80002f18:	0880                	addi	s0,sp,80
    80002f1a:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	ada080e7          	jalr	-1318(ra) # 800019f6 <myproc>
    80002f24:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f26:	00006797          	auipc	a5,0x6
    80002f2a:	1027b783          	ld	a5,258(a5) # 80009028 <initproc>
    80002f2e:	1e050493          	addi	s1,a0,480
    80002f32:	26050913          	addi	s2,a0,608
    80002f36:	02a79363          	bne	a5,a0,80002f5c <exit+0x5a>
    panic("init exiting");
    80002f3a:	00005517          	auipc	a0,0x5
    80002f3e:	38650513          	addi	a0,a0,902 # 800082c0 <digits+0x280>
    80002f42:	ffffd097          	auipc	ra,0xffffd
    80002f46:	5e8080e7          	jalr	1512(ra) # 8000052a <panic>
      fileclose(f);
    80002f4a:	00002097          	auipc	ra,0x2
    80002f4e:	2ca080e7          	jalr	714(ra) # 80005214 <fileclose>
      p->ofile[fd] = 0;
    80002f52:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002f56:	04a1                	addi	s1,s1,8
    80002f58:	01248563          	beq	s1,s2,80002f62 <exit+0x60>
    if(p->ofile[fd]){
    80002f5c:	6088                	ld	a0,0(s1)
    80002f5e:	f575                	bnez	a0,80002f4a <exit+0x48>
    80002f60:	bfdd                	j	80002f56 <exit+0x54>
  begin_op();
    80002f62:	00002097          	auipc	ra,0x2
    80002f66:	de6080e7          	jalr	-538(ra) # 80004d48 <begin_op>
  iput(p->cwd);
    80002f6a:	2609b503          	ld	a0,608(s3)
    80002f6e:	00001097          	auipc	ra,0x1
    80002f72:	5be080e7          	jalr	1470(ra) # 8000452c <iput>
  end_op();
    80002f76:	00002097          	auipc	ra,0x2
    80002f7a:	e52080e7          	jalr	-430(ra) # 80004dc8 <end_op>
  p->cwd = 0;
    80002f7e:	2609b023          	sd	zero,608(s3)
  acquire(&wait_lock);
    80002f82:	0000e517          	auipc	a0,0xe
    80002f86:	33650513          	addi	a0,a0,822 # 800112b8 <wait_lock>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	c38080e7          	jalr	-968(ra) # 80000bc2 <acquire>
  reparent(p);
    80002f92:	854e                	mv	a0,s3
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	910080e7          	jalr	-1776(ra) # 800028a4 <reparent>
  wakeup(p->parent);
    80002f9c:	1c89b503          	ld	a0,456(s3)
    80002fa0:	00000097          	auipc	ra,0x0
    80002fa4:	874080e7          	jalr	-1932(ra) # 80002814 <wakeup>
  acquire(&p->lock);
    80002fa8:	854e                	mv	a0,s3
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	c18080e7          	jalr	-1000(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002fb2:	0359a023          	sw	s5,32(s3)
  p->state = ZOMBIE;
    80002fb6:	4789                	li	a5,2
    80002fb8:	00f9ac23          	sw	a5,24(s3)
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002fbc:	27898493          	addi	s1,s3,632
    80002fc0:	6a05                	lui	s4,0x1
    80002fc2:	878a0a13          	addi	s4,s4,-1928 # 878 <_entry-0x7ffff788>
    80002fc6:	9a4e                	add	s4,s4,s3
      t->terminated = 1;
    80002fc8:	4b85                	li	s7,1
      if (t->state == SLEEPING) {
    80002fca:	4b09                	li	s6,2
          t->state = RUNNABLE;
    80002fcc:	4c0d                	li	s8,3
    80002fce:	a005                	j	80002fee <exit+0xec>
      release(&t->lock);
    80002fd0:	8526                	mv	a0,s1
    80002fd2:	ffffe097          	auipc	ra,0xffffe
    80002fd6:	cb6080e7          	jalr	-842(ra) # 80000c88 <release>
      kthread_join(t->tid, 0);
    80002fda:	4581                	li	a1,0
    80002fdc:	5888                	lw	a0,48(s1)
    80002fde:	00000097          	auipc	ra,0x0
    80002fe2:	e1e080e7          	jalr	-482(ra) # 80002dfc <kthread_join>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80002fe6:	0c048493          	addi	s1,s1,192
    80002fea:	029a0863          	beq	s4,s1,8000301a <exit+0x118>
    if (t->tid != mythread()->tid) {
    80002fee:	0304a903          	lw	s2,48(s1)
    80002ff2:	fffff097          	auipc	ra,0xfffff
    80002ff6:	a3e080e7          	jalr	-1474(ra) # 80001a30 <mythread>
    80002ffa:	591c                	lw	a5,48(a0)
    80002ffc:	ff2785e3          	beq	a5,s2,80002fe6 <exit+0xe4>
      acquire(&t->lock);
    80003000:	8526                	mv	a0,s1
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	bc0080e7          	jalr	-1088(ra) # 80000bc2 <acquire>
      t->terminated = 1;
    8000300a:	0374a423          	sw	s7,40(s1)
      if (t->state == SLEEPING) {
    8000300e:	4c9c                	lw	a5,24(s1)
    80003010:	fd6790e3          	bne	a5,s6,80002fd0 <exit+0xce>
          t->state = RUNNABLE;
    80003014:	0184ac23          	sw	s8,24(s1)
    80003018:	bf65                	j	80002fd0 <exit+0xce>
  release(&p->lock);
    8000301a:	854e                	mv	a0,s3
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	c6c080e7          	jalr	-916(ra) # 80000c88 <release>
  struct thread *t = mythread();
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	a0c080e7          	jalr	-1524(ra) # 80001a30 <mythread>
    8000302c:	84aa                	mv	s1,a0
  acquire(&t->lock);
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	b94080e7          	jalr	-1132(ra) # 80000bc2 <acquire>
  t->xstate = status;
    80003036:	0354a623          	sw	s5,44(s1)
  t->state = ZOMBIE_T;
    8000303a:	4795                	li	a5,5
    8000303c:	cc9c                	sw	a5,24(s1)
  release(&wait_lock);
    8000303e:	0000e517          	auipc	a0,0xe
    80003042:	27a50513          	addi	a0,a0,634 # 800112b8 <wait_lock>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	c42080e7          	jalr	-958(ra) # 80000c88 <release>
  sched();
    8000304e:	fffff097          	auipc	ra,0xfffff
    80003052:	386080e7          	jalr	902(ra) # 800023d4 <sched>
  panic("zombie exit");
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	25a50513          	addi	a0,a0,602 # 800082b0 <digits+0x270>
    8000305e:	ffffd097          	auipc	ra,0xffffd
    80003062:	4cc080e7          	jalr	1228(ra) # 8000052a <panic>

0000000080003066 <kthread_exit>:
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	e426                	sd	s1,8(sp)
    8000306e:	e04a                	sd	s2,0(sp)
    80003070:	1000                	addi	s0,sp,32
    80003072:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	982080e7          	jalr	-1662(ra) # 800019f6 <myproc>
    8000307c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	b44080e7          	jalr	-1212(ra) # 80000bc2 <acquire>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80003086:	27848793          	addi	a5,s1,632
    8000308a:	6685                	lui	a3,0x1
    8000308c:	87868693          	addi	a3,a3,-1928 # 878 <_entry-0x7ffff788>
    80003090:	96a6                	add	a3,a3,s1
  int used_threads = 0;
    80003092:	4601                	li	a2,0
    80003094:	a029                	j	8000309e <kthread_exit+0x38>
  for (struct thread *t = p->threads; t < &p->threads[NTHREAD]; t++) {
    80003096:	0c078793          	addi	a5,a5,192
    8000309a:	00f68663          	beq	a3,a5,800030a6 <kthread_exit+0x40>
    if (t->state != UNUSED_T) {
    8000309e:	4f98                	lw	a4,24(a5)
    800030a0:	db7d                	beqz	a4,80003096 <kthread_exit+0x30>
      used_threads++;
    800030a2:	2605                	addiw	a2,a2,1
    800030a4:	bfcd                	j	80003096 <kthread_exit+0x30>
  if (used_threads <= 1) {
    800030a6:	4785                	li	a5,1
    800030a8:	00c7d763          	bge	a5,a2,800030b6 <kthread_exit+0x50>
  exit_single_thread(status);
    800030ac:	854a                	mv	a0,s2
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	cec080e7          	jalr	-788(ra) # 80002d9a <exit_single_thread>
    release(&p->lock);
    800030b6:	8526                	mv	a0,s1
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	bd0080e7          	jalr	-1072(ra) # 80000c88 <release>
    exit(status);
    800030c0:	854a                	mv	a0,s2
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	e40080e7          	jalr	-448(ra) # 80002f02 <exit>

00000000800030ca <swtch>:
    800030ca:	00153023          	sd	ra,0(a0)
    800030ce:	00253423          	sd	sp,8(a0)
    800030d2:	e900                	sd	s0,16(a0)
    800030d4:	ed04                	sd	s1,24(a0)
    800030d6:	03253023          	sd	s2,32(a0)
    800030da:	03353423          	sd	s3,40(a0)
    800030de:	03453823          	sd	s4,48(a0)
    800030e2:	03553c23          	sd	s5,56(a0)
    800030e6:	05653023          	sd	s6,64(a0)
    800030ea:	05753423          	sd	s7,72(a0)
    800030ee:	05853823          	sd	s8,80(a0)
    800030f2:	05953c23          	sd	s9,88(a0)
    800030f6:	07a53023          	sd	s10,96(a0)
    800030fa:	07b53423          	sd	s11,104(a0)
    800030fe:	0005b083          	ld	ra,0(a1)
    80003102:	0085b103          	ld	sp,8(a1)
    80003106:	6980                	ld	s0,16(a1)
    80003108:	6d84                	ld	s1,24(a1)
    8000310a:	0205b903          	ld	s2,32(a1)
    8000310e:	0285b983          	ld	s3,40(a1)
    80003112:	0305ba03          	ld	s4,48(a1)
    80003116:	0385ba83          	ld	s5,56(a1)
    8000311a:	0405bb03          	ld	s6,64(a1)
    8000311e:	0485bb83          	ld	s7,72(a1)
    80003122:	0505bc03          	ld	s8,80(a1)
    80003126:	0585bc83          	ld	s9,88(a1)
    8000312a:	0605bd03          	ld	s10,96(a1)
    8000312e:	0685bd83          	ld	s11,104(a1)
    80003132:	8082                	ret

0000000080003134 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003134:	1141                	addi	sp,sp,-16
    80003136:	e406                	sd	ra,8(sp)
    80003138:	e022                	sd	s0,0(sp)
    8000313a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000313c:	00005597          	auipc	a1,0x5
    80003140:	1bc58593          	addi	a1,a1,444 # 800082f8 <states.0+0x18>
    80003144:	00030517          	auipc	a0,0x30
    80003148:	5bc50513          	addi	a0,a0,1468 # 80033700 <tickslock>
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	9e6080e7          	jalr	-1562(ra) # 80000b32 <initlock>
}
    80003154:	60a2                	ld	ra,8(sp)
    80003156:	6402                	ld	s0,0(sp)
    80003158:	0141                	addi	sp,sp,16
    8000315a:	8082                	ret

000000008000315c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000315c:	1141                	addi	sp,sp,-16
    8000315e:	e422                	sd	s0,8(sp)
    80003160:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003162:	00003797          	auipc	a5,0x3
    80003166:	78e78793          	addi	a5,a5,1934 # 800068f0 <kernelvec>
    8000316a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000316e:	6422                	ld	s0,8(sp)
    80003170:	0141                	addi	sp,sp,16
    80003172:	8082                	ret

0000000080003174 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003174:	7179                	addi	sp,sp,-48
    80003176:	f406                	sd	ra,40(sp)
    80003178:	f022                	sd	s0,32(sp)
    8000317a:	ec26                	sd	s1,24(sp)
    8000317c:	e84a                	sd	s2,16(sp)
    8000317e:	e44e                	sd	s3,8(sp)
    80003180:	e052                	sd	s4,0(sp)
    80003182:	1800                	addi	s0,sp,48
  struct thread *t = mythread(); // ADDED Q3
    80003184:	fffff097          	auipc	ra,0xfffff
    80003188:	8ac080e7          	jalr	-1876(ra) # 80001a30 <mythread>
    8000318c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000318e:	fffff097          	auipc	ra,0xfffff
    80003192:	868080e7          	jalr	-1944(ra) # 800019f6 <myproc>
    80003196:	89aa                	mv	s3,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003198:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000319c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000319e:	10079073          	csrw	sstatus,a5

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();
  handle_signals(); // ADDED Q2.4 
    800031a2:	fffff097          	auipc	ra,0xfffff
    800031a6:	3bc080e7          	jalr	956(ra) # 8000255e <handle_signals>
  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800031aa:	00004a17          	auipc	s4,0x4
    800031ae:	e56a0a13          	addi	s4,s4,-426 # 80007000 <_trampoline>
    800031b2:	00004797          	auipc	a5,0x4
    800031b6:	e4e78793          	addi	a5,a5,-434 # 80007000 <_trampoline>
    800031ba:	414787b3          	sub	a5,a5,s4
    800031be:	04000937          	lui	s2,0x4000
    800031c2:	197d                	addi	s2,s2,-1
    800031c4:	0932                	slli	s2,s2,0xc
    800031c6:	97ca                	add	a5,a5,s2
  asm volatile("csrw stvec, %0" : : "r" (x));
    800031c8:	10579073          	csrw	stvec,a5

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  t->trapframe->kernel_satp = r_satp();         // kernel page table
    800031cc:	64bc                	ld	a5,72(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800031ce:	18002773          	csrr	a4,satp
    800031d2:	e398                	sd	a4,0(a5)
  t->trapframe->kernel_sp = t->kstack + PGSIZE; // thread's kernel stack
    800031d4:	64b8                	ld	a4,72(s1)
    800031d6:	60bc                	ld	a5,64(s1)
    800031d8:	6685                	lui	a3,0x1
    800031da:	97b6                	add	a5,a5,a3
    800031dc:	e71c                	sd	a5,8(a4)
  t->trapframe->kernel_trap = (uint64)usertrap;
    800031de:	64bc                	ld	a5,72(s1)
    800031e0:	00000717          	auipc	a4,0x0
    800031e4:	17870713          	addi	a4,a4,376 # 80003358 <usertrap>
    800031e8:	eb98                	sd	a4,16(a5)
  t->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800031ea:	64bc                	ld	a5,72(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    800031ec:	8712                	mv	a4,tp
    800031ee:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031f0:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800031f4:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800031f8:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031fc:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(t->trapframe->epc);
    80003200:	64bc                	ld	a5,72(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003202:	6f9c                	ld	a5,24(a5)
    80003204:	14179073          	csrw	sepc,a5

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003208:	1d89b983          	ld	s3,472(s3)
    8000320c:	00c9d993          	srli	s3,s3,0xc
    80003210:	57fd                	li	a5,-1
    80003212:	17fe                	slli	a5,a5,0x3f
    80003214:	00f9e9b3          	or	s3,s3,a5
  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  printf("kernal2\n");//REMOVE
    80003218:	00005517          	auipc	a0,0x5
    8000321c:	0e850513          	addi	a0,a0,232 # 80008300 <states.0+0x20>
    80003220:	ffffd097          	auipc	ra,0xffffd
    80003224:	354080e7          	jalr	852(ra) # 80000574 <printf>
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    80003228:	58dc                	lw	a5,52(s1)
    8000322a:	00379513          	slli	a0,a5,0x3
    8000322e:	953e                	add	a0,a0,a5
    80003230:	0516                	slli	a0,a0,0x5
    80003232:	02000737          	lui	a4,0x2000
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003236:	00004797          	auipc	a5,0x4
    8000323a:	e5a78793          	addi	a5,a5,-422 # 80007090 <userret>
    8000323e:	414787b3          	sub	a5,a5,s4
    80003242:	993e                	add	s2,s2,a5
  ((void (*)(uint64,uint64))fn)(TRAPFRAME(t->index), satp);
    80003244:	85ce                	mv	a1,s3
    80003246:	fff70793          	addi	a5,a4,-1 # 1ffffff <_entry-0x7e000001>
    8000324a:	07b6                	slli	a5,a5,0xd
    8000324c:	953e                	add	a0,a0,a5
    8000324e:	9902                	jalr	s2
  printf("kernal3\n");//REMOVE
    80003250:	00005517          	auipc	a0,0x5
    80003254:	0c050513          	addi	a0,a0,192 # 80008310 <states.0+0x30>
    80003258:	ffffd097          	auipc	ra,0xffffd
    8000325c:	31c080e7          	jalr	796(ra) # 80000574 <printf>

}
    80003260:	70a2                	ld	ra,40(sp)
    80003262:	7402                	ld	s0,32(sp)
    80003264:	64e2                	ld	s1,24(sp)
    80003266:	6942                	ld	s2,16(sp)
    80003268:	69a2                	ld	s3,8(sp)
    8000326a:	6a02                	ld	s4,0(sp)
    8000326c:	6145                	addi	sp,sp,48
    8000326e:	8082                	ret

0000000080003270 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003270:	1101                	addi	sp,sp,-32
    80003272:	ec06                	sd	ra,24(sp)
    80003274:	e822                	sd	s0,16(sp)
    80003276:	e426                	sd	s1,8(sp)
    80003278:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000327a:	00030497          	auipc	s1,0x30
    8000327e:	48648493          	addi	s1,s1,1158 # 80033700 <tickslock>
    80003282:	8526                	mv	a0,s1
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	93e080e7          	jalr	-1730(ra) # 80000bc2 <acquire>
  ticks++;
    8000328c:	00006517          	auipc	a0,0x6
    80003290:	da450513          	addi	a0,a0,-604 # 80009030 <ticks>
    80003294:	411c                	lw	a5,0(a0)
    80003296:	2785                	addiw	a5,a5,1
    80003298:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000329a:	fffff097          	auipc	ra,0xfffff
    8000329e:	57a080e7          	jalr	1402(ra) # 80002814 <wakeup>
  release(&tickslock);
    800032a2:	8526                	mv	a0,s1
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	9e4080e7          	jalr	-1564(ra) # 80000c88 <release>
}
    800032ac:	60e2                	ld	ra,24(sp)
    800032ae:	6442                	ld	s0,16(sp)
    800032b0:	64a2                	ld	s1,8(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret

00000000800032b6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800032b6:	1101                	addi	sp,sp,-32
    800032b8:	ec06                	sd	ra,24(sp)
    800032ba:	e822                	sd	s0,16(sp)
    800032bc:	e426                	sd	s1,8(sp)
    800032be:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032c0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800032c4:	00074d63          	bltz	a4,800032de <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800032c8:	57fd                	li	a5,-1
    800032ca:	17fe                	slli	a5,a5,0x3f
    800032cc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800032ce:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800032d0:	06f70363          	beq	a4,a5,80003336 <devintr+0x80>
  }
}
    800032d4:	60e2                	ld	ra,24(sp)
    800032d6:	6442                	ld	s0,16(sp)
    800032d8:	64a2                	ld	s1,8(sp)
    800032da:	6105                	addi	sp,sp,32
    800032dc:	8082                	ret
     (scause & 0xff) == 9){
    800032de:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800032e2:	46a5                	li	a3,9
    800032e4:	fed792e3          	bne	a5,a3,800032c8 <devintr+0x12>
    int irq = plic_claim();
    800032e8:	00003097          	auipc	ra,0x3
    800032ec:	710080e7          	jalr	1808(ra) # 800069f8 <plic_claim>
    800032f0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800032f2:	47a9                	li	a5,10
    800032f4:	02f50763          	beq	a0,a5,80003322 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800032f8:	4785                	li	a5,1
    800032fa:	02f50963          	beq	a0,a5,8000332c <devintr+0x76>
    return 1;
    800032fe:	4505                	li	a0,1
    } else if(irq){
    80003300:	d8f1                	beqz	s1,800032d4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003302:	85a6                	mv	a1,s1
    80003304:	00005517          	auipc	a0,0x5
    80003308:	01c50513          	addi	a0,a0,28 # 80008320 <states.0+0x40>
    8000330c:	ffffd097          	auipc	ra,0xffffd
    80003310:	268080e7          	jalr	616(ra) # 80000574 <printf>
      plic_complete(irq);
    80003314:	8526                	mv	a0,s1
    80003316:	00003097          	auipc	ra,0x3
    8000331a:	706080e7          	jalr	1798(ra) # 80006a1c <plic_complete>
    return 1;
    8000331e:	4505                	li	a0,1
    80003320:	bf55                	j	800032d4 <devintr+0x1e>
      uartintr();
    80003322:	ffffd097          	auipc	ra,0xffffd
    80003326:	664080e7          	jalr	1636(ra) # 80000986 <uartintr>
    8000332a:	b7ed                	j	80003314 <devintr+0x5e>
      virtio_disk_intr();
    8000332c:	00004097          	auipc	ra,0x4
    80003330:	b82080e7          	jalr	-1150(ra) # 80006eae <virtio_disk_intr>
    80003334:	b7c5                	j	80003314 <devintr+0x5e>
    if(cpuid() == 0){
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	694080e7          	jalr	1684(ra) # 800019ca <cpuid>
    8000333e:	c901                	beqz	a0,8000334e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003340:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003344:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003346:	14479073          	csrw	sip,a5
    return 2;
    8000334a:	4509                	li	a0,2
    8000334c:	b761                	j	800032d4 <devintr+0x1e>
      clockintr();
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	f22080e7          	jalr	-222(ra) # 80003270 <clockintr>
    80003356:	b7ed                	j	80003340 <devintr+0x8a>

0000000080003358 <usertrap>:
{
    80003358:	7179                	addi	sp,sp,-48
    8000335a:	f406                	sd	ra,40(sp)
    8000335c:	f022                	sd	s0,32(sp)
    8000335e:	ec26                	sd	s1,24(sp)
    80003360:	e84a                	sd	s2,16(sp)
    80003362:	e44e                	sd	s3,8(sp)
    80003364:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003366:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000336a:	1007f793          	andi	a5,a5,256
    8000336e:	e3c9                	bnez	a5,800033f0 <usertrap+0x98>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003370:	00003797          	auipc	a5,0x3
    80003374:	58078793          	addi	a5,a5,1408 # 800068f0 <kernelvec>
    80003378:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	67a080e7          	jalr	1658(ra) # 800019f6 <myproc>
    80003384:	892a                	mv	s2,a0
  struct thread *t = mythread(); // ADDED Q3
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	6aa080e7          	jalr	1706(ra) # 80001a30 <mythread>
    8000338e:	84aa                	mv	s1,a0
  t->trapframe->epc = r_sepc();
    80003390:	653c                	ld	a5,72(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003392:	14102773          	csrr	a4,sepc
    80003396:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003398:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000339c:	47a1                	li	a5,8
    8000339e:	06f71d63          	bne	a4,a5,80003418 <usertrap+0xc0>
    if(p->killed)
    800033a2:	01c92783          	lw	a5,28(s2) # 400001c <_entry-0x7bffffe4>
    800033a6:	efa9                	bnez	a5,80003400 <usertrap+0xa8>
    if (t->terminated) {
    800033a8:	549c                	lw	a5,40(s1)
    800033aa:	e3ad                	bnez	a5,8000340c <usertrap+0xb4>
    t->trapframe->epc += 4;
    800033ac:	64b8                	ld	a4,72(s1)
    800033ae:	6f1c                	ld	a5,24(a4)
    800033b0:	0791                	addi	a5,a5,4
    800033b2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800033b8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033bc:	10079073          	csrw	sstatus,a5
    syscall();
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	302080e7          	jalr	770(ra) # 800036c2 <syscall>
  int which_dev = 0;
    800033c8:	4981                	li	s3,0
  if(p->killed)
    800033ca:	01c92783          	lw	a5,28(s2)
    800033ce:	e7d1                	bnez	a5,8000345a <usertrap+0x102>
  if (t->terminated) {
    800033d0:	549c                	lw	a5,40(s1)
    800033d2:	ebd1                	bnez	a5,80003466 <usertrap+0x10e>
  if(which_dev == 2)
    800033d4:	4789                	li	a5,2
    800033d6:	08f98e63          	beq	s3,a5,80003472 <usertrap+0x11a>
  usertrapret();
    800033da:	00000097          	auipc	ra,0x0
    800033de:	d9a080e7          	jalr	-614(ra) # 80003174 <usertrapret>
}
    800033e2:	70a2                	ld	ra,40(sp)
    800033e4:	7402                	ld	s0,32(sp)
    800033e6:	64e2                	ld	s1,24(sp)
    800033e8:	6942                	ld	s2,16(sp)
    800033ea:	69a2                	ld	s3,8(sp)
    800033ec:	6145                	addi	sp,sp,48
    800033ee:	8082                	ret
    panic("usertrap: not from user mode");
    800033f0:	00005517          	auipc	a0,0x5
    800033f4:	f5050513          	addi	a0,a0,-176 # 80008340 <states.0+0x60>
    800033f8:	ffffd097          	auipc	ra,0xffffd
    800033fc:	132080e7          	jalr	306(ra) # 8000052a <panic>
      exit(-1);
    80003400:	557d                	li	a0,-1
    80003402:	00000097          	auipc	ra,0x0
    80003406:	b00080e7          	jalr	-1280(ra) # 80002f02 <exit>
    8000340a:	bf79                	j	800033a8 <usertrap+0x50>
      kthread_exit(-1);
    8000340c:	557d                	li	a0,-1
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	c58080e7          	jalr	-936(ra) # 80003066 <kthread_exit>
    80003416:	bf59                	j	800033ac <usertrap+0x54>
  } else if((which_dev = devintr()) != 0){
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	e9e080e7          	jalr	-354(ra) # 800032b6 <devintr>
    80003420:	89aa                	mv	s3,a0
    80003422:	f545                	bnez	a0,800033ca <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003424:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003428:	02492603          	lw	a2,36(s2)
    8000342c:	00005517          	auipc	a0,0x5
    80003430:	f3450513          	addi	a0,a0,-204 # 80008360 <states.0+0x80>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	140080e7          	jalr	320(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000343c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003440:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003444:	00005517          	auipc	a0,0x5
    80003448:	f4c50513          	addi	a0,a0,-180 # 80008390 <states.0+0xb0>
    8000344c:	ffffd097          	auipc	ra,0xffffd
    80003450:	128080e7          	jalr	296(ra) # 80000574 <printf>
    p->killed = 1;
    80003454:	4785                	li	a5,1
    80003456:	00f92e23          	sw	a5,28(s2)
    exit(-1);
    8000345a:	557d                	li	a0,-1
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	aa6080e7          	jalr	-1370(ra) # 80002f02 <exit>
    80003464:	b7b5                	j	800033d0 <usertrap+0x78>
    kthread_exit(-1);
    80003466:	557d                	li	a0,-1
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	bfe080e7          	jalr	-1026(ra) # 80003066 <kthread_exit>
    80003470:	b795                	j	800033d4 <usertrap+0x7c>
    yield();
    80003472:	fffff097          	auipc	ra,0xfffff
    80003476:	05c080e7          	jalr	92(ra) # 800024ce <yield>
    8000347a:	b785                	j	800033da <usertrap+0x82>

000000008000347c <kerneltrap>:
{
    8000347c:	7179                	addi	sp,sp,-48
    8000347e:	f406                	sd	ra,40(sp)
    80003480:	f022                	sd	s0,32(sp)
    80003482:	ec26                	sd	s1,24(sp)
    80003484:	e84a                	sd	s2,16(sp)
    80003486:	e44e                	sd	s3,8(sp)
    80003488:	e052                	sd	s4,0(sp)
    8000348a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000348c:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003490:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003494:	14202a73          	csrr	s4,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003498:	10097793          	andi	a5,s2,256
    8000349c:	cf95                	beqz	a5,800034d8 <kerneltrap+0x5c>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000349e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800034a2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800034a4:	e3b1                	bnez	a5,800034e8 <kerneltrap+0x6c>
  if((which_dev = devintr()) == 0){
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	e10080e7          	jalr	-496(ra) # 800032b6 <devintr>
    800034ae:	84aa                	mv	s1,a0
    800034b0:	c521                	beqz	a0,800034f8 <kerneltrap+0x7c>
  struct thread *t = mythread();
    800034b2:	ffffe097          	auipc	ra,0xffffe
    800034b6:	57e080e7          	jalr	1406(ra) # 80001a30 <mythread>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    800034ba:	4789                	li	a5,2
    800034bc:	06f48b63          	beq	s1,a5,80003532 <kerneltrap+0xb6>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800034c0:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034c4:	10091073          	csrw	sstatus,s2
}
    800034c8:	70a2                	ld	ra,40(sp)
    800034ca:	7402                	ld	s0,32(sp)
    800034cc:	64e2                	ld	s1,24(sp)
    800034ce:	6942                	ld	s2,16(sp)
    800034d0:	69a2                	ld	s3,8(sp)
    800034d2:	6a02                	ld	s4,0(sp)
    800034d4:	6145                	addi	sp,sp,48
    800034d6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800034d8:	00005517          	auipc	a0,0x5
    800034dc:	ed850513          	addi	a0,a0,-296 # 800083b0 <states.0+0xd0>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800034e8:	00005517          	auipc	a0,0x5
    800034ec:	ef050513          	addi	a0,a0,-272 # 800083d8 <states.0+0xf8>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	03a080e7          	jalr	58(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800034f8:	85d2                	mv	a1,s4
    800034fa:	00005517          	auipc	a0,0x5
    800034fe:	efe50513          	addi	a0,a0,-258 # 800083f8 <states.0+0x118>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	072080e7          	jalr	114(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000350a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000350e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003512:	00005517          	auipc	a0,0x5
    80003516:	ef650513          	addi	a0,a0,-266 # 80008408 <states.0+0x128>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	05a080e7          	jalr	90(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	efe50513          	addi	a0,a0,-258 # 80008420 <states.0+0x140>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	000080e7          	jalr	ra # 8000052a <panic>
  if(which_dev == 2 && t != 0 && t->state == RUNNING)
    80003532:	d559                	beqz	a0,800034c0 <kerneltrap+0x44>
    80003534:	4d18                	lw	a4,24(a0)
    80003536:	4791                	li	a5,4
    80003538:	f8f714e3          	bne	a4,a5,800034c0 <kerneltrap+0x44>
    yield();
    8000353c:	fffff097          	auipc	ra,0xfffff
    80003540:	f92080e7          	jalr	-110(ra) # 800024ce <yield>
    80003544:	bfb5                	j	800034c0 <kerneltrap+0x44>

0000000080003546 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003546:	1101                	addi	sp,sp,-32
    80003548:	ec06                	sd	ra,24(sp)
    8000354a:	e822                	sd	s0,16(sp)
    8000354c:	e426                	sd	s1,8(sp)
    8000354e:	1000                	addi	s0,sp,32
    80003550:	84aa                	mv	s1,a0
  struct thread *t = mythread();
    80003552:	ffffe097          	auipc	ra,0xffffe
    80003556:	4de080e7          	jalr	1246(ra) # 80001a30 <mythread>
  switch (n) {
    8000355a:	4795                	li	a5,5
    8000355c:	0497e163          	bltu	a5,s1,8000359e <argraw+0x58>
    80003560:	048a                	slli	s1,s1,0x2
    80003562:	00005717          	auipc	a4,0x5
    80003566:	ef670713          	addi	a4,a4,-266 # 80008458 <states.0+0x178>
    8000356a:	94ba                	add	s1,s1,a4
    8000356c:	409c                	lw	a5,0(s1)
    8000356e:	97ba                	add	a5,a5,a4
    80003570:	8782                	jr	a5
  case 0:
    return t->trapframe->a0;
    80003572:	653c                	ld	a5,72(a0)
    80003574:	7ba8                	ld	a0,112(a5)
  case 5:
    return t->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	64a2                	ld	s1,8(sp)
    8000357c:	6105                	addi	sp,sp,32
    8000357e:	8082                	ret
    return t->trapframe->a1;
    80003580:	653c                	ld	a5,72(a0)
    80003582:	7fa8                	ld	a0,120(a5)
    80003584:	bfcd                	j	80003576 <argraw+0x30>
    return t->trapframe->a2;
    80003586:	653c                	ld	a5,72(a0)
    80003588:	63c8                	ld	a0,128(a5)
    8000358a:	b7f5                	j	80003576 <argraw+0x30>
    return t->trapframe->a3;
    8000358c:	653c                	ld	a5,72(a0)
    8000358e:	67c8                	ld	a0,136(a5)
    80003590:	b7dd                	j	80003576 <argraw+0x30>
    return t->trapframe->a4;
    80003592:	653c                	ld	a5,72(a0)
    80003594:	6bc8                	ld	a0,144(a5)
    80003596:	b7c5                	j	80003576 <argraw+0x30>
    return t->trapframe->a5;
    80003598:	653c                	ld	a5,72(a0)
    8000359a:	6fc8                	ld	a0,152(a5)
    8000359c:	bfe9                	j	80003576 <argraw+0x30>
  panic("argraw");
    8000359e:	00005517          	auipc	a0,0x5
    800035a2:	e9250513          	addi	a0,a0,-366 # 80008430 <states.0+0x150>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	f84080e7          	jalr	-124(ra) # 8000052a <panic>

00000000800035ae <fetchaddr>:
{
    800035ae:	1101                	addi	sp,sp,-32
    800035b0:	ec06                	sd	ra,24(sp)
    800035b2:	e822                	sd	s0,16(sp)
    800035b4:	e426                	sd	s1,8(sp)
    800035b6:	e04a                	sd	s2,0(sp)
    800035b8:	1000                	addi	s0,sp,32
    800035ba:	84aa                	mv	s1,a0
    800035bc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800035be:	ffffe097          	auipc	ra,0xffffe
    800035c2:	438080e7          	jalr	1080(ra) # 800019f6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800035c6:	1d053783          	ld	a5,464(a0)
    800035ca:	02f4f963          	bgeu	s1,a5,800035fc <fetchaddr+0x4e>
    800035ce:	00848713          	addi	a4,s1,8
    800035d2:	02e7e763          	bltu	a5,a4,80003600 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800035d6:	46a1                	li	a3,8
    800035d8:	8626                	mv	a2,s1
    800035da:	85ca                	mv	a1,s2
    800035dc:	1d853503          	ld	a0,472(a0)
    800035e0:	ffffe097          	auipc	ra,0xffffe
    800035e4:	10e080e7          	jalr	270(ra) # 800016ee <copyin>
    800035e8:	00a03533          	snez	a0,a0
    800035ec:	40a00533          	neg	a0,a0
}
    800035f0:	60e2                	ld	ra,24(sp)
    800035f2:	6442                	ld	s0,16(sp)
    800035f4:	64a2                	ld	s1,8(sp)
    800035f6:	6902                	ld	s2,0(sp)
    800035f8:	6105                	addi	sp,sp,32
    800035fa:	8082                	ret
    return -1;
    800035fc:	557d                	li	a0,-1
    800035fe:	bfcd                	j	800035f0 <fetchaddr+0x42>
    80003600:	557d                	li	a0,-1
    80003602:	b7fd                	j	800035f0 <fetchaddr+0x42>

0000000080003604 <fetchstr>:
{
    80003604:	7179                	addi	sp,sp,-48
    80003606:	f406                	sd	ra,40(sp)
    80003608:	f022                	sd	s0,32(sp)
    8000360a:	ec26                	sd	s1,24(sp)
    8000360c:	e84a                	sd	s2,16(sp)
    8000360e:	e44e                	sd	s3,8(sp)
    80003610:	1800                	addi	s0,sp,48
    80003612:	892a                	mv	s2,a0
    80003614:	84ae                	mv	s1,a1
    80003616:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003618:	ffffe097          	auipc	ra,0xffffe
    8000361c:	3de080e7          	jalr	990(ra) # 800019f6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003620:	86ce                	mv	a3,s3
    80003622:	864a                	mv	a2,s2
    80003624:	85a6                	mv	a1,s1
    80003626:	1d853503          	ld	a0,472(a0)
    8000362a:	ffffe097          	auipc	ra,0xffffe
    8000362e:	152080e7          	jalr	338(ra) # 8000177c <copyinstr>
  if(err < 0)
    80003632:	00054763          	bltz	a0,80003640 <fetchstr+0x3c>
  return strlen(buf);
    80003636:	8526                	mv	a0,s1
    80003638:	ffffe097          	auipc	ra,0xffffe
    8000363c:	82e080e7          	jalr	-2002(ra) # 80000e66 <strlen>
}
    80003640:	70a2                	ld	ra,40(sp)
    80003642:	7402                	ld	s0,32(sp)
    80003644:	64e2                	ld	s1,24(sp)
    80003646:	6942                	ld	s2,16(sp)
    80003648:	69a2                	ld	s3,8(sp)
    8000364a:	6145                	addi	sp,sp,48
    8000364c:	8082                	ret

000000008000364e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000364e:	1101                	addi	sp,sp,-32
    80003650:	ec06                	sd	ra,24(sp)
    80003652:	e822                	sd	s0,16(sp)
    80003654:	e426                	sd	s1,8(sp)
    80003656:	1000                	addi	s0,sp,32
    80003658:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	eec080e7          	jalr	-276(ra) # 80003546 <argraw>
    80003662:	c088                	sw	a0,0(s1)
  return 0;
}
    80003664:	4501                	li	a0,0
    80003666:	60e2                	ld	ra,24(sp)
    80003668:	6442                	ld	s0,16(sp)
    8000366a:	64a2                	ld	s1,8(sp)
    8000366c:	6105                	addi	sp,sp,32
    8000366e:	8082                	ret

0000000080003670 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003670:	1101                	addi	sp,sp,-32
    80003672:	ec06                	sd	ra,24(sp)
    80003674:	e822                	sd	s0,16(sp)
    80003676:	e426                	sd	s1,8(sp)
    80003678:	1000                	addi	s0,sp,32
    8000367a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	eca080e7          	jalr	-310(ra) # 80003546 <argraw>
    80003684:	e088                	sd	a0,0(s1)
  return 0;
}
    80003686:	4501                	li	a0,0
    80003688:	60e2                	ld	ra,24(sp)
    8000368a:	6442                	ld	s0,16(sp)
    8000368c:	64a2                	ld	s1,8(sp)
    8000368e:	6105                	addi	sp,sp,32
    80003690:	8082                	ret

0000000080003692 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003692:	1101                	addi	sp,sp,-32
    80003694:	ec06                	sd	ra,24(sp)
    80003696:	e822                	sd	s0,16(sp)
    80003698:	e426                	sd	s1,8(sp)
    8000369a:	e04a                	sd	s2,0(sp)
    8000369c:	1000                	addi	s0,sp,32
    8000369e:	84ae                	mv	s1,a1
    800036a0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	ea4080e7          	jalr	-348(ra) # 80003546 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800036aa:	864a                	mv	a2,s2
    800036ac:	85a6                	mv	a1,s1
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	f56080e7          	jalr	-170(ra) # 80003604 <fetchstr>
}
    800036b6:	60e2                	ld	ra,24(sp)
    800036b8:	6442                	ld	s0,16(sp)
    800036ba:	64a2                	ld	s1,8(sp)
    800036bc:	6902                	ld	s2,0(sp)
    800036be:	6105                	addi	sp,sp,32
    800036c0:	8082                	ret

00000000800036c2 <syscall>:
[SYS_kthread_join]   sys_kthread_join,
};

void
syscall(void)
{
    800036c2:	1101                	addi	sp,sp,-32
    800036c4:	ec06                	sd	ra,24(sp)
    800036c6:	e822                	sd	s0,16(sp)
    800036c8:	e426                	sd	s1,8(sp)
    800036ca:	e04a                	sd	s2,0(sp)
    800036cc:	1000                	addi	s0,sp,32
  int num;
  struct thread *t = mythread();
    800036ce:	ffffe097          	auipc	ra,0xffffe
    800036d2:	362080e7          	jalr	866(ra) # 80001a30 <mythread>
    800036d6:	84aa                	mv	s1,a0

  num = t->trapframe->a7;
    800036d8:	04853903          	ld	s2,72(a0)
    800036dc:	0a893783          	ld	a5,168(s2)
    800036e0:	0007861b          	sext.w	a2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800036e4:	37fd                	addiw	a5,a5,-1
    800036e6:	476d                	li	a4,27
    800036e8:	00f76f63          	bltu	a4,a5,80003706 <syscall+0x44>
    800036ec:	00361713          	slli	a4,a2,0x3
    800036f0:	00005797          	auipc	a5,0x5
    800036f4:	d8078793          	addi	a5,a5,-640 # 80008470 <syscalls>
    800036f8:	97ba                	add	a5,a5,a4
    800036fa:	639c                	ld	a5,0(a5)
    800036fc:	c789                	beqz	a5,80003706 <syscall+0x44>
    t->trapframe->a0 = syscalls[num]();
    800036fe:	9782                	jalr	a5
    80003700:	06a93823          	sd	a0,112(s2)
    80003704:	a829                	j	8000371e <syscall+0x5c>
  } else {
    printf("thread %d: unknown sys call %d\n",
    80003706:	588c                	lw	a1,48(s1)
    80003708:	00005517          	auipc	a0,0x5
    8000370c:	d3050513          	addi	a0,a0,-720 # 80008438 <states.0+0x158>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e64080e7          	jalr	-412(ra) # 80000574 <printf>
            t->tid, num);
    t->trapframe->a0 = -1;
    80003718:	64bc                	ld	a5,72(s1)
    8000371a:	577d                	li	a4,-1
    8000371c:	fbb8                	sd	a4,112(a5)
  }
}
    8000371e:	60e2                	ld	ra,24(sp)
    80003720:	6442                	ld	s0,16(sp)
    80003722:	64a2                	ld	s1,8(sp)
    80003724:	6902                	ld	s2,0(sp)
    80003726:	6105                	addi	sp,sp,32
    80003728:	8082                	ret

000000008000372a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000372a:	1101                	addi	sp,sp,-32
    8000372c:	ec06                	sd	ra,24(sp)
    8000372e:	e822                	sd	s0,16(sp)
    80003730:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003732:	fec40593          	addi	a1,s0,-20
    80003736:	4501                	li	a0,0
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	f16080e7          	jalr	-234(ra) # 8000364e <argint>
    return -1;
    80003740:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003742:	00054963          	bltz	a0,80003754 <sys_exit+0x2a>
  exit(n);
    80003746:	fec42503          	lw	a0,-20(s0)
    8000374a:	fffff097          	auipc	ra,0xfffff
    8000374e:	7b8080e7          	jalr	1976(ra) # 80002f02 <exit>
  return 0;  // not reached
    80003752:	4781                	li	a5,0
}
    80003754:	853e                	mv	a0,a5
    80003756:	60e2                	ld	ra,24(sp)
    80003758:	6442                	ld	s0,16(sp)
    8000375a:	6105                	addi	sp,sp,32
    8000375c:	8082                	ret

000000008000375e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000375e:	1141                	addi	sp,sp,-16
    80003760:	e406                	sd	ra,8(sp)
    80003762:	e022                	sd	s0,0(sp)
    80003764:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003766:	ffffe097          	auipc	ra,0xffffe
    8000376a:	290080e7          	jalr	656(ra) # 800019f6 <myproc>
}
    8000376e:	5148                	lw	a0,36(a0)
    80003770:	60a2                	ld	ra,8(sp)
    80003772:	6402                	ld	s0,0(sp)
    80003774:	0141                	addi	sp,sp,16
    80003776:	8082                	ret

0000000080003778 <sys_fork>:

uint64
sys_fork(void)
{
    80003778:	1141                	addi	sp,sp,-16
    8000377a:	e406                	sd	ra,8(sp)
    8000377c:	e022                	sd	s0,0(sp)
    8000377e:	0800                	addi	s0,sp,16
  return fork();
    80003780:	fffff097          	auipc	ra,0xfffff
    80003784:	882080e7          	jalr	-1918(ra) # 80002002 <fork>
}
    80003788:	60a2                	ld	ra,8(sp)
    8000378a:	6402                	ld	s0,0(sp)
    8000378c:	0141                	addi	sp,sp,16
    8000378e:	8082                	ret

0000000080003790 <sys_wait>:

uint64
sys_wait(void)
{
    80003790:	1101                	addi	sp,sp,-32
    80003792:	ec06                	sd	ra,24(sp)
    80003794:	e822                	sd	s0,16(sp)
    80003796:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003798:	fe840593          	addi	a1,s0,-24
    8000379c:	4501                	li	a0,0
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	ed2080e7          	jalr	-302(ra) # 80003670 <argaddr>
    800037a6:	87aa                	mv	a5,a0
    return -1;
    800037a8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800037aa:	0007c863          	bltz	a5,800037ba <sys_wait+0x2a>
  return wait(p);
    800037ae:	fe843503          	ld	a0,-24(s0)
    800037b2:	fffff097          	auipc	ra,0xfffff
    800037b6:	f3c080e7          	jalr	-196(ra) # 800026ee <wait>
}
    800037ba:	60e2                	ld	ra,24(sp)
    800037bc:	6442                	ld	s0,16(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret

00000000800037c2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800037c2:	7179                	addi	sp,sp,-48
    800037c4:	f406                	sd	ra,40(sp)
    800037c6:	f022                	sd	s0,32(sp)
    800037c8:	ec26                	sd	s1,24(sp)
    800037ca:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800037cc:	fdc40593          	addi	a1,s0,-36
    800037d0:	4501                	li	a0,0
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	e7c080e7          	jalr	-388(ra) # 8000364e <argint>
    return -1;
    800037da:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800037dc:	02054063          	bltz	a0,800037fc <sys_sbrk+0x3a>
  addr = myproc()->sz;
    800037e0:	ffffe097          	auipc	ra,0xffffe
    800037e4:	216080e7          	jalr	534(ra) # 800019f6 <myproc>
    800037e8:	1d052483          	lw	s1,464(a0)
  if(growproc(n) < 0)
    800037ec:	fdc42503          	lw	a0,-36(s0)
    800037f0:	ffffe097          	auipc	ra,0xffffe
    800037f4:	778080e7          	jalr	1912(ra) # 80001f68 <growproc>
    800037f8:	00054863          	bltz	a0,80003808 <sys_sbrk+0x46>
    return -1;
  return addr;
}
    800037fc:	8526                	mv	a0,s1
    800037fe:	70a2                	ld	ra,40(sp)
    80003800:	7402                	ld	s0,32(sp)
    80003802:	64e2                	ld	s1,24(sp)
    80003804:	6145                	addi	sp,sp,48
    80003806:	8082                	ret
    return -1;
    80003808:	54fd                	li	s1,-1
    8000380a:	bfcd                	j	800037fc <sys_sbrk+0x3a>

000000008000380c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000380c:	7139                	addi	sp,sp,-64
    8000380e:	fc06                	sd	ra,56(sp)
    80003810:	f822                	sd	s0,48(sp)
    80003812:	f426                	sd	s1,40(sp)
    80003814:	f04a                	sd	s2,32(sp)
    80003816:	ec4e                	sd	s3,24(sp)
    80003818:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000381a:	fcc40593          	addi	a1,s0,-52
    8000381e:	4501                	li	a0,0
    80003820:	00000097          	auipc	ra,0x0
    80003824:	e2e080e7          	jalr	-466(ra) # 8000364e <argint>
    return -1;
    80003828:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000382a:	06054563          	bltz	a0,80003894 <sys_sleep+0x88>
  acquire(&tickslock);
    8000382e:	00030517          	auipc	a0,0x30
    80003832:	ed250513          	addi	a0,a0,-302 # 80033700 <tickslock>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	38c080e7          	jalr	908(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000383e:	00005917          	auipc	s2,0x5
    80003842:	7f292903          	lw	s2,2034(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003846:	fcc42783          	lw	a5,-52(s0)
    8000384a:	cf85                	beqz	a5,80003882 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000384c:	00030997          	auipc	s3,0x30
    80003850:	eb498993          	addi	s3,s3,-332 # 80033700 <tickslock>
    80003854:	00005497          	auipc	s1,0x5
    80003858:	7dc48493          	addi	s1,s1,2012 # 80009030 <ticks>
    if(myproc()->killed){
    8000385c:	ffffe097          	auipc	ra,0xffffe
    80003860:	19a080e7          	jalr	410(ra) # 800019f6 <myproc>
    80003864:	4d5c                	lw	a5,28(a0)
    80003866:	ef9d                	bnez	a5,800038a4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003868:	85ce                	mv	a1,s3
    8000386a:	8526                	mv	a0,s1
    8000386c:	fffff097          	auipc	ra,0xfffff
    80003870:	e1e080e7          	jalr	-482(ra) # 8000268a <sleep>
  while(ticks - ticks0 < n){
    80003874:	409c                	lw	a5,0(s1)
    80003876:	412787bb          	subw	a5,a5,s2
    8000387a:	fcc42703          	lw	a4,-52(s0)
    8000387e:	fce7efe3          	bltu	a5,a4,8000385c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003882:	00030517          	auipc	a0,0x30
    80003886:	e7e50513          	addi	a0,a0,-386 # 80033700 <tickslock>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	3fe080e7          	jalr	1022(ra) # 80000c88 <release>
  return 0;
    80003892:	4781                	li	a5,0
}
    80003894:	853e                	mv	a0,a5
    80003896:	70e2                	ld	ra,56(sp)
    80003898:	7442                	ld	s0,48(sp)
    8000389a:	74a2                	ld	s1,40(sp)
    8000389c:	7902                	ld	s2,32(sp)
    8000389e:	69e2                	ld	s3,24(sp)
    800038a0:	6121                	addi	sp,sp,64
    800038a2:	8082                	ret
      release(&tickslock);
    800038a4:	00030517          	auipc	a0,0x30
    800038a8:	e5c50513          	addi	a0,a0,-420 # 80033700 <tickslock>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	3dc080e7          	jalr	988(ra) # 80000c88 <release>
      return -1;
    800038b4:	57fd                	li	a5,-1
    800038b6:	bff9                	j	80003894 <sys_sleep+0x88>

00000000800038b8 <sys_kill>:

// ADDED Q2.2.1
uint64
sys_kill(void)
{
    800038b8:	1101                	addi	sp,sp,-32
    800038ba:	ec06                	sd	ra,24(sp)
    800038bc:	e822                	sd	s0,16(sp)
    800038be:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    800038c0:	fec40593          	addi	a1,s0,-20
    800038c4:	4501                	li	a0,0
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	d88080e7          	jalr	-632(ra) # 8000364e <argint>
    return -1;
    800038ce:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    800038d0:	02054563          	bltz	a0,800038fa <sys_kill+0x42>

  if(argint(1, &signum) < 0)
    800038d4:	fe840593          	addi	a1,s0,-24
    800038d8:	4505                	li	a0,1
    800038da:	00000097          	auipc	ra,0x0
    800038de:	d74080e7          	jalr	-652(ra) # 8000364e <argint>
    return -1;
    800038e2:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    800038e4:	00054b63          	bltz	a0,800038fa <sys_kill+0x42>

  return kill(pid, signum);
    800038e8:	fe842583          	lw	a1,-24(s0)
    800038ec:	fec42503          	lw	a0,-20(s0)
    800038f0:	fffff097          	auipc	ra,0xfffff
    800038f4:	01a080e7          	jalr	26(ra) # 8000290a <kill>
    800038f8:	87aa                	mv	a5,a0
}
    800038fa:	853e                	mv	a0,a5
    800038fc:	60e2                	ld	ra,24(sp)
    800038fe:	6442                	ld	s0,16(sp)
    80003900:	6105                	addi	sp,sp,32
    80003902:	8082                	ret

0000000080003904 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003904:	1101                	addi	sp,sp,-32
    80003906:	ec06                	sd	ra,24(sp)
    80003908:	e822                	sd	s0,16(sp)
    8000390a:	e426                	sd	s1,8(sp)
    8000390c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000390e:	00030517          	auipc	a0,0x30
    80003912:	df250513          	addi	a0,a0,-526 # 80033700 <tickslock>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	2ac080e7          	jalr	684(ra) # 80000bc2 <acquire>
  xticks = ticks;
    8000391e:	00005497          	auipc	s1,0x5
    80003922:	7124a483          	lw	s1,1810(s1) # 80009030 <ticks>
  release(&tickslock);
    80003926:	00030517          	auipc	a0,0x30
    8000392a:	dda50513          	addi	a0,a0,-550 # 80033700 <tickslock>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	35a080e7          	jalr	858(ra) # 80000c88 <release>
  return xticks;
}
    80003936:	02049513          	slli	a0,s1,0x20
    8000393a:	9101                	srli	a0,a0,0x20
    8000393c:	60e2                	ld	ra,24(sp)
    8000393e:	6442                	ld	s0,16(sp)
    80003940:	64a2                	ld	s1,8(sp)
    80003942:	6105                	addi	sp,sp,32
    80003944:	8082                	ret

0000000080003946 <sys_sigprocmask>:

// ADDED Q2.1.3
uint64
sys_sigprocmask(void)
{
    80003946:	1101                	addi	sp,sp,-32
    80003948:	ec06                	sd	ra,24(sp)
    8000394a:	e822                	sd	s0,16(sp)
    8000394c:	1000                	addi	s0,sp,32
  uint sigmask;

  if(argint(0, (int *)&sigmask) < 0) 
    8000394e:	fec40593          	addi	a1,s0,-20
    80003952:	4501                	li	a0,0
    80003954:	00000097          	auipc	ra,0x0
    80003958:	cfa080e7          	jalr	-774(ra) # 8000364e <argint>
    8000395c:	87aa                	mv	a5,a0
    return -1;
    8000395e:	557d                	li	a0,-1
  if(argint(0, (int *)&sigmask) < 0) 
    80003960:	0007ca63          	bltz	a5,80003974 <sys_sigprocmask+0x2e>

  return sigprocmask(sigmask);
    80003964:	fec42503          	lw	a0,-20(s0)
    80003968:	fffff097          	auipc	ra,0xfffff
    8000396c:	18e080e7          	jalr	398(ra) # 80002af6 <sigprocmask>
    80003970:	1502                	slli	a0,a0,0x20
    80003972:	9101                	srli	a0,a0,0x20
}
    80003974:	60e2                	ld	ra,24(sp)
    80003976:	6442                	ld	s0,16(sp)
    80003978:	6105                	addi	sp,sp,32
    8000397a:	8082                	ret

000000008000397c <sys_sigaction>:

// ADDED Q2.1.4
uint64
sys_sigaction(void)
{
    8000397c:	7179                	addi	sp,sp,-48
    8000397e:	f406                	sd	ra,40(sp)
    80003980:	f022                	sd	s0,32(sp)
    80003982:	1800                	addi	s0,sp,48
  int signum;
  struct sigaction *act;
  struct sigaction *oldact;

  if(argint(0, &signum) < 0)
    80003984:	fec40593          	addi	a1,s0,-20
    80003988:	4501                	li	a0,0
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	cc4080e7          	jalr	-828(ra) # 8000364e <argint>
    return -1;
    80003992:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    80003994:	04054163          	bltz	a0,800039d6 <sys_sigaction+0x5a>

  if(argaddr(1, (uint64 *)&act) < 0)
    80003998:	fe040593          	addi	a1,s0,-32
    8000399c:	4505                	li	a0,1
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	cd2080e7          	jalr	-814(ra) # 80003670 <argaddr>
    return -1;
    800039a6:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&act) < 0)
    800039a8:	02054763          	bltz	a0,800039d6 <sys_sigaction+0x5a>

  if(argaddr(2, (uint64 *)&oldact) < 0)
    800039ac:	fd840593          	addi	a1,s0,-40
    800039b0:	4509                	li	a0,2
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	cbe080e7          	jalr	-834(ra) # 80003670 <argaddr>
    return -1;
    800039ba:	57fd                	li	a5,-1
  if(argaddr(2, (uint64 *)&oldact) < 0)
    800039bc:	00054d63          	bltz	a0,800039d6 <sys_sigaction+0x5a>

  return sigaction(signum, act, oldact);
    800039c0:	fd843603          	ld	a2,-40(s0)
    800039c4:	fe043583          	ld	a1,-32(s0)
    800039c8:	fec42503          	lw	a0,-20(s0)
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	18a080e7          	jalr	394(ra) # 80002b56 <sigaction>
    800039d4:	87aa                	mv	a5,a0
}
    800039d6:	853e                	mv	a0,a5
    800039d8:	70a2                	ld	ra,40(sp)
    800039da:	7402                	ld	s0,32(sp)
    800039dc:	6145                	addi	sp,sp,48
    800039de:	8082                	ret

00000000800039e0 <sys_sigret>:

// ADDED Q2.1.5
uint64
sys_sigret(void)
{
    800039e0:	1141                	addi	sp,sp,-16
    800039e2:	e406                	sd	ra,8(sp)
    800039e4:	e022                	sd	s0,0(sp)
    800039e6:	0800                	addi	s0,sp,16
  sigret();
    800039e8:	fffff097          	auipc	ra,0xfffff
    800039ec:	2ae080e7          	jalr	686(ra) # 80002c96 <sigret>
  return 0;
}
    800039f0:	4501                	li	a0,0
    800039f2:	60a2                	ld	ra,8(sp)
    800039f4:	6402                	ld	s0,0(sp)
    800039f6:	0141                	addi	sp,sp,16
    800039f8:	8082                	ret

00000000800039fa <sys_kthread_create>:

// ADDED Q3.2
uint64
sys_kthread_create(void)
{
    800039fa:	1101                	addi	sp,sp,-32
    800039fc:	ec06                	sd	ra,24(sp)
    800039fe:	e822                	sd	s0,16(sp)
    80003a00:	1000                	addi	s0,sp,32
  void (*start_func)();
  void *stack;

  if(argaddr(0, (uint64 *)&start_func) < 0)
    80003a02:	fe840593          	addi	a1,s0,-24
    80003a06:	4501                	li	a0,0
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	c68080e7          	jalr	-920(ra) # 80003670 <argaddr>
    return -1;
    80003a10:	57fd                	li	a5,-1
  if(argaddr(0, (uint64 *)&start_func) < 0)
    80003a12:	02054563          	bltz	a0,80003a3c <sys_kthread_create+0x42>

  if(argaddr(1, (uint64 *)&stack) < 0)
    80003a16:	fe040593          	addi	a1,s0,-32
    80003a1a:	4505                	li	a0,1
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	c54080e7          	jalr	-940(ra) # 80003670 <argaddr>
    return -1;
    80003a24:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&stack) < 0)
    80003a26:	00054b63          	bltz	a0,80003a3c <sys_kthread_create+0x42>

  return kthread_create(start_func, stack);
    80003a2a:	fe043583          	ld	a1,-32(s0)
    80003a2e:	fe843503          	ld	a0,-24(s0)
    80003a32:	fffff097          	auipc	ra,0xfffff
    80003a36:	2d2080e7          	jalr	722(ra) # 80002d04 <kthread_create>
    80003a3a:	87aa                	mv	a5,a0
}
    80003a3c:	853e                	mv	a0,a5
    80003a3e:	60e2                	ld	ra,24(sp)
    80003a40:	6442                	ld	s0,16(sp)
    80003a42:	6105                	addi	sp,sp,32
    80003a44:	8082                	ret

0000000080003a46 <sys_kthread_id>:

uint64
sys_kthread_id(void)
{
    80003a46:	1141                	addi	sp,sp,-16
    80003a48:	e406                	sd	ra,8(sp)
    80003a4a:	e022                	sd	s0,0(sp)
    80003a4c:	0800                	addi	s0,sp,16
  return mythread()->tid;
    80003a4e:	ffffe097          	auipc	ra,0xffffe
    80003a52:	fe2080e7          	jalr	-30(ra) # 80001a30 <mythread>
}
    80003a56:	5908                	lw	a0,48(a0)
    80003a58:	60a2                	ld	ra,8(sp)
    80003a5a:	6402                	ld	s0,0(sp)
    80003a5c:	0141                	addi	sp,sp,16
    80003a5e:	8082                	ret

0000000080003a60 <sys_kthread_exit>:

uint64
sys_kthread_exit(void)
{
    80003a60:	1101                	addi	sp,sp,-32
    80003a62:	ec06                	sd	ra,24(sp)
    80003a64:	e822                	sd	s0,16(sp)
    80003a66:	1000                	addi	s0,sp,32
  int status;

  if(argint(0, &status) < 0)
    80003a68:	fec40593          	addi	a1,s0,-20
    80003a6c:	4501                	li	a0,0
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	be0080e7          	jalr	-1056(ra) # 8000364e <argint>
    return -1;
    80003a76:	57fd                	li	a5,-1
  if(argint(0, &status) < 0)
    80003a78:	00054963          	bltz	a0,80003a8a <sys_kthread_exit+0x2a>

  kthread_exit(status);
    80003a7c:	fec42503          	lw	a0,-20(s0)
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	5e6080e7          	jalr	1510(ra) # 80003066 <kthread_exit>
  return 0; //TODO: retval?
    80003a88:	4781                	li	a5,0
}
    80003a8a:	853e                	mv	a0,a5
    80003a8c:	60e2                	ld	ra,24(sp)
    80003a8e:	6442                	ld	s0,16(sp)
    80003a90:	6105                	addi	sp,sp,32
    80003a92:	8082                	ret

0000000080003a94 <sys_kthread_join>:

uint64
sys_kthread_join(void)
{
    80003a94:	1101                	addi	sp,sp,-32
    80003a96:	ec06                	sd	ra,24(sp)
    80003a98:	e822                	sd	s0,16(sp)
    80003a9a:	1000                	addi	s0,sp,32
  int thread_id;
  int *status;

  if(argint(0, &thread_id) < 0)
    80003a9c:	fec40593          	addi	a1,s0,-20
    80003aa0:	4501                	li	a0,0
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	bac080e7          	jalr	-1108(ra) # 8000364e <argint>
    return -1;
    80003aaa:	57fd                	li	a5,-1
  if(argint(0, &thread_id) < 0)
    80003aac:	02054563          	bltz	a0,80003ad6 <sys_kthread_join+0x42>

  if(argaddr(1, (uint64 *)&status) < 0)
    80003ab0:	fe040593          	addi	a1,s0,-32
    80003ab4:	4505                	li	a0,1
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	bba080e7          	jalr	-1094(ra) # 80003670 <argaddr>
    return -1;
    80003abe:	57fd                	li	a5,-1
  if(argaddr(1, (uint64 *)&status) < 0)
    80003ac0:	00054b63          	bltz	a0,80003ad6 <sys_kthread_join+0x42>

  return kthread_join(thread_id, status);
    80003ac4:	fe043583          	ld	a1,-32(s0)
    80003ac8:	fec42503          	lw	a0,-20(s0)
    80003acc:	fffff097          	auipc	ra,0xfffff
    80003ad0:	330080e7          	jalr	816(ra) # 80002dfc <kthread_join>
    80003ad4:	87aa                	mv	a5,a0
    80003ad6:	853e                	mv	a0,a5
    80003ad8:	60e2                	ld	ra,24(sp)
    80003ada:	6442                	ld	s0,16(sp)
    80003adc:	6105                	addi	sp,sp,32
    80003ade:	8082                	ret

0000000080003ae0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003ae0:	7179                	addi	sp,sp,-48
    80003ae2:	f406                	sd	ra,40(sp)
    80003ae4:	f022                	sd	s0,32(sp)
    80003ae6:	ec26                	sd	s1,24(sp)
    80003ae8:	e84a                	sd	s2,16(sp)
    80003aea:	e44e                	sd	s3,8(sp)
    80003aec:	e052                	sd	s4,0(sp)
    80003aee:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003af0:	00005597          	auipc	a1,0x5
    80003af4:	a6858593          	addi	a1,a1,-1432 # 80008558 <syscalls+0xe8>
    80003af8:	00030517          	auipc	a0,0x30
    80003afc:	c2050513          	addi	a0,a0,-992 # 80033718 <bcache>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	032080e7          	jalr	50(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003b08:	00038797          	auipc	a5,0x38
    80003b0c:	c1078793          	addi	a5,a5,-1008 # 8003b718 <bcache+0x8000>
    80003b10:	00038717          	auipc	a4,0x38
    80003b14:	e7070713          	addi	a4,a4,-400 # 8003b980 <bcache+0x8268>
    80003b18:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003b1c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b20:	00030497          	auipc	s1,0x30
    80003b24:	c1048493          	addi	s1,s1,-1008 # 80033730 <bcache+0x18>
    b->next = bcache.head.next;
    80003b28:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003b2a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003b2c:	00005a17          	auipc	s4,0x5
    80003b30:	a34a0a13          	addi	s4,s4,-1484 # 80008560 <syscalls+0xf0>
    b->next = bcache.head.next;
    80003b34:	2b893783          	ld	a5,696(s2)
    80003b38:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003b3a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003b3e:	85d2                	mv	a1,s4
    80003b40:	01048513          	addi	a0,s1,16
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	4c2080e7          	jalr	1218(ra) # 80005006 <initsleeplock>
    bcache.head.next->prev = b;
    80003b4c:	2b893783          	ld	a5,696(s2)
    80003b50:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003b52:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b56:	45848493          	addi	s1,s1,1112
    80003b5a:	fd349de3          	bne	s1,s3,80003b34 <binit+0x54>
  }
}
    80003b5e:	70a2                	ld	ra,40(sp)
    80003b60:	7402                	ld	s0,32(sp)
    80003b62:	64e2                	ld	s1,24(sp)
    80003b64:	6942                	ld	s2,16(sp)
    80003b66:	69a2                	ld	s3,8(sp)
    80003b68:	6a02                	ld	s4,0(sp)
    80003b6a:	6145                	addi	sp,sp,48
    80003b6c:	8082                	ret

0000000080003b6e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b6e:	7179                	addi	sp,sp,-48
    80003b70:	f406                	sd	ra,40(sp)
    80003b72:	f022                	sd	s0,32(sp)
    80003b74:	ec26                	sd	s1,24(sp)
    80003b76:	e84a                	sd	s2,16(sp)
    80003b78:	e44e                	sd	s3,8(sp)
    80003b7a:	1800                	addi	s0,sp,48
    80003b7c:	892a                	mv	s2,a0
    80003b7e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003b80:	00030517          	auipc	a0,0x30
    80003b84:	b9850513          	addi	a0,a0,-1128 # 80033718 <bcache>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	03a080e7          	jalr	58(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b90:	00038497          	auipc	s1,0x38
    80003b94:	e404b483          	ld	s1,-448(s1) # 8003b9d0 <bcache+0x82b8>
    80003b98:	00038797          	auipc	a5,0x38
    80003b9c:	de878793          	addi	a5,a5,-536 # 8003b980 <bcache+0x8268>
    80003ba0:	02f48f63          	beq	s1,a5,80003bde <bread+0x70>
    80003ba4:	873e                	mv	a4,a5
    80003ba6:	a021                	j	80003bae <bread+0x40>
    80003ba8:	68a4                	ld	s1,80(s1)
    80003baa:	02e48a63          	beq	s1,a4,80003bde <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003bae:	449c                	lw	a5,8(s1)
    80003bb0:	ff279ce3          	bne	a5,s2,80003ba8 <bread+0x3a>
    80003bb4:	44dc                	lw	a5,12(s1)
    80003bb6:	ff3799e3          	bne	a5,s3,80003ba8 <bread+0x3a>
      b->refcnt++;
    80003bba:	40bc                	lw	a5,64(s1)
    80003bbc:	2785                	addiw	a5,a5,1
    80003bbe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003bc0:	00030517          	auipc	a0,0x30
    80003bc4:	b5850513          	addi	a0,a0,-1192 # 80033718 <bcache>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	0c0080e7          	jalr	192(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003bd0:	01048513          	addi	a0,s1,16
    80003bd4:	00001097          	auipc	ra,0x1
    80003bd8:	46c080e7          	jalr	1132(ra) # 80005040 <acquiresleep>
      return b;
    80003bdc:	a8b9                	j	80003c3a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003bde:	00038497          	auipc	s1,0x38
    80003be2:	dea4b483          	ld	s1,-534(s1) # 8003b9c8 <bcache+0x82b0>
    80003be6:	00038797          	auipc	a5,0x38
    80003bea:	d9a78793          	addi	a5,a5,-614 # 8003b980 <bcache+0x8268>
    80003bee:	00f48863          	beq	s1,a5,80003bfe <bread+0x90>
    80003bf2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003bf4:	40bc                	lw	a5,64(s1)
    80003bf6:	cf81                	beqz	a5,80003c0e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003bf8:	64a4                	ld	s1,72(s1)
    80003bfa:	fee49de3          	bne	s1,a4,80003bf4 <bread+0x86>
  panic("bget: no buffers");
    80003bfe:	00005517          	auipc	a0,0x5
    80003c02:	96a50513          	addi	a0,a0,-1686 # 80008568 <syscalls+0xf8>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	924080e7          	jalr	-1756(ra) # 8000052a <panic>
      b->dev = dev;
    80003c0e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003c12:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003c16:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003c1a:	4785                	li	a5,1
    80003c1c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003c1e:	00030517          	auipc	a0,0x30
    80003c22:	afa50513          	addi	a0,a0,-1286 # 80033718 <bcache>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	062080e7          	jalr	98(ra) # 80000c88 <release>
      acquiresleep(&b->lock);
    80003c2e:	01048513          	addi	a0,s1,16
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	40e080e7          	jalr	1038(ra) # 80005040 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003c3a:	409c                	lw	a5,0(s1)
    80003c3c:	cb89                	beqz	a5,80003c4e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003c3e:	8526                	mv	a0,s1
    80003c40:	70a2                	ld	ra,40(sp)
    80003c42:	7402                	ld	s0,32(sp)
    80003c44:	64e2                	ld	s1,24(sp)
    80003c46:	6942                	ld	s2,16(sp)
    80003c48:	69a2                	ld	s3,8(sp)
    80003c4a:	6145                	addi	sp,sp,48
    80003c4c:	8082                	ret
    virtio_disk_rw(b, 0);
    80003c4e:	4581                	li	a1,0
    80003c50:	8526                	mv	a0,s1
    80003c52:	00003097          	auipc	ra,0x3
    80003c56:	fd4080e7          	jalr	-44(ra) # 80006c26 <virtio_disk_rw>
    b->valid = 1;
    80003c5a:	4785                	li	a5,1
    80003c5c:	c09c                	sw	a5,0(s1)
  return b;
    80003c5e:	b7c5                	j	80003c3e <bread+0xd0>

0000000080003c60 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003c60:	1101                	addi	sp,sp,-32
    80003c62:	ec06                	sd	ra,24(sp)
    80003c64:	e822                	sd	s0,16(sp)
    80003c66:	e426                	sd	s1,8(sp)
    80003c68:	1000                	addi	s0,sp,32
    80003c6a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c6c:	0541                	addi	a0,a0,16
    80003c6e:	00001097          	auipc	ra,0x1
    80003c72:	46c080e7          	jalr	1132(ra) # 800050da <holdingsleep>
    80003c76:	cd01                	beqz	a0,80003c8e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c78:	4585                	li	a1,1
    80003c7a:	8526                	mv	a0,s1
    80003c7c:	00003097          	auipc	ra,0x3
    80003c80:	faa080e7          	jalr	-86(ra) # 80006c26 <virtio_disk_rw>
}
    80003c84:	60e2                	ld	ra,24(sp)
    80003c86:	6442                	ld	s0,16(sp)
    80003c88:	64a2                	ld	s1,8(sp)
    80003c8a:	6105                	addi	sp,sp,32
    80003c8c:	8082                	ret
    panic("bwrite");
    80003c8e:	00005517          	auipc	a0,0x5
    80003c92:	8f250513          	addi	a0,a0,-1806 # 80008580 <syscalls+0x110>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	894080e7          	jalr	-1900(ra) # 8000052a <panic>

0000000080003c9e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c9e:	1101                	addi	sp,sp,-32
    80003ca0:	ec06                	sd	ra,24(sp)
    80003ca2:	e822                	sd	s0,16(sp)
    80003ca4:	e426                	sd	s1,8(sp)
    80003ca6:	e04a                	sd	s2,0(sp)
    80003ca8:	1000                	addi	s0,sp,32
    80003caa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003cac:	01050913          	addi	s2,a0,16
    80003cb0:	854a                	mv	a0,s2
    80003cb2:	00001097          	auipc	ra,0x1
    80003cb6:	428080e7          	jalr	1064(ra) # 800050da <holdingsleep>
    80003cba:	c92d                	beqz	a0,80003d2c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003cbc:	854a                	mv	a0,s2
    80003cbe:	00001097          	auipc	ra,0x1
    80003cc2:	3d8080e7          	jalr	984(ra) # 80005096 <releasesleep>

  acquire(&bcache.lock);
    80003cc6:	00030517          	auipc	a0,0x30
    80003cca:	a5250513          	addi	a0,a0,-1454 # 80033718 <bcache>
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	ef4080e7          	jalr	-268(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003cd6:	40bc                	lw	a5,64(s1)
    80003cd8:	37fd                	addiw	a5,a5,-1
    80003cda:	0007871b          	sext.w	a4,a5
    80003cde:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003ce0:	eb05                	bnez	a4,80003d10 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003ce2:	68bc                	ld	a5,80(s1)
    80003ce4:	64b8                	ld	a4,72(s1)
    80003ce6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003ce8:	64bc                	ld	a5,72(s1)
    80003cea:	68b8                	ld	a4,80(s1)
    80003cec:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003cee:	00038797          	auipc	a5,0x38
    80003cf2:	a2a78793          	addi	a5,a5,-1494 # 8003b718 <bcache+0x8000>
    80003cf6:	2b87b703          	ld	a4,696(a5)
    80003cfa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003cfc:	00038717          	auipc	a4,0x38
    80003d00:	c8470713          	addi	a4,a4,-892 # 8003b980 <bcache+0x8268>
    80003d04:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003d06:	2b87b703          	ld	a4,696(a5)
    80003d0a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003d0c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003d10:	00030517          	auipc	a0,0x30
    80003d14:	a0850513          	addi	a0,a0,-1528 # 80033718 <bcache>
    80003d18:	ffffd097          	auipc	ra,0xffffd
    80003d1c:	f70080e7          	jalr	-144(ra) # 80000c88 <release>
}
    80003d20:	60e2                	ld	ra,24(sp)
    80003d22:	6442                	ld	s0,16(sp)
    80003d24:	64a2                	ld	s1,8(sp)
    80003d26:	6902                	ld	s2,0(sp)
    80003d28:	6105                	addi	sp,sp,32
    80003d2a:	8082                	ret
    panic("brelse");
    80003d2c:	00005517          	auipc	a0,0x5
    80003d30:	85c50513          	addi	a0,a0,-1956 # 80008588 <syscalls+0x118>
    80003d34:	ffffc097          	auipc	ra,0xffffc
    80003d38:	7f6080e7          	jalr	2038(ra) # 8000052a <panic>

0000000080003d3c <bpin>:

void
bpin(struct buf *b) {
    80003d3c:	1101                	addi	sp,sp,-32
    80003d3e:	ec06                	sd	ra,24(sp)
    80003d40:	e822                	sd	s0,16(sp)
    80003d42:	e426                	sd	s1,8(sp)
    80003d44:	1000                	addi	s0,sp,32
    80003d46:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d48:	00030517          	auipc	a0,0x30
    80003d4c:	9d050513          	addi	a0,a0,-1584 # 80033718 <bcache>
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	e72080e7          	jalr	-398(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003d58:	40bc                	lw	a5,64(s1)
    80003d5a:	2785                	addiw	a5,a5,1
    80003d5c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d5e:	00030517          	auipc	a0,0x30
    80003d62:	9ba50513          	addi	a0,a0,-1606 # 80033718 <bcache>
    80003d66:	ffffd097          	auipc	ra,0xffffd
    80003d6a:	f22080e7          	jalr	-222(ra) # 80000c88 <release>
}
    80003d6e:	60e2                	ld	ra,24(sp)
    80003d70:	6442                	ld	s0,16(sp)
    80003d72:	64a2                	ld	s1,8(sp)
    80003d74:	6105                	addi	sp,sp,32
    80003d76:	8082                	ret

0000000080003d78 <bunpin>:

void
bunpin(struct buf *b) {
    80003d78:	1101                	addi	sp,sp,-32
    80003d7a:	ec06                	sd	ra,24(sp)
    80003d7c:	e822                	sd	s0,16(sp)
    80003d7e:	e426                	sd	s1,8(sp)
    80003d80:	1000                	addi	s0,sp,32
    80003d82:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d84:	00030517          	auipc	a0,0x30
    80003d88:	99450513          	addi	a0,a0,-1644 # 80033718 <bcache>
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	e36080e7          	jalr	-458(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003d94:	40bc                	lw	a5,64(s1)
    80003d96:	37fd                	addiw	a5,a5,-1
    80003d98:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d9a:	00030517          	auipc	a0,0x30
    80003d9e:	97e50513          	addi	a0,a0,-1666 # 80033718 <bcache>
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	ee6080e7          	jalr	-282(ra) # 80000c88 <release>
}
    80003daa:	60e2                	ld	ra,24(sp)
    80003dac:	6442                	ld	s0,16(sp)
    80003dae:	64a2                	ld	s1,8(sp)
    80003db0:	6105                	addi	sp,sp,32
    80003db2:	8082                	ret

0000000080003db4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003db4:	1101                	addi	sp,sp,-32
    80003db6:	ec06                	sd	ra,24(sp)
    80003db8:	e822                	sd	s0,16(sp)
    80003dba:	e426                	sd	s1,8(sp)
    80003dbc:	e04a                	sd	s2,0(sp)
    80003dbe:	1000                	addi	s0,sp,32
    80003dc0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003dc2:	00d5d59b          	srliw	a1,a1,0xd
    80003dc6:	00038797          	auipc	a5,0x38
    80003dca:	02e7a783          	lw	a5,46(a5) # 8003bdf4 <sb+0x1c>
    80003dce:	9dbd                	addw	a1,a1,a5
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	d9e080e7          	jalr	-610(ra) # 80003b6e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003dd8:	0074f713          	andi	a4,s1,7
    80003ddc:	4785                	li	a5,1
    80003dde:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003de2:	14ce                	slli	s1,s1,0x33
    80003de4:	90d9                	srli	s1,s1,0x36
    80003de6:	00950733          	add	a4,a0,s1
    80003dea:	05874703          	lbu	a4,88(a4)
    80003dee:	00e7f6b3          	and	a3,a5,a4
    80003df2:	c69d                	beqz	a3,80003e20 <bfree+0x6c>
    80003df4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003df6:	94aa                	add	s1,s1,a0
    80003df8:	fff7c793          	not	a5,a5
    80003dfc:	8ff9                	and	a5,a5,a4
    80003dfe:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003e02:	00001097          	auipc	ra,0x1
    80003e06:	11e080e7          	jalr	286(ra) # 80004f20 <log_write>
  brelse(bp);
    80003e0a:	854a                	mv	a0,s2
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	e92080e7          	jalr	-366(ra) # 80003c9e <brelse>
}
    80003e14:	60e2                	ld	ra,24(sp)
    80003e16:	6442                	ld	s0,16(sp)
    80003e18:	64a2                	ld	s1,8(sp)
    80003e1a:	6902                	ld	s2,0(sp)
    80003e1c:	6105                	addi	sp,sp,32
    80003e1e:	8082                	ret
    panic("freeing free block");
    80003e20:	00004517          	auipc	a0,0x4
    80003e24:	77050513          	addi	a0,a0,1904 # 80008590 <syscalls+0x120>
    80003e28:	ffffc097          	auipc	ra,0xffffc
    80003e2c:	702080e7          	jalr	1794(ra) # 8000052a <panic>

0000000080003e30 <balloc>:
{
    80003e30:	711d                	addi	sp,sp,-96
    80003e32:	ec86                	sd	ra,88(sp)
    80003e34:	e8a2                	sd	s0,80(sp)
    80003e36:	e4a6                	sd	s1,72(sp)
    80003e38:	e0ca                	sd	s2,64(sp)
    80003e3a:	fc4e                	sd	s3,56(sp)
    80003e3c:	f852                	sd	s4,48(sp)
    80003e3e:	f456                	sd	s5,40(sp)
    80003e40:	f05a                	sd	s6,32(sp)
    80003e42:	ec5e                	sd	s7,24(sp)
    80003e44:	e862                	sd	s8,16(sp)
    80003e46:	e466                	sd	s9,8(sp)
    80003e48:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003e4a:	00038797          	auipc	a5,0x38
    80003e4e:	f927a783          	lw	a5,-110(a5) # 8003bddc <sb+0x4>
    80003e52:	cbd1                	beqz	a5,80003ee6 <balloc+0xb6>
    80003e54:	8baa                	mv	s7,a0
    80003e56:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003e58:	00038b17          	auipc	s6,0x38
    80003e5c:	f80b0b13          	addi	s6,s6,-128 # 8003bdd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e60:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003e62:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e64:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003e66:	6c89                	lui	s9,0x2
    80003e68:	a831                	j	80003e84 <balloc+0x54>
    brelse(bp);
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	e32080e7          	jalr	-462(ra) # 80003c9e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003e74:	015c87bb          	addw	a5,s9,s5
    80003e78:	00078a9b          	sext.w	s5,a5
    80003e7c:	004b2703          	lw	a4,4(s6)
    80003e80:	06eaf363          	bgeu	s5,a4,80003ee6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003e84:	41fad79b          	sraiw	a5,s5,0x1f
    80003e88:	0137d79b          	srliw	a5,a5,0x13
    80003e8c:	015787bb          	addw	a5,a5,s5
    80003e90:	40d7d79b          	sraiw	a5,a5,0xd
    80003e94:	01cb2583          	lw	a1,28(s6)
    80003e98:	9dbd                	addw	a1,a1,a5
    80003e9a:	855e                	mv	a0,s7
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	cd2080e7          	jalr	-814(ra) # 80003b6e <bread>
    80003ea4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ea6:	004b2503          	lw	a0,4(s6)
    80003eaa:	000a849b          	sext.w	s1,s5
    80003eae:	8662                	mv	a2,s8
    80003eb0:	faa4fde3          	bgeu	s1,a0,80003e6a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003eb4:	41f6579b          	sraiw	a5,a2,0x1f
    80003eb8:	01d7d69b          	srliw	a3,a5,0x1d
    80003ebc:	00c6873b          	addw	a4,a3,a2
    80003ec0:	00777793          	andi	a5,a4,7
    80003ec4:	9f95                	subw	a5,a5,a3
    80003ec6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003eca:	4037571b          	sraiw	a4,a4,0x3
    80003ece:	00e906b3          	add	a3,s2,a4
    80003ed2:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    80003ed6:	00d7f5b3          	and	a1,a5,a3
    80003eda:	cd91                	beqz	a1,80003ef6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003edc:	2605                	addiw	a2,a2,1
    80003ede:	2485                	addiw	s1,s1,1
    80003ee0:	fd4618e3          	bne	a2,s4,80003eb0 <balloc+0x80>
    80003ee4:	b759                	j	80003e6a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003ee6:	00004517          	auipc	a0,0x4
    80003eea:	6c250513          	addi	a0,a0,1730 # 800085a8 <syscalls+0x138>
    80003eee:	ffffc097          	auipc	ra,0xffffc
    80003ef2:	63c080e7          	jalr	1596(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003ef6:	974a                	add	a4,a4,s2
    80003ef8:	8fd5                	or	a5,a5,a3
    80003efa:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003efe:	854a                	mv	a0,s2
    80003f00:	00001097          	auipc	ra,0x1
    80003f04:	020080e7          	jalr	32(ra) # 80004f20 <log_write>
        brelse(bp);
    80003f08:	854a                	mv	a0,s2
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	d94080e7          	jalr	-620(ra) # 80003c9e <brelse>
  bp = bread(dev, bno);
    80003f12:	85a6                	mv	a1,s1
    80003f14:	855e                	mv	a0,s7
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	c58080e7          	jalr	-936(ra) # 80003b6e <bread>
    80003f1e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003f20:	40000613          	li	a2,1024
    80003f24:	4581                	li	a1,0
    80003f26:	05850513          	addi	a0,a0,88
    80003f2a:	ffffd097          	auipc	ra,0xffffd
    80003f2e:	db8080e7          	jalr	-584(ra) # 80000ce2 <memset>
  log_write(bp);
    80003f32:	854a                	mv	a0,s2
    80003f34:	00001097          	auipc	ra,0x1
    80003f38:	fec080e7          	jalr	-20(ra) # 80004f20 <log_write>
  brelse(bp);
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	d60080e7          	jalr	-672(ra) # 80003c9e <brelse>
}
    80003f46:	8526                	mv	a0,s1
    80003f48:	60e6                	ld	ra,88(sp)
    80003f4a:	6446                	ld	s0,80(sp)
    80003f4c:	64a6                	ld	s1,72(sp)
    80003f4e:	6906                	ld	s2,64(sp)
    80003f50:	79e2                	ld	s3,56(sp)
    80003f52:	7a42                	ld	s4,48(sp)
    80003f54:	7aa2                	ld	s5,40(sp)
    80003f56:	7b02                	ld	s6,32(sp)
    80003f58:	6be2                	ld	s7,24(sp)
    80003f5a:	6c42                	ld	s8,16(sp)
    80003f5c:	6ca2                	ld	s9,8(sp)
    80003f5e:	6125                	addi	sp,sp,96
    80003f60:	8082                	ret

0000000080003f62 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003f62:	7179                	addi	sp,sp,-48
    80003f64:	f406                	sd	ra,40(sp)
    80003f66:	f022                	sd	s0,32(sp)
    80003f68:	ec26                	sd	s1,24(sp)
    80003f6a:	e84a                	sd	s2,16(sp)
    80003f6c:	e44e                	sd	s3,8(sp)
    80003f6e:	e052                	sd	s4,0(sp)
    80003f70:	1800                	addi	s0,sp,48
    80003f72:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003f74:	47ad                	li	a5,11
    80003f76:	04b7fe63          	bgeu	a5,a1,80003fd2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003f7a:	ff45849b          	addiw	s1,a1,-12
    80003f7e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003f82:	0ff00793          	li	a5,255
    80003f86:	0ae7e463          	bltu	a5,a4,8000402e <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003f8a:	08052583          	lw	a1,128(a0)
    80003f8e:	c5b5                	beqz	a1,80003ffa <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003f90:	00092503          	lw	a0,0(s2)
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	bda080e7          	jalr	-1062(ra) # 80003b6e <bread>
    80003f9c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003f9e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003fa2:	02049713          	slli	a4,s1,0x20
    80003fa6:	01e75593          	srli	a1,a4,0x1e
    80003faa:	00b784b3          	add	s1,a5,a1
    80003fae:	0004a983          	lw	s3,0(s1)
    80003fb2:	04098e63          	beqz	s3,8000400e <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003fb6:	8552                	mv	a0,s4
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	ce6080e7          	jalr	-794(ra) # 80003c9e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003fc0:	854e                	mv	a0,s3
    80003fc2:	70a2                	ld	ra,40(sp)
    80003fc4:	7402                	ld	s0,32(sp)
    80003fc6:	64e2                	ld	s1,24(sp)
    80003fc8:	6942                	ld	s2,16(sp)
    80003fca:	69a2                	ld	s3,8(sp)
    80003fcc:	6a02                	ld	s4,0(sp)
    80003fce:	6145                	addi	sp,sp,48
    80003fd0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003fd2:	02059793          	slli	a5,a1,0x20
    80003fd6:	01e7d593          	srli	a1,a5,0x1e
    80003fda:	00b504b3          	add	s1,a0,a1
    80003fde:	0504a983          	lw	s3,80(s1)
    80003fe2:	fc099fe3          	bnez	s3,80003fc0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003fe6:	4108                	lw	a0,0(a0)
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	e48080e7          	jalr	-440(ra) # 80003e30 <balloc>
    80003ff0:	0005099b          	sext.w	s3,a0
    80003ff4:	0534a823          	sw	s3,80(s1)
    80003ff8:	b7e1                	j	80003fc0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003ffa:	4108                	lw	a0,0(a0)
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	e34080e7          	jalr	-460(ra) # 80003e30 <balloc>
    80004004:	0005059b          	sext.w	a1,a0
    80004008:	08b92023          	sw	a1,128(s2)
    8000400c:	b751                	j	80003f90 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000400e:	00092503          	lw	a0,0(s2)
    80004012:	00000097          	auipc	ra,0x0
    80004016:	e1e080e7          	jalr	-482(ra) # 80003e30 <balloc>
    8000401a:	0005099b          	sext.w	s3,a0
    8000401e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80004022:	8552                	mv	a0,s4
    80004024:	00001097          	auipc	ra,0x1
    80004028:	efc080e7          	jalr	-260(ra) # 80004f20 <log_write>
    8000402c:	b769                	j	80003fb6 <bmap+0x54>
  panic("bmap: out of range");
    8000402e:	00004517          	auipc	a0,0x4
    80004032:	59250513          	addi	a0,a0,1426 # 800085c0 <syscalls+0x150>
    80004036:	ffffc097          	auipc	ra,0xffffc
    8000403a:	4f4080e7          	jalr	1268(ra) # 8000052a <panic>

000000008000403e <iget>:
{
    8000403e:	7179                	addi	sp,sp,-48
    80004040:	f406                	sd	ra,40(sp)
    80004042:	f022                	sd	s0,32(sp)
    80004044:	ec26                	sd	s1,24(sp)
    80004046:	e84a                	sd	s2,16(sp)
    80004048:	e44e                	sd	s3,8(sp)
    8000404a:	e052                	sd	s4,0(sp)
    8000404c:	1800                	addi	s0,sp,48
    8000404e:	89aa                	mv	s3,a0
    80004050:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004052:	00038517          	auipc	a0,0x38
    80004056:	da650513          	addi	a0,a0,-602 # 8003bdf8 <itable>
    8000405a:	ffffd097          	auipc	ra,0xffffd
    8000405e:	b68080e7          	jalr	-1176(ra) # 80000bc2 <acquire>
  empty = 0;
    80004062:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004064:	00038497          	auipc	s1,0x38
    80004068:	dac48493          	addi	s1,s1,-596 # 8003be10 <itable+0x18>
    8000406c:	0003a697          	auipc	a3,0x3a
    80004070:	83468693          	addi	a3,a3,-1996 # 8003d8a0 <log>
    80004074:	a039                	j	80004082 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004076:	02090b63          	beqz	s2,800040ac <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000407a:	08848493          	addi	s1,s1,136
    8000407e:	02d48a63          	beq	s1,a3,800040b2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004082:	449c                	lw	a5,8(s1)
    80004084:	fef059e3          	blez	a5,80004076 <iget+0x38>
    80004088:	4098                	lw	a4,0(s1)
    8000408a:	ff3716e3          	bne	a4,s3,80004076 <iget+0x38>
    8000408e:	40d8                	lw	a4,4(s1)
    80004090:	ff4713e3          	bne	a4,s4,80004076 <iget+0x38>
      ip->ref++;
    80004094:	2785                	addiw	a5,a5,1
    80004096:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004098:	00038517          	auipc	a0,0x38
    8000409c:	d6050513          	addi	a0,a0,-672 # 8003bdf8 <itable>
    800040a0:	ffffd097          	auipc	ra,0xffffd
    800040a4:	be8080e7          	jalr	-1048(ra) # 80000c88 <release>
      return ip;
    800040a8:	8926                	mv	s2,s1
    800040aa:	a03d                	j	800040d8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800040ac:	f7f9                	bnez	a5,8000407a <iget+0x3c>
    800040ae:	8926                	mv	s2,s1
    800040b0:	b7e9                	j	8000407a <iget+0x3c>
  if(empty == 0)
    800040b2:	02090c63          	beqz	s2,800040ea <iget+0xac>
  ip->dev = dev;
    800040b6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800040ba:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800040be:	4785                	li	a5,1
    800040c0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800040c4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800040c8:	00038517          	auipc	a0,0x38
    800040cc:	d3050513          	addi	a0,a0,-720 # 8003bdf8 <itable>
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	bb8080e7          	jalr	-1096(ra) # 80000c88 <release>
}
    800040d8:	854a                	mv	a0,s2
    800040da:	70a2                	ld	ra,40(sp)
    800040dc:	7402                	ld	s0,32(sp)
    800040de:	64e2                	ld	s1,24(sp)
    800040e0:	6942                	ld	s2,16(sp)
    800040e2:	69a2                	ld	s3,8(sp)
    800040e4:	6a02                	ld	s4,0(sp)
    800040e6:	6145                	addi	sp,sp,48
    800040e8:	8082                	ret
    panic("iget: no inodes");
    800040ea:	00004517          	auipc	a0,0x4
    800040ee:	4ee50513          	addi	a0,a0,1262 # 800085d8 <syscalls+0x168>
    800040f2:	ffffc097          	auipc	ra,0xffffc
    800040f6:	438080e7          	jalr	1080(ra) # 8000052a <panic>

00000000800040fa <fsinit>:
fsinit(int dev) {
    800040fa:	7179                	addi	sp,sp,-48
    800040fc:	f406                	sd	ra,40(sp)
    800040fe:	f022                	sd	s0,32(sp)
    80004100:	ec26                	sd	s1,24(sp)
    80004102:	e84a                	sd	s2,16(sp)
    80004104:	e44e                	sd	s3,8(sp)
    80004106:	1800                	addi	s0,sp,48
    80004108:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000410a:	4585                	li	a1,1
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	a62080e7          	jalr	-1438(ra) # 80003b6e <bread>
    80004114:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004116:	00038997          	auipc	s3,0x38
    8000411a:	cc298993          	addi	s3,s3,-830 # 8003bdd8 <sb>
    8000411e:	02000613          	li	a2,32
    80004122:	05850593          	addi	a1,a0,88
    80004126:	854e                	mv	a0,s3
    80004128:	ffffd097          	auipc	ra,0xffffd
    8000412c:	c16080e7          	jalr	-1002(ra) # 80000d3e <memmove>
  brelse(bp);
    80004130:	8526                	mv	a0,s1
    80004132:	00000097          	auipc	ra,0x0
    80004136:	b6c080e7          	jalr	-1172(ra) # 80003c9e <brelse>
  if(sb.magic != FSMAGIC)
    8000413a:	0009a703          	lw	a4,0(s3)
    8000413e:	102037b7          	lui	a5,0x10203
    80004142:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004146:	02f71263          	bne	a4,a5,8000416a <fsinit+0x70>
  initlog(dev, &sb);
    8000414a:	00038597          	auipc	a1,0x38
    8000414e:	c8e58593          	addi	a1,a1,-882 # 8003bdd8 <sb>
    80004152:	854a                	mv	a0,s2
    80004154:	00001097          	auipc	ra,0x1
    80004158:	b4e080e7          	jalr	-1202(ra) # 80004ca2 <initlog>
}
    8000415c:	70a2                	ld	ra,40(sp)
    8000415e:	7402                	ld	s0,32(sp)
    80004160:	64e2                	ld	s1,24(sp)
    80004162:	6942                	ld	s2,16(sp)
    80004164:	69a2                	ld	s3,8(sp)
    80004166:	6145                	addi	sp,sp,48
    80004168:	8082                	ret
    panic("invalid file system");
    8000416a:	00004517          	auipc	a0,0x4
    8000416e:	47e50513          	addi	a0,a0,1150 # 800085e8 <syscalls+0x178>
    80004172:	ffffc097          	auipc	ra,0xffffc
    80004176:	3b8080e7          	jalr	952(ra) # 8000052a <panic>

000000008000417a <iinit>:
{
    8000417a:	7179                	addi	sp,sp,-48
    8000417c:	f406                	sd	ra,40(sp)
    8000417e:	f022                	sd	s0,32(sp)
    80004180:	ec26                	sd	s1,24(sp)
    80004182:	e84a                	sd	s2,16(sp)
    80004184:	e44e                	sd	s3,8(sp)
    80004186:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004188:	00004597          	auipc	a1,0x4
    8000418c:	47858593          	addi	a1,a1,1144 # 80008600 <syscalls+0x190>
    80004190:	00038517          	auipc	a0,0x38
    80004194:	c6850513          	addi	a0,a0,-920 # 8003bdf8 <itable>
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	99a080e7          	jalr	-1638(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800041a0:	00038497          	auipc	s1,0x38
    800041a4:	c8048493          	addi	s1,s1,-896 # 8003be20 <itable+0x28>
    800041a8:	00039997          	auipc	s3,0x39
    800041ac:	70898993          	addi	s3,s3,1800 # 8003d8b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800041b0:	00004917          	auipc	s2,0x4
    800041b4:	45890913          	addi	s2,s2,1112 # 80008608 <syscalls+0x198>
    800041b8:	85ca                	mv	a1,s2
    800041ba:	8526                	mv	a0,s1
    800041bc:	00001097          	auipc	ra,0x1
    800041c0:	e4a080e7          	jalr	-438(ra) # 80005006 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800041c4:	08848493          	addi	s1,s1,136
    800041c8:	ff3498e3          	bne	s1,s3,800041b8 <iinit+0x3e>
}
    800041cc:	70a2                	ld	ra,40(sp)
    800041ce:	7402                	ld	s0,32(sp)
    800041d0:	64e2                	ld	s1,24(sp)
    800041d2:	6942                	ld	s2,16(sp)
    800041d4:	69a2                	ld	s3,8(sp)
    800041d6:	6145                	addi	sp,sp,48
    800041d8:	8082                	ret

00000000800041da <ialloc>:
{
    800041da:	715d                	addi	sp,sp,-80
    800041dc:	e486                	sd	ra,72(sp)
    800041de:	e0a2                	sd	s0,64(sp)
    800041e0:	fc26                	sd	s1,56(sp)
    800041e2:	f84a                	sd	s2,48(sp)
    800041e4:	f44e                	sd	s3,40(sp)
    800041e6:	f052                	sd	s4,32(sp)
    800041e8:	ec56                	sd	s5,24(sp)
    800041ea:	e85a                	sd	s6,16(sp)
    800041ec:	e45e                	sd	s7,8(sp)
    800041ee:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800041f0:	00038717          	auipc	a4,0x38
    800041f4:	bf472703          	lw	a4,-1036(a4) # 8003bde4 <sb+0xc>
    800041f8:	4785                	li	a5,1
    800041fa:	04e7fa63          	bgeu	a5,a4,8000424e <ialloc+0x74>
    800041fe:	8aaa                	mv	s5,a0
    80004200:	8bae                	mv	s7,a1
    80004202:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004204:	00038a17          	auipc	s4,0x38
    80004208:	bd4a0a13          	addi	s4,s4,-1068 # 8003bdd8 <sb>
    8000420c:	00048b1b          	sext.w	s6,s1
    80004210:	0044d793          	srli	a5,s1,0x4
    80004214:	018a2583          	lw	a1,24(s4)
    80004218:	9dbd                	addw	a1,a1,a5
    8000421a:	8556                	mv	a0,s5
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	952080e7          	jalr	-1710(ra) # 80003b6e <bread>
    80004224:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004226:	05850993          	addi	s3,a0,88
    8000422a:	00f4f793          	andi	a5,s1,15
    8000422e:	079a                	slli	a5,a5,0x6
    80004230:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004232:	00099783          	lh	a5,0(s3)
    80004236:	c785                	beqz	a5,8000425e <ialloc+0x84>
    brelse(bp);
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	a66080e7          	jalr	-1434(ra) # 80003c9e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004240:	0485                	addi	s1,s1,1
    80004242:	00ca2703          	lw	a4,12(s4)
    80004246:	0004879b          	sext.w	a5,s1
    8000424a:	fce7e1e3          	bltu	a5,a4,8000420c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000424e:	00004517          	auipc	a0,0x4
    80004252:	3c250513          	addi	a0,a0,962 # 80008610 <syscalls+0x1a0>
    80004256:	ffffc097          	auipc	ra,0xffffc
    8000425a:	2d4080e7          	jalr	724(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    8000425e:	04000613          	li	a2,64
    80004262:	4581                	li	a1,0
    80004264:	854e                	mv	a0,s3
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	a7c080e7          	jalr	-1412(ra) # 80000ce2 <memset>
      dip->type = type;
    8000426e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004272:	854a                	mv	a0,s2
    80004274:	00001097          	auipc	ra,0x1
    80004278:	cac080e7          	jalr	-852(ra) # 80004f20 <log_write>
      brelse(bp);
    8000427c:	854a                	mv	a0,s2
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	a20080e7          	jalr	-1504(ra) # 80003c9e <brelse>
      return iget(dev, inum);
    80004286:	85da                	mv	a1,s6
    80004288:	8556                	mv	a0,s5
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	db4080e7          	jalr	-588(ra) # 8000403e <iget>
}
    80004292:	60a6                	ld	ra,72(sp)
    80004294:	6406                	ld	s0,64(sp)
    80004296:	74e2                	ld	s1,56(sp)
    80004298:	7942                	ld	s2,48(sp)
    8000429a:	79a2                	ld	s3,40(sp)
    8000429c:	7a02                	ld	s4,32(sp)
    8000429e:	6ae2                	ld	s5,24(sp)
    800042a0:	6b42                	ld	s6,16(sp)
    800042a2:	6ba2                	ld	s7,8(sp)
    800042a4:	6161                	addi	sp,sp,80
    800042a6:	8082                	ret

00000000800042a8 <iupdate>:
{
    800042a8:	1101                	addi	sp,sp,-32
    800042aa:	ec06                	sd	ra,24(sp)
    800042ac:	e822                	sd	s0,16(sp)
    800042ae:	e426                	sd	s1,8(sp)
    800042b0:	e04a                	sd	s2,0(sp)
    800042b2:	1000                	addi	s0,sp,32
    800042b4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042b6:	415c                	lw	a5,4(a0)
    800042b8:	0047d79b          	srliw	a5,a5,0x4
    800042bc:	00038597          	auipc	a1,0x38
    800042c0:	b345a583          	lw	a1,-1228(a1) # 8003bdf0 <sb+0x18>
    800042c4:	9dbd                	addw	a1,a1,a5
    800042c6:	4108                	lw	a0,0(a0)
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	8a6080e7          	jalr	-1882(ra) # 80003b6e <bread>
    800042d0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800042d2:	05850793          	addi	a5,a0,88
    800042d6:	40c8                	lw	a0,4(s1)
    800042d8:	893d                	andi	a0,a0,15
    800042da:	051a                	slli	a0,a0,0x6
    800042dc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800042de:	04449703          	lh	a4,68(s1)
    800042e2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800042e6:	04649703          	lh	a4,70(s1)
    800042ea:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800042ee:	04849703          	lh	a4,72(s1)
    800042f2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800042f6:	04a49703          	lh	a4,74(s1)
    800042fa:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800042fe:	44f8                	lw	a4,76(s1)
    80004300:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004302:	03400613          	li	a2,52
    80004306:	05048593          	addi	a1,s1,80
    8000430a:	0531                	addi	a0,a0,12
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	a32080e7          	jalr	-1486(ra) # 80000d3e <memmove>
  log_write(bp);
    80004314:	854a                	mv	a0,s2
    80004316:	00001097          	auipc	ra,0x1
    8000431a:	c0a080e7          	jalr	-1014(ra) # 80004f20 <log_write>
  brelse(bp);
    8000431e:	854a                	mv	a0,s2
    80004320:	00000097          	auipc	ra,0x0
    80004324:	97e080e7          	jalr	-1666(ra) # 80003c9e <brelse>
}
    80004328:	60e2                	ld	ra,24(sp)
    8000432a:	6442                	ld	s0,16(sp)
    8000432c:	64a2                	ld	s1,8(sp)
    8000432e:	6902                	ld	s2,0(sp)
    80004330:	6105                	addi	sp,sp,32
    80004332:	8082                	ret

0000000080004334 <idup>:
{
    80004334:	1101                	addi	sp,sp,-32
    80004336:	ec06                	sd	ra,24(sp)
    80004338:	e822                	sd	s0,16(sp)
    8000433a:	e426                	sd	s1,8(sp)
    8000433c:	1000                	addi	s0,sp,32
    8000433e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004340:	00038517          	auipc	a0,0x38
    80004344:	ab850513          	addi	a0,a0,-1352 # 8003bdf8 <itable>
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	87a080e7          	jalr	-1926(ra) # 80000bc2 <acquire>
  ip->ref++;
    80004350:	449c                	lw	a5,8(s1)
    80004352:	2785                	addiw	a5,a5,1
    80004354:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004356:	00038517          	auipc	a0,0x38
    8000435a:	aa250513          	addi	a0,a0,-1374 # 8003bdf8 <itable>
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	92a080e7          	jalr	-1750(ra) # 80000c88 <release>
}
    80004366:	8526                	mv	a0,s1
    80004368:	60e2                	ld	ra,24(sp)
    8000436a:	6442                	ld	s0,16(sp)
    8000436c:	64a2                	ld	s1,8(sp)
    8000436e:	6105                	addi	sp,sp,32
    80004370:	8082                	ret

0000000080004372 <ilock>:
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	e426                	sd	s1,8(sp)
    8000437a:	e04a                	sd	s2,0(sp)
    8000437c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000437e:	c115                	beqz	a0,800043a2 <ilock+0x30>
    80004380:	84aa                	mv	s1,a0
    80004382:	451c                	lw	a5,8(a0)
    80004384:	00f05f63          	blez	a5,800043a2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004388:	0541                	addi	a0,a0,16
    8000438a:	00001097          	auipc	ra,0x1
    8000438e:	cb6080e7          	jalr	-842(ra) # 80005040 <acquiresleep>
  if(ip->valid == 0){
    80004392:	40bc                	lw	a5,64(s1)
    80004394:	cf99                	beqz	a5,800043b2 <ilock+0x40>
}
    80004396:	60e2                	ld	ra,24(sp)
    80004398:	6442                	ld	s0,16(sp)
    8000439a:	64a2                	ld	s1,8(sp)
    8000439c:	6902                	ld	s2,0(sp)
    8000439e:	6105                	addi	sp,sp,32
    800043a0:	8082                	ret
    panic("ilock");
    800043a2:	00004517          	auipc	a0,0x4
    800043a6:	28650513          	addi	a0,a0,646 # 80008628 <syscalls+0x1b8>
    800043aa:	ffffc097          	auipc	ra,0xffffc
    800043ae:	180080e7          	jalr	384(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800043b2:	40dc                	lw	a5,4(s1)
    800043b4:	0047d79b          	srliw	a5,a5,0x4
    800043b8:	00038597          	auipc	a1,0x38
    800043bc:	a385a583          	lw	a1,-1480(a1) # 8003bdf0 <sb+0x18>
    800043c0:	9dbd                	addw	a1,a1,a5
    800043c2:	4088                	lw	a0,0(s1)
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	7aa080e7          	jalr	1962(ra) # 80003b6e <bread>
    800043cc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800043ce:	05850593          	addi	a1,a0,88
    800043d2:	40dc                	lw	a5,4(s1)
    800043d4:	8bbd                	andi	a5,a5,15
    800043d6:	079a                	slli	a5,a5,0x6
    800043d8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800043da:	00059783          	lh	a5,0(a1)
    800043de:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800043e2:	00259783          	lh	a5,2(a1)
    800043e6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800043ea:	00459783          	lh	a5,4(a1)
    800043ee:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800043f2:	00659783          	lh	a5,6(a1)
    800043f6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800043fa:	459c                	lw	a5,8(a1)
    800043fc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800043fe:	03400613          	li	a2,52
    80004402:	05b1                	addi	a1,a1,12
    80004404:	05048513          	addi	a0,s1,80
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	936080e7          	jalr	-1738(ra) # 80000d3e <memmove>
    brelse(bp);
    80004410:	854a                	mv	a0,s2
    80004412:	00000097          	auipc	ra,0x0
    80004416:	88c080e7          	jalr	-1908(ra) # 80003c9e <brelse>
    ip->valid = 1;
    8000441a:	4785                	li	a5,1
    8000441c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000441e:	04449783          	lh	a5,68(s1)
    80004422:	fbb5                	bnez	a5,80004396 <ilock+0x24>
      panic("ilock: no type");
    80004424:	00004517          	auipc	a0,0x4
    80004428:	20c50513          	addi	a0,a0,524 # 80008630 <syscalls+0x1c0>
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	0fe080e7          	jalr	254(ra) # 8000052a <panic>

0000000080004434 <iunlock>:
{
    80004434:	1101                	addi	sp,sp,-32
    80004436:	ec06                	sd	ra,24(sp)
    80004438:	e822                	sd	s0,16(sp)
    8000443a:	e426                	sd	s1,8(sp)
    8000443c:	e04a                	sd	s2,0(sp)
    8000443e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004440:	c905                	beqz	a0,80004470 <iunlock+0x3c>
    80004442:	84aa                	mv	s1,a0
    80004444:	01050913          	addi	s2,a0,16
    80004448:	854a                	mv	a0,s2
    8000444a:	00001097          	auipc	ra,0x1
    8000444e:	c90080e7          	jalr	-880(ra) # 800050da <holdingsleep>
    80004452:	cd19                	beqz	a0,80004470 <iunlock+0x3c>
    80004454:	449c                	lw	a5,8(s1)
    80004456:	00f05d63          	blez	a5,80004470 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000445a:	854a                	mv	a0,s2
    8000445c:	00001097          	auipc	ra,0x1
    80004460:	c3a080e7          	jalr	-966(ra) # 80005096 <releasesleep>
}
    80004464:	60e2                	ld	ra,24(sp)
    80004466:	6442                	ld	s0,16(sp)
    80004468:	64a2                	ld	s1,8(sp)
    8000446a:	6902                	ld	s2,0(sp)
    8000446c:	6105                	addi	sp,sp,32
    8000446e:	8082                	ret
    panic("iunlock");
    80004470:	00004517          	auipc	a0,0x4
    80004474:	1d050513          	addi	a0,a0,464 # 80008640 <syscalls+0x1d0>
    80004478:	ffffc097          	auipc	ra,0xffffc
    8000447c:	0b2080e7          	jalr	178(ra) # 8000052a <panic>

0000000080004480 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004480:	7179                	addi	sp,sp,-48
    80004482:	f406                	sd	ra,40(sp)
    80004484:	f022                	sd	s0,32(sp)
    80004486:	ec26                	sd	s1,24(sp)
    80004488:	e84a                	sd	s2,16(sp)
    8000448a:	e44e                	sd	s3,8(sp)
    8000448c:	e052                	sd	s4,0(sp)
    8000448e:	1800                	addi	s0,sp,48
    80004490:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004492:	05050493          	addi	s1,a0,80
    80004496:	08050913          	addi	s2,a0,128
    8000449a:	a021                	j	800044a2 <itrunc+0x22>
    8000449c:	0491                	addi	s1,s1,4
    8000449e:	01248d63          	beq	s1,s2,800044b8 <itrunc+0x38>
    if(ip->addrs[i]){
    800044a2:	408c                	lw	a1,0(s1)
    800044a4:	dde5                	beqz	a1,8000449c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800044a6:	0009a503          	lw	a0,0(s3)
    800044aa:	00000097          	auipc	ra,0x0
    800044ae:	90a080e7          	jalr	-1782(ra) # 80003db4 <bfree>
      ip->addrs[i] = 0;
    800044b2:	0004a023          	sw	zero,0(s1)
    800044b6:	b7dd                	j	8000449c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800044b8:	0809a583          	lw	a1,128(s3)
    800044bc:	e185                	bnez	a1,800044dc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800044be:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800044c2:	854e                	mv	a0,s3
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	de4080e7          	jalr	-540(ra) # 800042a8 <iupdate>
}
    800044cc:	70a2                	ld	ra,40(sp)
    800044ce:	7402                	ld	s0,32(sp)
    800044d0:	64e2                	ld	s1,24(sp)
    800044d2:	6942                	ld	s2,16(sp)
    800044d4:	69a2                	ld	s3,8(sp)
    800044d6:	6a02                	ld	s4,0(sp)
    800044d8:	6145                	addi	sp,sp,48
    800044da:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800044dc:	0009a503          	lw	a0,0(s3)
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	68e080e7          	jalr	1678(ra) # 80003b6e <bread>
    800044e8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800044ea:	05850493          	addi	s1,a0,88
    800044ee:	45850913          	addi	s2,a0,1112
    800044f2:	a021                	j	800044fa <itrunc+0x7a>
    800044f4:	0491                	addi	s1,s1,4
    800044f6:	01248b63          	beq	s1,s2,8000450c <itrunc+0x8c>
      if(a[j])
    800044fa:	408c                	lw	a1,0(s1)
    800044fc:	dde5                	beqz	a1,800044f4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800044fe:	0009a503          	lw	a0,0(s3)
    80004502:	00000097          	auipc	ra,0x0
    80004506:	8b2080e7          	jalr	-1870(ra) # 80003db4 <bfree>
    8000450a:	b7ed                	j	800044f4 <itrunc+0x74>
    brelse(bp);
    8000450c:	8552                	mv	a0,s4
    8000450e:	fffff097          	auipc	ra,0xfffff
    80004512:	790080e7          	jalr	1936(ra) # 80003c9e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004516:	0809a583          	lw	a1,128(s3)
    8000451a:	0009a503          	lw	a0,0(s3)
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	896080e7          	jalr	-1898(ra) # 80003db4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004526:	0809a023          	sw	zero,128(s3)
    8000452a:	bf51                	j	800044be <itrunc+0x3e>

000000008000452c <iput>:
{
    8000452c:	1101                	addi	sp,sp,-32
    8000452e:	ec06                	sd	ra,24(sp)
    80004530:	e822                	sd	s0,16(sp)
    80004532:	e426                	sd	s1,8(sp)
    80004534:	e04a                	sd	s2,0(sp)
    80004536:	1000                	addi	s0,sp,32
    80004538:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000453a:	00038517          	auipc	a0,0x38
    8000453e:	8be50513          	addi	a0,a0,-1858 # 8003bdf8 <itable>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	680080e7          	jalr	1664(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000454a:	4498                	lw	a4,8(s1)
    8000454c:	4785                	li	a5,1
    8000454e:	02f70363          	beq	a4,a5,80004574 <iput+0x48>
  ip->ref--;
    80004552:	449c                	lw	a5,8(s1)
    80004554:	37fd                	addiw	a5,a5,-1
    80004556:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004558:	00038517          	auipc	a0,0x38
    8000455c:	8a050513          	addi	a0,a0,-1888 # 8003bdf8 <itable>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	728080e7          	jalr	1832(ra) # 80000c88 <release>
}
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6902                	ld	s2,0(sp)
    80004570:	6105                	addi	sp,sp,32
    80004572:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004574:	40bc                	lw	a5,64(s1)
    80004576:	dff1                	beqz	a5,80004552 <iput+0x26>
    80004578:	04a49783          	lh	a5,74(s1)
    8000457c:	fbf9                	bnez	a5,80004552 <iput+0x26>
    acquiresleep(&ip->lock);
    8000457e:	01048913          	addi	s2,s1,16
    80004582:	854a                	mv	a0,s2
    80004584:	00001097          	auipc	ra,0x1
    80004588:	abc080e7          	jalr	-1348(ra) # 80005040 <acquiresleep>
    release(&itable.lock);
    8000458c:	00038517          	auipc	a0,0x38
    80004590:	86c50513          	addi	a0,a0,-1940 # 8003bdf8 <itable>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	6f4080e7          	jalr	1780(ra) # 80000c88 <release>
    itrunc(ip);
    8000459c:	8526                	mv	a0,s1
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	ee2080e7          	jalr	-286(ra) # 80004480 <itrunc>
    ip->type = 0;
    800045a6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800045aa:	8526                	mv	a0,s1
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	cfc080e7          	jalr	-772(ra) # 800042a8 <iupdate>
    ip->valid = 0;
    800045b4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800045b8:	854a                	mv	a0,s2
    800045ba:	00001097          	auipc	ra,0x1
    800045be:	adc080e7          	jalr	-1316(ra) # 80005096 <releasesleep>
    acquire(&itable.lock);
    800045c2:	00038517          	auipc	a0,0x38
    800045c6:	83650513          	addi	a0,a0,-1994 # 8003bdf8 <itable>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	5f8080e7          	jalr	1528(ra) # 80000bc2 <acquire>
    800045d2:	b741                	j	80004552 <iput+0x26>

00000000800045d4 <iunlockput>:
{
    800045d4:	1101                	addi	sp,sp,-32
    800045d6:	ec06                	sd	ra,24(sp)
    800045d8:	e822                	sd	s0,16(sp)
    800045da:	e426                	sd	s1,8(sp)
    800045dc:	1000                	addi	s0,sp,32
    800045de:	84aa                	mv	s1,a0
  iunlock(ip);
    800045e0:	00000097          	auipc	ra,0x0
    800045e4:	e54080e7          	jalr	-428(ra) # 80004434 <iunlock>
  iput(ip);
    800045e8:	8526                	mv	a0,s1
    800045ea:	00000097          	auipc	ra,0x0
    800045ee:	f42080e7          	jalr	-190(ra) # 8000452c <iput>
}
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6105                	addi	sp,sp,32
    800045fa:	8082                	ret

00000000800045fc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800045fc:	1141                	addi	sp,sp,-16
    800045fe:	e422                	sd	s0,8(sp)
    80004600:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004602:	411c                	lw	a5,0(a0)
    80004604:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004606:	415c                	lw	a5,4(a0)
    80004608:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000460a:	04451783          	lh	a5,68(a0)
    8000460e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004612:	04a51783          	lh	a5,74(a0)
    80004616:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000461a:	04c56783          	lwu	a5,76(a0)
    8000461e:	e99c                	sd	a5,16(a1)
}
    80004620:	6422                	ld	s0,8(sp)
    80004622:	0141                	addi	sp,sp,16
    80004624:	8082                	ret

0000000080004626 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004626:	457c                	lw	a5,76(a0)
    80004628:	0ed7e963          	bltu	a5,a3,8000471a <readi+0xf4>
{
    8000462c:	7159                	addi	sp,sp,-112
    8000462e:	f486                	sd	ra,104(sp)
    80004630:	f0a2                	sd	s0,96(sp)
    80004632:	eca6                	sd	s1,88(sp)
    80004634:	e8ca                	sd	s2,80(sp)
    80004636:	e4ce                	sd	s3,72(sp)
    80004638:	e0d2                	sd	s4,64(sp)
    8000463a:	fc56                	sd	s5,56(sp)
    8000463c:	f85a                	sd	s6,48(sp)
    8000463e:	f45e                	sd	s7,40(sp)
    80004640:	f062                	sd	s8,32(sp)
    80004642:	ec66                	sd	s9,24(sp)
    80004644:	e86a                	sd	s10,16(sp)
    80004646:	e46e                	sd	s11,8(sp)
    80004648:	1880                	addi	s0,sp,112
    8000464a:	8baa                	mv	s7,a0
    8000464c:	8c2e                	mv	s8,a1
    8000464e:	8ab2                	mv	s5,a2
    80004650:	84b6                	mv	s1,a3
    80004652:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004654:	9f35                	addw	a4,a4,a3
    return 0;
    80004656:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004658:	0ad76063          	bltu	a4,a3,800046f8 <readi+0xd2>
  if(off + n > ip->size)
    8000465c:	00e7f463          	bgeu	a5,a4,80004664 <readi+0x3e>
    n = ip->size - off;
    80004660:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004664:	0a0b0963          	beqz	s6,80004716 <readi+0xf0>
    80004668:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000466a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000466e:	5cfd                	li	s9,-1
    80004670:	a82d                	j	800046aa <readi+0x84>
    80004672:	020a1d93          	slli	s11,s4,0x20
    80004676:	020ddd93          	srli	s11,s11,0x20
    8000467a:	05890793          	addi	a5,s2,88
    8000467e:	86ee                	mv	a3,s11
    80004680:	963e                	add	a2,a2,a5
    80004682:	85d6                	mv	a1,s5
    80004684:	8562                	mv	a0,s8
    80004686:	ffffe097          	auipc	ra,0xffffe
    8000468a:	308080e7          	jalr	776(ra) # 8000298e <either_copyout>
    8000468e:	05950d63          	beq	a0,s9,800046e8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004692:	854a                	mv	a0,s2
    80004694:	fffff097          	auipc	ra,0xfffff
    80004698:	60a080e7          	jalr	1546(ra) # 80003c9e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000469c:	013a09bb          	addw	s3,s4,s3
    800046a0:	009a04bb          	addw	s1,s4,s1
    800046a4:	9aee                	add	s5,s5,s11
    800046a6:	0569f763          	bgeu	s3,s6,800046f4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800046aa:	000ba903          	lw	s2,0(s7)
    800046ae:	00a4d59b          	srliw	a1,s1,0xa
    800046b2:	855e                	mv	a0,s7
    800046b4:	00000097          	auipc	ra,0x0
    800046b8:	8ae080e7          	jalr	-1874(ra) # 80003f62 <bmap>
    800046bc:	0005059b          	sext.w	a1,a0
    800046c0:	854a                	mv	a0,s2
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	4ac080e7          	jalr	1196(ra) # 80003b6e <bread>
    800046ca:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046cc:	3ff4f613          	andi	a2,s1,1023
    800046d0:	40cd07bb          	subw	a5,s10,a2
    800046d4:	413b073b          	subw	a4,s6,s3
    800046d8:	8a3e                	mv	s4,a5
    800046da:	2781                	sext.w	a5,a5
    800046dc:	0007069b          	sext.w	a3,a4
    800046e0:	f8f6f9e3          	bgeu	a3,a5,80004672 <readi+0x4c>
    800046e4:	8a3a                	mv	s4,a4
    800046e6:	b771                	j	80004672 <readi+0x4c>
      brelse(bp);
    800046e8:	854a                	mv	a0,s2
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	5b4080e7          	jalr	1460(ra) # 80003c9e <brelse>
      tot = -1;
    800046f2:	59fd                	li	s3,-1
  }
  return tot;
    800046f4:	0009851b          	sext.w	a0,s3
}
    800046f8:	70a6                	ld	ra,104(sp)
    800046fa:	7406                	ld	s0,96(sp)
    800046fc:	64e6                	ld	s1,88(sp)
    800046fe:	6946                	ld	s2,80(sp)
    80004700:	69a6                	ld	s3,72(sp)
    80004702:	6a06                	ld	s4,64(sp)
    80004704:	7ae2                	ld	s5,56(sp)
    80004706:	7b42                	ld	s6,48(sp)
    80004708:	7ba2                	ld	s7,40(sp)
    8000470a:	7c02                	ld	s8,32(sp)
    8000470c:	6ce2                	ld	s9,24(sp)
    8000470e:	6d42                	ld	s10,16(sp)
    80004710:	6da2                	ld	s11,8(sp)
    80004712:	6165                	addi	sp,sp,112
    80004714:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004716:	89da                	mv	s3,s6
    80004718:	bff1                	j	800046f4 <readi+0xce>
    return 0;
    8000471a:	4501                	li	a0,0
}
    8000471c:	8082                	ret

000000008000471e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000471e:	457c                	lw	a5,76(a0)
    80004720:	10d7e863          	bltu	a5,a3,80004830 <writei+0x112>
{
    80004724:	7159                	addi	sp,sp,-112
    80004726:	f486                	sd	ra,104(sp)
    80004728:	f0a2                	sd	s0,96(sp)
    8000472a:	eca6                	sd	s1,88(sp)
    8000472c:	e8ca                	sd	s2,80(sp)
    8000472e:	e4ce                	sd	s3,72(sp)
    80004730:	e0d2                	sd	s4,64(sp)
    80004732:	fc56                	sd	s5,56(sp)
    80004734:	f85a                	sd	s6,48(sp)
    80004736:	f45e                	sd	s7,40(sp)
    80004738:	f062                	sd	s8,32(sp)
    8000473a:	ec66                	sd	s9,24(sp)
    8000473c:	e86a                	sd	s10,16(sp)
    8000473e:	e46e                	sd	s11,8(sp)
    80004740:	1880                	addi	s0,sp,112
    80004742:	8b2a                	mv	s6,a0
    80004744:	8c2e                	mv	s8,a1
    80004746:	8ab2                	mv	s5,a2
    80004748:	8936                	mv	s2,a3
    8000474a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000474c:	00e687bb          	addw	a5,a3,a4
    80004750:	0ed7e263          	bltu	a5,a3,80004834 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004754:	00043737          	lui	a4,0x43
    80004758:	0ef76063          	bltu	a4,a5,80004838 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000475c:	0c0b8863          	beqz	s7,8000482c <writei+0x10e>
    80004760:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004762:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004766:	5cfd                	li	s9,-1
    80004768:	a091                	j	800047ac <writei+0x8e>
    8000476a:	02099d93          	slli	s11,s3,0x20
    8000476e:	020ddd93          	srli	s11,s11,0x20
    80004772:	05848793          	addi	a5,s1,88
    80004776:	86ee                	mv	a3,s11
    80004778:	8656                	mv	a2,s5
    8000477a:	85e2                	mv	a1,s8
    8000477c:	953e                	add	a0,a0,a5
    8000477e:	ffffe097          	auipc	ra,0xffffe
    80004782:	268080e7          	jalr	616(ra) # 800029e6 <either_copyin>
    80004786:	07950263          	beq	a0,s9,800047ea <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000478a:	8526                	mv	a0,s1
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	794080e7          	jalr	1940(ra) # 80004f20 <log_write>
    brelse(bp);
    80004794:	8526                	mv	a0,s1
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	508080e7          	jalr	1288(ra) # 80003c9e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000479e:	01498a3b          	addw	s4,s3,s4
    800047a2:	0129893b          	addw	s2,s3,s2
    800047a6:	9aee                	add	s5,s5,s11
    800047a8:	057a7663          	bgeu	s4,s7,800047f4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800047ac:	000b2483          	lw	s1,0(s6)
    800047b0:	00a9559b          	srliw	a1,s2,0xa
    800047b4:	855a                	mv	a0,s6
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	7ac080e7          	jalr	1964(ra) # 80003f62 <bmap>
    800047be:	0005059b          	sext.w	a1,a0
    800047c2:	8526                	mv	a0,s1
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	3aa080e7          	jalr	938(ra) # 80003b6e <bread>
    800047cc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800047ce:	3ff97513          	andi	a0,s2,1023
    800047d2:	40ad07bb          	subw	a5,s10,a0
    800047d6:	414b873b          	subw	a4,s7,s4
    800047da:	89be                	mv	s3,a5
    800047dc:	2781                	sext.w	a5,a5
    800047de:	0007069b          	sext.w	a3,a4
    800047e2:	f8f6f4e3          	bgeu	a3,a5,8000476a <writei+0x4c>
    800047e6:	89ba                	mv	s3,a4
    800047e8:	b749                	j	8000476a <writei+0x4c>
      brelse(bp);
    800047ea:	8526                	mv	a0,s1
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	4b2080e7          	jalr	1202(ra) # 80003c9e <brelse>
  }

  if(off > ip->size)
    800047f4:	04cb2783          	lw	a5,76(s6)
    800047f8:	0127f463          	bgeu	a5,s2,80004800 <writei+0xe2>
    ip->size = off;
    800047fc:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004800:	855a                	mv	a0,s6
    80004802:	00000097          	auipc	ra,0x0
    80004806:	aa6080e7          	jalr	-1370(ra) # 800042a8 <iupdate>

  return tot;
    8000480a:	000a051b          	sext.w	a0,s4
}
    8000480e:	70a6                	ld	ra,104(sp)
    80004810:	7406                	ld	s0,96(sp)
    80004812:	64e6                	ld	s1,88(sp)
    80004814:	6946                	ld	s2,80(sp)
    80004816:	69a6                	ld	s3,72(sp)
    80004818:	6a06                	ld	s4,64(sp)
    8000481a:	7ae2                	ld	s5,56(sp)
    8000481c:	7b42                	ld	s6,48(sp)
    8000481e:	7ba2                	ld	s7,40(sp)
    80004820:	7c02                	ld	s8,32(sp)
    80004822:	6ce2                	ld	s9,24(sp)
    80004824:	6d42                	ld	s10,16(sp)
    80004826:	6da2                	ld	s11,8(sp)
    80004828:	6165                	addi	sp,sp,112
    8000482a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000482c:	8a5e                	mv	s4,s7
    8000482e:	bfc9                	j	80004800 <writei+0xe2>
    return -1;
    80004830:	557d                	li	a0,-1
}
    80004832:	8082                	ret
    return -1;
    80004834:	557d                	li	a0,-1
    80004836:	bfe1                	j	8000480e <writei+0xf0>
    return -1;
    80004838:	557d                	li	a0,-1
    8000483a:	bfd1                	j	8000480e <writei+0xf0>

000000008000483c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000483c:	1141                	addi	sp,sp,-16
    8000483e:	e406                	sd	ra,8(sp)
    80004840:	e022                	sd	s0,0(sp)
    80004842:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004844:	4639                	li	a2,14
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	574080e7          	jalr	1396(ra) # 80000dba <strncmp>
}
    8000484e:	60a2                	ld	ra,8(sp)
    80004850:	6402                	ld	s0,0(sp)
    80004852:	0141                	addi	sp,sp,16
    80004854:	8082                	ret

0000000080004856 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004856:	7139                	addi	sp,sp,-64
    80004858:	fc06                	sd	ra,56(sp)
    8000485a:	f822                	sd	s0,48(sp)
    8000485c:	f426                	sd	s1,40(sp)
    8000485e:	f04a                	sd	s2,32(sp)
    80004860:	ec4e                	sd	s3,24(sp)
    80004862:	e852                	sd	s4,16(sp)
    80004864:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004866:	04451703          	lh	a4,68(a0)
    8000486a:	4785                	li	a5,1
    8000486c:	00f71a63          	bne	a4,a5,80004880 <dirlookup+0x2a>
    80004870:	892a                	mv	s2,a0
    80004872:	89ae                	mv	s3,a1
    80004874:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004876:	457c                	lw	a5,76(a0)
    80004878:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000487a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000487c:	e79d                	bnez	a5,800048aa <dirlookup+0x54>
    8000487e:	a8a5                	j	800048f6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004880:	00004517          	auipc	a0,0x4
    80004884:	dc850513          	addi	a0,a0,-568 # 80008648 <syscalls+0x1d8>
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	ca2080e7          	jalr	-862(ra) # 8000052a <panic>
      panic("dirlookup read");
    80004890:	00004517          	auipc	a0,0x4
    80004894:	dd050513          	addi	a0,a0,-560 # 80008660 <syscalls+0x1f0>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	c92080e7          	jalr	-878(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048a0:	24c1                	addiw	s1,s1,16
    800048a2:	04c92783          	lw	a5,76(s2)
    800048a6:	04f4f763          	bgeu	s1,a5,800048f4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048aa:	4741                	li	a4,16
    800048ac:	86a6                	mv	a3,s1
    800048ae:	fc040613          	addi	a2,s0,-64
    800048b2:	4581                	li	a1,0
    800048b4:	854a                	mv	a0,s2
    800048b6:	00000097          	auipc	ra,0x0
    800048ba:	d70080e7          	jalr	-656(ra) # 80004626 <readi>
    800048be:	47c1                	li	a5,16
    800048c0:	fcf518e3          	bne	a0,a5,80004890 <dirlookup+0x3a>
    if(de.inum == 0)
    800048c4:	fc045783          	lhu	a5,-64(s0)
    800048c8:	dfe1                	beqz	a5,800048a0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800048ca:	fc240593          	addi	a1,s0,-62
    800048ce:	854e                	mv	a0,s3
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	f6c080e7          	jalr	-148(ra) # 8000483c <namecmp>
    800048d8:	f561                	bnez	a0,800048a0 <dirlookup+0x4a>
      if(poff)
    800048da:	000a0463          	beqz	s4,800048e2 <dirlookup+0x8c>
        *poff = off;
    800048de:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800048e2:	fc045583          	lhu	a1,-64(s0)
    800048e6:	00092503          	lw	a0,0(s2)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	754080e7          	jalr	1876(ra) # 8000403e <iget>
    800048f2:	a011                	j	800048f6 <dirlookup+0xa0>
  return 0;
    800048f4:	4501                	li	a0,0
}
    800048f6:	70e2                	ld	ra,56(sp)
    800048f8:	7442                	ld	s0,48(sp)
    800048fa:	74a2                	ld	s1,40(sp)
    800048fc:	7902                	ld	s2,32(sp)
    800048fe:	69e2                	ld	s3,24(sp)
    80004900:	6a42                	ld	s4,16(sp)
    80004902:	6121                	addi	sp,sp,64
    80004904:	8082                	ret

0000000080004906 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004906:	711d                	addi	sp,sp,-96
    80004908:	ec86                	sd	ra,88(sp)
    8000490a:	e8a2                	sd	s0,80(sp)
    8000490c:	e4a6                	sd	s1,72(sp)
    8000490e:	e0ca                	sd	s2,64(sp)
    80004910:	fc4e                	sd	s3,56(sp)
    80004912:	f852                	sd	s4,48(sp)
    80004914:	f456                	sd	s5,40(sp)
    80004916:	f05a                	sd	s6,32(sp)
    80004918:	ec5e                	sd	s7,24(sp)
    8000491a:	e862                	sd	s8,16(sp)
    8000491c:	e466                	sd	s9,8(sp)
    8000491e:	1080                	addi	s0,sp,96
    80004920:	84aa                	mv	s1,a0
    80004922:	8aae                	mv	s5,a1
    80004924:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004926:	00054703          	lbu	a4,0(a0)
    8000492a:	02f00793          	li	a5,47
    8000492e:	02f70363          	beq	a4,a5,80004954 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004932:	ffffd097          	auipc	ra,0xffffd
    80004936:	0c4080e7          	jalr	196(ra) # 800019f6 <myproc>
    8000493a:	26053503          	ld	a0,608(a0)
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	9f6080e7          	jalr	-1546(ra) # 80004334 <idup>
    80004946:	89aa                	mv	s3,a0
  while(*path == '/')
    80004948:	02f00913          	li	s2,47
  len = path - s;
    8000494c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000494e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004950:	4b85                	li	s7,1
    80004952:	a865                	j	80004a0a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004954:	4585                	li	a1,1
    80004956:	4505                	li	a0,1
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	6e6080e7          	jalr	1766(ra) # 8000403e <iget>
    80004960:	89aa                	mv	s3,a0
    80004962:	b7dd                	j	80004948 <namex+0x42>
      iunlockput(ip);
    80004964:	854e                	mv	a0,s3
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	c6e080e7          	jalr	-914(ra) # 800045d4 <iunlockput>
      return 0;
    8000496e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004970:	854e                	mv	a0,s3
    80004972:	60e6                	ld	ra,88(sp)
    80004974:	6446                	ld	s0,80(sp)
    80004976:	64a6                	ld	s1,72(sp)
    80004978:	6906                	ld	s2,64(sp)
    8000497a:	79e2                	ld	s3,56(sp)
    8000497c:	7a42                	ld	s4,48(sp)
    8000497e:	7aa2                	ld	s5,40(sp)
    80004980:	7b02                	ld	s6,32(sp)
    80004982:	6be2                	ld	s7,24(sp)
    80004984:	6c42                	ld	s8,16(sp)
    80004986:	6ca2                	ld	s9,8(sp)
    80004988:	6125                	addi	sp,sp,96
    8000498a:	8082                	ret
      iunlock(ip);
    8000498c:	854e                	mv	a0,s3
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	aa6080e7          	jalr	-1370(ra) # 80004434 <iunlock>
      return ip;
    80004996:	bfe9                	j	80004970 <namex+0x6a>
      iunlockput(ip);
    80004998:	854e                	mv	a0,s3
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	c3a080e7          	jalr	-966(ra) # 800045d4 <iunlockput>
      return 0;
    800049a2:	89e6                	mv	s3,s9
    800049a4:	b7f1                	j	80004970 <namex+0x6a>
  len = path - s;
    800049a6:	40b48633          	sub	a2,s1,a1
    800049aa:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800049ae:	099c5463          	bge	s8,s9,80004a36 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800049b2:	4639                	li	a2,14
    800049b4:	8552                	mv	a0,s4
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	388080e7          	jalr	904(ra) # 80000d3e <memmove>
  while(*path == '/')
    800049be:	0004c783          	lbu	a5,0(s1)
    800049c2:	01279763          	bne	a5,s2,800049d0 <namex+0xca>
    path++;
    800049c6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800049c8:	0004c783          	lbu	a5,0(s1)
    800049cc:	ff278de3          	beq	a5,s2,800049c6 <namex+0xc0>
    ilock(ip);
    800049d0:	854e                	mv	a0,s3
    800049d2:	00000097          	auipc	ra,0x0
    800049d6:	9a0080e7          	jalr	-1632(ra) # 80004372 <ilock>
    if(ip->type != T_DIR){
    800049da:	04499783          	lh	a5,68(s3)
    800049de:	f97793e3          	bne	a5,s7,80004964 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800049e2:	000a8563          	beqz	s5,800049ec <namex+0xe6>
    800049e6:	0004c783          	lbu	a5,0(s1)
    800049ea:	d3cd                	beqz	a5,8000498c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800049ec:	865a                	mv	a2,s6
    800049ee:	85d2                	mv	a1,s4
    800049f0:	854e                	mv	a0,s3
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	e64080e7          	jalr	-412(ra) # 80004856 <dirlookup>
    800049fa:	8caa                	mv	s9,a0
    800049fc:	dd51                	beqz	a0,80004998 <namex+0x92>
    iunlockput(ip);
    800049fe:	854e                	mv	a0,s3
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	bd4080e7          	jalr	-1068(ra) # 800045d4 <iunlockput>
    ip = next;
    80004a08:	89e6                	mv	s3,s9
  while(*path == '/')
    80004a0a:	0004c783          	lbu	a5,0(s1)
    80004a0e:	05279763          	bne	a5,s2,80004a5c <namex+0x156>
    path++;
    80004a12:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004a14:	0004c783          	lbu	a5,0(s1)
    80004a18:	ff278de3          	beq	a5,s2,80004a12 <namex+0x10c>
  if(*path == 0)
    80004a1c:	c79d                	beqz	a5,80004a4a <namex+0x144>
    path++;
    80004a1e:	85a6                	mv	a1,s1
  len = path - s;
    80004a20:	8cda                	mv	s9,s6
    80004a22:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004a24:	01278963          	beq	a5,s2,80004a36 <namex+0x130>
    80004a28:	dfbd                	beqz	a5,800049a6 <namex+0xa0>
    path++;
    80004a2a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004a2c:	0004c783          	lbu	a5,0(s1)
    80004a30:	ff279ce3          	bne	a5,s2,80004a28 <namex+0x122>
    80004a34:	bf8d                	j	800049a6 <namex+0xa0>
    memmove(name, s, len);
    80004a36:	2601                	sext.w	a2,a2
    80004a38:	8552                	mv	a0,s4
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	304080e7          	jalr	772(ra) # 80000d3e <memmove>
    name[len] = 0;
    80004a42:	9cd2                	add	s9,s9,s4
    80004a44:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004a48:	bf9d                	j	800049be <namex+0xb8>
  if(nameiparent){
    80004a4a:	f20a83e3          	beqz	s5,80004970 <namex+0x6a>
    iput(ip);
    80004a4e:	854e                	mv	a0,s3
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	adc080e7          	jalr	-1316(ra) # 8000452c <iput>
    return 0;
    80004a58:	4981                	li	s3,0
    80004a5a:	bf19                	j	80004970 <namex+0x6a>
  if(*path == 0)
    80004a5c:	d7fd                	beqz	a5,80004a4a <namex+0x144>
  while(*path != '/' && *path != 0)
    80004a5e:	0004c783          	lbu	a5,0(s1)
    80004a62:	85a6                	mv	a1,s1
    80004a64:	b7d1                	j	80004a28 <namex+0x122>

0000000080004a66 <dirlink>:
{
    80004a66:	7139                	addi	sp,sp,-64
    80004a68:	fc06                	sd	ra,56(sp)
    80004a6a:	f822                	sd	s0,48(sp)
    80004a6c:	f426                	sd	s1,40(sp)
    80004a6e:	f04a                	sd	s2,32(sp)
    80004a70:	ec4e                	sd	s3,24(sp)
    80004a72:	e852                	sd	s4,16(sp)
    80004a74:	0080                	addi	s0,sp,64
    80004a76:	892a                	mv	s2,a0
    80004a78:	8a2e                	mv	s4,a1
    80004a7a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a7c:	4601                	li	a2,0
    80004a7e:	00000097          	auipc	ra,0x0
    80004a82:	dd8080e7          	jalr	-552(ra) # 80004856 <dirlookup>
    80004a86:	e93d                	bnez	a0,80004afc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a88:	04c92483          	lw	s1,76(s2)
    80004a8c:	c49d                	beqz	s1,80004aba <dirlink+0x54>
    80004a8e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a90:	4741                	li	a4,16
    80004a92:	86a6                	mv	a3,s1
    80004a94:	fc040613          	addi	a2,s0,-64
    80004a98:	4581                	li	a1,0
    80004a9a:	854a                	mv	a0,s2
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	b8a080e7          	jalr	-1142(ra) # 80004626 <readi>
    80004aa4:	47c1                	li	a5,16
    80004aa6:	06f51163          	bne	a0,a5,80004b08 <dirlink+0xa2>
    if(de.inum == 0)
    80004aaa:	fc045783          	lhu	a5,-64(s0)
    80004aae:	c791                	beqz	a5,80004aba <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004ab0:	24c1                	addiw	s1,s1,16
    80004ab2:	04c92783          	lw	a5,76(s2)
    80004ab6:	fcf4ede3          	bltu	s1,a5,80004a90 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004aba:	4639                	li	a2,14
    80004abc:	85d2                	mv	a1,s4
    80004abe:	fc240513          	addi	a0,s0,-62
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	334080e7          	jalr	820(ra) # 80000df6 <strncpy>
  de.inum = inum;
    80004aca:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ace:	4741                	li	a4,16
    80004ad0:	86a6                	mv	a3,s1
    80004ad2:	fc040613          	addi	a2,s0,-64
    80004ad6:	4581                	li	a1,0
    80004ad8:	854a                	mv	a0,s2
    80004ada:	00000097          	auipc	ra,0x0
    80004ade:	c44080e7          	jalr	-956(ra) # 8000471e <writei>
    80004ae2:	872a                	mv	a4,a0
    80004ae4:	47c1                	li	a5,16
  return 0;
    80004ae6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ae8:	02f71863          	bne	a4,a5,80004b18 <dirlink+0xb2>
}
    80004aec:	70e2                	ld	ra,56(sp)
    80004aee:	7442                	ld	s0,48(sp)
    80004af0:	74a2                	ld	s1,40(sp)
    80004af2:	7902                	ld	s2,32(sp)
    80004af4:	69e2                	ld	s3,24(sp)
    80004af6:	6a42                	ld	s4,16(sp)
    80004af8:	6121                	addi	sp,sp,64
    80004afa:	8082                	ret
    iput(ip);
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	a30080e7          	jalr	-1488(ra) # 8000452c <iput>
    return -1;
    80004b04:	557d                	li	a0,-1
    80004b06:	b7dd                	j	80004aec <dirlink+0x86>
      panic("dirlink read");
    80004b08:	00004517          	auipc	a0,0x4
    80004b0c:	b6850513          	addi	a0,a0,-1176 # 80008670 <syscalls+0x200>
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	a1a080e7          	jalr	-1510(ra) # 8000052a <panic>
    panic("dirlink");
    80004b18:	00004517          	auipc	a0,0x4
    80004b1c:	c6850513          	addi	a0,a0,-920 # 80008780 <syscalls+0x310>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	a0a080e7          	jalr	-1526(ra) # 8000052a <panic>

0000000080004b28 <namei>:

struct inode*
namei(char *path)
{
    80004b28:	1101                	addi	sp,sp,-32
    80004b2a:	ec06                	sd	ra,24(sp)
    80004b2c:	e822                	sd	s0,16(sp)
    80004b2e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004b30:	fe040613          	addi	a2,s0,-32
    80004b34:	4581                	li	a1,0
    80004b36:	00000097          	auipc	ra,0x0
    80004b3a:	dd0080e7          	jalr	-560(ra) # 80004906 <namex>
}
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	6105                	addi	sp,sp,32
    80004b44:	8082                	ret

0000000080004b46 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004b46:	1141                	addi	sp,sp,-16
    80004b48:	e406                	sd	ra,8(sp)
    80004b4a:	e022                	sd	s0,0(sp)
    80004b4c:	0800                	addi	s0,sp,16
    80004b4e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004b50:	4585                	li	a1,1
    80004b52:	00000097          	auipc	ra,0x0
    80004b56:	db4080e7          	jalr	-588(ra) # 80004906 <namex>
}
    80004b5a:	60a2                	ld	ra,8(sp)
    80004b5c:	6402                	ld	s0,0(sp)
    80004b5e:	0141                	addi	sp,sp,16
    80004b60:	8082                	ret

0000000080004b62 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b62:	1101                	addi	sp,sp,-32
    80004b64:	ec06                	sd	ra,24(sp)
    80004b66:	e822                	sd	s0,16(sp)
    80004b68:	e426                	sd	s1,8(sp)
    80004b6a:	e04a                	sd	s2,0(sp)
    80004b6c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b6e:	00039917          	auipc	s2,0x39
    80004b72:	d3290913          	addi	s2,s2,-718 # 8003d8a0 <log>
    80004b76:	01892583          	lw	a1,24(s2)
    80004b7a:	02892503          	lw	a0,40(s2)
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	ff0080e7          	jalr	-16(ra) # 80003b6e <bread>
    80004b86:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b88:	02c92683          	lw	a3,44(s2)
    80004b8c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b8e:	02d05863          	blez	a3,80004bbe <write_head+0x5c>
    80004b92:	00039797          	auipc	a5,0x39
    80004b96:	d3e78793          	addi	a5,a5,-706 # 8003d8d0 <log+0x30>
    80004b9a:	05c50713          	addi	a4,a0,92
    80004b9e:	36fd                	addiw	a3,a3,-1
    80004ba0:	02069613          	slli	a2,a3,0x20
    80004ba4:	01e65693          	srli	a3,a2,0x1e
    80004ba8:	00039617          	auipc	a2,0x39
    80004bac:	d2c60613          	addi	a2,a2,-724 # 8003d8d4 <log+0x34>
    80004bb0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004bb2:	4390                	lw	a2,0(a5)
    80004bb4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004bb6:	0791                	addi	a5,a5,4
    80004bb8:	0711                	addi	a4,a4,4
    80004bba:	fed79ce3          	bne	a5,a3,80004bb2 <write_head+0x50>
  }
  bwrite(buf);
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	fffff097          	auipc	ra,0xfffff
    80004bc4:	0a0080e7          	jalr	160(ra) # 80003c60 <bwrite>
  brelse(buf);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	fffff097          	auipc	ra,0xfffff
    80004bce:	0d4080e7          	jalr	212(ra) # 80003c9e <brelse>
}
    80004bd2:	60e2                	ld	ra,24(sp)
    80004bd4:	6442                	ld	s0,16(sp)
    80004bd6:	64a2                	ld	s1,8(sp)
    80004bd8:	6902                	ld	s2,0(sp)
    80004bda:	6105                	addi	sp,sp,32
    80004bdc:	8082                	ret

0000000080004bde <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bde:	00039797          	auipc	a5,0x39
    80004be2:	cee7a783          	lw	a5,-786(a5) # 8003d8cc <log+0x2c>
    80004be6:	0af05d63          	blez	a5,80004ca0 <install_trans+0xc2>
{
    80004bea:	7139                	addi	sp,sp,-64
    80004bec:	fc06                	sd	ra,56(sp)
    80004bee:	f822                	sd	s0,48(sp)
    80004bf0:	f426                	sd	s1,40(sp)
    80004bf2:	f04a                	sd	s2,32(sp)
    80004bf4:	ec4e                	sd	s3,24(sp)
    80004bf6:	e852                	sd	s4,16(sp)
    80004bf8:	e456                	sd	s5,8(sp)
    80004bfa:	e05a                	sd	s6,0(sp)
    80004bfc:	0080                	addi	s0,sp,64
    80004bfe:	8b2a                	mv	s6,a0
    80004c00:	00039a97          	auipc	s5,0x39
    80004c04:	cd0a8a93          	addi	s5,s5,-816 # 8003d8d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c08:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c0a:	00039997          	auipc	s3,0x39
    80004c0e:	c9698993          	addi	s3,s3,-874 # 8003d8a0 <log>
    80004c12:	a00d                	j	80004c34 <install_trans+0x56>
    brelse(lbuf);
    80004c14:	854a                	mv	a0,s2
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	088080e7          	jalr	136(ra) # 80003c9e <brelse>
    brelse(dbuf);
    80004c1e:	8526                	mv	a0,s1
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	07e080e7          	jalr	126(ra) # 80003c9e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c28:	2a05                	addiw	s4,s4,1
    80004c2a:	0a91                	addi	s5,s5,4
    80004c2c:	02c9a783          	lw	a5,44(s3)
    80004c30:	04fa5e63          	bge	s4,a5,80004c8c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c34:	0189a583          	lw	a1,24(s3)
    80004c38:	014585bb          	addw	a1,a1,s4
    80004c3c:	2585                	addiw	a1,a1,1
    80004c3e:	0289a503          	lw	a0,40(s3)
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	f2c080e7          	jalr	-212(ra) # 80003b6e <bread>
    80004c4a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c4c:	000aa583          	lw	a1,0(s5)
    80004c50:	0289a503          	lw	a0,40(s3)
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	f1a080e7          	jalr	-230(ra) # 80003b6e <bread>
    80004c5c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c5e:	40000613          	li	a2,1024
    80004c62:	05890593          	addi	a1,s2,88
    80004c66:	05850513          	addi	a0,a0,88
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	0d4080e7          	jalr	212(ra) # 80000d3e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c72:	8526                	mv	a0,s1
    80004c74:	fffff097          	auipc	ra,0xfffff
    80004c78:	fec080e7          	jalr	-20(ra) # 80003c60 <bwrite>
    if(recovering == 0)
    80004c7c:	f80b1ce3          	bnez	s6,80004c14 <install_trans+0x36>
      bunpin(dbuf);
    80004c80:	8526                	mv	a0,s1
    80004c82:	fffff097          	auipc	ra,0xfffff
    80004c86:	0f6080e7          	jalr	246(ra) # 80003d78 <bunpin>
    80004c8a:	b769                	j	80004c14 <install_trans+0x36>
}
    80004c8c:	70e2                	ld	ra,56(sp)
    80004c8e:	7442                	ld	s0,48(sp)
    80004c90:	74a2                	ld	s1,40(sp)
    80004c92:	7902                	ld	s2,32(sp)
    80004c94:	69e2                	ld	s3,24(sp)
    80004c96:	6a42                	ld	s4,16(sp)
    80004c98:	6aa2                	ld	s5,8(sp)
    80004c9a:	6b02                	ld	s6,0(sp)
    80004c9c:	6121                	addi	sp,sp,64
    80004c9e:	8082                	ret
    80004ca0:	8082                	ret

0000000080004ca2 <initlog>:
{
    80004ca2:	7179                	addi	sp,sp,-48
    80004ca4:	f406                	sd	ra,40(sp)
    80004ca6:	f022                	sd	s0,32(sp)
    80004ca8:	ec26                	sd	s1,24(sp)
    80004caa:	e84a                	sd	s2,16(sp)
    80004cac:	e44e                	sd	s3,8(sp)
    80004cae:	1800                	addi	s0,sp,48
    80004cb0:	892a                	mv	s2,a0
    80004cb2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004cb4:	00039497          	auipc	s1,0x39
    80004cb8:	bec48493          	addi	s1,s1,-1044 # 8003d8a0 <log>
    80004cbc:	00004597          	auipc	a1,0x4
    80004cc0:	9c458593          	addi	a1,a1,-1596 # 80008680 <syscalls+0x210>
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	e6c080e7          	jalr	-404(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004cce:	0149a583          	lw	a1,20(s3)
    80004cd2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004cd4:	0109a783          	lw	a5,16(s3)
    80004cd8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004cda:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004cde:	854a                	mv	a0,s2
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	e8e080e7          	jalr	-370(ra) # 80003b6e <bread>
  log.lh.n = lh->n;
    80004ce8:	4d34                	lw	a3,88(a0)
    80004cea:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004cec:	02d05663          	blez	a3,80004d18 <initlog+0x76>
    80004cf0:	05c50793          	addi	a5,a0,92
    80004cf4:	00039717          	auipc	a4,0x39
    80004cf8:	bdc70713          	addi	a4,a4,-1060 # 8003d8d0 <log+0x30>
    80004cfc:	36fd                	addiw	a3,a3,-1
    80004cfe:	02069613          	slli	a2,a3,0x20
    80004d02:	01e65693          	srli	a3,a2,0x1e
    80004d06:	06050613          	addi	a2,a0,96
    80004d0a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004d0c:	4390                	lw	a2,0(a5)
    80004d0e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004d10:	0791                	addi	a5,a5,4
    80004d12:	0711                	addi	a4,a4,4
    80004d14:	fed79ce3          	bne	a5,a3,80004d0c <initlog+0x6a>
  brelse(buf);
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	f86080e7          	jalr	-122(ra) # 80003c9e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004d20:	4505                	li	a0,1
    80004d22:	00000097          	auipc	ra,0x0
    80004d26:	ebc080e7          	jalr	-324(ra) # 80004bde <install_trans>
  log.lh.n = 0;
    80004d2a:	00039797          	auipc	a5,0x39
    80004d2e:	ba07a123          	sw	zero,-1118(a5) # 8003d8cc <log+0x2c>
  write_head(); // clear the log
    80004d32:	00000097          	auipc	ra,0x0
    80004d36:	e30080e7          	jalr	-464(ra) # 80004b62 <write_head>
}
    80004d3a:	70a2                	ld	ra,40(sp)
    80004d3c:	7402                	ld	s0,32(sp)
    80004d3e:	64e2                	ld	s1,24(sp)
    80004d40:	6942                	ld	s2,16(sp)
    80004d42:	69a2                	ld	s3,8(sp)
    80004d44:	6145                	addi	sp,sp,48
    80004d46:	8082                	ret

0000000080004d48 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004d48:	1101                	addi	sp,sp,-32
    80004d4a:	ec06                	sd	ra,24(sp)
    80004d4c:	e822                	sd	s0,16(sp)
    80004d4e:	e426                	sd	s1,8(sp)
    80004d50:	e04a                	sd	s2,0(sp)
    80004d52:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004d54:	00039517          	auipc	a0,0x39
    80004d58:	b4c50513          	addi	a0,a0,-1204 # 8003d8a0 <log>
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	e66080e7          	jalr	-410(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004d64:	00039497          	auipc	s1,0x39
    80004d68:	b3c48493          	addi	s1,s1,-1220 # 8003d8a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d6c:	4979                	li	s2,30
    80004d6e:	a039                	j	80004d7c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d70:	85a6                	mv	a1,s1
    80004d72:	8526                	mv	a0,s1
    80004d74:	ffffe097          	auipc	ra,0xffffe
    80004d78:	916080e7          	jalr	-1770(ra) # 8000268a <sleep>
    if(log.committing){
    80004d7c:	50dc                	lw	a5,36(s1)
    80004d7e:	fbed                	bnez	a5,80004d70 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d80:	509c                	lw	a5,32(s1)
    80004d82:	0017871b          	addiw	a4,a5,1
    80004d86:	0007069b          	sext.w	a3,a4
    80004d8a:	0027179b          	slliw	a5,a4,0x2
    80004d8e:	9fb9                	addw	a5,a5,a4
    80004d90:	0017979b          	slliw	a5,a5,0x1
    80004d94:	54d8                	lw	a4,44(s1)
    80004d96:	9fb9                	addw	a5,a5,a4
    80004d98:	00f95963          	bge	s2,a5,80004daa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d9c:	85a6                	mv	a1,s1
    80004d9e:	8526                	mv	a0,s1
    80004da0:	ffffe097          	auipc	ra,0xffffe
    80004da4:	8ea080e7          	jalr	-1814(ra) # 8000268a <sleep>
    80004da8:	bfd1                	j	80004d7c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004daa:	00039517          	auipc	a0,0x39
    80004dae:	af650513          	addi	a0,a0,-1290 # 8003d8a0 <log>
    80004db2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	ed4080e7          	jalr	-300(ra) # 80000c88 <release>
      break;
    }
  }
}
    80004dbc:	60e2                	ld	ra,24(sp)
    80004dbe:	6442                	ld	s0,16(sp)
    80004dc0:	64a2                	ld	s1,8(sp)
    80004dc2:	6902                	ld	s2,0(sp)
    80004dc4:	6105                	addi	sp,sp,32
    80004dc6:	8082                	ret

0000000080004dc8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004dc8:	7139                	addi	sp,sp,-64
    80004dca:	fc06                	sd	ra,56(sp)
    80004dcc:	f822                	sd	s0,48(sp)
    80004dce:	f426                	sd	s1,40(sp)
    80004dd0:	f04a                	sd	s2,32(sp)
    80004dd2:	ec4e                	sd	s3,24(sp)
    80004dd4:	e852                	sd	s4,16(sp)
    80004dd6:	e456                	sd	s5,8(sp)
    80004dd8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004dda:	00039497          	auipc	s1,0x39
    80004dde:	ac648493          	addi	s1,s1,-1338 # 8003d8a0 <log>
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	dde080e7          	jalr	-546(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004dec:	509c                	lw	a5,32(s1)
    80004dee:	37fd                	addiw	a5,a5,-1
    80004df0:	0007891b          	sext.w	s2,a5
    80004df4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004df6:	50dc                	lw	a5,36(s1)
    80004df8:	e7b9                	bnez	a5,80004e46 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004dfa:	04091e63          	bnez	s2,80004e56 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004dfe:	00039497          	auipc	s1,0x39
    80004e02:	aa248493          	addi	s1,s1,-1374 # 8003d8a0 <log>
    80004e06:	4785                	li	a5,1
    80004e08:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004e0a:	8526                	mv	a0,s1
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	e7c080e7          	jalr	-388(ra) # 80000c88 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004e14:	54dc                	lw	a5,44(s1)
    80004e16:	06f04763          	bgtz	a5,80004e84 <end_op+0xbc>
    acquire(&log.lock);
    80004e1a:	00039497          	auipc	s1,0x39
    80004e1e:	a8648493          	addi	s1,s1,-1402 # 8003d8a0 <log>
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	d9e080e7          	jalr	-610(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004e2c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004e30:	8526                	mv	a0,s1
    80004e32:	ffffe097          	auipc	ra,0xffffe
    80004e36:	9e2080e7          	jalr	-1566(ra) # 80002814 <wakeup>
    release(&log.lock);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	e4c080e7          	jalr	-436(ra) # 80000c88 <release>
}
    80004e44:	a03d                	j	80004e72 <end_op+0xaa>
    panic("log.committing");
    80004e46:	00004517          	auipc	a0,0x4
    80004e4a:	84250513          	addi	a0,a0,-1982 # 80008688 <syscalls+0x218>
    80004e4e:	ffffb097          	auipc	ra,0xffffb
    80004e52:	6dc080e7          	jalr	1756(ra) # 8000052a <panic>
    wakeup(&log);
    80004e56:	00039497          	auipc	s1,0x39
    80004e5a:	a4a48493          	addi	s1,s1,-1462 # 8003d8a0 <log>
    80004e5e:	8526                	mv	a0,s1
    80004e60:	ffffe097          	auipc	ra,0xffffe
    80004e64:	9b4080e7          	jalr	-1612(ra) # 80002814 <wakeup>
  release(&log.lock);
    80004e68:	8526                	mv	a0,s1
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	e1e080e7          	jalr	-482(ra) # 80000c88 <release>
}
    80004e72:	70e2                	ld	ra,56(sp)
    80004e74:	7442                	ld	s0,48(sp)
    80004e76:	74a2                	ld	s1,40(sp)
    80004e78:	7902                	ld	s2,32(sp)
    80004e7a:	69e2                	ld	s3,24(sp)
    80004e7c:	6a42                	ld	s4,16(sp)
    80004e7e:	6aa2                	ld	s5,8(sp)
    80004e80:	6121                	addi	sp,sp,64
    80004e82:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e84:	00039a97          	auipc	s5,0x39
    80004e88:	a4ca8a93          	addi	s5,s5,-1460 # 8003d8d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e8c:	00039a17          	auipc	s4,0x39
    80004e90:	a14a0a13          	addi	s4,s4,-1516 # 8003d8a0 <log>
    80004e94:	018a2583          	lw	a1,24(s4)
    80004e98:	012585bb          	addw	a1,a1,s2
    80004e9c:	2585                	addiw	a1,a1,1
    80004e9e:	028a2503          	lw	a0,40(s4)
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	ccc080e7          	jalr	-820(ra) # 80003b6e <bread>
    80004eaa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004eac:	000aa583          	lw	a1,0(s5)
    80004eb0:	028a2503          	lw	a0,40(s4)
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	cba080e7          	jalr	-838(ra) # 80003b6e <bread>
    80004ebc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004ebe:	40000613          	li	a2,1024
    80004ec2:	05850593          	addi	a1,a0,88
    80004ec6:	05848513          	addi	a0,s1,88
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	e74080e7          	jalr	-396(ra) # 80000d3e <memmove>
    bwrite(to);  // write the log
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	d8c080e7          	jalr	-628(ra) # 80003c60 <bwrite>
    brelse(from);
    80004edc:	854e                	mv	a0,s3
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	dc0080e7          	jalr	-576(ra) # 80003c9e <brelse>
    brelse(to);
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	db6080e7          	jalr	-586(ra) # 80003c9e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ef0:	2905                	addiw	s2,s2,1
    80004ef2:	0a91                	addi	s5,s5,4
    80004ef4:	02ca2783          	lw	a5,44(s4)
    80004ef8:	f8f94ee3          	blt	s2,a5,80004e94 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004efc:	00000097          	auipc	ra,0x0
    80004f00:	c66080e7          	jalr	-922(ra) # 80004b62 <write_head>
    install_trans(0); // Now install writes to home locations
    80004f04:	4501                	li	a0,0
    80004f06:	00000097          	auipc	ra,0x0
    80004f0a:	cd8080e7          	jalr	-808(ra) # 80004bde <install_trans>
    log.lh.n = 0;
    80004f0e:	00039797          	auipc	a5,0x39
    80004f12:	9a07af23          	sw	zero,-1602(a5) # 8003d8cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004f16:	00000097          	auipc	ra,0x0
    80004f1a:	c4c080e7          	jalr	-948(ra) # 80004b62 <write_head>
    80004f1e:	bdf5                	j	80004e1a <end_op+0x52>

0000000080004f20 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004f20:	1101                	addi	sp,sp,-32
    80004f22:	ec06                	sd	ra,24(sp)
    80004f24:	e822                	sd	s0,16(sp)
    80004f26:	e426                	sd	s1,8(sp)
    80004f28:	e04a                	sd	s2,0(sp)
    80004f2a:	1000                	addi	s0,sp,32
    80004f2c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004f2e:	00039917          	auipc	s2,0x39
    80004f32:	97290913          	addi	s2,s2,-1678 # 8003d8a0 <log>
    80004f36:	854a                	mv	a0,s2
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	c8a080e7          	jalr	-886(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004f40:	02c92603          	lw	a2,44(s2)
    80004f44:	47f5                	li	a5,29
    80004f46:	06c7c563          	blt	a5,a2,80004fb0 <log_write+0x90>
    80004f4a:	00039797          	auipc	a5,0x39
    80004f4e:	9727a783          	lw	a5,-1678(a5) # 8003d8bc <log+0x1c>
    80004f52:	37fd                	addiw	a5,a5,-1
    80004f54:	04f65e63          	bge	a2,a5,80004fb0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f58:	00039797          	auipc	a5,0x39
    80004f5c:	9687a783          	lw	a5,-1688(a5) # 8003d8c0 <log+0x20>
    80004f60:	06f05063          	blez	a5,80004fc0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f64:	4781                	li	a5,0
    80004f66:	06c05563          	blez	a2,80004fd0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004f6a:	44cc                	lw	a1,12(s1)
    80004f6c:	00039717          	auipc	a4,0x39
    80004f70:	96470713          	addi	a4,a4,-1692 # 8003d8d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f74:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004f76:	4314                	lw	a3,0(a4)
    80004f78:	04b68c63          	beq	a3,a1,80004fd0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f7c:	2785                	addiw	a5,a5,1
    80004f7e:	0711                	addi	a4,a4,4
    80004f80:	fef61be3          	bne	a2,a5,80004f76 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f84:	0621                	addi	a2,a2,8
    80004f86:	060a                	slli	a2,a2,0x2
    80004f88:	00039797          	auipc	a5,0x39
    80004f8c:	91878793          	addi	a5,a5,-1768 # 8003d8a0 <log>
    80004f90:	963e                	add	a2,a2,a5
    80004f92:	44dc                	lw	a5,12(s1)
    80004f94:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f96:	8526                	mv	a0,s1
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	da4080e7          	jalr	-604(ra) # 80003d3c <bpin>
    log.lh.n++;
    80004fa0:	00039717          	auipc	a4,0x39
    80004fa4:	90070713          	addi	a4,a4,-1792 # 8003d8a0 <log>
    80004fa8:	575c                	lw	a5,44(a4)
    80004faa:	2785                	addiw	a5,a5,1
    80004fac:	d75c                	sw	a5,44(a4)
    80004fae:	a835                	j	80004fea <log_write+0xca>
    panic("too big a transaction");
    80004fb0:	00003517          	auipc	a0,0x3
    80004fb4:	6e850513          	addi	a0,a0,1768 # 80008698 <syscalls+0x228>
    80004fb8:	ffffb097          	auipc	ra,0xffffb
    80004fbc:	572080e7          	jalr	1394(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004fc0:	00003517          	auipc	a0,0x3
    80004fc4:	6f050513          	addi	a0,a0,1776 # 800086b0 <syscalls+0x240>
    80004fc8:	ffffb097          	auipc	ra,0xffffb
    80004fcc:	562080e7          	jalr	1378(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004fd0:	00878713          	addi	a4,a5,8
    80004fd4:	00271693          	slli	a3,a4,0x2
    80004fd8:	00039717          	auipc	a4,0x39
    80004fdc:	8c870713          	addi	a4,a4,-1848 # 8003d8a0 <log>
    80004fe0:	9736                	add	a4,a4,a3
    80004fe2:	44d4                	lw	a3,12(s1)
    80004fe4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004fe6:	faf608e3          	beq	a2,a5,80004f96 <log_write+0x76>
  }
  release(&log.lock);
    80004fea:	00039517          	auipc	a0,0x39
    80004fee:	8b650513          	addi	a0,a0,-1866 # 8003d8a0 <log>
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	c96080e7          	jalr	-874(ra) # 80000c88 <release>
}
    80004ffa:	60e2                	ld	ra,24(sp)
    80004ffc:	6442                	ld	s0,16(sp)
    80004ffe:	64a2                	ld	s1,8(sp)
    80005000:	6902                	ld	s2,0(sp)
    80005002:	6105                	addi	sp,sp,32
    80005004:	8082                	ret

0000000080005006 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005006:	1101                	addi	sp,sp,-32
    80005008:	ec06                	sd	ra,24(sp)
    8000500a:	e822                	sd	s0,16(sp)
    8000500c:	e426                	sd	s1,8(sp)
    8000500e:	e04a                	sd	s2,0(sp)
    80005010:	1000                	addi	s0,sp,32
    80005012:	84aa                	mv	s1,a0
    80005014:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005016:	00003597          	auipc	a1,0x3
    8000501a:	6ba58593          	addi	a1,a1,1722 # 800086d0 <syscalls+0x260>
    8000501e:	0521                	addi	a0,a0,8
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	b12080e7          	jalr	-1262(ra) # 80000b32 <initlock>
  lk->name = name;
    80005028:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000502c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005030:	0204a423          	sw	zero,40(s1)
}
    80005034:	60e2                	ld	ra,24(sp)
    80005036:	6442                	ld	s0,16(sp)
    80005038:	64a2                	ld	s1,8(sp)
    8000503a:	6902                	ld	s2,0(sp)
    8000503c:	6105                	addi	sp,sp,32
    8000503e:	8082                	ret

0000000080005040 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005040:	1101                	addi	sp,sp,-32
    80005042:	ec06                	sd	ra,24(sp)
    80005044:	e822                	sd	s0,16(sp)
    80005046:	e426                	sd	s1,8(sp)
    80005048:	e04a                	sd	s2,0(sp)
    8000504a:	1000                	addi	s0,sp,32
    8000504c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000504e:	00850913          	addi	s2,a0,8
    80005052:	854a                	mv	a0,s2
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	b6e080e7          	jalr	-1170(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    8000505c:	409c                	lw	a5,0(s1)
    8000505e:	cb89                	beqz	a5,80005070 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005060:	85ca                	mv	a1,s2
    80005062:	8526                	mv	a0,s1
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	626080e7          	jalr	1574(ra) # 8000268a <sleep>
  while (lk->locked) {
    8000506c:	409c                	lw	a5,0(s1)
    8000506e:	fbed                	bnez	a5,80005060 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005070:	4785                	li	a5,1
    80005072:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005074:	ffffd097          	auipc	ra,0xffffd
    80005078:	982080e7          	jalr	-1662(ra) # 800019f6 <myproc>
    8000507c:	515c                	lw	a5,36(a0)
    8000507e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005080:	854a                	mv	a0,s2
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	c06080e7          	jalr	-1018(ra) # 80000c88 <release>
}
    8000508a:	60e2                	ld	ra,24(sp)
    8000508c:	6442                	ld	s0,16(sp)
    8000508e:	64a2                	ld	s1,8(sp)
    80005090:	6902                	ld	s2,0(sp)
    80005092:	6105                	addi	sp,sp,32
    80005094:	8082                	ret

0000000080005096 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005096:	1101                	addi	sp,sp,-32
    80005098:	ec06                	sd	ra,24(sp)
    8000509a:	e822                	sd	s0,16(sp)
    8000509c:	e426                	sd	s1,8(sp)
    8000509e:	e04a                	sd	s2,0(sp)
    800050a0:	1000                	addi	s0,sp,32
    800050a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800050a4:	00850913          	addi	s2,a0,8
    800050a8:	854a                	mv	a0,s2
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	b18080e7          	jalr	-1256(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800050b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800050b6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	758080e7          	jalr	1880(ra) # 80002814 <wakeup>
  release(&lk->lk);
    800050c4:	854a                	mv	a0,s2
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	bc2080e7          	jalr	-1086(ra) # 80000c88 <release>
}
    800050ce:	60e2                	ld	ra,24(sp)
    800050d0:	6442                	ld	s0,16(sp)
    800050d2:	64a2                	ld	s1,8(sp)
    800050d4:	6902                	ld	s2,0(sp)
    800050d6:	6105                	addi	sp,sp,32
    800050d8:	8082                	ret

00000000800050da <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800050da:	7179                	addi	sp,sp,-48
    800050dc:	f406                	sd	ra,40(sp)
    800050de:	f022                	sd	s0,32(sp)
    800050e0:	ec26                	sd	s1,24(sp)
    800050e2:	e84a                	sd	s2,16(sp)
    800050e4:	e44e                	sd	s3,8(sp)
    800050e6:	1800                	addi	s0,sp,48
    800050e8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800050ea:	00850913          	addi	s2,a0,8
    800050ee:	854a                	mv	a0,s2
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	ad2080e7          	jalr	-1326(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800050f8:	409c                	lw	a5,0(s1)
    800050fa:	ef99                	bnez	a5,80005118 <holdingsleep+0x3e>
    800050fc:	4481                	li	s1,0
  release(&lk->lk);
    800050fe:	854a                	mv	a0,s2
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	b88080e7          	jalr	-1144(ra) # 80000c88 <release>
  return r;
}
    80005108:	8526                	mv	a0,s1
    8000510a:	70a2                	ld	ra,40(sp)
    8000510c:	7402                	ld	s0,32(sp)
    8000510e:	64e2                	ld	s1,24(sp)
    80005110:	6942                	ld	s2,16(sp)
    80005112:	69a2                	ld	s3,8(sp)
    80005114:	6145                	addi	sp,sp,48
    80005116:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005118:	0284a983          	lw	s3,40(s1)
    8000511c:	ffffd097          	auipc	ra,0xffffd
    80005120:	8da080e7          	jalr	-1830(ra) # 800019f6 <myproc>
    80005124:	5144                	lw	s1,36(a0)
    80005126:	413484b3          	sub	s1,s1,s3
    8000512a:	0014b493          	seqz	s1,s1
    8000512e:	bfc1                	j	800050fe <holdingsleep+0x24>

0000000080005130 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005130:	1141                	addi	sp,sp,-16
    80005132:	e406                	sd	ra,8(sp)
    80005134:	e022                	sd	s0,0(sp)
    80005136:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005138:	00003597          	auipc	a1,0x3
    8000513c:	5a858593          	addi	a1,a1,1448 # 800086e0 <syscalls+0x270>
    80005140:	00039517          	auipc	a0,0x39
    80005144:	8a850513          	addi	a0,a0,-1880 # 8003d9e8 <ftable>
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	9ea080e7          	jalr	-1558(ra) # 80000b32 <initlock>
}
    80005150:	60a2                	ld	ra,8(sp)
    80005152:	6402                	ld	s0,0(sp)
    80005154:	0141                	addi	sp,sp,16
    80005156:	8082                	ret

0000000080005158 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005158:	1101                	addi	sp,sp,-32
    8000515a:	ec06                	sd	ra,24(sp)
    8000515c:	e822                	sd	s0,16(sp)
    8000515e:	e426                	sd	s1,8(sp)
    80005160:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005162:	00039517          	auipc	a0,0x39
    80005166:	88650513          	addi	a0,a0,-1914 # 8003d9e8 <ftable>
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	a58080e7          	jalr	-1448(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005172:	00039497          	auipc	s1,0x39
    80005176:	88e48493          	addi	s1,s1,-1906 # 8003da00 <ftable+0x18>
    8000517a:	0003a717          	auipc	a4,0x3a
    8000517e:	82670713          	addi	a4,a4,-2010 # 8003e9a0 <ftable+0xfb8>
    if(f->ref == 0){
    80005182:	40dc                	lw	a5,4(s1)
    80005184:	cf99                	beqz	a5,800051a2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005186:	02848493          	addi	s1,s1,40
    8000518a:	fee49ce3          	bne	s1,a4,80005182 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000518e:	00039517          	auipc	a0,0x39
    80005192:	85a50513          	addi	a0,a0,-1958 # 8003d9e8 <ftable>
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	af2080e7          	jalr	-1294(ra) # 80000c88 <release>
  return 0;
    8000519e:	4481                	li	s1,0
    800051a0:	a819                	j	800051b6 <filealloc+0x5e>
      f->ref = 1;
    800051a2:	4785                	li	a5,1
    800051a4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800051a6:	00039517          	auipc	a0,0x39
    800051aa:	84250513          	addi	a0,a0,-1982 # 8003d9e8 <ftable>
    800051ae:	ffffc097          	auipc	ra,0xffffc
    800051b2:	ada080e7          	jalr	-1318(ra) # 80000c88 <release>
}
    800051b6:	8526                	mv	a0,s1
    800051b8:	60e2                	ld	ra,24(sp)
    800051ba:	6442                	ld	s0,16(sp)
    800051bc:	64a2                	ld	s1,8(sp)
    800051be:	6105                	addi	sp,sp,32
    800051c0:	8082                	ret

00000000800051c2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800051c2:	1101                	addi	sp,sp,-32
    800051c4:	ec06                	sd	ra,24(sp)
    800051c6:	e822                	sd	s0,16(sp)
    800051c8:	e426                	sd	s1,8(sp)
    800051ca:	1000                	addi	s0,sp,32
    800051cc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800051ce:	00039517          	auipc	a0,0x39
    800051d2:	81a50513          	addi	a0,a0,-2022 # 8003d9e8 <ftable>
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	9ec080e7          	jalr	-1556(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800051de:	40dc                	lw	a5,4(s1)
    800051e0:	02f05263          	blez	a5,80005204 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800051e4:	2785                	addiw	a5,a5,1
    800051e6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800051e8:	00039517          	auipc	a0,0x39
    800051ec:	80050513          	addi	a0,a0,-2048 # 8003d9e8 <ftable>
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	a98080e7          	jalr	-1384(ra) # 80000c88 <release>
  return f;
}
    800051f8:	8526                	mv	a0,s1
    800051fa:	60e2                	ld	ra,24(sp)
    800051fc:	6442                	ld	s0,16(sp)
    800051fe:	64a2                	ld	s1,8(sp)
    80005200:	6105                	addi	sp,sp,32
    80005202:	8082                	ret
    panic("filedup");
    80005204:	00003517          	auipc	a0,0x3
    80005208:	4e450513          	addi	a0,a0,1252 # 800086e8 <syscalls+0x278>
    8000520c:	ffffb097          	auipc	ra,0xffffb
    80005210:	31e080e7          	jalr	798(ra) # 8000052a <panic>

0000000080005214 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005214:	7139                	addi	sp,sp,-64
    80005216:	fc06                	sd	ra,56(sp)
    80005218:	f822                	sd	s0,48(sp)
    8000521a:	f426                	sd	s1,40(sp)
    8000521c:	f04a                	sd	s2,32(sp)
    8000521e:	ec4e                	sd	s3,24(sp)
    80005220:	e852                	sd	s4,16(sp)
    80005222:	e456                	sd	s5,8(sp)
    80005224:	0080                	addi	s0,sp,64
    80005226:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005228:	00038517          	auipc	a0,0x38
    8000522c:	7c050513          	addi	a0,a0,1984 # 8003d9e8 <ftable>
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	992080e7          	jalr	-1646(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80005238:	40dc                	lw	a5,4(s1)
    8000523a:	06f05163          	blez	a5,8000529c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000523e:	37fd                	addiw	a5,a5,-1
    80005240:	0007871b          	sext.w	a4,a5
    80005244:	c0dc                	sw	a5,4(s1)
    80005246:	06e04363          	bgtz	a4,800052ac <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000524a:	0004a903          	lw	s2,0(s1)
    8000524e:	0094ca83          	lbu	s5,9(s1)
    80005252:	0104ba03          	ld	s4,16(s1)
    80005256:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000525a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000525e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005262:	00038517          	auipc	a0,0x38
    80005266:	78650513          	addi	a0,a0,1926 # 8003d9e8 <ftable>
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	a1e080e7          	jalr	-1506(ra) # 80000c88 <release>

  if(ff.type == FD_PIPE){
    80005272:	4785                	li	a5,1
    80005274:	04f90d63          	beq	s2,a5,800052ce <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005278:	3979                	addiw	s2,s2,-2
    8000527a:	4785                	li	a5,1
    8000527c:	0527e063          	bltu	a5,s2,800052bc <fileclose+0xa8>
    begin_op();
    80005280:	00000097          	auipc	ra,0x0
    80005284:	ac8080e7          	jalr	-1336(ra) # 80004d48 <begin_op>
    iput(ff.ip);
    80005288:	854e                	mv	a0,s3
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	2a2080e7          	jalr	674(ra) # 8000452c <iput>
    end_op();
    80005292:	00000097          	auipc	ra,0x0
    80005296:	b36080e7          	jalr	-1226(ra) # 80004dc8 <end_op>
    8000529a:	a00d                	j	800052bc <fileclose+0xa8>
    panic("fileclose");
    8000529c:	00003517          	auipc	a0,0x3
    800052a0:	45450513          	addi	a0,a0,1108 # 800086f0 <syscalls+0x280>
    800052a4:	ffffb097          	auipc	ra,0xffffb
    800052a8:	286080e7          	jalr	646(ra) # 8000052a <panic>
    release(&ftable.lock);
    800052ac:	00038517          	auipc	a0,0x38
    800052b0:	73c50513          	addi	a0,a0,1852 # 8003d9e8 <ftable>
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	9d4080e7          	jalr	-1580(ra) # 80000c88 <release>
  }
}
    800052bc:	70e2                	ld	ra,56(sp)
    800052be:	7442                	ld	s0,48(sp)
    800052c0:	74a2                	ld	s1,40(sp)
    800052c2:	7902                	ld	s2,32(sp)
    800052c4:	69e2                	ld	s3,24(sp)
    800052c6:	6a42                	ld	s4,16(sp)
    800052c8:	6aa2                	ld	s5,8(sp)
    800052ca:	6121                	addi	sp,sp,64
    800052cc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800052ce:	85d6                	mv	a1,s5
    800052d0:	8552                	mv	a0,s4
    800052d2:	00000097          	auipc	ra,0x0
    800052d6:	34c080e7          	jalr	844(ra) # 8000561e <pipeclose>
    800052da:	b7cd                	j	800052bc <fileclose+0xa8>

00000000800052dc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800052dc:	715d                	addi	sp,sp,-80
    800052de:	e486                	sd	ra,72(sp)
    800052e0:	e0a2                	sd	s0,64(sp)
    800052e2:	fc26                	sd	s1,56(sp)
    800052e4:	f84a                	sd	s2,48(sp)
    800052e6:	f44e                	sd	s3,40(sp)
    800052e8:	0880                	addi	s0,sp,80
    800052ea:	84aa                	mv	s1,a0
    800052ec:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	708080e7          	jalr	1800(ra) # 800019f6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800052f6:	409c                	lw	a5,0(s1)
    800052f8:	37f9                	addiw	a5,a5,-2
    800052fa:	4705                	li	a4,1
    800052fc:	04f76763          	bltu	a4,a5,8000534a <filestat+0x6e>
    80005300:	892a                	mv	s2,a0
    ilock(f->ip);
    80005302:	6c88                	ld	a0,24(s1)
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	06e080e7          	jalr	110(ra) # 80004372 <ilock>
    stati(f->ip, &st);
    8000530c:	fb840593          	addi	a1,s0,-72
    80005310:	6c88                	ld	a0,24(s1)
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	2ea080e7          	jalr	746(ra) # 800045fc <stati>
    iunlock(f->ip);
    8000531a:	6c88                	ld	a0,24(s1)
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	118080e7          	jalr	280(ra) # 80004434 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005324:	46e1                	li	a3,24
    80005326:	fb840613          	addi	a2,s0,-72
    8000532a:	85ce                	mv	a1,s3
    8000532c:	1d893503          	ld	a0,472(s2)
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	332080e7          	jalr	818(ra) # 80001662 <copyout>
    80005338:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000533c:	60a6                	ld	ra,72(sp)
    8000533e:	6406                	ld	s0,64(sp)
    80005340:	74e2                	ld	s1,56(sp)
    80005342:	7942                	ld	s2,48(sp)
    80005344:	79a2                	ld	s3,40(sp)
    80005346:	6161                	addi	sp,sp,80
    80005348:	8082                	ret
  return -1;
    8000534a:	557d                	li	a0,-1
    8000534c:	bfc5                	j	8000533c <filestat+0x60>

000000008000534e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000534e:	7179                	addi	sp,sp,-48
    80005350:	f406                	sd	ra,40(sp)
    80005352:	f022                	sd	s0,32(sp)
    80005354:	ec26                	sd	s1,24(sp)
    80005356:	e84a                	sd	s2,16(sp)
    80005358:	e44e                	sd	s3,8(sp)
    8000535a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000535c:	00854783          	lbu	a5,8(a0)
    80005360:	c3d5                	beqz	a5,80005404 <fileread+0xb6>
    80005362:	84aa                	mv	s1,a0
    80005364:	89ae                	mv	s3,a1
    80005366:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005368:	411c                	lw	a5,0(a0)
    8000536a:	4705                	li	a4,1
    8000536c:	04e78963          	beq	a5,a4,800053be <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005370:	470d                	li	a4,3
    80005372:	04e78d63          	beq	a5,a4,800053cc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005376:	4709                	li	a4,2
    80005378:	06e79e63          	bne	a5,a4,800053f4 <fileread+0xa6>
    ilock(f->ip);
    8000537c:	6d08                	ld	a0,24(a0)
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	ff4080e7          	jalr	-12(ra) # 80004372 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005386:	874a                	mv	a4,s2
    80005388:	5094                	lw	a3,32(s1)
    8000538a:	864e                	mv	a2,s3
    8000538c:	4585                	li	a1,1
    8000538e:	6c88                	ld	a0,24(s1)
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	296080e7          	jalr	662(ra) # 80004626 <readi>
    80005398:	892a                	mv	s2,a0
    8000539a:	00a05563          	blez	a0,800053a4 <fileread+0x56>
      f->off += r;
    8000539e:	509c                	lw	a5,32(s1)
    800053a0:	9fa9                	addw	a5,a5,a0
    800053a2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800053a4:	6c88                	ld	a0,24(s1)
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	08e080e7          	jalr	142(ra) # 80004434 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800053ae:	854a                	mv	a0,s2
    800053b0:	70a2                	ld	ra,40(sp)
    800053b2:	7402                	ld	s0,32(sp)
    800053b4:	64e2                	ld	s1,24(sp)
    800053b6:	6942                	ld	s2,16(sp)
    800053b8:	69a2                	ld	s3,8(sp)
    800053ba:	6145                	addi	sp,sp,48
    800053bc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800053be:	6908                	ld	a0,16(a0)
    800053c0:	00000097          	auipc	ra,0x0
    800053c4:	3c0080e7          	jalr	960(ra) # 80005780 <piperead>
    800053c8:	892a                	mv	s2,a0
    800053ca:	b7d5                	j	800053ae <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800053cc:	02451783          	lh	a5,36(a0)
    800053d0:	03079693          	slli	a3,a5,0x30
    800053d4:	92c1                	srli	a3,a3,0x30
    800053d6:	4725                	li	a4,9
    800053d8:	02d76863          	bltu	a4,a3,80005408 <fileread+0xba>
    800053dc:	0792                	slli	a5,a5,0x4
    800053de:	00038717          	auipc	a4,0x38
    800053e2:	56a70713          	addi	a4,a4,1386 # 8003d948 <devsw>
    800053e6:	97ba                	add	a5,a5,a4
    800053e8:	639c                	ld	a5,0(a5)
    800053ea:	c38d                	beqz	a5,8000540c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800053ec:	4505                	li	a0,1
    800053ee:	9782                	jalr	a5
    800053f0:	892a                	mv	s2,a0
    800053f2:	bf75                	j	800053ae <fileread+0x60>
    panic("fileread");
    800053f4:	00003517          	auipc	a0,0x3
    800053f8:	30c50513          	addi	a0,a0,780 # 80008700 <syscalls+0x290>
    800053fc:	ffffb097          	auipc	ra,0xffffb
    80005400:	12e080e7          	jalr	302(ra) # 8000052a <panic>
    return -1;
    80005404:	597d                	li	s2,-1
    80005406:	b765                	j	800053ae <fileread+0x60>
      return -1;
    80005408:	597d                	li	s2,-1
    8000540a:	b755                	j	800053ae <fileread+0x60>
    8000540c:	597d                	li	s2,-1
    8000540e:	b745                	j	800053ae <fileread+0x60>

0000000080005410 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005410:	715d                	addi	sp,sp,-80
    80005412:	e486                	sd	ra,72(sp)
    80005414:	e0a2                	sd	s0,64(sp)
    80005416:	fc26                	sd	s1,56(sp)
    80005418:	f84a                	sd	s2,48(sp)
    8000541a:	f44e                	sd	s3,40(sp)
    8000541c:	f052                	sd	s4,32(sp)
    8000541e:	ec56                	sd	s5,24(sp)
    80005420:	e85a                	sd	s6,16(sp)
    80005422:	e45e                	sd	s7,8(sp)
    80005424:	e062                	sd	s8,0(sp)
    80005426:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005428:	00954783          	lbu	a5,9(a0)
    8000542c:	10078663          	beqz	a5,80005538 <filewrite+0x128>
    80005430:	892a                	mv	s2,a0
    80005432:	8aae                	mv	s5,a1
    80005434:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005436:	411c                	lw	a5,0(a0)
    80005438:	4705                	li	a4,1
    8000543a:	02e78263          	beq	a5,a4,8000545e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000543e:	470d                	li	a4,3
    80005440:	02e78663          	beq	a5,a4,8000546c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005444:	4709                	li	a4,2
    80005446:	0ee79163          	bne	a5,a4,80005528 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000544a:	0ac05d63          	blez	a2,80005504 <filewrite+0xf4>
    int i = 0;
    8000544e:	4981                	li	s3,0
    80005450:	6b05                	lui	s6,0x1
    80005452:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005456:	6b85                	lui	s7,0x1
    80005458:	c00b8b9b          	addiw	s7,s7,-1024
    8000545c:	a861                	j	800054f4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000545e:	6908                	ld	a0,16(a0)
    80005460:	00000097          	auipc	ra,0x0
    80005464:	22e080e7          	jalr	558(ra) # 8000568e <pipewrite>
    80005468:	8a2a                	mv	s4,a0
    8000546a:	a045                	j	8000550a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000546c:	02451783          	lh	a5,36(a0)
    80005470:	03079693          	slli	a3,a5,0x30
    80005474:	92c1                	srli	a3,a3,0x30
    80005476:	4725                	li	a4,9
    80005478:	0cd76263          	bltu	a4,a3,8000553c <filewrite+0x12c>
    8000547c:	0792                	slli	a5,a5,0x4
    8000547e:	00038717          	auipc	a4,0x38
    80005482:	4ca70713          	addi	a4,a4,1226 # 8003d948 <devsw>
    80005486:	97ba                	add	a5,a5,a4
    80005488:	679c                	ld	a5,8(a5)
    8000548a:	cbdd                	beqz	a5,80005540 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000548c:	4505                	li	a0,1
    8000548e:	9782                	jalr	a5
    80005490:	8a2a                	mv	s4,a0
    80005492:	a8a5                	j	8000550a <filewrite+0xfa>
    80005494:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005498:	00000097          	auipc	ra,0x0
    8000549c:	8b0080e7          	jalr	-1872(ra) # 80004d48 <begin_op>
      ilock(f->ip);
    800054a0:	01893503          	ld	a0,24(s2)
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	ece080e7          	jalr	-306(ra) # 80004372 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800054ac:	8762                	mv	a4,s8
    800054ae:	02092683          	lw	a3,32(s2)
    800054b2:	01598633          	add	a2,s3,s5
    800054b6:	4585                	li	a1,1
    800054b8:	01893503          	ld	a0,24(s2)
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	262080e7          	jalr	610(ra) # 8000471e <writei>
    800054c4:	84aa                	mv	s1,a0
    800054c6:	00a05763          	blez	a0,800054d4 <filewrite+0xc4>
        f->off += r;
    800054ca:	02092783          	lw	a5,32(s2)
    800054ce:	9fa9                	addw	a5,a5,a0
    800054d0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800054d4:	01893503          	ld	a0,24(s2)
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	f5c080e7          	jalr	-164(ra) # 80004434 <iunlock>
      end_op();
    800054e0:	00000097          	auipc	ra,0x0
    800054e4:	8e8080e7          	jalr	-1816(ra) # 80004dc8 <end_op>

      if(r != n1){
    800054e8:	009c1f63          	bne	s8,s1,80005506 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800054ec:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800054f0:	0149db63          	bge	s3,s4,80005506 <filewrite+0xf6>
      int n1 = n - i;
    800054f4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800054f8:	84be                	mv	s1,a5
    800054fa:	2781                	sext.w	a5,a5
    800054fc:	f8fb5ce3          	bge	s6,a5,80005494 <filewrite+0x84>
    80005500:	84de                	mv	s1,s7
    80005502:	bf49                	j	80005494 <filewrite+0x84>
    int i = 0;
    80005504:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005506:	013a1f63          	bne	s4,s3,80005524 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000550a:	8552                	mv	a0,s4
    8000550c:	60a6                	ld	ra,72(sp)
    8000550e:	6406                	ld	s0,64(sp)
    80005510:	74e2                	ld	s1,56(sp)
    80005512:	7942                	ld	s2,48(sp)
    80005514:	79a2                	ld	s3,40(sp)
    80005516:	7a02                	ld	s4,32(sp)
    80005518:	6ae2                	ld	s5,24(sp)
    8000551a:	6b42                	ld	s6,16(sp)
    8000551c:	6ba2                	ld	s7,8(sp)
    8000551e:	6c02                	ld	s8,0(sp)
    80005520:	6161                	addi	sp,sp,80
    80005522:	8082                	ret
    ret = (i == n ? n : -1);
    80005524:	5a7d                	li	s4,-1
    80005526:	b7d5                	j	8000550a <filewrite+0xfa>
    panic("filewrite");
    80005528:	00003517          	auipc	a0,0x3
    8000552c:	1e850513          	addi	a0,a0,488 # 80008710 <syscalls+0x2a0>
    80005530:	ffffb097          	auipc	ra,0xffffb
    80005534:	ffa080e7          	jalr	-6(ra) # 8000052a <panic>
    return -1;
    80005538:	5a7d                	li	s4,-1
    8000553a:	bfc1                	j	8000550a <filewrite+0xfa>
      return -1;
    8000553c:	5a7d                	li	s4,-1
    8000553e:	b7f1                	j	8000550a <filewrite+0xfa>
    80005540:	5a7d                	li	s4,-1
    80005542:	b7e1                	j	8000550a <filewrite+0xfa>

0000000080005544 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005544:	7179                	addi	sp,sp,-48
    80005546:	f406                	sd	ra,40(sp)
    80005548:	f022                	sd	s0,32(sp)
    8000554a:	ec26                	sd	s1,24(sp)
    8000554c:	e84a                	sd	s2,16(sp)
    8000554e:	e44e                	sd	s3,8(sp)
    80005550:	e052                	sd	s4,0(sp)
    80005552:	1800                	addi	s0,sp,48
    80005554:	84aa                	mv	s1,a0
    80005556:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005558:	0005b023          	sd	zero,0(a1)
    8000555c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005560:	00000097          	auipc	ra,0x0
    80005564:	bf8080e7          	jalr	-1032(ra) # 80005158 <filealloc>
    80005568:	e088                	sd	a0,0(s1)
    8000556a:	c551                	beqz	a0,800055f6 <pipealloc+0xb2>
    8000556c:	00000097          	auipc	ra,0x0
    80005570:	bec080e7          	jalr	-1044(ra) # 80005158 <filealloc>
    80005574:	00aa3023          	sd	a0,0(s4)
    80005578:	c92d                	beqz	a0,800055ea <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000557a:	ffffb097          	auipc	ra,0xffffb
    8000557e:	558080e7          	jalr	1368(ra) # 80000ad2 <kalloc>
    80005582:	892a                	mv	s2,a0
    80005584:	c125                	beqz	a0,800055e4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005586:	4985                	li	s3,1
    80005588:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000558c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005590:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005594:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005598:	00003597          	auipc	a1,0x3
    8000559c:	18858593          	addi	a1,a1,392 # 80008720 <syscalls+0x2b0>
    800055a0:	ffffb097          	auipc	ra,0xffffb
    800055a4:	592080e7          	jalr	1426(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800055a8:	609c                	ld	a5,0(s1)
    800055aa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800055ae:	609c                	ld	a5,0(s1)
    800055b0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800055b4:	609c                	ld	a5,0(s1)
    800055b6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800055ba:	609c                	ld	a5,0(s1)
    800055bc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800055c0:	000a3783          	ld	a5,0(s4)
    800055c4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800055c8:	000a3783          	ld	a5,0(s4)
    800055cc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800055d0:	000a3783          	ld	a5,0(s4)
    800055d4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800055d8:	000a3783          	ld	a5,0(s4)
    800055dc:	0127b823          	sd	s2,16(a5)
  return 0;
    800055e0:	4501                	li	a0,0
    800055e2:	a025                	j	8000560a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800055e4:	6088                	ld	a0,0(s1)
    800055e6:	e501                	bnez	a0,800055ee <pipealloc+0xaa>
    800055e8:	a039                	j	800055f6 <pipealloc+0xb2>
    800055ea:	6088                	ld	a0,0(s1)
    800055ec:	c51d                	beqz	a0,8000561a <pipealloc+0xd6>
    fileclose(*f0);
    800055ee:	00000097          	auipc	ra,0x0
    800055f2:	c26080e7          	jalr	-986(ra) # 80005214 <fileclose>
  if(*f1)
    800055f6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800055fa:	557d                	li	a0,-1
  if(*f1)
    800055fc:	c799                	beqz	a5,8000560a <pipealloc+0xc6>
    fileclose(*f1);
    800055fe:	853e                	mv	a0,a5
    80005600:	00000097          	auipc	ra,0x0
    80005604:	c14080e7          	jalr	-1004(ra) # 80005214 <fileclose>
  return -1;
    80005608:	557d                	li	a0,-1
}
    8000560a:	70a2                	ld	ra,40(sp)
    8000560c:	7402                	ld	s0,32(sp)
    8000560e:	64e2                	ld	s1,24(sp)
    80005610:	6942                	ld	s2,16(sp)
    80005612:	69a2                	ld	s3,8(sp)
    80005614:	6a02                	ld	s4,0(sp)
    80005616:	6145                	addi	sp,sp,48
    80005618:	8082                	ret
  return -1;
    8000561a:	557d                	li	a0,-1
    8000561c:	b7fd                	j	8000560a <pipealloc+0xc6>

000000008000561e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000561e:	1101                	addi	sp,sp,-32
    80005620:	ec06                	sd	ra,24(sp)
    80005622:	e822                	sd	s0,16(sp)
    80005624:	e426                	sd	s1,8(sp)
    80005626:	e04a                	sd	s2,0(sp)
    80005628:	1000                	addi	s0,sp,32
    8000562a:	84aa                	mv	s1,a0
    8000562c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000562e:	ffffb097          	auipc	ra,0xffffb
    80005632:	594080e7          	jalr	1428(ra) # 80000bc2 <acquire>
  if(writable){
    80005636:	02090d63          	beqz	s2,80005670 <pipeclose+0x52>
    pi->writeopen = 0;
    8000563a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000563e:	21848513          	addi	a0,s1,536
    80005642:	ffffd097          	auipc	ra,0xffffd
    80005646:	1d2080e7          	jalr	466(ra) # 80002814 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000564a:	2204b783          	ld	a5,544(s1)
    8000564e:	eb95                	bnez	a5,80005682 <pipeclose+0x64>
    release(&pi->lock);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffb097          	auipc	ra,0xffffb
    80005656:	636080e7          	jalr	1590(ra) # 80000c88 <release>
    kfree((char*)pi);
    8000565a:	8526                	mv	a0,s1
    8000565c:	ffffb097          	auipc	ra,0xffffb
    80005660:	37a080e7          	jalr	890(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005664:	60e2                	ld	ra,24(sp)
    80005666:	6442                	ld	s0,16(sp)
    80005668:	64a2                	ld	s1,8(sp)
    8000566a:	6902                	ld	s2,0(sp)
    8000566c:	6105                	addi	sp,sp,32
    8000566e:	8082                	ret
    pi->readopen = 0;
    80005670:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005674:	21c48513          	addi	a0,s1,540
    80005678:	ffffd097          	auipc	ra,0xffffd
    8000567c:	19c080e7          	jalr	412(ra) # 80002814 <wakeup>
    80005680:	b7e9                	j	8000564a <pipeclose+0x2c>
    release(&pi->lock);
    80005682:	8526                	mv	a0,s1
    80005684:	ffffb097          	auipc	ra,0xffffb
    80005688:	604080e7          	jalr	1540(ra) # 80000c88 <release>
}
    8000568c:	bfe1                	j	80005664 <pipeclose+0x46>

000000008000568e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000568e:	711d                	addi	sp,sp,-96
    80005690:	ec86                	sd	ra,88(sp)
    80005692:	e8a2                	sd	s0,80(sp)
    80005694:	e4a6                	sd	s1,72(sp)
    80005696:	e0ca                	sd	s2,64(sp)
    80005698:	fc4e                	sd	s3,56(sp)
    8000569a:	f852                	sd	s4,48(sp)
    8000569c:	f456                	sd	s5,40(sp)
    8000569e:	f05a                	sd	s6,32(sp)
    800056a0:	ec5e                	sd	s7,24(sp)
    800056a2:	e862                	sd	s8,16(sp)
    800056a4:	1080                	addi	s0,sp,96
    800056a6:	84aa                	mv	s1,a0
    800056a8:	8aae                	mv	s5,a1
    800056aa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800056ac:	ffffc097          	auipc	ra,0xffffc
    800056b0:	34a080e7          	jalr	842(ra) # 800019f6 <myproc>
    800056b4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800056b6:	8526                	mv	a0,s1
    800056b8:	ffffb097          	auipc	ra,0xffffb
    800056bc:	50a080e7          	jalr	1290(ra) # 80000bc2 <acquire>
  while(i < n){
    800056c0:	0b405363          	blez	s4,80005766 <pipewrite+0xd8>
  int i = 0;
    800056c4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056c6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800056c8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800056cc:	21c48b93          	addi	s7,s1,540
    800056d0:	a089                	j	80005712 <pipewrite+0x84>
      release(&pi->lock);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffb097          	auipc	ra,0xffffb
    800056d8:	5b4080e7          	jalr	1460(ra) # 80000c88 <release>
      return -1;
    800056dc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800056de:	854a                	mv	a0,s2
    800056e0:	60e6                	ld	ra,88(sp)
    800056e2:	6446                	ld	s0,80(sp)
    800056e4:	64a6                	ld	s1,72(sp)
    800056e6:	6906                	ld	s2,64(sp)
    800056e8:	79e2                	ld	s3,56(sp)
    800056ea:	7a42                	ld	s4,48(sp)
    800056ec:	7aa2                	ld	s5,40(sp)
    800056ee:	7b02                	ld	s6,32(sp)
    800056f0:	6be2                	ld	s7,24(sp)
    800056f2:	6c42                	ld	s8,16(sp)
    800056f4:	6125                	addi	sp,sp,96
    800056f6:	8082                	ret
      wakeup(&pi->nread);
    800056f8:	8562                	mv	a0,s8
    800056fa:	ffffd097          	auipc	ra,0xffffd
    800056fe:	11a080e7          	jalr	282(ra) # 80002814 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005702:	85a6                	mv	a1,s1
    80005704:	855e                	mv	a0,s7
    80005706:	ffffd097          	auipc	ra,0xffffd
    8000570a:	f84080e7          	jalr	-124(ra) # 8000268a <sleep>
  while(i < n){
    8000570e:	05495d63          	bge	s2,s4,80005768 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005712:	2204a783          	lw	a5,544(s1)
    80005716:	dfd5                	beqz	a5,800056d2 <pipewrite+0x44>
    80005718:	01c9a783          	lw	a5,28(s3)
    8000571c:	fbdd                	bnez	a5,800056d2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000571e:	2184a783          	lw	a5,536(s1)
    80005722:	21c4a703          	lw	a4,540(s1)
    80005726:	2007879b          	addiw	a5,a5,512
    8000572a:	fcf707e3          	beq	a4,a5,800056f8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000572e:	4685                	li	a3,1
    80005730:	01590633          	add	a2,s2,s5
    80005734:	faf40593          	addi	a1,s0,-81
    80005738:	1d89b503          	ld	a0,472(s3)
    8000573c:	ffffc097          	auipc	ra,0xffffc
    80005740:	fb2080e7          	jalr	-78(ra) # 800016ee <copyin>
    80005744:	03650263          	beq	a0,s6,80005768 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005748:	21c4a783          	lw	a5,540(s1)
    8000574c:	0017871b          	addiw	a4,a5,1
    80005750:	20e4ae23          	sw	a4,540(s1)
    80005754:	1ff7f793          	andi	a5,a5,511
    80005758:	97a6                	add	a5,a5,s1
    8000575a:	faf44703          	lbu	a4,-81(s0)
    8000575e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005762:	2905                	addiw	s2,s2,1
    80005764:	b76d                	j	8000570e <pipewrite+0x80>
  int i = 0;
    80005766:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005768:	21848513          	addi	a0,s1,536
    8000576c:	ffffd097          	auipc	ra,0xffffd
    80005770:	0a8080e7          	jalr	168(ra) # 80002814 <wakeup>
  release(&pi->lock);
    80005774:	8526                	mv	a0,s1
    80005776:	ffffb097          	auipc	ra,0xffffb
    8000577a:	512080e7          	jalr	1298(ra) # 80000c88 <release>
  return i;
    8000577e:	b785                	j	800056de <pipewrite+0x50>

0000000080005780 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005780:	715d                	addi	sp,sp,-80
    80005782:	e486                	sd	ra,72(sp)
    80005784:	e0a2                	sd	s0,64(sp)
    80005786:	fc26                	sd	s1,56(sp)
    80005788:	f84a                	sd	s2,48(sp)
    8000578a:	f44e                	sd	s3,40(sp)
    8000578c:	f052                	sd	s4,32(sp)
    8000578e:	ec56                	sd	s5,24(sp)
    80005790:	e85a                	sd	s6,16(sp)
    80005792:	0880                	addi	s0,sp,80
    80005794:	84aa                	mv	s1,a0
    80005796:	892e                	mv	s2,a1
    80005798:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000579a:	ffffc097          	auipc	ra,0xffffc
    8000579e:	25c080e7          	jalr	604(ra) # 800019f6 <myproc>
    800057a2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800057a4:	8526                	mv	a0,s1
    800057a6:	ffffb097          	auipc	ra,0xffffb
    800057aa:	41c080e7          	jalr	1052(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057ae:	2184a703          	lw	a4,536(s1)
    800057b2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800057b6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057ba:	02f71463          	bne	a4,a5,800057e2 <piperead+0x62>
    800057be:	2244a783          	lw	a5,548(s1)
    800057c2:	c385                	beqz	a5,800057e2 <piperead+0x62>
    if(pr->killed){
    800057c4:	01ca2783          	lw	a5,28(s4)
    800057c8:	ebc1                	bnez	a5,80005858 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800057ca:	85a6                	mv	a1,s1
    800057cc:	854e                	mv	a0,s3
    800057ce:	ffffd097          	auipc	ra,0xffffd
    800057d2:	ebc080e7          	jalr	-324(ra) # 8000268a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057d6:	2184a703          	lw	a4,536(s1)
    800057da:	21c4a783          	lw	a5,540(s1)
    800057de:	fef700e3          	beq	a4,a5,800057be <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057e2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057e4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057e6:	05505363          	blez	s5,8000582c <piperead+0xac>
    if(pi->nread == pi->nwrite)
    800057ea:	2184a783          	lw	a5,536(s1)
    800057ee:	21c4a703          	lw	a4,540(s1)
    800057f2:	02f70d63          	beq	a4,a5,8000582c <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800057f6:	0017871b          	addiw	a4,a5,1
    800057fa:	20e4ac23          	sw	a4,536(s1)
    800057fe:	1ff7f793          	andi	a5,a5,511
    80005802:	97a6                	add	a5,a5,s1
    80005804:	0187c783          	lbu	a5,24(a5)
    80005808:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000580c:	4685                	li	a3,1
    8000580e:	fbf40613          	addi	a2,s0,-65
    80005812:	85ca                	mv	a1,s2
    80005814:	1d8a3503          	ld	a0,472(s4)
    80005818:	ffffc097          	auipc	ra,0xffffc
    8000581c:	e4a080e7          	jalr	-438(ra) # 80001662 <copyout>
    80005820:	01650663          	beq	a0,s6,8000582c <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005824:	2985                	addiw	s3,s3,1
    80005826:	0905                	addi	s2,s2,1
    80005828:	fd3a91e3          	bne	s5,s3,800057ea <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000582c:	21c48513          	addi	a0,s1,540
    80005830:	ffffd097          	auipc	ra,0xffffd
    80005834:	fe4080e7          	jalr	-28(ra) # 80002814 <wakeup>
  release(&pi->lock);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffb097          	auipc	ra,0xffffb
    8000583e:	44e080e7          	jalr	1102(ra) # 80000c88 <release>
  return i;
}
    80005842:	854e                	mv	a0,s3
    80005844:	60a6                	ld	ra,72(sp)
    80005846:	6406                	ld	s0,64(sp)
    80005848:	74e2                	ld	s1,56(sp)
    8000584a:	7942                	ld	s2,48(sp)
    8000584c:	79a2                	ld	s3,40(sp)
    8000584e:	7a02                	ld	s4,32(sp)
    80005850:	6ae2                	ld	s5,24(sp)
    80005852:	6b42                	ld	s6,16(sp)
    80005854:	6161                	addi	sp,sp,80
    80005856:	8082                	ret
      release(&pi->lock);
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffb097          	auipc	ra,0xffffb
    8000585e:	42e080e7          	jalr	1070(ra) # 80000c88 <release>
      return -1;
    80005862:	59fd                	li	s3,-1
    80005864:	bff9                	j	80005842 <piperead+0xc2>

0000000080005866 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005866:	dd010113          	addi	sp,sp,-560
    8000586a:	22113423          	sd	ra,552(sp)
    8000586e:	22813023          	sd	s0,544(sp)
    80005872:	20913c23          	sd	s1,536(sp)
    80005876:	21213823          	sd	s2,528(sp)
    8000587a:	21313423          	sd	s3,520(sp)
    8000587e:	21413023          	sd	s4,512(sp)
    80005882:	ffd6                	sd	s5,504(sp)
    80005884:	fbda                	sd	s6,496(sp)
    80005886:	f7de                	sd	s7,488(sp)
    80005888:	f3e2                	sd	s8,480(sp)
    8000588a:	efe6                	sd	s9,472(sp)
    8000588c:	ebea                	sd	s10,464(sp)
    8000588e:	e7ee                	sd	s11,456(sp)
    80005890:	1c00                	addi	s0,sp,560
    80005892:	84aa                	mv	s1,a0
    80005894:	dea43023          	sd	a0,-544(s0)
    80005898:	deb43423          	sd	a1,-536(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000589c:	ffffc097          	auipc	ra,0xffffc
    800058a0:	15a080e7          	jalr	346(ra) # 800019f6 <myproc>
    800058a4:	89aa                	mv	s3,a0
  struct thread *t = mythread();
    800058a6:	ffffc097          	auipc	ra,0xffffc
    800058aa:	18a080e7          	jalr	394(ra) # 80001a30 <mythread>
    800058ae:	e0a43423          	sd	a0,-504(s0)
  begin_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	496080e7          	jalr	1174(ra) # 80004d48 <begin_op>

  if((ip = namei(path)) == 0){
    800058ba:	8526                	mv	a0,s1
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	26c080e7          	jalr	620(ra) # 80004b28 <namei>
    800058c4:	c50d                	beqz	a0,800058ee <exec+0x88>
    800058c6:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	aaa080e7          	jalr	-1366(ra) # 80004372 <ilock>

  // ADDED Q3
  acquire(&p->lock); //TOOD: decide where to put this block
    800058d0:	854e                	mv	a0,s3
    800058d2:	ffffb097          	auipc	ra,0xffffb
    800058d6:	2f0080e7          	jalr	752(ra) # 80000bc2 <acquire>
   for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    800058da:	27898493          	addi	s1,s3,632
    800058de:	6905                	lui	s2,0x1
    800058e0:	87890913          	addi	s2,s2,-1928 # 878 <_entry-0x7ffff788>
    800058e4:	994e                	add	s2,s2,s3
    if(t_temp->tid != t->tid){
      acquire(&t_temp->lock);
      t_temp->terminated = 1;
    800058e6:	4b05                	li	s6,1
      if(t_temp->state == SLEEPING){
    800058e8:	4a09                	li	s4,2
        t_temp->state = RUNNABLE;
    800058ea:	4b8d                	li	s7,3
    800058ec:	a035                	j	80005918 <exec+0xb2>
    end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	4da080e7          	jalr	1242(ra) # 80004dc8 <end_op>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	a849                	j	8000598a <exec+0x124>
      }
      release(&t_temp->lock);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffb097          	auipc	ra,0xffffb
    80005900:	38c080e7          	jalr	908(ra) # 80000c88 <release>
      kthread_join(t_temp->tid, 0);
    80005904:	4581                	li	a1,0
    80005906:	5888                	lw	a0,48(s1)
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	4f4080e7          	jalr	1268(ra) # 80002dfc <kthread_join>
   for(struct thread *t_temp = p->threads; t_temp < &p->threads[NTHREAD]; t_temp++){ 
    80005910:	0c048493          	addi	s1,s1,192
    80005914:	03248563          	beq	s1,s2,8000593e <exec+0xd8>
    if(t_temp->tid != t->tid){
    80005918:	5898                	lw	a4,48(s1)
    8000591a:	e0843783          	ld	a5,-504(s0)
    8000591e:	5b9c                	lw	a5,48(a5)
    80005920:	fef708e3          	beq	a4,a5,80005910 <exec+0xaa>
      acquire(&t_temp->lock);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffb097          	auipc	ra,0xffffb
    8000592a:	29c080e7          	jalr	668(ra) # 80000bc2 <acquire>
      t_temp->terminated = 1;
    8000592e:	0364a423          	sw	s6,40(s1)
      if(t_temp->state == SLEEPING){
    80005932:	4c9c                	lw	a5,24(s1)
    80005934:	fd4793e3          	bne	a5,s4,800058fa <exec+0x94>
        t_temp->state = RUNNABLE;
    80005938:	0174ac23          	sw	s7,24(s1)
    8000593c:	bf7d                	j	800058fa <exec+0x94>
    }
  }
  release(&p->lock);
    8000593e:	854e                	mv	a0,s3
    80005940:	ffffb097          	auipc	ra,0xffffb
    80005944:	348080e7          	jalr	840(ra) # 80000c88 <release>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005948:	04000713          	li	a4,64
    8000594c:	4681                	li	a3,0
    8000594e:	e4840613          	addi	a2,s0,-440
    80005952:	4581                	li	a1,0
    80005954:	8556                	mv	a0,s5
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	cd0080e7          	jalr	-816(ra) # 80004626 <readi>
    8000595e:	04000793          	li	a5,64
    80005962:	00f51a63          	bne	a0,a5,80005976 <exec+0x110>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005966:	e4842703          	lw	a4,-440(s0)
    8000596a:	464c47b7          	lui	a5,0x464c4
    8000596e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005972:	04f70263          	beq	a4,a5,800059b6 <exec+0x150>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005976:	8556                	mv	a0,s5
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	c5c080e7          	jalr	-932(ra) # 800045d4 <iunlockput>
    end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	448080e7          	jalr	1096(ra) # 80004dc8 <end_op>
  }
  return -1;
    80005988:	557d                	li	a0,-1
}
    8000598a:	22813083          	ld	ra,552(sp)
    8000598e:	22013403          	ld	s0,544(sp)
    80005992:	21813483          	ld	s1,536(sp)
    80005996:	21013903          	ld	s2,528(sp)
    8000599a:	20813983          	ld	s3,520(sp)
    8000599e:	20013a03          	ld	s4,512(sp)
    800059a2:	7afe                	ld	s5,504(sp)
    800059a4:	7b5e                	ld	s6,496(sp)
    800059a6:	7bbe                	ld	s7,488(sp)
    800059a8:	7c1e                	ld	s8,480(sp)
    800059aa:	6cfe                	ld	s9,472(sp)
    800059ac:	6d5e                	ld	s10,464(sp)
    800059ae:	6dbe                	ld	s11,456(sp)
    800059b0:	23010113          	addi	sp,sp,560
    800059b4:	8082                	ret
  if((pagetable = proc_pagetable(p)) == 0)
    800059b6:	854e                	mv	a0,s3
    800059b8:	ffffc097          	auipc	ra,0xffffc
    800059bc:	25c080e7          	jalr	604(ra) # 80001c14 <proc_pagetable>
    800059c0:	8b2a                	mv	s6,a0
    800059c2:	d955                	beqz	a0,80005976 <exec+0x110>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059c4:	e6842783          	lw	a5,-408(s0)
    800059c8:	e8045703          	lhu	a4,-384(s0)
    800059cc:	c735                	beqz	a4,80005a38 <exec+0x1d2>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800059ce:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059d0:	e0043023          	sd	zero,-512(s0)
    if(ph.vaddr % PGSIZE != 0)
    800059d4:	6a05                	lui	s4,0x1
    800059d6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800059da:	dce43c23          	sd	a4,-552(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800059de:	6d85                	lui	s11,0x1
    800059e0:	7d7d                	lui	s10,0xfffff
    800059e2:	a485                	j	80005c42 <exec+0x3dc>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800059e4:	00003517          	auipc	a0,0x3
    800059e8:	d4450513          	addi	a0,a0,-700 # 80008728 <syscalls+0x2b8>
    800059ec:	ffffb097          	auipc	ra,0xffffb
    800059f0:	b3e080e7          	jalr	-1218(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800059f4:	874a                	mv	a4,s2
    800059f6:	009c86bb          	addw	a3,s9,s1
    800059fa:	4581                	li	a1,0
    800059fc:	8556                	mv	a0,s5
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	c28080e7          	jalr	-984(ra) # 80004626 <readi>
    80005a06:	2501                	sext.w	a0,a0
    80005a08:	1ca91d63          	bne	s2,a0,80005be2 <exec+0x37c>
  for(i = 0; i < sz; i += PGSIZE){
    80005a0c:	009d84bb          	addw	s1,s11,s1
    80005a10:	013d09bb          	addw	s3,s10,s3
    80005a14:	2174f763          	bgeu	s1,s7,80005c22 <exec+0x3bc>
    pa = walkaddr(pagetable, va + i);
    80005a18:	02049593          	slli	a1,s1,0x20
    80005a1c:	9181                	srli	a1,a1,0x20
    80005a1e:	95e2                	add	a1,a1,s8
    80005a20:	855a                	mv	a0,s6
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	64e080e7          	jalr	1614(ra) # 80001070 <walkaddr>
    80005a2a:	862a                	mv	a2,a0
    if(pa == 0)
    80005a2c:	dd45                	beqz	a0,800059e4 <exec+0x17e>
      n = PGSIZE;
    80005a2e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005a30:	fd49f2e3          	bgeu	s3,s4,800059f4 <exec+0x18e>
      n = sz - i;
    80005a34:	894e                	mv	s2,s3
    80005a36:	bf7d                	j	800059f4 <exec+0x18e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005a38:	4481                	li	s1,0
  iunlockput(ip);
    80005a3a:	8556                	mv	a0,s5
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	b98080e7          	jalr	-1128(ra) # 800045d4 <iunlockput>
  end_op();
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	384080e7          	jalr	900(ra) # 80004dc8 <end_op>
  p = myproc();
    80005a4c:	ffffc097          	auipc	ra,0xffffc
    80005a50:	faa080e7          	jalr	-86(ra) # 800019f6 <myproc>
    80005a54:	8a2a                	mv	s4,a0
  uint64 oldsz = p->sz;
    80005a56:	1d053d03          	ld	s10,464(a0)
  sz = PGROUNDUP(sz);
    80005a5a:	6785                	lui	a5,0x1
    80005a5c:	17fd                	addi	a5,a5,-1
    80005a5e:	94be                	add	s1,s1,a5
    80005a60:	77fd                	lui	a5,0xfffff
    80005a62:	8fe5                	and	a5,a5,s1
    80005a64:	def43823          	sd	a5,-528(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a68:	6609                	lui	a2,0x2
    80005a6a:	963e                	add	a2,a2,a5
    80005a6c:	85be                	mv	a1,a5
    80005a6e:	855a                	mv	a0,s6
    80005a70:	ffffc097          	auipc	ra,0xffffc
    80005a74:	9a2080e7          	jalr	-1630(ra) # 80001412 <uvmalloc>
    80005a78:	8caa                	mv	s9,a0
  ip = 0;
    80005a7a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a7c:	16050363          	beqz	a0,80005be2 <exec+0x37c>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005a80:	75f9                	lui	a1,0xffffe
    80005a82:	95aa                	add	a1,a1,a0
    80005a84:	855a                	mv	a0,s6
    80005a86:	ffffc097          	auipc	ra,0xffffc
    80005a8a:	baa080e7          	jalr	-1110(ra) # 80001630 <uvmclear>
  stackbase = sp - PGSIZE;
    80005a8e:	7bfd                	lui	s7,0xfffff
    80005a90:	9be6                	add	s7,s7,s9
  for(argc = 0; argv[argc]; argc++) {
    80005a92:	de843783          	ld	a5,-536(s0)
    80005a96:	6388                	ld	a0,0(a5)
    80005a98:	c925                	beqz	a0,80005b08 <exec+0x2a2>
    80005a9a:	e8840993          	addi	s3,s0,-376
    80005a9e:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005aa2:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005aa4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005aa6:	ffffb097          	auipc	ra,0xffffb
    80005aaa:	3c0080e7          	jalr	960(ra) # 80000e66 <strlen>
    80005aae:	0015079b          	addiw	a5,a0,1
    80005ab2:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005ab6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005aba:	15796863          	bltu	s2,s7,80005c0a <exec+0x3a4>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005abe:	de843d83          	ld	s11,-536(s0)
    80005ac2:	000dba83          	ld	s5,0(s11) # 1000 <_entry-0x7ffff000>
    80005ac6:	8556                	mv	a0,s5
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	39e080e7          	jalr	926(ra) # 80000e66 <strlen>
    80005ad0:	0015069b          	addiw	a3,a0,1
    80005ad4:	8656                	mv	a2,s5
    80005ad6:	85ca                	mv	a1,s2
    80005ad8:	855a                	mv	a0,s6
    80005ada:	ffffc097          	auipc	ra,0xffffc
    80005ade:	b88080e7          	jalr	-1144(ra) # 80001662 <copyout>
    80005ae2:	12054863          	bltz	a0,80005c12 <exec+0x3ac>
    ustack[argc] = sp;
    80005ae6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005aea:	0485                	addi	s1,s1,1
    80005aec:	008d8793          	addi	a5,s11,8
    80005af0:	def43423          	sd	a5,-536(s0)
    80005af4:	008db503          	ld	a0,8(s11)
    80005af8:	c911                	beqz	a0,80005b0c <exec+0x2a6>
    if(argc >= MAXARG)
    80005afa:	09a1                	addi	s3,s3,8
    80005afc:	fb3c15e3          	bne	s8,s3,80005aa6 <exec+0x240>
  sz = sz1;
    80005b00:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005b04:	4a81                	li	s5,0
    80005b06:	a8f1                	j	80005be2 <exec+0x37c>
  sp = sz;
    80005b08:	8966                	mv	s2,s9
  for(argc = 0; argv[argc]; argc++) {
    80005b0a:	4481                	li	s1,0
  ustack[argc] = 0;
    80005b0c:	00349793          	slli	a5,s1,0x3
    80005b10:	f9040713          	addi	a4,s0,-112
    80005b14:	97ba                	add	a5,a5,a4
    80005b16:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffbcef8>
  sp -= (argc+1) * sizeof(uint64);
    80005b1a:	00148693          	addi	a3,s1,1
    80005b1e:	068e                	slli	a3,a3,0x3
    80005b20:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005b24:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005b28:	01797663          	bgeu	s2,s7,80005b34 <exec+0x2ce>
  sz = sz1;
    80005b2c:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005b30:	4a81                	li	s5,0
    80005b32:	a845                	j	80005be2 <exec+0x37c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005b34:	e8840613          	addi	a2,s0,-376
    80005b38:	85ca                	mv	a1,s2
    80005b3a:	855a                	mv	a0,s6
    80005b3c:	ffffc097          	auipc	ra,0xffffc
    80005b40:	b26080e7          	jalr	-1242(ra) # 80001662 <copyout>
    80005b44:	0c054b63          	bltz	a0,80005c1a <exec+0x3b4>
  t->trapframe->a1 = sp;
    80005b48:	e0843783          	ld	a5,-504(s0)
    80005b4c:	67bc                	ld	a5,72(a5)
    80005b4e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005b52:	de043783          	ld	a5,-544(s0)
    80005b56:	0007c703          	lbu	a4,0(a5)
    80005b5a:	cf11                	beqz	a4,80005b76 <exec+0x310>
    80005b5c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005b5e:	02f00693          	li	a3,47
    80005b62:	a029                	j	80005b6c <exec+0x306>
  for(last=s=path; *s; s++)
    80005b64:	0785                	addi	a5,a5,1
    80005b66:	fff7c703          	lbu	a4,-1(a5)
    80005b6a:	c711                	beqz	a4,80005b76 <exec+0x310>
    if(*s == '/')
    80005b6c:	fed71ce3          	bne	a4,a3,80005b64 <exec+0x2fe>
      last = s+1;
    80005b70:	def43023          	sd	a5,-544(s0)
    80005b74:	bfc5                	j	80005b64 <exec+0x2fe>
  safestrcpy(p->name, last, sizeof(p->name));
    80005b76:	4641                	li	a2,16
    80005b78:	de043583          	ld	a1,-544(s0)
    80005b7c:	268a0513          	addi	a0,s4,616
    80005b80:	ffffb097          	auipc	ra,0xffffb
    80005b84:	2b4080e7          	jalr	692(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    80005b88:	1d8a3503          	ld	a0,472(s4)
  p->pagetable = pagetable;
    80005b8c:	1d6a3c23          	sd	s6,472(s4)
  p->sz = sz;
    80005b90:	1d9a3823          	sd	s9,464(s4)
  t->trapframe->epc = elf.entry;  // initial program counter = main
    80005b94:	e0843683          	ld	a3,-504(s0)
    80005b98:	66bc                	ld	a5,72(a3)
    80005b9a:	e6043703          	ld	a4,-416(s0)
    80005b9e:	ef98                	sd	a4,24(a5)
  t->trapframe->sp = sp; // initial stack pointer
    80005ba0:	66bc                	ld	a5,72(a3)
    80005ba2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005ba6:	85ea                	mv	a1,s10
    80005ba8:	ffffc097          	auipc	ra,0xffffc
    80005bac:	10c080e7          	jalr	268(ra) # 80001cb4 <proc_freepagetable>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005bb0:	138a0793          	addi	a5,s4,312
    80005bb4:	038a0a13          	addi	s4,s4,56
    80005bb8:	863e                	mv	a2,a5
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005bba:	4685                	li	a3,1
    80005bbc:	a029                	j	80005bc6 <exec+0x360>
  for(int signum = 0; signum < SIG_NUM; signum++){
    80005bbe:	0791                	addi	a5,a5,4
    80005bc0:	0a21                	addi	s4,s4,8
    80005bc2:	00ca0b63          	beq	s4,a2,80005bd8 <exec+0x372>
    p->signal_handlers_masks[signum] = 0;
    80005bc6:	0007a023          	sw	zero,0(a5)
    if(p->signal_handlers[signum] != (void *)SIG_IGN) {
    80005bca:	000a3703          	ld	a4,0(s4)
    80005bce:	fed708e3          	beq	a4,a3,80005bbe <exec+0x358>
      p->signal_handlers[signum] = SIG_DFL;
    80005bd2:	000a3023          	sd	zero,0(s4)
    80005bd6:	b7e5                	j	80005bbe <exec+0x358>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005bd8:	0004851b          	sext.w	a0,s1
    80005bdc:	b37d                	j	8000598a <exec+0x124>
    80005bde:	de943823          	sd	s1,-528(s0)
    proc_freepagetable(pagetable, sz);
    80005be2:	df043583          	ld	a1,-528(s0)
    80005be6:	855a                	mv	a0,s6
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	0cc080e7          	jalr	204(ra) # 80001cb4 <proc_freepagetable>
  if(ip){
    80005bf0:	d80a93e3          	bnez	s5,80005976 <exec+0x110>
  return -1;
    80005bf4:	557d                	li	a0,-1
    80005bf6:	bb51                	j	8000598a <exec+0x124>
    80005bf8:	de943823          	sd	s1,-528(s0)
    80005bfc:	b7dd                	j	80005be2 <exec+0x37c>
    80005bfe:	de943823          	sd	s1,-528(s0)
    80005c02:	b7c5                	j	80005be2 <exec+0x37c>
    80005c04:	de943823          	sd	s1,-528(s0)
    80005c08:	bfe9                	j	80005be2 <exec+0x37c>
  sz = sz1;
    80005c0a:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005c0e:	4a81                	li	s5,0
    80005c10:	bfc9                	j	80005be2 <exec+0x37c>
  sz = sz1;
    80005c12:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005c16:	4a81                	li	s5,0
    80005c18:	b7e9                	j	80005be2 <exec+0x37c>
  sz = sz1;
    80005c1a:	df943823          	sd	s9,-528(s0)
  ip = 0;
    80005c1e:	4a81                	li	s5,0
    80005c20:	b7c9                	j	80005be2 <exec+0x37c>
    sz = sz1;
    80005c22:	df043483          	ld	s1,-528(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005c26:	e0043783          	ld	a5,-512(s0)
    80005c2a:	0017869b          	addiw	a3,a5,1
    80005c2e:	e0d43023          	sd	a3,-512(s0)
    80005c32:	df843783          	ld	a5,-520(s0)
    80005c36:	0387879b          	addiw	a5,a5,56
    80005c3a:	e8045703          	lhu	a4,-384(s0)
    80005c3e:	dee6dee3          	bge	a3,a4,80005a3a <exec+0x1d4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005c42:	2781                	sext.w	a5,a5
    80005c44:	def43c23          	sd	a5,-520(s0)
    80005c48:	03800713          	li	a4,56
    80005c4c:	86be                	mv	a3,a5
    80005c4e:	e1040613          	addi	a2,s0,-496
    80005c52:	4581                	li	a1,0
    80005c54:	8556                	mv	a0,s5
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	9d0080e7          	jalr	-1584(ra) # 80004626 <readi>
    80005c5e:	03800793          	li	a5,56
    80005c62:	f6f51ee3          	bne	a0,a5,80005bde <exec+0x378>
    if(ph.type != ELF_PROG_LOAD)
    80005c66:	e1042783          	lw	a5,-496(s0)
    80005c6a:	4705                	li	a4,1
    80005c6c:	fae79de3          	bne	a5,a4,80005c26 <exec+0x3c0>
    if(ph.memsz < ph.filesz)
    80005c70:	e3843603          	ld	a2,-456(s0)
    80005c74:	e3043783          	ld	a5,-464(s0)
    80005c78:	f8f660e3          	bltu	a2,a5,80005bf8 <exec+0x392>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005c7c:	e2043783          	ld	a5,-480(s0)
    80005c80:	963e                	add	a2,a2,a5
    80005c82:	f6f66ee3          	bltu	a2,a5,80005bfe <exec+0x398>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005c86:	85a6                	mv	a1,s1
    80005c88:	855a                	mv	a0,s6
    80005c8a:	ffffb097          	auipc	ra,0xffffb
    80005c8e:	788080e7          	jalr	1928(ra) # 80001412 <uvmalloc>
    80005c92:	dea43823          	sd	a0,-528(s0)
    80005c96:	d53d                	beqz	a0,80005c04 <exec+0x39e>
    if(ph.vaddr % PGSIZE != 0)
    80005c98:	e2043c03          	ld	s8,-480(s0)
    80005c9c:	dd843783          	ld	a5,-552(s0)
    80005ca0:	00fc77b3          	and	a5,s8,a5
    80005ca4:	ff9d                	bnez	a5,80005be2 <exec+0x37c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005ca6:	e1842c83          	lw	s9,-488(s0)
    80005caa:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005cae:	f60b8ae3          	beqz	s7,80005c22 <exec+0x3bc>
    80005cb2:	89de                	mv	s3,s7
    80005cb4:	4481                	li	s1,0
    80005cb6:	b38d                	j	80005a18 <exec+0x1b2>

0000000080005cb8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005cb8:	7179                	addi	sp,sp,-48
    80005cba:	f406                	sd	ra,40(sp)
    80005cbc:	f022                	sd	s0,32(sp)
    80005cbe:	ec26                	sd	s1,24(sp)
    80005cc0:	e84a                	sd	s2,16(sp)
    80005cc2:	1800                	addi	s0,sp,48
    80005cc4:	892e                	mv	s2,a1
    80005cc6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005cc8:	fdc40593          	addi	a1,s0,-36
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	982080e7          	jalr	-1662(ra) # 8000364e <argint>
    80005cd4:	04054063          	bltz	a0,80005d14 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005cd8:	fdc42703          	lw	a4,-36(s0)
    80005cdc:	47bd                	li	a5,15
    80005cde:	02e7ed63          	bltu	a5,a4,80005d18 <argfd+0x60>
    80005ce2:	ffffc097          	auipc	ra,0xffffc
    80005ce6:	d14080e7          	jalr	-748(ra) # 800019f6 <myproc>
    80005cea:	fdc42703          	lw	a4,-36(s0)
    80005cee:	03c70793          	addi	a5,a4,60
    80005cf2:	078e                	slli	a5,a5,0x3
    80005cf4:	953e                	add	a0,a0,a5
    80005cf6:	611c                	ld	a5,0(a0)
    80005cf8:	c395                	beqz	a5,80005d1c <argfd+0x64>
    return -1;
  if(pfd)
    80005cfa:	00090463          	beqz	s2,80005d02 <argfd+0x4a>
    *pfd = fd;
    80005cfe:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005d02:	4501                	li	a0,0
  if(pf)
    80005d04:	c091                	beqz	s1,80005d08 <argfd+0x50>
    *pf = f;
    80005d06:	e09c                	sd	a5,0(s1)
}
    80005d08:	70a2                	ld	ra,40(sp)
    80005d0a:	7402                	ld	s0,32(sp)
    80005d0c:	64e2                	ld	s1,24(sp)
    80005d0e:	6942                	ld	s2,16(sp)
    80005d10:	6145                	addi	sp,sp,48
    80005d12:	8082                	ret
    return -1;
    80005d14:	557d                	li	a0,-1
    80005d16:	bfcd                	j	80005d08 <argfd+0x50>
    return -1;
    80005d18:	557d                	li	a0,-1
    80005d1a:	b7fd                	j	80005d08 <argfd+0x50>
    80005d1c:	557d                	li	a0,-1
    80005d1e:	b7ed                	j	80005d08 <argfd+0x50>

0000000080005d20 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005d20:	1101                	addi	sp,sp,-32
    80005d22:	ec06                	sd	ra,24(sp)
    80005d24:	e822                	sd	s0,16(sp)
    80005d26:	e426                	sd	s1,8(sp)
    80005d28:	1000                	addi	s0,sp,32
    80005d2a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005d2c:	ffffc097          	auipc	ra,0xffffc
    80005d30:	cca080e7          	jalr	-822(ra) # 800019f6 <myproc>
    80005d34:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005d36:	1e050793          	addi	a5,a0,480
    80005d3a:	4501                	li	a0,0
    80005d3c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005d3e:	6398                	ld	a4,0(a5)
    80005d40:	cb19                	beqz	a4,80005d56 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005d42:	2505                	addiw	a0,a0,1
    80005d44:	07a1                	addi	a5,a5,8
    80005d46:	fed51ce3          	bne	a0,a3,80005d3e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005d4a:	557d                	li	a0,-1
}
    80005d4c:	60e2                	ld	ra,24(sp)
    80005d4e:	6442                	ld	s0,16(sp)
    80005d50:	64a2                	ld	s1,8(sp)
    80005d52:	6105                	addi	sp,sp,32
    80005d54:	8082                	ret
      p->ofile[fd] = f;
    80005d56:	03c50793          	addi	a5,a0,60
    80005d5a:	078e                	slli	a5,a5,0x3
    80005d5c:	963e                	add	a2,a2,a5
    80005d5e:	e204                	sd	s1,0(a2)
      return fd;
    80005d60:	b7f5                	j	80005d4c <fdalloc+0x2c>

0000000080005d62 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005d62:	715d                	addi	sp,sp,-80
    80005d64:	e486                	sd	ra,72(sp)
    80005d66:	e0a2                	sd	s0,64(sp)
    80005d68:	fc26                	sd	s1,56(sp)
    80005d6a:	f84a                	sd	s2,48(sp)
    80005d6c:	f44e                	sd	s3,40(sp)
    80005d6e:	f052                	sd	s4,32(sp)
    80005d70:	ec56                	sd	s5,24(sp)
    80005d72:	0880                	addi	s0,sp,80
    80005d74:	89ae                	mv	s3,a1
    80005d76:	8ab2                	mv	s5,a2
    80005d78:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005d7a:	fb040593          	addi	a1,s0,-80
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	dc8080e7          	jalr	-568(ra) # 80004b46 <nameiparent>
    80005d86:	892a                	mv	s2,a0
    80005d88:	12050e63          	beqz	a0,80005ec4 <create+0x162>
    return 0;

  ilock(dp);
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	5e6080e7          	jalr	1510(ra) # 80004372 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005d94:	4601                	li	a2,0
    80005d96:	fb040593          	addi	a1,s0,-80
    80005d9a:	854a                	mv	a0,s2
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	aba080e7          	jalr	-1350(ra) # 80004856 <dirlookup>
    80005da4:	84aa                	mv	s1,a0
    80005da6:	c921                	beqz	a0,80005df6 <create+0x94>
    iunlockput(dp);
    80005da8:	854a                	mv	a0,s2
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	82a080e7          	jalr	-2006(ra) # 800045d4 <iunlockput>
    ilock(ip);
    80005db2:	8526                	mv	a0,s1
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	5be080e7          	jalr	1470(ra) # 80004372 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005dbc:	2981                	sext.w	s3,s3
    80005dbe:	4789                	li	a5,2
    80005dc0:	02f99463          	bne	s3,a5,80005de8 <create+0x86>
    80005dc4:	0444d783          	lhu	a5,68(s1)
    80005dc8:	37f9                	addiw	a5,a5,-2
    80005dca:	17c2                	slli	a5,a5,0x30
    80005dcc:	93c1                	srli	a5,a5,0x30
    80005dce:	4705                	li	a4,1
    80005dd0:	00f76c63          	bltu	a4,a5,80005de8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005dd4:	8526                	mv	a0,s1
    80005dd6:	60a6                	ld	ra,72(sp)
    80005dd8:	6406                	ld	s0,64(sp)
    80005dda:	74e2                	ld	s1,56(sp)
    80005ddc:	7942                	ld	s2,48(sp)
    80005dde:	79a2                	ld	s3,40(sp)
    80005de0:	7a02                	ld	s4,32(sp)
    80005de2:	6ae2                	ld	s5,24(sp)
    80005de4:	6161                	addi	sp,sp,80
    80005de6:	8082                	ret
    iunlockput(ip);
    80005de8:	8526                	mv	a0,s1
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	7ea080e7          	jalr	2026(ra) # 800045d4 <iunlockput>
    return 0;
    80005df2:	4481                	li	s1,0
    80005df4:	b7c5                	j	80005dd4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005df6:	85ce                	mv	a1,s3
    80005df8:	00092503          	lw	a0,0(s2)
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	3de080e7          	jalr	990(ra) # 800041da <ialloc>
    80005e04:	84aa                	mv	s1,a0
    80005e06:	c521                	beqz	a0,80005e4e <create+0xec>
  ilock(ip);
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	56a080e7          	jalr	1386(ra) # 80004372 <ilock>
  ip->major = major;
    80005e10:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005e14:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005e18:	4a05                	li	s4,1
    80005e1a:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005e1e:	8526                	mv	a0,s1
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	488080e7          	jalr	1160(ra) # 800042a8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005e28:	2981                	sext.w	s3,s3
    80005e2a:	03498a63          	beq	s3,s4,80005e5e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005e2e:	40d0                	lw	a2,4(s1)
    80005e30:	fb040593          	addi	a1,s0,-80
    80005e34:	854a                	mv	a0,s2
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	c30080e7          	jalr	-976(ra) # 80004a66 <dirlink>
    80005e3e:	06054b63          	bltz	a0,80005eb4 <create+0x152>
  iunlockput(dp);
    80005e42:	854a                	mv	a0,s2
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	790080e7          	jalr	1936(ra) # 800045d4 <iunlockput>
  return ip;
    80005e4c:	b761                	j	80005dd4 <create+0x72>
    panic("create: ialloc");
    80005e4e:	00003517          	auipc	a0,0x3
    80005e52:	8fa50513          	addi	a0,a0,-1798 # 80008748 <syscalls+0x2d8>
    80005e56:	ffffa097          	auipc	ra,0xffffa
    80005e5a:	6d4080e7          	jalr	1748(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005e5e:	04a95783          	lhu	a5,74(s2)
    80005e62:	2785                	addiw	a5,a5,1
    80005e64:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005e68:	854a                	mv	a0,s2
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	43e080e7          	jalr	1086(ra) # 800042a8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005e72:	40d0                	lw	a2,4(s1)
    80005e74:	00003597          	auipc	a1,0x3
    80005e78:	8e458593          	addi	a1,a1,-1820 # 80008758 <syscalls+0x2e8>
    80005e7c:	8526                	mv	a0,s1
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	be8080e7          	jalr	-1048(ra) # 80004a66 <dirlink>
    80005e86:	00054f63          	bltz	a0,80005ea4 <create+0x142>
    80005e8a:	00492603          	lw	a2,4(s2)
    80005e8e:	00003597          	auipc	a1,0x3
    80005e92:	8d258593          	addi	a1,a1,-1838 # 80008760 <syscalls+0x2f0>
    80005e96:	8526                	mv	a0,s1
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	bce080e7          	jalr	-1074(ra) # 80004a66 <dirlink>
    80005ea0:	f80557e3          	bgez	a0,80005e2e <create+0xcc>
      panic("create dots");
    80005ea4:	00003517          	auipc	a0,0x3
    80005ea8:	8c450513          	addi	a0,a0,-1852 # 80008768 <syscalls+0x2f8>
    80005eac:	ffffa097          	auipc	ra,0xffffa
    80005eb0:	67e080e7          	jalr	1662(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005eb4:	00003517          	auipc	a0,0x3
    80005eb8:	8c450513          	addi	a0,a0,-1852 # 80008778 <syscalls+0x308>
    80005ebc:	ffffa097          	auipc	ra,0xffffa
    80005ec0:	66e080e7          	jalr	1646(ra) # 8000052a <panic>
    return 0;
    80005ec4:	84aa                	mv	s1,a0
    80005ec6:	b739                	j	80005dd4 <create+0x72>

0000000080005ec8 <sys_dup>:
{
    80005ec8:	7179                	addi	sp,sp,-48
    80005eca:	f406                	sd	ra,40(sp)
    80005ecc:	f022                	sd	s0,32(sp)
    80005ece:	ec26                	sd	s1,24(sp)
    80005ed0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005ed2:	fd840613          	addi	a2,s0,-40
    80005ed6:	4581                	li	a1,0
    80005ed8:	4501                	li	a0,0
    80005eda:	00000097          	auipc	ra,0x0
    80005ede:	dde080e7          	jalr	-546(ra) # 80005cb8 <argfd>
    return -1;
    80005ee2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005ee4:	02054363          	bltz	a0,80005f0a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005ee8:	fd843503          	ld	a0,-40(s0)
    80005eec:	00000097          	auipc	ra,0x0
    80005ef0:	e34080e7          	jalr	-460(ra) # 80005d20 <fdalloc>
    80005ef4:	84aa                	mv	s1,a0
    return -1;
    80005ef6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005ef8:	00054963          	bltz	a0,80005f0a <sys_dup+0x42>
  filedup(f);
    80005efc:	fd843503          	ld	a0,-40(s0)
    80005f00:	fffff097          	auipc	ra,0xfffff
    80005f04:	2c2080e7          	jalr	706(ra) # 800051c2 <filedup>
  return fd;
    80005f08:	87a6                	mv	a5,s1
}
    80005f0a:	853e                	mv	a0,a5
    80005f0c:	70a2                	ld	ra,40(sp)
    80005f0e:	7402                	ld	s0,32(sp)
    80005f10:	64e2                	ld	s1,24(sp)
    80005f12:	6145                	addi	sp,sp,48
    80005f14:	8082                	ret

0000000080005f16 <sys_read>:
{
    80005f16:	7179                	addi	sp,sp,-48
    80005f18:	f406                	sd	ra,40(sp)
    80005f1a:	f022                	sd	s0,32(sp)
    80005f1c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f1e:	fe840613          	addi	a2,s0,-24
    80005f22:	4581                	li	a1,0
    80005f24:	4501                	li	a0,0
    80005f26:	00000097          	auipc	ra,0x0
    80005f2a:	d92080e7          	jalr	-622(ra) # 80005cb8 <argfd>
    return -1;
    80005f2e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f30:	04054163          	bltz	a0,80005f72 <sys_read+0x5c>
    80005f34:	fe440593          	addi	a1,s0,-28
    80005f38:	4509                	li	a0,2
    80005f3a:	ffffd097          	auipc	ra,0xffffd
    80005f3e:	714080e7          	jalr	1812(ra) # 8000364e <argint>
    return -1;
    80005f42:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f44:	02054763          	bltz	a0,80005f72 <sys_read+0x5c>
    80005f48:	fd840593          	addi	a1,s0,-40
    80005f4c:	4505                	li	a0,1
    80005f4e:	ffffd097          	auipc	ra,0xffffd
    80005f52:	722080e7          	jalr	1826(ra) # 80003670 <argaddr>
    return -1;
    80005f56:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f58:	00054d63          	bltz	a0,80005f72 <sys_read+0x5c>
  return fileread(f, p, n);
    80005f5c:	fe442603          	lw	a2,-28(s0)
    80005f60:	fd843583          	ld	a1,-40(s0)
    80005f64:	fe843503          	ld	a0,-24(s0)
    80005f68:	fffff097          	auipc	ra,0xfffff
    80005f6c:	3e6080e7          	jalr	998(ra) # 8000534e <fileread>
    80005f70:	87aa                	mv	a5,a0
}
    80005f72:	853e                	mv	a0,a5
    80005f74:	70a2                	ld	ra,40(sp)
    80005f76:	7402                	ld	s0,32(sp)
    80005f78:	6145                	addi	sp,sp,48
    80005f7a:	8082                	ret

0000000080005f7c <sys_write>:
{
    80005f7c:	7179                	addi	sp,sp,-48
    80005f7e:	f406                	sd	ra,40(sp)
    80005f80:	f022                	sd	s0,32(sp)
    80005f82:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f84:	fe840613          	addi	a2,s0,-24
    80005f88:	4581                	li	a1,0
    80005f8a:	4501                	li	a0,0
    80005f8c:	00000097          	auipc	ra,0x0
    80005f90:	d2c080e7          	jalr	-724(ra) # 80005cb8 <argfd>
    return -1;
    80005f94:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f96:	04054163          	bltz	a0,80005fd8 <sys_write+0x5c>
    80005f9a:	fe440593          	addi	a1,s0,-28
    80005f9e:	4509                	li	a0,2
    80005fa0:	ffffd097          	auipc	ra,0xffffd
    80005fa4:	6ae080e7          	jalr	1710(ra) # 8000364e <argint>
    return -1;
    80005fa8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005faa:	02054763          	bltz	a0,80005fd8 <sys_write+0x5c>
    80005fae:	fd840593          	addi	a1,s0,-40
    80005fb2:	4505                	li	a0,1
    80005fb4:	ffffd097          	auipc	ra,0xffffd
    80005fb8:	6bc080e7          	jalr	1724(ra) # 80003670 <argaddr>
    return -1;
    80005fbc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fbe:	00054d63          	bltz	a0,80005fd8 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005fc2:	fe442603          	lw	a2,-28(s0)
    80005fc6:	fd843583          	ld	a1,-40(s0)
    80005fca:	fe843503          	ld	a0,-24(s0)
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	442080e7          	jalr	1090(ra) # 80005410 <filewrite>
    80005fd6:	87aa                	mv	a5,a0
}
    80005fd8:	853e                	mv	a0,a5
    80005fda:	70a2                	ld	ra,40(sp)
    80005fdc:	7402                	ld	s0,32(sp)
    80005fde:	6145                	addi	sp,sp,48
    80005fe0:	8082                	ret

0000000080005fe2 <sys_close>:
{
    80005fe2:	1101                	addi	sp,sp,-32
    80005fe4:	ec06                	sd	ra,24(sp)
    80005fe6:	e822                	sd	s0,16(sp)
    80005fe8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005fea:	fe040613          	addi	a2,s0,-32
    80005fee:	fec40593          	addi	a1,s0,-20
    80005ff2:	4501                	li	a0,0
    80005ff4:	00000097          	auipc	ra,0x0
    80005ff8:	cc4080e7          	jalr	-828(ra) # 80005cb8 <argfd>
    return -1;
    80005ffc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ffe:	02054563          	bltz	a0,80006028 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80006002:	ffffc097          	auipc	ra,0xffffc
    80006006:	9f4080e7          	jalr	-1548(ra) # 800019f6 <myproc>
    8000600a:	fec42783          	lw	a5,-20(s0)
    8000600e:	03c78793          	addi	a5,a5,60
    80006012:	078e                	slli	a5,a5,0x3
    80006014:	97aa                	add	a5,a5,a0
    80006016:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000601a:	fe043503          	ld	a0,-32(s0)
    8000601e:	fffff097          	auipc	ra,0xfffff
    80006022:	1f6080e7          	jalr	502(ra) # 80005214 <fileclose>
  return 0;
    80006026:	4781                	li	a5,0
}
    80006028:	853e                	mv	a0,a5
    8000602a:	60e2                	ld	ra,24(sp)
    8000602c:	6442                	ld	s0,16(sp)
    8000602e:	6105                	addi	sp,sp,32
    80006030:	8082                	ret

0000000080006032 <sys_fstat>:
{
    80006032:	1101                	addi	sp,sp,-32
    80006034:	ec06                	sd	ra,24(sp)
    80006036:	e822                	sd	s0,16(sp)
    80006038:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000603a:	fe840613          	addi	a2,s0,-24
    8000603e:	4581                	li	a1,0
    80006040:	4501                	li	a0,0
    80006042:	00000097          	auipc	ra,0x0
    80006046:	c76080e7          	jalr	-906(ra) # 80005cb8 <argfd>
    return -1;
    8000604a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000604c:	02054563          	bltz	a0,80006076 <sys_fstat+0x44>
    80006050:	fe040593          	addi	a1,s0,-32
    80006054:	4505                	li	a0,1
    80006056:	ffffd097          	auipc	ra,0xffffd
    8000605a:	61a080e7          	jalr	1562(ra) # 80003670 <argaddr>
    return -1;
    8000605e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006060:	00054b63          	bltz	a0,80006076 <sys_fstat+0x44>
  return filestat(f, st);
    80006064:	fe043583          	ld	a1,-32(s0)
    80006068:	fe843503          	ld	a0,-24(s0)
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	270080e7          	jalr	624(ra) # 800052dc <filestat>
    80006074:	87aa                	mv	a5,a0
}
    80006076:	853e                	mv	a0,a5
    80006078:	60e2                	ld	ra,24(sp)
    8000607a:	6442                	ld	s0,16(sp)
    8000607c:	6105                	addi	sp,sp,32
    8000607e:	8082                	ret

0000000080006080 <sys_link>:
{
    80006080:	7169                	addi	sp,sp,-304
    80006082:	f606                	sd	ra,296(sp)
    80006084:	f222                	sd	s0,288(sp)
    80006086:	ee26                	sd	s1,280(sp)
    80006088:	ea4a                	sd	s2,272(sp)
    8000608a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000608c:	08000613          	li	a2,128
    80006090:	ed040593          	addi	a1,s0,-304
    80006094:	4501                	li	a0,0
    80006096:	ffffd097          	auipc	ra,0xffffd
    8000609a:	5fc080e7          	jalr	1532(ra) # 80003692 <argstr>
    return -1;
    8000609e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060a0:	10054e63          	bltz	a0,800061bc <sys_link+0x13c>
    800060a4:	08000613          	li	a2,128
    800060a8:	f5040593          	addi	a1,s0,-176
    800060ac:	4505                	li	a0,1
    800060ae:	ffffd097          	auipc	ra,0xffffd
    800060b2:	5e4080e7          	jalr	1508(ra) # 80003692 <argstr>
    return -1;
    800060b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800060b8:	10054263          	bltz	a0,800061bc <sys_link+0x13c>
  begin_op();
    800060bc:	fffff097          	auipc	ra,0xfffff
    800060c0:	c8c080e7          	jalr	-884(ra) # 80004d48 <begin_op>
  if((ip = namei(old)) == 0){
    800060c4:	ed040513          	addi	a0,s0,-304
    800060c8:	fffff097          	auipc	ra,0xfffff
    800060cc:	a60080e7          	jalr	-1440(ra) # 80004b28 <namei>
    800060d0:	84aa                	mv	s1,a0
    800060d2:	c551                	beqz	a0,8000615e <sys_link+0xde>
  ilock(ip);
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	29e080e7          	jalr	670(ra) # 80004372 <ilock>
  if(ip->type == T_DIR){
    800060dc:	04449703          	lh	a4,68(s1)
    800060e0:	4785                	li	a5,1
    800060e2:	08f70463          	beq	a4,a5,8000616a <sys_link+0xea>
  ip->nlink++;
    800060e6:	04a4d783          	lhu	a5,74(s1)
    800060ea:	2785                	addiw	a5,a5,1
    800060ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060f0:	8526                	mv	a0,s1
    800060f2:	ffffe097          	auipc	ra,0xffffe
    800060f6:	1b6080e7          	jalr	438(ra) # 800042a8 <iupdate>
  iunlock(ip);
    800060fa:	8526                	mv	a0,s1
    800060fc:	ffffe097          	auipc	ra,0xffffe
    80006100:	338080e7          	jalr	824(ra) # 80004434 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006104:	fd040593          	addi	a1,s0,-48
    80006108:	f5040513          	addi	a0,s0,-176
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	a3a080e7          	jalr	-1478(ra) # 80004b46 <nameiparent>
    80006114:	892a                	mv	s2,a0
    80006116:	c935                	beqz	a0,8000618a <sys_link+0x10a>
  ilock(dp);
    80006118:	ffffe097          	auipc	ra,0xffffe
    8000611c:	25a080e7          	jalr	602(ra) # 80004372 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006120:	00092703          	lw	a4,0(s2)
    80006124:	409c                	lw	a5,0(s1)
    80006126:	04f71d63          	bne	a4,a5,80006180 <sys_link+0x100>
    8000612a:	40d0                	lw	a2,4(s1)
    8000612c:	fd040593          	addi	a1,s0,-48
    80006130:	854a                	mv	a0,s2
    80006132:	fffff097          	auipc	ra,0xfffff
    80006136:	934080e7          	jalr	-1740(ra) # 80004a66 <dirlink>
    8000613a:	04054363          	bltz	a0,80006180 <sys_link+0x100>
  iunlockput(dp);
    8000613e:	854a                	mv	a0,s2
    80006140:	ffffe097          	auipc	ra,0xffffe
    80006144:	494080e7          	jalr	1172(ra) # 800045d4 <iunlockput>
  iput(ip);
    80006148:	8526                	mv	a0,s1
    8000614a:	ffffe097          	auipc	ra,0xffffe
    8000614e:	3e2080e7          	jalr	994(ra) # 8000452c <iput>
  end_op();
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	c76080e7          	jalr	-906(ra) # 80004dc8 <end_op>
  return 0;
    8000615a:	4781                	li	a5,0
    8000615c:	a085                	j	800061bc <sys_link+0x13c>
    end_op();
    8000615e:	fffff097          	auipc	ra,0xfffff
    80006162:	c6a080e7          	jalr	-918(ra) # 80004dc8 <end_op>
    return -1;
    80006166:	57fd                	li	a5,-1
    80006168:	a891                	j	800061bc <sys_link+0x13c>
    iunlockput(ip);
    8000616a:	8526                	mv	a0,s1
    8000616c:	ffffe097          	auipc	ra,0xffffe
    80006170:	468080e7          	jalr	1128(ra) # 800045d4 <iunlockput>
    end_op();
    80006174:	fffff097          	auipc	ra,0xfffff
    80006178:	c54080e7          	jalr	-940(ra) # 80004dc8 <end_op>
    return -1;
    8000617c:	57fd                	li	a5,-1
    8000617e:	a83d                	j	800061bc <sys_link+0x13c>
    iunlockput(dp);
    80006180:	854a                	mv	a0,s2
    80006182:	ffffe097          	auipc	ra,0xffffe
    80006186:	452080e7          	jalr	1106(ra) # 800045d4 <iunlockput>
  ilock(ip);
    8000618a:	8526                	mv	a0,s1
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	1e6080e7          	jalr	486(ra) # 80004372 <ilock>
  ip->nlink--;
    80006194:	04a4d783          	lhu	a5,74(s1)
    80006198:	37fd                	addiw	a5,a5,-1
    8000619a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000619e:	8526                	mv	a0,s1
    800061a0:	ffffe097          	auipc	ra,0xffffe
    800061a4:	108080e7          	jalr	264(ra) # 800042a8 <iupdate>
  iunlockput(ip);
    800061a8:	8526                	mv	a0,s1
    800061aa:	ffffe097          	auipc	ra,0xffffe
    800061ae:	42a080e7          	jalr	1066(ra) # 800045d4 <iunlockput>
  end_op();
    800061b2:	fffff097          	auipc	ra,0xfffff
    800061b6:	c16080e7          	jalr	-1002(ra) # 80004dc8 <end_op>
  return -1;
    800061ba:	57fd                	li	a5,-1
}
    800061bc:	853e                	mv	a0,a5
    800061be:	70b2                	ld	ra,296(sp)
    800061c0:	7412                	ld	s0,288(sp)
    800061c2:	64f2                	ld	s1,280(sp)
    800061c4:	6952                	ld	s2,272(sp)
    800061c6:	6155                	addi	sp,sp,304
    800061c8:	8082                	ret

00000000800061ca <sys_unlink>:
{
    800061ca:	7151                	addi	sp,sp,-240
    800061cc:	f586                	sd	ra,232(sp)
    800061ce:	f1a2                	sd	s0,224(sp)
    800061d0:	eda6                	sd	s1,216(sp)
    800061d2:	e9ca                	sd	s2,208(sp)
    800061d4:	e5ce                	sd	s3,200(sp)
    800061d6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800061d8:	08000613          	li	a2,128
    800061dc:	f3040593          	addi	a1,s0,-208
    800061e0:	4501                	li	a0,0
    800061e2:	ffffd097          	auipc	ra,0xffffd
    800061e6:	4b0080e7          	jalr	1200(ra) # 80003692 <argstr>
    800061ea:	18054163          	bltz	a0,8000636c <sys_unlink+0x1a2>
  begin_op();
    800061ee:	fffff097          	auipc	ra,0xfffff
    800061f2:	b5a080e7          	jalr	-1190(ra) # 80004d48 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800061f6:	fb040593          	addi	a1,s0,-80
    800061fa:	f3040513          	addi	a0,s0,-208
    800061fe:	fffff097          	auipc	ra,0xfffff
    80006202:	948080e7          	jalr	-1720(ra) # 80004b46 <nameiparent>
    80006206:	84aa                	mv	s1,a0
    80006208:	c979                	beqz	a0,800062de <sys_unlink+0x114>
  ilock(dp);
    8000620a:	ffffe097          	auipc	ra,0xffffe
    8000620e:	168080e7          	jalr	360(ra) # 80004372 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006212:	00002597          	auipc	a1,0x2
    80006216:	54658593          	addi	a1,a1,1350 # 80008758 <syscalls+0x2e8>
    8000621a:	fb040513          	addi	a0,s0,-80
    8000621e:	ffffe097          	auipc	ra,0xffffe
    80006222:	61e080e7          	jalr	1566(ra) # 8000483c <namecmp>
    80006226:	14050a63          	beqz	a0,8000637a <sys_unlink+0x1b0>
    8000622a:	00002597          	auipc	a1,0x2
    8000622e:	53658593          	addi	a1,a1,1334 # 80008760 <syscalls+0x2f0>
    80006232:	fb040513          	addi	a0,s0,-80
    80006236:	ffffe097          	auipc	ra,0xffffe
    8000623a:	606080e7          	jalr	1542(ra) # 8000483c <namecmp>
    8000623e:	12050e63          	beqz	a0,8000637a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006242:	f2c40613          	addi	a2,s0,-212
    80006246:	fb040593          	addi	a1,s0,-80
    8000624a:	8526                	mv	a0,s1
    8000624c:	ffffe097          	auipc	ra,0xffffe
    80006250:	60a080e7          	jalr	1546(ra) # 80004856 <dirlookup>
    80006254:	892a                	mv	s2,a0
    80006256:	12050263          	beqz	a0,8000637a <sys_unlink+0x1b0>
  ilock(ip);
    8000625a:	ffffe097          	auipc	ra,0xffffe
    8000625e:	118080e7          	jalr	280(ra) # 80004372 <ilock>
  if(ip->nlink < 1)
    80006262:	04a91783          	lh	a5,74(s2)
    80006266:	08f05263          	blez	a5,800062ea <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000626a:	04491703          	lh	a4,68(s2)
    8000626e:	4785                	li	a5,1
    80006270:	08f70563          	beq	a4,a5,800062fa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006274:	4641                	li	a2,16
    80006276:	4581                	li	a1,0
    80006278:	fc040513          	addi	a0,s0,-64
    8000627c:	ffffb097          	auipc	ra,0xffffb
    80006280:	a66080e7          	jalr	-1434(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006284:	4741                	li	a4,16
    80006286:	f2c42683          	lw	a3,-212(s0)
    8000628a:	fc040613          	addi	a2,s0,-64
    8000628e:	4581                	li	a1,0
    80006290:	8526                	mv	a0,s1
    80006292:	ffffe097          	auipc	ra,0xffffe
    80006296:	48c080e7          	jalr	1164(ra) # 8000471e <writei>
    8000629a:	47c1                	li	a5,16
    8000629c:	0af51563          	bne	a0,a5,80006346 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800062a0:	04491703          	lh	a4,68(s2)
    800062a4:	4785                	li	a5,1
    800062a6:	0af70863          	beq	a4,a5,80006356 <sys_unlink+0x18c>
  iunlockput(dp);
    800062aa:	8526                	mv	a0,s1
    800062ac:	ffffe097          	auipc	ra,0xffffe
    800062b0:	328080e7          	jalr	808(ra) # 800045d4 <iunlockput>
  ip->nlink--;
    800062b4:	04a95783          	lhu	a5,74(s2)
    800062b8:	37fd                	addiw	a5,a5,-1
    800062ba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800062be:	854a                	mv	a0,s2
    800062c0:	ffffe097          	auipc	ra,0xffffe
    800062c4:	fe8080e7          	jalr	-24(ra) # 800042a8 <iupdate>
  iunlockput(ip);
    800062c8:	854a                	mv	a0,s2
    800062ca:	ffffe097          	auipc	ra,0xffffe
    800062ce:	30a080e7          	jalr	778(ra) # 800045d4 <iunlockput>
  end_op();
    800062d2:	fffff097          	auipc	ra,0xfffff
    800062d6:	af6080e7          	jalr	-1290(ra) # 80004dc8 <end_op>
  return 0;
    800062da:	4501                	li	a0,0
    800062dc:	a84d                	j	8000638e <sys_unlink+0x1c4>
    end_op();
    800062de:	fffff097          	auipc	ra,0xfffff
    800062e2:	aea080e7          	jalr	-1302(ra) # 80004dc8 <end_op>
    return -1;
    800062e6:	557d                	li	a0,-1
    800062e8:	a05d                	j	8000638e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800062ea:	00002517          	auipc	a0,0x2
    800062ee:	49e50513          	addi	a0,a0,1182 # 80008788 <syscalls+0x318>
    800062f2:	ffffa097          	auipc	ra,0xffffa
    800062f6:	238080e7          	jalr	568(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062fa:	04c92703          	lw	a4,76(s2)
    800062fe:	02000793          	li	a5,32
    80006302:	f6e7f9e3          	bgeu	a5,a4,80006274 <sys_unlink+0xaa>
    80006306:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000630a:	4741                	li	a4,16
    8000630c:	86ce                	mv	a3,s3
    8000630e:	f1840613          	addi	a2,s0,-232
    80006312:	4581                	li	a1,0
    80006314:	854a                	mv	a0,s2
    80006316:	ffffe097          	auipc	ra,0xffffe
    8000631a:	310080e7          	jalr	784(ra) # 80004626 <readi>
    8000631e:	47c1                	li	a5,16
    80006320:	00f51b63          	bne	a0,a5,80006336 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006324:	f1845783          	lhu	a5,-232(s0)
    80006328:	e7a1                	bnez	a5,80006370 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000632a:	29c1                	addiw	s3,s3,16
    8000632c:	04c92783          	lw	a5,76(s2)
    80006330:	fcf9ede3          	bltu	s3,a5,8000630a <sys_unlink+0x140>
    80006334:	b781                	j	80006274 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	46a50513          	addi	a0,a0,1130 # 800087a0 <syscalls+0x330>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	1ec080e7          	jalr	492(ra) # 8000052a <panic>
    panic("unlink: writei");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	47250513          	addi	a0,a0,1138 # 800087b8 <syscalls+0x348>
    8000634e:	ffffa097          	auipc	ra,0xffffa
    80006352:	1dc080e7          	jalr	476(ra) # 8000052a <panic>
    dp->nlink--;
    80006356:	04a4d783          	lhu	a5,74(s1)
    8000635a:	37fd                	addiw	a5,a5,-1
    8000635c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006360:	8526                	mv	a0,s1
    80006362:	ffffe097          	auipc	ra,0xffffe
    80006366:	f46080e7          	jalr	-186(ra) # 800042a8 <iupdate>
    8000636a:	b781                	j	800062aa <sys_unlink+0xe0>
    return -1;
    8000636c:	557d                	li	a0,-1
    8000636e:	a005                	j	8000638e <sys_unlink+0x1c4>
    iunlockput(ip);
    80006370:	854a                	mv	a0,s2
    80006372:	ffffe097          	auipc	ra,0xffffe
    80006376:	262080e7          	jalr	610(ra) # 800045d4 <iunlockput>
  iunlockput(dp);
    8000637a:	8526                	mv	a0,s1
    8000637c:	ffffe097          	auipc	ra,0xffffe
    80006380:	258080e7          	jalr	600(ra) # 800045d4 <iunlockput>
  end_op();
    80006384:	fffff097          	auipc	ra,0xfffff
    80006388:	a44080e7          	jalr	-1468(ra) # 80004dc8 <end_op>
  return -1;
    8000638c:	557d                	li	a0,-1
}
    8000638e:	70ae                	ld	ra,232(sp)
    80006390:	740e                	ld	s0,224(sp)
    80006392:	64ee                	ld	s1,216(sp)
    80006394:	694e                	ld	s2,208(sp)
    80006396:	69ae                	ld	s3,200(sp)
    80006398:	616d                	addi	sp,sp,240
    8000639a:	8082                	ret

000000008000639c <sys_open>:

uint64
sys_open(void)
{
    8000639c:	7131                	addi	sp,sp,-192
    8000639e:	fd06                	sd	ra,184(sp)
    800063a0:	f922                	sd	s0,176(sp)
    800063a2:	f526                	sd	s1,168(sp)
    800063a4:	f14a                	sd	s2,160(sp)
    800063a6:	ed4e                	sd	s3,152(sp)
    800063a8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800063aa:	08000613          	li	a2,128
    800063ae:	f5040593          	addi	a1,s0,-176
    800063b2:	4501                	li	a0,0
    800063b4:	ffffd097          	auipc	ra,0xffffd
    800063b8:	2de080e7          	jalr	734(ra) # 80003692 <argstr>
    return -1;
    800063bc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800063be:	0c054163          	bltz	a0,80006480 <sys_open+0xe4>
    800063c2:	f4c40593          	addi	a1,s0,-180
    800063c6:	4505                	li	a0,1
    800063c8:	ffffd097          	auipc	ra,0xffffd
    800063cc:	286080e7          	jalr	646(ra) # 8000364e <argint>
    800063d0:	0a054863          	bltz	a0,80006480 <sys_open+0xe4>

  begin_op();
    800063d4:	fffff097          	auipc	ra,0xfffff
    800063d8:	974080e7          	jalr	-1676(ra) # 80004d48 <begin_op>

  if(omode & O_CREATE){
    800063dc:	f4c42783          	lw	a5,-180(s0)
    800063e0:	2007f793          	andi	a5,a5,512
    800063e4:	cbdd                	beqz	a5,8000649a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800063e6:	4681                	li	a3,0
    800063e8:	4601                	li	a2,0
    800063ea:	4589                	li	a1,2
    800063ec:	f5040513          	addi	a0,s0,-176
    800063f0:	00000097          	auipc	ra,0x0
    800063f4:	972080e7          	jalr	-1678(ra) # 80005d62 <create>
    800063f8:	892a                	mv	s2,a0
    if(ip == 0){
    800063fa:	c959                	beqz	a0,80006490 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800063fc:	04491703          	lh	a4,68(s2)
    80006400:	478d                	li	a5,3
    80006402:	00f71763          	bne	a4,a5,80006410 <sys_open+0x74>
    80006406:	04695703          	lhu	a4,70(s2)
    8000640a:	47a5                	li	a5,9
    8000640c:	0ce7ec63          	bltu	a5,a4,800064e4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006410:	fffff097          	auipc	ra,0xfffff
    80006414:	d48080e7          	jalr	-696(ra) # 80005158 <filealloc>
    80006418:	89aa                	mv	s3,a0
    8000641a:	10050263          	beqz	a0,8000651e <sys_open+0x182>
    8000641e:	00000097          	auipc	ra,0x0
    80006422:	902080e7          	jalr	-1790(ra) # 80005d20 <fdalloc>
    80006426:	84aa                	mv	s1,a0
    80006428:	0e054663          	bltz	a0,80006514 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000642c:	04491703          	lh	a4,68(s2)
    80006430:	478d                	li	a5,3
    80006432:	0cf70463          	beq	a4,a5,800064fa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006436:	4789                	li	a5,2
    80006438:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000643c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006440:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006444:	f4c42783          	lw	a5,-180(s0)
    80006448:	0017c713          	xori	a4,a5,1
    8000644c:	8b05                	andi	a4,a4,1
    8000644e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006452:	0037f713          	andi	a4,a5,3
    80006456:	00e03733          	snez	a4,a4
    8000645a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000645e:	4007f793          	andi	a5,a5,1024
    80006462:	c791                	beqz	a5,8000646e <sys_open+0xd2>
    80006464:	04491703          	lh	a4,68(s2)
    80006468:	4789                	li	a5,2
    8000646a:	08f70f63          	beq	a4,a5,80006508 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000646e:	854a                	mv	a0,s2
    80006470:	ffffe097          	auipc	ra,0xffffe
    80006474:	fc4080e7          	jalr	-60(ra) # 80004434 <iunlock>
  end_op();
    80006478:	fffff097          	auipc	ra,0xfffff
    8000647c:	950080e7          	jalr	-1712(ra) # 80004dc8 <end_op>

  return fd;
}
    80006480:	8526                	mv	a0,s1
    80006482:	70ea                	ld	ra,184(sp)
    80006484:	744a                	ld	s0,176(sp)
    80006486:	74aa                	ld	s1,168(sp)
    80006488:	790a                	ld	s2,160(sp)
    8000648a:	69ea                	ld	s3,152(sp)
    8000648c:	6129                	addi	sp,sp,192
    8000648e:	8082                	ret
      end_op();
    80006490:	fffff097          	auipc	ra,0xfffff
    80006494:	938080e7          	jalr	-1736(ra) # 80004dc8 <end_op>
      return -1;
    80006498:	b7e5                	j	80006480 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000649a:	f5040513          	addi	a0,s0,-176
    8000649e:	ffffe097          	auipc	ra,0xffffe
    800064a2:	68a080e7          	jalr	1674(ra) # 80004b28 <namei>
    800064a6:	892a                	mv	s2,a0
    800064a8:	c905                	beqz	a0,800064d8 <sys_open+0x13c>
    ilock(ip);
    800064aa:	ffffe097          	auipc	ra,0xffffe
    800064ae:	ec8080e7          	jalr	-312(ra) # 80004372 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800064b2:	04491703          	lh	a4,68(s2)
    800064b6:	4785                	li	a5,1
    800064b8:	f4f712e3          	bne	a4,a5,800063fc <sys_open+0x60>
    800064bc:	f4c42783          	lw	a5,-180(s0)
    800064c0:	dba1                	beqz	a5,80006410 <sys_open+0x74>
      iunlockput(ip);
    800064c2:	854a                	mv	a0,s2
    800064c4:	ffffe097          	auipc	ra,0xffffe
    800064c8:	110080e7          	jalr	272(ra) # 800045d4 <iunlockput>
      end_op();
    800064cc:	fffff097          	auipc	ra,0xfffff
    800064d0:	8fc080e7          	jalr	-1796(ra) # 80004dc8 <end_op>
      return -1;
    800064d4:	54fd                	li	s1,-1
    800064d6:	b76d                	j	80006480 <sys_open+0xe4>
      end_op();
    800064d8:	fffff097          	auipc	ra,0xfffff
    800064dc:	8f0080e7          	jalr	-1808(ra) # 80004dc8 <end_op>
      return -1;
    800064e0:	54fd                	li	s1,-1
    800064e2:	bf79                	j	80006480 <sys_open+0xe4>
    iunlockput(ip);
    800064e4:	854a                	mv	a0,s2
    800064e6:	ffffe097          	auipc	ra,0xffffe
    800064ea:	0ee080e7          	jalr	238(ra) # 800045d4 <iunlockput>
    end_op();
    800064ee:	fffff097          	auipc	ra,0xfffff
    800064f2:	8da080e7          	jalr	-1830(ra) # 80004dc8 <end_op>
    return -1;
    800064f6:	54fd                	li	s1,-1
    800064f8:	b761                	j	80006480 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800064fa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800064fe:	04691783          	lh	a5,70(s2)
    80006502:	02f99223          	sh	a5,36(s3)
    80006506:	bf2d                	j	80006440 <sys_open+0xa4>
    itrunc(ip);
    80006508:	854a                	mv	a0,s2
    8000650a:	ffffe097          	auipc	ra,0xffffe
    8000650e:	f76080e7          	jalr	-138(ra) # 80004480 <itrunc>
    80006512:	bfb1                	j	8000646e <sys_open+0xd2>
      fileclose(f);
    80006514:	854e                	mv	a0,s3
    80006516:	fffff097          	auipc	ra,0xfffff
    8000651a:	cfe080e7          	jalr	-770(ra) # 80005214 <fileclose>
    iunlockput(ip);
    8000651e:	854a                	mv	a0,s2
    80006520:	ffffe097          	auipc	ra,0xffffe
    80006524:	0b4080e7          	jalr	180(ra) # 800045d4 <iunlockput>
    end_op();
    80006528:	fffff097          	auipc	ra,0xfffff
    8000652c:	8a0080e7          	jalr	-1888(ra) # 80004dc8 <end_op>
    return -1;
    80006530:	54fd                	li	s1,-1
    80006532:	b7b9                	j	80006480 <sys_open+0xe4>

0000000080006534 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006534:	7175                	addi	sp,sp,-144
    80006536:	e506                	sd	ra,136(sp)
    80006538:	e122                	sd	s0,128(sp)
    8000653a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000653c:	fffff097          	auipc	ra,0xfffff
    80006540:	80c080e7          	jalr	-2036(ra) # 80004d48 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006544:	08000613          	li	a2,128
    80006548:	f7040593          	addi	a1,s0,-144
    8000654c:	4501                	li	a0,0
    8000654e:	ffffd097          	auipc	ra,0xffffd
    80006552:	144080e7          	jalr	324(ra) # 80003692 <argstr>
    80006556:	02054963          	bltz	a0,80006588 <sys_mkdir+0x54>
    8000655a:	4681                	li	a3,0
    8000655c:	4601                	li	a2,0
    8000655e:	4585                	li	a1,1
    80006560:	f7040513          	addi	a0,s0,-144
    80006564:	fffff097          	auipc	ra,0xfffff
    80006568:	7fe080e7          	jalr	2046(ra) # 80005d62 <create>
    8000656c:	cd11                	beqz	a0,80006588 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000656e:	ffffe097          	auipc	ra,0xffffe
    80006572:	066080e7          	jalr	102(ra) # 800045d4 <iunlockput>
  end_op();
    80006576:	fffff097          	auipc	ra,0xfffff
    8000657a:	852080e7          	jalr	-1966(ra) # 80004dc8 <end_op>
  return 0;
    8000657e:	4501                	li	a0,0
}
    80006580:	60aa                	ld	ra,136(sp)
    80006582:	640a                	ld	s0,128(sp)
    80006584:	6149                	addi	sp,sp,144
    80006586:	8082                	ret
    end_op();
    80006588:	fffff097          	auipc	ra,0xfffff
    8000658c:	840080e7          	jalr	-1984(ra) # 80004dc8 <end_op>
    return -1;
    80006590:	557d                	li	a0,-1
    80006592:	b7fd                	j	80006580 <sys_mkdir+0x4c>

0000000080006594 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006594:	7135                	addi	sp,sp,-160
    80006596:	ed06                	sd	ra,152(sp)
    80006598:	e922                	sd	s0,144(sp)
    8000659a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000659c:	ffffe097          	auipc	ra,0xffffe
    800065a0:	7ac080e7          	jalr	1964(ra) # 80004d48 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800065a4:	08000613          	li	a2,128
    800065a8:	f7040593          	addi	a1,s0,-144
    800065ac:	4501                	li	a0,0
    800065ae:	ffffd097          	auipc	ra,0xffffd
    800065b2:	0e4080e7          	jalr	228(ra) # 80003692 <argstr>
    800065b6:	04054a63          	bltz	a0,8000660a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800065ba:	f6c40593          	addi	a1,s0,-148
    800065be:	4505                	li	a0,1
    800065c0:	ffffd097          	auipc	ra,0xffffd
    800065c4:	08e080e7          	jalr	142(ra) # 8000364e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800065c8:	04054163          	bltz	a0,8000660a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800065cc:	f6840593          	addi	a1,s0,-152
    800065d0:	4509                	li	a0,2
    800065d2:	ffffd097          	auipc	ra,0xffffd
    800065d6:	07c080e7          	jalr	124(ra) # 8000364e <argint>
     argint(1, &major) < 0 ||
    800065da:	02054863          	bltz	a0,8000660a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800065de:	f6841683          	lh	a3,-152(s0)
    800065e2:	f6c41603          	lh	a2,-148(s0)
    800065e6:	458d                	li	a1,3
    800065e8:	f7040513          	addi	a0,s0,-144
    800065ec:	fffff097          	auipc	ra,0xfffff
    800065f0:	776080e7          	jalr	1910(ra) # 80005d62 <create>
     argint(2, &minor) < 0 ||
    800065f4:	c919                	beqz	a0,8000660a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800065f6:	ffffe097          	auipc	ra,0xffffe
    800065fa:	fde080e7          	jalr	-34(ra) # 800045d4 <iunlockput>
  end_op();
    800065fe:	ffffe097          	auipc	ra,0xffffe
    80006602:	7ca080e7          	jalr	1994(ra) # 80004dc8 <end_op>
  return 0;
    80006606:	4501                	li	a0,0
    80006608:	a031                	j	80006614 <sys_mknod+0x80>
    end_op();
    8000660a:	ffffe097          	auipc	ra,0xffffe
    8000660e:	7be080e7          	jalr	1982(ra) # 80004dc8 <end_op>
    return -1;
    80006612:	557d                	li	a0,-1
}
    80006614:	60ea                	ld	ra,152(sp)
    80006616:	644a                	ld	s0,144(sp)
    80006618:	610d                	addi	sp,sp,160
    8000661a:	8082                	ret

000000008000661c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000661c:	7135                	addi	sp,sp,-160
    8000661e:	ed06                	sd	ra,152(sp)
    80006620:	e922                	sd	s0,144(sp)
    80006622:	e526                	sd	s1,136(sp)
    80006624:	e14a                	sd	s2,128(sp)
    80006626:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006628:	ffffb097          	auipc	ra,0xffffb
    8000662c:	3ce080e7          	jalr	974(ra) # 800019f6 <myproc>
    80006630:	892a                	mv	s2,a0
  
  begin_op();
    80006632:	ffffe097          	auipc	ra,0xffffe
    80006636:	716080e7          	jalr	1814(ra) # 80004d48 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000663a:	08000613          	li	a2,128
    8000663e:	f6040593          	addi	a1,s0,-160
    80006642:	4501                	li	a0,0
    80006644:	ffffd097          	auipc	ra,0xffffd
    80006648:	04e080e7          	jalr	78(ra) # 80003692 <argstr>
    8000664c:	04054b63          	bltz	a0,800066a2 <sys_chdir+0x86>
    80006650:	f6040513          	addi	a0,s0,-160
    80006654:	ffffe097          	auipc	ra,0xffffe
    80006658:	4d4080e7          	jalr	1236(ra) # 80004b28 <namei>
    8000665c:	84aa                	mv	s1,a0
    8000665e:	c131                	beqz	a0,800066a2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006660:	ffffe097          	auipc	ra,0xffffe
    80006664:	d12080e7          	jalr	-750(ra) # 80004372 <ilock>
  if(ip->type != T_DIR){
    80006668:	04449703          	lh	a4,68(s1)
    8000666c:	4785                	li	a5,1
    8000666e:	04f71063          	bne	a4,a5,800066ae <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006672:	8526                	mv	a0,s1
    80006674:	ffffe097          	auipc	ra,0xffffe
    80006678:	dc0080e7          	jalr	-576(ra) # 80004434 <iunlock>
  iput(p->cwd);
    8000667c:	26093503          	ld	a0,608(s2)
    80006680:	ffffe097          	auipc	ra,0xffffe
    80006684:	eac080e7          	jalr	-340(ra) # 8000452c <iput>
  end_op();
    80006688:	ffffe097          	auipc	ra,0xffffe
    8000668c:	740080e7          	jalr	1856(ra) # 80004dc8 <end_op>
  p->cwd = ip;
    80006690:	26993023          	sd	s1,608(s2)
  return 0;
    80006694:	4501                	li	a0,0
}
    80006696:	60ea                	ld	ra,152(sp)
    80006698:	644a                	ld	s0,144(sp)
    8000669a:	64aa                	ld	s1,136(sp)
    8000669c:	690a                	ld	s2,128(sp)
    8000669e:	610d                	addi	sp,sp,160
    800066a0:	8082                	ret
    end_op();
    800066a2:	ffffe097          	auipc	ra,0xffffe
    800066a6:	726080e7          	jalr	1830(ra) # 80004dc8 <end_op>
    return -1;
    800066aa:	557d                	li	a0,-1
    800066ac:	b7ed                	j	80006696 <sys_chdir+0x7a>
    iunlockput(ip);
    800066ae:	8526                	mv	a0,s1
    800066b0:	ffffe097          	auipc	ra,0xffffe
    800066b4:	f24080e7          	jalr	-220(ra) # 800045d4 <iunlockput>
    end_op();
    800066b8:	ffffe097          	auipc	ra,0xffffe
    800066bc:	710080e7          	jalr	1808(ra) # 80004dc8 <end_op>
    return -1;
    800066c0:	557d                	li	a0,-1
    800066c2:	bfd1                	j	80006696 <sys_chdir+0x7a>

00000000800066c4 <sys_exec>:

uint64
sys_exec(void)
{
    800066c4:	7145                	addi	sp,sp,-464
    800066c6:	e786                	sd	ra,456(sp)
    800066c8:	e3a2                	sd	s0,448(sp)
    800066ca:	ff26                	sd	s1,440(sp)
    800066cc:	fb4a                	sd	s2,432(sp)
    800066ce:	f74e                	sd	s3,424(sp)
    800066d0:	f352                	sd	s4,416(sp)
    800066d2:	ef56                	sd	s5,408(sp)
    800066d4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800066d6:	08000613          	li	a2,128
    800066da:	f4040593          	addi	a1,s0,-192
    800066de:	4501                	li	a0,0
    800066e0:	ffffd097          	auipc	ra,0xffffd
    800066e4:	fb2080e7          	jalr	-78(ra) # 80003692 <argstr>
    return -1;
    800066e8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800066ea:	0c054a63          	bltz	a0,800067be <sys_exec+0xfa>
    800066ee:	e3840593          	addi	a1,s0,-456
    800066f2:	4505                	li	a0,1
    800066f4:	ffffd097          	auipc	ra,0xffffd
    800066f8:	f7c080e7          	jalr	-132(ra) # 80003670 <argaddr>
    800066fc:	0c054163          	bltz	a0,800067be <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006700:	10000613          	li	a2,256
    80006704:	4581                	li	a1,0
    80006706:	e4040513          	addi	a0,s0,-448
    8000670a:	ffffa097          	auipc	ra,0xffffa
    8000670e:	5d8080e7          	jalr	1496(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006712:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006716:	89a6                	mv	s3,s1
    80006718:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000671a:	02000a13          	li	s4,32
    8000671e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006722:	00391793          	slli	a5,s2,0x3
    80006726:	e3040593          	addi	a1,s0,-464
    8000672a:	e3843503          	ld	a0,-456(s0)
    8000672e:	953e                	add	a0,a0,a5
    80006730:	ffffd097          	auipc	ra,0xffffd
    80006734:	e7e080e7          	jalr	-386(ra) # 800035ae <fetchaddr>
    80006738:	02054a63          	bltz	a0,8000676c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000673c:	e3043783          	ld	a5,-464(s0)
    80006740:	c3b9                	beqz	a5,80006786 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006742:	ffffa097          	auipc	ra,0xffffa
    80006746:	390080e7          	jalr	912(ra) # 80000ad2 <kalloc>
    8000674a:	85aa                	mv	a1,a0
    8000674c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006750:	cd11                	beqz	a0,8000676c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006752:	6605                	lui	a2,0x1
    80006754:	e3043503          	ld	a0,-464(s0)
    80006758:	ffffd097          	auipc	ra,0xffffd
    8000675c:	eac080e7          	jalr	-340(ra) # 80003604 <fetchstr>
    80006760:	00054663          	bltz	a0,8000676c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006764:	0905                	addi	s2,s2,1
    80006766:	09a1                	addi	s3,s3,8
    80006768:	fb491be3          	bne	s2,s4,8000671e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000676c:	10048913          	addi	s2,s1,256
    80006770:	6088                	ld	a0,0(s1)
    80006772:	c529                	beqz	a0,800067bc <sys_exec+0xf8>
    kfree(argv[i]);
    80006774:	ffffa097          	auipc	ra,0xffffa
    80006778:	262080e7          	jalr	610(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000677c:	04a1                	addi	s1,s1,8
    8000677e:	ff2499e3          	bne	s1,s2,80006770 <sys_exec+0xac>
  return -1;
    80006782:	597d                	li	s2,-1
    80006784:	a82d                	j	800067be <sys_exec+0xfa>
      argv[i] = 0;
    80006786:	0a8e                	slli	s5,s5,0x3
    80006788:	fc040793          	addi	a5,s0,-64
    8000678c:	9abe                	add	s5,s5,a5
    8000678e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006792:	e4040593          	addi	a1,s0,-448
    80006796:	f4040513          	addi	a0,s0,-192
    8000679a:	fffff097          	auipc	ra,0xfffff
    8000679e:	0cc080e7          	jalr	204(ra) # 80005866 <exec>
    800067a2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800067a4:	10048993          	addi	s3,s1,256
    800067a8:	6088                	ld	a0,0(s1)
    800067aa:	c911                	beqz	a0,800067be <sys_exec+0xfa>
    kfree(argv[i]);
    800067ac:	ffffa097          	auipc	ra,0xffffa
    800067b0:	22a080e7          	jalr	554(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800067b4:	04a1                	addi	s1,s1,8
    800067b6:	ff3499e3          	bne	s1,s3,800067a8 <sys_exec+0xe4>
    800067ba:	a011                	j	800067be <sys_exec+0xfa>
  return -1;
    800067bc:	597d                	li	s2,-1
}
    800067be:	854a                	mv	a0,s2
    800067c0:	60be                	ld	ra,456(sp)
    800067c2:	641e                	ld	s0,448(sp)
    800067c4:	74fa                	ld	s1,440(sp)
    800067c6:	795a                	ld	s2,432(sp)
    800067c8:	79ba                	ld	s3,424(sp)
    800067ca:	7a1a                	ld	s4,416(sp)
    800067cc:	6afa                	ld	s5,408(sp)
    800067ce:	6179                	addi	sp,sp,464
    800067d0:	8082                	ret

00000000800067d2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800067d2:	7139                	addi	sp,sp,-64
    800067d4:	fc06                	sd	ra,56(sp)
    800067d6:	f822                	sd	s0,48(sp)
    800067d8:	f426                	sd	s1,40(sp)
    800067da:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800067dc:	ffffb097          	auipc	ra,0xffffb
    800067e0:	21a080e7          	jalr	538(ra) # 800019f6 <myproc>
    800067e4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800067e6:	fd840593          	addi	a1,s0,-40
    800067ea:	4501                	li	a0,0
    800067ec:	ffffd097          	auipc	ra,0xffffd
    800067f0:	e84080e7          	jalr	-380(ra) # 80003670 <argaddr>
    return -1;
    800067f4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800067f6:	0e054463          	bltz	a0,800068de <sys_pipe+0x10c>
  if(pipealloc(&rf, &wf) < 0)
    800067fa:	fc840593          	addi	a1,s0,-56
    800067fe:	fd040513          	addi	a0,s0,-48
    80006802:	fffff097          	auipc	ra,0xfffff
    80006806:	d42080e7          	jalr	-702(ra) # 80005544 <pipealloc>
    return -1;
    8000680a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000680c:	0c054963          	bltz	a0,800068de <sys_pipe+0x10c>
  fd0 = -1;
    80006810:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006814:	fd043503          	ld	a0,-48(s0)
    80006818:	fffff097          	auipc	ra,0xfffff
    8000681c:	508080e7          	jalr	1288(ra) # 80005d20 <fdalloc>
    80006820:	fca42223          	sw	a0,-60(s0)
    80006824:	0a054063          	bltz	a0,800068c4 <sys_pipe+0xf2>
    80006828:	fc843503          	ld	a0,-56(s0)
    8000682c:	fffff097          	auipc	ra,0xfffff
    80006830:	4f4080e7          	jalr	1268(ra) # 80005d20 <fdalloc>
    80006834:	fca42023          	sw	a0,-64(s0)
    80006838:	06054c63          	bltz	a0,800068b0 <sys_pipe+0xde>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000683c:	4691                	li	a3,4
    8000683e:	fc440613          	addi	a2,s0,-60
    80006842:	fd843583          	ld	a1,-40(s0)
    80006846:	1d84b503          	ld	a0,472(s1)
    8000684a:	ffffb097          	auipc	ra,0xffffb
    8000684e:	e18080e7          	jalr	-488(ra) # 80001662 <copyout>
    80006852:	02054163          	bltz	a0,80006874 <sys_pipe+0xa2>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006856:	4691                	li	a3,4
    80006858:	fc040613          	addi	a2,s0,-64
    8000685c:	fd843583          	ld	a1,-40(s0)
    80006860:	0591                	addi	a1,a1,4
    80006862:	1d84b503          	ld	a0,472(s1)
    80006866:	ffffb097          	auipc	ra,0xffffb
    8000686a:	dfc080e7          	jalr	-516(ra) # 80001662 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000686e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006870:	06055763          	bgez	a0,800068de <sys_pipe+0x10c>
    p->ofile[fd0] = 0;
    80006874:	fc442783          	lw	a5,-60(s0)
    80006878:	03c78793          	addi	a5,a5,60
    8000687c:	078e                	slli	a5,a5,0x3
    8000687e:	97a6                	add	a5,a5,s1
    80006880:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006884:	fc042503          	lw	a0,-64(s0)
    80006888:	03c50513          	addi	a0,a0,60
    8000688c:	050e                	slli	a0,a0,0x3
    8000688e:	9526                	add	a0,a0,s1
    80006890:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006894:	fd043503          	ld	a0,-48(s0)
    80006898:	fffff097          	auipc	ra,0xfffff
    8000689c:	97c080e7          	jalr	-1668(ra) # 80005214 <fileclose>
    fileclose(wf);
    800068a0:	fc843503          	ld	a0,-56(s0)
    800068a4:	fffff097          	auipc	ra,0xfffff
    800068a8:	970080e7          	jalr	-1680(ra) # 80005214 <fileclose>
    return -1;
    800068ac:	57fd                	li	a5,-1
    800068ae:	a805                	j	800068de <sys_pipe+0x10c>
    if(fd0 >= 0)
    800068b0:	fc442783          	lw	a5,-60(s0)
    800068b4:	0007c863          	bltz	a5,800068c4 <sys_pipe+0xf2>
      p->ofile[fd0] = 0;
    800068b8:	03c78513          	addi	a0,a5,60
    800068bc:	050e                	slli	a0,a0,0x3
    800068be:	9526                	add	a0,a0,s1
    800068c0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800068c4:	fd043503          	ld	a0,-48(s0)
    800068c8:	fffff097          	auipc	ra,0xfffff
    800068cc:	94c080e7          	jalr	-1716(ra) # 80005214 <fileclose>
    fileclose(wf);
    800068d0:	fc843503          	ld	a0,-56(s0)
    800068d4:	fffff097          	auipc	ra,0xfffff
    800068d8:	940080e7          	jalr	-1728(ra) # 80005214 <fileclose>
    return -1;
    800068dc:	57fd                	li	a5,-1
}
    800068de:	853e                	mv	a0,a5
    800068e0:	70e2                	ld	ra,56(sp)
    800068e2:	7442                	ld	s0,48(sp)
    800068e4:	74a2                	ld	s1,40(sp)
    800068e6:	6121                	addi	sp,sp,64
    800068e8:	8082                	ret
    800068ea:	0000                	unimp
    800068ec:	0000                	unimp
	...

00000000800068f0 <kernelvec>:
    800068f0:	7111                	addi	sp,sp,-256
    800068f2:	e006                	sd	ra,0(sp)
    800068f4:	e40a                	sd	sp,8(sp)
    800068f6:	e80e                	sd	gp,16(sp)
    800068f8:	ec12                	sd	tp,24(sp)
    800068fa:	f016                	sd	t0,32(sp)
    800068fc:	f41a                	sd	t1,40(sp)
    800068fe:	f81e                	sd	t2,48(sp)
    80006900:	fc22                	sd	s0,56(sp)
    80006902:	e0a6                	sd	s1,64(sp)
    80006904:	e4aa                	sd	a0,72(sp)
    80006906:	e8ae                	sd	a1,80(sp)
    80006908:	ecb2                	sd	a2,88(sp)
    8000690a:	f0b6                	sd	a3,96(sp)
    8000690c:	f4ba                	sd	a4,104(sp)
    8000690e:	f8be                	sd	a5,112(sp)
    80006910:	fcc2                	sd	a6,120(sp)
    80006912:	e146                	sd	a7,128(sp)
    80006914:	e54a                	sd	s2,136(sp)
    80006916:	e94e                	sd	s3,144(sp)
    80006918:	ed52                	sd	s4,152(sp)
    8000691a:	f156                	sd	s5,160(sp)
    8000691c:	f55a                	sd	s6,168(sp)
    8000691e:	f95e                	sd	s7,176(sp)
    80006920:	fd62                	sd	s8,184(sp)
    80006922:	e1e6                	sd	s9,192(sp)
    80006924:	e5ea                	sd	s10,200(sp)
    80006926:	e9ee                	sd	s11,208(sp)
    80006928:	edf2                	sd	t3,216(sp)
    8000692a:	f1f6                	sd	t4,224(sp)
    8000692c:	f5fa                	sd	t5,232(sp)
    8000692e:	f9fe                	sd	t6,240(sp)
    80006930:	b4dfc0ef          	jal	ra,8000347c <kerneltrap>
    80006934:	6082                	ld	ra,0(sp)
    80006936:	6122                	ld	sp,8(sp)
    80006938:	61c2                	ld	gp,16(sp)
    8000693a:	7282                	ld	t0,32(sp)
    8000693c:	7322                	ld	t1,40(sp)
    8000693e:	73c2                	ld	t2,48(sp)
    80006940:	7462                	ld	s0,56(sp)
    80006942:	6486                	ld	s1,64(sp)
    80006944:	6526                	ld	a0,72(sp)
    80006946:	65c6                	ld	a1,80(sp)
    80006948:	6666                	ld	a2,88(sp)
    8000694a:	7686                	ld	a3,96(sp)
    8000694c:	7726                	ld	a4,104(sp)
    8000694e:	77c6                	ld	a5,112(sp)
    80006950:	7866                	ld	a6,120(sp)
    80006952:	688a                	ld	a7,128(sp)
    80006954:	692a                	ld	s2,136(sp)
    80006956:	69ca                	ld	s3,144(sp)
    80006958:	6a6a                	ld	s4,152(sp)
    8000695a:	7a8a                	ld	s5,160(sp)
    8000695c:	7b2a                	ld	s6,168(sp)
    8000695e:	7bca                	ld	s7,176(sp)
    80006960:	7c6a                	ld	s8,184(sp)
    80006962:	6c8e                	ld	s9,192(sp)
    80006964:	6d2e                	ld	s10,200(sp)
    80006966:	6dce                	ld	s11,208(sp)
    80006968:	6e6e                	ld	t3,216(sp)
    8000696a:	7e8e                	ld	t4,224(sp)
    8000696c:	7f2e                	ld	t5,232(sp)
    8000696e:	7fce                	ld	t6,240(sp)
    80006970:	6111                	addi	sp,sp,256
    80006972:	10200073          	sret
    80006976:	00000013          	nop
    8000697a:	00000013          	nop
    8000697e:	0001                	nop

0000000080006980 <timervec>:
    80006980:	34051573          	csrrw	a0,mscratch,a0
    80006984:	e10c                	sd	a1,0(a0)
    80006986:	e510                	sd	a2,8(a0)
    80006988:	e914                	sd	a3,16(a0)
    8000698a:	6d0c                	ld	a1,24(a0)
    8000698c:	7110                	ld	a2,32(a0)
    8000698e:	6194                	ld	a3,0(a1)
    80006990:	96b2                	add	a3,a3,a2
    80006992:	e194                	sd	a3,0(a1)
    80006994:	4589                	li	a1,2
    80006996:	14459073          	csrw	sip,a1
    8000699a:	6914                	ld	a3,16(a0)
    8000699c:	6510                	ld	a2,8(a0)
    8000699e:	610c                	ld	a1,0(a0)
    800069a0:	34051573          	csrrw	a0,mscratch,a0
    800069a4:	30200073          	mret
	...

00000000800069aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800069aa:	1141                	addi	sp,sp,-16
    800069ac:	e422                	sd	s0,8(sp)
    800069ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800069b0:	0c0007b7          	lui	a5,0xc000
    800069b4:	4705                	li	a4,1
    800069b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800069b8:	c3d8                	sw	a4,4(a5)
}
    800069ba:	6422                	ld	s0,8(sp)
    800069bc:	0141                	addi	sp,sp,16
    800069be:	8082                	ret

00000000800069c0 <plicinithart>:

void
plicinithart(void)
{
    800069c0:	1141                	addi	sp,sp,-16
    800069c2:	e406                	sd	ra,8(sp)
    800069c4:	e022                	sd	s0,0(sp)
    800069c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800069c8:	ffffb097          	auipc	ra,0xffffb
    800069cc:	002080e7          	jalr	2(ra) # 800019ca <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800069d0:	0085171b          	slliw	a4,a0,0x8
    800069d4:	0c0027b7          	lui	a5,0xc002
    800069d8:	97ba                	add	a5,a5,a4
    800069da:	40200713          	li	a4,1026
    800069de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800069e2:	00d5151b          	slliw	a0,a0,0xd
    800069e6:	0c2017b7          	lui	a5,0xc201
    800069ea:	953e                	add	a0,a0,a5
    800069ec:	00052023          	sw	zero,0(a0)
}
    800069f0:	60a2                	ld	ra,8(sp)
    800069f2:	6402                	ld	s0,0(sp)
    800069f4:	0141                	addi	sp,sp,16
    800069f6:	8082                	ret

00000000800069f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800069f8:	1141                	addi	sp,sp,-16
    800069fa:	e406                	sd	ra,8(sp)
    800069fc:	e022                	sd	s0,0(sp)
    800069fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006a00:	ffffb097          	auipc	ra,0xffffb
    80006a04:	fca080e7          	jalr	-54(ra) # 800019ca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006a08:	00d5179b          	slliw	a5,a0,0xd
    80006a0c:	0c201537          	lui	a0,0xc201
    80006a10:	953e                	add	a0,a0,a5
  return irq;
}
    80006a12:	4148                	lw	a0,4(a0)
    80006a14:	60a2                	ld	ra,8(sp)
    80006a16:	6402                	ld	s0,0(sp)
    80006a18:	0141                	addi	sp,sp,16
    80006a1a:	8082                	ret

0000000080006a1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006a1c:	1101                	addi	sp,sp,-32
    80006a1e:	ec06                	sd	ra,24(sp)
    80006a20:	e822                	sd	s0,16(sp)
    80006a22:	e426                	sd	s1,8(sp)
    80006a24:	1000                	addi	s0,sp,32
    80006a26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006a28:	ffffb097          	auipc	ra,0xffffb
    80006a2c:	fa2080e7          	jalr	-94(ra) # 800019ca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006a30:	00d5151b          	slliw	a0,a0,0xd
    80006a34:	0c2017b7          	lui	a5,0xc201
    80006a38:	97aa                	add	a5,a5,a0
    80006a3a:	c3c4                	sw	s1,4(a5)
}
    80006a3c:	60e2                	ld	ra,24(sp)
    80006a3e:	6442                	ld	s0,16(sp)
    80006a40:	64a2                	ld	s1,8(sp)
    80006a42:	6105                	addi	sp,sp,32
    80006a44:	8082                	ret

0000000080006a46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006a46:	1141                	addi	sp,sp,-16
    80006a48:	e406                	sd	ra,8(sp)
    80006a4a:	e022                	sd	s0,0(sp)
    80006a4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006a4e:	479d                	li	a5,7
    80006a50:	06a7c963          	blt	a5,a0,80006ac2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006a54:	00038797          	auipc	a5,0x38
    80006a58:	5ac78793          	addi	a5,a5,1452 # 8003f000 <disk>
    80006a5c:	00a78733          	add	a4,a5,a0
    80006a60:	6789                	lui	a5,0x2
    80006a62:	97ba                	add	a5,a5,a4
    80006a64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006a68:	e7ad                	bnez	a5,80006ad2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006a6a:	00451793          	slli	a5,a0,0x4
    80006a6e:	0003a717          	auipc	a4,0x3a
    80006a72:	59270713          	addi	a4,a4,1426 # 80041000 <disk+0x2000>
    80006a76:	6314                	ld	a3,0(a4)
    80006a78:	96be                	add	a3,a3,a5
    80006a7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006a7e:	6314                	ld	a3,0(a4)
    80006a80:	96be                	add	a3,a3,a5
    80006a82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006a86:	6314                	ld	a3,0(a4)
    80006a88:	96be                	add	a3,a3,a5
    80006a8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006a8e:	6318                	ld	a4,0(a4)
    80006a90:	97ba                	add	a5,a5,a4
    80006a92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006a96:	00038797          	auipc	a5,0x38
    80006a9a:	56a78793          	addi	a5,a5,1386 # 8003f000 <disk>
    80006a9e:	97aa                	add	a5,a5,a0
    80006aa0:	6509                	lui	a0,0x2
    80006aa2:	953e                	add	a0,a0,a5
    80006aa4:	4785                	li	a5,1
    80006aa6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006aaa:	0003a517          	auipc	a0,0x3a
    80006aae:	56e50513          	addi	a0,a0,1390 # 80041018 <disk+0x2018>
    80006ab2:	ffffc097          	auipc	ra,0xffffc
    80006ab6:	d62080e7          	jalr	-670(ra) # 80002814 <wakeup>
}
    80006aba:	60a2                	ld	ra,8(sp)
    80006abc:	6402                	ld	s0,0(sp)
    80006abe:	0141                	addi	sp,sp,16
    80006ac0:	8082                	ret
    panic("free_desc 1");
    80006ac2:	00002517          	auipc	a0,0x2
    80006ac6:	d0650513          	addi	a0,a0,-762 # 800087c8 <syscalls+0x358>
    80006aca:	ffffa097          	auipc	ra,0xffffa
    80006ace:	a60080e7          	jalr	-1440(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006ad2:	00002517          	auipc	a0,0x2
    80006ad6:	d0650513          	addi	a0,a0,-762 # 800087d8 <syscalls+0x368>
    80006ada:	ffffa097          	auipc	ra,0xffffa
    80006ade:	a50080e7          	jalr	-1456(ra) # 8000052a <panic>

0000000080006ae2 <virtio_disk_init>:
{
    80006ae2:	1101                	addi	sp,sp,-32
    80006ae4:	ec06                	sd	ra,24(sp)
    80006ae6:	e822                	sd	s0,16(sp)
    80006ae8:	e426                	sd	s1,8(sp)
    80006aea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006aec:	00002597          	auipc	a1,0x2
    80006af0:	cfc58593          	addi	a1,a1,-772 # 800087e8 <syscalls+0x378>
    80006af4:	0003a517          	auipc	a0,0x3a
    80006af8:	63450513          	addi	a0,a0,1588 # 80041128 <disk+0x2128>
    80006afc:	ffffa097          	auipc	ra,0xffffa
    80006b00:	036080e7          	jalr	54(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006b04:	100017b7          	lui	a5,0x10001
    80006b08:	4398                	lw	a4,0(a5)
    80006b0a:	2701                	sext.w	a4,a4
    80006b0c:	747277b7          	lui	a5,0x74727
    80006b10:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006b14:	0ef71163          	bne	a4,a5,80006bf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006b18:	100017b7          	lui	a5,0x10001
    80006b1c:	43dc                	lw	a5,4(a5)
    80006b1e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006b20:	4705                	li	a4,1
    80006b22:	0ce79a63          	bne	a5,a4,80006bf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006b26:	100017b7          	lui	a5,0x10001
    80006b2a:	479c                	lw	a5,8(a5)
    80006b2c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006b2e:	4709                	li	a4,2
    80006b30:	0ce79363          	bne	a5,a4,80006bf6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006b34:	100017b7          	lui	a5,0x10001
    80006b38:	47d8                	lw	a4,12(a5)
    80006b3a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006b3c:	554d47b7          	lui	a5,0x554d4
    80006b40:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006b44:	0af71963          	bne	a4,a5,80006bf6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b48:	100017b7          	lui	a5,0x10001
    80006b4c:	4705                	li	a4,1
    80006b4e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b50:	470d                	li	a4,3
    80006b52:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006b54:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006b56:	c7ffe737          	lui	a4,0xc7ffe
    80006b5a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fbc75f>
    80006b5e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006b60:	2701                	sext.w	a4,a4
    80006b62:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b64:	472d                	li	a4,11
    80006b66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b68:	473d                	li	a4,15
    80006b6a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006b6c:	6705                	lui	a4,0x1
    80006b6e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006b70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006b74:	5bdc                	lw	a5,52(a5)
    80006b76:	2781                	sext.w	a5,a5
  if(max == 0)
    80006b78:	c7d9                	beqz	a5,80006c06 <virtio_disk_init+0x124>
  if(max < NUM)
    80006b7a:	471d                	li	a4,7
    80006b7c:	08f77d63          	bgeu	a4,a5,80006c16 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b80:	100014b7          	lui	s1,0x10001
    80006b84:	47a1                	li	a5,8
    80006b86:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006b88:	6609                	lui	a2,0x2
    80006b8a:	4581                	li	a1,0
    80006b8c:	00038517          	auipc	a0,0x38
    80006b90:	47450513          	addi	a0,a0,1140 # 8003f000 <disk>
    80006b94:	ffffa097          	auipc	ra,0xffffa
    80006b98:	14e080e7          	jalr	334(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006b9c:	00038717          	auipc	a4,0x38
    80006ba0:	46470713          	addi	a4,a4,1124 # 8003f000 <disk>
    80006ba4:	00c75793          	srli	a5,a4,0xc
    80006ba8:	2781                	sext.w	a5,a5
    80006baa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006bac:	0003a797          	auipc	a5,0x3a
    80006bb0:	45478793          	addi	a5,a5,1108 # 80041000 <disk+0x2000>
    80006bb4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006bb6:	00038717          	auipc	a4,0x38
    80006bba:	4ca70713          	addi	a4,a4,1226 # 8003f080 <disk+0x80>
    80006bbe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006bc0:	00039717          	auipc	a4,0x39
    80006bc4:	44070713          	addi	a4,a4,1088 # 80040000 <disk+0x1000>
    80006bc8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006bca:	4705                	li	a4,1
    80006bcc:	00e78c23          	sb	a4,24(a5)
    80006bd0:	00e78ca3          	sb	a4,25(a5)
    80006bd4:	00e78d23          	sb	a4,26(a5)
    80006bd8:	00e78da3          	sb	a4,27(a5)
    80006bdc:	00e78e23          	sb	a4,28(a5)
    80006be0:	00e78ea3          	sb	a4,29(a5)
    80006be4:	00e78f23          	sb	a4,30(a5)
    80006be8:	00e78fa3          	sb	a4,31(a5)
}
    80006bec:	60e2                	ld	ra,24(sp)
    80006bee:	6442                	ld	s0,16(sp)
    80006bf0:	64a2                	ld	s1,8(sp)
    80006bf2:	6105                	addi	sp,sp,32
    80006bf4:	8082                	ret
    panic("could not find virtio disk");
    80006bf6:	00002517          	auipc	a0,0x2
    80006bfa:	c0250513          	addi	a0,a0,-1022 # 800087f8 <syscalls+0x388>
    80006bfe:	ffffa097          	auipc	ra,0xffffa
    80006c02:	92c080e7          	jalr	-1748(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006c06:	00002517          	auipc	a0,0x2
    80006c0a:	c1250513          	addi	a0,a0,-1006 # 80008818 <syscalls+0x3a8>
    80006c0e:	ffffa097          	auipc	ra,0xffffa
    80006c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006c16:	00002517          	auipc	a0,0x2
    80006c1a:	c2250513          	addi	a0,a0,-990 # 80008838 <syscalls+0x3c8>
    80006c1e:	ffffa097          	auipc	ra,0xffffa
    80006c22:	90c080e7          	jalr	-1780(ra) # 8000052a <panic>

0000000080006c26 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006c26:	7119                	addi	sp,sp,-128
    80006c28:	fc86                	sd	ra,120(sp)
    80006c2a:	f8a2                	sd	s0,112(sp)
    80006c2c:	f4a6                	sd	s1,104(sp)
    80006c2e:	f0ca                	sd	s2,96(sp)
    80006c30:	ecce                	sd	s3,88(sp)
    80006c32:	e8d2                	sd	s4,80(sp)
    80006c34:	e4d6                	sd	s5,72(sp)
    80006c36:	e0da                	sd	s6,64(sp)
    80006c38:	fc5e                	sd	s7,56(sp)
    80006c3a:	f862                	sd	s8,48(sp)
    80006c3c:	f466                	sd	s9,40(sp)
    80006c3e:	f06a                	sd	s10,32(sp)
    80006c40:	ec6e                	sd	s11,24(sp)
    80006c42:	0100                	addi	s0,sp,128
    80006c44:	8aaa                	mv	s5,a0
    80006c46:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006c48:	00c52c83          	lw	s9,12(a0)
    80006c4c:	001c9c9b          	slliw	s9,s9,0x1
    80006c50:	1c82                	slli	s9,s9,0x20
    80006c52:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006c56:	0003a517          	auipc	a0,0x3a
    80006c5a:	4d250513          	addi	a0,a0,1234 # 80041128 <disk+0x2128>
    80006c5e:	ffffa097          	auipc	ra,0xffffa
    80006c62:	f64080e7          	jalr	-156(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006c66:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006c68:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006c6a:	00038c17          	auipc	s8,0x38
    80006c6e:	396c0c13          	addi	s8,s8,918 # 8003f000 <disk>
    80006c72:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006c74:	4b0d                	li	s6,3
    80006c76:	a0ad                	j	80006ce0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006c78:	00fc0733          	add	a4,s8,a5
    80006c7c:	975e                	add	a4,a4,s7
    80006c7e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006c82:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006c84:	0207c563          	bltz	a5,80006cae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006c88:	2905                	addiw	s2,s2,1
    80006c8a:	0611                	addi	a2,a2,4
    80006c8c:	19690d63          	beq	s2,s6,80006e26 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006c90:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006c92:	0003a717          	auipc	a4,0x3a
    80006c96:	38670713          	addi	a4,a4,902 # 80041018 <disk+0x2018>
    80006c9a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006c9c:	00074683          	lbu	a3,0(a4)
    80006ca0:	fee1                	bnez	a3,80006c78 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006ca2:	2785                	addiw	a5,a5,1
    80006ca4:	0705                	addi	a4,a4,1
    80006ca6:	fe979be3          	bne	a5,s1,80006c9c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006caa:	57fd                	li	a5,-1
    80006cac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006cae:	01205d63          	blez	s2,80006cc8 <virtio_disk_rw+0xa2>
    80006cb2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006cb4:	000a2503          	lw	a0,0(s4)
    80006cb8:	00000097          	auipc	ra,0x0
    80006cbc:	d8e080e7          	jalr	-626(ra) # 80006a46 <free_desc>
      for(int j = 0; j < i; j++)
    80006cc0:	2d85                	addiw	s11,s11,1
    80006cc2:	0a11                	addi	s4,s4,4
    80006cc4:	ffb918e3          	bne	s2,s11,80006cb4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006cc8:	0003a597          	auipc	a1,0x3a
    80006ccc:	46058593          	addi	a1,a1,1120 # 80041128 <disk+0x2128>
    80006cd0:	0003a517          	auipc	a0,0x3a
    80006cd4:	34850513          	addi	a0,a0,840 # 80041018 <disk+0x2018>
    80006cd8:	ffffc097          	auipc	ra,0xffffc
    80006cdc:	9b2080e7          	jalr	-1614(ra) # 8000268a <sleep>
  for(int i = 0; i < 3; i++){
    80006ce0:	f8040a13          	addi	s4,s0,-128
{
    80006ce4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006ce6:	894e                	mv	s2,s3
    80006ce8:	b765                	j	80006c90 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006cea:	0003a697          	auipc	a3,0x3a
    80006cee:	3166b683          	ld	a3,790(a3) # 80041000 <disk+0x2000>
    80006cf2:	96ba                	add	a3,a3,a4
    80006cf4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006cf8:	00038817          	auipc	a6,0x38
    80006cfc:	30880813          	addi	a6,a6,776 # 8003f000 <disk>
    80006d00:	0003a697          	auipc	a3,0x3a
    80006d04:	30068693          	addi	a3,a3,768 # 80041000 <disk+0x2000>
    80006d08:	6290                	ld	a2,0(a3)
    80006d0a:	963a                	add	a2,a2,a4
    80006d0c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006d10:	0015e593          	ori	a1,a1,1
    80006d14:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006d18:	f8842603          	lw	a2,-120(s0)
    80006d1c:	628c                	ld	a1,0(a3)
    80006d1e:	972e                	add	a4,a4,a1
    80006d20:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d24:	20050593          	addi	a1,a0,512
    80006d28:	0592                	slli	a1,a1,0x4
    80006d2a:	95c2                	add	a1,a1,a6
    80006d2c:	577d                	li	a4,-1
    80006d2e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d32:	00461713          	slli	a4,a2,0x4
    80006d36:	6290                	ld	a2,0(a3)
    80006d38:	963a                	add	a2,a2,a4
    80006d3a:	03078793          	addi	a5,a5,48
    80006d3e:	97c2                	add	a5,a5,a6
    80006d40:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006d42:	629c                	ld	a5,0(a3)
    80006d44:	97ba                	add	a5,a5,a4
    80006d46:	4605                	li	a2,1
    80006d48:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d4a:	629c                	ld	a5,0(a3)
    80006d4c:	97ba                	add	a5,a5,a4
    80006d4e:	4809                	li	a6,2
    80006d50:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006d54:	629c                	ld	a5,0(a3)
    80006d56:	973e                	add	a4,a4,a5
    80006d58:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d5c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006d60:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d64:	6698                	ld	a4,8(a3)
    80006d66:	00275783          	lhu	a5,2(a4)
    80006d6a:	8b9d                	andi	a5,a5,7
    80006d6c:	0786                	slli	a5,a5,0x1
    80006d6e:	97ba                	add	a5,a5,a4
    80006d70:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006d74:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d78:	6698                	ld	a4,8(a3)
    80006d7a:	00275783          	lhu	a5,2(a4)
    80006d7e:	2785                	addiw	a5,a5,1
    80006d80:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d84:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d88:	100017b7          	lui	a5,0x10001
    80006d8c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006d90:	004aa783          	lw	a5,4(s5)
    80006d94:	02c79163          	bne	a5,a2,80006db6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006d98:	0003a917          	auipc	s2,0x3a
    80006d9c:	39090913          	addi	s2,s2,912 # 80041128 <disk+0x2128>
  while(b->disk == 1) {
    80006da0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006da2:	85ca                	mv	a1,s2
    80006da4:	8556                	mv	a0,s5
    80006da6:	ffffc097          	auipc	ra,0xffffc
    80006daa:	8e4080e7          	jalr	-1820(ra) # 8000268a <sleep>
  while(b->disk == 1) {
    80006dae:	004aa783          	lw	a5,4(s5)
    80006db2:	fe9788e3          	beq	a5,s1,80006da2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006db6:	f8042903          	lw	s2,-128(s0)
    80006dba:	20090793          	addi	a5,s2,512
    80006dbe:	00479713          	slli	a4,a5,0x4
    80006dc2:	00038797          	auipc	a5,0x38
    80006dc6:	23e78793          	addi	a5,a5,574 # 8003f000 <disk>
    80006dca:	97ba                	add	a5,a5,a4
    80006dcc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006dd0:	0003a997          	auipc	s3,0x3a
    80006dd4:	23098993          	addi	s3,s3,560 # 80041000 <disk+0x2000>
    80006dd8:	00491713          	slli	a4,s2,0x4
    80006ddc:	0009b783          	ld	a5,0(s3)
    80006de0:	97ba                	add	a5,a5,a4
    80006de2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006de6:	854a                	mv	a0,s2
    80006de8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006dec:	00000097          	auipc	ra,0x0
    80006df0:	c5a080e7          	jalr	-934(ra) # 80006a46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006df4:	8885                	andi	s1,s1,1
    80006df6:	f0ed                	bnez	s1,80006dd8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006df8:	0003a517          	auipc	a0,0x3a
    80006dfc:	33050513          	addi	a0,a0,816 # 80041128 <disk+0x2128>
    80006e00:	ffffa097          	auipc	ra,0xffffa
    80006e04:	e88080e7          	jalr	-376(ra) # 80000c88 <release>
}
    80006e08:	70e6                	ld	ra,120(sp)
    80006e0a:	7446                	ld	s0,112(sp)
    80006e0c:	74a6                	ld	s1,104(sp)
    80006e0e:	7906                	ld	s2,96(sp)
    80006e10:	69e6                	ld	s3,88(sp)
    80006e12:	6a46                	ld	s4,80(sp)
    80006e14:	6aa6                	ld	s5,72(sp)
    80006e16:	6b06                	ld	s6,64(sp)
    80006e18:	7be2                	ld	s7,56(sp)
    80006e1a:	7c42                	ld	s8,48(sp)
    80006e1c:	7ca2                	ld	s9,40(sp)
    80006e1e:	7d02                	ld	s10,32(sp)
    80006e20:	6de2                	ld	s11,24(sp)
    80006e22:	6109                	addi	sp,sp,128
    80006e24:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e26:	f8042503          	lw	a0,-128(s0)
    80006e2a:	20050793          	addi	a5,a0,512
    80006e2e:	0792                	slli	a5,a5,0x4
  if(write)
    80006e30:	00038817          	auipc	a6,0x38
    80006e34:	1d080813          	addi	a6,a6,464 # 8003f000 <disk>
    80006e38:	00f80733          	add	a4,a6,a5
    80006e3c:	01a036b3          	snez	a3,s10
    80006e40:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006e44:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006e48:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006e4c:	7679                	lui	a2,0xffffe
    80006e4e:	963e                	add	a2,a2,a5
    80006e50:	0003a697          	auipc	a3,0x3a
    80006e54:	1b068693          	addi	a3,a3,432 # 80041000 <disk+0x2000>
    80006e58:	6298                	ld	a4,0(a3)
    80006e5a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e5c:	0a878593          	addi	a1,a5,168
    80006e60:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006e62:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006e64:	6298                	ld	a4,0(a3)
    80006e66:	9732                	add	a4,a4,a2
    80006e68:	45c1                	li	a1,16
    80006e6a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006e6c:	6298                	ld	a4,0(a3)
    80006e6e:	9732                	add	a4,a4,a2
    80006e70:	4585                	li	a1,1
    80006e72:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006e76:	f8442703          	lw	a4,-124(s0)
    80006e7a:	628c                	ld	a1,0(a3)
    80006e7c:	962e                	add	a2,a2,a1
    80006e7e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffbc00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006e82:	0712                	slli	a4,a4,0x4
    80006e84:	6290                	ld	a2,0(a3)
    80006e86:	963a                	add	a2,a2,a4
    80006e88:	058a8593          	addi	a1,s5,88
    80006e8c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006e8e:	6294                	ld	a3,0(a3)
    80006e90:	96ba                	add	a3,a3,a4
    80006e92:	40000613          	li	a2,1024
    80006e96:	c690                	sw	a2,8(a3)
  if(write)
    80006e98:	e40d19e3          	bnez	s10,80006cea <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e9c:	0003a697          	auipc	a3,0x3a
    80006ea0:	1646b683          	ld	a3,356(a3) # 80041000 <disk+0x2000>
    80006ea4:	96ba                	add	a3,a3,a4
    80006ea6:	4609                	li	a2,2
    80006ea8:	00c69623          	sh	a2,12(a3)
    80006eac:	b5b1                	j	80006cf8 <virtio_disk_rw+0xd2>

0000000080006eae <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006eae:	1101                	addi	sp,sp,-32
    80006eb0:	ec06                	sd	ra,24(sp)
    80006eb2:	e822                	sd	s0,16(sp)
    80006eb4:	e426                	sd	s1,8(sp)
    80006eb6:	e04a                	sd	s2,0(sp)
    80006eb8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006eba:	0003a517          	auipc	a0,0x3a
    80006ebe:	26e50513          	addi	a0,a0,622 # 80041128 <disk+0x2128>
    80006ec2:	ffffa097          	auipc	ra,0xffffa
    80006ec6:	d00080e7          	jalr	-768(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006eca:	10001737          	lui	a4,0x10001
    80006ece:	533c                	lw	a5,96(a4)
    80006ed0:	8b8d                	andi	a5,a5,3
    80006ed2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ed4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ed8:	0003a797          	auipc	a5,0x3a
    80006edc:	12878793          	addi	a5,a5,296 # 80041000 <disk+0x2000>
    80006ee0:	6b94                	ld	a3,16(a5)
    80006ee2:	0207d703          	lhu	a4,32(a5)
    80006ee6:	0026d783          	lhu	a5,2(a3)
    80006eea:	06f70163          	beq	a4,a5,80006f4c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006eee:	00038917          	auipc	s2,0x38
    80006ef2:	11290913          	addi	s2,s2,274 # 8003f000 <disk>
    80006ef6:	0003a497          	auipc	s1,0x3a
    80006efa:	10a48493          	addi	s1,s1,266 # 80041000 <disk+0x2000>
    __sync_synchronize();
    80006efe:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006f02:	6898                	ld	a4,16(s1)
    80006f04:	0204d783          	lhu	a5,32(s1)
    80006f08:	8b9d                	andi	a5,a5,7
    80006f0a:	078e                	slli	a5,a5,0x3
    80006f0c:	97ba                	add	a5,a5,a4
    80006f0e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006f10:	20078713          	addi	a4,a5,512
    80006f14:	0712                	slli	a4,a4,0x4
    80006f16:	974a                	add	a4,a4,s2
    80006f18:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006f1c:	e731                	bnez	a4,80006f68 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006f1e:	20078793          	addi	a5,a5,512
    80006f22:	0792                	slli	a5,a5,0x4
    80006f24:	97ca                	add	a5,a5,s2
    80006f26:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006f28:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006f2c:	ffffc097          	auipc	ra,0xffffc
    80006f30:	8e8080e7          	jalr	-1816(ra) # 80002814 <wakeup>

    disk.used_idx += 1;
    80006f34:	0204d783          	lhu	a5,32(s1)
    80006f38:	2785                	addiw	a5,a5,1
    80006f3a:	17c2                	slli	a5,a5,0x30
    80006f3c:	93c1                	srli	a5,a5,0x30
    80006f3e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006f42:	6898                	ld	a4,16(s1)
    80006f44:	00275703          	lhu	a4,2(a4)
    80006f48:	faf71be3          	bne	a4,a5,80006efe <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006f4c:	0003a517          	auipc	a0,0x3a
    80006f50:	1dc50513          	addi	a0,a0,476 # 80041128 <disk+0x2128>
    80006f54:	ffffa097          	auipc	ra,0xffffa
    80006f58:	d34080e7          	jalr	-716(ra) # 80000c88 <release>
}
    80006f5c:	60e2                	ld	ra,24(sp)
    80006f5e:	6442                	ld	s0,16(sp)
    80006f60:	64a2                	ld	s1,8(sp)
    80006f62:	6902                	ld	s2,0(sp)
    80006f64:	6105                	addi	sp,sp,32
    80006f66:	8082                	ret
      panic("virtio_disk_intr status");
    80006f68:	00002517          	auipc	a0,0x2
    80006f6c:	8f050513          	addi	a0,a0,-1808 # 80008858 <syscalls+0x3e8>
    80006f70:	ffff9097          	auipc	ra,0xffff9
    80006f74:	5ba080e7          	jalr	1466(ra) # 8000052a <panic>
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
